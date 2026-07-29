#requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("DryRun", "Verify", "Upgrade", "Sync", "Remove")]
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
    [int]$TestCrashAfterMutation = 0,

    [switch]$TestFailWatcherHandoff,

    [switch]$TestCrashBeforeWatcherHandoff
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ManagedBy = "com.rice.ai-codedb"
$script:MarkerRelativePath = "AIWork/codedb/.rice-ai-codedb-payload.json"
$script:TargetPrefix = "AIWork/codedb/"
$script:GenerationId = "poc.25"
$script:BootstrapProtocol = 1
$script:GenerationTargetPrefix = "AIWork/.runtime/codedb/host/generations/$($script:GenerationId)/"
$script:CurrentPointerRelativePath = "AIWork/.runtime/codedb/host/current.json"
$script:LastKnownGoodPointerRelativePath = "AIWork/.runtime/codedb/host/last-known-good.json"
$script:GenerationLeaseRelativePath = "AIWork/.runtime/codedb/host/leases"
$script:RuntimeRelativePath = "AIWork/.runtime/codedb/payload-materializer"
$script:PocFixtureMarkerName = ".rice-ai-codedb-poc-fixture.json"
$script:TrackedHostAuthorizationDirectoryName = "authorizations"
$script:TrackedHostAuthorizationRelativeRoot = "AIWork/.runtime/codedb/payload-materializer/$($script:TrackedHostAuthorizationDirectoryName)"
$script:TrackedHostAuthorizationPurpose = "tracked-host-payload-mutation"
$script:TrackedHostAuthorizationAcknowledgement = "I authorize com.rice.ai-codedb to mutate only its audited host payload scope."
$script:HostUseGateVersion = 1
$script:ActiveMarkerName = "materialize-active.json"
$script:UpgradeStateName = "upgrade-state.json"
$script:UpgradeStateRelativePath = "$($script:RuntimeRelativePath)/$($script:UpgradeStateName)"
$script:HostUseLeaseDirectoryName = "host-use-leases"
$script:TransactionPrefix = "txn-v1-"
$script:TransactionJournalName = "transaction.json"
$script:RequestedExitCode = 0
$script:MutationCount = 0
$script:AllowedTargetPaths = @{}
$script:AllowedGenerationRelativePaths = @{}
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
foreach ($generationTarget in @(
    "codedb-mcp.runtime.example.toml",
    "codedbignore.example",
    "coordinator/codedb-watch-coordinator.mjs",
    "generation-manifest.json",
    "scripts/build-codedb-project-text-adapter.ps1",
    "scripts/check-codedb-project-freshness.ps1",
    "scripts/clear-codedb-project-index.ps1",
    "scripts/codedb-project-common.ps1",
    "scripts/emit-codedb-mcp-registration-draft.ps1",
    "scripts/manage-codedb-project-watch.ps1",
    "scripts/prepare-codedb-project-runtime.ps1",
    "scripts/prepare-codedb-project-watch-config.ps1",
    "scripts/probe-codedb-project-index.ps1",
    "scripts/probe-codedb-project-text-adapter.ps1",
    "scripts/refresh-codedb-project-if-stale.ps1",
    "scripts/refresh-codedb-project.ps1",
    "scripts/run-codedb-project-text-adapter-worker.ps1",
    "scripts/show-codedb-project-provider-guidance.ps1",
    "scripts/validate-codedb-mcp-project-config.ps1",
    "scripts/verify-codedb-project.ps1",
    "shared/codedb-host-use-gate.mjs"
)) {
    $script:AllowedGenerationRelativePaths[$generationTarget] = $true
    $script:AllowedTargetPaths[$script:GenerationTargetPrefix + $generationTarget] = $true
}
$script:AllowedTargetPaths[$script:CurrentPointerRelativePath] = $true

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

