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
$expectedUpmPackageVersion = "0.2.5-preview.5"
$expectedHostCompatibilityPackageVersion = "0.2.5-preview.5"
$expectedGenerationId = "poc.34"

# v0.3 P1-B moves command ownership to the project-local Supervisor. Keep
# these paths in the package boundary so a package cannot silently fall back to
# an unreviewed machine-global daemon or a missing bridge launcher.
$supervisorScriptPath = Join-Path $packageRoot "Tools~\codedb-project-supervisor.mjs"
$supervisorLauncherPath = Join-Path $packageRoot "Editor\AICodedbSupervisorLauncher.cs"
Assert-True -Condition (Test-Path -LiteralPath $supervisorScriptPath -PathType Leaf) -Message "Project Supervisor script is missing."
Assert-True -Condition (Test-Path -LiteralPath $supervisorLauncherPath -PathType Leaf) -Message "Project Supervisor launcher is missing."
$supervisorLauncherSource = [System.IO.File]::ReadAllText($supervisorLauncherPath)
Assert-True `
    -Condition ($supervisorLauncherSource.IndexOf('"--package-root", packageRoot', [StringComparison]::Ordinal) -ge 0) `
    -Message "Project Supervisor launcher does not route startup through the resolved Package root."
Assert-True `
    -Condition ($supervisorLauncherSource.IndexOf('AICodedbCurrentInstanceStatus', [StringComparison]::Ordinal) -lt 0) `
    -Message "Project Supervisor launcher still depends on a Bridge-side current-instance decision."
Assert-True `
    -Condition ($supervisorLauncherSource.IndexOf('context.GetProjectPath(context.ProviderConfigRelativePath)', [StringComparison]::Ordinal) -lt 0) `
    -Message "Project Supervisor launcher still routes through the legacy project runtime Provider config."
Assert-True `
    -Condition ($supervisorLauncherSource.IndexOf('AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(packageRoot, supervisorScript);', [StringComparison]::Ordinal) -ge 0) `
    -Message "Project Supervisor launcher does not validate the Package-owned script against the resolved Package root."
Assert-True `
    -Condition ($supervisorLauncherSource.IndexOf('AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(context.ProjectRoot, supervisorScript);', [StringComparison]::Ordinal) -lt 0) `
    -Message "Project Supervisor launcher still rejects legitimate UPM packages resolved outside the Unity project."

foreach ($requiredSupervisorLauncherRoutingBoundary in @(
    'AICodedbPackageRuntimeContractStore.Read(packageRoot)',
    'runtimeContract.ControlContract',
    'AICodedbControlContract.GetSupervisorRuntimePath('
)) {
    Assert-True -Condition ($supervisorLauncherSource.IndexOf($requiredSupervisorLauncherRoutingBoundary, [StringComparison]::Ordinal) -ge 0) -Message "Project Supervisor launcher is missing Package-derived control routing: $requiredSupervisorLauncherRoutingBoundary"
}
Assert-True -Condition ($supervisorLauncherSource.IndexOf('AICodedbProjectSettings.InstanceControlRelativePath', [StringComparison]::Ordinal) -lt 0) -Message "Project Supervisor launcher still references the fixed control namespace."

$supervisorBridgePath = Join-Path $packageRoot "Editor\AICodedbSupervisorBridge.cs"
Assert-True -Condition (Test-Path -LiteralPath $supervisorBridgePath -PathType Leaf) -Message "Project Supervisor bridge is missing."
$supervisorBridgeSource = [System.IO.File]::ReadAllText($supervisorBridgePath)
Assert-True `
    -Condition ($supervisorBridgeSource.IndexOf('AICodedbCurrentInstanceStore.Read', [StringComparison]::Ordinal) -lt 0) `
    -Message "Project Supervisor bridge still classifies or routes through current-instance storage."
Assert-True `
    -Condition ($supervisorBridgeSource.IndexOf('"handoff_queued"', [StringComparison]::Ordinal) -ge 0) `
    -Message "Project Supervisor bridge does not consume the Supervisor handoff disposition."

foreach ($requiredSupervisorBridgeRoutingBoundary in @(
    'AICodedbPackageRuntimeContractStore.Read(context.PackageRoot)',
    'runtimeContract.ControlContract',
    'AICodedbSupervisorLauncher.GetSupervisorStatePath(',
    'AICodedbSupervisorLauncher.GetSupervisorRuntimePath(',
    '"control_namespace"'
)) {
    Assert-True -Condition ($supervisorBridgeSource.IndexOf($requiredSupervisorBridgeRoutingBoundary, [StringComparison]::Ordinal) -ge 0) -Message "Project Supervisor bridge is missing Package-derived control routing: $requiredSupervisorBridgeRoutingBoundary"
}
Assert-True -Condition ($supervisorBridgeSource.IndexOf('AICodedbProjectSettings.InstanceControlRelativePath', [StringComparison]::Ordinal) -lt 0) -Message "Project Supervisor bridge still references the fixed control namespace."

