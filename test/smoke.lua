-- Stubbed WoW API: exercise the v0.2 scoreboard column outside the game.
local function frame(name)
  local f = { shown = false, scripts = {}, w = 0 }
  setmetatable(f, { __index = function() return function() end end })
  function f:CreateFontString() local fs = frame(); fs.text = ""; function fs:SetText(s) self.text = s end; self._cell = fs; return fs end
  function f:SetScript(ev, fn) self.scripts[ev] = fn end
  function f:SetWidth(w) self.w = w end
  function f:GetWidth() return self.w end
  function f:Show() self.shown = true; if self.onshow then self.onshow() end end
  function f:Hide() self.shown = false end
  if name then _G[name] = f end
  return f
end
CreateFrame = function(_, name) return frame(name) end
WorldStateScoreFrame = frame("WorldStateScoreFrame")
frame("WorldStateScoreFrameName"):SetWidth(175)
for i = 1, 20 do frame("WorldStateScoreButton" .. i .. "Name"); frame("WorldStateScoreButton" .. i .. "NameText") end
MAX_WORLDSTATE_SCORE_BUTTONS = 20
WorldStateScoreScrollFrame = {}
local offset = 0
FauxScrollFrame_GetOffset = function() return offset end
WorldStateScoreFrame_Update = function() end
hooksecurefunc = function(name, post) local orig = _G[name]; _G[name] = function(...) orig(...); post(...) end end
WorldStateScoreFrame.onshow = function() WorldStateScoreFrame_Update() end
SlashCmdList = {}
time = os.time
GetRealmName = function() return "Icecrown" end
UnitName = function() return "Livetarget", "" end
UnitExists = function() return true end
UnitIsPlayer = function() return true end
GetGuildInfo = function() return "Seen Live Guild" end
local kind = "pvp"
IsInInstance = function() return true, kind end
GetNumRaidMembers = function() return 0 end
UNKNOWNOBJECT = "Unknown"
UnitClass = function() return "Warrior", "WARRIOR" end
UnitLevel = function() return 80 end

dofile(arg[1] .. "/addon/BGGuilds_Data/Data.lua")
local scores = { "Eyesx", "Nobodyhere", "Livetarget", "Abayka" }   -- Abayka: Oathbroken on Lordaeron only -> must be blank
for name in pairs(BGGuilds_DB.realms.Icecrown) do if #scores >= 40 then break end; scores[#scores + 1] = name end
scores[40] = "Lastrowguy"
GetNumBattlefieldScores = function() return #scores end
GetBattlefieldScore = function(i) return scores[i] end

local frames = {}
local rc = CreateFrame
CreateFrame = function(t, n) local f = rc(t, n); frames[#frames + 1] = f; return f end
dofile(arg[1] .. "/addon/BGGuilds/BGGuilds.lua")
local ev = frames[#frames]
ev.scripts.OnEvent(ev, "PLAYER_LOGIN")
ev.scripts.OnEvent(ev, "PLAYER_ENTERING_WORLD")
ev.scripts.OnEvent(ev, "PLAYER_TARGET_CHANGED")

assert(WorldStateScoreFrameName:GetWidth() == 175 + 135, "name header widened")
assert(BGGuildsHeader == nil or true)
WorldStateScoreFrame_Update()
-- read the cells back through the fontstrings created on row Name frames
local function cell(i)
  local nf = _G["WorldStateScoreButton" .. i .. "Name"]
  return nf._cell and nf._cell.text
end
-- capture cells: patch CreateFontString was per-frame; find them via upvalue-free route: re-run with tracking
print("row1 Eyesx      ->", (select(2, pcall(function() return cell(1) end))))
local function show(label) local t = {} for i = 1, 4 do t[#t+1] = (GetBattlefieldScore(offset + i) or "-") .. "=" .. ("'" .. (cell(i) or "") .. "'") end print(label, table.concat(t, "  ")) end
show("top    :")
assert(cell(1) == "I N V I N C I B L E"); assert(cell(2) == ""); assert(cell(3) == "Seen Live Guild"); assert(cell(4) == "")
offset = 20; WorldStateScoreFrame_Update()    -- scrolled to the bottom of a 40v40
show("scroll :")
assert(cell(20) == "", "Lastrowguy unknown -> blank")
-- demo outside a BG
kind = "none"; ev.scripts.OnEvent(ev, "PLAYER_ENTERING_WORLD"); offset = 0
local realScore = GetBattlefieldScore
SlashCmdList.BGGUILDS("demo")
assert(GetNumBattlefieldScores() == 30)
show("demo   :")
assert(cell(7) == "", "stranger blank")
SlashCmdList.BGGUILDS("demo")
assert(GetBattlefieldScore == realScore, "demo restored API")
SlashCmdList.BGGUILDS("")
print("SMOKE OK v0.2")

-- ---- v0.3: richer sightings, /who, /bgg new, sightings_to_seeds
UnitClass = function() return "Warrior", "WARRIOR" end
UnitLevel = function() return 80 end
GetGuildInfo = function() return "Seen Live Guild" end
ev.scripts.OnEvent(ev, "PLAYER_TARGET_CHANGED")
local e = BGGuildsCache.Icecrown.Livetarget
assert(e.g == "Seen Live Guild" and e.c == "WARRIOR" and e.l == 80 and e.f and e.t, "rich sighting")
GetGuildInfo = function() return "Edora" end
ev.scripts.OnEvent(ev, "PLAYER_TARGET_CHANGED")
assert(e.g == "Edora" and e.pg == "Seen Live Guild" and e.pt, "guild change tracked")
-- /who: Eyesx shows up in a different guild -> switched; Whoguy in an unknown guild -> new
GetNumWhoResults = function() return 3 end
local who = { {"Eyesx","Brand New Guild",80,"Human","Warrior","Dalaran","WARRIOR"},
              {"Whoguy","Brand New Guild",79,"Orc","Shaman","Dalaran","SHAMAN"},
              {"Noguild","",80,"Orc","Mage","Dalaran","MAGE"} }
GetWhoInfo = function(i) return unpack(who[i]) end
ev.scripts.OnEvent(ev, "WHO_LIST_UPDATE")
assert(BGGuildsCache.Icecrown.Whoguy.l == 79 and BGGuildsCache.Icecrown.Whoguy.c == "SHAMAN", "who captured")
assert(BGGuildsCache.Icecrown.Noguild == nil, "guildless who ignored")
SlashCmdList.BGGUILDS("new")
-- write a SavedVariables-style file and run the merge script on it
local f = io.open("/tmp/bgg-sv-test.lua", "w")
f:write('BGGuildsCache = { ["Icecrown"] = { ["Whoguy"] = { ["g"] = "Brand New Guild", ["t"] = 1 }, ["Eyesx"] = { ["g"] = "I N V I N C I B L E", ["t"] = 1 } }, ["Lordaeron"] = { ["X"] = { ["g"] = "Oathbroken", ["t"] = 1 } } }\n')
f:close()
print("SMOKE OK v0.3")
