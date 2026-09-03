#requires -Version 5.1

$script:InstanceSchemaVersion = 1
$script:InstanceControlRelativePath = "AIWork/.runtime/codedb/control"
$script:InstanceCurrentRelativePath = "$($script:InstanceControlRelativePath)/current-instance.json"
$script:InstanceLastKnownGoodRelativePath = "$($script:InstanceControlRelativePath)/last-known-good-instance.json"
$script:InstanceDesiredStateRelativePath = "$($script:InstanceControlRelativePath)/desired-state.json"
$script:InstanceOperationRelativePath = "$($script:InstanceControlRelativePath)/operation.json"
$script:InstanceOperationsRelativePath = "$($script:InstanceControlRelativePath)/operations"
$script:InstanceRetiredRelativePath = "$($script:InstanceControlRelativePath)/retired-instances"
$script:InstancesRelativePath = "AIWork/.runtime/codedb/instances"
$script:InstanceWorkerRelativePath = "wrapper/codedb-project-instance-worker.mjs"
$script:InstanceAvailabilityRelativePath = "logs/mcp-availability.json"
$script:InstanceRetiringFileName = "retiring.json"
$script:InstanceLeaseDirectoryName = "leases"
$script:InstanceAllowedDirectories = @("config", "index", "adapter", "watch", "leases", "logs", "tmp")
$script:InstanceOptionalDirectories = @("leases")
$script:InstanceControlContractSchemaVersion = 1
$script:InstanceActivationRecordSchemaVersion = 1
$script:InstanceActivationOperationSchemaVersion = 1
$script:InstanceActivationRecordMaximumBytes = 64 * 1024
$script:InstanceActivationOperationMaximumBytes = 1024 * 1024
$script:InstanceContractNamespaceRelativePath = "$($script:InstanceControlRelativePath)/contracts"

function Assert-InstanceJsonFieldAllowlist {
    param(
        [AllowNull()]$Object,
        [Parameter(Mandatory = $true)][string[]]$Fields,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $null = Assert-JsonObject -Value $Object -Label $Label
    $allowed = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($field in $Fields) { $null = $allowed.Add($field) }
    $properties = @($Object.PSObject.Properties)
    if ($properties.Count -ne $allowed.Count) {
        throw "$Label does not contain the exact field set."
    }
    foreach ($property in $properties) {
        if (-not $allowed.Contains($property.Name)) {
            throw "$Label contains an unsupported field: $($property.Name)"
        }
    }
}

function Assert-InstanceLowercaseSha256 {
    param(
        [AllowNull()]$Value,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowNull
    )

    if ($AllowNull -and $null -eq $Value) { return $null }
    if ($null -eq $Value -or $Value -cnotmatch '^[0-9a-f]{64}$') {
        throw "$Label must be a lowercase SHA-256."
    }
    return $Value
}

function Assert-InstanceAttemptId {
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($null -eq $Value -or $Value -cnotmatch '^[0-9a-f]{32}$') {
        throw "$Label must be a lowercase 32-hex identity."
    }
    return $Value
}

function Assert-InstanceUtcTimestamp {
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    [DateTimeOffset]$parsed = [DateTimeOffset]::MinValue
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [DateTimeOffset]::TryParse(
            $Value,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$parsed) -or
        $parsed.Offset -ne [TimeSpan]::Zero) {
        throw "$Label must be an unambiguous UTC timestamp."
    }
    return $Value
}

function Read-InstanceControlContractIdentity {
    param([Parameter(Mandatory = $true)]$ManifestDocument)

    $property = Get-ExactJsonProperty -Object $ManifestDocument -Name "control_contract" -Label "payload manifest"
    if ($null -eq $property) {
        throw "Payload manifest is missing required property: control_contract"
    }
    $document = Assert-JsonObject -Value $property.Value -Label "payload control contract"
    Assert-InstanceJsonFieldAllowlist `
        -Object $document `
        -Fields @("id", "version", "schema_version", "sha256") `
        -Label "payload control contract"
    $id = Get-RequiredJsonString -Object $document -Name "id" -Label "payload control contract"
    $version = Get-RequiredJsonInt32 -Object $document -Name "version" -Label "payload control contract"
    $schemaVersion = Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "payload control contract"
    $sha256 = Get-RequiredJsonString -Object $document -Name "sha256" -Label "payload control contract"
    if ($id -cnotmatch '^[A-Za-z0-9._-]{1,64}$' -or
        $version -le 0 -or
        $schemaVersion -ne $script:InstanceControlContractSchemaVersion) {
        throw "Payload control contract identity is invalid."
    }
    $null = Assert-InstanceLowercaseSha256 -Value $sha256 -Label "payload control contract sha256"
    $canonicalIdentity = @(
        $script:ManagedBy,
        "control-contract",
        $id,
        $version.ToString([Globalization.CultureInfo]::InvariantCulture),
        $schemaVersion.ToString([Globalization.CultureInfo]::InvariantCulture)
    ) -join "`n"
    $expectedSha256 = Get-TextSha256 -Text $canonicalIdentity
    if (-not [string]::Equals($sha256, $expectedSha256, [StringComparison]::Ordinal)) {
        throw "Payload control contract identity hash is invalid."
    }
    return [pscustomobject]@{
        Id = $id
        Version = $version
        SchemaVersion = $schemaVersion
        Sha256 = $sha256
        CanonicalIdentity = $canonicalIdentity
    }
}

function Assert-InstanceControlContractIdentity {
    param([Parameter(Mandatory = $true)]$ControlContract)

    $id = [string]$ControlContract.Id
    $version = [int]$ControlContract.Version
    $schemaVersion = [int]$ControlContract.SchemaVersion
    $sha256 = [string]$ControlContract.Sha256
    if ($id -cnotmatch '^[A-Za-z0-9._-]{1,64}$' -or
        $version -le 0 -or
        $schemaVersion -ne $script:InstanceControlContractSchemaVersion) {
        throw "Control contract identity is invalid."
    }
    $null = Assert-InstanceLowercaseSha256 -Value $sha256 -Label "control contract sha256"
    $canonicalIdentity = @(
        $script:ManagedBy,
        "control-contract",
        $id,
        $version.ToString([Globalization.CultureInfo]::InvariantCulture),
        $schemaVersion.ToString([Globalization.CultureInfo]::InvariantCulture)
    ) -join "`n"
    if (-not [string]::Equals((Get-TextSha256 -Text $canonicalIdentity), $sha256, [StringComparison]::Ordinal)) {
        throw "Control contract identity hash is invalid."
    }
    return $ControlContract
}

function ConvertTo-InstanceControlContractDocument {
    param([Parameter(Mandatory = $true)]$ControlContract)

    $null = Assert-InstanceControlContractIdentity -ControlContract $ControlContract
    return [pscustomobject][ordered]@{
        id = [string]$ControlContract.Id
        version = [int64]$ControlContract.Version
        schema_version = [int64]$ControlContract.SchemaVersion
        sha256 = [string]$ControlContract.Sha256
    }
}

function Get-InstanceActivationContractPaths {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$ControlContract,
        [Parameter(Mandatory = $true)][string]$OperationId
    )

    $null = Assert-InstanceControlContractIdentity -ControlContract $ControlContract
    $null = Assert-InstanceAttemptId -Value $OperationId -Label "operation_id"
    $fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $fullProjectRoot -PathType Container)) {
        throw "Activation contract project root is unavailable: $fullProjectRoot"
    }
    Assert-NoReparsePoint -Path $fullProjectRoot -Root $fullProjectRoot -Label "activation contract project root"
    $versionText = $ControlContract.Version.ToString([Globalization.CultureInfo]::InvariantCulture)
    $contractRootRelativePath = "$($script:InstanceContractNamespaceRelativePath)/$($ControlContract.Id)/v$versionText"
    $activationRelativePath = "$contractRootRelativePath/activation.json"
    $operationRelativePath = "$contractRootRelativePath/operation.json"
    $operationsRelativePath = "$contractRootRelativePath/operations"
    $operationRootRelativePath = "$operationsRelativePath/$OperationId"
    $supervisorRelativePath = "$contractRootRelativePath/supervisor"
    $contractRoot = Get-InstanceProjectPath -ProjectRoot $fullProjectRoot -RelativePath $contractRootRelativePath -Label "activation contract root"
    $activationPath = Get-InstanceProjectPath -ProjectRoot $fullProjectRoot -RelativePath $activationRelativePath -Label "activation record"
    $operationPath = Get-InstanceProjectPath -ProjectRoot $fullProjectRoot -RelativePath $operationRelativePath -Label "activation operation journal"
    $operationRoot = Get-InstanceProjectPath -ProjectRoot $fullProjectRoot -RelativePath $operationRootRelativePath -Label "activation operation root"
    $supervisorRoot = Get-InstanceProjectPath -ProjectRoot $fullProjectRoot -RelativePath $supervisorRelativePath -Label "Supervisor contract root"
    return [pscustomobject]@{
        ContractRootRelativePath = $contractRootRelativePath
        ActivationRelativePath = $activationRelativePath
        OperationRelativePath = $operationRelativePath
        OperationsRelativePath = $operationsRelativePath
        OperationRootRelativePath = $operationRootRelativePath
        SupervisorRelativePath = $supervisorRelativePath
        ContractRoot = $contractRoot
        ActivationPath = $activationPath
        OperationPath = $operationPath
        OperationRoot = $operationRoot
        SupervisorRoot = $supervisorRoot
    }
}

function New-InstanceActivationAttemptIdentity {
    $activationEpoch = [guid]::NewGuid().ToString("N")
    do { $operationId = [guid]::NewGuid().ToString("N") } while ($operationId -ceq $activationEpoch)
    return [pscustomobject]@{ ActivationEpoch = $activationEpoch; OperationId = $operationId }
}

function Assert-InstanceActivationAttemptIdentity {
    param([Parameter(Mandatory = $true)]$Attempt)

    $activationEpoch = Assert-InstanceAttemptId -Value ([string]$Attempt.ActivationEpoch) -Label "activation_epoch"
    $operationId = Assert-InstanceAttemptId -Value ([string]$Attempt.OperationId) -Label "operation_id"
    if ([string]::Equals($activationEpoch, $operationId, [StringComparison]::Ordinal)) {
        throw "activation_epoch and operation_id must be distinct."
    }
    return $Attempt
}

function New-InstanceActivationEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$InstanceId,
        [Parameter(Mandatory = $true)][string]$GenerationId,
        [Parameter(Mandatory = $true)][string]$InstanceManifestSha256,
        [Parameter(Mandatory = $true)][string]$GenerationManifestSha256,
        [Parameter(Mandatory = $true)][ValidateSet("CURRENT", "TRUSTED_PREVIOUS", "NEWER", "SEQUENCE_COLLISION", "INVALID")][string]$GenerationDisposition
    )

    if ($InstanceId -cnotmatch '^[0-9a-f]{32}$') { throw "Activation instance_id is invalid." }
    if ($GenerationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$') { throw "Activation generation_id is invalid." }
    $null = Assert-InstanceLowercaseSha256 -Value $InstanceManifestSha256 -Label "activation instance manifest hash"
    $null = Assert-InstanceLowercaseSha256 -Value $GenerationManifestSha256 -Label "activation generation manifest hash"
    return [pscustomobject][ordered]@{
        instance_id = $InstanceId
        generation_id = $GenerationId
        instance_manifest_sha256 = $InstanceManifestSha256
        generation_manifest_sha256 = $GenerationManifestSha256
        generation_disposition = $GenerationDisposition
    }
}

function Read-InstanceActivationEvidenceDocument {
    param(
        [AllowNull()]$Document,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowNull
    )

    if ($AllowNull -and $null -eq $Document) { return $null }
    Assert-InstanceJsonFieldAllowlist `
        -Object $Document `
        -Fields @("instance_id", "generation_id", "instance_manifest_sha256", "generation_manifest_sha256", "generation_disposition") `
        -Label $Label
    $instanceId = Get-RequiredJsonString -Object $Document -Name "instance_id" -Label $Label
    $generationId = Get-RequiredJsonString -Object $Document -Name "generation_id" -Label $Label
    $instanceManifestSha256 = Get-RequiredJsonString -Object $Document -Name "instance_manifest_sha256" -Label $Label
    $generationManifestSha256 = Get-RequiredJsonString -Object $Document -Name "generation_manifest_sha256" -Label $Label
    $disposition = Get-RequiredJsonString -Object $Document -Name "generation_disposition" -Label $Label
    return New-InstanceActivationEvidence `
        -InstanceId $instanceId `
        -GenerationId $generationId `
        -InstanceManifestSha256 $instanceManifestSha256 `
        -GenerationManifestSha256 $generationManifestSha256 `
        -GenerationDisposition $disposition
}

function Test-InstanceActivationEvidenceEqual {
    param(
        [AllowNull()]$Left,
        [AllowNull()]$Right
    )

    if ($null -eq $Left -or $null -eq $Right) { return $null -eq $Left -and $null -eq $Right }
    return [string]::Equals([string]$Left.instance_id, [string]$Right.instance_id, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$Left.generation_id, [string]$Right.generation_id, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$Left.instance_manifest_sha256, [string]$Right.instance_manifest_sha256, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$Left.generation_manifest_sha256, [string]$Right.generation_manifest_sha256, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$Left.generation_disposition, [string]$Right.generation_disposition, [StringComparison]::Ordinal)
}

function Assert-InstanceActivationRoleSemantics {
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)]$Candidate,
        [AllowNull()]$Current,
        [AllowNull()]$LastKnownGood,
        [AllowNull()][string]$PublicationPhase
    )

    if (-not [string]::Equals([string]$Candidate.generation_id, [string]$Context.TargetGenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$Candidate.generation_manifest_sha256, [string]$Context.TargetGenerationManifestSha256, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$Candidate.generation_disposition, "CURRENT", [StringComparison]::Ordinal)) {
        throw "Activation candidate does not match the trusted current target generation."
    }
    foreach ($selection in @($Current, $LastKnownGood)) {
        if ($null -ne $selection -and $selection.generation_disposition -cnotin @("CURRENT", "TRUSTED_PREVIOUS")) {
            throw "Activation current/LKG evidence has an unsafe generation disposition."
        }
    }
    if ([string]::Equals($PublicationPhase, "COMMITTED", [StringComparison]::Ordinal) -and
        ($null -eq $Current -or -not (Test-InstanceActivationEvidenceEqual -Left $Candidate -Right $Current))) {
        throw "Committed activation must select the complete candidate identity as current."
    }
}

function New-InstanceActivationMutationEvidence {
    param(
        [Parameter(Mandatory = $true)][int]$Index,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][ValidateSet("Write", "Delete")][string]$Mutation,
        [AllowNull()][string]$DesiredSha256,
        [Parameter(Mandatory = $true)][bool]$ExistedBefore,
        [AllowNull()][string]$PreImageSha256
    )

    if ($Index -lt 0) { throw "Activation mutation index is invalid." }
    $normalizedTarget = Assert-InstanceTransactionTarget -Target $Target
    if ($Mutation -eq "Write") {
        $null = Assert-InstanceLowercaseSha256 -Value $DesiredSha256 -Label "activation mutation desired hash"
    } elseif ($null -ne $DesiredSha256) {
        throw "Activation delete mutation cannot declare desired bytes."
    }
    if ($ExistedBefore) {
        $null = Assert-InstanceLowercaseSha256 -Value $PreImageSha256 -Label "activation mutation pre-image hash"
    } elseif ($null -ne $PreImageSha256) {
        throw "Activation mutation cannot declare a pre-image for an absent target."
    }
    return [pscustomobject][ordered]@{
        index = [int64]$Index
        target = $normalizedTarget
        mutation = $Mutation.ToLowerInvariant()
        desired_sha256 = $DesiredSha256
        existed_before = $ExistedBefore
        pre_image_sha256 = $PreImageSha256
    }
}

function Read-InstanceActivationMutationEvidenceDocument {
    param(
        [Parameter(Mandatory = $true)]$Document,
        [Parameter(Mandatory = $true)][int]$ExpectedIndex
    )

    $label = "activation mutation evidence"
    Assert-InstanceJsonFieldAllowlist `
        -Object $Document `
        -Fields @("index", "target", "mutation", "desired_sha256", "existed_before", "pre_image_sha256") `
        -Label $label
    $index = Get-RequiredJsonInt32 -Object $Document -Name "index" -Label $label
    $mutationText = Get-RequiredJsonString -Object $Document -Name "mutation" -Label $label
    $mutation = if ($mutationText -ceq "write") { "Write" } elseif ($mutationText -ceq "delete") { "Delete" } else { throw "Activation mutation kind is invalid." }
    if ($index -ne $ExpectedIndex) { throw "Activation mutation evidence is not in exact index order." }
    return New-InstanceActivationMutationEvidence `
        -Index $index `
        -Target (Get-RequiredJsonString -Object $Document -Name "target" -Label $label) `
        -Mutation $mutation `
        -DesiredSha256 (Get-RequiredJsonNullableString -Object $Document -Name "desired_sha256" -Label $label) `
        -ExistedBefore (Get-RequiredJsonBoolean -Object $Document -Name "existed_before" -Label $label) `
        -PreImageSha256 (Get-RequiredJsonNullableString -Object $Document -Name "pre_image_sha256" -Label $label)
}

function New-InstanceActivationContractContext {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$OperationId
    )

    $contract = Assert-InstanceControlContractIdentity -ControlContract $Manifest.ControlContract
    $runtimeContractSha256 = Assert-InstanceLowercaseSha256 `
        -Value ([string]$Manifest.RuntimeContractSha256) `
        -Label "runtime_contract_sha256"
    $targetGenerationId = [string]$Manifest.TargetGenerationId
    if ($targetGenerationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$') {
        throw "Trusted Manifest context has no valid current target generation."
    }
    $targetGenerationManifestSha256 = Assert-InstanceLowercaseSha256 `
        -Value ([string]$Manifest.TargetGenerationManifestSha256) `
        -Label "target generation manifest hash"
    $paths = Get-InstanceActivationContractPaths `
        -ProjectRoot $ProjectRoot `
        -ControlContract $contract `
        -OperationId $OperationId
    return [pscustomobject]@{
        ControlContract = $contract
        RuntimeContractSha256 = $runtimeContractSha256
        TargetGenerationId = $targetGenerationId
        TargetGenerationManifestSha256 = $targetGenerationManifestSha256
        ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        ProjectIdentity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        Paths = $paths
    }
}

