#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$PackageVersion = "0.2.5-preview.5",
    [string]$LocalAppDataRoot = "",
    [switch]$TestMode,
    [string]$TestArchivePath = "",
    [string]$TestSignaturePath = "",
    [string]$TestDistributionManifestPath = "",
    [switch]$TestFailAfterBackup,
    [switch]$TestFailTemporaryCleanup,
    [switch]$TestDownloadTimeout
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
try {
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [Console]::OutputEncoding = $utf8NoBom
    $OutputEncoding = $utf8NoBom
} catch {
    # Result codes remain ASCII even when the host does not allow an encoding change.
}

$script:ProviderPackageVersion = "0.2.5-preview.5"
$script:DistributionManifestPath = Join-Path $PSScriptRoot "codedb-provider-distribution.json"
$script:ProviderContractPath = Join-Path $PSScriptRoot "..\Payload~\AIWork\codedb\shared\codedb-machine-provider-contract.ps1"
$script:ExpectedReleaseBaseUrl = "https://github.com/riceWithoutIce/UnityCodeDB/releases/download/codedb-provider-v0.5.0-28e3912"
$script:ExpectedArchiveName = "codedb-provider-0.5.0-28e3912-windows-x64.zip"
$script:ExpectedSignatureName = "codedb-provider-0.5.0-28e3912-windows-x64.zip.sig"
$script:ExpectedDevelopmentReleaseBaseUrl = "https://raw.githubusercontent.com/killop/codedb-mcp/28e3912d5cd67ff3499734984f3e3d626a204796/skills/codedb-mcp/assets"
$script:ExpectedDevelopmentArtifactName = "codebase-mcp.exe"
$script:ExpectedDevelopmentExecutableSha256 = "38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7"
$script:MaximumArchiveBytes = 268435456
$script:ProviderDownloadTimeoutMilliseconds = 120000
$script:ProviderStageCount = 6

function Write-ProviderStage {
    param(
        [Parameter(Mandatory = $true)][int]$Stage,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($Stage -lt 1 -or $Stage -gt $script:ProviderStageCount) {
        throw "Provider installer stage is outside the reviewed range."
    }

    # Direct console output keeps stage events visible to the Editor while
    # avoiding PowerShell pipeline values from helper functions.
    [Console]::Out.WriteLine("[PROVIDER_STAGE] $Stage/$($script:ProviderStageCount) $Message")
}

if (-not (Test-Path -LiteralPath $script:ProviderContractPath -PathType Leaf)) {
    throw "Package-owned Provider contract is missing."
}
. $script:ProviderContractPath
$script:RequiredArchiveEntries = @("THIRD-PARTY-NOTICES.txt", "codebase-mcp.exe", "provider-manifest.json")

function Write-ProviderInstallFailure {
    param(
        [Parameter(Mandatory = $true)][string]$ReasonCode,
        [Parameter(Mandatory = $true)][string]$Message
    )

    # Keep the machine-readable failure line ASCII so Windows PowerShell/OEM encoding
    # cannot turn the Manager's primary error into mojibake.
    $safeMessage = [regex]::Replace(($Message -replace "[\r\n]+", " "), "[^\x00-\x7F]", "?")
    [Console]::Error.WriteLine("[PROVIDER_INSTALL_RESULT] BLOCKED $ReasonCode - $safeMessage")
}

function Remove-ProviderTemporaryRootBestEffort {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    try {
        if (-not (Test-Path -LiteralPath $Path -ErrorAction Stop)) {
            return
        }

        if ($TestFailTemporaryCleanup) {
            [Console]::Out.WriteLine("[PROVIDER_INSTALL_WARNING] TEMPORARY_CLEANUP_DEFERRED - Temporary installer files could not be removed; the Provider installation result above remains authoritative.")
            try { Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue } catch { }
            return
        }

        for ($attempt = 1; $attempt -le 4; $attempt++) {
            try {
                Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
                return
            } catch {
                if ($attempt -lt 4) {
                    Start-Sleep -Milliseconds (50 * $attempt)
                }
            }
        }
    } catch {
        # The installation result is already committed or the caller is already failing.
    }

    [Console]::Out.WriteLine("[PROVIDER_INSTALL_WARNING] TEMPORARY_CLEANUP_DEFERRED - Temporary installer files could not be removed; the Provider installation result above remains authoritative.")
}

function Read-StrictUtf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$MaximumBytes,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label is missing: $Path"
    }
    $file = Get-Item -LiteralPath $Path -Force
    if ($file.Length -le 0 -or $file.Length -gt $MaximumBytes) {
        throw "$Label size is outside the accepted range."
    }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -le 0 -or $bytes.Length -gt $MaximumBytes) {
        throw "$Label size changed outside the accepted range while it was read."
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "$Label must be UTF-8 without a byte-order mark."
    }
    return [System.Text.UTF8Encoding]::new($false, $true).GetString($bytes)
}

