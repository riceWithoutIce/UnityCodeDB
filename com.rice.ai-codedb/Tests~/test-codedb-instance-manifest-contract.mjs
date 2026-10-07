#!/usr/bin/env node
// Test-owned pure decoder child of InstanceManifestContractOnly. No service imports.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { pathToFileURL } from 'node:url';

const [casesPath, stablePath, workerPath, canonicalHelperPath, generationHelperPath] = process.argv.slice(2);
assert.equal(process.argv.length, 7, 'Expected only fixture paths and two production caller paths.');
const tempRoot = path.resolve(os.tmpdir());
const relativeCases = path.relative(tempRoot, path.resolve(casesPath));
assert(!relativeCases.startsWith('..') && !path.isAbsolute(relativeCases), 'Cases must belong to a runtime-derived temporary root.');
const caseRoot = path.dirname(path.resolve(casesPath));
const cases = JSON.parse(fs.readFileSync(casesPath, 'utf8'));
assert.equal(cases.length, 26, 'Fixture case count drifted.');
assert(fs.readFileSync(canonicalHelperPath).equals(fs.readFileSync(generationHelperPath)), 'Generation helper differs from its canonical source.');
const stable = fs.readFileSync(stablePath, 'utf8');
const worker = fs.readFileSync(workerPath, 'utf8');
const binding = /import\s*\{\s*parseCodedbInstanceManifest\s*\}\s*from\s*["']\.\.\/shared\/codedb-instance-manifest-contract\.mjs["'];/;
assert(binding.test(stable) && binding.test(worker), 'Both real callers must import the tested decoder.');
assert(stable.includes('const instance = parseCodedbInstanceManifest(decodeStrictUtf8(instanceBytes, "selected CodeDB instance manifest"), "selected CodeDB instance manifest");'), 'Stable selection route bypasses the tested decoder.');
assert(worker.includes('const instance = parseCodedbInstanceManifest(instanceText, "CodeDB instance manifest");'), 'Worker route bypasses the tested decoder.');
assert(!stable.includes('const instance = parseStrictFlatJson(') && !worker.includes('const instance = parseStrictFlatJson('), 'An instance still uses the flat parser.');
let assertions = 0;
for (const helperPath of [canonicalHelperPath, generationHelperPath]) {
  const { parseCodedbInstanceManifest } = await import(pathToFileURL(path.resolve(helperPath)).href);
  for (const test of cases) {
    const relative = path.relative(caseRoot, path.resolve(test.path));
    assert(!relative.startsWith('..') && !path.isAbsolute(relative), 'Case escaped its owned fixture root.');
    const bytes = fs.readFileSync(test.path);
    const decode = () => parseCodedbInstanceManifest(new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes), test.name);
    if (test.accepted) {
      const value = decode();
      if (test.name === 'absent') assert(!Object.hasOwn(value, 'originating_action'));
      else if (test.name === 'null') assert.equal(value.originating_action, null);
      else {
        const [action, state] = test.name.split('-');
        assert.equal(value.originating_action.action, action);
        assert.equal(value.state, state);
        assert.match(value.originating_action.action_id, /^[0-9a-f]{32}$/);
        assert.match(value.originating_action.operation_id, /^[0-9a-f]{32}$/);
      }
    } else assert.throws(decode, undefined, test.name);
    assertions += 1;
  }
}
console.log(`[PASS] NodeInstanceManifestContract; cases=${cases.length}; helper_decodes=${assertions}; production_callers=2; service_children=0`);
