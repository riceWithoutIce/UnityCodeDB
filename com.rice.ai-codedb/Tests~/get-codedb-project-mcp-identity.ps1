#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd('\', '/')
$name = [System.IO.Path]::GetFileName($root)
$normalized = $name.Normalize([Text.NormalizationForm]::FormC)
$builder = [System.Text.StringBuilder]::new()
$previousWasSeparator = $false
$containsNonAscii = $false

foreach ($character in $normalized.ToCharArray()) {
    if ([int]$character -gt 0x7f) {
        $containsNonAscii = $true
    }
    if (($character -ge 'A' -and $character -le 'Z') -or
        ($character -ge 'a' -and $character -le 'z') -or
        ($character -ge '0' -and $character -le '9')) {
        $null = $builder.Append([char]::ToLowerInvariant($character))
        $previousWasSeparator = $false
    } elseif (-not $previousWasSeparator -and $builder.Length -gt 0) {
        $null = $builder.Append('-')
        $previousWasSeparator = $true
    }
}

while ($builder.Length -gt 0 -and $builder[$builder.Length - 1] -eq '-') {
    $builder.Length--
}

$slug = if ($builder.Length -eq 0) { "unity-project" } else { $builder.ToString() }
$requiresHash = $containsNonAscii
if ($slug.Length -gt 96) {
    $slug = $slug.Substring(0, 96).TrimEnd('-')
    $requiresHash = $true
}
if ($requiresHash) {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalized))
        $suffix = (($hash[0..5] | ForEach-Object { $_.ToString("x2") }) -join "")
        $slug = "$slug-$suffix"
    } finally {
        $sha256.Dispose()
    }
}

$serverName = "codedb-$slug"
"CODEDB_SERVER_NAME=$serverName"
"CODEDB_TOOL_NAMESPACE=mcp__$($serverName.Replace('-', '_'))__*"