function New-InstanceActivationRecordDocument {
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)]$Attempt,
        [Parameter(Mandatory = $true)]$Candidate,
        [AllowNull()]$Current,
        [AllowNull()]$LastKnownGood,
        [Parameter(Mandatory = $true)][ValidateSet("PREPARED", "ACTIVATING", "COMMITTED")][string]$PublicationPhase,
        [string]$TimestampUtc = [DateTime]::UtcNow.ToString("o")
    )

    $null = Assert-InstanceActivationAttemptIdentity -Attempt $Attempt
    $candidateDocument = Read-InstanceActivationEvidenceDocument -Document $Candidate -Label "activation candidate"
    $currentDocument = Read-InstanceActivationEvidenceDocument -Document $Current -Label "activation current" -AllowNull
    $lastKnownGoodDocument = Read-InstanceActivationEvidenceDocument -Document $LastKnownGood -Label "activation last-known-good" -AllowNull
    Assert-InstanceActivationRoleSemantics `
        -Context $Context `
        -Candidate $candidateDocument `
        -Current $currentDocument `
        -LastKnownGood $lastKnownGoodDocument `
        -PublicationPhase $PublicationPhase
    $null = Assert-InstanceUtcTimestamp -Value $TimestampUtc -Label "activation record timestamp"
    return [pscustomobject][ordered]@{
        schema_version = [int64]$script:InstanceActivationRecordSchemaVersion
        managed_by = $script:ManagedBy
        control_contract = ConvertTo-InstanceControlContractDocument -ControlContract $Context.ControlContract
        runtime_contract_sha256 = [string]$Context.RuntimeContractSha256
        project_root = [string]$Context.ProjectRoot
        project_identity = [string]$Context.ProjectIdentity
        activation_epoch = [string]$Attempt.ActivationEpoch
        operation_id = [string]$Attempt.OperationId
        candidate = $candidateDocument
        current = $currentDocument
        last_known_good = $lastKnownGoodDocument
        publication_phase = $PublicationPhase
        updated_at_utc = $TimestampUtc
    }
}

function New-InstanceActivationOperationDocument {
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)]$Attempt,
        [Parameter(Mandatory = $true)][ValidateSet("INSTALL", "UPGRADE", "REINSTALL")][string]$Action,
        [Parameter(Mandatory = $true)]$Candidate,
        [AllowNull()]$PreviousActivationRecordSha256,
        [Parameter(Mandatory = $true)][ValidateSet("PREPARED", "ACTIVATING", "COMMITTED")][string]$Phase,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Mutations,
        [string]$TimestampUtc = [DateTime]::UtcNow.ToString("o")
    )

    $null = Assert-InstanceActivationAttemptIdentity -Attempt $Attempt
    $candidateDocument = Read-InstanceActivationEvidenceDocument -Document $Candidate -Label "activation operation candidate"
    Assert-InstanceActivationRoleSemantics -Context $Context -Candidate $candidateDocument -Current $null -LastKnownGood $null
    $null = Assert-InstanceLowercaseSha256 `
        -Value $PreviousActivationRecordSha256 `
        -Label "previous activation record hash" `
        -AllowNull
    $null = Assert-InstanceUtcTimestamp -Value $TimestampUtc -Label "activation operation timestamp"
    $orderedMutations = New-Object System.Collections.Generic.List[object]
    $seenMutationTargets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    for ($index = 0; $index -lt $Mutations.Count; $index++) {
        $mutation = Read-InstanceActivationMutationEvidenceDocument -Document $Mutations[$index] -ExpectedIndex $index
        if (-not $seenMutationTargets.Add([string]$mutation.target)) {
            throw "Activation operation journal contains a duplicate mutation target."
        }
        $orderedMutations.Add($mutation)
    }
    return [pscustomobject][ordered]@{
        schema_version = [int64]$script:InstanceActivationOperationSchemaVersion
        managed_by = $script:ManagedBy
        control_contract = ConvertTo-InstanceControlContractDocument -ControlContract $Context.ControlContract
        runtime_contract_sha256 = [string]$Context.RuntimeContractSha256
        project_root = [string]$Context.ProjectRoot
        project_identity = [string]$Context.ProjectIdentity
        activation_epoch = [string]$Attempt.ActivationEpoch
        operation_id = [string]$Attempt.OperationId
        action = $Action
        candidate = $candidateDocument
        previous_activation_record_sha256 = $PreviousActivationRecordSha256
        phase = $Phase
        updated_at_utc = $TimestampUtc
        mutations = $orderedMutations.ToArray()
    }
}

function Assert-InstanceActivationContractDocumentContext {
    param(
        [Parameter(Mandatory = $true)]$Document,
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $controlDocument = Get-RequiredJsonPropertyValue -Object $Document -Name "control_contract" -Label $Label
    Assert-InstanceJsonFieldAllowlist `
        -Object $controlDocument `
        -Fields @("id", "version", "schema_version", "sha256") `
        -Label "$Label control contract"
    if (-not [string]::Equals((Get-RequiredJsonString -Object $controlDocument -Name "id" -Label $Label), [string]$Context.ControlContract.Id, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $controlDocument -Name "version" -Label $Label) -ne [int]$Context.ControlContract.Version -or
        (Get-RequiredJsonInt32 -Object $controlDocument -Name "schema_version" -Label $Label) -ne [int]$Context.ControlContract.SchemaVersion -or
        -not [string]::Equals((Get-RequiredJsonString -Object $controlDocument -Name "sha256" -Label $Label), [string]$Context.ControlContract.Sha256, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $Document -Name "runtime_contract_sha256" -Label $Label), [string]$Context.RuntimeContractSha256, [StringComparison]::Ordinal) -or
        -not [string]::Equals([System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $Document -Name "project_root" -Label $Label)).TrimEnd('\', '/'), [string]$Context.ProjectRoot, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $Document -Name "project_identity" -Label $Label), [string]$Context.ProjectIdentity, [StringComparison]::Ordinal)) {
        throw "$Label does not match its trusted contract or project context."
    }
}

function Assert-InstanceActivationRecordDocument {
    param(
        [Parameter(Mandatory = $true)]$Document,
        [Parameter(Mandatory = $true)]$Context
    )

    $label = "activation record"
    Assert-InstanceJsonFieldAllowlist `
        -Object $Document `
        -Fields @("schema_version", "managed_by", "control_contract", "runtime_contract_sha256", "project_root", "project_identity", "activation_epoch", "operation_id", "candidate", "current", "last_known_good", "publication_phase", "updated_at_utc") `
        -Label $label
    if ((Get-RequiredJsonInt32 -Object $Document -Name "schema_version" -Label $label) -ne $script:InstanceActivationRecordSchemaVersion -or
        -not [string]::Equals((Get-RequiredJsonString -Object $Document -Name "managed_by" -Label $label), $script:ManagedBy, [StringComparison]::Ordinal)) {
        throw "Activation record schema or owner is invalid."
    }
    Assert-InstanceActivationContractDocumentContext -Document $Document -Context $Context -Label $label
    $attempt = [pscustomobject]@{
        ActivationEpoch = Get-RequiredJsonString -Object $Document -Name "activation_epoch" -Label $label
        OperationId = Get-RequiredJsonString -Object $Document -Name "operation_id" -Label $label
    }
    $null = Assert-InstanceActivationAttemptIdentity -Attempt $attempt
    $candidate = Read-InstanceActivationEvidenceDocument -Document (Get-RequiredJsonPropertyValue -Object $Document -Name "candidate" -Label $label) -Label "activation candidate"
    $current = Read-InstanceActivationEvidenceDocument -Document (Get-RequiredJsonPropertyValue -Object $Document -Name "current" -Label $label) -Label "activation current" -AllowNull
    $lastKnownGood = Read-InstanceActivationEvidenceDocument -Document (Get-RequiredJsonPropertyValue -Object $Document -Name "last_known_good" -Label $label) -Label "activation last-known-good" -AllowNull
    $phase = Get-RequiredJsonString -Object $Document -Name "publication_phase" -Label $label
    if ($phase -cnotin @("PREPARED", "ACTIVATING", "COMMITTED")) {
        throw "Activation record publication phase is invalid."
    }
    Assert-InstanceActivationRoleSemantics `
        -Context $Context `
        -Candidate $candidate `
        -Current $current `
        -LastKnownGood $lastKnownGood `
        -PublicationPhase $phase
    $timestamp = Assert-InstanceUtcTimestamp -Value (Get-RequiredJsonString -Object $Document -Name "updated_at_utc" -Label $label) -Label "activation record timestamp"
    return [pscustomobject]@{
        Document = $Document
        Attempt = $attempt
        Candidate = $candidate
        Current = $current
        LastKnownGood = $lastKnownGood
        Phase = $phase
        TimestampUtc = $timestamp
    }
}

function Assert-InstanceActivationOperationDocument {
    param(
        [Parameter(Mandatory = $true)]$Document,
        [Parameter(Mandatory = $true)]$Context
    )

    $label = "activation operation journal"
    Assert-InstanceJsonFieldAllowlist `
        -Object $Document `
        -Fields @("schema_version", "managed_by", "control_contract", "runtime_contract_sha256", "project_root", "project_identity", "activation_epoch", "operation_id", "action", "candidate", "previous_activation_record_sha256", "phase", "updated_at_utc", "mutations") `
        -Label $label
    if ((Get-RequiredJsonInt32 -Object $Document -Name "schema_version" -Label $label) -ne $script:InstanceActivationOperationSchemaVersion -or
        -not [string]::Equals((Get-RequiredJsonString -Object $Document -Name "managed_by" -Label $label), $script:ManagedBy, [StringComparison]::Ordinal)) {
        throw "Activation operation journal schema or owner is invalid."
    }
    Assert-InstanceActivationContractDocumentContext -Document $Document -Context $Context -Label $label
    $attempt = [pscustomobject]@{
        ActivationEpoch = Get-RequiredJsonString -Object $Document -Name "activation_epoch" -Label $label
        OperationId = Get-RequiredJsonString -Object $Document -Name "operation_id" -Label $label
    }
    $null = Assert-InstanceActivationAttemptIdentity -Attempt $attempt
    $action = Get-RequiredJsonString -Object $Document -Name "action" -Label $label
    if ($action -cnotin @("INSTALL", "UPGRADE", "REINSTALL")) { throw "Activation operation action is invalid." }
    $candidate = Read-InstanceActivationEvidenceDocument -Document (Get-RequiredJsonPropertyValue -Object $Document -Name "candidate" -Label $label) -Label "activation operation candidate"
    Assert-InstanceActivationRoleSemantics -Context $Context -Candidate $candidate -Current $null -LastKnownGood $null
    $previousHash = Get-RequiredJsonNullableString -Object $Document -Name "previous_activation_record_sha256" -Label $label
    $null = Assert-InstanceLowercaseSha256 -Value $previousHash -Label "previous activation record hash" -AllowNull
    $phase = Get-RequiredJsonString -Object $Document -Name "phase" -Label $label
    if ($phase -cnotin @("PREPARED", "ACTIVATING", "COMMITTED")) { throw "Activation operation phase is invalid." }
    $timestamp = Assert-InstanceUtcTimestamp -Value (Get-RequiredJsonString -Object $Document -Name "updated_at_utc" -Label $label) -Label "activation operation timestamp"
    $mutationDocuments = Get-RequiredJsonArray -Object $Document -Name "mutations" -Label $label
    $mutations = New-Object System.Collections.Generic.List[object]
    $seenMutationTargets = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    for ($index = 0; $index -lt $mutationDocuments.Count; $index++) {
        $mutation = Read-InstanceActivationMutationEvidenceDocument -Document $mutationDocuments[$index] -ExpectedIndex $index
        if (-not $seenMutationTargets.Add([string]$mutation.target)) {
            throw "Activation operation journal contains a duplicate mutation target."
        }
        $mutations.Add($mutation)
    }
    return [pscustomobject]@{
        Document = $Document
        Attempt = $attempt
        Action = $action
        Candidate = $candidate
        PreviousActivationRecordSha256 = $previousHash
        Phase = $phase
        TimestampUtc = $timestamp
        Mutations = $mutations.ToArray()
    }
}

function Read-InstanceActivationRecord {
    param([Parameter(Mandatory = $true)]$Context)

    $path = [string]$Context.Paths.ActivationPath
    Assert-NoReparsePoint -Path $path -Root $Context.ProjectRoot -Label "activation record"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Activation record is missing or not a regular file." }
    $json = Read-BoundedJsonDocument -Path $path -Label "activation record" -MaximumBytes $script:InstanceActivationRecordMaximumBytes
    $validated = Assert-InstanceActivationRecordDocument -Document $json.Document -Context $Context
    $validated | Add-Member -NotePropertyName Path -NotePropertyValue $path
    $validated | Add-Member -NotePropertyName Sha256 -NotePropertyValue $json.Sha256
    $validated | Add-Member -NotePropertyName Text -NotePropertyValue $json.Text
    return $validated
}

function Read-InstanceActivationOperation {
    param([Parameter(Mandatory = $true)]$Context)

    $path = [string]$Context.Paths.OperationPath
    Assert-NoReparsePoint -Path $path -Root $Context.ProjectRoot -Label "activation operation journal"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Activation operation journal is missing or not a regular file." }
    $json = Read-BoundedJsonDocument -Path $path -Label "activation operation journal" -MaximumBytes $script:InstanceActivationOperationMaximumBytes
    $validated = Assert-InstanceActivationOperationDocument -Document $json.Document -Context $Context
    $validated | Add-Member -NotePropertyName Path -NotePropertyValue $path
    $validated | Add-Member -NotePropertyName Sha256 -NotePropertyValue $json.Sha256
    $validated | Add-Member -NotePropertyName Text -NotePropertyValue $json.Text
    return $validated
}

function Assert-InstanceActivationDocumentsMatch {
    param(
        [Parameter(Mandatory = $true)]$Activation,
        [Parameter(Mandatory = $true)]$Operation
    )

    if (-not [string]::Equals([string]$Activation.Attempt.ActivationEpoch, [string]$Operation.Attempt.ActivationEpoch, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$Activation.Attempt.OperationId, [string]$Operation.Attempt.OperationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$Activation.Phase, [string]$Operation.Phase, [StringComparison]::Ordinal) -or
        -not [string]::Equals(
            (ConvertTo-InstanceJsonText -Value $Activation.Candidate),
            (ConvertTo-InstanceJsonText -Value $Operation.Candidate),
            [StringComparison]::Ordinal)) {
        throw "Activation record and operation journal identities do not match."
    }
}

function Publish-InstanceActivationFileIfAbsentOrIdentical {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][int64]$MaximumBytes
    )

    Assert-NoReparsePoint -Path $Path -Root $ProjectRoot -Label $Label
    $desiredBytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Label is not a regular file." }
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.Length -le 0 -or $item.Length -gt $MaximumBytes) { throw "$Label size is outside the accepted range." }
        $existingBytes = [System.IO.File]::ReadAllBytes($Path)
        if ($existingBytes.Length -le 0 -or $existingBytes.Length -gt $MaximumBytes) { throw "$Label size changed outside the accepted range while it was read." }
        if ($existingBytes.Length -ne $desiredBytes.Length) { throw "$Label conflicts with the immutable activation attempt." }
        for ($index = 0; $index -lt $existingBytes.Length; $index++) {
            if ($existingBytes[$index] -ne $desiredBytes[$index]) { throw "$Label conflicts with the immutable activation attempt." }
        }
        return $false
    }
    try {
        Write-DurableUtf8File -Path $Path -Content $Content
        return $true
    } catch {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw }
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.Length -le 0 -or $item.Length -gt $MaximumBytes) { throw "$Label size is outside the accepted range." }
        $existingBytes = [System.IO.File]::ReadAllBytes($Path)
        if ($existingBytes.Length -le 0 -or $existingBytes.Length -gt $MaximumBytes) { throw "$Label size changed outside the accepted range while it was read." }
        if ($existingBytes.Length -ne $desiredBytes.Length) { throw "$Label conflicted during publication." }
        for ($index = 0; $index -lt $existingBytes.Length; $index++) {
            if ($existingBytes[$index] -ne $desiredBytes[$index]) { throw "$Label conflicted during publication." }
        }
        return $false
    }
}

function Assert-FreshInstanceActivationNamespace {
    param([Parameter(Mandatory = $true)]$Context)

    $contractRoot = [string]$Context.Paths.ContractRoot
    if (-not (Test-Path -LiteralPath $contractRoot)) { return }
    if (-not (Test-Path -LiteralPath $contractRoot -PathType Container)) {
        throw "Activation contract namespace is not a directory."
    }
    Assert-NoReparsePoint -Path $contractRoot -Root $Context.ProjectRoot -Label "activation contract namespace"
    foreach ($entry in @(Get-ChildItem -LiteralPath $contractRoot -Force)) {
        Assert-NoReparsePoint -Path $entry.FullName -Root $Context.ProjectRoot -Label "activation contract namespace entry"
        if ($entry.Name -ceq "activation.json" -or $entry.Name -ceq "operation.json") {
            if ($entry.PSIsContainer) { throw "Activation contract namespace record is not a regular file: $($entry.Name)" }
            continue
        }
        if ($entry.Name -ceq "operations") {
            if (-not $entry.PSIsContainer) { throw "Activation contract operations root is not a directory." }
            continue
        }
        throw "Activation contract namespace is not fresh: unexpected entry $($entry.Name)"
    }

    $operationsRoot = Get-InstanceProjectPath `
        -ProjectRoot $Context.ProjectRoot `
        -RelativePath $Context.Paths.OperationsRelativePath `
        -Label "activation operations root"
    if (-not (Test-Path -LiteralPath $operationsRoot)) { return }
    if (-not (Test-Path -LiteralPath $operationsRoot -PathType Container)) {
        throw "Activation contract operations root is not a directory."
    }
    foreach ($entry in @(Get-ChildItem -LiteralPath $operationsRoot -Force)) {
        Assert-NoReparsePoint -Path $entry.FullName -Root $Context.ProjectRoot -Label "activation operation directory"
        if (-not $entry.PSIsContainer -or
            -not [string]::Equals($entry.Name, [string]$Context.Paths.OperationRootRelativePath.Split('/')[-1], [StringComparison]::Ordinal)) {
            throw "Activation contract namespace is not fresh: unexpected operation entry $($entry.Name)"
        }
    }
    if (Test-Path -LiteralPath $Context.Paths.OperationRoot) {
        if (-not (Test-Path -LiteralPath $Context.Paths.OperationRoot -PathType Container)) {
            throw "Activation operation root is not a directory."
        }
        if (@(Get-ChildItem -LiteralPath $Context.Paths.OperationRoot -Force).Count -ne 0) {
            throw "Activation operation root contains unexpected evidence."
        }
    }
}

function Initialize-FreshInstanceActivationContract {
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)]$ActivationDocument,
        [Parameter(Mandatory = $true)]$OperationDocument
    )

    $activation = Assert-InstanceActivationRecordDocument -Document $ActivationDocument -Context $Context
    $operation = Assert-InstanceActivationOperationDocument -Document $OperationDocument -Context $Context
    Assert-InstanceActivationDocumentsMatch -Activation $activation -Operation $operation
    if (-not [string]::Equals([string]$activation.Attempt.OperationId, [string]$Context.Paths.OperationRootRelativePath.Split('/')[-1], [StringComparison]::Ordinal)) {
        throw "Activation attempt operation_id does not match its derived operation directory."
    }
    if ($null -ne $operation.PreviousActivationRecordSha256) {
        throw "Fresh activation contract provisioning cannot replace a previous activation record."
    }

    $activationText = ConvertTo-InstanceJsonText -Value $ActivationDocument
    $operationText = ConvertTo-InstanceJsonText -Value $OperationDocument
    foreach ($path in @($Context.Paths.ContractRoot, $Context.Paths.OperationRoot)) {
        Assert-NoReparsePoint -Path $path -Root $Context.ProjectRoot -Label "activation contract directory"
    }
    Assert-FreshInstanceActivationNamespace -Context $Context
    if (Test-Path -LiteralPath $Context.Paths.ActivationPath) {
        $existingActivation = Read-InstanceActivationRecord -Context $Context
        if (-not [string]::Equals($existingActivation.Text, $activationText, [StringComparison]::Ordinal)) {
            throw "Activation record conflicts with the immutable activation attempt."
        }
    }
    if (Test-Path -LiteralPath $Context.Paths.OperationPath) {
        $existingOperation = Read-InstanceActivationOperation -Context $Context
        if (-not [string]::Equals($existingOperation.Text, $operationText, [StringComparison]::Ordinal)) {
            throw "Activation operation journal conflicts with the immutable activation attempt."
        }
    }
    New-Item -ItemType Directory -Force -Path $Context.Paths.ContractRoot | Out-Null
    Assert-NoReparsePoint -Path $Context.Paths.ContractRoot -Root $Context.ProjectRoot -Label "activation contract root"
    New-Item -ItemType Directory -Force -Path $Context.Paths.OperationRoot | Out-Null
    Assert-NoReparsePoint -Path $Context.Paths.OperationRoot -Root $Context.ProjectRoot -Label "activation operation root"
    Assert-FreshInstanceActivationNamespace -Context $Context
    $operationCreated = Publish-InstanceActivationFileIfAbsentOrIdentical `
        -Path $Context.Paths.OperationPath `
        -Content $operationText `
        -ProjectRoot $Context.ProjectRoot `
        -Label "activation operation journal" `
        -MaximumBytes $script:InstanceActivationOperationMaximumBytes
    $activationCreated = Publish-InstanceActivationFileIfAbsentOrIdentical `
        -Path $Context.Paths.ActivationPath `
        -Content $activationText `
        -ProjectRoot $Context.ProjectRoot `
        -Label "activation record" `
        -MaximumBytes $script:InstanceActivationRecordMaximumBytes
    $publishedActivation = Read-InstanceActivationRecord -Context $Context
    $publishedOperation = Read-InstanceActivationOperation -Context $Context
    Assert-InstanceActivationDocumentsMatch -Activation $publishedActivation -Operation $publishedOperation
    Assert-FreshInstanceActivationNamespace -Context $Context
    return [pscustomobject]@{
        Created = $activationCreated -or $operationCreated
        Activation = $publishedActivation
        Operation = $publishedOperation
        Paths = $Context.Paths
    }
}

function ConvertTo-InstanceJsonText {
    param([Parameter(Mandatory = $true)]$Value)

    return (($Value | ConvertTo-Json -Depth 16).Replace("`r`n", "`n").TrimEnd("`n") + "`n")
}

