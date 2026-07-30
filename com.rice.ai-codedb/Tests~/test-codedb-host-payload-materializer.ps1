#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$embeddedProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $packageRoot "..\.."))
$embeddedPackagePath = Join-Path $embeddedProjectRoot "Packages\com.rice.ai-codedb"
$isEmbeddedLayout = [string]::Equals(
    [System.IO.Path]::GetFullPath($embeddedPackagePath).TrimEnd('\', '/'),
    $packageRoot.TrimEnd('\', '/'),
    [StringComparison]::OrdinalIgnoreCase)
$projectRoot = if ($isEmbeddedLayout) {
    $embeddedProjectRoot
} else {
    [System.IO.Path]::GetFullPath((Join-Path $packageRoot ".."))
}
$materializerPath = Join-Path $packageRoot "Tools~\materialize-codedb-host-payload.ps1"
$canonicalPayloadRoot = Join-Path $packageRoot "Payload~"
$pocRoot = Join-Path $projectRoot "AIWork\.runtime\codedb\materializer-poc"
$runRoot = Join-Path $pocRoot ([guid]::NewGuid().ToString("N"))
$hostRoot = Join-Path $runRoot "fixture"
$trackedHostRoot = Join-Path $runRoot "tracked-host"
$syntheticRoot = Join-Path $runRoot "payloads"
$fixtureGitIndexPath = Join-Path $runRoot "fixture-git-index"
$productionProjectRoot = if ($isEmbeddedLayout) { $projectRoot } else { Join-Path $runRoot "production-project" }
$powershellPath = (Get-Process -Id $PID).Path
$nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$markerRelativePath = "AIWork/codedb/.rice-ai-codedb-payload.json"
$generationId = "poc.27"
$generationTargetPrefix = "AIWork/.runtime/codedb/host/generations/$generationId/"
$currentPointerRelativePath = "AIWork/.runtime/codedb/host/current.json"
$lastKnownGoodPointerRelativePath = "AIWork/.runtime/codedb/host/last-known-good.json"
$fixtureMarkerName = ".rice-ai-codedb-poc-fixture.json"
$junctionPath = $null
$readEscapeJunctionPath = $null
$activeWatchManagerPath = $null
$activeWatchLifecycleId = $null
$activeMcpProcess = $null
$fixturePassed = $false
$canonicalPayloadManifestPath = Join-Path $canonicalPayloadRoot "payload-manifest.json"
$canonicalPayloadManifest = Get-Content -LiteralPath $canonicalPayloadManifestPath -Raw | ConvertFrom-Json
$canonicalManagedEntries = @($canonicalPayloadManifest.files | ForEach-Object {
    [pscustomobject]@{
        Source = [string]$_.source
        Target = [string]$_.target
    }
} | Sort-Object Target)
$canonicalSourceByTarget = @{}
foreach ($entry in $canonicalManagedEntries) {
    $canonicalSourceByTarget[$entry.Target] = $entry.Source
}
$legacyManagedTargets = @($canonicalManagedEntries | Where-Object {
    $_.Target.StartsWith("AIWork/codedb/", [StringComparison]::OrdinalIgnoreCase)
} | ForEach-Object { $_.Target })
$generationManagedTargets = @($canonicalManagedEntries | Where-Object {
    $_.Target.StartsWith($generationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
} | ForEach-Object { $_.Target })
$pointerManagedTargets = @($canonicalManagedEntries | Where-Object {
    [string]::Equals($_.Target, $currentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)
} | ForEach-Object { $_.Target })
$managedTargets = @($canonicalManagedEntries | ForEach-Object { $_.Target })
$sentinelPaths = @(
    $fixtureMarkerName,
    "Assets/BusinessSentinel.txt",
    "Assets/MaterializerFreshnessProbe.cs",
    "Assets/ZMaterializerBoundedReadProbe.cs",
    "Assets/ZMaterializerOutputCeilingProbe.cs",
    "Assets/MaterializerProbe.shader",
    "Assets/Scoped/ScopedProbe.cs",
    "Assets/Scoped/SecondScopedProbe.cs",
    "Assets/Scoped/ScopedProbe.shader",
    "Assets/Outside/OutsideProbe.cs",
    ".codex/config.toml",
    "AIWork/codedb/adoption-decision.md",
    "AIWork/codedb/wrapper/host-compatibility-sentinel.mjs"
)
$trackedHostSentinelPaths = @($sentinelPaths | Where-Object { $_ -ne $fixtureMarkerName })

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Equal {
    param(
        [AllowNull()]$Actual,
        [AllowNull()]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not [string]::Equals([string]$Actual, [string]$Expected, [StringComparison]::Ordinal)) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Assert-LfOnlyFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    Assert-True -Condition ($bytes.Length -gt 0) -Message "$Label is empty."
    Assert-True -Condition ([Array]::IndexOf($bytes, [byte]13) -lt 0) -Message "$Label contains CR bytes."
    Assert-Equal -Actual $bytes[$bytes.Length - 1] -Expected 10 -Message "$Label does not end with one LF byte."
}

function Wait-ForPathState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$Present,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if ((Test-Path -LiteralPath $Path) -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (Test-Path -LiteralPath $Path) -eq $Present
}

function Wait-ForWatchReady {
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [int]$TimeoutMilliseconds = 30000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
            try {
                $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
                $processIds = @($state.coordinator_pid, $state.provider_pid, $state.adapter_worker_pid)
                $processesReady = @($processIds | Where-Object {
                    $processId = 0
                    -not [int]::TryParse([string]$_, [ref]$processId) -or
                        $processId -le 0 -or
                        $null -eq (Get-Process -Id $processId -ErrorAction SilentlyContinue)
                }).Count -eq 0
                if ($state.provider_state -eq "ready" -and
                    $state.adapter_state -in @("watching", "pending", "building") -and
                    $state.adapter_worker_state -eq "ready" -and
                    $processesReady) {
                    return $true
                }
            } catch {
                # The coordinator publishes state atomically; retry any transient read race.
            }
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

function Get-HostUseLeasePaths {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId
    )

    $leaseRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\host-use-leases"
    if (-not (Test-Path -LiteralPath $leaseRoot -PathType Container)) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath $leaseRoot -Force -File | Where-Object {
        $_.Name -like "$Owner-$ProcessId-*.json"
    } | Sort-Object Name | ForEach-Object { $_.FullName })
}

function Wait-ForHostUseLease {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][bool]$Present,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if ((@(Get-HostUseLeasePaths -Owner $Owner -ProcessId $ProcessId).Count -gt 0) -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (@(Get-HostUseLeasePaths -Owner $Owner -ProcessId $ProcessId).Count -gt 0) -eq $Present
}

function Get-GenerationLeasePaths {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [string]$LeaseGenerationId = $generationId
    )

    $leaseRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\host\leases\$LeaseGenerationId"
    if (-not (Test-Path -LiteralPath $leaseRoot -PathType Container)) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath $leaseRoot -Force -File | Where-Object {
        $_.Name -like "$Owner-$ProcessId-*.json"
    } | Sort-Object Name | ForEach-Object { $_.FullName })
}

function Wait-ForGenerationLease {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][bool]$Present,
        [string]$LeaseGenerationId = $generationId,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        $exists = @(Get-GenerationLeasePaths -Owner $Owner -ProcessId $ProcessId -LeaseGenerationId $LeaseGenerationId).Count -gt 0
        if ($exists -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (@(Get-GenerationLeasePaths -Owner $Owner -ProcessId $ProcessId -LeaseGenerationId $LeaseGenerationId).Count -gt 0) -eq $Present
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function New-TestGenerationLease {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [int]$ProcessId = $PID,
        [string]$LeaseGenerationId = $generationId,
        [string]$ProcessStartIdentity,
        [DateTime]$HeartbeatUtc = [DateTime]::UtcNow
    )

    if ([string]::IsNullOrWhiteSpace($ProcessStartIdentity)) {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($null -ne $process -and -not $process.HasExited) {
            $startOffset = [DateTimeOffset]::new($process.StartTime.ToUniversalTime())
            $ProcessStartIdentity = $startOffset.ToUnixTimeMilliseconds().ToString([Globalization.CultureInfo]::InvariantCulture)
        } else {
            $ProcessStartIdentity = "1"
        }
    }
    $leaseId = "$Owner-$ProcessId-$([guid]::NewGuid().ToString('N'))"
    $leasePath = Join-Path $hostRoot "AIWork\.runtime\codedb\host\leases\$LeaseGenerationId\$leaseId.json"
    $lease = [ordered]@{
        schema_version = 2
        generation_lease_version = 2
        managed_by = "com.rice.ai-codedb"
        generation_id = $LeaseGenerationId
        lease_id = $leaseId
        owner = $Owner
        pid = $ProcessId
        process_start_identity = $ProcessStartIdentity
        project_root = [System.IO.Path]::GetFullPath($hostRoot).TrimEnd('\', '/')
        created_at_utc = $HeartbeatUtc.AddSeconds(-1).ToString("o")
        heartbeat_at_utc = $HeartbeatUtc.ToString("o")
    }
    Write-Utf8File -Path $leasePath -Content (($lease | ConvertTo-Json -Depth 5) + "`n")
    return $leasePath
}

function Start-LegacyHostUseLeaseProcess {
    param(
        [Parameter(Mandatory = $true)][string]$GatePath,
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner
    )

    $holderPath = Join-Path $runRoot ("legacy-$Owner-lease-holder-$([guid]::NewGuid().ToString('N')).mjs")
    $gateUriJson = ([System.Uri]::new($GatePath)).AbsoluteUri | ConvertTo-Json -Compress
    $rootJson = [System.IO.Path]::GetFullPath($hostRoot) | ConvertTo-Json -Compress
    $ownerJson = $Owner | ConvertTo-Json -Compress
    Write-Utf8File -Path $holderPath -Content @"
const { acquireCodedbHostUseLease } = await import($gateUriJson);
const lease = acquireCodedbHostUseLease($rootJson, $ownerJson);
process.stdout.write("READY\n");
let closing = false;
function close() {
  if (closing) return;
  closing = true;
  lease.release();
  process.exit(0);
}
process.stdin.resume();
process.stdin.on("end", close);
process.on("SIGTERM", close);
setInterval(() => {}, 1000);
"@

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$holderPath`""
    $startInfo.WorkingDirectory = $hostRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    $ready = $process.StandardOutput.ReadLine()
    if (-not [string]::Equals($ready, "READY", [StringComparison]::Ordinal)) {
        $errorText = $process.StandardError.ReadToEnd()
        if (-not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
        throw "Legacy $Owner lease holder failed to start. $errorText"
    }
    if (-not (Wait-ForHostUseLease -Owner $Owner -ProcessId $process.Id -Present $true)) {
        $process.Kill()
        $process.WaitForExit()
        $process.Dispose()
        throw "Legacy $Owner lease holder did not publish its lease."
    }
    return $process
}

function Stop-LegacyHostUseLeaseProcess {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner
    )

    $processId = $Process.Id
    if (-not $Process.HasExited) {
        $Process.StandardInput.Close()
        if (-not $Process.WaitForExit(10000)) {
            $Process.Kill()
            $Process.WaitForExit()
            throw "Legacy $Owner lease holder did not exit after stdin closed."
        }
    }
    $stderr = $Process.StandardError.ReadToEnd().Trim()
    Assert-Equal -Actual $Process.ExitCode -Expected 0 -Message "Legacy $Owner lease holder exit code mismatch."
    Assert-True -Condition ([string]::IsNullOrWhiteSpace($stderr)) -Message "Legacy $Owner lease holder reported stderr: $stderr"
    $Process.Dispose()
    Assert-True -Condition (Wait-ForHostUseLease -Owner $Owner -ProcessId $processId -Present $false) -Message "Legacy $Owner lease did not drain after its owner exited."
}

function Get-TestProjectIdentity {
    param([Parameter(Mandatory = $true)][string]$Root)

    $canonical = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/').Replace('\', '/').ToLowerInvariant()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canonical))
    } finally {
        $sha256.Dispose()
    }
    return "sha256:" + (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}

function New-TestEditorLease {
    param(
        [Parameter(Mandatory = $true)][string]$LeaseRoot,
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$SessionId = ([guid]::NewGuid().ToString("N")),
        [int]$ProcessId = $PID,
        [string]$ProcessStartTicks,
        [DateTime]$HeartbeatUtc = [DateTime]::UtcNow
    )

    if ([string]::IsNullOrWhiteSpace($ProcessStartTicks)) {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        $ProcessStartTicks = $process.StartTime.ToUniversalTime().Ticks.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    }
    $lease = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        session_id = $SessionId
        editor_pid = $ProcessId
        process_start_ticks = $ProcessStartTicks
        project_root = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
        project_identity = Get-TestProjectIdentity -Root $Root
        created_at_utc = $HeartbeatUtc.AddSeconds(-1).ToString("o")
        heartbeat_at_utc = $HeartbeatUtc.ToString("o")
    }
    $leasePath = Join-Path $LeaseRoot ($SessionId + ".json")
    Write-Utf8File -Path $leasePath -Content (($lease | ConvertTo-Json -Depth 5) + "`n")
    return $leasePath
}

function Set-TestEditorLeaseHeartbeat {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][DateTime]$HeartbeatUtc
    )

    $lease = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    $lease.created_at_utc = $HeartbeatUtc.AddSeconds(-1).ToString("o")
    $lease.heartbeat_at_utc = $HeartbeatUtc.ToString("o")
    Write-Utf8File -Path $Path -Content (($lease | ConvertTo-Json -Depth 5) + "`n")
}

function Wait-ForEditorSessionCount {
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [Parameter(Mandatory = $true)][int]$Count,
        [int]$TimeoutMilliseconds = 10000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
            try {
                $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
                if ([int]$state.editor_session_count -eq $Count) {
                    return $true
                }
            } catch {
                # Retry an atomic state replacement race.
            }
        }
        Start-Sleep -Milliseconds 50
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

function Invoke-PowerShellAction {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)

    Push-Location -LiteralPath $hostRoot
    try {
        $global:LASTEXITCODE = 0
        try {
            $output = @(& $Action 2>&1 3>&1 4>&1 5>&1 6>&1)
            $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
        } catch {
            $output = @($_)
            $exitCode = 1
        }
        $lines = @($output | ForEach-Object { $_.ToString() })
        return [pscustomobject]@{
            ExitCode = $exitCode
            Lines = $lines
            Text = $lines -join [Environment]::NewLine
        }
    } finally {
        Pop-Location
    }
}

function New-WatcherHandoffHarness {
    param([Parameter(Mandatory = $true)][string]$ManagerSourcePath)

    $harnessRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\watch-handoff-fixture"
    $codedbRoot = Join-Path $harnessRoot "codedb"
    $scriptsRoot = Join-Path $codedbRoot "scripts"
    $coordinatorRoot = Join-Path $codedbRoot "coordinator"
    $providerRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-handoff-fixture"
    $providerConfigRoot = Join-Path $providerRoot "config"
    $providerExecutablePath = Join-Path $providerRoot "bin\codebase-mcp.exe"
    $adapterManifestPath = Join-Path $providerRoot "text-adapter\manifest.json"
    $statePath = Join-Path $harnessRoot "coordinator-state.json"
    $managerPath = Join-Path $scriptsRoot "manage-codedb-project-watch.ps1"

    New-Item -ItemType Directory -Force -Path $scriptsRoot, $coordinatorRoot, $providerConfigRoot | Out-Null
    Copy-Item -LiteralPath $ManagerSourcePath -Destination $managerPath -Force
    Write-Utf8File -Path (Join-Path $scriptsRoot "handoff-context.json") -Content (([ordered]@{
        unity_root = [System.IO.Path]::GetFullPath($hostRoot)
        codedb_root = [System.IO.Path]::GetFullPath($codedbRoot)
        provider_root = [System.IO.Path]::GetFullPath($providerRoot)
        provider_config_root = [System.IO.Path]::GetFullPath($providerConfigRoot)
        provider_executable = [System.IO.Path]::GetFullPath($providerExecutablePath)
        adapter_manifest = [System.IO.Path]::GetFullPath($adapterManifestPath)
        generation_id = "fixture.new"
    } | ConvertTo-Json -Depth 4) + "`n")
    Write-Utf8File -Path (Join-Path $scriptsRoot "codedb-project-common.ps1") -Content @'
$script:HandoffContext = Get-Content -LiteralPath (Join-Path $PSScriptRoot "handoff-context.json") -Raw | ConvertFrom-Json

function Get-ProjectCodedbContext {
    return [pscustomobject]@{
        UnityRoot = [string]$script:HandoffContext.unity_root
        CodedbRoot = [string]$script:HandoffContext.codedb_root
        ProviderRoot = [string]$script:HandoffContext.provider_root
        ProviderConfigRoot = [string]$script:HandoffContext.provider_config_root
        TextAdapterManifestPath = [string]$script:HandoffContext.adapter_manifest
        GenerationId = [string]$script:HandoffContext.generation_id
        WrapperScriptPath = Join-Path ([string]$script:HandoffContext.codedb_root) "wrapper\codedb-project-wrapper.mjs"
    }
}

function Assert-CodedbUnityProject { param($Context) }

function Get-ProjectCodedbProviderPaths {
    param($Context)
    return [pscustomobject]@{ ExecutablePath = [string]$script:HandoffContext.provider_executable }
}

function Assert-ProjectCodedbProviderFiles {
    param($Context)
    return Get-ProjectCodedbProviderPaths -Context $Context
}

function Assert-CodedbPathInside {
    param([string]$Path, [string]$Root, [string]$Label)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    if (-not [string]::Equals($fullPath, $fullRoot, [StringComparison]::OrdinalIgnoreCase) -and
        -not $fullPath.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label path is outside expected root."
    }
}

function ConvertTo-CodedbProjectRelativePath {
    param($Context, [string]$Path)
    return $Path
}
'@

    foreach ($scriptName in @(
        "build-codedb-project-text-adapter.ps1",
        "refresh-codedb-project-if-stale.ps1",
        "run-codedb-project-text-adapter-worker.ps1"
    )) {
        Write-Utf8File -Path (Join-Path $scriptsRoot $scriptName) -Content "# fixture no-op`n"
    }
    Write-Utf8File -Path (Join-Path $scriptsRoot "prepare-codedb-project-watch-config.ps1") -Content "param([int]`$PollIntervalSeconds = 1)`n"
    Write-Utf8File -Path $providerExecutablePath -Content "fixture provider`n"
    Write-Utf8File -Path $adapterManifestPath -Content "{}`n"

    $statePathJson = $statePath.Replace('\', '/') | ConvertTo-Json -Compress
    Write-Utf8File -Path (Join-Path $coordinatorRoot "codedb-watch-coordinator.mjs") -Content @"
import fs from "node:fs";
import path from "node:path";

const statePath = $statePathJson;
const command = process.argv[2];
function option(name) {
  const index = process.argv.indexOf(name);
  return index >= 0 ? process.argv[index + 1] : null;
}
function stopped() {
  return {
    action: "stopped",
    generation_id: null,
    lifecycle_id: null,
    provider_state: "stopped",
    adapter_state: "stopped",
    adapter_worker_state: "stopped",
    editor_session_count: 1,
    exclusive_lifecycle: false
  };
}
function readState() {
  return fs.existsSync(statePath) ? JSON.parse(fs.readFileSync(statePath, "utf8")) : stopped();
}
function writeState(state) {
  fs.mkdirSync(path.dirname(statePath), { recursive: true });
  fs.writeFileSync(statePath, JSON.stringify(state) + "\n", "utf8");
}

if (command === "status") {
  process.stdout.write(JSON.stringify(readState()) + "\n");
} else if (command === "stop") {
  const state = stopped();
  writeState(state);
  process.stdout.write(JSON.stringify(state) + "\n");
} else if (command === "start") {
  const running = {
    action: "running",
    generation_id: option("--generation-id"),
    lifecycle_id: option("--lifecycle-id"),
    provider_state: "ready",
    adapter_state: "watching",
    adapter_worker_state: "ready",
    editor_session_count: 1,
    exclusive_lifecycle: option("--exclusive-lifecycle") === "true"
  };
  writeState(running);
  process.stdout.write(JSON.stringify({ ...running, action: "started" }) + "\n");
} else {
  throw new Error("Unsupported fixture coordinator command: " + command);
}
"@

    $editorLeaseRoot = Join-Path $providerRoot "watch\lifecycle\editor-leases"
    $null = New-TestEditorLease -LeaseRoot $editorLeaseRoot -Root $hostRoot -SessionId "handoff-fixture-editor"
    return [pscustomobject]@{
        ManagerPath = $managerPath
        StatePath = $statePath
        GenerationId = "fixture.new"
        ActiveMarkerPath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\materialize-active.json"
    }
}

function Set-WatcherHandoffCoordinatorState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowNull()][string]$GenerationId
    )

    $state = [ordered]@{
        action = "running"
        lifecycle_id = "fixture-old-lifecycle"
        provider_state = "ready"
        adapter_state = "watching"
        adapter_worker_state = "ready"
        editor_session_count = 1
        exclusive_lifecycle = $false
    }
    if (-not [string]::IsNullOrWhiteSpace($GenerationId)) {
        $state["generation_id"] = $GenerationId
    }
    Write-Utf8File -Path $Path -Content (($state | ConvertTo-Json -Depth 4 -Compress) + "`n")
}

function Write-TestMaterializerActiveMarker {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$ProcessId = $PID,
        [string]$ProcessStartTicks
    )

    if ([string]::IsNullOrWhiteSpace($ProcessStartTicks)) {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        $ProcessStartTicks = if ($null -eq $process) {
            "1"
        } else {
            $process.StartTime.ToUniversalTime().Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)
        }
    }
    $marker = [ordered]@{
        schema_version = 1
        host_use_gate_version = 1
        managed_by = "com.rice.ai-codedb"
        pid = $ProcessId
        process_start_ticks = $ProcessStartTicks
        project_root = [System.IO.Path]::GetFullPath($hostRoot)
        action = "upgrade"
        created_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    Write-Utf8File -Path $Path -Content (($marker | ConvertTo-Json -Depth 4) + "`n")
}

function Invoke-NativeProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [int]$TimeoutMilliseconds = 10000
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = $Arguments
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.StandardInput.Close()
        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            $process.Kill()
            $process.WaitForExit()
            throw "Native process timed out after $TimeoutMilliseconds ms: $FilePath $Arguments"
        }
        $process.WaitForExit()
        $stdout = $stdoutTask.Result
        $stderr = $stderrTask.Result
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = $stdout
            StandardError = $stderr
            Text = ($stdout + $stderr).Trim()
        }
    } finally {
        $process.Dispose()
    }
}

function Get-LastJsonObject {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $jsonLines = @($Result.Lines | Where-Object { $_.TrimStart().StartsWith("{") })
    if ($jsonLines.Count -eq 0) {
        throw "$Label returned no structured JSON.`n$($Result.Text)"
    }
    return $jsonLines[-1] | ConvertFrom-Json
}

function Get-TomlSectionValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $currentSection = ""
    $values = @()
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[([^\]]+)\]\s*(?:#.*)?$') {
            $currentSection = $Matches[1]
            continue
        }
        if ([string]::Equals($currentSection, $Section, [StringComparison]::OrdinalIgnoreCase) -and
            $line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*$' -and
            [string]::Equals($Matches[1], $Key, [StringComparison]::OrdinalIgnoreCase)) {
            $values += $Matches[2]
        }
    }
    if ($values.Count -ne 1) {
        throw "Expected exactly one [$Section].$Key value in $Path, found $($values.Count)."
    }
    return $values[0]
}

function New-FixtureProviderExecutable {
    param([Parameter(Mandatory = $true)][string]$Path)

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    $source = @'
using System;
using System.IO;
using System.Text.RegularExpressions;

public static class CodedbMaterializerFixtureProvider
{
    private static readonly Regex IdPattern = new Regex("\"id\"\\s*:\\s*(\\d+)", RegexOptions.Compiled);
    private static readonly Regex StorageDirPattern = new Regex(@"(?m)^\s*dir\s*=\s*""([^""]+)""\s*$", RegexOptions.Compiled);

    public static int Main(string[] args)
    {
        if (args.Length > 0 && String.Equals(args[0], "index", StringComparison.Ordinal))
        {
            return RunIndex(args);
        }
        if (args.Length > 0 && String.Equals(args[0], "tool", StringComparison.Ordinal))
        {
            return RunTool(args);
        }
        if (args.Length != 4 ||
            !String.Equals(args[0], "--config", StringComparison.Ordinal) ||
            !String.Equals(args[2], "mcp", StringComparison.Ordinal))
        {
            Console.Error.WriteLine("Unsupported fixture provider arguments.");
            return 2;
        }

        string line;
        while ((line = Console.ReadLine()) != null)
        {
            if (line.IndexOf("\"method\":\"initialize\"", StringComparison.Ordinal) >= 0)
            {
                Respond(line, "{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"serverInfo\":{\"name\":\"codedb-fixture-provider\",\"version\":\"0.1.0\"}}");
            }
            else if (line.IndexOf("\"method\":\"tools/list\"", StringComparison.Ordinal) >= 0)
            {
                Respond(line, "{\"tools\":[{\"name\":\"codedb_search\",\"description\":\"Fixture semantic search\",\"inputSchema\":{\"type\":\"object\"}},{\"name\":\"codedb_text_search\",\"description\":\"Fixture text search\",\"inputSchema\":{\"type\":\"object\"}},{\"name\":\"codedb_find\",\"description\":\"Fixture find\",\"inputSchema\":{\"type\":\"object\"}}]}");
            }
            else if (line.IndexOf("\"method\":\"tools/call\"", StringComparison.Ordinal) >= 0)
            {
                string toolName = GetRequestedToolName(line);
                Console.Error.WriteLine("codebase-mcp timing total: 0.007s");
                string output = BuildToolOutput(toolName, line, Path.GetFileName(args[1]), "mcp", args[3]);
                Respond(line, "{\"content\":[{\"type\":\"text\",\"text\":\"" + EscapeJson(output) + "\"}],\"isError\":false}");
            }
        }
        return 0;
    }

    private static int RunIndex(string[] args)
    {
        int rootIndex = Array.IndexOf(args, "--root");
        int configIndex = Array.IndexOf(args, "--config");
        bool noWatch = Array.IndexOf(args, "--no-watch") >= 0;
        if (rootIndex < 0 || rootIndex + 1 >= args.Length ||
            configIndex < 0 || configIndex + 1 >= args.Length ||
            !noWatch)
        {
            Console.Error.WriteLine("Fixture provider index requires --root, --config, and --no-watch.");
            return 2;
        }

        string root = Path.GetFullPath(args[rootIndex + 1]);
        string configPath = Path.GetFullPath(args[configIndex + 1]);
        Match storageMatch = StorageDirPattern.Match(File.ReadAllText(configPath));
        if (!storageMatch.Success)
        {
            Console.Error.WriteLine("Fixture provider config has no storage directory.");
            return 2;
        }

        string storageDir = storageMatch.Groups[1].Value.Replace('/', Path.DirectorySeparatorChar);
        string indexRoot = Path.IsPathRooted(storageDir)
            ? Path.GetFullPath(storageDir)
            : Path.GetFullPath(Path.Combine(root, storageDir));
        Directory.CreateDirectory(indexRoot);
        long createdUnixMs = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;
        File.WriteAllText(
            Path.Combine(indexRoot, "manifest.json"),
            "{\"schema_version\":1,\"fixture\":true,\"no_watch\":true,\"created_unix_ms\":" + createdUnixMs + "}\n");
        DirectoryInfo providerRoot = Directory.GetParent(indexRoot);
        if (providerRoot == null)
        {
            Console.Error.WriteLine("Fixture provider could not resolve its runtime root.");
            return 2;
        }
        string logsRoot = Path.Combine(providerRoot.FullName, "logs");
        Directory.CreateDirectory(logsRoot);
        File.AppendAllText(Path.Combine(logsRoot, "fixture-index-invocations.txt"), "index\n");
        Console.WriteLine("[FIXTURE PROVIDER] indexed --no-watch");
        return 0;
    }

    private static int RunTool(string[] args)
    {
        int configIndex = Array.IndexOf(args, "--config");
        if (configIndex < 0 || configIndex + 1 >= args.Length)
        {
            Console.Error.WriteLine("Fixture provider tool call is missing --config.");
            return 2;
        }
        Console.Error.WriteLine("codebase-mcp timing total: 0.007s");
        string toolName = args.Length > 1 ? args[1] : String.Empty;
        string toolArguments = args.Length > 2 ? args[2] : String.Empty;
        int rootIndex = Array.IndexOf(args, "--root");
        string root = rootIndex >= 0 && rootIndex + 1 < args.Length
            ? Path.GetFullPath(args[rootIndex + 1])
            : Directory.GetCurrentDirectory();
        Console.Write(BuildToolOutput(toolName, toolArguments, Path.GetFileName(args[configIndex + 1]), "tool", root));
        return 0;
    }

    private static string BuildToolOutput(string toolName, string toolArguments, string activeConfig, string mode, string root)
    {
        StringWriter writer = new StringWriter();
        writer.WriteLine("[FIXTURE PROVIDER] active_config=" + activeConfig);
        writer.WriteLine("[FIXTURE PROVIDER] mode=" + mode + " pid=" + System.Diagnostics.Process.GetCurrentProcess().Id);
        if (String.Equals(toolName, "codedb_status", StringComparison.Ordinal))
        {
            writer.WriteLine("ready");
        }
        else if (String.Equals(toolName, "codedb_text_search", StringComparison.Ordinal))
        {
            if (toolArguments.IndexOf("CODEDB_SINGLEFLIGHT_CONTRACT_A", StringComparison.Ordinal) >= 0)
            {
                System.Threading.Thread.Sleep(400);
                writer.WriteLine("1 result for 'CODEDB_SINGLEFLIGHT_CONTRACT_A' in 1 file:");
                writer.WriteLine("  Assets/Scoped/ScopedProbe.cs");
                writer.WriteLine("    L1: // CODEDB_SINGLEFLIGHT_CONTRACT_A");
            }
            else if (toolArguments.IndexOf("CODEDB_SINGLEFLIGHT_CONTRACT_B", StringComparison.Ordinal) >= 0)
            {
                writer.WriteLine("1 result for 'CODEDB_SINGLEFLIGHT_CONTRACT_B' in 1 file:");
                writer.WriteLine("  Assets/Scoped/SecondScopedProbe.cs");
                writer.WriteLine("    L1: // CODEDB_SINGLEFLIGHT_CONTRACT_B");
            }
            else if (toolArguments.IndexOf("CODEDB_SCOPE_CONTRACT", StringComparison.Ordinal) >= 0)
            {
                writer.WriteLine("[FIXTURE PROVIDER] args=" + toolArguments);
                writer.WriteLine("4 results for 'CODEDB_SCOPE_CONTRACT' in 4 files:");
                writer.WriteLine("  Assets/Scoped/ScopedProbe.cs");
                writer.WriteLine("    L1: // CODEDB_SCOPE_CONTRACT");
                writer.WriteLine("  Assets/Outside/OutsideProbe.cs");
                writer.WriteLine("    L1: // CODEDB_SCOPE_CONTRACT");
                writer.WriteLine("  Assets/Scoped/ScopedProbe.shader");
                writer.WriteLine("    L2: // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT");
                writer.WriteLine("  Assets/Scoped/SecondScopedProbe.cs");
                writer.WriteLine("    L1: // CODEDB_SCOPE_CONTRACT");
            }
            else
            {
                writer.WriteLine("[HIT] Assets/MaterializerFreshnessProbe.cs:1 CodedbMaterializerFreshnessProbe CODEDB_MATERIALIZER_PROVIDER_PROBE");
            }
        }
        else if (String.Equals(toolName, "codedb_search", StringComparison.Ordinal) &&
            toolArguments.IndexOf("CODEDB_SEARCH_CONTRACT", StringComparison.Ordinal) >= 0)
        {
            writer.WriteLine("3 results for 'CODEDB_SEARCH_CONTRACT':");
            writer.WriteLine("  Assets/Outside/OutsideProbe.cs:1-1  [score=1.000, text]");
            writer.WriteLine("    // CODEDB_SEARCH_CONTRACT");
            writer.WriteLine("  Assets/Scoped/ScopedProbe.cs:1-2  [score=0.900, text]");
            writer.WriteLine("    // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT");
            writer.WriteLine("  Assets/Scoped/ScopedProbe.shader:1-3  [score=0.800, text]");
            writer.WriteLine("    // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT");
        }
        else if (String.Equals(toolName, "codedb_find", StringComparison.Ordinal) &&
            toolArguments.IndexOf("CODEDB_FIND_CONTRACT", StringComparison.Ordinal) >= 0)
        {
            writer.WriteLine("1. Assets/Outside/OutsideProbe.cs (score: 100.00)");
            writer.WriteLine("2. Assets/Scoped/SecondScopedProbe.cs (score: 90.00)");
        }
        else if (String.Equals(toolName, "codedb_read", StringComparison.Ordinal))
        {
            string sourcePath = Path.Combine(root, "Assets", "MaterializerFreshnessProbe.cs");
            writer.WriteLine(File.ReadAllText(sourcePath));
        }
        return writer.ToString();
    }

    private static string GetRequestedToolName(string request)
    {
        foreach (string toolName in new[] { "codedb_search", "codedb_text_search", "codedb_find" })
        {
            if (request.IndexOf("\"name\":\"" + toolName + "\"", StringComparison.Ordinal) >= 0)
            {
                return toolName;
            }
        }
        return String.Empty;
    }

    private static string EscapeJson(string value)
    {
        return value
            .Replace("\\", "\\\\")
            .Replace("\"", "\\\"")
            .Replace("\r", "\\r")
            .Replace("\n", "\\n")
            .Replace("\t", "\\t");
    }

    private static void Respond(string request, string resultJson)
    {
        Match match = IdPattern.Match(request);
        if (!match.Success)
        {
            return;
        }
        Console.WriteLine("{\"jsonrpc\":\"2.0\",\"id\":" + match.Groups[1].Value + ",\"result\":" + resultJson + "}");
        Console.Out.Flush();
    }
}
'@
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $Path -OutputType ConsoleApplication -ErrorAction Stop | Out-Null
    Assert-True -Condition (Test-Path -LiteralPath $Path -PathType Leaf) -Message "Fixture provider executable was not generated: $Path"
}

