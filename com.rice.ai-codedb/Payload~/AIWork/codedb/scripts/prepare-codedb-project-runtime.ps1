#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
New-ProjectCodedbRuntime -Context $context
Test-ProjectCodedbRuntimeFileOperations -Context $context

$providerPaths = Get-ProjectCodedbProviderPaths -Context $context
$relativeRuntime = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderRoot
$relativeConfig = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ConfigPath
$relativeTemplate = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.RuntimeConfigTemplatePath

if ((Test-Path -LiteralPath $providerPaths.ConfigPath) -and -not $Force) {
    Write-Host "OK: Runtime directories exist at $relativeRuntime."
    Write-Host "OK: Runtime create/rename/delete probe passed."
    Write-Host "OK: Runtime config already exists at $relativeConfig. Use -Force to regenerate it from $relativeTemplate."
    Write-Host "[OK] Runtime config is ready at $relativeConfig."
    exit 0
}

$configPath = Sync-ProjectCodedbRuntimeConfig -Context $context
$providerPaths = Get-ProjectCodedbProviderPaths -Context $context
Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths

$relativeGeneratedConfig = ConvertTo-CodedbProjectRelativePath -Context $context -Path $configPath
Write-Host "OK: Runtime directories exist at $relativeRuntime."
Write-Host "OK: Runtime create/rename/delete probe passed."
Write-Host "OK: Generated provider runtime config from $relativeTemplate."
Write-Host "[OK] Runtime config is ready at $relativeGeneratedConfig."
exit 0
