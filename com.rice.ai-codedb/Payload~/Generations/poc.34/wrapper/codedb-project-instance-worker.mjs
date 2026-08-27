#!/usr/bin/env node

import crypto from "node:crypto";
import { execFile } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { AsyncLocalStorage } from "node:async_hooks";
import { performance } from "node:perf_hooks";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ADAPTER_EXTENSIONS = new Set([".shader", ".hlsl", ".compute", ".cginc"]);
const EXCLUDED_PREFIXES = [
  "Library/",
  "Temp/",
  "Logs/",
  "UserSettings/",
  "obj/",
  "bin/",
  "Build/",
  "Builds/",
  "AIWork/.runtime/"
];
const EXCLUDED_FRAGMENTS = ["/Library/PackageCache/", "/AIWork/.runtime/"];
const MAX_LIMIT = 200;
const MAX_READ_LINES = 200;
const MAX_OUTPUT_BYTES = 64 * 1024;
const COORDINATOR_QUERY_TIMEOUT_MS = 95000;
const COORDINATOR_STATUS_TIMEOUT_MS = 2000;
const COORDINATOR_CONNECT_RETRY_DELAYS_MS = [0, 50, 150];
const COORDINATOR_RETRYABLE_TRANSPORT_CODES = new Set(["EBUSY", "ECONNREFUSED", "ECONNRESET", "ENOENT", "EPIPE"]);
const MAX_COORDINATOR_RESPONSE_BYTES = 1024 * 1024;
const EDITOR_LEASE_STALE_AFTER_MS = 90000;
const EDITOR_LEASE_PROCESS_IDENTITY_RECHECK_AFTER_MS = 15000;
const ADAPTER_OPERATIONAL_STATES = new Set(["watching", "pending", "building"]);
const MANAGED_BY = "com.rice.ai-codedb";
const BOOTSTRAP_PROTOCOL = 1;
const PACKAGE_VERSION = "0.2.5-preview.5";
const REQUIRED_PROVIDER = Object.freeze({
  schemaVersion: 1,
  providerId: "killop/codedb-mcp",
  version: "0.5.0-28e3912",
  commit: "28e3912d5cd67ff3499734984f3e3d626a204796",
  executable: "codebase-mcp.exe",
  protocol: "codedb-cli-v1",
  source: "https://github.com/killop/codedb-mcp",
  packageMinInclusive: "0.2.5-preview.5",
  packageMaxExclusive: "0.2.6"
});
if (!new Set([22, 24]).has(Number.parseInt(process.versions.node.split(".")[0], 10))) {
  throw new Error("[MISSING_PREREQUISITE] CodeDB requires Node.js 22.x or 24.x LTS.");
}
const GENERATION_LEASE_VERSION = 2;
const GENERATION_HEARTBEAT_INTERVAL_MS = 5000;
const GENERATION_PIN_ATTEMPTS = 4;
const PROCESS_SNAPSHOT_TIMEOUT_MS = 5000;
const PROCESS_SNAPSHOT_MAX_BYTES = 1024 * 1024;
const READ_ONLY_TOOL_ANNOTATIONS = Object.freeze({
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false
});

let generationCache = null;

const baseContext = createContext(process.argv.slice(2));
let instanceLifetimeLease = null;
if (!baseContext.printContext) {
  instanceLifetimeLease = acquireInstanceLifetimeLease();
}
const requestGenerationStorage = new AsyncLocalStorage();
const context = new Proxy(baseContext, {
  get(target, property) {
    const generation = requestGenerationStorage.getStore();
    return generation && Object.prototype.hasOwnProperty.call(generation, property)
      ? generation[property]
      : target[property];
  }
});
if (context.printContext) {
  const generation = tryResolveCurrentGeneration();
  process.stdout.write(`${JSON.stringify({
    unity_root: context.unityRoot,
    project_slug: context.projectSlug,
    provider_name: context.providerName,
    runtime_root: context.instanceRelativePath,
    instance_id: context.instanceId,
    generation_id: generation?.generationId ?? null,
    bootstrap_protocol: BOOTSTRAP_PROTOCOL
  })}\n`);
  process.exit(0);
}

const tools = [
  {
    name: "codedb_status",
    description: "Report project-local wrapper, provider, and Shader/HLSL text adapter status.",
    annotations: READ_ONLY_TOOL_ANNOTATIONS,
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "codedb_search",
    description: "Search indexed project code through the project CodeDB wrapper.",
    annotations: READ_ONLY_TOOL_ANNOTATIONS,
    inputSchema: createSearchSchema()
  },
  {
    name: "codedb_text_search",
    description: "Run bounded text search across provider-indexed code and the Shader/HLSL adapter.",
    annotations: READ_ONLY_TOOL_ANNOTATIONS,
    inputSchema: createSearchSchema()
  },
  {
    name: "codedb_find",
    description: "Find project files or symbols through the project CodeDB wrapper.",
    annotations: READ_ONLY_TOOL_ANNOTATIONS,
    inputSchema: createSearchSchema()
  },
  {
    name: "codedb_read",
    description: "Read a bounded line range from an indexed project file.",
    annotations: READ_ONLY_TOOL_ANNOTATIONS,
    inputSchema: {
      type: "object",
      properties: {
        path: { type: "string" },
        start_line: { type: "integer", minimum: 1 },
        end_line: { type: "integer", minimum: 1 },
        startLine: { type: "integer", minimum: 1 },
        endLine: { type: "integer", minimum: 1 },
        language: { type: "string" }
      },
      required: ["path"],
      additionalProperties: true
    }
  },
  {
    name: "codedb_context",
    description: "Compose compact bounded project context from search and read results.",
    annotations: READ_ONLY_TOOL_ANNOTATIONS,
    inputSchema: createSearchSchema()
  }
];

process.stdin.setEncoding("utf8");

let stdinBuffer = "";
process.stdin.on("data", (chunk) => {
  stdinBuffer += chunk;
  while (true) {
    const newlineIndex = stdinBuffer.indexOf("\n");
    if (newlineIndex < 0) {
      break;
    }

    const line = stdinBuffer.slice(0, newlineIndex).trim();
    stdinBuffer = stdinBuffer.slice(newlineIndex + 1);
    if (line.length === 0) {
      continue;
    }

    handleMessageLine(line);
  }
});

process.stdin.on("end", () => {
  if (instanceLifetimeLease) {
    instanceLifetimeLease.release();
    instanceLifetimeLease = null;
  }
  process.exit(0);
});

function createSearchSchema() {
  return {
    type: "object",
    properties: {
      query: { type: "string" },
      pattern: { type: "string" },
      symbol: { type: "string" },
      path: { type: "string" },
      path_glob: { type: "string" },
      limit: { type: "integer", minimum: 1, maximum: MAX_LIMIT },
      language: { type: "string" },
      regex: { type: "boolean" }
    },
    additionalProperties: true
  };
}

function createContext(args) {
  const options = parseArgs(args);
  const unityRoot = resolveWrapperUnityRoot(options.root);
  const machineProvider = resolveMachineProvider();
  const instance = resolveInstanceContext(unityRoot, options.instanceRoot);
  const projectSlug = createProjectSlug(path.basename(unityRoot));
  const providerName = `codedb-${projectSlug}-${instance.instanceId.slice(0, 8)}`;
  const runtimeRoot = instance.instanceRoot;
  const hostRuntimeRoot = path.join(unityRoot, "AIWork", ".runtime", "codedb", "host");

  return {
    unityRoot,
    projectIdentity: createProjectIdentity(unityRoot),
    projectSlug,
    providerName,
    instanceId: instance.instanceId,
    instanceRoot: instance.instanceRoot,
    instanceRelativePath: instance.instanceRelativePath,
    instanceManifestPath: instance.instanceManifestPath,
    printContext: options.printContext === true,
    hostRuntimeRoot,
    currentGenerationPointerPath: instance.instanceManifestPath,
    providerExecutablePath: machineProvider.executablePath,
    providerManifestPath: machineProvider.manifestPath,
    providerConfigPath: path.join(runtimeRoot, "config", "codedb-mcp.toml"),
    watchConfigPath: path.join(runtimeRoot, "config", "codedb-mcp.watch.toml"),
    desiredStatePath: path.join(runtimeRoot, "watch", "lifecycle", "desired-state.json"),
    manualRuntimePath: path.join(runtimeRoot, "watch", "lifecycle", "manual-runtime.json"),
    editorLeaseRoot: path.join(runtimeRoot, "watch", "lifecycle", "editor-leases"),
    watchCoordinatorRuntimePath: path.join(runtimeRoot, "watch", "coordinator"),
    watchCoordinatorStatePath: path.join(runtimeRoot, "watch", "coordinator", "coordinator-state.json"),
    adapterBuilderPath: null,
    adapterWorkerPath: null,
    legacyAdapterBuilderPath: path.join(unityRoot, "AIWork", "codedb", "scripts", "build-codedb-project-text-adapter.ps1"),
    legacyAdapterWorkerPath: path.join(unityRoot, "AIWork", "codedb", "scripts", "run-codedb-project-text-adapter-worker.ps1"),
    providerIndexRoot: path.join(runtimeRoot, "index"),
    textAdapterRoot: path.join(runtimeRoot, "adapter", "text-index"),
    textAdapterManifestPath: path.join(runtimeRoot, "adapter", "text-index", "manifest.json"),
    textAdapterFilesPath: path.join(runtimeRoot, "adapter", "text-index", "files.jsonl"),
    textAdapterIndexPath: path.join(runtimeRoot, "adapter", "text-index", "index.jsonl")
  };
}

