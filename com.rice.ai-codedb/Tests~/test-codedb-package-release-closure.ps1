#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$PackageRoot = (Join-Path $PSScriptRoot ".."),
    [switch]$RepairCanonicalMetadata,
    [string]$SuccessorGenerationId = ''
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

function ConvertTo-InstanceConsumerProjection {
    param([string]$Text, [ValidateSet('common', 'worker')][string]$Kind)
    if ($Kind -eq 'common') {
        $binding = '. (Join-Path $PSScriptRoot "..\shared\codedb-machine-provider-contract.ps1")'
        Assert-Closure ($Text.Split(@($binding), [StringSplitOptions]::None).Length -eq 2) 'Common Provider binding is not unique.'
        $Text = $Text.Replace($binding, $binding + "`n" + '. (Join-Path $PSScriptRoot "..\shared\codedb-instance-manifest-contract.ps1")')
        $decoder = 'return ConvertFrom-CodedbProviderManifestJson -Text $text -Label $Label'
        Assert-Closure ($Text.Split(@($decoder), [StringSplitOptions]::None).Length -eq 2) 'Common instance decoder binding is not unique.'
        $Text = $Text.Replace($decoder, 'return ConvertFrom-CodedbInstanceManifestJson -Text $text -Label $Label')
        $oldAdmission = '(?ms)^    \$expectedNames = @\(\r?\n.*?^    }\r?\n'
        Assert-Closure ([regex]::Matches($Text, $oldAdmission).Count -eq 1) 'Common instance field admission is not unique.'
        $Text = [regex]::Replace($Text, $oldAdmission, "    Assert-CodedbInstanceManifestFields -Properties `$manifest`n")
        # Provider accessors outside the instance context retain their own contract.
        $tokens = $null; $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
        Assert-Closure ($errors.Count -eq 0) 'Projected common source does not parse.'
        $context = @($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -ceq 'Assert-CodedbInstanceContext' })
        Assert-Closure ($context.Count -eq 1) 'Common instance context is not unique.'
        $body = $context[0].Extent.Text
        $projected = $body.Replace('Get-CodedbProviderManifestString', 'Get-CodedbInstanceManifestString').Replace('Get-CodedbProviderManifestInt32', 'Get-CodedbInstanceManifestInt32')
        return $Text.Replace($body, $projected)
    }
    $binding = 'import { GENERATION_CONTRACT } from "../shared/codedb-host-use-gate.mjs";'
    Assert-Closure ($Text.Split(@($binding), [StringSplitOptions]::None).Length -eq 2) 'Worker generation binding is not unique.'
    $Text = $Text.Replace($binding, $binding + "`n" + 'import { parseCodedbInstanceManifest } from "../shared/codedb-instance-manifest-contract.mjs";')
    $decoder = 'const instance = parseStrictFlatJson(instanceText, "CodeDB instance manifest");'
    Assert-Closure ($Text.Split(@($decoder), [StringSplitOptions]::None).Length -eq 2) 'Worker instance decoder binding is not unique.'
    return $Text.Replace($decoder, 'const instance = parseCodedbInstanceManifest(instanceText, "CodeDB instance manifest");')
}

