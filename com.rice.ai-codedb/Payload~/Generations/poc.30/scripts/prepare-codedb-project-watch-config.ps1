#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateRange(1, 10)]
    [int]$PollIntervalSeconds = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\codedb-project-common.ps1"

function Get-TomlSectionValue {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,
        [Parameter(Mandatory = $true)]
        [string]$Section,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $currentSection = ""
    $values = @()
    foreach ($line in $Lines) {
        if ($line -match '^\s*\[([^\]]+)\]\s*(?:#.*)?$') {
            $currentSection = $Matches[1]
            continue
        }
        if ([string]::Equals($currentSection, $Section, [StringComparison]::OrdinalIgnoreCase) -and
            $line -match '^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*$' -and
            [string]::Equals($Matches[1], $Key, [StringComparison]::OrdinalIgnoreCase)) {
            $values += $Matches[2]
        }
    }

    if ($values.Count -ne 1) {
        throw "Expected exactly one [$Section].$Key value, found $($values.Count)."
    }
    return $values[0]
}

function Set-TomlSectionValues {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,
        [Parameter(Mandatory = $true)]
        [string]$Section,
        [Parameter(Mandatory = $true)]
        [hashtable]$Values
    )

    $currentSection = ""
    $found = @{}
    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $Lines) {
        if ($line -match '^\s*\[([^\]]+)\]\s*(?:#.*)?$') {
            $currentSection = $Matches[1]
            $result.Add($line)
            continue
        }

        if ([string]::Equals($currentSection, $Section, [StringComparison]::OrdinalIgnoreCase) -and
            $line -match '^(\s*)([A-Za-z0-9_]+)\s*=') {
            $indent = $Matches[1]
            $key = $Matches[2]
            if ($Values.ContainsKey($key)) {
                if ($found.ContainsKey($key)) {
                    throw "Duplicate [$Section].$key value in provider config."
                }
                $result.Add("$indent$key = $($Values[$key])")
                $found[$key] = $true
                continue
            }
        }
        $result.Add($line)
    }

    foreach ($key in $Values.Keys) {
        if (-not $found.ContainsKey($key)) {
            throw "Missing [$Section].$key value in provider config."
        }
    }
    return $result.ToArray()
}

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
$providerPaths = Assert-ProjectCodedbProviderFiles -Context $context
Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths

$watchConfigPath = Join-Path $context.ProviderConfigRoot "codedb-mcp.watch.toml"
Assert-CodedbPathInside -Path $watchConfigPath -Root $context.ProviderRoot -Label "watch config"
$formalLines = [System.IO.File]::ReadAllLines($providerPaths.ConfigPath)
$formalWatchEnabled = Get-TomlSectionValue -Lines $formalLines -Section "watch" -Key "enabled"
if (-not [string]::Equals($formalWatchEnabled.Trim(), "false", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Formal provider config must remain watch-disabled before generating the opt-in watch config."
}

$watchLines = Set-TomlSectionValues -Lines $formalLines -Section "logging" -Values @{
    enabled = "true"
    file = '"' + $context.ProviderRuntimeRelativePath + '/logs/codedb-watch.log"'
    flush_interval_ms = "100"
}
$watchLines = Set-TomlSectionValues -Lines $watchLines -Section "watch" -Values @{
    enabled = "true"
    poll_interval_seconds = $PollIntervalSeconds.ToString()
}

$watchEnabled = Get-TomlSectionValue -Lines $watchLines -Section "watch" -Key "enabled"
$watchStorage = Get-TomlSectionValue -Lines $watchLines -Section "storage" -Key "dir"
if (-not [string]::Equals($watchEnabled.Trim(), "true", [StringComparison]::OrdinalIgnoreCase)) {
    throw "Generated watch config did not enable native watch."
}
$expectedIndex = $context.ProviderRuntimeRelativePath + "/index"
if ($watchStorage.IndexOf($expectedIndex, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
    throw "Generated watch config must use the formal project-local provider index."
}

[System.IO.File]::WriteAllLines($watchConfigPath, $watchLines, [System.Text.UTF8Encoding]::new($false))
$relativeFormal = ConvertTo-CodedbProjectRelativePath -Context $context -Path $providerPaths.ConfigPath
$relativeWatch = ConvertTo-CodedbProjectRelativePath -Context $context -Path $watchConfigPath
Write-Host "[OK] Formal provider config remains watch-disabled: $relativeFormal"
Write-Host "[OK] Generated opt-in watch config: $relativeWatch"
Write-Host "[OK] Watch poll interval: $PollIntervalSeconds second(s)."