function resolveInstanceContext(unityRoot, requestedRelativePath) {
  if (!requestedRelativePath) {
    throw new Error("[CHECK_FAILED] CodeDB instance worker requires --instance-root.");
  }
  const relativePath = normalizeRelativePath(requestedRelativePath);
  const match = /^AIWork\/\.runtime\/codedb\/instances\/([a-f0-9]{32})$/i.exec(relativePath);
  if (!match) {
    throw new Error("[CHECK_FAILED] CodeDB instance root is not an approved project-relative path.");
  }
  const instanceId = match[1].toLowerCase();
  const instancesRoot = path.join(unityRoot, "AIWork", ".runtime", "codedb", "instances");
  const instanceRoot = path.resolve(unityRoot, relativePath.replace(/\\/g, path.sep));
  assertPathInside(instanceRoot, instancesRoot, "CodeDB instance root");
  assertNoSymlinkPath(instanceRoot, instancesRoot, "CodeDB instance root");
  const instanceManifestPath = path.join(instanceRoot, "instance.json");
  const instanceText = readBoundedUtf8File(instanceManifestPath, 128 * 1024, "CodeDB instance manifest");
  const instance = parseStrictFlatJson(instanceText, "CodeDB instance manifest");
  if (instance.schema_version !== 1
      || instance.managed_by !== MANAGED_BY
      || instance.instance_id !== instanceId
      || instance.instance_relative_path !== relativePath
      || instance.project_identity !== createProjectIdentity(unityRoot)
      || instance.state !== "READY"
      || instance.generation_id !== "poc.34"
      || instance.generation_relative_path !== `AIWork/.runtime/codedb/host/generations/${instance.generation_id}`
      || instance.worker_relative_path !== "wrapper/codedb-project-instance-worker.mjs"
      || typeof instance.worker_sha256 !== "string"
      || !/^[0-9a-f]{64}$/.test(instance.worker_sha256)) {
    throw new Error("[CHECK_FAILED] CodeDB instance manifest identity is invalid.");
  }
  const generationRoot = path.resolve(unityRoot, instance.generation_relative_path.replace(/\//g, path.sep));
  const generationsRoot = path.join(unityRoot, "AIWork", ".runtime", "codedb", "host", "generations");
  assertPathInside(generationRoot, generationsRoot, "CodeDB instance generation");
  assertNoSymlinkPath(generationRoot, generationsRoot, "CodeDB instance generation");
  const workerPath = path.resolve(generationRoot, instance.worker_relative_path.replace(/\//g, path.sep));
  assertPathInside(workerPath, generationRoot, "CodeDB instance worker");
  assertNoSymlinkPath(workerPath, generationRoot, "CodeDB instance worker");
  if (getFileSha256(workerPath) !== instance.worker_sha256) {
    throw new Error("[CHECK_FAILED] CodeDB instance worker hash does not match instance.json.");
  }
  process.env.RICE_CODEDB_UNITY_ROOT = unityRoot;
  process.env.RICE_CODEDB_INSTANCE_ROOT = instanceRoot;
  return { instanceId, instanceRoot, instanceRelativePath: relativePath, instanceManifestPath };
}

function resolveMachineProvider() {
  const localAppData = process.env.LOCALAPPDATA;
  if (!localAppData || !path.isAbsolute(localAppData)) {
    throw new Error("[MISSING_PREREQUISITE] Windows LOCALAPPDATA is unavailable, so the CodeDB machine Provider cannot be verified.");
  }
  const localRoot = path.resolve(localAppData);
  const providerRoot = path.join(localRoot, "Rice", "CodeDB", "providers", REQUIRED_PROVIDER.version);
  const manifestPath = path.join(providerRoot, "provider-manifest.json");
  const executablePath = path.join(providerRoot, REQUIRED_PROVIDER.executable);
  assertNoSymlinkPath(providerRoot, localRoot, "CodeDB machine Provider root");
  assertNoSymlinkPath(manifestPath, localRoot, "CodeDB Provider manifest");
  assertNoSymlinkPath(executablePath, localRoot, "CodeDB Provider executable");
  if (!fs.existsSync(providerRoot) || !fs.statSync(providerRoot).isDirectory()
      || !fs.existsSync(manifestPath) || !fs.statSync(manifestPath).isFile()
      || !fs.existsSync(executablePath) || !fs.statSync(executablePath).isFile()) {
    throw new Error("[MISSING_PREREQUISITE] CodeDB Provider 0.5.0-28e3912 is missing under %LOCALAPPDATA%/Rice/CodeDB/providers/0.5.0-28e3912.");
  }
  const realProviderRoot = fs.realpathSync(providerRoot);
  const realManifestPath = fs.realpathSync(manifestPath);
  const realExecutablePath = fs.realpathSync(executablePath);
  assertPathInside(realManifestPath, realProviderRoot, "CodeDB Provider manifest");
  assertPathInside(realExecutablePath, realProviderRoot, "CodeDB Provider executable");

  const manifest = parseStrictFlatJson(
    readStrictUtf8File(realManifestPath, 64 * 1024, "CodeDB Provider manifest"),
    "CodeDB Provider manifest");
  const expectedNames = [
    "schema_version",
    "provider_id",
    "version",
    "commit",
    "executable",
    "sha256",
    "protocol",
    "source",
    "supported_package_min_inclusive",
    "supported_package_max_exclusive"
  ];
  if (Object.keys(manifest).length !== expectedNames.length
      || Object.keys(manifest).some((name) => !expectedNames.includes(name))) {
    throw new Error("[MISSING_PREREQUISITE] CodeDB Provider manifest properties do not match schema 1.");
  }
  const identityCurrent = manifest.schema_version === REQUIRED_PROVIDER.schemaVersion
    && manifest.provider_id === REQUIRED_PROVIDER.providerId
    && manifest.version === REQUIRED_PROVIDER.version
    && manifest.commit === REQUIRED_PROVIDER.commit
    && manifest.executable === REQUIRED_PROVIDER.executable
    && manifest.protocol === REQUIRED_PROVIDER.protocol
    && manifest.source === REQUIRED_PROVIDER.source
    && manifest.supported_package_min_inclusive === REQUIRED_PROVIDER.packageMinInclusive
    && manifest.supported_package_max_exclusive === REQUIRED_PROVIDER.packageMaxExclusive
    && PACKAGE_VERSION === REQUIRED_PROVIDER.packageMinInclusive;
  if (!identityCurrent) {
    throw new Error("[MISSING_PREREQUISITE] The installed CodeDB Provider identity, protocol, or Package range is incompatible.");
  }
  if (typeof manifest.sha256 !== "string" || !/^[0-9a-f]{64}$/.test(manifest.sha256)) {
    throw new Error("[MISSING_PREREQUISITE] CodeDB Provider manifest sha256 is invalid.");
  }
  const actualSha256 = crypto.createHash("sha256").update(fs.readFileSync(realExecutablePath)).digest("hex");
  if (actualSha256 !== manifest.sha256) {
    throw new Error("[MISSING_PREREQUISITE] The installed CodeDB Provider hash does not match its manifest.");
  }
  return { root: realProviderRoot, manifestPath: realManifestPath, executablePath: realExecutablePath };
}

function readStrictUtf8File(filePath, maximumBytes, label) {
  const bytes = fs.readFileSync(filePath);
  if (bytes.length <= 0 || bytes.length > maximumBytes) {
    throw new Error(`[MISSING_PREREQUISITE] ${label} size is outside the accepted range.`);
  }
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) {
    throw new Error(`[MISSING_PREREQUISITE] ${label} must be UTF-8 without a byte-order mark.`);
  }
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch (error) {
    throw new Error(`[MISSING_PREREQUISITE] ${label} is not strict UTF-8: ${error.message}`);
  }
}

function parseStrictFlatJson(text, label) {
  let index = 0;
  const value = Object.create(null);
  const skipWhitespace = () => {
    while (index < text.length && (text[index] === " " || text[index] === "\t" || text[index] === "\r" || text[index] === "\n")) {
      index += 1;
    }
  };
  const readString = () => {
    if (text[index] !== "\"") {
      throw new Error(`[MISSING_PREREQUISITE] ${label} expected a JSON string at character ${index}.`);
    }
    const start = index;
    index += 1;
    let escaped = false;
    while (index < text.length) {
      const character = text[index];
      if (character.charCodeAt(0) < 0x20) {
        throw new Error(`[MISSING_PREREQUISITE] ${label} contains a control character in a JSON string.`);
      }
      index += 1;
      if (escaped) {
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === "\"") {
        try {
          const decoded = JSON.parse(text.slice(start, index));
          if (typeof decoded !== "string") {
            throw new Error("decoded token is not a string");
          }
          return decoded;
        } catch (error) {
          throw new Error(`[MISSING_PREREQUISITE] ${label} contains an invalid JSON string: ${error.message}`);
        }
      }
    }
    throw new Error(`[MISSING_PREREQUISITE] ${label} contains an unterminated JSON string.`);
  };

  skipWhitespace();
  if (text[index] !== "{") {
    throw new Error(`[MISSING_PREREQUISITE] ${label} must contain one JSON object.`);
  }
  index += 1;
  skipWhitespace();
  if (text[index] === "}") {
    index += 1;
  } else {
    while (index < text.length) {
      const name = readString();
      if (Object.prototype.hasOwnProperty.call(value, name)) {
        throw new Error(`[MISSING_PREREQUISITE] ${label} contains duplicate property: ${name}`);
      }
      skipWhitespace();
      if (text[index] !== ":") {
        throw new Error(`[MISSING_PREREQUISITE] ${label} expected : after property ${name}.`);
      }
      index += 1;
      skipWhitespace();
      if (text[index] === "\"") {
        value[name] = readString();
      } else {
        const match = text.slice(index).match(/^-?(?:0|[1-9][0-9]*)/);
        if (!match) {
          throw new Error(`[MISSING_PREREQUISITE] ${label} property ${name} must be a JSON string or signed integer.`);
        }
        const integer = Number(match[0]);
        if (!Number.isSafeInteger(integer)) {
          throw new Error(`[MISSING_PREREQUISITE] ${label} property ${name} is outside the safe integer range.`);
        }
        value[name] = integer;
        index += match[0].length;
      }
      skipWhitespace();
      if (text[index] === "}") {
        index += 1;
        break;
      }
      if (text[index] !== ",") {
        throw new Error(`[MISSING_PREREQUISITE] ${label} expected , between properties.`);
      }
      index += 1;
      skipWhitespace();
    }
  }
  skipWhitespace();
  if (index !== text.length) {
    throw new Error(`[MISSING_PREREQUISITE] ${label} contains trailing JSON content.`);
  }
  return value;
}

function assertNoSymlinkPath(filePath, rootPath, label) {
  const resolvedRoot = path.resolve(rootPath);
  let current = path.resolve(filePath);
  assertPathInside(current, resolvedRoot, label);
  while (true) {
    if (fs.existsSync(current) && fs.lstatSync(current).isSymbolicLink()) {
      throw new Error(`[MISSING_PREREQUISITE] ${label} traverses a symbolic link or junction: ${current}`);
    }
    if (current === resolvedRoot) {
      return;
    }
    const parent = path.dirname(current);
    if (parent === current) {
      throw new Error(`[MISSING_PREREQUISITE] ${label} could not be validated inside the machine Provider root.`);
    }
    current = parent;
  }
}

function tryResolveCurrentGeneration() {
  try {
    return resolveCurrentGeneration();
  } catch {
    return null;
  }
}

function resolveCurrentGeneration() {
  const pointerPath = baseContext.currentGenerationPointerPath;
  const pointerText = readBoundedUtf8File(pointerPath, 64 * 1024, "CodeDB generation pointer");
  const pointerIdentity = crypto.createHash("sha256").update(pointerText, "utf8").digest("hex");
  if (generationCache?.pointerIdentity === pointerIdentity) {
    return generationCache;
  }

  let pointer;
  try {
    pointer = JSON.parse(pointerText);
  } catch (error) {
    throw new Error(`[CHECK_FAILED] CodeDB generation pointer is invalid JSON: ${error.message}`);
  }
  const generationId = String(pointer?.generation_id ?? "");
  const generationRelativePath = normalizeRelativePath(pointer?.generation_relative_path);
  const expectedRelativePath = `AIWork/.runtime/codedb/host/generations/${generationId}`;
  const valid = pointer?.schema_version === 1
    && pointer?.managed_by === MANAGED_BY
    && Number.isInteger(pointer?.payload_sequence)
    && pointer.payload_sequence > 0
    && typeof pointer?.package_version === "string"
    && typeof pointer?.payload_version === "string"
    && /^[A-Za-z0-9._-]{1,64}$/.test(generationId)
    && pointer?.bootstrap_protocol === BOOTSTRAP_PROTOCOL
    && generationRelativePath === expectedRelativePath
    && /^[0-9a-f]{64}$/.test(String(pointer?.generation_manifest_sha256 ?? ""));
  if (!valid) {
    throw new Error("[CHECK_FAILED] CodeDB generation pointer identity or bootstrap protocol is invalid.");
  }

  const generationRoot = path.resolve(baseContext.unityRoot, generationRelativePath.replace(/\//g, path.sep));
  const generationsRoot = path.join(baseContext.hostRuntimeRoot, "generations");
  assertPathInside(generationRoot, generationsRoot, "CodeDB generation");
  if (!fs.existsSync(generationRoot) || !fs.statSync(generationRoot).isDirectory()) {
    throw new Error(`[CHECK_FAILED] Selected CodeDB generation is missing: ${generationRelativePath}`);
  }
  const realGenerationRoot = fs.realpathSync(generationRoot);
  assertPathInside(realGenerationRoot, fs.realpathSync(generationsRoot), "CodeDB resolved generation");

  const manifestPath = path.join(realGenerationRoot, "generation-manifest.json");
  const manifestText = readBoundedUtf8File(manifestPath, 1024 * 1024, "CodeDB generation manifest");
  const manifestSha256 = crypto.createHash("sha256").update(manifestText, "utf8").digest("hex");
  if (manifestSha256 !== pointer.generation_manifest_sha256) {
    throw new Error("[CHECK_FAILED] Selected CodeDB generation manifest hash does not match current.json.");
  }
  let manifest;
  try {
    manifest = JSON.parse(manifestText);
  } catch (error) {
    throw new Error(`[CHECK_FAILED] CodeDB generation manifest is invalid JSON: ${error.message}`);
  }
  const manifestValid = manifest?.schema_version === 1
    && manifest?.managed_by === MANAGED_BY
    && manifest?.generation_id === generationId
    && manifest?.package_version === pointer.package_version
    && manifest?.payload_version === pointer.payload_version
    && manifest?.payload_sequence === pointer.payload_sequence
    && manifest?.bootstrap_protocol === BOOTSTRAP_PROTOCOL
    && Array.isArray(manifest?.files)
    && manifest.files.length > 0;
  if (!manifestValid) {
    throw new Error("[CHECK_FAILED] CodeDB generation manifest identity does not match current.json.");
  }
  verifyGenerationFiles(realGenerationRoot, manifest.files);

  generationCache = {
    pointerIdentity,
    generationId,
    generationRoot: realGenerationRoot,
    packageVersion: pointer.package_version,
    payloadVersion: pointer.payload_version,
    payloadSequence: pointer.payload_sequence,
    bootstrapProtocol: pointer.bootstrap_protocol,
    generationManifestSha256: manifestSha256,
    adapterBuilderPath: path.join(realGenerationRoot, "scripts", "build-codedb-project-text-adapter.ps1"),
    adapterWorkerPath: path.join(realGenerationRoot, "scripts", "run-codedb-project-text-adapter-worker.ps1")
  };
  return generationCache;
}

function verifyGenerationFiles(generationRoot, files) {
  const seen = new Set();
  for (const entry of files) {
    const relativePath = normalizeRelativePath(entry?.path);
    const expectedHash = String(entry?.sha256 ?? "");
    if (!relativePath || relativePath === "." || seen.has(relativePath) || !/^[0-9a-f]{64}$/.test(expectedHash)) {
      throw new Error("[CHECK_FAILED] CodeDB generation manifest contains an invalid or duplicate file entry.");
    }
    seen.add(relativePath);
    const filePath = path.resolve(generationRoot, relativePath.replace(/\//g, path.sep));
    assertPathInside(filePath, generationRoot, "CodeDB generation file");
    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      throw new Error(`[CHECK_FAILED] CodeDB generation file is missing: ${relativePath}`);
    }
    const realPath = fs.realpathSync(filePath);
    assertPathInside(realPath, generationRoot, "CodeDB resolved generation file");
    const actualHash = crypto.createHash("sha256").update(fs.readFileSync(realPath)).digest("hex");
    if (actualHash !== expectedHash) {
      throw new Error(`[CHECK_FAILED] CodeDB generation file hash mismatch: ${relativePath}`);
    }
  }
}

function readBoundedUtf8File(filePath, maximumBytes, label) {
  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    throw new Error(`[HOST_NOT_READY] ${label} is missing: ${toUnityRelativePath(filePath)}`);
  }
  const stat = fs.statSync(filePath);
  if (stat.size <= 0 || stat.size > maximumBytes) {
    throw new Error(`[CHECK_FAILED] ${label} size is invalid.`);
  }
  return fs.readFileSync(filePath, "utf8");
}

function acquireInstanceLifetimeLease() {
  const retiringPath = path.join(baseContext.instanceRoot, "retiring.json");
  assertPathInside(retiringPath, baseContext.instanceRoot, "CodeDB instance retirement marker");
  assertInstanceNotRetiring(retiringPath);
  const leaseRoot = path.join(baseContext.instanceRoot, "leases");
  assertPathInside(leaseRoot, baseContext.instanceRoot, "CodeDB instance lease");
  fs.mkdirSync(leaseRoot, { recursive: true });
  const leaseId = `mcp-${process.pid}-${crypto.randomUUID().replace(/-/g, "")}`;
  const leasePath = path.join(leaseRoot, `${leaseId}.json`);
  const createdAt = new Date().toISOString();
  const lease = {
    schema_version: 1,
    instance_lease_version: 1,
    managed_by: MANAGED_BY,
    project_identity: baseContext.projectIdentity,
    instance_id: baseContext.instanceId,
    generation_id: "poc.34",
    lease_id: leaseId,
    owner: "mcp",
    pid: process.pid,
    process_start_identity: String(Math.max(0, Math.round(Date.now() - process.uptime() * 1000))),
    project_root: baseContext.unityRoot,
    created_at_utc: createdAt,
    heartbeat_at_utc: createdAt
  };
  publishGenerationLease(leasePath, lease, true);
  try {
    assertInstanceNotRetiring(retiringPath);
  } catch (error) {
    fs.rmSync(leasePath, { force: true });
    removeEmptyDirectory(leaseRoot);
    removeEmptyDirectory(baseContext.instanceRoot);
    throw error;
  }
  let released = false;
  const heartbeat = setInterval(() => {
    if (released) return;
    lease.heartbeat_at_utc = new Date().toISOString();
    try { publishGenerationLease(leasePath, lease, false); }
    catch { /* Cleanup treats unreadable live evidence as retained. */ }
  }, GENERATION_HEARTBEAT_INTERVAL_MS);
  heartbeat.unref();
  const release = () => {
    if (released) return;
    released = true;
    clearInterval(heartbeat);
    try { fs.rmSync(leasePath, { force: true }); }
    catch { /* A failed cleanup is safe; retirement remains pending. */ }
    removeEmptyDirectory(leaseRoot);
  };
  process.once("exit", release);
  return { release };
}

function assertInstanceNotRetiring(instanceMarkerPath) {
  const retiredControlRoot = path.join(
    baseContext.unityRoot,
    "AIWork",
    ".runtime",
    "codedb",
    "control",
    "retired-instances"
  );
  const retiredControlPath = path.join(retiredControlRoot, baseContext.instanceId + ".json");
  assertPathInside(retiredControlPath, retiredControlRoot, "CodeDB retired instance control marker");
  if (fs.existsSync(retiredControlPath)) {
    assertNoSymlinkPath(retiredControlPath, retiredControlRoot, "CodeDB retired instance control marker");
    throw new Error("[HOST_UPDATING] The selected CodeDB instance is retired and cannot accept a new MCP owner.");
  }
  if (fs.existsSync(instanceMarkerPath)) {
    assertNoSymlinkPath(instanceMarkerPath, baseContext.instanceRoot, "CodeDB instance retirement marker");
    throw new Error("[HOST_UPDATING] The selected CodeDB instance is retiring and cannot accept a new MCP owner.");
  }
}

function acquireGenerationRequestLease(generationId) {
  const materializerMarker = path.join(baseContext.unityRoot, "AIWork", ".runtime", "codedb", "payload-materializer", "materialize-active.json");
  assertDestructiveMaterializerInactive(materializerMarker);
  const leasesRoot = path.join(baseContext.hostRuntimeRoot, "leases");
  const leaseRoot = path.join(leasesRoot, generationId);
  assertPathInside(leaseRoot, baseContext.hostRuntimeRoot, "CodeDB request lease");
  fs.mkdirSync(leaseRoot, { recursive: true });

  const leaseId = `mcp-${process.pid}-${crypto.randomUUID().replace(/-/g, "")}`;
  const leasePath = path.join(leaseRoot, `${leaseId}.json`);
  const createdAt = new Date().toISOString();
  const lease = {
    schema_version: 2,
    generation_lease_version: GENERATION_LEASE_VERSION,
    managed_by: MANAGED_BY,
    generation_id: generationId,
    lease_id: leaseId,
    owner: "mcp",
    pid: process.pid,
    process_start_identity: String(Math.max(0, Math.round(Date.now() - process.uptime() * 1000))),
    project_root: baseContext.unityRoot,
    created_at_utc: createdAt,
    heartbeat_at_utc: createdAt
  };
  publishGenerationLease(leasePath, lease, true);
  try {
    assertDestructiveMaterializerInactive(materializerMarker);
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
      publishGenerationLease(leasePath, lease, false);
    } catch {
      // Strict host mutation treats an unreadable live lease as a blocker.
    }
  }, GENERATION_HEARTBEAT_INTERVAL_MS);
  heartbeat.unref();
  return {
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

function acquirePinnedGenerationRequest() {
  for (let attempt = 0; attempt < GENERATION_PIN_ATTEMPTS; attempt += 1) {
    const generation = resolveCurrentGeneration();
    const lease = acquireGenerationRequestLease(generation.generationId);
    let selected;
    try {
      selected = resolveCurrentGeneration();
    } catch (error) {
      lease.release();
      throw error;
    }
    if (selected.pointerIdentity === generation.pointerIdentity) {
      return { generation, lease };
    }
    lease.release();
  }
  throw new Error("[HOST_UPDATING] CodeDB selected generation changed repeatedly while publishing a request lease.");
}

function publishGenerationLease(leasePath, lease, createNew) {
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
    if (marker?.managed_by === MANAGED_BY && marker?.action === "upgrade") {
      return;
    }
  } catch {
    // Invalid materializer state remains a fail-closed blocker.
  }
  throw new Error(`[HOST_UPDATING] CodeDB host payload mutation is active: ${activeMarkerPath}`);
}

function removeEmptyDirectory(directoryPath) {
  try {
    fs.rmdirSync(directoryPath);
  } catch {
    // Another request or watcher still owns this directory.
  }
}

function resolveWrapperUnityRoot(rootAssertion) {
  const requestedRoot = rootAssertion === undefined
    ? (process.env.RICE_CODEDB_UNITY_ROOT || process.cwd())
    : path.resolve(process.cwd(), rootAssertion);
  return assertCodedbUnityProjectRoot(requestedRoot);
}

function assertCodedbUnityProjectRoot(unityRoot) {
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
  for (const marker of ["Assets", "Packages", "ProjectSettings"]) {
    const markerPath = path.join(root, marker);
    if (!fs.existsSync(markerPath) || !fs.statSync(markerPath).isDirectory()) {
      throw new Error(`Invalid Unity project root ${root}: missing ${marker} directory.`);
    }
  }
  return root;
}

function createProjectSlug(value) {
  const normalizedValue = String(value ?? "").normalize("NFC");
  let result = "";
  let previousWasSeparator = false;
  let containsNonAscii = false;
  for (const character of normalizedValue) {
    if (character.codePointAt(0) > 0x7f) {
      containsNonAscii = true;
    }
    if (/^[A-Za-z0-9]$/.test(character)) {
      result += character.toLowerCase();
      previousWasSeparator = false;
      continue;
    }

    if (previousWasSeparator || result.length === 0) {
      continue;
    }

    result += "-";
    previousWasSeparator = true;
  }

  result = result.replace(/-+$/, "") || "unity-project";
  let requiresHash = containsNonAscii;
  if (result.length > 96) {
    result = result.slice(0, 96).replace(/-+$/, "");
    requiresHash = true;
  }
  if (requiresHash) {
    const hash = crypto.createHash("sha256").update(normalizedValue, "utf8").digest("hex");
    result = `${result}-${hash.slice(0, 12)}`;
  }
  return result;
}

function createProjectIdentity(rootPath) {
  const canonical = normalizeAbsolutePath(rootPath).replace(/\/+$/, "");
  return `sha256:${crypto.createHash("sha256").update(canonical, "utf8").digest("hex")}`;
}

function getFileSha256(filePath) {
  return crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
}

function parseArgs(args) {
  const options = {};
  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === "--root") {
      if (index + 1 >= args.length) {
        throw new Error("--root requires a path assertion.");
      }
      if (options.root !== undefined) {
        throw new Error("--root may be specified only once.");
      }
      options.root = args[index + 1];
      index += 1;
    } else if (arg === "--print-context") {
      options.printContext = true;
    } else if (arg === "--instance-root") {
      if (index + 1 >= args.length || options.instanceRoot !== undefined) {
        throw new Error("--instance-root must be supplied once with one path.");
      }
      options.instanceRoot = args[++index];
    } else {
      throw new Error(`Unsupported CodeDB instance worker argument: ${arg}`);
    }
  }

  return options;
}

function handleMessageLine(line) {
  let message;
  try {
    message = JSON.parse(line);
  } catch (error) {
    writeLog(`Invalid JSON-RPC input: ${error.message}`);
    return;
  }

  if (!message || typeof message !== "object") {
    return;
  }

  if (message.id === undefined || message.id === null) {
    if (message.method === "notifications/initialized") {
      return;
    }

    return;
  }

  Promise.resolve()
    .then(() => handleRequest(message))
    .then((result) => {
      sendResponse({ jsonrpc: "2.0", id: message.id, result });
    })
    .catch((error) => {
      sendResponse({
        jsonrpc: "2.0",
        id: message.id,
        error: {
          code: -32000,
          message: limitOutputText(error.message || String(error))
        }
      });
    });
}

async function handleRequest(message) {
  switch (message.method) {
    case "initialize":
      return {
        protocolVersion: message.params?.protocolVersion ?? "2024-11-05",
        capabilities: {
          tools: {}
        },
        serverInfo: {
          name: "codedb-project-wrapper",
          version: "0.2.3"
        }
      };
    case "tools/list":
      return { tools };
    case "tools/call":
      return callTool(message.params ?? {});
    case "ping":
      return {};
    default:
      throw new Error(`Unsupported method: ${message.method}`);
  }
}

async function callTool(params) {
  const name = params.name;
  const args = normalizeArgs(params.arguments ?? {});
  const timing = createToolTiming(name);

  try {
    const pinned = acquirePinnedGenerationRequest();
    return await requestGenerationStorage.run(pinned.generation, async () => {
      try {
        let text;
        switch (name) {
          case "codedb_status":
            text = await getStatusText();
            break;
          case "codedb_search":
          case "codedb_text_search":
          case "codedb_find":
            text = await routeSearchTool(name, args, timing);
            break;
          case "codedb_read":
            text = routeReadTool(args, timing);
            break;
          case "codedb_context":
            text = await routeContextTool(args, timing);
            break;
          default:
            throw new Error(`Unsupported tool: ${name}`);
        }
        return toToolResult(text, false, timing);
      } finally {
        pinned.lease.release();
      }
    });
  } catch (error) {
    throw new Error(formatTimedOutput(error.message || String(error), timing));
  }
}

function toToolResult(text, isError = false, timing = null) {
  return {
    content: [
      {
        type: "text",
        text: timing ? formatTimedOutput(text, timing) : limitOutputText(text)
      }
    ],
    isError
  };
}

function normalizeArgs(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }

  return { ...value };
}

function createToolTiming(tool) {
  return {
    tool,
    startedAt: performance.now(),
    queueMs: 0,
    providerProcessMs: 0,
    providerCoreMs: null,
    adapterMs: 0,
    mergeMs: 0,
    readMs: 0,
    providerAttempts: 0,
    providerRoute: "none",
    providerShared: false
  };
}

function measureToolPhase(timing, field, action) {
  const startedAt = performance.now();
  try {
    return action();
  } finally {
    timing[field] += performance.now() - startedAt;
  }
}

function parseProviderCoreTiming(stderr) {
  const pattern = /codebase-mcp timing total:\s*([0-9]+(?:\.[0-9]+)?)s/gi;
  let match;
  let totalMs = null;
  while ((match = pattern.exec(String(stderr ?? ""))) !== null) {
    totalMs = Number.parseFloat(match[1]) * 1000;
  }
  return Number.isFinite(totalMs) ? totalMs : null;
}

function formatTimedOutput(value, timing) {
  const text = String(value ?? "");
  const metrics = {
    schema_version: 1,
    tool: timing.tool,
    total_ms: roundMilliseconds(performance.now() - timing.startedAt),
    queue_ms: roundMilliseconds(timing.queueMs),
    provider_process_ms: roundMilliseconds(timing.providerProcessMs),
    provider_core_ms: timing.providerCoreMs === null ? null : roundMilliseconds(timing.providerCoreMs),
    adapter_ms: roundMilliseconds(timing.adapterMs),
    merge_ms: roundMilliseconds(timing.mergeMs),
    read_ms: roundMilliseconds(timing.readMs),
    provider_attempts: timing.providerAttempts,
    provider_route: timing.providerRoute,
    provider_shared: timing.providerShared,
    output_bytes: Buffer.byteLength(text, "utf8")
  };
  return limitOutputText(text, `[TIMING] ${JSON.stringify(metrics)}`);
}

function roundMilliseconds(value) {
  return Math.round(Math.max(0, Number(value) || 0) * 100) / 100;
}

async function routeSearchTool(name, rawArgs, timing) {
  const args = normalizeSearchArgs(rawArgs);
  const query = getQueryText(args);
  const limit = getLimit(args.limit);
  if (!query) {
    return `[NO HIT] ${name} requires a query.`;
  }

  if (isExcludedScope(args.path_glob)) {
    return `[NO HIT] excluded path scope: ${args.path_glob}`;
  }

  const result = await collectUnifiedSearchEntries(name, args, limit, timing);
  return formatUnifiedSearchResult(name, query, result);
}

function routeReadTool(args, timing) {
  const targetPath = normalizeRelativePath(args.path);
  if (!targetPath) {
    throw new Error("codedb_read requires a relative path.");
  }

  if (isExcludedScope(targetPath)) {
    return `[NO HIT] excluded path scope: ${targetPath}`;
  }

  if (isAdapterPath(targetPath) || isShaderLanguage(args.language)) {
    return measureToolPhase(timing, "readMs", () => formatAdapterRead(targetPath, args));
  }

  return measureToolPhase(timing, "readMs", () => formatProjectRead(targetPath, args));
}

async function routeContextTool(rawArgs, timing) {
  const args = normalizeSearchArgs(rawArgs);
  const query = getQueryText(args);
  const limit = Math.min(getLimit(args.limit), 5);
  if (!query) {
    return "[NO HIT] codedb_context requires a query.";
  }

  if (isExcludedScope(args.path_glob)) {
    return `[NO HIT] excluded path scope: ${args.path_glob}`;
  }

  const search = await collectUnifiedSearchEntries("codedb_text_search", args, limit, timing);
  if (search.entries.length === 0) {
    return [...search.diagnostics, `[NO HIT] CodeDB context found no match for: ${query}`]
      .filter(Boolean)
      .join("\n");
  }

  const sections = [...search.diagnostics];
  for (const entry of search.entries) {
    const line = Math.max(1, entry.startLine ?? 1);
    const label = isAdapterPath(entry.path) ? "Shader adapter" : "CodeDB";
    try {
      sections.push(measureToolPhase(timing, "readMs", () => formatLocalRead(entry.path, {
          start_line: Math.max(1, line - 3),
          end_line: line + 5
        }, label)));
    } catch (error) {
      sections.push(`[READ ERROR] ${entry.path}: ${error.message}`);
    }
  }
  if (search.hasMore) {
    sections.push(`[LIMIT] Global context result limit ${limit} applied; additional hits were omitted.`);
  }
  return sections.filter(Boolean).join("\n\n");
}

function resolveSearchLanes(args) {
  if (isShaderLanguage(args.language) || hasAdapterPathScope(args)) {
    return { provider: false, adapter: true };
  }
  if (args.language || hasNonAdapterFileScope(args)) {
    return { provider: true, adapter: false };
  }
  return { provider: true, adapter: true };
}

function hasAdapterPathScope(args) {
  return isAdapterPath(args.path_glob);
}

function hasNonAdapterFileScope(args) {
  const scope = normalizeRelativePath(args.path_glob);
  if (!scope) {
    return false;
  }
  const extension = path.posix.extname(scope).toLowerCase();
  return Boolean(extension) && !ADAPTER_EXTENSIONS.has(extension);
}

function isShaderLanguage(language) {
  if (!language) {
    return false;
  }

  const normalized = String(language).replace(/[-_\s/]/g, "").toLowerCase();
  return normalized === "shaderhlsl"
    || normalized === "shader"
    || normalized === "hlsl"
    || normalized === "compute"
    || normalized === "cginc";
}

function isAdapterPath(value) {
  const relativePath = normalizeRelativePath(value);
  if (!relativePath) {
    return false;
  }

  const extension = path.posix.extname(relativePath).toLowerCase();
  return ADAPTER_EXTENSIONS.has(extension);
}

function isExcludedScope(value) {
  const relativePath = normalizeRelativePath(value);
  if (!relativePath) {
    return false;
  }

  const trimmed = stripGlob(relativePath);
  for (const prefix of EXCLUDED_PREFIXES) {
    if (trimmed.toLowerCase().startsWith(prefix.toLowerCase())) {
      return true;
    }
  }

  const wrapped = `/${trimmed}`;
  return EXCLUDED_FRAGMENTS.some((fragment) => wrapped.toLowerCase().includes(fragment.toLowerCase()));
}

function stripGlob(value) {
  const index = value.search(/[*?{[]/);
  if (index < 0) {
    return value;
  }

  return value.slice(0, index);
}

function getQueryText(args) {
  const query = args.query ?? args.pattern ?? args.symbol ?? args.name ?? "";
  return String(query).trim();
}

function getLimit(value) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return 20;
  }

  return Math.min(parsed, MAX_LIMIT);
}

function normalizeSearchArgs(args) {
  const normalized = { ...args };
  const pathScope = normalizeSearchScope(args.path);
  const globScope = normalizeSearchScope(args.path_glob);
  if (pathScope && globScope && pathScope.toLowerCase() !== globScope.toLowerCase()) {
    throw new Error("Search scope aliases path and path_glob disagree.");
  }

  delete normalized.path;
  if (pathScope || globScope) {
    normalized.path_glob = pathScope || globScope;
  } else {
    delete normalized.path_glob;
  }
  normalized.limit = getLimit(args.limit);
  return normalized;
}

function normalizeSearchScope(value) {
  const relativePath = normalizeRelativePath(value);
  if (!relativePath) {
    return "";
  }
  if (relativePath === ".") {
    return "**";
  }
  if (/[*?{[]/.test(relativePath)) {
    return relativePath;
  }

  const fullPath = resolveUnityPath(relativePath);
  assertPathInside(fullPath, context.unityRoot, "Search scope");
  if (fs.existsSync(fullPath)) {
    const realRoot = fs.realpathSync(context.unityRoot);
    const realPath = fs.realpathSync(fullPath);
    assertPathInside(realPath, realRoot, "Search scope resolved");
    if (fs.statSync(realPath).isDirectory()) {
      return `${relativePath.replace(/\/$/, "")}/**`;
    }
    return relativePath;
  }

  if (relativePath.endsWith("/") || !path.posix.extname(relativePath)) {
    return `${relativePath.replace(/\/$/, "")}/**`;
  }
  return relativePath;
}

function stripWrapperOnlyArgs(args) {
  const clone = { ...args };
  delete clone.language;
  return clone;
}

async function collectUnifiedSearchEntries(name, args, limit, timing) {
  const lanes = resolveSearchLanes(args);
  const diagnostics = [];
  const candidates = [];
  let providerReportedTotal = 0;
  let providerParsedCount = 0;

  if (lanes.provider) {
    try {
      const providerOutput = await invokeProviderTool(name, stripWrapperOnlyArgs(args), timing);
      const parsed = parseProviderSearchOutput(name, providerOutput);
      diagnostics.push(...parsed.diagnostics);
      candidates.push(...parsed.entries);
      providerReportedTotal = parsed.reportedTotal;
      providerParsedCount = parsed.entries.length;
    } catch (error) {
      if (!lanes.adapter) {
        throw error;
      }
      diagnostics.push(`[PROVIDER ERROR] ${error.message}`);
    }
  }

  let adapterMayHaveMore = false;
  if (lanes.adapter) {
    try {
      const adapterFetchLimit = Math.min(MAX_LIMIT, limit + 1);
      const matches = measureToolPhase(
        timing,
        "adapterMs",
        () => findAdapterMatches(getQueryText(args), args, adapterFetchLimit));
      adapterMayHaveMore = limit < MAX_LIMIT && matches.length > limit;
      for (const match of matches) {
        candidates.push({
          path: match.path,
          startLine: match.line,
          endLine: match.line,
          text: match.text,
          lanes: ["shader-adapter"]
        });
      }
    } catch (error) {
      if (!lanes.provider) {
        throw error;
      }
      diagnostics.push(`[SHADER ADAPTER ERROR] ${error.message}`);
    }
  }

  const mergeStartedAt = performance.now();
  const scoped = candidates.filter((entry) => {
    if (!entry.path || isExcludedScope(entry.path)) {
      return false;
    }
    return !args.path_glob || matchesGlob(entry.path, args.path_glob);
  });
  const deduplicated = mergeSearchEntries(name, scoped);
  timing.mergeMs += performance.now() - mergeStartedAt;
  const hasMore = deduplicated.length > limit
    || adapterMayHaveMore
    || providerReportedTotal > providerParsedCount;
  return {
    diagnostics,
    entries: deduplicated.slice(0, limit),
    hasMore,
    limit
  };
}

function parseProviderSearchOutput(name, output) {
  const lines = String(output ?? "").split(/\r?\n/);
  const entries = [];
  const diagnostics = [];
  let reportedTotal = 0;
  let currentPath = "";
  let currentChunk = null;

  for (const rawLine of lines) {
    const line = rawLine.trimEnd();
    if (!line.trim()) {
      currentChunk = null;
      continue;
    }

    const totalMatch = line.match(/^\s*(\d+)\s+results?\b/i);
    if (totalMatch) {
      reportedTotal = Math.max(reportedTotal, Number.parseInt(totalMatch[1], 10));
      currentChunk = null;
      continue;
    }

    if (line.startsWith("[FIXTURE PROVIDER]")) {
      diagnostics.push(line);
      continue;
    }

    const normalizedHit = line.match(/^\[HIT\]\s+(.+?):(\d+)(?:-(\d+))?(?:\s+(.*))?$/i);
    if (normalizedHit) {
      const entry = createSearchEntry(
        normalizedHit[1],
        Number.parseInt(normalizedHit[2], 10),
        Number.parseInt(normalizedHit[3] ?? normalizedHit[2], 10),
        normalizedHit[4] ?? "",
        "provider"
      );
      if (entry) {
        entries.push(entry);
      }
      currentChunk = null;
      continue;
    }

    if (name === "codedb_text_search") {
      const sourceLine = line.match(/^\s+L(\d+):\s?(.*)$/);
      if (sourceLine && currentPath) {
        const entry = createSearchEntry(
          currentPath,
          Number.parseInt(sourceLine[1], 10),
          Number.parseInt(sourceLine[1], 10),
          sourceLine[2],
          "provider"
        );
        if (entry) {
          entries.push(entry);
        }
        continue;
      }

      const pathLine = line.match(/^\s{2}([^\s].*)$/);
      if (pathLine && isProjectSourcePath(pathLine[1])) {
        currentPath = pathLine[1].trim();
      }
      continue;
    }

    if (name === "codedb_search") {
      const chunkLine = line.match(/^\s{2}(.+):(\d+)-(\d+)\s+\[score=[^\]]+\]\s*$/i);
      if (chunkLine) {
        currentChunk = createSearchEntry(
          chunkLine[1],
          Number.parseInt(chunkLine[2], 10),
          Number.parseInt(chunkLine[3], 10),
          "",
          "provider"
        );
        if (currentChunk) {
          entries.push(currentChunk);
        }
        continue;
      }
      if (currentChunk && /^\s{4}/.test(rawLine)) {
        currentChunk.text = currentChunk.text
          ? `${currentChunk.text}\n${rawLine.trim()}`
          : rawLine.trim();
      }
      continue;
    }

    if (name === "codedb_find") {
      const findLine = line.match(/^\s*\d+\.\s+(.+?)(?:\s+\(score:[^)]+\))?\s*$/i);
      if (findLine) {
        const entry = createSearchEntry(findLine[1], null, null, "", "provider");
        if (entry) {
          entries.push(entry);
        }
      }
    }
  }

  return {
    entries,
    diagnostics,
    reportedTotal: Math.max(reportedTotal, entries.length)
  };
}

function createSearchEntry(rawPath, startLine, endLine, text, lane) {
  let relativePath;
  try {
    relativePath = normalizeRelativePath(rawPath);
  } catch {
    return null;
  }
  if (!isProjectSourcePath(relativePath)) {
    return null;
  }
  return {
    path: relativePath,
    startLine: Number.isInteger(startLine) && startLine > 0 ? startLine : null,
    endLine: Number.isInteger(endLine) && endLine > 0 ? endLine : null,
    text: String(text ?? "").trim(),
    lanes: [lane]
  };
}

function isProjectSourcePath(value) {
  try {
    const relativePath = normalizeRelativePath(value);
    return /^(Assets|Packages|ProjectSettings)\//i.test(relativePath);
  } catch {
    return false;
  }
}

function mergeSearchEntries(name, entries) {
  const merged = [];
  for (const entry of entries) {
    const existing = merged.find((candidate) => searchEntriesOverlap(name, candidate, entry));
    if (!existing) {
      merged.push({ ...entry, lanes: [...entry.lanes] });
      continue;
    }
    for (const lane of entry.lanes) {
      if (!existing.lanes.includes(lane)) {
        existing.lanes.push(lane);
      }
    }
    if (!existing.text && entry.text) {
      existing.text = entry.text;
    }
  }
  return merged;
}

function searchEntriesOverlap(name, left, right) {
  if (left.path.toLowerCase() !== right.path.toLowerCase()) {
    return false;
  }
  if (name === "codedb_find") {
    return true;
  }
  if (name === "codedb_text_search") {
    return left.startLine === right.startLine;
  }
  if (left.startLine === null || right.startLine === null) {
    return true;
  }
  const leftEnd = left.endLine ?? left.startLine;
  const rightEnd = right.endLine ?? right.startLine;
  return left.startLine <= rightEnd && right.startLine <= leftEnd;
}

function formatUnifiedSearchResult(name, query, result) {
  const lines = [...result.diagnostics];
  if (result.entries.length === 0) {
    lines.push(`[NO HIT] ${name} found no match for: ${query}`);
    return lines.join("\n");
  }

  lines.push(`[OK] ${name} found ${result.entries.length} unique hit(s) for: ${query}`);
  for (const entry of result.entries) {
    const location = formatSearchLocation(entry);
    lines.push(`[HIT] ${location} [${entry.lanes.join("+")}]`);
    if (entry.text) {
      for (const textLine of entry.text.split(/\r?\n/)) {
        lines.push(`    ${textLine}`);
      }
    }
  }
  if (result.hasMore) {
    lines.push(`[LIMIT] Global result limit ${result.limit} applied; additional hits were omitted.`);
  }
  return lines.join("\n");
}

function formatSearchLocation(entry) {
  if (!entry.startLine) {
    return entry.path;
  }
  if (entry.endLine && entry.endLine !== entry.startLine) {
    return `${entry.path}:${entry.startLine}-${entry.endLine}`;
  }
  return `${entry.path}:${entry.startLine}`;
}

async function invokeProviderTool(name, args, timing) {
  const lifecycle = await readEffectiveLifecycle();
  const readyState = getReadyWatchCoordinatorState(lifecycle);
  if (!readyState) {
    throw createLifecycleUnavailableError(lifecycle);
  }

  const response = await requestCoordinatorQuery(readyState, name, args);
  if (response?.ok && response.lifecycle_id === readyState.lifecycle_id) {
    applyCoordinatorTiming(timing, response.timing);
    return String(response.output ?? "");
  }
  if (response?.error_code === "PROVIDER_TOOL_ERROR") {
    throw new Error(response.error ?? `provider tool ${name} failed.`);
  }
  if (response?.ok && response.lifecycle_id !== readyState.lifecycle_id) {
    throw lifecycleError("COORDINATOR_STATE_CHANGED", "CodeDB coordinator lifecycle changed while handling the query.");
  }
  throw lifecycleError(
    response?.error_code ?? "COORDINATOR_UNREACHABLE",
    response?.error ?? "CodeDB coordinator query is unavailable.");
}

function applyCoordinatorTiming(timing, metrics) {
  const value = metrics && typeof metrics === "object" ? metrics : {};
  timing.providerRoute = "coordinator";
  timing.providerShared = value.provider_shared === true;
  timing.queueMs += toNonNegativeNumber(value.queue_ms);
  timing.providerProcessMs += toNonNegativeNumber(value.provider_process_ms);
  if (value.provider_core_ms !== null && value.provider_core_ms !== undefined) {
    timing.providerCoreMs = (timing.providerCoreMs ?? 0) + toNonNegativeNumber(value.provider_core_ms);
  }
  timing.providerAttempts += Math.max(0, Number.parseInt(value.provider_attempts, 10) || 0);
}

function toNonNegativeNumber(value) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.max(0, parsed) : 0;
}

