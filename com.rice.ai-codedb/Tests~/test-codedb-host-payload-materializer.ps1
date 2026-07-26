#requires -Version 5.1

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$embeddedProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $packageRoot "..\.."))
$embeddedPackagePath = Join-Path $embeddedProjectRoot "Packages\com.rice.ai-codedb"
$isEmbeddedLayout = [string]::Equals(
    [System.IO.Path]::GetFullPath($embeddedPackagePath).TrimEnd('\', '/'),
    $packageRoot.TrimEnd('\', '/'),
    [StringComparison]::OrdinalIgnoreCase)
$projectRoot = if ($isEmbeddedLayout) {
    $embeddedProjectRoot
} else {
    [System.IO.Path]::GetFullPath((Join-Path $packageRoot ".."))
}
$materializerPath = Join-Path $packageRoot "Tools~\materialize-codedb-host-payload.ps1"
$canonicalPayloadRoot = Join-Path $packageRoot "Payload~"
$pocRoot = Join-Path $projectRoot "AIWork\.runtime\codedb\materializer-poc"
$runRoot = Join-Path $pocRoot ([guid]::NewGuid().ToString("N"))
$hostRoot = Join-Path $runRoot "fixture"
$trackedHostRoot = Join-Path $runRoot "tracked-host"
$syntheticRoot = Join-Path $runRoot "payloads"
$fixtureGitIndexPath = Join-Path $runRoot "fixture-git-index"
$productionProjectRoot = if ($isEmbeddedLayout) { $projectRoot } else { Join-Path $runRoot "production-project" }
$powershellPath = (Get-Process -Id $PID).Path
$nodePath = (Get-Command node -CommandType Application -ErrorAction Stop).Source
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$markerRelativePath = "AIWork/codedb/.rice-ai-codedb-payload.json"
$fixtureMarkerName = ".rice-ai-codedb-poc-fixture.json"
$junctionPath = $null
$readEscapeJunctionPath = $null
$activeWatchManagerPath = $null
$activeWatchLifecycleId = $null
$activeMcpProcess = $null
$managedTargets = @(
    "AIWork/codedb/codedb-mcp.runtime.example.toml",
    "AIWork/codedb/codedbignore.example",
    "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs",
    "AIWork/codedb/shared/codedb-host-use-gate.mjs",
    "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1",
    "AIWork/codedb/scripts/check-codedb-project-freshness.ps1",
    "AIWork/codedb/scripts/clear-codedb-project-index.ps1",
    "AIWork/codedb/scripts/codedb-project-common.ps1",
    "AIWork/codedb/scripts/emit-codedb-mcp-registration-draft.ps1",
    "AIWork/codedb/scripts/manage-codedb-project-watch.ps1",
    "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1",
    "AIWork/codedb/scripts/prepare-codedb-project-watch-config.ps1",
    "AIWork/codedb/scripts/probe-codedb-project-index.ps1",
    "AIWork/codedb/scripts/probe-codedb-project-text-adapter.ps1",
    "AIWork/codedb/scripts/refresh-codedb-project-if-stale.ps1",
    "AIWork/codedb/scripts/refresh-codedb-project.ps1",
    "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1",
    "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1",
    "AIWork/codedb/scripts/validate-codedb-mcp-project-config.ps1",
    "AIWork/codedb/scripts/verify-codedb-project.ps1",
    "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
)
$sentinelPaths = @(
    $fixtureMarkerName,
    "Assets/BusinessSentinel.txt",
    "Assets/MaterializerFreshnessProbe.cs",
    "Assets/ZMaterializerBoundedReadProbe.cs",
    "Assets/ZMaterializerOutputCeilingProbe.cs",
    "Assets/MaterializerProbe.shader",
    "Assets/Scoped/ScopedProbe.cs",
    "Assets/Scoped/SecondScopedProbe.cs",
    "Assets/Scoped/ScopedProbe.shader",
    "Assets/Outside/OutsideProbe.cs",
    ".codex/config.toml",
    "AIWork/codedb/adoption-decision.md",
    "AIWork/codedb/wrapper/host-compatibility-sentinel.mjs"
)
$trackedHostSentinelPaths = @($sentinelPaths | Where-Object { $_ -ne $fixtureMarkerName })

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-Equal {
    param(
        [AllowNull()]$Actual,
        [AllowNull()]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not [string]::Equals([string]$Actual, [string]$Expected, [StringComparison]::Ordinal)) {
        throw "$Message Expected '$Expected', got '$Actual'."
    }
}

function Assert-LfOnlyFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    Assert-True -Condition ($bytes.Length -gt 0) -Message "$Label is empty."
    Assert-True -Condition ([Array]::IndexOf($bytes, [byte]13) -lt 0) -Message "$Label contains CR bytes."
    Assert-Equal -Actual $bytes[$bytes.Length - 1] -Expected 10 -Message "$Label does not end with one LF byte."
}

function Wait-ForPathState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$Present,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if ((Test-Path -LiteralPath $Path) -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (Test-Path -LiteralPath $Path) -eq $Present
}

function Wait-ForWatchReady {
    param(
        [Parameter(Mandatory = $true)][string]$StatePath,
        [int]$TimeoutMilliseconds = 30000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
            try {
                $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
                $processIds = @($state.coordinator_pid, $state.provider_pid, $state.adapter_worker_pid)
                $processesReady = @($processIds | Where-Object {
                    $processId = 0
                    -not [int]::TryParse([string]$_, [ref]$processId) -or
                        $processId -le 0 -or
                        $null -eq (Get-Process -Id $processId -ErrorAction SilentlyContinue)
                }).Count -eq 0
                if ($state.provider_state -eq "ready" -and
                    $state.adapter_state -in @("watching", "pending", "building") -and
                    $state.adapter_worker_state -eq "ready" -and
                    $processesReady) {
                    return $true
                }
            } catch {
                # The coordinator publishes state atomically; retry any transient read race.
            }
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return $false
}

function Get-HostUseLeasePaths {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId
    )

    $leaseRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer\host-use-leases"
    if (-not (Test-Path -LiteralPath $leaseRoot -PathType Container)) {
        return @()
    }
    return @(Get-ChildItem -LiteralPath $leaseRoot -Force -File | Where-Object {
        $_.Name -like "$Owner-$ProcessId-*.json"
    } | Sort-Object Name | ForEach-Object { $_.FullName })
}

function Wait-ForHostUseLease {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("mcp", "watcher")][string]$Owner,
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][bool]$Present,
        [int]$TimeoutMilliseconds = 5000
    )

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMilliseconds)
    do {
        if ((@(Get-HostUseLeasePaths -Owner $Owner -ProcessId $ProcessId).Count -gt 0) -eq $Present) {
            return $true
        }
        Start-Sleep -Milliseconds 25
    } while ([DateTime]::UtcNow -lt $deadline)
    return (@(Get-HostUseLeasePaths -Owner $Owner -ProcessId $ProcessId).Count -gt 0) -eq $Present
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Invoke-PowerShellAction {
    param([Parameter(Mandatory = $true)][scriptblock]$Action)

    Push-Location -LiteralPath $hostRoot
    try {
        $global:LASTEXITCODE = 0
        try {
            $output = @(& $Action 2>&1 3>&1 4>&1 5>&1 6>&1)
            $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { $LASTEXITCODE }
        } catch {
            $output = @($_)
            $exitCode = 1
        }
        $lines = @($output | ForEach-Object { $_.ToString() })
        return [pscustomobject]@{
            ExitCode = $exitCode
            Lines = $lines
            Text = $lines -join [Environment]::NewLine
        }
    } finally {
        Pop-Location
    }
}

function Get-LastJsonObject {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $jsonLines = @($Result.Lines | Where-Object { $_.TrimStart().StartsWith("{") })
    if ($jsonLines.Count -eq 0) {
        throw "$Label returned no structured JSON.`n$($Result.Text)"
    }
    return $jsonLines[-1] | ConvertFrom-Json
}

function Get-TomlSectionValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $currentSection = ""
    $values = @()
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[([^\]]+)\]\s*(?:#.*)?$') {
            $currentSection = $Matches[1]
            continue
        }
        if ([string]::Equals($currentSection, $Section, [StringComparison]::OrdinalIgnoreCase) -and
            $line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*$' -and
            [string]::Equals($Matches[1], $Key, [StringComparison]::OrdinalIgnoreCase)) {
            $values += $Matches[2]
        }
    }
    if ($values.Count -ne 1) {
        throw "Expected exactly one [$Section].$Key value in $Path, found $($values.Count)."
    }
    return $values[0]
}

function New-FixtureProviderExecutable {
    param([Parameter(Mandatory = $true)][string]$Path)

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    $source = @'
using System;
using System.IO;
using System.Text.RegularExpressions;

public static class CodedbMaterializerFixtureProvider
{
    private static readonly Regex IdPattern = new Regex("\"id\"\\s*:\\s*(\\d+)", RegexOptions.Compiled);
    private static readonly Regex StorageDirPattern = new Regex(@"(?m)^\s*dir\s*=\s*""([^""]+)""\s*$", RegexOptions.Compiled);

    public static int Main(string[] args)
    {
        if (args.Length > 0 && String.Equals(args[0], "index", StringComparison.Ordinal))
        {
            return RunIndex(args);
        }
        if (args.Length > 0 && String.Equals(args[0], "tool", StringComparison.Ordinal))
        {
            return RunTool(args);
        }
        if (args.Length != 4 ||
            !String.Equals(args[0], "--config", StringComparison.Ordinal) ||
            !String.Equals(args[2], "mcp", StringComparison.Ordinal))
        {
            Console.Error.WriteLine("Unsupported fixture provider arguments.");
            return 2;
        }

        string line;
        while ((line = Console.ReadLine()) != null)
        {
            if (line.IndexOf("\"method\":\"initialize\"", StringComparison.Ordinal) >= 0)
            {
                Respond(line, "{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{},\"serverInfo\":{\"name\":\"codedb-fixture-provider\",\"version\":\"0.1.0\"}}");
            }
            else if (line.IndexOf("\"method\":\"tools/list\"", StringComparison.Ordinal) >= 0)
            {
                Respond(line, "{\"tools\":[{\"name\":\"codedb_text_search\",\"description\":\"Fixture provider search\",\"inputSchema\":{\"type\":\"object\"}}]}");
            }
        }
        return 0;
    }

    private static int RunIndex(string[] args)
    {
        int rootIndex = Array.IndexOf(args, "--root");
        int configIndex = Array.IndexOf(args, "--config");
        bool noWatch = Array.IndexOf(args, "--no-watch") >= 0;
        if (rootIndex < 0 || rootIndex + 1 >= args.Length ||
            configIndex < 0 || configIndex + 1 >= args.Length ||
            !noWatch)
        {
            Console.Error.WriteLine("Fixture provider index requires --root, --config, and --no-watch.");
            return 2;
        }

        string root = Path.GetFullPath(args[rootIndex + 1]);
        string configPath = Path.GetFullPath(args[configIndex + 1]);
        Match storageMatch = StorageDirPattern.Match(File.ReadAllText(configPath));
        if (!storageMatch.Success)
        {
            Console.Error.WriteLine("Fixture provider config has no storage directory.");
            return 2;
        }

        string storageDir = storageMatch.Groups[1].Value.Replace('/', Path.DirectorySeparatorChar);
        string indexRoot = Path.IsPathRooted(storageDir)
            ? Path.GetFullPath(storageDir)
            : Path.GetFullPath(Path.Combine(root, storageDir));
        Directory.CreateDirectory(indexRoot);
        long createdUnixMs = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;
        File.WriteAllText(
            Path.Combine(indexRoot, "manifest.json"),
            "{\"schema_version\":1,\"fixture\":true,\"no_watch\":true,\"created_unix_ms\":" + createdUnixMs + "}\n");
        DirectoryInfo providerRoot = Directory.GetParent(indexRoot);
        if (providerRoot == null)
        {
            Console.Error.WriteLine("Fixture provider could not resolve its runtime root.");
            return 2;
        }
        string logsRoot = Path.Combine(providerRoot.FullName, "logs");
        Directory.CreateDirectory(logsRoot);
        File.AppendAllText(Path.Combine(logsRoot, "fixture-index-invocations.txt"), "index\n");
        Console.WriteLine("[FIXTURE PROVIDER] indexed --no-watch");
        return 0;
    }

    private static int RunTool(string[] args)
    {
        int configIndex = Array.IndexOf(args, "--config");
        if (configIndex < 0 || configIndex + 1 >= args.Length)
        {
            Console.Error.WriteLine("Fixture provider tool call is missing --config.");
            return 2;
        }
        Console.Error.WriteLine("codebase-mcp timing total: 0.007s");
        Console.WriteLine("[FIXTURE PROVIDER] active_config=" + Path.GetFileName(args[configIndex + 1]));
        string toolName = args.Length > 1 ? args[1] : String.Empty;
        string toolArguments = args.Length > 2 ? args[2] : String.Empty;
        if (String.Equals(toolName, "codedb_status", StringComparison.Ordinal))
        {
            Console.WriteLine("ready");
        }
        else if (String.Equals(toolName, "codedb_text_search", StringComparison.Ordinal))
        {
            if (toolArguments.IndexOf("CODEDB_SCOPE_CONTRACT", StringComparison.Ordinal) >= 0)
            {
                Console.WriteLine("[FIXTURE PROVIDER] args=" + toolArguments);
                Console.WriteLine("4 results for 'CODEDB_SCOPE_CONTRACT' in 4 files:");
                Console.WriteLine("  Assets/Scoped/ScopedProbe.cs");
                Console.WriteLine("    L1: // CODEDB_SCOPE_CONTRACT");
                Console.WriteLine("  Assets/Outside/OutsideProbe.cs");
                Console.WriteLine("    L1: // CODEDB_SCOPE_CONTRACT");
                Console.WriteLine("  Assets/Scoped/ScopedProbe.shader");
                Console.WriteLine("    L2: // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT");
                Console.WriteLine("  Assets/Scoped/SecondScopedProbe.cs");
                Console.WriteLine("    L1: // CODEDB_SCOPE_CONTRACT");
            }
            else
            {
                Console.WriteLine("[HIT] Assets/MaterializerFreshnessProbe.cs:1 CodedbMaterializerFreshnessProbe CODEDB_MATERIALIZER_PROVIDER_PROBE");
            }
        }
        else if (String.Equals(toolName, "codedb_search", StringComparison.Ordinal) &&
            toolArguments.IndexOf("CODEDB_SEARCH_CONTRACT", StringComparison.Ordinal) >= 0)
        {
            Console.WriteLine("3 results for 'CODEDB_SEARCH_CONTRACT':");
            Console.WriteLine("  Assets/Outside/OutsideProbe.cs:1-1  [score=1.000, text]");
            Console.WriteLine("    // CODEDB_SEARCH_CONTRACT");
            Console.WriteLine("  Assets/Scoped/ScopedProbe.cs:1-2  [score=0.900, text]");
            Console.WriteLine("    // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT");
            Console.WriteLine("  Assets/Scoped/ScopedProbe.shader:1-3  [score=0.800, text]");
            Console.WriteLine("    // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT");
        }
        else if (String.Equals(toolName, "codedb_find", StringComparison.Ordinal) &&
            toolArguments.IndexOf("CODEDB_FIND_CONTRACT", StringComparison.Ordinal) >= 0)
        {
            Console.WriteLine("1. Assets/Outside/OutsideProbe.cs (score: 100.00)");
            Console.WriteLine("2. Assets/Scoped/SecondScopedProbe.cs (score: 90.00)");
        }
        else if (String.Equals(toolName, "codedb_read", StringComparison.Ordinal))
        {
            int rootIndex = Array.IndexOf(args, "--root");
            if (rootIndex < 0 || rootIndex + 1 >= args.Length)
            {
                Console.Error.WriteLine("Fixture provider read is missing --root.");
                return 2;
            }
            string sourcePath = Path.Combine(Path.GetFullPath(args[rootIndex + 1]), "Assets", "MaterializerFreshnessProbe.cs");
            Console.WriteLine(File.ReadAllText(sourcePath));
        }
        return 0;
    }

    private static void Respond(string request, string resultJson)
    {
        Match match = IdPattern.Match(request);
        if (!match.Success)
        {
            return;
        }
        Console.WriteLine("{\"jsonrpc\":\"2.0\",\"id\":" + match.Groups[1].Value + ",\"result\":" + resultJson + "}");
        Console.Out.Flush();
    }
}
'@
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $Path -OutputType ConsoleApplication -ErrorAction Stop | Out-Null
    Assert-True -Condition (Test-Path -LiteralPath $Path -PathType Leaf) -Message "Fixture provider executable was not generated: $Path"
}

function Invoke-AdapterWorkerRequest {
    param(
        [Parameter(Mandatory = $true)][string]$WorkerPath,
        [Parameter(Mandatory = $true)][string]$BuilderPath,
        [Parameter(Mandatory = $true)]$Request
    )

    $harnessPath = Join-Path $runRoot "adapter-worker-probe.mjs"
    if (-not (Test-Path -LiteralPath $harnessPath -PathType Leaf)) {
        $harness = @'
import { spawn } from "node:child_process";
import fs from "node:fs";
import readline from "node:readline";

const [workerPath, builderPath, requestPath] = process.argv.slice(2);
if (!workerPath || !builderPath || !requestPath) {
  throw new Error("Worker probe arguments are incomplete.");
}
const request = fs.readFileSync(requestPath, "utf8");

const command = process.platform === "win32" ? "powershell.exe" : "pwsh";
const child = spawn(command, [
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", workerPath,
  "-BuilderPath", builderPath
], { stdio: ["pipe", "pipe", "pipe"], windowsHide: true });
const lines = readline.createInterface({ input: child.stdout });
let ready = null;
let response = null;
let stderr = "";
const timer = setTimeout(() => {
  stderr += "Worker probe timed out.";
  child.kill();
}, 90000);

child.stderr.on("data", (chunk) => { stderr += String(chunk); });
lines.on("line", (rawLine) => {
  let message;
  try {
    message = JSON.parse(rawLine.replace(/^\uFEFF/, ""));
  } catch {
    return;
  }
  if (message.type === "ready" && !ready) {
    ready = message;
    child.stdin.write(`${request}\n`);
    return;
  }
  if ((message.type === "build_completed" || message.type === "build_failed") && !response) {
    response = message;
    child.stdin.end();
  }
});
child.once("error", (error) => {
  stderr += error.message;
});
child.once("exit", (code) => {
  clearTimeout(timer);
  if (code !== 0 || !ready || !response || stderr.trim()) {
    process.stderr.write(stderr || `Worker probe exited with code ${code}.`);
    process.exitCode = 1;
    return;
  }
  process.stdout.write(`${JSON.stringify({ ready, response })}\n`);
});
'@
        Write-Utf8File -Path $harnessPath -Content $harness
    }

    $requestPath = Join-Path $runRoot "adapter-worker-request.json"
    Write-Utf8File -Path $requestPath -Content ($Request | ConvertTo-Json -Compress -Depth 8)
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$harnessPath`" `"$WorkerPath`" `"$BuilderPath`" `"$requestPath`""
    $startInfo.WorkingDirectory = $hostRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(100000)) {
            $process.Kill()
            throw "Adapter worker protocol probe timed out."
        }
        $stdout = $stdoutTask.Result.Trim()
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Adapter worker protocol probe exited with code $($process.ExitCode).`n$stderr"
        }
        if ([string]::IsNullOrWhiteSpace($stdout)) {
            throw "Adapter worker protocol probe returned no result."
        }
        return $stdout | ConvertFrom-Json
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Get-RelativeFilePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    return $fullPath.Substring($fullRoot.Length + 1).Replace('\', '/')
}

