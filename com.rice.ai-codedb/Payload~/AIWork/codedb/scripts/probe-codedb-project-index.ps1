#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("All", "RuntimeHealth", "UnityProject", "CSharpProbe", "LanguageProbe", "ShaderProbe", "LuaProbe", "JavaScriptProbe", "CustomProbe")]
    [string]$Check = "All",
    [ValidateSet("CSharp", "ShaderHlsl", "Lua", "JavaScript")]
    [string]$Language = "CSharp",
    [string]$Query = ""
)

Set-StrictMode -Version Latest
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
$providerPaths = Assert-ProjectCodedbProviderFiles -Context $context

function Write-Skip {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "[SKIP] $Message"
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

function Quote-WindowsArgument {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Argument
    )

    if ([string]::IsNullOrEmpty($Argument)) {
        return '""'
    }

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append('"')
    $backslashes = 0

    foreach ($character in $Argument.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }

        if ($character -eq '"') {
            [void]$builder.Append('\', $backslashes * 2 + 1)
            [void]$builder.Append('"')
            $backslashes = 0
            continue
        }

        if ($backslashes -gt 0) {
            [void]$builder.Append('\', $backslashes)
            $backslashes = 0
        }

        [void]$builder.Append($character)
    }

    if ($backslashes -gt 0) {
        [void]$builder.Append('\', $backslashes * 2)
    }

    [void]$builder.Append('"')
    return $builder.ToString()
}

function Invoke-CodedbProcess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [int]$TimeoutMilliseconds = 120000
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.Arguments = ($Arguments | ForEach-Object { Quote-WindowsArgument $_ }) -join " "
    $startInfo.WorkingDirectory = $context.UnityRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo

    try {
        if (-not $process.Start()) {
            throw "Failed to start codebase-mcp."
        }

        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        if (-not $process.WaitForExit($TimeoutMilliseconds)) {
            try {
                $process.Kill()
            } catch {
                # Keep the original timeout failure as the actionable error.
            }

            throw "codebase-mcp timed out after $TimeoutMilliseconds ms."
        }

        [pscustomobject]@{
            ExitCode = $process.ExitCode
            StandardOutput = $stdout
            StandardError = $stderr
        }
    } finally {
        $process.Dispose()
    }
}

function Invoke-CodedbTool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [hashtable]$Arguments
    )

    $argumentJson = $Arguments | ConvertTo-Json -Compress -Depth 8
    $activeConfigPath = Get-ProjectCodedbActiveReadConfigPath -Context $context
    $watchConfigPath = Join-Path $context.ProviderConfigRoot "codedb-mcp.watch.toml"
    $retryUntil = [DateTime]::UtcNow.AddMilliseconds(2000)
    while ($true) {
        $result = Invoke-CodedbProcess `
            -FilePath $providerPaths.ExecutablePath `
            -Arguments @(
                "tool",
                $Name,
                $argumentJson,
                "--root",
                $context.UnityRoot,
                "--config",
                $activeConfigPath,
                "--no-watch"
            )

        if ($result.ExitCode -eq 0) {
            return $result.StandardOutput
        }

        $message = $result.StandardError.Trim()
        if ([string]::IsNullOrWhiteSpace($message)) {
            $message = $result.StandardOutput.Trim()
        }
        $watchReadActive = [string]::Equals(
            [System.IO.Path]::GetFullPath($activeConfigPath),
            [System.IO.Path]::GetFullPath($watchConfigPath),
            [StringComparison]::OrdinalIgnoreCase)
        $transientReadFailure = $message -match '(?i)failed(?:_|\s+)to(?:_|\s+)read'
        if (-not $watchReadActive -or -not $transientReadFailure -or [DateTime]::UtcNow -ge $retryUntil) {
            throw "codebase-mcp tool $Name failed with exit code $($result.ExitCode). $message"
        }
        Start-Sleep -Milliseconds 100
    }
}

function Assert-ContainsText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$Expected,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ($Text.IndexOf($Expected, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "$Label did not contain expected text: $Expected"
    }
}

function ConvertTo-GitRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
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

function Assert-UnityProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $fullPath = Join-Path $context.UnityRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Missing Unity project file: $RelativePath"
    }
}

