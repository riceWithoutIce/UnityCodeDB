[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ReceiptPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$schemaVersion = 1
$managedBy = 'com.rice.ai-codedb'
$maximumReceiptBytes = 262144
$maximumOutputBytes = 1048576
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][AllowEmptyCollection()][byte[]]$Bytes)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    $stream = [IO.File]::OpenRead($Path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $algorithm.Dispose()
        $stream.Dispose()
    }
}

function Test-Id {
    param([string]$Value, [int]$Length)
    return $null -ne $Value -and $Value.Length -eq $Length -and $Value -cmatch '^[0-9a-f]+$'
}

function Get-PhysicalIdentityKey {
    param([Parameter(Mandatory = $true)][string]$IdentityKey)
    if (-not (Test-Id $IdentityKey 64)) {
        throw 'Manager action identity key is invalid.'
    }
    return $IdentityKey.Substring(0, 24)
}

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Test-PathInside {
    param([string]$Root, [string]$Path)
    $normalizedRoot = Get-NormalizedPath $Root
    $normalizedPath = Get-NormalizedPath $Path
    return $normalizedPath.Equals($normalizedRoot, [StringComparison]::OrdinalIgnoreCase) -or
        $normalizedPath.StartsWith($normalizedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparseTraversal {
    param([string]$Root, [string]$Target, [string]$Label)
    $normalizedRoot = Get-NormalizedPath $Root
    $normalizedTarget = Get-NormalizedPath $Target
    if (-not (Test-PathInside $normalizedRoot $normalizedTarget)) {
        throw "$Label escapes its reviewed root."
    }
    $volume = [IO.Path]::GetPathRoot($normalizedTarget)
    $relative = $normalizedTarget.Substring($volume.Length).TrimStart('\', '/')
    $current = $volume
    foreach ($segment in @($relative -split '[\\/]' | Where-Object { $_ })) {
        $current = Join-Path $current $segment
        if (-not (Test-Path -LiteralPath $current)) { break }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label traverses a reparse point."
        }
    }
}

function Write-AtomicJson {
    param([string]$Path, [object]$Value)
    $text = ($Value | ConvertTo-Json -Depth 12) -replace "`r`n", "`n"
    if (-not $text.EndsWith("`n", [StringComparison]::Ordinal)) { $text += "`n" }
    $temp = $Path + '.' + [Diagnostics.Process]::GetCurrentProcess().Id + '.' + [Guid]::NewGuid().ToString('N') + '.tmp'
    try {
        [IO.File]::WriteAllText($temp, $text, $utf8NoBom)
        if (Test-Path -LiteralPath $Path) {
            [IO.File]::Replace($temp, $Path, $null)
        }
        else {
            [IO.File]::Move($temp, $Path)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temp) { [IO.File]::Delete($temp) }
    }
}

function Quote-WindowsArgument {
    param([AllowEmptyString()][string]$Value)
    if ([string]::IsNullOrEmpty($Value)) { return '""' }
    $builder = New-Object Text.StringBuilder
    [void]$builder.Append('"')
    $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') { $slashes++; continue }
        if ($character -eq '"') {
            [void]$builder.Append('\', ($slashes * 2) + 1)
            [void]$builder.Append('"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) { [void]$builder.Append('\', $slashes); $slashes = 0 }
        [void]$builder.Append($character)
    }
    if ($slashes -gt 0) { [void]$builder.Append('\', $slashes * 2) }
    [void]$builder.Append('"')
    return $builder.ToString()
}

function Read-BoundedText {
    param([string]$Path, [int]$MaximumBytes)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    try {
        $length = [Math]::Min($stream.Length, [long]$MaximumBytes)
        $bytes = New-Object byte[] ([int]$length)
        $read = $stream.Read($bytes, 0, $bytes.Length)
        return [Text.Encoding]::UTF8.GetString($bytes, 0, $read)
    }
    finally {
        $stream.Dispose()
    }
}

$localAppData = [Environment]::GetEnvironmentVariable('LOCALAPPDATA', [EnvironmentVariableTarget]::Process)
if ([string]::IsNullOrWhiteSpace($localAppData)) {
    $localAppData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
}
if ([string]::IsNullOrWhiteSpace($localAppData)) { throw 'Local application data is unavailable.' }
$receiptRoot = Get-NormalizedPath (Join-Path $localAppData 'Rice\CodeDB\manager-actions')
$receiptPath = Get-NormalizedPath $ReceiptPath
if (-not (Test-PathInside $receiptRoot $receiptPath)) { throw 'Manager action receipt path escapes its scoped root.' }
Assert-NoReparseTraversal $receiptRoot $receiptPath 'Manager action receipt path'

$admittedPath = Join-Path $receiptPath 'admitted.json'
$claimPath = Join-Path $receiptPath 'claim.json'
$terminalPath = Join-Path $receiptPath 'terminal.json'
$startFailurePath = Join-Path $receiptPath 'start-failure.json'
if (-not (Test-Path -LiteralPath $admittedPath -PathType Leaf)) { throw 'Manager action admission record is missing.' }
if ((Get-Item -LiteralPath $admittedPath).Length -gt $maximumReceiptBytes) { throw 'Manager action admission record exceeds its bound.' }
if (Test-Path -LiteralPath $claimPath) { throw 'Manager action stage already has a writer claim.' }
if (Test-Path -LiteralPath $terminalPath) { throw 'Manager action stage already has a terminal receipt.' }
if (Test-Path -LiteralPath $startFailurePath) { throw 'Manager action stage already has a start-failure receipt.' }

$admitted = [IO.File]::ReadAllText($admittedPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
if ($admitted.schema_version -ne $schemaVersion -or $admitted.managed_by -cne $managedBy -or $admitted.state -cne 'admitted') {
    throw 'Manager action admission envelope is invalid.'
}
if (-not (Test-Id ([string]$admitted.action_id) 32) -or -not (Test-Id ([string]$admitted.stage_id) 64)) {
    throw 'Manager action admission identity is invalid.'
}
if (-not (Test-Id ([string]$admitted.project_key) 64) -or -not (Test-Id ([string]$admitted.package_key) 64)) {
    throw 'Manager action project or Package key is invalid.'
}
$expectedSuffix = Join-Path (Join-Path (Join-Path (Get-PhysicalIdentityKey ([string]$admitted.project_key)) (Get-PhysicalIdentityKey ([string]$admitted.package_key))) ([string]$admitted.action_id)) ([string]$admitted.stage_id)
if (-not $receiptPath.EndsWith($expectedSuffix, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Manager action receipt path does not match its admitted identity.'
}

$projectRoot = Get-NormalizedPath ([string]$admitted.project_root)
$packageRoot = Get-NormalizedPath ([string]$admitted.package_root)
$projectKey = Get-Sha256Hex -Bytes ($utf8NoBom.GetBytes($projectRoot.Replace('\', '/').ToLowerInvariant()))
$packageKey = Get-Sha256Hex -Bytes ($utf8NoBom.GetBytes($packageRoot.Replace('\', '/').ToLowerInvariant()))
if ($projectKey -cne [string]$admitted.project_key -or
    $packageKey -cne [string]$admitted.package_key -or
    [string]$admitted.project_identity -cne ('sha256:' + $projectKey) -or
    [string]$admitted.package_identity -cne ('sha256:' + $packageKey)) {
    throw 'Manager action project or Package identity binding is invalid.'
}
if ([string]::IsNullOrWhiteSpace([string]$admitted.effect_class) -or
    [string]::IsNullOrWhiteSpace([string]$admitted.authorization_source)) {
    throw 'Manager action effect or authorization source is missing.'
}
$commandPath = Get-NormalizedPath ([string]$admitted.command.script_path)
$writerPath = Get-NormalizedPath $PSCommandPath
$expectedWriterPath = Get-NormalizedPath (Join-Path $packageRoot 'Tools~\invoke-codedb-manager-action.ps1')
if (-not $writerPath.Equals($expectedWriterPath, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Manager action writer is not the resolved Package-owned script.'
}
Assert-NoReparseTraversal $packageRoot $writerPath 'Manager action writer'
if ((Get-FileSha256 $writerPath) -cne ([string]$admitted.writer_sha256)) { throw 'Manager action writer bytes changed after admission.' }
if (-not ((Test-PathInside $projectRoot $commandPath) -or (Test-PathInside $packageRoot $commandPath))) {
    throw 'Manager action command is outside its admitted project and Package roots.'
}
$commandRoot = if (Test-PathInside $packageRoot $commandPath) { $packageRoot } else { $projectRoot }
Assert-NoReparseTraversal $commandRoot $commandPath 'Manager action command'
if (-not (Test-Path -LiteralPath $commandPath -PathType Leaf)) { throw 'Manager action command script is missing.' }
if ((Get-FileSha256 $commandPath) -cne ([string]$admitted.command.script_sha256)) { throw 'Manager action command bytes changed after admission.' }
$arguments = @($admitted.command.arguments | ForEach-Object { [string]$_ })
$argumentText = ($arguments -join "`n")
if ((Get-Sha256Hex $utf8NoBom.GetBytes($argumentText)) -cne ([string]$admitted.command.arguments_sha256)) {
    throw 'Manager action command arguments changed after admission.'
}
$timeoutMilliseconds = [int]$admitted.command.timeout_ms
if ($timeoutMilliseconds -lt 1 -or $timeoutMilliseconds -gt 1800000) { throw 'Manager action timeout is invalid.' }

$startInfo = New-Object Diagnostics.ProcessStartInfo
$startInfo.FileName = 'powershell.exe'
$commandArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $commandPath) + $arguments
$startInfo.Arguments = (($commandArguments | ForEach-Object { Quote-WindowsArgument $_ }) -join ' ')
$startInfo.WorkingDirectory = $projectRoot
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.EnvironmentVariables['RICE_CODEDB_UNITY_ROOT'] = $projectRoot
$child = New-Object Diagnostics.Process
$child.StartInfo = $startInfo

$writerProcess = [Diagnostics.Process]::GetCurrentProcess()
$claim = [ordered]@{
    schema_version = $schemaVersion
    managed_by = $managedBy
    state = 'claimed'
    action_id = [string]$admitted.action_id
    stage_id = [string]$admitted.stage_id
    project_key = [string]$admitted.project_key
    package_key = [string]$admitted.package_key
    writer_pid = $writerProcess.Id
    writer_start_utc_ticks = $writerProcess.StartTime.ToUniversalTime().Ticks.ToString([Globalization.CultureInfo]::InvariantCulture)
    claimed_at_utc = [DateTime]::UtcNow.ToString('O', [Globalization.CultureInfo]::InvariantCulture)
}
Write-AtomicJson $claimPath $claim

$startError = $null
try {
    if (-not $child.Start()) { $startError = 'CHILD_START_RETURNED_FALSE' }
}
catch [ComponentModel.Win32Exception] {
    if ($_.Exception.NativeErrorCode -in @(2, 3, 193, 267)) {
        $startError = 'CHILD_START_FAILED'
    }
    else { throw }
}
if ($null -ne $startError) {
    $child.Dispose()
    $startFailure = [ordered]@{
        schema_version = $schemaVersion
        managed_by = $managedBy
        state = 'start_failed'
        action_id = [string]$admitted.action_id
        stage_id = [string]$admitted.stage_id
        project_key = [string]$admitted.project_key
        package_key = [string]$admitted.package_key
        command_identity_sha256 = [string]$admitted.command_identity_sha256
        writer_pid = $writerProcess.Id
        reason = $startError
        completed_at_utc = [DateTime]::UtcNow.ToString('O', [Globalization.CultureInfo]::InvariantCulture)
    }
    Write-AtomicJson $startFailurePath $startFailure
    exit 0
}

$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$timedOut = $false
$outputOverflow = $false
$childPid = $child.Id
$stdoutBytes = New-Object IO.MemoryStream
$stderrBytes = New-Object IO.MemoryStream
$stdoutBuffer = New-Object byte[] 4096
$stderrBuffer = New-Object byte[] 4096
$stdoutTask = $child.StandardOutput.BaseStream.ReadAsync($stdoutBuffer, 0, $stdoutBuffer.Length)
$stderrTask = $child.StandardError.BaseStream.ReadAsync($stderrBuffer, 0, $stderrBuffer.Length)
$drainDeadline = [long]::MaxValue
try {
    while ($null -ne $stdoutTask -or $null -ne $stderrTask -or -not $child.HasExited) {
        if ($child.HasExited -and $drainDeadline -eq [long]::MaxValue) {
            $drainDeadline = $stopwatch.ElapsedMilliseconds + 5000
        }
        if ($null -ne $stdoutTask -and $stdoutTask.IsCompleted) {
            $count = $stdoutTask.GetAwaiter().GetResult()
            $stdoutTask = $null
            if ($count -gt 0) {
                if ($stdoutBytes.Length + $count -gt $maximumOutputBytes) { $outputOverflow = $true }
                elseif (-not $outputOverflow) { $stdoutBytes.Write($stdoutBuffer, 0, $count) }
                $stdoutTask = $child.StandardOutput.BaseStream.ReadAsync($stdoutBuffer, 0, $stdoutBuffer.Length)
            }
        }
        if ($null -ne $stderrTask -and $stderrTask.IsCompleted) {
            $count = $stderrTask.GetAwaiter().GetResult()
            $stderrTask = $null
            if ($count -gt 0) {
                if ($stderrBytes.Length + $count -gt $maximumOutputBytes) { $outputOverflow = $true }
                elseif (-not $outputOverflow) { $stderrBytes.Write($stderrBuffer, 0, $count) }
                $stderrTask = $child.StandardError.BaseStream.ReadAsync($stderrBuffer, 0, $stderrBuffer.Length)
            }
        }
        if (-not $child.HasExited -and ($outputOverflow -or $stopwatch.ElapsedMilliseconds -ge $timeoutMilliseconds)) {
            $timedOut = -not $outputOverflow
            $child.Kill()
            $drainDeadline = $stopwatch.ElapsedMilliseconds + 5000
        }
        if ($stopwatch.ElapsedMilliseconds -gt $drainDeadline) {
            throw 'Manager action output did not drain after the child stopped.'
        }
        if ($null -ne $stdoutTask -or $null -ne $stderrTask -or -not $child.HasExited) {
            Start-Sleep -Milliseconds 20
        }
    }
    $child.WaitForExit()
    $stdout = [Text.Encoding]::UTF8.GetString($stdoutBytes.ToArray())
    $stderr = [Text.Encoding]::UTF8.GetString($stderrBytes.ToArray())
    $exitCode = if ($timedOut -or $outputOverflow) { 4 } else { $child.ExitCode }
}
finally {
    if (-not $child.HasExited) { $child.Kill() }
    $child.Dispose()
    $stdoutBytes.Dispose()
    $stderrBytes.Dispose()
}
if ($outputOverflow) {
    $stderr = $stderr.TrimEnd() + "`nManager action output exceeded the bounded receipt limit."
}
$stopwatch.Stop()

$terminal = [ordered]@{
    schema_version = $schemaVersion
    managed_by = $managedBy
    state = 'terminal'
    action_id = [string]$admitted.action_id
    stage_id = [string]$admitted.stage_id
    terminal_for_action = [bool]$admitted.terminal_for_action
    project_key = [string]$admitted.project_key
    package_key = [string]$admitted.package_key
    project_identity = [string]$admitted.project_identity
    package_identity = [string]$admitted.package_identity
    effect_class = [string]$admitted.effect_class
    authorization_source = [string]$admitted.authorization_source
    command_identity_sha256 = [string]$admitted.command_identity_sha256
    writer_pid = $writerProcess.Id
    child_pid = $childPid
    exit_code = [int]$exitCode
    timed_out = [bool]$timedOut
    output_overflow = [bool]$outputOverflow
    elapsed_milliseconds = [Math]::Max(0, [Math]::Min([int]::MaxValue, $stopwatch.ElapsedMilliseconds))
    stdout = $stdout
    stderr = $stderr
    completed_at_utc = [DateTime]::UtcNow.ToString('O', [Globalization.CultureInfo]::InvariantCulture)
}
Write-AtomicJson $terminalPath $terminal
exit 0
