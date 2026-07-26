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
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
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

    $arguments = @($coordinatorScript, $Command, "--runtime", $coordinatorRuntime)
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
$enabledMarkerPath = Join-Path $watchRoot "auto-start.json"
$pausedMarkerPath = Join-Path $watchRoot "automatic-refresh-paused.json"
$managementLockPath = Join-Path $watchRoot "management.lock"
$refreshIfStaleScript = Join-Path $context.CodedbRoot "scripts\refresh-codedb-project-if-stale.ps1"

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
Assert-CodedbPathInside -Path $managementLockPath -Root $context.ProviderRoot -Label "watch management lock"

$managementLock = $null
try {
    if ($Action -in @("Ensure", "Start", "Pause", "Stop")) {
        $managementLock = Enter-WatchManagementLock -Path $managementLockPath
    }
    switch ($Action) {
    { $_ -in @("Ensure", "Start") } {
        $isAutomaticEnsure = $Action -eq "Ensure"
        if ($isAutomaticEnsure -and (Test-Path -LiteralPath $pausedMarkerPath -PathType Leaf)) {
            Write-Host "[SKIP] Automatic refresh is paused for this project."
            Write-Host "[OK] Automatic refresh: PAUSED"
            $status = Invoke-CoordinatorCli -Command status
            break
        }
        if ($isAutomaticEnsure -and (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf)) {
            $existingMarker = Get-Content -LiteralPath $enabledMarkerPath -Raw | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$existingMarker.lifecycle_id)) {
                $LifecycleId = [string]$existingMarker.lifecycle_id
            }
            if ($existingMarker.exclusive_lifecycle -eq $true) {
                $ExclusiveOwner = $true
            }
            $existingDebounceMilliseconds = 0
            if ([int]::TryParse([string]$existingMarker.adapter_debounce_ms, [ref]$existingDebounceMilliseconds) -and
                $existingDebounceMilliseconds -ge 100 -and
                $existingDebounceMilliseconds -le 10000) {
                $AdapterDebounceMilliseconds = $existingDebounceMilliseconds
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
        }
        try {
            if ($isAutomaticEnsure) {
                try {
                    $providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
                    $global:LASTEXITCODE = 0
                    & $refreshIfStaleScript
                    if ($LASTEXITCODE -ne 0) {
                        throw "Freshness repair failed with exit code $LASTEXITCODE."
                    }
                } catch {
                    Write-Host "[SKIP] Automatic refresh is waiting for completed Setup: $($_.Exception.Message)"
                    Write-Host "[OK] Automatic refresh: PENDING"
                    break
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

            $marker = [ordered]@{
                schema_version = 1
                enabled_at_utc = [DateTime]::UtcNow.ToString("o")
                project_root = "."
                watch_config = ConvertTo-CodedbProjectRelativePath -Context $context -Path $watchConfigPath
                coordinator_runtime = ConvertTo-CodedbProjectRelativePath -Context $context -Path $coordinatorRuntime
                adapter_builder = ConvertTo-CodedbProjectRelativePath -Context $context -Path $adapterBuilderPath
                adapter_worker = ConvertTo-CodedbProjectRelativePath -Context $context -Path $adapterWorkerPath
                adapter_manifest = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterManifestPath
                adapter_debounce_ms = $AdapterDebounceMilliseconds
                lifecycle_id = $status.lifecycle_id
                exclusive_lifecycle = $status.exclusive_lifecycle -eq $true
            } | ConvertTo-Json -Depth 6
            Write-Utf8NoBom -Path $enabledMarkerPath -Content $marker
            if (Test-Path -LiteralPath $pausedMarkerPath -PathType Leaf) {
                Remove-Item -LiteralPath $pausedMarkerPath -Force
            }
            Write-Host "[OK] Watch opt-in: ENABLED"
            Write-Host "[OK] Automatic refresh: ACTIVE"
            Write-Host "[OK] Wrapper auto-attach marker: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $enabledMarkerPath)"
            Write-Output ($status | ConvertTo-Json -Depth 8 -Compress)
        } catch {
            $startError = $_
            try {
                $cleanupStatus = Invoke-CoordinatorCli -Command status
                if ([string]::Equals([string]$cleanupStatus.lifecycle_id, $LifecycleId, [StringComparison]::Ordinal)) {
                    if ($cleanupStatus.action -eq "stale") {
                        $null = Invoke-CoordinatorCli -Command start -StartLifecycleId $LifecycleId -RequireNew -Exclusive:($cleanupStatus.exclusive_lifecycle -eq $true)
                    }
                    if ($cleanupStatus.action -in @("running", "stale")) {
                        $null = Invoke-CoordinatorCli -Command stop -StopExpectedLifecycleId $LifecycleId
                    }
                }
            } catch {
                Write-Warning "Watch coordinator cleanup after failed start also failed: $($_.Exception.Message)"
            }
            if (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf) {
                try {
                    $currentMarker = Get-Content -LiteralPath $enabledMarkerPath -Raw | ConvertFrom-Json
                    if ([string]::Equals([string]$currentMarker.lifecycle_id, $LifecycleId, [StringComparison]::Ordinal)) {
                        Remove-Item -LiteralPath $enabledMarkerPath -Force
                    }
                } catch {
                    Write-Warning "Watch marker cleanup after failed start was skipped: $($_.Exception.Message)"
                }
            }
            throw $startError
        }
    }
    "Status" {
        $markerState = if (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf) { "ENABLED" } else { "DISABLED" }
        Write-Host "[OK] Watch opt-in: $markerState"
        $automaticState = if (Test-Path -LiteralPath $pausedMarkerPath -PathType Leaf) {
            "PAUSED"
        } elseif ($markerState -eq "ENABLED") {
            "ACTIVE"
        } else {
            "PENDING"
        }
        Write-Host "[OK] Automatic refresh: $automaticState"
        $status = Invoke-CoordinatorCli -Command status
        $adapterOperational = [string]$status.adapter_state -in @("watching", "pending", "building")
        if ($markerState -eq "ENABLED" -and ($status.action -ne "running" -or $status.provider_state -ne "ready" -or -not $adapterOperational)) {
            Write-Warning "Watch opt-in is enabled but provider/adapter coordination is not ready. The wrapper will attempt recovery on its next startup."
        }
    }
    { $_ -in @("Pause", "Stop") } {
        $isPause = $Action -eq "Pause"
        $effectiveExpectedLifecycleId = $ExpectedLifecycleId
        if (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf) {
            $currentMarker = Get-Content -LiteralPath $enabledMarkerPath -Raw | ConvertFrom-Json
            if ($ExpectedLifecycleId) {
                if (-not [string]::Equals([string]$currentMarker.lifecycle_id, $ExpectedLifecycleId, [StringComparison]::Ordinal)) {
                    throw "Refusing to remove a watch marker owned by another lifecycle."
                }
            } elseif ($currentMarker.exclusive_lifecycle -eq $true) {
                throw "Exclusive watch lifecycle requires -ExpectedLifecycleId for Stop."
            } elseif (-not [string]::IsNullOrWhiteSpace([string]$currentMarker.lifecycle_id)) {
                $effectiveExpectedLifecycleId = [string]$currentMarker.lifecycle_id
            }
        }
        if ($effectiveExpectedLifecycleId) {
            $null = Invoke-CoordinatorCli -Command stop -StopExpectedLifecycleId $effectiveExpectedLifecycleId
            if (Test-Path -LiteralPath $enabledMarkerPath -PathType Leaf) {
                $currentMarker = Get-Content -LiteralPath $enabledMarkerPath -Raw | ConvertFrom-Json
                if ([string]::Equals([string]$currentMarker.lifecycle_id, $effectiveExpectedLifecycleId, [StringComparison]::Ordinal)) {
                    Remove-Item -LiteralPath $enabledMarkerPath -Force
                } else {
                    throw "Watch marker ownership changed after Stop; the replacement marker was preserved."
                }
            }
        } else {
            if (Test-Path -LiteralPath $enabledMarkerPath) {
                Remove-Item -LiteralPath $enabledMarkerPath -Force
            }
            $null = Invoke-CoordinatorCli -Command stop
        }
        if ($isPause) {
            $pauseMarker = [ordered]@{
                schema_version = 1
                paused_at_utc = [DateTime]::UtcNow.ToString("o")
                project_root = "."
            } | ConvertTo-Json -Depth 4
            Write-Utf8NoBom -Path $pausedMarkerPath -Content $pauseMarker
            Write-Host "[OK] Automatic refresh: PAUSED"
        } else {
            if (Test-Path -LiteralPath $pausedMarkerPath -PathType Leaf) {
                Remove-Item -LiteralPath $pausedMarkerPath -Force
            }
            Write-Host "[OK] Automatic refresh: PENDING"
        }
        Write-Host "[OK] Watch opt-in: DISABLED"
        Write-Host "[OK] Watch coordinator stop completed."
    }
    }
} finally {
    if ($null -ne $managementLock) {
        $managementLock.Dispose()
    }
}
