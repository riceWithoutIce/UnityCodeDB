using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    /// <summary>
    /// Starts the project-local Supervisor from a worker thread. The launcher
    /// owns only the short-lived Node start request; the detached Supervisor
    /// owns its coordinator, Provider, and command lifecycle thereafter.
    /// </summary>
    internal static class AICodedbSupervisorLauncher
    {
        private const int StartTimeoutMilliseconds = 35000;

        internal static Task<AICodedbCommandResult> EnsureStartedAsync(
            AICodedbEditorExecutionContext context,
            CancellationToken cancellationToken)
        {
            if (context.Platform != UnityEngine.RuntimePlatform.WindowsEditor)
            {
                return Task.FromResult(new AICodedbCommandResult(
                    4,
                    string.Empty,
                    "The project Supervisor is currently supported only in the Windows Editor.",
                    false));
            }

            return Task.Run(
                () => StartWorker(context, cancellationToken),
                cancellationToken);
        }

        internal static string GetSupervisorRuntimePath(string projectRoot)
        {
            return AICodedbPaths.NormalizePath(Path.Combine(
                projectRoot,
                AICodedbProjectSettings.InstanceControlRelativePath,
                "supervisor"));
        }

        internal static string GetSupervisorStatePath(string projectRoot)
        {
            return AICodedbPaths.NormalizePath(Path.Combine(
                GetSupervisorRuntimePath(projectRoot),
                "supervisor-state.json"));
        }

        internal static void ValidateLaunchRoots(
            string projectRoot,
            string packageRoot,
            string runtime,
            string supervisorScript)
        {
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(projectRoot, runtime);
            AICodedbProjectIntegrationStateStore.AssertNoReparsePoint(packageRoot, supervisorScript);
        }

        private static AICodedbCommandResult StartWorker(
            AICodedbEditorExecutionContext context,
            CancellationToken cancellationToken)
        {
            try
            {
                cancellationToken.ThrowIfCancellationRequested();
                var packageRoot = AICodedbPaths.NormalizePath(context.PackageRoot);
                var supervisorScript = AICodedbPaths.NormalizePath(Path.Combine(
                    packageRoot,
                    "Tools~",
                    "codedb-project-supervisor.mjs"));
                if (!File.Exists(supervisorScript))
                {
                    return new AICodedbCommandResult(
                        4,
                        string.Empty,
                        "The Package-owned Supervisor script is missing.",
                        false);
                }

                var runtime = GetSupervisorRuntimePath(context.ProjectRoot);
                ValidateLaunchRoots(
                    context.ProjectRoot,
                    packageRoot,
                    runtime,
                    supervisorScript);
                var arguments = new[]
                {
                    supervisorScript,
                    "start",
                    "--root", context.ProjectRoot,
                    "--runtime", runtime,
                    "--package-root", packageRoot,
                    "--lifecycle-id", "unity-bridge",
                    "--supervisor-id", "unity-bridge",
                    "--startup-timeout-ms", "30000"
                };
                var provider = context.MachineProviderExecutablePath;
                if (!string.IsNullOrWhiteSpace(provider))
                    arguments = AppendArguments(arguments, "--provider", provider);
                return RunNodeStart(arguments, context.ProjectRoot, StartTimeoutMilliseconds, cancellationToken);
            }
            catch (OperationCanceledException)
            {
                throw;
            }
            catch (Exception exception)
            {
                Debug.LogWarning("CodeDB Supervisor start failed: " + exception.Message);
                return new AICodedbCommandResult(4, string.Empty, exception.Message, false);
            }
        }

        private static string[] AppendArguments(string[] arguments, params string[] additional)
        {
            var combined = new string[arguments.Length + additional.Length];
            Array.Copy(arguments, combined, arguments.Length);
            Array.Copy(additional, 0, combined, arguments.Length, additional.Length);
            return combined;
        }

        private static AICodedbCommandResult RunNodeStart(
            string[] arguments,
            string workingDirectory,
            int timeoutMilliseconds,
            CancellationToken cancellationToken)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "node",
                WorkingDirectory = workingDirectory,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            startInfo.Arguments = BuildWindowsArguments(arguments);

            using (var process = new Process { StartInfo = startInfo, EnableRaisingEvents = true })
            {
                var startedAt = DateTime.UtcNow;
                try
                {
                    if (!process.Start())
                        return new AICodedbCommandResult(4, string.Empty, "Node could not start the Supervisor.", false);
                }
                catch (Exception exception)
                {
                    return new AICodedbCommandResult(4, string.Empty, exception.Message, false);
                }

                var stdoutTask = process.StandardOutput.ReadToEndAsync();
                var stderrTask = process.StandardError.ReadToEndAsync();
                while (!process.WaitForExit(50))
                {
                    cancellationToken.ThrowIfCancellationRequested();
                    if ((DateTime.UtcNow - startedAt).TotalMilliseconds > timeoutMilliseconds)
                    {
                        try { process.Kill(); } catch { }
                        return new AICodedbCommandResult(124, stdoutTask.GetAwaiter().GetResult(), stderrTask.GetAwaiter().GetResult(), true);
                    }
                }
                process.WaitForExit();
                return new AICodedbCommandResult(
                    process.ExitCode,
                    stdoutTask.GetAwaiter().GetResult(),
                    stderrTask.GetAwaiter().GetResult(),
                    false,
                    (long)(DateTime.UtcNow - startedAt).TotalMilliseconds);
            }
        }

        private static string BuildWindowsArguments(string[] arguments)
        {
            var builder = new StringBuilder();
            foreach (var argument in arguments)
            {
                if (builder.Length > 0)
                    builder.Append(' ');
                builder.Append('"');
                foreach (var character in argument ?? string.Empty)
                {
                    if (character == '"')
                        builder.Append('\\');
                    builder.Append(character);
                }
                builder.Append('"');
            }
            return builder.ToString();
        }
    }
}
