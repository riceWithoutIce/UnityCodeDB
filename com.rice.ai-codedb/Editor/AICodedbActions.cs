using System.IO;
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

        /// <summary>
        /// Synchronizes the audited host payload under explicit tracked-host authorization.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadSync(string authorizationPath, bool confirmLegacyMcpStopped)
        {
            return AICodedbHostPayloadMaterializer.RunSync(authorizationPath, confirmLegacyMcpStopped);
        }

        /// <summary>
        /// Removes only package-owned host payload paths under explicit tracked-host authorization.
        /// </summary>
        internal static AICodedbCommandResult RunHostPayloadRemove(string authorizationPath, bool confirmLegacyMcpStopped)
        {
            return AICodedbHostPayloadMaterializer.RunRemove(authorizationPath, confirmLegacyMcpStopped);
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
        /// Explicitly enables the project-local watch opt-in and starts or attaches to its coordinator.
        /// </summary>
        internal static AICodedbCommandResult RunStartWatcher()
        {
            return RunScript("Codedb Start Watcher", AICodedbPaths.WatchManageScriptPath, RefreshIndexTimeoutMilliseconds, "-Action", "Start");
        }

        /// <summary>
        /// Ensures the default project-local automatic refresh lifecycle is ready when Setup is complete.
        /// </summary>
        internal static AICodedbCommandResult RunEnsureWatcher()
        {
            return RunScript("Codedb Ensure Watcher", AICodedbPaths.WatchManageScriptPath, RefreshIndexTimeoutMilliseconds, "-Action", "Ensure");
        }

        /// <summary>
        /// Reads the project-local watch opt-in and coordinator status.
        /// </summary>
        internal static AICodedbCommandResult RunWatcherStatus()
        {
            return RunScript("Codedb Watcher Status", AICodedbPaths.WatchManageScriptPath, 0, "-Action", "Status");
        }

        /// <summary>
        /// Disables wrapper auto-attach and gracefully stops the project-local coordinator.
        /// </summary>
        internal static AICodedbCommandResult RunStopWatcher()
        {
            return RunScript("Codedb Stop Watcher", AICodedbPaths.WatchManageScriptPath, 0, "-Action", "Stop");
        }

        /// <summary>
        /// Persists an explicit automatic-refresh pause and stops the project-local coordinator.
        /// </summary>
        internal static AICodedbCommandResult RunPauseWatcher()
        {
            return RunScript("Codedb Pause Watcher", AICodedbPaths.WatchManageScriptPath, 0, "-Action", "Pause");
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
    }
}
