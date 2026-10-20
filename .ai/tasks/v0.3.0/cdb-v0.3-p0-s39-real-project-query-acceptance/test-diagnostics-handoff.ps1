#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$PreparationRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$preparation=[IO.Path]::GetFullPath((Join-Path $repo $PreparationRoot))
$authorizedParent=Join-Path $repo '.artifacts/tests/s39-diagnostics-delivery'
if (-not $preparation.StartsWith($authorizedParent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Preparation root escaped owner.' }
for ($current=$preparation; $current.Length -gt $repo.Length; $current=Split-Path $current -Parent) {
    if ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected preparation refused.' }
}
if (-not(Test-Path -LiteralPath (Join-Path $preparation 'owner.json') -PathType Leaf)) { throw 'Preparation ownership missing.' }
$candidate=Join-Path $preparation 'candidate/com.rice.ai-codedb'
$predecessor=Join-Path $repo '.artifacts/exports/s39-c07bb59/review/com.rice.ai-codedb'
$container=Join-Path $preparation ('handoff-'+[guid]::NewGuid().ToString('N').Substring(0,8))
if (Test-Path -LiteralPath $container) { throw 'Preserve prior handoff evidence.' }
[void][IO.Directory]::CreateDirectory($container)
$io=Join-Path $container 'io-probe'; [IO.File]::WriteAllText($io,'owned')
if ([IO.File]::ReadAllText($io) -cne 'owned') { throw 'Fixture read failed.' }; [IO.File]::Delete($io)
$parts=[Collections.Generic.List[string]]::new()
$parts.Add('param($container,$candidate,$predecessor)')
# Exact function bodies and declared constants, never an entry script main.
foreach ($relative in @('Payload~/AIWork/codedb/shared/codedb-strict-json.ps1',
    'Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1',
    'Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1',
    'Tools~/materialize-codedb-host-payload.ps1','Tools~/codedb-instance-engine.ps1')) {
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $candidate $relative),[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw ('Production source parse failed: '+$relative) }
    $beforeFunctions=$true
    foreach ($statement in $ast.EndBlock.Statements) {
        if ($statement -is [Management.Automation.Language.FunctionDefinitionAst]) {
            $beforeFunctions=$false; $parts.Add($statement.Extent.Text)
        } elseif ($beforeFunctions -and (($statement -is [Management.Automation.Language.AssignmentStatementAst] -and
            $statement.Left.Extent.Text.StartsWith('$script:')) -or $statement -is [Management.Automation.Language.ForEachStatementAst])) {
            $parts.Add($statement.Extent.Text)
        }
    }
}
$module=New-Module -ScriptBlock ([scriptblock]::Create($parts -join "`n")) -ArgumentList $container,$candidate,$predecessor
& $module {
    $ErrorActionPreference='Stop'
    function Get-MaterializerMachinePrerequisiteStatus {
        param($Manifest)
        return [pscustomobject]@{Current=$true;State='CURRENT';ReasonCode='FIXTURE_CURRENT';Detail='Synthetic prerequisite';NextAction='';NodePath='';NodeVersion='fixture';ProviderVersion='fixture';ProviderRoot='';ProviderManifestPath='';ProviderExecutablePath=''}
    }
    function Get-MaterializerProcessIdentity { param($ProcessId); throw 'External process observation forbidden.' }
    function Invoke-BoundedNativeProcessWithFileOutput { throw 'Real Provider execution forbidden.' }
    $script:PocFixture=$true; $script:Action='Install'
    $root=Join-Path $container 'project'
    foreach ($marker in @('Assets','Packages','ProjectSettings')) { [void][IO.Directory]::CreateDirectory((Join-Path $root $marker)) }
    $oldManifest=Read-PayloadManifest -Root (Join-Path $predecessor 'Payload~') -ProjectRoot $root
    Invoke-InstanceConvergence -Manifest $oldManifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath) -ActionName Install
    $selected=Get-ValidatedCurrentInstance -Manifest $oldManifest -ProjectRoot $root
    $oldContract=Get-InstanceActivationContractState -Manifest $oldManifest -ProjectRoot $root
    if ($oldContract.Operation.Phase -cne 'COMMITTED') { throw 'Synthetic baseline activation did not commit.' }
    $selectionHash=Get-FileSha256 $selected.SelectionPath
    $activationHash=Get-FileSha256 $oldContract.Activation.Path
    $operationHash=Get-FileSha256 $oldContract.Operation.Path
    $newManifest=Read-PayloadManifest -Root (Join-Path $candidate 'Payload~') -ProjectRoot $root
    $oldWrapperError=''
    try { $null=Get-ValidatedCurrentInstance -Manifest $newManifest -ProjectRoot $root }
    catch { $oldWrapperError=$_.Exception.Message }
    if (-not $oldWrapperError.Contains('stable wrapper')) { throw 'Expected current Package reader to refuse old wrapper bytes.' }
    $wrapperTarget='AIWork/codedb/wrapper/codedb-project-wrapper.mjs'
    [IO.File]::WriteAllBytes((Join-Path $root $wrapperTarget),[IO.File]::ReadAllBytes((Join-Path $candidate ('Payload~/'+$wrapperTarget))))
    $newSelected=Get-ValidatedCurrentInstance -Manifest $newManifest -ProjectRoot $root
    $activationError=''
    try { $null=Get-InstanceActivationContractState -Manifest $newManifest -ProjectRoot $root }
    catch { $activationError=$_.Exception.Message }
    foreach ($proof in @(@($selected.SelectionPath,$selectionHash),@($oldContract.Activation.Path,$activationHash),@($oldContract.Operation.Path,$operationHash))) {
        if ((Get-FileSha256 $proof[0]) -cne $proof[1]) { throw 'Fixture handoff rewrote protected activation/selection.' }
    }
    # A separate fresh project exercises the existing formal publication path;
    # it does not rewrite the previous fixture's activation authority.
    $freshRoot=Join-Path $container 'fresh-candidate-project'
    foreach ($marker in @('Assets','Packages','ProjectSettings')) { [void][IO.Directory]::CreateDirectory((Join-Path $freshRoot $marker)) }
    $freshManifest=Read-PayloadManifest -Root (Join-Path $candidate 'Payload~') -ProjectRoot $freshRoot
    $script:RequestedExitCode=0; $script:CommandOutcome=''; $script:CommandReasonCode=''
    $script:CommandCleanupState=''; $script:CommandNextAction=''; $script:CommandMutatedScopes.Clear()
    Invoke-InstanceConvergence -Manifest $freshManifest -ProjectRoot $freshRoot -MarkerPath (Join-Path $freshRoot $script:MarkerRelativePath) -ActionName Install
    $freshSelected=Get-ValidatedCurrentInstance -Manifest $freshManifest -ProjectRoot $freshRoot
    $freshContract=Get-InstanceActivationContractState -Manifest $freshManifest -ProjectRoot $freshRoot
    if ($freshContract.Operation.Phase -cne 'COMMITTED') { throw 'Candidate fresh activation did not commit.' }
    $result=[ordered]@{
        status=$(if ($activationError) {'SAME_GENERATION_HANDOFF_NOT_ADMITTED'} else {'READERS_ADMIT_SAME_GENERATION_HANDOFF'})
        synthetic_baseline_committed=$true
        old_wrapper_refusal=$oldWrapperError
        candidate_selection_read=$true
        same_instance=($newSelected.InstanceId -ceq $selected.InstanceId)
        same_epoch=($newSelected.ActivationEpoch -ceq $selected.ActivationEpoch)
        activation_reader_error=$activationError
        old_runtime_contract_sha256=$oldManifest.RuntimeContractSha256
        new_runtime_contract_sha256=$newManifest.RuntimeContractSha256
        protected_records_unchanged=$true
        fresh_candidate_install_committed=$true
        fresh_candidate_readers_admit=$true
        fresh_candidate_instance_id=$freshSelected.InstanceId
        limitations='Synthetic installed fixture only; no consumer write, Provider, Supervisor or MCP host execution.'
    }
    [IO.File]::WriteAllText((Join-Path $container 'result.json'),(ConvertTo-InstanceJsonText $result),[Text.UTF8Encoding]::new($false))
    Write-Output ('[HANDOFF_EVIDENCE] '+$result.status)
    if ($activationError) { Write-Output ('[REFUSAL] '+$activationError) }
    Write-Output '[FRESH_CANDIDATE] PASS synthetic Install committed and selected/activation readers agree.'
    Write-Output ('[EVIDENCE] '+$container.Substring($repo.Length+1).Replace('\','/'))
}