function Read-BoundedJsonDocument {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][int64]$MaximumBytes
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Throw-MaterializerError -Message "$Label does not exist: $Path" -ExitCode 2
    }
    $file = Get-Item -LiteralPath $Path -Force
    if ($file.Length -le 0 -or $file.Length -gt $MaximumBytes) {
        Throw-MaterializerError -Message "$Label size is outside the accepted range: $Path" -ExitCode 2
    }
    try {
        $text = Get-Content -LiteralPath $Path -Raw
        $document = $text | ConvertFrom-Json
    } catch {
        Throw-MaterializerError -Message "$Label is not valid JSON: $($_.Exception.Message)" -ExitCode 2
    }
    if ($null -eq $document -or $document.GetType() -ne [System.Management.Automation.PSCustomObject]) {
        Throw-MaterializerError -Message "$Label must contain one JSON object." -ExitCode 2
    }
    return [pscustomobject]@{ Text = $text; Document = $document }
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
    $allowed = $script:AllowedTargetPaths.ContainsKey($normalized)
    if (-not $allowed) {
        $generationMatch = [regex]::Match(
            $normalized,
            '^AIWork/\.runtime/codedb/host/generations/(?<generation>[A-Za-z0-9._-]{1,64})/(?<relative>.+)$',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($generationMatch.Success) {
            $generationRelativePath = ConvertTo-SafeRelativePath -Path $generationMatch.Groups['relative'].Value -Label "generation payload target"
            $allowed = $script:AllowedGenerationRelativePaths.ContainsKey($generationRelativePath)
        }
    }
    if ([string]::Equals($normalized, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or -not $allowed) {
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

    $manifestJson = Read-BoundedJsonDocument -Path $manifestPath -Label "payload manifest" -MaximumBytes (1024 * 1024)
    $document = $manifestJson.Document

    $schemaVersion = [int](Get-RequiredProperty -Object $document -Name "schema_version" -Label "payload manifest")
    $managedBy = [string](Get-RequiredProperty -Object $document -Name "managed_by" -Label "payload manifest")
    $packageVersion = [string](Get-RequiredProperty -Object $document -Name "package_version" -Label "payload manifest")
    $payloadVersion = [string](Get-RequiredProperty -Object $document -Name "payload_version" -Label "payload manifest")
    $payloadSequence = [int](Get-RequiredProperty -Object $document -Name "payload_sequence" -Label "payload manifest")
    $generationId = [string](Get-RequiredProperty -Object $document -Name "generation_id" -Label "payload manifest")
    $bootstrapProtocol = [int](Get-RequiredProperty -Object $document -Name "bootstrap_protocol" -Label "payload manifest")
    $currentPointerTarget = Assert-TargetRelativePath -Path ([string](Get-RequiredProperty -Object $document -Name "current_pointer_target" -Label "payload manifest"))
    $retiredTargets = @(Get-RequiredProperty -Object $document -Name "retired_targets" -Label "payload manifest")
    $manifestFiles = @(Get-RequiredProperty -Object $document -Name "files" -Label "payload manifest")

    if ($schemaVersion -ne 1 -or
        -not [string]::Equals($managedBy, $script:ManagedBy, [StringComparison]::Ordinal) -or
        [string]::IsNullOrWhiteSpace($packageVersion) -or
        [string]::IsNullOrWhiteSpace($payloadVersion) -or
        $payloadSequence -lt 1 -or
        -not [string]::Equals($generationId, $script:GenerationId, [StringComparison]::Ordinal) -or
        $bootstrapProtocol -ne $script:BootstrapProtocol -or
        -not [string]::Equals($currentPointerTarget, $script:CurrentPointerRelativePath, [StringComparison]::Ordinal) -or
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
    $sourceMap = @{}
    $targetMap = @{}
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
        $model = [pscustomobject]@{
            Source = $source
            SourcePath = $sourcePath
            Target = $target
            TargetPath = $targetPath
            Sha256 = $expectedHash
        }
        $files.Add($model)
        $sourceMap[$source] = $model
        $targetMap[$target] = $model
    }

    $manifest = [pscustomobject]@{
        SchemaVersion = $schemaVersion
        ManagedBy = $managedBy
        PackageVersion = $packageVersion
        PayloadVersion = $payloadVersion
        PayloadSequence = $payloadSequence
        GenerationId = $generationId
        BootstrapProtocol = $bootstrapProtocol
        CurrentPointerTarget = $currentPointerTarget
        RetiredTargets = @($retiredTargetMap.Keys | Sort-Object)
        RetiredTargetMap = $retiredTargetMap
        Root = $fullRoot
        ManifestPath = $manifestPath
        ManifestSha256 = Get-FileSha256 -Path $manifestPath
        Files = @($files | Sort-Object Target)
        SourceMap = $sourceMap
        TargetMap = $targetMap
    }
    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    $usesGenerationContract = $payloadSequence -ge 22 -or
        $targetMap.ContainsKey($generationManifestTarget) -or
        $targetMap.ContainsKey($script:CurrentPointerRelativePath)
    $manifest | Add-Member -NotePropertyName UsesGenerationContract -NotePropertyValue $usesGenerationContract
    if ($usesGenerationContract) {
        Assert-PayloadGenerationContract -Manifest $manifest
    }
    return $manifest
}

function Assert-PayloadGenerationContract {
    param([Parameter(Mandatory = $true)]$Manifest)

    $generationManifestTarget = $script:GenerationTargetPrefix + "generation-manifest.json"
    if (-not $Manifest.TargetMap.ContainsKey($generationManifestTarget) -or
        -not $Manifest.TargetMap.ContainsKey($script:CurrentPointerRelativePath)) {
        Throw-MaterializerError -Message "Payload manifest is missing its generation manifest or current pointer target." -ExitCode 2
    }

    $generationManifestFile = $Manifest.TargetMap[$generationManifestTarget]
    $pointerFile = $Manifest.TargetMap[$script:CurrentPointerRelativePath]
    if (-not [string]::Equals($generationManifestFile.Source, "Generations/$($script:GenerationId)/generation-manifest.json", [StringComparison]::Ordinal) -or
        -not [string]::Equals($pointerFile.Source, "host-current.json", [StringComparison]::Ordinal)) {
        Throw-MaterializerError -Message "Payload generation metadata sources do not match the audited package layout." -ExitCode 2
    }

    $generationJson = Read-BoundedJsonDocument -Path $generationManifestFile.SourcePath -Label "generation manifest" -MaximumBytes (1024 * 1024)
    $generation = $generationJson.Document
    $generationFiles = @(Get-RequiredProperty -Object $generation -Name "files" -Label "generation manifest")
    if ([int](Get-RequiredProperty -Object $generation -Name "schema_version" -Label "generation manifest") -ne 1 -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "managed_by" -Label "generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "generation_id" -Label "generation manifest"), $Manifest.GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "package_version" -Label "generation manifest"), $Manifest.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "payload_version" -Label "generation manifest"), $Manifest.PayloadVersion, [StringComparison]::Ordinal) -or
        [int](Get-RequiredProperty -Object $generation -Name "payload_sequence" -Label "generation manifest") -ne $Manifest.PayloadSequence -or
        [int](Get-RequiredProperty -Object $generation -Name "bootstrap_protocol" -Label "generation manifest") -ne $Manifest.BootstrapProtocol -or
        $generationFiles.Count -eq 0) {
        Throw-MaterializerError -Message "Generation manifest identity does not match the payload manifest." -ExitCode 2
    }

    $generationTargetFiles = @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase) -and
        -not [string]::Equals($_.Target, $generationManifestTarget, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($generationFiles.Count -ne $generationTargetFiles.Count) {
        Throw-MaterializerError -Message "Generation manifest file closure does not match the payload manifest." -ExitCode 2
    }
    $seenGenerationFiles = @{}
    foreach ($entry in $generationFiles) {
        $relativePath = ConvertTo-SafeRelativePath -Path ([string](Get-RequiredProperty -Object $entry -Name "path" -Label "generation file")) -Label "generation file"
        $expectedHash = ([string](Get-RequiredProperty -Object $entry -Name "sha256" -Label "generation file")).ToLowerInvariant()
        $target = $script:GenerationTargetPrefix + $relativePath
        if ($expectedHash -notmatch '^[0-9a-f]{64}$' -or
            $seenGenerationFiles.ContainsKey($relativePath) -or
            -not $Manifest.TargetMap.ContainsKey($target) -or
            -not [string]::Equals($Manifest.TargetMap[$target].Sha256, $expectedHash, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-MaterializerError -Message "Generation manifest contains an invalid, duplicate, or mismatched file: $relativePath" -ExitCode 2
        }
        $seenGenerationFiles[$relativePath] = $true
    }

    $pointerJson = Read-BoundedJsonDocument -Path $pointerFile.SourcePath -Label "generation pointer" -MaximumBytes (64 * 1024)
    $pointer = $pointerJson.Document
    $expectedGenerationRoot = $script:GenerationTargetPrefix.TrimEnd('/')
    if ([int](Get-RequiredProperty -Object $pointer -Name "schema_version" -Label "generation pointer") -ne 1 -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "managed_by" -Label "generation pointer"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "package_version" -Label "generation pointer"), $Manifest.PackageVersion, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "payload_version" -Label "generation pointer"), $Manifest.PayloadVersion, [StringComparison]::Ordinal) -or
        [int](Get-RequiredProperty -Object $pointer -Name "payload_sequence" -Label "generation pointer") -ne $Manifest.PayloadSequence -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "generation_id" -Label "generation pointer"), $Manifest.GenerationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "generation_relative_path" -Label "generation pointer"), $expectedGenerationRoot, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "generation_manifest_sha256" -Label "generation pointer"), $generationManifestFile.Sha256, [StringComparison]::OrdinalIgnoreCase) -or
        [int](Get-RequiredProperty -Object $pointer -Name "bootstrap_protocol" -Label "generation pointer") -ne $Manifest.BootstrapProtocol) {
        Throw-MaterializerError -Message "Generation pointer identity does not match the payload and generation manifests." -ExitCode 2
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
    $generationLeaseVersion = 0
    $generationId = $null
    $bootstrapProtocol = 0
    $generationLeaseProperty = $document.PSObject.Properties["generation_lease_version"]
    $generationIdProperty = $document.PSObject.Properties["generation_id"]
    $bootstrapProtocolProperty = $document.PSObject.Properties["bootstrap_protocol"]
    if ($null -ne $generationLeaseProperty -or $null -ne $generationIdProperty -or $null -ne $bootstrapProtocolProperty) {
        try {
            $generationLeaseVersion = [int]$generationLeaseProperty.Value
            $generationId = [string]$generationIdProperty.Value
            $bootstrapProtocol = [int]$bootstrapProtocolProperty.Value
        } catch {
            Throw-MaterializerError -Message "Installed payload marker has invalid generation metadata." -ExitCode 2
        }
        if ($generationLeaseVersion -lt 2 -or
            $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
            $bootstrapProtocol -lt 1) {
            Throw-MaterializerError -Message "Installed payload marker has invalid generation metadata." -ExitCode 2
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
        GenerationLeaseVersion = $generationLeaseVersion
        GenerationId = $generationId
        BootstrapProtocol = $bootstrapProtocol
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

function Get-AutomaticUpgradeEligibility {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)]$Plan
    )

    $marker = $Plan.Marker
    if ($null -eq $marker) {
        return [pscustomobject]@{ Eligible = $false; Reason = "first adoption requires explicit Sync authorization" }
    }
    if ($Plan.HasConflict -or $Plan.StagedTargets.Count -gt 0) {
        return [pscustomobject]@{ Eligible = $false; Reason = "conflict or staged target requires explicit review" }
    }
    foreach ($retired in $Plan.Retired) {
        $immutableGenerationTarget = $retired.Target -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/'
        if (-not $immutableGenerationTarget -or $retired.Status -ne "Retirable") {
            return [pscustomobject]@{ Eligible = $false; Reason = "non-generation retired target requires explicit review" }
        }
    }
    $knownLegacy = $marker.PayloadSequence -eq 21 -and
        [string]::Equals($marker.PackageVersion, "0.2.2", [StringComparison]::Ordinal) -and
        [string]::Equals($marker.PayloadVersion, "poc.21", [StringComparison]::Ordinal) -and
        $marker.HostUseGateVersion -eq 1 -and
        $Manifest.PayloadSequence -ge 22 -and
        $Manifest.BootstrapProtocol -eq 1 -and
        [string]::Equals($Manifest.GenerationId, $script:GenerationId, [StringComparison]::Ordinal)
    $knownGenerationUpgrade = $marker.PayloadSequence -ge 22 -and
        $marker.PayloadSequence -lt $Manifest.PayloadSequence -and
        $marker.GenerationLeaseVersion -ge 2 -and
        $marker.GenerationId -match '^[A-Za-z0-9._-]{1,64}$' -and
        $marker.BootstrapProtocol -ge 1 -and
        $marker.BootstrapProtocol -eq $Manifest.BootstrapProtocol -and
        -not [string]::Equals($marker.GenerationId, $Manifest.GenerationId, [StringComparison]::Ordinal)
    if (-not $knownLegacy -and -not $knownGenerationUpgrade) {
        return [pscustomobject]@{ Eligible = $false; Reason = "installed payload is not a supported owned generation upgrade source" }
    }

    $wrapperTarget = "AIWork/codedb/wrapper/codedb-project-wrapper.mjs"
    foreach ($item in $Plan.Files) {
        if ([string]::Equals($item.Target, $wrapperTarget, [StringComparison]::OrdinalIgnoreCase)) {
            $ownedWrapperTransition = if ($knownLegacy) {
                $item.Status -eq "Upgradeable" -and
                    -not [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256) -and
                    [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)
            } else {
                # A generation-only update must not replace the stable bridge.
                # Bootstrap protocol migrations require their own reviewed path.
                $item.Status -eq "Current"
            }
            if (-not $ownedWrapperTransition) {
                return [pscustomobject]@{ Eligible = $false; Reason = "bootstrap wrapper is not byte-exact at a supported protocol transition" }
            }
            continue
        }
        if ($item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            if ($item.Status -notin @("Missing", "Adoptable")) {
                return [pscustomobject]@{ Eligible = $false; Reason = "new generation target already exists and requires collision review" }
            }
            continue
        }
        if ([string]::Equals($item.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
            $ownedPointerTransition = if ($knownLegacy) {
                $item.Status -eq "Missing"
            } else {
                $item.Status -eq "Upgradeable" -and
                    -not [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256) -and
                    [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)
            }
            if (-not $ownedPointerTransition) {
                return [pscustomobject]@{ Eligible = $false; Reason = "new generation pointer already exists and requires collision review" }
            }
            continue
        }
        $ownedUnmodifiedTarget = $item.Status -eq "Current" -and
            -not [string]::IsNullOrWhiteSpace([string]$item.PreviousSha256) -and
            [string]::Equals([string]$item.TargetSha256, [string]$item.PreviousSha256, [StringComparison]::OrdinalIgnoreCase)
        if (-not $ownedUnmodifiedTarget) {
            return [pscustomobject]@{ Eligible = $false; Reason = "existing bootstrap payload is not fully owned and byte-exact" }
        }
    }
    $reason = if ($knownLegacy) {
        "owned poc.21 bootstrap can migrate without replacing active legacy scripts"
    } else {
        "owned immutable generation can switch while its leases remain protected"
    }
    return [pscustomobject]@{ Eligible = $true; Reason = $reason }
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
        generation_lease_version = 2
        generation_id = $Manifest.GenerationId
        bootstrap_protocol = $Manifest.BootstrapProtocol
        current_pointer = $Manifest.CurrentPointerTarget
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

    return (Get-MaterializerProcessIdentity -ProcessId $ProcessId).Alive
}

function Get-MaterializerProcessIdentity {
    param([AllowNull()]$ProcessId)

    try {
        $numericProcessId = [int]$ProcessId
        if ($numericProcessId -le 0) {
            return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
        }
    } catch {
        return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
    }

    try {
        $process = [System.Diagnostics.Process]::GetProcessById($numericProcessId)
    } catch [System.ArgumentException] {
        return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
    } catch {
        # Failure to inspect a possibly elevated process is indeterminate and
        # must remain a live safety owner.
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }
    try {
        if ($process.HasExited) {
            return [pscustomobject]@{ Alive = $false; StartTicks = $null; StartUnixMilliseconds = $null }
        }
    } catch {
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }

    try {
        $startUtc = $process.StartTime.ToUniversalTime()
        $startOffset = [DateTimeOffset]::new($startUtc)
        return [pscustomobject]@{
            Alive = $true
            StartTicks = $startUtc.Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)
            StartUnixMilliseconds = $startOffset.ToUnixTimeMilliseconds()
        }
    } catch {
        # Cross-elevation process metadata may be unavailable. A visible PID is
        # still treated as live, but it cannot prove an identity mismatch.
        return [pscustomobject]@{ Alive = $true; StartTicks = $null; StartUnixMilliseconds = $null }
    }
}

function Test-MaterializerGenerationProcessIdentity {
    param(
        [Parameter(Mandatory = $true)]$ProcessIdentity,
        [Parameter(Mandatory = $true)][string]$LeaseIdentity
    )

    [int64]$leaseStartMilliseconds = 0
    if (-not [int64]::TryParse($LeaseIdentity, [ref]$leaseStartMilliseconds) -or $leaseStartMilliseconds -le 0) {
        return $false
    }
    if (-not $ProcessIdentity.Alive -or $null -eq $ProcessIdentity.StartUnixMilliseconds) {
        return $null
    }
    return [Math]::Abs([int64]$ProcessIdentity.StartUnixMilliseconds - $leaseStartMilliseconds) -le 2000
}

