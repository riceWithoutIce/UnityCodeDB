param([switch] $Execute)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path.TrimEnd('\')
$artifactRoot = Join-Path $repoRoot '.artifacts'
$backupRoot = Join-Path $repoRoot '.backups'
$inventoryPath = Join-Path $artifactRoot 'maintenance/artifact-retention-review-20261020/review-candidates.json'
$backupLedgerPath = Join-Path $PSScriptRoot 'BACKUP-CANDIDATES-SHA256.txt'
$executionLog = Join-Path $PSScriptRoot 'CLEANUP-BATCH-01-EXECUTION.jsonl'
$inventorySha256 = '298ee842b3305ef1052a251c9f5563811086c6599a5de2dc273744bf944dbf28'
$ledgerSha256 = 'fb5c2610c1dcdd2694e4b7c6416a821a23dee74cbcc05c7df3153e7368dbdbd9'
$comparison = [StringComparison]::OrdinalIgnoreCase

function Assert-ContainedDirectory([string] $relative, [string] $storageRoot) {
    $full = [IO.Path]::GetFullPath((Join-Path $repoRoot $relative.Replace('/', '\')))
    if (-not $full.StartsWith($storageRoot.TrimEnd('\') + '\', $comparison)) {
        throw "Target escapes storage root: $relative"
    }
    if (-not (Test-Path -LiteralPath $full -PathType Container)) {
        throw "Missing target directory: $relative"
    }
    $cursor = $full
    while ($cursor.Length -ge $repoRoot.Length) {
        if (-not $cursor.StartsWith($repoRoot, $comparison)) {
            throw "Target ancestor escapes repository: $relative"
        }
        if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Reparse ancestor: $cursor"
        }
        if ($cursor.Equals($repoRoot, $comparison)) { break }
        $cursor = Split-Path -Parent $cursor
    }
    $nested = @(Get-ChildItem -LiteralPath $full -Recurse -Force -Attributes ReparsePoint)
    if ($nested.Count -ne 0) { throw "Reparse entry inside: $relative" }
    $gitEntries = @(Get-ChildItem -LiteralPath $full -Recurse -Force | Where-Object Name -Eq '.git')
    if ($gitEntries.Count -ne 0) { throw "Nested Git state inside: $relative" }
    return $full
}

function Assert-AvailableFiles([IO.FileInfo[]] $files) {
    foreach ($file in $files) {
        $stream = [IO.File]::Open($file.FullName, [IO.FileMode]::Open,
            [IO.FileAccess]::Read, [IO.FileShare]::None)
        $stream.Dispose()
    }
}

function Get-JsonStrings($value) {
    if ($value -is [string]) { return ,$value }
    if ($value -is [System.Collections.IDictionary]) {
        foreach ($child in $value.Values) { Get-JsonStrings $child }
        return
    }
    if ($value -is [System.Collections.IEnumerable]) {
        foreach ($child in $value) { Get-JsonStrings $child }
    }
}

if ((Get-FileHash -LiteralPath $inventoryPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $inventorySha256) {
    throw 'Test inventory identity changed'
}
if ((Get-FileHash -LiteralPath $backupLedgerPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ledgerSha256) {
    throw 'Backup candidate ledger identity changed'
}
$inventory = Get-Content -LiteralPath $inventoryPath -Raw | ConvertFrom-Json
$backupLines = @(Get-Content -LiteralPath $backupLedgerPath | Where-Object { $_ -and -not $_.StartsWith('#') })
if ($inventory.candidates.Count -ne 9 -or $backupLines.Count -ne 18) {
    throw 'Candidate count changed'
}

$targets = @()
foreach ($candidate in $inventory.candidates) {
    $relative = $candidate.source_root.TrimEnd('/')
    $full = Assert-ContainedDirectory $relative $artifactRoot
    $files = @(Get-ChildItem -LiteralPath $full -File -Recurse -Force)
    $expected = @{}
    foreach ($entry in $candidate.files) {
        if (-not $entry.source_path.StartsWith($candidate.source_root, [StringComparison]::Ordinal)) {
            throw "Invalid inventory path: $($entry.source_path)"
        }
        $name = $entry.source_path.Substring($candidate.source_root.Length)
        if ($expected.ContainsKey($name)) { throw "Duplicate inventory path: $name" }
        $expected[$name] = $entry
    }
    if ($files.Count -ne $candidate.file_count -or $expected.Count -ne $files.Count) {
        throw "File count changed: $relative"
    }
    $bytes = [long] 0
    foreach ($file in $files) {
        $name = $file.FullName.Substring($full.Length + 1).Replace('\', '/')
        if (-not $expected.ContainsKey($name)) { throw "Unlisted file: $relative/$name" }
        $entry = $expected[$name]
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($file.Length -ne $entry.bytes -or $hash -ne $entry.sha256) {
            throw "File identity changed: $relative/$name"
        }
        $bytes += $file.Length
    }
    Assert-AvailableFiles $files
    $targets += [pscustomobject]@{ Relative = $relative; Full = $full; Files = $files.Count; Bytes = $bytes }
}

$backupNames = @{}
foreach ($line in $backupLines) {
    $parts = $line -split ' ', 2
    if ($parts.Count -ne 2 -or $parts[0] -notmatch '^s29-[a-z0-9-]+$' -or
        $parts[1] -notmatch '^[0-9a-f]{64}$' -or $backupNames.ContainsKey($parts[0])) {
        throw "Invalid backup ledger line: $line"
    }
    $backupNames[$parts[0]] = $true
    $relative = ".backups/$($parts[0])"
    $full = Assert-ContainedDirectory $relative $backupRoot
    $files = @(Get-ChildItem -LiteralPath $full -File -Recurse -Force)
    if ($files.Count -ne 2 -or
        (@($files.Name | Sort-Object) -join ',') -ne 'manifest.json,packages-lock.json') {
        throw "Backup file set changed: $relative"
    }
    $hashLines = @($files | ForEach-Object {
        $_.Name + "`t" + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    })
    [Array]::Sort($hashLines, [StringComparer]::Ordinal)
    $treeHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes(($hashLines -join "`n") + "`n"))).ToLowerInvariant()
    if ($treeHash -ne $parts[1]) { throw "Backup identity changed: $relative" }
    Assert-AvailableFiles $files
    $targets += [pscustomobject]@{
        Relative = $relative
        Full = $full
        Files = $files.Count
        Bytes = [long] ($files | Measure-Object Length -Sum).Sum
    }
}

$actualS29Names = @(Get-ChildItem -LiteralPath $backupRoot -Directory -Force |
    Where-Object Name -Like 's29-*' | Select-Object -ExpandProperty Name)
if ($actualS29Names.Count -ne $backupNames.Count -or
    @($actualS29Names | Where-Object { -not $backupNames.ContainsKey($_) }).Count -ne 0) {
    throw 'S29 backup directory set changed'
}
if ($targets.Count -ne 27 -or
    ($targets | Measure-Object Files -Sum).Sum -ne 1269 -or
    ($targets | Measure-Object Bytes -Sum).Sum -ne 113787705) {
    throw 'Batch totals changed'
}
if (Test-Path -LiteralPath 'UnityFreshInstallValidationProjectS29') {
    throw 'S29 validation project unexpectedly exists'
}

$projects = @(Get-ChildItem -LiteralPath $repoRoot -Directory -Force |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'Packages/manifest.json') })
$s35 = Join-Path $artifactRoot 'unity-projects/s35'
if (Test-Path -LiteralPath (Join-Path $s35 'Packages/manifest.json')) {
    $projects += Get-Item -LiteralPath $s35
}
foreach ($project in $projects) {
    foreach ($name in @('manifest.json', 'packages-lock.json')) {
        $config = Join-Path $project.FullName "Packages/$name"
        if (-not (Test-Path -LiteralPath $config -PathType Leaf)) { continue }
        $strings = @(Get-JsonStrings (Get-Content -LiteralPath $config -Raw | ConvertFrom-Json -AsHashtable))
        foreach ($value in $strings) {
            foreach ($target in $targets) {
                if ($value.Replace('\', '/').IndexOf($target.Relative, $comparison) -ge 0) {
                    throw "Active Package config references candidate: $config -> $($target.Relative)"
                }
            }
        }
    }
}

$processes = @(Get-CimInstance Win32_Process)
foreach ($process in $processes) {
    if (-not $process.CommandLine) { continue }
    foreach ($target in $targets) {
        if ($process.CommandLine.IndexOf($target.Full, $comparison) -ge 0 -or
            $process.CommandLine.Replace('\', '/').IndexOf($target.Relative, $comparison) -ge 0) {
            throw "Process $($process.ProcessId) references candidate: $($target.Relative)"
        }
    }
}

$totalBytes = ($targets | Measure-Object Bytes -Sum).Sum
Write-Output "PREFLIGHT PASS: $($targets.Count) exact children; 1269 files; $totalBytes bytes; $($projects.Count) Package projects checked"
if (-not $Execute) { return }
if (Test-Path -LiteralPath $executionLog) { throw 'Execution log already exists' }

$encoding = [Text.UTF8Encoding]::new($false)
function Add-Event($event) {
    [IO.File]::AppendAllText($executionLog, ($event | ConvertTo-Json -Compress) + "`n", $encoding)
}
Add-Event ([ordered]@{ event = 'preflight'; utc = [DateTime]::UtcNow.ToString('o'); targets = 27; files = 1269; bytes = 113787705 })
foreach ($target in $targets) {
    Remove-Item -LiteralPath $target.Full -Recurse -Force -ErrorAction Stop
    if (Test-Path -LiteralPath $target.Full) { throw "Target remains after removal: $($target.Relative)" }
    Add-Event ([ordered]@{ event = 'removed'; utc = [DateTime]::UtcNow.ToString('o'); path = $target.Relative; files = $target.Files; bytes = $target.Bytes })
    Write-Output "REMOVED $($target.Relative) $($target.Files) $($target.Bytes)"
}
Add-Event ([ordered]@{ event = 'complete'; utc = [DateTime]::UtcNow.ToString('o'); targets = 27; files = 1269; bytes = 113787705 })
Write-Output 'CLEANUP COMPLETE'
