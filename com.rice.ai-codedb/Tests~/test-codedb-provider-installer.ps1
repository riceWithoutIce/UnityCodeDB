#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$RealArtifactPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$originalInstallerPath = Join-Path $packageRoot "Tools~\install-codedb-provider.ps1"
$providerContractPath = Join-Path $packageRoot "Payload~\AIWork\codedb\shared\codedb-machine-provider-contract.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("Rice-CodeDB-Provider-Test-" + [Guid]::NewGuid().ToString("N"))
$testPackageRoot = Join-Path $tempRoot "package"
$testToolsRoot = Join-Path $testPackageRoot "Tools~"
$testContractRoot = Join-Path $testPackageRoot "Payload~\AIWork\codedb\shared"
$installerPath = Join-Path $testToolsRoot "install-codedb-provider.ps1"
$fixtureRoot = Join-Path $tempRoot "fixture"
$archiveSourceRoot = Join-Path $tempRoot "archive-source"
$distributionPath = Join-Path $tempRoot "distribution.json"
$developmentDistributionPath = Join-Path $tempRoot "distribution-development.json"
$archivePath = Join-Path $tempRoot "codedb-provider-0.5.0-28e3912-windows-x64.zip"
$signaturePath = Join-Path $tempRoot "codedb-provider-0.5.0-28e3912-windows-x64.zip.sig"
$localAppDataRoot = Join-Path $fixtureRoot "LocalAppData"
$projectSentinel = Join-Path $fixtureRoot "project-sentinel.txt"

function Assert-True {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Actual, $Expected, [Parameter(Mandatory = $true)][string]$Label)
    if (-not [string]::Equals([string]$Actual, [string]$Expected, [StringComparison]::Ordinal)) {
        throw "$Label mismatch. Expected '$Expected', got '$Actual'."
    }
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Get-Hash {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function New-ProviderManifest {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutableHash,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $manifest = [ordered]@{
        schema_version = 1
        provider_id = "killop/codedb-mcp"
        version = "0.5.0-28e3912"
        commit = "28e3912d5cd67ff3499734984f3e3d626a204796"
        executable = "codebase-mcp.exe"
        sha256 = $ExecutableHash
        protocol = "codedb-cli-v1"
        source = "https://github.com/killop/codedb-mcp"
        supported_package_min_inclusive = "0.2.5-preview.5"
        supported_package_max_exclusive = "0.2.6"
    }
    $path = Join-Path $Root "provider-manifest.json"
    Write-Utf8NoBom -Path $path -Text (($manifest | ConvertTo-Json -Compress))
    return $path
}

function New-DistributionManifest {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveHash,
        [Parameter(Mandatory = $true)][string]$SignatureHash,
        [Parameter(Mandatory = $true)][string]$ExecutableHash,
        [Parameter(Mandatory = $true)][string]$PublicKeyXml
    )

    $manifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        distribution_state = "READY"
        provider_id = "killop/codedb-mcp"
        version = "0.5.0-28e3912"
        commit = "28e3912d5cd67ff3499734984f3e3d626a204796"
        protocol = "codedb-cli-v1"
        source = "https://github.com/killop/codedb-mcp"
        supported_package_min_inclusive = "0.2.5-preview.5"
        supported_package_max_exclusive = "0.2.6"
        release_base_url = ""
        archive_name = "codedb-provider-0.5.0-28e3912-windows-x64.zip"
        archive_sha256 = $ArchiveHash
        signature_name = "codedb-provider-0.5.0-28e3912-windows-x64.zip.sig"
        signature_encoding = "base64"
        signature_sha256 = $SignatureHash
        signature_algorithm = "RSA-SHA256"
        signature_public_key_xml = $PublicKeyXml
        executable_sha256 = $ExecutableHash
        license_status = "APPROVED"
    }
    Write-Utf8NoBom -Path $distributionPath -Text (($manifest | ConvertTo-Json -Compress))
}

