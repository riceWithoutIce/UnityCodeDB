#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context

$providerPaths = Get-ProjectCodedbProviderPaths -Context $context
$relativeProviderFolder = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderBinRoot
$relativeExecutable = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ExecutablePath
$relativeRuntime = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderRoot

Write-Host "codedb provider preparation guidance"
Write-Host ""
Write-Host "Provider:"
Write-Host "- Current external provider: killop/codedb-mcp / codebase-mcp."
Write-Host "- Expected Windows executable name: codebase-mcp.exe."
Write-Host "- Target folder: $relativeProviderFolder"
Write-Host "- Target file: $relativeExecutable"
Write-Host ""
Write-Host "Policy:"
Write-Host "- The provider executable is an external dependency."
Write-Host "- This project does not vendor, download, or commit the provider binary in this flow."
Write-Host "- Keep provider binaries, logs, indexes, and generated runtime files under ignored runtime: $relativeRuntime"
Write-Host "- Do not store local absolute paths in tracked files."
Write-Host "- Do not write user/global MCP client configuration from this setup flow."
Write-Host ""
if (Test-Path -LiteralPath $providerPaths.ExecutablePath -PathType Leaf) {
    Write-Host "[OK] Provider executable exists at $relativeExecutable."
} else {
    Write-Host "[NO HIT] Provider executable is missing at $relativeExecutable. Place the reviewed codebase-mcp.exe there, then run Verify Runtime."
}

exit 0
