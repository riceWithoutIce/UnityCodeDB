#requires -Version 5.1

Set-StrictMode -Version Latest

function ConvertTo-CodedbProjectSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $builder = [System.Text.StringBuilder]::new()
    $previousWasSeparator = $false
    foreach ($character in $Value.ToCharArray()) {
        if ([char]::IsLetterOrDigit($character)) {
            $null = $builder.Append([char]::ToLowerInvariant($character))
            $previousWasSeparator = $false
            continue
        }

        if ($previousWasSeparator -or $builder.Length -eq 0) {
            continue
        }

        $null = $builder.Append('-')
        $previousWasSeparator = $true
    }

    while ($builder.Length -gt 0 -and $builder[$builder.Length - 1] -eq '-') {
        $builder.Length--
    }

    if ($builder.Length -eq 0) {
        return "unity-project"
    }

    return $builder.ToString()
}

function Get-ProjectCodedbContext {
    param(
        [string]$UnityRoot
    )

    $scriptsRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
    $operationalRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptsRoot ".."))
    if ([string]::IsNullOrWhiteSpace($UnityRoot)) {
        if (-not [string]::IsNullOrWhiteSpace($env:RICE_CODEDB_UNITY_ROOT)) {
            $UnityRoot = $env:RICE_CODEDB_UNITY_ROOT
        } else {
            $workingRoot = [System.IO.Path]::GetFullPath((Get-Location).Path)
            $hasUnityMarkers = (Test-Path -LiteralPath (Join-Path $workingRoot "Assets") -PathType Container) -and
                (Test-Path -LiteralPath (Join-Path $workingRoot "Packages\manifest.json") -PathType Leaf) -and
                (Test-Path -LiteralPath (Join-Path $workingRoot "ProjectSettings\ProjectVersion.txt") -PathType Leaf)
            if (-not $hasUnityMarkers) {
                throw "CodeDB generation scripts require RICE_CODEDB_UNITY_ROOT or a Unity-project working directory."
            }
            $UnityRoot = $workingRoot
        }
    }

    $unityRoot = [System.IO.Path]::GetFullPath($UnityRoot)
    $projectName = Split-Path -Leaf $unityRoot.TrimEnd('\', '/')
    $projectSlug = ConvertTo-CodedbProjectSlug -Value $projectName
    $providerName = "codedb-$projectSlug"
    $repoRoot = $unityRoot
    if (Test-Path -LiteralPath $unityRoot -PathType Container) {
        $gitRoot = @(& git -C $unityRoot rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -eq 0 -and $gitRoot.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$gitRoot[0])) {
            $repoRoot = [System.IO.Path]::GetFullPath([string]$gitRoot[0])
        }
    }
    $bootstrapRoot = Join-Path $unityRoot "AIWork\codedb"
    $runtimeRoot = Join-Path $unityRoot "AIWork\.runtime\codedb"
    $hostRoot = Join-Path $runtimeRoot "host"
    $providerRoot = Join-Path $runtimeRoot $providerName
    $generationId = Split-Path -Leaf $operationalRoot.TrimEnd('\', '/')

    [pscustomobject]@{
        RepoRoot = $repoRoot
        UnityRoot = $unityRoot
        ProjectName = $projectName
        ProjectSlug = $projectSlug
        CodedbRoot = $operationalRoot
        BootstrapRoot = $bootstrapRoot
        HostRoot = $hostRoot
        GenerationId = $generationId
        RuntimeRoot = $runtimeRoot
        ProviderName = $providerName
        ProviderRuntimeRelativePath = "AIWork/.runtime/codedb/$providerName"
        ProviderRoot = $providerRoot
        ProviderBinRoot = Join-Path $providerRoot "bin"
        ProviderConfigRoot = Join-Path $providerRoot "config"
        ProviderIndexRoot = Join-Path $providerRoot "index"
        ProviderLogsRoot = Join-Path $providerRoot "logs"
        ProviderTempRoot = Join-Path $providerRoot "tmp"
        TextAdapterRoot = Join-Path $providerRoot "adapter\text-index"
        TextAdapterLogsRoot = Join-Path $providerRoot "adapter\text-index\logs"
        TextAdapterTempRoot = Join-Path $providerRoot "adapter\text-index\tmp"
        TextAdapterManifestPath = Join-Path $providerRoot "adapter\text-index\manifest.json"
        TextAdapterFilesPath = Join-Path $providerRoot "adapter\text-index\files.jsonl"
        TextAdapterIndexPath = Join-Path $providerRoot "adapter\text-index\index.jsonl"
        WrapperScriptPath = Join-Path $bootstrapRoot "wrapper\codedb-project-wrapper.mjs"
        IgnoreTemplatePath = Join-Path $operationalRoot "codedbignore.example"
        RuntimeConfigTemplatePath = Join-Path $operationalRoot "codedb-mcp.runtime.example.toml"
        GeneratedUnityIgnorePath = Join-Path $unityRoot ".codedbignore"
    }
}