function Get-MaterializerHostUseLeaseReport {
    param(
        [Parameter(Mandatory = $true)][string]$LeaseRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $liveLeases = New-Object System.Collections.Generic.List[string]
    $staleLeases = New-Object System.Collections.Generic.List[object]
    $invalidLeases = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $LeaseRoot)) {
        return [pscustomobject]@{
            Live = $liveLeases.ToArray()
            Stale = $staleLeases.ToArray()
            Invalid = $invalidLeases.ToArray()
        }
    }
    if (-not (Test-Path -LiteralPath $LeaseRoot -PathType Container)) {
        $invalidLeases.Add($LeaseRoot)
        return [pscustomobject]@{
            Live = $liveLeases.ToArray()
            Stale = $staleLeases.ToArray()
            Invalid = $invalidLeases.ToArray()
        }
    }

    Assert-NoReparsePoint -Path $LeaseRoot -Root $ProjectRoot -Label "host-use lease root"
    foreach ($item in @(Get-ChildItem -LiteralPath $LeaseRoot -Force | Sort-Object Name)) {
        $nameMatch = [regex]::Match($item.Name, '^(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json$')
        if ($item.PSIsContainer -or -not $nameMatch.Success) {
            $invalidLeases.Add($item.FullName)
            continue
        }

        $fileOwner = $nameMatch.Groups[1].Value
        $fileProcessId = [int]$nameMatch.Groups[2].Value
        $fileToken = $nameMatch.Groups[3].Value
        try {
            Assert-NoReparsePoint -Path $item.FullName -Root $LeaseRoot -Label "host-use lease"
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
            $invalidLeases.Add($item.FullName)
            continue
        }

        $processIdentity = Get-MaterializerProcessIdentity -ProcessId $processId
        if ($processIdentity.Alive) {
            $liveLeases.Add("$owner PID $processId")
        } else {
            $staleLeases.Add([pscustomobject]@{
                Owner = $owner
                ProcessId = $processId
                Path = $item.FullName
            })
        }
    }

    return [pscustomobject]@{
        Live = $liveLeases.ToArray()
        Stale = $staleLeases.ToArray()
        Invalid = $invalidLeases.ToArray()
    }
}

function Get-MaterializerGenerationLeaseReport {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $liveLeases = New-Object System.Collections.Generic.List[string]
    $liveLeaseDetails = New-Object System.Collections.Generic.List[object]
    $staleLeases = New-Object System.Collections.Generic.List[object]
    $invalidLeases = New-Object System.Collections.Generic.List[string]
    $leasesRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:GenerationLeaseRelativePath -Label "generation lease root"
    if (-not (Test-Path -LiteralPath $leasesRoot)) {
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); LiveDetails = $liveLeaseDetails.ToArray(); Stale = $staleLeases.ToArray(); Invalid = $invalidLeases.ToArray() }
    }
    if (-not (Test-Path -LiteralPath $leasesRoot -PathType Container)) {
        $invalidLeases.Add($leasesRoot)
        return [pscustomobject]@{ Live = $liveLeases.ToArray(); LiveDetails = $liveLeaseDetails.ToArray(); Stale = $staleLeases.ToArray(); Invalid = $invalidLeases.ToArray() }
    }

    Assert-NoReparsePoint -Path $leasesRoot -Root $ProjectRoot -Label "generation lease root"
    $now = [DateTime]::UtcNow
    foreach ($generationDirectory in @(Get-ChildItem -LiteralPath $leasesRoot -Force)) {
        if (-not $generationDirectory.PSIsContainer -or $generationDirectory.Name -notmatch '^[A-Za-z0-9._-]{1,64}$') {
            $invalidLeases.Add($generationDirectory.FullName)
            continue
        }
        Assert-NoReparsePoint -Path $generationDirectory.FullName -Root $leasesRoot -Label "generation lease directory"
        foreach ($item in @(Get-ChildItem -LiteralPath $generationDirectory.FullName -Force)) {
            $nameMatch = [regex]::Match($item.Name, '^(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json$')
            $temporaryNameMatch = [regex]::Match($item.Name, '^\.(mcp|watcher)-([0-9]+)-([0-9a-f]{32})\.json\.([0-9]+)\.[0-9a-fA-F-]{36}\.tmp$')
            if (-not $item.PSIsContainer -and $temporaryNameMatch.Success) {
                try {
                    Assert-NoReparsePoint -Path $item.FullName -Root $generationDirectory.FullName -Label "generation lease temporary file"
                    if ($item.LastWriteTimeUtc -lt $now.AddMinutes(-5)) {
                        $staleLeases.Add([pscustomobject]@{
                            GenerationId = $generationDirectory.Name
                            Owner = "temporary"
                            ProcessId = [int]$temporaryNameMatch.Groups[4].Value
                            Path = $item.FullName
                        })
                    }
                } catch {
                    $invalidLeases.Add($item.FullName)
                }
                continue
            }
            if ($item.PSIsContainer -or -not $nameMatch.Success) {
                $invalidLeases.Add($item.FullName)
                continue
            }
            try {
                Assert-NoReparsePoint -Path $item.FullName -Root $generationDirectory.FullName -Label "generation lease"
                $lease = Get-Content -LiteralPath $item.FullName -Raw | ConvertFrom-Json
                $owner = [string]$lease.owner
                $processId = [int]$lease.pid
                $generationId = [string]$lease.generation_id
                $heartbeat = [DateTime]::Parse([string]$lease.heartbeat_at_utc).ToUniversalTime()
                $leaseProcessStartIdentity = [string]$lease.process_start_identity
                $valid = [int]$lease.schema_version -eq 2 -and
                    [int]$lease.generation_lease_version -eq 2 -and
                    [string]::Equals([string]$lease.managed_by, $script:ManagedBy, [StringComparison]::Ordinal) -and
                    [string]::Equals($generationId, $generationDirectory.Name, [StringComparison]::Ordinal) -and
                    [string]::Equals($owner, $nameMatch.Groups[1].Value, [StringComparison]::Ordinal) -and
                    $processId -eq [int]$nameMatch.Groups[2].Value -and
                    [string]::Equals([string]$lease.lease_id, [System.IO.Path]::GetFileNameWithoutExtension($item.Name), [StringComparison]::Ordinal) -and
                    $leaseProcessStartIdentity -match '^[0-9]{1,20}$' -and
                    [string]::Equals([System.IO.Path]::GetFullPath([string]$lease.project_root), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -and
                    $heartbeat -le $now.AddSeconds(30)
            } catch {
                $valid = $false
            }
            if (-not $valid) {
                $invalidLeases.Add($item.FullName)
                continue
            }

            $processIdentity = Get-MaterializerProcessIdentity -ProcessId $processId
            $identityMatches = Test-MaterializerGenerationProcessIdentity -ProcessIdentity $processIdentity -LeaseIdentity $leaseProcessStartIdentity
            if ($processIdentity.Alive -and ($null -eq $identityMatches -or $identityMatches)) {
                $liveLeases.Add("generation $generationId $owner PID $processId")
                $liveLeaseDetails.Add([pscustomobject]@{
                    GenerationId = $generationId
                    Owner = $owner
                    ProcessId = $processId
                    Path = $item.FullName
                })
            } else {
                $staleLeases.Add([pscustomobject]@{
                    GenerationId = $generationId
                    Owner = $owner
                    ProcessId = $processId
                    Path = $item.FullName
                })
            }
        }
    }
    return [pscustomobject]@{ Live = $liveLeases.ToArray(); LiveDetails = $liveLeaseDetails.ToArray(); Stale = $staleLeases.ToArray(); Invalid = $invalidLeases.ToArray() }
}

function Write-HostUseLeaseGuidance {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $runtimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
    $leaseRoot = Join-Path $runtimeRoot $script:HostUseLeaseDirectoryName
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    foreach ($path in $report.Invalid) {
        Write-Host "[BLOCKED] Host-use lease requires manual review: $path"
    }
    foreach ($lease in $report.Live) {
        Write-Host "[ACTIVE] $lease"
    }
    foreach ($path in $generationReport.Invalid) {
        Write-Host "[BLOCKED] Generation lease requires manual review: $path"
    }
    foreach ($lease in $generationReport.Live) {
        Write-Host "[ACTIVE] $lease"
    }
    if ($report.Live.Count -gt 0 -or $generationReport.Live.Count -gt 0) {
        Write-Host "[BLOCKED] Host payload Sync/Remove is blocked while CodeDB host tooling is active. Pause the watcher and disconnect project MCP sessions first."
    }
    foreach ($lease in $report.Stale) {
        Write-Host "[STALE-LEASE] $($lease.Owner) PID $($lease.ProcessId) will be reclaimed by the next authorized mutation."
    }
    foreach ($lease in $generationReport.Stale) {
        Write-Host "[STALE-LEASE] generation $($lease.GenerationId) $($lease.Owner) PID $($lease.ProcessId) will be reclaimed by the next authorized mutation."
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
        $markerProcessIdentity = Get-MaterializerProcessIdentity -ProcessId $marker.pid
        $processStartProperty = $marker.PSObject.Properties["process_start_ticks"]
        $markerProcessStartTicks = if ($null -eq $processStartProperty) { "" } else { [string]$processStartProperty.Value }
        $valid = [int]$marker.schema_version -eq 1 -and
            [int]$marker.host_use_gate_version -eq $script:HostUseGateVersion -and
            [string]::Equals([string]$marker.managed_by, $script:ManagedBy, [StringComparison]::Ordinal) -and
            [int]$marker.pid -gt 0 -and
            [string]::Equals(
                [System.IO.Path]::GetFullPath([string]$marker.project_root),
                [System.IO.Path]::GetFullPath($ProjectRoot),
                [StringComparison]::OrdinalIgnoreCase) -and
            ([string]::IsNullOrWhiteSpace($markerProcessStartTicks) -or $markerProcessStartTicks -match '^[0-9]{1,20}$')
    } catch {
        $valid = $false
    }
    if (-not $valid) {
        Throw-MaterializerError -Message "Materializer active marker is invalid and requires manual review: $($Lock.ActiveMarkerPath)" -ExitCode 7
    }
    if ([int]$marker.pid -ne $PID -and $markerProcessIdentity.Alive -and
        ($null -eq $markerProcessIdentity.StartTicks -or
            [string]::IsNullOrWhiteSpace($markerProcessStartTicks) -or
            [string]::Equals($markerProcessStartTicks, [string]$markerProcessIdentity.StartTicks, [StringComparison]::Ordinal))) {
        Throw-MaterializerError -Message "Another payload materializer PID $($marker.pid) is active." -ExitCode 4
    }
    if ([int]$marker.pid -ne $PID -and $markerProcessIdentity.Alive -and
        -not [string]::IsNullOrWhiteSpace($markerProcessStartTicks) -and
        $null -ne $markerProcessIdentity.StartTicks -and
        -not [string]::Equals($markerProcessStartTicks, [string]$markerProcessIdentity.StartTicks, [StringComparison]::Ordinal)) {
        Write-Host "[RECOVERED] Ignored a stale materializer marker whose PID was reused."
    }
}

