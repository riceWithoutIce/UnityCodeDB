import fs from "node:fs";
import path from "node:path";
import readline from "node:readline";
import { spawn } from "node:child_process";
import { Worker } from "node:worker_threads";
import { fileURLToPath } from "node:url";

const REQUEST_TIMEOUT_MS = 10_000;
const EXIT_TIMEOUT_MS = 5_000;
const MAX_STDERR_CHARS = 64 * 1024;
const MAX_CANDIDATE_WORKER_BYTES = 4 * 1024 * 1024;
const AVAILABILITY_QUERY = "__RICE_CODEDB_PACKAGE_AVAILABILITY_PROBE__";
const PACKAGE_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const EXPECTED_TOOLS = [
  "codedb_context",
  "codedb_find",
  "codedb_read",
  "codedb_search",
  "codedb_status",
  "codedb_text_search"
];
const EXPECTED_READ_ONLY_ANNOTATIONS = Object.freeze({
  readOnlyHint: true,
  destructiveHint: false,
  idempotentHint: true,
  openWorldHint: false
});

let wrapperWorker = null;
const probeEvidence = createProbeEvidence();

try {
  const options = readProbeOptions(process.argv.slice(2));
  const projectRoot = options.projectRoot;
  const wrapperRelativePath = options.wrapperRelativePath
    ?? path.join("AIWork", "codedb", "wrapper", "codedb-project-wrapper.mjs");
  const wrapperPath = assertOwnedWrapper(
    projectRoot,
    wrapperRelativePath,
    options.instanceRoot);
  process.chdir(projectRoot);
  const result = await probeWrapper(projectRoot, wrapperPath, options.instanceRoot, probeEvidence);
  process.stdout.write(`${JSON.stringify(result)}\n`);
} catch (error) {
  if (wrapperWorker) {
    try {
      await terminateWrapper(wrapperWorker);
    } catch {
      // The worker may have exited between the identity check and termination.
    }
  }
  const detail = error instanceof Error ? error.message : String(error);
  probeEvidence.detail = detail;
  process.stdout.write(`${JSON.stringify(probeEvidence)}\n`);
  process.stderr.write(`${detail}\n`);
  process.exitCode = 1;
}

function createProbeEvidence() {
  return {
    schema_version: 2,
    availability: "UNAVAILABLE",
    server_name: "",
    protocol_version: "",
    tool_names: [],
    wrapper_initialize_callable: false,
    tools_list_callable: false,
    codedb_status_callable: false,
    codedb_status_usable: false,
    codedb_text_search_callable: false,
    status_summary: "",
    detail: "The Package-owned MCP availability probe did not complete."
  };
}

function readProbeOptions(args) {
  let requestedRoot;
  let wrapperRelativePath;
  let instanceRoot;
  for (let index = 0; index < args.length; index += 1) {
    const name = args[index];
    if (index + 1 >= args.length || !name.startsWith("--")) {
      throw new Error("Usage: probe-codedb-mcp-availability.mjs --project-root <UnityProjectRoot> [--wrapper <relative-path> --instance-root <relative-path>]");
    }
    const value = args[++index];
    if (name === "--project-root" && requestedRoot === undefined) requestedRoot = value;
    else if (name === "--wrapper" && wrapperRelativePath === undefined) wrapperRelativePath = value;
    else if (name === "--instance-root" && instanceRoot === undefined) instanceRoot = value;
    else throw new Error(`Unexpected or duplicate probe option: ${name}`);
  }
  if (requestedRoot === undefined || (instanceRoot !== undefined) !== (wrapperRelativePath !== undefined)) {
    throw new Error("Usage: probe-codedb-mcp-availability.mjs --project-root <UnityProjectRoot> [--wrapper <relative-path> --instance-root <relative-path>]");
  }
  const requestedPath = path.resolve(requestedRoot);
  const root = fs.realpathSync(requestedPath);
  if (!fs.statSync(root).isDirectory()) {
    throw new Error(`Invalid Unity project root ${root}: expected a directory.`);
  }
  for (const marker of ["Assets", "ProjectSettings"]) {
    if (!fs.statSync(path.join(root, marker)).isDirectory()) {
      throw new Error(`Invalid Unity project root ${root}: missing ${marker} directory.`);
    }
  }
  return {
    projectRoot: root,
    wrapperRelativePath,
    instanceRoot
  };
}

