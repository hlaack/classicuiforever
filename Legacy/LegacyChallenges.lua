local _, ns = ...
local L = ns.L

-- The Legacy window's challenges page, in the old trade skill window's shape (Skills/SkillShell.lua): the challenge
-- categories as folding headers, each challenge with the Legacy Points it gives, a filter for completed ones, and the
-- picked challenge below with its steps. Read from the client's achievement data, which holds the Legacy challenges.

local LG = ns.legacy
local Text = LG.Text
local SkillList = ns.SkillList

local LegacyConsts = Constants and Constants.LegacyConsts or ns.EMPTY
local POINTS_CURRENCY = LegacyConsts.LEGACY_POINTS_TRAIT_CURRENCY_ID or 4225
local TRACK_FACTION = LegacyConsts.LEGACY_REWARD_TRACK_FACTION_ID or 2802
-- The page inside the window's metal, from under its title band to the foot.
local PANEL_LEFT, PANEL_TOP, PANEL_RIGHT, PANEL_BOTTOM = 14, -12, 346, -440
local STONE_TOP = -50
local LIST_ROWS = 10
local CRITERIA_LINE = 13
-- The detail pane's text width: the page less the pane's scroll column.
local CONTENT_W = PANEL_RIGHT - PANEL_LEFT - 26
local DONE_COLOR = { 0.5, 0.5, 0.5 }
local OPEN_COLOR = { 1, 1, 1 }
local HEADER_COLOR = { 1, 0.82, 0 }

local panel, detail
local lines, collapsed = {}, {}
local show = { completed = true, incomplete = true }
local selected
local criteria = {}

-- Legacy Points a challenge gives; nil when the client cannot say.
local function PointsFor(id)
    local get = C_Traits and C_Traits.GetTraitCurrencyForAchievement
    if not get then return nil end
    local ok, points = pcall(get, POINTS_CURRENCY, id)
    return ok and type(points) == "number" and points or nil
end

local function ReadCategory(category)
    local total = GetCategoryNumAchievements(category) or 0
    local items, done = {}, 0
    for index = 1, total do
        local id, name, _, completed, month, day, year, description, _, icon = GetAchievementInfo(category, index)
        if id then
            if completed then done = done + 1 end
            if (completed and show.completed) or (not completed and show.incomplete) then
                items[#items + 1] = { id = id, name = name or "", completed = completed and true or false, description = description,
                    icon = icon, month = month, day = day, year = year, points = PointsFor(id) }
            end
        end
    end
    return items, done, total
end

