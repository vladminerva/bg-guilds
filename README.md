# BG Guilds

A WotLK 3.3.5a addon for Warmane that adds a Guild column to the battleground scoreboard.

It shows a guild only when it knows it for sure: from a snapshot of the Warmane armory, or because your client saw that player in game (teammates, your target, mouseover, focus, your teammates' targets). Anyone it doesn't know gets an empty cell.

## Install

Download `BGGuilds-installer.zip` from the [latest release](../../releases/latest), unzip it into your WoW folder (next to `Wow.exe`) and run `install-updater.bat`. It installs the addon and adds a small updater to Windows startup, so new guild data arrives by itself every time you log in to Windows. No admin rights, nothing else to install. `uninstall-updater.bat` removes it.

Prefer to do it by hand? Unzip `BGGuilds.zip` into `Interface/AddOns`.

In game: `/bgg demo` opens the scoreboard with sample rows so you can see the column without queueing. `/bgg` shows how much data is loaded.

## How the data is built

`crawl/seed_crawl.py` reads guild rosters from the public Warmane armory API, slowly, within its rate limit. `crawl/build_data.py` writes them to `addon/BGGuilds_Data/Data.lua`. `release.sh` packages and publishes a release.
