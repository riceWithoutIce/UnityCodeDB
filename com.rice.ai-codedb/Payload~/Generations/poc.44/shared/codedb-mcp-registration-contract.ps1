#requires -Version 5.1

# Pure helpers for the one project-owned MCP cwd field. No filesystem probing,
# config publication, environment expansion or client startup occurs here.
function ConvertTo-CodedbMcpWorkingDirectoryValue {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $path = [IO.Path]::GetFullPath($ProjectRoot).Replace('\', '/')
    return (ConvertTo-Json -InputObject $path -Compress)
}

function Test-CodedbMcpWorkingDirectoryValue {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    # Decode only a single-line TOML string (including its optional comment).
    # Literal/basic quoting, escaped backslashes and Unicode are equivalent;
    # this is not a parser or policy for any other client configuration.
    $string = [regex]::Match($Value, '^\s*(?<quoted>"(?:[^"\\\r\n]|\\(?:["\\btnfr]|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8}))*"|''[^''\r\n]*'')\s*(?:#.*)?$')
    if (-not $string.Success) { return $false }
    $quoted = $string.Groups['quoted'].Value
    try {
        if ($quoted[0] -eq "'") {
            $path = $quoted.Substring(1, $quoted.Length - 2)
        } else {
            $path = [regex]::Replace($quoted.Substring(1, $quoted.Length - 2), '\\(?:["\\btnfr]|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{8})', {
                param($escape)
                if ($escape.Value.StartsWith('\U', [StringComparison]::Ordinal)) {
                    return [char]::ConvertFromUtf32([Convert]::ToInt32($escape.Value.Substring(2), 16))
                }
                return [string](ConvertFrom-Json -InputObject ('"' + $escape.Value + '"'))
            })
        }
        if ([IO.Path]::DirectorySeparatorChar -eq '\') {
            if ($path -notmatch '^(?:[A-Za-z]:[\\/]|[\\/]{2})') { return $false }
            $comparison = [StringComparison]::OrdinalIgnoreCase
        } else {
            if (-not [IO.Path]::IsPathRooted($path)) { return $false }
            $comparison = [StringComparison]::Ordinal
        }
        $actual = [IO.Path]::GetFullPath($path).Replace('\', '/').TrimEnd('/')
        $expected = [IO.Path]::GetFullPath($ProjectRoot).Replace('\', '/').TrimEnd('/')
        return [string]::Equals($actual, $expected, $comparison)
    } catch {
        return $false
    }
}