-- The list: a header per category with challenges left by the filter, its challenges under it unless folded.
local function Collect()
    wipe(lines)
    local first, still
    for _, category in ipairs(GetCategoryList and GetCategoryList() or ns.EMPTY) do
        local items, done, total = ReadCategory(category)
        if #items > 0 then
            lines[#lines + 1] = { header = true, id = category, name = GetCategoryInfo(category) or "", done = done, total = total }
            if not collapsed[category] then
                for _, item in ipairs(items) do
                    lines[#lines + 1] = item
                    first = first or item.id
                    if item.id == selected then still = true end
                end
            end
        end
    end
    if not still then selected = first end
end

local function DrawItem(row, line)
    row.toggle:Hide()
    row.text:SetPoint("LEFT", row, "LEFT", 26, 0)
    row.text:SetText(line.name)
    SkillList.Paint(row, line.id == selected, line.completed and DONE_COLOR or OPEN_COLOR)
end

-- The right column: a header's count done, a challenge's points.
local function DrawCounts()
    for _, row in ipairs(panel.rows) do
        local line = row.line
        if line and line.header then
            row.points:SetText(line.done .. "/" .. line.total)
            row.points:SetTextColor(HEADER_COLOR[1], HEADER_COLOR[2], HEADER_COLOR[3])
        elseif line then
            row.points:SetText(line.points or "")
            local color = line.completed and DONE_COLOR or HEADER_COLOR
            row.points:SetTextColor(color[1], color[2], color[3])
        end
    end
end

local function UpdateRows()
    if not panel then return end
    SkillList.Draw(panel, lines, collapsed, DrawItem)
    DrawCounts()
    panel.bar:SetRange(math.max(0, #lines - LIST_ROWS))
    SkillList.FoldIcon(panel, lines, collapsed)
    panel.none:SetShown(#lines == 0)
end

local UpdateDetail

local function Row_OnClick(self, button)
    local line = self.line
    if not line then return end
    if SkillList.Fold(line, collapsed) then return LG.Refresh() end
    if button == "LeftButton" and IsModifiedClick("CHATLINK") then
        local link = GetAchievementLink and GetAchievementLink(line.id)
        if link and not ns.IsSecret(link) then ChatFrameUtil.InsertLink(link) end
        return
    end
    selected = line.id
    UpdateRows()
    UpdateDetail()
end

local function CreateRow(list, index)
    local row = ns.SkillListRow(list, index, Row_OnClick)
    row.points = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.points:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.points:SetJustifyH("RIGHT")
    row.text:SetPoint("RIGHT", row.points, "LEFT", -6, 0)
    return row
end

local function SelectedLine()
    for _, line in ipairs(lines) do
        if not line.header and line.id == selected then return line end
    end
end

----------------------------------------------------------------- the detail

local function CriteriaLine(index)
    local fs = criteria[index]
    if fs then return fs end
    fs = detail.content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    criteria[index] = fs
    return fs
end

-- The steps in two columns under the description; one counted step gets the rimmed bar instead. Returns the height used.
local function DrawCriteria(id, top)
    local count = GetAchievementNumCriteria and GetAchievementNumCriteria(id) or 0
    local width = (CONTENT_W - 42) / 2
    local shown = 0
    detail.progress:Hide()
    for _, fs in ipairs(criteria) do fs:Hide() end
    for index = 1, count do
        local text, _, done, quantity, required, _, _, _, quantityText = GetAchievementCriteriaInfo(id, index)
        if count == 1 and type(required) == "number" and required > 1 and type(quantity) == "number" then
            local bar = detail.progress
            bar:SetPoint("TOPLEFT", detail.content, "TOPLEFT", 22, top - 4)
            bar.fill:SetMinMaxValues(0, required)
            bar.fill:SetValue(math.min(quantity, required))
            bar.text:SetText(quantityText ~= "" and quantityText or (quantity .. " / " .. required))
            bar:Show()
            return 24
        end
        if type(text) == "string" and text ~= "" then
            shown = shown + 1
            local fs = CriteriaLine(shown)
            local column, rowIndex = (shown - 1) % 2, math.floor((shown - 1) / 2)
            fs:SetPoint("TOPLEFT", detail.content, "TOPLEFT", 21 + column * (width + 4), top - rowIndex * CRITERIA_LINE)
            fs:SetWidth(width)
            fs:SetText(text)
            if done then fs:SetTextColor(0.1, 1, 0.1) else fs:SetTextColor(DONE_COLOR[1], DONE_COLOR[2], DONE_COLOR[3]) end
            fs:Show()
        end
    end
    return math.ceil(shown / 2) * CRITERIA_LINE
end

local function DoneText(line)
    if not line.completed then return "" end
    local date = FormatShortDate and line.day and FormatShortDate(line.day, line.month, line.year)
        or (line.month and string.format("%d/%d/%02d", line.month, line.day, line.year)) or ""
    return "    |cff1aff1a" .. string.format(L["LEGACY_COMPLETED_ON"], date) .. "|r"
end

UpdateDetail = function()
    if not detail then return end
    local line = SelectedLine()
    detail.content:SetShown(line ~= nil)
    if not line then return end
    detail.icon:SetTexture(line.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    detail.icon:SetDesaturated(not line.completed)
    detail.name:SetText(line.name)
    local points = line.points and string.format(L["LEGACY_POINTS"], "|cffffffff" .. line.points .. "|r") or ""
    detail.requires:SetText(points .. DoneText(line))
    detail.text:SetText(line.description or "")
    local top = -62 - math.ceil(detail.text:GetStringHeight()) - 8
    local height = -top + DrawCriteria(line.id, top) + 10
    detail.content:SetHeight(math.max(height, detail.scroll:GetHeight()))
    local over = math.max(0, height - detail.scroll:GetHeight())
    detail.bar:SetRange(over, 20)
    detail.scroll:SetVerticalScroll(math.min(detail.bar:GetValue() or 0, over))
end

local function Icon_OnEnter(self)
    local link = selected and GetAchievementLink and GetAchievementLink(selected)
    if not link then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end

-- The picked challenge in a scrolling pane: icon, name, points and date, description, steps.
local function BuildDetail()
    local box = panel.detail
    local scroll = ns.NewFrame("ScrollFrame", nil, box)
    scroll:SetPoint("TOPLEFT", box, "TOPLEFT", 0, -4)
    scroll:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -26, 8)
    scroll:EnableMouseWheel(true)
    local content = ns.NewFrame("Frame", nil, scroll)
    content:SetSize(CONTENT_W, 1)
    scroll:SetScrollChild(content)
    detail = content
    detail.content, detail.scroll = content, scroll
    ns.ShellDetailHeader(detail, Icon_OnEnter)
    detail.text = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    detail.text:SetPoint("TOPLEFT", content, "TOPLEFT", 21, -62)
    detail.text:SetPoint("RIGHT", content, "RIGHT", -16, 0)
    detail.text:SetJustifyH("LEFT")
    detail.progress = ns.RimBar(content, 15)
    detail.progress:SetWidth(CONTENT_W - 44)
    local fill = ns.NewFrame("StatusBar", nil, detail.progress)
    fill:SetPoint("TOPLEFT", detail.progress, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", detail.progress, "BOTTOMRIGHT", -1, 1)
    ns.SetBarFill(fill)
    fill:SetStatusBarColor(0, 0.6, 0.1)
    detail.progress.fill = fill
    detail.progress.text:SetParent(fill)
    detail.progress:Hide()
    detail.bar = ns.ClassicScrollBar(box, scroll, function(value) scroll:SetVerticalScroll(value or 0) end)
    ns.ScrollColumnOn(detail.bar)
    detail.bar.hideWhenIdle = true
    scroll:SetScript("OnMouseWheel", function(_, delta)
        detail.bar:SetValue((detail.bar:GetValue() or 0) - delta * 20)
    end)
end

----------------------------------------------------------------- the page

local function Refresh(frame)
    Collect()
    UpdateRows()
    UpdateDetail()
    -- The window's points bar: earned, out of all the challenges give.
    local earned = C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel and C_MajorFactions.GetCurrentRenownLevel(TRACK_FACTION)
    local most = C_Traits.GetMaxAvailableTraitCurrency and C_Traits.GetMaxAvailableTraitCurrency(POINTS_CURRENCY, false)
    frame.spent:SetText(type(earned) == "number" and type(most) == "number"
        and string.format(L["LEGACY_EARNED"], "|cffffffff" .. earned .. "|r", "|cffffffff" .. most .. "|r") or "")
end

local function FilterItem(key, global, fallback)
    return { Text(global, fallback), function()
        show[key] = not show[key]
        LG.Refresh()
    end, function() return show[key] end }
end

local function BuildFilter()
    panel.filter:SetScript("OnClick", function(self)
        if not panel.filterList then
            panel.filterList = ns.DropList({
                FilterItem("completed", "ACHIEVEMENTFRAME_FILTER_COMPLETED", "LEGACY_SHOW_COMPLETED"),
                FilterItem("incomplete", "ACHIEVEMENTFRAME_FILTER_INCOMPLETE", "LEGACY_SHOW_INCOMPLETE"),
            })
            panel.filterList:Follow(panel)
        end
        panel.filterList:Toggle(self)
    end)
end

local function Build(frame)
    panel = ns.NewFrame("Frame", nil, frame)
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", PANEL_LEFT, PANEL_TOP)
    panel:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", PANEL_RIGHT, PANEL_BOTTOM)
    -- Stone from under the points bar to the foot, over the talent art's painted tree and foot.
    local stone = panel:CreateTexture(nil, "BACKGROUND")
    stone:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, STONE_TOP)
    stone:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    ns.TileTex(stone, "rockBg")
    ns.OldSkillShell(panel, { rows = LIST_ROWS, createRow = CreateRow, onScroll = UpdateRows })
    panel.bar.hideWhenIdle = true
    panel.collapseAll:SetScript("OnClick", function()
        SkillList.FoldAll(lines, collapsed)
        LG.Refresh()
    end)
    BuildFilter()
    panel.none = panel.list:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    panel.none:SetPoint("CENTER", panel.list, "CENTER", 0, 0)
    panel.none:SetText(L["LEGACY_NO_CHALLENGES"])
    BuildDetail()
    local close = ns.PanelButton(panel, CLOSE or "Close", 84)
    close:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 11)
    close:SetScript("OnClick", function() frame:Hide() end)
    panel:Hide()
end

local function Shown(_, on)
    panel:SetShown(on)
end

LG.AddPage({
    key = "challenges", icon = "Interface\\Icons\\Achievement_GuildPerk_HonorableMention",
    tip = { "LEGACY_CHALLENGE_TAB_TOOLTIP", "LEGACY_CHALLENGES" }, title = { "LEGACY_CHALLENGE_FRAME_TITLE", "LEGACY_CHALLENGES" },
    -- Challenges earned and their steps' progress; points earned.
    events = { "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" },
    build = Build, shown = Shown, refresh = Refresh,
})
