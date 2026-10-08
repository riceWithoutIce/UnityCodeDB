import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import net from "node:net";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const self = fileURLToPath(import.meta.url);
const mode = process.argv[2];
const root = process.env.REPRO_SCENARIO_ROOT;
const save = (name, value) => fs.writeFileSync(path.join(root, name), JSON.stringify(value, null, 2));
const record = (role) => save(`${role}.json`, { pid: process.pid, token: process.env.REPRO_TOKEN, role, utc: new Date().toISOString() });

async function request(state, command, extra = {}) {
  return new Promise((resolve, reject) => {
    const socket = net.createConnection(state.pipe_name);
    let buffer = "";
    socket.setEncoding("utf8");
    socket.setTimeout(2000, () => socket.destroy(new Error("fixture IPC timeout")));
    socket.on("error", reject);
    socket.on("connect", () => socket.write(`${JSON.stringify({ command, auth_token: state.auth_token, ...extra })}\n`));
    socket.on("data", (chunk) => { buffer += chunk; if (buffer.includes("\n")) { socket.end(); resolve(JSON.parse(buffer.split("\n")[0])); } });
  });
}

if (mode === "cli") {
  record("cli");
  if (process.env.REPRO_SCENARIO === "retained") {
    const retainer = spawn(process.execPath, [self, "retainer"], { stdio: "inherit", detached: true, windowsHide: true });
    retainer.unref();
  }
  const args = [process.env.REPRO_COORDINATOR, "start", "--root", process.env.REPRO_PROJECT,
    "--provider", process.env.REPRO_PROVIDER, "--config", path.join(root, "provider.json"),
    "--runtime", path.join(process.env.REPRO_PROJECT, "watch/coordinator"),
    "--lifecycle-id", process.env.REPRO_TOKEN, "--require-new", "true", "--exclusive-lifecycle", "true",
    "--adapter-builder", path.join(process.env.REPRO_PROJECT, "builder.mjs"),
    "--adapter-manifest", path.join(process.env.REPRO_PROJECT, "adapter.json"), "--startup-timeout-ms", "10000"];
  const child = spawnSync(process.execPath, args, { stdio: "inherit", windowsHide: true });
  save("start-result.json", { pid: child.pid, exit: child.status, error: child.error?.message ?? null });
  process.exitCode = child.status ?? 1;
} else if (mode === "retainer") {
  record("retainer-ready");
  setTimeout(() => { save("retainer-exit.json", { pid: process.pid, reason: "self_expiry" }); process.exit(0); }, 35000);
} else if (mode === "guard") {
  record("guard");
  const began = Date.now();
  const interval = setInterval(() => {
    if (fs.existsSync(path.join(root, "guard-stop"))) { clearInterval(interval); return; }
    if (Date.now() - began > 50000) {
      const target = path.join(process.env.REPRO_PROJECT, "watch/lifecycle/desired-state.json");
      const desired = JSON.parse(fs.readFileSync(target, "utf8"));
      desired.desired_state = "disabled";
      fs.writeFileSync(target, JSON.stringify(desired));
      save("guard-expiry.json", { pid: process.pid });
      clearInterval(interval);
    }
  }, 100);
} else if (mode === "status") {
  const state = JSON.parse(fs.readFileSync(path.join(process.env.REPRO_PROJECT, "watch/coordinator/coordinator-state.json"), "utf8"));
  const rejected = await request(state, "status", { auth_token: "wrong-owned-fixture-token" });
  assert.equal(rejected.error_code, "UNAUTHORIZED");
  const response = await request(state, "status");
  assert.equal(response.ok, true);
  assert.equal(response.status.lifecycle_id, process.env.REPRO_TOKEN);
  assert.equal(response.status.provider_state, "ready");
  assert.equal(response.status.adapter_state, "watching");
  assert.equal(response.status.generation_id, process.env.REPRO_GENERATION);
  assert.equal(response.status.root.toLowerCase().replaceAll("\\", "/"), process.env.REPRO_PROJECT.toLowerCase().replaceAll("\\", "/"));
  const wrongStop = await request(state, "stop", { expected_lifecycle_id: "other-owned-fixture" });
  assert.equal(wrongStop.ok, false);
  save("authenticated-status.json", { response, rejected, wrongStop, utc: new Date().toISOString() });
} else if (mode === "stop") {
  const child = spawnSync(process.execPath, [process.env.REPRO_COORDINATOR, "stop", "--runtime",
    path.join(process.env.REPRO_PROJECT, "watch/coordinator"), "--expected-lifecycle-id", process.env.REPRO_TOKEN], { encoding: "utf8", windowsHide: true });
  save("cooperative-stop.json", { exit: child.status, stdout: child.stdout, stderr: child.stderr });
  process.exitCode = child.status ?? 1;
} else if (mode === "transfer-child") {
  save("transfer.json", { args: process.argv.slice(3), cwd: process.cwd(), env: process.env.CODEDB_LAUNCH_TEST_VALUE, pid: process.pid });
} else if (mode === "transfer") {
  const { launchCodedbDaemon } = await import(pathToFileURL(process.env.REPRO_CALLER));
  const args = ["space value", "中文", 'a"b', "trailing\\", "", 'slash\\"quote'];
  const created = await launchCodedbDaemon(process.execPath, [self, "transfer-child", ...args], root,
    { ...process.env, CODEDB_LAUNCH_TEST_VALUE: "child-only-value" });
  for (let i = 0; i < 100 && !fs.existsSync(path.join(root, "transfer.json")); i++) await new Promise((r) => setTimeout(r, 20));
  const observed = JSON.parse(fs.readFileSync(path.join(root, "transfer.json"), "utf8"));
  assert.deepEqual(observed.args, args); assert.equal(observed.cwd.toLowerCase(), root.toLowerCase());
  assert.equal(observed.env, "child-only-value"); assert.equal(observed.pid, created.pid);
  await assert.rejects(launchCodedbDaemon(path.join(root, "absent.exe"), [], root), /LAUNCH_CREATE_FAILED win32=2/);
  save("transfer-result.json", { passed: true, created });
} else { throw new Error(`Unknown fixture mode: ${mode}`); }
