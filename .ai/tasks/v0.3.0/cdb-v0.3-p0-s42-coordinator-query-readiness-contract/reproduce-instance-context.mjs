import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import vm from 'node:vm';
import {EventEmitter} from 'node:events';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const task=path.dirname(fileURLToPath(import.meta.url));
const repo=path.resolve(task,'../../../..');
const sourceRoot=path.join(repo,'.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract/com.rice.ai-codedb');
const sources={supervisor:path.join(sourceRoot,'Tools~/codedb-project-supervisor.mjs'),
 common:path.join(sourceRoot,'Payload~/Generations/poc.44/scripts/codedb-project-common.ps1'),
 watch:path.join(sourceRoot,'Payload~/Generations/poc.44/scripts/manage-codedb-project-watch.ps1')};
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const source=fs.readFileSync(sources.supervisor,'utf8');
assert.equal(hash(source),'ac341b039f0840735801dc991e42a9ba7e313df0c82cca895d00dfc08a104fba');
const run=path.join(repo,'.artifacts/tests/s42-instance-context',new Date().toISOString().replace(/[:.]/g,'-'));
assert.equal(fs.existsSync(run),false);fs.mkdirSync(run,{recursive:true});
const project=path.join(run,'project');
const instance=path.join(project,'AIWork/.runtime/codedb/instances','a'.repeat(32));
const foreign=path.join(project,'AIWork/.runtime/codedb/instances','b'.repeat(32));
const leaseRoot=path.join(instance,'watch/lifecycle/editor-leases');
fs.mkdirSync(leaseRoot,{recursive:true});fs.mkdirSync(foreign,{recursive:true});
const projectIdentity='sha256:'+hash(project.replaceAll('\\','/').toLowerCase());
const stamp=new Date().toISOString();
fs.writeFileSync(path.join(leaseRoot,'fixture-session.json'),JSON.stringify({schema_version:1,managed_by:'com.rice.ai-codedb',
 session_id:'fixture-session',editor_pid:12345,process_start_ticks:'123456789',project_root:project,project_identity:projectIdentity,
 created_at_utc:stamp,heartbeat_at_utc:stamp}));
