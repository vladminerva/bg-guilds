@echo off
rem BG Guilds updater. Checks GitHub for a newer BG Guilds release and installs it.
rem It only ever writes to Interface\AddOns\BGGuilds and Interface\AddOns\BGGuilds_Data.
setlocal EnableExtensions
set "HOME_DIR=%APPDATA%\BGGuilds"
set "LOG=%HOME_DIR%\update.log"
set "BASE=https://github.com/__REPO__/releases/latest/download"
set "WORK=%TEMP%\BGGuilds-update"

if not exist "%HOME_DIR%\wowdir.txt" exit /b 1
set /p WOW=<"%HOME_DIR%\wowdir.txt"
set "ADDONS=%WOW%\Interface\AddOns"
if not exist "%WOW%\Wow.exe" (
  >>"%LOG%" echo %DATE% %TIME% WoW not found at "%WOW%"
  exit /b 1
)
if not exist "%ADDONS%" mkdir "%ADDONS%"

if exist "%WORK%" rmdir /s /q "%WORK%"
mkdir "%WORK%"

curl.exe -fsSL --max-time 20 -o "%WORK%\version.txt" "%BASE%/version.txt"
if errorlevel 1 (
  >>"%LOG%" echo %DATE% %TIME% offline or GitHub unreachable, kept current version
  goto :done
)
set "REMOTE="
set /p REMOTE=<"%WORK%\version.txt"
set "LOCAL="
if exist "%ADDONS%\BGGuilds_Data\version.txt" set /p LOCAL=<"%ADDONS%\BGGuilds_Data\version.txt"
if "%REMOTE%"=="" goto :done
if "%REMOTE%"=="%LOCAL%" goto :done

curl.exe -fsSL --max-time 180 -o "%WORK%\BGGuilds.zip" "%BASE%/BGGuilds.zip"
if errorlevel 1 (
  >>"%LOG%" echo %DATE% %TIME% download failed, kept %LOCAL%
  goto :done
)
mkdir "%WORK%\x"
tar.exe -xf "%WORK%\BGGuilds.zip" -C "%WORK%\x"
if not exist "%WORK%\x\BGGuilds\BGGuilds.toc" goto :bad
if not exist "%WORK%\x\BGGuilds_Data\Data.lua" goto :bad

robocopy "%WORK%\x\BGGuilds" "%ADDONS%\BGGuilds" /MIR /R:2 /W:2 /NJH /NJS /NFL /NDL /NP >nul
robocopy "%WORK%\x\BGGuilds_Data" "%ADDONS%\BGGuilds_Data" /MIR /R:2 /W:2 /NJH /NJS /NFL /NDL /NP >nul
>>"%LOG%" echo %DATE% %TIME% updated %LOCAL% -^> %REMOTE%
goto :done

:bad
>>"%LOG%" echo %DATE% %TIME% downloaded zip looked wrong, kept %LOCAL%

:done
if exist "%WORK%" rmdir /s /q "%WORK%"
exit /b 0
