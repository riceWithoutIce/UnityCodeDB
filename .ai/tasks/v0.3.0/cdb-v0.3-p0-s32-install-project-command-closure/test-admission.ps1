param([string]$RunRoot,[string]$PackageRoot,[switch]$SetupOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PackageRoot 'Payload~/AIWork/codedb/shared/codedb-strict-json.ps1')
. (Join-Path $PackageRoot 'Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1')
# HARNESS: original functions, real scoped files/lock; process/retained-closure
# observations below are explicit inputs, not a simulated successful Install.
foreach($relative in @('Tools~/materialize-codedb-host-payload.ps1','Tools~/codedb-instance-engine.ps1')){
 $errors=$null;$tokens=$null;$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PackageRoot $relative),[ref]$tokens,[ref]$errors)
 foreach($statement in $ast.EndBlock.Statements){
  if($statement -is [Management.Automation.Language.FunctionDefinitionAst] -or $statement -is [Management.Automation.Language.AssignmentStatementAst]){
   . ([scriptblock]::Create($statement.Extent.Text))
  }
 }
}
$project=Join-Path $RunRoot 'admission-project'
[void][IO.Directory]::CreateDirectory($project)
$OriginatingActionId='1'*32
$writerId=123456789
$writerTicks='638962992000000000'
$receiptRoot=Join-Path $env:LOCALAPPDATA 'Rice/CodeDB/manager-actions'
$actionRoot=Join-Path $receiptRoot $OriginatingActionId
[void][IO.Directory]::CreateDirectory($actionRoot)
$admission=Join-Path $actionRoot (('2'*16)+'.admitted.json')
function Json($path,$document){[IO.File]::WriteAllText($path,($document|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))}
$projectIdentity=Get-MaterializerProjectIdentity -ProjectRoot $project
Json $admission @{state='admitted';action_id=$OriginatingActionId;stage_id=('2'*64);project_root=$project;project_identity=$projectIdentity}
Json (Join-Path $actionRoot 'action.json') @{execution_route='project-install-v1';action_id=$OriginatingActionId}
Json ($admission -replace '\.admitted\.json$','.claim.json') @{state='claimed';action_id=$OriginatingActionId;stage_id=('2'*64);writer_pid=$writerId;writer_start_utc_ticks=$writerTicks}
$script:ProcessRows=@([pscustomobject]@{Name='powershell.exe';ProcessId=$PID;ParentProcessId=$writerId;CommandLine='fixture current child'},[pscustomobject]@{Name='powershell.exe';ProcessId=$writerId;ParentProcessId=0;CommandLine='fixture exact writer'})
$script:WriterAlive=$true;$script:HoldersClear=$true;$script:Retained=$false;$script:HistoryChildAlive=$false
function Get-CimInstance {param($ClassName,$ErrorAction) return $script:ProcessRows}
function Get-MaterializerProcessIdentity {param([int]$ProcessId)
 if($ProcessId -eq $writerId){return [pscustomobject]@{Alive=$script:WriterAlive;StartTicks=$writerTicks}}
 return [pscustomobject]@{Alive=$script:HistoryChildAlive;StartTicks='638962991000000000'}
}
$script:Evidence=[pscustomobject]@{InstanceId=('3'*32);InstanceRoot=(Join-Path $project 'retained');Manifest=[pscustomobject]@{};Generation=[pscustomobject]@{GenerationId='fixture-generation'}}
function Get-InstanceRemovalIntents {param($Manifest,$ProjectRoot) if($script:Retained){[pscustomobject]@{InstanceId=$script:Evidence.InstanceId;InstanceRoot=$script:Evidence.InstanceRoot;Document=[pscustomobject]@{schema_version=1}}}}
function Get-ValidatedRetiredInstance {param($Manifest,$ProjectRoot,$InstanceRoot,[switch]$AllowProvisioning,[switch]$FailedPreparation) return $script:Evidence}
function Get-ValidatedInstanceRetirementControls {param($Manifest,$ProjectRoot) return @()}
function Get-InstanceRetirementHolderEvidence {param($Evidence,$ProjectRoot) return [pscustomobject]@{Clear=$script:HoldersClear}}
function Get-InstanceGenerationPackageIdentity {param($Manifest,$InstanceManifest) return [pscustomobject]@{RuntimeContractSha256=('4'*64)}}
function Get-InstanceActivationContractRoot {param($Manifest,$ProjectRoot) return (Join-Path $ProjectRoot 'AIWork/.runtime/codedb/control/contracts/v0.3-control/v2')}
$manifest=@{}
function Check([string]$label,[bool]$refused,[string]$reason=''){
 $caught=$false;$operationLock=$null
 try{
  $operationLock=Enter-MaterializerLock -ProjectRoot $project
  Assert-ProjectInstallExecutionAdmission -Manifest $manifest -ProjectRoot $project -AdmissionPath $admission
 }catch{$caught=$true;if(-not $refused -or $_.Exception -is [Management.Automation.CommandNotFoundException]){throw};if($reason -and $_.Exception.Message -notlike ('*'+$reason+'*')){throw}}
 finally{Exit-MaterializerLock -Lock $operationLock}
 if($caught -ne $refused){throw ('Unexpected admission '+$label)}
 Write-Output ('PASS '+$label)
}
if($SetupOnly){return}
Check 'first Install under original project lock' $false
$runtime=Join-Path (Get-InstanceActivationContractRoot -Manifest $manifest -ProjectRoot $project) 'supervisor'
[void][IO.Directory]::CreateDirectory((Join-Path $runtime 'operation-history'))
[void][IO.Directory]::CreateDirectory((Join-Path $runtime 'manager-actions'))
$script:Retained=$true
$operation=@{schema_version=1;managed_by='com.rice.ai-codedb';project_identity=$projectIdentity;root=$project;runtime=$runtime;operation_id=('5'*32);manager_action_id=('6'*32);owner_epoch=('7'*32);key='materialize:Uninstall';request_id='fixture-request';name='materialize:Uninstall';lane='maintenance';execution_disposition='CHILD_ADMITTED';state='completed';phase='completed';selected_instance_id=$script:Evidence.InstanceId;selected_generation_id='fixture-generation';runtime_contract_sha256=('4'*64);started_at_utc='2026-10-17T01:00:00.000Z';completed_at_utc='2026-10-17T01:00:01.000Z';result=@{exit_code=0;stdout='complete fixture output';stderr='';timed_out=$false;output_overflow=$false;output_drain_incomplete=$false};child=@{schema_version=1;pid=87654321;process_start_identity='638962990000000000';executable_path=(Join-Path $PSHOME 'powershell.exe');argv_sha256=('8'*64);command_line_sha256=('9'*64);command=(Join-Path $PSHOME 'powershell.exe');normalized_argv=@('-File','fixture.ps1')}}
$history=Join-Path $runtime ('operation-history/'+('5'*32)+'.json')
$canonical=Join-Path $runtime 'operation.json'
Json $history $operation
Copy-Item -LiteralPath $history -Destination $canonical
Json (Join-Path $runtime ('manager-actions/'+('6'*32)+'.json')) @{schema_version=1;managed_by='com.rice.ai-codedb';project_identity=$projectIdentity;root=$project;runtime=$runtime;manager_action_id=('6'*32);operation_ids=@(('5'*32));latest_operation_id=('5'*32)}
Check 'completed attributable uninstall topology retains history' $false
$script:HoldersClear=$false;Check 'retained live or unknown holder' $true;$script:HoldersClear=$true
$script:WriterAlive=$false;Check 'writer identity unavailable' $true;$script:WriterAlive=$true
$script:ProcessRows+=,[pscustomobject]@{Name='node.exe';ProcessId=345678;ParentProcessId=0;CommandLine=('node supervisor --root '+$project)}
Check 'project-bound live Supervisor even without state or selection' $true
$script:ProcessRows=$script:ProcessRows[0..1]
$script:ProcessRows+=,[pscustomobject]@{Name='node.exe';ProcessId=345679;ParentProcessId=0;CommandLine=$null}
Check 'unrelated inaccessible Node metadata does not own project' $false
$script:ProcessRows=$script:ProcessRows[0..1]
foreach($flag in @('timed_out','output_overflow','output_drain_incomplete')){
 $operation.state='failed';$operation.phase='failed';$operation.result.exit_code=1;$operation.result[$flag]=$true
 Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
 Check ('incomplete execution '+$flag+' remains unknown') $true
 $operation.result[$flag]=$false
}
Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
Check 'complete failed command is inactive execution not running or success' $false
$saved=$operation.result;$operation.Remove('result');Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
Check 'missing result refuses' $true
$operation.result=$saved
$savedFlag=$operation.result.output_overflow;$operation.result.Remove('output_overflow');Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
Check 'missing completeness flag refuses' $true
$operation.result.output_overflow=$savedFlag
$operation.completed_at_utc='invalid';Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
Check 'referenced malformed timestamp refuses' $true
$operation.completed_at_utc='2026-10-17T01:00:01.000Z'
$operation.state='completed';$operation.phase='completed';$operation.result.exit_code=0
Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
$old=$operation.Clone();$old.operation_id='a'*32;$old.manager_action_id='';$old.selected_instance_id='b'*32;$old.selected_generation_id='removed-old-generation'
$oldPath=Join-Path $runtime ('operation-history/'+$old.operation_id+'.json');Json $oldPath $old
Check 'coherent inert history does not require old retained generation' $false
$script:Evidence.Manifest=[pscustomobject]@{originating_action=[pscustomobject]@{action='INSTALL';action_id=('c'*32);operation_id=$old.operation_id}}
Check 'retained origin explicitly references otherwise inert Supervisor history' $true 'no retained instance binding'
$script:Evidence.Manifest=[pscustomobject]@{}
$old.result=@{exit_code=1;stdout='';stderr='incomplete';timed_out=$true;output_overflow=$false;output_drain_incomplete=$false};$old.state='failed';$old.phase='failed';Json $oldPath $old
Check 'noncanonical incomplete execution cannot be silently treated as inert history' $true
$old.result=$operation.result
$old.state='running';$old.phase='running';Json $oldPath $old
Check 'overwritten canonical does not hide another running operation' $true
$old.state='queued';$old.phase='queued';Json $oldPath $old
Check 'overwritten canonical does not hide another queued operation' $true
[IO.File]::Delete($oldPath)
[IO.File]::Move($canonical,$canonical+'.saved')
Check 'history with missing current operation anchor remains unknown' $true
[IO.File]::Move($canonical+'.saved',$canonical)
Json (Join-Path $runtime 'supervisor.lock') @{}
Check 'conflicting Supervisor owner evidence' $true
[IO.File]::Delete((Join-Path $runtime 'supervisor.lock'))
$alternate=Join-Path $project 'AIWork/.runtime/codedb/control/supervisor'
[void][IO.Directory]::CreateDirectory($alternate)
Check 'alternate historical Supervisor authority is unknown' $true
[IO.Directory]::Delete($alternate)
$operation.state='running';$operation.phase='running';Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
Check 'running retained operation without current owner files' $true
$operation.state='completed';$operation.phase='completed';Json $history $operation;Copy-Item -LiteralPath $history -Destination $canonical -Force
$script:HistoryChildAlive=$true
# Different start identity proves PID reuse, never permission to kill.
Check 'reused historical child PID is not original execution' $false
$originalIdentity=${function:Get-MaterializerProcessIdentity}
function Get-MaterializerProcessIdentity {param([int]$ProcessId) if($ProcessId -eq $writerId){return [pscustomobject]@{Alive=$true;StartTicks=$writerTicks}};return [pscustomobject]@{Alive=$true;StartTicks=$null}}
Check 'referenced historical child identity unavailable despite inaccessible inventory' $true
function Get-MaterializerProcessIdentity {param([int]$ProcessId) if($ProcessId -eq $writerId){return [pscustomobject]@{Alive=$true;StartTicks=$writerTicks}};return [pscustomobject]@{Alive=$true;StartTicks='638962990000000000'}}
Check 'original historical child still live' $true
Write-Output 'HARNESS PASS: no candidate created, initialization/activation/Provider not exercised; original lock and Install ownership guard only.'