function Publish-InstanceAtomicText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$StageRoot
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    $stagePath = Join-Path $StageRoot ("instance-write-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content $Content
        Publish-TransactionFile -StagePath $stagePath -TargetPath $Path
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Get-InstanceProjectPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $RelativePath -Label $Label
    Assert-NoReparsePoint -Path $path -Root $ProjectRoot -Label $Label
    return $path
}

function Get-InstanceDesiredState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $path = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceDesiredStateRelativePath -Label "instance desired state"
    if (-not (Test-Path -LiteralPath $path)) {
        $legacy = Get-ProjectIntegrationState -ProjectRoot $ProjectRoot
        return [pscustomobject]@{
            Present = $legacy.Present
            DesiredState = if ($legacy.Uninstalled) { "UNINSTALLED" } else { "INSTALLED" }
            StateId = $legacy.StateId
            CleanupState = $legacy.CleanupState
            Path = $path
            Legacy = $legacy.Present
        }
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Instance desired state is not a regular file: $path"
    }
    $document = (Read-BoundedJsonDocument -Path $path -Label "instance desired state" -MaximumBytes (64 * 1024)).Document
    $state = Get-RequiredJsonString -Object $document -Name "desired_state" -Label "instance desired state"
    $stateId = Get-RequiredJsonString -Object $document -Name "state_id" -Label "instance desired state"
    $cleanupState = Get-RequiredJsonString -Object $document -Name "cleanup_state" -Label "instance desired state"
    if ((Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "instance desired state") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "instance desired state"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        $state -cnotin @("INSTALLED", "UNINSTALLED") -or
        $stateId -cnotmatch '^[0-9a-f]{32}$' -or
        $cleanupState -cnotin @("COMPLETE", "PENDING") -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "project_identity" -Label "instance desired state"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        -not [string]::Equals([System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $document -Name "project_root" -Label "instance desired state")), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Instance desired state identity or schema is invalid."
    }
    return [pscustomobject]@{
        Present = $true
        DesiredState = $state
        StateId = $stateId
        CleanupState = $cleanupState
        Path = $path
        Legacy = $false
    }
}

function New-InstanceDesiredStateDocument {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][ValidateSet("INSTALLED", "UNINSTALLED")][string]$DesiredState,
        [Parameter(Mandatory = $true)][string]$StateId,
        [Parameter(Mandatory = $true)][ValidateSet("COMPLETE", "PENDING")][string]$CleanupState
    )

    return [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        desired_state = $DesiredState
        state_id = $StateId
        cleanup_state = $CleanupState
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
    }
}

function Get-ValidatedCurrentInstance {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$AllowMissing,
        [switch]$LastKnownGood
    )

    $selectionRelativePath = if ($LastKnownGood) { $script:InstanceLastKnownGoodRelativePath } else { $script:InstanceCurrentRelativePath }
    $selectionLabel = if ($LastKnownGood) { "last-known-good instance selection" } else { "current instance selection" }
    $selectionPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $selectionRelativePath -Label $selectionLabel
    if (-not (Test-Path -LiteralPath $selectionPath)) {
        if ($AllowMissing) { return $null }
        throw "Current CodeDB instance selection is missing."
    }
    if (-not (Test-Path -LiteralPath $selectionPath -PathType Leaf)) {
        throw "Current CodeDB instance selection is not a regular file."
    }
    $selectionJson = Read-BoundedJsonDocument -Path $selectionPath -Label "current instance selection" -MaximumBytes (64 * 1024)
    $selection = $selectionJson.Document
    $instanceId = Get-RequiredJsonString -Object $selection -Name "instance_id" -Label "current instance selection"
    $instanceRelativePath = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $selection -Name "instance_relative_path" -Label "current instance selection") -Label "instance selection path"
    $selectionGenerationId = Get-RequiredJsonString -Object $selection -Name "generation_id" -Label "current instance selection"
    $expectedRelativePath = "$($script:InstancesRelativePath)/$instanceId"
    if ((Get-RequiredJsonInt32 -Object $selection -Name "schema_version" -Label "current instance selection") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $selection -Name "managed_by" -Label "current instance selection"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $selection -Name "project_identity" -Label "current instance selection"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        $instanceId -cnotmatch '^[0-9a-f]{32}$' -or
        -not [string]::Equals($instanceRelativePath, $expectedRelativePath, [StringComparison]::Ordinal) -or
        $selectionGenerationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$') {
        throw "Current CodeDB instance selection identity is invalid."
    }
    $instanceRoot = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $instanceRelativePath -Label "current instance root"
    if (-not (Test-Path -LiteralPath $instanceRoot -PathType Container)) {
        throw "Current CodeDB instance root is missing."
    }
    $instanceManifestPath = Join-Path $instanceRoot "instance.json"
    Assert-NoReparsePoint -Path $instanceManifestPath -Root $ProjectRoot -Label "current instance manifest"
    $instanceJson = Read-BoundedJsonDocument -Path $instanceManifestPath -Label "current instance manifest" -MaximumBytes (128 * 1024)
    $expectedManifestHash = Get-RequiredJsonString -Object $selection -Name "instance_manifest_sha256" -Label "current instance selection"
    if ($expectedManifestHash -cnotmatch '^[0-9a-f]{64}$' -or
        -not [string]::Equals((Get-FileSha256 -Path $instanceManifestPath), $expectedManifestHash, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Current CodeDB instance manifest hash is invalid."
    }
    $instanceManifestDocument = $instanceJson.Document
    $manifestGenerationId = Get-RequiredJsonString -Object $instanceManifestDocument -Name "generation_id" -Label "current instance manifest"
    if ((Get-RequiredJsonInt32 -Object $instanceManifestDocument -Name "schema_version" -Label "current instance manifest") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $instanceManifestDocument -Name "managed_by" -Label "current instance manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $instanceManifestDocument -Name "project_identity" -Label "current instance manifest"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $instanceManifestDocument -Name "instance_id" -Label "current instance manifest"), $instanceId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $instanceManifestDocument -Name "instance_relative_path" -Label "current instance manifest"), $instanceRelativePath, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $instanceManifestDocument -Name "state" -Label "current instance manifest"), "READY", [StringComparison]::Ordinal) -or
        $manifestGenerationId -cnotmatch '^[A-Za-z0-9._-]{1,64}$' -or
        -not [string]::Equals($selectionGenerationId, $manifestGenerationId, [StringComparison]::Ordinal)) {
        throw "Current CodeDB instance manifest identity is invalid."
    }
    $generation = Assert-InstanceGenerationClosure -Manifest $Manifest -ProjectRoot $ProjectRoot -InstanceManifest $instanceManifestDocument
    Assert-InstanceStableWrapper `
        -ProjectRoot $ProjectRoot `
        -ExpectedSha256 ([string]$generation.StableWrapperSha256)
    return [pscustomobject]@{
        InstanceId = $instanceId
        InstanceRelativePath = $instanceRelativePath
        InstanceRoot = $instanceRoot
        ManifestPath = $instanceManifestPath
        ManifestSha256 = $expectedManifestHash
        SelectionPath = $selectionPath
        SelectionText = $selectionJson.Text
        Manifest = $instanceManifestDocument
        Generation = $generation
        GenerationDisposition = $generation.Disposition
    }
}

function New-InstanceManifestDocument {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$InstanceId,
        [Parameter(Mandatory = $true)][ValidateSet("PROVISIONING", "READY", "RETIRED")][string]$State,
        [Parameter(Mandatory = $true)][string]$CreatedAtUtc
    )

    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    $workerTarget = $script:GenerationTargetPrefix + $script:InstanceWorkerRelativePath
    if (-not $Manifest.TargetMap.ContainsKey($generationManifestTarget) -or -not $Manifest.TargetMap.ContainsKey($workerTarget)) {
        throw "Package payload is missing the $($Manifest.GenerationId) generation manifest or instance worker."
    }
    return [ordered]@{
        schema_version = $script:InstanceSchemaVersion
        managed_by = $script:ManagedBy
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        instance_id = $InstanceId
        instance_relative_path = "$($script:InstancesRelativePath)/$InstanceId"
        state = $State
        package_version = $Manifest.PackageVersion
        payload_version = $Manifest.PayloadVersion
        payload_sequence = $Manifest.PayloadSequence
        generation_id = $Manifest.GenerationId
        generation_relative_path = $script:GenerationTargetPrefix.TrimEnd('/')
        generation_manifest_sha256 = $Manifest.TargetMap[$generationManifestTarget].Sha256
        bootstrap_protocol = $Manifest.BootstrapProtocol
        worker_relative_path = $script:InstanceWorkerRelativePath
        worker_sha256 = $Manifest.TargetMap[$workerTarget].Sha256
        created_at_utc = $CreatedAtUtc
        verified_at_utc = if ($State -eq "READY") { [DateTime]::UtcNow.ToString("o") } else { "" }
    }
}

function Write-InstanceManifest {
    param(
        [Parameter(Mandatory = $true)][string]$InstanceRoot,
        [Parameter(Mandatory = $true)]$Document
    )

    $path = Join-Path $InstanceRoot "instance.json"
    Publish-InstanceAtomicText -Path $path -Content (ConvertTo-InstanceJsonText -Value $Document) -StageRoot (Join-Path $InstanceRoot "tmp")
    return $path
}

function New-InstanceCandidateEditorLease {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$InstanceRoot,
        [Parameter(Mandatory = $true)][string]$InstanceId
    )

    $processIdentity = Get-MaterializerProcessIdentity -ProcessId $PID
    if (-not $processIdentity.Alive -or [string]::IsNullOrWhiteSpace([string]$processIdentity.StartTicks)) {
        throw "Candidate verification cannot establish the materializer process identity."
    }
    $leaseRoot = Join-Path $InstanceRoot "watch\lifecycle\editor-leases"
    New-Item -ItemType Directory -Force -Path $leaseRoot | Out-Null
    $handoff = $script:EditorLeaseHandoff
    if ($null -ne $handoff) {
        $handoffIdentity = Get-MaterializerProcessIdentity -ProcessId $handoff.ProcessId
        if (-not $handoffIdentity.Alive -or
            $null -eq $handoffIdentity.StartTicks -or
            -not [string]::Equals(
                [string]$handoffIdentity.StartTicks,
                [string]$handoff.ProcessStartTicks,
                [StringComparison]::Ordinal)) {
            Throw-MaterializerError `
                -Message "Candidate verification cannot establish the handed-off Unity Editor process identity." `
                -ExitCode 4
        }
        $sessionId = [string]$handoff.SessionId
        $editorPid = [int]$handoff.ProcessId
        $editorStartTicks = [string]$handoff.ProcessStartTicks
    } else {
        $sessionId = "candidate-$InstanceId"
        $editorPid = $PID
        $editorStartTicks = [string]$processIdentity.StartTicks
    }
    $createdAt = [DateTime]::UtcNow.ToString("o")
    $lease = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        session_id = $sessionId
        editor_pid = $editorPid
        process_start_ticks = $editorStartTicks
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        created_at_utc = $createdAt
        heartbeat_at_utc = $createdAt
    }
    $leasePath = Join-Path $leaseRoot "$sessionId.json"
    Publish-InstanceAtomicText -Path $leasePath -Content (ConvertTo-InstanceJsonText -Value $lease) -StageRoot (Join-Path $InstanceRoot "tmp")
    return [pscustomobject]@{
        Path = $leasePath
        Document = $lease
    }
}

function Update-InstanceCandidateEditorLease {
    param(
        [Parameter(Mandatory = $true)]$Lease,
        [Parameter(Mandatory = $true)][string]$InstanceRoot
    )

    Assert-NoReparsePoint -Path $Lease.Path -Root $InstanceRoot -Label "candidate Editor lease"
    $Lease.Document["heartbeat_at_utc"] = [DateTime]::UtcNow.ToString("o")
    Publish-InstanceAtomicText `
        -Path $Lease.Path `
        -Content (ConvertTo-InstanceJsonText -Value $Lease.Document) `
        -StageRoot (Join-Path $InstanceRoot "tmp")
}

function Invoke-InstancePowerShellScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$InstanceRoot,
        [string[]]$Arguments = @(),
        [ValidateRange(1, 600000)][int]$TimeoutMilliseconds = 300000,
        [AllowNull()][scriptblock]$WhileRunning
    )

    $powershell = (Get-Command powershell.exe -CommandType Application -ErrorAction Stop).Source
    $nativeArguments = @("-NoProfile", "-NonInteractive", "-NoLogo", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + @($Arguments)
    $result = Invoke-BoundedNativeProcessWithFileOutput `
        -FilePath $powershell `
        -Arguments $nativeArguments `
        -OutputRoot (Join-Path $InstanceRoot "tmp") `
        -TimeoutMilliseconds $TimeoutMilliseconds `
        -Environment @{
            RICE_CODEDB_UNITY_ROOT = [System.IO.Path]::GetFullPath($ProjectRoot)
            RICE_CODEDB_INSTANCE_ROOT = [System.IO.Path]::GetFullPath($InstanceRoot)
        } `
        -WhileRunning $WhileRunning
    if ($result.ExitCode -ne 0) {
        $detail = @($result.StandardError, $result.StandardOutput) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        throw "Package-owned instance script failed ($([System.IO.Path]::GetFileName($ScriptPath)), exit $($result.ExitCode)): $($detail -join ' ')"
    }
    return $result
}

function Copy-PreservedInstanceRuntimeConfig {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()]$PreviousInstance,
        [Parameter(Mandatory = $true)][string]$InstanceRoot,
        [Parameter(Mandatory = $true)][string]$InstanceRelativePath
    )

    $sources = New-Object System.Collections.Generic.List[object]
    if ($null -ne $PreviousInstance) {
        $sources.Add([pscustomobject]@{
            Path = Join-Path $PreviousInstance.InstanceRoot "config\codedb-mcp.toml"
            Runtime = $PreviousInstance.InstanceRelativePath
        })
    }
    $projectSlug = ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf ($ProjectRoot.TrimEnd('\', '/')))
    $legacyRuntime = "AIWork/.runtime/codedb/codedb-$projectSlug"
    $sources.Add([pscustomobject]@{
        Path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "$legacyRuntime/config/codedb-mcp.toml" -Label "legacy runtime config"
        Runtime = $legacyRuntime
    })
    $source = @($sources | Where-Object { Test-Path -LiteralPath $_.Path -PathType Leaf } | Select-Object -First 1)
    if ($source.Count -eq 0) { return $false }
    Assert-NoReparsePoint -Path $source[0].Path -Root $ProjectRoot -Label "preserved runtime config"
    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    $text = [System.IO.File]::ReadAllText($source[0].Path, $encoding)
    if ($text.IndexOf([string]$source[0].Runtime, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        return $false
    }
    $updated = $text.Replace([string]$source[0].Runtime, $InstanceRelativePath)
    $targetPath = Join-Path $InstanceRoot "config\codedb-mcp.toml"
    [System.IO.File]::WriteAllText($targetPath, $updated, [System.Text.UTF8Encoding]::new($false))
    return $true
}

function Invoke-InstanceCandidateProbe {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$InstanceRelativePath,
        [AllowNull()][scriptblock]$WhileRunning
    )

    if ($PocFixture) {
        Write-Host "[PHASE CANDIDATE_VERIFY] READY - deterministic fixture evidence."
        return [pscustomobject]@{
            availability = "AVAILABLE"
            codedb_status_usable = $true
            codedb_text_search_callable = $true
        }
    }
    $node = (Get-Command node -CommandType Application -ErrorAction Stop).Source
    $probePath = Join-Path $PSScriptRoot $script:McpAvailabilityProbeName
    $workerTarget = $script:GenerationTargetPrefix + $script:InstanceWorkerRelativePath
    $workerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $workerTarget -Label "candidate instance worker"
    Assert-NoReparsePoint -Path $workerPath -Root $ProjectRoot -Label "candidate instance worker"
    $result = Invoke-BoundedNativeProcess `
        -FilePath $node `
        -Arguments @(
            $probePath,
            "--project-root", $ProjectRoot,
            "--wrapper", $workerTarget,
            "--instance-root", $InstanceRelativePath
        ) `
        -TimeoutMilliseconds 180000 `
        -WhileRunning $WhileRunning
    if ($result.ExitCode -ne 0) {
        throw "Candidate instance MCP verification failed: $($result.StandardError) $($result.StandardOutput)"
    }
    $lines = @($result.StandardOutput -split "`r?`n" | Where-Object { $_.TrimStart().StartsWith("{") })
    if ($lines.Count -ne 1) { throw "Candidate instance MCP verification returned an ambiguous result." }
    $document = ConvertFrom-StrictJsonText -Text $lines[0] -Label "candidate MCP verification"
    if (-not [string]::Equals((Get-RequiredJsonString -Object $document -Name "availability" -Label "candidate MCP verification"), "AVAILABLE", [StringComparison]::Ordinal) -or
        -not (Get-RequiredJsonBoolean -Object $document -Name "codedb_status_usable" -Label "candidate MCP verification") -or
        -not (Get-RequiredJsonBoolean -Object $document -Name "codedb_text_search_callable" -Label "candidate MCP verification")) {
        throw "Candidate instance did not prove a usable status and bounded query."
    }
    Write-Host "[PHASE CANDIDATE_VERIFY] READY - initialize, exact tools, usable status, and bounded query succeeded."
    return $document
}

function Write-InstanceAvailabilityEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$InstanceRoot,
        [Parameter(Mandatory = $true)][string]$InstanceId,
        [Parameter(Mandatory = $true)]$Probe
    )

    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        instance_id = $InstanceId
        generation_id = $script:GenerationId
        availability = [string]$Probe.availability
        codedb_status_usable = [bool]$Probe.codedb_status_usable
        codedb_text_search_callable = [bool]$Probe.codedb_text_search_callable
        verified_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    $path = Join-Path $InstanceRoot ($script:InstanceAvailabilityRelativePath.Replace('/', '\'))
    Publish-InstanceAtomicText -Path $path -Content (ConvertTo-InstanceJsonText -Value $document) -StageRoot (Join-Path $InstanceRoot "tmp")
    return $path
}

function Get-ValidatedInstanceAvailabilityEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Instance
    )

    $path = Join-Path $Instance.InstanceRoot ($script:InstanceAvailabilityRelativePath.Replace('/', '\'))
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    Assert-NoReparsePoint -Path $path -Root $Instance.InstanceRoot -Label "instance availability evidence"
    $document = (Read-BoundedJsonDocument -Path $path -Label "instance availability evidence" -MaximumBytes (64 * 1024)).Document
    $verifiedText = Get-RequiredJsonString -Object $document -Name "verified_at_utc" -Label "instance availability evidence"
    [DateTimeOffset]$verified = [DateTimeOffset]::MinValue
    if ((Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "instance availability evidence") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "instance availability evidence"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "project_identity" -Label "instance availability evidence"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "instance_id" -Label "instance availability evidence"), $Instance.InstanceId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "generation_id" -Label "instance availability evidence"), $script:GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "availability" -Label "instance availability evidence"), "AVAILABLE", [StringComparison]::Ordinal) -or
        -not (Get-RequiredJsonBoolean -Object $document -Name "codedb_status_usable" -Label "instance availability evidence") -or
        -not (Get-RequiredJsonBoolean -Object $document -Name "codedb_text_search_callable" -Label "instance availability evidence") -or
        -not [DateTimeOffset]::TryParse($verifiedText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$verified) -or
        $verified -gt [DateTimeOffset]::UtcNow.AddMinutes(5)) {
        throw "Instance availability evidence identity or result is invalid."
    }
    return [pscustomobject]@{ Path = $path; Document = $document; VerifiedAt = $verified }
}

function New-VerifiedInstanceCandidate {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$GenerationRoot,
        [AllowNull()]$PreviousInstance
    )

    $instanceId = [guid]::NewGuid().ToString("N")
    $relativePath = "$($script:InstancesRelativePath)/$instanceId"
    $instanceRoot = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $relativePath -Label "candidate instance root"
    if (Test-Path -LiteralPath $instanceRoot) { throw "Candidate instance identity collided with an existing path." }
    New-Item -ItemType Directory -Path $instanceRoot | Out-Null
    foreach ($directory in @("config", "index", "adapter", "watch", "leases", "logs", "tmp")) {
        New-Item -ItemType Directory -Path (Join-Path $instanceRoot $directory) | Out-Null
    }
    $createdAt = [DateTime]::UtcNow.ToString("o")
    $document = New-InstanceManifestDocument -Manifest $Manifest -ProjectRoot $ProjectRoot -InstanceId $instanceId -State "PROVISIONING" -CreatedAtUtc $createdAt
    $manifestPath = Write-InstanceManifest -InstanceRoot $instanceRoot -Document $document
    $lease = $null
    $lifecycleId = "candidate-$instanceId"
    try {
        if ($PocFixture) {
            New-Item -ItemType Directory -Force -Path (Join-Path $instanceRoot "watch\lifecycle") | Out-Null
            New-Item -ItemType File -Force -Path (Join-Path $instanceRoot "index\fixture-ready") | Out-Null
            New-Item -ItemType File -Force -Path (Join-Path $instanceRoot "adapter\fixture-ready") | Out-Null
        } else {
            $lease = New-InstanceCandidateEditorLease -ProjectRoot $ProjectRoot -InstanceRoot $instanceRoot -InstanceId $instanceId
            $leaseHeartbeat = {
                Update-InstanceCandidateEditorLease -Lease $lease -InstanceRoot $instanceRoot
            }.GetNewClosure()
            $prepare = Join-Path $GenerationRoot "scripts\prepare-codedb-project-runtime.ps1"
            $adapter = Join-Path $GenerationRoot "scripts\build-codedb-project-text-adapter.ps1"
            $manager = Join-Path $GenerationRoot "scripts\manage-codedb-project-watch.ps1"
            $null = Invoke-InstancePowerShellScript -ScriptPath $prepare -ProjectRoot $ProjectRoot -InstanceRoot $instanceRoot -Arguments @("-Force") -WhileRunning $leaseHeartbeat
            if (Copy-PreservedInstanceRuntimeConfig -ProjectRoot $ProjectRoot -PreviousInstance $PreviousInstance -InstanceRoot $instanceRoot -InstanceRelativePath $relativePath) {
                $null = Invoke-InstancePowerShellScript -ScriptPath $prepare -ProjectRoot $ProjectRoot -InstanceRoot $instanceRoot -WhileRunning $leaseHeartbeat
            }
            $null = Invoke-InstancePowerShellScript -ScriptPath $adapter -ProjectRoot $ProjectRoot -InstanceRoot $instanceRoot -WhileRunning $leaseHeartbeat
            $null = Invoke-InstancePowerShellScript `
                -ScriptPath $manager `
                -ProjectRoot $ProjectRoot `
                -InstanceRoot $instanceRoot `
                -Arguments @("-Action", "Ensure", "-LifecycleId", $lifecycleId, "-RequireNewOwner", "-ExclusiveOwner") `
                -WhileRunning $leaseHeartbeat
        }
        $readyDocument = New-InstanceManifestDocument -Manifest $Manifest -ProjectRoot $ProjectRoot -InstanceId $instanceId -State "READY" -CreatedAtUtc $createdAt
        $manifestPath = Write-InstanceManifest -InstanceRoot $instanceRoot -Document $readyDocument
        $probe = Invoke-InstanceCandidateProbe `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -InstanceRelativePath $relativePath `
            -WhileRunning $(if ($PocFixture) { $null } else { $leaseHeartbeat })
        $null = Write-InstanceAvailabilityEvidence -ProjectRoot $ProjectRoot -InstanceRoot $instanceRoot -InstanceId $instanceId -Probe $probe
        if ($TestFailInstanceCandidate) { throw "Injected candidate verification failure before activation." }
        return [pscustomobject]@{
            InstanceId = $instanceId
            InstanceRelativePath = $relativePath
            InstanceRoot = $instanceRoot
            GenerationRoot = $GenerationRoot
            ManifestPath = $manifestPath
            ManifestSha256 = Get-FileSha256 -Path $manifestPath
            LifecycleId = $lifecycleId
            ProbeLeasePath = if ($null -eq $lease) { $null } else { $lease.Path }
        }
    } catch {
        if (Test-Path -LiteralPath $instanceRoot -PathType Container) {
            $candidateEvidence = $null
            try {
                $candidateEvidence = Get-ValidatedRetiredInstance `
                    -ProjectRoot $ProjectRoot `
                    -Manifest $Manifest `
                    -InstanceRoot $instanceRoot `
                    -AllowProvisioning
                $stopSucceeded = $PocFixture
                if (-not $PocFixture) {
                    $manager = Join-Path $GenerationRoot "scripts\manage-codedb-project-watch.ps1"
                    try {
                        $null = Invoke-InstancePowerShellScript -ScriptPath $manager -ProjectRoot $ProjectRoot -InstanceRoot $instanceRoot -Arguments @("-Action", "Stop", "-ExpectedLifecycleId", $lifecycleId) -TimeoutMilliseconds 30000
                        $stopSucceeded = $true
                    } catch {
                        Write-Warning "Candidate-owned watcher cleanup remains pending: $($_.Exception.Message)"
                    }
                }
                if ($stopSucceeded) {
                    $null = Remove-ValidatedRetiredInstance -Evidence $candidateEvidence -ProjectRoot $ProjectRoot -Manifest $Manifest -AllowProvisioning
                }
            } catch {
                Write-Warning "Candidate instance was retained for safe retirement: $($_.Exception.Message)"
            }
        }
        throw
    }
}

