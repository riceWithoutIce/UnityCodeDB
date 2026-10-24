param([ValidateSet('Build','Test')][string]$Stage = 'Build')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$run = Join-Path $repo '.artifacts/tests/s31c-f1-20261017-a'
if (!$run.StartsWith(($repo.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) { throw 'Output containment' }
foreach ($dir in @($repo, (Join-Path $repo '.artifacts'), (Join-Path $repo '.artifacts/tests'), $run)) {
    if ((Test-Path -LiteralPath $dir) -and ((Get-Item -LiteralPath $dir).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Reparse output rejected' }
}
$build = Join-Path $run 'build'
$unity = 'F:/unity/unity-2022.3.62f3/Editor/Data'
$mono = Join-Path $unity 'MonoBleedingEdge/bin/mono.exe'
$dotnet = Join-Path $unity 'NetCoreRuntime/dotnet.exe'
$csc = Join-Path $unity 'DotNetSdkRoslyn/csc.dll'
function Hash($Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function SaveJson($Path, $Value) { [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false)) }
function Child($Exe, [string[]]$Arguments, $Log) {
    $psi = [Diagnostics.ProcessStartInfo]::new(); $psi.FileName = $Exe; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $run; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Arguments = ($Arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }) -join ' '
    foreach ($pair in @{ TEMP=(Join-Path $run 'tmp'); TMP=(Join-Path $run 'tmp'); LOCALAPPDATA=(Join-Path $run 'local'); MONO_PATH=$build }.GetEnumerator()) { $psi.EnvironmentVariables[$pair.Key] = [string]$pair.Value }
    $p = [Diagnostics.Process]::Start($psi); $stdout = $p.StandardOutput.ReadToEndAsync(); $stderr = $p.StandardError.ReadToEndAsync()
    if (!$p.WaitForExit(120000)) { throw ('TIMEOUT: owned compile/test child PID=' + $p.Id + '; no force termination') }
    $output = $stdout.Result + [Environment]::NewLine + $stderr.Result
    [IO.File]::WriteAllText((Join-Path $run $Log), $output, [Text.UTF8Encoding]::new($false))
    $code = $p.ExitCode; $p.Dispose(); $output
    if ($code -ne 0) { throw ('Child exit ' + $code + ': ' + $Log) }
}
if ($Stage -eq 'Build') {
    if (Test-Path -LiteralPath $run) { throw 'Frozen output exists; do not overwrite evidence' }
    foreach ($dir in @($build, (Join-Path $run 'tmp'), (Join-Path $run 'local'))) { [void][IO.Directory]::CreateDirectory($dir) }
    $template = [IO.File]::ReadAllLines((Join-Path $repo '.artifacts/tests/s31b-r2/build/editor.rsp'))
    $refs = @($template | Where-Object { $_ -match '^-r:"(.+)"$' } | ForEach-Object { $_.Substring(4).TrimEnd('"') })
    $defines = @($template | Where-Object { $_ -match '^-define:' })
    $refs += Join-Path $repo 'UnityValidationProject/Library/PackageCache/com.unity.ext.nunit@1.0.6/net35/unity-custom/nunit.framework.dll'
    $refs += Join-Path $repo 'UnityValidationProject/Library/ScriptAssemblies/UnityEditor.TestRunner.dll'
    $refs += Join-Path $repo 'UnityValidationProject/Library/ScriptAssemblies/UnityEngine.TestRunner.dll'
    foreach ($ref in $refs) { if (!(Test-Path -LiteralPath $ref)) { throw ('Missing existing reference: ' + $ref) } }
    $editor = @(Get-ChildItem -LiteralPath (Join-Path $repo 'com.rice.ai-codedb/Editor') -Filter '*.cs' -File | Sort-Object Name)
    $tests = @(Get-ChildItem -LiteralPath (Join-Path $repo 'com.rice.ai-codedb/Tests/Editor') -Filter '*.cs' -File | Sort-Object Name)
    $editorDll = Join-Path $build 'Rice.AICodedb.Editor.dll'
    $common = @('-langversion:9.0','-nologo','-debug:portable') + $defines + @($refs | ForEach-Object { '-r:"' + $_ + '"' })
    [IO.File]::WriteAllLines((Join-Path $build 'editor.rsp'), [string[]](@('-target:library',('-out:"' + $editorDll + '"')) + $common + @($editor | ForEach-Object { '"' + $_.FullName + '"' })))
    $driver = @'
using System;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using Rice.AI.Codedb.Editor;
using Rice.AI.Codedb.Editor.Tests;
using UnityEngine;
using NUnit.Framework;
internal static class S31CEntry {
    static int Main(string[] args) {
        try {
            var root = Path.GetFullPath(args[0]);
            if (!File.Exists(Path.Combine(root, "manifest.json"))) throw new Exception("Missing manifest");
            var ui = new AICodedbProjectSettingsTests();
            foreach (AICodedbCurrentInstanceState current in Enum.GetValues(typeof(AICodedbCurrentInstanceState)))
                ui.UninstallEntry_CompleteDesiredStateAlwaysDefersToExistingBackend(current);
            Console.WriteLine("PASS F1: COMPLETE defers to original backend for Missing/Current/TrustedPrevious/ObsoleteReinstallRequired/Invalid (5 cases)");
            ui.UninstallEntry_FreshNoOpAndInvalidRefusalRemainLocalWithoutTerminalEvidence();
            Console.WriteLine("PASS F1 adjacent regression: canonical NotIntegrated typed result remains local no-op; Invalid remains local refusal, no writer terminal");
            Console.WriteLine("LIMIT: pure original action-classification component only; canonical reader, durable session, Unity and actual backend NOT RUN; frozen native path not retried");
            return 0;
        } catch(Exception e) { Console.Error.WriteLine(e); return 1; }
    }
}
'@
    [IO.File]::WriteAllText((Join-Path $build 'focused.cs'), $driver, [Text.UTF8Encoding]::new($false))
    $testRsp = @('-target:exe',('-out:"' + (Join-Path $build 'Rice.AICodedb.Editor.Tests.exe') + '"'),('-r:"' + $editorDll + '"')) + $common
    $testRsp += @($tests | ForEach-Object { '"' + $_.FullName + '"' }) + ('"' + (Join-Path $build 'focused.cs') + '"')
    [IO.File]::WriteAllLines((Join-Path $build 'tests.rsp'), [string[]]$testRsp)
    $manifest = [ordered]@{ task='s31c-uninstall-entry'; head='279b442c657676d1adbda7d15151a3770682a674'; evidence_level='HARNESS / focused original-source contracts'; environment=@{tmp='tmp';local='local';network='none';unity='not started'}; source_files=@(($editor + $tests) | ForEach-Object { @{path=$_.FullName;sha256=(Hash $_.FullName)} }); references=@($refs | ForEach-Object { @{path=$_;sha256=(Hash $_)} }); tools=@($mono,$dotnet,$csc | ForEach-Object { @{path=$_;sha256=(Hash $_)} }); driver_sha256=(Hash $PSCommandPath) }
    SaveJson (Join-Path $run 'manifest.json') $manifest
    foreach ($ref in $refs) { Copy-Item -LiteralPath $ref -Destination (Join-Path $build ([IO.Path]::GetFileName($ref))) }
    Child $dotnet @($csc,'/noconfig','/nostdlib',('@' + (Join-Path $build 'editor.rsp'))) 'editor-compile.log'
    Child $dotnet @($csc,'/noconfig','/nostdlib',('@' + (Join-Path $build 'tests.rsp'))) 'tests-compile.log'
    'PASS original Editor and Editor test source compilation'
} else {
    $manifest = Get-Content -Raw -LiteralPath (Join-Path $run 'manifest.json') | ConvertFrom-Json
    foreach ($entry in @($manifest.source_files) + @($manifest.references) + @($manifest.tools)) { if ((Hash $entry.path) -cne $entry.sha256) { throw ('Frozen input drift: ' + $entry.path) } }
    if ((Hash $PSCommandPath) -cne $manifest.driver_sha256) { throw 'Driver drift' }
    Child $mono @((Join-Path $build 'Rice.AICodedb.Editor.Tests.exe'), $run) 'focused-test.log'
}
