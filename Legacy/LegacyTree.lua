local _, ns = ...
local L = ns.L

-- The Legacy trees in the old talent window (UI/TalentWindow.lua): Professions, Adventure and Resourcefulness as its
-- foot tabs, each tree on an Era talent background. Each tree is its own config, spending the account's Legacy
-- Points; a click stages, Apply commits. Read from the client's tree data, so new or moved perks land where it puts them.

local LegacyConsts = Constants and Constants.LegacyConsts or ns.EMPTY
-- Tree ids, names and backgrounds in the game's tab order. Backgrounds are Era class trees picked for the theme.
local TREES = {
    { id = LegacyConsts.LEGACY_TREE_PROFESSIONS_ID or 1187, global = "LEGACY_TREE_PROFESSIONS", key = "LEGACY_PROFESSIONS",
        art = "DruidRestoration" },
    { id = LegacyConsts.LEGACY_TREE_ADVENTURE_ID or 1188, global = "LEGACY_TREE_ADVENTURE", key = "LEGACY_ADVENTURE",
        art = "HunterBeastMastery" },
    { id = LegacyConsts.LEGACY_TREE_PROGRESSION_ID or 1189, global = "LEGACY_TREE_PROGRESSION", key = "LEGACY_RESOURCEFULNESS",
        art = "WarriorProtection" },
}
-- Points, perks and staged changes; registered only while the window shows.
local TREE_EVENTS = { "TRAIT_CONFIG_UPDATED", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_NODE_CHANGED" }

local frame, watch

-- The game's own wording where this client has it.
local function Text(global, key)
    local text = _G[global]
    if type(text) == "string" and text ~= "" then return text end
    return L[key]
end

local names = {}
local function TreeNames()
    for i, info in ipairs(TREES) do names[i] = Text(info.global, info.key) end
    return names
end

-- The Legacy system needs its trees' configs; a client without them has no Legacy window.
local function Supported()
    return type(C_Traits) == "table" and type(C_Traits.GetConfigIDByTreeID) == "function"
        and type(C_Traits.GetTreeNodes) == "function"
end

local function ReadTree(index)
    local info = TREES[index]
    local configID = C_Traits.GetConfigIDByTreeID(info.id)
    if not configID then return nil end
    return ns.ReadTraitTree(configID, info.id, { name = Text(info.global, info.key), cell = "auto" })
end

local function Background()
    return TREES[frame.tabIndex].art
end

local function Refresh()
    if not frame or not frame:IsShown() then return end
    local tree = ReadTree(frame.tabIndex)
    local points = tree and string.format(L["LEGACY_POINTS"], "|cffffffff" .. tree.points .. "|r") or ""
    ns.DrawTalentTab(frame, tree, { background = Background, title = Text("LEGACY_TREE_FRAME_TITLE", "LEGACY_TITLE"),
        points = points, tabNames = TreeNames() })
    -- No config yet: the account has earned no Legacy Point.
    frame.locked:SetShown(tree == nil)
end

local function RefreshIfShown()
    if frame:IsShown() then Refresh() end
end

local function Learn(tree)
    if C_Traits.CommitConfig then pcall(C_Traits.CommitConfig, tree.configID) end
end

local function Build()
    if frame then return frame end
    frame = ns.TalentWindow("ClassicUIForeverLegacy", { refresh = Refresh, learn = Learn })
    frame.locked = frame.child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.locked:SetPoint("CENTER", frame.scroll, "CENTER", 0, 0)
    frame.locked:SetWidth(240)
    frame.locked:SetText(L["LEGACY_LOCKED"])
    frame.locked:Hide()

    -- A change to a tree is a burst of events: one refresh, next frame.
    watch = ns.EventFrame({}, function()
        ns.Sched.NextFrame("legacy.refresh", RefreshIfShown)
    end)

    frame:SetScript("OnShow", function()
        ns.TalentWindowShown(frame, true)
        ns.RegisterEvents(watch, TREE_EVENTS)
        if SetPortraitTexture then SetPortraitTexture(frame.portrait, "player") end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        Refresh()
    end)
    frame:SetScript("OnHide", function()
        watch:UnregisterAllEvents()
        ns.TalentWindowShown(frame, false)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    end)
    -- After the window's own SetScripts, which wipe earlier hooks.
    ns.RegisterClassicWindow(frame, true)
    ns.CloseOnEscape(frame)
    return frame
end

-- Opens or closes the window; false when this client or session cannot show it (said in chat).
function ns.ToggleLegacy()
    if not Supported() then
        ns.Print(L["CHAT_LEGACY_NOT_HERE"])
        return false
    end
    -- The gamepad cannot navigate our windows (Core/Gamepad.lua).
    if ns.padSession then
        ns.Print(L["CHAT_LEGACY_NO_GAMEPAD"])
        return false
    end
    Build()
    frame:SetShown(not frame:IsShown())
    return true
end