function Read-ProviderDistributionManifest {
    $manifestPath = if ($TestMode -and -not [string]::IsNullOrWhiteSpace($TestDistributionManifestPath)) {
        $TestDistributionManifestPath
    } else {
        $script:DistributionManifestPath
    }
    $text = Read-StrictUtf8File -Path $manifestPath -MaximumBytes 65536 -Label "Provider distribution manifest"
    $manifest = ConvertFrom-CodedbProviderManifestJson -Text $text -Label "Provider distribution manifest"
    $expectedNames = @(
        "schema_version", "managed_by", "distribution_state", "provider_id", "version", "commit",
        "protocol", "source", "supported_package_min_inclusive", "supported_package_max_exclusive",
        "release_base_url", "archive_name", "archive_sha256", "signature_name", "signature_encoding", "signature_sha256",
        "signature_algorithm", "signature_public_key_xml", "executable_sha256", "license_status"
    )
    if ($manifest.Count -ne $expectedNames.Count -or
        @($manifest.Keys | Where-Object { $expectedNames -cnotcontains $_ }).Count -ne 0) {
        throw "Provider distribution manifest properties do not match schema 1."
    }
    if ((Get-CodedbProviderManifestInt32 -Properties $manifest -Name "schema_version") -ne 1 -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "managed_by"), "com.rice.ai-codedb", [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "provider_id"), $script:CodedbRequiredProviderId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "version"), $script:CodedbRequiredProviderVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "commit"), $script:CodedbRequiredProviderCommit, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "protocol"), $script:CodedbRequiredProviderProtocol, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "source"), $script:CodedbRequiredProviderSource, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_min_inclusive"), $script:CodedbSupportedPackageMinInclusive, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_max_exclusive"), $script:CodedbSupportedPackageMaxExclusive, [StringComparison]::Ordinal)) {
        throw "Provider distribution identity does not match this Package."
    }
    return $manifest
}

function Assert-LeafName {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [string]::Equals([System.IO.Path]::GetFileName($Value), $Value, [StringComparison]::Ordinal) -or
        $Value.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        throw "$Label must be one safe file name."
    }
}

