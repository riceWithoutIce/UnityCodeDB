param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [Parameter(Mandatory=$true)][string]$SessionName,
    [Parameter(Mandatory=$true)][string]$DesktopLog
)
$ErrorActionPreference = 'Stop'
# Logman returns PLA_E_DCS_NOT_FOUND regardless of UI language/output encoding.
$sessionNotFoundExitCode = -2144337918 # 0x80300002
if ($SessionName -notmatch '^CodeDB-S39-[a-f0-9]{32}$') { throw 'Invalid owned session name' }
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$allowedRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.artifacts/tests/s39-process-observation'))
$destination = [IO.Path]::GetFullPath($EvidenceRoot)
if (!$destination.StartsWith($allowedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Evidence outside owned root' }
if (Test-Path -LiteralPath $destination) { throw 'Evidence destination already exists' }
for ($ancestor = $destination; $ancestor; $ancestor = Split-Path $ancestor -Parent) {
    if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse ancestor rejected' }
}
New-Item -ItemType Directory -Path $destination | Out-Null
$receiptPath = Join-Path $destination 'receipt.json'
$tracePath = Join-Path $destination 'process.etl'
$receipt = [ordered]@{
    session = $SessionName; status = 'PREPARED'; started_utc = $null; ended_utc = $null
    provider = '22fb2cd6-0e7b-422b-a0c7-2fad1fd0e716'; keyword = '0x10'
    raw_scope = 'system-wide process metadata only'; max_seconds = 60; max_mib = 16
    start_exit_code = $null; start_output = $null; stop_exit_code = $null; stop_output = $null
    initial_query_exit_code = $null; initial_query_output = $null
    cleanup_query_exit_code = $null; cleanup_query_output = $null
    final_query_exit_code = $null; final_query_output = $null
    host_events = @(); before = @(); after = @(); exception = $null
}
function Save-Receipt { $receipt | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $receiptPath -Encoding UTF8 }
function Read-InputHashes {
    @('.codex/config.toml','Packages/manifest.json','Packages/packages-lock.json',
      'AIWork/.runtime/codedb/control/current-instance.json','AIWork/codedb/wrapper/codedb-project-wrapper.mjs') | ForEach-Object {
        $inputPath = Join-Path $ProjectRoot $_
        [pscustomobject]@{ relative_path = $_; sha256 = (Get-FileHash -LiteralPath $inputPath -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
}
$owned = $false
$startAttempted = $false
$reader = $null
try {
    $initialQuery = & logman query $SessionName -ets 2>&1
    $receipt.initial_query_exit_code = $LASTEXITCODE
    $receipt.initial_query_output = ($initialQuery -join "`n")
    if ($LASTEXITCODE -eq 0) { throw 'Session already exists; ownership not established' }
    if ($LASTEXITCODE -ne $sessionNotFoundExitCode) { throw 'Cannot establish absent session; no start attempted' }
    $receipt.before = @(Read-InputHashes)
    $stream = [IO.File]::Open($DesktopLog,[IO.FileMode]::Open,[IO.FileAccess]::Read,([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
    [void]$stream.Seek(0,[IO.SeekOrigin]::End)
    $reader = New-Object IO.StreamReader($stream)
    $startAttempted = $true
    $timer = [Diagnostics.Stopwatch]::StartNew()
    $startOutput = & logman create trace $SessionName -p '{22fb2cd6-0e7b-422b-a0c7-2fad1fd0e716}' 0x10 5 -o $tracePath -f bincirc -max 16 -ct system -ets 2>&1
    $receipt.start_exit_code = $LASTEXITCODE
    $receipt.start_output = ($startOutput -join "`n")
    if ($receipt.start_exit_code -ne 0) {
        $receipt.status = 'START_FAILED_NO_RETRY'
        Write-Output ('OBSERVER_START_FAILED ' + $receipt.start_output)
    } else {
        $owned = $true
        $receipt.started_utc = [DateTime]::UtcNow.ToString('o')
        $receipt.status = 'RECORDING'
        Save-Receipt
        Write-Output ('OBSERVER_READY ' + $receipt.started_utc)
        $terminal = $false
        while ($timer.Elapsed.TotalSeconds -lt 60 -and !$terminal) {
            $line = $reader.ReadLine()
            if ($null -eq $line) { Start-Sleep -Milliseconds 200; continue }
            if ($line -match '^\d{4}-\d\d-\d\dT\S+ (info|warning|error) \[AppServerConnection\] mcp_server_startup_status_updated ' -and
                $line -match ' server=codedb-codedbtest-1 ' -and $line.Length -le 4096) {
                $receipt.host_events += $line
                if ($line -match ' status=(failed|ready|completed) ') { $terminal = $true }
            }
        }
        $receipt.status = $(if ($terminal) { 'TARGET_HOST_TERMINAL_EVENT' } else { 'TIME_BOUND_REACHED' })
    }
} catch {
    $receipt.exception = $_.Exception.Message
    $receipt.status = 'OBSERVER_ERROR'
    Write-Output ('OBSERVER_EXCEPTION ' + $receipt.exception)
} finally {
    # A nonzero create result can leave a live session after provider enable fails.
    # Query the unique, previously absent name and exact owned output before cleanup.
    if ($startAttempted -and !$owned) {
        $cleanupQuery = & logman query $SessionName -ets 2>&1
        $receipt.cleanup_query_exit_code = $LASTEXITCODE
        $receipt.cleanup_query_output = ($cleanupQuery -join "`n")
        if ($LASTEXITCODE -eq 0 -and $receipt.cleanup_query_output.Contains($tracePath.Replace('/','\'))) {
            $owned = $true
            $receipt.status = 'PARTIAL_START_FAILED_CLEANUP_REQUIRED'
        } elseif ($LASTEXITCODE -ne $sessionNotFoundExitCode) {
            $receipt.status = 'PARTIAL_SESSION_STATE_UNCONFIRMED'
        }
    }
    if ($owned) {
        $stopOutput = & logman stop $SessionName -ets 2>&1
        $receipt.stop_exit_code = $LASTEXITCODE
        $receipt.stop_output = ($stopOutput -join "`n")
        if ($receipt.stop_exit_code -ne 0) { $receipt.status = 'OWNED_RECORDER_STOP_FAILED' }
        $finalQuery = & logman query $SessionName -ets 2>&1
        $receipt.final_query_exit_code = $LASTEXITCODE
        $receipt.final_query_output = ($finalQuery -join "`n")
        if ($receipt.stop_exit_code -eq 0 -and $receipt.final_query_exit_code -ne $sessionNotFoundExitCode) {
            $receipt.status = 'RECORDER_ABSENCE_NOT_CONFIRMED'
        } elseif ($receipt.stop_exit_code -eq 0 -and $receipt.status -eq 'PARTIAL_START_FAILED_CLEANUP_REQUIRED') {
            $receipt.status = 'PARTIAL_START_FAILED_CLEANED'
        }
    }
    if ($null -ne $reader) { $reader.Dispose() }
    $receipt.ended_utc = [DateTime]::UtcNow.ToString('o')
    try { $receipt.after = @(Read-InputHashes) } catch { $receipt.exception = 'Final input hash read failed: ' + $_.Exception.Message }
    Save-Receipt
    Write-Output ('OBSERVER_ENDED ' + $receipt.status)
}
