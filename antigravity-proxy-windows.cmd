@echo off
setlocal

where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Windows PowerShell was not found.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0antigravity-proxy-windows.ps1"
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
