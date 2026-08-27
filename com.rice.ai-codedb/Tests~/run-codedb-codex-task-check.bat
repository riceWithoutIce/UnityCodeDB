@echo off
setlocal EnableExtensions

rem Read-only helper for the real new-Codex-task acceptance gate.
rem Usage: run-codedb-codex-task-check.bat "C:\path\to\UnityProject"

if "%~1"=="" (
    echo Usage: %~nx0 "C:\path\to\UnityProject"
    echo.
    echo The target must be the Unity project root used as the new Codex task cwd.
    exit /b 2
)

set "PROJECT_ROOT=%~f1"
set "CHECK_ROOT=%~dp0"
if not exist "%PROJECT_ROOT%\ProjectSettings\ProjectVersion.txt" (
    echo [FAIL] Unity project marker not found: %PROJECT_ROOT%\ProjectSettings\ProjectVersion.txt
    exit /b 2
)
if not exist "%PROJECT_ROOT%\Packages\manifest.json" (
    echo [FAIL] Unity package manifest not found: %PROJECT_ROOT%\Packages\manifest.json
    exit /b 2
)

pushd "%PROJECT_ROOT%" >nul || (
    echo [FAIL] Could not enter project root: %PROJECT_ROOT%
    exit /b 2
)

for /f "tokens=1,* delims==" %%A in ('%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%CHECK_ROOT%get-codedb-project-mcp-identity.ps1" -ProjectRoot "%PROJECT_ROOT%"') do set "%%A=%%B"
if not defined CODEDB_SERVER_NAME (
    echo [FAIL] Could not derive the project CodeDB MCP identity.
    set "CHECK_FAILED=1"
)

echo CodeDB new-task acceptance preflight
echo ==================================
echo.
echo [PASS] cwd: %CD%

"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
    "$m=Get-Content -LiteralPath 'Packages\manifest.json' -Raw -Encoding UTF8; if ($m -match 'com\.rice\.ai-codedb') { exit 0 } else { exit 1 }"
if errorlevel 1 (
    echo [FAIL] com.rice.ai-codedb is not present in Packages\manifest.json
    set "CHECK_FAILED=1"
) else (
    echo [PASS] com.rice.ai-codedb is present in Packages\manifest.json
)

if exist ".codex\config.toml" (
    echo [INFO] project .codex\config.toml exists ^(content not printed^)
) else (
    echo [WARN] project .codex\config.toml is not present
)

set "SUPERVISOR_STATE=%PROJECT_ROOT%\AIWork\.runtime\codedb\control\supervisor\supervisor-state.json"
if exist "%SUPERVISOR_STATE%" (
    echo [INFO] Supervisor cache exists: AIWork\.runtime\codedb\control\supervisor\supervisor-state.json
    "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
        "$p=$env:SUPERVISOR_STATE; try { $s=Get-Content -LiteralPath $p -Raw -Encoding UTF8 | ConvertFrom-Json; $r=[string]$s.readiness_state; $reason=[string]$s.reason_code; Write-Output ('[INFO] cached Supervisor readiness: ' + $r + ' (' + $reason + ')') } catch { Write-Output ('[WARN] Supervisor cache could not be read: ' + $_.Exception.Message) }"
) else (
    echo [INFO] Supervisor cache is not present; Unity may still be converging.
)

echo.
echo Manual new-Codex-task gate
echo -------------------------
echo 1. Create a NEW Codex task with this exact cwd:
echo    %PROJECT_ROOT%
echo 2. In that task run Get-Location and confirm the path above.
echo 3. Confirm %CODEDB_TOOL_NAMESPACE% tools are exposed.
echo 4. Call %CODEDB_SERVER_NAME% codedb_status and confirm it reports this project as usable.
echo 5. Run one bounded %CODEDB_SERVER_NAME% codedb_text_search query and confirm it succeeds.
echo.
echo This helper does not create a Codex task, edit user config, clear leases,
echo start or stop MCP processes, or invoke CodeDB tools. Its checks are read-only.

popd
if defined CHECK_FAILED exit /b 1
exit /b 0
