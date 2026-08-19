#requires -Version 5.1

Set-StrictMode -Version Latest

$script:CodedbRequiredProviderId = "killop/codedb-mcp"
$script:CodedbRequiredProviderVersion = "0.5.0"
$script:CodedbRequiredProviderCommit = "13de004783d21de631c4c85bf4803a4866de55e4"
$script:CodedbRequiredProviderProtocol = "codedb-cli-v1"
$script:CodedbRequiredProviderSource = "https://github.com/killop/codedb-mcp"
$script:CodedbSupportedPackageMinInclusive = "0.2.5-preview.5"
$script:CodedbSupportedPackageMaxExclusive = "0.2.6"
$script:CodedbSupportedNodeMajors = @(22, 24)

function Throw-CodedbPrerequisiteError {
    param(
        [Parameter(Mandatory = $true)][string]$ReasonCode,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $exception = [System.InvalidOperationException]::new($Message)
    $exception.Data["CodeDBPrerequisiteReason"] = $ReasonCode
    throw $exception
}

function Read-CodedbProviderJsonStringToken {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -cne '"') {
        throw "$Label expected a JSON string at character $($State.Index)."
    }
    $start = $State.Index
    $State.Index++
    $escaped = $false
    while ($State.Index -lt $State.Text.Length) {
        $character = $State.Text[$State.Index]
        if ([int]$character -lt 0x20) {
            throw "$Label contains a control character in a JSON string."
        }
        $State.Index++
        if ($escaped) {
            $escaped = $false
            continue
        }
        if ($character -ceq '\') {
            $escaped = $true
            continue
        }
        if ($character -ceq '"') {
            $token = $State.Text.Substring($start, $State.Index - $start)
            try {
                $value = $token | ConvertFrom-Json -ErrorAction Stop
            } catch {
                throw "$Label contains an invalid JSON string token. $($_.Exception.Message)"
            }
            if ($value -isnot [string]) {
                throw "$Label JSON string token did not decode to a string."
            }
            return [string]$value
        }
    }
    throw "$Label contains an unterminated JSON string."
}

function Skip-CodedbProviderJsonWhitespace {
    param([Parameter(Mandatory = $true)]$State)

    while ($State.Index -lt $State.Text.Length -and
        @(' ', "`t", "`r", "`n") -contains $State.Text[$State.Index]) {
        $State.Index++
    }
}