function Get-ValidatedDistributionMode {
    param([Parameter(Mandatory = $true)]$Manifest)

    $state = Get-CodedbProviderManifestString -Properties $Manifest -Name "distribution_state"
    $licenseStatus = Get-CodedbProviderManifestString -Properties $Manifest -Name "license_status"
    $releaseBaseUrl = Get-CodedbProviderManifestString -Properties $Manifest -Name "release_base_url"
    $archiveName = Get-CodedbProviderManifestString -Properties $Manifest -Name "archive_name"
    $signatureName = Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_name"
    $signatureEncoding = Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_encoding"
    Assert-LeafName -Value $archiveName -Label "Provider archive name"

    if ([string]::Equals($state, "READY", [StringComparison]::Ordinal)) {
        if (-not [string]::Equals($licenseStatus, "APPROVED", [StringComparison]::Ordinal)) {
            throw "Rice Provider distribution is not available until license, artifact hashes, and signing-key review are complete."
        }
        Assert-LeafName -Value $signatureName -Label "Provider signature name"
        if (-not $TestMode -and
            -not [string]::Equals($releaseBaseUrl, $script:ExpectedReleaseBaseUrl, [StringComparison]::Ordinal)) {
            throw "Provider release URL does not match the pinned Rice GitHub Release channel."
        }
        if ($TestMode -and [string]::IsNullOrWhiteSpace($releaseBaseUrl)) {
            $releaseBaseUrl = "fixture://local"
        }
        if ([string]::IsNullOrWhiteSpace($releaseBaseUrl)) {
            throw "Provider release URL is missing."
        }
        if (-not [string]::Equals($archiveName, $script:ExpectedArchiveName, [StringComparison]::Ordinal) -or
            -not [string]::Equals($signatureName, $script:ExpectedSignatureName, [StringComparison]::Ordinal)) {
            throw "Provider archive names do not match the fixed Windows distribution contract."
        }
        if (-not [string]::Equals($signatureEncoding, "base64", [StringComparison]::Ordinal)) {
            throw "Provider archive signature encoding is unsupported."
        }

        foreach ($name in @("archive_sha256", "signature_sha256", "executable_sha256")) {
            $value = Get-CodedbProviderManifestString -Properties $Manifest -Name $name
            if ($value -cnotmatch '^[0-9a-f]{64}$') {
                throw "Provider distribution property $name must be a lowercase SHA-256."
            }
        }
        if (-not [string]::Equals(
                (Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_algorithm"),
                "RSA-SHA256",
                [StringComparison]::Ordinal)) {
            throw "Provider distribution signature algorithm is unsupported."
        }
        $publicKey = Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_public_key_xml"
        if ([string]::IsNullOrWhiteSpace($publicKey)) {
            throw "Provider distribution signing key is missing."
        }
        return "RICE_RELEASE"
    }

    if ([string]::Equals($state, "DEVELOPMENT_UPSTREAM", [StringComparison]::Ordinal)) {
        if ($script:ProviderPackageVersion -cnotmatch '-preview\.[0-9]+$') {
            throw "Development Provider distribution is available only to preview Package versions."
        }
        $archiveSha256 = Get-CodedbProviderManifestString -Properties $Manifest -Name "archive_sha256"
        $executableSha256 = Get-CodedbProviderManifestString -Properties $Manifest -Name "executable_sha256"
        if (-not [string]::Equals($licenseStatus, "PENDING", [StringComparison]::Ordinal) -or
            -not [string]::Equals($archiveName, $script:ExpectedDevelopmentArtifactName, [StringComparison]::Ordinal) -or
            $archiveSha256 -cnotmatch '^[0-9a-f]{64}$' -or
            -not [string]::Equals($archiveSha256, $executableSha256, [StringComparison]::Ordinal) -or
            -not [string]::IsNullOrEmpty($signatureName) -or
            -not [string]::IsNullOrEmpty($signatureEncoding) -or
            -not [string]::IsNullOrEmpty((Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_sha256")) -or
            -not [string]::IsNullOrEmpty((Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_algorithm")) -or
            -not [string]::IsNullOrEmpty((Get-CodedbProviderManifestString -Properties $Manifest -Name "signature_public_key_xml"))) {
            throw "Development Provider distribution properties do not match the fixed upstream artifact contract."
        }
        if (-not $TestMode -and (
            -not [string]::Equals($releaseBaseUrl, $script:ExpectedDevelopmentReleaseBaseUrl, [StringComparison]::Ordinal) -or
            -not [string]::Equals($executableSha256, $script:ExpectedDevelopmentExecutableSha256, [StringComparison]::Ordinal))) {
            throw "Development Provider source or executable identity does not match the Package-pinned upstream commit."
        }
        if ($TestMode -and [string]::IsNullOrWhiteSpace($releaseBaseUrl)) {
            $releaseBaseUrl = "fixture://local"
        }
        if ([string]::IsNullOrWhiteSpace($releaseBaseUrl)) {
            throw "Development Provider source URL is missing."
        }
        return "DEVELOPMENT_UPSTREAM"
    }

    throw "Rice Provider distribution is not available until license, artifact hashes, and signing-key review are complete."
}

function Assert-NoReparsePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-CodedbMachinePathNoReparsePoint -Path $Path -Root $Root -Label $Label
}

function Assert-NoReparseClosure {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-NoReparsePath -Path $Root -Root $Root -Label $Label
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return
    }
    foreach ($entry in @(Get-ChildItem -LiteralPath $Root -Force -Recurse)) {
        if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label contains a reparse point: $($entry.FullName)"
        }
    }
}

function Copy-ProviderArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($TestMode -and $TestDownloadTimeout) {
        throw "[PROVIDER_DOWNLOAD_TIMEOUT] Provider artifact download timed out after $($script:ProviderDownloadTimeoutMilliseconds) ms."
    }

    if ($TestMode) {
        if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
            throw "$Label fixture is missing."
        }
        Copy-Item -LiteralPath $Source -Destination $Destination
        return
    }

    $request = $null
    $response = $null
    $inputStream = $null
    $outputStream = $null
    $completed = $false
    try {
        $request = [System.Net.HttpWebRequest]::Create($Source)
        $request.Method = "GET"
        $request.UserAgent = "Rice-AI-CodeDB/$script:ProviderPackageVersion"
        $request.AllowAutoRedirect = $true
        $request.Timeout = $script:ProviderDownloadTimeoutMilliseconds
        $request.ReadWriteTimeout = $script:ProviderDownloadTimeoutMilliseconds
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        if ([int]$response.StatusCode -lt 200 -or [int]$response.StatusCode -ge 300) {
            throw "$Label returned HTTP status $([int]$response.StatusCode)."
        }
        if ($response.ContentLength -le 0 -or $response.ContentLength -gt $script:MaximumArchiveBytes) {
            throw "$Label response size is outside the accepted bound."
        }

        $inputStream = $response.GetResponseStream()
        $outputStream = [System.IO.File]::Open(
            $Destination,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None)
        $buffer = New-Object byte[] (1024 * 1024)
        $totalBytes = 0L
        $deadline = [DateTime]::UtcNow.AddMilliseconds($script:ProviderDownloadTimeoutMilliseconds)
        while ($true) {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "[PROVIDER_DOWNLOAD_TIMEOUT] $Label download timed out after $($script:ProviderDownloadTimeoutMilliseconds) ms."
            }
            $read = $inputStream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) {
                break
            }
            $outputStream.Write($buffer, 0, $read)
            $totalBytes += $read
            if ($totalBytes -gt $script:MaximumArchiveBytes) {
                throw "$Label exceeded the accepted size bound."
            }
        }
        $outputStream.Flush()
        $completed = $true
    } catch [System.Net.WebException] {
        if ($_.Exception.Status -eq [System.Net.WebExceptionStatus]::Timeout) {
            throw "[PROVIDER_DOWNLOAD_TIMEOUT] $Label download timed out after $($script:ProviderDownloadTimeoutMilliseconds) ms."
        }
        throw "$Label download failed: $($_.Exception.Message)"
    } finally {
        if ($null -ne $outputStream) { $outputStream.Dispose() }
        if ($null -ne $inputStream) { $inputStream.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
        if ($null -ne $request) { $request.Abort() }
        if (-not $completed -and (Test-Path -LiteralPath $Destination -PathType Leaf)) {
            Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        }
    }
}

