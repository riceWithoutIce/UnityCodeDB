#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("DryRun", "Verify", "Sync", "Remove")]
    [string]$Action = "DryRun",

    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$PayloadRoot,

    [switch]$PocFixture,

    [string]$TrackedHostAuthorizationPath,

    [switch]$ConfirmLegacyMcpStopped,

    [ValidateRange(0, 1000)]
    [int]$TestFailAfterMutation = 0,

    [ValidateRange(0, 1000)]
    [int]$TestCrashAfterMutation = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ManagedBy = "com.rice.ai-codedb"
$script:MarkerRelativePath = "AIWork/codedb/.rice-ai-codedb-payload.json"
$script:TargetPrefix = "AIWork/codedb/"
$script:RuntimeRelativePath = "AIWork/.runtime/codedb/payload-materializer"
$script:PocFixtureMarkerName = ".rice-ai-codedb-poc-fixture.json"
$script:TrackedHostAuthorizationDirectoryName = "authorizations"
$script:TrackedHostAuthorizationRelativeRoot = "AIWork/.runtime/codedb/payload-materializer/$($script:TrackedHostAuthorizationDirectoryName)"
$script:TrackedHostAuthorizationPurpose = "tracked-host-payload-mutation"
$script:TrackedHostAuthorizationAcknowledgement = "I authorize com.rice.ai-codedb to mutate only its audited host payload scope."
$script:HostUseGateVersion = 1
$script:ActiveMarkerName = "materialize-active.json"
$script:HostUseLeaseDirectoryName = "host-use-leases"
$script:TransactionPrefix = "txn-v1-"
$script:TransactionJournalName = "transaction.json"
$script:RequestedExitCode = 0
$script:MutationCount = 0
$script:AllowedTargetPaths = @{}
foreach ($allowedTarget in @(
    "AIWork/codedb/codedb-mcp.runtime.example.toml",
    "AIWork/codedb/codedbignore.example",
    "AIWork/codedb/coordinator/codedb-watch-coordinator.mjs",
    "AIWork/codedb/shared/codedb-host-use-gate.mjs",
    "AIWork/codedb/wrapper/codedb-project-wrapper.mjs",
    "AIWork/codedb/scripts/build-codedb-project-text-adapter.ps1",
    "AIWork/codedb/scripts/check-codedb-project-freshness.ps1",
    "AIWork/codedb/scripts/clear-codedb-project-index.ps1",
    "AIWork/codedb/scripts/codedb-project-common.ps1",
    "AIWork/codedb/scripts/emit-codedb-mcp-registration-draft.ps1",
    "AIWork/codedb/scripts/manage-codedb-project-watch.ps1",
    "AIWork/codedb/scripts/prepare-codedb-project-runtime.ps1",
    "AIWork/codedb/scripts/prepare-codedb-project-watch-config.ps1",
    "AIWork/codedb/scripts/probe-codedb-project-index.ps1",
    "AIWork/codedb/scripts/probe-codedb-project-text-adapter.ps1",
    "AIWork/codedb/scripts/refresh-codedb-project-if-stale.ps1",
    "AIWork/codedb/scripts/refresh-codedb-project.ps1",
    "AIWork/codedb/scripts/run-codedb-project-text-adapter-worker.ps1",
    "AIWork/codedb/scripts/show-codedb-project-provider-guidance.ps1",
    "AIWork/codedb/scripts/validate-codedb-mcp-project-config.ps1",
    "AIWork/codedb/scripts/verify-codedb-project.ps1"
)) {
    $script:AllowedTargetPaths[$allowedTarget] = $true
}

function Throw-MaterializerError {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )

    $script:RequestedExitCode = $ExitCode
    $exception = [System.InvalidOperationException]::new($Message)
    $exception.Data["MaterializerExitCode"] = $ExitCode
    throw $exception
}

function Invoke-TestFaultAfterMutation {
    if ($TestFailAfterMutation -le 0 -and $TestCrashAfterMutation -le 0) {
        return
    }

    $script:MutationCount++
    if ($script:MutationCount -eq $TestCrashAfterMutation) {
        [Console]::Error.WriteLine("Injected POC process crash after mutation $($script:MutationCount).")
        [Console]::Error.Flush()
        [Environment]::Exit(86)
    }
    if ($script:MutationCount -eq $TestFailAfterMutation) {
        throw "Injected POC failure after mutation $($script:MutationCount)."
    }
}

function Get-RequiredProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        Throw-MaterializerError -Message "$Label is missing required property '$Name'." -ExitCode 2
    }

    return $property.Value
}

function ConvertTo-SafeRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or
        [System.IO.Path]::IsPathRooted($Path) -or
        $Path.StartsWith("\\", [StringComparison]::Ordinal) -or
        $Path.IndexOf(':') -ge 0 -or
        $Path.IndexOfAny([char[]]'*?') -ge 0) {
        Throw-MaterializerError -Message "$Label must be a non-rooted, literal relative path: $Path" -ExitCode 2
    }

    $segments = @($Path.Replace('\', '/').Split('/'))
    if ($segments.Count -eq 0) {
        Throw-MaterializerError -Message "$Label is empty." -ExitCode 2
    }

    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or
            $segment -eq "." -or
            $segment -eq ".." -or
            $segment.EndsWith(".", [StringComparison]::Ordinal) -or
            $segment.EndsWith(" ", [StringComparison]::Ordinal) -or
            $segment -match '^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?$') {
            Throw-MaterializerError -Message "$Label contains an unsafe path segment: $Path" -ExitCode 2
        }

        if ($segment.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Throw-MaterializerError -Message "$Label contains invalid path characters: $Path" -ExitCode 2
        }
    }

    return $segments -join '/'
}

function Assert-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowRoot
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    $isRoot = [string]::Equals($fullPath, $fullRoot, [StringComparison]::OrdinalIgnoreCase)
    $isInside = $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
    if (-not $isInside -and -not ($AllowRoot -and $isRoot)) {
        Throw-MaterializerError -Message "$Label escapes its allowed root. Path: $fullPath Root: $fullRoot" -ExitCode 2
    }
}

function Assert-NoReparsePoint {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    Assert-PathInside -Path $fullPath -Root $fullRoot -Label $Label -AllowRoot

    $current = $fullPath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                Throw-MaterializerError -Message "$Label traverses a reparse point: $current" -ExitCode 2
            }
        }

        if ([string]::Equals($current, $fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            break
        }

        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or
            -not $parent.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "$Label could not be validated inside $fullRoot." -ExitCode 2
        }
        $current = $parent
    }
}

function ConvertTo-AbsoluteChildPath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $platformPath = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $Root $platformPath))
    Assert-PathInside -Path $absolutePath -Root $Root -Label $Label
    return $absolutePath
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Assert-UnityProjectRoot {
    param([Parameter(Mandatory = $true)][string]$Root)

    foreach ($relativePath in @("Assets", "Packages/manifest.json", "ProjectSettings/ProjectVersion.txt")) {
        $markerPath = ConvertTo-AbsoluteChildPath -Root $Root -RelativePath $relativePath -Label "Unity project marker"
        if (-not (Test-Path -LiteralPath $markerPath)) {
            Throw-MaterializerError -Message "Unity project marker is missing: $markerPath" -ExitCode 2
        }
    }
}