function requestCoordinatorQuery(state, name, args) {
  return requestCoordinatorCommand(state, {
    schema_version: 1,
    auth_token: state?.auth_token,
    command: "query",
    tool: name,
    arguments: args
  }, COORDINATOR_QUERY_TIMEOUT_MS);
}

function requestCoordinatorStatus(state) {
  return requestCoordinatorCommand(state, {
    auth_token: state?.auth_token,
    command: "status"
  }, COORDINATOR_STATUS_TIMEOUT_MS);
}

async function requestCoordinatorCommand(state, request, timeoutMs) {
  if (!state?.pipe_name || !state?.auth_token) {
    return createCoordinatorFailure(
      "COORDINATOR_STATE_INVALID",
      "Coordinator state is missing its authenticated pipe endpoint.",
      state,
      "INVALID_STATE");
  }
  let response = null;
  for (const retryDelayMs of COORDINATOR_CONNECT_RETRY_DELAYS_MS) {
    if (retryDelayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, retryDelayMs));
    }
    response = await requestCoordinatorCommandOnce(state, request, timeoutMs);
    if (response?.transport_retryable !== true) {
      return response;
    }
  }
  return response;
}

function requestCoordinatorCommandOnce(state, request, timeoutMs) {
  return new Promise((resolve) => {
    const socket = net.createConnection(state.pipe_name);
    let settled = false;
    let buffer = "";
    const finish = (value) => {
      if (settled) {
        return;
      }
      settled = true;
      clearTimeout(timer);
      socket.destroy();
      resolve(value);
    };
    const timer = setTimeout(() => finish(createCoordinatorFailure(
      "COORDINATOR_TIMEOUT",
      "Timed out waiting for the coordinator response.",
      state,
      "TIMEOUT")), timeoutMs);
    socket.setEncoding("utf8");
    socket.on("connect", () => {
      socket.write(`${JSON.stringify(request)}\n`);
    });
    socket.on("data", (chunk) => {
      buffer += chunk;
      if (Buffer.byteLength(buffer, "utf8") > MAX_COORDINATOR_RESPONSE_BYTES) {
        finish(createCoordinatorFailure(
          "COORDINATOR_PROTOCOL_ERROR",
          "Coordinator response exceeded the bounded response limit.",
          state,
          "RESPONSE_TOO_LARGE"));
        return;
      }
      const newline = buffer.indexOf("\n");
      if (newline < 0) {
        return;
      }
      try {
        finish(JSON.parse(buffer.slice(0, newline)));
      } catch {
        finish(createCoordinatorFailure(
          "COORDINATOR_PROTOCOL_ERROR",
          "Coordinator returned invalid JSON.",
          state,
          "INVALID_JSON"));
      }
    });
    socket.on("error", (error) => finish(createCoordinatorFailure(
      "COORDINATOR_UNREACHABLE",
      "Could not connect to the Ready coordinator pipe.",
      state,
      error?.code ?? "UNKNOWN",
      COORDINATOR_RETRYABLE_TRANSPORT_CODES.has(error?.code))));
    socket.on("end", () => {
      if (!settled && buffer.trim()) {
        try {
          finish(JSON.parse(buffer.trim()));
        } catch {
          finish(createCoordinatorFailure(
            "COORDINATOR_PROTOCOL_ERROR",
            "Coordinator closed with an invalid JSON response.",
            state,
            "INVALID_JSON"));
        }
      } else if (!settled) {
        finish(createCoordinatorFailure(
          "COORDINATOR_UNREACHABLE",
          "Coordinator closed without a response.",
          state,
          "CONNECTION_CLOSED",
          true));
      }
    });
  });
}

