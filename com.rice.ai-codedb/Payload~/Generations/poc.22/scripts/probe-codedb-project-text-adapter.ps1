#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("All", "Status", "Search", "Read", "Stale")]
    [string]$Check = "All",
    [string]$Query = "",
    [switch]$Regex,
    [string]$Path = "",
    [int]$StartLine = 0,
    [int]$EndLine = 0,
    [ValidateRange(1, 200)]
    [int]$Limit = 20
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
$script:hasFailure = $false

$sourceRoots = @("Assets", "Packages", "ProjectSettings")
$extensions = @(".shader", ".hlsl", ".compute", ".cginc")
$excludePrefixes = @(
    "Library/",
    "Temp/",
    "Logs/",
    "UserSettings/",
    "obj/",
    "bin/",
    "Build/",
    "Builds/",
    "AIWork/.runtime/"
)
$excludeFragments = @(
    "/Library/PackageCache/",
    "/AIWork/.runtime/"
)

function Write-Fail {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[FAIL] $Message"
    $script:hasFailure = $true
}

function Write-NoHit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[NO HIT] $Message"
}

function Write-Hit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    Write-Host "[HIT] $Location"
}

function Assert-TextAdapterIndex {
    foreach ($path in @(
        $context.TextAdapterManifestPath,
        $context.TextAdapterFilesPath,
        $context.TextAdapterIndexPath
    )) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $relativePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $path
            throw "Missing text adapter index file: $relativePath. Run build-codedb-project-text-adapter.ps1 first."
        }
    }
}

function Get-TextAdapterManifest {
    Assert-TextAdapterIndex
    return Get-Content -LiteralPath $context.TextAdapterManifestPath -Raw | ConvertFrom-Json
}

function Get-TextAdapterFileRecords {
    Assert-TextAdapterIndex
    $records = @()
    foreach ($line in (Get-Content -LiteralPath $context.TextAdapterFilesPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $records += ($line | ConvertFrom-Json)
    }

    return @($records)
}

function ConvertTo-GitRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    $fullPath = [System.IO.Path]::GetFullPath($FullPath)
    $fullRoot = [System.IO.Path]::GetFullPath($context.RepoRoot)
    $fullRoot = $fullRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )

    if ([string]::Equals($fullPath, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return "."
    }

    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside Git repository: $fullPath"
    }

    return $fullPath.Substring($rootPrefix.Length).Replace("\", "/")
}

