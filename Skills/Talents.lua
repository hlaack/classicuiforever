local _, ns = ...

-- The old talent window: one tree per foot tab on its old background, rank plates and arrows, points spent atop and left at the foot.
-- A click stages, Apply commits (old preview). Our own window like the spellbook, so it opens in combat; the client's window is untouched.
-- The window itself is shared with the Legacy window (UI/TalentWindow.lua).

-- The talent window's private table; TalentsTree.lua reads the tree into it.
local TL = {}
ns.talents = TL

local active = false
local frame
-- Gamepad on at login: the window lives in the game's spell window (Spells/SpellsHost.lua), which opens and closes it.
local function Hosted() return ns.padSession == true end
-- Up only while someone's talents are shown.
local inspectWatch
-- nil for the player, or the inspected unit (its own read-only config).
local inspectUnit

-- The old backgrounds, by class and by the tree's place in the row.
local BACKGROUNDS = {
    DRUID = { "DruidBalance", "DruidFeralCombat", "DruidRestoration" },
    HUNTER = { "HunterBeastMastery", "HunterMarksmanship", "HunterSurvival" },
    MAGE = { "MageArcane", "MageFire", "MageFrost" },
    PALADIN = { "PaladinHoly", "PaladinProtection", "PaladinCombat" },
    PRIEST = { "PriestDiscipline", "PriestHoly", "PriestShadow" },
    ROGUE = { "RogueAssassination", "RogueCombat", "RogueSubtlety" },
    SHAMAN = { "ShamanElementalCombat", "ShamanEnhancement", "ShamanRestoration" },
    WARLOCK = { "WarlockCurses", "WarlockSummoning", "WarlockDestruction" },
    WARRIOR = { "WarriorArms", "WarriorFury", "WarriorProtection" },
}
local TREE_EVENTS = { "TRAIT_CONFIG_UPDATED", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_NODE_CHANGED", "PLAYER_TALENT_UPDATE",
    "ACTIVE_COMBAT_CONFIG_CHANGED", "PLAYER_LEVEL_UP" }

----------------------------------------------------------------- the view

local function Background(tab)
    local _, class = UnitClass(inspectUnit or "player")
    return BACKGROUNDS[class] and BACKGROUNDS[class][tab.index]
end

local function Refresh()
    if not frame or not active then return end
    local tree = TL.ReadTree(inspectUnit)
    local title = TALENTS or "Talents"
    if tree and tree.inspect then title = UnitName(inspectUnit) or title end
    ns.DrawTalentTab(frame, tree, { background = Background, title = title,
        points = tree and not tree.inspect and ((TALENT_POINTS or "Talent Points") .. ": |cffffffff" .. tree.points .. "|r") or "" })
end

-- Next-frame refresh after a tree change.
local function RefreshIfShown()
    if frame:IsShown() then Refresh() end
end

local function Learn(tree)
    if C_ClassTalents and C_ClassTalents.CommitConfig then
        -- nil like the client's window with no loadout picked: commits the talents in
        -- use. Given the active config, the client refused and then applied anyway.
        local ok, done = pcall(C_ClassTalents.CommitConfig, nil)
        ns.Persist("talents: commit called=" .. tostring(ok) .. " result=" .. tostring(done))
        if ok and done == false and UIErrorsFrame and TALENT_FRAME_CONFIG_OPERATION_TOO_FAST then
            UIErrorsFrame:AddMessage(TALENT_FRAME_CONFIG_OPERATION_TOO_FAST, 1, 0.1, 0.1)
        end
    elseif C_Traits.CommitConfig then
        pcall(C_Traits.CommitConfig, tree.configID)
    end
end

local function Build()
    if frame then return frame end
    frame = ns.TalentWindow("ClassicUIForeverTalents", { hosted = Hosted(), refresh = Refresh, learn = Learn })
    frame.title:SetText(TALENTS or "Talents")

    frame:SetScript("OnShow", function()
        -- Hidden and shown in one go (inspect to own) with a talent tooltip up: keep listening.
        ns.TalentWindowShown(frame, true)
        if SetPortraitTexture then SetPortraitTexture(frame.portrait, inspectUnit or "player") end
        -- Hosted, the game's window sounds its own.
        if not Hosted() then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end
        Refresh()
    end)
    frame:SetScript("OnHide", function()
        inspectUnit = nil
        if inspectWatch then inspectWatch:Hide() end
        ns.TalentWindowShown(frame, false)
        if not Hosted() then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end
    end)
    -- Inspect talents sit beside the inspect window and close with it: the client
    -- drops the data then.
    frame.fcuiKeep = function()
        return inspectUnit and _G["InspectFrame"] or nil
    end
    inspectWatch = ns.NewFrame("Frame", nil, frame)
    inspectWatch:Hide()
    ns.Sched.OnFrame(inspectWatch, { name = "talents.inspect", every = 0.2, fn = function()
        if not inspectUnit then return end
        local inspect = _G["InspectFrame"]
        if not (inspect and inspect:IsShown()) then frame:Hide() end
    end })
    if not Hosted() then
        -- After the window's own SetScripts, which wipe earlier hooks (it then opened
        -- over vendors, mail and the spellbook, and lost Escape).
        ns.RegisterClassicWindow(frame, true)
        -- Escape shuts the window before the client drops the target.
        ns.CloseOnEscape(frame)
    end

    -- A change to the tree is a burst of events: one refresh, next frame.
    ns.EventFrame(TREE_EVENTS, function()
        if not frame:IsShown() then return end
        ns.Sched.NextFrame("talents.refresh", RefreshIfShown)
    end)
    return frame
