using System;
using System.IO;
using System.Threading.Tasks;

namespace Rice.AI.Codedb.Editor
{
    internal sealed class AICodedbStatusSnapshot
    {
        private readonly AICodedbEditorExecutionContext _context;
        internal AICodedbStatusState OverallState { get; }
        internal string OverallTitle { get; }
        internal string OverallDescription { get; }
        internal AICodedbProjectIntegrationStatus ProjectIntegrationStatus { get; }
        internal AICodedbProductStatus ProductStatus { get; }
        internal bool IsProjectUninstalled => ProjectIntegrationStatus.IsUninstalled;
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
        internal AICodedbStatusItem McpAvailability { get; }
        internal AICodedbStatusItem RuntimeBoundary { get; }
        internal AICodedbStatusItem ToolProfile { get; }

        /// <summary>
        /// Captures the current read-only codedb setup status.
        /// </summary>
        private AICodedbStatusSnapshot(
            AICodedbEditorExecutionContext context,
            AICodedbCommandResult hostPayloadResult)
        {
            _context = context;
            ProjectIntegrationStatus = AICodedbProjectIntegrationStateStore.Read(context.ProjectRoot);
            var hostPayloadMarkerExists = File.Exists(context.GetProjectPath(AICodedbProjectSettings.HostPayloadMarkerRelativePath));
            HostGenerationSelection = AICodedbHostGenerationStore.Resolve(context.ProjectRoot);
            HostPayloadStatus = AICodedbHostPayloadStatusBuilder.Build(
                hostPayloadMarkerExists,
                hostPayloadResult,
                HostGenerationSelection.State == AICodedbHostGenerationState.Current
                    ? HostGenerationSelection.GenerationId
                    : string.Empty);
            ProductStatus = AICodedbProductStatusBuilder.Build(ProjectIntegrationStatus, hostPayloadResult);
            HostPayload = HostPayloadStatus.ToStatusItem();
            HostUpdatePolicyValue = AICodedbHostUpdatePolicyStore.Read(context.ProjectRoot);
            HostGeneration = CreateHostGenerationStatus(HostGenerationSelection);
            HostLastKnownGood = CreateLastKnownGoodStatus(hostPayloadMarkerExists);
            HostUpgradeStatus = AICodedbHostUpgradeStatusStore.Read(
                context.ProjectRoot,
                AICodedbProjectSettings.CurrentGenerationId);
            HostUpgrade = HostUpgradeStatus.ToStatusItem(hostPayloadMarkerExists);
            HostUpdatePolicy = CreateHostUpdatePolicyStatus(HostUpdatePolicyValue);
            ProviderExecutable = CreateAbsoluteFileStatus("Machine Provider executable", context.MachineProviderExecutablePath);
            ProviderConfig = CreateProviderConfigStatus();
            RuntimeConfigTemplate = CreateAbsoluteFileStatus("Runtime config template", ResolveRuntimeConfigTemplatePath());
            RuntimeDirectory = CreateDirectoryStatus("Runtime directory", context.RuntimeRelativePath);
            IndexDirectory = CreateDirectoryStatus("Index directory", context.IndexRelativePath);
            IndexManifest = CreateFileStatus("Index manifest", context.IndexManifestRelativePath);
            TextAdapterDirectory = CreateDirectoryStatus("Shader adapter directory", context.TextAdapterRelativePath);
            TextAdapterManifest = CreateFileStatus("Shader adapter manifest", context.TextAdapterManifestRelativePath);
            ProjectMcpConfig = CreateFileStatus("Project MCP config", AICodedbProjectSettings.ProjectMcpConfigRelativePath);
            McpAvailability = CreateProductLayerStatus(
                "MCP availability",
                ProductStatus.McpAvailable,
                AICodedbProjectSettings.McpAvailabilityStateRelativePath);
            RuntimeBoundary = CreateRuntimeBoundaryStatus(context.RuntimeRelativePath);
            ToolProfile = CreateToolProfileStatus();
            OverallState = ResolveOverallState();
            OverallTitle = CreateOverallTitle(ProductStatus.State, context.ProjectDisplayName);
            OverallDescription = CreateOverallDescription(ProductStatus);
        }

