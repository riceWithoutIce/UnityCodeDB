#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Ensure", "Enable", "Disable", "Start", "Status", "Pause", "Stop", "Restart")]
    [string]$Action,
    [ValidateRange(1, 10)]
    [int]$PollIntervalSeconds = 1,
    [ValidateRange(100, 10000)]
    [int]$AdapterDebounceMilliseconds = 750,
    [switch]$RequireNewOwner,
    [switch]$ExclusiveOwner,
    [ValidatePattern('^[A-Za-z0-9._-]{1,128}$')]
    [string]$LifecycleId,
    [ValidatePattern('^[A-Za-z0-9._-]{1,128}$')]
    [string]$ExpectedLifecycleId,
    [switch]$MaterializerHandoff,
    [int]$TestGenerationDrainTimeoutMilliseconds = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\codedb-project-common.ps1"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $temporaryPath = Join-Path $parent ("." + [System.IO.Path]::GetFileName($Path) + "." + [Guid]::NewGuid().ToString("N") + ".tmp")
    $backupPath = Join-Path $parent ("." + [System.IO.Path]::GetFileName($Path) + "." + [Guid]::NewGuid().ToString("N") + ".bak")
    try {
        $stream = [System.IO.File]::Open($temporaryPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try {
            $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
        } finally {
            $stream.Dispose()
        }
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [System.IO.File]::Replace($temporaryPath, $Path, $backupPath)
            Remove-Item -LiteralPath $backupPath -Force
        } else {
            [System.IO.File]::Move($temporaryPath, $Path)
        }
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $backupPath) {
            Remove-Item -LiteralPath $backupPath -Force
        }
    }
}

function Get-ProjectIdentity {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $canonical = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/').Replace('\', '/').ToLowerInvariant()
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($canonical))
    } finally {
        $sha256.Dispose()
    }
    return "sha256:" + (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Read-DesiredState {
    if (-not (Test-Path -LiteralPath $desiredStatePath -PathType Leaf)) {
        return $null
    }
    try {
        $document = Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json
    } catch {
        throw "CodeDB desired state is unreadable: $($_.Exception.Message)"
    }
    if ([int]$document.schema_version -ne 1 -or
        -not [string]::Equals([string]$document.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -or
        [string]$document.desired_state -notin @("enabled", "disabled") -or
        -not [string]::Equals([System.IO.Path]::GetFullPath([string]$document.project_root), [System.IO.Path]::GetFullPath($context.UnityRoot), [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals([string]$document.project_identity, $projectIdentity, [StringComparison]::Ordinal)) {
        throw "CodeDB desired state has invalid identity or schema."
    }
    return $document
}

function Write-DesiredState {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("enabled", "disabled")][string]$State,
        [Parameter(Mandatory = $true)][string]$Reason
    )

    $document = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        desired_state = $State
        project_root = [System.IO.Path]::GetFullPath($context.UnityRoot).TrimEnd('\', '/')
        project_identity = $projectIdentity
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
        updated_by = $Reason
    } | ConvertTo-Json -Depth 4
    Write-Utf8NoBom -Path $desiredStatePath -Content ($document + "`n")
}

function Get-ProcessStartTicks {
    param([Parameter(Mandatory = $true)][int]$ProcessId)

    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        if ($process.HasExited) {
            return $null
        }
        return $process.StartTime.ToUniversalTime().Ticks.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        return $null
    }
}

function Get-WatchProcessIdentity {
    param([AllowNull()]$ProcessId)

    try {
        $numericProcessId = [int]$ProcessId
        if ($numericProcessId -le 0) {
            return [pscustomobject]@{ Alive = $false; StartUnixMilliseconds = $null }
        }
    } catch {
        return [pscustomobject]@{ Alive = $false; StartUnixMilliseconds = $null }
    }

    try {
        $process = [System.Diagnostics.Process]::GetProcessById($numericProcessId)
    } catch [System.ArgumentException] {
        return [pscustomobject]@{ Alive = $false; StartUnixMilliseconds = $null }
    } catch {
        return [pscustomobject]@{ Alive = $true; StartUnixMilliseconds = $null }
    }
    try {
        if ($process.HasExited) {
            return [pscustomobject]@{ Alive = $false; StartUnixMilliseconds = $null }
        }
        $startOffset = [DateTimeOffset]::new($process.StartTime.ToUniversalTime())
        return [pscustomobject]@{
            Alive = $true
            StartUnixMilliseconds = $startOffset.ToUnixTimeMilliseconds()
        }
    } catch {
        # A visible but uninspectable process remains a conservative live owner.
        return [pscustomobject]@{ Alive = $true; StartUnixMilliseconds = $null }
    }
}

function Test-WatchGenerationProcessIdentity {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][string]$LeaseIdentity
    )

    [int64]$leaseStartMilliseconds = 0
    if (-not [int64]::TryParse($LeaseIdentity, [ref]$leaseStartMilliseconds) -or $leaseStartMilliseconds -le 0) {
        return $false
    }
    if (-not $ProcessIdentity.Alive -or $null -eq $ProcessIdentity.StartUnixMilliseconds) {
        return $null
    }
    return [Math]::Abs([int64]$ProcessIdentity.StartUnixMilliseconds - $leaseStartMilliseconds) -le 2000
}

