#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
$script:hasFailure = $false

function Pass {
    param([string]$Message)
    Write-Host "[OK] $Message"
}

function Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message"
    $script:hasFailure = $true
}

function ConvertTo-GitRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $gitRoot = [System.IO.Path]::GetFullPath($context.RepoRoot).TrimEnd('\', '/')
    $gitPrefix = $gitRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($gitPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the detected Git root. Path: $fullPath Root: $gitRoot"
    }

    return $fullPath.Substring($gitPrefix.Length).Replace('\', '/')
}

try {
    Assert-CodedbUnityProject -Context $context
    Pass "Unity project CodeDB markers found."
} catch {
    Fail $_.Exception.Message
}

try {
    Assert-CodedbPathInside -Path $context.RuntimeRoot -Root $context.UnityRoot -Label "codedb runtime"
    Assert-CodedbPathInside -Path $context.ProviderRoot -Root $context.RuntimeRoot -Label "provider runtime"
    Pass "Runtime paths stay inside the host Unity project."
} catch {
    Fail $_.Exception.Message
}

try {
    New-ProjectCodedbRuntime -Context $context
    Test-ProjectCodedbRuntimeFileOperations -Context $context
    Pass "Runtime create/rename/delete probe passed."
} catch {
    Fail $_.Exception.Message
}

if (Test-Path -LiteralPath $context.IgnoreTemplatePath) {
    Pass "Tracked codedb ignore template exists."
} else {
    Fail "Missing AIWork/codedb/codedbignore.example."
}

try {
    $providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
    Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths
    Pass "Provider executable and runtime config are present and use Unity-root-relative paths."
} catch {
    Fail $_.Exception.Message
}

$ignoredPaths = @(
    $context.RuntimeRoot,
    $context.ProviderIndexRoot,
    $context.GeneratedUnityIgnorePath
)
$optionalWorkspacePath = Join-Path $context.UnityRoot ".codex_tmp"
if (Test-Path -LiteralPath $optionalWorkspacePath) {
    $ignoredPaths += $optionalWorkspacePath
}

foreach ($fullPath in $ignoredPaths) {
    $relativePath = ConvertTo-GitRelativePath -Path $fullPath
    if (Test-CodedbPathGitIgnored -Context $context -RelativePath $relativePath) {
        Pass "$relativePath is ignored by Git."
    } else {
        Fail "$relativePath is not ignored by Git."
    }
}

$legacyUnityRootPaths = @(
    ".codedb",
    ".codedb-mcp",
    ".serena"
)

foreach ($relativePath in $legacyUnityRootPaths) {
    $fullPath = Join-Path $context.UnityRoot $relativePath
    if (Test-Path -LiteralPath $fullPath) {
        Fail "$relativePath exists under the Unity root. Keep provider runtime under AIWork/.runtime/ instead."
    } else {
        Pass "$relativePath is absent from the Unity root."
    }
}

$legacyOptionalPaths = @(
    ".codex_tmp"
)

foreach ($relativePath in $legacyOptionalPaths) {
    $fullPath = Join-Path $context.UnityRoot $relativePath
    if (Test-Path -LiteralPath $fullPath) {
        Pass "$relativePath exists as ignored local workspace state; it is not codedb runtime."
    } else {
        Pass "$relativePath is absent from the Unity root."
    }
}

if (Test-Path -LiteralPath $context.GeneratedUnityIgnorePath) {
    $template = Get-Content -LiteralPath $context.IgnoreTemplatePath -Raw
    $generated = Get-Content -LiteralPath $context.GeneratedUnityIgnorePath -Raw
    if ($template -eq $generated) {
        Pass "Generated .codedbignore matches the AIWork template."
    } else {
        Fail "Generated .codedbignore differs from AIWork/codedb/codedbignore.example."
    }
} else {
    Pass "No generated .codedbignore is present."
}

$trackedPaths = @(
    $context.RuntimeRoot,
    $context.GeneratedUnityIgnorePath,
    (Join-Path $context.UnityRoot ".codedb"),
    (Join-Path $context.UnityRoot ".codedb-mcp"),
    (Join-Path $context.UnityRoot ".serena"),
    (Join-Path $context.UnityRoot ".codex_tmp")
) | ForEach-Object { ConvertTo-GitRelativePath -Path $_ }
$trackedRuntimeStatus = & git -C $context.RepoRoot status --short -- $trackedPaths

if ($trackedRuntimeStatus) {
    Fail "Generated codedb runtime paths appear in git status: $($trackedRuntimeStatus -join '; ')"
} else {
    Pass "Generated codedb runtime paths do not appear in git status."
}

if ($script:hasFailure) {
    exit 1
}

Write-Host "Host project CodeDB structure verification passed."
exit 0
