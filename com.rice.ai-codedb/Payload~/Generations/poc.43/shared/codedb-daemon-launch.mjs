import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { execFile, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const nativeRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../native/win-x64");

// This returns creation evidence only, never a service-readiness decision.
export async function launchCodedbDaemon(executable, args, cwd, env = process.env) {
  if (process.platform !== "win32") {
    const child = spawn(executable, args, { cwd, env, detached: true, stdio: "ignore", windowsHide: true });
    await new Promise((resolve, reject) => { child.once("spawn", resolve); child.once("error", reject); });
    child.unref();
    return { pid: child.pid };
  }
  if (process.arch !== "x64") {
    throw new Error(`CodeDB daemon launcher requires Windows x64; current Node architecture is ${process.arch}.`);
  }
  const launcher = path.join(nativeRoot, "codedb-daemon-launch.exe");
  try {
    const manifest = JSON.parse(fs.readFileSync(path.join(nativeRoot, "build-manifest.json"), "utf8"));
    const binary = fs.readFileSync(launcher);
    const pe = binary.length >= 64 ? binary.readUInt32LE(60) : -1;
    if (manifest.schema_version !== 1 || manifest.managed_by !== "com.rice.ai-codedb"
        || manifest.platform !== "win32" || manifest.architecture !== "x64"
        || manifest.binary_sha256 !== crypto.createHash("sha256").update(binary).digest("hex")
        || pe < 0 || pe + 6 > binary.length || binary.readUInt32LE(pe) !== 0x4550
        || binary.readUInt16LE(pe + 4) !== 0x8664) {
      throw new Error("binary architecture or provenance hash mismatch");
    }
  } catch (error) {
    throw new Error(`CodeDB daemon launcher is missing or invalid: ${error.message}`);
  }
  const stdout = await new Promise((resolve, reject) => {
    execFile(launcher, [executable, cwd, ...args], {
      cwd, env, windowsHide: true, encoding: "utf8", timeout: 5000, maxBuffer: 8192
    }, (error, out, err) => {
      if (error) {
        reject(new Error(`CodeDB daemon creation failed (code=${error.code ?? "unknown"}, signal=${error.signal ?? "none"}): ${String(err || error.message).slice(0, 4096)}`));
      } else { resolve(out); }
    });
  });
  let created;
  try { created = JSON.parse(stdout); } catch { throw new Error("CodeDB daemon launcher returned invalid creation evidence; effects remain unproved."); }
  if (!Number.isInteger(created?.pid) || created.pid <= 0 || typeof created.time_observed !== "boolean"
      || !/^[0-9]+$/.test(created.creation_filetime)) {
    throw new Error("CodeDB daemon launcher returned incomplete creation evidence; effects remain unproved.");
  }
  return created;
}
