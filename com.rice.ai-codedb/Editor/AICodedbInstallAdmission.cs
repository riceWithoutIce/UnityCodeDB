using System;
using System.Collections.Generic;
using System.IO;

namespace Rice.AI.Codedb.Editor
{
    // The route belongs to the admitted action, never to a reconstructed title.
    internal static class AICodedbInstallAdmission
    {
        internal const string ProjectInstallRoute = "project-install-v1";

        internal static void ValidateRoute(AICodedbEditorExecutionContext context, string actionId,
            Dictionary<string, object> manifest)
        {
            var path = AICodedbPaths.GetManagerActionIndexPath(context, actionId);
            if (!File.Exists(path)) return; // closed receipt history is read independently
            var index = AICodedbStrictJson.ReadObject(path, 16384, "Manager route admission");
            var route = Route(index);
            if (route != Route(manifest) || (route != string.Empty &&
                (route != ProjectInstallRoute || AICodedbStrictJson.GetRequiredString(index,
                    "title", "Manager route admission") != "Install CodeDB")))
                throw new InvalidOperationException("Manager route differs from its admitted identity.");
        }

        private static string Route(Dictionary<string, object> record)
        {
            return record.ContainsKey("execution_route")
                ? AICodedbStrictJson.GetRequiredString(record, "execution_route", "Manager route") : string.Empty;
        }

        internal static string ReadCompetingAuthority(AICodedbEditorExecutionContext context, string actionId)
        {
            try
            {
                AICodedbProcessRunner.ValidateActionManifest(context, actionId);
                var identity = AICodedbStrictJson.ReadObject(Path.Combine(
                    AICodedbPaths.GetManagerActionReceiptRoot(context, actionId), "action.json"),
                    16384, "Project Install route");
                if (Route(identity) != ProjectInstallRoute)
                    throw new InvalidOperationException("The admitted project Install route is missing.");
                var contract = AICodedbPackageRuntimeContractStore.Read(context.PackageRoot);
                var runtime = AICodedbSupervisorLauncher.GetSupervisorRuntimePath(context.ProjectRoot, contract.ControlContract);
                var map = Path.Combine(runtime, "manager-actions", actionId + ".json");
                var operation = Path.Combine(runtime, "operation.json");
                foreach (var path in new[] { map, operation })
                {
                    for (var current = path; !string.IsNullOrEmpty(current); current = Path.GetDirectoryName(current))
                        if ((File.Exists(current) || Directory.Exists(current)) &&
                            (File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
                            throw new InvalidOperationException("Supervisor evidence traverses a redirected path.");
                    if (Directory.Exists(path)) throw new InvalidOperationException("Supervisor evidence is not a file.");
                }
                // Any map is a competing claim, including incomplete/old maps.
                if (File.Exists(map)) return "The project Install also has a Supervisor claim; no result was adopted.";
                if (File.Exists(operation))
                {
                    var record = AICodedbStrictJson.ReadObject(operation, 262144, "Supervisor canonical operation");
                    if (record.TryGetValue("manager_action_id", out var id) && (id as string) == actionId)
                        return "The project Install also has a Supervisor operation; no result was adopted.";
                }
                return string.Empty;
            }
            catch (Exception exception)
            {
                return "Project Install authority observation is unavailable: " + exception.Message;
            }
        }
    }
}
