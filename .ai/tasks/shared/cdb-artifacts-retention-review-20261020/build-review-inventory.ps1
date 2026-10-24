$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$testsRoot = Join-Path $repoRoot '.artifacts/tests'
$outputRoot = Join-Path $repoRoot '.artifacts/maintenance/artifact-retention-review-20261020'
$outputPath = Join-Path $outputRoot 'review-candidates.json'

$candidates = @(
    @{ Source = 's31d-uninstall-terminal/attempt-b'; Retained = 's31d-uninstall-terminal/attempt-c'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s31d-uninstall-terminal-session-closure/RESULT.md' }
    @{ Source = 's32-install/c'; Retained = 's32-install/frozen'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md' }
    @{ Source = 's32-install/final'; Retained = 's32-install/frozen'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md' }
    @{ Source = 's32-install/final-2'; Retained = 's32-install/frozen'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md' }
    @{ Source = 's32-install/repair-a'; Retained = 's32-install/repair-e'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md' }
    @{ Source = 's32-install/repair-c'; Retained = 's32-install/repair-e'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md' }
    @{ Source = 's32-install/repair-d'; Retained = 's32-install/repair-e'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s32-install-project-command-closure/RESULT.md' }
    @{ Source = 's29-removal-namespace/scenario-a2'; Retained = 's29-removal-namespace/scenario-a4'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/REMOVAL-PREFLIGHT-NAMESPACE-CONTRACT-RESULT.md' }
    @{ Source = 's29-removal-namespace/scenario-a3'; Retained = 's29-removal-namespace/scenario-a4'; Record = '.ai/tasks/v0.3.0/cdb-v0.3-p0-s29-fresh-project-integration-golden-path/REMOVAL-PREFLIGHT-NAMESPACE-CONTRACT-RESULT.md' }
)

function Get-Inventory([string] $relativeRoot) {
    $absoluteRoot = Join-Path $testsRoot $relativeRoot
    if (-not (Test-Path -LiteralPath $absoluteRoot -PathType Container)) {
        throw "Missing inventory root: $relativeRoot"
    }
    if ((Get-Item -LiteralPath $absoluteRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Reparse root: $relativeRoot"
    }
    $reparse = Get-ChildItem -LiteralPath $absoluteRoot -Recurse -Force -Attributes ReparsePoint | Select-Object -First 1
    if ($reparse) {
        throw "Reparse child under: $relativeRoot"
    }

    $files = @()
    $byPath = @{}
    $byHash = @{}
    $lines = @()
    foreach ($file in (Get-ChildItem -LiteralPath $absoluteRoot -File -Recurse -Force | Sort-Object FullName -CaseSensitive)) {
        $relativePath = $file.FullName.Substring($absoluteRoot.Length + 1).Replace([IO.Path]::DirectorySeparatorChar, '/')
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $entry = [pscustomobject]@{ relative_path = $relativePath; sha256 = $hash; bytes = [long] $file.Length }
        $files += $entry
        $byPath[$relativePath] = $entry
        if (-not $byHash.ContainsKey($hash)) { $byHash[$hash] = @() }
        $byHash[$hash] += $relativePath
        $lines += "$relativePath`t$hash"
    }
    [Array]::Sort($lines, [StringComparer]::Ordinal)
    $canonical = ($lines -join "`n") + "`n"
    $treeHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($canonical))).ToLowerInvariant()
    return [pscustomobject]@{ Files = $files; ByPath = $byPath; ByHash = $byHash; TreeHash = $treeHash }
}

if (Test-Path -LiteralPath $outputPath) {
    throw "Refusing to overwrite existing inventory: $outputPath"
}

$cache = @{}
$results = @()
foreach ($candidate in $candidates) {
    foreach ($root in @($candidate.Source, $candidate.Retained)) {
        if (-not $cache.ContainsKey($root)) { $cache[$root] = Get-Inventory $root }
    }
    $source = $cache[$candidate.Source]
    $retained = $cache[$candidate.Retained]
    $fileMappings = @()
    $matched = 0
    $uniqueBytes = [long] 0
    foreach ($file in $source.Files) {
        $retainedPath = $null
        if ($retained.ByPath.ContainsKey($file.relative_path) -and $retained.ByPath[$file.relative_path].sha256 -eq $file.sha256) {
            $retainedPath = $file.relative_path
        } elseif ($retained.ByHash.ContainsKey($file.sha256)) {
            $matchingPaths = @($retained.ByHash[$file.sha256])
            [Array]::Sort($matchingPaths, [StringComparer]::Ordinal)
            $retainedPath = $matchingPaths[0]
        }
        if ($null -ne $retainedPath) { $matched++ } else { $uniqueBytes += $file.bytes }
        $fileMappings += [ordered]@{
            source_path = ".artifacts/tests/$($candidate.Source)/$($file.relative_path)"
            sha256 = $file.sha256
            bytes = $file.bytes
            identical_retained_path = if ($null -ne $retainedPath) { ".artifacts/tests/$($candidate.Retained)/$retainedPath" } else { $null }
        }
    }
    $results += [ordered]@{
        source_root = ".artifacts/tests/$($candidate.Source)/"
        comparison_root = ".artifacts/tests/$($candidate.Retained)/"
        task_record = $candidate.Record
        disposition = 'REVIEW_ONLY'
        source_tree_sha256 = $source.TreeHash
        comparison_tree_sha256 = $retained.TreeHash
        file_count = $source.Files.Count
        identical_content_files = $matched
        unique_to_comparison_files = $source.Files.Count - $matched
        unique_to_comparison_bytes = $uniqueBytes
        files = $fileMappings
    }
}

$inventory = [ordered]@{
    schema = 'codedb-artifact-review-inventory-v1'
    scope = 'nine previously identified REVIEW children only'
    path_hash_format = 'ordinal relative path, TAB, lowercase SHA-256, LF, final LF, UTF-8 no BOM'
    caveat = 'Identical bytes do not authorize path removal; unique files have no byte-identical counterpart in the comparison root.'
    candidates = $results
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$json = $inventory | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($outputPath, $json + "`n", [Text.UTF8Encoding]::new($false))
$written = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
if ($written.candidates.Count -ne $candidates.Count) { throw 'Inventory round-trip candidate count mismatch' }
$totalFiles = ($written.candidates | Measure-Object -Property file_count -Sum).Sum
Write-Output "Inventory: .artifacts/maintenance/artifact-retention-review-20261020/review-candidates.json"
Write-Output "Candidates: $($written.candidates.Count); file mappings: $totalFiles"
Write-Output "SHA-256: $((Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant())"