function ConvertFrom-CodedbProviderManifestJson {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $state = [pscustomobject]@{ Text = $Text; Index = 0 }
    Skip-CodedbProviderJsonWhitespace -State $state
    if ($state.Index -ge $state.Text.Length -or $state.Text[$state.Index] -cne '{') {
        throw "$Label must contain one JSON object."
    }
    $state.Index++
    Skip-CodedbProviderJsonWhitespace -State $state
    $properties = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    if ($state.Index -lt $state.Text.Length -and $state.Text[$state.Index] -ceq '}') {
        $state.Index++
    } else {
        while ($true) {
            $name = Read-CodedbProviderJsonStringToken -State $state -Label $Label
            if ($properties.ContainsKey($name)) {
                throw "$Label contains duplicate property: $name"
            }
            Skip-CodedbProviderJsonWhitespace -State $state
            if ($state.Index -ge $state.Text.Length -or $state.Text[$state.Index] -cne ':') {
                throw "$Label expected : after property $name."
            }
            $state.Index++
            Skip-CodedbProviderJsonWhitespace -State $state
            if ($state.Index -ge $state.Text.Length) {
                throw "$Label is missing the value for property $name."
            }
            if ($state.Text[$state.Index] -ceq '"') {
                $value = Read-CodedbProviderJsonStringToken -State $state -Label $Label
            } else {
                $remaining = $state.Text.Substring($state.Index)
                $match = [regex]::Match(
                    $remaining,
                    '^-?(?:0|[1-9][0-9]*)',
                    [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
                if (-not $match.Success) {
                    throw "$Label property $name must be a JSON string or signed integer."
                }
                [int64]$integer = 0
                if (-not [int64]::TryParse(
                    $match.Value,
                    [Globalization.NumberStyles]::AllowLeadingSign,
                    [Globalization.CultureInfo]::InvariantCulture,
                    [ref]$integer)) {
                    throw "$Label property $name is outside the signed 64-bit integer range."
                }
                $state.Index += $match.Length
                $value = $integer
            }
            $properties.Add($name, $value)
            Skip-CodedbProviderJsonWhitespace -State $state
            if ($state.Index -ge $state.Text.Length) {
                throw "$Label contains an unterminated JSON object."
            }
            if ($state.Text[$state.Index] -ceq '}') {
                $state.Index++
                break
            }
            if ($state.Text[$state.Index] -cne ',') {
                throw "$Label expected , between properties."
            }
            $state.Index++
            Skip-CodedbProviderJsonWhitespace -State $state
        }
    }
    Skip-CodedbProviderJsonWhitespace -State $state
    if ($state.Index -ne $state.Text.Length) {
        throw "$Label contains trailing JSON content at character $($state.Index)."
    }
    return $properties
}

function Get-CodedbProviderManifestString {
    param(
        [Parameter(Mandatory = $true)]$Properties,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not $Properties.ContainsKey($Name) -or $Properties[$Name] -isnot [string]) {
        throw "Provider manifest property $Name must be a JSON string."
    }
    return [string]$Properties[$Name]
}

function Get-CodedbProviderManifestInt32 {
    param(
        [Parameter(Mandatory = $true)]$Properties,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not $Properties.ContainsKey($Name) -or
        $Properties[$Name] -isnot [int64] -or
        $Properties[$Name] -lt [int]::MinValue -or
        $Properties[$Name] -gt [int]::MaxValue) {
        throw "Provider manifest property $Name must be a signed 32-bit JSON integer."
    }
    return [int]$Properties[$Name]
}

function Read-CodedbProviderManifest {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_MISSING" -Message "CodeDB Provider 0.5.0 is missing. Install the reviewed machine Provider, then let Unity recheck automatically."
    }
    $file = Get-Item -LiteralPath $Path -Force
    if ($file.Length -le 0 -or $file.Length -gt 65536) {
        throw "Provider manifest size is outside the accepted range."
    }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -le 0 -or $bytes.Length -gt 65536) {
        throw "Provider manifest size changed outside the accepted range while it was read."
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "Provider manifest must be UTF-8 without a byte-order mark."
    }
    $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
    $text = $strictUtf8.GetString($bytes)
    return ConvertFrom-CodedbProviderManifestJson -Text $text -Label "Provider manifest"
}

function Assert-CodedbMachinePathNoReparsePoint {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $prefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not [string]::Equals($fullPath, $fullRoot, [StringComparison]::OrdinalIgnoreCase) -and
        -not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Label escapes the machine Provider root."
    }
    $current = $fullPath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Label traverses a reparse point: $current"
            }
        }
        if ([string]::Equals($current, $fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $current = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($current)) {
            throw "$Label could not be validated inside the machine Provider root."
        }
    }
}