function Test-WatchFixtureRoot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    try {
        $normalizedRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/').Replace('\', '/')
        $rootMatch = [regex]::Match(
            $normalizedRoot,
            '/AIWork/\.runtime/codedb/materializer-poc/(?<run>[0-9a-fA-F]{32})/fixture$',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $rootMatch.Success) {
            return $false
        }
        $markerPath = Join-Path $ProjectRoot ".rice-ai-codedb-poc-fixture.json"
        if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
            return $false
        }
        $markerItem = Get-Item -LiteralPath $markerPath -Force
        if (($markerItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            return $false
        }
        $marker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
        return [int]$marker.schema_version -eq 1 -and
            [string]::Equals([string]$marker.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -and
            [string]::Equals([string]$marker.purpose, "host-payload-materializer-poc", [StringComparison]::Ordinal) -and
            [string]::Equals([string]$marker.run_id, $rootMatch.Groups['run'].Value, [StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    }
}

function Assert-MaterializerHandoffMarker {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        throw "Materializer handoff requires an active upgrade marker: $MarkerPath"
    }
    $markerItem = Get-Item -LiteralPath $MarkerPath -Force
    if (($markerItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Materializer handoff marker must not be a reparse point: $MarkerPath"
    }
    try {
        $marker = Get-Content -LiteralPath $MarkerPath -Raw | ConvertFrom-Json
        $markerStartTicks = [string]$marker.process_start_ticks
        $actualStartTicks = Get-ProcessStartTicks -ProcessId $PID
        $valid = [int]$marker.schema_version -eq 1 -and
            [int]$marker.host_use_gate_version -eq 1 -and
            [string]::Equals([string]$marker.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -and
            [string]::Equals([System.IO.Path]::GetFullPath([string]$marker.project_root), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals([string]$marker.action, "upgrade", [StringComparison]::Ordinal) -and
            [int]$marker.pid -eq $PID -and
            $markerStartTicks -match '^[0-9]{1,20}$' -and
            -not [string]::IsNullOrWhiteSpace($actualStartTicks) -and
            [string]::Equals($markerStartTicks, $actualStartTicks, [StringComparison]::Ordinal)
    } catch {
        $valid = $false
    }
    if (-not $valid) {
        throw "Materializer handoff marker identity is invalid: $MarkerPath"
    }
}

function Get-LiveGenerationMcpLeaseReport {
    param(
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$LeasesRoot
    )

    $liveLeases = New-Object System.Collections.Generic.List[object]
    $invalidLeases = New-Object System.Collections.Generic.List[string]
    if ($GenerationId -notmatch '^[A-Za-z0-9._-]{1,64}$') {
        $invalidLeases.Add("invalid generation id: $GenerationId")
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); Invalid = $invalidLeases.ToArray(); Present = $false }
    }

    $leaseRoot = Join-Path $LeasesRoot $GenerationId
    Assert-CodedbPathInside -Path $leaseRoot -Root $ProjectRoot -Label "old-generation MCP lease runtime"
    if (-not (Test-Path -LiteralPath $leaseRoot)) {
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); Invalid = $invalidLeases.ToArray(); Present = $false }
    }
    if (-not (Test-Path -LiteralPath $leaseRoot -PathType Container)) {
        $invalidLeases.Add($leaseRoot)
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); Invalid = $invalidLeases.ToArray(); Present = $true }
    }
    $leaseRootItem = Get-Item -LiteralPath $leaseRoot -Force
    if (($leaseRootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        $invalidLeases.Add($leaseRoot)
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); Invalid = $invalidLeases.ToArray(); Present = $true }
    }

    $now = [DateTime]::UtcNow
    foreach ($item in @(Get-ChildItem -LiteralPath $leaseRoot -Force | Sort-Object Name)) {
        $temporaryNameMatch = [regex]::Match($item.Name, '^\.mcp-([0-9]+)-([0-9a-f]{32})\.json\.([0-9]+)\.[0-9a-fA-F-]{36}\.tmp$')
        if (-not $item.PSIsContainer -and $temporaryNameMatch.Success) {
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
                $item.LastWriteTimeUtc -lt $now.AddMinutes(-5)) {
                $invalidLeases.Add($item.FullName)
            }
            continue
        }

        $nameMatch = [regex]::Match($item.Name, '^mcp-([0-9]+)-([0-9a-f]{32})\.json$')
        if (-not $nameMatch.Success) {
            if ($item.Name.StartsWith("mcp-", [StringComparison]::OrdinalIgnoreCase) -or
                $item.Name.StartsWith(".mcp-", [StringComparison]::OrdinalIgnoreCase)) {
                $invalidLeases.Add($item.FullName)
            }
            continue
        }
        if ($item.PSIsContainer -or ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $invalidLeases.Add($item.FullName)
            continue
        }

        try {
            $lease = Get-Content -LiteralPath $item.FullName -Raw | ConvertFrom-Json
            $processId = [int]$lease.pid
            $leaseId = [string]$lease.lease_id
            $processStartIdentity = [string]$lease.process_start_identity
            $created = [DateTime]::Parse([string]$lease.created_at_utc).ToUniversalTime()
            $heartbeat = [DateTime]::Parse([string]$lease.heartbeat_at_utc).ToUniversalTime()
            $valid = [int]$lease.schema_version -eq 2 -and
                [int]$lease.generation_lease_version -eq 2 -and
                [string]::Equals([string]$lease.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -and
                [string]::Equals([string]$lease.generation_id, $GenerationId, [StringComparison]::Ordinal) -and
                [string]::Equals([string]$lease.owner, "mcp", [StringComparison]::Ordinal) -and
                $processId -eq [int]$nameMatch.Groups[1].Value -and
                [string]::Equals($leaseId, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                $processStartIdentity -match '^[0-9]{1,20}$' -and
                [string]::Equals([System.IO.Path]::GetFullPath([string]$lease.project_root), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
                $created -le $heartbeat -and
                $heartbeat -le $now.AddSeconds(30)
        } catch {
            $valid = $false
        }
        if (-not $valid) {
            $invalidLeases.Add($item.FullName)
            continue
        }

        $processIdentity = Get-WatchProcessIdentity -ProcessId $processId
        $identityMatches = Test-WatchGenerationProcessIdentity -ProcessIdentity $processIdentity -LeaseIdentity $processStartIdentity
        if ($processIdentity.Alive -and ($null -eq $identityMatches -or $identityMatches)) {
            $liveLeases.Add([pscustomobject]@{ ProcessId = $processId; Path = $item.FullName })
        }
    }

    return [pscustomobject]@{ Live = $liveLeases.ToArray(); Invalid = $invalidLeases.ToArray(); Present = $true }
}

function Wait-ForGenerationMcpLeaseDrain {
    param(
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$LeasesRoot,
        [Parameter(Mandatory = $true)][int]$TimeoutMilliseconds
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    $announced = $false
    while ($true) {
        $report = Get-LiveGenerationMcpLeaseReport -GenerationId $GenerationId -ProjectRoot $ProjectRoot -LeasesRoot $LeasesRoot
        if (-not $report.Present) {
            return
        }
        if ($report.Invalid.Count -gt 0) {
            throw "Old-generation MCP request lease is invalid and requires manual review: $($report.Invalid[0])"
        }
        if ($report.Live.Count -eq 0) {
            if ($announced) {
                Write-Host "[DRAINED] Generation $GenerationId MCP requests completed."
            }
            return
        }
        if (-not $announced) {
            $owners = @($report.Live | ForEach-Object { "PID $($_.ProcessId)" }) -join ", "
            Write-Host "[DRAINING] Waiting for generation $GenerationId MCP requests ($owners)."
            $announced = $true
        }
        if ([DateTime]::UtcNow -ge $deadline) {
            throw "Timed out waiting for generation $GenerationId MCP requests to drain; the old coordinator was not stopped."
        }
        Start-Sleep -Milliseconds 50
    }
}

function Get-ActiveEditorSessionIds {
    $sessions = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $editorLeaseRoot -PathType Container)) {
        return $sessions.ToArray()
    }

    $now = [DateTime]::UtcNow
    foreach ($item in @(Get-ChildItem -LiteralPath $editorLeaseRoot -File -Filter "*.json" -ErrorAction SilentlyContinue)) {
        try {
            $lease = Get-Content -LiteralPath $item.FullName -Raw | ConvertFrom-Json
            $sessionId = [string]$lease.session_id
            $processId = [int]$lease.editor_pid
            $processStartTicks = [string]$lease.process_start_ticks
            $created = [DateTime]::Parse([string]$lease.created_at_utc).ToUniversalTime()
            $heartbeat = [DateTime]::Parse([string]$lease.heartbeat_at_utc).ToUniversalTime()
            $valid = [int]$lease.schema_version -eq 1 -and
                [string]::Equals([string]$lease.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -and
                $sessionId -match '^[A-Za-z0-9._-]{1,128}$' -and
                [string]::Equals($sessionId, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                $processId -gt 0 -and
                $processStartTicks -match '^[0-9]+$' -and
                [string]::Equals([System.IO.Path]::GetFullPath([string]$lease.project_root), [System.IO.Path]::GetFullPath($context.UnityRoot), [StringComparison]::OrdinalIgnoreCase) -and
                [string]::Equals([string]$lease.project_identity, $projectIdentity, [StringComparison]::Ordinal) -and
                $created -le $heartbeat -and
                $heartbeat -le $now.AddSeconds(30) -and
                $heartbeat -ge $now.AddSeconds(-90)
            if ($valid) {
                $actualStartTicks = Get-ProcessStartTicks -ProcessId $processId
                $valid = -not [string]::IsNullOrWhiteSpace($actualStartTicks) -and
                    [string]::Equals($actualStartTicks, $processStartTicks, [StringComparison]::Ordinal)
            }
            if ($valid) {
                $sessions.Add($sessionId)
            }
        } catch {
            # The coordinator owns stale or malformed Editor lease reclamation.
        }
    }
    return @($sessions.ToArray() | Sort-Object -Unique)
}

function Read-ManualRuntime {
    if (-not (Test-Path -LiteralPath $manualRuntimePath -PathType Leaf)) {
        return $null
    }
    try {
        $document = Get-Content -LiteralPath $manualRuntimePath -Raw | ConvertFrom-Json
        $sessionIds = @($document.editor_session_ids)
        $valid = [int]$document.schema_version -eq 1 -and
            [string]::Equals([string]$document.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -and
            [string]$document.mode -in @("started", "stopped") -and
            [string]::Equals([System.IO.Path]::GetFullPath([string]$document.project_root), [System.IO.Path]::GetFullPath($context.UnityRoot), [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals([string]$document.project_identity, $projectIdentity, [StringComparison]::Ordinal) -and
            $sessionIds.Count -gt 0
        if ($valid) {
            return $document
        }
    } catch {
        # Invalid manual state fails closed until an explicit command replaces it.
    }
    throw "CodeDB manual runtime state is invalid: $manualRuntimePath"
}

function Get-ApplicableManualMode {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$ActiveSessionIds,
        [switch]$PreserveStale
    )

    $manual = Read-ManualRuntime
    if ($null -eq $manual) {
        return "none"
    }
    $matches = @($manual.editor_session_ids | Where-Object { $ActiveSessionIds -contains [string]$_ })
    if ($matches.Count -gt 0) {
        return [string]$manual.mode
    }
    if (-not $PreserveStale) {
        Remove-Item -LiteralPath $manualRuntimePath -Force
    }
    return "none"
}

function Write-ManualRuntime {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("started", "stopped")][string]$Mode,
        [Parameter(Mandatory = $true)][string[]]$EditorSessionIds
    )

    if ($EditorSessionIds.Count -eq 0) {
        throw "Start now, Stop now, and Restart require an interactive Unity Editor session."
    }
    $document = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        mode = $Mode
        project_root = [System.IO.Path]::GetFullPath($context.UnityRoot).TrimEnd('\', '/')
        project_identity = $projectIdentity
        editor_session_ids = @($EditorSessionIds | Sort-Object -Unique)
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
    } | ConvertTo-Json -Depth 4
    Write-Utf8NoBom -Path $manualRuntimePath -Content ($document + "`n")
}

function Remove-LegacyPreferenceMarkers {
    foreach ($path in @($enabledMarkerPath, $pausedMarkerPath)) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            Remove-Item -LiteralPath $path -Force
        }
    }
}

