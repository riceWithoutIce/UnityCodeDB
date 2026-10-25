#requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$RunDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$run = (Resolve-Path $RunDirectory).Path
$owned = Join-Path $repo '.artifacts/tests/cdb-v0.3-candidate-residual-legacy-review'
if (-not $run.StartsWith($owned + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Run directory outside task artifacts.' }
$wt = Join-Path $repo '.worktrees/cdb-identity-handoff-heartbeat-followup'
$checks = [Collections.Generic.List[string]]::new()
$receipt = [ordered]@{ outcome = 'RUNNING'; started_utc = [DateTime]::UtcNow.ToString('o'); checks = $checks; evidence = 'OFFLINE_EXTRACTED_BODIES_WITH_STUBS'; unity = 'NOT_RUN'; editmode = 'NOT_RUN'; mcp = 'NOT_RUN'; source_hashes = @{} }
function Check([bool]$ok, [string]$label) { if (-not $ok) { throw $label }; $checks.Add($label) }
$prior = [Environment]::GetEnvironmentVariable('CODEDB_EDITOR_DIAGNOSTICS')
try {
    $evidencePath = Join-Path $wt 'com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs'
    $helperPath = Join-Path $wt 'com.rice.ai-codedb/Editor/AICodedbManagerTransitionEvidence.cs'
    $source = [IO.File]::ReadAllText($evidencePath)
    $helper = [IO.File]::ReadAllText($helperPath)
    $tree = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText($source)
    Check (@($tree.GetDiagnostics() | Where-Object Severity -eq Error).Count -eq 0) 'F01 entire changed C# file parses'
    $type = @($tree.GetRoot().DescendantNodes() | Where-Object { $_ -is [Microsoft.CodeAnalysis.CSharp.Syntax.ClassDeclarationSyntax] -and $_.Identifier.ValueText -eq 'AICodedbLifecycleEvidence' })[0]
    $names = @('LogPrefix','SessionStateKey','DiagnosticPublicationEnabled','_managerTransitions','ManagerTransitions','PersistAndEmit','EmitWorkerCheckpoint','RecordManagerClosed')
    $members = @($type.Members | Where-Object {
        if ($_ -is [Microsoft.CodeAnalysis.CSharp.Syntax.FieldDeclarationSyntax]) { $_.Declaration.Variables[0].Identifier.ValueText -in $names }
        elseif ($_ -is [Microsoft.CodeAnalysis.CSharp.Syntax.MethodDeclarationSyntax]) { $_.Identifier.ValueText -in $names }
    })
    Check ($members.Count -eq $names.Count) 'Harness extracts exact factory/checkpoint/gate bodies and close counter wiring'
    $bodies = ($members | ForEach-Object ToFullString) -join "`n"
    $fixture = @'
namespace FIXTURE_NAMESPACE
{
    internal static class SessionState { internal static string Saved; internal static void SetString(string key, string value) { Saved = value; } }
    internal static class JsonUtility { internal static string ToJson(object value) { return System.Text.Json.JsonSerializer.Serialize(value); } }
    internal static class Debug { internal static readonly List<string> Logs = new List<string>(); internal static void Log(string text) { Logs.Add(text); } }
    internal sealed class StubCounter {
        internal int Closed;
        internal void RecordManagerClosed() { Closed++; }
        internal object Capture(string checkpoint) { return new Dictionary<string,string> { { "checkpoint", checkpoint }, { "closed", Closed.ToString() } }; }
    }
    internal static partial class AICodedbLifecycleEvidence {
        private static readonly StubCounter Counter = new StubCounter();
        private static StubCounter GetCounter() { return Counter; }
    }
    public static class GateFixture {
        private static void Assert(bool value, string name) { if (!value) throw new Exception(name); }
        public static void Run(string root, bool enabled) {
            var evidence = AICodedbLifecycleEvidence.ManagerTransitions(root);
            Assert((evidence != null) == enabled, "Factory must respect explicit opt-in");
            AICodedbLifecycleEvidence.RecordManagerClosed();
            AICodedbLifecycleEvidence.PersistAndEmit("fixture");
            Assert(SessionState.Saved.Contains("fixture") && SessionState.Saved.Contains("\"closed\":\"1\""), "Counters and persistence survive disabled publication");
            Assert(Debug.Logs.Count == (enabled ? 2 : 0), "Both full-document log paths gated");
            if (enabled) {
                evidence.Capture("fixture", "Ready", new Dictionary<string,string> { { "state", "Ready" } });
                Assert(System.Threading.SpinWait.SpinUntil(() => !evidence.IsWriting, 5000), "Bounded sidecar completion");
                var files = Directory.GetFiles(Path.Combine(root, "Library/CodeDB/Diagnostics"), "*.json");
                Assert(files.Length == 1, "Explicit diagnostic sidecar retained");
                using (var doc = System.Text.Json.JsonDocument.Parse(File.ReadAllText(files[0]))) {
                    Assert(doc.RootElement.GetProperty("records").GetArrayLength() == 1, "Published record JSON valid");
                }
            } else Assert(!Directory.Exists(root), "Default/off path must not create diagnostics or project directory");
            Environment.SetEnvironmentVariable("CODEDB_EDITOR_DIAGNOSTICS", enabled ? null : "1");
            Assert((AICodedbLifecycleEvidence.ManagerTransitions(root) != null) == enabled, "Opt-in cached for domain");
        }
    }
}
'@
    $values = @($null, '0', 'true', '1')
    for ($i = 0; $i -lt $values.Count; $i++) {
        [Environment]::SetEnvironmentVariable('CODEDB_EDITOR_DIAGNOSTICS', $values[$i])
        $ns = 'CodeDB.F01.Case' + $i
        $compiled = $helper.Replace('Rice.AI.Codedb.Editor', $ns) + "`nnamespace $ns { internal static partial class AICodedbLifecycleEvidence { $bodies } }`n" + $fixture.Replace('FIXTURE_NAMESPACE', $ns)
        Add-Type -TypeDefinition $compiled -Language CSharp
        $fixtureType = ([System.Management.Automation.PSTypeName]($ns + '.GateFixture')).Type
        $fixtureType::Run([string](Join-Path $run ('synthetic-' + $i)), [bool]($values[$i] -ceq '1'))
        Check $true ('F01 actual publication paths: opt-in case ' + $i)
    }
    $manager = [IO.File]::ReadAllText((Join-Path $wt 'com.rice.ai-codedb/Editor/AICodedbManagerWindow.cs'))
    Check ($manager.Contains('if (_transitionEvidence == null || _statusSnapshot == null)')) 'Disabled helper has existing null-safe Manager consumer'
    foreach ($entry in @(
        @{Root=$repo; Path='com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs'},
        @{Root=$repo; Path='com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'},
        @{Root=$wt; Path='com.rice.ai-codedb/Editor/AICodedbLifecycleEvidence.cs'},
        @{Root=$wt; Path='com.rice.ai-codedb/Editor/AICodedbManagerTransitionEvidence.cs'})) {
        $key = $(if ($entry.Root -eq $wt) { 'isolation/' } else { 'primary/' }) + $entry.Path
        $receipt.source_hashes[$key] = (Get-FileHash -LiteralPath (Join-Path $entry.Root $entry.Path) -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $tokens = $null; $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'com.rice.ai-codedb/Tools~/invoke-codedb-manager-action.ps1'), [ref]$tokens, [ref]$errors)
    Check ($errors.Count -eq 0) 'F02 restored PowerShell writer parses without execution'
    $runner = [Microsoft.CodeAnalysis.CSharp.CSharpSyntaxTree]::ParseText([IO.File]::ReadAllText((Join-Path $repo 'com.rice.ai-codedb/Editor/AICodedbProcessRunner.cs')))
    Check (@($runner.GetDiagnostics() | Where-Object Severity -eq Error).Count -eq 0) 'F02 restored C# runner parses'
    $receipt.outcome = 'PASS'
} catch {
    $receipt.outcome = 'FAIL'; $receipt.error = $_.Exception.ToString(); throw
} finally {
    [Environment]::SetEnvironmentVariable('CODEDB_EDITOR_DIAGNOSTICS', $prior)
    $receipt.finished_utc = [DateTime]::UtcNow.ToString('o')
    [IO.File]::WriteAllText((Join-Path $run 'receipt.json'), ($receipt | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    Write-Output ($receipt | ConvertTo-Json -Depth 8)
}
