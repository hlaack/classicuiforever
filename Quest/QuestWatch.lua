local _, ns = ...

-- Classic Era's quest watch in place of the game's objective tracker (#98): each watched quest's title and its
-- objectives as plain lines (Era's QuestWatch_Update), under the minimap left of the side bars, below the durability
-- figure while it shows. The game's tracker is parked by Quest/QuestTracker.lua, out of a fight.

local KEY = "questWatch"
local LINE_H, TITLE_GAP, MAX_LINES, PAD_W = 13, 4, 30, 10
-- Era's colors: a title dark gold, gold once every objective is done; an objective grey, white once done.
local TITLE, TITLE_DONE = { 0.75, 0.61, 0 }, { 1, 0.82, 0 }
local GOAL, GOAL_DONE = { 0.8, 0.8, 0.8 }, { 1, 1, 1 }
-- Era's right-side container: 5 in from the side bars, 192 down; the watch 10 under the durability figure.
local SIDE_GAP, TOP_Y, STACK_GAP = 5, -192, 10
local EVENTS = { "QUEST_WATCH_LIST_CHANGED", "QUEST_LOG_UPDATE", "PLAYER_ENTERING_WORLD" }

local home, lines, events, unitEvents
local active = false

local function Line(i)
    local line = lines[i]
    if line then return line end
    line = home:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
    line:SetJustifyH("LEFT")
    line:SetHeight(LINE_H)
    lines[i] = line
    return line
end

-- Its top right corner at Era's spot unless placed in edit mode; offsets in its own scale.
local function Lay()
    if not home or (ns.WindowPlaced and ns.WindowPlaced(KEY)) then return end
    local y = TOP_Y
    local durability = DurabilityFrame
    local bottom = durability and durability:IsVisible() and durability:GetBottom()
    if bottom and not ns.IsSecret(bottom) then
        local k = durability:GetEffectiveScale() / UIParent:GetEffectiveScale()
        y = bottom * k - UIParent:GetHeight() - STACK_GAP
    end
    local side = ns.band and ns.band.SideColumnsWidth and ns.band.SideColumnsWidth() or 0
    local scale = home:GetScale()
    ns.SetPointOnce(home, "TOPRIGHT", UIParent, "TOPRIGHT", -(side + SIDE_GAP) / scale, y / scale)
end

local function Color(line, rgb) line:SetTextColor(rgb[1], rgb[2], rgb[3]) end

-- Era's QuestWatch_Update over the game's watch list; a quest with no objectives is left out, as Era did.
local function Update()
    if not active then return end
    local used, quests, widest = 0, 0, 0
    for i = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(i)
        local goals = questID and C_QuestLog.GetQuestObjectives(questID)
        if goals and #goals > 0 and used + 1 + #goals <= MAX_LINES then
            used, quests = used + 1, quests + 1
            local title = Line(used)
            title:SetText(C_QuestLog.GetTitleForQuestID(questID) or "")
            if used == 1 then
                ns.SetPointOnce(title, "TOPLEFT", home, "TOPLEFT", 0, 0)
            else
                ns.SetPointOnce(title, "TOPLEFT", lines[used - 1], "BOTTOMLEFT", 0, -TITLE_GAP)
            end
            title:Show()
            widest = math.max(widest, title:GetStringWidth())
            local done = 0
            for _, goal in ipairs(goals) do
                used = used + 1
                local line = Line(used)
                line:SetText(" - " .. (goal.text or ""))
                ns.SetPointOnce(line, "TOPLEFT", lines[used - 1], "BOTTOMLEFT", 0, 0)
                Color(line, goal.finished and GOAL_DONE or GOAL)
                if goal.finished then done = done + 1 end
                line:Show()
                widest = math.max(widest, line:GetStringWidth())
            end
            Color(title, done == #goals and TITLE_DONE or TITLE)
        end
    end
    for i = used + 1, #lines do lines[i]:Hide() end
    home:SetShown(used > 0)
    home:SetSize(math.max(1, widest + PAD_W), math.max(1, used * LINE_H + math.max(0, quests - 1) * TITLE_GAP))
    Lay()
end

-- Edit mode's reset and size steps.
function ns.LayQuestWatch(key)
    if key == KEY then Lay() end
end

local function Apply()
    if not home then
        home = CreateFrame("Frame", "ForeverClassicUIQuestWatch", UIParent)
        home:SetFrameStrata("LOW")
        home:SetSize(1, 1)
        lines = {}
        events = ns.EventFrame(EVENTS, Update)
        unitEvents = ns.EventFrame({ "UNIT_QUEST_LOG_CHANGED" }, Update, "player")
        if ns.PlaceSavedWindows then ns.PlaceSavedWindows() end
        if DurabilityFrame then ns.Sched.OnVisible(DurabilityFrame, "questWatch.durability", Lay) end
    elseif not active then
        ns.RegisterEvents(events, EVENTS)
        ns.RegisterEvents(unitEvents, { "UNIT_QUEST_LOG_CHANGED" }, "player")
    end
    active = true
    ns.SyncGameTracker()
    Update()
end

local function Restore()
    active = false
    if home then
        home:Hide()
        events:UnregisterAllEvents()
        unitEvents:UnregisterAllEvents()
    end
    ns.SyncGameTracker()
end

ns.RegisterModule(KEY, { apply = Apply, restore = Restore })

-- Seen at once in a fight; the game's tracker follows when it ends.
ns.OnToggle(function(key)
    if key ~= KEY or not home then return end
    if ns.db.questWatch then Apply() else Restore() end
end)
