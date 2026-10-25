#requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $package
$run = Join-Path $repo ('.artifacts/tests/s42-ipc-diagnostics/' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($run)
$utf8 = [Text.UTF8Encoding]::new($false)
$savedTemp = $env:TEMP
$savedTmp = $env:TMP
$env:TEMP = $run
$env:TMP = $run
$checks = [Collections.Generic.List[string]]::new()
$observations = [Collections.Generic.List[object]]::new()
$receipt = [ordered]@{
    schema_version = 1; outcome = 'RUNNING'; started_at_utc = [DateTime]::UtcNow.ToString('o')
    powershell = $PSVersionTable.PSVersion.ToString(); framework = [Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    source_sha256 = $null; harness_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()
    runtime_sha256 = (Get-FileHash -LiteralPath (Join-Path $PSHOME 'pwsh.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
    extracted_transport_sha256 = $null; fixture_sha256 = $null; checks = $checks; observations = $observations
    unity = 'NOT_RUN'; editmode = 'NOT_RUN'; product_services = 'NOT_RUN'
}
function Check([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "Check failed: $Name" }
    $checks.Add($Name)
}
function Parse-Diagnostic([string]$Text) {
    $marker = '[CODEDB_IPC_DIAGNOSTIC] '
    $position = $Text.IndexOf($marker, [StringComparison]::Ordinal)
    Check ($position -ge 0) 'Structured diagnostic present'
    Check (-not $Text.Contains("`n") -and -not $Text.Contains("`r")) 'Diagnostic retained on the first error line'
    $value = $Text.Substring($position + $marker.Length) | ConvertFrom-Json
    Check ($value.schema_version -eq 1) 'Diagnostic schema 1'
    Check ($value.elapsed_ms -ge 0 -and $value.connect_ms -ge 0 -and $value.write_ms -ge 0 -and $value.read_ms -ge 0) 'Nonnegative stage durations'
    Check ([Math]::Abs($value.elapsed_ms - $value.connect_ms - $value.write_ms - $value.read_ms) -le 0.01) 'Stage durations account for elapsed time'
    Check ($Text -match '"started_at_utc":"[^"]+Z"') 'UTC timestamp supplied'
    return $value
}
try {
    $sourcePath = Join-Path $package 'Editor/AICodedbSupervisorBridge.cs'
    $source = [IO.File]::ReadAllText($sourcePath)
    $receipt.source_sha256 = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $start = $source.IndexOf('        internal sealed class IpcExchangeDiagnostic', [StringComparison]::Ordinal)
    $end = $source.IndexOf('        internal static string SerializeJsonObject', $start, [StringComparison]::Ordinal)
    Check ($start -ge 0 -and $end -gt $start) 'Exact production diagnostic and transport extraction boundaries'
    $transport = $source.Substring($start, $end - $start)
    $constants = @([regex]::Matches($source, '        internal const int (?:MaximumMessageBytes|ConnectionTimeoutMilliseconds) = [^;]+;') | ForEach-Object Value)
    Check ($constants.Count -eq 2) 'Exact production protocol constants extracted'
    Check ($source.Contains('internal const int ConnectionTimeoutMilliseconds = 1500;') -and $source.Contains('internal const int MaximumMessageBytes = 64 * 1024;')) 'Original timeouts and message bound retained'
    $exception = [regex]::Match($source, '(?s)        private sealed class SupervisorMessageTooLargeException : InvalidOperationException.*?(?=        private readonly struct SupervisorRuntimeIdentity)').Value
    Check (-not [string]::IsNullOrEmpty($exception)) 'Exact production message-limit exception extracted'
    Check ($source.Contains('new IpcExchangeDiagnostic("command", command, action, originalRequestId, null)')) 'Initial command context wired'
    Check ($source.Contains('new IpcExchangeDiagnostic("operation_poll", command, action, pollRequestId, operationId)')) 'Operation poll context wired'
    Check (([regex]::Matches($source, 'internal static string SendPipeRequest\(')).Count -eq 2) 'Three-argument compatibility overload retained'
    Check ($source.Contains('return SendPipeRequest(pipeName, request, cancellationToken, null);')) 'Compatibility overload forwards to diagnostic transport'
    Check ($source -match 'WaitForAcceptedOperation\(\s*responseLine,\s*normalizedRoot,\s*identity,\s*cancellationToken,\s*command,\s*action\)') 'Original command and action reach operation polling'
    Check ($source -match 'BuildOperationRequest\(\s*identity.AuthToken,\s*pollRequestId,\s*operationId\)') 'Poll diagnostic uses the actual request ID'
    Check ($source.Contains('uncertain ? "SUPERVISOR_OUTCOME_UNCONFIRMED" : "SUPERVISOR_IPC_TIMEOUT"')) 'Existing failure codes retained'
    Check ($transport.Contains('exception.Message + " " + diagnostic.FormatTimeout(), exception')) 'Original timeout prefix and inner exception retained'
    Check (-not ($transport -match 'ReadTimeout\s*=|WriteTimeout\s*=|Thread.Sleep|File\.|Console\.|Debug\.')) 'No stream timeout setters, logging or new sleeps'
    $header = @'
using System;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
public static class AICodedbSupervisorProtocol
{
'@
    $fixture = @'
public sealed class IpcFixtureResult
{
    public string Response;
    public string ErrorType;
    public string InnerType;
    public string Message;
    public string Diagnostic;
    public bool ClientClosed;
    public bool PipeDisposed;
}
public static class IpcDiagnosticsFixture
{
'@
    $tests = @'
    private static IpcFixtureResult Capture(Func<string> action, IpcExchangeDiagnostic diagnostic)
    {
        var result = new IpcFixtureResult();
        try { result.Response = action(); }
        catch (TimeoutException error)
        {
            result.ErrorType = error.GetType().Name;
            result.InnerType = error.InnerException == null ? null : error.InnerException.GetType().Name;
            result.Message = error.Message;
        }
        catch (OperationCanceledException error) { result.ErrorType = error.GetType().Name; result.Message = error.Message; }
        result.Diagnostic = diagnostic.FormatTimeout();
        return result;
    }
    public static IpcFixtureResult PipeCase(string scenario, string kind)
    {
        var name = "codedb-ipc-fixture-" + Guid.NewGuid().ToString("N");
        var diagnostic = new IpcExchangeDiagnostic(kind, "materialize", "Probe", new string('a', 32),
            kind == "operation_poll" ? new string('b', 32) : null);
        using (var lifetime = new CancellationTokenSource(6000))
        using (var cancellation = new CancellationTokenSource())
        using (var server = new NamedPipeServerStream(name, PipeDirection.InOut, 1,
            PipeTransmissionMode.Byte, PipeOptions.Asynchronous))
        {
            var closed = false;
            var serverTask = Task.Run(async () =>
            {
                await server.WaitForConnectionAsync(lifetime.Token);
                var buffer = new byte[1];
                var request = new StringBuilder();
                while (true)
                {
                    var count = await server.ReadAsync(buffer, 0, 1, lifetime.Token);
                    if (count == 0) throw new InvalidOperationException("Fixture request ended early.");
                    if (buffer[0] == '\n') break;
                    request.Append((char)buffer[0]);
                    if (request.Length > 256) throw new InvalidOperationException("Fixture request exceeded its bound.");
                }
                if (request.ToString() != "{\"synthetic_private_body\":true}")
                    throw new InvalidOperationException("Fixture request mismatch.");
                var response = Encoding.UTF8.GetBytes(scenario == "success" ? "{\"ok\":true}\n" : "{\"ok\":");
                await server.WriteAsync(response, 0, response.Length, lifetime.Token);
                if (scenario == "cancel") cancellation.CancelAfter(100);
                closed = await server.ReadAsync(buffer, 0, 1, lifetime.Token) == 0;
            });
            try
            {
                var result = Capture(() => SendPipeRequest(name, "{\"synthetic_private_body\":true}",
                    cancellation.Token, diagnostic), diagnostic);
                serverTask.GetAwaiter().GetResult();
                result.ClientClosed = closed;
                return result;
            }
            finally
            {
                lifetime.Cancel();
                server.Dispose();
                // Every task belongs to this fixture and must finish before returning.
                try { serverTask.GetAwaiter().GetResult(); }
                catch (OperationCanceledException) { }
            }
        }
    }
    public static IpcFixtureResult ConnectTimeout()
    {
        var diagnostic = new IpcExchangeDiagnostic("command", "materialize", "Probe", new string('a', 32), null);
        return Capture(() => SendPipeRequest("codedb-ipc-fixture-absent-" + Guid.NewGuid().ToString("N"),
            "{}", CancellationToken.None, diagnostic), diagnostic);
    }
    public static IpcFixtureResult PendingWrite(bool canceled)
    {
        var diagnostic = new IpcExchangeDiagnostic("command", "materialize", "Probe", new string('a', 32), null);
        diagnostic.Enter("write");
        var pending = new TaskCompletionSource<bool>();
        using (var cancellation = new CancellationTokenSource())
        using (var pipe = new NamedPipeServerStream("codedb-ipc-fixture-unused-" + Guid.NewGuid().ToString("N"),
            PipeDirection.InOut, 1, PipeTransmissionMode.Byte, PipeOptions.Asynchronous))
        {
            var handle = pipe.SafePipeHandle;
            if (canceled) cancellation.Cancel();
            // Deterministic waiter boundary, not an OS pipe-buffer saturation claim.
            var result = Capture(() =>
            {
                WaitForPipeIo((Task)pending.Task, pipe, DateTime.UtcNow.AddMilliseconds(-1), cancellation.Token);
                throw new InvalidOperationException("Pending write unexpectedly completed.");
            }, diagnostic);
            result.PipeDisposed = handle.IsClosed;
            pending.SetResult(true);
            return result;
        }
    }
    public static string[] SafeFields(string relativePrivatePath, string privatePath)
    {
        return new[]
        {
            new IpcExchangeDiagnostic("unknown", relativePrivatePath + "\"\n", "secret value", new string('z', 32), "secret").FormatTimeout(),
            new IpcExchangeDiagnostic("command", new string('x', 65), "", null, null).FormatTimeout(),
            new IpcExchangeDiagnostic("operation_poll", new string('x', 64), "Probe_1-test", new string('a', 32), new string('b', 32)).FormatTimeout(),
            new IpcExchangeDiagnostic("unknown", privatePath + "\"\n", "secret value", new string('z', 32), "secret").FormatTimeout()
        };
    }
}
'@
    $compiled = $header + "`n" + ($constants -join "`n") + "`n}`n" + $fixture + "`n" + $exception + $transport + $tests
    [IO.File]::WriteAllText((Join-Path $run 'extracted-transport.cs'), $transport, $utf8)
    [IO.File]::WriteAllText((Join-Path $run 'fixture.cs'), $compiled, $utf8)
    $receipt.extracted_transport_sha256 = (Get-FileHash -LiteralPath (Join-Path $run 'extracted-transport.cs') -Algorithm SHA256).Hash.ToLowerInvariant()
    $receipt.fixture_sha256 = (Get-FileHash -LiteralPath (Join-Path $run 'fixture.cs') -Algorithm SHA256).Hash.ToLowerInvariant()
    Add-Type -TypeDefinition $compiled -Language CSharp
    Check $true 'Extracted production transport compiles in offline fixture'
    Add-Type -TypeDefinition @'
using System;
using System.Threading;
public static class MethodGroupCompatibilityFixture
{
    private static string SendPipeRequest(string pipeName, string request, CancellationToken cancellationToken) { return null; }
    private static string SendPipeRequest(string pipeName, string request, CancellationToken cancellationToken, object diagnostic = null) { return null; }
    public static void Verify() { Func<string, string, CancellationToken, string> callback = SendPipeRequest; }
}
'@ -Language CSharp
    [MethodGroupCompatibilityFixture]::Verify()
    Check $true 'Three-argument method-group binding compiles'

    $privatePath = Join-Path $run 'private/token'
    $relativePrivatePath = [IO.Path]::GetRelativePath($run, $privatePath)
    Check ($relativePrivatePath.Length + 2 -le 64) 'Owned relative-path sample reaches malformed-character classification'
    $safe = [IpcDiagnosticsFixture]::SafeFields($relativePrivatePath, $privatePath)
    $invalid = Parse-Diagnostic $safe[0]
    Check ($invalid.kind -ceq 'other' -and $invalid.command -ceq 'omitted' -and $invalid.action -ceq 'omitted' -and $invalid.request_id -ceq 'omitted' -and $invalid.operation_id -ceq 'not_provided') 'Malformed fields omitted without serializing sensitive input'
    Check (-not ($safe[0] -match 'private|secret|token')) 'Injected path and private strings absent'
    $missing = Parse-Diagnostic $safe[1]
    Check ($missing.command -ceq 'not_provided' -and $missing.action -ceq 'not_provided') 'Empty and oversized fields bounded'
    $valid = Parse-Diagnostic $safe[2]
    Check ($valid.command.Length -eq 64 -and $valid.action -ceq 'Probe_1-test' -and $valid.request_id -ceq ('a' * 32) -and $valid.operation_id -ceq ('b' * 32)) 'Valid bounded fields and correlation IDs preserved'
    $absolute = Parse-Diagnostic $safe[3]
    $expectedAbsoluteCommand = if ($privatePath.Length + 2 -gt 64) { 'not_provided' } else { 'omitted' }
    Check ($absolute.command -ceq $expectedAbsoluteCommand) 'Owned absolute-path sample retains length-before-character classification'
    Check (-not $safe[3].Contains($privatePath) -and -not ($safe[3] -match 'private|secret|token')) 'Owned absolute path and private strings absent'
    $observations.Add([ordered]@{ case = 'safe_fields'; diagnostics = @($safe) })

    $success = [IpcDiagnosticsFixture]::PipeCase('success', 'command')
    Check ($success.Response -ceq '{"ok":true}' -and $null -eq $success.ErrorType -and $success.ClientClosed) 'Successful response unchanged and client pipe closed'
    # Complete is inspected here only; production emits no successful-request diagnostic.
    $complete = $success.Diagnostic.Substring($success.Diagnostic.IndexOf('{')) | ConvertFrom-Json
    Check ($complete.stage -ceq 'complete' -and $complete.received_bytes -eq 12) 'Success completes all stages and counts response bytes including newline'
    $observations.Add([ordered]@{ case = 'success'; outcome = 'PASS'; diagnostic = $complete })

    foreach ($kind in @('command', 'operation_poll')) {
        $timeout = [IpcDiagnosticsFixture]::PipeCase('partial', $kind)
        Check ($timeout.ErrorType -ceq 'TimeoutException' -and $timeout.InnerType -ceq 'TimeoutException' -and $timeout.ClientClosed) 'Partial response preserves timeout classification and disposes client pipe'
        Check ($timeout.Message.StartsWith('The Supervisor IPC request timed out. [CODEDB_IPC_DIAGNOSTIC] ')) 'Original exchange timeout message is the prefix'
        Check (-not $timeout.Message.Contains('synthetic_private_body')) 'Request body absent from timeout'
        $read = Parse-Diagnostic $timeout.Message
        Check ($read.stage -ceq 'read' -and $read.received_bytes -eq 6 -and $read.kind -ceq $kind) 'Partial-read stage, byte count and caller kind distinguished'
        Check ($read.request_id -ceq ('a' * 32) -and $read.operation_id -ceq $(if ($kind -eq 'operation_poll') { 'b' * 32 } else { 'not_provided' })) 'Initial and poll correlation IDs preserved'
        $observations.Add([ordered]@{ case = ('partial_' + $kind); outcome = 'PASS'; diagnostic = $read })
    }
    $connect = [IpcDiagnosticsFixture]::ConnectTimeout()
    Check ($connect.ErrorType -ceq 'TimeoutException' -and $connect.InnerType -ceq 'TimeoutException') 'Connect timeout preserves exception class and original cause'
    $connecting = Parse-Diagnostic $connect.Message
    Check ($connecting.stage -ceq 'connect' -and $connecting.received_bytes -eq 0 -and $connecting.write_ms -eq 0 -and $connecting.read_ms -eq 0) 'Connect timeout distinguished from exchange timeout'
    $observations.Add([ordered]@{ case = 'connect_timeout'; outcome = 'PASS'; diagnostic = $connecting })

    $cancel = [IpcDiagnosticsFixture]::PipeCase('cancel', 'operation_poll')
    Check ($cancel.ErrorType -ceq 'OperationCanceledException' -and $cancel.ClientClosed) 'Read cancellation remains cancellation and disposes pipe'
    Check (-not $cancel.Message.Contains('[CODEDB_IPC_DIAGNOSTIC]')) 'Cancellation is not relabeled as a diagnostic timeout'
    $observations.Add([ordered]@{ case = 'read_cancellation'; outcome = 'PASS'; category = $cancel.ErrorType })
    foreach ($canceled in @($false, $true)) {
        $write = [IpcDiagnosticsFixture]::PendingWrite($canceled)
        Check $write.PipeDisposed 'Pending write waiter disposes owned pipe'
        if ($canceled) {
            Check ($write.ErrorType -ceq 'OperationCanceledException') 'Canceled expired write keeps cancellation precedence'
        } else {
            Check ($write.ErrorType -ceq 'TimeoutException' -and $write.Message -ceq 'The Supervisor IPC request timed out.') 'Expired pending write retains original waiter timeout'
            $writing = Parse-Diagnostic $write.Diagnostic
            Check ($writing.stage -ceq 'write' -and $writing.received_bytes -eq 0 -and $writing.read_ms -eq 0) 'Deterministic write-stage accumulator distinguished'
        }
        $observations.Add([ordered]@{ case = ('pending_write_canceled_' + $canceled); outcome = 'PASS'; category = $write.ErrorType })
    }
    $receipt.outcome = 'PASS'
} catch {
    $receipt.outcome = 'FAIL'
    # Preserve failure identity without serializing absolute paths or test request data.
    $receipt.failure = $_.Exception.GetType().Name
    throw
} finally {
    $receipt.completed_at_utc = [DateTime]::UtcNow.ToString('o')
    [IO.File]::WriteAllText((Join-Path $run 'receipt.json'), ($receipt | ConvertTo-Json -Depth 12), $utf8)
    $env:TEMP = $savedTemp
    $env:TMP = $savedTmp
    Write-Host ($receipt.outcome + ': ' + $checks.Count + ' focused checks; receipt ' + (Join-Path $run 'receipt.json'))
}