function Test-TextAdapterExtension {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Extension
    )

    foreach ($candidate in $extensions) {
        if ([string]::Equals($Extension, $candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Test-TextAdapterExcludedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $normalizedPath = $RelativePath.Replace("\", "/")
    foreach ($prefix in $excludePrefixes) {
        if ($normalizedPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    $wrappedPath = "/" + $normalizedPath
    foreach ($fragment in $excludeFragments) {
        if ($wrappedPath.IndexOf($fragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $true
        }
    }

    return $false
}

function Get-CurrentTextAdapterSourceFiles {
    $files = @()
    foreach ($root in $sourceRoots) {
        $rootPath = Join-Path $context.UnityRoot $root
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            continue
        }

        $files += Get-ChildItem -LiteralPath $rootPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { Test-TextAdapterExtension -Extension $_.Extension } |
            ForEach-Object {
                $relativePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $_.FullName
                if (-not (Test-TextAdapterExcludedPath -RelativePath $relativePath)) {
                    [pscustomobject]@{
                        File = $_
                        RelativePath = $relativePath
                    }
                }
            }
    }

    return @($files | Sort-Object RelativePath)
}

function Get-SourceFileLines {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $fullPath = Join-Path $context.UnityRoot $RelativePath
    Assert-CodedbPathInside -Path $fullPath -Root $context.UnityRoot -Label "adapter source"

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Source file is missing: $RelativePath"
    }

    return [System.IO.File]::ReadAllLines($fullPath)
}

function Get-FirstMeaningfulQuery {
    $records = @(Get-TextAdapterFileRecords)
    if (-not $records) {
        return ""
    }

    $record = $records[0]
    $lines = @(Get-SourceFileLines -RelativePath $record.path)
    $content = [string]::Join([System.Environment]::NewLine, $lines)

    if ($record.extension -eq ".shader") {
        $shaderMatch = [regex]::Match($content, 'Shader\s+"([^"]+)"')
        if ($shaderMatch.Success) {
            $shaderToken = [regex]::Match($shaderMatch.Groups[1].Value, '[A-Za-z_][A-Za-z0-9_]{2,}')
            if ($shaderToken.Success) {
                return $shaderToken.Value
            }
        }
    }

    $skipWords = @(
        "Shader",
        "Properties",
        "SubShader",
        "Pass",
        "Tags",
        "float",
        "float2",
        "float3",
        "float4",
        "half",
        "half2",
        "half3",
        "half4",
        "void",
        "return",
        "include",
        "define"
    )

    $matches = [regex]::Matches($content, '\b[A-Za-z_][A-Za-z0-9_]{2,}\b')
    foreach ($match in $matches) {
        $candidate = $match.Value
        $isSkipWord = $false
        foreach ($skipWord in $skipWords) {
            if ([string]::Equals($candidate, $skipWord, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isSkipWord = $true
                break
            }
        }

        if (-not $isSkipWord) {
            return $candidate
        }
    }

    return [System.IO.Path]::GetFileNameWithoutExtension($record.path)
}

function Find-TextAdapterMatches {
    param(
        [Parameter(Mandatory = $true)]
        [string]$QueryText,
        [bool]$UseRegex,
        [int]$MaxResults
    )

    Assert-TextAdapterIndex

    $compiledRegex = $null
    if ($UseRegex) {
        $compiledRegex = [regex]::new($QueryText, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    $matches = @()
    foreach ($line in (Get-Content -LiteralPath $context.TextAdapterIndexPath)) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $entry = $line | ConvertFrom-Json
        $text = Get-TextAdapterLineText -Entry $entry
        $matched = $false

        if ($UseRegex) {
            $matched = $compiledRegex.IsMatch($text)
        } elseif ($text.IndexOf($QueryText, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $matched = $true
        }

        if (-not $matched) {
            continue
        }

        $matches += [pscustomobject]@{
            Path = [string]$entry.path
            Line = [int]$entry.line
            Text = $text
        }

        if ($matches.Count -ge $MaxResults) {
            break
        }
    }

    return @($matches)
}

function Get-TextAdapterLineText {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )

    if ($Entry.PSObject.Properties.Name -contains "textBase64") {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String([string]$Entry.textBase64))
    }

    return [string]$Entry.text
}

function Invoke-TextAdapterStatus {
    try {
        $manifest = Get-TextAdapterManifest
        $relativeAdapter = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterRoot
        $gitRelativeAdapter = ConvertTo-GitRelativePath -FullPath $context.TextAdapterRoot

        if (-not (Test-CodedbPathGitIgnored -Context $context -RelativePath $gitRelativeAdapter)) {
            Write-Fail "$gitRelativeAdapter is not ignored by Git."
            return
        }

        Write-Host "[OK] Shader adapter index ready: $($manifest.fileCount) file(s), $($manifest.lineCount) line(s)."
        Write-Host "Adapter index: $relativeAdapter"
        Write-Host "Generated at: $($manifest.generatedAtUtc)"
    } catch {
        Write-Fail $_.Exception.Message
    }
}

function Invoke-TextAdapterSearch {
    $queryText = $Query.Trim()
    if ([string]::IsNullOrWhiteSpace($queryText)) {
        $queryText = Get-FirstMeaningfulQuery
    }

    if ([string]::IsNullOrWhiteSpace($queryText)) {
        Write-NoHit "Shader adapter has no indexed query candidate."
        return @()
    }

    try {
        $matches = @(Find-TextAdapterMatches -QueryText $queryText -UseRegex $Regex.IsPresent -MaxResults $Limit)
        if (-not $matches) {
            Write-NoHit "Shader adapter search found no hit for: $queryText"
            return @()
        }

        Write-Host "[OK] Shader adapter search found $($matches.Count) hit(s) for: $queryText"
        foreach ($match in $matches) {
            Write-Hit "$($match.Path):$($match.Line)"
        }

        return @($matches)
    } catch {
        Write-Fail $_.Exception.Message
        return @()
    }
}

function Invoke-TextAdapterRead {
    try {
        $targetPath = $Path.Trim()
        $targetLine = $StartLine

        if ([string]::IsNullOrWhiteSpace($targetPath)) {
            $queryText = $Query.Trim()
            if ([string]::IsNullOrWhiteSpace($queryText)) {
                $queryText = Get-FirstMeaningfulQuery
            }

            if ([string]::IsNullOrWhiteSpace($queryText)) {
                Write-NoHit "Shader adapter read found no indexed query candidate."
                return
            }

            $matches = @(Find-TextAdapterMatches -QueryText $queryText -UseRegex $Regex.IsPresent -MaxResults 1)
            if (-not $matches) {
                Write-NoHit "Shader adapter read found no hit for: $queryText"
                return
            }

            $targetPath = $matches[0].Path
            $targetLine = $matches[0].Line
        }

        $lines = @(Get-SourceFileLines -RelativePath $targetPath)
        if ($lines.Length -eq 0) {
            Write-NoHit "Shader adapter read found an empty file: $targetPath"
            return
        }

        if ($targetLine -le 0) {
            $targetLine = 1
        }

        $start = [Math]::Max(1, $targetLine - 3)
        if ($StartLine -gt 0) {
            $start = [Math]::Min($StartLine, $lines.Length)
        }

        $end = $EndLine
        if ($end -le 0) {
            $end = [Math]::Min($lines.Length, $start + 8)
        } else {
            $end = [Math]::Min($end, $lines.Length)
        }

        if ($end -lt $start) {
            $end = $start
        }

        Write-Host "[OK] Shader adapter read $targetPath lines $start-$end."
        Write-Hit "${targetPath}:$start"
        for ($lineNumber = $start; $lineNumber -le $end; $lineNumber++) {
            $displayLine = $lines[$lineNumber - 1]
            Write-Host ("{0,5}: {1}" -f $lineNumber, $displayLine)
        }
    } catch {
        Write-Fail $_.Exception.Message
    }
}

function Invoke-TextAdapterStaleCheck {
    try {
        $records = @(Get-TextAdapterFileRecords)
        $recordByPath = @{}
        foreach ($record in $records) {
            $recordByPath[[string]$record.path] = $record
        }

        $currentFiles = @(Get-CurrentTextAdapterSourceFiles)
        $currentByPath = @{}
        foreach ($entry in $currentFiles) {
            $currentByPath[$entry.RelativePath] = $entry.File
        }

        $staleItems = @()
        foreach ($entry in $currentFiles) {
            if (-not $recordByPath.ContainsKey($entry.RelativePath)) {
                $staleItems += "added $($entry.RelativePath)"
                continue
            }

            $currentHash = (Get-FileHash -LiteralPath $entry.File.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $indexedHash = [string]$recordByPath[$entry.RelativePath].sha256
            if (-not [string]::Equals($currentHash, $indexedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
                $staleItems += "changed $($entry.RelativePath)"
            }
        }

        foreach ($record in $records) {
            $recordPath = [string]$record.path
            if (-not $currentByPath.ContainsKey($recordPath)) {
                $staleItems += "missing $recordPath"
            }
        }

        if ($staleItems.Count -gt 0) {
            Write-Fail "Shader adapter index is stale: $($staleItems.Count) change(s)."
            foreach ($item in $staleItems) {
                Write-Hit $item
            }

            return
        }

        Write-Host "[OK] Shader adapter stale check passed for $($records.Count) file(s)."
    } catch {
        Write-Fail $_.Exception.Message
    }
}

switch ($Check) {
    "All" {
        Invoke-TextAdapterStatus
        Invoke-TextAdapterSearch | Out-Null
        Invoke-TextAdapterRead
        Invoke-TextAdapterStaleCheck
    }
    "Status" {
        Invoke-TextAdapterStatus
    }
    "Search" {
        Invoke-TextAdapterSearch | Out-Null
    }
    "Read" {
        Invoke-TextAdapterRead
    }
    "Stale" {
        Invoke-TextAdapterStaleCheck
    }
}

Write-Host "Shader/HLSL text adapter smoke completed: $Check."

if ($script:hasFailure) {
    exit 1
}

exit 0
