@echo off
title Launching FidelLearn Desktop
echo Starting FidelLearn...
powershell -ExecutionPolicy Bypass -File "%~dp0tools\Install-FidelLearn-Desktop.ps1"
pause