function createCoordinatorFailure(errorCode, message, state, transportCode, retryable = false) {
  const stateTimestampMs = Date.parse(state?.last_lease_scan_at_utc ?? state?.provider_ready_at_utc ?? state?.started_at_utc ?? "");
  const stateAgeMs = Number.isFinite(stateTimestampMs) ? Math.max(0, Date.now() - stateTimestampMs) : null;
  const pipeValue = String(state?.pipe_name ?? "");
  const pipeId = pipeValue
    ? `sha256-${crypto.createHash("sha256").update(pipeValue, "utf8").digest("hex").slice(0, 12)}`
    : "unknown";
  const diagnostics = [
    `transport_code=${sanitizeDiagnosticToken(transportCode)}`,
    `pipe_id=${sanitizeDiagnosticToken(pipeId)}`,
    `lifecycle_id=${sanitizeDiagnosticToken(state?.lifecycle_id)}`,
    `state_age_ms=${stateAgeMs ?? "unknown"}`
  ].join(", ");
  return {
    ok: false,
    error_code: errorCode,
    error: `${message} (${diagnostics}).`,
    transport_retryable: retryable
  };
}

function sanitizeDiagnosticToken(value) {
  return String(value ?? "unknown").replace(/[^A-Za-z0-9._-]/g, "_").slice(0, 128) || "unknown";
}

