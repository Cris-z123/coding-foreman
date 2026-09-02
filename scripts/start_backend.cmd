@echo off
setlocal

rem Keep this file ASCII-only. cmd.exe decodes .cmd with the legacy GBK code
rem page on Chinese Windows, so UTF-8 Chinese comments can corrupt parsing.

rem Move to the project root (parent of scripts). pushd handles a drive switch
rem and avoids the "cd /d" argument that some shells rewrite as a path.
pushd "%~dp0.."

set PYTHONUTF8=1
set PYTHONIOENCODING=utf-8

set "PYTHON_BIN=%CD%\.venv\Scripts\python.exe"
if not exist "%PYTHON_BIN%" (
  echo [ERROR] Virtualenv not found: %PYTHON_BIN%
  echo         Run this in the project root first:  uv sync
  popd
  exit /b 1
)

rem Host and port can be overridden by env vars; defaults match start_backend.sh
if "%FOREMAN_BACKEND_HOST%"=="" set "FOREMAN_BACKEND_HOST=127.0.0.1"
if "%FOREMAN_BACKEND_PORT%"=="" set "FOREMAN_BACKEND_PORT=2024"

echo Starting backend: http://%FOREMAN_BACKEND_HOST%:%FOREMAN_BACKEND_PORT%/health
"%PYTHON_BIN%" -m uvicorn agent.src.app:app --host %FOREMAN_BACKEND_HOST% --port %FOREMAN_BACKEND_PORT%

popd
endlocal
