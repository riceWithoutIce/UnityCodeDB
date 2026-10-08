#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$PackageRoot = '',
    [string]$BuildRoot,
    [string]$NativeRoot,
    [string]$MsvcRoot,
    [string]$WindowsSdkRoot,
    [string]$WindowsSdkVersion,
    [switch]$VerifyOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $PackageRoot) { $PackageRoot = Join-Path $PSScriptRoot '..' }
$root = [IO.Path]::GetFullPath($PackageRoot)
$source = Join-Path $root 'Tools~/native/codedb-daemon-launch.cpp'
if (-not $NativeRoot) { $NativeRoot = Join-Path $root 'Payload~/AIWork/codedb/native/win-x64' }
$binary = Join-Path $NativeRoot 'codedb-daemon-launch.exe'
$manifestPath = Join-Path $NativeRoot 'build-manifest.json'
$options = @('/nologo','/W4','/WX','/O2','/MT','/EHsc','/utf-8','/Brepro','/MACHINE:X64','kernel32.lib')
function Hash([string]$p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant() }
function Save([string]$p, $value) { [IO.File]::WriteAllText($p, (($value | ConvertTo-Json -Depth 12).Replace("`r`n", "`n") + "`n"), [Text.UTF8Encoding]::new($false)) }
function Check([bool]$test, [string]$message) { if (-not $test) { throw $message } }
function Inspect-Pe([string]$p) {
    $bytes = [IO.File]::ReadAllBytes($p)
    Check ($bytes.Length -ge 256) 'Native binary is truncated.'
    $pe = [BitConverter]::ToInt32($bytes, 60)
    Check ($pe -gt 0 -and $pe + 264 -lt $bytes.Length) 'Invalid PE offset.'
    Check ([BitConverter]::ToUInt32($bytes, $pe) -eq 0x4550 -and [BitConverter]::ToUInt16($bytes, $pe + 4) -eq 0x8664) 'Native binary must be Windows x64 PE.'
    $optional = $pe + 24
    Check ([BitConverter]::ToUInt16($bytes, $optional) -eq 0x20b) 'Native binary must be PE32+.'
    $sections = [BitConverter]::ToUInt16($bytes, $pe + 6)
    $table = $optional + [BitConverter]::ToUInt16($bytes, $pe + 20)
    function Offset([uint32]$rva) {
        for ($i = 0; $i -lt $sections; $i++) {
            $entry = $table + 40 * $i
            $address = [BitConverter]::ToUInt32($bytes, $entry + 12)
            $size = [BitConverter]::ToUInt32($bytes, $entry + 16)
            if ($rva -ge $address -and $rva -lt $address + $size) { return [int]([BitConverter]::ToUInt32($bytes, $entry + 20) + $rva - $address) }
        }
        throw 'Native import RVA is outside sections.'
    }
    $importRva = [BitConverter]::ToUInt32($bytes, $optional + 120)
    $entry = Offset $importRva
    $dlls = @()
    for ($i = 0; $i -lt 32; $i++) {
        $nameRva = [BitConverter]::ToUInt32($bytes, $entry + 12)
        if ($nameRva -eq 0) { break }
        $start = Offset $nameRva; $end = $start
        while ($end -lt $bytes.Length -and $bytes[$end] -ne 0 -and $end - $start -lt 256) { $end++ }
        $dlls += [Text.Encoding]::ASCII.GetString($bytes, $start, $end - $start).ToUpperInvariant()
        $entry += 20
    }
    Check ($dlls.Count -eq 1 -and $dlls[0] -ceq 'KERNEL32.DLL') 'Native binary imports must be KERNEL32.DLL only (/MT, no runtime DLL).'
    return $dlls
}
if (-not $VerifyOnly) {
    Check (-not [string]::IsNullOrWhiteSpace($BuildRoot)) 'An explicit repository-local BuildRoot is required.'
    $checkout = Split-Path $root -Parent
    $tests = [IO.Path]::GetFullPath((Join-Path $checkout '.artifacts/tests'))
    $build = [IO.Path]::GetFullPath($BuildRoot)
    Check ($build.StartsWith($tests + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'BuildRoot must stay below checkout .artifacts/tests/.'
    Check (-not (Test-Path -LiteralPath $build)) 'BuildRoot must be fresh.'
    $ancestor = Split-Path $build -Parent
    while ($ancestor -and $ancestor.Length -ge $checkout.Length) {
        if (Test-Path -LiteralPath $ancestor) { Check (((Get-Item -LiteralPath $ancestor).Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'Build root ancestor is a reparse point.' }
        $ancestor = Split-Path $ancestor -Parent
    }
    if (-not $MsvcRoot) {
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
        Check (Test-Path -LiteralPath $vswhere) 'Pass MsvcRoot or install the supported Visual C++ developer tools.'
        $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        Check (-not [string]::IsNullOrWhiteSpace($vs)) 'No installed x64 MSVC toolchain found.'
        $version = ([IO.File]::ReadAllText((Join-Path $vs 'VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt'))).Trim()
        $MsvcRoot = Join-Path $vs ('VC/Tools/MSVC/' + $version)
    }
    if (-not $WindowsSdkRoot) { $WindowsSdkRoot = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots').KitsRoot10 }
    if (-not $WindowsSdkVersion) {
        $WindowsSdkVersion = Get-ChildItem -LiteralPath (Join-Path $WindowsSdkRoot 'Include') -Directory | Where-Object { $_.Name -match '^10\.\d+\.\d+\.\d+$' -and (Test-Path (Join-Path $_.FullName 'um/Windows.h')) } | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1 -ExpandProperty Name
    }
    $cl = Join-Path $MsvcRoot 'bin/Hostx64/x64/cl.exe'
    $link = Join-Path $MsvcRoot 'bin/Hostx64/x64/link.exe'
    Check ((Test-Path -LiteralPath $cl) -and (Test-Path -LiteralPath $link)) 'Missing installed x64 compiler/linker.'
    [void][IO.Directory]::CreateDirectory($build)
    $temporary = Join-Path $build 'tmp'; [void][IO.Directory]::CreateDirectory($temporary)
    $out = Join-Path $build 'codedb-daemon-launch.exe'
    $arguments = @($options[0..7]) + @(
        ('/I' + (Join-Path $MsvcRoot 'include')),
        ('/I' + (Join-Path $WindowsSdkRoot ('Include/' + $WindowsSdkVersion + '/ucrt'))),
        ('/I' + (Join-Path $WindowsSdkRoot ('Include/' + $WindowsSdkVersion + '/shared'))),
        ('/I' + (Join-Path $WindowsSdkRoot ('Include/' + $WindowsSdkVersion + '/um'))),
        $source, ('/Fo' + (Join-Path $build 'launch.obj')), ('/Fe' + $out), '/link', '/MACHINE:X64', '/Brepro',
        ('/LIBPATH:' + (Join-Path $MsvcRoot 'lib/x64')),
        ('/LIBPATH:' + (Join-Path $WindowsSdkRoot ('Lib/' + $WindowsSdkVersion + '/ucrt/x64'))),
        ('/LIBPATH:' + (Join-Path $WindowsSdkRoot ('Lib/' + $WindowsSdkVersion + '/um/x64'))), 'kernel32.lib')
    # Only this developer invocation and its compiler child see these temp paths.
    $oldTemp = $env:TEMP; $oldTmp = $env:TMP
    try {
        $env:TEMP = $temporary; $env:TMP = $temporary
        $ErrorActionPreference = 'Continue'
        $log = & $cl @arguments 2>&1; $code = $LASTEXITCODE
        $ErrorActionPreference = 'Stop'
        [IO.File]::WriteAllText((Join-Path $build 'build.log'), ($log | Out-String), [Text.UTF8Encoding]::new($false))
        Check ($code -eq 0) 'Native build failed; inspect repository-local build.log.'
    } finally { $env:TEMP = $oldTemp; $env:TMP = $oldTmp; $ErrorActionPreference = 'Stop' }
    $imports = @(Inspect-Pe $out)
    [void][IO.Directory]::CreateDirectory($NativeRoot)
    Copy-Item -LiteralPath $out -Destination $binary
    Save $manifestPath ([ordered]@{
        schema_version = 1; managed_by = 'com.rice.ai-codedb'; platform = 'win32'; architecture = 'x64'
        source = 'Tools~/native/codedb-daemon-launch.cpp'; source_sha256 = Hash $source
        build_script = 'Tools~/build-codedb-daemon-launch.ps1'; build_script_sha256 = Hash $PSCommandPath
        options = $options; imports = $imports; binary_sha256 = Hash $binary
        compiler_version = (Get-Item -LiteralPath $cl).VersionInfo.FileVersion; compiler_sha256 = Hash $cl
        linker_sha256 = Hash $link; windows_sdk_version = $WindowsSdkVersion
    })
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Check ($manifest.schema_version -eq 1 -and $manifest.managed_by -ceq 'com.rice.ai-codedb' -and $manifest.platform -ceq 'win32' -and $manifest.architecture -ceq 'x64') 'Native build manifest identity mismatch.'
Check ($manifest.source -ceq 'Tools~/native/codedb-daemon-launch.cpp' -and $manifest.source_sha256 -ceq (Hash $source)) 'Native build source provenance mismatch.'
Check ($manifest.build_script -ceq 'Tools~/build-codedb-daemon-launch.ps1' -and $manifest.build_script_sha256 -ceq (Hash $PSCommandPath)) 'Native build script provenance mismatch.'
Check (($manifest.options -join '|') -ceq ($options -join '|')) 'Native build options mismatch.'
Check ($manifest.binary_sha256 -ceq (Hash $binary)) 'Native binary provenance mismatch.'
Check (($manifest.imports -join '|') -ceq ((@(Inspect-Pe $binary)) -join '|')) 'Native binary imports provenance mismatch.'
foreach ($field in @('compiler_sha256', 'linker_sha256')) { Check ($manifest.$field -cmatch '^[0-9a-f]{64}$') "Native tool provenance missing: $field" }
Write-Output '[NATIVE_BUILD] PASS x64 /MT KERNEL32.DLL source/build/binary bound'
