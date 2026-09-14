#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateRange(1, 200)]
    [int]$MaxItems = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\codedb-project-common.ps1"

$providerExcludedExtensions = @(".shader", ".hlsl", ".compute", ".cginc")
$defaultSourceRoots = @("Assets", "Packages", "ProjectSettings")
$defaultProviderExtensions = @(".cs", ".lua", ".js", ".jsx", ".mjs", ".cjs", ".ts", ".tsx", ".c", ".h", ".cc", ".cpp", ".cxx", ".hpp", ".hh", ".hxx")
$defaultExcludePaths = @(
    "Library/**",
    "Library/PackageCache/**",
    "Temp/**",
    "Logs/**",
    "UserSettings/**",
    "obj/**",
    "bin/**",
    "Build/**",
    "Builds/**",
    ".codedb/**",
    ".codedb-mcp/**",
    ".serena/**",
    ".codex_tmp/**",
    "AIWork/.runtime/**"
)
$defaultSkipDirs = @(
    ".git",
    ".hg",
    ".svn",
    ".vs",
    ".idea",
    ".gradle",
    "node_modules",
    "target",
    "dist",
    ".next",
    ".svelte-kit",
    "coverage",
    "out",
    ".codedb",
    ".codedb-mcp",
    ".serena",
    ".codex_tmp",
    "Library",
    "Temp",
    "Logs",
    "UserSettings",
    "obj",
    "bin",
    "Build",
    "Builds"
)
$adapterExtensions = @(".shader", ".hlsl", ".compute", ".cginc")
$timeTolerance = [System.TimeSpan]::FromSeconds(2)

function Get-TomlStringArray {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $pattern = "(?ms)^\s*$([System.Text.RegularExpressions.Regex]::Escape($Name))\s*=\s*\[(.*?)\]"
    $match = [System.Text.RegularExpressions.Regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        return @()
    }

    $values = @()
    foreach ($valueMatch in [System.Text.RegularExpressions.Regex]::Matches($match.Groups[1].Value, '"([^"]+)"')) {
        $values += [string]$valueMatch.Groups[1].Value
    }

    return $values
}

function ConvertTo-ExtensionSet {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions
    )

    $set = @{}
    foreach ($extension in $Extensions) {
        if ([string]::IsNullOrWhiteSpace($extension)) {
            continue
        }

        $normalized = $extension.Trim().ToLowerInvariant()
        if (-not $normalized.StartsWith(".", [System.StringComparison]::Ordinal)) {
            $normalized = "." + $normalized
        }

        $set[$normalized] = $true
    }

    return $set
}

function Test-ExtensionInSet {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Extension,
        [Parameter(Mandatory = $true)]
        [hashtable]$Set
    )

    return $Set.ContainsKey($Extension.ToLowerInvariant())
}

