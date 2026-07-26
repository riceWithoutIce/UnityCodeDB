#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { performance } from "node:perf_hooks";
import readline from "node:readline";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { acquireCodedbHostUseLease } from "../shared/codedb-host-use-gate.mjs";

const STATE_FILE = "coordinator-state.json";
const LOCK_FILE = "coordinator.lock";
const ERROR_FILE = "coordinator-error.json";
const LOG_FILE = "coordinator.log";
const IPC_TIMEOUT_MS = 1500;
const PROVIDER_REQUEST_TIMEOUT_MS = 90000;
const PROVIDER_STOP_TIMEOUT_MS = 5000;
const MAX_PROVIDER_RESTARTS = 3;
const ADAPTER_STOP_TIMEOUT_MS = 5000;
const ADAPTER_WORKER_START_TIMEOUT_MS = 30000;
const ADAPTER_WORKER_BUILD_TIMEOUT_MS = 120000;
const MAX_ADAPTER_WORKER_RESTARTS = 3;
const DEFAULT_ADAPTER_DEBOUNCE_MS = 750;
const MAX_ADAPTER_OUTPUT_CHARS = 8192;
const MAX_IPC_REQUEST_BYTES = 64 * 1024;
const ADAPTER_WATCH_ROOTS = ["Assets", "Packages", "ProjectSettings"];
const ADAPTER_EXTENSIONS = new Set([".shader", ".hlsl", ".compute", ".cginc"]);
const ADAPTER_OPERATIONAL_STATES = new Set(["watching", "pending", "building"]);
const PROVIDER_QUERY_TOOLS = new Set(["codedb_search", "codedb_text_search", "codedb_find"]);

const { command, options } = parseArgs(process.argv.slice(2));

async function main() {
  try {
    switch (command) {
      case "start":
        await runStart(options);
        break;
      case "status":
        await runStatus(options);
        break;
      case "stop":
        await runStop(options);
        break;
      case "daemon":
        await runDaemon(options);
        break;
      default:
        throw new Error("Usage: codedb-watch-coordinator.mjs <start|status|stop> --runtime <path> [--root <path> --provider <path> --config <path> --adapter-builder <path> --adapter-manifest <path>]");
    }
  } catch (error) {
    if (command === "daemon" && options.runtime) {
      writeDaemonError(path.resolve(options.runtime), error);
    }
    process.stderr.write(`[ERROR] ${error.message}\n`);
    process.exitCode = 1;
  }
}

function parseArgs(args) {
  const parsed = { command: args[0] ?? "", options: {} };
  for (let index = 1; index < args.length; index += 1) {
    const argument = args[index];
    if (!argument.startsWith("--")) {
      throw new Error(`Unexpected argument: ${argument}`);
    }
    const key = argument.slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
    const value = args[index + 1];
    if (value === undefined || value.startsWith("--")) {
      throw new Error(`Missing value for ${argument}`);
    }
    parsed.options[key] = value;
    index += 1;
  }
  return parsed;
}

function buildRuntimeContext(rawOptions) {
  if (!rawOptions.runtime) {
    throw new Error("--runtime is required.");
  }
  const runtime = path.resolve(rawOptions.runtime);
  return {
    runtime,
    statePath: path.join(runtime, STATE_FILE),
    lockPath: path.join(runtime, LOCK_FILE),
    errorPath: path.join(runtime, ERROR_FILE),
    logPath: path.join(runtime, LOG_FILE)
  };
}

function buildLaunchContext(rawOptions) {
  const context = buildRuntimeContext(rawOptions);
  for (const key of ["root", "provider", "config"]) {
    if (!rawOptions[key]) {
      throw new Error(`--${key} is required for ${command}.`);
    }
  }

  context.root = path.resolve(rawOptions.root);
  context.provider = path.resolve(rawOptions.provider);
  context.config = path.resolve(rawOptions.config);
  context.startupTimeoutMs = parsePositiveInteger(rawOptions.startupTimeoutMs, 30000);
  context.lifecycleId = parseLifecycleId(rawOptions.lifecycleId);
  context.requireNew = parseBoolean(rawOptions.requireNew, false);
  context.exclusiveLifecycle = parseBoolean(rawOptions.exclusiveLifecycle, false);
  if ((context.requireNew || context.exclusiveLifecycle) && !context.lifecycleId) {
    throw new Error("--lifecycle-id is required with --require-new or --exclusive-lifecycle.");
  }

  const hasAdapterBuilder = Boolean(rawOptions.adapterBuilder);
  const hasAdapterManifest = Boolean(rawOptions.adapterManifest);
  const hasAdapterWorker = Boolean(rawOptions.adapterWorker);
  if (hasAdapterBuilder !== hasAdapterManifest) {
    throw new Error("--adapter-builder and --adapter-manifest must be provided together.");
  }
  context.adapterEnabled = hasAdapterBuilder;
  context.adapterBuilder = hasAdapterBuilder ? path.resolve(rawOptions.adapterBuilder) : null;
  context.adapterManifest = hasAdapterManifest ? path.resolve(rawOptions.adapterManifest) : null;
  context.adapterWorker = hasAdapterWorker ? path.resolve(rawOptions.adapterWorker) : null;
  if (hasAdapterWorker && !hasAdapterBuilder) {
    throw new Error("--adapter-worker requires --adapter-builder and --adapter-manifest.");
  }
  context.adapterDebounceMs = hasAdapterBuilder
    ? parsePositiveInteger(rawOptions.adapterDebounceMs, DEFAULT_ADAPTER_DEBOUNCE_MS)
    : null;

  assertDirectory(context.root, "project root");
  assertFile(context.provider, "provider executable");
  assertFile(context.config, "provider config");
  assertPathInside(context.runtime, context.root, "coordinator runtime");
  if (context.adapterEnabled) {
    assertFile(context.adapterBuilder, "adapter builder");
    assertFile(context.adapterManifest, "adapter manifest");
    assertPathInside(context.adapterBuilder, context.root, "adapter builder");
    assertPathInside(context.adapterManifest, context.root, "adapter manifest");
    if (context.adapterWorker) {
      assertFile(context.adapterWorker, "adapter worker");
      assertPathInside(context.adapterWorker, context.root, "adapter worker");
    }
  }
  context.pipeName = createPipeName(context.root, context.runtime);
  return context;
}

function parseLifecycleId(value) {
  if (value === undefined) {
    return null;
  }
  const parsed = String(value);
  if (!/^[A-Za-z0-9._-]{1,128}$/.test(parsed)) {
    throw new Error(`Invalid lifecycle id: ${value}`);
  }
  return parsed;
}

function parseBoolean(value, fallback) {
  if (value === undefined) {
    return fallback;
  }
  if (value === "true") {
    return true;
  }
  if (value === "false") {
    return false;
  }
  throw new Error(`Expected true or false, got: ${value}`);
}

function parsePositiveInteger(value, fallback) {
  if (value === undefined) {
    return fallback;
  }
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`Expected a positive integer, got: ${value}`);
  }
  return parsed;
}

function assertDirectory(targetPath, label) {
  if (!fs.existsSync(targetPath) || !fs.statSync(targetPath).isDirectory()) {
    throw new Error(`Missing ${label}: ${targetPath}`);
  }
}

function assertFile(targetPath, label) {
  if (!fs.existsSync(targetPath) || !fs.statSync(targetPath).isFile()) {
    throw new Error(`Missing ${label}: ${targetPath}`);
  }
}

function assertPathInside(targetPath, rootPath, label) {
  const relative = path.relative(rootPath, targetPath);
  if (relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative))) {
    return;
  }
  throw new Error(`${label} must stay inside the project root. Path=${targetPath} Root=${rootPath}`);
}

function createPipeName(root, runtime) {
  const hash = crypto.createHash("sha256").update(`${normalizePath(root)}\n${normalizePath(runtime)}`).digest("hex").slice(0, 20);
  if (process.platform === "win32") {
    return `\\\\.\\pipe\\codedb-watch-${hash}`;
  }
  return path.join(runtime, `codedb-watch-${hash}.sock`);
}

function isLaunchReady(status, context) {
  if (status?.provider_state !== "ready") {
    return false;
  }
  if (!context.adapterEnabled) {
    return status?.adapter_enabled !== true;
  }
  const workerReady = context.adapterWorker
    ? status?.adapter_worker_state === "ready" && isProcessAlive(status?.adapter_worker_pid)
    : true;
  return status?.adapter_enabled === true && ADAPTER_OPERATIONAL_STATES.has(status?.adapter_state) && workerReady;
}

