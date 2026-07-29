import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

export const GENERATION_LEASE_VERSION = 2;
export const GENERATION_ID = "poc.25";

const MATERIALIZER_RUNTIME = path.join("AIWork", ".runtime", "codedb", "payload-materializer");
const HOST_RUNTIME = path.join("AIWork", ".runtime", "codedb", "host");
const ACTIVE_MARKER = "materialize-active.json";
const LEASE_OWNERS = new Set(["mcp", "watcher"]);
const UNITY_PROJECT_MARKERS = ["Assets", "Packages", "ProjectSettings"];
const HEARTBEAT_INTERVAL_MS = 5000;

export function assertCodedbUnityProjectRoot(unityRoot) {
  const candidate = String(unityRoot ?? "").trim();
  if (!candidate) {
    throw new Error("CodeDB requires a Unity project root.");
  }

  const resolvedRoot = path.resolve(candidate);
  let root;
  try {
    root = fs.realpathSync(resolvedRoot);
  } catch (error) {
    throw new Error(`Invalid Unity project root ${resolvedRoot}: ${error.message}`);
  }

  if (!fs.statSync(root).isDirectory()) {
    throw new Error(`Invalid Unity project root ${root}: expected a directory.`);
  }

  for (const marker of UNITY_PROJECT_MARKERS) {
    const markerPath = path.join(root, marker);
    if (!fs.existsSync(markerPath) || !fs.statSync(markerPath).isDirectory()) {
      throw new Error(`Invalid Unity project root ${root}: missing ${marker} directory.`);
    }
  }

  return root;
}

export function acquireCodedbHostUseLease(unityRoot, owner, generationId = GENERATION_ID) {
  const normalizedOwner = String(owner ?? "").trim().toLowerCase();
  if (!LEASE_OWNERS.has(normalizedOwner)) {
    throw new Error(`Unsupported CodeDB generation lease owner: ${owner}`);
  }
  if (!/^[A-Za-z0-9._-]{1,64}$/.test(generationId)) {
    throw new Error(`Invalid CodeDB generation id: ${generationId}`);
  }

  const root = assertCodedbUnityProjectRoot(unityRoot);
  const materializerRoot = path.join(root, MATERIALIZER_RUNTIME);
  const activeMarkerPath = path.join(materializerRoot, ACTIVE_MARKER);
  const hostRoot = path.join(root, HOST_RUNTIME);
  const leasesRoot = path.join(hostRoot, "leases");
  const leaseRoot = path.join(leasesRoot, generationId);
  assertPathInside(leaseRoot, root, "CodeDB generation lease runtime");

  assertDestructiveMaterializerInactive(activeMarkerPath);
  fs.mkdirSync(leaseRoot, { recursive: true });

  const leaseId = `${normalizedOwner}-${process.pid}-${crypto.randomUUID().replace(/-/g, "")}`;
  const leasePath = path.join(leaseRoot, `${leaseId}.json`);
  const createdAt = new Date().toISOString();
  const lease = {
    schema_version: 2,
    generation_lease_version: GENERATION_LEASE_VERSION,
    managed_by: "com.rice.ai-codedb",
    generation_id: generationId,
    lease_id: leaseId,
    owner: normalizedOwner,
    pid: process.pid,
    process_start_identity: String(Math.max(0, Math.round(Date.now() - process.uptime() * 1000))),
    project_root: root,
    created_at_utc: createdAt,
    heartbeat_at_utc: createdAt
  };

  publishLease(leasePath, lease, true);
  try {
    assertDestructiveMaterializerInactive(activeMarkerPath);
  } catch (error) {
    fs.rmSync(leasePath, { force: true });
    removeEmptyDirectory(leaseRoot);
    removeEmptyDirectory(leasesRoot);
    throw error;
  }

  let released = false;
  const heartbeat = setInterval(() => {
    if (released) {
      return;
    }
    lease.heartbeat_at_utc = new Date().toISOString();
    try {
      publishLease(leasePath, lease, false);
    } catch {
      // A strict host mutation treats an unreadable lease as a blocker.
    }
  }, HEARTBEAT_INTERVAL_MS);
  heartbeat.unref();

  return {
    path: leasePath,
    generationId,
    release() {
      if (released) {
        return;
      }
      released = true;
      clearInterval(heartbeat);
      fs.rmSync(leasePath, { force: true });
      removeEmptyDirectory(leaseRoot);
      removeEmptyDirectory(leasesRoot);
    }
  };
}

function publishLease(leasePath, lease, createNew) {
  const temporaryPath = path.join(
    path.dirname(leasePath),
    `.${path.basename(leasePath)}.${process.pid}.${crypto.randomUUID()}.tmp`
  );
  let fd;
  try {
    if (createNew && fs.existsSync(leasePath)) {
      throw new Error(`CodeDB generation lease already exists: ${leasePath}`);
    }
    fd = fs.openSync(temporaryPath, "wx");
    fs.writeFileSync(fd, `${JSON.stringify(lease, null, 2)}\n`, "utf8");
    fs.fsyncSync(fd);
    fs.closeSync(fd);
    fd = undefined;
    fs.renameSync(temporaryPath, leasePath);
  } catch (error) {
    throw new Error(`Could not publish CodeDB ${lease.owner} generation lease: ${error.message}`);
  } finally {
    if (fd !== undefined) {
      fs.closeSync(fd);
    }
    fs.rmSync(temporaryPath, { force: true });
  }
}

function assertDestructiveMaterializerInactive(activeMarkerPath) {
  if (!fs.existsSync(activeMarkerPath)) {
    return;
  }
  try {
    const marker = JSON.parse(fs.readFileSync(activeMarkerPath, "utf8"));
    if (marker?.managed_by === "com.rice.ai-codedb" && marker?.action === "upgrade") {
      return;
    }
  } catch {
    // An invalid active marker remains a fail-closed blocker.
  }
  throw new Error(`CodeDB host payload materialization is active: ${activeMarkerPath}`);
}

function assertPathInside(targetPath, rootPath, label) {
  const target = path.resolve(targetPath);
  const root = path.resolve(rootPath);
  const relative = path.relative(root, target);
  if (relative === ".." || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
    throw new Error(`${label} escapes the Unity project root: ${target}`);
  }
}

function removeEmptyDirectory(directoryPath) {
  try {
    fs.rmdirSync(directoryPath);
  } catch {
    // Another lease still owns the generation directory.
  }
}
