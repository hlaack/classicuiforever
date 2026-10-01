local _, ns = ...
local L = ns.L

-- Swing timers in the 1.x player cast bar's look: its border, the old fill, its finish flash as a swing lands.
-- Blizzard's own frame art is blanked (range dimming resets its alpha); ours hangs on the bar and dims with it.

local FILL_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
-- 1.x bar colours to pick from per hand, in menu order.
ns.SWING_COLORS = {
    { key = "cast", label = L["UI_CAST_GOLD"], rgb = { 1, 0.7, 0 } },
    { key = "darkGold", label = L["UI_DARK_GOLD"], rgb = { 0.85, 0.55, 0 } },
    { key = "focus", label = L["UI_FOCUS_ORANGE"], rgb = { 1, 0.5, 0.25 } },
    { key = "energy", label = L["UI_ENERGY_YELLOW"], rgb = { 1, 1, 0 } },
    { key = "channel", label = L["UNIT_CHANNEL_GREEN"], rgb = { 0, 1, 0 } },
    { key = "mana", label = L["UI_MANA_BLUE"], rgb = { 0, 0, 1 } },
    { key = "failed", label = L["UI_FAILED_RED"], rgb = { 1, 0, 0 } },
}
local COLOR_BY_KEY = {}
for _, color in ipairs(ns.SWING_COLORS) do COLOR_BY_KEY[color.key] = color.rgb end
-- Border thickness steps, a quarter of the 1.x border each.
ns.SWING_BORDER_MIN, ns.SWING_BORDER_MAX = -3, 3
local BORDER_STEP = 0.25
local LABEL_X = 10
-- The border's opening sits 2.5 rows above the bar's middle.
local OPENING_UP = 2.5
-- The player cast bar's border (256 x 64) round its 195 x 13 bar, 30.5 past each end, scaled with the swing bar's
-- height (edit mode). Cut in nine so thickness moves only the outer parts.
local BAR_H, OUT_X = 13, 30.5
-- Cut round the opening (rows 28-37, columns 38-217) so every rail is in an outer piece: the 1.x border covers the
-- bar's foot and 7.5 of each end.
local CUT_LEFT, CUT_RIGHT, CUT_TOP, CUT_FOOT = 38, 217, 28, 37
local COLS = { 0, CUT_LEFT / 256, CUT_RIGHT / 256, 1 }
local ROWS = { 0, CUT_TOP / 64, CUT_FOOT / 64, 1 }
local IN_X, IN_H = CUT_LEFT - OUT_X, CUT_FOOT - CUT_TOP
local FLASH_TIME = 0.3
local RESET_DROP = 0.5   -- a fall of this much of the bar is a new swing
local FRAMES = {
    { name = "SwingTimerMainHandFrame", key = "swingColorMain", default = "cast" },
    { name = "SwingTimerOffHandFrame", key = "swingColorOff", default = "darkGold" },
    { name = "SwingTimerRangedFrame", key = "swingColorRanged", default = "channel" },
}

local function Color(entry)
    return COLOR_BY_KEY[ns.db and ns.db[entry.key]] or COLOR_BY_KEY[entry.default]
end

local function Thickness()
    local step = tonumber(ns.db and ns.db.swingBorder) or 0
    return 1 + BORDER_STEP * math.max(ns.SWING_BORDER_MIN, math.min(ns.SWING_BORDER_MAX, step))
end

local active = false
local own = setmetatable({}, { __mode = "k" })   -- status bar -> our border and flash