function New-DevelopmentDistributionManifest {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutableHash,
        [string]$Path = $developmentDistributionPath
    )

    $manifest = [ordered]@{
        schema_version = 1
        managed_by = "com.rice.ai-codedb"
        distribution_state = "DEVELOPMENT_UPSTREAM"
        provider_id = "killop/codedb-mcp"
        version = "0.5.0-28e3912"
        commit = "28e3912d5cd67ff3499734984f3e3d626a204796"
        protocol = "codedb-cli-v1"
        source = "https://github.com/killop/codedb-mcp"
        supported_package_min_inclusive = "0.2.5-preview.5"
        supported_package_max_exclusive = "0.2.6"
        release_base_url = ""
        archive_name = "codebase-mcp.exe"
        archive_sha256 = $ExecutableHash
        signature_name = ""
        signature_encoding = ""
        signature_sha256 = ""
        signature_algorithm = ""
        signature_public_key_xml = ""
        executable_sha256 = $ExecutableHash
        license_status = "PENDING"
    }
    Write-Utf8NoBom -Path $Path -Text (($manifest | ConvertTo-Json -Compress))
}

function Invoke-Installer {
    param(
        [switch]$FailAfterBackup,
        [switch]$FailTemporaryCleanup,
        [switch]$DownloadTimeout,
        [string]$DistributionOverride = ""
    )
    $arguments = @(
        '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $installerPath,
        '-PackageVersion', '0.2.5-preview.5', '-TestMode',
        '-LocalAppDataRoot', $localAppDataRoot,
        '-TestArchivePath', $archivePath,
        '-TestSignaturePath', $signaturePath
    )
    if ($FailAfterBackup) { $arguments += '-TestFailAfterBackup' }
    if ($FailTemporaryCleanup) { $arguments += '-TestFailTemporaryCleanup' }
    if ($DownloadTimeout) { $arguments += '-TestDownloadTimeout' }
    $manifestArgument = if ([string]::IsNullOrWhiteSpace($DistributionOverride)) { $distributionPath } else { $DistributionOverride }
    $arguments += @('-TestDistributionManifestPath', $manifestArgument)
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $script:LastInstallerOutput = @(& powershell.exe @arguments 2>&1)
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $code = $LASTEXITCODE
    $script:LastInstallerOutput | ForEach-Object { Write-Host $_ }
    return $code
}

function Invoke-ProductionTestModeAttempt {
    $arguments = @(
        '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $originalInstallerPath,
        '-PackageVersion', '0.2.5-preview.5', '-TestMode',
        '-LocalAppDataRoot', $localAppDataRoot,
        '-TestArchivePath', $archivePath,
        '-TestSignaturePath', $signaturePath,
        '-TestDistributionManifestPath', $distributionPath
    )
    & powershell.exe @arguments | ForEach-Object { Write-Host $_ }
    return $LASTEXITCODE
}

function Invoke-DevelopmentInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$ArtifactPath,
        [Parameter(Mandatory = $true)][string]$DistributionPath,
        [Parameter(Mandatory = $true)][string]$LocalAppDataPath
    )

    $arguments = @(
        '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $installerPath,
        '-PackageVersion', '0.2.5-preview.5', '-TestMode',
        '-LocalAppDataRoot', $LocalAppDataPath,
        '-TestArchivePath', $ArtifactPath,
        '-TestDistributionManifestPath', $DistributionPath
    )
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $script:LastInstallerOutput = @(& powershell.exe @arguments 2>&1)
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $code = $LASTEXITCODE
    $script:LastInstallerOutput | ForEach-Object { Write-Host $_ }
    return $code
}

