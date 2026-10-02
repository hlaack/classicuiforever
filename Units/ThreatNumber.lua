local _, ns = ...

-- Era's threat percent over the target frame (its TargetFrameNumericalThreat), as our own box: the game shows its own
-- only with threatShowNumeric on, a setting no code of ours may write at load. The game's own one fades under ours.

local UF = ns.UF
local IsSecret = ns.IsSecret
local UnitDetailedThreatSituation, UnitThreatPercentageOfLead = UnitDetailedThreatSituation, UnitThreatPercentageOfLead
local GetThreatStatusColor = GetThreatStatusColor

-- Era's numbers: a 49 x 18 box, its colored fill 37 x 14 and the label 3 and 4 down from the box's top; the box where
-- TargetFrame.lua puts the game's own.
local BOX_W, BOX_H, FILL_W, FILL_H, FILL_Y, TEXT_Y = 49, 18, 37, 14, -3, -4
local BOX_X, BOX_Y = -30, -26
local BORDER_COORDS = { 0, 0.765625, 0, 0.5625 }
-- The target's threat list and the player's standing on it; a new target and the fight's end.
local UNIT_EVENTS = { "UNIT_THREAT_LIST_UPDATE", "UNIT_THREAT_SITUATION_UPDATE" }
local EVENTS = { "PLAYER_TARGET_CHANGED", "PLAYER_REGEN_ENABLED" }
local box, driver, live

local function GameNumber()
    return ns.Path(TargetFrame, "TargetFrameContent", "TargetFrameContentContextual", "NumericalThreat")
end

local function Build()
    box = ns.NewFrame("Frame", nil, TargetFrame)
    box:SetSize(BOX_W, BOX_H)
    box:SetPoint("BOTTOM", TargetFrame, "TOP", BOX_X, BOX_Y)
    box.fill = box:CreateTexture(nil, "BACKGROUND")
    ns.SetTex(box.fill, "statusBar")
    box.fill:SetSize(FILL_W, FILL_H)
    box.fill:SetPoint("TOP", box, "TOP", 0, FILL_Y)
    box.border = box:CreateTexture(nil, "ARTWORK")
    ns.SetTex(box.border, "threatBorder")
    box.border:SetTexCoord(unpack(BORDER_COORDS))
    box.border:SetAllPoints(box)
    box.text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    box.text:SetPoint("TOP", box, "TOP", 0, TEXT_Y)
    box:Hide()
end

-- The game's own reading (UnitFrame_UpdateThreatIndicator): your share, or your lead over the next while tanking.
local function Update()
    local show = false
    if live and UnitExists("target") and not UnitIsDead("target") and UnitClassification("target") ~= "minus" then
        local tanking, status, _, raw = UnitDetailedThreatSituation("player", "target")
        local value = raw
        if tanking and not IsSecret(tanking) then value = UnitThreatPercentageOfLead("player", "target") end
        if value and status and not IsSecret(value) and not IsSecret(status) and value ~= 0 then
            box.text:SetFormattedText("%1.0f%%", value)
            box.fill:SetVertexColor(GetThreatStatusColor(status))
            show = true
        end
    end
    ns.SetShownIf(box, show)
end

-- On with the classic target frame and the option; called by the unit frame module and the option's switch.
function ns.ThreatNumberSync()
    local on = UF.active and UF.On("target") and ns.db.threatNumber ~= false
    if on and not box then Build() end
    if on and not driver then driver = ns.EventFrame(EVENTS, Update) end
    if driver then
        driver:UnregisterAllEvents()
        if on then
            ns.RegisterEvents(driver, EVENTS)
            ns.RegisterEvents(driver, UNIT_EVENTS, "player", "target")
        end
    end
    live = on
    local game = GameNumber()
    if game then ns.SetAlphaIf(game, on and 0 or 1) end
    if box then Update() end
end

-- The options pass waits out a fight, where threat shows: the switch answers at once.
ns.OnToggle(function(key)
    if key == "threatNumber" then ns.ThreatNumberSync() end
end)
