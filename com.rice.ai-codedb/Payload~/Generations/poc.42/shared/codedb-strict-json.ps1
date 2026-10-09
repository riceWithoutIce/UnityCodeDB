#requires -Version 5.1
# Pure recursive JSON reader shared by materializer and instance-record projection.

function Skip-StrictJsonWhitespace {
    param([Parameter(Mandatory = $true)]$State)

    while ($State.Index -lt $State.Text.Length -and
        $State.Text[$State.Index] -cin @(' ', "`t", "`r", "`n")) {
        $State.Index++
    }
}

function Read-StrictJsonStringToken {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -cne '"') {
        throw "$Label expected a JSON string at character $($State.Index)."
    }
    $State.Index++
    $builder = [System.Text.StringBuilder]::new()
    while ($State.Index -lt $State.Text.Length) {
        $character = $State.Text[$State.Index]
        $State.Index++
        if ($character -ceq '"') {
            return $builder.ToString()
        }
        if ([int]$character -lt 0x20) {
            throw "$Label contains an unescaped JSON control character."
        }
        if ($character -cne '\') {
            $null = $builder.Append($character)
            continue
        }
        if ($State.Index -ge $State.Text.Length) {
            throw "$Label contains an incomplete JSON escape."
        }
        $escape = $State.Text[$State.Index]
        $State.Index++
        switch -CaseSensitive ($escape) {
            '"' { $null = $builder.Append('"'); continue }
            '\' { $null = $builder.Append('\'); continue }
            '/' { $null = $builder.Append('/'); continue }
            'b' { $null = $builder.Append("`b"); continue }
            'f' { $null = $builder.Append("`f"); continue }
            'n' { $null = $builder.Append("`n"); continue }
            'r' { $null = $builder.Append("`r"); continue }
            't' { $null = $builder.Append("`t"); continue }
            'u' {
                if ($State.Index + 4 -gt $State.Text.Length) {
                    throw "$Label contains an incomplete JSON Unicode escape."
                }
                $hex = $State.Text.Substring($State.Index, 4)
                if ($hex -cnotmatch '^[0-9A-Fa-f]{4}$') {
                    throw "$Label contains an invalid JSON Unicode escape."
                }
                $State.Index += 4
                $codeUnit = [Convert]::ToInt32($hex, 16)
                if ($codeUnit -ge 0xD800 -and $codeUnit -le 0xDBFF) {
                    if ($State.Index + 6 -gt $State.Text.Length -or
                        $State.Text[$State.Index] -cne '\' -or
                        $State.Text[$State.Index + 1] -cne 'u') {
                        throw "$Label contains an unpaired high-surrogate JSON escape."
                    }
                    $lowHex = $State.Text.Substring($State.Index + 2, 4)
                    if ($lowHex -cnotmatch '^[0-9A-Fa-f]{4}$') {
                        throw "$Label contains an invalid low-surrogate JSON escape."
                    }
                    $lowCodeUnit = [Convert]::ToInt32($lowHex, 16)
                    if ($lowCodeUnit -lt 0xDC00 -or $lowCodeUnit -gt 0xDFFF) {
                        throw "$Label contains an unpaired high-surrogate JSON escape."
                    }
                    $State.Index += 6
                    $codePoint = 0x10000 + (($codeUnit - 0xD800) * 0x400) + ($lowCodeUnit - 0xDC00)
                    $null = $builder.Append([char]::ConvertFromUtf32($codePoint))
                    continue
                }
                if ($codeUnit -ge 0xDC00 -and $codeUnit -le 0xDFFF) {
                    throw "$Label contains an unpaired low-surrogate JSON escape."
                }
                $null = $builder.Append([char]$codeUnit)
                continue
            }
            default { throw "$Label contains an unsupported JSON escape."
            }
        }
    }
    throw "$Label contains an unclosed JSON string."
}