function Assert-InstanceTransactionTarget {
    param([Parameter(Mandatory = $true)][string]$Target)

    $normalized = ConvertTo-SafeRelativePath -Path $Target -Label "instance transaction target"
    if ($normalized -in @(
            $script:InstanceCurrentRelativePath,
            $script:InstanceLastKnownGoodRelativePath,
            $script:InstanceDesiredStateRelativePath,
            $script:CurrentPointerRelativePath,
            $script:LastKnownGoodPointerRelativePath,
            $script:MarkerRelativePath,
            $script:IntegrationStateRelativePath,
            $script:McpConfigRelativePath)) {
        return $normalized
    }
    if ($normalized.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        $script:AllowedTargetPaths.ContainsKey($normalized)) {
        return $normalized
    }
    throw "Instance transaction target is outside the reviewed activation surface: $normalized"
}

function New-InstanceTransactionEntry {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$OperationRoot,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][ValidateSet("Write", "Delete")][string]$Mutation,
        [AllowNull()][byte[]]$DesiredBytes,
        [Parameter(Mandatory = $true)][int]$Index
    )

    $normalizedTarget = Assert-InstanceTransactionTarget -Target $Target
    $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $normalizedTarget -Label "instance transaction target"
    Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "instance transaction target"
    if ((Test-Path -LiteralPath $targetPath) -and -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        throw "Instance transaction target is not a regular file: $normalizedTarget"
    }
    $existed = Test-Path -LiteralPath $targetPath -PathType Leaf
    $originalHash = if ($existed) { Get-FileSha256 -Path $targetPath } else { $null }
    $stagePath = $null
    $desiredHash = $null
    if ($Mutation -eq "Write") {
        if ($null -eq $DesiredBytes) { throw "Instance transaction write is missing desired bytes: $normalizedTarget" }
        $stagePath = Join-Path $OperationRoot ("stage\{0:D4}.new" -f $Index)
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stagePath) | Out-Null
        Write-DurableBytesFile -Path $stagePath -Bytes $DesiredBytes
        $desiredHash = Get-FileSha256 -Path $stagePath
    }
    $backupPath = Join-Path $OperationRoot ("backup\{0:D4}.bak" -f $Index)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $backupPath) | Out-Null
    return [pscustomobject]@{
        Index = $Index
        Target = $normalizedTarget
        TargetPath = $targetPath
        Mutation = $Mutation
        DesiredSha256 = $desiredHash
        StagePath = $stagePath
        ExistedBefore = $existed
        OriginalSha256 = $originalHash
        BackupPath = $backupPath
    }
}

function Write-InstanceOperationJournal {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$OperationId,
        [Parameter(Mandatory = $true)][ValidateSet("PREPARED", "ACTIVATING", "COMMITTED")][string]$State,
        [Parameter(Mandatory = $true)][string]$ActionName,
        [Parameter(Mandatory = $true)][string]$CandidateInstanceId,
        [Parameter(Mandatory = $true)][string]$OperationRoot,
        [Parameter(Mandatory = $true)]$Entries,
        [Parameter(Mandatory = $true)][string]$StageRoot
    )

    $projectPrefix = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $operationRootRelative = [System.IO.Path]::GetFullPath($OperationRoot).Substring($projectPrefix.Length).Replace('\', '/')
    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        operation_id = $OperationId
        operation = $ActionName.ToUpperInvariant()
        state = $State
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        candidate_instance_id = $CandidateInstanceId
        operation_root = $operationRootRelative
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
        entries = @($Entries | ForEach-Object {
            [ordered]@{
                index = $_.Index
                target = $_.Target
                mutation = $_.Mutation.ToLowerInvariant()
                desired_sha256 = $_.DesiredSha256
                stage = if ($null -eq $_.StagePath) { $null } else { [System.IO.Path]::GetFullPath($_.StagePath).Substring($projectPrefix.Length).Replace('\', '/') }
                existed_before = $_.ExistedBefore
                original_sha256 = $_.OriginalSha256
                backup = [System.IO.Path]::GetFullPath($_.BackupPath).Substring($projectPrefix.Length).Replace('\', '/')
            }
        })
    }
    $journalPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceOperationRelativePath -Label "instance operation journal"
    Publish-InstanceAtomicText -Path $journalPath -Content (ConvertTo-InstanceJsonText -Value $document) -StageRoot $StageRoot
}

function Read-InstanceOperationJournal {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $path = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceOperationRelativePath -Label "instance operation journal"
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Instance operation journal is not a regular file." }
    $document = (Read-BoundedJsonDocument -Path $path -Label "instance operation journal" -MaximumBytes (1024 * 1024)).Document
    $operationId = Get-RequiredJsonString -Object $document -Name "operation_id" -Label "instance operation journal"
    $operation = Get-RequiredJsonString -Object $document -Name "operation" -Label "instance operation journal"
    $state = Get-RequiredJsonString -Object $document -Name "state" -Label "instance operation journal"
    $operationRootRelative = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $document -Name "operation_root" -Label "instance operation journal") -Label "instance operation root"
    $candidateId = Get-RequiredJsonString -Object $document -Name "candidate_instance_id" -Label "instance operation journal"
    if ((Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "instance operation journal") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "instance operation journal"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "project_identity" -Label "instance operation journal"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        $operationId -cnotmatch '^[0-9a-f]{32}$' -or
        $candidateId -cnotmatch '^[0-9a-f]{32}$' -or
        $operation -cnotin @("INSTALL", "UPGRADE", "REINSTALL", "UNINSTALL") -or
        $state -cnotin @("PREPARED", "ACTIVATING", "COMMITTED") -or
        (-not $operationRootRelative.StartsWith("$($script:InstancesRelativePath)/$candidateId/tmp/operation-", [StringComparison]::Ordinal) -and
         -not [string]::Equals($operationRootRelative, "$($script:InstanceOperationsRelativePath)/operation-$operationId", [StringComparison]::Ordinal))) {
        throw "Instance operation journal identity or schema is invalid."
    }
    $operationRoot = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $operationRootRelative -Label "instance operation root"
    $entries = New-Object System.Collections.Generic.List[object]
    $seenIndices = @{}
    $seenTargets = @{}
    foreach ($entry in (Get-RequiredJsonArray -Object $document -Name "entries" -Label "instance operation journal")) {
        $null = Assert-JsonObject -Value $entry -Label "instance operation entry"
        $target = Assert-InstanceTransactionTarget -Target (Get-RequiredJsonString -Object $entry -Name "target" -Label "instance operation entry")
        $entryIndex = Get-RequiredJsonInt32 -Object $entry -Name "index" -Label "instance operation entry"
        $mutationText = Get-RequiredJsonString -Object $entry -Name "mutation" -Label "instance operation entry"
        $mutation = if ($mutationText -ceq "write") { "Write" } elseif ($mutationText -ceq "delete") { "Delete" } else { throw "Instance operation entry mutation is invalid." }
        $stageRelative = Get-RequiredJsonNullableString -Object $entry -Name "stage" -Label "instance operation entry"
        $backupRelative = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "backup" -Label "instance operation entry") -Label "instance operation backup"
        $desiredHash = Get-RequiredJsonNullableString -Object $entry -Name "desired_sha256" -Label "instance operation entry"
        $originalHash = Get-RequiredJsonNullableString -Object $entry -Name "original_sha256" -Label "instance operation entry"
        $existedBefore = Get-RequiredJsonBoolean -Object $entry -Name "existed_before" -Label "instance operation entry"
        if (($mutation -eq "Write" -and ([string]::IsNullOrWhiteSpace($stageRelative) -or $desiredHash -cnotmatch '^[0-9a-f]{64}$')) -or
            ($mutation -eq "Delete" -and (-not [string]::IsNullOrWhiteSpace($stageRelative) -or $null -ne $desiredHash)) -or
            ($existedBefore -and $originalHash -cnotmatch '^[0-9a-f]{64}$') -or
            (-not $existedBefore -and $null -ne $originalHash)) {
            throw "Instance operation entry evidence is invalid: $target"
        }
        if ($entryIndex -lt 0 -or $seenIndices.ContainsKey($entryIndex) -or $seenTargets.ContainsKey($target)) {
            throw "Instance operation journal contains a duplicate or invalid entry identity."
        }
        $seenIndices[$entryIndex] = $true
        $seenTargets[$target] = $true
        $stagePath = if ($null -eq $stageRelative) { $null } else { Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath (ConvertTo-SafeRelativePath -Path $stageRelative -Label "instance operation stage") -Label "instance operation stage" }
        $backupPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $backupRelative -Label "instance operation backup"
        Assert-PathInside -Path $backupPath -Root $operationRoot -Label "instance operation backup"
        if ($null -ne $stagePath) { Assert-PathInside -Path $stagePath -Root $operationRoot -Label "instance operation stage" }
        $entries.Add([pscustomobject]@{
            Index = $entryIndex
            Target = $target
            TargetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "instance transaction target"
            Mutation = $mutation
            DesiredSha256 = $desiredHash
            StagePath = $stagePath
            ExistedBefore = $existedBefore
            OriginalSha256 = $originalHash
            BackupPath = $backupPath
        })
    }
    return [pscustomobject]@{
        Path = $path
        OperationId = $operationId
        State = $state
        CandidateInstanceId = $candidateId
        OperationRoot = $operationRoot
        Entries = $entries.ToArray()
    }
}

function Restore-InstanceTransactionEntry {
    param(
        [Parameter(Mandatory = $true)]$Entry,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$AllowUnpublished
    )

    $target = $Entry.TargetPath
    Assert-NoReparsePoint -Path $target -Root $ProjectRoot -Label "instance rollback target"
    if ($AllowUnpublished) {
        $targetExists = Test-Path -LiteralPath $target -PathType Leaf
        $backupExists = Test-Path -LiteralPath $Entry.BackupPath -PathType Leaf
        if ($Entry.ExistedBefore -and -not $backupExists) {
            if ($targetExists -and
                [string]::Equals((Get-FileSha256 -Path $target), [string]$Entry.OriginalSha256, [StringComparison]::OrdinalIgnoreCase)) {
                return
            }
            throw "Instance recovery cannot distinguish an unpublished entry from lost rollback evidence: $($Entry.Target)"
        }
        if (-not $Entry.ExistedBefore -and -not $targetExists) {
            return
        }
    }
    if ($Entry.ExistedBefore) {
        if (-not (Test-Path -LiteralPath $Entry.BackupPath -PathType Leaf)) {
            throw "Instance rollback backup is missing: $($Entry.Target)"
        }
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $displaced = "$target.rollback-$([guid]::NewGuid().ToString('N')).tmp"
            [System.IO.File]::Replace($Entry.BackupPath, $target, $displaced, $true)
            Remove-Item -LiteralPath $displaced -Force -ErrorAction SilentlyContinue
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
            [System.IO.File]::Move($Entry.BackupPath, $target)
        }
        if (-not [string]::Equals((Get-FileSha256 -Path $target), [string]$Entry.OriginalSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Instance rollback verification failed: $($Entry.Target)"
        }
    } elseif (Test-Path -LiteralPath $target) {
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Instance rollback target became a non-file: $($Entry.Target)" }
        if ($null -eq $Entry.DesiredSha256 -or
            -not [string]::Equals((Get-FileSha256 -Path $target), [string]$Entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Instance rollback refuses to delete drifted target: $($Entry.Target)"
        }
        Remove-Item -LiteralPath $target -Force
    }
}

function Invoke-InstanceOperationRecovery {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$StageRoot
    )

    $journal = Read-InstanceOperationJournal -ProjectRoot $ProjectRoot
    if ($null -eq $journal) { return $false }
    Write-Host "[RECOVERY] Found instance operation $($journal.OperationId) in state $($journal.State)."
    if ($journal.State -eq "COMMITTED") {
        Remove-Item -LiteralPath $journal.Path -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $journal.OperationRoot -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    }
    if ($journal.State -eq "PREPARED") {
        Remove-Item -LiteralPath $journal.Path -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $journal.OperationRoot -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    }
    $rollbackError = $null
    foreach ($entry in @($journal.Entries | Sort-Object Index -Descending)) {
        try { Restore-InstanceTransactionEntry -Entry $entry -ProjectRoot $ProjectRoot -AllowUnpublished }
        catch { $rollbackError = $_.Exception.Message; break }
    }
    if ($null -ne $rollbackError) {
        throw "Instance activation recovery could not prove rollback: $rollbackError"
    }
    Remove-Item -LiteralPath $journal.Path -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $journal.OperationRoot -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[RECOVERY] Instance activation rolled back before selecting a new current instance."
    return $true
}