function Publish-MaterializerActiveMarker {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$MarkerAction
    )

    $publishedAction = if ([string]::IsNullOrWhiteSpace($MarkerAction)) {
        $Action.ToLowerInvariant()
    } else {
        $MarkerAction.ToLowerInvariant()
    }
    if ($publishedAction -notin @("upgrade", "sync", "remove")) {
        Throw-MaterializerError -Message "Unsupported materializer active marker action: $publishedAction" -ExitCode 2
    }
    $selfIdentity = Get-MaterializerProcessIdentity -ProcessId $PID
    $document = [ordered]@{
        schema_version = 1
        host_use_gate_version = $script:HostUseGateVersion
        managed_by = $script:ManagedBy
        pid = $PID
        process_start_ticks = $selfIdentity.StartTicks
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
        action = $publishedAction
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

function Publish-MaterializerUpgradeState {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][ValidateSet("INSTALLING", "SWITCHING", "ROLLBACK", "CURRENT", "CHECK_FAILED")][string]$State,
        [AllowNull()][string]$Message
    )

    $statePath = Join-Path $Lock.Root $script:UpgradeStateName
    Assert-NoReparsePoint -Path $statePath -Root $ProjectRoot -Label "materializer upgrade state"
    $boundedMessage = if ([string]::IsNullOrWhiteSpace($Message)) {
        $null
    } elseif ($Message.Length -le 512) {
        $Message
    } else {
        $Message.Substring(0, 512)
    }
    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        project_root = [System.IO.Path]::GetFullPath($ProjectRoot)
        state = $State
        generation_id = $script:GenerationId
        updated_at_utc = [DateTime]::UtcNow.ToString("o")
        message = $boundedMessage
    }
    $stagePath = Join-Path $Lock.Root ("upgrade-state-$([guid]::NewGuid().ToString('N')).tmp")
    try {
        Write-DurableUtf8File -Path $stagePath -Content (($document | ConvertTo-Json -Depth 6) + "`n")
        Publish-TransactionFile -StagePath $stagePath -TargetPath $statePath
    } finally {
        Remove-Item -LiteralPath $stagePath -Force -ErrorAction SilentlyContinue
    }
}

function Assert-MaterializerUpgradeStateArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    Assert-NoReparsePoint -Path $Path -Root $ProjectRoot -Label "materializer upgrade state"
    $stateJson = Read-BoundedJsonDocument -Path $Path -Label "materializer upgrade state" -MaximumBytes (64 * 1024)
    $state = $stateJson.Document
    if ([int](Get-RequiredProperty -Object $state -Name "schema_version" -Label "materializer upgrade state") -ne 1 -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $state -Name "managed_by" -Label "materializer upgrade state"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals([System.IO.Path]::GetFullPath([string](Get-RequiredProperty -Object $state -Name "project_root" -Label "materializer upgrade state")), [System.IO.Path]::GetFullPath($ProjectRoot), [StringComparison]::OrdinalIgnoreCase) -or
        [string](Get-RequiredProperty -Object $state -Name "state" -Label "materializer upgrade state") -notin @("INSTALLING", "SWITCHING", "ROLLBACK", "CURRENT", "CHECK_FAILED") -or
        [string](Get-RequiredProperty -Object $state -Name "generation_id" -Label "materializer upgrade state") -notmatch '^[A-Za-z0-9._-]{1,64}$') {
        throw "Materializer upgrade state identity is invalid."
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
    $report = Get-MaterializerHostUseLeaseReport -LeaseRoot $leaseRoot -ProjectRoot $ProjectRoot
    $generationReport = Get-MaterializerGenerationLeaseReport -ProjectRoot $ProjectRoot
    if ($report.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Host-use lease is invalid and requires manual review: $($report.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $report.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed stale $($lease.Owner) host-use lease for PID $($lease.ProcessId)."
    }
    if ($generationReport.Invalid.Count -gt 0) {
        Throw-MaterializerError -Message "Generation lease is invalid and requires manual review: $($generationReport.Invalid[0])" -ExitCode 7
    }
    foreach ($lease in $generationReport.Stale) {
        Remove-Item -LiteralPath $lease.Path -Force
        Write-Host "[RECOVERED] Removed stale generation $($lease.GenerationId) $($lease.Owner) lease for PID $($lease.ProcessId)."
    }

    if ($report.Live.Count -gt 0 -or $generationReport.Live.Count -gt 0) {
        foreach ($lease in $report.Live) {
            Write-Host "[ACTIVE] $lease"
        }
        foreach ($lease in $generationReport.Live) {
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

function Complete-MaterializerHostUseGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath
    )

    $Lock.ProviderRuntimeRoots = @(Get-MaterializerProviderRuntimeRoots -ProjectRoot $ProjectRoot)
    Enter-MaterializerWatchManagementLocks -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveHostUseLeases -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-NoLiveLegacyWatcherState -Lock $Lock -ProjectRoot $ProjectRoot
    Assert-LegacyMcpBoundary -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
}

function Initialize-MaterializerUpgradeGate {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    Assert-ExistingMaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
    Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
}

function Assert-TransactionTargetRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $normalized = ConvertTo-SafeRelativePath -Path $Path -Label "transaction target"
    if ([string]::Equals($normalized, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($normalized, $script:LastKnownGoodPointerRelativePath, [StringComparison]::OrdinalIgnoreCase) -or
        [string]::Equals($normalized, $script:UpgradeStateRelativePath, [StringComparison]::OrdinalIgnoreCase)) {
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
        [Parameter(Mandatory = $true)]$Entries,
        [switch]$AutomaticUpgrade,
        [AllowNull()][string]$PreviousWatcherManagerPath,
        [AllowNull()][string]$ProjectRoot
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
    $previousWatcherManager = $null
    $previousWatcherManagerSha256 = $null
    if ($AutomaticUpgrade) {
        if ([string]::IsNullOrWhiteSpace($ProjectRoot) -or [string]::IsNullOrWhiteSpace($PreviousWatcherManagerPath)) {
            throw "Automatic-upgrade journal requires the previous watcher manager identity."
        }
        $fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
        $fullPreviousManager = [System.IO.Path]::GetFullPath($PreviousWatcherManagerPath)
        Assert-PathInside -Path $fullPreviousManager -Root $fullProjectRoot -Label "previous watcher manager"
        $previousWatcherManager = $fullPreviousManager.Substring($fullProjectRoot.Length + 1).Replace('\', '/')
        $previousWatcherManager = ConvertTo-SafeRelativePath -Path $previousWatcherManager -Label "previous watcher manager"
        $isLegacyManager = [string]::Equals($previousWatcherManager, "AIWork/codedb/scripts/manage-codedb-project-watch.ps1", [StringComparison]::OrdinalIgnoreCase)
        $isGenerationManager = $previousWatcherManager -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/scripts/manage-codedb-project-watch\.ps1$'
        if (-not $isLegacyManager -and -not $isGenerationManager) {
            throw "Previous watcher manager is outside the supported legacy or immutable-generation layout."
        }
        Assert-NoReparsePoint -Path $fullPreviousManager -Root $fullProjectRoot -Label "previous watcher manager"
        if (-not (Test-Path -LiteralPath $fullPreviousManager -PathType Leaf)) {
            throw "Previous watcher manager does not exist."
        }
        $previousWatcherManagerSha256 = Get-FileSha256 -Path $fullPreviousManager
    }
    $document = [ordered]@{
        schema_version = 1
        managed_by = $script:ManagedBy
        transaction_id = $transactionId
        state = "prepared"
        operation = $Operation.ToLowerInvariant()
        automatic_upgrade = [bool]$AutomaticUpgrade
        previous_watcher_manager = $previousWatcherManager
        previous_watcher_manager_sha256 = $previousWatcherManagerSha256
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

    $automaticUpgrade = $false
    $automaticUpgradeProperty = $document.PSObject.Properties["automatic_upgrade"]
    if ($null -ne $automaticUpgradeProperty) {
        if ($automaticUpgradeProperty.Value -isnot [bool]) {
            throw "Transaction journal automatic_upgrade must be a boolean."
        }
        $automaticUpgrade = [bool]$automaticUpgradeProperty.Value
    }
    $previousWatcherManagerPath = $null
    $previousWatcherManagerSha256 = $null
    $previousWatcherProperty = $document.PSObject.Properties["previous_watcher_manager"]
    $previousWatcherHashProperty = $document.PSObject.Properties["previous_watcher_manager_sha256"]
    if ($automaticUpgrade) {
        if ($null -eq $previousWatcherProperty -or [string]::IsNullOrWhiteSpace([string]$previousWatcherProperty.Value) -or
            $null -eq $previousWatcherHashProperty -or [string]$previousWatcherHashProperty.Value -notmatch '^[0-9a-fA-F]{64}$') {
            throw "Automatic-upgrade journal is missing the previous watcher manager identity."
        }
        $previousWatcherRelativePath = ConvertTo-SafeRelativePath -Path ([string]$previousWatcherProperty.Value) -Label "previous watcher manager"
        $isLegacyManager = [string]::Equals($previousWatcherRelativePath, "AIWork/codedb/scripts/manage-codedb-project-watch.ps1", [StringComparison]::OrdinalIgnoreCase)
        $isGenerationManager = $previousWatcherRelativePath -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/scripts/manage-codedb-project-watch\.ps1$'
        if (-not $isLegacyManager -and -not $isGenerationManager) {
            throw "Automatic-upgrade journal has an unsupported previous watcher manager."
        }
        $previousWatcherManagerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $previousWatcherRelativePath -Label "previous watcher manager"
        Assert-NoReparsePoint -Path $previousWatcherManagerPath -Root $ProjectRoot -Label "previous watcher manager"
        $previousWatcherManagerSha256 = ([string]$previousWatcherHashProperty.Value).ToLowerInvariant()
    } elseif (($null -ne $previousWatcherProperty -and $null -ne $previousWatcherProperty.Value) -or
        ($null -ne $previousWatcherHashProperty -and $null -ne $previousWatcherHashProperty.Value)) {
        throw "Non-upgrade transaction journal cannot select a previous watcher manager."
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
        AutomaticUpgrade = $automaticUpgrade
        PreviousWatcherManagerPath = $previousWatcherManagerPath
        PreviousWatcherManagerSha256 = $previousWatcherManagerSha256
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

function Assert-PendingAutomaticUpgradeMarker {
    param(
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        throw "Pending automatic-upgrade recovery is missing its active marker."
    }
    Assert-NoReparsePoint -Path $MarkerPath -Root $ProjectRoot -Label "pending automatic-upgrade marker"
    $markerJson = Read-BoundedJsonDocument -Path $MarkerPath -Label "pending automatic-upgrade marker" -MaximumBytes (64 * 1024)
    $marker = $markerJson.Document
    $processStartTicks = [string](Get-RequiredProperty -Object $marker -Name "process_start_ticks" -Label "pending automatic-upgrade marker")
    $createdAt = [DateTime]::MinValue
    if ([int](Get-RequiredProperty -Object $marker -Name "schema_version" -Label "pending automatic-upgrade marker") -ne 1 -or
        [int](Get-RequiredProperty -Object $marker -Name "host_use_gate_version" -Label "pending automatic-upgrade marker") -ne $script:HostUseGateVersion -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $marker -Name "managed_by" -Label "pending automatic-upgrade marker"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        [int](Get-RequiredProperty -Object $marker -Name "pid" -Label "pending automatic-upgrade marker") -le 0 -or
        $processStartTicks -notmatch '^[0-9]{1,20}$' -or
        -not [string]::Equals(
            [System.IO.Path]::GetFullPath([string](Get-RequiredProperty -Object $marker -Name "project_root" -Label "pending automatic-upgrade marker")),
            [System.IO.Path]::GetFullPath($ProjectRoot),
            [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $marker -Name "action" -Label "pending automatic-upgrade marker"), "upgrade", [StringComparison]::Ordinal) -or
        -not [DateTime]::TryParse([string](Get-RequiredProperty -Object $marker -Name "created_at_utc" -Label "pending automatic-upgrade marker"), [ref]$createdAt)) {
        throw "Pending automatic-upgrade marker identity or schema is invalid."
    }
}

function Assert-PendingAutomaticUpgradeJournalIdentity {
    param(
        [Parameter(Mandatory = $true)]$Journal,
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not $Journal.AutomaticUpgrade -or
        -not [string]::Equals([string]$Journal.Operation, "sync", [StringComparison]::Ordinal)) {
        throw "Pending automatic-upgrade journal has the wrong operation identity."
    }
    $pointerTarget = [string]$Manifest.CurrentPointerTarget
    if (-not $Manifest.TargetMap.ContainsKey($pointerTarget)) {
        throw "Payload manifest has no current-pointer identity for pending recovery."
    }
    $pointerEntry = @($Journal.Entries | Where-Object {
        [string]::Equals([string]$_.Target, $pointerTarget, [StringComparison]::OrdinalIgnoreCase)
    })
    $markerEntry = @($Journal.Entries | Where-Object {
        [string]::Equals([string]$_.Target, $script:MarkerRelativePath, [StringComparison]::OrdinalIgnoreCase)
    })
    if ($pointerEntry.Count -ne 1 -or $markerEntry.Count -ne 1 -or
        -not [string]::Equals([string]$pointerEntry[0].Mutation, "Write", [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$markerEntry[0].Mutation, "Write", [StringComparison]::Ordinal) -or
        -not [string]::Equals([string]$pointerEntry[0].DesiredSha256, [string]$Manifest.TargetMap[$pointerTarget].Sha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Pending automatic-upgrade journal does not select the package generation pointer and marker."
    }
    $pointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $pointerTarget -Label "pending current generation pointer"
    $installedMarkerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "pending installed payload marker"
    if (-not (Test-Path -LiteralPath $pointerPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $installedMarkerPath -PathType Leaf) -or
        -not [string]::Equals((Get-FileSha256 -Path $pointerPath), [string]$pointerEntry[0].DesiredSha256, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-FileSha256 -Path $installedMarkerPath), [string]$markerEntry[0].DesiredSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Pending automatic-upgrade journal no longer matches the selected package generation."
    }

    $previousManagerPath = [System.IO.Path]::GetFullPath([string]$Journal.PreviousWatcherManagerPath)
    Assert-PathInside -Path $previousManagerPath -Root $ProjectRoot -Label "pending previous watcher manager"
    $projectPrefix = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    $previousManagerTarget = $previousManagerPath.Substring($projectPrefix.Length).Replace('\', '/')
    $managerBackupEntry = @($Journal.Entries | Where-Object {
        [string]::Equals([string]$_.Target, $previousManagerTarget, [StringComparison]::OrdinalIgnoreCase)
    })
    $currentManagerMatches = (Test-Path -LiteralPath $previousManagerPath -PathType Leaf) -and
        [string]::Equals((Get-FileSha256 -Path $previousManagerPath), [string]$Journal.PreviousWatcherManagerSha256, [StringComparison]::OrdinalIgnoreCase)
    $backupManagerMatches = $managerBackupEntry.Count -eq 1 -and
        $managerBackupEntry[0].ExistedBefore -and
        [string]::Equals([string]$managerBackupEntry[0].BackupSha256, [string]$Journal.PreviousWatcherManagerSha256, [StringComparison]::OrdinalIgnoreCase)
    if (-not $currentManagerMatches -and -not $backupManagerMatches) {
        throw "Pending automatic-upgrade journal no longer proves its previous watcher manager identity."
    }
}

function Get-PendingAutomaticUpgradeRecovery {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $notPending = [pscustomobject]@{ Pending = $false; TransactionId = $null }
    $runtimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:RuntimeRelativePath -Label "materializer runtime"
    if (-not (Test-Path -LiteralPath $runtimeRoot)) {
        return $notPending
    }
    if (-not (Test-Path -LiteralPath $runtimeRoot -PathType Container)) {
        throw "Materializer recovery runtime is not a directory: $runtimeRoot"
    }
    Assert-NoReparsePoint -Path $runtimeRoot -Root $ProjectRoot -Label "materializer recovery runtime"

    $automaticTransactions = New-Object System.Collections.Generic.List[object]
    $hasNonAutomaticOrUnclassifiedTransaction = $false
    foreach ($transactionDirectory in @(Get-ChildItem -LiteralPath $runtimeRoot -Force -Directory | Sort-Object Name)) {
        if ([string]::Equals($transactionDirectory.Name, $script:HostUseLeaseDirectoryName, [StringComparison]::Ordinal) -or
            [string]::Equals($transactionDirectory.Name, $script:TrackedHostAuthorizationDirectoryName, [StringComparison]::Ordinal)) {
            continue
        }
        if ($transactionDirectory.Name -notmatch '^txn-v1-[0-9a-f]{12}$') {
            throw "Unknown materializer recovery artifact requires manual review: $($transactionDirectory.FullName)"
        }
        Assert-NoReparsePoint -Path $transactionDirectory.FullName -Root $runtimeRoot -Label "pending materializer transaction"
        $journalPath = Join-Path $transactionDirectory.FullName $script:TransactionJournalName
        if (-not (Test-Path -LiteralPath $journalPath)) {
            $hasNonAutomaticOrUnclassifiedTransaction = $true
            continue
        }
        if (-not (Test-Path -LiteralPath $journalPath -PathType Leaf)) {
            throw "Pending transaction journal is not a file: $journalPath"
        }
        Assert-NoReparsePoint -Path $journalPath -Root $transactionDirectory.FullName -Label "pending transaction journal"
        $journalInfo = Get-Item -LiteralPath $journalPath -Force
        if ($journalInfo.Length -le 0 -or $journalInfo.Length -gt (1024 * 1024)) {
            throw "Pending transaction journal has an invalid size: $journalPath"
        }
        $journal = Read-TransactionJournal -TransactionRoot $transactionDirectory.FullName -ProjectRoot $ProjectRoot
        Assert-TransactionRecoveryState -Entries $journal.Entries
        if (-not $journal.AutomaticUpgrade) {
            $hasNonAutomaticOrUnclassifiedTransaction = $true
            continue
        }
        $automaticTransactions.Add([pscustomobject]@{
            Id = $transactionDirectory.Name
            Journal = $journal
        })
    }

    if ($hasNonAutomaticOrUnclassifiedTransaction -or $automaticTransactions.Count -eq 0) {
        return $notPending
    }
    if ($automaticTransactions.Count -ne 1) {
        throw "Multiple pending automatic-upgrade transactions require manual review."
    }
    $activeMarkerPath = Join-Path $runtimeRoot $script:ActiveMarkerName
    Assert-PendingAutomaticUpgradeMarker -MarkerPath $activeMarkerPath -ProjectRoot $ProjectRoot
    Assert-PendingAutomaticUpgradeJournalIdentity `
        -Journal $automaticTransactions[0].Journal `
        -Manifest $Manifest `
        -ProjectRoot $ProjectRoot
    return [pscustomobject]@{
        Pending = $true
        TransactionId = $automaticTransactions[0].Id
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
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
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
            $hostRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host" -Label "host generation runtime"
            Remove-EmptyManagedParents -Paths $createdPaths -TargetRoot $hostRuntimeRoot
        }
    }
    return $errors.ToArray()
}

function Invoke-PendingTransactionRecovery {
    param(
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [switch]$AutomaticOnly,
        [switch]$SkipAutomaticUpgrade
    )

    if ($AutomaticOnly -and $SkipAutomaticUpgrade) {
        throw "Pending transaction recovery filters are mutually exclusive."
    }
    $recoveredAutomaticUpgrade = $false
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
            if (($AutomaticOnly -and -not $journal.AutomaticUpgrade) -or
                ($SkipAutomaticUpgrade -and $journal.AutomaticUpgrade)) {
                continue
            }
            if ($journal.AutomaticUpgrade) {
                Publish-MaterializerUpgradeState -Lock $Lock -ProjectRoot $ProjectRoot -State "ROLLBACK" -Message "Recovering an interrupted automatic host upgrade."
            }
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
            $rollbackErrors = @(Restore-Transaction -Entries $journal.Entries -TransactionRoot $transactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
            if ($rollbackErrors.Count -gt 0) {
                throw $rollbackErrors -join '; '
            }
            if ($journal.AutomaticUpgrade) {
                $rollbackWatcherManager = Resolve-RollbackWatcherManager `
                    -ProjectRoot $ProjectRoot `
                    -RecordedWatchManagerPath $journal.PreviousWatcherManagerPath `
                    -RecordedWatchManagerSha256 $journal.PreviousWatcherManagerSha256
                Invoke-UpgradeWatcherRestore -WatchManagerPath $rollbackWatcherManager -Lock $Lock -ProjectRoot $ProjectRoot
                if (-not $Lock.ActiveMarkerPublished) {
                    Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot
                }
                Publish-MaterializerUpgradeState -Lock $Lock -ProjectRoot $ProjectRoot -State "CHECK_FAILED" -Message "Interrupted upgrade was rolled back to the last known-good selection."
                $recoveredAutomaticUpgrade = $true
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
    return $recoveredAutomaticUpgrade
}

function Remove-EmptyManagedParents {
    param(
        [Parameter(Mandatory = $true)][string[]]$Paths,
        [Parameter(Mandatory = $true)][string]$TargetRoot
    )

    $fullTargetRoot = [System.IO.Path]::GetFullPath($TargetRoot).TrimEnd('\', '/')
    $parents = @($Paths | ForEach-Object { Split-Path -Parent $_ } | Sort-Object -Unique | Sort-Object Length -Descending)
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

function Assert-GenerationDirectoryMatchesManifest {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$GenerationRoot,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [switch]$SkipSyntaxValidation
    )

    if (-not (Test-Path -LiteralPath $GenerationRoot -PathType Container)) {
        throw "Immutable generation directory does not exist: $GenerationRoot"
    }
    Assert-NoReparsePoint -Path $GenerationRoot -Root $ProjectRoot -Label "immutable generation"
    $expected = @{}
    foreach ($file in @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
    })) {
        $relativePath = $file.Target.Substring($script:GenerationTargetPrefix.Length)
        $relativePath = ConvertTo-SafeRelativePath -Path $relativePath -Label "immutable generation file"
        $expected[$relativePath] = $file
        $candidatePath = ConvertTo-AbsoluteChildPath -Root $GenerationRoot -RelativePath $relativePath -Label "immutable generation file"
        if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
            throw "Immutable generation file is missing: $relativePath"
        }
        Assert-NoReparsePoint -Path $candidatePath -Root $GenerationRoot -Label "immutable generation file"
        if (-not [string]::Equals((Get-FileSha256 -Path $candidatePath), $file.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Immutable generation file hash mismatch: $relativePath"
        }
    }

    $actualFiles = @()
    foreach ($item in @(Get-ChildItem -LiteralPath $GenerationRoot -Force -Recurse)) {
        Assert-NoReparsePoint -Path $item.FullName -Root $GenerationRoot -Label "immutable generation content"
        if ($item.PSIsContainer) {
            continue
        }
        $relativePath = $item.FullName.Substring($GenerationRoot.TrimEnd('\', '/').Length + 1).Replace('\', '/')
        $actualFiles += $relativePath
        if (-not $expected.ContainsKey($relativePath)) {
            throw "Immutable generation contains an unmanifested file: $relativePath"
        }
    }
    if ($actualFiles.Count -ne $expected.Count) {
        throw "Immutable generation file closure is incomplete."
    }

    if (-not $SkipSyntaxValidation) {
        $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
        if ($null -eq $nodeCommand) {
            throw "Node.js is required to validate the CodeDB generation coordinator."
        }
        $coordinatorPath = Join-Path $GenerationRoot "coordinator\codedb-watch-coordinator.mjs"
        $global:LASTEXITCODE = 0
        $nodeOutput = @(& $nodeCommand.Source --check $coordinatorPath 2>&1)
        if ($LASTEXITCODE -ne 0) {
            throw "Generation coordinator syntax validation failed: $($nodeOutput -join ' ')"
        }
        foreach ($scriptPath in @(Get-ChildItem -LiteralPath (Join-Path $GenerationRoot "scripts") -File -Filter "*.ps1" -ErrorAction Stop)) {
            $tokens = $null
            $parseErrors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath.FullName, [ref]$tokens, [ref]$parseErrors)
            if (@($parseErrors).Count -gt 0) {
                throw "Generation PowerShell syntax validation failed for $($scriptPath.Name): $($parseErrors[0].Message)"
            }
        }
    }
}

function Publish-ImmutableGeneration {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TransactionRoot
    )

    $generationRoot = ConvertTo-AbsoluteChildPath `
        -Root $ProjectRoot `
        -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') `
        -Label "immutable generation"
    if (Test-Path -LiteralPath $generationRoot) {
        Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $generationRoot -ProjectRoot $ProjectRoot
        Write-Host "[INSTALLING] Reusing the complete immutable generation $($Manifest.GenerationId)."
        return $generationRoot
    }

    $stagedGenerationRoot = Join-Path $TransactionRoot "generation-stage\$($Manifest.GenerationId)"
    New-Item -ItemType Directory -Force -Path $stagedGenerationRoot | Out-Null
    foreach ($file in @($Manifest.Files | Where-Object {
        $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
    })) {
        $relativePath = $file.Target.Substring($script:GenerationTargetPrefix.Length)
        $stagePath = ConvertTo-AbsoluteChildPath -Root $stagedGenerationRoot -RelativePath $relativePath -Label "staged generation file"
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $stagePath) | Out-Null
        Copy-Item -LiteralPath $file.SourcePath -Destination $stagePath
    }
    Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $stagedGenerationRoot -ProjectRoot $TransactionRoot

    $generationParent = Split-Path -Parent $generationRoot
    Assert-NoReparsePoint -Path $generationParent -Root $ProjectRoot -Label "generation publication root"
    New-Item -ItemType Directory -Force -Path $generationParent | Out-Null
    Assert-NoReparsePoint -Path $generationParent -Root $ProjectRoot -Label "generation publication root"
    [System.IO.Directory]::Move($stagedGenerationRoot, $generationRoot)
    Invoke-TestFaultAfterMutation
    Assert-GenerationDirectoryMatchesManifest -Manifest $Manifest -GenerationRoot $generationRoot -ProjectRoot $ProjectRoot
    Write-Host "[INSTALLING] Published immutable generation $($Manifest.GenerationId)."
    return $generationRoot
}

function Get-ValidatedInstalledGenerationPointer {
    param(
        [Parameter(Mandatory = $true)][string]$PointerPath,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath $PointerPath -PathType Leaf)) {
        return $null
    }
    Assert-NoReparsePoint -Path $PointerPath -Root $ProjectRoot -Label "installed generation pointer"
    $pointerJson = Read-BoundedJsonDocument -Path $PointerPath -Label "installed generation pointer" -MaximumBytes (64 * 1024)
    $pointer = $pointerJson.Document
    $generationId = [string](Get-RequiredProperty -Object $pointer -Name "generation_id" -Label "installed generation pointer")
    $generationRelativePath = ConvertTo-SafeRelativePath `
        -Path ([string](Get-RequiredProperty -Object $pointer -Name "generation_relative_path" -Label "installed generation pointer")) `
        -Label "installed generation path"
    $manifestSha256 = ([string](Get-RequiredProperty -Object $pointer -Name "generation_manifest_sha256" -Label "installed generation pointer")).ToLowerInvariant()
    $pointerBootstrapProtocol = [int](Get-RequiredProperty -Object $pointer -Name "bootstrap_protocol" -Label "installed generation pointer")
    $expectedRelativePath = "AIWork/.runtime/codedb/host/generations/$generationId"
    if ([int](Get-RequiredProperty -Object $pointer -Name "schema_version" -Label "installed generation pointer") -ne 1 -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $pointer -Name "managed_by" -Label "installed generation pointer"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        $generationId -notmatch '^[A-Za-z0-9._-]{1,64}$' -or
        -not [string]::Equals($generationRelativePath, $expectedRelativePath, [StringComparison]::Ordinal) -or
        $manifestSha256 -notmatch '^[0-9a-f]{64}$' -or
        $pointerBootstrapProtocol -lt 1 -or
        $pointerBootstrapProtocol -gt $script:BootstrapProtocol) {
        throw "Installed generation pointer identity is invalid."
    }

    $generationRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $generationRelativePath -Label "installed generation"
    Assert-NoReparsePoint -Path $generationRoot -Root $ProjectRoot -Label "installed generation"
    $generationManifestPath = Join-Path $generationRoot "generation-manifest.json"
    $generationJson = Read-BoundedJsonDocument -Path $generationManifestPath -Label "installed generation manifest" -MaximumBytes (1024 * 1024)
    if (-not [string]::Equals((Get-FileSha256 -Path $generationManifestPath), $manifestSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Installed generation manifest hash does not match its pointer."
    }
    $generation = $generationJson.Document
    $generationFiles = @(Get-RequiredProperty -Object $generation -Name "files" -Label "installed generation manifest")
    if ([int](Get-RequiredProperty -Object $generation -Name "schema_version" -Label "installed generation manifest") -ne 1 -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "managed_by" -Label "installed generation manifest"), $script:ManagedBy, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "generation_id" -Label "installed generation manifest"), $generationId, [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "package_version" -Label "installed generation manifest"), [string](Get-RequiredProperty -Object $pointer -Name "package_version" -Label "installed generation pointer"), [StringComparison]::Ordinal) -or
        -not [string]::Equals([string](Get-RequiredProperty -Object $generation -Name "payload_version" -Label "installed generation manifest"), [string](Get-RequiredProperty -Object $pointer -Name "payload_version" -Label "installed generation pointer"), [StringComparison]::Ordinal) -or
        [int](Get-RequiredProperty -Object $generation -Name "payload_sequence" -Label "installed generation manifest") -ne [int](Get-RequiredProperty -Object $pointer -Name "payload_sequence" -Label "installed generation pointer") -or
        [int](Get-RequiredProperty -Object $generation -Name "bootstrap_protocol" -Label "installed generation manifest") -ne $pointerBootstrapProtocol -or
        $generationFiles.Count -eq 0) {
        throw "Installed generation manifest identity does not match its pointer."
    }

    $seen = @{}
    $managedFiles = New-Object System.Collections.Generic.List[object]
    $managedFiles.Add([pscustomobject]@{ Path = $generationManifestPath; Sha256 = $manifestSha256 })
    foreach ($entry in $generationFiles) {
        $relativePath = ConvertTo-SafeRelativePath -Path ([string](Get-RequiredProperty -Object $entry -Name "path" -Label "installed generation file")) -Label "installed generation file"
        $sha256 = ([string](Get-RequiredProperty -Object $entry -Name "sha256" -Label "installed generation file")).ToLowerInvariant()
        if ($sha256 -notmatch '^[0-9a-f]{64}$' -or $seen.ContainsKey($relativePath)) {
            throw "Installed generation manifest contains an invalid or duplicate file: $relativePath"
        }
        $seen[$relativePath] = $true
        $filePath = ConvertTo-AbsoluteChildPath -Root $generationRoot -RelativePath $relativePath -Label "installed generation file"
        Assert-NoReparsePoint -Path $filePath -Root $generationRoot -Label "installed generation file"
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf) -or
            -not [string]::Equals((Get-FileSha256 -Path $filePath), $sha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Installed generation file is missing or has drifted: $relativePath"
        }
        $managedFiles.Add([pscustomobject]@{ Path = $filePath; Sha256 = $sha256 })
    }
    $actualFiles = @(Get-ChildItem -LiteralPath $generationRoot -Force -Recurse -File)
    foreach ($actualFile in $actualFiles) {
        Assert-NoReparsePoint -Path $actualFile.FullName -Root $generationRoot -Label "installed generation content"
        $relativePath = $actualFile.FullName.Substring($generationRoot.TrimEnd('\', '/').Length + 1).Replace('\', '/')
        if (-not [string]::Equals($relativePath, "generation-manifest.json", [StringComparison]::OrdinalIgnoreCase) -and
            -not $seen.ContainsKey($relativePath)) {
            throw "Installed generation contains an unmanifested file: $relativePath"
        }
    }
    if ($actualFiles.Count -ne $managedFiles.Count) {
        throw "Installed generation file closure is incomplete."
    }

    return [pscustomobject]@{
        Text = $pointerJson.Text
        Document = $pointer
        GenerationId = $generationId
        BootstrapProtocol = $pointerBootstrapProtocol
        GenerationRoot = $generationRoot
        WatchManagerPath = Join-Path $generationRoot "scripts\manage-codedb-project-watch.ps1"
        ManagedFiles = $managedFiles.ToArray()
    }
}

function Save-LastKnownGoodPointer {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TransactionRoot
    )

    $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "current generation pointer"
    $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
    if ($null -eq $current) {
        return $null
    }
    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
    Assert-NoReparsePoint -Path $lastKnownGoodPath -Root $ProjectRoot -Label "last-known-good generation pointer"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $lastKnownGoodPath) | Out-Null
    $stagePath = Join-Path $TransactionRoot "last-known-good.pointer"
    Write-DurableUtf8File -Path $stagePath -Content $current.Text
    Publish-TransactionFile -StagePath $stagePath -TargetPath $lastKnownGoodPath
    if (-not [string]::Equals((Get-FileSha256 -Path $lastKnownGoodPath), (Get-FileSha256 -Path $currentPointerPath), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Last-known-good generation pointer publication failed verification."
    }
    Write-Host "[INSTALLING] Retained generation $($current.GenerationId) as last known good."
    return $current
}

function Resolve-RollbackWatcherManager {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$RecordedWatchManagerPath,
        [Parameter(Mandatory = $true)][string]$RecordedWatchManagerSha256
    )

    $recordedPath = [System.IO.Path]::GetFullPath($RecordedWatchManagerPath)
    Assert-PathInside -Path $recordedPath -Root $ProjectRoot -Label "rollback watcher manager"
    Assert-NoReparsePoint -Path $recordedPath -Root $ProjectRoot -Label "rollback watcher manager"
    if ($RecordedWatchManagerSha256 -notmatch '^[0-9a-fA-F]{64}$' -or
        -not (Test-Path -LiteralPath $recordedPath -PathType Leaf) -or
        -not [string]::Equals((Get-FileSha256 -Path $recordedPath), $RecordedWatchManagerSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Rollback watcher manager no longer matches its transaction identity."
    }
    $normalizedPath = $recordedPath.Replace('\', '/')
    $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "rollback current pointer"
    $isGenerationManager = $normalizedPath.IndexOf('/AIWork/.runtime/codedb/host/generations/', [StringComparison]::OrdinalIgnoreCase) -ge 0
    if (-not $isGenerationManager) {
        $expectedLegacyPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1" -Label "legacy rollback watcher manager"
        if (-not [string]::Equals($recordedPath, $expectedLegacyPath, [StringComparison]::OrdinalIgnoreCase) -or
            (Test-Path -LiteralPath $currentPointerPath)) {
            throw "Legacy rollback selection does not match the restored flat host layout."
        }
        $markerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:MarkerRelativePath -Label "restored payload marker"
        $marker = Read-InstalledMarker -MarkerPath $markerPath -ProjectRoot $ProjectRoot
        $managerTarget = "AIWork/codedb/scripts/manage-codedb-project-watch.ps1"
        if ($null -eq $marker -or -not $marker.Map.ContainsKey($managerTarget) -or
            -not [string]::Equals($marker.Map[$managerTarget].InstalledSha256, $RecordedWatchManagerSha256, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Restored legacy marker does not own the recorded rollback watcher manager."
        }
        return $expectedLegacyPath
    }

    $current = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
    if ($null -eq $current -or
        -not [string]::Equals([System.IO.Path]::GetFullPath($current.WatchManagerPath), $recordedPath, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Restored current.json does not select the recorded rollback watcher generation."
    }
    $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
    $lastKnownGood = Get-ValidatedInstalledGenerationPointer -PointerPath $lastKnownGoodPath -ProjectRoot $ProjectRoot
    if ($null -eq $lastKnownGood -or
        -not [string]::Equals([System.IO.Path]::GetFullPath($lastKnownGood.WatchManagerPath), $recordedPath, [StringComparison]::OrdinalIgnoreCase) -or
        -not [string]::Equals((Get-FileSha256 -Path $lastKnownGoodPath), (Get-FileSha256 -Path $currentPointerPath), [StringComparison]::OrdinalIgnoreCase)) {
        throw "Last-known-good pointer does not match the restored current generation."
    }
    return $recordedPath
}

function Get-LegacyWatchManagerPath {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $path = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/codedb/scripts/manage-codedb-project-watch.ps1" -Label "legacy watch manager"
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Assert-NoReparsePoint -Path $path -Root $ProjectRoot -Label "legacy watch manager"
        return $path
    }
    return $null
}

function Invoke-UpgradeWatcherEnsure {
    param(
        [AllowNull()][string]$WatchManagerPath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($PocFixture) {
        if ($TestFailWatcherHandoff) {
            throw "Injected POC watcher readiness failure."
        }
        return
    }
    if ([string]::IsNullOrWhiteSpace($WatchManagerPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $WatchManagerPath -PathType Leaf)) {
        throw "$Label watch manager is missing: $WatchManagerPath"
    }
    Write-Host "[SWITCHING] Reconciling $Label watcher ownership."
    & $WatchManagerPath -Action Ensure -MaterializerHandoff
}

function Invoke-UpgradeWatcherRestore {
    param(
        [AllowNull()][string]$WatchManagerPath,
        [Parameter(Mandatory = $true)]$Lock,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if ($PocFixture -or [string]::IsNullOrWhiteSpace($WatchManagerPath)) {
        return
    }
    if (-not (Test-Path -LiteralPath $WatchManagerPath -PathType Leaf)) {
        throw "Last-known-good watch manager is missing: $WatchManagerPath"
    }
    $normalizedPath = [System.IO.Path]::GetFullPath($WatchManagerPath).Replace('\', '/')
    if ($normalizedPath.IndexOf('/AIWork/.runtime/codedb/host/generations/', [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        # Ensure detects a generation mismatch and performs the handoff without
        # creating the session-level manual-start override used by Restart.
        Write-Host "[ROLLBACK] Reconciling the last-known-good generation watcher."
        $callerAction = $Action.ToLowerInvariant()
        if (-not [string]::Equals($callerAction, "upgrade", [StringComparison]::Ordinal)) {
            # Recovery of an interrupted automatic upgrade is itself an upgrade
            # handoff, even when a later mutation discovered the journal.
            Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot -MarkerAction "upgrade"
        }
        try {
            & $WatchManagerPath -Action Ensure -MaterializerHandoff
        } finally {
            if (-not [string]::Equals($callerAction, "upgrade", [StringComparison]::Ordinal) -and
                (Test-Path -LiteralPath $Lock.ActiveMarkerPath -PathType Leaf)) {
                Publish-MaterializerActiveMarker -Lock $Lock -ProjectRoot $ProjectRoot -MarkerAction $callerAction
            }
        }
        return
    }

    # poc.21 has no Restart action. An explicit Stop is required because its
    # Ensure command can otherwise attach to a ready compatibility coordinator.
    Write-Host "[ROLLBACK] Stopping the selected coordinator before restoring the legacy watcher."
    & $WatchManagerPath -Action Stop
    if ($Lock.ActiveMarkerPublished -and (Test-Path -LiteralPath $Lock.ActiveMarkerPath -PathType Leaf)) {
        # The legacy gate blocks every active marker. File rollback is already
        # complete here, and the project materializer lock still excludes a
        # competing mutation while the old watcher reacquires its lease.
        Remove-Item -LiteralPath $Lock.ActiveMarkerPath -Force
        $Lock.ActiveMarkerPublished = $false
    }
    & $WatchManagerPath -Action Ensure
}

function Invoke-Sync {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$TargetRoot,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [switch]$AutomaticUpgrade
    )

    $lock = $null
    $transactionRoot = $null
    $keepTransaction = $false
    $entries = $null
    $previousWatcherManager = $null
    $previousWatcherManagerSha256 = $null
    $watcherHandoffAttempted = $false
    $upgradeMutationStarted = $false
    try {
        $lock = Enter-MaterializerLock -ProjectRoot $ProjectRoot
        if ($AutomaticUpgrade) {
            Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot
            $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot
        } else {
            Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot
            $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -AutomaticOnly
            Complete-MaterializerHostUseGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
            $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -SkipAutomaticUpgrade
        }
        $plan = Get-MaterializationPlan -Manifest $Manifest -MarkerPath $MarkerPath -ProjectRoot $ProjectRoot
        Write-MaterializationPlan -Plan $plan
        if ($plan.HasConflict) {
            Throw-MaterializerError -Message "Payload sync was rejected because one or more targets conflict." -ExitCode 3
        }
        if ($plan.IsCurrent) {
            Write-Host "[OK] Host payload is already current; no files were written."
            return
        }
        if ($AutomaticUpgrade) {
            $eligibility = Get-AutomaticUpgradeEligibility -Manifest $Manifest -Plan $plan
            if (-not $eligibility.Eligible) {
                Throw-MaterializerError -Message "Automatic host upgrade was rejected: $($eligibility.Reason)." -ExitCode 4
            }
            Write-Host "[INSTALLING] Installing immutable generation $($Manifest.GenerationId)."
            Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "INSTALLING" -Message "Validating and publishing immutable generation $($Manifest.GenerationId)."
            $currentPointerPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:CurrentPointerRelativePath -Label "current generation pointer"
            $previousGeneration = Get-ValidatedInstalledGenerationPointer -PointerPath $currentPointerPath -ProjectRoot $ProjectRoot
            $previousWatcherManager = if ($null -ne $previousGeneration) {
                $previousGeneration.WatchManagerPath
            } else {
                Get-LegacyWatchManagerPath -ProjectRoot $ProjectRoot
            }
            $previousWatcherManagerSha256 = Get-FileSha256 -Path $previousWatcherManager
        }

        $transactionRoot = Join-Path $lock.Root ($script:TransactionPrefix + [guid]::NewGuid().ToString("N").Substring(0, 12))
        $stageRoot = Join-Path $transactionRoot "stage"
        $backupRoot = Join-Path $transactionRoot "backup"
        New-Item -ItemType Directory -Force -Path $stageRoot, $backupRoot | Out-Null
        $entries = New-Object System.Collections.Generic.List[object]

        if ($AutomaticUpgrade) {
            $upgradeMutationStarted = $true
            $null = Publish-ImmutableGeneration -Manifest $Manifest -ProjectRoot $ProjectRoot -TransactionRoot $transactionRoot
            $null = Save-LastKnownGoodPointer -ProjectRoot $ProjectRoot -TransactionRoot $transactionRoot
            Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "SWITCHING" -Message "Publishing current.json and reconciling watcher ownership."
        }

        $orderedFiles = @($plan.Files | Sort-Object `
            @{ Expression = {
                if ($AutomaticUpgrade -and [string]::Equals($_.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) { 0 }
                elseif ($AutomaticUpgrade -and [string]::Equals($_.Target, "AIWork/codedb/wrapper/codedb-project-wrapper.mjs", [StringComparison]::OrdinalIgnoreCase)) { 1 }
                elseif ([string]::Equals($_.Target, $script:CurrentPointerRelativePath, [StringComparison]::OrdinalIgnoreCase)) { 3 }
                else { 2 }
            } }, `
            Target)
        foreach ($item in $orderedFiles) {
            if ($AutomaticUpgrade -and $item.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
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
            if ($AutomaticUpgrade -and $item.Target -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/') {
                Write-Host "[DRAINING] Retaining retired immutable generation content until lease and rollback retention permit cleanup: $($item.Target)"
                continue
            }
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
        Write-TransactionJournal `
            -Operation "Sync" `
            -TransactionRoot $transactionRoot `
            -Entries $entries.ToArray() `
            -AutomaticUpgrade:$AutomaticUpgrade `
            -PreviousWatcherManagerPath $previousWatcherManager `
            -ProjectRoot $ProjectRoot
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
        if ($AutomaticUpgrade -and $TestCrashBeforeWatcherHandoff) {
            Write-Host "Injected POC process crash after post-plan current and before watcher handoff."
            [Environment]::Exit(86)
        }
        $removedRetiredPaths = @($plan.Retired | Where-Object {
            -not ($AutomaticUpgrade -and $_.Target -match '^AIWork/\.runtime/codedb/host/generations/[A-Za-z0-9._-]{1,64}/')
        } | ForEach-Object { $_.TargetPath })
        if ($removedRetiredPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $removedRetiredPaths -TargetRoot $TargetRoot
        }
        if ($AutomaticUpgrade) {
            Write-Host "[SWITCHING] Published current generation pointer for $($Manifest.GenerationId)."
            $newWatcherManager = Join-Path `
                (ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') -Label "selected generation") `
                "scripts\manage-codedb-project-watch.ps1"
            $watcherHandoffAttempted = $true
            Invoke-UpgradeWatcherEnsure -WatchManagerPath $newWatcherManager -Label "selected generation"
            Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "CURRENT" -Message "Generation $($Manifest.GenerationId) is selected and watcher reconciliation succeeded."
            Write-Host "[OK] Host payload automatically upgraded to version $($Manifest.PayloadVersion)."
        } else {
            Write-Host "[OK] Host payload synchronized to version $($Manifest.PayloadVersion)."
        }
    } catch {
        $originalError = $_.Exception
        if ($AutomaticUpgrade -and $null -ne $lock -and $upgradeMutationStarted) {
            try {
                Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "ROLLBACK" -Message $originalError.Message
                Write-Host "[ROLLBACK] Restoring the last known-good host selection."
            } catch {
                Write-Warning "Could not publish CodeDB rollback state: $($_.Exception.Message)"
            }
        }
        $rollbackErrors = @()
        if ($null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
        }
        if ($AutomaticUpgrade -and $watcherHandoffAttempted -and $rollbackErrors.Count -eq 0) {
            try {
                Write-Host "[ROLLBACK] Restoring the previous watcher selection."
                $rollbackWatcherManager = Resolve-RollbackWatcherManager `
                    -ProjectRoot $ProjectRoot `
                    -RecordedWatchManagerPath $previousWatcherManager `
                    -RecordedWatchManagerSha256 $previousWatcherManagerSha256
                Invoke-UpgradeWatcherRestore -WatchManagerPath $rollbackWatcherManager -Lock $lock -ProjectRoot $ProjectRoot
            } catch {
                $rollbackErrors += "restore watcher: $($_.Exception.Message)"
            }
        }
        if ($rollbackErrors.Count -gt 0) {
            if ($AutomaticUpgrade -and $null -ne $lock) {
                try {
                    Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "CHECK_FAILED" -Message ($rollbackErrors -join '; ')
                } catch {
                    Write-Warning "Could not publish CodeDB failed upgrade state: $($_.Exception.Message)"
                }
            }
            $keepTransaction = $true
            Throw-MaterializerError -Message "Payload sync failed and rollback was incomplete. $($rollbackErrors -join '; ') Transaction: $transactionRoot" -ExitCode 7
        }
        if ($AutomaticUpgrade -and $null -ne $lock) {
            try {
                Publish-MaterializerUpgradeState -Lock $lock -ProjectRoot $ProjectRoot -State "CHECK_FAILED" -Message $originalError.Message
            } catch {
                Write-Warning "Could not publish CodeDB failed upgrade state: $($_.Exception.Message)"
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
        Initialize-MaterializerUpgradeGate -Lock $lock -ProjectRoot $ProjectRoot
        $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -AutomaticOnly
        Complete-MaterializerHostUseGate -Lock $lock -ProjectRoot $ProjectRoot -MarkerPath $MarkerPath
        $null = Invoke-PendingTransactionRecovery -Lock $lock -ProjectRoot $ProjectRoot -TargetRoot $TargetRoot -SkipAutomaticUpgrade
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

        $extraRemovalTargets = New-Object System.Collections.Generic.List[object]
        $removalTargetMap = @{}
        foreach ($item in $marker.Files) {
            $removalTargetMap[$item.Target] = $true
        }
        $candidateGenerationRoot = ConvertTo-AbsoluteChildPath `
            -Root $ProjectRoot `
            -RelativePath $script:GenerationTargetPrefix.TrimEnd('/') `
            -Label "package generation candidate"
        if (Test-Path -LiteralPath $candidateGenerationRoot) {
            # A failed automatic handoff can leave a complete but unselected
            # package generation beside the restored legacy installation.
            Assert-GenerationDirectoryMatchesManifest `
                -Manifest $Manifest `
                -GenerationRoot $candidateGenerationRoot `
                -ProjectRoot $ProjectRoot `
                -SkipSyntaxValidation
            foreach ($managedFile in @($Manifest.Files | Where-Object {
                $_.Target.StartsWith($script:GenerationTargetPrefix, [StringComparison]::OrdinalIgnoreCase)
            })) {
                if (-not $removalTargetMap.ContainsKey($managedFile.Target)) {
                    $extraRemovalTargets.Add([pscustomobject]@{ Target = $managedFile.Target; TargetPath = $managedFile.TargetPath })
                    $removalTargetMap[$managedFile.Target] = $true
                }
            }
        }
        $lastKnownGoodPath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:LastKnownGoodPointerRelativePath -Label "last-known-good generation pointer"
        if (Test-Path -LiteralPath $lastKnownGoodPath) {
            $lastKnownGood = Get-ValidatedInstalledGenerationPointer -PointerPath $lastKnownGoodPath -ProjectRoot $ProjectRoot
            foreach ($managedFile in $lastKnownGood.ManagedFiles) {
                $relativePath = $managedFile.Path.Substring([System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/').Length + 1).Replace('\', '/')
                $relativePath = Assert-TargetRelativePath -Path $relativePath
                if (-not $removalTargetMap.ContainsKey($relativePath)) {
                    $extraRemovalTargets.Add([pscustomobject]@{ Target = $relativePath; TargetPath = $managedFile.Path })
                    $removalTargetMap[$relativePath] = $true
                }
            }
            $extraRemovalTargets.Add([pscustomobject]@{ Target = $script:LastKnownGoodPointerRelativePath; TargetPath = $lastKnownGoodPath })
            $removalTargetMap[$script:LastKnownGoodPointerRelativePath] = $true
        }
        $upgradeStatePath = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath $script:UpgradeStateRelativePath -Label "materializer upgrade state"
        if (Test-Path -LiteralPath $upgradeStatePath) {
            Assert-MaterializerUpgradeStateArtifact -Path $upgradeStatePath -ProjectRoot $ProjectRoot
            $extraRemovalTargets.Add([pscustomobject]@{ Target = $script:UpgradeStateRelativePath; TargetPath = $upgradeStatePath })
            $removalTargetMap[$script:UpgradeStateRelativePath] = $true
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
        foreach ($item in @($extraRemovalTargets | Sort-Object Target)) {
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
        $flatRemovedPaths = @($marker.Files | Where-Object {
            $_.Target.StartsWith("AIWork/codedb/", [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object { $_.TargetPath })
        if ($flatRemovedPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $flatRemovedPaths -TargetRoot $TargetRoot
        }
        $hostRuntimeRoot = ConvertTo-AbsoluteChildPath -Root $ProjectRoot -RelativePath "AIWork/.runtime/codedb/host" -Label "host generation runtime"
        $runtimeRemovedPaths = @($marker.Files | Where-Object {
            $_.Target.StartsWith("AIWork/.runtime/codedb/host/", [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object { $_.TargetPath }) + @($extraRemovalTargets | Where-Object {
            $_.Target.StartsWith("AIWork/.runtime/codedb/host/", [StringComparison]::OrdinalIgnoreCase)
        } | ForEach-Object { $_.TargetPath })
        if ($runtimeRemovedPaths.Count -gt 0) {
            Remove-EmptyManagedParents -Paths $runtimeRemovedPaths -TargetRoot $hostRuntimeRoot
        }
        $generationLeaseRoot = Join-Path $hostRuntimeRoot "leases"
        if (Test-Path -LiteralPath $generationLeaseRoot -PathType Container) {
            foreach ($generationLeaseDirectory in @(Get-ChildItem -LiteralPath $generationLeaseRoot -Force -Directory)) {
                if (@(Get-ChildItem -LiteralPath $generationLeaseDirectory.FullName -Force).Count -eq 0) {
                    Remove-Item -LiteralPath $generationLeaseDirectory.FullName -Force
                }
            }
            if (@(Get-ChildItem -LiteralPath $generationLeaseRoot -Force).Count -eq 0) {
                Remove-Item -LiteralPath $generationLeaseRoot -Force
            }
        }
        if ((Test-Path -LiteralPath $hostRuntimeRoot -PathType Container) -and
            @(Get-ChildItem -LiteralPath $hostRuntimeRoot -Force).Count -eq 0) {
            Remove-Item -LiteralPath $hostRuntimeRoot -Force
        }
        Write-Host "[OK] Managed host payload was removed; unrelated host files were preserved."
    } catch {
        $originalError = $_.Exception
        if ($null -ne $transactionRoot -and $null -ne $entries -and $entries.Count -gt 0) {
            $rollbackErrors = @(Restore-Transaction -Entries $entries.ToArray() -TransactionRoot $transactionRoot -TargetRoot $TargetRoot -ProjectRoot $ProjectRoot)
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
    $requestedTestFaultCount = 0
    if ($TestFailAfterMutation -gt 0) { $requestedTestFaultCount += 1 }
    if ($TestCrashAfterMutation -gt 0) { $requestedTestFaultCount += 1 }
    if ($TestFailWatcherHandoff) { $requestedTestFaultCount += 1 }
    if ($TestCrashBeforeWatcherHandoff) { $requestedTestFaultCount += 1 }
    if ($requestedTestFaultCount -gt 1) {
        Throw-MaterializerError -Message "Only one materializer test fault may be requested at a time." -ExitCode 2
    }
    if ($TestFailWatcherHandoff -and (-not $PocFixture -or $Action -ne "Upgrade")) {
        Throw-MaterializerError -Message "Watcher handoff fault injection requires a fixture-only Upgrade action." -ExitCode 4
    }
    if ($TestCrashBeforeWatcherHandoff -and (-not $PocFixture -or $Action -ne "Upgrade")) {
        Throw-MaterializerError -Message "Pre-handoff crash injection requires a fixture-only Upgrade action." -ExitCode 4
    }
    if (($TestFailAfterMutation -gt 0 -or $TestCrashAfterMutation -gt 0) -and
        (-not $PocFixture -or $Action -notin @("Upgrade", "Sync", "Remove"))) {
        Throw-MaterializerError -Message "Materializer test faults require a fixture-only Upgrade, Sync, or Remove action." -ExitCode 4
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
            $upgradeEligibility = Get-AutomaticUpgradeEligibility -Manifest $payload -Plan $plan
            $pendingAutomaticRecovery = if ($plan.IsCurrent) {
                Get-PendingAutomaticUpgradeRecovery -Manifest $payload -ProjectRoot $projectRootPath
            } else {
                [pscustomobject]@{ Pending = $false; TransactionId = $null }
            }
            Write-HostUseLeaseGuidance -ProjectRoot $projectRootPath
            if ($pendingAutomaticRecovery.Pending) {
                Write-Host "[UPGRADE_READY] Interrupted automatic host upgrade $($pendingAutomaticRecovery.TransactionId) requires recovery before watcher handoff."
                Write-Host "[STALE] Host payload files are current but automatic upgrade recovery is pending."
            } elseif ($plan.IsCurrent) {
                Write-Host "[OK] Host payload is current."
            } elseif ($upgradeEligibility.Eligible) {
                $installedGeneration = [string]$plan.Marker.GenerationId
                $installedIdentity = if ($installedGeneration -match '^[A-Za-z0-9._-]{1,64}$') {
                    "generation $installedGeneration"
                } else {
                    "payload $([string]$plan.Marker.PayloadVersion)"
                }
                Write-Host "[UPGRADE_READY] Owned $installedIdentity can migrate to generation $($payload.GenerationId) while existing leases drain naturally."
                Write-Host "[STALE] Host payload has a safe automatic generation upgrade."
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
        "Upgrade" {
            Invoke-Sync -Manifest $payload -ProjectRoot $projectRootPath -TargetRoot $targetRoot -MarkerPath $markerPath -AutomaticUpgrade
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
