using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.ExceptionServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using NUnit.Framework;
using UnityEngine;

namespace Rice.AI.Codedb.Editor.Tests
{
    // Test entry only. Capture Application.dataPath on the Editor main thread;
    // AICodedbPaths may already be overridden by a simulated action context.
    internal sealed class AICodedbTestWorkspace
    {
        private const int MaximumEntries = 4096;
        private const int MaximumDepth = 32;
        private readonly string _parent;
        private readonly string _token;
        private readonly List<Exception> _cleanupFailures = new List<Exception>();
        private readonly List<IDisposable> _resources = new List<IDisposable>();
        private readonly Action<string, string> _probeFault;
        private bool _created;
        private bool _owned;
        private bool _reserved;
        private string ReservationPath => Root + ".reserve";
        internal string ProjectRoot { get; }
        internal string Root { get; }
        internal string OwnershipPath => Path.Combine(Root, ".codedb-test-owner");

        private AICodedbTestWorkspace(Action<string, string> probeFault, string ownershipToken = null)
        {
            _token = ownershipToken ?? Guid.NewGuid().ToString("N");
            if (!Guid.TryParseExact(_token, "N", out _) || _token != _token.ToLowerInvariant())
                throw new InvalidOperationException("Workspace ownership token must contain 32 lowercase hex characters.");
            var context = SynchronizationContext.Current;
            if (context == null || context.GetType().FullName != "UnityEngine.UnitySynchronizationContext")
                throw new InvalidOperationException("Test workspace capture requires the Editor main thread.");
            var assets = Application.dataPath;
            if (string.IsNullOrWhiteSpace(assets) || !Path.IsPathRooted(assets)
                || !string.Equals(Path.GetFileName(assets), "Assets", StringComparison.OrdinalIgnoreCase)
                || !Directory.Exists(assets))
                throw new InvalidOperationException("Actual Unity project Assets context is unavailable; no workspace fallback exists.");
            ProjectRoot = Canonical(Path.GetDirectoryName(assets));
            _parent = Path.Combine(ProjectRoot, "Library", "CodeDB", "Tests");
            Root = Path.Combine(_parent, _token.Substring(0, 12));
            _probeFault = probeFault;
        }

        internal static void Run(Action<AICodedbTestWorkspace> body, Action<string, string> probeFault = null,
            string ownershipToken = null)
        {
            var workspace = new AICodedbTestWorkspace(probeFault, ownershipToken);
            Exception primary = null;
            try { workspace.Initialize(); body(workspace); }
            catch (Exception exception) { primary = exception; }
            workspace.Complete(primary);
        }

        internal static async Task RunAsync(Func<AICodedbTestWorkspace, Task> body)
        {
            var workspace = new AICodedbTestWorkspace(null);
            Exception primary = null;
            try { workspace.Initialize(); await body(workspace); }
            catch (Exception exception) { primary = exception; }
            workspace.Complete(primary);
        }

        internal string GetPath(string relative)
        {
            if (string.IsNullOrWhiteSpace(relative) || Path.IsPathRooted(relative))
                throw new InvalidOperationException("A test path must be an explicit relative descendant.");
            foreach (var part in relative.Replace('\\', '/').Split('/'))
                if (part == ".." || part == "." || part.Length == 0)
                    throw new InvalidOperationException("Test path traversal is not allowed: " + relative);
            var result = Canonical(Path.Combine(Root, relative));
            AssertDescendant(Root, result);
            AssertNoReparse(result);
            return result;
        }

        // Register immediately after scope creation, including before constructors
        // can assert. Dispose records failures so it cannot replace a body exception.
        internal IDisposable RegisterCleanup(Action cleanup)
        {
            var resource = new CleanupResource(this, cleanup);
            _resources.Add(resource);
            return resource;
        }

        internal void CaptureCleanup(Action cleanup)
        {
            try { cleanup(); }
            catch (Exception exception) { _cleanupFailures.Add(exception); }
        }