function Publish-InstanceOperation {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ActionName,
        [Parameter(Mandatory = $true)][string]$CandidateInstanceId,
        [Parameter(Mandatory = $true)]$Entries,
        [Parameter(Mandatory = $true)][string]$StageRoot,
        [Parameter(Mandatory = $true)][string]$OperationRoot,
        [AllowNull()][scriptblock]$VerifyBeforeCommit,
        [AllowNull()][string]$OperationId
    )

    $journalOperationId = if ([string]::IsNullOrWhiteSpace($OperationId)) { [guid]::NewGuid().ToString("N") } else { $OperationId }
    if ($journalOperationId -cnotmatch '^[0-9a-f]{32}$') { throw "Instance operation identity is invalid." }
    Write-InstanceOperationJournal -ProjectRoot $ProjectRoot -OperationId $journalOperationId -State "PREPARED" -ActionName $ActionName -CandidateInstanceId $CandidateInstanceId -OperationRoot $OperationRoot -Entries $Entries -StageRoot $StageRoot
    Write-InstanceOperationJournal -ProjectRoot $ProjectRoot -OperationId $journalOperationId -State "ACTIVATING" -ActionName $ActionName -CandidateInstanceId $CandidateInstanceId -OperationRoot $OperationRoot -Entries $Entries -StageRoot $StageRoot
    $publishedEntries = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($entry in @($Entries)) {
            Assert-NoReparsePoint -Path $entry.TargetPath -Root $ProjectRoot -Label "instance activation target"
            if ($entry.ExistedBefore) {
                if (-not (Test-Path -LiteralPath $entry.TargetPath -PathType Leaf) -or
                    -not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), [string]$entry.OriginalSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Instance activation target changed after preflight: $($entry.Target)"
                }
            } elseif (Test-Path -LiteralPath $entry.TargetPath) {
                throw "Instance activation target appeared after preflight: $($entry.Target)"
            }
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
            if ($entry.Mutation -eq "Write") {
                if ($entry.ExistedBefore) {
                    [System.IO.File]::Replace($entry.StagePath, $entry.TargetPath, $entry.BackupPath, $true)
                    if (-not [string]::Equals((Get-FileSha256 -Path $entry.BackupPath), [string]$entry.OriginalSha256, [StringComparison]::OrdinalIgnoreCase)) {
                        throw "Instance activation replacement pre-image verification failed: $($entry.Target)"
                    }
                } else {
                    [System.IO.File]::Move($entry.StagePath, $entry.TargetPath)
                }
                if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), [string]$entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Instance activation publication verification failed: $($entry.Target)"
                }
            } else {
                if ($entry.ExistedBefore) {
                    [System.IO.File]::Copy($entry.TargetPath, $entry.BackupPath, $true)
                    [System.IO.File]::Delete($entry.TargetPath)
                }
            }
            $publishedEntries.Add($entry)
            Add-MaterializerMutationScope -Scope "instance_activation"
            Invoke-TestFaultAfterMutation
        }
        if ($null -ne $VerifyBeforeCommit) { & $VerifyBeforeCommit }
        Write-InstanceOperationJournal -ProjectRoot $ProjectRoot -OperationId $journalOperationId -State "COMMITTED" -ActionName $ActionName -CandidateInstanceId $CandidateInstanceId -OperationRoot $OperationRoot -Entries $Entries -StageRoot $StageRoot
        $journalPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceOperationRelativePath -Label "instance operation journal"
        Remove-Item -LiteralPath $journalPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $OperationRoot -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        $originalError = $_.Exception.Message
        $rollbackError = $null
        foreach ($entry in @($publishedEntries | Sort-Object Index -Descending)) {
            try { Restore-InstanceTransactionEntry -Entry $entry -ProjectRoot $ProjectRoot }
            catch { $rollbackError = $_.Exception.Message; break }
        }
        if ($null -eq $rollbackError) {
            $journalPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceOperationRelativePath -Label "instance operation journal"
            Remove-Item -LiteralPath $journalPath -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $OperationRoot -Recurse -Force -ErrorAction SilentlyContinue
            throw $originalError
        }
        throw "Instance activation failed and rollback was not proven: $originalError; $rollbackError"
    }
}

function Add-InstanceTransactionEntryIfNeeded {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$Entries,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$OperationRoot,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][ValidateSet("Write", "Delete")][string]$Mutation,
        [AllowNull()][byte[]]$DesiredBytes
    )

    $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $Target -Label "instance activation target"
    if ($Mutation -eq "Write" -and (Test-Path -LiteralPath $targetPath -PathType Leaf) -and $null -ne $DesiredBytes) {
        $existing = [System.IO.File]::ReadAllBytes($targetPath)
        if ($existing.Length -eq $DesiredBytes.Length) {
            $same = $true
            for ($index = 0; $index -lt $existing.Length; $index++) {
                if ($existing[$index] -ne $DesiredBytes[$index]) { $same = $false; break }
            }
            if ($same) { return }
        }
    }
    if ($Mutation -eq "Delete" -and -not (Test-Path -LiteralPath $targetPath)) { return }
    $Entries.Add((New-InstanceTransactionEntry -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $Target -Mutation $Mutation -DesiredBytes $DesiredBytes -Index $Entries.Count))
}

function Get-InstanceActivationBytes {
    param([Parameter(Mandatory = $true)]$Manifest,[Parameter(Mandatory = $true)][string]$Target)

    if (-not $Manifest.TargetMap.ContainsKey($Target)) { throw "Payload manifest has no activation source for $Target" }
    return [System.IO.File]::ReadAllBytes([string]$Manifest.TargetMap[$Target].SourcePath)
}

function New-InstanceSelectionDocument {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Candidate
    )

    return [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
        instance_id = $Candidate.InstanceId
        instance_relative_path = $Candidate.InstanceRelativePath
        instance_manifest_sha256 = $Candidate.ManifestSha256
        generation_id = $script:GenerationId
        activated_at_utc = [DateTime]::UtcNow.ToString("o")
    }
}

function Get-InstanceSelectedInstance {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )
    try { return Get-ValidatedCurrentInstance -Manifest $Manifest -ProjectRoot $ProjectRoot -AllowMissing }
    catch { throw "Existing CodeDB instance selection is ambiguous; Reinstall cannot safely replace it: $($_.Exception.Message)" }
}

function Assert-InstancePreflight {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [AllowNull()]$PreviousInstance,
        [Parameter(Mandatory = $true)][ValidateSet("Install", "Upgrade", "Reinstall")][string]$ActionName
    )

    if ($null -ne $PreviousInstance) {
        # Once a Package-owned instance is selected, the legacy marker and flat
        # payload are retirement evidence. Reinstall must only prove that its
        # unavoidable stable-launcher target is absent or still Package-owned.
        $wrapperTarget = "$($script:TargetPrefix)wrapper/codedb-project-wrapper.mjs"
        $wrapperPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $wrapperTarget -Label "stable instance wrapper"
        if (Test-Path -LiteralPath $wrapperPath) {
            if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf)) {
                throw "Stable instance wrapper target is not a regular file."
            }
            Assert-NoReparsePoint -Path $wrapperPath -Root $ProjectRoot -Label "stable instance wrapper"
            $previousPackageIdentity = Get-InstanceGenerationPackageIdentity `
                -Manifest $Manifest `
                -InstanceManifest $PreviousInstance.Manifest
            $expectedWrapperHash = [string]$previousPackageIdentity.StableWrapperSha256
            if (-not [string]::Equals((Get-FileSha256 -Path $wrapperPath), $expectedWrapperHash, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Stable instance wrapper target contains unowned or drifted bytes."
            }
        }
        return $null
    }

    if ($ActionName -eq "Install") {
        $retirementControls = @(Get-ValidatedInstanceRetirementControls -ProjectRoot $ProjectRoot -Manifest $Manifest)
        if ($retirementControls.Count -gt 0) {
            $null = @(Get-MarkerlessInstanceClosureFiles -Manifest $Manifest -ProjectRoot $ProjectRoot)
            return $null
        }
    }

    $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    $unsafe = @($plan.Files | Where-Object {
        -not $_.IsRuntime -and $_.Status -in @("Conflict", "ManagedDrift", "ManagedMissing")
    })
    if ($unsafe.Count -gt 0) {
        throw "Instance activation is blocked by unowned or drifted Package bootstrap bytes: $($unsafe[0].Target) ($($unsafe[0].Detail))."
    }
    return $plan
}

function Get-InstanceActivationEntries {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Candidate,
        [Parameter(Mandatory = $true)][string]$OperationRoot,
        [Parameter(Mandatory = $true)][ValidateSet("Install", "Upgrade", "Reinstall")][string]$ActionName,
        [AllowNull()]$PreviousInstance,
        [AllowNull()][string]$UninstallStateId
    )

    $entries = New-Object System.Collections.Generic.List[object]
    $wrapperTarget = "$($script:TargetPrefix)wrapper/codedb-project-wrapper.mjs"
    $wrapperBytes = Get-InstanceActivationBytes -Manifest $Manifest -Target $wrapperTarget

    $generationPointerPath = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:CurrentPointerRelativePath `
        -Label "legacy generation pointer"
    if (Test-Path -LiteralPath $generationPointerPath) {
        if (-not (Test-Path -LiteralPath $generationPointerPath -PathType Leaf) -or
            $null -eq (Get-ValidatedInstalledGenerationPointer -PointerPath $generationPointerPath -ProjectRoot $ProjectRoot)) {
            throw "Existing generation pointer cannot be retained for the legacy execution closure."
        }
    } else {
        # A clean install has no legacy process that can observe host/current.
        # Publish the Package pointer for Editor diagnostics; upgrades retain the
        # old pointer until the legacy owner/lease window has drained.
        $generationPointerBytes = Get-InstanceActivationBytes -Manifest $Manifest -Target $script:CurrentPointerRelativePath
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $script:CurrentPointerRelativePath -Mutation "Write" -DesiredBytes $generationPointerBytes
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $script:LastKnownGoodPointerRelativePath -Mutation "Write" -DesiredBytes $generationPointerBytes
    }

    $mcpPlanParameters = @{ ProjectRoot = $ProjectRoot }
    if ($ActionName -eq "Install") {
        $null = Assert-ProjectIntegrationStateId -StateId $UninstallStateId
        $mcpPlanParameters.RestoreUninstalledNamespace = $true
        $mcpPlanParameters.UninstallStateId = $UninstallStateId
    }
    $mcpPlan = Get-RepairMcpConfigPlan @mcpPlanParameters
    if (-not $mcpPlan.Current) {
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $script:McpConfigRelativePath -Mutation "Write" -DesiredBytes $mcpPlan.DesiredBytes
    }

    $stateId = [guid]::NewGuid().ToString("N")
    $desired = New-InstanceDesiredStateDocument -ProjectRoot $ProjectRoot -DesiredState "INSTALLED" -StateId $stateId -CleanupState "COMPLETE"
    $desiredBytes = [System.Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-InstanceJsonText -Value $desired))
    Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $script:InstanceDesiredStateRelativePath -Mutation "Write" -DesiredBytes $desiredBytes
    $legacyIntegrationPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:IntegrationStateRelativePath -Label "legacy integration state"
    if (Test-Path -LiteralPath $legacyIntegrationPath) {
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $script:IntegrationStateRelativePath -Mutation "Delete" -DesiredBytes $null
    }

    $selection = New-InstanceSelectionDocument -ProjectRoot $ProjectRoot -Candidate $Candidate
    $selectionBytes = [System.Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-InstanceJsonText -Value $selection))
    $lkgTarget = $script:InstanceLastKnownGoodRelativePath
    Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $lkgTarget -Mutation "Write" -DesiredBytes $selectionBytes

    # Publish the stable launcher before the selection pointer. During this
    # short window a new launcher fails closed because no new selection exists;
    # the pointer is the final activation commit point.
    Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $wrapperTarget -Mutation "Write" -DesiredBytes $wrapperBytes
    Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $OperationRoot -Target $script:InstanceCurrentRelativePath -Mutation "Write" -DesiredBytes $selectionBytes

    return [pscustomobject]@{ Entries = $entries.ToArray(); StateId = $stateId; McpPlan = $mcpPlan }
}

function Get-InstanceManifestExpectedHash {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if ($null -eq $Manifest.TargetMap -or -not $Manifest.TargetMap.ContainsKey($Target)) {
        throw "Package payload does not contain the reviewed instance identity: $Target"
    }
    $hash = [string]$Manifest.TargetMap[$Target].Sha256
    if ($hash -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Package payload contains an invalid instance identity hash: $Target"
    }
    return $hash.ToLowerInvariant()
}

function Assert-InstanceStableWrapper {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    $expected = $ExpectedSha256.ToLowerInvariant()
    if ($expected -notmatch '^[0-9a-f]{64}$') {
        throw "Selected instance has no valid Package-owned stable-wrapper identity."
    }
    $wrapperPath = Get-InstanceProjectPath `
        -ProjectRoot $ProjectRoot `
        -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs" `
        -Label "selected stable wrapper"
    if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf)) {
        throw "Selected stable wrapper is missing."
    }
    if (-not [string]::Equals((Get-FileSha256 -Path $wrapperPath), $expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Selected stable wrapper does not match the Package-declared runtime identity."
    }
}

function Get-InstanceGenerationPackageIdentity {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$InstanceManifest
    )

    $packageVersion = Get-RequiredJsonString -Object $InstanceManifest -Name "package_version" -Label "retired instance manifest"
    $payloadVersion = Get-RequiredJsonString -Object $InstanceManifest -Name "payload_version" -Label "retired instance manifest"
    $payloadSequence = Get-RequiredJsonInt32 -Object $InstanceManifest -Name "payload_sequence" -Label "retired instance manifest"
    $generationId = Get-RequiredJsonString -Object $InstanceManifest -Name "generation_id" -Label "retired instance manifest"
    $bootstrapProtocol = Get-RequiredJsonInt32 -Object $InstanceManifest -Name "bootstrap_protocol" -Label "retired instance manifest"
    $workerRelativePath = ConvertTo-SafeRelativePath `
        -Path (Get-RequiredJsonString -Object $InstanceManifest -Name "worker_relative_path" -Label "retired instance manifest") `
        -Label "retired instance worker path"
    if (-not [string]::Equals($workerRelativePath, $script:InstanceWorkerRelativePath, [StringComparison]::Ordinal)) {
        throw "Retired instance worker path is not the reviewed Package path."
    }

    $isCurrent = [string]::Equals($packageVersion, [string]$Manifest.PackageVersion, [StringComparison]::Ordinal) -and
        [string]::Equals($payloadVersion, [string]$Manifest.PayloadVersion, [StringComparison]::Ordinal) -and
        $payloadSequence -eq [int]$Manifest.PayloadSequence -and
        [string]::Equals($generationId, [string]$Manifest.GenerationId, [StringComparison]::Ordinal) -and
        $bootstrapProtocol -eq [int]$Manifest.BootstrapProtocol
    if ($isCurrent) {
        $generationTargetPrefix = "AIWork/.runtime/codedb/host/generations/$generationId/"
        return [pscustomobject]@{
            Current = $true
            PackageVersion = $packageVersion
            PayloadVersion = $payloadVersion
            PayloadSequence = $payloadSequence
            GenerationId = $generationId
            BootstrapProtocol = $bootstrapProtocol
            GenerationManifestSha256 = Get-InstanceManifestExpectedHash -Manifest $Manifest -Target ($generationTargetPrefix + "generation-manifest.json")
            WorkerSha256 = Get-InstanceManifestExpectedHash -Manifest $Manifest -Target ($generationTargetPrefix + $workerRelativePath)
            StableWrapperSha256 = Get-InstanceManifestExpectedHash -Manifest $Manifest -Target "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
        }
    }

    if ($payloadSequence -ge [int]$Manifest.PayloadSequence) {
        throw "Retired instance reuses or exceeds the current payload sequence with a different identity."
    }
    $matches = @($Manifest.BootstrapTransitions | Where-Object {
        [string]::Equals([string]$_.SourcePackageVersion, $packageVersion, [StringComparison]::Ordinal) -and
        [string]::Equals([string]$_.SourcePayloadVersion, $payloadVersion, [StringComparison]::Ordinal) -and
        [int]$_.SourcePayloadSequence -eq $payloadSequence -and
        [string]::Equals([string]$_.SourceGenerationId, $generationId, [StringComparison]::Ordinal) -and
        [int]$_.SourceBootstrapProtocol -eq $bootstrapProtocol
    })
    if ($matches.Count -ne 1) {
        throw "Retired instance is not an exact Package-declared transition."
    }

    $generationTargetPrefix = "AIWork/.runtime/codedb/host/generations/$generationId/"
    $generationManifestTarget = $generationTargetPrefix + "generation-manifest.json"
    $workerTarget = $generationTargetPrefix + $workerRelativePath
    if ($null -eq $Manifest.RetiredTargetMap -or
        -not $Manifest.RetiredTargetMap.ContainsKey($generationManifestTarget) -or
        -not $Manifest.RetiredTargetMap.ContainsKey($workerTarget)) {
        throw "Package payload does not retain the declared previous generation identity."
    }

    $packageGenerationRoot = ConvertTo-AbsoluteChildPath `
        -Root $Manifest.Root `
        -RelativePath "Generations/$generationId" `
        -Label "Package previous generation"
    $packageGenerationManifestPath = Join-Path $packageGenerationRoot "generation-manifest.json"
    $packageWorkerPath = ConvertTo-AbsoluteChildPath `
        -Root $packageGenerationRoot `
        -RelativePath $workerRelativePath `
        -Label "Package previous generation worker"
    Assert-NoReparsePoint -Path $packageGenerationRoot -Root $Manifest.Root -Label "Package previous generation"
    Assert-NoReparsePoint -Path $packageGenerationManifestPath -Root $packageGenerationRoot -Label "Package previous generation manifest"
    Assert-NoReparsePoint -Path $packageWorkerPath -Root $packageGenerationRoot -Label "Package previous generation worker"
    if (-not (Test-Path -LiteralPath $packageGenerationManifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $packageWorkerPath -PathType Leaf)) {
        throw "Package-preserved previous generation identity is incomplete."
    }

    return [pscustomobject]@{
        Current = $false
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        GenerationId = $generationId
        BootstrapProtocol = $bootstrapProtocol
        GenerationManifestSha256 = Get-FileSha256 -Path $packageGenerationManifestPath
        WorkerSha256 = Get-FileSha256 -Path $packageWorkerPath
        StableWrapperSha256 = [string]$matches[0].SourceStableWrapperSha256
    }
}

function Test-InstanceGenerationIdIsPackageSupported {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$GenerationId
    )

    $matches = if ([string]::Equals($GenerationId, [string]$Manifest.GenerationId, [StringComparison]::Ordinal)) { 1 } else { 0 }
    foreach ($transition in @($Manifest.BootstrapTransitions)) {
        if ([string]::Equals($GenerationId, [string]$transition.SourceGenerationId, [StringComparison]::Ordinal)) {
            $matches++
        }
    }
    return $matches -eq 1
}

