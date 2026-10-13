#requires -Version 5.1

# Scope declaration only. Inventory/preservation is not deletion or readiness
# authority; candidate/action/generation and filesystem checks remain consumers'
# responsibility. Importing this file performs no filesystem or process work.
function Get-CodedbTextAdapterOutputContract {
    $root = 'adapter/text-index'
    [pscustomobject]@{
        RootRelativePath = $root
        LogsRelativePath = "$root/logs"
        TempRelativePath = "$root/tmp"
        RetainedOutputTrees = @("$root/logs", "$root/tmp")
    }
}

function Test-CodedbTextAdapterRetainedOutputPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath, [switch]$DescendantOnly)
    foreach ($tree in (Get-CodedbTextAdapterOutputContract).RetainedOutputTrees) {
        if ((-not $DescendantOnly -and $RelativePath -ceq $tree) -or $RelativePath.StartsWith($tree + '/', [StringComparison]::Ordinal)) {
            return $true
        }
    }
    return $false
}
