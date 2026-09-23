#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Commit,
    [Parameter(Mandatory = $true)][string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$output = if ([IO.Path]::IsPathRooted($OutputRoot)) {
    [IO.Path]::GetFullPath($OutputRoot)
} else {
    [IO.Path]::GetFullPath((Join-Path $repositoryRoot $OutputRoot))
}
$packagePath = Join-Path $output "package\com.rice.ai-codedb"
$archivePath = Join-Path $output "com.rice.ai-codedb.zip"
$tarPath = Join-Path $output "package.tar"
$validator = Join-Path $PSScriptRoot "test-codedb-package-release-closure.ps1"

if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot ".git"))) { throw "Repository root is not a Git worktree." }
$resolvedCommit = (& git -C $repositoryRoot rev-parse --verify ("$Commit^{commit}") 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resolvedCommit)) { throw "Commit cannot be resolved: $Commit" }

if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Recurse -Force }
[IO.Directory]::CreateDirectory($output) | Out-Null

& git -C $repositoryRoot archive --format=tar --output=$tarPath $resolvedCommit -- "com.rice.ai-codedb"
if ($LASTEXITCODE -ne 0) { throw "git archive failed with exit code $LASTEXITCODE." }
[IO.Directory]::CreateDirectory((Join-Path $output "package")) | Out-Null
& tar -xf $tarPath -C (Join-Path $output "package")
if ($LASTEXITCODE -ne 0) { throw "tar extraction failed with exit code $LASTEXITCODE." }
Remove-Item -LiteralPath $tarPath -Force

# The source metadata are generated artifacts. Canonicalize them in the
# exported tree before validation so the archive and its declared hashes use
# one byte representation.
& powershell -NoProfile -ExecutionPolicy Bypass -File $validator -PackageRoot $packagePath -RepairCanonicalMetadata
if ($LASTEXITCODE -ne 0) { throw "Canonical package closure repair failed with exit code $LASTEXITCODE." }

$zipParent = Join-Path $output "package"
Compress-Archive -LiteralPath $packagePath -DestinationPath $archivePath -CompressionLevel Optimal
$artifactHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
$fileCount = @(Get-ChildItem -LiteralPath $packagePath -Recurse -File).Count
$byteCount = (Get-ChildItem -LiteralPath $packagePath -Recurse -File | Measure-Object -Property Length -Sum).Sum
$zipCount = @(tar -tf $archivePath).Count
Write-Output ("[PACKAGE_EXPORT] PASS commit={0} files={1} bytes={2} zip_entries={3} artifact_sha256={4}" -f $resolvedCommit, $fileCount, $byteCount, $zipCount, $artifactHash)
