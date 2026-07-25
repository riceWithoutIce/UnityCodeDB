using UnityEditor;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbMenuItems
    {
        private const int PriorityManager = 0;
        private const int PrioritySetup = 20;
        private const int PriorityIndex = 30;
        private const int PriorityMcp = 40;
        private const int PriorityPolicy = 50;

        /// <summary>
        /// Opens the codedb manager overview.
        /// </summary>
        [MenuItem(AICodedbProjectSettings.MenuRoot + "Manager", false, PriorityManager)]
        private static void OpenManager()
        {
            AICodedbManagerWindow.Open(AICodedbManagerTab.Overview);
        }

        /// <summary>
        /// Opens the codedb manager setup tab.
        /// </summary>
        [MenuItem(AICodedbProjectSettings.MenuRoot + "Setup", false, PrioritySetup)]
        private static void OpenSetup()
        {
            AICodedbManagerWindow.Open(AICodedbManagerTab.Setup);
        }

        /// <summary>
        /// Opens the codedb manager index tab.
        /// </summary>
        [MenuItem(AICodedbProjectSettings.MenuRoot + "Index", false, PriorityIndex)]
        private static void OpenIndex()
        {
            AICodedbManagerWindow.Open(AICodedbManagerTab.Index);
        }

        /// <summary>
        /// Opens the codedb manager MCP tab.
        /// </summary>
        [MenuItem(AICodedbProjectSettings.MenuRoot + "MCP", false, PriorityMcp)]
        private static void OpenMcp()
        {
            AICodedbManagerWindow.Open(AICodedbManagerTab.Mcp);
        }

        /// <summary>
        /// Opens the codedb manager policy tab.
        /// </summary>
        [MenuItem(AICodedbProjectSettings.MenuRoot + "Policy", false, PriorityPolicy)]
        private static void OpenPolicy()
        {
            AICodedbManagerWindow.Open(AICodedbManagerTab.Policy);
        }
    }
}