$supervisorSource = [System.IO.File]::ReadAllText($supervisorScriptPath)
foreach ($requiredSupervisorNodeRoutingBoundary in @(
    'readControlContract(value, "Package runtime contract")',
    'getSupervisorRuntimePath(root, runtimeContract.controlContract)',
    'Supervisor runtime does not match the Package-derived control namespace.',
    'control_namespace: context.controlNamespace'
)) {
    Assert-True -Condition ($supervisorSource.IndexOf($requiredSupervisorNodeRoutingBoundary, [StringComparison]::Ordinal) -ge 0) -Message "Project Supervisor Node route is missing Package-derived control routing: $requiredSupervisorNodeRoutingBoundary"
}

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
Assert-Equal -Actual $packageManifest.version -Expected $expectedUpmPackageVersion -Label "UPM Package version"
Assert-Equal -Actual $packageManifest.unity -Expected "2022.3" -Label "Unity version"
Assert-Equal `
    -Actual $packageManifest.documentationUrl `
    -Expected "https://github.com/riceWithoutIce/UnityCodeDB/tree/v$expectedUpmPackageVersion/com.rice.ai-codedb#readme" `
    -Label "Package documentation URL"
Assert-Equal `
    -Actual $packageManifest.changelogUrl `
    -Expected "https://github.com/riceWithoutIce/UnityCodeDB/blob/v$expectedUpmPackageVersion/com.rice.ai-codedb/CHANGELOG.md" `
    -Label "Package changelog URL"
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
    $relativeFilePath = Get-RelativePath -Root $packageRoot -Path $file.FullName
    if ($content -match '(?i)\bbalance\b|codedb-balance') {
        $isReviewedDefectEvidence = [string]::Equals(
            $relativeFilePath,
            "Documentation~/v0.2.5-roadmap.md",
            [StringComparison]::Ordinal)
        $evidenceMatches = [regex]::Matches($content, 'codedb-balance', [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $remainingContent = [regex]::Replace(
            $content,
            'codedb-balance',
            '',
            [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($isReviewedDefectEvidence) {
            $remainingContent = [regex]::Replace($remainingContent, "Balance runtime", "")
        }
        if (-not $isReviewedDefectEvidence -or
            $evidenceMatches.Count -ne 4 -or
            $remainingContent -match '(?i)\bbalance\b') {
            throw "Package contains a host-specific identifier: $relativeFilePath"
        }
    }

    if ($content -match '(?im)(^|[^A-Za-z0-9+.-])[A-Z]:[\\/]') {
        throw "Package contains a machine-local absolute path: $relativeFilePath"
    }
}

$runtimeSourceRoots = @(
    (Join-Path $packageRoot "Editor"),
    (Join-Path $packageRoot "Tools~"),
    (Join-Path $payloadRoot "AIWork"),
    (Join-Path $payloadRoot "Generations\$expectedGenerationId")
)
$runtimeSourceFiles = @(foreach ($root in $runtimeSourceRoots) {
    Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
        $_.Extension.ToLowerInvariant() -in @(".cs", ".mjs", ".ps1")
    }
})
$forbiddenVcsInvocationPatterns = @(
    '(?i)\b(?:git|svn|p4|perforce)(?:\.exe|\.cmd)?\b\s+(?:status|rev-parse|check-ignore|diff|ls-files|info)',
    '(?i)\bGet-Command\s+(?:git|svn|p4|perforce)(?:\.exe|\.cmd)?\b',
    '(?i)&\s*(?:git|svn|p4|perforce)(?:\.exe|\.cmd)?\b',
    '(?i)\b(?:GIT_INDEX_FILE|TrackedHostAuthorizationPath|ConfirmLegacyMcpStopped|GitStaged|GitWorktree|GitHead)\b',
    '(?i)\bPackageInfo\s*\.\s*(?:source|packageId|git|url)\b',
    '(?i)\bpackageInfo\s*\.\s*(?:source|packageId|git|url)\b'
)
foreach ($file in $runtimeSourceFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    foreach ($pattern in $forbiddenVcsInvocationPatterns) {
        Assert-True `
            -Condition (-not [regex]::IsMatch($content, $pattern)) `
            -Message "Package runtime contains a version-control invocation or authorization contract: $(Get-RelativePath -Root $packageRoot -Path $file.FullName)"
    }
}

$pathsSourcePath = Join-Path $packageRoot "Editor\AICodedbPaths.cs"
$pathsSource = [System.IO.File]::ReadAllText($pathsSourcePath)
Assert-True `
    -Condition ($pathsSource.IndexOf("PackageInfo.FindForAssembly", [StringComparison]::Ordinal) -ge 0) `
    -Message "Editor Package resolution does not use Unity's loaded Package metadata."
Assert-True `
    -Condition ($pathsSource.IndexOf("packageInfo.resolvedPath", [StringComparison]::Ordinal) -ge 0) `
    -Message "Editor Package resolution does not use Unity's resolved physical path."
Assert-True `
    -Condition ($pathsSource.IndexOf("Packages/" + $packageManifest.name, [StringComparison]::OrdinalIgnoreCase) -lt 0) `
    -Message "Editor Package resolution contains a fixed embedded-package fallback."

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
$controlContract = $payloadManifest.control_contract
Assert-True -Condition ($null -ne $controlContract) -Message "Payload control contract is missing."
$controlContractIdentitySource = [System.IO.File]::ReadAllText(
    (Join-Path $packageRoot "Editor\AICodedbControlContract.cs"))
$controlContractIdMatch = [regex]::Match(
    $controlContractIdentitySource,
    'internal\s+const\s+string\s+DefaultId\s*=\s*"(?<value>[^"]+)";')
$controlContractVersionMatch = [regex]::Match(
    $controlContractIdentitySource,
    'internal\s+const\s+int\s+DefaultVersion\s*=\s*(?<value>\d+);')
$controlContractSchemaMatch = [regex]::Match(
    $controlContractIdentitySource,
    'internal\s+const\s+int\s+CurrentSchemaVersion\s*=\s*(?<value>\d+);')
Assert-True `
    -Condition ($controlContractIdMatch.Success -and $controlContractVersionMatch.Success -and $controlContractSchemaMatch.Success) `
    -Message "Control contract source identity constants are missing."
$expectedControlContractId = $controlContractIdMatch.Groups["value"].Value
$expectedControlContractVersion = [int]$controlContractVersionMatch.Groups["value"].Value
$expectedControlContractSchema = [int]$controlContractSchemaMatch.Groups["value"].Value
$canonicalControlContract = [string]::Join("`n", @(
    "com.rice.ai-codedb",
    "control-contract",
    $expectedControlContractId,
    $expectedControlContractVersion.ToString([Globalization.CultureInfo]::InvariantCulture),
    $expectedControlContractSchema.ToString([Globalization.CultureInfo]::InvariantCulture)
))
$controlContractHasher = [System.Security.Cryptography.SHA256]::Create()
try {
    $expectedControlContractSha256 = [BitConverter]::ToString(
        $controlContractHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonicalControlContract)))
    $expectedControlContractSha256 = $expectedControlContractSha256.Replace("-", "").ToLowerInvariant()
} finally {
    $controlContractHasher.Dispose()
}
Assert-Equal -Actual $controlContract.id -Expected $expectedControlContractId -Label "Control contract id"
Assert-Equal -Actual $controlContract.version -Expected $expectedControlContractVersion -Label "Control contract version"
Assert-Equal -Actual $controlContract.schema_version -Expected $expectedControlContractSchema -Label "Control contract schema"
Assert-Equal -Actual $controlContract.sha256 -Expected $expectedControlContractSha256 -Label "Control contract canonical hash"
Assert-Equal `
    -Actual $payloadManifest.package_version `
    -Expected $expectedHostCompatibilityPackageVersion `
    -Label "Payload Host compatibility package version"
Assert-Equal -Actual $payloadManifest.payload_version -Expected $expectedGenerationId -Label "Payload version"
Assert-Equal -Actual $payloadManifest.payload_sequence -Expected 34 -Label "Payload sequence"
Assert-Equal -Actual $payloadManifest.generation_id -Expected $expectedGenerationId -Label "Payload generation"
Assert-Equal -Actual $payloadManifest.bootstrap_protocol -Expected 1 -Label "Payload bootstrap protocol"
Assert-Equal -Actual $payloadManifest.current_pointer_target -Expected "AIWork/.runtime/codedb/host/current.json" -Label "Payload current pointer target"
Assert-Equal -Actual @($payloadManifest.files).Count -Expected 46 -Label "Payload target count"
$bootstrapTransitions = @($payloadManifest.bootstrap_transitions)
Assert-Equal -Actual $bootstrapTransitions.Count -Expected 3 -Label "Reviewed bootstrap transition count"
$v024Transition = $bootstrapTransitions[0]
Assert-Equal -Actual ([string]$v024Transition.source_tag) -Expected "v0.2.4" -Label "Reviewed bootstrap transition tag"
Assert-Equal -Actual ([string]$v024Transition.source_package_version) -Expected "0.2.4" -Label "Reviewed bootstrap transition Package"
Assert-Equal -Actual ([string]$v024Transition.source_payload_version) -Expected "poc.27" -Label "Reviewed bootstrap transition payload"
Assert-Equal -Actual ([int]$v024Transition.source_payload_sequence) -Expected 27 -Label "Reviewed bootstrap transition sequence"
Assert-Equal -Actual ([string]$v024Transition.source_generation_id) -Expected "poc.27" -Label "Reviewed bootstrap transition generation"
Assert-Equal -Actual ([int]$v024Transition.source_bootstrap_protocol) -Expected 1 -Label "Reviewed bootstrap transition protocol"
Assert-Equal -Actual ([int]$v024Transition.source_marker_schema_version) -Expected 1 -Label "Reviewed bootstrap transition marker schema"
Assert-Equal -Actual ([int]$v024Transition.source_host_use_gate_version) -Expected 1 -Label "Reviewed bootstrap transition host-use gate"
Assert-Equal -Actual ([int]$v024Transition.source_generation_lease_version) -Expected 2 -Label "Reviewed bootstrap transition generation lease"
Assert-Equal -Actual ([int]$v024Transition.source_flat_file_count) -Expected 21 -Label "Reviewed bootstrap transition flat file count"
Assert-Equal -Actual ([string]$v024Transition.source_flat_closure_sha256) -Expected "d6d64725fbc15066ea6062cb8d8de46ff1eb0133d13ff9906c1a5231da6a484c" -Label "Reviewed bootstrap transition closure"
Assert-Equal -Actual ([string]$v024Transition.source_stable_wrapper_sha256) -Expected "b8858bbe4b94c8a7e6f12d3268424b2bb0e09cef2febeb68889ea993e3ccda3c" -Label "Reviewed bootstrap transition stable wrapper"
$preview5Transition = $bootstrapTransitions[1]
Assert-Equal -Actual ([string]$preview5Transition.source_tag) -Expected "v0.2.5-preview.5" -Label "Reviewed preview.5 bootstrap transition tag"
Assert-Equal -Actual ([string]$preview5Transition.source_package_version) -Expected "0.2.5-preview.5" -Label "Reviewed preview.5 bootstrap transition Package"
Assert-Equal -Actual ([string]$preview5Transition.source_payload_version) -Expected "poc.32" -Label "Reviewed preview.5 bootstrap transition payload"
Assert-Equal -Actual ([int]$preview5Transition.source_payload_sequence) -Expected 32 -Label "Reviewed preview.5 bootstrap transition sequence"
Assert-Equal -Actual ([string]$preview5Transition.source_generation_id) -Expected "poc.32" -Label "Reviewed preview.5 bootstrap transition generation"
Assert-Equal -Actual ([int]$preview5Transition.source_marker_schema_version) -Expected 2 -Label "Reviewed preview.5 bootstrap transition marker schema"
Assert-Equal -Actual ([int]$preview5Transition.source_flat_file_count) -Expected 22 -Label "Reviewed preview.5 bootstrap transition flat file count"
Assert-Equal -Actual ([string]$preview5Transition.source_flat_closure_sha256) -Expected "10f61a75a04a484b431ccb2a94f79ae61cfbb0f81da2b306990a26c8fb8250e1" -Label "Reviewed preview.5 bootstrap transition closure"
Assert-Equal -Actual ([string]$preview5Transition.source_stable_wrapper_sha256) -Expected "8f7b43408299c947a76d2d4306d31ca611964c59f7b42be679f995ec07c44c06" -Label "Reviewed preview.5 bootstrap transition stable wrapper"
$poc33Transition = $bootstrapTransitions[2]
Assert-Equal -Actual ([string]$poc33Transition.source_tag) -Expected "v0.2.5-preview.5" -Label "Reviewed poc.33 bootstrap transition tag"
Assert-Equal -Actual ([string]$poc33Transition.source_package_version) -Expected "0.2.5-preview.5" -Label "Reviewed poc.33 bootstrap transition Package"
Assert-Equal -Actual ([string]$poc33Transition.source_payload_version) -Expected "poc.33" -Label "Reviewed poc.33 bootstrap transition payload"
Assert-Equal -Actual ([int]$poc33Transition.source_payload_sequence) -Expected 33 -Label "Reviewed poc.33 bootstrap transition sequence"
Assert-Equal -Actual ([string]$poc33Transition.source_generation_id) -Expected "poc.33" -Label "Reviewed poc.33 bootstrap transition generation"
Assert-Equal -Actual ([int]$poc33Transition.source_marker_schema_version) -Expected 2 -Label "Reviewed poc.33 bootstrap transition marker schema"
Assert-Equal -Actual ([int]$poc33Transition.source_flat_file_count) -Expected 22 -Label "Reviewed poc.33 bootstrap transition flat file count"
Assert-Equal -Actual ([string]$poc33Transition.source_flat_closure_sha256) -Expected "629f8873e93bc6e3aab2da167ae4c0439e23bf5ea467e882d2a99b7ed866f8f9" -Label "Reviewed poc.33 bootstrap transition closure"
Assert-Equal -Actual ([string]$poc33Transition.source_stable_wrapper_sha256) -Expected "740fc4114d5a0e41d20a6f49f8178a61a68243b6646fbc02dc06ddfbf0432791" -Label "Reviewed poc.33 bootstrap transition stable wrapper"

$flatTargetPrefix = "AIWork/codedb/"
$generationSourcePrefix = "Generations/$expectedGenerationId/"
$generationTargetRoot = "AIWork/.runtime/codedb/host/generations/$expectedGenerationId"
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

Assert-Equal -Actual $flatSources.Count -Expected 22 -Label "Flat payload target count"
Assert-Equal -Actual $generationSources.Count -Expected 23 -Label "Generation payload target count"
Assert-Equal -Actual $currentPointerSources.Count -Expected 1 -Label "Current pointer target count"

$legacyRetiredGenerationSourceRoot = Join-Path $payloadRoot "Generations\poc.30"
$legacyRetiredGenerationRelativePaths = @(Get-ChildItem -LiteralPath $legacyRetiredGenerationSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $legacyRetiredGenerationSourceRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual $legacyRetiredGenerationRelativePaths.Count -Expected 21 -Label "Legacy retired generation compatibility closure"
$poc32RetiredGenerationSourceRoot = Join-Path $payloadRoot "Generations\poc.32"
$poc32RetiredGenerationRelativePaths = @(Get-ChildItem -LiteralPath $poc32RetiredGenerationSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $poc32RetiredGenerationSourceRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual $poc32RetiredGenerationRelativePaths.Count -Expected 23 -Label "poc.32 retired generation closure"
$poc33RetiredGenerationSourceRoot = Join-Path $payloadRoot "Generations\poc.33"
$poc33RetiredGenerationRelativePaths = @(Get-ChildItem -LiteralPath $poc33RetiredGenerationSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $poc33RetiredGenerationSourceRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual $poc33RetiredGenerationRelativePaths.Count -Expected 23 -Label "poc.33 retired generation closure"
$expectedRetiredTargets = @(
    foreach ($retiredGenerationId in @("poc.22", "poc.23", "poc.24", "poc.25", "poc.26", "poc.27", "poc.28", "poc.29", "poc.30")) {
        foreach ($generationSuffix in $legacyRetiredGenerationRelativePaths) {
            "AIWork/.runtime/codedb/host/generations/$retiredGenerationId/$generationSuffix"
        }
    }
    foreach ($generationSuffix in $poc32RetiredGenerationRelativePaths) {
        "AIWork/.runtime/codedb/host/generations/poc.32/$generationSuffix"
    }
    foreach ($generationSuffix in $poc33RetiredGenerationRelativePaths) {
        "AIWork/.runtime/codedb/host/generations/poc.33/$generationSuffix"
    }
) | Sort-Object
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
Assert-Equal -Actual $actualRetiredTargets.Count -Expected 235 -Label "Retired target count"
Assert-Equal `
    -Actual ($actualRetiredTargets -join "|") `
    -Expected ($expectedRetiredTargets -join "|") `
    -Label "Retired generation target closure"