function Assert-PocMutationTarget {
    param([Parameter(Mandatory = $true)][string]$Root)

    if (-not $PocFixture) {
        Throw-MaterializerError -Message "This POC only permits Sync/Remove with explicit -PocFixture." -ExitCode 4
    }

    $activeGitIndex = [Environment]::GetEnvironmentVariable("GIT_INDEX_FILE", [EnvironmentVariableTarget]::Process)
    try {
        # Fixture isolation is a property of the worktree's primary index. An
        # alternate index remains active later for staged-change verification.
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $null, [EnvironmentVariableTarget]::Process)
        $gitRootLines = @(& git -C $Root rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -ne 0 -or $gitRootLines.Count -eq 0) {
            Throw-MaterializerError -Message "POC mutation target must be inside a Git worktree and ignored." -ExitCode 4
        }
        $gitRoot = [System.IO.Path]::GetFullPath([string]$gitRootLines[0])
        Assert-PathInside -Path $Root -Root $gitRoot -Label "POC fixture"
        Assert-NoReparsePoint -Path $Root -Root $gitRoot -Label "POC fixture"

        & git -C $gitRoot check-ignore -q -- $Root
        if ($LASTEXITCODE -ne 0) {
            Throw-MaterializerError -Message "POC mutation target is not Git ignored: $Root" -ExitCode 4
        }
    } finally {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $activeGitIndex, [EnvironmentVariableTarget]::Process)
    }

    $normalizedRoot = [System.IO.Path]::GetFullPath($Root).Replace('\', '/')
    $fixturePrefix = "/AIWork/.runtime/codedb/materializer-poc/"
    $prefixIndex = $normalizedRoot.LastIndexOf($fixturePrefix, [StringComparison]::OrdinalIgnoreCase)
    if ($prefixIndex -lt 0) {
        Throw-MaterializerError -Message "POC mutation target is outside the materializer fixture root: $Root" -ExitCode 4
    }
    $fixtureSuffix = $normalizedRoot.Substring($prefixIndex + $fixturePrefix.Length)
    if ($fixtureSuffix -notmatch '^(?<run>[0-9a-fA-F]{32})/fixture$') {
        Throw-MaterializerError -Message "POC mutation target must match materializer-poc/<run-id>/fixture: $Root" -ExitCode 4
    }
    $runId = $Matches['run'].ToLowerInvariant()

    $fixtureMarkerPath = Join-Path $Root $script:PocFixtureMarkerName
    if (-not (Test-Path -LiteralPath $fixtureMarkerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "POC fixture ownership marker is missing: $fixtureMarkerPath" -ExitCode 4
    }
    try {
        $fixtureMarker = Get-Content -LiteralPath $fixtureMarkerPath -Raw | ConvertFrom-Json
        $fixtureMarkerValid = [int]$fixtureMarker.schema_version -eq 1 -and
            [string]::Equals([string]$fixtureMarker.managed_by, $script:ManagedBy, [StringComparison]::Ordinal) -and
            [string]::Equals([string]$fixtureMarker.purpose, "host-payload-materializer-poc", [StringComparison]::Ordinal) -and
            [string]::Equals([string]$fixtureMarker.run_id, $runId, [StringComparison]::OrdinalIgnoreCase)
    } catch {
        $fixtureMarkerValid = $false
    }
    if (-not $fixtureMarkerValid) {
        Throw-MaterializerError -Message "POC fixture ownership marker is invalid: $fixtureMarkerPath" -ExitCode 4
    }

}

function Get-GitWorktreeContext {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $gitRootLines = @(& git -C $ProjectRoot rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or $gitRootLines.Count -eq 0) {
        return $null
    }

    $gitRoot = [System.IO.Path]::GetFullPath([string]$gitRootLines[0]).TrimEnd('\', '/')
    $fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
    Assert-PathInside -Path $fullProjectRoot -Root $gitRoot -Label "Git project root" -AllowRoot
    $projectPrefix = ""
    if (-not [string]::Equals($fullProjectRoot, $gitRoot, [StringComparison]::OrdinalIgnoreCase)) {
        $projectPrefix = $fullProjectRoot.Substring($gitRoot.Length + 1).Replace('\', '/')
    }

    return [pscustomobject]@{
        Root = $gitRoot
        ProjectPrefix = $projectPrefix
    }
}

function Get-GitStagedTargetChanges {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$RelativePaths
    )

    $normalizedTargets = @($RelativePaths | ForEach-Object {
        ConvertTo-SafeRelativePath -Path $_ -Label "Git staged-change target"
    } | Sort-Object -Unique)
    if ($normalizedTargets.Count -eq 0) {
        return @()
    }

    $gitContext = Get-GitWorktreeContext -ProjectRoot $ProjectRoot
    if ($null -eq $gitContext) {
        return @()
    }

    $repoPathToTarget = @{}
    foreach ($target in $normalizedTargets) {
        $repoPath = if ([string]::IsNullOrWhiteSpace($gitContext.ProjectPrefix)) {
            $target
        } else {
            "$($gitContext.ProjectPrefix)/$target"
        }
        $repoPathToTarget[$repoPath] = $target
    }

    $arguments = @(
        "-C",
        $gitContext.Root,
        "diff",
        "--cached",
        "--name-only",
        "--no-renames",
        "--"
    ) + @($repoPathToTarget.Keys | Sort-Object)
    $output = @(& git @arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        $detail = @($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        Throw-MaterializerError -Message "Git staged-change inspection failed. $detail" -ExitCode 4
    }

    $stagedTargets = New-Object System.Collections.Generic.List[string]
    foreach ($line in $output) {
        $repoPath = $line.ToString().Replace('\', '/')
        if (-not $repoPathToTarget.ContainsKey($repoPath)) {
            Throw-MaterializerError -Message "Git staged-change inspection returned an unexpected path: $repoPath" -ExitCode 4
        }
        $stagedTargets.Add([string]$repoPathToTarget[$repoPath])
    }
    return @($stagedTargets.ToArray() | Sort-Object -Unique)
}

function Assert-TargetRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = ConvertTo-SafeRelativePath -Path $Path -Label "payload target"
    if (-not $normalized.StartsWith($script:TargetPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($normalized, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
        -not $script:AllowedTargetPaths.ContainsKey($normalized)) {
        Throw-MaterializerError -Message "Payload target is outside the audited production allowlist: $Path" -ExitCode 2
    }

    return $normalized
}

function Read-PayloadManifest {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $fullRoot = [System.IO.Path]::GetFullPath($Root)
    if (-not (Test-Path -LiteralPath $fullRoot -PathType Container)) {
        Throw-MaterializerError -Message "Payload root does not exist: $fullRoot" -ExitCode 2
    }
    Assert-NoReparsePoint -Path $fullRoot -Root $fullRoot -Label "payload root"

    $manifestPath = Join-Path $fullRoot "payload-manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Payload manifest does not exist: $manifestPath" -ExitCode 2
    }

    try {
        $document = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    } catch {
        Throw-MaterializerError -Message "Payload manifest is not valid JSON: $($_.Exception.Message)" -ExitCode 2
    }

    $schemaVersion = [int](Get-RequiredProperty -Object $document -Name "schema_version" -Label "payload manifest")
    $managedBy = [string](Get-RequiredProperty -Object $document -Name "managed_by" -Label "payload manifest")
    $packageVersion = [string](Get-RequiredProperty -Object $document -Name "package_version" -Label "payload manifest")
    $payloadVersion = [string](Get-RequiredProperty -Object $document -Name "payload_version" -Label "payload manifest")
    $payloadSequence = [int](Get-RequiredProperty -Object $document -Name "payload_sequence" -Label "payload manifest")
    $retiredTargets = @(Get-RequiredProperty -Object $document -Name "retired_targets" -Label "payload manifest")
    $manifestFiles = @(Get-RequiredProperty -Object $document -Name "files" -Label "payload manifest")

    if ($schemaVersion -ne 1 -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $payloadSequence -lt 1 -or
        $manifestFiles.Count -eq 0) {
        Throw-MaterializerError -Message "Payload manifest identity, version, or file list is invalid." -ExitCode 2
    }

    $seenSources = @{}
    $seenTargets = @{}
    $retiredTargetMap = @{}
    foreach ($retiredTargetValue in $retiredTargets) {
        $retiredTarget = Assert-TargetRelativePath -Path ([string]$retiredTargetValue)
        if ($retiredTargetMap.ContainsKey($retiredTarget)) {
            Throw-MaterializerError -Message "Payload manifest contains a duplicate retired target: $retiredTarget" -ExitCode 2
        }
        $retiredTargetMap[$retiredTarget] = $true
    }
    $files = New-Object System.Collections.Generic.List[object]
    foreach ($entry in $manifestFiles) {
        $source = ConvertTo-SafeRelativePath -Path ([string](Get-RequiredProperty -Object $entry -Name "source" -Label "payload file")) -Label "payload source"
        $target = Assert-TargetRelativePath -Path ([string](Get-RequiredProperty -Object $entry -Name "target" -Label "payload file"))
        $expectedHash = ([string](Get-RequiredProperty -Object $entry -Name "sha256" -Label "payload file")).ToLowerInvariant()
        if ($expectedHash -notmatch '^[0-9a-f]{64}$') {
            Throw-MaterializerError -Message "Payload file has an invalid SHA256: $target" -ExitCode 2
        }
        if ($seenSources.ContainsKey($source) -or $seenTargets.ContainsKey($target)) {
            Throw-MaterializerError -Message "Payload manifest contains a duplicate source or target: $target" -ExitCode 2
        }
        if ($retiredTargetMap.ContainsKey($target)) {
            Throw-MaterializerError -Message "Payload manifest cannot both install and retire the same target: $target" -ExitCode 2
        }
        $seenSources[$source] = $true
        $seenTargets[$target] = $true

        $sourcePath = ConvertTo-AbsoluteChildPath -Root $fullRoot -RelativePath $source -Label "payload source"
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            Throw-MaterializerError -Message "Payload source is missing: $source" -ExitCode 5
        }
        Assert-NoReparsePoint -Path $sourcePath -Root $fullRoot -Label "payload source"
        $actualHash = Get-FileSha256 -Path $sourcePath
        if (-not [string]::Equals($actualHash, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Payload source hash mismatch: $source" -ExitCode 5
        }

        $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "payload target"
        Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "payload target"
        $files.Add([pscustomobject]@{
            Source = $source
            SourcePath = $sourcePath
            Target = $target
            TargetPath = $targetPath
            Sha256 = $expectedHash
        })
    }

    return [pscustomobject]@{
        SchemaVersion = $schemaVersion
        ManagedBy = $managedBy
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        RetiredTargets = @($retiredTargetMap.Keys | Sort-Object)
        RetiredTargetMap = $retiredTargetMap
        Root = $fullRoot
        ManifestPath = $manifestPath
        Files = @($files | Sort-Object Target)
    }
}

function Get-TrackedHostAuthorizationProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        Throw-MaterializerError -Message "Tracked-host authorization is missing required property '$Name'." -ExitCode 4
    }
    return $property.Value
}

function Assert-TrackedHostMutationAuthorization {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][ValidateSet("Sync", "Remove")][string]$MutationAction,
        [Parameter(Mandatory = $true)][string]$AuthorizationPath
    )

    if (-not [System.IO.Path]::IsPathRooted($AuthorizationPath)) {
        Throw-MaterializerError -Message "Tracked-host authorization path must be absolute." -ExitCode 4
    }

    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $authorizationRoot = ConvertTo-AbsoluteChildPath `
        -Root $fullRoot `
        -RelativePath $script:TrackedHostAuthorizationRelativeRoot `
        -Label "tracked-host authorization root"
    $fullAuthorizationPath = [System.IO.Path]::GetFullPath($AuthorizationPath)
    $authorizationPrefix = $authorizationRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullAuthorizationPath.StartsWith($authorizationPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Tracked-host authorization is outside its required root: $authorizationRoot" -ExitCode 4
    }
    if (-not [string]::Equals(
        [System.IO.Path]::GetDirectoryName($fullAuthorizationPath),
        $authorizationRoot,
        [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Tracked-host authorization must be a direct child of $authorizationRoot." -ExitCode 4
    }
    if (-not (Test-Path -LiteralPath $fullAuthorizationPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Tracked-host authorization file does not exist: $fullAuthorizationPath" -ExitCode 4
    }
    Assert-NoReparsePoint -Path $fullAuthorizationPath -Root $fullRoot -Label "tracked-host authorization"
    $authorizationInfo = Get-Item -LiteralPath $fullAuthorizationPath -Force
    if ($authorizationInfo.Length -gt 65536) {
        Throw-MaterializerError -Message "Tracked-host authorization exceeds the 64 KiB size limit." -ExitCode 4
    }

    $gitContext = Get-GitWorktreeContext -ProjectRoot $fullRoot
    if ($null -eq $gitContext) {
        Throw-MaterializerError -Message "Tracked-host mutation requires a Git worktree." -ExitCode 4
    }

    $projectMarkers = @("Packages/manifest.json", "ProjectSettings/ProjectVersion.txt")
    $activeGitIndex = [Environment]::GetEnvironmentVariable("GIT_INDEX_FILE", [EnvironmentVariableTarget]::Process)
    try {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $null, [EnvironmentVariableTarget]::Process)
        foreach ($relativePath in $projectMarkers) {
            $repoPath = if ([string]::IsNullOrWhiteSpace($gitContext.ProjectPrefix)) {
                $relativePath
            } else {
                "$($gitContext.ProjectPrefix)/$relativePath"
            }
            $null = @(& git -C $gitContext.Root ls-files --error-unmatch -- $repoPath 2>$null)
            if ($LASTEXITCODE -ne 0) {
                Throw-MaterializerError -Message "Tracked-host mutation requires tracked Unity project marker: $relativePath" -ExitCode 4
            }
        }

        $authorizationRepoPath = $fullAuthorizationPath.Substring($gitContext.Root.Length + 1).Replace('\', '/')
        & git -C $gitContext.Root check-ignore -q -- $authorizationRepoPath
        if ($LASTEXITCODE -ne 0) {
            Throw-MaterializerError -Message "Tracked-host authorization must be Git ignored and untracked: $fullAuthorizationPath" -ExitCode 4
        }

        $gitHeadLines = @(& git -C $gitContext.Root rev-parse --verify HEAD 2>$null)
        if ($LASTEXITCODE -ne 0 -or $gitHeadLines.Count -ne 1) {
            Throw-MaterializerError -Message "Tracked-host authorization could not resolve the current Git HEAD." -ExitCode 4
        }
        $gitHead = ([string]$gitHeadLines[0]).Trim().ToLowerInvariant()
    } finally {
        [Environment]::SetEnvironmentVariable("GIT_INDEX_FILE", $activeGitIndex, [EnvironmentVariableTarget]::Process)
    }

    try {
        $document = Get-Content -LiteralPath $fullAuthorizationPath -Raw | ConvertFrom-Json
    } catch {
        Throw-MaterializerError -Message "Tracked-host authorization is not valid JSON: $($_.Exception.Message)" -ExitCode 4
    }
    if ($null -eq $document -or
        $document.GetType() -ne [System.Management.Automation.PSCustomObject]) {
        Throw-MaterializerError -Message "Tracked-host authorization must be one JSON object." -ExitCode 4
    }

    $propertyNames = @(
        "schema_version",
        "managed_by",
        "purpose",
        "authorization_id",
        "project_root",
        "git_head",
        "action",
        "package_version",
        "payload_version",
        "payload_sequence",
        "payload_manifest_sha256",
        "target_count",
        "acknowledgement"
    )
    $allowedProperties = @{}
    foreach ($propertyName in $propertyNames) {
        $allowedProperties[$propertyName] = $true
    }
    foreach ($property in @($document.PSObject.Properties)) {
        if (-not $allowedProperties.ContainsKey($property.Name)) {
            Throw-MaterializerError -Message "Tracked-host authorization contains unsupported property '$($property.Name)'." -ExitCode 4
        }
    }

    $schemaVersion = 0
    $payloadSequence = 0
    $targetCount = 0
    if (-not [int]::TryParse([string](Get-TrackedHostAuthorizationProperty -Object $document -Name "schema_version"), [ref]$schemaVersion) -or
        -not [int]::TryParse([string](Get-TrackedHostAuthorizationProperty -Object $document -Name "payload_sequence"), [ref]$payloadSequence) -or
        -not [int]::TryParse([string](Get-TrackedHostAuthorizationProperty -Object $document -Name "target_count"), [ref]$targetCount)) {
        Throw-MaterializerError -Message "Tracked-host authorization contains an invalid numeric property." -ExitCode 4
    }

    $managedBy = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "managed_by")
    $purpose = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "purpose")
    $authorizationId = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "authorization_id")
    $authorizedProjectRoot = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "project_root")
    $authorizedGitHead = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "git_head")
    $authorizedAction = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "action")
    $packageVersion = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "package_version")
    $payloadVersion = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "payload_version")
    $manifestSha256 = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "payload_manifest_sha256")
    $acknowledgement = [string](Get-TrackedHostAuthorizationProperty -Object $document -Name "acknowledgement")

    if ($schemaVersion -ne 1 -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals($purpose, $script:TrackedHostAuthorizationPurpose, [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Tracked-host authorization identity is invalid." -ExitCode 4
    }
    if ($authorizationId -cnotmatch '^[0-9a-f]{32}$' -or
        -not [string]::Equals([System.IO.Path]::GetFileName($fullAuthorizationPath), "$authorizationId.json", [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Tracked-host authorization ID must be lowercase hex and match its file name." -ExitCode 4
    }
    try {
        $authorizedProjectRoot = [System.IO.Path]::GetFullPath($authorizedProjectRoot).TrimEnd('\', '/')
    } catch {
        Throw-MaterializerError -Message "Tracked-host authorization project root is invalid." -ExitCode 4
    }
    if (-not [string]::Equals($authorizedProjectRoot, $fullRoot, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Tracked-host authorization project root does not match the requested project." -ExitCode 4
    }
    if ($authorizedGitHead -notmatch '^[0-9a-fA-F]{40,64}$' -or
        -not [string]::Equals($authorizedGitHead, $gitHead, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Tracked-host authorization Git HEAD does not match the current worktree." -ExitCode 4
    }
    if (-not [string]::Equals($authorizedAction, $MutationAction, [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Tracked-host authorization action '$authorizedAction' does not permit $MutationAction." -ExitCode 4
    }
    if (-not [string]::Equals($packageVersion, $Manifest.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals($payloadVersion, $Manifest.PayloadVersion, [StringComparison]::Ordinal) -or
        $payloadSequence -ne $Manifest.PayloadSequence -or
        $targetCount -ne $Manifest.Files.Count -or
        $manifestSha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        -not [string]::Equals($manifestSha256, (Get-FileSha256 -Path $Manifest.ManifestPath), [StringComparison]::OrdinalIgnoreCase)) {
        Throw-MaterializerError -Message "Tracked-host authorization payload identity does not match the requested manifest." -ExitCode 4
    }
    if (-not [string]::Equals($acknowledgement, $script:TrackedHostAuthorizationAcknowledgement, [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Tracked-host authorization acknowledgement is invalid." -ExitCode 4
    }

    Write-Host "[AUTHORIZED] Tracked-host $MutationAction authorization $authorizationId accepted for payload $($Manifest.PayloadVersion) sequence $($Manifest.PayloadSequence) at Git HEAD $gitHead."
}

function Assert-MutationAuthorization {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][ValidateSet("Sync", "Remove")][string]$MutationAction
    )

    $hasTrackedHostAuthorization = -not [string]::IsNullOrWhiteSpace($TrackedHostAuthorizationPath)
    if ($PocFixture -and $hasTrackedHostAuthorization) {
        Throw-MaterializerError -Message "Fixture and tracked-host mutation authorization modes are mutually exclusive." -ExitCode 4
    }
    if ($PocFixture) {
        Assert-PocMutationTarget -Root $Root
        return
    }
    if (-not $hasTrackedHostAuthorization) {
        Throw-MaterializerError -Message "Sync/Remove requires explicit -PocFixture or -TrackedHostAuthorizationPath." -ExitCode 4
    }
    Assert-TrackedHostMutationAuthorization `
        -Root $Root `
        -Manifest $Manifest `
        -MutationAction $MutationAction `
        -AuthorizationPath $TrackedHostAuthorizationPath
}

function Read-InstalledMarker {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $MarkerPath)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Installed payload marker is not a file: $MarkerPath" -ExitCode 2
    }
    Assert-NoReparsePoint -Path $MarkerPath -Root $ProjectRoot -Label "installed payload marker"

    try {
        $markerText = Get-Content -LiteralPath $MarkerPath -Raw
        $document = $markerText | ConvertFrom-Json
    } catch {
        Throw-MaterializerError -Message "Installed payload marker is not valid JSON: $($_.Exception.Message)" -ExitCode 2
    }

    $schemaVersion = [int](Get-RequiredProperty -Object $document -Name "schema_version" -Label "installed payload marker")
    $managedBy = [string](Get-RequiredProperty -Object $document -Name "managed_by" -Label "installed payload marker")
    $packageVersion = [string](Get-RequiredProperty -Object $document -Name "package_version" -Label "installed payload marker")
    $payloadVersion = [string](Get-RequiredProperty -Object $document -Name "payload_version" -Label "installed payload marker")
    $payloadSequence = [int](Get-RequiredProperty -Object $document -Name "payload_sequence" -Label "installed payload marker")
    $hostUseGateVersion = 0
    $hostUseGateProperty = $document.PSObject.Properties["host_use_gate_version"]
    if ($null -ne $hostUseGateProperty) {
        try {
            $hostUseGateVersion = [int]$hostUseGateProperty.Value
        } catch {
            Throw-MaterializerError -Message "Installed payload marker has an invalid host-use gate version." -ExitCode 2
        }
        if ($hostUseGateVersion -lt 1) {
            Throw-MaterializerError -Message "Installed payload marker has an invalid host-use gate version." -ExitCode 2
        }
    }
    $markerFiles = @(Get-RequiredProperty -Object $document -Name "files" -Label "installed payload marker")
    if ($schemaVersion -ne 1 -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $payloadSequence -lt 1) {
        Throw-MaterializerError -Message "Installed payload marker identity or version is invalid." -ExitCode 2
    }

    $map = @{}
    $files = New-Object System.Collections.Generic.List[object]
    foreach ($entry in $markerFiles) {
        $target = Assert-TargetRelativePath -Path ([string](Get-RequiredProperty -Object $entry -Name "path" -Label "installed payload file"))
        $installedHash = ([string](Get-RequiredProperty -Object $entry -Name "installed_sha256" -Label "installed payload file")).ToLowerInvariant()
        if ($installedHash -notmatch '^[0-9a-f]{64}$' -or $map.ContainsKey($target)) {
            Throw-MaterializerError -Message "Installed payload marker contains an invalid hash or duplicate target: $target" -ExitCode 2
        }

        $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "installed payload target"
        Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "installed payload target"
        $model = [pscustomobject]@{
            Target = $target
            TargetPath = $targetPath
            InstalledSha256 = $installedHash
        }
        $map[$target] = $model
        $files.Add($model)
    }

    return [pscustomobject]@{
        RawText = $markerText
        Document = $document
        SchemaVersion = $schemaVersion
        ManagedBy = $managedBy
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        HostUseGateVersion = $hostUseGateVersion
        Files = @($files | Sort-Object Target)
        Map = $map
    }
}

function Get-InstalledPayloadVersionPolicy {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        $Marker
    )

    if ($null -eq $Marker) {
        return [pscustomobject]@{
            IsDowngrade = $false
            IsSequenceCollision = $false
            PayloadIdentityMatches = $false
        }
    }

    $sequenceIdentityMatches =
        [string]::Equals($Marker.PayloadVersion, $Manifest.PayloadVersion, [StringComparison]::Ordinal) -and
        $Marker.Files.Count -eq $Manifest.Files.Count
    if ($sequenceIdentityMatches) {
        foreach ($file in $Manifest.Files) {
            if (-not $Marker.Map.ContainsKey($file.Target) -or
                -not [string]::Equals($Marker.Map[$file.Target].InstalledSha256, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                $sequenceIdentityMatches = $false
                break
            }
        }
    }
    $payloadIdentityMatches = $sequenceIdentityMatches -and
        [string]::Equals($Marker.PackageVersion, $Manifest.PackageVersion, [StringComparison]::Ordinal)

    $isDowngrade = $Marker.PayloadSequence -gt $Manifest.PayloadSequence
    $isSequenceCollision = $Marker.PayloadSequence -eq $Manifest.PayloadSequence -and -not $sequenceIdentityMatches
    return [pscustomobject]@{
        IsDowngrade = $isDowngrade
        IsSequenceCollision = $isSequenceCollision
        PayloadIdentityMatches = $payloadIdentityMatches
    }
}

function Get-MaterializationPlan {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $marker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
    $filePlans = New-Object System.Collections.Generic.List[object]
    $desiredTargets = @{}
    $hasConflict = $false

    foreach ($file in $Manifest.Files) {
        $desiredTargets[$file.Target] = $true
        $oldEntry = $null
        if ($null -ne $marker -and $marker.Map.ContainsKey($file.Target)) {
            $oldEntry = $marker.Map[$file.Target]
        }

        $targetHash = $null
        $status = $null
        $detail = $null
        if (Test-Path -LiteralPath $file.TargetPath) {
            if (-not (Test-Path -LiteralPath $file.TargetPath -PathType Leaf)) {
                $status = "Conflict"
                $detail = "target is not a regular file"
            } else {
                $targetHash = Get-FileSha256 -Path $file.TargetPath
                if ($null -eq $oldEntry) {
                    if ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                        $status = "Adoptable"
                        $detail = "exact unowned file"
                    } else {
                        $status = "Conflict"
                        $detail = "unowned file differs from package payload"
                    }
                } elseif ([string]::Equals($targetHash, $oldEntry.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    if ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                        $status = "Current"
                        $detail = "managed file matches package payload"
                    } else {
                        $status = "Upgradeable"
                        $detail = "managed file is unchanged since installation"
                    }
                } elseif ([string]::Equals($targetHash, $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
                    $status = "Upgradeable"
                    $detail = "file already matches the new payload; marker needs update"
                } else {
                    $status = "ManagedDrift"
                    $detail = "managed file changed after installation"
                }
            }
        } elseif ($null -eq $oldEntry) {
            $status = "Missing"
            $detail = "target is not installed"
        } else {
            $status = "ManagedMissing"
            $detail = "managed target was removed after installation"
        }

        if ($status -in @("Conflict", "ManagedDrift", "ManagedMissing")) {
            $hasConflict = $true
        }
        $filePlans.Add([pscustomobject]@{
            Status = $status
            Detail = $detail
            Source = $file.Source
            SourcePath = $file.SourcePath
            SourceSha256 = $file.Sha256
            Target = $file.Target
            TargetPath = $file.TargetPath
            TargetSha256 = $targetHash
            PreviousSha256 = if ($null -eq $oldEntry) { $null } else { $oldEntry.InstalledSha256 }
        })
    }

    $retiredPlans = New-Object System.Collections.Generic.List[object]
    if ($null -ne $marker) {
        foreach ($oldEntry in $marker.Files) {
            if ($desiredTargets.ContainsKey($oldEntry.Target)) {
                continue
            }

            $targetHash = $null
            if (-not $Manifest.RetiredTargetMap.ContainsKey($oldEntry.Target)) {
                $status = "UntrustedOwnedPath"
                $detail = "marker target is not allowed by the current or retired manifest allowlist"
                $hasConflict = $true
            } elseif (-not (Test-Path -LiteralPath $oldEntry.TargetPath -PathType Leaf)) {
                $status = "ManagedMissing"
                $detail = "retired managed target is missing or not a file"
                $hasConflict = $true
            } else {
                $targetHash = Get-FileSha256 -Path $oldEntry.TargetPath
                if ([string]::Equals($targetHash, $oldEntry.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    $status = "Retirable"
                    $detail = "managed file was removed from the new payload"
                } else {
                    $status = "RetireConflict"
                    $detail = "retired managed file changed after installation"
                    $hasConflict = $true
                }
            }
            $retiredPlans.Add([pscustomobject]@{
                Status = $status
                Detail = $detail
                Target = $oldEntry.Target
                TargetPath = $oldEntry.TargetPath
                TargetSha256 = $targetHash
                PreviousSha256 = $oldEntry.InstalledSha256
            })
        }
    }

    $managedScopeTargets = @($filePlans | ForEach-Object { $_.Target }) +
        @($retiredPlans | ForEach-Object { $_.Target }) +
        @($script:MarkerRelativePath)
    $stagedTargets = @(Get-GitStagedTargetChanges -ProjectRoot $ProjectRoot -RelativePaths $managedScopeTargets)
    if ($stagedTargets.Count -gt 0) {
        $hasConflict = $true
    }
    $versionPolicy = Get-InstalledPayloadVersionPolicy -Manifest $Manifest -Marker $marker
    if ($versionPolicy.IsDowngrade -or $versionPolicy.IsSequenceCollision) {
        $hasConflict = $true
    }

    $markerCurrent = $null -ne $marker -and
        $versionPolicy.PayloadIdentityMatches -and
        $marker.PayloadSequence -eq $Manifest.PayloadSequence -and
        $marker.HostUseGateVersion -eq $script:HostUseGateVersion -and
        [string]::Equals($marker.RawText, (New-MarkerJson -Manifest $Manifest), [StringComparison]::Ordinal)

    $allFilesCurrent = @($filePlans | Where-Object { $_.Status -ne "Current" }).Count -eq 0
    $isCurrent = $markerCurrent -and $allFilesCurrent -and $retiredPlans.Count -eq 0 -and $stagedTargets.Count -eq 0
    return [pscustomobject]@{
        Marker = $marker
        Files = $filePlans.ToArray()
        Retired = $retiredPlans.ToArray()
        StagedTargets = $stagedTargets
        HasConflict = $hasConflict
        IsCurrent = $isCurrent
        MarkerNeedsUpdate = -not $markerCurrent
        IsDowngrade = $versionPolicy.IsDowngrade
        IsSequenceCollision = $versionPolicy.IsSequenceCollision
    }
}

function Write-MaterializationPlan {
    param([Parameter(Mandatory = $true)]$Plan)

    if ($Plan.IsDowngrade) {
        Write-Host "[CONFLICT] Downgrade: installed payload sequence is newer than the requested payload."
    }
    if ($Plan.IsSequenceCollision) {
        Write-Host "[CONFLICT] SequenceCollision: the installed and requested payloads reuse one sequence with different identities or file hashes."
    }
    foreach ($target in $Plan.StagedTargets) {
        Write-Host "[CONFLICT] GitStaged: $target - the Git index contains a staged change in package ownership scope"
    }
    foreach ($item in @($Plan.Files) + @($Plan.Retired)) {
        $prefix = if ($item.Status -in @("Conflict", "ManagedDrift", "ManagedMissing", "RetireConflict", "UntrustedOwnedPath")) { "[CONFLICT]" } else { "[PLAN]" }
        Write-Host "$prefix $($item.Status): $($item.Target) - $($item.Detail)"
    }
}

function New-MarkerJson {
    param([Parameter(Mandatory = $true)]$Manifest)

    $files = @($Manifest.Files | Sort-Object Target | ForEach-Object {
        [ordered]@{
            path = $_.Target
            installed_sha256 = $_.Sha256
        }
    })
    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        package_version = $Manifest.PackageVersion
        payload_version = $Manifest.PayloadVersion
        payload_sequence = $Manifest.PayloadSequence
        host_use_gate_version = $script:HostUseGateVersion
        files = $files
    }
    $json = $document | ConvertTo-Json -Depth 8
    return $json.Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd([char]10) + "`n"
}

