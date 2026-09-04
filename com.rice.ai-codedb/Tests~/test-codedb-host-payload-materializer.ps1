#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$RepairOnly,

    [switch]$McpAvailabilityOnly,

    [switch]$UninstallOnly,

    [switch]$McpConfigOnly,

    [switch]$PrerequisiteOnly,

    [switch]$UpgradeOnly,

    [switch]$PayloadContractOnly,

    [switch]$ActivationContractOnly,

    [switch]$ActivationTransactionOnly,

    [switch]$PortabilityOnly,

    [switch]$TransactionOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (@($RepairOnly, $McpAvailabilityOnly, $UninstallOnly, $McpConfigOnly, $PrerequisiteOnly, $UpgradeOnly, $PayloadContractOnly, $ActivationContractOnly, $ActivationTransactionOnly, $PortabilityOnly, $TransactionOnly | Where-Object { $_ }).Count -gt 1) {
    throw "RepairOnly, McpAvailabilityOnly, UninstallOnly, McpConfigOnly, PrerequisiteOnly, UpgradeOnly, PayloadContractOnly, ActivationContractOnly, ActivationTransactionOnly, PortabilityOnly, and TransactionOnly are mutually exclusive."
}

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
$repairHostRoot = Join-Path $runRoot "repair-fixture"
$uninstallHostRoot = Join-Path $runRoot "uninstall-fixture"
$portabilityHostRoot = Join-Path $runRoot "portability-fixture"
$syntheticRoot = Join-Path $runRoot "payloads"
$reviewedLegacyCacheRoot = Join-Path $runRoot "reviewed-legacy-payloads"
$fixtureGitIndexPath = Join-Path $runRoot "fixture-git-index"
$fixtureGitObjectRoot = Join-Path $runRoot "fixture-git-objects"
$productionProjectRoot = Join-Path $runRoot "production-project"
$powershellPath = (Get-Process -Id $PID).Path
$nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$markerRelativePath = "AIWork/codedb/.rice-ai-codedb-payload.json"
$generationId = "poc.34"
$generationTargetPrefix = "AIWork/.runtime/codedb/host/generations/$generationId/"
$currentPointerRelativePath = "AIWork/.runtime/codedb/host/current.json"
$lastKnownGoodPointerRelativePath = "AIWork/.runtime/codedb/host/last-known-good.json"
$fixtureMarkerName = ".rice-ai-codedb-poc-fixture.json"
$junctionPath = $null
$readEscapeJunctionPath = $null
$activeWatchManagerPath = $null
$activeWatchLifecycleId = $null
$activeMcpProcess = $null
$fixtureRuntimeRoot = $null
$fixtureRuntimeRelativePath = $null
$fixturePreviousUnityRoot = $env:RICE_CODEDB_UNITY_ROOT
$fixturePreviousInstanceRoot = $env:RICE_CODEDB_INSTANCE_ROOT
$fixtureInstanceEnvironmentSet = $false
$fixturePassed = $false
$originalLocalAppData = $env:LOCALAPPDATA
$fixtureLocalAppData = Join-Path $runRoot "machine-local-app-data"
$canonicalPayloadManifestPath = Join-Path $canonicalPayloadRoot "payload-manifest.json"
$canonicalPayloadManifest = Get-Content -LiteralPath $canonicalPayloadManifestPath -Raw | ConvertFrom-Json

function Get-TestPayloadContentIdentitySha256 {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$CurrentPointerTarget,
        [Parameter(Mandatory = $true)][string]$GenerationTargetPrefix
    )

    $generationManifestTarget = $GenerationTargetPrefix + "generation-manifest.json"
    $identityLines = New-Object System.Collections.Generic.List[string]
    $identityLines.Add("managed_by=$($Manifest.managed_by)")
    $identityLines.Add("payload_version=$($Manifest.payload_version)")
    $identityLines.Add("payload_sequence=$($Manifest.payload_sequence)")
    $identityLines.Add("generation_id=$($Manifest.generation_id)")
    $identityLines.Add("bootstrap_protocol=$($Manifest.bootstrap_protocol)")
    foreach ($target in @($Manifest.retired_targets | Sort-Object)) {
        $identityLines.Add("retired=$target")
    }
    foreach ($transition in @($Manifest.bootstrap_transitions | Sort-Object source_payload_sequence, source_package_version)) {
        $identityLines.Add(
            "bootstrap_transition=$($transition.source_marker_schema_version):$($transition.source_package_version):$($transition.source_payload_version):$($transition.source_payload_sequence):$($transition.source_generation_id):$($transition.source_bootstrap_protocol):$($transition.source_host_use_gate_version):$($transition.source_generation_lease_version):$($transition.source_flat_file_count):$($transition.source_flat_closure_sha256):$($transition.source_stable_wrapper_sha256)")
    }
    foreach ($file in @($Manifest.files | Sort-Object target)) {
        if ([string]::Equals([string]$file.target, $CurrentPointerTarget, [StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals([string]$file.target, $generationManifestTarget, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $identityLines.Add("file=$($file.target):$($file.sha256)")
    }

    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try {
        $identityBytes = [System.Text.Encoding]::UTF8.GetBytes(($identityLines -join "`n") + "`n")
        return (($hasher.ComputeHash($identityBytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
        $hasher.Dispose()
    }
}

$canonicalPayloadContentSha256 = Get-TestPayloadContentIdentitySha256 `
    -Manifest $canonicalPayloadManifest `
    -CurrentPointerTarget $currentPointerRelativePath `
    -GenerationTargetPrefix $generationTargetPrefix
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
$productionSentinelPaths = @($sentinelPaths | Where-Object { $_ -ne $fixtureMarkerName })

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

function Assert-ThrowsMessage {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$ExpectedMessage,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $actualMessage = $null
    try {
        & $Action
    } catch {
        $actualMessage = $_.Exception.Message
    }
    Assert-True -Condition ($null -ne $actualMessage) -Message "$Label did not fail closed."
    Assert-True `
        -Condition ($actualMessage.IndexOf($ExpectedMessage, [StringComparison]::OrdinalIgnoreCase) -ge 0) `
        -Message "$Label returned an unexpected error: $actualMessage"
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
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [string]$Root = $hostRoot
    )

    $leaseRoot = Join-Path $Root "AIWork\.runtime\codedb\payload-materializer\host-use-leases"
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
        [string]$Root = $hostRoot,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if ((@(Get-HostUseLeasePaths -Owner $Owner -ProcessId $ProcessId -Root $Root).Count -gt 0) -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (@(Get-HostUseLeasePaths -Owner $Owner -ProcessId $ProcessId -Root $Root).Count -gt 0) -eq $Present
}

function Get-GenerationLeasePaths {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [string]$LeaseGenerationId = $generationId,
        [string]$Root = $hostRoot
    )

    $leaseRoot = Join-Path $Root "AIWork\.runtime\codedb\host\leases\$LeaseGenerationId"
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
        [string]$Root = $hostRoot,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        $exists = @(Get-GenerationLeasePaths -Owner $Owner -ProcessId $ProcessId -LeaseGenerationId $LeaseGenerationId -Root $Root).Count -gt 0
        if ($exists -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (@(Get-GenerationLeasePaths -Owner $Owner -ProcessId $ProcessId -LeaseGenerationId $LeaseGenerationId -Root $Root).Count -gt 0) -eq $Present
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
        [DateTime]$HeartbeatUtc = [DateTime]::UtcNow,
        [string]$Root = $hostRoot
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
    $leasePath = Join-Path $Root "AIWork\.runtime\codedb\host\leases\$LeaseGenerationId\$leaseId.json"
    $lease = [ordered]@{
        schema_version = 2
        generation_lease_version = 2
        managed_by = "com.rice.ai-codedb"
        generation_id = $LeaseGenerationId
        lease_id = $leaseId
        owner = $Owner
        pid = $ProcessId
        process_start_identity = $ProcessStartIdentity
        project_root = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
        created_at_utc = $HeartbeatUtc.AddSeconds(-1).ToString("o")
        heartbeat_at_utc = $HeartbeatUtc.ToString("o")
    }
    Write-Utf8File -Path $leasePath -Content (($lease | ConvertTo-Json -Depth 5) + "`n")
    return $leasePath
}

function New-TestLegacyHostUseLease {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][DateTimeOffset]$CreatedAtUtc,
        [string]$Root = $hostRoot
    )

    $leaseId = "$Owner-$ProcessId-$([guid]::NewGuid().ToString('N'))"
    $leasePath = Join-Path $Root "AIWork\.runtime\codedb\payload-materializer\host-use-leases\$leaseId.json"
    $lease = [ordered]@{
        schema_version = 1
        host_use_gate_version = 1
        managed_by = "com.rice.ai-codedb"
        lease_id = $leaseId
        owner = $Owner
        pid = $ProcessId
        project_root = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
        created_at_utc = $CreatedAtUtc.ToUniversalTime().ToString("o")
    }
    Write-Utf8File -Path $leasePath -Content (($lease | ConvertTo-Json -Depth 5) + "`n")
    return $leasePath
}

function Start-LegacyHostUseLeaseProcess {
    param(
        [Parameter(Mandatory = $true)][string]$GatePath,
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [string]$Root = $hostRoot
    )

    $holderPath = Join-Path $runRoot ("legacy-$Owner-lease-holder-$([guid]::NewGuid().ToString('N')).mjs")
    $gateUriJson = ([System.Uri]::new($GatePath)).AbsoluteUri | ConvertTo-Json -Compress
    $rootJson = [System.IO.Path]::GetFullPath($Root) | ConvertTo-Json -Compress
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
    $startInfo.WorkingDirectory = $Root
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
    if (-not (Wait-ForHostUseLease -Owner $Owner -ProcessId $process.Id -Present $true -Root $Root)) {
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
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [string]$Root = $hostRoot
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
    Assert-True -Condition (Wait-ForHostUseLease -Owner $Owner -ProcessId $processId -Present $false -Root $Root) -Message "Legacy $Owner lease did not drain after its owner exited."
}

function Start-GenerationHostUseLeaseProcess {
    param(
        [Parameter(Mandatory = $true)][string]$GatePath,
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [string]$LeaseGenerationId = $generationId,
        [switch]$SuppressHeartbeat,
        [string]$Root = $hostRoot
    )

    $holderPath = Join-Path $runRoot ("generation-$Owner-lease-holder-$([guid]::NewGuid().ToString('N')).mjs")
    $gateUriJson = ([System.Uri]::new($GatePath)).AbsoluteUri | ConvertTo-Json -Compress
    $rootJson = [System.IO.Path]::GetFullPath($Root) | ConvertTo-Json -Compress
    $ownerJson = $Owner | ConvertTo-Json -Compress
    $generationJson = $LeaseGenerationId | ConvertTo-Json -Compress
    $suppressHeartbeatJson = [bool]$SuppressHeartbeat | ConvertTo-Json -Compress
    Write-Utf8File -Path $holderPath -Content @"
const { acquireCodedbHostUseLease } = await import($gateUriJson);
const nativeSetInterval = globalThis.setInterval;
if ($suppressHeartbeatJson) {
  globalThis.setInterval = (callback) => nativeSetInterval(callback, 60 * 60 * 1000);
}
const lease = acquireCodedbHostUseLease($rootJson, $ownerJson, $generationJson);
globalThis.setInterval = nativeSetInterval;
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
nativeSetInterval(() => {}, 1000);
"@

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$holderPath`""
    $startInfo.WorkingDirectory = $Root
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
        throw "Generation $Owner lease holder failed to start. $errorText"
    }
    if (-not (Wait-ForGenerationLease -Owner $Owner -ProcessId $process.Id -Present $true -LeaseGenerationId $LeaseGenerationId -Root $Root)) {
        $process.Kill()
        $process.WaitForExit()
        $process.Dispose()
        throw "Generation $Owner lease holder did not publish its lease."
    }
    return $process
}

function Stop-GenerationHostUseLeaseProcess {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [string]$LeaseGenerationId = $generationId,
        [string]$Root = $hostRoot
    )

    $processId = $Process.Id
    if (-not $Process.HasExited) {
        $Process.StandardInput.Close()
        if (-not $Process.WaitForExit(10000)) {
            $Process.Kill()
            $Process.WaitForExit()
            throw "Generation $Owner lease holder did not exit after stdin closed."
        }
    }
    $stderr = $Process.StandardError.ReadToEnd().Trim()
    Assert-Equal -Actual $Process.ExitCode -Expected 0 -Message "Generation $Owner lease holder exit code mismatch."
    Assert-True -Condition ([string]::IsNullOrWhiteSpace($stderr)) -Message "Generation $Owner lease holder reported stderr: $stderr"
    $Process.Dispose()
    Assert-True `
        -Condition (Wait-ForGenerationLease -Owner $Owner -ProcessId $processId -Present $false -LeaseGenerationId $LeaseGenerationId -Root $Root) `
        -Message "Generation $Owner lease did not drain after its owner exited."
}

function Start-IdleOwnerProcess {
    param([Parameter(Mandatory = $true)][string]$Root)

    $holderPath = Join-Path $runRoot ("idle-owner-$([guid]::NewGuid().ToString('N')).mjs")
    Write-Utf8File -Path $holderPath -Content @"
process.stdout.write("READY\n");
let closing = false;
function close() {
  if (closing) return;
  closing = true;
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
    $startInfo.WorkingDirectory = $Root
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
        throw "Idle owner process failed to start. $errorText"
    }
    return $process
}

function Stop-IdleOwnerProcess {
    param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process)

    if (-not $Process.HasExited) {
        $Process.StandardInput.Close()
        if (-not $Process.WaitForExit(10000)) {
            $Process.Kill()
            $Process.WaitForExit()
            throw "Idle owner process did not exit after stdin closed."
        }
    }
    $stderr = $Process.StandardError.ReadToEnd().Trim()
    Assert-Equal -Actual $Process.ExitCode -Expected 0 -Message "Idle owner process exit code mismatch."
    Assert-True -Condition ([string]::IsNullOrWhiteSpace($stderr)) -Message "Idle owner process reported stderr: $stderr"
    $Process.Dispose()
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

function Start-TestEditorLeaseHeartbeat {
    param([Parameter(Mandatory = $true)][string]$LeasePath)

    $scriptPath = Join-Path $runRoot ("editor-lease-heartbeat-" + [guid]::NewGuid().ToString("N") + ".ps1")
    $stopPath = $scriptPath + ".stop"
    Write-Utf8File -Path $scriptPath -Content @'
param(
    [Parameter(Mandatory = $true)][string]$LeasePath,
    [Parameter(Mandatory = $true)][string]$StopPath,
    [Parameter(Mandatory = $true)][string]$SuccessPath,
    [Parameter(Mandatory = $true)][int]$ParentProcessId
)
$ErrorActionPreference = "Stop"
$encoding = [System.Text.UTF8Encoding]::new($false)
while (-not (Test-Path -LiteralPath $StopPath)) {
    if ($null -eq (Get-Process -Id $ParentProcessId -ErrorAction SilentlyContinue)) { break }
    if (-not (Test-Path -LiteralPath $LeasePath -PathType Leaf)) {
        Start-Sleep -Milliseconds 250
        continue
    }
    try {
        $lease = Get-Content -LiteralPath $LeasePath -Raw | ConvertFrom-Json
        $lease.heartbeat_at_utc = [DateTime]::UtcNow.ToString("o")
        $json = ($lease | ConvertTo-Json -Depth 5) + "`n"
        $temporaryPath = $LeasePath + "." + $PID + ".tmp"
        $backupPath = $LeasePath + "." + $PID + ".bak"
        [System.IO.File]::WriteAllText($temporaryPath, $json, $encoding)
        [System.IO.File]::Replace($temporaryPath, $LeasePath, $backupPath)
        Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        [System.IO.File]::WriteAllText($SuccessPath, $lease.heartbeat_at_utc, $encoding)
    } catch {
        Remove-Item -LiteralPath ($LeasePath + "." + $PID + ".tmp") -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath ($LeasePath + "." + $PID + ".bak") -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 5
}
'@
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $successPath = $scriptPath + ".success"
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -LeasePath `"$LeasePath`" -StopPath `"$stopPath`" -SuccessPath `"$successPath`" -ParentProcessId $PID"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    return [pscustomobject]@{
        Process = $process
        ScriptPath = $scriptPath
        StopPath = $stopPath
        SuccessPath = $successPath
    }
}

function Stop-TestEditorLeaseHeartbeat {
    param([AllowNull()]$Heartbeat)

    if ($null -eq $Heartbeat) { return }
    Write-Utf8File -Path $Heartbeat.StopPath -Content "stop`n"
    if (-not $Heartbeat.Process.WaitForExit(15000)) {
        $Heartbeat.Process.Kill()
        $Heartbeat.Process.WaitForExit()
        throw "Editor lease heartbeat fixture did not stop on request."
    }
    $stderr = $Heartbeat.Process.StandardError.ReadToEnd().Trim()
    Assert-Equal -Actual $Heartbeat.Process.ExitCode -Expected 0 -Message "Editor lease heartbeat fixture exit code mismatch."
    Assert-True -Condition ([string]::IsNullOrWhiteSpace($stderr)) -Message "Editor lease heartbeat fixture reported stderr: $stderr"
    $Heartbeat.Process.Dispose()
    Remove-Item -LiteralPath $Heartbeat.ScriptPath, $Heartbeat.StopPath, $Heartbeat.SuccessPath -Force -ErrorAction SilentlyContinue
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
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [string]$Root = $hostRoot
    )

    Push-Location -LiteralPath $Root
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
    Write-Utf8File -Path (Join-Path $providerConfigRoot "codedb-mcp.watch.toml") -Content "[watch]`nenabled = true`n"
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
    $templatePath = Join-Path $runRoot "fixture-provider-template.exe"
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
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $templatePath -OutputType ConsoleApplication -ErrorAction Stop | Out-Null
    }
    if (-not [string]::Equals([System.IO.Path]::GetFullPath($templatePath), [System.IO.Path]::GetFullPath($Path), [StringComparison]::OrdinalIgnoreCase)) {
        Copy-Item -LiteralPath $templatePath -Destination $Path -Force
    }
    Assert-True -Condition (Test-Path -LiteralPath $Path -PathType Leaf) -Message "Fixture provider executable was not generated: $Path"
}

function New-FixtureMachineProvider {
    param([Parameter(Mandatory = $true)][string]$LocalAppDataRoot)

    $providerRoot = Join-Path $LocalAppDataRoot "Rice\CodeDB\providers\0.5.0-28e3912"
    $providerExecutable = Join-Path $providerRoot "codebase-mcp.exe"
    $providerManifest = Join-Path $providerRoot "provider-manifest.json"
    New-FixtureProviderExecutable -Path $providerExecutable
    $document = [ordered]@{
        schema_version = 1
        provider_id = "killop/codedb-mcp"
        version = "0.5.0-28e3912"
        commit = "28e3912d5cd67ff3499734984f3e3d626a204796"
        executable = "codebase-mcp.exe"
        sha256 = (Get-FileHash -LiteralPath $providerExecutable -Algorithm SHA256).Hash.ToLowerInvariant()
        protocol = "codedb-cli-v1"
        source = "https://github.com/killop/codedb-mcp"
        supported_package_min_inclusive = "0.2.5-preview.5"
        supported_package_max_exclusive = "0.2.6"
    }
    Write-Utf8File -Path $providerManifest -Content (($document | ConvertTo-Json -Depth 4) + "`n")
    return [pscustomobject]@{
        Root = $providerRoot
        ExecutablePath = $providerExecutable
        ManifestPath = $providerManifest
    }
}

function ConvertTo-TestProjectSlug {
    param([Parameter(Mandatory = $true)][string]$Value)

    $normalizedValue = $Value.Normalize([Text.NormalizationForm]::FormC)
    $builder = [System.Text.StringBuilder]::new()
    $previousWasSeparator = $false
    $containsNonAscii = $false
    foreach ($character in $normalizedValue.ToCharArray()) {
        if ([int]$character -gt 0x7f) {
            $containsNonAscii = $true
        }
        if (($character -ge 'A' -and $character -le 'Z') -or
            ($character -ge 'a' -and $character -le 'z') -or
            ($character -ge '0' -and $character -le '9')) {
            $null = $builder.Append([char]::ToLowerInvariant($character))
            $previousWasSeparator = $false
        } elseif (-not $previousWasSeparator -and $builder.Length -gt 0) {
            $null = $builder.Append('-')
            $previousWasSeparator = $true
        }
    }
    while ($builder.Length -gt 0 -and $builder[$builder.Length - 1] -eq '-') {
        $builder.Length--
    }
    $result = if ($builder.Length -eq 0) { "unity-project" } else { $builder.ToString() }
    $requiresHash = $containsNonAscii
    if ($result.Length -gt 96) {
        $result = $result.Substring(0, 96).TrimEnd('-')
        $requiresHash = $true
    }
    if ($requiresHash) {
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalizedValue))
            $hash = (($hashBytes | ForEach-Object { $_.ToString("x2") }) -join "")
            $result = "$result-$($hash.Substring(0, 12))"
        } finally {
            $sha256.Dispose()
        }
    }
    return $result
}

function Start-OwnedLegacyWatcherFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$LifecycleId = "legacy-redeploy-fixture"
    )

    $projectSlug = ConvertTo-TestProjectSlug -Value (Split-Path -Leaf $Root.TrimEnd('\', '/'))
    $providerRoot = Join-Path $Root "AIWork\.runtime\codedb\codedb-$projectSlug"
    $providerExecutable = Join-Path $providerRoot "bin\codebase-mcp.exe"
    $providerConfig = Join-Path $providerRoot "config\codedb-mcp.toml"
    $adapterManifest = Join-Path $providerRoot "adapter\text-index\manifest.json"
    $watchRoot = Join-Path $providerRoot "watch"
    $editorLeaseRoot = Join-Path $watchRoot "lifecycle\editor-leases"
    $coordinatorRuntime = Join-Path $watchRoot "coordinator"
    $coordinatorStatePath = Join-Path $coordinatorRuntime "coordinator-state.json"
    $managerPath = Get-PathFromRelative -Root $Root -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1"
    $coordinatorPath = Get-PathFromRelative -Root $Root -RelativePath "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs"
    $runtimeTemplatePath = Get-PathFromRelative -Root $Root -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml"

    New-FixtureProviderExecutable -Path $providerExecutable
    $runtimeConfig = (Get-Content -LiteralPath $runtimeTemplatePath -Raw).Replace('__CODEDB_PROVIDER_SLUG__', "codedb-$projectSlug")
    Write-Utf8File -Path $providerConfig -Content $runtimeConfig
    $adapterManifestDocument = [ordered]@{
        schemaVersion = 1
        generatedAtUtc = [DateTime]::UtcNow.ToString("o")
        roots = @("Assets", "Packages")
        extensions = @(".cs", ".shader", ".hlsl", ".cginc")
        files = @()
    }
    Write-Utf8File -Path $adapterManifest -Content (($adapterManifestDocument | ConvertTo-Json -Depth 5) + "`n")
    $editorLeasePath = New-TestEditorLease `
        -LeaseRoot $editorLeaseRoot `
        -Root $Root `
        -SessionId "$LifecycleId-editor"

    $startResult = Invoke-PowerShellAction -Root $Root -Action {
        & $managerPath `
            -Action Start `
            -LifecycleId $LifecycleId `
            -RequireNewOwner `
            -ExclusiveOwner
    }
    if ($startResult.ExitCode -ne 0) {
        Remove-Item -LiteralPath $editorLeasePath -Force -ErrorAction SilentlyContinue
    }
    Assert-Result -Result $startResult -ExitCode 0 -Label "Owned legacy watcher fixture Start"
    Assert-True -Condition (Wait-ForWatchReady -StatePath $coordinatorStatePath) -Message "Owned legacy watcher fixture did not reach Ready."
    $state = Get-Content -LiteralPath $coordinatorStatePath -Raw | ConvertFrom-Json
    $coordinatorProcessId = [int]$state.coordinator_pid
    Assert-True `
        -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $coordinatorProcessId -Present $true -Root $Root) `
        -Message "Owned legacy watcher fixture did not publish its flat Host-use lease."
    return [pscustomobject]@{
        Root = $Root
        LifecycleId = $LifecycleId
        ProviderRoot = $providerRoot
        ManagerPath = $managerPath
        CoordinatorPath = $coordinatorPath
        Runtime = $coordinatorRuntime
        StatePath = $coordinatorStatePath
        EditorLeasePath = $editorLeasePath
        ProcessId = $coordinatorProcessId
        PipeName = [string]$state.pipe_name
        AuthToken = [string]$state.auth_token
    }
}

function Stop-OwnedLegacyWatcherFixture {
    param([Parameter(Mandatory = $true)]$Fixture)

    if (Test-Path -LiteralPath $Fixture.StatePath -PathType Leaf) {
        $state = Get-Content -LiteralPath $Fixture.StatePath -Raw | ConvertFrom-Json
        $sameOwner = [int]$state.coordinator_pid -eq [int]$Fixture.ProcessId -and
            [string]::Equals([string]$state.lifecycle_id, [string]$Fixture.LifecycleId, [StringComparison]::Ordinal)
        if ($sameOwner) {
            $global:LASTEXITCODE = 0
            $output = @(& $nodePath `
                $Fixture.CoordinatorPath `
                "stop" `
                "--runtime" $Fixture.Runtime `
                "--expected-lifecycle-id" $Fixture.LifecycleId 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "Owned legacy watcher fixture Stop failed.`n$($output -join [Environment]::NewLine)"
            }
        }
    }
    Assert-True `
        -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $Fixture.ProcessId -Present $false -Root $Fixture.Root -TimeoutMilliseconds 15000) `
        -Message "Owned legacy watcher fixture retained its Host-use lease after Stop."
}

function Start-ForgedLegacyWatcherCommandFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$LifecycleId = "legacy-forged-command-fixture"
    )

    # Build the complete reviewed legacy runtime through its real manager first,
    # then relaunch the same daemon through an unowned shim. The resulting pipe,
    # state, Provider, adapter, and lease are authentic; only the OS argv closure
    # is deliberately outside the reviewed Package-owned command identity.
    $prepared = Start-OwnedLegacyWatcherFixture -Root $Root -LifecycleId "$LifecycleId-prepare"
    Stop-OwnedLegacyWatcherFixture -Fixture $prepared

    $providerExecutable = Join-Path $prepared.ProviderRoot "bin\codebase-mcp.exe"
    $providerConfig = Join-Path $prepared.ProviderRoot "config\codedb-mcp.watch.toml"
    $adapterBuilder = Get-PathFromRelative -Root $Root -RelativePath "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1"
    $adapterWorker = Get-PathFromRelative -Root $Root -RelativePath "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1"
    $adapterManifest = Join-Path $prepared.ProviderRoot "adapter\text-index\manifest.json"
    $daemonArguments = @(
        "daemon",
        "--root", [System.IO.Path]::GetFullPath($Root),
        "--provider", [System.IO.Path]::GetFullPath($providerExecutable),
        "--config", [System.IO.Path]::GetFullPath($providerConfig),
        "--runtime", [System.IO.Path]::GetFullPath($prepared.Runtime),
        "--lifecycle-id", $LifecycleId,
        "--require-new", "true",
        "--exclusive-lifecycle", "true",
        "--startup-timeout-ms", "120000",
        "--adapter-builder", [System.IO.Path]::GetFullPath($adapterBuilder),
        "--adapter-manifest", [System.IO.Path]::GetFullPath($adapterManifest),
        "--adapter-debounce-ms", "750",
        "--adapter-worker", [System.IO.Path]::GetFullPath($adapterWorker)
    )
    $forgedArgv = @($nodePath, [System.IO.Path]::GetFullPath($prepared.CoordinatorPath)) + $daemonArguments
    $forgedArgvJson = ConvertTo-Json -InputObject $forgedArgv -Compress
    $coordinatorUriJson = ([System.Uri]::new($prepared.CoordinatorPath)).AbsoluteUri | ConvertTo-Json -Compress
    $shimPath = Join-Path $runRoot ("forged-legacy-coordinator-command-" + [guid]::NewGuid().ToString("N") + ".mjs")
    Write-Utf8File -Path $shimPath -Content @"
process.argv = $forgedArgvJson;
await import($coordinatorUriJson);
"@

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$shimPath`""
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    try {
        if (-not (Wait-ForWatchReady -StatePath $prepared.StatePath)) {
            $errorPath = Join-Path $prepared.Runtime "coordinator-error.json"
            $diagnostic = if (Test-Path -LiteralPath $errorPath -PathType Leaf) {
                Get-Content -LiteralPath $errorPath -Raw
            } else {
                "No coordinator error document was published."
            }
            throw "Forged-command legacy watcher fixture did not reach Ready. $diagnostic"
        }
        if (-not (Wait-ForHostUseLease -Owner "watcher" -ProcessId $process.Id -Present $true -Root $Root)) {
            throw "Forged-command legacy watcher fixture did not publish its live watcher lease."
        }
        $state = Get-Content -LiteralPath $prepared.StatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual ([int]$state.coordinator_pid) -Expected $process.Id -Message "Forged-command coordinator state PID mismatch."
        return [pscustomobject]@{
            Root = $Root
            LifecycleId = $LifecycleId
            ProviderRoot = $prepared.ProviderRoot
            CoordinatorPath = $prepared.CoordinatorPath
            Runtime = $prepared.Runtime
            StatePath = $prepared.StatePath
            EditorLeasePath = $prepared.EditorLeasePath
            ProcessId = $process.Id
            Process = $process
            ShimPath = $shimPath
            PipeName = [string]$state.pipe_name
            AuthToken = [string]$state.auth_token
        }
    } catch {
        if (-not $process.HasExited) {
            try {
                if (Test-Path -LiteralPath $prepared.StatePath -PathType Leaf) {
                    Stop-OwnedLegacyWatcherFixture -Fixture ([pscustomobject]@{
                        Root = $Root
                        LifecycleId = $LifecycleId
                        CoordinatorPath = $prepared.CoordinatorPath
                        Runtime = $prepared.Runtime
                        StatePath = $prepared.StatePath
                        ProcessId = $process.Id
                    })
                }
            } catch {
                # Fall through to exact-process cleanup while preserving the startup error.
            }
            if (-not $process.HasExited) {
                $process.Kill()
                $process.WaitForExit()
            }
        }
        $process.Dispose()
        throw
    }
}

function Stop-ForgedLegacyWatcherCommandFixture {
    param([Parameter(Mandatory = $true)]$Fixture)

    try {
        Stop-OwnedLegacyWatcherFixture -Fixture $Fixture
        if (-not $Fixture.Process.WaitForExit(10000)) {
            $Fixture.Process.Kill()
            $Fixture.Process.WaitForExit()
            throw "Forged-command legacy watcher process did not exit after authenticated fixture cleanup."
        }
    } finally {
        $Fixture.Process.Dispose()
        if (Test-Path -LiteralPath $Fixture.EditorLeasePath -PathType Leaf) {
            Remove-Item -LiteralPath $Fixture.EditorLeasePath -Force
        }
    }
}

function Write-LegacyCoordinatorStateFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [hashtable]$Overrides = @{}
    )

    $projectSlug = ConvertTo-TestProjectSlug -Value (Split-Path -Leaf $Root.TrimEnd('\', '/'))
    $runtime = Join-Path $Root "AIWork\.runtime\codedb\codedb-$projectSlug\watch\coordinator"
    $statePath = Join-Path $runtime "coordinator-state.json"
    $state = [ordered]@{
        schema_version = 2
        coordinator_pid = $ProcessId
        lifecycle_id = "legacy-state-fixture"
        exclusive_lifecycle = $false
        root = [System.IO.Path]::GetFullPath($Root)
        runtime = [System.IO.Path]::GetFullPath($runtime)
        pipe_name = "\\.\pipe\codedb-watch-mismatch-fixture"
        auth_token = "a" * 48
    }
    foreach ($key in $Overrides.Keys) {
        $state[$key] = $Overrides[$key]
    }
    Write-Utf8File -Path $statePath -Content (($state | ConvertTo-Json -Depth 6) + "`n")
    return [pscustomobject]@{ StatePath = $statePath; Runtime = $runtime }
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

function Get-FileSnapshotExcept {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$ExcludedRelativePaths
    )

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return "[]"
    }

    $excluded = @{}
    foreach ($relativePath in $ExcludedRelativePaths) {
        $excluded[$relativePath.Replace('\', '/')] = $true
    }
    $rows = @(
        Get-ChildItem -LiteralPath $Root -Recurse -Force -File |
            Sort-Object FullName |
            Where-Object {
                -not $excluded.ContainsKey((Get-RelativeFilePath -Root $Root -Path $_.FullName))
            } |
            ForEach-Object {
                [ordered]@{
                    path = Get-RelativeFilePath -Root $Root -Path $_.FullName
                    sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                    length = $_.Length
                    last_write_ticks = $_.LastWriteTimeUtc.Ticks
                    attributes = [int]$_.Attributes
                }
            }
    )
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

function Invoke-Materializer {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [AllowNull()][string]$PayloadRoot,
        [int]$TestFailAfterMutation = 0,
        [int]$TestCrashAfterMutation = 0,
        [switch]$TestFailWatcherHandoff,
        [switch]$TestCrashBeforeWatcherHandoff,
        [switch]$TestFailRepairMcpRegistration,
        [switch]$TestCrashAfterRemovalMarkerDeletion,
        [switch]$TestFailInstanceCandidate,
        [switch]$ConfirmedProjectMutation,
        [switch]$OmitPocFixture,
        [switch]$UseDefaultPayloadRoot,
        [int]$TestProcessIdentityUnavailableForPid = 0,
        [string]$MaterializerScriptPath = $materializerPath,
        [string]$PathOverride,
        [switch]$BoundedOutputDrain,
        [string]$TargetProjectRoot = $hostRoot
    )

    if (-not $UseDefaultPayloadRoot -and [string]::IsNullOrWhiteSpace($PayloadRoot)) {
        throw "Invoke-Materializer requires PayloadRoot unless UseDefaultPayloadRoot is selected."
    }
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $confirmationArgument = if ($ConfirmedProjectMutation) { " -ConfirmedProjectMutation" } else { "" }
    $watcherHandoffFaultArgument = if ($TestFailWatcherHandoff) { " -TestFailWatcherHandoff" } else { "" }
    $preHandoffCrashArgument = if ($TestCrashBeforeWatcherHandoff) { " -TestCrashBeforeWatcherHandoff" } else { "" }
    $repairMcpFaultArgument = if ($TestFailRepairMcpRegistration) { " -TestFailRepairMcpRegistration" } else { "" }
    $postMarkerRemoveCrashArgument = if ($TestCrashAfterRemovalMarkerDeletion) { " -TestCrashAfterRemovalMarkerDeletion" } else { "" }
    $instanceCandidateFaultArgument = if ($TestFailInstanceCandidate) { " -TestFailInstanceCandidate" } else { "" }
    $fixtureArgument = if ($OmitPocFixture) { "" } else { " -PocFixture" }
    $payloadArgument = if ($UseDefaultPayloadRoot) { "" } else { " -PayloadRoot `"$PayloadRoot`"" }
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$MaterializerScriptPath`" -Action $Action -ProjectRoot `"$TargetProjectRoot`"$payloadArgument$fixtureArgument$confirmationArgument -TestFailAfterMutation $TestFailAfterMutation -TestCrashAfterMutation $TestCrashAfterMutation -TestProcessIdentityUnavailableForPid $TestProcessIdentityUnavailableForPid$watcherHandoffFaultArgument$preHandoffCrashArgument$repairMcpFaultArgument$postMarkerRemoveCrashArgument$instanceCandidateFaultArgument"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if (-not [string]::IsNullOrWhiteSpace($PathOverride)) {
        $startInfo.EnvironmentVariables["PATH"] = $PathOverride
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if ($BoundedOutputDrain) {
        $stdoutLines = New-Object System.Collections.Generic.List[string]
        $stderrLines = New-Object System.Collections.Generic.List[string]
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadLineAsync()
        $stderrTask = $process.StandardError.ReadLineAsync()
        $stdoutClosed = $false
        $stderrClosed = $false
        $drainDeadline = $null
        while ($true) {
            if (-not $stdoutClosed -and $stdoutTask.IsCompleted) {
                $line = $stdoutTask.Result
                if ($null -eq $line) {
                    $stdoutClosed = $true
                } else {
                    $stdoutLines.Add($line)
                    $stdoutTask = $process.StandardOutput.ReadLineAsync()
                }
            }
            if (-not $stderrClosed -and $stderrTask.IsCompleted) {
                $line = $stderrTask.Result
                if ($null -eq $line) {
                    $stderrClosed = $true
                } else {
                    $stderrLines.Add($line)
                    $stderrTask = $process.StandardError.ReadLineAsync()
                }
            }
            if ($process.HasExited) {
                if ($stdoutClosed -and $stderrClosed) { break }
                if ($null -eq $drainDeadline) {
                    $drainDeadline = [DateTime]::UtcNow.AddSeconds(1)
                } elseif ([DateTime]::UtcNow -ge $drainDeadline) {
                    break
                }
            }
            Start-Sleep -Milliseconds 10
        }
        $stdout = ($stdoutLines.ToArray() -join [Environment]::NewLine).TrimEnd("`r", "`n")
        $stderr = ($stderrLines.ToArray() -join [Environment]::NewLine).TrimEnd("`r", "`n")
    } else {
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $stdout = $stdoutTask.Result.TrimEnd("`r", "`n")
        $stderr = $stderrTask.Result.TrimEnd("`r", "`n")
    }
    $exitCode = $process.ExitCode
    $process.Dispose()
    $rawOutput = @($stdout, $stderr | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($rawOutput | ForEach-Object { $_.ToString() })
        Text = ($rawOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    }
}

function Start-RemoveLockHandshakeInvocation {
    param(
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][string]$TargetProjectRoot,
        [Parameter(Mandatory = $true)][string]$ReadyEventName,
        [Parameter(Mandatory = $true)][string]$ContinueEventName
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action Remove -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`" -PocFixture -TestRemoveLockAcquiredEventName $ReadyEventName -TestRemoveContinueEventName $ContinueEventName"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    return [pscustomobject]@{
        Process = $process
        StdoutTask = $process.StandardOutput.ReadToEndAsync()
        StderrTask = $process.StandardError.ReadToEndAsync()
    }
}

function Start-RepairMarkerHandshakeInvocation {
    param(
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][string]$TargetProjectRoot,
        [Parameter(Mandatory = $true)][string]$ReadyEventName,
        [Parameter(Mandatory = $true)][string]$ContinueEventName
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action Repair -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`" -PocFixture -TestRepairMarkerPublishedEventName $ReadyEventName -TestRepairContinueEventName $ContinueEventName"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    return [pscustomobject]@{
        Process = $process
        StdoutTask = $process.StandardOutput.ReadToEndAsync()
        StderrTask = $process.StandardError.ReadToEndAsync()
    }
}

function Start-UninstallMcpHandshakeInvocation {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("Uninstall", "Upgrade")][string]$Action,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][string]$TargetProjectRoot,
        [Parameter(Mandatory = $true)][string]$ReadyEventName,
        [Parameter(Mandatory = $true)][string]$ContinueEventName
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action $Action -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`" -PocFixture -TestUninstallMcpPublishedEventName $ReadyEventName -TestUninstallContinueEventName $ContinueEventName"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    return [pscustomobject]@{
        Process = $process
        StdoutTask = $process.StandardOutput.ReadToEndAsync()
        StderrTask = $process.StandardError.ReadToEndAsync()
    }
}

function Start-InstallRepairHandshakeInvocation {
    param(
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][string]$TargetProjectRoot,
        [Parameter(Mandatory = $true)][string]$ReadyEventName,
        [Parameter(Mandatory = $true)][string]$ContinueEventName
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action Install -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`" -PocFixture -TestInstallRepairCompletedEventName $ReadyEventName -TestInstallContinueEventName $ContinueEventName"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    return [pscustomobject]@{
        Process = $process
        StdoutTask = $process.StandardOutput.ReadToEndAsync()
        StderrTask = $process.StandardError.ReadToEndAsync()
    }
}

function Start-AsyncMaterializerInvocation {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][string]$TargetProjectRoot,
        [AllowNull()][string]$AutomaticCleanupStateCapturedEventName
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $cleanupSignalArgument = if ([string]::IsNullOrWhiteSpace($AutomaticCleanupStateCapturedEventName)) {
        ""
    } else {
        " -TestAutomaticCleanupStateCapturedEventName $AutomaticCleanupStateCapturedEventName"
    }
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action $Action -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`" -PocFixture$cleanupSignalArgument"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    return [pscustomobject]@{
        Process = $process
        StdoutTask = $process.StandardOutput.ReadToEndAsync()
        StderrTask = $process.StandardError.ReadToEndAsync()
    }
}

function New-PendingGenerationRollbackFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$TargetRelativePath
    )

    $runtimeRoot = Join-Path $Root "AIWork\.runtime\codedb\payload-materializer"
    $transactionId = "txn-v1-" + [guid]::NewGuid().ToString("N").Substring(0, 12)
    $transactionRoot = Join-Path $runtimeRoot $transactionId
    $backupRoot = Join-Path $transactionRoot "backup"
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    $targetPath = Get-PathFromRelative -Root $Root -RelativePath $TargetRelativePath
    $backupPath = Join-Path $backupRoot "0000.bak"
    Copy-Item -LiteralPath $targetPath -Destination $backupPath -Force
    $backupSha256 = (Get-FileHash -LiteralPath $backupPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $document = [ordered]@{
        schema_version = 2
        managed_by = "com.rice.ai-codedb"
        transaction_id = $transactionId
        state = "prepared"
        operation = "sync"
        automatic_upgrade = $false
        package_version = [string]$canonicalPayloadManifest.package_version
        payload_version = [string]$canonicalPayloadManifest.payload_version
        payload_sequence = [int]$canonicalPayloadManifest.payload_sequence
        payload_content_sha256 = $canonicalPayloadContentSha256
        generation_id = $generationId
        bootstrap_protocol = 1
        generation_manifest_sha256 = (Get-FileHash -LiteralPath (Join-Path $canonicalPayloadRoot "Generations\$GenerationId\generation-manifest.json") -Algorithm SHA256).Hash.ToLowerInvariant()
        previous_watcher_manager = $null
        previous_watcher_manager_sha256 = $null
        entries = @([ordered]@{
            target = $TargetRelativePath
            mutation = "write"
            desired_sha256 = $backupSha256
            existed_before = $true
            backup = "backup/0000.bak"
            backup_sha256 = $backupSha256
        })
    }
    Write-Utf8File -Path (Join-Path $transactionRoot "transaction.json") -Content (($document | ConvertTo-Json -Depth 8) + "`n")
    return $transactionRoot
}

function Complete-MaterializerInvocation {
    param(
        [Parameter(Mandatory = $true)]$Invocation,
        [int]$TimeoutMilliseconds = 15000
    )

    try {
        if (-not $Invocation.Process.WaitForExit($TimeoutMilliseconds)) {
            $Invocation.Process.Kill()
            $Invocation.Process.WaitForExit()
            throw "Asynchronous materializer invocation timed out: $($Invocation.Process.StartInfo.Arguments)"
        }
        $stdout = $Invocation.StdoutTask.Result.TrimEnd("`r", "`n")
        $stderr = $Invocation.StderrTask.Result.TrimEnd("`r", "`n")
        $rawOutput = @($stdout, $stderr | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        return [pscustomobject]@{
            ExitCode = $Invocation.Process.ExitCode
            Output = @($rawOutput | ForEach-Object { $_.ToString() })
            Text = ($rawOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        }
    } finally {
        $Invocation.Process.Dispose()
    }
}

function Invoke-FixtureIndexGit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $previousIndex = [Environment]::GetEnvironmentVariable("GIT_INDEX_FILE", [EnvironmentVariableTarget]::Process)
    $previousObjectRoot = [Environment]::GetEnvironmentVariable("GIT_OBJECT_DIRECTORY", [EnvironmentVariableTarget]::Process)
    try {
        New-Item -ItemType Directory -Force -Path $fixtureGitObjectRoot | Out-Null
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $fixtureGitIndexPath, [EnvironmentVariableTarget]::Process)
        [Environment]::SetEnvironmentVariable("GIT_OBJECT_DIRECTORY", $fixtureGitObjectRoot, [EnvironmentVariableTarget]::Process)
        $output = @(& git -c core.autocrlf=false -C $projectRoot @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Fixture Git index command failed: git $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
        }
        return $output
    } finally {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $previousIndex, [EnvironmentVariableTarget]::Process)
        [Environment]::SetEnvironmentVariable("GIT_OBJECT_DIRECTORY", $previousObjectRoot, [EnvironmentVariableTarget]::Process)
    }
}

function Export-ReviewedGitBlob {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $gitCommand = @(Get-Command git -CommandType Application -All -ErrorAction Stop | Where-Object {
        [System.IO.File]::Exists([string]$_.Source)
    } | Select-Object -First 1)
    if ($gitCommand.Count -ne 1) {
        throw "A concrete Git executable is required only to export the reviewed legacy test fixture."
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$gitCommand[0].Source
    $startInfo.Arguments = "show `"${Tag}:$RepositoryPath`""
    $startInfo.WorkingDirectory = $projectRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $stream = $null
    try {
        $null = $process.Start()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $stream = [System.IO.FileStream]::new($Destination, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $process.StandardOutput.BaseStream.CopyTo($stream)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null
        $process.WaitForExit()
        $stderr = $stderrTask.Result
        if ($process.ExitCode -ne 0) {
            throw "Git could not export reviewed blob ${Tag}:$RepositoryPath. $stderr"
        }
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
        $process.Dispose()
        if ((Test-Path -LiteralPath $Destination -PathType Leaf) -and
            (Get-Item -LiteralPath $Destination -Force).Length -eq 0) {
            Remove-Item -LiteralPath $Destination -Force
        }
    }
}

function Get-ReviewedLegacyPayloadFixtureRoot {
    param([Parameter(Mandatory = $true)][ValidateSet("v0.1.0", "v0.2.0", "v0.2.1")][string]$Tag)

    $cacheRoot = Join-Path $reviewedLegacyCacheRoot $Tag
    $completePath = Join-Path $cacheRoot ".complete"
    if (Test-Path -LiteralPath $completePath -PathType Leaf) {
        return $cacheRoot
    }
    if (Test-Path -LiteralPath $cacheRoot) {
        Remove-Item -LiteralPath $cacheRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

    $manifestRepositoryPath = "com.rice.ai-codedb/Payload~/payload-manifest.json"
    $manifestPath = Join-Path $cacheRoot "payload-manifest.json"
    Export-ReviewedGitBlob -Tag $Tag -RepositoryPath $manifestRepositoryPath -Destination $manifestPath
    $manifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.UTF8Encoding]::new($false, $true)) | ConvertFrom-Json
    Assert-True -Condition ([int]$manifest.schema_version -eq 1) -Message "$Tag fixture manifest schema is invalid."
    Assert-Equal -Actual ([string]$manifest.managed_by) -Expected "com.rice.ai-codedb" -Message "$Tag fixture manifest owner is invalid."
    Assert-Equal -Actual @($manifest.files).Count -Expected 21 -Message "$Tag fixture manifest file count changed."

    $seenTargets = @{}
    foreach ($entry in @($manifest.files)) {
        $source = [string]$entry.source
        $target = [string]$entry.target
        $sha256 = [string]$entry.sha256
        Assert-True -Condition ($source.StartsWith("AIWork/codedb/", [StringComparison]::Ordinal)) -Message "$Tag fixture source escaped the legacy payload root: $source"
        Assert-True -Condition ($target.StartsWith("AIWork/codedb/", [StringComparison]::Ordinal)) -Message "$Tag fixture target escaped the legacy payload root: $target"
        Assert-True -Condition (-not $seenTargets.ContainsKey($target)) -Message "$Tag fixture has duplicate target $target."
        Assert-True -Condition ($sha256 -cmatch '^[0-9a-f]{64}$') -Message "$Tag fixture has invalid hash for $target."
        $seenTargets[$target] = $true
        $destination = Get-PathFromRelative -Root $cacheRoot -RelativePath $target
        Export-ReviewedGitBlob `
            -Tag $Tag `
            -RepositoryPath ("com.rice.ai-codedb/Payload~/" + $source) `
            -Destination $destination
        Assert-Equal `
            -Actual (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() `
            -Expected $sha256 `
            -Message "$Tag fixture blob hash mismatch for $target."
    }
    foreach ($target in $seenTargets.Keys) {
        Assert-True -Condition ($legacyManagedTargets -contains $target) -Message "$Tag fixture contains a target outside the current legacy allowlist: $target."
    }
    Write-Utf8File -Path $completePath -Content "$Tag`n"
    return $cacheRoot
}

function Get-ReviewedFlatPayloadFixtureRoot {
    param([Parameter(Mandatory = $true)][ValidateSet("v0.2.4")][string]$Tag)

    $cacheRoot = Join-Path $reviewedLegacyCacheRoot "$Tag-flat"
    $completePath = Join-Path $cacheRoot ".complete"
    if (Test-Path -LiteralPath $completePath -PathType Leaf) {
        return $cacheRoot
    }
    if (Test-Path -LiteralPath $cacheRoot) {
        Remove-Item -LiteralPath $cacheRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

    $manifestPath = Join-Path $cacheRoot "payload-manifest.json"
    Export-ReviewedGitBlob `
        -Tag $Tag `
        -RepositoryPath "com.rice.ai-codedb/Payload~/payload-manifest.json" `
        -Destination $manifestPath
    $manifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.UTF8Encoding]::new($false, $true)) | ConvertFrom-Json
    Assert-Equal -Actual ([string]$manifest.package_version) -Expected "0.2.4" -Message "$Tag flat fixture Package identity mismatch."
    Assert-Equal -Actual ([string]$manifest.payload_version) -Expected "poc.27" -Message "$Tag flat fixture payload identity mismatch."
    Assert-Equal -Actual ([int]$manifest.payload_sequence) -Expected 27 -Message "$Tag flat fixture sequence mismatch."
    $flatEntries = @($manifest.files | Where-Object { [string]$_.target -like "AIWork/codedb/*" })
    Assert-Equal -Actual $flatEntries.Count -Expected 21 -Message "$Tag flat fixture file count changed."
    $seenTargets = @{}
    foreach ($entry in $flatEntries) {
        $source = [string]$entry.source
        $target = [string]$entry.target
        $sha256 = ([string]$entry.sha256).ToLowerInvariant()
        Assert-True -Condition ($source.StartsWith("AIWork/codedb/", [StringComparison]::Ordinal)) -Message "$Tag flat fixture source escaped the legacy payload root: $source"
        Assert-True -Condition ($target.StartsWith("AIWork/codedb/", [StringComparison]::Ordinal)) -Message "$Tag flat fixture target escaped the legacy payload root: $target"
        Assert-True -Condition (-not $seenTargets.ContainsKey($target)) -Message "$Tag flat fixture has duplicate target $target."
        Assert-True -Condition ($sha256 -cmatch '^[0-9a-f]{64}$') -Message "$Tag flat fixture has invalid hash for $target."
        $seenTargets[$target] = $true
        $destination = Get-PathFromRelative -Root $cacheRoot -RelativePath $target
        Export-ReviewedGitBlob `
            -Tag $Tag `
            -RepositoryPath ("com.rice.ai-codedb/Payload~/" + $source) `
            -Destination $destination
        Assert-Equal `
            -Actual (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() `
            -Expected $sha256 `
            -Message "$Tag flat fixture blob hash mismatch for $target."
    }
    Write-Utf8File -Path $completePath -Content "$Tag flat payload`n"
    return $cacheRoot
}

function Get-ReviewedGenerationFixtureRoot {
    param(
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$PackageVersion,
        [Parameter(Mandatory = $true)][int]$PayloadSequence
    )

    $tag = switch ("$GenerationId|$PackageVersion|$PayloadSequence") {
        "poc.22|0.2.3|22" { "v0.2.3" }
        "poc.23|0.2.4-preview.1|23" { "v0.2.4-preview.1" }
        "poc.24|0.2.4-preview.2|24" { "v0.2.4-preview.2" }
        "poc.27|0.2.4|27" { "v0.2.4" }
        default { throw "No reviewed published generation fixture matches $GenerationId / $PackageVersion / $PayloadSequence." }
    }
    $cacheRoot = Join-Path $reviewedLegacyCacheRoot "$tag-$GenerationId"
    $completePath = Join-Path $cacheRoot ".complete"
    if (Test-Path -LiteralPath $completePath -PathType Leaf) {
        return $cacheRoot
    }
    if (Test-Path -LiteralPath $cacheRoot) {
        Remove-Item -LiteralPath $cacheRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

    $repositoryRoot = "com.rice.ai-codedb/Payload~/Generations/$GenerationId"
    $manifestPath = Join-Path $cacheRoot "generation-manifest.json"
    Export-ReviewedGitBlob `
        -Tag $tag `
        -RepositoryPath "$repositoryRoot/generation-manifest.json" `
        -Destination $manifestPath
    $manifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.UTF8Encoding]::new($false, $true)) | ConvertFrom-Json
    Assert-Equal -Actual ([int]$manifest.schema_version) -Expected 1 -Message "$tag generation fixture schema mismatch."
    Assert-Equal -Actual ([string]$manifest.managed_by) -Expected "com.rice.ai-codedb" -Message "$tag generation fixture owner mismatch."
    Assert-Equal -Actual ([string]$manifest.generation_id) -Expected $GenerationId -Message "$tag generation fixture id mismatch."
    Assert-Equal -Actual ([string]$manifest.package_version) -Expected $PackageVersion -Message "$tag generation fixture Package mismatch."
    Assert-Equal -Actual ([string]$manifest.payload_version) -Expected $GenerationId -Message "$tag generation fixture payload mismatch."
    Assert-Equal -Actual ([int]$manifest.payload_sequence) -Expected $PayloadSequence -Message "$tag generation fixture sequence mismatch."
    Assert-Equal -Actual @($manifest.files).Count -Expected 20 -Message "$tag generation fixture file count changed."

    $seen = @{}
    foreach ($entry in @($manifest.files)) {
        $relativePath = [string]$entry.path
        $sha256 = [string]$entry.sha256
        Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($relativePath)) -Message "$tag generation fixture contains an empty path."
        Assert-True -Condition (-not $seen.ContainsKey($relativePath)) -Message "$tag generation fixture contains duplicate path $relativePath."
        Assert-True -Condition ($sha256 -cmatch '^[0-9a-f]{64}$') -Message "$tag generation fixture has an invalid hash for $relativePath."
        $seen[$relativePath] = $true
        $destination = Get-PathFromRelative -Root $cacheRoot -RelativePath $relativePath
        Export-ReviewedGitBlob `
            -Tag $tag `
            -RepositoryPath "$repositoryRoot/$relativePath" `
            -Destination $destination
        Assert-Equal `
            -Actual (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant() `
            -Expected $sha256 `
            -Message "$tag generation fixture blob hash mismatch for $relativePath."
    }
    Write-Utf8File -Path $completePath -Content "$tag $GenerationId`n"
    return $cacheRoot
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

function Test-AllowedSpawnEpermDeferral {
    param([Parameter(Mandatory = $true)]$Result)

    return $Result.ExitCode -ne 0 -and
        $Result.Text.Contains("EPERM: spawn EPERM") -and
        [string]::Equals($env:RICE_CODEDB_TEST_ALLOW_SPAWN_EPERM, "1", [StringComparison]::Ordinal)
}

function Assert-StructuredCommandResult {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Outcome,
        [Parameter(Mandatory = $true)][ValidateSet("COMPLETE", "PENDING")][string]$CleanupState,
        [Parameter(Mandatory = $true)][string]$Label,
        [string[]]$RequiredScopes = @()
    )

    $lines = @($Result.Text -split '\r?\n' | Where-Object { $_.StartsWith("[COMMAND_RESULT] ", [StringComparison]::Ordinal) })
    Assert-Equal -Actual $lines.Count -Expected 1 -Message "$Label did not emit exactly one structured command result."
    $document = $lines[0].Substring("[COMMAND_RESULT] ".Length) | ConvertFrom-Json
    Assert-Equal -Actual $document.schema_version -Expected 1 -Message "$Label command-result schema mismatch."
    Assert-Equal -Actual $document.managed_by -Expected "com.rice.ai-codedb" -Message "$Label command-result manager mismatch."
    Assert-Equal -Actual $document.action -Expected $Action -Message "$Label command-result action mismatch."
    Assert-Equal -Actual $document.outcome -Expected $Outcome -Message "$Label command-result outcome mismatch."
    Assert-Equal -Actual $document.cleanup_state -Expected $CleanupState -Message "$Label command-result cleanup state mismatch."
    Assert-Equal -Actual $document.exit_code -Expected $Result.ExitCode -Message "$Label command-result exit code mismatch."
    Assert-True -Condition ([string]$document.phase -cmatch '^[A-Z][A-Z0-9_]{0,63}$') -Message "$Label command-result phase is invalid."
    Assert-True -Condition ([string]$document.reason_code -cmatch '^[A-Z][A-Z0-9_]{0,63}$') -Message "$Label command-result reason is invalid."
    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace([string]$document.next_action)) -Message "$Label command-result omitted its one next action."
    foreach ($scope in $RequiredScopes) {
        Assert-True -Condition (@($document.mutated_scopes) -ccontains $scope) -Message "$Label command-result omitted mutation scope $scope."
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
    param(
        [string]$Root = $hostRoot,
        [string[]]$AdditionalAllowedRuntimeFiles = @()
    )

    $runtimePath = Join-Path $Root "AIWork\.runtime\codedb\payload-materializer"
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
    $upgradeStatePath = Join-Path $runtimePath "upgrade-state.json"
    $mcpAvailabilityPath = Join-Path $runtimePath "mcp-availability.json"
    $allowedRuntimeFiles = @($upgradeStatePath, $mcpAvailabilityPath) + @($AdditionalAllowedRuntimeFiles | ForEach-Object {
        [System.IO.Path]::GetFullPath($_)
    })
    $unexpectedFiles = @(Get-ChildItem -LiteralPath $runtimePath -Recurse -Force -File | Where-Object {
        $candidatePath = $_.FullName
        @($allowedRuntimeFiles | Where-Object {
            [string]::Equals($_, $candidatePath, [StringComparison]::OrdinalIgnoreCase)
        }).Count -eq 0
    })
    Assert-Equal -Actual $unexpectedFiles.Count -Expected 0 -Message "Unexpected materializer runtime files remain."

    if (Test-Path -LiteralPath $upgradeStatePath -PathType Leaf) {
        $upgradeState = Get-Content -LiteralPath $upgradeStatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual $upgradeState.managed_by -Expected "com.rice.ai-codedb" -Message "Persisted upgrade state manager mismatch."
        Assert-True -Condition ([string]$upgradeState.state -in @("INSTALLING", "SWITCHING", "ROLLBACK", "CURRENT", "CHECK_FAILED")) -Message "Persisted upgrade state is invalid."
    }
    if (Test-Path -LiteralPath $mcpAvailabilityPath -PathType Leaf) {
        $availabilityState = Get-Content -LiteralPath $mcpAvailabilityPath -Raw | ConvertFrom-Json
        Assert-Equal -Actual ([int]$availabilityState.schema_version) -Expected 2 -Message "Persisted MCP availability schema mismatch."
        Assert-Equal -Actual ([string]$availabilityState.managed_by) -Expected "com.rice.ai-codedb" -Message "Persisted MCP availability manager mismatch."
        Assert-Equal -Actual ([System.IO.Path]::GetFullPath([string]$availabilityState.project_root)) -Expected ([System.IO.Path]::GetFullPath($Root)) -Message "Persisted MCP availability project root mismatch."
        Assert-True -Condition ([string]$availabilityState.availability -in @("AVAILABLE", "UNAVAILABLE")) -Message "Persisted MCP availability state is invalid."
        Assert-True -Condition (Test-Path -LiteralPath (Join-Path $Root "AIWork\codedb\.rice-ai-codedb-payload.json") -PathType Leaf) -Message "MCP availability evidence remained without an installed Host marker."
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
        [Parameter(Mandatory = $true)][string]$PriorPackageVersion,
        [string]$Root = $hostRoot,
        [string]$PointerRelativePath = $currentPointerRelativePath,
        [switch]$UsePackageGeneration,
        [switch]$UseReviewedGeneration,
        [switch]$UseReviewedFlatPayload,
        [switch]$PreserveManagedState,
        [switch]$SkipMarker
    )

    if ($UsePackageGeneration -and $UseReviewedGeneration) {
        throw "A prior-generation fixture must use exactly one published source."
    }

    $reviewedFlatPayloadRoot = $null
    $installedFlatTargets = @($legacyManagedTargets)
    if ($UseReviewedFlatPayload) {
        $reviewedFlatPayloadRoot = Get-ReviewedFlatPayloadFixtureRoot -Tag "v0.2.4"
        $reviewedFlatManifest = Get-Content -LiteralPath (Join-Path $reviewedFlatPayloadRoot "payload-manifest.json") -Raw | ConvertFrom-Json
        $installedFlatTargets = @($reviewedFlatManifest.files | Where-Object {
            [string]$_.target -like "AIWork/codedb/*"
        } | ForEach-Object { [string]$_.target } | Sort-Object)
    }

    if (-not $PreserveManagedState) {
        if ([string]::Equals([System.IO.Path]::GetFullPath($Root), [System.IO.Path]::GetFullPath($hostRoot), [StringComparison]::OrdinalIgnoreCase)) {
            Clear-ManagedTestState
        } else {
            foreach ($relativePath in $managedTargets + @($markerRelativePath)) {
                $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
                if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
            }
        }
        $hostGenerationRuntimeRoot = Get-PathFromRelative -Root $Root -RelativePath "AIWork/.runtime/codedb/host"
        if (Test-Path -LiteralPath $hostGenerationRuntimeRoot) {
            Remove-Item -LiteralPath $hostGenerationRuntimeRoot -Recurse -Force
        }

        foreach ($relativePath in $installedFlatTargets) {
            $source = if ($UseReviewedFlatPayload) {
                Get-PathFromRelative -Root $reviewedFlatPayloadRoot -RelativePath $relativePath
            } else {
                Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
            }
            $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            Copy-Item -LiteralPath $source -Destination $target -Force
        }
    }

    $usesPublishedGeneration = $UsePackageGeneration -or $UseReviewedGeneration
    $canonicalGenerationRoot = if ($UseReviewedGeneration) {
        Get-ReviewedGenerationFixtureRoot `
            -GenerationId $PriorGenerationId `
            -PackageVersion $PriorPackageVersion `
            -PayloadSequence $PriorPayloadSequence
    } else {
        Join-Path $canonicalPayloadRoot ("Generations\" + $(if ($UsePackageGeneration) { $PriorGenerationId } else { $generationId }))
    }
    $canonicalGenerationManifestPath = Join-Path $canonicalGenerationRoot "generation-manifest.json"
    $canonicalGenerationManifest = Get-Content -LiteralPath $canonicalGenerationManifestPath -Raw | ConvertFrom-Json
    if ($usesPublishedGeneration -and
        (-not [string]::Equals([string]$canonicalGenerationManifest.generation_id, $PriorGenerationId, [StringComparison]::Ordinal) -or
         [int]$canonicalGenerationManifest.payload_sequence -ne $PriorPayloadSequence -or
         -not [string]::Equals([string]$canonicalGenerationManifest.package_version, $PriorPackageVersion, [StringComparison]::Ordinal))) {
        throw "Package generation fixture identity does not match the requested prior generation: $PriorGenerationId"
    }
    $priorGenerationRelativeRoot = "AIWork/.runtime/codedb/host/generations/$PriorGenerationId"
    $priorGenerationRoot = Get-PathFromRelative -Root $Root -RelativePath $priorGenerationRelativeRoot
    $priorGenerationFiles = New-Object System.Collections.Generic.List[object]
    foreach ($entry in @($canonicalGenerationManifest.files)) {
        $relativePath = [string]$entry.path
        $sourcePath = Get-PathFromRelative -Root $canonicalGenerationRoot -RelativePath $relativePath
        $targetPath = Get-PathFromRelative -Root $priorGenerationRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPath) | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Force

        if (-not $usesPublishedGeneration -and [string]::Equals($relativePath, "coordinator/codedb-watch-coordinator.mjs", [StringComparison]::Ordinal)) {
            $content = [System.IO.File]::ReadAllText($targetPath).Replace(
                [string]$canonicalPayloadManifest.package_version,
                $PriorPackageVersion)
            Write-Utf8File -Path $targetPath -Content $content
        } elseif (-not $usesPublishedGeneration -and [string]::Equals($relativePath, "shared/codedb-host-use-gate.mjs", [StringComparison]::Ordinal)) {
            $content = [System.IO.File]::ReadAllText($targetPath).Replace($generationId, $PriorGenerationId)
            Write-Utf8File -Path $targetPath -Content $content
        }

        $priorGenerationFiles.Add([ordered]@{
            path = $relativePath
            sha256 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }) | Out-Null
    }

    $priorGenerationManifestPath = Join-Path $priorGenerationRoot "generation-manifest.json"
    if ($usesPublishedGeneration) {
        Copy-Item -LiteralPath $canonicalGenerationManifestPath -Destination $priorGenerationManifestPath -Force
    } else {
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
        Write-Utf8File -Path $priorGenerationManifestPath -Content (($priorGenerationManifest | ConvertTo-Json -Depth 8) + "`n")
    }

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
    $pointerPath = Get-PathFromRelative -Root $Root -RelativePath $PointerRelativePath
    if (Test-Path -LiteralPath $pointerPath) {
        Remove-Item -LiteralPath $pointerPath -Force
    }
    Write-Utf8File -Path $pointerPath -Content (($pointer | ConvertTo-Json -Depth 8) + "`n")

    $ownedTargets = New-Object System.Collections.Generic.List[string]
    foreach ($relativePath in $installedFlatTargets) {
        $ownedTargets.Add($relativePath) | Out-Null
    }
    foreach ($entry in $priorGenerationFiles) {
        $ownedTargets.Add("$priorGenerationRelativeRoot/$($entry.path)") | Out-Null
    }
    $ownedTargets.Add("$priorGenerationRelativeRoot/generation-manifest.json") | Out-Null
    $ownedTargets.Add($PointerRelativePath) | Out-Null
    $markerFiles = @($ownedTargets | Sort-Object | ForEach-Object {
        $targetPath = Get-PathFromRelative -Root $Root -RelativePath $_
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
    $markerPath = Get-PathFromRelative -Root $Root -RelativePath $markerRelativePath
    if (-not $SkipMarker) {
        Write-Utf8File -Path $markerPath -Content (($marker | ConvertTo-Json -Depth 8) + "`n")
    }

    return [pscustomobject]@{
        GenerationRoot = $priorGenerationRoot
        GenerationTargets = @($ownedTargets | Where-Object { $_.StartsWith("$priorGenerationRelativeRoot/", [StringComparison]::Ordinal) })
        InstalledFlatTargets = @($installedFlatTargets)
        OwnedTargets = @($ownedTargets)
        MarkerPath = $markerPath
        PointerPath = $pointerPath
    }
}

function Reset-RepairFixture {
    param([string]$Root = $repairHostRoot)

    if (Test-Path -LiteralPath $Root) {
        Remove-Item -LiteralPath $Root -Recurse -Force
    }
    New-TestHost -Root $Root
}

function Install-CurrentTrackedAdoptionFixture {
    param([string]$Root = $repairHostRoot)

    Reset-RepairFixture -Root $Root
    foreach ($relativePath in $legacyManagedTargets) {
        $source = Get-CanonicalPayloadSourcePath -TargetRelativePath $relativePath
        $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $payloadContentSha256 = Get-TestPayloadContentIdentitySha256 `
        -Manifest $canonicalPayloadManifest `
        -CurrentPointerTarget $currentPointerRelativePath `
        -GenerationTargetPrefix $generationTargetPrefix
    Assert-Equal `
        -Actual $payloadContentSha256 `
        -Expected $canonicalPayloadContentSha256 `
        -Message "Tracked adoption payload identity does not match the canonical production contract."

    $markerFiles = @($canonicalPayloadManifest.files | Where-Object {
        ([string]$_.target).StartsWith("AIWork/codedb/", [StringComparison]::OrdinalIgnoreCase)
    } | Sort-Object target | ForEach-Object {
        [ordered]@{
            path = [string]$_.target
            installed_sha256 = [string]$_.sha256
        }
    })
    $marker = [ordered]@{
        schema_version = 2
        managed_by = "com.rice.ai-codedb"
        package_version = [string]$canonicalPayloadManifest.package_version
        payload_version = [string]$canonicalPayloadManifest.payload_version
        payload_sequence = [int]$canonicalPayloadManifest.payload_sequence
        payload_content_sha256 = $payloadContentSha256
        host_use_gate_version = 1
        generation_lease_version = 2
        generation_id = $generationId
        bootstrap_protocol = 1
        current_pointer = $currentPointerRelativePath
        files = $markerFiles
    }
    $markerJson = ($marker | ConvertTo-Json -Depth 8).Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd([char]10) + "`n"
    Write-Utf8File -Path (Get-PathFromRelative -Root $Root -RelativePath $markerRelativePath) -Content $markerJson
}

function Get-ByteSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return "missing"
    }
    $item = Get-Item -LiteralPath $Path -Force
    return "file:$((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()):$($item.Length):$($item.LastWriteTimeUtc.Ticks):$([int]$item.Attributes)"
}

function Assert-RepairBlockedWithoutWrites {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigContent,
        [Parameter(Mandatory = $true)][string]$ExpectedText,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Install-CurrentTrackedAdoptionFixture
    $configPath = Join-Path $repairHostRoot ".codex\config.toml"
    Write-Utf8File -Path $configPath -Content $ConfigContent

    $before = Get-FileSnapshot -Root $repairHostRoot
    $blocked = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-True -Condition ($blocked.ExitCode -ne 0) -Message "$Label unexpectedly succeeded."
    Assert-True -Condition ($blocked.Text.Contains("[RESULT] BLOCKED")) -Message "$Label did not report BLOCKED."
    Assert-True -Condition ($blocked.Text.Contains($ExpectedText)) -Message "$Label did not report '$ExpectedText'.`n$($blocked.Text)"
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $before -Message "$Label changed the fixture."
}

function Invoke-McpConfigCompatibilityScenarios {
    $configPath = Join-Path $repairHostRoot ".codex\config.toml"
    $backupRoot = Join-Path $repairHostRoot "AIWork\.runtime\codedb\payload-materializer\mcp-config-backups"
    $targetTable = "mcp_servers.codedb-repair-fixture"
    $targetHeader = "[$targetTable]"

    function Reset-McpConfigCase {
        if (Test-Path -LiteralPath $configPath) {
            Remove-Item -LiteralPath $configPath -Force
        }
        if (Test-Path -LiteralPath $backupRoot) {
            Remove-Item -LiteralPath $backupRoot -Recurse -Force
        }
    }

    function Assert-McpConfigRepair {
        param(
            [Parameter(Mandatory = $true)][byte[]]$OriginalBytes,
            [Parameter(Mandatory = $true)][string]$Label,
            [Parameter(Mandatory = $true)][string[]]$PreservedFragments,
            [switch]$ExpectBom,
            [switch]$ExpectCrLf
        )

        Reset-McpConfigCase
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $configPath) | Out-Null
        [System.IO.File]::WriteAllBytes($configPath, $OriginalBytes)
        $originalHash = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash
        $repair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $repair -ExitCode 0 -Label $Label
        Assert-True -Condition ($repair.Text.Contains("[RESULT] REPAIRED")) -Message "$Label did not report REPAIRED."
        Assert-StructuredCommandResult `
            -Result $repair `
            -Action "REPAIR" `
            -Outcome "REPAIRED" `
            -CleanupState "COMPLETE" `
            -RequiredScopes @("mcp_registration", "mcp_availability") `
            -Label $Label

        $repairedBytes = [System.IO.File]::ReadAllBytes($configPath)
        $offset = if ($ExpectBom) { 3 } else { 0 }
        if ($ExpectBom) {
            Assert-True `
                -Condition ($repairedBytes.Length -ge 3 -and $repairedBytes[0] -eq 0xEF -and $repairedBytes[1] -eq 0xBB -and $repairedBytes[2] -eq 0xBF) `
                -Message "$Label did not preserve the UTF-8 BOM."
        }
        $repairedText = [System.Text.UTF8Encoding]::new($false, $true).GetString(
            $repairedBytes,
            $offset,
            $repairedBytes.Length - $offset)
        if ($ExpectCrLf) {
            Assert-True -Condition ($repairedText.Contains("`r`n")) -Message "$Label did not preserve CRLF."
            Assert-True -Condition (-not $repairedText.Replace("`r`n", "").Contains("`n")) -Message "$Label introduced mixed line endings."
        }
        foreach ($fragment in $PreservedFragments) {
            Assert-True -Condition ($repairedText.Contains($fragment)) -Message "$Label did not byte-preserve '$fragment'."
        }
        foreach ($managedLine in @(
            'command = "node"',
            'cwd = "."',
            'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
            'startup_timeout_sec = 120'
        )) {
            Assert-True -Condition ($repairedText.Contains($managedLine)) -Message "$Label did not publish '$managedLine'."
        }
        Assert-Equal `
            -Actual ([regex]::Matches($repairedText, '(?m)^\[mcp_servers\.codedb-repair-fixture\]\s*(?:#.*)?$').Count) `
            -Expected 1 `
            -Message "$Label did not leave exactly one target parent table."
        $backups = @(Get-ChildItem -LiteralPath $backupRoot -Force -File)
        Assert-Equal -Actual $backups.Count -Expected 1 -Message "$Label did not create exactly one replacement-time backup."
        Assert-Equal `
            -Actual (Get-FileHash -LiteralPath $backups[0].FullName -Algorithm SHA256).Hash `
            -Expected $originalHash `
            -Message "$Label backup is not the byte-exact pre-image."

        $afterFirstRepair = Get-FileSnapshot -Root $repairHostRoot
        $repeat = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $repeat -ExitCode 0 -Label "Repeated $Label"
        Assert-True -Condition ($repeat.Text.Contains("[PHASE MCP_REGISTRATION] CURRENT")) -Message "Repeated $Label did not report CURRENT."
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $afterFirstRepair -Message "Repeated $Label was not byte-exactly idempotent."
    }

    function Assert-McpConfigBlocked {
        param(
            [Parameter(Mandatory = $true)][string]$Content,
            [Parameter(Mandatory = $true)][string]$ExpectedText,
            [Parameter(Mandatory = $true)][string]$Label
        )

        Reset-McpConfigCase
        Write-Utf8File -Path $configPath -Content $Content
        $before = Get-FileSnapshot -Root $repairHostRoot
        $blocked = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-True -Condition ($blocked.ExitCode -ne 0) -Message "$Label unexpectedly succeeded."
        Assert-True -Condition ($blocked.Text.Contains("[RESULT] BLOCKED")) -Message "$Label did not report BLOCKED."
        Assert-True -Condition ($blocked.Text.Contains($ExpectedText)) -Message "$Label did not report '$ExpectedText'.`n$($blocked.Text)"
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $before -Message "$Label changed Host, config, backup, or control-state bytes."
    }

    Install-CurrentTrackedAdoptionFixture
    $bootstrap = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $bootstrap -ExitCode 0 -Label "MCP compatibility fixture bootstrap"
    Reset-McpConfigCase

    $parentFirstBody = @(
        "# parent-first prefix",
        "$targetHeader # target parent",
        'custom_transport = "keep-parent" # custom direct key',
        'command = "old-node" # managed comment',
        'startup_timeout_sec = 9',
        "",
        "# client-owned tool policy",
        "[$targetTable.tools.codedb_text_search]",
        'approval_mode = "approve" # keep tool comment',
        "",
        "[mcp_servers.unrelated]",
        'command = "unrelated.exe"',
        ""
    ) -join "`r`n"
    $parentFirstUtf8 = [System.Text.UTF8Encoding]::new($false).GetBytes($parentFirstBody)
    $parentFirstBytes = New-Object byte[] (3 + $parentFirstUtf8.Length)
    $parentFirstBytes[0] = 0xEF
    $parentFirstBytes[1] = 0xBB
    $parentFirstBytes[2] = 0xBF
    [Array]::Copy($parentFirstUtf8, 0, $parentFirstBytes, 3, $parentFirstUtf8.Length)
    Assert-McpConfigRepair `
        -OriginalBytes $parentFirstBytes `
        -Label "Parent-first target descendant Repair" `
        -ExpectBom `
        -ExpectCrLf `
        -PreservedFragments @(
            'custom_transport = "keep-parent" # custom direct key',
            "# client-owned tool policy`r`n[$targetTable.tools.codedb_text_search]`r`napproval_mode = `"approve`" # keep tool comment",
            "[mcp_servers.unrelated]`r`ncommand = `"unrelated.exe`""
        )

    $childFirst = @"
# child-first prefix
[$targetTable.tools.codedb_text_search]
approval_mode = "approve-child-first"

$targetHeader # parent follows child
custom_direct = "keep-child-first"
command = "stale-node"
"@
    Assert-McpConfigRepair `
        -OriginalBytes ([System.Text.UTF8Encoding]::new($false).GetBytes($childFirst)) `
        -Label "Child-first target descendant Repair" `
        -PreservedFragments @(
            "# child-first prefix`n[$targetTable.tools.codedb_text_search]`napproval_mode = `"approve-child-first`"",
            'custom_direct = "keep-child-first"',
            "$targetHeader # parent follows child"
        )

    $childOnly = @"
# child-only prefix
[$targetTable.tools.codedb_text_search]
approval_mode = "approve-child-only"

[mcp_servers.unrelated]
command = "keep-unrelated"
"@
    Assert-McpConfigRepair `
        -OriginalBytes ([System.Text.UTF8Encoding]::new($false).GetBytes($childOnly)) `
        -Label "Child-only target descendant Repair" `
        -PreservedFragments @(
            "# child-only prefix`n[$targetTable.tools.codedb_text_search]`napproval_mode = `"approve-child-only`"",
            "[mcp_servers.unrelated]`ncommand = `"keep-unrelated`""
        )

    Install-CurrentTrackedAdoptionFixture
    $thirdPartyConfigPath = $configPath
    $thirdPartyBackupRoot = $backupRoot
    $thirdPartyServer = "codedb-repair-fixture"
    $thirdPartyFixturePath = Join-Path $packageRoot "Tests~\Fixtures\mcp-config-tools-descendant.toml"
    $thirdPartyContent = [System.IO.File]::ReadAllText($thirdPartyFixturePath).
        Replace('__TARGET_SERVER__', $thirdPartyServer).
        Replace('__TARGET_WRAPPER__', "$thirdPartyServer-wrapper.mjs")
    Write-Utf8File -Path $thirdPartyConfigPath -Content $thirdPartyContent
    $thirdPartyOriginalHash = (Get-FileHash -LiteralPath $thirdPartyConfigPath -Algorithm SHA256).Hash
    $thirdPartyRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $thirdPartyRepair -ExitCode 0 -Label "Sanitized third-party tool configuration Repair"
    $thirdPartyAfter = [System.IO.File]::ReadAllText($thirdPartyConfigPath)
    foreach ($fragment in @(
        "[mcp_servers.$thirdPartyServer.tools.codedb_text_search]`napproval_mode = `"approve`"",
        'custom_transport = "keep"',
        "[mcp_servers.unrelated]`ncommand = `"unrelated.exe`""
    )) {
        Assert-True -Condition ($thirdPartyAfter.Contains($fragment)) -Message "Sanitized third-party Repair did not preserve '$fragment'."
    }
    foreach ($managedLine in @(
        'command = "node"',
        'cwd = "."',
        'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
        'startup_timeout_sec = 120'
    )) {
        Assert-True -Condition ($thirdPartyAfter.Contains($managedLine)) -Message "Sanitized third-party Repair did not publish '$managedLine'."
    }
    $thirdPartyBackups = @(Get-ChildItem -LiteralPath $thirdPartyBackupRoot -Force -File)
    Assert-Equal -Actual $thirdPartyBackups.Count -Expected 1 -Message "Sanitized third-party Repair did not create one backup."
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $thirdPartyBackups[0].FullName -Algorithm SHA256).Hash `
        -Expected $thirdPartyOriginalHash `
        -Message "Sanitized third-party backup is not byte-exact."
    $thirdPartySnapshot = Get-FileSnapshot -Root $repairHostRoot
    $thirdPartyRepeat = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $thirdPartyRepeat -ExitCode 0 -Label "Repeated sanitized third-party tool configuration Repair"
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $thirdPartySnapshot -Message "Repeated sanitized third-party Repair was not idempotent."

    Assert-McpConfigBlocked `
        -Content "[mcp_servers.alpha]`ncommand = unquoted-command`n" `
        -ExpectedText "unsupported or invalid bare TOML value" `
        -Label "Focused invalid TOML refusal"
    Assert-McpConfigBlocked `
        -Content "$targetHeader`ncommand = `"node`"`n`n$targetHeader`ncommand = `"node`"`n" `
        -ExpectedText "duplicate table" `
        -Label "Focused duplicate target refusal"
    Assert-McpConfigBlocked `
        -Content 'mcp_servers.codedb-repair-fixture = "occupied"' `
        -ExpectedText "ambiguous dotted-key collision" `
        -Label "Focused target scalar refusal"
    Assert-McpConfigBlocked `
        -Content "[mcp_servers]`ncodedb-repair-fixture = { command = `"node`" }`n" `
        -ExpectedText "ambiguous dotted-key collision" `
        -Label "Focused incompatible inline target refusal"
    Assert-McpConfigBlocked `
        -Content "[[$targetTable]]`ncommand = `"node`"`n" `
        -ExpectedText "ambiguous target array table" `
        -Label "Focused target array-table refusal"
    Assert-McpConfigBlocked `
        -Content "[$targetTable.command]`nformat = `"managed-key-table`"`n" `
        -ExpectedText "table namespace collision with managed key $targetTable.command" `
        -Label "Focused managed command table refusal"
    Assert-McpConfigBlocked `
        -Content "[[$targetTable.args]]`nvalue = `"managed-key-array`"`n" `
        -ExpectedText "table namespace collision with managed key $targetTable.args" `
        -Label "Focused managed args array-table refusal"
    Assert-McpConfigBlocked `
        -Content "$targetHeader`nstartup_timeout_sec.value = 120`n" `
        -ExpectedText "ambiguous target key collision" `
        -Label "Focused managed dotted-key refusal"

    Write-Host "[OK] MCP config compatibility preserved legal parent-first, child-first, child-only, custom-key, and tool-table configuration while retaining fail-closed namespace checks."
}

function Invoke-McpAvailabilityProbeContractScenarios {
    $probeRoot = Join-Path $runRoot "mcp-availability-probe"
    $wrapperRoot = Join-Path $probeRoot "AIWork\codedb\wrapper"
    New-Item -ItemType Directory -Force -Path (Join-Path $probeRoot "Assets") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $probeRoot "ProjectSettings") | Out-Null
    New-Item -ItemType Directory -Force -Path $wrapperRoot | Out-Null
    $wrapperPath = Join-Path $wrapperRoot "codedb-project-wrapper.mjs"
    $probePath = Join-Path $packageRoot "Tools~\probe-codedb-mcp-availability.mjs"
    $wrapperSource = @'
import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";

const mode = fs.readFileSync(path.join(process.cwd(), "probe-mode.txt"), "utf8").trim();
const annotations = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };
const tools = ["codedb_context", "codedb_find", "codedb_read", "codedb_search", "codedb_status", "codedb_text_search"]
  .map((name) => ({
    name,
    description: name,
    ...(mode === "MISSING_ANNOTATIONS" ? {} : { annotations }),
    inputSchema: { type: "object" }
  }));
const statuses = {
  EDITOR_OFFLINE: ["Editor demand: offline", "Automatic refresh: editor_offline", "Lifecycle reason: EDITOR_OFFLINE", "Watch coordinator: stopped"],
  STARTING: ["Editor demand: online", "Automatic refresh: starting", "Lifecycle reason: STARTING", "Watch coordinator: stopped"],
  COORDINATOR_UNREACHABLE: ["Editor demand: online", "Automatic refresh: unreachable", "Lifecycle reason: COORDINATOR_UNREACHABLE", "Watch coordinator: unreachable"],
  QUERY_FAILURE: ["Editor demand: online", "Automatic refresh: active", "Lifecycle reason: READY", "Watch coordinator: ready"],
  USABLE: ["Editor demand: online", "Automatic refresh: active", "Lifecycle reason: READY", "Watch coordinator: ready"]
};

function respond(id, result) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", id, result })}\n`);
}

const lines = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });
for await (const line of lines) {
  const message = JSON.parse(line);
  if (message.id === undefined) continue;
  if (message.method === "initialize") {
    respond(message.id, { protocolVersion: "2025-06-18", capabilities: {}, serverInfo: { name: "codedb-project-wrapper", version: "fixture" } });
  } else if (message.method === "tools/list") {
    respond(message.id, { tools });
  } else if (message.method === "tools/call" && message.params?.name === "codedb_status") {
    respond(message.id, { content: [{ type: "text", text: ["[OK] fixture wrapper ready.", ...(statuses[mode] ?? [])].join("\n") }], isError: false });
  } else if (message.method === "tools/call" && message.params?.name === "codedb_text_search") {
    respond(message.id, mode === "QUERY_FAILURE"
      ? { content: [{ type: "text", text: "backend query unavailable" }], isError: true }
      : { content: [{ type: "text", text: "[NO HIT] availability sentinel" }], isError: false });
  }
}
'@
    Write-Utf8File -Path $wrapperPath -Content $wrapperSource

    $scenarios = @(
        [pscustomobject]@{ Mode = "MISSING_ANNOTATIONS"; ExitCode = 1; StatusUsable = $false; SearchCallable = $false; Detail = "missing the required read-only MCP annotations" },
        [pscustomobject]@{ Mode = "EDITOR_OFFLINE"; ExitCode = 1; StatusUsable = $false; SearchCallable = $false; Detail = "EDITOR_OFFLINE" },
        [pscustomobject]@{ Mode = "STARTING"; ExitCode = 1; StatusUsable = $false; SearchCallable = $false; Detail = "STARTING" },
        [pscustomobject]@{ Mode = "COORDINATOR_UNREACHABLE"; ExitCode = 1; StatusUsable = $false; SearchCallable = $false; Detail = "COORDINATOR_UNREACHABLE" },
        [pscustomobject]@{ Mode = "QUERY_FAILURE"; ExitCode = 1; StatusUsable = $true; SearchCallable = $false; Detail = "codedb_text_search" },
        [pscustomobject]@{ Mode = "USABLE"; ExitCode = 0; StatusUsable = $true; SearchCallable = $true; Detail = "bounded codedb_text_search succeeded" }
    )
    foreach ($scenario in $scenarios) {
        Write-Utf8File -Path (Join-Path $probeRoot "probe-mode.txt") -Content ($scenario.Mode + "`n")
        $global:LASTEXITCODE = 0
        $previousErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            $output = @(& $nodePath $probePath --project-root $probeRoot 2>&1)
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        $exitCode = $LASTEXITCODE
        Assert-Equal -Actual $exitCode -Expected $scenario.ExitCode -Message "MCP availability probe $($scenario.Mode) exit mismatch."
        $jsonLines = @($output | ForEach-Object { [string]$_ } | Where-Object { $_.TrimStart().StartsWith("{") })
        Assert-Equal -Actual $jsonLines.Count -Expected 1 -Message "MCP availability probe $($scenario.Mode) result count mismatch."
        $evidence = $jsonLines[0] | ConvertFrom-Json
        Assert-Equal -Actual ([int]$evidence.schema_version) -Expected 2 -Message "MCP availability probe $($scenario.Mode) schema mismatch."
        Assert-True -Condition ([bool]$evidence.wrapper_initialize_callable) -Message "MCP availability probe $($scenario.Mode) did not distinguish wrapper initialize."
        $expectedToolSchema = $scenario.Mode -ne "MISSING_ANNOTATIONS"
        Assert-Equal -Actual ([bool]$evidence.tools_list_callable) -Expected $expectedToolSchema -Message "MCP availability probe $($scenario.Mode) tools/list schema mismatch."
        Assert-Equal -Actual ([bool]$evidence.codedb_status_callable) -Expected $expectedToolSchema -Message "MCP availability probe $($scenario.Mode) codedb_status callability mismatch."
        Assert-Equal -Actual ([bool]$evidence.codedb_status_usable) -Expected $scenario.StatusUsable -Message "MCP availability probe $($scenario.Mode) usable status mismatch."
        Assert-Equal -Actual ([bool]$evidence.codedb_text_search_callable) -Expected $scenario.SearchCallable -Message "MCP availability probe $($scenario.Mode) bounded query mismatch."
        Assert-Equal -Actual ([string]$evidence.availability) -Expected $(if ($scenario.ExitCode -eq 0) { "AVAILABLE" } else { "UNAVAILABLE" }) -Message "MCP availability probe $($scenario.Mode) availability mismatch."
        Assert-True -Condition ([string]$evidence.detail -like "*$($scenario.Detail)*") -Message "MCP availability probe $($scenario.Mode) diagnostic mismatch."
    }
    Write-Host "[OK] MCP availability requires read-only tool annotations and distinguishes callable wrapper surface from EDITOR_OFFLINE, STARTING, COORDINATOR_UNREACHABLE, failed query, and usable backend states."

    $productionInstanceProject = Join-Path $runRoot "production-instance-availability"
    $productionInstanceRoot = $null
    $productionEditorLease = $null
    $productionWatcherProcessId = 0
    $productionWatcherLifecycleId = $null
    $productionWatcherManager = $null
    $productionConvergenceDeferred = $false
    New-TestHost -Root $productionInstanceProject
    Remove-Item -LiteralPath (Join-Path $productionInstanceProject $fixtureMarkerName) -Force
    try {
        $productionConvergence = Invoke-Materializer `
            -Action "Upgrade" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $productionInstanceProject `
            -OmitPocFixture
        $productionConvergenceDeferred = $productionConvergence.ExitCode -ne 0 -and
            (Test-AllowedSpawnEpermDeferral -Result $productionConvergence)
        if ($productionConvergenceDeferred) {
            Write-Host "[DEFERRED] Production instance convergence could not spawn its Package-owned candidate processes in the current managed test environment."
        } else {
            Assert-Result -Result $productionConvergence -ExitCode 0 -Label "Production immutable-instance automatic convergence"
            Assert-True -Condition ($productionConvergence.Text.Contains("[PHASE CANDIDATE_VERIFY] READY")) -Message "Production convergence did not prove initialize, tools/list, usable status, and bounded query before activation."
            Assert-True -Condition ($productionConvergence.Text.Contains("[PRODUCT_STATE] READY")) -Message "Production convergence did not reduce the activated instance to READY."
            Assert-True -Condition (-not $productionConvergence.Text.Contains("fixture-only")) -Message "Production convergence used fixture-only MCP availability evidence."

            $selectionPath = Join-Path $productionInstanceProject "AIWork\.runtime\codedb\control\current-instance.json"
            $selection = Get-Content -LiteralPath $selectionPath -Raw | ConvertFrom-Json
            $productionInstanceRoot = Get-PathFromRelative `
                -Root $productionInstanceProject `
                -RelativePath ([string]$selection.instance_relative_path)
            $instanceManifestPath = Join-Path $productionInstanceRoot "instance.json"
            Assert-Equal `
                -Actual (Get-FileHash -LiteralPath $instanceManifestPath -Algorithm SHA256).Hash.ToLowerInvariant() `
                -Expected ([string]$selection.instance_manifest_sha256) `
                -Message "Production current-instance selection did not bind the activated manifest."
            $availabilityPath = Join-Path $productionInstanceRoot "logs\mcp-availability.json"
            $availability = Get-Content -LiteralPath $availabilityPath -Raw | ConvertFrom-Json
            Assert-Equal -Actual ([string]$availability.availability) -Expected "AVAILABLE" -Message "Production candidate availability was not persisted as AVAILABLE."
            Assert-True -Condition ([bool]$availability.codedb_status_usable) -Message "Production candidate did not persist usable codedb_status evidence."
            Assert-True -Condition ([bool]$availability.codedb_text_search_callable) -Message "Production candidate did not persist bounded codedb_text_search evidence."

            $productionWatcherManager = Join-Path $productionInstanceProject "AIWork\.runtime\codedb\host\generations\$generationId\scripts\manage-codedb-project-watch.ps1"
            $productionEditorLease = New-TestEditorLease `
                -LeaseRoot (Join-Path $productionInstanceRoot "watch\lifecycle\editor-leases") `
                -Root $productionInstanceProject `
                -SessionId "production-instance-availability-editor"
            $previousUnityRoot = $env:RICE_CODEDB_UNITY_ROOT
            $previousInstanceRoot = $env:RICE_CODEDB_INSTANCE_ROOT
            try {
                $env:RICE_CODEDB_UNITY_ROOT = [System.IO.Path]::GetFullPath($productionInstanceProject)
                $env:RICE_CODEDB_INSTANCE_ROOT = [System.IO.Path]::GetFullPath($productionInstanceRoot)
                $ensure = Invoke-PowerShellAction -Root $productionInstanceProject -Action {
                    & $productionWatcherManager -Action Ensure
                }
                Assert-Result -Result $ensure -ExitCode 0 -Label "Activated production instance watcher ensure"
            } finally {
                $env:RICE_CODEDB_UNITY_ROOT = $previousUnityRoot
                $env:RICE_CODEDB_INSTANCE_ROOT = $previousInstanceRoot
            }

            $productionStatePath = Join-Path $productionInstanceRoot "watch\coordinator\coordinator-state.json"
            Assert-True -Condition (Wait-ForWatchReady -StatePath $productionStatePath) -Message "Activated production instance watcher did not become ready."
            $productionState = Get-Content -LiteralPath $productionStatePath -Raw | ConvertFrom-Json
            $productionWatcherProcessId = [int]$productionState.coordinator_pid
            $productionWatcherLifecycleId = [string]$productionState.lifecycle_id

            $global:LASTEXITCODE = 0
            $previousErrorActionPreference = $ErrorActionPreference
            try {
                $ErrorActionPreference = "Continue"
                $stableProbeOutput = @(& $nodePath $probePath --project-root $productionInstanceProject 2>&1)
            } finally {
                $ErrorActionPreference = $previousErrorActionPreference
            }
            $stableProbeExitCode = $LASTEXITCODE
            Assert-Equal -Actual $stableProbeExitCode -Expected 0 -Message "Activated stable wrapper MCP probe failed: $($stableProbeOutput -join [Environment]::NewLine)"
            $stableProbeJson = @($stableProbeOutput | ForEach-Object { [string]$_ } | Where-Object { $_.TrimStart().StartsWith("{") })
            Assert-Equal -Actual $stableProbeJson.Count -Expected 1 -Message "Activated stable wrapper MCP probe returned an ambiguous result."
            $stableEvidence = $stableProbeJson[0] | ConvertFrom-Json
            Assert-Equal -Actual ([string]$stableEvidence.availability) -Expected "AVAILABLE" -Message "Activated stable wrapper did not resolve the selected instance."
            Assert-True -Condition ([bool]$stableEvidence.codedb_status_usable) -Message "Activated stable wrapper did not report usable codedb_status."
            Assert-True -Condition ([bool]$stableEvidence.codedb_text_search_callable) -Message "Activated stable wrapper did not complete bounded codedb_text_search."

            # Exercise the production (non-fixture) status path after a real
            # coordinator has been activated. PowerShell's automatic $PID
            # variable is read-only and case-insensitive; a local `$pid`
            # collision in coordinator evidence must not downgrade this
            # stable instance to NEEDS_ATTENTION or trigger replacement churn.
            $productionDryRun = Invoke-Materializer `
                -Action "DryRun" `
                -PayloadRoot $canonicalPayloadRoot `
                -TargetProjectRoot $productionInstanceProject `
                -OmitPocFixture
            Assert-Result -Result $productionDryRun -ExitCode 0 -Label "Production activated-instance DryRun"
            Assert-True -Condition ($productionDryRun.Text.Contains("[PRODUCT_LAYER MCP_AVAILABLE] CURRENT")) -Message "Production activated-instance DryRun lost MCP availability evidence."
            Assert-True -Condition ($productionDryRun.Text.Contains("[PRODUCT_STATE] READY")) -Message "Production activated-instance DryRun did not remain READY after coordinator validation."
        }
    } finally {
        if ($null -eq $productionInstanceRoot) {
            $selectionPath = Join-Path $productionInstanceProject "AIWork\.runtime\codedb\control\current-instance.json"
            if (Test-Path -LiteralPath $selectionPath -PathType Leaf) {
                try {
                    $selection = Get-Content -LiteralPath $selectionPath -Raw | ConvertFrom-Json
                    $productionInstanceRoot = Get-PathFromRelative -Root $productionInstanceProject -RelativePath ([string]$selection.instance_relative_path)
                } catch {
                    $productionInstanceRoot = $null
                }
            }
        }
        if ($null -ne $productionInstanceRoot) {
            $productionStatePath = Join-Path $productionInstanceRoot "watch\coordinator\coordinator-state.json"
            if (Test-Path -LiteralPath $productionStatePath -PathType Leaf) {
                try {
                    $productionState = Get-Content -LiteralPath $productionStatePath -Raw | ConvertFrom-Json
                    $productionWatcherProcessId = [int]$productionState.coordinator_pid
                    $productionWatcherLifecycleId = [string]$productionState.lifecycle_id
                } catch {
                    $productionWatcherProcessId = 0
                }
            }
        }
        if ($productionWatcherProcessId -gt 0 -and
            $null -ne (Get-Process -Id $productionWatcherProcessId -ErrorAction SilentlyContinue) -and
            $null -ne $productionInstanceRoot -and
            -not [string]::IsNullOrWhiteSpace($productionWatcherLifecycleId)) {
            if ($null -eq $productionWatcherManager) {
                $productionWatcherManager = Join-Path $productionInstanceProject "AIWork\.runtime\codedb\host\generations\$generationId\scripts\manage-codedb-project-watch.ps1"
            }
            $previousUnityRoot = $env:RICE_CODEDB_UNITY_ROOT
            $previousInstanceRoot = $env:RICE_CODEDB_INSTANCE_ROOT
            try {
                $env:RICE_CODEDB_UNITY_ROOT = [System.IO.Path]::GetFullPath($productionInstanceProject)
                $env:RICE_CODEDB_INSTANCE_ROOT = [System.IO.Path]::GetFullPath($productionInstanceRoot)
                $productionStop = Invoke-PowerShellAction -Root $productionInstanceProject -Action {
                    & $productionWatcherManager -Action Stop -ExpectedLifecycleId $productionWatcherLifecycleId
                }
                Assert-Result -Result $productionStop -ExitCode 0 -Label "Production immutable-instance watcher cleanup"
            } finally {
                $env:RICE_CODEDB_UNITY_ROOT = $previousUnityRoot
                $env:RICE_CODEDB_INSTANCE_ROOT = $previousInstanceRoot
            }
        }
        if ($null -ne $productionEditorLease) {
            Remove-Item -LiteralPath $productionEditorLease -Force -ErrorAction SilentlyContinue
        }
    }
    if (-not $productionConvergenceDeferred) {
        Write-Host "[OK] Production automatic convergence verified a candidate before atomic activation, and the stable wrapper resolved that selected immutable instance."
    }
}

function Invoke-RepairAcceptanceScenarios {
    Invoke-McpAvailabilityProbeContractScenarios

    $repairConfigPath = Join-Path $repairHostRoot ".codex\config.toml"
    $repairRuntimeRoot = Join-Path $repairHostRoot "AIWork\.runtime\codedb\payload-materializer"
    $repairBackupRoot = Join-Path $repairRuntimeRoot "mcp-config-backups"
    $repairHostRuntimeRoot = Join-Path $repairHostRoot "AIWork\.runtime\codedb\host"
    $repairMcpAvailabilityPath = Join-Path $repairRuntimeRoot "mcp-availability.json"
    $repairCurrentPointerPath = Get-PathFromRelative -Root $repairHostRoot -RelativePath $currentPointerRelativePath
    $repairLastKnownGoodPath = Get-PathFromRelative -Root $repairHostRoot -RelativePath $lastKnownGoodPointerRelativePath
    $repairGenerationRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    $targetHeader = "[mcp_servers.codedb-repair-fixture]"

    Reset-RepairFixture
    $firstAdoption = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $firstAdoption -ExitCode 0 -Label "Confirmed Repair first adoption"
    Assert-True -Condition ($firstAdoption.Text.Contains("[PHASE PREFLIGHT] OK")) -Message "Repair first adoption did not pass Package-owned preflight."
    Assert-True -Condition ($firstAdoption.Text.Contains("[RESULT] REPAIRED")) -Message "Repair first adoption did not converge."
    foreach ($expectedProductMarker in @(
        "[PRODUCT_LAYER INSTALLED] CURRENT",
        "[PRODUCT_LAYER CONFIGURED] CURRENT",
        "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT",
        "[PRODUCT_STATE] READY"
    )) {
        Assert-True -Condition ($firstAdoption.Text.Contains($expectedProductMarker)) -Message "Repair first adoption availability result is missing '$expectedProductMarker'."
    }
    Assert-True -Condition ($firstAdoption.Text.Contains("fixture-only backend evidence")) -Message "Repair fixture did not label its synthetic MCP availability evidence."
    Assert-True -Condition (-not $firstAdoption.Text.Contains("authorization")) -Message "Repair first adoption requested a version-control authorization."
    Assert-True -Condition (Test-Path -LiteralPath $repairGenerationRoot -PathType Container) -Message "Repair first adoption did not publish the immutable generation."
    Assert-True -Condition (Test-Path -LiteralPath $repairCurrentPointerPath -PathType Leaf) -Message "Repair first adoption did not publish current.json."
    Assert-True -Condition (Test-Path -LiteralPath $repairLastKnownGoodPath -PathType Leaf) -Message "Repair first adoption did not publish last-known-good.json."
    Assert-True -Condition (Test-Path -LiteralPath $repairMcpAvailabilityPath -PathType Leaf) -Message "Repair first adoption did not publish MCP availability evidence."
    $firstAvailability = Get-Content -LiteralPath $repairMcpAvailabilityPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([int]$firstAvailability.schema_version) -Expected 2 -Message "Repair first adoption availability evidence schema mismatch."
    Assert-Equal -Actual ([string]$firstAvailability.availability) -Expected "AVAILABLE" -Message "Repair first adoption availability evidence is not AVAILABLE."
    Assert-Equal -Actual ([string]$firstAvailability.project_root) -Expected ([System.IO.Path]::GetFullPath($repairHostRoot)) -Message "Repair first adoption availability evidence is not bound to the target project cwd."
    Assert-Equal `
        -Actual (@($firstAvailability.tool_names | Sort-Object) -join "|") `
        -Expected "codedb_context|codedb_find|codedb_read|codedb_search|codedb_status|codedb_text_search" `
        -Message "Repair first adoption availability evidence does not contain the complete CodeDB tool list."
    Assert-True -Condition ([bool]$firstAvailability.codedb_status_callable) -Message "Repair first adoption availability evidence did not prove codedb_status callable."
    Assert-True -Condition ([bool]$firstAvailability.codedb_status_usable) -Message "Repair first adoption availability evidence did not prove a usable project status."
    Assert-True -Condition ([bool]$firstAvailability.codedb_text_search_callable) -Message "Repair first adoption availability evidence did not prove bounded codedb_text_search callable."
    Assert-True -Condition ([string]$firstAvailability.detail -like "*bounded codedb_text_search succeeded*") -Message "Repair first adoption did not persist the usable backend result."
    $firstAdoptionSnapshot = Get-FileSnapshot -Root $repairHostRoot
    $repeatedFirstAdoption = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $repeatedFirstAdoption -ExitCode 0 -Label "Repeated first-adoption Repair"
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $firstAdoptionSnapshot -Message "Repeated first-adoption Repair was not byte-exact."

    $legacyAvailability = Get-Content -LiteralPath $repairMcpAvailabilityPath -Raw | ConvertFrom-Json
    $legacyAvailability.schema_version = 1
    Write-Utf8File -Path $repairMcpAvailabilityPath -Content (($legacyAvailability | ConvertTo-Json -Depth 8) + "`n")
    $legacyAvailabilityStatus = Invoke-Materializer `
        -Action "DryRun" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $legacyAvailabilityStatus -ExitCode 0 -Label "Legacy MCP availability evidence status"
    Assert-True -Condition (-not $legacyAvailabilityStatus.Text.Contains("[PRODUCT_STATE] READY")) -Message "Schema-1 MCP availability evidence was incorrectly retained as READY."
    $explicitAvailabilityProbe = Invoke-Materializer `
        -Action "Probe" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $explicitAvailabilityProbe -ExitCode 0 -Label "Focused Package-owned MCP availability probe"
    Assert-True -Condition ($explicitAvailabilityProbe.Text.Contains("fixture-only backend evidence")) -Message "Focused fixture probe did not label its synthetic MCP availability evidence."
    Assert-True -Condition ($explicitAvailabilityProbe.Text.Contains("[PRODUCT_STATE] READY")) -Message "Focused availability probe did not reduce verified product layers to READY."
    $upgradedAvailability = Get-Content -LiteralPath $repairMcpAvailabilityPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([int]$upgradedAvailability.schema_version) -Expected 2 -Message "Focused availability probe did not replace stale schema-1 evidence."
    Write-Host "[OK] One confirmed Repair adopted a fresh empty scope, persisted explicitly synthetic fixture evidence, rejected stale schema evidence, and repeated byte-exactly."

    $testRunnerProcess = Get-Process -Id $PID -ErrorAction Stop
    $testRunnerStart = [DateTimeOffset]::new($testRunnerProcess.StartTime.ToUniversalTime())
    foreach ($owner in @("mcp", "watcher")) {
        $absentPid = 2147483000
        Assert-True -Condition ($null -eq (Get-Process -Id $absentPid -ErrorAction SilentlyContinue)) -Message "Schema-1 absent-PID fixture unexpectedly found PID $absentPid."
        $absentLease = New-TestLegacyHostUseLease -Owner $owner -ProcessId $absentPid -CreatedAtUtc ([DateTimeOffset]::UtcNow) -Root $repairHostRoot
        $absentRepair = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $absentRepair -ExitCode 0 -Label "Schema-1 absent $owner lease Repair"
        Assert-True -Condition (-not (Test-Path -LiteralPath $absentLease)) -Message "Repair retained a proved-dead schema-1 $owner lease."
        Assert-True -Condition ($absentRepair.Text.Contains("ProcessExited")) -Message "Repair did not report the dead schema-1 $owner lease disposition."

        $reusedLease = New-TestLegacyHostUseLease -Owner $owner -ProcessId $PID -CreatedAtUtc ($testRunnerStart.AddSeconds(-5)) -Root $repairHostRoot
        $reusedRepair = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $reusedRepair -ExitCode 0 -Label "Schema-1 PID-reused $owner lease Repair"
        Assert-True -Condition (-not (Test-Path -LiteralPath $reusedLease)) -Message "Repair retained a PID-reused schema-1 $owner lease."
        Assert-True -Condition ($reusedRepair.Text.Contains("PidReused")) -Message "Repair did not report the PID-reused schema-1 $owner lease disposition."

        $liveLease = New-TestLegacyHostUseLease -Owner $owner -ProcessId $PID -CreatedAtUtc ([DateTimeOffset]::UtcNow) -Root $repairHostRoot
        $liveBefore = Get-FileSnapshot -Root $repairHostRoot
        $liveManagedBefore = Get-ManagedPayloadSnapshot -Root $repairHostRoot
        $liveLeaseBefore = Get-ByteSnapshot -Path $liveLease
        $liveConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $liveRepair = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
        Assert-True -Condition ($liveRepair.Text.Contains("[ACTIVE] $owner PID $PID")) -Message "Repair omitted the genuinely-live schema-1 $owner owner."
        if ([string]::Equals($owner, "mcp", [StringComparison]::Ordinal)) {
            Assert-Result -Result $liveRepair -ExitCode 0 -Label "Schema-1 retained live MCP Repair"
            Assert-True -Condition ($liveRepair.Text.Contains("[CLEANUP_STATE] PENDING")) -Message "Live schema-1 MCP Repair did not defer closure cleanup."
            Assert-True -Condition (-not $liveRepair.Text.Contains("[STOPPING]")) -Message "Repair attempted to Stop a live schema-1 MCP owner."
            Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $liveManagedBefore -Message "Repair changed the genuinely-live schema-1 MCP execution closure."
            Assert-Equal -Actual (Get-ByteSnapshot -Path $liveLease) -Expected $liveLeaseBefore -Message "Repair changed the genuinely-live schema-1 MCP lease."
            Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $liveConfigBefore -Message "Repair changed MCP registration while classifying a genuinely-live schema-1 MCP lease."
        } else {
            Assert-Result -Result $liveRepair -ExitCode 4 -Label "Schema-1 unauthenticated live watcher Repair refusal"
            Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $liveBefore -Message "Repair changed project bytes while classifying a genuinely-live schema-1 watcher lease."
        }
        Remove-Item -LiteralPath $liveLease -Force

        $unknownLease = New-TestLegacyHostUseLease -Owner $owner -ProcessId $PID -CreatedAtUtc ([DateTimeOffset]::UtcNow) -Root $repairHostRoot
        $unknownBefore = Get-FileSnapshot -Root $repairHostRoot
        $unknownRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -TestProcessIdentityUnavailableForPid $PID
        Assert-Result -Result $unknownRepair -ExitCode 4 -Label "Schema-1 identity-unavailable $owner lease Repair refusal"
        if ([string]::Equals($owner, "mcp", [StringComparison]::Ordinal)) {
            Assert-True `
                -Condition ($unknownRepair.Text.Contains("process start identity is unavailable")) `
                -Message "Repair did not identify the indeterminate schema-1 MCP process identity."
        } else {
            Assert-True -Condition ($unknownRepair.Text.Contains("[ACTIVE] $owner PID $PID")) -Message "Repair did not retain the identity-unavailable schema-1 $owner owner."
        }
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $unknownBefore -Message "Repair mutated the project while process identity was unavailable for schema-1 $owner."
        Remove-Item -LiteralPath $unknownLease -Force

        $invalidLease = New-TestLegacyHostUseLease -Owner $owner -ProcessId $PID -CreatedAtUtc ([DateTimeOffset]::UtcNow) -Root $repairHostRoot
        $invalidText = (Get-Content -LiteralPath $invalidLease -Raw).Replace('"schema_version":  1', '"schema_version":  2').Replace('"schema_version": 1', '"schema_version": 2')
        Write-Utf8File -Path $invalidLease -Content $invalidText
        $invalidBefore = Get-FileSnapshot -Root $repairHostRoot
        $invalidRepair = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
        Assert-True -Condition ($invalidRepair.ExitCode -ne 0) -Message "Repair accepted an invalid schema-1 $owner lease."
        Assert-True -Condition ($invalidRepair.Text.Contains("lease is invalid")) -Message "Repair did not identify the invalid schema-1 $owner lease."
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $invalidBefore -Message "Repair mutated the project before rejecting an invalid schema-1 $owner lease."
        Remove-Item -LiteralPath $invalidLease -Force
    }
    Write-Host "[OK] Schema-1 MCP and watcher leases distinguish absent, PID-reused, live, identity-unavailable, and invalid owners without inspecting process names."

    $currentFlatGatePath = Get-PathFromRelative -Root $repairHostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
    $currentFlatMcp = $null
    try {
        Remove-Item -LiteralPath $repairConfigPath -Force
        $currentFlatMcp = Start-LegacyHostUseLeaseProcess -GatePath $currentFlatGatePath -Owner "mcp" -Root $repairHostRoot
        $currentFlatMcpLeasePaths = @(Get-HostUseLeasePaths -Owner "mcp" -ProcessId $currentFlatMcp.Id -Root $repairHostRoot)
        Assert-Equal -Actual $currentFlatMcpLeasePaths.Count -Expected 1 -Message "Current-Host flat MCP fixture did not publish exactly one lease."
        $currentFlatMcpBefore = Get-ManagedPayloadSnapshot -Root $repairHostRoot
        $currentFlatMcpConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $currentFlatMcpLeaseBefore = Get-ByteSnapshot -Path $currentFlatMcpLeasePaths[0]
        $retainedCurrentFlatMcpRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $retainedCurrentFlatMcpRepair -ExitCode 0 -Label "Current Host with retained flat MCP Repair"
        Assert-True -Condition ($retainedCurrentFlatMcpRepair.Text.Contains("[ACTIVE] mcp PID $($currentFlatMcp.Id)")) -Message "Current-Host Repair omitted the retained flat MCP owner."
        Assert-True -Condition ($retainedCurrentFlatMcpRepair.Text.Contains("[CLEANUP_STATE] PENDING")) -Message "Retained flat MCP Repair did not report pending automatic cleanup."
        Assert-True -Condition ($retainedCurrentFlatMcpRepair.Text.Contains("[RESULT] REPAIRED")) -Message "Retained flat MCP Repair did not report REPAIRED."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $currentFlatMcpBefore -Message "Current-Host flat MCP Repair changed its execution closure."
        Assert-Equal -Actual $currentFlatMcpConfigBefore -Expected "missing" -Message "Current-Host flat MCP fixture unexpectedly retained its config pre-image."
        Assert-True -Condition ((Get-Content -LiteralPath $repairConfigPath -Raw).Contains($targetHeader)) -Message "Retained flat MCP Repair did not recreate registration for future sessions."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $currentFlatMcpLeasePaths[0]) -Expected $currentFlatMcpLeaseBefore -Message "Current-Host flat MCP Repair changed the live lease."
        Assert-True -Condition (-not $currentFlatMcp.HasExited) -Message "Current-Host Repair terminated the active flat MCP owner."
        Assert-True -Condition (-not $retainedCurrentFlatMcpRepair.Text.Contains("[STOPPING]")) -Message "Repair attempted to Stop the retained external MCP."
    } finally {
        if ($null -ne $currentFlatMcp) {
            Stop-LegacyHostUseLeaseProcess -Process $currentFlatMcp -Owner "mcp" -Root $repairHostRoot
        }
    }
    Write-Host "[OK] Current Host Repair retained its active flat MCP closure, repaired future registration, and reported automatic cleanup pending."

    $currentFlatWatcher = $null
    $currentFlatWatcherLease = $null
    $currentFlatWatcherStatePath = $null
    try {
        $currentFlatGatePath = Get-PathFromRelative -Root $repairHostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
        $currentFlatWatcher = Start-LegacyHostUseLeaseProcess -GatePath $currentFlatGatePath -Owner "watcher" -Root $repairHostRoot
        $currentFlatWatcherLeasePaths = @(Get-HostUseLeasePaths -Owner "watcher" -ProcessId $currentFlatWatcher.Id -Root $repairHostRoot)
        Assert-Equal -Actual $currentFlatWatcherLeasePaths.Count -Expected 1 -Message "Current-Host flat watcher fixture did not publish exactly one lease."
        $currentFlatWatcherLease = $currentFlatWatcherLeasePaths[0]
        $currentFlatProviderRoot = Join-Path $repairHostRoot "AIWork\.runtime\codedb\codedb-repair-fixture"
        $currentFlatWatcherStatePath = Join-Path $currentFlatProviderRoot "watch\coordinator\coordinator-state.json"
        $currentFlatWatcherState = [ordered]@{
            schema_version = 1
            coordinator_pid = $currentFlatWatcher.Id
            provider_pid = $currentFlatWatcher.Id
            adapter_worker_pid = $currentFlatWatcher.Id
            lifecycle_id = "current-flat-repair-fixture"
            root = [System.IO.Path]::GetFullPath($repairHostRoot).TrimEnd('\', '/')
            runtime = Split-Path -Parent $currentFlatWatcherStatePath
            pipe_name = "\\.\pipe\codedb-current-flat-repair-fixture"
            auth_token = "abcdef0123456789abcdef0123456789abcdef0123456789"
        }
        Write-Utf8File -Path $currentFlatWatcherStatePath -Content (($currentFlatWatcherState | ConvertTo-Json -Depth 5) + "`n")
        $currentFlatWatcherHostBefore = Get-ManagedPayloadSnapshot `
            -Root $repairHostRoot `
            -Paths @($managedTargets + @($markerRelativePath, $lastKnownGoodPointerRelativePath))
        $currentFlatWatcherConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $currentFlatWatcherStateBefore = Get-ByteSnapshot -Path $currentFlatWatcherStatePath
        $currentFlatWatcherLeaseBefore = Get-ByteSnapshot -Path $currentFlatWatcherLease
        $blockedCurrentFlatWatcherRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $blockedCurrentFlatWatcherRepair -ExitCode 4 -Label "Current Host with active flat watcher Repair refusal"
        Assert-True -Condition ($blockedCurrentFlatWatcherRepair.Text.Contains("[ACTIVE] watcher PID $($currentFlatWatcher.Id)")) -Message "Current-Host Repair omitted the active flat watcher owner."
        Assert-True -Condition ($blockedCurrentFlatWatcherRepair.Text.Contains("[RESULT] BLOCKED")) -Message "Current-Host flat watcher Repair did not report BLOCKED."
        Assert-Equal `
            -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot -Paths @($managedTargets + @($markerRelativePath, $lastKnownGoodPointerRelativePath))) `
            -Expected $currentFlatWatcherHostBefore `
            -Message "Current-Host flat watcher Repair changed the managed Host closure."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $currentFlatWatcherConfigBefore -Message "Current-Host flat watcher Repair changed MCP config bytes."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $currentFlatWatcherStatePath) -Expected $currentFlatWatcherStateBefore -Message "Current-Host flat watcher Repair changed coordinator state."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $currentFlatWatcherLease) -Expected $currentFlatWatcherLeaseBefore -Message "Current-Host flat watcher Repair changed the live lease."
        Assert-True -Condition (-not $currentFlatWatcher.HasExited) -Message "Current-Host Repair terminated the active flat watcher."
    } finally {
        if ($null -ne $currentFlatWatcher) {
            Stop-LegacyHostUseLeaseProcess -Process $currentFlatWatcher -Owner "watcher" -Root $repairHostRoot
        }
        if ($null -ne $currentFlatWatcherStatePath) {
            Remove-Item -LiteralPath $currentFlatWatcherStatePath -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[OK] Current Host Repair blocked and byte-exactly preserved its active flat watcher state and lease."

    $currentGenerationWatcherManager = Get-PathFromRelative `
        -Root $repairHostRoot `
        -RelativePath ($generationTargetPrefix + "scripts/manage-codedb-project-watch.ps1")
    $currentGenerationWatcherLifecycleId = $null
    $currentGenerationWatcherProcessId = 0
    $currentGenerationWatcherLease = $null
    $currentGenerationEditorLease = $null
    $currentGenerationWatcherDeferred = $false
    try {
        $currentGenerationProviderRoot = Join-Path $repairHostRoot "AIWork\.runtime\codedb\codedb-repair-fixture"
        $currentGenerationStatePath = Join-Path $currentGenerationProviderRoot "watch\coordinator\coordinator-state.json"
        $currentGenerationPrepare = Get-PathFromRelative `
            -Root $repairHostRoot `
            -RelativePath ($generationTargetPrefix + "scripts/prepare-codedb-project-runtime.ps1")
        $currentGenerationBuilder = Get-PathFromRelative `
            -Root $repairHostRoot `
            -RelativePath ($generationTargetPrefix + "scripts/build-codedb-project-text-adapter.ps1")
        $currentGenerationProviderExecutable = Join-Path $currentGenerationProviderRoot "bin\codebase-mcp.exe"
        $currentGenerationEditorLeaseRoot = Join-Path $currentGenerationProviderRoot "watch\lifecycle\editor-leases"
        New-FixtureProviderExecutable -Path $currentGenerationProviderExecutable
        Assert-Result `
            -Result (Invoke-PowerShellAction -Root $repairHostRoot -Action { & $currentGenerationPrepare }) `
            -ExitCode 0 `
            -Label "Current-generation Repair watcher runtime preparation"
        Assert-Result `
            -Result (Invoke-PowerShellAction -Root $repairHostRoot -Action { & $currentGenerationBuilder -Reason Manual }) `
            -ExitCode 0 `
            -Label "Current-generation Repair watcher adapter build"
        $currentGenerationEditorLease = New-TestEditorLease `
            -LeaseRoot $currentGenerationEditorLeaseRoot `
            -Root $repairHostRoot `
            -SessionId "repair-current-generation-editor"
        $currentGenerationStart = Invoke-PowerShellAction -Root $repairHostRoot -Action {
            & $currentGenerationWatcherManager -Action Ensure
        }
        $currentGenerationWatcherDeferred = Test-AllowedSpawnEpermDeferral -Result $currentGenerationStart
        if ($currentGenerationWatcherDeferred) {
            Write-Host "[DEFERRED] Current-generation watcher retention integration could not spawn its detached Node coordinator in the current managed test environment."
        } else {
            Assert-Result -Result $currentGenerationStart -ExitCode 0 -Label "Current-generation Repair watcher start"
            $currentGenerationStatus = Get-LastJsonObject -Result $currentGenerationStart -Label "Current-generation Repair watcher start"
            Assert-Equal -Actual $currentGenerationStatus.action -Expected "started" -Message "Current-generation Repair watcher did not start a new coordinator."
            Assert-Equal -Actual $currentGenerationStatus.generation_id -Expected $generationId -Message "Current-generation Repair watcher selected the wrong generation."
            Assert-Equal -Actual $currentGenerationStatus.provider_state -Expected "ready" -Message "Current-generation Repair watcher provider was not ready."
            Assert-Equal -Actual $currentGenerationStatus.adapter_state -Expected "watching" -Message "Current-generation Repair watcher adapter was not watching."
            $currentGenerationWatcherLifecycleId = [string]$currentGenerationStatus.lifecycle_id
            $currentGenerationWatcherProcessId = [int]$currentGenerationStatus.coordinator_pid
            $currentGenerationWatcherLeases = @(Get-GenerationLeasePaths `
                -Owner "watcher" `
                -ProcessId $currentGenerationWatcherProcessId `
                -LeaseGenerationId $generationId `
                -Root $repairHostRoot)
            Assert-Equal -Actual $currentGenerationWatcherLeases.Count -Expected 1 -Message "Current-generation Repair watcher did not publish exactly one generation lease."
            $currentGenerationWatcherLease = $currentGenerationWatcherLeases[0]
            Remove-Item -LiteralPath $repairConfigPath -Force
            $currentGenerationHostBefore = Get-FileSnapshot -Root $repairGenerationRoot
            $currentGenerationStateBefore = Get-Content -LiteralPath $currentGenerationStatePath -Raw | ConvertFrom-Json
            $currentGenerationLeaseBefore = Get-Content -LiteralPath $currentGenerationWatcherLease -Raw | ConvertFrom-Json
            $currentGenerationRepair = Invoke-Materializer `
                -Action "Repair" `
                -PayloadRoot $canonicalPayloadRoot `
                -TargetProjectRoot $repairHostRoot
            Assert-Result -Result $currentGenerationRepair -ExitCode 4 -Label "Legacy Repair with non-instance generation watcher refusal"
            Assert-True -Condition ($currentGenerationRepair.Text.Contains("[ACTIVE] unvalidated generation watcher state")) -Message "Legacy Repair did not report the non-instance watcher identity boundary."
            Assert-True -Condition ($currentGenerationRepair.Text.Contains("[RESULT] BLOCKED")) -Message "Legacy Repair did not report BLOCKED for the non-instance watcher."
            Assert-True -Condition (-not $currentGenerationRepair.Text.Contains("[STOPPING]")) -Message "Repair attempted to Stop the current-generation watcher."
            Assert-True -Condition ($null -ne (Get-Process -Id $currentGenerationWatcherProcessId -ErrorAction SilentlyContinue)) -Message "Repair terminated the current-generation watcher owner."
            Assert-Equal -Actual (Get-FileSnapshot -Root $repairGenerationRoot) -Expected $currentGenerationHostBefore -Message "Repair rewrote the active immutable generation."
            $currentGenerationStateAfter = Get-Content -LiteralPath $currentGenerationStatePath -Raw | ConvertFrom-Json
            foreach ($field in @(
                "schema_version", "generation_id", "coordinator_pid", "lifecycle_id", "exclusive_lifecycle",
                "provider_pid", "root", "runtime", "pipe_name", "auth_token", "provider_executable", "provider_config",
                "adapter_enabled", "adapter_builder", "adapter_worker", "generation_adapter_builder",
                "generation_adapter_worker", "adapter_manifest"
            )) {
                Assert-Equal `
                    -Actual $currentGenerationStateAfter.PSObject.Properties[$field].Value `
                    -Expected $currentGenerationStateBefore.PSObject.Properties[$field].Value `
                    -Message "Repair changed current-generation coordinator identity field $field."
            }
            Assert-True -Condition (Test-Path -LiteralPath $currentGenerationWatcherLease -PathType Leaf) -Message "Repair removed the current-generation watcher lease."
            $currentGenerationLeaseAfter = Get-Content -LiteralPath $currentGenerationWatcherLease -Raw | ConvertFrom-Json
            foreach ($field in @(
                "schema_version", "generation_lease_version", "managed_by", "generation_id", "lease_id", "owner",
                "pid", "process_start_identity", "project_root", "created_at_utc"
            )) {
                Assert-Equal `
                    -Actual $currentGenerationLeaseAfter.PSObject.Properties[$field].Value `
                    -Expected $currentGenerationLeaseBefore.PSObject.Properties[$field].Value `
                    -Message "Repair changed current-generation watcher lease identity field $field."
            }
            Assert-True -Condition (-not (Test-Path -LiteralPath $repairConfigPath)) -Message "Blocked legacy Repair created the missing MCP config."
        }
    } finally {
        if ($currentGenerationWatcherProcessId -gt 0 -and
            $null -ne (Get-Process -Id $currentGenerationWatcherProcessId -ErrorAction SilentlyContinue)) {
            $currentGenerationStop = Invoke-PowerShellAction -Root $repairHostRoot -Action {
                & $currentGenerationWatcherManager `
                    -Action Stop `
                    -ExpectedLifecycleId $currentGenerationWatcherLifecycleId
            }
            Assert-Result -Result $currentGenerationStop -ExitCode 0 -Label "Current-generation Repair watcher cleanup"
        }
        if ($null -ne $currentGenerationEditorLease) {
            Remove-Item -LiteralPath $currentGenerationEditorLease -Force -ErrorAction SilentlyContinue
        }
    }
    if (-not $currentGenerationWatcherDeferred) {
        Write-Host "[OK] Legacy Repair preserved and did not Stop a non-instance generation watcher, but refused all Host/MCP mutation."
    }

    Reset-RepairFixture
    $unownedCandidateRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $unownedCandidateRoot) | Out-Null
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "Generations\$generationId") -Destination $unownedCandidateRoot -Recurse
    $unownedGenerationBefore = Get-FileSnapshot -Root $unownedCandidateRoot
    $unownedBusinessBefore = Get-ByteSnapshot -Path (Join-Path $repairHostRoot "Assets\BusinessSentinel.txt")
    $unownedCandidateUpgrade = Invoke-Materializer `
        -Action "Upgrade" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $unownedCandidateUpgrade -ExitCode 0 -Label "Package-matching pre-published generation Upgrade"
    Assert-True -Condition ($unownedCandidateUpgrade.Text.Contains("[RESULT] UPGRADED")) -Message "Upgrade did not activate an isolated instance over the Package-matching generation."
    Assert-Equal -Actual (Get-FileSnapshot -Root $unownedCandidateRoot) -Expected $unownedGenerationBefore -Message "Upgrade rewrote the pre-published Package-matching generation."
    Assert-Equal -Actual (Get-ByteSnapshot -Path (Join-Path $repairHostRoot "Assets\BusinessSentinel.txt")) -Expected $unownedBusinessBefore -Message "Upgrade changed the unrelated business sentinel."

    Reset-RepairFixture
    $unownedCandidateRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $unownedCandidateRoot) | Out-Null
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "Generations\$generationId") -Destination $unownedCandidateRoot -Recurse
    $unownedCandidateBefore = Get-FileSnapshot -Root $repairHostRoot
    $unownedCandidateRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $unownedCandidateRepair -ExitCode 4 -Label "Non-empty first-adoption Repair refusal"
    Assert-True -Condition ($unownedCandidateRepair.Text.Contains("first adoption requires an empty CodeDB-managed target scope")) -Message "Repair did not report the strict empty-scope adoption boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $unownedCandidateBefore -Message "Rejected non-empty first-adoption Repair changed the fixture."
    Write-Host "[OK] Upgrade reused an exact Package generation without rewriting it; legacy Repair still blocked the same ownerless first-adoption state with byte-exact zero writes."

    Reset-RepairFixture
    Install-OwnedLegacyRedeployFixture -Root $repairHostRoot
    $legacyRepairGate = Get-PathFromRelative -Root $repairHostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
    $legacyRepairMcp = $null
    try {
        $legacyRepairMcp = Start-LegacyHostUseLeaseProcess -GatePath $legacyRepairGate -Owner "mcp" -Root $repairHostRoot
        $legacyRepairBefore = Get-FileSnapshot -Root $repairHostRoot
        $blockedLegacyRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $blockedLegacyRepair -ExitCode 4 -Label "Active flat legacy MCP Repair refusal"
        Assert-True `
            -Condition ($blockedLegacyRepair.Text.Contains("[ACTIVE] mcp PID $($legacyRepairMcp.Id)")) `
            -Message "Blocked Repair omitted the active flat legacy MCP owner.`n$($blockedLegacyRepair.Text)"
        Assert-True -Condition ($blockedLegacyRepair.Text.Contains("[RESULT] BLOCKED")) -Message "Blocked flat legacy Repair did not report BLOCKED."
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $legacyRepairBefore -Message "Blocked flat legacy Repair changed the execution closure or lease."
        Assert-True -Condition (-not $legacyRepairMcp.HasExited) -Message "Repair terminated the external flat legacy MCP owner."
    } finally {
        if ($null -ne $legacyRepairMcp) {
            Stop-LegacyHostUseLeaseProcess -Process $legacyRepairMcp -Owner "mcp" -Root $repairHostRoot
        }
    }
    Write-Host "[OK] Repair reported and preserved an active flat legacy MCP owner without replacing its execution closure."

    :legacyWatcherIntegration do {
        Reset-RepairFixture
        Install-OwnedLegacyRedeployFixture -Root $repairHostRoot
        $legacyRepairWatcher = $null
        $legacyWatcherSentinelRoot = Join-Path $runRoot "legacy-redeploy-vcs-sentinels"
        $legacyWatcherSentinelLog = Join-Path $legacyWatcherSentinelRoot "invocations.log"
        New-Item -ItemType Directory -Force -Path $legacyWatcherSentinelRoot | Out-Null
        foreach ($commandName in @("git", "svn", "p4")) {
            New-VersionControlSentinel -Directory $legacyWatcherSentinelRoot -CommandName $commandName -LogPath $legacyWatcherSentinelLog
        }
        $legacyWatcherSentinelPath = @(
            $legacyWatcherSentinelRoot,
            (Split-Path -Parent $nodePath),
            (Split-Path -Parent $powershellPath)
        ) -join [System.IO.Path]::PathSeparator
        $legacyEditorHeartbeat = $null
        try {
            try {
                $legacyRepairWatcher = Start-OwnedLegacyWatcherFixture -Root $repairHostRoot
            } catch {
                if ($_.Exception.Message.Contains("spawn EPERM") -and
                    [string]::Equals($env:RICE_CODEDB_TEST_ALLOW_SPAWN_EPERM, "1", [StringComparison]::Ordinal)) {
                    Write-Host "[DEFERRED] Authenticated legacy watcher Repair/Redeploy integration could not spawn its daemon in the current managed test environment."
                    break legacyWatcherIntegration
                }
                throw
            }
        $legacyEditorHeartbeat = Start-TestEditorLeaseHeartbeat -LeasePath $legacyRepairWatcher.EditorLeasePath
        $legacyWatcherProcessId = $legacyRepairWatcher.ProcessId
        $legacyRepairStopwatch = [Diagnostics.Stopwatch]::StartNew()
        $repairedWatcherResult = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -OmitPocFixture `
            -ConfirmedProjectMutation `
            -BoundedOutputDrain `
            -PathOverride $legacyWatcherSentinelPath
        $legacyRepairStopwatch.Stop()
        Assert-Result -Result $repairedWatcherResult -ExitCode 8 -Label "Authenticated flat legacy watcher Repair partial"
        Assert-True -Condition ($repairedWatcherResult.Text.Contains("[ACTIVE] watcher PID $legacyWatcherProcessId")) -Message "Repair omitted the authenticated flat legacy watcher owner."
        Assert-True -Condition ($repairedWatcherResult.Text.Contains("[STOPPING] Requesting authenticated Package-owned Stop for legacy watcher PID $legacyWatcherProcessId.")) -Message "Repair did not report its authenticated watcher Stop request."
        Assert-True -Condition ($repairedWatcherResult.Text.Contains("[PHASE WATCHER] BLOCKED")) -Message "Legacy Repair did not report that the restarted non-instance watcher remains outside the release validator."
        Assert-True -Condition ($repairedWatcherResult.Text.Contains("[RESULT] PARTIALLY_REPAIRED")) -Message "Authenticated watcher Repair did not report its non-release partial result."
        Assert-True -Condition ($repairedWatcherResult.Text.Contains('"cleanup_state":"PENDING"')) -Message "Authenticated watcher Repair did not report pending legacy cleanup."
        Assert-True -Condition ($null -eq (Get-Process -Id $legacyWatcherProcessId -ErrorAction SilentlyContinue)) -Message "Repair retained the replaced flat legacy watcher process."
        Assert-True `
            -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $legacyWatcherProcessId -Present $false -Root $repairHostRoot) `
            -Message "Repair retained the stopped flat legacy watcher lease."
        $heartbeatEvidence = if (Test-Path -LiteralPath $legacyEditorHeartbeat.SuccessPath -PathType Leaf) {
            Get-Content -LiteralPath $legacyEditorHeartbeat.SuccessPath -Raw
        } else {
            "missing"
        }
        Assert-True `
            -Condition (Test-Path -LiteralPath $legacyRepairWatcher.StatePath -PathType Leaf) `
            -Message "Repair did not retain restarted generation watcher state after $($legacyRepairStopwatch.ElapsedMilliseconds) ms; heartbeat evidence=$heartbeatEvidence.`n$($repairedWatcherResult.Text)"
        $restartedWatcherState = Get-Content -LiteralPath $legacyRepairWatcher.StatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual ([string]$restartedWatcherState.generation_id) -Expected $generationId -Message "Repair restarted the watcher on the wrong generation."
        Assert-True -Condition ([int]$restartedWatcherState.coordinator_pid -ne $legacyWatcherProcessId) -Message "Repair did not hand watcher ownership to a new generation process."
        Assert-True -Condition ((Get-Content -LiteralPath $repairConfigPath -Raw).Contains($targetHeader)) -Message "Authenticated watcher Repair did not verify the project MCP registration."
        Assert-True -Condition (-not (Test-Path -LiteralPath $legacyWatcherSentinelLog)) -Message "Authenticated watcher Repair invoked a git, svn, or p4 command sentinel."
        $repairedWatcherManager = Get-PathFromRelative `
            -Root $repairHostRoot `
            -RelativePath "AIWork/.runtime/codedb/host/generations/$generationId/scripts/manage-codedb-project-watch.ps1"
        $repairedWatcherStop = Invoke-PowerShellAction -Root $repairHostRoot -Action {
            & $repairedWatcherManager `
                -Action Stop `
                -ExpectedLifecycleId ([string]$restartedWatcherState.lifecycle_id)
        }
        Assert-Result -Result $repairedWatcherStop -ExitCode 0 -Label "Repaired generation watcher cleanup"

        Stop-TestEditorLeaseHeartbeat -Heartbeat $legacyEditorHeartbeat
        $legacyEditorHeartbeat = $null
        Reset-RepairFixture
        Install-OwnedLegacyRedeployFixture -Root $repairHostRoot
        $legacyRepairWatcher = Start-OwnedLegacyWatcherFixture -Root $repairHostRoot
        $legacyEditorHeartbeat = Start-TestEditorLeaseHeartbeat -LeasePath $legacyRepairWatcher.EditorLeasePath

        $unconfirmedManagedBefore = Get-ManagedPayloadSnapshot -Root $repairHostRoot
        $unconfirmedConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $unconfirmedControlPaths = @(
            (Join-Path $repairRuntimeRoot "materialize.lock"),
            (Join-Path $repairRuntimeRoot "materialize-active.json"),
            (Join-Path $repairRuntimeRoot "upgrade-state.json")
        )
        $unconfirmedControlBefore = @($unconfirmedControlPaths | ForEach-Object { Get-ByteSnapshot -Path $_ })
        $unconfirmedTransactionCount = @(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count
        $unconfirmedState = Get-Content -LiteralPath $legacyRepairWatcher.StatePath -Raw | ConvertFrom-Json
        $unconfirmedClientStopCount = @([regex]::Matches(
            $(if (Test-Path -LiteralPath (Join-Path $legacyRepairWatcher.Runtime "coordinator.log") -PathType Leaf) {
                Get-Content -LiteralPath (Join-Path $legacyRepairWatcher.Runtime "coordinator.log") -Raw
            } else {
                ""
            }),
            'coordinator_stop reason=client_stop')).Count
        $unconfirmedWatcherRedeploy = Invoke-Materializer `
            -Action "Redeploy" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -OmitPocFixture `
            -PathOverride $legacyWatcherSentinelPath
        Assert-Result -Result $unconfirmedWatcherRedeploy -ExitCode 4 -Label "Unconfirmed production active-watcher Redeploy refusal"
        Assert-True -Condition ($unconfirmedWatcherRedeploy.Text.Contains("Redeploy requires the Package Manager's second-level project mutation confirmation.")) -Message "Unconfirmed production Redeploy did not report its missing confirmation credential."
        Assert-True -Condition (-not $unconfirmedWatcherRedeploy.Text.Contains("[STOPPING]")) -Message "Unconfirmed production Redeploy reached the Package-owned Stop phase."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $unconfirmedManagedBefore -Message "Unconfirmed production Redeploy changed the managed Host closure."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $unconfirmedConfigBefore -Message "Unconfirmed production Redeploy changed MCP config bytes."
        $unconfirmedControlAfter = @($unconfirmedControlPaths | ForEach-Object { Get-ByteSnapshot -Path $_ })
        Assert-Equal -Actual ($unconfirmedControlAfter -join '|') -Expected ($unconfirmedControlBefore -join '|') -Message "Unconfirmed production Redeploy wrote materializer lock or state files."
        Assert-Equal -Actual @(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -Expected $unconfirmedTransactionCount -Message "Unconfirmed production Redeploy created a materializer transaction."
        Assert-True -Condition ($null -ne (Get-Process -Id $legacyRepairWatcher.ProcessId -ErrorAction SilentlyContinue)) -Message "Unconfirmed production Redeploy terminated the active legacy watcher."
        Assert-True -Condition (Test-Path -LiteralPath $legacyRepairWatcher.StatePath -PathType Leaf) -Message "Unconfirmed production Redeploy removed legacy coordinator state."
        $unconfirmedStateAfter = Get-Content -LiteralPath $legacyRepairWatcher.StatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual ([int]$unconfirmedStateAfter.coordinator_pid) -Expected ([int]$unconfirmedState.coordinator_pid) -Message "Unconfirmed production Redeploy changed the legacy coordinator PID."
        Assert-Equal -Actual ([string]$unconfirmedStateAfter.lifecycle_id) -Expected ([string]$unconfirmedState.lifecycle_id) -Message "Unconfirmed production Redeploy changed the legacy coordinator lifecycle."
        Assert-Equal -Actual ([string]$unconfirmedStateAfter.pipe_name) -Expected ([string]$unconfirmedState.pipe_name) -Message "Unconfirmed production Redeploy changed the legacy coordinator pipe."
        Assert-Equal -Actual ([string]$unconfirmedStateAfter.auth_token) -Expected ([string]$unconfirmedState.auth_token) -Message "Unconfirmed production Redeploy changed the legacy coordinator auth token."
        Assert-True `
            -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $legacyRepairWatcher.ProcessId -Present $true -Root $repairHostRoot) `
            -Message "Unconfirmed production Redeploy removed the live watcher lease."
        $unconfirmedClientStopCountAfter = @([regex]::Matches(
            (Get-Content -LiteralPath (Join-Path $legacyRepairWatcher.Runtime "coordinator.log") -Raw),
            'coordinator_stop reason=client_stop')).Count
        Assert-Equal -Actual $unconfirmedClientStopCountAfter -Expected $unconfirmedClientStopCount -Message "Unconfirmed production Redeploy sent a client_stop request."
        Assert-True -Condition (-not (Test-Path -LiteralPath $legacyWatcherSentinelLog)) -Message "Unconfirmed production Redeploy invoked a git, svn, or p4 command sentinel."

        $failedRedeployManagedBefore = Get-ManagedPayloadSnapshot -Root $repairHostRoot
        $failedRedeployConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $unrelatedOwner = Start-IdleOwnerProcess -Root $repairHostRoot
        try {
            $failedWatcherRedeploy = Invoke-Materializer `
                -Action "Redeploy" `
                -PayloadRoot $canonicalPayloadRoot `
                -TargetProjectRoot $repairHostRoot `
                -TestFailAfterMutation 1 `
                -PathOverride $legacyWatcherSentinelPath
            Assert-Result -Result $failedWatcherRedeploy -ExitCode 6 -Label "Post-Stop legacy Redeploy Host failure"
            Assert-True -Condition ($failedWatcherRedeploy.Text.Contains("[STOPPING] Requesting authenticated Package-owned Stop for legacy watcher PID $($legacyRepairWatcher.ProcessId).")) -Message "Injected Redeploy failure did not first authenticate and request watcher Stop."
            Assert-True -Condition ($failedWatcherRedeploy.Text.Contains("[STOPPED] Legacy watcher PID $($legacyRepairWatcher.ProcessId) released its execution closure.")) -Message "Injected Redeploy failure did not report the completed watcher Stop."
            Assert-True -Condition ($failedWatcherRedeploy.Text.Contains("[PHASE HOST_RUNTIME] PARTIAL - Host payload changes were rolled back, but the authenticated legacy watcher Stop cannot be rolled back.")) -Message "Post-Stop Redeploy failure did not distinguish Host rollback from the irreversible watcher Stop."
            Assert-True -Condition ($failedWatcherRedeploy.Text.Contains("[RESULT] PARTIALLY_REPAIRED")) -Message "Post-Stop Redeploy failure did not report PARTIALLY_REPAIRED."
            Assert-True -Condition ($failedWatcherRedeploy.Text.Contains("[NEXT] Click Repair CodeDB once to finish Host recovery; the stopped watcher will not restart automatically.")) -Message "Post-Stop Redeploy failure did not report one focused next step."
            Assert-True -Condition (-not $failedWatcherRedeploy.Text.Contains("Payload sync failed and was rolled back.")) -Message "Post-Stop Redeploy failure incorrectly claimed that every side effect was rolled back."
            Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $failedRedeployManagedBefore -Message "Post-Stop Redeploy failure did not restore the exact managed Host closure."
            Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $failedRedeployConfigBefore -Message "Post-Stop Redeploy failure changed MCP config bytes."
            Assert-True -Condition ($null -eq (Get-Process -Id $legacyRepairWatcher.ProcessId -ErrorAction SilentlyContinue)) -Message "Post-Stop Redeploy failure retained the legacy watcher process."
            Assert-True -Condition (-not (Test-Path -LiteralPath $legacyRepairWatcher.StatePath)) -Message "Post-Stop Redeploy failure restored stopped coordinator state."
            Assert-True `
                -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $legacyRepairWatcher.ProcessId -Present $false -Root $repairHostRoot) `
                -Message "Post-Stop Redeploy failure restored the stopped watcher lease."
            Assert-True -Condition (-not $unrelatedOwner.HasExited) -Message "Post-Stop Redeploy failure terminated an unrelated process."
            Assert-NoMaterializerResidue -Root $repairHostRoot
        } finally {
            Stop-IdleOwnerProcess -Process $unrelatedOwner
        }

        $legacyRepairWatcher = Start-OwnedLegacyWatcherFixture -Root $repairHostRoot
        $watcherRedeploy = Invoke-Materializer `
            -Action "Redeploy" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -OmitPocFixture `
            -ConfirmedProjectMutation `
            -PathOverride $legacyWatcherSentinelPath
        Assert-Result -Result $watcherRedeploy -ExitCode 0 -Label "Authenticated active-watcher legacy Redeploy"
        Assert-True -Condition ($watcherRedeploy.Text.Contains("[CONFIRMED] Redeploy is scoped to CodeDB-owned paths")) -Message "Confirmed production Redeploy did not report its project mutation scope."
        Assert-True -Condition ($watcherRedeploy.Text.Contains("[STOPPING] Requesting authenticated Package-owned Stop for legacy watcher PID $($legacyRepairWatcher.ProcessId).")) -Message "Redeploy did not report its Package-owned authenticated Stop request."
        Assert-True -Condition ($watcherRedeploy.Text.Contains("[STOPPED] Legacy watcher PID $($legacyRepairWatcher.ProcessId) released its execution closure.")) -Message "Redeploy did not report the released legacy watcher closure."
        Assert-True -Condition ($watcherRedeploy.Text.Contains("[OK] Host payload redeployed to version $generationId.")) -Message "Watcher Redeploy did not report completion."
        Assert-True -Condition ($null -eq (Get-Process -Id $legacyRepairWatcher.ProcessId -ErrorAction SilentlyContinue)) -Message "Redeploy retained the gracefully stopped legacy watcher process."
        Assert-True -Condition (-not (Test-Path -LiteralPath $legacyRepairWatcher.StatePath)) -Message "Redeploy retained active legacy coordinator state."
        Assert-True `
            -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $legacyRepairWatcher.ProcessId -Present $false -Root $repairHostRoot) `
            -Message "Redeploy retained the stopped legacy watcher lease."
        Assert-True -Condition (-not (Test-Path -LiteralPath $legacyWatcherSentinelLog)) -Message "Legacy watcher Redeploy invoked a git, svn, or p4 command sentinel."
        Assert-CanonicalFilesInstalled -Root $repairHostRoot
        } finally {
            if ($null -ne $legacyRepairWatcher) {
                Stop-OwnedLegacyWatcherFixture -Fixture $legacyRepairWatcher
            }
            Stop-TestEditorLeaseHeartbeat -Heartbeat $legacyEditorHeartbeat
        }
        Assert-Result `
            -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
            -ExitCode 0 `
            -Label "Authenticated watcher Redeploy cleanup"
        Write-Host "[OK] Repair and unconfirmed production Redeploy preserved the live legacy watcher; a post-Stop Host failure reported its partial side effect and rolled Host back; only confirmed Redeploy completed replacement."
    } while ($false)

    $legacyWatcherMismatchCases = @(
        [pscustomobject]@{
            Label = "missing coordinator state / lease mismatch"
            ExpectedExitCode = 4
            ExpectedText = "could not correlate the single watcher lease with exactly one authenticated coordinator state"
            Configure = { param($holder) }
        },
        [pscustomobject]@{
            Label = "coordinator PID mismatch"
            ExpectedExitCode = 4
            ExpectedText = "authenticated Stop contract is invalid"
            Configure = { param($holder) $null = Write-LegacyCoordinatorStateFixture -Root $repairHostRoot -ProcessId $PID }
        },
        [pscustomobject]@{
            Label = "coordinator project identity mismatch"
            ExpectedExitCode = 4
            ExpectedText = "authenticated Stop contract is invalid"
            Configure = { param($holder) $null = Write-LegacyCoordinatorStateFixture -Root $repairHostRoot -ProcessId $holder.Id -Overrides @{ root = [System.IO.Path]::GetFullPath($productionProjectRoot) } }
        },
        [pscustomobject]@{
            Label = "coordinator pipe mismatch"
            ExpectedExitCode = 4
            ExpectedText = "authenticated Stop contract is invalid"
            Configure = { param($holder) $null = Write-LegacyCoordinatorStateFixture -Root $repairHostRoot -ProcessId $holder.Id -Overrides @{ pipe_name = "\\.\pipe\codedb-watch-wrong-fixture" } }
        },
        [pscustomobject]@{
            Label = "coordinator auth mismatch"
            ExpectedExitCode = 4
            ExpectedText = "authenticated Stop contract is invalid"
            Configure = { param($holder) $null = Write-LegacyCoordinatorStateFixture -Root $repairHostRoot -ProcessId $holder.Id -Overrides @{ auth_token = "invalid" } }
        },
        [pscustomobject]@{
            Label = "coordinator lifecycle mismatch"
            ExpectedExitCode = 4
            ExpectedText = "authenticated Stop contract is invalid"
            Configure = { param($holder) $null = Write-LegacyCoordinatorStateFixture -Root $repairHostRoot -ProcessId $holder.Id -Overrides @{ lifecycle_id = "invalid lifecycle"; exclusive_lifecycle = $true } }
        }
    )
    foreach ($mismatchCase in $legacyWatcherMismatchCases) {
        Install-OwnedLegacyRedeployFixture -Root $repairHostRoot
        $mismatchGate = Get-PathFromRelative -Root $repairHostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
        $mismatchWatcher = $null
        $mismatchStatePath = Join-Path $repairHostRoot "AIWork\.runtime\codedb\codedb-repair-fixture\watch\coordinator\coordinator-state.json"
        Remove-Item -LiteralPath $mismatchStatePath -Force -ErrorAction SilentlyContinue
        try {
            $mismatchWatcher = Start-LegacyHostUseLeaseProcess -GatePath $mismatchGate -Owner "watcher" -Root $repairHostRoot
            & $mismatchCase.Configure $mismatchWatcher
            $mismatchBefore = Get-ManagedPayloadSnapshot -Root $repairHostRoot
            $mismatchConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
            $mismatchRedeploy = Invoke-Materializer `
                -Action "Redeploy" `
                -PayloadRoot $canonicalPayloadRoot `
                -TargetProjectRoot $repairHostRoot
            Assert-Result -Result $mismatchRedeploy -ExitCode $mismatchCase.ExpectedExitCode -Label "Legacy watcher $($mismatchCase.Label) refusal"
            Assert-True -Condition ($mismatchRedeploy.Text.Contains($mismatchCase.ExpectedText)) -Message "Legacy watcher $($mismatchCase.Label) did not report '$($mismatchCase.ExpectedText)'.`n$($mismatchRedeploy.Text)"
            Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $mismatchBefore -Message "Legacy watcher $($mismatchCase.Label) changed the Host closure."
            Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $mismatchConfigBefore -Message "Legacy watcher $($mismatchCase.Label) changed MCP config bytes."
            Assert-True -Condition (-not $mismatchWatcher.HasExited) -Message "Legacy watcher $($mismatchCase.Label) terminated the lease owner."
            Assert-True `
                -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId $mismatchWatcher.Id -Present $true -Root $repairHostRoot) `
                -Message "Legacy watcher $($mismatchCase.Label) removed the live lease."
        } finally {
            if ($null -ne $mismatchWatcher) {
                Stop-LegacyHostUseLeaseProcess -Process $mismatchWatcher -Owner "watcher" -Root $repairHostRoot
            }
            Remove-Item -LiteralPath $mismatchStatePath -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[OK] Legacy Redeploy failed closed on state, PID, pipe, auth, lifecycle, and lease mismatches without stopping an owner or changing Host/config bytes."

    :forgedWatcherIntegration do {
        Install-OwnedLegacyRedeployFixture -Root $repairHostRoot
        $forgedCommandWatcher = $null
        try {
            try {
                $forgedCommandWatcher = Start-ForgedLegacyWatcherCommandFixture -Root $repairHostRoot
            } catch {
                if ($_.Exception.Message.Contains("spawn EPERM") -and
                    [string]::Equals($env:RICE_CODEDB_TEST_ALLOW_SPAWN_EPERM, "1", [StringComparison]::Ordinal)) {
                    Write-Host "[DEFERRED] Forged-command legacy watcher integration could not spawn its preparation daemon in the current managed test environment."
                    break forgedWatcherIntegration
                }
                throw
            }
        $forgedStateBefore = Get-Content -LiteralPath $forgedCommandWatcher.StatePath -Raw | ConvertFrom-Json
        $forgedStatusBefore = Invoke-CoordinatorPipeRequest `
            -StatePath $forgedCommandWatcher.StatePath `
            -Request ([ordered]@{
                auth_token = [string]$forgedStateBefore.auth_token
                command = "status"
            })
        Assert-True -Condition ([bool]$forgedStatusBefore.ok) -Message "Forged-command watcher did not expose an authenticated live IPC status before Redeploy."
        Assert-Equal -Actual ([int]$forgedStatusBefore.status.coordinator_pid) -Expected $forgedCommandWatcher.ProcessId -Message "Forged-command watcher IPC status PID mismatch."
        $forgedLeasePaths = @(Get-HostUseLeasePaths -Owner "watcher" -ProcessId $forgedCommandWatcher.ProcessId -Root $repairHostRoot)
        Assert-Equal -Actual $forgedLeasePaths.Count -Expected 1 -Message "Forged-command watcher did not own exactly one live lease."
        $forgedLeaseBefore = Get-ByteSnapshot -Path $forgedLeasePaths[0]
        $forgedHostBefore = Get-ManagedPayloadSnapshot -Root $repairHostRoot
        $forgedConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $forgedLogPath = Join-Path $forgedCommandWatcher.Runtime "coordinator.log"
        $forgedClientStopCount = @([regex]::Matches(
            $(if (Test-Path -LiteralPath $forgedLogPath -PathType Leaf) {
                Get-Content -LiteralPath $forgedLogPath -Raw
            } else {
                ""
            }),
            'coordinator_stop reason=client_stop')).Count

        $forgedCommandRedeploy = Invoke-Materializer `
            -Action "Redeploy" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -OmitPocFixture `
            -ConfirmedProjectMutation
        Assert-Result -Result $forgedCommandRedeploy -ExitCode 4 -Label "Forged-command legacy watcher Redeploy refusal"
        Assert-True -Condition ($forgedCommandRedeploy.Text.Contains("Legacy coordinator executable or argv does not match the reviewed watcher closure.")) -Message "Forged-command Redeploy did not report the exact process-command closure mismatch.`n$($forgedCommandRedeploy.Text)"
        Assert-True -Condition (-not $forgedCommandRedeploy.Text.Contains("[STOPPING]")) -Message "Forged-command Redeploy reached the Package-owned Stop phase."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $forgedHostBefore -Message "Forged-command Redeploy changed the reviewed legacy Host closure."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $forgedConfigBefore -Message "Forged-command Redeploy changed MCP config bytes."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $forgedLeasePaths[0]) -Expected $forgedLeaseBefore -Message "Forged-command Redeploy changed or removed the live watcher lease."
        Assert-True -Condition (-not $forgedCommandWatcher.Process.HasExited) -Message "Forged-command Redeploy terminated the live coordinator process."
        Assert-True -Condition (Test-Path -LiteralPath $forgedCommandWatcher.StatePath -PathType Leaf) -Message "Forged-command Redeploy removed coordinator state."
        $forgedStateAfter = Get-Content -LiteralPath $forgedCommandWatcher.StatePath -Raw | ConvertFrom-Json
        Assert-Equal -Actual ([int]$forgedStateAfter.coordinator_pid) -Expected $forgedCommandWatcher.ProcessId -Message "Forged-command Redeploy changed coordinator state ownership."
        Assert-Equal -Actual ([string]$forgedStateAfter.lifecycle_id) -Expected $forgedCommandWatcher.LifecycleId -Message "Forged-command Redeploy changed coordinator lifecycle identity."
        $forgedClientStopCountAfter = @([regex]::Matches((Get-Content -LiteralPath $forgedLogPath -Raw), 'coordinator_stop reason=client_stop')).Count
        Assert-Equal -Actual $forgedClientStopCountAfter -Expected $forgedClientStopCount -Message "Forged-command Redeploy sent an authenticated client_stop request."
        $forgedStatusAfter = Invoke-CoordinatorPipeRequest `
            -StatePath $forgedCommandWatcher.StatePath `
            -Request ([ordered]@{
                auth_token = [string]$forgedStateAfter.auth_token
                command = "status"
            })
        Assert-True -Condition ([bool]$forgedStatusAfter.ok) -Message "Forged-command watcher IPC was no longer live after rejected Redeploy."
        Assert-Equal -Actual ([int]$forgedStatusAfter.status.coordinator_pid) -Expected $forgedCommandWatcher.ProcessId -Message "Rejected forged-command Redeploy changed the live IPC owner."
        Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $repairRuntimeRoot "materialize-active.json"))) -Message "Forged-command Redeploy left a materializer active marker."
        Assert-Equal -Actual @(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -Expected 0 -Message "Forged-command Redeploy created a Host transaction before command authentication."
        } finally {
            if ($null -ne $forgedCommandWatcher) {
                Stop-ForgedLegacyWatcherCommandFixture -Fixture $forgedCommandWatcher
            }
        }
        Write-Host "[OK] Confirmed Redeploy rejected an authenticated watcher with an unowned coordinator argv before Stop or Host/MCP publication."
    } while ($false)

    Install-CurrentTrackedAdoptionFixture
    Remove-Item -LiteralPath $repairConfigPath -Force
    $missingConfigRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $missingConfigRepair -ExitCode 0 -Label "Repair missing Host runtime and MCP config"
    foreach ($expected in @(
        "[PHASE PREFLIGHT] OK",
        "[PHASE HOST_RUNTIME] REPAIRED",
        "[PHASE WATCHER] FIXTURE",
        "[PHASE PRESERVATION] PRESERVED",
        "[PHASE MCP_REGISTRATION] REPAIRED",
        "[PHASE VERIFY] OK",
        "[RESULT] REPAIRED",
        "[NEXT] Start a new Codex session"
    )) {
        Assert-True -Condition ($missingConfigRepair.Text.Contains($expected)) -Message "Missing-config Repair omitted '$expected'."
    }
    Assert-True -Condition (-not $missingConfigRepair.Text.Contains("authorization")) -Message "Repair requested an authorization artifact."
    Assert-True -Condition (Test-Path -LiteralPath $repairGenerationRoot -PathType Container) -Message "Repair did not reconstruct the package generation."
    Assert-True -Condition (Test-Path -LiteralPath $repairCurrentPointerPath -PathType Leaf) -Message "Repair did not publish current.json."
    Assert-True -Condition (Test-Path -LiteralPath $repairLastKnownGoodPath -PathType Leaf) -Message "Repair did not publish last-known-good.json."
    $createdConfig = Get-Content -LiteralPath $repairConfigPath -Raw
    Assert-True -Condition ($createdConfig.Contains($targetHeader)) -Message "Repair did not create the project MCP target section."
    Assert-True -Condition ($createdConfig.Contains('command = "node"')) -Message "Repair MCP target command is not the reviewed wrapper command."
    Assert-True -Condition ($createdConfig.Contains('cwd = "."')) -Message "Repair MCP target does not pin the project working directory."
    Assert-True -Condition ($createdConfig.Contains('args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]')) -Message "Repair MCP target does not use the reviewed relative wrapper."
    Assert-True -Condition ($createdConfig.Contains('startup_timeout_sec = 120')) -Message "Repair MCP target does not use the bounded startup timeout."
    Assert-True -Condition (-not (Test-Path -LiteralPath $repairBackupRoot)) -Message "Creating a missing MCP config produced an unnecessary backup."
    $currentGenerationMcp = $null
    try {
        $currentGenerationGate = Join-Path $repairGenerationRoot "shared\codedb-host-use-gate.mjs"
        $currentGenerationMcp = Start-GenerationHostUseLeaseProcess `
            -GatePath $currentGenerationGate `
            -Owner "mcp" `
            -LeaseGenerationId $generationId `
            -SuppressHeartbeat `
            -Root $repairHostRoot
        $currentGenerationLeasePaths = @(Get-GenerationLeasePaths `
            -Owner "mcp" `
            -ProcessId $currentGenerationMcp.Id `
            -LeaseGenerationId $generationId `
            -Root $repairHostRoot)
        Assert-Equal -Actual $currentGenerationLeasePaths.Count -Expected 1 -Message "Current-generation MCP fixture did not publish exactly one lease."
        Remove-Item -LiteralPath $repairConfigPath -Force
        $currentGenerationMcpBefore = Get-FileSnapshot -Root $repairGenerationRoot
        $currentGenerationMcpLeaseBefore = Get-ByteSnapshot -Path $currentGenerationLeasePaths[0]
        $activeCurrentRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $activeCurrentRepair -ExitCode 0 -Label "Repair with retained current-generation MCP lease"
        Assert-True -Condition ($activeCurrentRepair.Text.Contains("[RETAINED] generation $generationId mcp PID $($currentGenerationMcp.Id)")) -Message "Repair omitted the retained current-generation MCP owner."
        Assert-True -Condition ($activeCurrentRepair.Text.Contains("[PHASE MCP_REGISTRATION] REPAIRED")) -Message "Repair did not repair registration while retaining the current-generation MCP owner."
        Assert-True -Condition ($activeCurrentRepair.Text.Contains("[RESULT] REPAIRED")) -Message "Retained current-generation MCP Repair did not report REPAIRED."
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairGenerationRoot) -Expected $currentGenerationMcpBefore -Message "Repair rewrote the retained current generation."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $currentGenerationLeasePaths[0]) -Expected $currentGenerationMcpLeaseBefore -Message "Repair changed the active current-generation MCP lease."
        Assert-True -Condition (-not $currentGenerationMcp.HasExited) -Message "Repair terminated the active current-generation MCP owner."
        Assert-True -Condition (-not $activeCurrentRepair.Text.Contains("[STOPPING]")) -Message "Repair attempted to Stop the active current-generation MCP owner."
        Assert-True -Condition ((Get-Content -LiteralPath $repairConfigPath -Raw).Contains($targetHeader)) -Message "Repair did not publish the missing registration while retaining the current-generation MCP owner."
    } finally {
        if ($null -ne $currentGenerationMcp) {
            Stop-GenerationHostUseLeaseProcess -Process $currentGenerationMcp -Owner "mcp" -LeaseGenerationId $generationId -Root $repairHostRoot
        }
    }
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Repeated Repair after retained current-generation MCP scenario"
    $missingConfigSnapshot = Get-FileSnapshot -Root $repairHostRoot
    $missingConfigRepairAgain = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $missingConfigRepairAgain -ExitCode 0 -Label "Repeated missing-config Repair"
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $missingConfigSnapshot -Message "Repeated Repair changed an already current fixture."
    Assert-True -Condition ($missingConfigRepairAgain.Text.Contains("[PHASE MCP_REGISTRATION] CURRENT")) -Message "Repeated Repair did not report the current MCP target."
    Write-Host "[OK] One Package-owned Repair reconstructed missing Host runtime and registration, then repeated byte-exactly."

    $repairRaceHostRoot = $portabilityHostRoot
    New-TestHost -Root $repairRaceHostRoot
    $repairRaceActivation = Invoke-Materializer `
        -Action "Upgrade" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairRaceHostRoot
    Assert-Result -Result $repairRaceActivation -ExitCode 0 -Label "Repair marker-race instance activation"
    Assert-True `
        -Condition (Test-Path -LiteralPath (Join-Path $repairRaceHostRoot "AIWork\.runtime\codedb\control\current-instance.json") -PathType Leaf) `
        -Message "Repair marker-race fixture did not activate an immutable instance."
    $repairRaceSelection = Get-Content -LiteralPath (Join-Path $repairRaceHostRoot "AIWork\.runtime\codedb\control\current-instance.json") -Raw | ConvertFrom-Json
    $repairRaceInstanceRoot = Get-PathFromRelative -Root $repairRaceHostRoot -RelativePath ([string]$repairRaceSelection.instance_relative_path)
    $repairRaceRuntimeRoot = Join-Path $repairRaceHostRoot "AIWork\.runtime\codedb\payload-materializer"
    $repairRaceHostRuntimeRoot = Join-Path $repairRaceHostRoot "AIWork\.runtime\codedb\host"
    $repairRaceMarkerPath = Join-Path $repairRaceRuntimeRoot "materialize-active.json"
    $repairRaceReadyName = "RiceAICodeDBRepairReady$([guid]::NewGuid().ToString('N'))"
    $repairRaceContinueName = "RiceAICodeDBRepairContinue$([guid]::NewGuid().ToString('N'))"
    $repairRaceReady = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $repairRaceReadyName)
    $repairRaceContinue = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $repairRaceContinueName)
    $repairRaceInvocation = $null
    try {
        $repairRaceInvocation = Start-RepairMarkerHandshakeInvocation `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -ReadyEventName $repairRaceReadyName `
            -ContinueEventName $repairRaceContinueName
        if (-not $repairRaceReady.WaitOne(30000)) {
            if ($repairRaceInvocation.Process.HasExited) {
                $repairRacePrematureResult = Complete-MaterializerInvocation -Invocation $repairRaceInvocation -TimeoutMilliseconds 30000
                $repairRaceInvocation = $null
                throw "Repair marker-race fixture exited before publishing its active marker.`n$($repairRacePrematureResult.Text)"
            }
            throw "Repair marker-race fixture did not publish its active marker within 30 seconds."
        }
        $repairActiveMarkerPath = Join-Path $repairRuntimeRoot "materialize-active.json"
        Assert-True -Condition (Test-Path -LiteralPath $repairActiveMarkerPath -PathType Leaf) -Message "Repair marker-race fixture did not retain its active marker at the handshake."
        $repairActiveMarker = Get-Content -LiteralPath $repairActiveMarkerPath -Raw | ConvertFrom-Json
        Assert-Equal -Actual ([string]$repairActiveMarker.action) -Expected "repair" -Message "Repair published the wrong active marker action."
        $repairRaceMarker = [ordered]@{
            schema_version = [int]$repairActiveMarker.schema_version
            host_use_gate_version = [int]$repairActiveMarker.host_use_gate_version
            managed_by = [string]$repairActiveMarker.managed_by
            pid = [int]$repairActiveMarker.pid
            process_start_ticks = $repairActiveMarker.process_start_ticks
            project_root = [System.IO.Path]::GetFullPath($repairRaceHostRoot)
            action = [string]$repairActiveMarker.action
            created_at_utc = [string]$repairActiveMarker.created_at_utc
        }
        Write-Utf8File -Path $repairRaceMarkerPath -Content (($repairRaceMarker | ConvertTo-Json -Depth 6) + "`n")
        $repairRaceLeasesBefore = Get-FileSnapshot -Root (Join-Path $repairRaceHostRuntimeRoot "leases")
        $repairRaceWrapperPath = Get-PathFromRelative -Root $repairRaceHostRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
        $repairRaceError = Invoke-WrapperToolErrorProbe `
            -WrapperPath $repairRaceWrapperPath `
            -Root $repairRaceHostRoot `
            -ToolName "codedb_status" `
            -Arguments ([ordered]@{})
        Assert-True -Condition $repairRaceError.Contains("[HOST_UPDATING]") -Message "A real wrapper request did not fail closed behind the Repair marker."
        Assert-Equal `
            -Actual (Get-FileSnapshot -Root (Join-Path $repairRaceHostRuntimeRoot "leases")) `
            -Expected $repairRaceLeasesBefore `
            -Message "A wrapper request published a generation MCP lease behind the Repair marker."
        $repairRaceInstanceLeaseRoot = Join-Path $repairRaceInstanceRoot "leases"
        $repairRaceInstanceLeaseFileCount = if (Test-Path -LiteralPath $repairRaceInstanceLeaseRoot -PathType Container) {
            @(Get-ChildItem -LiteralPath $repairRaceInstanceLeaseRoot -Force -File -Recurse).Count
        } else {
            0
        }
        Assert-Equal -Actual $repairRaceInstanceLeaseFileCount -Expected 0 -Message "A rejected wrapper request retained an instance MCP lease behind the Repair marker."
        Remove-Item -LiteralPath $repairRaceMarkerPath -Force
        $null = $repairRaceContinue.Set()
        $repairRaceResult = Complete-MaterializerInvocation -Invocation $repairRaceInvocation -TimeoutMilliseconds 30000
        $repairRaceInvocation = $null
        Assert-Result -Result $repairRaceResult -ExitCode 0 -Label "Repair marker acquisition-race completion"
        Assert-True -Condition (-not (Test-Path -LiteralPath $repairActiveMarkerPath)) -Message "Completed Repair retained its active marker."
    } finally {
        $null = $repairRaceContinue.Set()
        Remove-Item -LiteralPath $repairRaceMarkerPath -Force -ErrorAction SilentlyContinue
        if ($null -ne $repairRaceInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $repairRaceInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        $repairRaceContinue.Dispose()
        $repairRaceReady.Dispose()
    }
    Write-Host "[OK] Repair published action=repair before mutation and a real wrapper request could not acquire a generation MCP lease behind it."

    $dynamicPrior = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.29" `
        -PriorPayloadSequence 29 `
        -PriorPackageVersion "0.2.5-preview.2" `
        -UsePackageGeneration `
        -Root $repairHostRoot `
        -PointerRelativePath $lastKnownGoodPointerRelativePath `
        -PreserveManagedState `
        -SkipMarker
    $dynamicMcpReadyName = "RiceAICodeDBRepairReady$([guid]::NewGuid().ToString('N'))"
    $dynamicMcpContinueName = "RiceAICodeDBRepairContinue$([guid]::NewGuid().ToString('N'))"
    $dynamicMcpReady = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $dynamicMcpReadyName)
    $dynamicMcpContinue = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $dynamicMcpContinueName)
    $dynamicMcpInvocation = $null
    $dynamicPreviousMcp = $null
    $dynamicLeasePath = $null
    try {
        $dynamicMcpInvocation = Start-RepairMarkerHandshakeInvocation `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -ReadyEventName $dynamicMcpReadyName `
            -ContinueEventName $dynamicMcpContinueName
        Assert-True -Condition $dynamicMcpReady.WaitOne(10000) -Message "Dynamic MCP Repair fixture did not reach the marker handshake."
        # Model an acquisition that began before the Repair marker and published
        # its strict lease after the marker became visible.
        $dynamicPreviousMcp = Start-IdleOwnerProcess -Root $repairHostRoot
        $dynamicLeasePath = New-TestGenerationLease `
            -Owner "mcp" `
            -ProcessId $dynamicPreviousMcp.Id `
            -LeaseGenerationId "poc.29" `
            -Root $repairHostRoot
        $dynamicLeasePaths = @(Get-GenerationLeasePaths -Owner "mcp" -ProcessId $dynamicPreviousMcp.Id -LeaseGenerationId "poc.29" -Root $repairHostRoot)
        Assert-Equal -Actual $dynamicLeasePaths.Count -Expected 1 -Message "Dynamic previous-generation MCP did not publish one lease."
        $dynamicGenerationBefore = Get-FileSnapshot -Root $dynamicPrior.GenerationRoot
        $dynamicLeaseBefore = Get-ByteSnapshot -Path $dynamicLeasePaths[0]
        $null = $dynamicMcpContinue.Set()
        $dynamicMcpResult = Complete-MaterializerInvocation -Invocation $dynamicMcpInvocation -TimeoutMilliseconds 30000
        $dynamicMcpInvocation = $null
        Assert-Result -Result $dynamicMcpResult -ExitCode 0 -Label "Repair with a new non-conflicting MCP lease after marker handshake"
        Assert-True -Condition ($dynamicMcpResult.Text.Contains("[RESULT] REPAIRED")) -Message "A new non-conflicting generation MCP lease incorrectly blocked Repair."
        Assert-True -Condition (-not $dynamicMcpResult.Text.Contains("[STOPPING]")) -Message "Repair attempted to Stop the dynamically retained MCP owner."
        Assert-True -Condition (-not $dynamicPreviousMcp.HasExited) -Message "Repair terminated the dynamically retained MCP owner."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $dynamicLeasePaths[0]) -Expected $dynamicLeaseBefore -Message "Repair changed the dynamically acquired MCP lease."
        Assert-Equal -Actual (Get-FileSnapshot -Root $dynamicPrior.GenerationRoot) -Expected $dynamicGenerationBefore -Message "Repair changed the dynamically leased generation."
    } finally {
        $null = $dynamicMcpContinue.Set()
        if ($null -ne $dynamicMcpInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $dynamicMcpInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        if ($null -ne $dynamicPreviousMcp) {
            if ($null -ne $dynamicLeasePath -and (Test-Path -LiteralPath $dynamicLeasePath -PathType Leaf)) {
                Remove-Item -LiteralPath $dynamicLeasePath -Force
            }
            Stop-IdleOwnerProcess -Process $dynamicPreviousMcp
        }
        $dynamicMcpContinue.Dispose()
        $dynamicMcpReady.Dispose()
    }
    Write-Host "[OK] Repair tolerated a new non-conflicting immutable-generation MCP lease after its marker handshake."

    $concurrentPolicyPath = Join-Path $repairHostRuntimeRoot "update-policy.json"
    Write-Utf8File -Path $concurrentPolicyPath -Content "{`"mode`":`"disabled`",`"revision`":`"before`"}`n"
    $concurrentPolicyBytes = [System.Text.UTF8Encoding]::new($false).GetBytes("{`"mode`":`"disabled`",`"revision`":`"concurrent`"}`n")
    $policyRaceReadyName = "RiceAICodeDBRepairReady$([guid]::NewGuid().ToString('N'))"
    $policyRaceContinueName = "RiceAICodeDBRepairContinue$([guid]::NewGuid().ToString('N'))"
    $policyRaceReady = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $policyRaceReadyName)
    $policyRaceContinue = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $policyRaceContinueName)
    $policyRaceInvocation = $null
    try {
        $policyRaceInvocation = Start-RepairMarkerHandshakeInvocation `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -ReadyEventName $policyRaceReadyName `
            -ContinueEventName $policyRaceContinueName
        Assert-True -Condition $policyRaceReady.WaitOne(10000) -Message "Concurrent-policy Repair fixture did not reach the marker handshake."
        [System.IO.File]::WriteAllBytes($concurrentPolicyPath, $concurrentPolicyBytes)
        $concurrentPolicySnapshot = Get-ByteSnapshot -Path $concurrentPolicyPath
        $null = $policyRaceContinue.Set()
        $policyRaceResult = Complete-MaterializerInvocation -Invocation $policyRaceInvocation -TimeoutMilliseconds 30000
        $policyRaceInvocation = $null
        Assert-Result -Result $policyRaceResult -ExitCode 8 -Label "Concurrent policy update during Repair"
        Assert-True -Condition ($policyRaceResult.Text.Contains("[PHASE PRESERVATION] BLOCKED")) -Message "Concurrent policy update did not report the preservation phase."
        Assert-True -Condition ($policyRaceResult.Text.Contains("[RESULT] PARTIALLY_REPAIRED")) -Message "Concurrent policy update did not report PARTIALLY_REPAIRED."
        Assert-True -Condition ($policyRaceResult.Text.Contains("[NEXT] Resolve the reported preserved-runtime boundary, then click Repair CodeDB again.")) -Message "Concurrent policy update did not report one focused next step."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $concurrentPolicyPath) -Expected $concurrentPolicySnapshot -Message "Repair overwrote a concurrent user policy update."
    } finally {
        $null = $policyRaceContinue.Set()
        if ($null -ne $policyRaceInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $policyRaceInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        $policyRaceContinue.Dispose()
        $policyRaceReady.Dispose()
    }
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Repair retry after concurrent policy update"
    Assert-Equal -Actual (Get-ByteSnapshot -Path $concurrentPolicyPath) -Expected $concurrentPolicySnapshot -Message "Repair retry changed the retained concurrent policy bytes."
    Write-Host "[OK] Repair preserved a concurrent user policy update, reported one partial result, and converged on one retry without restoring stale bytes."

    Install-CurrentTrackedAdoptionFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Newer current Remove-boundary setup"
    $newerCurrent = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.35-review" `
        -PriorPayloadSequence 35 `
        -PriorPackageVersion "0.2.5-preview.6" `
        -Root $repairHostRoot `
        -PreserveManagedState `
        -SkipMarker
    $newerCurrentBefore = Get-FileSnapshot -Root $repairHostRoot
    $newerCurrentRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $newerCurrentRemove -ExitCode 3 -Label "Newer current.json Remove refusal"
    Assert-True -Condition ($newerCurrentRemove.Text.Contains("current.json selects newer generation poc.35-review")) -Message "Remove did not report the newer current.json boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $newerCurrentBefore -Message "Older Remove changed a newer current generation or another project byte."
    Assert-True -Condition (Test-Path -LiteralPath $newerCurrent.GenerationRoot -PathType Container) -Message "Older Remove deleted the newer current generation."

    Install-CurrentTrackedAdoptionFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Newer LKG Remove-boundary setup"
    $newerLkg = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.35-review" `
        -PriorPayloadSequence 35 `
        -PriorPackageVersion "0.2.5-preview.6" `
        -Root $repairHostRoot `
        -PointerRelativePath $lastKnownGoodPointerRelativePath `
        -PreserveManagedState `
        -SkipMarker
    $newerLkgBefore = Get-FileSnapshot -Root $repairHostRoot
    $newerLkgRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $newerLkgRemove -ExitCode 3 -Label "Newer last-known-good Remove refusal"
    Assert-True -Condition ($newerLkgRemove.Text.Contains("last-known-good.json selects newer generation poc.35-review")) -Message "Remove did not report the newer last-known-good boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $newerLkgBefore -Message "Older Remove changed a newer rollback generation or another project byte."
    Assert-True -Condition (Test-Path -LiteralPath $newerLkg.GenerationRoot -PathType Container) -Message "Older Remove deleted the newer rollback generation."

    Install-CurrentTrackedAdoptionFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Current identity-collision Remove-boundary setup"
    $collidingCurrent = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.34-collision" `
        -PriorPayloadSequence 34 `
        -PriorPackageVersion "0.2.5-preview.5-collision" `
        -Root $repairHostRoot `
        -PreserveManagedState `
        -SkipMarker
    $collidingCurrentBefore = Get-FileSnapshot -Root $repairHostRoot
    $collidingCurrentRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $collidingCurrentRemove -ExitCode 3 -Label "Current identity-collision Remove refusal"
    Assert-True -Condition ($collidingCurrentRemove.Text.Contains("SequenceCollision: current.json selects a different generation identity at sequence 34")) -Message "Remove did not report the current.json identity collision."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $collidingCurrentBefore -Message "Remove changed a same-sequence current identity collision or another project byte."
    Assert-True -Condition (Test-Path -LiteralPath $collidingCurrent.GenerationRoot -PathType Container) -Message "Remove deleted the same-sequence current identity collision."

    Install-CurrentTrackedAdoptionFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "LKG identity-collision Remove-boundary setup"
    $collidingLkg = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.34-collision" `
        -PriorPayloadSequence 34 `
        -PriorPackageVersion "0.2.5-preview.5-collision" `
        -Root $repairHostRoot `
        -PointerRelativePath $lastKnownGoodPointerRelativePath `
        -PreserveManagedState `
        -SkipMarker
    $collidingLkgBefore = Get-FileSnapshot -Root $repairHostRoot
    $collidingLkgRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $collidingLkgRemove -ExitCode 3 -Label "LKG identity-collision Remove refusal"
    Assert-True -Condition ($collidingLkgRemove.Text.Contains("SequenceCollision: last-known-good.json selects a different generation identity at sequence 34")) -Message "Remove did not report the last-known-good identity collision."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $collidingLkgBefore -Message "Remove changed a same-sequence rollback identity collision or another project byte."
    Assert-True -Condition (Test-Path -LiteralPath $collidingLkg.GenerationRoot -PathType Container) -Message "Remove deleted the same-sequence rollback identity collision."
    Write-Host "[OK] Marker, current.json, and last-known-good.json enforce independent Remove version and identity upper bounds."

    $newerRemovalPayloadRoot = New-CanonicalIdentityPayload `
        -Root (Join-Path $syntheticRoot "remove-newer") `
        -PackageVersion "0.2.5-preview.6" `
        -PayloadVersion "poc.35-review" `
        -PayloadSequence 35
    Reset-RepairFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $newerRemovalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Newer Remove journal setup"
    $newerRemovalCrash = Invoke-Materializer `
        -Action "Remove" `
        -PayloadRoot $newerRemovalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestCrashAfterRemovalMarkerDeletion
    Assert-Result -Result $newerRemovalCrash -ExitCode 87 -Label "Newer Remove crash after marker deletion"
    Assert-True -Condition ($newerRemovalCrash.Text.Contains("Injected POC process crash after Remove deleted the ownership marker.")) -Message "Newer Remove crash did not reach the marker-deletion boundary."
    $repairRuntimeRelativePath = "AIWork/.runtime/codedb/payload-materializer"
    $repairRuntimeRoot = Get-PathFromRelative -Root $repairHostRoot -RelativePath $repairRuntimeRelativePath
    $newerRemovalTransactions = @(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $newerRemovalTransactions.Count -Expected 1 -Message "Newer crashed Remove did not retain one journal."
    $newerJournalPath = Join-Path $newerRemovalTransactions[0].FullName "transaction.json"
    $newerJournal = Get-Content -LiteralPath $newerJournalPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $newerJournal.schema_version -Expected 2 -Message "Newer Remove journal did not record schema 2 provenance."
    Assert-Equal -Actual $newerJournal.payload_sequence -Expected 35 -Message "Newer Remove journal payload sequence mismatch."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $repairHostRoot -RelativePath $markerRelativePath))) -Message "Newer Remove crash occurred before marker deletion."
    $newerJournalBefore = Get-FileSnapshot -Root $repairHostRoot
    $olderAgainstNewerJournal = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $olderAgainstNewerJournal -ExitCode 3 -Label "Older Remove against newer journal"
    Assert-True -Condition ($olderAgainstNewerJournal.Text.Contains("pending transaction $($newerRemovalTransactions[0].Name) belongs to newer generation")) -Message "Older Remove did not report the newer pending journal identity."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $newerJournalBefore -Message "Older Remove changed bytes or control state before rejecting a newer journal."

    $newerJournal.package_version = "0.2.5-preview.5-collision"
    $newerJournal.payload_version = "poc.34-collision"
    $newerJournal.payload_sequence = 34
    $newerJournal.payload_content_sha256 = "1" * 64
    Write-Utf8File -Path $newerJournalPath -Content (($newerJournal | ConvertTo-Json -Depth 8) + "`n")
    $collisionJournalBefore = Get-FileSnapshot -Root $repairHostRoot
    $collisionJournalRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $collisionJournalRemove -ExitCode 3 -Label "Remove against same-sequence journal collision"
    Assert-True -Condition ($collisionJournalRemove.Text.Contains("SequenceCollision: pending transaction")) -Message "Remove did not report the same-sequence pending journal collision."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $collisionJournalBefore -Message "Remove changed bytes or control state before rejecting a same-sequence journal collision."

    $schemaOneJournal = Get-Content -LiteralPath $newerJournalPath -Raw | ConvertFrom-Json
    $schemaOneJournal.schema_version = 1
    foreach ($propertyName in @(
        "package_version",
        "payload_version",
        "payload_sequence",
        "payload_content_sha256",
        "generation_id",
        "bootstrap_protocol",
        "generation_manifest_sha256"
    )) {
        $schemaOneJournal.PSObject.Properties.Remove($propertyName)
    }
    Write-Utf8File -Path $newerJournalPath -Content (($schemaOneJournal | ConvertTo-Json -Depth 8) + "`n")
    $schemaOneJournalBefore = Get-FileSnapshot -Root $repairHostRoot
    $schemaOneJournalRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $schemaOneJournalRemove -ExitCode 3 -Label "Remove against schema-1 journal"
    Assert-True -Condition ($schemaOneJournalRemove.Text.Contains("has no package/generation provenance")) -Message "Remove did not fail closed on a schema-1 journal without provenance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $schemaOneJournalBefore -Message "Remove changed bytes or control state before rejecting a schema-1 journal."

    Reset-RepairFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Remove lock-race current setup"
    $readyEventName = "RiceAICodeDBRemoveReady$([guid]::NewGuid().ToString('N'))"
    $continueEventName = "RiceAICodeDBRemoveContinue$([guid]::NewGuid().ToString('N'))"
    $lockPath = Join-Path $repairRuntimeRoot "materialize.lock"
    $lockRelativePath = "$repairRuntimeRelativePath/materialize.lock"
    Write-Utf8File -Path $lockPath -Content "remove lock-race sentinel`n"
    $lockBefore = Get-ByteSnapshot -Path $lockPath
    $readyEvent = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $readyEventName)
    $continueEvent = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $continueEventName)
    $lockRaceInvocation = $null
    try {
        $lockRaceInvocation = Start-RemoveLockHandshakeInvocation `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot `
            -ReadyEventName $readyEventName `
            -ContinueEventName $continueEventName
        Assert-True -Condition $readyEvent.WaitOne(10000) -Message "Remove lock-race fixture did not acquire its lock."
        $newerRacePointer = Install-PriorGenerationFixture `
            -PriorGenerationId "poc.35-lock-race" `
            -PriorPayloadSequence 35 `
            -PriorPackageVersion "0.2.5-preview.6" `
            -Root $repairHostRoot `
            -PreserveManagedState `
            -SkipMarker
        $lockRaceBefore = Get-FileSnapshotExcept -Root $repairHostRoot -ExcludedRelativePaths @($lockRelativePath)
        $null = $continueEvent.Set()
        $lockRaceRemove = Complete-MaterializerInvocation -Invocation $lockRaceInvocation
        $lockRaceInvocation = $null
        Assert-Result -Result $lockRaceRemove -ExitCode 3 -Label "Remove lock-race newer pointer refusal"
        Assert-True -Condition ($lockRaceRemove.Text.Contains("current.json selects newer generation poc.35-lock-race")) -Message "Lock-race Remove did not report the concurrently inserted newer pointer."
        Assert-Equal `
            -Actual (Get-FileSnapshotExcept -Root $repairHostRoot -ExcludedRelativePaths @($lockRelativePath)) `
            -Expected $lockRaceBefore `
            -Message "Lock-race Remove changed Host, recovery, lease, or diagnostic bytes before rejecting the newer pointer."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $lockPath) -Expected $lockBefore -Message "Lock-race Remove changed or removed the pre-existing materializer lock sentinel."
        Assert-True -Condition (Test-Path -LiteralPath $newerRacePointer.GenerationRoot -PathType Container) -Message "Lock-race Remove deleted the concurrently inserted newer generation."
    } finally {
        if ($null -ne $lockRaceInvocation) {
            $null = $continueEvent.Set()
            if (-not $lockRaceInvocation.Process.HasExited) {
                $lockRaceInvocation.Process.Kill()
                $lockRaceInvocation.Process.WaitForExit()
            }
            $lockRaceInvocation.Process.Dispose()
        }
        $continueEvent.Dispose()
        $readyEvent.Dispose()
    }
    Remove-Item -LiteralPath $lockPath -Force
    Write-Host "[OK] Remove rejected newer, colliding, legacy, and concurrently inserted identities before recovery or control-state writes."

    Install-CurrentTrackedAdoptionFixture
    $multiServerBody = @(
        "# global comment",
        'approval_policy = "never"',
        "",
        "[mcp_servers.alpha] # alpha stays first",
        'command = "alpha.exe"',
        'args = ["--alpha"]',
        "custom = { enabled = true }",
        "",
        "[mcp_servers.beta]",
        'command = "beta.exe"',
        "startup_timeout_sec = 45",
        "",
        "[[profiles]]",
        'name = "one"',
        "",
        "[[profiles]]",
        'name = "two"',
        ""
    ) -join "`r`n"
    $multiServerUtf8 = [System.Text.UTF8Encoding]::new($false).GetBytes($multiServerBody)
    $multiServerBytes = New-Object byte[] (3 + $multiServerUtf8.Length)
    $multiServerBytes[0] = 0xEF
    $multiServerBytes[1] = 0xBB
    $multiServerBytes[2] = 0xBF
    [Array]::Copy($multiServerUtf8, 0, $multiServerBytes, 3, $multiServerUtf8.Length)
    [System.IO.File]::WriteAllBytes($repairConfigPath, $multiServerBytes)
    $multiServerOriginalHash = (Get-FileHash -LiteralPath $repairConfigPath -Algorithm SHA256).Hash
    $multiServerRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $multiServerRepair -ExitCode 0 -Label "Repair unrelated multi-server config"
    $mergedBytes = [System.IO.File]::ReadAllBytes($repairConfigPath)
    Assert-True -Condition ($mergedBytes[0] -eq 0xEF -and $mergedBytes[1] -eq 0xBB -and $mergedBytes[2] -eq 0xBF) -Message "Repair did not preserve the UTF-8 BOM."
    $mergedText = [System.Text.UTF8Encoding]::new($false, $true).GetString($mergedBytes, 3, $mergedBytes.Length - 3)
    Assert-True -Condition ($mergedText.StartsWith($multiServerBody + "`r`n", [StringComparison]::Ordinal)) -Message "Repair changed unrelated MCP content or ordering while appending its target."
    Assert-True -Condition ($mergedText.Contains("`r`n$targetHeader`r`n")) -Message "Repair did not preserve CRLF while appending the target section."
    Assert-True -Condition (-not $mergedText.Replace("`r`n", "").Contains("`n")) -Message "Repair introduced mixed line endings."
    Assert-Equal -Actual ([regex]::Matches($mergedText, '(?m)^\[mcp_servers\.codedb-repair-fixture\]\s*$').Count) -Expected 1 -Message "Repair did not create exactly one target table."
    $multiServerBackups = @(Get-ChildItem -LiteralPath $repairBackupRoot -Force -File)
    Assert-Equal -Actual $multiServerBackups.Count -Expected 1 -Message "Repair did not publish exactly one recoverable MCP backup."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $multiServerBackups[0].FullName -Algorithm SHA256).Hash -Expected $multiServerOriginalHash -Message "Repair MCP backup is not byte-exact to the original."
    $multiServerSnapshot = Get-FileSnapshot -Root $repairHostRoot
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Idempotent multi-server Repair"
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $multiServerSnapshot -Message "Repeated multi-server Repair changed config or created another backup."
    Write-Host "[OK] Repair preserved BOM, CRLF, comments, ordering, unrelated servers, legal repeated array tables, and a byte-exact backup."

    Install-CurrentTrackedAdoptionFixture
    $staleTargetConfig = @"
# leading comment
[mcp_servers.codedb-repair-fixture] # target header comment
custom_key = "keep-me"
command   = "old-node" # command comment
startup_timeout_sec = 5 # timeout comment
# target trailing comment

[mcp_servers.omega]
command = "omega.exe"
unknown = 77
"@
    Write-Utf8File -Path $repairConfigPath -Content $staleTargetConfig
    $staleTargetOriginalHash = (Get-FileHash -LiteralPath $repairConfigPath -Algorithm SHA256).Hash
    $staleTargetRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $staleTargetRepair -ExitCode 0 -Label "Repair stale target section"
    $repairedTargetConfig = Get-Content -LiteralPath $repairConfigPath -Raw
    foreach ($preserved in @(
        "# leading comment",
        "$targetHeader # target header comment",
        'custom_key = "keep-me"',
        '# command comment',
        '# timeout comment',
        "# target trailing comment",
        "[mcp_servers.omega]",
        'command = "omega.exe"',
        "unknown = 77"
    )) {
        Assert-True -Condition ($repairedTargetConfig.Contains($preserved)) -Message "Target-section Repair did not preserve '$preserved'."
    }
    Assert-True -Condition ($repairedTargetConfig.Contains('command   = "node" # command comment')) -Message "Repair did not update the stale command while preserving formatting and comment."
    Assert-True -Condition ($repairedTargetConfig.Contains('startup_timeout_sec = 120 # timeout comment')) -Message "Repair did not update the stale timeout while preserving its comment."
    Assert-True -Condition ($repairedTargetConfig.Contains('cwd = "."')) -Message "Repair did not insert missing cwd."
    Assert-True -Condition ($repairedTargetConfig.Contains('args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]')) -Message "Repair did not insert missing wrapper args."
    Assert-True -Condition ($repairedTargetConfig.IndexOf('custom_key = "keep-me"', [StringComparison]::Ordinal) -lt $repairedTargetConfig.IndexOf('command   = "node"', [StringComparison]::Ordinal)) -Message "Repair changed existing target-key ordering."
    $staleTargetBackups = @(Get-ChildItem -LiteralPath $repairBackupRoot -Force -File)
    Assert-Equal -Actual $staleTargetBackups.Count -Expected 1 -Message "Stale target Repair did not create exactly one backup."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $staleTargetBackups[0].FullName -Algorithm SHA256).Hash -Expected $staleTargetOriginalHash -Message "Stale target backup is not byte-exact."

    Install-CurrentTrackedAdoptionFixture
    $currentTargetConfig = @"
# unrelated prefix
[mcp_servers.codedb-repair-fixture]
command = "node"
cwd = "."
args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]
startup_timeout_sec = 120

[mcp_servers.keep]
command = "keep.exe"
"@
    Write-Utf8File -Path $repairConfigPath -Content $currentTargetConfig
    $currentTargetBefore = Get-ByteSnapshot -Path $repairConfigPath
    $currentTargetRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $currentTargetRepair -ExitCode 0 -Label "Repair current target section"
    Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $currentTargetBefore -Message "Repair rewrote a current MCP target section."
    Assert-True -Condition ($currentTargetRepair.Text.Contains("[PHASE MCP_REGISTRATION] CURRENT")) -Message "Current MCP target was not reported as CURRENT."
    Assert-True -Condition (-not (Test-Path -LiteralPath $repairBackupRoot)) -Message "Current MCP target produced an unnecessary backup."
    Write-Host "[OK] Repair updated only stale target keys and left a current target byte-exact."

    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "[mcp_servers.alpha]`ncommand = unquoted-command`n" `
        -ExpectedText "unsupported or invalid bare TOML value" `
        -Label "Invalid TOML Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "$targetHeader`ncommand = `"node`"`n`n$targetHeader`ncommand = `"node`"`n" `
        -ExpectedText "duplicate table" `
        -Label "Duplicate target table Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent 'mcp_servers.codedb-repair-fixture = "occupied"' `
        -ExpectedText "ambiguous dotted-key collision" `
        -Label "Ambiguous dotted target Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "[mcp_servers.codedb-repair-fixture.command]`nformat = `"table`"`n" `
        -ExpectedText "table namespace collision with managed key" `
        -Label "Managed target key table Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "[[$($targetHeader.Trim('[', ']'))]]`ncommand = `"node`"`n" `
        -ExpectedText "ambiguous target array table" `
        -Label "Ambiguous target array Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "x = { a = 1, a = 2 }`n" `
        -ExpectedText "duplicate inline-table key" `
        -Label "Duplicate inline-table key Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "x = { a = 1, a.b = 2 }`n" `
        -ExpectedText "inline-table namespace collision" `
        -Label "Inline-table namespace collision Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "[a.b]`nx = 1`n[[a]]`ny = 2`n" `
        -ExpectedText "converts an implicit table into an array table" `
        -Label "Implicit-table array conversion Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "[[a]]`nb = 1`n[a.b]`nc = 2`n" `
        -ExpectedText "nested table below an array table" `
        -Label "Array-table child namespace Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent ("x = `"before" + [char]0x7f + "after`"`n") `
        -ExpectedText "unsupported control character" `
        -Label "DEL control-character Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent ("x" + [char]0x00a0 + "=" + [char]0x00a0 + "1`n") `
        -ExpectedText "unsupported Unicode whitespace" `
        -Label "NBSP whitespace Repair refusal"
    foreach ($uppercaseShortEscape in @('B', 'T', 'N', 'F', 'R')) {
        Assert-RepairBlockedWithoutWrites `
            -ConfigContent ('x = "\' + $uppercaseShortEscape + '"' + "`n") `
            -ExpectedText "unsupported TOML escape" `
            -Label "Uppercase \\$uppercaseShortEscape short-escape Repair refusal"
    }

    Install-CurrentTrackedAdoptionFixture
    $integerBoundaryConfig = @"
x_decimal_max = 9223372036854775807
x_decimal_min = -9223372036854775808
x_hex_max = 0x7fff_ffff_ffff_ffff
x_octal_max = 0o777_777_777_777_777_777_777
x_binary_max = 0b111111111111111111111111111111111111111111111111111111111111111
"@
    Write-Utf8File -Path $repairConfigPath -Content $integerBoundaryConfig
    $integerBoundaryRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $integerBoundaryRepair -ExitCode 0 -Label "Signed Int64 TOML boundary Repair"
    $integerBoundaryAfter = Get-Content -LiteralPath $repairConfigPath -Raw
    foreach ($preservedInteger in @(
        'x_decimal_max = 9223372036854775807',
        'x_decimal_min = -9223372036854775808',
        'x_hex_max = 0x7fff_ffff_ffff_ffff',
        'x_octal_max = 0o777_777_777_777_777_777_777',
        'x_binary_max = 0b111111111111111111111111111111111111111111111111111111111111111'
    )) {
        Assert-True -Condition ($integerBoundaryAfter.Contains($preservedInteger)) -Message "Repair did not preserve valid TOML integer boundary '$preservedInteger'."
    }
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "x = 9223372036854775808`n" `
        -ExpectedText "outside the signed 64-bit range" `
        -Label "Positive decimal Int64 overflow Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "x = -9223372036854775809`n" `
        -ExpectedText "outside the signed 64-bit range" `
        -Label "Negative decimal Int64 overflow Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "x = 0x8000000000000000`n" `
        -ExpectedText "outside the signed 64-bit range" `
        -Label "Hexadecimal Int64 overflow Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent "x = 0o1000000000000000000000`n" `
        -ExpectedText "outside the signed 64-bit range" `
        -Label "Octal Int64 overflow Repair refusal"
    Assert-RepairBlockedWithoutWrites `
        -ConfigContent ("x = 0b1" + ('0' * 63) + "`n") `
        -ExpectedText "outside the signed 64-bit range" `
        -Label "Binary Int64 overflow Repair refusal"

    Install-CurrentTrackedAdoptionFixture
    $outsideConfigRoot = Join-Path $runRoot ("repair-config-outside-" + [guid]::NewGuid().ToString("N"))
    $repairCodexDirectory = Join-Path $repairHostRoot ".codex"
    Remove-Item -LiteralPath $repairCodexDirectory -Recurse -Force
    New-Item -ItemType Directory -Force -Path $outsideConfigRoot | Out-Null
    Write-Utf8File -Path (Join-Path $outsideConfigRoot "config.toml") -Content "[mcp_servers.outside]`ncommand = `"outside.exe`"`n"
    $outsideConfigBefore = Get-ByteSnapshot -Path (Join-Path $outsideConfigRoot "config.toml")
    $managedBeforeConfigEscape = Get-ManagedPayloadSnapshot -Root $repairHostRoot
    try {
        New-Item -ItemType Junction -Path $repairCodexDirectory -Target $outsideConfigRoot | Out-Null
        $configEscape = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-True -Condition ($configEscape.ExitCode -ne 0) -Message "Repair accepted a project MCP config through a reparse-point escape."
        Assert-True -Condition ($configEscape.Text.Contains("traverses a reparse point")) -Message "Repair did not report the project MCP config reparse boundary."
        Assert-True -Condition ($configEscape.Text.Contains("[RESULT] BLOCKED")) -Message "Config path escape did not report BLOCKED."
        Assert-Equal -Actual (Get-ByteSnapshot -Path (Join-Path $outsideConfigRoot "config.toml")) -Expected $outsideConfigBefore -Message "Repair changed the escaped MCP config target."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $repairHostRoot) -Expected $managedBeforeConfigEscape -Message "Config path escape changed managed Host state."
    } finally {
        if (Test-Path -LiteralPath $repairCodexDirectory) {
            $codexItem = Get-Item -LiteralPath $repairCodexDirectory -Force
            if (($codexItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                [System.IO.Directory]::Delete($repairCodexDirectory)
            }
        }
        Remove-Item -LiteralPath $outsideConfigRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Invalid, duplicate, ambiguous, and escaped MCP configs failed closed without writes."

    Reset-RepairFixture
    $prior = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.29" `
        -PriorPayloadSequence 29 `
        -PriorPackageVersion "0.2.5-preview.2" `
        -UsePackageGeneration `
        -Root $repairHostRoot
    $providerRoot = Join-Path $repairHostRoot "AIWork\.runtime\codedb\codedb-repair-fixture"
    $preservedFiles = @(
        "bin/codebase-mcp.exe",
        "config/codedb-mcp.toml",
        "index/provider.db",
        "adapter/text-index/manifest.json",
        "adapter/text-index/files.jsonl",
        "adapter/text-index/index.jsonl",
        "watch/lifecycle/desired-state.json",
        "watch/lifecycle/manual-runtime.json",
        "watch/auto-start.json",
        "watch/automatic-refresh-paused.json"
    )
    foreach ($relativePath in $preservedFiles) {
        Write-Utf8File `
            -Path (Get-PathFromRelative -Root $providerRoot -RelativePath $relativePath) `
            -Content "custom preserved $relativePath`n"
    }
    $updatePolicyPath = Join-Path $repairHostRuntimeRoot "update-policy.json"
    Write-Utf8File -Path $updatePolicyPath -Content '{"mode":"disabled","custom":true}'
    $unrelatedGenerationRoot = Join-Path $repairHostRuntimeRoot "generations\poc.business-retained"
    Write-Utf8File -Path (Join-Path $unrelatedGenerationRoot "business.bin") -Content "unrelated generation sentinel`n"
    $previousGenerationBefore = Get-FileSnapshot -Root $prior.GenerationRoot
    $providerBefore = Get-FileSnapshot -Root $providerRoot
    $unrelatedGenerationBefore = Get-FileSnapshot -Root $unrelatedGenerationRoot
    $updatePolicyBefore = Get-ByteSnapshot -Path $updatePolicyPath
    $businessSentinelPath = Join-Path $repairHostRoot "Assets\BusinessSentinel.txt"
    $businessText = Get-Content -LiteralPath $businessSentinelPath -Raw
    $businessGitPath = Get-ProjectGitPath -Path $businessSentinelPath
    $null = Invoke-FixtureIndexGit -Arguments @("read-tree", "--empty")
    Write-Utf8File -Path $businessSentinelPath -Content "staged business variant`n"
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $businessGitPath)
    Write-Utf8File -Path $businessSentinelPath -Content $businessText
    $businessBefore = Get-ByteSnapshot -Path $businessSentinelPath
    $indexBefore = (@(Invoke-FixtureIndexGit -Arguments @("diff", "--cached", "--name-only")) -join "`n")
    $previousGenerationMcp = $null
    try {
        $previousGenerationGate = Join-Path $prior.GenerationRoot "shared\codedb-host-use-gate.mjs"
        $previousGenerationMcp = Start-GenerationHostUseLeaseProcess `
            -GatePath $previousGenerationGate `
            -Owner "mcp" `
            -LeaseGenerationId "poc.29" `
            -SuppressHeartbeat `
            -Root $repairHostRoot
        $previousLeasePaths = @(Get-GenerationLeasePaths `
            -Owner "mcp" `
            -ProcessId $previousGenerationMcp.Id `
            -LeaseGenerationId "poc.29" `
            -Root $repairHostRoot)
        Assert-Equal -Actual $previousLeasePaths.Count -Expected 1 -Message "Previous-generation MCP fixture did not publish exactly one lease."
        $previousLeaseBefore = Get-ByteSnapshot -Path $previousLeasePaths[0]
        $preservingRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $preservingRepair -ExitCode 0 -Label "Repair with retained previous-generation MCP"
        Assert-True -Condition ($preservingRepair.Text.Contains("[RETAINED] generation poc.29 mcp PID $($previousGenerationMcp.Id)")) -Message "Repair omitted the retained previous-generation MCP owner."
        Assert-True -Condition ($preservingRepair.Text.Contains("[RESULT] REPAIRED")) -Message "Retained previous-generation MCP Repair did not report REPAIRED."
        Assert-True -Condition (-not $preservingRepair.Text.Contains("PARTIALLY_REPAIRED")) -Message "Retained previous-generation MCP was incorrectly treated as a partial repair."
        Assert-StructuredCommandResult `
            -Result $preservingRepair `
            -Action "REPAIR" `
            -Outcome "REPAIRED" `
            -CleanupState "PENDING" `
            -Label "Repair with retained previous-generation MCP"
        Assert-Equal -Actual (Get-ByteSnapshot -Path $previousLeasePaths[0]) -Expected $previousLeaseBefore -Message "Repair changed the active previous-generation MCP lease."
        Assert-True -Condition (-not $previousGenerationMcp.HasExited) -Message "Repair terminated the active previous-generation MCP owner."
        Assert-True -Condition (-not $preservingRepair.Text.Contains("[STOPPING]")) -Message "Repair attempted to Stop the active previous-generation MCP owner."
        Assert-Equal -Actual (Get-FileSnapshot -Root $prior.GenerationRoot) -Expected $previousGenerationBefore -Message "Repair changed the leased previous generation."
        Assert-True -Condition ((Get-Content -LiteralPath $repairConfigPath -Raw).Contains($targetHeader)) -Message "Repair did not publish registration while retaining the previous-generation MCP owner."
        $selectedWhilePreviousMcpActive = Get-Content -LiteralPath $repairCurrentPointerPath -Raw | ConvertFrom-Json
        $rollbackWhilePreviousMcpActive = Get-Content -LiteralPath $repairLastKnownGoodPath -Raw | ConvertFrom-Json
        Assert-Equal -Actual $selectedWhilePreviousMcpActive.generation_id -Expected $generationId -Message "Repair did not select the current generation while retaining the previous-generation MCP owner."
        Assert-Equal -Actual $rollbackWhilePreviousMcpActive.generation_id -Expected "poc.29" -Message "Repair did not retain poc.29 as last known good."
    } finally {
        if ($null -ne $previousGenerationMcp) {
            Stop-GenerationHostUseLeaseProcess -Process $previousGenerationMcp -Owner "mcp" -LeaseGenerationId "poc.29" -Root $repairHostRoot
        }
    }
    $preservingRepairAgain = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $preservingRepairAgain -ExitCode 0 -Label "Repeated Repair after retained previous-generation MCP"
    Assert-StructuredCommandResult `
        -Result $preservingRepairAgain `
        -Action "REPAIR" `
        -Outcome "REPAIRED" `
        -CleanupState "COMPLETE" `
        -Label "Repair after previous-generation MCP drain"
    Assert-True -Condition (-not (Test-Path -LiteralPath $prior.GenerationRoot)) -Message "Repair retained the drained previous generation."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerRoot) -Expected $providerBefore -Message "Repair changed Provider, custom config, index, adapter, or start policy content."
    Assert-Equal -Actual (Get-FileSnapshot -Root $unrelatedGenerationRoot) -Expected $unrelatedGenerationBefore -Message "Repair changed an unrelated generation."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $updatePolicyPath) -Expected $updatePolicyBefore -Message "Repair changed automatic-update policy bytes."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $businessSentinelPath) -Expected $businessBefore -Message "Repair changed a business file."
    $indexAfter = (@(Invoke-FixtureIndexGit -Arguments @("diff", "--cached", "--name-only")) -join "`n")
    Assert-Equal -Actual $indexAfter -Expected $indexBefore -Message "Repair changed the caller's Git index."
    $selectedAfterPreservingRepair = Get-Content -LiteralPath $repairCurrentPointerPath -Raw | ConvertFrom-Json
    $rollbackAfterPreservingRepair = Get-Content -LiteralPath $repairLastKnownGoodPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $selectedAfterPreservingRepair.generation_id -Expected $generationId -Message "Repair did not select the current generation."
    Assert-Equal -Actual $rollbackAfterPreservingRepair.generation_id -Expected $generationId -Message "Post-drain Repair did not advance last-known-good to the current generation."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $businessGitPath)
    Write-Host "[OK] Repair preserved live current/previous immutable-generation MCP owners, then reclaimed the previous closure after drain while preserving Provider, index, adapter, policies, business files, and Git staging."

    Install-CurrentTrackedAdoptionFixture
    Assert-Result `
        -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot) `
        -ExitCode 0 `
        -Label "Pending rollback intersection setup"
    $rollbackMcp = $null
    $pendingRollback = $null
    try {
        $rollbackMcp = Start-GenerationHostUseLeaseProcess `
            -GatePath (Join-Path $repairGenerationRoot "shared\codedb-host-use-gate.mjs") `
            -Owner "mcp" `
            -LeaseGenerationId $generationId `
            -SuppressHeartbeat `
            -Root $repairHostRoot
        $rollbackLeasePaths = @(Get-GenerationLeasePaths -Owner "mcp" -ProcessId $rollbackMcp.Id -LeaseGenerationId $generationId -Root $repairHostRoot)
        Assert-Equal -Actual $rollbackLeasePaths.Count -Expected 1 -Message "Pending rollback fixture did not publish one MCP lease."
        $rollbackTargetRelativePath = $generationTargetPrefix + "codedbignore.example"
        $pendingRollback = New-PendingGenerationRollbackFixture `
            -Root $repairHostRoot `
            -GenerationId $generationId `
            -TargetRelativePath $rollbackTargetRelativePath
        $pendingRollbackBefore = Get-FileSnapshot -Root $pendingRollback
        $rollbackGenerationBefore = Get-FileSnapshot -Root $repairGenerationRoot
        $rollbackLeaseBefore = Get-ByteSnapshot -Path $rollbackLeasePaths[0]
        $rollbackConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
        $blockedRollbackRepair = Invoke-Materializer `
            -Action "Repair" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $repairHostRoot
        Assert-Result -Result $blockedRollbackRepair -ExitCode 4 -Label "Repair pending rollback intersection refusal"
        Assert-True -Condition ($blockedRollbackRepair.Text.Contains("pending transaction rollback would mutate generation $generationId")) -Message "Repair did not report the pending rollback generation intersection.`n$($blockedRollbackRepair.Text)"
        Assert-True -Condition ($blockedRollbackRepair.Text.Contains("[RESULT] BLOCKED")) -Message "Pending rollback intersection did not report BLOCKED."
        Assert-True -Condition (-not $blockedRollbackRepair.Text.Contains("[STOPPING]")) -Message "Pending rollback refusal attempted to Stop the MCP owner."
        Assert-True -Condition (-not $rollbackMcp.HasExited) -Message "Pending rollback refusal terminated the MCP owner."
        Assert-Equal -Actual (Get-FileSnapshot -Root $pendingRollback) -Expected $pendingRollbackBefore -Message "Repair changed the conflicting pending transaction."
        Assert-Equal -Actual (Get-FileSnapshot -Root $repairGenerationRoot) -Expected $rollbackGenerationBefore -Message "Repair changed the leased generation before blocking rollback."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $rollbackLeasePaths[0]) -Expected $rollbackLeaseBefore -Message "Repair changed the lease before blocking rollback."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $rollbackConfigBefore -Message "Repair changed MCP config before blocking rollback."
        Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $repairRuntimeRoot "materialize-active.json"))) -Message "Blocked pending rollback left a Repair active marker."
    } finally {
        if ($null -ne $rollbackMcp) {
            Stop-GenerationHostUseLeaseProcess -Process $rollbackMcp -Owner "mcp" -LeaseGenerationId $generationId -Root $repairHostRoot
        }
        if ($null -ne $pendingRollback -and (Test-Path -LiteralPath $pendingRollback)) {
            Remove-Item -LiteralPath $pendingRollback -Recurse -Force
        }
    }
    Write-Host "[OK] Repair blocked a pending rollback intersecting a leased immutable generation before any related write."

    Install-CurrentTrackedAdoptionFixture
    $partialCandidateRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    $partialCandidateFile = Join-Path $partialCandidateRoot "codedbignore.example"
    New-Item -ItemType Directory -Force -Path $partialCandidateRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "Generations\$generationId\codedbignore.example") -Destination $partialCandidateFile
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "host-current.json") -Destination $repairCurrentPointerPath -Force
    $staleRollback = Get-Content -LiteralPath (Join-Path $canonicalPayloadRoot "host-current.json") -Raw | ConvertFrom-Json
    $staleRollback.package_version = "0.2.4"
    $staleRollback.payload_version = "poc.28"
    $staleRollback.payload_sequence = 28
    $staleRollback.generation_id = "poc.28"
    $staleRollback.generation_relative_path = "AIWork/.runtime/codedb/host/generations/poc.28"
    $staleRollback.generation_manifest_sha256 = "0" * 64
    Write-Utf8File -Path $repairLastKnownGoodPath -Content (($staleRollback | ConvertTo-Json -Depth 8) + "`n")
    $preMutationTransaction = Join-Path $repairRuntimeRoot "txn-v1-aaaaaaaaaaaa"
    New-Item -ItemType Directory -Force -Path $preMutationTransaction | Out-Null
    $quarantineRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $quarantineRepair -ExitCode 0 -Label "Repair deterministic Host residue"
    Assert-True -Condition ($quarantineRepair.Text.Contains("[RECOVERED] Removed an interrupted pre-mutation transaction.")) -Message "Repair did not recover the pre-mutation journal residue."
    Assert-True -Condition ([regex]::Matches($quarantineRepair.Text, '(?m)^\[QUARANTINED\]').Count -eq 3) -Message "Repair did not quarantine the candidate and two stale pointers."
    Assert-True -Condition (-not (Test-Path -LiteralPath $preMutationTransaction)) -Message "Repair retained the recovered pre-mutation transaction."
    $quarantineRuns = @(Get-ChildItem -LiteralPath (Join-Path $repairHostRuntimeRoot "quarantine") -Force -Directory)
    Assert-Equal -Actual $quarantineRuns.Count -Expected 1 -Message "Repair did not publish exactly one scoped quarantine run."
    Assert-Equal -Actual @(Get-ChildItem -LiteralPath $quarantineRuns[0].FullName -Force).Count -Expected 3 -Message "Repair quarantine does not contain the candidate and two pointers."
    Assert-Equal -Actual (Get-Content -LiteralPath $repairCurrentPointerPath -Raw | ConvertFrom-Json).generation_id -Expected $generationId -Message "Quarantine Repair did not reconstruct current.json."
    Assert-Equal -Actual (Get-Content -LiteralPath $repairLastKnownGoodPath -Raw | ConvertFrom-Json).generation_id -Expected $generationId -Message "Quarantine Repair did not reconstruct a valid rollback pointer."
    Write-Host "[OK] Repair recovered a journal and quarantined only deterministic candidate and pointer residue before reconstruction."

    Install-CurrentTrackedAdoptionFixture
    $unsafeCandidateRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    Write-Utf8File -Path (Join-Path $unsafeCandidateRoot "unowned.bin") -Content "unowned candidate content`n"
    $unsafeCandidateBefore = Get-FileSnapshot -Root $repairHostRoot
    $unsafeCandidateRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $unsafeCandidateRepair -ExitCode 4 -Label "Repair unowned candidate refusal"
    Assert-True -Condition ($unsafeCandidateRepair.Text.Contains("unowned content")) -Message "Repair did not report the unowned candidate boundary."
    Assert-True -Condition ($unsafeCandidateRepair.Text.Contains("[RESULT] BLOCKED")) -Message "Unowned candidate Repair did not report BLOCKED."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $unsafeCandidateBefore -Message "Repair changed an unsafe candidate fixture."

    Install-CurrentTrackedAdoptionFixture
    $leasedCandidateRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    New-Item -ItemType Directory -Force -Path $leasedCandidateRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "Generations\$generationId\codedbignore.example") -Destination (Join-Path $leasedCandidateRoot "codedbignore.example")
    $currentCandidateLease = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $generationId -Root $repairHostRoot
    $leasedCandidateBefore = Get-FileSnapshot -Root $repairHostRoot
    $leasedCandidateRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $leasedCandidateRepair -ExitCode 4 -Label "Repair live candidate lease refusal"
    Assert-True -Condition ($leasedCandidateRepair.Text.Contains("conflicted package generation has an active lease")) -Message "Repair did not report the live candidate lease boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $repairHostRoot) -Expected $leasedCandidateBefore -Message "Repair changed a live leased candidate."
    Assert-True -Condition (Test-Path -LiteralPath $currentCandidateLease -PathType Leaf) -Message "Repair removed the live candidate lease."
    Write-Host "[OK] Repair refused unowned or actively leased candidate residue without writes."

    Reset-RepairFixture
    $null = Install-PriorGenerationFixture `
        -PriorGenerationId "poc.29" `
        -PriorPayloadSequence 29 `
        -PriorPackageVersion "0.2.5-preview.2" `
        -UsePackageGeneration `
        -Root $repairHostRoot
    $crashedSync = Invoke-Materializer `
        -Action "Sync" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestCrashAfterMutation 2
    Assert-Result -Result $crashedSync -ExitCode 86 -Label "Repair interrupted-sync setup"
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 1) -Message "Interrupted Sync fixture did not retain one transaction."
    $interruptedRepair = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $interruptedRepair -ExitCode 0 -Label "Repair interrupted legacy Sync"
    Assert-True -Condition ($interruptedRepair.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Repair did not recover the interrupted Sync journal."
    Assert-True -Condition ($interruptedRepair.Text.Contains("[RESULT] REPAIRED")) -Message "Interrupted Sync Repair did not converge."
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 0) -Message "Repair retained an interrupted transaction after convergence."
    Write-Host "[OK] Repair recovered a durable interrupted legacy Sync journal and converged in one action."

    Install-CurrentTrackedAdoptionFixture
    $quarantineCrashCandidateRoot = Join-Path $repairHostRuntimeRoot "generations\$generationId"
    New-Item -ItemType Directory -Force -Path $quarantineCrashCandidateRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "Generations\$generationId\codedbignore.example") -Destination (Join-Path $quarantineCrashCandidateRoot "codedbignore.example")
    Copy-Item -LiteralPath (Join-Path $canonicalPayloadRoot "host-current.json") -Destination $repairCurrentPointerPath -Force
    $quarantineCrashPointer = Get-Content -LiteralPath $repairCurrentPointerPath -Raw | ConvertFrom-Json
    $quarantineCrashPointer.generation_manifest_sha256 = "0" * 64
    Write-Utf8File -Path $repairLastKnownGoodPath -Content (($quarantineCrashPointer | ConvertTo-Json -Depth 8) + "`n")
    $quarantineCrash = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestCrashAfterMutation 1
    Assert-Result -Result $quarantineCrash -ExitCode 86 -Label "Repair quarantine crash"
    Assert-True -Condition ($quarantineCrash.Text.Contains("Injected POC process crash after mutation 1.")) -Message "Quarantine crash did not reach its first move boundary."
    $quarantineCrashRetry = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $quarantineCrashRetry -ExitCode 0 -Label "Repair quarantine crash retry"
    Assert-True -Condition ($quarantineCrashRetry.Text.Contains("[RESULT] REPAIRED")) -Message "Quarantine crash retry did not converge."
    Assert-Equal -Actual (Get-Content -LiteralPath $repairCurrentPointerPath -Raw | ConvertFrom-Json).generation_id -Expected $generationId -Message "Quarantine crash retry did not restore current.json."

    Reset-RepairFixture
    Install-OwnedLegacyRedeployFixture -Root $repairHostRoot
    $legacyJournalCrash = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestCrashAfterMutation 2
    Assert-Result -Result $legacyJournalCrash -ExitCode 86 -Label "Repair flat Host journal crash"
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 1) -Message "Flat Host crash did not retain one durable journal."
    $legacyJournalRetry = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $legacyJournalRetry -ExitCode 0 -Label "Repair flat Host journal crash retry"
    Assert-True -Condition ($legacyJournalRetry.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Flat Host journal retry did not report recovery."
    Assert-True -Condition ($legacyJournalRetry.Text.Contains("[RESULT] REPAIRED")) -Message "Flat Host journal retry did not converge."

    Install-CurrentTrackedAdoptionFixture
    $pointerPublicationCrash = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestCrashAfterMutation 2
    Assert-Result -Result $pointerPublicationCrash -ExitCode 86 -Label "Repair current pointer publication crash"
    Assert-True -Condition (Test-Path -LiteralPath $repairCurrentPointerPath -PathType Leaf) -Message "Pointer crash did not reach current.json publication."
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 1) -Message "Pointer crash did not retain one durable journal."
    $pointerPublicationRetry = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $pointerPublicationRetry -ExitCode 0 -Label "Repair current pointer publication crash retry"
    Assert-True -Condition ($pointerPublicationRetry.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Pointer crash retry did not report recovery."
    Assert-True -Condition ($pointerPublicationRetry.Text.Contains("[RESULT] REPAIRED")) -Message "Pointer crash retry did not converge."
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $repairRuntimeRoot -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 0) -Message "Pointer crash retry retained a transaction."
    Write-Host "[OK] Repair recovered quarantine, flat Host journal, and current-pointer publication crashes on one retry."

    Install-CurrentTrackedAdoptionFixture
    $watcherPartialConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
    $watcherPartial = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestFailWatcherHandoff
    Assert-Result -Result $watcherPartial -ExitCode 8 -Label "Repair watcher partial failure"
    Assert-True -Condition ($watcherPartial.Text.Contains("[PHASE WATCHER] BLOCKED")) -Message "Watcher fault did not report its phase."
    Assert-True -Condition ($watcherPartial.Text.Contains("[RESULT] PARTIALLY_REPAIRED")) -Message "Watcher fault did not report PARTIALLY_REPAIRED."
    Assert-True -Condition ($watcherPartial.Text.Contains("[NEXT] Resolve the reported watcher runtime boundary")) -Message "Watcher fault did not report one focused next step."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $watcherPartialConfigBefore -Message "Watcher partial failure changed MCP registration."
    Assert-True -Condition (Test-Path -LiteralPath $repairCurrentPointerPath -PathType Leaf) -Message "Watcher partial failure did not retain repaired Host runtime."
    $watcherRetry = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $watcherRetry -ExitCode 0 -Label "Repair watcher partial retry"
    Assert-True -Condition ($watcherRetry.Text.Contains("[RESULT] REPAIRED")) -Message "Watcher partial retry did not converge."

    Install-CurrentTrackedAdoptionFixture
    $mcpPartialConfigBefore = Get-ByteSnapshot -Path $repairConfigPath
    $mcpPartial = Invoke-Materializer `
        -Action "Repair" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $repairHostRoot `
        -TestFailRepairMcpRegistration
    Assert-Result -Result $mcpPartial -ExitCode 8 -Label "Repair MCP partial failure"
    Assert-True -Condition ($mcpPartial.Text.Contains("[PHASE MCP_REGISTRATION] BLOCKED")) -Message "MCP fault did not report its phase."
    Assert-True -Condition ($mcpPartial.Text.Contains("[RESULT] PARTIALLY_REPAIRED")) -Message "MCP fault did not report PARTIALLY_REPAIRED."
    Assert-True -Condition ($mcpPartial.Text.Contains("[NEXT] Resolve the reported project MCP config boundary")) -Message "MCP fault did not report one focused next step."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $repairConfigPath) -Expected $mcpPartialConfigBefore -Message "Injected pre-publication MCP fault changed config bytes."
    Assert-True -Condition (Test-Path -LiteralPath $repairCurrentPointerPath -PathType Leaf) -Message "MCP partial failure did not retain repaired Host runtime."
    $mcpRetry = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $repairHostRoot
    Assert-Result -Result $mcpRetry -ExitCode 0 -Label "Repair MCP partial retry"
    Assert-True -Condition ($mcpRetry.Text.Contains("[RESULT] REPAIRED")) -Message "MCP partial retry did not converge."
    Write-Host "[OK] Watcher and MCP phase faults reported one partial result and converged on one Repair retry."

    Invoke-McpConfigCompatibilityScenarios
}

function Invoke-UninstallAcceptanceScenarios {
    $configPath = Join-Path $uninstallHostRoot ".codex\config.toml"
    $desiredStatePath = Join-Path $uninstallHostRoot "AIWork\.runtime\codedb\control\desired-state.json"
    $instanceCurrentPath = Join-Path $uninstallHostRoot "AIWork\.runtime\codedb\control\current-instance.json"
    $instanceLastKnownGoodPath = Join-Path $uninstallHostRoot "AIWork\.runtime\codedb\control\last-known-good-instance.json"
    $instancesRoot = Join-Path $uninstallHostRoot "AIWork\.runtime\codedb\instances"
    $stableWrapperPath = Join-Path $uninstallHostRoot "AIWork\codedb\wrapper\codedb-project-wrapper.mjs"
    $markerPath = Get-PathFromRelative -Root $uninstallHostRoot -RelativePath $markerRelativePath
    $currentPointerPath = Get-PathFromRelative -Root $uninstallHostRoot -RelativePath $currentPointerRelativePath
    $generationRoot = Join-Path $uninstallHostRoot "AIWork\.runtime\codedb\host\generations\$generationId"
    $projectSlug = ConvertTo-TestProjectSlug -Value (Split-Path -Leaf $uninstallHostRoot.TrimEnd('\', '/'))
    $targetTable = "mcp_servers.codedb-$projectSlug"
    $installedConfig = @(
        "# unrelated prefix",
        "[editor]",
        'theme = "dark"',
        "",
        "[$targetTable]",
        'command = "node"',
        'cwd = "."',
        'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
        'startup_timeout_sec = 120',
        'custom_direct = "keep"',
        "# preserve target comment",
        "",
        "[$targetTable.tools.codedb_text_search]",
        'approval_mode = "approve"',
        "",
        "[mcp_servers.unrelated]",
        'command = "keep-me"'
    ) -join "`n"
    $installedConfig += "`n"
    if (Test-Path -LiteralPath $uninstallHostRoot) {
        Remove-Item -LiteralPath $uninstallHostRoot -Recurse -Force
    }
    New-TestHost -Root $uninstallHostRoot
    $installSetup = Invoke-Materializer -Action "Reinstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $installSetup -ExitCode 0 -Label "Uninstall setup Reinstall"
    $initialInstance = [System.IO.File]::ReadAllText($instanceCurrentPath, $utf8NoBom) | ConvertFrom-Json
    $initialInstanceId = [string]$initialInstance.instance_id
    Assert-True -Condition ($initialInstanceId -cmatch '^[0-9a-f]{32}$') -Message "Uninstall setup did not select an immutable instance."
    Write-Utf8File -Path $configPath -Content $installedConfig
    $businessBefore = Get-ByteSnapshot -Path (Join-Path $uninstallHostRoot "Assets\BusinessSentinel.txt")

    $uninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $uninstall -ExitCode 0 -Label "Complete project Uninstall"
    Assert-True -Condition ($uninstall.Text.Contains("[RESULT] UNINSTALLED")) -Message "Complete Uninstall did not report UNINSTALLED."
    Assert-True -Condition ($uninstall.Text.Contains("[CLEANUP_STATE] COMPLETE")) -Message "Complete Uninstall did not report cleanup COMPLETE."
    Assert-True -Condition (Test-Path -LiteralPath $desiredStatePath -PathType Leaf) -Message "Uninstall did not persist UNINSTALLED desired state."
    Assert-True -Condition (-not (Test-Path -LiteralPath $markerPath)) -Message "Complete Uninstall retained the installed marker."
    Assert-True -Condition (-not (Test-Path -LiteralPath $currentPointerPath)) -Message "Complete Uninstall retained current.json."
    Assert-True -Condition (-not (Test-Path -LiteralPath $generationRoot)) -Message "Complete Uninstall retained the owned immutable generation."
    Assert-True -Condition (-not (Test-Path -LiteralPath $instanceCurrentPath)) -Message "Complete Uninstall retained current-instance.json."
    Assert-True -Condition (-not (Test-Path -LiteralPath $instanceLastKnownGoodPath)) -Message "Complete Uninstall retained last-known-good-instance.json."
    Assert-True -Condition (-not (Test-Path -LiteralPath $stableWrapperPath)) -Message "Complete Uninstall retained the stable CodeDB wrapper."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $instancesRoot $initialInstanceId))) -Message "Complete Uninstall retained the selected instance."
    $desiredState = [System.IO.File]::ReadAllText($desiredStatePath, $utf8NoBom) | ConvertFrom-Json
    Assert-Equal -Actual ([string]$desiredState.desired_state) -Expected "UNINSTALLED" -Message "Uninstall desired state is incorrect."
    Assert-True -Condition ([string]$desiredState.state_id -cmatch '^[0-9a-f]{32}$') -Message "Uninstall did not persist a valid state id."
    Assert-Equal -Actual ([string]$desiredState.cleanup_state) -Expected "COMPLETE" -Message "Complete Uninstall did not persist cleanup COMPLETE."
    $preservedPrefix = "# rice-ai-codedb-uninstalled:$($desiredState.state_id): "
    $installedLines = [regex]::Split($installedConfig, "`n")
    for ($lineIndex = 4; $lineIndex -le 14; $lineIndex++) {
        $installedLines[$lineIndex] = $preservedPrefix + $installedLines[$lineIndex]
    }
    $uninstalledConfig = $installedLines -join "`n"
    Assert-Equal -Actual ([System.IO.File]::ReadAllText($configPath, $utf8NoBom)) -Expected $uninstalledConfig -Message "Uninstall did not disable the complete target MCP namespace byte-exactly."
    Assert-True -Condition (-not ($installedLines -ccontains "[$targetTable]")) -Message "Uninstall retained an active target MCP parent table."
    Assert-True -Condition (-not ($installedLines -ccontains "[$targetTable.tools.codedb_text_search]")) -Message "Uninstall retained an active target MCP descendant table."
    Assert-Equal -Actual (Get-ByteSnapshot -Path (Join-Path $uninstallHostRoot "Assets\BusinessSentinel.txt")) -Expected $businessBefore -Message "Uninstall changed a business file."

    $uninstalledSnapshot = Get-FileSnapshot -Root $uninstallHostRoot
    $repeatUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $repeatUninstall -ExitCode 0 -Label "Repeated project Uninstall"
    Assert-True -Condition ($repeatUninstall.Text.Contains("[RESULT] UNINSTALLED")) -Message "Repeated Uninstall did not remain UNINSTALLED."
    Assert-Equal -Actual (Get-FileSnapshot -Root $uninstallHostRoot) -Expected $uninstalledSnapshot -Message "Repeated Uninstall was not byte-exact."

    foreach ($suppressedAction in @("DryRun", "Verify")) {
        $suppressed = Invoke-Materializer -Action $suppressedAction -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
        Assert-Result -Result $suppressed -ExitCode 0 -Label "UNINSTALLED $suppressedAction"
        Assert-True -Condition ($suppressed.Text.Contains("[UNINSTALLED]")) -Message "$suppressedAction did not report UNINSTALLED."
    }
    $blockedRepairBefore = Get-FileSnapshot -Root $uninstallHostRoot
    $blockedRepair = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $blockedRepair -ExitCode 4 -Label "UNINSTALLED Repair suppression"
    Assert-True -Condition ($blockedRepair.Text.Contains("Use Install CodeDB")) -Message "Suppressed Repair did not point to Install CodeDB."
    Assert-Equal -Actual (Get-FileSnapshot -Root $uninstallHostRoot) -Expected $blockedRepairBefore -Message "Suppressed Repair changed an UNINSTALLED project."

    $install = Invoke-Materializer -Action "Install" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $install -ExitCode 0 -Label "Fresh project Install"
    Assert-True -Condition ($install.Text.Contains("[RESULT] INSTALLED")) -Message "Install did not report INSTALLED."
    $installedDesiredState = [System.IO.File]::ReadAllText($desiredStatePath, $utf8NoBom) | ConvertFrom-Json
    Assert-Equal -Actual ([string]$installedDesiredState.desired_state) -Expected "INSTALLED" -Message "Install did not transition desired state to INSTALLED."
    Assert-Equal -Actual ([string]$installedDesiredState.cleanup_state) -Expected "COMPLETE" -Message "Install did not persist cleanup COMPLETE."
    Assert-True -Condition (-not (Test-Path -LiteralPath $markerPath)) -Message "Instance Install unexpectedly published a legacy flat marker."
    Assert-True -Condition (Test-Path -LiteralPath $currentPointerPath -PathType Leaf) -Message "Install did not restore current.json."
    Assert-True -Condition (Test-Path -LiteralPath $generationRoot -PathType Container) -Message "Install did not restore the immutable generation."
    Assert-True -Condition (Test-Path -LiteralPath $instanceCurrentPath -PathType Leaf) -Message "Install did not select a current instance."
    Assert-True -Condition (Test-Path -LiteralPath $stableWrapperPath -PathType Leaf) -Message "Install did not restore the stable wrapper."
    $installedInstance = [System.IO.File]::ReadAllText($instanceCurrentPath, $utf8NoBom) | ConvertFrom-Json
    Assert-True -Condition (-not [string]::Equals([string]$installedInstance.instance_id, $initialInstanceId, [StringComparison]::Ordinal)) -Message "Install reused the retired instance identity."
    $installedAfter = [System.IO.File]::ReadAllText($configPath, $utf8NoBom)
    Assert-True -Condition ($installedAfter.Contains('custom_direct = "keep"')) -Message "Install changed the custom target key."
    Assert-True -Condition ($installedAfter.Contains("[$targetTable.tools.codedb_text_search]")) -Message "Install changed the target tools descendant."
    Assert-True -Condition ($installedAfter.Contains('command = "node"')) -Message "Install did not restore managed MCP keys."
    Assert-Equal -Actual $installedAfter -Expected $installedConfig -Message "Install did not restore the exact pre-Uninstall target namespace bytes."
    $repeatInstallBefore = Get-FileSnapshot -Root $uninstallHostRoot
    $repeatInstall = Invoke-Materializer -Action "Install" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $repeatInstall -ExitCode 4 -Label "Installed-state Install refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $uninstallHostRoot) -Expected $repeatInstallBefore -Message "Refused repeated Install changed the project."
    Write-Host "[OK] Complete Uninstall, repeated Uninstall, suppression, and fresh Install converged without changing user-owned MCP content."

    $childFirstText = @(
        "# child-first sentinel",
        "[$targetTable.tools.codedb_text_search]",
        'approval_mode = "approve"',
        "# child-first comment",
        "",
        "[$targetTable]",
        'custom_direct = "child-first-keep"',
        'command = "node"',
        'cwd = "."',
        'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
        'startup_timeout_sec = 120',
        "",
        "[mcp_servers.unrelated]",
        'command = "keep-me"',
        ""
    ) -join "`r`n"
    $childFirstBody = $utf8NoBom.GetBytes($childFirstText)
    $childFirstBytes = New-Object byte[] ($childFirstBody.Length + 3)
    $childFirstBytes[0] = 0xEF
    $childFirstBytes[1] = 0xBB
    $childFirstBytes[2] = 0xBF
    [Array]::Copy($childFirstBody, 0, $childFirstBytes, 3, $childFirstBody.Length)
    [System.IO.File]::WriteAllBytes($configPath, $childFirstBytes)
    $childFirstOriginalBase64 = [Convert]::ToBase64String($childFirstBytes)
    $childFirstUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $childFirstUninstall -ExitCode 0 -Label "Child-first BOM/CRLF Uninstall"
    $childFirstDisabledBytes = [System.IO.File]::ReadAllBytes($configPath)
    Assert-True -Condition ($childFirstDisabledBytes[0] -eq 0xEF -and $childFirstDisabledBytes[1] -eq 0xBB -and $childFirstDisabledBytes[2] -eq 0xBF) -Message "Child-first Uninstall did not preserve UTF-8 BOM."
    $childFirstDisabledText = $utf8NoBom.GetString($childFirstDisabledBytes, 3, $childFirstDisabledBytes.Length - 3)
    Assert-True -Condition ($childFirstDisabledText.Contains("`r`n") -and -not $childFirstDisabledText.Replace("`r`n", "").Contains("`n")) -Message "Child-first Uninstall did not preserve CRLF."
    Assert-Equal -Actual ([regex]::Matches($childFirstDisabledText, "(?m)^\[$([regex]::Escape($targetTable))(?:\.|\])").Count) -Expected 0 -Message "Child-first Uninstall retained an active target namespace."
    Assert-True -Condition ($childFirstDisabledText.Contains('custom_direct = "child-first-keep"')) -Message "Child-first Uninstall lost the custom direct key bytes."
    Assert-True -Condition ($childFirstDisabledText.Contains("# child-first comment")) -Message "Child-first Uninstall lost the target comment bytes."
    $childFirstInstall = Invoke-Materializer -Action "Install" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $childFirstInstall -ExitCode 0 -Label "Child-first BOM/CRLF Install"
    Assert-Equal -Actual ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($configPath))) -Expected $childFirstOriginalBase64 -Message "Child-first Install did not restore the exact BOM/CRLF pre-image."

    $childOnlyConfig = @(
        "# child-only sentinel",
        "[$targetTable.tools.codedb_text_search]",
        'approval_mode = "approve"',
        "# child-only comment",
        "",
        "[mcp_servers.unrelated]",
        'command = "keep-me"',
        ""
    ) -join "`n"
    Write-Utf8File -Path $configPath -Content $childOnlyConfig
    $childOnlyUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $childOnlyUninstall -ExitCode 0 -Label "Child-only Uninstall"
    $childOnlyDisabled = [System.IO.File]::ReadAllText($configPath, $utf8NoBom)
    Assert-Equal -Actual ([regex]::Matches($childOnlyDisabled, "(?m)^\[$([regex]::Escape($targetTable))(?:\.|\])").Count) -Expected 0 -Message "Child-only Uninstall retained an active descendant table."
    $childOnlyInstall = Invoke-Materializer -Action "Install" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $childOnlyInstall -ExitCode 0 -Label "Child-only Install"
    $childOnlyInstalled = [System.IO.File]::ReadAllText($configPath, $utf8NoBom)
    Assert-True -Condition ($childOnlyInstalled.Contains("# child-only sentinel`n[$targetTable.tools.codedb_text_search]`napproval_mode = `"approve`"`n# child-only comment")) -Message "Child-only Install changed the preserved descendant block."
    Assert-Equal -Actual ([regex]::Matches($childOnlyInstalled, "(?m)^\[$([regex]::Escape($targetTable))\]$").Count) -Expected 1 -Message "Child-only Install did not create exactly one target parent table."
    foreach ($managedLine in @('command = "node"', 'cwd = "."', 'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]', 'startup_timeout_sec = 120')) {
        Assert-True -Condition ($childOnlyInstalled.Contains($managedLine)) -Message "Child-only Install did not restore managed MCP line '$managedLine'."
    }
    Write-Utf8File -Path $configPath -Content $installedConfig
    Write-Host "[OK] Uninstall/Install preserved child-first and child-only user namespaces, BOM/EOL, comments, and custom keys."

    $externalLease = New-TestGenerationLease -Owner "mcp" -Root $uninstallHostRoot
    $leaseBefore = Get-ByteSnapshot -Path $externalLease
    $generationBefore = Get-FileSnapshot -Root $generationRoot
    $markerBefore = Get-ByteSnapshot -Path $markerPath
    $pointerBefore = Get-ByteSnapshot -Path $currentPointerPath
    $pendingUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $pendingUninstall -ExitCode 0 -Label "External MCP pending Uninstall"
    Assert-True -Condition ($pendingUninstall.Text.Contains("[RESULT] UNINSTALLED")) -Message "External MCP Uninstall did not finish logically."
    Assert-True -Condition ($pendingUninstall.Text.Contains("[CLEANUP_STATE] PENDING")) -Message "External MCP Uninstall did not report cleanup PENDING."
    Assert-True -Condition ($pendingUninstall.Text.Contains("no external MCP process was stopped")) -Message "External MCP Uninstall did not report retained process ownership."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $externalLease) -Expected $leaseBefore -Message "External MCP Uninstall changed its lease."
    Assert-Equal -Actual (Get-FileSnapshot -Root $generationRoot) -Expected $generationBefore -Message "External MCP Uninstall changed its immutable generation."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $markerPath) -Expected $markerBefore -Message "External MCP Uninstall changed the retained marker."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $currentPointerPath) -Expected $pointerBefore -Message "External MCP Uninstall changed the retained pointer."
    Assert-True -Condition ($null -ne (Get-Process -Id $PID -ErrorAction SilentlyContinue)) -Message "External MCP Uninstall terminated the test owner process."

    $pendingSnapshot = Get-FileSnapshot -Root $uninstallHostRoot
    $repeatPending = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $repeatPending -ExitCode 0 -Label "Repeated external MCP pending Uninstall"
    Assert-True -Condition ($repeatPending.Text.Contains("[CLEANUP_STATE] PENDING")) -Message "Repeated external MCP Uninstall lost cleanup PENDING."
    Assert-Equal -Actual (Get-FileSnapshot -Root $uninstallHostRoot) -Expected $pendingSnapshot -Message "Repeated pending Uninstall was not byte-exact."

    Remove-Item -LiteralPath $externalLease -Force
    $cleanupReadyName = "RiceAICodeDBUninstallReady$([guid]::NewGuid().ToString('N'))"
    $cleanupContinueName = "RiceAICodeDBUninstallContinue$([guid]::NewGuid().ToString('N'))"
    $cleanupReady = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $cleanupReadyName)
    $cleanupContinue = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $cleanupContinueName)
    $cleanupInvocation = $null
    $cleanupBoundaryInstallInvocation = $null
    try {
        $cleanupInvocation = Start-UninstallMcpHandshakeInvocation `
            -Action "Upgrade" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $uninstallHostRoot `
            -ReadyEventName $cleanupReadyName `
            -ContinueEventName $cleanupContinueName
        Assert-True -Condition $cleanupReady.WaitOne(15000) -Message "Automatic cleanup did not pause at its MCP/Remove boundary."
        $cleanupBoundaryInstallInvocation = Start-AsyncMaterializerInvocation `
            -Action "Install" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $uninstallHostRoot
        Start-Sleep -Milliseconds 750
        Assert-True -Condition (-not $cleanupBoundaryInstallInvocation.Process.HasExited) -Message "Install bypassed the automatic cleanup materializer lock."
        $null = $cleanupContinue.Set()
        $automaticCleanup = Complete-MaterializerInvocation -Invocation $cleanupInvocation -TimeoutMilliseconds 45000
        $cleanupInvocation = $null
        Assert-Result -Result $automaticCleanup -ExitCode 0 -Label "Post-drain automatic Uninstall cleanup"
        Assert-True -Condition ($automaticCleanup.Text.Contains("[RESULT] UNINSTALLED")) -Message "Automatic cleanup did not retain UNINSTALLED result."
        Assert-True -Condition ($automaticCleanup.Text.Contains("[CLEANUP_STATE] COMPLETE")) -Message "Automatic cleanup did not converge to COMPLETE."
        $cleanupBoundaryInstall = Complete-MaterializerInvocation -Invocation $cleanupBoundaryInstallInvocation -TimeoutMilliseconds 45000
        $cleanupBoundaryInstallInvocation = $null
        Assert-Result -Result $cleanupBoundaryInstall -ExitCode 0 -Label "Install waiting behind automatic cleanup"
        Assert-True -Condition ($cleanupBoundaryInstall.Text.Contains("[RESULT] INSTALLED")) -Message "Install did not finish after automatic cleanup released the lock."
    } finally {
        $null = $cleanupContinue.Set()
        if ($null -ne $cleanupInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $cleanupInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        if ($null -ne $cleanupBoundaryInstallInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $cleanupBoundaryInstallInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        $cleanupContinue.Dispose()
        $cleanupReady.Dispose()
    }
    $postCleanupInstallState = [System.IO.File]::ReadAllText($desiredStatePath, $utf8NoBom) | ConvertFrom-Json
    Assert-Equal -Actual ([string]$postCleanupInstallState.desired_state) -Expected "INSTALLED" -Message "Install left UNINSTALLED state after the cleanup/Install interleaving."
    Assert-True -Condition (-not (Test-Path -LiteralPath $markerPath)) -Message "Instance Install published a legacy marker after cleanup completed first."
    Assert-True -Condition (Test-Path -LiteralPath $generationRoot -PathType Container) -Message "Install did not restore the current generation after cleanup completed first."
    Assert-True -Condition (Test-Path -LiteralPath $instanceCurrentPath -PathType Leaf) -Message "Install did not select a new instance after cleanup completed first."
    Assert-True -Condition ($null -ne (Get-Process -Id $PID -ErrorAction SilentlyContinue)) -Message "Cleanup/Install interleaving terminated the external owner process."
    Write-Host "[OK] Cleanup held one lock from MCP removal through Host cleanup; waiting Install restored Host only after cleanup completed."

    $installBoundaryLease = New-TestGenerationLease -Owner "mcp" -Root $uninstallHostRoot
    $installBoundaryUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $installBoundaryUninstall -ExitCode 0 -Label "Install-boundary pending Uninstall"
    Assert-True -Condition ($installBoundaryUninstall.Text.Contains("[CLEANUP_STATE] PENDING")) -Message "Install-boundary fixture did not retain an external closure."
    Remove-Item -LiteralPath $installBoundaryLease -Force
    $installReadyName = "RiceAICodeDBInstallReady$([guid]::NewGuid().ToString('N'))"
    $installContinueName = "RiceAICodeDBInstallContinue$([guid]::NewGuid().ToString('N'))"
    $installReady = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $installReadyName)
    $installContinue = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $installContinueName)
    $cleanupCapturedName = "RiceAICodeDBCleanupCaptured$([guid]::NewGuid().ToString('N'))"
    $cleanupCaptured = [System.Threading.EventWaitHandle]::new($false, [System.Threading.EventResetMode]::ManualReset, $cleanupCapturedName)
    $installInvocation = $null
    $obsoleteCleanupInvocation = $null
    try {
        $installInvocation = Start-InstallRepairHandshakeInvocation `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $uninstallHostRoot `
            -ReadyEventName $installReadyName `
            -ContinueEventName $installContinueName
        Assert-True -Condition $installReady.WaitOne(30000) -Message "Install did not pause between candidate verification and atomic activation."
        Assert-True -Condition (-not (Test-Path -LiteralPath $markerPath)) -Message "Install candidate unexpectedly published a legacy marker before activation."
        $installBoundaryState = [System.IO.File]::ReadAllText($desiredStatePath, $utf8NoBom) | ConvertFrom-Json
        Assert-Equal -Actual ([string]$installBoundaryState.desired_state) -Expected "UNINSTALLED" -Message "Install changed desired state before atomic activation."
        Assert-True -Condition (-not (Test-Path -LiteralPath $instanceCurrentPath)) -Message "Install selected the candidate before its activation boundary."
        $obsoleteCleanupInvocation = Start-AsyncMaterializerInvocation `
            -Action "Upgrade" `
            -PayloadRoot $canonicalPayloadRoot `
            -TargetProjectRoot $uninstallHostRoot `
            -AutomaticCleanupStateCapturedEventName $cleanupCapturedName
        Assert-True -Condition $cleanupCaptured.WaitOne(15000) -Message "Old automatic cleanup did not capture the pending state before Install clear."
        Assert-True -Condition (-not $obsoleteCleanupInvocation.Process.HasExited) -Message "Automatic cleanup bypassed the Install materializer lock."
        $null = $installContinue.Set()
        $installBoundaryInstall = Complete-MaterializerInvocation -Invocation $installInvocation -TimeoutMilliseconds 45000
        $installInvocation = $null
        Assert-Result -Result $installBoundaryInstall -ExitCode 0 -Label "Install candidate/desired-state atomic completion"
        $obsoleteCleanup = Complete-MaterializerInvocation -Invocation $obsoleteCleanupInvocation -TimeoutMilliseconds 45000
        $obsoleteCleanupInvocation = $null
        Assert-Result -Result $obsoleteCleanup -ExitCode 0 -Label "Obsolete automatic cleanup after Install"
        Assert-True -Condition ($obsoleteCleanup.Text.Contains("[SKIPPED] Automatic uninstall cleanup became obsolete")) -Message "Old automatic cleanup did not skip after Install cleared its state id."
    } finally {
        $null = $installContinue.Set()
        if ($null -ne $installInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $installInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        if ($null -ne $obsoleteCleanupInvocation) {
            try { $null = Complete-MaterializerInvocation -Invocation $obsoleteCleanupInvocation -TimeoutMilliseconds 30000 } catch { }
        }
        $installContinue.Dispose()
        $installReady.Dispose()
        $cleanupCaptured.Dispose()
    }
    $postObsoleteCleanupState = [System.IO.File]::ReadAllText($desiredStatePath, $utf8NoBom) | ConvertFrom-Json
    Assert-Equal -Actual ([string]$postObsoleteCleanupState.desired_state) -Expected "INSTALLED" -Message "Obsolete cleanup recreated or retained UNINSTALLED state after Install."
    Assert-True -Condition (-not (Test-Path -LiteralPath $markerPath)) -Message "Obsolete cleanup caused Install to publish a legacy marker."
    Assert-True -Condition (Test-Path -LiteralPath $generationRoot -PathType Container) -Message "Obsolete cleanup deleted the installed generation after activation."
    Assert-True -Condition (Test-Path -LiteralPath $instanceCurrentPath -PathType Leaf) -Message "Obsolete cleanup deleted the selected instance after Install."
    Assert-Equal -Actual ([System.IO.File]::ReadAllText($configPath, $utf8NoBom)) -Expected $installedConfig -Message "Install/cleanup interleaving changed restored MCP namespace bytes."
    Assert-True -Condition ($null -ne (Get-Process -Id $PID -ErrorAction SilentlyContinue)) -Message "Install/cleanup interleaving terminated the external owner process."
    Write-Host "[OK] Install held one lock through candidate activation and desired-state transition; the waiting old cleanup exited without deleting the selected instance or MCP state."

    $watcherManager = Get-PathFromRelative `
        -Root $uninstallHostRoot `
        -RelativePath ($generationTargetPrefix + "scripts/manage-codedb-project-watch.ps1")
    $watcherPrepare = Get-PathFromRelative `
        -Root $uninstallHostRoot `
        -RelativePath ($generationTargetPrefix + "scripts/prepare-codedb-project-runtime.ps1")
    $watcherBuilder = Get-PathFromRelative `
        -Root $uninstallHostRoot `
        -RelativePath ($generationTargetPrefix + "scripts/build-codedb-project-text-adapter.ps1")
    $providerRoot = Join-Path $uninstallHostRoot "AIWork\.runtime\codedb\codedb-$projectSlug"
    $providerExecutable = Join-Path $providerRoot "bin\codebase-mcp.exe"
    $adapterManifest = Join-Path $providerRoot "adapter\text-index\manifest.json"
    $watcherStatePath = Join-Path $providerRoot "watch\coordinator\coordinator-state.json"
    $editorLeaseRoot = Join-Path $providerRoot "watch\lifecycle\editor-leases"
    $editorLease = $null
    $watcherProcessId = 0
    $watcherLifecycleId = $null
    $watcherUninstallDeferred = $false
    try {
        New-FixtureProviderExecutable -Path $providerExecutable
        Assert-Result `
            -Result (Invoke-PowerShellAction -Root $uninstallHostRoot -Action { & $watcherPrepare }) `
            -ExitCode 0 `
            -Label "Uninstall watcher runtime preparation"
        Assert-Result `
            -Result (Invoke-PowerShellAction -Root $uninstallHostRoot -Action { & $watcherBuilder -Reason Manual }) `
            -ExitCode 0 `
            -Label "Uninstall watcher adapter build"
        $editorLease = New-TestEditorLease `
            -LeaseRoot $editorLeaseRoot `
            -Root $uninstallHostRoot `
            -SessionId "uninstall-generation-editor"
        $watcherStart = Invoke-PowerShellAction -Root $uninstallHostRoot -Action {
            & $watcherManager -Action Ensure
        }
        if (Test-AllowedSpawnEpermDeferral -Result $watcherStart) {
            $watcherUninstallDeferred = $true
            Write-Host "[DEFERRED] Authenticated watcher Uninstall integration could not spawn its detached Node coordinator in the current managed test environment."
        } else {
            Assert-Result -Result $watcherStart -ExitCode 0 -Label "Uninstall authenticated watcher start"
            $watcherStatus = Get-LastJsonObject -Result $watcherStart -Label "Uninstall authenticated watcher start"
            $watcherProcessId = [int]$watcherStatus.coordinator_pid
            $watcherLifecycleId = [string]$watcherStatus.lifecycle_id
            Assert-True -Condition ($watcherProcessId -gt 0) -Message "Uninstall watcher did not publish a coordinator PID."
            Assert-True -Condition (Test-Path -LiteralPath $watcherStatePath -PathType Leaf) -Message "Uninstall watcher did not publish coordinator state."
            $providerBefore = Get-ByteSnapshot -Path $providerExecutable
            $adapterBefore = Get-ByteSnapshot -Path $adapterManifest
            $businessBeforeWatcherUninstall = Get-ByteSnapshot -Path (Join-Path $uninstallHostRoot "Assets\BusinessSentinel.txt")

            $watcherUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
            Assert-Result -Result $watcherUninstall -ExitCode 0 -Label "Authenticated watcher Uninstall"
            Assert-True -Condition (-not $watcherUninstall.Text.Contains("[STOPPING]")) -Message "Logical Uninstall attempted to Stop the active watcher."
            Assert-True -Condition ($watcherUninstall.Text.Contains("[CLEANUP_STATE] PENDING")) -Message "Watcher Uninstall did not retain cleanup as PENDING."
            Assert-True -Condition ($null -ne (Get-Process -Id $watcherProcessId -ErrorAction SilentlyContinue)) -Message "Logical Uninstall terminated the authenticated watcher coordinator."
            Assert-True -Condition (Test-Path -LiteralPath $watcherStatePath -PathType Leaf) -Message "Logical Uninstall removed active watcher state."
            Assert-Equal -Actual (Get-ByteSnapshot -Path $providerExecutable) -Expected $providerBefore -Message "Uninstall changed the Provider executable."
            Assert-Equal -Actual (Get-ByteSnapshot -Path $adapterManifest) -Expected $adapterBefore -Message "Uninstall changed the adapter manifest."
            Assert-Equal -Actual (Get-ByteSnapshot -Path (Join-Path $uninstallHostRoot "Assets\BusinessSentinel.txt")) -Expected $businessBeforeWatcherUninstall -Message "Watcher Uninstall changed a business file."
        }
    } finally {
        if ($watcherProcessId -gt 0 -and $null -ne (Get-Process -Id $watcherProcessId -ErrorAction SilentlyContinue)) {
            $watcherStop = Invoke-PowerShellAction -Root $uninstallHostRoot -Action {
                & $watcherManager -Action Stop -ExpectedLifecycleId $watcherLifecycleId
            }
            Assert-Result -Result $watcherStop -ExitCode 0 -Label "Uninstall watcher test cleanup"
        }
        if ($null -ne $editorLease) {
            Remove-Item -LiteralPath $editorLease -Force -ErrorAction SilentlyContinue
        }
    }
    $ownerFreeWatcherCleanup = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $ownerFreeWatcherCleanup -ExitCode 0 -Label "Owner-free automatic cleanup after watcher drain"
    Assert-True -Condition ($ownerFreeWatcherCleanup.Text.Contains("[CLEANUP_STATE] COMPLETE")) -Message "Automatic cleanup did not complete after the watcher drained."
    if (-not $watcherUninstallDeferred) {
        Write-Host "[OK] Logical Uninstall preserved the active watcher and its closure; automatic cleanup completed after fixture-owned drain."
    }

    $reinstall = Invoke-Materializer -Action "Install" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $reinstall -ExitCode 0 -Label "Pre-crash reinstall"
    $crashedUninstall = Invoke-Materializer `
        -Action "Uninstall" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $uninstallHostRoot `
        -TestCrashAfterMutation 1
    Assert-Result -Result $crashedUninstall -ExitCode 86 -Label "Uninstall desired-state crash"
    Assert-True -Condition (Test-Path -LiteralPath $desiredStatePath -PathType Leaf) -Message "Uninstall crash did not durably publish UNINSTALLED desired state first."
    $crashRetry = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $uninstallHostRoot
    Assert-Result -Result $crashRetry -ExitCode 0 -Label "Uninstall crash retry"
    Assert-True -Condition ($crashRetry.Text.Contains("[RESULT] UNINSTALLED")) -Message "Uninstall crash retry did not converge."
    Assert-True -Condition ($crashRetry.Text.Contains("[CLEANUP_STATE] COMPLETE")) -Message "Uninstall crash retry did not finish cleanup."
    Write-Host "[OK] Uninstall desired-state publication survived process crash and converged idempotently on retry."
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
        [int]$PayloadSequence = 16,
        [string]$Root = $hostRoot
    )

    if ([string]::Equals([System.IO.Path]::GetFullPath($Root), [System.IO.Path]::GetFullPath($hostRoot), [StringComparison]::OrdinalIgnoreCase)) {
        Clear-ManagedTestState
    } else {
        foreach ($relativePath in $managedTargets + @($markerRelativePath)) {
            $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force }
        }
    }
    $reviewedTag = switch ($PackageVersion) {
        "0.1.0" { "v0.1.0" }
        "0.2.0" { "v0.2.0" }
        "0.2.1" { "v0.2.1" }
        default { throw "No reviewed legacy payload fixture tag is mapped for Package $PackageVersion." }
    }
    $reviewedSourceRoot = Get-ReviewedLegacyPayloadFixtureRoot -Tag $reviewedTag
    $reviewedManifest = Get-Content -LiteralPath (Join-Path $reviewedSourceRoot "payload-manifest.json") -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$reviewedManifest.package_version) -Expected $PackageVersion -Message "Reviewed legacy Package fixture identity mismatch."
    $reviewedTargets = @($reviewedManifest.files | ForEach-Object { [string]$_.target })
    foreach ($relativePath in $reviewedTargets) {
        $source = Get-PathFromRelative -Root $reviewedSourceRoot -RelativePath $relativePath
        $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
    $legacyFiles = @($reviewedTargets | Sort-Object | ForEach-Object {
        $target = Get-PathFromRelative -Root $Root -RelativePath $_
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
        -Path (Get-PathFromRelative -Root $Root -RelativePath $markerRelativePath) `
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
        [string]$PackageVersion = "0.2.5-preview.5",
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

    $providerContractTarget = "AIWork/codedb/shared/codedb-machine-provider-contract.ps1"
    $providerContractEntry = @($manifestFiles | Where-Object {
        [string]::Equals([string]$_.target, $providerContractTarget, [StringComparison]::OrdinalIgnoreCase)
    }) | Select-Object -First 1
    if ($null -eq $providerContractEntry) {
        $providerContractSource = [string]$canonicalSourceByTarget[$providerContractTarget]
        $providerContractSourcePath = Get-CanonicalPayloadSourcePath -TargetRelativePath $providerContractTarget
        $providerContractPayloadPath = Get-PathFromRelative -Root $Root -RelativePath $providerContractSource
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $providerContractPayloadPath) | Out-Null
        Copy-Item -LiteralPath $providerContractSourcePath -Destination $providerContractPayloadPath -Force
        $manifestFiles.Add([ordered]@{
            source = $providerContractSource
            target = $providerContractTarget
            sha256 = (Get-FileHash -LiteralPath $providerContractPayloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
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
        control_contract = $canonicalPayloadManifest.control_contract
        package_version = $PackageVersion
        payload_version = $PayloadVersion
        payload_sequence = $resolvedPayloadSequence
        generation_id = $generationId
        bootstrap_protocol = 1
        bootstrap_transitions = @()
        current_pointer_target = $currentPointerRelativePath
        retired_targets = @()
        files = $manifestFiles.ToArray()
    }
    Write-Utf8File -Path (Join-Path $Root "payload-manifest.json") -Content (($manifest | ConvertTo-Json -Depth 8) + "`n")
    return $Root
}

function Invoke-ActivationContractFoundationScenarios {
    $parseErrors = $null
    $parseTokens = $null
    $materializerAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $materializerPath,
        [ref]$parseTokens,
        [ref]$parseErrors)
    Assert-Equal -Actual @($parseErrors).Count -Expected 0 -Message "Materializer source did not parse for focused function loading."
    foreach ($statement in $materializerAst.EndBlock.Statements) {
        if ($statement -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            . ([scriptblock]::Create($statement.Extent.Text))
        }
    }
    $instanceEnginePath = Join-Path $packageRoot "Tools~\codedb-instance-engine.ps1"
    . $instanceEnginePath

    $script:ManagedBy = "com.rice.ai-codedb"
    $script:RequestedExitCode = 0
    $script:CurrentPointerRelativePath = "AIWork/.runtime/codedb/host/current.json"
    $script:LastKnownGoodPointerRelativePath = "AIWork/.runtime/codedb/host/last-known-good.json"
    $script:MarkerRelativePath = $markerRelativePath
    $script:IntegrationStateRelativePath = "AIWork/.runtime/codedb/payload-materializer/integration-state.json"
    $script:McpConfigRelativePath = ".codex/config.toml"
    $script:TargetPrefix = "AIWork/codedb/"
    $script:AllowedTargetPaths = @{}

    $manifestJson = Read-BoundedJsonDocument `
        -Path $canonicalPayloadManifestPath `
        -Label "focused Package runtime contract" `
        -MaximumBytes (1024 * 1024)
    $controlContract = Read-InstanceControlContractIdentity -ManifestDocument $manifestJson.Document
    Assert-Equal -Actual $controlContract.CanonicalIdentity -Expected "com.rice.ai-codedb`ncontrol-contract`nv0.3-control`n1`n1" -Message "PowerShell control-contract canonical identity diverged from C#/Node."
    Assert-Equal -Actual $controlContract.Sha256 -Expected "7c85ebc534091fcb53d40eedd9eadf869c09caf77fb56a35aeb22e0e8aea09a1" -Message "PowerShell control-contract SHA-256 diverged from C#/Node."
    Assert-Equal `
        -Actual $manifestJson.Sha256 `
        -Expected (Get-FileHash -LiteralPath $canonicalPayloadManifestPath -Algorithm SHA256).Hash.ToLowerInvariant() `
        -Message "runtime_contract_sha256 is not derived from the trusted raw manifest bytes."
    $materializerSource = [System.IO.File]::ReadAllText($materializerPath)
    Assert-True `
        -Condition ($materializerSource.IndexOf('Read-InstanceControlContractIdentity -ManifestDocument $document', [StringComparison]::Ordinal) -ge 0 -and
            $materializerSource.IndexOf('RuntimeContractSha256 = $manifestJson.Sha256', [StringComparison]::Ordinal) -ge 0) `
        -Message "Read-PayloadManifest is not wired to the strict control identity and raw-byte runtime hash."

    $invalidManifest = [pscustomobject]@{
        control_contract = [pscustomobject]@{
            id = "v0.3-control"
            version = [int64]1
            schema_version = [int64]1
            sha256 = $controlContract.Sha256.ToUpperInvariant()
        }
    }
    Assert-ThrowsMessage `
        -Action { Read-InstanceControlContractIdentity -ManifestDocument $invalidManifest } `
        -ExpectedMessage "lowercase SHA-256" `
        -Label "Uppercase manifest control hash"
    $invalidManifest.control_contract.sha256 = "0" * 64
    Assert-ThrowsMessage `
        -Action { Read-InstanceControlContractIdentity -ManifestDocument $invalidManifest } `
        -ExpectedMessage "identity hash is invalid" `
        -Label "Mismatched manifest control hash"
    $invalidManifest.control_contract.sha256 = $controlContract.Sha256
    $invalidManifest.control_contract | Add-Member -NotePropertyName unsupported -NotePropertyValue "blocked"
    Assert-ThrowsMessage `
        -Action { Read-InstanceControlContractIdentity -ManifestDocument $invalidManifest } `
        -ExpectedMessage "exact field set" `
        -Label "Expanded manifest control field set"

    $activationRoot = Join-Path $runRoot "activation-contract-fixture"
    New-TestHost -Root $activationRoot
    foreach ($legacyRelativePath in @(
            "AIWork/.runtime/codedb/control/current-instance.json",
            "AIWork/.runtime/codedb/control/last-known-good-instance.json",
            "AIWork/.runtime/codedb/control/operation.json")) {
        Write-Utf8File -Path (Get-PathFromRelative -Root $activationRoot -RelativePath $legacyRelativePath) -Content "{`"legacy_sentinel`":true}`n"
    }
    $protectedRelativePaths = @(
        ".codex/config.toml",
        "AIWork/.runtime/codedb/control/current-instance.json",
        "AIWork/.runtime/codedb/control/last-known-good-instance.json",
        "AIWork/.runtime/codedb/control/operation.json"
    )
    $protectedBefore = @{}
    foreach ($relativePath in $protectedRelativePaths) {
        $protectedBefore[$relativePath] = (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $activationRoot -RelativePath $relativePath) -Algorithm SHA256).Hash
    }

    $attempt = [pscustomobject]@{
        ActivationEpoch = "11111111111111111111111111111111"
        OperationId = "22222222222222222222222222222222"
    }
    $retryAttempt = New-InstanceActivationAttemptIdentity
    $secondRetryAttempt = New-InstanceActivationAttemptIdentity
    $null = Assert-InstanceActivationAttemptIdentity -Attempt $retryAttempt
    $null = Assert-InstanceActivationAttemptIdentity -Attempt $secondRetryAttempt
    Assert-True `
        -Condition (-not [string]::Equals($retryAttempt.ActivationEpoch, $secondRetryAttempt.ActivationEpoch, [StringComparison]::Ordinal) -and
            -not [string]::Equals($retryAttempt.OperationId, $secondRetryAttempt.OperationId, [StringComparison]::Ordinal)) `
        -Message "A retry reused an activation epoch or operation id."
    $targetGenerationId = [string]$canonicalPayloadManifest.generation_id
    $targetGenerationManifestTarget = "AIWork/.runtime/codedb/host/generations/$targetGenerationId/generation-manifest.json"
    $targetGenerationManifestEntries = @($canonicalPayloadManifest.files | Where-Object {
        [string]$_.target -ceq $targetGenerationManifestTarget
    })
    Assert-Equal -Actual $targetGenerationManifestEntries.Count -Expected 1 -Message "Canonical payload did not declare exactly one current generation manifest."
    $targetGenerationManifestSha256 = [string]$targetGenerationManifestEntries[0].sha256
    $manifest = [pscustomobject]@{
        ControlContract = $controlContract
        RuntimeContractSha256 = $manifestJson.Sha256
        TargetGenerationId = $targetGenerationId
        TargetGenerationManifestSha256 = $targetGenerationManifestSha256
    }
    $context = New-InstanceActivationContractContext `
        -Manifest $manifest `
        -ProjectRoot $activationRoot `
        -OperationId $attempt.OperationId
    Assert-Equal -Actual $context.Paths.ActivationRelativePath -Expected "AIWork/.runtime/codedb/control/contracts/v0.3-control/v1/activation.json" -Message "Activation record path diverged from the contract identity."
    Assert-Equal -Actual $context.Paths.OperationRelativePath -Expected "AIWork/.runtime/codedb/control/contracts/v0.3-control/v1/operation.json" -Message "Operation journal path diverged from the contract identity."
    Assert-Equal -Actual $context.Paths.OperationRootRelativePath -Expected "AIWork/.runtime/codedb/control/contracts/v0.3-control/v1/operations/22222222222222222222222222222222" -Message "Operation evidence path diverged from the attempt identity."
    Assert-Equal -Actual $context.Paths.SupervisorRelativePath -Expected "AIWork/.runtime/codedb/control/contracts/v0.3-control/v1/supervisor" -Message "Supervisor path diverged from C#/Node routing."

    $candidate = New-InstanceActivationEvidence `
        -InstanceId "33333333333333333333333333333333" `
        -GenerationId $targetGenerationId `
        -InstanceManifestSha256 ("a" * 64) `
        -GenerationManifestSha256 $targetGenerationManifestSha256 `
        -GenerationDisposition "CURRENT"
    $current = New-InstanceActivationEvidence `
        -InstanceId "44444444444444444444444444444444" `
        -GenerationId "poc.32" `
        -InstanceManifestSha256 ("c" * 64) `
        -GenerationManifestSha256 ("d" * 64) `
        -GenerationDisposition "TRUSTED_PREVIOUS"
    $lastKnownGood = New-InstanceActivationEvidence `
        -InstanceId "55555555555555555555555555555555" `
        -GenerationId "poc.32" `
        -InstanceManifestSha256 ("e" * 64) `
        -GenerationManifestSha256 ("f" * 64) `
        -GenerationDisposition "TRUSTED_PREVIOUS"
    $mutation = New-InstanceActivationMutationEvidence `
        -Index 0 `
        -Target $script:InstanceCurrentRelativePath `
        -Mutation Write `
        -DesiredSha256 ("1" * 64) `
        -ExistedBefore $true `
        -PreImageSha256 ("2" * 64)
    $timestamp = "2026-09-03T09:00:00.0000000Z"
    $activationDocument = New-InstanceActivationRecordDocument `
        -Context $context `
        -Attempt $attempt `
        -Candidate $candidate `
        -Current $current `
        -LastKnownGood $lastKnownGood `
        -PublicationPhase PREPARED `
        -TimestampUtc $timestamp
    $operationDocument = New-InstanceActivationOperationDocument `
        -Context $context `
        -Attempt $attempt `
        -Action UPGRADE `
        -Candidate $candidate `
        -PreviousActivationRecordSha256 $null `
        -Phase PREPARED `
        -Mutations @($mutation) `
        -TimestampUtc $timestamp

    $missingTargetGenerationManifest = [pscustomobject]@{
        ControlContract = $controlContract
        RuntimeContractSha256 = $manifestJson.Sha256
        TargetGenerationId = $null
        TargetGenerationManifestSha256 = $targetGenerationManifestSha256
    }
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationContractContext -Manifest $missingTargetGenerationManifest -ProjectRoot $activationRoot -OperationId $attempt.OperationId } `
        -ExpectedMessage "no valid current target generation" `
        -Label "Missing trusted target generation"
    $missingTargetHashManifest = [pscustomobject]@{
        ControlContract = $controlContract
        RuntimeContractSha256 = $manifestJson.Sha256
        TargetGenerationId = $targetGenerationId
        TargetGenerationManifestSha256 = $null
    }
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationContractContext -Manifest $missingTargetHashManifest -ProjectRoot $activationRoot -OperationId $attempt.OperationId } `
        -ExpectedMessage "target generation manifest hash must be a lowercase SHA-256" `
        -Label "Missing trusted target generation manifest hash"

    $wrongGenerationCandidate = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $candidate) `
        -Label "wrong-generation candidate fixture"
    $wrongGenerationCandidate.generation_id = "poc.999"
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $wrongGenerationCandidate -Current $current -LastKnownGood $lastKnownGood -PublicationPhase PREPARED -TimestampUtc $timestamp } `
        -ExpectedMessage "does not match the trusted current target generation" `
        -Label "Non-target activation candidate generation"
    $wrongGenerationHashCandidate = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $candidate) `
        -Label "wrong-generation-hash candidate fixture"
    $wrongGenerationHashCandidate.generation_manifest_sha256 = "9" * 64
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $wrongGenerationHashCandidate -Current $current -LastKnownGood $lastKnownGood -PublicationPhase PREPARED -TimestampUtc $timestamp } `
        -ExpectedMessage "does not match the trusted current target generation" `
        -Label "Non-target activation candidate manifest hash"
    $nonCurrentCandidate = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $candidate) `
        -Label "non-current candidate fixture"
    $nonCurrentCandidate.generation_disposition = "NEWER"
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $nonCurrentCandidate -Current $current -LastKnownGood $lastKnownGood -PublicationPhase PREPARED -TimestampUtc $timestamp } `
        -ExpectedMessage "does not match the trusted current target generation" `
        -Label "Non-current activation candidate disposition"
    foreach ($unsafeDisposition in @("NEWER", "SEQUENCE_COLLISION", "INVALID")) {
        $unsafeCurrent = ConvertFrom-StrictJsonText `
            -Text (ConvertTo-InstanceJsonText -Value $current) `
            -Label "unsafe current fixture"
        $unsafeCurrent.generation_disposition = $unsafeDisposition
        Assert-ThrowsMessage `
            -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $candidate -Current $unsafeCurrent -LastKnownGood $lastKnownGood -PublicationPhase PREPARED -TimestampUtc $timestamp } `
            -ExpectedMessage "current/LKG evidence has an unsafe generation disposition" `
            -Label "Unsafe current activation disposition $unsafeDisposition"
        $unsafeLastKnownGood = ConvertFrom-StrictJsonText `
            -Text (ConvertTo-InstanceJsonText -Value $lastKnownGood) `
            -Label "unsafe last-known-good fixture"
        $unsafeLastKnownGood.generation_disposition = $unsafeDisposition
        Assert-ThrowsMessage `
            -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $candidate -Current $current -LastKnownGood $unsafeLastKnownGood -PublicationPhase PREPARED -TimestampUtc $timestamp } `
            -ExpectedMessage "current/LKG evidence has an unsafe generation disposition" `
            -Label "Unsafe last-known-good activation disposition $unsafeDisposition"
    }
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $candidate -Current $null -LastKnownGood $lastKnownGood -PublicationPhase COMMITTED -TimestampUtc $timestamp } `
        -ExpectedMessage "must select the complete candidate identity as current" `
        -Label "Committed activation without current"
    $mismatchedCommittedCurrent = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $candidate) `
        -Label "mismatched committed current fixture"
    $mismatchedCommittedCurrent.instance_manifest_sha256 = "8" * 64
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationRecordDocument -Context $context -Attempt $attempt -Candidate $candidate -Current $mismatchedCommittedCurrent -LastKnownGood $lastKnownGood -PublicationPhase COMMITTED -TimestampUtc $timestamp } `
        -ExpectedMessage "must select the complete candidate identity as current" `
        -Label "Committed activation with incomplete candidate match"
    $null = New-InstanceActivationRecordDocument `
        -Context $context `
        -Attempt $attempt `
        -Candidate $candidate `
        -Current $null `
        -LastKnownGood $null `
        -PublicationPhase ACTIVATING `
        -TimestampUtc $timestamp

    $duplicateMutation = New-InstanceActivationMutationEvidence `
        -Index 1 `
        -Target $script:InstanceCurrentRelativePath `
        -Mutation Write `
        -DesiredSha256 ("3" * 64) `
        -ExistedBefore $true `
        -PreImageSha256 ("4" * 64)
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationOperationDocument -Context $context -Attempt $attempt -Action UPGRADE -Candidate $candidate -PreviousActivationRecordSha256 $null -Phase PREPARED -Mutations @($mutation, $duplicateMutation) -TimestampUtc $timestamp } `
        -ExpectedMessage "duplicate mutation target" `
        -Label "Duplicate activation journal mutation target"
    $nonContiguousMutation = New-InstanceActivationMutationEvidence `
        -Index 2 `
        -Target $script:LastKnownGoodPointerRelativePath `
        -Mutation Write `
        -DesiredSha256 ("5" * 64) `
        -ExistedBefore $true `
        -PreImageSha256 ("6" * 64)
    Assert-ThrowsMessage `
        -Action { New-InstanceActivationOperationDocument -Context $context -Attempt $attempt -Action UPGRADE -Candidate $candidate -PreviousActivationRecordSha256 $null -Phase PREPARED -Mutations @($mutation, $nonContiguousMutation) -TimestampUtc $timestamp } `
        -ExpectedMessage "not in exact index order" `
        -Label "Non-contiguous activation journal mutation index"

    $first = Initialize-FreshInstanceActivationContract `
        -Context $context `
        -ActivationDocument $activationDocument `
        -OperationDocument $operationDocument
    Assert-True -Condition $first.Created -Message "Fresh activation contract provisioning did not report creation."
    Assert-Equal -Actual $first.Activation.Sha256 -Expected (Get-FileHash -LiteralPath $context.Paths.ActivationPath -Algorithm SHA256).Hash.ToLowerInvariant() -Message "Activation record hash evidence mismatch."
    Assert-Equal -Actual $first.Operation.Sha256 -Expected (Get-FileHash -LiteralPath $context.Paths.OperationPath -Algorithm SHA256).Hash.ToLowerInvariant() -Message "Operation journal hash evidence mismatch."
    Assert-True -Condition (Test-Path -LiteralPath $context.Paths.OperationRoot -PathType Container) -Message "Exact operation evidence directory was not provisioned."
    Assert-Equal -Actual @(Get-ChildItem -LiteralPath $context.Paths.OperationRoot -Force).Count -Expected 0 -Message "Fresh operation evidence directory was not empty."
    Assert-True -Condition (-not (Test-Path -LiteralPath $context.Paths.SupervisorRoot)) -Message "Foundation provisioning created Supervisor state."
    $contractFiles = @(Get-ChildItem -LiteralPath $context.Paths.ContractRoot -Recurse -Force -File | ForEach-Object {
        Get-RelativeFilePath -Root $context.Paths.ContractRoot -Path $_.FullName
    } | Sort-Object)
    Assert-Equal -Actual ($contractFiles -join "|") -Expected "activation.json|operation.json" -Message "Fresh provisioning wrote outside the two contract records."
    Assert-True -Condition (-not ([System.IO.File]::ReadAllText($context.Paths.ActivationPath).Contains("READY"))) -Message "Activation foundation emitted reserved READY state."
    Assert-True -Condition (-not ([System.IO.File]::ReadAllText($context.Paths.OperationPath).Contains("READY"))) -Message "Operation foundation emitted reserved READY state."
    $snapshotAfterFirst = Get-FileSnapshot -Root $context.Paths.ContractRoot
    $repeat = Initialize-FreshInstanceActivationContract `
        -Context $context `
        -ActivationDocument $activationDocument `
        -OperationDocument $operationDocument
    Assert-True -Condition (-not $repeat.Created) -Message "Identical activation contract repeat was not idempotent."
    Assert-Equal -Actual (Get-FileSnapshot -Root $context.Paths.ContractRoot) -Expected $snapshotAfterFirst -Message "Identical activation contract repeat changed durable evidence."
    foreach ($relativePath in $protectedRelativePaths) {
        Assert-Equal `
            -Actual (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $activationRoot -RelativePath $relativePath) -Algorithm SHA256).Hash `
            -Expected $protectedBefore[$relativePath] `
            -Message "Activation foundation changed protected legacy/config input: $relativePath"
    }

    $assertFreshNamespaceRejects = {
        param(
            [Parameter(Mandatory = $true)][string]$Suffix,
            [Parameter(Mandatory = $true)][scriptblock]$Arrange,
            [Parameter(Mandatory = $true)][string]$ExpectedMessage
        )

        $fixtureRoot = Join-Path $runRoot "activation-not-fresh-$Suffix"
        New-TestHost -Root $fixtureRoot
        $fixtureContext = New-InstanceActivationContractContext `
            -Manifest $manifest `
            -ProjectRoot $fixtureRoot `
            -OperationId $attempt.OperationId
        $fixtureActivation = New-InstanceActivationRecordDocument `
            -Context $fixtureContext `
            -Attempt $attempt `
            -Candidate $candidate `
            -Current $current `
            -LastKnownGood $lastKnownGood `
            -PublicationPhase PREPARED `
            -TimestampUtc $timestamp
        $fixtureOperation = New-InstanceActivationOperationDocument `
            -Context $fixtureContext `
            -Attempt $attempt `
            -Action UPGRADE `
            -Candidate $candidate `
            -PreviousActivationRecordSha256 $null `
            -Phase PREPARED `
            -Mutations @($mutation) `
            -TimestampUtc $timestamp
        & $Arrange $fixtureContext
        Assert-ThrowsMessage `
            -Action { Initialize-FreshInstanceActivationContract -Context $fixtureContext -ActivationDocument $fixtureActivation -OperationDocument $fixtureOperation } `
            -ExpectedMessage $ExpectedMessage `
            -Label "Non-fresh activation namespace $Suffix"
    }
    & $assertFreshNamespaceRejects `
        -Suffix "supervisor" `
        -Arrange {
            param($fixtureContext)
            New-Item -ItemType Directory -Force -Path $fixtureContext.Paths.SupervisorRoot | Out-Null
        } `
        -ExpectedMessage "namespace is not fresh"
    & $assertFreshNamespaceRejects `
        -Suffix "unknown-file" `
        -Arrange {
            param($fixtureContext)
            Write-Utf8File -Path (Join-Path $fixtureContext.Paths.ContractRoot "unknown.json") -Content "{}`n"
        } `
        -ExpectedMessage "namespace is not fresh"
    & $assertFreshNamespaceRejects `
        -Suffix "unknown-directory" `
        -Arrange {
            param($fixtureContext)
            New-Item -ItemType Directory -Force -Path (Join-Path $fixtureContext.Paths.ContractRoot "unknown") | Out-Null
        } `
        -ExpectedMessage "namespace is not fresh"
    & $assertFreshNamespaceRejects `
        -Suffix "other-operation" `
        -Arrange {
            param($fixtureContext)
            New-Item `
                -ItemType Directory `
                -Force `
                -Path (Join-Path (Split-Path -Parent $fixtureContext.Paths.OperationRoot) "77777777777777777777777777777777") | Out-Null
        } `
        -ExpectedMessage "unexpected operation entry"
    & $assertFreshNamespaceRejects `
        -Suffix "nonempty-operation" `
        -Arrange {
            param($fixtureContext)
            Write-Utf8File -Path (Join-Path $fixtureContext.Paths.OperationRoot "evidence.json") -Content "{}`n"
        } `
        -ExpectedMessage "contains unexpected evidence"

    $mismatchedOperation = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $operationDocument) `
        -Label "mismatched operation fixture"
    $mismatchedOperation.activation_epoch = "66666666666666666666666666666666"
    Assert-ThrowsMessage `
        -Action { Initialize-FreshInstanceActivationContract -Context $context -ActivationDocument $activationDocument -OperationDocument $mismatchedOperation } `
        -ExpectedMessage "identities do not match" `
        -Label "Cross-record activation epoch mismatch"
    $readyActivation = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $activationDocument) `
        -Label "READY activation fixture"
    $readyActivation.publication_phase = "READY"
    Assert-ThrowsMessage `
        -Action { Assert-InstanceActivationRecordDocument -Document $readyActivation -Context $context } `
        -ExpectedMessage "publication phase is invalid" `
        -Label "Reserved READY activation phase"
    $expandedOperation = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $operationDocument) `
        -Label "expanded operation fixture"
    $expandedOperation | Add-Member -NotePropertyName unsupported -NotePropertyValue $true
    Assert-ThrowsMessage `
        -Action { Assert-InstanceActivationOperationDocument -Document $expandedOperation -Context $context } `
        -ExpectedMessage "exact field set" `
        -Label "Expanded operation field set"
    $badHashOperation = ConvertFrom-StrictJsonText `
        -Text (ConvertTo-InstanceJsonText -Value $operationDocument) `
        -Label "bad-hash operation fixture"
    $badHashOperation.mutations[0].pre_image_sha256 = "A" * 64
    Assert-ThrowsMessage `
        -Action { Assert-InstanceActivationOperationDocument -Document $badHashOperation -Context $context } `
        -ExpectedMessage "lowercase SHA-256" `
        -Label "Uppercase operation evidence hash"
    [System.IO.File]::AppendAllText($context.Paths.ActivationPath, "`n", $utf8NoBom)
    Assert-ThrowsMessage `
        -Action { Initialize-FreshInstanceActivationContract -Context $context -ActivationDocument $activationDocument -OperationDocument $operationDocument } `
        -ExpectedMessage "conflicts with the immutable activation attempt" `
        -Label "Conflicting existing activation record"

    $invalidRoot = Join-Path $runRoot "activation-invalid-fixture"
    New-TestHost -Root $invalidRoot
    $invalidContext = New-InstanceActivationContractContext `
        -Manifest $manifest `
        -ProjectRoot $invalidRoot `
        -OperationId $attempt.OperationId
    Write-Utf8File -Path $invalidContext.Paths.ActivationPath -Content "{"
    Assert-ThrowsMessage `
        -Action { Read-InstanceActivationRecord -Context $invalidContext } `
        -ExpectedMessage "not valid JSON" `
        -Label "Malformed activation record"
    Write-Utf8File -Path $invalidContext.Paths.ActivationPath -Content ("x" * ($script:InstanceActivationRecordMaximumBytes + 1))
    Assert-ThrowsMessage `
        -Action { Read-InstanceActivationRecord -Context $invalidContext } `
        -ExpectedMessage "size is outside the accepted range" `
        -Label "Oversized activation record"

    $redirectRoot = Join-Path $runRoot "activation-redirect-fixture"
    New-TestHost -Root $redirectRoot
    $redirectTarget = Join-Path $runRoot "activation-redirect-target"
    New-Item -ItemType Directory -Force -Path $redirectTarget | Out-Null
    $contractsRoot = Get-PathFromRelative -Root $redirectRoot -RelativePath "AIWork/.runtime/codedb/control/contracts"
    New-Item -ItemType Directory -Force -Path $contractsRoot | Out-Null
    $redirectPath = Join-Path $contractsRoot $controlContract.Id
    try {
        New-Item -ItemType Junction -Path $redirectPath -Target $redirectTarget | Out-Null
        Assert-ThrowsMessage `
            -Action { Get-InstanceActivationContractPaths -ProjectRoot $redirectRoot -ControlContract $controlContract -OperationId $attempt.OperationId } `
            -ExpectedMessage "reparse point" `
            -Label "Redirected activation namespace"
    } finally {
        if (Test-Path -LiteralPath $redirectPath) {
            $redirectItem = Get-Item -LiteralPath $redirectPath -Force
            Assert-True -Condition (($redirectItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) -Message "Activation redirect fixture changed type."
            [System.IO.Directory]::Delete($redirectPath)
        }
    }

    Write-Host "[OK] Versioned activation contract identity, paths, strict records, fresh provisioning, idempotence, and fail-closed boundaries passed."
}

function Invoke-ActivationTransactionScenarios {
    $parseErrors = $null
    $parseTokens = $null
    $materializerAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $materializerPath,
        [ref]$parseTokens,
        [ref]$parseErrors)
    Assert-Equal -Actual @($parseErrors).Count -Expected 0 -Message "Materializer source did not parse for focused activation transaction loading."
    foreach ($statement in $materializerAst.EndBlock.Statements) {
        if ($statement -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            . ([scriptblock]::Create($statement.Extent.Text))
        }
    }
    $instanceEnginePath = Join-Path $packageRoot "Tools~\codedb-instance-engine.ps1"
    . $instanceEnginePath
    Assert-True `
        -Condition ($null -ne (Get-Command -Name Read-InstanceControlContractIdentity -CommandType Function -ErrorAction SilentlyContinue)) `
        -Message "Activation transaction fixture did not load the instance engine contract helpers."
    $script:ManagedBy = "com.rice.ai-codedb"
    $script:RequestedExitCode = 0
    $script:CurrentPointerRelativePath = "AIWork/.runtime/codedb/host/current.json"
    $script:LastKnownGoodPointerRelativePath = "AIWork/.runtime/codedb/host/last-known-good.json"
    $script:MarkerRelativePath = $markerRelativePath
    $script:IntegrationStateRelativePath = "AIWork/.runtime/codedb/payload-materializer/integration-state.json"
    $script:McpConfigRelativePath = ".codex/config.toml"
    $script:TargetPrefix = "AIWork/codedb/"
    $script:AllowedTargetPaths = @{
        "AIWork/codedb/wrapper/codedb-project-wrapper.mjs" = $true
    }

    $prior = Install-TrustedPreviousInstanceFixture
    $selectionPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/control/current-instance.json"
    $selectionBefore = Get-Content -LiteralPath $selectionPath -Raw | ConvertFrom-Json
    $oldInstanceRoot = Get-PathFromRelative -Root $hostRoot -RelativePath ([string]$selectionBefore.instance_relative_path)
    $externalSentinelRelativePath = "AIWork/codedb/legacy-external-mcp.sentinel"
    Write-Utf8File `
        -Path (Get-PathFromRelative -Root $hostRoot -RelativePath $externalSentinelRelativePath) `
        -Content "external MCP and legacy state sentinel`n"

    $protectedRelativePaths = @(
        ".codex/config.toml",
        "AIWork/.runtime/codedb/host/current.json",
        "AIWork/.runtime/codedb/control/current-instance.json",
        "AIWork/.runtime/codedb/control/last-known-good-instance.json",
        "AIWork/.runtime/codedb/control/desired-state.json",
        "AIWork/codedb/wrapper/codedb-project-wrapper.mjs",
        $externalSentinelRelativePath
    )
    $protectedBefore = Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $protectedRelativePaths
    $oldInstanceBefore = Get-FileSnapshot -Root $oldInstanceRoot
    $oldGenerationBefore = Get-FileSnapshot -Root $prior.GenerationRoot
    $legacyOperationPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/control/operation.json"
    $canonicalManifestJson = Read-BoundedJsonDocument `
        -Path $canonicalPayloadManifestPath `
        -Label "focused activation transaction Package manifest" `
        -MaximumBytes (1024 * 1024)
    $controlContract = Read-InstanceControlContractIdentity -ManifestDocument $canonicalManifestJson.Document
    $activationManifest = [pscustomobject]@{
        ControlContract = $controlContract
        RuntimeContractSha256 = (Get-FileHash -LiteralPath $canonicalPayloadManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        TargetGenerationId = $generationId
        TargetGenerationManifestSha256 = (Get-FileHash -LiteralPath (Get-CanonicalPayloadSourcePath -TargetRelativePath ($generationTargetPrefix + "generation-manifest.json")) -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $contractRoot = Get-InstanceActivationContractRoot -Manifest $activationManifest -ProjectRoot $hostRoot

    $candidateFailure = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TestFailInstanceCandidate
    Assert-Result -Result $candidateFailure -ExitCode 6 -Label "Versioned candidate verification failure"
    Assert-True -Condition ($candidateFailure.Text.Contains("Injected candidate verification failure before activation.")) -Message "Candidate failure did not occur before activation contract publication."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $protectedRelativePaths) -Expected $protectedBefore -Message "Candidate verification failure changed protected selection state."
    Assert-Equal -Actual (Get-FileSnapshot -Root $oldInstanceRoot) -Expected $oldInstanceBefore -Message "Candidate verification failure changed the old selected instance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $prior.GenerationRoot) -Expected $oldGenerationBefore -Message "Candidate verification failure changed the old generation."
    Assert-True -Condition (-not (Test-Path -LiteralPath $contractRoot)) -Message "Candidate verification failure published a versioned activation contract."

    $activationAction = "Upgrade"
    $activationFailure = Invoke-Materializer -Action $activationAction -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 1
    Assert-Result -Result $activationFailure -ExitCode 6 -Label "Versioned activation failure rollback"
    Assert-True `
        -Condition ($activationFailure.Text.Contains(("Instance {0} failed without selecting an unverified candidate." -f $activationAction))) `
        -Message "Activation failure did not fail closed before selection."
    $activationFailureText = [string]$activationFailure.Text
    $injectedMutationFaultReached = $activationFailureText.IndexOf(
        "Injected POC failure after mutation 1.",
        [StringComparison]::Ordinal) -ge 0
    Write-Host "[DIAGNOSTIC] activationFailure.Text BEGIN"
    Write-Host $activationFailureText
    Write-Host "[DIAGNOSTIC] activationFailure.Text END"
    Write-Host "[DIAGNOSTIC] Injected POC failure after mutation 1 reached: $injectedMutationFaultReached"
    Assert-True `
        -Condition $injectedMutationFaultReached `
        -Message "Activation failure did not reach the injected mutation fault after mutation 1. Actual activationFailure.Text: $activationFailureText"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $protectedRelativePaths) -Expected $protectedBefore -Message "Activation failure changed protected selection state."
    Assert-Equal -Actual (Get-FileSnapshot -Root $oldInstanceRoot) -Expected $oldInstanceBefore -Message "Activation failure changed the old selected instance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $prior.GenerationRoot) -Expected $oldGenerationBefore -Message "Activation failure changed the old generation."
    Assert-True -Condition (Test-Path -LiteralPath $contractRoot -PathType Container) -Message "Activation failure left no durable versioned recovery contract."
    $activatingOperationPath = Join-Path $contractRoot "operation.json"
    $activatingOperation = Get-Content -LiteralPath $activatingOperationPath -Raw | ConvertFrom-Json
    $activatingActivation = Get-Content -LiteralPath (Join-Path $contractRoot "activation.json") -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$activatingOperation.phase) -Expected "ACTIVATING" -Message "Activation failure did not retain the ACTIVATING journal phase."
    Assert-Equal -Actual ([string]$activatingActivation.publication_phase) -Expected "ACTIVATING" -Message "Activation failure did not retain the ACTIVATING record phase."
    Assert-True -Condition (@($activatingOperation.mutations).Count -gt 0) -Message "Activation journal did not retain mutation evidence."
    Assert-True -Condition (-not (Test-Path -LiteralPath $legacyOperationPath)) -Message "Versioned activation created an independently authoritative legacy operation journal."

    $recovered = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $recovered -ExitCode 0 -Label "Versioned activation recovery and commit"
    Assert-True -Condition ($recovered.Text.Contains("[RECOVERY] Versioned activation rolled back before selecting a new current instance.")) -Message "Versioned activation recovery did not roll back the interrupted attempt."
    Assert-True -Condition ($recovered.Text.Contains("[RESULT] UPGRADED")) -Message "Recovered activation did not commit the new candidate."
    $committedActivationPath = Join-Path $contractRoot "activation.json"
    $committedOperationPath = Join-Path $contractRoot "operation.json"
    $committedActivation = Get-Content -LiteralPath $committedActivationPath -Raw | ConvertFrom-Json
    $committedOperation = Get-Content -LiteralPath $committedOperationPath -Raw | ConvertFrom-Json
    $selectedAfterCommit = Get-Content -LiteralPath $selectionPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$committedActivation.publication_phase) -Expected "COMMITTED" -Message "Committed activation record did not reach COMMITTED."
    Assert-Equal -Actual ([string]$committedOperation.phase) -Expected "COMMITTED" -Message "Committed activation journal did not reach COMMITTED."
    Assert-Equal -Actual ([string]$committedActivation.operation_id) -Expected ([string]$committedOperation.operation_id) -Message "Committed activation and operation ids diverged."
    Assert-Equal -Actual ([string]$committedActivation.activation_epoch) -Expected ([string]$committedOperation.activation_epoch) -Message "Committed activation and operation epochs diverged."
    Assert-Equal -Actual ([string]$committedOperation.candidate.instance_id) -Expected ([string]$selectedAfterCommit.instance_id) -Message "Committed journal candidate does not match current selection."
    Assert-Equal -Actual ([string]$committedOperation.candidate.generation_id) -Expected $generationId -Message "Committed journal selected the wrong generation."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $contractRoot ("operations\" + [string]$committedOperation.operation_id)))) -Message "Committed activation retained low-level operation evidence after commit."
    Assert-True -Condition (Test-Path -LiteralPath $oldInstanceRoot -PathType Container) -Message "Activation commit deleted the old selected instance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $oldInstanceRoot) -Expected $oldInstanceBefore -Message "Activation commit changed the old selected instance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $prior.GenerationRoot) -Expected $oldGenerationBefore -Message "Activation commit changed the old generation."
    Assert-True -Condition (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $externalSentinelRelativePath) -PathType Leaf) -Message "Activation commit deleted the external MCP/legacy sentinel."
    Assert-True -Condition (-not (Test-Path -LiteralPath $legacyOperationPath)) -Message "Committed versioned activation published a legacy journal."

    $committedOperationTextBeforeRepeat = Get-Content -LiteralPath $committedOperationPath -Raw
    $repeat = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $repeat -ExitCode 0 -Label "Identical versioned activation retry"
    Assert-True -Condition ($repeat.Text.Contains("[RESULT] READY")) -Message "Identical activation retry did not converge the existing current instance."
    $selectedAfterRepeat = Get-Content -LiteralPath $selectionPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$selectedAfterRepeat.instance_id) -Expected ([string]$selectedAfterCommit.instance_id) -Message "Identical activation retry replaced the committed current instance."
    Assert-Equal -Actual (Get-Content -LiteralPath $committedOperationPath -Raw) -Expected $committedOperationTextBeforeRepeat -Message "Identical activation retry changed the committed journal."

    $conflictingOperation = Get-Content -LiteralPath $committedOperationPath -Raw | ConvertFrom-Json
    $conflictingOperation.activation_epoch = "f" * 32
    Write-Utf8File -Path $committedOperationPath -Content (($conflictingOperation | ConvertTo-Json -Depth 16) + "`n")
    Assert-ThrowsMessage `
        -Action { Get-InstanceActivationContractState -Manifest $activationManifest -ProjectRoot $hostRoot } `
        -ExpectedMessage "identities do not match" `
        -Label "Conflicting versioned activation journal"
    Write-Host "[OK] Versioned candidate-to-activation transaction covered pre-selection candidate failure, PREPARED/ACTIVATING/COMMITTED phases, rollback recovery, idempotent retry, conflict rejection, and protected old-state retention."
}

function Invoke-PayloadManifestContractScenarios {
    $targetRelativePath = "AIWork/codedb/codedbignore.example"
    $payloadRoot = New-SyntheticPayload `
        -Root (Join-Path $syntheticRoot "manifest-contract") `
        -PayloadVersion "test.1" `
        -Entries ([ordered]@{ $targetRelativePath = "synthetic manifest contract`n" })
    $manifest = Get-Content -LiteralPath (Join-Path $payloadRoot "payload-manifest.json") -Raw | ConvertFrom-Json
    Assert-Equal `
        -Actual (@($manifest.bootstrap_transitions).Count) `
        -Expected 0 `
        -Message "Synthetic payload did not serialize the required empty bootstrap transition array."

    Assert-Result `
        -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $payloadRoot) `
        -ExitCode 0 `
        -Label "Synthetic payload manifest contract Sync"
    $marker = Get-Content `
        -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) `
        -Raw | ConvertFrom-Json
    $expectedIdentity = Get-TestPayloadContentIdentitySha256 `
        -Manifest $manifest `
        -CurrentPointerTarget $currentPointerRelativePath `
        -GenerationTargetPrefix $generationTargetPrefix
    Assert-Equal `
        -Actual ([string]$marker.payload_content_sha256) `
        -Expected $expectedIdentity `
        -Message "Synthetic payload marker identity does not match the production payload contract."
    Assert-Result `
        -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $payloadRoot) `
        -ExitCode 0 `
        -Label "Synthetic payload manifest contract Verify"
    Assert-Result `
        -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $payloadRoot) `
        -ExitCode 0 `
        -Label "Synthetic payload manifest contract Remove"
    Assert-NoMaterializerResidue
    Write-Host "[OK] Synthetic payload manifest and marker identity match the production bootstrap transition contract."
}

function New-CanonicalIdentityPayload {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$PackageVersion,
        [Parameter(Mandatory = $true)][string]$PayloadVersion,
        [Parameter(Mandatory = $true)][int]$PayloadSequence
    )

    if (Test-Path -LiteralPath $Root) {
        Remove-Item -LiteralPath $Root -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    Get-ChildItem -LiteralPath $canonicalPayloadRoot -Force | Copy-Item -Destination $Root -Recurse -Force

    $manifestPath = Join-Path $Root "payload-manifest.json"
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $generationManifestEntry = @($manifest.files | Where-Object {
        [string]::Equals([string]$_.target, $generationTargetPrefix + "generation-manifest.json", [StringComparison]::OrdinalIgnoreCase)
    })
    $currentPointerEntry = @($manifest.files | Where-Object {
        [string]::Equals([string]$_.target, $currentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)
    })
    Assert-Equal -Actual $generationManifestEntry.Count -Expected 1 -Message "Canonical identity payload generation-manifest entry count mismatch."
    Assert-Equal -Actual $currentPointerEntry.Count -Expected 1 -Message "Canonical identity payload current-pointer entry count mismatch."

    $generationManifestPath = Get-PathFromRelative -Root $Root -RelativePath ([string]$generationManifestEntry[0].source)
    $generationManifest = Get-Content -LiteralPath $generationManifestPath -Raw | ConvertFrom-Json
    $generationManifest.package_version = $PackageVersion
    $generationManifest.payload_version = $PayloadVersion
    $generationManifest.payload_sequence = $PayloadSequence
    Write-Utf8File -Path $generationManifestPath -Content (($generationManifest | ConvertTo-Json -Depth 8) + "`n")
    $generationManifestEntry[0].sha256 = (Get-FileHash -LiteralPath $generationManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()

    $currentPointerPath = Get-PathFromRelative -Root $Root -RelativePath ([string]$currentPointerEntry[0].source)
    $currentPointer = Get-Content -LiteralPath $currentPointerPath -Raw | ConvertFrom-Json
    $currentPointer.package_version = $PackageVersion
    $currentPointer.payload_version = $PayloadVersion
    $currentPointer.payload_sequence = $PayloadSequence
    $currentPointer.generation_manifest_sha256 = [string]$generationManifestEntry[0].sha256
    Write-Utf8File -Path $currentPointerPath -Content (($currentPointer | ConvertTo-Json -Depth 8) + "`n")
    $currentPointerEntry[0].sha256 = (Get-FileHash -LiteralPath $currentPointerPath -Algorithm SHA256).Hash.ToLowerInvariant()

    $manifest.package_version = $PackageVersion
    $manifest.payload_version = $PayloadVersion
    $manifest.payload_sequence = $PayloadSequence
    $manifest.bootstrap_transitions = @($manifest.bootstrap_transitions | Where-Object {
        [int]$_.source_payload_sequence -lt $PayloadSequence
    })
    Write-Utf8File -Path $manifestPath -Content (($manifest | ConvertTo-Json -Depth 8) + "`n")
    return $Root
}

function Clear-ManagedTestState {
    foreach ($relativePath in @(
        "AIWork/.runtime/codedb/control",
        "AIWork/.runtime/codedb/instances"
    )) {
        $path = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }

    foreach ($relativePath in $managedTargets + @($markerRelativePath)) {
        $path = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        if (Test-Path -LiteralPath $path) {
            Set-ItemProperty -LiteralPath $path -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }

    $generationRoot = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/host/generations/$generationId"
    $emptyManagedDirectories = @()
    if (Test-Path -LiteralPath $generationRoot -PathType Container) {
        $emptyManagedDirectories += @(Get-ChildItem -LiteralPath $generationRoot -Force -Recurse -Directory |
            Sort-Object { $_.FullName.Length } -Descending |
            ForEach-Object { $_.FullName })
    }
    $emptyManagedDirectories += @(
        $generationRoot,
        (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/host/generations"),
        (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/host")
    )
    foreach ($directory in $emptyManagedDirectories) {
        if ((Test-Path -LiteralPath $directory -PathType Container) -and
            @(Get-ChildItem -LiteralPath $directory -Force).Count -eq 0) {
            Remove-Item -LiteralPath $directory -Force
        }
    }
}

function Reset-PortabilityFixture {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("None", "Git", "Svn")]
        [string]$MetadataKind
    )

    if (Test-Path -LiteralPath $portabilityHostRoot) {
        Get-ChildItem -LiteralPath $portabilityHostRoot -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
            $_.IsReadOnly = $false
        }
        Remove-Item -LiteralPath $portabilityHostRoot -Recurse -Force
    }
    New-TestHost -Root $portabilityHostRoot
    Write-Utf8File -Path (Join-Path $portabilityHostRoot ".codex\config.toml") -Content @"
# portability config sentinel
[mcp_servers.codedb-portability-fixture]
command = "node"
cwd = "."
args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]
startup_timeout_sec = 120
"@

    $metadataRoot = $null
    switch ($MetadataKind) {
        "Git" {
            $metadataRoot = Join-Path $portabilityHostRoot ".git"
            Write-Utf8File -Path (Join-Path $metadataRoot "HEAD") -Content "ref: refs/heads/fixture`n"
            Write-Utf8File -Path (Join-Path $metadataRoot "index") -Content "opaque git index sentinel`n"
            Write-Utf8File -Path (Join-Path $metadataRoot "info\exclude") -Content "AIWork/`n"
        }
        "Svn" {
            $metadataRoot = Join-Path $portabilityHostRoot ".svn"
            Write-Utf8File -Path (Join-Path $metadataRoot "wc.db") -Content "opaque svn working-copy sentinel`n"
            Write-Utf8File -Path (Join-Path $metadataRoot "entries") -Content "fixture revision sentinel`n"
        }
    }

    return $metadataRoot
}

function Invoke-PortabilityActionMatrix {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [ValidateSet("None", "Git", "Svn")][string]$MetadataKind = "None",
        [string]$PathOverride,
        [string]$MaterializerScriptPath = $materializerPath,
        [switch]$UseDefaultPayloadRoot
    )

    $invokeArguments = @{
        PayloadRoot = if ($UseDefaultPayloadRoot) { $null } else { $canonicalPayloadRoot }
        TargetProjectRoot = $portabilityHostRoot
        MaterializerScriptPath = $MaterializerScriptPath
    }
    if ($UseDefaultPayloadRoot) { $invokeArguments["UseDefaultPayloadRoot"] = $true }
    if (-not [string]::IsNullOrWhiteSpace($PathOverride)) { $invokeArguments["PathOverride"] = $PathOverride }

    $metadataRoot = Reset-PortabilityFixture -MetadataKind $MetadataKind
    $metadataBefore = if ($null -eq $metadataRoot) { "none" } else { Get-FileSnapshot -Root $metadataRoot }
    $signature = New-Object System.Collections.Generic.List[string]

    $dryRun = Invoke-Materializer -Action "DryRun" @invokeArguments
    Assert-Result -Result $dryRun -ExitCode 0 -Label "$Label empty-scope DryRun"
    Assert-True -Condition ($dryRun.Text.Contains("[PRODUCT_STATE] NEEDS_ATTENTION")) -Message "$Label DryRun did not report the missing integration state."
    Assert-True -Condition ($dryRun.Text.Contains("[INSTANCE] NONE")) -Message "$Label DryRun did not report the missing immutable instance."
    $signature.Add("dryrun:$($dryRun.ExitCode):instance-missing")

    $upgrade = Invoke-Materializer -Action "Upgrade" @invokeArguments
    Assert-Result -Result $upgrade -ExitCode 0 -Label "$Label automatic instance Upgrade"
    Assert-StructuredCommandResult -Result $upgrade -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "COMPLETE" -Label "$Label automatic instance Upgrade"
    Assert-True -Condition ($upgrade.Text.Contains("[PRODUCT_STATE] READY")) -Message "$Label automatic instance Upgrade did not reach READY."
    $upgradedInstance = Get-TestCurrentInstanceSelection -Root $portabilityHostRoot
    Assert-TestStableInstanceWrapper -Root $portabilityHostRoot
    $signature.Add("upgrade:$($upgrade.ExitCode):ready")

    $verify = Invoke-Materializer -Action "Verify" @invokeArguments
    Assert-Result -Result $verify -ExitCode 0 -Label "$Label Verify"
    Assert-True -Condition ($verify.Text.Contains("[PRODUCT_STATE] READY")) -Message "$Label Verify did not report the selected instance as READY."
    $signature.Add("verify:$($verify.ExitCode):ready")

    $repeatedUpgrade = Invoke-Materializer -Action "Upgrade" @invokeArguments
    Assert-Result -Result $repeatedUpgrade -ExitCode 0 -Label "$Label repeated instance Upgrade"
    Assert-StructuredCommandResult -Result $repeatedUpgrade -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "COMPLETE" -Label "$Label repeated instance Upgrade"
    Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection -Root $portabilityHostRoot).Selection.instance_id) -Expected ([string]$upgradedInstance.Selection.instance_id) -Message "$Label repeated Upgrade replaced an already-ready instance."
    $signature.Add("repeat-upgrade:$($repeatedUpgrade.ExitCode):converged")

    # The instance worker removes its empty lease directory after the last
    # MCP owner exits. Reinstall must accept that valid retired state without
    # requiring a user-created placeholder directory.
    $emptyLeaseRoot = Join-Path $upgradedInstance.Root "leases"
    if (Test-Path -LiteralPath $emptyLeaseRoot) {
        Assert-Equal -Actual @(Get-ChildItem -LiteralPath $emptyLeaseRoot -Force).Count -Expected 0 -Message "$Label unexpectedly had an active instance lease before the empty-lease regression."
        Remove-Item -LiteralPath $emptyLeaseRoot -Force
    }
    $reinstall = Invoke-Materializer -Action "Reinstall" @invokeArguments
    Assert-Result -Result $reinstall -ExitCode 0 -Label "$Label instance Reinstall"
    Assert-StructuredCommandResult -Result $reinstall -Action "REINSTALL" -Outcome "REINSTALLED" -CleanupState "COMPLETE" -Label "$Label instance Reinstall"
    $reinstalledInstance = Get-TestCurrentInstanceSelection -Root $portabilityHostRoot
    Assert-True -Condition (-not [string]::Equals([string]$reinstalledInstance.Selection.instance_id, [string]$upgradedInstance.Selection.instance_id, [StringComparison]::Ordinal)) -Message "$Label Reinstall reused the selected instance identity."
    Assert-TestStableInstanceWrapper -Root $portabilityHostRoot
    $signature.Add("reinstall:$($reinstall.ExitCode):ready")

    $uninstall = Invoke-Materializer -Action "Uninstall" @invokeArguments
    Assert-Result -Result $uninstall -ExitCode 0 -Label "$Label logical Uninstall"
    Assert-StructuredCommandResult -Result $uninstall -Action "UNINSTALL" -Outcome "UNINSTALLED" -CleanupState "COMPLETE" -Label "$Label logical Uninstall"
    $currentInstancePath = Get-PathFromRelative -Root $portabilityHostRoot -RelativePath "AIWork/.runtime/codedb/control/current-instance.json"
    Assert-True -Condition (-not (Test-Path -LiteralPath $currentInstancePath)) -Message "$Label Uninstall retained current-instance.json."
    $signature.Add("uninstall:$($uninstall.ExitCode):complete")

    $install = Invoke-Materializer -Action "Install" @invokeArguments
    Assert-Result -Result $install -ExitCode 0 -Label "$Label fresh instance Install"
    Assert-StructuredCommandResult -Result $install -Action "INSTALL" -Outcome "INSTALLED" -CleanupState "COMPLETE" -Label "$Label fresh instance Install"
    $installedInstance = Get-TestCurrentInstanceSelection -Root $portabilityHostRoot
    Assert-True -Condition (-not [string]::Equals([string]$installedInstance.Selection.instance_id, [string]$reinstalledInstance.Selection.instance_id, [StringComparison]::Ordinal)) -Message "$Label Install reused the uninstalled instance identity."
    Assert-TestStableInstanceWrapper -Root $portabilityHostRoot
    $signature.Add("install:$($install.ExitCode):ready")

    $finalUninstall = Invoke-Materializer -Action "Uninstall" @invokeArguments
    Assert-Result -Result $finalUninstall -ExitCode 0 -Label "$Label final logical Uninstall"
    Assert-StructuredCommandResult -Result $finalUninstall -Action "UNINSTALL" -Outcome "UNINSTALLED" -CleanupState "COMPLETE" -Label "$Label final logical Uninstall"
    Assert-True -Condition (-not (Test-Path -LiteralPath $currentInstancePath)) -Message "$Label final Uninstall retained current-instance.json."
    $signature.Add("final-uninstall:$($finalUninstall.ExitCode):complete")
    Assert-Equal `
        -Actual $(if ($null -eq $metadataRoot) { "none" } else { Get-FileSnapshot -Root $metadataRoot }) `
        -Expected $metadataBefore `
        -Message "$Label changed version-control metadata."

    return $signature.ToArray() -join "|"
}

function New-VersionControlSentinel {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$LogPath
    )

    $commandPath = Join-Path $Directory "$CommandName.cmd"
    Write-Utf8File -Path $commandPath -Content "@echo off`r`n>>`"$LogPath`" echo $CommandName %*`r`nexit /b 91`r`n"
}

function Invoke-PortabilityAcceptanceScenarios {
    $baselineSignature = Invoke-PortabilityActionMatrix -Label "No-metadata project" -MetadataKind None
    foreach ($metadataKind in @("Git", "Svn")) {
        $signature = Invoke-PortabilityActionMatrix -Label "$metadataKind-metadata project" -MetadataKind $metadataKind
        Assert-Equal -Actual $signature -Expected $baselineSignature -Message "$metadataKind metadata changed CodeDB action outcomes."
    }
    Write-Host "[OK] DryRun, Upgrade, Verify, Reinstall, Uninstall, and Install were identical with no VCS, Git metadata, and SVN metadata."

    $nodeDirectory = Split-Path -Parent $nodePath
    $noVcsPathSignature = Invoke-PortabilityActionMatrix `
        -Label "No-VCS-PATH project" `
        -MetadataKind None `
        -PathOverride $nodeDirectory
    Assert-Equal -Actual $noVcsPathSignature -Expected $baselineSignature -Message "Removing version-control executables from PATH changed CodeDB outcomes."

    $sentinelRoot = Join-Path $runRoot "vcs-command-sentinels"
    $sentinelLogPath = Join-Path $sentinelRoot "invocations.log"
    New-Item -ItemType Directory -Force -Path $sentinelRoot | Out-Null
    foreach ($commandName in @("git", "svn", "p4")) {
        New-VersionControlSentinel -Directory $sentinelRoot -CommandName $commandName -LogPath $sentinelLogPath
    }
    $sentinelPath = $sentinelRoot + [System.IO.Path]::PathSeparator + $nodeDirectory
    $sentinelSignature = Invoke-PortabilityActionMatrix `
        -Label "VCS-command-sentinel project" `
        -MetadataKind None `
        -PathOverride $sentinelPath
    Assert-Equal -Actual $sentinelSignature -Expected $baselineSignature -Message "VCS command sentinels changed CodeDB outcomes."
    Assert-True -Condition (-not (Test-Path -LiteralPath $sentinelLogPath)) -Message "Package runtime invoked a git, svn, or p4 command sentinel."
    Write-Host "[OK] CodeDB converged with no VCS tools on PATH and invoked zero git, svn, or p4 sentinels."

    $layoutRoot = Join-Path $runRoot "package-layouts"
    $layouts = @(
        [pscustomobject]@{ Name = "cached"; PackageRoot = Join-Path $layoutRoot "cached\Library\PackageCache\com.rice.ai-codedb@0.2.5-preview.5" },
        [pscustomobject]@{ Name = "local"; PackageRoot = Join-Path $layoutRoot "local\LocalPackages\com.rice.ai-codedb" },
        [pscustomobject]@{ Name = "embedded"; PackageRoot = Join-Path $layoutRoot "embedded\Packages\com.rice.ai-codedb" }
    )
    foreach ($layout in $layouts) {
        $layoutToolsRoot = Join-Path $layout.PackageRoot "Tools~"
        $layoutPayloadRoot = Join-Path $layout.PackageRoot "Payload~"
        New-Item -ItemType Directory -Force -Path $layoutToolsRoot | Out-Null
        Copy-Item -LiteralPath $canonicalPayloadRoot -Destination $layoutPayloadRoot -Recurse -Force
        $layoutMaterializerPath = Join-Path $layoutToolsRoot "materialize-codedb-host-payload.ps1"
        $layoutInstanceEnginePath = Join-Path $layoutToolsRoot "codedb-instance-engine.ps1"
        $layoutStopClientPath = Join-Path $layoutToolsRoot "stop-codedb-legacy-watcher.mjs"
        $layoutMcpAvailabilityProbePath = Join-Path $layoutToolsRoot "probe-codedb-mcp-availability.mjs"
        Copy-Item -LiteralPath $materializerPath -Destination $layoutMaterializerPath -Force
        Copy-Item -LiteralPath (Join-Path $packageRoot "Tools~\codedb-instance-engine.ps1") -Destination $layoutInstanceEnginePath -Force
        Copy-Item -LiteralPath (Join-Path $packageRoot "Tools~\stop-codedb-legacy-watcher.mjs") -Destination $layoutStopClientPath -Force
        Copy-Item -LiteralPath (Join-Path $packageRoot "Tools~\probe-codedb-mcp-availability.mjs") -Destination $layoutMcpAvailabilityProbePath -Force
        Get-ChildItem -LiteralPath $layout.PackageRoot -Recurse -Force -File | ForEach-Object { $_.IsReadOnly = $true }
        $sourceBefore = Get-FileSnapshot -Root $layout.PackageRoot

        $layoutSignature = Invoke-PortabilityActionMatrix `
            -Label "$($layout.Name) read-only Package" `
            -MetadataKind None `
            -MaterializerScriptPath $layoutMaterializerPath `
            -UseDefaultPayloadRoot
        Assert-Equal -Actual $layoutSignature -Expected $baselineSignature -Message "$($layout.Name) Package layout changed CodeDB outcomes."
        Assert-Equal -Actual (Get-FileSnapshot -Root $layout.PackageRoot) -Expected $sourceBefore -Message "$($layout.Name) Package source bytes, timestamps, or attributes changed."
    }
    Write-Host "[OK] Cached, local, and embedded read-only Package layouts resolved Payload~ relative to the loaded script without changing Package source."
}

function Assert-MachinePrerequisiteFailure {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$ReasonCode,
        [string]$Action = "DryRun",
        [string]$PayloadRoot = $canonicalPayloadRoot,
        [string]$PathOverride,
        [string]$TargetProjectRoot = $hostRoot
    )

    $before = Get-FileSnapshot -Root $TargetProjectRoot
    $invokeParameters = @{
        Action = $Action
        PayloadRoot = $PayloadRoot
        TargetProjectRoot = $TargetProjectRoot
    }
    if (-not [string]::IsNullOrWhiteSpace($PathOverride)) {
        $invokeParameters.PathOverride = $PathOverride
    }
    $result = Invoke-Materializer @invokeParameters
    $expectedExitCode = if ($Action -eq "DryRun") { 0 } else { 4 }
    Assert-Result -Result $result -ExitCode $expectedExitCode -Label $Label
    Assert-True -Condition ($result.Text.Contains("[PRODUCT_STATE] MISSING_PREREQUISITE")) -Message "$Label did not reduce to Missing prerequisite. Output: $($result.Text)"
    Assert-True -Condition ($result.Text.Contains("[REASON_CODE] $ReasonCode")) -Message "$Label did not report reason $ReasonCode."
    Assert-True -Condition ($result.Text.Contains('"product_state":"MISSING_PREREQUISITE"')) -Message "$Label did not emit a versioned readiness snapshot."
    $commandResultLines = @($result.Text -split '\r?\n' | Where-Object { $_.StartsWith("[COMMAND_RESULT] ", [StringComparison]::Ordinal) })
    if ($Action -eq "DryRun") {
        Assert-Equal -Actual $commandResultLines.Count -Expected 0 -Message "$Label emitted a mutating command result for read-only DryRun."
    } else {
        Assert-Equal -Actual $commandResultLines.Count -Expected 1 -Message "$Label did not emit exactly one versioned command result."
        $commandResult = $commandResultLines[0].Substring("[COMMAND_RESULT] ".Length) | ConvertFrom-Json
        Assert-Equal -Actual $commandResult.schema_version -Expected 1 -Message "$Label command result schema mismatch."
        Assert-Equal -Actual $commandResult.action -Expected $Action.ToUpperInvariant() -Message "$Label command result action mismatch."
        Assert-Equal -Actual $commandResult.outcome -Expected "BLOCKED" -Message "$Label command result outcome mismatch."
        Assert-Equal -Actual $commandResult.phase -Expected "PREFLIGHT" -Message "$Label prerequisite failure did not remain in preflight."
        Assert-Equal -Actual $commandResult.reason_code -Expected $ReasonCode -Message "$Label command result reason mismatch."
        Assert-Equal -Actual @($commandResult.mutated_scopes).Count -Expected 0 -Message "$Label prerequisite failure reported project mutation."
        Assert-Equal -Actual $commandResult.cleanup_state -Expected "COMPLETE" -Message "$Label prerequisite failure cleanup state mismatch."
        Assert-Equal -Actual $commandResult.exit_code -Expected 4 -Message "$Label command result exit code mismatch."
        Assert-True -Condition (-not [string]::IsNullOrWhiteSpace([string]$commandResult.next_action)) -Message "$Label command result omitted its one next action."
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $TargetProjectRoot) -Expected $before -Message "$Label changed project bytes or timestamps."
    $allowedRuntimeFiles = if ($Action -eq "Install") {
        @((Join-Path $TargetProjectRoot "AIWork\.runtime\codedb\payload-materializer\integration-state.json"))
    } else {
        @()
    }
    Assert-NoMaterializerResidue -Root $TargetProjectRoot -AdditionalAllowedRuntimeFiles $allowedRuntimeFiles
}

function Invoke-MachinePrerequisiteContractScenarios {
    $provider = New-FixtureMachineProvider -LocalAppDataRoot $fixtureLocalAppData
    $projectBefore = Get-FileSnapshot -Root $hostRoot
    $valid = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $valid -ExitCode 0 -Label "Current machine prerequisites"
    Assert-True -Condition ($valid.Text.Contains("[PRODUCT_LAYER PREREQUISITE] CURRENT")) -Message "Current machine prerequisites were not reported as current."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $projectBefore -Message "Valid prerequisite DryRun changed the project."

    $preview6PayloadRoot = New-CanonicalIdentityPayload `
        -Root (Join-Path $syntheticRoot "provider-range-preview-6") `
        -PackageVersion "0.2.5-preview.6" `
        -PayloadVersion $generationId `
        -PayloadSequence 31
    $preview6 = Invoke-Materializer -Action "DryRun" -PayloadRoot $preview6PayloadRoot
    Assert-Result -Result $preview6 -ExitCode 0 -Label "Provider Package range in-window prerelease"
    Assert-True -Condition ($preview6.Text.Contains("[PRODUCT_LAYER PREREQUISITE] CURRENT")) -Message "Provider Package range rejected preview.6 inside the reviewed window."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $projectBefore -Message "In-window Provider Package range DryRun changed the project."

    $preview4PayloadRoot = New-CanonicalIdentityPayload `
        -Root (Join-Path $syntheticRoot "provider-range-preview-4") `
        -PackageVersion "0.2.5-preview.4" `
        -PayloadVersion $generationId `
        -PayloadSequence 31
    Assert-MachinePrerequisiteFailure `
        -Label "Provider Package range lower-bound refusal" `
        -ReasonCode "PROVIDER_PACKAGE_INCOMPATIBLE" `
        -PayloadRoot $preview4PayloadRoot

    $package026PayloadRoot = New-CanonicalIdentityPayload `
        -Root (Join-Path $syntheticRoot "provider-range-0-2-6") `
        -PackageVersion "0.2.6" `
        -PayloadVersion $generationId `
        -PayloadSequence 31
    Assert-MachinePrerequisiteFailure `
        -Label "Provider Package range exclusive upper-bound refusal" `
        -ReasonCode "PROVIDER_PACKAGE_INCOMPATIBLE" `
        -PayloadRoot $package026PayloadRoot

    $missingNodePath = Join-Path $runRoot "missing-node-path"
    New-Item -ItemType Directory -Force -Path $missingNodePath | Out-Null
    Assert-MachinePrerequisiteFailure -Label "Missing Node DryRun" -ReasonCode "NODE_MISSING" -PathOverride $missingNodePath
    Assert-MachinePrerequisiteFailure -Label "Missing Node automatic install" -ReasonCode "NODE_MISSING" -Action "Upgrade" -PathOverride $missingNodePath

    $unsupportedNodePath = Join-Path $runRoot "unsupported-node-path"
    New-Item -ItemType Directory -Force -Path $unsupportedNodePath | Out-Null
    Copy-Item -LiteralPath $provider.ExecutablePath -Destination (Join-Path $unsupportedNodePath "node.exe") -Force
    Assert-MachinePrerequisiteFailure -Label "Unsupported Node DryRun" -ReasonCode "NODE_INCOMPATIBLE" -PathOverride $unsupportedNodePath

    $providerDisabledRoot = $provider.Root + ".disabled"
    [System.IO.Directory]::Move($provider.Root, $providerDisabledRoot)
    try {
        Assert-MachinePrerequisiteFailure -Label "Missing Provider DryRun" -ReasonCode "PROVIDER_MISSING"
        Assert-MachinePrerequisiteFailure -Label "Missing Provider automatic install" -ReasonCode "PROVIDER_MISSING" -Action "Upgrade"
        Assert-MachinePrerequisiteFailure -Label "Missing Provider Fix" -ReasonCode "PROVIDER_MISSING" -Action "Repair"

        $installRoot = $repairHostRoot
        New-TestHost -Root $installRoot
        $integrationStatePath = Join-Path $installRoot "AIWork\.runtime\codedb\payload-materializer\integration-state.json"
        $integrationState = [ordered]@{
            schema_version = 1
            managed_by = "com.rice.ai-codedb"
            desired_state = "UNINSTALLED"
            state_id = "0123456789abcdef0123456789abcdef"
            cleanup_state = "COMPLETE"
            project_root = [System.IO.Path]::GetFullPath($installRoot).TrimEnd('\', '/')
            project_identity = Get-TestProjectIdentity -Root $installRoot
            updated_at_utc = [DateTime]::UtcNow.ToString("o")
        }
        Write-Utf8File -Path $integrationStatePath -Content (($integrationState | ConvertTo-Json -Depth 5) + "`n")
        Assert-MachinePrerequisiteFailure `
            -Label "Missing Provider explicit Install" `
            -ReasonCode "PROVIDER_MISSING" `
            -Action "Install" `
            -TargetProjectRoot $installRoot
    } finally {
        [System.IO.Directory]::Move($providerDisabledRoot, $provider.Root)
    }

    $originalManifestBytes = [System.IO.File]::ReadAllBytes($provider.ManifestPath)
    try {
        $manifestText = [System.Text.UTF8Encoding]::new($false, $true).GetString($originalManifestBytes)
        $objectStart = $manifestText.IndexOf('{')
        Assert-True -Condition ($objectStart -ge 0) -Message "Fixture Provider manifest is not a JSON object."
        $duplicateSchema = $manifestText.Insert($objectStart + 1, '"schema_version":1,')
        Write-Utf8File -Path $provider.ManifestPath -Content $duplicateSchema
        Assert-MachinePrerequisiteFailure -Label "Duplicate Provider manifest property" -ReasonCode "PROVIDER_INVALID"

        $wrongTypeSchema = [regex]::Replace(
            $manifestText,
            '("schema_version"\s*:\s*)1',
            '${1}true',
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
        Assert-True -Condition (-not [string]::Equals($wrongTypeSchema, $manifestText, [StringComparison]::Ordinal)) -Message "Fixture Provider manifest schema type was not changed."
        Write-Utf8File -Path $provider.ManifestPath -Content $wrongTypeSchema
        Assert-MachinePrerequisiteFailure -Label "Wrong-type Provider manifest property" -ReasonCode "PROVIDER_INVALID"

        $manifest = $manifestText | ConvertFrom-Json
        $manifest.sha256 = "0" * 64
        Write-Utf8File -Path $provider.ManifestPath -Content (($manifest | ConvertTo-Json -Depth 4) + "`n")
        Assert-MachinePrerequisiteFailure -Label "Provider hash mismatch" -ReasonCode "PROVIDER_HASH_MISMATCH"

        $manifest = $manifestText | ConvertFrom-Json
        $manifest.protocol = "codedb-cli-v2"
        Write-Utf8File -Path $provider.ManifestPath -Content (($manifest | ConvertTo-Json -Depth 4) + "`n")
        Assert-MachinePrerequisiteFailure -Label "Provider protocol mismatch" -ReasonCode "PROVIDER_INCOMPATIBLE"

        $manifest = $manifestText | ConvertFrom-Json
        $manifest.supported_package_min_inclusive = "0.2.6"
        Write-Utf8File -Path $provider.ManifestPath -Content (($manifest | ConvertTo-Json -Depth 4) + "`n")
        Assert-MachinePrerequisiteFailure -Label "Provider Package incompatibility" -ReasonCode "PROVIDER_PACKAGE_INCOMPATIBLE"
    } finally {
        [System.IO.File]::WriteAllBytes($provider.ManifestPath, $originalManifestBytes)
    }

    $disabledManifestPath = $provider.ManifestPath + ".disabled"
    [System.IO.File]::Move($provider.ManifestPath, $disabledManifestPath)
    try {
        Assert-MachinePrerequisiteFailure -Label "Missing Provider manifest" -ReasonCode "PROVIDER_MISSING"
    } finally {
        [System.IO.File]::Move($disabledManifestPath, $provider.ManifestPath)
    }
    Write-Host "[OK] Machine prerequisite contract accepts the reviewed Node/Provider pair and blocks representative missing, invalid, hash, protocol, and Package failures before project mutation."
}

function Get-TestCurrentInstanceSelection {
    param([string]$Root = $hostRoot)

    $selectionPath = Get-PathFromRelative -Root $Root -RelativePath "AIWork/.runtime/codedb/control/current-instance.json"
    Assert-True -Condition (Test-Path -LiteralPath $selectionPath -PathType Leaf) -Message "Immutable instance activation did not publish current-instance.json."
    $selection = Get-Content -LiteralPath $selectionPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$selection.generation_id) -Expected $generationId -Message "Current instance selected the wrong generation."
    Assert-True -Condition ([string]$selection.instance_id -cmatch '^[0-9a-f]{32}$') -Message "Current instance id is invalid."
    $expectedRelativePath = "AIWork/.runtime/codedb/instances/$($selection.instance_id)"
    Assert-Equal -Actual ([string]$selection.instance_relative_path) -Expected $expectedRelativePath -Message "Current instance path is not isolated by instance id."
    $instanceRoot = Get-PathFromRelative -Root $Root -RelativePath $expectedRelativePath
    $manifestPath = Join-Path $instanceRoot "instance.json"
    Assert-True -Condition (Test-Path -LiteralPath $manifestPath -PathType Leaf) -Message "Current instance manifest is missing."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant() -Expected ([string]$selection.instance_manifest_sha256) -Message "Current instance manifest hash does not match its selection."
    $instance = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$instance.state) -Expected "READY" -Message "Current instance was selected before READY."
    Assert-Equal -Actual ([string]$instance.generation_id) -Expected $generationId -Message "Current instance manifest selected the wrong generation."
    return [pscustomobject]@{ Selection = $selection; Instance = $instance; Path = $selectionPath; Root = $instanceRoot }
}

function Assert-TestStableInstanceWrapper {
    param([string]$Root = $hostRoot)

    $wrapperTarget = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    $installed = Get-PathFromRelative -Root $Root -RelativePath $wrapperTarget
    $canonical = Get-CanonicalPayloadSourcePath -TargetRelativePath $wrapperTarget
    Assert-True -Condition (Test-Path -LiteralPath $installed -PathType Leaf) -Message "Stable instance wrapper is missing."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash -Expected (Get-FileHash -LiteralPath $canonical -Algorithm SHA256).Hash -Message "Stable instance wrapper does not match the Package activation identity."
}

function Install-TrustedPreviousInstanceFixture {
    $previousGenerationId = "poc.33"
    $previousPackageVersion = "0.2.5-preview.5"
    $previousPayloadVersion = "poc.33"
    $previousPayloadSequence = 33
    $previousStableWrapperRevision = "d1313efa"
    $previousStableWrapperSha256 = "740fc4114d5a0e41d20a6f49f8178a61a68243b6646fbc02dc06ddfbf0432791"
    if (Test-Path -LiteralPath $hostRoot) {
        Remove-Item -LiteralPath $hostRoot -Recurse -Force
    }
    New-TestHost -Root $hostRoot

    $packageGenerationRoot = Join-Path $canonicalPayloadRoot "Generations\$previousGenerationId"
    $generationRelativePath = "AIWork/.runtime/codedb/host/generations/$previousGenerationId"
    $generationRoot = Get-PathFromRelative -Root $hostRoot -RelativePath $generationRelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $generationRoot) | Out-Null
    Copy-Item -LiteralPath $packageGenerationRoot -Destination $generationRoot -Recurse -Force
    $generationManifestPath = Join-Path $generationRoot "generation-manifest.json"
    $generationManifestSha256 = (Get-FileHash -LiteralPath $generationManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $workerRelativePath = "wrapper/codedb-project-instance-worker.mjs"
    $workerSha256 = (Get-FileHash -LiteralPath (Join-Path $generationRoot $workerRelativePath) -Algorithm SHA256).Hash.ToLowerInvariant()

    $hostPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    $hostPointer = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = $previousPackageVersion
        payload_version = $previousPayloadVersion
        payload_sequence = $previousPayloadSequence
        generation_id = $previousGenerationId
        generation_relative_path = $generationRelativePath
        generation_manifest_sha256 = $generationManifestSha256
        bootstrap_protocol = 1
    }
    Write-Utf8File -Path $hostPointerPath -Content (($hostPointer | ConvertTo-Json -Depth 5) + "`n")

    $instanceId = [guid]::NewGuid().ToString("N")
    $instanceRelativePath = "AIWork/.runtime/codedb/instances/$instanceId"
    $instanceRoot = Get-PathFromRelative -Root $hostRoot -RelativePath $instanceRelativePath
    foreach ($directory in @("config", "index", "adapter", "watch", "leases", "logs", "tmp")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $instanceRoot $directory) | Out-Null
    }
    $createdAt = [DateTime]::UtcNow.ToString("o")
    $instanceManifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        project_identity = Get-TestProjectIdentity -Root $hostRoot
        instance_id = $instanceId
        instance_relative_path = $instanceRelativePath
        state = "READY"
        package_version = $previousPackageVersion
        payload_version = $previousPayloadVersion
        payload_sequence = $previousPayloadSequence
        generation_id = $previousGenerationId
        generation_relative_path = $generationRelativePath
        generation_manifest_sha256 = $generationManifestSha256
        bootstrap_protocol = 1
        worker_relative_path = $workerRelativePath
        worker_sha256 = $workerSha256
        created_at_utc = $createdAt
        verified_at_utc = $createdAt
    }
    $instanceManifestPath = Join-Path $instanceRoot "instance.json"
    Write-Utf8File -Path $instanceManifestPath -Content (($instanceManifest | ConvertTo-Json -Depth 6) + "`n")

    $selectionPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/control/current-instance.json"
    $selection = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        project_identity = Get-TestProjectIdentity -Root $hostRoot
        instance_id = $instanceId
        instance_relative_path = $instanceRelativePath
        instance_manifest_sha256 = (Get-FileHash -LiteralPath $instanceManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        generation_id = $previousGenerationId
        activated_at_utc = $createdAt
    }
    Write-Utf8File -Path $selectionPath -Content (($selection | ConvertTo-Json -Depth 5) + "`n")

    $desiredStatePath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/control/desired-state.json"
    $desiredState = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        desired_state = "INSTALLED"
        state_id = [guid]::NewGuid().ToString("N")
        cleanup_state = "PENDING"
        project_root = [System.IO.Path]::GetFullPath($hostRoot).TrimEnd('\', '/')
        project_identity = Get-TestProjectIdentity -Root $hostRoot
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    Write-Utf8File -Path $desiredStatePath -Content (($desiredState | ConvertTo-Json -Depth 5) + "`n")

    $stableWrapperTarget = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    $stableWrapperPath = Get-PathFromRelative -Root $hostRoot -RelativePath $stableWrapperTarget
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stableWrapperPath) | Out-Null
    Export-ReviewedGitBlob `
        -Tag $previousStableWrapperRevision `
        -RepositoryPath "com.rice.ai-codedb/Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs" `
        -Destination $stableWrapperPath
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $stableWrapperPath -Algorithm SHA256).Hash.ToLowerInvariant() `
        -Expected $previousStableWrapperSha256 `
        -Message "Reviewed poc.33 stable wrapper fixture hash mismatch."

    $process = Get-Process -Id $PID
    $processStartIdentity = ([DateTimeOffset]::new($process.StartTime.ToUniversalTime())).ToUnixTimeMilliseconds().ToString([Globalization.CultureInfo]::InvariantCulture)
    $leaseId = "mcp-$PID-$([guid]::NewGuid().ToString('N'))"
    $instanceLeasePath = Join-Path $instanceRoot "leases\$leaseId.json"
    $instanceLease = [ordered]@{
        schema_version = 1
        instance_lease_version = 1
        managed_by = "com.rice.ai-codedb"
        owner = "mcp"
        instance_id = $instanceId
        generation_id = $previousGenerationId
        lease_id = $leaseId
        pid = $PID
        process_start_identity = $processStartIdentity
        project_root = [System.IO.Path]::GetFullPath($hostRoot).TrimEnd('\', '/')
        project_identity = Get-TestProjectIdentity -Root $hostRoot
        created_at_utc = [DateTime]::UtcNow.AddSeconds(-1).ToString("o")
        heartbeat_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    Write-Utf8File -Path $instanceLeasePath -Content (($instanceLease | ConvertTo-Json -Depth 5) + "`n")
    $generationLeasePath = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId $previousGenerationId

    return [pscustomobject]@{
        GenerationId = $previousGenerationId
        GenerationRoot = $generationRoot
        InstanceId = $instanceId
        InstanceRoot = $instanceRoot
        InstanceManifestPath = $instanceManifestPath
        SelectionPath = $selectionPath
        StableWrapperPath = $stableWrapperPath
        StableWrapperSha256 = $previousStableWrapperSha256
        InstanceLeasePath = $instanceLeasePath
        GenerationLeasePath = $generationLeasePath
    }
}

function Invoke-PriorGenerationUpgradeScenarios {
    $priorParameters = @{
        PriorGenerationId = "poc.27"
        PriorPayloadSequence = 27
        PriorPackageVersion = "0.2.4"
        UseReviewedGeneration = $true
        UseReviewedFlatPayload = $true
    }
    $instanceCurrentRelativePath = "AIWork/.runtime/codedb/control/current-instance.json"
    $instanceLkgRelativePath = "AIWork/.runtime/codedb/control/last-known-good-instance.json"
    $instanceDesiredRelativePath = "AIWork/.runtime/codedb/control/desired-state.json"
    $stableWrapperTarget = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"

    # Candidate and activation failures keep the real v0.2.4 selection and
    # flat execution closure usable. The verified poc.34 generation may remain
    # as an unselected Package-owned side-by-side closure.
    $prior = Install-PriorGenerationFixture @priorParameters
    $dryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $dryRun -ExitCode 0 -Label "v0.2.4 immutable-instance DryRun"
    Assert-True -Condition ($dryRun.Text.Contains("[PRODUCT_LAYER INSTALLED] MISSING") -and $dryRun.Text.Contains("[INSTANCE] NONE")) -Message "v0.2.4 DryRun did not report the missing instance selection."
    $rollbackPaths = @($prior.OwnedTargets + @(
        $markerRelativePath,
        ".codex/config.toml",
        $instanceCurrentRelativePath,
        $instanceLkgRelativePath,
        $instanceDesiredRelativePath
    ))
    $beforeCandidateFailure = Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackPaths
    $beforeCandidateSentinels = Get-SentinelSnapshot
    $candidateFailure = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TestFailInstanceCandidate
    Assert-Result -Result $candidateFailure -ExitCode 6 -Label "v0.2.4 candidate verification failure"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackPaths) -Expected $beforeCandidateFailure -Message "Candidate failure changed the selected v0.2.4 installation."
    Assert-SentinelsUnchanged -ExpectedSnapshot $beforeCandidateSentinels
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $instanceCurrentRelativePath))) -Message "Candidate failure selected an instance."

    $beforeActivationFailure = Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackPaths
    $activationFailure = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 1
    Assert-Result -Result $activationFailure -ExitCode 6 -Label "v0.2.4 activation rollback"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $rollbackPaths) -Expected $beforeActivationFailure -Message "Activation rollback changed the selected v0.2.4 installation."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $instanceCurrentRelativePath))) -Message "Activation failure retained an unverified current instance."

    $ownerFreeUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $ownerFreeUpgrade -ExitCode 0 -Label "v0.2.4 owner-free instance Upgrade"
    Assert-StructuredCommandResult -Result $ownerFreeUpgrade -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "COMPLETE" -Label "v0.2.4 owner-free instance Upgrade"
    $ownerFreeInstance = Get-TestCurrentInstanceSelection
    Assert-TestStableInstanceWrapper
    $selectedHost = Get-Content -LiteralPath $prior.PointerPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([string]$selectedHost.generation_id) -Expected $generationId -Message "Owner-free retirement did not switch host/current to poc.34."
    $lastKnownGoodPath = Get-PathFromRelative -Root $hostRoot -RelativePath $lastKnownGoodPointerRelativePath
    Assert-Equal -Actual (Get-FileHash -LiteralPath $lastKnownGoodPath -Algorithm SHA256).Hash -Expected (Get-FileHash -LiteralPath $prior.PointerPath -Algorithm SHA256).Hash -Message "Owner-free retirement did not converge generation last-known-good."
    Assert-True -Condition (-not (Test-Path -LiteralPath $prior.MarkerPath)) -Message "Owner-free retirement retained the legacy marker."
    Assert-True -Condition (-not (Test-Path -LiteralPath $prior.GenerationRoot)) -Message "Owner-free retirement retained poc.27."
    foreach ($target in $prior.InstalledFlatTargets) {
        if ([string]::Equals($target, $stableWrapperTarget, [StringComparison]::OrdinalIgnoreCase)) { continue }
        Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $target))) -Message "Owner-free retirement retained legacy flat target $target."
    }

    # A transiently unreadable availability document must not make the
    # still-selected, correctly registered instance look unconfigured. The
    # next convergence pass should recover availability in place and retain
    # the same immutable instance identity.
    $availabilityPath = Join-Path $ownerFreeInstance.Root "logs\mcp-availability.json"
    $availabilityBytes = [System.IO.File]::ReadAllBytes($availabilityPath)
    $availabilityRecovered = $false
    try {
        Write-Utf8File -Path $availabilityPath -Content "{invalid availability evidence`n"
        $transientRead = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $transientRead -ExitCode 0 -Label "Transient instance availability read"
        Assert-True -Condition ($transientRead.Text.Contains("[PRODUCT_LAYER CONFIGURED] CURRENT")) -Message "Transient availability failure downgraded the current MCP registration."
        Assert-True -Condition ($transientRead.Text.Contains("[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE")) -Message "Transient availability failure was not isolated to MCP availability."
        Assert-True -Condition ($transientRead.Text.Contains("[PRODUCT_STATE] NEEDS_ATTENTION")) -Message "Transient availability failure was incorrectly reported as Ready."
        $recoveredTransient = Invoke-Materializer -Action "Probe" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $recoveredTransient -ExitCode 0 -Label "Transient current-instance availability Probe"
        Assert-True -Condition ($recoveredTransient.Text.Contains("[PHASE CANDIDATE_VERIFY] READY")) -Message "Current-instance Probe did not verify the selected immutable instance."
        Assert-True -Condition ($recoveredTransient.Text.Contains("[PRODUCT_LAYER MCP_AVAILABLE] CURRENT")) -Message "Current-instance Probe did not restore MCP availability."
        Assert-True -Condition ($recoveredTransient.Text.Contains("[PRODUCT_STATE] READY")) -Message "Current-instance Probe did not restore Ready."
        Assert-True -Condition (-not $recoveredTransient.Text.Contains("current Package-owned Host runtime")) -Message "Current-instance Probe incorrectly used the legacy flat Host availability path."
        $availabilityRecovered = $true
    } finally {
        if (-not $availabilityRecovered) {
            [System.IO.File]::WriteAllBytes($availabilityPath, $availabilityBytes)
        }
    }
    Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection).Selection.instance_id) -Expected ([string]$ownerFreeInstance.Selection.instance_id) -Message "Current-instance Probe replaced the selected immutable instance."

    $repeatOwnerFree = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $repeatOwnerFree -ExitCode 0 -Label "v0.2.4 owner-free repeated Upgrade"
    Assert-StructuredCommandResult -Result $repeatOwnerFree -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "COMPLETE" -Label "v0.2.4 owner-free repeated Upgrade"
    Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection).Selection.instance_id) -Expected ([string]$ownerFreeInstance.Selection.instance_id) -Message "Repeated Upgrade replaced an already-ready instance."

    # A real schema-1 flat MCP lease plus a generation request lease preserves
    # the old pointer, marker, scripts, process, lease, and generation. Future
    # sessions still receive the independently selected poc.34 instance.
    $prior = Install-PriorGenerationFixture @priorParameters
    $legacyGate = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/shared/codedb-host-use-gate.mjs"
    $flatMcp = $null
    $generationLease = $null
    try {
        $flatMcp = Start-LegacyHostUseLeaseProcess -GatePath $legacyGate -Owner "mcp"
        $generationLease = New-TestGenerationLease -Owner "mcp" -LeaseGenerationId "poc.27"
        $oldPointerBytes = Get-ByteSnapshot -Path $prior.PointerPath
        $oldMarkerBytes = Get-ByteSnapshot -Path $prior.MarkerPath
        $oldGenerationSnapshot = Get-FileSnapshot -Root $prior.GenerationRoot
        $oldFlatPaths = @($prior.InstalledFlatTargets | Where-Object { -not [string]::Equals($_, $stableWrapperTarget, [StringComparison]::OrdinalIgnoreCase) })
        $oldFlatSnapshot = Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $oldFlatPaths
        $generationLeaseBytes = Get-ByteSnapshot -Path $generationLease

        $activeUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $activeUpgrade -ExitCode 0 -Label "v0.2.4 active-owner instance Upgrade"
        Assert-StructuredCommandResult -Result $activeUpgrade -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "PENDING" -Label "v0.2.4 active-owner instance Upgrade"
        $activeInstance = Get-TestCurrentInstanceSelection
        Assert-TestStableInstanceWrapper
        Assert-Equal -Actual (Get-ByteSnapshot -Path $prior.PointerPath) -Expected $oldPointerBytes -Message "Active-owner Upgrade changed the legacy Host pointer."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $prior.MarkerPath) -Expected $oldMarkerBytes -Message "Active-owner Upgrade changed the legacy marker."
        Assert-Equal -Actual (Get-FileSnapshot -Root $prior.GenerationRoot) -Expected $oldGenerationSnapshot -Message "Active-owner Upgrade changed poc.27 bytes."
        Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot -Paths $oldFlatPaths) -Expected $oldFlatSnapshot -Message "Active-owner Upgrade changed legacy flat scripts."
        Assert-Equal -Actual (Get-ByteSnapshot -Path $generationLease) -Expected $generationLeaseBytes -Message "Active-owner Upgrade changed the generation lease."
        Assert-True -Condition (-not $flatMcp.HasExited) -Message "Active-owner Upgrade terminated the external fixture MCP."
        Assert-True -Condition (-not $activeUpgrade.Text.Contains("[STOPPING]")) -Message "Active-owner Upgrade attempted to Stop an external MCP."

        $repeatActive = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $repeatActive -ExitCode 0 -Label "v0.2.4 repeated active-owner Upgrade"
        Assert-StructuredCommandResult -Result $repeatActive -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "PENDING" -Label "v0.2.4 repeated active-owner Upgrade"
        Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection).Selection.instance_id) -Expected ([string]$activeInstance.Selection.instance_id) -Message "Pending cleanup replaced the selected instance."
    } finally {
        if ($null -ne $generationLease -and (Test-Path -LiteralPath $generationLease)) { Remove-Item -LiteralPath $generationLease -Force }
        if ($null -ne $flatMcp) { Stop-LegacyHostUseLeaseProcess -Process $flatMcp -Owner "mcp" }
    }
    $drainedUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $drainedUpgrade -ExitCode 0 -Label "v0.2.4 drained owner cleanup"
    Assert-StructuredCommandResult -Result $drainedUpgrade -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "COMPLETE" -Label "v0.2.4 drained owner cleanup"
    Assert-True -Condition (-not (Test-Path -LiteralPath $prior.GenerationRoot)) -Message "Drained cleanup retained poc.27."
    Assert-True -Condition (-not (Test-Path -LiteralPath $prior.MarkerPath)) -Message "Drained cleanup retained the v0.2.4 marker."
    Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection).Selection.instance_id) -Expected ([string]$activeInstance.Selection.instance_id) -Message "Drain cleanup replaced the selected instance."

    # A live but unauthenticated coordinator state is retirement evidence, not
    # an activation dependency. It is never stopped and only keeps cleanup pending.
    $prior = Install-PriorGenerationFixture @priorParameters
    $unknownStatePath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/codedb-fixture/watch/coordinator/coordinator-state.json"
    Write-Utf8File -Path $unknownStatePath -Content (([ordered]@{ coordinator_pid = $PID } | ConvertTo-Json) + "`n")
    try {
        $unknownOwnerUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $unknownOwnerUpgrade -ExitCode 0 -Label "v0.2.4 unknown-owner non-blocking Upgrade"
        Assert-StructuredCommandResult -Result $unknownOwnerUpgrade -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "PENDING" -Label "v0.2.4 unknown-owner non-blocking Upgrade"
        $unknownOwnerInstance = Get-TestCurrentInstanceSelection
        Assert-True -Condition ($unknownOwnerUpgrade.Text.Contains("[ACTIVE]")) -Message "Unknown-owner Upgrade did not report retained coordinator evidence."
        Assert-True -Condition ($null -ne (Get-Process -Id $PID -ErrorAction SilentlyContinue)) -Message "Unknown-owner Upgrade terminated the unrelated fixture process."
        Assert-Equal -Actual ([string](Get-Content -LiteralPath $prior.PointerPath -Raw | ConvertFrom-Json).generation_id) -Expected "poc.27" -Message "Unknown-owner Upgrade changed the legacy Host pointer before drain."
    } finally {
        if (Test-Path -LiteralPath $unknownStatePath) { Remove-Item -LiteralPath $unknownStatePath -Force }
    }
    $unknownDrained = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownDrained -ExitCode 0 -Label "v0.2.4 unknown-owner drained cleanup"
    Assert-StructuredCommandResult -Result $unknownDrained -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "COMPLETE" -Label "v0.2.4 unknown-owner drained cleanup"
    Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection).Selection.instance_id) -Expected ([string]$unknownOwnerInstance.Selection.instance_id) -Message "Unknown-owner drain replaced the selected instance."
    Assert-True -Condition (-not (Test-Path -LiteralPath $prior.GenerationRoot)) -Message "Unknown-owner drain retained poc.27."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Real v0.2.4 flat/runtime state converged through an isolated poc.34 instance; candidate and activation failures retained the old selection, live/unknown owners were never stopped, and retirement completed idempotently after drain."

    # A selected immutable instance from an exact Package-declared transition is
    # a valid automatic handoff source. Its live leases and generation remain
    # byte-exact until they drain; an undeclared identity still fails closed.
    $trustedPrevious = Install-TrustedPreviousInstanceFixture
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $trustedPrevious.StableWrapperPath -Algorithm SHA256).Hash.ToLowerInvariant() `
        -Expected $trustedPrevious.StableWrapperSha256 `
        -Message "Previous-instance Upgrade fixture did not start from the reviewed poc.33 stable wrapper."
    $previousInstanceSnapshot = Get-FileSnapshot -Root $trustedPrevious.InstanceRoot
    $previousGenerationSnapshot = Get-FileSnapshot -Root $trustedPrevious.GenerationRoot
    $previousInstanceLeaseBytes = Get-ByteSnapshot -Path $trustedPrevious.InstanceLeasePath
    $previousGenerationLeaseBytes = Get-ByteSnapshot -Path $trustedPrevious.GenerationLeasePath
    $trustedUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $trustedUpgrade -ExitCode 0 -Label "Package-declared previous instance Upgrade"
    Assert-StructuredCommandResult -Result $trustedUpgrade -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "PENDING" -Label "Package-declared previous instance Upgrade"
    $trustedCurrent = Get-TestCurrentInstanceSelection
    Assert-True -Condition (-not [string]::Equals([string]$trustedCurrent.Selection.instance_id, $trustedPrevious.InstanceId, [StringComparison]::Ordinal)) -Message "Previous-instance Upgrade did not activate a new immutable instance."
    Assert-TestStableInstanceWrapper
    Assert-Equal -Actual (Get-FileSnapshot -Root $trustedPrevious.InstanceRoot) -Expected $previousInstanceSnapshot -Message "Previous-instance Upgrade changed the retained instance closure."
    Assert-Equal -Actual (Get-FileSnapshot -Root $trustedPrevious.GenerationRoot) -Expected $previousGenerationSnapshot -Message "Previous-instance Upgrade changed the retained generation closure."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $trustedPrevious.InstanceLeasePath) -Expected $previousInstanceLeaseBytes -Message "Previous-instance Upgrade changed its live instance lease."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $trustedPrevious.GenerationLeasePath) -Expected $previousGenerationLeaseBytes -Message "Previous-instance Upgrade changed its live generation lease."
    Assert-True -Condition (-not $trustedUpgrade.Text.Contains("[STOPPING]")) -Message "Previous-instance Upgrade attempted to stop a retained MCP owner."

    Remove-Item -LiteralPath $trustedPrevious.InstanceLeasePath -Force
    Remove-Item -LiteralPath $trustedPrevious.GenerationLeasePath -Force
    $trustedDrain = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $trustedDrain -ExitCode 0 -Label "Package-declared previous instance drain"
    Assert-StructuredCommandResult -Result $trustedDrain -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "COMPLETE" -Label "Package-declared previous instance drain"
    Assert-True -Condition (-not (Test-Path -LiteralPath $trustedPrevious.InstanceRoot)) -Message "Drained previous instance was not retired."
    Assert-True -Condition (-not (Test-Path -LiteralPath $trustedPrevious.GenerationRoot)) -Message "Drained previous generation was not retired."

    $forgedWrapper = Install-TrustedPreviousInstanceFixture
    Write-Utf8File -Path $forgedWrapper.StableWrapperPath -Content "forged stable wrapper`n"
    $forgedWrapperSelectionBytes = Get-ByteSnapshot -Path $forgedWrapper.SelectionPath
    $forgedWrapperBytes = Get-ByteSnapshot -Path $forgedWrapper.StableWrapperPath
    $forgedWrapperInstanceSnapshot = Get-FileSnapshot -Root $forgedWrapper.InstanceRoot
    $forgedWrapperGenerationSnapshot = Get-FileSnapshot -Root $forgedWrapper.GenerationRoot
    $currentGenerationRoot = Get-PathFromRelative -Root $hostRoot -RelativePath $generationTargetPrefix.TrimEnd([char]'/')
    Assert-True -Condition (-not (Test-Path -LiteralPath $currentGenerationRoot)) -Message "Forged-wrapper fixture unexpectedly started with poc.34."
    $forgedWrapperUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $forgedWrapperUpgrade -ExitCode 6 -Label "Forged previous stable wrapper refusal"
    Assert-True `
        -Condition ($forgedWrapperUpgrade.Text.IndexOf("stable wrapper", [StringComparison]::OrdinalIgnoreCase) -ge 0) `
        -Message "Forged previous stable wrapper did not report its ownership boundary."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $forgedWrapper.SelectionPath) -Expected $forgedWrapperSelectionBytes -Message "Rejected stable wrapper changed the selected instance."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $forgedWrapper.StableWrapperPath) -Expected $forgedWrapperBytes -Message "Rejected stable wrapper was overwritten."
    Assert-Equal -Actual (Get-FileSnapshot -Root $forgedWrapper.InstanceRoot) -Expected $forgedWrapperInstanceSnapshot -Message "Rejected stable wrapper changed the retained instance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $forgedWrapper.GenerationRoot) -Expected $forgedWrapperGenerationSnapshot -Message "Rejected stable wrapper changed the retained generation."
    Assert-True -Condition (-not (Test-Path -LiteralPath $currentGenerationRoot)) -Message "Rejected stable wrapper published poc.34 before refusing activation."

    $forgedPrevious = Install-TrustedPreviousInstanceFixture
    $forgedManifest = Get-Content -LiteralPath $forgedPrevious.InstanceManifestPath -Raw | ConvertFrom-Json
    $forgedManifest.payload_version = "poc.33-undeclared"
    Write-Utf8File -Path $forgedPrevious.InstanceManifestPath -Content (($forgedManifest | ConvertTo-Json -Depth 6) + "`n")
    $forgedSelection = Get-Content -LiteralPath $forgedPrevious.SelectionPath -Raw | ConvertFrom-Json
    $forgedSelection.instance_manifest_sha256 = (Get-FileHash -LiteralPath $forgedPrevious.InstanceManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    Write-Utf8File -Path $forgedPrevious.SelectionPath -Content (($forgedSelection | ConvertTo-Json -Depth 5) + "`n")
    $forgedSelectionBytes = Get-ByteSnapshot -Path $forgedPrevious.SelectionPath
    $forgedInstanceSnapshot = Get-FileSnapshot -Root $forgedPrevious.InstanceRoot
    $forgedGenerationSnapshot = Get-FileSnapshot -Root $forgedPrevious.GenerationRoot
    $forgedUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $forgedUpgrade -ExitCode 6 -Label "Undeclared previous instance refusal"
    Assert-True -Condition ($forgedUpgrade.Text.Contains("not an exact Package-declared transition")) -Message "Undeclared previous instance did not report the transition identity boundary."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $forgedPrevious.SelectionPath) -Expected $forgedSelectionBytes -Message "Rejected previous instance changed its selection."
    Assert-Equal -Actual (Get-FileSnapshot -Root $forgedPrevious.InstanceRoot) -Expected $forgedInstanceSnapshot -Message "Rejected previous instance changed its closure."
    Assert-Equal -Actual (Get-FileSnapshot -Root $forgedPrevious.GenerationRoot) -Expected $forgedGenerationSnapshot -Message "Rejected previous instance changed its generation."
    Write-Host "[OK] Exact Package-declared immutable instances hand off automatically, retain live owners, drain idempotently, and reject undeclared identities before activation."
}

$packageSnapshotBefore = $null
$sentinelSnapshot = $null
try {
    $env:LOCALAPPDATA = $fixtureLocalAppData
    $fixtureMachineProvider = New-FixtureMachineProvider -LocalAppDataRoot $fixtureLocalAppData
    Assert-True -Condition (Test-Path -LiteralPath $materializerPath -PathType Leaf) -Message "Materializer script is missing."
    Assert-True -Condition (Test-Path -LiteralPath $canonicalPayloadRoot -PathType Container) -Message "Canonical payload root is missing."
    Assert-Equal -Actual $canonicalPayloadManifest.package_version -Expected "0.2.5-preview.5" -Message "Canonical package version mismatch."
    Assert-Equal -Actual $canonicalPayloadManifest.payload_version -Expected $generationId -Message "Canonical payload version mismatch."
    Assert-Equal -Actual $canonicalPayloadManifest.payload_sequence -Expected 34 -Message "Canonical payload sequence mismatch."
    Assert-Equal -Actual $canonicalPayloadManifest.generation_id -Expected $generationId -Message "Canonical generation id mismatch."
    Assert-Equal -Actual $legacyManagedTargets.Count -Expected 22 -Message "Flat target count mismatch."
    Assert-Equal -Actual $generationManagedTargets.Count -Expected 23 -Message "Generation target count mismatch."
    Assert-Equal -Actual $pointerManagedTargets.Count -Expected 1 -Message "Current-pointer target count mismatch."
    Assert-Equal -Actual $managedTargets.Count -Expected 46 -Message "Total managed target count mismatch."
    New-TestHost -Root $hostRoot
    New-TestHost -Root $productionProjectRoot
    Remove-Item -LiteralPath (Join-Path $productionProjectRoot $fixtureMarkerName) -Force
    $packageSnapshotBefore = Get-FileSnapshot -Root $packageRoot
    $sentinelSnapshot = Get-SentinelSnapshot

    if ($PrerequisiteOnly) {
        Invoke-MachinePrerequisiteContractScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused machine prerequisite acceptance modified package source files."
        Write-Host "[OK] Focused machine prerequisite scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($UpgradeOnly) {
        Invoke-PriorGenerationUpgradeScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused prior-generation Upgrade acceptance modified package source files."
        Write-Host "[OK] Focused prior-generation Upgrade scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($PayloadContractOnly) {
        Invoke-PayloadManifestContractScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused payload manifest contract acceptance modified package source files."
        Write-Host "[OK] Focused payload manifest contract scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($ActivationContractOnly) {
        Invoke-ActivationContractFoundationScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused activation contract acceptance modified package source files."
        Write-Host "[OK] Focused activation contract foundation scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($ActivationTransactionOnly) {
        Invoke-ActivationTransactionScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused activation transaction acceptance modified package source files."
        Write-Host "[OK] Focused activation transaction scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($McpAvailabilityOnly) {
        Invoke-McpAvailabilityProbeContractScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused MCP availability acceptance modified package source files."
        Write-Host "[OK] Focused MCP availability contract scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($UninstallOnly) {
        Invoke-UninstallAcceptanceScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused Uninstall acceptance modified package source files."
        Write-Host "[OK] Uninstall CodeDB acceptance scenarios passed."
        $fixturePassed = $true
        return
    }

    if ($McpConfigOnly) {
        Invoke-McpConfigCompatibilityScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Focused MCP config acceptance modified package source files."
        Write-Host "[OK] Focused MCP config compatibility scenarios passed."
        $fixturePassed = $true
        return
    }

    if (-not $TransactionOnly) {
        if (-not $PortabilityOnly) {
            Invoke-RepairAcceptanceScenarios
            Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Repair acceptance modified package source files."
            if ($RepairOnly) {
                Write-Host "[OK] Repair CodeDB acceptance scenarios passed."
                $fixturePassed = $true
                return
            }
            Invoke-UninstallAcceptanceScenarios
            Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Uninstall acceptance modified package source files."
        }

        Invoke-PortabilityAcceptanceScenarios
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Portability acceptance modified package source files."
        if ($PortabilityOnly) {
            Write-Host "[OK] Version-control and Package-source independence acceptance scenarios passed."
            $fixturePassed = $true
            return
        }

    $productionHostBefore = Get-ManagedPayloadSnapshot -Root $productionProjectRoot
    $productionConfirmationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot -OmitPocFixture
    Assert-Result -Result $productionConfirmationGuard -ExitCode 4 -Label "Production confirmation guard"
    Assert-True -Condition ($productionConfirmationGuard.Text.Contains("second-level project mutation confirmation")) -Message "Production confirmation guard did not identify the missing confirmation."
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $productionProjectRoot) -Expected $productionHostBefore -Message "Production confirmation guard changed the production host payload."
    $productionFixtureGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot
    Assert-Result -Result $productionFixtureGuard -ExitCode 4 -Label "Production fixture guard"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $productionProjectRoot) -Expected $productionHostBefore -Message "Production fixture guard changed the production host payload."
    Write-Host "[OK] Missing project confirmation and fixture ownership both rejected mutation."

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

    $productionSentinelSnapshot = Get-SentinelSnapshot -Root $productionProjectRoot -Paths $productionSentinelPaths
    $confirmedSync = Invoke-Materializer `
        -Action "Sync" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $productionProjectRoot `
        -OmitPocFixture `
        -ConfirmedProjectMutation
    Assert-Result -Result $confirmedSync -ExitCode 0 -Label "Confirmed project Sync"
    Assert-True -Condition ($confirmedSync.Text.Contains("[CONFIRMED] Sync is scoped to CodeDB-owned paths")) -Message "Confirmed Sync did not report its project scope."
    Assert-CanonicalFilesInstalled -Root $productionProjectRoot
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot -OmitPocFixture) -ExitCode 0 -Label "Production Verify"
    $confirmedRemove = Invoke-Materializer `
        -Action "Remove" `
        -PayloadRoot $canonicalPayloadRoot `
        -TargetProjectRoot $productionProjectRoot `
        -OmitPocFixture `
        -ConfirmedProjectMutation
    Assert-Result -Result $confirmedRemove -ExitCode 0 -Label "Confirmed project Remove"
    Assert-CanonicalFilesRemoved -Root $productionProjectRoot
    Assert-SentinelsUnchanged -ExpectedSnapshot $productionSentinelSnapshot -Root $productionProjectRoot -Paths $productionSentinelPaths
    Write-Host "[OK] Production Sync and Remove used one project confirmation without version-control input."

    $dryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $dryRun -ExitCode 0 -Label "Empty install DryRun"
    Assert-True -Condition ($dryRun.Text.Contains("[PRODUCT_STATE] NEEDS_ATTENTION")) -Message "Empty install DryRun did not report the missing integration state."
    Assert-True -Condition ($dryRun.Text.Contains("[INSTANCE] NONE")) -Message "Empty install DryRun did not report the missing immutable instance."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Empty instance status is read-only."

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

    $currentPointerMutation = @($canonicalPayloadManifest.files).Count
    $beforePointerFailure = Get-FileSnapshot -Root $hostRoot
    $pointerFailure = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation $currentPointerMutation
    Assert-Result -Result $pointerFailure -ExitCode 6 -Label "Injected current-pointer publication failure"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforePointerFailure -Message "Current-pointer publication failure did not restore the exact pre-sync tree."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue

    $beforePointerCrash = Get-FileSnapshot -Root $hostRoot
    $pointerCrash = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation $currentPointerMutation
    Assert-Result -Result $pointerCrash -ExitCode 86 -Label "Injected current-pointer publication crash"
    $crashedPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $crashedPointerPath -PathType Leaf) -Message "Pointer-boundary crash did not publish current.json at mutation $currentPointerMutation."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath))) -Message "Pointer-boundary crash unexpectedly published the ownership marker."
    $pointerCrashRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $pointerCrashRecovery -ExitCode 0 -Label "Current-pointer crash recovery"
    Assert-True -Condition ($pointerCrashRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Pointer-boundary crash recovery did not report rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforePointerCrash -Message "Pointer-boundary crash recovery did not restore the exact pre-sync tree."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Current generation pointer failure and crash both rolled generation publication back to the exact old state."

    Invoke-PriorGenerationUpgradeScenarios

    # The in-place automatic Upgrade workflow is superseded by immutable-instance convergence above.
    Install-OwnedLegacyRedeployFixture -PayloadVersion "poc.15" -PayloadSequence 15
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
        $reviewedLegacyRedeploy = Invoke-Materializer -Action "Redeploy" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $reviewedLegacyRedeploy -ExitCode 0 -Label "$($identity.PayloadVersion) reviewed Redeploy"
        Assert-True -Condition ($reviewedLegacyRedeploy.Text.Contains("[REDEPLOYING] Replacing byte-exact $($identity.PayloadVersion) host files and publishing generation $generationId.")) -Message "Reviewed $($identity.PayloadVersion) Redeploy omitted its source and target identities."
        Assert-CanonicalFilesInstalled
        Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "$($identity.PayloadVersion) reviewed Redeploy cleanup"
        Assert-CanonicalFilesRemoved
    }
    Write-Host "[OK] Published poc.9, poc.16, and poc.20 identities completed controlled Redeploy."

    Install-OwnedLegacyRedeployFixture
    $legacyRedeployBeforeBlock = Get-ManagedPayloadSnapshot -Root $hostRoot
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

    $canonicalDiagnosticSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $canonicalDiagnosticSync -ExitCode 0 -Label "Canonical diagnostic Host Sync"
    Assert-CanonicalFilesInstalled
    Assert-NoMaterializerResidue
    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    $currentPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    $lastKnownGoodPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $lastKnownGoodPointerRelativePath
    $failedUpgradeStatePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\upgrade-state.json"

    Assert-True -Condition (Test-Path -LiteralPath $markerPath -PathType Leaf) -Message "Diagnostic Sync did not write the ownership marker."
    $markerText = Get-Content -LiteralPath $markerPath -Raw
    Assert-LfOnlyFile -Path $markerPath -Label "Synchronized ownership marker"
    Assert-True -Condition (-not $markerText.Contains($hostRoot)) -Message "Ownership marker contains an absolute host path."

    Write-Utf8File -Path $markerPath -Content $markerText.Replace("`n", "`r`n")
    Assert-True -Condition ([Array]::IndexOf([System.IO.File]::ReadAllBytes($markerPath), [byte]13) -ge 0) -Message "Non-canonical marker fixture did not contain CR bytes."
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Non-canonical marker repair"
    Assert-LfOnlyFile -Path $markerPath -Label "Repaired ownership marker"
    Assert-Equal -Actual (Get-Content -LiteralPath $markerPath -Raw) -Expected $markerText -Message "Marker repair did not restore canonical serialization."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Ownership markers use canonical LF serialization and repair non-canonical JSON formatting."

    $marker = $markerText | ConvertFrom-Json
    Assert-Equal -Actual $marker.managed_by -Expected "com.rice.ai-codedb" -Message "Marker manager mismatch."
    Assert-Equal -Actual $marker.schema_version -Expected 2 -Message "Marker schema version mismatch."
    Assert-Equal -Actual $marker.package_version -Expected "0.2.5-preview.5" -Message "Marker package version mismatch."
    Assert-Equal -Actual $marker.payload_version -Expected $generationId -Message "Marker payload version mismatch."
    Assert-Equal -Actual $marker.payload_sequence -Expected 34 -Message "Marker payload sequence mismatch."
    Assert-True -Condition ([string]$marker.payload_content_sha256 -match '^[0-9a-f]{64}$') -Message "Marker payload content identity mismatch."
    Assert-Equal -Actual $marker.host_use_gate_version -Expected 1 -Message "Marker host-use gate version mismatch."
    Assert-Equal -Actual $marker.generation_lease_version -Expected 2 -Message "Marker generation-lease version mismatch."
    Assert-Equal -Actual $marker.generation_id -Expected $generationId -Message "Marker generation id mismatch."
    Assert-Equal -Actual $marker.current_pointer -Expected $currentPointerRelativePath -Message "Marker current-pointer path mismatch."
    Assert-Equal -Actual @($marker.files).Count -Expected $legacyManagedTargets.Count -Message "Marker tracked-file count mismatch."
    $currentPointerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $currentPointerRelativePath
    Assert-LfOnlyFile -Path $currentPointerPath -Label "Current generation pointer"
    $currentPointer = Get-Content -LiteralPath $currentPointerPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $currentPointer.package_version -Expected "0.2.5-preview.5" -Message "Current pointer package version mismatch."
    Assert-Equal -Actual $currentPointer.generation_id -Expected $generationId -Message "Current pointer generation id mismatch."
    Assert-Equal -Actual $currentPointer.generation_relative_path -Expected $generationTargetPrefix.TrimEnd([char]'/') -Message "Current pointer generation path mismatch."
    $installedGenerationManifest = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "generation-manifest.json")
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $installedGenerationManifest -Algorithm SHA256).Hash.ToLowerInvariant() `
        -Expected ([string]$currentPointer.generation_manifest_sha256) `
        -Message "Current pointer generation-manifest hash mismatch."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Synchronized marker, immutable generation, and current pointer form the expected $($managedTargets.Count)-target closure."

    $wrapperInstanceActivation = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $wrapperInstanceActivation -ExitCode 0 -Label "Wrapper instance activation"
    Assert-StructuredCommandResult -Result $wrapperInstanceActivation -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "COMPLETE" -Label "Wrapper instance activation"
    $wrapperInstance = Get-TestCurrentInstanceSelection
    Assert-TestStableInstanceWrapper
    $wrapperDiagnosticSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $wrapperDiagnosticSync -ExitCode 0 -Label "Wrapper diagnostic Host restoration"
    Assert-CanonicalFilesInstalled
    $fixtureRuntimeRoot = $wrapperInstance.Root
    $fixtureRuntimeRelativePath = [string]$wrapperInstance.Selection.instance_relative_path
    $fixtureProviderName = "codedb-fixture-$(([string]$wrapperInstance.Selection.instance_id).Substring(0, 8))"
    $env:RICE_CODEDB_UNITY_ROOT = [System.IO.Path]::GetFullPath($hostRoot)
    $env:RICE_CODEDB_INSTANCE_ROOT = [System.IO.Path]::GetFullPath($fixtureRuntimeRoot)
    $fixtureInstanceEnvironmentSet = $true

    $materializedPrepare = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/prepare-codedb-project-runtime.ps1")
    $prepareResult = Invoke-NativeProcess `
        -FilePath $powershellPath `
        -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$materializedPrepare`"" `
        -WorkingDirectory $hostRoot
    Assert-Result -Result $prepareResult -ExitCode 0 -Label "Initial runtime config preparation"
    $generatedConfig = Join-Path $fixtureRuntimeRoot "config\codedb-mcp.toml"
    Assert-True -Condition (Test-Path -LiteralPath $generatedConfig -PathType Leaf) -Message "Materialized prepare-runtime did not generate the fixture config."
    $generatedConfigText = Get-Content -LiteralPath $generatedConfig -Raw
    Assert-True -Condition ($generatedConfigText.Contains("$fixtureRuntimeRelativePath/index")) -Message "Materialized prepare-runtime resolved the wrong instance index root."
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
    $adapterManifestPath = Join-Path $fixtureRuntimeRoot "adapter\text-index\manifest.json"
    Assert-True -Condition (Test-Path -LiteralPath $adapterManifestPath -PathType Leaf) -Message "Materialized builder did not publish the adapter manifest."
    $adapterManifest = Get-Content -LiteralPath $adapterManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adapterManifest.buildReason -Expected "manual" -Message "Materialized builder reason mismatch."
    Assert-Equal -Actual $adapterManifest.fileCount -Expected 2 -Message "Materialized builder file count mismatch."
    Assert-Equal -Actual $adapterManifest.files[0].path -Expected "Assets/MaterializerProbe.shader" -Message "Materialized builder indexed the wrong fixture file."

    $materializedWorker = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/run-codedb-project-text-adapter-worker.ps1")
    $workerRequestId = "materializer-adapter-probe"
    $workerProbeDeferred = $false
    try {
        $workerProbe = Invoke-AdapterWorkerRequest `
            -WorkerPath $materializedWorker `
            -BuilderPath $materializedBuilder `
            -Request ([ordered]@{
                schema_version = 1
                action = "build"
                request_id = $workerRequestId
                reason = "Automatic"
            })
    } catch {
        if ($_.Exception.Message.Contains("spawn EPERM") -and
            [string]::Equals($env:RICE_CODEDB_TEST_ALLOW_SPAWN_EPERM, "1", [StringComparison]::Ordinal)) {
            $workerProbeDeferred = $true
            Write-Host "[DEFERRED] Adapter worker protocol integration could not spawn PowerShell in the current managed test environment."
        } else {
            throw
        }
    }
    if (-not $workerProbeDeferred) {
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
    }

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
    Assert-Equal -Actual $wrapperContext.provider_name -Expected $fixtureProviderName -Message "Materialized wrapper provider name mismatch."
    Assert-Equal -Actual $wrapperContext.runtime_root -Expected $fixtureRuntimeRelativePath -Message "Materialized wrapper runtime root mismatch."
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
    Assert-Equal -Actual $outerContext.provider_name -Expected $fixtureProviderName -Message "Wrapper did not derive its project from its installed path."
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
    Assert-True -Condition ($wrongRootAssertion.Text -like "*--root must match the wrapper-owned Unity project*") -Message "Wrong Unity root did not report the wrapper ownership mismatch."
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
            Assert-True -Condition ($generationLeaseDryRun.Text.Contains("[PRODUCT_STATE] READY")) -Message "DryRun did not report the selected immutable instance as READY."
            Assert-True -Condition ($generationLeaseDryRun.Text.Contains("[INSTANCE] $($wrapperInstance.Selection.instance_id)")) -Message "DryRun did not report the selected immutable instance."

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
            "[OK] $fixtureProviderName wrapper ready.",
            "Provider executable: present",
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

    # Immutable-instance handoff is session-scoped: an already-running wrapper
    # keeps its instance manifest, while a newly started wrapper resolves the
    # atomically selected current-instance.json.
    $instanceSelectionPath = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/.runtime/codedb/control/current-instance.json"
    $originalInstanceSelectionBytes = [System.IO.File]::ReadAllBytes($instanceSelectionPath)
    $handoffInstanceId = [guid]::NewGuid().ToString("N")
    $handoffInstanceRelativePath = "AIWork/.runtime/codedb/instances/$handoffInstanceId"
    $handoffInstanceRoot = Get-PathFromRelative -Root $hostRoot -RelativePath $handoffInstanceRelativePath
    $oldInstanceManifestHash = Get-FileHash -LiteralPath (Join-Path $wrapperInstance.Root "instance.json") -Algorithm SHA256
    $handoffWrapperProcess = $null
    $handoffWrapperStarted = $false
    try {
        Copy-Item -LiteralPath $wrapperInstance.Root -Destination $handoffInstanceRoot -Recurse
        foreach ($volatileRelativePath in @("leases", "watch/lifecycle/editor-leases")) {
            $volatilePath = Join-Path $handoffInstanceRoot ($volatileRelativePath.Replace('/', '\'))
            if (Test-Path -LiteralPath $volatilePath) {
                Remove-Item -LiteralPath $volatilePath -Recurse -Force
            }
        }

        $handoffManifestPath = Join-Path $handoffInstanceRoot "instance.json"
        $handoffManifest = Get-Content -LiteralPath $handoffManifestPath -Raw | ConvertFrom-Json
        $handoffManifest.instance_id = $handoffInstanceId
        $handoffManifest.instance_relative_path = $handoffInstanceRelativePath
        Write-Utf8File -Path $handoffManifestPath -Content (($handoffManifest | ConvertTo-Json -Depth 16) + "`n")
        $handoffManifestHash = (Get-FileHash -LiteralPath $handoffManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()

        $handoffSelection = ([System.Text.UTF8Encoding]::new($false, $true).GetString($originalInstanceSelectionBytes)) | ConvertFrom-Json
        $handoffSelection.instance_id = $handoffInstanceId
        $handoffSelection.instance_relative_path = $handoffInstanceRelativePath
        $handoffSelection.instance_manifest_sha256 = $handoffManifestHash

        $handoffStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $handoffStartInfo.FileName = $nodePath
        $handoffStartInfo.Arguments = "`"$materializedWrapper`" --root `"$hostRoot`""
        $handoffStartInfo.WorkingDirectory = $hostRoot
        $handoffStartInfo.UseShellExecute = $false
        $handoffStartInfo.CreateNoWindow = $true
        $handoffStartInfo.RedirectStandardInput = $true
        $handoffStartInfo.RedirectStandardOutput = $true
        $handoffStartInfo.RedirectStandardError = $true
        $handoffWrapperProcess = [System.Diagnostics.Process]::new()
        $handoffWrapperProcess.StartInfo = $handoffStartInfo
        $null = $handoffWrapperProcess.Start()
        $handoffWrapperStarted = $true
        $handoffWrapperStderrTask = $handoffWrapperProcess.StandardError.ReadToEndAsync()
        $null = Invoke-WrapperRpc -Process $handoffWrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 21
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        Assert-True -Condition (@(Get-ChildItem -LiteralPath (Join-Path $wrapperInstance.Root "leases") -Force -File -ErrorAction SilentlyContinue).Count -gt 0) -Message "Running wrapper did not publish its immutable instance lease."

        # Switch the selection while the old session is still running. It must
        # continue to report the old instance and never follow this pointer.
        Write-Utf8File -Path $instanceSelectionPath -Content (($handoffSelection | ConvertTo-Json -Depth 16) + "`n")
        $oldSessionStatusRpc = Invoke-WrapperRpc -Process $handoffWrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 22
            method = "tools/call"
            params = [ordered]@{ name = "codedb_status"; arguments = [ordered]@{} }
        })
        $oldSessionStatus = [string]$oldSessionStatusRpc.result.content[0].text
        $newFixtureProviderName = "codedb-fixture-$($handoffInstanceId.Substring(0, 8))"
        Assert-True -Condition ($oldSessionStatus.Contains($fixtureProviderName)) -Message "Running wrapper did not retain its original immutable instance after current-instance switched."
        Assert-True -Condition (-not $oldSessionStatus.Contains($newFixtureProviderName)) -Message "Running wrapper followed a newly selected instance during an active session."
        Assert-Equal -Actual (Get-FileHash -LiteralPath (Join-Path $wrapperInstance.Root "instance.json") -Algorithm SHA256).Hash -Expected $oldInstanceManifestHash.Hash -Message "Running wrapper changed the old instance manifest."

        $handoffWrapperProcess.StandardInput.Close()
        if (-not $handoffWrapperProcess.WaitForExit(10000)) {
            $handoffWrapperProcess.Kill()
            $handoffWrapperProcess.WaitForExit()
        }
        $handoffWrapperError = $handoffWrapperStderrTask.Result.Trim()
        if ($handoffWrapperProcess.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($handoffWrapperError)) {
            throw "Old immutable-instance wrapper exited with code $($handoffWrapperProcess.ExitCode).`n$handoffWrapperError"
        }
        $handoffWrapperStarted = $false
        $newSessionStatus = Invoke-WrapperToolProbe `
            -WrapperPath $materializedWrapper `
            -Root $hostRoot `
            -ToolName "codedb_status" `
            -Arguments ([ordered]@{})
        Assert-True -Condition ($newSessionStatus.Contains($newFixtureProviderName)) -Message "New wrapper session did not resolve the newly selected immutable instance."
        Assert-True -Condition (-not $newSessionStatus.Contains($fixtureProviderName)) -Message "New wrapper session retained the previous immutable instance."
        Write-Host "[OK] Immutable-instance handoff retained the old running session and selected the new instance for a new wrapper session."
    } finally {
        if ($handoffWrapperStarted -and $null -ne $handoffWrapperProcess -and -not $handoffWrapperProcess.HasExited) {
            $handoffWrapperProcess.Kill()
            $handoffWrapperProcess.WaitForExit()
        }
        if ($null -ne $handoffWrapperProcess) {
            $handoffWrapperProcess.Dispose()
        }
        [System.IO.File]::WriteAllBytes($instanceSelectionPath, $originalInstanceSelectionBytes)
        if (Test-Path -LiteralPath $handoffInstanceRoot) {
            Remove-Item -LiteralPath $handoffInstanceRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
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
    Assert-True -Condition ($pidReuseDryRun.Text.Contains("[PRODUCT_STATE] READY")) -Message "PID-reuse DryRun did not retain READY instance status."
    $pidReuseRecovery = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $pidReuseRecovery -ExitCode 0 -Label "PID-reuse generation lease recovery"
    Assert-True -Condition ($pidReuseRecovery.Text.Contains("[RECOVERED] Removed stale generation $generationId mcp lease for PID $PID.")) -Message "PID-reuse generation lease was not reclaimed."
    Assert-True -Condition (-not (Test-Path -LiteralPath $pidReuseLease)) -Message "PID-reuse generation lease remained after recovery."
    Assert-True -Condition (Test-Path -LiteralPath $temporaryLeasePath -PathType Leaf) -Message "Fresh atomic generation lease temp file was unexpectedly reclaimed."
    Remove-Item -LiteralPath $temporaryLeasePath -Force
    Write-Host "[OK] Generation lease PID reuse was reclaimed while fresh atomic publication temp files stayed non-blocking."
    $fixtureWatchRoot = Join-Path $fixtureRuntimeRoot "watch"
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
    $fixtureProviderExecutable = $fixtureMachineProvider.ExecutablePath
    $watchConfigPath = Join-Path $fixtureRuntimeRoot "config\codedb-mcp.watch.toml"
    $watchMarkerPath = Join-Path $fixtureWatchRoot "auto-start.json"
    $watchPausedMarkerPath = Join-Path $fixtureWatchRoot "automatic-refresh-paused.json"
    $lifecycleRoot = Join-Path $fixtureWatchRoot "lifecycle"
    $desiredStatePath = Join-Path $lifecycleRoot "desired-state.json"
    $manualRuntimePath = Join-Path $lifecycleRoot "manual-runtime.json"
    $editorLeaseRoot = Join-Path $lifecycleRoot "editor-leases"
    $coordinatorRuntime = Join-Path $fixtureWatchRoot "coordinator"
    $coordinatorStatePath = Join-Path $coordinatorRuntime "coordinator-state.json"
    $materializedProviderGuidance = Get-PathFromRelative -Root $hostRoot -RelativePath ($generationTargetPrefix + "scripts/show-codedb-project-provider-guidance.ps1")
    $disabledFixtureProviderManifest = $fixtureMachineProvider.ManifestPath + ".guidance-disabled"
    Move-Item -LiteralPath $fixtureMachineProvider.ManifestPath -Destination $disabledFixtureProviderManifest
    try {
        $beforeMissingGuidance = Get-FileSnapshot -Root $hostRoot
        $missingGuidanceResult = Invoke-PowerShellAction -Action {
            & $materializedProviderGuidance
        }
        Assert-Result -Result $missingGuidanceResult -ExitCode 0 -Label "Materialized provider guidance without machine manifest"
        foreach ($expectedGuidance in @(
            "The provider executable is an external dependency.",
            "This project does not vendor, download, or commit the provider binary in this flow.",
            "Do not write user/global MCP client configuration from this setup flow.",
            "[MISSING_PREREQUISITE] CodeDB Provider 0.5.0-28e3912 is missing."
        )) {
            Assert-True -Condition ($missingGuidanceResult.Text.Contains($expectedGuidance)) -Message "Provider guidance is missing '$expectedGuidance'."
        }
        Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMissingGuidance -Message "Provider guidance mutated the fixture while the machine manifest was missing."
    } finally {
        Move-Item -LiteralPath $disabledFixtureProviderManifest -Destination $fixtureMachineProvider.ManifestPath -Force
    }

    $beforeAvailableGuidance = Get-FileSnapshot -Root $hostRoot
    $availableGuidanceResult = Invoke-PowerShellAction -Action {
        & $materializedProviderGuidance
    }
    Assert-Result -Result $availableGuidanceResult -ExitCode 0 -Label "Materialized provider guidance with machine Provider"
    Assert-True -Condition ($availableGuidanceResult.Text.Contains("and CodeDB Provider 0.5.0-28e3912 are verified.")) -Message "Provider guidance did not verify the machine Provider fixture."
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
        adapter_manifest = [System.IO.Path]::GetFullPath((Join-Path $fixtureRuntimeRoot "adapter\text-index\manifest.json"))
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
    Assert-True -Condition ($activeWatcherDryRun.Text.Contains("[PRODUCT_STATE] READY")) -Message "Active watcher DryRun did not retain READY instance status."
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
        "Active provider config: $fixtureRuntimeRelativePath/config/codedb-mcp.watch.toml"
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
    $providerRoot = $fixtureRuntimeRoot
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
        "Machine Provider identity/hash and project-local runtime config are valid.",
        "Generated .codedbignore matches the AIWork template.",
        "AIWork/.runtime/codedb stays inside the Unity project.",
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

    $fixtureMcpConfigPath = Join-Path $hostRoot ".codex\config.toml"
    $stableMcpConfigBytes = [System.IO.File]::ReadAllBytes($fixtureMcpConfigPath)
    $stableMcpConfigLastWriteTimeUtc = [System.IO.File]::GetLastWriteTimeUtc($fixtureMcpConfigPath)
    $stableMcpConfig = [System.Text.UTF8Encoding]::new($false, $true).GetString($stableMcpConfigBytes)
    $instanceMcpConfig = $stableMcpConfig.Replace(
        "[mcp_servers.codedb-fixture]",
        "[mcp_servers.$fixtureProviderName]")
    Write-Utf8File -Path $fixtureMcpConfigPath -Content $instanceMcpConfig
    try {
        $beforeMcpGuidance = Get-FileSnapshot -Root $hostRoot
        $mcpDraftResult = Invoke-PowerShellAction -Action {
            & $materializedMcpDraft
        }
        Assert-Result -Result $mcpDraftResult -ExitCode 0 -Label "Materialized MCP registration draft"
        foreach ($expected in @(
            "$fixtureProviderName MCP registration draft",
            "Status: review draft only; no MCP client configuration was written.",
            "- Target file: .codex/config.toml",
            "[mcp_servers.$fixtureProviderName]",
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

        $validMcpConfig = Get-Content -LiteralPath $fixtureMcpConfigPath -Raw
        $validMcpConfigLastWriteTimeUtc = [System.IO.File]::GetLastWriteTimeUtc($fixtureMcpConfigPath)
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
[mcp_servers.$fixtureProviderName]
command = "$($fixtureMachineProvider.ExecutablePath)"
cwd = "."
args = ["mcp", "--root", ".", "--config", "$fixtureRuntimeRelativePath/config/codedb-mcp.toml", "--no-watch"]
startup_timeout_sec = 120
"@
        $directProviderValidation = Invoke-PowerShellAction -Action {
            & $materializedMcpValidator
        }
        Assert-Result -Result $directProviderValidation -ExitCode 1 -Label "Direct-Provider MCP project config validation"
        Assert-True `
            -Condition ($directProviderValidation.Text.Contains("FAIL: Direct Provider registration is not accepted for formal project MCP configuration. Use the project wrapper.")) `
            -Message "MCP validator accepted the direct Provider transition shape."
        Write-Utf8File -Path $fixtureMcpConfigPath -Content $validMcpConfig
        [System.IO.File]::SetLastWriteTimeUtc($fixtureMcpConfigPath, $validMcpConfigLastWriteTimeUtc)
        Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMcpGuidance -Message "MCP project config validation changed host files."
        Write-Host "[OK] Materialized MCP draft enforced cwd and wrapper-only registration without mutating host configuration."
    } finally {
        [System.IO.File]::WriteAllBytes($fixtureMcpConfigPath, $stableMcpConfigBytes)
        [System.IO.File]::SetLastWriteTimeUtc($fixtureMcpConfigPath, $stableMcpConfigLastWriteTimeUtc)
    }

    $verify = Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $verify -ExitCode 0 -Label "Current Verify"
    $beforeIdempotent = Get-ManagedPayloadSnapshot -Root $hostRoot
    $syncAgain = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $syncAgain -ExitCode 0 -Label "Idempotent Sync"
    Assert-Equal -Actual (Get-ManagedPayloadSnapshot -Root $hostRoot) -Expected $beforeIdempotent -Message "Idempotent Sync changed managed state."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Verify and idempotent no-op passed."

    $fixtureMcpConfigPath = Join-Path $hostRoot ".codex\config.toml"
    $fixtureMcpConfigBytes = [System.IO.File]::ReadAllBytes($fixtureMcpConfigPath)
    $fixtureMcpConfigLastWriteTimeUtc = [System.IO.File]::GetLastWriteTimeUtc($fixtureMcpConfigPath)
    Remove-Item -LiteralPath $fixtureMcpConfigPath -Force
    $repairMissingConfig = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $repairMissingConfig -ExitCode 0 -Label "Repair missing MCP config"
    Assert-True -Condition ($repairMissingConfig.Text.Contains("[RESULT] REPAIRED")) -Message "Repair did not report the unified repaired result."
    foreach ($expectedProductMarker in @(
        "[PRODUCT_LAYER INSTALLED] CURRENT",
        "[PRODUCT_LAYER CONFIGURED] CURRENT",
        "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT",
        "[PRODUCT_STATE] READY"
    )) {
        Assert-True -Condition ($repairMissingConfig.Text.Contains($expectedProductMarker)) -Message "Repair availability result is missing '$expectedProductMarker'."
    }
    Assert-True -Condition ($repairMissingConfig.Text.Contains("[NEXT] Start a new Codex session")) -Message "Repair did not report the single new-session next step."
    Assert-True -Condition (Test-Path -LiteralPath $fixtureMcpConfigPath -PathType Leaf) -Message "Repair did not create the missing project MCP config."
    $mcpAvailabilityPath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\mcp-availability.json"
    Assert-True -Condition (Test-Path -LiteralPath $mcpAvailabilityPath -PathType Leaf) -Message "Repair did not publish Package-owned MCP availability evidence."
    $availabilityDocument = Get-Content -LiteralPath $mcpAvailabilityPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual ([int]$availabilityDocument.schema_version) -Expected 2 -Message "Repair availability evidence schema mismatch."
    Assert-Equal -Actual ([string]$availabilityDocument.availability) -Expected "AVAILABLE" -Message "Repair availability evidence did not report AVAILABLE."
    Assert-Equal -Actual ([string]$availabilityDocument.generation_id) -Expected $generationId -Message "Repair availability evidence did not bind the current generation."
    Assert-Equal `
        -Actual (@($availabilityDocument.tool_names | Sort-Object) -join "|") `
        -Expected "codedb_context|codedb_find|codedb_read|codedb_search|codedb_status|codedb_text_search" `
        -Message "Repair availability evidence did not bind the complete expected tool list."
    Assert-True -Condition ([bool]$availabilityDocument.codedb_status_callable) -Message "Repair availability evidence did not prove codedb_status callable."
    Assert-True -Condition ([bool]$availabilityDocument.codedb_status_usable) -Message "Repair availability evidence did not prove a usable project status."
    Assert-True -Condition ([bool]$availabilityDocument.codedb_text_search_callable) -Message "Repair availability evidence did not prove bounded codedb_text_search callable."
    $beforeExplicitProbe = Get-FileSnapshot -Root $hostRoot
    $explicitProbe = Invoke-Materializer -Action "Probe" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $explicitProbe -ExitCode 0 -Label "Explicit Package-owned MCP availability probe"
    Assert-True -Condition ($explicitProbe.Text.Contains("[PRODUCT_LAYER MCP_AVAILABLE] CURRENT")) -Message "Explicit availability probe did not report the current MCP availability layer."
    Assert-True -Condition ($explicitProbe.Text.Contains("[PRODUCT_STATE] READY")) -Message "Explicit availability probe did not reduce the verified layers to READY."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeExplicitProbe -Message "Repeated current availability probe changed project bytes."
    $repairSnapshot = Get-FileSnapshot -Root $hostRoot
    $repairAgain = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $repairAgain -ExitCode 0 -Label "Idempotent Repair"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $repairSnapshot -Message "Repeated Repair changed the fixture after it was current."
    [System.IO.File]::WriteAllBytes($fixtureMcpConfigPath, $fixtureMcpConfigBytes)
    [System.IO.File]::SetLastWriteTimeUtc($fixtureMcpConfigPath, $fixtureMcpConfigLastWriteTimeUtc)
    $repairBackupRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\mcp-config-backups"
    if (Test-Path -LiteralPath $repairBackupRoot) {
        Remove-Item -LiteralPath $repairBackupRoot -Recurse -Force
    }
    Assert-NoMaterializerResidue
    Write-Host "[OK] One Repair action created missing MCP registration and repeated byte-exactly without authorization input."

    $env:RICE_CODEDB_UNITY_ROOT = $fixturePreviousUnityRoot
    $env:RICE_CODEDB_INSTANCE_ROOT = $fixturePreviousInstanceRoot
    $fixtureInstanceEnvironmentSet = $false
    Clear-ManagedTestState
    $postInstanceDiagnosticSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $postInstanceDiagnosticSync -ExitCode 0 -Label "Post-instance diagnostic Host restoration"
    Assert-CanonicalFilesInstalled

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
    $unknownSameNameBefore = Get-FileSnapshot -Root $hostRoot
    $unknownDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownDryRun -ExitCode 0 -Label "Unknown same-name DryRun"
    Assert-True -Condition ($unknownDryRun.Text.Contains("[PRODUCT_STATE] NEEDS_ATTENTION")) -Message "DryRun did not report the missing immutable instance."
    Assert-True -Condition ($unknownDryRun.Text.Contains("[INSTANCE] NONE")) -Message "DryRun did not report that no immutable instance is selected."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "DryRun changed unknown same-name content or wrote diagnostics."
    $unknownVerify = Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownVerify -ExitCode 0 -Label "Unknown same-name Verify status"
    Assert-True -Condition ($unknownVerify.Text.Contains("[PRODUCT_STATE] NEEDS_ATTENTION")) -Message "Verify did not report the missing immutable instance."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "Verify changed unknown same-name content or wrote diagnostics."
    $unknownUpgrade = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownUpgrade -ExitCode 6 -Label "Unknown same-name Upgrade refusal"
    Assert-StructuredCommandResult -Result $unknownUpgrade -Action "UPGRADE" -Outcome "BLOCKED" -CleanupState "COMPLETE" -Label "Unknown same-name Upgrade refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "Upgrade changed unknown same-name content or wrote diagnostics."
    $unknownReinstall = Invoke-Materializer -Action "Reinstall" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownReinstall -ExitCode 6 -Label "Unknown same-name Reinstall refusal"
    Assert-StructuredCommandResult -Result $unknownReinstall -Action "REINSTALL" -Outcome "BLOCKED" -CleanupState "COMPLETE" -Label "Unknown same-name Reinstall refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "Reinstall changed unknown same-name content or wrote diagnostics."
    $unknownRepair = Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unknownRepair -ExitCode 4 -Label "Unknown same-name Repair refusal"
    Assert-True -Condition ($unknownRepair.Text.Contains("[RESULT] BLOCKED")) -Message "Unknown same-name Repair did not report BLOCKED."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "Repair changed unknown same-name content or wrote diagnostics."
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 3 -Label "Unknown same-name Sync refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "Sync changed unknown same-name content or wrote diagnostics."
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Unknown same-name Remove boundary"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $unknownSameNameBefore -Message "Remove changed unknown same-name content or wrote diagnostics."
        Write-Host "[OK] Unknown same-name content remained byte-exact while instance activation failed closed."
    }

    Clear-ManagedTestState
    $firstAutomaticAdoption = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $firstAutomaticAdoption -ExitCode 0 -Label "Fresh automatic first adoption"
    Assert-StructuredCommandResult -Result $firstAutomaticAdoption -Action "UPGRADE" -Outcome "UPGRADED" -CleanupState "COMPLETE" -Label "Fresh automatic first adoption"
    Assert-True -Condition ($firstAutomaticAdoption.Text.Contains("[PRODUCT_STATE] READY")) -Message "Automatic first adoption did not reach READY."
    $firstAutomaticInstance = Get-TestCurrentInstanceSelection
    Assert-TestStableInstanceWrapper
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Fresh automatic adoption Verify"
    $repeatedAutomaticAdoption = Invoke-Materializer -Action "Upgrade" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $repeatedAutomaticAdoption -ExitCode 0 -Label "Repeated automatic first adoption"
    Assert-StructuredCommandResult -Result $repeatedAutomaticAdoption -Action "UPGRADE" -Outcome "CONVERGED" -CleanupState "COMPLETE" -Label "Repeated automatic first adoption"
    Assert-Equal -Actual ([string](Get-TestCurrentInstanceSelection).Selection.instance_id) -Expected ([string]$firstAutomaticInstance.Selection.instance_id) -Message "Repeated automatic adoption replaced an already-ready instance."
    Write-Host "[OK] Fresh empty scope activated one immutable instance and repeated without replacement."

    $postAdoptionUninstall = Invoke-Materializer -Action "Uninstall" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $postAdoptionUninstall -ExitCode 0 -Label "Post-first-adoption Uninstall"
    Assert-StructuredCommandResult -Result $postAdoptionUninstall -Action "UNINSTALL" -Outcome "UNINSTALLED" -CleanupState "COMPLETE" -Label "Post-first-adoption Uninstall"
    Clear-ManagedTestState

    $atomicTargetRelativePath = "AIWork/codedb/codedbignore.example"
    $atomicOldContent = "atomic-reader-old`n" + [string]::new([char]65, 2 * 1024 * 1024)
    $atomicNewContent = "atomic-reader-new`n" + [string]::new([char]66, 2 * 1024 * 1024)
    $atomicV1Entries = [ordered]@{ $atomicTargetRelativePath = $atomicOldContent }
    $atomicV2Entries = [ordered]@{ $atomicTargetRelativePath = $atomicNewContent }
    $atomicV1Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "atomic-v1") -PayloadVersion "test.1" -Entries $atomicV1Entries
    $atomicV2Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "atomic-v2") -PayloadVersion "test.2" -Entries $atomicV2Entries
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $atomicV1Root) -ExitCode 0 -Label "Atomic reader v1 Sync"
    $atomicV1Manifest = Get-Content -LiteralPath (Join-Path $atomicV1Root "payload-manifest.json") -Raw | ConvertFrom-Json
    Assert-Equal -Actual (@($atomicV1Manifest.bootstrap_transitions).Count) -Expected 0 -Message "Synthetic payload bootstrap transition contract mismatch."
    $atomicV1Marker = Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) -Raw | ConvertFrom-Json
    $atomicV1ExpectedIdentity = Get-TestPayloadContentIdentitySha256 `
        -Manifest $atomicV1Manifest `
        -CurrentPointerTarget $currentPointerRelativePath `
        -GenerationTargetPrefix $generationTargetPrefix
    Assert-Equal `
        -Actual ([string]$atomicV1Marker.payload_content_sha256) `
        -Expected $atomicV1ExpectedIdentity `
        -Message "Synthetic Sync marker identity does not match the production payload contract."
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
    $packageMetadataManifest.package_version = "0.2.5-preview.6"
    $packageMetadataManifest.retired_targets = @("AIWork/codedb/codedb-mcp.runtime.example.toml")
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

    $beforeSyntheticCrash = Get-FileSnapshot -Root $hostRoot
    $syntheticCrash = Invoke-Materializer `
        -Action "Sync" `
        -PayloadRoot $v1Root `
        -TestCrashAfterMutation 1
    Assert-Result -Result $syntheticCrash -ExitCode 86 -Label "Synthetic non-generation journal crash"
    $transactionRuntimePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer"
    $syntheticTransactions = @(Get-ChildItem -LiteralPath $transactionRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $syntheticTransactions.Count -Expected 1 -Message "Synthetic crash did not retain exactly one transaction."
    $syntheticJournalPath = Join-Path $syntheticTransactions[0].FullName "transaction.json"
    $syntheticJournal = Get-Content -LiteralPath $syntheticJournalPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $syntheticJournal.schema_version -Expected 2 -Message "Synthetic journal did not record schema 2 provenance."
    Assert-True -Condition ($null -eq $syntheticJournal.generation_manifest_sha256) -Message "Non-generation journal unexpectedly recorded an immutable generation hash."
    Assert-True -Condition (@($syntheticJournal.entries).Count -gt 1) -Message "Synthetic journal did not preserve its entry array."
    $syntheticRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $v1Root
    Assert-Result -Result $syntheticRecovery -ExitCode 0 -Label "Synthetic non-generation journal recovery"
    Assert-True -Condition ($syntheticRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Synthetic journal recovery did not report the rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeSyntheticCrash -Message "Synthetic journal recovery did not restore the exact pre-crash tree."
    Assert-NoMaterializerResidue

    $collisionJournalCrash = Invoke-Materializer `
        -Action "Sync" `
        -PayloadRoot $collisionRoot `
        -TestCrashAfterMutation 1
    Assert-Result -Result $collisionJournalCrash -ExitCode 86 -Label "Same-sequence journal collision setup"
    $beforeCollisionJournalRefusal = Get-FileSnapshot -Root $hostRoot
    $collisionJournalRefusal = Invoke-Materializer -Action "Remove" -PayloadRoot $v2Root
    Assert-Result -Result $collisionJournalRefusal -ExitCode 3 -Label "Same-sequence journal collision refusal"
    Assert-True -Condition ($collisionJournalRefusal.Text.Contains("SequenceCollision: pending transaction")) -Message "Remove did not identify the pending same-sequence journal collision."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeCollisionJournalRefusal -Message "Same-sequence journal refusal changed project or control-state bytes."
    $collisionJournalCleanup = Invoke-Materializer -Action "Remove" -PayloadRoot $collisionRoot
    Assert-Result -Result $collisionJournalCleanup -ExitCode 0 -Label "Same-sequence journal collision cleanup"
    Assert-True -Condition ($collisionJournalCleanup.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Matching payload did not recover the collision journal fixture."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeSyntheticCrash -Message "Collision journal cleanup did not restore the empty managed scope."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Ordinary transaction journals retained Package provenance, allowed null generation identity, recovered exactly, and rejected same-sequence collisions."

    Install-LegacyPoc21Fixture
    $automaticJournalCrash = Invoke-Materializer `
        -Action "Upgrade" `
        -PayloadRoot $canonicalPayloadRoot `
        -TestCrashBeforeWatcherHandoff
    Assert-Result -Result $automaticJournalCrash -ExitCode 86 -Label "Automatic journal immutable identity setup"
    $automaticRuntimePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer"
    $automaticTransactions = @(Get-ChildItem -LiteralPath $automaticRuntimePath -Force -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue)
    Assert-Equal -Actual $automaticTransactions.Count -Expected 1 -Message "Automatic crash did not retain exactly one transaction."
    $automaticJournalPath = Join-Path $automaticTransactions[0].FullName "transaction.json"
    $automaticJournalText = Get-Content -LiteralPath $automaticJournalPath -Raw
    $automaticJournal = $automaticJournalText | ConvertFrom-Json
    Assert-True -Condition ([string]$automaticJournal.generation_manifest_sha256 -match '^[0-9a-f]{64}$') -Message "Automatic journal did not record its immutable generation hash."
    $automaticJournal.generation_manifest_sha256 = $null
    Write-Utf8File -Path $automaticJournalPath -Content (($automaticJournal | ConvertTo-Json -Depth 8) + "`n")
    $beforeMissingAutomaticIdentity = Get-FileSnapshot -Root $hostRoot
    $missingAutomaticIdentity = Invoke-Materializer `
        -Action "DryRun" `
        -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $missingAutomaticIdentity -ExitCode 1 -Label "Automatic journal missing immutable identity"
    Assert-True -Condition ($missingAutomaticIdentity.Text.Contains("Pending automatic-upgrade journal does not match the current Package generation identity.")) -Message "DryRun did not reject the missing automatic generation identity."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMissingAutomaticIdentity -Message "Automatic journal identity refusal changed project bytes."
    Write-Utf8File -Path $automaticJournalPath -Content $automaticJournalText
    $automaticJournalRecovery = Invoke-Materializer `
        -Action "Upgrade" `
        -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $automaticJournalRecovery -ExitCode 0 -Label "Automatic journal immutable identity recovery"
    Assert-True -Condition ($automaticJournalRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Automatic journal recovery did not report its rollback."
    Assert-Result `
        -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) `
        -ExitCode 0 `
        -Label "Automatic journal fixture cleanup"
    Assert-NoMaterializerResidue
    Write-Host "[OK] Automatic recovery required a non-null Package-owned immutable generation identity."

    if ($TransactionOnly) {
        Assert-SentinelsUnchanged -ExpectedSnapshot $sentinelSnapshot
        Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "Transaction acceptance modified package source files."
        Write-Host "[OK] Transaction and strict-JSON regression scenarios passed."
        $fixturePassed = $true
        return
    }

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
        -PayloadVersion "poc.29-test-upgrade" `
        -PayloadSequence 30 `
        -PackageVersion "0.2.6-test" `
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

    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Version-control independence setup Sync"
    $null = Invoke-FixtureIndexGit -Arguments @("read-tree", "--empty")
    $stagedRelativePath = "AIWork/codedb/scripts/codedb-project-common.ps1"
    $stagedTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $stagedRelativePath
    $stagedGitPath = Get-ProjectGitPath -Path $stagedTargetPath
    Write-Utf8File -Path $stagedTargetPath -Content "staged managed variant`n"
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $stagedGitPath)
    Copy-Item -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $stagedRelativePath) -Destination $stagedTargetPath -Force
    $indexBefore = (@(Invoke-FixtureIndexGit -Arguments @("diff", "--cached", "--name-only")) -join "`n")
    $indexBytesBefore = Get-ByteSnapshot -Path $fixtureGitIndexPath
    Assert-Result -Result (Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Staged-state-independent DryRun"
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Staged-state-independent Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Staged-state-independent Sync"
    Assert-Result -Result (Invoke-Materializer -Action "Repair" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Staged-state-independent Repair"
    Assert-Equal -Actual (Get-ByteSnapshot -Path $fixtureGitIndexPath) -Expected $indexBytesBefore -Message "CodeDB changed the caller's isolated Git index bytes."
    Assert-Equal -Actual (@(Invoke-FixtureIndexGit -Arguments @("diff", "--cached", "--name-only")) -join "`n") -Expected $indexBefore -Message "CodeDB changed the caller's staged paths."
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Staged-state-independent Remove"
    Assert-Equal -Actual (Get-ByteSnapshot -Path $fixtureGitIndexPath) -Expected $indexBytesBefore -Message "Remove changed the caller's isolated Git index bytes."
    Assert-Equal -Actual (@(Invoke-FixtureIndexGit -Arguments @("diff", "--cached", "--name-only")) -join "`n") -Expected $indexBefore -Message "Remove changed the caller's staged paths."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $stagedGitPath)
    Write-Host "[OK] DryRun, Verify, Sync, Repair, and Remove ignored and preserved external Git staging."

    $crashedStagedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1
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
    $recoveryTargetText = Get-Content -LiteralPath $recoveryTargetPath -Raw
    Write-Utf8File -Path $recoveryTargetPath -Content "staged recovery variant`n"
    $recoveryGitPath = Get-ProjectGitPath -Path $recoveryTargetPath
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $recoveryGitPath)
    Write-Utf8File -Path $recoveryTargetPath -Content $recoveryTargetText
    $recoveryIndexBefore = Get-ByteSnapshot -Path $fixtureGitIndexPath
    $completedStagedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $completedStagedRecovery -ExitCode 0 -Label "Staged-state-independent interrupted recovery"
    Assert-True -Condition ($completedStagedRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Interrupted recovery did not converge independently of external staging."
    Assert-Equal -Actual (Get-ByteSnapshot -Path $fixtureGitIndexPath) -Expected $recoveryIndexBefore -Message "Interrupted recovery changed the isolated Git index."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $recoveryGitPath)
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Interrupted transaction recovery converged without reading or changing external staging."

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
        bootstrap_transitions = @()
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
            $cleanupRuntime = if ($null -ne $fixtureRuntimeRoot) {
                Join-Path $fixtureRuntimeRoot "watch\coordinator"
            } else {
                Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\watch\coordinator"
            }
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
    if ($fixtureInstanceEnvironmentSet) {
        $env:RICE_CODEDB_UNITY_ROOT = $fixturePreviousUnityRoot
        $env:RICE_CODEDB_INSTANCE_ROOT = $fixturePreviousInstanceRoot
        $fixtureInstanceEnvironmentSet = $false
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
            $cleanupDelaysMilliseconds = @(100, 250, 500, 1000, 2000)
            for ($attempt = 0; ; $attempt++) {
                try {
                    Remove-Item -LiteralPath $fullRunRoot -Recurse -Force
                    break
                } catch [System.UnauthorizedAccessException], [System.IO.IOException] {
                    if ($attempt -ge $cleanupDelaysMilliseconds.Count) {
                        if (-not $fixturePassed) {
                            Write-Warning "Failed fixture cleanup remains pending at $fullRunRoot`: $($_.Exception.Message)"
                            break
                        }
                        throw
                    }
                    Start-Sleep -Milliseconds $cleanupDelaysMilliseconds[$attempt]
                }
            }
        } else {
            throw "Refusing to clean an unsafe POC path: $fullRunRoot"
        }
    }
    if (-not $preserveFailedFixture -and
        (Test-Path -LiteralPath $pocRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $pocRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $pocRoot -Force
    }
    $env:LOCALAPPDATA = $originalLocalAppData
}

if (-not $preserveFailedFixture) {
    Assert-True -Condition (-not (Test-Path -LiteralPath $runRoot)) -Message "POC fixture cleanup failed: $runRoot"
}