function Get-ProbeFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions
    )

    $searchRoots = @("Assets", "Packages", "ProjectSettings")
    $excludedFragments = @(
        "\AIWork\.runtime\",
        "\Library\PackageCache\",
        "\Library\",
        "\Temp\",
        "\Obj\",
        "\Logs\"
    )

    $allFiles = @()
    foreach ($root in $searchRoots) {
        $rootPath = Join-Path $context.UnityRoot $root
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) {
            continue
        }

        foreach ($extension in $Extensions) {
            $normalizedExtension = $extension
            if (-not $normalizedExtension.StartsWith(".")) {
                $normalizedExtension = "." + $normalizedExtension
            }

            $allFiles += Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter "*$normalizedExtension" -ErrorAction SilentlyContinue |
                Where-Object {
                    $projectRelativePath = "\" + (ConvertTo-CodedbProjectRelativePath -Context $context -Path $_.FullName).Replace("/", "\")
                    $isExcluded = $false
                    foreach ($fragment in $excludedFragments) {
                        if ($projectRelativePath.IndexOf($fragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                            $isExcluded = $true
                            break
                        }
                    }

                    -not $isExcluded
                }
        }
    }

    return @($allFiles | Sort-Object `
        @{ Expression = { if ($_.FullName.IndexOf(" ", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { 1 } else { 0 } } }, `
        FullName)
}

function Get-ProbeFile {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions
    )

    $files = Get-ProbeFiles -Extensions $Extensions
    if ($files) {
        return $files[0]
    }

    return $null
}

function Get-CSharpProbeFile {
    return Get-ProbeFile -Extensions @(".cs")
}

function Get-ProbeFileText {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $content = Get-Content -LiteralPath $File.FullName -Raw
    if ($null -eq $content) {
        return ""
    }

    return [string]$content
}

function Get-FirstMeaningfulToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $skipWords = @(
        "Shader",
        "Properties",
        "SubShader",
        "Pass",
        "Tags",
        "Blend",
        "Cull",
        "ZWrite",
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
        "define",
        "local",
        "function",
        "const",
        "let",
        "var",
        "class",
        "export",
        "import"
    )

    $matches = [regex]::Matches($Content, '\b[A-Za-z_][A-Za-z0-9_]{2,}\b')
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

    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $fallbackMatch = [regex]::Match($fileName, '[A-Za-z_][A-Za-z0-9_]{2,}')
    if ($fallbackMatch.Success) {
        return $fallbackMatch.Value
    }

    return $fileName
}

function Get-CSharpProbeTerm {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $content = Get-ProbeFileText -File $File
    $match = [regex]::Match($content, '\b(class|struct|interface|enum)\s+([A-Za-z_][A-Za-z0-9_]*)')
    if ($match.Success) {
        return $match.Groups[2].Value
    }

    return [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
}

function Get-ShaderProbeTerm {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $content = Get-ProbeFileText -File $File
    if ($File.Extension.Equals(".shader", [System.StringComparison]::OrdinalIgnoreCase)) {
        $shaderMatch = [regex]::Match($content, 'Shader\s+"([^"]+)"')
        if ($shaderMatch.Success) {
            $shaderToken = [regex]::Match($shaderMatch.Groups[1].Value, '[A-Za-z_][A-Za-z0-9_]{2,}')
            if ($shaderToken.Success) {
                return $shaderToken.Value
            }

            return $shaderMatch.Groups[1].Value
        }
    }

    return Get-FirstMeaningfulToken -Content $content -File $File
}

function Get-LuaProbeTerm {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $content = Get-ProbeFileText -File $File

    $match = [regex]::Match($content, '\blocal\s+function\s+([A-Za-z_][A-Za-z0-9_]*)')
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    $match = [regex]::Match($content, '\bfunction\s+([A-Za-z_][A-Za-z0-9_.:]*)')
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    $match = [regex]::Match($content, '\blocal\s+([A-Za-z_][A-Za-z0-9_]*)')
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return Get-FirstMeaningfulToken -Content $content -File $File
}

function Get-JavaScriptProbeTerm {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $content = Get-ProbeFileText -File $File

    $match = [regex]::Match($content, '\b(class|function)\s+([A-Za-z_$][A-Za-z0-9_$]*)')
    if ($match.Success) {
        return $match.Groups[2].Value
    }

    $match = [regex]::Match($content, '\b(?:const|let|var)\s+([A-Za-z_$][A-Za-z0-9_$]*)')
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return Get-FirstMeaningfulToken -Content $content -File $File
}

function Assert-CodedbConfigIncludesExtension {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    $normalizedExtension = $Extension.TrimStart(".")
    $config = Get-Content -LiteralPath $providerPaths.ConfigPath -Raw
    $expected = '"' + $normalizedExtension + '"'
    if ($config.IndexOf($expected, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Runtime config does not include .$normalizedExtension in scan.extensions. Regenerate config and refresh the index before running this language probe."
    }
}

function Get-CustomLanguageLabel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LanguageName
    )

    switch ($LanguageName) {
        "CSharp" { return "C#" }
        "ShaderHlsl" { return "Shader/HLSL" }
        "Lua" { return "Lua" }
        "JavaScript" { return "JavaScript" }
    }
}

function Get-CustomLanguageExtensions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LanguageName
    )

    switch ($LanguageName) {
        "CSharp" { return @(".cs") }
        "ShaderHlsl" { return @(".shader", ".hlsl", ".compute", ".cginc") }
        "Lua" { return @(".lua") }
        "JavaScript" { return @(".js", ".jsx", ".mjs", ".cjs") }
    }
}