function assertStatusMatchesContext(status, context, label) {
  for (const [field, expected] of [
    ["root", context.root],
    ["provider_executable", context.provider],
    ["provider_config", context.config],
    ["runtime", context.runtime]
  ]) {
    if (normalizePath(status?.[field]) !== normalizePath(expected)) {
      throw new Error(`${label} metadata mismatch for ${field}; stop it before starting this configuration.`);
    }
  }

  const statusAdapterEnabled = status?.adapter_enabled === true;
  if (statusAdapterEnabled !== context.adapterEnabled) {
    throw new Error(`${label} adapter lane does not match this request; stop the existing coordinator before starting it again.`);
  }
  if (!context.adapterEnabled) {
    return;
  }
  for (const [field, expected] of [
    ["adapter_builder", context.adapterBuilder],
    ["adapter_manifest", context.adapterManifest],
    ["adapter_worker", context.adapterWorker]
  ]) {
    if (normalizePath(status?.[field]) !== normalizePath(expected)) {
      throw new Error(`${label} metadata mismatch for ${field}; stop it before starting this configuration.`);
    }
  }
  if (Number(status?.adapter_debounce_ms) !== context.adapterDebounceMs) {
    throw new Error(`${label} metadata mismatch for adapter_debounce_ms; stop it before starting this configuration.`);
  }
}

async function runStart(rawOptions) {
  const context = buildLaunchContext(rawOptions);
  const lifecycleId = context.lifecycleId ?? crypto.randomUUID();
  fs.mkdirSync(context.runtime, { recursive: true });
  const live = await requestCoordinator(context, "status", IPC_TIMEOUT_MS);
  if (live?.ok) {
    assertStatusMatchesContext(live.status, context, "Live coordinator");
    assertAttachAllowed(live.status, context, lifecycleId);
    if (isLaunchReady(live.status, context)) {
      printResult("ATTACHED", { action: "attached", ...live.status });
      return;
    }
    if (live.status?.provider_state === "failed" || live.status?.adapter_state === "failed") {
      const detail = live.status?.adapter_last_error ?? live.status?.last_error ?? "unknown coordinator failure";
      throw new Error(`Live coordinator is not recoverable through attach/start: ${detail}`);
    }
  }

  const staleState = readJsonFile(context.statePath);
  if (context.requireNew && staleState && staleState.lifecycle_id !== lifecycleId) {
    throw new Error("Stale coordinator metadata belongs to another lifecycle; require-new refused recovery.");
  }

  fs.rmSync(context.errorPath, { force: true });
  const daemonArgs = [
    fileURLToPath(import.meta.url),
    "daemon",
    "--root", context.root,
    "--provider", context.provider,
    "--config", context.config,
    "--runtime", context.runtime,
    "--lifecycle-id", lifecycleId,
    "--require-new", String(context.requireNew),
    "--exclusive-lifecycle", String(context.exclusiveLifecycle),
    "--startup-timeout-ms", String(context.startupTimeoutMs)
  ];
  if (context.adapterEnabled) {
    daemonArgs.push(
      "--adapter-builder", context.adapterBuilder,
      "--adapter-manifest", context.adapterManifest,
      "--adapter-debounce-ms", String(context.adapterDebounceMs)
    );
    if (context.adapterWorker) {
      daemonArgs.push("--adapter-worker", context.adapterWorker);
    }
  }
  const daemon = spawn(process.execPath, daemonArgs, {
    cwd: context.root,
    detached: true,
    stdio: "ignore",
    windowsHide: true
  });
  daemon.unref();

  const timer = Date.now();
  while (Date.now() - timer < context.startupTimeoutMs) {
    const response = await requestCoordinator(context, "status", 500);
    if (response?.ok) {
      assertStatusMatchesContext(response.status, context, "Started coordinator");
      const sameLifecycle = response.status?.lifecycle_id === lifecycleId;
      if (!sameLifecycle) {
        assertAttachAllowed(response.status, context, lifecycleId);
        if (isLaunchReady(response.status, context)) {
          printResult("ATTACHED", { action: "attached", ...response.status });
          return;
        }
        await delay(100);
        continue;
      }
      if (isLaunchReady(response.status, context)) {
        printResult("STARTED", { action: "started", ...response.status });
        return;
      }
    }
    const daemonError = readJsonFile(context.errorPath);
    if (daemonError?.message) {
      throw new Error(`Coordinator daemon failed: ${daemonError.message}`);
    }
    await delay(100);
  }
  throw new Error(`Timed out after ${context.startupTimeoutMs} ms waiting for coordinator readiness.`);
}

function assertAttachAllowed(status, context, lifecycleId) {
  if (context.requireNew) {
    throw new Error("A coordinator lifecycle already owns this runtime; require-new refused to attach.");
  }
  if (status?.exclusive_lifecycle === true && status?.lifecycle_id !== lifecycleId) {
    throw new Error("The live coordinator lifecycle is exclusive and refuses external attach.");
  }
}

async function runStatus(rawOptions) {
  const context = buildRuntimeContext(rawOptions);
  const response = await requestCoordinator(context, "status", IPC_TIMEOUT_MS);
  if (response?.ok) {
    printResult("OK", { action: "running", ...response.status });
    return;
  }

  const state = readJsonFile(context.statePath);
  const action = state ? "stale" : "stopped";
  printResult(action === "stale" ? "STALE" : "STOPPED", {
    action,
    coordinator_pid: state?.coordinator_pid ?? null,
    lifecycle_id: state?.lifecycle_id ?? null,
    exclusive_lifecycle: state?.exclusive_lifecycle === true,
    provider_pid: state?.provider_pid ?? null,
    adapter_state: state?.adapter_state ?? "stopped",
    adapter_worker_pid: state?.adapter_worker_pid ?? null,
    adapter_worker_state: state?.adapter_worker_state ?? "stopped",
    adapter_build_pid: state?.adapter_build_pid ?? null,
    runtime: context.runtime
  });
}

async function runStop(rawOptions) {
  const context = buildRuntimeContext(rawOptions);
  const expectedLifecycleId = parseLifecycleId(rawOptions.expectedLifecycleId);
  const response = await requestCoordinator(context, "stop", IPC_TIMEOUT_MS, { expectedLifecycleId });
  if (response && !response.ok) {
    throw new Error(response.error ?? "Coordinator refused the stop request.");
  }
  if (!response?.ok) {
    const state = readJsonFile(context.statePath);
    if (expectedLifecycleId && state) {
      if (state.lifecycle_id !== expectedLifecycleId) {
        throw new Error("Refusing to stop stale coordinator metadata owned by another lifecycle.");
      }
      throw new Error("The expected coordinator lifecycle is stale; recover it with the same lifecycle id before stopping it.");
    }
    printResult("STOPPED", { action: "already_stopped", runtime: context.runtime });
    return;
  }

  const coordinatorPid = response.status?.coordinator_pid;
  const timer = Date.now();
  while (Date.now() - timer < PROVIDER_STOP_TIMEOUT_MS + ADAPTER_STOP_TIMEOUT_MS + 3000) {
    if (!isProcessAlive(coordinatorPid) && !fs.existsSync(context.statePath)) {
      printResult("STOPPED", { action: "stopped", coordinator_pid: coordinatorPid, runtime: context.runtime });
      return;
    }
    await delay(100);
  }
  throw new Error(`Coordinator ${coordinatorPid} did not stop cleanly.`);
}

async function runDaemon(rawOptions) {
  const context = buildLaunchContext(rawOptions);
  const hostUseLease = acquireCodedbHostUseLease(context.root, "watcher");
  try {
    await runOwnedDaemon(context);
  } finally {
    hostUseLease.release();
  }
}

