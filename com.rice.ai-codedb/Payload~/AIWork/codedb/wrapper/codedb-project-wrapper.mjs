#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { Worker } from "node:worker_threads";
import { fileURLToPath } from "node:url";

const MANAGED_BY = "com.rice.ai-codedb";
const EXPECTED_GENERATION = "poc.33";
const EXPECTED_WORKER_RELATIVE_PATH = "wrapper/codedb-project-instance-worker.mjs";
const MAX_CONTROL_BYTES = 64 * 1024;
const MAX_INSTANCE_BYTES = 128 * 1024;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let child = null;

try {
  const unityRoot = resolveUnityRoot(process.argv.slice(2));
  const selection = resolveSelectedInstance(unityRoot);
  process.chdir(unityRoot);
  child = new Worker(selection.workerPath, {
    argv: [
      "--root",
      ".",
      "--instance-root",
      selection.instanceRelativePath,
      ...(process.argv.includes("--print-context") ? ["--print-context"] : [])
    ],
    stdin: true,
    stdout: true,
    stderr: true
  });
  child.stdout.pipe(process.stdout);
  child.stderr.pipe(process.stderr);
  process.stdin.pipe(child.stdin);
  child.once("error", fail);
  child.once("exit", (code) => {
    process.exitCode = Number.isInteger(code) ? code : 1;
  });
} catch (error) {
  fail(error);
}

function fail(error) {
  const detail = error instanceof Error ? error.message : String(error);
  process.stderr.write(`${detail}\n`);
  process.exitCode = 1;
}

function resolveUnityRoot(args) {
  let assertedRoot;
  for (let index = 0; index < args.length; index += 1) {
    if (args[index] === "--root") {
      if (assertedRoot !== undefined || index + 1 >= args.length) {
        throw new Error("--root must be supplied at most once with one path assertion.");
      }
      assertedRoot = args[++index];
    } else if (args[index] !== "--print-context") {
      throw new Error(`Unsupported CodeDB wrapper argument: ${args[index]}`);
    }
  }
  const ownedRoot = validateUnityRoot(path.resolve(__dirname, "..", "..", ".."));
  if (assertedRoot === undefined) return ownedRoot;
  const requestedRoot = validateUnityRoot(path.resolve(process.cwd(), assertedRoot));
  if (!samePath(ownedRoot, requestedRoot)) {
    throw new Error(`--root must match the wrapper-owned Unity project: ${ownedRoot}`);
  }
  return ownedRoot;
}

function validateUnityRoot(candidate) {
  const root = fs.realpathSync(path.resolve(candidate));
  if (!fs.statSync(root).isDirectory()) throw new Error(`Invalid Unity project root: ${root}`);
  for (const marker of ["Assets", "Packages", "ProjectSettings"]) {
    const markerPath = path.join(root, marker);
    if (!fs.existsSync(markerPath) || !fs.statSync(markerPath).isDirectory()) {
      throw new Error(`Invalid Unity project root ${root}: missing ${marker}.`);
    }
  }
  return root;
}

