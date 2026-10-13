#requires -Version 5.1
[CmdletBinding()]
param([switch]$DeclaredAdapterOutputs, [switch]$OriginalProjectRoots)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repositoryRoot = Split-Path $packageRoot -Parent
if ($DeclaredAdapterOutputs -and $OriginalProjectRoots) { throw 'Select one focused proof mode.' }
$family = if ($OriginalProjectRoots) { 's29-original-root' } elseif ($DeclaredAdapterOutputs) { 's29-adapter' } else { 's29-entry' }
$fixtureContainer = Join-Path $repositoryRoot ('.artifacts/tests/' + $family + '/r-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$projectRoot = Join-Path $fixtureContainer 'p'
$materializer = Join-Path $packageRoot 'Tools~/materialize-codedb-host-payload.ps1'
$powershell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$utf8 = [Text.UTF8Encoding]::new($false)
$script:assertions = 0
$priorLocal = [Environment]::GetEnvironmentVariable('LOCALAPPDATA','Process')

function Import-EntryDefinitions {
    param([string]$Path, [string[]]$Names = @())
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if(@($errors).Count){throw "Fixture definition parse failed: $Path"}
    if($Names.Count) {
        foreach($name in $Names) {
            $matches=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq $name},$true))
            if($matches.Count -ne 1){throw "Fixture helper is not unique: $name"}
            $body=$matches[0].Body.Extent.Text
            Set-Item -Path ('Function:global:'+$name) -Value ([scriptblock]::Create($body.Substring(1,$body.Length-2)))
        }
        return
    }
    $beforeFunctions=$true
    foreach($statement in $ast.EndBlock.Statements) {
        if($statement -is [Management.Automation.Language.FunctionDefinitionAst]) {
            $beforeFunctions=$false
            $body=$statement.Body.Extent.Text
            Set-Item -Path ('Function:global:'+$statement.Name) -Value ([scriptblock]::Create($body.Substring(1,$body.Length-2)))
        } elseif($beforeFunctions -and
            (($statement -is [Management.Automation.Language.AssignmentStatementAst] -and $statement.Left.Extent.Text.StartsWith('$script:',[StringComparison]::Ordinal)) -or
             $statement -is [Management.Automation.Language.ForEachStatementAst])) {
            . ([scriptblock]::Create($statement.Extent.Text))
        }
    }
}
function Assert-Entry {
    param([bool]$Condition,[string]$Label)
    if(-not $Condition){throw "Entry assertion failed: $Label"}
    $script:assertions++
    Write-Host "[OK] $Label"
}
function Get-EntryDigest {
    param([string]$Root)
    Get-TextSha256 -Text ((@(Get-ChildItem -LiteralPath $Root -Recurse -Force | Sort-Object FullName | ForEach-Object {
        if ($_.PSIsContainer) { 'D:'+ $_.FullName.Substring($Root.Length) }
        else { 'F:'+ $_.FullName.Substring($Root.Length)+':'+(Get-FileSha256 -Path $_.FullName) }
    })) -join "`n")
}
function Invoke-EntryCli {
    param([string]$Label,[string]$ActionName,[string]$ActionId,[switch]$Confirmed,[string]$ProcessMode='clear')
    # Execute the original on-disk script. Only Win32_Process enumeration is
    # synthetic; dispatch, action/record/hash decoders and PID checks are real.
    $args=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$runner,
        '-Script',$materializer,'-Root',$projectRoot,'-Action',$ActionName,
        '-ProcessMode',$ProcessMode)
    if($ActionId){$args+=@('-ActionId',$ActionId)}
    if($Confirmed){$args+='-Confirmed'}
    $info=[Diagnostics.ProcessStartInfo]::new()
    $info.FileName=$powershell
    # Values are owned paths/hex/enums; quote each argument, never shell code.
    $info.Arguments=($args | ForEach-Object {'"'+$_.Replace('"','\"')+'"'}) -join ' '
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$info
    if(-not $process.Start()){throw 'Fixture child did not start.'}
    $outTask=$process.StandardOutput.ReadToEndAsync(); $errTask=$process.StandardError.ReadToEndAsync()
    if(-not $process.WaitForExit(120000)) {
        Write-Warning 'Fixture child exceeded 120 seconds.'
        if(-not $process.WaitForExit(180000)){throw 'Fixture child exceeded 300 seconds; no process was terminated.'}
    }
    $stdout=$outTask.Result; $stderr=$errTask.Result; $exit=$process.ExitCode
    $process.Dispose()
    [IO.File]::WriteAllText((Join-Path $fixtureContainer ($Label+'.stdout.txt')),$stdout,$utf8)
    [IO.File]::WriteAllText((Join-Path $fixtureContainer ($Label+'.stderr.txt')),$stderr,$utf8)
    Write-Host "[CLI] $Label exit=$exit"
    return [pscustomobject]@{ExitCode=$exit;Text=$stdout+"`n"+$stderr}
}
function Assert-EntryReadOnly {
    param([string]$Label,[string]$ActionName='UninstallPreflight',[string]$ActionId,[string]$Expected,[int]$ExitCode=4,[string]$ProcessMode='clear')
    $beforeProject=Get-EntryDigest $projectRoot; $beforeReceipts=Get-EntryDigest $fixture.LocalData
    $result=Invoke-EntryCli -Label $Label -ActionName $ActionName -ActionId $ActionId -ProcessMode $ProcessMode
    Assert-Entry ($result.ExitCode -eq $ExitCode -and $result.Text.Contains($Expected)) ($Label+'-dedicated-result')
    Assert-Entry ((Get-EntryDigest $projectRoot) -ceq $beforeProject -and (Get-EntryDigest $fixture.LocalData) -ceq $beforeReceipts) ($Label+'-project-and-receipts-byte-identical')
}