async function runOwnedDaemon(context) {
  fs.mkdirSync(context.runtime, { recursive: true });
  const recovery = await recoverStaleRuntime(context);
  if (recovery.blocked) {
    if (recovery.benign) {
      return;
    }
    throw new Error(recovery.reason);
  }

  let lockFd;
  try {
    lockFd = fs.openSync(context.lockPath, "wx");
  } catch (error) {
    if (error.code === "EEXIST") {
      return;
    }
    throw error;
  }

  fs.rmSync(context.errorPath, { force: true });
  const daemonState = createDaemonState(context, recovery);
  const log = (message) => appendLog(context.logPath, message);
  let server;
  let provider = null;
  let providerRpc = null;
  let stopping = false;
  let hasBeenReady = false;
  let restartTimer = null;
  let shutdownPromise = null;
  let adapterWatchers = [];
  let adapterDebounceTimer = null;
  let adapterBuilder = null;
  let adapterWorker = null;
  let adapterWorkerRpc = null;
  let adapterWorkerRestartTimer = null;
  let adapterWorkerHasBeenReady = false;
  let adapterBuildPromise = null;
  const adapterPendingPaths = new Set();
  let adapterPendingEventCount = 0;
  const adapterSourceSnapshots = new Map();
  const adapterValidationTimers = new Map();
  const adapterBufferedCandidates = new Map();
  let adapterInitializing = false;

  const persistState = () => writeJsonFile(context.statePath, daemonState);
  const publicStatus = () => sanitizeStatus(daemonState);

  const queryProvider = async (request) => {
    if (request.schema_version !== 1) {
      return { ok: false, error_code: "INVALID_QUERY", error: "Unsupported coordinator query schema version." };
    }
    if (!PROVIDER_QUERY_TOOLS.has(request.tool)) {
      return { ok: false, error_code: "INVALID_QUERY", error: `Unsupported coordinator query tool: ${request.tool}` };
    }
    if (!request.arguments || typeof request.arguments !== "object" || Array.isArray(request.arguments)) {
      return { ok: false, error_code: "INVALID_QUERY", error: "Coordinator query arguments must be an object." };
    }
    if (stopping || daemonState.provider_state !== "ready" || !providerRpc) {
      return { ok: false, error_code: "PROVIDER_UNAVAILABLE", error: "Coordinator Provider is not ready." };
    }

    const providerStartedAt = performance.now();
    daemonState.provider_query_count += 1;
    daemonState.provider_last_query_at_utc = new Date().toISOString();
    try {
      const result = await providerRpc.request("tools/call", {
        name: request.tool,
        arguments: request.arguments
      }, PROVIDER_REQUEST_TIMEOUT_MS);
      const providerProcessMs = performance.now() - providerStartedAt;
      daemonState.provider_last_query_elapsed_ms = Math.round(providerProcessMs * 100) / 100;
      return {
        ok: true,
        lifecycle_id: daemonState.lifecycle_id,
        output: getProviderToolOutput(result),
        timing: {
          queue_ms: 0,
          provider_process_ms: daemonState.provider_last_query_elapsed_ms,
          provider_core_ms: null,
          provider_attempts: 1
        }
      };
    } catch (error) {
      daemonState.provider_query_error_count += 1;
      daemonState.provider_last_query_elapsed_ms = Math.round((performance.now() - providerStartedAt) * 100) / 100;
      return {
        ok: false,
        error_code: error.code === "PROVIDER_TOOL_ERROR" ? "PROVIDER_TOOL_ERROR" : "PROVIDER_UNAVAILABLE",
        error: error.message
      };
    }
  };

  const persistAdapterPending = () => {
    daemonState.adapter_pending_paths = [...adapterPendingPaths].sort();
    daemonState.adapter_pending_event_count = adapterPendingEventCount;
  };

  const closeAdapterWatchers = () => {
    for (const watcher of adapterWatchers) {
      watcher.close();
    }
    adapterWatchers = [];
    for (const timer of adapterValidationTimers.values()) {
      clearTimeout(timer);
    }
    adapterValidationTimers.clear();
    adapterBufferedCandidates.clear();
    adapterSourceSnapshots.clear();
    adapterInitializing = false;
    daemonState.adapter_watched_roots = [];
  };

  const scheduleAdapterBuild = () => {
    if (!context.adapterEnabled || stopping || adapterBuildPromise || adapterPendingPaths.size === 0) {
      return;
    }
    if (context.adapterWorker && daemonState.adapter_worker_state !== "ready") {
      daemonState.adapter_state = "pending";
      persistAdapterPending();
      persistState();
      return;
    }
    if (adapterDebounceTimer) {
      clearTimeout(adapterDebounceTimer);
    }
    const quietForMs = Date.now() - (daemonState.adapter_last_event_at_ms ?? Date.now());
    const waitMs = Math.max(0, context.adapterDebounceMs - quietForMs);
    daemonState.adapter_state = "pending";
    daemonState.last_event = "adapter_build_pending";
    persistAdapterPending();
    persistState();
    adapterDebounceTimer = setTimeout(() => {
      adapterDebounceTimer = null;
      void launchAdapterBuild();
    }, waitMs);
  };

  const launchAdapterBuild = async () => {
    if (!context.adapterEnabled || stopping || adapterBuildPromise || adapterPendingPaths.size === 0) {
      return;
    }

    const batchPaths = [...adapterPendingPaths].sort();
    const batchEventCount = adapterPendingEventCount;
    adapterPendingPaths.clear();
    adapterPendingEventCount = 0;
    persistAdapterPending();

    const startedAtMs = Date.now();
    daemonState.adapter_state = "building";
    daemonState.adapter_build_attempt_count += 1;
    daemonState.adapter_last_build_started_at_utc = new Date(startedAtMs).toISOString();
    daemonState.adapter_last_build_finished_at_utc = null;
    daemonState.adapter_last_build_elapsed_ms = null;
    daemonState.adapter_last_build_event_count = batchEventCount;
    daemonState.adapter_last_build_paths = batchPaths;
    daemonState.adapter_last_error = null;
    daemonState.last_event = "adapter_build_started";
    persistState();

    let buildRequeued = false;
    adapterBuildPromise = (async () => {
      try {
        let builderPid;
        if (context.adapterWorker) {
          if (!adapterWorker || !adapterWorkerRpc || daemonState.adapter_worker_state !== "ready") {
            const error = new Error("Adapter worker is not ready for a build request.");
            error.code = "ADAPTER_WORKER_UNAVAILABLE";
            throw error;
          }
          builderPid = adapterWorker.pid ?? null;
          daemonState.adapter_build_pid = builderPid;
          persistState();
          const result = await adapterWorkerRpc.requestBuild("Automatic", ADAPTER_WORKER_BUILD_TIMEOUT_MS);
          if (result.output) {
            log(`adapter_stdout ${truncateText(result.output, MAX_ADAPTER_OUTPUT_CHARS).replace(/\r?\n/g, " | ")}`);
          }
        } else {
          const launch = createAdapterBuilderLaunch(context.adapterBuilder);
          const child = spawn(launch.command, launch.args, {
            cwd: context.root,
            stdio: ["ignore", "pipe", "pipe"],
            windowsHide: true
          });
          adapterBuilder = child;
          builderPid = child.pid ?? null;
          daemonState.adapter_build_pid = builderPid;
          persistState();

          const result = await collectChildResult(child, MAX_ADAPTER_OUTPUT_CHARS);
          if (result.stdout) {
            log(`adapter_stdout ${result.stdout.replace(/\r?\n/g, " | ")}`);
          }
          if (result.stderr) {
            log(`adapter_stderr ${result.stderr.replace(/\r?\n/g, " | ")}`);
          }
          if (result.error) {
            throw result.error;
          }
          if (result.code !== 0) {
            const detail = result.stderr || result.stdout || `exit code ${result.code}`;
            throw new Error(`Shader adapter builder failed with exit code ${result.code}. ${detail}`);
          }
        }
        validatePublishedAdapterManifest(context.adapterManifest, startedAtMs);

        daemonState.adapter_build_count += 1;
        daemonState.adapter_last_error = null;
        daemonState.last_event = "adapter_build_completed";
        log(`adapter_build_completed pid=${builderPid ?? "unknown"} elapsed_ms=${Date.now() - startedAtMs} events=${batchEventCount} paths=${batchPaths.length}`);
      } catch (error) {
        const workerTransportFailure = context.adapterWorker && [
          "ADAPTER_WORKER_EXIT",
          "ADAPTER_WORKER_TIMEOUT",
          "ADAPTER_WORKER_WRITE",
          "ADAPTER_WORKER_PROTOCOL",
          "ADAPTER_WORKER_UNAVAILABLE"
        ].includes(error.code);
        if (error.output) {
          log(`adapter_stderr ${truncateText(error.output, MAX_ADAPTER_OUTPUT_CHARS).replace(/\r?\n/g, " | ")}`);
        }
        if (!stopping && workerTransportFailure && adapterWorker && adapterWorker.exitCode === null) {
          adapterWorker.kill();
        }
        const workerRestartScheduled = !stopping && workerTransportFailure
          ? scheduleAdapterWorkerRestart("adapter_build_worker_failure")
          : false;
        if (workerRestartScheduled) {
          for (const batchPath of batchPaths) {
            adapterPendingPaths.add(batchPath);
          }
          adapterPendingEventCount += batchEventCount;
          buildRequeued = true;
          daemonState.adapter_last_error = null;
          daemonState.last_event = "adapter_build_requeued_after_worker_failure";
          log(`adapter_build_requeued error=${error.stack ?? error.message}`);
        } else if (!stopping) {
          daemonState.adapter_last_error = error.message;
          daemonState.last_event = "adapter_build_failed";
          log(`adapter_build_failed error=${error.stack ?? error.message}`);
        }
      } finally {
        adapterBuilder = null;
        daemonState.adapter_build_pid = null;
        daemonState.adapter_last_build_finished_at_utc = new Date().toISOString();
        daemonState.adapter_last_build_elapsed_ms = Date.now() - startedAtMs;
        if (stopping) {
          daemonState.adapter_state = "stopped";
        } else if (buildRequeued || adapterPendingPaths.size > 0) {
          daemonState.adapter_state = "pending";
        } else if (daemonState.adapter_last_error) {
          daemonState.adapter_state = "failed";
        } else {
          daemonState.adapter_state = "watching";
        }
        persistAdapterPending();
        persistState();
      }
    })();

    try {
      await adapterBuildPromise;
    } finally {
      adapterBuildPromise = null;
      if (!stopping && adapterPendingPaths.size > 0) {
        scheduleAdapterBuild();
      }
    }
  };

  const queueConfirmedAdapterEvent = (candidate, eventType) => {
    const relativePath = path.relative(context.root, candidate).replace(/\\/g, "/");
    adapterPendingPaths.add(relativePath);
    adapterPendingEventCount += 1;
    daemonState.adapter_event_count += 1;
    daemonState.adapter_last_error = null;
    daemonState.adapter_last_event_at_ms = Date.now();
    daemonState.adapter_last_event_at_utc = new Date(daemonState.adapter_last_event_at_ms).toISOString();
    daemonState.adapter_last_event_path = relativePath;
    daemonState.adapter_last_event_type = eventType;
    daemonState.last_event = adapterBuildPromise ? "adapter_event_queued_during_build" : "adapter_event_queued";
    persistAdapterPending();
    persistState();

    if (!adapterBuildPromise) {
      scheduleAdapterBuild();
    }
  };

  const validateAdapterCandidate = (candidate, eventType, attempt = 0) => {
    if (stopping) {
      return;
    }
    const key = normalizePath(candidate);
    const previous = adapterSourceSnapshots.get(key) ?? null;
    try {
      const result = readAdapterSourceSnapshot(candidate, previous);
      if (result.snapshot) {
        adapterSourceSnapshots.set(key, result.snapshot);
      } else {
        adapterSourceSnapshots.delete(key);
      }
      if (result.contentChanged) {
        queueConfirmedAdapterEvent(candidate, eventType);
      } else {
        daemonState.adapter_ignored_event_count += 1;
        persistState();
      }
    } catch (error) {
      if (attempt < 5) {
        const retry = setTimeout(() => {
          adapterValidationTimers.delete(key);
          validateAdapterCandidate(candidate, eventType, attempt + 1);
        }, 100);
        adapterValidationTimers.set(key, retry);
        return;
      }
      daemonState.adapter_state = "failed";
      daemonState.adapter_last_error = `Shader event validation failed for ${path.relative(context.root, candidate)}: ${error.message}`;
      daemonState.last_event = "adapter_event_validation_failed";
      persistState();
      log(`adapter_event_validation_failed path=${candidate} error=${error.stack ?? error.message}`);
    }
  };

  const scheduleAdapterCandidateValidation = (watchRoot, filename, eventType) => {
    if (!context.adapterEnabled || stopping || filename === null || filename === undefined) {
      return;
    }
    const candidate = path.resolve(watchRoot, String(filename));
    if (!isPathInside(candidate, watchRoot) || !ADAPTER_EXTENSIONS.has(path.extname(candidate).toLowerCase())) {
      return;
    }
    const key = normalizePath(candidate);
    daemonState.adapter_raw_event_count += 1;
    if (adapterInitializing) {
      adapterBufferedCandidates.set(key, { candidate, eventType });
      return;
    }
    const existing = adapterValidationTimers.get(key);
    if (existing) {
      clearTimeout(existing);
    }
    const timer = setTimeout(() => {
      adapterValidationTimers.delete(key);
      validateAdapterCandidate(candidate, eventType);
    }, 50);
    adapterValidationTimers.set(key, timer);
  };

  const startAdapterWatchers = () => {
    if (!context.adapterEnabled) {
      return;
    }
    const watchedRoots = [];
    const absoluteWatchRoots = [];
    adapterInitializing = true;
    try {
      for (const relativeRoot of ADAPTER_WATCH_ROOTS) {
        const watchRoot = path.join(context.root, relativeRoot);
        if (!fs.existsSync(watchRoot) || !fs.statSync(watchRoot).isDirectory()) {
          continue;
        }
        const watcher = fs.watch(watchRoot, { recursive: true, encoding: "utf8" }, (eventType, filename) => {
          scheduleAdapterCandidateValidation(watchRoot, filename, eventType);
        });
        watcher.on("error", (error) => {
          if (stopping) {
            return;
          }
          daemonState.adapter_state = "failed";
          daemonState.adapter_last_error = `Shader adapter watcher failed for ${relativeRoot}: ${error.message}`;
          daemonState.last_event = "adapter_watcher_failed";
          persistState();
          log(`adapter_watcher_failed root=${relativeRoot} error=${error.stack ?? error.message}`);
        });
        adapterWatchers.push(watcher);
        watchedRoots.push(relativeRoot);
        absoluteWatchRoots.push(watchRoot);
      }
      if (adapterWatchers.length === 0) {
        throw new Error("No Shader adapter watch roots exist under the project root.");
      }
      for (const watchRoot of absoluteWatchRoots) {
        for (const sourcePath of listAdapterSourceFiles(watchRoot)) {
          const snapshot = readAdapterSourceSnapshot(sourcePath, null).snapshot;
          if (snapshot) {
            adapterSourceSnapshots.set(normalizePath(sourcePath), snapshot);
          }
        }
      }
      adapterInitializing = false;
      for (const buffered of adapterBufferedCandidates.values()) {
        scheduleAdapterCandidateValidation(path.dirname(buffered.candidate), path.basename(buffered.candidate), buffered.eventType);
      }
      adapterBufferedCandidates.clear();
      daemonState.adapter_watched_roots = watchedRoots;
      daemonState.adapter_state = "watching";
      daemonState.adapter_last_error = null;
      daemonState.last_event = "adapter_watching";
      persistState();
      log(`adapter_watching roots=${watchedRoots.join(",")} debounce_ms=${context.adapterDebounceMs}`);
    } catch (error) {
      adapterInitializing = false;
      closeAdapterWatchers();
      throw error;
    }
  };

  const stopAdapterBuilder = async () => {
    if (!adapterBuilder || adapterBuilder.exitCode !== null) {
      if (adapterBuildPromise) {
        await adapterBuildPromise;
      }
      return;
    }
    const target = adapterBuilder;
    target.kill();
    const exited = await waitForExit(target, ADAPTER_STOP_TIMEOUT_MS);
    if (!exited && target.exitCode === null) {
      target.kill();
      await waitForExit(target, ADAPTER_STOP_TIMEOUT_MS);
    }
    if (adapterBuildPromise) {
      await adapterBuildPromise;
    }
  };

  const stopAdapterWorker = async () => {
    if (!adapterWorker || adapterWorker.exitCode !== null) {
      if (adapterBuildPromise) {
        await adapterBuildPromise;
      }
      return;
    }
    const target = adapterWorker;
    if (adapterBuildPromise) {
      target.kill();
    } else {
      target.stdin.end();
    }
    const exited = await waitForExit(target, ADAPTER_STOP_TIMEOUT_MS);
    if (!exited && target.exitCode === null) {
      target.kill();
      await waitForExit(target, ADAPTER_STOP_TIMEOUT_MS);
    }
    if (adapterBuildPromise) {
      await adapterBuildPromise;
    }
  };

  const stopProvider = async () => {
    if (!provider || provider.exitCode !== null) {
      return;
    }
    const target = provider;
    target.stdin.end();
    const exited = await waitForExit(target, PROVIDER_STOP_TIMEOUT_MS);
    if (!exited && target.exitCode === null) {
      target.kill();
      await waitForExit(target, PROVIDER_STOP_TIMEOUT_MS);
    }
  };

  const cleanup = async (reason, exitCode = 0) => {
    if (shutdownPromise) {
      return shutdownPromise;
    }
    shutdownPromise = (async () => {
      stopping = true;
      daemonState.provider_state = "stopping";
      if (context.adapterEnabled) {
        daemonState.adapter_state = "stopping";
      }
      if (context.adapterWorker) {
        daemonState.adapter_worker_state = "stopping";
      }
      daemonState.last_event = reason;
      if (restartTimer) {
        clearTimeout(restartTimer);
      }
      if (adapterWorkerRestartTimer) {
        clearTimeout(adapterWorkerRestartTimer);
        adapterWorkerRestartTimer = null;
      }
      if (adapterDebounceTimer) {
        clearTimeout(adapterDebounceTimer);
        adapterDebounceTimer = null;
      }
      closeAdapterWatchers();
      persistState();
      if (server) {
        await new Promise((resolve) => server.close(resolve));
      }
      if (context.adapterWorker) {
        await stopAdapterWorker();
      } else {
        await stopAdapterBuilder();
      }
      await stopProvider();
      fs.rmSync(context.statePath, { force: true });
      try {
        fs.closeSync(lockFd);
      } catch {
        // The lock is best-effort during process teardown.
      }
      fs.rmSync(context.lockPath, { force: true });
      if (process.platform !== "win32") {
        fs.rmSync(context.pipeName, { force: true });
      }
      log(`coordinator_stop reason=${reason} exit_code=${exitCode}`);
      process.exitCode = exitCode;
    })();
    return shutdownPromise;
  };

  const scheduleProviderRestart = (reason) => {
    if (stopping || restartTimer) {
      return;
    }
    if (daemonState.restart_count >= MAX_PROVIDER_RESTARTS) {
      daemonState.provider_state = "failed";
      daemonState.last_error = `Provider restart limit reached after ${reason}.`;
      persistState();
      return;
    }
    daemonState.restart_count += 1;
    daemonState.provider_state = "restarting";
    daemonState.last_event = reason;
    persistState();
    restartTimer = setTimeout(async () => {
      restartTimer = null;
      try {
        await launchProvider();
      } catch (error) {
        daemonState.last_error = error.message;
        persistState();
        scheduleProviderRestart("restart_failed");
      }
    }, 250);
  };

  const scheduleAdapterWorkerRestart = (reason) => {
    if (!context.adapterWorker || stopping) {
      return false;
    }
    if (adapterWorkerRestartTimer) {
      return true;
    }
    if (daemonState.adapter_worker_restart_count >= MAX_ADAPTER_WORKER_RESTARTS) {
      daemonState.adapter_worker_state = "failed";
      daemonState.adapter_state = "failed";
      daemonState.adapter_last_error = `Adapter worker restart limit reached after ${reason}.`;
      daemonState.last_event = "adapter_worker_restart_limit";
      persistState();
      return false;
    }
    daemonState.adapter_worker_restart_count += 1;
    daemonState.adapter_worker_state = "restarting";
    daemonState.adapter_state = adapterPendingPaths.size > 0 ? "pending" : "restarting";
    daemonState.last_event = reason;
    persistState();
    adapterWorkerRestartTimer = setTimeout(async () => {
      adapterWorkerRestartTimer = null;
      try {
        await launchAdapterWorker();
      } catch (error) {
        daemonState.adapter_last_error = error.message;
        persistState();
        if (error.code === "ADAPTER_WORKER_CLEANUP_FAILED") {
          daemonState.adapter_worker_state = "failed";
          daemonState.adapter_state = "failed";
          daemonState.last_event = "adapter_worker_cleanup_failed";
          persistState();
        } else {
          scheduleAdapterWorkerRestart("adapter_worker_restart_failed");
        }
      }
    }, 250);
    return true;
  };

  const launchAdapterWorker = async () => {
    if (!context.adapterWorker) {
      return;
    }
    daemonState.adapter_worker_state = "starting";
    daemonState.adapter_last_error = null;
    persistState();
    const launch = createAdapterWorkerLaunch(context.adapterWorker, context.adapterBuilder);
    const child = spawn(launch.command, launch.args, {
      cwd: context.root,
      stdio: ["pipe", "pipe", "pipe"],
      windowsHide: true
    });
    adapterWorker = child;
    adapterWorkerRpc = new AdapterWorkerRpc(child);
    daemonState.adapter_worker_pid = child.pid ?? null;
    persistState();
    child.stderr.on("data", (chunk) => appendLog(context.logPath, `adapter_worker ${String(chunk).trimEnd()}`));
    child.once("exit", (code, signal) => {
      if (adapterWorker !== child) {
        return;
      }
      adapterWorker = null;
      adapterWorkerRpc = null;
      daemonState.adapter_worker_pid = null;
      daemonState.adapter_worker_state = stopping ? "stopped" : "exited";
      daemonState.last_event = `adapter_worker_exit code=${code} signal=${signal ?? "none"}`;
      persistState();
      if (!stopping && adapterWorkerHasBeenReady) {
        scheduleAdapterWorkerRestart("adapter_worker_unexpected_exit");
      }
    });

    let ready;
    try {
      ready = await adapterWorkerRpc.waitReady(ADAPTER_WORKER_START_TIMEOUT_MS);
      if (Number(ready.worker_pid) !== Number(child.pid)
          || normalizePath(ready.builder_path) !== normalizePath(context.adapterBuilder)) {
        const error = new Error("Adapter worker readiness identity does not match the launched process.");
        error.code = "ADAPTER_WORKER_PROTOCOL";
        throw error;
      }
    } catch (error) {
      if (child.exitCode === null) {
        child.kill();
      }
      const exited = await waitForExit(child, ADAPTER_STOP_TIMEOUT_MS);
      if (!exited && child.exitCode === null) {
        const cleanupError = new Error(`Adapter worker PID ${child.pid ?? "unknown"} did not exit after readiness failure: ${error.message}`);
        cleanupError.code = "ADAPTER_WORKER_CLEANUP_FAILED";
        throw cleanupError;
      }
      throw error;
    }
    adapterWorkerHasBeenReady = true;
    daemonState.adapter_worker_state = "ready";
    daemonState.adapter_worker_ready_at_utc = new Date().toISOString();
    daemonState.adapter_last_error = null;
    if (adapterWatchers.length > 0 && adapterPendingPaths.size === 0 && !adapterBuildPromise) {
      daemonState.adapter_state = "watching";
    }
    daemonState.last_event = "adapter_worker_ready";
    persistState();
    log(`adapter_worker_ready pid=${child.pid} restart_count=${daemonState.adapter_worker_restart_count}`);
    if (adapterPendingPaths.size > 0 && !adapterBuildPromise) {
      scheduleAdapterBuild();
    }
  };

  const launchProvider = async () => {
    daemonState.provider_state = "starting";
    daemonState.last_error = null;
    persistState();
    const child = spawn(context.provider, ["--config", context.config, "mcp", context.root], {
      cwd: context.root,
      stdio: ["pipe", "pipe", "pipe"],
      windowsHide: true
    });
    provider = child;
    daemonState.provider_pid = child.pid;
    persistState();
    child.stderr.on("data", (chunk) => appendLog(context.logPath, `provider ${String(chunk).trimEnd()}`));
    child.once("exit", (code, signal) => {
      if (provider !== child) {
        return;
      }
      daemonState.provider_pid = null;
      daemonState.provider_state = stopping ? "stopped" : "exited";
      daemonState.last_event = `provider_exit code=${code} signal=${signal ?? "none"}`;
      persistState();
      if (!stopping && hasBeenReady) {
        scheduleProviderRestart("provider_unexpected_exit");
      }
    });

    providerRpc = new ProviderRpc(child);
    const initialize = await providerRpc.request("initialize", {
      protocolVersion: "2024-11-05",
      capabilities: {},
      clientInfo: { name: "codedb-watch-coordinator", version: "0.1.0" }
    }, PROVIDER_REQUEST_TIMEOUT_MS);
    if (!initialize?.serverInfo?.name) {
      throw new Error("Provider initialize did not return server information.");
    }
    providerRpc.notify("notifications/initialized", {});
    const tools = await providerRpc.request("tools/list", {}, PROVIDER_REQUEST_TIMEOUT_MS);
    const toolNames = (tools?.tools ?? []).map((tool) => tool.name);
    if (!toolNames.includes("codedb_text_search")) {
      throw new Error("Provider is missing codedb_text_search.");
    }
    hasBeenReady = true;
    daemonState.provider_state = "ready";
    daemonState.provider_ready_at_utc = new Date().toISOString();
    daemonState.last_event = "provider_ready";
    persistState();
    log(`provider_ready pid=${child.pid} restart_count=${daemonState.restart_count}`);
  };

  try {
    server = net.createServer((socket) => handleClient(socket, daemonState.auth_token, publicStatus, async (request) => {
      const clientCommand = request.command;
      if (clientCommand === "status") {
        return { ok: true, status: publicStatus() };
      }
      if (clientCommand === "query") {
        return queryProvider(request);
      }
      if (clientCommand === "stop") {
        if (daemonState.exclusive_lifecycle === true && !request.expected_lifecycle_id) {
          return { ok: false, error: "Exclusive coordinator lifecycle requires an expected lifecycle id for Stop." };
        }
        if (request.expected_lifecycle_id && request.expected_lifecycle_id !== daemonState.lifecycle_id) {
          return { ok: false, error: "Refusing to stop a coordinator owned by another lifecycle." };
        }
        const response = { ok: true, status: publicStatus() };
        setTimeout(() => void cleanup("client_stop"), 25);
        return response;
      }
      return { ok: false, error: `Unsupported coordinator command: ${clientCommand}` };
    }));
    await listen(server, context.pipeName);
    persistState();
    log(`coordinator_start pid=${process.pid} pipe=${context.pipeName}`);
    await launchAdapterWorker();
    startAdapterWatchers();
    await launchProvider();

    process.on("SIGINT", () => void cleanup("sigint"));
    process.on("SIGTERM", () => void cleanup("sigterm"));
    process.on("uncaughtException", (error) => {
      writeDaemonError(context.runtime, error);
      void cleanup("uncaught_exception", 1);
    });
    process.on("unhandledRejection", (error) => {
      writeDaemonError(context.runtime, error instanceof Error ? error : new Error(String(error)));
      void cleanup("unhandled_rejection", 1);
    });

    await new Promise((resolve) => server.once("close", resolve));
    await shutdownPromise;
  } catch (error) {
    writeDaemonError(context.runtime, error);
    await cleanup("daemon_start_failure", 1);
    throw error;
  }
}

