#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$base = 'cc49c95e84945308385f64640963716d93d070ea'
$run = Join-Path $repo '.artifacts/tests/s31d-delivery-preparation-a'
$package = Join-Path $run 'candidate/com.rice.ai-codedb'
$utf8 = [Text.UTF8Encoding]::new($false)
function Hash($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function Json($p,$v) { [IO.File]::WriteAllText($p,($v | ConvertTo-Json -Depth 8),$utf8) }
function LF($text) { $text.Replace("`r`n","`n") }
if (Test-Path -LiteralPath $run) { throw 'Preserve existing preparation evidence' }
foreach ($p in @($repo,(Join-Path $repo '.artifacts'),(Join-Path $repo '.artifacts/tests'))) {
    if ((Get-Item -LiteralPath $p).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected output rejected' }
}
if ((& git -C $repo rev-parse HEAD).Trim() -cne $base) { throw 'Base drift' }
$result = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'RESULT.md')
$result = $result.Substring($result.IndexOf('### Final F1 source identity'))
$accepted = [ordered]@{}
foreach ($m in [regex]::Matches($result,'(?m)^\| ((?:Editor|Tools~|Tests|Tests~|Documentation~)/[^|]+?) \| ([a-f0-9]{64}) \|')) {
    $rel = $m.Groups[1].Value -replace ' \(unchanged\)$',''
    if ((Hash (Join-Path $repo ('com.rice.ai-codedb/'+$rel))) -cne $m.Groups[2].Value) { throw ('Accepted source drift: '+$rel) }
    $accepted[$rel] = $m.Groups[2].Value
}
if ($accepted.Count -ne 10) { throw 'Expected exactly ten reviewed files' }
$prior = Get-Content -Raw -LiteralPath (Join-Path $repo '.artifacts/tests/s31c-f1-20261017-a/manifest.json') | ConvertFrom-Json
foreach ($entry in @($prior.tools)+@($prior.references)) {
    if ((Hash $entry.path) -cne $entry.sha256) { throw ('Tool/reference drift: '+$entry.path) }
}
foreach ($dir in @((Join-Path $run 'candidate'),(Join-Path $run 'build'),(Join-Path $run 'tmp'),(Join-Path $run 'local'))) {
    [void][IO.Directory]::CreateDirectory($dir)
}
$tar = Join-Path $run 'baseline-source.tar'
& git -C $repo archive --format=tar --output=$tar $base -- com.rice.ai-codedb
if ($LASTEXITCODE -ne 0) { throw 'Baseline source archive failed' }
& tar -xf $tar -C (Join-Path $run 'candidate')
if ($LASTEXITCODE -ne 0) { throw 'Baseline source extraction failed' }
$baseline = @{}
foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
    $baseline[$file.FullName.Substring($package.Length+1).Replace('\','/')] = Hash $file.FullName
}
$runnerRel = 'Editor/AICodedbProcessRunner.cs'
$docRel = 'Documentation~/v0.3.0-p0-host-action-execution.md'
$runnerMarker = '    internal static class AICodedbProcessRunner'
$docMarker = '### Current Uninstall terminal/session closure - 2026-10-17'
$projected = @{}
foreach ($entry in $accepted.GetEnumerator()) {
    $sourcePath = Join-Path $repo ('com.rice.ai-codedb/'+$entry.Key)
    $destination = Join-Path $package $entry.Key
    if ($entry.Key -eq $runnerRel) {
        $incoming = LF ([IO.File]::ReadAllText($sourcePath))
        $original = LF ([IO.File]::ReadAllText($destination))
        if ($incoming.IndexOf($runnerMarker) -lt 0 -or $original.IndexOf($runnerMarker) -lt 0) { throw 'Runner type boundary missing' }
        $prefix = $incoming.Substring(0,$incoming.IndexOf($runnerMarker))
        $tail = $original.Substring($original.IndexOf($runnerMarker))
        [IO.File]::WriteAllText($destination,($prefix+$tail),$utf8)
        $projected[$entry.Key] = 'reviewed command-result types + HEAD runner body; excludes incoming timeout hunks'
    } elseif ($entry.Key -eq $docRel) {
        $incoming = LF ([IO.File]::ReadAllText($sourcePath))
        $original = LF ([IO.File]::ReadAllText($destination))
        if ($incoming.IndexOf($docMarker) -lt 0 -or $original.Contains($docMarker)) { throw 'Contract append boundary invalid' }
        [IO.File]::WriteAllText($destination,($original.TrimEnd()+"`n`n"+$incoming.Substring($incoming.IndexOf($docMarker))),$utf8)
        $projected[$entry.Key] = 'HEAD contract + reviewed S31-D/F1 append only; excludes historical dirty sections'
    } else {
        Copy-Item -LiteralPath $sourcePath -Destination $destination
    }
}
$files = @(foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
    $rel = $file.FullName.Substring($package.Length+1).Replace('\','/')
    $actual = Hash $file.FullName
    if (!$accepted.Contains($rel) -and $actual -cne $baseline[$rel]) { throw ('Unrelated candidate drift: '+$rel) }
    if ($accepted.Contains($rel) -and !$projected.ContainsKey($rel) -and $actual -cne $accepted[$rel]) { throw ('Candidate source drift: '+$rel) }
    [ordered]@{path=$rel;sha256=$actual;reviewed_sha256=$accepted[$rel];projection=$projected[$rel]}
})
if ($files.Count -ne ($baseline.Count+2)) { throw 'Only two new helper files are allowed' }
$build = Join-Path $run 'build'
$template = [IO.File]::ReadAllLines((Join-Path $repo '.artifacts/tests/s31b-r2/build/editor.rsp'))
$defines = @($template | Where-Object { $_ -match '^-define:' })
$refs = @($prior.references | ForEach-Object {$_.path})
$common = @('-langversion:9.0','-nologo','-debug:portable')+$defines+@($refs|ForEach-Object {'-r:"'+$_+'"'})
$editor = @(Get-ChildItem -LiteralPath (Join-Path $package 'Editor') -Filter '*.cs' -File | Sort-Object Name)
$tests = @(Get-ChildItem -LiteralPath (Join-Path $package 'Tests/Editor') -Filter '*.cs' -File | Sort-Object Name)
$editorDll = Join-Path $build 'Rice.AICodedb.Editor.dll'
$testDll = Join-Path $build 'Rice.AICodedb.Editor.Tests.dll'
[IO.File]::WriteAllLines((Join-Path $build 'editor.rsp'),[string[]](@('-target:library',('-out:"'+$editorDll+'"'))+$common+@($editor|ForEach-Object {'"'+$_.FullName+'"'})))
[IO.File]::WriteAllLines((Join-Path $build 'tests.rsp'),[string[]](@('-target:library',('-out:"'+$testDll+'"'),('-r:"'+$editorDll+'"'))+$common+@($tests|ForEach-Object {'"'+$_.FullName+'"'})))
Json (Join-Path $run 'manifest.json') ([ordered]@{base=$base;source='HEAD plus eight reviewed files and two task-only projections';files=$files;tools=$prior.tools;references=$prior.references;driver_sha256=(Hash $PSCommandPath);evidence='candidate compile and path provenance only; no package export/Unity/backend'})
$dotnet = @($prior.tools|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'dotnet.exe'})[0].path
$csc = @($prior.tools|Where-Object {[IO.Path]::GetFileName($_.path) -eq 'csc.dll'})[0].path
foreach ($name in @('editor','tests')) {
    $psi = [Diagnostics.ProcessStartInfo]::new(); $psi.FileName=$dotnet; $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
    $psi.WorkingDirectory=$run; $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
    $psi.Arguments='"'+$csc+'" /noconfig /nostdlib "@'+(Join-Path $build ($name+'.rsp'))+'"'
    foreach ($key in @('TEMP','TMP')) {$psi.EnvironmentVariables[$key]=Join-Path $run 'tmp'}
    $psi.EnvironmentVariables['LOCALAPPDATA']=Join-Path $run 'local'
    $p=[Diagnostics.Process]::Start($psi); $o=$p.StandardOutput.ReadToEndAsync(); $e=$p.StandardError.ReadToEndAsync()
    if (!$p.WaitForExit(120000)) { throw ('Compiler timeout PID='+$p.Id+'; no termination') }
    $output=$o.Result+[Environment]::NewLine+$e.Result
    [IO.File]::WriteAllText((Join-Path $run ($name+'-compile.log')),$output,$utf8)
    $code=$p.ExitCode; $p.Dispose(); Write-Output $output
    if ($code -ne 0) { throw ('Candidate compile failed: '+$name+' exit='+$code) }
}
Json (Join-Path $run 'compile-result.json') ([ordered]@{status='PASS';manifest_sha256=(Hash (Join-Path $run 'manifest.json'));editor_sha256=(Hash $editorDll);tests_sha256=(Hash $testDll)})
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $package 'Tests~/test-codedb-package-boundary.ps1') -PathProvenanceOnly *> (Join-Path $run 'path-provenance.log')
if ($LASTEXITCODE -ne 0) { throw 'Candidate path provenance failed; preserve evidence' }
Write-Output 'PASS exact task-only candidate compile and path provenance; no commit/export/reference switch/Unity/backend'
