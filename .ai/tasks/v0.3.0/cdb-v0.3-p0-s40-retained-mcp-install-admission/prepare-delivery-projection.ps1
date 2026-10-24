#requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$RepositoryRoot,[ValidatePattern('^delivery-projection-[a-z]+$')][string]$RunName='delivery-projection-a')
$ErrorActionPreference='Stop'
$taskRelative='.ai/tasks/v0.3.0/cdb-v0.3-p0-s40-retained-mcp-install-admission'
$candidate=Join-Path $RepositoryRoot '.worktrees/cdb-v0.3-p0-s40-retained-mcp-install-admission'
$output=Join-Path (Join-Path $RepositoryRoot '.artifacts/tests/s40-retained-mcp-install') $RunName
if(Test-Path -LiteralPath $output){throw 'Preserve previous projection'}
$snapshot=Get-Content -LiteralPath (Join-Path $RepositoryRoot ($taskRelative+'/SOURCE-SHA256.json')) -Raw|ConvertFrom-Json
foreach($source in $snapshot.sources){if((Get-FileHash -LiteralPath (Join-Path $candidate $source.path)).Hash.ToLowerInvariant() -cne $source.sha256){throw 'Candidate source drift'}}
if((& git -C $candidate rev-parse HEAD).Trim() -cne $snapshot.base){throw 'Base drift'}
if(@(& git -C $candidate diff --cached --name-only).Count){throw 'Real index must remain empty'}
$realIndex=(& git -C $candidate rev-parse --path-format=absolute --git-path index).Trim()
$indexBefore=if(Test-Path -LiteralPath $realIndex){(Get-FileHash -LiteralPath $realIndex).Hash}else{''}
$common=(& git -C $candidate rev-parse --path-format=absolute --git-common-dir).Trim()
[void][IO.Directory]::CreateDirectory($output)
[void][IO.Directory]::CreateDirectory((Join-Path $output 'objects'))
$saved=@{}
foreach($name in @('GIT_INDEX_FILE','GIT_OBJECT_DIRECTORY','GIT_ALTERNATE_OBJECT_DIRECTORIES')){$saved[$name]=[Environment]::GetEnvironmentVariable($name,'Process')}
try {
 $env:GIT_INDEX_FILE=Join-Path $output 'index'
 $env:GIT_OBJECT_DIRECTORY=Join-Path $output 'objects'
 $env:GIT_ALTERNATE_OBJECT_DIRECTORIES=Join-Path $common 'objects'
 & git -C $candidate read-tree $snapshot.base
 if($LASTEXITCODE -ne 0){throw 'Projection read-tree failed'}
 foreach($source in $snapshot.sources){
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
$indexAfter=if(Test-Path -LiteralPath $realIndex){(Get-FileHash -LiteralPath $realIndex).Hash}else{''}
if($indexAfter -cne $indexBefore){throw 'Real index changed'}
$stage=Join-Path $output 'stage'
[void][IO.Directory]::CreateDirectory($stage)
& tar -xf (Join-Path $output 'projection.tar') -C $stage
if($LASTEXITCODE -ne 0){throw 'Projection extraction failed'}
foreach($source in $snapshot.sources){if((Get-FileHash -LiteralPath (Join-Path $stage $source.path)).Hash.ToLowerInvariant() -cne $source.sha256){throw 'Archive candidate bytes changed'}}
$package=Join-Path $stage 'com.rice.ai-codedb'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $package 'Tests~/test-codedb-package-release-closure.ps1') -PackageRoot $package -AdmissionProjectRoot (Join-Path $output 'admission') *> (Join-Path $output 'closure.log')
if($LASTEXITCODE -ne 0){Get-Content (Join-Path $output 'closure.log');throw 'Projection closure failed'}
$files=@(Get-ChildItem -LiteralPath $package -Recurse -File)
$receipt=[ordered]@{evidence='PREPARATION_ONLY: isolated index/object tree; not a commit or formal export';tree=$tree;base=$snapshot.base;files=$files.Count;real_index_unchanged=$true;candidate_sources=$snapshot.sources;closure='PASS'}
[IO.File]::WriteAllText((Join-Path $output 'projection.json'),($receipt|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
Get-Content (Join-Path $output 'closure.log')
Write-Output ('PREPARATION PASS: projected Package files='+$files.Count+'; real index unchanged; no commit or external write')