function Assert-FileSha256 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $actual = Get-CodedbFileSha256 -Path $Path
    if (-not [string]::Equals($actual, $Expected, [StringComparison]::Ordinal)) {
        throw "$Label SHA-256 mismatch."
    }
}

function Assert-DetachedSignature {
    param(
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$SignaturePath,
        [Parameter(Mandatory = $true)][string]$PublicKeyXml
    )

    $signatureText = (Read-StrictUtf8File -Path $SignaturePath -MaximumBytes 16384 -Label "Provider archive signature").Trim()
    if ($signatureText -cnotmatch '^[A-Za-z0-9+/]+={0,2}$') {
        throw "Provider archive signature is not canonical base64."
    }
    try {
        $signature = [Convert]::FromBase64String($signatureText)
    } catch {
        throw "Provider archive signature is not valid base64."
    }
    $archiveBytes = [System.IO.File]::ReadAllBytes($ArchivePath)
    $rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new()
    try {
        $rsa.PersistKeyInCsp = $false
        $rsa.FromXmlString($PublicKeyXml)
        if (-not $rsa.VerifyData($archiveBytes, "SHA256", $signature)) {
            throw "Provider archive detached signature is invalid."
        }
    } finally {
        $rsa.Dispose()
    }
}

function New-DevelopmentProviderCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [Parameter(Mandatory = $true)][string]$CandidateRoot,
        [Parameter(Mandatory = $true)]$Distribution
    )

    $candidateExecutablePath = Join-Path $CandidateRoot "codebase-mcp.exe"
    Copy-Item -LiteralPath $ExecutablePath -Destination $candidateExecutablePath
    $manifest = [ordered]@{
        schema_version = 1
        provider_id = $script:CodedbRequiredProviderId
        version = $script:CodedbRequiredProviderVersion
        commit = $script:CodedbRequiredProviderCommit
        executable = "codebase-mcp.exe"
        sha256 = Get-CodedbProviderManifestString -Properties $Distribution -Name "executable_sha256"
        protocol = $script:CodedbRequiredProviderProtocol
        source = $script:CodedbRequiredProviderSource
        supported_package_min_inclusive = $script:CodedbSupportedPackageMinInclusive
        supported_package_max_exclusive = $script:CodedbSupportedPackageMaxExclusive
    }
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText(
        (Join-Path $CandidateRoot "provider-manifest.json"),
        ($manifest | ConvertTo-Json -Compress),
        $utf8NoBom)
    [System.IO.File]::WriteAllText(
        (Join-Path $CandidateRoot "THIRD-PARTY-NOTICES.txt"),
        "Development-only direct retrieval from $($script:CodedbRequiredProviderSource) at commit $($script:CodedbRequiredProviderCommit). Rice license and signed-release review are pending.",
        $utf8NoBom)
}

function Expand-ValidatedProviderArchive {
    param(
        [Parameter(Mandatory = $true)][string]$ArchivePath,
        [Parameter(Mandatory = $true)][string]$CandidateRoot
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $entries = @($archive.Entries)
        if ($entries.Count -ne $script:RequiredArchiveEntries.Count -or
            @($entries | Where-Object { $script:RequiredArchiveEntries -cnotcontains $_.FullName }).Count -ne 0) {
            throw "Provider archive entries do not match the fixed Windows distribution closure."
        }
        foreach ($entry in $entries) {
            if ([string]::IsNullOrWhiteSpace($entry.Name) -or
                $entry.Length -le 0 -or
                ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000)) {
                throw "Provider archive contains an invalid file entry: $($entry.FullName)"
            }
        }
    } finally {
        $archive.Dispose()
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($ArchivePath, $CandidateRoot)
    foreach ($name in $script:RequiredArchiveEntries) {
        $path = Join-Path $CandidateRoot $name
        Assert-NoReparsePath -Path $path -Root $CandidateRoot -Label "Provider candidate entry"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Provider candidate entry is missing after extraction: $name"
        }
    }
}

