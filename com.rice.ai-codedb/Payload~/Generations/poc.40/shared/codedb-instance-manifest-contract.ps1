#requires -Version 5.1
# Projection of the 2026-10-07 instance-manifest contract. No filesystem effects.
. (Join-Path $PSScriptRoot 'codedb-strict-json.ps1')

function Assert-CodedbInstanceOriginatingAction {
    param([AllowNull()]$Origin, [string]$Label = 'instance originating action')
    if ($null -eq $Origin) { return }
    if ($Origin -is [Collections.IDictionary]) { $Origin = [pscustomobject]$Origin }
    if ($Origin -isnot [Management.Automation.PSCustomObject]) { throw "$Label must be a JSON object or null." }
    $names = @($Origin.PSObject.Properties | ForEach-Object { $_.Name })
    $expected = @('action', 'action_id', 'operation_id')
    if ($names.Count -ne 3 -or @($names | Where-Object { $expected -cnotcontains $_ }).Count -ne 0) {
        throw "$Label properties do not match the reviewed schema."
    }
    if ($Origin.action -isnot [string] -or $Origin.action -cnotin @('INSTALL', 'UPGRADE', 'REINSTALL') -or
        $Origin.action_id -isnot [string] -or $Origin.action_id -cnotmatch '^[0-9a-f]{32}$' -or
        $Origin.operation_id -isnot [string] -or $Origin.operation_id -cnotmatch '^[0-9a-f]{32}$') {
        throw "$Label identity is invalid."
    }
}

function Get-CodedbInstanceManifestString {
    param([Parameter(Mandatory = $true)]$Properties, [Parameter(Mandatory = $true)][string]$Name)
    if (-not $Properties.ContainsKey($Name) -or $Properties[$Name] -isnot [string]) {
        throw "Instance manifest property $Name must be a JSON string."
    }
    return [string]$Properties[$Name]
}

function Get-CodedbInstanceManifestInt32 {
    param([Parameter(Mandatory = $true)]$Properties, [Parameter(Mandatory = $true)][string]$Name)
    if (-not $Properties.ContainsKey($Name) -or $Properties[$Name] -isnot [int64] -or
        $Properties[$Name] -lt [int]::MinValue -or $Properties[$Name] -gt [int]::MaxValue) {
        throw "Instance manifest property $Name must be a signed 32-bit JSON integer."
    }
    return [int]$Properties[$Name]
}

function Assert-CodedbInstanceManifestFields {
    param([Parameter(Mandatory = $true)]$Properties)
    $integers = @('schema_version', 'payload_sequence', 'bootstrap_protocol')
    $strings = @('managed_by', 'project_identity', 'instance_id', 'instance_relative_path', 'state',
        'package_version', 'payload_version', 'generation_id', 'generation_relative_path',
        'generation_manifest_sha256', 'worker_relative_path', 'worker_sha256', 'created_at_utc', 'verified_at_utc')
    $required = @($integers) + @($strings)
    $allowed = @($required) + @('originating_action')
    if ($Properties -isnot [Collections.IDictionary] -or
        $Properties.Count -lt $required.Count -or $Properties.Count -gt $allowed.Count -or
        @($Properties.Keys | Where-Object { $allowed -cnotcontains $_ }).Count -ne 0) {
        throw 'Instance manifest properties do not match the reviewed schema.'
    }
    foreach ($name in $strings) { $null = Get-CodedbInstanceManifestString -Properties $Properties -Name $name }
    foreach ($name in $integers) { $null = Get-CodedbInstanceManifestInt32 -Properties $Properties -Name $name }
    if ($Properties.ContainsKey('originating_action')) {
        Assert-CodedbInstanceOriginatingAction -Origin $Properties['originating_action']
    }
}

function ConvertFrom-CodedbInstanceManifestJson {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text, [Parameter(Mandatory = $true)][string]$Label)
    if ([Text.Encoding]::UTF8.GetByteCount($Text) -le 0 -or [Text.Encoding]::UTF8.GetByteCount($Text) -gt 128KB -or
        $Text[0] -eq [char]0xFEFF) { throw "$Label size or byte-order mark is invalid." }
    $document = ConvertFrom-StrictJsonText -Text $Text -Label $Label
    if ($document -isnot [Management.Automation.PSCustomObject]) { throw "$Label must be a JSON object." }
    $properties = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($property in $document.PSObject.Properties) { $properties.Add($property.Name, $property.Value) }
    Assert-CodedbInstanceManifestFields -Properties $properties
    return $properties
}
