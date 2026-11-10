-- BG Guilds 0.2.0 for WotLK 3.3.5a (Warmane)
-- Adds a Guild column to the battleground scoreboard (10v10, 15v15, 40v40; scrolls with it).
-- Sources, best first: seen live in game (cache) > armory snapshot (BGGuilds_Data).
-- Only certain matches are shown; players we don't know get an empty cell.
--
-- Layout notes (from Blizzard's 3.3.5 WorldStateFrame.xml):
--   Name header: 175 wide, LEFT on the Class header (frame x=18). Every stat header chains off
--   its RIGHT edge, and every row's stat text anchors to its header, so widening the Name header
--   shifts the whole scoreboard right. WorldStateScoreFrame_Resize() sizes the frame from
--   WorldStateScoreFrameName:GetWidth(), so the frame grows by itself.
--   Rows: WorldStateScoreButtonN at frame x=17; the row's Name frame sits at row x=20.

local GUILD_W = 135                 -- width added for the Guild column
local NAME_W = 175                  -- Blizzard's Name header width
local NAME_TEXT_W = 140             -- row name text, narrowed so it never runs into the guild
local GUILD_X = NAME_W + 2          -- guild column start, from the Name header's left edge
local ROW_GUILD_X = (18 + GUILD_X) - (17 + 20)   -- same column, from the row's Name frame
local CACHE_TTL = 60 * 24 * 3600    -- live sightings stay trusted for 60 days

local myRealm
local cells = {}

-- ---------------------------------------------------------------- lookup

local function splitName(full)
  local n, r = full:match("^([^%-]+)%-(.+)$")
  if n then return n, r end
  return full, nil
end

local function dbGet(name, realm)
  local db = BGGuilds_DB
  local t = db and db.realms and db.realms[realm]
  local idx = t and t[name]
  return idx and db.guilds[idx]
end

local function cacheGet(name, realm)
  local c = BGGuildsCache and BGGuildsCache[realm]
  local e = c and c[name]
  if e and (time() - e.t) < CACHE_TTL then return e.g end
end

local function lookup(full)
  local name, realm = splitName(full)
  local r = realm or myRealm
  return cacheGet(name, r) or dbGet(name, r)
end

-- ---------------------------------------------------------------- learning from live units

local function learn(unit)
  if not UnitExists(unit) or not UnitIsPlayer(unit) then return end
  local name, realm = UnitName(unit)
  if not name or name == UNKNOWNOBJECT then return end
  if not realm or realm == "" then realm = myRealm end
  local g = GetGuildInfo(unit)
  if not g then return end   -- nil = guildless OR not loaded yet; only record positives
  BGGuildsCache[realm] = BGGuildsCache[realm] or {}
  local e = BGGuildsCache[realm][name]
  if e and e.g == g then e.t = time() else BGGuildsCache[realm][name] = { g = g, t = time() } end
end

local function scanRaid()
  for i = 1, GetNumRaidMembers() do
    learn("raid" .. i)
    learn("raid" .. i .. "target")
  end
end

-- ---------------------------------------------------------------- scoreboard column

local function setupScoreboard()
  if not (WorldStateScoreFrame and WorldStateScoreFrameName and WorldStateScoreFrame_Update) then return end

  WorldStateScoreFrameName:SetWidth(NAME_W + GUILD_W)

  local header = WorldStateScoreFrame:CreateFontString("BGGuildsHeader", "ARTWORK", "GameFontHighlightSmall")
  header:SetPoint("LEFT", WorldStateScoreFrameName, "LEFT", GUILD_X, 0)
  header:SetJustifyH("LEFT")
  header:SetText("Guild")

  local rows = MAX_WORLDSTATE_SCORE_BUTTONS or 20
  for i = 1, rows do
    local nameFrame = _G["WorldStateScoreButton" .. i .. "Name"]
    local nameText = _G["WorldStateScoreButton" .. i .. "NameText"]
    if nameFrame then
      local fs = nameFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", nameFrame, "LEFT", ROW_GUILD_X, 0)
      fs:SetWidth(GUILD_W - 8)
      fs:SetHeight(16)
      fs:SetJustifyH("LEFT")
      fs:SetTextColor(0.82, 0.82, 0.82)
      cells[i] = fs
    end
    if nameText then nameText:SetWidth(NAME_TEXT_W) end
  end

  -- Runs after every scoreboard refresh: opening it, score updates, faction tabs, scrolling.
  hooksecurefunc("WorldStateScoreFrame_Update", function()
    local offset = WorldStateScoreScrollFrame and FauxScrollFrame_GetOffset(WorldStateScoreScrollFrame) or 0
    for i, fs in pairs(cells) do
      local name = GetBattlefieldScore(offset + i)
      fs:SetText(name and lookup(name) or "")
    end
  end)
end

-- ---------------------------------------------------------------- demo (see it without queueing)

local demo
local function stopDemo()
  if not demo then return end
  GetNumBattlefieldScores, GetBattlefieldScore = demo.num, demo.score
  demo = nil
  WorldStateScoreFrame:Hide()
  print("|cffffcc00BG Guilds:|r demo closed. Type /reload before your next battleground.")
end

local function startDemo()
  local t = BGGuilds_DB and BGGuilds_DB.realms and (BGGuilds_DB.realms[myRealm] or BGGuilds_DB.realms.Icecrown)
  if not t then print("|cffffcc00BG Guilds:|r no data loaded (is BGGuilds_Data enabled?)") return end
  local names = {}
  for n in pairs(t) do names[#names + 1] = n end
  local classes = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
  local strangers = { [7] = "Qwertyhunt", [22] = "Frostyorc" }   -- not in the data: empty guild cell
  local rows = {}
  for i = 1, 30 do                                                -- 15v15, scrolls past 20 like a real AB
    rows[i] = { strangers[i] or names[math.random(#names)], math.random(0, 6), math.random(0, 20), math.random(0, 6),
                math.random(100, 400), (i <= 15) and 1 or 0, classes[math.random(#classes)],
                math.random(5, 160) * 1000, math.random(0, 120) * 1000 }
  end
  demo = { num = GetNumBattlefieldScores, score = GetBattlefieldScore }
  GetNumBattlefieldScores = function() return #rows end
  GetBattlefieldScore = function(i)
    local r = rows[i]
    if not r then return end
    return r[1], r[2], r[3], r[4], r[5], r[6], 0, "", "", r[7], r[8], r[9]
  end
  WorldStateScoreFrame:Show()
  print("|cffffcc00BG Guilds:|r demo with real names from the data. /bgg demo again to close.")
end

-- ---------------------------------------------------------------- events

local ev = CreateFrame("Frame")
local inBG, elapsed = false, 0

ev:SetScript("OnUpdate", function(self, dt)
  if not inBG then return end
  elapsed = elapsed + dt
  if elapsed > 1 then elapsed = 0; scanRaid() end
end)

ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ev:RegisterEvent("PLAYER_TARGET_CHANGED")
ev:RegisterEvent("PLAYER_FOCUS_CHANGED")

ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    BGGuildsCache = BGGuildsCache or {}
    BGGuildsSettings = BGGuildsSettings or {}
    myRealm = GetRealmName()
    setupScoreboard()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    local _, kind = IsInInstance()
    inBG = (kind == "pvp" or kind == "arena")
    if inBG then stopDemo() end
  elseif event == "UPDATE_MOUSEOVER_UNIT" then
    learn("mouseover")
  elseif event == "PLAYER_TARGET_CHANGED" then
    learn("target")
  elseif event == "PLAYER_FOCUS_CHANGED" then
    learn("focus")
  end
end)

-- ---------------------------------------------------------------- slash

SLASH_BGGUILDS1 = "/bgg"
SlashCmdList.BGGUILDS = function(msg)
  msg = (msg or ""):lower()
  if msg == "demo" then
    if demo then stopDemo()
    elseif inBG then print("|cffffcc00BG Guilds:|r you're in a battleground, just open the scoreboard.")
    else startDemo() end
  else
    local live = 0
    for _, t in pairs(BGGuildsCache) do for _ in pairs(t) do live = live + 1 end end
    local db = BGGuilds_DB
    print(("|cffffcc00BG Guilds:|r armory data %s (%d characters), %d seen live, realm %s. /bgg demo to preview."):format(
      db and db.version or "missing", db and db.count or 0, live, tostring(myRealm)))
  end
end
