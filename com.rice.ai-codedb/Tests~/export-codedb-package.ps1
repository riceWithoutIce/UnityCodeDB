#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Commit,
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [Parameter(DontShow = $true)][switch]$LoadFunctionsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Assert-Export {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)
    if (-not $Condition) { throw $Message }
}

function Invoke-PackageClosureValidator {
    param(
        [Parameter(Mandatory = $true)][string]$ValidatorPath,
        [Parameter(Mandatory = $true)][string]$PackagePath,
        [Parameter(Mandatory = $true)][string]$Label
    )
    Assert-Export (Test-Path -LiteralPath $ValidatorPath -PathType Leaf) "$Label validator is missing from the Package."
    & powershell -NoProfile -ExecutionPolicy Bypass -File $ValidatorPath -PackageRoot $PackagePath
    if ($LASTEXITCODE -ne 0) { throw "$Label closure validation failed with exit code $LASTEXITCODE." }
}

function New-DeterministicPackageZip {
    param(
        [Parameter(Mandatory = $true)][string]$PackagePath,
        [Parameter(Mandatory = $true)][string]$ArchivePath
    )
    Add-Type -AssemblyName System.IO.Compression
    $relativePaths = [string[]]@(
        Get-ChildItem -LiteralPath $PackagePath -Recurse -File | ForEach-Object {
            $_.FullName.Substring($PackagePath.Length + 1).Replace('\', '/')
        }
    )
    [Array]::Sort($relativePaths, [StringComparer]::Ordinal)
    $fixedTimestamp = [DateTimeOffset]::ParseExact(
        "1980-01-01T00:00:00+00:00",
        "yyyy-MM-dd'T'HH:mm:sszzz",
        [Globalization.CultureInfo]::InvariantCulture)
    $archiveStream = [IO.File]::Open($ArchivePath, [IO.FileMode]::CreateNew, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $archive = New-Object IO.Compression.ZipArchive($archiveStream, [IO.Compression.ZipArchiveMode]::Create, $true)
        try {
            foreach ($relativePath in $relativePaths) {
                $entry = $archive.CreateEntry(
                    "com.rice.ai-codedb/$relativePath",
                    [IO.Compression.CompressionLevel]::Optimal)
                $entry.LastWriteTime = $fixedTimestamp
                $sourcePath = Join-Path $PackagePath ($relativePath.Replace('/', '\'))
                $source = [IO.File]::Open($sourcePath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
                try {
                    $destination = $entry.Open()
                    try { $source.CopyTo($destination) } finally { $destination.Dispose() }
                } finally {
                    $source.Dispose()
                }
            }
        } finally {
            $archive.Dispose()
        }
    } finally {
        $archiveStream.Dispose()
    }
}

if ($LoadFunctionsOnly) { return }

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$output = if ([IO.Path]::IsPathRooted($OutputRoot)) {
    [IO.Path]::GetFullPath($OutputRoot)
} else {
    [IO.Path]::GetFullPath((Join-Path $repositoryRoot $OutputRoot))
}
$packageParent = Join-Path $output "package"
$packagePath = Join-Path $packageParent "com.rice.ai-codedb"
$archivePath = Join-Path $output "com.rice.ai-codedb.zip"
$tarPath = Join-Path $output "package.tar"
$reviewRoot = Join-Path $output "review"

Assert-Export (Test-Path -LiteralPath (Join-Path $repositoryRoot ".git")) "Repository root is not a Git worktree."
$resolvedCommit = (& git -C $repositoryRoot rev-parse --verify ("$Commit^{commit}") 2>$null).Trim()
Assert-Export ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($resolvedCommit)) "Commit cannot be resolved: $Commit"
Assert-Export (-not (Test-Path -LiteralPath $output)) "Output root already exists: $OutputRoot"
[IO.Directory]::CreateDirectory($output) | Out-Null

& git -C $repositoryRoot archive --format=tar --output=$tarPath $resolvedCommit -- "com.rice.ai-codedb"
if ($LASTEXITCODE -ne 0) { throw "git archive failed with exit code $LASTEXITCODE." }
[IO.Directory]::CreateDirectory($packageParent) | Out-Null
& tar -xf $tarPath -C $packageParent
if ($LASTEXITCODE -ne 0) { throw "tar extraction failed with exit code $LASTEXITCODE." }
Remove-Item -LiteralPath $tarPath -Force

$stagedValidator = Join-Path $packagePath "Tests~\test-codedb-package-release-closure.ps1"
Invoke-PackageClosureValidator -ValidatorPath $stagedValidator -PackagePath $packagePath -Label "Commit-staged Package"
New-DeterministicPackageZip -PackagePath $packagePath -ArchivePath $archivePath

[IO.Compression.ZipFile]::ExtractToDirectory($archivePath, $reviewRoot)
$reviewRoots = @(Get-ChildItem -LiteralPath $reviewRoot -Force)
Assert-Export ($reviewRoots.Count -eq 1 -and $reviewRoots[0].PSIsContainer -and $reviewRoots[0].Name -eq "com.rice.ai-codedb") `
    "Emitted ZIP does not contain exactly one com.rice.ai-codedb root."
$reviewPackagePath = $reviewRoots[0].FullName
$reviewValidator = Join-Path $reviewPackagePath "Tests~\test-codedb-package-release-closure.ps1"
Invoke-PackageClosureValidator -ValidatorPath $reviewValidator -PackagePath $reviewPackagePath -Label "Exact ZIP"

$artifactHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$files = @(Get-ChildItem -LiteralPath $reviewPackagePath -Recurse -File)
$byteCount = ($files | Measure-Object -Property Length -Sum).Sum
$zip = [IO.Compression.ZipFile]::OpenRead($archivePath)
try { $zipCount = $zip.Entries.Count } finally { $zip.Dispose() }
Write-Output ("[PACKAGE_EXPORT] PASS commit={0} root=com.rice.ai-codedb files={1} bytes={2} zip_entries={3} artifact_sha256={4}" -f $resolvedCommit, $files.Count, $byteCount, $zipCount, $artifactHash)