function createDaemonState(context, recovery) {
  return {
    schema_version: 1,
    coordinator_pid: process.pid,
    lifecycle_id: context.lifecycleId,
    exclusive_lifecycle: context.exclusiveLifecycle,
    provider_pid: null,
    provider_state: "starting",
    restart_count: 0,
    orphan_cleanup_count: recovery.orphanCleanupCount ?? 0,
    root: context.root,
    provider_executable: context.provider,
    provider_config: context.config,
    runtime: context.runtime,
    pipe_name: context.pipeName,
    auth_token: crypto.randomBytes(24).toString("hex"),
    started_at_utc: new Date().toISOString(),
    provider_ready_at_utc: null,
    provider_query_count: 0,
    provider_query_error_count: 0,
    provider_last_query_at_utc: null,
    provider_last_query_elapsed_ms: null,
    adapter_enabled: context.adapterEnabled,
    adapter_builder: context.adapterBuilder,
    adapter_worker: context.adapterWorker,
    adapter_manifest: context.adapterManifest,
    adapter_debounce_ms: context.adapterDebounceMs,
    adapter_state: context.adapterEnabled ? "starting" : "disabled",
    adapter_worker_pid: null,
    adapter_worker_state: context.adapterWorker ? "starting" : "disabled",
    adapter_worker_restart_count: 0,
    adapter_worker_orphan_cleanup_count: recovery.adapterWorkerOrphanCleanupCount ?? 0,
    adapter_worker_ready_at_utc: null,
    adapter_build_pid: null,
    adapter_build_count: 0,
    adapter_build_attempt_count: 0,
    adapter_orphan_cleanup_count: recovery.adapterOrphanCleanupCount ?? 0,
    adapter_raw_event_count: 0,
    adapter_ignored_event_count: 0,
    adapter_event_count: 0,
    adapter_pending_event_count: 0,
    adapter_pending_paths: [],
    adapter_watched_roots: [],
    adapter_last_event_at_ms: null,
    adapter_last_event_at_utc: null,
    adapter_last_event_path: null,
    adapter_last_event_type: null,
    adapter_last_build_started_at_utc: null,
    adapter_last_build_finished_at_utc: null,
    adapter_last_build_elapsed_ms: null,
    adapter_last_build_event_count: 0,
    adapter_last_build_paths: [],
    adapter_last_error: null,
    last_event: "coordinator_starting",
    last_error: null
  };
}

