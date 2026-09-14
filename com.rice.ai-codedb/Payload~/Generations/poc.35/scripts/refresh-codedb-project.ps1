#requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$GenerateUnityIgnore,
    [switch]$CleanFirst
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
Assert-ProjectCodedbWatchCoordinatorStopped -Context $context
$cleanTargetExists = Test-Path -LiteralPath $context.ProviderIndexRoot
New-ProjectCodedbRuntime -Context $context
Test-ProjectCodedbRuntimeFileOperations -Context $context
$providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths

Assert-CodedbPathInside -Path $context.ProviderIndexRoot -Root $context.ProviderRoot -Label "provider index"
Test-ProjectCodedbRuntimeFileOperations -Context $context -TargetDirectory $context.ProviderIndexRoot

if ($CleanFirst) {
    if ($cleanTargetExists) {
        Clear-ProjectCodedbIndex -Context $context
        New-Item -ItemType Directory -Force -Path $context.ProviderIndexRoot | Out-Null
    } else {
        Write-Host "No generated codedb index existed before rebuild."
    }
}

if ($GenerateUnityIgnore) {
    Sync-ProjectCodedbIgnore -Context $context
    $relativeIgnore = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.GeneratedUnityIgnorePath
    Write-Host "Generated $relativeIgnore from AIWork/codedb/codedbignore.example."
}

$relativeRuntime = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderRoot
$relativeIndex = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.ProviderIndexRoot
$relativeExe = ConvertTo-CodedbDisplayPath -Context $context -Path $providerPaths.ExecutablePath
$relativeConfig = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ConfigPath

Write-Host "Prepared $($context.ProviderName) runtime at $relativeRuntime."
Write-Host "Runtime create/rename/delete probe passed."
Write-Host "Index create/rename/delete probe passed."
Write-Host "Provider executable: $relativeExe"
Write-Host "Provider config: $relativeConfig"
Write-Host "Refreshing the host project CodeDB index at $relativeIndex..."

Push-Location -LiteralPath $context.UnityRoot
try {
    & $providerPaths.ExecutablePath index `
        --root $context.UnityRoot `
        --config $providerPaths.ConfigPath `
        --no-watch

    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

if ($exitCode -ne 0) {
    throw "The host project CodeDB index refresh failed with exit code $exitCode."
}

if (-not (Test-Path -LiteralPath (Join-Path $context.ProviderIndexRoot "manifest.json"))) {
    throw "The host project CodeDB index refresh finished, but no index manifest was found under $relativeIndex."
}

Write-Host "[OK] Host project CodeDB index refresh completed."
Write-Host "Generated index data remains under ignored runtime: $relativeIndex."
