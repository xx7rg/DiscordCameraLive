@echo off
setlocal
title DiscordCameraLive standalone

rem O PowerShell recusa script baixado da internet por padrao. O -ExecutionPolicy Bypass vale
rem so para este processo: nao mexe na politica da maquina.
rem
rem Mantido por x7rG

set "GLB_SCRIPT=%~dp0DiscordCameraLive-Standalone.ps1"

if not exist "%GLB_SCRIPT%" (
    echo.
    echo   Nao achei o DiscordCameraLive-Standalone.ps1 nesta pasta.
    echo   Baixe a pasta standalone inteira: o .ps1 e o discordcameralive.js precisam estar juntos.
    echo.
    pause
    exit /b 1
)

if not exist "%~dp0discordcameralive.js" (
    echo.
    echo   Nao achei o discordcameralive.js nesta pasta.
    echo   Ele e o bypass em si; sem ele o instalador nao tem o que instalar.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%GLB_SCRIPT%" %*

echo.
pause
