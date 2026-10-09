local _, ns = ...
local L = ns.L

-- The Legacy window's challenges page as Era's Skills tab (UI/EraSkills.lua): the challenge categories as its folding
-- sections, each challenge a skill bar of its progress, the picked one in the detail pane with its points and steps;
-- a search line and a filter beside the All tab. Read from the client's achievement data, which holds the challenges.

local LG = ns.legacy

local POINTS_CURRENCY = LG.POINTS_CURRENCY
-- Window coordinates beside Era's All tab (it ends near 132).
local SEARCH_X, SEARCH_Y, SEARCH_W = 142, -50, 110
local FILTER_X, FILTER_Y, FILTER_W = 258, -47, 82
local STEP_DONE, STEP_OPEN = "|cff1aff1a", "|cff808080"

local page
local lines, collapsed = {}, {}
local selected
local query = ""
local show = { completed = true, incomplete = true }

-- Legacy Points a challenge gives; nil when the client cannot say.
local function PointsFor(id)
    local get = C_Traits and C_Traits.GetTraitCurrencyForAchievement
    if not get then return nil end
    local ok, points = pcall(get, POINTS_CURRENCY, id)
    return ok and type(points) == "number" and points or nil
end

-- How far along a challenge is: one counted step by its count, else its steps done of all.
local function Progress(id, completed)
    local count = GetAchievementNumCriteria and GetAchievementNumCriteria(id) or 0
    if count == 1 then
        local _, _, done, quantity, required = GetAchievementCriteriaInfo(id, 1)
        if type(required) == "number" and required > 1 and type(quantity) == "number" then
            return math.min(quantity, required), required
        end
        return (done or completed) and 1 or 0, 1
    end
    if count == 0 then return completed and 1 or 0, 1 end
    local done = 0
    for index = 1, count do
        if select(3, GetAchievementCriteriaInfo(id, index)) then done = done + 1 end
    end
    return done, count
end

local function Wanted(name, completed)
    if completed and not show.completed then return false end
    if not completed and not show.incomplete then return false end
    return query == "" or name:lower():find(query, 1, true) ~= nil
end

local function ReadCategory(category)
    local items = {}
    for index = 1, GetCategoryNumAchievements(category) or 0 do
        local id, name, _, completed, month, day, year, description, _, icon = GetAchievementInfo(category, index)
        if id and Wanted(name or "", completed) then
            local value, most = Progress(id, completed)
            items[#items + 1] = { id = id, name = name or "", completed = completed and true or false,
                description = description, icon = icon, month = month, day = day, year = year, points = PointsFor(id),
                rank = value, most = most, count = true }
        end
    end
    return items
end

-- Era's list: a section per category, its challenges under it unless folded; the first shown is picked by default.
local function Collect()
    wipe(lines)
    local first, still
    for _, category in ipairs(GetCategoryList and GetCategoryList() or ns.EMPTY) do
        local items = ReadCategory(category)
        if #items > 0 then
            lines[#lines + 1] = { header = true, id = category, name = GetCategoryInfo(category) or "",
                expanded = not collapsed[category] }
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
    for _, line in ipairs(lines) do line.selected = not line.header and line.id == selected end
end

local function DoneText(line)
    local date = FormatShortDate and line.day and FormatShortDate(line.day, line.month, line.year)
        or (line.month and string.format("%d/%d/%02d", line.month, line.day, line.year)) or ""
    return string.format(L["LEGACY_COMPLETED_ON"], date)
end

-- The detail's words: the description, then each step in green once done.
local function Words(line)
    local parts = { line.description or "" }
    local count = GetAchievementNumCriteria and GetAchievementNumCriteria(line.id) or 0
    if count > 1 then
        parts[#parts + 1] = ""
        for index = 1, count do
            local text, _, done = GetAchievementCriteriaInfo(line.id, index)
            if type(text) == "string" and text ~= "" then parts[#parts + 1] = (done and STEP_DONE or STEP_OPEN) .. text .. "|r" end
        end
    end
    if line.completed then
        parts[#parts + 1] = ""
        parts[#parts + 1] = STEP_DONE .. DoneText(line) .. "|r"
    end
    return table.concat(parts, "\n")
end

local function Detail()
    for _, line in ipairs(lines) do
        if not line.header and line.id == selected then
            local cost = line.points and string.format(L["LEGACY_POINTS"], "|cffffffff" .. line.points .. "|r") or nil
            return { name = line.name, rank = line.rank, most = line.most, count = true, cost = cost, words = Words(line) }
        end
    end
end

local function Refresh()
    if not page then return end
    Collect()
    page.lines = lines
    page:Draw()
    page:DrawDetail(Detail())
    LG.DrawEarned(page)
end

local SPEC = {
    collapsed = collapsed,
    pick = function(line) selected = line.id end,
    link = function(line) return GetAchievementLink and GetAchievementLink(line.id) end,
}

local function SearchBox()
    local box = ns.SearchBox(page, SEARCH_W, SEARCH or "Search")
    box:SetPoint("TOPLEFT", page, "TOPLEFT", SEARCH_X, SEARCH_Y)
    box:SetScript("OnTextChanged", function(self)
        local text = (self:GetText() or ""):lower()
        self.hint:SetShown(text == "")
        self.clear:SetShown(text ~= "")
        if text == query then return end
        query = text
        page.scroll:SetValue(0)
        LG.Refresh()
    end)
end

local function FilterItem(key, global, fallback)
    return { LG.Text(global, fallback), function()
        show[key] = not show[key]
        LG.Refresh()
    end, function() return show[key] end }
end

local function Filter()
    local filter = ns.ShellFilterButton(page)
    filter:SetWidth(FILTER_W)
    filter:SetPoint("TOPLEFT", page, "TOPLEFT", FILTER_X, FILTER_Y)
    local list
    filter:SetScript("OnClick", function(self)
        if not list then
            list = ns.DropList({
                FilterItem("completed", "ACHIEVEMENTFRAME_FILTER_COMPLETED", "LEGACY_SHOW_COMPLETED"),
                FilterItem("incomplete", "ACHIEVEMENTFRAME_FILTER_INCOMPLETE", "LEGACY_SHOW_INCOMPLETE"),
            })
            list:Follow(page)
        end
        list:Toggle(self)
    end)
end

local function Build(window)
    page = LG.EraPage(window, SPEC)
    page.empty:SetText(L["LEGACY_NO_CHALLENGES"])
    SearchBox()
    Filter()
end

local function Shown(_, on)
    page:SetShown(on)
end

LG.AddPage({
    key = "challenges", tab = 2, icon = "Interface\\Icons\\Achievement_GuildPerk_HonorableMention",
    tip = { "LEGACY_CHALLENGE_TAB_TOOLTIP", "LEGACY_CHALLENGES" }, title = { "LEGACY_CHALLENGE_FRAME_TITLE", "LEGACY_CHALLENGES" },
    -- Challenges earned and their steps' progress; points earned.
    events = { "ACHIEVEMENT_EARNED", "CRITERIA_UPDATE", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" },
    build = Build, shown = Shown, refresh = Refresh,
})
