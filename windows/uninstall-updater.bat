@echo off
rem Removes the BG Guilds updater. Leaves the addon folders in place; delete them from Interface\AddOns if you want it gone too.
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if exist "%STARTUP%\BGGuilds-update.cmd" del "%STARTUP%\BGGuilds-update.cmd"
if exist "%APPDATA%\BGGuilds" rmdir /s /q "%APPDATA%\BGGuilds"
echo BG Guilds updater removed. If you added "Play WoW" to your desktop, delete that file too.
pause