-- Nine pieces of a border sheet, row by row from the top left.
local function Slices(bar, key, layer)
    local list = {}
    for row = 1, 3 do
        for col = 1, 3 do
            local tex = bar:CreateTexture(nil, layer, nil, 2)
            ns.SetTex(tex, key)
            tex:SetTexCoord(COLS[col], COLS[col + 1], ROWS[row], ROWS[row + 1])
            list[#list + 1] = tex
        end
    end
    return list
end

-- The outline at edge (x out from the bar's ends, top over and foot under its top); ends l wide, top t and foot b
-- tall inside it, the middle piece the opening they leave.
local function LaySlices(list, bar, edge, l, t, b)
    local tl, top, tr, left, mid, right, bl, bottom, br = unpack(list)
    for i = 1, #list do list[i]:ClearAllPoints() end
    mid:SetPoint("TOPLEFT", bar, "TOPLEFT", edge.x + l, edge.top - t)
    mid:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", -edge.x - l, edge.foot + b)
    tl:SetPoint("BOTTOMRIGHT", mid, "TOPLEFT")
    tl:SetSize(l, t)
    top:SetPoint("BOTTOMLEFT", mid, "TOPLEFT")
    top:SetPoint("BOTTOMRIGHT", mid, "TOPRIGHT")
    top:SetHeight(t)
    tr:SetPoint("BOTTOMLEFT", mid, "TOPRIGHT")
    tr:SetSize(l, t)
    left:SetPoint("TOPRIGHT", mid, "TOPLEFT")
    left:SetPoint("BOTTOMRIGHT", mid, "BOTTOMLEFT")
    left:SetWidth(l)
    right:SetPoint("TOPLEFT", mid, "TOPRIGHT")
    right:SetPoint("BOTTOMLEFT", mid, "BOTTOMRIGHT")
    right:SetWidth(l)
    bl:SetPoint("TOPRIGHT", mid, "BOTTOMLEFT")
    bl:SetSize(l, b)
    bottom:SetPoint("TOPLEFT", mid, "BOTTOMLEFT")
    bottom:SetPoint("TOPRIGHT", mid, "BOTTOMRIGHT")
    bottom:SetHeight(b)
    br:SetPoint("TOPLEFT", mid, "BOTTOMRIGHT")
    br:SetSize(l, b)
end

local function ShowSlices(list, shown)
    for i = 1, #list do list[i]:SetShown(shown) end
end

local function Dress(entry)
    local timer = _G[entry.name]
    local bar = timer and timer.StatusBar
    if not bar then return end
    if timer.Background then timer.Background:SetTexture(nil) end
    if timer.Border then timer.Border:SetTexture(nil) end
    if bar.Pip then bar.Pip:SetAlpha(0) end
    if bar.TypeLabelShadow then bar.TypeLabelShadow:SetAlpha(0) end
    bar:SetStatusBarTexture(FILL_TEXTURE)
    local rgb = Color(entry)
    bar:SetStatusBarColor(rgb[1], rgb[2], rgb[3])
    local parts = own[bar]
    if not parts then
        parts = {}
        parts.border = Slices(bar, "castBorder", "ARTWORK")
        -- The 1.x cast bar's dark backing, the bar's own size.
        parts.edge = {}
        parts.back = bar:CreateTexture(nil, "BACKGROUND")
        parts.back:SetColorTexture(0, 0, 0, 0.5)
        parts.back:SetAllPoints(bar)
        parts.flash = Slices(bar, "castFlash", "OVERLAY")
        local anim = bar:CreateAnimationGroup()
        for _, tex in ipairs(parts.flash) do
            tex:SetBlendMode("ADD")
            tex:SetAlpha(0)
            local fade = anim:CreateAnimation("Alpha")
            fade:SetTarget(tex)
            fade:SetFromAlpha(1)
            fade:SetToAlpha(0)
            fade:SetDuration(FLASH_TIME)
        end
        anim:SetToFinalAlpha(true)
        parts.anim = anim
        own[bar] = parts
    end
    local h = bar:GetHeight() or 0
    local k = Thickness()
    -- One scale on every side (the bar's height), so the ends keep their shape and thickness steps match the rails.
    local sy = h / BAR_H
    -- The outline stays where the 1.x border has it; thinner rails leave its opening wider, backed dark.
    local l0, t0, b0 = CUT_LEFT * sy, CUT_TOP * sy, (64 - CUT_FOOT) * sy
    local edge = parts.edge
    edge.x, edge.top, edge.foot = IN_X * sy - l0, t0, -(IN_H * sy + b0)
    local l, t, b = l0 * k, t0 * k, b0 * k
    LaySlices(parts.border, bar, edge, l, t, b)
    LaySlices(parts.flash, bar, edge, l, t, b)
    parts.back:ClearAllPoints()
    if k < 1 then
        parts.back:SetAllPoints(parts.border[5])
    else
        parts.back:SetAllPoints(bar)
    end
    local up = OPENING_UP * sy
    if bar.TypeLabel then ns.SetPointOnce(bar.TypeLabel, "LEFT", bar, "LEFT", LABEL_X, up) end
    if bar.TimeLabel then ns.SetPointOnce(bar.TimeLabel, "RIGHT", bar, "RIGHT", -LABEL_X, up) end
    ShowSlices(parts.border, true)
    ShowSlices(parts.flash, true)
    -- The middle slice is only the rails' soft inner fade: stretched round a thinner border's wider opening it swelled.
    parts.border[5]:SetShown(k >= 1)
    parts.flash[5]:SetShown(k >= 1)
    parts.back:Show()
end

local function Undress(entry)
    local timer = _G[entry.name]
    local bar = timer and timer.StatusBar
    if not bar then return end
    if timer.Background then timer.Background:SetAtlas("ui-swingtimerbar-background") end
    if timer.Border then timer.Border:SetAtlas("ui-swingtimerbar-frame") end
    if bar.Pip then bar.Pip:SetAlpha(1) end
    if bar.TypeLabelShadow then bar.TypeLabelShadow:SetAlpha(1) end
    if bar.TypeLabel then ns.SetPointOnce(bar.TypeLabel, "LEFT", bar, "LEFT", LABEL_X, 0) end
    if bar.TimeLabel then ns.SetPointOnce(bar.TimeLabel, "RIGHT", bar, "RIGHT", -LABEL_X, 0) end
    if timer.barTexture then bar:SetStatusBarTexture(timer.barTexture) end
    bar:SetStatusBarColor(1, 1, 1)
    local parts = own[bar]
    if parts then
        ShowSlices(parts.border, false)
        ShowSlices(parts.flash, false)
        parts.back:Hide()
    end
end

-- A resized bar (edit mode) fits its border again.
local function Resized(bar)
    if not active then return end
    for _, entry in ipairs(FRAMES) do
        local timer = _G[entry.name]
        if timer and timer.StatusBar == bar then Dress(entry) end
    end
end

-- While a timer shows: the bar falling back is a swing landing, which flashes as a cast finishing.
local lastValue = setmetatable({}, { __mode = "k" })
local function WatchSwing(job)
    local bar = job.bar
    local value = active and bar:GetValue() or nil
    local last = lastValue[bar]
    lastValue[bar] = value
    local parts = own[bar]
    if value and last and parts and last - value >= RESET_DROP then
        parts.anim:Stop()
        parts.anim:Play()
    end
end

local function Apply()
    active = true
    for _, entry in ipairs(FRAMES) do
        local timer = _G[entry.name]
        if timer and timer.StatusBar then
            ns.HookScriptOnce(timer.StatusBar, "OnSizeChanged", Resized)
            local job = ns.Sched.Attach(timer, { name = "swing.flash", every = 0, fn = WatchSwing })
            if job then job.bar = timer.StatusBar end
            ns.SafeCall(Dress, entry)
        end
    end
end

local function Restore()
    if not active then return end
    active = false
    for _, entry in ipairs(FRAMES) do ns.SafeCall(Undress, entry) end
end

-- A colour or thickness picked in the options.
function ns.SetSwingLook(key, value)
    if key then ns.db[key] = value end
    if not active then return end
    for _, entry in ipairs(FRAMES) do ns.SafeCall(Dress, entry) end
end

function ns.SetSwingBorder(step)
    ns.SetSwingLook("swingBorder", step)
end

-- The border thickness under the client's swing timer dialog too; the same setting as the options.
local HANDS = { SwingTimerMainHandFrame = true, SwingTimerOffHandFrame = true, SwingTimerRangedFrame = true }
local function BorderValues()
    local low, high = ns.SWING_BORDER_MIN, ns.SWING_BORDER_MAX
    return tonumber(ns.db and ns.db.swingBorder) or 0, low, high, high - low
end
ns.DialogExtra({
    title = L["MAP_CLASSICUI_FOREVER"],
    match = function(system) return active and HANDS[system:GetName() or ""] == true end,
    build = function(panel) panel.border = ns.DialogExtraSlider(panel, L["OPTWIN_BORDER_THICKNESS"], BorderValues, ns.SetSwingBorder) end,
    fill = function(panel) panel.border() end,
})

ns.RegisterModule("swingTimers", { apply = Apply, restore = Restore })
