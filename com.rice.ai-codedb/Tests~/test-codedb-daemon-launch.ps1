#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RunRoot, [string]$PackageRoot = '',
    [ValidateSet('normal','missing','corrupt','retained')][string[]]$Scenarios = @('normal','missing','corrupt','retained'))
$ErrorActionPreference = 'Stop'
if (-not $PackageRoot) { $PackageRoot = Join-Path $PSScriptRoot '..' }
$package = [IO.Path]::GetFullPath($PackageRoot)
$tests = [IO.Path]::GetFullPath((Join-Path (Split-Path $package -Parent) '.artifacts/tests'))
$root = [IO.Path]::GetFullPath($RunRoot)
if (-not $root.StartsWith($tests + '\', [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $root)) { throw 'RunRoot must be fresh below checkout .artifacts/tests.' }
$ancestor = Split-Path $root -Parent
while ($ancestor.Length -ge $tests.Length) {
    if ((Test-Path $ancestor) -and (((Get-Item -LiteralPath $ancestor).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw 'RunRoot ancestor is a reparse point.' }
    $ancestor = Split-Path $ancestor -Parent
}
[void][IO.Directory]::CreateDirectory($root)
$utf8 = [Text.UTF8Encoding]::new($false)
function Save($p,$o) { [IO.File]::WriteAllText($p, ($o | ConvertTo-Json -Depth 30), $utf8) }
function Write-FixtureText($p,[string]$s) { [void][IO.Directory]::CreateDirectory((Split-Path $p -Parent)); [IO.File]::WriteAllText($p,$s,$utf8) }
function Read($p) { if (Test-Path -LiteralPath $p) { try { return Get-Content -LiteralPath $p -Raw | ConvertFrom-Json } catch { return $null } }; return $null }
function Hash($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function Sha([string]$s) { $h=[Security.Cryptography.SHA256]::Create(); try { -join ($h.ComputeHash($utf8.GetBytes($s)) | ForEach-Object { $_.ToString('x2') }) } finally { $h.Dispose() } }
function Norm($p) { [IO.Path]::GetFullPath($p).Replace('\','/') }
function OwnedAlive($id) { try { $p=Get-Process -Id $id -ErrorAction Stop; return @{pid=$p.Id;start_ticks=$p.StartTime.ToUniversalTime().Ticks;exe=$p.Path;alive=$true;utc=[DateTime]::UtcNow.ToString('o')} } catch { return $null } }
$token=[Guid]::NewGuid().ToString('N')
Save (Join-Path $root 'owner.json') @{token=$token;head=(& git -C (Split-Path $package -Parent) rev-parse HEAD);utc=[DateTime]::UtcNow.ToString('o')}
$manifest=Read (Join-Path $package 'Payload~/payload-manifest.json')
$generation=Join-Path $package ('Payload~/Generations/'+$manifest.generation_id)
$node=(Get-Command node.exe).Source
$winps=Join-Path $PSHOME 'powershell.exe'
$fixture=Join-Path $PSScriptRoot 'test-codedb-daemon-launch.mjs'
$source=Join-Path $package 'Tools~/materialize-codedb-host-payload.ps1'
$pkg=Join-Path $root 'pkg'; [void][IO.Directory]::CreateDirectory((Join-Path $pkg 'Tools~'))
$writer=Join-Path $pkg 'Tools~/invoke-codedb-manager-action.ps1'
Copy-Item -LiteralPath (Join-Path $package 'Tools~/invoke-codedb-manager-action.ps1') -Destination $writer
$command=Join-Path $pkg 'Tools~/command.ps1'
Write-FixtureText $command @'
$ErrorActionPreference='Stop'
$t=$null;$e=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($env:REPRO_SOURCE,[ref]$t,[ref]$e)
if($e.Count){throw 'Materializer source parse failed'}
foreach($name in @('Throw-MaterializerError','ConvertTo-NativeProcessArgument','Assert-PathInside','Assert-NoReparsePoint','Invoke-BoundedNativeProcessWithFileOutput')){
 $f=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq $name},$false)
 if(-not $f){throw "Missing production helper $name"}; . ([scriptblock]::Create($f.Extent.Text))
}
@{pid=$PID;token=$env:REPRO_TOKEN}|ConvertTo-Json|Set-Content (Join-Path $env:REPRO_SCENARIO_ROOT 'control.json') -Encoding UTF8
$watch=[Diagnostics.Stopwatch]::StartNew()
$result=Invoke-BoundedNativeProcessWithFileOutput -FilePath (Join-Path $PSHOME 'powershell.exe') -Arguments @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $env:REPRO_ROOT 'leaf.ps1')) -OutputRoot (Join-Path $env:REPRO_SCENARIO_ROOT 'native') -TimeoutMilliseconds 20000
@{elapsed_ms=$watch.ElapsedMilliseconds;result=$result}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $env:REPRO_SCENARIO_ROOT 'native-result.json') -Encoding UTF8
[Console]::Out.WriteLine(($result|ConvertTo-Json -Compress))
if($result.OutputDrainIncomplete){exit 6};exit $result.ExitCode
'@
Write-FixtureText (Join-Path $root 'leaf.ps1') @'
$ErrorActionPreference='Stop'
@{pid=$PID;token=$env:REPRO_TOKEN}|ConvertTo-Json|Set-Content (Join-Path $env:REPRO_SCENARIO_ROOT 'leaf.json') -Encoding UTF8
& $env:REPRO_NODE $env:REPRO_FIXTURE cli
exit $LASTEXITCODE
'@
# Developer-side synthetic Provider. No consumer compilation or Add-Type path.
$providerSource=Join-Path $root 'provider.cs'
Write-FixtureText $providerSource @'
using System;
using System.IO;
using System.Diagnostics;
using System.Collections.Generic;
using System.Web.Script.Serialization;
using System.Threading;
public static class FixtureProvider {
 public static int Main(string[] args) {
  var json=new JavaScriptSerializer();
  var timer=new Timer(_=>Environment.Exit(90),null,70000,Timeout.Infinite);
  var record=new Dictionary<string,object>{{"pid",Process.GetCurrentProcess().Id},{"cwd",Environment.CurrentDirectory},{"env",Environment.GetEnvironmentVariable("RICE_CODEDB_UNITY_ROOT")},{"args",args},{"token",Environment.GetEnvironmentVariable("REPRO_TOKEN")}};
  File.WriteAllText(Path.Combine(Environment.GetEnvironmentVariable("REPRO_SCENARIO_ROOT"),"provider-identity.json"),json.Serialize(record));
  if(args.Length!=4 || args[0]!="--config" || args[2]!="mcp" || !File.Exists(args[1])) return 64;
  string line;
  while((line=Console.ReadLine())!=null) {
   var request=json.Deserialize<Dictionary<string,object>>(line);
   if(!request.ContainsKey("id")) continue;
   object result=request["method"].ToString()=="initialize" ? (object)new {serverInfo=new {name="isolated-fixture-provider"}} : new {tools=new[]{new {name="codedb_text_search"}}};
   Console.WriteLine(json.Serialize(new {jsonrpc="2.0",id=request["id"],result=result}));
  }
  timer.Dispose();return 0;
 }
}
'@
$provider=Join-Path $root 'provider.exe'
$csc=Join-Path ([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) 'csc.exe'
$temp=Join-Path $root 'tmp';[void][IO.Directory]::CreateDirectory($temp)
$oldTemp=$env:TEMP;$oldTmp=$env:TMP
try { $env:TEMP=$temp;$env:TMP=$temp; $log=& $csc /nologo /target:exe /r:System.Web.Extensions.dll ('/out:'+$provider) $providerSource 2>&1; $compile=$LASTEXITCODE; Write-FixtureText (Join-Path $root 'provider-build.log') ($log|Out-String) }
finally { $env:TEMP=$oldTemp;$env:TMP=$oldTmp }
if($compile -ne 0){throw 'Synthetic Provider developer build failed.'}
foreach($f in @(Get-ChildItem -LiteralPath $root -Recurse -Filter '*.ps1')) { $t=$null;$e=$null;$null=[Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$t,[ref]$e);if($e.Count){throw ($e|Out-String)} }
function Start-Owned($exe,[string]$argumentLine,$environment,$cwd) {
 $pi=[Diagnostics.ProcessStartInfo]::new();$pi.FileName=$exe;$pi.Arguments=$argumentLine;$pi.UseShellExecute=$false;$pi.CreateNoWindow=$true;$pi.RedirectStandardOutput=$true;$pi.RedirectStandardError=$true;$pi.WorkingDirectory=$cwd
 foreach($kv in $environment.GetEnumerator()){$pi.EnvironmentVariables[$kv.Key]=[string]$kv.Value}
 $p=[Diagnostics.Process]::new();$p.StartInfo=$pi;if(-not $p.Start()){throw 'Fixture child failed to start'}
 return @{process=$p;stdout=$p.StandardOutput.ReadToEndAsync();stderr=$p.StandardError.ReadToEndAsync()}
}
function Run-Node([string]$mode,$environment,$cwd) {
 $child=Start-Owned $node ('"'+$fixture+'" '+$mode) $environment $cwd
 $watch=[Diagnostics.Stopwatch]::StartNew()
 while($watch.ElapsedMilliseconds -lt 16000 -and (-not $child.process.HasExited -or -not $child.stdout.IsCompleted -or -not $child.stderr.IsCompleted)){Start-Sleep -Milliseconds 25}
 if(-not $child.process.HasExited -or -not $child.stdout.IsCompleted -or -not $child.stderr.IsCompleted){throw "Fixture $mode exceeded bound; no kill authorized"}
 $result=@{exit=$child.process.ExitCode;stdout=$child.stdout.Result;stderr=$child.stderr.Result;pid=$child.process.Id}
 $child.process.Dispose();return $result
}
$rows=@();$allProofs=@()
foreach($scenario in $Scenarios) {
 $sr=Join-Path $root $scenario
 foreach($d in @('native','project/Assets','project/Packages','project/ProjectSettings','project/watch/lifecycle/editor-leases','temp','local')){[void][IO.Directory]::CreateDirectory((Join-Path $sr $d))}
 $project=Join-Path $sr 'project';$local=Join-Path $sr 'local';$lifecycle=Join-Path $project 'watch/lifecycle'
 $runtime=Join-Path $project 'watch/coordinator'
 $copy=Join-Path $sr $manifest.generation_id;Copy-Item -LiteralPath $generation -Destination $copy -Recurse
 $coordinator=Join-Path $copy 'coordinator/codedb-watch-coordinator.mjs'
 if($scenario -eq 'missing'){Remove-Item -LiteralPath (Join-Path $copy 'native/win-x64/codedb-daemon-launch.exe')}
 if($scenario -eq 'corrupt'){[IO.File]::AppendAllText((Join-Path $copy 'native/win-x64/codedb-daemon-launch.exe'),'owned tamper')}
 Save (Join-Path $sr 'provider.json') @{}
 Write-FixtureText (Join-Path $project 'builder.mjs') '// No source changes are generated by this launch-only fixture.'
 Save (Join-Path $project 'adapter.json') @{}
 $projectIdentity='sha256:'+(Sha (Norm $project).ToLowerInvariant())
 $now=[DateTime]::UtcNow.ToString('o');$self=[Diagnostics.Process]::GetCurrentProcess()
 Save (Join-Path $lifecycle 'desired-state.json') @{schema_version=1;managed_by='com.rice.ai-codedb';desired_state='enabled';project_root=$project;project_identity=$projectIdentity}
 Save (Join-Path $lifecycle ('editor-leases/'+$token+'.json')) @{schema_version=1;managed_by='com.rice.ai-codedb';session_id=$token;editor_pid=$PID;process_start_ticks=$self.StartTime.ToUniversalTime().Ticks.ToString();project_root=$project;project_identity=$projectIdentity;created_at_utc=$now;heartbeat_at_utc=$now}
 $environment=@{LOCALAPPDATA=$local;TEMP=(Join-Path $sr 'temp');TMP=(Join-Path $sr 'temp');REPRO_ROOT=$root;REPRO_SCENARIO_ROOT=$sr;REPRO_SCENARIO=$scenario;REPRO_SOURCE=$source;REPRO_NODE=$node;REPRO_TOKEN=$token;REPRO_FIXTURE=$fixture;REPRO_COORDINATOR=$coordinator;REPRO_PROJECT=$project;REPRO_PROVIDER=$provider;REPRO_GENERATION=$manifest.generation_id;REPRO_CALLER=(Join-Path $generation 'shared/codedb-daemon-launch.mjs')}
 if($scenario -eq 'normal') {
  $transfer=Run-Node 'transfer' $environment $project;Save (Join-Path $sr 'transfer-command.json') $transfer
  if($transfer.exit -ne 0 -or -not (Test-Path (Join-Path $sr 'transfer-result.json'))){throw 'Argument/cwd/environment or missing-executable validation failed.'}
 }
 # A detached guard disables this exact synthetic lifecycle after 50s if the observer fails.
 $launcher=Join-Path $generation 'native/win-x64/codedb-daemon-launch.exe'
 $guard=Start-Owned $launcher ('"'+$node+'" "'+$project+'" "'+$fixture+'" guard') $environment $project
 $guard.process.WaitForExit(5000)|Out-Null
 if(-not $guard.process.HasExited -or $guard.process.ExitCode -ne 0){throw 'Fixture expiry guard failed to launch.'}
 $guard.process.Dispose()
 $action=[Guid]::NewGuid().ToString('N');$pk=Sha (Norm $project).ToLowerInvariant();$kk=Sha (Norm $pkg).ToLowerInvariant()
 $ch=Hash $command;$ah=Sha '';$timeout=25000;$ci=Sha "$ch`n$ah`n$timeout";$stage=Sha "$action`n$scenario`n$ci"
 $ar=Join-Path $local ('Rice/CodeDB/manager-actions/'+$action);[void][IO.Directory]::CreateDirectory($ar)
 $ad=@{schema_version=1;storage_layout='compact-v1';managed_by='com.rice.ai-codedb';state='admitted';action_id=$action;stage_id=$stage;terminal_for_action=$true;project_key=$pk;package_key=$kk;project_identity='sha256:'+$pk;package_identity='sha256:'+$kk;effect_class='Observation';authorization_source='PackageMaterializer';command_identity_sha256=$ci;writer_sha256=Hash $writer;project_root=Norm $project;package_root=Norm $pkg;command=@{script_path=Norm $command;script_sha256=$ch;arguments_sha256=$ah;timeout_ms=$timeout;arguments=@()}}
 Save (Join-Path $ar 'action.json') @{schema_version=1;storage_layout='compact-v1';managed_by='com.rice.ai-codedb';action_id=$action;project_key=$pk;package_key=$kk;project_root=$ad.project_root;package_root=$ad.package_root}
 $adpath=Join-Path $ar ($stage.Substring(0,16)+'.admitted.json');Save $adpath $ad
 $terminal=Join-Path $ar ($stage.Substring(0,16)+'.terminal.json')
 $child=Start-Owned $winps ('-NoProfile -ExecutionPolicy Bypass -File "'+$writer+'" -ReceiptPath "'+$adpath+'"') $environment $project
 $sw=[Diagnostics.Stopwatch]::StartNew();$proofs=@{writer=(OwnedAlive $child.process.Id)};$checkpoints=@{};$passed=$false;$failure=$null
 try {
  while($sw.ElapsedMilliseconds -lt 55000) {
   $n=Read (Join-Path $sr 'native-result.json');$receipt=Read $terminal;$state=Read (Join-Path $runtime 'coordinator-state.json')
   foreach($role in @('control','leaf','cli','guard','retainer-ready','provider-identity')) {
    if(-not $proofs.ContainsKey($role)){$r=Read (Join-Path $sr ($role+'.json'));if($r -and $r.token -ceq $token){$p=OwnedAlive $r.pid;if($p){$proofs[$role]=$p}}}
   }
   if($state -and $state.lifecycle_id -ceq $token -and -not $proofs.ContainsKey('coordinator')){$p=OwnedAlive $state.coordinator_pid;if($p){$proofs.coordinator=$p}}
   foreach($kind in @('native','terminal','eof')) {
    $seen=($kind -eq 'native' -and $n) -or ($kind -eq 'terminal' -and $receipt) -or ($kind -eq 'eof' -and $child.process.HasExited -and $child.stdout.IsCompleted -and $child.stderr.IsCompleted)
    if($seen -and -not $checkpoints.ContainsKey($kind)) {
     $live=$null;if($state -and $state.lifecycle_id -ceq $token){$live=OwnedAlive $state.coordinator_pid}
     $checkpoints[$kind]=@{ms=$sw.ElapsedMilliseconds;coordinator=$live;provider_state=$state.provider_state;adapter_state=$state.adapter_state;generation_id=$state.generation_id;lifecycle_id=$state.lifecycle_id}
     Save (Join-Path $sr ($kind+'-checkpoint.json')) $checkpoints[$kind]
    }
   }
   Save (Join-Path $sr 'observation.json') @{checkpoints=$checkpoints;proofs=$proofs;native=$n;terminal=$receipt;elapsed_ms=$sw.ElapsedMilliseconds}
   if($checkpoints.Count -eq 3){break};Start-Sleep -Milliseconds 50
  }
  if($checkpoints.Count -ne 3){throw 'Observer did not obtain both collection results and EOF within bound.'}
  if($scenario -in @('missing','corrupt')) {
   $passed=$n.result.ExitCode -eq 1 -and -not $n.result.OutputDrainIncomplete -and $receipt.exit_code -eq 1 -and -not $receipt.output_drain_incomplete -and -not (Test-Path (Join-Path $runtime 'coordinator-state.json')) -and $n.result.StandardError -match 'launcher is missing or invalid'
  } else {
   $status=Run-Node 'status' $environment $project;Save (Join-Path $sr 'status-command.json') $status
   if($status.exit -ne 0){throw 'Real authenticated coordinator readiness check failed.'}
   $providerIdentity=Read (Join-Path $sr 'provider-identity.json')
   if($providerIdentity.env -cne $project -or $providerIdentity.cwd -cne $project){throw 'Real daemon environment/cwd propagation failed.'}
   $liveChecks=@($checkpoints.Values|Where-Object{$null -ne $_.coordinator -and $_.provider_state -eq 'ready' -and $_.adapter_state -eq 'watching' -and $_.lifecycle_id -ceq $token}).Count -eq 3
   if($scenario -eq 'normal'){$passed=$liveChecks -and $n.result.ExitCode -eq 0 -and -not $n.result.OutputDrainIncomplete -and $receipt.exit_code -eq 0 -and -not $receipt.output_drain_incomplete}
   else {$passed=$liveChecks -and $n.result.OutputDrainIncomplete -and $receipt.exit_code -eq 6 -and $receipt.output_drain_incomplete -and $receipt.elapsed_milliseconds -lt 25000}
  }
 } catch { $failure=$_.Exception.ToString();$passed=$false }
 finally {
  if(Test-Path (Join-Path $runtime 'coordinator-state.json')) { $stop=Run-Node 'stop' $environment $project; if($stop.exit -ne 0){$passed=$false;$failure+=' Cooperative stop failed.'} }
  Write-FixtureText (Join-Path $sr 'guard-stop') $token
  Start-Sleep -Milliseconds 300
  $remaining=@();foreach($proof in $proofs.Values){$live=OwnedAlive $proof.pid;if($live -and $live.start_ticks -eq $proof.start_ticks){$remaining+=$live}}
  if($remaining.Count){$passed=$false;$failure+=' Fixture processes remain.'}
  if($child.stdout.IsCompleted){Write-FixtureText (Join-Path $sr 'writer-stdout.log') $child.stdout.Result};if($child.stderr.IsCompleted){Write-FixtureText (Join-Path $sr 'writer-stderr.log') $child.stderr.Result}
  $row=@{scenario=$scenario;passed=$passed;elapsed_ms=$sw.ElapsedMilliseconds;native=$n;terminal=$receipt;checkpoints=$checkpoints;proofs=$proofs;remaining=$remaining;error=$failure}
  Save (Join-Path $sr 'result.json') $row;$rows+=$row;$allProofs+=@($proofs.Values);Save (Join-Path $root 'results.json') $rows;$child.process.Dispose()
 }
 Write-Output ("[NATIVE_LAUNCH] {0} passed={1} native={2}/{3} manager={4}/{5}" -f $scenario,$passed,$n.result.ExitCode,$n.result.OutputDrainIncomplete,$receipt.exit_code,$receipt.output_drain_incomplete)
 if(-not $passed){break}
}
$audit=@($allProofs|ForEach-Object{$live=OwnedAlive $_.pid;@{pid=$_.pid;start_ticks=$_.start_ticks;present=($null -ne $live -and $live.start_ticks -eq $_.start_ticks)}})
Save (Join-Path $root 'final-process-audit.json') $audit
Save (Join-Path $root 'source-identity.json') @{writer=Hash $writer;writer_source=Hash (Join-Path $package 'Tools~/invoke-codedb-manager-action.ps1');materializer=Hash $source;generation=$manifest.generation_id;generation_manifest=Hash (Join-Path $generation 'generation-manifest.json');test_ps=Hash $PSCommandPath;test_js=Hash $fixture;node_version=(& $node --version);winps=$PSVersionTable.PSVersion.ToString()}
if($rows.Count -ne $Scenarios.Count -or @($rows|Where-Object{-not $_.passed}).Count -or @($audit|Where-Object{$_.present}).Count){throw 'Focused native integration harness failed; inspect retained result.json.'}
