#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Equal {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not [string]::Equals([string]$Actual, [string]$Expected, [StringComparison]::Ordinal)) {
        throw "$Label mismatch. Expected '$Expected', got '$Actual'."
    }
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    return $Path.Substring($Root.TrimEnd('\', '/').Length + 1).Replace('\', '/')
}

$packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$packageManifestPath = Join-Path $packageRoot "package.json"
$payloadRoot = Join-Path $packageRoot "Payload~"
$payloadManifestPath = Join-Path $payloadRoot "payload-manifest.json"

$expectedTopLevel = @(
    ".gitattributes",
    "CHANGELOG.md",
    "CHANGELOG.md.meta",
    "Documentation~",
    "Editor",
    "Editor.meta",
    "LICENSE.md",
    "LICENSE.md.meta",
    "package.json",
    "package.json.meta",
    "Payload~",
    "README.md",
    "README.md.meta",
    "Tests",
    "Tests.meta",
    "Tests~",
    "Third Party Notices.md",
    "Third Party Notices.md.meta",
    "Tools~"
) | Sort-Object
$actualTopLevel = @(Get-ChildItem -LiteralPath $packageRoot -Force | ForEach-Object { $_.Name } | Sort-Object)
Assert-Equal -Actual ($actualTopLevel -join "|") -Expected ($expectedTopLevel -join "|") -Label "Package top-level closure"

$packageManifest = Get-Content -LiteralPath $packageManifestPath -Raw | ConvertFrom-Json
Assert-Equal -Actual $packageManifest.name -Expected "com.rice.ai-codedb" -Label "Package name"
Assert-Equal -Actual $packageManifest.version -Expected "0.1.0" -Label "Package version"
Assert-Equal -Actual $packageManifest.unity -Expected "2022.3" -Label "Unity version"
Assert-True -Condition (-not [string]::IsNullOrWhiteSpace([string]$packageManifest.documentationUrl)) -Message "Package documentationUrl is missing."
Assert-True -Condition (-not [string]::IsNullOrWhiteSpace([string]$packageManifest.changelogUrl)) -Message "Package changelogUrl is missing."
Assert-True -Condition (-not [string]::IsNullOrWhiteSpace([string]$packageManifest.licensesUrl)) -Message "Package licensesUrl is missing."

$forbiddenBinaryExtensions = @(".7z", ".dll", ".exe", ".gz", ".pdb", ".tar", ".zip")
$binaryFiles = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Where-Object {
    $forbiddenBinaryExtensions -contains $_.Extension.ToLowerInvariant()
})
$binaryFilePaths = @($binaryFiles | ForEach-Object { $_.FullName })
Assert-True -Condition ($binaryFiles.Count -eq 0) -Message "Package contains forbidden provider or archive binaries: $($binaryFilePaths -join ', ')"

$textExtensions = @(".asmdef", ".cs", ".json", ".md", ".meta", ".mjs", ".ps1", ".toml")
$textFiles = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | Where-Object {
    $textExtensions -contains $_.Extension.ToLowerInvariant() -or
    $_.Name -in @(".gitattributes", "codedbignore.example")
})
foreach ($file in $textFiles) {
    if ([string]::Equals($file.FullName, $PSCommandPath, [StringComparison]::OrdinalIgnoreCase)) {
        continue
    }

    $content = [System.IO.File]::ReadAllText($file.FullName)
    if ($content -match '(?i)\bbalance\b|codedb-balance') {
        throw "Package contains a host-specific identifier: $(Get-RelativePath -Root $packageRoot -Path $file.FullName)"
    }

    if ($content -match '(?im)(^|[^A-Za-z0-9+.-])[A-Z]:[\\/]') {
        throw "Package contains a machine-local absolute path: $(Get-RelativePath -Root $packageRoot -Path $file.FullName)"
    }
}

$payloadManifest = Get-Content -LiteralPath $payloadManifestPath -Raw | ConvertFrom-Json
Assert-Equal -Actual $payloadManifest.schema_version -Expected 1 -Label "Payload schema"
Assert-Equal -Actual $payloadManifest.managed_by -Expected $packageManifest.name -Label "Payload manager"
Assert-Equal -Actual $payloadManifest.package_version -Expected $packageManifest.version -Label "Payload package version"
Assert-Equal -Actual $payloadManifest.payload_version -Expected "poc.9" -Label "Payload version"
Assert-Equal -Actual $payloadManifest.payload_sequence -Expected 9 -Label "Payload sequence"
Assert-Equal -Actual @($payloadManifest.files).Count -Expected 21 -Label "Payload target count"
Assert-Equal -Actual @($payloadManifest.retired_targets).Count -Expected 0 -Label "Retired target count"

$manifestSources = @()
foreach ($entry in $payloadManifest.files) {
    $source = [string]$entry.source
    $target = [string]$entry.target
    Assert-Equal -Actual $source -Expected $target -Label "Payload source and target"
    Assert-True -Condition $source.StartsWith("AIWork/codedb/", [StringComparison]::Ordinal) -Message "Payload target escapes AIWork/codedb: $source"
    Assert-True -Condition ($source.IndexOf("..", [StringComparison]::Ordinal) -lt 0) -Message "Payload target contains traversal: $source"

    $sourcePath = Join-Path $payloadRoot $source.Replace('/', '\')
    Assert-True -Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) -Message "Payload source is missing: $source"
    $actualHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Equal -Actual $actualHash -Expected ([string]$entry.sha256).ToLowerInvariant() -Label "Payload hash for $source"
    $manifestSources += $source
}

$payloadSourceRoot = Join-Path $payloadRoot "AIWork\codedb"
$payloadSources = @(Get-ChildItem -LiteralPath $payloadSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $payloadRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual ($payloadSources -join "|") -Expected (($manifestSources | Sort-Object) -join "|") -Label "Payload source closure"

$runtimeTemplate = Get-Content -LiteralPath (Join-Path $payloadRoot "AIWork\codedb\codedb-mcp.runtime.example.toml") -Raw
Assert-True -Condition ($runtimeTemplate -match '(?ms)^\[watch\]\s*$.*?^enabled\s*=\s*false\s*$') -Message "Tracked provider template must keep watch disabled by default."
Assert-True -Condition ($runtimeTemplate.IndexOf("__CODEDB_PROVIDER_SLUG__", [StringComparison]::Ordinal) -ge 0) -Message "Runtime template is missing the project provider slug token."

$packageAttributes = Get-Content -LiteralPath (Join-Path $packageRoot ".gitattributes") -Raw
foreach ($requiredRule in @(
    "Payload~/**/*.ps1 text eol=lf",
    "Payload~/**/*.mjs text eol=lf",
    "Payload~/**/*.json text eol=lf",
    "Tools~/**/*.ps1 text eol=lf",
    "Tests~/**/*.ps1 text eol=lf"
)) {
    Assert-True -Condition ($packageAttributes.IndexOf($requiredRule, [StringComparison]::Ordinal) -ge 0) -Message "Missing package EOL rule: $requiredRule"
}

Write-Host "[OK] Standalone CodeDB package boundary passed."
