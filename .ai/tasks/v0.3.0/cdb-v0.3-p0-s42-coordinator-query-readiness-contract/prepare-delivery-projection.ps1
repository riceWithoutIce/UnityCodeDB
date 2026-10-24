#requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$RepositoryRoot,[ValidatePattern('^s42prep-[a-z0-9]+$')][string]$RunName='s42prep-a')
$ErrorActionPreference='Stop'
$candidate=Join-Path $RepositoryRoot '.worktrees/cdb-v0.3-p0-s42-coordinator-query-readiness-contract'
$output=Join-Path $RepositoryRoot ('.artifacts/tests/'+$RunName)
$base='186aacf0371ba64e47114306170b449dbca261c9'
$sources=@(
 @{path='com.rice.ai-codedb/Tools~/codedb-project-supervisor.mjs';sha256='ac341b039f0840735801dc991e42a9ba7e313df0c82cca895d00dfc08a104fba'},
 @{path='com.rice.ai-codedb/Tests~/test-codedb-project-supervisor.mjs';sha256='7bf20ca426419905b34bb3297af2f164be2946d50a3e95a9850de09fb77f468e'}
)
if(Test-Path -LiteralPath $output){throw 'Preserve previous projection'}
foreach($source in $sources){if((Get-FileHash -LiteralPath (Join-Path $candidate $source.path)).Hash.ToLowerInvariant() -cne $source.sha256){throw 'Candidate source drift'}}
if((& git -C $candidate rev-parse HEAD).Trim() -cne $base){throw 'Base drift'}
if(@(& git -C $candidate diff --cached --name-only).Count){throw 'Real index must remain empty'}
$changed=@(& git -C $candidate diff --name-only)
if(($changed|Sort-Object) -join "`n" -cne (($sources.path|Sort-Object) -join "`n")){throw 'Changed path scope differs'}
$realIndex=(& git -C $candidate rev-parse --path-format=absolute --git-path index).Trim()
$indexBefore=(Get-FileHash -LiteralPath $realIndex).Hash
$common=(& git -C $candidate rev-parse --path-format=absolute --git-common-dir).Trim()
[void][IO.Directory]::CreateDirectory($output)
[void][IO.Directory]::CreateDirectory((Join-Path $output 'objects'))
$saved=@{}
foreach($name in @('GIT_INDEX_FILE','GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES')){$saved[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try {
 $env:GIT_INDEX_FILE=Join-Path $output 'index'
 $env:GIT_OBJECT_DIRECTORY=Join-Path $output 'objects'
 $env:GIT_ALTERNATE_OBJECT_DIRECTORIES=Join-Path $common 'objects'
 & git -C $candidate read-tree $base
 if($LASTEXITCODE -ne 0){throw 'Projection read-tree failed'}
 foreach($source in $sources){
  $blob=(& git -C $candidate hash-object -w --no-filters -- (Join-Path $candidate $source.path)).Trim()
  if($LASTEXITCODE -ne 0){throw 'Raw blob projection failed'}
  & git -C $candidate update-index --add --cacheinfo ('100644,'+$blob+','+$source.path)
  if($LASTEXITCODE -ne 0){throw 'Projection index update failed'}
 }
 $tree=(& git -C $candidate write-tree).Trim()
 if($LASTEXITCODE -ne 0){throw 'Projection write-tree failed'}
 & git -C $candidate archive --format=tar ('--output='+(Join-Path $output 'projection.tar')) $tree -- com.rice.ai-codedb
 if($LASTEXITCODE -ne 0){throw 'Projection archive failed'}
} finally {
 foreach($name in $saved.Keys){[Environment]::SetEnvironmentVariable($name,$saved[$name],'Process')}
}
if((Get-FileHash -LiteralPath $realIndex).Hash -cne $indexBefore){throw 'Real index changed'}
$stage=Join-Path $output 'stage'
[void][IO.Directory]::CreateDirectory($stage)
& tar -xf (Join-Path $output 'projection.tar') -C $stage
if($LASTEXITCODE -ne 0){throw 'Projection extraction failed'}
foreach($source in $sources){if((Get-FileHash -LiteralPath (Join-Path $stage $source.path)).Hash.ToLowerInvariant() -cne $source.sha256){throw 'Projected candidate bytes changed'}}
$package=Join-Path $stage 'com.rice.ai-codedb'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $package 'Tests~/test-codedb-package-release-closure.ps1') -PackageRoot $package -AdmissionProjectRoot (Join-Path $output 'admission') *> (Join-Path $output 'closure.log')
if($LASTEXITCODE -ne 0){Get-Content (Join-Path $output 'closure.log');throw 'Projection closure failed'}
foreach($fixture in @(@{flag='--query-readiness-contract-fixture';root='s42-readiness/projection-a';log='readiness.log'},@{flag='--s32-disposition-fixture';root='s32-install/projection-a';log='disposition.log'})){
 & node (Join-Path $package 'Tests~/test-codedb-project-supervisor.mjs') $fixture.flag (Join-Path $stage ('.artifacts/tests/'+$fixture.root)) *> (Join-Path $output $fixture.log)
 if($LASTEXITCODE -ne 0){Get-Content (Join-Path $output $fixture.log);throw 'Projected focused fixture failed'}
}
$files=@(Get-ChildItem -LiteralPath $package -Recurse -File)
$inventory=@($files|ForEach-Object{@{path=$_.FullName.Substring($package.Length+1).Replace('\','/');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()}})
[IO.File]::WriteAllText((Join-Path $output 'inventory.json'),($inventory|ConvertTo-Json -Depth 4),[Text.UTF8Encoding]::new($false))
$receipt=[ordered]@{evidence='PREPARATION_ONLY: isolated index/object tree; not a commit or formal export';tree=$tree;base=$base;files=$files.Count;real_index_unchanged=$true;candidate_sources=$sources;closure='PASS';readiness='PASS';disposition='PASS'}
[IO.File]::WriteAllText((Join-Path $output 'projection.json'),($receipt|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
Get-Content (Join-Path $output 'closure.log')
Get-Content (Join-Path $output 'readiness.log')
Get-Content (Join-Path $output 'disposition.log')
Write-Output ('PREPARATION PASS: tree='+$tree+'; files='+$files.Count+'; real index unchanged; no commit or consumer mutation')