$flatSourceRoot = Join-Path $payloadRoot "AIWork\codedb"
$actualFlatSources = @(Get-ChildItem -LiteralPath $flatSourceRoot -Recurse -File | ForEach-Object {
    Get-RelativePath -Root $payloadRoot -Path $_.FullName
} | Sort-Object)
Assert-Equal -Actual ($actualFlatSources -join "|") -Expected (($flatSources | Sort-Object) -join "|") -Label "Flat payload source closure"

$generationSourceRoot = Join-Path $payloadRoot "Generations\$expectedGenerationId"
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
Assert-Equal -Actual @($generationManifest.files).Count -Expected 22 -Label "Generation manifest file count"
$generationHostUseGatePath = Join-Path $generationSourceRoot "shared\codedb-host-use-gate.mjs"
$generationHostUseGate = Get-Content -LiteralPath $generationHostUseGatePath -Raw
Assert-Equal `
    -Actual ([regex]::Matches($generationHostUseGate, '(?m)^export const GENERATION_ID = "poc\.34";$').Count) `
    -Expected 1 `
    -Label "Generation lease identity closure"

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

$generationWorkerSource = [System.IO.File]::ReadAllText((Join-Path $generationSourceRoot "wrapper\codedb-project-instance-worker.mjs"))
Assert-Equal `
    -Actual ([regex]::Matches($generationWorkerSource, '(?m)^\s*annotations: READ_ONLY_TOOL_ANNOTATIONS,\s*$').Count) `
    -Expected 6 `
    -Label "Project MCP read-only annotation coverage"
