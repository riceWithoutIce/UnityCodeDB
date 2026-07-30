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

function Assert-SafeRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-True -Condition (-not [string]::IsNullOrWhiteSpace($Path)) -Message "$Label is empty."
    Assert-True -Condition (-not [System.IO.Path]::IsPathRooted($Path)) -Message "$Label is rooted: $Path"
    $normalized = $Path.Replace('\', '/')
    Assert-True -Condition (-not $normalized.StartsWith("/", [StringComparison]::Ordinal)) -Message "$Label starts at a root: $Path"
    foreach ($segment in $normalized.Split('/')) {
        Assert-True `
            -Condition (-not [string]::IsNullOrWhiteSpace($segment) -and $segment -ne "." -and $segment -ne "..") `
            -Message "$Label contains an invalid path segment: $Path"
    }
    return $normalized
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
Assert-Equal -Actual $packageManifest.version -Expected "0.2.4-preview.4" -Label "Package version"
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

$textExtensions = @(".asmdef", ".cs", ".json", ".md", ".meta", ".mjs", ".ps1", ".svg", ".toml")
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

$iconSourcePath = Join-Path $packageRoot "Documentation~\images\codedb-icon.svg"
$iconTexturePath = Join-Path $packageRoot "Editor\Icons\CodedbIcon.png"
$iconTextureMetaPath = "$iconTexturePath.meta"
$tabIconTexturePath = Join-Path $packageRoot "Editor\Icons\CodedbTabIcon.png"
$tabIconTextureMetaPath = "$tabIconTexturePath.meta"
$thirdPartyNoticesPath = Join-Path $packageRoot "Third Party Notices.md"
Assert-True -Condition (Test-Path -LiteralPath $iconSourcePath -PathType Leaf) -Message "Brand SVG source is missing."
Assert-True -Condition (Test-Path -LiteralPath $iconTexturePath -PathType Leaf) -Message "Brand PNG is missing."
Assert-True -Condition (Test-Path -LiteralPath $iconTextureMetaPath -PathType Leaf) -Message "Brand PNG metadata is missing."
Assert-True -Condition (Test-Path -LiteralPath $tabIconTexturePath -PathType Leaf) -Message "Tab PNG is missing."
Assert-True -Condition (Test-Path -LiteralPath $tabIconTextureMetaPath -PathType Leaf) -Message "Tab PNG metadata is missing."

[xml]$iconSource = Get-Content -LiteralPath $iconSourcePath -Raw
$iconPaths = @($iconSource.svg.g.path)
Assert-Equal -Actual $iconSource.svg.viewBox -Expected "0 0 48 48" -Label "Brand SVG viewBox"
Assert-Equal -Actual $iconPaths.Count -Expected 3 -Label "Brand SVG path count"
Assert-Equal -Actual ($iconPaths.fill -join "|") -Expected "#8fbffa|#2859c5|#2859c5" -Label "Brand SVG colors"

$iconBytes = [System.IO.File]::ReadAllBytes($iconTexturePath)
Assert-True -Condition ($iconBytes.Length -ge 24) -Message "Brand PNG is truncated."
Assert-Equal -Actual (($iconBytes[0..7] -join ",")) -Expected "137,80,78,71,13,10,26,10" -Label "Brand PNG signature"
Assert-Equal -Actual (($iconBytes[16..19] -join ",")) -Expected "0,0,0,48" -Label "Brand PNG width"
Assert-Equal -Actual (($iconBytes[20..23] -join ",")) -Expected "0,0,0,48" -Label "Brand PNG height"

$tabIconBytes = [System.IO.File]::ReadAllBytes($tabIconTexturePath)
Assert-True -Condition ($tabIconBytes.Length -ge 24) -Message "Tab PNG is truncated."
Assert-Equal -Actual (($tabIconBytes[0..7] -join ",")) -Expected "137,80,78,71,13,10,26,10" -Label "Tab PNG signature"
Assert-Equal -Actual (($tabIconBytes[16..19] -join ",")) -Expected "0,0,0,48" -Label "Tab PNG width"
Assert-Equal -Actual (($tabIconBytes[20..23] -join ",")) -Expected "0,0,0,48" -Label "Tab PNG height"
Assert-True `
    -Condition ((Get-FileHash -LiteralPath $tabIconTexturePath -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $iconTexturePath -Algorithm SHA256).Hash) `
    -Message "Tab PNG must be an independent padded resource, not a duplicate of the brand PNG."

$iconMeta = Get-Content -LiteralPath $iconTextureMetaPath -Raw
$tabIconMeta = Get-Content -LiteralPath $tabIconTextureMetaPath -Raw
$iconGuidMatch = [regex]::Match($iconMeta, '(?m)^guid:\s*([0-9a-f]{32})\s*$')
$tabIconGuidMatch = [regex]::Match($tabIconMeta, '(?m)^guid:\s*([0-9a-f]{32})\s*$')
Assert-True -Condition $iconGuidMatch.Success -Message "Brand PNG metadata has no valid GUID."
Assert-True -Condition $tabIconGuidMatch.Success -Message "Tab PNG metadata has no valid GUID."
Assert-True -Condition ($tabIconGuidMatch.Groups[1].Value -ne $iconGuidMatch.Groups[1].Value) -Message "Tab PNG must have an independent Unity asset GUID."

$thirdPartyNotices = Get-Content -LiteralPath $thirdPartyNoticesPath -Raw
Assert-True -Condition ($thirdPartyNotices.IndexOf("Streamline", [StringComparison]::Ordinal) -ge 0) -Message "Streamline attribution is missing."
Assert-True -Condition ($thirdPartyNotices.IndexOf("CC BY 4.0", [StringComparison]::Ordinal) -ge 0) -Message "Streamline license is missing."
Assert-True -Condition ($thirdPartyNotices.IndexOf("https://streamlinehq.com", [StringComparison]::Ordinal) -ge 0) -Message "Streamline project link is missing."

$payloadManifest = Get-Content -LiteralPath $payloadManifestPath -Raw | ConvertFrom-Json
Assert-Equal -Actual $payloadManifest.schema_version -Expected 1 -Label "Payload schema"
Assert-Equal -Actual $payloadManifest.managed_by -Expected $packageManifest.name -Label "Payload manager"
Assert-Equal -Actual $payloadManifest.package_version -Expected $packageManifest.version -Label "Payload package version"
Assert-Equal -Actual $payloadManifest.payload_version -Expected "poc.26" -Label "Payload version"
Assert-Equal -Actual $payloadManifest.payload_sequence -Expected 26 -Label "Payload sequence"
Assert-Equal -Actual $payloadManifest.generation_id -Expected "poc.26" -Label "Payload generation"
Assert-Equal -Actual $payloadManifest.bootstrap_protocol -Expected 1 -Label "Payload bootstrap protocol"
Assert-Equal -Actual $payloadManifest.current_pointer_target -Expected "AIWork/.runtime/codedb/host/current.json" -Label "Payload current pointer target"
Assert-Equal -Actual @($payloadManifest.files).Count -Expected 43 -Label "Payload target count"

$flatTargetPrefix = "AIWork/codedb/"
$generationSourcePrefix = "Generations/poc.26/"
$generationTargetRoot = "AIWork/.runtime/codedb/host/generations/poc.26"
$generationTargetPrefix = $generationTargetRoot + "/"
$currentPointerSource = "host-current.json"
$currentPointerTarget = "AIWork/.runtime/codedb/host/current.json"
$manifestSources = @()
$flatSources = @()
$generationSources = @()
$currentPointerSources = @()
$seenSources = @{}
$seenTargets = @{}
$hashMismatches = New-Object System.Collections.Generic.List[string]
foreach ($entry in $payloadManifest.files) {
    $source = Assert-SafeRelativePath -Path ([string]$entry.source) -Label "Payload source"
    $target = Assert-SafeRelativePath -Path ([string]$entry.target) -Label "Payload target"
    Assert-True -Condition (-not $seenSources.ContainsKey($source)) -Message "Duplicate payload source: $source"
    Assert-True -Condition (-not $seenTargets.ContainsKey($target)) -Message "Duplicate payload target: $target"
    $seenSources[$source] = $true
    $seenTargets[$target] = $true

    $sourcePath = Join-Path $payloadRoot $source.Replace('/', '\')
    Assert-True -Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) -Message "Payload source is missing: $source"
    $expectedHash = ([string]$entry.sha256).ToLowerInvariant()
    Assert-True -Condition ($expectedHash -match '^[0-9a-f]{64}$') -Message "Payload hash is invalid: $source"
    $actualHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not [string]::Equals($actualHash, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
        $hashMismatches.Add("Payload manifest: $source expected $expectedHash, got $actualHash")
    }

    if ($target.StartsWith($flatTargetPrefix, [StringComparison]::Ordinal)) {
        Assert-Equal -Actual $source -Expected $target -Label "Flat payload source and target"
        $flatSources += $source
    } elseif ($target.StartsWith($generationTargetPrefix, [StringComparison]::Ordinal)) {
        $generationSuffix = $target.Substring($generationTargetPrefix.Length)
        Assert-Equal -Actual $source -Expected ($generationSourcePrefix + $generationSuffix) -Label "Generation payload source and target"
        $generationSources += $source
    } elseif ([string]::Equals($target, $currentPointerTarget, [StringComparison]::Ordinal)) {
        Assert-Equal -Actual $source -Expected $currentPointerSource -Label "Current pointer source"
        $currentPointerSources += $source
    } else {
        throw "Payload target is outside the reviewed flat, generation, and pointer scopes: $target"
    }
    $manifestSources += $source
}

Assert-Equal -Actual $flatSources.Count -Expected 21 -Label "Flat payload target count"
Assert-Equal -Actual $generationSources.Count -Expected 21 -Label "Generation payload target count"
Assert-Equal -Actual $currentPointerSources.Count -Expected 1 -Label "Current pointer target count"

$expectedRetiredTargets = @(foreach ($retiredGenerationId in @("poc.22", "poc.23", "poc.24", "poc.25")) {
    foreach ($generationSource in $generationSources) {
        $generationSuffix = $generationSource.Substring($generationSourcePrefix.Length)
        "AIWork/.runtime/codedb/host/generations/$retiredGenerationId/$generationSuffix"
    }
}) | Sort-Object
$actualRetiredTargets = New-Object System.Collections.Generic.List[string]
$seenRetiredTargets = @{}
foreach ($retiredTargetValue in @($payloadManifest.retired_targets)) {
    $retiredTarget = Assert-SafeRelativePath -Path ([string]$retiredTargetValue) -Label "Retired payload target"
    Assert-True -Condition (-not $seenRetiredTargets.ContainsKey($retiredTarget)) -Message "Duplicate retired payload target: $retiredTarget"
    Assert-True -Condition (-not $seenTargets.ContainsKey($retiredTarget)) -Message "Retired payload target is still current: $retiredTarget"
    $seenRetiredTargets[$retiredTarget] = $true
    $actualRetiredTargets.Add($retiredTarget)
}
$actualRetiredTargets = @($actualRetiredTargets | Sort-Object)
Assert-Equal -Actual $actualRetiredTargets.Count -Expected 84 -Label "Retired target count"
Assert-Equal `
    -Actual ($actualRetiredTargets -join "|") `
    -Expected ($expectedRetiredTargets -join "|") `
    -Label "Retired generation target closure"

$flatSourceRoot = Join-Path $payloadRoot "AIWork\codedb"
$actualFlatSources = @(Get-ChildItem -LiteralPath $flatSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $payloadRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual ($actualFlatSources -join "|") -Expected (($flatSources | Sort-Object) -join "|") -Label "Flat payload source closure"

$generationSourceRoot = Join-Path $payloadRoot "Generations\poc.26"
$actualGenerationSources = @(Get-ChildItem -LiteralPath $generationSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $payloadRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual ($actualGenerationSources -join "|") -Expected (($generationSources | Sort-Object) -join "|") -Label "Generation payload source closure"
Assert-True -Condition (Test-Path -LiteralPath (Join-Path $payloadRoot $currentPointerSource) -PathType Leaf) -Message "Current pointer source is missing."

$generationManifestPath = Join-Path $generationSourceRoot "generation-manifest.json"
$generationManifest = Get-Content -LiteralPath $generationManifestPath -Raw | ConvertFrom-Json
Assert-Equal -Actual $generationManifest.schema_version -Expected 1 -Label "Generation manifest schema"
Assert-Equal -Actual $generationManifest.managed_by -Expected $payloadManifest.managed_by -Label "Generation manifest manager"
Assert-Equal -Actual $generationManifest.generation_id -Expected $payloadManifest.generation_id -Label "Generation manifest generation"
Assert-Equal -Actual $generationManifest.package_version -Expected $payloadManifest.package_version -Label "Generation manifest package version"
Assert-Equal -Actual $generationManifest.payload_version -Expected $payloadManifest.payload_version -Label "Generation manifest payload version"
Assert-Equal -Actual $generationManifest.payload_sequence -Expected $payloadManifest.payload_sequence -Label "Generation manifest payload sequence"
Assert-Equal -Actual $generationManifest.bootstrap_protocol -Expected $payloadManifest.bootstrap_protocol -Label "Generation manifest bootstrap protocol"
Assert-Equal -Actual @($generationManifest.files).Count -Expected 20 -Label "Generation manifest file count"

$generationManifestPaths = @()
$seenGenerationPaths = @{}
foreach ($entry in $generationManifest.files) {
    $relativePath = Assert-SafeRelativePath -Path ([string]$entry.path) -Label "Generation file"
    Assert-True -Condition (-not $seenGenerationPaths.ContainsKey($relativePath)) -Message "Duplicate generation file: $relativePath"
    $seenGenerationPaths[$relativePath] = $true
    $generationManifestPaths += $relativePath

    $generationFilePath = Join-Path $generationSourceRoot $relativePath.Replace('/', '\')
    Assert-True -Condition (Test-Path -LiteralPath $generationFilePath -PathType Leaf) -Message "Generation file is missing: $relativePath"
    $expectedHash = ([string]$entry.sha256).ToLowerInvariant()
    Assert-True -Condition ($expectedHash -match '^[0-9a-f]{64}$') -Message "Generation file hash is invalid: $relativePath"
    $actualHash = (Get-FileHash -LiteralPath $generationFilePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if (-not [string]::Equals($actualHash, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
        $hashMismatches.Add("Generation manifest: $relativePath expected $expectedHash, got $actualHash")
    }

    $mainSource = $generationSourcePrefix + $relativePath
    $mainEntries = @($payloadManifest.files | Where-Object { [string]::Equals([string]$_.source, $mainSource, [StringComparison]::Ordinal) })
    Assert-Equal -Actual $mainEntries.Count -Expected 1 -Label "Main manifest entry count for $mainSource"
    Assert-Equal -Actual ([string]$mainEntries[0].target) -Expected ($generationTargetPrefix + $relativePath) -Label "Main generation target for $relativePath"
    Assert-Equal -Actual ([string]$mainEntries[0].sha256).ToLowerInvariant() -Expected $expectedHash -Label "Main generation hash for $relativePath"
}

$actualGenerationImplementationPaths = @(Get-ChildItem -LiteralPath $generationSourceRoot -Recurse -File | Where-Object {
    -not [string]::Equals($_.FullName, $generationManifestPath, [StringComparison]::OrdinalIgnoreCase)
} | ForEach-Object {
    Get-RelativePath -Root $generationSourceRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal `
    -Actual ($actualGenerationImplementationPaths -join "|") `
    -Expected (($generationManifestPaths | Sort-Object) -join "|") `
    -Label "Generation manifest source closure"

$currentPointerPath = Join-Path $payloadRoot $currentPointerSource
$currentPointer = Get-Content -LiteralPath $currentPointerPath -Raw | ConvertFrom-Json
Assert-Equal -Actual $currentPointer.schema_version -Expected 1 -Label "Current pointer schema"
Assert-Equal -Actual $currentPointer.managed_by -Expected $payloadManifest.managed_by -Label "Current pointer manager"
Assert-Equal -Actual $currentPointer.package_version -Expected $payloadManifest.package_version -Label "Current pointer package version"
Assert-Equal -Actual $currentPointer.payload_version -Expected $payloadManifest.payload_version -Label "Current pointer payload version"
Assert-Equal -Actual $currentPointer.payload_sequence -Expected $payloadManifest.payload_sequence -Label "Current pointer payload sequence"
Assert-Equal -Actual $currentPointer.generation_id -Expected $payloadManifest.generation_id -Label "Current pointer generation"
Assert-Equal -Actual $currentPointer.generation_relative_path -Expected $generationTargetRoot -Label "Current pointer generation path"
Assert-Equal -Actual $currentPointer.bootstrap_protocol -Expected $payloadManifest.bootstrap_protocol -Label "Current pointer bootstrap protocol"
$generationManifestHash = (Get-FileHash -LiteralPath $generationManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if (-not [string]::Equals(
        ([string]$currentPointer.generation_manifest_sha256).ToLowerInvariant(),
        $generationManifestHash,
        [StringComparison]::OrdinalIgnoreCase)) {
    $hashMismatches.Add(
        "Current pointer: generation-manifest.json expected $(([string]$currentPointer.generation_manifest_sha256).ToLowerInvariant()), got $generationManifestHash")
}

$runtimeTemplate = Get-Content -LiteralPath (Join-Path $generationSourceRoot "codedb-mcp.runtime.example.toml") -Raw
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

if ($hashMismatches.Count -gt 0) {
    throw "Payload hash validation failed:`n - $($hashMismatches -join "`n - ")"
}

Write-Host "[OK] Standalone CodeDB package boundary passed."