function Assert-InstanceGenerationClosure {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$InstanceManifest
    )

    $packageIdentity = Get-InstanceGenerationPackageIdentity -Manifest $Manifest -InstanceManifest $InstanceManifest
    $generationId = [string]$packageIdentity.GenerationId
    $generationRelativePath = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $InstanceManifest -Name "generation_relative_path" -Label "retired instance manifest") -Label "retired instance generation path"
    $expectedGenerationRelativePath = "AIWork/.runtime/codedb/host/generations/$generationId"
    if (-not [string]::Equals($generationRelativePath, $expectedGenerationRelativePath, [StringComparison]::Ordinal)) {
        throw "Retired instance generation path is not the reviewed immutable path."
    }
    $generationRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $generationRelativePath -Label "retired instance generation"
    Assert-NoReparsePoint -Path $generationRoot -Root $ProjectRoot -Label "retired instance generation"
    if (-not (Test-Path -LiteralPath $generationRoot -PathType Container)) {
        throw "Retired instance generation root is missing."
    }
    $generationManifestPath = Join-Path $generationRoot "generation-manifest.json"
    Assert-NoReparsePoint -Path $generationManifestPath -Root $generationRoot -Label "retired instance generation manifest"
    $expectedGenerationHash = [string]$packageIdentity.GenerationManifestSha256
    $recordedGenerationHash = (Get-RequiredJsonString -Object $InstanceManifest -Name "generation_manifest_sha256" -Label "retired instance manifest").ToLowerInvariant()
    if (-not [string]::Equals($recordedGenerationHash, $expectedGenerationHash, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-FileSha256 -Path $generationManifestPath), $expectedGenerationHash, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Retired instance generation manifest is not Package-owned."
    }

    $generationDocument = (Read-BoundedJsonDocument -Path $generationManifestPath -Label "retired instance generation manifest" -MaximumBytes (1024 * 1024)).Document
    $generationFiles = Get-RequiredJsonArray -Object $generationDocument -Name "files" -Label "retired instance generation manifest"
    if ((Get-RequiredJsonInt32 -Object $generationDocument -Name "schema_version" -Label "retired instance generation manifest") -ne 1 -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generationDocument -Name "managed_by" -Label "retired instance generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generationDocument -Name "generation_id" -Label "retired instance generation manifest"), $generationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generationDocument -Name "package_version" -Label "retired instance generation manifest"), [string]$packageIdentity.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $generationDocument -Name "payload_version" -Label "retired instance generation manifest"), [string]$packageIdentity.PayloadVersion, [StringComparison]::Ordinal) -or
        (Get-RequiredJsonInt32 -Object $generationDocument -Name "payload_sequence" -Label "retired instance generation manifest") -ne [int]$packageIdentity.PayloadSequence -or
        (Get-RequiredJsonInt32 -Object $generationDocument -Name "bootstrap_protocol" -Label "retired instance generation manifest") -ne [int]$packageIdentity.BootstrapProtocol -or
        $generationFiles.Count -eq 0) {
        throw "Retired instance generation manifest identity is invalid."
    }
    $seen = @{}
    foreach ($entry in $generationFiles) {
        $null = Assert-JsonObject -Value $entry -Label "retired instance generation file"
        $relativePath = ConvertTo-SafeRelativePath -Path (Get-RequiredJsonString -Object $entry -Name "path" -Label "retired instance generation file") -Label "retired instance generation file"
        $hash = (Get-RequiredJsonString -Object $entry -Name "sha256" -Label "retired instance generation file").ToLowerInvariant()
        if ($hash -notmatch '^[0-9a-f]{64}$' -or $seen.ContainsKey($relativePath)) {
            throw "Retired instance generation manifest contains a duplicate or invalid file."
        }
        $seen[$relativePath] = $true
        $filePath = ConvertTo-AbsoluteChildPath -Root $generationRoot -RelativePath $relativePath -Label "retired instance generation file"
        Assert-NoReparsePoint -Path $filePath -Root $generationRoot -Label "retired instance generation file"
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $filePath), $hash, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Retired instance generation file is missing or drifted: $relativePath"
        }
    }
    Assert-ImmutableGenerationFilesystemClosure -Root $generationRoot -ExpectedFiles (@("generation-manifest.json") + @($seen.Keys)) -Label "retired immutable generation"

    $workerRelativePath = $script:InstanceWorkerRelativePath
    $expectedWorkerHash = [string]$packageIdentity.WorkerSha256
    $recordedWorkerHash = (Get-RequiredJsonString -Object $InstanceManifest -Name "worker_sha256" -Label "retired instance manifest").ToLowerInvariant()
    $workerPath = ConvertTo-AbsoluteChildPath -Root $generationRoot -RelativePath $workerRelativePath -Label "retired instance worker"
    Assert-NoReparsePoint -Path $workerPath -Root $generationRoot -Label "retired instance worker"
    if (-not [string]::Equals($recordedWorkerHash, $expectedWorkerHash, [StringComparison]::OrdinalIgnoreCase) -or
        -not (Test-Path -LiteralPath $workerPath -PathType Leaf) -or
        -not [string]::Equals((Get-FileSha256 -Path $workerPath), $expectedWorkerHash, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Retired instance worker is not Package-owned."
    }
    return [pscustomobject]@{
        GenerationRoot = $generationRoot
        GenerationId = $generationId
        WorkerPath = $workerPath
        StableWrapperSha256 = [string]$packageIdentity.StableWrapperSha256
        Disposition = if ($packageIdentity.Current) { "CURRENT" } else { "TRUSTED_PREVIOUS" }
    }
}

function Get-ValidatedRetiredInstance {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$InstanceRoot,
        [switch]$AllowProvisioning
    )

    Assert-NoReparsePoint -Path $InstanceRoot -Root $ProjectRoot -Label "retired instance"
    if (-not (Test-Path -LiteralPath $InstanceRoot -PathType Container)) {
        throw "Retired instance root is not a directory."
    }
    $instanceId = Split-Path -Leaf $InstanceRoot
    if ($instanceId -cnotmatch '^[0-9a-f]{32}$') {
        throw "Retired instance directory name is not an instance identity."
    }
    $allowedDirectories = @{}
    foreach ($name in $script:InstanceAllowedDirectories) { $allowedDirectories[$name] = $true }
    foreach ($item in @(Get-ChildItem -LiteralPath $InstanceRoot -Force -ErrorAction Stop)) {
        Assert-NoReparsePoint -Path $item.FullName -Root $InstanceRoot -Label "retired instance entry"
        if ($item.PSIsContainer) {
            if (-not $allowedDirectories.ContainsKey($item.Name)) { throw "Retired instance contains an unexpected top-level directory: $($item.Name)" }
        } elseif ($item.Name -ne "instance.json" -and $item.Name -ne $script:InstanceRetiringFileName) {
            throw "Retired instance contains an unexpected top-level file: $($item.Name)"
        }
    }
    foreach ($name in $script:InstanceAllowedDirectories) {
        $directoryPath = Join-Path $InstanceRoot $name
        if ($script:InstanceOptionalDirectories -contains $name -and -not (Test-Path -LiteralPath $directoryPath)) {
            # A released instance lease removes its empty lease directory. Its
            # absence is equivalent to an empty, validated lease root.
            continue
        }
        if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            throw "Retired instance is missing its owned directory: $name"
        }
    }
    foreach ($item in @(Get-ChildItem -LiteralPath $InstanceRoot -Force -Recurse -ErrorAction Stop)) {
        Assert-NoReparsePoint -Path $item.FullName -Root $InstanceRoot -Label "retired instance closure"
    }

    $manifestPath = Join-Path $InstanceRoot "instance.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Retired instance manifest is missing." }
    $document = (Read-BoundedJsonDocument -Path $manifestPath -Label "retired instance manifest" -MaximumBytes (128 * 1024)).Document
    $state = Get-RequiredJsonString -Object $document -Name "state" -Label "retired instance manifest"
    $expectedStates = @("READY", "RETIRED")
    if ($AllowProvisioning) { $expectedStates += "PROVISIONING" }
    if ($state -cnotin $expectedStates -or
        (Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "retired instance manifest") -ne $script:InstanceSchemaVersion -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "retired instance manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "project_identity" -Label "retired instance manifest"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "instance_id" -Label "retired instance manifest"), $instanceId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "instance_relative_path" -Label "retired instance manifest"), "$($script:InstancesRelativePath)/$instanceId", [StringComparison]::Ordinal)) {
        throw "Retired instance manifest identity or state is invalid."
    }
    $retiringPath = Join-Path $InstanceRoot $script:InstanceRetiringFileName
    if (Test-Path -LiteralPath $retiringPath) {
        $retiring = (Read-BoundedJsonDocument -Path $retiringPath -Label "retired instance marker" -MaximumBytes (32 * 1024)).Document
        if ((Get-RequiredJsonInt32 -Object $retiring -Name "schema_version" -Label "retired instance marker") -ne 1 -or
            -not [string]::Equals((Get-RequiredJsonString -Object $retiring -Name "managed_by" -Label "retired instance marker"), $script:ManagedBy, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-RequiredJsonString -Object $retiring -Name "instance_id" -Label "retired instance marker"), $instanceId, [StringComparison]::Ordinal)) {
            throw "Retired instance marker identity is invalid."
        }
    }
    $generation = Assert-InstanceGenerationClosure -Manifest $Manifest -ProjectRoot $ProjectRoot -InstanceManifest $document
    return [pscustomobject]@{
        InstanceId = $instanceId
        InstanceRoot = $InstanceRoot
        ManifestPath = $manifestPath
        Manifest = $document
        Generation = $generation
        LeaseRoot = Join-Path $InstanceRoot $script:InstanceLeaseDirectoryName
        EditorLeaseRoot = Join-Path $InstanceRoot "watch\lifecycle\editor-leases"
        CoordinatorStatePath = Join-Path $InstanceRoot "watch\coordinator\coordinator-state.json"
    }
}

function Get-InstanceLeaseEvidence {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $live = New-Object System.Collections.Generic.List[object]
    $stale = New-Object System.Collections.Generic.List[object]
    $invalid = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $Evidence.LeaseRoot)) {
        return [pscustomobject]@{ Live = $live.ToArray(); Stale = $stale.ToArray(); Invalid = $invalid.ToArray() }
    }
    if (-not (Test-Path -LiteralPath $Evidence.LeaseRoot -PathType Container)) {
        $invalid.Add($Evidence.LeaseRoot)
        return [pscustomobject]@{ Live = $live.ToArray(); Stale = $stale.ToArray(); Invalid = $invalid.ToArray() }
    }
    Assert-NoReparsePoint -Path $Evidence.LeaseRoot -Root $Evidence.InstanceRoot -Label "instance lease root"
    $now = [DateTimeOffset]::UtcNow
    foreach ($item in @(Get-ChildItem -LiteralPath $Evidence.LeaseRoot -Force -ErrorAction Stop)) {
        try {
            Assert-NoReparsePoint -Path $item.FullName -Root $Evidence.LeaseRoot -Label "instance lease"
            $match = [regex]::Match($item.Name, '^mcp-([0-9]+)-([0-9a-f]{32})\.json$')
            if ($item.PSIsContainer -or -not $match.Success) { throw "invalid instance lease name" }
            $lease = (Read-BoundedJsonDocument -Path $item.FullName -Label "instance lease" -MaximumBytes (64 * 1024)).Document
            $leaseId = Get-RequiredJsonString -Object $lease -Name "lease_id" -Label "instance lease"
            $createdText = Get-RequiredJsonString -Object $lease -Name "created_at_utc" -Label "instance lease"
            $heartbeatText = Get-RequiredJsonString -Object $lease -Name "heartbeat_at_utc" -Label "instance lease"
            [DateTimeOffset]$created = [DateTimeOffset]::MinValue
            [DateTimeOffset]$heartbeat = [DateTimeOffset]::MinValue
            $valid = (Get-RequiredJsonInt32 -Object $lease -Name "schema_version" -Label "instance lease") -eq 1 -and
                (Get-RequiredJsonInt32 -Object $lease -Name "instance_lease_version" -Label "instance lease") -eq 1 -and
                [string]::Equals((Get-RequiredJsonString -Object $lease -Name "managed_by" -Label "instance lease"), $script:ManagedBy, [StringComparison]::Ordinal) -and
                [string]::Equals((Get-RequiredJsonString -Object $lease -Name "owner" -Label "instance lease"), "mcp", [StringComparison]::Ordinal) -and
                [string]::Equals((Get-RequiredJsonString -Object $lease -Name "instance_id" -Label "instance lease"), $Evidence.InstanceId, [StringComparison]::Ordinal) -and
                [string]::Equals((Get-RequiredJsonString -Object $lease -Name "generation_id" -Label "instance lease"), [string]$Evidence.Generation.GenerationId, [StringComparison]::Ordinal) -and
                [string]::Equals($leaseId, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                (Get-RequiredJsonInt32 -Object $lease -Name "pid" -Label "instance lease") -eq [int]$match.Groups[1].Value -and
                (Get-RequiredJsonString -Object $lease -Name "process_start_identity" -Label "instance lease") -match '^[0-9]{1,20}$' -and
                [string]::Equals([System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $lease -Name "project_root" -Label "instance lease")), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
                [string]::Equals((Get-RequiredJsonString -Object $lease -Name "project_identity" -Label "instance lease"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -and
                [DateTimeOffset]::TryParse($createdText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$created) -and
                [DateTimeOffset]::TryParse($heartbeatText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$heartbeat) -and
                $created -le $heartbeat -and
                $heartbeat -le $now.AddMinutes(5)
            if (-not $valid) { throw "invalid instance lease evidence" }
            $leasePid = Get-RequiredJsonInt32 -Object $lease -Name "pid" -Label "instance lease"
            $identity = Get-MaterializerProcessIdentity -ProcessId $leasePid
            $identityMatches = Test-MaterializerGenerationProcessIdentity -ProcessIdentity $identity -LeaseIdentity (Get-RequiredJsonString -Object $lease -Name "process_start_identity" -Label "instance lease")
            if ($identity.Alive -and ($null -eq $identityMatches -or $identityMatches)) {
                $live.Add([pscustomobject]@{ Path = $item.FullName; ProcessId = $leasePid })
            } else {
                $stale.Add([pscustomobject]@{ Path = $item.FullName; ProcessId = $leasePid })
            }
        } catch {
            $invalid.Add($item.FullName)
        }
    }
    return [pscustomobject]@{ Live = $live.ToArray(); Stale = $stale.ToArray(); Invalid = $invalid.ToArray() }
}

function Get-InstanceEditorLeaseEvidence {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $live = New-Object System.Collections.Generic.List[object]
    $stale = New-Object System.Collections.Generic.List[object]
    $invalid = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $Evidence.EditorLeaseRoot)) {
        return [pscustomobject]@{ Live = $live.ToArray(); Stale = $stale.ToArray(); Invalid = $invalid.ToArray() }
    }
    if (-not (Test-Path -LiteralPath $Evidence.EditorLeaseRoot -PathType Container)) {
        $invalid.Add($Evidence.EditorLeaseRoot)
        return [pscustomobject]@{ Live = $live.ToArray(); Stale = $stale.ToArray(); Invalid = $invalid.ToArray() }
    }
    Assert-NoReparsePoint -Path $Evidence.EditorLeaseRoot -Root $Evidence.InstanceRoot -Label "instance Editor lease root"
    foreach ($item in @(Get-ChildItem -LiteralPath $Evidence.EditorLeaseRoot -Force -ErrorAction Stop)) {
        try {
            Assert-NoReparsePoint -Path $item.FullName -Root $Evidence.EditorLeaseRoot -Label "instance Editor lease"
            if ($item.PSIsContainer -or $item.Name -notmatch '^[A-Za-z0-9._-]{1,128}\.json$') { throw "invalid editor lease name" }
            $lease = (Read-BoundedJsonDocument -Path $item.FullName -Label "instance Editor lease" -MaximumBytes (64 * 1024)).Document
            $sessionId = Get-RequiredJsonString -Object $lease -Name "session_id" -Label "instance Editor lease"
            if ("$sessionId.json" -cne $item.Name -or
                (Get-RequiredJsonInt32 -Object $lease -Name "schema_version" -Label "instance Editor lease") -ne 1 -or
                -not [string]::Equals((Get-RequiredJsonString -Object $lease -Name "managed_by" -Label "instance Editor lease"), $script:ManagedBy, [StringComparison]::Ordinal) -or
                (Get-RequiredJsonInt32 -Object $lease -Name "editor_pid" -Label "instance Editor lease") -le 0 -or
                (Get-RequiredJsonString -Object $lease -Name "process_start_ticks" -Label "instance Editor lease") -notmatch '^[0-9]+$' -or
                -not [string]::Equals([System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $lease -Name "project_root" -Label "instance Editor lease")), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -or
                -not [string]::Equals((Get-RequiredJsonString -Object $lease -Name "project_identity" -Label "instance Editor lease"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal)) {
                throw "invalid editor lease evidence"
            }
            $editorLeasePid = Get-RequiredJsonInt32 -Object $lease -Name "editor_pid" -Label "instance Editor lease"
            $identity = Get-MaterializerProcessIdentity -ProcessId $editorLeasePid
            if ($identity.Alive -and ($null -eq $identity.StartTicks -or [string]::Equals($identity.StartTicks, (Get-RequiredJsonString -Object $lease -Name "process_start_ticks" -Label "instance Editor lease"), [StringComparison]::Ordinal))) {
                $live.Add([pscustomobject]@{ Path = $item.FullName; ProcessId = $editorLeasePid })
            } else {
                $stale.Add([pscustomobject]@{ Path = $item.FullName; ProcessId = $editorLeasePid })
            }
        } catch {
            $invalid.Add($item.FullName)
        }
    }
    return [pscustomobject]@{ Live = $live.ToArray(); Stale = $stale.ToArray(); Invalid = $invalid.ToArray() }
}

function Get-InstanceCoordinatorEvidence {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $Evidence.CoordinatorStatePath)) {
        return [pscustomobject]@{ State = "ABSENT"; Path = $Evidence.CoordinatorStatePath }
    }
    try {
        Assert-NoReparsePoint -Path $Evidence.CoordinatorStatePath -Root $Evidence.InstanceRoot -Label "instance coordinator state"
        $state = (Read-BoundedJsonDocument -Path $Evidence.CoordinatorStatePath -Label "instance coordinator state" -MaximumBytes (512 * 1024)).Document
        $runtimePath = [System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "runtime" -Label "instance coordinator state"))
        $expectedRuntime = [System.IO.Path]::GetFullPath((Join-Path $Evidence.InstanceRoot "watch\coordinator"))
        $startedText = Get-RequiredJsonString -Object $state -Name "started_at_utc" -Label "instance coordinator state"
        [DateTimeOffset]$started = [DateTimeOffset]::MinValue
        if ((Get-RequiredJsonInt32 -Object $state -Name "schema_version" -Label "instance coordinator state") -ne 2 -or
            -not [string]::Equals((Get-RequiredJsonString -Object $state -Name "generation_id" -Label "instance coordinator state"), [string]$Evidence.Generation.GenerationId, [StringComparison]::Ordinal) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath((Get-RequiredJsonString -Object $state -Name "root" -Label "instance coordinator state")), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals($runtimePath, $expectedRuntime, [StringComparison]::OrdinalIgnoreCase) -or
            (Get-RequiredJsonInt32 -Object $state -Name "coordinator_pid" -Label "instance coordinator state") -le 0 -or
            [string]::IsNullOrWhiteSpace((Get-RequiredJsonString -Object $state -Name "lifecycle_id" -Label "instance coordinator state")) -or
            -not [DateTimeOffset]::TryParse($startedText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$started)) {
            throw "invalid coordinator state identity"
        }
        $coordinatorPid = Get-RequiredJsonInt32 -Object $state -Name "coordinator_pid" -Label "instance coordinator state"
        $pids = New-Object System.Collections.Generic.List[int]
        $pids.Add($coordinatorPid)
        foreach ($field in @("provider_pid", "adapter_worker_pid", "adapter_build_pid")) {
            $property = $state.PSObject.Properties[$field]
            if ($null -ne $property -and $null -ne $property.Value) {
                $value = Get-RequiredJsonInt32 -Object $state -Name $field -Label "instance coordinator state"
                if ($value -gt 0) { $pids.Add($value) }
            }
        }
        foreach ($observedPid in @($pids | Select-Object -Unique)) {
            $identity = Get-MaterializerProcessIdentity -ProcessId $observedPid
            if (-not $identity.Alive) { continue }
            if ($observedPid -ne $coordinatorPid) {
                return [pscustomobject]@{ State = "LIVE"; Path = $Evidence.CoordinatorStatePath; ProcessId = $observedPid; Document = $state }
            }
            if ($null -eq $identity.StartUnixMilliseconds -or [int64]$identity.StartUnixMilliseconds -le $started.ToUnixTimeMilliseconds() + 2000) {
                return [pscustomobject]@{ State = "LIVE"; Path = $Evidence.CoordinatorStatePath; ProcessId = $observedPid; Document = $state }
            }
        }
        return [pscustomobject]@{ State = "STALE"; Path = $Evidence.CoordinatorStatePath; Document = $state }
    } catch {
        return [pscustomobject]@{ State = "INVALID"; Path = $Evidence.CoordinatorStatePath; Error = $_.Exception.Message }
    }
}

function Test-InstanceCoordinatorOperational {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if ($PocFixture) { return $true }
    $coordinator = Get-InstanceCoordinatorEvidence -Evidence $Evidence -ProjectRoot $ProjectRoot
    if ($coordinator.State -ne "LIVE" -or $null -eq $coordinator.Document) { return $false }
    try {
        $adapterState = Get-RequiredJsonString -Object $coordinator.Document -Name "adapter_state" -Label "instance coordinator state"
        return [string]::Equals((Get-RequiredJsonString -Object $coordinator.Document -Name "provider_state" -Label "instance coordinator state"), "ready", [StringComparison]::Ordinal) -and
            [string]::Equals((Get-RequiredJsonString -Object $coordinator.Document -Name "desired_state" -Label "instance coordinator state"), "enabled", [StringComparison]::Ordinal) -and
            [string]::Equals((Get-RequiredJsonString -Object $coordinator.Document -Name "editor_demand" -Label "instance coordinator state"), "online", [StringComparison]::Ordinal) -and
            [string]::Equals((Get-RequiredJsonString -Object $coordinator.Document -Name "adapter_worker_state" -Label "instance coordinator state"), "ready", [StringComparison]::Ordinal) -and
            @("watching", "pending", "building") -ccontains $adapterState
    } catch {
        return $false
    }
}

