@echo off
setlocal

rem Keep this file ASCII-only. cmd.exe decodes .cmd with the legacy GBK code
rem page on Chinese Windows, so UTF-8 Chinese comments can corrupt parsing.

rem Move to the ui directory. pushd handles a drive switch and avoids the
rem "cd /d" argument that some shells rewrite as a path.
pushd "%~dp0..\ui"

if not exist "%CD%\node_modules\vite\bin\vite.js" (
  echo [ERROR] Frontend deps missing: %CD%\node_modules
  echo         Run this in the ui directory first:  pnpm install
  popd
  exit /b 1
)

if "%VITE_DASHBOARD_API_BASE_URL%"=="" set "VITE_DASHBOARD_API_BASE_URL=http://127.0.0.1:2024"
if "%FOREMAN_UI_HOST%"=="" set "FOREMAN_UI_HOST=127.0.0.1"
if "%FOREMAN_UI_PORT%"=="" set "FOREMAN_UI_PORT=3000"

echo Starting frontend: http://%FOREMAN_UI_HOST%:%FOREMAN_UI_PORT%/
node "%CD%\node_modules\vite\bin\vite.js" dev --host %FOREMAN_UI_HOST% --port %FOREMAN_UI_PORT%

popd
endlocal