function Initialize-DesiredState {
    $existing = Read-DesiredState
    if ($null -ne $existing) {
        return [string]$existing.desired_state
    }

    if (Test-Path -LiteralPath $pausedMarkerPath -PathType Leaf) {
        Write-DesiredState -State "disabled" -Reason "legacy-pause-migration"
        Remove-LegacyPreferenceMarkers
        return "disabled"
    }

    if (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf) {
        Write-DesiredState -State "enabled" -Reason "legacy-enabled-migration"
        Remove-LegacyPreferenceMarkers
        return "enabled"
    }

    try {
        $null = Assert-ProjectCodedbProviderFiles -Context $context
        if (-not (Test-Path -LiteralPath $context.TextAdapterManifestPath -PathType Leaf)) {
            return $null
        }
    } catch {
        return $null
    }

    Write-DesiredState -State "enabled" -Reason "valid-setup-default"
    return "enabled"
}

function Get-DesiredStateForStatus {
    $existing = Read-DesiredState
    if ($null -ne $existing) {
        return [string]$existing.desired_state
    }
    if (Test-Path -LiteralPath $pausedMarkerPath -PathType Leaf) {
        return "disabled"
    }
    if (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf) {
        return "enabled"
    }
    return "unknown"
}

function Enter-WatchManagementLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [int]$TimeoutSeconds = 150
    )

    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            return [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        } catch [System.IO.IOException] {
            Start-Sleep -Milliseconds 50
        }
    }
    throw "Timed out waiting for the project-local watch management lock."
}

