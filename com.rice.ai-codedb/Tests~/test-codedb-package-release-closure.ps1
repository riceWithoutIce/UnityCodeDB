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
$payloadRoot = Join-Path $root "Payload~"
$payloadManifestPath = Join-Path $payloadRoot "payload-manifest.json"
$hostCurrentPath = Join-Path $payloadRoot "host-current.json"
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
}

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

Write-Output ("[PACKAGE_CLOSURE] PASS source_count={0} mismatch_count=0 generation_hash={1} host_current_hash={2}" -f $sourceCount, $generationHash, $hostHash)
