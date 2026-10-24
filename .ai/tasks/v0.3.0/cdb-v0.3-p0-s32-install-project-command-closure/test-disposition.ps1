param([string]$RunRoot,[string]$PackageRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'test-admission.ps1') -RunRoot $RunRoot -PackageRoot $PackageRoot -SetupOnly
$fixture=Get-Content -Raw -LiteralPath (Join-Path $RunRoot 'producer/fixtures.json')|ConvertFrom-Json
$runtime=Join-Path (Get-InstanceActivationContractRoot -Manifest $manifest -ProjectRoot $project) 'supervisor'
if(-not (Test-RemoveIntegrationPathEqual -Left $runtime -Right $fixture.context.runtime)){throw 'Producer/reader context mismatch'}
$script:Retained=$true
$canonical=Join-Path $runtime 'operation.json'
$historyRoot=Join-Path $runtime 'operation-history'
function Reset-Execution {
 foreach($id in @($fixture.cases.operationId|Select-Object -Unique)){
  $file=Join-Path $historyRoot ($id+'.json');if(Test-Path -LiteralPath $file){[IO.File]::Delete($file)}
 }
 if(Test-Path -LiteralPath $canonical){[IO.File]::Delete($canonical)}
}
function Select-Execution([string]$name){
 Reset-Execution
 $case=@($fixture.cases|Where-Object{$_.name -ceq $name})[0]
 Copy-Item -LiteralPath $case.path -Destination $canonical
 Copy-Item -LiteralPath $case.path -Destination (Join-Path $historyRoot ($case.operationId+'.json'))
}
Select-Execution 'ready-no-child'
Check 'original ready branch serialized NO_CHILD passes current Install reader' $false
Select-Execution 'identified-child'
Check 'original pre-spawn admission and captured child complete terminal passes' $false
$inactive=@($fixture.cases|Where-Object{$_.name -ceq 'ready-no-child'})[0]
$old=Get-Content -Raw -LiteralPath $inactive.path|ConvertFrom-Json
$old.selected_instance_id='b'*32;$old.selected_generation_id='inert-old-generation'
Json (Join-Path $historyRoot ($old.operation_id+'.json')) $old
Check 'proved NO_CHILD inert history does not require old generation' $false
foreach($name in @('legacy-missing','capture-failed','second-capture-missing','no-child-conflict')){
 Select-Execution $name
 Check ('original serialized '+$name+' remains unknown or conflicting') $true
}
Select-Execution 'ready-no-child'
$current=Get-Content -Raw -LiteralPath $canonical|ConvertFrom-Json
$current.execution_disposition='UNKNOWN';Json $canonical $current;Json (Join-Path $historyRoot ($current.operation_id+'.json')) $current
Check 'explicit UNKNOWN is not NO_CHILD' $true
Select-Execution 'ready-no-child'
$current=Get-Content -Raw -LiteralPath $canonical|ConvertFrom-Json
$current.result.output_drain_incomplete=$true;Json $canonical $current;Json (Join-Path $historyRoot ($current.operation_id+'.json')) $current
Check 'NO_CHILD cannot bypass complete output requirement' $true
Select-Execution 'ready-no-child'
$hidden=@($fixture.cases|Where-Object{$_.name -ceq 'hidden-running'})[0]
Copy-Item -LiteralPath $hidden.path -Destination (Join-Path $historyRoot ($hidden.operationId+'.json'))
Check 'canonical NO_CHILD does not hide unfinished operation' $true
Select-Execution 'identified-child'
function Get-MaterializerProcessIdentity {param([int]$ProcessId) if($ProcessId -eq $writerId){return [pscustomobject]@{Alive=$true;StartTicks=$writerTicks}};return [pscustomobject]@{Alive=$true;StartTicks='638962990000000000'}}
Check 'CHILD_ADMITTED still checks original child live' $true
function Get-MaterializerProcessIdentity {param([int]$ProcessId) if($ProcessId -eq $writerId){return [pscustomobject]@{Alive=$true;StartTicks=$writerTicks}};return [pscustomobject]@{Alive=$true;StartTicks=$null}}
Check 'CHILD_ADMITTED still checks referenced identity unknown' $true
Write-Output 'HARNESS PASS original no-spawn/child-admission producer -> durable serializer -> actual locked PowerShell Install reader; status/process and retained closure mocked, no full Install/Provider.'
