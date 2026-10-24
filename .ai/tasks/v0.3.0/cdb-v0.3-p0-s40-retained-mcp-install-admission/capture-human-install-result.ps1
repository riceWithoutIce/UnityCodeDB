param([Parameter(Mandatory=$true)][string]$RepositoryRoot,[Parameter(Mandatory=$true)][string]$ProjectRoot)
$ErrorActionPreference='Stop'
$output=Join-Path $RepositoryRoot '.artifacts/tests/s40-retained-mcp-install/human-install-post-a'
if(Test-Path -LiteralPath $output){throw 'Preserve previous snapshot'}
[void][IO.Directory]::CreateDirectory($output)
$captures=[Collections.Generic.List[object]]::new()
function Capture($source,$name){
 $bytes=[IO.File]::ReadAllBytes($source)
 [IO.File]::WriteAllBytes((Join-Path $output $name),$bytes)
 $captures.Add([pscustomobject]@{source=$source;copy=$name;sha256=(Get-FileHash -LiteralPath (Join-Path $output $name)).Hash.ToLowerInvariant()})
 return ([Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xfeff)|ConvertFrom-Json)
}
$control=Join-Path $ProjectRoot 'AIWork/.runtime/codedb/control'
$pointerPath=Join-Path $control 'current-instance.json'
$pointerHash=(Get-FileHash -LiteralPath $pointerPath).Hash
$pointer=Capture $pointerPath 'current-instance.json'
$instance=Capture (Join-Path $ProjectRoot ($pointer.instance_relative_path+'/instance.json')) 'new-instance.json'
$desired=Capture (Join-Path $control 'desired-state.json') 'desired-state.json'
$actionId=$instance.originating_action.action_id
if($actionId -cne '63a1cc9fc5fa4e4eb18f67b0442c5685'){throw 'Action drift'}
$actionRoot=Join-Path $env:LOCALAPPDATA ('Rice/CodeDB/manager-actions/'+$actionId)
$action=Capture (Join-Path $actionRoot 'action.json') 'action.json'
$admitted=Capture (Join-Path $actionRoot '8d5710464b438f75.admitted.json') 'admitted.json'
$claim=Capture (Join-Path $actionRoot '8d5710464b438f75.claim.json') 'claim.json'
$terminal=Capture (Join-Path $actionRoot '8d5710464b438f75.terminal.json') 'terminal.json'
if($terminal.exit_code -ne 0 -or -not $terminal.terminal_for_action -or $terminal.action_id -cne $actionId -or $terminal.stage_id -cne $admitted.stage_id -or $terminal.stage_id -cne $claim.stage_id){throw 'Terminal linkage mismatch'}
$commandLines=@($terminal.stdout -split "`n" | Where-Object { $_.StartsWith('[COMMAND_RESULT] ') })
if($commandLines.Count -ne 1){throw 'Command result absent or ambiguous'}
$command=$commandLines[0].Substring('[COMMAND_RESULT] '.Length)|ConvertFrom-Json
if($command.outcome -cne 'INSTALLED' -or $command.exit_code -ne 0 -or $instance.state -cne 'READY' -or $desired.desired_state -cne 'INSTALLED'){throw 'Install outcome mismatch'}
if($pointer.instance_id -cne $instance.instance_id -or $terminal.project_identity -cne $pointer.project_identity -or $instance.project_identity -cne $pointer.project_identity -or $captures[1].sha256 -cne $pointer.instance_manifest_sha256){throw 'Selected identity mismatch'}
$expectedReference='file:../../Packages/186aacf-s40-codedbtest2/com.rice.ai-codedb'
$manifest=Get-Content -LiteralPath (Join-Path $ProjectRoot 'Packages/manifest.json') -Raw|ConvertFrom-Json
$lock=Get-Content -LiteralPath (Join-Path $ProjectRoot 'Packages/packages-lock.json') -Raw|ConvertFrom-Json
if($manifest.dependencies.'com.rice.ai-codedb' -cne $expectedReference -or $lock.dependencies.'com.rice.ai-codedb'.version -cne $expectedReference){throw 'Delivered reference drift'}
$engineHash=(Get-FileHash -LiteralPath (Join-Path $action.package_root 'Tools~/codedb-instance-engine.ps1')).Hash.ToLowerInvariant()
if($engineHash -cne 'b8931439f2f77fbebc65f81a3614cedf94b0c5b62f1ddac0e62ae402bf8b045f'){throw 'Delivered engine drift'}
$intent=Capture (Join-Path $control 'removal-intents/0efd158a637644e690c0fcae1d5cab15.json') 'old-removal-intent.json'
$oldRoot=Join-Path $ProjectRoot ('AIWork/.runtime/codedb/instances/'+$intent.retained_instance_id)
$old=Capture (Join-Path $oldRoot 'instance.json') 'old-instance.json'
if($captures[$captures.Count-1].sha256 -cne $intent.retained_instance_manifest_sha256){throw 'Retained manifest mismatch'}
$holderObservations=@(Get-ChildItem -LiteralPath (Join-Path $oldRoot 'leases') -Filter 'mcp-*.json' -File | ForEach-Object {
 $lease=Capture $_.FullName ('old-'+$_.Name)
 $process=@(Get-CimInstance -ClassName Win32_Process -Filter ('ProcessId='+[int]$lease.pid) -ErrorAction Stop)
 $observedStart=$null;$sameStart=$false;$wrapperInvocation=$false
 if($process.Count -eq 1){
  $observedStart=([DateTimeOffset]$process[0].CreationDate).ToUnixTimeMilliseconds().ToString()
  $sameStart=$observedStart -ceq $lease.process_start_identity
  $wrapperInvocation=$process[0].Name -ieq 'node.exe' -and $process[0].CommandLine -like '*AIWork/codedb/wrapper/codedb-project-wrapper.mjs*'
 }
 [pscustomobject]@{pid=$lease.pid;lease_start=$lease.process_start_identity;observed_at_utc=[DateTime]::UtcNow.ToString('o');process_present=($process.Count -eq 1);observed_start=$observedStart;same_start=$sameStart;registered_wrapper_invocation_observed=$wrapperInvocation;timing='POST_ACTION_ONLY; not evidence of pre-Install liveness'}
})
if((Get-FileHash -LiteralPath $pointerPath).Hash -cne $pointerHash){throw 'Selection changed during snapshot'}
$receipt=[ordered]@{state='INSTALL_TERMINAL_AND_SELECTED_INSTANCE_PASS';observed_at_utc=[DateTime]::UtcNow.ToString('o');action_id=$actionId;exit_code=$terminal.exit_code;elapsed_milliseconds=$terminal.elapsed_milliseconds;completed_at_utc=$terminal.completed_at_utc;command_result=$command;project_identity=$pointer.project_identity;new_instance=$instance.instance_id;activation_epoch=$pointer.activation_epoch;generation=$pointer.generation_id;old_instance=$old.instance_id;old_manifest_matches_removal_intent=$true;delivered_engine_sha256=$engineHash;package_reference=$expectedReference;pointer_stable_during_snapshot=$true;old_holder_observations=$holderObservations;pre_action_live_holder_snapshot='NOT_CAPTURED';target_codex_tools_called=0;development_chat_runtime_operations=0;captures=$captures}
[IO.File]::WriteAllText((Join-Path $output 'snapshot.json'),($receipt|ConvertTo-Json -Depth 12),[Text.UTF8Encoding]::new($false))
[pscustomobject]$receipt|Select-Object state,action_id,exit_code,new_instance,activation_epoch,old_instance,old_holder_observations,pre_action_live_holder_snapshot|ConvertTo-Json -Depth 5