function Get-CodedbFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = $null
    $sha256 = $null
    try {
        $stream = [System.IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        return (($sha256.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
        if ($null -ne $sha256) { $sha256.Dispose() }
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Get-CodedbSupportedNode {
    $command = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command -or [string]::IsNullOrWhiteSpace($command.Source)) {
        Throw-CodedbPrerequisiteError -ReasonCode "NODE_MISSING" -Message "CodeDB requires Node.js 22.x or 24.x LTS. Install a supported Node.js runtime, then let Unity recheck automatically."
    }
    $nodePath = [System.IO.Path]::GetFullPath($command.Source)
    if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf) -or
        ((Get-Item -LiteralPath $nodePath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        Throw-CodedbPrerequisiteError -ReasonCode "NODE_INVALID" -Message "The resolved Node.js executable is not a regular machine file. Install Node.js 22.x or 24.x LTS, then let Unity recheck automatically."
    }
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $nodePath
    $startInfo.Arguments = "--version"
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(5000)) {
            $process.Kill()
            $process.WaitForExit()
            Throw-CodedbPrerequisiteError -ReasonCode "NODE_INVALID" -Message "The resolved Node.js runtime did not report its version within 5 seconds. Install Node.js 22.x or 24.x LTS, then let Unity recheck automatically."
        }
        $versionText = $stdout.Result.Trim()
        $null = $stderr.Result
        $match = [regex]::Match($versionText, '^v(?<major>[0-9]+)\.(?<minor>[0-9]+)\.(?<patch>[0-9]+)$', [Text.RegularExpressions.RegexOptions]::CultureInvariant)
        if ($process.ExitCode -ne 0 -or -not $match.Success -or
            $script:CodedbSupportedNodeMajors -notcontains [int]$match.Groups['major'].Value) {
            Throw-CodedbPrerequisiteError -ReasonCode "NODE_INCOMPATIBLE" -Message "CodeDB requires Node.js 22.x or 24.x LTS. Install a supported Node.js runtime, then let Unity recheck automatically."
        }
        return [pscustomobject]@{ Path = $nodePath; Version = $versionText }
    } finally {
        $process.Dispose()
    }
}

function ConvertTo-CodedbSemanticVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    $match = [regex]::Match(
        $Version,
        '^(?<major>0|[1-9][0-9]*)\.(?<minor>0|[1-9][0-9]*)\.(?<patch>0|[1-9][0-9]*)(?:-(?<prerelease>[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$',
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
    if (-not $match.Success) {
        throw "Package version is not a supported semantic version: $Version"
    }
    $prerelease = [string]$match.Groups['prerelease'].Value
    $identifiers = if ([string]::IsNullOrEmpty($prerelease)) { @() } else { @($prerelease.Split('.')) }
    foreach ($identifier in $identifiers) {
        if ($identifier -cmatch '^[0-9]+$' -and $identifier.Length -gt 1 -and $identifier[0] -ceq '0') {
            throw "Package semantic version has a zero-padded numeric prerelease identifier: $Version"
        }
    }
    return [pscustomobject]@{
        Major = [string]$match.Groups['major'].Value
        Minor = [string]$match.Groups['minor'].Value
        Patch = [string]$match.Groups['patch'].Value
        HasPrerelease = -not [string]::IsNullOrEmpty($prerelease)
        Prerelease = [string[]]$identifiers
    }
}

function Compare-CodedbNumericVersionIdentifier {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return $(if ($Left.Length -lt $Right.Length) { -1 } else { 1 })
    }
    return [Math]::Sign([string]::Compare($Left, $Right, [StringComparison]::Ordinal))
}