function Enter-MaterializerLock {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $lockRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
    Assert-NoReparsePoint -Path $lockRoot -Root $ProjectRoot -Label "materializer runtime"
    New-Item -ItemType Directory -Force -Path $lockRoot | Out-Null
    $lockPath = Join-Path $lockRoot "materialize.lock"
    try {
        $stream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    } catch {
        Throw-MaterializerError -Message "Another payload materialization is active: $lockPath" -ExitCode 4
    }

    return [pscustomobject]@{
        Root = $lockRoot
        Path = $lockPath
        Stream = $stream
        ActiveMarkerPath = Join-Path $lockRoot $script:ActiveMarkerName
        ActiveMarkerPublished = $false
        ProviderRuntimeRoots = @()
        ManagementLocks = New-Object System.Collections.Generic.List[object]
    }
}

function Exit-MaterializerLock {
    param($Lock)

    if ($null -eq $Lock) {
        return
    }
    foreach ($managementLock in @($Lock.ManagementLocks.ToArray()) | Sort-Object { $_.Path.Length } -Descending) {
        if ($null -ne $managementLock.Stream) {
            $managementLock.Stream.Dispose()
        }
        if (-not $managementLock.ExistedBefore) {
            Remove-Item -LiteralPath $managementLock.Path -Force -ErrorAction SilentlyContinue
        }
    }
    $hasPendingTransaction = @(Get-ChildItem -LiteralPath $Lock.Root -Force -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name.StartsWith($script:TransactionPrefix, [StringComparison]::Ordinal)
    }).Count -gt 0
    if ($Lock.ActiveMarkerPublished -and -not $hasPendingTransaction) {
        Remove-Item -LiteralPath $Lock.ActiveMarkerPath -Force -ErrorAction SilentlyContinue
    }

    if ($null -ne $Lock.Stream) {
        $Lock.Stream.Dispose()
    }
    Remove-Item -LiteralPath $Lock.Path -Force -ErrorAction SilentlyContinue
    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    if ((Test-Path -LiteralPath $leaseRoot -PathType Container) -and
        @(Get-ChildItem -LiteralPath $leaseRoot -Force).Count -eq 0) {
        Remove-Item -LiteralPath $leaseRoot -Force -ErrorAction SilentlyContinue
    }
    if ((Test-Path -LiteralPath $Lock.Root -PathType Container) -and
        @(Get-ChildItem -LiteralPath $Lock.Root -Force).Count -eq 0) {
        Remove-Item -LiteralPath $Lock.Root -Force -ErrorAction SilentlyContinue
    }
}