function Get-ValidatedInstanceRetirementControls {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $root = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceRetiredRelativePath -Label "retired instance control root"
    if (-not (Test-Path -LiteralPath $root)) { return @() }
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Retired instance control root is not a directory." }
    $controls = New-Object System.Collections.Generic.List[object]
    foreach ($item in @(Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop)) {
        Assert-NoReparsePoint -Path $item.FullName -Root $root -Label "retired instance control"
        $match = [regex]::Match($item.Name, '^([0-9a-f]{32})\.json$')
        if ($item.PSIsContainer -or -not $match.Success) { throw "Retired instance control entry is invalid: $($item.Name)" }
        $document = (Read-BoundedJsonDocument -Path $item.FullName -Label "retired instance control" -MaximumBytes (32 * 1024)).Document
        $instanceId = Get-RequiredJsonString -Object $document -Name "instance_id" -Label "retired instance control"
        $manifestSha256 = Get-RequiredJsonString -Object $document -Name "instance_manifest_sha256" -Label "retired instance control"
        $createdText = Get-RequiredJsonString -Object $document -Name "created_at_utc" -Label "retired instance control"
        [DateTimeOffset]$created = [DateTimeOffset]::MinValue
        $controlGenerationId = Get-RequiredJsonString -Object $document -Name "generation_id" -Label "retired instance control"
        if ((Get-RequiredJsonInt32 -Object $document -Name "schema_version" -Label "retired instance control") -ne 1 -or
            -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "managed_by" -Label "retired instance control"), $script:ManagedBy, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-RequiredJsonString -Object $document -Name "project_identity" -Label "retired instance control"), (Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot), [StringComparison]::Ordinal) -or
            -not [string]::Equals($instanceId, $match.Groups[1].Value, [StringComparison]::Ordinal) -or
            -not (Test-InstanceGenerationIdIsPackageSupported -Manifest $Manifest -GenerationId $controlGenerationId) -or
            $manifestSha256 -cnotmatch '^[0-9a-f]{64}$' -or
            -not [DateTimeOffset]::TryParse($createdText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$created)) {
            throw "Retired instance control identity is invalid."
        }
        $controls.Add([pscustomobject]@{
            Path = $item.FullName
            InstanceId = $instanceId
            ManifestSha256 = $manifestSha256
        })
    }
    return $controls.ToArray()
}

