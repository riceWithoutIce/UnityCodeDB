#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$package=Join-Path $repo 'com.rice.ai-codedb'
$payloadPath=Join-Path $package 'Payload~/payload-manifest.json'
$payload=Get-Content -LiteralPath $payloadPath -Raw|ConvertFrom-Json
if ($payload.generation_id -cne 'poc.44') { throw 'Only the new cwd successor is writable.' }
$generationPath=Join-Path $package 'Payload~/Generations/poc.44/generation-manifest.json'
$hostPath=Join-Path $package 'Payload~/host-current.json'
$generation=Get-Content -LiteralPath $generationPath -Raw|ConvertFrom-Json
$hostCurrent=Get-Content -LiteralPath $hostPath -Raw|ConvertFrom-Json
$helper='shared/codedb-mcp-registration-contract.ps1'
Copy-Item -LiteralPath (Join-Path $package ('Payload~/AIWork/codedb/'+$helper)) -Destination (Join-Path $package ('Payload~/Generations/poc.44/'+$helper))
if (@($generation.files|Where-Object path -eq $helper).Count -eq 0) {
    $generation.files=@($generation.files)+@([pscustomobject]@{path=$helper;sha256=''})
}
foreach ($prefix in @('AIWork/codedb/','Generations/poc.44/')) {
    $source=$prefix+$helper
    if (@($payload.files|Where-Object source -eq $source).Count -eq 0) {
        $target=if ($prefix -eq 'AIWork/codedb/') {$source} else {'AIWork/.runtime/codedb/host/generations/poc.44/'+$helper}
        $payload.files=@($payload.files)+@([pscustomobject]@{source=$source;target=$target;sha256=''})
    }
}
foreach ($file in $generation.files) {
    $file.sha256=(Get-FileHash -LiteralPath (Join-Path $package ('Payload~/Generations/poc.44/'+$file.path)) -Algorithm SHA256).Hash.ToLowerInvariant()
}
foreach ($file in $payload.files) {
    $file.sha256=(Get-FileHash -LiteralPath (Join-Path $package ('Payload~/'+$file.source)) -Algorithm SHA256).Hash.ToLowerInvariant()
}
# Reuse the existing canonical closure writer, not a new metadata format.
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $package 'Tests~/test-codedb-package-release-closure.ps1'),[ref]$tokens,[ref]$errors)
if ($errors.Count) {throw 'Canonical writer source syntax failed.'}
$names=@('Get-Sha256','Write-CanonicalJson','Repair-CanonicalMetadata')
$defs=@($ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -cin $names})
if ($defs.Count -ne $names.Count) {throw 'Canonical writer definitions missing.'}
$module=New-Module -ScriptBlock ([scriptblock]::Create(($defs.Extent.Text -join "`n")))
try {
    & $module {
        param($package,$payload,$hostCurrent,$generation,$payloadPath,$hostPath,$generationPath)
        Repair-CanonicalMetadata -Root $package -Payload $payload -HostCurrent $hostCurrent -Generation $generation -PayloadManifestPath $payloadPath -HostCurrentPath $hostPath -GenerationPath $generationPath
        $fixturePath=Join-Path $package 'Tests/Editor/OwnerIdentityV2Status.json'
        $fixture=Get-Content -LiteralPath $fixturePath -Raw|ConvertFrom-Json
        $fixture.status.runtime_contract_sha256=Get-Sha256 $payloadPath
        $fixture.status.operational_readiness.runtime_contract_sha256=Get-Sha256 $payloadPath
        Write-CanonicalJson -Path $fixturePath -Value $fixture
    } $package $payload $hostCurrent $generation $payloadPath $hostPath $generationPath
} finally {Remove-Module $module}
