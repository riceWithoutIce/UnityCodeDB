#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context

$prerequisite = Get-CodedbMachinePrerequisiteStatus -PackageVersion $script:CodedbHostPackageVersion
$expectedProviderFolder = if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
    "%LOCALAPPDATA%\Rice\CodeDB\providers\0.5.0"
} else {
    Join-Path $env:LOCALAPPDATA "Rice\CodeDB\providers\0.5.0"
}
$expectedExecutable = Join-Path $expectedProviderFolder "codebase-mcp.exe"
$relativeRuntime = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderRoot

Write-Host "codedb provider preparation guidance"
Write-Host ""
Write-Host "Provider:"
Write-Host "- Required Provider: killop/codedb-mcp 0.5.0."
Write-Host "- Required protocol: codedb-cli-v1."
Write-Host "- Machine folder: $expectedProviderFolder"
Write-Host "- Machine executable: $expectedExecutable"
Write-Host ""
Write-Host "Policy:"
Write-Host "- The provider executable is an external dependency."
Write-Host "- This project does not vendor, download, or commit the provider binary in this flow."
Write-Host "- Keep Provider binaries in the machine folder; project config, logs, indexes, and generated runtime stay under ignored runtime: $relativeRuntime"
Write-Host "- Do not store local absolute paths in tracked files."
Write-Host "- Do not write user/global MCP client configuration from this setup flow."
Write-Host ""
if ($prerequisite.Current) {
    Write-Host "[OK] $($prerequisite.Detail)"
} else {
    Write-Host "[MISSING_PREREQUISITE] $($prerequisite.Detail)"
}

exit 0
