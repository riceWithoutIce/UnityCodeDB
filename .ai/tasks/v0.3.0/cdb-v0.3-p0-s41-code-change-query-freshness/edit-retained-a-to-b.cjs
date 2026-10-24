// Task helper only. --check never writes; consumer --apply needs a fresh grant.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const expectedA = '2827d0f71db580099a13daad9c301407adeed331c8e4d0aa5413dfcebe2ce11c';
const from = Buffer.from('CODEDB_S41_FRESHNESS_A_20261022');
const to = Buffer.from('CODEDB_S41_FRESHNESS_B_20261022');
let fd;
try {
  const [mode, input, ...extra] = process.argv.slice(2);
  if (!['--check', '--apply'].includes(mode) || !input || extra.length)
    throw new Error('USAGE: node edit-retained-a-to-b.cjs --check|--apply <probe-file>');
  const file = path.resolve(input);
  if (path.basename(file) !== 'CodeDBFreshnessProbeS41.cs') throw new Error('WRONG_PROBE_NAME');
  fd = fs.openSync(file, mode === '--check' ? 'r' : 'r+');
  const before = fs.readFileSync(fd);
  if (hash(before) !== expectedA) throw new Error('A_PREIMAGE_MISMATCH');
  const at = before.indexOf(from);
  if (at < 0 || before.indexOf(from, at + from.length) !== -1) throw new Error('MARKER_NOT_UNIQUE');
  const after = Buffer.concat([before.subarray(0, at), to, before.subarray(at + from.length)]);
  const result = {mode, before_sha256: hash(before), expected_b_sha256: hash(after), bytes: after.length, writes: 0};
  if (mode === '--apply') {
    if (fs.writeSync(fd, after, 0, after.length, 0) !== after.length) throw new Error('SHORT_WRITE_STOP_NO_RETRY');
    result.writes = 1;
    fs.closeSync(fd); fd = undefined;
    result.saved_at_utc = new Date().toISOString();
    if (!fs.readFileSync(file).equals(after)) throw new Error('POST_WRITE_MISMATCH_STOP_NO_RETRY');
    result.status = 'B_SAVED';
  } else result.status = 'CHECK_PASS_NO_WRITE';
  console.log(JSON.stringify(result));
} catch (error) {
  console.log(JSON.stringify({status: 'STOPPED_NO_RETRY', error: error.message}));
  process.exitCode = 1;
} finally {
  if (fd !== undefined) fs.closeSync(fd);
}
