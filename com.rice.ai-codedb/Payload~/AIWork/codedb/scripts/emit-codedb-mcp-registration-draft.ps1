#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext

Assert-CodedbUnityProject -Context $context
New-ProjectCodedbRuntime -Context $context
Test-ProjectCodedbRuntimeFileOperations -Context $context
$providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
if (-not (Test-Path -LiteralPath $context.WrapperScriptPath -PathType Leaf)) {
    throw "Missing wrapper script: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.WrapperScriptPath)"
}

$draft = [ordered]@{
    name = $context.ProviderName
    cwd = $context.UnityRoot
    command = "node"
    args = @(
        $context.WrapperScriptPath,
        "--root",
        $context.UnityRoot
    )
    defaultProfile = "Discover Read"
    registrationPolicy = "manual-review-only"
    registrationScope = "workspace-local-project-level-preferred"
    globalFallback = "temporary-smoke-fallback-only"
}

$relativeExePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ExecutablePath
$relativeConfigPath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ConfigPath
$relativeWrapperPath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.WrapperScriptPath
$projectConfigPath = ".codex/config.toml"
$projectConfigDraft = @"
[mcp_servers.$($context.ProviderName)]
command = "node"
args = ["$relativeWrapperPath", "--root", "."]
startup_timeout_sec = 120
"@

Write-Host "$($context.ProviderName) MCP registration draft"
Write-Host "Status: review draft only; no MCP client configuration was written."
Write-Host ""
Write-Host "Review gates passed:"
Write-Host "- Unity project CodeDB markers found."
Write-Host "- Runtime create/rename/delete probe passed."
Write-Host "- Provider executable exists at $relativeExePath."
Write-Host "- Provider config exists at $relativeConfigPath."
Write-Host "- Wrapper script exists at $relativeWrapperPath."
Write-Host ""
Write-Host "Policy:"
Write-Host "- Server name must be $($context.ProviderName)."
Write-Host "- Formal registration must prefer a workspace-local/project-level MCP configuration."
Write-Host "- User-level or global MCP registration is temporary smoke fallback only after project-level registration is unavailable or insufficient."
Write-Host "- Default first-use profile is Discover Read."
Write-Host "- Wrapper registration exposes only the approved Discover Read tool surface."
Write-Host "- Do not enable write, shell, remote, memory, cross-project, or broad export tools by default."
Write-Host "- Do not commit this printed draft if it contains machine-local absolute paths."
Write-Host ""
Write-Host "Workspace-local/project-level Codex draft:"
Write-Host "- Target file: $projectConfigPath"
Write-Host "- This project-level snippet uses Unity-root-relative paths and may be committed only after review."
Write-Host $projectConfigDraft
Write-Host ""
Write-Host "Machine-local review draft:"
$draft | ConvertTo-Json -Depth 4