function Find-SourceTextMatches {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,
        [Parameter(Mandatory = $true)]
        [string]$QueryText
    )

    $matches = @()
    foreach ($file in ($Files | Sort-Object FullName)) {
        $fileMatches = Select-String -LiteralPath $file.FullName -SimpleMatch -Pattern $QueryText
        foreach ($match in $fileMatches) {
            $matches += [pscustomobject]@{
                File = $file
                LineNumber = $match.LineNumber
                Line = $match.Line
            }
        }
    }

    return @($matches)
}

function Invoke-CodedbLanguageProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [string[]]$Extensions,
        [Parameter(Mandatory = $true)]
        [scriptblock]$TermResolver
    )

    $probeFile = Get-ProbeFile -Extensions $Extensions
    if ($null -eq $probeFile) {
        Write-Skip "No $Label files found under Assets, Packages, or ProjectSettings."
        return
    }

    Assert-CodedbConfigIncludesExtension -Extension $probeFile.Extension

    $relativePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $probeFile.FullName
    $queryTerm = & $TermResolver $probeFile

    if ([string]::IsNullOrWhiteSpace($queryTerm)) {
        throw "$Label could not derive a codedb query from $relativePath."
    }

    $read = Invoke-CodedbTool -Name "codedb_read" -Arguments @{
        path = $relativePath
        start_line = 1
        end_line = 120
    }

    if ($read.IndexOf("file not indexed", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "$Label source file exists and runtime config includes $($probeFile.Extension), but codedb did not index it: $relativePath. Refresh the index or treat this as a provider capability gap."
    }

    Assert-ContainsText -Text $read -Expected $queryTerm -Label "$Label read"

    $search = Invoke-CodedbTool -Name "codedb_text_search" -Arguments @{
        query = $queryTerm
        path_glob = $relativePath
        limit = 10
    }
    Assert-ContainsText -Text $search -Expected $relativePath -Label "$Label search"

    Write-Host "[OK] $Label codedb probe passed with $queryTerm in $relativePath."
}

function Invoke-CodedbCustomProbe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$Files,
        [Parameter(Mandatory = $true)]
        [string]$QueryText
    )

    Assert-CodedbConfigIncludesExtension -Extension $Files[0].Extension

    $sourceMatches = Find-SourceTextMatches -Files $Files -QueryText $QueryText
    if (-not $sourceMatches) {
        Write-NoHit "$Label custom probe found no source match for: $QueryText"
        return
    }

    $verifiedMatches = @()
    foreach ($sourceMatch in $sourceMatches) {
        $relativePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $sourceMatch.File.FullName

        if ($verifiedMatches | Where-Object { $_.Path -eq $relativePath }) {
            $verifiedMatches += [pscustomobject]@{
                Path = $relativePath
                LineNumber = $sourceMatch.LineNumber
            }
            continue
        }

        $search = Invoke-CodedbTool -Name "codedb_text_search" -Arguments @{
            query = $QueryText
            path_glob = $relativePath
            limit = 10
        }

        if ($search.IndexOf($relativePath, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            continue
        }

        $startLine = [Math]::Max(1, $sourceMatch.LineNumber - 3)
        $endLine = $sourceMatch.LineNumber + 3
        $read = Invoke-CodedbTool -Name "codedb_read" -Arguments @{
            path = $relativePath
            start_line = $startLine
            end_line = $endLine
        }

        if ($read.IndexOf($QueryText, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            continue
        }

        $verifiedMatches += [pscustomobject]@{
            Path = $relativePath
            LineNumber = $sourceMatch.LineNumber
        }
    }

    if (-not $verifiedMatches) {
        Write-NoHit "$Label source contains $QueryText, but codedb did not return verified matches."
        return
    }

    Write-Host "[OK] $Label custom probe found $($verifiedMatches.Count) hit(s) for: $QueryText"
    foreach ($match in $verifiedMatches) {
        Write-Hit "$($match.Path):$($match.LineNumber)"
    }
}

function Invoke-RuntimeHealthSmoke {
    Write-Host "Running codedb runtime health smoke..."

    Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths

    $manifestPath = Join-Path $context.ProviderIndexRoot "manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Missing codedb index manifest: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $manifestPath). Refresh the index first."
    }

    foreach ($fullPath in @($context.RuntimeRoot, $context.ProviderIndexRoot)) {
        $relativePath = ConvertTo-GitRelativePath -Path $fullPath
        if (-not (Test-CodedbPathGitIgnored -Context $context -RelativePath $relativePath)) {
            throw "$relativePath is not ignored by Git."
        }
    }

    # CLI `tool` calls use the config-selected project directly. MCP calls still
    # require the registered project argument where the tool supports it.
    $status = Invoke-CodedbTool -Name "codedb_status" -Arguments @{}
    Assert-ContainsText -Text $status -Expected "ready" -Label "codedb_status"

    Write-Host "[OK] Runtime health smoke passed."
}

