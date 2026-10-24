param([ValidatePattern('^[a-z0-9-]+$')][string]$Attempt='repair-a')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$package=Join-Path $repo 'com.rice.ai-codedb'
$run=Join-Path $repo ('.artifacts/tests/s32-install/'+$Attempt)
if(Test-Path -LiteralPath $run){throw 'Preserve prior evidence'}
for($item=Get-Item -LiteralPath $repo;$item;$item=$item.Parent){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected repository'}}
for($part=Split-Path -Parent $run;$part.Length -gt $repo.Length;$part=Split-Path -Parent $part){if((Test-Path -LiteralPath $part) -and ((Get-Item -LiteralPath $part).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Redirected output'}}
foreach($part in @($run,(Join-Path $run 'tmp'),(Join-Path $run 'local'))){[void][IO.Directory]::CreateDirectory($part)}
function Hash($path){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
$frozen=Join-Path $repo '.artifacts/tests/s32-install/frozen'
$prior=Get-Content -Raw -LiteralPath (Join-Path $frozen 'manifest.json')|ConvertFrom-Json
foreach($entry in @($prior.tools)+@($prior.references)+@($prior.sources)){if((Hash $entry.path) -cne $entry.sha256){throw ('Frozen input drift '+$entry.path)}}
$mono=@($prior.tools|Where-Object{[IO.Path]::GetFileName($_.path) -eq 'mono.exe'})[0].path
$build=Join-Path $frozen 'b'
function Child($tool,[string[]]$arguments,$log){
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$tool;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.WorkingDirectory=$run;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $psi.Arguments=($arguments|ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' '
 foreach($key in @('TEMP','TMP')){$psi.EnvironmentVariables[$key]=Join-Path $run 'tmp'}
 $psi.EnvironmentVariables['LOCALAPPDATA']=Join-Path $run 'local';$psi.EnvironmentVariables['MONO_PATH']=$build
 $p=[Diagnostics.Process]::Start($psi);$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
 if(!$p.WaitForExit(120000)){throw ('Timeout owned diagnostic PID='+$p.Id+'; no termination')}
 $output=$o.Result+[Environment]::NewLine+$e.Result
 [IO.File]::WriteAllText((Join-Path $run $log),$output,[Text.UTF8Encoding]::new($false));$code=$p.ExitCode;$p.Dispose()
 Write-Output $output
 if($code -ne 0){throw ('Child failure '+$log+' exit='+$code)}
}
$inputs=@('Tools~/codedb-instance-engine.ps1','Tools~/codedb-project-supervisor.mjs','Tools~/invoke-codedb-manager-action.ps1','Tools~/materialize-codedb-host-payload.ps1')|ForEach-Object{@{path=$_;sha256=(Hash (Join-Path $package $_))}}
$manifest=@{head=(& git -C $repo rev-parse HEAD).Trim();evidence='HARNESS repair F1/F2; original guard/lock, mocked inventory/retained closure; frozen C# immediate route/result regression';tools=$prior.tools;references=$prior.references;sources=$inputs;driver_sha256=(Hash $PSCommandPath);admission_driver_sha256=(Hash (Join-Path $PSScriptRoot 'test-admission.ps1'));frozen_build=@(Get-ChildItem -LiteralPath $build -File|ForEach-Object{@{name=$_.Name;sha256=(Hash $_.FullName)}});roots=@{output=$run;tmp=(Join-Path $run 'tmp');local=(Join-Path $run 'local')};network='none';child_roles='PowerShell focused guard, Mono frozen original route/result regression; no Unity/Supervisor/backend'}
[IO.File]::WriteAllText((Join-Path $run 'manifest.json'),($manifest|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
$errors=$null;$tokens=$null;$null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $package 'Tools~/codedb-instance-engine.ps1'),[ref]$tokens,[ref]$errors)
if($errors.Count){throw ($errors|Out-String)}
# Source-backed ordering guards; never execute a Supervisor or managed child.
$writer=[IO.File]::ReadAllText((Join-Path $package 'Tools~/invoke-codedb-manager-action.ps1'))
$supervisor=[IO.File]::ReadAllText((Join-Path $package 'Tools~/codedb-project-supervisor.mjs'))
function Ordered($text,[string[]]$markers){$index=-1;foreach($marker in $markers){$next=$text.IndexOf($marker,$index+1,[StringComparison]::Ordinal);if($next -lt 0){throw ('Missing/out-of-order authority '+$marker)};$index=$next}}
Ordered $writer @('Write-AtomicJson $claimPath $claim','if (-not $child.Start())')
$start=$supervisor.Substring($supervisor.IndexOf('async function runStart(raw)'))
Ordered $start @('await prepareSupervisorStart(context)','const daemon = spawn(')
$daemon=$supervisor.Substring($supervisor.IndexOf('async function runDaemon(raw)'))
Ordered $daemon @('await acquireSupervisorLock(context, ownerEvidence)','const admitMaintenance =','rememberOperation(value);','scheduleRequestQueue();')
$maintenance=$supervisor.Substring($supervisor.IndexOf('const startMaintenance ='))
Ordered $maintenance @('rememberOperation(value);','.then(() => entry.run(value))')
$materializer=$supervisor.Substring($supervisor.IndexOf('async function runMaterializer('))
Ordered $materializer @('prepareOperationChildEvidence(context, operation, "materializer_admitted")','return runChild(')
Write-Output 'PASS source ordering: direct claim and Supervisor owner/operation precede managed child; post-spawn capture does not replace published authority.'
Child (Join-Path $PSHOME 'powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'test-admission.ps1'),'-RunRoot',$run,'-PackageRoot',$package) 'admission-test.log'
Child $mono @((Join-Path $build 'Rice.AICodedb.Editor.Tests.exe'),(Join-Path $run 'f'),$package) 'route-result-regression.log'