async function recoverStaleRuntime(context) {
  const state = readJsonFile(context.statePath);
  if (!state) {
    if (fs.existsSync(context.lockPath)) {
      const ageMs = Date.now() - fs.statSync(context.lockPath).mtimeMs;
      if (ageMs < 5000) {
        return {
          blocked: true,
          benign: true,
          reason: "Coordinator lock exists without stable metadata; another owner is starting."
        };
      }
      fs.rmSync(context.lockPath, { force: true });
    }
    return {
      blocked: false,
      orphanCleanupCount: 0,
      adapterOrphanCleanupCount: 0,
      adapterWorkerOrphanCleanupCount: 0
    };
  }

  if (isProcessAlive(state.coordinator_pid)) {
    return {
      blocked: true,
      benign: true,
      reason: `Coordinator PID ${state.coordinator_pid} is already the live owner.`
    };
  }
  if (context.requireNew &&
      (state.lifecycle_id !== context.lifecycleId || state.exclusive_lifecycle !== context.exclusiveLifecycle)) {
    throw new Error("Stale coordinator ownership does not match the requested require-new lifecycle; refusing cleanup.");
  }
  assertStateMatchesContext(state, context);

  let orphanCleanupCount = Number.parseInt(state.orphan_cleanup_count ?? 0, 10) || 0;
  let adapterOrphanCleanupCount = Number.parseInt(state.adapter_orphan_cleanup_count ?? 0, 10) || 0;
  let adapterWorkerOrphanCleanupCount = Number.parseInt(state.adapter_worker_orphan_cleanup_count ?? 0, 10) || 0;
  const adapterProcesses = new Map();
  if (isProcessAlive(state.adapter_worker_pid)) {
    adapterProcesses.set(Number(state.adapter_worker_pid), "worker");
  }
  if (isProcessAlive(state.adapter_build_pid) && !adapterProcesses.has(Number(state.adapter_build_pid))) {
    adapterProcesses.set(Number(state.adapter_build_pid), "builder");
  }
  for (const [processId, kind] of adapterProcesses) {
    const identity = getWindowsProcessIdentity(processId);
    const identityMatches = kind === "worker"
      ? adapterWorkerIdentityMatches(identity, context)
      : adapterBuilderIdentityMatches(identity, context);
    if (!identity || !identityMatches) {
      throw new Error(`Refusing to terminate stale adapter ${kind} PID ${processId}: process identity does not match the recorded command.`);
    }
    process.kill(processId);
    const exited = await waitForProcessExit(processId, ADAPTER_STOP_TIMEOUT_MS);
    if (!exited) {
      throw new Error(`Validated orphan adapter ${kind} PID ${processId} did not exit.`);
    }
    if (kind === "worker") {
      adapterWorkerOrphanCleanupCount += 1;
    } else {
      adapterOrphanCleanupCount += 1;
    }
  }
  if (isProcessAlive(state.provider_pid)) {
    const identity = getWindowsProcessIdentity(state.provider_pid);
    if (!identity || !providerIdentityMatches(identity, context)) {
      throw new Error(`Refusing to terminate stale provider PID ${state.provider_pid}: process identity does not match the recorded provider/root/config.`);
    }
    process.kill(state.provider_pid);
    const exited = await waitForProcessExit(state.provider_pid, PROVIDER_STOP_TIMEOUT_MS);
    if (!exited) {
      throw new Error(`Validated orphan provider PID ${state.provider_pid} did not exit.`);
    }
    orphanCleanupCount += 1;
  }

  fs.rmSync(context.statePath, { force: true });
  fs.rmSync(context.lockPath, { force: true });
  return {
    blocked: false,
    orphanCleanupCount,
    adapterOrphanCleanupCount,
    adapterWorkerOrphanCleanupCount
  };
}

