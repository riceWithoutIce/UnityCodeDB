#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Ensure", "Start", "Status", "Pause", "Stop")]
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
    [string]$ExpectedLifecycleId
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
$editorLeaseRoot = Join-Path $lifecycleRoot "editor-leases"
$enabledMarkerPath = Join-Path $watchRoot "auto-start.json"
$pausedMarkerPath = Join-Path $watchRoot "automatic-refresh-paused.json"
$managementLockPath = Join-Path $watchRoot "management.lock"
$refreshIfStaleScript = Join-Path $context.CodedbRoot "scripts\refresh-codedb-project-if-stale.ps1"
$projectIdentity = Get-ProjectIdentity -ProjectRoot $context.UnityRoot

if ($Action -in @("Ensure", "Start")) {
    if ($ExpectedLifecycleId) {
        throw "-ExpectedLifecycleId is valid only with -Action Pause or Stop."
    }
    if (-not $LifecycleId) {
        $LifecycleId = [Guid]::NewGuid().ToString("N")
    }
} elseif ($LifecycleId -or $RequireNewOwner -or $ExclusiveOwner) {
    throw "-LifecycleId, -RequireNewOwner, and -ExclusiveOwner are valid only with -Action Ensure or Start."
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
Assert-CodedbPathInside -Path $editorLeaseRoot -Root $context.ProviderRoot -Label "Editor lease runtime"
Assert-CodedbPathInside -Path $managementLockPath -Root $context.ProviderRoot -Label "watch management lock"

$managementLock = $null
try {
    if ($Action -in @("Ensure", "Start", "Pause", "Stop")) {
        $managementLock = Enter-WatchManagementLock -Path $managementLockPath
    }
    switch ($Action) {
    { $_ -in @("Ensure", "Start") } {
        $isAutomaticEnsure = $Action -eq "Ensure"
        if ($isAutomaticEnsure) {
            $desiredState = Initialize-DesiredState
            if ($null -eq $desiredState) {
                Write-Host "[SKIP] Automatic refresh is waiting for completed Setup."
                Write-Host "[OK] Watch opt-in: UNKNOWN"
                Write-Host "[OK] Automatic refresh: PENDING"
                $status = Invoke-CoordinatorCli -Command status
                break
            }
            if ($desiredState -eq "disabled") {
                Write-Host "[SKIP] CodeDB is disabled for this project."
                Write-Host "[OK] Watch opt-in: DISABLED"
                Write-Host "[OK] Automatic refresh: DISABLED"
                $status = Invoke-CoordinatorCli -Command status
                break
            }
        } else {
            Write-DesiredState -State "enabled" -Reason "manual-enable"
            Remove-LegacyPreferenceMarkers
        }

        $existingStatus = Invoke-CoordinatorCli -Command status
        $adapterOperational = [string]$existingStatus.adapter_state -in @("watching", "pending", "building")
        if ($existingStatus.action -eq "running" -and
            $existingStatus.provider_state -eq "ready" -and
            $adapterOperational) {
            Write-Host "[OK] Watch opt-in: ENABLED"
            Write-Host "[OK] Automatic refresh: ACTIVE"
            break
        }

        try {
            if ($isAutomaticEnsure) {
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
            if ($status.provider_state -ne "ready" -or $status.adapter_state -ne "watching") {
                throw "Watch coordinator did not reach provider ready / adapter watching state."
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
            Write-Host "[OK] Watch opt-in: ENABLED"
            Write-Host "[OK] Automatic refresh: ACTIVE"
            Write-Output ($status | ConvertTo-Json -Depth 8 -Compress)
        } catch {
            $startError = $_
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
        $preferenceLabel = switch ($desiredState) {
            "enabled" { "ENABLED" }
            "disabled" { "DISABLED" }
            default { "UNKNOWN" }
        }
        Write-Host "[OK] Watch opt-in: $preferenceLabel"
        $status = Invoke-CoordinatorCli -Command status
        $editorDemand = if ([int]$status.editor_session_count -gt 0) { "ONLINE" } else { "OFFLINE" }
        Write-Host "[OK] Editor demand: $editorDemand ($([int]$status.editor_session_count))"
        $adapterOperational = [string]$status.adapter_state -in @("watching", "pending", "building")
        $automaticState = if ($desiredState -eq "disabled") {
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
    { $_ -in @("Pause", "Stop") } {
        $isPause = $Action -eq "Pause"
        if ($isPause) {
            Write-DesiredState -State "disabled" -Reason "manual-disable"
            Remove-LegacyPreferenceMarkers
        }
        if ($ExpectedLifecycleId) {
            $null = Invoke-CoordinatorCli -Command stop -StopExpectedLifecycleId $ExpectedLifecycleId
        } else {
            $null = Invoke-CoordinatorCli -Command stop
        }
        $desiredState = Get-DesiredStateForStatus
        $preferenceLabel = if ($desiredState -eq "enabled") { "ENABLED" } else { "DISABLED" }
        Write-Host "[OK] Watch opt-in: $preferenceLabel"
        Write-Host "[OK] Automatic refresh: $(if ($desiredState -eq 'enabled') { 'STOPPED' } else { 'DISABLED' })"
        Write-Host "[OK] Watch coordinator stop completed."
    }
    }
} finally {
    if ($null -ne $managementLock) {
        $managementLock.Dispose()
    }
}
