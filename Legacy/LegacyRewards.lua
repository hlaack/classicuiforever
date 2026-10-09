local _, ns = ...
local L = ns.L

-- The Legacy window's reward track page: the bar to the next reward, then each milestone down a marble pane with its
-- rewards in the 1.x quest reward buttons (UI/RewardSlot.lua), lit once earned. Read from the client's reward track
-- (its level is the Legacy Points the account has earned), so new milestones and rewards show as the client adds them.

local LG = ns.legacy

local TEXT_W = LG.PANEL_W - 46
-- Two reward buttons plus the gap span the text width, as in the quest log.
local SLOT_GAP = 3
local SLOT_SCALE = (TEXT_W - SLOT_GAP) / 2 / 147
local HEADING_GAP, SLOT_ROW_GAP, MILESTONE_GAP = 6, 4, 12
-- The progress bar and the rewards' pane, this far under the divider's metal.
local BAR_UNDER, PANE_UNDER = 15, 51
-- The scroll column's marble, as bright as the shell's panes.
local RUN_SHADE = 1.35
local BAR_COLOR = { 0.25, 0.35, 0.75 }
local EARNED_COLOR = { 1, 0.82, 0 }
local LOCKED_COLOR = { 0.5, 0.5, 0.5 }
local NAME_COLOR = { 1, 1, 1 }

local panel, pane
local headings, slots = {}, {}
local headingsUsed, slotsUsed = 0, 0
-- The next milestone's heading, to scroll to as the page opens.
local nextHeading

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

----------------------------------------------------------------- the pieces

local function Slot_OnEnter(self)
    local reward = self.reward
    if not reward then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local spellID = reward.spellID
    if reward.mountID and C_MountJournal and C_MountJournal.GetMountInfoByID then
        spellID = select(2, C_MountJournal.GetMountInfoByID(reward.mountID))
    end
    if reward.itemID then
        GameTooltip:SetItemByID(reward.itemID)
    elseif spellID then
        GameTooltip:SetSpellByID(spellID)
    else
        GameTooltip:SetText(self.name:GetText() or "", 1, 1, 1)
        if self.description then GameTooltip:AddLine(self.description, 1, 0.82, 0, true) end
    end
    GameTooltip:Show()
end

local function Slot_OnClick(self)
    local reward = self.reward
    if not (reward and IsModifiedClick("CHATLINK")) then return end
    local link
    if reward.itemID then
        link = select(2, C_Item.GetItemInfo(reward.itemID))
    elseif reward.spellID then
        link = C_Spell.GetSpellLink(reward.spellID)
    end
    if link and not ns.IsSecret(link) then ChatFrameUtil.InsertLink(link) end
end

local function Heading()
    headingsUsed = headingsUsed + 1
    local fs = headings[headingsUsed]
    if not fs then
        fs = pane.child:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetJustifyH("LEFT")
        fs:SetWidth(TEXT_W)
        headings[headingsUsed] = fs
    end
    fs:Show()
    return fs
end

local function Slot()
    slotsUsed = slotsUsed + 1
    local slot = slots[slotsUsed]
    if not slot then
        slot = ns.RewardSlot(pane.child, Slot_OnEnter, Slot_OnClick)
        slot:SetScale(SLOT_SCALE)
        slots[slotsUsed] = slot
    end
    slot:Show()
    return slot
end

local function Release()
    for i = 1, headingsUsed do headings[i]:Hide() end
    for i = 1, slotsUsed do slots[i]:Hide() end
    headingsUsed, slotsUsed, nextHeading = 0, 0, nil
end

----------------------------------------------------------------- the view

-- One milestone under y: its heading, then its rewards two to a row. Returns the y under it.
local function DrawMilestone(milestone, y)
    local heading = Heading()
    ns.SetPointOnce(heading, "TOPLEFT", pane.child, "TOPLEFT", 4, y)
    local color = milestone.earned and EARNED_COLOR or LOCKED_COLOR
    heading:SetText(string.format(L["LEGACY_MILESTONE"], milestone.level))
    heading:SetTextColor(color[1], color[2], color[3])
    if not milestone.earned and not nextHeading then nextHeading = y end
    y = y - math.ceil(heading:GetStringHeight()) - HEADING_GAP
    for i, reward in ipairs(milestone.rewards) do
        local slot = Slot()
        local icon, name, description = RewardText(reward)
        slot.reward, slot.description = reward, description
        slot.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        slot.icon:SetDesaturated(not milestone.earned)
        slot.count:SetText("")
        slot.name:SetText(name or "")
        -- 1.x showed reward names in white; a reward not reached yet is grey.
        local text = milestone.earned and NAME_COLOR or LOCKED_COLOR
        slot.name:SetTextColor(text[1], text[2], text[3])
        -- Offsets in the slot's scaled units.
        local column = (i - 1) % 2
        ns.SetPointOnce(slot, "TOPLEFT", pane.child, "TOPLEFT", (4 + column * (147 * SLOT_SCALE + SLOT_GAP)) / SLOT_SCALE, y / SLOT_SCALE)
        if column == 1 or i == #milestone.rewards then y = y - 41 * SLOT_SCALE - SLOT_ROW_GAP end
    end
    return y - MILESTONE_GAP
