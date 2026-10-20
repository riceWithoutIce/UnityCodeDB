#requires -Version 5.1
param([string]$CanonicalPayloadRoot, [switch]$CSharpOnly, [string]$FixtureContainer)
$ErrorActionPreference = 'Stop'
$package = Split-Path $PSScriptRoot -Parent
$repository = Split-Path $package -Parent
# Extracted candidates use the enclosing checkout's test root, keeping Windows
# fixture paths bounded without moving output outside the authorized repository.
$gitRoot=@(& git -C $package rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -eq 0 -and $gitRoot.Count -eq 1) {
    $candidateRepository=[IO.Path]::GetFullPath($gitRoot[0])
    if ([IO.Path]::GetFullPath($package).StartsWith($candidateRepository.TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
        $repository=$candidateRepository
    }
}
if (-not $CanonicalPayloadRoot) { $CanonicalPayloadRoot=Join-Path $package 'Payload~' }
$CanonicalPayloadRoot=[IO.Path]::GetFullPath($CanonicalPayloadRoot)
if ($CSharpOnly) {
    if (-not $FixtureContainer) { throw 'CSharpOnly requires a fixture from the PowerShell cases.' }
    $fixture=Get-Content (Join-Path $FixtureContainer 'fixture.json') -Raw | ConvertFrom-Json
    $compileRoot=Join-Path $FixtureContainer 'csharp'
    [void][IO.Directory]::CreateDirectory($compileRoot)
    $sources=@()
    foreach ($name in @('AICodedbPackageRuntimeContract','AICodedbStrictJson')) {
        $target=Join-Path $compileRoot ($name+'.cs')
        [IO.File]::WriteAllText($target,[IO.File]::ReadAllText((Join-Path $package ('Editor/'+$name+'.cs'))))
        $sources+= $target
    }
    # Exact production control identity classes, excluding unrelated Unity migration UI.
    $control=[IO.File]::ReadAllText((Join-Path $package 'Editor/AICodedbControlContract.cs'))
    $control=$control.Substring(0,$control.IndexOf('    internal enum AICodedbControlContractMigrationState'))+'}'
    $target=Join-Path $compileRoot 'ControlIdentity.cs'; [IO.File]::WriteAllText($target,$control); $sources+=$target
    $boundary=@'
using System;
using System.IO;
namespace Rice.AI.Codedb.Editor {
 internal static class AICodedbPaths { internal static string NormalizePath(string value) => Path.GetFullPath(value).Replace(Path.DirectorySeparatorChar,'/'); }
 internal static class AICodedbProjectIntegrationStateStore {
  internal static void AssertNoReparsePoint(string root,string target) {
   var current=Path.GetFullPath(target); var boundary=Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);
   if(!current.StartsWith(boundary+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Outside fixture");
   while(current.Length>=boundary.Length) {
    if((File.Exists(current)||Directory.Exists(current)) && (File.GetAttributes(current)&FileAttributes.ReparsePoint)!=0) throw new InvalidOperationException("Reparse point");
    current=Path.GetDirectoryName(current); if(current==null) break;
   }
  }
 }
 public static class BootstrapHarness {
  public static void Validate(string root,string hash,string generation,bool historical) => AICodedbPackageRuntimeContractStore.ValidateProjectStableWrapper(root,hash,generation,historical);
 }
}
'@
    $target=Join-Path $compileRoot 'FixtureBoundary.cs'; [IO.File]::WriteAllText($target,$boundary); $sources+=$target
    Add-Type -Path $sources
    $wrapper=Join-Path $fixture.project 'AIWork/codedb/wrapper/codedb-project-wrapper.mjs'
    $dependency=Join-Path $fixture.project 'AIWork/codedb/shared/codedb-instance-manifest-contract.mjs'
    $hash=(Get-FileHash -LiteralPath $wrapper).Hash.ToLowerInvariant()
    $bytes=[IO.File]::ReadAllBytes($dependency)
    function Validate([bool]$historical=$false) { [Rice.AI.Codedb.Editor.BootstrapHarness]::Validate($fixture.project,$hash,$fixture.generation,$historical) }
    function MustReject([scriptblock]$body) { $rejected=$false; try { & $body } catch { $rejected=$true }; if(-not $rejected){throw 'C# dependency validation unexpectedly accepted'} }
    Validate
    try {
        Remove-Item -LiteralPath $dependency
        MustReject { Validate }
        Validate $true
        [IO.File]::WriteAllText($dependency,'tampered')
        MustReject { Validate }; MustReject { Validate $true }
    } finally { [IO.File]::WriteAllBytes($dependency,$bytes) }
    $wrapperBytes=[IO.File]::ReadAllBytes($wrapper)
    try {
        [IO.File]::WriteAllText($wrapper,'// authenticated historical self-contained launcher')
        $hash=(Get-FileHash -LiteralPath $wrapper).Hash.ToLowerInvariant()
        Validate
    } finally { [IO.File]::WriteAllBytes($wrapper,$wrapperBytes) }
    Write-Host '[PASS] C# contract compiled and 6 dependency/historical cases; real strict parser/control identity; fixture filesystem boundaries; NOT Unity compilation'
    return
}
$container = Join-Path $repository ('.artifacts/tests/s39-stable-bootstrap/r-' + [guid]::NewGuid().ToString('N').Substring(0,8))
if (Test-Path -LiteralPath $container) { throw 'S39 fixture allocation collision.' }
[void][IO.Directory]::CreateDirectory($container)
$parts = [Collections.Generic.List[string]]::new()
$parts.Add('param($package, $container, $canonicalPayloadRoot)')
# Import unchanged function bodies and their declared constants, never script main.
foreach ($path in @('Payload~/AIWork/codedb/shared/codedb-strict-json.ps1',
    'Payload~/AIWork/codedb/shared/codedb-instance-manifest-contract.ps1',
    'Payload~/AIWork/codedb/shared/codedb-text-adapter-output-contract.ps1',
    'Tools~/materialize-codedb-host-payload.ps1', 'Tools~/codedb-instance-engine.ps1')) {
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $package $path),[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw "Production parse failed: $path" }
    $beforeFunctions=$true
    foreach ($statement in $ast.EndBlock.Statements) {
        if ($statement -is [Management.Automation.Language.FunctionDefinitionAst]) {
            $beforeFunctions=$false; $parts.Add($statement.Extent.Text)
        } elseif ($beforeFunctions -and (($statement -is [Management.Automation.Language.AssignmentStatementAst] -and
            $statement.Left.Extent.Text.StartsWith('$script:')) -or $statement -is [Management.Automation.Language.ForEachStatementAst])) {
            $parts.Add($statement.Extent.Text)
        }
    }
}
$module=New-Module -ScriptBlock ([scriptblock]::Create($parts -join "`n")) -ArgumentList $package,$container,$CanonicalPayloadRoot
Start-Transcript -Path (Join-Path $container 'run.log') | Out-Null
try {
    & $module {
        $ErrorActionPreference='Stop'
        $script:cases=0
        function Check($condition, $label) {
            if (-not $condition) { throw "Assertion failed: $label" }
            $script:cases++; Write-Host "[PASS] $label"
        }
        function Reject([scriptblock]$body, $expected, $label) {
            $message=''; try { & $body | Out-Null } catch { $message=$_.Exception.Message }
            Check ($message.Contains($expected)) "$label ($expected)"
        }
        function Record($path,$document) {
            Assert-PathInside -Path $path -Root $container -Label 'S39 fixture write'
            [void][IO.Directory]::CreateDirectory((Split-Path $path -Parent))
            [IO.File]::WriteAllText($path,(ConvertTo-InstanceJsonText $document),[Text.UTF8Encoding]::new($false))
        }
        function Fresh($name) {
            $root=Join-Path $container $name
            foreach ($dir in @('Assets','Packages','ProjectSettings')) { [void][IO.Directory]::CreateDirectory((Join-Path $root $dir)) }
            $manifest=Read-PayloadManifest -Root $canonicalPayloadRoot -ProjectRoot $root
            return @{Root=$root;Manifest=$manifest}
        }
        function Reset-Result {
            $script:RequestedExitCode=0; $script:CommandOutcome=''; $script:CommandReasonCode=''
            $script:CommandCleanupState=''; $script:CommandNextAction=''; $script:CommandMutatedScopes.Clear()
        }
        # Explicit synthetic external boundaries; no Provider/Unity/process discovery.
        function Get-MaterializerMachinePrerequisiteStatus {
            param($Manifest)
            return [pscustomobject]@{Current=$true;State='CURRENT';ReasonCode='FIXTURE_CURRENT';Detail='Synthetic prerequisite';NextAction='';NodePath='';NodeVersion='fixture';ProviderVersion='fixture';ProviderRoot='';ProviderManifestPath='';ProviderExecutablePath=''}
        }
        function Get-MaterializerProcessIdentity { param($ProcessId); throw 'External process observation forbidden in S39 fixtures.' }
        function Invoke-BoundedNativeProcessWithFileOutput { throw 'Provider execution forbidden in S39 fixtures.' }
        $script:PocFixture=$true; $script:Action='Install'
        $fresh=Fresh 'clean'; $root=$fresh.Root; $manifest=$fresh.Manifest
        Reset-Result
        Invoke-InstanceConvergence -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root $script:MarkerRelativePath) -ActionName Install
        $current=Get-ValidatedCurrentInstance -Manifest $manifest -ProjectRoot $root
        $state=Get-InstanceActivationContractState -Manifest $manifest -ProjectRoot $root
        $bootstrap=@(Get-InstanceBootstrapTargets)
        foreach ($target in $bootstrap) {
            Check ((Get-FileSha256 (Join-Path $root $target)) -ceq $manifest.TargetMap[$target].Sha256) "clean activation publishes $target"
        }
        $targets=@($state.Operation.Document.mutations | ForEach-Object { $_.target })
        $dependency=Join-Path $root $bootstrap[1]
        Check ($targets.IndexOf($bootstrap[1]) -ge 0 -and $targets.IndexOf($bootstrap[1]) -lt $targets.IndexOf($bootstrap[0]) -and $targets[-1] -ceq $script:InstanceCurrentRelativePath) 'dependency precedes launcher and final selection'
        Check ($state.Operation.Phase -ceq 'COMMITTED' -and $script:CommandOutcome -ceq 'INSTALLED') 'production activation committed'
        $bytes=[IO.File]::ReadAllBytes($dependency)
        Remove-Item -LiteralPath $dependency
        Reject { Get-ValidatedCurrentInstance -Manifest $manifest -ProjectRoot $root } 'bootstrap dependency' 'operational missing dependency fails closed'
        [IO.File]::WriteAllText($dependency,'unknown-owned-by-user')
        Reject { Get-ValidatedCurrentInstance -Manifest $manifest -ProjectRoot $root } 'bootstrap dependency' 'operational drift fails closed'
        Reject { Assert-InstanceBootstrapPublication -Manifest $manifest -ProjectRoot $root -PreviousInstance $current } 'unowned or drifted' 'unknown existing dependency is not overwritten'
        Reject { Get-MarkerlessInstanceClosureFiles -Manifest $manifest -ProjectRoot $root } 'not the exact Package-owned' 'removal refuses dependency drift'
        [IO.File]::WriteAllBytes($dependency,$bytes)
        $removal=@(Get-MarkerlessInstanceClosureFiles -Manifest $manifest -ProjectRoot $root)
        Check ($bootstrap[1] -cin @($removal.Target)) 'authenticated dependency participates in removal'
        $inventoryId=[guid]::NewGuid().ToString('N')
        $inventoryRoot=Join-Path $root ($script:InstancesRelativePath+'/'+$inventoryId)
        foreach ($dir in $script:InstanceAllowedDirectories) { [void][IO.Directory]::CreateDirectory((Join-Path $inventoryRoot $dir)) }
        $document=New-InstanceManifestDocument -Manifest $manifest -ProjectRoot $root -InstanceId $inventoryId -State PROVISIONING -CreatedAtUtc ([DateTime]::UtcNow.ToString('o'))
        $inventoryManifest=Write-InstanceManifest -InstanceRoot $inventoryRoot -Document $document
        try {
            $effects=@(Get-FailedPreparationEffects -ProjectRoot $root -InstanceId $inventoryId -GenerationId $current.Generation.GenerationId -Manifest $manifest -Generation $current.Generation)
            $authority=@{Evidence=@{InstanceId=$inventoryId;ManifestPath=$inventoryManifest;Manifest=$document};Effects=@($effects | Where-Object { $_.relative_path -cne 'AIWork/codedb/shared' });WrapperSha256=$current.Generation.StableWrapperSha256}
            $intent=New-FailedPreparationRemovalIntentDocument -ProjectRoot $root -StateId ([guid]::NewGuid().ToString('N')) -Authority $authority
            $intent=ConvertFrom-StrictJsonText -Text (ConvertTo-InstanceJsonText $intent) -Label 'synthetic retained intent'
            Assert-FailedPreparationEffects -ProjectRoot $root -Document $intent -Manifest $manifest
            Check $true 'retained snapshot permits authenticated shared-directory handoff'
            [IO.File]::WriteAllText($dependency,'unowned-retained-dependency')
            try { Reject { Assert-FailedPreparationEffects -ProjectRoot $root -Document $intent -Manifest $manifest } 'unowned or drifted' 'shared exclusion still authenticates dependency on every read' }
            finally { [IO.File]::WriteAllBytes($dependency,$bytes) }
            $legacyEffects=[Collections.Generic.List[object]]::new()
            foreach ($effect in $effects) {
                $legacyEffects.Add($effect)
                if ($effect.relative_path -ceq 'AIWork/codedb/shared') { $legacyEffects.Add([pscustomobject]@{relative_path=$bootstrap[1];kind='FILE';sha256=(Get-FileSha256 $dependency)}) }
            }
            $intent.retained_effects=$legacyEffects.ToArray()
            $intent.authority_fingerprint=Get-FailedPreparationFingerprint -Document $intent
            $intent=ConvertFrom-StrictJsonText -Text (ConvertTo-InstanceJsonText $intent) -Label 'historical retained intent'
            $historicalText=ConvertTo-InstanceJsonText $intent
            Assert-FailedPreparationEffects -ProjectRoot $root -Document $intent -Manifest $manifest
            Check ((ConvertTo-InstanceJsonText $intent) -ceq $historicalText) 'historical dependency snapshot is accepted without rewriting its observation'
        }
        finally {
            Assert-PathInside -Path $inventoryRoot -Root $container -Label 'owned inventory fixture cleanup'
            Remove-Item -LiteralPath $inventoryRoot -Recurse -Force
        }
        Check ($bootstrap[1] -cnotin @($effects.relative_path) -and $bootstrap[0] -cnotin @($effects.relative_path)) 'retained candidate inventory excludes mutable shared bootstrap'
        & {
            # Only marker/transition input readers are synthetic; execute the actual
            # retirement loop against the real authenticated bootstrap files.
            function Read-InstalledMarker { param($MarkerPath,$ProjectRoot); return @{Map=@{$bootstrap[0]=1};Files=@($bootstrap | ForEach-Object { [pscustomobject]@{Target=$_;TargetPath=(Join-Path $root $_);InstalledSha256='old-marker-hash'} })} }
            function Get-ReviewedBootstrapTransition { param($Manifest,$Marker); return @{Fixture=$true} }
            $retirement=Get-ValidatedLegacyFlatRetirement -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root 'fixture-marker')
            Check ($retirement.Files.Count -eq 0) 'legacy retirement preserves complete active bootstrap'
            [IO.File]::WriteAllText($dependency,'drift-before-retirement')
            try { Reject { Get-ValidatedLegacyFlatRetirement -Manifest $manifest -ProjectRoot $root -MarkerPath (Join-Path $root 'fixture-marker') } 'activation identity' 'legacy retirement refuses active dependency drift' }
            finally { [IO.File]::WriteAllBytes($dependency,$bytes) }
        }
        $remove=Fresh 'removal'
        foreach ($target in $bootstrap) {
            $path=Join-Path $remove.Root $target
            [void][IO.Directory]::CreateDirectory((Split-Path $path -Parent))
            [IO.File]::WriteAllBytes($path,(Get-InstanceActivationBytes -Manifest $remove.Manifest -Target $target))
        }
        $owned=@(Get-MarkerlessInstanceClosureFiles -Manifest $remove.Manifest -ProjectRoot $remove.Root)
        $opId=[guid]::NewGuid().ToString('N')
        $opRoot=Join-Path $remove.Root ($script:InstanceOperationsRelativePath+'/operation-'+$opId)
        [void][IO.Directory]::CreateDirectory($opRoot)
        $entries=[Collections.Generic.List[object]]::new()
        foreach ($file in $owned) { Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $remove.Root -OperationRoot $opRoot -Target $file.Target -Mutation Delete -DesiredBytes $null }
        Publish-InstanceOperation -ProjectRoot $remove.Root -ActionName Uninstall -CandidateInstanceId ([guid]::NewGuid().ToString('N')) -Entries $entries -StageRoot $opRoot -OperationRoot $opRoot -OperationId $opId
        Check (-not (Test-Path -LiteralPath (Join-Path $remove.Root $bootstrap[1]))) 'authenticated removal transaction deletes dependency'
        # Drive the production transaction publisher through a failure after all writes.
        foreach ($existing in @($false,$true)) {
            $rollback=Fresh ('rollback-'+$existing)
            $opId=[guid]::NewGuid().ToString('N')
            $opRoot=Join-Path $rollback.Root ($script:InstanceOperationsRelativePath+'/operation-'+$opId)
            [void][IO.Directory]::CreateDirectory($opRoot)
            $entries=[Collections.Generic.List[object]]::new()
            foreach ($target in @($bootstrap[1],$bootstrap[0])) {
                $path=Join-Path $rollback.Root $target
                if ($existing) { [void][IO.Directory]::CreateDirectory((Split-Path $path -Parent)); [IO.File]::WriteAllText($path,'previous-authenticated-bootstrap') }
                Add-InstanceTransactionEntryIfNeeded -Entries $entries -ProjectRoot $rollback.Root -OperationRoot $opRoot -Target $target -Mutation Write -DesiredBytes (Get-InstanceActivationBytes -Manifest $rollback.Manifest -Target $target)
            }
            Reject { Publish-InstanceOperation -ProjectRoot $rollback.Root -ActionName Install -CandidateInstanceId ([guid]::NewGuid().ToString('N')) -Entries $entries -StageRoot $opRoot -OperationRoot $opRoot -OperationId $opId -VerifyBeforeCommit { throw 'S39 injected after bootstrap publication' } } 'S39 injected' "transaction failure existing=$existing"
            foreach ($target in $bootstrap) {
                $path=Join-Path $rollback.Root $target
                Check $(if ($existing) { [IO.File]::ReadAllText($path) -ceq 'previous-authenticated-bootstrap' } else { -not (Test-Path -LiteralPath $path) }) "rollback restores bootstrap existing=$existing $target"
            }
        }
        # Real publication/selection with a deterministic post-commit boundary failure.
        $script:StableEntryProbeFunction=(Get-Command Invoke-InstanceStableEntryProbe).ScriptBlock
        function Invoke-InstanceStableEntryProbe { param($ProjectRoot); throw 'S39 postcommit probe failure' }
        $failed=Fresh 'postcommit'; Reset-Result
        Reject { Invoke-InstanceConvergence -Manifest $failed.Manifest -ProjectRoot $failed.Root -MarkerPath (Join-Path $failed.Root $script:MarkerRelativePath) -ActionName Install } 'COMMITTED' 'postcommit failure is explicit'
        $retained=Get-ValidatedCurrentInstance -Manifest $failed.Manifest -ProjectRoot $failed.Root
        $committed=Get-InstanceActivationContractState -Manifest $failed.Manifest -ProjectRoot $failed.Root
        Check ($committed.Operation.Phase -ceq 'COMMITTED' -and (Test-Path -LiteralPath $retained.InstanceRoot)) 'postcommit failure retains committed selection and candidate'
        Check ($script:CommandOutcome -ceq 'BLOCKED' -and $script:CommandReasonCode -ceq 'INSTANCE_STABLE_ENTRY_FAILED' -and $script:CommandCleanupState -ceq 'PENDING') 'postcommit failure never reports Ready or rollback'
        # Preserve the clean fixture for the separately bounded real Node entry test.
        Record (Join-Path $container 'fixture.json') @{project=$root;generation=$current.Generation.GenerationRoot;payload=$canonicalPayloadRoot;cases=$script:cases}
        Write-Host "[PASS] S39 PowerShell cases=$script:cases; synthetic external boundaries; no native service children"
    }
    & node (Join-Path $PSScriptRoot 'test-codedb-stable-bootstrap.mjs') $container $package
    if ($LASTEXITCODE -ne 0) { throw 'S39 Node stable-entry fixture failed.' }
    & $module {
        # A real file preserves the unchanged function's automatic PSScriptRoot;
        # an AST-created module has no source-file directory.
        $probeSource=Join-Path $container 'probe-entry.ps1'
        [IO.File]::WriteAllText($probeSource,('function Invoke-InstanceStableEntryProbe {'+$script:StableEntryProbeFunction.ToString()+'}'))
        Copy-Item -LiteralPath (Join-Path $package 'Tools~/probe-codedb-mcp-availability.mjs') -Destination (Join-Path $container $script:McpAvailabilityProbeName)
        . $probeSource
        $script:PocFixture=$false
        $fixture=Get-Content (Join-Path $container 'fixture.json') -Raw | ConvertFrom-Json
        Invoke-InstanceStableEntryProbe -ProjectRoot $fixture.project
        Write-Host '[PASS] production PowerShell stable-entry probe and native output collector against owned synthetic backend'
    }
    & pwsh -NoProfile -File $PSCommandPath -CSharpOnly -FixtureContainer $container
    if ($LASTEXITCODE -ne 0) { throw 'S39 standalone C# contract cases failed.' }
    $fixture=Get-Content (Join-Path $container 'fixture.json') -Raw | ConvertFrom-Json
    $receipt=@{result='PASS';powershell_cases=$fixture.cases;supervisor_reader_cases=3;node_stable_entry_cases=2;csharp_contract_cases=6;production_probe_cases=1;unity_compilation='NOT_RUN';real_provider='NOT_RUN';real_codex='NOT_RUN';payload_manifest_sha256=(Get-FileHash -LiteralPath (Join-Path $CanonicalPayloadRoot 'payload-manifest.json')).Hash.ToLowerInvariant()}
    [IO.File]::WriteAllText((Join-Path $container 'result.json'),($receipt | ConvertTo-Json))
    Write-Host ('[EVIDENCE] '+$container.Replace($repository,'<repository-root>'))
} finally { Stop-Transcript | Out-Null; Remove-Module $module -ErrorAction SilentlyContinue }
