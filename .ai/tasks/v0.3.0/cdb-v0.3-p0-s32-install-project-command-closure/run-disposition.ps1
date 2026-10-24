param([ValidatePattern('^[a-z0-9-]+$')][string]$Attempt='disposition-a', [string]$SourcePackageRoot='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$package=if($SourcePackageRoot){[IO.Path]::GetFullPath($SourcePackageRoot)}else{Join-Path $repo 'com.rice.ai-codedb'}
if(-not $package.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Package must remain repository-local'}
for($item=Get-Item -LiteralPath $package;$item;$item=$item.Parent){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected Package'}}
$run=Join-Path (Split-Path -Parent $package) ('.artifacts/tests/s32-install/'+$Attempt)
if(Test-Path -LiteralPath $run){throw 'Preserve prior evidence'}
for($item=Get-Item -LiteralPath $repo;$item;$item=$item.Parent){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected repository'}}
for($part=Split-Path -Parent $run;$part.Length -gt $repo.Length;$part=Split-Path -Parent $part){if((Test-Path -LiteralPath $part) -and ((Get-Item -LiteralPath $part).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Redirected output'}}
foreach($part in @($run,(Join-Path $run 'tmp'),(Join-Path $run 'local'))){[void][IO.Directory]::CreateDirectory($part)}
function Hash($path){(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}
$prior=Get-Content -Raw -LiteralPath (Join-Path $repo '.artifacts/tests/s31d-uninstall-terminal/attempt-f1-delivery-b/manifest.json')|ConvertFrom-Json
foreach($entry in @($prior.tools)+@($prior.references)){if((Hash $entry.path) -cne $entry.sha256){throw ('Frozen tool/reference drift '+$entry.path)}}
$node=@($prior.tools|Where-Object{[IO.Path]::GetFileName($_.path) -eq 'node.exe'})[0].path
$sources=@('Tools~/codedb-project-supervisor.mjs','Tools~/codedb-instance-engine.ps1','Tools~/materialize-codedb-host-payload.ps1','Tests~/test-codedb-project-supervisor.mjs')|ForEach-Object{@{path=$_;sha256=(Hash (Join-Path $package $_))}}
$record=@{head=(& git -C $repo rev-parse HEAD).Trim();evidence='HARNESS original producer/serializer -> actual PowerShell reader; mocked status/process/retained inputs';tools=$prior.tools;references=$prior.references;sources=$sources;driver_sha256=(Hash $PSCommandPath);fixture_driver_sha256=(Hash (Join-Path $PSScriptRoot 'test-disposition.ps1'));setup_driver_sha256=(Hash (Join-Path $PSScriptRoot 'test-admission.ps1'));roots=@{output=$run;tmp=(Join-Path $run 'tmp');local=(Join-Path $run 'local')};network='none';child_roles='Node producer VM with spawn forbidden; PowerShell locked reader fixture; no Unity/Supervisor/backend'}
[IO.File]::WriteAllText((Join-Path $run 'manifest.json'),($record|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($false))
function Child($tool,[string[]]$arguments,$log){
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$tool;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.WorkingDirectory=$run;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $psi.Arguments=($arguments|ForEach-Object{'"'+$_.Replace('"','\"')+'"'}) -join ' '
 foreach($key in @('TEMP','TMP')){$psi.EnvironmentVariables[$key]=Join-Path $run 'tmp'}
 $psi.EnvironmentVariables['LOCALAPPDATA']=Join-Path $run 'local'
 $p=[Diagnostics.Process]::Start($psi);$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
 if(!$p.WaitForExit(120000)){throw ('Timeout owned diagnostic PID='+$p.Id+'; no termination')}
 $output=$o.Result+[Environment]::NewLine+$e.Result
 [IO.File]::WriteAllText((Join-Path $run $log),$output,[Text.UTF8Encoding]::new($false));$code=$p.ExitCode;$p.Dispose()
 Write-Output $output;if($code -ne 0){throw ('Child failure '+$log+' exit='+$code)}
}
foreach($relative in @('Tools~/codedb-instance-engine.ps1','Tools~/materialize-codedb-host-payload.ps1')){
 $errors=$null;$tokens=$null;$null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $package $relative),[ref]$tokens,[ref]$errors)
 if($errors.Count){throw ($errors|Out-String)}
}
Child $node @('--check',(Join-Path $package 'Tools~/codedb-project-supervisor.mjs')) 'producer-syntax.log'
Child $node @((Join-Path $package 'Tests~/test-codedb-project-supervisor.mjs'),'--s32-disposition-fixture',(Join-Path $run 'producer')) 'producer.log'
Child (Join-Path $PSHOME 'powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'test-disposition.ps1'),'-RunRoot',$run,'-PackageRoot',$package) 'reader.log'