function Test-ExcludedExtension {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Extension,
        [Parameter(Mandatory = $true)]
        [string[]]$ExcludedExtensions
    )

    foreach ($excludedExtension in $ExcludedExtensions) {
        if ([string]::Equals($Extension, $excludedExtension, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Test-PathSkippedByDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SkipDirs
    )

    $segments = $RelativePath.Replace("\", "/").Split("/")
    foreach ($segment in $segments) {
        foreach ($skipDir in $SkipDirs) {
            if ([string]::Equals($segment, $skipDir, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    }

    return $false
}

function Test-PathExcludedByPattern {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string[]]$ExcludePaths
    )

    $normalizedPath = $RelativePath.Replace("\", "/")
    foreach ($excludePath in $ExcludePaths) {
        $normalizedPattern = $excludePath.Replace("\", "/")
        if ([string]::IsNullOrWhiteSpace($normalizedPattern)) {
            continue
        }

        if ($normalizedPattern.EndsWith("/**", [System.StringComparison]::Ordinal)) {
            $prefix = $normalizedPattern.Substring(0, $normalizedPattern.Length - 3).TrimEnd("/")
            if ([string]::Equals($normalizedPath, $prefix, [System.StringComparison]::OrdinalIgnoreCase) -or
                $normalizedPath.StartsWith($prefix + "/", [System.StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }

        if ($normalizedPath -like $normalizedPattern) {
            return $true
        }
    }

    return $false
}

function Get-SourceFiles {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [Parameter(Mandatory = $true)]
        [string[]]$Roots,
        [Parameter(Mandatory = $true)]
        [hashtable]$ExtensionSet,
        [Parameter(Mandatory = $true)]
        [string[]]$ExcludePaths,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$SkipDirs
    )

    $files = @()
    foreach ($root in $Roots) {
        if ([string]::IsNullOrWhiteSpace($root)) {
            continue
        }

        $rootPath = Join-Path $Context.UnityRoot $root
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            continue
        }

        $files += Get-ChildItem -LiteralPath $rootPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { Test-ExtensionInSet -Extension $_.Extension -Set $ExtensionSet } |
            ForEach-Object {
                $relativePath = ConvertTo-CodedbProjectRelativePath -Context $Context -Path $_.FullName
                if (-not (Test-PathSkippedByDirectory -RelativePath $relativePath -SkipDirs $SkipDirs) -and
                    -not (Test-PathExcludedByPattern -RelativePath $relativePath -ExcludePaths $ExcludePaths)) {
                    [pscustomobject]@{
                        File = $_
                        RelativePath = $relativePath
                    }
                }
            }
    }

    return @($files | Sort-Object RelativePath)
}

function Get-ProviderRefreshTimeUtc {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return $null
    }

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ($manifest.PSObject.Properties.Name -contains "created_unix_ms") {
        return [System.DateTimeOffset]::FromUnixTimeMilliseconds([int64]$manifest.created_unix_ms).UtcDateTime
    }

    return (Get-Item -LiteralPath $ManifestPath).LastWriteTimeUtc
}

function Get-AdapterManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return $null
    }

    return Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
}

function Get-AdapterRefreshTimeUtc {
    param(
        [AllowNull()]
        [object]$Manifest,
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    if ($null -eq $Manifest) {
        return $null
    }

    if ($Manifest.PSObject.Properties.Name -contains "generatedAtUtc") {
        return ([System.DateTimeOffset]::Parse([string]$Manifest.generatedAtUtc)).UtcDateTime
    }

    return (Get-Item -LiteralPath $ManifestPath).LastWriteTimeUtc
}

function Get-IndexedProviderExtensions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        return $defaultProviderExtensions
    }

    $config = Get-Content -LiteralPath $ConfigPath -Raw
    $extensions = @(Get-TomlStringArray -Content $config -Name "extensions")
    if ($extensions.Count -eq 0) {
        $extensions = $defaultProviderExtensions
    }

    $result = @()
    foreach ($extension in $extensions) {
        $normalized = $extension.Trim().ToLowerInvariant()
        if (-not $normalized.StartsWith(".", [System.StringComparison]::Ordinal)) {
            $normalized = "." + $normalized
        }

        if (-not (Test-ExcludedExtension -Extension $normalized -ExcludedExtensions $providerExcludedExtensions)) {
            $result += $normalized
        }
    }

    return $result
}

function Get-ProviderScanSettings {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        return [pscustomobject]@{
            Roots = $defaultSourceRoots
            ExcludePaths = $defaultExcludePaths
            SkipDirs = $defaultSkipDirs
        }
    }

    $config = Get-Content -LiteralPath $ConfigPath -Raw
    $roots = @(Get-TomlStringArray -Content $config -Name "root_paths")
    $excludePaths = @(Get-TomlStringArray -Content $config -Name "exclude_paths")
    $skipDirs = @(Get-TomlStringArray -Content $config -Name "skip_dirs")

    if ($roots.Count -eq 0) {
        $roots = $defaultSourceRoots
    }

    if ($excludePaths.Count -eq 0) {
        $excludePaths = $defaultExcludePaths
    }

    if ($skipDirs.Count -eq 0) {
        $skipDirs = $defaultSkipDirs
    }

    [pscustomobject]@{
        Roots = $roots
        ExcludePaths = $excludePaths
        SkipDirs = $skipDirs
    }
}

function New-FreshnessResult {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "STALE", "UNKNOWN")]
        [string]$State,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        [string[]]$Items = @()
    )

    [pscustomobject]@{
        State = $State
        Label = $Label
        Summary = $Summary
        Items = @($Items)
    }
}

function Test-ProviderFreshness {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $manifestPath = Join-Path $Context.ProviderIndexRoot "manifest.json"
    $refreshTimeUtc = Get-ProviderRefreshTimeUtc -ManifestPath $manifestPath
    if ($null -eq $refreshTimeUtc) {
        return New-FreshnessResult -State "UNKNOWN" -Label "Provider index" -Summary "Missing provider index manifest."
    }

    $scanSettings = Get-ProviderScanSettings -ConfigPath $ConfigPath
    $extensions = @(Get-IndexedProviderExtensions -ConfigPath $ConfigPath)
    $extensionSet = ConvertTo-ExtensionSet -Extensions $extensions
    $files = @(Get-SourceFiles -Context $Context -Roots $scanSettings.Roots -ExtensionSet $extensionSet -ExcludePaths $scanSettings.ExcludePaths -SkipDirs $scanSettings.SkipDirs)
    $staleFiles = @(
        $files |
            Where-Object { $_.File.LastWriteTimeUtc -gt $refreshTimeUtc.Add($timeTolerance) } |
            Sort-Object { $_.File.LastWriteTimeUtc } -Descending
    )

    $refreshText = $refreshTimeUtc.ToString("o")
    if ($staleFiles.Count -gt 0) {
        $items = @()
        foreach ($entry in @($staleFiles | Select-Object -First $MaxItems)) {
            $items += "provider changed $($entry.RelativePath) (modified $($entry.File.LastWriteTimeUtc.ToString("o")))"
        }

        return New-FreshnessResult -State "STALE" -Label "Provider index" -Summary "$($staleFiles.Count) provider-indexed file(s) are newer than $refreshText." -Items $items
    }

    return New-FreshnessResult -State "OK" -Label "Provider index" -Summary "$($files.Count) provider-indexed file(s) are not newer than $refreshText."
}