function getReadyWatchCoordinatorState(lifecycle) {
  if (lifecycle.desiredState !== "enabled" || !lifecycle.editorOnline) {
    return null;
  }
  const state = readWatchCoordinatorState();
  if (!state) {
    return null;
  }
  const commonReady = state.schema_version === 2
    && state.provider_state === "ready"
    && state.desired_state === "enabled"
    && state.editor_demand === "online"
    && Number(state.editor_session_count) > 0
    && state.adapter_enabled === true
    && ADAPTER_OPERATIONAL_STATES.has(state.adapter_state)
    && normalizeAbsolutePath(state.root) === normalizeAbsolutePath(context.unityRoot)
    && normalizeAbsolutePath(state.provider_executable) === normalizeAbsolutePath(context.providerExecutablePath)
    && normalizeAbsolutePath(state.provider_config) === normalizeAbsolutePath(context.watchConfigPath)
    && normalizeAbsolutePath(state.runtime) === normalizeAbsolutePath(context.watchCoordinatorRuntimePath)
    && normalizeAbsolutePath(state.adapter_manifest) === normalizeAbsolutePath(context.textAdapterManifestPath)
    && Number(state.adapter_debounce_ms) > 0
    && state.adapter_worker_state === "ready"
    && processMayBeAlive(state.coordinator_pid)
    && processMayBeAlive(state.provider_pid)
    && processMayBeAlive(state.adapter_worker_pid);
  if (!commonReady) {
    return null;
  }

  const aliasesMatch = normalizeAbsolutePath(state.adapter_builder) === normalizeAbsolutePath(context.legacyAdapterBuilderPath)
    && normalizeAbsolutePath(state.adapter_worker) === normalizeAbsolutePath(context.legacyAdapterWorkerPath);
  const currentGeneration = state.generation_id === context.generationId
    && aliasesMatch
    && normalizeAbsolutePath(state.generation_adapter_builder) === normalizeAbsolutePath(context.adapterBuilderPath)
    && normalizeAbsolutePath(state.generation_adapter_worker) === normalizeAbsolutePath(context.adapterWorkerPath);
  if (currentGeneration) {
    return { ...state, watcher_generation: context.generationId, watcher_generation_mode: "current" };
  }

  const legacyGeneration = (state.generation_id === undefined || state.generation_id === null)
    && aliasesMatch
    && (state.generation_adapter_builder === undefined || state.generation_adapter_builder === null)
    && (state.generation_adapter_worker === undefined || state.generation_adapter_worker === null)
    && countLegacyMcpSessions() > 0;
  return legacyGeneration
    ? { ...state, watcher_generation: "poc.21", watcher_generation_mode: "legacy-draining" }
    : null;
}

