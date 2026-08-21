using System;
using System.IO;
using System.Threading.Tasks;
using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbActions
    {
        private const int RefreshIndexTimeoutMilliseconds = 600000;
        private const int BuildTextAdapterTimeoutMilliseconds = 300000;
        private const int ProviderInstallTimeoutMilliseconds = 180000;

        /// <summary>
        /// Opens the ignored project-local codedb runtime folder.
        /// </summary>
        internal static void OpenRuntimeFolder()
        {
            var runtimePath = ResolveRuntimeFolderPath(AICodedbPaths.ProjectRoot);
            Directory.CreateDirectory(runtimePath);
            EditorUtility.RevealInFinder(runtimePath);
        }

        /// <summary>
        /// Opens the ignored provider binary folder.
        /// </summary>
        internal static void OpenProviderFolder()
        {
            var providerFolder = Path.GetDirectoryName(AICodedbPaths.ProviderExecutablePath);
            if (string.IsNullOrWhiteSpace(providerFolder) || !Directory.Exists(providerFolder))
            {
                EditorUtility.DisplayDialog(
                    "CodeDB Provider",
                    "The machine Provider is not present. Use Configure Dependencies to install the fixed 0.5.0-28e3912 Provider, then let Unity recheck automatically.",
                    "OK");
                return;
            }
            EditorUtility.RevealInFinder(providerFolder);
        }

        /// <summary>
        /// Opens the ignored provider config folder.
        /// </summary>
        internal static void OpenConfigFolder()
        {
            var configFolder = Path.Combine(
                ResolveRuntimeFolderPath(AICodedbPaths.ProjectRoot),
                "config");
            if (string.IsNullOrWhiteSpace(configFolder))
                configFolder = AICodedbPaths.RuntimePath;

            Directory.CreateDirectory(configFolder);
            EditorUtility.RevealInFinder(configFolder);
        }

        internal static string ResolveRuntimeFolderPath(string projectRoot)
        {
            var currentInstance = AICodedbCurrentInstanceStore.Read(projectRoot);
            return currentInstance.IsCurrent
                ? currentInstance.InstanceRoot
                : AICodedbPaths.NormalizePath(Path.Combine(
                    projectRoot,
                    AICodedbProjectSettings.RuntimeRelativePath));
        }

        /// <summary>
        /// Inspects package-managed host files without writing project content.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadDryRun()
        {
            return AICodedbHostPayloadMaterializer.RunDryRun();
        }

        /// <summary>
        /// Verifies that the ownership marker and all managed host files are current.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadVerify()
        {
            return AICodedbHostPayloadMaterializer.RunVerify();
        }

        internal static AICodedbCommandResult RunHostPayloadUpgrade()
        {
            return AICodedbHostPayloadMaterializer.RunUpgrade();
        }

        /// <summary>
        /// Runs the Package-owned one-click Host and project MCP recovery workflow.
        /// </summary>
        internal static AICodedbCommandResult RunRepairCodeDB()
        {
            return AICodedbHostPayloadMaterializer.RunRepair();
        }

        internal static async Task<AICodedbCommandResult> RunRepairCodeDBAsync()
        {
            var result = await AICodedbHostPayloadMaterializer.RunRepairAsync();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        /// <summary>
        /// Replaces a recognized byte-exact legacy host payload and regenerates its ignored runtime config.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadRedeploy(bool confirmedProjectMutation)
        {
            if (!confirmedProjectMutation)
                return AICodedbHostPayloadMaterializer.RunRedeploy(false);

            var preflightResult = AICodedbHostPayloadMaterializer.RunDryRun();
            if (!preflightResult.Succeeded)
                return preflightResult;

            var preflight = AICodedbHostPayloadStatusBuilder.Build(
                File.Exists(AICodedbPaths.HostPayloadMarkerPath),
                preflightResult,
                AICodedbProjectSettings.CurrentGenerationId);
            if (!preflight.CanRedeploy)
            {
                return new AICodedbCommandResult(
                    4,
                    preflightResult.StandardOutput,
                    "Redeploy preflight changed. Refresh the Manager and try again.",
                    false,
                    preflightResult.ElapsedMilliseconds);
            }

            if (preflight.ActiveOwners.Length > 0 && !preflight.HasOnlyLegacyWatcherOwners)
            {
                var ownerDescription = preflight.ActiveMcpSessionCount > 0
                    ? "Disconnect this project from its MCP clients, then try Redeploy host again."
                    : "Close the connected CodeDB client, then try Redeploy host again.";
                return new AICodedbCommandResult(
                    4,
                    preflightResult.StandardOutput,
                    ownerDescription + " External client processes are never terminated by the Manager.",
                    false,
                    preflightResult.ElapsedMilliseconds);
            }

            var redeployResult = AICodedbHostPayloadMaterializer.RunRedeploy(true);
            if (!redeployResult.Succeeded)
                return redeployResult;

            var configResult = RunRegenerateRuntimeConfig();
            return CombineResults(redeployResult, configResult);
        }

        /// <summary>
        /// Synchronizes the audited host payload after the Manager's project-scoped confirmation.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadSync()
        {
            return AICodedbHostPayloadMaterializer.RunSync();
        }

        /// <summary>
        /// Removes only package-owned host payload paths after project-scoped confirmation.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadRemove()
        {
            return AICodedbHostPayloadMaterializer.RunRemove();
        }

        internal static AICodedbCommandResult RunUninstallCodeDB()
        {
            var result = AICodedbHostPayloadMaterializer.RunUninstall();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        internal static async Task<AICodedbCommandResult> RunUninstallCodeDBAsync()
        {
            var result = await AICodedbHostPayloadMaterializer.RunUninstallAsync();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        internal static AICodedbCommandResult RunInstallCodeDB()
        {
            var result = AICodedbHostPayloadMaterializer.RunInstall();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        internal static async Task<AICodedbCommandResult> RunInstallCodeDBAsync()
        {
            var result = await AICodedbHostPayloadMaterializer.RunInstallAsync();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        internal static AICodedbCommandResult RunReinstallCodeDB()
        {
            var result = AICodedbHostPayloadMaterializer.RunReinstall();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        internal static async Task<AICodedbCommandResult> RunReinstallCodeDBAsync()
        {
            var result = await AICodedbHostPayloadMaterializer.RunReinstallAsync();
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        /// <summary>
        /// Prepares runtime folders and creates the runtime config if it is missing.
        /// </summary>
        internal static AICodedbCommandResult RunPrepareRuntime()
        {
            return RunScript("Codedb Prepare Runtime", AICodedbPaths.PrepareRuntimeScriptPath);
        }

        /// <summary>
        /// Regenerates the ignored runtime config from the tracked runtime template.
        /// </summary>
        internal static AICodedbCommandResult RunRegenerateRuntimeConfig()
        {
            return RunScript("Codedb Regenerate Runtime Config", AICodedbPaths.PrepareRuntimeScriptPath, 0, "-Force");
        }

        /// <summary>
        /// Shows provider binary preparation guidance without downloading or writing global config.
        /// </summary>
        internal static AICodedbCommandResult RunProviderGuidance()
        {
            return RunScript("Codedb Provider Guidance", AICodedbPaths.ProviderGuidanceScriptPath);
        }

        /// <summary>
        /// Configures the fixed machine Provider without touching the Unity project.
        /// </summary>
        internal static AICodedbCommandResult RunInstallProvider()
        {
            var result = RunProviderInstaller(AICodedbPaths.CaptureExecutionContext(), true);
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        internal static async Task<AICodedbCommandResult> RunInstallProviderAsync()
        {
            return await RunInstallProviderAsync(null);
        }

        internal static async Task<AICodedbCommandResult> RunInstallProviderAsync(Action<string> outputLine)
        {
            var context = AICodedbPaths.CaptureExecutionContext();
            var result = await RunProviderInstallerAsync(context, outputLine);
            AICodedbEditorLifecycle.RequestReconcile();
            return result;
        }

        private static AICodedbCommandResult RunProviderInstaller(
            AICodedbEditorExecutionContext context,
            bool showProgress)
        {
            if (context.Platform != RuntimePlatform.WindowsEditor)
            {
                return new AICodedbCommandResult(
                    4,
                    string.Empty,
                    "The fixed machine Provider installer is supported only in the Windows Editor.",
                    false);
            }

            if (showProgress)
                EditorUtility.DisplayProgressBar(AICodedbProjectSettings.DisplayName, "Configuring CodeDB dependencies", 0.5f);
            try
            {
                return AICodedbProcessRunner.RunResolvedPackageProviderInstallerPowerShellScript(
                    context,
                    ProviderInstallTimeoutMilliseconds,
                    "-PackageVersion",
                    AICodedbProjectSettings.CurrentPackageVersion);
            }
            finally
            {
                if (showProgress)
                    EditorUtility.ClearProgressBar();
            }
        }

        private static Task<AICodedbCommandResult> RunProviderInstallerAsync(
            AICodedbEditorExecutionContext context)
        {
            return RunProviderInstallerAsync(context, null);
        }

        private static Task<AICodedbCommandResult> RunProviderInstallerAsync(
            AICodedbEditorExecutionContext context,
            Action<string> outputLine)
        {
            if (context.Platform != RuntimePlatform.WindowsEditor)
            {
                return Task.FromResult(new AICodedbCommandResult(
                    4,
                    string.Empty,
                    "The fixed machine Provider installer is supported only in the Windows Editor.",
                    false));
            }

            return AICodedbProcessRunner.RunResolvedPackageProviderInstallerPowerShellScriptAsync(
                context,
                ProviderInstallTimeoutMilliseconds,
                outputLine,
                "-PackageVersion",
                AICodedbProjectSettings.CurrentPackageVersion);
        }

        /// <summary>
        /// Runs the project-local codedb index refresh script and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunRefreshIndex()
        {
            return RunScript("Codedb Refresh Index", AICodedbPaths.RefreshScriptPath, RefreshIndexTimeoutMilliseconds);
        }

        /// <summary>
        /// Removes only generated index data while preserving provider binary and runtime config.
        /// </summary>
        internal static AICodedbCommandResult RunCleanIndex()
        {
            return RunScript("Codedb Clean Index", AICodedbPaths.CleanIndexScriptPath);
        }

        /// <summary>
        /// Removes generated index data and immediately refreshes the project-local index.
        /// </summary>
        internal static AICodedbCommandResult RunRebuildIndex()
        {
            return RunScript("Codedb Rebuild Index", AICodedbPaths.RefreshScriptPath, RefreshIndexTimeoutMilliseconds, "-CleanFirst");
        }

        /// <summary>
        /// Runs the codedb runtime health smoke test and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunRuntimeHealth()
        {
            return RunScript("Codedb Runtime Health", AICodedbPaths.IndexProbeScriptPath, 0, "-Check", "RuntimeHealth");
        }

        /// <summary>
        /// Runs the generic Unity project smoke test and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunUnityProjectSmoke()
        {
            return RunScript("Codedb Unity Project Smoke", AICodedbPaths.IndexProbeScriptPath, 0, "-Check", "UnityProject");
        }

        /// <summary>
        /// Runs the auto-discovered C# language probe and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunCSharpProbe()
        {
            return RunScript("Codedb C# Probe", AICodedbPaths.IndexProbeScriptPath, 0, "-Check", "CSharpProbe");
        }

        /// <summary>
        /// Runs auto-discovered language probes and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunLanguageProbe()
        {
            return RunScript("Codedb Language Probe", AICodedbPaths.IndexProbeScriptPath, 0, "-Check", "LanguageProbe");
        }

        /// <summary>
        /// Checks whether generated project-local indexes are stale without refreshing them.
        /// </summary>
        internal static AICodedbCommandResult RunFreshnessCheck()
        {
            return RunScript("Codedb Freshness Check", AICodedbPaths.FreshnessScriptPath);
        }

        /// <summary>
        /// Refreshes generated indexes only when the freshness check reports stale or unknown state.
        /// </summary>
        internal static AICodedbCommandResult RunRefreshIfStale()
        {
            return RunScript("Codedb Refresh If Stale", AICodedbPaths.RefreshIfStaleScriptPath, RefreshIndexTimeoutMilliseconds);
        }

        /// <summary>
        /// Enables the persistent Start with Unity Editor policy.
        /// </summary>
        internal static AICodedbCommandResult RunEnableWatcher()
        {
            return RunWatcherAction("Codedb Enable Watcher", "Enable", RefreshIndexTimeoutMilliseconds);
        }

        /// <summary>
        /// Disables the persistent Start with Unity Editor policy and stops the coordinator.
        /// </summary>
        internal static AICodedbCommandResult RunDisableWatcher()
        {
            return RunWatcherAction("Codedb Disable Watcher", "Disable", 0);
        }

        /// <summary>
        /// Starts CodeDB for the current Editor session without changing persistent policy.
        /// </summary>
        internal static AICodedbCommandResult RunStartWatcher()
        {
            return RunWatcherAction("Codedb Start Now", "Start", RefreshIndexTimeoutMilliseconds);
        }

        /// <summary>
        /// Reconciles the Editor-owned watcher lifecycle without blocking the Unity main thread.
        /// </summary>
        internal static Task<AICodedbCommandResult> RunEnsureWatcherAsync()
        {
            var context = AICodedbPaths.CaptureExecutionContext();
            return Task.Run(() => RunWatcherScript(
                context,
                "Ensure",
                RefreshIndexTimeoutMilliseconds));
        }

        internal static AICodedbCommandResult RunEnsureWatcher(AICodedbEditorExecutionContext context)
        {
            return RunWatcherScript(context, "Ensure", RefreshIndexTimeoutMilliseconds);
        }

        /// <summary>
        /// Reads the project-local watch opt-in and coordinator status.
        /// </summary>
        internal static AICodedbCommandResult RunWatcherStatus()
        {
            return RunWatcherAction("Codedb Watcher Status", "Status", 0);
        }

        internal static Task<AICodedbCommandResult> RunWatcherStatusAsync()
        {
            var context = AICodedbPaths.CaptureExecutionContext();
            return Task.Run(() => RunWatcherScript(context, "Status", 0));
        }

        /// <summary>
        /// Stops CodeDB for the current Editor session without changing persistent policy.
        /// </summary>
        internal static AICodedbCommandResult RunStopWatcher()
        {
            return RunWatcherAction("Codedb Stop Now", "Stop", 0);
        }

        /// <summary>
        /// Gracefully restarts CodeDB for the current Editor session.
        /// </summary>
        internal static AICodedbCommandResult RunRestartWatcher()
        {
            return RunWatcherAction("Codedb Restart", "Restart", RefreshIndexTimeoutMilliseconds);
        }

        internal static string[] BuildWatcherScriptArguments(string action)
        {
            switch (action)
            {
                case "Enable":
                case "Disable":
                case "Start":
                case "Ensure":
                case "Status":
                case "Stop":
                case "Restart":
                    return new[] { "-Action", action };
                default:
                    throw new ArgumentException("Unsupported CodeDB watcher action.", nameof(action));
            }
        }

        private static AICodedbCommandResult RunWatcherScript(
            AICodedbEditorExecutionContext context,
            string action,
            int timeoutMilliseconds)
        {
            var selection = AICodedbHostGenerationStore.Resolve(context.ProjectRoot, context.PackageRoot);
            var scriptPath = selection.IsUsable
                ? AICodedbPaths.NormalizePath(Path.Combine(
                    selection.RootPath,
                    "scripts/manage-codedb-project-watch.ps1"))
                : string.Empty;
            var readinessFailure = GetHostCommandReadinessFailure(selection, scriptPath);
            if (readinessFailure != null)
                return readinessFailure;

            // Generation scripts resolve their provider/watch state from the
            // selected immutable instance. Without this environment binding
            // an Editor restart silently falls back to the retired flat path.
            var instanceRoot = string.Empty;
            if (selection.State == AICodedbHostGenerationState.Current)
            {
                var currentInstance = AICodedbCurrentInstanceStore.Read(context.ProjectRoot);
                if (!currentInstance.IsCurrent)
                {
                    return new AICodedbCommandResult(
                        4,
                        string.Empty,
                        "The selected CodeDB instance is not ready for watcher operations: "
                        + currentInstance.Detail,
                        false);
                }
                instanceRoot = currentInstance.InstanceRoot;
            }

            return AICodedbProcessRunner.RunPowerShellScript(
                context,
                scriptPath,
                timeoutMilliseconds,
                instanceRoot,
                BuildWatcherScriptArguments(action));
        }

        private static AICodedbCommandResult RunWatcherAction(
            string title,
            string action,
            int timeoutMilliseconds)
        {
            var context = AICodedbPaths.CaptureExecutionContext();
            if (WatcherActionRequiresEditorLease(action))
            {
                string leaseDetail;
                if (!AICodedbEditorLifecycle.TryPrepareCurrentEditorLease(context, out leaseDetail))
                {
                    return new AICodedbCommandResult(
                        4,
                        string.Empty,
                        leaseDetail,
                        false);
                }
            }

            EditorUtility.DisplayProgressBar(
                AICodedbProjectSettings.DisplayName,
                $"Running {title}",
                0.5f);
            try
            {
                return RunWatcherScript(context, action, timeoutMilliseconds);
            }
            finally
            {
                EditorUtility.ClearProgressBar();
            }
        }

        internal static bool WatcherActionRequiresEditorLease(string action)
        {
            return string.Equals(action, "Enable", StringComparison.Ordinal)
                   || string.Equals(action, "Start", StringComparison.Ordinal)
                   || string.Equals(action, "Stop", StringComparison.Ordinal)
                   || string.Equals(action, "Restart", StringComparison.Ordinal);
        }

        /// <summary>
        /// Persists an explicit automatic-refresh pause and stops the project-local coordinator.
        /// </summary>
        internal static AICodedbCommandResult RunPauseWatcher()
        {
            return RunDisableWatcher();
        }

        internal static AICodedbCommandResult SetAutomaticHostUpdates(bool enabled)
        {
            try
            {
                AICodedbHostUpdatePolicyStore.SetEnabled(AICodedbPaths.ProjectRoot, enabled);
                return new AICodedbCommandResult(
                    0,
                    "[OK] Automatic host updates: " + (enabled ? "ENABLED" : "DISABLED"),
                    string.Empty,
                    false);
            }
            catch (System.Exception exception)
            {
                return new AICodedbCommandResult(-1, string.Empty, exception.Message, false);
            }
        }

        /// <summary>
        /// Builds the project-local Shader/HLSL text adapter index.
        /// </summary>
        internal static AICodedbCommandResult RunBuildShaderAdapter()
        {
            return RunScript("Codedb Build Shader Adapter", AICodedbPaths.TextAdapterBuildScriptPath, BuildTextAdapterTimeoutMilliseconds);
        }

        /// <summary>
        /// Runs the Shader/HLSL text adapter smoke test.
        /// </summary>
        internal static AICodedbCommandResult RunShaderAdapterProbe()
        {
            return RunScript("Codedb Shader Adapter Probe", AICodedbPaths.TextAdapterProbeScriptPath);
        }

        /// <summary>
        /// Searches the Shader/HLSL text adapter with user-provided text.
        /// </summary>
        /// <param name="query">User-provided text to search for.</param>
        internal static AICodedbCommandResult RunShaderAdapterSearch(string query)
        {
            return RunScript("Codedb Shader Adapter Search", AICodedbPaths.TextAdapterProbeScriptPath, 0, "-Check", "Search", "-Query", query);
        }

        /// <summary>
        /// Reads Shader/HLSL text adapter source context around a user-provided query.
        /// </summary>
        /// <param name="query">User-provided text to read around.</param>
        internal static AICodedbCommandResult RunShaderAdapterRead(string query)
        {
            return RunScript("Codedb Shader Adapter Read", AICodedbPaths.TextAdapterProbeScriptPath, 0, "-Check", "Read", "-Query", query);
        }

        /// <summary>
        /// Runs a provider-backed custom language probe and returns the captured result.
        /// </summary>
        /// <param name="language">Language scope used by the smoke script.</param>
        /// <param name="query">User-provided text to search for.</param>
        internal static AICodedbCommandResult RunProviderCustomProbe(string language, string query)
        {
            return RunScript("Codedb Provider Custom Probe", AICodedbPaths.IndexProbeScriptPath, 0, "-Check", "CustomProbe", "-Language", language, "-Query", query);
        }

        /// <summary>
        /// Runs the project-local codedb runtime verification script and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunVerifyRuntime()
        {
            return RunScript("Codedb Verify Runtime", AICodedbPaths.VerifyScriptPath);
        }

        /// <summary>
        /// Generates the project-level MCP registration draft and returns the captured result.
        /// </summary>
        internal static AICodedbCommandResult RunRegistrationDraft()
        {
            return RunScript("Codedb Registration Draft", AICodedbPaths.RegistrationDraftScriptPath);
        }

        /// <summary>
        /// Validates the project-level MCP registration config without writing client settings.
        /// </summary>
        internal static AICodedbCommandResult RunRegistrationValidation()
        {
            return RunScript("Codedb Registration Validation", AICodedbPaths.RegistrationValidateScriptPath);
        }

        private static AICodedbCommandResult CombineResults(
            AICodedbCommandResult first,
            AICodedbCommandResult second)
        {
            return new AICodedbCommandResult(
                second.ExitCode,
                JoinOutput(first.StandardOutput, second.StandardOutput),
                JoinOutput(first.StandardError, second.StandardError),
                first.TimedOut || second.TimedOut,
                first.ElapsedMilliseconds + second.ElapsedMilliseconds);
        }

        private static string JoinOutput(string first, string second)
        {
            if (string.IsNullOrWhiteSpace(first))
                return second ?? string.Empty;
            if (string.IsNullOrWhiteSpace(second))
                return first ?? string.Empty;
            return first.TrimEnd() + Environment.NewLine + second.TrimStart();
        }

        /// <summary>
        /// Runs a codedb script with a progress bar and returns the captured output.
        /// </summary>
        /// <param name="title">Progress title.</param>
        /// <param name="scriptPath">Absolute path to the script.</param>
        private static AICodedbCommandResult RunScript(string title, string scriptPath)
        {
            return RunScript(title, scriptPath, 0);
        }

        /// <summary>
        /// Runs a codedb script with a timeout and returns the captured output.
        /// </summary>
        /// <param name="title">Progress title.</param>
        /// <param name="scriptPath">Absolute path to the script.</param>
        /// <param name="timeoutMilliseconds">Maximum runtime in milliseconds, or zero for the default timeout.</param>
        /// <param name="scriptArguments">Optional arguments passed to the script.</param>
        private static AICodedbCommandResult RunScript(string title, string scriptPath, int timeoutMilliseconds, params string[] scriptArguments)
        {
            var context = AICodedbPaths.CaptureExecutionContext();
            var readinessFailure = GetHostCommandReadinessFailure(
                AICodedbHostGenerationStore.Resolve(context.ProjectRoot, context.PackageRoot),
                scriptPath);
            if (readinessFailure != null)
                return readinessFailure;

            EditorUtility.DisplayProgressBar(AICodedbProjectSettings.DisplayName, $"Running {Path.GetFileName(scriptPath)}", 0.5f);

            try
            {
                return AICodedbProcessRunner.RunPowerShellScript(scriptPath, timeoutMilliseconds, scriptArguments);
            }
            finally
            {
                EditorUtility.ClearProgressBar();
            }
        }

        internal static AICodedbCommandResult GetHostCommandReadinessFailure(
            AICodedbHostGenerationSelection selection,
            string scriptPath)
        {
            if (!selection.IsUsable)
            {
                return new AICodedbCommandResult(
                    4,
                    string.Empty,
                    "Host command is unavailable while generation state is " + selection.State + ". " + selection.Detail,
                    false);
            }

            try
            {
                var normalizedRoot = AICodedbPaths.NormalizePath(selection.RootPath).TrimEnd('/');
                var normalizedScript = AICodedbPaths.NormalizePath(scriptPath);
                if (string.IsNullOrWhiteSpace(normalizedRoot)
                    || !normalizedScript.StartsWith(normalizedRoot + "/", StringComparison.OrdinalIgnoreCase)
                    || !File.Exists(normalizedScript))
                {
                    return new AICodedbCommandResult(
                        4,
                        string.Empty,
                        "Host command path is unavailable for the validated generation: " + normalizedScript,
                        false);
                }
            }
            catch (Exception exception)
            {
                return new AICodedbCommandResult(
                    4,
                    string.Empty,
                    "Host command path validation failed: " + exception.Message,
                    false);
            }
            return null;
        }
    }
}
