#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$base = '97471f537749eba97171f6756a29112dd552a22b'
$run = Join-Path $repo '.artifacts/tests/s32-delivery-preparation-a'
$candidateRoot = Join-Path $run 'candidate'
$package = Join-Path $candidateRoot 'com.rice.ai-codedb'
$utf8 = [Text.UTF8Encoding]::new($false)
function Hash($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function GitText([string[]]$arguments, [string]$inputText = '') {
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'; $psi.WorkingDirectory = $repo
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = $utf8; $psi.StandardErrorEncoding = $utf8
    $psi.Arguments = ($arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }) -join ' '
    $process = [Diagnostics.Process]::Start($psi)
    $output = $process.StandardOutput.ReadToEndAsync(); $errors = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($inputText); $process.StandardInput.Close(); $process.WaitForExit()
    $code = $process.ExitCode; $process.Dispose()
    if ($code -ne 0) { throw ('git failed: ' + $errors.Result) }
    return $output.Result
}
if ((GitText @('rev-parse','HEAD')).Trim() -cne $base) { throw 'Base drift' }
if ((GitText @('diff','--cached','--name-only')).Trim()) { throw 'Index must remain empty' }
if (Test-Path -LiteralPath $run) { throw 'Preserve previous preparation evidence' }
for ($item = Get-Item -LiteralPath $repo; $item; $item = $item.Parent) {
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected repository rejected' }
}
foreach ($path in @((Join-Path $repo '.artifacts'), (Join-Path $repo '.artifacts/tests'))) {
    if ((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected output rejected' }
}
$accepted = @{}
foreach ($match in [regex]::Matches((Get-Content -Raw (Join-Path $PSScriptRoot 'RESULT.md')), '(?m)^\| ([^|\r\n]+) \| ([a-f0-9]{64}) \|\r?$')) {
    $accepted[$match.Groups[1].Value.Trim()] = $match.Groups[2].Value
}
if ($accepted.Count -ne 14) { throw 'Expected 14 reviewed source files' }
foreach ($entry in $accepted.GetEnumerator()) {
    if ((Hash (Join-Path $repo ('com.rice.ai-codedb/' + $entry.Key))) -cne $entry.Value) { throw ('Accepted source drift: ' + $entry.Key) }
}
foreach ($path in @($candidateRoot, (Join-Path $run 'build'), (Join-Path $run 'tmp'), (Join-Path $run 'local'))) { [void][IO.Directory]::CreateDirectory($path) }
# This archive is only a local baseline source snapshot, never a distributable export.
$null = GitText @('archive','--format=tar',('--output=' + (Join-Path $run 'baseline-source.tar')), $base,'--','com.rice.ai-codedb')
& tar -xf (Join-Path $run 'baseline-source.tar') -C $candidateRoot
if ($LASTEXITCODE -ne 0) { throw 'Baseline extraction failed' }
$baseline = @{}
foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) { $baseline[$file.FullName.Substring($package.Length + 1).Replace('\','/')] = Hash $file.FullName }
$projections = @{
    'Editor/AICodedbProcessRunner.cs' = @{ pattern = 'index\.ExecutionRoute|AICodedbInstallAdmission\.ValidateRoute'; count = 2; excluded = 'incoming timeout/termination changes' }
    'Tools~/invoke-codedb-manager-action.ps1' = @{ pattern = 'RICE_CODEDB_PROJECT_INSTALL_ADMISSION'; count = 1; excluded = 'incoming durable transaction timeout/termination changes' }
    'Tools~/codedb-instance-engine.ps1' = @{ pattern = 'Assert-ProjectInstallExecutionAdmission'; count = 2; excluded = 'incoming repeated-Uninstall idempotence changes' }
    'Documentation~/v0.3.0-p0-host-action-execution.md' = @{ pattern = '#### Project Install command route - 2026-10-17 \(S32\)'; count = 1; excluded = 'incoming historical documentation changes' }
}
foreach ($entry in $accepted.GetEnumerator()) {
    if (!$projections.ContainsKey($entry.Key)) {
        Copy-Item -LiteralPath (Join-Path $repo ('com.rice.ai-codedb/' + $entry.Key)) -Destination (Join-Path $package $entry.Key)
        continue
    }
    $diff = GitText @('diff','--no-ext-diff','--no-color','--unified=3',$base,'--',('com.rice.ai-codedb/' + $entry.Key))
    $hunks = @([regex]::Matches($diff, '(?ms)^@@ [^\n]*\n.*?(?=^@@ |\z)'))
    $selected = @($hunks | Where-Object { $_.Value -match $projections[$entry.Key].pattern })
    if ($selected.Count -ne $projections[$entry.Key].count) { throw ('Projection hunk mismatch: ' + $entry.Key) }
    $patch = $diff.Substring(0, $hunks[0].Index) + (($selected | ForEach-Object { $_.Value }) -join '')
    $relativeCandidate = '.artifacts/tests/s32-delivery-preparation-a/candidate'
    $null = GitText @('apply',('--directory=' + $relativeCandidate),'--check','-') $patch
    $null = GitText @('apply',('--directory=' + $relativeCandidate),'-') $patch
}
$files = @(foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
    $relative = $file.FullName.Substring($package.Length + 1).Replace('\','/')
    $actual = Hash $file.FullName
    if (!$accepted.ContainsKey($relative) -and $actual -cne $baseline[$relative]) { throw ('Non-task drift: ' + $relative) }
    if ($accepted.ContainsKey($relative) -and !$projections.ContainsKey($relative) -and $actual -cne $accepted[$relative]) { throw ('Candidate mismatch: ' + $relative) }
    $projection = if ($projections.ContainsKey($relative)) { $projections[$relative].excluded } else { $null }
    [ordered]@{ path = $relative; sha256 = $actual; reviewed_sha256 = $accepted[$relative]; excluded_incoming = $projection }
})
if ($files.Count -ne ($baseline.Count + 4)) { throw 'Only four new task files are allowed' }
$prior = Get-Content -Raw (Join-Path $repo '.artifacts/tests/s32-install/disposition-b/manifest.json') | ConvertFrom-Json
foreach ($entry in @($prior.tools) + @($prior.references)) { if ((Hash $entry.path) -cne $entry.sha256) { throw ('Tool/reference drift: ' + $entry.path) } }
$manifest = [ordered]@{ base = $base; evidence = 'local precise source candidate; no stage/commit/export/reference switch'; files = $files; tools = $prior.tools; references = $prior.references; driver_sha256 = (Hash $PSCommandPath) }
[IO.File]::WriteAllText((Join-Path $run 'manifest.json'), ($manifest | ConvertTo-Json -Depth 8), $utf8)
function Child($tool, [string[]]$arguments, $log) {
    $psi = [Diagnostics.ProcessStartInfo]::new(); $psi.FileName = $tool; $psi.WorkingDirectory = $run
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.Arguments = ($arguments | ForEach-Object { '"' + $_.Replace('"','\"') + '"' }) -join ' '
    foreach ($key in @('TEMP','TMP')) { $psi.EnvironmentVariables[$key] = Join-Path $run 'tmp' }
    $psi.EnvironmentVariables['LOCALAPPDATA'] = Join-Path $run 'local'
    $process = [Diagnostics.Process]::Start($psi); $output = $process.StandardOutput.ReadToEndAsync(); $errors = $process.StandardError.ReadToEndAsync()
    if (!$process.WaitForExit(120000)) { throw ('Child timeout; no termination; PID=' + $process.Id) }
    $text = $output.Result + [Environment]::NewLine + $errors.Result; $code = $process.ExitCode; $process.Dispose()
    [IO.File]::WriteAllText((Join-Path $run $log), $text, $utf8)
    if ($code -ne 0) { throw ('Child failed: ' + $log + '; preserve evidence') }
}
$build = Join-Path $run 'build'
$template = [IO.File]::ReadAllLines((Join-Path $repo '.artifacts/tests/s31b-r2/build/editor.rsp'))
$common = @('-langversion:9.0','-nologo','-debug:portable') + @($template | Where-Object { $_ -match '^-define:' }) + @($prior.references | ForEach-Object { '-r:"' + $_.path + '"' })
$editorDll = Join-Path $build 'Rice.AICodedb.Editor.dll'; $testsDll = Join-Path $build 'Rice.AICodedb.Editor.Tests.dll'
foreach ($kind in @('editor','tests')) {
    $directory = if ($kind -eq 'editor') { 'Editor' } else { 'Tests/Editor' }
    $outputDll = if ($kind -eq 'editor') { $editorDll } else { $testsDll }
    $extra = if ($kind -eq 'tests') { @('-r:"' + $editorDll + '"') } else { @() }
    $sources = @(Get-ChildItem -LiteralPath (Join-Path $package $directory) -Filter '*.cs' -File | Sort-Object Name | ForEach-Object { '"' + $_.FullName + '"' })
    [IO.File]::WriteAllLines((Join-Path $build ($kind + '.rsp')), [string[]](@('-target:library', ('-out:"' + $outputDll + '"')) + $common + $extra + $sources), $utf8)
}
$dotnet = @($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'dotnet.exe' })[0].path
$csc = @($prior.tools | Where-Object { [IO.Path]::GetFileName($_.path) -eq 'csc.dll' })[0].path
foreach ($kind in @('editor','tests')) { Child $dotnet @($csc,'/noconfig','/nostdlib', ('@' + (Join-Path $build ($kind + '.rsp')))) ($kind + '-compile.log') }
Child (Join-Path $PSHOME 'powershell.exe') @('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $package 'Tests~/test-codedb-package-boundary.ps1'),'-PathProvenanceOnly') 'path-provenance.log'
foreach ($entry in $accepted.GetEnumerator()) { if ((Hash (Join-Path $repo ('com.rice.ai-codedb/' + $entry.Key))) -cne $entry.Value) { throw 'Working source was changed' } }
Write-Output ('PASS local precise candidate: ' + $files.Count + ' files; 14 task files, four projections; compile/path provenance; source/index untouched')
