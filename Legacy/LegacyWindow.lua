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

-- page: { key, icon, tip = { global, key }, title = { global, key }, events, build(frame), shown(frame, on),
-- refresh(frame), learn(tree) }. Pages show in the order added.
function LG.AddPage(page)
    LG.pages[#LG.pages + 1] = page
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

-- The Legacy system needs its trees' configs; a client without them has no Legacy window.
local function Supported()
    return type(C_Traits) == "table" and type(C_Traits.GetConfigIDByTreeID) == "function"
        and type(C_Traits.GetTreeNodes) == "function"
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
