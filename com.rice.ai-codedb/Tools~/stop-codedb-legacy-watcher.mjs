#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";

const STATE_FILE = "coordinator-state.json";
const MAX_STATE_BYTES = 64 * 1024;
const IPC_TIMEOUT_MS = 2000;
const STOP_TIMEOUT_MS = 25000;

const options = parseArgs(process.argv.slice(2));

async function main() {
  const projectRoot = fs.realpathSync(path.resolve(requireOption("projectRoot")));
  const runtime = fs.realpathSync(path.resolve(requireOption("runtime")));
  const expectedPid = parsePositiveInteger(requireOption("expectedPid"), "expected PID");
  const expectedStateSha256 = requireOption("expectedStateSha256").toLowerCase();
  if (!/^[0-9a-f]{64}$/.test(expectedStateSha256)) {
    throw new Error("Expected coordinator state SHA256 is invalid.");
  }
  assertPathInside(runtime, projectRoot, "legacy coordinator runtime");

  const statePath = path.join(runtime, STATE_FILE);
  const initial = readValidatedState(statePath, projectRoot, runtime, expectedPid, expectedStateSha256);
  const statusResponse = await requestCoordinator(initial, "status");
  validateResponse(statusResponse, initial, projectRoot, runtime, "status");

  const beforeStop = readValidatedState(statePath, projectRoot, runtime, expectedPid, expectedStateSha256);
  validateStableIdentity(beforeStop, initial);
  const stopResponse = await requestCoordinator(beforeStop, "stop", beforeStop.lifecycle_id
    ? { expected_lifecycle_id: beforeStop.lifecycle_id }
    : {});
  validateResponse(stopResponse, beforeStop, projectRoot, runtime, "stop");

  const deadline = Date.now() + STOP_TIMEOUT_MS;
  while (Date.now() < deadline) {
    if (!processMayBeAlive(expectedPid) && !fs.existsSync(statePath)) {
      process.stdout.write(`[STOPPED] Package-owned legacy watcher handoff completed for PID ${expectedPid}.\n`);
      return;
    }
    await delay(100);
  }
  throw new Error(`Legacy coordinator PID ${expectedPid} did not stop cleanly.`);
}

function parseArgs(args) {
  const result = {};
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (!argument.startsWith("--")) {
      throw new Error(`Unexpected argument: ${argument}`);
    }
    const value = args[index + 1];
    if (value === undefined || value.startsWith("--")) {
      throw new Error(`Missing value for ${argument}`);
    }
    const key = argument.slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase());
    if (Object.hasOwn(result, key)) {
      throw new Error(`Duplicate argument: ${argument}`);
    }
    result[key] = value;
    index += 1;
  }
  return result;
}

function requireOption(name) {
  const value = String(options[name] ?? "").trim();
  if (!value) {
    throw new Error(`--${name.replace(/[A-Z]/g, (letter) => `-${letter.toLowerCase()}`)} is required.`);
  }
  return value;
}

function parsePositiveInteger(value, label) {
  if (!/^[0-9]+$/.test(String(value))) {
    throw new Error(`${label} is invalid.`);
  }
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed <= 0) {
    throw new Error(`${label} is invalid.`);
  }
  return parsed;
}

function readValidatedState(statePath, projectRoot, runtime, expectedPid, expectedStateSha256) {
  const bytes = readBoundedFile(statePath);
  if (expectedStateSha256 && sha256(bytes) !== expectedStateSha256) {
    throw new Error("Legacy coordinator state changed after Package-owned preflight.");
  }
  let state;
  try {
    state = JSON.parse(bytes.toString("utf8"));
  } catch (error) {
    throw new Error(`Legacy coordinator state is invalid JSON: ${error.message}`);
  }
  const validSchema = state?.schema_version === 1 || state?.schema_version === 2;
  const validExclusive = typeof state?.exclusive_lifecycle === "boolean";
  const validLifecycle = state?.lifecycle_id === null
    || state?.lifecycle_id === undefined
    || (typeof state.lifecycle_id === "string" && /^[A-Za-z0-9._-]{1,128}$/.test(state.lifecycle_id));
  if (!validSchema
      || state?.coordinator_pid !== expectedPid
      || normalizePath(state?.root) !== normalizePath(projectRoot)
      || normalizePath(state?.runtime) !== normalizePath(runtime)
      || state?.pipe_name !== createPipeName(projectRoot, runtime)
      || typeof state?.auth_token !== "string"
      || !/^[0-9a-f]{48}$/i.test(state.auth_token)
      || !validExclusive
      || !validLifecycle
      || (state?.exclusive_lifecycle === true && !state?.lifecycle_id)) {
    throw new Error("Legacy coordinator state identity or authenticated Stop contract is invalid.");
  }
  return state;
}