foreach ($annotationBoundary in @(
    "readOnlyHint: true",
    "destructiveHint: false",
    "idempotentHint: true",
    "openWorldHint: false"
)) {
    Assert-True `
        -Condition ($generationWorkerSource.IndexOf($annotationBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "Project MCP worker is missing annotation boundary: $annotationBoundary"
}

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
    "Tools~/**/*.mjs text eol=lf",
    "Tools~/**/*.json text eol=lf",
    "Tests~/**/*.ps1 text eol=lf",
    "Tests~/**/*.toml text eol=lf"
)) {
    Assert-True -Condition ($packageAttributes.IndexOf($requiredRule, [StringComparison]::Ordinal) -ge 0) -Message "Missing package EOL rule: $requiredRule"
}

$projectSettingsSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Editor\AICodedbProjectSettings.cs"))
$forbiddenRuntimePolicyNames = @(
    "CurrentPackageVersion",
    "CurrentPayloadVersion",
    "CurrentPayloadSequence",
    "CurrentGenerationId",
    "CurrentBootstrapProtocol"
)
foreach ($forbiddenRuntimePolicyName in $forbiddenRuntimePolicyNames) {
    Assert-True `
        -Condition ($projectSettingsSource.IndexOf($forbiddenRuntimePolicyName, [StringComparison]::Ordinal) -lt 0) `
        -Message "Editor settings still duplicate Package runtime policy: $forbiddenRuntimePolicyName"
}
$runtimeContractSourcePath = Join-Path $packageRoot "Editor\AICodedbPackageRuntimeContract.cs"
$runtimeContractMetaPath = "$runtimeContractSourcePath.meta"
Assert-True -Condition (Test-Path -LiteralPath $runtimeContractSourcePath -PathType Leaf) -Message "Package runtime contract reader is missing."
Assert-True -Condition (Test-Path -LiteralPath $runtimeContractMetaPath -PathType Leaf) -Message "Package runtime contract reader meta file is missing."
$runtimeContractSource = [System.IO.File]::ReadAllText($runtimeContractSourcePath)
foreach ($requiredRuntimeContractBoundary in @(
    '"Payload~"',
    '"payload-manifest.json"',
    '"control_contract"',
    'AICodedbControlContractIdentity',
    'ControlContract { get; }',
    'ReadControlContract(',
    "AICodedbStrictJson.ParseObject(",
    "bootstrap_transitions",
    "AICodedbRuntimeGenerationDisposition.Current",
    "AICodedbRuntimeGenerationDisposition.TrustedPrevious",
    "AICodedbRuntimeGenerationDisposition.Newer",
    "AICodedbRuntimeGenerationDisposition.SequenceCollision",
    "AICodedbRuntimeGenerationDisposition.Invalid"
)) {
    Assert-True `
        -Condition ($runtimeContractSource.IndexOf($requiredRuntimeContractBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "Package runtime contract reader is missing boundary: $requiredRuntimeContractBoundary"
}

$controlContractSourcePath = Join-Path $packageRoot "Editor\AICodedbControlContract.cs"
$controlContractMetaPath = "$controlContractSourcePath.meta"
Assert-True -Condition (Test-Path -LiteralPath $controlContractSourcePath -PathType Leaf) -Message "Control contract migration source is missing."
Assert-True -Condition (Test-Path -LiteralPath $controlContractMetaPath -PathType Leaf) -Message "Control contract migration meta file is missing."
$controlContractSource = [System.IO.File]::ReadAllText($controlContractSourcePath)
foreach ($requiredMigrationBoundary in @(
    "AICodedbControlContractMigrationState",
    "ObsoleteReinstallRequired",
    "InvalidOrAmbiguous",
    "BlocksAutomaticStart",
    "AICodedbControlContractMigrationStore",
    "InspectNamespace(",
    "AICodedbPackageRuntimeContractStore.Read("
)) {
    Assert-True `
        -Condition ($controlContractSource.IndexOf($requiredMigrationBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "Control contract migration source is missing boundary: $requiredMigrationBoundary"
}
foreach ($forbiddenMigrationMutation in @(
    "File.Delete(",
    "Directory.Delete(",
    "Process.Kill("
)) {
    Assert-True `
        -Condition ($controlContractSource.IndexOf($forbiddenMigrationMutation, [StringComparison]::Ordinal) -lt 0) `
        -Message "Control contract classification must remain read-only: $forbiddenMigrationMutation"
}
foreach ($requiredFailClosedClassifierBoundary in @(
    "if (!stateExists || !lockExists)",
    "LooksLikeKnownLegacyEvidence(",
    "IsCompleteKnownLegacyEvidence(",
    "HasCurrentContractEvidence(",
    "LegacyStateRequiredFields",
    "LegacyLockRequiredFields",
    "LegacyStateOptionalFields",
    "LegacySupervisorStateSchemaVersion = 3",
    "schema == LegacySupervisorStateSchemaVersion",
    "supervisorProtocol == LegacySupervisorProtocolVersion",
    "supervisorProtocol == LegacySupervisorProtocolVersionV1",
    "SameOwner(state, owner)",
    "contains an unknown or conflicting property",
    "!string.Equals(pipeName, expectedPipe",
    "&& !string.IsNullOrWhiteSpace(recordedPath)"
)) {
    Assert-True `
        -Condition ($controlContractSource.IndexOf($requiredFailClosedClassifierBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "Control contract classifier is missing fail-closed boundary: $requiredFailClosedClassifierBoundary"
}
foreach ($forbiddenPermissiveClassifierBoundary in @(
    "if (legacy || LooksLikeKnownLegacyEvidence(evidence))",
    "LegacySupervisorStateSchemaVersionV2",
    "var evidence = state ?? owner;",
    "(string.IsNullOrWhiteSpace(recordedPath)"
)) {
    Assert-True `
        -Condition ($controlContractSource.IndexOf($forbiddenPermissiveClassifierBoundary, [StringComparison]::Ordinal) -lt 0) `
        -Message "Control contract classifier still accepts ambiguous evidence: $forbiddenPermissiveClassifierBoundary"
}
$legacyEvidenceValidator = [regex]::Match(
    $controlContractSource,
    '(?s)private\s+static\s+bool\s+IsCompleteKnownLegacyEvidence\s*\(.*?(?<body>\{.*?\})\s*\r?\n\s*private\s+static\s+bool\s+HasCurrentContractEvidence')
Assert-True -Condition $legacyEvidenceValidator.Success -Message "Package boundary could not isolate the known legacy evidence validator."
foreach ($requiredLegacyEvidenceField in @(
    '"evidence_schema_version"',
    '"root"',
    '"project_identity"',
    '"runtime"',
    '"pipe_name"',
    '"generation_id"',
    '"target_generation_id"',
    '"selected_generation_id"',
    '"selected_instance_id"',
    '"runtime_contract_sha256"',
    '"generation_disposition"',
    '"lifecycle_id"',
    '"supervisor_id"',
    '"owner_epoch"',
    '"supervisor_pid"',
    '"publication_phase"',
    '"owner_evidence"',
    '"process_start_identity"',
    '"executable_path"',
    '"argv_sha256"',
    '"command_line_sha256"',
    '"protocol_version"',
    '"auth_token"',
    '"desired_state"',
    '"editor_demand"',
    '"readiness_state"',
    '"reason_code"',
    '"detail"',
    '"last_event"',
    '"last_event_detail"',
    '"owner_started_at_utc"',
    "IsExpectedSupervisorPipeName(",
    "AICodedbEditorLifecycle.CreateProjectIdentity(projectRoot)",
    "AICodedbControlContract.IsSha256(authToken)",
    "evidencePid == supervisorPid"
)) {
    Assert-True `
        -Condition ($legacyEvidenceValidator.Groups["body"].Value.IndexOf($requiredLegacyEvidenceField, [StringComparison]::Ordinal) -ge 0) `
        -Message "Known legacy evidence validator is missing complete evidence boundary: $requiredLegacyEvidenceField"
}
foreach ($requiredRejectedCurrentContractField in @(
    '"control_contract_id"',
    '"control_contract_version"',
    '"control_contract_schema_version"',
    '"control_contract_sha256"',
    '"control_namespace"'
)) {
    Assert-True `
        -Condition ($controlContractSource.IndexOf($requiredRejectedCurrentContractField, $controlContractSource.IndexOf("HasCurrentContractEvidence("), [StringComparison]::Ordinal) -ge 0) `
        -Message "Known legacy evidence validator does not reject current-contract lookalikes: $requiredRejectedCurrentContractField"
}
$currentNamespacePriority = [regex]::Match(
    $controlContractSource,
    'if\s*\(\s*current\.Kind\s*==\s*NamespaceEvidenceKind\.Current\s*\)')
$legacyInvalidFallback = [regex]::Match(
    $controlContractSource,
    '(?s)if\s*\(\s*legacy\.Kind\s*==\s*NamespaceEvidenceKind\.Invalid\s*\)\s*return\s+Invalid')
Assert-True -Condition $currentNamespacePriority.Success -Message "Control contract classifier does not prioritize the current namespace."
Assert-True -Condition $legacyInvalidFallback.Success -Message "Control contract classifier is missing the legacy invalid fallback."
Assert-True `
    -Condition ($currentNamespacePriority.Index -lt $legacyInvalidFallback.Index) `
    -Message "Malformed legacy evidence is evaluated before the current namespace result."
Assert-True `
    -Condition ($controlContractSource.IndexOf("Legacy namespace evidence was retained for diagnostics and ignored", [StringComparison]::Ordinal) -ge 0) `
    -Message "Current namespace classification does not explicitly ignore malformed legacy evidence."

$migrationTestsSourcePath = Join-Path $packageRoot "Tests\Editor\AICodedbManagerUiTests.cs"
Assert-True -Condition (Test-Path -LiteralPath $migrationTestsSourcePath -PathType Leaf) -Message "Control contract migration tests are missing."
$migrationTestsSource = [System.IO.File]::ReadAllText($migrationTestsSourcePath)
foreach ($requiredMigrationTest in @(
    "Read_RecognizesCompleteLegacyStateAndLock",
    "Read_RejectsSignatureOnlyLegacyEvidence",
    "Read_RejectsStateOnlyLegacyEvidence",
    "Read_RejectsLockOnlyLegacyEvidence",
    "Read_RejectsMissingStateOrLockSpecificFields",
    "Read_RejectsWrongLegacyPathIdentity",
    "Read_RejectsDirectoryInEvidencePath",
    "Read_RejectsMalformedLegacyJson",
    "Read_RejectsStateLockOwnerConflict",
    "Read_RejectsStateSpecificFieldOnLegacyLock",
    "Read_RejectsUnknownLegacyFieldWithoutCurrentNamespace",
    "Read_RejectsLegacyCurrentContractLookalike",
    "Read_PreservesAuthenticatedCurrentResultWhenLegacyEvidenceIsMalformed",
    "AICodedbControlContractMigrationStore.Read("
)) {
    Assert-True `
        -Condition ($migrationTestsSource.IndexOf($requiredMigrationTest, [StringComparison]::Ordinal) -ge 0) `
        -Message "Focused migration behavior matrix is missing: $requiredMigrationTest"
}



$runtimePolicySources = @(
    Get-ChildItem -LiteralPath (Join-Path $packageRoot "Editor") -Recurse -File -Filter "*.cs"
    Get-ChildItem -LiteralPath (Join-Path $packageRoot "Tools~") -Recurse -File | Where-Object { $_.Extension -in @(".mjs", ".ps1") }
    Get-ChildItem -LiteralPath (Join-Path $payloadRoot "AIWork") -Recurse -File | Where-Object { $_.Extension -in @(".mjs", ".ps1") }
)
foreach ($runtimePolicyFile in $runtimePolicySources) {
    $runtimePolicySource = [System.IO.File]::ReadAllText($runtimePolicyFile.FullName)
    foreach ($forbiddenRuntimePolicyName in $forbiddenRuntimePolicyNames) {
        Assert-True `
            -Condition ($runtimePolicySource.IndexOf($forbiddenRuntimePolicyName, [StringComparison]::Ordinal) -lt 0) `
            -Message "Runtime control source duplicates Package runtime policy ($forbiddenRuntimePolicyName): $(Get-RelativePath -Root $packageRoot -Path $runtimePolicyFile.FullName)"
    }
    Assert-True `
        -Condition ($runtimePolicySource.IndexOf('poc.34', [StringComparison]::Ordinal) -lt 0) `
        -Message "Runtime control source hard-codes the current generation: $(Get-RelativePath -Root $packageRoot -Path $runtimePolicyFile.FullName)"
}

$legacyStopClientPath = Join-Path $packageRoot "Tools~\stop-codedb-legacy-watcher.mjs"
Assert-True -Condition (Test-Path -LiteralPath $legacyStopClientPath -PathType Leaf) -Message "Package-owned legacy watcher Stop client is missing."
$mcpAvailabilityProbePath = Join-Path $packageRoot "Tools~\probe-codedb-mcp-availability.mjs"
Assert-True -Condition (Test-Path -LiteralPath $mcpAvailabilityProbePath -PathType Leaf) -Message "Package-owned MCP availability probe is missing."
$providerInstallerPath = Join-Path $packageRoot "Tools~\install-codedb-provider.ps1"
Assert-True -Condition (Test-Path -LiteralPath $providerInstallerPath -PathType Leaf) -Message "Package-owned Provider installer is missing."
$providerDistributionManifestPath = Join-Path $packageRoot "Tools~\codedb-provider-distribution.json"
Assert-True -Condition (Test-Path -LiteralPath $providerDistributionManifestPath -PathType Leaf) -Message "Provider distribution descriptor is missing."
$providerInstallerSource = [System.IO.File]::ReadAllText($providerInstallerPath)
foreach ($requiredProviderInstallerBoundary in @(
    "distribution_state",
    "Get-ValidatedDistributionMode",
    "New-DevelopmentProviderCandidate",
    "Assert-DetachedSignature",
    "Expand-ValidatedProviderArchive",
    "Install-ProviderCandidate",
    "Assert-TestModeIsolation",
    "TestMode",
    "PROVIDER_DISTRIBUTION_UNAVAILABLE"
)) {
    Assert-True `
        -Condition ($providerInstallerSource.IndexOf($requiredProviderInstallerBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "Provider installer is missing boundary: $requiredProviderInstallerBoundary"
}
$providerDistributionManifestSource = [System.IO.File]::ReadAllText($providerDistributionManifestPath)
foreach ($requiredDistributionField in @(
    '"provider_id": "killop/codedb-mcp"',
    '"version": "0.5.0-28e3912"',
    '"commit": "28e3912d5cd67ff3499734984f3e3d626a204796"',
    '"distribution_state": "DEVELOPMENT_UPSTREAM"',
    '"release_base_url": "https://raw.githubusercontent.com/killop/codedb-mcp/28e3912d5cd67ff3499734984f3e3d626a204796/skills/codedb-mcp/assets"',
    '"archive_name": "codebase-mcp.exe"',
    '"executable_sha256": "38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7"',
    '"license_status": "PENDING"'
)) {
    Assert-True `
        -Condition ($providerDistributionManifestSource.IndexOf($requiredDistributionField, [StringComparison]::Ordinal) -ge 0) `
        -Message "Provider distribution descriptor is missing field: $requiredDistributionField"
}
$mcpAvailabilityProbeSource = [System.IO.File]::ReadAllText($mcpAvailabilityProbePath)
foreach ($requiredProbeBoundary in @(
    '"Lifecycle reason: READY"',
    '"Watch coordinator: ready"',
    'name: "codedb_text_search"',
    'codedb_status_usable: false',
    'codedb_text_search_callable: false',
    'readOnlyHint: true',
    'destructiveHint: false',
    'idempotentHint: true',
    'openWorldHint: false'
)) {
    Assert-True `
        -Condition ($mcpAvailabilityProbeSource.IndexOf($requiredProbeBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "MCP availability probe is missing the usable-backend boundary: $requiredProbeBoundary"
}
$materializerSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Tools~\materialize-codedb-host-payload.ps1"))
Assert-True `
    -Condition ($materializerSource.IndexOf("stop-codedb-legacy-watcher.mjs", [StringComparison]::Ordinal) -ge 0) `
    -Message "Materializer does not reference the Package-owned legacy watcher Stop client."
Assert-True `
    -Condition ($materializerSource.IndexOf("probe-codedb-mcp-availability.mjs", [StringComparison]::Ordinal) -ge 0) `
    -Message "Materializer does not reference the Package-owned MCP availability probe."
$pendingRecoveryFunction = [regex]::Match(
    $materializerSource,
    '(?s)function\s+Invoke-PendingTransactionRecovery\s*\{(?<body>.*?)\r?\n\}\r?\n\r?\nfunction\s+Remove-EmptyManagedParents')
Assert-True -Condition $pendingRecoveryFunction.Success -Message "Package boundary could not isolate pending transaction recovery."
Assert-True `
    -Condition (-not [regex]::IsMatch($pendingRecoveryFunction.Groups["body"].Value, '(?m)^\s*&\s*\$[A-Za-z]*WatcherManager(?:Path)?\b')) `
    -Message "Pending transaction recovery still executes a selected historical watcher manager."
$rollbackResolverFunction = [regex]::Match(
    $materializerSource,
    '(?s)function\s+Resolve-RollbackWatcherManager\s*\{(?<body>.*?)\r?\n\}\r?\n\r?\nfunction\s+Get-LegacyWatchManagerPath')
Assert-True -Condition $rollbackResolverFunction.Success -Message "Package boundary could not isolate rollback watcher identity validation."
Assert-True `
    -Condition (-not [regex]::IsMatch($rollbackResolverFunction.Groups["body"].Value, '(?m)^\s*&\s*\$[A-Za-z]*WatcherManager(?:Path)?\b')) `
    -Message "Rollback watcher identity validation executes the historical watcher manager."
$repairFunction = [regex]::Match(
    $materializerSource,
    '(?s)function\s+Invoke-Repair\s*\{(?<body>.*?)\r?\n\}\r?\n\r?\nfunction\s+Get-ValidatedInstalledGenerationPointer')
Assert-True -Condition $repairFunction.Success -Message "Package boundary could not isolate Invoke-Repair."
Assert-True `
    -Condition ($repairFunction.Groups["body"].Value.IndexOf("Complete-OwnedLegacyRedeployHostUseGate", [StringComparison]::Ordinal) -lt 0) `
    -Message "Repair must never use the Redeploy-only gate that can stop a recognized legacy watcher."
$supervisorBridgePath = Join-Path $packageRoot "Editor\AICodedbSupervisorBridge.cs"
Assert-True -Condition (Test-Path -LiteralPath $supervisorBridgePath -PathType Leaf) -Message "Package is missing the v0.3 Supervisor Bridge source."
$supervisorBridgeSource = [System.IO.File]::ReadAllText($supervisorBridgePath)
Assert-True `
    -Condition ($supervisorBridgeSource.IndexOf("protocol_version", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("NamedPipeClientStream", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("PipeOptions.Asynchronous", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("WaitForPipeIo(", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("Task.Run", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("TryGetExpectedWindowsPipeName", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("runtime_contract_sha256", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("generation_disposition", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("CORE_READY", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("ReadBoundedLine", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("provider_ready_at_utc", [StringComparison]::Ordinal) -ge 0) `
    -Message "Supervisor Bridge must use a versioned asynchronous named-pipe boundary."
Assert-True `
    -Condition ($supervisorBridgeSource.IndexOf("pipe.ReadTimeout =", [StringComparison]::Ordinal) -lt 0 -and
        $supervisorBridgeSource.IndexOf("pipe.WriteTimeout =", [StringComparison]::Ordinal) -lt 0) `
    -Message "Supervisor Bridge must not assign unsupported NamedPipeClientStream timeout properties."
foreach ($forbiddenBridgeMainThreadCall in @(
    "EditorApplication.",
    "AssetDatabase.",
    "Process.Start(",
    "RunPowerShellScript("
)) {
    Assert-True `
        -Condition ($supervisorBridgeSource.IndexOf($forbiddenBridgeMainThreadCall, [StringComparison]::Ordinal) -lt 0) `
        -Message "Supervisor Bridge must not own Unity callbacks or synchronous process launch: $forbiddenBridgeMainThreadCall"
}
$supervisorQueuePath = Join-Path $packageRoot "Editor\AICodedbSupervisorRequestQueue.cs"
Assert-True -Condition (Test-Path -LiteralPath $supervisorQueuePath -PathType Leaf) -Message "Package is missing the v0.3 Supervisor request queue source."
$supervisorQueueSource = [System.IO.File]::ReadAllText($supervisorQueuePath)
foreach ($requiredQueueBoundary in @(
    "AICodedbSupervisorRequestKind",
    "AICodedbSupervisorRequestPriority",
    "RunContinuationsAsynchronously",
    "TakeNextEntryLocked",
    "SetMaintenanceSuspended",
    "Invalidate"
)) {
    Assert-True `
        -Condition ($supervisorQueueSource.IndexOf($requiredQueueBoundary, [StringComparison]::Ordinal) -ge 0) `
        -Message "Supervisor request queue is missing boundary: $requiredQueueBoundary"
}
$editorLifecycleSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Editor\AICodedbEditorLifecycle.cs"))
Assert-True `
    -Condition ($editorLifecycleSource.IndexOf("SupervisorRequestQueue.Enqueue(", [StringComparison]::Ordinal) -ge 0 -and
        $editorLifecycleSource.IndexOf("SupervisorRequestQueue.Invalidate(", [StringComparison]::Ordinal) -ge 0) `
    -Message "Editor lifecycle must route reconcile/reconnect work through the Supervisor request queue."
$initializeOnLoadConstructor = [regex]::Match(
    $editorLifecycleSource,
    '(?s)static\s+AICodedbEditorLifecycle\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+static\s+void\s+QueueDeferredInitialization')
Assert-True -Condition $initializeOnLoadConstructor.Success -Message "Package boundary could not isolate the InitializeOnLoad constructor."
Assert-True `
    -Condition ($initializeOnLoadConstructor.Groups["body"].Value.IndexOf("QueueDeferredInitialization()", [StringComparison]::Ordinal) -ge 0) `
    -Message "InitializeOnLoad must only queue deferred lifecycle initialization."
foreach ($forbiddenReloadCall in @(
    "PackageInfo.FindForAssembly(",
    "AICodedbPaths.CaptureExecutionContext(",
    "ValidateProjectRoot(",
    "CreateProjectIdentity(",
    "ReadPersistedProductState(",
    "HasPackageFingerprintChanged(",
    "RecordReconciledPackageFingerprint(",
    "Process.GetCurrentProcess(",
    "SessionState."
)) {
    Assert-True `
        -Condition ($initializeOnLoadConstructor.Groups["body"].Value.IndexOf($forbiddenReloadCall, [StringComparison]::Ordinal) -lt 0) `
        -Message "InitializeOnLoad constructor still performs blocking setup: $forbiddenReloadCall"
}
$initializeFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+void\s+Initialize\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+static\s+void\s+QueueInitialReconcile')
Assert-True -Condition $initializeFunction.Success -Message "Package boundary could not isolate Editor lifecycle Initialize."
$initialReconcileIndex = $initializeFunction.Groups["body"].Value.IndexOf("QueueInitialReconcile()", [StringComparison]::Ordinal)
$stablePlayLeaseIndex = $initializeFunction.Groups["body"].Value.IndexOf("QueueLeaseRefresh()", [StringComparison]::Ordinal)
Assert-True `
    -Condition ($initialReconcileIndex -ge 0 -and
        $stablePlayLeaseIndex -gt $initialReconcileIndex -and
        $initializeFunction.Groups["body"].Value.IndexOf("if (!maintenanceSuspended)", [StringComparison]::Ordinal) -ge 0 -and
        $initializeFunction.Groups["body"].Value.IndexOf("BeginReconcile(true)", [StringComparison]::Ordinal) -lt 0) `
    -Message "Editor cold start must queue delayed reconciliation, while stable Play may queue only the persisted lease heartbeat."
foreach ($forbiddenMainThreadCall in @(
    "PublishLease(",
    "RefreshEditorLeaseForIntegrationState(",
    "BackendNeedsReconcile(",
    "AICodedbHostGenerationStore.Resolve(",
    "AICodedbHostPayloadMaterializer.",
    "AICodedbActions.RunEnsureWatcher("
)) {
    Assert-True `
        -Condition ($initializeFunction.Groups["body"].Value.IndexOf($forbiddenMainThreadCall, [StringComparison]::Ordinal) -lt 0) `
        -Message "Editor cold start directly invokes main-thread work: $forbiddenMainThreadCall"
}
$editorUpdateFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+void\s+OnEditorUpdate\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*internal\s+static\s+bool\s+ShouldRunScheduledReconcile')
Assert-True -Condition $editorUpdateFunction.Success -Message "Package boundary could not isolate Editor lifecycle heartbeat."
$missingPrerequisiteHeartbeatIndex = $editorUpdateFunction.Groups["body"].Value.IndexOf(
    "_lastProductState == AICodedbProductState.MissingPrerequisite",
    [StringComparison]::Ordinal)
$heartbeatLeaseIndex = $editorUpdateFunction.Groups["body"].Value.IndexOf("QueueLeaseRefresh()", [StringComparison]::Ordinal)
$lastHeartbeatLeaseIndex = $editorUpdateFunction.Groups["body"].Value.LastIndexOf("QueueLeaseRefresh()", [StringComparison]::Ordinal)
Assert-True `
    -Condition ($missingPrerequisiteHeartbeatIndex -ge 0 -and $lastHeartbeatLeaseIndex -gt $missingPrerequisiteHeartbeatIndex) `
    -Message "Editor heartbeat must return through the read-only prerequisite recheck before lease refresh."
Assert-True `
    -Condition ($heartbeatLeaseIndex -ge 0 -and $heartbeatLeaseIndex -lt $missingPrerequisiteHeartbeatIndex) `
    -Message "Editor heartbeat must keep the lease alive while Play-mode maintenance is suspended."
foreach ($forbiddenMainThreadCall in @(
    "PublishLease(",
    "RefreshEditorLeaseForIntegrationState(",
    "BackendNeedsReconcile(",
    "AICodedbHostGenerationStore.Resolve(",
    "AICodedbHostPayloadMaterializer.",
    "AICodedbActions.RunEnsureWatcher("
)) {
    Assert-True `
        -Condition ($editorUpdateFunction.Groups["body"].Value.IndexOf($forbiddenMainThreadCall, [StringComparison]::Ordinal) -lt 0) `
        -Message "Editor heartbeat directly invokes main-thread work: $forbiddenMainThreadCall"
}
$boundaryCancellationFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+void\s+CancelBackgroundMaintenanceForBoundary\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*internal\s+static\s+AICodedbSupervisorSnapshot')
Assert-True -Condition $boundaryCancellationFunction.Success -Message "Package boundary could not isolate lifecycle boundary cancellation."
Assert-True `
    -Condition ($boundaryCancellationFunction.Groups["body"].Value.IndexOf("AICodedbProcessRunner.CancelBackgroundProcesses(", [StringComparison]::Ordinal) -lt 0) `
    -Message "Play/domain-reload cancellation must not synchronously inspect or kill processes."
$quittingFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+void\s+OnEditorQuitting\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+static\s+void\s+OnBeforeAssemblyReload')
Assert-True -Condition $quittingFunction.Success -Message "Package boundary could not isolate Editor quitting callback."
Assert-True `
    -Condition ($quittingFunction.Groups["body"].Value.IndexOf("QueueEditorLeaseDeletion(", [StringComparison]::Ordinal) -ge 0 -and
        $quittingFunction.Groups["body"].Value.IndexOf("QueueOwnedSupervisorShutdown(", [StringComparison]::Ordinal) -ge 0 -and
        $quittingFunction.Groups["body"].Value.IndexOf("DeleteEditorLease(", [StringComparison]::Ordinal) -lt 0) `
    -Message "Editor quitting must queue lease deletion and authenticated Supervisor shutdown without filesystem I/O inline."
$schedulerSuspensionFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)internal\s+void\s+SetMaintenanceSuspended\s*\(\s*bool\s+suspended\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*internal\s+Task<T>\s+QueueMaintenance')
Assert-True -Condition $schedulerSuspensionFunction.Success -Message "Package boundary could not isolate scheduler suspension."
Assert-True `
    -Condition ($schedulerSuspensionFunction.Groups["body"].Value.IndexOf("CancelMaintenance(", [StringComparison]::Ordinal) -ge 0 -and
        $editorLifecycleSource.IndexOf("QueueProcessCancellation(", [StringComparison]::Ordinal) -lt 0 -and
        $editorLifecycleSource.IndexOf("AICodedbProcessRunner.CancelBackgroundProcesses", [StringComparison]::Ordinal) -lt 0) `
    -Message "Scheduler suspension must cancel Unity-side tokens without retaining a process-kill route."
$playCallbackFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+void\s+OnPlayModeStateChanged\s*\(.*?\)\s*\{(?<body>.*?)\r?\n\s*private\s+static\s+void\s+OnEditorQuitting')
Assert-True -Condition $playCallbackFunction.Success -Message "Package boundary could not isolate the Play-mode callback."
Assert-True `
    -Condition ($playCallbackFunction.Groups["body"].Value.IndexOf("SupervisorBridge.Invalidate(", [StringComparison]::Ordinal) -lt 0 -and
        $playCallbackFunction.Groups["body"].Value.IndexOf("QueueSupervisorReconnect(false)", [StringComparison]::Ordinal) -ge 0) `
    -Message "Play mode must preserve the healthy Bridge and permit stable-Play reconnect."
foreach ($forbiddenBoundaryIo in @(
    "AICodedbPaths.CaptureExecutionContext(",
    "AICodedbHostPayloadMaterializer.",
    "AICodedbHostGenerationStore.Resolve(",
    "Process.",
    "File.",
    "Directory.",
    "PackageInfo."
)) {
    Assert-True `
        -Condition ($playCallbackFunction.Groups["body"].Value.IndexOf($forbiddenBoundaryIo, [StringComparison]::Ordinal) -lt 0) `
        -Message "Play-mode callback still performs synchronous CodeDB work: $forbiddenBoundaryIo"
}
$reloadCallbackFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+void\s+OnBeforeAssemblyReload\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+static\s+async\s+void\s+BeginReconcile')
Assert-True -Condition $reloadCallbackFunction.Success -Message "Package boundary could not isolate the assembly-reload callback."
foreach ($forbiddenBoundaryIo in @(
    "AICodedbHostPayloadMaterializer.",
    "AICodedbHostGenerationStore.Resolve(",
    "Process.",
    "File.",
    "Directory.",
    "PackageInfo."
)) {
    Assert-True `
        -Condition ($reloadCallbackFunction.Groups["body"].Value.IndexOf($forbiddenBoundaryIo, [StringComparison]::Ordinal) -lt 0) `
        -Message "Assembly-reload callback still performs synchronous CodeDB work: $forbiddenBoundaryIo"
}
$reconcileWorkerFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)private\s+static\s+LifecycleReconcileResult\s+RunReconcileWorker\s*\(.*?\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+static')
Assert-True -Condition $reconcileWorkerFunction.Success -Message "Package boundary could not isolate Editor lifecycle reconcile worker."
$supervisorProbeIndex = $reconcileWorkerFunction.Groups["body"].Value.IndexOf(
    'RunSupervisorCommand(context, "materialize", "Probe"',
    [StringComparison]::Ordinal)
$supervisorRecoveryIndex = $reconcileWorkerFunction.Groups["body"].Value.IndexOf(
    "RecoverCurrentInstanceAvailability(",
    [StringComparison]::Ordinal)
$supervisorWatcherIndex = $editorLifecycleSource.IndexOf(
    'RunSupervisorCommand(context, "watcher", "Ensure"',
    [StringComparison]::Ordinal)
$prerequisiteLeaseGateIndex = $reconcileWorkerFunction.Groups["body"].Value.IndexOf(
    "ApplyPrerequisiteGatedLeaseRefresh(",
    [StringComparison]::Ordinal)
Assert-True `
    -Condition ($supervisorProbeIndex -ge 0 -and $prerequisiteLeaseGateIndex -gt $supervisorProbeIndex) `
    -Message "Editor lifecycle must obtain a Supervisor-backed prerequisite/status observation before any lease publication gate."
Assert-True `
    -Condition ($supervisorRecoveryIndex -ge 0 -and $supervisorWatcherIndex -ge 0) `
    -Message "Editor lifecycle must route watcher maintenance through the project-local Supervisor."
$actionsSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Editor\AICodedbActions.cs"))
$supervisorWatcherCommandFunction = [regex]::Match(
    $actionsSource,
    '(?s)private\s+static\s+AICodedbCommandResult\s+RunSupervisorWatcherCommandSync\s*\(.*?\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*///')
Assert-True -Condition $supervisorWatcherCommandFunction.Success -Message "Package boundary could not isolate the explicit Supervisor watcher command route."
$explicitWatcherLeaseIndex = $supervisorWatcherCommandFunction.Groups["body"].Value.IndexOf(
    "TryPrepareCurrentEditorLease(",
    [StringComparison]::Ordinal)
$explicitWatcherSupervisorIndex = $supervisorWatcherCommandFunction.Groups["body"].Value.IndexOf(
    "RunSupervisorCommandAsync(",
    [StringComparison]::Ordinal)
Assert-True `
    -Condition ($explicitWatcherLeaseIndex -ge 0 -and $explicitWatcherSupervisorIndex -gt $explicitWatcherLeaseIndex) `
    -Message "Explicit watcher controls must publish the prerequisite-gated Editor lease before Supervisor admission."
$supervisorBridgeSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Editor\AICodedbSupervisorBridge.cs"))
Assert-True `
    -Condition ($supervisorBridgeSource.IndexOf("SendCommandAsync(", [StringComparison]::Ordinal) -ge 0 -and
        $supervisorBridgeSource.IndexOf("AICodedbStrictJson.ReadObject(", [StringComparison]::Ordinal) -ge 0) `
    -Message "Supervisor Bridge must use asynchronous IPC and strict JSON evidence."
Assert-True `
    -Condition ([regex]::IsMatch(
            $supervisorBridgeSource,
            '(?s)RequestOwnedShutdownAsync\s*\(.*?SendCommandWorker\s*\(.*?CancellationToken\.None,\s*false(?:,\s*false)?\s*\)') -and
        $supervisorBridgeSource.IndexOf("if (!startIfMissing)", [StringComparison]::Ordinal) -ge 0) `
    -Message "Final Editor shutdown must authenticate an existing Supervisor without launching a missing runtime."
$supervisorLifecycleSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Editor\AICodedbEditorLifecycle.cs"))
Assert-True `
    -Condition ($supervisorLifecycleSource.IndexOf("IsSupervisorOneShotFallbackAllowed(", [StringComparison]::Ordinal) -ge 0) `
    -Message "Supervisor fallback must be explicitly bounded to reviewed one-shot outage/bootstrap conditions."
$managerSource = [System.IO.File]::ReadAllText((Join-Path $packageRoot "Editor\AICodedbManagerWindow.cs"))
$managerEnableFunction = [regex]::Match(
    $managerSource,
    '(?s)private\s+void\s+OnEnable\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+void\s+OnDisable')
Assert-True -Condition $managerEnableFunction.Success -Message "Package boundary could not isolate Manager OnEnable."
foreach ($forbiddenManagerOpenCall in @(
    "RefreshTransientHostStatusAsync(",
    "AICodedbHostPayloadMaterializer.",
    "RunPowerShellScript(",
    "BeginStatusRefresh(true)"
)) {
    Assert-True `
        -Condition ($managerEnableFunction.Groups["body"].Value.IndexOf($forbiddenManagerOpenCall, [StringComparison]::Ordinal) -lt 0) `
        -Message "Manager opening must not launch synchronous or duplicate CodeDB work: $forbiddenManagerOpenCall"
}
$managerBeginRefreshFunction = [regex]::Match(
    $managerSource,
    '(?s)private\s+void\s+BeginStatusRefresh\s*\(\s*bool\s+force\s*=\s*false\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+bool\s+TryApplyCachedLifecycleStatus')
Assert-True -Condition $managerBeginRefreshFunction.Success -Message "Package boundary could not isolate Manager status refresh scheduling."
Assert-True `
    -Condition ($managerBeginRefreshFunction.Groups["body"].Value.IndexOf("if (!force)", [StringComparison]::Ordinal) -ge 0 -and
        $managerBeginRefreshFunction.Groups["body"].Value.IndexOf("RefreshTransientHostStatusAsync()", [StringComparison]::Ordinal) -ge 0) `
    -Message "Manager status refresh must reserve direct materializer launch for explicit force refresh."
$managerTransientRefreshFunction = [regex]::Match(
    $managerSource,
    '(?s)private\s+void\s+ObserveTransientHostStatus\s*\(\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*private\s+async\s+void\s+RefreshTransientHostStatusAsync')
Assert-True -Condition $managerTransientRefreshFunction.Success -Message "Package boundary could not isolate Manager transient status observation."
Assert-True `
    -Condition ($managerTransientRefreshFunction.Groups["body"].Value.IndexOf("AICodedbEditorLifecycle.RequestBackgroundStatusObservation()", [StringComparison]::Ordinal) -ge 0) `
    -Message "Play-mode transient refresh must request the Lifecycle worker."
foreach ($forbiddenTransientRefreshCall in @(
    "BeginStatusRefresh(true)",
    "RefreshTransientHostStatusAsync()"
)) {
    Assert-True `
        -Condition ($managerTransientRefreshFunction.Groups["body"].Value.IndexOf($forbiddenTransientRefreshCall, [StringComparison]::Ordinal) -lt 0) `
        -Message "Play-mode transient refresh must not launch a second status process: $forbiddenTransientRefreshCall"
}
$lifecycleObservationFunction = [regex]::Match(
    $editorLifecycleSource,
    '(?s)internal\s+static\s+void\s+RequestBackgroundStatusObservation\s*\(\s*bool\s+force\s*\)\s*\{(?<body>.*?)\r?\n\s*\}\r?\n\r?\n\s*internal\s+static\s+bool\s+IsLifecycleInitialized')
Assert-True -Condition $lifecycleObservationFunction.Success -Message "Package boundary could not isolate Lifecycle status observation."
Assert-True `
    -Condition ($lifecycleObservationFunction.Groups["body"].Value.IndexOf("QueueSupervisorReconnect(force)", [StringComparison]::Ordinal) -ge 0) `
    -Message "Manager status observation must use the Supervisor query/reconnect lane."
foreach ($forbiddenObservationMutation in @(
    "BeginReconcile(",
    "_nextReconcileAt"
)) {
    Assert-True `
        -Condition ($lifecycleObservationFunction.Groups["body"].Value.IndexOf($forbiddenObservationMutation, [StringComparison]::Ordinal) -lt 0) `
        -Message "Manager status observation must not trigger or reschedule lifecycle mutation: $forbiddenObservationMutation"
}
$editorMaterializerSource = Get-Content -LiteralPath (Join-Path $packageRoot "Editor\AICodedbHostPayloadMaterializer.cs") -Raw
Assert-True `
    -Condition ([regex]::IsMatch($editorMaterializerSource, 'RunRedeploy\s*\(\s*bool\s+confirmedProjectMutation\s*\)')) `
    -Message "Editor Redeploy must require an explicit second-level confirmation credential."
$editorConfirmationFunction = [regex]::Match(
    $editorMaterializerSource,
    '(?s)private\s+static\s+bool\s+RequiresConfirmation\s*\([^)]*\)\s*\{(?<body>.*?)\}')
Assert-True -Condition $editorConfirmationFunction.Success -Message "Package boundary could not isolate the Editor confirmation gate."
foreach ($confirmedAction in @("Redeploy", "Uninstall", "Install")) {
    Assert-True `
        -Condition ($editorConfirmationFunction.Groups["body"].Value.IndexOf("AICodedbHostPayloadAction.$confirmedAction", [StringComparison]::Ordinal) -ge 0) `
        -Message "Editor $confirmedAction is missing from the second-level confirmation gate."
}
Assert-True `
    -Condition ([regex]::IsMatch($materializerSource, 'ValidateSet\("Redeploy",\s*"Sync",\s*"Remove",\s*"Repair",\s*"Reinstall",\s*"Uninstall",\s*"Install"\)\]\[string\]\$MutationAction')) `
    -Message "PowerShell user mutations are missing from the second-level confirmation contract."
$materializerTokens = $null
$materializerParseErrors = $null
$materializerAst = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $packageRoot "Tools~\materialize-codedb-host-payload.ps1"),
    [ref]$materializerTokens,
    [ref]$materializerParseErrors)
Assert-Equal -Actual $materializerParseErrors.Count -Expected 0 -Label "Materializer AST parse errors"
$confirmationDispatchGates = @($materializerAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.IfStatementAst] -and
        $node.Extent.Text.IndexOf('$Action -in @("Redeploy", "Sync", "Remove", "Repair", "Reinstall", "Uninstall", "Install")', [StringComparison]::Ordinal) -ge 0 -and
        $node.Extent.Text.IndexOf('Assert-MutationConfirmation -Root $projectRootPath -Manifest $payload -MutationAction $Action', [StringComparison]::Ordinal) -ge 0
}, $true))
Assert-True `
    -Condition ($confirmationDispatchGates.Count -eq 1) `
    -Message "PowerShell user mutations do not enter the confirmation gate before dispatch."

if ($hashMismatches.Count -gt 0) {
    throw "Payload hash validation failed:`n - $($hashMismatches -join "`n - ")"
}

Write-Host "[OK] Standalone CodeDB package boundary passed."
