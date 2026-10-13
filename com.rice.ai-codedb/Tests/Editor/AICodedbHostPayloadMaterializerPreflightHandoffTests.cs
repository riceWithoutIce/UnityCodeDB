using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbHostPayloadMaterializerPreflightHandoffTests
    {
        [Test]
        public void RemovalPreflight_RequiresOneAvailableLineAndHandoff()
        {
            var result = new AICodedbCommandResult(
                0,
                "[REMOVAL_PREFLIGHT] AVAILABLE\n[REMOVAL_PREFLIGHT_HANDOFF] abc.def\n",
                string.Empty,
                false);

            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(result), Is.True);
            Assert.That(AICodedbHostPayloadMaterializer.ReadRemovalPreflightHandoff(result), Is.EqualTo("abc.def"));
        }

        [Test]
        public void RemovalPreflight_RejectsMissingOrDuplicateHandoff()
        {
            var missing = new AICodedbCommandResult(0, "[REMOVAL_PREFLIGHT] AVAILABLE\n", string.Empty, false);
            var duplicate = new AICodedbCommandResult(
                0,
                "[REMOVAL_PREFLIGHT] AVAILABLE\n[REMOVAL_PREFLIGHT_HANDOFF] a.b\n[REMOVAL_PREFLIGHT_HANDOFF] c.d\n",
                string.Empty,
                false);

            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(missing), Is.False);
            Assert.That(AICodedbHostPayloadMaterializer.HasAuthenticatedRemovalPreflight(duplicate), Is.False);
            Assert.That(AICodedbHostPayloadMaterializer.ReadRemovalPreflightHandoff(missing), Is.Null);
            Assert.That(AICodedbHostPayloadMaterializer.ReadRemovalPreflightHandoff(duplicate), Is.Null);
        }

        [Test]
        public void RemovalIntegrationArguments_RequireHandoff()
        {
            Assert.Throws<System.ArgumentException>(() =>
                AICodedbHostPayloadMaterializer.BuildRuntimeScriptArguments(
                    AICodedbHostPayloadAction.RemoveIntegration,
                    true,
                    "G:/fixture/project"));
        }
    }
}