function Assert-ProviderCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$ProviderRoot,
        [Parameter(Mandatory = $true)]$Distribution
    )

    $manifestPath = Join-Path $ProviderRoot "provider-manifest.json"
    $executablePath = Join-Path $ProviderRoot "codebase-mcp.exe"
    Assert-NoReparsePath -Path $ProviderRoot -Root $ProviderRoot -Label "Provider candidate root"
    Assert-NoReparsePath -Path $manifestPath -Root $ProviderRoot -Label "Provider candidate manifest"
    Assert-NoReparsePath -Path $executablePath -Root $ProviderRoot -Label "Provider candidate executable"
    $allowedEntries = @("codebase-mcp.exe", "provider-manifest.json", "THIRD-PARTY-NOTICES.txt")
    $entries = @(Get-ChildItem -LiteralPath $ProviderRoot -Force)
    if (@($entries | Where-Object {
                $_.PSIsContainer -or $allowedEntries -cnotcontains $_.Name
            }).Count -ne 0) {
        throw "Provider candidate contains unexpected files or directories."
    }
    $manifest = Read-CodedbProviderManifest -Path $manifestPath
    $expectedNames = @(
        "schema_version", "provider_id", "version", "commit", "executable", "sha256",
        "protocol", "source", "supported_package_min_inclusive", "supported_package_max_exclusive"
    )
    if ($manifest.Count -ne $expectedNames.Count -or @($manifest.Keys | Where-Object { $expectedNames -cnotcontains $_ }).Count -ne 0) {
        throw "Provider candidate manifest properties do not match schema 1."
    }
    $executableSha256 = Get-CodedbProviderManifestString -Properties $Distribution -Name "executable_sha256"
    if ((Get-CodedbProviderManifestInt32 -Properties $manifest -Name "schema_version") -ne 1 -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "provider_id"), $script:CodedbRequiredProviderId, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "version"), $script:CodedbRequiredProviderVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "commit"), $script:CodedbRequiredProviderCommit, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "executable"), "codebase-mcp.exe", [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "sha256"), $executableSha256, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "protocol"), $script:CodedbRequiredProviderProtocol, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "source"), $script:CodedbRequiredProviderSource, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_min_inclusive"), $script:CodedbSupportedPackageMinInclusive, [StringComparison]::Ordinal) -or
        -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_max_exclusive"), $script:CodedbSupportedPackageMaxExclusive, [StringComparison]::Ordinal)) {
        throw "Provider candidate identity does not match this Package."
    }
    Assert-FileSha256 -Path $executablePath -Expected $executableSha256 -Label "Provider executable"
    return [pscustomobject]@{ ManifestPath = $manifestPath; ExecutablePath = $executablePath }
}

function Test-InstalledProviderCurrent {
    param(
        [Parameter(Mandatory = $true)][string]$ProviderRoot,
        [Parameter(Mandatory = $true)]$Distribution
    )

    if (-not (Test-Path -LiteralPath $ProviderRoot -PathType Container)) {
        return $false
    }
    try {
        $null = Assert-ProviderCandidate -ProviderRoot $ProviderRoot -Distribution $Distribution
        return $true
    } catch {
        return $false
    }
}

