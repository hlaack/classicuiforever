local _, ns = ...
local L = ns.L

-- The Legacy window's tree page: Professions, Adventure and Resourcefulness as the talent window's foot tabs, each on
-- an Era talent background. Each tree is its own config, spending the account's Legacy Points; a click stages, Apply
-- commits. Read from the client's tree data, so new or moved perks land where it puts them.

local LG = ns.legacy
local Text = LG.Text

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

local names = {}
local function TreeNames()
    for i, info in ipairs(TREES) do names[i] = Text(info.global, info.key) end
    return names
end

local function ReadTree(index)
    local info = TREES[index]
    local configID = C_Traits.GetConfigIDByTreeID(info.id)
    if not configID then return nil end
    return ns.ReadTraitTree(configID, info.id, { name = Text(info.global, info.key), cell = "auto" })
end

local locked
local function Build(frame)
    locked = frame.child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    locked:SetPoint("CENTER", frame.scroll, "CENTER", 0, 0)
    locked:SetWidth(240)
    locked:SetText(L["LEGACY_LOCKED"])
    locked:Hide()
end

local function Refresh(frame)
    local tree = ReadTree(frame.tabIndex)
    local points = tree and string.format(L["LEGACY_POINTS"], "|cffffffff" .. tree.points .. "|r") or ""
    ns.DrawTalentTab(frame, tree, {
        background = function() return TREES[frame.tabIndex].art end,
        title = Text("LEGACY_TREE_FRAME_TITLE", "LEGACY_TITLE"), points = points, tabNames = TreeNames() })
    -- No config yet: the account has earned no Legacy Point.
    locked:SetShown(tree == nil)
end

local function Shown(frame, on)
    ns.TalentTreeShown(frame, on)
end

local function Learn(tree)
    if C_Traits.CommitConfig then pcall(C_Traits.CommitConfig, tree.configID) end
end

LG.AddPage({
    key = "tree", tab = 3, icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend",
    tip = { "LEGACY_TREE_TAB_TOOLTIP", "LEGACY_TREE_TAB" }, title = { "LEGACY_TREE_FRAME_TITLE", "LEGACY_TITLE" },
    -- Points, perks and staged changes.
    events = { "TRAIT_CONFIG_UPDATED", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_NODE_CHANGED" },
    build = Build, shown = Shown, refresh = Refresh, learn = Learn,
})
