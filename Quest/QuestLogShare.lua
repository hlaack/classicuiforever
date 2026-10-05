local _, ns = ...
local L = ns.L

-- The quest log's Share Quest: a secure pad presses the client's own share, our click only explains.

local QL = ns.QL

-- QuestLogPushQuest is protected; the map's Share reads its quest off a row the game fills only as its quest pane shows.
-- One press, in one script run: the map, its pane and the quest's header open, the row, Share and Back are pressed, and
-- what was opened is shut. The Aim steps are ours: each points the next clicks at what the game has just built.
local STEPS = { "Open", "AimPane", "Pane", "AimHeader", "Header", "AimRow", "Row", "Share", "Back", "AimShut", "Shut" }
-- The row's click leaves the map on the quest's zone, and the game sorts the whole quest log for the map's zone: the
-- map is opened and shut once more at the end, which puts it back on the player's.
local ORDER = { "Open", "AimPane", "Pane", "AimHeader", "Header", "AimRow", "Row", "Share", "Back", "AimShut", "Shut", "Open",
    "Open", "Open" }
-- Only what the press aims: Open stays aimed while a share is possible.
local AIMED = { "Pane", "Header", "Row", "Share", "Back", "Shut" }
local proxies, macro
local armedID          -- the quest the pad shares
local openedPane       -- the pane was shut and this press opened it
local pressed, shared  -- a press ran its aims; it reached the row

local function Aim(step, target)
    ns.SetAttributeIf(proxies[step], "clickbutton", target or nil)
end

local function Disarm()
    for _, step in ipairs(AIMED) do Aim(step, nil) end
end

-- Every aim needs the map this press opened: with a modifier held the open is skipped and nothing is pressed.
local function MapUp()
    return armedID ~= nil and not InCombatLockdown() and WorldMapFrame:IsShown()
end

local function AimPane()
    -- A modifier skips the map's clicks: that press is no failed share.
    pressed, shared, openedPane = not IsModifierKeyDown(), false, false
    Disarm()
    if not MapUp() then return end
    local toggle = WorldMapFrame.SidePanelToggle
    openedPane = not QuestMapFrame:IsShown() and toggle ~= nil and toggle.OpenButton ~= nil
    Aim("Pane", openedPane and toggle.OpenButton or nil)
end

-- The header the quest sits under, by the log's own order; nil unless it is folded and has its button.
local function FoldedHeader(questID)
    local header, found
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
        local info = C_QuestLog.GetInfo(i)
        if info and info.isHeader then
            header = info.isCollapsed and i or nil
        elseif info and info.questID == questID then
            found = true
            break
        end
    end
    local pool = found and header and QuestScrollFrame and QuestScrollFrame.headerFramePool
    if not pool then return nil end
    for button in pool:EnumerateActive() do
        if button.questLogIndex == header then return button end
    end
end

local function AimHeader()
    if MapUp() and QuestMapFrame:IsShown() then Aim("Header", FoldedHeader(armedID)) end
end

-- The quest's row, with a questID only client code wrote; reads only.
local function AimRow()
    if not (MapUp() and QuestMapFrame:IsShown()) then return end
    local find = _G.QuestLogQuests_GetQuestButton
    local row = find and find(armedID)
    local details = QuestMapFrame.DetailsFrame
    local back = details and details.BackFrame and details.BackFrame.BackButton
    if not (row and issecurevariable(row, "questID") and details and details.ShareButton and back) then return end
    shared = true
    Aim("Row", row)
    Aim("Share", details.ShareButton)
    Aim("Back", back)
end

local function AimShut()
    local toggle = WorldMapFrame.SidePanelToggle
    if MapUp() and openedPane and toggle then Aim("Shut", toggle.CloseButton) end
end

local AIMS = { AimPane = AimPane, AimHeader = AimHeader, AimRow = AimRow, AimShut = AimShut }

local function Build()
    if proxies then return end
    proxies = {}
    local lines = {}
    for i, step in ipairs(STEPS) do
        proxies[step] = ns.ClickProxy("FCUIQS" .. i)
        if AIMS[step] then proxies[step]:SetScript("PreClick", AIMS[step]) end
    end
    -- [nomod] on the map's own two: shift on a map row toggles tracking and the chat-link modifier links it.
    for i, step in ipairs(ORDER) do
        lines[i] = string.format(step == "Open" and "/click [nomod] %s" or "/click %s", proxies[step]:GetName())
    end
    macro = table.concat(lines, "\n")
end

-- The quest to share while the pad may act: our Share lit, the world map shut, the game's pieces there.
local function Wanted()
    local frame, selectedID = QL.Frame(), QL.SelectedID()
    if not (selectedID and frame.share:IsVisible() and frame.share:IsEnabled()) then return nil end
    if not (WorldMapFrame and QuestMapFrame and MinimapCluster and MinimapCluster.ZoneTextButton) then return nil end
    if WorldMapFrame:IsShown() then return nil end
    return selectedID
end

-- Arms the pad for the picked quest out of combat, or disarms it so a stale pad presses nothing.
function QL.PointShare()
    if InCombatLockdown() then return nil end
    local questID = Wanted()
    if not questID and not proxies then return nil end
    Build()
    armedID = questID
    Aim("Open", questID and MinimapCluster.ZoneTextButton or nil)
    Disarm()
    return questID
end

-- Called by the pad's placer; nil hides the pad so our own click explains.
function QL.ShareMacro()
    return QL.PointShare() and macro or nil
end

-- After each press: nothing stays aimed, and a press that found no row says where to share instead.
function QL.SharePadAfter()
    if not pressed then return end
    pressed = false
    if not InCombatLockdown() then Disarm() end
    if not shared then UIErrorsFrame:AddMessage(L["QUEST_SHARE_FROM_THE_MAP"], 1, 0.1, 0.1) end
end

-- Reached only with the pad away: in combat, or with the map open.
function QL.ShareClick()
    local selectedID = QL.SelectedID()
    local info = selectedID and QL.QuestInLog(selectedID)
    if not info then return end
    if not IsInGroup() then
        UIErrorsFrame:AddMessage(L["QUEST_YOU_ARE_NOT_IN_A"], 1, 0.1, 0.1)
        return
    end
    if InCombatLockdown() then
        ns.SayNotInCombat()
    elseif WorldMapFrame and WorldMapFrame:IsShown() then
        -- Our log shares only with the map shut (both stay up only when opened in combat).
        UIErrorsFrame:AddMessage(L["QUEST_CLOSE_THE_WORLD_MAP_THEN"], 1, 0.1, 0.1)
    end
end