function assertOwnedWrapper(projectRoot, relativePath, instanceRoot) {
  const normalized = String(relativePath).replace(/\\/g, "/");
  if (path.isAbsolute(normalized) || normalized.includes("\0") || normalized.includes("..")) {
    throw new Error("CodeDB probe wrapper path must be a project-relative path without traversal.");
  }
  const expectedPath = path.resolve(projectRoot, normalized.replace(/\//g, path.sep));
  const actualPath = fs.realpathSync(expectedPath);
  if (!samePath(expectedPath, actualPath)) {
    throw new Error("CodeDB wrapper path contains a symbolic link or reparse-point redirect.");
  }
  if (!fs.statSync(actualPath).isFile()) {
    throw new Error(`CodeDB wrapper is not a file: ${actualPath}`);
  }
  if (instanceRoot !== undefined) {
    const match = /^AIWork\/\.runtime\/codedb\/host\/generations\/([A-Za-z0-9._-]{1,64})\/wrapper\/codedb-project-instance-worker\.mjs$/.exec(normalized);
    const normalizedInstanceRoot = String(instanceRoot).replace(/\\/g, "/");
    if (!match
        || !/^AIWork\/\.runtime\/codedb\/instances\/[0-9a-f]{32}$/i.test(normalizedInstanceRoot)) {
      throw new Error("Candidate probe paths do not match the immutable instance layout.");
    }
    const packageWorkerPath = path.join(
      PACKAGE_ROOT,
      "Payload~",
      "Generations",
      match[1],
      "wrapper",
      "codedb-project-instance-worker.mjs");
    const packageWorker = fs.realpathSync(packageWorkerPath);
    const projectWorkerBytes = fs.readFileSync(actualPath);
    const packageWorkerBytes = fs.readFileSync(packageWorker);
    if (!samePath(packageWorkerPath, packageWorker)
        || !fs.statSync(packageWorker).isFile()
        || projectWorkerBytes.length === 0
        || projectWorkerBytes.length > MAX_CANDIDATE_WORKER_BYTES
        || !projectWorkerBytes.equals(packageWorkerBytes)) {
      throw new Error("Candidate probe only permits an exact Package-owned immutable instance worker.");
    }
  }
  return actualPath;
}

async function probeWrapper(projectRoot, wrapperPath, instanceRoot, evidence) {
  const stderrParts = [];
  let stderrLength = 0;
  let nextId = 1;
  let protocolFailure = null;
  const pending = new Map();
  let resolveWorkerExit;
  const workerExit = new Promise((resolve) => {
    resolveWorkerExit = resolve;
  });

  wrapperWorker = instanceRoot
    ? new Worker(wrapperPath, {
        argv: ["--root", ".", "--instance-root", instanceRoot],
        stdin: true,
        stdout: true,
        stderr: true
      })
    : spawn(process.execPath, [wrapperPath, "--root", "."], {
        cwd: projectRoot,
        stdio: ["pipe", "pipe", "pipe"],
        windowsHide: true
      });

  wrapperWorker.stderr.setEncoding("utf8");
  wrapperWorker.stderr.on("data", (chunk) => {
    if (stderrLength >= MAX_STDERR_CHARS) {
      return;
    }
    const text = String(chunk);
    const remaining = MAX_STDERR_CHARS - stderrLength;
    stderrParts.push(text.slice(0, remaining));
    stderrLength += Math.min(text.length, remaining);
  });

  const lines = readline.createInterface({ input: wrapperWorker.stdout, crlfDelay: Infinity });
  lines.on("line", (line) => {
    if (line.length > 256 * 1024) {
      protocolFailure = new Error("CodeDB wrapper returned an oversized JSON-RPC response.");
      rejectPending(protocolFailure);
      return;
    }
    let message;
    try {
      message = JSON.parse(line);
    } catch (error) {
      protocolFailure = new Error(`CodeDB wrapper returned invalid JSON-RPC: ${error.message}`);
      rejectPending(protocolFailure);
      return;
    }
    const entry = pending.get(message?.id);
    if (!entry) {
      return;
    }
    pending.delete(message.id);
    clearTimeout(entry.timer);
    if (message.error) {
      entry.reject(new Error(`CodeDB wrapper ${entry.method} failed: ${String(message.error.message ?? "unknown error")}`));
    } else {
      entry.resolve(message.result);
    }
  });

  wrapperWorker.once("error", (error) => rejectPending(new Error(`CodeDB wrapper worker could not start: ${error.message}`)));
  wrapperWorker.once("exit", (code) => {
    resolveWorkerExit(code);
    if (pending.size > 0) {
      rejectPending(new Error(`CodeDB wrapper exited during availability probe (code=${code}).`));
    }
  });

  function rejectPending(error) {
    for (const entry of pending.values()) {
      clearTimeout(entry.timer);
      entry.reject(error);
    }
    pending.clear();
  }

  function request(method, params) {
    if (protocolFailure) {
      return Promise.reject(protocolFailure);
    }
    const id = nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error(`CodeDB wrapper ${method} timed out after ${REQUEST_TIMEOUT_MS} ms.`));
      }, REQUEST_TIMEOUT_MS);
      pending.set(id, { method, resolve, reject, timer });
      wrapperWorker.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`);
    });
  }

  const initialized = await request("initialize", {
    protocolVersion: "2025-06-18",
    capabilities: {},
    clientInfo: { name: "rice-ai-codedb-package-probe", version: "1" }
  });
  if (!initialized || initialized.serverInfo?.name !== "codedb-project-wrapper") {
    throw new Error("CodeDB wrapper initialize response has an unexpected server identity.");
  }
  evidence.server_name = initialized.serverInfo.name;
  evidence.protocol_version = String(initialized.protocolVersion ?? "");
  evidence.wrapper_initialize_callable = true;
  wrapperWorker.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", method: "notifications/initialized", params: {} })}\n`);

  const listed = await request("tools/list", {});
  const toolNames = Array.isArray(listed?.tools)
    ? listed.tools.map((tool) => String(tool?.name ?? "")).sort()
    : [];
  if (JSON.stringify(toolNames) !== JSON.stringify(EXPECTED_TOOLS)) {
    throw new Error(`CodeDB wrapper tools/list mismatch: ${toolNames.join(", ") || "none"}.`);
  }
  for (const tool of listed.tools) {
    if (!hasExpectedReadOnlyAnnotations(tool?.annotations)) {
      throw new Error(`CodeDB wrapper tool ${String(tool?.name ?? "<unnamed>")} is missing the required read-only MCP annotations.`);
    }
  }
  evidence.tool_names = toolNames;
  evidence.tools_list_callable = true;

  const status = await request("tools/call", { name: "codedb_status", arguments: {} });
  const statusText = Array.isArray(status?.content)
    ? status.content.filter((item) => item?.type === "text").map((item) => String(item.text ?? "")).join("\n")
    : "";
  if (status?.isError === true || statusText.length === 0) {
    throw new Error("CodeDB wrapper codedb_status was not callable.");
  }
  evidence.codedb_status_callable = true;
  evidence.status_summary = firstNonEmptyLine(statusText);

  const statusLines = new Set(statusText.split(/\r?\n/).map((line) => line.trim()));
  const requiredReadyLines = [
    "Editor demand: online",
    "Automatic refresh: active",
    "Lifecycle reason: READY",
    "Watch coordinator: ready"
  ];
  const missingReadyLines = requiredReadyLines.filter((line) => !statusLines.has(line));
  if (missingReadyLines.length > 0) {
    const observedReason = [...statusLines].find((line) => line.startsWith("Lifecycle reason: "))
      ?? "Lifecycle reason: missing";
    throw new Error(
      `CodeDB wrapper is callable but the project backend is unavailable (${observedReason}): missing ${missingReadyLines.join(", ")}.`
    );
  }
  evidence.codedb_status_usable = true;

  const search = await request("tools/call", {
    name: "codedb_text_search",
    arguments: { query: AVAILABILITY_QUERY, limit: 1 }
  });
  const searchText = Array.isArray(search?.content)
    ? search.content.filter((item) => item?.type === "text").map((item) => String(item.text ?? "")).join("\n")
    : "";
  if (search?.isError === true || searchText.length === 0) {
    throw new Error("CodeDB wrapper codedb_text_search did not complete a bounded project query.");
  }
  evidence.codedb_text_search_callable = true;

  wrapperWorker.stdin.end();
  const exitCode = await waitForExit(wrapperWorker, workerExit, EXIT_TIMEOUT_MS);
  const stderr = stderrParts.join("").trim();
  if (exitCode !== 0) {
    throw new Error(`CodeDB wrapper exited with code ${exitCode}. ${stderr}`.trim());
  }
  wrapperWorker = null;

  evidence.availability = "AVAILABLE";
  evidence.detail = "Project backend READY and bounded codedb_text_search succeeded.";
  return evidence;
}

function hasExpectedReadOnlyAnnotations(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return false;
  }
  return Object.entries(EXPECTED_READ_ONLY_ANNOTATIONS)
    .every(([name, expected]) => value[name] === expected);
}

async function waitForExit(worker, exitPromise, timeoutMs) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(`CodeDB wrapper did not exit after stdin closed (${timeoutMs} ms).`)), timeoutMs);
  });
  try {
    return await Promise.race([exitPromise, timeout]);
  } catch (error) {
    await terminateWrapper(worker);
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

async function terminateWrapper(worker) {
  if (typeof worker.terminate === "function") {
    if (worker.threadId !== -1) await worker.terminate();
    return;
  }
  if (worker.exitCode === null && worker.signalCode === null) {
    worker.kill();
    await new Promise((resolve) => worker.once("exit", resolve));
  }
}

function firstNonEmptyLine(text) {
  return String(text).split(/\r?\n/).find((line) => line.trim().length > 0)?.trim() ?? "";
}

function samePath(left, right) {
  return path.resolve(left).replace(/[\\/]+$/, "").toLowerCase()
    === path.resolve(right).replace(/[\\/]+$/, "").toLowerCase();
}