function Remove-ValidatedRetiredInstance {
    param(
        [Parameter(Mandatory = $true)]$Evidence,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [switch]$AllowProvisioning
    )

    try {
        $retiredControlPath = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath "$($script:InstanceRetiredRelativePath)/$($Evidence.InstanceId).json" -Label "retired instance control marker"
        $manifestSha256 = Get-FileSha256 -Path $Evidence.ManifestPath
        if (-not (Test-Path -LiteralPath $retiredControlPath)) {
            $controlMarker = [ordered]@{
                schema_version = 1
                managed_by = $script:ManagedBy
                project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
                instance_id = $Evidence.InstanceId
                generation_id = $Evidence.Generation.GenerationId
                instance_manifest_sha256 = $manifestSha256
                created_at_utc = [DateTime]::UtcNow.ToString("o")
            }
            Publish-InstanceAtomicText -Path $retiredControlPath -Content (ConvertTo-InstanceJsonText -Value $controlMarker) -StageRoot (Join-Path $Evidence.InstanceRoot "tmp")
        } else {
            $existingControl = @(Get-ValidatedInstanceRetirementControls -ProjectRoot $ProjectRoot -Manifest $Manifest | Where-Object {
                [string]::Equals($_.InstanceId, $Evidence.InstanceId, [StringComparison]::Ordinal)
            })
            if ($existingControl.Count -ne 1 -or
                -not [string]::Equals([string]$existingControl[0].ManifestSha256, $manifestSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Retired instance control does not match the validated instance manifest."
            }
        }
        $retiringPath = Join-Path $Evidence.InstanceRoot $script:InstanceRetiringFileName
        if (-not (Test-Path -LiteralPath $retiringPath)) {
            $marker = [ordered]@{
                schema_version = 1
                managed_by = $script:ManagedBy
                project_identity = Get-MaterializerProjectIdentity -ProjectRoot $ProjectRoot
                instance_id = $Evidence.InstanceId
                created_at_utc = [DateTime]::UtcNow.ToString("o")
            }
            Publish-InstanceAtomicText -Path $retiringPath -Content (ConvertTo-InstanceJsonText -Value $marker) -StageRoot (Join-Path $Evidence.InstanceRoot "tmp")
        }
        $rechecked = Get-ValidatedRetiredInstance -ProjectRoot $ProjectRoot -Manifest $Manifest -InstanceRoot $Evidence.InstanceRoot -AllowProvisioning:$AllowProvisioning
        $leases = Get-InstanceLeaseEvidence -Evidence $rechecked -ProjectRoot $ProjectRoot
        $editorLeases = Get-InstanceEditorLeaseEvidence -Evidence $rechecked -ProjectRoot $ProjectRoot
        $coordinator = Get-InstanceCoordinatorEvidence -Evidence $rechecked -ProjectRoot $ProjectRoot
        if ($leases.Invalid.Count -gt 0 -or
            $editorLeases.Invalid.Count -gt 0 -or
            $coordinator.State -eq "INVALID" -or
            $leases.Live.Count -gt 0 -or
            $editorLeases.Live.Count -gt 0 -or
            $coordinator.State -eq "LIVE") {
            return $false
        }
        foreach ($stale in @($leases.Stale + $editorLeases.Stale)) {
            Remove-Item -LiteralPath $stale.Path -Force -ErrorAction Stop
        }
        Remove-Item -LiteralPath $rechecked.InstanceRoot -Recurse -Force -ErrorAction Stop
        Add-MaterializerMutationScope -Scope "instance_cleanup"
        return $true
    } catch {
        Write-Warning "Retired instance cleanup remains pending: $($_.Exception.Message)"
        return $false
    }
}

function Get-InstanceCleanupState {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [AllowNull()]$CurrentInstance,
        [switch]$PerformCleanup
    )

    $pending = $false
    try {
        $instancesRoot = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstancesRelativePath -Label "instance root"
        if (-not (Test-Path -LiteralPath $instancesRoot)) { return "COMPLETE" }
        if (-not (Test-Path -LiteralPath $instancesRoot -PathType Container)) { return "PENDING" }
        foreach ($item in @(Get-ChildItem -LiteralPath $instancesRoot -Force -ErrorAction Stop)) {
            Assert-NoReparsePoint -Path $item.FullName -Root $instancesRoot -Label "instance root entry"
            if (-not $item.PSIsContainer) {
                $pending = $true
                continue
            }
            if ($null -ne $CurrentInstance -and [string]::Equals($item.Name, $CurrentInstance.InstanceId, [StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            try {
                $evidence = Get-ValidatedRetiredInstance -ProjectRoot $ProjectRoot -Manifest $Manifest -InstanceRoot $item.FullName
                $leases = Get-InstanceLeaseEvidence -Evidence $evidence -ProjectRoot $ProjectRoot
                $editorLeases = Get-InstanceEditorLeaseEvidence -Evidence $evidence -ProjectRoot $ProjectRoot
                $coordinator = Get-InstanceCoordinatorEvidence -Evidence $evidence -ProjectRoot $ProjectRoot
                if ($leases.Invalid.Count -gt 0 -or
                    $editorLeases.Invalid.Count -gt 0 -or
                    $coordinator.State -eq "INVALID" -or
                    $leases.Live.Count -gt 0 -or
                    $editorLeases.Live.Count -gt 0 -or
                    $coordinator.State -eq "LIVE") {
                    $pending = $true
                    continue
                }
                if ($PerformCleanup -and -not (Remove-ValidatedRetiredInstance -Evidence $evidence -ProjectRoot $ProjectRoot -Manifest $Manifest)) {
                    $pending = $true
                }
            } catch {
                $pending = $true
            }
        }
    } catch {
        $pending = $true
    }
    if ($pending) { return "PENDING" }
    return "COMPLETE"
}

function Get-InstanceUninstallCleanupState {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [switch]$PerformCleanup
    )

    $instanceState = Get-InstanceCleanupState `
        -ProjectRoot $ProjectRoot `
        -Manifest $Manifest `
        -CurrentInstance $null `
        -PerformCleanup:$PerformCleanup
    if ($instanceState -eq "PENDING") { return "PENDING" }

    try {
        $retirementControls = @(Get-ValidatedInstanceRetirementControls -ProjectRoot $ProjectRoot -Manifest $Manifest)
    } catch {
        Write-Warning "Instance retirement control remains pending: $($_.Exception.Message)"
        return "PENDING"
    }
    $legacyState = Get-UninstallCleanupState -Manifest $Manifest -ProjectRoot $ProjectRoot
    if (-not $PerformCleanup) {
        if ($legacyState -eq "PENDING" -or $retirementControls.Count -gt 0) { return "PENDING" }
        return "COMPLETE"
    }

    if ($legacyState -eq "PENDING") {
        $hasLegacyMarker = Test-Path -LiteralPath $MarkerPath -PathType Leaf
        if (-not $hasLegacyMarker -and $retirementControls.Count -eq 0) {
            Write-Warning "Host cleanup remains pending because no validated legacy marker or retired instance control authorizes the remaining files."
            return "PENDING"
        }
        $requestedExitCodeBeforeCleanup = $script:RequestedExitCode
        try {
            $targetRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb" -Label "uninstall Host root"
            $null = Invoke-Remove `
                -Manifest $Manifest `
                -ProjectRoot $ProjectRoot `
                -TargetRoot $targetRoot `
                -MarkerPath $MarkerPath `
                -ExistingLock $Lock `
                -AllowMarkerlessInstanceClosure:($retirementControls.Count -gt 0)
        } catch {
            $script:RequestedExitCode = $requestedExitCodeBeforeCleanup
            Write-Warning "Host execution closure cleanup remains pending: $($_.Exception.Message)"
            return "PENDING"
        }
        if ((Get-UninstallCleanupState -Manifest $Manifest -ProjectRoot $ProjectRoot) -eq "PENDING") {
            return "PENDING"
        }
    }

    try {
        $retirementControls = @(Get-ValidatedInstanceRetirementControls -ProjectRoot $ProjectRoot -Manifest $Manifest)
        foreach ($control in $retirementControls) {
            Remove-Item -LiteralPath $control.Path -Force -ErrorAction Stop
            Add-MaterializerMutationScope -Scope "instance_cleanup"
        }
        $retiredRoot = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceRetiredRelativePath -Label "retired instance control root"
        if ((Test-Path -LiteralPath $retiredRoot -PathType Container) -and
            @(Get-ChildItem -LiteralPath $retiredRoot -Force).Count -eq 0) {
            Remove-Item -LiteralPath $retiredRoot -Force -ErrorAction Stop
        }
    } catch {
        Write-Warning "Retired instance control cleanup remains pending: $($_.Exception.Message)"
        return "PENDING"
    }
    return "COMPLETE"
}

function Get-CombinedInstanceCleanupState {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [AllowNull()]$CurrentInstance,
        [switch]$PerformCleanup
    )

    $instanceState = Get-InstanceCleanupState `
        -ProjectRoot $ProjectRoot `
        -Manifest $Manifest `
        -CurrentInstance $CurrentInstance `
        -PerformCleanup:$PerformCleanup
    $legacyState = "COMPLETE"
    $requestedExitCodeBeforeCleanup = $script:RequestedExitCode
    try {
        $plan = Get-MaterializationPlan `
            -Manifest $Manifest `
            -MarkerPath $MarkerPath `
            -ProjectRoot $ProjectRoot
        $legacyCleanup = Invoke-AutomaticGenerationCleanup `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -Lock $Lock `
            -Plan $plan
        $legacyState = [string]$legacyCleanup.CleanupState
    } catch {
        # Retirement is best effort after a verified instance is selected. A
        # fail-closed legacy validator may set the process exit code before it
        # throws; retain the successful activation result and surface PENDING.
        $script:RequestedExitCode = $requestedExitCodeBeforeCleanup
        $legacyState = "PENDING"
        Write-Warning "Legacy execution closure cleanup remains pending: $($_.Exception.Message)"
    }
    if ($instanceState -eq "PENDING" -or $legacyState -eq "PENDING") {
        return "PENDING"
    }
    return "COMPLETE"
}

function Update-InstanceDesiredCleanupState {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][ValidateSet("INSTALLED", "UNINSTALLED")][string]$DesiredState,
        [Parameter(Mandatory = $true)][string]$StateId,
        [Parameter(Mandatory = $true)][ValidateSet("COMPLETE", "PENDING")][string]$CleanupState
    )

    $document = New-InstanceDesiredStateDocument -ProjectRoot $ProjectRoot -DesiredState $DesiredState -StateId $StateId -CleanupState $CleanupState
    $path = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath $script:InstanceDesiredStateRelativePath -Label "instance desired state"
    Publish-InstanceAtomicText -Path $path -Content (ConvertTo-InstanceJsonText -Value $document) -StageRoot $Lock.Root
}

function Get-InstanceCurrentReadiness {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)]$CurrentInstance,
        [switch]$LiveProbe
    )

    # Keep registration ownership separate from runtime availability. The
    # current instance can remain selected and correctly registered while a
    # coordinator/availability read is briefly unavailable during Play-mode
    # resume, watcher restart, or an atomic evidence refresh. Collapsing that
    # read failure into Configured=false makes the lifecycle choose Deploy and
    # causes the Manager to offer Reinstall for a still-owned instance.
    $configured = $false
    try {
        $configured = [bool](Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot).Current
        if (-not $configured) {
            return [pscustomobject]@{ Ready = $false; Installed = $true; Configured = $false; McpAvailable = $false; Reason = "Project MCP registration is missing or stale." }
        }
        $evidence = Get-ValidatedRetiredInstance -ProjectRoot $ProjectRoot -Manifest $Manifest -InstanceRoot $CurrentInstance.InstanceRoot
        if (-not (Test-InstanceCoordinatorOperational -Evidence $evidence -ProjectRoot $ProjectRoot)) {
            return [pscustomobject]@{ Ready = $false; Installed = $true; Configured = $true; McpAvailable = $false; Reason = "Selected instance coordinator is not operational." }
        }
        if ($LiveProbe) {
            $probe = Invoke-InstanceCandidateProbe -Manifest $Manifest -ProjectRoot $ProjectRoot -InstanceRelativePath $CurrentInstance.InstanceRelativePath
            $null = Write-InstanceAvailabilityEvidence -ProjectRoot $ProjectRoot -InstanceRoot $CurrentInstance.InstanceRoot -InstanceId $CurrentInstance.InstanceId -Probe $probe
        }
        $availability = Get-ValidatedInstanceAvailabilityEvidence -ProjectRoot $ProjectRoot -Instance $CurrentInstance
        if ($null -eq $availability) {
            return [pscustomobject]@{ Ready = $false; Installed = $true; Configured = $true; McpAvailable = $false; Reason = "Selected instance has no validated MCP availability evidence." }
        }
        return [pscustomobject]@{ Ready = $true; Installed = $true; Configured = $true; McpAvailable = $true; Reason = "Selected instance registration, coordinator, status, and bounded query are current." }
    } catch {
        $reason = $_.Exception.Message
        if (-not $configured) {
            # A file can be observed between the atomic replace and the next
            # read. Re-read the registration once before classifying it as
            # genuinely missing; a persistent parse/ownership failure still
            # remains fail-closed.
            try {
                $configured = [bool](Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot).Current
            } catch {
                $configured = $false
            }
        }
        if ($configured) {
            return [pscustomobject]@{
                Ready = $false
                Installed = $true
                Configured = $true
                McpAvailable = $false
                Reason = "Selected instance availability could not be verified: $reason"
            }
        }
        return [pscustomobject]@{ Ready = $false; Installed = $true; Configured = $false; McpAvailable = $false; Reason = $reason }
    }
}

function Invoke-InstanceConvergence {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][ValidateSet("Install", "Upgrade", "Reinstall")][string]$ActionName
    )

    $desiredBefore = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
    if ($ActionName -eq "Install" -and $desiredBefore.DesiredState -ne "UNINSTALLED") {
        Throw-MaterializerError -Message "Install CodeDB is available only while the project is explicitly UNINSTALLED." -ExitCode 4
    }
    if ($ActionName -ne "Install" -and $desiredBefore.DesiredState -eq "UNINSTALLED") {
        Throw-MaterializerError -Message "$ActionName cannot override the project's explicit UNINSTALLED desired state." -ExitCode 4
    }
    $null = Assert-MachinePrerequisiteForAction -Manifest $Manifest -ActionName $ActionName
    $lock = $null
    $candidate = $null
    $generationTransactionRoot = $null
    Set-MaterializerCommandPhase -Phase "PREFLIGHT"
    try {
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot -WaitForExisting -WaitTimeoutMilliseconds 120000
        $null = Assert-MachinePrerequisiteForAction -Manifest $Manifest -ActionName $ActionName
        $null = Invoke-InstanceOperationRecovery -ProjectRoot $ProjectRoot -StageRoot $lock.Root
        $desiredLocked = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
        if ($ActionName -eq "Install" -and $desiredLocked.DesiredState -ne "UNINSTALLED") {
            throw "Install desired state changed while waiting for the project operation lock."
        }
        if ($ActionName -ne "Install" -and $desiredLocked.DesiredState -eq "UNINSTALLED") {
            throw "$ActionName was cancelled because the project became UNINSTALLED while waiting for the lock."
        }

        $previous = Get-InstanceSelectedInstance -Manifest $Manifest -ProjectRoot $ProjectRoot
        if ($ActionName -eq "Upgrade" -and $null -ne $previous -and
            [string]::Equals([string]$previous.GenerationDisposition, "CURRENT", [StringComparison]::Ordinal) -and
            (Get-RequiredJsonInt32 -Object $previous.Manifest -Name "payload_sequence" -Label "current instance manifest") -eq $Manifest.PayloadSequence) {
            $currentReadiness = Get-InstanceCurrentReadiness -Manifest $Manifest -ProjectRoot $ProjectRoot -CurrentInstance $previous -LiveProbe
            if ($currentReadiness.Ready) {
                $cleanupState = Get-CombinedInstanceCleanupState `
                    -ProjectRoot $ProjectRoot `
                    -Manifest $Manifest `
                    -Lock $lock `
                    -MarkerPath $MarkerPath `
                    -CurrentInstance $previous `
                    -PerformCleanup
                $stateId = if ($desiredLocked.StateId -match '^[0-9a-f]{32}$') { $desiredLocked.StateId } else { [guid]::NewGuid().ToString("N") }
                if (-not $desiredLocked.Present -or $desiredLocked.Legacy -or $desiredLocked.CleanupState -ne $cleanupState) {
                    Update-InstanceDesiredCleanupState -ProjectRoot $ProjectRoot -Lock $lock -DesiredState "INSTALLED" -StateId $stateId -CleanupState $cleanupState
                }
                Write-Host "[PRODUCT_LAYER PREREQUISITE] CURRENT"
                Write-Host "[PRODUCT_LAYER INSTALLED] CURRENT"
                Write-Host "[PRODUCT_LAYER CONFIGURED] CURRENT"
                Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT"
                Write-Host "[PRODUCT_STATE] READY"
                Write-Host "[RESULT] READY"
                Write-Host "[CLEANUP_STATE] $cleanupState"
                Set-MaterializerCommandOutcome -Outcome "CONVERGED" -ReasonCode "INSTANCE_CURRENT" -CleanupState $cleanupState -NextAction "No action required."
                return
            }
            Write-Host "[CONVERGENCE] Current instance requires replacement: $($currentReadiness.Reason)"
        }

        if ($null -ne $previous) {
            $null = Get-ValidatedRetiredInstance -ProjectRoot $ProjectRoot -Manifest $Manifest -InstanceRoot $previous.InstanceRoot
        }
        $null = Assert-InstancePreflight `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -MarkerPath $MarkerPath `
            -PreviousInstance $previous `
            -ActionName $ActionName
        $generationTransactionRoot = Join-Path $lock.Root ("instance-generation-$([guid]::NewGuid().ToString('N'))")
        New-Item -ItemType Directory -Path $generationTransactionRoot | Out-Null
        $generationMutated = $false
        $generationRoot = Publish-ImmutableGeneration `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -TransactionRoot $generationTransactionRoot `
            -RepairPayloadRoot $null `
            -MutationOccurred ([ref]$generationMutated)

        Set-MaterializerCommandPhase -Phase "CANDIDATE"
        $candidate = New-VerifiedInstanceCandidate -Manifest $Manifest -ProjectRoot $ProjectRoot -GenerationRoot $generationRoot -PreviousInstance $previous
        $operationRoot = Join-Path $candidate.InstanceRoot ("tmp\operation-$([guid]::NewGuid().ToString('N'))")
        New-Item -ItemType Directory -Path $operationRoot | Out-Null
        $activation = Get-InstanceActivationEntries `
            -Manifest $Manifest `
            -ProjectRoot $ProjectRoot `
            -Candidate $candidate `
            -OperationRoot $operationRoot `
            -ActionName $ActionName `
            -PreviousInstance $previous `
            -UninstallStateId $(if ($ActionName -eq "Install") { $desiredLocked.StateId } else { $null })
        if ($ActionName -eq "Install") {
            Invoke-TestInstallAfterRepairHandshake
        }
        Set-MaterializerCommandPhase -Phase "ACTIVATION"
        $verification = {
            $selected = Get-ValidatedCurrentInstance -Manifest $Manifest -ProjectRoot $ProjectRoot
            if (-not [string]::Equals([string]$selected.GenerationDisposition, "CURRENT", [StringComparison]::Ordinal) -or
                -not [string]::Equals($selected.InstanceId, $candidate.InstanceId, [StringComparison]::Ordinal)) {
                throw "Activated current-instance pointer did not select the verified candidate."
            }
            $mcpVerification = Get-RepairMcpConfigPlan -ProjectRoot $ProjectRoot
            if (-not $mcpVerification.Current) { throw "Activated project MCP registration did not select the stable instance wrapper." }
            $stateVerification = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
            if ($stateVerification.DesiredState -ne "INSTALLED") { throw "Activated desired state is not INSTALLED." }
        }.GetNewClosure()
        Publish-InstanceOperation `
            -ProjectRoot $ProjectRoot `
            -ActionName $ActionName `
            -CandidateInstanceId $candidate.InstanceId `
            -Entries $activation.Entries `
            -StageRoot $lock.Root `
            -OperationRoot $operationRoot `
            -VerifyBeforeCommit $verification

        $selected = Get-ValidatedCurrentInstance -Manifest $Manifest -ProjectRoot $ProjectRoot
        $cleanupState = Get-CombinedInstanceCleanupState `
            -ProjectRoot $ProjectRoot `
            -Manifest $Manifest `
            -Lock $lock `
            -MarkerPath $MarkerPath `
            -CurrentInstance $selected `
            -PerformCleanup
        if ($cleanupState -ne "COMPLETE") {
            Update-InstanceDesiredCleanupState -ProjectRoot $ProjectRoot -Lock $lock -DesiredState "INSTALLED" -StateId $activation.StateId -CleanupState $cleanupState
        }
        $outcome = switch ($ActionName) { "Install" { "INSTALLED" }; "Reinstall" { "REINSTALLED" }; default { "UPGRADED" } }
        Write-Host "[PRODUCT_LAYER PREREQUISITE] CURRENT"
        Write-Host "[PRODUCT_LAYER INSTALLED] CURRENT"
        Write-Host "[PRODUCT_LAYER CONFIGURED] CURRENT"
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT"
        Write-Host "[PRODUCT_STATE] READY"
        Write-Host "[RESULT] $outcome"
        Write-Host "[INSTANCE] $($candidate.InstanceId)"
        Write-Host "[CLEANUP_STATE] $cleanupState"
        Write-Host "[NEXT] Start a new Codex task so it reads the selected project instance."
        Set-MaterializerCommandPhase -Phase "COMPLETE"
        Set-MaterializerCommandOutcome -Outcome $outcome -ReasonCode "INSTANCE_ACTIVATED" -CleanupState $cleanupState -NextAction "Start a new Codex task so it reads the selected project instance."
    } catch {
        $originalError = $_.Exception
        if ($null -ne $candidate) {
            $current = $null
            $currentKnown = $false
            try {
                $current = Get-ValidatedCurrentInstance -Manifest $Manifest -ProjectRoot $ProjectRoot -AllowMissing
                $currentKnown = $true
            } catch {
                Write-Warning "Candidate cleanup retained the instance because current selection could not be validated: $($_.Exception.Message)"
            }
            if ($currentKnown -and ($null -eq $current -or -not [string]::Equals($current.InstanceId, $candidate.InstanceId, [StringComparison]::Ordinal))) {
                $stopSucceeded = $PocFixture
                if (-not $PocFixture) {
                    try {
                        $manager = Join-Path $candidate.GenerationRoot "scripts\manage-codedb-project-watch.ps1"
                        $null = Invoke-InstancePowerShellScript -ScriptPath $manager -ProjectRoot $ProjectRoot -InstanceRoot $candidate.InstanceRoot -Arguments @("-Action", "Stop", "-ExpectedLifecycleId", $candidate.LifecycleId) -TimeoutMilliseconds 30000
                        $stopSucceeded = $true
                    } catch {
                        Write-Warning "Candidate-owned watcher cleanup remains pending after activation failure: $($_.Exception.Message)"
                    }
                }
                if ($stopSucceeded) {
                    try {
                        $evidence = Get-ValidatedRetiredInstance -ProjectRoot $ProjectRoot -Manifest $Manifest -InstanceRoot $candidate.InstanceRoot
                        $null = Remove-ValidatedRetiredInstance -Evidence $evidence -ProjectRoot $ProjectRoot -Manifest $Manifest
                    } catch {
                        Write-Warning "Candidate instance remains pending after activation failure: $($_.Exception.Message)"
                    }
                }
            }
        }
        if ($script:RequestedExitCode -ne 0) {
            throw $originalError
        }
        $rollbackUnproven = $originalError.Message.IndexOf(
            "rollback was not proven",
            [StringComparison]::OrdinalIgnoreCase) -ge 0
        $reasonCode = if ($rollbackUnproven) {
            "INSTANCE_ROLLBACK_UNPROVEN"
        } elseif ($script:CommandPhase -eq "CANDIDATE") {
            "INSTANCE_CANDIDATE_FAILED"
        } elseif ($script:CommandPhase -eq "ACTIVATION") {
            "INSTANCE_ACTIVATION_FAILED"
        } else {
            "INSTANCE_CONVERGENCE_FAILED"
        }
        $cleanupState = if ($null -ne $candidate -and (Test-Path -LiteralPath $candidate.InstanceRoot)) {
            "PENDING"
        } else {
            "COMPLETE"
        }
        Set-MaterializerCommandOutcome `
            -Outcome "BLOCKED" `
            -ReasonCode $reasonCode `
            -CleanupState $cleanupState `
            -NextAction "CodeDB will retry automatic convergence after the underlying failure is corrected."
        Throw-MaterializerError `
            -Message "Instance $ActionName failed without selecting an unverified candidate. $($originalError.Message)" `
            -ExitCode $(if ($rollbackUnproven) { 7 } else { 6 })
    } finally {
        if ($null -ne $generationTransactionRoot) { Remove-Item -LiteralPath $generationTransactionRoot -Recurse -Force -ErrorAction SilentlyContinue }
        Exit-MaterializerLock -Lock $lock
    }
}

function Invoke-InstanceUninstall {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [switch]$AutomaticCleanup
    )

    $lock = $null
    $automaticStateId = $null
    Set-MaterializerCommandPhase -Phase "PREFLIGHT"
    try {
        if ($AutomaticCleanup) {
            $automaticState = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
            if ($automaticState.DesiredState -ne "UNINSTALLED" -or $automaticState.CleanupState -ne "PENDING") {
                Write-Host "[SKIPPED] Automatic uninstall cleanup is not pending."
                Set-MaterializerCommandPhase -Phase "COMPLETE"
                Set-MaterializerCommandOutcome -Outcome "SKIPPED" -ReasonCode "DESIRED_STATE_CURRENT" -CleanupState $automaticState.CleanupState -NextAction "No action required."
                return
            }
            $automaticStateId = $automaticState.StateId
            Invoke-TestAutomaticCleanupStateCapturedSignal
        }
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot -WaitForExisting -WaitTimeoutMilliseconds 120000
        $null = Invoke-InstanceOperationRecovery -ProjectRoot $ProjectRoot -StageRoot $lock.Root
        $previous = Get-InstanceSelectedInstance -Manifest $Manifest -ProjectRoot $ProjectRoot
        $desiredBefore = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
        if ($AutomaticCleanup -and
            ($desiredBefore.DesiredState -ne "UNINSTALLED" -or
             $desiredBefore.CleanupState -ne "PENDING" -or
             -not [string]::Equals($desiredBefore.StateId, $automaticStateId, [StringComparison]::Ordinal))) {
            Write-Host "[SKIPPED] Automatic uninstall cleanup became obsolete while waiting for the materializer lock."
            Set-MaterializerCommandPhase -Phase "COMPLETE"
            Set-MaterializerCommandOutcome -Outcome "SKIPPED" -ReasonCode "DESIRED_STATE_CHANGED" -CleanupState "COMPLETE" -NextAction "No action required."
            return
        }
        if ($desiredBefore.DesiredState -eq "UNINSTALLED" -and $null -eq $previous) {
            Invoke-TestUninstallAfterMcpHandshake
            $cleanupState = Get-InstanceUninstallCleanupState `
                -ProjectRoot $ProjectRoot `
                -Manifest $Manifest `
                -Lock $lock `
                -MarkerPath $MarkerPath `
                -PerformCleanup
            if ($desiredBefore.CleanupState -ne $cleanupState) {
                Update-InstanceDesiredCleanupState -ProjectRoot $ProjectRoot -Lock $lock -DesiredState "UNINSTALLED" -StateId $desiredBefore.StateId -CleanupState $cleanupState
            }
            $nextAction = if ($cleanupState -eq "PENDING") {
                "No action is required; retained closures will be cleaned automatically after their owners drain."
            } else {
                "Use Install CodeDB when this project should be integrated again."
            }
            Write-Host "[RESULT] UNINSTALLED"
            Write-Host "[CLEANUP_STATE] $cleanupState"
            if ($cleanupState -eq "PENDING") {
                Write-Host "[RETAINED] Cleanup remains pending; no external MCP process was stopped."
            }
            Write-Host "[NEXT] $nextAction"
            Set-MaterializerCommandPhase -Phase "COMPLETE"
            Set-MaterializerCommandOutcome -Outcome "UNINSTALLED" -ReasonCode "LOGICAL_UNINSTALL_CURRENT" -CleanupState $cleanupState -NextAction $nextAction
            return
        }

        $operationId = [guid]::NewGuid().ToString("N")
        $operationRoot = Get-InstanceProjectPath -ProjectRoot $ProjectRoot -RelativePath "$($script:InstanceOperationsRelativePath)/operation-$operationId" -Label "uninstall operation root"
        New-Item -ItemType Directory -Force -Path $operationRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]
        $stateId = if ($desiredBefore.StateId -match '^[0-9a-f]{32}$') { $desiredBefore.StateId } else { [guid]::NewGuid().ToString("N") }
        $desired = New-InstanceDesiredStateDocument -ProjectRoot $ProjectRoot -DesiredState "UNINSTALLED" -StateId $stateId -CleanupState "PENDING"
        $desiredBytes = [System.Text.UTF8Encoding]::new($false).GetBytes((ConvertTo-InstanceJsonText -Value $desired))
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $operationRoot -Target $script:InstanceDesiredStateRelativePath -Mutation "Write" -DesiredBytes $desiredBytes
        $legacyIntegrationPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:IntegrationStateRelativePath -Label "legacy integration state"
        if (Test-Path -LiteralPath $legacyIntegrationPath) {
            Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $operationRoot -Target $script:IntegrationStateRelativePath -Mutation "Delete" -DesiredBytes $null
        }
        $mcpPlan = Get-RepairMcpConfigPlan `
            -ProjectRoot $ProjectRoot `
            -RemoveManagedKeys `
            -UninstallStateId $stateId
        if (-not $mcpPlan.Current) {
            Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $operationRoot -Target $script:McpConfigRelativePath -Mutation "Write" -DesiredBytes $mcpPlan.DesiredBytes
        }
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $operationRoot -Target $script:InstanceCurrentRelativePath -Mutation "Delete" -DesiredBytes $null
        Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $ProjectRoot -OperationRoot $operationRoot -Target $script:InstanceLastKnownGoodRelativePath -Mutation "Delete" -DesiredBytes $null
        Set-MaterializerCommandPhase -Phase "ACTIVATION"
        $currentSelectionPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:InstanceCurrentRelativePath -Label "current instance selection"
        $verification = {
            if (Test-Path -LiteralPath $currentSelectionPath) { throw "Logical Uninstall did not remove current instance selection." }
            $mcpVerification = Get-RepairMcpConfigPlan `
                -ProjectRoot $ProjectRoot `
                -RemoveManagedKeys `
                -UninstallStateId $stateId
            if (-not $mcpVerification.Current) { throw "Logical Uninstall did not disable the project MCP registration." }
            $stateVerification = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
            if ($stateVerification.DesiredState -ne "UNINSTALLED") { throw "Logical Uninstall did not publish UNINSTALLED desired state." }
        }.GetNewClosure()
        Publish-InstanceOperation -ProjectRoot $ProjectRoot -ActionName "Uninstall" -CandidateInstanceId $operationId -Entries $entries.ToArray() -StageRoot $lock.Root -OperationRoot $operationRoot -VerifyBeforeCommit $verification -OperationId $operationId
        Invoke-TestUninstallAfterMcpHandshake
        $cleanupState = Get-InstanceUninstallCleanupState `
            -ProjectRoot $ProjectRoot `
            -Manifest $Manifest `
            -Lock $lock `
            -MarkerPath $MarkerPath `
            -PerformCleanup
        Update-InstanceDesiredCleanupState -ProjectRoot $ProjectRoot -Lock $lock -DesiredState "UNINSTALLED" -StateId $stateId -CleanupState $cleanupState
        $nextAction = if ($cleanupState -eq "PENDING") {
            "No action is required; retained closures will be cleaned automatically after their owners drain."
        } else {
            "Use Install CodeDB when this project should be integrated again."
        }
        Write-Host "[RESULT] UNINSTALLED"
        Write-Host "[CLEANUP_STATE] $cleanupState"
        if ($cleanupState -eq "PENDING") {
            Write-Host "[RETAINED] Cleanup remains pending; no external MCP process was stopped."
        }
        Write-Host "[NEXT] $nextAction"
        Set-MaterializerCommandPhase -Phase "COMPLETE"
        Set-MaterializerCommandOutcome -Outcome "UNINSTALLED" -ReasonCode "LOGICAL_UNINSTALL_COMPLETE" -CleanupState $cleanupState -NextAction $nextAction
    } finally {
        Exit-MaterializerLock -Lock $lock
    }
}

function Write-InstanceProductStatus {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$LiveProbe,
        [switch]$RequireReady
    )

    $desired = Get-InstanceDesiredState -ProjectRoot $ProjectRoot
    $prerequisite = $script:MachinePrerequisiteStatus
    if ($null -eq $prerequisite) {
        $prerequisite = Get-MaterializerMachinePrerequisiteStatus -Manifest $Manifest
    }
    if (-not $prerequisite.Current) {
        Write-Host "[PRODUCT_LAYER PREREQUISITE] MISSING"
        Write-Host "[PRODUCT_STATE] MISSING_PREREQUISITE"
        Write-Host "[PREREQUISITE] $($prerequisite.Detail)"
        Write-Host "[CLEANUP_STATE] $($desired.CleanupState)"
        return $true
    }
    Write-Host "[PRODUCT_LAYER PREREQUISITE] CURRENT"
    if ($desired.DesiredState -eq "UNINSTALLED") {
        Write-Host "[PRODUCT_LAYER INSTALLED] MISSING"
        Write-Host "[PRODUCT_LAYER CONFIGURED] MISSING"
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE"
        Write-Host "[PRODUCT_STATE] UNINSTALLED"
        Write-Host "[CLEANUP_STATE] $($desired.CleanupState)"
        return $true
    }
    $current = $null
    try { $current = Get-ValidatedCurrentInstance -Manifest $Manifest -ProjectRoot $ProjectRoot -AllowMissing }
    catch {
        $detail = $_.Exception.Message
        Write-Host "[PRODUCT_LAYER INSTALLED] BLOCKED"
        Write-Host "[PRODUCT_LAYER CONFIGURED] BLOCKED"
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE"
        Write-Host "[PRODUCT_STATE] NEEDS_ATTENTION"
        Write-Host "[INSTANCE] INVALID - $detail"
        if ($RequireReady) {
            Throw-MaterializerError -Message "Current instance availability probe is blocked: $detail" -ExitCode 5
        }
        return $true
    }
    if ($null -eq $current) {
        Write-Host "[PRODUCT_LAYER INSTALLED] MISSING"
        Write-Host "[PRODUCT_LAYER CONFIGURED] MISSING"
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE"
        Write-Host "[PRODUCT_STATE] NEEDS_ATTENTION"
        Write-Host "[INSTANCE] NONE"
        if ($RequireReady) {
            Throw-MaterializerError -Message "Current instance availability probe requires a selected Package-owned instance." -ExitCode 5
        }
        return $true
    }
    if (-not [string]::Equals([string]$current.GenerationDisposition, "CURRENT", [StringComparison]::Ordinal)) {
        Write-Host "[PRODUCT_LAYER INSTALLED] MISSING"
        Write-Host "[PRODUCT_LAYER CONFIGURED] PENDING"
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE"
        Write-Host "[PRODUCT_STATE] NEEDS_ATTENTION"
        Write-Host "[INSTANCE] TRUSTED_PREVIOUS - $($current.InstanceId) generation $($current.Generation.GenerationId) is ready for automatic handoff."
        Write-Host "[CLEANUP_STATE] PENDING"
        if ($RequireReady) {
            Throw-MaterializerError -Message "Current instance availability probe requires handoff from the trusted previous generation." -ExitCode 5
        }
        return $true
    }
    $readiness = Get-InstanceCurrentReadiness `
        -Manifest $Manifest `
        -ProjectRoot $ProjectRoot `
        -CurrentInstance $current `
        -LiveProbe:$LiveProbe
    if ($readiness.Configured) {
        Write-Host "[PRODUCT_LAYER INSTALLED] CURRENT"
        Write-Host "[PRODUCT_LAYER CONFIGURED] CURRENT"
    } else {
        Write-Host "[PRODUCT_LAYER INSTALLED] CURRENT"
        Write-Host "[PRODUCT_LAYER CONFIGURED] MISSING"
    }
    if ($readiness.McpAvailable) {
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] CURRENT"
    } else {
        Write-Host "[PRODUCT_LAYER MCP_AVAILABLE] UNAVAILABLE"
    }
    if ($readiness.Ready) {
        Write-Host "[PRODUCT_STATE] READY"
    } else {
        Write-Host "[PRODUCT_STATE] NEEDS_ATTENTION"
        Write-Host "[DETAIL] $($readiness.Reason)"
    }
    Write-Host "[INSTANCE] $($current.InstanceId)"
    $cleanupState = Get-InstanceCleanupState -ProjectRoot $ProjectRoot -Manifest $Manifest -CurrentInstance $current
    if ($desired.CleanupState -eq "PENDING") {
        $cleanupState = "PENDING"
    }
    Write-Host "[CLEANUP_STATE] $cleanupState"
    if ($RequireReady -and -not $readiness.Ready) {
        Throw-MaterializerError -Message "Current instance availability probe did not reach Ready: $($readiness.Reason)" -ExitCode 5
    }
    return $true
}