const extract=name=>{const lines=source.split(/\r?\n/);const start=lines.findIndex(l=>new RegExp(`^(?:async )?function ${name}\\(`).test(l));
 const end=lines.findIndex((l,i)=>i>start&&/^(?:async )?function |^await main\(/.test(l));assert.ok(start>=0&&end>start,name);return lines.slice(start,end).join('\n');};
const cases=[];
for(const [name,inheritedInstance] of [['absent',null],['matching',instance],['foreign',foreign]]){
 let captured;let admissionCount=0,captureCount=0;
 // Deliberately controlled environment: no host environment secrets enter VM or output.
 const env={RICE_CODEDB_UNITY_ROOT:project,FIXTURE_UNRELATED:'preserve'};
 if(inheritedInstance)env.RICE_CODEDB_INSTANCE_ROOT=inheritedInstance;
 const sandbox={process:{platform:'win32',env},setTimeout,clearTimeout,
  prepareOperationChildEvidence:async()=>{admissionCount++;},queueChildEvidenceCapture:()=>{captureCount++;},
  spawn:(command,args,options)=>{
   assert.equal(command,'powershell.exe');assert.ok(args.includes('Stop'));
   assert.equal(args[args.indexOf('-ExpectedLifecycleId')+1],'fixture-lifecycle');
   captured={...options.env};
   const child=new EventEmitter();child.pid=999;child.stdout=new EventEmitter();child.stderr=new EventEmitter();
   child.kill=()=>{throw Error('FIXTURE_KILL_FORBIDDEN');};setImmediate(()=>child.emit('close',0,null));return child;
  }};
 const api=vm.runInNewContext(extract('runWatchManager')+'\n'+extract('runChild')+'\n({runWatchManager})',sandbox);
 const result=await api.runWatchManager({root:project,selectedInstance:{instanceRoot:instance},watchManager:'synthetic-watch.ps1'},
  'Stop',{expected_lifecycle_id:'fixture-lifecycle'},{});
 assert.equal(result.code,0);assert.equal(admissionCount,1);assert.equal(captureCount,1);
 assert.equal(captured.RICE_CODEDB_INSTANCE_ROOT??null,inheritedInstance);
 assert.equal(captured.FIXTURE_UNRELATED,'preserve');
 cases.push({name,capturedEnvironment:captured});
}
const input=path.join(run,'input.json');
fs.writeFileSync(input,JSON.stringify({project,selectedInstance:instance,projectIdentity,sources,cases}));
const probe=String.raw`param([string]$InputFile)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$fixture=Get-Content -LiteralPath $InputFile -Raw | ConvertFrom-Json
function Import-FixtureFunction([string]$Source,[string]$Name) {
 $tokens=$null;$errors=$null
 $ast=[System.Management.Automation.Language.Parser]::ParseFile($Source,[ref]$tokens,[ref]$errors)
 if($errors.Count -gt 0){throw 'SOURCE_PARSE_FAILED'}
 $nodes=@($ast.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name},$true))
 if($nodes.Count -ne 1){throw 'FUNCTION_EXTRACTION_FAILED'}
 return $nodes[0].Extent.Text
}
# Only function definitions are evaluated. A fixture file supplies PSScriptRoot;
# no original script entry point/imports run.
$functionFile=Join-Path (Split-Path -Parent $InputFile) 'consumer-functions.ps1'
$definitions=(Import-FixtureFunction $fixture.sources.common 'Get-ProjectCodedbContext')+[Environment]::NewLine+(Import-FixtureFunction $fixture.sources.watch 'Get-ActiveEditorSessionIds')
Set-Content -LiteralPath $functionFile -Value $definitions -Encoding UTF8
. $functionFile
function ConvertTo-CodedbProjectSlug { param([string]$Value) return 'fixture-project' }
function Assert-CodedbPathInside { param([string]$Path,[string]$Root,[string]$Label)
 if(-not $Path.StartsWith($Root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'FIXTURE_PATH_OUTSIDE_ROOT'} }
function Get-CodedbTextAdapterOutputContract { return [pscustomobject]@{RootRelativePath='adapter/text-index';LogsRelativePath='adapter/text-index/logs';TempRelativePath='adapter/text-index/tmp'} }
function Get-ProcessStartTicks { param([int]$ProcessId)
 if($ProcessId -ne 12345){throw 'UNEXPECTED_SYNTHETIC_PID'};return '123456789' }
$reports=@()
foreach($case in $fixture.cases){
 $env:RICE_CODEDB_UNITY_ROOT=$case.capturedEnvironment.RICE_CODEDB_UNITY_ROOT
 $property=$case.capturedEnvironment.PSObject.Properties['RICE_CODEDB_INSTANCE_ROOT']
 $env:RICE_CODEDB_INSTANCE_ROOT=if($null -eq $property){$null}else{[string]$property.Value}
 $context=Get-ProjectCodedbContext
 $projectIdentity=$fixture.projectIdentity
 $editorLeaseRoot=Join-Path $context.ProviderRoot 'watch/lifecycle/editor-leases'
 $sessions=@(Get-ActiveEditorSessionIds)
 $reports += [pscustomobject]@{name=$case.name;selected_instance_used=[string]::Equals($context.ProviderRoot,$fixture.selectedInstance,[StringComparison]::OrdinalIgnoreCase);session_count=$sessions.Count}
}
$reports | ConvertTo-Json -Depth 4 -Compress
`;
const probePath=path.join(run,'consumer-probe.ps1');fs.writeFileSync(probePath,probe);
const stdout=execFileSync('powershell.exe',['-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',probePath,'-InputFile',input],
 {encoding:'utf8',timeout:15000,windowsHide:true,maxBuffer:65536});
const consumer=JSON.parse(stdout.trim());
assert.equal(consumer.length,3);
for(const c of consumer){assert.equal(c.selected_instance_used,c.name==='matching');assert.equal(c.session_count,c.name==='matching'?1:0);}
const report={status:'REPRODUCED_CONTEXT_DEPENDENCE',evidence:'OFFLINE_FUNCTION_BOUNDARY',
 production_child_starts:0,consumer_fixture_powershell_invocations:1,live_process_probes:0,ipc_requests:0,
 selected_instance_only_has_synthetic_lease:true,
 cases:consumer,
 sources:Object.fromEntries(Object.entries(sources).map(([name,p])=>[name,{path:path.relative(repo,p).replaceAll('\\','/'),sha256:hash(fs.readFileSync(p))}])),
 limitations:['Synthetic process-start evidence','Controlled inherited environment, not historical child environment','No production repair or live retirement established']};
fs.writeFileSync(path.join(run,'result.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({result:path.relative(repo,path.join(run,'result.json')).replaceAll('\\','/'),...report},null,2));