        private sealed class CleanupResource : IDisposable
        {
            private readonly AICodedbTestWorkspace _owner;
            private readonly Action _cleanup;
            private bool _disposed;
            internal CleanupResource(AICodedbTestWorkspace owner, Action cleanup) { _owner = owner; _cleanup = cleanup; }
            public void Dispose()
            {
                if (_disposed) return;
                _disposed = true;
                _owner.CaptureCleanup(_cleanup);
            }
        }

        private void Initialize()
        {
            var operation = "create owned workspace";
            try
            {
                AssertDescendant(ProjectRoot, _parent);
                AssertDescendant(_parent, Root);
                AssertNoReparse(Root);
                Directory.CreateDirectory(_parent);
                using (var reservation = new FileStream(ReservationPath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    var bytes = Encoding.UTF8.GetBytes(_token);
                    reservation.Write(bytes, 0, bytes.Length);
                }
                _reserved = true;
                if (Directory.Exists(Root) || File.Exists(Root))
                    throw new IOException("The unique test workspace already exists.");
                Directory.CreateDirectory(Root);
                _created = true;
                AssertNoReparse(Root);
                using (var stream = new FileStream(OwnershipPath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                {
                    var bytes = Encoding.UTF8.GetBytes(_token);
                    stream.Write(bytes, 0, bytes.Length);
                }
                _owned = true;
                var probeDirectory = GetPath("capability-probe");
                var probeFile = Path.Combine(probeDirectory, "probe.txt");
                operation = "probe-create";
                _probeFault?.Invoke(operation, Root);
                Directory.CreateDirectory(probeDirectory);
                using (var stream = new FileStream(probeFile, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                    stream.WriteByte(71);
                operation = "probe-read";
                _probeFault?.Invoke(operation, Root);
                if (File.ReadAllText(probeFile) != "G") throw new IOException("Workspace probe bytes changed.");
                operation = "probe-delete";
                _probeFault?.Invoke(operation, Root);
                File.Delete(probeFile);
                Directory.Delete(probeDirectory, false);
                if (Directory.Exists(probeDirectory)) throw new IOException("Workspace probe directory remains.");
                operation = "probe deepest Manager record and publication paths";
                ProbeReceiptPaths(Root);
            }
            catch (Exception exception)
            {
                throw new IOException("Test workspace setup failed during " + operation + " at " + Root
                    + "; no alternate root was selected.", exception);
            }
        }

        internal void ProbeReceiptPaths(string receiptRoot)
        {
            try { AssertDescendant(_parent, receiptRoot); }
            catch (Exception exception)
            {
                throw new IOException("Deep Manager path validation failed (length " + receiptRoot.Length + "): " + receiptRoot, exception);
            }
            var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                GetPath("project"), GetPath("package"), "path probe");
            using (AICodedbPaths.UseManagerActionsRootForTests(receiptRoot))
            {
                foreach (var path in AICodedbPaths.GetManagerReceiptRequiredPaths(context,
                    new string('a', 32), new string('b', 64)))
                {
                    try
                    {
                        AssertNoReparse(path);
                        Directory.CreateDirectory(Path.GetDirectoryName(path));
                        using (var stream = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                            stream.WriteByte(71);
                        if (File.ReadAllText(path) != "G") throw new IOException("Deep path probe bytes changed.");
                        File.Delete(path);
                    }
                    catch (Exception exception)
                    {
                        throw new IOException("Deep Manager path probe failed (length " + path.Length + "): " + path, exception);
                    }
                }
                // Remove only empty probe-owned directories; preserve the run root.
                Directory.Delete(AICodedbPaths.GetManagerActionReceiptRoot(context, new string('a', 32)), false);
                Directory.Delete(AICodedbPaths.GetManagerActionIndexDirectory(context), false);
            }
        }

        internal void ValidateCleanupTarget(string path, Func<string, bool> extraReparseForTests = null)
        {
            var target = Canonical(path);
            AssertDescendant(_parent, Root);
            if (!string.Equals(target, Root, StringComparison.OrdinalIgnoreCase)) AssertDescendant(Root, target);
            AssertNoReparse(target, extraReparseForTests);
            AssertNoReparse(OwnershipPath);
            if (!_owned || !File.Exists(OwnershipPath) || new FileInfo(OwnershipPath).Length != _token.Length
                || File.ReadAllText(OwnershipPath) != _token)
                throw new InvalidOperationException("Workspace ownership cannot be proved; retained path: " + Root);
        }

        private void CleanupOwnedRoot()
        {
            if (!_created) return;
            DeleteOwnedTree(Root);
        }

        internal void DeleteOwnedTree(string pathToDelete)
        {
            var target = Canonical(pathToDelete);
            ValidateCleanupTarget(target);
            var files = new List<string>();
            var directories = new List<string>();
            var queue = new Queue<KeyValuePair<string, int>>();
            queue.Enqueue(new KeyValuePair<string, int>(target, 0));
            var entries = 0;
            while (queue.Count != 0)
            {
                var directory = queue.Dequeue();
                if (directory.Value > MaximumDepth) throw new IOException("Workspace cleanup depth limit exceeded: " + Root);
                ValidateCleanupTarget(directory.Key);
                foreach (var path in Directory.EnumerateFileSystemEntries(directory.Key))
                {
                    if (++entries > MaximumEntries) throw new IOException("Workspace cleanup entry limit exceeded: " + Root);
                    ValidateCleanupTarget(path);
                    if ((File.GetAttributes(path) & FileAttributes.Directory) != 0)
                    {
                        directories.Add(path);
                        queue.Enqueue(new KeyValuePair<string, int>(path, directory.Value + 1));
                    }
                    else if (!string.Equals(path, OwnershipPath, StringComparison.OrdinalIgnoreCase)) files.Add(path);
                }
            }
            // Validate the complete bounded tree before any deletion, then recheck
            // each exact target. Never invoke recursive Directory.Delete.
            foreach (var file in files) { ValidateCleanupTarget(file); File.Delete(file); }
            for (var index = directories.Count - 1; index >= 0; index--)
            {
                ValidateCleanupTarget(directories[index]);
                Directory.Delete(directories[index], false);
            }
            ValidateCleanupTarget(target);
            if (string.Equals(target, Root, StringComparison.OrdinalIgnoreCase)) File.Delete(OwnershipPath);
            AssertNoReparse(target);
            Directory.Delete(target, false);
        }

        private void Complete(Exception primary)
        {
            for (var index = _resources.Count - 1; index >= 0; index--) _resources[index].Dispose();
            CaptureCleanup(CleanupOwnedRoot);
            CaptureCleanup(() =>
            {
                if (!_reserved) return;
                AssertNoReparse(ReservationPath);
                if (File.ReadAllText(ReservationPath) != _token)
                    throw new IOException("Workspace reservation ownership changed: " + ReservationPath);
                File.Delete(ReservationPath);
            });
            if (_cleanupFailures.Count != 0)
            {
                var failures = new List<Exception>();
                if (primary != null) failures.Add(primary);
                failures.AddRange(_cleanupFailures);
                throw new AggregateException("Test workspace cleanup failed. "
                    + (primary == null ? "No primary test exception. " : "Primary test exception is the first inner exception. ")
                    + "Workspace/residual path: " + Root, failures);
            }
            if (primary != null) ExceptionDispatchInfo.Capture(primary).Throw();
        }

        private static string Canonical(string path)
        {
            var full = Path.GetFullPath(path);
            return full.Length == Path.GetPathRoot(full).Length ? full
                : full.TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        }
        private static void AssertDescendant(string parent, string path)
        {
            var prefix = Canonical(parent).TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            if (!Canonical(path).StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Test workspace path escapes its owner: " + path);
        }
        private static void AssertNoReparse(string path, Func<string, bool> extraReparseForTests = null)
        {
            var current = Path.GetPathRoot(path);
            foreach (var part in path.Substring(current.Length).Split(new[] { Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar }, StringSplitOptions.RemoveEmptyEntries))
            {
                current = Path.Combine(current, part);
                if (extraReparseForTests != null && extraReparseForTests(current))
                    throw new InvalidOperationException("Injected reparse boundary: " + current);
                try
                {
                    if ((File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
                        throw new InvalidOperationException("Test workspace reparse boundary: " + current);
                }
                catch (FileNotFoundException) { }
                catch (DirectoryNotFoundException) { }
            }
        }
    }

    internal sealed class AICodedbTestWorkspaceTests
    {
        [Test]
        public void TestWorkspace_OwnedRootUsesActualProjectAndProbesCapabilities()
        {
            string root = null;
            AICodedbTestWorkspace.Run(workspace =>
            {
                root = workspace.Root;
                var expectedParent = Path.GetFullPath(Path.Combine(Application.dataPath, "..", "Library", "CodeDB", "Tests"));
                Assert.That(Path.GetDirectoryName(root), Is.EqualTo(expectedParent));
                Assert.That(File.Exists(workspace.OwnershipPath), Is.True);
                Assert.That(Path.GetFileName(root), Does.Match("^[0-9a-f]{12}$"));
                Assert.That(File.ReadAllText(workspace.OwnershipPath), Does.Match("^[0-9a-f]{32}$"));
                Assert.That(Directory.Exists(Path.Combine(root, "capability-probe")), Is.False);
                var file = workspace.GetPath("owned.txt");
                File.WriteAllText(file, "owned");
                Assert.That(File.ReadAllText(file), Is.EqualTo("owned"));
                using (AICodedbPaths.UseActionContext(new AICodedbEditorExecutionContext(
                    RuntimePlatform.WindowsEditor, workspace.GetPath("project"), workspace.GetPath("package"), "fixture")))
                    Assert.That(workspace.Root, Is.EqualTo(root));
            });
            Assert.That(Directory.Exists(root), Is.False);
        }

        [Test]
        public void TestWorkspace_ProbesS29DepthUsingProductionPaths()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                // Observed S29 receipt root length is 98; longest C# publication
                // path is 204. A longer current project naturally increases both.
                var root = workspace.GetPath(new string('d', Math.Max(1, 98 - workspace.Root.Length - 1)));
                workspace.ProbeReceiptPaths(root);
                using (AICodedbPaths.UseManagerActionsRootForTests(root))
                {
                    var context = new AICodedbEditorExecutionContext(RuntimePlatform.WindowsEditor,
                        workspace.GetPath("project"), workspace.GetPath("package"), "depth");
                    var maximum = 0;
                    foreach (var path in AICodedbPaths.GetManagerReceiptRequiredPaths(context, new string('a', 32), new string('b', 64)))
                        maximum = Math.Max(maximum, path.Length);
                    Assert.That(maximum, Is.GreaterThanOrEqualTo(204));
                    TestContext.WriteLine("Deepest actual production path: " + maximum);
                }
            });
        }

        [Test]
        public void TestWorkspace_ExclusiveCollisionPreservesExistingOwner()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                var token = File.ReadAllText(workspace.OwnershipPath);
                var bodyEntered = false;
                Assert.Throws<IOException>(() => AICodedbTestWorkspace.Run(_ => bodyEntered = true,
                    ownershipToken: token));
                Assert.That(bodyEntered, Is.False);
                Assert.That(File.ReadAllText(workspace.OwnershipPath), Is.EqualTo(token));
                workspace.ValidateCleanupTarget(workspace.Root);
            });
        }

        [Test]
        public void TestWorkspace_OverlongComponentReportsExactPathWithoutFallback()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                var root = Path.Combine(workspace.Root, new string('x', 256));
                var failure = Assert.Throws<IOException>(() => workspace.ProbeReceiptPaths(root));
                Assert.That(failure.Message, Does.Contain("length").And.Contain(root));
            });
        }

