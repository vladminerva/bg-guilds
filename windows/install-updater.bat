@echo off
rem BG Guilds installer. Put this file (and update.bat) in your WoW folder, next to Wow.exe, then double-click it.
rem No admin rights needed. Undo any time with uninstall-updater.bat.
setlocal EnableExtensions
set "WOW=%~dp0"
if "%WOW:~-1%"=="\" set "WOW=%WOW:~0,-1%"
set "HOME_DIR=%APPDATA%\BGGuilds"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

echo.
echo  BG Guilds installer
echo  -------------------
if not exist "%WOW%\Wow.exe" goto :nowow
if not exist "%~dp0update.bat" (
  echo  update.bat is missing. Unzip both files into your WoW folder and run this again.
  goto :end
)
where curl.exe >nul 2>nul || (echo  This Windows has no curl.exe. Windows 10 version 1803 or newer is needed. & goto :end)
where tar.exe >nul 2>nul || (echo  This Windows has no tar.exe. Windows 10 version 1803 or newer is needed. & goto :end)

rem Test that we can write to the AddOns folder (fails under C:\Program Files without admin).
if not exist "%WOW%\Interface\AddOns" mkdir "%WOW%\Interface\AddOns" 2>nul
>"%WOW%\Interface\AddOns\.bgguilds-write-test" echo ok 2>nul
if not exist "%WOW%\Interface\AddOns\.bgguilds-write-test" goto :readonly
del "%WOW%\Interface\AddOns\.bgguilds-write-test"

if not exist "%HOME_DIR%" mkdir "%HOME_DIR%"
>"%HOME_DIR%\wowdir.txt" echo %WOW%
rem "type" makes a fresh copy, so Windows does not treat the updater as a downloaded file at every login.
type "%~dp0update.bat" > "%HOME_DIR%\update.bat"
>"%STARTUP%\BGGuilds-update.cmd" echo @start "" /min cmd /c call "%HOME_DIR%\update.bat"
echo  Updater added to Windows startup: it checks for new guild data every time you log in to Windows.

echo  Installing the addon now...
call "%HOME_DIR%\update.bat"
if exist "%WOW%\Interface\AddOns\BGGuilds_Data\Data.lua" (
  echo  Done. BG Guilds is installed in Interface\AddOns.
  echo  In game: tick "BG Guilds" and "BG Guilds - Data" in the AddOns list, then type /bgg demo to see it.
) else (
  echo  The updater is set up, but the download did not work right now. It will try again at your next Windows login.
  echo  Details are in update.log, in the BGGuilds folder under AppData.
)

echo.
echo  Updater log (last lines):
powershell -NoProfile -Command "Get-Content -Path ($env:APPDATA + '\BGGuilds\update.log') -Tail 3"
echo.
choice /c YN /m " Also put a 'Play WoW' file on your desktop that updates first, then starts WoW"
if errorlevel 2 goto :end
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP=%%D"
if "%DESKTOP%"=="" set "DESKTOP=%USERPROFILE%\Desktop"
> "%DESKTOP%\Play WoW.bat" echo @echo off
>>"%DESKTOP%\Play WoW.bat" echo call "%HOME_DIR%\update.bat"
>>"%DESKTOP%\Play WoW.bat" echo start "" /d "%WOW%" "%WOW%\Wow.exe"
echo  Added "Play WoW" to your desktop.

:end
echo.
pause
exit /b

:nowow
echo  Wow.exe is not in this folder:
echo    "%WOW%"
echo  If you opened it straight from the zip, extract the zip first: right-click it, "Extract All...",
echo  pick your WoW folder (the one with Wow.exe), then run install-updater.bat from there.
goto :end

:readonly
echo  Windows won't let normal programs write to this folder:
echo    "%WOW%"
echo  This happens under C:\Program Files. Move your WoW folder to e.g. C:\Games and run this again.
goto :end