function Get-FileSnapshot {
    param([Parameter(Mandatory = $true)][string]$Root)

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return "[]"
    }

    $rows = @(Get-ChildItem -LiteralPath $Root -Recurse -Force -File | Sort-Object FullName | ForEach-Object {
        [ordered]@{
            path = Get-RelativeFilePath -Root $Root -Path $_.FullName
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            length = $_.Length
            last_write_ticks = $_.LastWriteTimeUtc.Ticks
            attributes = [int]$_.Attributes
        }
    })
    return ($rows | ConvertTo-Json -Depth 5 -Compress)
}

function Get-PathFromRelative {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    return Join-Path $Root $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

function Assert-NoReparseAncestors {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $current = $fullPath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "POC cleanup path traverses a reparse point: $current"
            }
        }
        if ([string]::Equals($current, $fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent)) {
            throw "POC cleanup path is outside its project root: $fullPath"
        }
        $parentIsRoot = [string]::Equals($parent, $fullRoot, [StringComparison]::OrdinalIgnoreCase)
        $parentIsInside = $parent.StartsWith($fullRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
        if (-not ($parentIsRoot -or $parentIsInside)) {
            throw "POC cleanup path is outside its project root: $fullPath"
        }
        $current = $parent
    }
}

function Assert-NoReparseTree {
    param([Parameter(Mandatory = $true)][string]$Root)

    $pending = New-Object System.Collections.Generic.Stack[string]
    $pending.Push([System.IO.Path]::GetFullPath($Root))
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $current -Force)) {
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "POC cleanup tree contains a reparse point: $($item.FullName)"
            }
            if ($item.PSIsContainer) {
                $pending.Push($item.FullName)
            }
        }
    }
}

function New-TestHost {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$RunId = (Split-Path -Leaf (Split-Path -Parent $Root))
    )

    New-Item -ItemType Directory -Force -Path (Join-Path $Root "Assets") | Out-Null
    $fixtureMarker = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        purpose = "host-payload-materializer-poc"
        run_id = $RunId
    }
    Write-Utf8File -Path (Join-Path $Root $fixtureMarkerName) -Content (($fixtureMarker | ConvertTo-Json) + "`n")
    Write-Utf8File -Path (Join-Path $Root "Packages\manifest.json") -Content "{}`n"
    Write-Utf8File -Path (Join-Path $Root "ProjectSettings\ProjectVersion.txt") -Content "m_EditorVersion: 2022.3.62f1`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\BusinessSentinel.txt") -Content "business sentinel`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\MaterializerFreshnessProbe.cs") -Content @"
public static class CodedbMaterializerFreshnessProbe {
    public const string Token = "CODEDB_MATERIALIZER_PROVIDER_PROBE";
    public const string Outside = "CODEDB_BOUNDED_READ_EXCLUDED";
}
"@
    $boundedReadLines = @(1..250 | ForEach-Object { "// CODEDB_BOUNDED_LINE_{0:D3}" -f $_ })
    Write-Utf8File `
        -Path (Join-Path $Root "Assets\ZMaterializerBoundedReadProbe.cs") `
        -Content (($boundedReadLines -join "`n") + "`n")
    Write-Utf8File `
        -Path (Join-Path $Root "Assets\ZMaterializerOutputCeilingProbe.cs") `
        -Content ("// " + ("x" * 70000) + "`n")
    Write-Utf8File -Path (Join-Path $Root "Assets\MaterializerProbe.shader") -Content "Shader `"Hidden/Rice/MaterializerProbe`" {`n    // CODEDB_MATERIALIZER_ADAPTER_PROBE`n}`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Scoped\ScopedProbe.cs") -Content "// CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT`npublic static class ScopedProbe { }`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Scoped\SecondScopedProbe.cs") -Content "// CODEDB_SCOPE_CONTRACT CODEDB_FIND_CONTRACT`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Scoped\ScopedProbe.shader") -Content "Shader `"Hidden/Rice/ScopedProbe`" {`n    // CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT`n}`n"
    Write-Utf8File -Path (Join-Path $Root "Assets\Outside\OutsideProbe.cs") -Content "// CODEDB_SCOPE_CONTRACT CODEDB_SEARCH_CONTRACT CODEDB_FIND_CONTRACT`n"
    Write-Utf8File -Path (Join-Path $Root ".codex\config.toml") -Content @"
# config sentinel
[mcp_servers.codedb-fixture]
command = "node"
args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]
startup_timeout_sec = 120
"@
    Write-Utf8File -Path (Join-Path $Root "AIWork\codedb\adoption-decision.md") -Content "host-owned documentation`n"
    Write-Utf8File -Path (Join-Path $Root "AIWork\codedb\wrapper\host-compatibility-sentinel.mjs") -Content "// host compatibility sentinel`n"
}

function Invoke-TrackedHostGit {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git -c core.autocrlf=false -C $Root @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Tracked-host Git command failed: git $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
    }
    return $output
}

function New-TrackedHostTestProject {
    param([Parameter(Mandatory = $true)][string]$Root)

    New-TestHost -Root $Root
    Remove-Item -LiteralPath (Join-Path $Root $fixtureMarkerName) -Force
    Write-Utf8File -Path (Join-Path $Root ".gitignore") -Content "/AIWork/.runtime/`n"
    foreach ($relativePath in $managedTargets) {
        $source = Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $relativePath
        $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }

    $null = Invoke-TrackedHostGit -Root $Root -Arguments @("init", "--quiet")
    $null = Invoke-TrackedHostGit -Root $Root -Arguments @("config", "core.autocrlf", "false")
    $null = Invoke-TrackedHostGit -Root $Root -Arguments @("add", "--all")
    $null = Invoke-TrackedHostGit -Root $Root -Arguments @(
        "-c", "user.name=CodeDB Fixture",
        "-c", "user.email=codedb-fixture@example.invalid",
        "commit", "--quiet", "-m", "Initialize tracked host fixture"
    )
}

function New-TrackedHostAuthorization {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [Parameter(Mandatory = $true)][ValidateSet("Sync", "Remove")][string]$Action,
        [hashtable]$Overrides = @{}
    )

    $manifestPath = Join-Path $PayloadRoot "payload-manifest.json"
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $gitHead = [string](@(Invoke-TrackedHostGit -Root $Root -Arguments @("rev-parse", "HEAD"))[0])
    $authorizationId = [guid]::NewGuid().ToString("N")
    $authorization = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        purpose = "tracked-host-payload-mutation"
        authorization_id = $authorizationId
        project_root = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
        git_head = $gitHead.Trim().ToLowerInvariant()
        action = $Action
        package_version = [string]$manifest.package_version
        payload_version = [string]$manifest.payload_version
        payload_sequence = [int]$manifest.payload_sequence
        payload_manifest_sha256 = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
        target_count = @($manifest.files).Count
        acknowledgement = "I authorize com.rice.ai-codedb to mutate only its audited host payload scope."
    }
    foreach ($key in $Overrides.Keys) {
        if ($authorization.Contains($key)) {
            $authorization[$key] = $Overrides[$key]
        } else {
            $authorization.Add($key, $Overrides[$key])
        }
    }

    $authorizationPath = Join-Path $Root "AIWork\.runtime\codedb\payload-materializer\authorizations\$authorizationId.json"
    Write-Utf8File -Path $authorizationPath -Content (($authorization | ConvertTo-Json -Depth 5) + "`n")
    return $authorizationPath
}

function Invoke-Materializer {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$PayloadRoot,
        [int]$TestFailAfterMutation = 0,
        [int]$TestCrashAfterMutation = 0,
        [switch]$ConfirmLegacyMcpStopped,
        [switch]$OmitPocFixture,
        [string]$TrackedHostAuthorizationPath,
        [string]$GitIndexFile,
        [string]$TargetProjectRoot = $hostRoot
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $powershellPath
    $legacyConfirmationArgument = if ($ConfirmLegacyMcpStopped) { " -ConfirmLegacyMcpStopped" } else { "" }
    $fixtureArgument = if ($OmitPocFixture) { "" } else { " -PocFixture" }
    $authorizationArgument = if ([string]::IsNullOrWhiteSpace($TrackedHostAuthorizationPath)) { "" } else { " -TrackedHostAuthorizationPath `"$TrackedHostAuthorizationPath`"" }
    $startInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializerPath`" -Action $Action -ProjectRoot `"$TargetProjectRoot`" -PayloadRoot `"$PayloadRoot`"$fixtureArgument$authorizationArgument -TestFailAfterMutation $TestFailAfterMutation -TestCrashAfterMutation $TestCrashAfterMutation$legacyConfirmationArgument"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    if (-not [string]::IsNullOrWhiteSpace($GitIndexFile)) {
        $startInfo.EnvironmentVariables["GIT_INDEX_FILE"] = [System.IO.Path]::GetFullPath($GitIndexFile)
    }
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $null = $process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.Result.TrimEnd("`r", "`n")
    $stderr = $stderrTask.Result.TrimEnd("`r", "`n")
    $exitCode = $process.ExitCode
    $process.Dispose()
    $rawOutput = @($stdout, $stderr | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($rawOutput | ForEach-Object { $_.ToString() })
        Text = ($rawOutput | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    }
}

function Invoke-FixtureIndexGit {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $previousIndex = [Environment]::GetEnvironmentVariable("GIT_INDEX_FILE", [EnvironmentVariableTarget]::Process)
    try {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $fixtureGitIndexPath, [EnvironmentVariableTarget]::Process)
        $output = @(& git -c core.autocrlf=false -C $projectRoot @Arguments 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Fixture Git index command failed: git $($Arguments -join ' ')`n$($output -join [Environment]::NewLine)"
        }
        return $output
    } finally {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $previousIndex, [EnvironmentVariableTarget]::Process)
    }
}

function Get-ProjectGitPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return Get-RelativeFilePath -Root $projectRoot -Path $Path
}

function Assert-Result {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Result.ExitCode -ne $ExitCode) {
        throw "$Label returned $($Result.ExitCode), expected $ExitCode.`n$($Result.Text)"
    }
}

function Assert-FreshnessResult {
    param(
        [Parameter(Mandatory = $true)]$Result,
        [Parameter(Mandatory = $true)][ValidateSet("OK", "STALE", "UNKNOWN")][string]$OverallState,
        [Parameter(Mandatory = $true)][ValidateSet("OK", "STALE", "UNKNOWN")][string]$ProviderState,
        [Parameter(Mandatory = $true)][ValidateSet("OK", "STALE", "UNKNOWN")][string]$AdapterState,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-Result -Result $Result -ExitCode 0 -Label $Label
    $overallMarker = switch ($OverallState) {
        "OK" { "[OK] codedb freshness check passed." }
        "STALE" { "[STALE] codedb freshness check found stale index data." }
        "UNKNOWN" { "[UNKNOWN] codedb freshness check could not determine full freshness." }
    }
    foreach ($expected in @(
        $overallMarker,
        "Provider index: $ProviderState -",
        "Shader adapter: $AdapterState -",
        "Policy: this check is read-only."
    )) {
        Assert-True -Condition ($Result.Text.Contains($expected)) -Message "$Label is missing '$expected'."
    }
}

function Get-FixtureIndexInvocationCount {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 0
    }
    return @(Get-Content -LiteralPath $Path | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
}

function Invoke-WrapperRpc {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)]$Request
    )

    $requestLine = $Request | ConvertTo-Json -Compress -Depth 8
    $Process.StandardInput.WriteLine($requestLine)
    $Process.StandardInput.Flush()
    $responseLine = $Process.StandardOutput.ReadLine()
    if ([string]::IsNullOrWhiteSpace($responseLine)) {
        throw "Materialized wrapper closed without responding to request id $($Request.id)."
    }
    $response = $responseLine | ConvertFrom-Json
    if ($null -ne $response.PSObject.Properties["error"]) {
        throw "Materialized wrapper returned an RPC error for request id $($Request.id): $($response.error.message)"
    }
    return $response
}

function Invoke-WrapperRpcError {
    param(
        [Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory = $true)]$Request
    )

    $requestLine = $Request | ConvertTo-Json -Compress -Depth 8
    $Process.StandardInput.WriteLine($requestLine)
    $Process.StandardInput.Flush()
    $responseLine = $Process.StandardOutput.ReadLine()
    if ([string]::IsNullOrWhiteSpace($responseLine)) {
        throw "Materialized wrapper closed without responding to expected-error request id $($Request.id)."
    }
    $response = $responseLine | ConvertFrom-Json
    if ($null -eq $response.PSObject.Properties["error"]) {
        throw "Materialized wrapper accepted request id $($Request.id), but an RPC error was expected."
    }
    return $response
}

function Get-WrapperTiming {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $matches = [regex]::Matches($Text, '(?m)^\[TIMING\] (?<json>\{.*\})\s*$')
    if ($matches.Count -ne 1) {
        throw "$Label expected exactly one machine-readable timing footer, found $($matches.Count)."
    }
    try {
        return $matches[0].Groups["json"].Value | ConvertFrom-Json
    } catch {
        throw "$Label timing footer is not valid JSON: $($_.Exception.Message)"
    }
}

function Invoke-WrapperWatchProbe {
    param(
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$WaitForCoordinatorStatePath,
        [string]$WaitForWatchMarkerPath
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$WrapperPath`" --root `"$Root`""
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $null = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 101
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        if ($WaitForCoordinatorStatePath -and
            -not (Wait-ForWatchReady -StatePath $WaitForCoordinatorStatePath)) {
            throw "Materialized wrapper did not start automatic watch within 30 seconds."
        }
        if ($WaitForWatchMarkerPath -and
            -not (Wait-ForPathState -Path $WaitForWatchMarkerPath -Present $true -TimeoutMilliseconds 30000)) {
            throw "Materialized wrapper did not publish its automatic watch marker within 30 seconds."
        }
        $search = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 102
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_search"
                arguments = [ordered]@{ query = "FixtureProviderProbe"; language = "CSharp"; limit = 1 }
            }
        })
        $status = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 103
            method = "tools/call"
            params = [ordered]@{ name = "codedb_status"; arguments = [ordered]@{} }
        })
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(10000)) {
            $process.Kill()
            throw "Materialized wrapper watch probe did not exit after stdin closed."
        }
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Materialized wrapper watch probe exited with code $($process.ExitCode).`n$stderr"
        }
        return [pscustomobject]@{
            SearchText = [string]$search.result.content[0].text
            StatusText = [string]$status.result.content[0].text
        }
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Invoke-WrapperToolProbe {
    param(
        [Parameter(Mandatory = $true)][string]$WrapperPath,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ToolName,
        [Parameter(Mandatory = $true)]$Arguments,
        [string]$WaitForCoordinatorStatePath,
        [string]$WaitForWatchMarkerPath
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "`"$WrapperPath`" --root `"$Root`""
    $startInfo.WorkingDirectory = $Root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $false
    try {
        $null = $process.Start()
        $started = $true
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $null = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 201
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        if ($WaitForCoordinatorStatePath -and
            -not (Wait-ForWatchReady -StatePath $WaitForCoordinatorStatePath)) {
            throw "Materialized wrapper tool probe did not observe watcher ready within 30 seconds."
        }
        if ($WaitForWatchMarkerPath -and
            -not (Wait-ForPathState -Path $WaitForWatchMarkerPath -Present $true -TimeoutMilliseconds 30000)) {
            throw "Materialized wrapper tool probe did not observe the watch marker within 30 seconds."
        }
        $response = Invoke-WrapperRpc -Process $process -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 202
            method = "tools/call"
            params = [ordered]@{ name = $ToolName; arguments = $Arguments }
        })
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(10000)) {
            $process.Kill()
            throw "Materialized wrapper tool probe did not exit after stdin closed."
        }
        $stderr = $stderrTask.Result.Trim()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            throw "Materialized wrapper tool probe exited with code $($process.ExitCode).`n$stderr"
        }
        return [string]$response.result.content[0].text
    } finally {
        if ($started -and -not $process.HasExited) {
            $process.Kill()
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

function Assert-NoMaterializerResidue {
    $runtimePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer"
    Assert-True -Condition (-not (Test-Path -LiteralPath $runtimePath)) -Message "Materializer runtime residue remains: $runtimePath"
}

function Get-SentinelSnapshot {
    param(
        [string]$Root = $hostRoot,
        [string[]]$Paths = $sentinelPaths
    )

    $snapshot = @{}
    foreach ($relativePath in $Paths) {
        $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        $item = Get-Item -LiteralPath $path -Force
        $snapshot[$relativePath] = [pscustomobject]@{
            Sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
            LastWriteTicks = $item.LastWriteTimeUtc.Ticks
        }
    }
    return $snapshot
}

function Assert-SentinelsUnchanged {
    param(
        [Parameter(Mandatory = $true)]$ExpectedSnapshot,
        [string]$Root = $hostRoot,
        [string[]]$Paths = $sentinelPaths
    )

    foreach ($relativePath in $Paths) {
        $path = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        Assert-True -Condition (Test-Path -LiteralPath $path -PathType Leaf) -Message "Sentinel was removed: $relativePath"
        $item = Get-Item -LiteralPath $path -Force
        Assert-Equal -Actual (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -Expected $ExpectedSnapshot[$relativePath].Sha256 -Message "Sentinel hash changed: $relativePath."
        Assert-Equal -Actual $item.LastWriteTimeUtc.Ticks -Expected $ExpectedSnapshot[$relativePath].LastWriteTicks -Message "Sentinel timestamp changed: $relativePath."
    }
}

function Copy-CanonicalFilesToHost {
    foreach ($relativePath in $managedTargets) {
        $source = Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $relativePath
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
}

function Assert-CanonicalFilesInstalled {
    param([string]$Root = $hostRoot)

    foreach ($relativePath in $managedTargets) {
        $source = Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $relativePath
        $target = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        Assert-True -Condition (Test-Path -LiteralPath $target -PathType Leaf) -Message "Managed target is missing: $relativePath"
        Assert-Equal -Actual (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -Expected (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -Message "Managed target hash mismatch: $relativePath."
    }
}

function Assert-CanonicalFilesRemoved {
    param([string]$Root = $hostRoot)

    foreach ($relativePath in $managedTargets) {
        Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $Root -RelativePath $relativePath))) -Message "Managed target remains after removal: $relativePath"
    }
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $Root -RelativePath $markerRelativePath))) -Message "Ownership marker remains after removal."
}