function Test-MaterializerProcessAlive {
    param([AllowNull()]$ProcessId)

    try {
        $numericProcessId = [int]$ProcessId
        if ($numericProcessId -le 0) {
            return $false
        }
        $process = Get-Process -Id $numericProcessId -ErrorAction Stop
        return -not $process.HasExited
    } catch {
        return $false
    }
}

function ConvertTo-MaterializerProjectSlug {
    param([Parameter(Mandatory = $true)][string]$Value)

    $result = ""
    $previousWasSeparator = $false
    foreach ($character in $Value.ToCharArray()) {
        if ([char]::IsLetterOrDigit($character)) {
            $result += [char]::ToLowerInvariant($character)
            $previousWasSeparator = $false
        } elseif (-not $previousWasSeparator -and $result.Length -gt 0) {
            $result += "-"
            $previousWasSeparator = $true
        }
    }
    $result = $result.TrimEnd('-')
    return $(if ([string]::IsNullOrWhiteSpace($result)) { "unity-project" } else { $result })
}

function Get-MaterializerProviderRuntimeRoots {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $codedbRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb" -Label "CodeDB runtime root"
    Assert-NoReparsePoint -Path $codedbRuntimeRoot -Root $ProjectRoot -Label "CodeDB runtime root"
    $projectSlug = ConvertTo-MaterializerProjectSlug -Value (Split-Path -Leaf $ProjectRoot.TrimEnd('\', '/'))
    $roots = @{}
    $expectedRoot = Join-Path $codedbRuntimeRoot "codedb-$projectSlug"
    $roots[[System.IO.Path]::GetFullPath($expectedRoot)] = $expectedRoot

    if (Test-Path -LiteralPath $codedbRuntimeRoot -PathType Container) {
        foreach ($directory in @(Get-ChildItem -LiteralPath $codedbRuntimeRoot -Force -Directory)) {
            if (-not $directory.Name.StartsWith("codedb-", [StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
            Assert-NoReparsePoint -Path $directory.FullName -Root $ProjectRoot -Label "provider runtime"
            $roots[[System.IO.Path]::GetFullPath($directory.FullName)] = $directory.FullName
        }
    }

    return @($roots.Values | Sort-Object)
}

function Assert-ExistingMaterializerActiveMarker {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $Lock.ActiveMarkerPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $Lock.ActiveMarkerPath -PathType Leaf)) {
        Throw-MaterializerError -Message "Materializer active marker is not a file: $($Lock.ActiveMarkerPath)" -ExitCode 7
    }
    Assert-NoReparsePoint -Path $Lock.ActiveMarkerPath -Root $ProjectRoot -Label "materializer active marker"
    try {
        $marker = Get-Content -LiteralPath $Lock.ActiveMarkerPath -Raw | ConvertFrom-Json
        $valid = [int]$marker.schema_version -eq 1 -and
            [int]$marker.host_use_gate_version -eq $script:HostUseGateVersion -and
            [string]::Equals([string]$marker.managed_by, $script:ManagedBy, [StringComparison]::Ordinal) -and
            [int]$marker.pid -gt 0 -and
            [string]::Equals(
                [System.IO.Path]::GetFullPath([string]$marker.project_root),
                [System.IO.Path]::GetFullPath($ProjectRoot),
                [StringComparison]::OrdinalIgnoreCase)
    } catch {
        $valid = $false
    }
    if (-not $valid) {
        Throw-MaterializerError -Message "Materializer active marker is invalid and requires manual review: $($Lock.ActiveMarkerPath)" -ExitCode 7
    }
    if ([int]$marker.pid -ne $PID -and (Test-MaterializerProcessAlive -ProcessId $marker.pid)) {
        Throw-MaterializerError -Message "Another payload materializer PID $($marker.pid) is active." -ExitCode 4
    }
}

function Publish-MaterializerActiveMarker {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $document = [ordered]@{
        schema_version = 1
        host_use_gate_version = $script:HostUseGateVersion
        managed_by = $script:ManagedBy
        pid = $PID
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
        action = $Action.ToLowerInvariant()
        created_at_utc = [DateTime]::UtcNow.ToString("o")
    }
    $stagePath = Join-Path $Lock.Root ("active-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content (($document | ConvertTo-Json -Depth 6) + "`n")
        Publish-TransactionFile -StagePath $stagePath -TargetPath $Lock.ActiveMarkerPath
        $Lock.ActiveMarkerPublished = $true
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Enter-MaterializerWatchManagementLocks {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    foreach ($providerRoot in $Lock.ProviderRuntimeRoots) {
        $watchRoot = Join-Path $providerRoot "watch"
        Assert-PathInside -Path $watchRoot -Root $ProjectRoot -Label "watch management runtime"
        Assert-NoReparsePoint -Path $watchRoot -Root $ProjectRoot -Label "watch management runtime"
        if (-not (Test-Path -LiteralPath $watchRoot -PathType Container)) {
            continue
        }

        $managementLockPath = Join-Path $watchRoot "management.lock"
        Assert-NoReparsePoint -Path $managementLockPath -Root $ProjectRoot -Label "watch management lock"
        $existedBefore = Test-Path -LiteralPath $managementLockPath -PathType Leaf
        try {
            $stream = [System.IO.File]::Open(
                $managementLockPath,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        } catch {
            Throw-MaterializerError -Message "Watcher management is active for provider runtime: $providerRoot" -ExitCode 4
        }
        $Lock.ManagementLocks.Add([pscustomobject]@{
            Path = $managementLockPath
            Stream = $stream
            ExistedBefore = $existedBefore
        })
    }
}

function Assert-NoLiveHostUseLeases {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $leaseRoot = Join-Path $Lock.Root $script:HostUseLeaseDirectoryName
    if (-not (Test-Path -LiteralPath $leaseRoot)) {
        return
    }
    if (-not (Test-Path -LiteralPath $leaseRoot -PathType Container)) {
        Throw-MaterializerError -Message "Host-use lease root is not a directory: $leaseRoot" -ExitCode 7
    }
    Assert-NoReparsePoint -Path $leaseRoot -Root $ProjectRoot -Label "host-use lease root"

    $liveLeases = New-Object System.Collections.Generic.List[string]
    foreach ($item in @(Get-ChildItem -LiteralPath $leaseRoot -Force | Sort-Object Name)) {
        if ($item.PSIsContainer -or $item.Name -notmatch '^(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json$') {
            Throw-MaterializerError -Message "Unknown host-use lease artifact requires manual review: $($item.FullName)" -ExitCode 7
        }
        $fileOwner = $Matches[1]
        $fileProcessId = [int]$Matches[2]
        $fileToken = $Matches[3]
        Assert-NoReparsePoint -Path $item.FullName -Root $leaseRoot -Label "host-use lease"
        try {
            $lease = Get-Content -LiteralPath $item.FullName -Raw | ConvertFrom-Json
            $owner = [string]$lease.owner
            $processId = [int]$lease.pid
            $leaseId = [string]$lease.lease_id
            $valid = [int]$lease.schema_version -eq 1 -and
                [int]$lease.host_use_gate_version -eq $script:HostUseGateVersion -and
                [string]::Equals([string]$lease.managed_by, $script:ManagedBy, [StringComparison]::Ordinal) -and
                [string]::Equals($owner, $fileOwner, [StringComparison]::Ordinal) -and
                $processId -eq $fileProcessId -and
                [string]::Equals($leaseId, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                [string]::Equals($leaseId, "$fileOwner-$fileProcessId-$fileToken", [StringComparison]::Ordinal) -and
                [string]::Equals(
                    [System.IO.Path]::GetFullPath([string]$lease.project_root),
                    [System.IO.Path]::GetFullPath($ProjectRoot),
                    [StringComparison]::OrdinalIgnoreCase) -and
                -not [string]::IsNullOrWhiteSpace([string]$lease.created_at_utc)
        } catch {
            $valid = $false
        }
        if (-not $valid) {
            Throw-MaterializerError -Message "Host-use lease is invalid and requires manual review: $($item.FullName)" -ExitCode 7
        }

        if (Test-MaterializerProcessAlive -ProcessId $processId) {
            $liveLeases.Add("$owner PID $processId")
        } else {
            Remove-Item -LiteralPath $item.FullName -Force
            Write-Host "[RECOVERED] Removed stale $owner host-use lease for PID $processId."
        }
    }

    if ($liveLeases.Count -gt 0) {
        foreach ($lease in $liveLeases) {
            Write-Host "[ACTIVE] $lease"
        }
        Throw-MaterializerError -Message "Host payload mutation is blocked while CodeDB host tooling is active." -ExitCode 4
    }
}

function Assert-NoLiveLegacyWatcherState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $liveProcesses = New-Object System.Collections.Generic.List[string]
    foreach ($providerRoot in $Lock.ProviderRuntimeRoots) {
        $statePath = Join-Path $providerRoot "watch\coordinator\coordinator-state.json"
        Assert-PathInside -Path $statePath -Root $ProjectRoot -Label "coordinator state"
        if (-not (Test-Path -LiteralPath $statePath)) {
            continue
        }
        if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
            Throw-MaterializerError -Message "Coordinator state is not a file: $statePath" -ExitCode 7
        }
        Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "coordinator state"
        try {
            $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        } catch {
            Throw-MaterializerError -Message "Coordinator state is invalid and requires manual review: $statePath" -ExitCode 7
        }

        foreach ($field in @("coordinator_pid", "provider_pid", "adapter_worker_pid", "adapter_build_pid")) {
            $property = $state.PSObject.Properties[$field]
            if ($null -eq $property -or $null -eq $property.Value) {
                continue
            }
            try {
                $processId = [int]$property.Value
            } catch {
                Throw-MaterializerError -Message "Coordinator state has an invalid ${field}: $statePath" -ExitCode 7
            }
            if ($processId -le 0) {
                Throw-MaterializerError -Message "Coordinator state has an invalid ${field}: $statePath" -ExitCode 7
            }
            if (Test-MaterializerProcessAlive -ProcessId $processId) {
                $liveProcesses.Add("$field PID $processId in $providerRoot")
            }
        }
    }

    if ($liveProcesses.Count -gt 0) {
        foreach ($process in $liveProcesses) {
            Write-Host "[ACTIVE] $process"
        }
        Throw-MaterializerError -Message "Host payload mutation is blocked by a live watcher process." -ExitCode 4
    }
}

function Test-InstalledMarkerAdvertisesHostUseGate {
    param([Parameter(Mandatory = $true)][string]$MarkerPath)

    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        return $false
    }
    try {
        $marker = Get-Content -LiteralPath $MarkerPath -Raw | ConvertFrom-Json
        return [string]::Equals([string]$marker.managed_by, $script:ManagedBy, [StringComparison]::Ordinal) -and
            [int]$marker.host_use_gate_version -ge $script:HostUseGateVersion
    } catch {
        return $false
    }
}

function Assert-LegacyMcpBoundary {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $wrapperPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/wrapper/codedb-project-wrapper.mjs" -Label "CodeDB wrapper"
    if (-not (Test-Path -LiteralPath $wrapperPath -PathType Leaf) -or
        (Test-InstalledMarkerAdvertisesHostUseGate -MarkerPath $MarkerPath)) {
        return
    }
    Assert-NoReparsePoint -Path $wrapperPath -Root $ProjectRoot -Label "CodeDB wrapper"
    if (-not $ConfirmLegacyMcpStopped) {
        Throw-MaterializerError -Message "A legacy or unowned MCP wrapper exists without host-use leases. Confirm every legacy MCP session is stopped, then retry with -ConfirmLegacyMcpStopped." -ExitCode 4
    }
    Write-Host "[CONFIRMED] Legacy MCP sessions were explicitly confirmed stopped."
}

function Initialize-MaterializerHostUseGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    Assert-ExistingMaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
    Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
    $Lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
    Enter-MaterializerWatchManagementLocks -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveHostUseLeases -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveLegacyWatcherState -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-LegacyMcpBoundary -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
}

function Assert-TransactionTargetRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = ConvertTo-SafeRelativePath -Path $Path -Label "transaction target"
    if ([string]::Equals($normalized, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
        return $normalized
    }
    return Assert-TargetRelativePath -Path $normalized
}

function Write-DurableUtf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $temporaryPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    $stream = $null
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Content)
        $stream = [System.IO.FileStream]::new(
            $temporaryPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None,
            4096,
            [System.IO.FileOptions]::WriteThrough)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
        $stream.Dispose()
        $stream = $null
        [System.IO.File]::Move($temporaryPath, $Path)
    } finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Publish-TransactionFile {
    param(
        [Parameter(Mandatory = $true)][string]$StagePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    $stageRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($StagePath))
    $targetRoot = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($TargetPath))
    if (-not [string]::Equals($stageRoot, $targetRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Atomic payload publication requires staging and target paths on the same volume: $TargetPath"
    }

    if (Test-Path -LiteralPath $TargetPath) {
        if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
            throw "Atomic payload target is not a file: $TargetPath"
        }
        $replacementBackupPath = Join-Path (Split-Path -Parent $StagePath) ("swap-$([guid]::NewGuid().ToString('N')).bak")
        try {
            [System.IO.File]::Replace($StagePath, $TargetPath, $replacementBackupPath, $true)
        } finally {
            if (Test-Path -LiteralPath $replacementBackupPath -PathType Leaf) {
                Remove-Item -LiteralPath $replacementBackupPath -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        [System.IO.File]::Move($StagePath, $TargetPath)
    }
}

function New-TransactionEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][ValidateSet("Write", "Delete")][string]$Mutation,
        [AllowNull()][string]$DesiredSha256,
        [AllowNull()][string]$StagePath,
        [Parameter(Mandatory = $true)][string]$BackupRoot,
        [Parameter(Mandatory = $true)][int]$Index
    )

    $normalizedTarget = Assert-TransactionTargetRelativePath -Path $Target
    if ($Mutation -eq "Write" -and
        ([string]::IsNullOrWhiteSpace($DesiredSha256) -or $DesiredSha256 -notmatch '^[0-9a-f]{64}$' -or
            [string]::IsNullOrWhiteSpace($StagePath))) {
        throw "Transaction write entry is missing a staged file or SHA256: $normalizedTarget"
    }
    if ($Mutation -eq "Delete" -and
        (-not [string]::IsNullOrWhiteSpace($DesiredSha256) -or -not [string]::IsNullOrWhiteSpace($StagePath))) {
        throw "Transaction delete entry cannot contain staged file state: $normalizedTarget"
    }
    if ((Test-Path -LiteralPath $TargetPath) -and -not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
        throw "Transaction target is not a file: $normalizedTarget"
    }

    $existedBefore = Test-Path -LiteralPath $TargetPath -PathType Leaf
    $backupPath = $null
    $backupSha256 = $null
    if ($existedBefore) {
        $backupName = "{0:D4}.bak" -f $Index
        $backupPath = Join-Path $BackupRoot $backupName
        Copy-Item -LiteralPath $TargetPath -Destination $backupPath -Force
        $backupSha256 = Get-FileSha256 -Path $backupPath
    }

    return [pscustomobject]@{
        Target = $normalizedTarget
        TargetPath = $TargetPath
        Mutation = $Mutation
        DesiredSha256 = $DesiredSha256
        StagePath = $StagePath
        ExistedBefore = $existedBefore
        BackupPath = $backupPath
        BackupSha256 = $backupSha256
    }
}

function Write-TransactionJournal {
    param(
        [Parameter(Mandatory = $true)][ValidateSet("Sync", "Remove")][string]$Operation,
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [Parameter(Mandatory = $true)]$Entries
    )

    $transactionId = Split-Path -Leaf $TransactionRoot
    $journalEntries = @($Entries | ForEach-Object {
        [ordered]@{
            target = $_.Target
            mutation = $_.Mutation.ToLowerInvariant()
            desired_sha256 = if ($_.Mutation -eq "Write") { $_.DesiredSha256 } else { $null }
            existed_before = $_.ExistedBefore
            backup = if ($_.ExistedBefore) { "backup/$([System.IO.Path]::GetFileName($_.BackupPath))" } else { $null }
            backup_sha256 = $_.BackupSha256
        }
    })
    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        transaction_id = $transactionId
        state = "prepared"
        operation = $Operation.ToLowerInvariant()
        entries = $journalEntries
    }
    $journalPath = Join-Path $TransactionRoot $script:TransactionJournalName
    Write-DurableUtf8File -Path $journalPath -Content (($document | ConvertTo-Json -Depth 8) + "`n")
}

function Read-TransactionJournal {
    param(
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $transactionId = Split-Path -Leaf $TransactionRoot
    $journalPath = Join-Path $TransactionRoot $script:TransactionJournalName
    $document = Get-Content -LiteralPath $journalPath -Raw | ConvertFrom-Json
    $schemaVersion = [int](Get-RequiredProperty -Object $document -Name "schema_version" -Label "transaction journal")
    $managedBy = [string](Get-RequiredProperty -Object $document -Name "managed_by" -Label "transaction journal")
    $journalId = [string](Get-RequiredProperty -Object $document -Name "transaction_id" -Label "transaction journal")
    $state = [string](Get-RequiredProperty -Object $document -Name "state" -Label "transaction journal")
    $operation = [string](Get-RequiredProperty -Object $document -Name "operation" -Label "transaction journal")
    $journalEntries = @(Get-RequiredProperty -Object $document -Name "entries" -Label "transaction journal")
    if ($schemaVersion -ne 1 -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals($journalId, $transactionId, [StringComparison]::Ordinal) -or
        -not [string]::Equals($state, "prepared", [StringComparison]::Ordinal) -or
        $operation -notin @("sync", "remove") -or
        $journalEntries.Count -eq 0) {
        throw "Transaction journal identity, state, operation, or entries are invalid."
    }

    $seenTargets = @{}
    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($journalEntry in $journalEntries) {
        $target = Assert-TransactionTargetRelativePath -Path ([string](Get-RequiredProperty -Object $journalEntry -Name "target" -Label "transaction entry"))
        if ($seenTargets.ContainsKey($target)) {
            throw "Transaction journal contains a duplicate target: $target"
        }
        $seenTargets[$target] = $true

        $mutation = [string](Get-RequiredProperty -Object $journalEntry -Name "mutation" -Label "transaction entry")
        if ($mutation -notin @("write", "delete")) {
            throw "Transaction entry has an invalid mutation: $target"
        }
        $desiredSha256 = Get-RequiredProperty -Object $journalEntry -Name "desired_sha256" -Label "transaction entry"
        if ($mutation -eq "write") {
            $desiredSha256 = ([string]$desiredSha256).ToLowerInvariant()
            if ($desiredSha256 -notmatch '^[0-9a-f]{64}$') {
                throw "Transaction write entry has an invalid desired SHA256: $target"
            }
        } elseif ($null -ne $desiredSha256) {
            throw "Transaction delete entry contains a desired SHA256: $target"
        }

        $existedBeforeValue = Get-RequiredProperty -Object $journalEntry -Name "existed_before" -Label "transaction entry"
        if ($existedBeforeValue -isnot [bool]) {
            throw "Transaction entry has a non-boolean existed_before value: $target"
        }
        $existedBefore = [bool]$existedBeforeValue
        $backupRelativePath = Get-RequiredProperty -Object $journalEntry -Name "backup" -Label "transaction entry"
        $backupSha256 = Get-RequiredProperty -Object $journalEntry -Name "backup_sha256" -Label "transaction entry"
        $backupPath = $null
        if ($existedBefore) {
            $backupRelativePath = ConvertTo-SafeRelativePath -Path ([string]$backupRelativePath) -Label "transaction backup"
            $backupSha256 = ([string]$backupSha256).ToLowerInvariant()
            if ($backupRelativePath -notmatch '^backup/[0-9]{4}\.bak$' -or $backupSha256 -notmatch '^[0-9a-f]{64}$') {
                throw "Transaction entry has invalid backup metadata: $target"
            }
            $backupPath = ConvertTo-AbsoluteChildPath -Root $TransactionRoot -RelativePath $backupRelativePath -Label "transaction backup"
            Assert-NoReparsePoint -Path $backupPath -Root $TransactionRoot -Label "transaction backup"
            if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf) -or
                -not [string]::Equals((Get-FileSha256 -Path $backupPath), $backupSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Transaction backup is missing or does not match its journal hash: $target"
            }
        } elseif ($null -ne $backupRelativePath -or $null -ne $backupSha256) {
            throw "Transaction entry without prior state contains backup metadata: $target"
        }

        $targetPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $target -Label "transaction target"
        Assert-NoReparsePoint -Path $targetPath -Root $ProjectRoot -Label "transaction target"
        $entries.Add([pscustomobject]@{
            Target = $target
            TargetPath = $targetPath
            Mutation = if ($mutation -eq "write") { "Write" } else { "Delete" }
            DesiredSha256 = $desiredSha256
            StagePath = $null
            ExistedBefore = $existedBefore
            BackupPath = $backupPath
            BackupSha256 = $backupSha256
        })
    }

    return [pscustomobject]@{
        Operation = $operation
        Entries = $entries.ToArray()
    }
}

function Assert-TransactionRecoveryState {
    param([Parameter(Mandatory = $true)]$Entries)

    foreach ($entry in $Entries) {
        if ((Test-Path -LiteralPath $entry.TargetPath) -and -not (Test-Path -LiteralPath $entry.TargetPath -PathType Leaf)) {
            throw "Interrupted transaction target is no longer a file: $($entry.Target)"
        }
        $targetExists = Test-Path -LiteralPath $entry.TargetPath -PathType Leaf
        $currentSha256 = if ($targetExists) { Get-FileSha256 -Path $entry.TargetPath } else { $null }
        $matchesBefore = $entry.ExistedBefore -and $targetExists -and
            [string]::Equals($currentSha256, $entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)
        $matchesAfter = if ($entry.Mutation -eq "Write") {
            $targetExists -and [string]::Equals($currentSha256, $entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)
        } else {
            -not $targetExists
        }
        $matchesUnchangedMissing = -not $entry.ExistedBefore -and -not $targetExists
        if (-not ($matchesBefore -or $matchesAfter -or $matchesUnchangedMissing)) {
            throw "Interrupted transaction target changed outside the recorded before/after states: $($entry.Target)"
        }
    }
}

function Assert-TransactionEntryBeforeMutation {
    param([Parameter(Mandatory = $true)]$Entry)

    if ($Entry.ExistedBefore) {
        if (-not (Test-Path -LiteralPath $Entry.TargetPath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $Entry.TargetPath), $Entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Transaction target changed after it was backed up: $($Entry.Target)"
        }
    } elseif (Test-Path -LiteralPath $Entry.TargetPath) {
        throw "Transaction target appeared after the missing state was recorded: $($Entry.Target)"
    }
}

function Restore-Transaction {
    param(
        [Parameter(Mandatory = $true)]$Entries,
        [Parameter(Mandatory = $true)][string]$TransactionRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot
    )

    $errors = New-Object System.Collections.Generic.List[string]
    try {
        # Validate the whole recovery set before rollback can overwrite any external change.
        Assert-TransactionRecoveryState -Entries $Entries
    } catch {
        $errors.Add("validate interrupted state: $($_.Exception.Message)")
        return $errors.ToArray()
    }

    foreach ($entry in @($Entries | Where-Object { -not $_.ExistedBefore } | Sort-Object Target -Descending)) {
        try {
            if (Test-Path -LiteralPath $entry.TargetPath -PathType Leaf) {
                Remove-Item -LiteralPath $entry.TargetPath -Force
            }
        } catch {
            $errors.Add("remove $($entry.Target): $($_.Exception.Message)")
        }
    }

    $markerEntries = @($Entries | Where-Object { $_.ExistedBefore -and [string]::Equals($_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) })
    $fileEntries = @($Entries | Where-Object { $_.ExistedBefore -and -not [string]::Equals($_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) } | Sort-Object Target)
    foreach ($entry in @($fileEntries) + @($markerEntries)) {
        try {
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
            $restoreStagePath = Join-Path $TransactionRoot ("restore-$([guid]::NewGuid().ToString('N')).payload")
            Copy-Item -LiteralPath $entry.BackupPath -Destination $restoreStagePath -Force
            if (-not [string]::Equals((Get-FileSha256 -Path $restoreStagePath), $entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Restore staging hash mismatch."
            }
            Publish-TransactionFile -StagePath $restoreStagePath -TargetPath $entry.TargetPath
            if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), $entry.BackupSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Restored target hash mismatch."
            }
        } catch {
            $errors.Add("restore $($entry.Target): $($_.Exception.Message)")
        }
    }

    if ($errors.Count -eq 0) {
        $createdPaths = @($Entries | Where-Object { -not $_.ExistedBefore } | ForEach-Object { $_.TargetPath })
        if ($createdPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $createdPaths -TargetRoot $TargetRoot
        }
    }
    return $errors.ToArray()
}

function Invoke-PendingTransactionRecovery {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot
    )

    foreach ($transactionDirectory in @(Get-ChildItem -LiteralPath $Lock.Root -Force -Directory | Sort-Object Name)) {
        if ([string]::Equals($transactionDirectory.Name, $script:HostUseLeaseDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:TrackedHostAuthorizationDirectoryName, [StringComparison]::Ordinal)) {
            continue
        }
        $transactionRoot = $transactionDirectory.FullName
        $stagedRecoveryConflict = $false
        if ($transactionDirectory.Name -notmatch '^txn-v1-[0-9a-f]{12}$') {
            Throw-MaterializerError -Message "Unknown materializer recovery artifact requires manual review: $transactionRoot" -ExitCode 7
        }
        try {
            Assert-NoReparsePoint -Path $transactionRoot -Root $Lock.Root -Label "materializer transaction"
            $journalPath = Join-Path $transactionRoot $script:TransactionJournalName
            if (-not (Test-Path -LiteralPath $journalPath)) {
                # New transactions publish the journal before their first host mutation.
                Remove-Item -LiteralPath $transactionRoot -Recurse -Force
                Write-Host "[RECOVERED] Removed an interrupted pre-mutation transaction."
                continue
            }
            if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
                throw "Transaction journal is not a file."
            }
            Assert-NoReparsePoint -Path $journalPath -Root $transactionRoot -Label "transaction journal"
            $journal = Read-TransactionJournal -TransactionRoot $transactionRoot -ProjectRoot $ProjectRoot
            $stagedTargets = @(Get-GitStagedTargetChanges `
                -ProjectRoot $ProjectRoot `
                -RelativePaths @($journal.Entries | ForEach-Object { $_.Target }))
            if ($stagedTargets.Count -gt 0) {
                foreach ($target in $stagedTargets) {
                    Write-Host "[CONFLICT] GitStaged: $target - interrupted transaction recovery would change a staged target"
                }
                $stagedRecoveryConflict = $true
                Throw-MaterializerError -Message "Interrupted payload transaction recovery was rejected because package-managed targets have staged Git changes." -ExitCode 3
            }
            $rollbackErrors = @(Restore-Transaction -Entries $journal.Entries -TransactionRoot $transactionRoot -TargetRoot $TargetRoot)
            if ($rollbackErrors.Count -gt 0) {
                throw $rollbackErrors -join '; '
            }
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force
            Write-Host "[RECOVERED] Rolled back interrupted $($journal.Operation) transaction."
        } catch {
            if ($stagedRecoveryConflict) {
                throw
            }
            Throw-MaterializerError -Message "Interrupted payload transaction could not be recovered. $($_.Exception.Message) Transaction: $transactionRoot" -ExitCode 7
        }
    }
}

function Remove-EmptyManagedParents {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][string]$TargetRoot
    )

    $fullTargetRoot = [System.IO.Path]::GetFullPath($TargetRoot).TrimEnd('\', '/')
    $parents = @($Paths | ForEach-Object { Split-Path -Parent $_ } | Sort-Object Length -Descending -Unique)
    foreach ($parent in $parents) {
        $current = $parent
        while (-not [string]::IsNullOrWhiteSpace($current) -and
            -not [string]::Equals($current, $fullTargetRoot, [StringComparison]::OrdinalIgnoreCase) -and
            $current.StartsWith($fullTargetRoot + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            if ((Test-Path -LiteralPath $current -PathType Container) -and
                @(Get-ChildItem -LiteralPath $current -Force).Count -eq 0) {
                Remove-Item -LiteralPath $current -Force
                $current = Split-Path -Parent $current
            } else {
                break
            }
        }
    }
}

function Invoke-Sync {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $lock = $null
    $transactionRoot = $null
    $keepTransaction = $false
    $entries = $null
    try {
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot
        Initialize-MaterializerHostUseGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
        Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        Write-MaterializationPlan -Plan $plan
        if ($plan.HasConflict) {
            Throw-MaterializerError -Message "Payload sync was rejected because one or more targets conflict." -ExitCode 3
        }
        if ($plan.IsCurrent) {
            Write-Host "[OK] Host payload is already current; no files were written."
            return
        }

        $transactionRoot = Join-Path $lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $stageRoot = Join-Path $transactionRoot "stage"
        $backupRoot = Join-Path $transactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $stageRoot, $backupRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]

        foreach ($item in $plan.Files) {
            $needsFileWrite = $item.Status -eq "Missing" -or
                ($item.Status -eq "Upgradeable" -and
                    -not [string]::Equals([string]$item.TargetSha256, $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase))
            if (-not $needsFileWrite) {
                continue
            }

            $stagePath = Join-Path $stageRoot (([guid]::NewGuid().ToString("N")) + ".payload")
            Copy-Item -LiteralPath $item.SourcePath -Destination $stagePath -Force
            if (-not [string]::Equals((Get-FileSha256 -Path $stagePath), $item.SourceSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Staged payload hash mismatch: $($item.Target)"
            }

            if (Test-Path -LiteralPath $item.TargetPath -PathType Leaf) {
                if (-not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), [string]$item.TargetSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Payload target changed during sync: $($item.Target)"
                }
            }
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Write" `
                -DesiredSha256 $item.SourceSha256 `
                -StagePath $stagePath `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }

        foreach ($item in $plan.Retired) {
            if (-not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), $item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Retired payload target changed during sync: $($item.Target)"
            }
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Delete" `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }

        $markerStagePath = Join-Path $stageRoot ".rice-ai-codedb-payload.json"
        [System.IO.File]::WriteAllText($markerStagePath, (New-MarkerJson -Manifest $Manifest), [System.Text.UTF8Encoding]::new($false))
        $markerSha256 = Get-FileSha256 -Path $markerStagePath
        $entries.Add((New-TransactionEntry `
            -Target $script:MarkerRelativePath `
            -TargetPath $MarkerPath `
            -Mutation "Write" `
            -DesiredSha256 $markerSha256 `
            -StagePath $markerStagePath `
            -BackupRoot $backupRoot `
            -Index $entries.Count)) | Out-Null

        # The durable journal is the recovery commit point; target mutations start after it.
        Write-TransactionJournal -Operation "Sync" -TransactionRoot $transactionRoot -Entries $entries.ToArray()
        foreach ($entry in $entries) {
            Assert-TransactionEntryBeforeMutation -Entry $entry
            if ($entry.Mutation -eq "Write") {
                New-Item -ItemType Directory -Force -Path (Split-Path -Parent $entry.TargetPath) | Out-Null
                Publish-TransactionFile -StagePath $entry.StagePath -TargetPath $entry.TargetPath
                if (-not [string]::Equals((Get-FileSha256 -Path $entry.TargetPath), $entry.DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
                    throw "Published payload hash mismatch: $($entry.Target)"
                }
            } else {
                Remove-Item -LiteralPath $entry.TargetPath -Force
                if (Test-Path -LiteralPath $entry.TargetPath) {
                    throw "Retired payload target remained after deletion: $($entry.Target)"
                }
            }
            Invoke-TestFaultAfterMutation
        }

        $postPlan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if (-not $postPlan.IsCurrent) {
            throw "Post-sync verification did not reach the current state."
        }
        if ($plan.Retired.Count -gt 0) {
            Remove-EmptyManagedParents -Paths @($plan.Retired | ForEach-Object { $_.TargetPath }) -TargetRoot $TargetRoot
        }
        Write-Host "[OK] Host payload synchronized to version $($Manifest.PayloadVersion)."
    } catch {
        $originalError = $_.Exception
        if ($null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $TargetRoot)
            if ($rollbackErrors.Count -gt 0) {
                $keepTransaction = $true
                Throw-MaterializerError -Message "Payload sync failed and rollback was incomplete. $($rollbackErrors -join '; ') Transaction: $transactionRoot" -ExitCode 7
            }
        }
        if ($script:RequestedExitCode -ne 0) {
            throw $originalError
        }
        Throw-MaterializerError -Message "Payload sync failed and was rolled back. $($originalError.Message)" -ExitCode 6
    } finally {
        if ($null -ne $transactionRoot -and -not $keepTransaction -and (Test-Path -LiteralPath $transactionRoot)) {
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        Exit-MaterializerLock -Lock $lock
    }
}

function Invoke-Remove {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $lock = $null
    $transactionRoot = $null
    $keepTransaction = $false
    $entries = $null
    try {
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot
        Initialize-MaterializerHostUseGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
        Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        $marker = Read-InstalledMarker -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        if ($null -eq $marker) {
            Write-Host "[OK] No managed host payload is installed."
            return
        }

        $versionPolicy = Get-InstalledPayloadVersionPolicy -Manifest $Manifest -Marker $marker
        if ($versionPolicy.IsDowngrade) {
            Write-Host "[CONFLICT] Downgrade: installed payload sequence is newer than the requested payload."
            Throw-MaterializerError -Message "Payload removal was rejected because an older manifest cannot remove a newer installation." -ExitCode 3
        }
        if ($versionPolicy.IsSequenceCollision) {
            Write-Host "[CONFLICT] SequenceCollision: the installed and requested payloads reuse one sequence with different identities or file hashes."
            Throw-MaterializerError -Message "Payload removal was rejected because the installed payload identity does not match this manifest sequence." -ExitCode 3
        }

        $stagedTargets = @(Get-GitStagedTargetChanges `
            -ProjectRoot $ProjectRoot `
            -RelativePaths (@($marker.Files | ForEach-Object { $_.Target }) + @($script:MarkerRelativePath)))
        if ($stagedTargets.Count -gt 0) {
            foreach ($target in $stagedTargets) {
                Write-Host "[CONFLICT] GitStaged: $target - the Git index contains a staged change in package ownership scope"
            }
            Throw-MaterializerError -Message "Payload removal was rejected because package-managed targets have staged Git changes." -ExitCode 3
        }

        $conflicts = New-Object System.Collections.Generic.List[string]
        foreach ($item in $marker.Files) {
            $isTrustedTarget = @($Manifest.Files | Where-Object { [string]::Equals($_.Target, $item.Target, [StringComparison]::OrdinalIgnoreCase) }).Count -eq 1 -or
                $Manifest.RetiredTargetMap.ContainsKey($item.Target)
            if (-not $isTrustedTarget) {
                $conflicts.Add("$($item.Target) is not allowed by the current or retired manifest allowlist")
            } elseif (-not (Test-Path -LiteralPath $item.TargetPath -PathType Leaf)) {
                $conflicts.Add("$($item.Target) is missing or not a file")
            } elseif (-not [string]::Equals((Get-FileSha256 -Path $item.TargetPath), $item.InstalledSha256, [StringComparison]::OrdinalIgnoreCase)) {
                $conflicts.Add("$($item.Target) changed after installation")
            }
        }
        if ($conflicts.Count -gt 0) {
            foreach ($conflict in $conflicts) {
                Write-Host "[CONFLICT] $conflict"
            }
            Throw-MaterializerError -Message "Payload removal was rejected because managed files drifted." -ExitCode 3
        }

        $transactionRoot = Join-Path $lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $backupRoot = Join-Path $transactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]
        foreach ($item in $marker.Files) {
            $entries.Add((New-TransactionEntry `
                -Target $item.Target `
                -TargetPath $item.TargetPath `
                -Mutation "Delete" `
                -BackupRoot $backupRoot `
                -Index $entries.Count)) | Out-Null
        }
        $entries.Add((New-TransactionEntry `
            -Target $script:MarkerRelativePath `
            -TargetPath $MarkerPath `
            -Mutation "Delete" `
            -BackupRoot $backupRoot `
            -Index $entries.Count)) | Out-Null

        # The durable journal is the recovery commit point; target mutations start after it.
        Write-TransactionJournal -Operation "Remove" -TransactionRoot $transactionRoot -Entries $entries.ToArray()
        foreach ($entry in $entries) {
            Assert-TransactionEntryBeforeMutation -Entry $entry
            Remove-Item -LiteralPath $entry.TargetPath -Force
            if (Test-Path -LiteralPath $entry.TargetPath) {
                throw "Managed payload target remained after deletion: $($entry.Target)"
            }
            Invoke-TestFaultAfterMutation
        }
        if ($marker.Files.Count -gt 0) {
            Remove-EmptyManagedParents -Paths @($marker.Files | ForEach-Object { $_.TargetPath }) -TargetRoot $TargetRoot
        }
        Write-Host "[OK] Managed host payload was removed; unrelated host files were preserved."
    } catch {
        $originalError = $_.Exception
        if ($null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $TargetRoot)
            if ($rollbackErrors.Count -gt 0) {
                $keepTransaction = $true
                Throw-MaterializerError -Message "Payload removal failed and rollback was incomplete. $($rollbackErrors -join '; ') Transaction: $transactionRoot" -ExitCode 7
            }
        }
        if ($script:RequestedExitCode -ne 0) {
            throw $originalError
        }
        Throw-MaterializerError -Message "Payload removal failed and was rolled back. $($originalError.Message)" -ExitCode 6
    } finally {
        if ($null -ne $transactionRoot -and -not $keepTransaction -and (Test-Path -LiteralPath $transactionRoot)) {
            Remove-Item -LiteralPath $transactionRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
        Exit-MaterializerLock -Lock $lock
    }
}

try {
    $hasTrackedHostAuthorization = -not [string]::IsNullOrWhiteSpace($TrackedHostAuthorizationPath)
    if ($PocFixture -and $hasTrackedHostAuthorization) {
        Throw-MaterializerError -Message "Fixture and tracked-host mutation authorization modes are mutually exclusive." -ExitCode 4
    }
    if ($Action -notin @("Sync", "Remove") -and $hasTrackedHostAuthorization) {
        Throw-MaterializerError -Message "Tracked-host authorization is valid only for Sync or Remove." -ExitCode 4
    }
    if ($TestFailAfterMutation -gt 0 -and $TestCrashAfterMutation -gt 0) {
        Throw-MaterializerError -Message "Only one materializer test fault may be requested at a time." -ExitCode 2
    }
    if (($TestFailAfterMutation -gt 0 -or $TestCrashAfterMutation -gt 0) -and
        (-not $PocFixture -or $Action -notin @("Sync", "Remove"))) {
        Throw-MaterializerError -Message "Materializer test faults require a fixture-only Sync or Remove action." -ExitCode 4
    }

    $projectRootPath = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $projectRootPath -PathType Container)) {
        Throw-MaterializerError -Message "Project root does not exist: $projectRootPath" -ExitCode 2
    }
    Assert-NoReparsePoint -Path $projectRootPath -Root $projectRootPath -Label "project root"
    Assert-UnityProjectRoot -Root $projectRootPath

    if ([string]::IsNullOrWhiteSpace($PayloadRoot)) {
        $packageRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
        $PayloadRoot = Join-Path $packageRoot "Payload~"
    }
    $payload = Read-PayloadManifest -Root $PayloadRoot -ProjectRoot $projectRootPath
    if ($Action -in @("Sync", "Remove")) {
        Assert-MutationAuthorization -Root $projectRootPath -Manifest $payload -MutationAction $Action
    }
    $targetRoot = ConvertTo-AbsoluteChildPath -Root $projectRootPath -RelativePath "AIWork/codedb" -Label "host payload root"
    $markerPath = ConvertTo-AbsoluteChildPath -Root $projectRootPath -RelativePath $script:MarkerRelativePath -Label "installed payload marker"

    switch ($Action) {
        "DryRun" {
            $plan = Get-MaterializationPlan -Manifest $payload -MarkerPath $markerPath -ProjectRoot $projectRootPath
            Write-MaterializationPlan -Plan $plan
            if ($plan.IsCurrent) {
                Write-Host "[OK] Host payload is current."
            } elseif ($plan.HasConflict) {
                Write-Host "[STALE] Host payload has conflicts; Sync would be rejected."
            } else {
                Write-Host "[STALE] Host payload can be synchronized without overwriting unowned changes."
            }
        }
        "Verify" {
            $plan = Get-MaterializationPlan -Manifest $payload -MarkerPath $markerPath -ProjectRoot $projectRootPath
            Write-MaterializationPlan -Plan $plan
            if (-not $plan.IsCurrent) {
                Throw-MaterializerError -Message "Host payload is not current." -ExitCode 3
            }
            Write-Host "[OK] Host payload marker and managed files are current."
        }
        "Sync" {
            Invoke-Sync -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath
        }
        "Remove" {
            Invoke-Remove -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath
        }
    }
    exit 0
} catch {
    $exitCode = $script:RequestedExitCode
    if ($exitCode -eq 0) { $exitCode = 1 }
    [Console]::Error.WriteLine($_.Exception.Message)
    exit $exitCode
}