function assertStateMatchesContext(state, context) {
  for (const [field, expected] of [
    ["root", context.root],
    ["provider_executable", context.provider],
    ["provider_config", context.config],
    ["runtime", context.runtime]
  ]) {
    if (normalizePath(state[field]) !== normalizePath(expected)) {
      throw new Error(`Stale coordinator metadata mismatch for ${field}; refusing cleanup.`);
    }
  }

  const stateAdapterEnabled = state.adapter_enabled === true;
  if (stateAdapterEnabled !== context.adapterEnabled) {
    throw new Error("Stale coordinator adapter lane does not match this request; refusing cleanup.");
  }
  if (!context.adapterEnabled) {
    return;
  }
  for (const [field, expected] of [
    ["adapter_builder", context.adapterBuilder],
    ["adapter_manifest", context.adapterManifest],
    ["adapter_worker", context.adapterWorker]
  ]) {
    if (normalizePath(state[field]) !== normalizePath(expected)) {
      throw new Error(`Stale coordinator metadata mismatch for ${field}; refusing cleanup.`);
    }
  }
  if (Number(state.adapter_debounce_ms) !== context.adapterDebounceMs) {
    throw new Error("Stale coordinator metadata mismatch for adapter_debounce_ms; refusing cleanup.");
  }
}

function getWindowsProcessIdentity(pid) {
  if (!Number.isInteger(Number(pid)) || Number(pid) <= 0 || process.platform !== "win32") {
    return null;
  }
  const script = `$p=Get-CimInstance Win32_Process -Filter "ProcessId = ${Number(pid)}" -ErrorAction SilentlyContinue; if($null -ne $p){[pscustomobject]@{ExecutablePath=$p.ExecutablePath;CommandLine=$p.CommandLine}|ConvertTo-Json -Compress}`;
  const result = spawnSync("powershell.exe", ["-NoProfile", "-Command", script], {
    encoding: "utf8",
    windowsHide: true,
    timeout: 5000
  });
  if (result.status !== 0 || !result.stdout.trim()) {
    return null;
  }
  return JSON.parse(result.stdout.trim());
}