function Invoke-CoordinatorCli {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("start", "status", "stop")]
        [string]$Command,
        [string]$StartLifecycleId,
        [switch]$RequireNew,
        [switch]$Exclusive,
        [string]$StopExpectedLifecycleId
    )

    $arguments = @(
        $coordinatorScript,
        $Command,
        "--runtime", $coordinatorRuntime,
        "--root", $context.UnityRoot
    )
    if ($Command -eq "start") {
        $arguments += @(
            "--generation-id", $context.GenerationId,
            "--root", $context.UnityRoot,
            "--provider", $providerPaths.ExecutablePath,
            "--config", $watchConfigPath,
            "--adapter-builder", $adapterBuilderPath,
            "--adapter-worker", $adapterWorkerPath,
            "--adapter-manifest", $context.TextAdapterManifestPath,
            "--adapter-debounce-ms", $AdapterDebounceMilliseconds.ToString(),
            "--startup-timeout-ms", "120000"
        )
        if ($StartLifecycleId) {
            $arguments += @("--lifecycle-id", $StartLifecycleId)
        }
        if ($RequireNew) {
            $arguments += @("--require-new", "true")
        }
        if ($Exclusive) {
            $arguments += @("--exclusive-lifecycle", "true")
        }
    } elseif ($Command -eq "stop" -and $StopExpectedLifecycleId) {
        $arguments += @("--expected-lifecycle-id", $StopExpectedLifecycleId)
    }

    $global:LASTEXITCODE = 0
    $output = @(& $nodePath @arguments 2>&1)
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    foreach ($line in $output) {
        Write-Host $line
    }
    if ($exitCode -ne 0) {
        throw "Codedb watch coordinator $Command failed with exit code $exitCode."
    }

    $jsonLine = @($output | ForEach-Object { [string]$_ } | Where-Object { $_.TrimStart().StartsWith("{") } | Select-Object -Last 1)
    if ($jsonLine.Count -ne 1) {
        throw "Codedb watch coordinator $Command returned no structured JSON status."
    }
    return $jsonLine[0] | ConvertFrom-Json
}

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
$providerPaths = Get-ProjectCodedbProviderPaths -Context $context
$nodeCommand = Get-Command node -ErrorAction Stop
$nodePath = $nodeCommand.Source
$coordinatorScript = Join-Path $context.CodedbRoot "coordinator\codedb-watch-coordinator.mjs"
$watchPrepareScript = Join-Path $context.CodedbRoot "scripts\prepare-codedb-project-watch-config.ps1"
$adapterBuilderPath = Join-Path $context.CodedbRoot "scripts\build-codedb-project-text-adapter.ps1"
$adapterWorkerPath = Join-Path $context.CodedbRoot "scripts\run-codedb-project-text-adapter-worker.ps1"
$watchConfigPath = Join-Path $context.ProviderConfigRoot "codedb-mcp.watch.toml"
$watchRoot = Join-Path $context.ProviderRoot "watch"
$coordinatorRuntime = Join-Path $watchRoot "coordinator"
$lifecycleRoot = Join-Path $watchRoot "lifecycle"
$desiredStatePath = Join-Path $lifecycleRoot "desired-state.json"
$manualRuntimePath = Join-Path $lifecycleRoot "manual-runtime.json"
$editorLeaseRoot = Join-Path $lifecycleRoot "editor-leases"
$enabledMarkerPath = Join-Path $watchRoot "auto-start.json"
$pausedMarkerPath = Join-Path $watchRoot "automatic-refresh-paused.json"
$managementLockPath = Join-Path $watchRoot "management.lock"
$refreshIfStaleScript = Join-Path $context.CodedbRoot "scripts\refresh-codedb-project-if-stale.ps1"
$projectIdentity = Get-ProjectIdentity -ProjectRoot $context.UnityRoot
$materializerActiveMarkerPath = Join-Path $context.UnityRoot "AIWork\.runtime\codedb\payload-materializer\materialize-active.json"
$generationLeasesRoot = Join-Path $context.UnityRoot "AIWork\.runtime\codedb\host\leases"
$generationDrainTimeoutMilliseconds = 105000