function New-SyntheticPayload {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$PayloadVersion,
        [Parameter(Mandatory = $true)]$Entries
    )

    New-Item -ItemType Directory -Force -Path $Root | Out-Null
    $manifestFiles = New-Object System.Collections.Generic.List[object]
    foreach ($relativePath in @($Entries.Keys | Sort-Object)) {
        $sourcePath = Get-PathFromRelative -Root $Root -RelativePath $relativePath
        Write-Utf8File -Path $sourcePath -Content ([string]$Entries[$relativePath])
        $manifestFiles.Add([ordered]@{
            source = $relativePath
            target = $relativePath
            sha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }
    $manifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = "0.1.0-test"
        payload_version = $PayloadVersion
        payload_sequence = if ($PayloadVersion -eq "test.1") { 1 } else { 2 }
        retired_targets = @()
        files = $manifestFiles.ToArray()
    }
    Write-Utf8File -Path (Join-Path $Root "payload-manifest.json") -Content (($manifest | ConvertTo-Json -Depth 8) + "`n")
    return $Root
}

function Clear-ManagedTestState {
    foreach ($relativePath in $managedTargets + @($markerRelativePath)) {
        $path = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        if (Test-Path -LiteralPath $path) {
            Set-ItemProperty -LiteralPath $path -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $path -Recurse -Force
        }
    }
}

