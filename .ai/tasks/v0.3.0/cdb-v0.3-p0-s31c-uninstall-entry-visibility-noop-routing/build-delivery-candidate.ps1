#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$base = '279b442c657676d1adbda7d15151a3770682a674'
$run = Join-Path $repo '.artifacts/tests/s31c-delivery-20261017-a'
$accepted = [ordered]@{
    'Editor/AICodedbManagerWindow.cs' = 'd812bd9ee59a1a9518eebb4a5918b8877e6dc8ca834275fa2107433df936947e'
    'Editor/AICodedbActions.cs' = '9c2133d9790183b22d57415977a9dafa8518c7df9730271785bc5b2fffd4bee2'
    'Tests/Editor/AICodedbManagerUiTests.cs' = 'abf690e017b4343b0dfda8d26b7cd71a4744831cfd52ee5126b954dc7e745fd5'
    'Tests/Editor/AICodedbEditorLifecycleTests.cs' = '634100865e8e7410b6d35cfb4bb6ff526cc383c0d8cdbfbe70e9682f3354662e'
}
function Hash($Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Json($Path, $Value) { [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false)) }
if (Test-Path -LiteralPath $run) { throw 'Frozen output exists' }
foreach ($dir in @($repo, (Join-Path $repo '.artifacts'), (Join-Path $repo '.artifacts/tests'))) {
    if ((Get-Item -LiteralPath $dir).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse output rejected' }
}
if ((& git -C $repo rev-parse HEAD).Trim() -cne $base) { throw 'Base drift' }
foreach ($entry in $accepted.GetEnumerator()) {
    if ((Hash (Join-Path $repo ('com.rice.ai-codedb/' + $entry.Key))) -cne $entry.Value) { throw ('Accepted source drift: ' + $entry.Key) }
}
$prior = Get-Content -LiteralPath (Join-Path $repo '.artifacts/tests/s31c-f1-20261017-a/manifest.json') -Raw | ConvertFrom-Json
foreach ($entry in @($prior.tools) + @($prior.references)) {
    if ((Hash $entry.path) -cne $entry.sha256) { throw ('Tool/reference drift: ' + $entry.path) }
}
$dotnet = @($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'dotnet.exe' })[0].path
$csc = @($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'csc.dll' })[0].path
$build = Join-Path $run 'build'
$candidate = Join-Path $run 'candidate'
foreach ($dir in @($build, $candidate, (Join-Path $run 'tmp'), (Join-Path $run 'local'))) { [void][IO.Directory]::CreateDirectory($dir) }
$tar = Join-Path $run 'base-package.tar'
& git -C $repo archive --format=tar --output=$tar $base -- com.rice.ai-codedb
if ($LASTEXITCODE -ne 0) { throw 'Archive failed' }
& tar -xf $tar -C $candidate
if ($LASTEXITCODE -ne 0) { throw 'Extract failed' }
$package = Join-Path $candidate 'com.rice.ai-codedb'
$baseline = @{}
foreach ($file in Get-ChildItem -LiteralPath $package -File -Recurse) {
    $baseline[$file.FullName.Substring($package.Length + 1).Replace('\','/')] = Hash $file.FullName
}
foreach ($entry in $accepted.GetEnumerator()) {
    Copy-Item -LiteralPath (Join-Path $repo ('com.rice.ai-codedb/' + $entry.Key)) -Destination (Join-Path $package $entry.Key)
}
$bound = @(foreach ($file in Get-ChildItem -LiteralPath $package -File -Recurse) {
    $relative = $file.FullName.Substring($package.Length + 1).Replace('\','/')
    $expected = if ($accepted.Contains($relative)) { $accepted[$relative] } else { $baseline[$relative] }
    $actual = Hash $file.FullName
    if ($actual -cne $expected) { throw ('Candidate drift: ' + $relative) }
    [ordered]@{path=$relative;sha256=$actual}
})
if ($bound.Count -ne $baseline.Count) { throw 'Candidate file count drift' }
$template = [IO.File]::ReadAllLines((Join-Path $repo '.artifacts/tests/s31b-r2/build/editor.rsp'))
$defines = @($template | Where-Object { $_ -match '^-define:' })
$refs = @($prior.references | ForEach-Object { $_.path })
$common = @('-langversion:9.0','-nologo','-debug:portable') + $defines + @($refs | ForEach-Object { '-r:"' + $_ + '"' })
$editor = @(Get-ChildItem -LiteralPath (Join-Path $package 'Editor') -Filter '*.cs' -File | Sort-Object Name)
$tests = @(Get-ChildItem -LiteralPath (Join-Path $package 'Tests/Editor') -Filter '*.cs' -File | Sort-Object Name)
$editorDll = Join-Path $build 'Rice.AICodedb.Editor.dll'
$testDll = Join-Path $build 'Rice.AICodedb.Editor.Tests.dll'
[IO.File]::WriteAllLines((Join-Path $build 'editor.rsp'), [string[]](@('-target:library',('-out:"' + $editorDll + '"')) + $common + @($editor | ForEach-Object { '"' + $_.FullName + '"' })))
[IO.File]::WriteAllLines((Join-Path $build 'tests.rsp'), [string[]](@('-target:library',('-out:"' + $testDll + '"'),('-r:"' + $editorDll + '"')) + $common + @($tests | ForEach-Object { '"' + $_.FullName + '"' })))
Json (Join-Path $run 'manifest.json') ([ordered]@{base=$base;source='HEAD plus exactly four accepted files';files=$bound;tools=$prior.tools;references=$prior.references;driver_sha256=(Hash $PSCommandPath);evidence='compile only; no Unity/native reader/backend execution'})
foreach ($name in @('editor','tests')) {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $dotnet; $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = $run; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Arguments = '"' + $csc + '" /noconfig /nostdlib "@' + (Join-Path $build ($name + '.rsp')) + '"'
    foreach ($key in @('TEMP','TMP')) { $psi.EnvironmentVariables[$key] = Join-Path $run 'tmp' }
    $psi.EnvironmentVariables['LOCALAPPDATA'] = Join-Path $run 'local'
    $child = [Diagnostics.Process]::Start($psi)
    $stdout = $child.StandardOutput.ReadToEndAsync(); $stderr = $child.StandardError.ReadToEndAsync()
    if (!$child.WaitForExit(120000)) { throw ('TIMEOUT owned compiler PID=' + $child.Id + '; no termination') }
    $output = $stdout.Result + [Environment]::NewLine + $stderr.Result
    [IO.File]::WriteAllText((Join-Path $run ($name + '-compile.log')), $output, [Text.UTF8Encoding]::new($false))
    $code = $child.ExitCode; $child.Dispose()
    Write-Output $output
    if ($code -ne 0) { throw ('Compile failed: ' + $name + ' exit=' + $code) }
}
Json (Join-Path $run 'compile-result.json') ([ordered]@{status='PASS';editor_sha256=(Hash $editorDll);tests_sha256=(Hash $testDll);manifest_sha256=(Hash (Join-Path $run 'manifest.json'))})
Write-Output 'PASS exact HEAD-plus-four candidate Editor and Editor tests compile; Unity/native reader/backend NOT RUN'
