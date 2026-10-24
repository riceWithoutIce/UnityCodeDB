#requires -Version 5.1
[CmdletBinding()]
param([ValidateSet('Contract','Flow')][string]$Mode = 'Contract')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$package = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $package
$run = Join-Path $repo ('.artifacts/tests/s39-cwd-fix/' + $Mode + '-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($run)
$utf8 = [Text.UTF8Encoding]::new($false)
$cases = [Collections.Generic.List[string]]::new()
function Check([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw $Name }
    $cases.Add($Name)
}
function Save([string]$Path, [string]$Text) {
    [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Definitions([string]$Path, [string[]]$Names) {
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw "Source syntax: $Path" }
    foreach ($name in $Names) {
        $nodes=@($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.FunctionDefinitionAst] -and $_.Name -ceq $name })
        if ($nodes.Count -ne 1) { throw "Missing/ambiguous production function $name" }
        $nodes[0].Extent.Text
    }
}
$helper=Join-Path $package 'Payload~/AIWork/codedb/shared/codedb-mcp-registration-contract.ps1'
. $helper
$production=Join-Path $package 'Tools~/materialize-codedb-host-payload.ps1'
$names=@('Throw-MaterializerError','Assert-PathInside','Assert-NoReparsePoint','ConvertTo-AbsoluteChildPath','Get-TextSha256',
    'ConvertTo-MaterializerProjectSlug','Get-RepairMcpRegistrationValues','Get-RepairMcpRegistrationContent',
    'Skip-RepairTomlWhitespace','Assert-RepairTomlCharacterSet','Read-RepairTomlStringValue',
    'Assert-RepairTomlIntegerFitsInt64','Read-RepairTomlBareValue','Read-RepairTomlValue',
    'Get-RepairTomlValueInfo','Get-RepairMcpConfigPlan','Publish-RepairMcpConfig')