function Invoke-AdapterWorkerRequest {
    param(
        [Parameter(Mandatory = $true)][string]$WorkerPath,
        [Parameter(Mandatory = $true)][string]$BuilderPath,
        [Parameter(Mandatory = $true)]$Request
    )

    $harnessPath = Join-Path $runRoot "adapter-worker-probe.mjs"
    if (-not (Test-Path -LiteralPath $harnessPath -PathType Leaf)) {
        $harness = @'
import { spawn } from "node:child_process";
import fs from "node:fs";
import readline from "node:readline";

const [workerPath, builderPath, requestPath] = process.argv.slice(2);
if (!workerPath || !builderPath || !requestPath) {
  throw new Error("Worker probe arguments are incomplete.");
}
const request = fs.readFileSync(requestPath, "utf8");

const command = process.platform === "win32" ? "powershell.exe" : "pwsh";
const child = spawn(command, [
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", workerPath,
  "-BuilderPath", builderPath
], { stdio: ["pipe", "pipe", "pipe"], windowsHide: true });
const lines = readline.createInterface({ input: child.stdout });
let ready = null;
let response = null;
let stderr = "";
const timer = setTimeout(() => {
  stderr += "Worker probe timed out.";
  child.kill();
}, 90000);

child.stderr.on("data", (chunk) => { stderr += String(chunk); });
lines.on("line", (rawLine) => {
  let message;
  try {
    message = JSON.parse(rawLine.replace(/^\uFEFF/, ""));
  } catch {
    return;
  }
  if (message.type === "ready" && !ready) {
    ready = message;
    child.stdin.write(`${request}\n`);
    return;
  }
  if ((message.type === "build_completed" || message.type === "build_failed") && !response) {
    response = message;
    child.stdin.end();
  }
});
child.once("error", (error) => {
  stderr += error.message;
});
child.once("exit", (code) => {
  clearTimeout(timer);
  if (code !== 0 || !ready || !response || stderr.trim()) {
    process.stderr.write(stderr || `Worker probe exited with code ${code}.`);
    process.exitCode = 1;
    return;
  }
  process.stdout.write(`${JSON.stringify({ ready, response })}\n`);
});
'@
        Write-Utf8File -Path $harnessPath -Content $harness
    }

    $requestPath = Join-Path $runRoot "adapter-worker-request.json"
    Write-Utf8File -Path $requestPath -Content ($Request | ConvertTo-Json -Compress -Depth 8)
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$harnessPath`" `"$WorkerPath`" `"$BuilderPath`" `"$requestPath`""
    $startInfo.WorkingDirectory = $hostRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(100000)) {
            $process.Kill()
            throw "Adapter worker protocol probe timed out."
        }
        $stdout = $stdoutTask.Result.Trim()
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Adapter worker protocol probe exited with code $($process.ExitCode).`n$stderr"
        }
        if ([string]::IsNullOrWhiteSpace($stdout)) {
            throw "Adapter worker protocol probe returned no result."
        }
        return $stdout | ConvertFrom-Json
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Get-RelativeFilePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    return $fullPath.Substring($fullRoot.Length + 1).Replace('\', '/')
}

function Get-FileSnapshot {
    param([Parameter(Mandatory = $true)][string]$Root)

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return "[]"
    }

    $rows = @(Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
        [ordered]@{
            path = Get-RelativeFilePath -Root $Root -Path $_.FullName
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            length = $_.Length
            last_write_ticks = $_.LastWriteTimeUtc.Ticks
            attributes = [int]$_.Attributes
        }
    })
    return ($rows | ConvertTo-Json -Depth 5 -Compress)
}

function Get-ManagedPayloadSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string[]]$Paths
    )

    if ($null -eq $Paths -or $Paths.Count -eq 0) {
        $Paths = @($managedTargets + @($markerRelativePath))
    }
    $rows = @($Paths | Sort-Object -Unique | ForEach-Object {
        $relativePath = $_
        $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        if (-not (Test-Path -LiteralPath $path)) {
            return
        }
        $item = Get-Item -LiteralPath $path -Force
        [ordered]@{
            path = $relativePath
            type = if ($item.PSIsContainer) { "directory" } else { "file" }
            sha256 = if ($item.PSIsContainer) { $null } else { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
            length = if ($item.PSIsContainer) { $null } else { $item.Length }
            last_write_ticks = $item.LastWriteTimeUtc.Ticks
            attributes = [int]$item.Attributes
        }
    })
    return ($rows | ConvertTo-Json -Depth 5 -Compress)
}

function Get-PathFromRelative {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    return Join-Path $Root $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

function Get-CanonicalPayloadSourcePath {
    param([Parameter(Mandatory = $true)][string]$TargetRelativePath)

    if (-not $canonicalSourceByTarget.ContainsKey($TargetRelativePath)) {
        throw "Canonical payload manifest has no source for target: $TargetRelativePath"
    }
    return Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath ([string]$canonicalSourceByTarget[$TargetRelativePath])
}

function Assert-NoReparseAncestors {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $current = $fullPath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "POC cleanup path traverses a reparse point: $current"
            }
        }
        if ([string]::Equals($current, $fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent)) {
            throw "POC cleanup path is outside its project root: $fullPath"
        }
        $parentIsRoot = [string]::Equals($parent, $fullRoot, [StringComparison]::OrdinalIgnoreCase)
        $parentIsInside = $parent.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
        if (-not ($parentIsRoot -or $parentIsInside)) {
            throw "POC cleanup path is outside its project root: $fullPath"
        }
        $current = $parent
    }
}

function Assert-NoReparseTree {
    param([Parameter(Mandatory = $true)][string]$Root)

    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push([System.IO.Path]::GetFullPath($Root))
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $current -Force)) {
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "POC cleanup tree contains a reparse point: $($item.FullName)"
            }
            if ($item.PSIsContainer) {
                $pending.Push($item.FullName)
            }
        }
    }
}

function New-TestHost {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$RunId = (Split-Path -Leaf (Split-Path -Parent $Root))
    )

    New-Item -ItemType Directory -Force -Path (Join-Path $Root "Assets") | Out-Null
    $fixtureMarker = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        purpose = "host-payload-materializer-poc"
        run_id = $RunId
    }
    Write-Utf8File -Path (Join-Path $Root $fixtureMarkerName) -Content (($fixtureMarker | ConvertTo-Json) + "`n")
    Write-Utf8File -Path (Join-Path $Root "Packages\manifest.json") -Content "{}`n"
    Write-Utf8File -Path (Join-Path $Root "ProjectSettings\ProjectVersion.txt") -Content "m_EditorVersion: 2022.3.62f1`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\BusinessSentinel.txt") -Content "business sentinel`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\MaterializerFreshnessProbe.cs") -Content @"
public static class CodedbMaterializerFreshnessProbe {
    public const string Token = "CODEDB_MATERIALIZER_PROVIDER_PROBE";
    public const string Outside = "CODEDB_BOUNDED_READ_EXCLUDED";
}
"@
    $boundedReadLines = @(1..250 | ForEach-Object { "// CODEDB_BOUNDED_LINE_{0:D3}" -f $_ })
    Write-Utf8File `
        -Path (Join-Path $Root "Assets\ZMaterializerBoundedReadProbe.cs") `
        -Content (($boundedReadLines -join "`n") + "`n")
    Write-Utf8File `
        -Path (Join-Path $Root "Assets\ZMaterializerOutputCeilingProbe.cs") `
        -Content ("// " + ("x" * 70000) + "`n")
    Write-Utf8File -Path (Join-Path $Root "Assets\MaterializerProbe.shader") -Content "Shader `"Hidden/Rice/MaterializerProbe`" {`n    // CODEDB_MATERIALIZER_ADAPTER_PROBE`n}`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Scoped\ScopedProbe.cs") -Content "// CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT`npublic static class ScopedProbe { }`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Scoped\SecondScopedProbe.cs") -Content "// CODEDB_SCOPE_CONTRACT CODEDB_FIND_CONTRACT`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Scoped\ScopedProbe.shader") -Content "Shader `"Hidden/Rice/ScopedProbe`" {`n    // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT`n}`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Outside\OutsideProbe.cs") -Content "// CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT CODEDB_FIND_CONTRACT`n"
    Write-Utf8File -Path (Join-Path $Root ".codex\config.toml") -Content @"
# config sentinel
[mcp_servers.codedb-fixture]
command = "node"
cwd = "."
args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]
startup_timeout_sec = 120
"@
    Write-Utf8File -Path (Join-Path $Root "AIWork\codedb\adoption-decision.md") -Content "host-owned documentation`n"
    Write-Utf8File -Path (Join-Path $Root "AIWork\codedb\wrapper\host-compatibility-sentinel.mjs") -Content "// host compatibility sentinel`n"
}

function Invoke-TrackedHostGit {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git -c core.autocrlf=false -C $Root @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Tracked-host Git command failed: git $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function New-TrackedHostTestProject {
    param([Parameter(Mandatory = $true)][string]$Root)

    New-TestHost -Root $Root
    Remove-Item -LiteralPath (Join-Path $Root $fixtureMarkerName) -Force
    Write-Utf8File -Path (Join-Path $Root ".gitignore") -Content "/AIWork/.runtime/`n"
    foreach ($relativePath in $managedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $null = Invoke-TrackedHostGit -Root $Root -Arguments @("init", "--quiet")
    $null = Invoke-TrackedHostGit -Root $Root -Arguments @("config", "core.autocrlf", "false")
    $null = Invoke-TrackedHostGit -Root $Root -Arguments @("add", "--all")
    $null = Invoke-TrackedHostGit -Root $Root -Arguments @(
        "-c", "user.name=CodeDB Fixture",
        "-c", "user.email=codedb-fixture@example.invalid",
        "commit", "--quiet", "-m", "Initialize tracked host fixture"
    )
}

function New-TrackedHostAuthorization {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][ValidateSet("Sync", "Remove")][string]$Action,
        [hashtable]$Overrides = @{}
    )

    $manifestPath = Join-Path $PayloadRoot "payload-manifest.json"
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $gitHead = [string](@(Invoke-TrackedHostGit -Root $Root -Arguments @("rev-parse", "HEAD"))[0])
    $authorizationId = [guid]::NewGuid().ToString("N")
    $authorization = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        purpose = "tracked-host-payload-mutation"
        authorization_id = $authorizationId
        project_root = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
        git_head = $gitHead.Trim().ToLowerInvariant()
        action = $Action
        package_version = [string]$manifest.package_version
        payload_version = [string]$manifest.payload_version
        payload_sequence = [int]$manifest.payload_sequence
        payload_manifest_sha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        target_count = @($manifest.files).Count
        acknowledgement = "I authorize com.rice.ai-codedb to mutate only its audited host payload scope."
    }
    foreach ($key in $Overrides.Keys) {
        if ($authorization.Contains($key)) {
            $authorization[$key] = $Overrides[$key]
        } else {
            $authorization.Add($key, $Overrides[$key])
        }
    }

    $authorizationPath = Join-Path $Root "AIWork\.runtime\codedb\payload-materializer\authorizations\$authorizationId.json"
    Write-Utf8File -Path $authorizationPath -Content (($authorization | ConvertTo-Json -Depth 5) + "`n")
    return $authorizationPath
}

function Invoke-Materializer {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [int]$TestFailAfterMutation = 0,
        [int]$TestCrashAfterMutation = 0,
        [switch]$TestFailWatcherHandoff,
        [switch]$TestCrashBeforeWatcherHandoff,
        [switch]$ConfirmLegacyMcpStopped,
        [switch]$OmitPocFixture,
        [string]$TrackedHostAuthorizationPath,
        [string]$GitIndexFile,
        [string]$TargetProjectRoot = $hostRoot
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $legacyConfirmationArgument = if ($ConfirmLegacyMcpStopped) { " -ConfirmLegacyMcpStopped" } else { "" }
    $watcherHandoffFaultArgument = if ($TestFailWatcherHandoff) { " -TestFailWatcherHandoff" } else { "" }
    $preHandoffCrashArgument = if ($TestCrashBeforeWatcherHandoff) { " -TestCrashBeforeWatcherHandoff" } else { "" }
    $fixtureArgument = if ($OmitPocFixture) { "" } else { " -PocFixture" }
    $authorizationArgument = if ([string]::IsNullOrWhiteSpace($TrackedHostAuthorizationPath)) { "" } else { " -TrackedHostAuthorizationPath `"$TrackedHostAuthorizationPath`"" }
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action $Action -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`"$fixtureArgument$authorizationArgument -TestFailAfterMutation $TestFailAfterMutation -TestCrashAfterMutation $TestCrashAfterMutation$watcherHandoffFaultArgument$preHandoffCrashArgument$legacyConfirmationArgument"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if (-not [string]::IsNullOrWhiteSpace($GitIndexFile)) {
        $startInfo.EnvironmentVariables["GIT_INDEX_FILE"] = [System.IO.Path]::GetFullPath($GitIndexFile)
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.Result.TrimEnd("`r", "`n")
    $stderr = $stderrTask.Result.TrimEnd("`r", "`n")
    $exitCode = $process.ExitCode
    $process.Dispose()
    $rawOutput = @($stdout, $stderr | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($rawOutput | ForEach-Object { $_.ToString() })
        Text = ($rawOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    }
}

function Invoke-FixtureIndexGit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $previousIndex = [Environment]::GetEnvironmentVariable("GIT_INDEX_FILE", [EnvironmentVariableTarget]::Process)
    try {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $fixtureGitIndexPath, [EnvironmentVariableTarget]::Process)
        $output = @(& git -c core.autocrlf=false -C $projectRoot @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Fixture Git index command failed: git $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
        }
        return $output
    } finally {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $previousIndex, [EnvironmentVariableTarget]::Process)
    }
}

function Get-ProjectGitPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return Get-RelativeFilePath -Root $projectRoot -Path $Path
}

function Assert-Result {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Result.ExitCode -ne $ExitCode) {
        throw "$Label returned $($Result.ExitCode), expected $ExitCode.`n$($Result.Text)"
    }
}

function Assert-FreshnessResult {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][ValidateSet("OK", "STALE", "UNKNOWN")][string]$OverallState,
        [Parameter(Mandatory = $true)][ValidateSet("OK", "STALE", "UNKNOWN")][string]$ProviderState,
        [Parameter(Mandatory = $true)][ValidateSet("OK", "STALE", "UNKNOWN")][string]$AdapterState,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-Result -Result $Result -ExitCode 0 -Label $Label
    $overallMarker = switch ($OverallState) {
        "OK" { "[OK] codedb freshness check passed." }
        "STALE" { "[STALE] codedb freshness check found stale index data." }
        "UNKNOWN" { "[UNKNOWN] codedb freshness check could not determine full freshness." }
    }
    foreach ($expected in @(
        $overallMarker,
        "Provider index: $ProviderState -",
        "Shader adapter: $AdapterState -",
        "Policy: this check is read-only."
    )) {
        Assert-True -Condition ($Result.Text.Contains($expected)) -Message "$Label is missing '$expected'."
    }
}

function Get-FixtureIndexInvocationCount {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 0
    }
    return @(Get-Content -LiteralPath $Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
}

function Invoke-WrapperRpc {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)]$Request
    )

    $requestLine = $Request | ConvertTo-Json -Compress -Depth 8
    $Process.StandardInput.WriteLine($requestLine)
    $Process.StandardInput.Flush()
    $responseLine = $Process.StandardOutput.ReadLine()
    if ([string]::IsNullOrWhiteSpace($responseLine)) {
        throw "Materialized wrapper closed without responding to request id $($Request.id)."
    }
    $response = $responseLine | ConvertFrom-Json
    if ($null -ne $response.PSObject.Properties["error"]) {
        throw "Materialized wrapper returned an RPC error for request id $($Request.id): $($response.error.message)"
    }
    return $response
}

function Invoke-WrapperRpcError {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)]$Request
    )

    $requestLine = $Request | ConvertTo-Json -Compress -Depth 8
    $Process.StandardInput.WriteLine($requestLine)
    $Process.StandardInput.Flush()
    $responseLine = $Process.StandardOutput.ReadLine()
    if ([string]::IsNullOrWhiteSpace($responseLine)) {
        throw "Materialized wrapper closed without responding to expected-error request id $($Request.id)."
    }
    $response = $responseLine | ConvertFrom-Json
    if ($null -eq $response.PSObject.Properties["error"]) {
        throw "Materialized wrapper accepted request id $($Request.id), but an RPC error was expected."
    }
    return $response
}

function Get-WrapperTiming {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $matches = [regex]::Matches($Text, '(?m)^\[TIMING\] (?<json>\{.*\})\s*$')
    if ($matches.Count -ne 1) {
        throw "$Label expected exactly one machine-readable timing footer, found $($matches.Count)."
    }
    try {
        return $matches[0].Groups["json"].Value | ConvertFrom-Json
    } catch {
        throw "$Label timing footer is not valid JSON: $($_.Exception.Message)"
    }
}

function Invoke-CoordinatorPipeRequest {
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [Parameter(Mandatory = $true)]$Request
    )

    $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
    $pipePrefix = "\\.\pipe\"
    if (-not ([string]$state.pipe_name).StartsWith($pipePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Coordinator fixture expected a Windows named pipe, got '$($state.pipe_name)'."
    }

    $pipeName = ([string]$state.pipe_name).Substring($pipePrefix.Length)
    $client = [System.IO.Pipes.NamedPipeClientStream]::new(
        ".",
        $pipeName,
        [System.IO.Pipes.PipeDirection]::InOut,
        [System.IO.Pipes.PipeOptions]::None)
    $reader = $null
    $writer = $null
    try {
        $client.Connect(5000)
        $reader = [System.IO.StreamReader]::new($client, [System.Text.Encoding]::UTF8, $false, 4096, $true)
        $writer = [System.IO.StreamWriter]::new($client, [System.Text.UTF8Encoding]::new($false), 4096, $true)
        $writer.AutoFlush = $true
        $writer.WriteLine(($Request | ConvertTo-Json -Compress -Depth 8))
        $responseLine = $reader.ReadLine()
        if ([string]::IsNullOrWhiteSpace($responseLine)) {
            throw "Coordinator pipe closed without a response."
        }
        return $responseLine | ConvertFrom-Json
    } finally {
        if ($null -ne $writer) { $writer.Dispose() }
        if ($null -ne $reader) { $reader.Dispose() }
        $client.Dispose()
    }
}

function Invoke-WrapperWatchProbe {
    param(
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$WaitForCoordinatorStatePath,
        [string]$WaitForWatchMarkerPath,
        [hashtable]$EnvironmentVariables = @{}
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$WrapperPath`" --root `"$Root`""
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
        $startInfo.EnvironmentVariables[[string]$entry.Key] = [string]$entry.Value
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $null = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 101
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        if ($WaitForCoordinatorStatePath -and
            -not (Wait-ForWatchReady -StatePath $WaitForCoordinatorStatePath)) {
            throw "Materialized wrapper did not start automatic watch within 30 seconds."
        }
        if ($WaitForWatchMarkerPath -and
            -not (Wait-ForPathState -Path $WaitForWatchMarkerPath -Present $true -TimeoutMilliseconds 30000)) {
            throw "Materialized wrapper did not publish its automatic watch marker within 30 seconds."
        }
        $search = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 102
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_search"
                arguments = [ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 }
            }
        })
        $status = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 103
            method = "tools/call"
            params = [ordered]@{ name = "codedb_status"; arguments = [ordered]@{} }
        })
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(10000)) {
            $process.Kill()
            throw "Materialized wrapper watch probe did not exit after stdin closed."
        }
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Materialized wrapper watch probe exited with code $($process.ExitCode).`n$stderr"
        }
        return [pscustomobject]@{
            SearchText = [string]$search.result.content[0].text
            StatusText = [string]$status.result.content[0].text
        }
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Invoke-WrapperToolProbe {
    param(
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ToolName,
        [Parameter(Mandatory = $true)]$Arguments,
        [string]$WaitForCoordinatorStatePath,
        [string]$WaitForWatchMarkerPath,
        [hashtable]$EnvironmentVariables = @{}
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$WrapperPath`" --root `"$Root`""
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($entry in $EnvironmentVariables.GetEnumerator()) {
        $startInfo.EnvironmentVariables[[string]$entry.Key] = [string]$entry.Value
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $null = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 201
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        if ($WaitForCoordinatorStatePath -and
            -not (Wait-ForWatchReady -StatePath $WaitForCoordinatorStatePath)) {
            throw "Materialized wrapper tool probe did not observe watcher ready within 30 seconds."
        }
        if ($WaitForWatchMarkerPath -and
            -not (Wait-ForPathState -Path $WaitForWatchMarkerPath -Present $true -TimeoutMilliseconds 30000)) {
            throw "Materialized wrapper tool probe did not observe the watch marker within 30 seconds."
        }
        $response = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 202
            method = "tools/call"
            params = [ordered]@{ name = $ToolName; arguments = $Arguments }
        })
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(10000)) {
            $process.Kill()
            throw "Materialized wrapper tool probe did not exit after stdin closed."
        }
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Materialized wrapper tool probe exited with code $($process.ExitCode).`n$stderr"
        }
        return [string]$response.result.content[0].text
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Invoke-WrapperToolErrorProbe {
    param(
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ToolName,
        [Parameter(Mandatory = $true)]$Arguments
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$WrapperPath`" --root `"$Root`""
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $null = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 301
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        $response = Invoke-WrapperRpcError -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 302
            method = "tools/call"
            params = [ordered]@{ name = $ToolName; arguments = $Arguments }
        })
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(10000)) {
            $process.Kill()
            throw "Materialized wrapper error probe did not exit after stdin closed."
        }
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Materialized wrapper error probe exited with code $($process.ExitCode).`n$stderr"
        }
        return [string]$response.error.message
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Invoke-ConcurrentWrapperQueries {
    param(
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $queries = @(
        "CODEDB_SINGLEFLIGHT_CONTRACT_A",
        "CODEDB_SINGLEFLIGHT_CONTRACT_A",
        "CODEDB_SINGLEFLIGHT_CONTRACT_B"
    )
    $entries = @()
    try {
        for ($index = 0; $index -lt $queries.Count; $index += 1) {
            $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = $nodePath
            $startInfo.Arguments = "`"$WrapperPath`" --root `"$Root`""
            $startInfo.WorkingDirectory = $Root
            $startInfo.UseShellExecute = $false
            $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardInput = $true
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $startInfo
            $null = $process.Start()
            $entry = [pscustomobject]@{
                Process = $process
                StderrTask = $process.StandardError.ReadToEndAsync()
                Query = $queries[$index]
            }
            $entries += $entry
            $null = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
                jsonrpc = "2.0"
                id = 301
                method = "initialize"
                params = [ordered]@{ protocolVersion = "2024-11-05" }
            })
        }

        for ($index = 0; $index -lt 2; $index += 1) {
            $requestLine = [ordered]@{
                jsonrpc = "2.0"
                id = 302
                method = "tools/call"
                params = [ordered]@{
                    name = "codedb_text_search"
                    arguments = [ordered]@{ query = $entries[$index].Query; language = "CSharp"; limit = 1 }
                }
            } | ConvertTo-Json -Compress -Depth 8
            $entries[$index].Process.StandardInput.WriteLine($requestLine)
            $entries[$index].Process.StandardInput.Flush()
        }
        Start-Sleep -Milliseconds 75
        $thirdRequest = [ordered]@{
            jsonrpc = "2.0"
            id = 302
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{ query = $entries[2].Query; language = "CSharp"; limit = 1 }
            }
        } | ConvertTo-Json -Compress -Depth 8
        $entries[2].Process.StandardInput.WriteLine($thirdRequest)
        $entries[2].Process.StandardInput.Flush()

        $texts = @()
        foreach ($entry in $entries) {
            $responseLine = $entry.Process.StandardOutput.ReadLine()
            if ([string]::IsNullOrWhiteSpace($responseLine)) {
                throw "Concurrent wrapper closed without responding for $($entry.Query)."
            }
            $response = $responseLine | ConvertFrom-Json
            if ($null -ne $response.PSObject.Properties["error"]) {
                throw "Concurrent wrapper returned an RPC error for $($entry.Query): $($response.error.message)"
            }
            $texts += [string]$response.result.content[0].text
            $entry.Process.StandardInput.Close()
        }

        foreach ($entry in $entries) {
            if (-not $entry.Process.WaitForExit(10000)) {
                $entry.Process.Kill()
                throw "Concurrent wrapper did not exit for $($entry.Query)."
            }
            $stderr = $entry.StderrTask.Result.Trim()
            if ($entry.Process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
                throw "Concurrent wrapper exited with code $($entry.Process.ExitCode) for $($entry.Query).`n$stderr"
            }
        }
        return $texts
    } finally {
        foreach ($entry in $entries) {
            if (-not $entry.Process.HasExited) {
                $entry.Process.Kill()
                $entry.Process.WaitForExit()
            }
            $entry.Process.Dispose()
        }
    }
}

function Assert-NoMaterializerResidue {
    $runtimePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer"
    if (-not (Test-Path -LiteralPath $runtimePath)) {
        return
    }

    foreach ($forbiddenPath in @(
        (Join-Path $runtimePath "materialize.lock"),
        (Join-Path $runtimePath "materialize-active.json"),
        (Join-Path $runtimePath "host-use-leases")
    )) {
        Assert-True -Condition (-not (Test-Path -LiteralPath $forbiddenPath)) -Message "Materializer mutation residue remains: $forbiddenPath"
    }
    Assert-Equal `
        -Actual @(Get-ChildItem -LiteralPath $runtimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count `
        -Expected 0 `
        -Message "Materializer transaction residue remains."
    $unexpectedFiles = @(Get-ChildItem -LiteralPath $runtimePath -Recurse -Force -File | Where-Object {
        -not [string]::Equals($_.Name, "upgrade-state.json", [StringComparison]::Ordinal)
    })
    Assert-Equal -Actual $unexpectedFiles.Count -Expected 0 -Message "Unexpected materializer runtime files remain."

    $upgradeStatePath = Join-Path $runtimePath "upgrade-state.json"
    if (Test-Path -LiteralPath $upgradeStatePath -PathType Leaf) {
        $upgradeState = Get-Content -LiteralPath $upgradeStatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual $upgradeState.managed_by -Expected "com.rice.ai-codedb" -Message "Persisted upgrade state manager mismatch."
        Assert-True -Condition ([string]$upgradeState.state -in @("INSTALLING", "SWITCHING", "ROLLBACK", "CURRENT", "CHECK_FAILED")) -Message "Persisted upgrade state is invalid."
    }
}

function Get-SentinelSnapshot {
    param(
        [string]$Root = $hostRoot,
        [string[]]$Paths = $sentinelPaths
    )

    $snapshot = @{}
    foreach ($relativePath in $Paths) {
        $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        $item = Get-Item -LiteralPath $path -Force
        $snapshot[$relativePath] = [pscustomobject]@{
            Sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            LastWriteTicks = $item.LastWriteTimeUtc.Ticks
        }
    }
    return $snapshot
}

function Assert-SentinelsUnchanged {
    param(
        [Parameter(Mandatory = $true)]$ExpectedSnapshot,
        [string]$Root = $hostRoot,
        [string[]]$Paths = $sentinelPaths
    )

    foreach ($relativePath in $Paths) {
        $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        Assert-True -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "Sentinel was removed: $relativePath"
        $item = Get-Item -LiteralPath $path -Force
        Assert-Equal -Actual (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -Expected $ExpectedSnapshot[$relativePath].Sha256 -Message "Sentinel hash changed: $relativePath."
        Assert-Equal -Actual $item.LastWriteTimeUtc.Ticks -Expected $ExpectedSnapshot[$relativePath].LastWriteTicks -Message "Sentinel timestamp changed: $relativePath."
    }
}

function Copy-CanonicalFilesToHost {
    foreach ($relativePath in $managedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
}

function Install-PriorGenerationFixture {
    param(
        [Parameter(Mandatory = $true)][string]$PriorGenerationId,
        [Parameter(Mandatory = $true)][int]$PriorPayloadSequence,
        [Parameter(Mandatory = $true)][string]$PriorPackageVersion
    )

    Clear-ManagedTestState
    $hostGenerationRuntimeRoot = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/host"
    if (Test-Path -LiteralPath $hostGenerationRuntimeRoot) {
        Remove-Item -LiteralPath $hostGenerationRuntimeRoot -Recurse -Force
    }

    foreach ($relativePath in $legacyManagedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $canonicalGenerationRoot = Join-Path $canonicalPayloadRoot "Generations\$generationId"
    $canonicalGenerationManifest = Get-Content -LiteralPath (Join-Path $canonicalGenerationRoot "generation-manifest.json") -Raw | ConvertFrom-Json
    $priorGenerationRelativeRoot = "AIWork/.runtime/codedb/host/generations/$PriorGenerationId"
    $priorGenerationRoot = Get-PathFromRelative -Root $hostRoot -RelativePath $priorGenerationRelativeRoot
    $priorGenerationFiles = New-Object System.Collections.Generic.List[object]
    foreach ($entry in @($canonicalGenerationManifest.files)) {
        $relativePath = [string]$entry.path
        $sourcePath = Get-PathFromRelative -Root $canonicalGenerationRoot -RelativePath $relativePath
        $targetPath = Get-PathFromRelative -Root $priorGenerationRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPath) | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force

        if ([string]::Equals($relativePath, "coordinator/codedb-watch-coordinator.mjs", [StringComparison]::Ordinal)) {
            $content = [System.IO.File]::ReadAllText($targetPath).Replace(
                [string]$canonicalPayloadManifest.package_version,
                $PriorPackageVersion)
            Write-Utf8File -Path $targetPath -Content $content
        } elseif ([string]::Equals($relativePath, "shared/codedb-host-use-gate.mjs", [StringComparison]::Ordinal)) {
            $content = [System.IO.File]::ReadAllText($targetPath).Replace($generationId, $PriorGenerationId)
            Write-Utf8File -Path $targetPath -Content $content
        }

        $priorGenerationFiles.Add([ordered]@{
            path = $relativePath
            sha256 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }) | Out-Null
    }

    $priorGenerationManifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        generation_id = $PriorGenerationId
        package_version = $PriorPackageVersion
        payload_version = $PriorGenerationId
        payload_sequence = $PriorPayloadSequence
        bootstrap_protocol = 1
        files = $priorGenerationFiles.ToArray()
    }
    $priorGenerationManifestPath = Join-Path $priorGenerationRoot "generation-manifest.json"
    Write-Utf8File -Path $priorGenerationManifestPath -Content (($priorGenerationManifest | ConvertTo-Json -Depth 8) + "`n")

    $pointer = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = $PriorPackageVersion
        payload_version = $PriorGenerationId
        payload_sequence = $PriorPayloadSequence
        generation_id = $PriorGenerationId
        generation_relative_path = $priorGenerationRelativeRoot
        generation_manifest_sha256 = (Get-FileHash -LiteralPath $priorGenerationManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        bootstrap_protocol = 1
    }
    $pointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    Write-Utf8File -Path $pointerPath -Content (($pointer | ConvertTo-Json -Depth 8) + "`n")

    $ownedTargets = New-Object System.Collections.Generic.List[string]
    foreach ($relativePath in $legacyManagedTargets) {
        $ownedTargets.Add($relativePath) | Out-Null
    }
    foreach ($entry in $priorGenerationFiles) {
        $ownedTargets.Add("$priorGenerationRelativeRoot/$($entry.path)") | Out-Null
    }
    $ownedTargets.Add("$priorGenerationRelativeRoot/generation-manifest.json") | Out-Null
    $ownedTargets.Add($currentPointerRelativePath) | Out-Null
    $markerFiles = @($ownedTargets | Sort-Object | ForEach-Object {
        $targetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $_
        [ordered]@{
            path = $_
            installed_sha256 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    })
    $marker = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = $PriorPackageVersion
        payload_version = $PriorGenerationId
        payload_sequence = $PriorPayloadSequence
        host_use_gate_version = 1
        generation_lease_version = 2
        generation_id = $PriorGenerationId
        bootstrap_protocol = 1
        current_pointer = $currentPointerRelativePath
        files = $markerFiles
    }
    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    Write-Utf8File -Path $markerPath -Content (($marker | ConvertTo-Json -Depth 8) + "`n")

    return [pscustomobject]@{
        GenerationRoot = $priorGenerationRoot
        GenerationTargets = @($ownedTargets | Where-Object { $_.StartsWith("$priorGenerationRelativeRoot/", [StringComparison]::Ordinal) })
        MarkerPath = $markerPath
        PointerPath = $pointerPath
    }
}

