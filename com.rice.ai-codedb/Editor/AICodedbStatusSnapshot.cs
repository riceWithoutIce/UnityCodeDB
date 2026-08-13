using System;
using System.IO;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbStatusSnapshot
    {
        internal AICodedbStatusState OverallState { get; }
        internal string OverallTitle { get; }
        internal string OverallDescription { get; }
        internal AICodedbHostPayloadStatus HostPayloadStatus { get; }
        internal AICodedbStatusItem HostPayload { get; }
        internal AICodedbStatusItem HostGeneration { get; }
        internal AICodedbStatusItem HostLastKnownGood { get; }
        internal AICodedbStatusItem HostUpgrade { get; }
        internal AICodedbStatusItem HostUpdatePolicy { get; }
        internal AICodedbHostGenerationSelection HostGenerationSelection { get; }
        internal AICodedbHostUpgradeStatus HostUpgradeStatus { get; }
        internal AICodedbHostUpdatePolicy HostUpdatePolicyValue { get; }
        internal AICodedbStatusItem ProviderExecutable { get; }
        internal AICodedbStatusItem ProviderConfig { get; }
        internal AICodedbStatusItem RuntimeConfigTemplate { get; }
        internal AICodedbStatusItem RuntimeDirectory { get; }
        internal AICodedbStatusItem IndexDirectory { get; }
        internal AICodedbStatusItem IndexManifest { get; }
        internal AICodedbStatusItem TextAdapterDirectory { get; }
        internal AICodedbStatusItem TextAdapterManifest { get; }
        internal AICodedbStatusItem ProjectMcpConfig { get; }
        internal AICodedbStatusItem RuntimeBoundary { get; }
        internal AICodedbStatusItem ToolProfile { get; }

        /// <summary>
        /// Captures the current read-only codedb setup status.
        /// </summary>
        private AICodedbStatusSnapshot(AICodedbCommandResult hostPayloadResult)
        {
            var hostPayloadMarkerExists = File.Exists(AICodedbPaths.HostPayloadMarkerPath);
            HostGenerationSelection = AICodedbPaths.HostGeneration;
            HostPayloadStatus = AICodedbHostPayloadStatusBuilder.Build(
                hostPayloadMarkerExists,
                hostPayloadResult ?? AICodedbHostPayloadMaterializer.ReadStatus(),
                HostGenerationSelection.State == AICodedbHostGenerationState.Current
                    ? HostGenerationSelection.GenerationId
                    : string.Empty);
            HostPayload = HostPayloadStatus.ToStatusItem();
            HostUpdatePolicyValue = AICodedbHostUpdatePolicyStore.Read(AICodedbPaths.ProjectRoot);
            HostGeneration = CreateHostGenerationStatus(HostGenerationSelection);
            HostLastKnownGood = CreateLastKnownGoodStatus(hostPayloadMarkerExists);
            HostUpgradeStatus = AICodedbHostUpgradeStatusStore.Read(
                AICodedbPaths.ProjectRoot,
                AICodedbProjectSettings.CurrentGenerationId);
            HostUpgrade = HostUpgradeStatus.ToStatusItem(hostPayloadMarkerExists);
            HostUpdatePolicy = CreateHostUpdatePolicyStatus(HostUpdatePolicyValue);
            ProviderExecutable = CreateFileStatus("Provider executable", AICodedbProjectSettings.ProviderExecutableRelativePath);
            ProviderConfig = CreateProviderConfigStatus();
            RuntimeConfigTemplate = CreateAbsoluteFileStatus("Runtime config template", AICodedbPaths.RuntimeConfigTemplatePath);
            RuntimeDirectory = CreateDirectoryStatus("Runtime directory", AICodedbProjectSettings.RuntimeRelativePath);
            IndexDirectory = CreateDirectoryStatus("Index directory", AICodedbProjectSettings.IndexRelativePath);
            IndexManifest = CreateFileStatus("Index manifest", AICodedbProjectSettings.IndexManifestRelativePath);
            TextAdapterDirectory = CreateDirectoryStatus("Shader adapter directory", AICodedbProjectSettings.TextAdapterRelativePath);
            TextAdapterManifest = CreateFileStatus("Shader adapter manifest", AICodedbProjectSettings.TextAdapterManifestRelativePath);
            ProjectMcpConfig = CreateFileStatus("Project MCP config", AICodedbProjectSettings.ProjectMcpConfigRelativePath);
            RuntimeBoundary = CreateRuntimeBoundaryStatus(AICodedbProjectSettings.RuntimeRelativePath);
            ToolProfile = CreateToolProfileStatus();
            OverallState = ResolveOverallState();
            OverallTitle = CreateOverallTitle(OverallState);
            OverallDescription = CreateOverallDescription(OverallState);
        }

        /// <summary>
        /// Creates a fresh status snapshot without writing project files.
        /// </summary>
        internal static AICodedbStatusSnapshot Refresh()
        {
            return new AICodedbStatusSnapshot(null);
        }

        internal static AICodedbStatusSnapshot Refresh(AICodedbCommandResult hostPayloadResult)
        {
            if (hostPayloadResult == null)
                throw new ArgumentNullException(nameof(hostPayloadResult));
            return new AICodedbStatusSnapshot(hostPayloadResult);
        }

        /// <summary>
        /// Returns true when all setup status checks are currently passing.
        /// </summary>
        internal bool IsReady()
        {
            return OverallState == AICodedbStatusState.Ok;
        }

        /// <summary>
        /// Returns whether the installed host payload exactly matches this package.
        /// </summary>
        internal bool IsHostPayloadCurrent()
        {
            return HostPayloadStatus.IsCurrent;
        }

        /// <summary>
        /// Returns the current host-payload group status.
        /// </summary>
        internal AICodedbStatusState GetHostPayloadState()
        {
            return HostPayload.State;
        }

        /// <summary>
        /// Returns the current Provider group status.
        /// </summary>
        internal AICodedbStatusState GetProviderState()
        {
            return ProviderExecutable.State;
        }

        /// <summary>
        /// Returns the current Config group status.
        /// </summary>
        internal AICodedbStatusState GetConfigState()
        {
            return CombineStates(ProviderConfig.State, RuntimeConfigTemplate.State);
        }

        /// <summary>
        /// Returns the current Runtime group status.
        /// </summary>
        internal AICodedbStatusState GetRuntimeState()
        {
            return CombineStates(RuntimeDirectory.State, RuntimeBoundary.State);
        }

        /// <summary>
        /// Returns the current Index group status.
        /// </summary>
        internal AICodedbStatusState GetIndexState()
        {
            return CombineStates(IndexDirectory.State, IndexManifest.State);
        }

        /// <summary>
        /// Returns the current Shader/HLSL text adapter status.
        /// </summary>
        internal AICodedbStatusState GetTextAdapterState()
        {
            return CombineStates(TextAdapterDirectory.State, TextAdapterManifest.State);
        }

        /// <summary>
        /// Returns the current MCP group status.
        /// </summary>
        internal AICodedbStatusState GetMcpState()
        {
            return ProjectMcpConfig.State;
        }

        /// <summary>
        /// Returns the current Policy group status.
        /// </summary>
        internal AICodedbStatusState GetPolicyState()
        {
            return ToolProfile.State;
        }

        /// <summary>
        /// Combines two status states into the highest severity.
        /// </summary>
        /// <param name="first">First state.</param>
        /// <param name="second">Second state.</param>
        internal static AICodedbStatusState CombineStates(AICodedbStatusState first, AICodedbStatusState second)
        {
            if (first == AICodedbStatusState.Error || second == AICodedbStatusState.Error)
                return AICodedbStatusState.Error;

            if (first == AICodedbStatusState.Warning || second == AICodedbStatusState.Warning)
                return AICodedbStatusState.Warning;

            return AICodedbStatusState.Ok;
        }

        internal static AICodedbStatusState GetHostManagementState(
            AICodedbStatusState payload,
            AICodedbStatusState generation,
            AICodedbStatusState upgrade,
            AICodedbStatusState updatePolicy)
        {
            var state = CombineStates(payload, generation);
            state = CombineStates(state, upgrade);
            return CombineStates(state, updatePolicy);
        }

        /// <summary>
        /// Creates a compact display label for a status state.
        /// </summary>
        /// <param name="state">Status state.</param>
        internal static string GetStateLabel(AICodedbStatusState state)
        {
            switch (state)
            {
                case AICodedbStatusState.Ok:
                    return "OK";
                case AICodedbStatusState.Inactive:
                    return "Inactive";
                case AICodedbStatusState.Warning:
                    return "Needs Setup";
                case AICodedbStatusState.Error:
                    return "Error";
                default:
                    return "Unknown";
            }
        }

        /// <summary>
        /// Computes the highest severity across all setup checks.
        /// </summary>
        private AICodedbStatusState ResolveOverallState()
        {
            var state = GetHostManagementState(
                HostPayload.State,
                HostGeneration.State,
                HostUpgrade.State,
                HostUpdatePolicy.State);
            state = CombineStates(state, ProviderExecutable.State);
            state = CombineStates(state, ProviderConfig.State);
            state = CombineStates(state, RuntimeConfigTemplate.State);
            state = CombineStates(state, RuntimeDirectory.State);
            state = CombineStates(state, IndexDirectory.State);
            state = CombineStates(state, IndexManifest.State);
            state = CombineStates(state, ProjectMcpConfig.State);
            state = CombineStates(state, RuntimeBoundary.State);
            state = CombineStates(state, ToolProfile.State);
            return state;
        }

        /// <summary>
        /// Creates the top-level status title.
        /// </summary>
        /// <param name="state">Overall status state.</param>
        private static string CreateOverallTitle(AICodedbStatusState state)
        {
            var projectName = AICodedbProjectSettings.ProjectDisplayName;
            switch (state)
            {
                case AICodedbStatusState.Ok:
                    return projectName + " codedb is ready";
                case AICodedbStatusState.Warning:
                    return projectName + " codedb needs setup";
                case AICodedbStatusState.Error:
                    return projectName + " codedb has blocking issues";
                default:
                    return projectName + " codedb status is unknown";
            }
        }

        /// <summary>
        /// Creates the top-level status description.
        /// </summary>
        /// <param name="state">Overall status state.</param>
        private static string CreateOverallDescription(AICodedbStatusState state)
        {
            switch (state)
            {
                case AICodedbStatusState.Ok:
                    return "Discover Read only. Runtime stays inside this Unity project.";
                case AICodedbStatusState.Warning:
                    return "Complete the host payload or warning items before relying on codedb for discovery.";
                case AICodedbStatusState.Error:
                    return "Fix the error items before using or refreshing the codedb setup.";
                default:
                    return "Refresh status or run verification to inspect the local setup.";
            }
        }

        /// <summary>
        /// Builds the status item for a required file.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="relativePath">Unity-project-relative file path.</param>
        private static AICodedbStatusItem CreateFileStatus(string label, string relativePath)
        {
            var path = AICodedbPaths.GetProjectPath(relativePath);
            if (File.Exists(path))
                return AICodedbStatusItem.Ok(label, "Found", relativePath);

            return AICodedbStatusItem.Warning(label, "Missing", relativePath);
        }

        private static AICodedbStatusItem CreateAbsoluteFileStatus(string label, string absolutePath)
        {
            var detail = AICodedbPaths.ToProjectRelativeDisplayPath(absolutePath);
            if (File.Exists(absolutePath))
                return AICodedbStatusItem.Ok(label, "Found", detail);
            return AICodedbStatusItem.Warning(label, "Missing", detail);
        }

        private static AICodedbStatusItem CreateLastKnownGoodStatus(bool hostPayloadMarkerExists)
        {
            const string label = "Last known good";
            var absolutePath = AICodedbPaths.HostLastKnownGoodPointerPath;
            var detail = AICodedbPaths.ToProjectRelativeDisplayPath(absolutePath);
            if (!File.Exists(absolutePath))
            {
                return AICodedbStatusItem.Inactive(
                    label,
                    "Not retained",
                    detail + " is created when an existing current generation is upgraded.");
            }

            var selection = AICodedbHostGenerationStore.ResolvePointer(
                AICodedbPaths.ProjectRoot,
                absolutePath);
            if (!hostPayloadMarkerExists)
            {
                return AICodedbStatusItem.Inactive(
                    label,
                    "Historical",
                    "No installed host payload marker exists. " + selection.Detail);
            }
            if (selection.State == AICodedbHostGenerationState.Invalid
                || selection.State == AICodedbHostGenerationState.Unavailable)
                return AICodedbStatusItem.Error(label, "Invalid", selection.Detail);
            if (selection.State == AICodedbHostGenerationState.DowngradeReviewRequired)
                return AICodedbStatusItem.Warning(label, "Newer " + selection.GenerationId, selection.Detail);
            return AICodedbStatusItem.Ok(label, "Retained " + selection.GenerationId, detail);
        }

        private static AICodedbStatusItem CreateHostGenerationStatus(AICodedbHostGenerationSelection selection)
        {
            switch (selection.State)
            {
                case AICodedbHostGenerationState.Current:
                    return AICodedbStatusItem.Ok(
                        "Host generation",
                        selection.GenerationId,
                        $"Package {selection.PackageVersion}, sequence {selection.PayloadSequence}, bootstrap {selection.BootstrapProtocol}");
                case AICodedbHostGenerationState.Legacy:
                    return AICodedbStatusItem.Warning(
                        "Host generation",
                        "Legacy " + selection.GenerationId,
                        "The recognized poc.21 flat payload is awaiting generation migration.");
                case AICodedbHostGenerationState.Previous:
                    return AICodedbStatusItem.Warning(
                        "Host generation",
                        "Previous " + selection.GenerationId,
                        selection.Detail);
                case AICodedbHostGenerationState.DowngradeReviewRequired:
                    return AICodedbStatusItem.Warning(
                        "Host generation",
                        "Downgrade review required: " + selection.GenerationId,
                        selection.Detail);
                case AICodedbHostGenerationState.Unavailable:
                    return AICodedbStatusItem.Warning("Host generation", "Not selected", selection.Detail);
                default:
                    return AICodedbStatusItem.Error("Host generation", "Invalid", selection.Detail);
            }
        }

        private static AICodedbStatusItem CreateHostUpdatePolicyStatus(AICodedbHostUpdatePolicy policy)
        {
            if (!policy.IsValid)
                return AICodedbStatusItem.Error("Automatic host updates", "Invalid", policy.Detail);
            if (policy.IsEnabled)
                return AICodedbStatusItem.Ok("Automatic host updates", policy.IsDefault ? "On (default)" : "On", policy.Detail);
            return AICodedbStatusItem.Inactive("Automatic host updates", "Off", policy.Detail);
        }

        private static AICodedbStatusItem CreateProviderConfigStatus()
        {
            var relativePath = AICodedbProjectSettings.ProviderConfigRelativePath;
            var path = AICodedbPaths.GetProjectPath(relativePath);
            if (!File.Exists(path))
                return BuildProviderConfigStatus(false, string.Empty, relativePath);

            try
            {
                return BuildProviderConfigStatus(true, File.ReadAllText(path), relativePath);
            }
            catch (Exception exception)
            {
                return AICodedbStatusItem.Error("Provider config", "Check failed", exception.Message);
            }
        }

        internal static AICodedbStatusItem BuildProviderConfigStatus(bool exists, string config, string detail)
        {
            if (!exists)
                return AICodedbStatusItem.Warning("Provider config", "Missing", detail);

            var currentSection = string.Empty;
            var flushIntervalCount = 0;
            var flushIntervalValid = false;
            using (var reader = new StringReader(config ?? string.Empty))
            {
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    var commentIndex = line.IndexOf('#');
                    var content = (commentIndex >= 0 ? line.Substring(0, commentIndex) : line).Trim();
                    if (content.StartsWith("[", StringComparison.Ordinal)
                        && content.EndsWith("]", StringComparison.Ordinal)
                        && content.Length > 2)
                    {
                        currentSection = content.Substring(1, content.Length - 2).Trim();
                        continue;
                    }

                    if (!string.Equals(currentSection, "logging", StringComparison.OrdinalIgnoreCase))
                        continue;

                    var separatorIndex = content.IndexOf('=');
                    if (separatorIndex < 0
                        || !string.Equals(content.Substring(0, separatorIndex).Trim(), "flush_interval_ms", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    flushIntervalCount++;
                    int flushIntervalMilliseconds;
                    flushIntervalValid = int.TryParse(content.Substring(separatorIndex + 1).Trim(), out flushIntervalMilliseconds)
                                         && flushIntervalMilliseconds > 0;
                }
            }

            if (flushIntervalCount != 1 || !flushIntervalValid)
            {
                return AICodedbStatusItem.Warning(
                    "Provider config",
                    "Update Required",
                    detail + " is missing a valid [logging].flush_interval_ms. Use Regenerate.");
            }

            return AICodedbStatusItem.Ok("Provider config", "Found", detail);
        }

        /// <summary>
        /// Builds the status item for a required directory.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="relativePath">Unity-project-relative directory path.</param>
        private static AICodedbStatusItem CreateDirectoryStatus(string label, string relativePath)
        {
            var path = AICodedbPaths.GetProjectPath(relativePath);
            if (Directory.Exists(path))
                return AICodedbStatusItem.Ok(label, "Found", relativePath);

            return AICodedbStatusItem.Warning(label, "Missing", relativePath);
        }

        /// <summary>
        /// Checks that the runtime path stays inside the canonical Unity project root.
        /// </summary>
        private static AICodedbStatusItem CreateRuntimeBoundaryStatus(string relativePath)
        {
            var path = AICodedbPaths.GetProjectPath(relativePath);
            return AICodedbPaths.IsInsideProject(path)
                ? AICodedbStatusItem.Ok("Runtime boundary", "Project-local", relativePath)
                : AICodedbStatusItem.Error("Runtime boundary", "Outside project", path);
        }

        /// <summary>
        /// Checks that the active default capability profile stays read-only.
        /// </summary>
        private static AICodedbStatusItem CreateToolProfileStatus()
        {
            var profile = AICodedbProjectSettings.DefaultToolProfile;
            if (string.Equals(profile, "Discover Read", StringComparison.Ordinal))
                return AICodedbStatusItem.Ok("Default profile", profile, "Read-only discovery and source lookup.");

            return AICodedbStatusItem.Error("Default profile", profile, "Expected Discover Read.");
        }

    }

    internal readonly struct AICodedbStatusItem
    {
        internal string Label { get; }
        internal AICodedbStatusState State { get; }
        internal string Summary { get; }
        internal string Detail { get; }

        /// <summary>
        /// Creates a single status row for the codedb manager.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="state">Status severity.</param>
        /// <param name="summary">Short status summary.</param>
        /// <param name="detail">Additional detail or path.</param>
        private AICodedbStatusItem(string label, AICodedbStatusState state, string summary, string detail)
        {
            Label = label;
            State = state;
            Summary = summary;
            Detail = detail;
        }

        /// <summary>
        /// Creates an OK status item.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="summary">Short status summary.</param>
        /// <param name="detail">Additional detail or path.</param>
        internal static AICodedbStatusItem Ok(string label, string summary, string detail)
        {
            return new AICodedbStatusItem(label, AICodedbStatusState.Ok, summary, detail);
        }

        /// <summary>
        /// Creates a warning status item.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="summary">Short status summary.</param>
        /// <param name="detail">Additional detail or path.</param>
        internal static AICodedbStatusItem Warning(string label, string summary, string detail)
        {
            return new AICodedbStatusItem(label, AICodedbStatusState.Warning, summary, detail);
        }

        /// <summary>
        /// Creates an error status item.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="summary">Short status summary.</param>
        /// <param name="detail">Additional detail or path.</param>
        internal static AICodedbStatusItem Error(string label, string summary, string detail)
        {
            return new AICodedbStatusItem(label, AICodedbStatusState.Error, summary, detail);
        }

        internal static AICodedbStatusItem Inactive(string label, string summary, string detail)
        {
            return new AICodedbStatusItem(label, AICodedbStatusState.Inactive, summary, detail);
        }
    }

    internal enum AICodedbStatusState
    {
        Ok,
        Inactive,
        Warning,
        Error
    }
}