if ($MaterializerHandoff -and $Action -ne "Ensure") {
    throw "-MaterializerHandoff is valid only with -Action Ensure."
}
if ($TestGenerationDrainTimeoutMilliseconds -ne 0) {
    if ($TestGenerationDrainTimeoutMilliseconds -lt 100 -or $TestGenerationDrainTimeoutMilliseconds -gt $generationDrainTimeoutMilliseconds) {
        throw "-TestGenerationDrainTimeoutMilliseconds must be between 100 and $generationDrainTimeoutMilliseconds."
    }
    if (-not (Test-WatchFixtureRoot -ProjectRoot $context.UnityRoot)) {
        throw "-TestGenerationDrainTimeoutMilliseconds is restricted to an owned materializer POC fixture."
    }
    $generationDrainTimeoutMilliseconds = $TestGenerationDrainTimeoutMilliseconds
}

if ($Action -in @("Ensure", "Enable", "Start", "Restart")) {
    if ($ExpectedLifecycleId) {
        throw "-ExpectedLifecycleId is valid only with -Action Disable, Pause, or Stop."
    }
    if (-not $LifecycleId) {
        $LifecycleId = [Guid]::NewGuid().ToString("N")
    }
} elseif ($LifecycleId -or $RequireNewOwner -or $ExclusiveOwner) {
    throw "-LifecycleId, -RequireNewOwner, and -ExclusiveOwner are valid only with -Action Ensure, Enable, Start, or Restart."
}