function Invoke-UnityProjectSmoke {
    Write-Host "Running Unity project smoke..."

    Assert-UnityProjectFile -RelativePath "Packages\manifest.json"
    Assert-UnityProjectFile -RelativePath "ProjectSettings\ProjectVersion.txt"

    Write-Host "[OK] Unity project files exist: Packages/manifest.json, ProjectSettings/ProjectVersion.txt."
}

function Invoke-CSharpProbeSmoke {
    Write-Host "Running C# language probe..."

    $probeFile = Get-CSharpProbeFile
    if ($null -eq $probeFile) {
        Write-Skip "No C# files found under Assets, Packages, or ProjectSettings."
        return
    }

    $relativePath = ConvertTo-CodedbProjectRelativePath -Context $context -Path $probeFile.FullName
    $queryTerm = Get-CSharpProbeTerm -File $probeFile

    if ([string]::IsNullOrWhiteSpace($queryTerm)) {
        throw "Could not derive a C# probe query from $relativePath."
    }

    $search = Invoke-CodedbTool -Name "codedb_text_search" -Arguments @{
        query = $queryTerm
        path_glob = $relativePath
        limit = 10
    }
    Assert-ContainsText -Text $search -Expected $relativePath -Label "C# probe search"

    $read = Invoke-CodedbTool -Name "codedb_read" -Arguments @{
        path = $relativePath
        start_line = 1
        end_line = 120
    }
    Assert-ContainsText -Text $read -Expected $queryTerm -Label "C# probe read"

    Write-Host "[OK] C# probe passed with $queryTerm in $relativePath."
}

function Invoke-ShaderProbeSmoke {
    Write-Host "Running Shader/HLSL language probe..."

    Invoke-CodedbLanguageProbe `
        -Label "Shader/HLSL probe" `
        -Extensions @(".shader", ".hlsl", ".compute", ".cginc") `
        -TermResolver { param($file) Get-ShaderProbeTerm -File $file }
}

function Invoke-LuaProbeSmoke {
    Write-Host "Running Lua language probe..."

    Invoke-CodedbLanguageProbe `
        -Label "Lua probe" `
        -Extensions @(".lua") `
        -TermResolver { param($file) Get-LuaProbeTerm -File $file }
}

function Invoke-JavaScriptProbeSmoke {
    Write-Host "Running JavaScript language probe..."

    Invoke-CodedbLanguageProbe `
        -Label "JavaScript probe" `
        -Extensions @(".js", ".jsx", ".mjs", ".cjs") `
        -TermResolver { param($file) Get-JavaScriptProbeTerm -File $file }
}

function Invoke-LanguageProbeSmoke {
    Invoke-CSharpProbeSmoke
    Invoke-ShaderProbeSmoke
    Invoke-LuaProbeSmoke
    Invoke-JavaScriptProbeSmoke
}

function Invoke-CustomProbeSmoke {
    Write-Host "Running custom language probe..."

    if ([string]::IsNullOrWhiteSpace($Query)) {
        throw "CustomProbe requires a non-empty -Query value."
    }

    $languageLabel = Get-CustomLanguageLabel -LanguageName $Language
    $extensions = Get-CustomLanguageExtensions -LanguageName $Language
    $probeFiles = Get-ProbeFiles -Extensions $extensions

    if (-not $probeFiles) {
        Write-Skip "No $languageLabel files found under Assets, Packages, or ProjectSettings."
        return
    }

    Invoke-CodedbCustomProbe -Label $languageLabel -Files $probeFiles -QueryText $Query
}

Assert-ProjectCodedbRuntimeConfig -Context $context -ProviderPaths $providerPaths

switch ($Check) {
    "All" {
        Invoke-RuntimeHealthSmoke
        Invoke-UnityProjectSmoke
        Invoke-LanguageProbeSmoke
    }
    "RuntimeHealth" {
        Invoke-RuntimeHealthSmoke
    }
    "UnityProject" {
        Invoke-UnityProjectSmoke
    }
    "CSharpProbe" {
        Invoke-CSharpProbeSmoke
    }
    "LanguageProbe" {
        Invoke-LanguageProbeSmoke
    }
    "ShaderProbe" {
        Invoke-ShaderProbeSmoke
    }
    "LuaProbe" {
        Invoke-LuaProbeSmoke
    }
    "JavaScriptProbe" {
        Invoke-JavaScriptProbeSmoke
    }
    "CustomProbe" {
        Invoke-CustomProbeSmoke
    }
}

Write-Host "codedb index smoke completed: $Check."
