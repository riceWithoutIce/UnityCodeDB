#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$PackageRoot = (Join-Path $PSScriptRoot ".."),
    [switch]$RepairCanonicalMetadata
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Closure {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)
    if (-not $Condition) { throw $Message }
}

function Safe-RelativePath {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Label)
    Assert-Closure (-not [string]::IsNullOrWhiteSpace($Path)) "$Label is empty."
    Assert-Closure (-not [IO.Path]::IsPathRooted($Path)) "$Label is rooted: $Path"
    $normalized = $Path.Replace('\', '/')
    foreach ($segment in $normalized.Split('/')) {
        Assert-Closure ($segment -notin @('', '.', '..')) "$Label contains an invalid segment: $Path"
    }
    return $normalized
}

function Read-JsonObject {
    param([Parameter(Mandatory = $true)][string]$Path)
    Assert-Closure (Test-Path -LiteralPath $Path -PathType Leaf) "Missing JSON metadata: $Path"
    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop)
}

function Write-CanonicalJson {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)]$Value)
    $json = $Value | ConvertTo-Json -Depth 100
    $canonical = $json.Replace("`r`n", "`n").Replace("`r", "`n") + "`n"
    [IO.File]::WriteAllText($Path, $canonical, (New-Object Text.UTF8Encoding($false)))
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Assert-EqualValue {
    param(
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$Label
    )
    Assert-Closure ([string]::Equals([string]$Actual, [string]$Expected, [StringComparison]::Ordinal)) `
        "$Label mismatch. Expected '$Expected', got '$Actual'."
}

function Get-ControlContractSha256 {
    param(
        [Parameter(Mandatory = $true)][string]$ManagedBy,
        [Parameter(Mandatory = $true)]$ControlContract
    )
    $canonical = [string]::Join("`n", @(
        $ManagedBy,
        "control-contract",
        [string]$ControlContract.id,
        ([int]$ControlContract.version).ToString([Globalization.CultureInfo]::InvariantCulture),
        ([int]$ControlContract.schema_version).ToString([Globalization.CultureInfo]::InvariantCulture)
    ))
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString(
            $algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical))).Replace("-", "").ToLowerInvariant()
    } finally {
        $algorithm.Dispose()
    }
}

function Repair-CanonicalMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Payload,
        [Parameter(Mandatory = $true)]$HostCurrent,
        [Parameter(Mandatory = $true)]$Generation,
        [Parameter(Mandatory = $true)][string]$PayloadManifestPath,
        [Parameter(Mandatory = $true)][string]$HostCurrentPath,
        [Parameter(Mandatory = $true)][string]$GenerationPath
    )

    Write-CanonicalJson -Path $GenerationPath -Value $Generation
    $generationHash = Get-Sha256 -Path $GenerationPath
    $HostCurrent.generation_manifest_sha256 = $generationHash
    Write-CanonicalJson -Path $HostCurrentPath -Value $HostCurrent
    $hostHash = Get-Sha256 -Path $HostCurrentPath

    foreach ($entry in @($Payload.files)) {
        if ([string]::Equals([string]$entry.source, "Generations/$($Generation.generation_id)/generation-manifest.json", [StringComparison]::Ordinal)) {
            $entry.sha256 = $generationHash
        } elseif ([string]::Equals([string]$entry.source, "host-current.json", [StringComparison]::Ordinal)) {
            $entry.sha256 = $hostHash
        }
    }
    Write-CanonicalJson -Path $PayloadManifestPath -Value $Payload
}

$root = [IO.Path]::GetFullPath($PackageRoot)
$packageManifestPath = Join-Path $root "package.json"
$payloadRoot = Join-Path $root "Payload~"
$payloadManifestPath = Join-Path $payloadRoot "payload-manifest.json"
$hostCurrentPath = Join-Path $payloadRoot "host-current.json"
$runtimeIdentityFixturePath = Join-Path $root "Tests\Editor\OwnerIdentityV2Status.json"
$package = Read-JsonObject -Path $packageManifestPath
$payload = Read-JsonObject -Path $payloadManifestPath
$hostCurrent = Read-JsonObject -Path $hostCurrentPath
$generationId = [string]$payload.generation_id
$generationPath = Join-Path $payloadRoot ("Generations\$generationId\generation-manifest.json")
$generation = Read-JsonObject -Path $generationPath

