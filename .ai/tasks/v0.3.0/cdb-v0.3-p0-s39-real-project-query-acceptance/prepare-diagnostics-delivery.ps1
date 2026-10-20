#requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$base = 'c07bb5903b5b3fcda7d97f5238c2915e3c566cf8'
if ((& git -C $repo rev-parse HEAD).Trim() -cne $base) { throw 'Frozen base changed.' }
$parent = Join-Path $repo '.artifacts/tests/s39-diagnostics-delivery'
$run = Join-Path $parent ('r-' + [guid]::NewGuid().ToString('N').Substring(0,8))
function Hash([string]$path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Guard([string]$path) {
    $resolved = [IO.Path]::GetFullPath($path)
    if (-not $resolved.StartsWith($repo.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Output escaped repository.' }
    while ($resolved.Length -gt $repo.Length) {
        if (Test-Path -LiteralPath $resolved) {
            if ((Get-Item -LiteralPath $resolved -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Redirected output refused.' }
        }
        $resolved = Split-Path $resolved -Parent
    }
}
Guard $run
if (Test-Path -LiteralPath $run) { throw 'Run allocation collision.' }
[void][IO.Directory]::CreateDirectory($run)
$ioProbe=Join-Path $run 'io-probe'
[IO.File]::WriteAllText($ioProbe,'owned')
if ([IO.File]::ReadAllText($ioProbe) -cne 'owned') { throw 'Owned output read failed.' }
[IO.File]::Delete($ioProbe)
$utf8=[Text.UTF8Encoding]::new($false)
function Record([string]$path,$value) {
    Guard $path
    [IO.File]::WriteAllText($path,($value | ConvertTo-Json -Depth 100),$utf8)
}
Record (Join-Path $run 'owner.json') @{task='s39-diagnostics-delivery';base=$base}
$candidateParent=Join-Path $run 'candidate'
[void][IO.Directory]::CreateDirectory($candidateParent)
# Read-only Git baseline snapshot for local review; not a distributable export.
$baselineArchive=Join-Path $run 'baseline-source.tar'
& git -C $repo archive --format=tar "--output=$baselineArchive" $base -- com.rice.ai-codedb
if ($LASTEXITCODE -ne 0) { throw 'Baseline source snapshot failed.' }
& tar -xf (Join-Path $run 'baseline-source.tar') -C $candidateParent
if ($LASTEXITCODE -ne 0) { throw 'Baseline extraction failed.' }
$package=Join-Path $candidateParent 'com.rice.ai-codedb'
$baseline=@{}
foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
    $baseline[$file.FullName.Substring($package.Length+1).Replace('\','/')]=Hash $file.FullName
}
$overlay=@('Payload~/AIWork/codedb/wrapper/codedb-project-wrapper.mjs',
    'Tools~/probe-codedb-mcp-availability.mjs','Tests~/test-codedb-bootstrap-diagnostics.mjs')
foreach ($relative in $overlay) {
    Copy-Item -LiteralPath (Join-Path $repo ('com.rice.ai-codedb/'+$relative)) -Destination (Join-Path $package $relative)
}
$contract='Documentation~/v0.3.0-p0-project-integration-reinstall-contract.md'
$text=[IO.File]::ReadAllText((Join-Path $repo ('com.rice.ai-codedb/'+$contract)))
$matches=[regex]::Matches($text,'(?ms)^### Stable Entry Termination Diagnostics[^\r\n]*\r?\n.*?(?=^### |\z)')
if ($matches.Count -ne 1) { throw 'Diagnostic contract amendment is not unique.' }
$candidateContract=Join-Path $package $contract
$baselineContract=[IO.File]::ReadAllText($candidateContract)
$anchor='### Declared Adapter Outputs and Retention Boundary - 2026-10-09'
if ([regex]::Matches($baselineContract,[regex]::Escape($anchor)).Count -ne 1) { throw 'Contract insertion anchor drifted.' }
[IO.File]::WriteAllText($candidateContract,$baselineContract.Replace($anchor,$matches[0].Value.Replace("`r`n","`n")+$anchor),$utf8)

# One local generator route: validate every unchanged source, derive the changed
# stable-bootstrap hash from its bytes, then use the existing canonical writer
# for generation/host/payload cross-hashes and the existing status projection.
$validator=Join-Path $package 'Tests~/test-codedb-package-release-closure.ps1'
$tokens=$null; $errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($validator,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw 'Canonical metadata source parse failed.' }
$functions=@('Get-Sha256','Write-CanonicalJson','Repair-CanonicalMetadata')
$definitions=@($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -cin $functions })
if ($definitions.Count -ne $functions.Count) { throw 'Canonical writer functions missing.' }
$writer=New-Module -ScriptBlock ([scriptblock]::Create(($definitions.Extent.Text -join "`n")))
$payloadPath=Join-Path $package 'Payload~/payload-manifest.json'
$hostPath=Join-Path $package 'Payload~/host-current.json'
$payload=Get-Content -LiteralPath $payloadPath -Raw | ConvertFrom-Json
$generationPath=Join-Path $package ('Payload~/Generations/'+$payload.generation_id+'/generation-manifest.json')
$generationHash=Hash $generationPath; $hostHash=Hash $hostPath
$hostCurrent=Get-Content -LiteralPath $hostPath -Raw | ConvertFrom-Json
$generation=Get-Content -LiteralPath $generationPath -Raw | ConvertFrom-Json
foreach ($entry in $payload.files) {
    $actual=Hash (Join-Path $package ('Payload~/'+$entry.source))
    if ($entry.source -ceq 'AIWork/codedb/wrapper/codedb-project-wrapper.mjs') { $entry.sha256=$actual }
    elseif ($actual -cne $entry.sha256) { throw ('Unexpected source drift: '+$entry.source) }
}
& $writer {
    param($package,$payload,$hostCurrent,$generation,$payloadPath,$hostPath,$generationPath)
    Repair-CanonicalMetadata -Root $package -Payload $payload -HostCurrent $hostCurrent -Generation $generation `
        -PayloadManifestPath $payloadPath -HostCurrentPath $hostPath -GenerationPath $generationPath
    $fixturePath=Join-Path $package 'Tests/Editor/OwnerIdentityV2Status.json'
    $fixture=Get-Content -LiteralPath $fixturePath -Raw | ConvertFrom-Json
    $fixture.status.runtime_contract_sha256=Get-Sha256 $payloadPath
    $fixture.status.operational_readiness.runtime_contract_sha256=Get-Sha256 $payloadPath
    Write-CanonicalJson -Path $fixturePath -Value $fixture
} $package $payload $hostCurrent $generation $payloadPath $hostPath $generationPath
if ((Hash $generationPath) -cne $generationHash -or (Hash $hostPath) -cne $hostHash) { throw 'Canonical rewrite changed protected immutable metadata bytes; no delivery.' }
$allowed=@($overlay)+@($contract,'Payload~/payload-manifest.json','Tests/Editor/OwnerIdentityV2Status.json')
$changes=@(foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
    $relative=$file.FullName.Substring($package.Length+1).Replace('\','/')
    $actual=Hash $file.FullName
    if (-not $baseline.ContainsKey($relative) -or $actual -cne $baseline[$relative]) {
        if ($relative -cnotin $allowed) { throw ('Unexpected candidate delta: '+$relative) }
        [ordered]@{path=$relative;sha256=$actual;prior_sha256=$baseline[$relative]}
    }
})
if ($changes.Count -ne $allowed.Count) { throw 'Candidate delta cardinality drifted.' }
Record (Join-Path $run 'candidate-diff.json') $changes
Record (Join-Path $run 'preparation.json') ([ordered]@{status='LOCAL_REVIEW_CANDIDATE';base=$base;candidate=$package.Substring($repo.Length+1).Replace('\','/');immutable_generation_unchanged=$true;host_current_unchanged=$true;delivery_authorization='NONE'})
Write-Output ('[PREPARED] '+$run.Substring($repo.Length+1).Replace('\','/'))
