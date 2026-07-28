using System;
using System.IO;
using NUnit.Framework;

namespace Rice.AI.Codedb.Editor.Tests
{
    internal sealed class AICodedbEditorLifecycleTests
    {
        private string _projectRoot;

        [SetUp]
        public void SetUp()
        {
            _projectRoot = Path.Combine(
                Path.GetTempPath(),
                "Rice-AICodedb-Lifecycle-Tests",
                Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Assets"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "Packages"));
            Directory.CreateDirectory(Path.Combine(_projectRoot, "ProjectSettings"));
        }

        [TearDown]
        public void TearDown()
        {
            if (Directory.Exists(_projectRoot))
                Directory.Delete(_projectRoot, true);
        }

        [Test]
        public void ValidateProjectRoot_AcceptsOnlyUnityProjectMarkers()
        {
            var validated = AICodedbEditorLifecycle.ValidateProjectRoot(_projectRoot);
            Assert.That(validated, Is.EqualTo(AICodedbPaths.NormalizePath(_projectRoot).TrimEnd('/')));

            Directory.Delete(Path.Combine(_projectRoot, "ProjectSettings"));
            var exception = Assert.Throws<InvalidOperationException>(
                () => AICodedbEditorLifecycle.ValidateProjectRoot(_projectRoot));
            Assert.That(exception.Message, Does.Contain("ProjectSettings"));
        }

        [Test]
        public void CreateProjectIdentity_IsCanonicalAndStable()
        {
            var identity = AICodedbEditorLifecycle.CreateProjectIdentity(_projectRoot);
            var equivalentPath = Path.Combine(_projectRoot, ".");

            Assert.That(identity, Does.Match("^sha256:[0-9a-f]{64}$"));
            Assert.That(AICodedbEditorLifecycle.CreateProjectIdentity(equivalentPath), Is.EqualTo(identity));
        }
    }
}