function providerIdentityMatches(identity, context) {
  const executableMatches = normalizePath(identity.ExecutablePath) === normalizePath(context.provider);
  const commandLine = normalizePath(identity.CommandLine);
  return executableMatches
    && commandLine.includes(normalizePath(context.config))
    && commandLine.includes(normalizePath(context.root));
}

function adapterBuilderIdentityMatches(identity, context) {
  if (!identity || !context.adapterEnabled) {
    return false;
  }
  return normalizePath(identity.CommandLine).includes(normalizePath(context.adapterBuilder));
}

function adapterWorkerIdentityMatches(identity, context) {
  if (!identity || !context.adapterWorker) {
    return false;
  }
  const commandLine = normalizePath(identity.CommandLine);
  return commandLine.includes(normalizePath(context.adapterWorker))
    && commandLine.includes(normalizePath(context.adapterBuilder));
}

function normalizePath(value) {
  return String(value ?? "").replace(/^\\\\\?\\/, "").replace(/\\/g, "/").toLowerCase();
}

function handleClient(socket, authToken, getStatus, dispatch) {
  socket.setEncoding("utf8");
  let buffer = "";
  let handled = false;
  socket.on("data", (chunk) => {
    if (handled) {
      return;
    }
    buffer += chunk;
    if (Buffer.byteLength(buffer, "utf8") > MAX_IPC_REQUEST_BYTES) {
      handled = true;
      socket.end(`${JSON.stringify({ ok: false, error_code: "REQUEST_TOO_LARGE", error: "Coordinator request exceeds 64 KiB." })}\n`);
      return;
    }
    const newline = buffer.indexOf("\n");
    if (newline < 0) {
      return;
    }
    handled = true;
    const line = buffer.slice(0, newline);
    buffer = buffer.slice(newline + 1);
    void (async () => {
      try {
        const request = JSON.parse(line);
        if (!authTokensMatch(request.auth_token, authToken)) {
          socket.end(`${JSON.stringify({ ok: false, error_code: "UNAUTHORIZED", error: "Unauthorized coordinator request." })}\n`);
          return;
        }
        const response = await dispatch(request, getStatus());
        socket.end(`${JSON.stringify(response)}\n`);
      } catch (error) {
        socket.end(`${JSON.stringify({ ok: false, error_code: error.code ?? "COORDINATOR_REQUEST_FAILED", error: error.message })}\n`);
      }
    })();
  });
}

function authTokensMatch(value, expected) {
  const actualBuffer = Buffer.from(String(value ?? ""), "utf8");
  const expectedBuffer = Buffer.from(String(expected ?? ""), "utf8");
  return actualBuffer.length === expectedBuffer.length
    && actualBuffer.length > 0
    && crypto.timingSafeEqual(actualBuffer, expectedBuffer);
}

async function requestCoordinator(context, clientCommand, timeoutMs, requestOptions = {}) {
  const state = readJsonFile(context.statePath);
  if (!state?.pipe_name || !state?.auth_token) {
    return null;
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
    const timer = setTimeout(() => finish(null), timeoutMs);
    socket.setEncoding("utf8");
    socket.on("connect", () => {
      const request = { auth_token: state.auth_token, command: clientCommand };
      if (requestOptions.expectedLifecycleId) {
        request.expected_lifecycle_id = requestOptions.expectedLifecycleId;
      }
      socket.write(`${JSON.stringify(request)}\n`);
    });
    socket.on("data", (chunk) => {
      buffer += chunk;
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

class ProviderRpc {
  constructor(child) {
    this.child = child;
    this.nextId = 1;
    this.pending = new Map();
    this.lines = readline.createInterface({ input: child.stdout });
    this.lines.on("line", (line) => this.handleLine(line));
    child.once("exit", () => {
      for (const pending of this.pending.values()) {
        clearTimeout(pending.timer);
        const error = new Error("Provider exited while an MCP request was pending.");
        error.code = "PROVIDER_UNAVAILABLE";
        pending.reject(error);
      }
      this.pending.clear();
    });
  }

  request(method, params, timeoutMs) {
    const id = this.nextId;
    this.nextId += 1;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        const error = new Error(`Timed out waiting for provider MCP method ${method}.`);
        error.code = "PROVIDER_TIMEOUT";
        reject(error);
      }, timeoutMs);
      this.pending.set(id, { resolve, reject, timer });
      this.child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", id, method, params })}\n`);
    });
  }

  notify(method, params) {
    this.child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", method, params })}\n`);
  }

  handleLine(line) {
    let message;
    try {
      message = JSON.parse(line);
    } catch {
      return;
    }
    const pending = this.pending.get(message.id);
    if (!pending) {
      return;
    }
    this.pending.delete(message.id);
    clearTimeout(pending.timer);
    if (message.error) {
      const error = new Error(message.error.message ?? "Provider MCP error.");
      error.code = "PROVIDER_TOOL_ERROR";
      pending.reject(error);
    } else {
      pending.resolve(message.result);
    }
  }
}

function getProviderToolOutput(result) {
  const content = Array.isArray(result?.content) ? result.content : [];
  const text = content
    .filter((entry) => entry?.type === "text")
    .map((entry) => String(entry.text ?? ""))
    .join("\n");
  if (result?.isError === true) {
    const error = new Error(text || "Provider tool returned an error result.");
    error.code = "PROVIDER_TOOL_ERROR";
    throw error;
  }
  if (content.length > 0 && !content.some((entry) => entry?.type === "text")) {
    const error = new Error("Provider tool returned no text content.");
    error.code = "PROVIDER_TOOL_ERROR";
    throw error;
  }
  return text;
}

class AdapterWorkerRpc {
  constructor(child) {
    this.child = child;
    this.nextId = 1;
    this.pending = new Map();
    this.readyMessage = null;
    this.readyPromise = new Promise((resolve, reject) => {
      this.resolveReady = resolve;
      this.rejectReady = reject;
    });
    this.lines = readline.createInterface({ input: child.stdout });
    this.lines.on("line", (line) => this.handleLine(line));
    child.stdin.on("error", (cause) => this.handleWriteFailure(cause));
    child.once("error", (cause) => this.handleWriteFailure(cause));
    child.once("exit", (code, signal) => {
      const error = new Error(`Adapter worker exited code=${code} signal=${signal ?? "none"}.`);
      error.code = "ADAPTER_WORKER_EXIT";
      this.rejectReady(error);
      this.rejectPending(error);
    });
  }

  async waitReady(timeoutMs) {
    if (this.readyMessage) {
      return this.readyMessage;
    }
    let timer;
    try {
      return await Promise.race([
        this.readyPromise,
        new Promise((_, reject) => {
          timer = setTimeout(() => {
            const error = new Error("Timed out waiting for adapter worker readiness.");
            error.code = "ADAPTER_WORKER_TIMEOUT";
            reject(error);
          }, timeoutMs);
        })
      ]);
    } finally {
      clearTimeout(timer);
    }
  }

  requestBuild(reason, timeoutMs) {
    const requestId = `build-${this.nextId}`;
    this.nextId += 1;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(requestId);
        const error = new Error(`Timed out waiting for adapter worker request ${requestId}.`);
        error.code = "ADAPTER_WORKER_TIMEOUT";
        reject(error);
      }, timeoutMs);
      this.pending.set(requestId, { resolve, reject, timer });
      try {
        this.child.stdin.write(`${JSON.stringify({
          schema_version: 1,
          action: "build",
          request_id: requestId,
          reason
        })}\n`, (cause) => {
          if (cause) {
            this.handleWriteFailure(cause);
          }
        });
      } catch (cause) {
        this.handleWriteFailure(cause);
      }
    });
  }

  handleWriteFailure(cause) {
    const error = new Error(`Failed to write to adapter worker: ${cause?.message ?? cause}`);
    error.code = "ADAPTER_WORKER_WRITE";
    this.rejectReady(error);
    this.rejectPending(error);
  }

  handleLine(line) {
    let message;
    try {
      message = JSON.parse(line);
    } catch {
      const error = new Error(`Adapter worker returned invalid JSON: ${line.slice(0, 200)}`);
      error.code = "ADAPTER_WORKER_PROTOCOL";
      this.rejectReady(error);
      this.rejectPending(error);
      this.child.kill();
      return;
    }
    if (message.schema_version !== 1) {
      const error = new Error("Adapter worker returned an unsupported schema version.");
      error.code = "ADAPTER_WORKER_PROTOCOL";
      this.rejectReady(error);
      this.rejectPending(error);
      this.child.kill();
      return;
    }
    if (message.type === "ready") {
      this.readyMessage = message;
      this.resolveReady(message);
      return;
    }
    const pending = this.pending.get(message.request_id);
    if (!pending) {
      return;
    }
    this.pending.delete(message.request_id);
    clearTimeout(pending.timer);
    if (message.type === "build_completed") {
      pending.resolve(message);
      return;
    }
    const error = new Error(message.error ?? "Adapter worker build failed.");
    error.code = "ADAPTER_BUILD_FAILED";
    error.output = message.output ?? "";
    pending.reject(error);
  }

  rejectPending(error) {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer);
      pending.reject(error);
    }
    this.pending.clear();
  }
}

