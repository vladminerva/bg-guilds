-- Turn a player's SavedVariables file into a seed list of guilds we don't have yet.
-- Usage: luajit crawl/sightings_to_seeds.lua <BGGuilds.lua from WTF\...\SavedVariables> <addon/BGGuilds_Data/Data.lua> > crawl/seeds-<date>-sightings.txt
-- Output lines: "Guild Name | Realm"  (the format seed_crawl.py reads)
local sv, data = arg[1], arg[2]
assert(sv and data, "usage: luajit sightings_to_seeds.lua <SavedVariables BGGuilds.lua> <Data.lua>")
dofile(data)
dofile(sv)
local cache = BGGuildsCache or {}
local known = {}
for realm, t in pairs(BGGuilds_DB.realms) do
  known[realm] = {}
  for _, idx in pairs(t) do known[realm][BGGuilds_DB.guilds[idx]:lower()] = true end
end
local seen, out, players = {}, {}, 0
for realm, t in pairs(cache) do
  for _, e in pairs(t) do
    players = players + 1
    local key = realm .. "\0" .. e.g
    if not (known[realm] and known[realm][e.g:lower()]) and not seen[key] then
      seen[key] = true
      out[#out + 1] = e.g .. " | " .. realm
    end
  end
end
table.sort(out)
print(("# from sightings: %d players seen, %d new guilds"):format(players, #out))
for _, l in ipairs(out) do print(l) end