try {
    [System.IO.Directory]::CreateDirectory($archiveSourceRoot) | Out-Null
    [System.IO.Directory]::CreateDirectory($fixtureRoot) | Out-Null
    [System.IO.Directory]::CreateDirectory($testToolsRoot) | Out-Null
    [System.IO.Directory]::CreateDirectory($testContractRoot) | Out-Null
    Copy-Item -LiteralPath $originalInstallerPath -Destination $installerPath
    Copy-Item -LiteralPath $providerContractPath -Destination (Join-Path $testContractRoot "codedb-machine-provider-contract.ps1")
    Write-Utf8NoBom -Path $projectSentinel -Text "project bytes must remain unchanged"

    $executablePath = Join-Path $archiveSourceRoot "codebase-mcp.exe"
    Write-Utf8NoBom -Path $executablePath -Text "fixed Provider fixture bytes"
    $null = New-ProviderManifest -ExecutableHash (Get-Hash $executablePath) -Root $archiveSourceRoot
    Write-Utf8NoBom -Path (Join-Path $archiveSourceRoot "THIRD-PARTY-NOTICES.txt") -Text "Reviewed fixture notice"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $archiveSourceRoot,
        $archivePath,
        [System.IO.Compression.CompressionLevel]::NoCompression,
        $false)

    $rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new(2048)
    try {
        $rsa.PersistKeyInCsp = $false
        $signature = $rsa.SignData(
            [System.IO.File]::ReadAllBytes($archivePath),
            "SHA256")
        Write-Utf8NoBom -Path $signaturePath -Text ([Convert]::ToBase64String($signature))
        New-DistributionManifest `
            -ArchiveHash (Get-Hash $archivePath) `
            -SignatureHash (Get-Hash $signaturePath) `
            -ExecutableHash (Get-Hash $executablePath) `
            -PublicKeyXml $rsa.ToXmlString($false)
    } finally {
        $rsa.Dispose()
    }

    $productionTestModeExit = Invoke-ProductionTestModeAttempt
    Assert-Equal -Actual $productionTestModeExit -Expected 4 -Label "Package production TestMode rejection exit code"

    $downloadTimeoutExit = Invoke-Installer -DownloadTimeout
    Assert-Equal -Actual $downloadTimeoutExit -Expected 4 -Label "Provider download timeout exit code"
    Assert-True `
        -Condition ((($script:LastInstallerOutput | ForEach-Object { [string]$_ }) -join "`n") -match "PROVIDER_DOWNLOAD_TIMEOUT") `
        -Message "Provider download timeout did not report its bounded failure reason."
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Join-Path $localAppDataRoot "Rice\CodeDB\providers\0.5.0-28e3912"))) `
        -Message "Provider download timeout created an installation."
    Assert-Equal -Actual (Get-Content -LiteralPath $projectSentinel -Raw) -Expected "project bytes must remain unchanged" -Label "Download timeout project sentinel"

    $developmentLocalAppDataRoot = Join-Path $fixtureRoot "DevelopmentLocalAppData"
    New-DevelopmentDistributionManifest -ExecutableHash (Get-Hash $executablePath)
    $developmentExit = Invoke-DevelopmentInstaller `
        -ArtifactPath $executablePath `
        -DistributionPath $developmentDistributionPath `
        -LocalAppDataPath $developmentLocalAppDataRoot
    Assert-Equal -Actual $developmentExit -Expected 0 -Label "Development Provider installation exit code"
    $developmentInstalledRoot = Join-Path $developmentLocalAppDataRoot "Rice\CodeDB\providers\0.5.0-28e3912"
    Assert-Equal `
        -Actual (Get-Hash (Join-Path $developmentInstalledRoot "codebase-mcp.exe")) `
        -Expected (Get-Hash $executablePath) `
        -Label "Development Provider executable bytes"
    $developmentOutput = ($script:LastInstallerOutput | ForEach-Object { [string]$_ }) -join "`n"
    foreach ($stage in 1..5) {
        Assert-True `
            -Condition ($developmentOutput -match "\[PROVIDER_STAGE\] $stage/6 ") `
            -Message "Development Provider installer did not report stage $stage."
    }
    $developmentManifest = Get-Content -LiteralPath (Join-Path $developmentInstalledRoot "provider-manifest.json") -Raw | ConvertFrom-Json
    Assert-Equal -Actual $developmentManifest.commit -Expected "28e3912d5cd67ff3499734984f3e3d626a204796" -Label "Development Provider commit"
    Assert-Equal -Actual $developmentManifest.sha256 -Expected (Get-Hash $executablePath) -Label "Development Provider manifest hash"
    Assert-Equal -Actual (Get-Content -LiteralPath $projectSentinel -Raw) -Expected "project bytes must remain unchanged" -Label "Development project sentinel"
    $developmentRepeatExit = Invoke-DevelopmentInstaller `
        -ArtifactPath $executablePath `
        -DistributionPath $developmentDistributionPath `
        -LocalAppDataPath $developmentLocalAppDataRoot
    Assert-Equal -Actual $developmentRepeatExit -Expected 0 -Label "Development Provider idempotent exit code"

    $developmentWrongHashPath = Join-Path $tempRoot "distribution-development-wrong-hash.json"
    New-DevelopmentDistributionManifest -ExecutableHash ("0" * 64) -Path $developmentWrongHashPath
    $developmentWrongHashRoot = Join-Path $fixtureRoot "DevelopmentWrongHashLocalAppData"
    $developmentWrongHashExit = Invoke-DevelopmentInstaller `
        -ArtifactPath $executablePath `
        -DistributionPath $developmentWrongHashPath `
        -LocalAppDataPath $developmentWrongHashRoot
    Assert-Equal -Actual $developmentWrongHashExit -Expected 4 -Label "Development Provider wrong hash exit code"
    Assert-True `
        -Condition (-not (Test-Path -LiteralPath (Join-Path $developmentWrongHashRoot "Rice\CodeDB\providers\0.5.0-28e3912"))) `
        -Message "Development Provider wrong hash created an installation."

    if (-not [string]::IsNullOrWhiteSpace($RealArtifactPath)) {
        $realArtifact = [System.IO.Path]::GetFullPath($RealArtifactPath)
        Assert-True -Condition (Test-Path -LiteralPath $realArtifact -PathType Leaf) -Message "Real Provider artifact is missing."
        Assert-Equal `
            -Actual (Get-Hash $realArtifact) `
            -Expected "38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7" `
            -Label "Real fixed Provider artifact hash"
        $realArtifactLocalAppDataRoot = Join-Path $fixtureRoot "RealArtifactLocalAppData"
        $realArtifactExit = Invoke-DevelopmentInstaller `
            -ArtifactPath $realArtifact `
            -DistributionPath (Join-Path $packageRoot "Tools~\codedb-provider-distribution.json") `
            -LocalAppDataPath $realArtifactLocalAppDataRoot
        Assert-Equal -Actual $realArtifactExit -Expected 0 -Label "Real fixed Provider artifact installation exit code"
        Assert-Equal `
            -Actual (Get-Hash (Join-Path $realArtifactLocalAppDataRoot "Rice\CodeDB\providers\0.5.0-28e3912\codebase-mcp.exe")) `
            -Expected "38c7d07dde2fa9e322ac0dcbb5ca8961921c8ea6aad548e6bd36e2277752e5e7" `
            -Label "Installed real fixed Provider artifact hash"
    }

    $firstExit = Invoke-Installer -FailTemporaryCleanup
    Assert-Equal -Actual $firstExit -Expected 0 -Label "First Provider installation exit code"
    Assert-True `
        -Condition ((($script:LastInstallerOutput | ForEach-Object { [string]$_ }) -join "`n") -match "TEMPORARY_CLEANUP_DEFERRED") `
        -Message "Committed Provider cleanup warning was not reported."
    $installedRoot = Join-Path $localAppDataRoot "Rice\CodeDB\providers\0.5.0-28e3912"
    Assert-True -Condition (Test-Path -LiteralPath (Join-Path $installedRoot "codebase-mcp.exe") -PathType Leaf) -Message "Verified Provider executable was not installed."
    $installedExecutableHash = Get-Hash (Join-Path $installedRoot "codebase-mcp.exe")
    $installedManifestHash = Get-Hash (Join-Path $installedRoot "provider-manifest.json")
    $installedExecutablePath = Join-Path $installedRoot "codebase-mcp.exe"
    $installedExecutableBytes = [System.IO.File]::ReadAllBytes($installedExecutablePath)

    $unexpectedEntryPath = Join-Path $installedRoot "unexpected-provider-file.txt"
    Write-Utf8NoBom -Path $unexpectedEntryPath -Text "unexpected Provider bytes"
    $unexpectedEntryExit = Invoke-Installer
    Assert-Equal -Actual $unexpectedEntryExit -Expected 4 -Label "Unexpected Provider entry exit code"
    Assert-True -Condition (Test-Path -LiteralPath $unexpectedEntryPath -PathType Leaf) -Message "Unexpected Provider entry was removed instead of preserved."
    Remove-Item -LiteralPath $unexpectedEntryPath -Force

    Write-Utf8NoBom -Path $installedExecutablePath -Text "tampered Provider bytes"
    $tamperedBytesHash = Get-Hash $installedExecutablePath
    $tamperedExit = Invoke-Installer -FailAfterBackup
    Assert-Equal -Actual $tamperedExit -Expected 4 -Label "Tampered existing Provider exit code"
    Assert-Equal -Actual (Get-Hash $installedExecutablePath) -Expected $tamperedBytesHash -Label "Tampered Provider bytes preserved"
    [System.IO.File]::WriteAllBytes($installedExecutablePath, $installedExecutableBytes)

    $duplicateDistributionPath = Join-Path $tempRoot "distribution-duplicate.json"
    Write-Utf8NoBom -Path $duplicateDistributionPath -Text '{"schema_version":1,"schema_version":1}'
    $duplicateExit = Invoke-Installer -DistributionOverride $duplicateDistributionPath
    Assert-Equal -Actual $duplicateExit -Expected 4 -Label "Duplicate distribution manifest exit code"
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "codebase-mcp.exe")) -Expected $installedExecutableHash -Label "Duplicate manifest executable bytes"

    $wrongTypeDistributionPath = Join-Path $tempRoot "distribution-wrong-type.json"
    Write-Utf8NoBom -Path $wrongTypeDistributionPath -Text '{"schema_version":true}'
    $wrongTypeExit = Invoke-Installer -DistributionOverride $wrongTypeDistributionPath
    Assert-Equal -Actual $wrongTypeExit -Expected 4 -Label "Wrong-type distribution manifest exit code"
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "provider-manifest.json")) -Expected $installedManifestHash -Label "Wrong-type manifest bytes"

    $secondExit = Invoke-Installer
    Assert-Equal -Actual $secondExit -Expected 0 -Label "Idempotent Provider installation exit code"
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "codebase-mcp.exe")) -Expected $installedExecutableHash -Label "Idempotent executable bytes"
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "provider-manifest.json")) -Expected $installedManifestHash -Label "Idempotent manifest bytes"

    $failedExit = Invoke-Installer -FailAfterBackup
    Assert-Equal -Actual $failedExit -Expected 4 -Label "Injected Provider replacement failure exit code"
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "codebase-mcp.exe")) -Expected $installedExecutableHash -Label "Rollback executable bytes"
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "provider-manifest.json")) -Expected $installedManifestHash -Label "Rollback manifest bytes"

    $providersRoot = Split-Path -Parent $installedRoot
    $interruptedBackup = Join-Path $providersRoot ".0.5.0-28e3912.backup-interrupted"
    Move-Item -LiteralPath $installedRoot -Destination $interruptedBackup
    $recoveryExit = Invoke-Installer
    Assert-Equal -Actual $recoveryExit -Expected 0 -Label "Interrupted Provider backup recovery exit code"
    Assert-True -Condition (Test-Path -LiteralPath $installedRoot -PathType Container) -Message "Interrupted Provider backup was not recovered."
    Assert-Equal -Actual (Get-Hash (Join-Path $installedRoot "codebase-mcp.exe")) -Expected $installedExecutableHash -Label "Recovered executable bytes"
    Assert-Equal -Actual (Get-Content -LiteralPath $projectSentinel -Raw) -Expected "project bytes must remain unchanged" -Label "Project sentinel"

    Write-Host "[OK] Provider installer focused regression passed."
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