function Compare-CodedbSemanticVersion {
    param(
        [Parameter(Mandatory = $true)][string]$Left,
        [Parameter(Mandatory = $true)][string]$Right
    )

    $leftVersion = ConvertTo-CodedbSemanticVersion -Version $Left
    $rightVersion = ConvertTo-CodedbSemanticVersion -Version $Right
    [string[]]$leftPrerelease = if ($leftVersion.HasPrerelease) { [string[]]$leftVersion.Prerelease } else { [string[]]@() }
    [string[]]$rightPrerelease = if ($rightVersion.HasPrerelease) { [string[]]$rightVersion.Prerelease } else { [string[]]@() }
    foreach ($name in @('Major', 'Minor', 'Patch')) {
        $comparison = Compare-CodedbNumericVersionIdentifier `
            -Left ([string]$leftVersion.$name) `
            -Right ([string]$rightVersion.$name)
        if ($comparison -ne 0) { return $comparison }
    }
    if (-not $leftVersion.HasPrerelease -or -not $rightVersion.HasPrerelease) {
        if ($leftVersion.HasPrerelease -eq $rightVersion.HasPrerelease) { return 0 }
        return $(if (-not $leftVersion.HasPrerelease) { 1 } else { -1 })
    }
    $count = [Math]::Min($leftPrerelease.Count, $rightPrerelease.Count)
    for ($index = 0; $index -lt $count; $index++) {
        $leftIdentifier = [string]$leftPrerelease[$index]
        $rightIdentifier = [string]$rightPrerelease[$index]
        $leftNumeric = $leftIdentifier -cmatch '^[0-9]+$'
        $rightNumeric = $rightIdentifier -cmatch '^[0-9]+$'
        if ($leftNumeric -and $rightNumeric) {
            $comparison = Compare-CodedbNumericVersionIdentifier -Left $leftIdentifier -Right $rightIdentifier
        } elseif ($leftNumeric -ne $rightNumeric) {
            $comparison = if ($leftNumeric) { -1 } else { 1 }
        } else {
            $comparison = [Math]::Sign([string]::Compare($leftIdentifier, $rightIdentifier, [StringComparison]::Ordinal))
        }
        if ($comparison -ne 0) { return $comparison }
    }
    return [Math]::Sign($leftPrerelease.Count - $rightPrerelease.Count)
}

function Assert-CodedbMachineProvider {
    param([Parameter(Mandatory = $true)][string]$PackageVersion)

    if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_ROOT_UNAVAILABLE" -Message "Windows LOCALAPPDATA is unavailable, so the CodeDB machine Provider cannot be verified."
    }
    $localAppData = [System.IO.Path]::GetFullPath($env:LOCALAPPDATA)
    $providerRoot = Join-Path $localAppData "Rice\CodeDB\providers\$($script:CodedbRequiredProviderVersion)"
    $manifestPath = Join-Path $providerRoot "provider-manifest.json"
    $executablePath = Join-Path $providerRoot "codebase-mcp.exe"
    Assert-CodedbMachinePathNoReparsePoint -Path $providerRoot -Root $localAppData -Label "CodeDB machine Provider root"
    Assert-CodedbMachinePathNoReparsePoint -Path $manifestPath -Root $localAppData -Label "CodeDB Provider manifest"
    Assert-CodedbMachinePathNoReparsePoint -Path $executablePath -Root $localAppData -Label "CodeDB Provider executable"
    if (-not (Test-Path -LiteralPath $providerRoot -PathType Container) -or
        -not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
        Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_MISSING" -Message "CodeDB Provider 0.5.0 is missing. Install it under %LOCALAPPDATA%\Rice\CodeDB\providers\0.5.0, then let Unity recheck automatically."
    }

    try {
        $manifest = Read-CodedbProviderManifest -Path $manifestPath
        $expectedNames = @(
            "schema_version", "provider_id", "version", "commit", "executable", "sha256",
            "protocol", "source", "supported_package_min_inclusive", "supported_package_max_exclusive"
        )
        if ($manifest.Count -ne $expectedNames.Count -or @($manifest.Keys | Where-Object { $expectedNames -cnotcontains $_ }).Count -ne 0) {
            throw "Provider manifest properties do not match schema 1."
        }
        if ((Get-CodedbProviderManifestInt32 -Properties $manifest -Name "schema_version") -ne 1 -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "provider_id"), $script:CodedbRequiredProviderId, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "version"), $script:CodedbRequiredProviderVersion, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "commit"), $script:CodedbRequiredProviderCommit, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "executable"), "codebase-mcp.exe", [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "protocol"), $script:CodedbRequiredProviderProtocol, [StringComparison]::Ordinal) -or
            -not [string]::Equals((Get-CodedbProviderManifestString -Properties $manifest -Name "source"), $script:CodedbRequiredProviderSource, [StringComparison]::Ordinal)) {
            Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_INCOMPATIBLE" -Message "The installed CodeDB Provider identity or protocol is incompatible with this Package. Install the reviewed Provider 0.5.0 build, then let Unity recheck automatically."
        }
        $minimum = Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_min_inclusive"
        $maximum = Get-CodedbProviderManifestString -Properties $manifest -Name "supported_package_max_exclusive"
        $packageInRange = $false
        try {
            $packageInRange = (Compare-CodedbSemanticVersion -Left $PackageVersion -Right $minimum) -ge 0 -and
                (Compare-CodedbSemanticVersion -Left $PackageVersion -Right $maximum) -lt 0
        } catch {
            $packageInRange = $false
        }
        if (-not [string]::Equals($minimum, $script:CodedbSupportedPackageMinInclusive, [StringComparison]::Ordinal) -or
            -not [string]::Equals($maximum, $script:CodedbSupportedPackageMaxExclusive, [StringComparison]::Ordinal) -or
            -not $packageInRange) {
            Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_PACKAGE_INCOMPATIBLE" -Message "The installed CodeDB Provider does not support Package $PackageVersion. Install a compatible machine Provider, then let Unity recheck automatically."
        }
        $expectedSha256 = (Get-CodedbProviderManifestString -Properties $manifest -Name "sha256").ToLowerInvariant()
        if ($expectedSha256 -cnotmatch '^[0-9a-f]{64}$' -or
            -not [string]::Equals((Get-CodedbFileSha256 -Path $executablePath), $expectedSha256, [StringComparison]::Ordinal)) {
            Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_HASH_MISMATCH" -Message "The installed CodeDB Provider hash does not match its manifest. Reinstall the reviewed Provider 0.5.0 build, then let Unity recheck automatically."
        }
    } catch {
        if ($_.Exception.Data.Contains("CodeDBPrerequisiteReason")) { throw }
        Throw-CodedbPrerequisiteError -ReasonCode "PROVIDER_INVALID" -Message "The CodeDB Provider manifest is invalid: $($_.Exception.Message)"
    }
    return [pscustomobject]@{
        Version = $script:CodedbRequiredProviderVersion
        Root = [System.IO.Path]::GetFullPath($providerRoot)
        ManifestPath = [System.IO.Path]::GetFullPath($manifestPath)
        ExecutablePath = [System.IO.Path]::GetFullPath($executablePath)
    }
}