function resolveSelectedInstance(unityRoot) {
  const runtimeRoot = path.join(unityRoot, "AIWork", ".runtime", "codedb");
  const controlRoot = path.join(runtimeRoot, "control");
  const instancesRoot = path.join(runtimeRoot, "instances");
  const generationsRoot = path.join(runtimeRoot, "host", "generations");
  const selectionPath = path.join(controlRoot, "current-instance.json");
  assertOwnedPath(selectionPath, runtimeRoot, "current instance selection", "file");
  const selectionBytes = readBoundedFile(selectionPath, MAX_CONTROL_BYTES, "current instance selection");
  const selection = parseStrictFlatJson(decodeStrictUtf8(selectionBytes, "current instance selection"), "current instance selection");
  const instanceId = requiredString(selection, "instance_id", "current instance selection");
  const instanceRelativePath = normalizeRelativePath(requiredString(selection, "instance_relative_path", "current instance selection"));
  const expectedInstanceRelativePath = `AIWork/.runtime/codedb/instances/${instanceId}`;
  const expectedProjectIdentity = createProjectIdentity(unityRoot);
  if (requiredInteger(selection, "schema_version", "current instance selection") !== 1
      || requiredString(selection, "managed_by", "current instance selection") !== MANAGED_BY
      || requiredString(selection, "project_identity", "current instance selection") !== expectedProjectIdentity
      || !/^[a-f0-9]{32}$/.test(instanceId)
      || instanceRelativePath !== expectedInstanceRelativePath
      || requiredString(selection, "generation_id", "current instance selection") !== EXPECTED_GENERATION) {
    throw new Error("[CHECK_FAILED] Current CodeDB instance selection identity is invalid.");
  }
  const instanceRoot = path.resolve(unityRoot, instanceRelativePath.replace(/\//g, path.sep));
  assertPathInside(instanceRoot, instancesRoot, "selected CodeDB instance");
  assertOwnedPath(instanceRoot, instancesRoot, "selected CodeDB instance", "directory");
  const instancePath = path.join(instanceRoot, "instance.json");
  assertOwnedPath(instancePath, instancesRoot, "selected CodeDB instance manifest", "file");
  const instanceBytes = readBoundedFile(instancePath, MAX_INSTANCE_BYTES, "selected CodeDB instance manifest");
  if (sha256(instanceBytes) !== requiredHash(selection, "instance_manifest_sha256", "current instance selection")) {
    throw new Error("[CHECK_FAILED] Selected CodeDB instance manifest hash does not match current-instance.json.");
  }
  const instance = parseStrictFlatJson(decodeStrictUtf8(instanceBytes, "selected CodeDB instance manifest"), "selected CodeDB instance manifest");
  const generationId = requiredString(instance, "generation_id", "selected CodeDB instance manifest");
  const generationRelativePath = normalizeRelativePath(requiredString(instance, "generation_relative_path", "selected CodeDB instance manifest"));
  const expectedGenerationRelativePath = `AIWork/.runtime/codedb/host/generations/${generationId}`;
  const workerRelativePath = normalizeRelativePath(requiredString(instance, "worker_relative_path", "selected CodeDB instance manifest"));
  if (requiredInteger(instance, "schema_version", "selected CodeDB instance manifest") !== 1
      || requiredString(instance, "managed_by", "selected CodeDB instance manifest") !== MANAGED_BY
      || requiredString(instance, "project_identity", "selected CodeDB instance manifest") !== expectedProjectIdentity
      || requiredString(instance, "instance_id", "selected CodeDB instance manifest") !== instanceId
      || requiredString(instance, "instance_relative_path", "selected CodeDB instance manifest") !== instanceRelativePath
      || requiredString(instance, "state", "selected CodeDB instance manifest") !== "READY"
      || generationId !== EXPECTED_GENERATION
      || generationRelativePath !== expectedGenerationRelativePath
      || workerRelativePath !== EXPECTED_WORKER_RELATIVE_PATH) {
    throw new Error("[CHECK_FAILED] Selected CodeDB instance manifest identity is invalid.");
  }
  const generationRoot = path.resolve(unityRoot, generationRelativePath.replace(/\//g, path.sep));
  assertPathInside(generationRoot, generationsRoot, "selected CodeDB generation");
  assertOwnedPath(generationRoot, generationsRoot, "selected CodeDB generation", "directory");
  const generationManifestPath = path.join(generationRoot, "generation-manifest.json");
  assertOwnedPath(generationManifestPath, generationRoot, "selected CodeDB generation manifest", "file");
  if (sha256(readBoundedFile(generationManifestPath, 1024 * 1024, "selected CodeDB generation manifest"))
      !== requiredHash(instance, "generation_manifest_sha256", "selected CodeDB instance manifest")) {
    throw new Error("[CHECK_FAILED] Selected CodeDB generation manifest hash is invalid.");
  }
  const workerPath = path.resolve(generationRoot, workerRelativePath.replace(/\//g, path.sep));
  assertPathInside(workerPath, generationRoot, "selected CodeDB instance worker");
  assertOwnedPath(workerPath, generationRoot, "selected CodeDB instance worker", "file");
  if (sha256(readBoundedFile(workerPath, 4 * 1024 * 1024, "selected CodeDB instance worker"))
      !== requiredHash(instance, "worker_sha256", "selected CodeDB instance manifest")) {
    throw new Error("[CHECK_FAILED] Selected CodeDB instance worker hash is invalid.");
  }
  return { instanceRelativePath, workerPath };
}

function assertOwnedPath(candidate, root, label, expectedType) {
  const fullCandidate = path.resolve(candidate);
  const fullRoot = path.resolve(root);
  assertPathInside(fullCandidate, fullRoot, label);
  let current = fullCandidate;
  while (true) {
    if (fs.existsSync(current) && fs.lstatSync(current).isSymbolicLink()) {
      throw new Error(`[CHECK_FAILED] ${label} traverses a symbolic link or junction: ${current}`);
    }
    if (samePath(current, fullRoot)) break;
    const parent = path.dirname(current);
    if (parent === current) throw new Error(`[CHECK_FAILED] ${label} escapes its owned root.`);
    current = parent;
  }
  if (!fs.existsSync(fullCandidate)) throw new Error(`[HOST_NOT_READY] ${label} is missing: ${fullCandidate}`);
  const stat = fs.statSync(fullCandidate);
  if ((expectedType === "file" && !stat.isFile()) || (expectedType === "directory" && !stat.isDirectory())) {
    throw new Error(`[CHECK_FAILED] ${label} has the wrong filesystem type.`);
  }
  const resolved = fs.realpathSync(fullCandidate);
  assertPathInside(resolved, fs.realpathSync(fullRoot), `${label} resolved path`);
}

function readBoundedFile(filePath, maximumBytes, label) {
  const bytes = fs.readFileSync(filePath);
  if (bytes.length === 0 || bytes.length > maximumBytes) throw new Error(`[CHECK_FAILED] ${label} size is outside the accepted range.`);
  return bytes;
}

function decodeStrictUtf8(bytes, label) {
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) {
    throw new Error(`[CHECK_FAILED] ${label} must be UTF-8 without a byte-order mark.`);
  }
  try { return new TextDecoder("utf-8", { fatal: true }).decode(bytes); }
  catch (error) { throw new Error(`[CHECK_FAILED] ${label} is not strict UTF-8: ${error.message}`); }
}

function parseStrictFlatJson(text, label) {
  let index = 0;
  const value = Object.create(null);
  const skip = () => { while (index < text.length && /[ \t\r\n]/.test(text[index])) index += 1; };
  const readString = () => {
    if (text[index] !== '"') throw new Error(`[CHECK_FAILED] ${label} expected a JSON string.`);
    const start = index++;
    let escaped = false;
    while (index < text.length) {
      const character = text[index++];
      if (character.charCodeAt(0) < 0x20) throw new Error(`[CHECK_FAILED] ${label} contains a control character.`);
      if (escaped) escaped = false;
      else if (character === "\\") escaped = true;
      else if (character === '"') {
        try { return JSON.parse(text.slice(start, index)); }
        catch (error) { throw new Error(`[CHECK_FAILED] ${label} contains invalid JSON: ${error.message}`); }
      }
    }
    throw new Error(`[CHECK_FAILED] ${label} contains an unterminated string.`);
  };
  skip();
  if (text[index++] !== "{") throw new Error(`[CHECK_FAILED] ${label} must contain one JSON object.`);
  skip();
  if (text[index] === "}") index += 1;
  else {
    while (index < text.length) {
      const name = readString();
      if (Object.prototype.hasOwnProperty.call(value, name)) throw new Error(`[CHECK_FAILED] ${label} contains duplicate property ${name}.`);
      skip();
      if (text[index++] !== ":") throw new Error(`[CHECK_FAILED] ${label} expected : after ${name}.`);
      skip();
      if (text[index] === '"') value[name] = readString();
      else {
        const match = text.slice(index).match(/^-?(?:0|[1-9][0-9]*)/);
        if (!match) throw new Error(`[CHECK_FAILED] ${label} property ${name} must be a string or integer.`);
        const integer = Number(match[0]);
        if (!Number.isSafeInteger(integer)) throw new Error(`[CHECK_FAILED] ${label} property ${name} is outside the safe integer range.`);
        value[name] = integer;
        index += match[0].length;
      }
      skip();
      if (text[index] === "}") { index += 1; break; }
      if (text[index++] !== ",") throw new Error(`[CHECK_FAILED] ${label} expected , between properties.`);
      skip();
    }
  }
  skip();
  if (index !== text.length) throw new Error(`[CHECK_FAILED] ${label} contains trailing JSON content.`);
  return value;
}

function requiredString(value, name, label) {
  if (typeof value[name] !== "string" || value[name].length === 0) throw new Error(`[CHECK_FAILED] ${label}.${name} must be a non-empty string.`);
  return value[name];
}
function requiredInteger(value, name, label) {
  if (!Number.isSafeInteger(value[name])) throw new Error(`[CHECK_FAILED] ${label}.${name} must be an integer.`);
  return value[name];
}
function requiredHash(value, name, label) {
  const hash = requiredString(value, name, label);
  if (!/^[0-9a-f]{64}$/.test(hash)) throw new Error(`[CHECK_FAILED] ${label}.${name} must be a lowercase SHA-256.`);
  return hash;
}
function normalizeRelativePath(value) {
  const text = String(value ?? "").replace(/\\/g, "/");
  if (!text || path.isAbsolute(text) || text.includes("\0")) throw new Error(`[CHECK_FAILED] Invalid relative path: ${text}`);
  const normalized = path.posix.normalize(text);
  if (normalized === ".." || normalized.startsWith("../")) throw new Error(`[CHECK_FAILED] Relative path escapes the project: ${text}`);
  return normalized;
}
function assertPathInside(candidate, root, label) {
  const relative = path.relative(path.resolve(root), path.resolve(candidate));
  if (relative === "") return;
  if (relative === ".." || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative)) {
    throw new Error(`[CHECK_FAILED] ${label} is outside its owned root.`);
  }
}
function createProjectIdentity(root) {
  const canonical = path.resolve(root).replace(/^\\\\\?\\/, "").replace(/\\/g, "/").replace(/\/+$/, "").toLowerCase();
  return `sha256:${crypto.createHash("sha256").update(canonical, "utf8").digest("hex")}`;
}
function sha256(bytes) { return crypto.createHash("sha256").update(bytes).digest("hex"); }
function samePath(left, right) {
  return path.resolve(left).replace(/[\\/]+$/, "").toLowerCase() === path.resolve(right).replace(/[\\/]+$/, "").toLowerCase();
}