function Assert-CodedbUnityProject {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    $requiredPaths = @(
        (Join-Path $Context.UnityRoot "Assets"),
        (Join-Path $Context.UnityRoot "Packages\manifest.json"),
        (Join-Path $Context.UnityRoot "ProjectSettings\ProjectVersion.txt"),
        $Context.CodedbRoot,
        (Join-Path $Context.CodedbRoot "scripts\codedb-project-common.ps1"),
        $Context.WrapperScriptPath
    )

    foreach ($path in $requiredPaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Unity project CodeDB marker missing: $path"
        }
    }
}

function Assert-CodedbPathInside {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Root,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root)
    $fullRoot = $fullRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )

    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    $isRoot = [string]::Equals($fullPath, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)
    $isInside = $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)

    if (-not ($isRoot -or $isInside)) {
        throw "$Label path is outside expected root. Path: $fullPath Root: $fullRoot"
    }
}

function ConvertTo-CodedbProjectRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Context.UnityRoot)
    $fullRoot = $fullRoot.TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )

    if ([string]::Equals($fullPath, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return "."
    }

    $rootPrefix = $fullRoot + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the host Unity project: $fullPath"
    }

    return $fullPath.Substring($rootPrefix.Length).Replace("\", "/")
}

function New-ProjectCodedbRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    Assert-CodedbPathInside -Path $Context.RuntimeRoot -Root $Context.UnityRoot -Label "codedb runtime"
    Assert-CodedbPathInside -Path $Context.ProviderRoot -Root $Context.RuntimeRoot -Label "provider runtime"

    foreach ($path in @(
        $Context.ProviderBinRoot,
        $Context.ProviderConfigRoot,
        $Context.ProviderIndexRoot,
        $Context.ProviderLogsRoot,
        $Context.ProviderTempRoot
    )) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}

function New-ProjectCodedbTextAdapterRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    Assert-CodedbPathInside -Path $Context.TextAdapterRoot -Root $Context.ProviderRoot -Label "text adapter runtime"

    foreach ($path in @(
        $Context.TextAdapterRoot,
        $Context.TextAdapterLogsRoot,
        $Context.TextAdapterTempRoot
    )) {
        New-Item -ItemType Directory -Force -Path $path | Out-Null
    }
}

function Clear-ProjectCodedbIndex {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    Assert-CodedbPathInside -Path $Context.ProviderIndexRoot -Root $Context.ProviderRoot -Label "provider index"

    $relativeIndex = ConvertTo-CodedbProjectRelativePath -Context $Context -Path $Context.ProviderIndexRoot
    if (-not (Test-Path -LiteralPath $Context.ProviderIndexRoot)) {
        Write-Host "No generated codedb index exists at $relativeIndex."
        return
    }

    if ($PSCmdlet.ShouldProcess($relativeIndex, "Remove generated codedb index data")) {
        Remove-Item -LiteralPath $Context.ProviderIndexRoot -Recurse -Force
        Write-Host "Removed generated codedb index at $relativeIndex."
    }
}

function Get-ProjectCodedbProviderPaths {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    [pscustomobject]@{
        ExecutablePath = Join-Path $Context.ProviderBinRoot "codebase-mcp.exe"
        ConfigPath = Join-Path $Context.ProviderConfigRoot "codedb-mcp.toml"
    }
}

function Assert-ProjectCodedbProviderFiles {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    $providerPaths = Get-ProjectCodedbProviderPaths -Context $Context

    Assert-CodedbPathInside -Path $providerPaths.ExecutablePath -Root $Context.ProviderRoot -Label "provider executable"
    Assert-CodedbPathInside -Path $providerPaths.ConfigPath -Root $Context.ProviderRoot -Label "provider config"

    if (-not (Test-Path -LiteralPath $providerPaths.ExecutablePath)) {
        $relativePath = ConvertTo-CodedbProjectRelativePath -Context $Context -Path $providerPaths.ExecutablePath
        throw "Missing provider executable: $relativePath. Prepare codebase-mcp.exe in ignored runtime before refreshing the index."
    }

    if (-not (Test-Path -LiteralPath $providerPaths.ConfigPath)) {
        $relativePath = ConvertTo-CodedbProjectRelativePath -Context $Context -Path $providerPaths.ConfigPath
        throw "Missing provider config: $relativePath. Prepare codedb-mcp.toml in ignored runtime before refreshing the index."
    }

    return $providerPaths
}