end

-- The bar from the last milestone reached to the next, and the words under it.
local function DrawProgress(track)
    local from, to = 0, nil
    for _, milestone in ipairs(track.milestones) do
        if milestone.earned then from = milestone.level elseif not to then to = milestone.level end
    end
    local bar = panel.progress
    if to then
        bar.fill:SetMinMaxValues(from, to)
        bar.fill:SetValue(track.earned)
        bar.text:SetText(track.earned .. " / " .. to)
        panel.next:SetText(string.format(L["LEGACY_NEXT_REWARD"], to))
    else
        bar.fill:SetMinMaxValues(0, 1)
        bar.fill:SetValue(1)
        bar.text:SetText(track.earned)
        panel.next:SetText(L["LEGACY_ALL_EARNED"])
    end
end

local function Refresh(frame)
    LG.ShowEarned(frame)
    Release()
    local track = ReadTrack()
    panel.locked:SetShown(track == nil)
    panel.progress:SetShown(track ~= nil)
    panel.next:SetShown(track ~= nil)
    if not track then
        pane.bar:SetRange(0, 20)
        return
    end
    DrawProgress(track)
    local y = -4
    for _, milestone in ipairs(track.milestones) do y = DrawMilestone(milestone, y) end
    local height = -y
    local view = pane.scroll:GetHeight()
    pane.child:SetHeight(math.max(height, view))
    local over = math.max(0, height - view)
    pane.bar:SetRange(over, 20)
    -- First drawn since the page showed: open at the next reward.
    if panel.toNext then
        panel.toNext = false
        pane.bar:SetValue(math.min(over, math.max(0, -(nextHeading or 0) - 4)))
    end
    pane.scroll:SetVerticalScroll(math.min(pane.bar:GetValue() or 0, over))
end

----------------------------------------------------------------- the page

local function BuildPane()
    local box = ns.SkillInsetBox(panel, 32)
    box:SetPoint("TOPLEFT", panel, "TOPLEFT", -2, LG.METAL_FOOT - PANE_UNDER)
    box:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -17, 33)
    local scroll = ns.NewFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", box, "TOPLEFT", 14, -12)
    scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -8, 10)
    scroll:EnableMouseWheel(true)
    local child = ns.NewFrame("Frame", nil, scroll)
    child:SetSize(TEXT_W + 8, 1)
    scroll:SetScrollChild(child)
    pane = { box = box, scroll = scroll, child = child }
    pane.bar = ns.ClassicScrollBar(panel, scroll, function(value) scroll:SetVerticalScroll(value or 0) end)
    pane.bar:ClearAllPoints()
    pane.bar:SetPoint("TOPLEFT", box, "TOPRIGHT", -9, -27)
    pane.bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", -9, 22)
    pane.bar:SetFrameLevel(box:GetFrameLevel() + 6)
    ns.ScrollColumnOn(pane.bar)
    -- Marble down the column's see-through channel, as the trade skill list's; the pane's border showed through.
    local run = pane.bar:CreateTexture(nil, "BORDER")
    ns.TileTex(run, "marbleBg", nil, RUN_SHADE)
    run:SetAllPoints(pane.bar)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        pane.bar:SetValue((pane.bar:GetValue() or 0) - delta * 30)
    end)
end

local function Build(frame)
    panel = LG.Panel(frame)
    panel.progress = ns.RimBar(panel, 15, BAR_COLOR)
    panel.progress:SetWidth(TEXT_W)
    panel.progress:SetPoint("TOP", panel, "TOP", 0, LG.METAL_FOOT - BAR_UNDER)
    panel.next = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    panel.next:SetPoint("TOP", panel.progress, "BOTTOM", 0, -5)
    BuildPane()
    panel.locked = pane.box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.locked:SetPoint("CENTER", pane.box, "CENTER", 0, 0)
    panel.locked:SetWidth(TEXT_W - 20)
    panel.locked:SetText(L["LEGACY_TRACK_LOCKED"])
    panel.locked:Hide()
    local foot = ns.SkillInsetBox(panel, 20, true)
    foot:SetPoint("TOPLEFT", pane.box, "BOTTOMLEFT", 0, 7)
    foot:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 1, 2)
end

local function Shown(_, on)
    panel:SetShown(on)
    -- Each showing opens at the next reward.
    if on then panel.toNext = true end
end

LG.AddPage({
    key = "rewards", icon = "Interface\\Icons\\UI_Chat",
    tip = { "LEGACY_REWARD_TRACK_TAB_TOOLTIP", "LEGACY_REWARD_TRACK" }, title = { "LEGACY_TRACK_FRAME_TITLE", "LEGACY_REWARD_TRACK" },
    -- Points earned move the track; the track's own data can arrive after login.
    events = { "MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "MAJOR_FACTION_UNLOCKED", "UPDATE_FACTION" },
    build = Build, shown = Shown, refresh = Refresh,
})