function createAdapterWorkerLaunch(workerPath, builderPath) {
  return {
    command: process.platform === "win32" ? "powershell.exe" : "pwsh",
    args: [
      "-NoProfile",
      "-NonInteractive",
      "-NoLogo",
      "-ExecutionPolicy", "Bypass",
      "-File", workerPath,
      "-BuilderPath", builderPath
    ]
  };
}

function createAdapterBuilderLaunch(builderPath) {
  const extension = path.extname(builderPath).toLowerCase();
  if (extension === ".ps1") {
    return {
      command: process.platform === "win32" ? "powershell.exe" : "pwsh",
      args: ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", builderPath, "-Reason", "Automatic"]
    };
  }
  if (extension === ".js" || extension === ".mjs" || extension === ".cjs") {
    return { command: process.execPath, args: [builderPath, "--reason", "automatic"] };
  }
  return { command: builderPath, args: ["--reason", "automatic"] };
}

function listAdapterSourceFiles(rootPath) {
  const files = [];
  const pendingDirectories = [rootPath];
  while (pendingDirectories.length > 0) {
    const directory = pendingDirectories.pop();
    let entries;
    try {
      entries = fs.readdirSync(directory, { withFileTypes: true });
    } catch (error) {
      if (["EACCES", "ENOENT", "EPERM"].includes(error.code)) {
        continue;
      }
      throw error;
    }
    for (const entry of entries) {
      const entryPath = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        pendingDirectories.push(entryPath);
      } else if (entry.isFile() && ADAPTER_EXTENSIONS.has(path.extname(entry.name).toLowerCase())) {
        files.push(entryPath);
      }
    }
  }
  return files;
}

function readAdapterSourceSnapshot(filePath, previous) {
  let stat;
  try {
    stat = fs.statSync(filePath);
  } catch (error) {
    if (error.code === "ENOENT") {
      return { snapshot: null, contentChanged: previous !== null };
    }
    throw error;
  }
  if (!stat.isFile()) {
    return { snapshot: null, contentChanged: previous !== null };
  }

  if (previous
      && previous.size === stat.size
      && previous.mtimeMs === stat.mtimeMs
      && previous.ctimeMs === stat.ctimeMs) {
    return { snapshot: previous, contentChanged: false };
  }

  const sha256 = crypto.createHash("sha256").update(fs.readFileSync(filePath)).digest("hex");
  const snapshot = {
    size: stat.size,
    mtimeMs: stat.mtimeMs,
    ctimeMs: stat.ctimeMs,
    sha256
  };
  return {
    snapshot,
    contentChanged: previous === null || previous.sha256 !== sha256
  };
}

function collectChildResult(child, maxChars) {
  return new Promise((resolve) => {
    let stdout = "";
    let stderr = "";
    let spawnError = null;
    const append = (current, chunk) => `${current}${String(chunk)}`.slice(-maxChars);
    child.stdout?.on("data", (chunk) => {
      stdout = append(stdout, chunk);
    });
    child.stderr?.on("data", (chunk) => {
      stderr = append(stderr, chunk);
    });
    child.once("error", (error) => {
      spawnError = error;
    });
    child.once("close", (code, signal) => {
      resolve({
        code,
        signal,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
        error: spawnError
      });
    });
  });
}

function truncateText(value, maxChars) {
  const text = String(value ?? "");
  return text.length <= maxChars ? text : text.slice(-maxChars);
}

function validatePublishedAdapterManifest(manifestPath, buildStartedAtMs) {
  assertFile(manifestPath, "published adapter manifest");
  const stat = fs.statSync(manifestPath);
  if (stat.mtimeMs < buildStartedAtMs - 2000) {
    throw new Error("Shader adapter builder exited successfully but did not publish a current manifest.");
  }
  try {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    if (!manifest || typeof manifest !== "object" || Array.isArray(manifest)) {
      throw new Error("manifest root is not an object");
    }
  } catch (error) {
    throw new Error(`Published Shader adapter manifest is invalid JSON: ${error.message}`);
  }
}

function isPathInside(targetPath, rootPath) {
  const relative = path.relative(path.resolve(rootPath), path.resolve(targetPath));
  return relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative));
}

function sanitizeStatus(state) {
  return {
    schema_version: state.schema_version,
    coordinator_pid: state.coordinator_pid,
    lifecycle_id: state.lifecycle_id ?? null,
    exclusive_lifecycle: state.exclusive_lifecycle === true,
    provider_pid: state.provider_pid,
    provider_state: state.provider_state,
    restart_count: state.restart_count,
    orphan_cleanup_count: state.orphan_cleanup_count,
    root: state.root,
    provider_executable: state.provider_executable,
    provider_config: state.provider_config,
    runtime: state.runtime,
    started_at_utc: state.started_at_utc,
    provider_ready_at_utc: state.provider_ready_at_utc,
    provider_query_count: state.provider_query_count,
    provider_query_error_count: state.provider_query_error_count,
    provider_last_query_at_utc: state.provider_last_query_at_utc,
    provider_last_query_elapsed_ms: state.provider_last_query_elapsed_ms,
    adapter_enabled: state.adapter_enabled,
    adapter_builder: state.adapter_builder,
    adapter_worker: state.adapter_worker,
    adapter_manifest: state.adapter_manifest,
    adapter_debounce_ms: state.adapter_debounce_ms,
    adapter_state: state.adapter_state,
    adapter_worker_pid: state.adapter_worker_pid,
    adapter_worker_state: state.adapter_worker_state,
    adapter_worker_restart_count: state.adapter_worker_restart_count,
    adapter_worker_orphan_cleanup_count: state.adapter_worker_orphan_cleanup_count,
    adapter_worker_ready_at_utc: state.adapter_worker_ready_at_utc,
    adapter_build_pid: state.adapter_build_pid,
    adapter_build_count: state.adapter_build_count,
    adapter_build_attempt_count: state.adapter_build_attempt_count,
    adapter_orphan_cleanup_count: state.adapter_orphan_cleanup_count,
    adapter_raw_event_count: state.adapter_raw_event_count,
    adapter_ignored_event_count: state.adapter_ignored_event_count,
    adapter_event_count: state.adapter_event_count,
    adapter_pending_event_count: state.adapter_pending_event_count,
    adapter_pending_paths: state.adapter_pending_paths,
    adapter_watched_roots: state.adapter_watched_roots,
    adapter_last_event_at_utc: state.adapter_last_event_at_utc,
    adapter_last_event_path: state.adapter_last_event_path,
    adapter_last_event_type: state.adapter_last_event_type,
    adapter_last_build_started_at_utc: state.adapter_last_build_started_at_utc,
    adapter_last_build_finished_at_utc: state.adapter_last_build_finished_at_utc,
    adapter_last_build_elapsed_ms: state.adapter_last_build_elapsed_ms,
    adapter_last_build_event_count: state.adapter_last_build_event_count,
    adapter_last_build_paths: state.adapter_last_build_paths,
    adapter_last_error: state.adapter_last_error,
    last_event: state.last_event,
    last_error: state.last_error
  };
}

function listen(server, pipeName) {
  if (process.platform !== "win32") {
    fs.rmSync(pipeName, { force: true });
  }
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(pipeName, () => {
      server.off("error", reject);
      resolve();
    });
  });
}

function waitForExit(child, timeoutMs) {
  if (child.exitCode !== null) {
    return Promise.resolve(true);
  }
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(false), timeoutMs);
    child.once("exit", () => {
      clearTimeout(timer);
      resolve(true);
    });
  });
}

async function waitForProcessExit(pid, timeoutMs) {
  const started = Date.now();
  while (Date.now() - started < timeoutMs) {
    if (!isProcessAlive(pid)) {
      return true;
    }
    await delay(100);
  }
  return !isProcessAlive(pid);
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

function readJsonFile(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function writeJsonFile(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function writeDaemonError(runtime, error) {
  try {
    fs.mkdirSync(runtime, { recursive: true });
    writeJsonFile(path.join(runtime, ERROR_FILE), {
      created_at_utc: new Date().toISOString(),
      message: error.message,
      stack: error.stack ?? null
    });
    appendLog(path.join(runtime, LOG_FILE), `daemon_error ${error.stack ?? error.message}`);
  } catch {
    // Preserve the original error when diagnostics cannot be written.
  }
}

function appendLog(logPath, message) {
  fs.appendFileSync(logPath, `${new Date().toISOString()} ${message}\n`, "utf8");
}

function printResult(marker, value) {
  process.stdout.write(`[${marker}] codedb watch coordinator ${value.action}.\n`);
  process.stdout.write(`${JSON.stringify(value)}\n`);
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

await main();
