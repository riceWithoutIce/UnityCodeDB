#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("Manual", "Automatic")]
    [string]$Reason = "Manual"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\codedb-project-common.ps1"

$context = Get-ProjectCodedbContext
Assert-CodedbUnityProject -Context $context
New-ProjectCodedbTextAdapterRuntime -Context $context

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

function Get-TextAdapterSourceFiles {
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

function Get-FileLineText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        return [System.IO.File]::ReadAllLines($Path)
    } catch {
        $content = Get-Content -LiteralPath $Path
        if ($null -eq $content) {
            return @()
        }

        return @($content)
    }
}

function ConvertTo-JsonString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append('"')

    foreach ($character in $Text.ToCharArray()) {
        $codePoint = [int][char]$character
        if ($codePoint -eq 34) {
            [void]$builder.Append('\"')
            continue
        }

        if ($codePoint -eq 92) {
            [void]$builder.Append('\\')
            continue
        }

        if ($codePoint -eq 8) {
            [void]$builder.Append('\b')
            continue
        }

        if ($codePoint -eq 12) {
            [void]$builder.Append('\f')
            continue
        }

        if ($codePoint -eq 10) {
            [void]$builder.Append('\n')
            continue
        }

        if ($codePoint -eq 13) {
            [void]$builder.Append('\r')
            continue
        }

        if ($codePoint -eq 9) {
            [void]$builder.Append('\t')
            continue
        }

        if ($codePoint -lt 32) {
            [void]$builder.Append('\u')
            [void]$builder.Append($codePoint.ToString('x4'))
            continue
        }

        [void]$builder.Append($character)
    }

    [void]$builder.Append('"')
    return $builder.ToString()
}

function Get-StringSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hashBytes = $sha256.ComputeHash($bytes)
        return -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    } finally {
        $sha256.Dispose()
    }
}

function New-Utf8NoBomWriter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $encoding = [System.Text.UTF8Encoding]::new($false)
    return [System.IO.StreamWriter]::new($Path, $false, $encoding)
}

function Enter-TextAdapterBuildLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LockPath
    )

    for ($attempt = 0; $attempt -lt 2; $attempt++) {
        try {
            $stream = [System.IO.File]::Open(
                $LockPath,
                [System.IO.FileMode]::CreateNew,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None
            )
            $metadata = [pscustomobject]@{
                schemaVersion = 1
                processId = $PID
                createdAtUtc = [System.DateTime]::UtcNow.ToString("o")
                reason = $Reason
            } | ConvertTo-Json -Compress
            $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($metadata + [System.Environment]::NewLine)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush($true)
            return $stream
        } catch [System.IO.IOException] {
            if ($attempt -gt 0) {
                throw "Shader adapter build lock could not be acquired: $LockPath"
            }

            $ownerPid = 0
            try {
                $owner = Get-Content -LiteralPath $LockPath -Raw | ConvertFrom-Json
                [void][int]::TryParse([string]$owner.processId, [ref]$ownerPid)
            } catch {
                throw "Shader adapter build lock is active or unreadable: $LockPath"
            }

            if ($ownerPid -gt 0 -and $null -ne (Get-Process -Id $ownerPid -ErrorAction SilentlyContinue)) {
                throw "Shader adapter build is already running under PID $ownerPid."
            }

            Remove-Item -LiteralPath $LockPath -Force
        }
    }

    throw "Shader adapter build lock could not be acquired: $LockPath"
}

function Publish-TextAdapterArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Missing generated Shader adapter artifact: $SourcePath"
    }

    if (Test-Path -LiteralPath $DestinationPath -PathType Leaf) {
        $backupPath = $SourcePath + ".previous"
        Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        try {
            [System.IO.File]::Replace($SourcePath, $DestinationPath, $backupPath, $true)
        } finally {
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        }
    } else {
        [System.IO.File]::Move($SourcePath, $DestinationPath)
    }
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$buildId = "build-$PID-$([System.Guid]::NewGuid().ToString('N'))"
$buildRoot = Join-Path $context.TextAdapterTempRoot $buildId
$lockPath = Join-Path $context.TextAdapterTempRoot "adapter-build.lock"
$temporaryManifestPath = Join-Path $buildRoot "manifest.json"
$temporaryFilesPath = Join-Path $buildRoot "files.jsonl"
$temporaryIndexPath = Join-Path $buildRoot "index.jsonl"
$lockStream = $null
$phaseStopwatch = [System.Diagnostics.Stopwatch]::new()
$phaseTimings = [ordered]@{
    enumeration_ms = 0.0
    source_read_hash_ms = 0.0
    files_jsonl_ms = 0.0
    index_jsonl_ms = 0.0
    manifest_ms = 0.0
    publish_ms = 0.0
}

