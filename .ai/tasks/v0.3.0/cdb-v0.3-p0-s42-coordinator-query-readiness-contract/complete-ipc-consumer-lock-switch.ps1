#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ProjectRoot, [switch]$ExecuteApproved)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$project = [IO.Path]::GetFullPath($ProjectRoot)
if ([IO.Path]::GetFileName($project.TrimEnd('\','/')) -cne 'CodedbTest_2') { throw 'Wrong project' }
$run = Join-Path $repo '.artifacts/tests/s42-ipc-consumer-switch-c53e181/execution-a'
$backup = Join-Path $repo '.backups/s42-ipc-consumer-switch-c53e181'
$old = 'file:../../Packages/4589249-s42-codedbtest2/com.rice.ai-codedb'
$new = 'file:../../Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb'
$destination = Join-Path (Split-Path $project -Parent) 'Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb'
$expected = Get-Content (Join-Path $repo '.artifacts/tests/s42-ipc-commit-export/execution-a/exact-inventory.json') -Raw | ConvertFrom-Json
function Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function EqualBytes([byte[]]$a,[byte[]]$b) { [Convert]::ToBase64String($a) -ceq [Convert]::ToBase64String($b) }
function Replacement([byte[]]$bytes) {
    $needle = [Text.Encoding]::UTF8.GetBytes($old)
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    if ([regex]::Matches($text,[regex]::Escape($old)).Count -ne 1) { throw 'Reference not unique' }
    $updated = [Text.Encoding]::UTF8.GetBytes($text.Replace($old,$new))
    $null = [Text.Encoding]::UTF8.GetString($updated).TrimStart([char]0xfeff) | ConvertFrom-Json
    return ,$updated
}
function CheckClosed {
    foreach ($relative in @('Library/UnityLockfile','Temp/UnityLockfile')) {
        if (Test-Path -LiteralPath (Join-Path $project $relative)) { throw 'Unity lock appeared' }
    }
}
CheckClosed
$manifest = Join-Path $project 'Packages/manifest.json'
$lock = Join-Path $project 'Packages/packages-lock.json'
$originalManifest = [IO.File]::ReadAllBytes((Join-Path $backup 'manifest.json'))
$originalLock = [IO.File]::ReadAllBytes((Join-Path $backup 'packages-lock.json'))
if ((Hash (Join-Path $backup 'manifest.json')) -cne '003e58e939b2a63e6ae9d8174e4d7ef5b054c6942e0f2e15f79ecd9865426f2f' -or
    (Hash (Join-Path $backup 'packages-lock.json')) -cne 'b2b7e48cdb5b8316c1873a88e1ab60ad9fbee569e30eb11864863639bc4f0f39') { throw 'Backup drift' }
$newManifest = Replacement $originalManifest
$newLock = Replacement $originalLock
if (-not (EqualBytes ([IO.File]::ReadAllBytes($manifest)) $newManifest)) { throw 'Manifest no longer exact partial result' }
if (-not (EqualBytes ([IO.File]::ReadAllBytes($lock)) $originalLock)) { throw 'Lock no longer original' }
if ($expected.Count -ne 667 -or @(Get-ChildItem -LiteralPath $destination -Recurse -File).Count -ne 667) { throw 'Package inventory size drift' }
foreach ($entry in $expected) {
    if ((Hash (Join-Path $destination $entry.path)) -cne $entry.sha256) { throw 'Package byte drift' }
}
$protected = [ordered]@{
    'AIWork/.runtime/codedb/control/current-instance.json'='1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a'
    'Assets/CodeDBValidation/CodeDBQueryProbe.cs'='d96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432'
    'Assets/CodeDBValidation/CodeDBQueryProbe.cs.meta'='2c61d4f1fb1059d53533dcb62ed6613d525ed32e348858f68e725b0a81299149'
    'Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs'='496ebae5e49d4970a938632b289701427e8d93d90572ea64be67650d747c47cc'
    'Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs.meta'='a5c854525ce471b9a445f015decceb026b4bf0f82a3a84045fd12d695c2dba68'
}
function CheckProtected {
    foreach ($relative in $protected.Keys) {
        if ((Hash (Join-Path $project $relative)) -cne $protected[$relative]) { throw 'Protected byte drift' }
    }
}
CheckProtected
$receiptPath = Join-Path $run 'lock-completion-result.json'
if (Test-Path -LiteralPath $receiptPath) { throw 'Completion already attempted' }
if (-not $ExecuteApproved) { 'READ_ONLY_PREFLIGHT_PASS; no project writes'; return }
$result = [ordered]@{status='STARTED';started_at_utc=[DateTime]::UtcNow.ToString('o');writes=0;package_files=667;new_reference=$new;manifest_rewritten=$false}
try {
    CheckClosed
    CheckProtected
    if (-not (EqualBytes ([IO.File]::ReadAllBytes($lock)) $originalLock)) { throw 'Lock drift before write' }
    [IO.File]::WriteAllBytes($lock,$newLock)
    $result.writes = 1
    if (-not (EqualBytes ([IO.File]::ReadAllBytes($lock)) $newLock)) { throw 'Lock write mismatch' }
    if (-not (EqualBytes ([IO.File]::ReadAllBytes($manifest)) $newManifest)) { throw 'Manifest drift after lock write' }
    CheckProtected
    CheckClosed
    $result.status = 'CONSUMER_REFERENCE_SWITCH_PASS_NOT_REOPENED'
    $result.manifest_sha256 = Hash $manifest
    $result.lock_sha256 = Hash $lock
} catch {
    $result.status = 'STOPPED_NO_REPLAY'
    $result.error_type = $_.Exception.GetType().Name
    throw
} finally {
    $result.ended_at_utc = [DateTime]::UtcNow.ToString('o')
    [IO.File]::WriteAllText($receiptPath,($result | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
}
$result | ConvertTo-Json -Depth 5
