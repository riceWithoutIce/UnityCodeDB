import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

export const HOST_USE_GATE_VERSION = 1;

const MATERIALIZER_RUNTIME = path.join("AIWork", ".runtime", "codedb", "payload-materializer");
const ACTIVE_MARKER = "materialize-active.json";
const LEASE_DIRECTORY = "host-use-leases";
const LEASE_OWNERS = new Set(["mcp", "watcher"]);

export function acquireCodedbHostUseLease(unityRoot, owner) {
  const normalizedOwner = String(owner ?? "").trim().toLowerCase();
  if (!LEASE_OWNERS.has(normalizedOwner)) {
    throw new Error(`Unsupported CodeDB host-use lease owner: ${owner}`);
  }

  const root = path.resolve(String(unityRoot ?? ""));
  const runtimeRoot = path.join(root, MATERIALIZER_RUNTIME);
  assertPathInside(runtimeRoot, root, "CodeDB host-use gate runtime");
  const activeMarkerPath = path.join(runtimeRoot, ACTIVE_MARKER);
  const leaseRoot = path.join(runtimeRoot, LEASE_DIRECTORY);

  assertMaterializerInactive(activeMarkerPath);
  fs.mkdirSync(leaseRoot, { recursive: true });

  const leaseId = `${normalizedOwner}-${process.pid}-${crypto.randomUUID().replace(/-/g, "")}`;
  const leasePath = path.join(leaseRoot, `${leaseId}.json`);
  const lease = {
    schema_version: 1,
    host_use_gate_version: HOST_USE_GATE_VERSION,
    managed_by: "com.rice.ai-codedb",
    lease_id: leaseId,
    owner: normalizedOwner,
    pid: process.pid,
    project_root: root,
    created_at_utc: new Date().toISOString()
  };

  let fd;
  try {
    try {
      fd = fs.openSync(leasePath, "wx");
      fs.writeFileSync(fd, `${JSON.stringify(lease, null, 2)}\n`, "utf8");
      fs.fsyncSync(fd);
    } finally {
      if (fd !== undefined) {
        fs.closeSync(fd);
        fd = undefined;
      }
    }
  } catch (error) {
    fs.rmSync(leasePath, { force: true });
    throw new Error(`Could not publish CodeDB ${normalizedOwner} host-use lease: ${error.message}`);
  }

  try {
    assertMaterializerInactive(activeMarkerPath);
  } catch (error) {
    fs.rmSync(leasePath, { force: true });
    removeEmptyDirectory(leaseRoot);
    removeEmptyDirectory(runtimeRoot);
    throw error;
  }

  let released = false;
  return {
    path: leasePath,
    release() {
      if (released) {
        return;
      }
      released = true;
      fs.rmSync(leasePath, { force: true });
      removeEmptyDirectory(leaseRoot);
      removeEmptyDirectory(runtimeRoot);
    }
  };
}

function assertMaterializerInactive(activeMarkerPath) {
  if (fs.existsSync(activeMarkerPath)) {
    throw new Error(`CodeDB host payload materialization is active: ${activeMarkerPath}`);
  }
}

function assertPathInside(targetPath, rootPath, label) {
  const target = path.resolve(targetPath);
  const root = path.resolve(rootPath);
  const prefix = root.endsWith(path.sep) ? root : `${root}${path.sep}`;
  if (target !== root && !target.startsWith(prefix)) {
    throw new Error(`${label} escapes the Unity project root: ${target}`);
  }
}

function removeEmptyDirectory(directoryPath) {
  try {
    fs.rmdirSync(directoryPath);
  } catch {
    // Another lease or the materializer still owns the shared runtime.
  }
}