function readWatchCoordinatorState() {
  if (!fs.existsSync(context.watchCoordinatorStatePath)) {
    return null;
  }
  try {
    return JSON.parse(fs.readFileSync(context.watchCoordinatorStatePath, "utf8"));
  } catch {
    return null;
  }
}

function readDesiredState() {
  try {
    const document = JSON.parse(fs.readFileSync(context.desiredStatePath, "utf8"));
    const valid = document?.schema_version === 1
      && document?.managed_by === "com.rice.ai-codedb"
      && (document?.desired_state === "enabled" || document?.desired_state === "disabled")
      && normalizeAbsolutePath(document?.project_root) === normalizeAbsolutePath(context.unityRoot)
      && document?.project_identity === context.projectIdentity;
    return valid ? document : null;
  } catch {
    return null;
  }
}

async function readEffectiveLifecycle() {
  const policyState = readDesiredState()?.desired_state ?? "unknown";
  const activeSessionIds = await readActiveEditorSessionIds();
  const manualMode = readManualRuntimeMode(activeSessionIds);
  const desiredState = manualMode === "started"
    ? "enabled"
    : (manualMode === "stopped" ? "disabled" : policyState);
  return {
    policyState,
    manualMode,
    desiredState,
    editorOnline: activeSessionIds.size > 0
  };
}

