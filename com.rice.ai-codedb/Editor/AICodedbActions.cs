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

        /// <summary>
        /// Opens the ignored project-local codedb runtime folder.
        /// </summary>
        internal static void OpenRuntimeFolder()
        {
            Directory.CreateDirectory(AICodedbPaths.RuntimePath);
            EditorUtility.RevealInFinder(AICodedbPaths.RuntimePath);
        }

        /// <summary>
        /// Opens the ignored provider binary folder.
        /// </summary>
        internal static void OpenProviderFolder()
        {
            var providerFolder = Path.GetDirectoryName(AICodedbPaths.ProviderExecutablePath);
            if (string.IsNullOrWhiteSpace(providerFolder))
                providerFolder = AICodedbPaths.RuntimePath;

            Directory.CreateDirectory(providerFolder);
            EditorUtility.RevealInFinder(providerFolder);
        }

        /// <summary>
        /// Opens the ignored provider config folder.
        /// </summary>
        internal static void OpenConfigFolder()
        {
            var configFolder = Path.GetDirectoryName(AICodedbPaths.ProviderConfigPath);
            if (string.IsNullOrWhiteSpace(configFolder))
                configFolder = AICodedbPaths.RuntimePath;

            Directory.CreateDirectory(configFolder);
            EditorUtility.RevealInFinder(configFolder);
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
            return RunScript("Codedb Enable Watcher", AICodedbPaths.WatchManageScriptPath, RefreshIndexTimeoutMilliseconds, BuildWatcherScriptArguments("Enable"));
        }

        /// <summary>
        /// Disables the persistent Start with Unity Editor policy and stops the coordinator.
        /// </summary>
        internal static AICodedbCommandResult RunDisableWatcher()
        {
            return RunScript("Codedb Disable Watcher", AICodedbPaths.WatchManageScriptPath, 0, BuildWatcherScriptArguments("Disable"));
        }

        /// <summary>
        /// Starts CodeDB for the current Editor session without changing persistent policy.
        /// </summary>
        internal static AICodedbCommandResult RunStartWatcher()
        {
            return RunScript("Codedb Start Now", AICodedbPaths.WatchManageScriptPath, RefreshIndexTimeoutMilliseconds, BuildWatcherScriptArguments("Start"));
        }

        /// <summary>
        /// Reconciles the Editor-owned watcher lifecycle without blocking the Unity main thread.
        /// </summary>
        internal static Task<AICodedbCommandResult> RunEnsureWatcherAsync()
        {
            var scriptPath = AICodedbPaths.WatchManageScriptPath;
            var readinessFailure = GetHostCommandReadinessFailure(
                AICodedbPaths.HostGeneration,
                scriptPath);
            if (readinessFailure != null)
                return Task.FromResult(readinessFailure);
            return AICodedbProcessRunner.RunPowerShellScriptAsync(
                scriptPath,
                RefreshIndexTimeoutMilliseconds,
                BuildWatcherScriptArguments("Ensure"));
        }

        /// <summary>
        /// Reads the project-local watch opt-in and coordinator status.
        /// </summary>
        internal static AICodedbCommandResult RunWatcherStatus()
        {
            return RunScript("Codedb Watcher Status", AICodedbPaths.WatchManageScriptPath, 0, BuildWatcherScriptArguments("Status"));
        }

        /// <summary>
        /// Stops CodeDB for the current Editor session without changing persistent policy.
        /// </summary>
        internal static AICodedbCommandResult RunStopWatcher()
        {
            return RunScript("Codedb Stop Now", AICodedbPaths.WatchManageScriptPath, 0, BuildWatcherScriptArguments("Stop"));
        }

        /// <summary>
        /// Gracefully restarts CodeDB for the current Editor session.
        /// </summary>
        internal static AICodedbCommandResult RunRestartWatcher()
        {
            return RunScript("Codedb Restart", AICodedbPaths.WatchManageScriptPath, RefreshIndexTimeoutMilliseconds, BuildWatcherScriptArguments("Restart"));
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
            var readinessFailure = GetHostCommandReadinessFailure(
                AICodedbPaths.HostGeneration,
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
