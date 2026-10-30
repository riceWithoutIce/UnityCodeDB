const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),cp=require('node:child_process');
const assert=(x,m)=>{if(!x)throw Error(m);},sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const root=fs.realpathSync(process.cwd()),test=fs.realpathSync(process.argv[2]);
assert(process.argv[3]==='--editor-closed-confirmed','Closed Editor confirmation required');
const commit='d84b5ca88b1adb57748b2988aa79cc9c7e6e8be9',short=commit.slice(0,7);
const family=path.join(root,'.artifacts/tests/cdb-v0.3-install-quarantine-admission');
const project=fs.realpathSync(path.join(test,'CodedbTest_3')),packages=fs.realpathSync(path.join(test,'Packages'));
const source=path.join(family,'export-'+short,'review/com.rice.ai-codedb');
const destParent=path.join(packages,short+'-v03-child-close'),dest=path.join(destParent,'com.rice.ai-codedb');
const ref='file:../../Packages/'+short+'-v03-child-close/com.rice.ai-codedb';
const receipt=path.join(family,'delivery-'+short+'-test3');
const inside=(p,b)=>p.toLowerCase().startsWith((b+path.sep).toLowerCase());
function noRedirect(p){for(let c=path.resolve(p);;c=path.dirname(c)){if(fs.existsSync(c))assert(!fs.lstatSync(c).isSymbolicLink(),'Redirected path');if(c===path.dirname(c))break;}}
for(const p of [project,packages,source,receipt])noRedirect(p);
assert(inside(project,test)&&inside(packages,test),'Outside test root');
assert(!fs.existsSync(destParent)&&!fs.existsSync(receipt),'Preserve existing delivery');
assert(!fs.existsSync(path.join(project,'Temp/UnityLockfile'))&&!fs.existsSync(path.join(project,'AIWork'))&&!fs.existsSync(path.join(project,'.codex')),'Project baseline changed');
assert(sha(fs.readFileSync(path.join(family,'export-'+short,'com.rice.ai-codedb.zip')))==='e096468b884c4fa8809377a9d6f14bb13da2ddf99b643ba99f327de24d2caa05','ZIP drift');
for(const [file,count] of [['producer-result.json',11],['PowerShell-01-result.json',54],['CSharp-01-result.json',27]]){
 const r=JSON.parse(fs.readFileSync(path.join(family,'09-exact-zip-child-closure',file)));
 assert(r.state==='PASS'&&(Array.isArray(r.checks)?r.checks.length:r.checks)===count,'Extracted contract gate missing');
}
const candidate=JSON.parse(fs.readFileSync(path.join(source,'package.json')));
assert(candidate.name==='com.rice.ai-codedb'&&candidate.version==='0.3.0-preview.5','Candidate identity drift');
function inventory(dir,prefix=''){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>{assert(!e.isSymbolicLink(),'Redirected Package entry');const rel=prefix+e.name,p=path.join(dir,e.name);return e.isDirectory()?inventory(p,rel+'/'):[{path:rel,sha256:sha(fs.readFileSync(p)),bytes:fs.statSync(p).size}];}).sort((a,b)=>a.path.localeCompare(b.path));}
const files=inventory(source);assert(files.length===673,'Inventory count changed');
const expected={'Packages/manifest.json':'5e9e9601dc2749a734a4e8f9bebfca0a3b12a8e6842784c5bf0575e0e26d15e1','Packages/packages-lock.json':'2e64daa498edb8d35f9773c45b069a853d71d3364f3d48b6e13c60a8b1f0edf6'};
const edits=Object.entries(expected).map(([rel,hash])=>{
 const absolute=path.join(project,rel),before=fs.readFileSync(absolute),text=before.toString('utf8'),json=JSON.parse(text);
 assert(sha(before)===hash&&!Object.hasOwn(json.dependencies,candidate.name),'Project reference preimage drift');
 const value=rel.endsWith('manifest.json')?ref:{version:ref,depth:0,source:'local',dependencies:{}};
 const nl=text.includes('\r\n')?'\r\n':'\n';
 const entry=JSON.stringify(value,null,2).replaceAll('\n',nl+'    ');
 const after=text.replace(/("dependencies"\s*:\s*\{)(\r?\n)/,(_,a,b)=>a+b+'    '+JSON.stringify(candidate.name)+': '+entry+','+b);
 assert(after!==text,'Cannot insert dependency');const parsed=JSON.parse(after);delete parsed.dependencies[candidate.name];
 assert(JSON.stringify(parsed)===JSON.stringify(json),'Unrelated dependency values changed');
 return {rel,absolute,before,after:Buffer.from(after)};
});
const versionPath=path.join(project,'ProjectSettings/ProjectVersion.txt'),versionHash=sha(fs.readFileSync(versionPath));
assert(versionHash==='b51164d22c4d2716ba8aee7f0b59d6b7dd0efa8552fd1db2a8c3b123fae3a1ec','Editor metadata drift');
fs.mkdirSync(receipt);const result={state:'RUNNING',commit,project:'<external-test-root>/CodedbTest_3',destination:'<external-test-root>/Packages/'+short+'-v03-child-close/com.rice.ai-codedb',reference:ref,steps:[]};
const save=()=>fs.writeFileSync(path.join(receipt,'result.json'),JSON.stringify(result,null,2));const step=s=>{result.steps.push(s);save();};save();
try{
 for(const e of edits){const backup=path.join(receipt,'preimages',e.rel);fs.mkdirSync(path.dirname(backup),{recursive:true});fs.writeFileSync(backup,e.before,{flag:'wx'});}step('preimages_saved');
 fs.mkdirSync(dest,{recursive:true});
 for(const f of files){const target=path.join(dest,f.path);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(source,f.path),target,fs.constants.COPYFILE_EXCL);assert(sha(fs.readFileSync(target))===f.sha256,'Copy mismatch: '+f.path);}
 assert(JSON.stringify(inventory(dest))===JSON.stringify(files),'Delivered inventory differs');step('673_copied_file_hashes_verified');
 for(const e of edits)assert(fs.readFileSync(e.absolute).equals(e.before),'Concurrent project change');
 for(const e of edits){step('write_pending:'+e.rel);fs.writeFileSync(e.absolute,e.after);assert(fs.readFileSync(e.absolute).equals(e.after),'Reference write mismatch');const j=JSON.parse(fs.readFileSync(e.absolute));const r=e.rel.endsWith('manifest.json')?j.dependencies[candidate.name]:j.dependencies[candidate.name].version;assert(r===ref&&fs.realpathSync(path.resolve(path.dirname(e.absolute),r.slice(5)))===fs.realpathSync(dest),'Reference binding mismatch');step('write_verified:'+e.rel);}
 assert(sha(fs.readFileSync(versionPath))===versionHash,'Project version changed');assert(!fs.existsSync(path.join(project,'AIWork'))&&!fs.existsSync(path.join(project,'.codex')),'Unexpected runtime/registration');
 result.state='DELIVERY_PASS';result.file_count=files.length;result.archive_sha256='e096468b884c4fa8809377a9d6f14bb13da2ddf99b643ba99f327de24d2caa05';result.references=edits.map(e=>({path:e.rel,before_sha256:sha(e.before),after_sha256:sha(e.after)}));
 fs.writeFileSync(path.join(receipt,'file-manifest.json'),JSON.stringify({commit,files},null,2));save();console.log(JSON.stringify(result,null,2));
}catch(error){result.state='DELIVERY_FAILED';result.error=String(error.message).replaceAll(root,'<repository-root>').replaceAll(test,'<external-test-root>');save();throw error;}