foreach ($path in @($coordinatorScript, $watchPrepareScript, $adapterBuilderPath, $adapterWorkerPath, $refreshIfStaleScript)) {
    Assert-CodedbPathInside -Path $path -Root $context.CodedbRoot -Label "watch integration script"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing watch integration file: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $path)"
    }
}
Assert-CodedbPathInside -Path $watchRoot -Root $context.ProviderRoot -Label "watch runtime"
Assert-CodedbPathInside -Path $lifecycleRoot -Root $context.ProviderRoot -Label "watch lifecycle runtime"
Assert-CodedbPathInside -Path $desiredStatePath -Root $context.ProviderRoot -Label "watch desired state"
Assert-CodedbPathInside -Path $manualRuntimePath -Root $context.ProviderRoot -Label "watch manual runtime state"
Assert-CodedbPathInside -Path $editorLeaseRoot -Root $context.ProviderRoot -Label "Editor lease runtime"
Assert-CodedbPathInside -Path $managementLockPath -Root $context.ProviderRoot -Label "watch management lock"
Assert-CodedbPathInside -Path $materializerActiveMarkerPath -Root $context.UnityRoot -Label "materializer active marker"
Assert-CodedbPathInside -Path $generationLeasesRoot -Root $context.UnityRoot -Label "generation lease runtime"
if ($MaterializerHandoff) {
    Assert-MaterializerHandoffMarker -MarkerPath $materializerActiveMarkerPath -ProjectRoot $context.UnityRoot
}

