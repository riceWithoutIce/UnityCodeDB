#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$repositoryRoot = Split-Path $packageRoot -Parent
$fixtureContainer = Join-Path $repositoryRoot ('.artifacts/tests/s29-entry/r-' + [guid]::NewGuid().ToString('N').Substring(0,8))
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
    Get-TextSha256 -Text ((@(Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
        $_.FullName.Substring($Root.Length)+':'+(Get-FileSha256 -Path $_.FullName)
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
    foreach($path in @('Payload~/AIWork/codedb/shared/codedb-strict-json.ps1','Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1','Tools~/materialize-codedb-host-payload.ps1','Tools~/codedb-instance-engine.ps1')) {
        Import-EntryDefinitions (Join-Path $packageRoot $path)
    }
    Import-EntryDefinitions (Join-Path $PSScriptRoot 'test-codedb-host-payload-materializer.ps1') @('Write-PhaseCRecord','Invoke-RetainedCandidateRecoveryCase')
    $manifest=Read-PayloadManifest -Root (Join-Path $packageRoot 'Payload~') -ProjectRoot $projectRoot
    $fixture=Invoke-RetainedCandidateRecoveryCase -ProjectRoot $projectRoot -PackageRoot $packageRoot -Manifest $manifest -BuildFixtureOnly
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
    $null=Get-InstanceRemovalIntent -Manifest $manifest -ProjectRoot $projectRoot -StateId $stateId
    $null=Assert-InstanceNextChangeAdmission -Manifest $manifest -ProjectRoot $projectRoot
    Assert-Entry (-not (Test-Path (Join-Path $fixture.IndexRoot ('resolved-action-'+$fixture.ActionId+'.pending.json')))) 'production-readers-accept-emitted-links-no-pending-marker'
    [IO.File]::WriteAllText((Join-Path $fixtureContainer 'summary.txt'),("PASS assertions=$script:assertions CLI=8 PS=$($PSVersionTable.PSVersion) fixture=$fixtureContainer"),$utf8)
    Write-Host "[PASS] assertions=$script:assertions CLI=8 evidence=$fixtureContainer"
} finally {
    [Environment]::SetEnvironmentVariable('LOCALAPPDATA',$priorLocal,'Process')
}
