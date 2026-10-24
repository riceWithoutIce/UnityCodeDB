param([ValidateSet('a','b','c','f1-a','f1-b','f1-c','delivery-a','f1-delivery-a','delivery-b','f1-delivery-b')][string]$Attempt='a', [string]$DeliveryPackageRoot='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$package=Join-Path $repo 'com.rice.ai-codedb'
if($DeliveryPackageRoot) {
 $package=(Resolve-Path -LiteralPath $DeliveryPackageRoot).Path
 $expected=Join-Path $repo '.artifacts/s31d-uninstall-terminal-97471f5/review/com.rice.ai-codedb'
 if($package -cne $expected) {throw 'Unexpected exact delivery Package'}
 for($ancestor=Get-Item -LiteralPath $package; $ancestor; $ancestor=$ancestor.Parent) {
  if($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) {throw 'Redirected source'}
 }
}
$run=Join-Path $repo ('.artifacts/tests/s31d-uninstall-terminal/attempt-'+$Attempt)
$fixtures=Join-Path $run 'fixtures'
if($DeliveryPackageRoot) {
 $fixtureRelative=$Attempt+'/fixtures'
 if($Attempt -eq 'delivery-b') {$fixtureRelative='d2'}
 if($Attempt -eq 'f1-delivery-b') {$fixtureRelative='f2'}
 $fixtures=Join-Path (Split-Path -Parent $package) ('.artifacts/tests/s31d-uninstall-terminal/'+$fixtureRelative)
 if(Test-Path -LiteralPath $fixtures) {throw 'Preserve previous delivery fixtures'}
}
$build=Join-Path $run 'build'
if (Test-Path -LiteralPath $build) { throw 'Preserve previous evidence' }
foreach($part in @($repo,(Join-Path $repo '.artifacts'),(Join-Path $repo '.artifacts/tests'),(Join-Path $repo '.artifacts/tests/s31d-uninstall-terminal'),$run)) {
 if ((Test-Path -LiteralPath $part) -and ((Get-Item -LiteralPath $part).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Redirected output' }
}
foreach($part in @($build,(Join-Path $run 'tmp'),(Join-Path $run 'local'))) { [void][IO.Directory]::CreateDirectory($part) }
$prior=Get-Content -LiteralPath (Join-Path $repo '.artifacts/tests/s31c-f1-20261017-a/manifest.json') -Raw | ConvertFrom-Json
function Hash($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
foreach($entry in @($prior.tools)+@($prior.references)) { if ((Hash $entry.path) -cne $entry.sha256) { throw ('Input drift '+$entry.path) } }
$mono=@($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'mono.exe' })[0].path
$dotnet=@($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'dotnet.exe' })[0].path
$csc=@($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'csc.dll' })[0].path
$refs=@($prior.references | ForEach-Object {$_.path})
$defines=@([IO.File]::ReadAllLines((Join-Path $repo '.artifacts/tests/s31b-r2/build/editor.rsp')) | Where-Object {$_ -match '^-define:'})
$editor=@(Get-ChildItem -LiteralPath (Join-Path $package 'Editor') -Filter '*.cs' -File | Sort-Object Name)
$tests=@(Get-ChildItem -LiteralPath (Join-Path $package 'Tests/Editor') -Filter '*.cs' -File | Sort-Object Name)
$common=@('-langversion:9.0','-nologo','-debug:portable')+$defines+@($refs | ForEach-Object {'-r:"'+$_+'"'})
$dll=Join-Path $build 'Rice.AICodedb.Editor.dll'
$exe=Join-Path $build 'Rice.AICodedb.Editor.Tests.exe'
$driver=@'
using System;
using System.IO;
using Rice.AI.Codedb.Editor.Tests;
internal static class S31DEntry {
 static int Main(string[] args) { try {
  new AICodedbS31DTerminalTests().SupervisorTerminal_GenericSuccessHasNoBoundProvenance();
  AICodedbS31DTerminalTests.AssertProductionFixtures(args[0]);
  Console.WriteLine("PASS original producer -> C# reader -> normal/reopen Manager resolver -> exact journal release; complete failure preserved; timeout/overflow/drain blocked; wrong operation/owner/request blocked");
  return 0;
 } catch(Exception e) { Console.Error.WriteLine(e); return 1; } }
}
'@
if($Attempt.StartsWith('f1-')) {
 $driver=$driver.Replace('AssertProductionFixtures(args[0])','AssertHandoffRepairFixtures(args[0])').Replace(
  'PASS original producer -> C# reader -> normal/reopen Manager resolver -> exact journal release; complete failure preserved; timeout/overflow/drain blocked; wrong operation/owner/request blocked',
  'PASS F1 original response conversion preserves separate handoff failure warning and unchanged backend success; successful handoff/failure regressions; normal no-second-lookup, reopen unconfirmed without replay, exact journal release and foreign-action refusal')
}
[IO.File]::WriteAllText((Join-Path $build 'focused.cs'),$driver,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines((Join-Path $build 'editor.rsp'),[string[]](@('-target:library',('-out:"'+$dll+'"'))+$common+@($editor|ForEach-Object {'"'+$_.FullName+'"'})))
[IO.File]::WriteAllLines((Join-Path $build 'tests.rsp'),[string[]](@('-target:exe',('-out:"'+$exe+'"'),('-r:"'+$dll+'"'))+$common+@($tests|ForEach-Object {'"'+$_.FullName+'"'})+('"'+(Join-Path $build 'focused.cs')+'"')))
foreach($ref in $refs) { Copy-Item -LiteralPath $ref -Destination (Join-Path $build ([IO.Path]::GetFileName($ref))) }
function Child($tool,[string[]]$arguments,$log) {
 $psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName=$tool;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true
 $psi.WorkingDirectory=$run;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $psi.Arguments=($arguments|ForEach-Object {'"'+$_.Replace('"','\"')+'"'}) -join ' '
 foreach($key in @('TEMP','TMP')) {$psi.EnvironmentVariables[$key]=Join-Path $run 'tmp'}
 $psi.EnvironmentVariables['LOCALAPPDATA']=Join-Path $run 'local';$psi.EnvironmentVariables['MONO_PATH']=$build
 $p=[Diagnostics.Process]::Start($psi);$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync()
 if(!$p.WaitForExit(120000)){throw ('Timeout owned compiler/test PID='+$p.Id+'; no termination')}
 $output=$o.Result+[Environment]::NewLine+$e.Result
 [IO.File]::WriteAllText((Join-Path $run $log),$output,[Text.UTF8Encoding]::new($false));$code=$p.ExitCode;$p.Dispose()
 Write-Output $output
 if($code -ne 0){throw ('Child failure '+$log+' exit='+$code)}
}
$manifest=[ordered]@{head=(& git -C $repo rev-parse HEAD).Trim();evidence='CONTRACT_ISOLATED producer/reader; Unity not started';tools=$prior.tools;references=$prior.references;driver_sha256=(Hash $PSCommandPath);sources=@(($editor+$tests)|ForEach-Object {@{path=$_.FullName;sha256=(Hash $_.FullName)}});roots=@{package=$package;output=$run;tmp=(Join-Path $run 'tmp');local=(Join-Path $run 'local');fixtures=$fixtures};network='none';child_roles='existing compiler and mono; delivery producer-only Node entry; no Supervisor/backend'}
if($DeliveryPackageRoot) {
 $node=(Get-Command node.exe -ErrorAction Stop).Source
 $producer=Join-Path $package 'Tests~/test-codedb-project-supervisor.mjs'
 $manifest.tools=@($manifest.tools)+@(@{path=$node;sha256=(Hash $node)})
 $manifest.producer=@{path=$producer;sha256=(Hash $producer);production_source_sha256=(Hash (Join-Path $package 'Tools~/codedb-project-supervisor.mjs'))}
 $arguments=@($producer,'--terminal-session-fixture',$fixtures)
 if($Attempt.StartsWith('f1-')) {$arguments+=,'success,failure'}
 Child $node $arguments 'producer.log'
}
[IO.File]::WriteAllText((Join-Path $run 'manifest.json'),($manifest|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
Child $dotnet @($csc,'/noconfig','/nostdlib',('@'+(Join-Path $build 'editor.rsp'))) 'editor-compile.log'
Child $dotnet @($csc,'/noconfig','/nostdlib',('@'+(Join-Path $build 'tests.rsp'))) 'tests-compile.log'
Child $mono @($exe,$fixtures) 'focused-test.log'
