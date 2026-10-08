#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param()

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
Assert-ProjectCodedbWatchCoordinatorStopped -Context $context
Assert-CodedbPathInside -Path $context.ProviderRoot -Root $context.RuntimeRoot -Label "provider runtime"
Assert-CodedbPathInside -Path $context.ProviderIndexRoot -Root $context.ProviderRoot -Label "provider index"

$providerPaths = Get-ProjectCodedbProviderPaths -Context $context
$relativeIndex = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderIndexRoot
$relativeExecutable = ConvertTo-CodedbDisplayPath -Context $context -Path $providerPaths.ExecutablePath
$relativeConfig = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ConfigPath
$indexExists = Test-Path -LiteralPath $context.ProviderIndexRoot

Clear-ProjectCodedbIndex -Context $context

if (Test-Path -LiteralPath $providerPaths.ExecutablePath) {
    Write-Host "Preserved provider executable: $relativeExecutable"
} else {
    Write-Host "Provider executable was already missing: $relativeExecutable"
}

if (Test-Path -LiteralPath $providerPaths.ConfigPath) {
    Write-Host "Preserved provider config: $relativeConfig"
} else {
    Write-Host "Provider config was already missing: $relativeConfig"
}

if (-not $indexExists) {
    Write-Host "[SKIP] No generated codedb index existed at $relativeIndex."
    exit 0
}

if ($WhatIfPreference) {
    Write-Host "[OK] Index clean preview completed for $relativeIndex. Provider executable and runtime config would be preserved."
} else {
    Write-Host "[OK] Index clean completed for $relativeIndex. Provider executable and runtime config were preserved."
}