function Test-AdapterFreshness {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    $manifest = Get-AdapterManifest -ManifestPath $Context.TextAdapterManifestPath
    if ($null -eq $manifest) {
        return New-FreshnessResult -State "UNKNOWN" -Label "Shader adapter" -Summary "Missing Shader/HLSL adapter manifest."
    }

    $refreshTimeUtc = Get-AdapterRefreshTimeUtc -Manifest $manifest -ManifestPath $Context.TextAdapterManifestPath
    $roots = @($manifest.roots)
    if ($roots.Count -eq 0) {
        $roots = $defaultSourceRoots
    }

    $extensions = @($manifest.extensions)
    if ($extensions.Count -eq 0) {
        $extensions = $adapterExtensions
    }

    $extensionSet = ConvertTo-ExtensionSet -Extensions $extensions
    $files = @(Get-SourceFiles -Context $Context -Roots $roots -ExtensionSet $extensionSet -ExcludePaths $defaultExcludePaths -SkipDirs @())
    $recordByPath = @{}
    foreach ($record in @($manifest.files)) {
        $recordByPath[[string]$record.path] = $record
    }

    $currentByPath = @{}
    foreach ($entry in $files) {
        $currentByPath[$entry.RelativePath] = $entry
    }

    $staleItems = @()
    foreach ($entry in $files) {
        if (-not $recordByPath.ContainsKey($entry.RelativePath)) {
            $staleItems += "adapter added $($entry.RelativePath)"
            continue
        }

        $currentHash = (Get-FileHash -LiteralPath $entry.File.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $indexedHash = [string]$recordByPath[$entry.RelativePath].sha256
        if (-not [string]::Equals($currentHash, $indexedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
            $staleItems += "adapter changed $($entry.RelativePath)"
        }
    }

    foreach ($record in @($manifest.files)) {
        $recordPath = [string]$record.path
        if (-not $currentByPath.ContainsKey($recordPath)) {
            $staleItems += "adapter missing $recordPath"
        }
    }

    if ($staleItems.Count -gt 0) {
        return New-FreshnessResult -State "STALE" -Label "Shader adapter" -Summary "$($staleItems.Count) Shader/HLSL adapter file change(s) since $($refreshTimeUtc.ToString("o"))." -Items @($staleItems | Select-Object -First $MaxItems)
    }

    return New-FreshnessResult -State "OK" -Label "Shader adapter" -Summary "$($files.Count) Shader/HLSL file(s) match the adapter manifest from $($refreshTimeUtc.ToString("o"))."
}

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
$providerPaths = Get-ProjectCodedbProviderPaths -Context $context

$providerResult = Test-ProviderFreshness -Context $context -ConfigPath $providerPaths.ConfigPath
$adapterResult = Test-AdapterFreshness -Context $context
$results = @($providerResult, $adapterResult)

$overallState = "OK"
if (@($results | Where-Object { $_.State -eq "STALE" }).Count -gt 0) {
    $overallState = "STALE"
} elseif (@($results | Where-Object { $_.State -eq "UNKNOWN" }).Count -gt 0) {
    $overallState = "UNKNOWN"
}

switch ($overallState) {
    "OK" {
        Write-Host "[OK] codedb freshness check passed."
    }
    "STALE" {
        Write-Host "[STALE] codedb freshness check found stale index data."
    }
    "UNKNOWN" {
        Write-Host "[UNKNOWN] codedb freshness check could not determine full freshness."
    }
}

foreach ($result in $results) {
    Write-Host "$($result.Label): $($result.State) - $($result.Summary)"
    foreach ($item in @($result.Items)) {
        Write-Host "  - $item"
    }
}

Write-Host "Policy: this check is read-only. It does not refresh provider index data or rebuild the Shader/HLSL adapter."