try {
    foreach($name in @('Assets','Packages','ProjectSettings')) {New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot $name)|Out-Null}
    [IO.File]::WriteAllText((Join-Path $projectRoot 'Packages/manifest.json'),'{"dependencies":{}}',$utf8)
    [IO.File]::WriteAllText((Join-Path $projectRoot 'ProjectSettings/ProjectVersion.txt'),'m_EditorVersion: 2022.3.0f1',$utf8)
    foreach($path in @('Payload~/AIWork/codedb/shared/codedb-strict-json.ps1','Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1','Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1','Tools~/materialize-codedb-host-payload.ps1','Tools~/codedb-instance-engine.ps1')) {
        Import-EntryDefinitions (Join-Path $packageRoot $path)
    }
    Import-EntryDefinitions (Join-Path $PSScriptRoot 'test-codedb-host-payload-materializer.ps1') @('Write-PhaseCRecord','Invoke-RetainedCandidateRecoveryCase')
    $manifest=Read-PayloadManifest -Root (Join-Path $packageRoot 'Payload~') -ProjectRoot $projectRoot
    $fixtureParameters=@{ProjectRoot=$projectRoot;PackageRoot=$packageRoot;Manifest=$manifest;BuildFixtureOnly=$true}
    if ($OriginalProjectRoots) { $fixtureParameters.RecordedProjectRoot=$projectRoot.Replace('\','/') }
    $fixture=Invoke-RetainedCandidateRecoveryCase @fixtureParameters
    if ($DeclaredAdapterOutputs) {
        $instanceRoot=Join-Path $projectRoot ($script:InstancesRelativePath+'/'+$fixture.InstanceId)
        $adapterContract=Get-CodedbTextAdapterOutputContract
        # Execute each actual producer common script and context binding in its
        # own scope. No path decoder or initializer is replaced by the fixture.
        $flatCommon=Join-Path $packageRoot 'Payload~/AIWork/codedb/scripts/codedb-project-common.ps1'
        $generationCommon=Join-Path $packageRoot ('Payload~/Generations/'+$manifest.GenerationId+'/scripts/codedb-project-common.ps1')
        & {
            param($Common,$Root,$Candidate)
            . $Common
            $context=Get-ProjectCodedbContext -UnityRoot $Root
            $contract=Get-CodedbTextAdapterOutputContract
            # Flat producer uses its legacy provider location. Only bind the
            # candidate context here, then call the real initialization function.
            $context.ProviderRoot=$Candidate
            $context.TextAdapterRoot=Join-Path $Candidate $contract.RootRelativePath
            $context.TextAdapterLogsRoot=Join-Path $Candidate $contract.LogsRelativePath
            $context.TextAdapterTempRoot=Join-Path $Candidate $contract.TempRelativePath
            New-ProjectCodedbTextAdapterRuntime -Context $context
        } $flatCommon $projectRoot $instanceRoot
        $priorInstance=[Environment]::GetEnvironmentVariable('RICE_CODEDB_INSTANCE_ROOT','Process')
        try {
            [Environment]::SetEnvironmentVariable('RICE_CODEDB_INSTANCE_ROOT',$instanceRoot,'Process')
            & {
                param($Common,$Root)
                . $Common
                $context=Get-ProjectCodedbContext -UnityRoot $Root
                New-ProjectCodedbTextAdapterRuntime -Context $context
            } $generationCommon $projectRoot
        } finally { [Environment]::SetEnvironmentVariable('RICE_CODEDB_INSTANCE_ROOT',$priorInstance,'Process') }
        Assert-Entry ((Test-Path (Join-Path $instanceRoot $adapterContract.LogsRelativePath) -PathType Container) -and (Test-Path (Join-Path $instanceRoot $adapterContract.TempRelativePath) -PathType Container)) 'actual-flat-and-generation-initializers-create-declared-trees'
    }
    # Build authentic retained intent/desired-state fixtures with existing
    # producers. No backend recovery call is used to set up this test.
    $authority=Get-CurrentProjectRemovalAuthority -Manifest $manifest -ProjectRoot $projectRoot
    $stateId=[guid]::NewGuid().ToString('N')
    $intentPath=Join-Path $projectRoot ($script:InstanceRemovalIntentsRelativePath+'/'+$stateId+'.json')
    Write-PhaseCRecord $intentPath (New-FailedPreparationRemovalIntentDocument -ProjectRoot $projectRoot -StateId $stateId -Authority $authority)
    Write-PhaseCRecord (Join-Path $projectRoot $script:InstanceDesiredStateRelativePath) (New-InstanceDesiredStateDocument -ProjectRoot $projectRoot -DesiredState UNINSTALLED -StateId $stateId -CleanupState PENDING)
    $null=Get-InstanceRemovalIntent -Manifest $manifest -ProjectRoot $projectRoot -StateId $stateId
    Assert-Entry ($null -eq (Get-CurrentProjectRemovalAuthority -Manifest $manifest -ProjectRoot $projectRoot -AllowNoNewCandidate)) 'fixture-requires-retained-intent-lookup'
    $runner=Join-Path $fixtureContainer 'cli.ps1'
    $runnerText=@'
#requires -Version 5.1
param([string]$Script,[string]$Root,[string]$Action,[string]$ActionId,[switch]$Confirmed,[string]$ProcessMode)
$ErrorActionPreference='Stop'
function global:Get-CimInstance {
    param($ClassName,$ErrorAction)
    if($ClassName -cne 'Win32_Process'){throw 'Unexpected fixture native service.'}
    Write-Host ('[FIXTURE_PROCESS_INVENTORY] '+$ProcessMode)
    if($ProcessMode -ceq 'ambiguous') {
        return [pscustomobject]@{ProcessId=424244;Name='powershell.exe';CommandLine=''}
    }
    return [pscustomobject]@{ProcessId=424244;Name='powershell.exe';CommandLine='unrelated synthetic process'}
}
$parameters=@{Action=$Action;ProjectRoot=$Root}
if($ActionId){$parameters.RetainedCandidateActionId=$ActionId}
if($Confirmed){$parameters.ConfirmedProjectMutation=$true}
& $Script @parameters
exit $LASTEXITCODE
'@
    [IO.File]::WriteAllText($runner,$runnerText,$utf8)
    $runnerTokens=$null; $runnerErrors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($runner,[ref]$runnerTokens,[ref]$runnerErrors)
    Assert-Entry (@($runnerErrors).Count -eq 0) 'materialized-cli-runner-PS51-parse'

    Assert-EntryReadOnly -Label matching -ActionId $fixture.ActionId -Expected '[REMOVAL_PREFLIGHT] AVAILABLE' -ExitCode 0
    $extraCli=0
    if ($OriginalProjectRoots) {
        $recorded=(Read-BoundedJsonDocument -Path $fixture.AdmissionPath -Label 'mixed-root admission' -MaximumBytes 131072).Document
        Assert-Entry ($recorded.project_root -ceq $projectRoot.Replace('\','/') -and $recorded.project_root -cne $projectRoot -and $recorded.command.arguments[3] -ceq $recorded.project_root) 'independently-recorded-forward-slash-root-native-caller'
        foreach ($equivalent in @($projectRoot.Replace('\','/'), ($projectRoot.ToUpperInvariant()+'\'))) {
            Assert-Entry (Test-RetainedAbsoluteProjectRootIdentity $equivalent $projectRoot) 'absolute-root-slash-case-trailing-equivalence'
        }
        $invalidQuestionRoot = Join-Path $fixtureContainer 'bad?root'
        $invalidNulRoot = (Join-Path $fixtureContainer 'bad') + [char]0 + 'root'
        foreach ($invalid in @('relative/project', ($projectRoot.Substring(0,2)+'relative'), '\relative', '/relative', $invalidQuestionRoot, $invalidNulRoot, '\\server', (Join-Path $fixtureContainer 'other'))) {
            Assert-Entry (-not (Test-RetainedAbsoluteProjectRootIdentity $invalid $projectRoot) -and -not (Test-RetainedAbsoluteProjectRootIdentity $projectRoot $invalid)) 'incomplete-malformed-or-different-root-rejected-both-operands'
        }
        $originalAdmission=[IO.File]::ReadAllBytes($fixture.AdmissionPath)
        foreach ($scenario in @('variant','different','incomplete','hash-tamper','operation','incomplete-admission')) {
            try {
                $doc=(Read-BoundedJsonDocument -Path $fixture.AdmissionPath -Label 'root scenario admission' -MaximumBytes 131072).Document
                $expected='Failed candidate original INSTALL linkage conflicts: -ProjectRoot.'; $exitCode=4
                switch ($scenario) {
                    variant { $doc.project_root=$projectRoot.Replace('\','/').ToUpperInvariant()+'/'; $expected='[REMOVAL_PREFLIGHT] AVAILABLE'; $exitCode=0 }
                    different { $doc.command.arguments[3]=Join-Path $fixtureContainer 'other' }
                    incomplete { $doc.command.arguments[3]=$projectRoot.Substring(0,2)+'relative' }
                    'hash-tamper' { $doc.command.arguments[3]=$projectRoot; $expected='Failed candidate command/terminal identity conflicts.' }
                    operation { $doc.command.arguments[8]='0'*32; $expected='Failed candidate original INSTALL linkage conflicts: -OriginatingOperationId.' }
                    'incomplete-admission' { $doc.project_root='\relative'; $expected='Failed candidate admission context conflicts.' }
                }
                # Tampered cases deliberately retain the original raw hashes.
                # The variant changes only non-hashed admission context spelling.
                Write-PhaseCRecord $fixture.AdmissionPath $doc
                Assert-EntryReadOnly -Label ('root-'+$scenario) -ActionId $fixture.ActionId -Expected $expected -ExitCode $exitCode
                $extraCli++
            } finally { [IO.File]::WriteAllBytes($fixture.AdmissionPath,$originalAdmission) }
        }
    }
    if ($DeclaredAdapterOutputs) {
        # Snapshot drift must refuse using the existing intent reader. Remove
        # only fixture-owned new bytes before establishing the next snapshot.
        $addedPaths=@()
        foreach($tree in $adapterContract.RetainedOutputTrees) {
            $nested=Join-Path $instanceRoot ($tree+'/nested')
            New-Item -ItemType Directory -Path $nested | Out-Null
            $added=Join-Path $nested 'opaque.dat'
            [IO.File]::WriteAllText($added,'ordinary retained output '+$tree,$utf8)
            $addedPaths += $added
        }
        Assert-EntryReadOnly -Label snapshot-drift -ActionId $fixture.ActionId -Expected 'retained effect snapshot changed'
        $extraCli++
        $authority.Effects=@(Get-FailedPreparationEffects -ProjectRoot $projectRoot -InstanceId $fixture.InstanceId -GenerationId $manifest.GenerationId -Manifest $manifest -Generation $authority.Evidence.Generation)
        Write-PhaseCRecord $intentPath (New-FailedPreparationRemovalIntentDocument -ProjectRoot $projectRoot -StateId $stateId -Authority $authority)
        Assert-EntryReadOnly -Label nonempty -ActionId $fixture.ActionId -Expected '[REMOVAL_PREFLIGHT] AVAILABLE' -ExitCode 0
        $extraCli++
        foreach($added in $addedPaths) {
            $intent=(Read-BoundedJsonDocument -Path $intentPath -Label 'fixture retained outputs' -MaximumBytes 131072).Document
            $rel=$added.Substring($projectRoot.Length+1).Replace('\','/')
            $entry=@($intent.retained_effects | Where-Object {$_.relative_path -ceq $rel})
            Assert-Entry ($entry.Count -eq 1 -and $entry[0].kind -ceq 'FILE' -and $entry[0].sha256 -ceq (Get-FileSha256 $added)) 'nonempty-output-hash-in-existing-v2-intent'
        }
        $logsRoot=Join-Path $instanceRoot $adapterContract.LogsRelativePath
        $savedLogs=Join-Path $fixtureContainer 'saved-logs'
        Move-Item -LiteralPath $logsRoot -Destination $savedLogs
        try {
            [IO.File]::WriteAllText($logsRoot,'declared tree root must be a directory',$utf8)
            Assert-EntryReadOnly -Label file-at-tree-root -ActionId $fixture.ActionId -Expected ('unexpected mutable bytes outside declared output trees: '+$adapterContract.LogsRelativePath)
            $extraCli++
        } finally { [IO.File]::Delete($logsRoot); Move-Item -LiteralPath $savedLogs -Destination $logsRoot }
        $outside=Join-Path $instanceRoot ($adapterContract.RootRelativePath+'/foreign')
        New-Item -ItemType Directory -Path $outside | Out-Null
        try { Assert-EntryReadOnly -Label outside -ActionId $fixture.ActionId -Expected ($adapterContract.RootRelativePath+'/foreign'); $extraCli++ }
        finally { [IO.Directory]::Delete($outside) }
        # A redirected declared subtree remains refused before enumeration.
        $redirectTarget=Join-Path $fixtureContainer 'redirect-target'
        New-Item -ItemType Directory -Path $redirectTarget | Out-Null
        $redirect=Join-Path $instanceRoot ($adapterContract.TempRelativePath+'/redirect')
        New-Item -ItemType Junction -Path $redirect -Target $redirectTarget | Out-Null
        try {
            # Digest intentionally does not traverse redirect; it includes the
            # junction and fixture target separately using fixed known paths.
            $beforeIntent=Get-FileSha256 $intentPath; $beforeReceipts=Get-EntryDigest $fixture.LocalData
            $redirectResult=Invoke-EntryCli -Label redirected -ActionName UninstallPreflight -ActionId $fixture.ActionId
            Assert-Entry ($redirectResult.ExitCode -eq 4 -and $redirectResult.Text.Contains('redirect') -and $redirectResult.Text.Contains('reparse')) 'redirected-declared-output-refused-with-path'
            Assert-Entry ((Get-FileSha256 $intentPath) -ceq $beforeIntent -and (Get-EntryDigest $fixture.LocalData) -ceq $beforeReceipts -and @(Get-ChildItem $redirectTarget -Force).Count -eq 0) 'redirect-refusal-preserves-intent-receipts-target'
            $extraCli++
        } finally { [IO.Directory]::Delete($redirect) }
        foreach($name in @('manifest.json','files.jsonl','index.jsonl')) { [IO.File]::Delete((Join-Path $instanceRoot ($adapterContract.RootRelativePath+'/'+$name))) }
        $authority.Effects=@(Get-FailedPreparationEffects -ProjectRoot $projectRoot -InstanceId $fixture.InstanceId -GenerationId $manifest.GenerationId -Manifest $manifest -Generation $authority.Evidence.Generation)
        Write-PhaseCRecord $intentPath (New-FailedPreparationRemovalIntentDocument -ProjectRoot $projectRoot -StateId $stateId -Authority $authority)
        Assert-EntryReadOnly -Label partial-no-manifest -ActionId $fixture.ActionId -Expected '[REMOVAL_PREFLIGHT] AVAILABLE' -ExitCode 0
        $extraCli++
    }
    Assert-EntryReadOnly -Label unknown -ActionId ([guid]::NewGuid().ToString('N')) -Expected 'not uniquely intent-bound'
    $admissionBytes=[IO.File]::ReadAllBytes($fixture.AdmissionPath)
    try {
        $admission=(Read-BoundedJsonDocument -Path $fixture.AdmissionPath -Label 'fixture admission' -MaximumBytes 131072).Document
        $admission.action_id=[guid]::NewGuid().ToString('N')
        Write-PhaseCRecord $fixture.AdmissionPath $admission
        Assert-EntryReadOnly -Label mismatch -ActionId $fixture.ActionId -Expected '[REMOVAL_PREFLIGHT] BLOCKED'
    } finally {[IO.File]::WriteAllBytes($fixture.AdmissionPath,$admissionBytes)}
    Assert-EntryReadOnly -Label ambiguous -ActionId $fixture.ActionId -ProcessMode ambiguous -Expected 'relevant process command is unobservable'
    Assert-EntryReadOnly -Label no-confirmation -ActionName Uninstall -ActionId $fixture.ActionId -Expected 'second-level project mutation confirmation'
    Assert-EntryReadOnly -Label no-reinstall -ActionName Reinstall -Expected 'second-level project mutation confirmation'
    # Explicitly confirm the representative disallowed action to reach the
    # no-reinstall switch, separately from the mutation-confirmation gate.
    $beforeProject=Get-EntryDigest $projectRoot; $beforeReceipts=Get-EntryDigest $fixture.LocalData
    $blocked=Invoke-EntryCli -Label no-reinstall-confirmed -ActionName Reinstall -Confirmed
    Assert-Entry ($blocked.ExitCode -eq 4 -and $blocked.Text.Contains('Reinstall cannot reinstall a project whose desired state is UNINSTALLED.')) 'confirmed-reinstall-policy-refused'
    Assert-Entry ((Get-EntryDigest $projectRoot) -ceq $beforeProject -and (Get-EntryDigest $fixture.LocalData) -ceq $beforeReceipts) 'confirmed-reinstall-policy-byte-identical'

    $intentHash=Get-FileSha256 $intentPath
    $receiptHash=Get-EntryDigest (Split-Path $fixture.TerminalPath -Parent)
    $instanceRoot=Join-Path $projectRoot ($script:InstancesRelativePath+'/'+$fixture.InstanceId)
    $instanceHash=Get-EntryDigest $instanceRoot
    $completed=Invoke-EntryCli -Label confirmed-uninstall -ActionName Uninstall -ActionId $fixture.ActionId -Confirmed
    Assert-Entry ($completed.ExitCode -eq 0 -and $completed.Text.Contains('FAILED_CANDIDATE_EFFECTS_RETAINED')) 'confirmed-uninstall-top-level-disposition'
    $markerPath=Join-Path $fixture.IndexRoot ('resolved-action-'+$fixture.ActionId+'.json')
    $marker=(Read-BoundedJsonDocument -Path $markerPath -Label 'emitted disposition' -MaximumBytes 131072).Document
    Assert-Entry ($marker.action_id -ceq $fixture.ActionId -and $marker.disposition -ceq 'FailedCandidateEffectsRetained' -and $marker.command_outcome -ceq 'failed_or_unknown' -and $marker.retained_instance_id -ceq $fixture.InstanceId -and $marker.removal_state_id -ceq $stateId) 'disposition-original-action-and-retained-intent-links'
    Assert-Entry ($marker.terminal_sha256 -ceq $fixture.TerminalHash -and $marker.removal_intent_sha256 -ceq $intentHash -and $marker.desired_state_sha256 -ceq (Get-FileSha256 (Join-Path $projectRoot $script:InstanceDesiredStateRelativePath))) 'disposition-original-terminal-intent-desired-hashes'
    Assert-Entry ((Get-FileSha256 $intentPath) -ceq $intentHash -and (Get-EntryDigest (Split-Path $fixture.TerminalPath -Parent)) -ceq $receiptHash -and (Get-EntryDigest $instanceRoot) -ceq $instanceHash) 'confirmed-uninstall-preserves-intent-history-and-retained-effects'
    $terminal=(Read-BoundedJsonDocument -Path $fixture.TerminalPath -Label 'original terminal' -MaximumBytes 131072).Document
    Assert-Entry ($terminal.exit_code -eq 6 -and $terminal.output_drain_incomplete -and $terminal.stdout -ceq 'incomplete original INSTALL' -and $terminal.stderr -ceq 'original failure') 'original-incomplete-command-remains-failed'
    if ($OriginalProjectRoots) {
        $desired=(Read-BoundedJsonDocument -Path (Join-Path $projectRoot $script:InstanceDesiredStateRelativePath) -Label 'retained desired state' -MaximumBytes 131072).Document
        Assert-Entry ($desired.desired_state -ceq 'UNINSTALLED' -and $desired.cleanup_state -ceq 'PENDING') 'mixed-root-retention-preserves-pending-logical-uninstall'
    }
    $null=Get-InstanceRemovalIntent -Manifest $manifest -ProjectRoot $projectRoot -StateId $stateId
    $null=Assert-InstanceNextChangeAdmission -Manifest $manifest -ProjectRoot $projectRoot
    Assert-Entry (-not (Test-Path (Join-Path $fixture.IndexRoot ('resolved-action-'+$fixture.ActionId+'.pending.json')))) 'production-readers-accept-emitted-links-no-pending-marker'
    [IO.File]::WriteAllText((Join-Path $fixtureContainer 'summary.txt'),("PASS assertions=$script:assertions CLI=$(8+$extraCli) PS=$($PSVersionTable.PSVersion) fixture=$fixtureContainer"),$utf8)
    Write-Host "[PASS] assertions=$script:assertions CLI=$(8+$extraCli) evidence=$fixtureContainer"
} finally {
    [Environment]::SetEnvironmentVariable('LOCALAPPDATA',$priorLocal,'Process')
}