$definitions=@(Definitions $production $names) -join "`n"
$module=New-Module -ScriptBlock ([scriptblock]::Create(@'
param($helper)
Set-StrictMode -Version Latest
. $helper
$script:McpConfigRelativePath='.codex/config.toml'
$script:McpConfigBackupRelativePath='AIWork/.runtime/codedb/payload-materializer/mcp-config-backups'
# Only operation-ledger/fault-injection hooks are fixtures. The config planner,
# writer, path/drift checks, replacement and byte-exact backup are production.
function Add-MaterializerMutationScope { param($Scope) }
function Invoke-TestFaultAfterMutation {}
'@ + "`n" + $definitions)) -ArgumentList $helper
try {
    $project=Join-Path $run ('project ' + [char]0x5de5 + [char]0x7a0b + ' one')
    [void][IO.Directory]::CreateDirectory($project)
    $config=Join-Path $project '.codex/config.toml'
    if ($Mode -eq 'Contract') {
        $value=ConvertTo-CodedbMcpWorkingDirectoryValue -ProjectRoot $project
        Check ((ConvertFrom-Json -InputObject $value) -ceq $project.Replace('\','/')) 'Generated cwd decodes to the dynamic space/Unicode root'
        $apostropheRoot=$project+" ' more"
        Check ((ConvertFrom-Json -InputObject (ConvertTo-CodedbMcpWorkingDirectoryValue $apostropheRoot)) -ceq $apostropheRoot.Replace('\','/')) 'Apostrophe is encoded without hardcoding the root'
        foreach ($equivalent in @($value, ("'"+$project+"' # caller comment"), ('"'+$project.Replace('\','\\')+'"'), ('"'+$project.Replace('\','/').ToUpperInvariant()+'/./"'))) {
            Check (Test-CodedbMcpWorkingDirectoryValue $equivalent $project) ('Equivalent cwd accepted: '+$cases.Count)
        }
        foreach ($wrong in @('"."','".."','""','42',('"'+$project.Replace('\','/')+'-other"'))) {
            Check (-not (Test-CodedbMcpWorkingDirectoryValue $wrong $project)) ('Wrong/missing/nonstring cwd refused: '+$cases.Count)
        }
        $plan=& $module { param($root) Get-RepairMcpConfigPlan -ProjectRoot $root } $project
        $text=$utf8.GetString($plan.DesiredBytes)
        Check ($text.Contains('cwd = '+$value)) 'New registration uses the current root'
        Check ($text.Contains('args = ["AIWork/codedb/wrapper/codedb-project-wrapper.mjs", "--root", "."]')) 'Relative wrapper/root argv preserved'
        Save $config $text
        $repeat=& $module { param($root) Get-RepairMcpConfigPlan -ProjectRoot $root } $project
        Check $repeat.Current 'Repeated plan is idempotent'
        $literal=$text.Replace('cwd = '+$value, "cwd = '"+$project+"' # preserve me")
        Save $config $literal
        $equivalent=& $module { param($root) Get-RepairMcpConfigPlan -ProjectRoot $root } $project
        Check $equivalent.Current 'Equivalent existing TOML formatting is preserved byte-exactly'
    } else {
        $lock=[pscustomobject]@{Root=$run}
        $new=& $module { param($root,$lock) $p=Get-RepairMcpConfigPlan -ProjectRoot $root; Publish-RepairMcpConfig -Plan $p -ProjectRoot $root -Lock $lock } $project $lock
        Check (Test-Path -LiteralPath $config) 'Production publisher creates the missing registration'
        $base=[IO.File]::ReadAllText($config)
        $line='cwd = '+(ConvertTo-CodedbMcpWorkingDirectoryValue $project)
        $unrelated="`r`n[mcp_servers.other]`r`ncommand = '"+$project+"/client.exe'`r`ncustom = { value = 'keep' }`r`n"
        $legacy=($base.Replace($line,'cwd = "."').Replace("`n","`r`n"))+$unrelated
        # Retain a BOM and CRLF in the pre-image as well as unrelated config.
        $legacyBytes=[byte[]](@(0xef,0xbb,0xbf)+@($utf8.GetBytes($legacy)))
        [IO.File]::WriteAllBytes($config,$legacyBytes)
        $backup=& $module { param($root,$lock) $p=Get-RepairMcpConfigPlan -ProjectRoot $root; Publish-RepairMcpConfig -Plan $p -ProjectRoot $root -Lock $lock } $project $lock
        Check ([Convert]::ToBase64String([IO.File]::ReadAllBytes($backup)) -ceq [Convert]::ToBase64String($legacyBytes)) 'Legacy dot update retains byte-exact backup'
        $updated=[IO.File]::ReadAllText($config)
        Check ($updated.Contains($line) -and $updated.Contains($unrelated)) 'Legacy update changes cwd and preserves unrelated absolute paths'
        $repeat=& $module { param($root) Get-RepairMcpConfigPlan -ProjectRoot $root } $project
        Check $repeat.Current 'Updated registration is idempotent'
        $moved=Join-Path $run 'moved-project'
        [void][IO.Directory]::CreateDirectory((Join-Path $moved '.codex'))
        [IO.File]::WriteAllBytes((Join-Path $moved '.codex/config.toml'),[IO.File]::ReadAllBytes($config))
        $movePlan=& $module { param($root) Get-RepairMcpConfigPlan -ProjectRoot $root } $moved
        Check ($utf8.GetString($movePlan.DesiredBytes).Contains('cwd = '+(ConvertTo-CodedbMcpWorkingDirectoryValue $moved))) 'Moved project regenerates cwd from the new root'
        $driftPlan=& $module { param($root) Get-RepairMcpConfigPlan -ProjectRoot $root } $moved
        Save (Join-Path $moved '.codex/config.toml') 'intervening edit'
        $refused=$false
        try { & $module { param($p,$root,$lock) Publish-RepairMcpConfig -Plan $p -ProjectRoot $root -Lock $lock } $driftPlan $moved $lock } catch { $refused=$true }
        Check ($refused -and [IO.File]::ReadAllText((Join-Path $moved '.codex/config.toml')) -ceq 'intervening edit') 'Existing publication drift guard preserves intervening edits'

        # Run the unmodified successor validator/draft bodies. Only the common
        # context/Provider boundary is stubbed; no Provider or MCP is launched.
        $manifest=Get-Content (Join-Path $package 'Payload~/payload-manifest.json') -Raw | ConvertFrom-Json
        $scripts=Join-Path $run 'consumer/scripts'
        [void][IO.Directory]::CreateDirectory($scripts)
        [void][IO.Directory]::CreateDirectory((Join-Path $run 'consumer/shared'))
        Copy-Item -LiteralPath $helper -Destination (Join-Path $run 'consumer/shared/codedb-mcp-registration-contract.ps1')
        foreach ($name in @('validate-codedb-mcp-project-config.ps1','emit-codedb-mcp-registration-draft.ps1')) {
            Copy-Item -LiteralPath (Join-Path $package ('Payload~/Generations/'+$manifest.generation_id+'/scripts/'+$name)) -Destination (Join-Path $scripts $name)
        }
        $ctx=[ordered]@{UnityRoot=$project;ProviderName='codedb-observed';ProjectSlug='observed';BootstrapRoot=(Join-Path $project 'AIWork/codedb');CodedbRoot=(Join-Path $project 'AIWork/codedb');WrapperScriptPath=(Join-Path $project 'AIWork/codedb/wrapper/codedb-project-wrapper.mjs');TextAdapterManifestPath=(Join-Path $project 'adapter.json')}
        Save $ctx.WrapperScriptPath '// fixture only'
        Save $ctx.TextAdapterManifestPath '{}'
        Save (Join-Path $scripts 'context.json') ($ctx|ConvertTo-Json)
        Save (Join-Path $scripts 'codedb-project-common.ps1') @'
$script:fixtureContext=Get-Content (Join-Path $PSScriptRoot 'context.json') -Encoding UTF8 -Raw|ConvertFrom-Json
function Get-ProjectCodedbContext { $script:fixtureContext }
function Assert-CodedbUnityProject { param($Context) }
function Assert-CodedbPathInside { param($Path,$Root,$Label) }
function New-ProjectCodedbRuntime { param($Context) }
function Test-ProjectCodedbRuntimeFileOperations { param($Context) }
function Get-ProjectCodedbProviderPaths { param($Context) [pscustomobject]@{ExecutablePath=(Join-Path $Context.UnityRoot 'provider.exe');ConfigPath=(Join-Path $Context.UnityRoot 'provider.json')} }
function Assert-ProjectCodedbProviderFiles { param($Context) Get-ProjectCodedbProviderPaths $Context }
function Assert-ProjectCodedbRuntimeConfig { param($Context,$ProviderPaths) }
function ConvertTo-CodedbProjectRelativePath { param($Context,$Path) $Path.Substring($Context.UnityRoot.Length+1).Replace('\','/') }
function ConvertTo-CodedbDisplayPath { param($Context,$Path) ConvertTo-CodedbProjectRelativePath $Context $Path }
'@
        $powershell=(Get-Process -Id $PID).Path
        function Consumer([string]$Name,[int]$Expected) {
            $output=@(& $powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts $Name) 2>&1)
            $code=$LASTEXITCODE
            Save (Join-Path $run ($cases.Count.ToString()+'-'+$Name+'.log')) ($output -join "`n")
            Check ($code -eq $Expected) ($Name+' exit '+$Expected+' case '+$cases.Count)
            return ($output -join "`n")
        }
        $targetHeader=[regex]::Match($updated,'(?m)^\[mcp_servers\.[^\]]+\]').Value
        $valid=$updated.Replace($targetHeader,'[mcp_servers.codedb-observed]')
        Save $config $valid
        $null=Consumer 'validate-codedb-mcp-project-config.ps1' 0
        Save $config ($valid.Replace($line,'cwd = "."'))
        $null=Consumer 'validate-codedb-mcp-project-config.ps1' 1
        Save $config ($valid.Replace($line,'cwd = '+(ConvertTo-CodedbMcpWorkingDirectoryValue $moved)))
        $null=Consumer 'validate-codedb-mcp-project-config.ps1' 1
        Save $config ($valid -replace '(?m)^cwd[^\r\n]*\r?\n','')
        $null=Consumer 'validate-codedb-mcp-project-config.ps1' 1
        Save $config ($valid.Replace($line,"cwd = '"+$project+"' # equivalent"))
        $null=Consumer 'validate-codedb-mcp-project-config.ps1' 0
        Save $config $valid
        $before=[IO.File]::ReadAllText($config)
        $draft=Consumer 'emit-codedb-mcp-registration-draft.ps1' 0
        Check ($draft.Contains($line) -and [IO.File]::ReadAllText($config) -ceq $before) 'Production draft uses dynamic cwd and does not publish config'
        # The retained flat scripts have the same cwd contract, with their
        # existing CodedbRoot compatibility layout instead of BootstrapRoot.
        foreach ($name in @('validate-codedb-mcp-project-config.ps1','emit-codedb-mcp-registration-draft.ps1')) {
            Copy-Item -LiteralPath (Join-Path $package ('Payload~/AIWork/codedb/scripts/'+$name)) -Destination (Join-Path $scripts $name) -Force
        }
        $null=Consumer 'validate-codedb-mcp-project-config.ps1' 0
        $flatDraft=Consumer 'emit-codedb-mcp-registration-draft.ps1' 0
        Check ($flatDraft.Contains($line) -and [IO.File]::ReadAllText($config) -ceq $before) 'Flat draft/validator share the generated cwd contract'
    }
    $result=[ordered]@{status='PASS';mode=$Mode;evidence='CONTRACT_ISOLATED';powershell=$PSVersionTable.PSVersion.ToString();passed=$cases.Count;cases=$cases;real_mcp_calls=0;real_provider_starts=0}
    Save (Join-Path $run 'result.json') ($result|ConvertTo-Json -Depth 5)
    Write-Output ("[MCP_CWD] PASS mode=$Mode cases=$($cases.Count) evidence=CONTRACT_ISOLATED root="+$run.Substring($repo.Length+1).Replace('\','/'))
} catch {
    Save (Join-Path $run 'failure.txt') ($_|Out-String)
    throw
} finally { Remove-Module $module }