function New-CanonicalSuccessorGeneration {
    param([string]$Root, $Payload, $HostCurrent, $Generation, [string]$Identity)
    Assert-Closure ($Identity -cmatch '^poc\.([0-9]+)$') 'Successor generation identity is invalid.'
    $sequence = [int]$Matches[1]
    Assert-Closure ($sequence -eq ([int]$Payload.payload_sequence + 1)) 'Successor must be the next canonical sequence.'
    Assert-Closure ([string]$Payload.generation_id -ceq [string]$Generation.generation_id) 'Source generation identity drifted.'
    $payloadRoot = Join-Path $Root 'Payload~'
    $priorRoot = Join-Path $payloadRoot ('Generations\' + [string]$Payload.generation_id)
    $nextRoot = Join-Path $payloadRoot ('Generations\' + $Identity)
    Assert-Closure (-not (Test-Path -LiteralPath $nextRoot)) 'Successor generation already exists; refusing overwrite.'
    $canonicalShared = Join-Path $payloadRoot 'AIWork\codedb\shared'
    $helpers = @('codedb-strict-json.ps1', 'codedb-instance-manifest-contract.ps1', 'codedb-instance-manifest-contract.mjs')
    foreach ($helper in $helpers) {
        Assert-Closure (Test-Path -LiteralPath (Join-Path $canonicalShared $helper) -PathType Leaf) "Missing canonical instance helper: $helper"
    }
    $sourceFiles = @(Get-ChildItem -LiteralPath $priorRoot -Recurse -File)
    Assert-Closure (@($sourceFiles | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -eq 0) 'Source generation contains a reparse file.'
    Assert-Closure (@(Get-ChildItem -LiteralPath $priorRoot -Recurse -Directory | Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 }).Count -eq 0) 'Source generation contains a reparse directory.'
    # Produce both changed consumer bodies before any successor write.
    $common = ConvertTo-InstanceConsumerProjection -Text ([IO.File]::ReadAllText((Join-Path $priorRoot 'scripts\codedb-project-common.ps1'))) -Kind common
    $worker = ConvertTo-InstanceConsumerProjection -Text ([IO.File]::ReadAllText((Join-Path $priorRoot 'wrapper\codedb-project-instance-worker.mjs'))) -Kind worker
    $oldGenerationId = [string]$Payload.generation_id
    # Read the existing marker compatibility constants from their production authority.
    $tokens = $null; $errors = $null
    $materializer = [Management.Automation.Language.Parser]::ParseFile((Join-Path $Root 'Tools~\materialize-codedb-host-payload.ps1'), [ref]$tokens, [ref]$errors)
    Assert-Closure ($errors.Count -eq 0) 'Canonical marker source failed parse.'
    $versions = @{}
    foreach ($name in @('MarkerSchemaVersion', 'HostUseGateVersion')) {
        $assignment = @($materializer.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -ceq ('$script:' + $name) })
        Assert-Closure ($assignment.Count -eq 1 -and $assignment[0].Right.Extent.Text.Trim() -cmatch '^[0-9]+$') "Canonical $name is not one integer constant."
        $versions[$name] = [int]$assignment[0].Right.Extent.Text.Trim()
    }
    $markerWriter = @($materializer.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -ceq 'New-MarkerJson' })
    $leaseVersion = [regex]::Matches($markerWriter[0].Extent.Text, '(?m)^\s*generation_lease_version = ([0-9]+)\s*$')
    Assert-Closure ($markerWriter.Count -eq 1 -and $leaseVersion.Count -eq 1) 'Canonical generation lease version is not one integer constant.'
    $versions.GenerationLeaseVersion = [int]$leaseVersion[0].Groups[1].Value
    $flat = @($Payload.files | Where-Object { ([string]$_.target).StartsWith('AIWork/codedb/', [StringComparison]::Ordinal) })
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($line in @("schema_version=$($versions.MarkerSchemaVersion)", "managed_by=$($Payload.managed_by)", "package_version=$($Payload.package_version)",
        "payload_version=$($Payload.payload_version)", "payload_sequence=$($Payload.payload_sequence)",
        "host_use_gate_version=$($versions.HostUseGateVersion)", "generation_lease_version=$($versions.GenerationLeaseVersion)",
        "generation_id=$oldGenerationId", "bootstrap_protocol=$($Payload.bootstrap_protocol)")) { $lines.Add($line) }
    [string[]]$flatTargets = @($flat | ForEach-Object { [string]$_.target }); [Array]::Sort($flatTargets, [StringComparer]::Ordinal)
    foreach ($target in $flatTargets) {
        $entry = @($flat | Where-Object { [string]$_.target -ceq $target })[0]
        $lines.Add("file=$target`:$($entry.sha256)")
    }
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { $flatHash = [BitConverter]::ToString($algorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes(($lines -join "`n") + "`n"))).Replace('-', '').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
    $oldWrapper = @($flat | Where-Object { [string]$_.target -ceq 'AIWork/codedb/wrapper/codedb-project-wrapper.mjs' })
    Assert-Closure ($oldWrapper.Count -eq 1) 'Source stable-wrapper hash is not unique.'
    Assert-Closure (@($Payload.bootstrap_transitions | Where-Object { [string]$_.source_generation_id -ceq $oldGenerationId }).Count -eq 0) 'Source generation transition is already declared.'
    $transition = [ordered]@{
        source_tag = 'v' + [string]$Payload.package_version; source_package_version = [string]$Payload.package_version
        source_payload_version = [string]$Payload.payload_version; source_payload_sequence = [int]$Payload.payload_sequence
        source_generation_id = $oldGenerationId; source_bootstrap_protocol = [int]$Payload.bootstrap_protocol
        source_marker_schema_version = $versions.MarkerSchemaVersion; source_host_use_gate_version = $versions.HostUseGateVersion
        source_generation_lease_version = $versions.GenerationLeaseVersion; source_flat_file_count = $flat.Count
        source_flat_closure_sha256 = $flatHash; source_stable_wrapper_sha256 = [string]$oldWrapper[0].sha256
    }
    New-Item -ItemType Directory -Path $nextRoot | Out-Null
    foreach ($file in $sourceFiles) {
        $relative = $file.FullName.Substring($priorRoot.Length + 1)
        if ($relative -ceq 'generation-manifest.json') { continue }
        $target = Join-Path $nextRoot $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $target
    }
    [IO.File]::WriteAllText((Join-Path $nextRoot 'scripts\codedb-project-common.ps1'), $common, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $nextRoot 'wrapper\codedb-project-instance-worker.mjs'), $worker, [Text.UTF8Encoding]::new($false))
    foreach ($helper in $helpers) { Copy-Item -LiteralPath (Join-Path $canonicalShared $helper) -Destination (Join-Path $nextRoot ('shared\' + $helper)) }
    $Generation.generation_id = $Identity; $Generation.payload_version = $Identity; $Generation.payload_sequence = $sequence
    $generationFiles = [Collections.Generic.List[object]]::new()
    [string[]]$paths = @(Get-ChildItem -LiteralPath $nextRoot -Recurse -File | ForEach-Object { $_.FullName.Substring($nextRoot.Length + 1).Replace('\', '/') })
    [Array]::Sort($paths, [StringComparer]::Ordinal)
    foreach ($relative in $paths) { $generationFiles.Add([ordered]@{ path = $relative; sha256 = Get-Sha256 -Path (Join-Path $nextRoot $relative) }) }
    $Generation.files = $generationFiles.ToArray()
    Write-CanonicalJson -Path (Join-Path $nextRoot 'generation-manifest.json') -Value $Generation
    $Payload.generation_id = $Identity; $Payload.payload_version = $Identity; $Payload.payload_sequence = $sequence
    $Payload.bootstrap_transitions = @($Payload.bootstrap_transitions) + @($transition)
    $HostCurrent.generation_id = $Identity; $HostCurrent.payload_version = $Identity; $HostCurrent.payload_sequence = $sequence
    $HostCurrent.generation_relative_path = 'AIWork/.runtime/codedb/host/generations/' + $Identity
    $allFiles = [Collections.Generic.List[object]]::new()
    [string[]]$sources = @(
        Get-ChildItem -LiteralPath (Join-Path $payloadRoot 'AIWork\codedb') -Recurse -File | ForEach-Object { $_.FullName.Substring($payloadRoot.Length + 1).Replace('\', '/') }
        Get-ChildItem -LiteralPath $nextRoot -Recurse -File | ForEach-Object { $_.FullName.Substring($payloadRoot.Length + 1).Replace('\', '/') }
        'host-current.json'
    )
    [Array]::Sort($sources, [StringComparer]::Ordinal)
    foreach ($source in $sources) {
        $target = if ($source.StartsWith('Generations/' + $Identity + '/', [StringComparison]::Ordinal)) {
            'AIWork/.runtime/codedb/host/generations/' + $Identity + '/' + $source.Substring(('Generations/' + $Identity + '/').Length)
        } elseif ($source -ceq 'host-current.json') { 'AIWork/.runtime/codedb/host/current.json' } else { $source }
        $allFiles.Add([ordered]@{ source = $source; target = $target; sha256 = Get-Sha256 -Path (Join-Path $payloadRoot $source) })
    }
    $Payload.files = $allFiles.ToArray()
    return (Join-Path $nextRoot 'generation-manifest.json')
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

if (-not [string]::IsNullOrEmpty($SuccessorGenerationId)) {
    Assert-Closure ([bool]$RepairCanonicalMetadata) 'Successor creation requires the canonical metadata route.'
    $generationPath = New-CanonicalSuccessorGeneration -Root $root -Payload $payload -HostCurrent $hostCurrent -Generation $generation -Identity $SuccessorGenerationId
    $generationId = [string]$payload.generation_id
}

if ($RepairCanonicalMetadata) {
    Repair-CanonicalMetadata -Root $root -Payload $payload -HostCurrent $hostCurrent -Generation $generation `
        -PayloadManifestPath $payloadManifestPath -HostCurrentPath $hostCurrentPath -GenerationPath $generationPath
    $payload = Read-JsonObject -Path $payloadManifestPath
    $hostCurrent = Read-JsonObject -Path $hostCurrentPath
    $generation = Read-JsonObject -Path $generationPath
    $runtimeIdentityFixture = Read-JsonObject -Path $runtimeIdentityFixturePath
    foreach ($name in @('generation_id', 'target_generation_id', 'selected_generation_id')) {
        $runtimeIdentityFixture.status.$name = [string]$payload.generation_id
    }
    foreach ($name in @('target_generation_id', 'selected_generation_id')) {
        $runtimeIdentityFixture.status.operational_readiness.$name = [string]$payload.generation_id
    }
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