        private AICodedbStatusSnapshot(string projectDisplayName)
        {
            _context = default(AICodedbEditorExecutionContext);
            ProjectIntegrationStatus = new AICodedbProjectIntegrationStatus(
                AICodedbProjectIntegrationState.Installed,
                AICodedbProjectCleanupState.None,
                string.Empty,
                "Checking project integration in the background.");
            ProductStatus = new AICodedbProductStatus(
                AICodedbProductState.Starting,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                AICodedbProductLayerState.Pending,
                "CodeDB is checking the project integration in the background.");
            HostPayloadStatus = new AICodedbHostPayloadStatus(
                AICodedbHostPayloadState.Unknown,
                AICodedbStatusState.Warning,
                "Checking",
                "Host status is loading in the background.");
            HostGenerationSelection = new AICodedbHostGenerationSelection(
                AICodedbHostGenerationState.Unavailable,
                string.Empty,
                string.Empty,
                string.Empty,
                0,
                0,
                string.Empty,
                "Host generation status is loading in the background.");
            HostUpgradeStatus = new AICodedbHostUpgradeStatus(
                AICodedbHostUpgradePhase.Unavailable,
                AICodedbStatusState.Inactive,
                string.Empty,
                "Checking",
                string.Empty);
            HostUpdatePolicyValue = new AICodedbHostUpdatePolicy(true, true, true, "Checking");
            HostPayload = HostPayloadStatus.ToStatusItem();
            HostGeneration = Checking("Host generation");
            HostLastKnownGood = Checking("Last known good");
            HostUpgrade = Checking("Host upgrade");
            HostUpdatePolicy = Checking("Automatic host updates");
            ProviderExecutable = Checking("Provider executable");
            ProviderConfig = Checking("Provider config");
            RuntimeConfigTemplate = Checking("Runtime config template");
            RuntimeDirectory = Checking("Runtime directory");
            IndexDirectory = Checking("Index directory");
            IndexManifest = Checking("Index manifest");
            TextAdapterDirectory = Checking("Shader adapter directory");
            TextAdapterManifest = Checking("Shader adapter manifest");
            ProjectMcpConfig = Checking("Project MCP config");
            McpAvailability = Checking("MCP availability");
            RuntimeBoundary = Checking("Runtime boundary");
            ToolProfile = AICodedbStatusItem.Ok("Default profile", AICodedbProjectSettings.DefaultToolProfile, "Read-only discovery and source lookup.");
            OverallState = AICodedbStatusState.Warning;
            OverallTitle = CreateOverallTitle(AICodedbProductState.Starting, projectDisplayName);
            OverallDescription = CreateOverallDescription(ProductStatus);
        }

        /// <summary>
        /// Creates a fresh status snapshot without writing project files.
        /// </summary>
        internal static AICodedbStatusSnapshot Refresh()
        {
            return new AICodedbStatusSnapshot(AICodedbPaths.CaptureExecutionContext(), null);
        }

        internal static AICodedbStatusSnapshot Refresh(AICodedbCommandResult hostPayloadResult)
        {
            if (hostPayloadResult == null)
                throw new ArgumentNullException(nameof(hostPayloadResult));
            return new AICodedbStatusSnapshot(AICodedbPaths.CaptureExecutionContext(), hostPayloadResult);
        }

        internal static AICodedbStatusSnapshot CreateStarting(string projectDisplayName)
        {
            return new AICodedbStatusSnapshot(projectDisplayName);
        }

        internal static Task<AICodedbStatusSnapshot> RefreshAsync(
            AICodedbEditorExecutionContext context,
            AICodedbCommandResult hostPayloadResult)
        {
            return Task.Run(() => new AICodedbStatusSnapshot(context, hostPayloadResult));
        }

        /// <summary>
        /// Returns true when all setup status checks are currently passing.
        /// </summary>
        internal bool IsReady()
        {
            return ProductStatus.IsReady;
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
            return CombineStates(ProjectMcpConfig.State, McpAvailability.State);
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
            switch (ProductStatus.State)
            {
                case AICodedbProductState.Ready:
                    return AICodedbStatusState.Ok;
                case AICodedbProductState.Uninstalled:
                    return AICodedbStatusState.Inactive;
                case AICodedbProductState.Starting:
                    return AICodedbStatusState.Warning;
                case AICodedbProductState.MissingPrerequisite:
                    return AICodedbStatusState.Error;
                default:
                    return AICodedbStatusState.Error;
            }
        }

        /// <summary>
        /// Creates the top-level status title.
        /// </summary>
        /// <param name="state">Overall status state.</param>
        private static string CreateOverallTitle(AICodedbProductState state, string projectDisplayName)
        {
            var projectName = string.IsNullOrWhiteSpace(projectDisplayName)
                ? "UnityProject"
                : projectDisplayName;
            switch (state)
            {
                case AICodedbProductState.Ready:
                    return projectName + " · Ready";
                case AICodedbProductState.Starting:
                    return projectName + " · Starting";
                case AICodedbProductState.Uninstalled:
                    return projectName + " · Uninstalled";
                case AICodedbProductState.MissingPrerequisite:
                    return projectName + " · Missing prerequisite";
                default:
                    return projectName + " · Needs attention";
            }
        }

        /// <summary>
        /// Creates the top-level status description.
        /// </summary>
        /// <param name="state">Overall status state.</param>
        private static string CreateOverallDescription(AICodedbProductStatus status)
        {
            switch (status.State)
            {
                case AICodedbProductState.Ready:
                    return "The project-local CodeDB backend passed initialize, tools/list, usable codedb_status, and a bounded text query.";
                case AICodedbProductState.Starting:
                    return "CodeDB is checking or converging the project integration in the background.";
                case AICodedbProductState.Uninstalled:
                    return "CodeDB project integration is explicitly uninstalled; the Package remains installed.";
                case AICodedbProductState.MissingPrerequisite:
                    return string.IsNullOrWhiteSpace(status.Detail)
                        ? "Install the supported Node.js runtime and compatible machine Provider."
                        : status.Detail;
                default:
                    return string.IsNullOrWhiteSpace(status.Detail)
                        ? "CodeDB could not complete the project-local usable path."
                        : status.Detail;
            }
        }