if ($RepairCanonicalMetadata) {
    Repair-CanonicalMetadata -Root $root -Payload $payload -HostCurrent $hostCurrent -Generation $generation `
        -PayloadManifestPath $payloadManifestPath -HostCurrentPath $hostCurrentPath -GenerationPath $generationPath
    $payload = Read-JsonObject -Path $payloadManifestPath
    $hostCurrent = Read-JsonObject -Path $hostCurrentPath
    $generation = Read-JsonObject -Path $generationPath
    $runtimeIdentityFixture = Read-JsonObject -Path $runtimeIdentityFixturePath
    $runtimeContractHash = Get-Sha256 -Path $payloadManifestPath
    $runtimeIdentityFixture.status.runtime_contract_sha256 = $runtimeContractHash
    $runtimeIdentityFixture.status.operational_readiness.runtime_contract_sha256 = $runtimeContractHash
    Write-CanonicalJson -Path $runtimeIdentityFixturePath -Value $runtimeIdentityFixture
}

Assert-EqualValue $package.name $payload.managed_by "Package owner"
Assert-EqualValue $package.version $payload.package_version "Package version"
Assert-EqualValue $payload.schema_version 1 "Payload schema"
Assert-EqualValue $payload.owner_identity_version 2 "Owner identity version"
Assert-Closure ($null -ne $payload.control_contract) "Payload control contract is missing."
Assert-EqualValue $payload.control_contract.schema_version 1 "Control contract schema"
Assert-Closure ([int]$payload.control_contract.version -gt 0) "Control contract version is invalid."
Assert-Closure ([string]$payload.control_contract.id -match '^[A-Za-z0-9._-]{1,64}$') "Control contract id is invalid."
$controlContractHash = Get-ControlContractSha256 -ManagedBy ([string]$package.name) -ControlContract $payload.control_contract
Assert-EqualValue ([string]$payload.control_contract.sha256).ToLowerInvariant() $controlContractHash "Control contract hash"

foreach ($identityDocument in @(
    [pscustomobject]@{ Label = "Host-current"; Value = $hostCurrent },
    [pscustomobject]@{ Label = "Generation manifest"; Value = $generation }
)) {
    Assert-EqualValue $identityDocument.Value.schema_version 1 "$($identityDocument.Label) schema"
    Assert-EqualValue $identityDocument.Value.managed_by $payload.managed_by "$($identityDocument.Label) owner"
    Assert-EqualValue $identityDocument.Value.package_version $payload.package_version "$($identityDocument.Label) package version"
    Assert-EqualValue $identityDocument.Value.payload_version $payload.payload_version "$($identityDocument.Label) payload version"
    Assert-EqualValue ([int]$identityDocument.Value.payload_sequence) ([int]$payload.payload_sequence) "$($identityDocument.Label) payload sequence"
    Assert-EqualValue $identityDocument.Value.generation_id $payload.generation_id "$($identityDocument.Label) generation id"
    Assert-EqualValue ([int]$identityDocument.Value.bootstrap_protocol) ([int]$payload.bootstrap_protocol) "$($identityDocument.Label) bootstrap protocol"
}
$expectedGenerationRelativePath = "AIWork/.runtime/codedb/host/generations/$generationId"
Assert-EqualValue $hostCurrent.generation_relative_path $expectedGenerationRelativePath "Host-current generation path"

$declaredSources = @{}
$declaredTargets = @{}
$mismatches = New-Object System.Collections.Generic.List[string]
$sourceCount = 0
foreach ($entry in @($payload.files)) {
    $source = Safe-RelativePath ([string]$entry.source) "Payload source"
    $target = Safe-RelativePath ([string]$entry.target) "Payload target"
    Assert-Closure (-not $declaredSources.ContainsKey($source)) "Duplicate payload source: $source"
    Assert-Closure (-not $declaredTargets.ContainsKey($target)) "Duplicate payload target: $target"
    $declaredSources[$source] = $true
    $declaredTargets[$target] = $true
    $sourcePath = Join-Path $payloadRoot ($source.Replace('/', '\'))
    Assert-Closure (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Payload source is missing: $source"
    $expected = ([string]$entry.sha256).ToLowerInvariant()
    Assert-Closure ($expected -match '^[0-9a-f]{64}$') "Payload hash is invalid: $source"
    $actual = Get-Sha256 -Path $sourcePath
    if ($actual -ne $expected) { $mismatches.Add("payload:$source expected=$expected actual=$actual") }
    $sourceCount++
}

$generationEntry = @($payload.files | Where-Object { [string]$_.source -eq "Generations/$generationId/generation-manifest.json" })
$hostEntry = @($payload.files | Where-Object { [string]$_.source -eq "host-current.json" })
Assert-Closure ($generationEntry.Count -eq 1) "Generation manifest payload entry count mismatch."
Assert-Closure ($hostEntry.Count -eq 1) "Host-current payload entry count mismatch."
$generationHash = Get-Sha256 -Path $generationPath
$hostHash = Get-Sha256 -Path $hostCurrentPath
Assert-Closure ([string]$generationEntry[0].sha256 -eq $generationHash) "Generation manifest cross-hash mismatch."
Assert-Closure ([string]$hostEntry[0].sha256 -eq $hostHash) "Host-current cross-hash mismatch."
Assert-Closure ([string]$hostCurrent.generation_manifest_sha256 -eq $generationHash) "Host-current generation hash mismatch."

Assert-Closure ([string]$generation.generation_id -eq [string]$payload.generation_id) "Generation identity mismatch."
Assert-Closure ([string]$generation.package_version -eq [string]$payload.package_version) "Generation package version mismatch."
Assert-Closure ([int]$generation.payload_sequence -eq [int]$payload.payload_sequence) "Generation sequence mismatch."
$runtimeContractHash = Get-Sha256 -Path $payloadManifestPath
$runtimeIdentityFixture = Read-JsonObject -Path $runtimeIdentityFixturePath
Assert-Closure ($null -ne $runtimeIdentityFixture.status) "Runtime identity fixture status is missing."
Assert-Closure ($null -ne $runtimeIdentityFixture.status.operational_readiness) "Runtime identity fixture operational readiness is missing."
Assert-EqualValue ([string]$runtimeIdentityFixture.status.runtime_contract_sha256).ToLowerInvariant() $runtimeContractHash "Runtime contract identity"
Assert-EqualValue ([string]$runtimeIdentityFixture.status.operational_readiness.runtime_contract_sha256).ToLowerInvariant() $runtimeContractHash "Operational runtime contract identity"
$generationSources = @($generation.files | ForEach-Object { Safe-RelativePath ([string]$_.path) "Generation file" })
foreach ($entry in @($generation.files)) {
    $relative = Safe-RelativePath ([string]$entry.path) "Generation file"
    $path = Join-Path $payloadRoot ("Generations\$generationId\" + $relative.Replace('/', '\'))
    Assert-Closure (Test-Path -LiteralPath $path -PathType Leaf) "Generation file missing: $relative"
    $actual = Get-Sha256 -Path $path
    if ($actual -ne ([string]$entry.sha256).ToLowerInvariant()) {
        $mismatches.Add("generation:$relative expected=$($entry.sha256) actual=$actual")
    }
}

$flatRoot = Join-Path $payloadRoot "AIWork\codedb"
$generationRoot = Join-Path $payloadRoot ("Generations\$generationId")
$actualSources = @(
    Get-ChildItem -LiteralPath $flatRoot -Recurse -File | ForEach-Object { $_.FullName.Substring($payloadRoot.Length + 1).Replace('\', '/') }
    Get-ChildItem -LiteralPath $generationRoot -Recurse -File | ForEach-Object { $_.FullName.Substring($payloadRoot.Length + 1).Replace('\', '/') }
    'host-current.json'
) | Sort-Object
Assert-Closure ((@($actualSources) -join '|') -eq (@($declaredSources.Keys | Sort-Object) -join '|')) "Payload source closure has missing or extra files."

if ($mismatches.Count -gt 0) {
    throw (($mismatches | Select-Object -First 20) -join "`n")
}

Write-Output ("[PACKAGE_CLOSURE] PASS source_count={0} mismatch_count=0 generation_hash={1} host_current_hash={2} runtime_contract_hash={3}" -f $sourceCount, $generationHash, $hostHash, $runtimeContractHash)
