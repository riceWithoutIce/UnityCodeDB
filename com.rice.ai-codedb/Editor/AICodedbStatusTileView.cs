using UnityEditor;
using UnityEngine;

namespace Rice.AI.Codedb.Editor
{
    internal static class AICodedbStatusTileView
    {
        /// <summary>
        /// Draws a compact status row without duplicating the state in a boxed column.
        /// </summary>
        /// <param name="label">Tile label.</param>
        /// <param name="description">Tile description.</param>
        /// <param name="state">Tile status.</param>
        internal static void Draw(string label, string description, AICodedbStatusState state)
        {
            AICodedbSectionView.DrawStatusRow(
                label,
                description,
                state,
                AICodedbStatusSnapshot.GetStateLabel(state));
        }

        /// <summary>
        /// Returns a built-in icon for a status state.
        /// </summary>
        /// <param name="state">Status state.</param>
        internal static GUIContent GetIconContent(AICodedbStatusState state)
        {
            switch (state)
            {
                case AICodedbStatusState.Ok:
                    return EditorGUIUtility.IconContent("TestPassed");
                case AICodedbStatusState.Inactive:
                    return EditorGUIUtility.IconContent("console.infoicon");
                case AICodedbStatusState.Warning:
                    return EditorGUIUtility.IconContent("console.warnicon");
                case AICodedbStatusState.Error:
                    return EditorGUIUtility.IconContent("console.erroricon");
                default:
                    return EditorGUIUtility.IconContent("console.infoicon");
            }
        }

    }
}
