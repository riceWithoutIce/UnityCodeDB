#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { performance } from "node:perf_hooks";
import { fileURLToPath } from "node:url";
import {
  acquireCodedbHostUseLease,
  assertCodedbUnityProjectRoot
} from "../shared/codedb-host-use-gate.mjs";

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
const MAX_COORDINATOR_RESPONSE_BYTES = 1024 * 1024;
const EDITOR_LEASE_STALE_AFTER_MS = 90000;
const EDITOR_LEASE_MONITOR_INTERVAL_MS = 2000;
const ADAPTER_OPERATIONAL_STATES = new Set(["watching", "pending", "building"]);

const context = createContext(process.argv.slice(2));
if (context.printContext) {
  process.stdout.write(`${JSON.stringify({
    unity_root: context.unityRoot,
    project_slug: context.projectSlug,
    provider_name: context.providerName,
    runtime_root: path.join("AIWork", ".runtime", "codedb", context.providerName).replace(/\\/g, "/")
  })}\n`);
  process.exit(0);
}

const hostUseLease = acquireCodedbHostUseLease(context.unityRoot, "mcp");
let editorLeaseObserved = hasActiveEditorLease();
const editorLeaseMonitor = setInterval(() => {
  const editorOnline = hasActiveEditorLease();
  if (editorOnline) {
    editorLeaseObserved = true;
  } else if (editorLeaseObserved) {
    process.exit(0);
  }
}, EDITOR_LEASE_MONITOR_INTERVAL_MS);
editorLeaseMonitor.unref();
process.once("exit", () => {
  clearInterval(editorLeaseMonitor);
  hostUseLease.release();
});