function readManualRuntimeMode(activeSessionIds) {
  try {
    const document = JSON.parse(fs.readFileSync(context.manualRuntimePath, "utf8"));
    const sessionIds = Array.isArray(document?.editor_session_ids) ? document.editor_session_ids : [];
    const valid = document?.schema_version === 1
      && document?.managed_by === MANAGED_BY
      && (document?.mode === "started" || document?.mode === "stopped")
      && normalizeAbsolutePath(document?.project_root) === normalizeAbsolutePath(context.unityRoot)
      && document?.project_identity === context.projectIdentity
      && sessionIds.length > 0
      && sessionIds.every((value) => typeof value === "string" && /^[A-Za-z0-9._-]{1,128}$/.test(value));
    if (!valid || !sessionIds.some((sessionId) => activeSessionIds.has(sessionId))) {
      return "none";
    }
    return document.mode;
  } catch {
    return "none";
  }
}

async function readActiveEditorSessionIds() {
  let names;
  try {
    names = fs.readdirSync(context.editorLeaseRoot);
  } catch {
    return new Set();
  }

  const now = Date.now();
  const candidates = [];
  for (const name of names) {
    if (!name.toLowerCase().endsWith(".json")) {
      continue;
    }
    try {
      const lease = JSON.parse(fs.readFileSync(path.join(context.editorLeaseRoot, name), "utf8"));
      const heartbeatMs = Date.parse(lease?.heartbeat_at_utc ?? "");
      const createdMs = Date.parse(lease?.created_at_utc ?? "");
      const pid = Number(lease?.editor_pid);
      const valid = lease?.schema_version === 1
        && lease?.managed_by === "com.rice.ai-codedb"
        && typeof lease?.session_id === "string"
        && /^[A-Za-z0-9._-]{1,128}$/.test(lease.session_id)
        && `${lease?.session_id}.json` === name
        && Number.isInteger(pid)
        && pid > 0
        && typeof lease?.process_start_ticks === "string"
        && /^[0-9]+$/.test(lease.process_start_ticks)
        && normalizeAbsolutePath(lease?.project_root) === normalizeAbsolutePath(context.unityRoot)
        && lease?.project_identity === context.projectIdentity
        && Number.isFinite(createdMs)
        && Number.isFinite(heartbeatMs)
        && createdMs <= heartbeatMs
        && heartbeatMs <= now + 30000
        && now - heartbeatMs <= EDITOR_LEASE_STALE_AFTER_MS;
      if (valid) {
        candidates.push({ lease, pid, heartbeatMs });
      }
    } catch {
      // The coordinator owns malformed/stale lease reclamation.
    }
  }

  const processSnapshot = await getProcessStartTicks(candidates
    .filter((candidate) => now - candidate.heartbeatMs > EDITOR_LEASE_PROCESS_IDENTITY_RECHECK_AFTER_MS)
    .map((candidate) => candidate.pid));
  const sessionIds = new Set();
  for (const candidate of candidates) {
    if (processSnapshot.available && processSnapshot.starts.has(candidate.pid)) {
      if (processSnapshot.starts.get(candidate.pid) !== candidate.lease.process_start_ticks) {
        continue;
      }
    } else if (!processMayBeAlive(candidate.pid)) {
      continue;
    }
    sessionIds.add(candidate.lease.session_id);
  }
  return sessionIds;
}

async function getProcessStartTicks(processIds) {
  const ids = [...new Set(processIds
    .map(Number)
    .filter((value) => Number.isInteger(value) && value > 0))];
  const starts = new Map();
  if (ids.length === 0) {
    return { available: true, starts };
  }
  if (process.platform !== "win32") {
    return { available: false, starts };
  }

  const script = `$rows = foreach ($id in @(${ids.join(",")})) { try { $p = Get-Process -Id $id -ErrorAction Stop; [pscustomobject]@{ pid = [int]$p.Id; start_ticks = $p.StartTime.ToUniversalTime().Ticks.ToString([System.Globalization.CultureInfo]::InvariantCulture) } } catch {} }; ConvertTo-Json -Compress -InputObject @($rows)`;
  const command = await new Promise((resolve) => {
    execFile("powershell.exe", ["-NoProfile", "-NonInteractive", "-NoLogo", "-Command", script], {
      encoding: "utf8",
      windowsHide: true,
      timeout: PROCESS_SNAPSHOT_TIMEOUT_MS,
      maxBuffer: PROCESS_SNAPSHOT_MAX_BYTES
    }, (error, stdout) => resolve({ error, stdout: stdout ?? "" }));
  });
  if (command.error || !command.stdout.trim()) {
    return { available: false, starts };
  }

  try {
    const rows = JSON.parse(command.stdout.trim());
    for (const row of Array.isArray(rows) ? rows : [rows]) {
      const pid = Number(row?.pid);
      if (Number.isInteger(pid)
          && pid > 0
          && typeof row?.start_ticks === "string"
          && /^[0-9]+$/.test(row.start_ticks)) {
        starts.set(pid, row.start_ticks);
      }
    }
  } catch {
    return { available: false, starts: new Map() };
  }
  return { available: true, starts };
}

function countLegacyMcpSessions() {
  const leaseRoot = path.join(
    baseContext.unityRoot,
    "AIWork",
    ".runtime",
    "codedb",
    "payload-materializer",
    "host-use-leases"
  );
  let names;
  try {
    names = fs.readdirSync(leaseRoot);
  } catch {
    return 0;
  }
  let count = 0;
  for (const name of names) {
    const match = /^mcp-([0-9]+)-[0-9a-f]{32}\.json$/i.exec(name);
    if (match && processMayBeAlive(Number(match[1]))) {
      count += 1;
    }
  }
  return count;
}

function lifecycleError(code, message) {
  return new Error(`[${code}] ${message}`);
}

function createLifecycleUnavailableError(lifecycle) {
  if (lifecycle.desiredState === "disabled") {
    const message = lifecycle.manualMode === "stopped"
      ? "CodeDB is stopped for the current Unity Editor session."
      : "CodeDB is disabled for this Unity project.";
    const code = lifecycle.manualMode === "stopped" ? "MANUAL_STOPPED" : "SERVICE_DISABLED";
    return lifecycleError(code, message);
  }
  if (!lifecycle.editorOnline) {
    return lifecycleError("EDITOR_OFFLINE", "No interactive Unity Editor session is online for this project.");
  }
  return lifecycleError("STARTING", "CodeDB is enabled and the Unity Editor is online, but the backend is not ready yet.");
}

function processMayBeAlive(pid) {
  return probeProcess(pid) !== "missing";
}

function probeProcess(pid) {
  const numericPid = Number(pid);
  if (!Number.isInteger(numericPid) || numericPid <= 0) {
    return "missing";
  }
  try {
    process.kill(numericPid, 0);
    return "alive";
  } catch (error) {
    return ["ENOENT", "ESRCH"].includes(error?.code) ? "missing" : "indeterminate";
  }
}

function normalizeAbsolutePath(value) {
  return path.resolve(String(value ?? "")).replace(/^\\\\\?\\/, "").replace(/\\/g, "/").toLowerCase();
}

async function getStatusText() {
  const watchState = readWatchCoordinatorState();
  const lifecycle = await readEffectiveLifecycle();
  const desiredState = lifecycle.desiredState;
  const editorOnline = lifecycle.editorOnline;
  const readyState = getReadyWatchCoordinatorState(lifecycle);
  const coordinatorResponse = readyState ? await requestCoordinatorStatus(readyState) : null;
  const coordinatorReady = coordinatorResponse?.ok === true
    && coordinatorResponse?.status?.lifecycle_id === readyState?.lifecycle_id;
  const coordinatorUnreachable = readyState !== null && !coordinatorReady;
  let automaticRefreshState;
  let reasonCode;
  if (lifecycle.manualMode === "stopped") {
    automaticRefreshState = "manual_stopped";
    reasonCode = "MANUAL_STOPPED";
  } else if (desiredState === "disabled") {
    automaticRefreshState = "disabled";
    reasonCode = "SERVICE_DISABLED";
  } else if (!editorOnline) {
    automaticRefreshState = "editor_offline";
    reasonCode = "EDITOR_OFFLINE";
  } else if (coordinatorReady) {
    automaticRefreshState = "active";
    reasonCode = "READY";
  } else if (coordinatorUnreachable) {
    automaticRefreshState = "unreachable";
    reasonCode = "COORDINATOR_UNREACHABLE";
  } else {
    automaticRefreshState = "starting";
    reasonCode = "STARTING";
  }
  const watcherGeneration = readyState?.watcher_generation
    ?? (watchState?.generation_id || (watchState ? "poc.21" : "none"));
  const watcherGenerationMode = readyState?.watcher_generation_mode
    ?? (watchState ? (watchState.generation_id ? "not-ready" : "legacy-not-ready") : "stopped");
  const lines = [
    `[OK] ${context.providerName} wrapper ready.`,
    `Package version: ${context.packageVersion}`,
    `Selected generation: ${context.generationId}`,
    `Payload sequence: ${context.payloadSequence}`,
    `Bootstrap protocol: ${context.bootstrapProtocol}`,
    `Generation manifest: ${context.generationManifestSha256}`,
    `Legacy sessions: ${countLegacyMcpSessions()}`,
    `Unity root: ${toUnityRelativePath(context.unityRoot)}`,
    `Provider executable: ${fileState(context.providerExecutablePath)}`,
    `Provider config: ${fileState(context.providerConfigPath)}`,
    `Policy state: ${lifecycle.policyState}`,
    `Manual runtime: ${lifecycle.manualMode}`,
    `Desired state: ${desiredState}`,
    `Editor demand: ${editorOnline ? "online" : "offline"}`,
    `Automatic refresh: ${automaticRefreshState}`,
    `Lifecycle reason: ${reasonCode}`,
    `Watch config: ${fileState(context.watchConfigPath)}`,
    `Watch coordinator: ${coordinatorReady ? "ready" : (coordinatorUnreachable ? "unreachable" : "stopped")}`,
    `Watcher generation: ${watcherGeneration} (${watcherGenerationMode})`,
    `Shader watcher: ${watchState?.adapter_state ?? "stopped"}`,
    `Active provider config: ${coordinatorReady ? toUnityRelativePath(context.watchConfigPath) : "none"}`,
    `Provider index: ${fileState(context.providerIndexRoot)}`,
    `Shader adapter manifest: ${fileState(context.textAdapterManifestPath)}`,
    "Tool profile: Discover Read only"
  ];

  if (watchState?.adapter_last_error) {
    lines.push(`[WARN] Shader watcher last error: ${watchState.adapter_last_error}`);
  }
  if (coordinatorUnreachable && coordinatorResponse?.error) {
    lines.push(`Coordinator diagnostic: ${coordinatorResponse.error}`);
  }

  if (fs.existsSync(context.textAdapterManifestPath)) {
    try {
      const manifest = JSON.parse(fs.readFileSync(context.textAdapterManifestPath, "utf8"));
      lines.push(`Shader adapter files: ${manifest.fileCount ?? "unknown"}`);
      lines.push(`Shader adapter lines: ${manifest.lineCount ?? "unknown"}`);
    } catch (error) {
      lines.push(`[WARN] Shader adapter manifest parse failed: ${error.message}`);
    }
  }

  return lines.join("\n");
}