$packageSnapshotBefore = $null
$sentinelSnapshot = $null
try {
    Assert-True -Condition (Test-Path -LiteralPath $materializerPath -PathType Leaf) -Message "Materializer script is missing."
    Assert-True -Condition (Test-Path -LiteralPath $canonicalPayloadRoot -PathType Container) -Message "Canonical payload root is missing."
    New-TestHost -Root $hostRoot
    if (-not $isEmbeddedLayout) {
        New-TestHost -Root $productionProjectRoot
        Remove-Item -LiteralPath (Join-Path $productionProjectRoot $fixtureMarkerName) -Force
    }
    $packageSnapshotBefore = Get-FileSnapshot -Root $packageRoot
    $sentinelSnapshot = Get-SentinelSnapshot

    $productionHostBefore = Get-FileSnapshot -Root (Join-Path $productionProjectRoot "AIWork\codedb")
    $productionAuthorizationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot -OmitPocFixture
    Assert-Result -Result $productionAuthorizationGuard -ExitCode 4 -Label "Production authorization guard"
    Assert-True -Condition ($productionAuthorizationGuard.Text.Contains("requires explicit -PocFixture or -TrackedHostAuthorizationPath")) -Message "Production authorization guard did not identify the missing explicit mode."
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $productionProjectRoot "AIWork\codedb")) -Expected $productionHostBefore -Message "Production authorization guard changed the production host payload."
    $productionFixtureGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $productionProjectRoot
    Assert-Result -Result $productionFixtureGuard -ExitCode 4 -Label "Production fixture guard"
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $productionProjectRoot "AIWork\codedb")) -Expected $productionHostBefore -Message "Production fixture guard changed the production host payload."
    Write-Host "[OK] Missing authorization and fixture mode both rejected the production project root."

    $junctionRunId = [guid]::NewGuid().ToString("N")
    $junctionTargetRoot = Join-Path $runRoot "junction-target"
    New-TestHost -Root (Join-Path $junctionTargetRoot "fixture") -RunId $junctionRunId
    $junctionPath = Join-Path $pocRoot $junctionRunId
    New-Item -ItemType Junction -Path $junctionPath -Target $junctionTargetRoot | Out-Null
    $junctionProjectRoot = Join-Path $junctionPath "fixture"
    $junctionBefore = Get-FileSnapshot -Root (Join-Path $junctionTargetRoot "fixture")
    $junctionGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $junctionProjectRoot
    Assert-Result -Result $junctionGuard -ExitCode 2 -Label "Junction ancestor guard"
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $junctionTargetRoot "fixture")) -Expected $junctionBefore -Message "Junction ancestor guard changed its target."
    [System.IO.Directory]::Delete($junctionPath)
    $junctionPath = $null
    Write-Host "[OK] POC mutation guard rejected a fixture below a junction ancestor."

    New-TrackedHostTestProject -Root $trackedHostRoot
    $trackedManagedRoot = Join-Path $trackedHostRoot "AIWork\codedb"
    $trackedSentinelSnapshot = Get-SentinelSnapshot -Root $trackedHostRoot -Paths $trackedHostSentinelPaths
    $trackedManagedBefore = Get-FileSnapshot -Root $trackedManagedRoot

    $missingTrackedAuthorization = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture
    Assert-Result -Result $missingTrackedAuthorization -ExitCode 4 -Label "Missing tracked-host authorization"
    Assert-Equal -Actual (Get-FileSnapshot -Root $trackedManagedRoot) -Expected $trackedManagedBefore -Message "Missing tracked-host authorization changed managed files."

    $validSyncAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    $readOnlyAuthorization = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validSyncAuthorization
    Assert-Result -Result $readOnlyAuthorization -ExitCode 4 -Label "Read-only authorization misuse"
    Assert-True -Condition ($readOnlyAuthorization.Text.Contains("valid only for Sync or Remove")) -Message "Read-only authorization misuse did not fail explicitly."

    $ambiguousAuthorization = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -TrackedHostAuthorizationPath $validSyncAuthorization
    Assert-Result -Result $ambiguousAuthorization -ExitCode 4 -Label "Ambiguous mutation authorization"
    Assert-True -Condition ($ambiguousAuthorization.Text.Contains("mutually exclusive")) -Message "Ambiguous fixture/tracked-host authorization did not fail explicitly."

    $outsideAuthorization = Join-Path $trackedHostRoot ("AIWork\.runtime\codedb\payload-materializer\" + (Split-Path -Leaf $validSyncAuthorization))
    Copy-Item -LiteralPath $validSyncAuthorization -Destination $outsideAuthorization -Force
    $outsideAuthorizationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $outsideAuthorization
    Assert-Result -Result $outsideAuthorizationGuard -ExitCode 4 -Label "Authorization path boundary"

    $trackedAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    $trackedAuthorizationRelative = Get-RelativeFilePath -Root $trackedHostRoot -Path $trackedAuthorization
    $null = Invoke-TrackedHostGit -Root $trackedHostRoot -Arguments @("add", "-f", "--", $trackedAuthorizationRelative)
    $trackedAuthorizationGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $trackedAuthorization
    Assert-Result -Result $trackedAuthorizationGuard -ExitCode 4 -Label "Tracked authorization refusal"
    Assert-True -Condition ($trackedAuthorizationGuard.Text.Contains("must be Git ignored and untracked")) -Message "Tracked authorization was not rejected by its ownership boundary."
    $null = Invoke-TrackedHostGit -Root $trackedHostRoot -Arguments @("reset", "--", $trackedAuthorizationRelative)

    $projectMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        project_root = [System.IO.Path]::GetDirectoryName($trackedHostRoot)
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $projectMismatchAuthorization) -ExitCode 4 -Label "Authorization project binding"

    $gitMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        git_head = (("0" * 40) -join "")
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $gitMismatchAuthorization) -ExitCode 4 -Label "Authorization Git binding"

    $actionMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Remove"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $actionMismatchAuthorization) -ExitCode 4 -Label "Authorization action binding"

    $payloadMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        payload_manifest_sha256 = (("f" * 64) -join "")
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $payloadMismatchAuthorization) -ExitCode 4 -Label "Authorization payload binding"

    $acknowledgementMismatchAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        acknowledgement = "not authorized"
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $acknowledgementMismatchAuthorization) -ExitCode 4 -Label "Authorization acknowledgement"

    $unknownPropertyAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync" -Overrides @{
        unexpected = "reject"
    }
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $unknownPropertyAuthorization) -ExitCode 4 -Label "Authorization schema closure"

    $invalidShapeAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    Write-Utf8File -Path $invalidShapeAuthorization -Content "[]`n"
    $invalidShapeGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $invalidShapeAuthorization
    Assert-Result -Result $invalidShapeGuard -ExitCode 4 -Label "Authorization JSON shape"
    Assert-True -Condition ($invalidShapeGuard.Text.Contains("must be one JSON object")) -Message "Authorization JSON shape did not fail explicitly."

    $arrayShapeAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Sync"
    Write-Utf8File -Path $arrayShapeAuthorization -Content "[{}]`n"
    $arrayShapeGuard = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $arrayShapeAuthorization
    Assert-Result -Result $arrayShapeGuard -ExitCode 4 -Label "Authorization JSON array shape"
    Assert-True -Condition ($arrayShapeGuard.Text.Contains("must be one JSON object")) -Message "Authorization JSON array shape did not fail explicitly."
    Assert-Equal -Actual (Get-FileSnapshot -Root $trackedManagedRoot) -Expected $trackedManagedBefore -Message "Rejected tracked-host authorizations changed managed files."
    Assert-SentinelsUnchanged -ExpectedSnapshot $trackedSentinelSnapshot -Root $trackedHostRoot -Paths $trackedHostSentinelPaths

    $authorizedSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validSyncAuthorization -ConfirmLegacyMcpStopped
    Assert-Result -Result $authorizedSync -ExitCode 0 -Label "Authorized tracked-host Sync"
    Assert-True -Condition ($authorizedSync.Text.Contains("[AUTHORIZED] Tracked-host Sync authorization")) -Message "Authorized Sync did not report the accepted authorization."
    Assert-CanonicalFilesInstalled -Root $trackedHostRoot
    $trackedMarkerPath = Get-PathFromRelative -Root $trackedHostRoot -RelativePath $markerRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $trackedMarkerPath -PathType Leaf) -Message "Authorized Sync did not write the ownership marker."
    Assert-LfOnlyFile -Path $trackedMarkerPath -Label "Authorized tracked-host ownership marker"
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture) -ExitCode 0 -Label "Tracked-host Verify without mutation authorization"

    $beforeWrongActionRemove = Get-FileSnapshot -Root $trackedManagedRoot
    $wrongActionRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validSyncAuthorization
    Assert-Result -Result $wrongActionRemove -ExitCode 4 -Label "Sync authorization cannot Remove"
    Assert-Equal -Actual (Get-FileSnapshot -Root $trackedManagedRoot) -Expected $beforeWrongActionRemove -Message "Wrong-action Remove changed managed files."

    $validRemoveAuthorization = New-TrackedHostAuthorization -Root $trackedHostRoot -PayloadRoot $canonicalPayloadRoot -Action "Remove"
    $authorizedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TargetProjectRoot $trackedHostRoot -OmitPocFixture -TrackedHostAuthorizationPath $validRemoveAuthorization
    Assert-Result -Result $authorizedRemove -ExitCode 0 -Label "Authorized tracked-host Remove"
    Assert-True -Condition ($authorizedRemove.Text.Contains("[AUTHORIZED] Tracked-host Remove authorization")) -Message "Authorized Remove did not report the accepted authorization."
    Assert-CanonicalFilesRemoved -Root $trackedHostRoot
    Assert-SentinelsUnchanged -ExpectedSnapshot $trackedSentinelSnapshot -Root $trackedHostRoot -Paths $trackedHostSentinelPaths
    $trackedMaterializerRuntime = Join-Path $trackedHostRoot "AIWork\.runtime\codedb\payload-materializer"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $trackedMaterializerRuntime "materialize-active.json"))) -Message "Tracked-host materializer active marker remained after Remove."
    Assert-True -Condition (@(Get-ChildItem -LiteralPath $trackedMaterializerRuntime -Directory -Filter "txn-v1-*" -ErrorAction SilentlyContinue).Count -eq 0) -Message "Tracked-host transaction residue remained after Remove."
    Write-Host "[OK] Tracked-host authorization rejected invalid bindings and permitted only the exact authorized Sync/Remove actions."

    $dryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $dryRun -ExitCode 0 -Label "Empty install DryRun"
    Assert-True -Condition ($dryRun.Text -match '\[PLAN\] Missing:') -Message "Empty install DryRun did not report missing files."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Empty install plan is read-only."

    $beforeFailedInstall = Get-FileSnapshot -Root $hostRoot
    $failedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 1
    Assert-Result -Result $failedInstall -ExitCode 6 -Label "Injected install failure"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeFailedInstall -Message "Injected install failure did not restore the host file tree."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Mid-install failure restored the pre-sync file state."

    $beforeCrashedInstall = Get-FileSnapshot -Root $hostRoot
    $crashedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1
    Assert-Result -Result $crashedInstall -ExitCode 86 -Label "Injected install process crash"
    Assert-True -Condition ($crashedInstall.Text.Contains("Injected POC process crash after mutation 1.")) -Message "Injected install process crash did not report its mutation boundary."
    $materializerRuntimePath = Join-Path $hostRoot "AIWork\.runtime\codedb\payload-materializer"
    Assert-True -Condition (Test-Path -LiteralPath $materializerRuntimePath -PathType Container) -Message "Injected install process crash left no persistent recovery transaction."
    $crashedInstallTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/codedbignore.example"
    Assert-True -Condition (Test-Path -LiteralPath $crashedInstallTarget -PathType Leaf) -Message "Injected install process crash did not stop after the expected first atomic publication."
    Write-Utf8File -Path $crashedInstallTarget -Content "external change after interrupted materialization`n"
    $blockedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $blockedRecovery -ExitCode 7 -Label "Externally changed recovery refusal"
    Assert-Equal -Actual (Get-Content -LiteralPath $crashedInstallTarget -Raw) -Expected "external change after interrupted materialization`n" -Message "Recovery refusal overwrote an external post-crash change."
    Assert-True -Condition (Test-Path -LiteralPath $materializerRuntimePath -PathType Container) -Message "Recovery refusal discarded the persistent transaction evidence."
    Copy-Item -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath "AIWork/codedb/codedbignore.example") -Destination $crashedInstallTarget -Force
    $recoveredInstall = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $recoveredInstall -ExitCode 0 -Label "Install crash recovery"
    Assert-True -Condition ($recoveredInstall.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Install crash recovery did not report the interrupted Sync rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeCrashedInstall -Message "Persistent install recovery did not restore the exact pre-sync fixture."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Recovery refused external drift, then a new process restored the interrupted install from its persistent journal."

    $sync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $sync -ExitCode 0 -Label "Initial Sync"
    Assert-CanonicalFilesInstalled
    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    Assert-True -Condition (Test-Path -LiteralPath $markerPath -PathType Leaf) -Message "Initial Sync did not write the ownership marker."
    $markerText = Get-Content -LiteralPath $markerPath -Raw
    Assert-LfOnlyFile -Path $markerPath -Label "Initial ownership marker"
    Assert-True -Condition (-not $markerText.Contains($hostRoot)) -Message "Ownership marker contains an absolute host path."

    Write-Utf8File -Path $markerPath -Content $markerText.Replace("`n", "`r`n")
    Assert-True -Condition ([Array]::IndexOf([System.IO.File]::ReadAllBytes($markerPath), [byte]13) -ge 0) -Message "Non-canonical marker fixture did not contain CR bytes."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 3 -Label "Non-canonical marker Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Non-canonical marker repair"
    Assert-LfOnlyFile -Path $markerPath -Label "Repaired ownership marker"
    Assert-Equal -Actual (Get-Content -LiteralPath $markerPath -Raw) -Expected $markerText -Message "Marker repair did not restore canonical serialization."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Ownership markers use canonical LF serialization and repair non-canonical JSON formatting."

    $marker = $markerText | ConvertFrom-Json
    Assert-Equal -Actual $marker.managed_by -Expected "com.rice.ai-codedb" -Message "Marker manager mismatch."
    Assert-Equal -Actual $marker.payload_version -Expected "poc.13" -Message "Marker payload version mismatch."
    Assert-Equal -Actual $marker.payload_sequence -Expected 13 -Message "Marker payload sequence mismatch."
    Assert-Equal -Actual $marker.host_use_gate_version -Expected 1 -Message "Marker host-use gate version mismatch."
    Assert-Equal -Actual @($marker.files).Count -Expected 21 -Message "Marker file count mismatch."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Initial Sync installed only the manifest-owned files."

    $legacyMarker = $markerText | ConvertFrom-Json
    $legacyMarker.PSObject.Properties.Remove("host_use_gate_version")
    Write-Utf8File -Path $markerPath -Content (($legacyMarker | ConvertTo-Json -Depth 8) + "`n")
    $beforeLegacyUpgradeGate = Get-FileSnapshot -Root $hostRoot
    $legacyUpgradeRejected = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $legacyUpgradeRejected -ExitCode 4 -Label "Legacy marker upgrade confirmation gate"
    Assert-True -Condition ($legacyUpgradeRejected.Text.Contains("retry with -ConfirmLegacyMcpStopped")) -Message "Legacy marker upgrade did not request explicit MCP confirmation."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeLegacyUpgradeGate -Message "Rejected legacy marker upgrade changed the fixture."
    $legacyUpgrade = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -ConfirmLegacyMcpStopped
    Assert-Result -Result $legacyUpgrade -ExitCode 0 -Label "Confirmed legacy marker upgrade"
    $upgradedMarker = Get-Content -LiteralPath $markerPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $upgradedMarker.host_use_gate_version -Expected 1 -Message "Confirmed legacy upgrade did not publish gate ownership."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Legacy installed marker upgrade required explicit MCP-stop confirmation."

    $materializedPrepare = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1"
    $prepareStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $prepareStartInfo.FileName = $powershellPath
    $prepareStartInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$materializedPrepare`""
    $prepareStartInfo.WorkingDirectory = $hostRoot
    $prepareStartInfo.UseShellExecute = $false
    $prepareStartInfo.CreateNoWindow = $true
    $prepareStartInfo.RedirectStandardOutput = $true
    $prepareStartInfo.RedirectStandardError = $true
    $prepareProcess = [System.Diagnostics.Process]::new()
    $prepareProcess.StartInfo = $prepareStartInfo
    $null = $prepareProcess.Start()
    $prepareStdoutTask = $prepareProcess.StandardOutput.ReadToEndAsync()
    $prepareStderrTask = $prepareProcess.StandardError.ReadToEndAsync()
    $prepareProcess.WaitForExit()
    $prepareOutput = ($prepareStdoutTask.Result + $prepareStderrTask.Result).Trim()
    $prepareExitCode = $prepareProcess.ExitCode
    $prepareProcess.Dispose()
    if ($prepareExitCode -ne 0) {
        throw "Materialized prepare-runtime returned $prepareExitCode.`n$prepareOutput"
    }
    $generatedConfig = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\config\codedb-mcp.toml"
    Assert-True -Condition (Test-Path -LiteralPath $generatedConfig -PathType Leaf) -Message "Materialized prepare-runtime did not generate the fixture config."
    $generatedConfigText = Get-Content -LiteralPath $generatedConfig -Raw
    Assert-True -Condition ($generatedConfigText.Contains("AIWork/.runtime/codedb/codedb-fixture/index")) -Message "Materialized prepare-runtime resolved the wrong Unity project slug."
    Assert-True -Condition (-not $generatedConfigText.Contains("__CODEDB_PROVIDER_SLUG__")) -Message "Materialized prepare-runtime left an unresolved template token."
    Write-Host "[OK] Materialized common, prepare-runtime, and TOML template execute from the host path."

    $materializedCoordinator = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs"
    $coordinatorCheckOutput = @(& $nodePath --check $materializedCoordinator 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Materialized coordinator failed Node syntax validation.`n$($coordinatorCheckOutput -join [Environment]::NewLine)"
    }
    Write-Host "[OK] Materialized coordinator passed Node syntax validation from the host path."

    $materializedBuilder = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1"
    Push-Location $hostRoot
    try {
        $builderOutput = @(& $materializedBuilder -Reason Manual 2>&1)
        $builderSucceeded = $?
    } finally {
        Pop-Location
    }
    if (-not $builderSucceeded) {
        throw "Materialized Shader adapter builder failed.`n$($builderOutput -join [Environment]::NewLine)"
    }
    $adapterManifestPath = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\adapter\text-index\manifest.json"
    Assert-True -Condition (Test-Path -LiteralPath $adapterManifestPath -PathType Leaf) -Message "Materialized builder did not publish the adapter manifest."
    $adapterManifest = Get-Content -LiteralPath $adapterManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adapterManifest.buildReason -Expected "manual" -Message "Materialized builder reason mismatch."
    Assert-Equal -Actual $adapterManifest.fileCount -Expected 2 -Message "Materialized builder file count mismatch."
    Assert-Equal -Actual $adapterManifest.files[0].path -Expected "Assets/MaterializerProbe.shader" -Message "Materialized builder indexed the wrong fixture file."

    $materializedWorker = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1"
    $workerRequestId = "materializer-adapter-probe"
    $workerProbe = Invoke-AdapterWorkerRequest `
        -WorkerPath $materializedWorker `
        -BuilderPath $materializedBuilder `
        -Request ([ordered]@{
            schema_version = 1
            action = "build"
            request_id = $workerRequestId
            reason = "Automatic"
        })
    $workerReady = $workerProbe.ready
    $workerResponse = $workerProbe.response
    Assert-Equal -Actual $workerReady.type -Expected "ready" -Message "Materialized worker readiness type mismatch."
    Assert-True -Condition ([string]::Equals([string]$workerReady.builder_path, $materializedBuilder, [StringComparison]::OrdinalIgnoreCase)) -Message "Materialized worker resolved the wrong builder path."
    if (-not [string]::Equals([string]$workerResponse.type, "build_completed", [StringComparison]::Ordinal)) {
        throw "Materialized worker response type mismatch. Expected 'build_completed', got '$($workerResponse.type)'. Error: $($workerResponse.error)"
    }
    Assert-Equal -Actual $workerResponse.request_id -Expected $workerRequestId -Message "Materialized worker request id mismatch."
    $adapterManifest = Get-Content -LiteralPath $adapterManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adapterManifest.buildReason -Expected "automatic" -Message "Materialized worker build reason mismatch."
    Assert-Equal -Actual $adapterManifest.fileCount -Expected 2 -Message "Materialized worker file count mismatch."
    Write-Host "[OK] Materialized Shader adapter builder and persistent worker executed from the host path."

    $materializedWrapper = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    $wrapperCheckOutput = @(& $nodePath --check $materializedWrapper 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Materialized wrapper failed Node syntax validation.`n$($wrapperCheckOutput -join [Environment]::NewLine)"
    }
    $wrapperContextOutput = @(& $nodePath $materializedWrapper --root $hostRoot --print-context 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Materialized wrapper context probe failed.`n$($wrapperContextOutput -join [Environment]::NewLine)"
    }
    $wrapperContext = ($wrapperContextOutput -join [Environment]::NewLine) | ConvertFrom-Json
    Assert-Equal -Actual $wrapperContext.project_slug -Expected "fixture" -Message "Materialized wrapper project slug mismatch."
    Assert-Equal -Actual $wrapperContext.provider_name -Expected "codedb-fixture" -Message "Materialized wrapper provider name mismatch."
    Assert-Equal -Actual $wrapperContext.runtime_root -Expected "AIWork/.runtime/codedb/codedb-fixture" -Message "Materialized wrapper runtime root mismatch."

    $readEscapeRoot = Join-Path $runRoot "read-escape-source"
    New-Item -ItemType Directory -Force -Path $readEscapeRoot | Out-Null
    Write-Utf8File -Path (Join-Path $readEscapeRoot "Outside.cs") -Content "// CODEDB_READ_MUST_NOT_ESCAPE_ROOT`n"
    $readEscapeJunctionPath = Join-Path $hostRoot "Assets\ReadEscape"
    New-Item -ItemType Junction -Path $readEscapeJunctionPath -Target $readEscapeRoot | Out-Null

    $wrapperStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $wrapperStartInfo.FileName = $nodePath
    $wrapperStartInfo.Arguments = "`"$materializedWrapper`" --root `"$hostRoot`""
    $wrapperStartInfo.WorkingDirectory = $hostRoot
    $wrapperStartInfo.UseShellExecute = $false
    $wrapperStartInfo.CreateNoWindow = $true
    $wrapperStartInfo.RedirectStandardInput = $true
    $wrapperStartInfo.RedirectStandardOutput = $true
    $wrapperStartInfo.RedirectStandardError = $true
    $wrapperProcess = [System.Diagnostics.Process]::new()
    $wrapperProcess.StartInfo = $wrapperStartInfo
    $wrapperStarted = $false
    try {
        $null = $wrapperProcess.Start()
        $wrapperStarted = $true
        $wrapperProcessId = $wrapperProcess.Id
        $wrapperStderrTask = $wrapperProcess.StandardError.ReadToEndAsync()

        $initializeRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 1
            method = "initialize"
            params = [ordered]@{ protocolVersion = "2024-11-05" }
        })
        Assert-Equal -Actual $initializeRpc.result.serverInfo.name -Expected "codedb-project-wrapper" -Message "Materialized wrapper server name mismatch."

        $toolsRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 2
            method = "tools/list"
            params = [ordered]@{}
        })
        $toolNames = @($toolsRpc.result.tools | ForEach-Object { [string]$_.name } | Sort-Object)
        Assert-Equal -Actual ($toolNames -join "|") -Expected "codedb_context|codedb_find|codedb_read|codedb_search|codedb_status|codedb_text_search" -Message "Materialized wrapper tool surface mismatch."

        Assert-True -Condition (Wait-ForHostUseLease -Owner "mcp" -ProcessId $wrapperProcess.Id -Present $true) -Message "Materialized wrapper did not publish its MCP host-use lease."
        $beforeActiveMcpGate = Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")
        $activeMcpSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $activeMcpSync -ExitCode 4 -Label "Active MCP Sync gate"
        Assert-True -Condition ($activeMcpSync.Text.Contains("[ACTIVE] mcp PID $($wrapperProcess.Id)")) -Message "Active MCP gate did not identify the live wrapper PID."
        Assert-True -Condition (-not $activeMcpSync.Text.Contains("[PLAN]")) -Message "Active MCP gate ran after materialization planning."
        Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")) -Expected $beforeActiveMcpGate -Message "Active MCP gate changed managed host tooling."

        $statusRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 3
            method = "tools/call"
            params = [ordered]@{ name = "codedb_status"; arguments = [ordered]@{} }
        })
        $statusText = [string]$statusRpc.result.content[0].text
        foreach ($expectedStatus in @(
            "[OK] codedb-fixture wrapper ready.",
            "Provider executable: missing",
            "Watch opt-in: disabled",
            "Automatic refresh: pending",
            "Watch coordinator: stopped",
            "Shader adapter manifest: present",
            "Shader adapter files: 2",
            "Tool profile: Discover Read only"
        )) {
            Assert-True -Condition ($statusText.Contains($expectedStatus)) -Message "Materialized wrapper status is missing '$expectedStatus'."
        }
        $statusTiming = Get-WrapperTiming -Text $statusText -Label "Wrapper status"
        Assert-Equal -Actual $statusTiming.schema_version -Expected 1 -Message "Wrapper timing schema mismatch."
        Assert-Equal -Actual $statusTiming.tool -Expected "codedb_status" -Message "Wrapper status timing tool mismatch."
        Assert-Equal -Actual $statusTiming.queue_ms -Expected 0 -Message "One-shot wrapper status unexpectedly reported queue time."
        Assert-Equal -Actual $statusTiming.provider_attempts -Expected 0 -Message "Wrapper status unexpectedly invoked the Provider."

        $searchRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 4
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{ query = "CODEDB_MATERIALIZER_ADAPTER_PROBE"; language = "ShaderHlsl"; limit = 5 }
            }
        })
        $searchText = [string]$searchRpc.result.content[0].text
        Assert-True -Condition ($searchText.Contains("[HIT] Assets/MaterializerProbe.shader:2")) -Message "Materialized wrapper did not find the Shader fixture token."
        $adapterSearchTiming = Get-WrapperTiming -Text $searchText -Label "Shader adapter search"
        Assert-Equal -Actual $adapterSearchTiming.tool -Expected "codedb_text_search" -Message "Shader adapter timing tool mismatch."
        Assert-True -Condition ($adapterSearchTiming.adapter_ms -ge 0) -Message "Shader adapter timing is negative."
        Assert-Equal -Actual $adapterSearchTiming.provider_attempts -Expected 0 -Message "Shader-only search unexpectedly invoked the Provider."

        $readRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 5
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/MaterializerProbe.shader"; start_line = 2; end_line = 2; language = "ShaderHlsl" }
            }
        })
        $readText = [string]$readRpc.result.content[0].text
        Assert-True -Condition ($readText.Contains("lines 2-2")) -Message "Materialized wrapper did not preserve the requested read window."
        Assert-True -Condition ($readText.Contains("CODEDB_MATERIALIZER_ADAPTER_PROBE")) -Message "Materialized wrapper read omitted the Shader fixture token."
        $readTiming = Get-WrapperTiming -Text $readText -Label "Shader adapter read"
        Assert-Equal -Actual $readTiming.tool -Expected "codedb_read" -Message "Shader read timing tool mismatch."
        Assert-True -Condition ($readTiming.read_ms -ge 0) -Message "Shader read timing is negative."

        $csharpReadRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 6
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/MaterializerFreshnessProbe.cs"; start_line = 2; end_line = 2; language = "CSharp" }
            }
        })
        $csharpReadText = [string]$csharpReadRpc.result.content[0].text
        Assert-True -Condition ($csharpReadText.Contains("CodeDB read Assets/MaterializerFreshnessProbe.cs lines 2-2")) -Message "C# read did not report the exact requested window."
        Assert-True -Condition ($csharpReadText.Contains("CODEDB_MATERIALIZER_PROVIDER_PROBE")) -Message "C# read omitted the requested source line."
        Assert-True -Condition (-not $csharpReadText.Contains("CodedbMaterializerFreshnessProbe {")) -Message "C# read leaked source before the requested window."
        Assert-True -Condition (-not $csharpReadText.Contains("CODEDB_BOUNDED_READ_EXCLUDED")) -Message "C# read leaked source after the requested window."

        $cappedReadRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 7
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/ZMaterializerBoundedReadProbe.cs"; start_line = 10; end_line = 250; language = "CSharp" }
            }
        })
        $cappedReadText = [string]$cappedReadRpc.result.content[0].text
        Assert-True -Condition ($cappedReadText.Contains("lines 10-209")) -Message "C# read did not cap the requested window at 200 lines."
        Assert-True -Condition ($cappedReadText.Contains("[LIMIT] Read window capped at 200 lines")) -Message "C# read did not disclose its line cap."
        Assert-True -Condition ($cappedReadText.Contains("CODEDB_BOUNDED_LINE_010")) -Message "C# capped read omitted its first requested line."
        Assert-True -Condition ($cappedReadText.Contains("CODEDB_BOUNDED_LINE_209")) -Message "C# capped read omitted its final allowed line."
        Assert-True -Condition (-not $cappedReadText.Contains("CODEDB_BOUNDED_LINE_210")) -Message "C# capped read exceeded the 200-line boundary."

        $largeReadRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 8
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/ZMaterializerOutputCeilingProbe.cs"; start_line = 1; end_line = 1; language = "CSharp" }
            }
        })
        $largeReadText = [string]$largeReadRpc.result.content[0].text
        $largeReadBytes = [System.Text.Encoding]::UTF8.GetByteCount($largeReadText)
        Assert-True -Condition ($largeReadBytes -le 65536) -Message "Wrapper output exceeded its 64 KiB UTF-8 ceiling: $largeReadBytes bytes."
        Assert-True -Condition ($largeReadText.Contains("[TRUNCATED] Wrapper output exceeded 65536 UTF-8 bytes.")) -Message "Wrapper output ceiling did not disclose truncation."
        $largeReadTiming = Get-WrapperTiming -Text $largeReadText -Label "Truncated wrapper read"
        Assert-True -Condition ($largeReadTiming.output_bytes -gt 65536) -Message "Truncated wrapper timing did not report the uncapped body size."

        $escapedReadRpc = Invoke-WrapperRpcError -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 9
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_read"
                arguments = [ordered]@{ path = "Assets/ReadEscape/Outside.cs"; start_line = 1; end_line = 1; language = "CSharp" }
            }
        })
        Assert-True `
            -Condition ([string]$escapedReadRpc.error.message -like "*read resolved path is outside Unity root*") `
            -Message "Wrapper did not report the resolved-path escape boundary."
        $readEscapeItem = Get-Item -LiteralPath $readEscapeJunctionPath -Force
        Assert-True -Condition (($readEscapeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) -Message "Read escape fixture stopped being a junction."
        [System.IO.Directory]::Delete($readEscapeJunctionPath)
        $readEscapeJunctionPath = $null

        $conflictingScopeRpc = Invoke-WrapperRpcError -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 10
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{
                    query = "CODEDB_SCOPE_CONTRACT"
                    path = "Assets/Scoped"
                    path_glob = "Assets/Outside/**"
                }
            }
        })
        Assert-True `
            -Condition ([string]$conflictingScopeRpc.error.message -like "*path and path_glob disagree*") `
            -Message "Wrapper accepted conflicting search scope aliases."

        $excludedRpc = Invoke-WrapperRpc -Process $wrapperProcess -Request ([ordered]@{
            jsonrpc = "2.0"
            id = 11
            method = "tools/call"
            params = [ordered]@{
                name = "codedb_text_search"
                arguments = [ordered]@{
                    query = "CODEDB_MATERIALIZER_ADAPTER_PROBE"
                    language = "ShaderHlsl"
                    path_glob = "Library/PackageCache/**"
                }
            }
        })
        $excludedText = [string]$excludedRpc.result.content[0].text
        Assert-True -Condition ($excludedText.Contains("[NO HIT] excluded path scope: Library/PackageCache/**")) -Message "Materialized wrapper did not enforce the PackageCache exclusion."

        $wrapperProcess.StandardInput.Close()
        if (-not $wrapperProcess.WaitForExit(10000)) {
            $wrapperProcess.Kill()
            throw "Materialized wrapper did not exit after stdin closed."
        }
        $wrapperError = $wrapperStderrTask.Result.Trim()
        if ($wrapperProcess.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($wrapperError)) {
            throw "Materialized wrapper exited with code $($wrapperProcess.ExitCode).`n$wrapperError"
        }
    } finally {
        if ($wrapperStarted -and -not $wrapperProcess.HasExited) {
            $wrapperProcess.Kill()
            $wrapperProcess.WaitForExit()
        }
        $wrapperProcess.Dispose()
    }
    Assert-True -Condition (Wait-ForHostUseLease -Owner "mcp" -ProcessId $wrapperProcessId -Present $false) -Message "Normally closed MCP wrapper left a host-use lease."

    $staleLeaseStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $staleLeaseStartInfo.FileName = $nodePath
    $staleLeaseStartInfo.Arguments = "`"$materializedWrapper`" --root `"$hostRoot`""
    $staleLeaseStartInfo.WorkingDirectory = $hostRoot
    $staleLeaseStartInfo.UseShellExecute = $false
    $staleLeaseStartInfo.CreateNoWindow = $true
    $staleLeaseStartInfo.RedirectStandardInput = $true
    $staleLeaseStartInfo.RedirectStandardOutput = $true
    $staleLeaseStartInfo.RedirectStandardError = $true
    $staleLeaseProcess = [System.Diagnostics.Process]::new()
    $staleLeaseProcess.StartInfo = $staleLeaseStartInfo
    try {
        $null = $staleLeaseProcess.Start()
        $activeMcpProcess = $staleLeaseProcess
        Assert-True -Condition (Wait-ForHostUseLease -Owner "mcp" -ProcessId $staleLeaseProcess.Id -Present $true) -Message "Hard-kill MCP fixture did not publish a lease."
        $staleLeaseProcess.Kill()
        $staleLeaseProcess.WaitForExit()
        $activeMcpProcess = $null
        $staleLeasePaths = @(Get-HostUseLeasePaths -Owner "mcp" -ProcessId $staleLeaseProcess.Id)
        Assert-Equal -Actual $staleLeasePaths.Count -Expected 1 -Message "Hard-killed MCP wrapper did not leave exactly one stale lease."

        $beforeStaleLeaseRecovery = Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")
        $staleLeaseRecovery = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
        Assert-Result -Result $staleLeaseRecovery -ExitCode 0 -Label "Stale MCP lease recovery"
        Assert-True -Condition ($staleLeaseRecovery.Text.Contains("[RECOVERED] Removed stale mcp host-use lease for PID $($staleLeaseProcess.Id).")) -Message "Materializer did not report stale MCP lease recovery."
        Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")) -Expected $beforeStaleLeaseRecovery -Message "Stale MCP lease recovery changed managed host tooling."
        Assert-True -Condition (Wait-ForHostUseLease -Owner "mcp" -ProcessId $staleLeaseProcess.Id -Present $false) -Message "Stale MCP lease remained after recovery."
        Assert-NoMaterializerResidue
    } finally {
        if (-not $staleLeaseProcess.HasExited) {
            $staleLeaseProcess.Kill()
            $staleLeaseProcess.WaitForExit()
        }
        $activeMcpProcess = $null
        $staleLeaseProcess.Dispose()
    }
    $fixtureWatchRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\watch"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $fixtureWatchRoot "auto-start.json"))) -Message "Materialized wrapper created a watch marker before Setup completed."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $fixtureWatchRoot "coordinator\coordinator-state.json"))) -Message "Materialized wrapper started the coordinator before Setup completed."
    Write-Host "[OK] Materialized wrapper passed MCP Discover Read, active gate, stale-lease recovery, and pre-Setup pending coverage."

    $materializedWatchPrepare = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-watch-config.ps1"
    $materializedWatchManager = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1"
    $fixtureProviderExecutable = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\bin\codebase-mcp.exe"
    $watchConfigPath = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\config\codedb-mcp.watch.toml"
    $watchMarkerPath = Join-Path $fixtureWatchRoot "auto-start.json"
    $watchPausedMarkerPath = Join-Path $fixtureWatchRoot "automatic-refresh-paused.json"
    $coordinatorRuntime = Join-Path $fixtureWatchRoot "coordinator"
    $coordinatorStatePath = Join-Path $coordinatorRuntime "coordinator-state.json"
    $materializedProviderGuidance = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1"
    $beforeMissingGuidance = Get-FileSnapshot -Root $hostRoot
    $missingGuidanceResult = Invoke-PowerShellAction -Action {
        & $materializedProviderGuidance
    }
    Assert-Result -Result $missingGuidanceResult -ExitCode 0 -Label "Materialized provider guidance without executable"
    foreach ($expectedGuidance in @(
        "The provider executable is an external dependency.",
        "This project does not vendor, download, or commit the provider binary in this flow.",
        "Do not write user/global MCP client configuration from this setup flow.",
        "[NO HIT] Provider executable is missing"
    )) {
        Assert-True -Condition ($missingGuidanceResult.Text.Contains($expectedGuidance)) -Message "Provider guidance is missing '$expectedGuidance'."
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMissingGuidance -Message "Provider guidance mutated the fixture while the executable was missing."

    New-FixtureProviderExecutable -Path $fixtureProviderExecutable
    $beforeAvailableGuidance = Get-FileSnapshot -Root $hostRoot
    $availableGuidanceResult = Invoke-PowerShellAction -Action {
        & $materializedProviderGuidance
    }
    Assert-Result -Result $availableGuidanceResult -ExitCode 0 -Label "Materialized provider guidance with executable"
    Assert-True -Condition ($availableGuidanceResult.Text.Contains("[OK] Provider executable exists")) -Message "Provider guidance did not detect the fixture executable."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeAvailableGuidance -Message "Provider guidance mutated the fixture after the executable was present."
    Write-Host "[OK] Materialized provider guidance remained read-only and registration-free."

    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Formal fixture config must remain watch-disabled."
    $activeWatchManagerPath = $materializedWatchManager
    $automaticWatchProbe = Invoke-WrapperWatchProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -WaitForCoordinatorStatePath $coordinatorStatePath `
        -WaitForWatchMarkerPath $watchMarkerPath
    Assert-True -Condition ($automaticWatchProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.watch.toml")) -Message "First post-Setup wrapper did not route reads through automatic watch."
    foreach ($expectedStatus in @(
        "Watch opt-in: enabled",
        "Automatic refresh: active",
        "Watch coordinator: ready",
        "Shader watcher: watching"
    )) {
        Assert-True -Condition ($automaticWatchProbe.StatusText.Contains($expectedStatus)) -Message "Automatic wrapper status is missing '$expectedStatus'."
    }
    Assert-True -Condition (Test-Path -LiteralPath $watchConfigPath -PathType Leaf) -Message "Automatic watch did not generate the watch config."
    Assert-True -Condition (Test-Path -LiteralPath $watchMarkerPath -PathType Leaf) -Message "Automatic watch did not create its lifecycle marker."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Automatic watch changed the formal provider config."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $watchConfigPath -Section "watch" -Key "enabled").Trim() -Expected "true" -Message "Generated watch config did not enable native watch."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $watchConfigPath -Section "watch" -Key "poll_interval_seconds").Trim() -Expected "1" -Message "Generated watch config poll interval mismatch."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $watchConfigPath -Section "storage" -Key "dir").Trim() -Expected (Get-TomlSectionValue -Path $generatedConfig -Section "storage" -Key "dir").Trim() -Message "Generated watch config changed the formal index location."

    $automaticStatusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $automaticStatusResult -ExitCode 0 -Label "Automatic watcher Status"
    $automaticStatus = Get-LastJsonObject -Result $automaticStatusResult -Label "Automatic watcher Status"
    Assert-Equal -Actual $automaticStatus.action -Expected "running" -Message "Automatic watcher did not reach running."
    Assert-Equal -Actual $automaticStatus.provider_state -Expected "ready" -Message "Automatic watcher provider did not reach ready."
    Assert-Equal -Actual $automaticStatus.adapter_state -Expected "watching" -Message "Automatic watcher adapter did not reach watching."
    $automaticLifecycleId = [string]$automaticStatus.lifecycle_id
    $activeWatchManagerPath = $materializedWatchManager
    $activeWatchLifecycleId = $automaticLifecycleId

    $scopedTextSearch = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_text_search" `
        -Arguments ([ordered]@{ query = "CODEDB_SCOPE_CONTRACT"; path = "Assets/Scoped"; limit = 2 }) `
        -WaitForCoordinatorStatePath $coordinatorStatePath `
        -WaitForWatchMarkerPath $watchMarkerPath
    Assert-True -Condition ($scopedTextSearch.Contains('"path_glob":"Assets/Scoped/**"')) -Message "Wrapper did not normalize path to a directory path_glob before Provider routing."
    Assert-True -Condition (-not $scopedTextSearch.Contains('"path":"Assets/Scoped"')) -Message "Wrapper forwarded the legacy path alias to the Provider."
    Assert-Equal -Actual ([regex]::Matches($scopedTextSearch, '(?m)^\[HIT\] ').Count) -Expected 2 -Message "Merged text search did not enforce one global limit."
    Assert-True -Condition ($scopedTextSearch.Contains("Assets/Scoped/ScopedProbe.cs:1 [provider]")) -Message "Scoped text search omitted the Provider C# lane."
    Assert-True -Condition ($scopedTextSearch.Contains("Assets/Scoped/ScopedProbe.shader:2 [provider+shader-adapter]")) -Message "Scoped text search did not deduplicate and merge the Shader lanes."
    Assert-True -Condition (-not $scopedTextSearch.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Scoped text search leaked a Provider result outside path_glob."
    Assert-True -Condition (-not $scopedTextSearch.Contains("Assets/Scoped/SecondScopedProbe.cs")) -Message "Scoped text search exceeded its global result limit."
    Assert-True -Condition ($scopedTextSearch.Contains("[LIMIT] Global result limit 2 applied")) -Message "Scoped text search did not disclose global limiting."
    $scopedTextSearchTiming = Get-WrapperTiming -Text $scopedTextSearch -Label "Scoped dual-lane text search"
    Assert-Equal -Actual $scopedTextSearchTiming.tool -Expected "codedb_text_search" -Message "Scoped text search timing tool mismatch."
    Assert-Equal -Actual $scopedTextSearchTiming.queue_ms -Expected 0 -Message "One-shot Provider path unexpectedly reported queue time."
    Assert-True -Condition ($scopedTextSearchTiming.provider_process_ms -gt 0) -Message "Scoped text search did not report Provider process wall time."
    Assert-Equal -Actual $scopedTextSearchTiming.provider_core_ms -Expected 7 -Message "Scoped text search did not parse Provider core timing."
    Assert-Equal -Actual $scopedTextSearchTiming.provider_attempts -Expected 1 -Message "Scoped text search Provider attempt count mismatch."
    Assert-True -Condition ($scopedTextSearchTiming.adapter_ms -ge 0) -Message "Scoped text search adapter timing is negative."
    Assert-True -Condition ($scopedTextSearchTiming.merge_ms -ge 0) -Message "Scoped text search merge timing is negative."
    Assert-True -Condition ($scopedTextSearchTiming.total_ms -ge $scopedTextSearchTiming.provider_process_ms) -Message "Scoped text search total timing is below Provider process time."

    $scopedSemanticSearch = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_search" `
        -Arguments ([ordered]@{ query = "CODEDB_SEARCH_CONTRACT"; path_glob = "Assets/Scoped/**"; limit = 2 })
    Assert-Equal -Actual ([regex]::Matches($scopedSemanticSearch, '(?m)^\[HIT\] ').Count) -Expected 2 -Message "Semantic search parser returned the wrong unique hit count."
    Assert-True -Condition ($scopedSemanticSearch.Contains("Assets/Scoped/ScopedProbe.cs:1-2 [provider]")) -Message "Semantic search did not parse the Provider chunk range."
    Assert-True -Condition ($scopedSemanticSearch.Contains("Assets/Scoped/ScopedProbe.shader:1-3 [provider+shader-adapter]")) -Message "Semantic search did not merge an Adapter line into its Provider chunk."
    Assert-True -Condition (-not $scopedSemanticSearch.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Semantic search leaked an out-of-scope chunk."

    $scopedFind = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_find" `
        -Arguments ([ordered]@{ query = "CODEDB_FIND_CONTRACT"; path = "Assets/Scoped"; language = "CSharp"; limit = 1 })
    Assert-Equal -Actual ([regex]::Matches($scopedFind, '(?m)^\[HIT\] ').Count) -Expected 1 -Message "Find parser returned the wrong scoped hit count."
    Assert-True -Condition ($scopedFind.Contains("Assets/Scoped/SecondScopedProbe.cs [provider]")) -Message "Find parser omitted the in-scope Provider result."
    Assert-True -Condition (-not $scopedFind.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Find parser leaked an out-of-scope Provider result."

    $scopedContext = Invoke-WrapperToolProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -ToolName "codedb_context" `
        -Arguments ([ordered]@{ query = "CODEDB_SCOPE_CONTRACT"; path = "Assets/Scoped"; limit = 2 })
    Assert-True -Condition ($scopedContext.Contains("CodeDB read Assets/Scoped/ScopedProbe.cs")) -Message "Context omitted the bounded C# lane."
    Assert-True -Condition ($scopedContext.Contains("Shader adapter read Assets/Scoped/ScopedProbe.shader")) -Message "Context omitted the bounded Shader lane."
    Assert-True -Condition (-not $scopedContext.Contains("Assets/Outside/OutsideProbe.cs")) -Message "Context leaked an out-of-scope Provider result."
    Assert-True -Condition (-not $scopedContext.Contains("Assets/Scoped/SecondScopedProbe.cs")) -Message "Context exceeded its global result limit."
    Assert-True -Condition ($scopedContext.Contains("[LIMIT] Global context result limit 2 applied")) -Message "Context did not disclose its global result limit."
    Write-Host "[OK] Materialized wrapper normalized scopes and enforced dual-lane merge, deduplication, and global limits."

    $pauseResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Pause -ExpectedLifecycleId $automaticLifecycleId
    }
    Assert-Result -Result $pauseResult -ExitCode 0 -Label "Materialized watcher Pause"
    $activeWatchManagerPath = $null
    $activeWatchLifecycleId = $null
    Assert-True -Condition ($pauseResult.Text.Contains("[OK] Automatic refresh: PAUSED")) -Message "Pause did not report the persisted automatic-refresh state."
    Assert-True -Condition (Wait-ForPathState -Path $watchPausedMarkerPath -Present $true) -Message "Pause did not create its persistent marker."
    Assert-True -Condition (Wait-ForPathState -Path $watchMarkerPath -Present $false) -Message "Pause left the watch lifecycle marker behind."
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false) -Message "Pause left coordinator state behind."

    $pausedWatchProbe = Invoke-WrapperWatchProbe -WrapperPath $materializedWrapper -Root $hostRoot
    Assert-True -Condition ($pausedWatchProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.toml")) -Message "Paused wrapper did not fall back to the formal provider config."
    foreach ($expectedStatus in @(
        "Watch opt-in: disabled",
        "Automatic refresh: paused",
        "Watch coordinator: stopped"
    )) {
        Assert-True -Condition ($pausedWatchProbe.StatusText.Contains($expectedStatus)) -Message "Paused wrapper status is missing '$expectedStatus'."
    }
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "A wrapper restarted automatic watch while paused."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "A wrapper recreated coordinator state while paused."

    $watchLifecycleId = "materializer-" + [guid]::NewGuid().ToString("N")
    $activeWatchManagerPath = $materializedWatchManager
    $activeWatchLifecycleId = $watchLifecycleId
    $startResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager `
            -Action Start `
            -PollIntervalSeconds 1 `
            -AdapterDebounceMilliseconds 200 `
            -LifecycleId $watchLifecycleId `
            -RequireNewOwner `
            -ExclusiveOwner
    }
    Assert-Result -Result $startResult -ExitCode 0 -Label "Materialized watcher Start"
    $startStatus = Get-LastJsonObject -Result $startResult -Label "Materialized watcher Start"
    Assert-Equal -Actual $startStatus.action -Expected "started" -Message "Materialized watcher did not create a new coordinator lifecycle."
    Assert-Equal -Actual $startStatus.lifecycle_id -Expected $watchLifecycleId -Message "Materialized watcher lifecycle id mismatch."
    Assert-Equal -Actual $startStatus.exclusive_lifecycle -Expected $true -Message "Materialized watcher did not preserve exclusive ownership."
    Assert-Equal -Actual $startStatus.provider_state -Expected "ready" -Message "Materialized watcher provider did not reach ready."
    Assert-Equal -Actual $startStatus.adapter_state -Expected "watching" -Message "Materialized watcher adapter did not reach watching."
    Assert-Equal -Actual $startStatus.adapter_worker_state -Expected "ready" -Message "Materialized watcher adapter worker did not reach ready."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchPausedMarkerPath)) -Message "Resume left the automatic-refresh pause marker behind."
    Assert-True -Condition (Wait-ForPathState -Path $watchMarkerPath -Present $true) -Message "Materialized watcher did not create the opt-in marker."

    $marker = Get-Content -LiteralPath $watchMarkerPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $marker.lifecycle_id -Expected $watchLifecycleId -Message "Watch marker lifecycle id mismatch."
    Assert-Equal -Actual $marker.exclusive_lifecycle -Expected $true -Message "Watch marker exclusive ownership mismatch."
    Assert-Equal -Actual $marker.watch_config -Expected "AIWork/.runtime/codedb/codedb-fixture/config/codedb-mcp.watch.toml" -Message "Watch marker config path mismatch."

    $statusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $statusResult -ExitCode 0 -Label "Materialized watcher Status"
    $runningStatus = Get-LastJsonObject -Result $statusResult -Label "Materialized watcher Status"
    Assert-Equal -Actual $runningStatus.action -Expected "running" -Message "Materialized watcher Status did not report running."
    Assert-Equal -Actual $runningStatus.lifecycle_id -Expected $watchLifecycleId -Message "Materialized watcher Status reported another lifecycle."
    Assert-Equal -Actual $runningStatus.provider_state -Expected "ready" -Message "Materialized watcher Status provider mismatch."
    Assert-Equal -Actual $runningStatus.adapter_state -Expected "watching" -Message "Materialized watcher Status adapter mismatch."
    Assert-True -Condition (Wait-ForHostUseLease -Owner "watcher" -ProcessId ([int]$runningStatus.coordinator_pid) -Present $true) -Message "Watcher daemon did not publish its host-use lease."

    $beforeActiveWatcherGate = Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")
    $activeWatcherSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $activeWatcherSync -ExitCode 4 -Label "Active watcher Sync gate"
    Assert-True -Condition ($activeWatcherSync.Text.Contains("[ACTIVE] watcher PID $($runningStatus.coordinator_pid)")) -Message "Active watcher Sync gate did not identify the coordinator lease."
    Assert-True -Condition (-not $activeWatcherSync.Text.Contains("[PLAN]")) -Message "Active watcher Sync gate ran after materialization planning."
    $activeWatcherRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $activeWatcherRemove -ExitCode 4 -Label "Active watcher Remove gate"
    Assert-True -Condition ($activeWatcherRemove.Text.Contains("[ACTIVE] watcher PID $($runningStatus.coordinator_pid)")) -Message "Active watcher Remove gate did not identify the coordinator lease."
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")) -Expected $beforeActiveWatcherGate -Message "Active watcher gates changed managed host tooling."

    $watcherLeasePaths = @(Get-HostUseLeasePaths -Owner "watcher" -ProcessId ([int]$runningStatus.coordinator_pid))
    Assert-Equal -Actual $watcherLeasePaths.Count -Expected 1 -Message "Watcher daemon did not own exactly one host-use lease."
    Remove-Item -LiteralPath $watcherLeasePaths[0] -Force
    $legacyWatcherSync = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $legacyWatcherSync -ExitCode 4 -Label "Legacy watcher state Sync gate"
    Assert-True -Condition ($legacyWatcherSync.Text.Contains("[ACTIVE] coordinator_pid PID $($runningStatus.coordinator_pid)")) -Message "Legacy watcher state gate did not identify the live coordinator PID."
    Assert-True -Condition ($legacyWatcherSync.Text.Contains("live watcher process")) -Message "Legacy watcher state gate did not report its ownership boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")) -Expected $beforeActiveWatcherGate -Message "Legacy watcher state gate changed managed host tooling."
    Write-Host "[OK] Materialized watcher reached ready and blocked Sync/Remove through lease and legacy PID gates."

    $global:LASTEXITCODE = 0
    $directStopOutput = @(& $nodePath $materializedCoordinator stop --runtime $coordinatorRuntime --expected-lifecycle-id $watchLifecycleId 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Direct fixture coordinator stop failed before wrapper recovery.`n$($directStopOutput -join [Environment]::NewLine)"
    }
    Assert-True -Condition (Test-Path -LiteralPath $watchMarkerPath -PathType Leaf) -Message "Direct coordinator stop unexpectedly removed the host-owned opt-in marker."

    $wrapperWatchProbe = Invoke-WrapperWatchProbe `
        -WrapperPath $materializedWrapper `
        -Root $hostRoot `
        -WaitForCoordinatorStatePath $coordinatorStatePath `
        -WaitForWatchMarkerPath $watchMarkerPath
    Assert-True -Condition ($wrapperWatchProbe.SearchText.Contains("[FIXTURE PROVIDER] active_config=codedb-mcp.watch.toml")) -Message "Materialized wrapper did not route provider reads through the watch config."
    foreach ($expectedStatus in @(
        "Watch opt-in: enabled",
        "Watch coordinator: ready",
        "Shader watcher: watching",
        "Active provider config: AIWork/.runtime/codedb/codedb-fixture/config/codedb-mcp.watch.toml"
    )) {
        Assert-True -Condition ($wrapperWatchProbe.StatusText.Contains($expectedStatus)) -Message "Recovered wrapper status is missing '$expectedStatus'."
    }
    $recoveredStatusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $recoveredStatusResult -ExitCode 0 -Label "Wrapper-recovered watcher Status"
    $recoveredState = Get-LastJsonObject -Result $recoveredStatusResult -Label "Wrapper-recovered watcher Status"
    Assert-Equal -Actual $recoveredState.lifecycle_id -Expected $watchLifecycleId -Message "Wrapper recovery changed lifecycle ownership."
    Assert-Equal -Actual $recoveredState.exclusive_lifecycle -Expected $true -Message "Wrapper recovery changed exclusive ownership."
    Assert-Equal -Actual $recoveredState.provider_state -Expected "ready" -Message "Wrapper recovery provider state mismatch."
    Assert-Equal -Actual $recoveredState.adapter_state -Expected "watching" -Message "Wrapper recovery adapter state mismatch."
    Write-Host "[OK] Materialized wrapper recovered and attached to the same opt-in lifecycle."

    $wrongLifecycleId = "foreign-" + [guid]::NewGuid().ToString("N")
    $wrongStopResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Stop -ExpectedLifecycleId $wrongLifecycleId
    }
    Assert-True -Condition ($wrongStopResult.ExitCode -ne 0) -Message "Materialized watcher accepted a foreign lifecycle Stop."
    Assert-True -Condition ($wrongStopResult.Text.Contains("another lifecycle")) -Message "Foreign lifecycle Stop did not report marker ownership refusal."
    Assert-True -Condition (Test-Path -LiteralPath $watchMarkerPath -PathType Leaf) -Message "Foreign lifecycle Stop removed the owned marker."
    $statusAfterWrongStop = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $statusAfterWrongStop -ExitCode 0 -Label "Post-refusal watcher Status"
    $stateAfterWrongStop = Get-LastJsonObject -Result $statusAfterWrongStop -Label "Post-refusal watcher Status"
    Assert-Equal -Actual $stateAfterWrongStop.lifecycle_id -Expected $watchLifecycleId -Message "Foreign lifecycle Stop changed the live coordinator owner."

    $stopResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Stop -ExpectedLifecycleId $watchLifecycleId
    }
    Assert-Result -Result $stopResult -ExitCode 0 -Label "Materialized watcher Stop"
    $activeWatchManagerPath = $null
    $activeWatchLifecycleId = $null
    Assert-True -Condition (Wait-ForPathState -Path $watchMarkerPath -Present $false -TimeoutMilliseconds 10000) -Message "Materialized watcher Stop left the opt-in marker behind."
    Assert-True -Condition (Wait-ForPathState -Path $coordinatorStatePath -Present $false -TimeoutMilliseconds 10000) -Message "Materialized watcher Stop left coordinator state behind."

    $finalStatusResult = Invoke-PowerShellAction -Action {
        & $materializedWatchManager -Action Status
    }
    Assert-Result -Result $finalStatusResult -ExitCode 0 -Label "Materialized watcher final Status"
    Assert-True -Condition ($finalStatusResult.Text.Contains("[OK] Watch opt-in: DISABLED")) -Message "Final watcher Status did not report disabled opt-in."
    $finalStatus = Get-LastJsonObject -Result $finalStatusResult -Label "Materialized watcher final Status"
    Assert-Equal -Actual $finalStatus.action -Expected "stopped" -Message "Final watcher Status did not report stopped."
    Assert-Equal -Actual $finalStatus.coordinator_pid -Expected $null -Message "Final watcher Status retained a coordinator PID."
    Assert-Equal -Actual $finalStatus.adapter_state -Expected "stopped" -Message "Final watcher adapter state mismatch."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Watcher lifecycle changed the formal provider config."
    Write-Host "[OK] Materialized watcher rejected foreign ownership and ended DISABLED / STOPPED."

    $materializedProjectVerify = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/verify-codedb-project.ps1"
    $materializedProjectRefresh = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/refresh-codedb-project.ps1"
    $materializedIndexClear = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/clear-codedb-project-index.ps1"
    $materializedIgnoreTemplate = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/codedbignore.example"
    $generatedIgnorePath = Join-Path $hostRoot ".codedbignore"
    $providerRoot = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture"
    $providerIndexRoot = Join-Path $providerRoot "index"
    $providerManifestPath = Join-Path $providerIndexRoot "manifest.json"
    $providerLogsSentinel = Join-Path $providerRoot "logs\setup-index-preserve.log"
    $providerTempSentinel = Join-Path $providerRoot "tmp\setup-index-preserve.tmp"
    $staleIndexSentinel = Join-Path $providerIndexRoot "stale-before-clean.txt"
    Write-Utf8File -Path $providerLogsSentinel -Content "preserve provider logs`n"
    Write-Utf8File -Path $providerTempSentinel -Content "preserve provider temp`n"
    Write-Utf8File -Path $staleIndexSentinel -Content "stale provider index`n"

    $providerExecutableHash = (Get-FileHash -LiteralPath $fixtureProviderExecutable -Algorithm SHA256).Hash
    $formalConfigHash = (Get-FileHash -LiteralPath $generatedConfig -Algorithm SHA256).Hash
    $watchConfigHash = (Get-FileHash -LiteralPath $watchConfigPath -Algorithm SHA256).Hash
    $providerLogsHash = (Get-FileHash -LiteralPath $providerLogsSentinel -Algorithm SHA256).Hash
    $providerTempHash = (Get-FileHash -LiteralPath $providerTempSentinel -Algorithm SHA256).Hash
    $adapterRoot = Join-Path $providerRoot "adapter\text-index"
    $adapterSnapshotBeforeSetupIndex = Get-FileSnapshot -Root $adapterRoot

    $refreshResult = Invoke-PowerShellAction -Action {
        & $materializedProjectRefresh -GenerateUnityIgnore -CleanFirst
    }
    Assert-Result -Result $refreshResult -ExitCode 0 -Label "Materialized project refresh"
    foreach ($expectedRefreshOutput in @(
        "[FIXTURE PROVIDER] indexed --no-watch",
        "[OK] Host project CodeDB index refresh completed."
    )) {
        Assert-True -Condition ($refreshResult.Text.Contains($expectedRefreshOutput)) -Message "Materialized refresh is missing '$expectedRefreshOutput'."
    }
    Assert-True -Condition (Test-Path -LiteralPath $providerManifestPath -PathType Leaf) -Message "Materialized refresh did not publish the provider manifest."
    Assert-True -Condition (-not (Test-Path -LiteralPath $staleIndexSentinel)) -Message "Materialized CleanFirst refresh retained stale provider index data."
    $providerManifest = Get-Content -LiteralPath $providerManifestPath -Raw | ConvertFrom-Json
    Assert-Equal -Actual $providerManifest.fixture -Expected $true -Message "Fixture provider manifest identity mismatch."
    Assert-Equal -Actual $providerManifest.no_watch -Expected $true -Message "Materialized refresh did not enforce --no-watch."
    Assert-True -Condition (Test-Path -LiteralPath $generatedIgnorePath -PathType Leaf) -Message "Materialized refresh did not generate .codedbignore."
    Assert-Equal -Actual (Get-Content -LiteralPath $generatedIgnorePath -Raw) -Expected (Get-Content -LiteralPath $materializedIgnoreTemplate -Raw) -Message "Generated .codedbignore does not match the materialized template."
    Assert-Equal -Actual (Get-TomlSectionValue -Path $generatedConfig -Section "watch" -Key "enabled").Trim() -Expected "false" -Message "Materialized refresh changed formal watch policy."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $fixtureProviderExecutable -Algorithm SHA256).Hash -Expected $providerExecutableHash -Message "Materialized refresh changed the provider executable."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $generatedConfig -Algorithm SHA256).Hash -Expected $formalConfigHash -Message "Materialized refresh changed the formal provider config."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $watchConfigPath -Algorithm SHA256).Hash -Expected $watchConfigHash -Message "Materialized refresh changed the watch config."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterSnapshotBeforeSetupIndex -Message "Materialized refresh changed Shader/HLSL adapter data."
    Write-Host "[OK] Materialized refresh rebuilt only the formal no-watch provider index."

    $projectVerifyResult = Invoke-PowerShellAction -Action {
        & $materializedProjectVerify
    }
    Assert-Result -Result $projectVerifyResult -ExitCode 0 -Label "Materialized project verification"
    foreach ($expectedVerificationOutput in @(
        "Provider executable and runtime config are present and use Unity-root-relative paths.",
        "Generated .codedbignore matches the AIWork template.",
        "Generated codedb runtime paths do not appear in git status.",
        "Host project CodeDB structure verification passed."
    )) {
        Assert-True -Condition ($projectVerifyResult.Text.Contains($expectedVerificationOutput)) -Message "Materialized verification is missing '$expectedVerificationOutput'."
    }
    Write-Host "[OK] Materialized project verification accepted isolated ignored runtime state."

    $beforeClearPreview = Get-FileSnapshot -Root $providerRoot
    $clearPreviewResult = Invoke-PowerShellAction -Action {
        & $materializedIndexClear -WhatIf
    }
    Assert-Result -Result $clearPreviewResult -ExitCode 0 -Label "Materialized index clear preview"
    Assert-True -Condition ($clearPreviewResult.Text.Contains("[OK] Index clean preview completed")) -Message "Materialized index clear preview did not report WhatIf completion."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerRoot) -Expected $beforeClearPreview -Message "Materialized index clear preview changed provider runtime."

    $clearResult = Invoke-PowerShellAction -Action {
        & $materializedIndexClear -Confirm:$false
    }
    Assert-Result -Result $clearResult -ExitCode 0 -Label "Materialized index clear"
    Assert-True -Condition ($clearResult.Text.Contains("[OK] Index clean completed")) -Message "Materialized index clear did not report completion."
    Assert-True -Condition (-not (Test-Path -LiteralPath $providerIndexRoot)) -Message "Materialized index clear retained provider index data."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $fixtureProviderExecutable -Algorithm SHA256).Hash -Expected $providerExecutableHash -Message "Materialized index clear changed the provider executable."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $generatedConfig -Algorithm SHA256).Hash -Expected $formalConfigHash -Message "Materialized index clear changed the formal provider config."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $watchConfigPath -Algorithm SHA256).Hash -Expected $watchConfigHash -Message "Materialized index clear changed the watch config."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterSnapshotBeforeSetupIndex -Message "Materialized index clear changed Shader/HLSL adapter data."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $providerLogsSentinel -Algorithm SHA256).Hash -Expected $providerLogsHash -Message "Materialized index clear changed provider logs."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $providerTempSentinel -Algorithm SHA256).Hash -Expected $providerTempHash -Message "Materialized index clear changed provider temp state."
    Assert-True -Condition (-not (Test-Path -LiteralPath $watchMarkerPath)) -Message "Materialized index clear recreated the watcher opt-in marker."
    Assert-True -Condition (-not (Test-Path -LiteralPath $coordinatorStatePath)) -Message "Materialized index clear recreated coordinator state."
    Assert-True -Condition (Test-Path -LiteralPath $generatedIgnorePath -PathType Leaf) -Message "Materialized index clear removed generated .codedbignore."

    $clearMissingResult = Invoke-PowerShellAction -Action {
        & $materializedIndexClear -Confirm:$false
    }
    Assert-Result -Result $clearMissingResult -ExitCode 0 -Label "Materialized missing-index clear"
    Assert-True -Condition ($clearMissingResult.Text.Contains("[SKIP] No generated codedb index existed")) -Message "Materialized missing-index clear did not report SKIP."
    Write-Host "[OK] Materialized clear preview and index-only cleanup preserved every adjacent runtime owner."

    $materializedProviderProbe = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/probe-codedb-project-index.ps1"
    $materializedAdapterProbe = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/probe-codedb-project-text-adapter.ps1"
    $materializedFreshnessCheck = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/check-codedb-project-freshness.ps1"
    $materializedRefreshIfStale = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/refresh-codedb-project-if-stale.ps1"
    $materializedMcpDraft = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/emit-codedb-mcp-registration-draft.ps1"
    $materializedMcpValidator = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/validate-codedb-mcp-project-config.ps1"
    $providerInvocationLog = Join-Path $providerRoot "logs\fixture-index-invocations.txt"

    $unknownProviderResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $unknownProviderResult `
        -OverallState "UNKNOWN" `
        -ProviderState "UNKNOWN" `
        -AdapterState "OK" `
        -Label "Missing-provider freshness check"
    $adapterBeforeUnknownProviderRefresh = Get-FileSnapshot -Root $adapterRoot
    $providerInvocationsBeforeUnknownRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $unknownProviderRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $unknownProviderRefresh -ExitCode 0 -Label "Unknown-provider conditional refresh"
    foreach ($expected in @(
        "[OK] Refresh plan: provider=UNKNOWN, adapter=OK.",
        "[OK] Refreshing stale provider index.",
        "[OK] codedb conditional refresh completed and freshness check passed."
    )) {
        Assert-True -Condition ($unknownProviderRefresh.Text.Contains($expected)) -Message "Unknown-provider conditional refresh is missing '$expected'."
    }
    Assert-True -Condition (-not $unknownProviderRefresh.Text.Contains("Rebuilding stale Shader/HLSL adapter index")) -Message "Unknown-provider conditional refresh rebuilt the fresh adapter."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected ($providerInvocationsBeforeUnknownRefresh + 1) -Message "Unknown-provider conditional refresh did not invoke the provider exactly once."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterBeforeUnknownProviderRefresh -Message "Unknown-provider conditional refresh changed the fresh adapter."
    Write-Host "[OK] Provider UNKNOWN refreshed only the provider lane."

    $runtimeHealthProbe = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check RuntimeHealth
    }
    Assert-Result -Result $runtimeHealthProbe -ExitCode 0 -Label "Materialized provider runtime-health probe"
    Assert-True -Condition ($runtimeHealthProbe.Text.Contains("[OK] Runtime health smoke passed.")) -Message "Provider runtime-health probe did not report success."

    $csharpProbe = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check CSharpProbe
    }
    Assert-Result -Result $csharpProbe -ExitCode 0 -Label "Materialized C# provider probe"
    Assert-True `
        -Condition ($csharpProbe.Text.Contains("[OK] C# probe passed with CodedbMaterializerFreshnessProbe in Assets/MaterializerFreshnessProbe.cs.")) `
        -Message "C# provider probe did not verify the fixture source. Output:`n$($csharpProbe.Text)"

    $providerCustomHit = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check CustomProbe -Language CSharp -Query "CODEDB_MATERIALIZER_PROVIDER_PROBE"
    }
    Assert-Result -Result $providerCustomHit -ExitCode 0 -Label "Materialized provider custom hit"
    Assert-True -Condition ($providerCustomHit.Text.Contains("[OK] C# custom probe found 1 hit(s)")) -Message "Provider custom probe did not report its hit."
    Assert-True -Condition ($providerCustomHit.Text.Contains("[HIT] Assets/MaterializerFreshnessProbe.cs:2")) -Message "Provider custom probe did not report the fixture path."

    $providerCustomNoHit = Invoke-PowerShellAction -Action {
        & $materializedProviderProbe -Check CustomProbe -Language CSharp -Query "CODEDB_MATERIALIZER_PROVIDER_MISSING"
    }
    Assert-Result -Result $providerCustomNoHit -ExitCode 0 -Label "Materialized provider custom no-hit"
    Assert-True -Condition ($providerCustomNoHit.Text.Contains("[NO HIT] C# custom probe found no source match")) -Message "Provider custom no-hit did not report NO HIT."

    $adapterProbe = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check All -Query "CODEDB_MATERIALIZER_ADAPTER_PROBE"
    }
    Assert-Result -Result $adapterProbe -ExitCode 0 -Label "Materialized Shader adapter probe"
    foreach ($expected in @(
        "[OK] Shader adapter index ready:",
        "[OK] Shader adapter search found 1 hit(s)",
        "[OK] Shader adapter read Assets/MaterializerProbe.shader",
        "[OK] Shader adapter stale check passed"
    )) {
        Assert-True -Condition ($adapterProbe.Text.Contains($expected)) -Message "Shader adapter probe is missing '$expected'."
    }

    $adapterNoHit = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check Search -Query "CODEDB_MATERIALIZER_ADAPTER_MISSING"
    }
    Assert-Result -Result $adapterNoHit -ExitCode 0 -Label "Materialized Shader adapter no-hit"
    Assert-True -Condition ($adapterNoHit.Text.Contains("[NO HIT] Shader adapter search found no hit")) -Message "Shader adapter no-hit did not report NO HIT."
    Write-Host "[OK] Materialized provider and Shader adapter probes covered hit and no-hit behavior."

    $allFreshResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $allFreshResult `
        -OverallState "OK" `
        -ProviderState "OK" `
        -AdapterState "OK" `
        -Label "All-fresh check"
    $providerBeforeNoOp = Get-FileSnapshot -Root $providerIndexRoot
    $adapterBeforeNoOp = Get-FileSnapshot -Root $adapterRoot
    $providerInvocationsBeforeNoOp = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $noOpRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $noOpRefresh -ExitCode 0 -Label "All-fresh conditional refresh"
    Assert-True -Condition ($noOpRefresh.Text.Contains("[OK] Refresh plan: provider=OK, adapter=OK.")) -Message "All-fresh conditional refresh reported the wrong plan."
    Assert-True -Condition ($noOpRefresh.Text.Contains("[OK] codedb indexes are fresh. No refresh required.")) -Message "All-fresh conditional refresh did not report its no-op."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected $providerInvocationsBeforeNoOp -Message "All-fresh conditional refresh invoked the provider."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerIndexRoot) -Expected $providerBeforeNoOp -Message "All-fresh conditional refresh changed provider index data."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterBeforeNoOp -Message "All-fresh conditional refresh changed adapter data."
    Write-Host "[OK] Fresh provider and adapter state produced an exact no-op."

    Write-Utf8File -Path $providerManifestPath -Content "{`"schema_version`":1,`"fixture`":true,`"no_watch`":true,`"created_unix_ms`":946684800000}`n"
    $staleProviderResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $staleProviderResult `
        -OverallState "STALE" `
        -ProviderState "STALE" `
        -AdapterState "OK" `
        -Label "Stale-provider freshness check"
    $adapterBeforeStaleProviderRefresh = Get-FileSnapshot -Root $adapterRoot
    $providerInvocationsBeforeStaleRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $staleProviderRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $staleProviderRefresh -ExitCode 0 -Label "Stale-provider conditional refresh"
    Assert-True -Condition ($staleProviderRefresh.Text.Contains("[OK] Refresh plan: provider=STALE, adapter=OK.")) -Message "Stale-provider conditional refresh reported the wrong plan."
    Assert-True -Condition (-not $staleProviderRefresh.Text.Contains("Rebuilding stale Shader/HLSL adapter index")) -Message "Stale-provider conditional refresh rebuilt the fresh adapter."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected ($providerInvocationsBeforeStaleRefresh + 1) -Message "Stale-provider conditional refresh did not invoke the provider exactly once."
    Assert-Equal -Actual (Get-FileSnapshot -Root $adapterRoot) -Expected $adapterBeforeStaleProviderRefresh -Message "Stale-provider conditional refresh changed the fresh adapter."
    Write-Host "[OK] Provider STALE refreshed only the provider lane."

    $addedShaderPath = Join-Path $hostRoot "Assets\MaterializerFreshnessProbe.shader"
    Write-Utf8File -Path $addedShaderPath -Content "Shader `"Hidden/Rice/MaterializerFreshnessProbe`" {`n    // CODEDB_MATERIALIZER_ADAPTER_FRESHNESS_PROBE`n}`n"
    $staleAdapterResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $staleAdapterResult `
        -OverallState "STALE" `
        -ProviderState "OK" `
        -AdapterState "STALE" `
        -Label "Stale-adapter freshness check"
    $adapterStaleProbe = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check Stale
    }
    Assert-Result -Result $adapterStaleProbe -ExitCode 1 -Label "Materialized stale Shader adapter probe"
    Assert-True -Condition ($adapterStaleProbe.Text.Contains("[FAIL] Shader adapter index is stale")) -Message "Stale Shader adapter probe did not report failure."
    $providerBeforeStaleAdapterRefresh = Get-FileSnapshot -Root $providerIndexRoot
    $providerInvocationsBeforeAdapterRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $staleAdapterRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $staleAdapterRefresh -ExitCode 0 -Label "Stale-adapter conditional refresh"
    Assert-True -Condition ($staleAdapterRefresh.Text.Contains("[OK] Refresh plan: provider=OK, adapter=STALE.")) -Message "Stale-adapter conditional refresh reported the wrong plan."
    Assert-True -Condition (-not $staleAdapterRefresh.Text.Contains("Refreshing stale provider index")) -Message "Stale-adapter conditional refresh invoked the fresh provider."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected $providerInvocationsBeforeAdapterRefresh -Message "Stale-adapter conditional refresh changed the provider invocation count."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerIndexRoot) -Expected $providerBeforeStaleAdapterRefresh -Message "Stale-adapter conditional refresh changed provider index data."
    $adapterFreshProbe = Invoke-PowerShellAction -Action {
        & $materializedAdapterProbe -Check Stale
    }
    Assert-Result -Result $adapterFreshProbe -ExitCode 0 -Label "Materialized refreshed Shader adapter probe"
    Assert-True -Condition ($adapterFreshProbe.Text.Contains("[OK] Shader adapter stale check passed for 3 file(s).")) -Message "Refreshed Shader adapter probe did not return to OK."
    Write-Host "[OK] Adapter STALE rebuilt only the Shader/HLSL adapter lane."

    Remove-Item -LiteralPath $adapterManifestPath -Force
    $unknownAdapterResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $unknownAdapterResult `
        -OverallState "UNKNOWN" `
        -ProviderState "OK" `
        -AdapterState "UNKNOWN" `
        -Label "Unknown-adapter freshness check"
    $providerBeforeUnknownAdapterRefresh = Get-FileSnapshot -Root $providerIndexRoot
    $providerInvocationsBeforeUnknownAdapterRefresh = Get-FixtureIndexInvocationCount -Path $providerInvocationLog
    $unknownAdapterRefresh = Invoke-PowerShellAction -Action {
        & $materializedRefreshIfStale
    }
    Assert-Result -Result $unknownAdapterRefresh -ExitCode 0 -Label "Unknown-adapter conditional refresh"
    Assert-True -Condition ($unknownAdapterRefresh.Text.Contains("[OK] Refresh plan: provider=OK, adapter=UNKNOWN.")) -Message "Unknown-adapter conditional refresh reported the wrong plan."
    Assert-True -Condition (-not $unknownAdapterRefresh.Text.Contains("Refreshing stale provider index")) -Message "Unknown-adapter conditional refresh invoked the fresh provider."
    Assert-Equal -Actual (Get-FixtureIndexInvocationCount -Path $providerInvocationLog) -Expected $providerInvocationsBeforeUnknownAdapterRefresh -Message "Unknown-adapter conditional refresh changed the provider invocation count."
    Assert-Equal -Actual (Get-FileSnapshot -Root $providerIndexRoot) -Expected $providerBeforeUnknownAdapterRefresh -Message "Unknown-adapter conditional refresh changed provider index data."
    Assert-True -Condition (Test-Path -LiteralPath $adapterManifestPath -PathType Leaf) -Message "Unknown-adapter conditional refresh did not restore the adapter manifest."
    $finalFreshnessResult = Invoke-PowerShellAction -Action {
        & $materializedFreshnessCheck
    }
    Assert-FreshnessResult `
        -Result $finalFreshnessResult `
        -OverallState "OK" `
        -ProviderState "OK" `
        -AdapterState "OK" `
        -Label "Final freshness check"
    Write-Host "[OK] Adapter UNKNOWN rebuilt only the Shader/HLSL adapter lane and returned both owners to fresh."

    $beforeMcpGuidance = Get-FileSnapshot -Root $hostRoot
    $mcpDraftResult = Invoke-PowerShellAction -Action {
        & $materializedMcpDraft
    }
    Assert-Result -Result $mcpDraftResult -ExitCode 0 -Label "Materialized MCP registration draft"
    foreach ($expected in @(
        "codedb-fixture MCP registration draft",
        "Status: review draft only; no MCP client configuration was written.",
        "- Target file: .codex/config.toml",
        "[mcp_servers.codedb-fixture]",
        'command = "node"',
        'args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]',
        '"registrationPolicy"',
        '"manual-review-only"'
    )) {
        Assert-True -Condition ($mcpDraftResult.Text.Contains($expected)) -Message "MCP registration draft is missing '$expected'."
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMcpGuidance -Message "MCP registration draft changed host files."

    $mcpValidationResult = Invoke-PowerShellAction -Action {
        & $materializedMcpValidator
    }
    Assert-Result -Result $mcpValidationResult -ExitCode 0 -Label "Materialized MCP project config validation"
    foreach ($expected in @(
        "OK: Project config uses the package-neutral wrapper MCP command shape.",
        "OK: Shader/HLSL text adapter manifest is present for wrapper routing.",
        "OK: .codex/config.toml uses relative paths only.",
        "[OK] Project-level MCP config validation passed."
    )) {
        Assert-True -Condition ($mcpValidationResult.Text.Contains($expected)) -Message "MCP project config validation is missing '$expected'."
    }
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeMcpGuidance -Message "MCP project config validation changed host files."
    Write-Host "[OK] Materialized MCP draft and project config validation preserved host-owned configuration."

    $verify = Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $verify -ExitCode 0 -Label "Current Verify"
    $beforeIdempotent = Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")
    $syncAgain = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $syncAgain -ExitCode 0 -Label "Idempotent Sync"
    Assert-Equal -Actual (Get-FileSnapshot -Root (Join-Path $hostRoot "AIWork\codedb")) -Expected $beforeIdempotent -Message "Idempotent Sync changed managed state."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Verify and idempotent no-op passed."

    $beforeFailedRemove = Get-FileSnapshot -Root $hostRoot
    $failedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TestFailAfterMutation 1
    Assert-Result -Result $failedRemove -ExitCode 6 -Label "Injected Remove failure"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeFailedRemove -Message "Injected Remove failure did not restore the host file tree."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Post-rollback Verify"
    Assert-NoMaterializerResidue
    Write-Host "[OK] Mid-remove failure restored the owned files and marker."

    $beforeCrashedRemove = Get-FileSnapshot -Root $hostRoot
    $crashedRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1
    Assert-Result -Result $crashedRemove -ExitCode 86 -Label "Injected Remove process crash"
    Assert-True -Condition ($crashedRemove.Text.Contains("Injected POC process crash after mutation 1.")) -Message "Injected Remove process crash did not report its mutation boundary."
    Assert-True -Condition (Test-Path -LiteralPath $materializerRuntimePath -PathType Container) -Message "Injected Remove process crash left no persistent recovery transaction."
    $recoveredRemove = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $recoveredRemove -ExitCode 0 -Label "Remove crash recovery"
    Assert-True -Condition ($recoveredRemove.Text.Contains("[RECOVERED] Rolled back interrupted remove transaction.")) -Message "Remove crash recovery did not report the interrupted Remove rollback."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeCrashedRemove -Message "Persistent Remove recovery did not restore the exact installed fixture."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Post-crash-recovery Verify"
    Assert-NoMaterializerResidue
    Write-Host "[OK] A new process recovered the interrupted Remove from its persistent journal."

    $removeForAdoption = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $removeForAdoption -ExitCode 0 -Label "Pre-adoption Remove"
    Copy-CanonicalFilesToHost
    $adoptionTime = [datetime]::SpecifyKind([datetime]"2020-01-02T03:04:06", [DateTimeKind]::Utc)
    foreach ($relativePath in $managedTargets) {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        [System.IO.File]::SetLastWriteTimeUtc($target, $adoptionTime)
        Set-ItemProperty -LiteralPath $target -Name IsReadOnly -Value $true
    }
    $beforeAdoption = @{}
    foreach ($relativePath in $managedTargets) {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        $item = Get-Item -LiteralPath $target -Force
        $beforeAdoption[$relativePath] = [pscustomobject]@{
            Sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
            LastWriteTicks = $item.LastWriteTimeUtc.Ticks
            Attributes = [int]$item.Attributes
        }
    }
    $beforeRejectedAdoption = Get-FileSnapshot -Root $hostRoot
    $rejectedAdoption = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $rejectedAdoption -ExitCode 4 -Label "Unconfirmed exact-file adoption"
    Assert-True -Condition ($rejectedAdoption.Text.Contains("retry with -ConfirmLegacyMcpStopped")) -Message "Unconfirmed adoption did not report the legacy MCP boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeRejectedAdoption -Message "Unconfirmed adoption changed the fixture."

    $adopt = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -ConfirmLegacyMcpStopped
    Assert-Result -Result $adopt -ExitCode 0 -Label "Exact-file adoption"
    $adoptedMarker = Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath) -Raw | ConvertFrom-Json
    Assert-Equal -Actual $adoptedMarker.host_use_gate_version -Expected 1 -Message "Adoption marker did not advertise the host-use gate."
    foreach ($relativePath in $managedTargets) {
        $target = Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath
        $after = Get-Item -LiteralPath $target -Force
        Assert-Equal -Actual (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -Expected $beforeAdoption[$relativePath].Sha256 -Message "Adoption rewrote file bytes: $relativePath."
        Assert-Equal -Actual $after.LastWriteTimeUtc.Ticks -Expected $beforeAdoption[$relativePath].LastWriteTicks -Message "Adoption rewrote file time: $relativePath."
        Assert-Equal -Actual ([int]$after.Attributes) -Expected $beforeAdoption[$relativePath].Attributes -Message "Adoption rewrote file attributes: $relativePath."
    }
    Write-Host "[OK] Exact-file adoption required legacy MCP confirmation and wrote only the ownership marker."

    foreach ($relativePath in $managedTargets) {
        Set-ItemProperty -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath $relativePath) -Name IsReadOnly -Value $false
    }
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Post-adoption Remove"

    $atomicTargetRelativePath = "AIWork/codedb/codedbignore.example"
    $atomicOldContent = "atomic-reader-old`n" + [string]::new([char]65, 2 * 1024 * 1024)
    $atomicNewContent = "atomic-reader-new`n" + [string]::new([char]66, 2 * 1024 * 1024)
    $atomicV1Entries = [ordered]@{ $atomicTargetRelativePath = $atomicOldContent }
    $atomicV2Entries = [ordered]@{ $atomicTargetRelativePath = $atomicNewContent }
    $atomicV1Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "atomic-v1") -PayloadVersion "test.1" -Entries $atomicV1Entries
    $atomicV2Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "atomic-v2") -PayloadVersion "test.2" -Entries $atomicV2Entries
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $atomicV1Root) -ExitCode 0 -Label "Atomic reader v1 Sync"
    $atomicTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $atomicTargetRelativePath
    $atomicOldSha256 = (Get-FileHash -LiteralPath $atomicTargetPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $atomicNewSha256 = (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $atomicV2Root -RelativePath $atomicTargetRelativePath) -Algorithm SHA256).Hash.ToLowerInvariant()
    $atomicReadyPath = Join-Path $runRoot "atomic-reader.ready"
    $atomicSawNewPath = Join-Path $runRoot "atomic-reader.saw-new"
    $atomicStopPath = Join-Path $runRoot "atomic-reader.stop"
    $atomicReaderJob = Start-Job -ArgumentList $atomicTargetPath, $atomicOldSha256, $atomicNewSha256, $atomicReadyPath, $atomicSawNewPath, $atomicStopPath -ScriptBlock {
        param($TargetPath, $OldSha256, $NewSha256, $ReadyPath, $SawNewPath, $StopPath)

        $oldReads = 0
        $newReads = 0
        $sharingRetries = 0
        $deadline = [DateTime]::UtcNow.AddSeconds(20)
        while ([DateTime]::UtcNow -lt $deadline) {
            $stream = $null
            $sha256 = $null
            $hash = $null
            try {
                $share = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
                $stream = [System.IO.File]::Open($TargetPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, $share)
                $sha256 = [System.Security.Cryptography.SHA256]::Create()
                $hash = ([System.BitConverter]::ToString($sha256.ComputeHash($stream))).Replace("-", "").ToLowerInvariant()
            } catch {
                $ioException = $_.Exception
                while ($null -ne $ioException.InnerException) {
                    $ioException = $ioException.InnerException
                }
                $win32Code = $ioException.HResult -band 0xffff
                if ($ioException -is [System.IO.IOException] -and $win32Code -in @(32, 33)) {
                    $sharingRetries++
                    [System.Threading.Thread]::Sleep(1)
                    continue
                }
                throw
            } finally {
                if ($null -ne $sha256) { $sha256.Dispose() }
                if ($null -ne $stream) { $stream.Dispose() }
            }

            if ([string]::Equals($hash, $OldSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $oldReads++
                if (-not (Test-Path -LiteralPath $ReadyPath)) {
                    [System.IO.File]::WriteAllText($ReadyPath, "ready")
                }
            } elseif ([string]::Equals($hash, $NewSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $newReads++
                if (-not (Test-Path -LiteralPath $SawNewPath)) {
                    [System.IO.File]::WriteAllText($SawNewPath, "new")
                }
            } else {
                throw "Concurrent reader observed an unexpected or partial SHA256: $hash"
            }

            if ((Test-Path -LiteralPath $StopPath) -and $oldReads -gt 0 -and $newReads -gt 0) {
                return [pscustomobject]@{ OldReads = $oldReads; NewReads = $newReads; SharingRetries = $sharingRetries }
            }
            [System.Threading.Thread]::Sleep(1)
        }
        throw "Concurrent reader timed out before observing complete old and new files."
    }
    try {
        Assert-True -Condition (Wait-ForPathState -Path $atomicReadyPath -Present $true -TimeoutMilliseconds 10000) -Message "Concurrent reader did not observe the complete old file before Sync."
        $atomicUpgrade = Invoke-Materializer -Action "Sync" -PayloadRoot $atomicV2Root
        Assert-Result -Result $atomicUpgrade -ExitCode 0 -Label "Atomic reader v2 Sync"
        Assert-True -Condition (Wait-ForPathState -Path $atomicSawNewPath -Present $true -TimeoutMilliseconds 10000) -Message "Concurrent reader did not observe the complete new file after Sync."
        Write-Utf8File -Path $atomicStopPath -Content "stop`n"
        $null = Wait-Job -Job $atomicReaderJob -Timeout 10
        Assert-Equal -Actual $atomicReaderJob.State -Expected "Completed" -Message "Concurrent reader did not complete successfully."
        $atomicReaderResult = Receive-Job -Job $atomicReaderJob -ErrorAction Stop
        Assert-True -Condition ([int]$atomicReaderResult.OldReads -gt 0) -Message "Concurrent reader recorded no old-file observations."
        Assert-True -Condition ([int]$atomicReaderResult.NewReads -gt 0) -Message "Concurrent reader recorded no new-file observations."
    } finally {
        if (-not (Test-Path -LiteralPath $atomicStopPath)) {
            Write-Utf8File -Path $atomicStopPath -Content "stop`n"
        }
        if ($atomicReaderJob.State -in @("Running", "NotStarted")) {
            Stop-Job -Job $atomicReaderJob -ErrorAction SilentlyContinue
        }
        Remove-Job -Job $atomicReaderJob -Force -ErrorAction SilentlyContinue
    }
    Assert-Equal -Actual (Get-FileHash -LiteralPath $atomicTargetPath -Algorithm SHA256).Hash.ToLowerInvariant() -Expected $atomicNewSha256 -Message "Atomic upgrade did not publish the complete new file."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $atomicV2Root) -ExitCode 0 -Label "Atomic reader v2 Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $atomicV2Root) -ExitCode 0 -Label "Atomic reader v2 Remove"
    Assert-NoMaterializerResidue
    Write-Host "[OK] Concurrent readers observed only complete old or new bytes during same-file replacement."

    $v1Entries = [ordered]@{
        "AIWork/codedb/codedb-mcp.runtime.example.toml" = "obsolete-v1`n"
        "AIWork/codedb/scripts/codedb-project-common.ps1" = "common-v1`n"
        "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1" = "prepare-stable`n"
    }
    $v2Entries = [ordered]@{
        "AIWork/codedb/scripts/codedb-project-common.ps1" = "common-v2`n"
        "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1" = "prepare-stable`n"
        "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1" = "upgrade-only-v2`n"
    }
    $v1Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "v1") -PayloadVersion "test.1" -Entries $v1Entries
    $v2Root = New-SyntheticPayload -Root (Join-Path $syntheticRoot "v2") -PayloadVersion "test.2" -Entries $v2Entries
    $collisionEntries = [ordered]@{
        "AIWork/codedb/scripts/codedb-project-common.ps1" = "same-sequence-collision`n"
        "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1" = "prepare-stable`n"
        "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1" = "upgrade-only-v2`n"
    }
    $collisionRoot = New-SyntheticPayload -Root (Join-Path $syntheticRoot "sequence-collision") -PayloadVersion "test.2-collision" -Entries $collisionEntries
    $packageMetadataRoot = New-SyntheticPayload -Root (Join-Path $syntheticRoot "package-metadata") -PayloadVersion "test.2" -Entries $v2Entries
    $packageMetadataManifestPath = Join-Path $packageMetadataRoot "payload-manifest.json"
    $packageMetadataManifest = Get-Content -LiteralPath $packageMetadataManifestPath -Raw | ConvertFrom-Json
    $packageMetadataManifest.package_version = "0.1.1-test"
    Write-Utf8File -Path $packageMetadataManifestPath -Content (($packageMetadataManifest | ConvertTo-Json -Depth 8) + "`n")
    $v2ManifestPath = Join-Path $v2Root "payload-manifest.json"
    $v2Manifest = Get-Content -LiteralPath $v2ManifestPath -Raw | ConvertFrom-Json
    $v2Manifest.retired_targets = @("AIWork/codedb/codedb-mcp.runtime.example.toml")
    Write-Utf8File -Path $v2ManifestPath -Content (($v2Manifest | ConvertTo-Json -Depth 8) + "`n")
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v1Root) -ExitCode 0 -Label "Synthetic v1 Sync"
    $retiredTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml"
    Write-Utf8File -Path $retiredTarget -Content "retired file drift`n"
    $beforeRetiredConflict = Get-FileSnapshot -Root $hostRoot
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v2Root) -ExitCode 3 -Label "Retired-file drift conflict"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeRetiredConflict -Message "Retired-file conflict caused a partial upgrade."
    Copy-Item -LiteralPath (Get-PathFromRelative -Root $v1Root -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml") -Destination $retiredTarget -Force
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v2Root) -ExitCode 0 -Label "Synthetic v2 upgrade"
    Assert-Equal -Actual (Get-Content -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/codedb-project-common.ps1") -Raw) -Expected "common-v2`n" -Message "Upgrade did not replace the changed file."
    Assert-True -Condition (-not (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/codedb-mcp.runtime.example.toml"))) -Message "Upgrade did not retire the removed payload file."
    Assert-True -Condition (Test-Path -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1") -PathType Leaf) -Message "Upgrade did not install the new payload file."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $v2Root) -ExitCode 0 -Label "Synthetic v2 Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $packageMetadataRoot) -ExitCode 0 -Label "Same-payload package metadata Sync"
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $packageMetadataRoot) -ExitCode 0 -Label "Same-payload package metadata Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $v2Root) -ExitCode 0 -Label "Same-payload package metadata restore"
    $beforeDowngrade = Get-FileSnapshot -Root $hostRoot
    $collisionDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $collisionRoot
    Assert-Result -Result $collisionDryRun -ExitCode 0 -Label "Synthetic sequence-collision DryRun"
    Assert-True -Condition ($collisionDryRun.Text.Contains("[CONFLICT] SequenceCollision:")) -Message "Sequence-collision DryRun did not identify the reused sequence."
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $collisionRoot) -ExitCode 3 -Label "Synthetic sequence-collision Sync rejection"
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $collisionRoot) -ExitCode 3 -Label "Synthetic sequence-collision Remove rejection"
    $downgradeSync = Invoke-Materializer -Action "Sync" -PayloadRoot $v1Root
    Assert-Result -Result $downgradeSync -ExitCode 3 -Label "Synthetic downgrade Sync rejection"
    Assert-True -Condition ($downgradeSync.Text.Contains("[CONFLICT] Downgrade:")) -Message "Downgrade Sync did not report the installed/requested sequence boundary."
    $downgradeRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $v1Root
    Assert-Result -Result $downgradeRemove -ExitCode 3 -Label "Synthetic downgrade Remove rejection"
    Assert-True -Condition ($downgradeRemove.Text.Contains("[CONFLICT] Downgrade:")) -Message "Downgrade Remove did not report the installed/requested sequence boundary."
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeDowngrade -Message "Downgrade rejection changed host files."
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $v2Root) -ExitCode 0 -Label "Synthetic v2 Remove"
    Write-Host "[OK] Synthetic upgrade, package-only metadata update, retired drift refusal, sequence-collision refusal, and Sync/Remove downgrade refusal passed."

    $conflictTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1"
    Write-Utf8File -Path $conflictTarget -Content "foreign unowned content`n"
    $beforeUnownedConflict = Get-FileSnapshot -Root $hostRoot
    $unownedConflict = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $unownedConflict -ExitCode 3 -Label "Unowned-file conflict"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeUnownedConflict -Message "Unowned conflict caused partial writes."
    Remove-Item -LiteralPath $conflictTarget -Force
    Assert-NoMaterializerResidue
    Write-Host "[OK] Unowned-file conflict rejected the entire Sync."

    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Managed drift setup"
    $driftTarget = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1"
    Write-Utf8File -Path $driftTarget -Content "managed drift`n"
    $canonicalV2Entries = [ordered]@{}
    foreach ($relativePath in $managedTargets) {
        $canonicalV2Entries[$relativePath] = [System.IO.File]::ReadAllText((Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $relativePath))
    }
    $canonicalV2Entries["AIWork/codedb/scripts/codedb-project-common.ps1"] = "package upgrade that must not partially apply`n"
    $conflictingUpgradeRoot = New-SyntheticPayload -Root (Join-Path $syntheticRoot "conflicting-upgrade") -PayloadVersion "poc.2-test" -Entries $canonicalV2Entries
    $beforeManagedConflict = Get-FileSnapshot -Root $hostRoot
    $managedConflict = Invoke-Materializer -Action "Sync" -PayloadRoot $conflictingUpgradeRoot
    Assert-Result -Result $managedConflict -ExitCode 3 -Label "Managed-file drift conflict"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeManagedConflict -Message "Managed drift conflict caused a partial upgrade."
    $removeConflict = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $removeConflict -ExitCode 3 -Label "Drifted Remove"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeManagedConflict -Message "Drifted Remove deleted or rewrote files."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Managed drift blocked both upgrade and Remove without partial writes."

    Copy-Item -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1") -Destination $driftTarget -Force
    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    $originalMarkerText = Get-Content -LiteralPath $markerPath -Raw
    $tamperedMarker = $originalMarkerText | ConvertFrom-Json
    $tamperedMarker.files += [pscustomobject]@{
        path = "AIWork/codedb/adoption-decision.md"
        installed_sha256 = (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/adoption-decision.md") -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    Write-Utf8File -Path $markerPath -Content (($tamperedMarker | ConvertTo-Json -Depth 8) + "`n")
    $beforeTamperedRemove = Get-FileSnapshot -Root $hostRoot
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot) -ExitCode 2 -Label "Tampered marker Remove"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeTamperedRemove -Message "Tampered marker caused host file changes."
    Write-Utf8File -Path $markerPath -Content $originalMarkerText
    Write-Host "[OK] Marker cannot extend ownership to a host-only document."

    $exactRemove = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $exactRemove -ExitCode 0 -Label "Exact-owner Remove"
    Assert-CanonicalFilesRemoved
    Assert-SentinelsUnchanged -ExpectedSnapshot $sentinelSnapshot
    Assert-NoMaterializerResidue
    Write-Host "[OK] Exact-owner Remove preserved every unrelated sentinel."

    $eolRelativePath = "AIWork/codedb/scripts/codedb-project-common.ps1"
    $eolPayloadPath = Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $eolRelativePath
    $eolTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $eolRelativePath
    $lfPayloadText = [System.IO.File]::ReadAllText($eolPayloadPath)
    Assert-True -Condition (-not $lfPayloadText.Contains("`r`n")) -Message "Canonical payload EOL fixture is not LF-only."
    $crlfHostText = $lfPayloadText.Replace("`n", "`r`n")
    Write-Utf8File -Path $eolTargetPath -Content $crlfHostText
    Assert-True `
        -Condition (-not [string]::Equals((Get-FileHash -LiteralPath $eolTargetPath -Algorithm SHA256).Hash, (Get-FileHash -LiteralPath $eolPayloadPath -Algorithm SHA256).Hash, [StringComparison]::OrdinalIgnoreCase)) `
        -Message "CRLF host fixture unexpectedly matched the LF payload hash."
    $beforeEolConflict = Get-FileSnapshot -Root $hostRoot
    $eolDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot
    Assert-Result -Result $eolDryRun -ExitCode 0 -Label "CRLF host DryRun"
    Assert-True -Condition ($eolDryRun.Text.Contains("[CONFLICT] Conflict: $eolRelativePath")) -Message "CRLF host DryRun did not report an exact-byte conflict."
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 3 -Label "CRLF host Sync refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeEolConflict -Message "CRLF conflict changed the fixture."
    Remove-Item -LiteralPath $eolTargetPath -Force
    Assert-NoMaterializerResidue
    Write-Host "[OK] CRLF host content was not normalized or adopted against the LF payload hash."

    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot) -ExitCode 0 -Label "Git staged-change setup Sync"
    $null = Invoke-FixtureIndexGit -Arguments @("read-tree", "--empty")

    $stagedRelativePath = "AIWork/codedb/scripts/codedb-project-common.ps1"
    $stagedTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $stagedRelativePath
    $stagedGitPath = Get-ProjectGitPath -Path $stagedTargetPath
    Write-Utf8File -Path $stagedTargetPath -Content "staged managed variant`n"
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $stagedGitPath)
    Copy-Item -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $stagedRelativePath) -Destination $stagedTargetPath -Force
    Assert-Equal `
        -Actual (Get-FileHash -LiteralPath $stagedTargetPath -Algorithm SHA256).Hash `
        -Expected (Get-FileHash -LiteralPath (Get-PathFromRelative -Root $canonicalPayloadRoot -RelativePath $stagedRelativePath) -Algorithm SHA256).Hash `
        -Message "Managed staged-change fixture did not restore exact working-tree bytes."
    $beforeStagedManagedGate = Get-FileSnapshot -Root $hostRoot
    $stagedDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $stagedDryRun -ExitCode 0 -Label "Managed staged-change DryRun"
    Assert-True -Condition ($stagedDryRun.Text.Contains("[CONFLICT] GitStaged: $stagedRelativePath")) -Message "DryRun did not report the staged managed target."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 3 -Label "Managed staged-change Verify refusal"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 3 -Label "Managed staged-change Sync refusal"
    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 3 -Label "Managed staged-change Remove refusal"
    Assert-Equal -Actual (Get-FileSnapshot -Root $hostRoot) -Expected $beforeStagedManagedGate -Message "Managed staged-change refusal changed host files."
    Assert-NoMaterializerResidue
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $stagedGitPath)

    $markerPath = Get-PathFromRelative -Root $hostRoot -RelativePath $markerRelativePath
    $markerGitPath = Get-ProjectGitPath -Path $markerPath
    $exactMarkerText = Get-Content -LiteralPath $markerPath -Raw
    Write-Utf8File -Path $markerPath -Content ($exactMarkerText + "`n")
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $markerGitPath)
    Write-Utf8File -Path $markerPath -Content $exactMarkerText
    $stagedMarkerVerify = Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $stagedMarkerVerify -ExitCode 3 -Label "Staged ownership-marker Verify refusal"
    Assert-True -Condition ($stagedMarkerVerify.Text.Contains("[CONFLICT] GitStaged: $markerRelativePath")) -Message "Verify did not report the staged ownership marker."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $markerGitPath)

    $unrelatedTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath "Assets/BusinessSentinel.txt"
    $unrelatedGitPath = Get-ProjectGitPath -Path $unrelatedTargetPath
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $unrelatedGitPath)
    $unrelatedDryRun = Invoke-Materializer -Action "DryRun" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $unrelatedDryRun -ExitCode 0 -Label "Unrelated staged-change DryRun"
    Assert-True -Condition (-not $unrelatedDryRun.Text.Contains("[CONFLICT] GitStaged:")) -Message "An unrelated staged business file blocked the managed payload scope."
    Assert-Result -Result (Invoke-Materializer -Action "Verify" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 0 -Label "Unrelated staged-change Verify"
    Assert-Result -Result (Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 0 -Label "Unrelated staged-change no-op Sync"
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $unrelatedGitPath)
    Write-Host "[OK] Managed files and the ownership marker reject staged index state while unrelated staged files remain out of scope."

    Assert-Result -Result (Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath) -ExitCode 0 -Label "Staged recovery setup Remove"
    $crashedStagedInstall = Invoke-Materializer -Action "Sync" -PayloadRoot $canonicalPayloadRoot -TestCrashAfterMutation 1 -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $crashedStagedInstall -ExitCode 86 -Label "Staged recovery install crash"
    $recoveryRelativePath = "AIWork/codedb/codedbignore.example"
    $recoveryTargetPath = Get-PathFromRelative -Root $hostRoot -RelativePath $recoveryRelativePath
    $recoveryGitPath = Get-ProjectGitPath -Path $recoveryTargetPath
    $recoveryTargetText = Get-Content -LiteralPath $recoveryTargetPath -Raw
    Write-Utf8File -Path $recoveryTargetPath -Content "staged recovery variant`n"
    $null = Invoke-FixtureIndexGit -Arguments @("add", "-f", "--", $recoveryGitPath)
    Write-Utf8File -Path $recoveryTargetPath -Content $recoveryTargetText
    $recoveryTargetHash = (Get-FileHash -LiteralPath $recoveryTargetPath -Algorithm SHA256).Hash
    $blockedStagedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $blockedStagedRecovery -ExitCode 3 -Label "Staged interrupted-transaction recovery refusal"
    Assert-True -Condition ($blockedStagedRecovery.Text.Contains("[CONFLICT] GitStaged: $recoveryRelativePath")) -Message "Interrupted recovery did not report its staged target."
    Assert-Equal -Actual (Get-FileHash -LiteralPath $recoveryTargetPath -Algorithm SHA256).Hash -Expected $recoveryTargetHash -Message "Blocked staged recovery changed the target bytes."
    $null = Invoke-FixtureIndexGit -Arguments @("rm", "--cached", "-f", "--", $recoveryGitPath)
    $completedStagedRecovery = Invoke-Materializer -Action "Remove" -PayloadRoot $canonicalPayloadRoot -GitIndexFile $fixtureGitIndexPath
    Assert-Result -Result $completedStagedRecovery -ExitCode 0 -Label "Unstaged interrupted-transaction recovery"
    Assert-True -Condition ($completedStagedRecovery.Text.Contains("[RECOVERED] Rolled back interrupted sync transaction.")) -Message "Unstaged retry did not recover the interrupted transaction."
    Assert-CanonicalFilesRemoved
    Assert-NoMaterializerResidue
    Write-Host "[OK] Interrupted transaction recovery also refuses staged managed targets until the index is cleared."

    $escapeRoot = Join-Path $syntheticRoot "escape"
    New-Item -ItemType Directory -Force -Path $escapeRoot | Out-Null
    Write-Utf8File -Path (Join-Path $escapeRoot "safe.ps1") -Content "safe`n"
    $escapeManifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        package_version = "0.1.0-test"
        payload_version = "escape-test"
        payload_sequence = 1
        retired_targets = @()
        files = @([ordered]@{
            source = "safe.ps1"
            target = "../escaped.ps1"
            sha256 = (Get-FileHash -LiteralPath (Join-Path $escapeRoot "safe.ps1") -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }
    Write-Utf8File -Path (Join-Path $escapeRoot "payload-manifest.json") -Content (($escapeManifest | ConvertTo-Json -Depth 8) + "`n")
    $escapeResult = Invoke-Materializer -Action "Sync" -PayloadRoot $escapeRoot
    Assert-Result -Result $escapeResult -ExitCode 2 -Label "Path escape rejection"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $hostRoot "escaped.ps1"))) -Message "Unsafe manifest escaped the managed target root."
    Assert-NoMaterializerResidue
    Write-Host "[OK] Unsafe manifest paths are rejected before writes."

    Assert-SentinelsUnchanged -ExpectedSnapshot $sentinelSnapshot
    Assert-Equal -Actual (Get-FileSnapshot -Root $packageRoot) -Expected $packageSnapshotBefore -Message "POC modified package source files."
    Write-Host "[OK] CodeDB host payload materializer POC passed all scenarios."
} finally {
    if ($null -ne $activeMcpProcess) {
        try {
            if (-not $activeMcpProcess.HasExited) {
                $activeMcpProcess.Kill()
                $activeMcpProcess.WaitForExit()
            }
            $activeMcpProcess.Dispose()
        } catch {
            Write-Warning "Fixture MCP cleanup failed: $($_.Exception.Message)"
        }
        $activeMcpProcess = $null
    }
    if ($activeWatchManagerPath -or $activeWatchLifecycleId) {
        try {
            if ($activeWatchManagerPath -and (Test-Path -LiteralPath $activeWatchManagerPath -PathType Leaf)) {
                $cleanupResult = Invoke-PowerShellAction -Action {
                    if ($activeWatchLifecycleId) {
                        & $activeWatchManagerPath -Action Stop -ExpectedLifecycleId $activeWatchLifecycleId
                    } else {
                        & $activeWatchManagerPath -Action Stop
                    }
                }
                if ($cleanupResult.ExitCode -ne 0) {
                    Write-Warning "Fixture watcher cleanup through the manager failed: $($cleanupResult.Text)"
                }
            }
            $cleanupCoordinator = Get-PathFromRelative -Root $hostRoot -RelativePath "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs"
            $cleanupRuntime = Join-Path $hostRoot "AIWork\.runtime\codedb\codedb-fixture\watch\coordinator"
            $cleanupState = Join-Path $cleanupRuntime "coordinator-state.json"
            if ((Test-Path -LiteralPath $cleanupCoordinator -PathType Leaf) -and (Test-Path -LiteralPath $cleanupState -PathType Leaf)) {
                $global:LASTEXITCODE = 0
                $cleanupArguments = @($cleanupCoordinator, "stop", "--runtime", $cleanupRuntime)
                if ($activeWatchLifecycleId) {
                    $cleanupArguments += @("--expected-lifecycle-id", $activeWatchLifecycleId)
                }
                $cleanupOutput = @(& $nodePath @cleanupArguments 2>&1)
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Fixture watcher cleanup through the coordinator failed: $($cleanupOutput -join [Environment]::NewLine)"
                }
            }
        } catch {
            Write-Warning "Fixture watcher cleanup failed: $($_.Exception.Message)"
        }
    }
    if ($null -ne $junctionPath -and (Test-Path -LiteralPath $junctionPath)) {
        $junctionItem = Get-Item -LiteralPath $junctionPath -Force
        if (($junctionItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusing to clean an unexpected non-junction path: $junctionPath"
        }
        [System.IO.Directory]::Delete($junctionPath)
        $junctionPath = $null
    }
    if ($null -ne $readEscapeJunctionPath -and (Test-Path -LiteralPath $readEscapeJunctionPath)) {
        $readEscapeItem = Get-Item -LiteralPath $readEscapeJunctionPath -Force
        if (($readEscapeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusing to clean an unexpected non-junction path: $readEscapeJunctionPath"
        }
        [System.IO.Directory]::Delete($readEscapeJunctionPath)
        $readEscapeJunctionPath = $null
    }
    if (Test-Path -LiteralPath $runRoot) {
        $fullRunRoot = [System.IO.Path]::GetFullPath($runRoot)
        $fullPocRoot = [System.IO.Path]::GetFullPath($pocRoot).TrimEnd('\', '/')
        if ($fullRunRoot.StartsWith($fullPocRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -and
            -not [string]::Equals($fullRunRoot, $fullPocRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Assert-NoReparseAncestors -Path $fullRunRoot -Root $projectRoot
            Assert-NoReparseTree -Root $fullRunRoot
            Get-ChildItem -LiteralPath $fullRunRoot -Recurse -Force -File -ErrorAction SilentlyContinue | ForEach-Object {
                $_.IsReadOnly = $false
            }
            Remove-Item -LiteralPath $fullRunRoot -Recurse -Force
        } else {
            throw "Refusing to clean an unsafe POC path: $fullRunRoot"
        }
    }
    if ((Test-Path -LiteralPath $pocRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $pocRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $pocRoot -Force
    }
}

Assert-True -Condition (-not (Test-Path -LiteralPath $runRoot)) -Message "POC fixture cleanup failed: $runRoot"