function Install-LegacyPoc21Fixture {
    Clear-ManagedTestState
    foreach ($relativePath in $legacyManagedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $legacyWrapperPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    Write-Utf8File -Path $legacyWrapperPath -Content "// byte-exact owned poc.21 wrapper fixture`n"
    $legacyFiles = @($legacyManagedTargets | Sort-Object | ForEach-Object {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $_
        [ordered]@{
            path = $_
            installed_sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    })
    $legacyMarker = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = "0.2.2"
        payload_version = "poc.21"
        payload_sequence = 21
        host_use_gate_version = 1
        files = $legacyFiles
    }
    Write-Utf8File `
        -Path (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) `
        -Content (($legacyMarker | ConvertTo-Json -Depth 8) + "`n")
}

function Install-OwnedLegacyRedeployFixture {
    param(
        [string]$PackageVersion = "0.2.0",
        [string]$PayloadVersion = "poc.16",
        [int]$PayloadSequence = 16
    )

    Clear-ManagedTestState
    foreach ($relativePath in $legacyManagedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $legacyWrapperPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    Write-Utf8File -Path $legacyWrapperPath -Content "// byte-exact owned $PayloadVersion wrapper fixture`n"
    $legacyFiles = @($legacyManagedTargets | Sort-Object | ForEach-Object {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $_
        [ordered]@{
            path = $_
            installed_sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    })
    $legacyMarker = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = $PackageVersion
        payload_version = $PayloadVersion
        payload_sequence = $PayloadSequence
        host_use_gate_version = 1
        files = $legacyFiles
    }
    Write-Utf8File `
        -Path (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) `
        -Content (($legacyMarker | ConvertTo-Json -Depth 8) + "`n")
}

function Assert-CanonicalFilesInstalled {
    param([string]$Root = $hostRoot)

    foreach ($relativePath in $managedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        Assert-True -Condition (Test-Path -LiteralPath $target -PathType Leaf) -Message "Managed target is missing: $relativePath"
        Assert-Equal -Actual (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -Expected (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -Message "Managed target hash mismatch: $relativePath."
    }
}

function Assert-CanonicalFilesRemoved {
    param([string]$Root = $hostRoot)

    foreach ($relativePath in $managedTargets) {
        Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $Root -RelativePath $relativePath))) -Message "Managed target remains after removal: $relativePath"
    }
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $Root -RelativePath $markerRelativePath))) -Message "Ownership marker remains after removal."
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $Root -RelativePath $generationTargetPrefix.TrimEnd('/')))) `
        -Message "Empty managed generation directory remains after removal or rollback."
}

function New-SyntheticPayload {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$PayloadVersion,
        [Parameter(Mandatory = $true)]$Entries,
        [string]$PackageVersion = "0.1.0-test",
        [int]$PayloadSequence = 0
    )

    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    $resolvedPayloadSequence = if ($PayloadSequence -gt 0) {
        $PayloadSequence
    } elseif ($PayloadVersion -eq "test.1") {
        1
    } else {
        2
    }
    $manifestFiles = New-Object System.Collections.Generic.List[object]
    foreach ($relativePath in @($Entries.Keys | Sort-Object)) {
        $sourceRelativePath = if ($canonicalSourceByTarget.ContainsKey($relativePath)) {
            [string]$canonicalSourceByTarget[$relativePath]
        } else {
            $relativePath
        }
        $sourcePath = Get-PathFromRelative -Root $Root -RelativePath $sourceRelativePath
        Write-Utf8File -Path $sourcePath -Content ([string]$Entries[$relativePath])
        $manifestFiles.Add([ordered]@{
            source = $sourceRelativePath
            target = $relativePath
            sha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }

    $generationManifestTarget = $generationTargetPrefix + "generation-manifest.json"
    $generationManifestEntry = @($manifestFiles | Where-Object {
        [string]::Equals([string]$_.target, $generationManifestTarget, [StringComparison]::OrdinalIgnoreCase)
    }) | Select-Object -First 1
    $currentPointerEntry = @($manifestFiles | Where-Object {
        [string]::Equals([string]$_.target, $currentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)
    }) | Select-Object -First 1
    if (($null -eq $generationManifestEntry) -ne ($null -eq $currentPointerEntry)) {
        throw "Synthetic payload must include both generation metadata targets or neither."
    }
    if ($null -ne $generationManifestEntry) {
        $generationManifestPath = Get-PathFromRelative -Root $Root -RelativePath ([string]$generationManifestEntry.source)
        $generationManifest = Get-Content -LiteralPath $generationManifestPath -Raw | ConvertFrom-Json
        $generationManifest.package_version = $PackageVersion
        $generationManifest.payload_version = $PayloadVersion
        $generationManifest.payload_sequence = $resolvedPayloadSequence
        Write-Utf8File -Path $generationManifestPath -Content (($generationManifest | ConvertTo-Json -Depth 8) + "`n")
        $generationManifestEntry.sha256 = (Get-FileHash -LiteralPath $generationManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()

        $currentPointerPath = Get-PathFromRelative -Root $Root -RelativePath ([string]$currentPointerEntry.source)
        $currentPointer = Get-Content -LiteralPath $currentPointerPath -Raw | ConvertFrom-Json
        $currentPointer.package_version = $PackageVersion
        $currentPointer.payload_version = $PayloadVersion
        $currentPointer.payload_sequence = $resolvedPayloadSequence
        $currentPointer.generation_manifest_sha256 = [string]$generationManifestEntry.sha256
        Write-Utf8File -Path $currentPointerPath -Content (($currentPointer | ConvertTo-Json -Depth 8) + "`n")
        $currentPointerEntry.sha256 = (Get-FileHash -LiteralPath $currentPointerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }

    $manifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = $PackageVersion
        payload_version = $PayloadVersion
        payload_sequence = $resolvedPayloadSequence
        generation_id = $generationId
        bootstrap_protocol = 1
        current_pointer_target = $currentPointerRelativePath
        retired_targets = @()
        files = $manifestFiles.ToArray()
    }
    Write-Utf8File -Path (Join-Path $Root "payload-manifest.json") -Content (($manifest | ConvertTo-Json -Depth 8) + "`n")
    return $Root
}

function Clear-ManagedTestState {
    foreach ($relativePath in $managedTargets + @($markerRelativePath)) {
        $path = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        if (Test-Path -LiteralPath $path) {
            Set-ItemProperty -LiteralPath $path -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

$packageSnapshotBefore = $null
$sentinelSnapshot = $null
try {
    Assert-True -Condition (Test-Path -LiteralPath $materializerPath -PathType Leaf) -Message "Materializer script is missing."
    Assert-True -Condition (Test-Path -LiteralPath $canonicalPayloadRoot -PathType Container) -Message "Canonical payload root is missing."
    Assert-Equal -Actual $canonicalPayloadManifest.package_version -Expected "0.2.4" -Message "Canonical package version mismatch."
    Assert-Equal -Actual $canonicalPayloadManifest.payload_version -Expected $generationId -Message "Canonical payload version mismatch."
    Assert-Equal -Actual $canonicalPayloadManifest.payload_sequence -Expected 27 -Message "Canonical payload sequence mismatch."
    Assert-Equal -Actual $canonicalPayloadManifest.generation_id -Expected $generationId -Message "Canonical generation id mismatch."
    Assert-Equal -Actual $legacyManagedTargets.Count -Expected 21 -Message "Legacy target count mismatch."
    Assert-Equal -Actual $generationManagedTargets.Count -Expected 21 -Message "Generation target count mismatch."
    Assert-Equal -Actual $pointerManagedTargets.Count -Expected 1 -Message "Current-pointer target count mismatch."
    Assert-Equal -Actual $managedTargets.Count -Expected 43 -Message "Total managed target count mismatch."
    New-TestHost -Root $hostRoot
    if (-not $isEmbeddedLayout) {
        New-TestHost -Root $productionProjectRoot
        Remove-Item -LiteralPath (Join-Path $productionProjectRoot $fixtureMarkerName) -Force
    }
    $packageSnapshotBefore = Get-FileSnapshot -Root $packageRoot
    $sentinelSnapshot = Get-SentinelSnapshot

    $productionHostBefore = Get-ManagedPayloadSnapshot -Root $productionProjectRoot
    $productionAuthorizationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot -OmitPocFixture
    Assert-Result -Result $productionAuthorizationGuard -ExitCode 4 -Label "Production authorization guard"
    Assert-True -Condition ($productionAuthorizationGuard.Text.Contains("requires explicit -PocFixture or -TrackedHostAuthorizationPath")) -Message "Production authorization guard did not identify the missing explicit mode."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $productionProjectRoot) -Expected $productionHostBefore -Message "Production authorization guard changed the production host payload."
    $productionFixtureGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot
    Assert-Result -Result $productionFixtureGuard -ExitCode 4 -Label "Production fixture guard"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $productionProjectRoot) -Expected $productionHostBefore -Message "Production fixture guard changed the production host payload."
    Write-Host "[OK] Missing authorization and fixture mode both rejected the production project root."

    $junctionRunId = [guid]::NewGuid().ToString("N")
    $junctionTargetRoot = Join-Path $runRoot "junction-target"
    New-TestHost -Root (Join-Path $junctionTargetRoot "fixture") -RunId $junctionRunId
    $junctionPath = Join-Path $pocRoot $junctionRunId
    New-Item -ItemType Junction -Path $junctionPath -Target $junctionTargetRoot | Out-Null
    $junctionProjectRoot = Join-Path $junctionPath "fixture"
    $junctionBefore = Get-FileSnapshot -Root (Join-Path $junctionTargetRoot "fixture")
    $junctionGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $junctionProjectRoot
    Assert-Result -Result $junctionGuard -ExitCode 2 -Label "Junction ancestor guard"
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $junctionTargetRoot "fixture")) -Expected $junctionBefore -Message "Junction ancestor guard changed its target."
    [System.IO.Directory]::Delete($junctionPath)
    $junctionPath = $null
    Write-Host "[OK] POC mutation guard rejected a fixture below a junction ancestor."

    New-TrackedHostTestProject -Root $trackedHostRoot
    $trackedSentinelSnapshot = Get-SentinelSnapshot -Root $trackedHostRoot -Paths $trackedHostSentinelPaths
    $trackedManagedBefore = Get-ManagedPayloadSnapshot -Root $trackedHostRoot

    $missingTrackedAuthorization = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture
    Assert-Result -Result $missingTrackedAuthorization -ExitCode 4 -Label "Missing tracked-host authorization"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $trackedHostRoot) -Expected $trackedManagedBefore -Message "Missing tracked-host authorization changed managed files."

    $validSyncAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    $readOnlyAuthorization = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validSyncAuthorization
    Assert-Result -Result $readOnlyAuthorization -ExitCode 4 -Label "Read-only authorization misuse"
    Assert-True -Condition ($readOnlyAuthorization.Text.Contains("valid only for Sync or Remove")) -Message "Read-only authorization misuse did not fail explicitly."

    $ambiguousAuthorization = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -TrackedHostAuthorizationPath $validSyncAuthorization
    Assert-Result -Result $ambiguousAuthorization -ExitCode 4 -Label "Ambiguous mutation authorization"
    Assert-True -Condition ($ambiguousAuthorization.Text.Contains("mutually exclusive")) -Message "Ambiguous fixture/tracked-host authorization did not fail explicitly."

    $outsideAuthorization = Join-Path $trackedHostRoot ("AIWork\.runtime\codedb\payload-materializer\" + (Split-Path -Leaf $validSyncAuthorization))
    Copy-Item -LiteralPath $validSyncAuthorization -Destination $outsideAuthorization -Force
    $outsideAuthorizationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $outsideAuthorization
    Assert-Result -Result $outsideAuthorizationGuard -ExitCode 4 -Label "Authorization path boundary"

    $trackedAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    $trackedAuthorizationRelative = Get-RelativeFilePath -Root $trackedHostRoot -Path $trackedAuthorization
    $null = Invoke-TrackedHostGit -Root $trackedHostRoot -Arguments @("add", "-f", "--", $trackedAuthorizationRelative)
    $trackedAuthorizationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $trackedAuthorization
    Assert-Result -Result $trackedAuthorizationGuard -ExitCode 4 -Label "Tracked authorization refusal"
    Assert-True -Condition ($trackedAuthorizationGuard.Text.Contains("must be Git ignored and untracked")) -Message "Tracked authorization was not rejected by its ownership boundary."
    $null = Invoke-TrackedHostGit -Root $trackedHostRoot -Arguments @("reset", "--", $trackedAuthorizationRelative)

    $projectMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        project_root = [System.IO.Path]::GetDirectoryName($trackedHostRoot)
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $projectMismatchAuthorization) -ExitCode 4 -Label "Authorization project binding"

    $gitMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        git_head = (("0" * 40) -join "")
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $gitMismatchAuthorization) -ExitCode 4 -Label "Authorization Git binding"

    $actionMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Remove"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $actionMismatchAuthorization) -ExitCode 4 -Label "Authorization action binding"

    $payloadMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        payload_manifest_sha256 = (("f" * 64) -join "")
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $payloadMismatchAuthorization) -ExitCode 4 -Label "Authorization payload binding"

    $acknowledgementMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        acknowledgement = "not authorized"
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $acknowledgementMismatchAuthorization) -ExitCode 4 -Label "Authorization acknowledgement"

    $unknownPropertyAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        unexpected = "reject"
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $unknownPropertyAuthorization) -ExitCode 4 -Label "Authorization schema closure"

    $invalidShapeAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    Write-Utf8File -Path $invalidShapeAuthorization -Content "[]`n"
    $invalidShapeGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $invalidShapeAuthorization
    Assert-Result -Result $invalidShapeGuard -ExitCode 4 -Label "Authorization JSON shape"
    Assert-True -Condition ($invalidShapeGuard.Text.Contains("must be one JSON object")) -Message "Authorization JSON shape did not fail explicitly."

    $arrayShapeAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    Write-Utf8File -Path $arrayShapeAuthorization -Content "[{}]`n"
    $arrayShapeGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $arrayShapeAuthorization
    Assert-Result -Result $arrayShapeGuard -ExitCode 4 -Label "Authorization JSON array shape"
    Assert-True -Condition ($arrayShapeGuard.Text.Contains("must be one JSON object")) -Message "Authorization JSON array shape did not fail explicitly."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $trackedHostRoot) -Expected $trackedManagedBefore -Message "Rejected tracked-host authorizations changed managed files."
    Assert-SentinelsUnchanged -ExpectedSnapshot $trackedSentinelSnapshot -Root $trackedHostRoot -Paths $trackedHostSentinelPaths

    $authorizedSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validSyncAuthorization -ConfirmLegacyMcpStopped
    Assert-Result -Result $authorizedSync -ExitCode 0 -Label "Authorized tracked-host Sync"
    Assert-True -Condition ($authorizedSync.Text.Contains("[AUTHORIZED] Tracked-host Sync authorization")) -Message "Authorized Sync did not report the accepted authorization."
    Assert-CanonicalFilesInstalled -Root $trackedHostRoot
    $trackedMarkerPath = Get-PathFromRelative -Root $trackedHostRoot -RelativePath $markerRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $trackedMarkerPath -PathType Leaf) -Message "Authorized Sync did not write the ownership marker."
    Assert-LfOnlyFile -Path $trackedMarkerPath -Label "Authorized tracked-host ownership marker"
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture) -ExitCode 0 -Label "Tracked-host Verify without mutation authorization"

    $beforeWrongActionRemove = Get-ManagedPayloadSnapshot -Root $trackedHostRoot
    $wrongActionRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validSyncAuthorization
    Assert-Result -Result $wrongActionRemove -ExitCode 4 -Label "Sync authorization cannot Remove"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $trackedHostRoot) -Expected $beforeWrongActionRemove -Message "Wrong-action Remove changed managed files."

    $validRemoveAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Remove"
    $authorizedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validRemoveAuthorization
    Assert-Result -Result $authorizedRemove -ExitCode 0 -Label "Authorized tracked-host Remove"
    Assert-True -Condition ($authorizedRemove.Text.Contains("[AUTHORIZED] Tracked-host Remove authorization")) -Message "Authorized Remove did not report the accepted authorization."
    Assert-CanonicalFilesRemoved -Root $trackedHostRoot
    Assert-SentinelsUnchanged -ExpectedSnapshot $trackedSentinelSnapshot -Root $trackedHostRoot -Paths $trackedHostSentinelPaths
    $trackedMaterializerRuntime = Join-Path $trackedHostRoot "AIWork\.runtime\codedb\payload-materializer"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $trackedMaterializerRuntime "materialize-active.json"))) -Message "Tracked-host materializer active marker remained after Remove."
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $trackedMaterializerRuntime -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 0) -Message "Tracked-host transaction residue remained after Remove."
    Write-Host "[OK] Tracked-host authorization rejected invalid bindings and permitted only the exact authorized Sync/Remove actions."

    $dryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $dryRun -ExitCode 0 -Label "Empty install DryRun"
    Assert-True -Condition ($dryRun.Text -match '\[PLAN\] Missing:') -Message "Empty install DryRun did not report missing files."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Empty install plan is read-only."

    $beforeFailedInstall = Get-FileSnapshot -Root $hostRoot
    $failedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 1
    Assert-Result -Result $failedInstall -ExitCode 6 -Label "Injected install failure"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeFailedInstall -Message "Injected install failure did not restore the host file tree."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Mid-install failure restored the pre-sync file state."

    $beforeCrashedInstall = Get-FileSnapshot -Root $hostRoot
    $crashedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1
    Assert-Result -Result $crashedInstall -ExitCode 86 -Label "Injected install process crash"
    Assert-True -Condition ($crashedInstall.Text.Contains("Injected POC process crash after mutation 1.")) -Message "Injected install process crash did not report its mutation boundary."
    $materializerRuntimePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer"
    Assert-True -Condition (Test-Path -LiteralPath $materializerRuntimePath -PathType Container) -Message "Injected install process crash left no persistent recovery transaction."
    $firstInstallTargetRelativePath = @($managedTargets | Where-Object { $_ -ne $currentPointerRelativePath } | Sort-Object)[0]
    $crashedInstallTarget = Get-PathFromRelative -Root $hostRoot -RelativePath $firstInstallTargetRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $crashedInstallTarget -PathType Leaf) -Message "Injected install process crash did not stop after the expected first atomic publication."
    Write-Utf8File -Path $crashedInstallTarget -Content "external change after interrupted materialization`n"
    $blockedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $blockedRecovery -ExitCode 7 -Label "Externally changed recovery refusal"
    Assert-Equal -Actual (Get-Content -LiteralPath $crashedInstallTarget -Raw) -Expected "external change after interrupted materialization`n" -Message "Recovery refusal overwrote an external post-crash change."
    Assert-True -Condition (Test-Path -LiteralPath $materializerRuntimePath -PathType Container) -Message "Recovery refusal discarded the persistent transaction evidence."
    Copy-Item -LiteralPath (Get-CanonicalPayloadSourcePath -TargetRelativePath $firstInstallTargetRelativePath) -Destination $crashedInstallTarget -Force
    $recoveredInstall = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $recoveredInstall -ExitCode 0 -Label "Install crash recovery"
    Assert-True -Condition ($recoveredInstall.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Install crash recovery did not report the interrupted Sync rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeCrashedInstall -Message "Persistent install recovery did not restore the exact pre-sync fixture."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Recovery refused external drift, then a new process restored the interrupted install from its persistent journal."

    $beforePointerFailure = Get-FileSnapshot -Root $hostRoot
    $pointerFailure = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 43
    Assert-Result -Result $pointerFailure -ExitCode 6 -Label "Injected current-pointer publication failure"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforePointerFailure -Message "Current-pointer publication failure did not restore the exact pre-sync tree."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue

    $beforePointerCrash = Get-FileSnapshot -Root $hostRoot
    $pointerCrash = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 43
    Assert-Result -Result $pointerCrash -ExitCode 86 -Label "Injected current-pointer publication crash"
    $crashedPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $crashedPointerPath -PathType Leaf) -Message "Pointer-boundary crash did not publish current.json at mutation 43."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath))) -Message "Pointer-boundary crash unexpectedly published the ownership marker."
    $pointerCrashRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -ConfirmLegacyMcpStopped
    Assert-Result -Result $pointerCrashRecovery -ExitCode 0 -Label "Current-pointer crash recovery"
    Assert-True -Condition ($pointerCrashRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Pointer-boundary crash recovery did not report rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforePointerCrash -Message "Pointer-boundary crash recovery did not restore the exact pre-sync tree."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Current generation pointer failure and crash both rolled generation publication back to the exact old state."

    $priorGenerationCases = @(
        [pscustomobject]@{ GenerationId = "poc.22"; Sequence = 22; PackageVersion = "0.2.3"; LiveLease = $false },
        [pscustomobject]@{ GenerationId = "poc.23"; Sequence = 23; PackageVersion = "0.2.4-preview.1"; LiveLease = $true },
        [pscustomobject]@{ GenerationId = "poc.24"; Sequence = 24; PackageVersion = "0.2.4-preview.2"; LiveLease = $false },
        [pscustomobject]@{ GenerationId = "poc.25"; Sequence = 25; PackageVersion = "0.2.4-preview.3"; LiveLease = $false },
        [pscustomobject]@{ GenerationId = "poc.26"; Sequence = 26; PackageVersion = "0.2.4-preview.4"; LiveLease = $false }
    )
    foreach ($priorGenerationCase in $priorGenerationCases) {
        $priorFixture = Install-PriorGenerationFixture `
            -PriorGenerationId $priorGenerationCase.GenerationId `
            -PriorPayloadSequence $priorGenerationCase.Sequence `
            -PriorPackageVersion $priorGenerationCase.PackageVersion
        $priorLeasePath = $null
        if ($priorGenerationCase.LiveLease) {
            $priorLeasePath = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $priorGenerationCase.GenerationId
        }

        $priorUpgradeDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $priorUpgradeDryRun -ExitCode 0 -Label "$($priorGenerationCase.GenerationId) to $generationId DryRun"
        Assert-True `
            -Condition (-not $priorUpgradeDryRun.Text.Contains("UntrustedOwnedPath")) `
            -Message "$($priorGenerationCase.GenerationId) DryRun rejected package-owned generation targets as untrusted."
        Assert-True `
            -Condition ($priorUpgradeDryRun.Text.Contains("[UPGRADE_READY] Owned generation $($priorGenerationCase.GenerationId) can migrate to generation $generationId while existing leases drain naturally.")) `
            -Message "$($priorGenerationCase.GenerationId) DryRun did not advertise the supported generation upgrade."

        $priorUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $priorUpgrade -ExitCode 0 -Label "$($priorGenerationCase.GenerationId) to $generationId Upgrade"
        Assert-True -Condition (-not $priorUpgrade.Text.Contains("UntrustedOwnedPath")) -Message "$($priorGenerationCase.GenerationId) Upgrade reported an untrusted owned target."
        Assert-CanonicalFilesInstalled
        foreach ($relativePath in $priorFixture.GenerationTargets) {
            Assert-True `
                -Condition (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath) -PathType Leaf) `
                -Message "Automatic Upgrade removed retained $($priorGenerationCase.GenerationId) file: $relativePath"
        }
        $selectedPointer = Get-Content -LiteralPath $priorFixture.PointerPath -Raw | ConvertFrom-Json
        Assert-Equal -Actual $selectedPointer.generation_id -Expected $generationId -Message "$($priorGenerationCase.GenerationId) Upgrade did not select $generationId."

        if ($priorGenerationCase.LiveLease) {
            Assert-True -Condition (Test-Path -LiteralPath $priorLeasePath -PathType Leaf) -Message "Automatic Upgrade removed the live $($priorGenerationCase.GenerationId) lease."
            $leasedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
            Assert-Result -Result $leasedRemove -ExitCode 4 -Label "$($priorGenerationCase.GenerationId) live-lease Remove gate"
            Assert-True `
                -Condition ($leasedRemove.Text.Contains("[ACTIVE] generation $($priorGenerationCase.GenerationId) mcp PID $PID")) `
                -Message "Remove did not report the live $($priorGenerationCase.GenerationId) generation lease."
            Assert-True -Condition (Test-Path -LiteralPath $priorFixture.GenerationRoot -PathType Container) -Message "Leased prior generation was removed before drain."
            Remove-Item -LiteralPath $priorLeasePath -Force
        }

        $priorCleanup = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $priorCleanup -ExitCode 0 -Label "$($priorGenerationCase.GenerationId) post-upgrade cleanup Remove"
        Assert-CanonicalFilesRemoved
        Assert-True -Condition (-not (Test-Path -LiteralPath $priorFixture.GenerationRoot)) -Message "Remove retained drained $($priorGenerationCase.GenerationId) generation content."
        Assert-NoMaterializerResidue
    }
    Write-Host "[OK] poc.22 through poc.26 upgraded to poc.27 without untrusted-path conflicts; live poc.23 content remained protected until lease drain."

    Install-LegacyPoc21Fixture
    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    $rollbackSelectionPaths = @($legacyManagedTargets + @($markerRelativePath, $currentPointerRelativePath))
    $beforeWatcherHandoffFailure = Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackSelectionPaths
    $watcherHandoffFailure = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TestFailWatcherHandoff
    Assert-Result -Result $watcherHandoffFailure -ExitCode 6 -Label "Injected upgrade watcher-handoff failure"
    Assert-True -Condition ($watcherHandoffFailure.Text.Contains("[ROLLBACK] Restoring the last known-good host selection.")) -Message "Watcher-handoff failure did not report selection rollback."
    Assert-True -Condition ($watcherHandoffFailure.Text.Contains("Injected POC watcher readiness failure.")) -Message "Watcher-handoff failure did not reach the readiness boundary. Output: $($watcherHandoffFailure.Text)"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackSelectionPaths) -Expected $beforeWatcherHandoffFailure -Message "Watcher-handoff rollback did not restore the exact poc.21 selection."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath))) -Message "Watcher-handoff rollback left the failed current pointer selected."
    foreach ($relativePath in $generationManagedTargets) {
        $retainedGenerationTarget = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        $retainedGenerationSource = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        Assert-True -Condition (Test-Path -LiteralPath $retainedGenerationTarget -PathType Leaf) -Message "Watcher-handoff rollback removed validated immutable generation file: $relativePath"
        Assert-Equal `
            -Actual (Get-FileHash -LiteralPath $retainedGenerationTarget -Algorithm SHA256).Hash `
            -Expected (Get-FileHash -LiteralPath $retainedGenerationSource -Algorithm SHA256).Hash `
            -Message "Retained immutable generation hash mismatch: $relativePath."
    }
    $failedUpgradeStatePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\upgrade-state.json"
    $failedUpgradeState = Get-Content -LiteralPath $failedUpgradeStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $failedUpgradeState.state -Expected "CHECK_FAILED" -Message "Watcher-handoff rollback did not persist CHECK_FAILED diagnostics."
    Assert-Equal -Actual $failedUpgradeState.generation_id -Expected $generationId -Message "Watcher-handoff rollback diagnostic generation mismatch."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Failed watcher handoff restored poc.21 selection and retained a complete, unselected poc.27 generation for safe retry."

    $failedCandidateCleanup = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $failedCandidateCleanup -ExitCode 0 -Label "Failed-upgrade candidate cleanup Remove"
    Assert-CanonicalFilesRemoved
    Assert-True -Condition (-not (Test-Path -LiteralPath $failedUpgradeStatePath)) -Message "Remove retained failed-upgrade diagnostics after deleting the legacy installation."
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Join-Path $hostRoot "AIWork\.runtime\codedb\host"))) `
        -Message "Remove retained the empty host-generation runtime after deleting an unselected candidate."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Remove transactionally deleted the restored legacy selection, unselected package generation, and upgrade diagnostics."

    foreach ($recoveryAction in @("Sync", "Remove")) {
        Install-LegacyPoc21Fixture
        $beforeAutomaticCrash = Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackSelectionPaths
        $legacyHostUseGate = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
        $recoveryWatcherProcess = $null
        try {
            $recoveryWatcherProcess = Start-LegacyHostUseLeaseProcess -GatePath $legacyHostUseGate -Owner "watcher"
            $crashedUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 2
            Assert-Result -Result $crashedUpgrade -ExitCode 86 -Label "$recoveryAction-triggered automatic Upgrade crash"
            Assert-True -Condition ($crashedUpgrade.Text.Contains("Injected POC process crash after mutation 2.")) -Message "Automatic Upgrade crash did not report its mutation boundary."
            Assert-True `
                -Condition (@(Get-ChildItem -LiteralPath $materializerRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 1) `
                -Message "Automatic Upgrade crash did not retain exactly one recovery transaction."

            $blockedAfterRecovery = Invoke-Materializer -Action $recoveryAction -PayloadRoot $canonicalPayloadRoot
            Assert-Result -Result $blockedAfterRecovery -ExitCode 4 -Label "$recoveryAction automatic-upgrade recovery with active watcher"
            Assert-True -Condition ($blockedAfterRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "$recoveryAction did not recover the interrupted automatic Upgrade before enforcing leases."
            Assert-True -Condition ($blockedAfterRecovery.Text.Contains("[ACTIVE] watcher PID $($recoveryWatcherProcess.Id)")) -Message "$recoveryAction did not report the still-active legacy watcher after recovery."
            Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackSelectionPaths) -Expected $beforeAutomaticCrash -Message "$recoveryAction recovery did not restore the exact poc.21 selection."
            Assert-Equal `
                -Actual @(Get-ChildItem -LiteralPath $materializerRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count `
                -Expected 0 `
                -Message "$recoveryAction left the recovered automatic-upgrade transaction behind."
            $recoveredUpgradeState = Get-Content -LiteralPath $failedUpgradeStatePath -Raw | ConvertFrom-Json
            Assert-Equal -Actual $recoveredUpgradeState.state -Expected "CHECK_FAILED" -Message "$recoveryAction recovery did not persist CHECK_FAILED diagnostics."
            foreach ($relativePath in $generationManagedTargets) {
                Assert-True -Condition (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath) -PathType Leaf) -Message "$recoveryAction recovery removed retained immutable generation file: $relativePath"
            }
        } finally {
            if ($null -ne $recoveryWatcherProcess) {
                Stop-LegacyHostUseLeaseProcess -Process $recoveryWatcherProcess -Owner "watcher"
            }
        }

        if ($recoveryAction -eq "Sync") {
            $retryUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
            Assert-Result -Result $retryUpgrade -ExitCode 0 -Label "$recoveryAction recovery retry Upgrade"
            Assert-CanonicalFilesInstalled
            Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "$recoveryAction recovery cleanup Remove"
        } else {
            $candidateCleanup = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
            Assert-Result -Result $candidateCleanup -ExitCode 0 -Label "$recoveryAction recovered candidate cleanup"
        }
        Assert-CanonicalFilesRemoved
        Assert-True -Condition (-not (Test-Path -LiteralPath $failedUpgradeStatePath)) -Message "$recoveryAction recovery cleanup retained upgrade-state.json."
        Assert-NoMaterializerResidue
    }
    Write-Host "[OK] Sync and Remove recovered an interrupted automatic Upgrade before reporting the active legacy watcher lease."

    Install-LegacyPoc21Fixture
    $legacyHostUseGate = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
    $legacyWatchManagerPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1"
    $legacyWatchManagerSource = Get-CanonicalPayloadSourcePath -TargetRelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1"
    $driftRecoveryWatcherProcess = $null
    try {
        $driftRecoveryWatcherProcess = Start-LegacyHostUseLeaseProcess -GatePath $legacyHostUseGate -Owner "watcher"
        $driftCrash = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 2
        Assert-Result -Result $driftCrash -ExitCode 86 -Label "Legacy watcher identity Upgrade crash"
        Write-Utf8File -Path $legacyWatchManagerPath -Content "external watcher drift after interrupted upgrade`n"

        $driftedWatcherRecovery = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $driftedWatcherRecovery -ExitCode 7 -Label "Drifted legacy watcher recovery refusal"
        Assert-True -Condition ($driftedWatcherRecovery.Text.Contains("Rollback watcher manager no longer matches its transaction identity.")) -Message "Automatic recovery did not reject the drifted legacy watcher identity."
        Assert-True `
            -Condition (@(Get-ChildItem -LiteralPath $materializerRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 1) `
            -Message "Drifted watcher recovery discarded the unresolved automatic-upgrade journal."
    } finally {
        if ($null -ne $driftRecoveryWatcherProcess) {
            Stop-LegacyHostUseLeaseProcess -Process $driftRecoveryWatcherProcess -Owner "watcher"
        }
    }
    Copy-Item -LiteralPath $legacyWatchManagerSource -Destination $legacyWatchManagerPath -Force
    $repairedWatcherRecovery = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $repairedWatcherRecovery -ExitCode 0 -Label "Repaired legacy watcher recovery"
    Assert-True -Condition ($repairedWatcherRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Repaired watcher retry did not recover the retained automatic-upgrade journal."
    Assert-CanonicalFilesInstalled
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Repaired legacy watcher recovery cleanup Remove"
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Automatic recovery rejected legacy watcher SHA drift and retained its journal until byte-exact repair."

    Install-LegacyPoc21Fixture

    $preHandoffCrash = Invoke-Materializer `
        -Action "Upgrade" `
        -PayloadRoot $canonicalPayloadRoot `
        -TestCrashBeforeWatcherHandoff
    Assert-Result -Result $preHandoffCrash -ExitCode 86 -Label "Post-plan current pre-handoff Upgrade crash"
    Assert-True `
        -Condition ($preHandoffCrash.Text.Contains("Injected POC process crash after post-plan current and before watcher handoff.")) `
        -Message "Pre-handoff crash did not report its exact transaction boundary."
    Assert-CanonicalFilesInstalled
    $pendingAutomaticTransactions = @(Get-ChildItem -LiteralPath $materializerRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $pendingAutomaticTransactions.Count -Expected 1 -Message "Pre-handoff crash did not retain exactly one automatic transaction."
    $pendingAutomaticJournalPath = Join-Path $pendingAutomaticTransactions[0].FullName "transaction.json"
    $pendingAutomaticJournalText = Get-Content -LiteralPath $pendingAutomaticJournalPath -Raw
    $pendingAutomaticJournal = $pendingAutomaticJournalText | ConvertFrom-Json
    Assert-Equal -Actual $pendingAutomaticJournal.automatic_upgrade -Expected $true -Message "Pre-handoff crash journal lost its automatic-upgrade identity."
    Assert-Equal -Actual $pendingAutomaticJournal.operation -Expected "sync" -Message "Pre-handoff crash journal operation mismatch."
    $pendingActiveMarkerPath = Join-Path $materializerRuntimePath "materialize-active.json"
    Assert-True -Condition (Test-Path -LiteralPath $pendingActiveMarkerPath -PathType Leaf) -Message "Pre-handoff crash did not retain its materializer active marker."
    Assert-True `
        -Condition (-not [string]::Equals(
            (Get-FileHash -LiteralPath $pendingActiveMarkerPath -Algorithm SHA256).Hash,
            (Get-FileHash -LiteralPath $markerPath -Algorithm SHA256).Hash,
            [StringComparison]::OrdinalIgnoreCase)) `
        -Message "Recovery fixture unexpectedly made the active marker indistinguishable from the installed payload marker."
    $pendingUpgradeState = Get-Content -LiteralPath $failedUpgradeStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $pendingUpgradeState.state -Expected "SWITCHING" -Message "Pre-handoff crash did not remain in SWITCHING."

    $ordinaryJournal = $pendingAutomaticJournalText | ConvertFrom-Json
    $ordinaryJournal.automatic_upgrade = $false
    $ordinaryJournal.previous_watcher_manager = $null
    $ordinaryJournal.previous_watcher_manager_sha256 = $null
    Write-Utf8File -Path $pendingAutomaticJournalPath -Content (($ordinaryJournal | ConvertTo-Json -Depth 8) + "`n")
    $ordinaryPendingDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $ordinaryPendingDryRun -ExitCode 0 -Label "Ordinary transaction is not automatic recovery"
    Assert-True -Condition (-not $ordinaryPendingDryRun.Text.Contains("Interrupted automatic host upgrade")) -Message "DryRun elevated an ordinary Sync journal into automatic recovery."
    Assert-True -Condition ($ordinaryPendingDryRun.Text.Contains("[OK] Host payload is current.")) -Message "Ordinary pending journal unexpectedly changed the current payload classification."
    Write-Utf8File -Path $pendingAutomaticJournalPath -Content $pendingAutomaticJournalText

    $beforePendingRecoveryDryRun = Get-FileSnapshot -Root $hostRoot
    $pendingRecoveryDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $pendingRecoveryDryRun -ExitCode 0 -Label "Pending automatic recovery DryRun"
    Assert-True `
        -Condition ($pendingRecoveryDryRun.Text.Contains("[UPGRADE_READY] Interrupted automatic host upgrade $($pendingAutomaticTransactions[0].Name) requires recovery before watcher handoff.")) `
        -Message "DryRun did not advertise the strictly validated automatic recovery transaction."
    Assert-True -Condition (-not $pendingRecoveryDryRun.Text.Contains("[OK] Host payload is current.")) -Message "Pending automatic recovery was masked by the current payload status."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforePendingRecoveryDryRun -Message "Pending-recovery DryRun changed the crashed transaction."

    $completedPreHandoffRecovery = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $completedPreHandoffRecovery -ExitCode 0 -Label "Automatic pre-handoff crash recovery"
    Assert-True -Condition ($completedPreHandoffRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Upgrade did not recover the pre-handoff automatic transaction first."
    Assert-True -Condition ($completedPreHandoffRecovery.Text.Contains("[INSTALLING] Installing immutable generation $generationId.")) -Message "Recovered Upgrade did not retry immutable generation installation."
    Assert-True -Condition ($completedPreHandoffRecovery.Text.Contains("[SWITCHING] Published current generation pointer for $generationId.")) -Message "Recovered Upgrade did not retry watcher handoff."
    Assert-CanonicalFilesInstalled
    $completedUpgradeState = Get-Content -LiteralPath $failedUpgradeStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $completedUpgradeState.state -Expected "CURRENT" -Message "Recovered pre-handoff Upgrade did not reach CURRENT."
    Assert-NoMaterializerResidue
    Write-Host "[OK] DryRun exposed a validated post-plan crash, rejected ordinary-journal elevation, and Upgrade completed automatic recovery."

    $preHandoffRecoveryCleanup = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $preHandoffRecoveryCleanup -ExitCode 0 -Label "Pre-handoff recovery cleanup Remove"
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue

    Install-OwnedLegacyRedeployFixture -PayloadVersion "poc.15" -PayloadSequence 15
    $unknownLegacyDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownLegacyDryRun -ExitCode 0 -Label "Unknown legacy Redeploy DryRun"
    Assert-True -Condition (-not $unknownLegacyDryRun.Text.Contains("[REDEPLOY_READY]")) -Message "Unknown legacy payload incorrectly advertised Redeploy."
    $unknownLegacyBefore = Get-ManagedPayloadSnapshot -Root $hostRoot
    $unknownLegacyRedeploy = Invoke-Materializer -Action "Redeploy" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownLegacyRedeploy -ExitCode 4 -Label "Unknown legacy Redeploy refusal"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $unknownLegacyBefore -Message "Rejected unknown legacy Redeploy changed managed state."

    $reviewedLegacyRedeployIdentities = @(
        [pscustomobject]@{ PackageVersion = "0.1.0"; PayloadVersion = "poc.9"; PayloadSequence = 9 },
        [pscustomobject]@{ PackageVersion = "0.2.0"; PayloadVersion = "poc.16"; PayloadSequence = 16 },
        [pscustomobject]@{ PackageVersion = "0.2.1"; PayloadVersion = "poc.20"; PayloadSequence = 20 }
    )
    foreach ($identity in $reviewedLegacyRedeployIdentities) {
        Install-OwnedLegacyRedeployFixture `
            -PackageVersion $identity.PackageVersion `
            -PayloadVersion $identity.PayloadVersion `
            -PayloadSequence $identity.PayloadSequence
        $reviewedLegacyDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $reviewedLegacyDryRun -ExitCode 0 -Label "$($identity.PayloadVersion) Redeploy DryRun"
        Assert-True `
            -Condition ($reviewedLegacyDryRun.Text.Contains("[REDEPLOY_READY] Owned payload $($identity.PayloadVersion) can redeploy to generation $generationId after MCP and watcher owners stop.")) `
            -Message "Reviewed $($identity.PayloadVersion) identity did not advertise the controlled Redeploy action."
        Assert-True -Condition (-not $reviewedLegacyDryRun.Text.Contains("[UPGRADE_READY]")) -Message "Reviewed $($identity.PayloadVersion) identity incorrectly advertised a live automatic upgrade."
    }
    Write-Host "[OK] Published poc.9, poc.16, and poc.20 identities advertise controlled Redeploy."

    Install-OwnedLegacyRedeployFixture
    $legacyRedeployDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $legacyRedeployDryRun -ExitCode 0 -Label "poc.16 Redeploy DryRun"
    Assert-True `
        -Condition ($legacyRedeployDryRun.Text.Contains("[REDEPLOY_READY] Owned payload poc.16 can redeploy to generation $generationId after MCP and watcher owners stop.")) `
        -Message "Owned poc.16 DryRun did not advertise the controlled redeploy action."
    Assert-True -Condition (-not $legacyRedeployDryRun.Text.Contains("[UPGRADE_READY]")) -Message "Owned poc.16 incorrectly advertised a live automatic upgrade."

    $legacyRedeployBeforeBlock = Get-ManagedPayloadSnapshot -Root $hostRoot
    $unsupportedAutomaticUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unsupportedAutomaticUpgrade -ExitCode 4 -Label "poc.16 automatic Upgrade refusal"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $legacyRedeployBeforeBlock -Message "Rejected poc.16 automatic Upgrade changed managed state."

    $legacyRedeployGate = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
    $legacyRedeployMcpProcess = $null
    try {
        $legacyRedeployMcpProcess = Start-LegacyHostUseLeaseProcess -GatePath $legacyRedeployGate -Owner "mcp"
        $blockedRedeploy = Invoke-Materializer -Action "Redeploy" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $blockedRedeploy -ExitCode 4 -Label "Active-owner poc.16 Redeploy refusal"
        Assert-True -Condition ($blockedRedeploy.Text.Contains("[ACTIVE] mcp PID $($legacyRedeployMcpProcess.Id)")) -Message "Blocked Redeploy omitted its active MCP owner."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $legacyRedeployBeforeBlock -Message "Blocked poc.16 Redeploy changed managed state."
    } finally {
        if ($null -ne $legacyRedeployMcpProcess) {
            Stop-LegacyHostUseLeaseProcess -Process $legacyRedeployMcpProcess -Owner "mcp"
        }
    }

    $legacyRedeploy = Invoke-Materializer -Action "Redeploy" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $legacyRedeploy -ExitCode 0 -Label "Owned poc.16 Redeploy"
    Assert-True -Condition ($legacyRedeploy.Text.Contains("[REDEPLOYING] Replacing byte-exact poc.16 host files and publishing generation $generationId.")) -Message "Redeploy omitted its source and target identities."
    Assert-True -Condition ($legacyRedeploy.Text.Contains("[OK] Host payload redeployed to version $generationId.")) -Message "Redeploy omitted its completion state."
    Assert-CanonicalFilesInstalled
    $redeployedPointer = Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath) -Raw | ConvertFrom-Json
    Assert-Equal -Actual $redeployedPointer.generation_id -Expected $generationId -Message "Redeploy did not select the current generation."
    $redeployedMarker = Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) -Raw | ConvertFrom-Json
    Assert-Equal -Actual $redeployedMarker.payload_version -Expected $generationId -Message "Redeploy did not publish the current ownership marker."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Byte-exact poc.16 required stopped owners, redeployed transactionally, and selected $generationId."

    $legacyRedeployCleanup = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $legacyRedeployCleanup -ExitCode 0 -Label "Redeploy cleanup Remove"
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue

    Install-LegacyPoc21Fixture

    $legacyFlatHashes = @{}
    foreach ($relativePath in $legacyManagedTargets | Where-Object { $_ -ne "AIWork/codedb/wrapper/codedb-project-wrapper.mjs" }) {
        $legacyFlatHashes[$relativePath] = (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath) -Algorithm SHA256).Hash
    }
    $legacyHostUseGate = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
    $legacyMcpProcess = $null
    $legacyWatcherProcess = $null
    try {
        $legacyMcpProcess = Start-LegacyHostUseLeaseProcess -GatePath $legacyHostUseGate -Owner "mcp"
        $legacyWatcherProcess = Start-LegacyHostUseLeaseProcess -GatePath $legacyHostUseGate -Owner "watcher"
        $beforeUpgradeDryRun = Get-ManagedPayloadSnapshot -Root $hostRoot
        $upgradeDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $upgradeDryRun -ExitCode 0 -Label "poc.21 automatic-upgrade DryRun"
        Assert-True `
            -Condition ($upgradeDryRun.Text.Contains("[UPGRADE_READY] Owned payload poc.21 can migrate to generation $generationId while existing leases drain naturally.")) `
            -Message "Owned poc.21 DryRun did not advertise the source and target upgrade identities."
        Assert-True -Condition ($upgradeDryRun.Text.Contains("[ACTIVE] mcp PID $($legacyMcpProcess.Id)")) -Message "Upgrade DryRun omitted the live legacy MCP owner."
        Assert-True -Condition ($upgradeDryRun.Text.Contains("[ACTIVE] watcher PID $($legacyWatcherProcess.Id)")) -Message "Upgrade DryRun omitted the live legacy watcher owner."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeUpgradeDryRun -Message "Automatic-upgrade DryRun changed managed state."
        Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath))) -Message "poc.21 fixture unexpectedly had a current generation pointer."

        $upgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $upgrade -ExitCode 0 -Label "Live-owner poc.21 automatic Upgrade"
        Assert-True -Condition ($upgrade.Text.Contains("[INSTALLING] Installing immutable generation $generationId.")) -Message "Automatic Upgrade omitted the installing state."
        Assert-True -Condition ($upgrade.Text.Contains("[SWITCHING] Published current generation pointer for $generationId.")) -Message "Automatic Upgrade omitted the pointer switching state."
        Assert-True -Condition ($upgrade.Text.Contains("[OK] Host payload automatically upgraded to version $generationId.")) -Message "Automatic Upgrade omitted its completion state."
        Assert-True -Condition (Wait-ForHostUseLease -Owner "mcp" -ProcessId $legacyMcpProcess.Id -Present $true) -Message "Automatic Upgrade displaced the live legacy MCP owner."
        Assert-True -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $legacyWatcherProcess.Id -Present $true) -Message "Automatic Upgrade displaced the live legacy watcher owner."
        Assert-CanonicalFilesInstalled
        foreach ($relativePath in $legacyFlatHashes.Keys) {
            Assert-Equal `
                -Actual (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath) -Algorithm SHA256).Hash `
                -Expected $legacyFlatHashes[$relativePath] `
                -Message "Automatic Upgrade rewrote unchanged legacy flat bytes: $relativePath."
        }

        $strictSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $strictSync -ExitCode 4 -Label "Post-upgrade strict Sync lease gate"
        Assert-True -Condition ($strictSync.Text.Contains("[ACTIVE] mcp PID $($legacyMcpProcess.Id)")) -Message "Strict Sync omitted the draining legacy MCP owner."
        Assert-True -Condition ($strictSync.Text.Contains("[ACTIVE] watcher PID $($legacyWatcherProcess.Id)")) -Message "Strict Sync omitted the draining legacy watcher owner."
    } finally {
        if ($null -ne $legacyMcpProcess) {
            Stop-LegacyHostUseLeaseProcess -Process $legacyMcpProcess -Owner "mcp"
        }
        if ($null -ne $legacyWatcherProcess) {
            Stop-LegacyHostUseLeaseProcess -Process $legacyWatcherProcess -Owner "watcher"
        }
    }
    Assert-NoMaterializerResidue
    Write-Host "[OK] poc.21 upgraded with live legacy owners, published poc.27 atomically, and let both legacy leases drain naturally."

    $currentPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    $lastKnownGoodPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $lastKnownGoodPointerRelativePath
    Copy-Item -LiteralPath $currentPointerPath -Destination $lastKnownGoodPointerPath -Force
    $currentUpgradeState = Get-Content -LiteralPath $failedUpgradeStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $currentUpgradeState.state -Expected "CURRENT" -Message "Successful automatic Upgrade did not retain CURRENT diagnostics."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $lastKnownGoodPointerPath -Algorithm SHA256).Hash -Expected (Get-FileHash -LiteralPath $currentPointerPath -Algorithm SHA256).Hash -Message "LKG cleanup fixture does not match current.json."

    Assert-True -Condition (Test-Path -LiteralPath $markerPath -PathType Leaf) -Message "Automatic Upgrade did not write the ownership marker."
    $markerText = Get-Content -LiteralPath $markerPath -Raw
    Assert-LfOnlyFile -Path $markerPath -Label "Upgraded ownership marker"
    Assert-True -Condition (-not $markerText.Contains($hostRoot)) -Message "Ownership marker contains an absolute host path."

    Write-Utf8File -Path $markerPath -Content $markerText.Replace("`n", "`r`n")
    Assert-True -Condition ([Array]::IndexOf([System.IO.File]::ReadAllBytes($markerPath), [byte]13) -ge 0) -Message "Non-canonical marker fixture did not contain CR bytes."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 3 -Label "Non-canonical marker Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Non-canonical marker repair"
    Assert-LfOnlyFile -Path $markerPath -Label "Repaired ownership marker"
    Assert-Equal -Actual (Get-Content -LiteralPath $markerPath -Raw) -Expected $markerText -Message "Marker repair did not restore canonical serialization."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Ownership markers use canonical LF serialization and repair non-canonical JSON formatting."

    $marker = $markerText | ConvertFrom-Json
    Assert-Equal -Actual $marker.managed_by -Expected "com.rice.ai-codedb" -Message "Marker manager mismatch."
    Assert-Equal -Actual $marker.package_version -Expected "0.2.4" -Message "Marker package version mismatch."
    Assert-Equal -Actual $marker.payload_version -Expected $generationId -Message "Marker payload version mismatch."
    Assert-Equal -Actual $marker.payload_sequence -Expected 27 -Message "Marker payload sequence mismatch."
    Assert-Equal -Actual $marker.host_use_gate_version -Expected 1 -Message "Marker host-use gate version mismatch."
    Assert-Equal -Actual $marker.generation_lease_version -Expected 2 -Message "Marker generation-lease version mismatch."
    Assert-Equal -Actual $marker.generation_id -Expected $generationId -Message "Marker generation id mismatch."
    Assert-Equal -Actual $marker.current_pointer -Expected $currentPointerRelativePath -Message "Marker current-pointer path mismatch."
    Assert-Equal -Actual @($marker.files).Count -Expected 43 -Message "Marker file count mismatch."
    $currentPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    Assert-LfOnlyFile -Path $currentPointerPath -Label "Current generation pointer"
    $currentPointer = Get-Content -LiteralPath $currentPointerPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $currentPointer.package_version -Expected "0.2.4" -Message "Current pointer package version mismatch."
    Assert-Equal -Actual $currentPointer.generation_id -Expected $generationId -Message "Current pointer generation id mismatch."
    Assert-Equal -Actual $currentPointer.generation_relative_path -Expected $generationTargetPrefix.TrimEnd([char]'/') -Message "Current pointer generation path mismatch."
    $installedGenerationManifest = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "generation-manifest.json")
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $installedGenerationManifest -Algorithm SHA256).Hash.ToLowerInvariant() `
        -Expected ([string]$currentPointer.generation_manifest_sha256) `
        -Message "Current pointer generation-manifest hash mismatch."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Upgraded marker, immutable generation, and current pointer form the expected 43-target closure."

    $materializedPrepare = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/prepare-codedb-project-runtime.ps1")
    $prepareResult = Invoke-NativeProcess `
        -FilePath $powershellPath `
        -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$materializedPrepare`"" `
        -WorkingDirectory $hostRoot
    Assert-Result -Result $prepareResult -ExitCode 0 -Label "Initial runtime config preparation"
    $generatedConfig = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\config\codedb-mcp.toml"
    Assert-True -Condition (Test-Path -LiteralPath $generatedConfig -PathType Leaf) -Message "Materialized prepare-runtime did not generate the fixture config."
    $generatedConfigText = Get-Content -LiteralPath $generatedConfig -Raw
    Assert-True -Condition ($generatedConfigText.Contains("AIWork/.runtime/codedb/codedb-fixture/index")) -Message "Materialized prepare-runtime resolved the wrong Unity project slug."
    Assert-True -Condition (-not $generatedConfigText.Contains("__CODEDB_PROVIDER_SLUG__")) -Message "Materialized prepare-runtime left an unresolved template token."
    Assert-True -Condition ($generatedConfigText.Contains("flush_interval_ms = 500")) -Message "Generated runtime config omitted the required logging flush interval."

    $legacyConfigText = [regex]::Replace($generatedConfigText, '(?m)^\s*flush_interval_ms\s*=.*\r?\n?', '')
    Write-Utf8File -Path $generatedConfig -Content $legacyConfigText
    $legacyConfigBeforeCheck = Get-Content -LiteralPath $generatedConfig -Raw
    $legacyConfigCheck = Invoke-NativeProcess `
        -FilePath $powershellPath `
        -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$materializedPrepare`"" `
        -WorkingDirectory $hostRoot
    Assert-Result -Result $legacyConfigCheck -ExitCode 3 -Label "Legacy runtime config compatibility check"
    Assert-True -Condition ($legacyConfigCheck.Text.Contains("[UPDATE_REQUIRED]")) -Message "Legacy runtime config did not report UPDATE_REQUIRED."
    Assert-True -Condition ($legacyConfigCheck.Text.Contains("[logging].flush_interval_ms")) -Message "Legacy runtime config did not identify the missing required field."
    Assert-Equal -Actual (Get-Content -LiteralPath $generatedConfig -Raw) -Expected $legacyConfigBeforeCheck -Message "Compatibility check rewrote the legacy runtime config."

    $legacyConfigRegeneration = Invoke-NativeProcess `
        -FilePath $powershellPath `
        -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$materializedPrepare`" -Force" `
        -WorkingDirectory $hostRoot
    Assert-Result -Result $legacyConfigRegeneration -ExitCode 0 -Label "Explicit legacy runtime config regeneration"
    Assert-True -Condition ((Get-Content -LiteralPath $generatedConfig -Raw).Contains("flush_interval_ms = 500")) -Message "Explicit regeneration did not restore the required logging flush interval."
    Write-Host "[OK] Materialized runtime preparation detected an old config without writing it and regenerated only with -Force."

    $materializedCoordinator = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "coordinator/codedb-watch-coordinator.mjs")
    $coordinatorCheckOutput = @(& $nodePath --check $materializedCoordinator 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Materialized coordinator failed Node syntax validation.`n$($coordinatorCheckOutput -join [Environment]::NewLine)"
    }
    Write-Host "[OK] Materialized coordinator passed Node syntax validation from the host path."

    $materializedBuilder = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/build-codedb-project-text-adapter.ps1")
    Push-Location $hostRoot
    try {
        $builderOutput = @(& $materializedBuilder -Reason Manual 2>&1)
        $builderSucceeded = $?
    } finally {
        Pop-Location
    }
    if (-not $builderSucceeded) {
        throw "Materialized Shader adapter builder failed.`n$($builderOutput -join [Environment]::NewLine)"
    }
    $adapterManifestPath = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\adapter\text-index\manifest.json"
    Assert-True -Condition (Test-Path -LiteralPath $adapterManifestPath -PathType Leaf) -Message "Materialized builder did not publish the adapter manifest."
    $adapterManifest = Get-Content -LiteralPath $adapterManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adapterManifest.buildReason -Expected "manual" -Message "Materialized builder reason mismatch."
    Assert-Equal -Actual $adapterManifest.fileCount -Expected 2 -Message "Materialized builder file count mismatch."
    Assert-Equal -Actual $adapterManifest.files[0].path -Expected "Assets/MaterializerProbe.shader" -Message "Materialized builder indexed the wrong fixture file."

    $materializedWorker = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/run-codedb-project-text-adapter-worker.ps1")
    $workerRequestId = "materializer-adapter-probe"
    $workerProbe = Invoke-AdapterWorkerRequest `
        -WorkerPath $materializedWorker `
        -BuilderPath $materializedBuilder `
        -Request ([ordered]@{
            schema_version = 1
            action = "build"
            request_id = $workerRequestId
            reason = "Automatic"
        })
    $workerReady = $workerProbe.ready
    $workerResponse = $workerProbe.response
    Assert-Equal -Actual $workerReady.type -Expected "ready" -Message "Materialized worker readiness type mismatch."
    Assert-True -Condition ([string]::Equals([string]$workerReady.builder_path, $materializedBuilder, [StringComparison]::OrdinalIgnoreCase)) -Message "Materialized worker resolved the wrong builder path."
    if (-not [string]::Equals([string]$workerResponse.type, "build_completed", [StringComparison]::Ordinal)) {
        throw "Materialized worker response type mismatch. Expected 'build_completed', got '$($workerResponse.type)'. Error: $($workerResponse.error)"
    }
    Assert-Equal -Actual $workerResponse.request_id -Expected $workerRequestId -Message "Materialized worker request id mismatch."
    $adapterManifest = Get-Content -LiteralPath $adapterManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adapterManifest.buildReason -Expected "automatic" -Message "Materialized worker build reason mismatch."
    Assert-Equal -Actual $adapterManifest.fileCount -Expected 2 -Message "Materialized worker file count mismatch."
    Write-Host "[OK] Materialized Shader adapter builder and persistent worker executed from the host path."

    $materializedWrapper = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    $wrapperCheckOutput = @(& $nodePath --check $materializedWrapper 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Materialized wrapper failed Node syntax validation.`n$($wrapperCheckOutput -join [Environment]::NewLine)"
    }
    $wrapperContextOutput = @(& $nodePath $materializedWrapper --root $hostRoot --print-context 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Materialized wrapper context probe failed.`n$($wrapperContextOutput -join [Environment]::NewLine)"
    }
    $wrapperContext = ($wrapperContextOutput -join [Environment]::NewLine) | ConvertFrom-Json
    Assert-Equal -Actual $wrapperContext.project_slug -Expected "fixture" -Message "Materialized wrapper project slug mismatch."
    Assert-Equal -Actual $wrapperContext.provider_name -Expected "codedb-fixture" -Message "Materialized wrapper provider name mismatch."
    Assert-Equal -Actual $wrapperContext.runtime_root -Expected "AIWork/.runtime/codedb/codedb-fixture" -Message "Materialized wrapper runtime root mismatch."
    Assert-Equal -Actual $wrapperContext.generation_id -Expected $generationId -Message "Materialized wrapper selected generation mismatch."
    Assert-Equal -Actual $wrapperContext.bootstrap_protocol -Expected 1 -Message "Materialized wrapper bootstrap protocol mismatch."

    $outerWorkingRoot = Join-Path $runRoot "wrapper-outer-cwd"
    New-Item -ItemType Directory -Force -Path $outerWorkingRoot | Out-Null
    $outerContextProbe = Invoke-NativeProcess `
        -FilePath $nodePath `
        -Arguments "`"$materializedWrapper`" --print-context" `
        -WorkingDirectory $outerWorkingRoot
    Assert-Equal -Actual $outerContextProbe.ExitCode -Expected 0 -Message "Wrapper self-path root probe failed."
    $outerContext = $outerContextProbe.StandardOutput | ConvertFrom-Json
    Assert-Equal -Actual $outerContext.provider_name -Expected "codedb-fixture" -Message "Wrapper did not derive its project from its installed path."
    Assert-Equal -Actual $outerContext.generation_id -Expected $generationId -Message "Outer-cwd wrapper selected the wrong generation."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $outerWorkingRoot "AIWork"))) -Message "Wrapper self-path context probe created outer AIWork state."

    $outerRootAssertion = Invoke-NativeProcess `
        -FilePath $nodePath `
        -Arguments "`"$materializedWrapper`" --root ." `
        -WorkingDirectory $outerWorkingRoot
    Assert-True -Condition ($outerRootAssertion.ExitCode -ne 0) -Message "Wrapper accepted an invalid outer-working-directory root assertion."
    Assert-True -Condition ($outerRootAssertion.Text -like "*Invalid Unity project root*") -Message "Invalid outer root did not report Unity marker validation."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $outerWorkingRoot "AIWork"))) -Message "Invalid outer root created AIWork before validation."

    $materializedHostUseGate = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "shared/codedb-host-use-gate.mjs")
    $hostUseGateUri = ([System.Uri]::new($materializedHostUseGate)).AbsoluteUri
    $hostUseGateProbePath = Join-Path $runRoot "invalid-host-use-gate-probe.mjs"
    Write-Utf8File -Path $hostUseGateProbePath -Content @"
