#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$run = (Resolve-Path $RunDirectory).Path
$owned = Join-Path $repo '.artifacts/tests/cdb-v0.3-candidate-source-integration'
if (-not $run.StartsWith($owned + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Wrong task artifact root.' }
$plan = Get-Content -LiteralPath (Join-Path $run 'plan.json') -Raw | ConvertFrom-Json
$manifest = Get-Content -LiteralPath (Join-Path $run 'candidate-source-manifest.json') -Raw | ConvertFrom-Json
$checks = [Collections.Generic.List[string]]::new()
$receipt = [ordered]@{ outcome='RUNNING'; started_utc=[DateTime]::UtcNow.ToString('o'); checks=$checks; unity='NOT_RUN'; editmode='NOT_RUN'; mcp='NOT_RUN'; full_release_closure='NOT_RUN'; source_manifest_sha256=$manifest.source_manifest_sha256 }
function Check([bool]$value, [string]$label) { if (-not $value) { throw $label }; $checks.Add($label) }
function Hash([string]$p) { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
try {
    foreach ($file in $plan.files) {
        $p = Join-Path $repo $file.path
        switch ([IO.Path]::GetExtension($p)) {
            '.cs' {
                $tree = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText($p))
                Check (@($tree.GetDiagnostics() | Where-Object Severity -eq Error).Count -eq 0) ('C# syntax: ' + $file.path)
            }
            '.ps1' {
                $tokens=$null; $errors=$null
                [void][Management.Automation.Language.Parser]::ParseFile($p,[ref]$tokens,[ref]$errors)
                Check ($errors.Count -eq 0) ('PowerShell syntax: ' + $file.path)
            }
            '.mjs' {
                & node --check $p
                Check ($LASTEXITCODE -eq 0) ('Node syntax without module execution: ' + $file.path)
            }
            '.meta' {
                Check ([IO.File]::ReadAllText($p) -match '(?m)^guid: [0-9a-f]{32}\r?$') ('Unity GUID metadata: ' + $file.path)
            }
        }
    }
    $payloadRoot = Join-Path $repo 'com.rice.ai-codedb/Payload~'
    $payload = Get-Content -LiteralPath (Join-Path $payloadRoot 'payload-manifest.json') -Raw | ConvertFrom-Json
    $generationPath = Join-Path $payloadRoot ('Generations/' + $payload.generation_id + '/generation-manifest.json')
    $generation = Get-Content -LiteralPath $generationPath -Raw | ConvertFrom-Json
    foreach ($file in $payload.files) {
        Check ((Hash (Join-Path $payloadRoot $file.source)) -ceq $file.sha256) ('Payload declared hash: ' + $file.source)
    }
    foreach ($file in $generation.files) {
        Check ((Hash (Join-Path (Split-Path $generationPath -Parent) $file.path)) -ceq $file.sha256) ('Current generation declared hash: ' + $file.path)
    }
    $receipt.generation_id = $payload.generation_id
    $receipt.generation_manifest_sha256 = Hash $generationPath
    Check ($receipt.generation_manifest_sha256 -ceq 'f7ff1d0777b6d7e4daa846139b22bdf86686e7778234a2a7e8264f6d61694fbb') 'Selected generation manifest remains accepted poc.44'
    $old = Get-Content -LiteralPath (Join-Path $repo '.artifacts/tests/cdb-v0.3-candidate-residual-legacy-review/1d2ce6c8-f8fc-4fbb-98e9-6c907b4ec160/receipt.json') -Raw | ConvertFrom-Json
    Check ($old.outcome -ceq 'PASS') 'Prior F01 executable offline receipt passes'
    Check ((Hash (Join-Path $repo 'com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs')) -ceq $old.source_hashes.'isolation/com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs') 'Integrated F01 bytes match executable fixture evidence'
    Check ((Hash (Join-Path $repo 'com.rice.ai-codedb/Editor/AICodedbManagerTransitionEvidence.cs')) -ceq $old.source_hashes.'isolation/com.rice.ai-codedb/Editor/AICodedbManagerTransitionEvidence.cs') 'Integrated helper matches executable fixture evidence'
    foreach ($name in @('com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs','com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1')) {
        Check ((Hash (Join-Path $repo $name)) -ceq $old.source_hashes.('primary/' + $name)) ('F02 exclusion preserved: ' + $name)
    }
    foreach ($file in $manifest.files) {
        if ((Hash (Join-Path $repo $file.path)) -cne $file.sha256) { throw ('Source changed during checks: ' + $file.path) }
    }
    Check $true ('All ' + $manifest.files.Count + ' candidate source hashes stable after checks')
    & git -C $repo diff --check -- @($plan.files.path)
    Check ($LASTEXITCODE -eq 0) 'Scoped integration diff whitespace check'
    $receipt.outcome='PASS'
} catch {
    $receipt.outcome='FAIL'; $receipt.error=$_.Exception.ToString(); throw
} finally {
    $receipt.finished_utc=[DateTime]::UtcNow.ToString('o')
    [IO.File]::WriteAllText((Join-Path $run 'verification-receipt.json'),($receipt | ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    [ordered]@{outcome=$receipt.outcome; checks=$checks.Count; source_manifest_sha256=$receipt.source_manifest_sha256; receipt=[IO.Path]::GetRelativePath($repo,(Join-Path $run 'verification-receipt.json'))} | ConvertTo-Json
}
