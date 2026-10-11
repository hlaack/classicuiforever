local _, ns = ...
local L = ns.L

-- The Legacy window's reward track page as Era's Skills tab (UI/EraSkills.lua): each milestone a folding section, each
-- reward a skill bar of the points toward it, the picked one in the detail pane; the next reward beside the All tab.
-- Read from the client's reward track (its level is the Legacy Points earned), so milestones and rewards follow it.

local LG = ns.legacy

-- Window coordinates beside Era's All tab, on its middle line.
local NEXT_X, NEXT_Y = 142, -61
local WHITE = "|cffffffff%s|r"

local page
local lines, collapsed = {}, {}
local selected
-- The next milestone's section, to scroll to as the page opens.
local nextIndex

----------------------------------------------------------------- the data

-- The track's milestones, each { level, earned, rewards }; nil before the client has the track.
local function ReadTrack()
    local factions = C_MajorFactions
    if not (factions and factions.GetRenownLevels and factions.GetRenownRewardsForLevel) then return nil end
    local ok, levels = pcall(factions.GetRenownLevels, LG.TRACK_FACTION)
    if not ok or type(levels) ~= "table" or #levels == 0 then return nil end
    local earned = LG.Earned() or 0
    local track = { earned = earned, milestones = {} }
    for _, info in ipairs(levels) do
        local okRewards, rewards = pcall(factions.GetRenownRewardsForLevel, LG.TRACK_FACTION, info.level)
        track.milestones[#track.milestones + 1] = { level = info.level, earned = earned >= info.level,
            rewards = okRewards and type(rewards) == "table" and rewards or ns.EMPTY }
    end
    return track
end

-- An item reward's details can arrive late: the page draws again then.
local function RewardLoaded()
    ns.Sched.NextFrame("legacy.refresh", LG.Refresh)
end

-- A reward's icon, name and description, by the game's own reading where this client has it.
local function RewardText(reward)
    local util = RenownRewardUtil
    if util and util.GetRenownRewardInfo then
        local ok, icon, name, description = pcall(util.GetRenownRewardInfo, reward, RewardLoaded)
        if ok then return icon or reward.icon, name or reward.name, description or reward.description end
    end
    return reward.icon, reward.name, reward.description
end

-- Era's list: a section per milestone, its rewards under it unless folded. The next reward is picked by default.
local function Collect(track)
    wipe(lines)
    nextIndex = nil
    local first, still
    for _, milestone in ipairs(track.milestones) do
        local level = milestone.level
        lines[#lines + 1] = { header = true, id = level, name = string.format(L["LEGACY_MILESTONE"], level),
            expanded = not collapsed[level] }
        if not milestone.earned and not nextIndex then nextIndex = #lines end
        if not collapsed[level] then
            for i, reward in ipairs(milestone.rewards) do
                local _, name, description = RewardText(reward)
                local line = { id = level .. ":" .. i, name = name or "", description = description, reward = reward,
                    level = level, rank = math.min(track.earned, level), most = level, count = true }
                lines[#lines + 1] = line
                if line.id == selected then still = true end
                if not milestone.earned then first = first or line.id end
            end
        end
    end
    if not still then selected = first or (lines[2] and lines[2].id) end
    for _, line in ipairs(lines) do line.selected = not line.header and line.id == selected end
end

local function Detail()
    for _, line in ipairs(lines) do
        if line.selected then
            return { name = line.name, rank = line.rank, most = line.most, count = true,
                cost = string.format(L["LEGACY_MILESTONE"], string.format(WHITE, line.level)), words = line.description }
        end
    end
end

-- The words beside the All tab: the next milestone, or all earned.
local function DrawNext(track)
    for _, milestone in ipairs(track.milestones) do
        if not milestone.earned then
            page.next:SetText(string.format(L["LEGACY_NEXT_REWARD"], string.format(WHITE, milestone.level)))
            return
        end
    end
    page.next:SetText(L["LEGACY_ALL_EARNED"])
end

local function Refresh()
    if not page then return end
    LG.DrawEarned(page)
    local track = ReadTrack()
    page.next:SetShown(track ~= nil)
    if track then
        Collect(track)
        DrawNext(track)
    else
        wipe(lines)
    end
    page.lines = lines
    page:Draw()
    page:DrawDetail(Detail())
    -- First drawn since the page showed: open at the next milestone.
    if page.toNext then
        page.toNext = false
        page.scroll:SetValue(math.max(0, (nextIndex or 1) - 1))
    end
end

----------------------------------------------------------------- the page

local function Reward_OnEnter(line, region)
    local reward = line.reward
    GameTooltip:SetOwner(region, "ANCHOR_RIGHT")
    local spellID = reward.spellID
    if reward.mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
        spellID = select(2, C_MountJournal.GetMountInfoByID(reward.mountID))
    end
    if reward.itemID then
        GameTooltip:SetItemByID(reward.itemID)
    elseif spellID then
        GameTooltip:SetSpellByID(spellID)
    else
        GameTooltip:SetText(line.name, 1, 1, 1)
        if line.description then GameTooltip:AddLine(line.description, 1, 0.82, 0, true) end
    end
    GameTooltip:Show()
end

local function RewardLink(reward)
    if reward.itemID then return select(2, C_Item.GetItemInfo(reward.itemID)) end
    if reward.spellID then return C_Spell.GetSpellLink(reward.spellID) end
end

local SPEC = {
    collapsed = collapsed,
    pick = function(line) selected = line.id end,
    link = function(line) return RewardLink(line.reward) end,
    onEnter = Reward_OnEnter,
}

local function Build(window)
    page = LG.EraPage(window, SPEC)
    page.empty:SetText(L["LEGACY_TRACK_LOCKED"])
    page.next = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    page.next:SetPoint("LEFT", page, "TOPLEFT", NEXT_X, NEXT_Y)
end

local function Shown(_, on)
    page:SetShown(on)
    if on then page.toNext = true end
end

LG.AddPage({
    key = "rewards", tab = 1, icon = "Interface\\Icons\\UI_Chat",
    tip = { "LEGACY_REWARD_TRACK_TAB_TOOLTIP", "LEGACY_REWARD_TRACK" }, title = { "LEGACY_TRACK_FRAME_TITLE", "LEGACY_REWARD_TRACK" },
    -- Points earned move the track; the track's own data can arrive after login.
    events = { "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "MAJOR_FACTION_UNLOCKED", "UPDATE_FACTION" },
    build = Build, shown = Shown, refresh = Refresh,
})
