param([ValidatePattern('^[a-z0-9-]+$')][string]$Attempt='a', [string]$SourcePackageRoot='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$package=if($SourcePackageRoot){[IO.Path]::GetFullPath($SourcePackageRoot)}else{Join-Path $repo 'com.rice.ai-codedb'}
if(-not $package.StartsWith($repo+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Package must remain repository-local'}
for($item=Get-Item -LiteralPath $package;$item;$item=$item.Parent){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected Package'}}
$run=Join-Path (Split-Path -Parent $package) ('.artifacts/tests/s32-install/'+$Attempt)
if(Test-Path -LiteralPath $run){throw 'Preserve previous evidence'}
for($item=Get-Item -LiteralPath $repo;$item;$item=$item.Parent){if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected repository'}}
$ancestor=Split-Path -Parent $run
while($ancestor.Length -gt $repo.Length){if((Test-Path -LiteralPath $ancestor) -and ((Get-Item -LiteralPath $ancestor).Attributes -band [IO.FileAttributes]::ReparsePoint)){throw 'Redirected output'};$ancestor=Split-Path -Parent $ancestor}
$build=Join-Path $run 'b'
foreach($part in @($build,(Join-Path $run 'tmp'),(Join-Path $run 'local'))){[void][IO.Directory]::CreateDirectory($part)}
$prior=Get-Content -LiteralPath (Join-Path $repo '.artifacts/tests/s31c-f1-20261017-a/manifest.json') -Raw|ConvertFrom-Json
function Hash($p){(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()}
foreach($entry in @($prior.tools)+@($prior.references)){if((Hash $entry.path) -cne $entry.sha256){throw ('Input drift '+$entry.path)}}
$mono=@($prior.tools|Where-Object{[IO.Path]::GetFileName($_.path) -eq 'mono.exe'})[0].path
$dotnet=@($prior.tools|Where-Object{[IO.Path]::GetFileName($_.path) -eq 'dotnet.exe'})[0].path
$csc=@($prior.tools|Where-Object{[IO.Path]::GetFileName($_.path) -eq 'csc.dll'})[0].path
$refs=@($prior.references|ForEach-Object{$_.path})
$defines=@([IO.File]::ReadAllLines((Join-Path $repo '.artifacts/tests/s31b-r2/build/editor.rsp'))|Where-Object{$_ -match '^-define:'})
$editor=@(Get-ChildItem -LiteralPath (Join-Path $package 'Editor') -Filter '*.cs' -File|Sort-Object Name)
$tests=@(Get-ChildItem -LiteralPath (Join-Path $package 'Tests/Editor') -Filter '*.cs' -File|Sort-Object Name)
$common=@('-langversion:9.0','-nologo','-debug:portable')+$defines+@($refs|ForEach-Object{'-r:"'+$_+'"'})
$dll=Join-Path $build 'Rice.AICodedb.Editor.dll'
$exe=Join-Path $build 'Rice.AICodedb.Editor.Tests.exe'
$driver=@'
using System;
using Rice.AI.Codedb.Editor.Tests;
internal static class S32Entry {
 static int Main(string[] args) {try {
  AICodedbS32InstallTests.AssertOriginalWriter(args[0],args[1]);
  var tests = new AICodedbProjectSettingsTests();
  tests.InstallEntryAndManager_RequireConfirmedCompleteSuccess(1,"FAILED","PENDING",true,false);
  tests.InstallEntryAndManager_RequireConfirmedCompleteSuccess(0,"UNKNOWN","PENDING",true,false);
  tests.InstallEntryAndManager_RequireConfirmedCompleteSuccess(0,"INSTALLED","PENDING",true,false);
  tests.InstallEntryAndManager_RequireConfirmedCompleteSuccess(0,"INSTALLED","COMPLETE",false,false);
  tests.InstallEntryAndManager_RequireConfirmedCompleteSuccess(0,"INSTALLED","COMPLETE",true,true);
  tests.InstallEntry_MissingOrMalformedResultDoesNotReconcile();
  Console.WriteLine("PASS original writer/materializer refusal -> reader -> offline Manager reopen and exact release; repeated admission, missing terminal and competing map remain blocked. HARNESS: first/retained topology, no successful installation or Provider.");
  return 0;
 } catch(Exception e) {Console.Error.WriteLine(e);return 1;} }
}
'@
[IO.File]::WriteAllText((Join-Path $build 'entry.cs'),$driver,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines((Join-Path $build 'editor.rsp'),[string[]](@('-target:library',('-out:"'+$dll+'"'))+$common+@($editor|ForEach-Object{'"'+$_.FullName+'"'})))
[IO.File]::WriteAllLines((Join-Path $build 'tests.rsp'),[string[]](@('-target:exe',('-out:"'+$exe+'"'),('-r:"'+$dll+'"'))+$common+@($tests|ForEach-Object{'"'+$_.FullName+'"'})+('"'+(Join-Path $build 'entry.cs')+'"')))
foreach($ref in $refs){Copy-Item -LiteralPath $ref -Destination (Join-Path $build ([IO.Path]::GetFileName($ref)))}
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
$manifest=[ordered]@{head=(& git -C $repo rev-parse HEAD).Trim();evidence='HARNESS; original C# compilation, original writer/materializer negative path and offline reader';tools=$prior.tools;references=$prior.references;driver_sha256=(Hash $PSCommandPath);sources=@(($editor+$tests)|ForEach-Object{@{path=$_.FullName;sha256=(Hash $_.FullName)}});roots=@{output=$run;tmp=(Join-Path $run 'tmp');local=(Join-Path $run 'local');fixtures=(Join-Path $run 'f')};network='none';child_roles='existing compiler, Mono, bounded PowerShell writer/materializer preflight refusal; no Unity/Supervisor/backend'}
[IO.File]::WriteAllText((Join-Path $run 'manifest.json'),($manifest|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
foreach($relative in @('Tools~/codedb-instance-engine.ps1','Tools~/invoke-codedb-manager-action.ps1')){
 $parseErrors=$null;$tokens=$null;$null=[Management.Automation.Language.Parser]::ParseFile((Join-Path $package $relative),[ref]$tokens,[ref]$parseErrors)
 if($parseErrors.Count){throw ($parseErrors|Out-String)}
}
Child $dotnet @($csc,'/noconfig','/nostdlib',('@'+(Join-Path $build 'editor.rsp'))) 'editor-compile.log'
Child $dotnet @($csc,'/noconfig','/nostdlib',('@'+(Join-Path $build 'tests.rsp'))) 'tests-compile.log'
Child $mono @($exe,(Join-Path $run 'f'),$package) 'focused-test.log'
Child (Join-Path $PSHOME 'powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'test-admission.ps1'),'-RunRoot',$run,'-PackageRoot',$package) 'admission-test.log'