$managementLock = $null
try {
    if ($Action -in @("Ensure", "Enable", "Disable", "Start", "Pause", "Stop", "Restart")) {
        $managementLock = Enter-WatchManagementLock -Path $managementLockPath
    }
    switch ($Action) {
    { $_ -in @("Ensure", "Enable", "Start", "Restart") } {
        $isAutomaticEnsure = $Action -eq "Ensure"
        $isPolicyEnable = $Action -eq "Enable"
        $isImmediateCommand = $Action -in @("Start", "Restart")
        $activeSessionIds = @(Get-ActiveEditorSessionIds)

        if ($isPolicyEnable) {
            Write-DesiredState -State "enabled" -Reason "policy-enable"
            Remove-LegacyPreferenceMarkers
        } elseif ($isImmediateCommand) {
            Write-ManualRuntime -Mode "started" -EditorSessionIds $activeSessionIds
        }

        $desiredState = if ($isAutomaticEnsure) { Initialize-DesiredState } else { Get-DesiredStateForStatus }
        $manualMode = Get-ApplicableManualMode -ActiveSessionIds $activeSessionIds
        if ($null -eq $desiredState) {
            Write-Host "[SKIP] Automatic refresh is waiting for completed Setup."
            Write-Host "[OK] Start with Unity Editor: UNKNOWN"
            Write-Host "[OK] Manual runtime: NONE"
            Write-Host "[OK] Automatic refresh: PENDING"
            $status = Invoke-CoordinatorCli -Command status
            break
        }
        if ($manualMode -eq "stopped") {
            $null = Invoke-CoordinatorCli -Command stop
            Write-Host "[SKIP] CodeDB is stopped for the current Editor session."
            Write-Host "[OK] Start with Unity Editor: $(if ($desiredState -eq 'enabled') { 'ENABLED' } else { 'DISABLED' })"
            Write-Host "[OK] Manual runtime: STOPPED"
            Write-Host "[OK] Automatic refresh: MANUAL_STOPPED"
            break
        }
        if ($desiredState -eq "disabled" -and $manualMode -ne "started") {
            Write-Host "[SKIP] Start with Unity Editor is disabled for this project."
            Write-Host "[OK] Start with Unity Editor: DISABLED"
            Write-Host "[OK] Manual runtime: NONE"
            Write-Host "[OK] Automatic refresh: DISABLED"
            $status = Invoke-CoordinatorCli -Command status
            break
        }

        $existingStatus = Invoke-CoordinatorCli -Command status
        $adapterOperational = [string]$existingStatus.adapter_state -in @("watching", "pending", "building")
        $sameGeneration = [string]::Equals([string]$existingStatus.generation_id, $context.GenerationId, [StringComparison]::Ordinal)
        $generationMismatch = $existingStatus.action -in @("running", "stale") -and -not $sameGeneration
        if ($generationMismatch -and $isAutomaticEnsure -and -not $MaterializerHandoff -and
            (Test-Path -LiteralPath $materializerActiveMarkerPath)) {
            Write-Host "[SKIP] Payload materialization owns the generation handoff; generation $([string]$existingStatus.generation_id) remains active."
            Write-Host "[OK] Automatic refresh: HANDOFF_PENDING"
            Write-Output ($existingStatus | ConvertTo-Json -Depth 8 -Compress)
            break
        }
        $mustRestart = $Action -eq "Restart" -or $generationMismatch
        if ($mustRestart -and $existingStatus.action -in @("running", "stale")) {
            if ($generationMismatch) {
                Wait-ForGenerationMcpLeaseDrain `
                    -GenerationId ([string]$existingStatus.generation_id) `
                    -ProjectRoot $context.UnityRoot `
                    -LeasesRoot $generationLeasesRoot `
                    -TimeoutMilliseconds $generationDrainTimeoutMilliseconds
            }
            Write-Host "[SWITCHING] Stopping generation $([string]$existingStatus.generation_id) before starting $($context.GenerationId)."
            $null = Invoke-CoordinatorCli -Command stop
            $existingStatus = Invoke-CoordinatorCli -Command status
            $adapterOperational = $false
        }
        if ($existingStatus.action -eq "running" -and
            $sameGeneration -and
            $existingStatus.provider_state -eq "ready" -and
            $adapterOperational) {
            Write-Host "[OK] Start with Unity Editor: $(if ($desiredState -eq 'enabled') { 'ENABLED' } else { 'DISABLED' })"
            Write-Host "[OK] Manual runtime: $(if ($manualMode -eq 'started') { 'STARTED' } else { 'NONE' })"
            Write-Host "[OK] Automatic refresh: ACTIVE"
            break
        }

        try {
            if ($isAutomaticEnsure -or $isPolicyEnable) {
                $providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
                $global:LASTEXITCODE = 0
                & $refreshIfStaleScript
                if ($LASTEXITCODE -ne 0) {
                    throw "Freshness repair failed with exit code $LASTEXITCODE."
                }
            }
            $providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
            if (-not (Test-Path -LiteralPath $context.TextAdapterManifestPath -PathType Leaf)) {
                throw "Missing Shader adapter manifest. Build the Shader/HLSL text adapter before starting the watcher."
            }
            $global:LASTEXITCODE = 0
            & $watchPrepareScript -PollIntervalSeconds $PollIntervalSeconds
            if ($LASTEXITCODE -ne 0) {
                throw "Watch config generation failed with exit code $LASTEXITCODE."
            }
            $status = Invoke-CoordinatorCli -Command start -StartLifecycleId $LifecycleId -RequireNew:$RequireNewOwner -Exclusive:$ExclusiveOwner
            if ($status.provider_state -ne "ready" -or $status.adapter_state -ne "watching" -or
                -not [string]::Equals([string]$status.generation_id, $context.GenerationId, [StringComparison]::Ordinal)) {
                throw "Watch coordinator did not reach the selected generation with provider ready / adapter watching state."
            }
            if ($RequireNewOwner -and $status.action -ne "started") {
                throw "Exclusive watch start attached to an existing lifecycle unexpectedly."
            }
            if ($status.action -eq "started" -and
                -not [string]::Equals([string]$status.lifecycle_id, $LifecycleId, [StringComparison]::Ordinal)) {
                throw "Watch coordinator returned a different lifecycle id for a newly started owner."
            }
            if ($ExclusiveOwner -and $status.exclusive_lifecycle -ne $true) {
                throw "Watch coordinator did not preserve exclusive lifecycle ownership."
            }
            Remove-LegacyPreferenceMarkers
            Write-Host "[OK] Start with Unity Editor: $(if ($desiredState -eq 'enabled') { 'ENABLED' } else { 'DISABLED' })"
            Write-Host "[OK] Manual runtime: $(if ($manualMode -eq 'started') { 'STARTED' } else { 'NONE' })"
            Write-Host "[OK] Automatic refresh: ACTIVE"
            Write-Output ($status | ConvertTo-Json -Depth 8 -Compress)
        } catch {
            $startError = $_
            if ($isImmediateCommand -and (Test-Path -LiteralPath $manualRuntimePath -PathType Leaf)) {
                Remove-Item -LiteralPath $manualRuntimePath -Force
            }
            try {
                $cleanupStatus = Invoke-CoordinatorCli -Command status
                if ([string]::Equals([string]$cleanupStatus.lifecycle_id, $LifecycleId, [StringComparison]::Ordinal) -and
                    $cleanupStatus.action -in @("running", "stale")) {
                    $null = Invoke-CoordinatorCli -Command stop -StopExpectedLifecycleId $LifecycleId
                }
            } catch {
                Write-Warning "Watch coordinator cleanup after failed start also failed: $($_.Exception.Message)"
            }
            throw $startError
        }
    }
    "Status" {
        $desiredState = Get-DesiredStateForStatus
        $activeSessionIds = @(Get-ActiveEditorSessionIds)
        $manualMode = Get-ApplicableManualMode -ActiveSessionIds $activeSessionIds -PreserveStale
        $preferenceLabel = switch ($desiredState) {
            "enabled" { "ENABLED" }
            "disabled" { "DISABLED" }
            default { "UNKNOWN" }
        }
        Write-Host "[OK] Watch opt-in: $preferenceLabel"
        Write-Host "[OK] Start with Unity Editor: $preferenceLabel"
        Write-Host "[OK] Manual runtime: $($manualMode.ToUpperInvariant())"
        $status = Invoke-CoordinatorCli -Command status
        $editorDemand = if ([int]$status.editor_session_count -gt 0) { "ONLINE" } else { "OFFLINE" }
        Write-Host "[OK] Editor demand: $editorDemand ($([int]$status.editor_session_count))"
        $adapterOperational = [string]$status.adapter_state -in @("watching", "pending", "building")
        $automaticState = if ($manualMode -eq "stopped") {
            "MANUAL_STOPPED"
        } elseif ($manualMode -eq "started" -and $status.action -eq "running" -and $status.provider_state -eq "ready" -and $adapterOperational) {
            "ACTIVE"
        } elseif ($desiredState -eq "disabled") {
            "DISABLED"
        } elseif ($desiredState -ne "enabled") {
            "PENDING"
        } elseif ($editorDemand -eq "OFFLINE") {
            "EDITOR_OFFLINE"
        } elseif ($status.action -eq "running" -and $status.provider_state -eq "ready" -and $adapterOperational) {
            "ACTIVE"
        } else {
            "STARTING"
        }
        Write-Host "[OK] Automatic refresh: $automaticState"
        if ($desiredState -eq "enabled" -and $editorDemand -eq "ONLINE" -and $automaticState -ne "ACTIVE") {
            Write-Warning "CodeDB is enabled and the Editor is online, but provider/adapter coordination is not ready."
        }
    }
    { $_ -in @("Disable", "Pause", "Stop") } {
        $isPolicyDisable = $Action -in @("Disable", "Pause")
        if ($isPolicyDisable) {
            Write-DesiredState -State "disabled" -Reason "policy-disable"
            Remove-LegacyPreferenceMarkers
            if (Test-Path -LiteralPath $manualRuntimePath -PathType Leaf) {
                Remove-Item -LiteralPath $manualRuntimePath -Force
            }
        } else {
            $activeSessionIds = @(Get-ActiveEditorSessionIds)
            if ($activeSessionIds.Count -eq 0) {
                throw "Start now, Stop now, and Restart require an interactive Unity Editor session."
            }
        }
        if ($ExpectedLifecycleId) {
            $null = Invoke-CoordinatorCli -Command stop -StopExpectedLifecycleId $ExpectedLifecycleId
        } else {
            $null = Invoke-CoordinatorCli -Command stop
        }
        if (-not $isPolicyDisable) {
            Write-ManualRuntime -Mode "stopped" -EditorSessionIds $activeSessionIds
        }
        $desiredState = Get-DesiredStateForStatus
        $preferenceLabel = if ($desiredState -eq "enabled") { "ENABLED" } else { "DISABLED" }
        Write-Host "[OK] Watch opt-in: $preferenceLabel"
        Write-Host "[OK] Start with Unity Editor: $preferenceLabel"
        Write-Host "[OK] Manual runtime: $(if ($isPolicyDisable) { 'NONE' } else { 'STOPPED' })"
        Write-Host "[OK] Automatic refresh: $(if ($isPolicyDisable) { 'DISABLED' } else { 'MANUAL_STOPPED' })"
        Write-Host "[OK] Watch coordinator stop completed."
    }
    }
} finally {
    if ($null -ne $managementLock) {
        $managementLock.Dispose()
    }
}
