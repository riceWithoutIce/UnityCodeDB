using System;
using System.Diagnostics;
using System.IO;
using System.Globalization;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;
using Debug = UnityEngine.Debug;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbCommandResult
    {
        internal int ExitCode { get; }
        internal string StandardOutput { get; }
        internal string StandardError { get; }
        internal bool TimedOut { get; }
        internal long ElapsedMilliseconds { get; }
        internal bool Succeeded => !TimedOut && ExitCode == 0;

        /// <summary>
        /// Creates a command result captured from a local process run.
        /// </summary>
        /// <param name="exitCode">Process exit code.</param>
        /// <param name="standardOutput">Captured stdout text.</param>
        /// <param name="standardError">Captured stderr text.</param>
        /// <param name="timedOut">Whether the process exceeded the timeout.</param>
        /// <param name="elapsedMilliseconds">Elapsed wall-clock time for the command.</param>
        internal AICodedbCommandResult(int exitCode, string standardOutput, string standardError, bool timedOut, long elapsedMilliseconds = 0)
        {
            ExitCode = exitCode;
            StandardOutput = standardOutput ?? string.Empty;
            StandardError = standardError ?? string.Empty;
            TimedOut = timedOut;
            ElapsedMilliseconds = Math.Max(0, elapsedMilliseconds);
        }

        /// <summary>
        /// Builds a compact status line suitable for Editor UI.
        /// </summary>
        internal string GetSummary()
        {
            if (TimedOut)
                return "Command timed out.";

            if (!Succeeded)
                return $"Command failed with exit code {ExitCode}.";

            if (HasLeadingFreshnessWarningMarker(StandardOutput))
                return "Command completed with warning.";

            return "Command completed successfully.";
        }

        /// <summary>
        /// Builds a readable command output block for the result window.
        /// </summary>
        internal string GetDisplayText()
        {
            var builder = new StringBuilder();
            builder.AppendLine(GetSummary());
            builder.AppendLine();
            builder.AppendLine($"Exit Code: {ExitCode}");
            if (ElapsedMilliseconds > 0)
                builder.AppendLine($"Elapsed: {GetElapsedText()}");

            if (TimedOut)
                builder.AppendLine("Timed Out: True");

            AppendSection(builder, "Output", StandardOutput);
            AppendSection(builder, "Error", StandardError);

            return builder.ToString();
        }

        /// <summary>
        /// Returns a compact elapsed-time label for Editor UI.
        /// </summary>
        internal string GetElapsedText()
        {
            if (ElapsedMilliseconds <= 0)
                return "n/a";

            if (ElapsedMilliseconds < 1000)
                return ElapsedMilliseconds.ToString(CultureInfo.InvariantCulture) + " ms";

            var seconds = ElapsedMilliseconds / 1000d;
            if (seconds < 60d)
                return seconds.ToString("0.00", CultureInfo.InvariantCulture) + " s";

            var minutes = seconds / 60d;
            return minutes.ToString("0.0", CultureInfo.InvariantCulture) + " min";
        }

        /// <summary>
        /// Appends a named output section when it has content.
        /// </summary>
        /// <param name="builder">String builder receiving the section.</param>
        /// <param name="title">Section title.</param>
        /// <param name="content">Section body.</param>
        private static void AppendSection(StringBuilder builder, string title, string content)
        {
            if (string.IsNullOrWhiteSpace(content))
                return;

            builder.AppendLine();
            builder.AppendLine(title + ":");
            builder.AppendLine(content.TrimEnd());
        }

        /// <summary>
        /// Returns whether the first structured output marker reports stale or unknown freshness.
        /// </summary>
        /// <param name="output">Captured standard output.</param>
        private static bool HasLeadingFreshnessWarningMarker(string output)
        {
            if (string.IsNullOrWhiteSpace(output))
                return false;

            var lines = output.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None);
            foreach (var line in lines)
            {
                var trimmed = line.Trim();
                if (trimmed.StartsWith("[STALE]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[UNKNOWN]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[CONFLICT]", StringComparison.OrdinalIgnoreCase))
                    return true;

                if (trimmed.StartsWith("[OK]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[NO HIT]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[SKIP]", StringComparison.OrdinalIgnoreCase)
                    || trimmed.StartsWith("[FAIL]", StringComparison.OrdinalIgnoreCase))
                    return false;
            }

            return false;
        }
    }

    internal static class AICodedbProcessRunner
    {
        private const int DefaultTimeoutMilliseconds = 120000;
        private const int OutputDrainTimeoutMilliseconds = 1000;

        private enum PowerShellScriptPathPolicy
        {
            ProjectLocal,
            ResolvedPackageMaterializer
        }

        /// <summary>
        /// Runs a project-local PowerShell script and captures its output.
        /// </summary>
        /// <param name="scriptPath">Absolute path to a script under the Unity project root.</param>
        internal static AICodedbCommandResult RunPowerShellScript(string scriptPath)
        {
            return RunPowerShellScript(scriptPath, DefaultTimeoutMilliseconds);
        }

        /// <summary>
        /// Runs a project-local PowerShell script with a timeout and captures its output.
        /// </summary>
        /// <param name="scriptPath">Absolute path to a script under the Unity project root.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the PowerShell script.</param>
        internal static AICodedbCommandResult RunPowerShellScript(string scriptPath, int timeoutMilliseconds, params string[] scriptArguments)
        {
            return RunPowerShellScript(
                AICodedbPaths.CaptureExecutionContext(),
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        internal static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        /// <summary>
        /// Runs only the materializer script owned by the CodeDB Package resolved for this assembly.
        /// </summary>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the materializer.</param>
        internal static AICodedbCommandResult RunResolvedPackageMaterializerPowerShellScript(
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                AICodedbPaths.CaptureExecutionContext(),
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        internal static AICodedbCommandResult RunResolvedPackageMaterializerPowerShellScript(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScript(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        /// <summary>
        /// Runs a project-local PowerShell script on a worker thread so Editor initialization stays responsive.
        /// </summary>
        /// <param name="scriptPath">Absolute path to a script under the Unity project root.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the PowerShell script.</param>
        internal static Task<AICodedbCommandResult> RunPowerShellScriptAsync(
            string scriptPath,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsync(
                AICodedbPaths.CaptureExecutionContext(),
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        internal static Task<AICodedbCommandResult> RunPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsync(
                context,
                scriptPath,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ProjectLocal,
                scriptArguments);
        }

        /// <summary>
        /// Runs the resolved Package-owned materializer on a worker thread.
        /// </summary>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        /// <param name="scriptArguments">Optional arguments passed to the materializer.</param>
        internal static Task<AICodedbCommandResult> RunResolvedPackageMaterializerPowerShellScriptAsync(
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsync(
                AICodedbPaths.CaptureExecutionContext(),
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        internal static Task<AICodedbCommandResult> RunResolvedPackageMaterializerPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            int timeoutMilliseconds,
            params string[] scriptArguments)
        {
            return RunPowerShellScriptAsync(
                context,
                string.Empty,
                timeoutMilliseconds,
                PowerShellScriptPathPolicy.ResolvedPackageMaterializer,
                scriptArguments);
        }

        private static AICodedbCommandResult RunPowerShellScript(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            PowerShellScriptPathPolicy pathPolicy,
            string[] scriptArguments)
        {
            if (context.Platform != RuntimePlatform.WindowsEditor)
                return UnsupportedPlatformResult();

            if (timeoutMilliseconds <= 0)
                timeoutMilliseconds = DefaultTimeoutMilliseconds;

            string normalizedScriptPath;
            string authorizationError;
            if (!TryAuthorizePowerShellScriptPath(
                    pathPolicy,
                    context,
                    scriptPath,
                    out normalizedScriptPath,
                    out authorizationError))
            {
                return new AICodedbCommandResult(-1, string.Empty, authorizationError, false);
            }

            return RunProcess(
                BuildPowerShellStartInfo(context, normalizedScriptPath, scriptArguments),
                timeoutMilliseconds);
        }

        private static Task<AICodedbCommandResult> RunPowerShellScriptAsync(
            AICodedbEditorExecutionContext context,
            string scriptPath,
            int timeoutMilliseconds,
            PowerShellScriptPathPolicy pathPolicy,
            string[] scriptArguments)
        {
            if (context.Platform != RuntimePlatform.WindowsEditor)
                return Task.FromResult(UnsupportedPlatformResult());

            if (timeoutMilliseconds <= 0)
                timeoutMilliseconds = DefaultTimeoutMilliseconds;

            var effectiveTimeout = timeoutMilliseconds;
            return Task.Run(() => RunPowerShellScript(
                context,
                scriptPath,
                effectiveTimeout,
                pathPolicy,
                scriptArguments));
        }

        private static AICodedbCommandResult UnsupportedPlatformResult()
        {
            return new AICodedbCommandResult(
                -1,
                string.Empty,
                "PowerShell codedb scripts are currently supported only in the Windows Editor.",
                false);
        }

        private static bool TryAuthorizePowerShellScriptPath(
            PowerShellScriptPathPolicy pathPolicy,
            AICodedbEditorExecutionContext context,
            string scriptPath,
            out string normalizedScriptPath,
            out string error)
        {
            normalizedScriptPath = string.Empty;
            error = string.Empty;

            try
            {
                if (pathPolicy == PowerShellScriptPathPolicy.ResolvedPackageMaterializer)
                {
                    var resolvedPackageRoot = context.PackageRoot;
                    var materializerPath = AICodedbPaths.NormalizePath(Path.Combine(
                        resolvedPackageRoot,
                        AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
                    return TryValidateResolvedPackageMaterializerScriptPath(
                        resolvedPackageRoot,
                        materializerPath,
                        out normalizedScriptPath,
                        out error);
                }

                normalizedScriptPath = AICodedbPaths.NormalizePath(scriptPath);
                if (!IsInsideRoot(context.ProjectRoot, normalizedScriptPath))
                {
                    error = $"Refusing to run a script outside the Unity project: {normalizedScriptPath}";
                    normalizedScriptPath = string.Empty;
                    return false;
                }

                if (!File.Exists(normalizedScriptPath))
                {
                    error = $"Script not found: {ToRootRelativeDisplayPath(context.ProjectRoot, normalizedScriptPath)}";
                    normalizedScriptPath = string.Empty;
                    return false;
                }

                return true;
            }
            catch (Exception exception)
            {
                normalizedScriptPath = string.Empty;
                error = "Refusing to run a PowerShell script because its path could not be validated: "
                        + exception.Message;
                return false;
            }
        }

        /// <summary>
        /// Validates the one Package-owned script that may execute outside the Unity project.
        /// </summary>
        internal static bool TryValidateResolvedPackageMaterializerScriptPath(
            string resolvedPackageRoot,
            string scriptPath,
            out string normalizedScriptPath,
            out string error)
        {
            normalizedScriptPath = string.Empty;
            error = string.Empty;

            try
            {
                if (string.IsNullOrWhiteSpace(resolvedPackageRoot)
                    || !Path.IsPathRooted(resolvedPackageRoot))
                {
                    error = "Resolved CodeDB Package root must be an absolute path.";
                    return false;
                }

                if (string.IsNullOrWhiteSpace(scriptPath) || !Path.IsPathRooted(scriptPath))
                {
                    error = "Resolved CodeDB Package materializer path must be absolute.";
                    return false;
                }

                var normalizedPackageRoot = AICodedbPaths.NormalizePath(resolvedPackageRoot).TrimEnd('/', '\\');
                var requestedScriptPath = AICodedbPaths.NormalizePath(scriptPath);
                var expectedScriptPath = AICodedbPaths.NormalizePath(Path.Combine(
                    normalizedPackageRoot,
                    AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath));
                var packagePrefix = normalizedPackageRoot + "/";

                if (!expectedScriptPath.StartsWith(packagePrefix, StringComparison.OrdinalIgnoreCase)
                    || !string.Equals(requestedScriptPath, expectedScriptPath, StringComparison.OrdinalIgnoreCase))
                {
                    error = "Refusing to run a script other than the resolved CodeDB Package materializer: "
                            + requestedScriptPath;
                    return false;
                }

                if (!Directory.Exists(normalizedPackageRoot))
                {
                    error = "Resolved CodeDB Package root was not found: " + normalizedPackageRoot;
                    return false;
                }

                if (!TryValidatePackageMaterializerPathNodes(
                        normalizedPackageRoot,
                        out error))
                    return false;

                normalizedScriptPath = expectedScriptPath;
                return true;
            }
            catch (Exception exception)
            {
                error = "Refusing to run the resolved CodeDB Package materializer because its path could not be validated: "
                        + exception.Message;
                return false;
            }
        }

        private static bool TryValidatePackageMaterializerPathNodes(
            string normalizedPackageRoot,
            out string error)
        {
            error = string.Empty;

            var current = normalizedPackageRoot;
            var relativeSegments = AICodedbProjectSettings.HostPayloadMaterializerScriptPackageRelativePath
                .Replace('\\', '/')
                .Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);

            if (!TryValidatePathNode(current, true, out error))
                return false;

            for (var index = 0; index < relativeSegments.Length; index++)
            {
                current = AICodedbPaths.NormalizePath(Path.Combine(current, relativeSegments[index]));
                var expectDirectory = index < relativeSegments.Length - 1;
                if (TryValidatePathNode(current, expectDirectory, out error))
                    continue;

                return false;
            }

            return true;
        }

        private static bool TryValidatePathNode(string path, bool expectDirectory, out string error)
        {
            error = string.Empty;
            if (expectDirectory ? !Directory.Exists(path) : !File.Exists(path))
            {
                error = expectDirectory
                    ? "Resolved CodeDB Package directory was not found: " + path
                    : "Resolved CodeDB Package materializer was not found: " + path;
                return false;
            }

            var attributes = File.GetAttributes(path);
            if ((attributes & FileAttributes.ReparsePoint) == 0)
                return true;

            error = "Refusing to run the resolved CodeDB Package materializer through a reparse point: " + path;
            return false;
        }

        private static ProcessStartInfo BuildPowerShellStartInfo(
            AICodedbEditorExecutionContext context,
            string normalizedScriptPath,
            string[] scriptArguments)
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = BuildPowerShellArguments(normalizedScriptPath, scriptArguments),
                WorkingDirectory = context.ProjectRoot,
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };
            startInfo.EnvironmentVariables["RICE_CODEDB_UNITY_ROOT"] = context.ProjectRoot;
            return startInfo;
        }

        private static bool IsInsideRoot(string root, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/', '\\');
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            return string.Equals(normalizedRoot, normalizedPath, StringComparison.OrdinalIgnoreCase)
                   || normalizedPath.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase);
        }

        private static string ToRootRelativeDisplayPath(string root, string path)
        {
            var normalizedRoot = AICodedbPaths.NormalizePath(root).TrimEnd('/', '\\');
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            var prefix = normalizedRoot + "/";
            return normalizedPath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                ? normalizedPath.Substring(prefix.Length)
                : normalizedPath;
        }

        /// <summary>
        /// Builds the PowerShell command line used to run a project script.
        /// </summary>
        /// <param name="scriptPath">Absolute script path.</param>
        /// <param name="scriptArguments">Optional script arguments.</param>
        private static string BuildPowerShellArguments(string scriptPath, string[] scriptArguments)
        {
            var builder = new StringBuilder();
            AppendArgument(builder, "-NoProfile");
            AppendArgument(builder, "-ExecutionPolicy");
            AppendArgument(builder, "Bypass");
            AppendArgument(builder, "-File");
            AppendArgument(builder, scriptPath);

            if (scriptArguments == null)
                return builder.ToString();

            foreach (var argument in scriptArguments)
                AppendArgument(builder, argument);

            return builder.ToString();
        }

        /// <summary>
        /// Appends one quoted process argument to the command-line builder.
        /// </summary>
        /// <param name="builder">Command-line builder.</param>
        /// <param name="argument">Argument to append.</param>
        private static void AppendArgument(StringBuilder builder, string argument)
        {
            if (builder.Length > 0)
                builder.Append(' ');

            builder.Append(QuoteWindowsArgument(argument));
        }

        /// <summary>
        /// Runs a process and captures stdout and stderr for the Editor result window.
        /// </summary>
        /// <param name="startInfo">Process start information.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds.</param>
        private static AICodedbCommandResult RunProcess(ProcessStartInfo startInfo, int timeoutMilliseconds)
        {
            var output = new StringBuilder();
            var error = new StringBuilder();
            var outputLock = new object();
            var errorLock = new object();
            var outputCompleted = new TaskCompletionSource<bool>();
            var errorCompleted = new TaskCompletionSource<bool>();
            var stopwatch = Stopwatch.StartNew();

            try
            {
                using (var process = new Process())
                {
                    process.StartInfo = startInfo;
                    process.OutputDataReceived += (sender, args) =>
                    {
                        if (args.Data == null)
                        {
                            outputCompleted.TrySetResult(true);
                            return;
                        }

                        lock (outputLock)
                            output.AppendLine(args.Data);
                    };
                    process.ErrorDataReceived += (sender, args) =>
                    {
                        if (args.Data == null)
                        {
                            errorCompleted.TrySetResult(true);
                            return;
                        }

                        lock (errorLock)
                            error.AppendLine(args.Data);
                    };

                    if (!process.Start())
                        return new AICodedbCommandResult(-1, string.Empty, "Failed to start process.", false, GetElapsedMilliseconds(stopwatch));

                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();

                    if (!process.WaitForExit(timeoutMilliseconds))
                    {
                        TryKillProcess(process);
                        WaitForOutputDrain(outputCompleted.Task, errorCompleted.Task);
                        return new AICodedbCommandResult(-1, GetCapturedText(output, outputLock), GetCapturedText(error, errorLock), true, GetElapsedMilliseconds(stopwatch));
                    }

                    WaitForOutputDrain(outputCompleted.Task, errorCompleted.Task);
                    return new AICodedbCommandResult(process.ExitCode, GetCapturedText(output, outputLock), GetCapturedText(error, errorLock), false, GetElapsedMilliseconds(stopwatch));
                }
            }
            catch (Exception exception)
            {
                Debug.LogException(exception);
                var errorText = GetCapturedText(error, errorLock);
                if (!string.IsNullOrWhiteSpace(errorText))
                    errorText = errorText.TrimEnd() + Environment.NewLine;

                return new AICodedbCommandResult(-1, GetCapturedText(output, outputLock), errorText + exception.Message, false, GetElapsedMilliseconds(stopwatch));
            }
        }

        /// <summary>
        /// Gives asynchronous stdout and stderr readers a bounded chance to deliver their final lines.
        /// </summary>
        private static void WaitForOutputDrain(Task outputCompleted, Task errorCompleted)
        {
            if (!Task.WaitAll(new[] { outputCompleted, errorCompleted }, OutputDrainTimeoutMilliseconds))
                Debug.LogWarning("Codedb process exited while redirected output remained open; continuing with the output captured so far.");
        }

        /// <summary>
        /// Takes a thread-safe snapshot of asynchronously captured process output.
        /// </summary>
        private static string GetCapturedText(StringBuilder builder, object syncRoot)
        {
            lock (syncRoot)
                return builder.ToString();
        }

        /// <summary>
        /// Gets elapsed milliseconds while preserving visibly non-zero fast runs.
        /// </summary>
        /// <param name="stopwatch">Running stopwatch.</param>
        private static long GetElapsedMilliseconds(Stopwatch stopwatch)
        {
            if (stopwatch == null)
                return 0;

            if (stopwatch.ElapsedMilliseconds > 0)
                return stopwatch.ElapsedMilliseconds;

            return stopwatch.ElapsedTicks > 0 ? 1 : 0;
        }

        /// <summary>
        /// Terminates a process after a timeout without surfacing cleanup failures.
        /// </summary>
        /// <param name="process">Process to terminate.</param>
        private static void TryKillProcess(Process process)
        {
            try
            {
                if (!process.HasExited)
                    process.Kill();
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Failed to kill timed-out codedb process: {exception.Message}");
            }
        }

        /// <summary>
        /// Quotes a Windows command-line argument for ProcessStartInfo.Arguments.
        /// </summary>
        /// <param name="argument">Argument to quote.</param>
        private static string QuoteWindowsArgument(string argument)
        {
            if (string.IsNullOrEmpty(argument))
                return "\"\"";

            var builder = new StringBuilder();
            builder.Append('"');

            var backslashes = 0;
            foreach (var character in argument)
            {
                if (character == '\\')
                {
                    backslashes++;
                    continue;
                }

                if (character == '"')
                {
                    builder.Append('\\', backslashes * 2 + 1);
                    builder.Append('"');
                    backslashes = 0;
                    continue;
                }

                if (backslashes > 0)
                {
                    builder.Append('\\', backslashes);
                    backslashes = 0;
                }

                builder.Append(character);
            }

            if (backslashes > 0)
                builder.Append('\\', backslashes * 2);

            builder.Append('"');
            return builder.ToString();
        }
    }
}
