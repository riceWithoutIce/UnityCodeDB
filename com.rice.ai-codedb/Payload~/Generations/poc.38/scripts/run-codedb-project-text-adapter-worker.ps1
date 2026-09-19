#requires -Version 5.1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BuilderPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-WorkerMessage {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Value
    )

    $json = [pscustomobject]$Value | ConvertTo-Json -Compress -Depth 8
    [System.Console]::Out.WriteLine($json)
    [System.Console]::Out.Flush()
}

$builderFullPath = [System.IO.Path]::GetFullPath($BuilderPath)
if (-not (Test-Path -LiteralPath $builderFullPath -PathType Leaf)) {
    throw "Missing text adapter builder: $builderFullPath"
}
if (-not [string]::Equals(
        [System.IO.Path]::GetExtension($builderFullPath),
        ".ps1",
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Persistent text adapter worker requires a PowerShell builder: $builderFullPath"
}

Write-WorkerMessage -Value ([ordered]@{
    schema_version = 1
    type = "ready"
    worker_pid = $PID
    builder_path = $builderFullPath
})

while ($null -ne ($requestLine = [System.Console]::In.ReadLine())) {
    if ([string]::IsNullOrWhiteSpace($requestLine)) {
        continue
    }

    $requestId = $null
    $capturedOutput = @()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $request = $requestLine | ConvertFrom-Json
        $requestId = [string]$request.request_id
        $reason = [string]$request.reason
        if ([int]$request.schema_version -ne 1 -or
            -not [string]::Equals([string]$request.action, "build", [System.StringComparison]::Ordinal) -or
            [string]::IsNullOrWhiteSpace($requestId) -or
            $reason -notin @("Manual", "Automatic")) {
            throw "Unsupported text adapter worker request."
        }

        $capturedOutput = @(& $builderFullPath -Reason $reason 2>&1 3>&1 4>&1 5>&1 6>&1)
        $buildSucceeded = $?
        if (-not $buildSucceeded) {
            throw "Text adapter builder returned a failed PowerShell status."
        }

        $stopwatch.Stop()
        Write-WorkerMessage -Value ([ordered]@{
            schema_version = 1
            type = "build_completed"
            request_id = $requestId
            worker_pid = $PID
            elapsed_ms = $stopwatch.ElapsedMilliseconds
            output = (@($capturedOutput | ForEach-Object { [string]$_ }) -join [System.Environment]::NewLine).Trim()
        })
    } catch {
        $stopwatch.Stop()
        Write-WorkerMessage -Value ([ordered]@{
            schema_version = 1
            type = "build_failed"
            request_id = $requestId
            worker_pid = $PID
            elapsed_ms = $stopwatch.ElapsedMilliseconds
            error = $_.Exception.Message
            output = (@($capturedOutput | ForEach-Object { [string]$_ }) -join [System.Environment]::NewLine).Trim()
        })
    }
}
