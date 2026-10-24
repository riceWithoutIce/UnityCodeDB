# Loading these functions performs no ETW call. Tests inject a simulated controller.
function Read-S39InputHashes([string]$ProjectRoot) {
    @('.codex/config.toml','Packages/manifest.json','Packages/packages-lock.json',
      'AIWork/.runtime/codedb/control/current-instance.json','AIWork/codedb/wrapper/codedb-project-wrapper.mjs') | ForEach-Object {
        [pscustomobject]@{relative_path=$_; sha256=(Get-FileHash -LiteralPath (Join-Path $ProjectRoot $_) -Algorithm SHA256).Hash.ToLowerInvariant()}
    }
}
function Get-S39CleanupStatus($State) {
    if (!$State.StartAttempted) { return 'NOT_STARTED' }
    if ($State.StartCode -ne 0) {
        if ($State.FinalQueryCode -eq 4201) { return 'START_FAILED_ABSENT' }
        return 'START_FAILED_STATE_UNCONFIRMED'
    }
    if (!$State.StopAttempted -or $State.StopCode -ne 0) { return 'OWNED_STOP_NOT_CONFIRMED' }
    if ($State.FinalQueryCode -ne 4201) { return 'ABSENCE_NOT_CONFIRMED' }
    return 'STOPPED_ABSENT'
}
function Invoke-S39CommandLineObservation {
    param(
        [Parameter(Mandatory=$true)][string]$ProjectRoot,
        [Parameter(Mandatory=$true)][string]$EvidenceRoot,
        [Parameter(Mandatory=$true)][string]$SessionName,
        [Parameter(Mandatory=$true)][guid]$SessionGuid,
        [Parameter(Mandatory=$true)][string]$DesktopLog,
        [Parameter(Mandatory=$true)][scriptblock]$ControllerFactory
    )
    $ErrorActionPreference = 'Stop'
    if ($SessionName -notmatch '^CodeDB-S39-Cmd-[a-f0-9]{32}$') { throw 'Invalid owned session name' }
    $repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
    $allowed = [IO.Path]::GetFullPath((Join-Path $repo '.artifacts/tests/s39-commandline-observation'))
    $destination = [IO.Path]::GetFullPath($EvidenceRoot)
    if (!$destination.StartsWith($allowed + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Evidence outside owned root' }
    if (Test-Path -LiteralPath $destination) { throw 'Evidence destination already exists' }
    for ($ancestor=$destination; $ancestor; $ancestor=Split-Path $ancestor -Parent) {
        if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse ancestor rejected' }
    }
    New-Item -ItemType Directory -Path $destination | Out-Null
    $receiptPath = Join-Path $destination 'receipt.json'
    $tracePath = Join-Path $destination 'process.etl'
    $receipt = [ordered]@{
        session=$SessionName; session_guid=$SessionGuid.ToString(); project_root=[IO.Path]::GetFullPath($ProjectRoot)
        mode='NOT_STARTED'; outcome='PREPARING'; cleanup_status='NOT_STARTED'
        raw_scope='system-wide process events including full command lines, existing-process rundown and UserSID'
        max_seconds=60; max_mib=16; trace_path=$tracePath; ready_utc=$null; ended_utc=$null
        native_state=$null; host_events=@(); before=@(); after=@(); input_hashes_unchanged=$null; exception=$null
    }
    $controller=$null; $reader=$null
    try {
        $receipt.before=@(Read-S39InputHashes $ProjectRoot)
        $stream=[IO.File]::Open($DesktopLog,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        [void]$stream.Seek(0,[IO.SeekOrigin]::End)
        $reader=New-Object IO.StreamReader($stream)
        $controller=& $ControllerFactory $SessionName $tracePath $SessionGuid
        $receipt.mode=$(if ($controller.Snapshot().IsNative) {'NATIVE'} else {'OFFLINE_SIMULATION'})
        $controller.Begin()
        $state=$controller.Snapshot()
        if (!$state.StartAttempted) {
            $receipt.outcome=$(if ($state.InitialQueryCode -eq 0) {'SESSION_COLLISION_NO_START'} else {'INITIAL_STATE_UNKNOWN_NO_START'})
        } elseif ($state.StartCode -ne 0) { $receipt.outcome='START_FAILED_NO_RETRY' }
        elseif (!$state.Owned -or $state.StopAttempted) { $receipt.outcome='STOPPED_BEFORE_READY' }
        else {
            $receipt.ready_utc=[DateTime]::UtcNow.ToString('o')
            $receipt.outcome='RECORDING'
            $receipt.native_state=$state
            $receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
            Write-Output ('OBSERVER_READY ' + $receipt.ready_utc)
            $pending=''; $skipLongLine=$false; $terminal=$false
            $buffer=New-Object char[] 4096
            while (!$terminal) {
                $state=$controller.Snapshot()
                if ($state.StopAttempted -or $state.DeadlineReached -or $state.ElapsedSeconds -ge 60) {
                    $receipt.outcome=$(if ($state.DeadlineReached -or $state.ElapsedSeconds -ge 60) {'TIME_BOUND_REACHED'} else {'RECORDER_STOPPED_EARLY'})
                    break
                }
                $count=$reader.Read($buffer,0,$buffer.Length)
                if ($count -eq 0) { Start-Sleep -Milliseconds 100; continue }
                $chunk=-join $buffer[0..($count-1)]
                $parts=($pending + $chunk) -split "`n"
                for ($i=0; $i -lt $parts.Count-1; $i++) {
                    if ($i -eq 0 -and $skipLongLine) { $skipLongLine=$false; continue }
                    $line=$parts[$i].TrimEnd([char]13)
                    if ($line.Length -le 4096 -and
                        $line -match '^\d{4}-\d\d-\d\dT\S+ (info|warning|error) \[AppServerConnection\] mcp_server_startup_status_updated ' -and
                        $line -match '(?:^| )server=codedb-codedbtest-1(?= |$)') {
                        $receipt.host_events+= $line
                        if ($line -match '(?:^| )status=(failed|ready|completed)(?= |$)') { $terminal=$true; break }
                        if ($receipt.host_events.Count -ge 20) { throw 'Host event limit exceeded; stop without retry' }
                    }
                }
                if ($parts.Count -gt 1) { $skipLongLine=$false }
                $pending=$parts[-1]
                if ($skipLongLine -or $pending.Length -gt 4096) { $pending=''; $skipLongLine=$true }
            }
            if ($terminal) { $receipt.outcome='TARGET_HOST_TERMINAL_EVENT' }
        }
    } catch {
        $receipt.outcome='OBSERVER_ERROR'; $receipt.exception=$_.Exception.Message
        Write-Output ('OBSERVER_EXCEPTION ' + $receipt.exception)
    } finally {
        if ($null -ne $controller) {
            try { $controller.Finish() } catch { $receipt.exception=$_.Exception.Message }
            $receipt.native_state=$controller.Snapshot()
            $receipt.cleanup_status=Get-S39CleanupStatus $receipt.native_state
        }
        if ($null -ne $reader) { $reader.Dispose() }
        $receipt.ended_utc=[DateTime]::UtcNow.ToString('o')
        try {
            $receipt.after=@(Read-S39InputHashes $ProjectRoot)
            $receipt.input_hashes_unchanged=(($receipt.before | ConvertTo-Json -Compress) -ceq ($receipt.after | ConvertTo-Json -Compress))
        } catch { $receipt.exception='Final input hash read failed: ' + $_.Exception.Message }
        $receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
        Write-Output ('OBSERVER_ENDED ' + $receipt.outcome + ' / ' + $receipt.cleanup_status)
    }
}
