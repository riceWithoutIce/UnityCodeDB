#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\codedb-project-common.ps1"

function Invoke-CodedbScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    Assert-CodedbPathInside -Path $ScriptPath -Root $context.CodedbRoot -Label "codedb script"
    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        throw "Missing codedb script: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $ScriptPath)"
    }

    $global:LASTEXITCODE = 0
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $ScriptPath @Arguments 6>&1 2>&1
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    foreach ($line in @($output)) {
        Write-Host $line
    }

    if ($exitCode -ne 0) {
        throw "Script failed with exit code ${exitCode}: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $ScriptPath)"
    }

    return @($output | ForEach-Object { [string]$_ })
}

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context

$freshnessScript = Join-Path $context.CodedbRoot "scripts\check-codedb-project-freshness.ps1"
$providerRefreshScript = Join-Path $context.CodedbRoot "scripts\refresh-codedb-project.ps1"
$adapterBuildScript = Join-Path $context.CodedbRoot "scripts\build-codedb-project-text-adapter.ps1"

Write-Host "[OK] Checking codedb freshness before conditional refresh."
$initialLines = Invoke-CodedbScript -ScriptPath $freshnessScript
$refreshPlan = Get-ProjectCodedbRefreshPlan -FreshnessLines @($initialLines)
Write-Host "[OK] Refresh plan: provider=$($refreshPlan.ProviderState), adapter=$($refreshPlan.AdapterState)."

if (-not $refreshPlan.ProviderNeedsRefresh -and -not $refreshPlan.AdapterNeedsRefresh) {
    Write-Host "[OK] codedb indexes are fresh. No refresh required."
    return
}

if ($refreshPlan.ProviderNeedsRefresh) {
    Write-Host "[OK] Refreshing stale provider index."
    Invoke-CodedbScript -ScriptPath $providerRefreshScript | Out-Null
}

if ($refreshPlan.AdapterNeedsRefresh) {
    Write-Host "[OK] Rebuilding stale Shader/HLSL adapter index."
    Invoke-CodedbScript -ScriptPath $adapterBuildScript | Out-Null
}

Write-Host "[OK] Rechecking codedb freshness after conditional refresh."
$finalLines = Invoke-CodedbScript -ScriptPath $freshnessScript
$null = Assert-ProjectCodedbFreshnessPassed -FreshnessLines @($finalLines)

Write-Host "[OK] codedb conditional refresh completed and freshness check passed."