function Test-ProviderRootOwnedForReplacement {
    param([Parameter(Mandatory = $true)][string]$ProviderRoot)

    if (-not (Test-Path -LiteralPath $ProviderRoot -PathType Container)) {
        return $false
    }
    try {
        Assert-NoReparseClosure -Root $ProviderRoot -Label "Existing CodeDB Provider"
        $allowedEntries = @("codebase-mcp.exe", "provider-manifest.json", "THIRD-PARTY-NOTICES.txt")
        $entries = @(Get-ChildItem -LiteralPath $ProviderRoot -Force)
        if (@($entries | Where-Object {
                    $_.PSIsContainer -or $allowedEntries -cnotcontains $_.Name
                }).Count -ne 0) {
            return $false
        }
        $manifestPath = Join-Path $ProviderRoot "provider-manifest.json"
        $executablePath = Join-Path $ProviderRoot "codebase-mcp.exe"
        $manifest = Read-CodedbProviderManifest -Path $manifestPath
        $expectedNames = @(
            "schema_version", "provider_id", "version", "commit", "executable", "sha256",
            "protocol", "source", "supported_package_min_inclusive", "supported_package_max_exclusive"
        )
        if ($manifest.Count -ne $expectedNames.Count -or
            @($manifest.Keys | Where-Object { $expectedNames -cnotcontains $_ }).Count -ne 0 -or
            -not (Test-Path -LiteralPath $executablePath -PathType Leaf) -or
            (Get-CodedbProviderManifestInt32 -Properties $manifest -Name "schema_version") -ne 1 -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "provider_id"), $script:CodedbRequiredProviderId, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "version"), $script:CodedbRequiredProviderVersion, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "commit"), $script:CodedbRequiredProviderCommit, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "executable"), "codebase-mcp.exe", [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "protocol"), $script:CodedbRequiredProviderProtocol, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "source"), $script:CodedbRequiredProviderSource, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_min_inclusive"), $script:CodedbSupportedPackageMinInclusive, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_max_exclusive"), $script:CodedbSupportedPackageMaxExclusive, [StringComparison]::Ordinal)) {
            return $false
        }
        $sha256 = Get-CodedbProviderManifestString -Properties $manifest -Name "sha256"
        if ($sha256 -cnotmatch '^[0-9a-f]{64}$') {
            return $false
        }
        try {
            Assert-FileSha256 -Path $executablePath -Expected $sha256 -Label "Existing CodeDB Provider executable"
        } catch {
            return $false
        }
        return $true
    } catch {
        return $false
    }
}

function Recover-ProviderInstallArtifacts {
    param(
        [Parameter(Mandatory = $true)][string]$ProviderRoot,
        [Parameter(Mandatory = $true)][string]$ProvidersRoot
    )

    $backupPattern = ".${script:CodedbRequiredProviderVersion}.backup-*"
    $backups = @(Get-ChildItem -LiteralPath $ProvidersRoot -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -like $backupPattern
    })
    if ($backups.Count -eq 0) {
        return
    }
    if (Test-Path -LiteralPath $ProviderRoot) {
        return
    }
    if ($backups.Count -ne 1) {
        throw "Multiple interrupted CodeDB Provider backups require manual review; no Provider path was changed."
    }
    $backupRoot = $backups[0].FullName
    if (-not (Test-ProviderRootOwnedForReplacement -ProviderRoot $backupRoot)) {
        throw "An interrupted Provider backup is not an authenticated fixed CodeDB identity; no Provider path was changed."
    }
    Move-Item -LiteralPath $backupRoot -Destination $ProviderRoot
}

function Install-ProviderCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$CandidateRoot,
        [Parameter(Mandatory = $true)][string]$ProviderRoot,
        [Parameter(Mandatory = $true)][string]$ProvidersRoot,
        [Parameter(Mandatory = $true)][string]$LocalAppDataBoundary,
        [Parameter(Mandatory = $true)]$Distribution
    )

    Assert-NoReparsePath -Path $ProvidersRoot -Root $LocalAppDataBoundary -Label "CodeDB Providers root"
    [System.IO.Directory]::CreateDirectory($ProvidersRoot) | Out-Null
    Assert-NoReparsePath -Path $ProvidersRoot -Root $LocalAppDataBoundary -Label "CodeDB Providers root"
    $lockPath = Join-Path $ProvidersRoot ".install-$($script:CodedbRequiredProviderVersion).lock"
    $lock = $null
    try {
        $lock = [System.IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        Recover-ProviderInstallArtifacts -ProviderRoot $ProviderRoot -ProvidersRoot $ProvidersRoot
        if (Test-Path -LiteralPath $ProviderRoot) {
            Assert-NoReparseClosure -Root $ProviderRoot -Label "CodeDB Provider install target"
        }
        if (-not $TestFailAfterBackup -and
            (Test-InstalledProviderCurrent -ProviderRoot $ProviderRoot -Distribution $Distribution)) {
            return "ALREADY_INSTALLED"
        }
        if ((Test-Path -LiteralPath $ProviderRoot) -and
            -not (Test-ProviderRootOwnedForReplacement -ProviderRoot $ProviderRoot)) {
            throw "The existing Provider path is not an authenticated CodeDB Provider identity and was preserved."
        }

        $suffix = [Guid]::NewGuid().ToString("N")
        $stagingRoot = Join-Path $ProvidersRoot ".$($script:CodedbRequiredProviderVersion).candidate-$suffix"
        $backupRoot = Join-Path $ProvidersRoot ".$($script:CodedbRequiredProviderVersion).backup-$suffix"
        [System.IO.Directory]::CreateDirectory($stagingRoot) | Out-Null
        foreach ($candidateEntry in @(Get-ChildItem -LiteralPath $CandidateRoot -Force)) {
            Copy-Item -LiteralPath $candidateEntry.FullName -Destination $stagingRoot -Recurse -Force
        }
        $null = Assert-ProviderCandidate -ProviderRoot $stagingRoot -Distribution $Distribution
        $hadExisting = Test-Path -LiteralPath $ProviderRoot
        $published = $false
        try {
            if ($hadExisting) {
                Move-Item -LiteralPath $ProviderRoot -Destination $backupRoot
            }
            if ($TestFailAfterBackup) {
                throw "Injected Provider installation failure after backup."
            }
            Move-Item -LiteralPath $stagingRoot -Destination $ProviderRoot
            $null = Assert-ProviderCandidate -ProviderRoot $ProviderRoot -Distribution $Distribution
            $published = $true
        } catch {
            if (Test-Path -LiteralPath $ProviderRoot) {
                Remove-Item -LiteralPath $ProviderRoot -Recurse -Force
            }
            if ($hadExisting -and (Test-Path -LiteralPath $backupRoot)) {
                Move-Item -LiteralPath $backupRoot -Destination $ProviderRoot
            }
            throw
        } finally {
            if (Test-Path -LiteralPath $stagingRoot) {
                try {
                    Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction Stop
                } catch {
                    [Console]::Out.WriteLine("[PROVIDER_INSTALL_WARNING] STAGING_CLEANUP_DEFERRED - Provider installation result remains authoritative.")
                }
            }
        }
        if ($published -and (Test-Path -LiteralPath $backupRoot)) {
            try { Remove-Item -LiteralPath $backupRoot -Recurse -Force } catch { }
        }
        return "INSTALLED"
    } finally {
        if ($null -ne $lock) { $lock.Dispose() }
    }
}