function Read-StrictJsonValueToken {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Skip-StrictJsonWhitespace -State $State
    if ($State.Index -ge $State.Text.Length) {
        throw "$Label contains an incomplete JSON value."
    }
    $State.Depth++
    if ($State.Depth -gt 64) {
        throw "$Label exceeds the accepted JSON nesting depth."
    }
    try {
        $character = $State.Text[$State.Index]
        if ($character -ceq '"') {
            return [pscustomobject]@{ Value = (Read-StrictJsonStringToken -State $State -Label $Label) }
        }
        if ($character -ceq '{') {
            $State.Index++
            $properties = [ordered]@{}
            $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            Skip-StrictJsonWhitespace -State $State
            if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -ceq '}') {
                $State.Index++
                return [pscustomobject]@{ Value = [pscustomobject]$properties }
            }
            while ($true) {
                $name = Read-StrictJsonStringToken -State $State -Label $Label
                if (-not $seen.Add($name)) {
                    throw "$Label contains a duplicate or case-ambiguous JSON property: $name"
                }
                Skip-StrictJsonWhitespace -State $State
                if ($State.Index -ge $State.Text.Length -or $State.Text[$State.Index] -cne ':') {
                    throw "$Label expected : after JSON property $name."
                }
                $State.Index++
                $valueToken = Read-StrictJsonValueToken -State $State -Label $Label
                $properties[$name] = $valueToken.Value
                Skip-StrictJsonWhitespace -State $State
                if ($State.Index -ge $State.Text.Length) {
                    throw "$Label contains an unclosed JSON object."
                }
                if ($State.Text[$State.Index] -ceq '}') {
                    $State.Index++
                    return [pscustomobject]@{ Value = [pscustomobject]$properties }
                }
                if ($State.Text[$State.Index] -cne ',') {
                    throw "$Label expected , between JSON object properties."
                }
                $State.Index++
                Skip-StrictJsonWhitespace -State $State
            }
        }
        if ($character -ceq '[') {
            $State.Index++
            $items = New-Object System.Collections.Generic.List[object]
            Skip-StrictJsonWhitespace -State $State
            if ($State.Index -lt $State.Text.Length -and $State.Text[$State.Index] -ceq ']') {
                $State.Index++
                return [pscustomobject]@{ Value = [object[]]@() }
            }
            while ($true) {
                $valueToken = Read-StrictJsonValueToken -State $State -Label $Label
                $items.Add($valueToken.Value)
                Skip-StrictJsonWhitespace -State $State
                if ($State.Index -ge $State.Text.Length) {
                    throw "$Label contains an unclosed JSON array."
                }
                if ($State.Text[$State.Index] -ceq ']') {
                    $State.Index++
                    return [pscustomobject]@{ Value = [object[]]$items.ToArray() }
                }
                if ($State.Text[$State.Index] -cne ',') {
                    throw "$Label expected , between JSON array values."
                }
                $State.Index++
                Skip-StrictJsonWhitespace -State $State
            }
        }
        foreach ($literal in @(
            [pscustomobject]@{ Text = 'true'; Value = $true },
            [pscustomobject]@{ Text = 'false'; Value = $false },
            [pscustomobject]@{ Text = 'null'; Value = $null }
        )) {
            if ($State.Index + $literal.Text.Length -le $State.Text.Length -and
                [string]::Equals($State.Text.Substring($State.Index, $literal.Text.Length), $literal.Text, [StringComparison]::Ordinal)) {
                $State.Index += $literal.Text.Length
                return [pscustomobject]@{ Value = $literal.Value }
            }
        }

        $remaining = $State.Text.Substring($State.Index)
        $numberMatch = [regex]::Match($remaining, '^-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?', [System.Text.RegularExpressions.RegexOptions]::CultureInvariant)
        if (-not $numberMatch.Success) {
            throw "$Label contains an unsupported JSON token at character $($State.Index)."
        }
        $numberText = $numberMatch.Value
        $State.Index += $numberText.Length
        if ($numberText.IndexOfAny([char[]]@('.', 'e', 'E')) -lt 0) {
            [int64]$integer = 0
            if (-not [int64]::TryParse($numberText, [Globalization.NumberStyles]::AllowLeadingSign, [Globalization.CultureInfo]::InvariantCulture, [ref]$integer)) {
                throw "$Label contains a JSON integer outside the signed 64-bit range."
            }
            return [pscustomobject]@{ Value = $integer }
        }
        [double]$number = 0
        if (-not [double]::TryParse($numberText, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -or
            [double]::IsNaN($number) -or [double]::IsInfinity($number)) {
            throw "$Label contains a non-finite or out-of-range JSON number."
        }
        return [pscustomobject]@{ Value = $number }
    } finally {
        $State.Depth--
    }
}

function ConvertFrom-StrictJsonText {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $state = [pscustomobject]@{ Text = $Text; Index = 0; Depth = 0 }
    $token = Read-StrictJsonValueToken -State $state -Label $Label
    Skip-StrictJsonWhitespace -State $state
    if ($state.Index -ne $state.Text.Length) {
        throw "$Label contains trailing JSON content at character $($state.Index)."
    }
    Write-Output -NoEnumerate $token.Value
}