        [TestCase("probe-create")]
        [TestCase("probe-read")]
        [TestCase("probe-delete")]
        public void TestWorkspace_UnavailableCapabilityFailsBeforeBodyWithoutFallback(string failedOperation)
        {
            string attemptedRoot = null;
            var enteredBody = false;
            var failure = Assert.Throws<IOException>(() => AICodedbTestWorkspace.Run(
                _ => enteredBody = true,
                (operation, root) =>
                {
                    if (operation != failedOperation) return;
                    attemptedRoot = root;
                    throw new IOException("Owned capability fault.");
                }));
            Assert.That(enteredBody, Is.False);
            Assert.That(failure.Message, Does.Contain(failedOperation).And.Contain(attemptedRoot));
            Assert.That(Directory.Exists(attemptedRoot), Is.False);
        }

        [Test]
        public void TestWorkspace_CleanupRejectsOutsideTargetAndChangedOwnership()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                Assert.Throws<InvalidOperationException>(() => workspace.DeleteOwnedTree(Path.GetDirectoryName(workspace.Root)));
                Assert.Throws<InvalidOperationException>(() => workspace.GetPath("../another-run"));
                var ownership = File.ReadAllBytes(workspace.OwnershipPath);
                try
                {
                    File.WriteAllText(workspace.OwnershipPath, "other-owner");
                    Assert.Throws<InvalidOperationException>(() => workspace.DeleteOwnedTree(workspace.Root));
                    Assert.That(Directory.Exists(workspace.Root), Is.True);
                }
                finally { workspace.CaptureCleanup(() => File.WriteAllBytes(workspace.OwnershipPath, ownership)); }
            });
        }

        [Test]
        public void TestWorkspace_ReparseBoundaryIsRejectedBeforeTraversal()
        {
            AICodedbTestWorkspace.Run(workspace =>
            {
                var child = workspace.GetPath("owned-child");
                Directory.CreateDirectory(child);
                Assert.Throws<InvalidOperationException>(() => workspace.ValidateCleanupTarget(child,
                    path => string.Equals(path, child, StringComparison.OrdinalIgnoreCase)));
                Assert.That(Directory.Exists(child), Is.True);
            });
        }

        [Test]
        public void TestWorkspace_PrimaryFailureRestoresRegisteredScope()
        {
            var originalRoot = AICodedbPaths.GetManagerActionsRoot();
            var primary = new InvalidOperationException("Primary assertion substitute.");
            var observed = Assert.Throws<InvalidOperationException>(() => AICodedbTestWorkspace.Run(workspace =>
            {
                var scope = AICodedbPaths.UseManagerActionsRootForTests(workspace.GetPath("journal"));
                workspace.RegisterCleanup(scope.Dispose);
                throw primary;
            }));
            Assert.That(observed, Is.SameAs(primary));
            Assert.That(AICodedbPaths.GetManagerActionsRoot(), Is.EqualTo(originalRoot));
        }

        [Test]
        public void TestWorkspace_PrimaryAndCleanupFailuresRemainSeparate()
        {
            var primary = new InvalidOperationException("Primary failure.");
            var cleanup = new IOException("Cleanup failure.");
            var originalRoot = AICodedbPaths.GetManagerActionsRoot();
            string root = null;
            var observed = Assert.Throws<AggregateException>(() => AICodedbTestWorkspace.Run(workspace =>
            {
                root = workspace.Root;
                var scope = AICodedbPaths.UseManagerActionsRootForTests(workspace.GetPath("journal"));
                workspace.RegisterCleanup(scope.Dispose);
                workspace.RegisterCleanup(() => throw cleanup);
                throw primary;
            }));
            Assert.That(observed.InnerExceptions.Count, Is.EqualTo(2));
            Assert.That(observed.InnerExceptions[0], Is.SameAs(primary));
            Assert.That(observed.InnerExceptions[1], Is.SameAs(cleanup));
            Assert.That(observed.Message, Does.Contain(root));
            Assert.That(AICodedbPaths.GetManagerActionsRoot(), Is.EqualTo(originalRoot));
            Assert.That(Directory.Exists(root), Is.False);
        }

        [Test]
        public void TestWorkspace_CleanupOnlyFailureCannotPass()
        {
            var cleanup = new IOException("Cleanup-only failure.");
            var observed = Assert.Throws<AggregateException>(() => AICodedbTestWorkspace.Run(workspace =>
                workspace.RegisterCleanup(() => throw cleanup)));
            Assert.That(observed.InnerExceptions.Count, Is.EqualTo(1));
            Assert.That(observed.InnerExceptions[0], Is.SameAs(cleanup));
        }
    }
}
