local _, ns = ...
local L = ns.L

-- The classic Legacy window: the old talent window (UI/TalentWindow.lua) with its pages down the right edge on the
-- spellbook's skill line tabs. Each page file adds itself with LG.AddPage; a page is built the first time it shows,
-- and its events are registered only while it shows.

local LG = { pages = {} }
ns.legacy = LG

local frame, watch, current
local tabs = {}

-- The game's own wording where this client has it.
function LG.Text(global, key)
    local text = _G[global]
    if type(text) == "string" and text ~= "" then return text end
    return L[key]
end

-- A page in place of the tree, inside the window's metal down to the foot, on stone over the talent art's painted tree
-- and foot under the trainer's divider bar, Close at its foot. Hidden; the page shows it.
-- Right to the border's inner edge (340, as the talent window's foot): past it the page covered the border.
local PANEL_LEFT, PANEL_TOP, PANEL_RIGHT, PANEL_BOTTOM = 14, -24, 340, -440
-- The bar's metal: its upper 8 rows of 16 (the damage meter's divider measures it the same way).
local METAL_H = 8
-- The divider's metal foot 55 down the page (79 down the window); the stone starts under its metal (75 down the window,
-- under the portrait ring's foot at about 71, measured in game), which hides where the stone meets the window's art.
local METAL_FOOT = -55
LG.METAL_FOOT = METAL_FOOT
local STONE_TOP = METAL_FOOT + METAL_H / 2
-- The bar over a page's own frames (the trade skill shell's All tab and its stone strips stand 3 to 6 over the page),
-- under its filter button (12 over).
local BAR_LEVEL = 8
LG.PANEL_W = PANEL_RIGHT - PANEL_LEFT

function LG.Panel(frame)
    local panel = ns.NewFrame("Frame", nil, frame)
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", PANEL_LEFT, PANEL_TOP)
    panel:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", PANEL_RIGHT, PANEL_BOTTOM)
    local stone = panel:CreateTexture(nil, "BACKGROUND")
    stone:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, STONE_TOP)
    stone:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    ns.TileTex(stone, "rockBg")
    local bar = ns.NewFrame("Frame", nil, panel)
    bar:SetAllPoints(panel)
    bar:SetFrameLevel(panel:GetFrameLevel() + BAR_LEVEL)
    local barRun, barEnd = ns.DividerBar(bar)
    barEnd:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, METAL_FOOT + METAL_H)
    barRun:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, METAL_FOOT + METAL_H)
    barRun:SetPoint("TOPRIGHT", barEnd, "TOPLEFT")
    local close = ns.PanelButton(panel, CLOSE or "Close", 84)
    close:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 11)
    close:SetScript("OnClick", function() frame:Hide() end)
    panel:Hide()
    return panel
end

local LegacyConsts = Constants and Constants.LegacyConsts or ns.EMPTY
LG.POINTS_CURRENCY = LegacyConsts.LEGACY_POINTS_TRAIT_CURRENCY_ID or 4225
LG.TRACK_FACTION = LegacyConsts.LEGACY_REWARD_TRACK_FACTION_ID or 2802

-- The account's Legacy Points earned so far (its reward track level); nil when the client cannot say.
function LG.Earned()
    local get = C_MajorFactions and C_MajorFactions.GetCurrentRenownLevel
    local earned = get and get(LG.TRACK_FACTION)
    return type(earned) == "number" and earned or nil
end

-- The window's points bar: earned, out of all the challenges give.
function LG.ShowEarned(frame)
    local earned = LG.Earned()
    local most = C_Traits.GetMaxAvailableTraitCurrency and C_Traits.GetMaxAvailableTraitCurrency(LG.POINTS_CURRENCY, false)
    frame.spent:SetText(earned and type(most) == "number"
        and string.format(L["LEGACY_EARNED"], "|cffffffff" .. earned .. "|r", "|cffffffff" .. most .. "|r") or "")
end

-- page: { key, tab, icon, tip = { global, key }, title = { global, key }, events, build(frame), shown(frame, on),
-- refresh(frame), learn(tree) }. tab is its place in the game's own Legacy window (Reward Track, Challenges, Tree),
-- which opens on the first.
function LG.AddPage(page)
    LG.pages[page.tab] = page
end

-- The current page drawn again.
function LG.Refresh()
    if not (frame and frame:IsShown() and current) then return end
    frame.title:SetText(LG.Text(current.title[1], current.title[2]))
    current.refresh(frame)
