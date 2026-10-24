#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$ProjectRoot, [switch]$ExecuteApproved)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$project = [IO.Path]::GetFullPath($ProjectRoot)
$commit = '61dcd26383c42766763eca2b885b159725b2f7dc'
$export = Join-Path $repo '.artifacts/exports/s42-ipc-compile-repair-61dcd26'
$source = Join-Path $export 'review/com.rice.ai-codedb'
$zip = Join-Path $export 'com.rice.ai-codedb.zip'
$destination = Join-Path (Split-Path $project -Parent) 'Packages/61dcd26-s42-ipc-compile-repair/com.rice.ai-codedb'
$evidence = Join-Path $repo '.artifacts/tests/s42-ipc-compile-repair-consumer/execution-a'
$backup = Join-Path $repo '.backups/s42-ipc-compile-repair-61dcd26'
$manifest = Join-Path $project 'Packages/manifest.json'
$lock = Join-Path $project 'Packages/packages-lock.json'
$old = 'file:../../Packages/c53e181-s42-ipc-diagnostics/com.rice.ai-codedb'
$new = 'file:../../Packages/61dcd26-s42-ipc-compile-repair/com.rice.ai-codedb'
$protected = [ordered]@{
    'AIWork/.runtime/codedb/control/current-instance.json' = '1637870d57dcf07c3817505ebd8516236d5af16521d4d12475463fa8bed50f1a'
    'Assets/CodeDBValidation/CodeDBQueryProbe.cs' = 'd96bc90c3f207664fa426a3ea975a19cdcbc7802a65759384607256fc62d3432'
    'Assets/CodeDBValidation/CodeDBQueryProbe.cs.meta' = '2c61d4f1fb1059d53533dcb62ed6613d525ed32e348858f68e725b0a81299149'
    'Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs' = '496ebae5e49d4970a938632b289701427e8d93d90572ea64be67650d747c47cc'
    'Assets/CodeDBValidation/CodeDBFreshnessProbeS41.cs.meta' = 'a5c854525ce471b9a445f015decceb026b4bf0f82a3a84045fd12d695c2dba68'
}
function Get-Sha256([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Equal-Bytes([byte[]]$Left, [byte[]]$Right) { [Convert]::ToBase64String($Left) -ceq [Convert]::ToBase64String($Right) }
function Assert-NoLink([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.LinkType) { throw "PATH_REDIRECTED:$Path" }
    }
}
function Assert-Protected {
    foreach ($relative in $protected.Keys) {
        if ((Get-Sha256 (Join-Path $project $relative)) -cne $protected[$relative]) { throw "PROTECTED_DRIFT:$relative" }
    }
}
function Get-Inventory([string]$Root) {
    return @(Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
        Assert-NoLink $_.FullName
        [ordered]@{ path = $_.FullName.Substring($Root.Length + 1).Replace('\', '/'); sha256 = Get-Sha256 $_.FullName; bytes = $_.Length }
    } | Sort-Object path)
}
$unityLock = (Test-Path (Join-Path $project 'Library/UnityLockfile')) -or (Test-Path (Join-Path $project 'Temp/UnityLockfile'))
if ($unityLock) { throw 'UNITY_OPEN' }
if (Test-Path $destination) { throw 'NEW_DESTINATION_EXISTS' }
if (Test-Path $evidence) { throw 'EVIDENCE_EXISTS' }
if (Test-Path $backup) { throw 'BACKUP_EXISTS' }
if ((Get-Sha256 $zip) -cne '3830edc8521788fdbed01283aec02173e5334098d35ddf51cabdd4300189f26f') { throw 'ZIP_HASH_DRIFT' }
Assert-NoLink $project; Assert-NoLink $source
[IO.Directory]::CreateDirectory($evidence) | Out-Null
$manifestBytes = [IO.File]::ReadAllBytes($manifest)
$lockBytes = [IO.File]::ReadAllBytes($lock)
$manifestText = [Text.Encoding]::UTF8.GetString($manifestBytes)
$lockText = [Text.Encoding]::UTF8.GetString($lockBytes)
if (([regex]::Matches($manifestText, [regex]::Escape($old))).Count -ne 1 -or
    ([regex]::Matches($lockText, [regex]::Escape($old))).Count -ne 1) { throw 'CURRENT_REFERENCE_PRECONDITION_FAILED' }
foreach ($relative in $protected.Keys) {
    Assert-NoLink (Join-Path $project $relative)
    if (-not (Test-Path (Join-Path $project $relative))) { throw "MISSING_PROTECTED:$relative" }
}
Assert-Protected
[IO.Directory]::CreateDirectory($backup) | Out-Null
[IO.File]::WriteAllBytes((Join-Path $backup 'manifest.json'), $manifestBytes)
[IO.File]::WriteAllBytes((Join-Path $backup 'packages-lock.json'), $lockBytes)
[IO.File]::WriteAllText((Join-Path $evidence 'preflight.json'), ([ordered]@{
    status = 'PASS'; commit = $commit; current_manifest = Get-Sha256 $manifest; current_lock = Get-Sha256 $lock
    zip = Get-Sha256 $zip; new_reference = $new
} | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
$sourceInventory = Get-Inventory $source
[IO.Directory]::CreateDirectory((Split-Path $destination -Parent)) | Out-Null
Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
$destinationInventory = Get-Inventory $destination
if (($sourceInventory | ConvertTo-Json -Depth 5) -cne ($destinationInventory | ConvertTo-Json -Depth 5)) { throw 'PACKAGE_INVENTORY_MISMATCH' }
if ($destinationInventory.Count -ne 667) { throw 'PACKAGE_FILE_COUNT_MISMATCH' }
[IO.File]::WriteAllText((Join-Path $evidence 'copied-inventory.json'), ($destinationInventory | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
$newManifest = [Text.Encoding]::UTF8.GetBytes($manifestText.Replace($old, $new))
$newLock = [Text.Encoding]::UTF8.GetBytes($lockText.Replace($old, $new))
$null = [Text.Encoding]::UTF8.GetString($newManifest).TrimStart([char]0xfeff) | ConvertFrom-Json
$null = [Text.Encoding]::UTF8.GetString($newLock).TrimStart([char]0xfeff) | ConvertFrom-Json
if (-not $ExecuteApproved) { 'READ_ONLY_PREFLIGHT_PASS; no project writes'; return }
[IO.File]::WriteAllBytes($manifest, $newManifest)
if (-not (Equal-Bytes ([IO.File]::ReadAllBytes($manifest)) $newManifest)) { throw 'MANIFEST_VERIFY_FAILED' }
[IO.File]::WriteAllBytes($lock, $newLock)
if (-not (Equal-Bytes ([IO.File]::ReadAllBytes($lock)) $newLock)) { throw 'LOCK_VERIFY_FAILED' }
Assert-Protected
$unityLock = (Test-Path (Join-Path $project 'Library/UnityLockfile')) -or (Test-Path (Join-Path $project 'Temp/UnityLockfile'))
if ($unityLock) { throw 'UNITY_LOCK_APPEARED' }
$result = [ordered]@{
    status = 'CONSUMER_REPAIR_REFERENCE_SWITCH_PASS_NOT_REOPENED'; commit = $commit; files = $destinationInventory.Count
    zip_sha256 = Get-Sha256 $zip; destination = '<external-packages>/61dcd26-s42-ipc-compile-repair/com.rice.ai-codedb'
    manifest_before = Get-Sha256 (Join-Path $backup 'manifest.json'); lock_before = Get-Sha256 (Join-Path $backup 'packages-lock.json')
    manifest_after = Get-Sha256 $manifest; lock_after = Get-Sha256 $lock; protected_unchanged = $true
    unity_operations = 0; service_operations = 0; codedb_calls = 0; completed_at_utc = [DateTime]::UtcNow.ToString('o')
}
[IO.File]::WriteAllText((Join-Path $evidence 'result.json'), ($result | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
$result | ConvertTo-Json -Depth 5
