#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("DryRun", "Probe", "Verify", "Upgrade", "Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install")]
    [string]$Action = "DryRun",

    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [AllowEmptyString()]
    [string]$EditorSessionId = "",

    [ValidateRange(0, 2147483647)]
    [int]$EditorProcessId = 0,

    [AllowEmptyString()]
    [string]$EditorProcessStartTicks = "",

    [string]$PayloadRoot,

    [switch]$PocFixture,

    [switch]$ConfirmedProjectMutation,

    [ValidateRange(0, 1000)]
    [int]$TestFailAfterMutation = 0,

    [ValidateRange(0, 1000)]
    [int]$TestCrashAfterMutation = 0,

    [switch]$TestFailWatcherHandoff,

    [switch]$TestCrashBeforeWatcherHandoff,

    [switch]$TestFailRepairMcpRegistration,

    [switch]$TestCrashAfterRemovalMarkerDeletion,

    [ValidatePattern('^RiceAICodeDBRemove[A-Za-z0-9._-]{1,96}$')]
    [string]$TestRemoveLockAcquiredEventName,

    [ValidatePattern('^RiceAICodeDBRemove[A-Za-z0-9._-]{1,96}$')]
    [string]$TestRemoveContinueEventName,

    [ValidatePattern('^RiceAICodeDBRepair[A-Za-z0-9._-]{1,96}$')]
    [string]$TestRepairMarkerPublishedEventName,

    [ValidatePattern('^RiceAICodeDBRepair[A-Za-z0-9._-]{1,96}$')]
    [string]$TestRepairContinueEventName,

    [ValidateRange(0, 2147483647)]
    [int]$TestProcessIdentityUnavailableForPid = 0,

    [ValidatePattern('^RiceAICodeDBUninstall[A-Za-z0-9._-]{1,96}$')]
    [string]$TestUninstallMcpPublishedEventName,

    [ValidatePattern('^RiceAICodeDBUninstall[A-Za-z0-9._-]{1,96}$')]
    [string]$TestUninstallContinueEventName,

    [ValidatePattern('^RiceAICodeDBInstall[A-Za-z0-9._-]{1,96}$')]
    [string]$TestInstallRepairCompletedEventName,

    [ValidatePattern('^RiceAICodeDBInstall[A-Za-z0-9._-]{1,96}$')]
    [string]$TestInstallContinueEventName,

    [ValidatePattern('^RiceAICodeDBCleanup[A-Za-z0-9._-]{1,96}$')]
    [string]$TestAutomaticCleanupStateCapturedEventName,

    [switch]$TestFailInstanceCandidate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ManagedBy = "com.rice.ai-codedb"
$script:MarkerRelativePath = "AIWork/codedb/.rice-ai-codedb-payload.json"
$script:MarkerSchemaVersion = 2
$script:TargetPrefix = "AIWork/codedb/"
$script:GenerationId = ""
$script:BootstrapProtocol = 0
$script:SupportedBootstrapProtocol = 1
$script:GenerationTargetPrefix = ""
$script:CurrentPointerRelativePath = "AIWork/.runtime/codedb/host/current.json"
$script:LastKnownGoodPointerRelativePath = "AIWork/.runtime/codedb/host/last-known-good.json"
$script:GenerationLeaseRelativePath = "AIWork/.runtime/codedb/host/leases"
$script:HostQuarantineRelativePath = "AIWork/.runtime/codedb/host/quarantine"
$script:RuntimeRelativePath = "AIWork/.runtime/codedb/payload-materializer"
$script:McpConfigRelativePath = ".codex/config.toml"
$script:McpConfigBackupDirectoryName = "mcp-config-backups"
$script:McpConfigBackupRelativePath = "$($script:RuntimeRelativePath)/$($script:McpConfigBackupDirectoryName)"
$script:IntegrationStateRelativePath = "$($script:RuntimeRelativePath)/integration-state.json"
$script:IntegrationStateSchemaVersion = 1
$script:McpAvailabilityRelativePath = "$($script:RuntimeRelativePath)/mcp-availability.json"
$script:McpAvailabilitySchemaVersion = 2
$script:McpAvailabilityProbeName = "probe-codedb-mcp-availability.mjs"
$script:ExpectedMcpTools = @(
    "codedb_context",
    "codedb_find",
    "codedb_read",
    "codedb_search",
    "codedb_status",
    "codedb_text_search"
)
$script:LegacyWatcherStopClientName = "stop-codedb-legacy-watcher.mjs"
$script:PocFixtureMarkerName = ".rice-ai-codedb-poc-fixture.json"
$script:HistoricalRuntimeDirectoryName = "authorizations"
$script:HostUseGateVersion = 1
$script:ActiveMarkerName = "materialize-active.json"
$script:UpgradeStateName = "upgrade-state.json"
$script:UpgradeStateRelativePath = "$($script:RuntimeRelativePath)/$($script:UpgradeStateName)"
$script:HostUseLeaseDirectoryName = "host-use-leases"
$script:TransactionPrefix = "txn-v1-"
$script:TransactionJournalName = "transaction.json"
$script:RequestedExitCode = 0
$script:MutationCount = 0
$script:MachinePrerequisiteStatus = $null
$script:CommandResultWritten = $false
$script:CommandPhase = "PREFLIGHT"
$script:CommandOutcome = ""
$script:CommandReasonCode = ""
$script:CommandCleanupState = ""
$script:CommandNextAction = ""
$script:CommandMutatedScopes = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$script:EditorLeaseHandoff = $null
$script:AllowedTargetPaths = @{}
$script:AllowedGenerationRelativePaths = @{}
foreach ($allowedTarget in @(
    "AIWork/codedb/codedb-mcp.runtime.example.toml",
    "AIWork/codedb/codedbignore.example",
    "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs",
    "AIWork/codedb/shared/codedb-machine-provider-contract.ps1",
    "AIWork/codedb/shared/codedb-host-use-gate.mjs",
    "AIWork/codedb/wrapper/codedb-project-wrapper.mjs",
    "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1",
    "AIWork/codedb/scripts/check-codedb-project-freshness.ps1",
    "AIWork/codedb/scripts/clear-codedb-project-index.ps1",
    "AIWork/codedb/scripts/codedb-project-common.ps1",
    "AIWork/codedb/scripts/emit-codedb-mcp-registration-draft.ps1",
    "AIWork/codedb/scripts/manage-codedb-project-watch.ps1",
    "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1",
    "AIWork/codedb/scripts/prepare-codedb-project-watch-config.ps1",
    "AIWork/codedb/scripts/probe-codedb-project-index.ps1",
    "AIWork/codedb/scripts/probe-codedb-project-text-adapter.ps1",
    "AIWork/codedb/scripts/refresh-codedb-project-if-stale.ps1",
    "AIWork/codedb/scripts/refresh-codedb-project.ps1",
    "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1",
    "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1",
    "AIWork/codedb/scripts/validate-codedb-mcp-project-config.ps1",
    "AIWork/codedb/scripts/verify-codedb-project.ps1"
)) {
    $script:AllowedTargetPaths[$allowedTarget] = $true
}
foreach ($generationTarget in @(
    "codedb-mcp.runtime.example.toml",
    "codedbignore.example",
    "coordinator/codedb-watch-coordinator.mjs",
    "generation-manifest.json",
    "scripts/build-codedb-project-text-adapter.ps1",
    "scripts/check-codedb-project-freshness.ps1",
    "scripts/clear-codedb-project-index.ps1",
    "scripts/codedb-project-common.ps1",
    "scripts/emit-codedb-mcp-registration-draft.ps1",
    "scripts/manage-codedb-project-watch.ps1",
    "scripts/prepare-codedb-project-runtime.ps1",
    "scripts/prepare-codedb-project-watch-config.ps1",
    "scripts/probe-codedb-project-index.ps1",
    "scripts/probe-codedb-project-text-adapter.ps1",
    "scripts/refresh-codedb-project-if-stale.ps1",
    "scripts/refresh-codedb-project.ps1",
    "scripts/run-codedb-project-text-adapter-worker.ps1",
    "scripts/show-codedb-project-provider-guidance.ps1",
    "scripts/validate-codedb-mcp-project-config.ps1",
    "scripts/verify-codedb-project.ps1",
    "shared/codedb-machine-provider-contract.ps1",
    "shared/codedb-host-use-gate.mjs",
    "wrapper/codedb-project-instance-worker.mjs"
)) {
    $script:AllowedGenerationRelativePaths[$generationTarget] = $true
    $script:AllowedTargetPaths[$script:GenerationTargetPrefix + $generationTarget] = $true
}
$script:AllowedTargetPaths[$script:CurrentPointerRelativePath] = $true

function Test-MaterializerMutationAction {
    param([Parameter(Mandatory = $true)][string]$Name)

    return $Name -cin @("Upgrade", "Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install")
}

function Set-MaterializerCommandPhase {
    param([Parameter(Mandatory = $true)][ValidatePattern('^[A-Z][A-Z0-9_]{0,63}$')][string]$Phase)

    $script:CommandPhase = $Phase
}

function Add-MaterializerMutationScope {
    param([Parameter(Mandatory = $true)][ValidatePattern('^[a-z][a-z0-9_]{0,63}$')][string]$Scope)

    $null = $script:CommandMutatedScopes.Add($Scope)
    if ([string]::Equals($script:CommandPhase, "PREFLIGHT", [StringComparison]::Ordinal)) {
        $script:CommandPhase = "MUTATION"
    }
}

function Set-MaterializerCommandOutcome {
    param(
        [Parameter(Mandatory = $true)][ValidatePattern('^[A-Z][A-Z0-9_]{0,63}$')][string]$Outcome,
        [Parameter(Mandatory = $true)][ValidatePattern('^[A-Z][A-Z0-9_]{0,63}$')][string]$ReasonCode,
        [Parameter(Mandatory = $true)][ValidateSet("COMPLETE", "PENDING")][string]$CleanupState,
        [Parameter(Mandatory = $true)][string]$NextAction
    )

    $script:CommandOutcome = $Outcome
    $script:CommandReasonCode = $ReasonCode
    $script:CommandCleanupState = $CleanupState
    $script:CommandNextAction = $NextAction
}

function Write-MaterializerCommandResult {
    param(
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [AllowEmptyString()][string]$ErrorDetail = ""
    )

    if ($script:CommandResultWritten -or -not (Test-MaterializerMutationAction -Name $Action)) {
        return
    }

    $succeeded = $ExitCode -eq 0
    $outcome = $script:CommandOutcome
    if ([string]::IsNullOrWhiteSpace($outcome)) {
        if (-not $succeeded) {
            $outcome = "BLOCKED"
        } else {
            $outcome = switch ($Action) {
                "Repair" { "REPAIRED" }
                "Install" { "INSTALLED" }
                "Uninstall" { "UNINSTALLED" }
                "Remove" { "REMOVED" }
                default { "CONVERGED" }
            }
        }
    }

    $reasonCode = $script:CommandReasonCode
    if ([string]::IsNullOrWhiteSpace($reasonCode)) {
        if ($null -ne $script:MachinePrerequisiteStatus -and -not $script:MachinePrerequisiteStatus.Current) {
            $reasonCode = [string]$script:MachinePrerequisiteStatus.ReasonCode
        } elseif ($succeeded) {
            $reasonCode = "ACTION_COMPLETE"
        } else {
            $reasonCode = "MATERIALIZER_EXIT_$ExitCode"
        }
    }

    $cleanupState = $script:CommandCleanupState
    if ([string]::IsNullOrWhiteSpace($cleanupState)) {
        $cleanupState = if ($succeeded -or $script:CommandMutatedScopes.Count -eq 0) { "COMPLETE" } else { "PENDING" }
    }
    $nextAction = $script:CommandNextAction
    if ([string]::IsNullOrWhiteSpace($nextAction)) {
        if (-not $succeeded -and $null -ne $script:MachinePrerequisiteStatus -and -not $script:MachinePrerequisiteStatus.Current) {
            $nextAction = [string]$script:MachinePrerequisiteStatus.NextAction
        } elseif ($succeeded) {
            $nextAction = "No action required."
        } else {
            $nextAction = "Review the reported CodeDB diagnostic, then retry the same confirmed action once."
        }
    }

    $phase = $script:CommandPhase
    if ([string]::IsNullOrWhiteSpace($phase)) { $phase = "PREFLIGHT" }
    $result = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        action = $Action.ToUpperInvariant()
        outcome = $outcome
        phase = $phase
        reason_code = $reasonCode
        mutated_scopes = @($script:CommandMutatedScopes | Sort-Object)
        cleanup_state = $cleanupState
        next_action = $nextAction
        exit_code = $ExitCode
        detail = $ErrorDetail
    }
    Write-Host "[COMMAND_RESULT] $($result | ConvertTo-Json -Compress -Depth 5)"
    $script:CommandResultWritten = $true
}

function Throw-MaterializerError {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )

    $script:RequestedExitCode = $ExitCode
    $exception = [System.InvalidOperationException]::new($Message)
    $exception.Data["MaterializerExitCode"] = $ExitCode
    throw $exception
}

function ConvertTo-NativeProcessArgument {
    param([AllowEmptyString()][string]$Value)

    if ($null -eq $Value -or $Value.Length -eq 0) {
        return '""'
    }
    if ($Value -notmatch '[\s"]') {
        return $Value
    }

    $builder = [System.Text.StringBuilder]::new()
    $null = $builder.Append([char]'"')
    $backslashCount = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]'\') {
            $backslashCount += 1
            continue
        }
        if ($character -eq [char]'"') {
            if ($backslashCount -gt 0) {
                $null = $builder.Append([char]'\', ($backslashCount * 2))
            }
            $null = $builder.Append([char]'\')
            $null = $builder.Append([char]'"')
        } else {
            if ($backslashCount -gt 0) {
                $null = $builder.Append([char]'\', $backslashCount)
            }
            $null = $builder.Append($character)
        }
        $backslashCount = 0
    }
    if ($backslashCount -gt 0) {
        $null = $builder.Append([char]'\', ($backslashCount * 2))
    }
    $null = $builder.Append([char]'"')
    return $builder.ToString()
}

function Invoke-BoundedNativeProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [ValidateRange(1, 600000)][int]$TimeoutMilliseconds = 35000,
        [AllowNull()][hashtable]$Environment,
        [AllowNull()][scriptblock]$WhileRunning
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = (@($Arguments | ForEach-Object { ConvertTo-NativeProcessArgument -Value $_ }) -join ' ')
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if ($null -ne $Environment) {
        foreach ($name in $Environment.Keys) {
            $startInfo.EnvironmentVariables[[string]$name] = [string]$Environment[$name]
        }
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
        $nextHeartbeat = [DateTime]::UtcNow
        while (-not ($process.HasExited -and $stdoutTask.IsCompleted -and $stderrTask.IsCompleted)) {
            $remaining = [int][Math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalMilliseconds)
            if ($remaining -le 0) {
                if (-not $process.HasExited) {
                    $process.Kill()
                    $process.WaitForExit()
                }
                return [pscustomobject]@{ ExitCode = -1; StandardOutput = ''; StandardError = 'Package-owned native client timed out.'; TimedOut = $true }
            }
            if ($null -ne $WhileRunning -and [DateTime]::UtcNow -ge $nextHeartbeat) {
                & $WhileRunning
                $nextHeartbeat = [DateTime]::UtcNow.AddSeconds(5)
            }
            if (-not $process.HasExited) {
                $null = $process.WaitForExit([Math]::Min(250, $remaining))
            } else {
                Start-Sleep -Milliseconds ([Math]::Min(250, $remaining))
            }
        }
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = $stdoutTask.Result
            StandardError = $stderrTask.Result
            TimedOut = $false
        }
    } finally {
        if ($null -ne $WhileRunning) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill()
                    $process.WaitForExit()
                }
            } catch {
                # The child may have exited between the check and cleanup.
            }
        }
        $process.Dispose()
    }
}

function Invoke-BoundedNativeProcessWithFileOutput {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$OutputRoot,
        [ValidateRange(1, 600000)][int]$TimeoutMilliseconds = 35000,
        [AllowNull()][hashtable]$Environment,
        [AllowNull()][scriptblock]$WhileRunning
    )

    Assert-NoReparsePoint -Path $OutputRoot -Root $OutputRoot -Label "native process output root"
    $token = [Guid]::NewGuid().ToString("N")
    $stdoutPath = Join-Path $OutputRoot "native-$token.stdout.log"
    $stderrPath = Join-Path $OutputRoot "native-$token.stderr.log"
    foreach ($path in @($stdoutPath, $stderrPath)) {
        Assert-PathInside -Path $path -Root $OutputRoot -Label "native process output"
        if (Test-Path -LiteralPath $path) {
            throw "Native process output path collided with an existing file."
        }
    }

    $argumentText = (@($Arguments | ForEach-Object { ConvertTo-NativeProcessArgument -Value $_ }) -join ' ')
    $savedEnvironment = @{}
    $process = $null
    try {
        if ($null -ne $Environment) {
            foreach ($name in $Environment.Keys) {
                $environmentName = [string]$name
                $savedEnvironment[$environmentName] = [Environment]::GetEnvironmentVariable(
                    $environmentName,
                    [EnvironmentVariableTarget]::Process)
                [Environment]::SetEnvironmentVariable(
                    $environmentName,
                    [string]$Environment[$name],
                    [EnvironmentVariableTarget]::Process)
            }
        }
        try {
            $process = Start-Process `
                -FilePath $FilePath `
                -ArgumentList $argumentText `
                -WindowStyle Hidden `
                -RedirectStandardOutput $stdoutPath `
                -RedirectStandardError $stderrPath `
                -PassThru
            # Windows PowerShell 5.1 can release a short-lived Start-Process
            # handle before ExitCode is read unless the handle is opened here.
            $null = $process.Handle
        } finally {
            foreach ($name in $savedEnvironment.Keys) {
                [Environment]::SetEnvironmentVariable(
                    [string]$name,
                    $savedEnvironment[$name],
                    [EnvironmentVariableTarget]::Process)
            }
        }

        $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
        $nextHeartbeat = [DateTime]::UtcNow
        while (-not $process.HasExited) {
            $remaining = [int][Math]::Ceiling(($deadline - [DateTime]::UtcNow).TotalMilliseconds)
            if ($remaining -le 0) {
                $process.Kill()
                $process.WaitForExit()
                return [pscustomobject]@{
                    ExitCode = -1
                    StandardOutput = ''
                    StandardError = 'Package-owned native client timed out.'
                    TimedOut = $true
                }
            }
            if ($null -ne $WhileRunning -and [DateTime]::UtcNow -ge $nextHeartbeat) {
                & $WhileRunning
                $nextHeartbeat = [DateTime]::UtcNow.AddSeconds(5)
            }
            $null = $process.WaitForExit([Math]::Min(250, $remaining))
        }
        $process.WaitForExit()
        $process.Refresh()

        $maximumOutputBytes = 4 * 1024 * 1024
        $readOutput = {
            param([Parameter(Mandatory = $true)][string]$Path)

            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
            Assert-NoReparsePoint -Path $Path -Root $OutputRoot -Label "native process output"
            $file = Get-Item -LiteralPath $Path -Force
            if ($file.Length -gt $maximumOutputBytes) {
                return '[Package-owned native client output exceeded the diagnostic limit.]'
            }
            try {
                return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::Default)
            } catch [System.IO.IOException] {
                return '[Package-owned native client output remained locked after the direct process exited.]'
            }
        }.GetNewClosure()
        return [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = & $readOutput -Path $stdoutPath
            StandardError = & $readOutput -Path $stderrPath
            TimedOut = $false
        }
    } finally {
        if ($null -ne $process) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill()
                    $process.WaitForExit()
                }
            } catch {
                # The direct child may have exited between the check and cleanup.
            }
            $process.Dispose()
        }
        foreach ($path in @($stdoutPath, $stderrPath)) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                try { Remove-Item -LiteralPath $path -Force } catch { }
            }
        }
    }
}

function Invoke-TestFaultAfterMutation {
    if ($TestFailAfterMutation -le 0 -and $TestCrashAfterMutation -le 0) {
        return
    }

    $script:MutationCount++
    if ($script:MutationCount -eq $TestCrashAfterMutation) {
        [Console]::Error.WriteLine("Injected POC process crash after mutation $($script:MutationCount).")
        [Console]::Error.Flush()
        [Environment]::Exit(86)
    }
    if ($script:MutationCount -eq $TestFailAfterMutation) {
        throw "Injected POC failure after mutation $($script:MutationCount)."
    }
}

function Invoke-TestCrashAfterRemovalMarkerDeletion {
    param([Parameter(Mandatory = $true)][string]$Target)

    if (-not $TestCrashAfterRemovalMarkerDeletion -or
        -not [string]::Equals($Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
        return
    }

    [Console]::Error.WriteLine("Injected POC process crash after Remove deleted the ownership marker.")
    [Console]::Error.Flush()
    [Environment]::Exit(87)
}

function Invoke-TestRemoveAfterLockHandshake {
    if ([string]::IsNullOrWhiteSpace($TestRemoveLockAcquiredEventName)) {
        return
    }

    $readyEvent = $null
    $continueEvent = $null
    try {
        $readyEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestRemoveLockAcquiredEventName)
        $continueEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestRemoveContinueEventName)
        if (-not $readyEvent.Set()) {
            throw "Remove lock-acquired fixture event could not be signaled."
        }
        if (-not $continueEvent.WaitOne(10000)) {
            throw "Remove lock-acquired fixture timed out waiting for continuation."
        }
    } finally {
        if ($null -ne $continueEvent) { $continueEvent.Dispose() }
        if ($null -ne $readyEvent) { $readyEvent.Dispose() }
    }
}

function Invoke-TestRepairAfterMarkerHandshake {
    if ([string]::IsNullOrWhiteSpace($TestRepairMarkerPublishedEventName)) {
        return
    }

    $readyEvent = $null
    $continueEvent = $null
    try {
        $readyEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestRepairMarkerPublishedEventName)
        $continueEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestRepairContinueEventName)
        if (-not $readyEvent.Set()) {
            throw "Repair marker-published fixture event could not be signaled."
        }
        if (-not $continueEvent.WaitOne(10000)) {
            throw "Repair marker-published fixture timed out waiting for continuation."
        }
    } finally {
        if ($null -ne $continueEvent) { $continueEvent.Dispose() }
        if ($null -ne $readyEvent) { $readyEvent.Dispose() }
    }
}

function Invoke-TestUninstallAfterMcpHandshake {
    if ([string]::IsNullOrWhiteSpace($TestUninstallMcpPublishedEventName)) {
        return
    }

    $readyEvent = $null
    $continueEvent = $null
    try {
        $readyEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestUninstallMcpPublishedEventName)
        $continueEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestUninstallContinueEventName)
        if (-not $readyEvent.Set()) {
            throw "Uninstall MCP-published fixture event could not be signaled."
        }
        if (-not $continueEvent.WaitOne(30000)) {
            throw "Uninstall MCP-published fixture timed out waiting for continuation."
        }
    } finally {
        if ($null -ne $continueEvent) { $continueEvent.Dispose() }
        if ($null -ne $readyEvent) { $readyEvent.Dispose() }
    }
}

function Invoke-TestInstallAfterRepairHandshake {
    if ([string]::IsNullOrWhiteSpace($TestInstallRepairCompletedEventName)) {
        return
    }

    $readyEvent = $null
    $continueEvent = $null
    try {
        $readyEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestInstallRepairCompletedEventName)
        $continueEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestInstallContinueEventName)
        if (-not $readyEvent.Set()) {
            throw "Install Repair-completed fixture event could not be signaled."
        }
        if (-not $continueEvent.WaitOne(30000)) {
            throw "Install Repair-completed fixture timed out waiting for continuation."
        }
    } finally {
        if ($null -ne $continueEvent) { $continueEvent.Dispose() }
        if ($null -ne $readyEvent) { $readyEvent.Dispose() }
    }
}

function Invoke-TestAutomaticCleanupStateCapturedSignal {
    if ([string]::IsNullOrWhiteSpace($TestAutomaticCleanupStateCapturedEventName)) {
        return
    }

    $readyEvent = $null
    try {
        $readyEvent = [System.Threading.EventWaitHandle]::OpenExisting($TestAutomaticCleanupStateCapturedEventName)
        if (-not $readyEvent.Set()) {
            throw "Automatic cleanup state-captured fixture event could not be signaled."
        }
    } finally {
        if ($null -ne $readyEvent) { $readyEvent.Dispose() }
    }
}

function ConvertTo-SafeRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or
        [System.IO.Path]::IsPathRooted($Path) -or
        $Path.StartsWith("\\", [StringComparison]::Ordinal) -or
        $Path.IndexOf(':') -ge 0 -or
        $Path.IndexOfAny([char[]]'*?') -ge 0) {
        Throw-MaterializerError -Message "$Label must be a non-rooted, literal relative path: $Path" -ExitCode 2
    }

    $segments = @($Path.Replace('\', '/').Split('/'))
    if ($segments.Count -eq 0) {
        Throw-MaterializerError -Message "$Label is empty." -ExitCode 2
    }

    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or
            $segment -eq "." -or
            $segment -eq ".." -or
            $segment.EndsWith(".", [StringComparison]::Ordinal) -or
            $segment.EndsWith(" ", [StringComparison]::Ordinal) -or
            $segment -match '^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?$') {
            Throw-MaterializerError -Message "$Label contains an unsafe path segment: $Path" -ExitCode 2
        }

        if ($segment.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Throw-MaterializerError -Message "$Label contains invalid path characters: $Path" -ExitCode 2
        }
    }

    return $segments -join '/'
}

function Assert-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowRoot
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    $isRoot = [string]::Equals($fullPath, $fullRoot, [StringComparison]::OrdinalIgnoreCase)
    $isInside = $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    if (-not $isInside -and -not ($AllowRoot -and $isRoot)) {
        Throw-MaterializerError -Message "$Label escapes its allowed root. Path: $fullPath Root: $fullRoot" -ExitCode 2
    }
}

function Assert-NoReparsePoint {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    Assert-PathInside -Path $fullPath -Root $fullRoot -Label $Label -AllowRoot

    $current = $fullPath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                Throw-MaterializerError -Message "$Label traverses a reparse point: $current" -ExitCode 2
            }
        }

        if ([string]::Equals($current, $fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }

        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or
            -not $parent.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "$Label could not be validated inside $fullRoot." -ExitCode 2
        }
        $current = $parent
    }
}

function ConvertTo-AbsoluteChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $platformPath = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $Root $platformPath))
    Assert-PathInside -Path $absolutePath -Root $Root -Label $Label
    return $absolutePath
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = $null
    $sha256 = $null
    try {
        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::Read)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        return (($sha256.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
        if ($null -ne $sha256) { $sha256.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Get-TextSha256 {
    param([Parameter(Mandatory = $true)][string]$Text)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return (($sha256.ComputeHash($bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
        $sha256.Dispose()
    }
}

function Get-PayloadContentIdentitySha256 {
    param([Parameter(Mandatory = $true)]$Manifest)

    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("managed_by=$($Manifest.ManagedBy)")
    $lines.Add("payload_version=$($Manifest.PayloadVersion)")
    $lines.Add("payload_sequence=$($Manifest.PayloadSequence)")
    $lines.Add("generation_id=$($Manifest.GenerationId)")
    $lines.Add("bootstrap_protocol=$($Manifest.BootstrapProtocol)")
    foreach ($target in @($Manifest.RetiredTargets | Sort-Object)) {
        $lines.Add("retired=$target")
    }
    foreach ($transition in @($Manifest.BootstrapTransitions | Sort-Object SourcePayloadSequence, SourcePackageVersion)) {
        $lines.Add(
            "bootstrap_transition=$($transition.SourceMarkerSchemaVersion):$($transition.SourcePackageVersion):$($transition.SourcePayloadVersion):$($transition.SourcePayloadSequence):$($transition.SourceGenerationId):$($transition.SourceBootstrapProtocol):$($transition.SourceHostUseGateVersion):$($transition.SourceGenerationLeaseVersion):$($transition.SourceFlatFileCount):$($transition.SourceFlatClosureSha256):$($transition.SourceStableWrapperSha256)")
    }
    foreach ($file in @($Manifest.Files | Sort-Object Target)) {
        if ([string]::Equals($file.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($file.Target, $generationManifestTarget, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $lines.Add("file=$($file.Target):$($file.Sha256)")
    }
    return Get-TextSha256 -Text (($lines -join "`n") + "`n")
}

function Skip-StrictJsonWhitespace {
    param([Parameter(Mandatory = $true)]$State)

    while ($State.Index -lt $State.Text.Length -and
        $State.Text[$State.Index] -cin @(' ', "`t", "`r", "`n")) {
        $State.Index++
    }
}

function Read-StrictJsonStringToken {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -cne '"') {
        throw "$Label expected a JSON string at character $($State.Index)."
    }
    $State.Index++
    $builder = [System.Text.StringBuilder]::new()
    while ($State.Index -lt $State.Text.Length) {
        $character = $State.Text[$State.Index]
        $State.Index++
        if ($character -ceq '"') {
            return $builder.ToString()
        }
        if ([int]$character -lt 0x20) {
            throw "$Label contains an unescaped JSON control character."
        }
        if ($character -cne '\') {
            $null = $builder.Append($character)
            continue
        }
        if ($State.Index -ge $State.Text.Length) {
            throw "$Label contains an incomplete JSON escape."
        }
        $escape = $State.Text[$State.Index]
        $State.Index++
        switch -CaseSensitive ($escape) {
            '"' { $null = $builder.Append('"'); continue }
            '\' { $null = $builder.Append('\'); continue }
            '/' { $null = $builder.Append('/'); continue }
            'b' { $null = $builder.Append("`b"); continue }
            'f' { $null = $builder.Append("`f"); continue }
            'n' { $null = $builder.Append("`n"); continue }
            'r' { $null = $builder.Append("`r"); continue }
            't' { $null = $builder.Append("`t"); continue }
            'u' {
                if ($State.Index + 4 -gt $State.Text.Length) {
                    throw "$Label contains an incomplete JSON Unicode escape."
                }
                $hex = $State.Text.Substring($State.Index, 4)
                if ($hex -cnotmatch '^[0-9A-Fa-f]{4}$') {
                    throw "$Label contains an invalid JSON Unicode escape."
                }
                $State.Index += 4
                $codeUnit = [Convert]::ToInt32($hex, 16)
                if ($codeUnit -ge 0xD800 -and $codeUnit -le 0xDBFF) {
                    if ($State.Index + 6 -gt $State.Text.Length -or
                        $State.Text[$State.Index] -cne '\' -or
                        $State.Text[$State.Index + 1] -cne 'u') {
                        throw "$Label contains an unpaired high-surrogate JSON escape."
                    }
                    $lowHex = $State.Text.Substring($State.Index + 2, 4)
                    if ($lowHex -cnotmatch '^[0-9A-Fa-f]{4}$') {
                        throw "$Label contains an invalid low-surrogate JSON escape."
                    }
                    $lowCodeUnit = [Convert]::ToInt32($lowHex, 16)
                    if ($lowCodeUnit -lt 0xDC00 -or $lowCodeUnit -gt 0xDFFF) {
                        throw "$Label contains an unpaired high-surrogate JSON escape."
                    }
                    $State.Index += 6
                    $codePoint = 0x10000 + (($codeUnit - 0xD800) * 0x400) + ($lowCodeUnit - 0xDC00)
                    $null = $builder.Append([char]::ConvertFromUtf32($codePoint))
                    continue
                }
                if ($codeUnit -ge 0xDC00 -and $codeUnit -le 0xDFFF) {
                    throw "$Label contains an unpaired low-surrogate JSON escape."
                }
                $null = $builder.Append([char]$codeUnit)
                continue
            }
            default { throw "$Label contains an unsupported JSON escape."
            }
        }
    }
    throw "$Label contains an unclosed JSON string."
}

function Read-StrictJsonValueToken {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Skip-StrictJsonWhitespace -State $State
    if ($State.Index -ge $State.Text.Length) {
        throw "$Label contains an incomplete JSON value."
    }
    $State.Depth++
    if ($State.Depth -gt 64) {
        throw "$Label exceeds the accepted JSON nesting depth."
    }
    try {
        $character = $State.Text[$State.Index]
        if ($character -ceq '"') {
            return [pscustomobject]@{ Value = (Read-StrictJsonStringToken -State $State -Label $Label) }
        }
        if ($character -ceq '{') {
            $State.Index++
            $properties = [ordered]@{}
            $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            Skip-StrictJsonWhitespace -State $State
            if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -ceq '}') {
                $State.Index++
                return [pscustomobject]@{ Value = [pscustomobject]$properties }
            }
            while ($true) {
                $name = Read-StrictJsonStringToken -State $State -Label $Label
                if (-not $seen.Add($name)) {
                    throw "$Label contains a duplicate or case-ambiguous JSON property: $name"
                }
                Skip-StrictJsonWhitespace -State $State
                if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -cne ':') {
                    throw "$Label expected : after JSON property $name."
                }
                $State.Index++
                $valueToken = Read-StrictJsonValueToken -State $State -Label $Label
                $properties[$name] = $valueToken.Value
                Skip-StrictJsonWhitespace -State $State
                if ($State.Index -ge $State.Text.Length) {
                    throw "$Label contains an unclosed JSON object."
                }
                if ($State.Text[$State.Index] -ceq '}') {
                    $State.Index++
                    return [pscustomobject]@{ Value = [pscustomobject]$properties }
                }
                if ($State.Text[$State.Index] -cne ',') {
                    throw "$Label expected , between JSON object properties."
                }
                $State.Index++
                Skip-StrictJsonWhitespace -State $State
            }
        }
        if ($character -ceq '[') {
            $State.Index++
            $items = New-Object System.Collections.Generic.List[object]
            Skip-StrictJsonWhitespace -State $State
            if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -ceq ']') {
                $State.Index++
                return [pscustomobject]@{ Value = [object[]]@() }
            }
            while ($true) {
                $valueToken = Read-StrictJsonValueToken -State $State -Label $Label
                $items.Add($valueToken.Value)
                Skip-StrictJsonWhitespace -State $State
                if ($State.Index -ge $State.Text.Length) {
                    throw "$Label contains an unclosed JSON array."
                }
                if ($State.Text[$State.Index] -ceq ']') {
                    $State.Index++
                    return [pscustomobject]@{ Value = [object[]]$items.ToArray() }
                }
                if ($State.Text[$State.Index] -cne ',') {
                    throw "$Label expected , between JSON array values."
                }
                $State.Index++
                Skip-StrictJsonWhitespace -State $State
            }
        }
        foreach ($literal in @(
            [pscustomobject]@{ Text = 'true'; Value = $true },
            [pscustomobject]@{ Text = 'false'; Value = $false },
            [pscustomobject]@{ Text = 'null'; Value = $null }
        )) {
            if ($State.Index + $literal.Text.Length -le $State.Text.Length -and
                [string]::Equals($State.Text.Substring($State.Index, $literal.Text.Length), $literal.Text, [StringComparison]::Ordinal)) {
                $State.Index += $literal.Text.Length
                return [pscustomobject]@{ Value = $literal.Value }
            }
        }

        $remaining = $State.Text.Substring($State.Index)
        $numberMatch = [regex]::Match($remaining, '^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?', [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
        if (-not $numberMatch.Success) {
            throw "$Label contains an unsupported JSON token at character $($State.Index)."
        }
        $numberText = $numberMatch.Value
        $State.Index += $numberText.Length
        if ($numberText.IndexOfAny([char[]]@('.', 'e', 'E')) -lt 0) {
            [int64]$integer = 0
            if (-not [int64]::TryParse($numberText, [Globalization.NumberStyles]::AllowLeadingSign, [Globalization.CultureInfo]::InvariantCulture, [ref]$integer)) {
                throw "$Label contains a JSON integer outside the signed 64-bit range."
            }
            return [pscustomobject]@{ Value = $integer }
        }
        [double]$number = 0
        if (-not [double]::TryParse($numberText, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -or
            [double]::IsNaN($number) -or [double]::IsInfinity($number)) {
            throw "$Label contains a non-finite or out-of-range JSON number."
        }
        return [pscustomobject]@{ Value = $number }
    } finally {
        $State.Depth--
    }
}

function ConvertFrom-StrictJsonText {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $state = [pscustomobject]@{ Text = $Text; Index = 0; Depth = 0 }
    $token = Read-StrictJsonValueToken -State $state -Label $Label
    Skip-StrictJsonWhitespace -State $state
    if ($state.Index -ne $state.Text.Length) {
        throw "$Label contains trailing JSON content at character $($state.Index)."
    }
    Write-Output -NoEnumerate $token.Value
}

function Get-RequiredJsonPropertyValue {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Object.GetType() -ne [System.Management.Automation.PSCustomObject]) {
        throw "$Label must be a JSON object."
    }
    $property = @($Object.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, $Name, [StringComparison]::Ordinal)
    })
    if ($property.Count -ne 1) {
        throw "$Label is missing required property: $Name"
    }
    # PowerShell enumerates arrays crossing a function boundary unless explicitly
    # suppressed. Preserve JSON [] and single-element arrays as arrays so exact
    # token-type validation cannot confuse them with null or a scalar.
    Write-Output -NoEnumerate $property[0].Value
}

function Get-ExactJsonProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Object.GetType() -ne [System.Management.Automation.PSCustomObject]) {
        throw "$Label must be a JSON object."
    }
    $properties = @($Object.PSObject.Properties | Where-Object {
        [string]::Equals($_.Name, $Name, [StringComparison]::Ordinal)
    })
    if ($properties.Count -gt 1) {
        throw "$Label contains duplicate property: $Name"
    }
    if ($properties.Count -eq 0) { return $null }
    return $properties[0]
}

function Get-RequiredJsonString {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($value -isnot [string]) { throw "$Label property $Name must be a JSON string." }
    return [string]$value
}

function Get-RequiredJsonInt32 {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($value -isnot [int64] -or $value -lt [int]::MinValue -or $value -gt [int]::MaxValue) {
        throw "$Label property $Name must be a signed 32-bit JSON integer."
    }
    return [int]$value
}

function Get-RequiredJsonInt64 {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($value -isnot [int64]) { throw "$Label property $Name must be a signed 64-bit JSON integer." }
    return [int64]$value
}

function Get-RequiredJsonBoolean {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($value -isnot [bool]) { throw "$Label property $Name must be a JSON boolean." }
    return [bool]$value
}

function Get-RequiredJsonArray {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($value -isnot [object[]]) { throw "$Label property $Name must be a JSON array." }
    Write-Output -NoEnumerate ([object[]]$value)
}

function Get-RequiredJsonNullableString {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($null -ne $value -and $value -isnot [string]) {
        throw "$Label property $Name must be a JSON string or null."
    }
    return $value
}

function Get-RequiredJsonNullableInt32 {
    param($Object, [string]$Name, [string]$Label)
    $value = Get-RequiredJsonPropertyValue -Object $Object -Name $Name -Label $Label
    if ($null -eq $value) { return $null }
    if ($value -isnot [int64] -or $value -lt [int]::MinValue -or $value -gt [int]::MaxValue) {
        throw "$Label property $Name must be a signed 32-bit JSON integer or null."
    }
    return [int]$value
}

function Get-OptionalJsonNullableString {
    param($Object, [string]$Name, [string]$Label)
    $property = Get-ExactJsonProperty -Object $Object -Name $Name -Label $Label
    if ($null -eq $property -or $null -eq $property.Value) { return $null }
    if ($property.Value -isnot [string]) {
        throw "$Label property $Name must be a JSON string or null."
    }
    return [string]$property.Value
}

function Get-OptionalJsonNullableInt32 {
    param($Object, [string]$Name, [string]$Label)
    $property = Get-ExactJsonProperty -Object $Object -Name $Name -Label $Label
    if ($null -eq $property -or $null -eq $property.Value) { return $null }
    if ($property.Value -isnot [int64] -or
        $property.Value -lt [int]::MinValue -or $property.Value -gt [int]::MaxValue) {
        throw "$Label property $Name must be a signed 32-bit JSON integer or null."
    }
    return [int]$property.Value
}

function Get-OptionalJsonBoolean {
    param($Object, [string]$Name, [string]$Label, [bool]$DefaultValue = $false)
    $property = Get-ExactJsonProperty -Object $Object -Name $Name -Label $Label
    if ($null -eq $property) { return $DefaultValue }
    if ($property.Value -isnot [bool]) {
        throw "$Label property $Name must be a JSON boolean."
    }
    return [bool]$property.Value
}

function Assert-JsonObject {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if ($null -eq $Value -or $Value.GetType() -ne [System.Management.Automation.PSCustomObject]) {
        throw "$Label must be a JSON object."
    }
    return $Value
}

function Read-BoundedJsonDocument {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][int64]$MaximumBytes
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Throw-MaterializerError -Message "$Label does not exist: $Path" -ExitCode 2
    }
    try {
        $file = Get-Item -LiteralPath $Path -Force
        if ($file.Length -le 0 -or $file.Length -gt $MaximumBytes) {
            throw "$Label size is outside the accepted range: $Path"
        }
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -le 0 -or $bytes.Length -gt $MaximumBytes) {
            throw "$Label size changed outside the accepted range while it was read: $Path"
        }
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            throw "$Label must be UTF-8 without a byte-order mark."
        }
        $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $text = $strictUtf8.GetString($bytes)
        $document = ConvertFrom-StrictJsonText -Text $text -Label $Label
    } catch {
        Throw-MaterializerError -Message "$Label is not valid JSON: $($_.Exception.Message)" -ExitCode 2
    }
    if ($null -eq $document -or $document.GetType() -ne [System.Management.Automation.PSCustomObject]) {
        Throw-MaterializerError -Message "$Label must contain one JSON object." -ExitCode 2
    }
    return [pscustomobject]@{ Text = $text; Document = $document }
}

function Assert-UnityProjectRoot {
    param([Parameter(Mandatory = $true)][string]$Root)

    foreach ($relativePath in @("Assets", "Packages/manifest.json", "ProjectSettings/ProjectVersion.txt")) {
        $markerPath = ConvertTo-AbsoluteChildPath -Root $Root -RelativePath $relativePath -Label "Unity project marker"
        if (-not (Test-Path -LiteralPath $markerPath)) {
            Throw-MaterializerError -Message "Unity project marker is missing: $markerPath" -ExitCode 2
        }
    }
}

function Assert-PocMutationTarget {
    param([Parameter(Mandatory = $true)][string]$Root)

    if (-not $PocFixture) {
        Throw-MaterializerError -Message "This POC mutation requires explicit -PocFixture." -ExitCode 4
    }

    $normalizedRoot = [System.IO.Path]::GetFullPath($Root).Replace('\', '/')
    $fixturePrefix = "/AIWork/.runtime/codedb/materializer-poc/"
    $prefixIndex = $normalizedRoot.LastIndexOf($fixturePrefix, [StringComparison]::OrdinalIgnoreCase)
    if ($prefixIndex -lt 0) {
        Throw-MaterializerError -Message "POC mutation target is outside the materializer fixture root: $Root" -ExitCode 4
    }
    $fixtureSuffix = $normalizedRoot.Substring($prefixIndex + $fixturePrefix.Length)
    if ($fixtureSuffix -notmatch '^(?<run>[0-9a-fA-F]{32})/(?:fixture|repair-fixture|uninstall-fixture|portability-fixture)$') {
        Throw-MaterializerError -Message "POC mutation target must match one reviewed materializer-poc/<run-id> fixture: $Root" -ExitCode 4
    }
    $runId = $Matches['run'].ToLowerInvariant()
    $fixtureUnityRoot = $normalizedRoot.Substring(0, $prefixIndex).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    Assert-NoReparsePoint -Path $Root -Root $fixtureUnityRoot -Label "POC fixture"

    $fixtureMarkerPath = Join-Path $Root $script:PocFixtureMarkerName
    if (-not (Test-Path -LiteralPath $fixtureMarkerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "POC fixture ownership marker is missing: $fixtureMarkerPath" -ExitCode 4
    }
    try {
        $fixtureMarker = (Read-BoundedJsonDocument -Path $fixtureMarkerPath -Label "POC fixture ownership marker" -MaximumBytes (64 * 1024)).Document
        $fixtureMarkerValid = (Get-RequiredJsonInt32 -Object $fixtureMarker -Name "schema_version" -Label "POC fixture ownership marker") -eq 1 -and
            [string]::Equals((Get-RequiredJsonString -Object $fixtureMarker -Name "managed_by" -Label "POC fixture ownership marker"), $script:ManagedBy, [StringComparison]::Ordinal) -and
            [string]::Equals((Get-RequiredJsonString -Object $fixtureMarker -Name "purpose" -Label "POC fixture ownership marker"), "host-payload-materializer-poc", [StringComparison]::Ordinal) -and
            [string]::Equals((Get-RequiredJsonString -Object $fixtureMarker -Name "run_id" -Label "POC fixture ownership marker"), $runId, [StringComparison]::OrdinalIgnoreCase)
    } catch {
        $fixtureMarkerValid = $false
    }
    if (-not $fixtureMarkerValid) {
        Throw-MaterializerError -Message "POC fixture ownership marker is invalid: $fixtureMarkerPath" -ExitCode 4
    }

}

function Assert-TargetRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = ConvertTo-SafeRelativePath -Path $Path -Label "payload target"
    $allowed = $script:AllowedTargetPaths.ContainsKey($normalized)
    if (-not $allowed) {
        $generationMatch = [regex]::Match(
            $normalized,
            '^AIWork/\.runtime/codedb/host/generations/(?<generation>[A-Za-z0-9._-]{1,64})/(?<relative>.+)$',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($generationMatch.Success) {
            $generationRelativePath = ConvertTo-SafeRelativePath -Path $generationMatch.Groups['relative'].Value -Label "generation payload target"
            $allowed = $script:AllowedGenerationRelativePaths.ContainsKey($generationRelativePath)
        }
    }
    if ([string]::Equals($normalized, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or -not $allowed) {
        Throw-MaterializerError -Message "Payload target is outside the audited production allowlist: $Path" -ExitCode 2
    }

    return $normalized
}

function Initialize-PackageRuntimeContract {
    param(
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][int]$BootstrapProtocol
    )

    if ($GenerationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$' -or
        $BootstrapProtocol -ne $script:SupportedBootstrapProtocol) {
        Throw-MaterializerError -Message "Payload runtime contract identity or bootstrap protocol is unsupported." -ExitCode 2
    }
    if (-not [string]::IsNullOrWhiteSpace($script:GenerationId) -and
        (-not [string]::Equals($script:GenerationId, $GenerationId, [StringComparison]::Ordinal) -or
         $script:BootstrapProtocol -ne $BootstrapProtocol)) {
        Throw-MaterializerError -Message "Payload runtime contract changed during one materializer invocation." -ExitCode 2
    }

    $script:GenerationId = $GenerationId
    $script:BootstrapProtocol = $BootstrapProtocol
    $script:GenerationTargetPrefix = "AIWork/.runtime/codedb/host/generations/$GenerationId/"
}

function Read-PayloadManifest {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $fullRoot = [System.IO.Path]::GetFullPath($Root)
    if (-not (Test-Path -LiteralPath $fullRoot -PathType Container)) {
        Throw-MaterializerError -Message "Payload root does not exist: $fullRoot" -ExitCode 2
    }
    Assert-NoReparsePoint -Path $fullRoot -Root $fullRoot -Label "payload root"

    $manifestPath = Join-Path $fullRoot "payload-manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Payload manifest does not exist: $manifestPath" -ExitCode 2
    }

    $manifestJson = Read-BoundedJsonDocument -Path $manifestPath -Label "payload manifest" -MaximumBytes (1024 * 1024)
    $document = $manifestJson.Document

    $schemaVersion = Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "payload manifest"
    $managedBy = Get-RequiredJsonString -Object $document -Name "managed_by" -Label "payload manifest"
    $packageVersion = Get-RequiredJsonString -Object $document -Name "package_version" -Label "payload manifest"
    $payloadVersion = Get-RequiredJsonString -Object $document -Name "payload_version" -Label "payload manifest"
    $payloadSequence = Get-RequiredJsonInt32 -Object $document -Name "payload_sequence" -Label "payload manifest"
    $generationId = Get-RequiredJsonString -Object $document -Name "generation_id" -Label "payload manifest"
    $bootstrapProtocol = Get-RequiredJsonInt32 -Object $document -Name "bootstrap_protocol" -Label "payload manifest"
    $bootstrapTransitionDocuments = Get-RequiredJsonArray -Object $document -Name "bootstrap_transitions" -Label "payload manifest"
    $currentPointerTarget = Assert-TargetRelativePath -Path (Get-RequiredJsonString -Object $document -Name "current_pointer_target" -Label "payload manifest")
    $retiredTargets = Get-RequiredJsonArray -Object $document -Name "retired_targets" -Label "payload manifest"
    $manifestFiles = Get-RequiredJsonArray -Object $document -Name "files" -Label "payload manifest"

    if ($schemaVersion -ne 1 -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $payloadSequence -lt 1 -or
        $generationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$' -or
        $bootstrapProtocol -ne $script:SupportedBootstrapProtocol -or
        -not [string]::Equals($currentPointerTarget, $script:CurrentPointerRelativePath, [StringComparison]::Ordinal) -or
        $manifestFiles.Count -eq 0) {
        Throw-MaterializerError -Message "Payload manifest identity, version, or file list is invalid." -ExitCode 2
    }
    Initialize-PackageRuntimeContract -GenerationId $generationId -BootstrapProtocol $bootstrapProtocol

    $seenSources = @{}
    $seenTargets = @{}
    $bootstrapTransitions = New-Object System.Collections.Generic.List[object]
    $seenBootstrapTransitions = @{}
    foreach ($entry in $bootstrapTransitionDocuments) {
        $null = Assert-JsonObject -Value $entry -Label "payload bootstrap transition"
        $sourceTag = Get-RequiredJsonString -Object $entry -Name "source_tag" -Label "payload bootstrap transition"
        $sourcePackageVersion = Get-RequiredJsonString -Object $entry -Name "source_package_version" -Label "payload bootstrap transition"
        $sourcePayloadVersion = Get-RequiredJsonString -Object $entry -Name "source_payload_version" -Label "payload bootstrap transition"
        $sourcePayloadSequence = Get-RequiredJsonInt32 -Object $entry -Name "source_payload_sequence" -Label "payload bootstrap transition"
        $sourceGenerationId = Get-RequiredJsonString -Object $entry -Name "source_generation_id" -Label "payload bootstrap transition"
        $sourceBootstrapProtocol = Get-RequiredJsonInt32 -Object $entry -Name "source_bootstrap_protocol" -Label "payload bootstrap transition"
        $sourceMarkerSchemaVersion = Get-RequiredJsonInt32 -Object $entry -Name "source_marker_schema_version" -Label "payload bootstrap transition"
        $sourceHostUseGateVersion = Get-RequiredJsonInt32 -Object $entry -Name "source_host_use_gate_version" -Label "payload bootstrap transition"
        $sourceGenerationLeaseVersion = Get-RequiredJsonInt32 -Object $entry -Name "source_generation_lease_version" -Label "payload bootstrap transition"
        $sourceFlatFileCount = Get-RequiredJsonInt32 -Object $entry -Name "source_flat_file_count" -Label "payload bootstrap transition"
        $sourceFlatClosureSha256 = (Get-RequiredJsonString -Object $entry -Name "source_flat_closure_sha256" -Label "payload bootstrap transition").ToLowerInvariant()
        $sourceStableWrapperSha256 = (Get-RequiredJsonString -Object $entry -Name "source_stable_wrapper_sha256" -Label "payload bootstrap transition").ToLowerInvariant()
        $transitionKey = "$sourcePackageVersion|$sourcePayloadVersion|$sourcePayloadSequence|$sourceGenerationId|$sourceBootstrapProtocol"
        if ($sourceTag -notmatch '^v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$' -or
            [string]::IsNullOrWhiteSpace($sourcePackageVersion) -or
            [string]::IsNullOrWhiteSpace($sourcePayloadVersion) -or
            $sourcePayloadSequence -lt 1 -or $sourcePayloadSequence -ge $payloadSequence -or
            $sourceGenerationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
            $sourceBootstrapProtocol -lt 1 -or
            $sourceMarkerSchemaVersion -notin @(1, $script:MarkerSchemaVersion) -or
            $sourceHostUseGateVersion -lt 1 -or
            $sourceGenerationLeaseVersion -lt 2 -or
            $sourceFlatFileCount -lt 1 -or
            $sourceFlatClosureSha256 -notmatch '^[0-9a-f]{64}$' -or
            $sourceStableWrapperSha256 -notmatch '^[0-9a-f]{64}$' -or
            $seenBootstrapTransitions.ContainsKey($transitionKey)) {
            Throw-MaterializerError -Message "Payload manifest contains an invalid or duplicate bootstrap transition: $transitionKey" -ExitCode 2
        }
        $seenBootstrapTransitions[$transitionKey] = $true
        $bootstrapTransitions.Add([pscustomobject]@{
            SourceTag = $sourceTag
            SourcePackageVersion = $sourcePackageVersion
            SourcePayloadVersion = $sourcePayloadVersion
            SourcePayloadSequence = $sourcePayloadSequence
            SourceGenerationId = $sourceGenerationId
            SourceBootstrapProtocol = $sourceBootstrapProtocol
            SourceMarkerSchemaVersion = $sourceMarkerSchemaVersion
            SourceHostUseGateVersion = $sourceHostUseGateVersion
            SourceGenerationLeaseVersion = $sourceGenerationLeaseVersion
            SourceFlatFileCount = $sourceFlatFileCount
            SourceFlatClosureSha256 = $sourceFlatClosureSha256
            SourceStableWrapperSha256 = $sourceStableWrapperSha256
        })
    }
    $retiredTargetMap = @{}
    foreach ($retiredTargetValue in $retiredTargets) {
        if ($retiredTargetValue -isnot [string]) {
            Throw-MaterializerError -Message "Payload manifest retired target must be a JSON string." -ExitCode 2
        }
        $retiredTarget = Assert-TargetRelativePath -Path ([string]$retiredTargetValue)
        if ($retiredTargetMap.ContainsKey($retiredTarget)) {
            Throw-MaterializerError -Message "Payload manifest contains a duplicate retired target: $retiredTarget" -ExitCode 2
        }
        $retiredTargetMap[$retiredTarget] = $true
    }
    $files = New-Object System.Collections.Generic.List[object]
    $sourceMap = @{}
    $targetMap = @{}
    foreach ($entry in $manifestFiles) {
        $null = Assert-JsonObject -Value $entry -Label "payload file"
        $source = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "source" -Label "payload file") -Label "payload source"
        $target = Assert-TargetRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "target" -Label "payload file")
        $expectedHash = (Get-RequiredJsonString -Object $entry -Name "sha256" -Label "payload file").ToLowerInvariant()
        if ($expectedHash -notmatch '^[0-9a-f]{64}$') {
            Throw-MaterializerError -Message "Payload file has an invalid SHA256: $target" -ExitCode 2
        }
        if ($seenSources.ContainsKey($source) -or $seenTargets.ContainsKey($target)) {
            Throw-MaterializerError -Message "Payload manifest contains a duplicate source or target: $target" -ExitCode 2
        }
        if ($retiredTargetMap.ContainsKey($target)) {
            Throw-MaterializerError -Message "Payload manifest cannot both install and retire the same target: $target" -ExitCode 2
        }
        $seenSources[$source] = $true
        $seenTargets[$target] = $true

        $sourcePath = ConvertTo-AbsoluteChildPath -Root $fullRoot -RelativePath $source -Label "payload source"
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            Throw-MaterializerError -Message "Payload source is missing: $source" -ExitCode 5
        }
        Assert-NoReparsePoint -Path $sourcePath -Root $fullRoot -Label "payload source"
        $actualHash = Get-FileSha256 -Path $sourcePath
        if (-not [string]::Equals($actualHash, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Payload source hash mismatch: $source" -ExitCode 5
        }

        $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "payload target"
        Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "payload target"
        $model = [pscustomobject]@{
            Source = $source
            SourcePath = $sourcePath
            Target = $target
            TargetPath = $targetPath
            Sha256 = $expectedHash
        }
        $files.Add($model)
        $sourceMap[$source] = $model
        $targetMap[$target] = $model
    }

    $manifest = [pscustomobject]@{
        SchemaVersion = $schemaVersion
        ManagedBy = $managedBy
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        GenerationId = $generationId
        BootstrapProtocol = $bootstrapProtocol
        BootstrapTransitions = $bootstrapTransitions.ToArray()
        CurrentPointerTarget = $currentPointerTarget
        RetiredTargets = @($retiredTargetMap.Keys | Sort-Object)
        RetiredTargetMap = $retiredTargetMap
        Root = $fullRoot
        ManifestPath = $manifestPath
        ManifestSha256 = Get-FileSha256 -Path $manifestPath
        Files = @($files | Sort-Object Target)
        SourceMap = $sourceMap
        TargetMap = $targetMap
    }
    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    $usesGenerationContract = $targetMap.ContainsKey($generationManifestTarget) -or
        $targetMap.ContainsKey($script:CurrentPointerRelativePath)
    $manifest | Add-Member -NotePropertyName UsesGenerationContract -NotePropertyValue $usesGenerationContract
    if ($usesGenerationContract) {
        Assert-PayloadGenerationContract -Manifest $manifest
    }
    return $manifest
}

function Assert-PayloadGenerationContract {
    param([Parameter(Mandatory = $true)]$Manifest)

    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    if (-not $Manifest.TargetMap.ContainsKey($generationManifestTarget) -or
        -not $Manifest.TargetMap.ContainsKey($script:CurrentPointerRelativePath)) {
        Throw-MaterializerError -Message "Payload manifest is missing its generation manifest or current pointer target." -ExitCode 2
    }

    $generationManifestFile = $Manifest.TargetMap[$generationManifestTarget]
    $pointerFile = $Manifest.TargetMap[$script:CurrentPointerRelativePath]
    if (-not [string]::Equals($generationManifestFile.Source, "Generations/$($script:GenerationId)/generation-manifest.json", [StringComparison]::Ordinal) -or
        -not [string]::Equals($pointerFile.Source, "host-current.json", [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Payload generation metadata sources do not match the audited package layout." -ExitCode 2
    }

    $generationJson = Read-BoundedJsonDocument -Path $generationManifestFile.SourcePath -Label "generation manifest" -MaximumBytes (1024 * 1024)
    $generation = $generationJson.Document
    $generationFiles = Get-RequiredJsonArray -Object $generation -Name "files" -Label "generation manifest"
    if ((Get-RequiredJsonInt32 -Object $generation -Name "schema_version" -Label "generation manifest") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "managed_by" -Label "generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "generation_id" -Label "generation manifest"), $Manifest.GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "package_version" -Label "generation manifest"), $Manifest.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "payload_version" -Label "generation manifest"), $Manifest.PayloadVersion, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $generation -Name "payload_sequence" -Label "generation manifest") -ne $Manifest.PayloadSequence -or
        (Get-RequiredJsonInt32 -Object $generation -Name "bootstrap_protocol" -Label "generation manifest") -ne $Manifest.BootstrapProtocol -or
        $generationFiles.Count -eq 0) {
        Throw-MaterializerError -Message "Generation manifest identity does not match the payload manifest." -ExitCode 2
    }

    $generationTargetFiles = @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        -not [string]::Equals($_.Target, $generationManifestTarget, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($generationFiles.Count -ne $generationTargetFiles.Count) {
        Throw-MaterializerError -Message "Generation manifest file closure does not match the payload manifest." -ExitCode 2
    }
    $seenGenerationFiles = @{}
    foreach ($entry in $generationFiles) {
        $null = Assert-JsonObject -Value $entry -Label "generation file"
        $relativePath = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "path" -Label "generation file") -Label "generation file"
        $expectedHash = (Get-RequiredJsonString -Object $entry -Name "sha256" -Label "generation file").ToLowerInvariant()
        $target = $script:GenerationTargetPrefix + $relativePath
        if ($expectedHash -notmatch '^[0-9a-f]{64}$' -or
            $seenGenerationFiles.ContainsKey($relativePath) -or
            -not $Manifest.TargetMap.ContainsKey($target) -or
            -not [string]::Equals($Manifest.TargetMap[$target].Sha256, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Generation manifest contains an invalid, duplicate, or mismatched file: $relativePath" -ExitCode 2
        }
        $seenGenerationFiles[$relativePath] = $true
    }

    $pointerJson = Read-BoundedJsonDocument -Path $pointerFile.SourcePath -Label "generation pointer" -MaximumBytes (64 * 1024)
    $pointer = $pointerJson.Document
    $expectedGenerationRoot = $script:GenerationTargetPrefix.TrimEnd('/')
    if ((Get-RequiredJsonInt32 -Object $pointer -Name "schema_version" -Label "generation pointer") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "managed_by" -Label "generation pointer"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "package_version" -Label "generation pointer"), $Manifest.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "payload_version" -Label "generation pointer"), $Manifest.PayloadVersion, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $pointer -Name "payload_sequence" -Label "generation pointer") -ne $Manifest.PayloadSequence -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "generation_id" -Label "generation pointer"), $Manifest.GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "generation_relative_path" -Label "generation pointer"), $expectedGenerationRoot, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "generation_manifest_sha256" -Label "generation pointer"), $generationManifestFile.Sha256, [StringComparison]::OrdinalIgnoreCase) -or
        (Get-RequiredJsonInt32 -Object $pointer -Name "bootstrap_protocol" -Label "generation pointer") -ne $Manifest.BootstrapProtocol) {
        Throw-MaterializerError -Message "Generation pointer identity does not match the payload and generation manifests." -ExitCode 2
    }
}

function Get-MaterializerMachinePrerequisiteStatus {
    param([Parameter(Mandatory = $true)]$Manifest)

    $contractTarget = "AIWork/codedb/shared/codedb-machine-provider-contract.ps1"
    if (-not $Manifest.TargetMap.ContainsKey($contractTarget)) {
        Throw-MaterializerError -Message "Payload manifest is missing the machine Provider prerequisite contract." -ExitCode 2
    }
    $contractPath = [string]$Manifest.TargetMap[$contractTarget].SourcePath
    try {
        . $contractPath
        return Get-CodedbMachinePrerequisiteStatus -PackageVersion $Manifest.PackageVersion
    } catch {
        return [pscustomobject]@{
            Current = $false
            State = "MISSING"
            ReasonCode = "PREREQUISITE_CONTRACT_INVALID"
            Detail = "The Package-owned machine prerequisite contract could not be evaluated: $($_.Exception.Message)"
            NextAction = "Reinstall this CodeDB Package, then let Unity recheck automatically."
            NodePath = ""
            NodeVersion = ""
            ProviderVersion = "0.5.0-28e3912"
            ProviderRoot = ""
            ProviderManifestPath = ""
            ProviderExecutablePath = ""
        }
    }
}

function Write-ReadinessSnapshot {
    param(
        [Parameter(Mandatory = $true)]$Prerequisite,
        [Parameter(Mandatory = $true)][string]$Installed,
        [Parameter(Mandatory = $true)][string]$Configured,
        [Parameter(Mandatory = $true)][string]$McpAvailable,
        [Parameter(Mandatory = $true)][bool]$UsableStatus,
        [Parameter(Mandatory = $true)][bool]$BoundedQuery,
        [Parameter(Mandatory = $true)][string]$CleanupState,
        [Parameter(Mandatory = $true)][string]$ProductState,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $snapshot = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        prerequisite = [ordered]@{
            state = [string]$Prerequisite.State
            reason_code = [string]$Prerequisite.ReasonCode
            node_version = [string]$Prerequisite.NodeVersion
            provider_version = [string]$Prerequisite.ProviderVersion
        }
        installed = $Installed
        configured = $Configured
        mcp_available = $McpAvailable
        usable_status = $UsableStatus
        bounded_query = $BoundedQuery
        cleanup_state = $CleanupState
        product_state = $ProductState
        detail = $Detail
    }
    Write-Host "[READINESS_SNAPSHOT] $($snapshot | ConvertTo-Json -Compress -Depth 5)"
}

function Write-MachinePrerequisiteStatus {
    param([Parameter(Mandatory = $true)]$Status)

    if ($Status.Current) {
        Write-Host "[PRODUCT_LAYER PREREQUISITE] CURRENT - $($Status.Detail)"
        return
    }
    Write-Host "[PRODUCT_LAYER PREREQUISITE] MISSING - $($Status.Detail)"
    Write-Host "[REASON_CODE] $($Status.ReasonCode)"
    Write-Host "[PRODUCT_STATE] MISSING_PREREQUISITE"
    Write-Host "[NEXT] $($Status.NextAction)"
    Write-ReadinessSnapshot `
        -Prerequisite $Status `
        -Installed "UNKNOWN" `
        -Configured "UNKNOWN" `
        -McpAvailable "UNKNOWN" `
        -UsableStatus $false `
        -BoundedQuery $false `
        -CleanupState "UNKNOWN" `
        -ProductState "MISSING_PREREQUISITE" `
        -Detail ([string]$Status.Detail)
}

function Assert-MachinePrerequisiteForAction {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ActionName
    )

    $status = Get-MaterializerMachinePrerequisiteStatus -Manifest $Manifest
    $script:MachinePrerequisiteStatus = $status
    Write-MachinePrerequisiteStatus -Status $status
    if (-not $status.Current) {
        Throw-MaterializerError -Message $status.Detail -ExitCode 4
    }
    return $status
}

function Assert-MutationConfirmation {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][ValidateSet("Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install")][string]$MutationAction
    )

    if ($PocFixture) {
        Assert-PocMutationTarget -Root $Root
        return
    }
    if (-not $ConfirmedProjectMutation) {
        Throw-MaterializerError -Message "$MutationAction requires the Package Manager's second-level project mutation confirmation." -ExitCode 4
    }
    Write-Host "[CONFIRMED] $MutationAction is scoped to CodeDB-owned paths in this Unity project."
}

function Read-InstalledMarker {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $MarkerPath)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Installed payload marker is not a file: $MarkerPath" -ExitCode 2
    }
    Assert-NoReparsePoint -Path $MarkerPath -Root $ProjectRoot -Label "installed payload marker"

    $markerJson = Read-BoundedJsonDocument -Path $MarkerPath -Label "installed payload marker" -MaximumBytes (1024 * 1024)
    $markerText = $markerJson.Text
    $document = $markerJson.Document

    $schemaVersion = Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "installed payload marker"
    $managedBy = Get-RequiredJsonString -Object $document -Name "managed_by" -Label "installed payload marker"
    $packageVersion = Get-RequiredJsonString -Object $document -Name "package_version" -Label "installed payload marker"
    $payloadVersion = Get-RequiredJsonString -Object $document -Name "payload_version" -Label "installed payload marker"
    $payloadSequence = Get-RequiredJsonInt32 -Object $document -Name "payload_sequence" -Label "installed payload marker"
    $payloadContentSha256 = $null
    $payloadContentProperty = Get-ExactJsonProperty -Object $document -Name "payload_content_sha256" -Label "installed payload marker"
    if ($null -ne $payloadContentProperty) {
        if ($payloadContentProperty.Value -isnot [string]) {
            Throw-MaterializerError -Message "Installed payload marker payload_content_sha256 must be a JSON string." -ExitCode 2
        }
        $payloadContentSha256 = ([string]$payloadContentProperty.Value).ToLowerInvariant()
        if ($payloadContentSha256 -notmatch '^[0-9a-f]{64}$') {
            Throw-MaterializerError -Message "Installed payload marker has an invalid payload content identity." -ExitCode 2
        }
    }
    $hostUseGateVersion = 0
    $hostUseGateProperty = Get-ExactJsonProperty -Object $document -Name "host_use_gate_version" -Label "installed payload marker"
    if ($null -ne $hostUseGateProperty) {
        if ($hostUseGateProperty.Value -isnot [int64] -or
            $hostUseGateProperty.Value -lt [int]::MinValue -or
            $hostUseGateProperty.Value -gt [int]::MaxValue) {
            Throw-MaterializerError -Message "Installed payload marker has an invalid host-use gate version." -ExitCode 2
        }
        $hostUseGateVersion = [int]$hostUseGateProperty.Value
        if ($hostUseGateVersion -lt 1) {
            Throw-MaterializerError -Message "Installed payload marker has an invalid host-use gate version." -ExitCode 2
        }
    }
    $generationLeaseVersion = 0
    $generationId = $null
    $bootstrapProtocol = 0
    $generationLeaseProperty = Get-ExactJsonProperty -Object $document -Name "generation_lease_version" -Label "installed payload marker"
    $generationIdProperty = Get-ExactJsonProperty -Object $document -Name "generation_id" -Label "installed payload marker"
    $bootstrapProtocolProperty = Get-ExactJsonProperty -Object $document -Name "bootstrap_protocol" -Label "installed payload marker"
    if ($null -ne $generationLeaseProperty -or $null -ne $generationIdProperty -or $null -ne $bootstrapProtocolProperty) {
        if ($null -eq $generationLeaseProperty -or $generationLeaseProperty.Value -isnot [int64] -or
            $generationLeaseProperty.Value -lt [int]::MinValue -or $generationLeaseProperty.Value -gt [int]::MaxValue -or
            $null -eq $generationIdProperty -or $generationIdProperty.Value -isnot [string] -or
            $null -eq $bootstrapProtocolProperty -or $bootstrapProtocolProperty.Value -isnot [int64] -or
            $bootstrapProtocolProperty.Value -lt [int]::MinValue -or $bootstrapProtocolProperty.Value -gt [int]::MaxValue) {
            Throw-MaterializerError -Message "Installed payload marker has invalid generation metadata." -ExitCode 2
        }
        $generationLeaseVersion = [int]$generationLeaseProperty.Value
        $generationId = [string]$generationIdProperty.Value
        $bootstrapProtocol = [int]$bootstrapProtocolProperty.Value
        if ($generationLeaseVersion -lt 2 -or
            $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
            $bootstrapProtocol -lt 1) {
            Throw-MaterializerError -Message "Installed payload marker has invalid generation metadata." -ExitCode 2
        }
    }
    $markerFiles = Get-RequiredJsonArray -Object $document -Name "files" -Label "installed payload marker"
    if ($schemaVersion -notin @(1, $script:MarkerSchemaVersion) -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $payloadSequence -lt 1 -or
        $markerFiles.Count -eq 0 -or
        ($schemaVersion -eq $script:MarkerSchemaVersion -and
            ($payloadContentSha256 -notmatch '^[0-9a-f]{64}$' -or
             $generationLeaseVersion -lt 2 -or
             $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
             $bootstrapProtocol -lt 1))) {
        Throw-MaterializerError -Message "Installed payload marker identity or version is invalid." -ExitCode 2
    }

    $allMap = @{}
    $trackedMap = @{}
    $historicalRuntimeMap = @{}
    $allFiles = New-Object System.Collections.Generic.List[object]
    $trackedFiles = New-Object System.Collections.Generic.List[object]
    $historicalRuntimeFiles = New-Object System.Collections.Generic.List[object]
    foreach ($entry in $markerFiles) {
        $null = Assert-JsonObject -Value $entry -Label "installed payload file"
        $target = Assert-TargetRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "path" -Label "installed payload file")
        $installedHash = (Get-RequiredJsonString -Object $entry -Name "installed_sha256" -Label "installed payload file").ToLowerInvariant()
        if ($installedHash -notmatch '^[0-9a-f]{64}$' -or $allMap.ContainsKey($target)) {
            Throw-MaterializerError -Message "Installed payload marker contains an invalid hash or duplicate target: $target" -ExitCode 2
        }

        $isTrackedOwnership = $target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase)
        if ($schemaVersion -eq $script:MarkerSchemaVersion -and -not $isTrackedOwnership) {
            Throw-MaterializerError -Message "Schema-$schemaVersion marker files may own only tracked Host targets: $target" -ExitCode 2
        }
        $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "installed payload target"
        Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "installed payload target"
        $model = [pscustomobject]@{
            Target = $target
            TargetPath = $targetPath
            InstalledSha256 = $installedHash
            IsTrackedOwnership = $isTrackedOwnership
        }
        $allMap[$target] = $model
        $allFiles.Add($model)
        if ($isTrackedOwnership) {
            $trackedMap[$target] = $model
            $trackedFiles.Add($model)
        } else {
            $historicalRuntimeMap[$target] = $model
            $historicalRuntimeFiles.Add($model)
        }
    }

    return [pscustomobject]@{
        RawText = $markerText
        Document = $document
        SchemaVersion = $schemaVersion
        ManagedBy = $managedBy
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        PayloadContentSha256 = $payloadContentSha256
        HostUseGateVersion = $hostUseGateVersion
        GenerationLeaseVersion = $generationLeaseVersion
        GenerationId = $generationId
        BootstrapProtocol = $bootstrapProtocol
        Files = [object[]]@($trackedFiles | Sort-Object Target)
        Map = $trackedMap
        HistoricalRuntimeFiles = [object[]]@($historicalRuntimeFiles | Sort-Object Target)
        HistoricalRuntimeMap = $historicalRuntimeMap
        AllFiles = [object[]]@($allFiles | Sort-Object Target)
        AllMap = $allMap
    }
}

function Test-RuntimeIdentityMatch {
    param(
        [Parameter(Mandatory = $true)]$Left,
        [Parameter(Mandatory = $true)]$Right
    )

    return [string]::Equals([string]$Left.PackageVersion, [string]$Right.PackageVersion, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$Left.PayloadVersion, [string]$Right.PayloadVersion, [StringComparison]::Ordinal) -and
        [int]$Left.PayloadSequence -eq [int]$Right.PayloadSequence -and
        [string]::Equals([string]$Left.GenerationId, [string]$Right.GenerationId, [StringComparison]::Ordinal) -and
        [int]$Left.BootstrapProtocol -eq [int]$Right.BootstrapProtocol
}

function Get-RuntimeTransitionForIdentity {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Identity
    )

    $matches = @($Manifest.BootstrapTransitions | Where-Object {
        [string]::Equals([string]$_.SourcePackageVersion, [string]$Identity.PackageVersion, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$_.SourcePayloadVersion, [string]$Identity.PayloadVersion, [StringComparison]::Ordinal) -and
        [int]$_.SourcePayloadSequence -eq [int]$Identity.PayloadSequence -and
        [string]::Equals([string]$_.SourceGenerationId, [string]$Identity.GenerationId, [StringComparison]::Ordinal) -and
        [int]$_.SourceBootstrapProtocol -eq [int]$Identity.BootstrapProtocol
    })
    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}

function Get-RuntimeIdentityDisposition {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Identity
    )

    $identityIsWellFormed = -not [string]::IsNullOrWhiteSpace([string]$Identity.PackageVersion) -and
        -not [string]::IsNullOrWhiteSpace([string]$Identity.PayloadVersion) -and
        [int]$Identity.PayloadSequence -ge 1 -and
        [string]$Identity.GenerationId -match '^[A-Za-z0-9._-]{1,64}$' -and
        [int]$Identity.BootstrapProtocol -ge 1
    if (-not $identityIsWellFormed) { return "INVALID" }

    if (Test-RuntimeIdentityMatch -Left $Identity -Right $Manifest) { return "CURRENT" }
    if ([int]$Identity.PayloadSequence -gt [int]$Manifest.PayloadSequence) { return "NEWER" }
    if ([int]$Identity.PayloadSequence -eq [int]$Manifest.PayloadSequence) { return "SEQUENCE_COLLISION" }
    if ($null -ne (Get-RuntimeTransitionForIdentity -Manifest $Manifest -Identity $Identity)) {
        return "TRUSTED_PREVIOUS"
    }
    return "INVALID"
}

function Get-PackageGenerationIdentityForRuntimeIdentity {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Identity
    )

    $disposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $Identity
    if ([string]::Equals($disposition, "CURRENT", [StringComparison]::Ordinal)) {
        $manifestTarget = "AIWork/.runtime/codedb/host/generations/$($Manifest.GenerationId)/generation-manifest.json"
        if (-not $Manifest.TargetMap.ContainsKey($manifestTarget)) { return $null }
        return [pscustomobject]@{
            Disposition = $disposition
            Transition = $null
            GenerationManifestSha256 = [string]$Manifest.TargetMap[$manifestTarget].Sha256
        }
    }
    if (-not [string]::Equals($disposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal)) {
        return $null
    }

    $transition = Get-RuntimeTransitionForIdentity -Manifest $Manifest -Identity $Identity
    if ($null -eq $transition) { return $null }
    $generationPrefix = "AIWork/.runtime/codedb/host/generations/$($transition.SourceGenerationId)/"
    $manifestTarget = $generationPrefix + "generation-manifest.json"
    if (-not $Manifest.RetiredTargetMap.ContainsKey($manifestTarget)) { return $null }

    $packageGenerationRoot = ConvertTo-AbsoluteChildPath `
        -Root $Manifest.Root `
        -RelativePath "Generations/$($transition.SourceGenerationId)" `
        -Label "Package transition generation"
    $packageGenerationManifestPath = Join-Path $packageGenerationRoot "generation-manifest.json"
    Assert-NoReparsePoint -Path $packageGenerationRoot -Root $Manifest.Root -Label "Package transition generation"
    Assert-NoReparsePoint -Path $packageGenerationManifestPath -Root $packageGenerationRoot -Label "Package transition generation manifest"
    if (-not (Test-Path -LiteralPath $packageGenerationManifestPath -PathType Leaf)) { return $null }

    $document = (Read-BoundedJsonDocument `
        -Path $packageGenerationManifestPath `
        -Label "Package transition generation manifest" `
        -MaximumBytes (1024 * 1024)).Document
    $files = Get-RequiredJsonArray -Object $document -Name "files" -Label "Package transition generation manifest"
    if ((Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "Package transition generation manifest") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "Package transition generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "package_version" -Label "Package transition generation manifest"), [string]$Identity.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "payload_version" -Label "Package transition generation manifest"), [string]$Identity.PayloadVersion, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $document -Name "payload_sequence" -Label "Package transition generation manifest") -ne [int]$Identity.PayloadSequence -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "generation_id" -Label "Package transition generation manifest"), [string]$Identity.GenerationId, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $document -Name "bootstrap_protocol" -Label "Package transition generation manifest") -ne [int]$Identity.BootstrapProtocol -or
        $files.Count -eq 0) {
        return $null
    }

    $expectedFiles = New-Object System.Collections.Generic.List[string]
    $expectedFiles.Add("generation-manifest.json")
    $seen = @{}
    foreach ($entry in $files) {
        $null = Assert-JsonObject -Value $entry -Label "Package transition generation file"
        $relativePath = ConvertTo-SafeRelativePath `
            -Path (Get-RequiredJsonString -Object $entry -Name "path" -Label "Package transition generation file") `
            -Label "Package transition generation file"
        $sha256 = (Get-RequiredJsonString -Object $entry -Name "sha256" -Label "Package transition generation file").ToLowerInvariant()
        $retiredTarget = $generationPrefix + $relativePath
        if ($sha256 -notmatch '^[0-9a-f]{64}$' -or
            $seen.ContainsKey($relativePath) -or
            -not $Manifest.RetiredTargetMap.ContainsKey($retiredTarget)) {
            return $null
        }
        $seen[$relativePath] = $true
        $packagePath = ConvertTo-AbsoluteChildPath `
            -Root $packageGenerationRoot `
            -RelativePath $relativePath `
            -Label "Package transition generation file"
        Assert-NoReparsePoint -Path $packagePath -Root $packageGenerationRoot -Label "Package transition generation file"
        if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $packagePath), $sha256, [StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }
        $expectedFiles.Add($relativePath)
    }
    Assert-ImmutableGenerationFilesystemClosure `
        -Root $packageGenerationRoot `
        -ExpectedFiles $expectedFiles.ToArray() `
        -Label "Package transition generation"
    return [pscustomobject]@{
        Disposition = $disposition
        Transition = $transition
        GenerationManifestSha256 = Get-FileSha256 -Path $packageGenerationManifestPath
    }
}

function Test-EarliestLegacyBootstrapCompatibility {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Marker
    )

    return $Manifest.UsesGenerationContract -and
        $Manifest.BootstrapProtocol -eq $script:SupportedBootstrapProtocol -and
        $Marker.SchemaVersion -eq 1 -and
        [string]::Equals($Marker.ManagedBy, $script:ManagedBy, [StringComparison]::Ordinal) -and
        [string]::Equals($Marker.PackageVersion, "0.2.2", [StringComparison]::Ordinal) -and
        [string]::Equals($Marker.PayloadVersion, "poc.21", [StringComparison]::Ordinal) -and
        $Marker.PayloadSequence -eq 21 -and
        $Marker.HostUseGateVersion -eq 1 -and
        $Marker.GenerationLeaseVersion -eq 0 -and
        [string]::IsNullOrWhiteSpace([string]$Marker.GenerationId) -and
        $Marker.BootstrapProtocol -eq 0 -and
        $Marker.AllFiles.Count -eq 22
}

function Get-InstalledPayloadVersionPolicy {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        $Marker
    )

    if ($null -eq $Marker) {
        return [pscustomobject]@{
            IsDowngrade = $false
            IsSequenceCollision = $false
            PayloadIdentityMatches = $false
            Disposition = "MISSING"
            Transition = $null
            IsInvalid = $false
        }
    }

    $markerIdentityFiles = @(if ($Marker.SchemaVersion -eq 1) { $Marker.AllFiles } else { $Marker.Files })
    $manifestIdentityFiles = @(if ($Marker.SchemaVersion -eq 1) {
        $Manifest.Files
    } else {
        @($Manifest.Files | Where-Object { $_.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase) })
    })
    $markerIdentityMap = if ($Marker.SchemaVersion -eq 1) { $Marker.AllMap } else { $Marker.Map }
    $closureMatches =
        [string]::Equals($Marker.PayloadVersion, $Manifest.PayloadVersion, [StringComparison]::Ordinal) -and
        $markerIdentityFiles.Count -eq $manifestIdentityFiles.Count
    if ($closureMatches) {
        foreach ($file in $manifestIdentityFiles) {
            if (-not $markerIdentityMap.ContainsKey($file.Target) -or
                -not [string]::Equals($markerIdentityMap[$file.Target].InstalledSha256, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                $closureMatches = $false
                break
            }
        }
    }
    if ($closureMatches -and $Marker.SchemaVersion -eq $script:MarkerSchemaVersion) {
        $closureMatches =
            [string]::Equals($Marker.PayloadContentSha256, (Get-PayloadContentIdentitySha256 -Manifest $Manifest), [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($Marker.GenerationId, $Manifest.GenerationId, [StringComparison]::Ordinal) -and
            $Marker.BootstrapProtocol -eq $Manifest.BootstrapProtocol
    }
    $payloadIdentityMatches = $closureMatches -and
        [string]::Equals($Marker.PackageVersion, $Manifest.PackageVersion, [StringComparison]::Ordinal)

    $disposition = "LEGACY_COMPATIBLE"
    $transition = $null
    $isInvalid = $false
    if ($Manifest.UsesGenerationContract -and
        -not [string]::IsNullOrWhiteSpace([string]$Marker.GenerationId)) {
        $disposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $Marker
        if ([string]::Equals($disposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal)) {
            $transition = Get-ReviewedBootstrapTransition -Manifest $Manifest -Marker $Marker
            if ($null -eq $transition) {
                $disposition = "INVALID"
            }
        } elseif ([string]::Equals($disposition, "CURRENT", [StringComparison]::Ordinal) -and
            -not $payloadIdentityMatches) {
            $disposition = "INVALID"
        }
        $isInvalid = [string]::Equals($disposition, "INVALID", [StringComparison]::Ordinal)
    } elseif ($Manifest.UsesGenerationContract) {
        $reviewedLegacy = $null -ne (Get-ReviewedLegacyMarkerIdentity -Marker $Marker) -or
            (Test-EarliestLegacyBootstrapCompatibility -Manifest $Manifest -Marker $Marker)
        if (-not $reviewedLegacy) {
            $disposition = "INVALID"
            $isInvalid = $true
        }
    }

    $isDowngrade = if ($Manifest.UsesGenerationContract) {
        [string]::Equals($disposition, "NEWER", [StringComparison]::Ordinal)
    } else {
        $Marker.PayloadSequence -gt $Manifest.PayloadSequence
    }
    $isSequenceCollision = if ($Manifest.UsesGenerationContract) {
        [string]::Equals($disposition, "SEQUENCE_COLLISION", [StringComparison]::Ordinal)
    } else {
        $Marker.PayloadSequence -eq $Manifest.PayloadSequence -and -not $closureMatches
    }
    return [pscustomobject]@{
        IsDowngrade = $isDowngrade
        IsSequenceCollision = $isSequenceCollision
        PayloadIdentityMatches = $payloadIdentityMatches
        Disposition = $disposition
        Transition = $transition
        IsInvalid = $isInvalid
    }
}

function Get-MaterializationPlan {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $marker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    $filePlans = New-Object System.Collections.Generic.List[object]
    $desiredTargets = @{}
    $hasConflict = $false
    $runtimeConflict = $null
    $selectedGeneration = $null
    $selectedDisposition = "MISSING"
    $pointerValidationError = $null
    $candidateGenerationRoot = $null
    $candidateGenerationExists = $false

    if ($Manifest.UsesGenerationContract) {
        $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "current generation pointer"
        if (Test-Path -LiteralPath $currentPointerPath) {
            if (-not (Test-Path -LiteralPath $currentPointerPath -PathType Leaf)) {
                $pointerValidationError = "Current generation pointer is not a regular file."
            } else {
                try {
                    $selectedGeneration = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
                    if ($null -ne $selectedGeneration) {
                        $selectedDisposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $selectedGeneration
                    }
                } catch {
                    $pointerValidationError = $_.Exception.Message
                }
            }
        }

        $candidateGenerationRoot = ConvertTo-AbsoluteChildPath `
            -Root $ProjectRoot `
            -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') `
            -Label "package generation candidate"
        if (Test-Path -LiteralPath $candidateGenerationRoot) {
            $candidateGenerationExists = $true
            if (-not (Test-Path -LiteralPath $candidateGenerationRoot -PathType Container)) {
                $runtimeConflict = "Package generation candidate is not a directory."
            } else {
                try {
                    Assert-GenerationDirectoryMatchesManifest `
                        -Manifest $Manifest `
                        -GenerationRoot $candidateGenerationRoot `
                        -ProjectRoot $ProjectRoot `
                        -SkipSyntaxValidation
                } catch {
                    $runtimeConflict = $_.Exception.Message
                }
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($runtimeConflict)) {
            $hasConflict = $true
        }
    }

    foreach ($file in $Manifest.Files) {
        $desiredTargets[$file.Target] = $true
        $oldEntry = $null
        if ($null -ne $marker -and $marker.Map.ContainsKey($file.Target)) {
            $oldEntry = $marker.Map[$file.Target]
        }

        $targetHash = $null
        $status = $null
        $detail = $null
        $isTrackedOwnershipTarget = $file.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase)
        $isGenerationTarget = $file.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
        $isCurrentPointerTarget = [string]::Equals($file.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)
        if ($isGenerationTarget) {
            if (-not (Test-Path -LiteralPath $file.TargetPath)) {
                $status = "Missing"
                $detail = "package generation is not installed"
            } elseif (-not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf)) {
                $status = "Conflict"
                $detail = "package generation target is not a regular file"
            } else {
                $targetHash = Get-FileSha256 -Path $file.TargetPath
                if ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                    $status = "Current"
                    $detail = "runtime file matches the validated package generation"
                } else {
                    $status = "Conflict"
                    $detail = "package generation target differs from the immutable payload"
                }
            }
        } elseif ($isCurrentPointerTarget) {
            if (-not (Test-Path -LiteralPath $file.TargetPath)) {
                $status = "Missing"
                $detail = "no generation is selected on this machine"
            } elseif (-not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf)) {
                $status = "Conflict"
                $detail = "current generation pointer is not a regular file"
            } else {
                $targetHash = Get-FileSha256 -Path $file.TargetPath
                if (-not [string]::IsNullOrWhiteSpace($pointerValidationError)) {
                    $status = "Conflict"
                    $detail = "selected generation is invalid: $pointerValidationError"
                } elseif ($null -eq $selectedGeneration) {
                    $status = "Conflict"
                    $detail = "selected generation could not be validated"
                } else {
                    switch ($selectedDisposition) {
                        "CURRENT" {
                            $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
                            if (-not [string]::Equals(
                                $selectedGeneration.GenerationManifestSha256,
                                $Manifest.TargetMap[$generationManifestTarget].Sha256,
                                [StringComparison]::OrdinalIgnoreCase)) {
                                $status = "Conflict"
                                $detail = "selected current generation does not match the Package immutable manifest"
                            } elseif ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                                $status = "Current"
                                $detail = "current pointer selects the validated package generation"
                            } else {
                                $status = "Upgradeable"
                                $detail = "current generation identity is valid and its pointer bytes can converge"
                            }
                        }
                        "TRUSTED_PREVIOUS" {
                            $packagePrevious = Get-ValidatedPackageOwnedInstalledGeneration `
                                -GenerationId $selectedGeneration.GenerationId `
                                -ProjectRoot $ProjectRoot `
                                -PayloadRoot $Manifest.Root
                            if ($null -eq $packagePrevious -or
                                -not (Test-RuntimeIdentityMatch -Left $selectedGeneration -Right $packagePrevious) -or
                                -not [string]::Equals(
                                    $selectedGeneration.GenerationManifestSha256,
                                    $packagePrevious.GenerationManifestSha256,
                                    [StringComparison]::OrdinalIgnoreCase)) {
                                $status = "Conflict"
                                $detail = "selected previous generation does not match its Package-preserved immutable closure"
                            } else {
                                $status = "Upgradeable"
                                $detail = "Package-declared previous generation can switch atomically to the current generation"
                            }
                        }
                        "NEWER" {
                            $status = "Conflict"
                            $detail = "selected generation is newer than the requested package"
                        }
                        "SEQUENCE_COLLISION" {
                            $status = "Conflict"
                            $detail = "selected generation reuses the requested sequence with a different identity"
                        }
                        default {
                            $status = "Conflict"
                            $detail = "selected generation is not an exact Package-declared transition"
                        }
                    }
                }
            }
        } elseif (Test-Path -LiteralPath $file.TargetPath) {
            if (-not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf)) {
                $status = "Conflict"
                $detail = "target is not a regular file"
            } else {
                $targetHash = Get-FileSha256 -Path $file.TargetPath
                if ($null -eq $oldEntry) {
                if ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                    if ($null -eq $marker) {
                        $status = "Conflict"
                        $detail = "unknown same-name file exists without CodeDB ownership"
                    } else {
                        $status = "Adoptable"
                        $detail = "exact newly introduced file under an existing CodeDB adoption"
                    }
                    } else {
                        $status = "Conflict"
                        $detail = "unowned file differs from package payload"
                    }
                } elseif ([string]::Equals($targetHash, $oldEntry.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    if ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                        $status = "Current"
                        $detail = "managed file matches package payload"
                    } else {
                        $status = "Upgradeable"
                        $detail = "managed file is unchanged since installation"
                    }
                } elseif ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                    $status = "Upgradeable"
                    $detail = "file already matches the new payload; marker needs update"
                } else {
                    $status = "ManagedDrift"
                    $detail = "managed file changed after installation"
                }
            }
        } elseif ($null -eq $oldEntry) {
            $status = "Missing"
            $detail = "target is not installed"
        } else {
            $status = "ManagedMissing"
            $detail = "managed target was removed after installation"
        }

        if ($status -in @("Conflict", "ManagedDrift", "ManagedMissing")) {
            $hasConflict = $true
        }
        $filePlans.Add([pscustomobject]@{
            Status = $status
            Detail = $detail
            Source = $file.Source
            SourcePath = $file.SourcePath
            SourceSha256 = $file.Sha256
            Target = $file.Target
            TargetPath = $file.TargetPath
            TargetSha256 = $targetHash
            PreviousSha256 = if ($null -eq $oldEntry) { $null } else { $oldEntry.InstalledSha256 }
            IsTrackedOwnership = $isTrackedOwnershipTarget
            IsRuntime = $isGenerationTarget -or $isCurrentPointerTarget
        })
    }

    $retiredPlans = New-Object System.Collections.Generic.List[object]
    if ($null -ne $marker) {
        foreach ($oldEntry in $marker.AllFiles) {
            if ($desiredTargets.ContainsKey($oldEntry.Target)) {
                continue
            }

            $targetHash = $null
            if (-not $Manifest.RetiredTargetMap.ContainsKey($oldEntry.Target)) {
                $status = "UntrustedOwnedPath"
                $detail = "marker target is not allowed by the current or retired manifest allowlist"
                $hasConflict = $true
            } elseif (-not (Test-Path -LiteralPath $oldEntry.TargetPath -PathType Leaf)) {
                $status = "ManagedMissing"
                $detail = "retired managed target is missing or not a file"
                $hasConflict = $true
            } else {
                $targetHash = Get-FileSha256 -Path $oldEntry.TargetPath
                if ([string]::Equals($targetHash, $oldEntry.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    $status = "Retirable"
                    $detail = "managed file was removed from the new payload"
                } else {
                    $status = "RetireConflict"
                    $detail = "retired managed file changed after installation"
                    $hasConflict = $true
                }
            }
            $retiredPlans.Add([pscustomobject]@{
                Status = $status
                Detail = $detail
                Target = $oldEntry.Target
                TargetPath = $oldEntry.TargetPath
                TargetSha256 = $targetHash
                PreviousSha256 = $oldEntry.InstalledSha256
            })
        }
    }

    $versionPolicy = Get-InstalledPayloadVersionPolicy -Manifest $Manifest -Marker $marker
    if ($versionPolicy.IsDowngrade -or $versionPolicy.IsSequenceCollision -or $versionPolicy.IsInvalid) {
        $hasConflict = $true
    }

    $markerCurrent = $null -ne $marker -and
        $versionPolicy.PayloadIdentityMatches -and
        $marker.PayloadSequence -eq $Manifest.PayloadSequence -and
        $marker.HostUseGateVersion -eq $script:HostUseGateVersion -and
        [string]::Equals($marker.RawText, (New-MarkerJson -Manifest $Manifest), [StringComparison]::Ordinal)

    $allFilesCurrent = @($filePlans | Where-Object { $_.Status -ne "Current" }).Count -eq 0
    $isCurrent = $markerCurrent -and $allFilesCurrent -and $retiredPlans.Count -eq 0
    return [pscustomobject]@{
        Marker = $marker
        Files = $filePlans.ToArray()
        Retired = $retiredPlans.ToArray()
        HasConflict = $hasConflict
        IsCurrent = $isCurrent
        MarkerNeedsUpdate = -not $markerCurrent
        IsDowngrade = $versionPolicy.IsDowngrade
        IsSequenceCollision = $versionPolicy.IsSequenceCollision
        IsInvalidIdentity = $versionPolicy.IsInvalid
        MarkerDisposition = $versionPolicy.Disposition
        BootstrapTransition = $versionPolicy.Transition
        PayloadIdentityMatches = $versionPolicy.PayloadIdentityMatches
        RuntimeConflict = $runtimeConflict
        SelectedGeneration = $selectedGeneration
        SelectedDisposition = $selectedDisposition
        CandidateGenerationExists = $candidateGenerationExists
    }
}

function Write-MaterializationPlan {
    param([Parameter(Mandatory = $true)]$Plan)

    if (-not [string]::IsNullOrWhiteSpace([string]$Plan.RuntimeConflict)) {
        Write-Host "[CONFLICT] RuntimeGeneration: $($Plan.RuntimeConflict)"
    }
    if ($Plan.IsDowngrade) {
        Write-Host "[CONFLICT] Downgrade: installed payload sequence is newer than the requested payload."
    }
    if ($Plan.IsSequenceCollision) {
        Write-Host "[CONFLICT] SequenceCollision: the installed and requested payloads reuse one sequence with different identities or file hashes."
    }
    if ($Plan.IsInvalidIdentity) {
        Write-Host "[CONFLICT] InvalidIdentity: the installed payload is not current or an exact Package-declared transition."
    }
    foreach ($item in @($Plan.Files) + @($Plan.Retired)) {
        $prefix = if ($item.Status -in @("Conflict", "ManagedDrift", "ManagedMissing", "RetireConflict", "UntrustedOwnedPath")) { "[CONFLICT]" } else { "[PLAN]" }
        Write-Host "$prefix $($item.Status): $($item.Target) - $($item.Detail)"
    }
}

function Test-SafeFirstAdoptionPlan {
    param(
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if ($null -ne $Plan.Marker -or $Plan.HasConflict -or $Plan.Retired.Count -gt 0) {
        return $false
    }
    foreach ($item in $Plan.Files) {
        if ($item.IsTrackedOwnership -and $item.Status -ne "Missing") {
            return $false
        }
        if ([string]::Equals($item.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase) -and
            $item.Status -ne "Missing") {
            return $false
        }
        if ($item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase) -and
            $item.Status -ne "Missing") {
            return $false
        }
    }
    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:LastKnownGoodPointerRelativePath `
        -Label "first-adoption rollback pointer"
    return -not (Test-Path -LiteralPath $lastKnownGoodPath)
}

function Get-InstalledFlatClosureSha256 {
    param([Parameter(Mandatory = $true)]$Marker)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("schema_version=$($Marker.SchemaVersion)")
    $lines.Add("managed_by=$($Marker.ManagedBy)")
    $lines.Add("package_version=$($Marker.PackageVersion)")
    $lines.Add("payload_version=$($Marker.PayloadVersion)")
    $lines.Add("payload_sequence=$($Marker.PayloadSequence)")
    $lines.Add("host_use_gate_version=$($Marker.HostUseGateVersion)")
    $lines.Add("generation_lease_version=$($Marker.GenerationLeaseVersion)")
    $lines.Add("generation_id=$($Marker.GenerationId)")
    $lines.Add("bootstrap_protocol=$($Marker.BootstrapProtocol)")
    [string[]]$targets = @($Marker.Files | ForEach-Object { [string]$_.Target })
    [Array]::Sort($targets, [StringComparer]::Ordinal)
    foreach ($target in $targets) {
        $file = $Marker.Map[$target]
        $lines.Add("file=$($file.Target):$($file.InstalledSha256)")
    }
    return Get-TextSha256 -Text (($lines -join "`n") + "`n")
}

function Get-ReviewedBootstrapTransition {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Marker
    )

    foreach ($transition in @($Manifest.BootstrapTransitions)) {
        if ($Marker.SchemaVersion -eq $transition.SourceMarkerSchemaVersion -and
            [string]::Equals($Marker.ManagedBy, $script:ManagedBy, [StringComparison]::Ordinal) -and
            [string]::Equals($Marker.PackageVersion, $transition.SourcePackageVersion, [StringComparison]::Ordinal) -and
            [string]::Equals($Marker.PayloadVersion, $transition.SourcePayloadVersion, [StringComparison]::Ordinal) -and
            $Marker.PayloadSequence -eq $transition.SourcePayloadSequence -and
            [string]::Equals($Marker.GenerationId, $transition.SourceGenerationId, [StringComparison]::Ordinal) -and
            $Marker.BootstrapProtocol -eq $transition.SourceBootstrapProtocol -and
            $Marker.HostUseGateVersion -eq $transition.SourceHostUseGateVersion -and
            $Marker.GenerationLeaseVersion -eq $transition.SourceGenerationLeaseVersion -and
            $Marker.Files.Count -eq $transition.SourceFlatFileCount -and
            [string]::Equals(
                (Get-InstalledFlatClosureSha256 -Marker $Marker),
                $transition.SourceFlatClosureSha256,
                [StringComparison]::OrdinalIgnoreCase)) {
            return $transition
        }
    }
    return $null
}

function Get-AutomaticUpgradeEligibility {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $marker = $Plan.Marker
    if ($Plan.HasConflict) {
        return [pscustomobject]@{ Eligible = $false; Reason = "a CodeDB ownership or path conflict requires explicit review" }
    }
    if ($null -eq $marker) {
        if (-not (Test-SafeFirstAdoptionPlan -Plan $Plan -ProjectRoot $ProjectRoot)) {
            return [pscustomobject]@{ Eligible = $false; Reason = "first adoption requires an empty CodeDB-managed target scope" }
        }
        return [pscustomobject]@{ Eligible = $true; Reason = "empty CodeDB-managed scope can be adopted safely" }
    }
    foreach ($retired in $Plan.Retired) {
        $immutableGenerationTarget = $retired.Target -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/'
        if (-not $immutableGenerationTarget -or $retired.Status -ne "Retirable") {
            return [pscustomobject]@{ Eligible = $false; Reason = "non-generation retired target requires explicit review" }
        }
    }
    $earliestLegacyBootstrap = Test-EarliestLegacyBootstrapCompatibility -Manifest $Manifest -Marker $marker
    $bootstrapTransition = if ([string]::Equals([string]$Plan.MarkerDisposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal)) {
        $Plan.BootstrapTransition
    } else { $null }
    $knownGenerationUpgrade = $null -ne $bootstrapTransition
    $knownAdoptedRuntimeRepair = [string]::Equals([string]$Plan.MarkerDisposition, "CURRENT", [StringComparison]::Ordinal) -and
        $Plan.PayloadIdentityMatches -and
        $marker.GenerationLeaseVersion -ge 2 -and
        (Test-RuntimeIdentityMatch -Left $marker -Right $Manifest)
    if (-not $earliestLegacyBootstrap -and -not $knownGenerationUpgrade -and -not $knownAdoptedRuntimeRepair) {
        return [pscustomobject]@{ Eligible = $false; Reason = "installed payload is not a supported owned generation upgrade source" }
    }

    $wrapperTarget = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    foreach ($item in $Plan.Files) {
        if ([string]::Equals($item.Target, $wrapperTarget, [StringComparison]::OrdinalIgnoreCase)) {
            $ownedWrapperTransition = if ($earliestLegacyBootstrap) {
                $item.Status -eq "Upgradeable" -and
                    -not [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256) -and
                    [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)
            } elseif ($null -ne $bootstrapTransition) {
                $true
            } else {
                # A generation-only update must not replace the stable bridge.
                # Bootstrap protocol migrations require their own reviewed path.
                $item.Status -eq "Current"
            }
            if (-not $ownedWrapperTransition) {
                return [pscustomobject]@{ Eligible = $false; Reason = "bootstrap wrapper is not byte-exact at a supported protocol transition" }
            }
            if ($null -eq $bootstrapTransition -or $earliestLegacyBootstrap) {
                continue
            }
        }
        if ($item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            if ($item.Status -notin @("Missing", "Current")) {
                return [pscustomobject]@{ Eligible = $false; Reason = "new generation target already exists and requires collision review" }
            }
            continue
        }
        if ([string]::Equals($item.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
            $ownedPointerTransition = if ($earliestLegacyBootstrap) {
                $item.Status -eq "Missing"
            } else {
                $item.Status -in @("Missing", "Upgradeable", "Current")
            }
            if (-not $ownedPointerTransition) {
                return [pscustomobject]@{ Eligible = $false; Reason = "selected generation pointer requires collision review" }
            }
            continue
        }
        if ($null -ne $bootstrapTransition -and
            $item.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $introducedTarget = [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256)
            $ownedBootstrapTransition = if ($introducedTarget) {
                $item.Status -in @("Missing", "Adoptable")
            } else {
                $item.Status -in @("Current", "Upgradeable") -and
                    [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)
            }
            if (-not $ownedBootstrapTransition) {
                return [pscustomobject]@{ Eligible = $false; Reason = "reviewed bootstrap transition source is not byte-exact" }
            }
            continue
        }
        $ownedUnmodifiedTarget = $item.Status -eq "Current" -and
            -not [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256) -and
            [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)
        if (-not $ownedUnmodifiedTarget) {
            return [pscustomobject]@{ Eligible = $false; Reason = "existing bootstrap payload is not fully owned and byte-exact" }
        }
    }
    $reason = if ($earliestLegacyBootstrap) {
        "owned earliest legacy bootstrap can migrate without replacing active legacy scripts"
    } elseif ($knownAdoptedRuntimeRepair) {
        "tracked adoption is current and ignored runtime can be reconstructed safely"
    } elseif ($null -ne $bootstrapTransition) {
        "reviewed $($bootstrapTransition.SourceTag) flat bootstrap can transition while immutable generation leases remain protected"
    } else {
        "owned immutable generation can switch while its leases remain protected"
    }
    return [pscustomobject]@{ Eligible = $true; Reason = $reason }
}

function Get-OwnedLegacyRedeployEligibility {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Plan
    )

    $marker = $Plan.Marker
    if ($null -eq $marker) {
        return [pscustomobject]@{ Eligible = $false; Reason = "no owned legacy payload is installed" }
    }
    if ($Plan.IsCurrent) {
        return [pscustomobject]@{ Eligible = $false; Reason = "host payload is already current" }
    }
    if ($Plan.HasConflict) {
        return [pscustomobject]@{ Eligible = $false; Reason = "a CodeDB ownership or path conflict requires explicit review" }
    }
    if (-not [string]::Equals([string]$Plan.MarkerDisposition, "LEGACY_COMPATIBLE", [StringComparison]::Ordinal) -or
        $marker.PayloadSequence -ge $Manifest.PayloadSequence -or
        -not [string]::IsNullOrWhiteSpace([string]$marker.GenerationId) -or
        $marker.HostUseGateVersion -lt 1 -or
        -not $Manifest.UsesGenerationContract -or
        $Manifest.BootstrapProtocol -ne $script:SupportedBootstrapProtocol) {
        return [pscustomobject]@{ Eligible = $false; Reason = "installed payload is not a supported flat legacy redeploy source" }
    }

    $supportedIdentity = Get-ReviewedLegacyMarkerIdentity -Marker $marker
    if ($null -eq $supportedIdentity) {
        return [pscustomobject]@{ Eligible = $false; Reason = "installed payload identity is not in the reviewed legacy redeploy allowlist" }
    }

    foreach ($item in $Plan.Files) {
        if ($item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase) -or
            [string]::Equals($item.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
            if ($item.Status -ne "Missing") {
                return [pscustomobject]@{ Eligible = $false; Reason = "new generation target already exists and requires explicit review" }
            }
            continue
        }
        $isNewMissingTarget = $item.Status -eq "Missing" -and
            [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256)
        if ($isNewMissingTarget) {
            continue
        }
        if (-not $item.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase) -or
            $item.Status -notin @("Current", "Upgradeable") -or
            [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256) -or
            -not [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)) {
            return [pscustomobject]@{ Eligible = $false; Reason = "legacy flat payload is not fully owned and byte-exact" }
        }
    }
    if ($Plan.Retired.Count -gt 0) {
        return [pscustomobject]@{ Eligible = $false; Reason = "legacy marker contains targets outside the current flat payload closure" }
    }

    return [pscustomobject]@{
        Eligible = $true
        Reason = "owned $($marker.PayloadVersion) flat payload can be stopped and redeployed to generation $($Manifest.GenerationId)"
        Marker = $marker
        ReviewedIdentity = $supportedIdentity
    }
}

function Get-ReviewedLegacyMarkerIdentity {
    param([Parameter(Mandatory = $true)]$Marker)

    if ($Marker.SchemaVersion -ne 1 -or
        -not [string]::Equals($Marker.ManagedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        $Marker.HostUseGateVersion -ne 1 -or
        $Marker.AllFiles.Count -ne 21) {
        return $null
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("managed_by=$($Marker.ManagedBy)")
    $lines.Add("schema_version=$($Marker.SchemaVersion)")
    $lines.Add("package_version=$($Marker.PackageVersion)")
    $lines.Add("payload_version=$($Marker.PayloadVersion)")
    $lines.Add("payload_sequence=$($Marker.PayloadSequence)")
    $lines.Add("host_use_gate_version=$($Marker.HostUseGateVersion)")
    foreach ($file in @($Marker.AllFiles | Sort-Object Target)) {
        $lines.Add("file=$($file.Target):$($file.InstalledSha256)")
    }
    $closureSha256 = Get-TextSha256 -Text (($lines -join "`n") + "`n")
    $matches = @(@(
        [pscustomobject]@{
            PackageVersion = "0.1.0"
            PayloadVersion = "poc.9"
            PayloadSequence = 9
            ClosureSha256 = "89bd8be3d643c37838426e1e0c14465ef79ccf855feb97def1bada9c2e63a915"
        },
        [pscustomobject]@{
            PackageVersion = "0.2.0"
            PayloadVersion = "poc.16"
            PayloadSequence = 16
            ClosureSha256 = "112a2b5883242328b22b448e915bdc4776bc37c9b02f3c3733f613ee22ff3f12"
        },
        [pscustomobject]@{
            PackageVersion = "0.2.1"
            PayloadVersion = "poc.20"
            PayloadSequence = 20
            ClosureSha256 = "2c91c8d35d372d37d7b468a436972eab7bb4af871c266d9e1c835a58bf7cef42"
        }
    ) | Where-Object {
        [string]::Equals($_.PackageVersion, $Marker.PackageVersion, [StringComparison]::Ordinal) -and
        [string]::Equals($_.PayloadVersion, $Marker.PayloadVersion, [StringComparison]::Ordinal) -and
        $_.PayloadSequence -eq $Marker.PayloadSequence -and
        [string]::Equals($_.ClosureSha256, $closureSha256, [StringComparison]::Ordinal)
    })
    if ($matches.Count -ne 1) { return $null }
    return $matches[0]
}

function Assert-ReviewedLegacyFlatPayloadClosure {
    param(
        [Parameter(Mandatory = $true)]$Marker,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $identity = Get-ReviewedLegacyMarkerIdentity -Marker $Marker
    if ($null -eq $identity) {
        Throw-MaterializerError -Message "Legacy flat payload marker does not match a reviewed published closure." -ExitCode 4
    }
    foreach ($file in $Marker.AllFiles) {
        if (-not $file.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Reviewed legacy marker contains a target outside the flat Host closure: $($file.Target)" -ExitCode 4
        }
        $path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $file.Target -Label "reviewed legacy Host file"
        Assert-NoReparsePoint -Path $path -Root $ProjectRoot -Label "reviewed legacy Host file"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $path), $file.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Reviewed legacy Host file is missing or drifted: $($file.Target)" -ExitCode 4
        }
    }
    return $identity
}

function New-MarkerJson {
    param([Parameter(Mandatory = $true)]$Manifest)

    $files = @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase)
    } | Sort-Object Target | ForEach-Object {
        [ordered]@{
            path = $_.Target
            installed_sha256 = $_.Sha256
        }
    })
    $document = [ordered]@{
        schema_version = $script:MarkerSchemaVersion
        managed_by = $script:ManagedBy
        package_version = $Manifest.PackageVersion
        payload_version = $Manifest.PayloadVersion
        payload_sequence = $Manifest.PayloadSequence
        payload_content_sha256 = Get-PayloadContentIdentitySha256 -Manifest $Manifest
        host_use_gate_version = $script:HostUseGateVersion
        generation_lease_version = 2
        generation_id = $Manifest.GenerationId
        bootstrap_protocol = $Manifest.BootstrapProtocol
        current_pointer = $Manifest.CurrentPointerTarget
        files = $files
    }
    $json = $document | ConvertTo-Json -Depth 8
    return $json.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd([char]10) + "`n"
}

function Enter-MaterializerLock {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$WaitForExisting,
        [ValidateRange(1, 120000)][int]$WaitTimeoutMilliseconds = 30000
    )

    $lockRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
    Assert-NoReparsePoint -Path $lockRoot -Root $ProjectRoot -Label "materializer runtime"
    New-Item -ItemType Directory -Force -Path $lockRoot | Out-Null
    $lockPath = Join-Path $lockRoot "materialize.lock"
    Assert-NoReparsePoint -Path $lockPath -Root $ProjectRoot -Label "materializer lock"
    $lockFileExistedBefore = Test-Path -LiteralPath $lockPath -PathType Leaf
    if ((Test-Path -LiteralPath $lockPath) -and -not $lockFileExistedBefore) {
        Throw-MaterializerError -Message "Materializer lock path is not a regular file: $lockPath" -ExitCode 7
    }
    $stream = $null
    $deadline = [DateTime]::UtcNow.AddMilliseconds($WaitTimeoutMilliseconds)
    while ($null -eq $stream) {
        try {
            $stream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        } catch {
            if (-not $WaitForExisting -or [DateTime]::UtcNow -ge $deadline) {
                Throw-MaterializerError -Message "Another payload materialization is active: $lockPath" -ExitCode 4
            }
            if (-not (Test-Path -LiteralPath $lockRoot -PathType Container)) {
                Assert-NoReparsePoint -Path $lockRoot -Root $ProjectRoot -Label "materializer runtime"
                New-Item -ItemType Directory -Force -Path $lockRoot | Out-Null
                Assert-NoReparsePoint -Path $lockRoot -Root $ProjectRoot -Label "materializer runtime"
            }
            Start-Sleep -Milliseconds 50
        }
    }

    return [pscustomobject]@{
        Root = $lockRoot
        Path = $lockPath
        Stream = $stream
        LockFileExistedBefore = $lockFileExistedBefore
        PreserveLockFile = $false
        ActiveMarkerPath = Join-Path $lockRoot $script:ActiveMarkerName
        ActiveMarkerPublished = $false
        ProviderRuntimeRoots = @()
        ManagementLocks = New-Object System.Collections.Generic.List[object]
    }
}

function Exit-MaterializerWatchManagementLocks {
    param($Lock)

    if ($null -eq $Lock -or $null -eq $Lock.ManagementLocks) {
        return
    }
    foreach ($managementLock in @($Lock.ManagementLocks.ToArray()) | Sort-Object { $_.Path.Length } -Descending) {
        if ($null -ne $managementLock.Stream) {
            $managementLock.Stream.Dispose()
        }
        if (-not $managementLock.ExistedBefore) {
            Remove-Item -LiteralPath $managementLock.Path -Force -ErrorAction SilentlyContinue
        }
    }
    $Lock.ManagementLocks.Clear()
}

function Exit-MaterializerLock {
    param($Lock)

    if ($null -eq $Lock) {
        return
    }
    Exit-MaterializerWatchManagementLocks -Lock $Lock
    $hasPendingTransaction = @(Get-ChildItem -LiteralPath $Lock.Root -Force -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name.StartsWith($script:TransactionPrefix, [StringComparison]::Ordinal)
    }).Count -gt 0
    if ($Lock.ActiveMarkerPublished -and -not $hasPendingTransaction) {
        Remove-Item -LiteralPath $Lock.ActiveMarkerPath -Force -ErrorAction SilentlyContinue
    }

    if ($null -ne $Lock.Stream) {
        $Lock.Stream.Dispose()
    }
    if (-not $Lock.PreserveLockFile) {
        Remove-Item -LiteralPath $Lock.Path -Force -ErrorAction SilentlyContinue
    }
    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    if ((Test-Path -LiteralPath $leaseRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $leaseRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $leaseRoot -Force -ErrorAction SilentlyContinue
    }
    if ((Test-Path -LiteralPath $Lock.Root -PathType Container) -and
        @(Get-ChildItem -LiteralPath $Lock.Root -Force).Count -eq 0) {
        Remove-Item -LiteralPath $Lock.Root -Force -ErrorAction SilentlyContinue
    }
}

function Test-MaterializerProcessAlive {
    param([AllowNull()]$ProcessId)

    return (Get-MaterializerProcessIdentity -ProcessId $ProcessId).Alive
}

function Get-MaterializerProcessIdentity {
    param([AllowNull()]$ProcessId)

    try {
        $numericProcessId = [int]$ProcessId
        if ($numericProcessId -le 0) {
            return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
        }
    } catch {
        return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
    }

    if ($PocFixture -and $TestProcessIdentityUnavailableForPid -eq $numericProcessId) {
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }

    try {
        $process = [System.Diagnostics.Process]::GetProcessById($numericProcessId)
    } catch [System.ArgumentException] {
        return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
    } catch {
        # Failure to inspect a possibly elevated process is indeterminate and
        # must remain a live safety owner.
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }
    try {
        if ($process.HasExited) {
            return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
        }
    } catch {
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }

    try {
        $startUtc = $process.StartTime.ToUniversalTime()
        $startOffset = [DateTimeOffset]::new($startUtc)
        return [pscustomobject]@{
            Alive = $true
            StartTicks = $startUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)
            StartUnixMilliseconds = $startOffset.ToUnixTimeMilliseconds()
        }
    } catch {
        # Cross-elevation process metadata may be unavailable. A visible PID is
        # still treated as live, but it cannot prove an identity mismatch.
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }
}

function Set-EditorLeaseHandoff {
    param(
        [AllowEmptyString()][string]$SessionId,
        [int]$ProcessId,
        [AllowEmptyString()][string]$ProcessStartTicks
    )

    $hasSessionId = -not [string]::IsNullOrWhiteSpace($SessionId)
    $hasProcessId = $ProcessId -gt 0
    $hasProcessStartTicks = -not [string]::IsNullOrWhiteSpace($ProcessStartTicks)
    if (-not ($hasSessionId -or $hasProcessId -or $hasProcessStartTicks)) {
        $script:EditorLeaseHandoff = $null
        return
    }
    if (-not ($hasSessionId -and $hasProcessId -and $hasProcessStartTicks)) {
        Throw-MaterializerError `
            -Message "Editor lease handoff requires session id, process id, and process start ticks together." `
            -ExitCode 4
    }
    if ($SessionId -cnotmatch '^[A-Za-z0-9._-]{1,128}$') {
        Throw-MaterializerError -Message "Editor lease handoff session id is invalid." -ExitCode 4
    }
    if ($ProcessStartTicks -cnotmatch '^[0-9]+$') {
        Throw-MaterializerError -Message "Editor lease handoff process start ticks are invalid." -ExitCode 4
    }

    $identity = Get-MaterializerProcessIdentity -ProcessId $ProcessId
    if (-not $identity.Alive -or
        $null -eq $identity.StartTicks -or
        -not [string]::Equals(
            [string]$identity.StartTicks,
            $ProcessStartTicks,
            [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Editor lease handoff process identity is no longer valid." -ExitCode 4
    }
    $script:EditorLeaseHandoff = [pscustomobject]@{
        SessionId = $SessionId
        ProcessId = $ProcessId
        ProcessStartTicks = $ProcessStartTicks
    }
}

function Get-MaterializerLegacyLeaseProcessDisposition {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][DateTimeOffset]$LeaseCreatedAt
    )

    if (-not $ProcessIdentity.Alive) {
        return [pscustomobject]@{ State = "Stale"; Reason = "ProcessExited" }
    }
    if ($null -eq $ProcessIdentity.StartUnixMilliseconds) {
        return [pscustomobject]@{ State = "Indeterminate"; Reason = "ProcessIdentityUnavailable" }
    }

    $leaseCreatedMilliseconds = $LeaseCreatedAt.ToUnixTimeMilliseconds()
    if ([int64]$ProcessIdentity.StartUnixMilliseconds -gt $leaseCreatedMilliseconds) {
        return [pscustomobject]@{ State = "Stale"; Reason = "PidReused" }
    }
    return [pscustomobject]@{ State = "Live"; Reason = "ProcessPredatesLease" }
}

function Get-MaterializerWindowsProcessCommandIdentity {
    param([Parameter(Mandatory = $true)][int]$ProcessId)

    if ($ProcessId -le 0 -or [Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        return $null
    }
    try {
        $process = Get-CimInstance Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction Stop
        if ($null -eq $process -or [string]::IsNullOrWhiteSpace([string]$process.CommandLine)) {
            return $null
        }
        if ($null -eq ("RiceAICodeDB.WindowsCommandLine" -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace RiceAICodeDB
{
    public static class WindowsCommandLine
    {
        [DllImport("shell32.dll", SetLastError = true)]
        private static extern IntPtr CommandLineToArgvW(
            [MarshalAs(UnmanagedType.LPWStr)] string commandLine,
            out int argumentCount);

        [DllImport("kernel32.dll")]
        private static extern IntPtr LocalFree(IntPtr memory);

        public static string[] Parse(string commandLine)
        {
            int argumentCount;
            IntPtr argumentVector = CommandLineToArgvW(commandLine, out argumentCount);
            if (argumentVector == IntPtr.Zero)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            try
            {
                string[] arguments = new string[argumentCount];
                for (int index = 0; index < argumentCount; index++)
                {
                    IntPtr argument = Marshal.ReadIntPtr(argumentVector, index * IntPtr.Size);
                    arguments[index] = Marshal.PtrToStringUni(argument);
                }
                return arguments;
            }
            finally
            {
                LocalFree(argumentVector);
            }
        }
    }
}
'@
        }
        $arguments = [RiceAICodeDB.WindowsCommandLine]::Parse([string]$process.CommandLine)
        if ($arguments.Count -eq 0) {
            return $null
        }
        return [pscustomobject]@{
            ExecutablePath = [string]$process.ExecutablePath
            CommandLine = [string]$process.CommandLine
            Arguments = [string[]]$arguments
        }
    } catch {
        # An uninspectable live process cannot prove immutable-generation ownership.
        return $null
    }
}

function Test-MaterializerProcessExecutableIdentity {
    param([Parameter(Mandatory = $true)]$ProcessIdentity)

    if ([string]::IsNullOrWhiteSpace([string]$ProcessIdentity.ExecutablePath) -or
        $null -eq $ProcessIdentity.Arguments -or $ProcessIdentity.Arguments.Count -eq 0) {
        return $false
    }
    try {
        $executablePath = [System.IO.Path]::GetFullPath([string]$ProcessIdentity.ExecutablePath)
        $commandExecutable = [string]$ProcessIdentity.Arguments[0]
        if ([System.IO.Path]::IsPathRooted($commandExecutable)) {
            return [string]::Equals(
                [System.IO.Path]::GetFullPath($commandExecutable),
                $executablePath,
                [StringComparison]::OrdinalIgnoreCase)
        }
        return [string]::Equals(
            [System.IO.Path]::GetFileName($commandExecutable),
            [System.IO.Path]::GetFileName($executablePath),
            [StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    }
}

function Test-MaterializerArgumentPathIdentity {
    param(
        [AllowNull()][string]$Actual,
        [Parameter(Mandatory = $true)][string]$Expected
    )

    if ([string]::IsNullOrWhiteSpace($Actual)) { return $false }
    try {
        return [string]::Equals(
            [System.IO.Path]::GetFullPath($Actual),
            [System.IO.Path]::GetFullPath($Expected),
            [StringComparison]::OrdinalIgnoreCase)
    } catch {
        return $false
    }
}

function Get-MaterializerExactOptionMap {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][int]$StartIndex,
        [Parameter(Mandatory = $true)][string[]]$AllowedOptions
    )

    if ($StartIndex -lt 0 -or $StartIndex -gt $Arguments.Count -or
        (($Arguments.Count - $StartIndex) % 2) -ne 0) {
        return $null
    }
    $allowed = @{}
    foreach ($option in $AllowedOptions) { $allowed[$option] = $true }
    $result = @{}
    for ($index = $StartIndex; $index -lt $Arguments.Count; $index += 2) {
        $option = [string]$Arguments[$index]
        if (-not $allowed.ContainsKey($option) -or $result.ContainsKey($option)) {
            return $null
        }
        $result[$option] = [string]$Arguments[$index + 1]
    }
    return $result
}

function Test-MaterializerExactGenerationCoordinatorCommand {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][string]$CoordinatorPath,
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Runtime,
        [Parameter(Mandatory = $true)][string]$ProviderExecutable,
        [Parameter(Mandatory = $true)][string]$ProviderConfig,
        [Parameter(Mandatory = $true)][string]$LifecycleId,
        [Parameter(Mandatory = $true)][bool]$ExclusiveLifecycle,
        [Parameter(Mandatory = $true)][string]$AdapterBuilder,
        [Parameter(Mandatory = $true)][string]$AdapterWorker,
        [Parameter(Mandatory = $true)][string]$AdapterManifest
    )

    $arguments = [string[]]$ProcessIdentity.Arguments
    if (-not (Test-MaterializerProcessExecutableIdentity -ProcessIdentity $ProcessIdentity) -or
        $arguments.Count -lt 3 -or
        -not (Test-MaterializerArgumentPathIdentity -Actual $arguments[1] -Expected $CoordinatorPath) -or
        -not [string]::Equals($arguments[2], "daemon", [StringComparison]::Ordinal)) {
        return $false
    }
    $requiredOptions = @(
        "--generation-id", "--root", "--provider", "--config", "--runtime", "--lifecycle-id",
        "--require-new", "--exclusive-lifecycle", "--startup-timeout-ms", "--adapter-builder",
        "--adapter-manifest", "--adapter-debounce-ms", "--adapter-worker"
    )
    $options = Get-MaterializerExactOptionMap -Arguments $arguments -StartIndex 3 -AllowedOptions $requiredOptions
    if ($null -eq $options -or $options.Count -ne $requiredOptions.Count) { return $false }
    foreach ($requiredOption in $requiredOptions) {
        if (-not $options.ContainsKey($requiredOption)) { return $false }
    }
    [int]$startupTimeout = 0
    [int]$adapterDebounce = 0
    return [string]::Equals($options["--generation-id"], $GenerationId, [StringComparison]::Ordinal) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--root"] -Expected $ProjectRoot) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--provider"] -Expected $ProviderExecutable) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--config"] -Expected $ProviderConfig) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--runtime"] -Expected $Runtime) -and
        [string]::Equals($options["--lifecycle-id"], $LifecycleId, [StringComparison]::Ordinal) -and
        $options["--require-new"] -in @("true", "false") -and
        [string]::Equals($options["--exclusive-lifecycle"], $ExclusiveLifecycle.ToString().ToLowerInvariant(), [StringComparison]::Ordinal) -and
        [int]::TryParse($options["--startup-timeout-ms"], [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$startupTimeout) -and
        $startupTimeout -ge 1 -and $startupTimeout -le 120000 -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--adapter-builder"] -Expected $AdapterBuilder) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--adapter-worker"] -Expected $AdapterWorker) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--adapter-manifest"] -Expected $AdapterManifest) -and
        [int]::TryParse($options["--adapter-debounce-ms"], [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$adapterDebounce) -and
        $adapterDebounce -ge 1 -and $adapterDebounce -le 60000
}

function Test-MaterializerExactLegacyCoordinatorCommand {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][string]$CoordinatorPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Runtime,
        [Parameter(Mandatory = $true)][string]$ProviderExecutable,
        [Parameter(Mandatory = $true)][string]$ProviderConfig,
        [Parameter(Mandatory = $true)][string]$LifecycleId,
        [Parameter(Mandatory = $true)][bool]$ExclusiveLifecycle,
        [Parameter(Mandatory = $true)][string]$AdapterBuilder,
        [Parameter(Mandatory = $true)][string]$AdapterWorker,
        [Parameter(Mandatory = $true)][string]$AdapterManifest
    )

    $arguments = [string[]]$ProcessIdentity.Arguments
    if (-not (Test-MaterializerProcessExecutableIdentity -ProcessIdentity $ProcessIdentity) -or
        $arguments.Count -lt 3 -or
        -not (Test-MaterializerArgumentPathIdentity -Actual $arguments[1] -Expected $CoordinatorPath) -or
        -not [string]::Equals($arguments[2], "daemon", [StringComparison]::Ordinal)) {
        return $false
    }
    $requiredOptions = @(
        "--root", "--provider", "--config", "--runtime", "--lifecycle-id", "--require-new",
        "--exclusive-lifecycle", "--startup-timeout-ms", "--adapter-builder", "--adapter-manifest",
        "--adapter-debounce-ms", "--adapter-worker"
    )
    $options = Get-MaterializerExactOptionMap -Arguments $arguments -StartIndex 3 -AllowedOptions $requiredOptions
    if ($null -eq $options -or $options.Count -ne $requiredOptions.Count) { return $false }
    foreach ($requiredOption in $requiredOptions) {
        if (-not $options.ContainsKey($requiredOption)) { return $false }
    }
    [int]$startupTimeout = 0
    [int]$adapterDebounce = 0
    return (Test-MaterializerArgumentPathIdentity -Actual $options["--root"] -Expected $ProjectRoot) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--provider"] -Expected $ProviderExecutable) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--config"] -Expected $ProviderConfig) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--runtime"] -Expected $Runtime) -and
        [string]::Equals($options["--lifecycle-id"], $LifecycleId, [StringComparison]::Ordinal) -and
        @("true", "false") -ccontains $options["--require-new"] -and
        [string]::Equals($options["--exclusive-lifecycle"], $ExclusiveLifecycle.ToString().ToLowerInvariant(), [StringComparison]::Ordinal) -and
        [int]::TryParse($options["--startup-timeout-ms"], [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$startupTimeout) -and
        $startupTimeout -ge 1 -and $startupTimeout -le 120000 -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--adapter-builder"] -Expected $AdapterBuilder) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--adapter-worker"] -Expected $AdapterWorker) -and
        (Test-MaterializerArgumentPathIdentity -Actual $options["--adapter-manifest"] -Expected $AdapterManifest) -and
        [int]::TryParse($options["--adapter-debounce-ms"], [Globalization.NumberStyles]::None, [Globalization.CultureInfo]::InvariantCulture, [ref]$adapterDebounce) -and
        $adapterDebounce -ge 1 -and $adapterDebounce -le 60000
}

function Test-MaterializerExactProviderCommand {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][string]$ProviderExecutable,
        [Parameter(Mandatory = $true)][string]$ProviderConfig,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $arguments = [string[]]$ProcessIdentity.Arguments
    return (Test-MaterializerProcessExecutableIdentity -ProcessIdentity $ProcessIdentity) -and
        (Test-MaterializerArgumentPathIdentity -Actual $ProcessIdentity.ExecutablePath -Expected $ProviderExecutable) -and
        $arguments.Count -eq 5 -and
        [string]::Equals($arguments[1], "--config", [StringComparison]::Ordinal) -and
        (Test-MaterializerArgumentPathIdentity -Actual $arguments[2] -Expected $ProviderConfig) -and
        [string]::Equals($arguments[3], "mcp", [StringComparison]::Ordinal) -and
        (Test-MaterializerArgumentPathIdentity -Actual $arguments[4] -Expected $ProjectRoot)
}

function Test-MaterializerExactAdapterCommand {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][ValidateSet("Worker", "Builder")][string]$Kind,
        [Parameter(Mandatory = $true)][string]$BuilderPath,
        [AllowNull()][string]$WorkerPath
    )

    $arguments = [string[]]$ProcessIdentity.Arguments
    if (-not (Test-MaterializerProcessExecutableIdentity -ProcessIdentity $ProcessIdentity) -or
        [System.IO.Path]::GetFileName($ProcessIdentity.ExecutablePath) -notin @("powershell.exe", "pwsh.exe")) {
        return $false
    }
    if ($Kind -eq "Worker") {
        return $arguments.Count -eq 10 -and
            [string]::Equals($arguments[1], "-NoProfile", [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($arguments[2], "-NonInteractive", [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($arguments[3], "-NoLogo", [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($arguments[4], "-ExecutionPolicy", [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($arguments[5], "Bypass", [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($arguments[6], "-File", [StringComparison]::OrdinalIgnoreCase) -and
            (Test-MaterializerArgumentPathIdentity -Actual $arguments[7] -Expected $WorkerPath) -and
            [string]::Equals($arguments[8], "-BuilderPath", [StringComparison]::OrdinalIgnoreCase) -and
            (Test-MaterializerArgumentPathIdentity -Actual $arguments[9] -Expected $BuilderPath)
    }
    return $arguments.Count -eq 8 -and
        [string]::Equals($arguments[1], "-NoProfile", [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals($arguments[2], "-ExecutionPolicy", [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals($arguments[3], "Bypass", [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals($arguments[4], "-File", [StringComparison]::OrdinalIgnoreCase) -and
        (Test-MaterializerArgumentPathIdentity -Actual $arguments[5] -Expected $BuilderPath) -and
        [string]::Equals($arguments[6], "-Reason", [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals($arguments[7], "Automatic", [StringComparison]::OrdinalIgnoreCase)
}

function Get-MaterializerAuthenticatedCoordinatorStatus {
    param(
        [Parameter(Mandatory = $true)][string]$PipeName,
        [Parameter(Mandatory = $true)][string]$AuthToken,
        [ValidateRange(100, 5000)][int]$TimeoutMilliseconds = 1500,
        [AllowNull()][ref]$Failure
    )

    $prefix = "\\.\pipe\"
    if (-not $PipeName.StartsWith($prefix, [StringComparison]::Ordinal) -or
        $PipeName.Length -le $prefix.Length) {
        if ($null -ne $Failure) { $Failure.Value = "pipe name is outside the authenticated coordinator namespace" }
        return $null
    }
    $pipeLeaf = $PipeName.Substring($prefix.Length)
    if ($pipeLeaf -notmatch '^[A-Za-z0-9._-]{1,128}$') {
        if ($null -ne $Failure) { $Failure.Value = "pipe leaf is invalid" }
        return $null
    }

    $pipe = $null
    $responseStream = $null
    try {
        $pipe = [System.IO.Pipes.NamedPipeClientStream]::new(
            ".",
            $pipeLeaf,
            [System.IO.Pipes.PipeDirection]::InOut,
            [System.IO.Pipes.PipeOptions]::Asynchronous)
        $pipe.Connect($TimeoutMilliseconds)
        $pipe.ReadMode = [System.IO.Pipes.PipeTransmissionMode]::Byte
        $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
        $request = ([ordered]@{ auth_token = $AuthToken; command = "status" } | ConvertTo-Json -Compress) + "`n"
        $requestBytes = [System.Text.UTF8Encoding]::new($false, $true).GetBytes($request)
        $remaining = [Math]::Max(1, [int]($deadline - [DateTime]::UtcNow).TotalMilliseconds)
        $writeTask = $pipe.WriteAsync($requestBytes, 0, $requestBytes.Length)
        if (-not $writeTask.Wait($remaining)) {
            throw "Authenticated coordinator status request timed out while writing."
        }
        $null = $writeTask.GetAwaiter().GetResult()

        $responseStream = [System.IO.MemoryStream]::new()
        $buffer = New-Object byte[] 4096
        $complete = $false
        while (-not $complete) {
            $remaining = [Math]::Max(0, [int]($deadline - [DateTime]::UtcNow).TotalMilliseconds)
            if ($remaining -le 0) {
                throw "Authenticated coordinator status response timed out."
            }
            $readTask = $pipe.ReadAsync($buffer, 0, $buffer.Length)
            if (-not $readTask.Wait($remaining)) {
                throw "Authenticated coordinator status response timed out."
            }
            $readCount = $readTask.GetAwaiter().GetResult()
            if ($readCount -le 0) {
                throw "Authenticated coordinator status response ended before one JSON line."
            }
            for ($index = 0; $index -lt $readCount; $index++) {
                if ($buffer[$index] -eq 0x0A) {
                    $complete = $true
                    break
                }
                if ($responseStream.Length -ge (64 * 1024)) {
                    throw "Authenticated coordinator status response exceeded 64 KiB."
                }
                $responseStream.WriteByte($buffer[$index])
            }
        }

        $responseBytes = $responseStream.ToArray()
        if ($responseBytes.Length -gt 0 -and $responseBytes[$responseBytes.Length - 1] -eq 0x0D) {
            $responseBytes = $responseBytes[0..($responseBytes.Length - 2)]
        }
        if ($responseBytes.Length -eq 0 -or
            ($responseBytes.Length -ge 3 -and $responseBytes[0] -eq 0xEF -and $responseBytes[1] -eq 0xBB -and $responseBytes[2] -eq 0xBF)) {
            if ($null -ne $Failure) { $Failure.Value = "coordinator status response is empty or contains a UTF-8 BOM" }
            return $null
        }
        $line = [System.Text.UTF8Encoding]::new($false, $true).GetString($responseBytes)
        $response = ConvertFrom-StrictJsonText -Text $line -Label "authenticated coordinator response"
        if ((Get-RequiredJsonBoolean -Object $response -Name "ok" -Label "authenticated coordinator response") -ne $true) {
            if ($null -ne $Failure) { $Failure.Value = "coordinator rejected authenticated status" }
            return $null
        }
        $status = Get-RequiredJsonPropertyValue -Object $response -Name "status" -Label "authenticated coordinator response"
        if ($status.GetType() -ne [System.Management.Automation.PSCustomObject]) {
            if ($null -ne $Failure) { $Failure.Value = "coordinator status is not a JSON object" }
            return $null
        }
        return $status
    } catch {
        if ($null -ne $Failure) { $Failure.Value = $_.Exception.Message }
        return $null
    } finally {
        if ($null -ne $responseStream) { $responseStream.Dispose() }
        if ($null -ne $pipe) { $pipe.Dispose() }
    }
}

function Test-MaterializerCoordinatorStatusIdentity {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)]$Status,
        [AllowNull()][ref]$Failure
    )

    try {
        if ($Status.GetType() -ne [System.Management.Automation.PSCustomObject]) {
            throw "authenticated coordinator status must be a JSON object."
        }
        foreach ($field in @("schema_version", "coordinator_pid", "provider_pid")) {
            if ((Get-RequiredJsonInt32 -Object $Status -Name $field -Label "authenticated coordinator status") -ne
                (Get-RequiredJsonInt32 -Object $State -Name $field -Label "generation coordinator state")) {
                if ($null -ne $Failure) { $Failure.Value = "$field mismatch" }
                return $false
            }
        }
        foreach ($field in @("generation_id", "lifecycle_id")) {
            if (-not [string]::Equals(
                (Get-RequiredJsonString -Object $Status -Name $field -Label "authenticated coordinator status"),
                (Get-RequiredJsonString -Object $State -Name $field -Label "generation coordinator state"),
                [StringComparison]::Ordinal)) {
                if ($null -ne $Failure) { $Failure.Value = "$field mismatch" }
                return $false
            }
        }
        foreach ($field in @("exclusive_lifecycle", "adapter_enabled")) {
            $statusValue = Get-RequiredJsonBoolean -Object $Status -Name $field -Label "authenticated coordinator status"
            $stateValue = Get-RequiredJsonBoolean -Object $State -Name $field -Label "generation coordinator state"
            if ($statusValue -ne $stateValue) {
                if ($null -ne $Failure) { $Failure.Value = "$field mismatch" }
                return $false
            }
        }
        foreach ($field in @("adapter_worker_pid", "adapter_build_pid")) {
            $statusValue = Get-RequiredJsonNullableInt32 -Object $Status -Name $field -Label "authenticated coordinator status"
            $stateValue = Get-RequiredJsonNullableInt32 -Object $State -Name $field -Label "generation coordinator state"
            if ($statusValue -ne $stateValue) {
                if ($null -ne $Failure) { $Failure.Value = "$field changed while status was read" }
                return $false
            }
        }
        foreach ($field in @(
            "root", "runtime", "provider_executable", "provider_config", "adapter_builder", "adapter_worker",
            "generation_adapter_builder", "generation_adapter_worker", "adapter_manifest"
        )) {
            $statusPath = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $Status -Name $field -Label "authenticated coordinator status"))
            $statePath = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $State -Name $field -Label "generation coordinator state"))
            if (-not [string]::Equals($statusPath, $statePath, [StringComparison]::OrdinalIgnoreCase)) {
                if ($null -ne $Failure) { $Failure.Value = "$field mismatch" }
                return $false
            }
        }
        $adapterState = Get-RequiredJsonString -Object $Status -Name "adapter_state" -Label "authenticated coordinator status"
        if ((Get-RequiredJsonInt32 -Object $Status -Name "schema_version" -Label "authenticated coordinator status") -ne 2) {
            if ($null -ne $Failure) { $Failure.Value = "unsupported status schema" }
            return $false
        }
        if (-not [string]::Equals((Get-RequiredJsonString -Object $Status -Name "provider_state" -Label "authenticated coordinator status"), "ready", [StringComparison]::Ordinal)) {
            if ($null -ne $Failure) { $Failure.Value = "Provider is not ready" }
            return $false
        }
        if (-not [string]::Equals((Get-RequiredJsonString -Object $Status -Name "adapter_worker_state" -Label "authenticated coordinator status"), "ready", [StringComparison]::Ordinal)) {
            if ($null -ne $Failure) { $Failure.Value = "adapter worker is not ready" }
            return $false
        }
        if (-not (@("watching", "pending", "building") -ccontains $adapterState)) {
            if ($null -ne $Failure) { $Failure.Value = "adapter state is not operational" }
            return $false
        }
        return $true
    } catch {
        if ($null -ne $Failure) { $Failure.Value = $_.Exception.Message }
        return $false
    }
}

function Test-MaterializerLegacyCoordinatorStatusIdentity {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)]$Status
    )

    try {
        foreach ($field in @("schema_version", "coordinator_pid", "provider_pid")) {
            if ((Get-RequiredJsonInt32 -Object $Status -Name $field -Label "authenticated legacy coordinator status") -ne
                (Get-RequiredJsonInt32 -Object $State -Name $field -Label "legacy coordinator state")) {
                return $false
            }
        }
        foreach ($field in @("lifecycle_id")) {
            if (-not [string]::Equals(
                (Get-RequiredJsonString -Object $Status -Name $field -Label "authenticated legacy coordinator status"),
                (Get-RequiredJsonString -Object $State -Name $field -Label "legacy coordinator state"),
                [StringComparison]::Ordinal)) {
                return $false
            }
        }
        foreach ($field in @("exclusive_lifecycle", "adapter_enabled")) {
            if ((Get-RequiredJsonBoolean -Object $Status -Name $field -Label "authenticated legacy coordinator status") -ne
                (Get-RequiredJsonBoolean -Object $State -Name $field -Label "legacy coordinator state")) {
                return $false
            }
        }
        foreach ($field in @("adapter_worker_pid", "adapter_build_pid")) {
            if ((Get-RequiredJsonNullableInt32 -Object $Status -Name $field -Label "authenticated legacy coordinator status") -ne
                (Get-RequiredJsonNullableInt32 -Object $State -Name $field -Label "legacy coordinator state")) {
                return $false
            }
        }
        foreach ($field in @(
            "root", "runtime", "provider_executable", "provider_config", "adapter_builder", "adapter_worker", "adapter_manifest"
        )) {
            $statusPath = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $Status -Name $field -Label "authenticated legacy coordinator status"))
            $statePath = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $State -Name $field -Label "legacy coordinator state"))
            if (-not [string]::Equals($statusPath, $statePath, [StringComparison]::OrdinalIgnoreCase)) {
                return $false
            }
        }
        $adapterState = Get-RequiredJsonString -Object $Status -Name "adapter_state" -Label "authenticated legacy coordinator status"
        return (Get-RequiredJsonInt32 -Object $Status -Name "schema_version" -Label "authenticated legacy coordinator status") -eq 1 -and
            [string]::Equals((Get-RequiredJsonString -Object $Status -Name "provider_state" -Label "authenticated legacy coordinator status"), "ready", [StringComparison]::Ordinal) -and
            [string]::Equals((Get-RequiredJsonString -Object $Status -Name "adapter_worker_state" -Label "authenticated legacy coordinator status"), "ready", [StringComparison]::Ordinal) -and
            @("watching", "pending", "building") -ccontains $adapterState
    } catch {
        return $false
    }
}

function Test-MaterializerGenerationProcessIdentity {
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

function Get-MaterializerHostUseLeaseReport {
    param(
        [Parameter(Mandatory = $true)][string]$LeaseRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $liveLeases = New-Object System.Collections.Generic.List[string]
    $liveLeaseDetails = New-Object System.Collections.Generic.List[object]
    $staleLeases = New-Object System.Collections.Generic.List[object]
    $invalidLeases = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $LeaseRoot)) {
        return [pscustomobject]@{
            Live = $liveLeases.ToArray()
            LiveDetails = $liveLeaseDetails.ToArray()
            Stale = $staleLeases.ToArray()
            Invalid = $invalidLeases.ToArray()
        }
    }
    if (-not (Test-Path -LiteralPath $LeaseRoot -PathType Container)) {
        $invalidLeases.Add($LeaseRoot)
        return [pscustomobject]@{
            Live = $liveLeases.ToArray()
            LiveDetails = $liveLeaseDetails.ToArray()
            Stale = $staleLeases.ToArray()
            Invalid = $invalidLeases.ToArray()
        }
    }

    Assert-NoReparsePoint -Path $LeaseRoot -Root $ProjectRoot -Label "host-use lease root"
    foreach ($item in @(Get-ChildItem -LiteralPath $LeaseRoot -Force | Sort-Object Name)) {
        $nameMatch = [regex]::Match($item.Name, '^(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json$')
        if ($item.PSIsContainer -or -not $nameMatch.Success) {
            $invalidLeases.Add($item.FullName)
            continue
        }

        $fileOwner = $nameMatch.Groups[1].Value
        $fileProcessId = [int]$nameMatch.Groups[2].Value
        $fileToken = $nameMatch.Groups[3].Value
        try {
            Assert-NoReparsePoint -Path $item.FullName -Root $LeaseRoot -Label "host-use lease"
            $lease = (Read-BoundedJsonDocument -Path $item.FullName -Label "host-use lease" -MaximumBytes (64 * 1024)).Document
            $owner = Get-RequiredJsonString -Object $lease -Name "owner" -Label "host-use lease"
            $processId = Get-RequiredJsonInt32 -Object $lease -Name "pid" -Label "host-use lease"
            $leaseId = Get-RequiredJsonString -Object $lease -Name "lease_id" -Label "host-use lease"
            $projectRootValue = Get-RequiredJsonString -Object $lease -Name "project_root" -Label "host-use lease"
            $createdAtText = Get-RequiredJsonString -Object $lease -Name "created_at_utc" -Label "host-use lease"
            [DateTimeOffset]$createdAt = [DateTimeOffset]::MinValue
            $valid = (Get-RequiredJsonInt32 -Object $lease -Name "schema_version" -Label "host-use lease") -eq 1 -and
                (Get-RequiredJsonInt32 -Object $lease -Name "host_use_gate_version" -Label "host-use lease") -eq $script:HostUseGateVersion -and
                [string]::Equals((Get-RequiredJsonString -Object $lease -Name "managed_by" -Label "host-use lease"), $script:ManagedBy, [StringComparison]::Ordinal) -and
                [string]::Equals($owner, $fileOwner, [StringComparison]::Ordinal) -and
                $processId -eq $fileProcessId -and
                [string]::Equals($leaseId, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                [string]::Equals($leaseId, "$fileOwner-$fileProcessId-$fileToken", [StringComparison]::Ordinal) -and
                [string]::Equals(
                    [System.IO.Path]::GetFullPath($projectRootValue),
                    [System.IO.Path]::GetFullPath($ProjectRoot),
                    [StringComparison]::OrdinalIgnoreCase) -and
                [DateTimeOffset]::TryParse(
                    $createdAtText,
                    [Globalization.CultureInfo]::InvariantCulture,
                    [Globalization.DateTimeStyles]::RoundtripKind,
                    [ref]$createdAt)
        } catch {
            $valid = $false
        }
        if (-not $valid) {
            $invalidLeases.Add($item.FullName)
            continue
        }

        $processIdentity = Get-MaterializerProcessIdentity -ProcessId $processId
        $disposition = Get-MaterializerLegacyLeaseProcessDisposition `
            -ProcessIdentity $processIdentity `
            -LeaseCreatedAt $createdAt
        if (-not [string]::Equals($disposition.State, "Stale", [StringComparison]::Ordinal)) {
            $liveLeases.Add("$owner PID $processId")
            $liveLeaseDetails.Add([pscustomobject]@{
                Owner = $owner
                ProcessId = $processId
                Path = $item.FullName
                ProcessIdentityState = $disposition.State
                ProcessIdentityReason = $disposition.Reason
            })
        } else {
            $staleLeases.Add([pscustomobject]@{
                Owner = $owner
                ProcessId = $processId
                Path = $item.FullName
                Reason = $disposition.Reason
            })
        }
    }

    return [pscustomobject]@{
        Live = $liveLeases.ToArray()
        LiveDetails = $liveLeaseDetails.ToArray()
        Stale = $staleLeases.ToArray()
        Invalid = $invalidLeases.ToArray()
    }
}

function Get-MaterializerGenerationLeaseReport {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $liveLeases = New-Object System.Collections.Generic.List[string]
    $liveLeaseDetails = New-Object System.Collections.Generic.List[object]
    $staleLeases = New-Object System.Collections.Generic.List[object]
    $invalidLeases = New-Object System.Collections.Generic.List[string]
    $leasesRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:GenerationLeaseRelativePath -Label "generation lease root"
    if (-not (Test-Path -LiteralPath $leasesRoot)) {
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); LiveDetails = $liveLeaseDetails.ToArray(); Stale = $staleLeases.ToArray(); Invalid = $invalidLeases.ToArray() }
    }
    if (-not (Test-Path -LiteralPath $leasesRoot -PathType Container)) {
        $invalidLeases.Add($leasesRoot)
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); LiveDetails = $liveLeaseDetails.ToArray(); Stale = $staleLeases.ToArray(); Invalid = $invalidLeases.ToArray() }
    }

    Assert-NoReparsePoint -Path $leasesRoot -Root $ProjectRoot -Label "generation lease root"
    $now = [DateTime]::UtcNow
    foreach ($generationDirectory in @(Get-ChildItem -LiteralPath $leasesRoot -Force)) {
        if (-not $generationDirectory.PSIsContainer -or $generationDirectory.Name -notmatch '^[A-Za-z0-9._-]{1,64}$') {
            $invalidLeases.Add($generationDirectory.FullName)
            continue
        }
        Assert-NoReparsePoint -Path $generationDirectory.FullName -Root $leasesRoot -Label "generation lease directory"
        foreach ($item in @(Get-ChildItem -LiteralPath $generationDirectory.FullName -Force)) {
            $nameMatch = [regex]::Match($item.Name, '^(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json$')
            $temporaryNameMatch = [regex]::Match($item.Name, '^\.(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json\.([0-9]+)\.[0-9a-fA-F-]{36}\.tmp$')
            if (-not $item.PSIsContainer -and $temporaryNameMatch.Success) {
                try {
                    Assert-NoReparsePoint -Path $item.FullName -Root $generationDirectory.FullName -Label "generation lease temporary file"
                    if ($item.LastWriteTimeUtc -lt $now.AddMinutes(-5)) {
                        $staleLeases.Add([pscustomobject]@{
                            GenerationId = $generationDirectory.Name
                            Owner = "temporary"
                            ProcessId = [int]$temporaryNameMatch.Groups[4].Value
                            Path = $item.FullName
                        })
                    }
                } catch {
                    # A heartbeat may atomically rename the strictly named temp
                    # file after enumeration and before metadata is read.
                    if (Test-Path -LiteralPath $item.FullName) {
                        $invalidLeases.Add($item.FullName)
                    }
                }
                continue
            }
            if ($item.PSIsContainer -or -not $nameMatch.Success) {
                $invalidLeases.Add($item.FullName)
                continue
            }
            try {
                Assert-NoReparsePoint -Path $item.FullName -Root $generationDirectory.FullName -Label "generation lease"
                $lease = (Read-BoundedJsonDocument -Path $item.FullName -Label "generation lease" -MaximumBytes (64 * 1024)).Document
                $owner = Get-RequiredJsonString -Object $lease -Name "owner" -Label "generation lease"
                $processId = Get-RequiredJsonInt32 -Object $lease -Name "pid" -Label "generation lease"
                $generationId = Get-RequiredJsonString -Object $lease -Name "generation_id" -Label "generation lease"
                $heartbeatText = Get-RequiredJsonString -Object $lease -Name "heartbeat_at_utc" -Label "generation lease"
                [DateTimeOffset]$heartbeat = [DateTimeOffset]::MinValue
                $leaseProcessStartIdentity = Get-RequiredJsonString -Object $lease -Name "process_start_identity" -Label "generation lease"
                $leaseId = Get-RequiredJsonString -Object $lease -Name "lease_id" -Label "generation lease"
                $leaseProjectRoot = Get-RequiredJsonString -Object $lease -Name "project_root" -Label "generation lease"
                $valid = (Get-RequiredJsonInt32 -Object $lease -Name "schema_version" -Label "generation lease") -eq 2 -and
                    (Get-RequiredJsonInt32 -Object $lease -Name "generation_lease_version" -Label "generation lease") -eq 2 -and
                    [string]::Equals((Get-RequiredJsonString -Object $lease -Name "managed_by" -Label "generation lease"), $script:ManagedBy, [StringComparison]::Ordinal) -and
                    [string]::Equals($generationId, $generationDirectory.Name, [StringComparison]::Ordinal) -and
                    [string]::Equals($owner, $nameMatch.Groups[1].Value, [StringComparison]::Ordinal) -and
                    $processId -eq [int]$nameMatch.Groups[2].Value -and
                    [string]::Equals($leaseId, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                    $leaseProcessStartIdentity -match '^[0-9]{1,20}$' -and
                    [string]::Equals([System.IO.Path]::GetFullPath($leaseProjectRoot), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
                    [DateTimeOffset]::TryParse(
                        $heartbeatText,
                        [Globalization.CultureInfo]::InvariantCulture,
                        [Globalization.DateTimeStyles]::RoundtripKind,
                        [ref]$heartbeat) -and
                    $heartbeat.UtcDateTime -le $now.AddSeconds(30)
            } catch {
                $valid = $false
            }
            if (-not $valid) {
                $invalidLeases.Add($item.FullName)
                continue
            }

            $processIdentity = Get-MaterializerProcessIdentity -ProcessId $processId
            $identityMatches = Test-MaterializerGenerationProcessIdentity -ProcessIdentity $processIdentity -LeaseIdentity $leaseProcessStartIdentity
            if ($processIdentity.Alive -and ($null -eq $identityMatches -or $identityMatches)) {
                $liveLeases.Add("generation $generationId $owner PID $processId")
                $liveLeaseDetails.Add([pscustomobject]@{
                    GenerationId = $generationId
                    Owner = $owner
                    ProcessId = $processId
                    Path = $item.FullName
                })
            } else {
                $staleLeases.Add([pscustomobject]@{
                    GenerationId = $generationId
                    Owner = $owner
                    ProcessId = $processId
                    Path = $item.FullName
                })
            }
        }
    }
    return [pscustomobject]@{ Live = $liveLeases.ToArray(); LiveDetails = $liveLeaseDetails.ToArray(); Stale = $staleLeases.ToArray(); Invalid = $invalidLeases.ToArray() }
}

function Write-HostUseLeaseGuidance {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $runtimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
    $leaseRoot = Join-Path $runtimeRoot $script:HostUseLeaseDirectoryName
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    foreach ($path in $report.Invalid) {
        Write-Host "[BLOCKED] Host-use lease requires manual review: $path"
    }
    foreach ($lease in $report.Live) {
        Write-Host "[ACTIVE] $lease"
    }
    foreach ($path in $generationReport.Invalid) {
        Write-Host "[BLOCKED] Generation lease requires manual review: $path"
    }
    foreach ($lease in $generationReport.Live) {
        Write-Host "[ACTIVE] $lease"
    }
    if ($report.Live.Count -gt 0 -or $generationReport.Live.Count -gt 0) {
        Write-Host "[BLOCKED] Host payload Sync/Remove is blocked while CodeDB host tooling is active. Pause the watcher and disconnect project MCP sessions first."
    }
    foreach ($lease in $report.Stale) {
        Write-Host "[STALE-LEASE] $($lease.Owner) PID $($lease.ProcessId) will be reclaimed by the next authorized mutation."
    }
    foreach ($lease in $generationReport.Stale) {
        Write-Host "[STALE-LEASE] generation $($lease.GenerationId) $($lease.Owner) PID $($lease.ProcessId) will be reclaimed by the next authorized mutation."
    }
}

function ConvertTo-MaterializerProjectSlug {
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
    $result = $builder.ToString().TrimEnd('-')
    if ([string]::IsNullOrWhiteSpace($result)) {
        $result = "unity-project"
    }
    $requiresHash = $containsNonAscii
    if ($result.Length -gt 96) {
        $result = $result.Substring(0, 96).TrimEnd('-')
        $requiresHash = $true
    }
    if ($requiresHash) {
        $hash = Get-TextSha256 -Text $normalizedValue
        $result = "$result-$($hash.Substring(0, 12))"
    }
    return $result
}

function Get-MaterializerProjectIdentity {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $canonicalRoot = [System.IO.Path]::GetFullPath($ProjectRoot).Replace('\', '/').TrimEnd('/').ToLowerInvariant()
    return "sha256:$(Get-TextSha256 -Text $canonicalRoot)"
}

function Get-ProjectIntegrationState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $statePath = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:IntegrationStateRelativePath `
        -Label "project integration desired state"
    Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "project integration desired state"
    if (-not (Test-Path -LiteralPath $statePath)) {
        return [pscustomobject]@{
            Path = $statePath
            Present = $false
            Uninstalled = $false
            DesiredState = $null
            StateId = $null
            CleanupState = $null
        }
    }
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        throw "Project integration desired state is not a regular file: $statePath"
    }

    $document = (Read-BoundedJsonDocument `
        -Path $statePath `
        -Label "project integration desired state" `
        -MaximumBytes (64 * 1024)).Document
    $schemaVersion = Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "project integration desired state"
    $managedBy = Get-RequiredJsonString -Object $document -Name "managed_by" -Label "project integration desired state"
    $desiredState = Get-RequiredJsonString -Object $document -Name "desired_state" -Label "project integration desired state"
    $recordedRoot = Get-RequiredJsonString -Object $document -Name "project_root" -Label "project integration desired state"
    $recordedIdentity = Get-RequiredJsonString -Object $document -Name "project_identity" -Label "project integration desired state"
    $stateId = Get-RequiredJsonString -Object $document -Name "state_id" -Label "project integration desired state"
    $cleanupState = Get-RequiredJsonString -Object $document -Name "cleanup_state" -Label "project integration desired state"
    $updatedAtText = Get-RequiredJsonString -Object $document -Name "updated_at_utc" -Label "project integration desired state"
    [DateTimeOffset]$updatedAt = [DateTimeOffset]::MinValue
    $expectedRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    try {
        $actualRoot = [System.IO.Path]::GetFullPath($recordedRoot).TrimEnd('\', '/')
    } catch {
        throw "Project integration desired state contains an invalid project root."
    }
    if ($schemaVersion -ne $script:IntegrationStateSchemaVersion -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals($desiredState, "UNINSTALLED", [StringComparison]::Ordinal) -or
        -not [string]::Equals($actualRoot, $expectedRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals($recordedIdentity, (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        $stateId -cnotmatch '^[0-9a-f]{32}$' -or
        $cleanupState -cnotin @("PENDING", "COMPLETE") -or
        -not [DateTimeOffset]::TryParse(
            $updatedAtText,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$updatedAt)) {
        throw "Project integration desired state identity or schema is invalid."
    }

    return [pscustomobject]@{
        Path = $statePath
        Present = $true
        Uninstalled = $true
        DesiredState = $desiredState
        StateId = $stateId
        CleanupState = $cleanupState
    }
}

function Assert-ProjectIntegrationStateId {
    param([Parameter(Mandatory = $true)][string]$StateId)

    if ($StateId -cnotmatch '^[0-9a-f]{32}$') {
        throw "Project integration state id is invalid."
    }
    return $StateId
}

function Assert-ProjectIntegrationStateMatch {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateId,
        [AllowNull()][string]$CleanupState
    )

    $null = Assert-ProjectIntegrationStateId -StateId $StateId
    $current = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
    if (-not $current.Uninstalled -or
        -not [string]::Equals([string]$current.StateId, $StateId, [StringComparison]::Ordinal) -or
        (-not [string]::IsNullOrWhiteSpace($CleanupState) -and
         -not [string]::Equals([string]$current.CleanupState, $CleanupState, [StringComparison]::Ordinal))) {
        throw "Project integration desired state changed while the operation was waiting to mutate the project."
    }
    return $current
}

function Write-ProjectIntegrationState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateId,
        [Parameter(Mandatory = $true)][ValidateSet("PENDING", "COMPLETE")][string]$CleanupState
    )

    $null = Assert-ProjectIntegrationStateId -StateId $StateId
    $statePath = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:IntegrationStateRelativePath `
        -Label "project integration desired state"
    $document = [ordered]@{
        schema_version = $script:IntegrationStateSchemaVersion
        managed_by = $script:ManagedBy
        desired_state = "UNINSTALLED"
        state_id = $StateId
        cleanup_state = $CleanupState
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    $stagePath = Join-Path $Lock.Root ("integration-state-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content (($document | ConvertTo-Json -Depth 6) + "`n")
        Publish-TransactionFile -StagePath $stagePath -TargetPath $statePath
        $published = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
        if (-not $published.Uninstalled -or
            -not [string]::Equals([string]$published.StateId, $StateId, [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$published.CleanupState, $CleanupState, [StringComparison]::Ordinal)) {
            throw "Project integration desired state publication failed verification."
        }
        Add-MaterializerMutationScope -Scope "desired_state"
        Invoke-TestFaultAfterMutation
        return $published
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Publish-ProjectIntegrationUninstalledState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateId
    )

    $null = Assert-ProjectIntegrationStateId -StateId $StateId
    $current = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
    if ($current.Uninstalled) {
        if (-not [string]::Equals([string]$current.StateId, $StateId, [StringComparison]::Ordinal)) {
            throw "Project integration desired state identity changed before Uninstall publication."
        }
        Write-Host "[PHASE DESIRED_STATE] CURRENT - project integration remains UNINSTALLED."
        return $current
    }

    $published = Write-ProjectIntegrationState `
        -Lock $Lock `
        -ProjectRoot $ProjectRoot `
        -StateId $StateId `
        -CleanupState "PENDING"
    Write-Host "[PHASE DESIRED_STATE] UNINSTALLED - automatic installation and watcher attachment are disabled."
    return $published
}

function Publish-ProjectIntegrationCleanupState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateId,
        [Parameter(Mandatory = $true)][ValidateSet("PENDING", "COMPLETE")][string]$CleanupState
    )

    $current = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $StateId
    if ([string]::Equals([string]$current.CleanupState, $CleanupState, [StringComparison]::Ordinal)) {
        return $current
    }
    return Write-ProjectIntegrationState `
        -Lock $Lock `
        -ProjectRoot $ProjectRoot `
        -StateId $StateId `
        -CleanupState $CleanupState
}

function Clear-ProjectIntegrationUninstalledState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StateId
    )

    $current = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $StateId
    Remove-Item -LiteralPath $current.Path -Force
    if (Test-Path -LiteralPath $current.Path) {
        throw "Project integration desired state remained after Install."
    }
    Add-MaterializerMutationScope -Scope "desired_state"
    Invoke-TestFaultAfterMutation
    Write-Host "[PHASE DESIRED_STATE] INSTALLED - the UNINSTALLED override was cleared."
    return $true
}

function Get-RepairMcpRegistrationContent {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $projectSlug = ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf ($ProjectRoot.TrimEnd('\', '/')))
    $providerSlug = "codedb-$projectSlug"
    return @(
        "[mcp_servers.$providerSlug]",
        'command = "node"',
        'cwd = "."',
        'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
        'startup_timeout_sec = 120'
    ) -join "`n"
}

function Skip-RepairTomlWhitespace {
    param([Parameter(Mandatory = $true)]$State)

    while ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -in @(' ', "`t")) {
        $State.Index++
    }
}

function Assert-RepairTomlCharacterSet {
    param([Parameter(Mandatory = $true)][string]$Text)

    $inBasicString = $false
    $inLiteralString = $false
    $inComment = $false
    $escaped = $false
    foreach ($character in $Text.ToCharArray()) {
        $codePoint = [int]$character
        if (($codePoint -lt 0x20 -and $character -notin @("`t", "`r", "`n")) -or $codePoint -eq 0x7f) {
            throw "Project MCP config contains an unsupported control character."
        }
        if ($character -eq "`r" -or $character -eq "`n") {
            $inComment = $false
            $escaped = $false
            continue
        }
        if ($inComment) { continue }
        if ($inBasicString) {
            if ($escaped) { $escaped = $false; continue }
            if ($character -eq '\') { $escaped = $true; continue }
            if ($character -eq '"') { $inBasicString = $false }
            continue
        }
        if ($inLiteralString) {
            if ($character -eq "'") { $inLiteralString = $false }
            continue
        }
        if ($character -eq '#') { $inComment = $true; continue }
        if ($character -eq '"') { $inBasicString = $true; continue }
        if ($character -eq "'") { $inLiteralString = $true; continue }
        if ([char]::IsWhiteSpace($character) -and $character -notin @(' ', "`t")) {
            throw "Project MCP config contains unsupported Unicode whitespace."
        }
    }
}

function Read-RepairTomlStringValue {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][char]$Quote,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $shortEscapes = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($shortEscape in @('"', '\', 'b', 't', 'n', 'f', 'r')) {
        $null = $shortEscapes.Add($shortEscape)
    }
    $State.Index++
    while ($State.Index -lt $State.Text.Length) {
        $character = $State.Text[$State.Index]
        if (([int]$character -lt 0x20 -and $character -ne "`t") -or [int]$character -eq 0x7f) {
            throw "Project MCP config contains an unsupported control character in a TOML string: $Line"
        }
        if ($character -eq $Quote) {
            $State.Index++
            return
        }
        if ($Quote -eq '"' -and $character -eq '\') {
            $State.Index++
            if ($State.Index -ge $State.Text.Length) {
                throw "Project MCP config has an incomplete TOML escape: $Line"
            }
            $escape = $State.Text[$State.Index]
            if ($shortEscapes.Contains([string]$escape)) {
                $State.Index++
                continue
            }
            $hexLength = if ($escape -ceq 'u') { 4 } elseif ($escape -ceq 'U') { 8 } else { 0 }
            if ($hexLength -eq 0 -or $State.Index + $hexLength -ge $State.Text.Length) {
                throw "Project MCP config contains an unsupported TOML escape: $Line"
            }
            $hex = $State.Text.Substring($State.Index + 1, $hexLength)
            if ($hex -cnotmatch "^[0-9A-Fa-f]{$hexLength}$") {
                throw "Project MCP config contains an invalid Unicode escape: $Line"
            }
            $codePoint = [Convert]::ToInt64($hex, 16)
            if ($codePoint -gt 0x10FFFF -or ($codePoint -ge 0xD800 -and $codePoint -le 0xDFFF)) {
                throw "Project MCP config contains an invalid Unicode scalar value: $Line"
            }
            $State.Index += $hexLength + 1
            continue
        }
        $State.Index++
    }
    throw "Project MCP config has an unclosed TOML string: $Line"
}

function Assert-RepairTomlIntegerFitsInt64 {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $normalized = $Token.Replace('_', '').ToLowerInvariant()
    $limit = $null
    if ($normalized -match '^[+-]?[0-9]+$') {
        $negative = $normalized.StartsWith('-', [StringComparison]::Ordinal)
        $digits = $normalized.TrimStart('+', '-').TrimStart('0')
        $limit = if ($negative) { '9223372036854775808' } else { '9223372036854775807' }
    } elseif ($normalized.StartsWith('0x', [StringComparison]::Ordinal)) {
        $digits = $normalized.Substring(2).TrimStart('0')
        $limit = '7fffffffffffffff'
    } elseif ($normalized.StartsWith('0o', [StringComparison]::Ordinal)) {
        $digits = $normalized.Substring(2).TrimStart('0')
        $limit = '777777777777777777777'
    } elseif ($normalized.StartsWith('0b', [StringComparison]::Ordinal)) {
        $digits = $normalized.Substring(2).TrimStart('0')
        $limit = '111111111111111111111111111111111111111111111111111111111111111'
    } else {
        throw "Project MCP config contains an unsupported or invalid bare TOML value: $Line"
    }
    if ($digits.Length -eq 0) { $digits = '0' }
    if ($digits.Length -gt $limit.Length -or
        ($digits.Length -eq $limit.Length -and [string]::CompareOrdinal($digits, $limit) -gt 0)) {
        throw "Project MCP config contains a TOML integer outside the signed 64-bit range: $Line"
    }
}

function Read-RepairTomlBareValue {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $start = $State.Index
    while ($State.Index -lt $State.Text.Length -and
        -not [char]::IsWhiteSpace($State.Text[$State.Index]) -and
        $State.Text[$State.Index] -notin @(',', ']', '}')) {
        $State.Index++
    }
    $token = $State.Text.Substring($start, $State.Index - $start)
    $decimalInteger = '^[+-]?(?:0|[1-9](?:_?[0-9])*)$'
    $basedInteger = '^(?:0x[0-9A-Fa-f](?:_?[0-9A-Fa-f])*|0o[0-7](?:_?[0-7])*|0b[01](?:_?[01])*)$'
    $decimalDigits = '(?:0|[1-9](?:_?[0-9])*)'
    $fractionDigits = '[0-9](?:_?[0-9])*'
    $float = "^[+-]?(?:(?:$decimalDigits\.$fractionDigits)(?:[eE][+-]?$fractionDigits)?|$decimalDigits[eE][+-]?$fractionDigits|inf|nan)$"
    if ($token -cnotmatch '^(?:true|false)$' -and
        $token -cnotmatch $decimalInteger -and
        $token -cnotmatch $basedInteger -and
        $token -cnotmatch $float) {
        throw "Project MCP config contains an unsupported or invalid bare TOML value: $Line"
    }
    if ($token -cmatch $decimalInteger -or $token -cmatch $basedInteger) {
        Assert-RepairTomlIntegerFitsInt64 -Token $token -Line $Line
    }
}

function Read-RepairTomlValue {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Line
    )

    Skip-RepairTomlWhitespace -State $State
    if ($State.Index -ge $State.Text.Length) {
        throw "Project MCP config has a missing TOML value: $Line"
    }
    $character = $State.Text[$State.Index]
    if ($character -eq '"' -or $character -eq "'") {
        Read-RepairTomlStringValue -State $State -Quote $character -Line $Line
        return
    }
    if ($character -eq '[') {
        $State.Index++
        Skip-RepairTomlWhitespace -State $State
        if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -eq ']') {
            $State.Index++
            return
        }
        while ($true) {
            Read-RepairTomlValue -State $State -Line $Line
            Skip-RepairTomlWhitespace -State $State
            if ($State.Index -ge $State.Text.Length) {
                throw "Project MCP config has an unclosed TOML array: $Line"
            }
            if ($State.Text[$State.Index] -eq ']') {
                $State.Index++
                return
            }
            if ($State.Text[$State.Index] -ne ',') {
                throw "Project MCP config has an invalid TOML array delimiter: $Line"
            }
            $State.Index++
            Skip-RepairTomlWhitespace -State $State
            if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -eq ']') {
                $State.Index++
                return
            }
        }
    }
    if ($character -eq '{') {
        $State.Index++
        Skip-RepairTomlWhitespace -State $State
        if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -eq '}') {
            $State.Index++
            return
        }
        $inlineValuePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        $inlineNamespacePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        while ($true) {
            $remaining = $State.Text.Substring($State.Index)
            if ($remaining -notmatch '^(?<key>[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*)\s*=') {
                throw "Project MCP config contains an unsupported or invalid inline-table key: $Line"
            }
            $inlineKey = [string]$Matches.key
            if ($inlineValuePaths.Contains($inlineKey)) {
                throw "Project MCP config contains a duplicate inline-table key: $inlineKey"
            }
            $inlineSegments = @($inlineKey.Split('.'))
            for ($segmentCount = 1; $segmentCount -lt $inlineSegments.Count; $segmentCount++) {
                $inlinePrefix = $inlineSegments[0..($segmentCount - 1)] -join '.'
                if ($inlineValuePaths.Contains($inlinePrefix)) {
                    throw "Project MCP config contains an inline-table namespace collision at $inlinePrefix."
                }
                $null = $inlineNamespacePaths.Add($inlinePrefix)
            }
            if ($inlineNamespacePaths.Contains($inlineKey) -or
                @($inlineValuePaths | Where-Object { $_.StartsWith($inlineKey + '.', [StringComparison]::Ordinal) }).Count -gt 0) {
                throw "Project MCP config contains an inline-table namespace collision at $inlineKey."
            }
            $null = $inlineValuePaths.Add($inlineKey)
            $State.Index += $inlineKey.Length
            Skip-RepairTomlWhitespace -State $State
            if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -ne '=') {
                throw "Project MCP config has an invalid inline-table assignment: $Line"
            }
            $State.Index++
            Read-RepairTomlValue -State $State -Line $Line
            Skip-RepairTomlWhitespace -State $State
            if ($State.Index -ge $State.Text.Length) {
                throw "Project MCP config has an unclosed TOML inline table: $Line"
            }
            if ($State.Text[$State.Index] -eq '}') {
                $State.Index++
                return
            }
            if ($State.Text[$State.Index] -ne ',') {
                throw "Project MCP config has an invalid inline-table delimiter: $Line"
            }
            $State.Index++
            Skip-RepairTomlWhitespace -State $State
            if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -eq '}') {
                throw "Project MCP config has an invalid trailing inline-table comma: $Line"
            }
        }
    }
    Read-RepairTomlBareValue -State $State -Line $Line
}

function Get-RepairTomlValueInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $valueText = $Value.TrimStart()
    if ([string]::IsNullOrWhiteSpace($valueText)) {
        throw "Project MCP config has a missing TOML value: $Line"
    }
    $inBasicString = $false
    $inLiteralString = $false
    $escaped = $false
    $squareDepth = 0
    $curlyDepth = 0
    $valueEnd = $valueText.Length
    for ($index = 0; $index -lt $valueText.Length; $index++) {
        $character = $valueText[$index]
        if ($inBasicString) {
            if ($escaped) { $escaped = $false; continue }
            if ($character -eq '\') { $escaped = $true; continue }
            if ($character -eq '"') { $inBasicString = $false }
            continue
        }
        if ($inLiteralString) {
            if ($character -eq "'") { $inLiteralString = $false }
            continue
        }
        if ($character -eq '#') { $valueEnd = $index; break }
        if ($character -eq '"') { $inBasicString = $true; continue }
        if ($character -eq "'") { $inLiteralString = $true; continue }
        switch ($character) {
            '[' { $squareDepth++ }
            ']' { $squareDepth--; if ($squareDepth -lt 0) { throw "Project MCP config has an unmatched ]: $Line" } }
            '{' { $curlyDepth++ }
            '}' { $curlyDepth--; if ($curlyDepth -lt 0) { throw "Project MCP config has an unmatched }: $Line" } }
        }
    }
    if ($inBasicString -or $inLiteralString -or $escaped -or $squareDepth -ne 0 -or $curlyDepth -ne 0) {
        throw "Project MCP config has an unclosed string, array, or inline table: $Line"
    }
    $valueWithoutComment = $valueText.Substring(0, $valueEnd).Trim()
    if ([string]::IsNullOrWhiteSpace($valueWithoutComment)) {
        throw "Project MCP config has a missing TOML value: $Line"
    }
    $state = [pscustomobject]@{ Text = $valueWithoutComment; Index = 0 }
    Read-RepairTomlValue -State $state -Line $Line
    Skip-RepairTomlWhitespace -State $state
    if ($state.Index -ne $state.Text.Length) {
        throw "Project MCP config contains trailing TOML value content: $Line"
    }

    $rawValueBeforeComment = $valueText.Substring(0, $valueEnd)
    $trailingWhitespace = [regex]::Match($rawValueBeforeComment, '\s*$').Value
    $comment = if ($valueEnd -lt $valueText.Length) { $valueText.Substring($valueEnd) } else { "" }
    return [pscustomobject]@{
        Value = $valueWithoutComment
        Suffix = $trailingWhitespace + $comment
    }
}

function Assert-RepairTomlValue {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Line
    )

    $null = Get-RepairTomlValueInfo -Value $Value -Line $Line
}

function Get-RepairMcpConfigPlan {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$RemoveManagedKeys,
        [switch]$RestoreUninstalledNamespace,
        [AllowNull()][string]$UninstallStateId
    )

    if ($RemoveManagedKeys -and $RestoreUninstalledNamespace) {
        throw "Project MCP config cannot be removed and restored in the same plan."
    }
    if ($RemoveManagedKeys -or $RestoreUninstalledNamespace) {
        $null = Assert-ProjectIntegrationStateId -StateId $UninstallStateId
    }

    $configPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:McpConfigRelativePath -Label "project MCP config"
    $providerSlug = "codedb-$(ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf ($ProjectRoot.TrimEnd('\', '/'))))"
    if ($providerSlug -notmatch '^[a-z0-9][a-z0-9-]{0,126}$') {
        throw "Project MCP server slug cannot be represented as a safe bare TOML key: $providerSlug"
    }
    $targetTable = "mcp_servers.$providerSlug"
    $desiredSectionLf = Get-RepairMcpRegistrationContent -ProjectRoot $ProjectRoot
    Assert-NoReparsePoint -Path $configPath -Root $ProjectRoot -Label "project MCP config"
    if (-not (Test-Path -LiteralPath $configPath)) {
        return [pscustomobject]@{
            Path = $configPath
            Exists = $false
            Current = [bool]$RemoveManagedKeys
            OriginalBytes = [byte[]]@()
            DesiredBytes = if ($RemoveManagedKeys) { [byte[]]@() } else { [System.Text.UTF8Encoding]::new($false).GetBytes($desiredSectionLf + "`n") }
            NewLine = "`n"
            RemovingRegistration = [bool]$RemoveManagedKeys
        }
    }
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        throw "Project MCP config is not a regular file: $configPath"
    }
    Assert-NoReparsePoint -Path $configPath -Root $ProjectRoot -Label "project MCP config"
    $fileInfo = Get-Item -LiteralPath $configPath -Force
    if ($fileInfo.Length -gt (1024 * 1024)) {
        throw "Project MCP config exceeds the 1 MiB repair limit."
    }
    $bytes = [System.IO.File]::ReadAllBytes($configPath)
    $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $offset = 3
    }
    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $text = $utf8.GetString($bytes, $offset, $bytes.Length - $offset)
    } catch {
        throw "Project MCP config is not valid UTF-8."
    }
    if ($text.IndexOf([char]0) -ge 0) {
        throw "Project MCP config contains NUL bytes."
    }
    Assert-RepairTomlCharacterSet -Text $text
    $hasCrLf = $text.Contains("`r`n")
    $withoutCrLf = $text.Replace("`r`n", "")
    if ($withoutCrLf.Contains("`r")) {
        throw "Project MCP config uses unsupported bare CR line endings."
    }
    if ($hasCrLf -and $text.Replace("`r`n", "").Contains("`n")) {
        throw "Project MCP config uses mixed line endings."
    }
    $newLine = if ($hasCrLf) { "`r`n" } else { "`n" }

    $reservedPrefixStem = "# rice-ai-codedb-uninstalled:"
    $reservedPrefix = if ([string]::IsNullOrWhiteSpace($UninstallStateId)) {
        $null
    } else {
        "$reservedPrefixStem$UninstallStateId`: "
    }
    $preservedLineCount = 0
    $encodedLines = [regex]::Split($text, "`r?`n")
    for ($lineIndex = 0; $lineIndex -lt $encodedLines.Count; $lineIndex++) {
        $encodedLine = $encodedLines[$lineIndex]
        if (-not $encodedLine.StartsWith($reservedPrefixStem, [StringComparison]::Ordinal)) { continue }
        if ([string]::IsNullOrWhiteSpace($reservedPrefix) -or
            -not $encodedLine.StartsWith($reservedPrefix, [StringComparison]::Ordinal)) {
            throw "Project MCP config contains a preserved CodeDB namespace for a different or invalid uninstall state."
        }
        $preservedLineCount += 1
        if ($RestoreUninstalledNamespace) {
            $encodedLines[$lineIndex] = $encodedLine.Substring($reservedPrefix.Length)
        }
    }
    if ($preservedLineCount -gt 0 -and -not ($RemoveManagedKeys -or $RestoreUninstalledNamespace)) {
        throw "Project MCP config contains an uninstalled CodeDB namespace that only Install CodeDB may restore."
    }
    if ($RestoreUninstalledNamespace -and $preservedLineCount -gt 0) {
        $text = $encodedLines -join $newLine
    }

    # The repairer deliberately supports a conservative TOML subset. Complex
    # multiline values are left for manual review rather than guessed at.
    if ($text.Contains("'''" ) -or $text.Contains('"""')) {
        throw "Project MCP config contains a multiline TOML string that cannot be merged safely."
    }
    $lines = [regex]::Split($text, "`r?`n")
    $tables = New-Object System.Collections.Generic.List[object]
    $seenTables = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    $seenKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $valuePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $dottedTablePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $implicitNonArrayTablePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $arrayTablePaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $targetAssignments = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    $desiredValues = [ordered]@{
        command = '"node"'
        cwd = '"."'
        args = '["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]'
        startup_timeout_sec = '120'
    }
    $currentTable = ""
    $currentScope = "@root"
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) { continue }
        $isTable = $false
        $isArray = $false
        $body = ""
        if ($trimmed -match '^\[\[(?<body>[^\[\]]+)\]\]\s*(?:#.*)?$') {
            $isTable = $true
            $isArray = $true
            $body = $Matches.body.Trim()
        } elseif ($trimmed -match '^\[(?<body>[^\[\]]+)\]\s*(?:#.*)?$') {
            $isTable = $true
            $body = $Matches.body.Trim()
        }
        if ($isTable) {
            if ($body -notmatch '^[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*$') {
                throw "Project MCP config contains an unsupported or invalid table header: $trimmed"
            }
            $tableSegments = @($body.Split('.'))
            for ($segmentCount = 1; $segmentCount -le $tableSegments.Count; $segmentCount++) {
                $tablePrefix = $tableSegments[0..($segmentCount - 1)] -join '.'
                if ($valuePaths.Contains($tablePrefix)) {
                    throw "Project MCP config contains a value/table namespace collision at $tablePrefix."
                }
            }
            if ($dottedTablePaths.Contains($body)) {
                throw "Project MCP config redeclares a table already defined by a dotted key: [$body]"
            }
            if ($isArray -and $implicitNonArrayTablePaths.Contains($body)) {
                throw "Project MCP config converts an implicit table into an array table: [[$body]]"
            }
            foreach ($arrayTablePath in $arrayTablePaths) {
                if ($body.StartsWith($arrayTablePath + '.', [StringComparison]::Ordinal)) {
                    throw "Project MCP config contains a nested table below an array table that cannot be merged safely: $body"
                }
            }
            if ($seenTables.ContainsKey($body)) {
                $previousWasArray = [bool]$seenTables[$body]
                if (-not ($previousWasArray -and $isArray)) {
                    throw "Project MCP config contains a duplicate table: [$body]"
                }
            } else {
                $seenTables.Add($body, $isArray)
            }
            if ($isArray) {
                $null = $arrayTablePaths.Add($body)
            }
            for ($segmentCount = 1; $segmentCount -lt $tableSegments.Count; $segmentCount++) {
                $tablePrefix = $tableSegments[0..($segmentCount - 1)] -join '.'
                if (-not $seenTables.ContainsKey($tablePrefix) -and
                    -not $dottedTablePaths.Contains($tablePrefix)) {
                    $null = $implicitNonArrayTablePaths.Add($tablePrefix)
                }
            }
            $tables.Add([pscustomobject]@{ Name = $body; Line = $index; IsArray = $isArray })
            $currentTable = $body
            $currentScope = if ($isArray) { "$body#$index" } else { $body }
            continue
        }
        if ($trimmed.StartsWith('[')) {
            throw "Project MCP config contains an invalid table header: $trimmed"
        }
        if ($line -notmatch '^(?<prefix>\s*)(?<key>[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*)(?<separator>\s*=\s*)(?<value>.*)$') {
            throw "Project MCP config contains unsupported TOML syntax: $trimmed"
        }
        $key = $Matches.key
        $value = $Matches.value
        $linePrefix = $Matches.prefix + $key + $Matches.separator
        $valueInfo = Get-RepairTomlValueInfo -Value $value -Line $trimmed
        $scopedKey = "$currentScope`:$key"
        if (-not $seenKeys.Add($scopedKey)) {
            throw "Project MCP config contains a duplicate key: $key"
        }
        $absoluteKey = if ([string]::IsNullOrWhiteSpace($currentTable)) { $key } else { "$currentTable.$key" }
        $namespaceKey = if ([string]::IsNullOrWhiteSpace($currentTable)) { $key } else { "$currentScope.$key" }
        $absoluteSegments = @($namespaceKey.Split('.'))
        $scopeSegmentCount = if ([string]::IsNullOrWhiteSpace($currentTable)) { 0 } else { @($currentScope.Split('.')).Count }
        for ($segmentCount = 1; $segmentCount -lt $absoluteSegments.Count; $segmentCount++) {
            $keyPrefix = $absoluteSegments[0..($segmentCount - 1)] -join '.'
            if ($valuePaths.Contains($keyPrefix)) {
                throw "Project MCP config contains a value/dotted-key namespace collision at $keyPrefix."
            }
            if ($segmentCount -gt $scopeSegmentCount) {
                if ($seenTables.ContainsKey($keyPrefix)) {
                    throw "Project MCP config redefines table namespace $keyPrefix through a dotted key."
                }
                $null = $dottedTablePaths.Add($keyPrefix)
            }
        }
        $isArrayScope = -not [string]::Equals($namespaceKey, $absoluteKey, [StringComparison]::Ordinal)
        if ((-not $isArrayScope -and
                ($seenTables.ContainsKey($absoluteKey) -or
                 @($tables | Where-Object { $_.Name.StartsWith($absoluteKey + '.', [StringComparison]::Ordinal) }).Count -gt 0)) -or
            $dottedTablePaths.Contains($namespaceKey) -or
            @($valuePaths | Where-Object { $_.StartsWith($namespaceKey + '.', [StringComparison]::Ordinal) }).Count -gt 0 -or
            -not $valuePaths.Add($namespaceKey)) {
            throw "Project MCP config contains a duplicate key or key/table namespace collision at $absoluteKey."
        }
        $isTargetTableScope = [string]::Equals($currentTable, $targetTable, [StringComparison]::Ordinal)
        $isTargetDescendantScope = $currentTable.StartsWith($targetTable + '.', [StringComparison]::Ordinal)
        if (-not $isTargetTableScope -and
            -not $isTargetDescendantScope -and
            ([string]::Equals($absoluteKey, $targetTable, [StringComparison]::Ordinal) -or
             $absoluteKey.StartsWith($targetTable + '.', [StringComparison]::Ordinal) -or
             $targetTable.StartsWith($absoluteKey + '.', [StringComparison]::Ordinal))) {
            throw "Project MCP config contains an ambiguous dotted-key collision for $targetTable."
        }
        if ($isTargetTableScope) {
            foreach ($desiredKey in $desiredValues.Keys) {
                if ([string]::Equals($key, $desiredKey, [StringComparison]::Ordinal)) {
                    $targetAssignments.Add($key, [pscustomobject]@{
                        Line = $index
                        Prefix = $linePrefix
                        Value = $valueInfo.Value
                        Suffix = $valueInfo.Suffix
                    })
                } elseif ($key.StartsWith($desiredKey + '.', [StringComparison]::Ordinal) -or
                    $desiredKey.StartsWith($key + '.', [StringComparison]::Ordinal)) {
                    throw "Project MCP config contains an ambiguous target key collision for $targetTable.$desiredKey."
                }
            }
        }
    }
    $targetTables = @($tables | Where-Object {
        [string]::Equals($_.Name, $targetTable, [StringComparison]::Ordinal)
    })
    if ($targetTables.Count -gt 1) {
        throw "Project MCP config contains duplicate target tables: [$targetTable]"
    }
    if ($targetTables.Count -eq 1 -and $targetTables[0].IsArray) {
        throw "Project MCP config contains an ambiguous target array table: [[$targetTable]]"
    }
    foreach ($table in $tables) {
        if ($table.IsArray -and $targetTable.StartsWith($table.Name + '.', [StringComparison]::Ordinal)) {
            throw "Project MCP config has an ambiguous array-table collision with [$targetTable]."
        }
        foreach ($desiredKey in $desiredValues.Keys) {
            $managedPath = "$targetTable.$desiredKey"
            if ([string]::Equals($table.Name, $managedPath, [StringComparison]::Ordinal) -or
                $table.Name.StartsWith($managedPath + '.', [StringComparison]::Ordinal)) {
                throw "Project MCP config contains a table namespace collision with managed key $managedPath."
            }
        }
    }

    $desiredSection = $desiredSectionLf.Replace("`n", $newLine)
    if ($RemoveManagedKeys) {
        $targetNamespaceTables = @($tables | Where-Object {
            [string]::Equals($_.Name, $targetTable, [StringComparison]::Ordinal) -or
            $_.Name.StartsWith($targetTable + '.', [StringComparison]::Ordinal)
        } | Sort-Object Line)
        if ($preservedLineCount -gt 0 -and $targetNamespaceTables.Count -gt 0) {
            throw "Project MCP config contains both active and preserved declarations for [$targetTable]."
        }
        if ($preservedLineCount -gt 0 -or $targetNamespaceTables.Count -eq 0) {
            $desiredText = $text
        } else {
            $desiredLines = [System.Collections.Generic.List[string]]::new()
            $desiredLines.AddRange([string[]]$lines)
            $allTables = @($tables | Sort-Object Line)
            foreach ($targetNamespaceTable in $targetNamespaceTables) {
                $nextTable = @($allTables | Where-Object { $_.Line -gt $targetNamespaceTable.Line } | Select-Object -First 1)
                $endLine = if ($nextTable.Count -eq 0) { $desiredLines.Count - 1 } else { [int]$nextTable[0].Line - 1 }
                for ($lineIndex = [int]$targetNamespaceTable.Line; $lineIndex -le $endLine; $lineIndex++) {
                    $desiredLines[$lineIndex] = $reservedPrefix + $desiredLines[$lineIndex]
                }
            }
            $desiredText = $desiredLines.ToArray() -join $newLine
        }
    } elseif ($targetTables.Count -eq 0) {
        $separator = if ($text.Length -eq 0) { "" } elseif ($text.EndsWith($newLine)) { $newLine } else { $newLine + $newLine }
        $desiredText = $text + $separator + $desiredSection + $newLine
    } else {
        $target = $targetTables[0]
        $desiredLines = [System.Collections.Generic.List[string]]::new()
        $desiredLines.AddRange([string[]]$lines)
        foreach ($desiredKey in $desiredValues.Keys) {
            if (-not $targetAssignments.ContainsKey($desiredKey)) { continue }
            $assignment = $targetAssignments[$desiredKey]
            $desiredLines[$assignment.Line] = $assignment.Prefix + [string]$desiredValues[$desiredKey] + $assignment.Suffix
        }
        $missingLines = [System.Collections.Generic.List[string]]::new()
        foreach ($desiredKey in $desiredValues.Keys) {
            if (-not $targetAssignments.ContainsKey($desiredKey)) {
                $missingLines.Add("$desiredKey = $($desiredValues[$desiredKey])")
            }
        }
        if ($missingLines.Count -gt 0) {
            $next = @($tables | Where-Object { $_.Line -gt $target.Line } | Sort-Object Line | Select-Object -First 1)
            $insertionLine = if ($next.Count -eq 0) { $lines.Count } else { [int]$next[0].Line }
            while ($insertionLine -gt ($target.Line + 1)) {
                $preceding = $lines[$insertionLine - 1].Trim()
                if (-not [string]::IsNullOrWhiteSpace($preceding) -and -not $preceding.StartsWith('#')) { break }
                $insertionLine--
            }
            $desiredLines.InsertRange($insertionLine, $missingLines.ToArray())
        }
        $desiredText = $desiredLines.ToArray() -join $newLine
    }
    $desiredBody = [System.Text.UTF8Encoding]::new($false).GetBytes($desiredText)
    $desiredBytes = New-Object byte[] ($offset + $desiredBody.Length)
    if ($offset -eq 3) {
        $desiredBytes[0] = 0xEF
        $desiredBytes[1] = 0xBB
        $desiredBytes[2] = 0xBF
    }
    [Array]::Copy($desiredBody, 0, $desiredBytes, $offset, $desiredBody.Length)
    $current = $bytes.Length -eq $desiredBytes.Length
    if ($current) {
        for ($index = 0; $index -lt $bytes.Length; $index++) {
            if ($bytes[$index] -ne $desiredBytes[$index]) { $current = $false; break }
        }
    }
    return [pscustomobject]@{
        Path = $configPath
        Exists = $true
        Current = $current
        OriginalBytes = $bytes
        DesiredBytes = $desiredBytes
        NewLine = $newLine
        RemovingRegistration = [bool]$RemoveManagedKeys
    }
}

function Publish-RepairMcpConfig {
    param(
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Lock
    )

    if ($Plan.Current) {
        if ($Plan.RemovingRegistration) {
            Write-Host "[PHASE MCP_REGISTRATION] DISABLED - the target namespace is already preserved as inert uninstall-state comments."
        } else {
            Write-Host "[PHASE MCP_REGISTRATION] CURRENT - target section already matches the reviewed project registration."
        }
        return $null
    }
    $configDirectory = Split-Path -Parent $Plan.Path
    Assert-NoReparsePoint -Path $configDirectory -Root $ProjectRoot -Label "project MCP config directory"
    New-Item -ItemType Directory -Force -Path $configDirectory | Out-Null
    Assert-NoReparsePoint -Path $configDirectory -Root $ProjectRoot -Label "project MCP config directory"
    Assert-NoReparsePoint -Path $Plan.Path -Root $ProjectRoot -Label "project MCP config"
    $stagePath = Join-Path $Lock.Root ("mcp-config-$([guid]::NewGuid().ToString('N')).tmp")
    $stream = $null
    try {
        $stream = [System.IO.FileStream]::new($stagePath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::WriteThrough)
        $stream.Write($Plan.DesiredBytes, 0, $Plan.DesiredBytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null

        $backupPath = $null
        if ($Plan.Exists) {
            $currentBytes = [System.IO.File]::ReadAllBytes($Plan.Path)
            if ($currentBytes.Length -ne $Plan.OriginalBytes.Length) { throw "Project MCP config changed after preflight." }
            for ($index = 0; $index -lt $currentBytes.Length; $index++) {
                if ($currentBytes[$index] -ne $Plan.OriginalBytes[$index]) { throw "Project MCP config changed after preflight." }
            }
            $backupRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:McpConfigBackupRelativePath -Label "MCP config backup root"
            Assert-NoReparsePoint -Path $backupRoot -Root $ProjectRoot -Label "MCP config backup root"
            New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
            Assert-NoReparsePoint -Path $backupRoot -Root $ProjectRoot -Label "MCP config backup root"
            $backupPath = Join-Path $backupRoot ("config-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))-$([guid]::NewGuid().ToString('N').Substring(0,8)).toml.bak")
            [System.IO.File]::Replace($stagePath, $Plan.Path, $backupPath, $true)
            if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) { throw "Project MCP config backup could not be published." }
            $backupBytes = [System.IO.File]::ReadAllBytes($backupPath)
            $backupMatchesPlan = $backupBytes.Length -eq $Plan.OriginalBytes.Length
            if ($backupMatchesPlan) {
                for ($index = 0; $index -lt $backupBytes.Length; $index++) {
                    if ($backupBytes[$index] -ne $Plan.OriginalBytes[$index]) { $backupMatchesPlan = $false; break }
                }
            }
            if (-not $backupMatchesPlan) {
                $raceBackupPath = Join-Path $backupRoot ("config-race-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))-$([guid]::NewGuid().ToString('N').Substring(0,8)).toml.bak")
                try {
                    [System.IO.File]::Replace($backupPath, $Plan.Path, $raceBackupPath, $true)
                } catch {
                    throw "Project MCP config changed during atomic publication. The replacement-moment pre-image remains at $backupPath. Restore failed: $($_.Exception.Message)"
                }
                throw "Project MCP config changed during atomic publication and was restored from its replacement-moment pre-image. The displaced bytes remain recoverable at $raceBackupPath."
            }
        } elseif (Test-Path -LiteralPath $Plan.Path) {
            throw "Project MCP config appeared after preflight."
        } else {
            [System.IO.File]::Move($stagePath, $Plan.Path)
        }
        $published = [System.IO.File]::ReadAllBytes($Plan.Path)
        if ($published.Length -ne $Plan.DesiredBytes.Length) { throw "Project MCP config publication failed verification." }
        for ($index = 0; $index -lt $published.Length; $index++) {
            if ($published[$index] -ne $Plan.DesiredBytes[$index]) { throw "Project MCP config publication failed verification." }
        }
        Add-MaterializerMutationScope -Scope "mcp_registration"
        Invoke-TestFaultAfterMutation
        $projectSlug = ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf ($ProjectRoot.TrimEnd('\', '/')))
        if ($Plan.RemovingRegistration) {
            Write-Host "[PHASE MCP_REGISTRATION] DISABLED - [mcp_servers.codedb-$projectSlug] and its descendants were preserved as inert uninstall-state comments."
        } else {
            Write-Host "[PHASE MCP_REGISTRATION] REPAIRED - only [mcp_servers.codedb-$projectSlug] was published."
        }
        if ($null -ne $backupPath) { Write-Host "[BACKUP] $backupPath" }
        return $backupPath
    } finally {
        if ($null -ne $stream) { $stream.Dispose() }
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Get-McpAvailabilityIdentity {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $markerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "installed payload marker"
    $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $markerPath -ProjectRoot $ProjectRoot
    if (-not $plan.IsCurrent) {
        throw "MCP availability requires the current Package-owned Host runtime."
    }
    $mcpPlan = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
    if (-not $mcpPlan.Current) {
        throw "MCP availability requires the current ownership-safe project registration."
    }

    $wrapperRelativePath = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    $wrapperPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $wrapperRelativePath -Label "project MCP wrapper"
    Assert-NoReparsePoint -Path $wrapperPath -Root $ProjectRoot -Label "project MCP wrapper"
    if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf)) {
        throw "Project MCP wrapper is missing: $wrapperPath"
    }
    $wrapperFile = $Manifest.TargetMap[$wrapperRelativePath]
    if ($null -eq $wrapperFile -or
        -not [string]::Equals((Get-FileSha256 -Path $wrapperPath), [string]$wrapperFile.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Project MCP wrapper does not match the current Package-owned payload."
    }

    return [pscustomobject]@{
        ConfigPath = $mcpPlan.Path
        ConfigSha256 = Get-FileSha256 -Path $mcpPlan.Path
        WrapperPath = $wrapperPath
        WrapperRelativePath = $wrapperRelativePath
        WrapperSha256 = Get-FileSha256 -Path $wrapperPath
        ProviderSlug = "codedb-$(ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf ($ProjectRoot.TrimEnd('\', '/'))))"
    }
}

function Write-McpAvailabilityState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Identity,
        [Parameter(Mandatory = $true)][ValidateSet("AVAILABLE", "UNAVAILABLE")][string]$Availability,
        [Parameter(Mandatory = $true)][string]$Detail,
        [string[]]$ToolNames = @(),
        [bool]$WrapperInitializeCallable = $false,
        [bool]$ToolsListCallable = $false,
        [bool]$CodedbStatusCallable = $false,
        [bool]$CodedbStatusUsable = $false,
        [bool]$CodedbTextSearchCallable = $false
    )

    $statePath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:McpAvailabilityRelativePath -Label "MCP availability state"
    $stateRoot = Split-Path -Parent $statePath
    Assert-NoReparsePoint -Path $stateRoot -Root $ProjectRoot -Label "MCP availability state root"
    New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null
    Assert-NoReparsePoint -Path $stateRoot -Root $ProjectRoot -Label "MCP availability state root"
    Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "MCP availability state"

    $document = [ordered]@{
        schema_version = $script:McpAvailabilitySchemaVersion
        managed_by = $script:ManagedBy
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
        generation_id = $Manifest.GenerationId
        provider_slug = $Identity.ProviderSlug
        config_sha256 = $Identity.ConfigSha256
        wrapper_relative_path = $Identity.WrapperRelativePath
        wrapper_sha256 = $Identity.WrapperSha256
        availability = $Availability
        tool_names = @($ToolNames)
        wrapper_initialize_callable = $WrapperInitializeCallable
        tools_list_callable = $ToolsListCallable
        codedb_status_callable = $CodedbStatusCallable
        codedb_status_usable = $CodedbStatusUsable
        codedb_text_search_callable = $CodedbTextSearchCallable
        detail = $Detail
        checked_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    $stagePath = Join-Path $Lock.Root ("mcp-availability-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content (($document | ConvertTo-Json -Depth 6) + "`n")
        Publish-TransactionFile -StagePath $stagePath -TargetPath $statePath
        Add-MaterializerMutationScope -Scope "mcp_availability"
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Get-McpAvailabilityStatus {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $identity = Get-McpAvailabilityIdentity -Manifest $Manifest -ProjectRoot $ProjectRoot
    $statePath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:McpAvailabilityRelativePath -Label "MCP availability state"
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return [pscustomobject]@{ Current = $false; Pending = $true; Detail = "No Package-owned MCP handshake has completed for this Host and registration." }
    }
    Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "MCP availability state"
    $json = Read-BoundedJsonDocument -Path $statePath -Label "MCP availability state" -MaximumBytes (64 * 1024)
    $document = $json.Document
    $toolNames = Get-RequiredJsonArray -Object $document -Name "tool_names" -Label "MCP availability state"
    foreach ($toolName in $toolNames) {
        if ($toolName -isnot [string]) {
            throw "MCP availability state tool_names must contain only JSON strings."
        }
    }
    $expectedTools = @($script:ExpectedMcpTools | Sort-Object)
    $actualTools = @($toolNames | ForEach-Object { [string]$_ } | Sort-Object)
    $toolsCurrent = ($actualTools.Count -eq $expectedTools.Count) -and
        [string]::Equals(($actualTools -join "|"), ($expectedTools -join "|"), [StringComparison]::Ordinal)
    $current = (Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "MCP availability state") -eq $script:McpAvailabilitySchemaVersion -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "MCP availability state"), $script:ManagedBy, [StringComparison]::Ordinal) -and
        [string]::Equals([System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $document -Name "project_root" -Label "MCP availability state")), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "generation_id" -Label "MCP availability state"), $Manifest.GenerationId, [StringComparison]::Ordinal) -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "provider_slug" -Label "MCP availability state"), $identity.ProviderSlug, [StringComparison]::Ordinal) -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "config_sha256" -Label "MCP availability state"), $identity.ConfigSha256, [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "wrapper_relative_path" -Label "MCP availability state"), $identity.WrapperRelativePath, [StringComparison]::Ordinal) -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "wrapper_sha256" -Label "MCP availability state"), $identity.WrapperSha256, [StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals((Get-RequiredJsonString -Object $document -Name "availability" -Label "MCP availability state"), "AVAILABLE", [StringComparison]::Ordinal) -and
        (Get-RequiredJsonBoolean -Object $document -Name "wrapper_initialize_callable" -Label "MCP availability state") -and
        (Get-RequiredJsonBoolean -Object $document -Name "tools_list_callable" -Label "MCP availability state") -and
        (Get-RequiredJsonBoolean -Object $document -Name "codedb_status_callable" -Label "MCP availability state") -and
        (Get-RequiredJsonBoolean -Object $document -Name "codedb_status_usable" -Label "MCP availability state") -and
        (Get-RequiredJsonBoolean -Object $document -Name "codedb_text_search_callable" -Label "MCP availability state") -and
        $toolsCurrent
    $detail = Get-RequiredJsonString -Object $document -Name "detail" -Label "MCP availability state"
    $null = Get-RequiredJsonString -Object $document -Name "checked_at_utc" -Label "MCP availability state"
    return [pscustomobject]@{
        Current = $current
        Pending = $false
        Detail = if ($current) { $detail } elseif ([string]::IsNullOrWhiteSpace($detail)) { "The last Package-owned MCP handshake is unavailable or stale." } else { $detail }
    }
}

function Assert-McpAvailabilityStateArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    Assert-NoReparsePoint -Path $Path -Root $ProjectRoot -Label "MCP availability state"
    $document = (Read-BoundedJsonDocument -Path $Path -Label "MCP availability state" -MaximumBytes (64 * 1024)).Document
    $recordedRoot = Get-RequiredJsonString -Object $document -Name "project_root" -Label "MCP availability state"
    $generationId = Get-RequiredJsonString -Object $document -Name "generation_id" -Label "MCP availability state"
    $providerSlug = Get-RequiredJsonString -Object $document -Name "provider_slug" -Label "MCP availability state"
    $configSha256 = Get-RequiredJsonString -Object $document -Name "config_sha256" -Label "MCP availability state"
    $wrapperRelativePath = Get-RequiredJsonString -Object $document -Name "wrapper_relative_path" -Label "MCP availability state"
    $wrapperSha256 = Get-RequiredJsonString -Object $document -Name "wrapper_sha256" -Label "MCP availability state"
    $availability = Get-RequiredJsonString -Object $document -Name "availability" -Label "MCP availability state"
    $toolNames = Get-RequiredJsonArray -Object $document -Name "tool_names" -Label "MCP availability state"
    $wrapperInitializeCallable = Get-RequiredJsonBoolean -Object $document -Name "wrapper_initialize_callable" -Label "MCP availability state"
    $toolsListCallable = Get-RequiredJsonBoolean -Object $document -Name "tools_list_callable" -Label "MCP availability state"
    $statusCallable = Get-RequiredJsonBoolean -Object $document -Name "codedb_status_callable" -Label "MCP availability state"
    $statusUsable = Get-RequiredJsonBoolean -Object $document -Name "codedb_status_usable" -Label "MCP availability state"
    $textSearchCallable = Get-RequiredJsonBoolean -Object $document -Name "codedb_text_search_callable" -Label "MCP availability state"
    $detail = Get-RequiredJsonString -Object $document -Name "detail" -Label "MCP availability state"
    $checkedAtText = Get-RequiredJsonString -Object $document -Name "checked_at_utc" -Label "MCP availability state"
    foreach ($toolName in $toolNames) {
        if ($toolName -isnot [string]) {
            throw "MCP availability state tool_names must contain only JSON strings."
        }
    }
    $actualTools = @($toolNames | ForEach-Object { [string]$_ } | Sort-Object)
    $expectedTools = @($script:ExpectedMcpTools | Sort-Object)
    $hasExpectedTools = $actualTools.Count -eq $expectedTools.Count -and
        [string]::Equals(($actualTools -join "|"), ($expectedTools -join "|"), [StringComparison]::Ordinal)
    $usable = $wrapperInitializeCallable -and
        $toolsListCallable -and
        $statusCallable -and
        $statusUsable -and
        $textSearchCallable -and
        $hasExpectedTools
    [DateTimeOffset]$checkedAt = [DateTimeOffset]::MinValue
    try {
        $actualRoot = [System.IO.Path]::GetFullPath($recordedRoot).TrimEnd('\', '/')
        $expectedRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    } catch {
        throw "MCP availability state contains an invalid project root."
    }
    if ((Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "MCP availability state") -ne $script:McpAvailabilitySchemaVersion -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "MCP availability state"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals($actualRoot, $expectedRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $generationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$' -or
        $providerSlug -cnotmatch '^[a-z0-9][a-z0-9-]{0,126}$' -or
        $configSha256 -cnotmatch '^[0-9a-fA-F]{64}$' -or
        -not [string]::Equals($wrapperRelativePath, "AIWork/codedb/wrapper/codedb-project-wrapper.mjs", [StringComparison]::Ordinal) -or
        $wrapperSha256 -cnotmatch '^[0-9a-fA-F]{64}$' -or
        $availability -cnotin @("AVAILABLE", "UNAVAILABLE") -or
        ($availability -ceq "AVAILABLE" -and -not $usable) -or
        ($availability -ceq "UNAVAILABLE" -and $usable) -or
        $detail.Length -gt (32 * 1024) -or
        -not [DateTimeOffset]::TryParse(
            $checkedAtText,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$checkedAt)) {
        throw "MCP availability state identity or schema is invalid."
    }
    return $document
}

function Open-McpAvailabilityProbeWindow {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if ($Lock.ActiveMarkerPublished -and (Test-Path -LiteralPath $Lock.ActiveMarkerPath -PathType Leaf)) {
        Assert-NoReparsePoint -Path $Lock.ActiveMarkerPath -Root $ProjectRoot -Label "materializer active marker"
        Remove-Item -LiteralPath $Lock.ActiveMarkerPath -Force
        $Lock.ActiveMarkerPublished = $false
    }
}

function Invoke-McpAvailabilityProbe {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Lock
    )

    $identity = Get-McpAvailabilityIdentity -Manifest $Manifest -ProjectRoot $ProjectRoot
    if ($PocFixture) {
        # Fixture mode deliberately suppresses watcher process creation. Keep
        # unrelated transaction/ownership regressions deterministic, while the
        # production probe path is exercised by a separate non-fixture test.
        $existingAvailability = $null
        try {
            $existingAvailability = Get-McpAvailabilityStatus -Manifest $Manifest -ProjectRoot $ProjectRoot
        } catch {
            $existingAvailability = $null
        }
        if ($null -eq $existingAvailability -or -not $existingAvailability.Current) {
            Write-McpAvailabilityState `
                -Lock $Lock `
                -ProjectRoot $ProjectRoot `
                -Manifest $Manifest `
                -Identity $identity `
                -Availability "AVAILABLE" `
                -Detail "Fixture-only usable backend evidence: initialize, tools/list, usable codedb_status, and bounded codedb_text_search succeeded." `
                -ToolNames $script:ExpectedMcpTools `
                -WrapperInitializeCallable $true `
                -ToolsListCallable $true `
                -CodedbStatusCallable $true `
                -CodedbStatusUsable $true `
                -CodedbTextSearchCallable $true
        }
        Write-Host "[PHASE MCP_AVAILABLE] READY - fixture-only backend evidence; production wrapper probing remains separately covered."
        return Get-McpAvailabilityStatus -Manifest $Manifest -ProjectRoot $ProjectRoot
    }
    $nodeCommand = Get-Command node -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $nodeCommand) {
        Write-McpAvailabilityState -Lock $Lock -ProjectRoot $ProjectRoot -Manifest $Manifest -Identity $identity -Availability "UNAVAILABLE" -Detail "Node.js is unavailable to the project MCP registration."
        throw "Node.js is unavailable to start the project MCP wrapper."
    }
    $packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
    $probePath = Join-Path $PSScriptRoot $script:McpAvailabilityProbeName
    Assert-NoReparsePoint -Path $probePath -Root $packageRoot -Label "Package-owned MCP availability probe"
    if (-not (Test-Path -LiteralPath $probePath -PathType Leaf)) {
        throw "Package-owned MCP availability probe is missing."
    }

    $global:LASTEXITCODE = 0
    $output = @(& $nodeCommand.Source $probePath --project-root $ProjectRoot 2>&1)
    $exitCode = $LASTEXITCODE
    $text = ($output | ForEach-Object { [string]$_ }) -join "`n"
    if ($text.Length -gt (1024 * 1024)) {
        $text = $text.Substring(0, 1024 * 1024)
        $exitCode = 1
    }
    $jsonLines = @($output | ForEach-Object { [string]$_ } | Where-Object { $_.TrimStart().StartsWith("{") })
    if ($jsonLines.Count -ne 1) {
        if ($exitCode -ne 0) {
            $detail = if ([string]::IsNullOrWhiteSpace($text)) { "Package-owned MCP handshake failed without diagnostic output." } else { $text.Trim() }
            Write-McpAvailabilityState -Lock $Lock -ProjectRoot $ProjectRoot -Manifest $Manifest -Identity $identity -Availability "UNAVAILABLE" -Detail $detail
        }
        throw "Package-owned MCP handshake returned an ambiguous result."
    }
    $result = ConvertFrom-StrictJsonText -Text $jsonLines[0] -Label "Package-owned MCP handshake result"
    $resultSchema = Get-RequiredJsonInt32 -Object $result -Name "schema_version" -Label "Package-owned MCP handshake result"
    $resultAvailability = Get-RequiredJsonString -Object $result -Name "availability" -Label "Package-owned MCP handshake result"
    $serverName = Get-RequiredJsonString -Object $result -Name "server_name" -Label "Package-owned MCP handshake result"
    $null = Get-RequiredJsonString -Object $result -Name "protocol_version" -Label "Package-owned MCP handshake result"
    $statusSummary = Get-RequiredJsonString -Object $result -Name "status_summary" -Label "Package-owned MCP handshake result"
    $resultDetail = Get-RequiredJsonString -Object $result -Name "detail" -Label "Package-owned MCP handshake result"
    $wrapperInitializeCallable = Get-RequiredJsonBoolean -Object $result -Name "wrapper_initialize_callable" -Label "Package-owned MCP handshake result"
    $toolsListCallable = Get-RequiredJsonBoolean -Object $result -Name "tools_list_callable" -Label "Package-owned MCP handshake result"
    $statusCallable = Get-RequiredJsonBoolean -Object $result -Name "codedb_status_callable" -Label "Package-owned MCP handshake result"
    $statusUsable = Get-RequiredJsonBoolean -Object $result -Name "codedb_status_usable" -Label "Package-owned MCP handshake result"
    $textSearchCallable = Get-RequiredJsonBoolean -Object $result -Name "codedb_text_search_callable" -Label "Package-owned MCP handshake result"
    $toolNames = Get-RequiredJsonArray -Object $result -Name "tool_names" -Label "Package-owned MCP handshake result"
    foreach ($toolName in $toolNames) {
        if ($toolName -isnot [string]) { throw "Package-owned MCP handshake tool_names must contain only strings." }
    }
    $actualTools = @($toolNames | ForEach-Object { [string]$_ } | Sort-Object)
    $expectedTools = @($script:ExpectedMcpTools | Sort-Object)
    $hasExpectedTools = $actualTools.Count -eq $expectedTools.Count -and
        [string]::Equals(($actualTools -join "|"), ($expectedTools -join "|"), [StringComparison]::Ordinal)
    $usable = $wrapperInitializeCallable -and
        $toolsListCallable -and
        $statusCallable -and
        $statusUsable -and
        $textSearchCallable -and
        $hasExpectedTools
    if ($resultSchema -ne $script:McpAvailabilitySchemaVersion -or
        $resultAvailability -cnotin @("AVAILABLE", "UNAVAILABLE") -or
        ($wrapperInitializeCallable -and -not [string]::Equals($serverName, "codedb-project-wrapper", [StringComparison]::Ordinal)) -or
        ($resultAvailability -ceq "AVAILABLE" -and -not $usable) -or
        ($resultAvailability -ceq "UNAVAILABLE" -and $usable) -or
        ($exitCode -eq 0 -and $resultAvailability -cne "AVAILABLE") -or
        ($exitCode -ne 0 -and $resultAvailability -cne "UNAVAILABLE")) {
        throw "Package-owned MCP handshake returned an invalid availability result."
    }
    if ($exitCode -ne 0) {
        Write-McpAvailabilityState `
            -Lock $Lock `
            -ProjectRoot $ProjectRoot `
            -Manifest $Manifest `
            -Identity $identity `
            -Availability "UNAVAILABLE" `
            -Detail $resultDetail `
            -ToolNames $actualTools `
            -WrapperInitializeCallable $wrapperInitializeCallable `
            -ToolsListCallable $toolsListCallable `
            -CodedbStatusCallable $statusCallable `
            -CodedbStatusUsable $statusUsable `
            -CodedbTextSearchCallable $textSearchCallable
        throw "Package-owned MCP handshake did not reach a usable project backend. $resultDetail"
    }
    $existingAvailability = $null
    try {
        $existingAvailability = Get-McpAvailabilityStatus -Manifest $Manifest -ProjectRoot $ProjectRoot
    } catch {
        $existingAvailability = $null
    }
    if ($null -eq $existingAvailability -or -not $existingAvailability.Current) {
        Write-McpAvailabilityState `
            -Lock $Lock `
            -ProjectRoot $ProjectRoot `
            -Manifest $Manifest `
            -Identity $identity `
            -Availability "AVAILABLE" `
            -Detail $resultDetail `
            -ToolNames $actualTools `
            -WrapperInitializeCallable $wrapperInitializeCallable `
            -ToolsListCallable $toolsListCallable `
            -CodedbStatusCallable $statusCallable `
            -CodedbStatusUsable $statusUsable `
            -CodedbTextSearchCallable $textSearchCallable
    }
    Write-Host "[PHASE MCP_AVAILABLE] READY - initialize, tools/list, usable codedb_status, and bounded codedb_text_search succeeded from the Unity project working directory."
    return Get-McpAvailabilityStatus -Manifest $Manifest -ProjectRoot $ProjectRoot
}

function Write-ProductLayerStatus {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Plan,
        [ValidateSet("COMPLETE", "PENDING")][string]$CleanupState = "COMPLETE"
    )

    $prerequisite = $script:MachinePrerequisiteStatus
    if ($null -eq $prerequisite) {
        $prerequisite = Get-MaterializerMachinePrerequisiteStatus -Manifest $Manifest
        $script:MachinePrerequisiteStatus = $prerequisite
        Write-MachinePrerequisiteStatus -Status $prerequisite
    }
    $installed = "PENDING"
    $configured = "PENDING"
    $mcpAvailable = "PENDING"
    $usableStatus = $false
    $boundedQuery = $false
    $productState = "STARTING"
    $detail = "CodeDB is converging the Package-owned Host, registration, and MCP availability."
    if ($Plan.IsCurrent) {
        $installed = "CURRENT"
        try {
            $mcpPlan = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
            if ($mcpPlan.Current) {
                $configured = "CURRENT"
                $availability = Get-McpAvailabilityStatus -Manifest $Manifest -ProjectRoot $ProjectRoot
                if ($availability.Current) {
                    $mcpAvailable = "CURRENT"
                    $usableStatus = $true
                    $boundedQuery = $true
                    $productState = "READY"
                    $detail = [string]$availability.Detail
                } elseif ($availability.Pending) {
                    $detail = [string]$availability.Detail
                } else {
                    $mcpAvailable = "UNAVAILABLE"
                    $productState = "NEEDS_ATTENTION"
                    $detail = [string]$availability.Detail
                }
            }
        } catch {
            $configured = "BLOCKED"
            $productState = "NEEDS_ATTENTION"
            $detail = $_.Exception.Message
        }
    }

    Write-Host "[PRODUCT_LAYER INSTALLED] $installed"
    Write-Host "[PRODUCT_LAYER CONFIGURED] $configured"
    Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] $mcpAvailable$(if ([string]::IsNullOrWhiteSpace($detail)) { '' } else { " - $detail" })"
    Write-Host "[PRODUCT_STATE] $productState"
    Write-ReadinessSnapshot `
        -Prerequisite $prerequisite `
        -Installed $installed `
        -Configured $configured `
        -McpAvailable $mcpAvailable `
        -UsableStatus $usableStatus `
        -BoundedQuery $boundedQuery `
        -CleanupState $CleanupState `
        -ProductState $productState `
        -Detail $detail
}

function Complete-AutomaticMcpConvergence {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)]$McpPlan,
        [switch]$WatcherAlreadyEnsured
    )

    $null = Publish-RepairMcpConfig -Plan $McpPlan -ProjectRoot $ProjectRoot -Lock $Lock
    $verifiedMcpPlan = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
    if (-not $verifiedMcpPlan.Current) {
        throw "Automatic convergence did not reach CONFIGURED."
    }
    if (-not $WatcherAlreadyEnsured) {
        $currentPointerPath = ConvertTo-AbsoluteChildPath `
            -Root $ProjectRoot `
            -RelativePath $script:CurrentPointerRelativePath `
            -Label "automatic convergence current pointer"
        $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
        if ($null -eq $current) {
            throw "Automatic convergence could not resolve the current Package-owned watcher."
        }
        Open-McpAvailabilityProbeWindow -Lock $Lock -ProjectRoot $ProjectRoot
        Invoke-UpgradeWatcherEnsure `
            -WatchManagerPath $current.WatchManagerPath `
            -ProjectRoot $ProjectRoot `
            -Label "current generation" `
            -WithoutMaterializerHandoff
    }
    Open-McpAvailabilityProbeWindow -Lock $Lock -ProjectRoot $ProjectRoot
    $availability = Invoke-McpAvailabilityProbe -Manifest $Manifest -ProjectRoot $ProjectRoot -Lock $Lock
    if (-not $availability.Current) {
        throw "Automatic convergence did not reach MCP_AVAILABLE."
    }
    $verifiedPlan = Get-MaterializationPlan `
        -Manifest $Manifest `
        -MarkerPath (ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "installed payload marker") `
        -ProjectRoot $ProjectRoot
    if (-not $verifiedPlan.IsCurrent) {
        throw "Automatic convergence did not preserve the current Host generation."
    }
}

function Get-MaterializerProviderRuntimeRoots {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $codedbRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb" -Label "CodeDB runtime root"
    Assert-NoReparsePoint -Path $codedbRuntimeRoot -Root $ProjectRoot -Label "CodeDB runtime root"
    $projectSlug = ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf ($ProjectRoot.TrimEnd('\', '/')))
    $roots = @{}
    $expectedRoot = Join-Path $codedbRuntimeRoot "codedb-$projectSlug"
    $roots[[System.IO.Path]::GetFullPath($expectedRoot)] = $expectedRoot

    if (Test-Path -LiteralPath $codedbRuntimeRoot -PathType Container) {
        foreach ($directory in @(Get-ChildItem -LiteralPath $codedbRuntimeRoot -Force -Directory)) {
            if (-not $directory.Name.StartsWith("codedb-", [StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            Assert-NoReparsePoint -Path $directory.FullName -Root $ProjectRoot -Label "provider runtime"
            $roots[[System.IO.Path]::GetFullPath($directory.FullName)] = $directory.FullName
        }
    }

    return @($roots.Values | Sort-Object)
}

function Assert-ExistingMaterializerActiveMarker {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $Lock.ActiveMarkerPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $Lock.ActiveMarkerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Materializer active marker is not a file: $($Lock.ActiveMarkerPath)" -ExitCode 7
    }
    Assert-NoReparsePoint -Path $Lock.ActiveMarkerPath -Root $ProjectRoot -Label "materializer active marker"
    try {
        $marker = (Read-BoundedJsonDocument -Path $Lock.ActiveMarkerPath -Label "materializer active marker" -MaximumBytes (64 * 1024)).Document
        $markerProcessId = Get-RequiredJsonInt32 -Object $marker -Name "pid" -Label "materializer active marker"
        $markerProcessIdentity = Get-MaterializerProcessIdentity -ProcessId $markerProcessId
        $markerProcessStartTicks = Get-RequiredJsonNullableString -Object $marker -Name "process_start_ticks" -Label "materializer active marker"
        $markerProjectRoot = Get-RequiredJsonString -Object $marker -Name "project_root" -Label "materializer active marker"
        $markerAction = Get-RequiredJsonString -Object $marker -Name "action" -Label "materializer active marker"
        $markerCreatedAtText = Get-RequiredJsonString -Object $marker -Name "created_at_utc" -Label "materializer active marker"
        [DateTimeOffset]$markerCreatedAt = [DateTimeOffset]::MinValue
        $valid = (Get-RequiredJsonInt32 -Object $marker -Name "schema_version" -Label "materializer active marker") -eq 1 -and
            (Get-RequiredJsonInt32 -Object $marker -Name "host_use_gate_version" -Label "materializer active marker") -eq $script:HostUseGateVersion -and
            [string]::Equals((Get-RequiredJsonString -Object $marker -Name "managed_by" -Label "materializer active marker"), $script:ManagedBy, [StringComparison]::Ordinal) -and
            $markerProcessId -gt 0 -and
            [string]::Equals(
                [System.IO.Path]::GetFullPath($markerProjectRoot),
                [System.IO.Path]::GetFullPath($ProjectRoot),
                [StringComparison]::OrdinalIgnoreCase) -and
            ($null -eq $markerProcessStartTicks -or $markerProcessStartTicks -match '^[0-9]{1,20}$') -and
            $markerAction -in @("upgrade", "sync", "remove", "repair") -and
            [DateTimeOffset]::TryParse(
                $markerCreatedAtText,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::RoundtripKind,
                [ref]$markerCreatedAt)
    } catch {
        $valid = $false
    }
    if (-not $valid) {
        Throw-MaterializerError -Message "Materializer active marker is invalid and requires manual review: $($Lock.ActiveMarkerPath)" -ExitCode 7
    }
    if ($markerProcessId -ne $PID -and $markerProcessIdentity.Alive -and
        ($null -eq $markerProcessIdentity.StartTicks -or
            [string]::IsNullOrWhiteSpace($markerProcessStartTicks) -or
            [string]::Equals($markerProcessStartTicks, [string]$markerProcessIdentity.StartTicks, [StringComparison]::Ordinal))) {
        Throw-MaterializerError -Message "Another payload materializer PID $markerProcessId is active." -ExitCode 4
    }
    if ($markerProcessId -ne $PID -and $markerProcessIdentity.Alive -and
        -not [string]::IsNullOrWhiteSpace($markerProcessStartTicks) -and
        $null -ne $markerProcessIdentity.StartTicks -and
        -not [string]::Equals($markerProcessStartTicks, [string]$markerProcessIdentity.StartTicks, [StringComparison]::Ordinal)) {
        Write-Host "[RECOVERED] Ignored a stale materializer marker whose PID was reused."
    }
}

function Publish-MaterializerActiveMarker {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$MarkerAction
    )

    $publishedAction = if ([string]::IsNullOrWhiteSpace($MarkerAction)) {
        $Action.ToLowerInvariant()
    } else {
        $MarkerAction.ToLowerInvariant()
    }
    if ($publishedAction -notin @("upgrade", "sync", "remove", "repair")) {
        Throw-MaterializerError -Message "Unsupported materializer active marker action: $publishedAction" -ExitCode 2
    }
    $selfIdentity = Get-MaterializerProcessIdentity -ProcessId $PID
    $document = [ordered]@{
        schema_version = 1
        host_use_gate_version = $script:HostUseGateVersion
        managed_by = $script:ManagedBy
        pid = $PID
        process_start_ticks = $selfIdentity.StartTicks
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
        action = $publishedAction
        created_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    $stagePath = Join-Path $Lock.Root ("active-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content (($document | ConvertTo-Json -Depth 6) + "`n")
        Publish-TransactionFile -StagePath $stagePath -TargetPath $Lock.ActiveMarkerPath
        $Lock.ActiveMarkerPublished = $true
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Publish-MaterializerUpgradeState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][ValidateSet("INSTALLING", "SWITCHING", "ROLLBACK", "CURRENT", "CHECK_FAILED")][string]$State,
        [AllowNull()][string]$Message,
        [ValidateSet("COMPLETE", "PENDING")][string]$CleanupState = "COMPLETE"
    )

    $statePath = Join-Path $Lock.Root $script:UpgradeStateName
    Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "materializer upgrade state"
    $boundedMessage = if ([string]::IsNullOrWhiteSpace($Message)) {
        $null
    } elseif ($Message.Length -le 512) {
        $Message
    } else {
        $Message.Substring(0, 512)
    }
    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
        state = $State
        generation_id = $script:GenerationId
        cleanup_state = $CleanupState
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
        message = $boundedMessage
    }
    $stagePath = Join-Path $Lock.Root ("upgrade-state-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content (($document | ConvertTo-Json -Depth 6) + "`n")
        Publish-TransactionFile -StagePath $stagePath -TargetPath $statePath
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Ensure-MaterializerUpgradeStateCurrent {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("COMPLETE", "PENDING")][string]$CleanupState = "COMPLETE"
    )

    $statePath = Join-Path $Lock.Root $script:UpgradeStateName
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        try {
            $state = Assert-MaterializerUpgradeStateArtifact -Path $statePath -ProjectRoot $ProjectRoot
            if ([string]::Equals((Get-RequiredJsonString -Object $state -Name "state" -Label "materializer upgrade state"), "CURRENT", [StringComparison]::Ordinal) -and
                [string]::Equals((Get-RequiredJsonString -Object $state -Name "generation_id" -Label "materializer upgrade state"), $script:GenerationId, [StringComparison]::Ordinal) -and
                [string]::Equals((Get-RequiredJsonString -Object $state -Name "cleanup_state" -Label "materializer upgrade state"), $CleanupState, [StringComparison]::Ordinal)) {
                return $false
            }
        } catch {
            # A bounded Package-owned state artifact is replaced with verified
            # current status only after the full Repair workflow succeeds.
        }
    }
    Publish-MaterializerUpgradeState `
        -Lock $Lock `
        -ProjectRoot $ProjectRoot `
        -State "CURRENT" `
        -Message $Message `
        -CleanupState $CleanupState
    return $true
}

function Assert-MaterializerUpgradeStateArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    Assert-NoReparsePoint -Path $Path -Root $ProjectRoot -Label "materializer upgrade state"
    $stateJson = Read-BoundedJsonDocument -Path $Path -Label "materializer upgrade state" -MaximumBytes (64 * 1024)
    $state = $stateJson.Document
    $stateProjectRoot = Get-RequiredJsonString -Object $state -Name "project_root" -Label "materializer upgrade state"
    $stateName = Get-RequiredJsonString -Object $state -Name "state" -Label "materializer upgrade state"
    $stateGenerationId = Get-RequiredJsonString -Object $state -Name "generation_id" -Label "materializer upgrade state"
    $updatedAtText = Get-RequiredJsonString -Object $state -Name "updated_at_utc" -Label "materializer upgrade state"
    $message = Get-RequiredJsonNullableString -Object $state -Name "message" -Label "materializer upgrade state"
    $cleanupStateProperty = Get-ExactJsonProperty -Object $state -Name "cleanup_state" -Label "materializer upgrade state"
    $cleanupState = "COMPLETE"
    if ($null -ne $cleanupStateProperty) {
        if ($cleanupStateProperty.Value -isnot [string] -or
            [string]$cleanupStateProperty.Value -notin @("COMPLETE", "PENDING")) {
            throw "Materializer upgrade state cleanup_state is invalid."
        }
        $cleanupState = [string]$cleanupStateProperty.Value
    } else {
        Add-Member -InputObject $state -MemberType NoteProperty -Name "cleanup_state" -Value $cleanupState
    }
    [DateTimeOffset]$updatedAt = [DateTimeOffset]::MinValue
    if ((Get-RequiredJsonInt32 -Object $state -Name "schema_version" -Label "materializer upgrade state") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $state -Name "managed_by" -Label "materializer upgrade state"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals([System.IO.Path]::GetFullPath($stateProjectRoot), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -or
        $stateName -notin @("INSTALLING", "SWITCHING", "ROLLBACK", "CURRENT", "CHECK_FAILED") -or
        $stateGenerationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
        ($null -ne $message -and $message.Length -gt 512) -or
        -not [DateTimeOffset]::TryParse(
            $updatedAtText,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$updatedAt)) {
        throw "Materializer upgrade state identity is invalid."
    }
    return $state
}

function Get-PersistedMaterializerCleanupState {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$GenerationId
    )

    $statePath = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:UpgradeStateRelativePath `
        -Label "materializer upgrade state"
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return "COMPLETE"
    }
    $state = Assert-MaterializerUpgradeStateArtifact -Path $statePath -ProjectRoot $ProjectRoot
    if (-not [string]::Equals(
            (Get-RequiredJsonString -Object $state -Name "state" -Label "materializer upgrade state"),
            "CURRENT",
            [StringComparison]::Ordinal) -or
        -not [string]::Equals(
            (Get-RequiredJsonString -Object $state -Name "generation_id" -Label "materializer upgrade state"),
            $GenerationId,
            [StringComparison]::Ordinal)) {
        return "COMPLETE"
    }
    return Get-RequiredJsonString -Object $state -Name "cleanup_state" -Label "materializer upgrade state"
}

function Enter-MaterializerWatchManagementLocks {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    foreach ($providerRoot in $Lock.ProviderRuntimeRoots) {
        $watchRoot = Join-Path $providerRoot "watch"
        Assert-PathInside -Path $watchRoot -Root $ProjectRoot -Label "watch management runtime"
        Assert-NoReparsePoint -Path $watchRoot -Root $ProjectRoot -Label "watch management runtime"
        if (-not (Test-Path -LiteralPath $watchRoot -PathType Container)) {
            continue
        }

        $managementLockPath = Join-Path $watchRoot "management.lock"
        Assert-NoReparsePoint -Path $managementLockPath -Root $ProjectRoot -Label "watch management lock"
        $existedBefore = Test-Path -LiteralPath $managementLockPath -PathType Leaf
        try {
            $stream = [System.IO.File]::Open(
                $managementLockPath,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        } catch {
            Throw-MaterializerError -Message "Watcher management is active for provider runtime: $providerRoot" -ExitCode 4
        }
        $Lock.ManagementLocks.Add([pscustomobject]@{
            Path = $managementLockPath
            Stream = $stream
            ExistedBefore = $existedBefore
        })
    }
}

function Assert-NoLiveHostUseLeases {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($report.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Host-use lease is invalid and requires manual review: $($report.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $report.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed stale $($lease.Owner) host-use lease for PID $($lease.ProcessId)."
    }
    if ($generationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $generationReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed stale generation $($lease.GenerationId) $($lease.Owner) lease for PID $($lease.ProcessId)."
    }

    if ($report.Live.Count -gt 0 -or $generationReport.Live.Count -gt 0) {
        foreach ($lease in $report.Live) {
            Write-Host "[ACTIVE] $lease"
        }
        foreach ($lease in $generationReport.Live) {
            Write-Host "[ACTIVE] $lease"
        }
        Throw-MaterializerError -Message "Host payload mutation is blocked while CodeDB host tooling is active." -ExitCode 4
    }
}

function Assert-ImmutableGenerationFilesystemClosure {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$ExpectedFiles,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        throw "$Label directory does not exist: $Root"
    }
    Assert-NoReparsePoint -Path $Root -Root $Root -Label $Label
    $expectedFileMap = @{}
    $expectedDirectoryMap = @{}
    foreach ($expectedFile in $ExpectedFiles) {
        $relativePath = ConvertTo-SafeRelativePath -Path $expectedFile -Label "$Label file"
        if ($expectedFileMap.ContainsKey($relativePath)) {
            throw "$Label contains a duplicate expected file: $relativePath"
        }
        $expectedFileMap[$relativePath] = $true
        $parent = [System.IO.Path]::GetDirectoryName($relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        while (-not [string]::IsNullOrWhiteSpace($parent)) {
            $normalizedParent = $parent.Replace('\', '/')
            $expectedDirectoryMap[$normalizedParent] = $true
            $parent = [System.IO.Path]::GetDirectoryName($parent)
        }
    }

    $actualFileCount = 0
    foreach ($item in @(Get-ChildItem -LiteralPath $Root -Force -Recurse)) {
        Assert-NoReparsePoint -Path $item.FullName -Root $Root -Label "$Label content"
        $relativePath = $item.FullName.Substring($Root.TrimEnd('\', '/').Length + 1).Replace('\', '/')
        if ($item.PSIsContainer) {
            if (-not $expectedDirectoryMap.ContainsKey($relativePath)) {
                throw "$Label contains an unexpected directory: $relativePath"
            }
            continue
        }
        $actualFileCount++
        if (-not $expectedFileMap.ContainsKey($relativePath)) {
            throw "$Label contains an unmanifested file: $relativePath"
        }
    }
    if ($actualFileCount -ne $expectedFileMap.Count) {
        throw "$Label file closure is incomplete."
    }
}

function Get-ValidatedPackageOwnedInstalledGeneration {
    param(
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot
    )

    if ($GenerationId -notmatch '^[A-Za-z0-9._-]{1,64}$') { return $null }
    $packageGenerationRoot = ConvertTo-AbsoluteChildPath `
        -Root $PayloadRoot `
        -RelativePath "Generations/$GenerationId" `
        -Label "Package-owned generation"
    $installedGenerationRoot = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath "AIWork/.runtime/codedb/host/generations/$GenerationId" `
        -Label "installed generation"
    if (-not (Test-Path -LiteralPath $packageGenerationRoot -PathType Container) -or
        -not (Test-Path -LiteralPath $installedGenerationRoot -PathType Container)) {
        return $null
    }
    Assert-NoReparsePoint -Path $packageGenerationRoot -Root $PayloadRoot -Label "Package-owned generation"
    Assert-NoReparsePoint -Path $installedGenerationRoot -Root $ProjectRoot -Label "installed generation"

    $packageManifestPath = Join-Path $packageGenerationRoot "generation-manifest.json"
    $installedManifestPath = Join-Path $installedGenerationRoot "generation-manifest.json"
    if (-not (Test-Path -LiteralPath $packageManifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $installedManifestPath -PathType Leaf)) {
        return $null
    }
    Assert-NoReparsePoint -Path $packageManifestPath -Root $packageGenerationRoot -Label "Package-owned generation manifest"
    Assert-NoReparsePoint -Path $installedManifestPath -Root $installedGenerationRoot -Label "installed generation manifest"
    $packageManifestSha256 = Get-FileSha256 -Path $packageManifestPath
    if (-not [string]::Equals($packageManifestSha256, (Get-FileSha256 -Path $installedManifestPath), [StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $manifest = (Read-BoundedJsonDocument -Path $packageManifestPath -Label "Package-owned generation manifest" -MaximumBytes (1024 * 1024)).Document
    $manifestFiles = Get-RequiredJsonArray -Object $manifest -Name "files" -Label "Package-owned generation manifest"
    $packageVersion = Get-RequiredJsonString -Object $manifest -Name "package_version" -Label "Package-owned generation manifest"
    $payloadVersion = Get-RequiredJsonString -Object $manifest -Name "payload_version" -Label "Package-owned generation manifest"
    $payloadSequence = Get-RequiredJsonInt32 -Object $manifest -Name "payload_sequence" -Label "Package-owned generation manifest"
    $bootstrapProtocol = Get-RequiredJsonInt32 -Object $manifest -Name "bootstrap_protocol" -Label "Package-owned generation manifest"
    if ((Get-RequiredJsonInt32 -Object $manifest -Name "schema_version" -Label "Package-owned generation manifest") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $manifest -Name "managed_by" -Label "Package-owned generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $manifest -Name "generation_id" -Label "Package-owned generation manifest"), $GenerationId, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $payloadSequence -lt 1 -or
        $bootstrapProtocol -lt 1 -or $bootstrapProtocol -gt $script:SupportedBootstrapProtocol -or
        $manifestFiles.Count -eq 0) {
        return $null
    }

    $seen = @{}
    $managedFiles = New-Object System.Collections.Generic.List[object]
    $managedFiles.Add([pscustomobject]@{ Path = $installedManifestPath; Sha256 = $packageManifestSha256 }) | Out-Null
    foreach ($entry in $manifestFiles) {
        $null = Assert-JsonObject -Value $entry -Label "Package-owned generation file"
        $relativePath = ConvertTo-SafeRelativePath `
            -Path (Get-RequiredJsonString -Object $entry -Name "path" -Label "Package-owned generation file") `
            -Label "Package-owned generation file"
        $sha256 = (Get-RequiredJsonString -Object $entry -Name "sha256" -Label "Package-owned generation file").ToLowerInvariant()
        if ($sha256 -notmatch '^[0-9a-f]{64}$' -or $seen.ContainsKey($relativePath)) { return $null }
        $seen[$relativePath] = $true
        $packagePath = ConvertTo-AbsoluteChildPath -Root $packageGenerationRoot -RelativePath $relativePath -Label "Package-owned generation file"
        $installedPath = ConvertTo-AbsoluteChildPath -Root $installedGenerationRoot -RelativePath $relativePath -Label "installed generation file"
        Assert-NoReparsePoint -Path $packagePath -Root $packageGenerationRoot -Label "Package-owned generation file"
        Assert-NoReparsePoint -Path $installedPath -Root $installedGenerationRoot -Label "installed generation file"
        if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf) -or
            -not (Test-Path -LiteralPath $installedPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $packagePath), $sha256, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals((Get-FileSha256 -Path $installedPath), $sha256, [StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }
        $managedFiles.Add([pscustomobject]@{ Path = $installedPath; Sha256 = $sha256 }) | Out-Null
    }
    $expectedFiles = @("generation-manifest.json") + @($seen.Keys)
    Assert-ImmutableGenerationFilesystemClosure -Root $packageGenerationRoot -ExpectedFiles $expectedFiles -Label "Package-owned immutable generation"
    Assert-ImmutableGenerationFilesystemClosure -Root $installedGenerationRoot -ExpectedFiles $expectedFiles -Label "installed immutable generation"

    return [pscustomobject]@{
        GenerationId = $GenerationId
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        BootstrapProtocol = $bootstrapProtocol
        GenerationManifestSha256 = $packageManifestSha256
        GenerationRoot = $installedGenerationRoot
        WatchManagerPath = Join-Path $installedGenerationRoot "scripts\manage-codedb-project-watch.ps1"
        ManagedFiles = $managedFiles.ToArray()
    }
}

function Get-ValidatedGenerationWatcherCoordinatorState {
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)]$GenerationReport
    )

    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { return $null }
    $rejection = $null
    try {
        Assert-NoReparsePoint -Path $StatePath -Root $ProjectRoot -Label "generation coordinator state"
        $state = (Read-BoundedJsonDocument -Path $StatePath -Label "generation coordinator state" -MaximumBytes (64 * 1024)).Document
        $generationId = Get-RequiredJsonString -Object $state -Name "generation_id" -Label "generation coordinator state"
        $coordinatorProcessId = Get-RequiredJsonInt32 -Object $state -Name "coordinator_pid" -Label "generation coordinator state"
        $stateRoot = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "root" -Label "generation coordinator state"))
        $stateRuntime = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "runtime" -Label "generation coordinator state"))
        $pipeName = Get-RequiredJsonString -Object $state -Name "pipe_name" -Label "generation coordinator state"
        $authToken = Get-RequiredJsonString -Object $state -Name "auth_token" -Label "generation coordinator state"
        $lifecycleId = Get-RequiredJsonString -Object $state -Name "lifecycle_id" -Label "generation coordinator state"
        $exclusiveLifecycle = Get-RequiredJsonBoolean -Object $state -Name "exclusive_lifecycle" -Label "generation coordinator state"
        $providerProcessId = Get-RequiredJsonInt32 -Object $state -Name "provider_pid" -Label "generation coordinator state"
        $providerExecutable = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "provider_executable" -Label "generation coordinator state"))
        $providerConfig = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "provider_config" -Label "generation coordinator state"))
        $adapterEnabled = Get-RequiredJsonBoolean -Object $state -Name "adapter_enabled" -Label "generation coordinator state"
        $expectedRuntime = [System.IO.Path]::GetFullPath((Split-Path -Parent $StatePath))
        $watchRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $expectedRuntime))
        $providerRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $watchRoot))
        $expectedProviderExecutable = Join-Path $providerRoot "bin\codebase-mcp.exe"
        $expectedProviderConfig = Join-Path $providerRoot "config\codedb-mcp.watch.toml"
        $expectedAdapterManifest = Join-Path $providerRoot "adapter\text-index\manifest.json"
        $expectedPipeHash = Get-TextSha256 -Text ((
            $stateRoot.Replace('\', '/').ToLowerInvariant().TrimEnd('/') + "`n" +
            $stateRuntime.Replace('\', '/').ToLowerInvariant()))
        $expectedPipeName = "\\.\pipe\codedb-watch-$($expectedPipeHash.Substring(0, 20))"
        if ((Get-RequiredJsonInt32 -Object $state -Name "schema_version" -Label "generation coordinator state") -ne 2 -or
            $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
            $coordinatorProcessId -le 0 -or
            $providerProcessId -le 0 -or
            -not [string]::Equals($stateRoot, [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($stateRuntime, $expectedRuntime, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($pipeName, $expectedPipeName, [StringComparison]::Ordinal) -or
            $authToken -notmatch '^[0-9a-fA-F]{48}$' -or
            $lifecycleId -notmatch '^[A-Za-z0-9._-]{1,128}$' -or
            -not $adapterEnabled -or
            -not [string]::Equals($providerExecutable, $expectedProviderExecutable, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($providerConfig, $expectedProviderConfig, [StringComparison]::OrdinalIgnoreCase)) {
            throw "state identity, runtime, pipe, Provider, or lifecycle metadata mismatch"
        }
        foreach ($pathIdentity in @($providerExecutable, $providerConfig, $expectedAdapterManifest)) {
            Assert-PathInside -Path $pathIdentity -Root $ProjectRoot -Label "generation coordinator dependency"
            if (-not (Test-Path -LiteralPath $pathIdentity -PathType Leaf)) {
                throw "required Provider or adapter dependency is missing"
            }
        }

        $selectedGeneration = Get-ValidatedPackageOwnedInstalledGeneration `
            -GenerationId $generationId `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $PayloadRoot
        if ($null -eq $selectedGeneration) { throw "Package and installed immutable-generation closures do not match" }
        $matchingPointers = New-Object System.Collections.Generic.List[object]
        foreach ($pointerRelativePath in @($script:CurrentPointerRelativePath, $script:LastKnownGoodPointerRelativePath)) {
            $pointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $pointerRelativePath -Label "generation watcher selection pointer"
            if (-not (Test-Path -LiteralPath $pointerPath -PathType Leaf)) { continue }
            try {
                $pointerSelection = Get-ValidatedInstalledGenerationPointer -PointerPath $pointerPath -ProjectRoot $ProjectRoot
            } catch {
                continue
            }
            if ($null -ne $pointerSelection -and
                [string]::Equals($pointerSelection.GenerationId, $selectedGeneration.GenerationId, [StringComparison]::Ordinal) -and
                [string]::Equals($pointerSelection.PackageVersion, $selectedGeneration.PackageVersion, [StringComparison]::Ordinal) -and
                [string]::Equals($pointerSelection.PayloadVersion, $selectedGeneration.PayloadVersion, [StringComparison]::Ordinal) -and
                $pointerSelection.PayloadSequence -eq $selectedGeneration.PayloadSequence -and
                $pointerSelection.BootstrapProtocol -eq $selectedGeneration.BootstrapProtocol -and
                [string]::Equals($pointerSelection.GenerationManifestSha256, $selectedGeneration.GenerationManifestSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $matchingPointers.Add($pointerSelection) | Out-Null
            }
        }
        if ($matchingPointers.Count -eq 0) { throw "no validated current or last-known-good pointer selects this immutable generation" }
        $watchManagerPath = Join-Path $selectedGeneration.GenerationRoot "scripts\manage-codedb-project-watch.ps1"
        $coordinatorPath = Join-Path $selectedGeneration.GenerationRoot "coordinator\codedb-watch-coordinator.mjs"
        $managedPathMap = @{}
        foreach ($managedFile in $selectedGeneration.ManagedFiles) {
            $managedPathMap[[System.IO.Path]::GetFullPath($managedFile.Path)] = $managedFile.Sha256
        }
        if (-not $managedPathMap.ContainsKey([System.IO.Path]::GetFullPath($watchManagerPath)) -or
            -not $managedPathMap.ContainsKey([System.IO.Path]::GetFullPath($coordinatorPath))) {
            throw "watch manager or coordinator is absent from the authenticated generation manifest"
        }
        $expectedFlatAdapterBuilder = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1" -Label "adapter builder alias"
        $expectedFlatAdapterWorker = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1" -Label "adapter worker alias"
        $expectedGenerationAdapterBuilder = Join-Path $selectedGeneration.GenerationRoot "scripts\build-codedb-project-text-adapter.ps1"
        $expectedGenerationAdapterWorker = Join-Path $selectedGeneration.GenerationRoot "scripts\run-codedb-project-text-adapter-worker.ps1"
        $adapterBuilder = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "adapter_builder" -Label "generation coordinator state"))
        $adapterWorker = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "adapter_worker" -Label "generation coordinator state"))
        $generationAdapterBuilder = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "generation_adapter_builder" -Label "generation coordinator state"))
        $generationAdapterWorker = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "generation_adapter_worker" -Label "generation coordinator state"))
        $adapterManifest = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "adapter_manifest" -Label "generation coordinator state"))
        if (-not [string]::Equals($adapterBuilder, $expectedFlatAdapterBuilder, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($adapterWorker, $expectedFlatAdapterWorker, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($generationAdapterBuilder, $expectedGenerationAdapterBuilder, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($generationAdapterWorker, $expectedGenerationAdapterWorker, [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($adapterManifest, $expectedAdapterManifest, [StringComparison]::OrdinalIgnoreCase) -or
            -not $managedPathMap.ContainsKey($generationAdapterBuilder) -or
            -not $managedPathMap.ContainsKey($generationAdapterWorker)) {
            throw "adapter aliases or immutable-generation adapter paths do not match coordinator state"
        }

        $matchingGenerationLeases = @($GenerationReport.LiveDetails | Where-Object {
            [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal) -and
            $_.ProcessId -eq $coordinatorProcessId -and
            [string]::Equals([string]$_.GenerationId, $generationId, [StringComparison]::Ordinal)
        })
        if ($matchingGenerationLeases.Count -ne 1) {
            throw "generation watcher lease does not uniquely match coordinator PID and generation"
        }

        $commandIdentity = Get-MaterializerWindowsProcessCommandIdentity -ProcessId $coordinatorProcessId
        if ($null -eq $commandIdentity -or -not (Test-MaterializerExactGenerationCoordinatorCommand `
            -ProcessIdentity $commandIdentity `
            -CoordinatorPath $coordinatorPath `
            -GenerationId $generationId `
            -ProjectRoot $stateRoot `
            -Runtime $stateRuntime `
            -ProviderExecutable $providerExecutable `
            -ProviderConfig $providerConfig `
            -LifecycleId $lifecycleId `
            -ExclusiveLifecycle ([bool]$exclusiveLifecycle) `
            -AdapterBuilder $generationAdapterBuilder `
            -AdapterWorker $generationAdapterWorker `
            -AdapterManifest $adapterManifest)) {
            throw "coordinator executable or argv does not match the immutable-generation launch contract"
        }
        $providerCommandIdentity = Get-MaterializerWindowsProcessCommandIdentity -ProcessId $providerProcessId
        if ($null -eq $providerCommandIdentity -or -not (Test-MaterializerExactProviderCommand `
            -ProcessIdentity $providerCommandIdentity `
            -ProviderExecutable $providerExecutable `
            -ProviderConfig $providerConfig `
            -ProjectRoot $stateRoot)) {
            throw "Provider executable or argv does not match the coordinator state"
        }
        foreach ($adapterProcess in @(
            [pscustomobject]@{ Field = "adapter_worker_pid"; RequiredPath = $generationAdapterWorker; SecondPath = $generationAdapterBuilder },
            [pscustomobject]@{ Field = "adapter_build_pid"; RequiredPath = $generationAdapterBuilder; SecondPath = $null }
        )) {
            $adapterProcessId = Get-RequiredJsonNullableInt32 -Object $state -Name $adapterProcess.Field -Label "generation coordinator state"
            if ($null -eq $adapterProcessId) {
                continue
            }
            if ($adapterProcessId -le 0) {
                throw "adapter process PID is invalid"
            }
            $adapterCommandIdentity = Get-MaterializerWindowsProcessCommandIdentity -ProcessId $adapterProcessId
            $adapterKind = if ([string]::Equals($adapterProcess.Field, "adapter_worker_pid", [StringComparison]::Ordinal)) { "Worker" } else { "Builder" }
            if ($null -eq $adapterCommandIdentity -or -not (Test-MaterializerExactAdapterCommand `
                -ProcessIdentity $adapterCommandIdentity `
                -Kind $adapterKind `
                -BuilderPath $generationAdapterBuilder `
                -WorkerPath $generationAdapterWorker)) {
                throw "adapter $adapterKind executable or argv does not match the coordinator state"
            }
        }

        $statusRequestFailure = $null
        $authenticatedStatus = Get-MaterializerAuthenticatedCoordinatorStatus `
            -PipeName $pipeName `
            -AuthToken $authToken `
            -Failure ([ref]$statusRequestFailure)
        $statusFailure = $null
        if ($null -eq $authenticatedStatus -or
            -not (Test-MaterializerCoordinatorStatusIdentity -State $state -Status $authenticatedStatus -Failure ([ref]$statusFailure))) {
            $statusDetail = if (-not [string]::IsNullOrWhiteSpace($statusRequestFailure)) {
                $statusRequestFailure
            } elseif ([string]::IsNullOrWhiteSpace($statusFailure)) {
                "status request failed"
            } else {
                $statusFailure
            }
            throw "authenticated coordinator status does not match the validated state: $statusDetail"
        }

        return [pscustomobject]@{
            Rejected = $false
            Rejection = $null
            GenerationId = $generationId
            ProcessId = $coordinatorProcessId
            LeasePath = [string]$matchingGenerationLeases[0].Path
            State = $state
            SelectedGeneration = $selectedGeneration
        }
    } catch {
        $rejection = $_.Exception.Message
        return [pscustomobject]@{
            Rejected = $true
            Rejection = $rejection
            StatePath = $StatePath
        }
    }
}

function Assert-NoLiveLegacyWatcherState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$PayloadRoot,
        [switch]$AllowGenerationOwnedWatcher,
        [AllowNull()][ref]$RetainedGenerationWatchers
    )

    $liveProcesses = New-Object System.Collections.Generic.List[string]
    $generationReport = $null
    $validatedGenerationWatcherLeases = @{}
    $validatedGenerationWatchers = New-Object System.Collections.Generic.List[object]
    if ($AllowGenerationOwnedWatcher) {
        if ([string]::IsNullOrWhiteSpace($PayloadRoot)) {
            Throw-MaterializerError -Message "Package payload root is required to authenticate an immutable-generation watcher." -ExitCode 7
        }
        $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
        if ($generationReport.Invalid.Count -gt 0) {
            Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
        }
    }
    foreach ($providerRoot in $Lock.ProviderRuntimeRoots) {
        $statePath = Join-Path $providerRoot "watch\coordinator\coordinator-state.json"
        Assert-PathInside -Path $statePath -Root $ProjectRoot -Label "coordinator state"
        if (-not (Test-Path -LiteralPath $statePath)) {
            continue
        }
        if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
            Throw-MaterializerError -Message "Coordinator state is not a file: $statePath" -ExitCode 7
        }
        Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "coordinator state"
        try {
            $state = (Read-BoundedJsonDocument -Path $statePath -Label "coordinator state" -MaximumBytes (64 * 1024)).Document
        } catch {
            Throw-MaterializerError -Message "Coordinator state is invalid and requires manual review: $statePath" -ExitCode 7
        }

        $generationOwnedWatcher = $null
        if ($AllowGenerationOwnedWatcher) {
            $generationOwnedWatcher = Get-ValidatedGenerationWatcherCoordinatorState `
                -StatePath $statePath `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $PayloadRoot `
                -GenerationReport $generationReport
        }
        if ($null -ne $generationOwnedWatcher -and -not $generationOwnedWatcher.Rejected) {
            if ($validatedGenerationWatcherLeases.ContainsKey($generationOwnedWatcher.LeasePath)) {
                Throw-MaterializerError -Message "Multiple coordinator states claim the same immutable-generation watcher lease." -ExitCode 4
            }
            $validatedGenerationWatcherLeases[$generationOwnedWatcher.LeasePath] = $true
            $validatedGenerationWatchers.Add($generationOwnedWatcher) | Out-Null
            Write-Host "[RETAINED] generation $($generationOwnedWatcher.GenerationId) watcher PID $($generationOwnedWatcher.ProcessId) keeps its immutable Host closure."
            continue
        }
        if ($null -ne $generationOwnedWatcher -and $generationOwnedWatcher.Rejected) {
            Write-Host "[ACTIVE] unvalidated generation watcher state $statePath ($($generationOwnedWatcher.Rejection))"
        }

        foreach ($field in @("coordinator_pid", "provider_pid", "adapter_worker_pid", "adapter_build_pid")) {
            try {
                $processId = Get-OptionalJsonNullableInt32 -Object $state -Name $field -Label "coordinator state"
            } catch {
                Throw-MaterializerError -Message "Coordinator state has an invalid ${field}: $statePath" -ExitCode 7
            }
            if ($null -eq $processId) { continue }
            if ($processId -le 0) {
                Throw-MaterializerError -Message "Coordinator state has an invalid ${field}: $statePath" -ExitCode 7
            }
            if (Test-MaterializerProcessAlive -ProcessId $processId) {
                $liveProcesses.Add("$field PID $processId in $providerRoot")
            }
        }
    }

    if ($AllowGenerationOwnedWatcher) {
        foreach ($watcherLease in @($generationReport.LiveDetails | Where-Object {
            [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal)
        })) {
            if (-not $validatedGenerationWatcherLeases.ContainsKey([string]$watcherLease.Path)) {
                $liveProcesses.Add("unvalidated generation $($watcherLease.GenerationId) watcher PID $($watcherLease.ProcessId)")
            }
        }
    }

    if ($liveProcesses.Count -gt 0) {
        foreach ($process in $liveProcesses) {
            Write-Host "[ACTIVE] $process"
        }
        Throw-MaterializerError -Message "Host payload mutation is blocked by a live watcher process." -ExitCode 4
    }
    if ($null -ne $RetainedGenerationWatchers) {
        $RetainedGenerationWatchers.Value = @($validatedGenerationWatchers.ToArray())
    }
}

function Test-InstalledMarkerAdvertisesHostUseGate {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        return $false
    }
    try {
        Assert-NoReparsePoint -Path $MarkerPath -Root $ProjectRoot -Label "installed payload marker"
        $marker = (Read-BoundedJsonDocument -Path $MarkerPath -Label "installed payload marker" -MaximumBytes (1024 * 1024)).Document
        return [string]::Equals((Get-RequiredJsonString -Object $marker -Name "managed_by" -Label "installed payload marker"), $script:ManagedBy, [StringComparison]::Ordinal) -and
            (Get-RequiredJsonInt32 -Object $marker -Name "host_use_gate_version" -Label "installed payload marker") -ge $script:HostUseGateVersion
    } catch {
        return $false
    }
}

function Assert-LegacyMcpBoundary {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $wrapperPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs" -Label "CodeDB wrapper"
    if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf) -or
        (Test-InstalledMarkerAdvertisesHostUseGate -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot)) {
        return
    }
    Assert-NoReparsePoint -Path $wrapperPath -Root $ProjectRoot -Label "CodeDB wrapper"
    if ($Action -notin @("Sync", "Remove", "Repair")) {
        Throw-MaterializerError -Message "A legacy or unowned MCP wrapper exists without host-use leases and requires a confirmed CodeDB recovery action." -ExitCode 4
    }
    if (-not $PocFixture -and -not $ConfirmedProjectMutation -and $Action -ne "Repair") {
        Throw-MaterializerError -Message "A legacy or unowned MCP wrapper requires the Package Manager's second-level project mutation confirmation." -ExitCode 4
    }
    Write-Host "[CONFIRMED] The project-scoped action may replace the recognized wrapper; external MCP clients will not be terminated."
}

function Complete-MaterializerHostUseGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $Lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
    Enter-MaterializerWatchManagementLocks -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveHostUseLeases -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveLegacyWatcherState -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-LegacyMcpBoundary -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
}

function Get-ValidatedLegacyWatcherCoordinatorState {
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Marker
    )

    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) {
        Throw-MaterializerError -Message "Legacy coordinator state is not a regular file: $StatePath" -ExitCode 7
    }
    Assert-NoReparsePoint -Path $StatePath -Root $ProjectRoot -Label "legacy coordinator state"
    try {
        $reviewedIdentity = Assert-ReviewedLegacyFlatPayloadClosure -Marker $Marker -ProjectRoot $ProjectRoot
        $requiredFlatTargets = @(
            "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs",
            "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1",
            "AIWork/codedb/scripts/manage-codedb-project-watch.ps1",
            "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1"
        )
        foreach ($target in $requiredFlatTargets) {
            if (-not $Marker.AllMap.ContainsKey($target)) {
                throw "Reviewed legacy marker omits required watcher executable closure: $target"
            }
        }

        $state = (Read-BoundedJsonDocument -Path $StatePath -Label "legacy coordinator state" -MaximumBytes (64 * 1024)).Document
        $schemaVersion = Get-RequiredJsonInt32 -Object $state -Name "schema_version" -Label "legacy coordinator state"
        $coordinatorProcessId = Get-RequiredJsonInt32 -Object $state -Name "coordinator_pid" -Label "legacy coordinator state"
        $stateRoot = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "root" -Label "legacy coordinator state"))
        $stateRuntime = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "runtime" -Label "legacy coordinator state"))
        $pipeName = Get-RequiredJsonString -Object $state -Name "pipe_name" -Label "legacy coordinator state"
        $authToken = Get-RequiredJsonString -Object $state -Name "auth_token" -Label "legacy coordinator state"
        $expectedRuntime = [System.IO.Path]::GetFullPath((Split-Path -Parent $StatePath))
        $watchRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $expectedRuntime))
        $providerRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $watchRoot))
        $lifecycleId = Get-RequiredJsonString -Object $state -Name "lifecycle_id" -Label "legacy coordinator state"
        $exclusiveLifecycle = Get-RequiredJsonBoolean -Object $state -Name "exclusive_lifecycle" -Label "legacy coordinator state"
        $providerProcessId = Get-RequiredJsonInt32 -Object $state -Name "provider_pid" -Label "legacy coordinator state"
        $providerExecutable = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "provider_executable" -Label "legacy coordinator state"))
        $providerConfig = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "provider_config" -Label "legacy coordinator state"))
        $adapterEnabled = Get-RequiredJsonBoolean -Object $state -Name "adapter_enabled" -Label "legacy coordinator state"
        $adapterBuilder = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "adapter_builder" -Label "legacy coordinator state"))
        $adapterWorker = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "adapter_worker" -Label "legacy coordinator state"))
        $adapterManifest = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "adapter_manifest" -Label "legacy coordinator state"))
        $expectedProviderExecutable = Join-Path $providerRoot "bin\codebase-mcp.exe"
        $expectedProviderConfig = Join-Path $providerRoot "config\codedb-mcp.watch.toml"
        $expectedAdapterManifest = Join-Path $providerRoot "adapter\text-index\manifest.json"
        $coordinatorPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs" -Label "reviewed legacy coordinator"
        $expectedAdapterBuilder = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1" -Label "reviewed legacy adapter builder"
        $expectedAdapterWorker = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1" -Label "reviewed legacy adapter worker"
        $expectedPipeHash = Get-TextSha256 -Text (($stateRoot.Replace('\', '/').ToLowerInvariant().TrimEnd('/') + "`n" + $stateRuntime.Replace('\', '/').ToLowerInvariant()))
        $expectedPipeName = "\\.\pipe\codedb-watch-$($expectedPipeHash.Substring(0, 20))"
        $valid = $schemaVersion -eq 1 -and
            $coordinatorProcessId -gt 0 -and
            $providerProcessId -gt 0 -and
            [string]::Equals($stateRoot, [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($stateRuntime, $expectedRuntime, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($pipeName, $expectedPipeName, [StringComparison]::Ordinal) -and
            $authToken -cmatch '^[0-9a-fA-F]{48}$' -and
            $lifecycleId -cmatch '^[A-Za-z0-9._-]{1,128}$' -and
            $adapterEnabled -and
            [string]::Equals($providerExecutable, $expectedProviderExecutable, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($providerConfig, $expectedProviderConfig, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($adapterBuilder, $expectedAdapterBuilder, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($adapterWorker, $expectedAdapterWorker, [StringComparison]::OrdinalIgnoreCase) -and
            [string]::Equals($adapterManifest, $expectedAdapterManifest, [StringComparison]::OrdinalIgnoreCase)
        if (-not $valid) { throw "Legacy coordinator state identity values do not match the reviewed closure." }

        foreach ($pathIdentity in @(
            $providerExecutable, $providerConfig, $adapterManifest, $coordinatorPath, $adapterBuilder, $adapterWorker
        )) {
            Assert-PathInside -Path $pathIdentity -Root $ProjectRoot -Label "legacy coordinator dependency"
            Assert-NoReparsePoint -Path $pathIdentity -Root $ProjectRoot -Label "legacy coordinator dependency"
            if (-not (Test-Path -LiteralPath $pathIdentity -PathType Leaf)) {
                throw "Legacy coordinator dependency is missing: $pathIdentity"
            }
        }

        $coordinatorCommand = Get-MaterializerWindowsProcessCommandIdentity -ProcessId $coordinatorProcessId
        if ($null -eq $coordinatorCommand -or -not (Test-MaterializerExactLegacyCoordinatorCommand `
            -ProcessIdentity $coordinatorCommand `
            -CoordinatorPath $coordinatorPath `
            -ProjectRoot $stateRoot `
            -Runtime $stateRuntime `
            -ProviderExecutable $providerExecutable `
            -ProviderConfig $providerConfig `
            -LifecycleId $lifecycleId `
            -ExclusiveLifecycle ([bool]$exclusiveLifecycle) `
            -AdapterBuilder $adapterBuilder `
            -AdapterWorker $adapterWorker `
            -AdapterManifest $adapterManifest)) {
            throw "Legacy coordinator executable or argv does not match the reviewed watcher closure."
        }
        $providerCommand = Get-MaterializerWindowsProcessCommandIdentity -ProcessId $providerProcessId
        if ($null -eq $providerCommand -or -not (Test-MaterializerExactProviderCommand `
            -ProcessIdentity $providerCommand `
            -ProviderExecutable $providerExecutable `
            -ProviderConfig $providerConfig `
            -ProjectRoot $stateRoot)) {
            throw "Legacy Provider executable or argv does not match the recorded watcher closure."
        }
        foreach ($adapterProcess in @(
            [pscustomobject]@{ Field = "adapter_worker_pid"; Kind = "Worker"; Required = $true },
            [pscustomobject]@{ Field = "adapter_build_pid"; Kind = "Builder"; Required = $false }
        )) {
            $adapterProcessId = Get-RequiredJsonNullableInt32 -Object $state -Name $adapterProcess.Field -Label "legacy coordinator state"
            if ($null -eq $adapterProcessId) {
                if ($adapterProcess.Required) { throw "Legacy adapter worker PID is missing." }
                continue
            }
            if ($adapterProcessId -le 0) { throw "Legacy adapter PID is invalid." }
            $adapterCommand = Get-MaterializerWindowsProcessCommandIdentity -ProcessId $adapterProcessId
            if ($null -eq $adapterCommand -or -not (Test-MaterializerExactAdapterCommand `
                -ProcessIdentity $adapterCommand `
                -Kind $adapterProcess.Kind `
                -BuilderPath $adapterBuilder `
                -WorkerPath $adapterWorker)) {
                throw "Legacy adapter $($adapterProcess.Kind) executable or argv does not match the reviewed watcher closure."
            }
        }

        $authenticatedStatus = Get-MaterializerAuthenticatedCoordinatorStatus -PipeName $pipeName -AuthToken $authToken
        if ($null -eq $authenticatedStatus -or
            -not (Test-MaterializerLegacyCoordinatorStatusIdentity -State $state -Status $authenticatedStatus)) {
            throw "Legacy coordinator authenticated status does not match its state and process closure."
        }
    } catch {
        Throw-MaterializerError -Message "Legacy coordinator state identity or authenticated Stop contract is invalid: $StatePath. $($_.Exception.Message)" -ExitCode 4
    }

    $liveProcesses = New-Object System.Collections.Generic.List[string]
    foreach ($field in @("coordinator_pid", "provider_pid", "adapter_worker_pid", "adapter_build_pid")) {
        $processId = Get-RequiredJsonNullableInt32 -Object $state -Name $field -Label "legacy coordinator state"
        if ($null -eq $processId) { continue }
        if ($processId -le 0) {
            Throw-MaterializerError -Message "Legacy coordinator state has an invalid ${field}: $StatePath" -ExitCode 7
        }
        if (Test-MaterializerProcessAlive -ProcessId $processId) {
            $liveProcesses.Add("$field PID $processId")
        }
    }
    return [pscustomobject]@{
        Path = $StatePath
        Runtime = $stateRuntime
        ProcessId = $coordinatorProcessId
        Sha256 = Get-FileSha256 -Path $StatePath
        LiveProcesses = $liveProcesses.ToArray()
        State = $state
        ReviewedIdentity = $reviewedIdentity
    }
}

function Invoke-PackageOwnedLegacyWatcherStop {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$CoordinatorState
    )

    $clientPath = Join-Path $PSScriptRoot $script:LegacyWatcherStopClientName
    if (-not (Test-Path -LiteralPath $clientPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Package-owned legacy watcher Stop client is missing: $clientPath" -ExitCode 7
    }
    $clientItem = Get-Item -LiteralPath $clientPath -Force
    if (($clientItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        Throw-MaterializerError -Message "Package-owned legacy watcher Stop client is a reparse point: $clientPath" -ExitCode 7
    }
    $nodeCommand = Get-Command node -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $nodeCommand) {
        Throw-MaterializerError -Message "Node.js is required for Package-owned legacy watcher recovery." -ExitCode 4
    }

    $arguments = @(
        $clientPath,
        "--project-root", $ProjectRoot,
        "--runtime", $CoordinatorState.Runtime,
        "--expected-pid", [string]$CoordinatorState.ProcessId,
        "--expected-state-sha256", $CoordinatorState.Sha256
    )
    try {
        $result = Invoke-BoundedNativeProcess -FilePath $nodeCommand.Source -Arguments $arguments
    } catch {
        Throw-MaterializerError -Message "Package-owned legacy watcher Stop client could not start: $($_.Exception.Message)" -ExitCode 4
    }
    foreach ($line in @($result.StandardOutput, $result.StandardError)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
            foreach ($outputLine in @(([string]$line) -split '\r?\n')) {
                if (-not [string]::IsNullOrWhiteSpace($outputLine)) { Write-Host $outputLine }
            }
        }
    }
    if ($result.ExitCode -ne 0 -or $result.TimedOut) {
        Throw-MaterializerError -Message "Package-owned legacy watcher Stop was blocked for PID $($CoordinatorState.ProcessId)." -ExitCode 4
    }
    Add-MaterializerMutationScope -Scope "watcher"
}

function Complete-OwnedLegacyRedeployHostUseGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [AllowNull()][ref]$WatcherStopped
    )

    $Lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
    Enter-MaterializerWatchManagementLocks -Lock $Lock -ProjectRoot $ProjectRoot
    $validatedMarker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    if ($null -eq $validatedMarker) {
        Throw-MaterializerError -Message "Owned legacy redeploy marker disappeared before owner authentication." -ExitCode 4
    }
    $null = Assert-ReviewedLegacyFlatPayloadClosure -Marker $validatedMarker -ProjectRoot $ProjectRoot
    $validatedMarkerSha256 = Get-FileSha256 -Path $MarkerPath
    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($report.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Legacy Host-use lease is invalid and requires manual review: $($report.Invalid[0])" -ExitCode 7
    }
    if ($generationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $report.Live) { Write-Host "[ACTIVE] $lease" }
    foreach ($lease in $generationReport.Live) { Write-Host "[ACTIVE] $lease" }

    $mcpOwners = @($report.LiveDetails | Where-Object { [string]::Equals($_.Owner, "mcp", [StringComparison]::Ordinal) })
    $watcherOwners = @($report.LiveDetails | Where-Object { [string]::Equals($_.Owner, "watcher", [StringComparison]::Ordinal) })
    if ($mcpOwners.Count -gt 0 -or $generationReport.Live.Count -gt 0) {
        Throw-MaterializerError -Message "Owned legacy redeploy is blocked by an MCP client, generation owner, or other owner that the Package must not terminate." -ExitCode 4
    }
    if ($watcherOwners.Count -gt 1) {
        Throw-MaterializerError -Message "Owned legacy redeploy found multiple watcher owners and cannot select one safely." -ExitCode 4
    }
    if ($watcherOwners.Count -eq 0) {
        Assert-NoLiveLegacyWatcherState -Lock $Lock -ProjectRoot $ProjectRoot
    } else {
        $watcher = $watcherOwners[0]
        $matchingStates = New-Object System.Collections.Generic.List[object]
        $otherLiveStates = New-Object System.Collections.Generic.List[string]
        foreach ($providerRoot in $Lock.ProviderRuntimeRoots) {
            $statePath = Join-Path $providerRoot "watch\coordinator\coordinator-state.json"
            Assert-PathInside -Path $statePath -Root $ProjectRoot -Label "legacy coordinator state"
            if (-not (Test-Path -LiteralPath $statePath)) { continue }
            $coordinatorState = Get-ValidatedLegacyWatcherCoordinatorState -StatePath $statePath -ProjectRoot $ProjectRoot -Marker $validatedMarker
            if ($coordinatorState.ProcessId -eq $watcher.ProcessId) {
                $matchingStates.Add($coordinatorState)
            } elseif ($coordinatorState.LiveProcesses.Count -gt 0) {
                $otherLiveStates.Add("$statePath ($($coordinatorState.LiveProcesses -join ', '))")
            }
        }
        if ($otherLiveStates.Count -gt 0) {
            foreach ($state in $otherLiveStates) { Write-Host "[ACTIVE] unrecognized coordinator state $state" }
            Throw-MaterializerError -Message "Owned legacy redeploy found a live coordinator that does not match the single watcher lease." -ExitCode 4
        }
        if ($matchingStates.Count -ne 1) {
            Throw-MaterializerError -Message "Owned legacy redeploy could not correlate the single watcher lease with exactly one authenticated coordinator state." -ExitCode 4
        }

        $recheckedMarker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if ($null -eq $recheckedMarker -or
            -not [string]::Equals((Get-FileSha256 -Path $MarkerPath), $validatedMarkerSha256, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Owned legacy marker changed during Package-owned Stop preflight." -ExitCode 4
        }
        $null = Assert-ReviewedLegacyFlatPayloadClosure -Marker $recheckedMarker -ProjectRoot $ProjectRoot
        $recheckedState = Get-ValidatedLegacyWatcherCoordinatorState -StatePath $matchingStates[0].Path -ProjectRoot $ProjectRoot -Marker $recheckedMarker
        $recheckedReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
        $recheckedGenerationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
        $sameWatcher = @($recheckedReport.LiveDetails | Where-Object {
            [string]::Equals($_.Owner, "watcher", [StringComparison]::Ordinal) -and
            $_.ProcessId -eq $watcher.ProcessId -and
            [string]::Equals($_.Path, $watcher.Path, [StringComparison]::OrdinalIgnoreCase)
        })
        if ($recheckedReport.Invalid.Count -gt 0 -or $recheckedGenerationReport.Invalid.Count -gt 0 -or
            $recheckedReport.LiveDetails.Count -ne 1 -or $sameWatcher.Count -ne 1 -or
            $recheckedGenerationReport.Live.Count -gt 0 -or
            -not [string]::Equals($recheckedState.Sha256, $matchingStates[0].Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Owned legacy watcher ownership changed during Package-owned Stop preflight." -ExitCode 4
        }

        Write-Host "[STOPPING] Requesting authenticated Package-owned Stop for legacy watcher PID $($watcher.ProcessId)."
        Invoke-PackageOwnedLegacyWatcherStop -ProjectRoot $ProjectRoot -CoordinatorState $recheckedState
        if ($null -ne $WatcherStopped) { $WatcherStopped.Value = $true }
        Write-Host "[STOPPED] Legacy watcher PID $($watcher.ProcessId) released its execution closure."
    }

    $finalReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $finalGenerationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($finalReport.Invalid.Count -gt 0 -or $finalGenerationReport.Invalid.Count -gt 0 -or
        $finalReport.Live.Count -gt 0 -or $finalGenerationReport.Live.Count -gt 0) {
        Throw-MaterializerError -Message "Owned legacy redeploy still has an active or invalid owner after Package-owned Stop." -ExitCode 4
    }
    Assert-NoLiveLegacyWatcherState -Lock $Lock -ProjectRoot $ProjectRoot
    foreach ($lease in $finalReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed stale $($lease.Owner) flat Host-use lease for PID $($lease.ProcessId)."
    }
    foreach ($lease in $finalGenerationReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed stale generation $($lease.GenerationId) $($lease.Owner) lease for PID $($lease.ProcessId)."
    }
    Assert-LegacyMcpBoundary -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
    return $watcherOwners.Count -eq 1
}

function Complete-RepairOwnedLegacyWatcherStop {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)]$Watcher
    )

    $validatedMarker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    if ($null -eq $validatedMarker) {
        Throw-MaterializerError -Message "Repair cannot authenticate a legacy watcher without its ownership marker." -ExitCode 4
    }
    $null = Assert-ReviewedLegacyFlatPayloadClosure -Marker $validatedMarker -ProjectRoot $ProjectRoot
    $markerSha256 = Get-FileSha256 -Path $MarkerPath
    $matchingStates = New-Object System.Collections.Generic.List[object]
    $otherLiveStates = New-Object System.Collections.Generic.List[string]
    foreach ($providerRoot in $Lock.ProviderRuntimeRoots) {
        $statePath = Join-Path $providerRoot "watch\coordinator\coordinator-state.json"
        Assert-PathInside -Path $statePath -Root $ProjectRoot -Label "legacy coordinator state"
        if (-not (Test-Path -LiteralPath $statePath)) { continue }
        $coordinatorState = Get-ValidatedLegacyWatcherCoordinatorState `
            -StatePath $statePath `
            -ProjectRoot $ProjectRoot `
            -Marker $validatedMarker
        if ($coordinatorState.ProcessId -eq $Watcher.ProcessId) {
            $matchingStates.Add($coordinatorState)
        } elseif ($coordinatorState.LiveProcesses.Count -gt 0) {
            $otherLiveStates.Add("$statePath ($($coordinatorState.LiveProcesses -join ', '))")
        }
    }
    if ($otherLiveStates.Count -gt 0 -or $matchingStates.Count -ne 1) {
        Throw-MaterializerError -Message "Repair could not correlate the legacy watcher lease with exactly one authenticated Package-owned coordinator." -ExitCode 4
    }

    $recheckedMarker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    if ($null -eq $recheckedMarker -or
        -not [string]::Equals((Get-FileSha256 -Path $MarkerPath), $markerSha256, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Legacy watcher ownership changed during Repair Stop preflight." -ExitCode 4
    }
    $null = Assert-ReviewedLegacyFlatPayloadClosure -Marker $recheckedMarker -ProjectRoot $ProjectRoot
    $recheckedState = Get-ValidatedLegacyWatcherCoordinatorState `
        -StatePath $matchingStates[0].Path `
        -ProjectRoot $ProjectRoot `
        -Marker $recheckedMarker
    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    $recheckedReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $sameWatcher = @($recheckedReport.LiveDetails | Where-Object {
        [string]::Equals($_.Owner, "watcher", [StringComparison]::Ordinal) -and
        $_.ProcessId -eq $Watcher.ProcessId -and
        [string]::Equals($_.Path, $Watcher.Path, [StringComparison]::OrdinalIgnoreCase)
    })
    $otherWatchers = @($recheckedReport.LiveDetails | Where-Object {
        [string]::Equals($_.Owner, "watcher", [StringComparison]::Ordinal) -and
        ($_.ProcessId -ne $Watcher.ProcessId -or
         -not [string]::Equals($_.Path, $Watcher.Path, [StringComparison]::OrdinalIgnoreCase))
    })
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($recheckedReport.Invalid.Count -gt 0 -or $generationReport.Invalid.Count -gt 0 -or
        $sameWatcher.Count -ne 1 -or $otherWatchers.Count -gt 0 -or
        -not [string]::Equals($recheckedState.Sha256, $matchingStates[0].Sha256, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Legacy watcher ownership changed during Repair Stop preflight." -ExitCode 4
    }

    Write-Host "[STOPPING] Requesting authenticated Package-owned Stop for legacy watcher PID $($Watcher.ProcessId)."
    Invoke-PackageOwnedLegacyWatcherStop -ProjectRoot $ProjectRoot -CoordinatorState $recheckedState
    Write-Host "[STOPPED] Legacy watcher PID $($Watcher.ProcessId) released its execution closure."
}

function Complete-RepairFlatHostUseGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot
    )

    $Lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
    Enter-MaterializerWatchManagementLocks -Lock $Lock -ProjectRoot $ProjectRoot
    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    if ($report.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Legacy Host-use lease is invalid and requires manual review: $($report.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $report.Live) { Write-Host "[ACTIVE] $lease" }
    $flatMcpOwners = @(Get-RepairFlatMcpOwners -ProjectRoot $ProjectRoot)
    $watcherOwners = @($report.LiveDetails | Where-Object {
        [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal)
    })
    if ($watcherOwners.Count -gt 1) {
        Throw-MaterializerError -Message "Repair found multiple legacy watcher owners and cannot authenticate one safely." -ExitCode 4
    }
    $legacyWatcherStopped = $false
    if ($watcherOwners.Count -eq 1) {
        $markerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "legacy watcher ownership marker"
        Complete-RepairOwnedLegacyWatcherStop `
            -Lock $Lock `
            -ProjectRoot $ProjectRoot `
            -MarkerPath $markerPath `
            -Watcher $watcherOwners[0]
        $legacyWatcherStopped = $true
    }
    $recheckedFlatReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $remainingWatchers = @($recheckedFlatReport.LiveDetails | Where-Object {
        [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal)
    })
    if ($recheckedFlatReport.Invalid.Count -gt 0 -or $remainingWatchers.Count -gt 0) {
        Throw-MaterializerError -Message "Legacy Host-use ownership changed during stale-lease reclamation." -ExitCode 4
    }
    foreach ($lease in $recheckedFlatReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed proved-stale $($lease.Owner) flat Host-use lease for PID $($lease.ProcessId) ($($lease.Reason))."
    }
    $retainedGenerationWatchers = @()
    Assert-NoLiveLegacyWatcherState `
        -Lock $Lock `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -AllowGenerationOwnedWatcher `
        -RetainedGenerationWatchers ([ref]$retainedGenerationWatchers)
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($generationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
    }
    $generationMcpOwners = @(Get-RepairGenerationMcpOwners `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -GenerationReport $generationReport)
    foreach ($owner in $generationMcpOwners) {
        Write-Host "[RETAINED] generation $($owner.GenerationId) mcp PID $($owner.ProcessId) keeps its immutable Host closure."
    }
    $recheckedGenerationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($recheckedGenerationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation ownership changed during stale-lease reclamation." -ExitCode 4
    }
    foreach ($lease in $recheckedGenerationReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed proved-stale generation $($lease.GenerationId) $($lease.Owner) lease for PID $($lease.ProcessId)."
    }
    return [pscustomobject]@{
        RetainedGenerationWatchers = @($retainedGenerationWatchers)
        RetainedGenerationMcps = @($generationMcpOwners)
        RetainedFlatMcps = @($flatMcpOwners)
        LegacyWatcherStopped = $legacyWatcherStopped
    }
}

function Complete-UninstallGenerationWatcherStop {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)]$Watcher
    )

    $runtime = [System.IO.Path]::GetFullPath((Get-RequiredJsonString `
        -Object $Watcher.State `
        -Name "runtime" `
        -Label "generation coordinator state"))
    $statePath = Join-Path $runtime "coordinator-state.json"
    Assert-PathInside -Path $statePath -Root $ProjectRoot -Label "generation coordinator state"
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    $rechecked = Get-ValidatedGenerationWatcherCoordinatorState `
        -StatePath $statePath `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -GenerationReport $generationReport
    if ($null -eq $rechecked -or $rechecked.Rejected -or
        $rechecked.ProcessId -ne $Watcher.ProcessId -or
        -not [string]::Equals([string]$rechecked.GenerationId, [string]$Watcher.GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$rechecked.LeasePath, [string]$Watcher.LeasePath, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Uninstall generation watcher ownership changed before Package-owned Stop." -ExitCode 4
    }

    $coordinatorState = [pscustomobject]@{
        ProcessId = [int]$rechecked.ProcessId
        Runtime = $runtime
        Sha256 = Get-FileSha256 -Path $statePath
    }
    Write-Host "[STOPPING] Requesting authenticated Package-owned Stop for generation $($rechecked.GenerationId) watcher PID $($rechecked.ProcessId)."
    Invoke-PackageOwnedLegacyWatcherStop -ProjectRoot $ProjectRoot -CoordinatorState $coordinatorState

    $finalReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($finalReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation ownership became invalid after Package-owned watcher Stop." -ExitCode 4
    }
    foreach ($stale in $finalReport.Stale) {
        Remove-Item -LiteralPath $stale.Path -Force
        Write-Host "[RECOVERED] Removed proved-stale generation $($stale.GenerationId) $($stale.Owner) lease for PID $($stale.ProcessId)."
    }
    $remainingReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($remainingReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation ownership became invalid while verifying Package-owned watcher Stop." -ExitCode 4
    }
    $remaining = @($remainingReport.LiveDetails | Where-Object {
        [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal) -and
        $_.ProcessId -eq $Watcher.ProcessId -and
        [string]::Equals([string]$_.GenerationId, [string]$Watcher.GenerationId, [StringComparison]::Ordinal)
    })
    if ($remaining.Count -gt 0) {
        Throw-MaterializerError -Message "Authenticated generation watcher retained its lease after Package-owned Stop." -ExitCode 4
    }
    Write-Host "[STOPPED] Generation $($rechecked.GenerationId) watcher PID $($rechecked.ProcessId) released its execution closure."
}

function Test-RepairPathIntersectsGenerationRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$GenerationRoot
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $fullGenerationRoot = [System.IO.Path]::GetFullPath($GenerationRoot).TrimEnd('\', '/')
    if ([string]::Equals($fullPath, $fullGenerationRoot, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    $pathPrefix = $fullPath + [System.IO.Path]::DirectorySeparatorChar
    $generationPrefix = $fullGenerationRoot + [System.IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith($generationPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        $fullGenerationRoot.StartsWith($pathPrefix, [StringComparison]::OrdinalIgnoreCase)
}

function Get-RepairGenerationMcpOwners {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [AllowNull()]$GenerationReport
    )

    if ($null -eq $GenerationReport) {
        $GenerationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    }
    if ($GenerationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($GenerationReport.Invalid[0])" -ExitCode 7
    }

    $owners = New-Object System.Collections.Generic.List[object]
    $validatedGenerations = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($lease in @($GenerationReport.LiveDetails | Where-Object {
        [string]::Equals([string]$_.Owner, "mcp", [StringComparison]::Ordinal)
    })) {
        $generationId = [string]$lease.GenerationId
        if (-not $validatedGenerations.ContainsKey($generationId)) {
            try {
                $validatedGeneration = Get-ValidatedPackageOwnedInstalledGeneration `
                    -GenerationId $generationId `
                    -ProjectRoot $ProjectRoot `
                    -PayloadRoot $PayloadRoot
            } catch {
                Throw-MaterializerError `
                    -Message "Generation MCP lease does not prove a safe Package-owned immutable closure: $generationId. $($_.Exception.Message)" `
                    -ExitCode 7
            }
            if ($null -eq $validatedGeneration) {
                Throw-MaterializerError `
                    -Message "Generation MCP lease does not prove a safe Package-owned immutable closure: $generationId." `
                    -ExitCode 7
            }
            $validatedGenerations.Add($generationId, $validatedGeneration)
        }
        $generation = $validatedGenerations[$generationId]
        $owners.Add([pscustomobject]@{
            GenerationId = $generationId
            ProcessId = [int]$lease.ProcessId
            LeasePath = [string]$lease.Path
            GenerationRoot = [string]$generation.GenerationRoot
        }) | Out-Null
    }
    return $owners.ToArray()
}

function Get-RepairFlatMcpOwners {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $leaseRoot = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath "$($script:RuntimeRelativePath)/$($script:HostUseLeaseDirectoryName)" `
        -Label "flat Host-use lease root"
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    if ($report.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Legacy Host-use lease is invalid and requires manual review: $($report.Invalid[0])" -ExitCode 7
    }
    $mcpLeases = @($report.LiveDetails | Where-Object {
        [string]::Equals([string]$_.Owner, "mcp", [StringComparison]::Ordinal)
    })
    if ($mcpLeases.Count -eq 0) {
        return @()
    }
    $indeterminateMcpLease = @($mcpLeases | Where-Object {
        -not [string]::Equals([string]$_.ProcessIdentityState, "Live", [StringComparison]::Ordinal)
    } | Select-Object -First 1)
    if ($indeterminateMcpLease.Count -gt 0) {
        Throw-MaterializerError `
            -Message "A flat MCP lease process start identity is unavailable and cannot be retained safely: PID $($indeterminateMcpLease[0].ProcessId)." `
            -ExitCode 4
    }

    $markerPath = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:MarkerRelativePath `
        -Label "flat MCP ownership marker"
    $marker = Read-InstalledMarker -MarkerPath $markerPath -ProjectRoot $ProjectRoot
    if ($null -eq $marker -or $marker.HostUseGateVersion -lt 1) {
        Throw-MaterializerError -Message "A live flat MCP lease has no validated CodeDB ownership marker." -ExitCode 4
    }
    if ($marker.SchemaVersion -eq 1) {
        $null = Assert-ReviewedLegacyFlatPayloadClosure -Marker $marker -ProjectRoot $ProjectRoot
    }
    foreach ($file in $marker.Files) {
        if (-not $file.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $file.TargetPath), $file.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "A live flat MCP lease does not have a byte-exact owned execution closure: $($file.Target)" -ExitCode 4
        }
    }
    $closurePaths = @($marker.Files | ForEach-Object { [string]$_.TargetPath })
    if ($closurePaths.Count -eq 0) {
        Throw-MaterializerError -Message "A live flat MCP lease has an empty execution closure." -ExitCode 4
    }

    return @($mcpLeases | ForEach-Object {
        [pscustomobject]@{
            ProcessId = [int]$_.ProcessId
            LeasePath = [string]$_.Path
            ClosurePaths = $closurePaths
            MarkerPath = $markerPath
            PayloadVersion = [string]$marker.PayloadVersion
        }
    })
}

function Assert-RepairMutationPathsDoNotConflictWithGenerationMcp {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Paths,
        [Parameter(Mandatory = $true)][string]$Boundary
    )

    $owners = @(Get-RepairGenerationMcpOwners -ProjectRoot $ProjectRoot -PayloadRoot $PayloadRoot)
    $flatOwners = @(Get-RepairFlatMcpOwners -ProjectRoot $ProjectRoot)
    foreach ($pathValue in $Paths) {
        $path = [System.IO.Path]::GetFullPath([string]$pathValue)
        Assert-PathInside -Path $path -Root $ProjectRoot -Label "Repair $Boundary target"
        foreach ($owner in $owners) {
            if (-not (Test-RepairPathIntersectsGenerationRoot -Path $path -GenerationRoot $owner.GenerationRoot)) {
                continue
            }
            Write-Host "[ACTIVE] generation $($owner.GenerationId) mcp PID $($owner.ProcessId) protects $($owner.GenerationRoot)"
            Throw-MaterializerError `
                -Message "Repair $Boundary would mutate generation $($owner.GenerationId) while MCP PID $($owner.ProcessId) owns its immutable Host closure." `
                -ExitCode 4
        }
        foreach ($owner in $flatOwners) {
            foreach ($closurePath in $owner.ClosurePaths) {
                if (-not (Test-RepairPathIntersectsGenerationRoot -Path $path -GenerationRoot $closurePath)) {
                    continue
                }
                Write-Host "[ACTIVE] mcp PID $($owner.ProcessId)"
                Write-Host "[CONFLICT] Retained flat MCP closure intersects $closurePath."
                Throw-MaterializerError `
                    -Message "Repair $Boundary would mutate the retained flat MCP closure at $closurePath while PID $($owner.ProcessId) is active." `
                    -ExitCode 4
            }
        }
    }
    return [pscustomobject]@{ GenerationMcps = $owners; FlatMcps = $flatOwners }
}

function Assert-RepairOwnerGateStable {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$ExpectedGenerationWatchers,
        [AllowNull()][ref]$RetainedGenerationWatchers,
        [AllowNull()][ref]$RetainedGenerationMcps,
        [AllowNull()][ref]$RetainedFlatMcps
    )

    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    $flatReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    if ($flatReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Legacy Host-use lease is invalid and requires manual review: $($flatReport.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $flatReport.Live) { Write-Host "[ACTIVE] $lease" }
    $flatWatcherOwners = @($flatReport.LiveDetails | Where-Object {
        [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal)
    })
    if ($flatWatcherOwners.Count -gt 0) {
        Throw-MaterializerError -Message "Repair found a legacy watcher after its authenticated owner gate." -ExitCode 4
    }
    $flatMcpOwners = @(Get-RepairFlatMcpOwners -ProjectRoot $ProjectRoot)

    $validatedWatchers = @()
    Assert-NoLiveLegacyWatcherState `
        -Lock $Lock `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -AllowGenerationOwnedWatcher `
        -RetainedGenerationWatchers ([ref]$validatedWatchers)
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($generationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
    }
    $generationMcpOwners = @(Get-RepairGenerationMcpOwners `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -GenerationReport $generationReport)
    foreach ($owner in $generationMcpOwners) {
        Write-Host "[RETAINED] generation $($owner.GenerationId) mcp PID $($owner.ProcessId) keeps its immutable Host closure."
    }

    $expectedKeys = @{}
    foreach ($watcher in $ExpectedGenerationWatchers) {
        $expectedKeys["$($watcher.GenerationId)|$($watcher.ProcessId)|$($watcher.LeasePath)"] = $true
    }
    foreach ($watcher in $validatedWatchers) {
        $key = "$($watcher.GenerationId)|$($watcher.ProcessId)|$($watcher.LeasePath)"
        if (-not $expectedKeys.ContainsKey($key)) {
            Throw-MaterializerError -Message "Repair watcher ownership changed after its initial safety gate." -ExitCode 4
        }
    }
    if ($null -ne $RetainedGenerationWatchers) {
        $RetainedGenerationWatchers.Value = @($validatedWatchers)
    }
    if ($null -ne $RetainedGenerationMcps) {
        $RetainedGenerationMcps.Value = @($generationMcpOwners)
    }
    if ($null -ne $RetainedFlatMcps) {
        $RetainedFlatMcps.Value = @($flatMcpOwners)
    }
}

function Initialize-MaterializerUpgradeGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$MarkerAction
    )

    Assert-ExistingMaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
    Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot -MarkerAction $MarkerAction
}

function Assert-TransactionTargetRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = ConvertTo-SafeRelativePath -Path $Path -Label "transaction target"
    if ([string]::Equals($normalized, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($normalized, $script:LastKnownGoodPointerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($normalized, $script:UpgradeStateRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($normalized, $script:McpAvailabilityRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
        return $normalized
    }
    return Assert-TargetRelativePath -Path $normalized
}

function Write-DurableUtf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $temporaryPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    $stream = $null
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
        $stream = [System.IO.FileStream]::new(
            $temporaryPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None,
            4096,
            [System.IO.FileOptions]::WriteThrough)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null
        [System.IO.File]::Move($temporaryPath, $Path)
    } finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Write-DurableBytesFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes
    )

    if (Test-Path -LiteralPath $Path) {
        throw "Durable byte publication target already exists: $Path"
    }
    $temporaryPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    $stream = $null
    try {
        $stream = [System.IO.FileStream]::new(
            $temporaryPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None,
            4096,
            [System.IO.FileOptions]::WriteThrough)
        $stream.Write($Bytes, 0, $Bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null
        [System.IO.File]::Move($temporaryPath, $Path)
    } finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Publish-TransactionFile {
    param(
        [Parameter(Mandatory = $true)][string]$StagePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $stageRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($StagePath))
    $targetRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($TargetPath))
    if (-not [string]::Equals($stageRoot, $targetRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Atomic payload publication requires staging and target paths on the same volume: $TargetPath"
    }

    if (Test-Path -LiteralPath $TargetPath) {
        if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
            throw "Atomic payload target is not a file: $TargetPath"
        }
        $replacementBackupPath = Join-Path (Split-Path -Parent $StagePath) ("swap-$([guid]::NewGuid().ToString('N')).bak")
        try {
            [System.IO.File]::Replace($StagePath, $TargetPath, $replacementBackupPath, $true)
        } finally {
            if (Test-Path -LiteralPath $replacementBackupPath -PathType Leaf) {
                Remove-Item -LiteralPath $replacementBackupPath -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        [System.IO.File]::Move($StagePath, $TargetPath)
    }
}

function New-TransactionEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][ValidateSet("Write", "Delete")][string]$Mutation,
        [AllowNull()][string]$DesiredSha256,
        [AllowNull()][string]$StagePath,
        [Parameter(Mandatory = $true)][string]$BackupRoot,
        [Parameter(Mandatory = $true)][int]$Index
    )

    $normalizedTarget = Assert-TransactionTargetRelativePath -Path $Target
    if ($Mutation -eq "Write" -and
        ([string]::IsNullOrWhiteSpace($DesiredSha256) -or $DesiredSha256 -notmatch '^[0-9a-f]{64}$' -or
            [string]::IsNullOrWhiteSpace($StagePath))) {
        throw "Transaction write entry is missing a staged file or SHA256: $normalizedTarget"
    }
    if ($Mutation -eq "Delete" -and
        (-not [string]::IsNullOrWhiteSpace($DesiredSha256) -or -not [string]::IsNullOrWhiteSpace($StagePath))) {
        throw "Transaction delete entry cannot contain staged file state: $normalizedTarget"
    }
    if ((Test-Path -LiteralPath $TargetPath) -and -not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        throw "Transaction target is not a file: $normalizedTarget"
    }

    $existedBefore = Test-Path -LiteralPath $TargetPath -PathType Leaf
    $backupPath = $null
    $backupSha256 = $null
    if ($existedBefore) {
        $backupName = "{0:D4}.bak" -f $Index
        $backupPath = Join-Path $BackupRoot $backupName
        Copy-Item -LiteralPath $TargetPath -Destination $backupPath -Force
        $backupSha256 = Get-FileSha256 -Path $backupPath
    }

    return [pscustomobject]@{
        Target = $normalizedTarget
        TargetPath = $TargetPath
        Mutation = $Mutation
        DesiredSha256 = $DesiredSha256
        StagePath = $StagePath
        ExistedBefore = $existedBefore
        BackupPath = $backupPath
        BackupSha256 = $backupSha256
    }
}

function Write-TransactionJournal {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("Sync", "Remove")][string]$Operation,
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [Parameter(Mandatory = $true)]$Entries,
        [Parameter(Mandatory = $true)]$Manifest,
        [switch]$AutomaticUpgrade,
        [AllowNull()][string]$PreviousWatcherManagerPath,
        [AllowNull()][string]$ProjectRoot
    )

    $transactionId = Split-Path -Leaf $TransactionRoot
    $journalEntries = @($Entries | ForEach-Object {
        [ordered]@{
            target = $_.Target
            mutation = $_.Mutation.ToLowerInvariant()
            desired_sha256 = if ($_.Mutation -eq "Write") { $_.DesiredSha256 } else { $null }
            existed_before = $_.ExistedBefore
            backup = if ($_.ExistedBefore) { "backup/$([System.IO.Path]::GetFileName($_.BackupPath))" } else { $null }
            backup_sha256 = $_.BackupSha256
        }
    })
    $previousWatcherManager = $null
    $previousWatcherManagerSha256 = $null
    if ($AutomaticUpgrade) {
        if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
            throw "Automatic-upgrade journal requires the project root identity."
        }
        if (-not [string]::IsNullOrWhiteSpace($PreviousWatcherManagerPath)) {
            $fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
            $fullPreviousManager = [System.IO.Path]::GetFullPath($PreviousWatcherManagerPath)
            Assert-PathInside -Path $fullPreviousManager -Root $fullProjectRoot -Label "previous watcher manager"
            $previousWatcherManager = $fullPreviousManager.Substring($fullProjectRoot.Length + 1).Replace('\', '/')
            $previousWatcherManager = ConvertTo-SafeRelativePath -Path $previousWatcherManager -Label "previous watcher manager"
            $isLegacyManager = [string]::Equals($previousWatcherManager, "AIWork/codedb/scripts/manage-codedb-project-watch.ps1", [StringComparison]::OrdinalIgnoreCase)
            $isGenerationManager = $previousWatcherManager -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/scripts/manage-codedb-project-watch\.ps1$'
            if (-not $isLegacyManager -and -not $isGenerationManager) {
                throw "Previous watcher manager is outside the supported legacy or immutable-generation layout."
            }
            Assert-NoReparsePoint -Path $fullPreviousManager -Root $fullProjectRoot -Label "previous watcher manager"
            if (-not (Test-Path -LiteralPath $fullPreviousManager -PathType Leaf)) {
                throw "Previous watcher manager does not exist."
            }
            $previousWatcherManagerSha256 = Get-FileSha256 -Path $fullPreviousManager
        }
    }
    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    if ($AutomaticUpgrade -and -not $Manifest.UsesGenerationContract) {
        throw "Automatic-upgrade journal requires an immutable generation manifest identity."
    }
    if ($Manifest.UsesGenerationContract -and -not $Manifest.TargetMap.ContainsKey($generationManifestTarget)) {
        throw "Transaction journal cannot record a missing generation manifest identity."
    }
    $generationManifestSha256 = if ($Manifest.UsesGenerationContract) {
        $Manifest.TargetMap[$generationManifestTarget].Sha256
    } else {
        $null
    }
    $document = [ordered]@{
        schema_version = 2
        managed_by = $script:ManagedBy
        transaction_id = $transactionId
        state = "prepared"
        operation = $Operation.ToLowerInvariant()
        automatic_upgrade = [bool]$AutomaticUpgrade
        package_version = $Manifest.PackageVersion
        payload_version = $Manifest.PayloadVersion
        payload_sequence = $Manifest.PayloadSequence
        payload_content_sha256 = Get-PayloadContentIdentitySha256 -Manifest $Manifest
        generation_id = $Manifest.GenerationId
        bootstrap_protocol = $Manifest.BootstrapProtocol
        generation_manifest_sha256 = $generationManifestSha256
        previous_watcher_manager = $previousWatcherManager
        previous_watcher_manager_sha256 = $previousWatcherManagerSha256
        entries = $journalEntries
    }
    $journalPath = Join-Path $TransactionRoot $script:TransactionJournalName
    Write-DurableUtf8File -Path $journalPath -Content (($document | ConvertTo-Json -Depth 8) + "`n")
}

function Read-TransactionJournal {
    param(
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $transactionId = Split-Path -Leaf $TransactionRoot
    $journalPath = Join-Path $TransactionRoot $script:TransactionJournalName
    $document = (Read-BoundedJsonDocument -Path $journalPath -Label "transaction journal" -MaximumBytes (1024 * 1024)).Document
    $schemaVersion = Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "transaction journal"
    $managedBy = Get-RequiredJsonString -Object $document -Name "managed_by" -Label "transaction journal"
    $journalId = Get-RequiredJsonString -Object $document -Name "transaction_id" -Label "transaction journal"
    $state = Get-RequiredJsonString -Object $document -Name "state" -Label "transaction journal"
    $operation = Get-RequiredJsonString -Object $document -Name "operation" -Label "transaction journal"
    $journalEntries = Get-RequiredJsonArray -Object $document -Name "entries" -Label "transaction journal"
    if ($schemaVersion -notin @(1, 2) -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals($journalId, $transactionId, [StringComparison]::Ordinal) -or
        -not [string]::Equals($state, "prepared", [StringComparison]::Ordinal) -or
        $operation -notin @("sync", "remove") -or
        $journalEntries.Count -eq 0) {
        throw "Transaction journal identity, state, operation, or entries are invalid."
    }

    $provenance = $null
    if ($schemaVersion -eq 2) {
        $packageVersion = Get-RequiredJsonString -Object $document -Name "package_version" -Label "transaction journal"
        $payloadVersion = Get-RequiredJsonString -Object $document -Name "payload_version" -Label "transaction journal"
        $payloadSequence = Get-RequiredJsonInt32 -Object $document -Name "payload_sequence" -Label "transaction journal"
        $payloadContentSha256 = (Get-RequiredJsonString -Object $document -Name "payload_content_sha256" -Label "transaction journal").ToLowerInvariant()
        $generationId = Get-RequiredJsonString -Object $document -Name "generation_id" -Label "transaction journal"
        $bootstrapProtocol = Get-RequiredJsonInt32 -Object $document -Name "bootstrap_protocol" -Label "transaction journal"
        $generationManifestSha256 = Get-RequiredJsonNullableString -Object $document -Name "generation_manifest_sha256" -Label "transaction journal"
        if ($null -ne $generationManifestSha256) {
            $generationManifestSha256 = ([string]$generationManifestSha256).ToLowerInvariant()
        }
        if ([string]::IsNullOrWhiteSpace($packageVersion) -or
            [string]::IsNullOrWhiteSpace($payloadVersion) -or
            $payloadSequence -lt 1 -or
            $payloadContentSha256 -notmatch '^[0-9a-f]{64}$' -or
            $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
            $bootstrapProtocol -lt 1 -or
            ($null -ne $generationManifestSha256 -and $generationManifestSha256 -notmatch '^[0-9a-f]{64}$')) {
            throw "Transaction journal package or generation provenance is invalid."
        }
        $provenance = [pscustomobject]@{
            PackageVersion = $packageVersion
            PayloadVersion = $payloadVersion
            PayloadSequence = $payloadSequence
            PayloadContentSha256 = $payloadContentSha256
            GenerationId = $generationId
            BootstrapProtocol = $bootstrapProtocol
            GenerationManifestSha256 = $generationManifestSha256
        }
    }

    $automaticUpgrade = Get-OptionalJsonBoolean -Object $document -Name "automatic_upgrade" -Label "transaction journal"
    $previousWatcherManagerPath = $null
    $previousWatcherManagerSha256 = $null
    $previousWatcherProperty = Get-ExactJsonProperty -Object $document -Name "previous_watcher_manager" -Label "transaction journal"
    $previousWatcherHashProperty = Get-ExactJsonProperty -Object $document -Name "previous_watcher_manager_sha256" -Label "transaction journal"
    if ($automaticUpgrade) {
        if ($null -eq $previousWatcherProperty -or $null -eq $previousWatcherHashProperty) {
            throw "Automatic-upgrade journal is missing the previous watcher fields."
        }
        $hasPreviousWatcher = $null -ne $previousWatcherProperty.Value -or $null -ne $previousWatcherHashProperty.Value
        if ($hasPreviousWatcher) {
            if ($previousWatcherProperty.Value -isnot [string] -or
                $previousWatcherHashProperty.Value -isnot [string] -or
                [string]::IsNullOrWhiteSpace([string]$previousWatcherProperty.Value) -or
                [string]$previousWatcherHashProperty.Value -cnotmatch '^[0-9a-fA-F]{64}$') {
                throw "Automatic-upgrade journal has an incomplete previous watcher identity."
            }
            $previousWatcherRelativePath = ConvertTo-SafeRelativePath -Path ([string]$previousWatcherProperty.Value) -Label "previous watcher manager"
            $isLegacyManager = [string]::Equals($previousWatcherRelativePath, "AIWork/codedb/scripts/manage-codedb-project-watch.ps1", [StringComparison]::OrdinalIgnoreCase)
            $isGenerationManager = $previousWatcherRelativePath -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/scripts/manage-codedb-project-watch\.ps1$'
            if (-not $isLegacyManager -and -not $isGenerationManager) {
                throw "Automatic-upgrade journal has an unsupported previous watcher manager."
            }
            $previousWatcherManagerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $previousWatcherRelativePath -Label "previous watcher manager"
            Assert-NoReparsePoint -Path $previousWatcherManagerPath -Root $ProjectRoot -Label "previous watcher manager"
            $previousWatcherManagerSha256 = ([string]$previousWatcherHashProperty.Value).ToLowerInvariant()
        }
    } elseif (($null -ne $previousWatcherProperty -and $null -ne $previousWatcherProperty.Value) -or
        ($null -ne $previousWatcherHashProperty -and $null -ne $previousWatcherHashProperty.Value)) {
        throw "Non-upgrade transaction journal cannot select a previous watcher manager."
    }

    $seenTargets = @{}
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($journalEntry in $journalEntries) {
        $null = Assert-JsonObject -Value $journalEntry -Label "transaction entry"
        $target = Assert-TransactionTargetRelativePath -Path (Get-RequiredJsonString -Object $journalEntry -Name "target" -Label "transaction entry")
        if ($seenTargets.ContainsKey($target)) {
            throw "Transaction journal contains a duplicate target: $target"
        }
        $seenTargets[$target] = $true

        $mutation = Get-RequiredJsonString -Object $journalEntry -Name "mutation" -Label "transaction entry"
        if ($mutation -notin @("write", "delete")) {
            throw "Transaction entry has an invalid mutation: $target"
        }
        $desiredSha256 = Get-RequiredJsonNullableString -Object $journalEntry -Name "desired_sha256" -Label "transaction entry"
        if ($mutation -eq "write") {
            $desiredSha256 = ([string]$desiredSha256).ToLowerInvariant()
            if ($desiredSha256 -notmatch '^[0-9a-f]{64}$') {
                throw "Transaction write entry has an invalid desired SHA256: $target"
            }
        } elseif ($null -ne $desiredSha256) {
            throw "Transaction delete entry contains a desired SHA256: $target"
        }

        $existedBefore = Get-RequiredJsonBoolean -Object $journalEntry -Name "existed_before" -Label "transaction entry"
        $backupRelativePath = Get-RequiredJsonNullableString -Object $journalEntry -Name "backup" -Label "transaction entry"
        $backupSha256 = Get-RequiredJsonNullableString -Object $journalEntry -Name "backup_sha256" -Label "transaction entry"
        $backupPath = $null
        if ($existedBefore) {
            $backupRelativePath = ConvertTo-SafeRelativePath -Path ([string]$backupRelativePath) -Label "transaction backup"
            $backupSha256 = ([string]$backupSha256).ToLowerInvariant()
            if ($backupRelativePath -notmatch '^backup/[0-9]{4}\.bak$' -or $backupSha256 -notmatch '^[0-9a-f]{64}$') {
                throw "Transaction entry has invalid backup metadata: $target"
            }
            $backupPath = ConvertTo-AbsoluteChildPath -Root $TransactionRoot -RelativePath $backupRelativePath -Label "transaction backup"
            Assert-NoReparsePoint -Path $backupPath -Root $TransactionRoot -Label "transaction backup"
            if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf) -or
                -not [string]::Equals((Get-FileSha256 -Path $backupPath), $backupSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Transaction backup is missing or does not match its journal hash: $target"
            }
        } elseif ($null -ne $backupRelativePath -or $null -ne $backupSha256) {
            throw "Transaction entry without prior state contains backup metadata: $target"
        }

        $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "transaction target"
        Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "transaction target"
        $entries.Add([pscustomobject]@{
            Target = $target
            TargetPath = $targetPath
            Mutation = if ($mutation -eq "write") { "Write" } else { "Delete" }
            DesiredSha256 = $desiredSha256
            StagePath = $null
            ExistedBefore = $existedBefore
            BackupPath = $backupPath
            BackupSha256 = $backupSha256
        })
    }

    return [pscustomobject]@{
        SchemaVersion = $schemaVersion
        Operation = $operation
        AutomaticUpgrade = $automaticUpgrade
        Provenance = $provenance
        PreviousWatcherManagerPath = $previousWatcherManagerPath
        PreviousWatcherManagerSha256 = $previousWatcherManagerSha256
        Entries = $entries.ToArray()
    }
}

function Get-PendingMaterializerTransactionRecords {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $records = New-Object System.Collections.Generic.List[object]
    foreach ($transactionDirectory in @(Get-ChildItem -LiteralPath $Lock.Root -Force -Directory | Sort-Object Name)) {
        if ([string]::Equals($transactionDirectory.Name, $script:HostUseLeaseDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:HistoricalRuntimeDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:McpConfigBackupDirectoryName, [StringComparison]::Ordinal)) {
            continue
        }
        if ($transactionDirectory.Name -notmatch '^txn-v1-[0-9a-f]{12}$') {
            Throw-MaterializerError -Message "Unknown materializer recovery artifact requires manual review: $($transactionDirectory.FullName)" -ExitCode 7
        }
        Assert-NoReparsePoint -Path $transactionDirectory.FullName -Root $Lock.Root -Label "pending materializer transaction"
        $journalPath = Join-Path $transactionDirectory.FullName $script:TransactionJournalName
        if (-not (Test-Path -LiteralPath $journalPath)) {
            $records.Add([pscustomobject]@{
                Root = $transactionDirectory.FullName
                Id = $transactionDirectory.Name
                Journal = $null
            }) | Out-Null
            continue
        }
        if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
            Throw-MaterializerError -Message "Pending transaction journal is not a file: $journalPath" -ExitCode 7
        }
        Assert-NoReparsePoint -Path $journalPath -Root $transactionDirectory.FullName -Label "pending transaction journal"
        $journalInfo = Get-Item -LiteralPath $journalPath -Force
        if ($journalInfo.Length -le 0 -or $journalInfo.Length -gt (1024 * 1024)) {
            Throw-MaterializerError -Message "Pending transaction journal has an invalid size: $journalPath" -ExitCode 7
        }
        try {
            $journal = Read-TransactionJournal -TransactionRoot $transactionDirectory.FullName -ProjectRoot $ProjectRoot
            Assert-TransactionRecoveryState -Entries $journal.Entries
        } catch {
            Throw-MaterializerError -Message "Pending transaction failed read-only recovery preflight. $($_.Exception.Message) Transaction: $($transactionDirectory.FullName)" -ExitCode 7
        }
        $records.Add([pscustomobject]@{
            Root = $transactionDirectory.FullName
            Id = $transactionDirectory.Name
            Journal = $journal
        }) | Out-Null
    }
    return $records.ToArray()
}

function Assert-RepairPendingRecoveryDoesNotConflictWithGenerationMcp {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot
    )

    $mutationPaths = New-Object System.Collections.Generic.List[string]
    foreach ($record in @(Get-PendingMaterializerTransactionRecords -Lock $Lock -ProjectRoot $ProjectRoot)) {
        if ($null -eq $record.Journal) {
            continue
        }
        foreach ($entry in $record.Journal.Entries) {
            $mutationPaths.Add([string]$entry.TargetPath) | Out-Null
        }
    }
    $null = Assert-RepairMutationPathsDoNotConflictWithGenerationMcp `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -Paths $mutationPaths.ToArray() `
        -Boundary "pending transaction rollback"
}

function Assert-NoPendingMaterializerTransactions {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ActionLabel
    )

    $records = @(Get-PendingMaterializerTransactionRecords -Lock $Lock -ProjectRoot $ProjectRoot)
    if ($records.Count -gt 0) {
        Throw-MaterializerError -Message "$ActionLabel is blocked by pending materializer transaction $($records[0].Id); Repair CodeDB must resolve it before a process handoff." -ExitCode 4
    }
}

function Assert-TransactionRecoveryState {
    param([Parameter(Mandatory = $true)]$Entries)

    foreach ($entry in $Entries) {
        if ((Test-Path -LiteralPath $entry.TargetPath) -and -not (Test-Path -LiteralPath $entry.TargetPath -PathType Leaf)) {
            throw "Interrupted transaction target is no longer a file: $($entry.Target)"
        }
        $targetExists = Test-Path -LiteralPath $entry.TargetPath -PathType Leaf
        $currentSha256 = if ($targetExists) { Get-FileSha256 -Path $entry.TargetPath } else { $null }
        $matchesBefore = $entry.ExistedBefore -and $targetExists -and
            [string]::Equals($currentSha256, $entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)
        $matchesAfter = if ($entry.Mutation -eq "Write") {
            $targetExists -and [string]::Equals($currentSha256, $entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)
        } else {
            -not $targetExists
        }
        $matchesUnchangedMissing = -not $entry.ExistedBefore -and -not $targetExists
        if (-not ($matchesBefore -or $matchesAfter -or $matchesUnchangedMissing)) {
            throw "Interrupted transaction target changed outside the recorded before/after states: $($entry.Target)"
        }
    }
}

function Assert-PendingAutomaticUpgradeMarker {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        throw "Pending automatic-upgrade recovery is missing its active marker."
    }
    Assert-NoReparsePoint -Path $MarkerPath -Root $ProjectRoot -Label "pending automatic-upgrade marker"
    $markerJson = Read-BoundedJsonDocument -Path $MarkerPath -Label "pending automatic-upgrade marker" -MaximumBytes (64 * 1024)
    $marker = $markerJson.Document
    $processStartTicks = Get-RequiredJsonString -Object $marker -Name "process_start_ticks" -Label "pending automatic-upgrade marker"
    $createdAtText = Get-RequiredJsonString -Object $marker -Name "created_at_utc" -Label "pending automatic-upgrade marker"
    [DateTimeOffset]$createdAt = [DateTimeOffset]::MinValue
    if ((Get-RequiredJsonInt32 -Object $marker -Name "schema_version" -Label "pending automatic-upgrade marker") -ne 1 -or
        (Get-RequiredJsonInt32 -Object $marker -Name "host_use_gate_version" -Label "pending automatic-upgrade marker") -ne $script:HostUseGateVersion -or
        -not [string]::Equals((Get-RequiredJsonString -Object $marker -Name "managed_by" -Label "pending automatic-upgrade marker"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $marker -Name "pid" -Label "pending automatic-upgrade marker") -le 0 -or
        $processStartTicks -notmatch '^[0-9]{1,20}$' -or
        -not [string]::Equals(
            [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $marker -Name "project_root" -Label "pending automatic-upgrade marker")),
            [System.IO.Path]::GetFullPath($ProjectRoot),
            [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $marker -Name "action" -Label "pending automatic-upgrade marker"), "upgrade", [StringComparison]::Ordinal) -or
        -not [DateTimeOffset]::TryParse(
            $createdAtText,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$createdAt)) {
        throw "Pending automatic-upgrade marker identity or schema is invalid."
    }
}

function Assert-PendingAutomaticUpgradeJournalIdentity {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not $Journal.AutomaticUpgrade -or
        -not [string]::Equals([string]$Journal.Operation, "sync", [StringComparison]::Ordinal)) {
        throw "Pending automatic-upgrade journal has the wrong operation identity."
    }
    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    if (-not $Manifest.UsesGenerationContract -or
        -not $Manifest.TargetMap.ContainsKey($generationManifestTarget) -or
        $null -eq $Journal.Provenance) {
        throw "Pending automatic-upgrade journal has no immutable Package generation provenance."
    }
    $provenance = $Journal.Provenance
    if (-not [string]::Equals($provenance.PackageVersion, $Manifest.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals($provenance.PayloadVersion, $Manifest.PayloadVersion, [StringComparison]::Ordinal) -or
        $provenance.PayloadSequence -ne $Manifest.PayloadSequence -or
        -not [string]::Equals($provenance.PayloadContentSha256, (Get-PayloadContentIdentitySha256 -Manifest $Manifest), [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals($provenance.GenerationId, $Manifest.GenerationId, [StringComparison]::Ordinal) -or
        $provenance.BootstrapProtocol -ne $Manifest.BootstrapProtocol -or
        -not [string]::Equals($provenance.GenerationManifestSha256, $Manifest.TargetMap[$generationManifestTarget].Sha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Pending automatic-upgrade journal does not match the current Package generation identity."
    }
    $pointerTarget = [string]$Manifest.CurrentPointerTarget
    if (-not $Manifest.TargetMap.ContainsKey($pointerTarget)) {
        throw "Payload manifest has no current-pointer identity for pending recovery."
    }
    $pointerEntry = @($Journal.Entries | Where-Object {
        [string]::Equals([string]$_.Target, $pointerTarget, [StringComparison]::OrdinalIgnoreCase)
    })
    $markerEntry = @($Journal.Entries | Where-Object {
        [string]::Equals([string]$_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($pointerEntry.Count -ne 1 -or $markerEntry.Count -ne 1 -or
        -not [string]::Equals([string]$pointerEntry[0].Mutation, "Write", [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$markerEntry[0].Mutation, "Write", [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$pointerEntry[0].DesiredSha256, [string]$Manifest.TargetMap[$pointerTarget].Sha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Pending automatic-upgrade journal does not select the package generation pointer and marker."
    }
    $pointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $pointerTarget -Label "pending current generation pointer"
    $installedMarkerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "pending installed payload marker"
    if (-not (Test-Path -LiteralPath $pointerPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $installedMarkerPath -PathType Leaf) -or
        -not [string]::Equals((Get-FileSha256 -Path $pointerPath), [string]$pointerEntry[0].DesiredSha256, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-FileSha256 -Path $installedMarkerPath), [string]$markerEntry[0].DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Pending automatic-upgrade journal no longer matches the selected package generation."
    }

    if ($null -ne $Journal.PreviousWatcherManagerPath) {
        $previousManagerPath = [System.IO.Path]::GetFullPath([string]$Journal.PreviousWatcherManagerPath)
        Assert-PathInside -Path $previousManagerPath -Root $ProjectRoot -Label "pending previous watcher manager"
        $projectPrefix = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
        $previousManagerTarget = $previousManagerPath.Substring($projectPrefix.Length).Replace('\', '/')
        $managerBackupEntry = @($Journal.Entries | Where-Object {
            [string]::Equals([string]$_.Target, $previousManagerTarget, [StringComparison]::OrdinalIgnoreCase)
        })
        $currentManagerMatches = (Test-Path -LiteralPath $previousManagerPath -PathType Leaf) -and
            [string]::Equals((Get-FileSha256 -Path $previousManagerPath), [string]$Journal.PreviousWatcherManagerSha256, [StringComparison]::OrdinalIgnoreCase)
        $backupManagerMatches = $managerBackupEntry.Count -eq 1 -and
            $managerBackupEntry[0].ExistedBefore -and
            [string]::Equals([string]$managerBackupEntry[0].BackupSha256, [string]$Journal.PreviousWatcherManagerSha256, [StringComparison]::OrdinalIgnoreCase)
        if (-not $currentManagerMatches -and -not $backupManagerMatches) {
            throw "Pending automatic-upgrade journal no longer proves its previous watcher manager identity."
        }
    } else {
        foreach ($entry in $Journal.Entries) {
            if ($entry.ExistedBefore) {
                throw "First-adoption automatic-upgrade journal unexpectedly records pre-existing CodeDB content."
            }
        }
    }
}

function Get-PendingAutomaticUpgradeRecovery {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $notPending = [pscustomobject]@{ Pending = $false; TransactionId = $null }
    $runtimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
    if (-not (Test-Path -LiteralPath $runtimeRoot)) {
        return $notPending
    }
    if (-not (Test-Path -LiteralPath $runtimeRoot -PathType Container)) {
        throw "Materializer recovery runtime is not a directory: $runtimeRoot"
    }
    Assert-NoReparsePoint -Path $runtimeRoot -Root $ProjectRoot -Label "materializer recovery runtime"

    $automaticTransactions = New-Object System.Collections.Generic.List[object]
    $hasNonAutomaticOrUnclassifiedTransaction = $false
    foreach ($transactionDirectory in @(Get-ChildItem -LiteralPath $runtimeRoot -Force -Directory | Sort-Object Name)) {
        if ([string]::Equals($transactionDirectory.Name, $script:HostUseLeaseDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:HistoricalRuntimeDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:McpConfigBackupDirectoryName, [StringComparison]::Ordinal)) {
            continue
        }
        if ($transactionDirectory.Name -notmatch '^txn-v1-[0-9a-f]{12}$') {
            throw "Unknown materializer recovery artifact requires manual review: $($transactionDirectory.FullName)"
        }
        Assert-NoReparsePoint -Path $transactionDirectory.FullName -Root $runtimeRoot -Label "pending materializer transaction"
        $journalPath = Join-Path $transactionDirectory.FullName $script:TransactionJournalName
        if (-not (Test-Path -LiteralPath $journalPath)) {
            $hasNonAutomaticOrUnclassifiedTransaction = $true
            continue
        }
        if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
            throw "Pending transaction journal is not a file: $journalPath"
        }
        Assert-NoReparsePoint -Path $journalPath -Root $transactionDirectory.FullName -Label "pending transaction journal"
        $journalInfo = Get-Item -LiteralPath $journalPath -Force
        if ($journalInfo.Length -le 0 -or $journalInfo.Length -gt (1024 * 1024)) {
            throw "Pending transaction journal has an invalid size: $journalPath"
        }
        $journal = Read-TransactionJournal -TransactionRoot $transactionDirectory.FullName -ProjectRoot $ProjectRoot
        Assert-TransactionRecoveryState -Entries $journal.Entries
        if (-not $journal.AutomaticUpgrade) {
            $hasNonAutomaticOrUnclassifiedTransaction = $true
            continue
        }
        $automaticTransactions.Add([pscustomobject]@{
            Id = $transactionDirectory.Name
            Journal = $journal
        })
    }

    if ($hasNonAutomaticOrUnclassifiedTransaction -or $automaticTransactions.Count -eq 0) {
        return $notPending
    }
    if ($automaticTransactions.Count -ne 1) {
        throw "Multiple pending automatic-upgrade transactions require manual review."
    }
    $activeMarkerPath = Join-Path $runtimeRoot $script:ActiveMarkerName
    Assert-PendingAutomaticUpgradeMarker -MarkerPath $activeMarkerPath -ProjectRoot $ProjectRoot
    Assert-PendingAutomaticUpgradeJournalIdentity `
        -Journal $automaticTransactions[0].Journal `
        -Manifest $Manifest `
        -ProjectRoot $ProjectRoot
    return [pscustomobject]@{
        Pending = $true
        TransactionId = $automaticTransactions[0].Id
    }
}

function Assert-TransactionEntryBeforeMutation {
    param([Parameter(Mandatory = $true)]$Entry)

    if ($Entry.ExistedBefore) {
        if (-not (Test-Path -LiteralPath $Entry.TargetPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $Entry.TargetPath), $Entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Transaction target changed after it was backed up: $($Entry.Target)"
        }
    } elseif (Test-Path -LiteralPath $Entry.TargetPath) {
        throw "Transaction target appeared after the missing state was recorded: $($Entry.Target)"
    }
}

function Restore-Transaction {
    param(
        [Parameter(Mandatory = $true)]$Entries,
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $errors = New-Object System.Collections.Generic.List[string]
    try {
        # Validate the whole recovery set before rollback can overwrite any external change.
        Assert-TransactionRecoveryState -Entries $Entries
    } catch {
        $errors.Add("validate interrupted state: $($_.Exception.Message)")
        return $errors.ToArray()
    }

    foreach ($entry in @($Entries | Where-Object { -not $_.ExistedBefore } | Sort-Object Target -Descending)) {
        try {
            if (Test-Path -LiteralPath $entry.TargetPath -PathType Leaf) {
                Remove-Item -LiteralPath $entry.TargetPath -Force
            }
        } catch {
            $errors.Add("remove $($entry.Target): $($_.Exception.Message)")
        }
    }

    $markerEntries = @($Entries | Where-Object { $_.ExistedBefore -and [string]::Equals($_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) })
    $fileEntries = @($Entries | Where-Object { $_.ExistedBefore -and -not [string]::Equals($_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object Target)
    foreach ($entry in @($fileEntries) + @($markerEntries)) {
        try {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
            $restoreStagePath = Join-Path $TransactionRoot ("restore-$([guid]::NewGuid().ToString('N')).payload")
            Copy-Item -LiteralPath $entry.BackupPath -Destination $restoreStagePath -Force
            if (-not [string]::Equals((Get-FileSha256 -Path $restoreStagePath), $entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Restore staging hash mismatch."
            }
            Publish-TransactionFile -StagePath $restoreStagePath -TargetPath $entry.TargetPath
            if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), $entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Restored target hash mismatch."
            }
        } catch {
            $errors.Add("restore $($entry.Target): $($_.Exception.Message)")
        }
    }

    if ($errors.Count -eq 0) {
        $createdPaths = @($Entries | Where-Object { -not $_.ExistedBefore } | ForEach-Object { $_.TargetPath })
        if ($createdPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $createdPaths -TargetRoot $TargetRoot
            $hostRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host" -Label "host generation runtime"
            Remove-EmptyManagedParents -Paths $createdPaths -TargetRoot $hostRuntimeRoot
        }
    }
    return $errors.ToArray()
}

function Invoke-PendingTransactionRecovery {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [switch]$AutomaticOnly,
        [switch]$SkipAutomaticUpgrade,
        [AllowNull()][ref]$MutationOccurred
    )

    if ($AutomaticOnly -and $SkipAutomaticUpgrade) {
        throw "Pending transaction recovery filters are mutually exclusive."
    }
    $recoveredAutomaticUpgrade = $false
    foreach ($transactionDirectory in @(Get-ChildItem -LiteralPath $Lock.Root -Force -Directory | Sort-Object Name)) {
        if ([string]::Equals($transactionDirectory.Name, $script:HostUseLeaseDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:HistoricalRuntimeDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:McpConfigBackupDirectoryName, [StringComparison]::Ordinal)) {
            continue
        }
        $transactionRoot = $transactionDirectory.FullName
        if ($transactionDirectory.Name -notmatch '^txn-v1-[0-9a-f]{12}$') {
            Throw-MaterializerError -Message "Unknown materializer recovery artifact requires manual review: $transactionRoot" -ExitCode 7
        }
        try {
            Assert-NoReparsePoint -Path $transactionRoot -Root $Lock.Root -Label "materializer transaction"
            $journalPath = Join-Path $transactionRoot $script:TransactionJournalName
            if (-not (Test-Path -LiteralPath $journalPath)) {
                # New transactions publish the journal before their first host mutation.
                Remove-Item -LiteralPath $transactionRoot -Recurse -Force
                if ($null -ne $MutationOccurred) { $MutationOccurred.Value = $true }
                Write-Host "[RECOVERED] Removed an interrupted pre-mutation transaction."
                continue
            }
            if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
                throw "Transaction journal is not a file."
            }
            Assert-NoReparsePoint -Path $journalPath -Root $transactionRoot -Label "transaction journal"
            $journal = Read-TransactionJournal -TransactionRoot $transactionRoot -ProjectRoot $ProjectRoot
            if (($AutomaticOnly -and -not $journal.AutomaticUpgrade) -or
                ($SkipAutomaticUpgrade -and $journal.AutomaticUpgrade)) {
                continue
            }
            if ($journal.AutomaticUpgrade) {
                Publish-MaterializerUpgradeState -Lock $Lock -ProjectRoot $ProjectRoot -State "ROLLBACK" -Message "Recovering an interrupted automatic host upgrade."
                if ($null -ne $MutationOccurred) { $MutationOccurred.Value = $true }
            }
            $rollbackErrors = @(Restore-Transaction -Entries $journal.Entries -TransactionRoot $transactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
            if ($rollbackErrors.Count -gt 0) {
                throw $rollbackErrors -join '; '
            }
            if ($journal.AutomaticUpgrade) {
                if ($null -ne $journal.PreviousWatcherManagerPath) {
                    $null = Resolve-RollbackWatcherManager `
                        -ProjectRoot $ProjectRoot `
                        -RecordedWatchManagerPath $journal.PreviousWatcherManagerPath `
                        -RecordedWatchManagerSha256 $journal.PreviousWatcherManagerSha256
                    Write-Host "[ROLLBACK] Restored and validated the previous Host selection without executing its watcher manager."
                }
                if (-not $Lock.ActiveMarkerPublished) {
                    Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
                }
                Publish-MaterializerUpgradeState -Lock $Lock -ProjectRoot $ProjectRoot -State "CHECK_FAILED" -Message "Interrupted upgrade was rolled back to the last-known-good selection. Watcher restart is deferred to Package-owned Repair."
                $recoveredAutomaticUpgrade = $true
            }
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force
            if ($null -ne $MutationOccurred) { $MutationOccurred.Value = $true }
            Write-Host "[RECOVERED] Rolled back interrupted $($journal.Operation) transaction."
        } catch {
            Throw-MaterializerError -Message "Interrupted payload transaction could not be recovered. $($_.Exception.Message) Transaction: $transactionRoot" -ExitCode 7
        }
    }
    return $recoveredAutomaticUpgrade
}

function Remove-EmptyManagedParents {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][string]$TargetRoot
    )

    $fullTargetRoot = [System.IO.Path]::GetFullPath($TargetRoot).TrimEnd('\', '/')
    $parents = @($Paths | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique | Sort-Object Length -Descending)
    foreach ($parent in $parents) {
        $current = $parent
        while (-not [string]::IsNullOrWhiteSpace($current) -and
            -not [string]::Equals($current, $fullTargetRoot, [StringComparison]::OrdinalIgnoreCase) -and
            $current.StartsWith($fullTargetRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            if ((Test-Path -LiteralPath $current -PathType Container) -and
                @(Get-ChildItem -LiteralPath $current -Force).Count -eq 0) {
                Remove-Item -LiteralPath $current -Force
                $current = Split-Path -Parent $current
            } else {
                break
            }
        }
    }
}

function Assert-GenerationDirectoryMatchesManifest {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$GenerationRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$SkipSyntaxValidation
    )

    if (-not (Test-Path -LiteralPath $GenerationRoot -PathType Container)) {
        throw "Immutable generation directory does not exist: $GenerationRoot"
    }
    Assert-NoReparsePoint -Path $GenerationRoot -Root $ProjectRoot -Label "immutable generation"
    $expected = @{}
    foreach ($file in @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
    })) {
        $relativePath = $file.Target.Substring($script:GenerationTargetPrefix.Length)
        $relativePath = ConvertTo-SafeRelativePath -Path $relativePath -Label "immutable generation file"
        $expected[$relativePath] = $file
        $candidatePath = ConvertTo-AbsoluteChildPath -Root $GenerationRoot -RelativePath $relativePath -Label "immutable generation file"
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
            throw "Immutable generation file is missing: $relativePath"
        }
        Assert-NoReparsePoint -Path $candidatePath -Root $GenerationRoot -Label "immutable generation file"
        if (-not [string]::Equals((Get-FileSha256 -Path $candidatePath), $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Immutable generation file hash mismatch: $relativePath"
        }
    }

    Assert-ImmutableGenerationFilesystemClosure `
        -Root $GenerationRoot `
        -ExpectedFiles @($expected.Keys) `
        -Label "immutable generation"

    if (-not $SkipSyntaxValidation) {
        $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
        if ($null -eq $nodeCommand) {
            throw "Node.js is required to validate the CodeDB generation coordinator."
        }
        $coordinatorPath = Join-Path $GenerationRoot "coordinator\codedb-watch-coordinator.mjs"
        $global:LASTEXITCODE = 0
        $nodeOutput = @(& $nodeCommand.Source --check $coordinatorPath 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Generation coordinator syntax validation failed: $($nodeOutput -join ' ')"
        }
        foreach ($scriptPath in @(Get-ChildItem -LiteralPath (Join-Path $GenerationRoot "scripts") -File -Filter "*.ps1" -ErrorAction Stop)) {
            $tokens = $null
            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath.FullName, [ref]$tokens, [ref]$parseErrors)
            if (@($parseErrors).Count -gt 0) {
                throw "Generation PowerShell syntax validation failed for $($scriptPath.Name): $($parseErrors[0].Message)"
            }
        }
    }
}

function Publish-ImmutableGeneration {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [AllowNull()][string]$RepairPayloadRoot,
        [AllowNull()][ref]$MutationOccurred
    )

    $generationRoot = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') `
        -Label "immutable generation"
    if (Test-Path -LiteralPath $generationRoot) {
        Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $generationRoot -ProjectRoot $ProjectRoot
        Write-Host "[INSTALLING] Reusing the complete immutable generation $($Manifest.GenerationId)."
        return $generationRoot
    }

    if (-not [string]::IsNullOrWhiteSpace($RepairPayloadRoot)) {
        $null = Assert-RepairMutationPathsDoNotConflictWithGenerationMcp `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $RepairPayloadRoot `
            -Paths @($generationRoot) `
            -Boundary "immutable generation publication"
    }

    $stagedGenerationRoot = Join-Path $TransactionRoot "generation-stage\$($Manifest.GenerationId)"
    New-Item -ItemType Directory -Force -Path $stagedGenerationRoot | Out-Null
    foreach ($file in @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
    })) {
        $relativePath = $file.Target.Substring($script:GenerationTargetPrefix.Length)
        $stagePath = ConvertTo-AbsoluteChildPath -Root $stagedGenerationRoot -RelativePath $relativePath -Label "staged generation file"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stagePath) | Out-Null
        Copy-Item -LiteralPath $file.SourcePath -Destination $stagePath
    }
    Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $stagedGenerationRoot -ProjectRoot $TransactionRoot

    $generationParent = Split-Path -Parent $generationRoot
    Assert-NoReparsePoint -Path $generationParent -Root $ProjectRoot -Label "generation publication root"
    New-Item -ItemType Directory -Force -Path $generationParent | Out-Null
    Assert-NoReparsePoint -Path $generationParent -Root $ProjectRoot -Label "generation publication root"
    [System.IO.Directory]::Move($stagedGenerationRoot, $generationRoot)
    if ($null -ne $MutationOccurred) { $MutationOccurred.Value = $true }
    Add-MaterializerMutationScope -Scope "host_runtime"
    Invoke-TestFaultAfterMutation
    Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $generationRoot -ProjectRoot $ProjectRoot
    Write-Host "[INSTALLING] Published immutable generation $($Manifest.GenerationId)."
    return $generationRoot
}

function Move-RepairPathToQuarantine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][string]$Reason,
        [Parameter(Mandatory = $true)][string]$QuarantineRoot,
        [AllowNull()][ref]$MutationOccurred
    )

    Assert-PathInside -Path $Path -Root $ProjectRoot -Label "repair quarantine source"
    Assert-NoReparsePoint -Path $Path -Root $ProjectRoot -Label "repair quarantine source"
    $null = Assert-RepairMutationPathsDoNotConflictWithGenerationMcp `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $PayloadRoot `
        -Paths @($Path) `
        -Boundary "quarantine"
    Assert-NoReparsePoint -Path $QuarantineRoot -Root $ProjectRoot -Label "repair quarantine root"
    New-Item -ItemType Directory -Force -Path $QuarantineRoot | Out-Null
    $destination = Join-Path $QuarantineRoot ("$Reason-$([guid]::NewGuid().ToString('N').Substring(0,12))")
    if (Test-Path -LiteralPath $Path -PathType Container) {
        [System.IO.Directory]::Move([System.IO.Path]::GetFullPath($Path), [System.IO.Path]::GetFullPath($destination))
    } elseif (Test-Path -LiteralPath $Path -PathType Leaf) {
        [System.IO.File]::Move([System.IO.Path]::GetFullPath($Path), [System.IO.Path]::GetFullPath($destination))
    } else {
        throw "Repair quarantine source disappeared: $Path"
    }
    if ($null -ne $MutationOccurred) { $MutationOccurred.Value = $true }
    Add-MaterializerMutationScope -Scope "host_runtime"
    Invoke-TestFaultAfterMutation
    Write-Host "[QUARANTINED] $Path -> $destination"
    return $destination
}

function Assert-RepairCandidateCanBeQuarantined {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$CandidateRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    Assert-NoReparsePoint -Path $CandidateRoot -Root $ProjectRoot -Label "repair generation candidate"
    $expected = @{}
    $expectedDirectories = @{ "" = $true }
    foreach ($file in @($Manifest.Files | Where-Object { $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase) })) {
        $relativePath = $file.Target.Substring($script:GenerationTargetPrefix.Length)
        $expected[$relativePath] = $file.Sha256
        $parent = [System.IO.Path]::GetDirectoryName($relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        while (-not [string]::IsNullOrWhiteSpace($parent)) {
            $expectedDirectories[$parent.Replace('\', '/')] = $true
            $parent = [System.IO.Path]::GetDirectoryName($parent)
        }
    }
    foreach ($item in @(Get-ChildItem -LiteralPath $CandidateRoot -Force -Recurse)) {
        Assert-NoReparsePoint -Path $item.FullName -Root $CandidateRoot -Label "repair generation residue"
        $relativePath = $item.FullName.Substring($CandidateRoot.TrimEnd('\', '/').Length + 1).Replace('\', '/')
        if ($item.PSIsContainer) {
            if (-not $expectedDirectories.ContainsKey($relativePath)) {
                throw "Package generation candidate contains an unmanifested directory: $relativePath"
            }
            continue
        }
        if (-not $expected.ContainsKey($relativePath)) {
            throw "Package generation candidate contains unowned content: $relativePath"
        }
        if (-not [string]::Equals((Get-FileSha256 -Path $item.FullName), [string]$expected[$relativePath], [StringComparison]::OrdinalIgnoreCase)) {
            throw "Package generation candidate contains drifted content: $relativePath"
        }
    }
}

function Assert-RepairPointerCanBeQuarantined {
    param(
        [Parameter(Mandatory = $true)][string]$PointerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $pointerJson = Read-BoundedJsonDocument -Path $PointerPath -Label "repair generation pointer" -MaximumBytes (64 * 1024)
    $pointer = $pointerJson.Document
    $generationId = Get-RequiredJsonString -Object $pointer -Name "generation_id" -Label "repair generation pointer"
    $relativePath = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $pointer -Name "generation_relative_path" -Label "repair generation pointer") -Label "repair generation pointer path"
    $manifestSha256 = Get-RequiredJsonString -Object $pointer -Name "generation_manifest_sha256" -Label "repair generation pointer"
    $bootstrapProtocol = Get-RequiredJsonInt32 -Object $pointer -Name "bootstrap_protocol" -Label "repair generation pointer"
    $payloadSequence = Get-RequiredJsonInt32 -Object $pointer -Name "payload_sequence" -Label "repair generation pointer"
    $packageVersion = Get-RequiredJsonString -Object $pointer -Name "package_version" -Label "repair generation pointer"
    $payloadVersion = Get-RequiredJsonString -Object $pointer -Name "payload_version" -Label "repair generation pointer"
    if ((Get-RequiredJsonInt32 -Object $pointer -Name "schema_version" -Label "repair generation pointer") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "managed_by" -Label "repair generation pointer"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
        -not [string]::Equals($relativePath, "AIWork/.runtime/codedb/host/generations/$generationId", [StringComparison]::Ordinal) -or
        $manifestSha256 -cnotmatch '^[0-9a-fA-F]{64}$') {
        throw "Generation pointer does not prove CodeDB ownership and cannot be quarantined."
    }
    $identity = [pscustomobject]@{
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        GenerationId = $generationId
        BootstrapProtocol = $bootstrapProtocol
    }
    $disposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $identity
    if ([string]::Equals($disposition, "NEWER", [StringComparison]::Ordinal) -or
        [string]::Equals($disposition, "SEQUENCE_COLLISION", [StringComparison]::Ordinal)) {
        throw "Generation pointer exceeds the current Package identity and cannot be quarantined."
    }
    if (-not [string]::Equals($disposition, "CURRENT", [StringComparison]::Ordinal) -and
        -not [string]::Equals($disposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal)) {
        throw "Generation pointer is not an exact Package runtime identity and cannot be quarantined."
    }
    return [pscustomobject]@{
        GenerationId = $generationId
        PayloadSequence = $payloadSequence
        Disposition = $disposition
    }
}

function Get-RepairPreservationSnapshot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $policyPaths = New-Object System.Collections.Generic.List[string]
    $runtimePaths = New-Object System.Collections.Generic.List[string]
    $policyPaths.Add((ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host/update-policy.json" -Label "automatic-update policy"))
    foreach ($providerRoot in @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)) {
        foreach ($relativePath in @(
            "bin",
            "config",
            "index",
            "adapter/text-index/manifest.json",
            "adapter/text-index/files.jsonl",
            "adapter/text-index/index.jsonl"
        )) {
            $runtimePaths.Add((ConvertTo-AbsoluteChildPath -Root $providerRoot -RelativePath $relativePath -Label "preserved Provider runtime"))
        }
        foreach ($relativePath in @(
            "watch/lifecycle/desired-state.json",
            "watch/lifecycle/manual-runtime.json",
            "watch/auto-start.json",
            "watch/automatic-refresh-paused.json"
        )) {
            $policyPaths.Add((ConvertTo-AbsoluteChildPath -Root $providerRoot -RelativePath $relativePath -Label "automatic-start policy"))
        }
    }
    $runtime = @{}
    foreach ($path in $runtimePaths) {
        Assert-NoReparsePoint -Path $path -Root $ProjectRoot -Label "preserved CodeDB runtime"
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path -Force
            if ($item.PSIsContainer) {
                $rows = @()
                foreach ($child in @(Get-ChildItem -LiteralPath $path -Force -Recurse)) {
                    Assert-NoReparsePoint -Path $child.FullName -Root $path -Label "preserved CodeDB runtime content"
                    if ($child.PSIsContainer) { continue }
                    $rows += "$($child.FullName.Substring($path.TrimEnd('\', '/').Length + 1).Replace('\', '/')):$((Get-FileSha256 -Path $child.FullName)):$($child.Length):$([int]$child.Attributes)"
                }
                $runtime[$path] = "directory:`n" + (($rows | Sort-Object) -join "`n")
            } else {
                $runtime[$path] = "file:$((Get-FileSha256 -Path $path)):$($item.Length):$([int]$item.Attributes)"
            }
        } else {
            $runtime[$path] = $null
        }
    }
    $policyFiles = New-Object System.Collections.Generic.List[object]
    foreach ($path in $policyPaths) {
        Assert-NoReparsePoint -Path $path -Root $ProjectRoot -Label "CodeDB policy"
        if (Test-Path -LiteralPath $path) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "CodeDB policy is not a regular file: $path" }
            $bytes = [System.IO.File]::ReadAllBytes($path)
            $policyFiles.Add([pscustomobject]@{
                Path = $path
                Exists = $true
                Bytes = $bytes
                Sha256 = Get-FileSha256 -Path $path
            })
        } else {
            $policyFiles.Add([pscustomobject]@{ Path = $path; Exists = $false; Bytes = [byte[]]@(); Sha256 = $null })
        }
    }
    return [pscustomobject]@{
        ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
        Runtime = $runtime
        PolicyFiles = $policyFiles.ToArray()
    }
}

function Assert-RepairPreservationSnapshot {
    param([Parameter(Mandatory = $true)]$Snapshot)

    $current = Get-RepairPreservationSnapshot -ProjectRoot $Snapshot.ProjectRoot
    foreach ($path in $Snapshot.Runtime.Keys) {
        if (-not $current.Runtime.ContainsKey($path) -or
            -not [string]::Equals([string]$current.Runtime[$path], [string]$Snapshot.Runtime[$path], [StringComparison]::Ordinal)) {
            throw "Repair changed preserved Provider, config, index, adapter, or policy content unexpectedly: $path"
        }
    }
    foreach ($entry in $Snapshot.PolicyFiles) {
        $currentEntry = @($current.PolicyFiles | Where-Object { [string]::Equals($_.Path, $entry.Path, [StringComparison]::OrdinalIgnoreCase) })
        if ($currentEntry.Count -ne 1 -or
            $currentEntry[0].Exists -ne $entry.Exists -or
            ($entry.Exists -and -not [string]::Equals([string]$currentEntry[0].Sha256, [string]$entry.Sha256, [StringComparison]::OrdinalIgnoreCase))) {
            throw "Repair did not preserve an automatic-start or automatic-update policy byte-exactly: $($entry.Path)"
        }
    }
}

function Get-RepairHostPlan {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if ($Plan.IsDowngrade -or $Plan.IsSequenceCollision) {
        return [pscustomobject]@{ Allowed = $false; Reason = "downgrade or sequence collision requires manual review"; QuarantinePaths = @() }
    }
    $marker = $Plan.Marker
    if ($null -eq $marker) {
        if (-not (Test-SafeFirstAdoptionPlan -Plan $Plan -ProjectRoot $ProjectRoot)) {
            return [pscustomobject]@{ Allowed = $false; Reason = "first adoption requires an empty CodeDB-managed target scope"; QuarantinePaths = @() }
        }
    } else {
        foreach ($item in @($Plan.Files | Where-Object { $_.IsTrackedOwnership })) {
            $isNewMissingTarget = $item.Status -eq "Missing" -and
                [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256)
            if ($item.Status -notin @("Current", "Upgradeable", "Adoptable") -and -not $isNewMissingTarget) {
                return [pscustomobject]@{ Allowed = $false; Reason = "tracked Host ownership is not byte-exact: $($item.Target)"; QuarantinePaths = @() }
            }
        }
        foreach ($retired in $Plan.Retired) {
            if ($retired.Status -ne "Retirable" -or $retired.Target -notmatch '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/') {
                return [pscustomobject]@{ Allowed = $false; Reason = "retired Host ownership requires manual review: $($retired.Target)"; QuarantinePaths = @() }
            }
        }
    }

    $generationLeaseReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($generationLeaseReport.Invalid.Count -gt 0) {
        return [pscustomobject]@{ Allowed = $false; Reason = "generation lease requires manual review: $($generationLeaseReport.Invalid[0])"; QuarantinePaths = @() }
    }
    $liveGenerationIds = @{}
    foreach ($lease in $generationLeaseReport.LiveDetails) { $liveGenerationIds[$lease.GenerationId] = $true }
    $quarantine = New-Object System.Collections.Generic.List[object]
    $candidateRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') -Label "package generation candidate"
    if (-not [string]::IsNullOrWhiteSpace([string]$Plan.RuntimeConflict) -and (Test-Path -LiteralPath $candidateRoot)) {
        if ($liveGenerationIds.ContainsKey($Manifest.GenerationId)) {
            return [pscustomobject]@{ Allowed = $false; Reason = "conflicted package generation has an active lease"; QuarantinePaths = @() }
        }
        if (-not (Test-Path -LiteralPath $candidateRoot -PathType Container)) {
            return [pscustomobject]@{ Allowed = $false; Reason = "package generation collision is not a directory"; QuarantinePaths = @() }
        }
        try {
            Assert-RepairCandidateCanBeQuarantined -Manifest $Manifest -CandidateRoot $candidateRoot -ProjectRoot $ProjectRoot
        } catch {
            return [pscustomobject]@{ Allowed = $false; Reason = $_.Exception.Message; QuarantinePaths = @() }
        }
        $quarantine.Add([pscustomobject]@{ Path = $candidateRoot; Reason = "generation-$($Manifest.GenerationId)" })
    }

    foreach ($pointerRelativePath in @($script:CurrentPointerRelativePath, $script:LastKnownGoodPointerRelativePath)) {
        $pointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $pointerRelativePath -Label "repair pointer"
        if (-not (Test-Path -LiteralPath $pointerPath)) { continue }
        if (-not (Test-Path -LiteralPath $pointerPath -PathType Leaf)) {
            return [pscustomobject]@{ Allowed = $false; Reason = "generation pointer is not a regular file: $pointerRelativePath"; QuarantinePaths = @() }
        }
        try {
            $null = Get-ValidatedInstalledGenerationPointer -PointerPath $pointerPath -ProjectRoot $ProjectRoot
        } catch {
            try {
                $pointerOwnership = Assert-RepairPointerCanBeQuarantined -PointerPath $pointerPath -ProjectRoot $ProjectRoot -Manifest $Manifest
            } catch {
                return [pscustomobject]@{ Allowed = $false; Reason = $_.Exception.Message; QuarantinePaths = @() }
            }
            if ($liveGenerationIds.ContainsKey($pointerOwnership.GenerationId)) {
                return [pscustomobject]@{ Allowed = $false; Reason = "generation pointer selects an active leased generation and cannot be quarantined: $($pointerOwnership.GenerationId)"; QuarantinePaths = @() }
            }
            $quarantine.Add([pscustomobject]@{ Path = $pointerPath; Reason = ([System.IO.Path]::GetFileNameWithoutExtension($pointerPath)) })
        }
    }
    return [pscustomobject]@{ Allowed = $true; Reason = "reviewed Host state can be reconstructed"; QuarantinePaths = $quarantine.ToArray() }
}

function Assert-RepairPlannedHostMutationsDoNotConflictWithMcp {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)]$RepairPlan,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($item in $RepairPlan.QuarantinePaths) {
        $paths.Add([string]$item.Path) | Out-Null
    }
    foreach ($item in $Plan.Files) {
        if ($item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            if ($item.Status -eq "Missing") {
                $paths.Add([string]$item.TargetPath) | Out-Null
            }
            continue
        }
        $needsWrite = $item.Status -in @("Missing", "Adoptable") -or
            ($item.Status -eq "Upgradeable" -and
             -not [string]::Equals([string]$item.TargetSha256, $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase))
        if ($needsWrite) {
            $paths.Add([string]$item.TargetPath) | Out-Null
        }
    }
    $markerJson = New-MarkerJson -Manifest $Manifest
    if ($null -eq $Plan.Marker -or
        -not [string]::Equals([string]$Plan.Marker.RawText, $markerJson, [StringComparison]::Ordinal)) {
        $paths.Add($MarkerPath) | Out-Null
    }
    $null = Assert-RepairMutationPathsDoNotConflictWithGenerationMcp `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $Manifest.Root `
        -Paths $paths.ToArray() `
        -Boundary "planned Host recovery"
}

function Invoke-Repair {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [switch]$InstallMode,
        [AllowNull()][ref]$ResultCleanupState,
        [AllowNull()]$ExistingLock,
        [AllowNull()][string]$InstallStateId
    )

    if ($InstallMode) {
        $null = Assert-ProjectIntegrationStateId -StateId $InstallStateId
    }
    $mcpPlanParameters = @{ ProjectRoot = $ProjectRoot }
    if ($InstallMode) {
        $mcpPlanParameters.RestoreUninstalledNamespace = $true
        $mcpPlanParameters.UninstallStateId = $InstallStateId
    }
    $lock = $ExistingLock
    $ownsLock = $null -eq $ExistingLock
    $hostTransactionRoot = $null
    $hostEntries = $null
    $keepTransaction = $false
    $hostCommitted = $false
    $repairResidualMutation = $false
    $repairPhase = "PREFLIGHT"
    Set-MaterializerCommandPhase -Phase $repairPhase
    $preservationSnapshot = $null
    try {
        # Invalid or ambiguous TOML must cause byte-exact zero writes.
        $mcpPlan = Get-RepairMcpConfigPlan @mcpPlanParameters
        $preLockPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        $preLockRepairPlan = Get-RepairHostPlan -Manifest $Manifest -Plan $preLockPlan -ProjectRoot $ProjectRoot
        if (-not $preLockRepairPlan.Allowed) {
            Throw-MaterializerError -Message "Repair Host preflight was blocked: $($preLockRepairPlan.Reason)." -ExitCode 4
        }
        if ($ownsLock) {
            $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot
        }
        # Re-check the config while holding the project materializer lock, then
        # snapshot preserved runtime bytes before any recovery mutation.
        $mcpPlan = Get-RepairMcpConfigPlan @mcpPlanParameters
        $preservationSnapshot = Get-RepairPreservationSnapshot -ProjectRoot $ProjectRoot
        $lockedPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        $lockedRepairPlan = Get-RepairHostPlan -Manifest $Manifest -Plan $lockedPlan -ProjectRoot $ProjectRoot
        if (-not $lockedRepairPlan.Allowed) {
            Throw-MaterializerError -Message "Repair Host preflight was blocked: $($lockedRepairPlan.Reason)." -ExitCode 4
        }
        Assert-RepairPlannedHostMutationsDoNotConflictWithMcp `
            -Manifest $Manifest `
            -Plan $lockedPlan `
            -RepairPlan $lockedRepairPlan `
            -ProjectRoot $ProjectRoot `
            -MarkerPath $MarkerPath
        Assert-RepairPendingRecoveryDoesNotConflictWithGenerationMcp `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $Manifest.Root
        $repairOwnerGate = Complete-RepairFlatHostUseGate `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $Manifest.Root
        Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerAction "repair"
        Invoke-TestRepairAfterMarkerHandshake
        $postMarkerGenerationWatchers = @()
        $postMarkerGenerationMcps = @()
        $postMarkerFlatMcps = @()
        Assert-RepairOwnerGateStable `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $Manifest.Root `
            -ExpectedGenerationWatchers @($repairOwnerGate.RetainedGenerationWatchers) `
            -RetainedGenerationWatchers ([ref]$postMarkerGenerationWatchers) `
            -RetainedGenerationMcps ([ref]$postMarkerGenerationMcps) `
            -RetainedFlatMcps ([ref]$postMarkerFlatMcps)
        $repairOwnerGate.RetainedGenerationWatchers = @($postMarkerGenerationWatchers)
        $repairOwnerGate.RetainedGenerationMcps = @($postMarkerGenerationMcps)
        $repairOwnerGate.RetainedFlatMcps = @($postMarkerFlatMcps)
        # Re-read both the journal targets and generation leases after the
        # active marker closes new Host-use acquisition.
        Assert-RepairPendingRecoveryDoesNotConflictWithGenerationMcp `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $Manifest.Root
        $null = Invoke-PendingTransactionRecovery `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -TargetRoot $TargetRoot `
            -MutationOccurred ([ref]$repairResidualMutation)
        $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        Write-MaterializationPlan -Plan $plan
        $repairPlan = Get-RepairHostPlan -Manifest $Manifest -Plan $plan -ProjectRoot $ProjectRoot
        if (-not $repairPlan.Allowed) {
            Throw-MaterializerError -Message "Repair Host preflight was blocked: $($repairPlan.Reason)." -ExitCode 4
        }
        Assert-RepairPlannedHostMutationsDoNotConflictWithMcp `
            -Manifest $Manifest `
            -Plan $plan `
            -RepairPlan $repairPlan `
            -ProjectRoot $ProjectRoot `
            -MarkerPath $MarkerPath
        $retainedGenerationWatchers = @()
        $retainedGenerationMcps = @()
        $retainedFlatMcps = @()
        Assert-RepairOwnerGateStable `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $Manifest.Root `
            -ExpectedGenerationWatchers @($repairOwnerGate.RetainedGenerationWatchers) `
            -RetainedGenerationWatchers ([ref]$retainedGenerationWatchers) `
            -RetainedGenerationMcps ([ref]$retainedGenerationMcps) `
            -RetainedFlatMcps ([ref]$retainedFlatMcps)
        $repairOwnerGate.RetainedGenerationWatchers = @($retainedGenerationWatchers)
        $repairOwnerGate.RetainedGenerationMcps = @($retainedGenerationMcps)
        $repairOwnerGate.RetainedFlatMcps = @($retainedFlatMcps)
        Write-Host "[PHASE PREFLIGHT] OK - Package-owned recovery and project MCP registration passed validation."

        $repairPhase = "HOST_RUNTIME"
        Set-MaterializerCommandPhase -Phase $repairPhase
        $quarantineRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath ($script:HostQuarantineRelativePath + "/repair-$([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))-$([guid]::NewGuid().ToString('N').Substring(0,8))") -Label "repair quarantine"
        foreach ($item in $repairPlan.QuarantinePaths) {
            $null = Move-RepairPathToQuarantine `
                -Path $item.Path `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $Manifest.Root `
                -Reason $item.Reason `
                -QuarantineRoot $quarantineRoot `
                -MutationOccurred ([ref]$repairResidualMutation)
        }
        if ($repairPlan.QuarantinePaths.Count -gt 0) {
            $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        }

        $hostTransactionRoot = Join-Path $lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $stageRoot = Join-Path $hostTransactionRoot "stage"
        $backupRoot = Join-Path $hostTransactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $stageRoot, $backupRoot | Out-Null
        $hostEntries = New-Object System.Collections.Generic.List[object]
        if (-not $plan.IsCurrent) {
            Write-Host "[PHASE HOST_RUNTIME] REPAIRING - reconstructing immutable generation $($Manifest.GenerationId)."
            $null = Publish-ImmutableGeneration `
                -Manifest $Manifest `
                -ProjectRoot $ProjectRoot `
                -TransactionRoot $hostTransactionRoot `
                -RepairPayloadRoot $Manifest.Root `
                -MutationOccurred ([ref]$repairResidualMutation)
        }

        foreach ($item in @($plan.Files | Sort-Object @{ Expression = { if ([string]::Equals($_.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) { 1 } else { 0 } } }, Target)) {
            if ($item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) { continue }
            $needsWrite = $item.Status -in @("Missing", "Adoptable") -or
                ($item.Status -eq "Upgradeable" -and -not [string]::Equals([string]$item.TargetSha256, $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase))
            if (-not $needsWrite) { continue }
            $stagePath = Join-Path $stageRoot (([guid]::NewGuid().ToString("N")) + ".payload")
            Copy-Item -LiteralPath $item.SourcePath -Destination $stagePath -Force
            if (-not [string]::Equals((Get-FileSha256 -Path $stagePath), $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Repair Host staging hash mismatch: $($item.Target)"
            }
            $hostEntries.Add((New-TransactionEntry -Target $item.Target -TargetPath $item.TargetPath -Mutation "Write" -DesiredSha256 $item.SourceSha256 -StagePath $stagePath -BackupRoot $backupRoot -Index $hostEntries.Count)) | Out-Null
        }

        $markerJson = New-MarkerJson -Manifest $Manifest
        $markerCurrent = $null -ne $plan.Marker -and
            [string]::Equals([string]$plan.Marker.RawText, $markerJson, [StringComparison]::Ordinal)
        if (-not $markerCurrent) {
            $markerStagePath = Join-Path $stageRoot ".rice-ai-codedb-payload.json"
            Write-DurableUtf8File -Path $markerStagePath -Content $markerJson
            $hostEntries.Add((New-TransactionEntry -Target $script:MarkerRelativePath -TargetPath $MarkerPath -Mutation "Write" -DesiredSha256 (Get-FileSha256 -Path $markerStagePath) -StagePath $markerStagePath -BackupRoot $backupRoot -Index $hostEntries.Count)) | Out-Null
        }

        $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "repaired current pointer"
        $currentSource = $Manifest.TargetMap[$script:CurrentPointerRelativePath]
        $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "repaired last-known-good pointer"
        $lkgCurrent = $false
        if (Test-Path -LiteralPath $lastKnownGoodPath -PathType Leaf) {
            try {
                $validatedLkg = Get-ValidatedInstalledGenerationPointer -PointerPath $lastKnownGoodPath -ProjectRoot $ProjectRoot
                $lkgCurrent = $null -ne $validatedLkg
            } catch {
                $lkgCurrent = $false
            }
        }
        if (-not $lkgCurrent) {
            $lkgStagePath = Join-Path $stageRoot "last-known-good.pointer"
            if ($null -ne $plan.SelectedGeneration -and
                -not [string]::Equals($plan.SelectedGeneration.GenerationId, $Manifest.GenerationId, [StringComparison]::Ordinal)) {
                Write-DurableUtf8File -Path $lkgStagePath -Content $plan.SelectedGeneration.Text
            } else {
                Copy-Item -LiteralPath $currentSource.SourcePath -Destination $lkgStagePath -Force
            }
            $hostEntries.Add((New-TransactionEntry -Target $script:LastKnownGoodPointerRelativePath -TargetPath $lastKnownGoodPath -Mutation "Write" -DesiredSha256 (Get-FileSha256 -Path $lkgStagePath) -StagePath $lkgStagePath -BackupRoot $backupRoot -Index $hostEntries.Count)) | Out-Null
        }

        if ($hostEntries.Count -gt 0) {
            $null = Assert-RepairMutationPathsDoNotConflictWithGenerationMcp `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $Manifest.Root `
                -Paths @($hostEntries | ForEach-Object { $_.TargetPath }) `
                -Boundary "Host transaction publication"
            Write-TransactionJournal -Operation "Sync" -TransactionRoot $hostTransactionRoot -Entries $hostEntries.ToArray() -Manifest $Manifest
            foreach ($entry in $hostEntries) {
                Assert-TransactionEntryBeforeMutation -Entry $entry
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
                Publish-TransactionFile -StagePath $entry.StagePath -TargetPath $entry.TargetPath
                if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), $entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Repair Host publication hash mismatch: $($entry.Target)"
                }
                Add-MaterializerMutationScope -Scope "host_runtime"
                Invoke-TestFaultAfterMutation
            }
        }

        $postPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if (-not $postPlan.IsCurrent) { throw "Repair Host verification did not reach the current state." }
        $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
        $lastKnownGood = Get-ValidatedInstalledGenerationPointer -PointerPath $lastKnownGoodPath -ProjectRoot $ProjectRoot
        if ($null -eq $current -or $null -eq $lastKnownGood) { throw "Repair Host pointer verification failed." }

        $hostCommitted = $true
        if (Test-Path -LiteralPath $hostTransactionRoot) {
            Remove-Item -LiteralPath $hostTransactionRoot -Recurse -Force
        }
        $hostTransactionRoot = $null
        Write-Host "[PHASE HOST_RUNTIME] REPAIRED - current and rollback pointers select validated immutable generations."

        $repairPhase = "WATCHER"
        Set-MaterializerCommandPhase -Phase $repairPhase
        $retainedPreviousWatchers = @($repairOwnerGate.RetainedGenerationWatchers | Where-Object {
            -not [string]::Equals([string]$_.GenerationId, $Manifest.GenerationId, [StringComparison]::Ordinal)
        })
        if ($TestFailWatcherHandoff) { throw "Injected POC non-terminating watcher verification failure." }
        if ($repairOwnerGate.LegacyWatcherStopped) {
            Write-Host "[PHASE WATCHER] STOPPED - authenticated Package-owned legacy watcher will restart after Host and MCP verification."
        } elseif ($repairOwnerGate.RetainedGenerationWatchers.Count -gt 0) {
            foreach ($watcher in $repairOwnerGate.RetainedGenerationWatchers) {
                Write-Host "[PHASE WATCHER] RETAINED - generation $($watcher.GenerationId) watcher PID $($watcher.ProcessId) remains pinned to its immutable Host closure."
            }
        } else {
            Write-Host "[PHASE WATCHER] PENDING - no authenticated watcher is active; Repair will ensure the current Package-owned watcher after registration verification."
        }

        $repairPhase = "PRESERVATION"
        Set-MaterializerCommandPhase -Phase $repairPhase
        Assert-RepairPreservationSnapshot -Snapshot $preservationSnapshot
        Write-Host "[PHASE PRESERVATION] PRESERVED - Provider, runtime config, index, adapter, and user policy bytes are unchanged."

        $repairPhase = "MCP_REGISTRATION"
        Set-MaterializerCommandPhase -Phase $repairPhase
        $latestRetainedGenerationWatchers = @()
        $latestRetainedGenerationMcps = @()
        $latestRetainedFlatMcps = @()
        Assert-RepairOwnerGateStable `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -PayloadRoot $Manifest.Root `
            -ExpectedGenerationWatchers @($repairOwnerGate.RetainedGenerationWatchers) `
            -RetainedGenerationWatchers ([ref]$latestRetainedGenerationWatchers) `
            -RetainedGenerationMcps ([ref]$latestRetainedGenerationMcps) `
            -RetainedFlatMcps ([ref]$latestRetainedFlatMcps)
        $repairOwnerGate.RetainedGenerationWatchers = @($latestRetainedGenerationWatchers)
        $repairOwnerGate.RetainedGenerationMcps = @($latestRetainedGenerationMcps)
        $repairOwnerGate.RetainedFlatMcps = @($latestRetainedFlatMcps)
        $retainedPreviousWatchers = @($latestRetainedGenerationWatchers | Where-Object {
            -not [string]::Equals([string]$_.GenerationId, $Manifest.GenerationId, [StringComparison]::Ordinal)
        })
        if ($TestFailRepairMcpRegistration) { throw "Injected POC MCP registration repair failure." }
        $null = Publish-RepairMcpConfig -Plan $mcpPlan -ProjectRoot $ProjectRoot -Lock $lock
        $verifiedMcpPlan = Get-RepairMcpConfigPlan @mcpPlanParameters
        if (-not $verifiedMcpPlan.Current) { throw "Project MCP registration verification failed." }
        $repairPhase = "VERIFY"
        Set-MaterializerCommandPhase -Phase $repairPhase
        $verificationMessage = if ($repairOwnerGate.LegacyWatcherStopped) {
            "Repair CodeDB verified generation $($Manifest.GenerationId) and project MCP registration before restarting the authenticated Package-owned watcher."
        } else {
            "Repair CodeDB verified generation $($Manifest.GenerationId) and project MCP registration without changing MCP or watcher processes."
        }
        Write-Host "[PHASE VERIFY] OK - Host generation and project MCP registration are current; existing clients retain their leased immutable generations."
        $shouldEnsureCurrentWatcher = $repairOwnerGate.LegacyWatcherStopped -or
            ($latestRetainedGenerationWatchers.Count -eq 0 -and
             $latestRetainedGenerationMcps.Count -eq 0 -and
             $latestRetainedFlatMcps.Count -eq 0)
        if ($shouldEnsureCurrentWatcher) {
            $repairPhase = "WATCHER"
            Set-MaterializerCommandPhase -Phase $repairPhase
            if ($lock.ActiveMarkerPublished -and (Test-Path -LiteralPath $lock.ActiveMarkerPath -PathType Leaf)) {
                Remove-Item -LiteralPath $lock.ActiveMarkerPath -Force
                $lock.ActiveMarkerPublished = $false
            }
            Exit-MaterializerWatchManagementLocks -Lock $lock
            Invoke-UpgradeWatcherEnsure `
                -WatchManagerPath $current.WatchManagerPath `
                -ProjectRoot $ProjectRoot `
                -Label "repaired generation" `
                -WithoutMaterializerHandoff
            if (-not $PocFixture) {
                $lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
                Enter-MaterializerWatchManagementLocks -Lock $lock -ProjectRoot $ProjectRoot
                $validatedRestartedWatchers = @()
                Assert-NoLiveLegacyWatcherState `
                    -Lock $lock `
                    -ProjectRoot $ProjectRoot `
                    -PayloadRoot $PayloadRoot `
                    -AllowGenerationOwnedWatcher `
                    -RetainedGenerationWatchers ([ref]$validatedRestartedWatchers)
                $currentRestartedWatchers = @($validatedRestartedWatchers | Where-Object {
                    [string]::Equals([string]$_.GenerationId, $current.GenerationId, [StringComparison]::Ordinal)
                })
                if ($currentRestartedWatchers.Count -ne 1) {
                    throw "Authenticated Package-owned watcher restart did not produce exactly one validated current-generation owner."
                }
            }
            if ($repairOwnerGate.LegacyWatcherStopped) {
                Write-Host "[PHASE WATCHER] RESTARTED - authenticated Package-owned watcher now uses generation $($current.GenerationId)."
            } elseif ($PocFixture) {
                Write-Host "[PHASE WATCHER] FIXTURE - process start is suppressed in fixture mode and covered by the production-path integration test."
            } else {
                Write-Host "[PHASE WATCHER] STARTED - current Package-owned watcher now uses generation $($current.GenerationId)."
            }
        } elseif ($latestRetainedGenerationWatchers.Count -eq 0) {
            Write-Host "[PHASE WATCHER] PRESERVED - active MCP owners retain their immutable closure; Repair did not stop or replace their processes."
        }
        $repairPhase = "MCP_AVAILABLE"
        Set-MaterializerCommandPhase -Phase $repairPhase
        Open-McpAvailabilityProbeWindow -Lock $lock -ProjectRoot $ProjectRoot
        $availability = Invoke-McpAvailabilityProbe -Manifest $Manifest -ProjectRoot $ProjectRoot -Lock $lock
        if (-not $availability.Current) {
            throw "Package-owned MCP handshake did not reach MCP_AVAILABLE."
        }
        $cleanup = Invoke-AutomaticGenerationCleanup `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -Lock $lock `
            -Plan $lockedPlan
        $cleanupState = [string]$cleanup.CleanupState
        $null = Ensure-MaterializerUpgradeStateCurrent `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -Message $verificationMessage `
            -CleanupState $cleanupState
        $postCleanupPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        Write-ProductLayerStatus `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -Plan $postCleanupPlan `
            -CleanupState $cleanupState
        if ($null -ne $ResultCleanupState) { $ResultCleanupState.Value = $cleanupState }
        Write-Host "[CLEANUP_STATE] $cleanupState"
        if (-not $InstallMode) {
            Set-MaterializerCommandPhase -Phase "COMPLETE"
            Set-MaterializerCommandOutcome `
                -Outcome "REPAIRED" `
                -ReasonCode "REPAIR_COMPLETE" `
                -CleanupState $cleanupState `
                -NextAction "Start a new Codex task so it reads the repaired project MCP configuration."
            Write-Host "[RESULT] REPAIRED"
            Write-Host "[PRODUCT_STATE] READY"
            Write-Host "[NEXT] Start a new Codex session so it reads the repaired project MCP configuration."
        }
    } catch {
        $originalError = $_.Exception
        Set-MaterializerCommandPhase -Phase $repairPhase
        if ($hostCommitted -or $repairResidualMutation) {
            Set-MaterializerCommandOutcome `
                -Outcome "PARTIALLY_REPAIRED" `
                -ReasonCode "REPAIR_PARTIAL" `
                -CleanupState "PENDING" `
                -NextAction "Review the reported Repair phase, then use Fix CodeDB once after the boundary is resolved."
        } else {
            Set-MaterializerCommandOutcome `
                -Outcome "BLOCKED" `
                -ReasonCode "REPAIR_BLOCKED" `
                -CleanupState "COMPLETE" `
                -NextAction "Resolve the reported ownership or configuration boundary, then use Fix CodeDB once."
        }
        if (-not $hostCommitted -and $null -ne $hostTransactionRoot -and $null -ne $hostEntries -and $hostEntries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $hostEntries.ToArray() -TransactionRoot $hostTransactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
            if ($rollbackErrors.Count -gt 0) {
                $keepTransaction = $true
                Write-Host "[PHASE HOST_RUNTIME] BLOCKED - rollback was incomplete."
                Write-Host "[RESULT] BLOCKED"
                Write-Host "[NEXT] Review the retained materializer transaction before retrying Repair CodeDB."
                Throw-MaterializerError -Message "Repair failed and Host rollback was incomplete. $($rollbackErrors -join '; ')" -ExitCode 7
            }
        }
        if ($hostCommitted -and [string]::Equals($repairPhase, "WATCHER", [StringComparison]::Ordinal)) {
            Write-Host "[PHASE WATCHER] BLOCKED - $($originalError.Message)"
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[NEXT] Resolve the reported watcher runtime boundary, then click Repair CodeDB again."
            Throw-MaterializerError -Message $originalError.Message -ExitCode 8
        }
        if ($hostCommitted -and [string]::Equals($repairPhase, "PRESERVATION", [StringComparison]::Ordinal)) {
            Write-Host "[PHASE PRESERVATION] BLOCKED - $($originalError.Message)"
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[NEXT] Resolve the reported preserved-runtime boundary, then click Repair CodeDB again."
            Throw-MaterializerError -Message $originalError.Message -ExitCode 8
        }
        if ($hostCommitted -and [string]::Equals($repairPhase, "MCP_REGISTRATION", [StringComparison]::Ordinal)) {
            Write-Host "[PHASE MCP_REGISTRATION] BLOCKED - $($originalError.Message)"
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[NEXT] Resolve the reported project MCP config boundary, then click Repair CodeDB again."
            Throw-MaterializerError -Message $originalError.Message -ExitCode 8
        }
        if ($hostCommitted -and [string]::Equals($repairPhase, "VERIFY", [StringComparison]::Ordinal)) {
            Write-Host "[PHASE VERIFY] BLOCKED - $($originalError.Message)"
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[NEXT] Resolve the reported verification-state boundary, then click Repair CodeDB again."
            Throw-MaterializerError -Message $originalError.Message -ExitCode 8
        }
        if ($hostCommitted -and [string]::Equals($repairPhase, "MCP_AVAILABLE", [StringComparison]::Ordinal)) {
            Write-Host "[PHASE MCP_AVAILABLE] BLOCKED - $($originalError.Message)"
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[PRODUCT_STATE] NEEDS_ATTENTION"
            if ($InstallMode) {
                Write-Host "[NEXT] Install remains incomplete and will be retried by the Package; no external process was stopped."
            } else {
                Write-Host "[NEXT] CodeDB will retry automatically; use Fix CodeDB only if Needs attention remains."
            }
            Throw-MaterializerError -Message $originalError.Message -ExitCode 8
        }
        if ($repairResidualMutation) {
            Write-Host "[PHASE $repairPhase] BLOCKED - $($originalError.Message)"
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[NEXT] Resolve the reported Host boundary, then click Repair CodeDB again."
            if ($script:RequestedExitCode -ne 0) { throw $originalError }
            Throw-MaterializerError -Message $originalError.Message -ExitCode 8
        }
        Write-Host "[PHASE $repairPhase] BLOCKED - $($originalError.Message)"
        Write-Host "[RESULT] BLOCKED"
        Write-Host "[NEXT] Resolve the reported unsafe Host or configuration boundary, then click Repair CodeDB again."
        if ($script:RequestedExitCode -ne 0) { throw $originalError }
        Throw-MaterializerError -Message $originalError.Message -ExitCode 4
    } finally {
        if ($null -ne $hostTransactionRoot -and -not $keepTransaction -and (Test-Path -LiteralPath $hostTransactionRoot)) {
            Remove-Item -LiteralPath $hostTransactionRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($ownsLock) {
            Exit-MaterializerLock -Lock $lock
        }
    }
}

function Get-ValidatedInstalledGenerationPointer {
    param(
        [Parameter(Mandatory = $true)][string]$PointerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $PointerPath -PathType Leaf)) {
        return $null
    }
    Assert-NoReparsePoint -Path $PointerPath -Root $ProjectRoot -Label "installed generation pointer"
    $pointerJson = Read-BoundedJsonDocument -Path $PointerPath -Label "installed generation pointer" -MaximumBytes (64 * 1024)
    $pointer = $pointerJson.Document
    $generationId = Get-RequiredJsonString -Object $pointer -Name "generation_id" -Label "installed generation pointer"
    $generationRelativePath = ConvertTo-SafeRelativePath `
        -Path (Get-RequiredJsonString -Object $pointer -Name "generation_relative_path" -Label "installed generation pointer") `
        -Label "installed generation path"
    $manifestSha256 = (Get-RequiredJsonString -Object $pointer -Name "generation_manifest_sha256" -Label "installed generation pointer").ToLowerInvariant()
    $pointerBootstrapProtocol = Get-RequiredJsonInt32 -Object $pointer -Name "bootstrap_protocol" -Label "installed generation pointer"
    $pointerPackageVersion = Get-RequiredJsonString -Object $pointer -Name "package_version" -Label "installed generation pointer"
    $pointerPayloadVersion = Get-RequiredJsonString -Object $pointer -Name "payload_version" -Label "installed generation pointer"
    $pointerPayloadSequence = Get-RequiredJsonInt32 -Object $pointer -Name "payload_sequence" -Label "installed generation pointer"
    $expectedRelativePath = "AIWork/.runtime/codedb/host/generations/$generationId"
    if ((Get-RequiredJsonInt32 -Object $pointer -Name "schema_version" -Label "installed generation pointer") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "managed_by" -Label "installed generation pointer"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($pointerPackageVersion) -or
        [string]::IsNullOrWhiteSpace($pointerPayloadVersion) -or
        $pointerPayloadSequence -lt 1 -or
        $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
        -not [string]::Equals($generationRelativePath, $expectedRelativePath, [StringComparison]::Ordinal) -or
        $manifestSha256 -notmatch '^[0-9a-f]{64}$' -or
        $pointerBootstrapProtocol -lt 1 -or
        $pointerBootstrapProtocol -gt $script:SupportedBootstrapProtocol) {
        throw "Installed generation pointer identity is invalid."
    }

    $generationRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $generationRelativePath -Label "installed generation"
    Assert-NoReparsePoint -Path $generationRoot -Root $ProjectRoot -Label "installed generation"
    $generationManifestPath = Join-Path $generationRoot "generation-manifest.json"
    $generationJson = Read-BoundedJsonDocument -Path $generationManifestPath -Label "installed generation manifest" -MaximumBytes (1024 * 1024)
    if (-not [string]::Equals((Get-FileSha256 -Path $generationManifestPath), $manifestSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Installed generation manifest hash does not match its pointer."
    }
    $generation = $generationJson.Document
    $generationFiles = Get-RequiredJsonArray -Object $generation -Name "files" -Label "installed generation manifest"
    if ((Get-RequiredJsonInt32 -Object $generation -Name "schema_version" -Label "installed generation manifest") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "managed_by" -Label "installed generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "generation_id" -Label "installed generation manifest"), $generationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "package_version" -Label "installed generation manifest"), $pointerPackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generation -Name "payload_version" -Label "installed generation manifest"), $pointerPayloadVersion, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $generation -Name "payload_sequence" -Label "installed generation manifest") -ne $pointerPayloadSequence -or
        (Get-RequiredJsonInt32 -Object $generation -Name "bootstrap_protocol" -Label "installed generation manifest") -ne $pointerBootstrapProtocol -or
        $generationFiles.Count -eq 0) {
        throw "Installed generation manifest identity does not match its pointer."
    }

    $seen = @{}
    $managedFiles = New-Object System.Collections.Generic.List[object]
    $managedFiles.Add([pscustomobject]@{ Path = $generationManifestPath; Sha256 = $manifestSha256 })
    foreach ($entry in $generationFiles) {
        $null = Assert-JsonObject -Value $entry -Label "installed generation file"
        $relativePath = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "path" -Label "installed generation file") -Label "installed generation file"
        $sha256 = (Get-RequiredJsonString -Object $entry -Name "sha256" -Label "installed generation file").ToLowerInvariant()
        if ($sha256 -notmatch '^[0-9a-f]{64}$' -or $seen.ContainsKey($relativePath)) {
            throw "Installed generation manifest contains an invalid or duplicate file: $relativePath"
        }
        $seen[$relativePath] = $true
        $filePath = ConvertTo-AbsoluteChildPath -Root $generationRoot -RelativePath $relativePath -Label "installed generation file"
        Assert-NoReparsePoint -Path $filePath -Root $generationRoot -Label "installed generation file"
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $filePath), $sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Installed generation file is missing or has drifted: $relativePath"
        }
        $managedFiles.Add([pscustomobject]@{ Path = $filePath; Sha256 = $sha256 })
    }
    Assert-ImmutableGenerationFilesystemClosure `
        -Root $generationRoot `
        -ExpectedFiles (@("generation-manifest.json") + @($seen.Keys)) `
        -Label "installed immutable generation"

    return [pscustomobject]@{
        Text = $pointerJson.Text
        Document = $pointer
        GenerationId = $generationId
        PackageVersion = $pointerPackageVersion
        PayloadVersion = $pointerPayloadVersion
        PayloadSequence = $pointerPayloadSequence
        BootstrapProtocol = $pointerBootstrapProtocol
        GenerationManifestSha256 = $manifestSha256
        GenerationRoot = $generationRoot
        WatchManagerPath = Join-Path $generationRoot "scripts\manage-codedb-project-watch.ps1"
        ManagedFiles = $managedFiles.ToArray()
    }
}

function Read-GenerationPointerIdentity {
    param(
        [Parameter(Mandatory = $true)][string]$PointerPath,
        [Parameter(Mandatory = $true)][string]$PointerLabel,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    Assert-NoReparsePoint -Path $PointerPath -Root $ProjectRoot -Label $PointerLabel
    $pointerJson = Read-BoundedJsonDocument -Path $PointerPath -Label $PointerLabel -MaximumBytes (64 * 1024)
    $pointer = $pointerJson.Document
    $generationId = Get-RequiredJsonString -Object $pointer -Name "generation_id" -Label $PointerLabel
    $generationRelativePath = ConvertTo-SafeRelativePath `
        -Path (Get-RequiredJsonString -Object $pointer -Name "generation_relative_path" -Label $PointerLabel) `
        -Label "$PointerLabel generation path"
    $manifestSha256 = (Get-RequiredJsonString -Object $pointer -Name "generation_manifest_sha256" -Label $PointerLabel).ToLowerInvariant()
    $bootstrapProtocol = Get-RequiredJsonInt32 -Object $pointer -Name "bootstrap_protocol" -Label $PointerLabel
    $payloadSequence = Get-RequiredJsonInt32 -Object $pointer -Name "payload_sequence" -Label $PointerLabel
    $packageVersion = Get-RequiredJsonString -Object $pointer -Name "package_version" -Label $PointerLabel
    $payloadVersion = Get-RequiredJsonString -Object $pointer -Name "payload_version" -Label $PointerLabel
    $expectedRelativePath = "AIWork/.runtime/codedb/host/generations/$generationId"
    if ((Get-RequiredJsonInt32 -Object $pointer -Name "schema_version" -Label $PointerLabel) -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $pointer -Name "managed_by" -Label $PointerLabel), $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
        -not [string]::Equals($generationRelativePath, $expectedRelativePath, [StringComparison]::Ordinal) -or
        $manifestSha256 -notmatch '^[0-9a-f]{64}$' -or
        $payloadSequence -lt 1 -or
        $bootstrapProtocol -lt 1 -or
        $bootstrapProtocol -gt $script:SupportedBootstrapProtocol) {
        throw "$PointerLabel identity is invalid."
    }
    return [pscustomobject]@{
        Text = $pointerJson.Text
        GenerationId = $generationId
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        BootstrapProtocol = $bootstrapProtocol
        GenerationManifestSha256 = $manifestSha256
        GenerationRelativePath = $generationRelativePath
    }
}

function Assert-RemovalGenerationIdentityUpperBound {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Selection,
        [Parameter(Mandatory = $true)][string]$PointerLabel
    )

    $disposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $Selection
    if ([string]::Equals($disposition, "NEWER", [StringComparison]::Ordinal)) {
        Write-Host "[CONFLICT] Downgrade: $PointerLabel selects newer generation $($Selection.GenerationId), sequence $($Selection.PayloadSequence)."
        Throw-MaterializerError -Message "Payload removal was rejected because an older manifest cannot remove the generation selected by $PointerLabel." -ExitCode 3
    }
    if ([string]::Equals($disposition, "SEQUENCE_COLLISION", [StringComparison]::Ordinal)) {
        Write-Host "[CONFLICT] SequenceCollision: $PointerLabel selects a different generation identity at sequence $($Manifest.PayloadSequence)."
        Throw-MaterializerError -Message "Payload removal was rejected because $PointerLabel does not match this manifest identity." -ExitCode 3
    }
    $packageIdentity = Get-PackageGenerationIdentityForRuntimeIdentity -Manifest $Manifest -Identity $Selection
    if ($null -eq $packageIdentity -or
        -not [string]::Equals(
            [string]$Selection.GenerationManifestSha256,
            [string]$packageIdentity.GenerationManifestSha256,
            [StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "[CONFLICT] InvalidIdentity: $PointerLabel is not current or an exact Package-declared transition."
        Throw-MaterializerError -Message "Payload removal was rejected because $PointerLabel has no authenticated Package runtime identity." -ExitCode 3
    }
}

function Assert-RemovalTransactionProvenanceUpperBound {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)][string]$TransactionId
    )

    if ($null -eq $Journal.Provenance) {
        Throw-MaterializerError -Message "Payload removal was rejected because pending transaction $TransactionId has no package/generation provenance." -ExitCode 3
    }
    $provenance = $Journal.Provenance
    $disposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $provenance
    if ([string]::Equals($disposition, "NEWER", [StringComparison]::Ordinal)) {
        Write-Host "[CONFLICT] Downgrade: pending transaction $TransactionId belongs to newer generation $($provenance.GenerationId), sequence $($provenance.PayloadSequence)."
        Throw-MaterializerError -Message "Payload removal was rejected because an older manifest cannot recover a newer transaction." -ExitCode 3
    }
    if ([string]::Equals($disposition, "SEQUENCE_COLLISION", [StringComparison]::Ordinal)) {
        Write-Host "[CONFLICT] SequenceCollision: pending transaction $TransactionId has another package/generation identity at sequence $($Manifest.PayloadSequence)."
        Throw-MaterializerError -Message "Payload removal was rejected because a pending transaction does not match this manifest identity." -ExitCode 3
    }

    if (-not $Manifest.UsesGenerationContract) {
        $identityMatches = [string]::Equals($provenance.PackageVersion, $Manifest.PackageVersion, [StringComparison]::Ordinal) -and
            [string]::Equals($provenance.PayloadVersion, $Manifest.PayloadVersion, [StringComparison]::Ordinal) -and
            $provenance.PayloadSequence -eq $Manifest.PayloadSequence -and
            [string]::Equals($provenance.PayloadContentSha256, (Get-PayloadContentIdentitySha256 -Manifest $Manifest), [StringComparison]::OrdinalIgnoreCase) -and
            $null -eq $provenance.GenerationManifestSha256
        if (-not $identityMatches) {
            Throw-MaterializerError -Message "Payload removal was rejected because a pending transaction does not match this non-generation manifest identity." -ExitCode 3
        }
        return
    }

    $packageIdentity = Get-PackageGenerationIdentityForRuntimeIdentity -Manifest $Manifest -Identity $provenance
    $currentContentMatches = -not [string]::Equals($disposition, "CURRENT", [StringComparison]::Ordinal) -or
        [string]::Equals($provenance.PayloadContentSha256, (Get-PayloadContentIdentitySha256 -Manifest $Manifest), [StringComparison]::OrdinalIgnoreCase)
    if ($null -eq $packageIdentity -or
        -not $currentContentMatches -or
        -not [string]::Equals(
            [string]$provenance.GenerationManifestSha256,
            [string]$packageIdentity.GenerationManifestSha256,
            [StringComparison]::OrdinalIgnoreCase)) {
        Write-Host "[CONFLICT] InvalidIdentity: pending transaction $TransactionId is not current or an exact Package-declared transition."
        Throw-MaterializerError -Message "Payload removal was rejected because a pending transaction has no authenticated Package runtime identity." -ExitCode 3
    }
}

function Assert-RemovalPendingTransactionUpperBound {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    foreach ($record in @(Get-PendingMaterializerTransactionRecords -Lock $Lock -ProjectRoot $ProjectRoot)) {
        if ($null -eq $record.Journal) {
            Throw-MaterializerError -Message "Payload removal was rejected because pending transaction $($record.Id) has no durable provenance journal." -ExitCode 3
        }
        Assert-RemovalTransactionProvenanceUpperBound -Manifest $Manifest -Journal $record.Journal -TransactionId $record.Id
        foreach ($pointer in @(
            [pscustomobject]@{ Target = $script:CurrentPointerRelativePath; Label = "current.json backup in $($record.Id)" },
            [pscustomobject]@{ Target = $script:LastKnownGoodPointerRelativePath; Label = "last-known-good.json backup in $($record.Id)" }
        )) {
            $entry = @($record.Journal.Entries | Where-Object {
                $_.ExistedBefore -and [string]::Equals([string]$_.Target, $pointer.Target, [StringComparison]::OrdinalIgnoreCase)
            })
            if ($entry.Count -gt 1) {
                Throw-MaterializerError -Message "Payload removal was rejected because pending transaction $($record.Id) duplicates $($pointer.Target)." -ExitCode 3
            }
            if ($entry.Count -eq 1) {
                try {
                    $selection = Read-GenerationPointerIdentity -PointerPath $entry[0].BackupPath -PointerLabel $pointer.Label -ProjectRoot $record.Root
                } catch {
                    Throw-MaterializerError -Message "Payload removal was rejected because $($pointer.Label) is invalid: $($_.Exception.Message)" -ExitCode 3
                }
                Assert-RemovalGenerationIdentityUpperBound -Manifest $Manifest -Selection $selection -PointerLabel $pointer.Label
            }
        }
        $markerEntry = @($record.Journal.Entries | Where-Object {
            $_.ExistedBefore -and [string]::Equals([string]$_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase)
        })
        if ($markerEntry.Count -gt 1) {
            Throw-MaterializerError -Message "Payload removal was rejected because pending transaction $($record.Id) duplicates the ownership marker." -ExitCode 3
        }
        if ($markerEntry.Count -eq 1) {
            try {
                $backupMarker = Read-InstalledMarker -MarkerPath $markerEntry[0].BackupPath -ProjectRoot $record.Root
            } catch {
                Throw-MaterializerError -Message "Payload removal was rejected because the marker backup in $($record.Id) is invalid: $($_.Exception.Message)" -ExitCode 3
            }
            $backupPolicy = Get-InstalledPayloadVersionPolicy -Manifest $Manifest -Marker $backupMarker
            if ($backupPolicy.IsDowngrade -or $backupPolicy.IsSequenceCollision -or $backupPolicy.IsInvalid) {
                Throw-MaterializerError -Message "Payload removal was rejected because the marker backup in $($record.Id) exceeds this manifest identity." -ExitCode 3
            }
        }
    }
}

function Assert-RemovalPendingTransactionUpperBoundBeforeLock {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $runtimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer recovery runtime"
    if (-not (Test-Path -LiteralPath $runtimeRoot)) {
        return
    }
    if (-not (Test-Path -LiteralPath $runtimeRoot -PathType Container)) {
        Throw-MaterializerError -Message "Payload removal was rejected because the materializer recovery runtime is not a directory: $runtimeRoot" -ExitCode 3
    }
    Assert-NoReparsePoint -Path $runtimeRoot -Root $ProjectRoot -Label "materializer recovery runtime"
    $readOnlyLockView = [pscustomobject]@{ Root = $runtimeRoot }
    Assert-RemovalPendingTransactionUpperBound -Manifest $Manifest -Lock $readOnlyLockView -ProjectRoot $ProjectRoot
}

function Assert-RemovalGenerationPointerUpperBound {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$PointerPath,
        [Parameter(Mandatory = $true)][string]$PointerLabel,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $PointerPath)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $PointerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Payload removal was rejected because $PointerLabel is not a regular file." -ExitCode 3
    }
    try {
        $selection = Get-ValidatedInstalledGenerationPointer -PointerPath $PointerPath -ProjectRoot $ProjectRoot
    } catch {
        Throw-MaterializerError -Message "Payload removal was rejected because $PointerLabel is invalid: $($_.Exception.Message)" -ExitCode 3
    }
    Assert-RemovalGenerationIdentityUpperBound -Manifest $Manifest -Selection $selection -PointerLabel $PointerLabel
    return $selection
}

function Assert-RemovalIdentityUpperBound {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $marker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    if ($null -ne $marker) {
        $versionPolicy = Get-InstalledPayloadVersionPolicy -Manifest $Manifest -Marker $marker
        if ($versionPolicy.IsDowngrade) {
            Write-Host "[CONFLICT] Downgrade: installed payload sequence is newer than the requested payload."
            Throw-MaterializerError -Message "Payload removal was rejected because an older manifest cannot remove a newer installation." -ExitCode 3
        }
        if ($versionPolicy.IsSequenceCollision) {
            Write-Host "[CONFLICT] SequenceCollision: the installed and requested payloads reuse one sequence with different identities or file hashes."
            Throw-MaterializerError -Message "Payload removal was rejected because the installed payload identity does not match this manifest sequence." -ExitCode 3
        }
        if ($versionPolicy.IsInvalid) {
            Write-Host "[CONFLICT] InvalidIdentity: the installed payload is not current or an exact Package-declared transition."
            Throw-MaterializerError -Message "Payload removal was rejected because the installed payload has no authenticated Package runtime identity." -ExitCode 3
        }
    }

    $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "selected generation pointer"
    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
    $null = Assert-RemovalGenerationPointerUpperBound -Manifest $Manifest -PointerPath $currentPointerPath -PointerLabel "current.json" -ProjectRoot $ProjectRoot
    $null = Assert-RemovalGenerationPointerUpperBound -Manifest $Manifest -PointerPath $lastKnownGoodPath -PointerLabel "last-known-good.json" -ProjectRoot $ProjectRoot
    return $marker
}

function Save-LastKnownGoodPointer {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TransactionRoot
    )

    $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "current generation pointer"
    $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
    if ($null -eq $current) {
        return $null
    }
    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
    Assert-NoReparsePoint -Path $lastKnownGoodPath -Root $ProjectRoot -Label "last-known-good generation pointer"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $lastKnownGoodPath) | Out-Null
    $stagePath = Join-Path $TransactionRoot "last-known-good.pointer"
    Write-DurableUtf8File -Path $stagePath -Content $current.Text
    Publish-TransactionFile -StagePath $stagePath -TargetPath $lastKnownGoodPath
    if (-not [string]::Equals((Get-FileSha256 -Path $lastKnownGoodPath), (Get-FileSha256 -Path $currentPointerPath), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Last-known-good generation pointer publication failed verification."
    }
    Write-Host "[INSTALLING] Retained generation $($current.GenerationId) as last known good."
    return $current
}

function Get-ValidatedPlanRetiredGenerationForCleanup {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)]$LastKnownGood,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $packageIdentity = Get-PackageGenerationIdentityForRuntimeIdentity -Manifest $Manifest -Identity $LastKnownGood
    if ($null -eq $packageIdentity -or
        -not [string]::Equals([string]$packageIdentity.Disposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$LastKnownGood.GenerationId, $GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals(
            [string]$LastKnownGood.GenerationManifestSha256,
            [string]$packageIdentity.GenerationManifestSha256,
            [StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }
    $generationPrefix = "AIWork/.runtime/codedb/host/generations/$GenerationId/"
    $retiredItems = @($Plan.Retired | Where-Object {
        $_.Target.StartsWith($generationPrefix, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($retiredItems.Count -eq 0 -or $retiredItems.Count -ne @($LastKnownGood.ManagedFiles).Count) {
        return $null
    }

    $retiredMap = @{}
    foreach ($item in $retiredItems) {
        $target = Assert-TransactionTargetRelativePath -Path ([string]$item.Target)
        if (-not [string]::Equals([string]$item.Status, "Retirable", [StringComparison]::Ordinal) -or
            [string]$item.PreviousSha256 -notmatch '^[0-9a-fA-F]{64}$' -or
            -not (Test-Path -LiteralPath $item.TargetPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }
        $retiredMap[[System.IO.Path]::GetFullPath([string]$item.TargetPath)] = [string]$item.PreviousSha256
    }
    foreach ($managedFile in @($LastKnownGood.ManagedFiles)) {
        $path = [System.IO.Path]::GetFullPath([string]$managedFile.Path)
        if (-not $retiredMap.ContainsKey($path) -or
            -not [string]::Equals([string]$retiredMap[$path], [string]$managedFile.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            return $null
        }
    }
    return $LastKnownGood
}

function Get-ValidatedLegacyFlatRetirement {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $marker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    if ($null -eq $marker) { return $null }
    $transition = Get-ReviewedBootstrapTransition -Manifest $Manifest -Marker $marker
    if ($null -eq $transition) {
        throw "Legacy flat payload is not a reviewed bootstrap-transition source."
    }

    $wrapperTarget = "$($script:TargetPrefix)wrapper/codedb-project-wrapper.mjs"
    if (-not $Manifest.TargetMap.ContainsKey($wrapperTarget) -or -not $marker.Map.ContainsKey($wrapperTarget)) {
        throw "Legacy flat retirement has no reviewed stable-wrapper identity."
    }
    $expectedWrapperHash = ([string]$Manifest.TargetMap[$wrapperTarget].Sha256).ToLowerInvariant()
    $retiredFiles = New-Object System.Collections.Generic.List[object]
    foreach ($file in @($marker.Files | Sort-Object Target)) {
        if (-not $file.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Legacy flat retirement target escapes the reviewed Host root: $($file.Target)"
        }
        Assert-NoReparsePoint -Path $file.TargetPath -Root $ProjectRoot -Label "legacy flat retirement target"
        if (-not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf)) {
            throw "Legacy flat retirement target is missing: $($file.Target)"
        }
        if ([string]::Equals($file.Target, $wrapperTarget, [StringComparison]::OrdinalIgnoreCase)) {
            if (-not [string]::Equals((Get-FileSha256 -Path $file.TargetPath), $expectedWrapperHash, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Stable instance wrapper no longer matches the Package-owned activation identity."
            }
            continue
        }
        if (-not [string]::Equals((Get-FileSha256 -Path $file.TargetPath), $file.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Legacy flat retirement target drifted after activation: $($file.Target)"
        }
        $retiredFiles.Add($file) | Out-Null
    }
    return [pscustomobject]@{
        Marker = $marker
        MarkerPath = $MarkerPath
        Transition = $transition
        Files = $retiredFiles.ToArray()
        StableWrapperTarget = $wrapperTarget
    }
}

function Invoke-AutomaticGenerationCleanup {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)]$Plan
    )

    # Close the old wrapper lease window before inventory. A v0.2.4 wrapper
    # rejects action=remove, while the selected instance uses disjoint leases.
    Initialize-MaterializerUpgradeGate -Lock $Lock -ProjectRoot $ProjectRoot -MarkerAction "remove"

    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    $flatReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($flatReport.Invalid.Count -gt 0 -or $generationReport.Invalid.Count -gt 0) {
        Write-Warning "Automatic retirement found invalid ownership evidence and will retry without mutating the legacy closure."
        return [pscustomobject]@{ CleanupState = "PENDING"; LiveFlatOwners = @($flatReport.LiveDetails); LiveHistoricalGenerationIds = @() }
    }
    foreach ($lease in $flatReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Add-MaterializerMutationScope -Scope "host_runtime"
        Write-Host "[RECOVERED] Removed proved-stale $($lease.Owner) flat Host-use lease for PID $($lease.ProcessId)."
    }
    foreach ($lease in $generationReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Add-MaterializerMutationScope -Scope "host_runtime"
        Write-Host "[RECOVERED] Removed proved-stale generation $($lease.GenerationId) $($lease.Owner) lease for PID $($lease.ProcessId)."
    }

    $flatReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($flatReport.Invalid.Count -gt 0 -or $generationReport.Invalid.Count -gt 0) {
        Write-Warning "Automatic retirement ownership changed while stale evidence was reclaimed."
        return [pscustomobject]@{ CleanupState = "PENDING"; LiveFlatOwners = @($flatReport.LiveDetails); LiveHistoricalGenerationIds = @() }
    }

    $liveHistoricalIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($owner in $generationReport.LiveDetails) {
        if (-not [string]::Equals([string]$owner.GenerationId, [string]$Manifest.GenerationId, [StringComparison]::Ordinal)) {
            $null = $liveHistoricalIds.Add([string]$owner.GenerationId)
        }
        Write-Host "[RETAINED] generation $($owner.GenerationId) $($owner.Owner) PID $($owner.ProcessId) keeps the legacy Host selection and every historical generation."
    }
    foreach ($owner in $flatReport.LiveDetails) {
        Write-Host "[RETAINED] $($owner.Owner) PID $($owner.ProcessId) keeps the flat Host closure and every historical generation."
    }
    if ($flatReport.Live.Count -gt 0 -or $generationReport.Live.Count -gt 0) {
        Write-Host "[DRAINING] Historical CodeDB execution closures remain active; cleanup will retry automatically after their leases drain."
        return [pscustomobject]@{
            CleanupState = "PENDING"
            LiveFlatOwners = @($flatReport.LiveDetails)
            LiveHistoricalGenerationIds = @($liveHistoricalIds | Sort-Object)
        }
    }

    # Legacy coordinator state without a live lease is unknown retirement
    # evidence. It may delay cleanup, but it never blocks the selected instance.
    $Lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
    Enter-MaterializerWatchManagementLocks -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveLegacyWatcherState `
        -Lock $Lock `
        -ProjectRoot $ProjectRoot `
        -PayloadRoot $Manifest.Root `
        -AllowGenerationOwnedWatcher

    $markerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "legacy retirement marker"
    $installedMarker = Read-InstalledMarker -MarkerPath $markerPath -ProjectRoot $ProjectRoot
    $currentFlatPayload = $false
    if ($null -ne $installedMarker -and $installedMarker.SchemaVersion -eq $script:MarkerSchemaVersion) {
        $currentFlatPayload = (Get-InstalledPayloadVersionPolicy -Manifest $Manifest -Marker $installedMarker).PayloadIdentityMatches
    }
    $legacyRetirement = if ($currentFlatPayload) {
        $null
    } else {
        Get-ValidatedLegacyFlatRetirement -Manifest $Manifest -ProjectRoot $ProjectRoot -MarkerPath $markerPath
    }
    if ($null -eq $legacyRetirement -and -not $currentFlatPayload) {
        $legacyResidue = @($Manifest.Files | Where-Object {
            $_.Target.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase) -and
            -not [string]::Equals($_.Target, "$($script:TargetPrefix)wrapper/codedb-project-wrapper.mjs", [StringComparison]::OrdinalIgnoreCase) -and
            (Test-Path -LiteralPath (ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $_.Target -Label "legacy flat residue"))
        } | Select-Object -First 1)
        if ($legacyResidue.Count -gt 0) {
            throw "Legacy flat files remain without a reviewed retirement marker: $($legacyResidue[0].Target)"
        }
    }

    $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "automatic cleanup current generation pointer"
    $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
    if ($null -eq $current) { throw "Automatic retirement cannot validate host/current.json." }
    $currentDisposition = Get-RuntimeIdentityDisposition -Manifest $Manifest -Identity $current
    $currentIsPackageGeneration = [string]::Equals($currentDisposition, "CURRENT", [StringComparison]::Ordinal)
    if ($currentIsPackageGeneration) {
        Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $current.GenerationRoot -ProjectRoot $ProjectRoot -SkipSyntaxValidation
    } else {
        $reviewedTransition = Get-RuntimeTransitionForIdentity -Manifest $Manifest -Identity $current
        if ($null -eq $reviewedTransition -or
            -not [string]::Equals($currentDisposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal)) {
            throw "Legacy host/current.json does not match the reviewed bootstrap-transition identity."
        }
        if ($null -eq $legacyRetirement) {
            $packageOwnedPrevious = Get-ValidatedPackageOwnedInstalledGeneration `
                -GenerationId $current.GenerationId `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $Manifest.Root
            if ($null -eq $packageOwnedPrevious -or
                -not [string]::Equals([string]$packageOwnedPrevious.PackageVersion, [string]$current.PackageVersion, [StringComparison]::Ordinal) -or
                -not [string]::Equals([string]$packageOwnedPrevious.PayloadVersion, [string]$current.PayloadVersion, [StringComparison]::Ordinal) -or
                $packageOwnedPrevious.PayloadSequence -ne $current.PayloadSequence -or
                $packageOwnedPrevious.BootstrapProtocol -ne $current.BootstrapProtocol -or
                -not [string]::Equals([string]$packageOwnedPrevious.GenerationManifestSha256, [string]$current.GenerationManifestSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Previous-instance host/current.json does not match the Package-preserved immutable generation."
            }
        }
    }

    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "automatic cleanup last-known-good pointer"
    $lastKnownGood = $null
    if (Test-Path -LiteralPath $lastKnownGoodPath) {
        if (-not (Test-Path -LiteralPath $lastKnownGoodPath -PathType Leaf)) { throw "Automatic retirement last-known-good pointer is not a regular file." }
        $lastKnownGood = Get-ValidatedInstalledGenerationPointer -PointerPath $lastKnownGoodPath -ProjectRoot $ProjectRoot
        if ($null -eq $lastKnownGood) { throw "Automatic retirement cannot validate last-known-good.json." }
    }

    $generationsRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host/generations" -Label "installed generations root"
    $validatedHistorical = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    if (Test-Path -LiteralPath $generationsRoot) {
        if (-not (Test-Path -LiteralPath $generationsRoot -PathType Container)) { throw "Installed generations root is not a directory." }
        Assert-NoReparsePoint -Path $generationsRoot -Root $ProjectRoot -Label "installed generations root"
        foreach ($directory in @(Get-ChildItem -LiteralPath $generationsRoot -Force)) {
            if (-not $directory.PSIsContainer -or $directory.Name -notmatch '^[A-Za-z0-9._-]{1,64}$') { throw "Automatic retirement found an unknown generation entry: $($directory.FullName)" }
            Assert-NoReparsePoint -Path $directory.FullName -Root $generationsRoot -Label "installed generation"
            if ([string]::Equals($directory.Name, [string]$Manifest.GenerationId, [StringComparison]::Ordinal)) { continue }
            $historicalPrefix = "AIWork/.runtime/codedb/host/generations/$($directory.Name)/"
            $reviewed = @($Manifest.RetiredTargets | Where-Object { $_.StartsWith($historicalPrefix, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
            if (-not $reviewed) {
                Write-Host "[PRESERVED] Unowned generation-like directory is outside the Package cleanup allowlist: $($directory.FullName)"
                continue
            }
            $validatedGeneration = Get-ValidatedPackageOwnedInstalledGeneration -GenerationId $directory.Name -ProjectRoot $ProjectRoot -PayloadRoot $Manifest.Root
            if ($null -ne $validatedGeneration) {
                $packageIdentity = Get-PackageGenerationIdentityForRuntimeIdentity -Manifest $Manifest -Identity $validatedGeneration
                if ($null -eq $packageIdentity -or
                    -not [string]::Equals([string]$packageIdentity.Disposition, "TRUSTED_PREVIOUS", [StringComparison]::Ordinal) -or
                    -not [string]::Equals(
                        [string]$validatedGeneration.GenerationManifestSha256,
                        [string]$packageIdentity.GenerationManifestSha256,
                        [StringComparison]::OrdinalIgnoreCase)) {
                    Write-Host "[PRESERVED] Package generation $($directory.Name) is not an exact declared transition and is outside automatic retirement."
                    continue
                }
            }
            if ($null -eq $validatedGeneration -and $null -ne $lastKnownGood) {
                $validatedGeneration = Get-ValidatedPlanRetiredGenerationForCleanup -Manifest $Manifest -GenerationId $directory.Name -Plan $Plan -LastKnownGood $lastKnownGood -ProjectRoot $ProjectRoot
            }
            if ($null -eq $validatedGeneration) { throw "Automatic retirement cannot prove Package ownership for historical generation $($directory.Name)." }
            $validatedHistorical.Add($directory.Name, $validatedGeneration)
        }
    }

    if (-not $Manifest.TargetMap.ContainsKey($script:CurrentPointerRelativePath)) { throw "Package payload has no current generation pointer identity." }
    $packagePointerSource = [string]$Manifest.TargetMap[$script:CurrentPointerRelativePath].SourcePath
    $packagePointerText = [System.IO.File]::ReadAllText($packagePointerSource, [System.Text.UTF8Encoding]::new($false, $true))
    $packagePointerHash = Get-FileSha256 -Path $packagePointerSource

    $transactionRoot = $null
    $entries = $null
    $keepTransaction = $false
    $removedGenerationPaths = New-Object System.Collections.Generic.List[string]
    $removedFlatPaths = New-Object System.Collections.Generic.List[string]
    try {
        $transactionRoot = Join-Path $Lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $stageRoot = Join-Path $transactionRoot "stage"
        $backupRoot = Join-Path $transactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $stageRoot, $backupRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]

        if (-not (Test-Path -LiteralPath $lastKnownGoodPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $lastKnownGoodPath), $packagePointerHash, [StringComparison]::OrdinalIgnoreCase)) {
            $lastKnownGoodStagePath = Join-Path $stageRoot "last-known-good-generation.pointer"
            Write-DurableUtf8File -Path $lastKnownGoodStagePath -Content $packagePointerText
            $entries.Add((New-TransactionEntry -Target $script:LastKnownGoodPointerRelativePath -TargetPath $lastKnownGoodPath -Mutation "Write" -DesiredSha256 $packagePointerHash -StagePath $lastKnownGoodStagePath -BackupRoot $backupRoot -Index $entries.Count)) | Out-Null
        }
        if (-not $currentIsPackageGeneration -or
            -not [string]::Equals((Get-FileSha256 -Path $currentPointerPath), $packagePointerHash, [StringComparison]::OrdinalIgnoreCase)) {
            $currentStagePath = Join-Path $stageRoot "current-generation.pointer"
            Write-DurableUtf8File -Path $currentStagePath -Content $packagePointerText
            $entries.Add((New-TransactionEntry -Target $script:CurrentPointerRelativePath -TargetPath $currentPointerPath -Mutation "Write" -DesiredSha256 $packagePointerHash -StagePath $currentStagePath -BackupRoot $backupRoot -Index $entries.Count)) | Out-Null
        }

        foreach ($generationId in @($validatedHistorical.Keys | Sort-Object)) {
            foreach ($managedFile in @($validatedHistorical[$generationId].ManagedFiles | Sort-Object Path)) {
                $targetPath = [System.IO.Path]::GetFullPath([string]$managedFile.Path)
                $relativePath = $targetPath.Substring([System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/').Length + 1).Replace('\', '/')
                $relativePath = Assert-TransactionTargetRelativePath -Path $relativePath
                $entries.Add((New-TransactionEntry -Target $relativePath -TargetPath $targetPath -Mutation "Delete" -BackupRoot $backupRoot -Index $entries.Count)) | Out-Null
                $removedGenerationPaths.Add($targetPath) | Out-Null
            }
        }
        if ($null -ne $legacyRetirement) {
            foreach ($file in @($legacyRetirement.Files | Sort-Object Target)) {
                $entries.Add((New-TransactionEntry -Target $file.Target -TargetPath $file.TargetPath -Mutation "Delete" -BackupRoot $backupRoot -Index $entries.Count)) | Out-Null
                $removedFlatPaths.Add([string]$file.TargetPath) | Out-Null
            }
            $entries.Add((New-TransactionEntry -Target $script:MarkerRelativePath -TargetPath $legacyRetirement.MarkerPath -Mutation "Delete" -BackupRoot $backupRoot -Index $entries.Count)) | Out-Null
            $removedFlatPaths.Add([string]$legacyRetirement.MarkerPath) | Out-Null
        }

        if ($entries.Count -gt 0) {
            $finalFlatReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
            $finalGenerationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
            if ($finalFlatReport.Invalid.Count -gt 0 -or $finalGenerationReport.Invalid.Count -gt 0 -or
                $finalFlatReport.Live.Count -gt 0 -or $finalGenerationReport.Live.Count -gt 0) {
                throw "Automatic retirement ownership changed before transaction publication."
            }
            Assert-NoLiveLegacyWatcherState -Lock $Lock -ProjectRoot $ProjectRoot -PayloadRoot $Manifest.Root -AllowGenerationOwnedWatcher
            Write-TransactionJournal -Operation "Remove" -TransactionRoot $transactionRoot -Entries $entries.ToArray() -Manifest $Manifest
            foreach ($entry in $entries) {
                $entryFlatReport = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
                $entryGenerationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
                if ($entryFlatReport.Invalid.Count -gt 0 -or $entryGenerationReport.Invalid.Count -gt 0 -or
                    $entryFlatReport.Live.Count -gt 0 -or $entryGenerationReport.Live.Count -gt 0) {
                    throw "Automatic retirement ownership changed before mutating $($entry.Target)."
                }
                Assert-TransactionEntryBeforeMutation -Entry $entry
                if ([string]::Equals([string]$entry.Mutation, "Write", [StringComparison]::Ordinal)) {
                    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
                    Publish-TransactionFile -StagePath $entry.StagePath -TargetPath $entry.TargetPath
                    if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), [string]$entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) { throw "Automatic retirement pointer publication failed: $($entry.Target)" }
                } else {
                    Remove-Item -LiteralPath $entry.TargetPath -Force
                    if (Test-Path -LiteralPath $entry.TargetPath) { throw "Automatic retirement target remained after deletion: $($entry.Target)" }
                }
                Add-MaterializerMutationScope -Scope "host_runtime"
                Invoke-TestFaultAfterMutation
            }
        }

        if ($removedGenerationPaths.Count -gt 0) {
            $hostRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host" -Label "host generation runtime"
            Remove-EmptyManagedParents -Paths $removedGenerationPaths.ToArray() -TargetRoot $hostRuntimeRoot
        }
        if ($removedFlatPaths.Count -gt 0) {
            $flatRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:TargetPrefix.TrimEnd('/') -Label "legacy flat Host root"
            Remove-EmptyManagedParents -Paths $removedFlatPaths.ToArray() -TargetRoot $flatRoot
        }
    } catch {
        $originalError = $_.Exception
        $rollbackErrors = @()
        if ($null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $targetRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork" -Label "automatic retirement target root"
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $targetRoot -ProjectRoot $ProjectRoot)
        }
        if ($rollbackErrors.Count -gt 0) {
            $keepTransaction = $true
            Throw-MaterializerError -Message "Automatic retirement failed and rollback was incomplete. $($rollbackErrors -join '; ') Transaction: $transactionRoot" -ExitCode 7
        }
        throw $originalError
    } finally {
        if ($null -ne $transactionRoot -and -not $keepTransaction -and (Test-Path -LiteralPath $transactionRoot)) {
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    if ($currentFlatPayload) {
        Write-Host "[CLEANUP] Retired immutable generation closures are reclaimed; the current diagnostic flat payload remains installed."
    } else {
        Write-Host "[CLEANUP] Retired flat and immutable generation closures are reclaimed; host/current now selects the Package generation."
    }
    return [pscustomobject]@{ CleanupState = "COMPLETE"; LiveFlatOwners = @(); LiveHistoricalGenerationIds = @() }
}

function Resolve-RollbackWatcherManager {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$RecordedWatchManagerPath,
        [Parameter(Mandatory = $true)][string]$RecordedWatchManagerSha256
    )

    $recordedPath = [System.IO.Path]::GetFullPath($RecordedWatchManagerPath)
    Assert-PathInside -Path $recordedPath -Root $ProjectRoot -Label "rollback watcher manager"
    Assert-NoReparsePoint -Path $recordedPath -Root $ProjectRoot -Label "rollback watcher manager"
    if ($RecordedWatchManagerSha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        -not (Test-Path -LiteralPath $recordedPath -PathType Leaf) -or
        -not [string]::Equals((Get-FileSha256 -Path $recordedPath), $RecordedWatchManagerSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Rollback watcher manager no longer matches its transaction identity."
    }
    $normalizedPath = $recordedPath.Replace('\', '/')
    $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "rollback current pointer"
    $isGenerationManager = $normalizedPath.IndexOf('/AIWork/.runtime/codedb/host/generations/', [StringComparison]::OrdinalIgnoreCase) -ge 0
    if (-not $isGenerationManager) {
        $expectedLegacyPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1" -Label "legacy rollback watcher manager"
        if (-not [string]::Equals($recordedPath, $expectedLegacyPath, [StringComparison]::OrdinalIgnoreCase) -or
            (Test-Path -LiteralPath $currentPointerPath)) {
            throw "Legacy rollback selection does not match the restored flat host layout."
        }
        $markerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "restored payload marker"
        $marker = Read-InstalledMarker -MarkerPath $markerPath -ProjectRoot $ProjectRoot
        $managerTarget = "AIWork/codedb/scripts/manage-codedb-project-watch.ps1"
        if ($null -eq $marker -or -not $marker.Map.ContainsKey($managerTarget) -or
            -not [string]::Equals($marker.Map[$managerTarget].InstalledSha256, $RecordedWatchManagerSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Restored legacy marker does not own the recorded rollback watcher manager."
        }
        return $expectedLegacyPath
    }

    $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
    if ($null -eq $current -or
        -not [string]::Equals([System.IO.Path]::GetFullPath($current.WatchManagerPath), $recordedPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Restored current.json does not select the recorded rollback watcher generation."
    }
    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
    $lastKnownGood = Get-ValidatedInstalledGenerationPointer -PointerPath $lastKnownGoodPath -ProjectRoot $ProjectRoot
    if ($null -eq $lastKnownGood -or
        -not [string]::Equals([System.IO.Path]::GetFullPath($lastKnownGood.WatchManagerPath), $recordedPath, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-FileSha256 -Path $lastKnownGoodPath), (Get-FileSha256 -Path $currentPointerPath), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Last-known-good pointer does not match the restored current generation."
    }
    return $recordedPath
}

function Get-LegacyWatchManagerPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1" -Label "legacy watch manager"
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Assert-NoReparsePoint -Path $path -Root $ProjectRoot -Label "legacy watch manager"
        return $path
    }
    return $null
}

function Invoke-UpgradeWatcherEnsure {
    param(
        [AllowNull()][string]$WatchManagerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$WithoutMaterializerHandoff
    )

    if ($PocFixture) {
        if ($TestFailWatcherHandoff) {
            throw "Injected POC watcher readiness failure."
        }
        return
    }
    if ([string]::IsNullOrWhiteSpace($WatchManagerPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $WatchManagerPath -PathType Leaf)) {
        throw "$Label watch manager is missing: $WatchManagerPath"
    }
    Write-Host "[SWITCHING] Reconciling $Label watcher ownership."
    $previousUnityRoot = $env:RICE_CODEDB_UNITY_ROOT
    Push-Location -LiteralPath $ProjectRoot
    try {
        $env:RICE_CODEDB_UNITY_ROOT = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        if ($WithoutMaterializerHandoff) {
            & $WatchManagerPath -Action Ensure
        } else {
            & $WatchManagerPath -Action Ensure -MaterializerHandoff
        }
    } finally {
        if ($null -eq $previousUnityRoot) {
            Remove-Item Env:RICE_CODEDB_UNITY_ROOT -ErrorAction SilentlyContinue
        } else {
            $env:RICE_CODEDB_UNITY_ROOT = $previousUnityRoot
        }
        Pop-Location
    }
}

function Invoke-Sync {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [switch]$AutomaticUpgrade,
        [switch]$OwnedLegacyRedeploy
    )

    if ($AutomaticUpgrade -and $OwnedLegacyRedeploy) {
        throw "AutomaticUpgrade and OwnedLegacyRedeploy are mutually exclusive."
    }
    Set-MaterializerCommandPhase -Phase "PREFLIGHT"

    $lock = $null
    $transactionRoot = $null
    $keepTransaction = $false
    $entries = $null
    $previousWatcherManager = $null
    $previousWatcherManagerSha256 = $null
    $watcherHandoffAttempted = $false
    $upgradeMutationStarted = $false
    $automaticHostCommitted = $false
    $automaticMcpPlan = $null
    $legacyWatcherStopped = $false
    $automaticCleanupState = "COMPLETE"

    if ($AutomaticUpgrade) {
        # Stable invalid or ambiguous TOML must block before any automatic Host
        # or materializer-control mutation.
        $automaticMcpPlan = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
        $runtimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
        $hasPendingTransaction = $false
        if (Test-Path -LiteralPath $runtimeRoot) {
            if (-not (Test-Path -LiteralPath $runtimeRoot -PathType Container)) {
                throw "Materializer recovery runtime is not a directory: $runtimeRoot"
            }
            Assert-NoReparsePoint -Path $runtimeRoot -Root $ProjectRoot -Label "materializer recovery runtime"
            $hasPendingTransaction = @(Get-ChildItem -LiteralPath $runtimeRoot -Force -Directory | Where-Object {
                $_.Name -match '^txn-v1-[0-9a-f]{12}$'
            }).Count -gt 0
        }

        # A stable ownership conflict must be rejected before the lock, active
        # marker, or upgrade diagnostics can write. A controlled pending journal
        # still enters the locked path so the existing recovery flow can run.
        if (-not $hasPendingTransaction) {
            $preLockPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
            if ($preLockPlan.HasConflict) {
                Write-MaterializationPlan -Plan $preLockPlan
                Throw-MaterializerError -Message "Payload sync was rejected because one or more targets conflict." -ExitCode 3
            }
            if ($null -eq $preLockPlan.Marker -and
                -not (Test-SafeFirstAdoptionPlan -Plan $preLockPlan -ProjectRoot $ProjectRoot)) {
                Throw-MaterializerError -Message "Automatic host upgrade was rejected: first adoption requires an empty CodeDB-managed target scope." -ExitCode 4
            }
        }
    }

    try {
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot
        Set-MaterializerCommandPhase -Phase "HOST_RUNTIME"
        if ($AutomaticUpgrade) {
            Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot
            $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        } else {
            if ($OwnedLegacyRedeploy) {
                # A confirmed watcher Stop must remain the first persistent
                # effect. Any interrupted transaction is repaired separately.
                if ($lock.LockFileExistedBefore) {
                    $lock.PreserveLockFile = $true
                }
                Assert-NoPendingMaterializerTransactions -Lock $lock -ProjectRoot $ProjectRoot -ActionLabel "Owned legacy redeploy"
                $lock.PreserveLockFile = $false
                $preGatePlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
                $preGateEligibility = Get-OwnedLegacyRedeployEligibility -Manifest $Manifest -Plan $preGatePlan
                if (-not $preGateEligibility.Eligible) {
                    Throw-MaterializerError -Message "Owned legacy host redeploy was rejected: $($preGateEligibility.Reason)." -ExitCode 4
                }
                $null = Complete-OwnedLegacyRedeployHostUseGate `
                    -Lock $lock `
                    -ProjectRoot $ProjectRoot `
                    -MarkerPath $MarkerPath `
                    -WatcherStopped ([ref]$legacyWatcherStopped)
                Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerAction "sync"
            } else {
                Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot
                $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -AutomaticOnly
                Complete-MaterializerHostUseGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
                $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -SkipAutomaticUpgrade
            }
        }
        $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if ($AutomaticUpgrade) {
            $automaticMcpPlan = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
        }
        Write-MaterializationPlan -Plan $plan
        if ($plan.HasConflict) {
            Throw-MaterializerError -Message "Payload sync was rejected because one or more targets conflict." -ExitCode 3
        }
        if ($plan.IsCurrent) {
            Write-Host "[OK] Host payload is already current; no files were written."
            if ($AutomaticUpgrade) {
                $automaticHostCommitted = $true
                Set-MaterializerCommandPhase -Phase "MCP_AVAILABLE"
                Complete-AutomaticMcpConvergence `
                    -Manifest $Manifest `
                    -ProjectRoot $ProjectRoot `
                    -Lock $lock `
                    -McpPlan $automaticMcpPlan
                $cleanup = Invoke-AutomaticGenerationCleanup `
                    -Manifest $Manifest `
                    -ProjectRoot $ProjectRoot `
                    -Lock $lock `
                    -Plan $plan
                $automaticCleanupState = [string]$cleanup.CleanupState
                $null = Ensure-MaterializerUpgradeStateCurrent `
                    -Lock $lock `
                    -ProjectRoot $ProjectRoot `
                    -Message "Generation $($Manifest.GenerationId), project registration, and Package-owned MCP handshake are current." `
                    -CleanupState $automaticCleanupState
                $currentPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
                Write-ProductLayerStatus `
                    -Manifest $Manifest `
                    -ProjectRoot $ProjectRoot `
                    -Plan $currentPlan `
                    -CleanupState $automaticCleanupState
                Write-Host "[CLEANUP_STATE] $automaticCleanupState"
            }
            Set-MaterializerCommandOutcome `
                -Outcome "CONVERGED" `
                -ReasonCode "ACTION_COMPLETE" `
                -CleanupState $(if ($AutomaticUpgrade) { $automaticCleanupState } else { "COMPLETE" }) `
                -NextAction $(if ($AutomaticUpgrade -and $automaticCleanupState -eq "PENDING") { "No action required; CodeDB will reclaim retired closures after their leases drain." } else { "No action required." })
            Set-MaterializerCommandPhase -Phase "COMPLETE"
            return
        }
        if ($OwnedLegacyRedeploy) {
            $redeployEligibility = Get-OwnedLegacyRedeployEligibility -Manifest $Manifest -Plan $plan
            if (-not $redeployEligibility.Eligible) {
                Throw-MaterializerError -Message "Owned legacy host redeploy was rejected: $($redeployEligibility.Reason)." -ExitCode 4
            }
            Write-Host "[REDEPLOYING] Replacing byte-exact $($plan.Marker.PayloadVersion) host files and publishing generation $($Manifest.GenerationId)."
        }
        if ($AutomaticUpgrade) {
            $eligibility = Get-AutomaticUpgradeEligibility -Manifest $Manifest -Plan $plan -ProjectRoot $ProjectRoot
            if (-not $eligibility.Eligible) {
                Throw-MaterializerError -Message "Automatic host upgrade was rejected: $($eligibility.Reason)." -ExitCode 4
            }
            Write-Host "[INSTALLING] Installing immutable generation $($Manifest.GenerationId)."
            Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "INSTALLING" -Message "Validating and publishing immutable generation $($Manifest.GenerationId)."
            $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "current generation pointer"
            $previousGeneration = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
            $previousWatcherManager = if ($null -ne $previousGeneration) {
                $previousGeneration.WatchManagerPath
            } else {
                Get-LegacyWatchManagerPath -ProjectRoot $ProjectRoot
            }
            $previousWatcherManagerSha256 = if ([string]::IsNullOrWhiteSpace($previousWatcherManager)) {
                $null
            } else {
                Get-FileSha256 -Path $previousWatcherManager
            }
        }

        $transactionRoot = Join-Path $lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $stageRoot = Join-Path $transactionRoot "stage"
        $backupRoot = Join-Path $transactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $stageRoot, $backupRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]

        if ($AutomaticUpgrade) {
            $upgradeMutationStarted = $true
            $null = Publish-ImmutableGeneration -Manifest $Manifest -ProjectRoot $ProjectRoot -TransactionRoot $transactionRoot
            $null = Save-LastKnownGoodPointer -ProjectRoot $ProjectRoot -TransactionRoot $transactionRoot
            Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "SWITCHING" -Message "Publishing current.json and reconciling watcher ownership."
        }

        $orderedFiles = @($plan.Files | Sort-Object `
            @{ Expression = {
                if ($AutomaticUpgrade -and [string]::Equals($_.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) { 0 }
                elseif ($AutomaticUpgrade -and [string]::Equals($_.Target, "AIWork/codedb/wrapper/codedb-project-wrapper.mjs", [StringComparison]::OrdinalIgnoreCase)) { 1 }
                elseif ([string]::Equals($_.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) { 3 }
                else { 2 }
            } }, `
            Target)
        foreach ($item in $orderedFiles) {
            if ($AutomaticUpgrade -and $item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            $needsFileWrite = $item.Status -eq "Missing" -or
                ($item.Status -eq "Upgradeable" -and
                    -not [string]::Equals([string]$item.TargetSha256, $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase))
            if (-not $needsFileWrite) {
                continue
            }

            $stagePath = Join-Path $stageRoot (([guid]::NewGuid().ToString("N")) + ".payload")
            Copy-Item -LiteralPath $item.SourcePath -Destination $stagePath -Force
            if (-not [string]::Equals((Get-FileSha256 -Path $stagePath), $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Staged payload hash mismatch: $($item.Target)"
            }

            if (Test-Path -LiteralPath $item.TargetPath -PathType Leaf) {
                if (-not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), [string]$item.TargetSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Payload target changed during sync: $($item.Target)"
                }
            }
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Write" `
                -DesiredSha256 $item.SourceSha256 `
                -StagePath $stagePath `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }

        foreach ($item in $plan.Retired) {
            if ($AutomaticUpgrade -and $item.Target -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/') {
                Write-Host "[DRAINING] Retaining retired immutable generation content until lease and rollback retention permit cleanup: $($item.Target)"
                continue
            }
            if (-not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), $item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Retired payload target changed during sync: $($item.Target)"
            }
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Delete" `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }

        $markerStagePath = Join-Path $stageRoot ".rice-ai-codedb-payload.json"
        [System.IO.File]::WriteAllText($markerStagePath, (New-MarkerJson -Manifest $Manifest), [System.Text.UTF8Encoding]::new($false))
        $markerSha256 = Get-FileSha256 -Path $markerStagePath
        $entries.Add((New-TransactionEntry `
            -Target $script:MarkerRelativePath `
            -TargetPath $MarkerPath `
            -Mutation "Write" `
            -DesiredSha256 $markerSha256 `
            -StagePath $markerStagePath `
            -BackupRoot $backupRoot `
            -Index $entries.Count)) | Out-Null

        # The durable journal is the recovery commit point; target mutations start after it.
        Write-TransactionJournal `
            -Operation "Sync" `
            -TransactionRoot $transactionRoot `
            -Entries $entries.ToArray() `
            -Manifest $Manifest `
            -AutomaticUpgrade:$AutomaticUpgrade `
            -PreviousWatcherManagerPath $previousWatcherManager `
            -ProjectRoot $ProjectRoot
        foreach ($entry in $entries) {
            Assert-TransactionEntryBeforeMutation -Entry $entry
            if ($entry.Mutation -eq "Write") {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
                Publish-TransactionFile -StagePath $entry.StagePath -TargetPath $entry.TargetPath
                if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), $entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Published payload hash mismatch: $($entry.Target)"
                }
            } else {
                Remove-Item -LiteralPath $entry.TargetPath -Force
                if (Test-Path -LiteralPath $entry.TargetPath) {
                    throw "Retired payload target remained after deletion: $($entry.Target)"
                }
            }
            Add-MaterializerMutationScope -Scope "host_runtime"
            Invoke-TestFaultAfterMutation
        }

        $postPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if (-not $postPlan.IsCurrent) {
            throw "Post-sync verification did not reach the current state."
        }
        if ($AutomaticUpgrade -and $TestCrashBeforeWatcherHandoff) {
            Write-Host "Injected POC process crash after post-plan current and before watcher handoff."
            [Environment]::Exit(86)
        }
        $removedRetiredPaths = @($plan.Retired | Where-Object {
            -not ($AutomaticUpgrade -and $_.Target -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/')
        } | ForEach-Object { $_.TargetPath })
        if ($removedRetiredPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $removedRetiredPaths -TargetRoot $TargetRoot
        }
        if ($AutomaticUpgrade) {
            Write-Host "[SWITCHING] Published current generation pointer for $($Manifest.GenerationId)."
            $newWatcherManager = Join-Path `
                (ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') -Label "selected generation") `
                "scripts\manage-codedb-project-watch.ps1"
            $watcherHandoffAttempted = $true
            Invoke-UpgradeWatcherEnsure -WatchManagerPath $newWatcherManager -ProjectRoot $ProjectRoot -Label "selected generation"
            if (Test-Path -LiteralPath $transactionRoot) {
                Remove-Item -LiteralPath $transactionRoot -Recurse -Force
            }
            $transactionRoot = $null
            $entries = $null
            $automaticHostCommitted = $true
            Set-MaterializerCommandPhase -Phase "MCP_AVAILABLE"
            Complete-AutomaticMcpConvergence `
                -Manifest $Manifest `
                -ProjectRoot $ProjectRoot `
                -Lock $lock `
                -McpPlan $automaticMcpPlan `
                -WatcherAlreadyEnsured
            $cleanup = Invoke-AutomaticGenerationCleanup `
                -Manifest $Manifest `
                -ProjectRoot $ProjectRoot `
                -Lock $lock `
                -Plan $plan
            $automaticCleanupState = [string]$cleanup.CleanupState
            Publish-MaterializerUpgradeState `
                -Lock $lock `
                -ProjectRoot $ProjectRoot `
                -State "CURRENT" `
                -Message "Generation $($Manifest.GenerationId), project registration, and Package-owned MCP handshake are current." `
                -CleanupState $automaticCleanupState
            $currentPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
            Write-ProductLayerStatus `
                -Manifest $Manifest `
                -ProjectRoot $ProjectRoot `
                -Plan $currentPlan `
                -CleanupState $automaticCleanupState
            Write-Host "[CLEANUP_STATE] $automaticCleanupState"
            Write-Host "[OK] Host payload automatically upgraded to version $($Manifest.PayloadVersion)."
        } elseif ($OwnedLegacyRedeploy) {
            Write-Host "[OK] Host payload redeployed to version $($Manifest.PayloadVersion)."
        } else {
            Write-Host "[OK] Host payload synchronized to version $($Manifest.PayloadVersion)."
        }
        Set-MaterializerCommandOutcome `
            -Outcome "CONVERGED" `
            -ReasonCode "ACTION_COMPLETE" `
            -CleanupState $(if ($AutomaticUpgrade) { $automaticCleanupState } else { "COMPLETE" }) `
            -NextAction $(if ($AutomaticUpgrade -and $automaticCleanupState -eq "PENDING") { "No action required; CodeDB will reclaim retired closures after their leases drain." } else { "No action required." })
        Set-MaterializerCommandPhase -Phase "COMPLETE"
    } catch {
        $originalError = $_.Exception
        if ($AutomaticUpgrade -and $automaticHostCommitted) {
            Set-MaterializerCommandOutcome `
                -Outcome "PARTIALLY_REPAIRED" `
                -ReasonCode "MCP_AVAILABILITY_INCOMPLETE" `
                -CleanupState "PENDING" `
                -NextAction "CodeDB will retry availability automatically; use Fix CodeDB only if Needs attention remains."
        } else {
            Set-MaterializerCommandOutcome `
                -Outcome "BLOCKED" `
                -ReasonCode "CONVERGENCE_BLOCKED" `
                -CleanupState $(if ($legacyWatcherStopped) { "PENDING" } else { "COMPLETE" }) `
                -NextAction $(if ($legacyWatcherStopped) { "Use Fix CodeDB once to restart the authenticated watcher and finish Host recovery." } else { "Review the reported convergence boundary, then retry once." })
        }
        if ($AutomaticUpgrade -and $null -ne $lock -and $upgradeMutationStarted -and -not $automaticHostCommitted) {
            try {
                Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "ROLLBACK" -Message $originalError.Message
                Write-Host "[ROLLBACK] Restoring the last known-good host selection."
            } catch {
                Write-Warning "Could not publish CodeDB rollback state: $($_.Exception.Message)"
            }
        }
        $rollbackErrors = @()
        if (-not $automaticHostCommitted -and $null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
        }
        if ($AutomaticUpgrade -and -not $automaticHostCommitted -and $watcherHandoffAttempted -and $rollbackErrors.Count -eq 0 -and
            -not [string]::IsNullOrWhiteSpace($previousWatcherManager)) {
            try {
                $null = Resolve-RollbackWatcherManager `
                    -ProjectRoot $ProjectRoot `
                    -RecordedWatchManagerPath $previousWatcherManager `
                    -RecordedWatchManagerSha256 $previousWatcherManagerSha256
                Write-Host "[ROLLBACK] Restored and validated the previous Host selection without executing its watcher manager."
            } catch {
                $rollbackErrors += "validate restored watcher selection: $($_.Exception.Message)"
            }
        }
        if ($rollbackErrors.Count -gt 0) {
            if ($AutomaticUpgrade -and $null -ne $lock) {
                try {
                    Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "CHECK_FAILED" -Message ($rollbackErrors -join '; ')
                } catch {
                    Write-Warning "Could not publish CodeDB failed upgrade state: $($_.Exception.Message)"
                }
            }
            $keepTransaction = $true
            if ($OwnedLegacyRedeploy -and $legacyWatcherStopped) {
                Write-Host "[PHASE HOST_RUNTIME] BLOCKED - Host rollback was incomplete after the authenticated legacy watcher stopped."
                Write-Host "[RESULT] PARTIALLY_REPAIRED"
                Write-Host "[NEXT] Review the retained materializer transaction before retrying any CodeDB action."
            }
            Throw-MaterializerError -Message "Payload sync failed and rollback was incomplete. $($rollbackErrors -join '; ') Transaction: $transactionRoot" -ExitCode 7
        }
        if ($AutomaticUpgrade -and $null -ne $lock) {
            try {
                Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "CHECK_FAILED" -Message "$($originalError.Message) Historical watcher execution was not attempted; retry with Package-owned Repair."
            } catch {
                Write-Warning "Could not publish CodeDB failed upgrade state: $($_.Exception.Message)"
            }
        }
        if ($OwnedLegacyRedeploy -and $legacyWatcherStopped) {
            Write-Host "[PHASE HOST_RUNTIME] PARTIAL - Host payload changes were rolled back, but the authenticated legacy watcher Stop cannot be rolled back."
            Write-Host "[RESULT] PARTIALLY_REPAIRED"
            Write-Host "[NEXT] Click Repair CodeDB once to finish Host recovery; the stopped watcher will not restart automatically."
            if ($script:RequestedExitCode -ne 0) {
                throw $originalError
            }
            Throw-MaterializerError -Message "Payload redeploy failed after the authenticated legacy watcher stopped; Host payload changes were rolled back. $($originalError.Message)" -ExitCode 6
        }
        if ($AutomaticUpgrade -and $automaticHostCommitted) {
            Write-Host "[PRODUCT_STATE] NEEDS_ATTENTION"
            Throw-MaterializerError -Message "Automatic convergence installed the current Host but did not reach MCP_AVAILABLE. $($originalError.Message)" -ExitCode 8
        }
        if ($script:RequestedExitCode -ne 0) {
            throw $originalError
        }
        Throw-MaterializerError -Message "Payload sync failed and was rolled back. $($originalError.Message)" -ExitCode 6
    } finally {
        if ($null -ne $transactionRoot -and -not $keepTransaction -and (Test-Path -LiteralPath $transactionRoot)) {
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        Exit-MaterializerLock -Lock $lock
    }
}

function Get-UninstallCleanupState {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    foreach ($relativePath in @($script:MarkerRelativePath, $script:LastKnownGoodPointerRelativePath)) {
        $path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $relativePath -Label "uninstall cleanup target"
        if (Test-Path -LiteralPath $path) { return "PENDING" }
    }
    foreach ($file in $Manifest.Files) {
        if (Test-Path -LiteralPath $file.TargetPath) { return "PENDING" }
    }
    foreach ($relativePath in $Manifest.RetiredTargets) {
        $path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $relativePath -Label "retired uninstall cleanup target"
        if (Test-Path -LiteralPath $path) { return "PENDING" }
    }
    return "COMPLETE"
}

function Invoke-Uninstall {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [switch]$AutomaticCleanup
    )

    $lock = $null
    $desiredStateCommitted = $false
    $retainedFlatMcps = @()
    $retainedGenerationMcps = @()
    $watcherCleanupPending = $false
    $cleanupState = "PENDING"
    $stateId = $null
    Set-MaterializerCommandPhase -Phase "PREFLIGHT"
    try {
        # Invalid TOML and invalid desired-state evidence remain zero-write failures.
        $integrationState = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
        if ($AutomaticCleanup -and -not $integrationState.Uninstalled) {
            Throw-MaterializerError -Message "Automatic uninstall cleanup requires a valid UNINSTALLED project integration state." -ExitCode 4
        }
        $stateId = if ($integrationState.Uninstalled) {
            [string]$integrationState.StateId
        } else {
            [guid]::NewGuid().ToString('N').ToLowerInvariant()
        }
        $mcpPlan = Get-RepairMcpConfigPlan `
            -ProjectRoot $ProjectRoot `
            -RemoveManagedKeys `
            -UninstallStateId $stateId
        if ($integrationState.Uninstalled -and
            [string]::Equals([string]$integrationState.CleanupState, "COMPLETE", [StringComparison]::Ordinal) -and
            $mcpPlan.Current -and
            [string]::Equals((Get-UninstallCleanupState -Manifest $Manifest -ProjectRoot $ProjectRoot), "COMPLETE", [StringComparison]::Ordinal)) {
            Write-Host "[PHASE DESIRED_STATE] CURRENT - project integration remains UNINSTALLED."
            Write-Host "[CLEANUP_STATE] COMPLETE"
            Write-Host "[RESULT] UNINSTALLED"
            Write-Host "[NEXT] Use Install CodeDB when this project should be integrated again."
            Set-MaterializerCommandOutcome `
                -Outcome "UNINSTALLED" `
                -ReasonCode "UNINSTALL_COMPLETE" `
                -CleanupState "COMPLETE" `
                -NextAction "Use Install CodeDB when this project should be integrated again."
            Set-MaterializerCommandPhase -Phase "COMPLETE"
            return
        }
        if ($AutomaticCleanup) {
            Invoke-TestAutomaticCleanupStateCapturedSignal
        }

        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot -WaitForExisting:$AutomaticCleanup
        Set-MaterializerCommandPhase -Phase "DESIRED_STATE"
        $lockedState = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
        if ($AutomaticCleanup) {
            if (-not $lockedState.Uninstalled -or
                -not [string]::Equals([string]$lockedState.StateId, $stateId, [StringComparison]::Ordinal) -or
                -not [string]::Equals([string]$lockedState.CleanupState, "PENDING", [StringComparison]::Ordinal)) {
                Write-Host "[SKIPPED] Automatic uninstall cleanup became obsolete while waiting for the materializer lock."
                Set-MaterializerCommandOutcome `
                    -Outcome "SKIPPED" `
                    -ReasonCode "DESIRED_STATE_CHANGED" `
                    -CleanupState "COMPLETE" `
                    -NextAction "No action required."
                return
            }
            $desiredStateCommitted = $true
            Write-Host "[PHASE DESIRED_STATE] CURRENT - project integration remains UNINSTALLED."
        } else {
            if ($lockedState.Uninstalled -and
                -not [string]::Equals([string]$lockedState.StateId, $stateId, [StringComparison]::Ordinal)) {
                throw "Project integration desired state identity changed while Uninstall waited for the materializer lock."
            }
            $lockedState = Publish-ProjectIntegrationUninstalledState `
                -Lock $lock `
                -ProjectRoot $ProjectRoot `
                -StateId $stateId
            $desiredStateCommitted = $true
            if ([string]::Equals([string]$lockedState.CleanupState, "COMPLETE", [StringComparison]::Ordinal)) {
                $lockedState = Publish-ProjectIntegrationCleanupState `
                    -Lock $lock `
                    -ProjectRoot $ProjectRoot `
                    -StateId $stateId `
                    -CleanupState "PENDING"
            }
        }
        $mcpPlan = Get-RepairMcpConfigPlan `
            -ProjectRoot $ProjectRoot `
            -RemoveManagedKeys `
            -UninstallStateId $stateId

        if ($AutomaticCleanup) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $stateId -CleanupState "PENDING"
        }
        Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerAction "remove"

        if ($AutomaticCleanup) {
            $flatReport = Get-MaterializerHostUseLeaseReport `
                -LeaseRoot (Join-Path $lock.Root $script:HostUseLeaseDirectoryName) `
                -ProjectRoot $ProjectRoot
            $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
            if ($flatReport.Invalid.Count -gt 0) {
                Throw-MaterializerError -Message "Legacy Host-use lease is invalid and requires manual review: $($flatReport.Invalid[0])" -ExitCode 7
            }
            if ($generationReport.Invalid.Count -gt 0) {
                Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
            }
            foreach ($stale in $flatReport.Stale) {
                $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $stateId -CleanupState "PENDING"
                Remove-Item -LiteralPath $stale.Path -Force
                Add-MaterializerMutationScope -Scope "leases"
                Write-Host "[RECOVERED] Removed proved-stale $($stale.Owner) flat Host-use lease for PID $($stale.ProcessId)."
            }
            foreach ($stale in $generationReport.Stale) {
                $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $stateId -CleanupState "PENDING"
                Remove-Item -LiteralPath $stale.Path -Force
                Add-MaterializerMutationScope -Scope "leases"
                Write-Host "[RECOVERED] Removed proved-stale generation $($stale.GenerationId) $($stale.Owner) lease for PID $($stale.ProcessId)."
            }
            $flatReport = Get-MaterializerHostUseLeaseReport `
                -LeaseRoot (Join-Path $lock.Root $script:HostUseLeaseDirectoryName) `
                -ProjectRoot $ProjectRoot
            $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
            $watcherCleanupPending = @($flatReport.LiveDetails | Where-Object {
                [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal)
            }).Count -gt 0 -or @($generationReport.LiveDetails | Where-Object {
                [string]::Equals([string]$_.Owner, "watcher", [StringComparison]::Ordinal)
            }).Count -gt 0
            $retainedFlatMcps = @(Get-RepairFlatMcpOwners -ProjectRoot $ProjectRoot)
            $retainedGenerationMcps = @(Get-RepairGenerationMcpOwners `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $Manifest.Root `
                -GenerationReport $generationReport)
        } else {
            $ownerGate = Complete-RepairFlatHostUseGate `
                -Lock $lock `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $Manifest.Root
            foreach ($watcher in @($ownerGate.RetainedGenerationWatchers)) {
                Complete-UninstallGenerationWatcherStop `
                    -Lock $lock `
                    -ProjectRoot $ProjectRoot `
                    -PayloadRoot $Manifest.Root `
                    -Watcher $watcher
            }
            $currentGenerationWatchers = @()
            $currentGenerationMcps = @()
            $currentFlatMcps = @()
            Assert-RepairOwnerGateStable `
                -Lock $lock `
                -ProjectRoot $ProjectRoot `
                -PayloadRoot $Manifest.Root `
                -ExpectedGenerationWatchers @() `
                -RetainedGenerationWatchers ([ref]$currentGenerationWatchers) `
                -RetainedGenerationMcps ([ref]$currentGenerationMcps) `
                -RetainedFlatMcps ([ref]$currentFlatMcps)
            if ($currentGenerationWatchers.Count -gt 0) {
                Throw-MaterializerError -Message "Authenticated watcher ownership remained after Uninstall Stop." -ExitCode 4
            }
            $retainedGenerationMcps = @($currentGenerationMcps)
            $retainedFlatMcps = @($currentFlatMcps)
        }

        if ($AutomaticCleanup) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $stateId -CleanupState "PENDING"
        }
        $latestMcpPlan = Get-RepairMcpConfigPlan `
            -ProjectRoot $ProjectRoot `
            -RemoveManagedKeys `
            -UninstallStateId $stateId
        Set-MaterializerCommandPhase -Phase "MCP_REGISTRATION"
        $null = Publish-RepairMcpConfig -Plan $latestMcpPlan -ProjectRoot $ProjectRoot -Lock $lock
        $verifiedMcpPlan = Get-RepairMcpConfigPlan `
            -ProjectRoot $ProjectRoot `
            -RemoveManagedKeys `
            -UninstallStateId $stateId
        if (-not $verifiedMcpPlan.Current) {
            throw "Project MCP registration removal failed verification."
        }

        Invoke-TestUninstallAfterMcpHandshake
        $hasRetainedMcp = $retainedFlatMcps.Count -gt 0 -or $retainedGenerationMcps.Count -gt 0
        if (-not $hasRetainedMcp -and -not $watcherCleanupPending) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $stateId -CleanupState "PENDING"
            Exit-MaterializerWatchManagementLocks -Lock $lock
            Invoke-Remove `
                -Manifest $Manifest `
                -ProjectRoot $ProjectRoot `
                -TargetRoot $TargetRoot `
                -MarkerPath $MarkerPath `
                -ExistingLock $lock `
                -RequiredIntegrationStateId $stateId
        }

        $cleanupState = Get-UninstallCleanupState -Manifest $Manifest -ProjectRoot $ProjectRoot
        if ($hasRetainedMcp -or $watcherCleanupPending) { $cleanupState = "PENDING" }
        $null = Publish-ProjectIntegrationCleanupState `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -StateId $stateId `
            -CleanupState $cleanupState
    } catch {
        $originalError = $_.Exception
        Set-MaterializerCommandOutcome `
            -Outcome "BLOCKED" `
            -ReasonCode "UNINSTALL_BLOCKED" `
            -CleanupState $(if ($desiredStateCommitted) { "PENDING" } else { "COMPLETE" }) `
            -NextAction $(if ($desiredStateCommitted) { "Resolve the reported boundary; automatic cleanup will continue while the project remains Uninstalled." } else { "Resolve the reported boundary, then retry Uninstall CodeDB once." })
        Write-Host "[RESULT] BLOCKED"
        if ($desiredStateCommitted) {
            Write-Host "[CLEANUP_STATE] PENDING"
            Write-Host "[NEXT] Resolve the reported ownership or configuration boundary; the UNINSTALLED state remains in force."
        } else {
            Write-Host "[NEXT] Resolve the reported desired-state or MCP configuration boundary, then retry Uninstall CodeDB from Project."
        }
        if ($script:RequestedExitCode -ne 0) { throw $originalError }
        Throw-MaterializerError -Message $originalError.Message -ExitCode 4
    } finally {
        Exit-MaterializerLock -Lock $lock
    }

    foreach ($owner in $retainedFlatMcps) {
        Write-Host "[RETAINED] flat mcp PID $($owner.ProcessId) keeps its exact owned Host closure; the process was not stopped."
    }
    foreach ($owner in $retainedGenerationMcps) {
        Write-Host "[RETAINED] generation $($owner.GenerationId) mcp PID $($owner.ProcessId) keeps its immutable Host closure; the process was not stopped."
    }
    if ($watcherCleanupPending) {
        Write-Host "[RETAINED] Automatic cleanup did not stop a watcher process."
    }
    Write-Host "[CLEANUP_STATE] $cleanupState"
    Write-Host "[RESULT] UNINSTALLED"
    Set-MaterializerCommandPhase -Phase "COMPLETE"
    if ($cleanupState -eq "PENDING") {
        Write-Host "[NEXT] No action is required; retained closures will be cleaned automatically after their owners drain."
        Set-MaterializerCommandOutcome `
            -Outcome "UNINSTALLED" `
            -ReasonCode "UNINSTALL_CLEANUP_PENDING" `
            -CleanupState "PENDING" `
            -NextAction "No action is required; retained closures will be cleaned automatically after their owners drain."
    } else {
        Write-Host "[NEXT] Use Install CodeDB when this project should be integrated again."
        Set-MaterializerCommandOutcome `
            -Outcome "UNINSTALLED" `
            -ReasonCode "UNINSTALL_COMPLETE" `
            -CleanupState "COMPLETE" `
            -NextAction "Use Install CodeDB when this project should be integrated again."
    }
}

function Invoke-Install {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $integrationState = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
    if (-not $integrationState.Uninstalled) {
        Throw-MaterializerError -Message "Install CodeDB requires a valid UNINSTALLED project integration state." -ExitCode 4
    }

    $cleanupState = "COMPLETE"
    $lock = $null
    Set-MaterializerCommandPhase -Phase "PREFLIGHT"
    try {
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot -WaitForExisting
        $lockedState = Assert-ProjectIntegrationStateMatch `
            -ProjectRoot $ProjectRoot `
            -StateId $integrationState.StateId
        Invoke-Repair `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -TargetRoot $TargetRoot `
            -MarkerPath $MarkerPath `
            -InstallMode `
            -ResultCleanupState ([ref]$cleanupState) `
            -ExistingLock $lock `
            -InstallStateId $lockedState.StateId

        Invoke-TestInstallAfterRepairHandshake
        $verifiedHost = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if (-not $verifiedHost.IsCurrent) {
            throw "Install CodeDB final Host verification did not reach the current state."
        }
        $verifiedMcp = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
        if (-not $verifiedMcp.Current) {
            throw "Install CodeDB final MCP registration verification failed."
        }
        $verifiedAvailability = Get-McpAvailabilityStatus -Manifest $Manifest -ProjectRoot $ProjectRoot
        if (-not $verifiedAvailability.Current) {
            throw "Install CodeDB final Package-owned MCP handshake verification failed."
        }
        $null = Assert-ProjectIntegrationStateMatch `
            -ProjectRoot $ProjectRoot `
            -StateId $lockedState.StateId
        $null = Clear-ProjectIntegrationUninstalledState `
            -Lock $lock `
            -ProjectRoot $ProjectRoot `
            -StateId $lockedState.StateId
        if ((Get-ProjectIntegrationState -ProjectRoot $ProjectRoot).Present) {
            throw "Install CodeDB final desired-state verification failed."
        }
    } finally {
        Exit-MaterializerLock -Lock $lock
    }
    Write-Host "[CLEANUP_STATE] $cleanupState"
    Write-Host "[RESULT] INSTALLED"
    Write-Host "[PRODUCT_STATE] READY"
    Write-Host "[NEXT] Start a new Codex session so it reads the installed project MCP configuration."
    Set-MaterializerCommandPhase -Phase "COMPLETE"
    Set-MaterializerCommandOutcome `
        -Outcome "INSTALLED" `
        -ReasonCode "INSTALL_COMPLETE" `
        -CleanupState $cleanupState `
        -NextAction "Start a new Codex task so it reads the installed project MCP configuration."
}

function Get-MarkerlessInstanceClosureFiles {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $files = New-Object System.Collections.Generic.List[object]
    foreach ($file in $Manifest.Files) {
        if (-not (Test-Path -LiteralPath $file.TargetPath)) { continue }
        Assert-NoReparsePoint -Path $file.TargetPath -Root $ProjectRoot -Label "markerless instance closure target"
        if (-not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $file.TargetPath), [string]$file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Markerless instance closure target is not the exact Package-owned file: $($file.Target)"
        }
        $files.Add([pscustomobject]@{
            Target = $file.Target
            TargetPath = $file.TargetPath
            InstalledSha256 = $file.Sha256
        })
    }
    return $files.ToArray()
}

function Invoke-Remove {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [AllowNull()]$ExistingLock,
        [AllowNull()][string]$RequiredIntegrationStateId,
        [switch]$AllowMarkerlessInstanceClosure
    )

    $lock = $ExistingLock
    $ownsLock = $null -eq $ExistingLock
    $transactionRoot = $null
    $keepTransaction = $false
    $entries = $null
    Set-MaterializerCommandPhase -Phase "PREFLIGHT"
    # Reject an older Package before acquiring owner-management locks or
    # publishing recovery state. Marker, current, and rollback identities are
    # independent deletion authorities and each must stay within this manifest.
    $null = Assert-RemovalIdentityUpperBound -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    Assert-RemovalPendingTransactionUpperBoundBeforeLock -Manifest $Manifest -ProjectRoot $ProjectRoot
    if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
        $null = Assert-ProjectIntegrationStateMatch `
            -ProjectRoot $ProjectRoot `
            -StateId $RequiredIntegrationStateId `
            -CleanupState "PENDING"
    }
    try {
        if ($ownsLock) {
            $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot
        }
        Set-MaterializerCommandPhase -Phase "HOST_RUNTIME"
        if ($ownsLock -and $lock.LockFileExistedBefore) {
            $lock.PreserveLockFile = $true
        }
        Invoke-TestRemoveAfterLockHandshake
        if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
            $null = Assert-ProjectIntegrationStateMatch `
                -ProjectRoot $ProjectRoot `
                -StateId $RequiredIntegrationStateId `
                -CleanupState "PENDING"
        }
        # Re-check every live identity and every journal rollback pre-image
        # before active state, recovery, lease reclamation, or Host mutation.
        $markerBeforeGate = Assert-RemovalIdentityUpperBound -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        Assert-RemovalPendingTransactionUpperBound -Manifest $Manifest -Lock $lock -ProjectRoot $ProjectRoot
        if ($null -eq $markerBeforeGate -and $AllowMarkerlessInstanceClosure) {
            $null = @(Get-MarkerlessInstanceClosureFiles -Manifest $Manifest -ProjectRoot $ProjectRoot)
        }
        $lock.PreserveLockFile = $false
        if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $RequiredIntegrationStateId -CleanupState "PENDING"
        }
        Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerAction "remove"
        if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $RequiredIntegrationStateId -CleanupState "PENDING"
        }
        $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -AutomaticOnly
        $markerBeforeGate = Assert-RemovalIdentityUpperBound -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        Assert-RemovalPendingTransactionUpperBound -Manifest $Manifest -Lock $lock -ProjectRoot $ProjectRoot
        if ($null -eq $markerBeforeGate -and $AllowMarkerlessInstanceClosure) {
            $null = @(Get-MarkerlessInstanceClosureFiles -Manifest $Manifest -ProjectRoot $ProjectRoot)
        }
        if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $RequiredIntegrationStateId -CleanupState "PENDING"
        }
        if ($null -eq $markerBeforeGate -and $AllowMarkerlessInstanceClosure) {
            $lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
            Enter-MaterializerWatchManagementLocks -Lock $lock -ProjectRoot $ProjectRoot
            Assert-NoLiveHostUseLeases -Lock $lock -ProjectRoot $ProjectRoot
            Assert-NoLiveLegacyWatcherState -Lock $lock -ProjectRoot $ProjectRoot
        } else {
            Complete-MaterializerHostUseGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
        }
        if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $RequiredIntegrationStateId -CleanupState "PENDING"
        }
        $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -SkipAutomaticUpgrade
        $marker = Assert-RemovalIdentityUpperBound -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if ($null -eq $marker -and -not $AllowMarkerlessInstanceClosure) {
            Write-Host "[OK] No managed host payload is installed."
            Set-MaterializerCommandOutcome `
                -Outcome "REMOVED" `
                -ReasonCode "REMOVE_COMPLETE" `
                -CleanupState "COMPLETE" `
                -NextAction "No action required."
            Set-MaterializerCommandPhase -Phase "COMPLETE"
            return
        }

        $managedRemovalFiles = New-Object System.Collections.Generic.List[object]
        if ($null -ne $marker) {
            foreach ($item in $marker.Files) { $managedRemovalFiles.Add($item) }
        } else {
            foreach ($file in @(Get-MarkerlessInstanceClosureFiles -Manifest $Manifest -ProjectRoot $ProjectRoot)) {
                $managedRemovalFiles.Add($file)
            }
        }

        $conflicts = New-Object System.Collections.Generic.List[string]
        foreach ($item in $managedRemovalFiles) {
            $isTrustedTarget = @($Manifest.Files | Where-Object { [string]::Equals($_.Target, $item.Target, [StringComparison]::OrdinalIgnoreCase) }).Count -eq 1 -or
                $Manifest.RetiredTargetMap.ContainsKey($item.Target)
            if (-not $isTrustedTarget) {
                $conflicts.Add("$($item.Target) is not allowed by the current or retired manifest allowlist")
            } elseif (-not (Test-Path -LiteralPath $item.TargetPath -PathType Leaf)) {
                $conflicts.Add("$($item.Target) is missing or not a file")
            } elseif (-not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), $item.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $conflicts.Add("$($item.Target) changed after installation")
            }
        }
        if ($conflicts.Count -gt 0) {
            foreach ($conflict in $conflicts) {
                Write-Host "[CONFLICT] $conflict"
            }
            Throw-MaterializerError -Message "Payload removal was rejected because managed files drifted." -ExitCode 3
        }

        $extraRemovalTargets = New-Object System.Collections.Generic.List[object]
        $removalTargetMap = @{}
        foreach ($item in $managedRemovalFiles) {
            $removalTargetMap[$item.Target] = $true
        }
        $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "selected generation pointer"
        if (Test-Path -LiteralPath $currentPointerPath) {
            $selectedGeneration = Assert-RemovalGenerationPointerUpperBound -Manifest $Manifest -PointerPath $currentPointerPath -PointerLabel "current.json" -ProjectRoot $ProjectRoot
            foreach ($managedFile in $selectedGeneration.ManagedFiles) {
                $relativePath = $managedFile.Path.Substring([System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/').Length + 1).Replace('\', '/')
                $relativePath = Assert-TargetRelativePath -Path $relativePath
                if (-not $removalTargetMap.ContainsKey($relativePath)) {
                    $extraRemovalTargets.Add([pscustomobject]@{ Target = $relativePath; TargetPath = $managedFile.Path })
                    $removalTargetMap[$relativePath] = $true
                }
            }
            if (-not $removalTargetMap.ContainsKey($script:CurrentPointerRelativePath)) {
                $extraRemovalTargets.Add([pscustomobject]@{ Target = $script:CurrentPointerRelativePath; TargetPath = $currentPointerPath })
                $removalTargetMap[$script:CurrentPointerRelativePath] = $true
            }
        }
        $candidateGenerationRoot = ConvertTo-AbsoluteChildPath `
            -Root $ProjectRoot `
            -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') `
            -Label "package generation candidate"
        if (Test-Path -LiteralPath $candidateGenerationRoot) {
            # A failed automatic handoff can leave a complete but unselected
            # package generation beside the restored legacy installation.
            Assert-GenerationDirectoryMatchesManifest `
                -Manifest $Manifest `
                -GenerationRoot $candidateGenerationRoot `
                -ProjectRoot $ProjectRoot `
                -SkipSyntaxValidation
            foreach ($managedFile in @($Manifest.Files | Where-Object {
                $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
            })) {
                if (-not $removalTargetMap.ContainsKey($managedFile.Target)) {
                    $extraRemovalTargets.Add([pscustomobject]@{ Target = $managedFile.Target; TargetPath = $managedFile.TargetPath })
                    $removalTargetMap[$managedFile.Target] = $true
                }
            }
        }
        $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
        if (Test-Path -LiteralPath $lastKnownGoodPath) {
            $lastKnownGood = Assert-RemovalGenerationPointerUpperBound -Manifest $Manifest -PointerPath $lastKnownGoodPath -PointerLabel "last-known-good.json" -ProjectRoot $ProjectRoot
            foreach ($managedFile in $lastKnownGood.ManagedFiles) {
                $relativePath = $managedFile.Path.Substring([System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/').Length + 1).Replace('\', '/')
                $relativePath = Assert-TargetRelativePath -Path $relativePath
                if (-not $removalTargetMap.ContainsKey($relativePath)) {
                    $extraRemovalTargets.Add([pscustomobject]@{ Target = $relativePath; TargetPath = $managedFile.Path })
                    $removalTargetMap[$relativePath] = $true
                }
            }
            if (-not $removalTargetMap.ContainsKey($script:LastKnownGoodPointerRelativePath)) {
                $extraRemovalTargets.Add([pscustomobject]@{ Target = $script:LastKnownGoodPointerRelativePath; TargetPath = $lastKnownGoodPath })
                $removalTargetMap[$script:LastKnownGoodPointerRelativePath] = $true
            }
        }
        $upgradeStatePath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:UpgradeStateRelativePath -Label "materializer upgrade state"
        if (Test-Path -LiteralPath $upgradeStatePath) {
            Assert-MaterializerUpgradeStateArtifact -Path $upgradeStatePath -ProjectRoot $ProjectRoot
            $extraRemovalTargets.Add([pscustomobject]@{ Target = $script:UpgradeStateRelativePath; TargetPath = $upgradeStatePath })
            $removalTargetMap[$script:UpgradeStateRelativePath] = $true
        }
        $mcpAvailabilityPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:McpAvailabilityRelativePath -Label "MCP availability state"
        if (Test-Path -LiteralPath $mcpAvailabilityPath) {
            $null = Assert-McpAvailabilityStateArtifact -Path $mcpAvailabilityPath -ProjectRoot $ProjectRoot
            $extraRemovalTargets.Add([pscustomobject]@{ Target = $script:McpAvailabilityRelativePath; TargetPath = $mcpAvailabilityPath })
            $removalTargetMap[$script:McpAvailabilityRelativePath] = $true
        }

        $transactionRoot = Join-Path $lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $backupRoot = Join-Path $transactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]
        foreach ($item in $managedRemovalFiles) {
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Delete" `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }
        foreach ($item in @($extraRemovalTargets | Sort-Object Target)) {
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Delete" `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }
        if ($null -ne $marker) {
            $entries.Add((New-TransactionEntry `
                -Target $script:MarkerRelativePath `
                -TargetPath $MarkerPath `
                -Mutation "Delete" `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }

        # The durable journal is the recovery commit point; target mutations start after it.
        if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
            $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $RequiredIntegrationStateId -CleanupState "PENDING"
        }
        Write-TransactionJournal -Operation "Remove" -TransactionRoot $transactionRoot -Entries $entries.ToArray() -Manifest $Manifest
        foreach ($entry in $entries) {
            if (-not [string]::IsNullOrWhiteSpace($RequiredIntegrationStateId)) {
                $null = Assert-ProjectIntegrationStateMatch -ProjectRoot $ProjectRoot -StateId $RequiredIntegrationStateId -CleanupState "PENDING"
            }
            Assert-TransactionEntryBeforeMutation -Entry $entry
            Remove-Item -LiteralPath $entry.TargetPath -Force
            if (Test-Path -LiteralPath $entry.TargetPath) {
                throw "Managed payload target remained after deletion: $($entry.Target)"
            }
            Invoke-TestCrashAfterRemovalMarkerDeletion -Target $entry.Target
            Add-MaterializerMutationScope -Scope "host_runtime"
            Invoke-TestFaultAfterMutation
        }
        $flatRemovedPaths = @($managedRemovalFiles | Where-Object {
            $_.Target.StartsWith("AIWork/codedb/", [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object { $_.TargetPath })
        if ($flatRemovedPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $flatRemovedPaths -TargetRoot $TargetRoot
        }
        $hostRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host" -Label "host generation runtime"
        $runtimeRemovedPaths = @($managedRemovalFiles | Where-Object {
            $_.Target.StartsWith("AIWork/.runtime/codedb/host/", [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object { $_.TargetPath }) + @($extraRemovalTargets | Where-Object {
            $_.Target.StartsWith("AIWork/.runtime/codedb/host/", [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object { $_.TargetPath })
        if ($runtimeRemovedPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $runtimeRemovedPaths -TargetRoot $hostRuntimeRoot
        }
        $generationLeaseRoot = Join-Path $hostRuntimeRoot "leases"
        if (Test-Path -LiteralPath $generationLeaseRoot -PathType Container) {
            foreach ($generationLeaseDirectory in @(Get-ChildItem -LiteralPath $generationLeaseRoot -Force -Directory)) {
                if (@(Get-ChildItem -LiteralPath $generationLeaseDirectory.FullName -Force).Count -eq 0) {
                    Remove-Item -LiteralPath $generationLeaseDirectory.FullName -Force
                }
            }
            if (@(Get-ChildItem -LiteralPath $generationLeaseRoot -Force).Count -eq 0) {
                Remove-Item -LiteralPath $generationLeaseRoot -Force
            }
        }
        if ((Test-Path -LiteralPath $hostRuntimeRoot -PathType Container) -and
            @(Get-ChildItem -LiteralPath $hostRuntimeRoot -Force).Count -eq 0) {
            Remove-Item -LiteralPath $hostRuntimeRoot -Force
        }
        Write-Host "[OK] Managed host payload was removed; unrelated host files were preserved."
        Set-MaterializerCommandOutcome `
            -Outcome "REMOVED" `
            -ReasonCode "REMOVE_COMPLETE" `
            -CleanupState "COMPLETE" `
            -NextAction "No action required."
        Set-MaterializerCommandPhase -Phase "COMPLETE"
    } catch {
        $originalError = $_.Exception
        Set-MaterializerCommandOutcome `
            -Outcome "BLOCKED" `
            -ReasonCode "REMOVE_BLOCKED" `
            -CleanupState $(if ($script:CommandMutatedScopes.Count -gt 0) { "PENDING" } else { "COMPLETE" }) `
            -NextAction "Review the reported ownership or rollback boundary before retrying removal."
        if ($null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
            if ($rollbackErrors.Count -gt 0) {
                $keepTransaction = $true
                Throw-MaterializerError -Message "Payload removal failed and rollback was incomplete. $($rollbackErrors -join '; ') Transaction: $transactionRoot" -ExitCode 7
            }
        }
        if ($script:RequestedExitCode -ne 0) {
            throw $originalError
        }
        Throw-MaterializerError -Message "Payload removal failed and was rolled back. $($originalError.Message)" -ExitCode 6
    } finally {
        if ($null -ne $transactionRoot -and -not $keepTransaction -and (Test-Path -LiteralPath $transactionRoot)) {
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($ownsLock) {
            Exit-MaterializerLock -Lock $lock
        }
    }
}

. (Join-Path $PSScriptRoot "codedb-instance-engine.ps1")

try {
    if ($ConfirmedProjectMutation -and $Action -notin @("Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install")) {
        Throw-MaterializerError -Message "Project mutation confirmation is valid only for Redeploy, Sync, Remove, Repair, Reinstall, Uninstall, or Install." -ExitCode 4
    }
    if ($PocFixture -and $ConfirmedProjectMutation) {
        Throw-MaterializerError -Message "Fixture and confirmed project mutation modes are mutually exclusive." -ExitCode 4
    }
    if ($TestProcessIdentityUnavailableForPid -gt 0 -and -not $PocFixture) {
        Throw-MaterializerError -Message "Process identity fault injection requires fixture mode." -ExitCode 4
    }
    $hasRemoveLockAcquiredEvent = -not [string]::IsNullOrWhiteSpace($TestRemoveLockAcquiredEventName)
    $hasRemoveContinueEvent = -not [string]::IsNullOrWhiteSpace($TestRemoveContinueEventName)
    if ($hasRemoveLockAcquiredEvent -ne $hasRemoveContinueEvent -or
        ($hasRemoveLockAcquiredEvent -and (-not $PocFixture -or $Action -ne "Remove"))) {
        Throw-MaterializerError -Message "Remove lock handshake requires paired fixture-only Remove event names." -ExitCode 4
    }
    $requestedTestFaultCount = 0
    if ($TestFailAfterMutation -gt 0) { $requestedTestFaultCount += 1 }
    if ($TestCrashAfterMutation -gt 0) { $requestedTestFaultCount += 1 }
    if ($TestFailWatcherHandoff) { $requestedTestFaultCount += 1 }
    if ($TestCrashBeforeWatcherHandoff) { $requestedTestFaultCount += 1 }
    if ($TestFailRepairMcpRegistration) { $requestedTestFaultCount += 1 }
    if ($TestCrashAfterRemovalMarkerDeletion) { $requestedTestFaultCount += 1 }
    if ($TestFailInstanceCandidate) { $requestedTestFaultCount += 1 }
    if ($requestedTestFaultCount -gt 1) {
        Throw-MaterializerError -Message "Only one materializer test fault may be requested at a time." -ExitCode 2
    }
    if ($TestFailWatcherHandoff -and (-not $PocFixture -or $Action -notin @("Upgrade", "Repair"))) {
        Throw-MaterializerError -Message "Watcher handoff fault injection requires a fixture-only Upgrade or Repair action." -ExitCode 4
    }
    if ($TestCrashBeforeWatcherHandoff -and (-not $PocFixture -or $Action -ne "Upgrade")) {
        Throw-MaterializerError -Message "Pre-handoff crash injection requires a fixture-only Upgrade action." -ExitCode 4
    }
    if ($TestFailRepairMcpRegistration -and (-not $PocFixture -or $Action -notin @("Repair", "Install"))) {
        Throw-MaterializerError -Message "MCP registration fault injection requires a fixture-only Repair or Install action." -ExitCode 4
    }
    if ($TestCrashAfterRemovalMarkerDeletion -and (-not $PocFixture -or $Action -ne "Remove")) {
        Throw-MaterializerError -Message "Post-marker Remove crash injection requires a fixture-only Remove action." -ExitCode 4
    }
    if ($TestFailInstanceCandidate -and (-not $PocFixture -or $Action -notin @("Upgrade", "Install", "Reinstall"))) {
        Throw-MaterializerError -Message "Candidate failure injection requires a fixture-only Upgrade, Install, or Reinstall action." -ExitCode 4
    }
    $hasRepairHandshake = -not [string]::IsNullOrWhiteSpace($TestRepairMarkerPublishedEventName) -or
        -not [string]::IsNullOrWhiteSpace($TestRepairContinueEventName)
    if ($hasRepairHandshake -and
        (-not $PocFixture -or $Action -ne "Repair" -or
         [string]::IsNullOrWhiteSpace($TestRepairMarkerPublishedEventName) -or
         [string]::IsNullOrWhiteSpace($TestRepairContinueEventName))) {
        Throw-MaterializerError -Message "Repair marker handshake requires both fixture event names and a fixture-only Repair action." -ExitCode 4
    }
    $hasUninstallHandshake = -not [string]::IsNullOrWhiteSpace($TestUninstallMcpPublishedEventName) -or
        -not [string]::IsNullOrWhiteSpace($TestUninstallContinueEventName)
    if ($hasUninstallHandshake -and
        (-not $PocFixture -or $Action -notin @("Uninstall", "Upgrade") -or
         [string]::IsNullOrWhiteSpace($TestUninstallMcpPublishedEventName) -or
         [string]::IsNullOrWhiteSpace($TestUninstallContinueEventName))) {
        Throw-MaterializerError -Message "Uninstall MCP handshake requires both fixture event names and a fixture-only Uninstall or automatic cleanup action." -ExitCode 4
    }
    $hasInstallHandshake = -not [string]::IsNullOrWhiteSpace($TestInstallRepairCompletedEventName) -or
        -not [string]::IsNullOrWhiteSpace($TestInstallContinueEventName)
    if ($hasInstallHandshake -and
        (-not $PocFixture -or $Action -ne "Install" -or
         [string]::IsNullOrWhiteSpace($TestInstallRepairCompletedEventName) -or
         [string]::IsNullOrWhiteSpace($TestInstallContinueEventName))) {
        Throw-MaterializerError -Message "Install Repair-completed handshake requires both fixture event names and a fixture-only Install action." -ExitCode 4
    }
    if (-not [string]::IsNullOrWhiteSpace($TestAutomaticCleanupStateCapturedEventName) -and
        (-not $PocFixture -or $Action -ne "Upgrade")) {
        Throw-MaterializerError -Message "Automatic cleanup state-captured signal requires a fixture-only Upgrade action." -ExitCode 4
    }
    if (($TestFailAfterMutation -gt 0 -or $TestCrashAfterMutation -gt 0) -and
        (-not $PocFixture -or $Action -notin @("Upgrade", "Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install"))) {
        Throw-MaterializerError -Message "Materializer test faults require a fixture-only Upgrade, Redeploy, Sync, Remove, Repair, Reinstall, Uninstall, or Install action." -ExitCode 4
    }

    $projectRootPath = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $projectRootPath -PathType Container)) {
        Throw-MaterializerError -Message "Project root does not exist: $projectRootPath" -ExitCode 2
    }
    Assert-NoReparsePoint -Path $projectRootPath -Root $projectRootPath -Label "project root"
    Assert-UnityProjectRoot -Root $projectRootPath
    Set-EditorLeaseHandoff `
        -SessionId $EditorSessionId `
        -ProcessId $EditorProcessId `
        -ProcessStartTicks $EditorProcessStartTicks

    if ([string]::IsNullOrWhiteSpace($PayloadRoot)) {
        $packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
        $PayloadRoot = Join-Path $packageRoot "Payload~"
    }
    $payload = Read-PayloadManifest -Root $PayloadRoot -ProjectRoot $projectRootPath
    if ($Action -in @("Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install")) {
        Assert-MutationConfirmation -Root $projectRootPath -Manifest $payload -MutationAction $Action
    }
    $targetRoot = ConvertTo-AbsoluteChildPath -Root $projectRootPath -RelativePath "AIWork/codedb" -Label "host payload root"
    $markerPath = ConvertTo-AbsoluteChildPath -Root $projectRootPath -RelativePath $script:MarkerRelativePath -Label "installed payload marker"
    $integrationState = Get-ProjectIntegrationState -ProjectRoot $projectRootPath
    $instanceDesiredState = Get-InstanceDesiredState -ProjectRoot $projectRootPath

    if ($instanceDesiredState.DesiredState -eq "UNINSTALLED") {
        switch ($Action) {
            "DryRun" {
                Write-Host "[UNINSTALLED] CodeDB project integration is disabled; automatic installation and watcher attachment remain suppressed."
                Write-Host "[NEXT] Use Install CodeDB when this project should be integrated again."
                exit 0
            }
            "Verify" {
                Write-Host "[UNINSTALLED] CodeDB project integration is absent by explicit project desired state."
                exit 0
            }
            "Upgrade" {
                Invoke-InstanceUninstall -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath -AutomaticCleanup
                Write-MaterializerCommandResult -ExitCode 0
                exit 0
            }
            "Remove" {
                Invoke-InstanceUninstall -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath -AutomaticCleanup
                Write-MaterializerCommandResult -ExitCode 0
                exit 0
            }
            "Uninstall" {
                Invoke-InstanceUninstall -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath
                Write-MaterializerCommandResult -ExitCode 0
                exit 0
            }
            "Install" {
                Invoke-InstanceConvergence -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath -ActionName "Install"
                Write-MaterializerCommandResult -ExitCode 0
                exit 0
            }
            default {
                Write-Host "[RESULT] BLOCKED"
                Write-Host "[NEXT] Use Install CodeDB to restore this project's integration."
                Throw-MaterializerError -Message "$Action cannot reinstall a project whose desired state is UNINSTALLED." -ExitCode 4
            }
        }
    }

    if ($Action -eq "Install") {
        Throw-MaterializerError -Message "Install CodeDB is available only while project integration is UNINSTALLED." -ExitCode 4
    }

    if ($Action -eq "DryRun") {
        $script:MachinePrerequisiteStatus = Get-MaterializerMachinePrerequisiteStatus -Manifest $payload
        Write-MachinePrerequisiteStatus -Status $script:MachinePrerequisiteStatus
        if (-not $script:MachinePrerequisiteStatus.Current) {
            exit 0
        }
    } elseif ($Action -notin @("Remove", "Uninstall")) {
        $null = Assert-MachinePrerequisiteForAction -Manifest $payload -ActionName $Action
    }

    switch ($Action) {
        "DryRun" {
            if (Write-InstanceProductStatus -Manifest $payload -ProjectRoot $projectRootPath) { exit 0 }
            $plan = Get-MaterializationPlan -Manifest $payload -MarkerPath $markerPath -ProjectRoot $projectRootPath
            Write-MaterializationPlan -Plan $plan
            $upgradeEligibility = Get-AutomaticUpgradeEligibility -Manifest $payload -Plan $plan -ProjectRoot $projectRootPath
            $redeployEligibility = Get-OwnedLegacyRedeployEligibility -Manifest $payload -Plan $plan
            $pendingAutomaticRecovery = if ($plan.IsCurrent) {
                Get-PendingAutomaticUpgradeRecovery -Manifest $payload -ProjectRoot $projectRootPath
            } else {
                [pscustomobject]@{ Pending = $false; TransactionId = $null }
            }
            Write-HostUseLeaseGuidance -ProjectRoot $projectRootPath
            if ($pendingAutomaticRecovery.Pending) {
                Write-Host "[UPGRADE_READY] Interrupted automatic host upgrade $($pendingAutomaticRecovery.TransactionId) requires recovery before watcher handoff."
                Write-Host "[STALE] Host payload files are current but automatic upgrade recovery is pending."
            } elseif ($plan.IsCurrent) {
                Write-Host "[OK] Host payload is current."
            } elseif ($upgradeEligibility.Eligible) {
                $installedGeneration = if ($null -ne $plan.SelectedGeneration) {
                    [string]$plan.SelectedGeneration.GenerationId
                } elseif ($null -ne $plan.Marker) {
                    [string]$plan.Marker.GenerationId
                } else {
                    ""
                }
                $installedIdentity = if ($null -eq $plan.Marker) {
                    "empty CodeDB scope"
                } elseif ($installedGeneration -match '^[A-Za-z0-9._-]{1,64}$') {
                    "generation $installedGeneration"
                } else {
                    "payload $([string]$plan.Marker.PayloadVersion)"
                }
                Write-Host "[UPGRADE_READY] Owned $installedIdentity can migrate to generation $($payload.GenerationId) while existing leases drain naturally."
                Write-Host "[UPGRADE_SOURCE] $($upgradeEligibility.Reason)"
                Write-Host "[STALE] Host payload has a safe automatic generation upgrade."
            } elseif ($redeployEligibility.Eligible) {
                Write-Host "[REDEPLOY_READY] Owned payload $([string]$plan.Marker.PayloadVersion) can redeploy to generation $($payload.GenerationId) after MCP and watcher owners stop."
                Write-Host "[STALE] Host payload requires a controlled legacy redeploy."
            } elseif ($plan.HasConflict) {
                Write-Host "[STALE] Host payload has conflicts; Sync would be rejected."
            } else {
                Write-Host "[UPGRADE_BLOCKED] $($upgradeEligibility.Reason)"
                Write-Host "[STALE] Host payload can be synchronized without overwriting unowned changes."
            }
            $cleanupState = Get-PersistedMaterializerCleanupState `
                -ProjectRoot $projectRootPath `
                -GenerationId $payload.GenerationId
            Write-ProductLayerStatus `
                -Manifest $payload `
                -ProjectRoot $projectRootPath `
                -Plan $plan `
                -CleanupState $cleanupState
        }
        "Probe" {
            $lock = $null
            try {
                $lock = Enter-MaterializerLock -ProjectRoot $projectRootPath
                # An activated immutable instance owns its own runtime and
                # availability evidence. Probe that closure in place instead
                # of routing through the legacy flat Host probe, which would
                # report a healthy instance as "current Host runtime" missing.
                $currentInstancePath = Get-InstanceProjectPath `
                    -ProjectRoot $projectRootPath `
                    -RelativePath $script:InstanceCurrentRelativePath `
                    -Label "current instance selection"
                if (Test-Path -LiteralPath $currentInstancePath) {
                    Write-InstanceProductStatus `
                        -Manifest $payload `
                        -ProjectRoot $projectRootPath `
                        -LiveProbe `
                        -RequireReady
                } else {
                    $availability = Invoke-McpAvailabilityProbe -Manifest $payload -ProjectRoot $projectRootPath -Lock $lock
                    if (-not $availability.Current) {
                        Throw-MaterializerError -Message "Package-owned MCP availability probe did not reach READY." -ExitCode 5
                    }
                    $plan = Get-MaterializationPlan -Manifest $payload -MarkerPath $markerPath -ProjectRoot $projectRootPath
                    $cleanupState = Get-PersistedMaterializerCleanupState `
                        -ProjectRoot $projectRootPath `
                        -GenerationId $payload.GenerationId
                    Write-ProductLayerStatus `
                        -Manifest $payload `
                        -ProjectRoot $projectRootPath `
                        -Plan $plan `
                        -CleanupState $cleanupState
                }
            } finally {
                Exit-MaterializerLock -Lock $lock
            }
        }
        "Verify" {
            if (Write-InstanceProductStatus -Manifest $payload -ProjectRoot $projectRootPath) { exit 0 }
            $plan = Get-MaterializationPlan -Manifest $payload -MarkerPath $markerPath -ProjectRoot $projectRootPath
            Write-MaterializationPlan -Plan $plan
            if (-not $plan.IsCurrent) {
                Throw-MaterializerError -Message "Host payload is not current." -ExitCode 3
            }
            Write-Host "[OK] Host payload marker and managed files are current."
        }
        "Upgrade" {
            Invoke-InstanceConvergence -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath -ActionName "Upgrade"
        }
        "Reinstall" {
            Invoke-InstanceConvergence -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath -ActionName "Reinstall"
        }
        "Redeploy" {
            Invoke-Sync -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath -OwnedLegacyRedeploy
        }
        "Sync" {
            Invoke-Sync -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath
        }
        "Remove" {
            Invoke-Remove -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath
        }
        "Repair" {
            Invoke-Repair -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath
        }
        "Uninstall" {
            Invoke-InstanceUninstall -Manifest $payload -ProjectRoot $projectRootPath -MarkerPath $markerPath
        }
    }
    Write-MaterializerCommandResult -ExitCode 0
    exit 0
} catch {
    $exitCode = $script:RequestedExitCode
    if ($exitCode -eq 0) { $exitCode = 1 }
    Write-MaterializerCommandResult -ExitCode $exitCode -ErrorDetail $_.Exception.Message
    [Console]::Error.WriteLine($_.Exception.Message)
    exit $exitCode
}
