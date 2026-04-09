-- GoldTracker.lua
-- Tracks gold for the current character and stores it account-wide.
local addonName, ns = ...

ns.GoldTracker = {}
local GT = ns.GoldTracker

local function SaveCurrentGold()
    local key  = ns.GetCharKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    local _, classFile = UnitClass("player")

    local entry = InfoBotWoWDB.characters[key] or {}
    entry.name     = name
    entry.realm    = realm
    entry.class    = classFile
    entry.gold     = GetMoney()
    entry.lastSeen = time()
    InfoBotWoWDB.characters[key] = entry
end

function GT:OnLogin()
    -- Snapshot session-start gold before any changes this session.
    InfoBotWoWChar.sessionStartGold = GetMoney()

    -- Persist current gold into the account-wide DB.
    SaveCurrentGold()

    -- Update gold whenever money changes.
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_MONEY")
    f:SetScript("OnEvent", function()
        SaveCurrentGold()
    end)
end

function GT:OnLogout()
    SaveCurrentGold()
end

-- Returns the net gold change since the session started (may be negative).
function GT:GetSessionChange()
    return GetMoney() - (InfoBotWoWChar.sessionStartGold or GetMoney())
end

-- Returns a sorted list of all known character entries.
function GT:GetAllCharacters()
    local list = {}
    for key, data in pairs(InfoBotWoWDB.characters) do
        list[#list + 1] = { key = key, data = data }
    end
    table.sort(list, function(a, b)
        -- Current character first, then alphabetical.
        local myKey = ns.GetCharKey()
        if a.key == myKey then return true end
        if b.key == myKey then return false end
        return (a.data.name or "") < (b.data.name or "")
    end)
    return list
end