end

------------------------------------------------------------- the way in

local function Toggle()
    Build()
    if frame:IsShown() and inspectUnit then
        -- Up on someone else's talents: the key turns it to the player's.
        inspectUnit = nil
        inspectWatch:Hide()
        frame:Hide()
        frame:Show()
    elseif frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

-- Public API (Core/API.lua): the player's talents shown, on tree tab if given.
function ns.ShowTalents(tab)
    if not active or Hosted() then return false end
    Build()
    if inspectUnit then
        inspectUnit = nil
        if inspectWatch then inspectWatch:Hide() end
        frame:Hide()
    end
    if not frame:IsShown() then frame:Show() end
    local button = type(tab) == "number" and frame.tabs[tab]
    if button and button:IsShown() then button:Click() end
    return frame:IsShown()
end

-- The inspect window's Talents button, which opened the client's window.
local function ShowInspect(unit)
    if not unit then return end
    Build()
    if frame:IsShown() then frame:Hide() end
    inspectUnit = unit
    inspectWatch:Show()
    frame.tabIndex = 1
    frame:Show()
end

local inspectClick
local function TakeInspectButton(on)
    local doll = _G["InspectPaperDollFrame"]
    local button = doll and doll.InspectTalents
    if not button then return end
    if on then
        if inspectClick == nil then inspectClick = button:GetScript("OnClick") or false end
        button:SetScript("OnClick", function()
            if C_Traits and C_Traits.HasValidInspectData and not C_Traits.HasValidInspectData() then return end
            local inspect = _G["InspectFrame"]
            ShowInspect(inspect and inspect.unit or "target")
        end)
    elseif inspectClick then
        button:SetScript("OnClick", inspectClick)
        inspectClick = nil
    end
end
-- The inspect window is a piece the client loads when first wanted.
ns.EventFrame("ADDON_LOADED", function(_, _, name)
    if name == "Blizzard_InspectUI" and active then TakeInspectButton(true) end
end)

-- Talents micro button and key open this window while on. Both client buttons:
-- this client shows TalentMicroButton; taking only PlayerSpellsMicroButton
-- (never shown) left the visible one opening the client's window.
local microClicks = {}
local function TakeButton(on)
    for _, name in ipairs({ "TalentMicroButton", "PlayerSpellsMicroButton" }) do
        local button = _G[name]
        if button and button.GetScript then
            if on then
                if microClicks[name] == nil then microClicks[name] = button:GetScript("OnClick") or false end
                button:SetScript("OnClick", function()
                    if KeybindFrames_InQuickKeybindMode and KeybindFrames_InQuickKeybindMode() then return end
                    if InCombatLockdown() and C_Timer and C_Timer.After then C_Timer.After(0, Toggle) else Toggle() end
                end)
            elseif microClicks[name] then
                button:SetScript("OnClick", microClicks[name])
            end
        end
    end
end

local BIND_NAME = "ClassicUIForeverTalentsBind"
local bindButton
local function UpdateBinding()
    if not bindButton or InCombatLockdown() then return end
    ClearOverrideBindings(bindButton)
    if not active then return end
    local key, second = GetBindingKey("TOGGLETALENTS")
    for _, k in ipairs({ key, second }) do
        if k then SetOverrideBindingClick(bindButton, true, k, ns.KeyProxy(BIND_NAME), "LeftButton") end
    end
end

local function Apply()
    active = true
    if Hosted() then
        -- Nothing of the client's is taken: its keys and buttons open the window the talents sit in.
        if ns.HostSpellsWindow then ns.HostSpellsWindow() end
        return
    end
    if not bindButton then
        -- Secure, so its click can bind Escape in a fight (UI/Escape.lua); its events live on a side frame, as a
        -- frame with registrations can be refused by the secure environment.
        bindButton = CreateFrame("Button", BIND_NAME, UIParent, "SecureActionButtonTemplate")
        bindButton:RegisterForClicks("AnyDown", "AnyUp")
        bindButton:SetAttribute("useOnKeyDown", false)
        bindButton:SetScript("PostClick", function(_, _, down)
            if not down then Toggle() end
        end)
        if ns.EscArmOnClick then ns.EscArmOnClick(bindButton, "talents") end
        ns.EventFrame({ "UPDATE_BINDINGS", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }, UpdateBinding)
    end
    TakeButton(true)
    TakeInspectButton(true)
    UpdateBinding()
end

local function Restore()
    active = false
    TakeButton(false)
    TakeInspectButton(false)
    UpdateBinding()
    if frame and not Hosted() then frame:Hide() end
    if ns.HostSpellsWindow then ns.HostSpellsWindow() end
end

ns.RegisterModule("talents", { apply = Apply, restore = Restore, padHost = true })

function ns.TalentsActive() return active end
function ns.TalentsRefresh() if frame and frame:IsShown() then Refresh() end end

-- Hosted: built with a button for every talent of the largest tree, so the window's read on opening finds them all.
function ns.TalentsBuilt()
    if not active or InCombatLockdown() then return frame end
    Build()
    local tree = TL.ReadTree and TL.ReadTree()
    local most = 0
    for _, tab in ipairs(tree and tree.tabs or {}) do most = math.max(most, #tab.nodes) end
    ns.TalentButtons(frame, most)
    return frame
end