function validateStableIdentity(actual, expected) {
  if (actual.coordinator_pid !== expected.coordinator_pid
      || actual.schema_version !== expected.schema_version
      || actual.pipe_name !== expected.pipe_name
      || actual.auth_token !== expected.auth_token
      || normalizePath(actual.root) !== normalizePath(expected.root)
      || normalizePath(actual.runtime) !== normalizePath(expected.runtime)
      || (actual.lifecycle_id ?? null) !== (expected.lifecycle_id ?? null)) {
    throw new Error("Legacy coordinator identity changed before Package-owned Stop.");
  }
}

function readBoundedFile(filePath) {
  const stat = fs.statSync(filePath);
  if (!stat.isFile() || stat.size <= 0 || stat.size > MAX_STATE_BYTES) {
    throw new Error(`Legacy coordinator state is not a bounded file: ${filePath}`);
  }
  return fs.readFileSync(filePath);
}

function validateResponse(response, expected, projectRoot, runtime, label) {
  const state = response?.status;
  if (response?.ok !== true
      || state?.coordinator_pid !== expected.coordinator_pid
      || state?.schema_version !== expected.schema_version
      || normalizePath(state?.root) !== normalizePath(projectRoot)
      || normalizePath(state?.runtime) !== normalizePath(runtime)
      || (expected.lifecycle_id ?? null) !== (state?.lifecycle_id ?? null)
      || expected.exclusive_lifecycle !== state?.exclusive_lifecycle) {
    throw new Error(`Legacy coordinator ${label} response changed or omitted its validated identity.`);
  }
}

function requestCoordinator(state, command, extra = {}) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection(state.pipe_name);
    let settled = false;
    let buffer = "";
    const finish = (error, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      socket.destroy();
      if (error) reject(error);
      else resolve(value);
    };
    const timer = setTimeout(
      () => finish(new Error(`Legacy coordinator ${command} request timed out.`)),
      IPC_TIMEOUT_MS);
    socket.setEncoding("utf8");
    socket.on("connect", () => {
      socket.write(`${JSON.stringify({ auth_token: state.auth_token, command, ...extra })}\n`);
    });
    socket.on("data", (chunk) => {
      buffer += chunk;
      if (Buffer.byteLength(buffer, "utf8") > MAX_STATE_BYTES) {
        finish(new Error(`Legacy coordinator ${command} response exceeded the bounded size.`));
        return;
      }
      const newline = buffer.indexOf("\n");
      if (newline < 0) return;
      try {
        finish(null, JSON.parse(buffer.slice(0, newline)));
      } catch (error) {
        finish(new Error(`Legacy coordinator ${command} response is invalid JSON: ${error.message}`));
      }
    });
    socket.on("error", (error) => finish(new Error(`Legacy coordinator ${command} request failed: ${error.message}`)));
    socket.on("end", () => {
      if (!settled) finish(new Error(`Legacy coordinator ${command} response ended before one JSON object.`));
    });
  });
}

function createPipeName(projectRoot, runtime) {
  const digest = crypto
    .createHash("sha256")
    .update(`${normalizePath(projectRoot)}\n${normalizePath(runtime)}`)
    .digest("hex")
    .slice(0, 20);
  return process.platform === "win32"
    ? `\\\\.\\pipe\\codedb-watch-${digest}`
    : path.join(runtime, `codedb-watch-${digest}.sock`);
}

function assertPathInside(targetPath, rootPath, label) {
  const relative = path.relative(rootPath, targetPath);
  if (relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== ".." && !path.isAbsolute(relative))) {
    return;
  }
  throw new Error(`${label} must stay inside the Unity project root.`);
}

function normalizePath(value) {
  const normalized = String(value ?? "").replace(/^\\\\\?\\/, "").replace(/\\/g, "/");
  return process.platform === "win32" ? normalized.toLowerCase() : normalized;
}

function sha256(bytes) {
  return crypto.createHash("sha256").update(bytes).digest("hex");
}

function processMayBeAlive(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return error.code === "EPERM";
  }
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

main().catch((error) => {
  process.stderr.write(`[BLOCKED] ${error.message}\n`);
  process.exitCode = 1;
});
