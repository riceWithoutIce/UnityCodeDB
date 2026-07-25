#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
$script:hasFailure = $false

function Record-Pass {
    param([string]$Message)
    Write-Host "OK: $Message"
}

function Record-Failure {
    param([string]$Message)
    Write-Host "FAIL: $Message"
    $script:hasFailure = $true
}

function Test-ContainsLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Literal
    )

    return $Content.IndexOf($Literal, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Assert-LiteralLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Literal,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (Test-ContainsLiteral -Content $Content -Literal $Literal) {
        Record-Pass "$Label matches expected project-level value."
    } else {
        Record-Failure "$Label is missing or differs from expected value: $Literal"
    }
}

function Test-HasMachineLocalPath {
    param([Parameter(Mandatory = $true)][string]$Content)

    return $Content -match '(?im)"(?:[A-Za-z]:[\\/]|\\\\|~/|/)'
}

try {
    Assert-CodedbUnityProject -Context $context
    Record-Pass "Unity project CodeDB markers found."
} catch {
    Record-Failure $_.Exception.Message
}

$projectConfigPath = Join-Path $context.UnityRoot ".codex\config.toml"
$projectConfigRelativePath = ".codex/config.toml"

try {
    Assert-CodedbPathInside -Path $projectConfigPath -Root $context.UnityRoot -Label "project MCP config"
    Record-Pass "Project MCP config path stays inside the Unity project."
} catch {
    Record-Failure $_.Exception.Message
}

if (-not (Test-Path -LiteralPath $projectConfigPath)) {
    Record-Failure "Missing project MCP config: $projectConfigRelativePath"
} else {
    $config = Get-Content -LiteralPath $projectConfigPath -Raw
    $providerPaths = Get-ProjectCodedbProviderPaths -Context $context
    $relativeExePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ExecutablePath
    $relativeConfigPath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ConfigPath
    $relativeWrapperPath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.WrapperScriptPath
    $compatibilityWrapperPath = Join-Path $context.CodedbRoot "wrapper\codedb-$($context.ProjectSlug)-wrapper.mjs"
    $relativeCompatibilityWrapperPath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $compatibilityWrapperPath

    Assert-LiteralLine -Content $config -Literal "[mcp_servers.$($context.ProviderName)]" -Label "MCP server section"
    Assert-LiteralLine -Content $config -Literal "startup_timeout_sec = 120" -Label "Startup timeout"

    $usesProjectWrapper = Test-ContainsLiteral -Content $config -Literal "args = [`"$relativeWrapperPath`", `"--root`", `".`"]"
    $usesCompatibilityWrapper = (Test-Path -LiteralPath $compatibilityWrapperPath -PathType Leaf) -and
        (Test-ContainsLiteral -Content $config -Literal "args = [`"$relativeCompatibilityWrapperPath`", `"--root`", `".`"]")
    $usesWrapper = (Test-ContainsLiteral -Content $config -Literal 'command = "node"') -and
        ($usesProjectWrapper -or $usesCompatibilityWrapper)
    $usesDirectProvider = (Test-ContainsLiteral -Content $config -Literal "command = `"$relativeExePath`"") -and
        (Test-ContainsLiteral -Content $config -Literal "args = [`"mcp`", `"--root`", `".`", `"--config`", `"$relativeConfigPath`", `"--no-watch`"]")

    if ($usesWrapper) {
        if ($usesProjectWrapper) {
            Record-Pass "Project config uses the package-neutral wrapper MCP command shape."
        } else {
            Record-Pass "Project config uses the host compatibility wrapper MCP command shape."
        }

        $referencedWrapperPath = if ($usesProjectWrapper) { $context.WrapperScriptPath } else { $compatibilityWrapperPath }
        $referencedRelativeWrapperPath = if ($usesProjectWrapper) { $relativeWrapperPath } else { $relativeCompatibilityWrapperPath }
        if (Test-Path -LiteralPath $referencedWrapperPath -PathType Leaf) {
            Record-Pass "Referenced wrapper script exists under tracked codedb files."
        } else {
            Record-Failure "Missing wrapper script: $referencedRelativeWrapperPath"
        }

        if (Test-Path -LiteralPath $context.TextAdapterManifestPath -PathType Leaf) {
            Record-Pass "Shader/HLSL text adapter manifest is present for wrapper routing."
        } else {
            Record-Failure "Missing Shader/HLSL text adapter manifest. Build the adapter before registering the wrapper."
        }
    } elseif ($usesDirectProvider) {
        Record-Pass "Project config still uses the direct provider command shape; accepted only as a transition before wrapper registration."
    } else {
        Record-Failure "Project config must use either the wrapper command shape or the direct provider transition shape."
    }

    if (Test-HasMachineLocalPath -Content $config) {
        Record-Failure "$projectConfigRelativePath contains a quoted absolute or user-local path. Use Unity-root-relative paths only."
    } else {
        Record-Pass "$projectConfigRelativePath uses relative paths only."
    }

    try {
        $providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
        Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths
        Record-Pass "Referenced provider executable and config are present under project-local runtime."
    } catch {
        Record-Failure $_.Exception.Message
    }
}

if ($script:hasFailure) {
    Write-Host "[FAIL] Project-level MCP config validation failed."
    exit 1
}

Write-Host "[OK] Project-level MCP config validation passed."
exit 0