const tools = [
  {
    name: "codedb_status",
    description: "Report project-local wrapper, provider, and Shader/HLSL text adapter status.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "codedb_search",
    description: "Search indexed project code through the project CodeDB wrapper.",
    inputSchema: createSearchSchema()
  },
  {
    name: "codedb_text_search",
    description: "Run bounded text search across provider-indexed code and the Shader/HLSL adapter.",
    inputSchema: createSearchSchema()
  },
  {
    name: "codedb_find",
    description: "Find project files or symbols through the project CodeDB wrapper.",
    inputSchema: createSearchSchema()
  },
  {
    name: "codedb_read",
    description: "Read a bounded line range from an indexed project file.",
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
  const projectSlug = createProjectSlug(path.basename(unityRoot));
  const providerName = `codedb-${projectSlug}`;
  const runtimeRoot = path.join(unityRoot, "AIWork", ".runtime", "codedb", providerName);

  return {
    unityRoot,
    projectIdentity: createProjectIdentity(unityRoot),
    projectSlug,
    providerName,
    printContext: options.printContext === true,
    providerExecutablePath: path.join(runtimeRoot, "bin", "codebase-mcp.exe"),
    providerConfigPath: path.join(runtimeRoot, "config", "codedb-mcp.toml"),
    watchConfigPath: path.join(runtimeRoot, "config", "codedb-mcp.watch.toml"),
    desiredStatePath: path.join(runtimeRoot, "watch", "lifecycle", "desired-state.json"),
    editorLeaseRoot: path.join(runtimeRoot, "watch", "lifecycle", "editor-leases"),
    watchCoordinatorRuntimePath: path.join(runtimeRoot, "watch", "coordinator"),
    watchCoordinatorStatePath: path.join(runtimeRoot, "watch", "coordinator", "coordinator-state.json"),
    adapterBuilderPath: path.join(__dirname, "..", "scripts", "build-codedb-project-text-adapter.ps1"),
    adapterWorkerPath: path.join(__dirname, "..", "scripts", "run-codedb-project-text-adapter-worker.ps1"),
    providerIndexRoot: path.join(runtimeRoot, "index"),
    textAdapterRoot: path.join(runtimeRoot, "adapter", "text-index"),
    textAdapterManifestPath: path.join(runtimeRoot, "adapter", "text-index", "manifest.json"),
    textAdapterFilesPath: path.join(runtimeRoot, "adapter", "text-index", "files.jsonl"),
    textAdapterIndexPath: path.join(runtimeRoot, "adapter", "text-index", "index.jsonl")
  };
}

function resolveWrapperUnityRoot(rootAssertion) {
  const wrapperUnityRoot = assertCodedbUnityProjectRoot(path.resolve(__dirname, "..", "..", ".."));
  if (rootAssertion === undefined) {
    return wrapperUnityRoot;
  }

  const assertedRoot = assertCodedbUnityProjectRoot(path.resolve(process.cwd(), rootAssertion));
  if (normalizeAbsolutePath(assertedRoot) !== normalizeAbsolutePath(wrapperUnityRoot)) {
    throw new Error(`--root must match wrapper-owned Unity root ${wrapperUnityRoot}; received ${assertedRoot}.`);
  }

  return wrapperUnityRoot;
}

function createProjectSlug(value) {
  let result = "";
  let previousWasSeparator = false;
  for (const character of String(value ?? "")) {
    if (/^[\p{L}\p{N}]$/u.test(character)) {
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

  return result.replace(/-+$/, "") || "unity-project";
}

function createProjectIdentity(rootPath) {
  const canonical = normalizeAbsolutePath(rootPath).replace(/\/+$/, "");
  return `sha256:${crypto.createHash("sha256").update(canonical, "utf8").digest("hex")}`;
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
          version: "0.2.1"
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
    let text;
    switch (name) {
      case "codedb_status":
        text = getStatusText();
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
  const readyState = getReadyWatchCoordinatorState();
  if (!readyState) {
    throw createLifecycleUnavailableError();
  }

  const response = await requestCoordinatorQuery(readyState, name, args);
  if (response?.ok && response.lifecycle_id === readyState.lifecycle_id) {
    applyCoordinatorTiming(timing, response.timing);
    return String(response.output ?? "");
  }
  if (response?.error_code === "PROVIDER_TOOL_ERROR") {
    throw new Error(response.error ?? `provider tool ${name} failed.`);
  }
  throw lifecycleError("STARTING", response?.error ?? "CodeDB coordinator query is temporarily unavailable.");
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
  if (!state?.pipe_name || !state?.auth_token) {
    return Promise.resolve(null);
  }
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
    const timer = setTimeout(() => finish(null), COORDINATOR_QUERY_TIMEOUT_MS);
    socket.setEncoding("utf8");
    socket.on("connect", () => {
      socket.write(`${JSON.stringify({
        schema_version: 1,
        auth_token: state.auth_token,
        command: "query",
        tool: name,
        arguments: args
      })}\n`);
    });
    socket.on("data", (chunk) => {
      buffer += chunk;
      if (Buffer.byteLength(buffer, "utf8") > MAX_COORDINATOR_RESPONSE_BYTES) {
        finish(null);
        return;
      }
      const newline = buffer.indexOf("\n");
      if (newline < 0) {
        return;
      }
      try {
        finish(JSON.parse(buffer.slice(0, newline)));
      } catch {
        finish(null);
      }
    });
    socket.on("error", () => finish(null));
    socket.on("end", () => {
      if (!settled && buffer.trim()) {
        try {
          finish(JSON.parse(buffer.trim()));
        } catch {
          finish(null);
        }
      }
    });
  });
}

function isWatchCoordinatorReady() {
  return getReadyWatchCoordinatorState() !== null;
}

function getReadyWatchCoordinatorState() {
  const desired = readDesiredState();
  const state = readWatchCoordinatorState();
  if (desired?.desired_state !== "enabled" || !state) {
    return null;
  }
  const ready = state.provider_state === "ready"
    && state.desired_state === "enabled"
    && state.editor_demand === "online"
    && Number(state.editor_session_count) > 0
    && state.adapter_enabled === true
    && ADAPTER_OPERATIONAL_STATES.has(state.adapter_state)
    && normalizeAbsolutePath(state.root) === normalizeAbsolutePath(context.unityRoot)
    && normalizeAbsolutePath(state.provider_executable) === normalizeAbsolutePath(context.providerExecutablePath)
    && normalizeAbsolutePath(state.provider_config) === normalizeAbsolutePath(context.watchConfigPath)
    && normalizeAbsolutePath(state.adapter_builder) === normalizeAbsolutePath(context.adapterBuilderPath)
    && normalizeAbsolutePath(state.adapter_worker) === normalizeAbsolutePath(context.adapterWorkerPath)
    && normalizeAbsolutePath(state.adapter_manifest) === normalizeAbsolutePath(context.textAdapterManifestPath)
    && state.adapter_worker_state === "ready"
    && isProcessAlive(state.coordinator_pid)
    && isProcessAlive(state.provider_pid)
    && isProcessAlive(state.adapter_worker_pid);
  return ready ? state : null;
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

function hasActiveEditorLease() {
  let names;
  try {
    names = fs.readdirSync(context.editorLeaseRoot);
  } catch {
    return false;
  }

  const now = Date.now();
  for (const name of names) {
    if (!name.toLowerCase().endsWith(".json")) {
      continue;
    }
    try {
      const lease = JSON.parse(fs.readFileSync(path.join(context.editorLeaseRoot, name), "utf8"));
      const heartbeatMs = Date.parse(lease?.heartbeat_at_utc ?? "");
      const valid = lease?.schema_version === 1
        && lease?.managed_by === "com.rice.ai-codedb"
        && `${lease?.session_id}.json` === name
        && normalizeAbsolutePath(lease?.project_root) === normalizeAbsolutePath(context.unityRoot)
        && lease?.project_identity === context.projectIdentity
        && Number.isFinite(heartbeatMs)
        && heartbeatMs <= now + 30000
        && now - heartbeatMs <= EDITOR_LEASE_STALE_AFTER_MS
        && isProcessAlive(lease?.editor_pid);
      if (valid) {
        return true;
      }
    } catch {
      // The coordinator owns malformed/stale lease reclamation.
    }
  }
  return false;
}

function lifecycleError(code, message) {
  return new Error(`[${code}] ${message}`);
}

function createLifecycleUnavailableError() {
  const desired = readDesiredState();
  if (desired?.desired_state === "disabled") {
    return lifecycleError("SERVICE_DISABLED", "CodeDB is disabled for this Unity project.");
  }
  if (!hasActiveEditorLease()) {
    return lifecycleError("EDITOR_OFFLINE", "No interactive Unity Editor session is online for this project.");
  }
  return lifecycleError("STARTING", "CodeDB is enabled and the Unity Editor is online, but the backend is not ready yet.");
}

function isProcessAlive(pid) {
  const numericPid = Number(pid);
  if (!Number.isInteger(numericPid) || numericPid <= 0) {
    return false;
  }
  try {
    process.kill(numericPid, 0);
    return true;
  } catch {
    return false;
  }
}

function normalizeAbsolutePath(value) {
  return path.resolve(String(value ?? "")).replace(/^\\\\\?\\/, "").replace(/\\/g, "/").toLowerCase();
}

function getStatusText() {
  const watchState = readWatchCoordinatorState();
  const desiredState = readDesiredState()?.desired_state ?? "unknown";
  const editorOnline = hasActiveEditorLease();
  const coordinatorReady = isWatchCoordinatorReady();
  const automaticRefreshState = desiredState === "disabled"
    ? "disabled"
    : (!editorOnline ? "editor_offline" : (coordinatorReady ? "active" : "starting"));
  const reasonCode = desiredState === "disabled"
    ? "SERVICE_DISABLED"
    : (!editorOnline ? "EDITOR_OFFLINE" : (coordinatorReady ? "READY" : "STARTING"));
  const lines = [
    `[OK] ${context.providerName} wrapper ready.`,
    `Unity root: ${toUnityRelativePath(context.unityRoot)}`,
    `Provider executable: ${fileState(context.providerExecutablePath)}`,
    `Provider config: ${fileState(context.providerConfigPath)}`,
    `Desired state: ${desiredState}`,
    `Editor demand: ${editorOnline ? "online" : "offline"}`,
    `Automatic refresh: ${automaticRefreshState}`,
    `Lifecycle reason: ${reasonCode}`,
    `Watch config: ${fileState(context.watchConfigPath)}`,
    `Watch coordinator: ${coordinatorReady ? "ready" : "stopped"}`,
    `Shader watcher: ${watchState?.adapter_state ?? "stopped"}`,
    `Active provider config: ${coordinatorReady ? toUnityRelativePath(context.watchConfigPath) : "none"}`,
    `Provider index: ${fileState(context.providerIndexRoot)}`,
    `Shader adapter manifest: ${fileState(context.textAdapterManifestPath)}`,
    "Tool profile: Discover Read only"
  ];

  if (watchState?.adapter_last_error) {
    lines.push(`[WARN] Shader watcher last error: ${watchState.adapter_last_error}`);
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