try {
    New-Item -ItemType Directory -Force -Path $context.TextAdapterTempRoot, $buildRoot | Out-Null
    $lockStream = Enter-TextAdapterBuildLock -LockPath $lockPath

    $phaseStopwatch.Restart()
    $sourceFiles = Get-TextAdapterSourceFiles
    $phaseStopwatch.Stop()
    $phaseTimings.enumeration_ms = $phaseStopwatch.Elapsed.TotalMilliseconds
    $fileRecords = @()
    $aggregateBuilder = [System.Text.StringBuilder]::new()
    $totalLineCount = 0
    $filesWriter = New-Utf8NoBomWriter -Path $temporaryFilesPath
    $indexWriter = New-Utf8NoBomWriter -Path $temporaryIndexPath

    try {
        foreach ($entry in $sourceFiles) {
            $file = $entry.File
            $relativePath = $entry.RelativePath

            $phaseStopwatch.Restart()
            # PowerShell scalarizes a one-element string array unless the
            # caller wraps it.
            $lines = @(Get-FileLineText -Path $file.FullName)
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $phaseStopwatch.Stop()
            $phaseTimings.source_read_hash_ms += $phaseStopwatch.Elapsed.TotalMilliseconds
            $lineCount = $lines.Length
            $totalLineCount += $lineCount
            $extension = $file.Extension.ToLowerInvariant()
            $modifiedUtc = $file.LastWriteTimeUtc.ToString("o")
            $relativePathJson = ConvertTo-JsonString -Text $relativePath

            $phaseStopwatch.Restart()
            $fileRecord = [pscustomobject]@{
                path = $relativePath
                extension = $extension
                lineCount = $lineCount
                byteSize = $fileBytes.Length
                sha256 = $hash
                modifiedUtc = $modifiedUtc
            }

            $fileRecordJson = '{"path":' + $relativePathJson +
                ',"extension":' + (ConvertTo-JsonString -Text $extension) +
                ',"lineCount":' + $lineCount.ToString([System.Globalization.CultureInfo]::InvariantCulture) +
                ',"byteSize":' + $fileBytes.Length.ToString([System.Globalization.CultureInfo]::InvariantCulture) +
                ',"sha256":' + (ConvertTo-JsonString -Text $hash) +
                ',"modifiedUtc":' + (ConvertTo-JsonString -Text $modifiedUtc) + '}'
            $filesWriter.WriteLine($fileRecordJson)
            $fileRecords += $fileRecord
            [void]$aggregateBuilder.AppendLine("$relativePath|$hash|$lineCount|$($fileBytes.Length)")
            $phaseStopwatch.Stop()
            $phaseTimings.files_jsonl_ms += $phaseStopwatch.Elapsed.TotalMilliseconds

            $phaseStopwatch.Restart()
            for ($lineIndex = 0; $lineIndex -lt $lines.Length; $lineIndex++) {
                $lineNumber = ($lineIndex + 1).ToString([System.Globalization.CultureInfo]::InvariantCulture)
                $lineBase64 = [System.Convert]::ToBase64String(
                    [System.Text.Encoding]::UTF8.GetBytes($lines[$lineIndex])
                )

                # Base64 needs no JSON escaping; the path is escaped once per file.
                $jsonLine = '{"path":' + $relativePathJson +
                    ',"line":' + $lineNumber +
                    ',"textBase64":"' + $lineBase64 + '"}'
                $indexWriter.WriteLine($jsonLine)
            }
            $phaseStopwatch.Stop()
            $phaseTimings.index_jsonl_ms += $phaseStopwatch.Elapsed.TotalMilliseconds
        }
    } finally {
        $filesWriter.Dispose()
        $indexWriter.Dispose()
    }

    $phaseStopwatch.Restart()
    $manifest = [pscustomobject]@{
        schemaVersion = 1
        generatedAtUtc = [System.DateTime]::UtcNow.ToString("o")
        adapter = "shader-hlsl-text-index"
        providerName = $context.ProviderName
        output = (ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterRoot)
        roots = $sourceRoots
        extensions = $extensions
        excludes = @(
            "Library",
            "Temp",
            "Logs",
            "UserSettings",
            "obj",
            "bin",
            "Build",
            "Builds",
            "Library/PackageCache",
            "AIWork/.runtime"
        )
        buildMode = "full-atomic"
        buildReason = $Reason.ToLowerInvariant()
        buildId = $buildId
        generationMilliseconds = $stopwatch.ElapsedMilliseconds
        fileCount = $fileRecords.Count
        lineCount = $totalLineCount
        aggregateSha256 = (Get-StringSha256 -Text $aggregateBuilder.ToString())
        files = $fileRecords
    }

    $manifestJson = $manifest | ConvertTo-Json -Depth 8
    $manifestEncoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($temporaryManifestPath, $manifestJson + [System.Environment]::NewLine, $manifestEncoding)
    $phaseStopwatch.Stop()
    $phaseTimings.manifest_ms = $phaseStopwatch.Elapsed.TotalMilliseconds

    $phaseStopwatch.Restart()
    Publish-TextAdapterArtifact -SourcePath $temporaryFilesPath -DestinationPath $context.TextAdapterFilesPath
    Publish-TextAdapterArtifact -SourcePath $temporaryIndexPath -DestinationPath $context.TextAdapterIndexPath
    Publish-TextAdapterArtifact -SourcePath $temporaryManifestPath -DestinationPath $context.TextAdapterManifestPath
    $phaseStopwatch.Stop()
    $phaseTimings.publish_ms = $phaseStopwatch.Elapsed.TotalMilliseconds
    foreach ($phaseName in @($phaseTimings.Keys)) {
        $phaseTimings[$phaseName] = [System.Math]::Round([double]$phaseTimings[$phaseName], 2)
    }

    $stopwatch.Stop()
    $relativeOutput = ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterRoot
    Write-Host "[OK] Shader/HLSL text adapter built $($fileRecords.Count) file(s), $totalLineCount line(s)."
    Write-Host "Build mode: full-atomic"
    Write-Host "Build reason: $($Reason.ToLowerInvariant())"
    Write-Host "Elapsed: $($stopwatch.ElapsedMilliseconds) ms"
    Write-Host ("Phase timings: enumerate={0} ms, source/read/hash={1} ms, files JSONL={2} ms, index JSONL={3} ms, manifest={4} ms, publish={5} ms" -f
        $phaseTimings.enumeration_ms,
        $phaseTimings.source_read_hash_ms,
        $phaseTimings.files_jsonl_ms,
        $phaseTimings.index_jsonl_ms,
        $phaseTimings.manifest_ms,
        $phaseTimings.publish_ms)
    Write-Host "Adapter index: $relativeOutput"
    Write-Host "Manifest: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterManifestPath)"
    Write-Host "Files: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterFilesPath)"
    Write-Host "Index: $(ConvertTo-CodedbProjectRelativePath -Context $context -Path $context.TextAdapterIndexPath)"
    Write-Host ([pscustomobject]@{
        action = "adapter_built"
        mode = "full-atomic"
        reason = $Reason.ToLowerInvariant()
        file_count = $fileRecords.Count
        line_count = $totalLineCount
        elapsed_ms = $stopwatch.ElapsedMilliseconds
        timings_ms = $phaseTimings
    } | ConvertTo-Json -Compress)
} finally {
    if ($null -ne $lockStream) {
        $lockStream.Dispose()
    }
    Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $buildRoot -Recurse -Force -ErrorAction SilentlyContinue
}
