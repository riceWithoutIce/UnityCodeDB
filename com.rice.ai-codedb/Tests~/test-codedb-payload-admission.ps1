#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$PackageRoot = '',
    [string]$EvidenceRoot = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($PackageRoot)) { $PackageRoot = Join-Path $PSScriptRoot '..' }
$package = [IO.Path]::GetFullPath($PackageRoot)
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $repo '.artifacts/tests'))
if ([string]::IsNullOrWhiteSpace($EvidenceRoot)) {
    $EvidenceRoot = Join-Path $testRoot ('pa41-admission-' + [Guid]::NewGuid().ToString('N'))
}
$evidence = [IO.Path]::GetFullPath($EvidenceRoot)
if (-not $evidence.StartsWith($testRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
    [IO.Path]::GetFileName($evidence) -notlike 'pa41*' -or (Test-Path -LiteralPath $evidence)) {
    throw 'EvidenceRoot must be a fresh repository-local .artifacts/tests/pa41* directory.'
}
[IO.Directory]::CreateDirectory($evidence) | Out-Null
$utf8 = New-Object Text.UTF8Encoding($false)
function Assert-Test([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Save-Text([string]$Path, [string]$Text) { [IO.File]::WriteAllText($Path, $Text, $utf8) }
function Snapshot([string]$Root) {
    (@(Get-ChildItem -LiteralPath $Root -Recurse -Force | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($Root.Length).Replace('\', '/')
        if ($_.PSIsContainer) { 'D ' + $relative }
        else { 'F {0} {1}' -f $relative, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    }) -join "`n")
}
function Invoke-PowerShell([string]$Name, [string]$Arguments) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = 'powershell.exe'
    $start.Arguments = '-NoProfile -ExecutionPolicy Bypass ' + $Arguments
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [Diagnostics.Process]::Start($start)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $result = [pscustomobject]@{ ExitCode = $process.ExitCode; Out = $stdout.Result; Error = $stderr.Result }
    $process.Dispose()
    Save-Text (Join-Path $evidence ($Name + '.stdout.txt')) $result.Out
    Save-Text (Join-Path $evidence ($Name + '.stderr.txt')) $result.Error
    Save-Text (Join-Path $evidence ($Name + '.exit.txt')) ([string]$result.ExitCode)
    Save-Text (Join-Path $evidence ($Name + '.command.txt')) ('powershell.exe -NoProfile -ExecutionPolicy Bypass ' + $Arguments)
    return $result
}
function Invoke-Reader([string]$Name, [string]$Root) {
    $projection = Join-Path $evidence ($Name + '-logical-project')
    $before = Snapshot $Root
    Save-Text (Join-Path $evidence ($Name + '.package-before.txt')) $before
    $result = Invoke-PowerShell $Name ('-File "{0}" -Action ValidatePayload -ProjectRoot "{1}" -PayloadRoot "{2}"' -f
        (Join-Path $Root 'Tools~/materialize-codedb-host-payload.ps1'), $projection, (Join-Path $Root 'Payload~'))
    Assert-Test (-not (Test-Path -LiteralPath $projection)) "$Name created logical project state."
    $after = Snapshot $Root
    Save-Text (Join-Path $evidence ($Name + '.package-after.txt')) $after
    Assert-Test ($before -ceq $after) "$Name changed Package state."
    return $result
}
function Quote-PS([string]$Value) { return "'" + $Value.Replace("'", "''") + "'" }
function Invoke-ExportGate([string]$Name, [string]$Root) {
    $before = Snapshot $Root
    Save-Text (Join-Path $evidence ($Name + '.package-before.txt')) $before
    $exporter = Quote-PS (Join-Path $Root 'Tests~/export-codedb-package.ps1')
    $validator = Quote-PS (Join-Path $Root 'Tests~/test-codedb-package-release-closure.ps1')
    $command = '. {0} -Commit fixture -OutputRoot {1} -LoadFunctionsOnly; Invoke-PackageClosureValidator -ValidatorPath {2} -PackagePath {3} -Label {4}' -f
        $exporter, (Quote-PS $evidence), $validator, (Quote-PS $Root), (Quote-PS $Name)
    $result = Invoke-PowerShell $Name ('-Command "' + $command + '"')
    $after = Snapshot $Root
    Save-Text (Join-Path $evidence ($Name + '.package-after.txt')) $after
    Assert-Test ($before -ceq $after) "$Name changed Package state."
    Assert-Test (-not (Test-Path -LiteralPath (Join-Path $Root 'Tests~/.payload-admission-projection'))) "$Name created projection state."
    return $result
}
function Assert-DeclaredSourceHashes([string]$Root) {
    $payloadRoot = Join-Path $Root 'Payload~'
    $manifest = Get-Content -LiteralPath (Join-Path $payloadRoot 'payload-manifest.json') -Raw | ConvertFrom-Json
    foreach ($entry in $manifest.files) {
        $actual = (Get-FileHash -LiteralPath (Join-Path $payloadRoot $entry.source) -Algorithm SHA256).Hash.ToLowerInvariant()
        Assert-Test ($actual -ceq [string]$entry.sha256) ('Fixture source/hash changed: ' + $entry.source)
    }
}
$sourceBefore = Snapshot $package
Save-Text (Join-Path $evidence 'source-before.txt') $sourceBefore
$manifest = Get-Content -LiteralPath (Join-Path $package 'Payload~/payload-manifest.json') -Raw | ConvertFrom-Json
$generationPrefix = 'AIWork/.runtime/codedb/host/generations/' + $manifest.generation_id + '/'
$sixTargets = @()
foreach ($prefix in @('AIWork/codedb/', $generationPrefix)) {
    foreach ($relative in @('native/win-x64/build-manifest.json', 'native/win-x64/codedb-daemon-launch.exe', 'shared/codedb-daemon-launch.mjs')) {
        $target = $prefix + $relative
        Assert-Test (@($manifest.files | Where-Object { $_.target -ceq $target }).Count -eq 1) ('Canonical target missing: ' + $target)
        $sixTargets += $target
    }
}
Save-Text (Join-Path $evidence 'six-targets.txt') ($sixTargets -join "`n")
$positive = Invoke-Reader 'canonical-source' $package
Assert-Test ($positive.ExitCode -eq 0 -and $positive.Out -match '\[PRODUCTION_PAYLOAD_ADMISSION\] PASS ') 'Canonical admission failed.'

# Commit bytes plus the bounded source repair form the reviewable staging fixture.
# This does not create a commit or claim committed delivery.
$baseCommit = (& git -C $repo rev-parse HEAD).Trim()
Save-Text (Join-Path $evidence 'base-commit.txt') $baseCommit
$tar = Join-Path $evidence 'base-package.tar'
& git -C $repo archive --format=tar --output=$tar $baseCommit -- com.rice.ai-codedb
Assert-Test ($LASTEXITCODE -eq 0) 'Fixture git archive failed.'
$stageParent = Join-Path $evidence 'stage'
[IO.Directory]::CreateDirectory($stageParent) | Out-Null
& tar -xf $tar -C $stageParent
Assert-Test ($LASTEXITCODE -eq 0) 'Fixture extraction failed.'
$stage = Join-Path $stageParent 'com.rice.ai-codedb'
$changedPaths = @('Tools~/materialize-codedb-host-payload.ps1', 'Tests~/test-codedb-package-release-closure.ps1', 'Tests~/export-codedb-package.ps1', 'Tests~/test-codedb-payload-admission.ps1')
foreach ($relative in $changedPaths) {
    Copy-Item -LiteralPath (Join-Path $package $relative) -Destination (Join-Path $stage $relative)
}
$staged = Invoke-ExportGate 'source-snapshot-stage' $stage
Assert-Test ($staged.ExitCode -eq 0 -and $staged.Out -match '\[PACKAGE_EXPORT_GATE\] PASS ' -and $staged.Out -match '\[PACKAGE_BYTE_CLOSURE\] PASS ') 'Staged export gate failed.'
. (Join-Path $package 'Tests~/export-codedb-package.ps1') -Commit fixture -OutputRoot $evidence -LoadFunctionsOnly
$zip = Join-Path $evidence 'source-snapshot.zip'
New-DeterministicPackageZip -PackagePath $stage -ArchivePath $zip
$exactParent = Join-Path $evidence 'exact-zip'
[IO.Compression.ZipFile]::ExtractToDirectory($zip, $exactParent)
$exact = Join-Path $exactParent 'com.rice.ai-codedb'
Assert-Test ((Snapshot $stage) -ceq (Snapshot $exact)) 'ZIP extraction differs from staged snapshot.'
$extracted = Invoke-ExportGate 'exact-zip' $exact
Assert-Test ($extracted.ExitCode -eq 0 -and $extracted.Out -match '\[PACKAGE_EXPORT_GATE\] PASS ' -and $extracted.Out -match '\[PACKAGE_BYTE_CLOSURE\] PASS ') 'Exact ZIP export gate failed.'

foreach ($layout in @('flat', 'generation')) {
    $fixtureParent = Join-Path $evidence ('unknown-' + $layout)
    [IO.Directory]::CreateDirectory($fixtureParent) | Out-Null
    Copy-Item -LiteralPath $stage -Destination $fixtureParent -Recurse
    $fixture = Join-Path $fixtureParent 'com.rice.ai-codedb'
    $path = Join-Path $fixture 'Payload~/payload-manifest.json'
    $document = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $prefix = if ($layout -eq 'flat') { 'AIWork/codedb/' } else { $generationPrefix }
    $entry = @($document.files | Where-Object { $_.target -ceq ($prefix + 'native/win-x64/build-manifest.json') })[0]
    $entry.target = $prefix + 'native/win-x64/unaudited-adjacent.json'
    Save-Text $path (($document | ConvertTo-Json -Depth 100) + "`n")
    Assert-DeclaredSourceHashes $fixture
    Save-Text (Join-Path $evidence ('unknown-' + $layout + '.source-hashes.txt')) 'PASS: every declared source byte SHA256 is unchanged and valid; only the copied manifest target changed.'
    $negative = Invoke-Reader ('unknown-' + $layout + '-reader') $fixture
    Assert-Test ($negative.ExitCode -eq 2 -and $negative.Error.Contains('outside the audited production allowlist: ' + $entry.target)) "$layout reader failed to reject unknown target."
    $gate = Invoke-ExportGate ('unknown-' + $layout + '-export-gate') $fixture
    Assert-Test ($gate.ExitCode -ne 0 -and $gate.Error.Contains('outside the audited production allowlist: ' + $entry.target)) "$layout export gate failed to reject the same target."
    Assert-Test ($gate.Out -notmatch '\[PACKAGE_(EXPORT_GATE|CLOSURE)\] PASS') "$layout invalid Package received export/closure PASS."
}
$sourceAfter = Snapshot $package
Save-Text (Join-Path $evidence 'source-after.txt') $sourceAfter
Assert-Test ($sourceBefore -ceq $sourceAfter) 'Focused validation changed source Package.'
$hashLines = @($changedPaths | ForEach-Object { '{0} {1}' -f $_, (Get-FileHash -LiteralPath (Join-Path $package $_) -Algorithm SHA256).Hash.ToLowerInvariant() })
Save-Text (Join-Path $evidence 'source-script-hashes.txt') ($hashLines -join "`n")
Save-Text (Join-Path $evidence 'summary.txt') 'PASS: canonical six targets; staged byte closure and production admission; exact ZIP byte closure and admission; flat/generation unknown reader exit 2 and export refusal; all Package snapshots unchanged; no logical project created.'
Write-Output ('[PAYLOAD_ADMISSION_TEST] PASS evidence=' + $evidence)
