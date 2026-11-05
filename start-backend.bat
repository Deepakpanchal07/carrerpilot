@echo off
title CareerPilot AI - Backend Server
cd /d "%~dp0backend"
echo ======================================================
echo   Starting CareerPilot AI Backend Server (Port 5000)
echo ======================================================
echo.
node server.js
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Server terminated with error code %errorlevel%.
    pause
)

