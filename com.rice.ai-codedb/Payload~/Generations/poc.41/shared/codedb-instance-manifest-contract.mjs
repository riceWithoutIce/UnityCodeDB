// Projection of the 2026-10-07 instance-manifest contract. Pure decoding only.
const INTEGER_FIELDS = new Set(['schema_version', 'payload_sequence', 'bootstrap_protocol']);
const STRING_FIELDS = new Set([
  'managed_by', 'project_identity', 'instance_id', 'instance_relative_path', 'state',
  'package_version', 'payload_version', 'generation_id', 'generation_relative_path',
  'generation_manifest_sha256', 'worker_relative_path', 'worker_sha256', 'created_at_utc', 'verified_at_utc'
]);
const REQUIRED_FIELDS = [...INTEGER_FIELDS, ...STRING_FIELDS];
const ALLOWED_FIELDS = new Set([...REQUIRED_FIELDS, 'originating_action']);

export function parseCodedbInstanceManifest(text, label = 'CodeDB instance manifest') {
  const fail = (detail) => { throw new Error(`[CHECK_FAILED] ${label} ${detail}`); };
  if (typeof text !== 'string' || Buffer.byteLength(text, 'utf8') === 0
      || Buffer.byteLength(text, 'utf8') > 128 * 1024 || text.charCodeAt(0) === 0xfeff) {
    fail('size or byte-order mark is invalid.');
  }
  let index = 0;
  const skip = () => { while (index < text.length && /[ \t\r\n]/.test(text[index])) index += 1; };
  const readString = () => {
    if (text[index] !== '"') fail('expected a JSON string.');
    const start = index++;
    let escaped = false;
    while (index < text.length) {
      const character = text[index++];
      if (character.charCodeAt(0) < 0x20) fail('contains a control character.');
      if (escaped) escaped = false;
      else if (character === '\\') escaped = true;
      else if (character === '"') {
        try { return JSON.parse(text.slice(start, index)); }
        catch (error) { fail(`contains invalid JSON: ${error.message}`); }
      }
    }
    fail('contains an unterminated string.');
  };
  const readValue = (depth) => {
    if (depth > 64) fail('exceeds the accepted JSON nesting depth.');
    skip();
    if (text[index] === '"') return readString();
    if (text[index] === '{') {
      index += 1;
      const value = Object.create(null);
      const seen = new Set();
      skip();
      if (text[index] === '}') { index += 1; return value; }
      while (index < text.length) {
        const name = readString();
        const key = name.toLowerCase();
        if (seen.has(key)) fail(`contains duplicate or case-ambiguous property ${name}.`);
        seen.add(key);
        skip();
        if (text[index++] !== ':') fail(`expected : after ${name}.`);
        value[name] = readValue(depth + 1);
        skip();
        if (text[index] === '}') { index += 1; return value; }
        if (text[index++] !== ',') fail('expected , between properties.');
        skip();
      }
      fail('contains an unclosed object.');
    }
    if (text.startsWith('null', index)) { index += 4; return null; }
    const match = text.slice(index).match(/^-?(?:0|[1-9][0-9]*)/);
    if (!match) fail('contains an unsupported JSON value.');
    const integer = Number(match[0]);
    if (!Number.isSafeInteger(integer)) fail('contains an integer outside the safe integer range.');
    index += match[0].length;
    return integer;
  };
  const value = readValue(1);
  skip();
  if (index !== text.length) fail('contains trailing JSON content.');
  if (value === null || typeof value !== 'object' || Array.isArray(value)) fail('must contain one JSON object.');
  if (Object.keys(value).some((name) => !ALLOWED_FIELDS.has(name))
      || REQUIRED_FIELDS.some((name) => !Object.prototype.hasOwnProperty.call(value, name))) {
    fail('properties do not match the reviewed schema.');
  }
  for (const name of STRING_FIELDS) if (typeof value[name] !== 'string') fail(`property ${name} must be a JSON string.`);
  for (const name of INTEGER_FIELDS) {
    if (!Number.isInteger(value[name]) || value[name] < -2147483648 || value[name] > 2147483647) {
      fail(`property ${name} must be a signed 32-bit JSON integer.`);
    }
  }
  const origin = value.originating_action;
  if (origin !== undefined && origin !== null) {
    const names = ['action', 'action_id', 'operation_id'];
    if (typeof origin !== 'object' || Array.isArray(origin) || Object.keys(origin).length !== 3
        || names.some((name) => typeof origin[name] !== 'string')
        || Object.keys(origin).some((name) => !names.includes(name))) {
      fail('originating_action properties do not match the reviewed schema.');
    }
    if (!['INSTALL', 'UPGRADE', 'REINSTALL'].includes(origin.action)
        || !/^[0-9a-f]{32}$/.test(origin.action_id) || !/^[0-9a-f]{32}$/.test(origin.operation_id)) {
      fail('originating_action identity is invalid.');
    }
  }
  return value;
}