end

local function RefreshSoon()
    ns.Sched.NextFrame("legacy.refresh", LG.Refresh)
end

local function Listen(on)
    watch:UnregisterAllEvents()
    if on and current and current.events then ns.RegisterEvents(watch, current.events) end
end

local function ShowPage(page)
    if current == page then return end
    if current then current.shown(frame, false) end
    current = page
    if not page.built then
        page.built = true
        page.build(frame)
    end
    page.shown(frame, true)
    for i, tab in ipairs(tabs) do tab:SetChecked(LG.pages[i] == page) end
    if frame:IsShown() then
        Listen(true)
        LG.Refresh()
    end
end

local function Tab_OnClick(self)
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    ShowPage(LG.pages[self:GetID()])
    -- A click on the picked tab would uncheck it.
    self:SetChecked(true)
end

local function Tab_OnEnter(self)
    local page = LG.pages[self:GetID()]
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(LG.Text(page.tip[1], page.tip[2]))
    GameTooltip:Show()
end

local function Learn(tree)
    if current and current.learn then current.learn(tree) end
end

local function BuildTabs()
    for i, page in ipairs(LG.pages) do
        local tab = ns.SkillLineTab(frame, tabs[i - 1])
        tab:SetID(i)
        tab:SetNormalTexture(page.icon)
        tab:SetScript("OnClick", Tab_OnClick)
        tab:SetScript("OnEnter", Tab_OnEnter)
        tab:SetScript("OnLeave", GameTooltip_Hide)
        tab:Show()
        tabs[i] = tab
    end
end

local function Build()
    if frame then return frame end
    frame = ns.TalentWindow("ClassicUIForeverLegacy", { refresh = LG.Refresh, learn = Learn })
    -- A change is a burst of events: one refresh, next frame.
    watch = ns.EventFrame({}, RefreshSoon)
    BuildTabs()
    frame:SetScript("OnShow", function()
        ns.TalentWindowShown(frame, true)
        Listen(true)
        if SetPortraitTexture then SetPortraitTexture(frame.portrait, "player") end
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
        LG.Refresh()
    end)
    frame:SetScript("OnHide", function()
        Listen(false)
        ns.TalentWindowShown(frame, false)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
    end)
    -- After the window's own SetScripts, which wipe earlier hooks; the next window keeps clear of the page tabs.
    ns.SetSlotWidth(frame, ns.SIDE_TAB_SLOT)
    ns.RegisterClassicWindow(frame, true)
    ns.CloseOnEscape(frame)
    ShowPage(LG.pages[1])
    return frame
end

-- Forever's Legacy system, with its trees' configs; retail has the same tree calls but no Legacy system.
local function Supported()
    return ns.OnForever() and type(C_Traits) == "table" and type(C_Traits.GetConfigIDByTreeID) == "function"
        and type(C_Traits.GetTreeNodes) == "function"
end

local active = false

local function Toggle()
    Build()
    frame:SetShown(not frame:IsShown())
end

-- The Legacy micro button opens this window while on, and the minimap icon with it (it presses the button); in a fight
-- the frame after, as the talents button.
local TakeButton = ns.WindowMicro({ "LegacyMicroButton" }, function()
    if InCombatLockdown() then ns.Sched.NextFrame("legacy.open", Toggle) else Toggle() end
end)

-- The game's Legacy key opens this window too.
local key = ns.WindowKey("ClassicUIForeverLegacyBind", "TOGGLELEGACYSYSTEM", Toggle, "legacy")

local function Apply()
    if not Supported() then return end
    active = true
    TakeButton(true)
    key:Set(true)
end

local function Restore()
    active = false
    TakeButton(false)
    key:Set(false)
    if frame and frame:IsShown() then frame:Hide() end
end

-- The gamepad cannot navigate our windows (Core/Gamepad.lua): with it on at login the game's window stays.
ns.RegisterModule("legacyWindow", { apply = Apply, restore = Restore, padLogin = true })

-- Opens or closes the window (/fcui legacy); false when this client or session cannot show it (said in chat).
function ns.ToggleLegacy()
    if not Supported() then
        ns.Print(L["CHAT_LEGACY_NOT_HERE"])
        return false
    end
    if ns.padSession then
        ns.Print(L["CHAT_LEGACY_NO_GAMEPAD"])
        return false
    end
    if not active then
        ns.Print(L["CHAT_LEGACY_OFF"])
        return false
    end
    Toggle()
    return true
end
