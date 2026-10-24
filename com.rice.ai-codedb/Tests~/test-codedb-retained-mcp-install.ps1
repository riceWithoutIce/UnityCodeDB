#requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$RunRoot, [switch]$L0Only)
$ErrorActionPreference='Stop'
$package=Split-Path $PSScriptRoot -Parent
$repository=(& git -C $package rev-parse --show-toplevel).Trim()
$primary=(& git -C $package rev-parse --path-format=absolute --git-common-dir).Trim()
$primary=Split-Path $primary -Parent
$run=[IO.Path]::GetFullPath($RunRoot)
$boundary=[IO.Path]::GetFullPath((Join-Path $primary '.artifacts/tests/s40-retained-mcp-install'))
if(-not $run.StartsWith($boundary+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Run must be task-owned'}
for($cursor=$run;$cursor;$cursor=Split-Path $cursor -Parent){if((Test-Path -LiteralPath $cursor) -and ((Get-Item -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Redirected output'}}
if(Test-Path -LiteralPath $run){throw 'Preserve prior run'}
[void][IO.Directory]::CreateDirectory($run)
foreach($part in @('local','tmp')){[void][IO.Directory]::CreateDirectory((Join-Path $run $part))}
$env:LOCALAPPDATA=Join-Path $run 'local';$env:TEMP=Join-Path $run 'tmp';$env:TMP=$env:TEMP
$env:RICE_CODEDB_PROJECT_INSTALL_ADMISSION=''
$parts=[Collections.Generic.List[string]]::new()
$inputs=@('Payload~/AIWork/codedb/shared/codedb-strict-json.ps1','Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1','Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1','Payload~/AIWork/codedb/shared/codedb-mcp-registration-contract.ps1','Tools~/materialize-codedb-host-payload.ps1','Tools~/codedb-instance-engine.ps1')
foreach($relative in $inputs){
 $tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $package $relative),[ref]$tokens,[ref]$errors)
 if($errors.Count){throw "Production parse failed: $relative"}
 $beforeFunctions=$true
 foreach($statement in $ast.EndBlock.Statements){
  if($statement -is [Management.Automation.Language.FunctionDefinitionAst]){$beforeFunctions=$false;$parts.Add($statement.Extent.Text)}
  elseif($beforeFunctions -and (($statement -is [Management.Automation.Language.AssignmentStatementAst] -and $statement.Left.Extent.Text.StartsWith('$script:')) -or $statement -is [Management.Automation.Language.ForEachStatementAst])){$parts.Add($statement.Extent.Text)}
 }
}
$module=New-Module -ScriptBlock ([scriptblock]::Create($parts -join "`n"))
$manifest=[ordered]@{evidence='HARNESS: production functions/records, synthetic process and prerequisite inputs, PocFixture backend';base=(& git -C $package rev-parse HEAD).Trim();package=$package;run=$run;network='none';local=$env:LOCALAPPDATA;tmp=$env:TEMP;process_roles='test PowerShell only; no Unity, Provider or external client';powershell=@{path=(Get-Process -Id $PID).Path;version=$PSVersionTable.PSVersion.ToString()};sources=@($inputs|ForEach-Object{@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $package $_)).Hash.ToLowerInvariant()}})}
[IO.File]::WriteAllText((Join-Path $run 'manifest.json'),($manifest|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
Start-Transcript -Path (Join-Path $run 'run.log') | Out-Null
try { & $module {
 param($package,$run,$l0Only)
 $ErrorActionPreference='Stop'
 $script:Cases=0
 function Check($condition,$label){if(-not $condition){throw "Assertion failed: $label"};$script:Cases++;Write-Host "PASS $label"}
 function Record($path,$value){Assert-PathInside -Path $path -Root $run -Label 'fixture record';[void][IO.Directory]::CreateDirectory((Split-Path $path -Parent));[IO.File]::WriteAllText($path,(ConvertTo-InstanceJsonText $value),[Text.UTF8Encoding]::new($false))}
 function Reject($body,$reason,$label){$message='';try{& $body|Out-Null}catch{$message=$_.Exception.Message};Check ($message -like ('*'+$reason+'*')) "$label [$message]"}
 function Fault($path,$change,$body,$reason,$label){$bytes=[IO.File]::ReadAllBytes($path);try{$doc=(Read-BoundedJsonDocument -Path $path -Label 'fixture fault' -MaximumBytes 1048576).Document;& $change $doc;Record $path $doc;Reject $body $reason $label}finally{[IO.File]::WriteAllBytes($path,$bytes)}}
 function ResetResult {$script:RequestedExitCode=0;$script:CommandOutcome='';$script:CommandReasonCode='';$script:CommandCleanupState='';$script:CommandNextAction='';$script:CommandMutatedScopes.Clear()}
 # Only external prerequisite/process/command observations are synthetic.
 function Get-MaterializerMachinePrerequisiteStatus {param($Manifest);[pscustomobject]@{Current=$true;State='CURRENT';ReasonCode='FIXTURE_CURRENT';Detail='Synthetic prerequisite';NextAction='';NodePath='';NodeVersion='fixture';ProviderVersion='fixture';ProviderRoot='';ProviderManifestPath='';ProviderExecutablePath=''}}
 $script:HolderStart=1234567890000;$script:HolderKnown=$true;$script:HolderAlive=$true;$script:EditorAlive=$true
 $script:WriterId=123456789;$script:HolderId=234567890
 $script:FixtureNodePath=Join-Path $run 'synthetic-node/node.exe'
 function Get-MaterializerProcessIdentity {param($ProcessId)
  if($ProcessId -eq $PID){return [pscustomobject]@{Alive=$true;StartTicks='638962992000000001';StartUnixMilliseconds=1}}
  if($ProcessId -eq $script:WriterId){return [pscustomobject]@{Alive=$true;StartTicks='638962992000000000';StartUnixMilliseconds=1}}
  if($ProcessId -eq $script:HolderId){return [pscustomobject]@{Alive=$script:HolderAlive;StartTicks=$null;StartUnixMilliseconds=$(if($script:HolderKnown){$script:HolderStart}else{$null})}}
  if($ProcessId -eq 345678901){return [pscustomobject]@{Alive=$script:EditorAlive;StartTicks='123';StartUnixMilliseconds=123}}
  throw "Undeclared process observation $ProcessId"
 }
 function Get-CimInstance {param($ClassName,$ErrorAction);return $script:Rows}
 function Get-MaterializerWindowsProcessCommandIdentity {param($ProcessId);if($ProcessId -ne $script:HolderId){throw 'Undeclared command identity'};return $script:Command}
 function Invoke-BoundedNativeProcessWithFileOutput {throw 'Provider execution forbidden'}
 $root=Join-Path $run 'project'
 foreach($dir in @('Assets','Packages','ProjectSettings')){[void][IO.Directory]::CreateDirectory((Join-Path $root $dir))}
 $script:Rows=@([pscustomobject]@{Name='powershell.exe';ProcessId=$PID;ParentProcessId=$script:WriterId;CommandLine='fixture child'},[pscustomobject]@{Name='powershell.exe';ProcessId=$script:WriterId;ParentProcessId=0;CommandLine='fixture writer'})
 $script:Command=[pscustomobject]@{ExecutablePath=$script:FixtureNodePath;Arguments=@($script:FixtureNodePath,'AIWork/codedb/wrapper/codedb-project-wrapper.mjs','--root','.');CommandLine='fixture registered wrapper'}
 $script:PocFixture=$true;$script:Action='Install'
 $manifest=Read-PayloadManifest -Root (Join-Path $package 'Payload~') -ProjectRoot $root
 ResetResult
 Invoke-InstanceConvergence -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath) -ActionName Install
 $old=Get-ValidatedCurrentInstance -Manifest $manifest -ProjectRoot $root
 $oldEpoch=$old.ActivationEpoch
 Check ($script:CommandCleanupState -ceq 'COMPLETE' -and (Get-InstanceDesiredState -ProjectRoot $root).CleanupState -ceq 'COMPLETE') 'first activation without retained instances reports complete cleanup'
 # Real authenticated Manager admission files, without launching the writer.
 $script:OriginatingActionId='1'*32
 $actionRoot=Join-Path $env:LOCALAPPDATA ('Rice/CodeDB/manager-actions/'+$script:OriginatingActionId)
 $admission=Join-Path $actionRoot 'stage.admitted.json'
 Record (Join-Path $actionRoot 'action.json') @{execution_route='project-install-v1';action_id=$script:OriginatingActionId}
 Record $admission @{state='admitted';action_id=$script:OriginatingActionId;stage_id=('2'*64);project_root=$root;project_identity=(Get-MaterializerProjectIdentity -ProjectRoot $root)}
 Record (Join-Path $actionRoot 'stage.claim.json') @{state='claimed';action_id=$script:OriginatingActionId;stage_id=('2'*64);writer_pid=$script:WriterId;writer_start_utc_ticks='638962992000000000'}
 $leasePath=Join-Path $old.InstanceRoot ('leases/mcp-'+$script:HolderId+'-'+('3'*32)+'.json')
 Record $leasePath @{schema_version=1;instance_lease_version=1;managed_by=$script:ManagedBy;owner='mcp';project_identity=(Get-MaterializerProjectIdentity -ProjectRoot $root);project_root=$root;instance_id=$old.InstanceId;generation_id=$manifest.GenerationId;lease_id=('mcp-'+$script:HolderId+'-'+('3'*32));pid=$script:HolderId;process_start_identity=[string]$script:HolderStart;created_at_utc=[DateTime]::UtcNow.ToString('o');heartbeat_at_utc=[DateTime]::UtcNow.ToString('o')}
 ResetResult
 Invoke-InstanceUninstall -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath)
 $desired=Get-InstanceDesiredState -ProjectRoot $root
 $intent=Get-InstanceRemovalIntent -Manifest $manifest -ProjectRoot $root -StateId $desired.StateId
 $evidence=Get-ValidatedRetiredInstance -Manifest $manifest -ProjectRoot $root -InstanceRoot $old.InstanceRoot
 Check ($desired.DesiredState -ceq 'UNINSTALLED' -and $desired.CleanupState -ceq 'PENDING') 'production logical uninstall retains MCP without cleanup'
 $admit={Assert-ProjectInstallExecutionAdmission -Manifest $manifest -ProjectRoot $root -AdmissionPath $admission}
 function Admit {param($label);$lock=Enter-MaterializerLock -ProjectRoot $root;try{& $admit;Check $true $label}finally{Exit-MaterializerLock $lock}}
 Admit 'known relative registered wrapper admitted'
 Check (-not (Get-InstanceRetirementHolderEvidence -Evidence $evidence -ProjectRoot $root).Clear) 'deletion authority remains false with live MCP'
 $script:Command.Arguments=@($script:FixtureNodePath,(Join-Path $root 'AIWork/codedb/wrapper/codedb-project-wrapper.mjs'),'--root',$root)
 $script:Rows+=,[pscustomobject]@{Name='node.exe';ProcessId=$script:HolderId;ParentProcessId=0;CommandLine=('node --root '+$root)}
 Admit 'known absolute registered wrapper is not competing writer'
 $originalCommand=$script:Command
 $script:HolderKnown=$false;Reject $admit 'identity is unknown' 'unknown start remains blocked';$script:HolderKnown=$true
 $script:Command=$null;Reject $admit 'invocation is unknown' 'unknown invocation remains blocked';$script:Command=$originalCommand
 $script:Command.Arguments=@($script:FixtureNodePath,'foreign.mjs','--root',$root);Reject $admit 'registered project wrapper' 'foreign invocation remains blocked'
 $script:Command.Arguments=@($script:FixtureNodePath,'AIWork/codedb/wrapper/codedb-project-wrapper.mjs','--root','.')
 Fault $leasePath {param($d)$d.project_identity='sha256:'+('0'*64)} $admit 'invalid holders' 'foreign lease remains blocked'
 Fault $intent.Path {param($d)$d.retained_instance_manifest_sha256='0'*64} $admit 'manifest changed' 'intent hash conflict remains blocked'
 $intentBytes=[IO.File]::ReadAllBytes($intent.Path);try{[IO.File]::Delete($intent.Path);Reject $admit 'blocked' 'missing intent remains blocked'}finally{[IO.File]::WriteAllBytes($intent.Path,$intentBytes)}
 $pointer=Join-Path $root $script:InstanceCurrentRelativePath
 try{[IO.File]::WriteAllText($pointer,$old.SelectionText);Reject $admit 'logically uninstalled' 'selected predecessor blocks exception'}finally{[IO.File]::Delete($pointer)}
 $editorPath=Join-Path $old.InstanceRoot ('watch/lifecycle/editor-leases/'+('4'*32)+'.json')
 Record $editorPath @{schema_version=1;managed_by=$script:ManagedBy;session_id=('4'*32);editor_pid=345678901;process_start_ticks='123';project_root=$root;project_identity=(Get-MaterializerProjectIdentity -ProjectRoot $root);last_heartbeat_utc=[DateTime]::UtcNow.ToString('o')}
 try{Reject $admit 'active runtime writer' 'live Editor remains blocked'}finally{[IO.File]::Delete($editorPath)}
 $coordinatorPath=Join-Path $old.InstanceRoot 'watch/coordinator/coordinator-state.json'
 Record $coordinatorPath @{schema_version=2;generation_id=$manifest.GenerationId;root=$root;runtime=(Join-Path $old.InstanceRoot 'watch/coordinator');started_at_utc=[DateTime]::UtcNow.ToString('o');coordinator_pid=345678901;lifecycle_id='fixture'}
 try{Reject $admit 'active runtime writer' 'live Coordinator remains blocked'}finally{[IO.File]::Delete($coordinatorPath)}
 $savedGeneration=$manifest.GenerationId;try{$manifest.GenerationId='poc.999';Reject {Get-InstanceRetainedMcpInstallHolders -Manifest $manifest -ProjectRoot $root -Evidence $evidence} 'current-Package' 'other generation has no exception'}finally{$manifest.GenerationId=$savedGeneration}
 $savedState=$evidence.Manifest.state;try{$evidence.Manifest.state='PROVISIONING';Reject {Get-InstanceRetainedMcpInstallHolders -Manifest $manifest -ProjectRoot $root -Evidence $evidence} 'current-Package' 'failed preparation has no exception'}finally{$evidence.Manifest.state=$savedState}
 $script:Rows+=,[pscustomobject]@{Name='node.exe';ProcessId=456789012;ParentProcessId=0;CommandLine=('node supervisor --root '+$root)}
 Reject $admit 'project-bound execution' 'competing project execution remains blocked';$script:Rows=$script:Rows[0..2]
 $oldSnapshot=@(Get-ChildItem -LiteralPath $old.InstanceRoot -Recurse -File|ForEach-Object{@{path=$_.FullName;hash=(Get-FileSha256 -Path $_.FullName)}})
 $intentHash=Get-FileSha256 -Path $intent.Path
 if(-not $l0Only){
  # Exercise original convergence, including the same Manager admission boundary.
  $env:RICE_CODEDB_PROJECT_INSTALL_ADMISSION=$admission
  $script:TestFailInstanceCandidate=$true
  try{ResetResult;Reject {Invoke-InstanceConvergence -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath) -ActionName Install} 'Injected candidate' 'candidate failure after holder admission'}finally{$script:TestFailInstanceCandidate=$false}
  Check ((Get-InstanceDesiredState -ProjectRoot $root).DesiredState -ceq 'UNINSTALLED' -and -not (Test-Path -LiteralPath $pointer)) 'candidate failure preserves logical uninstall and no selection'
  ResetResult
  Invoke-InstanceConvergence -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath) -ActionName Install
  $fresh=Get-ValidatedCurrentInstance -Manifest $manifest -ProjectRoot $root
  Check ($fresh.InstanceId -cne $old.InstanceId -and $fresh.ActivationEpoch -cne $oldEpoch) 'admitted production convergence creates distinct instance and epoch'
  Check ((Get-FileSha256 -Path $intent.Path) -ceq $intentHash) 'old removal intent preserved'
  foreach($item in $oldSnapshot){Check ((Get-FileSha256 -Path $item.path) -ceq $item.hash) ('old instance unchanged: '+[IO.Path]::GetFileName($item.path))}
  Record (Join-Path $run 'worker-fixture.json') @{root=$root;old=$old.InstanceId;fresh=$fresh.InstanceId;generation=$fresh.Generation.GenerationRoot;package=$package}
  Record (Join-Path $run 'cleanup-observation.json') @{outcome=$script:CommandOutcome;command_cleanup=$script:CommandCleanupState;desired_cleanup=(Get-InstanceDesiredState -ProjectRoot $root).CleanupState;instance_cleanup=(Get-InstanceCleanupState -ProjectRoot $root -Manifest $manifest -CurrentInstance $fresh);versioned_cleanup=(Get-VersionedInstanceRetirementCleanupState -ProjectRoot $root -Manifest $manifest);old_intent_present=(Test-Path -LiteralPath $intent.Path);old_lease_present=(Test-Path -LiteralPath $leasePath)}
  Check ($script:CommandOutcome -ceq 'INSTALLED' -and $script:CommandCleanupState -ceq 'PENDING') 'successful new activation retains pending cleanup'
  Check ((Get-InstanceDesiredState -ProjectRoot $root).CleanupState -ceq 'PENDING') 'desired state preserves pending cleanup after activation'
  Check ((Test-Path -LiteralPath $leasePath) -and -not (Get-InstanceRetirementHolderEvidence -Evidence $evidence -ProjectRoot $root).Clear) 'retained MCP still prevents physical deletion after new activation'
  # F1: A's reader remains live across a second logical uninstall/fresh Install.
  ResetResult
  Invoke-InstanceUninstall -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath)
  $secondDesired=Get-InstanceDesiredState -ProjectRoot $root
  $secondIntent=Get-InstanceRemovalIntent -Manifest $manifest -ProjectRoot $root -StateId $secondDesired.StateId
  Check ($secondDesired.DesiredState -ceq 'UNINSTALLED' -and $secondDesired.CleanupState -ceq 'PENDING' -and $secondIntent.InstanceId -ceq $fresh.InstanceId -and $secondDesired.StateId -cne $desired.StateId) 'second uninstall has its own intent while the oldest MCP remains'
  $secondIntentHash=Get-FileSha256 -Path $secondIntent.Path
  $secondSnapshot=@(Get-ChildItem -LiteralPath $fresh.InstanceRoot -Recurse -File|ForEach-Object{@{path=$_.FullName;hash=(Get-FileSha256 -Path $_.FullName)}})
  Reject {Get-InstanceRetainedMcpInstallHolders -Manifest $manifest -ProjectRoot $root -Evidence $evidence -RemovalStateId $secondDesired.StateId} 'normal-uninstall closure' 'a newer valid intent cannot authorize the oldest instance'
  Fault $intent.Path {param($d)$d.retained_instance_manifest_sha256='0'*64} $admit 'manifest changed' 'tampered older intent blocks despite a valid latest intent'
  Admit 'two-cycle admission retains the oldest reader using its own intent'
  ResetResult
  Invoke-InstanceConvergence -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath) -ActionName Install
  $third=Get-ValidatedCurrentInstance -Manifest $manifest -ProjectRoot $root
  Check ($third.InstanceId -cnotin @($old.InstanceId,$fresh.InstanceId) -and $third.ActivationEpoch -cnotin @($oldEpoch,$fresh.ActivationEpoch)) 'second fresh Install publishes a distinct third instance and epoch'
  Check ($script:CommandOutcome -ceq 'INSTALLED' -and $script:CommandCleanupState -ceq 'PENDING' -and (Get-InstanceDesiredState -ProjectRoot $root).CleanupState -ceq 'PENDING') 'second fresh Install preserves command and desired pending cleanup'
  Check ((Get-FileSha256 -Path $intent.Path) -ceq $intentHash -and (Get-FileSha256 -Path $secondIntent.Path) -ceq $secondIntentHash) 'both normal removal intents remain unchanged after two cycles'
  foreach($item in @($oldSnapshot)+@($secondSnapshot)){Check ((Get-FileSha256 -Path $item.path) -ceq $item.hash) ('two-cycle retained instance unchanged: '+[IO.Path]::GetFileName($item.path))}
  Check ((Test-Path -LiteralPath $leasePath) -and -not (Get-InstanceRetirementHolderEvidence -Evidence $evidence -ProjectRoot $root).Clear) 'oldest connected MCP still prevents deletion after two cycles'
  Record (Join-Path $run 'two-cycle-observation.json') @{old_instance=$old.InstanceId;second_instance=$fresh.InstanceId;third_instance=$third.InstanceId;old_intent_state=$desired.StateId;second_intent_state=$secondDesired.StateId;command_cleanup=$script:CommandCleanupState;desired_cleanup=(Get-InstanceDesiredState -ProjectRoot $root).CleanupState;old_lease_present=(Test-Path -LiteralPath $leasePath)}
  Record (Join-Path $run 'worker-fixture.json') @{root=$root;old=$old.InstanceId;fresh=$third.InstanceId;generation=$third.Generation.GenerationRoot;package=$package}
 }
 Record (Join-Path $run 'result.json') @{state='PASS';cases=$script:Cases;evidence='HARNESS';l0_only=[bool]$l0Only;old_instance=$old.InstanceId;external_client_calls=0;provider_execution=0}
 Write-Host ('PASS S40 cases='+$script:Cases+'; production state/closure, synthetic OS/prerequisite, PocFixture; NOT real lifecycle acceptance')
} $package $run ([bool]$L0Only) } finally {Stop-Transcript | Out-Null}