function fileState(filePath) {
  return fs.existsSync(filePath) ? "present" : "missing";
}

function findAdapterMatches(query, args, limit) {
  assertFileExists(context.textAdapterIndexPath, "Shader adapter index");

  const pathGlob = normalizeRelativePath(args.path_glob ?? args.path);
  const useRegex = Boolean(args.regex);
  const regex = useRegex ? new RegExp(query, "i") : null;
  const records = fs.readFileSync(context.textAdapterIndexPath, "utf8").split(/\r?\n/);
  const matches = [];

  for (const line of records) {
    if (!line.trim()) {
      continue;
    }

    const entry = JSON.parse(line);
    const entryPath = normalizeRelativePath(entry.path);
    if (!entryPath || isExcludedScope(entryPath)) {
      continue;
    }

    if (pathGlob && !matchesGlob(entryPath, pathGlob)) {
      continue;
    }

    const text = getAdapterLineText(entry);
    const matched = useRegex ? regex.test(text) : text.toLowerCase().includes(query.toLowerCase());
    if (!matched) {
      continue;
    }

    matches.push({
      path: entryPath,
      line: Number.parseInt(entry.line, 10),
      text
    });

    if (matches.length >= limit) {
      break;
    }
  }

  return matches;
}

function getAdapterLineText(entry) {
  if (entry.textBase64) {
    return Buffer.from(String(entry.textBase64), "base64").toString("utf8");
  }

  return String(entry.text ?? "");
}

function formatAdapterRead(targetPath, args) {
  const relativePath = normalizeRelativePath(targetPath);
  if (!relativePath) {
    throw new Error("Shader adapter read requires a relative path.");
  }

  if (!isAdapterPath(relativePath)) {
    throw new Error(`Shader adapter read only supports ${Array.from(ADAPTER_EXTENSIONS).join(", ")} files.`);
  }

  if (isExcludedScope(relativePath)) {
    return `[NO HIT] excluded path scope: ${relativePath}`;
  }

  return formatLocalRead(relativePath, args, "Shader adapter");
}

function formatProjectRead(targetPath, args) {
  const relativePath = normalizeRelativePath(targetPath);
  if (!relativePath) {
    throw new Error("CodeDB read requires a relative path.");
  }

  if (isExcludedScope(relativePath)) {
    return `[NO HIT] excluded path scope: ${relativePath}`;
  }

  return formatLocalRead(relativePath, args, "CodeDB");
}

function formatLocalRead(relativePath, args, label) {
  const fullPath = resolveUnityPath(relativePath);
  assertPathInside(fullPath, context.unityRoot, `${label} read`);
  assertFileExists(fullPath, `${label} source`);

  const realRoot = fs.realpathSync(context.unityRoot);
  const realPath = fs.realpathSync(fullPath);
  assertPathInside(realPath, realRoot, `${label} read resolved`);
  if (!fs.statSync(realPath).isFile()) {
    throw new Error(`${label} read target is not a file: ${relativePath}`);
  }

  const source = fs.readFileSync(realPath);
  if (source.includes(0)) {
    throw new Error(`${label} read does not support binary files: ${relativePath}`);
  }

  const lines = source.toString("utf8").split(/\r\n|\n|\r/);
  const window = resolveReadWindow(args, lines.length);
  if (window.start > lines.length) {
    return `[NO HIT] ${label} read ${relativePath}: requested start line ${window.start} exceeds ${lines.length} line(s).`;
  }

  const output = [`[OK] ${label} read ${relativePath} lines ${window.start}-${window.end}.`, `[HIT] ${relativePath}:${window.start}`];
  if (window.wasCapped) {
    output.push(`[LIMIT] Read window capped at ${MAX_READ_LINES} lines; requested end line was ${window.requestedEnd}.`);
  }
  for (let lineNumber = window.start; lineNumber <= window.end; lineNumber += 1) {
    output.push(`${String(lineNumber).padStart(5, " ")}: ${lines[lineNumber - 1] ?? ""}`);
  }

  return output.join("\n");
}

function resolveReadWindow(args, totalLines) {
  const start = getAliasedPositiveInteger(args, "start_line", "startLine", 1);
  const requestedEnd = getAliasedPositiveInteger(args, "end_line", "endLine", start + 8);
  if (requestedEnd < start) {
    throw new Error("codedb_read end_line must be greater than or equal to start_line.");
  }

  const maximumEnd = start + MAX_READ_LINES - 1;
  return {
    start,
    end: Math.min(requestedEnd, maximumEnd, totalLines),
    requestedEnd,
    wasCapped: requestedEnd > maximumEnd
  };
}

function getAliasedPositiveInteger(args, snakeName, camelName, defaultValue) {
  const snakeValue = args[snakeName];
  const camelValue = args[camelName];
  if (snakeValue !== undefined && camelValue !== undefined && Number(snakeValue) !== Number(camelValue)) {
    throw new Error(`codedb_read ${snakeName} and ${camelName} disagree.`);
  }

  const value = snakeValue ?? camelValue;
  if (value === undefined || value === null || value === "") {
    return defaultValue;
  }

  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error(`codedb_read ${snakeName} must be a positive integer.`);
  }
  return parsed;
}

function limitOutputText(value, suffix = "") {
  const text = String(value ?? "");
  const suffixText = suffix ? `${text ? "\n" : ""}${suffix}` : "";
  const combined = `${text}${suffixText}`;
  const combinedBytes = Buffer.from(combined, "utf8");
  if (combinedBytes.length <= MAX_OUTPUT_BYTES) {
    return combined;
  }

  const notice = `\n[TRUNCATED] Wrapper output exceeded ${MAX_OUTPUT_BYTES} UTF-8 bytes.`;
  const trailer = `${notice}${suffix ? `\n${suffix}` : ""}`;
  const bytes = Buffer.from(text, "utf8");
  const budget = Math.max(0, MAX_OUTPUT_BYTES - Buffer.byteLength(trailer, "utf8"));
  let end = budget;
  while (end > 0 && (bytes[end] & 0xc0) === 0x80) {
    end -= 1;
  }
  const prefix = bytes.subarray(0, end).toString("utf8").trimEnd();
  return `${prefix}${trailer}`;
}

function normalizeRelativePath(value) {
  if (value === undefined || value === null) {
    return "";
  }

  const text = String(value).trim().replace(/\\/g, "/");
  if (!text || text === ".") {
    return text;
  }

  if (path.isAbsolute(text) || text.includes("\0")) {
    throw new Error(`Expected Unity-root-relative path, got: ${text}`);
  }

  const normalized = path.posix.normalize(text);
  if (normalized === ".." || normalized.startsWith("../")) {
    throw new Error(`Path escapes Unity root: ${text}`);
  }

  return normalized;
}

function resolveUnityPath(relativePath) {
  return path.resolve(context.unityRoot, relativePath.replace(/\//g, path.sep));
}

function toUnityRelativePath(filePath) {
  const relativePath = path.relative(context.unityRoot, filePath).replace(/\\/g, "/");
  return relativePath || ".";
}

function assertPathInside(filePath, rootPath, label) {
  const resolvedPath = path.resolve(filePath);
  const resolvedRoot = path.resolve(rootPath);
  const relativePath = path.relative(resolvedRoot, resolvedPath);
  if (relativePath === "") {
    return;
  }
  if (relativePath === ".." || relativePath.startsWith(`..${path.sep}`) || path.isAbsolute(relativePath)) {
    throw new Error(`${label} path is outside Unity root: ${resolvedPath}`);
  }
}

function assertFileExists(filePath, label) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Missing ${label}: ${toUnityRelativePath(filePath)}`);
  }
}

function matchesGlob(relativePath, glob) {
  if (!glob || glob === "**/*" || glob === "**") {
    return true;
  }

  const normalizedGlob = normalizeRelativePath(glob);
  let regexText = "";
  for (let index = 0; index < normalizedGlob.length; index += 1) {
    const character = normalizedGlob[index];
    if (character === "*" && normalizedGlob[index + 1] === "*") {
      index += 1;
      if (normalizedGlob[index + 1] === "/") {
        index += 1;
        regexText += "(?:.*/)?";
      } else {
        regexText += ".*";
      }
      continue;
    }
    if (character === "*") {
      regexText += "[^/]*";
      continue;
    }
    if (character === "?") {
      regexText += "[^/]";
      continue;
    }
    regexText += character.replace(/[|\\{}()[\]^$+?.]/g, "\\$&");
  }

  return new RegExp(`^${regexText}$`, "i").test(relativePath);
}

function sendResponse(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function writeLog(message) {
  process.stderr.write(`[${context.providerName}-wrapper] ${message}\n`);
}