        private static AICodedbStatusItem CreateProductLayerStatus(
            string label,
            AICodedbProductLayerState layerState,
            string detail)
        {
            switch (layerState)
            {
                case AICodedbProductLayerState.Current:
                    return AICodedbStatusItem.Ok(label, "Current", detail);
                case AICodedbProductLayerState.Blocked:
                case AICodedbProductLayerState.Unavailable:
                    return AICodedbStatusItem.Error(label, layerState.ToString(), detail);
                default:
                    return AICodedbStatusItem.Warning(label, "Pending", detail);
            }
        }

        /// <summary>
        /// Builds the status item for a required file.
        /// </summary>
        /// <param name="label">Status label.</param>
        /// <param name="relativePath">Unity-project-relative file path.</param>
        private AICodedbStatusItem CreateFileStatus(string label, string relativePath)
        {
            var path = _context.GetProjectPath(relativePath);
            if (File.Exists(path))
                return AICodedbStatusItem.Ok(label, "Found", relativePath);

            return AICodedbStatusItem.Warning(label, "Missing", relativePath);
        }

        private AICodedbStatusItem CreateAbsoluteFileStatus(string label, string absolutePath)
        {
            var detail = ToProjectRelativeDisplayPath(absolutePath);
            if (File.Exists(absolutePath))
                return AICodedbStatusItem.Ok(label, "Found", detail);
            return AICodedbStatusItem.Warning(label, "Missing", detail);
        }

        private AICodedbStatusItem CreateLastKnownGoodStatus(bool hostPayloadMarkerExists)
        {
            const string label = "Last known good";
            var absolutePath = _context.GetProjectPath(AICodedbProjectSettings.HostLastKnownGoodPointerRelativePath);
            var detail = ToProjectRelativeDisplayPath(absolutePath);
            if (!File.Exists(absolutePath))
            {
                return AICodedbStatusItem.Inactive(
                    label,
                    "Not retained",
                    detail + " is created when an existing current generation is upgraded.");
            }

            var selection = AICodedbHostGenerationStore.ResolvePointer(
                _context.ProjectRoot,
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

        private AICodedbStatusItem CreateProviderConfigStatus()
        {
            var relativePath = _context.ProviderConfigRelativePath;
            var path = _context.GetProjectPath(relativePath);
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
        private AICodedbStatusItem CreateDirectoryStatus(string label, string relativePath)
        {
            var path = _context.GetProjectPath(relativePath);
            if (Directory.Exists(path))
                return AICodedbStatusItem.Ok(label, "Found", relativePath);

            return AICodedbStatusItem.Warning(label, "Missing", relativePath);
        }

        /// <summary>
        /// Checks that the runtime path stays inside the canonical Unity project root.
        /// </summary>
        private AICodedbStatusItem CreateRuntimeBoundaryStatus(string relativePath)
        {
            var path = _context.GetProjectPath(relativePath);
            return IsInsideProject(path)
                ? AICodedbStatusItem.Ok("Runtime boundary", "Project-local", relativePath)
                : AICodedbStatusItem.Error("Runtime boundary", "Outside project", path);
        }

        private string ResolveRuntimeConfigTemplatePath()
        {
            if (HostGenerationSelection.State == AICodedbHostGenerationState.Current
                || HostGenerationSelection.State == AICodedbHostGenerationState.Previous
                || HostGenerationSelection.State == AICodedbHostGenerationState.DowngradeReviewRequired)
            {
                return AICodedbPaths.NormalizePath(Path.Combine(
                    HostGenerationSelection.RootPath,
                    "codedb-mcp.runtime.example.toml"));
            }
            return _context.GetProjectPath(AICodedbProjectSettings.RuntimeConfigTemplateRelativePath);
        }

        private string ToProjectRelativeDisplayPath(string path)
        {
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            var root = _context.ProjectRoot.TrimEnd('/', '\\');
            var prefix = root + "/";
            return normalizedPath.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
                ? normalizedPath.Substring(prefix.Length)
                : normalizedPath;
        }

        private bool IsInsideProject(string path)
        {
            var normalizedPath = AICodedbPaths.NormalizePath(path);
            var root = _context.ProjectRoot.TrimEnd('/', '\\');
            return string.Equals(normalizedPath, root, StringComparison.OrdinalIgnoreCase)
                   || normalizedPath.StartsWith(root + "/", StringComparison.OrdinalIgnoreCase);
        }

        private static AICodedbStatusItem Checking(string label)
        {
            return AICodedbStatusItem.Warning(label, "Checking", "Status is loading in the background.");
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