import { acquireCodedbHostUseLease } from "$hostUseGateUri";

try {
  const lease = acquireCodedbHostUseLease(process.argv[2], "mcp");
  lease.release();
  process.stderr.write("Host-use gate accepted an invalid Unity root.\n");
  process.exit(2);
} catch (error) {
  process.stderr.write(String(error.message) + "\n");
}
"@
    $hostUseGateProbe = Invoke-NativeProcess `
        -FilePath $nodePath `
        -Arguments "`"$hostUseGateProbePath`" `"$outerWorkingRoot`"" `
        -WorkingDirectory $outerWorkingRoot
    Assert-Equal -Actual $hostUseGateProbe.ExitCode -Expected 0 -Message "Host-use gate invalid-root probe failed."
    Assert-True -Condition ($hostUseGateProbe.Text -like "*Invalid Unity project root*") -Message "Host-use gate did not validate Unity markers before lease creation."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $outerWorkingRoot "AIWork"))) -Message "Host-use gate created runtime directories before Unity-root validation."

    $wrongUnityRoot = Join-Path $runRoot "wrong-unity-root"
    New-Item -ItemType Directory -Force -Path (Join-Path $wrongUnityRoot "Assets") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $wrongUnityRoot "Packages") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $wrongUnityRoot "ProjectSettings") | Out-Null
    $wrongRootAssertion = Invoke-NativeProcess `
        -FilePath $nodePath `
        -Arguments "`"$materializedWrapper`" --root `"$wrongUnityRoot`"" `
        -WorkingDirectory $hostRoot
    Assert-True -Condition ($wrongRootAssertion.ExitCode -ne 0) -Message "Wrapper accepted another valid Unity project as its root assertion."
    Assert-True -Condition ($wrongRootAssertion.Text -like "*--root must match wrapper-owned Unity root*") -Message "Wrong Unity root did not report the wrapper ownership mismatch."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $wrongUnityRoot "AIWork"))) -Message "Wrong Unity root created AIWork before ownership validation."
    Write-Host "[OK] Wrapper root authority rejected outer and wrong-project roots without runtime writes."

    $readEscapeRoot = Join-Path $runRoot "read-escape-source"
    New-Item -ItemType Directory -Force -Path $readEscapeRoot | Out-Null
    Write-Utf8File -Path (Join-Path $readEscapeRoot "Outside.cs") -Content "// CODEDB_READ_MUST_NOT_ESCAPE_ROOT`n"
    $readEscapeJunctionPath = Join-Path $hostRoot "Assets\ReadEscape"
    New-Item -ItemType Junction -Path $readEscapeJunctionPath -Target $readEscapeRoot | Out-Null

    $wrapperStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $wrapperStartInfo.FileName = $nodePath
    $wrapperStartInfo.Arguments = "`"$materializedWrapper`" --root `"$hostRoot`""
    $wrapperStartInfo.WorkingDirectory = $hostRoot
    $wrapperStartInfo.UseShellExecute = $false
    $wrapperStartInfo.CreateNoWindow = $true
    $wrapperStartInfo.RedirectStandardInput = $true
    $wrapperStartInfo.RedirectStandardOutput = $true
    $wrapperStartInfo.RedirectStandardError = $true
    $wrapperProcess = [System.Diagnostics.Process]::new()
    $wrapperProcess.StartInfo = $wrapperStartInfo
    $wrapperStarted = $false
    try {
        $null = $wrapperProcess.Start()
        $wrapperStarted = $true
        $wrapperProcessId = $wrapperProcess.Id
        $wrapperStderrTask = $wrapperProcess.StandardError.ReadToEndAsync()

        $initializeRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 1
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        Assert-Equal -Actual $initializeRpc.result.serverInfo.name -Expected "codedb-project-wrapper" -Message "Materialized wrapper server name mismatch."
        Assert-Equal -Actual $initializeRpc.result.serverInfo.version -Expected "0.2.3" -Message "Materialized wrapper server version mismatch."

        $toolsRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 2
            method = "tools/list"
            params = [ordered]@{}
        })
        $toolNames = @($toolsRpc.result.tools | ForEach-Object { [string]$_.name } | Sort-Object)
        Assert-Equal -Actual ($toolNames -join "|") -Expected "codedb_context|codedb_find|codedb_read|codedb_search|codedb_status|codedb_text_search" -Message "Materialized wrapper tool surface mismatch."

        Assert-True -Condition (Wait-ForHostUseLease -Owner "mcp" -ProcessId $wrapperProcess.Id -Present $false) -Message "Generation-aware wrapper published a legacy process-lifetime lease."
        Assert-True -Condition (Wait-ForGenerationLease -Owner "mcp" -ProcessId $wrapperProcess.Id -Present $false) -Message "Completed wrapper RPC left its request generation lease behind."

        $liveGenerationMcpLease = New-TestGenerationLease -Owner "mcp"
        $liveGenerationWatcherLease = New-TestGenerationLease -Owner "watcher"
        try {
            $generationLeaseDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
            Assert-Result -Result $generationLeaseDryRun -ExitCode 0 -Label "Multi-owner generation lease DryRun"
            Assert-True -Condition ($generationLeaseDryRun.Text.Contains("[ACTIVE] generation $generationId mcp PID $PID")) -Message "DryRun omitted the live generation MCP owner."
            Assert-True -Condition ($generationLeaseDryRun.Text.Contains("[ACTIVE] generation $generationId watcher PID $PID")) -Message "DryRun omitted the live generation watcher owner."

            $beforeActiveMcpGate = Get-ManagedPayloadSnapshot -Root $hostRoot
            $activeMcpSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
            Assert-Result -Result $activeMcpSync -ExitCode 4 -Label "Active generation-owner Sync gate"
            Assert-True -Condition ($activeMcpSync.Text.Contains("[ACTIVE] generation $generationId mcp PID $PID")) -Message "Active gate did not identify the generation MCP owner."
            Assert-True -Condition ($activeMcpSync.Text.Contains("[ACTIVE] generation $generationId watcher PID $PID")) -Message "Active gate did not identify the generation watcher owner."
            Assert-True -Condition (-not $activeMcpSync.Text.Contains("[PLAN]")) -Message "Active generation gate ran after materialization planning."
            Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeActiveMcpGate -Message "Active generation gate changed managed host tooling."
        } finally {
            Remove-Item -LiteralPath $liveGenerationMcpLease -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $liveGenerationWatcherLease -Force -ErrorAction SilentlyContinue
        }

        $statusRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 3
            method = "tools/call"
            params = [ordered]@{ name = "codedb_status"; arguments = [ordered]@{} }
        })
        $statusText = [string]$statusRpc.result.content[0].text
        Assert-True -Condition (Wait-ForGenerationLease -Owner "mcp" -ProcessId $wrapperProcess.Id -Present $false) -Message "Completed status RPC left its generation lease behind."
        foreach ($expectedStatus in @(
            "[OK] codedb-fixture wrapper ready.",
            "Provider executable: missing",
            "Desired state: unknown",
            "Editor demand: offline",
            "Automatic refresh: editor_offline",
            "Lifecycle reason: EDITOR_OFFLINE",
            "Watch coordinator: stopped",
            "Shader adapter manifest: present",
            "Shader adapter files: 2",
            "Tool profile: Discover Read only"
        )) {
            Assert-True -Condition ($statusText.Contains($expectedStatus)) -Message "Materialized wrapper status is missing '$expectedStatus'."
        }
        $statusTiming = Get-WrapperTiming -Text $statusText -Label "Wrapper status"
        Assert-Equal -Actual $statusTiming.schema_version -Expected 1 -Message "Wrapper timing schema mismatch."
        Assert-Equal -Actual $statusTiming.tool -Expected "codedb_status" -Message "Wrapper status timing tool mismatch."
        Assert-Equal -Actual $statusTiming.queue_ms -Expected 0 -Message "Status-only wrapper unexpectedly reported queue time."
        Assert-Equal -Actual $statusTiming.provider_attempts -Expected 0 -Message "Wrapper status unexpectedly invoked the Provider."

        $searchRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 4
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{ query = "CODEDB_MATERIALIZER_ADAPTER_PROBE"; language = "ShaderHlsl"; limit = 5 }
            }
        })
        $searchText = [string]$searchRpc.result.content[0].text
        Assert-True -Condition ($searchText.Contains("[HIT] Assets/MaterializerProbe.shader:2")) -Message "Materialized wrapper did not find the Shader fixture token."
        $adapterSearchTiming = Get-WrapperTiming -Text $searchText -Label "Shader adapter search"
        Assert-Equal -Actual $adapterSearchTiming.tool -Expected "codedb_text_search" -Message "Shader adapter timing tool mismatch."
        Assert-True -Condition ($adapterSearchTiming.adapter_ms -ge 0) -Message "Shader adapter timing is negative."
        Assert-Equal -Actual $adapterSearchTiming.provider_attempts -Expected 0 -Message "Shader-only search unexpectedly invoked the Provider."

        $readRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 5
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/MaterializerProbe.shader"; start_line = 2; end_line = 2; language = "ShaderHlsl" }
            }
        })
        $readText = [string]$readRpc.result.content[0].text
        Assert-True -Condition ($readText.Contains("lines 2-2")) -Message "Materialized wrapper did not preserve the requested read window."
        Assert-True -Condition ($readText.Contains("CODEDB_MATERIALIZER_ADAPTER_PROBE")) -Message "Materialized wrapper read omitted the Shader fixture token."
        $readTiming = Get-WrapperTiming -Text $readText -Label "Shader adapter read"
        Assert-Equal -Actual $readTiming.tool -Expected "codedb_read" -Message "Shader read timing tool mismatch."
        Assert-True -Condition ($readTiming.read_ms -ge 0) -Message "Shader read timing is negative."

        $csharpReadRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 6
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/MaterializerFreshnessProbe.cs"; start_line = 2; end_line = 2; language = "CSharp" }
            }
        })
        $csharpReadText = [string]$csharpReadRpc.result.content[0].text
        Assert-True -Condition ($csharpReadText.Contains("CodeDB read Assets/MaterializerFreshnessProbe.cs lines 2-2")) -Message "C# read did not report the exact requested window."
        Assert-True -Condition ($csharpReadText.Contains("CODEDB_MATERIALIZER_PROVIDER_PROBE")) -Message "C# read omitted the requested source line."
        Assert-True -Condition (-not $csharpReadText.Contains("CodedbMaterializerFreshnessProbe {")) -Message "C# read leaked source before the requested window."
        Assert-True -Condition (-not $csharpReadText.Contains("CODEDB_BOUNDED_READ_EXCLUDED")) -Message "C# read leaked source after the requested window."

        $cappedReadRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 7
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/ZMaterializerBoundedReadProbe.cs"; start_line = 10; end_line = 250; language = "CSharp" }
            }
        })
        $cappedReadText = [string]$cappedReadRpc.result.content[0].text
        Assert-True -Condition ($cappedReadText.Contains("lines 10-209")) -Message "C# read did not cap the requested window at 200 lines."
        Assert-True -Condition ($cappedReadText.Contains("[LIMIT] Read window capped at 200 lines")) -Message "C# read did not disclose its line cap."
        Assert-True -Condition ($cappedReadText.Contains("CODEDB_BOUNDED_LINE_010")) -Message "C# capped read omitted its first requested line."
        Assert-True -Condition ($cappedReadText.Contains("CODEDB_BOUNDED_LINE_209")) -Message "C# capped read omitted its final allowed line."
        Assert-True -Condition (-not $cappedReadText.Contains("CODEDB_BOUNDED_LINE_210")) -Message "C# capped read exceeded the 200-line boundary."

        $largeReadRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 8
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/ZMaterializerOutputCeilingProbe.cs"; start_line = 1; end_line = 1; language = "CSharp" }
            }
        })
        $largeReadText = [string]$largeReadRpc.result.content[0].text
        $largeReadBytes = [System.Text.Encoding]::UTF8.GetByteCount($largeReadText)
        Assert-True -Condition ($largeReadBytes -le 65536) -Message "Wrapper output exceeded its 64 KiB UTF-8 ceiling: $largeReadBytes bytes."
        Assert-True -Condition ($largeReadText.Contains("[TRUNCATED] Wrapper output exceeded 65536 UTF-8 bytes.")) -Message "Wrapper output ceiling did not disclose truncation."
        $largeReadTiming = Get-WrapperTiming -Text $largeReadText -Label "Truncated wrapper read"
        Assert-True -Condition ($largeReadTiming.output_bytes -gt 65536) -Message "Truncated wrapper timing did not report the uncapped body size."

        $escapedReadRpc = Invoke-WrapperRpcError -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 9
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/ReadEscape/Outside.cs"; start_line = 1; end_line = 1; language = "CSharp" }
            }
        })
        Assert-True `
            -Condition ([string]$escapedReadRpc.error.message -like "*read resolved path is outside Unity root*") `
            -Message "Wrapper did not report the resolved-path escape boundary."
        $readEscapeItem = Get-Item -LiteralPath $readEscapeJunctionPath -Force
        Assert-True -Condition (($readEscapeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) -Message "Read escape fixture stopped being a junction."
        [System.IO.Directory]::Delete($readEscapeJunctionPath)
        $readEscapeJunctionPath = $null

        $conflictingScopeRpc = Invoke-WrapperRpcError -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 10
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{
                    query = "CODEDB_SCOPE_CONTRACT"
                    path = "Assets/Scoped"
                    path_glob = "Assets/Outside/**"
                }
            }
        })
        Assert-True `
            -Condition ([string]$conflictingScopeRpc.error.message -like "*path and path_glob disagree*") `
            -Message "Wrapper accepted conflicting search scope aliases."

        $excludedRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 11
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{
                    query = "CODEDB_MATERIALIZER_ADAPTER_PROBE"
                    language = "ShaderHlsl"
                    path_glob = "Library/PackageCache/**"
                }
            }
        })
        $excludedText = [string]$excludedRpc.result.content[0].text
        Assert-True -Condition ($excludedText.Contains("[NO HIT] excluded path scope: Library/PackageCache/**")) -Message "Materialized wrapper did not enforce the PackageCache exclusion."

        $wrapperProcess.StandardInput.Close()
        if (-not $wrapperProcess.WaitForExit(10000)) {
            $wrapperProcess.Kill()
            throw "Materialized wrapper did not exit after stdin closed."
        }
        $wrapperError = $wrapperStderrTask.Result.Trim()
        if ($wrapperProcess.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($wrapperError)) {
            throw "Materialized wrapper exited with code $($wrapperProcess.ExitCode).`n$wrapperError"
        }
    } finally {
        if ($wrapperStarted -and -not $wrapperProcess.HasExited) {
            $wrapperProcess.Kill()
            $wrapperProcess.WaitForExit()
        }
        $wrapperProcess.Dispose()
    }
    Assert-True -Condition (Wait-ForGenerationLease -Owner "mcp" -ProcessId $wrapperProcessId -Present $false) -Message "Normally closed MCP wrapper left a generation lease."

    $handoffGenerationId = "$generationId-handoff"
    $installedGenerationRoot = Split-Path -Parent $installedGenerationManifest
    $installedGenerationsRoot = Split-Path -Parent $installedGenerationRoot
    $hostRuntimeRoot = Split-Path -Parent $installedGenerationsRoot
    $hostLeaseRoot = Join-Path $hostRuntimeRoot "leases"
    $handoffGenerationRoot = Join-Path $installedGenerationsRoot $handoffGenerationId
    $handoffPointerPath = Join-Path $runRoot "handoff-current.json"
    $handoffHookPath = Join-Path $runRoot "fixture-wrapper-generation-handoff.cjs"
    $handoffLeaseLogPath = Join-Path $runRoot "fixture-wrapper-generation-handoff.log"
    $originalCurrentPointerText = Get-Content -LiteralPath $currentPointerPath -Raw
    try {
        Copy-Item -LiteralPath $installedGenerationRoot -Destination $handoffGenerationRoot -Recurse
        $handoffManifestPath = Join-Path $handoffGenerationRoot "generation-manifest.json"
        $handoffManifest = Get-Content -LiteralPath $handoffManifestPath -Raw | ConvertFrom-Json
        $handoffManifest.generation_id = $handoffGenerationId
        $handoffManifest.payload_version = $handoffGenerationId
        $handoffManifest.payload_sequence = 27
        Write-Utf8File -Path $handoffManifestPath -Content (($handoffManifest | ConvertTo-Json -Depth 8) + "`n")

        $handoffPointer = $originalCurrentPointerText | ConvertFrom-Json
        $handoffPointer.generation_id = $handoffGenerationId
        $handoffPointer.payload_version = $handoffGenerationId
        $handoffPointer.payload_sequence = 27
        $handoffPointer.generation_relative_path = "AIWork/.runtime/codedb/host/generations/$handoffGenerationId"
        $handoffPointer.generation_manifest_sha256 = (Get-FileHash -LiteralPath $handoffManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        Write-Utf8File -Path $handoffPointerPath -Content (($handoffPointer | ConvertTo-Json -Depth 8) + "`n")

        Write-Utf8File -Path $handoffHookPath -Content @'
const fs = require("node:fs");
const originalRenameSync = fs.renameSync.bind(fs);
let switched = false;
fs.renameSync = (source, target) => {
  const result = originalRenameSync(source, target);
  const normalized = String(target ?? "").replace(/\\/g, "/");
  if (/\/host\/leases\/[^/]+\/mcp-[0-9]+-[0-9a-f]{32}\.json$/i.test(normalized)) {
    fs.appendFileSync(process.env.CODEDB_TEST_HANDOFF_LEASE_LOG, `${normalized}\n`, "utf8");
    if (!switched && normalized.includes(`/host/leases/${process.env.CODEDB_TEST_HANDOFF_OLD_GENERATION}/`)) {
      switched = true;
      fs.copyFileSync(
        process.env.CODEDB_TEST_HANDOFF_REPLACEMENT_POINTER,
        process.env.CODEDB_TEST_HANDOFF_CURRENT_POINTER);
    }
  }
  return result;
};
'@

        $handoffStatus = Invoke-WrapperToolProbe `
            -WrapperPath $materializedWrapper `
            -Root $hostRoot `
            -ToolName "codedb_status" `
            -Arguments ([ordered]@{}) `
            -EnvironmentVariables @{
                NODE_OPTIONS = "--require=$handoffHookPath"
                CODEDB_TEST_HANDOFF_CURRENT_POINTER = $currentPointerPath
                CODEDB_TEST_HANDOFF_REPLACEMENT_POINTER = $handoffPointerPath
                CODEDB_TEST_HANDOFF_LEASE_LOG = $handoffLeaseLogPath
                CODEDB_TEST_HANDOFF_OLD_GENERATION = $generationId
            }
        Assert-True -Condition ($handoffStatus.Contains("Selected generation: $handoffGenerationId")) -Message "Wrapper request did not retry on the newly selected generation."
        $handoffLeasePublications = @(Get-Content -LiteralPath $handoffLeaseLogPath)
        Assert-True -Condition ($handoffLeasePublications.Count -ge 2) -Message "Pointer switch did not cause a second request-lease publication."
        Assert-True -Condition ($handoffLeasePublications[0].Contains("/host/leases/$generationId/")) -Message "First handoff lease did not pin the old generation."
        Assert-True -Condition ($handoffLeasePublications[1].Contains("/host/leases/$handoffGenerationId/")) -Message "Retried handoff lease did not pin the new generation."
        Assert-Equal -Actual @(Get-ChildItem -LiteralPath (Join-Path $hostLeaseRoot $generationId) -File -Filter "mcp-*.json" -ErrorAction SilentlyContinue).Count -Expected 0 -Message "Generation handoff left an old request lease."
        Assert-Equal -Actual @(Get-ChildItem -LiteralPath (Join-Path $hostLeaseRoot $handoffGenerationId) -File -Filter "mcp-*.json" -ErrorAction SilentlyContinue).Count -Expected 0 -Message "Generation handoff left a new request lease."
        Write-Host "[OK] Wrapper re-read current pointer identity after lease publication and retried on the selected generation."
    } finally {
        Write-Utf8File -Path $currentPointerPath -Content $originalCurrentPointerText
        Remove-Item -LiteralPath $handoffGenerationRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $handoffPointerPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $handoffHookPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $handoffLeaseLogPath -Force -ErrorAction SilentlyContinue
    }

    $staleGenerationProcessId = 2147483000
    $staleGenerationLease = New-TestGenerationLease `
        -Owner "mcp" `
        -ProcessId $staleGenerationProcessId `
        -HeartbeatUtc ([DateTime]::UtcNow.AddSeconds(-91))
    $beforeStaleLeaseRecovery = Get-ManagedPayloadSnapshot -Root $hostRoot
    $staleLeaseRecovery = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $staleLeaseRecovery -ExitCode 0 -Label "Stale generation lease recovery"
    Assert-True -Condition ($staleLeaseRecovery.Text.Contains("[RECOVERED] Removed stale generation $generationId mcp lease for PID $staleGenerationProcessId.")) -Message "Materializer did not report stale generation lease recovery."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeStaleLeaseRecovery -Message "Stale generation lease recovery changed managed host tooling."
    Assert-True -Condition (-not (Test-Path -LiteralPath $staleGenerationLease)) -Message "Stale generation lease remained after recovery."
    Assert-NoMaterializerResidue

    $pidReuseLease = New-TestGenerationLease -Owner "mcp" -ProcessId $PID -ProcessStartIdentity "1"
    $generationLeaseRoot = Split-Path -Parent $pidReuseLease
    $temporaryLeasePath = Join-Path $generationLeaseRoot (".mcp-$PID-$([guid]::NewGuid().ToString('N')).json.$PID.$([guid]::NewGuid().ToString('D')).tmp")
    Write-Utf8File -Path $temporaryLeasePath -Content "in-progress atomic lease publication`n"
    $pidReuseDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $pidReuseDryRun -ExitCode 0 -Label "PID-reuse and atomic-temp DryRun"
    Assert-True -Condition ($pidReuseDryRun.Text.Contains("[STALE-LEASE] generation $generationId mcp PID $PID")) -Message "PID-reuse identity mismatch was not classified as stale."
    Assert-True -Condition (-not $pidReuseDryRun.Text.Contains("Generation lease requires manual review")) -Message "Fresh atomic generation lease temp file was treated as invalid."
    $pidReuseRecovery = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $pidReuseRecovery -ExitCode 0 -Label "PID-reuse generation lease recovery"
    Assert-True -Condition ($pidReuseRecovery.Text.Contains("[RECOVERED] Removed stale generation $generationId mcp lease for PID $PID.")) -Message "PID-reuse generation lease was not reclaimed."
    Assert-True -Condition (-not (Test-Path -LiteralPath $pidReuseLease)) -Message "PID-reuse generation lease remained after recovery."
    Assert-True -Condition (Test-Path -LiteralPath $temporaryLeasePath -PathType Leaf) -Message "Fresh atomic generation lease temp file was unexpectedly reclaimed."
    Remove-Item -LiteralPath $temporaryLeasePath -Force
    Write-Host "[OK] Generation lease PID reuse was reclaimed while fresh atomic publication temp files stayed non-blocking."
    $fixtureWatchRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\watch"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $fixtureWatchRoot "auto-start.json"))) -Message "Materialized wrapper created a watch marker before Setup completed."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $fixtureWatchRoot "coordinator\coordinator-state.json"))) -Message "Materialized wrapper started the coordinator before Setup completed."
    Write-Host "[OK] Materialized wrapper released request leases, reported all generation owners, reclaimed stale leases, and stayed pending before Setup."

    $materializedWatchPrepare = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/prepare-codedb-project-watch-config.ps1")
    $materializedWatchManager = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/manage-codedb-project-watch.ps1")
    $handoffHarness = New-WatcherHandoffHarness -ManagerSourcePath $materializedWatchManager
    $oldHandoffGeneration = "fixture.old"
    try {
        Set-WatcherHandoffCoordinatorState -Path $handoffHarness.StatePath -GenerationId $oldHandoffGeneration
        Write-TestMaterializerActiveMarker -Path $handoffHarness.ActiveMarkerPath
        $plainEnsureDuringUpgrade = Invoke-PowerShellAction -Action {
            & $handoffHarness.ManagerPath -Action Ensure
        }
        Assert-Result -Result $plainEnsureDuringUpgrade -ExitCode 0 -Label "Plain Ensure during materializer handoff"
        Assert-True -Condition ($plainEnsureDuringUpgrade.Text.Contains("[OK] Automatic refresh: HANDOFF_PENDING")) -Message "Plain Ensure did not report materializer-owned handoff."
        $plainEnsureState = Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual $plainEnsureState.action -Expected "running" -Message "Plain Ensure stopped the old coordinator during materialization."
        Assert-Equal -Actual $plainEnsureState.generation_id -Expected $oldHandoffGeneration -Message "Plain Ensure switched generations during materialization."

        Write-TestMaterializerActiveMarker -Path $handoffHarness.ActiveMarkerPath -ProcessId ($PID + 1) -ProcessStartTicks "1"
        $invalidHandoffPid = Invoke-PowerShellAction -Action {
            & $handoffHarness.ManagerPath -Action Ensure -MaterializerHandoff
        }
        Assert-True -Condition ($invalidHandoffPid.ExitCode -ne 0) -Message "Materializer handoff accepted another marker PID."
        Assert-True -Condition ($invalidHandoffPid.Text.Contains("Materializer handoff marker identity is invalid")) -Message "Invalid handoff PID did not report its authorization boundary."
        Assert-Equal -Actual (Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json).generation_id -Expected $oldHandoffGeneration -Message "Invalid handoff PID changed coordinator ownership."

        Write-TestMaterializerActiveMarker -Path $handoffHarness.ActiveMarkerPath -ProcessStartTicks "1"
        $invalidHandoffStart = Invoke-PowerShellAction -Action {
            & $handoffHarness.ManagerPath -Action Ensure -MaterializerHandoff
        }
        Assert-True -Condition ($invalidHandoffStart.ExitCode -ne 0) -Message "Materializer handoff accepted a mismatched process-start identity."
        Assert-True -Condition ($invalidHandoffStart.Text.Contains("Materializer handoff marker identity is invalid")) -Message "Invalid handoff start identity did not report its authorization boundary."
        Assert-Equal -Actual (Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json).generation_id -Expected $oldHandoffGeneration -Message "Invalid handoff identity changed coordinator ownership."

        Write-TestMaterializerActiveMarker -Path $handoffHarness.ActiveMarkerPath
        $drainingLease = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $oldHandoffGeneration
        $drainRemovalJob = Start-Job -ScriptBlock {
            param($LeasePath)
            Start-Sleep -Milliseconds 500
            Remove-Item -LiteralPath $LeasePath -Force
        } -ArgumentList $drainingLease
        try {
            $authorizedDrain = Invoke-PowerShellAction -Action {
                & $handoffHarness.ManagerPath -Action Ensure -MaterializerHandoff
            }
        } finally {
            $null = Wait-Job -Job $drainRemovalJob -Timeout 10
            if ($drainRemovalJob.State -eq "Running") {
                Stop-Job -Job $drainRemovalJob
            }
            $null = Receive-Job -Job $drainRemovalJob -ErrorAction SilentlyContinue
            Remove-Job -Job $drainRemovalJob -Force
        }
        Assert-Result -Result $authorizedDrain -ExitCode 0 -Label "Authorized generation handoff drain"
        Assert-True -Condition ($authorizedDrain.Text.Contains("[DRAINING] Waiting for generation $oldHandoffGeneration MCP requests")) -Message "Authorized handoff did not wait for the old MCP request lease."
        Assert-True -Condition ($authorizedDrain.Text.Contains("[DRAINED] Generation $oldHandoffGeneration MCP requests completed.")) -Message "Authorized handoff did not observe lease drain completion."
        $drainedState = Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual $drainedState.generation_id -Expected $handoffHarness.GenerationId -Message "Authorized handoff did not switch after request drain."

        Set-WatcherHandoffCoordinatorState -Path $handoffHarness.StatePath -GenerationId $oldHandoffGeneration
        $pidReuseDrainLease = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $oldHandoffGeneration -ProcessStartIdentity "1"
        $deadDrainLease = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $oldHandoffGeneration -ProcessId 2147483000 -ProcessStartIdentity "1"
        try {
            $staleDrainOwners = Invoke-PowerShellAction -Action {
                & $handoffHarness.ManagerPath -Action Ensure -MaterializerHandoff
            }
            Assert-Result -Result $staleDrainOwners -ExitCode 0 -Label "PID-reused and dead generation leases"
            Assert-True -Condition (-not $staleDrainOwners.Text.Contains("[DRAINING]")) -Message "PID-reused or dead MCP leases blocked generation handoff."
            Assert-Equal -Actual (Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json).generation_id -Expected $handoffHarness.GenerationId -Message "Stale MCP lease classification prevented generation handoff."
        } finally {
            Remove-Item -LiteralPath $pidReuseDrainLease -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $deadDrainLease -Force -ErrorAction SilentlyContinue
        }

        Set-WatcherHandoffCoordinatorState -Path $handoffHarness.StatePath -GenerationId $oldHandoffGeneration
        $timeoutDrainLease = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $oldHandoffGeneration
        try {
            $drainTimeout = Invoke-PowerShellAction -Action {
                & $handoffHarness.ManagerPath `
                    -Action Ensure `
                    -MaterializerHandoff `
                    -TestGenerationDrainTimeoutMilliseconds 200
            }
            Assert-True -Condition ($drainTimeout.ExitCode -ne 0) -Message "Generation handoff stopped a coordinator before a live MCP request drained."
            Assert-True -Condition ($drainTimeout.Text.Contains("old coordinator was not stopped")) -Message "Generation drain timeout omitted its fail-closed status."
            $timeoutState = Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json
            Assert-Equal -Actual $timeoutState.action -Expected "running" -Message "Drain timeout stopped the old coordinator."
            Assert-Equal -Actual $timeoutState.generation_id -Expected $oldHandoffGeneration -Message "Drain timeout switched coordinator generations."
        } finally {
            Remove-Item -LiteralPath $timeoutDrainLease -Force -ErrorAction SilentlyContinue
        }

        $legacyHandoffGeneration = "fixture.legacy"
        $legacyLeaseRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\host\leases\$legacyHandoffGeneration"
        Assert-True -Condition (-not (Test-Path -LiteralPath $legacyLeaseRoot)) -Message "Legacy handoff fixture unexpectedly has a generation lease directory."
        Set-WatcherHandoffCoordinatorState -Path $handoffHarness.StatePath -GenerationId $legacyHandoffGeneration
        $legacyHandoff = Invoke-PowerShellAction -Action {
            & $handoffHarness.ManagerPath `
                -Action Ensure `
                -MaterializerHandoff `
                -TestGenerationDrainTimeoutMilliseconds 200
        }
        Assert-Result -Result $legacyHandoff -ExitCode 0 -Label "Legacy coordinator handoff without generation leases"
        Assert-True -Condition (-not $legacyHandoff.Text.Contains("[DRAINING]")) -Message "Legacy coordinator without a generation lease directory entered the drain wait."
        Assert-Equal -Actual (Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json).generation_id -Expected $handoffHarness.GenerationId -Message "Legacy coordinator did not hand off directly."

        Set-WatcherHandoffCoordinatorState -Path $handoffHarness.StatePath
        $legacySchemaHandoff = Invoke-PowerShellAction -Action {
            & $handoffHarness.ManagerPath `
                -Action Ensure `
                -MaterializerHandoff `
                -TestGenerationDrainTimeoutMilliseconds 200
        }
        Assert-Result -Result $legacySchemaHandoff -ExitCode 0 -Label "poc.21 coordinator-state handoff without generation_id"
        Assert-True -Condition (-not $legacySchemaHandoff.Text.Contains("[DRAINING]")) -Message "poc.21 schema entered generation lease drain."
        Assert-True -Condition ($legacySchemaHandoff.Text.Contains("[SWITCHING] Stopping generation legacy")) -Message "poc.21 schema was not classified as a legacy coordinator."
        Assert-Equal -Actual (Get-Content -LiteralPath $handoffHarness.StatePath -Raw | ConvertFrom-Json).generation_id -Expected $handoffHarness.GenerationId -Message "poc.21 schema did not hand off to the selected generation."
        Write-Host "[OK] Materializer-owned watcher handoff accepted the real poc.21 schema, rejected lifecycle races, drained old requests, ignored stale identities, and failed closed before stop."
    } finally {
        Remove-Item -LiteralPath $handoffHarness.ActiveMarkerPath -Force -ErrorAction SilentlyContinue
        $oldLeaseRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\host\leases\$oldHandoffGeneration"
        if ((Test-Path -LiteralPath $oldLeaseRoot -PathType Container) -and
            @(Get-ChildItem -LiteralPath $oldLeaseRoot -Force).Count -eq 0) {
            Remove-Item -LiteralPath $oldLeaseRoot -Force
        }
    }
    $fixtureProviderExecutable = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\bin\codebase-mcp.exe"
    $watchConfigPath = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\config\codedb-mcp.watch.toml"
    $watchMarkerPath = Join-Path $fixtureWatchRoot "auto-start.json"
    $watchPausedMarkerPath = Join-Path $fixtureWatchRoot "automatic-refresh-paused.json"
    $lifecycleRoot = Join-Path $fixtureWatchRoot "lifecycle"
    $desiredStatePath = Join-Path $lifecycleRoot "desired-state.json"
    $manualRuntimePath = Join-Path $lifecycleRoot "manual-runtime.json"
    $editorLeaseRoot = Join-Path $lifecycleRoot "editor-leases"
    $coordinatorRuntime = Join-Path $fixtureWatchRoot "coordinator"
    $coordinatorStatePath = Join-Path $coordinatorRuntime "coordinator-state.json"
    $materializedProviderGuidance = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/show-codedb-project-provider-guidance.ps1")
    $beforeMissingGuidance = Get-FileSnapshot -Root $hostRoot
    $missingGuidanceResult = Invoke-PowerShellAction -Action {
        & $materializedProviderGuidance
    }
    Assert-Result -Result $missingGuidanceResult -ExitCode 0 -Label "Materialized provider guidance without executable"
    foreach ($expectedGuidance in @(
        "The provider executable is an external dependency.",
        "This project does not vendor, download, or commit the provider binary in this flow.",
        "Do not write user/global MCP client configuration from this setup flow.",
        "[NO HIT] Provider executable is missing"
    )) {
        Assert-True -Condition ($missingGuidanceResult.Text.Contains($expectedGuidance)) -Message "Provider guidance is missing '$expectedGuidance'."
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMissingGuidance -Message "Provider guidance mutated the fixture while the executable was missing."

    New-FixtureProviderExecutable -Path $fixtureProviderExecutable
    $beforeAvailableGuidance = Get-FileSnapshot -Root $hostRoot
    $availableGuidanceResult = Invoke-PowerShellAction -Action {
        & $materializedProviderGuidance
    }
    Assert-Result -Result $availableGuidanceResult -ExitCode 0 -Label "Materialized provider guidance with executable"
    Assert-True -Condition ($availableGuidanceResult.Text.Contains("[OK] Provider executable exists")) -Message "Provider guidance did not detect the fixture executable."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeAvailableGuidance -Message "Provider guidance mutated the fixture after the executable was present."
    Write-Host "[OK] Materialized provider guidance remained read-only and registration-free."

    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Formal fixture config must remain watch-disabled."
    $activeWatchManagerPath = $materializedWatchManager
    $primaryEditorLeasePath = New-TestEditorLease -LeaseRoot $editorLeaseRoot -Root $hostRoot -SessionId "fixture-editor-primary"

    Write-Utf8File -Path $watchMarkerPath -Content "{`"schema_version`":1}`n"
    Write-Utf8File -Path $watchPausedMarkerPath -Content "{`"schema_version`":1}`n"
    $pauseMigration = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $pauseMigration -ExitCode 0 -Label "Legacy Pause migration"
    Assert-True -Condition ($pauseMigration.Text.Contains("[OK] Start with Unity Editor: DISABLED")) -Message "Legacy Pause did not win over the old enabled marker."
    Assert-True -Condition ($pauseMigration.Text.Contains("[OK] Manual runtime: NONE")) -Message "Legacy Pause migration created a session override."
    $migratedDesired = Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $migratedDesired.desired_state -Expected "disabled" -Message "Legacy Pause did not migrate to disabled."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "Legacy enabled marker remained after migration."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchPausedMarkerPath)) -Message "Legacy Pause marker remained after migration."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "Disabled migration started a coordinator."

    Remove-Item -LiteralPath $desiredStatePath -Force
    $priorGenerationId = "poc.23"
    $priorGenerationRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\host\generations\$priorGenerationId"
    $stalePriorCoordinatorState = [ordered]@{
        schema_version = 2
        generation_id = $priorGenerationId
        coordinator_pid = 2147483000
        lifecycle_id = "poc23-stale-lifecycle"
        exclusive_lifecycle = $false
        provider_pid = $null
        provider_state = "stopped"
        restart_count = 0
        orphan_cleanup_count = 0
        root = [System.IO.Path]::GetFullPath($hostRoot)
        provider_executable = [System.IO.Path]::GetFullPath($fixtureProviderExecutable)
        provider_config = [System.IO.Path]::GetFullPath($watchConfigPath)
        runtime = [System.IO.Path]::GetFullPath($coordinatorRuntime)
        adapter_enabled = $true
        adapter_builder = [System.IO.Path]::GetFullPath((Join-Path $hostRoot "AIWork\codedb\scripts\build-codedb-project-text-adapter.ps1"))
        adapter_worker = [System.IO.Path]::GetFullPath((Join-Path $hostRoot "AIWork\codedb\scripts\run-codedb-project-text-adapter-worker.ps1"))
        generation_adapter_builder = [System.IO.Path]::GetFullPath((Join-Path $priorGenerationRoot "scripts\build-codedb-project-text-adapter.ps1"))
        generation_adapter_worker = [System.IO.Path]::GetFullPath((Join-Path $priorGenerationRoot "scripts\run-codedb-project-text-adapter-worker.ps1"))
        adapter_manifest = [System.IO.Path]::GetFullPath((Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\adapter\text-index\manifest.json"))
        adapter_debounce_ms = 750
        adapter_worker_pid = $null
        adapter_worker_restart_count = 0
        adapter_worker_orphan_cleanup_count = 0
        adapter_build_pid = $null
        adapter_orphan_cleanup_count = 0
    }
    $unsafeStaleCoordinatorState = [ordered]@{}
    foreach ($entry in $stalePriorCoordinatorState.GetEnumerator()) {
        $unsafeStaleCoordinatorState[$entry.Key] = $entry.Value
    }
    $unsafeStaleCoordinatorState.generation_adapter_builder = [System.IO.Path]::GetFullPath((Join-Path $hostRoot "AIWork\.runtime\codedb\outside-generation\build-codedb-project-text-adapter.ps1"))
    Write-Utf8File -Path $coordinatorStatePath -Content (($unsafeStaleCoordinatorState | ConvertTo-Json -Depth 6) + "`n")
    $unsafePriorStateResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $unsafePriorStateResult -ExitCode 1 -Label "Unsafe stale poc.23 coordinator state"
    Assert-True -Condition $unsafePriorStateResult.Text.Contains("Stale coordinator metadata mismatch for generation_adapter_builder; refusing cleanup.") -Message "Automatic startup did not reject an out-of-generation stale adapter path."
    Assert-True -Condition (Test-Path -LiteralPath $coordinatorStatePath -PathType Leaf) -Message "Rejected stale coordinator metadata was removed despite the fail-closed path check."

    Write-Utf8File -Path $coordinatorStatePath -Content (($stalePriorCoordinatorState | ConvertTo-Json -Depth 6) + "`n")
    $defaultEnableResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $defaultEnableResult -ExitCode 0 -Label "Valid Setup default enable from stale poc.23 coordinator state"
    Assert-True -Condition (-not $defaultEnableResult.Text.Contains("Stale coordinator metadata mismatch for generation_adapter_builder")) -Message "Automatic startup compared the stale poc.23 adapter path to the selected generation path."
    $automaticStatus = Get-LastJsonObject -Result $defaultEnableResult -Label "Valid Setup default enable"
    Assert-Equal -Actual $automaticStatus.action -Expected "started" -Message "Editor-owned Ensure did not start the coordinator."
    Assert-Equal -Actual $automaticStatus.provider_state -Expected "ready" -Message "Automatic watcher provider did not reach ready."
    Assert-Equal -Actual $automaticStatus.adapter_state -Expected "watching" -Message "Automatic watcher adapter did not reach watching."
    Assert-Equal -Actual $automaticStatus.editor_session_count -Expected 1 -Message "Automatic watcher did not observe the Editor lease."
    $automaticLifecycleId = [string]$automaticStatus.lifecycle_id
    $activeWatchLifecycleId = $automaticLifecycleId

    $desiredState = Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $desiredState.desired_state -Expected "enabled" -Message "Valid Setup did not default desired state to enabled."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "Editor-owned startup recreated the legacy enabled marker."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchPausedMarkerPath)) -Message "Editor-owned startup recreated the legacy Pause marker."

    $automaticWatchProbe = Invoke-WrapperWatchProbe -WrapperPath $materializedWrapper -Root $hostRoot
    Assert-True -Condition ($automaticWatchProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.watch.toml")) -Message "First post-Setup wrapper did not route reads through automatic watch."
    foreach ($expectedStatus in @(
        "Desired state: enabled",
        "Editor demand: online",
        "Automatic refresh: active",
        "Lifecycle reason: READY",
        "Watch coordinator: ready",
        "Shader watcher: watching"
    )) {
        Assert-True -Condition ($automaticWatchProbe.StatusText.Contains($expectedStatus)) -Message "Automatic wrapper status is missing '$expectedStatus'."
    }
    Assert-True -Condition (Test-Path -LiteralPath $watchConfigPath -PathType Leaf) -Message "Automatic watch did not generate the watch config."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Automatic watch changed the formal provider config."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $watchConfigPath -Section "watch" -Key "enabled").Trim() -Expected "true" -Message "Generated watch config did not enable native watch."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $watchConfigPath -Section "watch" -Key "poll_interval_seconds").Trim() -Expected "1" -Message "Generated watch config poll interval mismatch."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $watchConfigPath -Section "storage" -Key "dir").Trim() -Expected (Get-TomlSectionValue -Path $generatedConfig -Section "storage" -Key "dir").Trim() -Message "Generated watch config changed the formal index location."

    $automaticStatusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $automaticStatusResult -ExitCode 0 -Label "Automatic watcher Status"
    $automaticStatus = Get-LastJsonObject -Result $automaticStatusResult -Label "Automatic watcher Status"
    Assert-Equal -Actual $automaticStatus.action -Expected "running" -Message "Automatic watcher did not reach running."
    Assert-Equal -Actual $automaticStatus.provider_state -Expected "ready" -Message "Automatic watcher provider did not reach ready."
    Assert-Equal -Actual $automaticStatus.adapter_state -Expected "watching" -Message "Automatic watcher adapter did not reach watching."
    Assert-True -Condition ($automaticStatus.provider_query_count -ge 1) -Message "Automatic wrapper did not route its Provider query through the coordinator."
    $activeWatchManagerPath = $materializedWatchManager

    $coordinatorState = Get-Content -LiteralPath $coordinatorStatePath -Raw | ConvertFrom-Json
    $unauthorizedQuery = Invoke-CoordinatorPipeRequest -StatePath $coordinatorStatePath -Request ([ordered]@{
        schema_version = 1
        auth_token = "invalid-token"
        command = "query"
        tool = "codedb_text_search"
        arguments = [ordered]@{ query = "CODEDB_SCOPE_CONTRACT"; limit = 1 }
    })
    Assert-Equal -Actual $unauthorizedQuery.ok -Expected $false -Message "Coordinator accepted an invalid query token."
    Assert-Equal -Actual $unauthorizedQuery.error_code -Expected "UNAUTHORIZED" -Message "Coordinator unauthorized-query error code mismatch."

    $unsupportedQuery = Invoke-CoordinatorPipeRequest -StatePath $coordinatorStatePath -Request ([ordered]@{
        schema_version = 1
        auth_token = [string]$coordinatorState.auth_token
        command = "query"
        tool = "codedb_read"
        arguments = [ordered]@{ path = "Assets/MaterializerFreshnessProbe.cs" }
    })
    Assert-Equal -Actual $unsupportedQuery.ok -Expected $false -Message "Coordinator exposed a Provider tool outside the query allowlist."
    Assert-Equal -Actual $unsupportedQuery.error_code -Expected "INVALID_QUERY" -Message "Coordinator unsupported-query error code mismatch."

    $scopedTextSearch = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_text_search" `
        -Arguments ([ordered]@{ query = "CODEDB_SCOPE_CONTRACT"; path = "Assets/Scoped"; limit = 2; regex = $true }) `
        -WaitForCoordinatorStatePath $coordinatorStatePath
    Assert-True -Condition ($scopedTextSearch.Contains('"path_glob":"Assets/Scoped/**"')) -Message "Wrapper did not normalize path to a directory path_glob before Provider routing."
    Assert-True -Condition (-not $scopedTextSearch.Contains('"path":"Assets/Scoped"')) -Message "Wrapper forwarded the legacy path alias to the Provider."
    Assert-True -Condition ($scopedTextSearch.Contains('"regex":true')) -Message "Wrapper stripped the regex flag before Provider routing."
    Assert-Equal -Actual ([regex]::Matches($scopedTextSearch, '(?m)^\[HIT\] ').Count) -Expected 2 -Message "Merged text search did not enforce one global limit."
    Assert-True -Condition ($scopedTextSearch.Contains("Assets/Scoped/ScopedProbe.cs:1 [provider]")) -Message "Scoped text search omitted the Provider C# lane."
    Assert-True -Condition ($scopedTextSearch.Contains("Assets/Scoped/ScopedProbe.shader:2 [provider+shader-adapter]")) -Message "Scoped text search did not deduplicate and merge the Shader lanes."
    Assert-True -Condition (-not $scopedTextSearch.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Scoped text search leaked a Provider result outside path_glob."
    Assert-True -Condition (-not $scopedTextSearch.Contains("Assets/Scoped/SecondScopedProbe.cs")) -Message "Scoped text search exceeded its global result limit."
    Assert-True -Condition ($scopedTextSearch.Contains("[LIMIT] Global result limit 2 applied")) -Message "Scoped text search did not disclose global limiting."
    Assert-True -Condition ($scopedTextSearch.Contains("[FIXTURE PROVIDER] mode=mcp pid=$($automaticStatus.provider_pid)")) -Message "Scoped text search did not reuse the coordinator-owned Provider process."
    $scopedTextSearchTiming = Get-WrapperTiming -Text $scopedTextSearch -Label "Scoped dual-lane text search"
    Assert-Equal -Actual $scopedTextSearchTiming.tool -Expected "codedb_text_search" -Message "Scoped text search timing tool mismatch."
    Assert-True -Condition ($scopedTextSearchTiming.queue_ms -ge 0) -Message "Shared Provider query reported negative queue time."
    Assert-Equal -Actual $scopedTextSearchTiming.provider_route -Expected "coordinator" -Message "Scoped text search reported the wrong Provider route."
    Assert-Equal -Actual $scopedTextSearchTiming.provider_shared -Expected $false -Message "Isolated scoped text search unexpectedly joined another flight."
    Assert-True -Condition ($scopedTextSearchTiming.provider_process_ms -gt 0) -Message "Scoped text search did not report Provider process wall time."
    Assert-True -Condition ($null -eq $scopedTextSearchTiming.provider_core_ms) -Message "Persistent Provider query unexpectedly reported uncorrelated core timing."
    Assert-Equal -Actual $scopedTextSearchTiming.provider_attempts -Expected 1 -Message "Scoped text search Provider attempt count mismatch."
    Assert-True -Condition ($scopedTextSearchTiming.adapter_ms -ge 0) -Message "Scoped text search adapter timing is negative."
    Assert-True -Condition ($scopedTextSearchTiming.merge_ms -ge 0) -Message "Scoped text search merge timing is negative."
    Assert-True -Condition ($scopedTextSearchTiming.total_ms -ge $scopedTextSearchTiming.provider_process_ms) -Message "Scoped text search total timing is below Provider process time."

    $scopedSemanticSearch = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_search" `
        -Arguments ([ordered]@{ query = "CODEDB_SEARCH_CONTRACT"; path_glob = "Assets/Scoped/**"; limit = 2 })
    Assert-Equal -Actual ([regex]::Matches($scopedSemanticSearch, '(?m)^\[HIT\] ').Count) -Expected 2 -Message "Semantic search parser returned the wrong unique hit count."
    Assert-True -Condition ($scopedSemanticSearch.Contains("Assets/Scoped/ScopedProbe.cs:1-2 [provider]")) -Message "Semantic search did not parse the Provider chunk range."
    Assert-True -Condition ($scopedSemanticSearch.Contains("Assets/Scoped/ScopedProbe.shader:1-3 [provider+shader-adapter]")) -Message "Semantic search did not merge an Adapter line into its Provider chunk."
    Assert-True -Condition (-not $scopedSemanticSearch.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Semantic search leaked an out-of-scope chunk."

    $scopedFind = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_find" `
        -Arguments ([ordered]@{ query = "CODEDB_FIND_CONTRACT"; path = "Assets/Scoped"; language = "CSharp"; limit = 1 })
    Assert-Equal -Actual ([regex]::Matches($scopedFind, '(?m)^\[HIT\] ').Count) -Expected 1 -Message "Find parser returned the wrong scoped hit count."
    Assert-True -Condition ($scopedFind.Contains("Assets/Scoped/SecondScopedProbe.cs [provider]")) -Message "Find parser omitted the in-scope Provider result."
    Assert-True -Condition (-not $scopedFind.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Find parser leaked an out-of-scope Provider result."

    $scopedContext = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_context" `
        -Arguments ([ordered]@{ query = "CODEDB_SCOPE_CONTRACT"; path = "Assets/Scoped"; limit = 2 })
    Assert-True -Condition ($scopedContext.Contains("CodeDB read Assets/Scoped/ScopedProbe.cs")) -Message "Context omitted the bounded C# lane."
    Assert-True -Condition ($scopedContext.Contains("Shader adapter read Assets/Scoped/ScopedProbe.shader")) -Message "Context omitted the bounded Shader lane."
    Assert-True -Condition (-not $scopedContext.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Context leaked an out-of-scope Provider result."
    Assert-True -Condition (-not $scopedContext.Contains("Assets/Scoped/SecondScopedProbe.cs")) -Message "Context exceeded its global result limit."
    Assert-True -Condition ($scopedContext.Contains("[LIMIT] Global context result limit 2 applied")) -Message "Context did not disclose its global result limit."
    Write-Host "[OK] Materialized wrapper normalized scopes and enforced dual-lane merge, deduplication, and global limits."

    $beforeSingleFlightResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $beforeSingleFlightResult -ExitCode 0 -Label "Pre-single-flight watcher Status"
    $beforeSingleFlight = Get-LastJsonObject -Result $beforeSingleFlightResult -Label "Pre-single-flight watcher Status"

    $concurrentQueryTexts = @(Invoke-ConcurrentWrapperQueries -WrapperPath $materializedWrapper -Root $hostRoot)
    Assert-Equal -Actual $concurrentQueryTexts.Count -Expected 3 -Message "Concurrent wrapper query result count mismatch."
    Assert-True -Condition ($concurrentQueryTexts[0].Contains("CODEDB_SINGLEFLIGHT_CONTRACT_A")) -Message "First shared query omitted its token."
    Assert-True -Condition ($concurrentQueryTexts[1].Contains("CODEDB_SINGLEFLIGHT_CONTRACT_A")) -Message "Second shared query omitted its token."
    Assert-True -Condition ($concurrentQueryTexts[2].Contains("CODEDB_SINGLEFLIGHT_CONTRACT_B")) -Message "Queued distinct query omitted its token."

    $concurrentTimings = @()
    for ($index = 0; $index -lt $concurrentQueryTexts.Count; $index += 1) {
        Assert-True -Condition ($concurrentQueryTexts[$index].Contains("[FIXTURE PROVIDER] mode=mcp pid=$($automaticStatus.provider_pid)")) -Message "Concurrent wrapper $index did not reuse the coordinator Provider PID."
        $timing = Get-WrapperTiming -Text $concurrentQueryTexts[$index] -Label "Concurrent wrapper query $index"
        Assert-Equal -Actual $timing.provider_route -Expected "coordinator" -Message "Concurrent wrapper $index reported the wrong Provider route."
        $concurrentTimings += $timing
    }
    Assert-Equal -Actual (($concurrentTimings | Measure-Object -Property provider_attempts -Sum).Sum) -Expected 2 -Message "Three concurrent wrappers did not collapse to two Provider executions."
    Assert-Equal -Actual @($concurrentTimings | Where-Object { $_.provider_shared -eq $true }).Count -Expected 1 -Message "Exactly one duplicate wrapper query should join a single flight."
    Assert-True -Condition ($concurrentTimings[2].queue_ms -ge 200) -Message "Distinct queued query did not report real queue wait."

    $afterSingleFlightResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $afterSingleFlightResult -ExitCode 0 -Label "Post-single-flight watcher Status"
    $afterSingleFlight = Get-LastJsonObject -Result $afterSingleFlightResult -Label "Post-single-flight watcher Status"
    Assert-Equal -Actual ($afterSingleFlight.provider_query_count - $beforeSingleFlight.provider_query_count) -Expected 3 -Message "Coordinator client-query count mismatch."
    Assert-Equal -Actual ($afterSingleFlight.provider_query_execution_count - $beforeSingleFlight.provider_query_execution_count) -Expected 2 -Message "Coordinator Provider execution count mismatch."
    Assert-Equal -Actual ($afterSingleFlight.provider_query_shared_count - $beforeSingleFlight.provider_query_shared_count) -Expected 1 -Message "Coordinator single-flight join count mismatch."
    Assert-Equal -Actual $afterSingleFlight.provider_query_inflight_count -Expected 0 -Message "Coordinator retained a completed query flight."
    Assert-Equal -Actual $afterSingleFlight.provider_query_queue_depth -Expected 0 -Message "Coordinator retained a completed query queue entry."
    Assert-Equal -Actual $afterSingleFlight.lifecycle_id -Expected $automaticLifecycleId -Message "Concurrent queries changed the coordinator lifecycle."
    Assert-Equal -Actual $afterSingleFlight.provider_pid -Expected $automaticStatus.provider_pid -Message "Concurrent queries replaced the persistent Provider process."
    Write-Host "[OK] Three concurrent wrappers reused one Provider, joined identical work, and reported real queue time without implicit batching."

    $secondaryEditorLeasePath = New-TestEditorLease -LeaseRoot $editorLeaseRoot -Root $hostRoot -SessionId "fixture-editor-secondary"
    Assert-True -Condition (Wait-ForEditorSessionCount -StatePath $coordinatorStatePath -Count 2) -Message "Coordinator did not observe both same-project Editor leases."
    $twoEditorState = Get-Content -LiteralPath $coordinatorStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $twoEditorState.provider_pid -Expected $automaticStatus.provider_pid -Message "Second same-project Editor lease replaced the shared Provider."
    Remove-Item -LiteralPath $primaryEditorLeasePath -Force
    Assert-True -Condition (Wait-ForEditorSessionCount -StatePath $coordinatorStatePath -Count 1) -Message "Coordinator did not release only the closed Editor session."
    $oneEditorState = Get-Content -LiteralPath $coordinatorStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $oneEditorState.coordinator_pid -Expected $twoEditorState.coordinator_pid -Message "Closing one Editor replaced the shared coordinator."
    Assert-Equal -Actual $oneEditorState.provider_pid -Expected $twoEditorState.provider_pid -Message "Closing one Editor replaced the shared Provider."
    Write-Host "[OK] Two same-project Editor leases shared one coordinator and closing one kept the backend ready."

    $disableResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Disable -ExpectedLifecycleId $automaticLifecycleId
    }
    Assert-Result -Result $disableResult -ExitCode 0 -Label "Materialized watcher Disable"
    $activeWatchManagerPath = $null
    $activeWatchLifecycleId = $null
    Assert-True -Condition ($disableResult.Text.Contains("[OK] Start with Unity Editor: DISABLED")) -Message "Disable did not report the persisted startup policy."
    Assert-True -Condition ($disableResult.Text.Contains("[OK] Manual runtime: NONE")) -Message "Disable left a session override behind."
    Assert-True -Condition ($disableResult.Text.Contains("[OK] Automatic refresh: DISABLED")) -Message "Disable did not report the persisted disabled state."
    $disabledDesired = Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $disabledDesired.desired_state -Expected "disabled" -Message "Disable did not persist disabled desired state."
    Assert-True -Condition (Test-Path -LiteralPath $secondaryEditorLeasePath -PathType Leaf) -Message "Disable removed the online Editor lease."
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false) -Message "Disable left coordinator state behind."

    $pausedSearchError = Invoke-WrapperToolErrorProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_search" `
        -Arguments ([ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 })
    Assert-True -Condition ($pausedSearchError.Contains("[SERVICE_DISABLED]")) -Message "Disabled wrapper query did not return SERVICE_DISABLED."
    $pausedSearchTiming = Get-WrapperTiming -Text $pausedSearchError -Label "Disabled Provider query"
    Assert-Equal -Actual $pausedSearchTiming.provider_route -Expected "none" -Message "Disabled query reported a Provider route."
    Assert-Equal -Actual $pausedSearchTiming.provider_attempts -Expected 0 -Message "Disabled query started a Provider attempt."
    $pausedStatusText = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_status" `
        -Arguments ([ordered]@{})
    foreach ($expectedStatus in @(
        "Desired state: disabled",
        "Editor demand: online",
        "Automatic refresh: disabled",
        "Lifecycle reason: SERVICE_DISABLED",
        "Watch coordinator: stopped"
    )) {
        Assert-True -Condition ($pausedStatusText.Contains($expectedStatus)) -Message "Disabled wrapper status is missing '$expectedStatus'."
    }
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "A wrapper restarted automatic watch while disabled."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "A wrapper recreated coordinator state while disabled."

    $watchLifecycleId = "materializer-" + [guid]::NewGuid().ToString("N")
    $activeWatchManagerPath = $materializedWatchManager
    $activeWatchLifecycleId = $watchLifecycleId
    $startResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager `
            -Action Start `
            -PollIntervalSeconds 1 `
            -AdapterDebounceMilliseconds 200 `
            -LifecycleId $watchLifecycleId
    }
    Assert-Result -Result $startResult -ExitCode 0 -Label "Materialized watcher Start"
    $startStatus = Get-LastJsonObject -Result $startResult -Label "Materialized watcher Start"
    Assert-Equal -Actual $startStatus.action -Expected "started" -Message "Materialized watcher did not create a new coordinator lifecycle."
    Assert-Equal -Actual $startStatus.lifecycle_id -Expected $watchLifecycleId -Message "Materialized watcher lifecycle id mismatch."
    Assert-Equal -Actual $startStatus.exclusive_lifecycle -Expected $false -Message "Normal Editor-owned start unexpectedly enabled exclusive ownership."
    Assert-Equal -Actual $startStatus.provider_state -Expected "ready" -Message "Materialized watcher provider did not reach ready."
    Assert-Equal -Actual $startStatus.adapter_state -Expected "watching" -Message "Materialized watcher adapter did not reach watching."
    Assert-Equal -Actual $startStatus.adapter_worker_state -Expected "ready" -Message "Materialized watcher adapter worker did not reach ready."
    Assert-Equal -Actual $startStatus.editor_session_count -Expected 1 -Message "Resumed watcher lost the remaining Editor lease."
    $resumedDesired = Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $resumedDesired.desired_state -Expected "disabled" -Message "Manual Start changed the persisted startup policy."
    $startedManualRuntime = Get-Content -LiteralPath $manualRuntimePath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $startedManualRuntime.mode -Expected "started" -Message "Manual Start did not publish a session-scoped started override."
    Assert-True -Condition (@($startedManualRuntime.editor_session_ids) -contains "fixture-editor-secondary") -Message "Manual Start did not bind its override to the active Editor session."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchPausedMarkerPath)) -Message "Resume recreated the legacy Pause marker."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "Resume recreated the legacy enabled marker."

    $enableResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Enable
    }
    Assert-Result -Result $enableResult -ExitCode 0 -Label "Persistent watcher Enable"
    Assert-Equal -Actual (Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json).desired_state -Expected "enabled" -Message "Enable did not persist the Editor startup policy."
    Assert-Equal -Actual (Get-Content -LiteralPath $manualRuntimePath -Raw | ConvertFrom-Json).mode -Expected "started" -Message "Enable replaced the active session override."

    $preRestartLifecycleId = $watchLifecycleId
    $restartResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Restart -PollIntervalSeconds 1 -AdapterDebounceMilliseconds 200
    }
    Assert-Result -Result $restartResult -ExitCode 0 -Label "Session-scoped watcher Restart"
    $restartStatus = Get-LastJsonObject -Result $restartResult -Label "Session-scoped watcher Restart"
    Assert-Equal -Actual $restartStatus.action -Expected "started" -Message "Restart did not create a replacement coordinator lifecycle."
    Assert-True -Condition (-not [string]::Equals([string]$restartStatus.lifecycle_id, $preRestartLifecycleId, [StringComparison]::Ordinal)) -Message "Restart reused the previous coordinator lifecycle."
    Assert-Equal -Actual (Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json).desired_state -Expected "enabled" -Message "Restart changed the persisted startup policy."
    Assert-Equal -Actual (Get-Content -LiteralPath $manualRuntimePath -Raw | ConvertFrom-Json).mode -Expected "started" -Message "Restart did not retain the session-scoped started override."
    $watchLifecycleId = [string]$restartStatus.lifecycle_id
    $activeWatchLifecycleId = $watchLifecycleId

    $stopNowResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Stop -ExpectedLifecycleId $watchLifecycleId
    }
    Assert-Result -Result $stopNowResult -ExitCode 0 -Label "Session-scoped watcher Stop"
    Assert-True -Condition ($stopNowResult.Text.Contains("[OK] Start with Unity Editor: ENABLED")) -Message "Stop changed the persisted startup policy label."
    Assert-True -Condition ($stopNowResult.Text.Contains("[OK] Manual runtime: STOPPED")) -Message "Stop did not report its session override."
    Assert-True -Condition ($stopNowResult.Text.Contains("[OK] Automatic refresh: MANUAL_STOPPED")) -Message "Stop did not report MANUAL_STOPPED."
    Assert-Equal -Actual (Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json).desired_state -Expected "enabled" -Message "Stop changed the persisted startup policy."
    Assert-Equal -Actual (Get-Content -LiteralPath $manualRuntimePath -Raw | ConvertFrom-Json).mode -Expected "stopped" -Message "Stop did not persist a session-scoped stopped override."
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false) -Message "Stop left the coordinator running."

    $manualStopEnsure = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $manualStopEnsure -ExitCode 0 -Label "Ensure under MANUAL_STOPPED"
    Assert-True -Condition ($manualStopEnsure.Text.Contains("[OK] Manual runtime: STOPPED")) -Message "Ensure did not preserve the stopped session override."
    Assert-True -Condition ($manualStopEnsure.Text.Contains("[OK] Automatic refresh: MANUAL_STOPPED")) -Message "Ensure reversed MANUAL_STOPPED."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "Ensure restarted a manually stopped current session."

    Remove-Item -LiteralPath $secondaryEditorLeasePath -Force
    $secondaryEditorLeasePath = New-TestEditorLease -LeaseRoot $editorLeaseRoot -Root $hostRoot -SessionId "fixture-editor-reopened"
    $postSessionEnsure = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $postSessionEnsure -ExitCode 0 -Label "Ensure after Editor session replacement"
    $postSessionStatus = Get-LastJsonObject -Result $postSessionEnsure -Label "Ensure after Editor session replacement"
    Assert-Equal -Actual $postSessionStatus.action -Expected "started" -Message "A new Editor session did not resume the enabled startup policy."
    Assert-Equal -Actual $postSessionStatus.editor_session_count -Expected 1 -Message "Replacement Editor session count mismatch."
    Assert-True -Condition (-not (Test-Path -LiteralPath $manualRuntimePath)) -Message "Expired manual override remained after the original Editor session ended."
    $watchLifecycleId = [string]$postSessionStatus.lifecycle_id
    $activeWatchLifecycleId = $watchLifecycleId
    Write-Host "[OK] Persistent policy and session controls stayed independent; MANUAL_STOPPED survived Ensure and expired with its Editor session."

    $statusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $statusResult -ExitCode 0 -Label "Materialized watcher Status"
    $runningStatus = Get-LastJsonObject -Result $statusResult -Label "Materialized watcher Status"
    Assert-Equal -Actual $runningStatus.action -Expected "running" -Message "Materialized watcher Status did not report running."
    Assert-Equal -Actual $runningStatus.lifecycle_id -Expected $watchLifecycleId -Message "Materialized watcher Status reported another lifecycle."
    Assert-Equal -Actual $runningStatus.provider_state -Expected "ready" -Message "Materialized watcher Status provider mismatch."
    Assert-Equal -Actual $runningStatus.adapter_state -Expected "watching" -Message "Materialized watcher Status adapter mismatch."
    Assert-Equal -Actual $runningStatus.generation_id -Expected $generationId -Message "Watcher Status reported the wrong generation."
    Assert-True -Condition (Wait-ForGenerationLease -Owner "watcher" -ProcessId ([int]$runningStatus.coordinator_pid) -Present $true) -Message "Watcher daemon did not publish its generation lease."

    $beforeActiveWatcherDryRun = Get-ManagedPayloadSnapshot -Root $hostRoot
    $activeWatcherDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $activeWatcherDryRun -ExitCode 0 -Label "Active watcher DryRun guidance"
    Assert-True -Condition ($activeWatcherDryRun.Text.Contains("[ACTIVE] generation $generationId watcher PID $($runningStatus.coordinator_pid)")) -Message "DryRun did not identify the active generation watcher lease before Sync."
    Assert-True -Condition ($activeWatcherDryRun.Text.Contains("[BLOCKED] Host payload Sync/Remove is blocked")) -Message "DryRun did not explain the active host-use blocker."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeActiveWatcherDryRun -Message "DryRun lease guidance changed managed host tooling."

    $beforeActiveWatcherGate = Get-ManagedPayloadSnapshot -Root $hostRoot
    $activeWatcherSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $activeWatcherSync -ExitCode 4 -Label "Active watcher Sync gate"
    Assert-True -Condition ($activeWatcherSync.Text.Contains("[ACTIVE] generation $generationId watcher PID $($runningStatus.coordinator_pid)")) -Message "Active watcher Sync gate did not identify the coordinator generation lease."
    Assert-True -Condition (-not $activeWatcherSync.Text.Contains("[PLAN]")) -Message "Active watcher Sync gate ran after materialization planning."
    $activeWatcherRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $activeWatcherRemove -ExitCode 4 -Label "Active watcher Remove gate"
    Assert-True -Condition ($activeWatcherRemove.Text.Contains("[ACTIVE] generation $generationId watcher PID $($runningStatus.coordinator_pid)")) -Message "Active watcher Remove gate did not identify the coordinator generation lease."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeActiveWatcherGate -Message "Active watcher gates changed managed host tooling."

    $watcherLeasePaths = @(Get-GenerationLeasePaths -Owner "watcher" -ProcessId ([int]$runningStatus.coordinator_pid))
    Assert-Equal -Actual $watcherLeasePaths.Count -Expected 1 -Message "Watcher daemon did not own exactly one generation lease."
    Write-Host "[OK] Materialized watcher held one long-lived generation lease and blocked strict Sync/Remove."

    $readyCoordinatorState = Get-Content -LiteralPath $coordinatorStatePath -Raw | ConvertFrom-Json
    $global:LASTEXITCODE = 0
    $directStopOutput = @(& $nodePath $materializedCoordinator stop --runtime $coordinatorRuntime --expected-lifecycle-id $watchLifecycleId 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Direct fixture coordinator stop failed before wrapper recovery.`n$($directStopOutput -join [Environment]::NewLine)"
    }
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false) -Message "Direct coordinator stop left state behind."
    Assert-Equal -Actual (Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json).desired_state -Expected "enabled" -Message "Direct coordinator stop changed the desired state."

    $readyCoordinatorState.coordinator_pid = $PID
    $readyCoordinatorState.provider_pid = $PID
    $readyCoordinatorState.adapter_worker_pid = $PID
    $readyCoordinatorState.pipe_name = "\\.\pipe\codedb-watch-unreachable-fixture"
    $readyCoordinatorState.last_lease_scan_at_utc = [DateTime]::UtcNow.ToString("o")
    Write-Utf8File -Path $coordinatorStatePath -Content (($readyCoordinatorState | ConvertTo-Json -Depth 8) + "`n")
    $unreachableSearchError = Invoke-WrapperToolErrorProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_search" `
        -Arguments ([ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 })
    Assert-True -Condition ($unreachableSearchError.Contains("[COORDINATOR_UNREACHABLE]")) -Message "Ready state with an unreachable pipe did not return COORDINATOR_UNREACHABLE."
    Assert-True -Condition ($unreachableSearchError.Contains("transport_code=")) -Message "Unreachable coordinator error omitted its bounded transport code."
    Assert-True -Condition ($unreachableSearchError.Contains("pipe_id=sha256-")) -Message "Unreachable coordinator error omitted its hashed pipe identifier."
    Assert-True -Condition (-not $unreachableSearchError.Contains("codedb-watch-unreachable-fixture")) -Message "Unreachable coordinator error exposed the raw pipe name."
    $unreachableTiming = Get-WrapperTiming -Text $unreachableSearchError -Label "Unreachable coordinator query"
    Assert-Equal -Actual $unreachableTiming.provider_attempts -Expected 0 -Message "Unreachable coordinator query started a Provider attempt."
    $unreachableStatus = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_status" `
        -Arguments ([ordered]@{})
    foreach ($expectedStatus in @(
        "Automatic refresh: unreachable",
        "Lifecycle reason: COORDINATOR_UNREACHABLE",
        "Watch coordinator: unreachable",
        "Coordinator diagnostic: Could not connect to the Ready coordinator pipe."
    )) {
        Assert-True -Condition ($unreachableStatus.Contains($expectedStatus)) -Message "Unreachable coordinator status is missing '$expectedStatus'."
    }
    Remove-Item -LiteralPath $coordinatorStatePath -Force
    Write-Host "[OK] Ready metadata with an unreachable pipe failed explicitly without a Provider fallback."

    $stoppedSearchError = Invoke-WrapperToolErrorProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_search" `
        -Arguments ([ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 })
    Assert-True -Condition ($stoppedSearchError.Contains("[STARTING]")) -Message "Wrapper query did not report STARTING while Editor demand remained online."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "Wrapper query restarted the stopped coordinator."
    $stoppedTiming = Get-WrapperTiming -Text $stoppedSearchError -Label "Stopped coordinator query"
    Assert-Equal -Actual $stoppedTiming.provider_attempts -Expected 0 -Message "Stopped coordinator query started a Provider attempt."

    $editorReconcile = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $editorReconcile -ExitCode 0 -Label "Editor-owned watcher reconcile"
    $recoveredState = Get-LastJsonObject -Result $editorReconcile -Label "Editor-owned watcher reconcile"
    Assert-Equal -Actual $recoveredState.action -Expected "started" -Message "Editor owner did not recover the stopped coordinator."
    Assert-True -Condition (-not [string]::Equals([string]$recoveredState.lifecycle_id, $watchLifecycleId, [StringComparison]::Ordinal)) -Message "Recovered coordinator reused a completed lifecycle id."
    Assert-Equal -Actual $recoveredState.exclusive_lifecycle -Expected $false -Message "Editor reconcile changed exclusive ownership."
    Assert-Equal -Actual $recoveredState.provider_state -Expected "ready" -Message "Editor reconcile provider state mismatch."
    Assert-Equal -Actual $recoveredState.adapter_state -Expected "watching" -Message "Editor reconcile adapter state mismatch."
    $watchLifecycleId = [string]$recoveredState.lifecycle_id
    $activeWatchLifecycleId = $watchLifecycleId

    $wrapperWatchProbe = Invoke-WrapperWatchProbe -WrapperPath $materializedWrapper -Root $hostRoot
    Assert-True -Condition ($wrapperWatchProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.watch.toml")) -Message "Materialized wrapper did not route provider reads through the watch config."
    foreach ($expectedStatus in @(
        "Desired state: enabled",
        "Editor demand: online",
        "Watch coordinator: ready",
        "Shader watcher: watching",
        "Active provider config: AIWork/.runtime/codedb/codedb-fixture/config/codedb-mcp.watch.toml"
    )) {
        Assert-True -Condition ($wrapperWatchProbe.StatusText.Contains($expectedStatus)) -Message "Recovered wrapper status is missing '$expectedStatus'."
    }
    $permissionProbeHookPath = Join-Path $coordinatorRuntime "fixture-wrapper-eperm.cjs"
    Write-Utf8File -Path $permissionProbeHookPath -Content @'
const childProcess = require("node:child_process");
const { syncBuiltinESMExports } = require("node:module");

const originalKill = process.kill.bind(process);
const originalExecFile = childProcess.execFile.bind(childProcess);
const deniedPids = new Set(String(process.env.CODEDB_TEST_EPERM_PIDS ?? "").split(",").filter(Boolean));
process.kill = (pid, signal) => {
  if ((signal === 0 || signal === "0") && deniedPids.has(String(pid))) {
    const error = new Error("Fixture permission-denied process probe.");
    error.code = "EPERM";
    throw error;
  }
  return originalKill(pid, signal);
};
childProcess.execFile = (...args) => {
  if (process.env.CODEDB_TEST_FORBID_PROCESS_SNAPSHOT === "1") {
    throw new Error("Fresh Editor lease unexpectedly started a process snapshot.");
  }
  if (process.env.CODEDB_TEST_EMPTY_PROCESS_SNAPSHOT === "1") {
    const callback = args.at(-1);
    queueMicrotask(() => callback(null, "[]", ""));
    return undefined;
  }
  return originalExecFile(...args);
};
syncBuiltinESMExports();
'@
    $permissionState = Get-Content -LiteralPath $coordinatorStatePath -Raw | ConvertFrom-Json
    Set-TestEditorLeaseHeartbeat -Path $secondaryEditorLeasePath -HeartbeatUtc ([DateTime]::UtcNow)
    $freshPermissionProbe = Invoke-WrapperWatchProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -EnvironmentVariables @{
            NODE_OPTIONS = "--require=$permissionProbeHookPath"
            CODEDB_TEST_EPERM_PIDS = @(
                $PID,
                $permissionState.coordinator_pid,
                $permissionState.provider_pid,
                $permissionState.adapter_worker_pid
            ) -join ","
            CODEDB_TEST_FORBID_PROCESS_SNAPSHOT = "1"
        }
    Assert-True -Condition ($freshPermissionProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.watch.toml")) -Message "Fresh permission-denied PID probes prevented a Ready coordinator query."
    foreach ($expectedStatus in @(
        "Editor demand: online",
        "Lifecycle reason: READY",
        "Watch coordinator: ready"
    )) {
        Assert-True -Condition ($freshPermissionProbe.StatusText.Contains($expectedStatus)) -Message "Fresh permission-denied wrapper status is missing '$expectedStatus'."
    }
    Write-Host "[OK] Fresh Editor leases avoided the PowerShell process snapshot and preserved EPERM demand."

    Set-TestEditorLeaseHeartbeat -Path $secondaryEditorLeasePath -HeartbeatUtc ([DateTime]::UtcNow.AddSeconds(-30))
    $missingSnapshotProbe = Invoke-WrapperWatchProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -EnvironmentVariables @{
            NODE_OPTIONS = "--require=$permissionProbeHookPath"
            CODEDB_TEST_EPERM_PIDS = @(
                $PID,
                $permissionState.coordinator_pid,
                $permissionState.provider_pid,
                $permissionState.adapter_worker_pid
            ) -join ","
            CODEDB_TEST_EMPTY_PROCESS_SNAPSHOT = "1"
        }
    Assert-True -Condition ($missingSnapshotProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.watch.toml")) -Message "Missing process snapshot rows prevented a Ready coordinator query."
    foreach ($expectedStatus in @(
        "Editor demand: online",
        "Lifecycle reason: READY",
        "Watch coordinator: ready"
    )) {
        Assert-True -Condition ($missingSnapshotProbe.StatusText.Contains($expectedStatus)) -Message "Missing-snapshot wrapper status is missing '$expectedStatus'."
    }
    Write-Host "[OK] Missing process snapshot rows and permission-denied PID probes preserved live Editor demand."
    Set-TestEditorLeaseHeartbeat -Path $secondaryEditorLeasePath -HeartbeatUtc ([DateTime]::UtcNow)
    $activeCommonPath = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/codedb-project-common.ps1")
    $activeReadConfig = Invoke-PowerShellAction -Action {
        . $activeCommonPath
        $activeContext = Get-ProjectCodedbContext
        Get-ProjectCodedbActiveReadConfigPath -Context $activeContext
    }
    Assert-Result -Result $activeReadConfig -ExitCode 0 -Label "Active read-config selection"
    Assert-Equal -Actual $activeReadConfig.Text.Trim() -Expected ([System.IO.Path]::GetFullPath($watchConfigPath)) -Message "Active read-config selection did not return the live watch config."
    $activeProviderProbePath = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/probe-codedb-project-index.ps1")
    $activeProviderProbe = Invoke-PowerShellAction -Action {
        & $activeProviderProbePath -Check CSharpProbe
    }
    Assert-Result -Result $activeProviderProbe -ExitCode 0 -Label "Active watcher provider probe"
    Assert-True -Condition ($activeProviderProbe.Text.Contains("[OK] C# probe passed")) -Message "Active provider probe did not complete against the live watch config."
    Write-Host "[OK] Wrapper stayed read-only while the Editor owner recovered a stopped coordinator."

    $wrongLifecycleId = "foreign-" + [guid]::NewGuid().ToString("N")
    $manualRuntimeBeforeWrongStop = if (Test-Path -LiteralPath $manualRuntimePath -PathType Leaf) {
        Get-Content -LiteralPath $manualRuntimePath -Raw
    } else {
        $null
    }
    $wrongStopResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Stop -ExpectedLifecycleId $wrongLifecycleId
    }
    Assert-True -Condition ($wrongStopResult.ExitCode -ne 0) -Message "Materialized watcher accepted a foreign lifecycle Stop."
    Assert-True -Condition ($wrongStopResult.Text.Contains("another lifecycle")) -Message "Foreign lifecycle Stop did not report coordinator ownership refusal."
    Assert-Equal -Actual (Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json).desired_state -Expected "enabled" -Message "Foreign lifecycle Stop changed desired state."
    $manualRuntimeAfterWrongStop = if (Test-Path -LiteralPath $manualRuntimePath -PathType Leaf) {
        Get-Content -LiteralPath $manualRuntimePath -Raw
    } else {
        $null
    }
    Assert-Equal -Actual $manualRuntimeAfterWrongStop -Expected $manualRuntimeBeforeWrongStop -Message "Rejected foreign lifecycle Stop changed the session override."
    $statusAfterWrongStop = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $statusAfterWrongStop -ExitCode 0 -Label "Post-refusal watcher Status"
    $stateAfterWrongStop = Get-LastJsonObject -Result $statusAfterWrongStop -Label "Post-refusal watcher Status"
    Assert-Equal -Actual $stateAfterWrongStop.lifecycle_id -Expected $watchLifecycleId -Message "Foreign lifecycle Stop changed the live coordinator owner."

    $wrapperMonitorStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $wrapperMonitorStartInfo.FileName = $nodePath
    $wrapperMonitorStartInfo.Arguments = "`"$materializedWrapper`" --root `"$hostRoot`""
    $wrapperMonitorStartInfo.WorkingDirectory = $hostRoot
    $wrapperMonitorStartInfo.UseShellExecute = $false
    $wrapperMonitorStartInfo.CreateNoWindow = $true
    $wrapperMonitorStartInfo.RedirectStandardInput = $true
    $wrapperMonitorStartInfo.RedirectStandardOutput = $true
    $wrapperMonitorStartInfo.RedirectStandardError = $true
    $wrapperMonitorProcess = [System.Diagnostics.Process]::new()
    $wrapperMonitorProcess.StartInfo = $wrapperMonitorStartInfo
    $null = $wrapperMonitorProcess.Start()
    $activeMcpProcess = $wrapperMonitorProcess
    $wrapperMonitorStderr = $wrapperMonitorProcess.StandardError.ReadToEndAsync()
    $null = Invoke-WrapperRpc -Process $wrapperMonitorProcess -Request ([ordered]@{
        jsonrpc = "2.0"
        id = 401
        method = "initialize"
        params = [ordered]@{ protocolVersion = "2024-11-05" }
    })
    Remove-Item -LiteralPath $secondaryEditorLeasePath -Force
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false -TimeoutMilliseconds 10000) -Message "Last Editor lease removal did not stop the coordinator."
    Assert-True -Condition (-not $wrapperMonitorProcess.HasExited) -Message "Wrapper exited when Unity Editor demand went offline."
    $sameProcessOfflineRpc = Invoke-WrapperRpcError -Process $wrapperMonitorProcess -Request ([ordered]@{
        jsonrpc = "2.0"
        id = 402
        method = "tools/call"
        params = [ordered]@{
            name = "codedb_search"
            arguments = [ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 }
        }
    })
    Assert-True -Condition (([string]$sameProcessOfflineRpc.error.message).Contains("[EDITOR_OFFLINE]")) -Message "Long-lived wrapper did not return EDITOR_OFFLINE after the last Editor closed."
    Assert-True -Condition (-not $wrapperMonitorProcess.HasExited) -Message "Wrapper exited after reporting EDITOR_OFFLINE."
    Assert-True -Condition (Wait-ForGenerationLease -Owner "mcp" -ProcessId $wrapperMonitorProcess.Id -Present $false) -Message "Offline request left a generation lease behind."

    $sameProcessReopenedLease = New-TestEditorLease -LeaseRoot $editorLeaseRoot -Root $hostRoot -SessionId "fixture-editor-wrapper-reopen"
    $sameProcessEnsure = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-Result -Result $sameProcessEnsure -ExitCode 0 -Label "Same-wrapper Editor reopen Ensure"
    $sameProcessReady = Get-LastJsonObject -Result $sameProcessEnsure -Label "Same-wrapper Editor reopen Ensure"
    Assert-Equal -Actual $sameProcessReady.action -Expected "started" -Message "Editor reopen did not restart the coordinator."
    $activeWatchManagerPath = $materializedWatchManager
    $activeWatchLifecycleId = [string]$sameProcessReady.lifecycle_id
    $sameProcessRecoveredRpc = Invoke-WrapperRpc -Process $wrapperMonitorProcess -Request ([ordered]@{
        jsonrpc = "2.0"
        id = 403
        method = "tools/call"
        params = [ordered]@{
            name = "codedb_search"
            arguments = [ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 }
        }
    })
    Assert-True -Condition (([string]$sameProcessRecoveredRpc.result.content[0].text).Contains("[FIXTURE PROVIDER]")) -Message "Same wrapper process did not recover after Editor reopen."
    Assert-True -Condition (Wait-ForGenerationLease -Owner "mcp" -ProcessId $wrapperMonitorProcess.Id -Present $false) -Message "Recovered request left a generation lease behind."

    $wrapperMonitorProcess.StandardInput.Close()
    if (-not $wrapperMonitorProcess.WaitForExit(10000)) {
        $wrapperMonitorProcess.Kill()
        throw "Wrapper did not exit after stdin closed."
    }
    Assert-Equal -Actual $wrapperMonitorProcess.ExitCode -Expected 0 -Message "Wrapper exited with an error after the recovery probe."
    Assert-True -Condition ([string]::IsNullOrWhiteSpace($wrapperMonitorStderr.Result)) -Message "Wrapper reported stderr during offline/reopen recovery."
    $wrapperMonitorProcess.Dispose()
    $activeMcpProcess = $null
    Remove-Item -LiteralPath $sameProcessReopenedLease -Force
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false -TimeoutMilliseconds 10000) -Message "Closing the reopened Editor session did not stop the coordinator."
    $activeWatchManagerPath = $null
    $activeWatchLifecycleId = $null
    Write-Host "[OK] One wrapper process survived Editor offline state and resumed queries after Editor reopen."

    $offlineSearchError = Invoke-WrapperToolErrorProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_search" `
        -Arguments ([ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 })
    Assert-True -Condition ($offlineSearchError.Contains("[EDITOR_OFFLINE]")) -Message "Offline wrapper query did not return EDITOR_OFFLINE."
    $offlineTiming = Get-WrapperTiming -Text $offlineSearchError -Label "Offline Provider query"
    Assert-Equal -Actual $offlineTiming.provider_attempts -Expected 0 -Message "Offline query started a Provider attempt."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "Offline wrapper query started the coordinator."

    $staleHeartbeatLease = New-TestEditorLease `
        -LeaseRoot $editorLeaseRoot `
        -Root $hostRoot `
        -SessionId "fixture-editor-stale-heartbeat" `
        -HeartbeatUtc ([DateTime]::UtcNow.AddSeconds(-91))
    $staleHeartbeatStatus = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $staleHeartbeatStatus -ExitCode 0 -Label "Read-only stale-heartbeat Status"
    Assert-True -Condition (Test-Path -LiteralPath $staleHeartbeatLease -PathType Leaf) -Message "Read-only Status reclaimed an Editor lease."
    Assert-True -Condition ($staleHeartbeatStatus.Text.Contains("Editor demand: OFFLINE (0)")) -Message "Read-only Status counted a stale Editor heartbeat as online."
    $staleHeartbeatEnsure = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-True -Condition ($staleHeartbeatEnsure.ExitCode -ne 0) -Message "Coordinator accepted an Editor heartbeat older than 90 seconds."
    Assert-True -Condition ($staleHeartbeatEnsure.Text.Contains("EDITOR_OFFLINE")) -Message "Stale heartbeat rejection did not report EDITOR_OFFLINE."
    Assert-True -Condition (-not (Test-Path -LiteralPath $staleHeartbeatLease)) -Message "Coordinator did not reclaim the stale heartbeat lease."
    Write-Host "[OK] Offline Status preserved stale leases while the Editor-owned Ensure path reclaimed them."

    $mismatchedIdentityLease = New-TestEditorLease `
        -LeaseRoot $editorLeaseRoot `
        -Root $hostRoot `
        -SessionId "fixture-editor-wrong-start" `
        -ProcessStartTicks "1" `
        -HeartbeatUtc ([DateTime]::UtcNow.AddSeconds(-30))
    $mismatchedIdentityWrapperStatus = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_status" `
        -Arguments ([ordered]@{})
    Assert-True -Condition ($mismatchedIdentityWrapperStatus.Contains("Editor demand: offline")) -Message "Wrapper counted a PID-reused Editor lease as online."
    Assert-True -Condition ($mismatchedIdentityWrapperStatus.Contains("Lifecycle reason: EDITOR_OFFLINE")) -Message "Wrapper PID-reuse status did not report EDITOR_OFFLINE."
    Assert-True -Condition (Test-Path -LiteralPath $mismatchedIdentityLease -PathType Leaf) -Message "Read-only wrapper status reclaimed a PID-reused Editor lease."
    $mismatchedIdentityStop = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Stop
    }
    Assert-True -Condition ($mismatchedIdentityStop.ExitCode -ne 0) -Message "Stop accepted a PID-reused Editor lease."
    Assert-True -Condition ($mismatchedIdentityStop.Text.Contains("require an interactive Unity Editor session")) -Message "PID-reused Stop rejection omitted the Editor-session boundary."
    Assert-True -Condition (-not (Test-Path -LiteralPath $manualRuntimePath)) -Message "Rejected PID-reused Stop wrote manual runtime state."
    Assert-True -Condition (Test-Path -LiteralPath $mismatchedIdentityLease -PathType Leaf) -Message "Watcher manager reclaimed a lease owned by the coordinator."
    $mismatchedIdentityEnsure = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Ensure
    }
    Assert-True -Condition ($mismatchedIdentityEnsure.ExitCode -ne 0) -Message "Coordinator accepted a mismatched Editor process-start identity."
    Assert-True -Condition ($mismatchedIdentityEnsure.Text.Contains("EDITOR_OFFLINE")) -Message "Process identity rejection did not report EDITOR_OFFLINE."
    Assert-True -Condition (-not (Test-Path -LiteralPath $mismatchedIdentityLease)) -Message "Coordinator did not reclaim the mismatched process lease."

    $disableFinal = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Disable
    }
    Assert-Result -Result $disableFinal -ExitCode 0 -Label "Final persistent disable"

    $finalStatusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $finalStatusResult -ExitCode 0 -Label "Materialized watcher final Status"
    Assert-True -Condition ($finalStatusResult.Text.Contains("[OK] Watch opt-in: DISABLED")) -Message "Final watcher Status did not report disabled opt-in."
    $finalStatus = Get-LastJsonObject -Result $finalStatusResult -Label "Materialized watcher final Status"
    Assert-Equal -Actual $finalStatus.action -Expected "stopped" -Message "Final watcher Status did not report stopped."
    Assert-Equal -Actual $finalStatus.coordinator_pid -Expected $null -Message "Final watcher Status retained a coordinator PID."
    Assert-Equal -Actual $finalStatus.adapter_state -Expected "stopped" -Message "Final watcher adapter state mismatch."
    Assert-Equal -Actual $finalStatus.desired_state -Expected "disabled" -Message "Final watcher desired state mismatch."
    Assert-Equal -Actual $finalStatus.editor_session_count -Expected 0 -Message "Final watcher retained an Editor lease."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Watcher lifecycle changed the formal provider config."
    Write-Host "[OK] Last Editor exit stopped all backend ownership, stale leases were rejected, and manual disable persisted."

    $materializedProjectVerify = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/verify-codedb-project.ps1")
    $materializedProjectRefresh = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/refresh-codedb-project.ps1")
    $materializedIndexClear = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/clear-codedb-project-index.ps1")
    $materializedIgnoreTemplate = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "codedbignore.example")
    $generatedIgnorePath = Join-Path $hostRoot ".codedbignore"
    $providerRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture"
    $providerIndexRoot = Join-Path $providerRoot "index"
    $providerManifestPath = Join-Path $providerIndexRoot "manifest.json"
    $providerLogsSentinel = Join-Path $providerRoot "logs\setup-index-preserve.log"
    $providerTempSentinel = Join-Path $providerRoot "tmp\setup-index-preserve.tmp"
    $staleIndexSentinel = Join-Path $providerIndexRoot "stale-before-clean.txt"
    Write-Utf8File -Path $providerLogsSentinel -Content "preserve provider logs`n"
    Write-Utf8File -Path $providerTempSentinel -Content "preserve provider temp`n"
    Write-Utf8File -Path $staleIndexSentinel -Content "stale provider index`n"

    $providerExecutableHash = (Get-FileHash -LiteralPath $fixtureProviderExecutable -Algorithm SHA256).Hash
    $formalConfigHash = (Get-FileHash -LiteralPath $generatedConfig -Algorithm SHA256).Hash
    $watchConfigHash = (Get-FileHash -LiteralPath $watchConfigPath -Algorithm SHA256).Hash
    $providerLogsHash = (Get-FileHash -LiteralPath $providerLogsSentinel -Algorithm SHA256).Hash
    $providerTempHash = (Get-FileHash -LiteralPath $providerTempSentinel -Algorithm SHA256).Hash
    $adapterRoot = Join-Path $providerRoot "adapter\text-index"
    $adapterSnapshotBeforeSetupIndex = Get-FileSnapshot -Root $adapterRoot

    $refreshResult = Invoke-PowerShellAction -Action {
        & $materializedProjectRefresh -GenerateUnityIgnore -CleanFirst
    }
    Assert-Result -Result $refreshResult -ExitCode 0 -Label "Materialized project refresh"
    foreach ($expectedRefreshOutput in @(
        "[FIXTURE PROVIDER] indexed --no-watch",
        "[OK] Host project CodeDB index refresh completed."
    )) {
        Assert-True -Condition ($refreshResult.Text.Contains($expectedRefreshOutput)) -Message "Materialized refresh is missing '$expectedRefreshOutput'."
    }
    Assert-True -Condition (Test-Path -LiteralPath $providerManifestPath -PathType Leaf) -Message "Materialized refresh did not publish the provider manifest."
    Assert-True -Condition (-not (Test-Path -LiteralPath $staleIndexSentinel)) -Message "Materialized CleanFirst refresh retained stale provider index data."
    $providerManifest = Get-Content -LiteralPath $providerManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $providerManifest.fixture -Expected $true -Message "Fixture provider manifest identity mismatch."
    Assert-Equal -Actual $providerManifest.no_watch -Expected $true -Message "Materialized refresh did not enforce --no-watch."
    Assert-True -Condition (Test-Path -LiteralPath $generatedIgnorePath -PathType Leaf) -Message "Materialized refresh did not generate .codedbignore."
    Assert-Equal -Actual (Get-Content -LiteralPath $generatedIgnorePath -Raw) -Expected (Get-Content -LiteralPath $materializedIgnoreTemplate -Raw) -Message "Generated .codedbignore does not match the materialized template."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Materialized refresh changed formal watch policy."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $fixtureProviderExecutable -Algorithm SHA256).Hash -Expected $providerExecutableHash -Message "Materialized refresh changed the provider executable."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $generatedConfig -Algorithm SHA256).Hash -Expected $formalConfigHash -Message "Materialized refresh changed the formal provider config."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $watchConfigPath -Algorithm SHA256).Hash -Expected $watchConfigHash -Message "Materialized refresh changed the watch config."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterSnapshotBeforeSetupIndex -Message "Materialized refresh changed Shader/HLSL adapter data."
    Write-Host "[OK] Materialized refresh rebuilt only the formal no-watch provider index."

    $projectVerifyResult = Invoke-PowerShellAction -Action {
        & $materializedProjectVerify
    }
    Assert-Result -Result $projectVerifyResult -ExitCode 0 -Label "Materialized project verification"
    foreach ($expectedVerificationOutput in @(
        "Provider executable and runtime config are present and use Unity-root-relative paths.",
        "Generated .codedbignore matches the AIWork template.",
        "Generated codedb runtime paths do not appear in git status.",
        "Host project CodeDB structure verification passed."
    )) {
        Assert-True -Condition ($projectVerifyResult.Text.Contains($expectedVerificationOutput)) -Message "Materialized verification is missing '$expectedVerificationOutput'."
    }
    Write-Host "[OK] Materialized project verification accepted isolated ignored runtime state."

    $beforeClearPreview = Get-FileSnapshot -Root $providerRoot
    $clearPreviewResult = Invoke-PowerShellAction -Action {
        & $materializedIndexClear -WhatIf
    }
    Assert-Result -Result $clearPreviewResult -ExitCode 0 -Label "Materialized index clear preview"
    Assert-True -Condition ($clearPreviewResult.Text.Contains("[OK] Index clean preview completed")) -Message "Materialized index clear preview did not report WhatIf completion."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerRoot) -Expected $beforeClearPreview -Message "Materialized index clear preview changed provider runtime."

    $clearResult = Invoke-PowerShellAction -Action {
        & $materializedIndexClear -Confirm:$false
    }
    Assert-Result -Result $clearResult -ExitCode 0 -Label "Materialized index clear"
    Assert-True -Condition ($clearResult.Text.Contains("[OK] Index clean completed")) -Message "Materialized index clear did not report completion."
    Assert-True -Condition (-not (Test-Path -LiteralPath $providerIndexRoot)) -Message "Materialized index clear retained provider index data."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $fixtureProviderExecutable -Algorithm SHA256).Hash -Expected $providerExecutableHash -Message "Materialized index clear changed the provider executable."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $generatedConfig -Algorithm SHA256).Hash -Expected $formalConfigHash -Message "Materialized index clear changed the formal provider config."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $watchConfigPath -Algorithm SHA256).Hash -Expected $watchConfigHash -Message "Materialized index clear changed the watch config."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterSnapshotBeforeSetupIndex -Message "Materialized index clear changed Shader/HLSL adapter data."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $providerLogsSentinel -Algorithm SHA256).Hash -Expected $providerLogsHash -Message "Materialized index clear changed provider logs."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $providerTempSentinel -Algorithm SHA256).Hash -Expected $providerTempHash -Message "Materialized index clear changed provider temp state."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "Materialized index clear recreated the watcher opt-in marker."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "Materialized index clear recreated coordinator state."
    Assert-True -Condition (Test-Path -LiteralPath $generatedIgnorePath -PathType Leaf) -Message "Materialized index clear removed generated .codedbignore."

    $clearMissingResult = Invoke-PowerShellAction -Action {
        & $materializedIndexClear -Confirm:$false
    }
    Assert-Result -Result $clearMissingResult -ExitCode 0 -Label "Materialized missing-index clear"
    Assert-True -Condition ($clearMissingResult.Text.Contains("[SKIP] No generated codedb index existed")) -Message "Materialized missing-index clear did not report SKIP."
    Write-Host "[OK] Materialized clear preview and index-only cleanup preserved every adjacent runtime owner."

    $materializedProviderProbe = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/probe-codedb-project-index.ps1")
    $materializedAdapterProbe = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/probe-codedb-project-text-adapter.ps1")
    $materializedFreshnessCheck = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/check-codedb-project-freshness.ps1")
    $materializedRefreshIfStale = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/refresh-codedb-project-if-stale.ps1")
    $materializedMcpDraft = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/emit-codedb-mcp-registration-draft.ps1")
    $materializedMcpValidator = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/validate-codedb-mcp-project-config.ps1")
    $providerInvocationLog = Join-Path $providerRoot "logs\fixture-index-invocations.txt"

    $unknownProviderResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $unknownProviderResult `
        -OverallState "UNKNOWN" `
        -ProviderState "UNKNOWN" `
        -AdapterState "OK" `
        -Label "Missing-provider freshness check"
    $adapterBeforeUnknownProviderRefresh = Get-FileSnapshot -Root $adapterRoot
    $providerInvocationsBeforeUnknownRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $unknownProviderRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $unknownProviderRefresh -ExitCode 0 -Label "Unknown-provider conditional refresh"
    foreach ($expected in @(
        "[OK] Refresh plan: provider=UNKNOWN, adapter=OK.",
        "[OK] Refreshing stale provider index.",
        "[OK] codedb conditional refresh completed and freshness check passed."
    )) {
        Assert-True -Condition ($unknownProviderRefresh.Text.Contains($expected)) -Message "Unknown-provider conditional refresh is missing '$expected'."
    }
    Assert-True -Condition (-not $unknownProviderRefresh.Text.Contains("Rebuilding stale Shader/HLSL adapter index")) -Message "Unknown-provider conditional refresh rebuilt the fresh adapter."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected ($providerInvocationsBeforeUnknownRefresh + 1) -Message "Unknown-provider conditional refresh did not invoke the provider exactly once."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterBeforeUnknownProviderRefresh -Message "Unknown-provider conditional refresh changed the fresh adapter."
    Write-Host "[OK] Provider UNKNOWN refreshed only the provider lane."

    $runtimeHealthProbe = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check RuntimeHealth
    }
    Assert-Result -Result $runtimeHealthProbe -ExitCode 0 -Label "Materialized provider runtime-health probe"
    Assert-True -Condition ($runtimeHealthProbe.Text.Contains("[OK] Runtime health smoke passed.")) -Message "Provider runtime-health probe did not report success."

    $csharpProbe = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check CSharpProbe
    }
    Assert-Result -Result $csharpProbe -ExitCode 0 -Label "Materialized C# provider probe"
    Assert-True `
        -Condition ($csharpProbe.Text.Contains("[OK] C# probe passed with CodedbMaterializerFreshnessProbe in Assets/MaterializerFreshnessProbe.cs.")) `
        -Message "C# provider probe did not verify the fixture source. Output:`n$($csharpProbe.Text)"

    $providerCustomHit = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check CustomProbe -Language CSharp -Query "CODEDB_MATERIALIZER_PROVIDER_PROBE"
    }
    Assert-Result -Result $providerCustomHit -ExitCode 0 -Label "Materialized provider custom hit"
    Assert-True -Condition ($providerCustomHit.Text.Contains("[OK] C# custom probe found 1 hit(s)")) -Message "Provider custom probe did not report its hit."
    Assert-True -Condition ($providerCustomHit.Text.Contains("[HIT] Assets/MaterializerFreshnessProbe.cs:2")) -Message "Provider custom probe did not report the fixture path."

    $providerCustomNoHit = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check CustomProbe -Language CSharp -Query "CODEDB_MATERIALIZER_PROVIDER_MISSING"
    }
    Assert-Result -Result $providerCustomNoHit -ExitCode 0 -Label "Materialized provider custom no-hit"
    Assert-True -Condition ($providerCustomNoHit.Text.Contains("[NO HIT] C# custom probe found no source match")) -Message "Provider custom no-hit did not report NO HIT."

    $adapterProbe = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check All -Query "CODEDB_MATERIALIZER_ADAPTER_PROBE"
    }
    Assert-Result -Result $adapterProbe -ExitCode 0 -Label "Materialized Shader adapter probe"
    foreach ($expected in @(
        "[OK] Shader adapter index ready:",
        "[OK] Shader adapter search found 1 hit(s)",
        "[OK] Shader adapter read Assets/MaterializerProbe.shader",
        "[OK] Shader adapter stale check passed"
    )) {
        Assert-True -Condition ($adapterProbe.Text.Contains($expected)) -Message "Shader adapter probe is missing '$expected'."
    }

    $adapterNoHit = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check Search -Query "CODEDB_MATERIALIZER_ADAPTER_MISSING"
    }
    Assert-Result -Result $adapterNoHit -ExitCode 0 -Label "Materialized Shader adapter no-hit"
    Assert-True -Condition ($adapterNoHit.Text.Contains("[NO HIT] Shader adapter search found no hit")) -Message "Shader adapter no-hit did not report NO HIT."
    Write-Host "[OK] Materialized provider and Shader adapter probes covered hit and no-hit behavior."

    $allFreshResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $allFreshResult `
        -OverallState "OK" `
        -ProviderState "OK" `
        -AdapterState "OK" `
        -Label "All-fresh check"
    $providerBeforeNoOp = Get-FileSnapshot -Root $providerIndexRoot
    $adapterBeforeNoOp = Get-FileSnapshot -Root $adapterRoot
    $providerInvocationsBeforeNoOp = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $noOpRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $noOpRefresh -ExitCode 0 -Label "All-fresh conditional refresh"
    Assert-True -Condition ($noOpRefresh.Text.Contains("[OK] Refresh plan: provider=OK, adapter=OK.")) -Message "All-fresh conditional refresh reported the wrong plan."
    Assert-True -Condition ($noOpRefresh.Text.Contains("[OK] codedb indexes are fresh. No refresh required.")) -Message "All-fresh conditional refresh did not report its no-op."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected $providerInvocationsBeforeNoOp -Message "All-fresh conditional refresh invoked the provider."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerIndexRoot) -Expected $providerBeforeNoOp -Message "All-fresh conditional refresh changed provider index data."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterBeforeNoOp -Message "All-fresh conditional refresh changed adapter data."
    Write-Host "[OK] Fresh provider and adapter state produced an exact no-op."

    Write-Utf8File -Path $providerManifestPath -Content "{`"schema_version`":1,`"fixture`":true,`"no_watch`":true,`"created_unix_ms`":946684800000}`n"
    $staleProviderResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $staleProviderResult `
        -OverallState "STALE" `
        -ProviderState "STALE" `
        -AdapterState "OK" `
        -Label "Stale-provider freshness check"
    $adapterBeforeStaleProviderRefresh = Get-FileSnapshot -Root $adapterRoot
    $providerInvocationsBeforeStaleRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $staleProviderRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $staleProviderRefresh -ExitCode 0 -Label "Stale-provider conditional refresh"
    Assert-True -Condition ($staleProviderRefresh.Text.Contains("[OK] Refresh plan: provider=STALE, adapter=OK.")) -Message "Stale-provider conditional refresh reported the wrong plan."
    Assert-True -Condition (-not $staleProviderRefresh.Text.Contains("Rebuilding stale Shader/HLSL adapter index")) -Message "Stale-provider conditional refresh rebuilt the fresh adapter."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected ($providerInvocationsBeforeStaleRefresh + 1) -Message "Stale-provider conditional refresh did not invoke the provider exactly once."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterBeforeStaleProviderRefresh -Message "Stale-provider conditional refresh changed the fresh adapter."
    Write-Host "[OK] Provider STALE refreshed only the provider lane."

    $addedShaderPath = Join-Path $hostRoot "Assets\MaterializerFreshnessProbe.shader"
    Write-Utf8File -Path $addedShaderPath -Content "Shader `"Hidden/Rice/MaterializerFreshnessProbe`" {`n    // CODEDB_MATERIALIZER_ADAPTER_FRESHNESS_PROBE`n}`n"
    $staleAdapterResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $staleAdapterResult `
        -OverallState "STALE" `
        -ProviderState "OK" `
        -AdapterState "STALE" `
        -Label "Stale-adapter freshness check"
    $adapterStaleProbe = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check Stale
    }
    Assert-Result -Result $adapterStaleProbe -ExitCode 1 -Label "Materialized stale Shader adapter probe"
    Assert-True -Condition ($adapterStaleProbe.Text.Contains("[FAIL] Shader adapter index is stale")) -Message "Stale Shader adapter probe did not report failure."
    $providerBeforeStaleAdapterRefresh = Get-FileSnapshot -Root $providerIndexRoot
    $providerInvocationsBeforeAdapterRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $staleAdapterRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $staleAdapterRefresh -ExitCode 0 -Label "Stale-adapter conditional refresh"
    Assert-True -Condition ($staleAdapterRefresh.Text.Contains("[OK] Refresh plan: provider=OK, adapter=STALE.")) -Message "Stale-adapter conditional refresh reported the wrong plan."
    Assert-True -Condition (-not $staleAdapterRefresh.Text.Contains("Refreshing stale provider index")) -Message "Stale-adapter conditional refresh invoked the fresh provider."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected $providerInvocationsBeforeAdapterRefresh -Message "Stale-adapter conditional refresh changed the provider invocation count."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerIndexRoot) -Expected $providerBeforeStaleAdapterRefresh -Message "Stale-adapter conditional refresh changed provider index data."
    $adapterFreshProbe = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check Stale
    }
    Assert-Result -Result $adapterFreshProbe -ExitCode 0 -Label "Materialized refreshed Shader adapter probe"
    Assert-True -Condition ($adapterFreshProbe.Text.Contains("[OK] Shader adapter stale check passed for 3 file(s).")) -Message "Refreshed Shader adapter probe did not return to OK."
    Write-Host "[OK] Adapter STALE rebuilt only the Shader/HLSL adapter lane."

    Remove-Item -LiteralPath $adapterManifestPath -Force
    $unknownAdapterResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $unknownAdapterResult `
        -OverallState "UNKNOWN" `
        -ProviderState "OK" `
        -AdapterState "UNKNOWN" `
        -Label "Unknown-adapter freshness check"
    $providerBeforeUnknownAdapterRefresh = Get-FileSnapshot -Root $providerIndexRoot
    $providerInvocationsBeforeUnknownAdapterRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $unknownAdapterRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $unknownAdapterRefresh -ExitCode 0 -Label "Unknown-adapter conditional refresh"
    Assert-True -Condition ($unknownAdapterRefresh.Text.Contains("[OK] Refresh plan: provider=OK, adapter=UNKNOWN.")) -Message "Unknown-adapter conditional refresh reported the wrong plan."
    Assert-True -Condition (-not $unknownAdapterRefresh.Text.Contains("Refreshing stale provider index")) -Message "Unknown-adapter conditional refresh invoked the fresh provider."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected $providerInvocationsBeforeUnknownAdapterRefresh -Message "Unknown-adapter conditional refresh changed the provider invocation count."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerIndexRoot) -Expected $providerBeforeUnknownAdapterRefresh -Message "Unknown-adapter conditional refresh changed provider index data."
    Assert-True -Condition (Test-Path -LiteralPath $adapterManifestPath -PathType Leaf) -Message "Unknown-adapter conditional refresh did not restore the adapter manifest."
    $finalFreshnessResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $finalFreshnessResult `
        -OverallState "OK" `
        -ProviderState "OK" `
        -AdapterState "OK" `
        -Label "Final freshness check"
    Write-Host "[OK] Adapter UNKNOWN rebuilt only the Shader/HLSL adapter lane and returned both owners to fresh."

    $beforeMcpGuidance = Get-FileSnapshot -Root $hostRoot
    $mcpDraftResult = Invoke-PowerShellAction -Action {
        & $materializedMcpDraft
    }
    Assert-Result -Result $mcpDraftResult -ExitCode 0 -Label "Materialized MCP registration draft"
    foreach ($expected in @(
        "codedb-fixture MCP registration draft",
        "Status: review draft only; no MCP client configuration was written.",
        "- Target file: .codex/config.toml",
        "[mcp_servers.codedb-fixture]",
        'command = "node"',
        'cwd = "."',
        'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
        '"registrationPolicy"',
        '"manual-review-only"'
    )) {
        Assert-True -Condition ($mcpDraftResult.Text.Contains($expected)) -Message "MCP registration draft is missing '$expected'."
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMcpGuidance -Message "MCP registration draft changed host files."

    $mcpValidationResult = Invoke-PowerShellAction -Action {
        & $materializedMcpValidator
    }
    Assert-Result -Result $mcpValidationResult -ExitCode 0 -Label "Materialized MCP project config validation"
    foreach ($expected in @(
        "OK: MCP working directory matches expected project-level value.",
        "OK: Project config uses the package-neutral wrapper MCP command shape.",
        "OK: Shader/HLSL text adapter manifest is present for wrapper routing.",
        "OK: .codex/config.toml uses relative paths only.",
        "[OK] Project-level MCP config validation passed."
    )) {
        Assert-True -Condition ($mcpValidationResult.Text.Contains($expected)) -Message "MCP project config validation is missing '$expected'."
    }

    $fixtureMcpConfigPath = Join-Path $hostRoot ".codex\config.toml"
    $validMcpConfig = Get-Content -LiteralPath $fixtureMcpConfigPath -Raw
    $validMcpConfigLastWriteTimeUtc = [System.IO.File]::GetLastWriteTimeUtc($fixtureMcpConfigPath)
    try {
        $missingCwdConfig = $validMcpConfig -replace '(?m)^\s*cwd\s*=\s*"\."\s*\r?\n', ''
        Write-Utf8File -Path $fixtureMcpConfigPath -Content $missingCwdConfig
        $missingCwdValidation = Invoke-PowerShellAction -Action {
            & $materializedMcpValidator
        }
        Assert-Result -Result $missingCwdValidation -ExitCode 1 -Label "Missing-cwd MCP project config validation"
        Assert-True `
            -Condition ($missingCwdValidation.Text.Contains("FAIL: MCP working directory must appear exactly once in the project MCP section.")) `
            -Message "MCP validator accepted a project registration without cwd."

        $wrongCwdConfig = $validMcpConfig.Replace('cwd = "."', 'cwd = ".."')
        Write-Utf8File -Path $fixtureMcpConfigPath -Content $wrongCwdConfig
        $wrongCwdValidation = Invoke-PowerShellAction -Action {
            & $materializedMcpValidator
        }
        Assert-Result -Result $wrongCwdValidation -ExitCode 1 -Label "Wrong-cwd MCP project config validation"
        Assert-True `
            -Condition ($wrongCwdValidation.Text.Contains('FAIL: MCP working directory differs from the required project-level value: cwd = "."')) `
            -Message "MCP validator accepted a project registration with the wrong cwd."

        Write-Utf8File -Path $fixtureMcpConfigPath -Content @"
# config sentinel
[mcp_servers.codedb-fixture]
command = "AIWork/.runtime/codedb/codedb-fixture/bin/codebase-mcp.exe"
cwd = "."
args = ["mcp", "--root", ".", "--config", "AIWork/.runtime/codedb/codedb-fixture/config/codedb-mcp.toml", "--no-watch"]
startup_timeout_sec = 120
"@
        $directProviderValidation = Invoke-PowerShellAction -Action {
            & $materializedMcpValidator
        }
        Assert-Result -Result $directProviderValidation -ExitCode 1 -Label "Direct-Provider MCP project config validation"
        Assert-True `
            -Condition ($directProviderValidation.Text.Contains("FAIL: Direct Provider registration is not accepted for formal project MCP configuration. Use the project wrapper.")) `
            -Message "MCP validator accepted the direct Provider transition shape."
    } finally {
        Write-Utf8File -Path $fixtureMcpConfigPath -Content $validMcpConfig
        [System.IO.File]::SetLastWriteTimeUtc($fixtureMcpConfigPath, $validMcpConfigLastWriteTimeUtc)
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMcpGuidance -Message "MCP project config validation changed host files."
    Write-Host "[OK] Materialized MCP draft enforced cwd and wrapper-only registration without mutating host configuration."

    $verify = Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $verify -ExitCode 0 -Label "Current Verify"
    $beforeIdempotent = Get-ManagedPayloadSnapshot -Root $hostRoot
    $syncAgain = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $syncAgain -ExitCode 0 -Label "Idempotent Sync"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeIdempotent -Message "Idempotent Sync changed managed state."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Verify and idempotent no-op passed."

    $beforeFailedRemove = Get-FileSnapshot -Root $hostRoot
    $failedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 1
    Assert-Result -Result $failedRemove -ExitCode 6 -Label "Injected Remove failure"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeFailedRemove -Message "Injected Remove failure did not restore the host file tree."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Post-rollback Verify"
    Assert-NoMaterializerResidue
    Write-Host "[OK] Mid-remove failure restored the owned files and marker."

    $beforeCrashedRemove = Get-FileSnapshot -Root $hostRoot
    $crashedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1
    Assert-Result -Result $crashedRemove -ExitCode 86 -Label "Injected Remove process crash"
    Assert-True -Condition ($crashedRemove.Text.Contains("Injected POC process crash after mutation 1.")) -Message "Injected Remove process crash did not report its mutation boundary."
    Assert-True -Condition (Test-Path -LiteralPath $materializerRuntimePath -PathType Container) -Message "Injected Remove process crash left no persistent recovery transaction."
    $recoveredRemove = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $recoveredRemove -ExitCode 0 -Label "Remove crash recovery"
    Assert-True -Condition ($recoveredRemove.Text.Contains("[RECOVERED] Rolled back interrupted remove transaction.")) -Message "Remove crash recovery did not report the interrupted Remove rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeCrashedRemove -Message "Persistent Remove recovery did not restore the exact installed fixture."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Post-crash-recovery Verify"
    Assert-NoMaterializerResidue
    Write-Host "[OK] A new process recovered the interrupted Remove from its persistent journal."

    $removeForAdoption = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $removeForAdoption -ExitCode 0 -Label "Pre-adoption Remove"
    Assert-True -Condition (-not (Test-Path -LiteralPath $lastKnownGoodPointerPath)) -Message "Remove retained last-known-good.json."
    Assert-True -Condition (-not (Test-Path -LiteralPath $failedUpgradeStatePath)) -Message "Remove retained upgrade-state.json."
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Join-Path $hostRoot "AIWork\.runtime\codedb\host"))) `
        -Message "Remove retained the empty host-generation runtime."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Remove transactionally cleaned the valid LKG pointer and automatic-upgrade diagnostics."
    Copy-CanonicalFilesToHost
    $adoptionTime = [datetime]::SpecifyKind([datetime]"2020-01-02T03:04:06", [DateTimeKind]::Utc)
    foreach ($relativePath in $managedTargets) {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        [System.IO.File]::SetLastWriteTimeUtc($target, $adoptionTime)
        Set-ItemProperty -LiteralPath $target -Name IsReadOnly -Value $true
    }
    $beforeAdoption = @{}
    foreach ($relativePath in $managedTargets) {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        $item = Get-Item -LiteralPath $target -Force
        $beforeAdoption[$relativePath] = [pscustomobject]@{
            Sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
            LastWriteTicks = $item.LastWriteTimeUtc.Ticks
            Attributes = [int]$item.Attributes
        }
    }
    $beforeRejectedAdoption = Get-FileSnapshot -Root $hostRoot
    $rejectedAdoption = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $rejectedAdoption -ExitCode 4 -Label "Unconfirmed exact-file adoption"
    Assert-True -Condition ($rejectedAdoption.Text.Contains("retry with -ConfirmLegacyMcpStopped")) -Message "Unconfirmed adoption did not report the legacy MCP boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeRejectedAdoption -Message "Unconfirmed adoption changed the fixture."

    $adopt = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -ConfirmLegacyMcpStopped
    Assert-Result -Result $adopt -ExitCode 0 -Label "Exact-file adoption"
    $adoptedMarker = Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adoptedMarker.host_use_gate_version -Expected 1 -Message "Adoption marker did not advertise the host-use gate."
    foreach ($relativePath in $managedTargets) {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        $after = Get-Item -LiteralPath $target -Force
        Assert-Equal -Actual (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -Expected $beforeAdoption[$relativePath].Sha256 -Message "Adoption rewrote file bytes: $relativePath."
        Assert-Equal -Actual $after.LastWriteTimeUtc.Ticks -Expected $beforeAdoption[$relativePath].LastWriteTicks -Message "Adoption rewrote file time: $relativePath."
        Assert-Equal -Actual ([int]$after.Attributes) -Expected $beforeAdoption[$relativePath].Attributes -Message "Adoption rewrote file attributes: $relativePath."
    }
    Write-Host "[OK] Exact-file adoption required legacy MCP confirmation and wrote only the ownership marker."

    foreach ($relativePath in $managedTargets) {
        Set-ItemProperty -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath) -Name IsReadOnly -Value $false
    }
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Post-adoption Remove"

    $atomicTargetRelativePath = "AIWork/codedb/codedbignore.example"
    $atomicOldContent = "atomic-reader-old`n" + [string]::new([char]65, 2 * 1024 * 1024)
    $atomicNewContent = "atomic-reader-new`n" + [string]::new([char]66, 2 * 1024 * 1024)
    $atomicV1Entries = [ordered]@{ $atomicTargetRelativePath = $atomicOldContent }
    $atomicV2Entries = [ordered]@{ $atomicTargetRelativePath = $atomicNewContent }
    $atomicV1Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "atomic-v1") -PayloadVersion "test.1" -Entries $atomicV1Entries
    $atomicV2Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "atomic-v2") -PayloadVersion "test.2" -Entries $atomicV2Entries
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $atomicV1Root) -ExitCode 0 -Label "Atomic reader v1 Sync"
    $atomicTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $atomicTargetRelativePath
    $atomicOldSha256 = (Get-FileHash -LiteralPath $atomicTargetPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $atomicNewSha256 = (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $atomicV2Root -RelativePath $atomicTargetRelativePath) -Algorithm SHA256).Hash.ToLowerInvariant()
    $atomicReadyPath = Join-Path $runRoot "atomic-reader.ready"
    $atomicSawNewPath = Join-Path $runRoot "atomic-reader.saw-new"
    $atomicStopPath = Join-Path $runRoot "atomic-reader.stop"
    $atomicReaderJob = Start-Job -ArgumentList $atomicTargetPath, $atomicOldSha256, $atomicNewSha256, $atomicReadyPath, $atomicSawNewPath, $atomicStopPath -ScriptBlock {
        param($TargetPath, $OldSha256, $NewSha256, $ReadyPath, $SawNewPath, $StopPath)

        $oldReads = 0
        $newReads = 0
        $sharingRetries = 0
        $deadline = [DateTime]::UtcNow.AddSeconds(20)
        while ([DateTime]::UtcNow -lt $deadline) {
            $stream = $null
            $sha256 = $null
            $hash = $null
            try {
                $share = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
                $stream = [System.IO.File]::Open($TargetPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, $share)
                $sha256 = [System.Security.Cryptography.SHA256]::Create()
                $hash = ([System.BitConverter]::ToString($sha256.ComputeHash($stream))).Replace("-", "").ToLowerInvariant()
            } catch {
                $ioException = $_.Exception
                while ($null -ne $ioException.InnerException) {
                    $ioException = $ioException.InnerException
                }
                $win32Code = $ioException.HResult -band 0xffff
                if ($ioException -is [System.IO.IOException] -and $win32Code -in @(32, 33)) {
                    $sharingRetries++
                    [System.Threading.Thread]::Sleep(1)
                    continue
                }
                throw
            } finally {
                if ($null -ne $sha256) { $sha256.Dispose() }
                if ($null -ne $stream) { $stream.Dispose() }
            }

            if ([string]::Equals($hash, $OldSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $oldReads++
                if (-not (Test-Path -LiteralPath $ReadyPath)) {
                    [System.IO.File]::WriteAllText($ReadyPath, "ready")
                }
            } elseif ([string]::Equals($hash, $NewSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $newReads++
                if (-not (Test-Path -LiteralPath $SawNewPath)) {
                    [System.IO.File]::WriteAllText($SawNewPath, "new")
                }
            } else {
                throw "Concurrent reader observed an unexpected or partial SHA256: $hash"
            }

            if ((Test-Path -LiteralPath $StopPath) -and $oldReads -gt 0 -and $newReads -gt 0) {
                return [pscustomobject]@{ OldReads = $oldReads; NewReads = $newReads; SharingRetries = $sharingRetries }
            }
            [System.Threading.Thread]::Sleep(1)
        }
        throw "Concurrent reader timed out before observing complete old and new files."
    }
    try {
        Assert-True -Condition (Wait-ForPathState -Path $atomicReadyPath -Present $true -TimeoutMilliseconds 10000) -Message "Concurrent reader did not observe the complete old file before Sync."
        $atomicUpgrade = Invoke-Materializer -Action "Sync" -PayloadRoot $atomicV2Root
        Assert-Result -Result $atomicUpgrade -ExitCode 0 -Label "Atomic reader v2 Sync"
        Assert-True -Condition (Wait-ForPathState -Path $atomicSawNewPath -Present $true -TimeoutMilliseconds 10000) -Message "Concurrent reader did not observe the complete new file after Sync."
        Write-Utf8File -Path $atomicStopPath -Content "stop`n"
        $null = Wait-Job -Job $atomicReaderJob -Timeout 10
        Assert-Equal -Actual $atomicReaderJob.State -Expected "Completed" -Message "Concurrent reader did not complete successfully."
        $atomicReaderResult = Receive-Job -Job $atomicReaderJob -ErrorAction Stop
        Assert-True -Condition ([int]$atomicReaderResult.OldReads -gt 0) -Message "Concurrent reader recorded no old-file observations."
        Assert-True -Condition ([int]$atomicReaderResult.NewReads -gt 0) -Message "Concurrent reader recorded no new-file observations."
    } finally {
        if (-not (Test-Path -LiteralPath $atomicStopPath)) {
            Write-Utf8File -Path $atomicStopPath -Content "stop`n"
        }
        if ($atomicReaderJob.State -in @("Running", "NotStarted")) {
            Stop-Job -Job $atomicReaderJob -ErrorAction SilentlyContinue
        }
        Remove-Job -Job $atomicReaderJob -Force -ErrorAction SilentlyContinue
    }
    Assert-Equal -Actual (Get-FileHash -LiteralPath $atomicTargetPath -Algorithm SHA256).Hash.ToLowerInvariant() -Expected $atomicNewSha256 -Message "Atomic upgrade did not publish the complete new file."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $atomicV2Root) -ExitCode 0 -Label "Atomic reader v2 Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $atomicV2Root) -ExitCode 0 -Label "Atomic reader v2 Remove"
    Assert-NoMaterializerResidue
    Write-Host "[OK] Concurrent readers observed only complete old or new bytes during same-file replacement."

    $v1Entries = [ordered]@{
        "AIWork/codedb/codedb-mcp.runtime.example.toml" = "obsolete-v1`n"
        "AIWork/codedb/scripts/codedb-project-common.ps1" = "common-v1`n"
        "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1" = "prepare-stable`n"
    }
    $v2Entries = [ordered]@{
        "AIWork/codedb/scripts/codedb-project-common.ps1" = "common-v2`n"
        "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1" = "prepare-stable`n"
        "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1" = "upgrade-only-v2`n"
    }
    $v1Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "v1") -PayloadVersion "test.1" -Entries $v1Entries
    $v2Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "v2") -PayloadVersion "test.2" -Entries $v2Entries
    $collisionEntries = [ordered]@{
        "AIWork/codedb/scripts/codedb-project-common.ps1" = "same-sequence-collision`n"
        "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1" = "prepare-stable`n"
        "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1" = "upgrade-only-v2`n"
    }
    $collisionRoot = New-SyntheticPayload -Root (Join-Path $syntheticRoot "sequence-collision") -PayloadVersion "test.2-collision" -Entries $collisionEntries
    $packageMetadataRoot = New-SyntheticPayload -Root (Join-Path $syntheticRoot "package-metadata") -PayloadVersion "test.2" -Entries $v2Entries
    $packageMetadataManifestPath = Join-Path $packageMetadataRoot "payload-manifest.json"
    $packageMetadataManifest = Get-Content -LiteralPath $packageMetadataManifestPath -Raw | ConvertFrom-Json
    $packageMetadataManifest.package_version = "0.1.1-test"
    Write-Utf8File -Path $packageMetadataManifestPath -Content (($packageMetadataManifest | ConvertTo-Json -Depth 8) + "`n")
    $v2ManifestPath = Join-Path $v2Root "payload-manifest.json"
    $v2Manifest = Get-Content -LiteralPath $v2ManifestPath -Raw | ConvertFrom-Json
    $v2Manifest.retired_targets = @("AIWork/codedb/codedb-mcp.runtime.example.toml")
    Write-Utf8File -Path $v2ManifestPath -Content (($v2Manifest | ConvertTo-Json -Depth 8) + "`n")
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v1Root) -ExitCode 0 -Label "Synthetic v1 Sync"
    $retiredTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml"
    Write-Utf8File -Path $retiredTarget -Content "retired file drift`n"
    $beforeRetiredConflict = Get-FileSnapshot -Root $hostRoot
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v2Root) -ExitCode 3 -Label "Retired-file drift conflict"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeRetiredConflict -Message "Retired-file conflict caused a partial upgrade."
    Copy-Item -LiteralPath (Get-PathFromRelative -Root $v1Root -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml") -Destination $retiredTarget -Force
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v2Root) -ExitCode 0 -Label "Synthetic v2 upgrade"
    Assert-Equal -Actual (Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/codedb-project-common.ps1") -Raw) -Expected "common-v2`n" -Message "Upgrade did not replace the changed file."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml"))) -Message "Upgrade did not retire the removed payload file."
    Assert-True -Condition (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1") -PathType Leaf) -Message "Upgrade did not install the new payload file."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $v2Root) -ExitCode 0 -Label "Synthetic v2 Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $packageMetadataRoot) -ExitCode 0 -Label "Same-payload package metadata Sync"
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $packageMetadataRoot) -ExitCode 0 -Label "Same-payload package metadata Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v2Root) -ExitCode 0 -Label "Same-payload package metadata restore"
    $beforeDowngrade = Get-FileSnapshot -Root $hostRoot
    $collisionDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $collisionRoot
    Assert-Result -Result $collisionDryRun -ExitCode 0 -Label "Synthetic sequence-collision DryRun"
    Assert-True -Condition ($collisionDryRun.Text.Contains("[CONFLICT] SequenceCollision:")) -Message "Sequence-collision DryRun did not identify the reused sequence."
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $collisionRoot) -ExitCode 3 -Label "Synthetic sequence-collision Sync rejection"
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $collisionRoot) -ExitCode 3 -Label "Synthetic sequence-collision Remove rejection"
    $downgradeSync = Invoke-Materializer -Action "Sync" -PayloadRoot $v1Root
    Assert-Result -Result $downgradeSync -ExitCode 3 -Label "Synthetic downgrade Sync rejection"
    Assert-True -Condition ($downgradeSync.Text.Contains("[CONFLICT] Downgrade:")) -Message "Downgrade Sync did not report the installed/requested sequence boundary."
    $downgradeRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $v1Root
    Assert-Result -Result $downgradeRemove -ExitCode 3 -Label "Synthetic downgrade Remove rejection"
    Assert-True -Condition ($downgradeRemove.Text.Contains("[CONFLICT] Downgrade:")) -Message "Downgrade Remove did not report the installed/requested sequence boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeDowngrade -Message "Downgrade rejection changed host files."
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $v2Root) -ExitCode 0 -Label "Synthetic v2 Remove"
    Write-Host "[OK] Synthetic upgrade, package-only metadata update, retired drift refusal, sequence-collision refusal, and Sync/Remove downgrade refusal passed."

    $conflictTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1"
    Write-Utf8File -Path $conflictTarget -Content "foreign unowned content`n"
    $beforeUnownedConflict = Get-FileSnapshot -Root $hostRoot
    $unownedConflict = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unownedConflict -ExitCode 3 -Label "Unowned-file conflict"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeUnownedConflict -Message "Unowned conflict caused partial writes."
    Remove-Item -LiteralPath $conflictTarget -Force
    Assert-NoMaterializerResidue
    Write-Host "[OK] Unowned-file conflict rejected the entire Sync."

    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Managed drift setup"
    $driftTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1"
    Write-Utf8File -Path $driftTarget -Content "managed drift`n"
    $canonicalV2Entries = [ordered]@{}
    foreach ($relativePath in $managedTargets) {
        $canonicalV2Entries[$relativePath] = [System.IO.File]::ReadAllText((Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath))
    }
    $canonicalV2Entries["AIWork/codedb/scripts/codedb-project-common.ps1"] = "package upgrade that must not partially apply`n"
    $conflictingUpgradeRoot = New-SyntheticPayload `
        -Root (Join-Path $syntheticRoot "conflicting-upgrade") `
        -PayloadVersion "poc.27-test-upgrade" `
        -PayloadSequence 28 `
        -PackageVersion "0.2.5-test" `
        -Entries $canonicalV2Entries
    $beforeManagedConflict = Get-FileSnapshot -Root $hostRoot
    $managedConflict = Invoke-Materializer -Action "Sync" -PayloadRoot $conflictingUpgradeRoot
    Assert-Result -Result $managedConflict -ExitCode 3 -Label "Managed-file drift conflict"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeManagedConflict -Message "Managed drift conflict caused a partial upgrade."
    $removeConflict = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $removeConflict -ExitCode 3 -Label "Drifted Remove"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeManagedConflict -Message "Drifted Remove deleted or rewrote files."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Managed drift blocked both upgrade and Remove without partial writes."

    Copy-Item -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1") -Destination $driftTarget -Force
    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    $originalMarkerText = Get-Content -LiteralPath $markerPath -Raw
    $tamperedMarker = $originalMarkerText | ConvertFrom-Json
    $tamperedMarker.files += [pscustomobject]@{
        path = "AIWork/codedb/adoption-decision.md"
        installed_sha256 = (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/adoption-decision.md") -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Write-Utf8File -Path $markerPath -Content (($tamperedMarker | ConvertTo-Json -Depth 8) + "`n")
    $beforeTamperedRemove = Get-FileSnapshot -Root $hostRoot
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 2 -Label "Tampered marker Remove"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeTamperedRemove -Message "Tampered marker caused host file changes."
    Write-Utf8File -Path $markerPath -Content $originalMarkerText
    Write-Host "[OK] Marker cannot extend ownership to a host-only document."

    $exactRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $exactRemove -ExitCode 0 -Label "Exact-owner Remove"
    Assert-CanonicalFilesRemoved
    Assert-SentinelsUnchanged -ExpectedSnapshot $sentinelSnapshot
    Assert-NoMaterializerResidue
    Write-Host "[OK] Exact-owner Remove preserved every unrelated sentinel."

    $eolRelativePath = "AIWork/codedb/scripts/codedb-project-common.ps1"
    $eolPayloadPath = Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $eolRelativePath
    $eolTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $eolRelativePath
    $lfPayloadText = [System.IO.File]::ReadAllText($eolPayloadPath)
    Assert-True -Condition (-not $lfPayloadText.Contains("`r`n")) -Message "Canonical payload EOL fixture is not LF-only."
    $crlfHostText = $lfPayloadText.Replace("`n", "`r`n")
    Write-Utf8File -Path $eolTargetPath -Content $crlfHostText
    Assert-True `
        -Condition (-not [string]::Equals((Get-FileHash -LiteralPath $eolTargetPath -Algorithm SHA256).Hash, (Get-FileHash -LiteralPath $eolPayloadPath -Algorithm SHA256).Hash, [StringComparison]::OrdinalIgnoreCase)) `
        -Message "CRLF host fixture unexpectedly matched the LF payload hash."
    $beforeEolConflict = Get-FileSnapshot -Root $hostRoot
    $eolDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $eolDryRun -ExitCode 0 -Label "CRLF host DryRun"
    Assert-True -Condition ($eolDryRun.Text.Contains("[CONFLICT] Conflict: $eolRelativePath")) -Message "CRLF host DryRun did not report an exact-byte conflict."
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 3 -Label "CRLF host Sync refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeEolConflict -Message "CRLF conflict changed the fixture."
    Remove-Item -LiteralPath $eolTargetPath -Force
    Assert-NoMaterializerResidue
    Write-Host "[OK] CRLF host content was not normalized or adopted against the LF payload hash."

    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Git staged-change setup Sync"
    $null = Invoke-FixtureIndexGit -Arguments @("read-tree", "--empty")

    $stagedRelativePath = "AIWork/codedb/scripts/codedb-project-common.ps1"
    $stagedTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $stagedRelativePath
    $stagedGitPath = Get-ProjectGitPath -Path $stagedTargetPath
    Write-Utf8File -Path $stagedTargetPath -Content "staged managed variant`n"
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $stagedGitPath)
    Copy-Item -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $stagedRelativePath) -Destination $stagedTargetPath -Force
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $stagedTargetPath -Algorithm SHA256).Hash `
        -Expected (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $stagedRelativePath) -Algorithm SHA256).Hash `
        -Message "Managed staged-change fixture did not restore exact working-tree bytes."
    $beforeStagedManagedGate = Get-FileSnapshot -Root $hostRoot
    $stagedDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $stagedDryRun -ExitCode 0 -Label "Managed staged-change DryRun"
    Assert-True -Condition ($stagedDryRun.Text.Contains("[CONFLICT] GitStaged: $stagedRelativePath")) -Message "DryRun did not report the staged managed target."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 3 -Label "Managed staged-change Verify refusal"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 3 -Label "Managed staged-change Sync refusal"
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 3 -Label "Managed staged-change Remove refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeStagedManagedGate -Message "Managed staged-change refusal changed host files."
    Assert-NoMaterializerResidue
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $stagedGitPath)

    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    $markerGitPath = Get-ProjectGitPath -Path $markerPath
    $exactMarkerText = Get-Content -LiteralPath $markerPath -Raw
    Write-Utf8File -Path $markerPath -Content ($exactMarkerText + "`n")
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $markerGitPath)
    Write-Utf8File -Path $markerPath -Content $exactMarkerText
    $stagedMarkerVerify = Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $stagedMarkerVerify -ExitCode 3 -Label "Staged ownership-marker Verify refusal"
    Assert-True -Condition ($stagedMarkerVerify.Text.Contains("[CONFLICT] GitStaged: $markerRelativePath")) -Message "Verify did not report the staged ownership marker."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $markerGitPath)

    $unrelatedTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath "Assets/BusinessSentinel.txt"
    $unrelatedGitPath = Get-ProjectGitPath -Path $unrelatedTargetPath
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $unrelatedGitPath)
    $unrelatedDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $unrelatedDryRun -ExitCode 0 -Label "Unrelated staged-change DryRun"
    Assert-True -Condition (-not $unrelatedDryRun.Text.Contains("[CONFLICT] GitStaged:")) -Message "An unrelated staged business file blocked the managed payload scope."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 0 -Label "Unrelated staged-change Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 0 -Label "Unrelated staged-change no-op Sync"
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $unrelatedGitPath)
    Write-Host "[OK] Managed files and the ownership marker reject staged index state while unrelated staged files remain out of scope."

    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 0 -Label "Staged recovery setup Remove"
    $crashedStagedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1 -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $crashedStagedInstall -ExitCode 86 -Label "Staged recovery install crash"
    $stagedRecoveryTransactions = @(Get-ChildItem -LiteralPath $materializerRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $stagedRecoveryTransactions.Count -Expected 1 -Message "Staged recovery crash did not retain exactly one transaction."
    $stagedRecoveryJournalPath = Join-Path $stagedRecoveryTransactions[0].FullName "transaction.json"
    $stagedRecoveryJournal = Get-Content -LiteralPath $stagedRecoveryJournalPath -Raw | ConvertFrom-Json
    $stagedRecoveryEntries = @($stagedRecoveryJournal.entries)
    Assert-True -Condition ($stagedRecoveryEntries.Count -gt 0) -Message "Staged recovery journal contains no mutation targets."
    $recoveryRelativePath = [string]$stagedRecoveryEntries[0].target
    $recoveryTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $recoveryRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $recoveryTargetPath -PathType Leaf) -Message "First crashed Sync mutation did not publish its journal target."
    $recoveryGitPath = Get-ProjectGitPath -Path $recoveryTargetPath
    $recoveryTargetText = Get-Content -LiteralPath $recoveryTargetPath -Raw
    Write-Utf8File -Path $recoveryTargetPath -Content "staged recovery variant`n"
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $recoveryGitPath)
    Write-Utf8File -Path $recoveryTargetPath -Content $recoveryTargetText
    $recoveryTargetHash = (Get-FileHash -LiteralPath $recoveryTargetPath -Algorithm SHA256).Hash
    $blockedStagedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $blockedStagedRecovery -ExitCode 3 -Label "Staged interrupted-transaction recovery refusal"
    Assert-True -Condition ($blockedStagedRecovery.Text.Contains("[CONFLICT] GitStaged: $recoveryRelativePath")) -Message "Interrupted recovery did not report its staged target."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $recoveryTargetPath -Algorithm SHA256).Hash -Expected $recoveryTargetHash -Message "Blocked staged recovery changed the target bytes."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $recoveryGitPath)
    $completedStagedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $completedStagedRecovery -ExitCode 0 -Label "Unstaged interrupted-transaction recovery"
    Assert-True -Condition ($completedStagedRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Unstaged retry did not recover the interrupted transaction."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Interrupted transaction recovery also refuses staged managed targets until the index is cleared."

    $escapeRoot = Join-Path $syntheticRoot "escape"
    New-Item -ItemType Directory -Force -Path $escapeRoot | Out-Null
    Write-Utf8File -Path (Join-Path $escapeRoot "safe.ps1") -Content "safe`n"
    $escapeManifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = "0.1.0-test"
        payload_version = "escape-test"
        payload_sequence = 1
        generation_id = $generationId
        bootstrap_protocol = 1
        current_pointer_target = $currentPointerRelativePath
        retired_targets = @()
        files = @([ordered]@{
            source = "safe.ps1"
            target = "../escaped.ps1"
            sha256 = (Get-FileHash -LiteralPath (Join-Path $escapeRoot "safe.ps1") -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }
    Write-Utf8File -Path (Join-Path $escapeRoot "payload-manifest.json") -Content (($escapeManifest | ConvertTo-Json -Depth 8) + "`n")
    $escapeResult = Invoke-Materializer -Action "Sync" -PayloadRoot $escapeRoot
    Assert-Result -Result $escapeResult -ExitCode 2 -Label "Path escape rejection"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $hostRoot "escaped.ps1"))) -Message "Unsafe manifest escaped the managed target root."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Unsafe manifest paths are rejected before writes."

    Assert-SentinelsUnchanged -ExpectedSnapshot $sentinelSnapshot
    Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "POC modified package source files."
    Write-Host "[OK] CodeDB host payload materializer POC passed all scenarios."
    $fixturePassed = $true
} finally {
    if ($null -ne $activeMcpProcess) {
        try {
            if (-not $activeMcpProcess.HasExited) {
                $activeMcpProcess.Kill()
                $activeMcpProcess.WaitForExit()
            }
            $activeMcpProcess.Dispose()
        } catch {
            Write-Warning "Fixture MCP cleanup failed: $($_.Exception.Message)"
        }
        $activeMcpProcess = $null
    }
    if ($activeWatchManagerPath -or $activeWatchLifecycleId) {
        try {
            if ($activeWatchManagerPath -and (Test-Path -LiteralPath $activeWatchManagerPath -PathType Leaf)) {
                $cleanupResult = Invoke-PowerShellAction -Action {
                    if ($activeWatchLifecycleId) {
                        & $activeWatchManagerPath -Action Stop -ExpectedLifecycleId $activeWatchLifecycleId
                    } else {
                        & $activeWatchManagerPath -Action Stop
                    }
                }
                if ($cleanupResult.ExitCode -ne 0) {
                    Write-Warning "Fixture watcher cleanup through the manager failed: $($cleanupResult.Text)"
                }
            }
            $cleanupCoordinator = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "coordinator/codedb-watch-coordinator.mjs")
            $cleanupRuntime = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\watch\coordinator"
            $cleanupState = Join-Path $cleanupRuntime "coordinator-state.json"
            if ((Test-Path -LiteralPath $cleanupCoordinator -PathType Leaf) -and (Test-Path -LiteralPath $cleanupState -PathType Leaf)) {
                $global:LASTEXITCODE = 0
                $cleanupArguments = @($cleanupCoordinator, "stop", "--runtime", $cleanupRuntime)
                if ($activeWatchLifecycleId) {
                    $cleanupArguments += @("--expected-lifecycle-id", $activeWatchLifecycleId)
                }
                $cleanupOutput = @(& $nodePath @cleanupArguments 2>&1)
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Fixture watcher cleanup through the coordinator failed: $($cleanupOutput -join [Environment]::NewLine)"
                }
            }
        } catch {
            Write-Warning "Fixture watcher cleanup failed: $($_.Exception.Message)"
        }
    }
    if ($null -ne $junctionPath -and (Test-Path -LiteralPath $junctionPath)) {
        $junctionItem = Get-Item -LiteralPath $junctionPath -Force
        if (($junctionItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusing to clean an unexpected non-junction path: $junctionPath"
        }
        [System.IO.Directory]::Delete($junctionPath)
        $junctionPath = $null
    }
    if ($null -ne $readEscapeJunctionPath -and (Test-Path -LiteralPath $readEscapeJunctionPath)) {
        $readEscapeItem = Get-Item -LiteralPath $readEscapeJunctionPath -Force
        if (($readEscapeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusing to clean an unexpected non-junction path: $readEscapeJunctionPath"
        }
        [System.IO.Directory]::Delete($readEscapeJunctionPath)
        $readEscapeJunctionPath = $null
    }
    $preserveFailedFixture = -not $fixturePassed -and [string]::Equals($env:CODEDB_PRESERVE_FAILED_FIXTURE, "1", [StringComparison]::Ordinal)
    if ($preserveFailedFixture) {
        Write-Warning "Preserved POC fixture root: $runRoot"
    } elseif (Test-Path -LiteralPath $runRoot) {
        $fullRunRoot = [System.IO.Path]::GetFullPath($runRoot)
        $fullPocRoot = [System.IO.Path]::GetFullPath($pocRoot).TrimEnd('\', '/')
        if ($fullRunRoot.StartsWith($fullPocRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and
            -not [string]::Equals($fullRunRoot, $fullPocRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Assert-NoReparseAncestors -Path $fullRunRoot -Root $projectRoot
            Assert-NoReparseTree -Root $fullRunRoot
            Get-ChildItem -LiteralPath $fullRunRoot -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
                $_.IsReadOnly = $false
            }
            Remove-Item -LiteralPath $fullRunRoot -Recurse -Force
        } else {
            throw "Refusing to clean an unsafe POC path: $fullRunRoot"
        }
    }
    if (-not $preserveFailedFixture -and
        (Test-Path -LiteralPath $pocRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $pocRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $pocRoot -Force
    }
}

if (-not $preserveFailedFixture) {
    Assert-True -Condition (-not (Test-Path -LiteralPath $runRoot)) -Message "POC fixture cleanup failed: $runRoot"
}