function Assert-TestModeIsolation {
    if (-not $TestMode) {
        return
    }
    if ([string]::IsNullOrWhiteSpace($PSCommandPath)) {
        throw "Provider installer test mode requires an isolated script file."
    }
    $temporaryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/')
    $scriptPath = [System.IO.Path]::GetFullPath($PSCommandPath)
    $temporaryPrefix = $temporaryRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $scriptPath.StartsWith($temporaryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Provider installer test mode is available only from an isolated temporary copy."
    }
}

function Invoke-CodedbProviderInstall {
    if (-not [string]::Equals($PackageVersion, $script:ProviderPackageVersion, [StringComparison]::Ordinal)) {
        throw "Provider installer Package version does not match its reviewed distribution contract."
    }
    Assert-TestModeIsolation
    $distribution = Read-ProviderDistributionManifest
    $distributionMode = Get-ValidatedDistributionMode -Manifest $distribution
    Write-ProviderStage -Stage 1 -Message "Validating the fixed Provider contract"
    if ($TestMode) {
        if ([string]::IsNullOrWhiteSpace($LocalAppDataRoot) -or
            [string]::IsNullOrWhiteSpace($TestArchivePath) -or
            [string]::IsNullOrWhiteSpace($TestDistributionManifestPath) -or
            ([string]::Equals($distributionMode, "RICE_RELEASE", [StringComparison]::Ordinal) -and
                [string]::IsNullOrWhiteSpace($TestSignaturePath))) {
            throw "Provider installer test mode requires isolated LocalAppData and artifact paths."
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($LocalAppDataRoot) -or
        -not [string]::IsNullOrWhiteSpace($TestArchivePath) -or
        -not [string]::IsNullOrWhiteSpace($TestSignaturePath) -or
        -not [string]::IsNullOrWhiteSpace($TestDistributionManifestPath) -or
        $TestFailAfterBackup -or
        $TestFailTemporaryCleanup -or
        $TestDownloadTimeout) {
        throw "Provider installer test-only arguments require -TestMode."
    }

    $effectiveLocalAppData = if ($TestMode) { $LocalAppDataRoot } else { $env:LOCALAPPDATA }
    if ([string]::IsNullOrWhiteSpace($effectiveLocalAppData)) {
        throw "Windows LOCALAPPDATA is unavailable."
    }
    $effectiveLocalAppData = [System.IO.Path]::GetFullPath($effectiveLocalAppData)
    if ($TestMode) {
        [System.IO.Directory]::CreateDirectory($effectiveLocalAppData) | Out-Null
    } elseif (-not (Test-Path -LiteralPath $effectiveLocalAppData -PathType Container)) {
        throw "Windows LOCALAPPDATA is unavailable."
    }
    Assert-NoReparsePath -Path $effectiveLocalAppData -Root $effectiveLocalAppData -Label "Windows LOCALAPPDATA"

    $temporaryBoundary = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\', '/')
    Assert-NoReparsePath -Path $temporaryBoundary -Root $temporaryBoundary -Label "Windows temporary directory"
    $temporaryRoot = Join-Path $temporaryBoundary ("Rice-CodeDB-Provider-" + [Guid]::NewGuid().ToString("N"))
    [System.IO.Directory]::CreateDirectory($temporaryRoot) | Out-Null
    Assert-NoReparsePath -Path $temporaryRoot -Root $temporaryBoundary -Label "Provider temporary directory"
    try {
        $artifactName = Get-CodedbProviderManifestString -Properties $distribution -Name "archive_name"
        $artifactPath = Join-Path $temporaryRoot $artifactName
        $releaseBase = (Get-CodedbProviderManifestString -Properties $distribution -Name "release_base_url").TrimEnd('/')
        $artifactSource = if ($TestMode) { $TestArchivePath } else { "$releaseBase/$artifactName" }
        Write-ProviderStage -Stage 2 -Message "Downloading the Provider package and signature"
        Copy-ProviderArtifact -Source $artifactSource -Destination $artifactPath -Label "Provider artifact"
        $artifactFile = Get-Item -LiteralPath $artifactPath -Force
        if ($artifactFile.Length -le 0 -or $artifactFile.Length -gt $script:MaximumArchiveBytes) {
            throw "Provider artifact size is outside the accepted bound."
        }
        Assert-FileSha256 -Path $artifactPath -Expected (Get-CodedbProviderManifestString -Properties $distribution -Name "archive_sha256") -Label "Provider artifact"

        $candidateRoot = Join-Path $temporaryRoot "candidate"
        [System.IO.Directory]::CreateDirectory($candidateRoot) | Out-Null
        if ([string]::Equals($distributionMode, "RICE_RELEASE", [StringComparison]::Ordinal)) {
            $signatureName = Get-CodedbProviderManifestString -Properties $distribution -Name "signature_name"
            $signaturePath = Join-Path $temporaryRoot $signatureName
            $signatureSource = if ($TestMode) { $TestSignaturePath } else { "$releaseBase/$signatureName" }
            Copy-ProviderArtifact -Source $signatureSource -Destination $signaturePath -Label "Provider signature"
            Assert-FileSha256 -Path $signaturePath -Expected (Get-CodedbProviderManifestString -Properties $distribution -Name "signature_sha256") -Label "Provider signature"
            Assert-DetachedSignature `
                -ArchivePath $artifactPath `
                -SignaturePath $signaturePath `
                -PublicKeyXml (Get-CodedbProviderManifestString -Properties $distribution -Name "signature_public_key_xml")
            Expand-ValidatedProviderArchive -ArchivePath $artifactPath -CandidateRoot $candidateRoot
        } else {
            New-DevelopmentProviderCandidate `
                -ExecutablePath $artifactPath `
                -CandidateRoot $candidateRoot `
                -Distribution $distribution
        }
        Write-ProviderStage -Stage 3 -Message "Verifying artifact hash and signature"
        Assert-NoReparseClosure -Root $candidateRoot -Label "Provider candidate closure"
        $null = Assert-ProviderCandidate -ProviderRoot $candidateRoot -Distribution $distribution
        Write-ProviderStage -Stage 4 -Message "Preparing the isolated Provider candidate"

        $providersRoot = Join-Path $effectiveLocalAppData "Rice\CodeDB\providers"
        $providerRoot = Join-Path $providersRoot $script:CodedbRequiredProviderVersion
        Write-ProviderStage -Stage 5 -Message "Activating the verified Provider installation"
        $result = Install-ProviderCandidate `
            -CandidateRoot $candidateRoot `
            -ProviderRoot $providerRoot `
            -ProvidersRoot $providersRoot `
            -LocalAppDataBoundary $effectiveLocalAppData `
            -Distribution $distribution
        $sourceLabel = if ([string]::Equals($distributionMode, "RICE_RELEASE", [StringComparison]::Ordinal)) {
            "Rice signed release"
        } else {
            "development upstream commit"
        }
        Write-Output "[PROVIDER_INSTALL_RESULT] $result - CodeDB Provider $($script:CodedbRequiredProviderVersion) from $sourceLabel is verified at $providerRoot"
    } finally {
        if (Test-Path -LiteralPath $temporaryRoot) {
            Remove-ProviderTemporaryRootBestEffort -Path $temporaryRoot
        }
    }
}

try {
    Invoke-CodedbProviderInstall
    exit 0
} catch {
    $reason = if ($_.Exception.Message.IndexOf("[PROVIDER_DOWNLOAD_TIMEOUT]", [StringComparison]::Ordinal) -ge 0) {
        "PROVIDER_DOWNLOAD_TIMEOUT"
    } elseif ($_.Exception.Message.IndexOf("distribution is not available", [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        "PROVIDER_DISTRIBUTION_UNAVAILABLE"
    } else {
        "PROVIDER_INSTALL_FAILED"
    }
    Write-ProviderInstallFailure -ReasonCode $reason -Message $_.Exception.Message
    exit 4
}