function Get-CodedbMachinePrerequisiteStatus {
    param([Parameter(Mandatory = $true)][string]$PackageVersion)

    try {
        $node = Get-CodedbSupportedNode
        $provider = Assert-CodedbMachineProvider -PackageVersion $PackageVersion
        return [pscustomobject]@{
            Current = $true
            State = "CURRENT"
            ReasonCode = "PREREQUISITES_CURRENT"
            Detail = "Node.js $($node.Version) and CodeDB Provider $($provider.Version) are verified."
            NextAction = "No action required."
            NodePath = $node.Path
            NodeVersion = $node.Version
            ProviderVersion = $provider.Version
            ProviderRoot = $provider.Root
            ProviderManifestPath = $provider.ManifestPath
            ProviderExecutablePath = $provider.ExecutablePath
        }
    } catch {
        $reason = if ($_.Exception.Data.Contains("CodeDBPrerequisiteReason")) {
            [string]$_.Exception.Data["CodeDBPrerequisiteReason"]
        } else {
            "PREREQUISITE_INVALID"
        }
        return [pscustomobject]@{
            Current = $false
            State = "MISSING"
            ReasonCode = $reason
            Detail = $_.Exception.Message
            NextAction = $_.Exception.Message
            NodePath = ""
            NodeVersion = ""
            ProviderVersion = $script:CodedbRequiredProviderVersion
            ProviderRoot = ""
            ProviderManifestPath = ""
            ProviderExecutablePath = ""
        }
    }
}
