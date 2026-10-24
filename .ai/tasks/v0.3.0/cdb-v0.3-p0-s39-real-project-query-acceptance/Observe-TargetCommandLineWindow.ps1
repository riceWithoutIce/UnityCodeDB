param(
    [Parameter(Mandatory=$true)][string]$ProjectRoot,
    [Parameter(Mandatory=$true)][string]$EvidenceRoot,
    [Parameter(Mandatory=$true)][string]$SessionName,
    [Parameter(Mandatory=$true)][guid]$SessionGuid,
    [Parameter(Mandatory=$true)][string]$DesktopLog,
    [Parameter(Mandatory=$true)][switch]$ApprovedLiveWindow
)
$ErrorActionPreference='Stop'
if (!$ApprovedLiveWindow) { throw 'A separately approved live window is required' }
$identity=[Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (!$identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Recorder requires an independent administrator terminal; do not elevate Codex/Unity' }
if ([IntPtr]::Size -ne 8) { throw 'Use x64 PowerShell' }
if ('CodeDB.S39.CommandLineV1.Controller' -as [type]) { throw 'Native type already loaded; refuse possible stale controller' }
Add-Type -Path (Join-Path $PSScriptRoot 'NativeProcessTrace.cs')
. (Join-Path $PSScriptRoot 'CommandLineObserver.Core.ps1')
Invoke-S39CommandLineObservation -ProjectRoot $ProjectRoot -EvidenceRoot $EvidenceRoot `
    -SessionName $SessionName -SessionGuid $SessionGuid -DesktopLog $DesktopLog -ControllerFactory {
        param($name,$path,$id)
        [CodeDB.S39.CommandLineV1.Controller]::CreateNative($name,$path,$id)
    }