function Assert-ProjectCodedbRuntimeConfig {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ProviderPaths
    )

    $config = Get-Content -LiteralPath $ProviderPaths.ConfigPath -Raw
    $relativeConfig = ConvertTo-CodedbProjectRelativePath -Context $Context -Path $ProviderPaths.ConfigPath

    if ($config -match '"[^"/]+/(Assets|Packages|ProjectSettings)"') {
        throw "Runtime config still uses repository-root scan paths. Regenerate $relativeConfig with Unity-root-relative scan roots: Assets, Packages, ProjectSettings."
    }

    foreach ($requiredRoot in @('"Assets"', '"Packages"', '"ProjectSettings"')) {
        if ($config.IndexOf($requiredRoot, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "Runtime config $relativeConfig is missing required scan root $requiredRoot."
        }
    }

    foreach ($requiredExclude in @(
        'Library/PackageCache/**',
        'AIWork/.runtime/**'
    )) {
        if ($config.IndexOf($requiredExclude, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "Runtime config $relativeConfig is missing required exclusion $requiredExclude."
        }
    }

    if ($config.IndexOf('__CODEDB_PROVIDER_SLUG__', [System.StringComparison]::Ordinal) -ge 0) {
        throw "Runtime config $relativeConfig still contains an unresolved provider slug token."
    }

    $expectedIndex = "$($Context.ProviderRuntimeRelativePath)/index"
    if ($config.IndexOf($expectedIndex, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Runtime config $relativeConfig must store indexes under $expectedIndex."
    }

    $currentSection = ""
    $flushIntervalValues = @()
    foreach ($line in ($config -split "`r?`n")) {
        if ($line -match '^\s*\[([^\]]+)\]\s*(?:#.*)?$') {
            $currentSection = $Matches[1].Trim()
            continue
        }
        if ([string]::Equals($currentSection, "logging", [System.StringComparison]::OrdinalIgnoreCase) -and
            $line -match '^\s*([A-Za-z0-9_]+)\s*=\s*([^#]*?)\s*(?:#.*)?$' -and
            [string]::Equals($Matches[1], "flush_interval_ms", [System.StringComparison]::OrdinalIgnoreCase)) {
            $flushIntervalValues += $Matches[2].Trim()
        }
    }

    if ($flushIntervalValues.Count -ne 1) {
        throw "Runtime config $relativeConfig is missing required [logging].flush_interval_ms."
    }

    $flushIntervalMilliseconds = 0
    if (-not [int]::TryParse($flushIntervalValues[0], [ref]$flushIntervalMilliseconds) -or
        $flushIntervalMilliseconds -le 0) {
        throw "Runtime config $relativeConfig must define [logging].flush_interval_ms as a positive integer."
    }
}

function Test-ProjectCodedbRuntimeFileOperations {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [string]$TargetDirectory = $Context.ProviderTempRoot
    )

    Assert-CodedbPathInside -Path $TargetDirectory -Root $Context.ProviderRoot -Label "runtime permission probe"
    New-Item -ItemType Directory -Force -Path $TargetDirectory | Out-Null

    $probeId = [guid]::NewGuid().ToString("N")
    $createdPath = Join-Path $TargetDirectory "probe-$probeId.create.tmp"
    $renamedPath = Join-Path $TargetDirectory "probe-$probeId.rename.tmp"
    $directoryPath = Join-Path $TargetDirectory "probe-$probeId"

    try {
        Set-Content -LiteralPath $createdPath -Value "codedb runtime permission probe" -Encoding ASCII -NoNewline
        Move-Item -LiteralPath $createdPath -Destination $renamedPath -ErrorAction Stop
        Remove-Item -LiteralPath $renamedPath -Force -ErrorAction Stop

        New-Item -ItemType Directory -Path $directoryPath -ErrorAction Stop | Out-Null
        Remove-Item -LiteralPath $directoryPath -Force -ErrorAction Stop
    } catch {
        throw "Runtime permission probe failed for $($Context.ProviderName). The refresh runner must support file create, rename, and delete operations under AIWork/.runtime/codedb/. $($_.Exception.Message)"
    } finally {
        foreach ($path in @($createdPath, $renamedPath, $directoryPath)) {
            if (Test-Path -LiteralPath $path) {
                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Sync-ProjectCodedbIgnore {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    if (-not (Test-Path -LiteralPath $Context.IgnoreTemplatePath)) {
        throw "Missing codedb ignore template: $($Context.IgnoreTemplatePath)"
    }

    Assert-CodedbPathInside -Path $Context.GeneratedUnityIgnorePath -Root $Context.UnityRoot -Label "generated .codedbignore"
    Copy-Item -LiteralPath $Context.IgnoreTemplatePath -Destination $Context.GeneratedUnityIgnorePath -Force
}

function Sync-ProjectCodedbRuntimeConfig {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    if (-not (Test-Path -LiteralPath $Context.RuntimeConfigTemplatePath)) {
        throw "Missing codedb runtime config template: $($Context.RuntimeConfigTemplatePath)"
    }

    $providerPaths = Get-ProjectCodedbProviderPaths -Context $Context
    Assert-CodedbPathInside -Path $providerPaths.ConfigPath -Root $Context.ProviderRoot -Label "provider runtime config"
    New-Item -ItemType Directory -Force -Path $Context.ProviderConfigRoot | Out-Null
    $template = Get-Content -LiteralPath $Context.RuntimeConfigTemplatePath -Raw
    if ($template.IndexOf('__CODEDB_PROVIDER_SLUG__', [System.StringComparison]::Ordinal) -lt 0) {
        throw "Runtime config template is missing __CODEDB_PROVIDER_SLUG__."
    }

    $renderedConfig = $template.Replace('__CODEDB_PROVIDER_SLUG__', $Context.ProviderName)
    [System.IO.File]::WriteAllText(
        $providerPaths.ConfigPath,
        $renderedConfig,
        [System.Text.UTF8Encoding]::new($false)
    )

    return $providerPaths.ConfigPath
}

function Test-CodedbPathGitIgnored {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    & git -C $Context.RepoRoot check-ignore -q -- $RelativePath
    return $LASTEXITCODE -eq 0
}

function Assert-ProjectCodedbWatchCoordinatorStopped {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    $statePath = Join-Path $Context.ProviderRoot "watch\coordinator\coordinator-state.json"
    Assert-CodedbPathInside -Path $statePath -Root $Context.ProviderRoot -Label "watch coordinator state"
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return
    }

    try {
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    } catch {
        throw "Watch coordinator state is unreadable. Run Stop Watcher before provider index maintenance. $($_.Exception.Message)"
    }

    $livePids = @()
    foreach ($candidate in @($state.coordinator_pid, $state.provider_pid, $state.adapter_worker_pid, $state.adapter_build_pid)) {
        $processId = 0
        if ([int]::TryParse([string]$candidate, [ref]$processId) -and
            $processId -gt 0 -and
            $null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
            $livePids += $processId
        }
    }
    if ($livePids.Count -gt 0) {
        throw "Watch coordinator is still running (PID(s): $($livePids -join ', ')). Run Stop Watcher before provider index maintenance."
    }
}

function Get-ProjectCodedbActiveReadConfigPath {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    $providerPaths = Get-ProjectCodedbProviderPaths -Context $Context
    $watchConfigPath = Join-Path $Context.ProviderConfigRoot "codedb-mcp.watch.toml"
    $adapterBuilderPath = Join-Path $Context.CodedbRoot "scripts\build-codedb-project-text-adapter.ps1"
    $adapterWorkerPath = Join-Path $Context.CodedbRoot "scripts\run-codedb-project-text-adapter-worker.ps1"
    $legacyAdapterBuilderPath = Join-Path $Context.BootstrapRoot "scripts\build-codedb-project-text-adapter.ps1"
    $legacyAdapterWorkerPath = Join-Path $Context.BootstrapRoot "scripts\run-codedb-project-text-adapter-worker.ps1"
    $watchRoot = Join-Path $Context.ProviderRoot "watch"
    $desiredStatePath = Join-Path $watchRoot "lifecycle\desired-state.json"
    $coordinatorRuntime = Join-Path $watchRoot "coordinator"
    $statePath = Join-Path $coordinatorRuntime "coordinator-state.json"
    foreach ($path in @($watchConfigPath, $Context.TextAdapterManifestPath, $desiredStatePath, $coordinatorRuntime, $statePath)) {
        Assert-CodedbPathInside -Path $path -Root $Context.ProviderRoot -Label "watch read config state"
    }
    foreach ($path in @($adapterBuilderPath, $adapterWorkerPath)) {
        Assert-CodedbPathInside -Path $path -Root $Context.CodedbRoot -Label "watch integration script"
    }
    foreach ($path in @($legacyAdapterBuilderPath, $legacyAdapterWorkerPath)) {
        Assert-CodedbPathInside -Path $path -Root $Context.BootstrapRoot -Label "legacy watch integration alias"
    }

    if (-not (Test-Path -LiteralPath $watchConfigPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $adapterBuilderPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $Context.TextAdapterManifestPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $desiredStatePath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return $providerPaths.ConfigPath
    }

    try {
        $desired = Get-Content -LiteralPath $desiredStatePath -Raw | ConvertFrom-Json
        $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        $adapterOperational = [string]$state.adapter_state -in @("watching", "pending", "building")
        if ([int]$desired.schema_version -ne 1 -or
            -not [string]::Equals([string]$desired.managed_by, "com.rice.ai-codedb", [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$desired.desired_state, "enabled", [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$state.desired_state, "enabled", [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$state.editor_demand, "online", [StringComparison]::Ordinal) -or
            [int]$state.editor_session_count -le 0 -or
            -not [string]::Equals([string]$state.provider_state, "ready", [StringComparison]::OrdinalIgnoreCase) -or
            -not [bool]$state.adapter_enabled -or
            -not $adapterOperational -or
            [int]$state.adapter_debounce_ms -le 0 -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.root), [System.IO.Path]::GetFullPath($Context.UnityRoot), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.provider_executable), [System.IO.Path]::GetFullPath($providerPaths.ExecutablePath), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.provider_config), [System.IO.Path]::GetFullPath($watchConfigPath), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([string]$state.generation_id, [string]$Context.GenerationId, [StringComparison]::Ordinal) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.adapter_builder), [System.IO.Path]::GetFullPath($legacyAdapterBuilderPath), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.adapter_worker), [System.IO.Path]::GetFullPath($legacyAdapterWorkerPath), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.generation_adapter_builder), [System.IO.Path]::GetFullPath($adapterBuilderPath), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.generation_adapter_worker), [System.IO.Path]::GetFullPath($adapterWorkerPath), [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([string]$state.adapter_worker_state, "ready", [StringComparison]::OrdinalIgnoreCase) -or
            -not [string]::Equals([System.IO.Path]::GetFullPath([string]$state.adapter_manifest), [System.IO.Path]::GetFullPath($Context.TextAdapterManifestPath), [StringComparison]::OrdinalIgnoreCase)) {
            return $providerPaths.ConfigPath
        }

        foreach ($candidate in @($state.coordinator_pid, $state.provider_pid, $state.adapter_worker_pid)) {
            $processId = 0
            if (-not [int]::TryParse([string]$candidate, [ref]$processId) -or
                $processId -le 0 -or
                $null -eq (Get-Process -Id $processId -ErrorAction SilentlyContinue)) {
                return $providerPaths.ConfigPath
            }
        }
        return $watchConfigPath
    } catch {
        return $providerPaths.ConfigPath
    }
}

function Get-ProjectCodedbFreshnessState {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Provider index", "Shader adapter")]
        [string]$Label
    )

    $pattern = "^$([System.Text.RegularExpressions.Regex]::Escape($Label)):\s+(OK|STALE|UNKNOWN)\b"
    $states = @()
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            $states += $Matches[1].ToUpperInvariant()
        }
    }

    if ($states.Count -ne 1) {
        throw "Expected exactly one $Label freshness state, found $($states.Count)."
    }

    return $states[0]
}

function Get-ProjectCodedbRefreshPlan {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FreshnessLines
    )

    $providerState = Get-ProjectCodedbFreshnessState -Lines $FreshnessLines -Label "Provider index"
    $adapterState = Get-ProjectCodedbFreshnessState -Lines $FreshnessLines -Label "Shader adapter"

    [pscustomobject]@{
        ProviderState = $providerState
        AdapterState = $adapterState
        ProviderNeedsRefresh = $providerState -ne "OK"
        AdapterNeedsRefresh = $adapterState -ne "OK"
    }
}

function Assert-ProjectCodedbFreshnessPassed {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$FreshnessLines
    )

    $plan = Get-ProjectCodedbRefreshPlan -FreshnessLines $FreshnessLines
    $hasOverallOk = @($FreshnessLines | Where-Object {
        $_ -match '^\[OK\]\s+codedb freshness check passed\.\s*$'
    }).Count -eq 1

    if (-not $hasOverallOk -or $plan.ProviderState -ne "OK" -or $plan.AdapterState -ne "OK") {
        throw "Codedb freshness acceptance requires one overall OK marker and OK component states. Provider=$($plan.ProviderState) Adapter=$($plan.AdapterState)."
    }

    return $plan
}
