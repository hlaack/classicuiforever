local _, ns = ...

-- Swing timers in the 1.x player cast bar's look: its border, the old fill, its finish flash as a swing lands.
-- Blizzard's own frame art is blanked (range dimming resets its alpha); ours hangs on the bar and dims with it.

local FILL_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
-- 1.x bar colours to pick from per hand, in menu order.
ns.SWING_COLORS = {
    { key = "cast", label = "Cast gold", rgb = { 1, 0.7, 0 } },
    { key = "darkGold", label = "Dark gold", rgb = { 0.85, 0.55, 0 } },
    { key = "focus", label = "Focus orange", rgb = { 1, 0.5, 0.25 } },
    { key = "energy", label = "Energy yellow", rgb = { 1, 1, 0 } },
    { key = "channel", label = "Channel green", rgb = { 0, 1, 0 } },
    { key = "mana", label = "Mana blue", rgb = { 0, 0, 1 } },
    { key = "failed", label = "Failed red", rgb = { 1, 0, 0 } },
}
local COLOR_BY_KEY = {}
for _, color in ipairs(ns.SWING_COLORS) do COLOR_BY_KEY[color.key] = color.rgb end
-- Border thickness steps, a quarter of the 1.x border each.
ns.SWING_BORDER_MIN, ns.SWING_BORDER_MAX = -3, 3
local BORDER_STEP = 0.25
local LABEL_X = 10
-- The border's opening sits 2.5 rows above the bar's middle.
local OPENING_UP = 2.5
-- The player cast bar's border (256 x 64) round its 195 x 13 bar: 30.5 past each end, 28 over the top, 23 under,
-- scaled with the swing bar's own size (edit mode).
local BAR_W, BAR_H = 195, 13
local OUT_X, OUT_TOP, OUT_BOTTOM = 30.5, 28, 23
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

local function Dress(entry)
    local timer = _G[entry.name]
    local bar = timer and timer.StatusBar
    if not bar then return end
    -- The 1.x cast bar's dark backing, seen where a thick border opens past the fill.
    if timer.Background then timer.Background:SetColorTexture(0, 0, 0, 0.5) end
    if timer.Border then timer.Border:SetTexture(nil) end
    if bar.Pip then bar.Pip:SetAlpha(0) end
    if bar.TypeLabelShadow then bar.TypeLabelShadow:SetAlpha(0) end
    bar:SetStatusBarTexture(FILL_TEXTURE)
    local rgb = Color(entry)
    bar:SetStatusBarColor(rgb[1], rgb[2], rgb[3])
    local parts = own[bar]
    if not parts then
        parts = {}
        parts.border = bar:CreateTexture(nil, "ARTWORK", nil, 2)
        ns.SetTex(parts.border, "castBorder")
        parts.flash = bar:CreateTexture(nil, "OVERLAY", nil, 2)
        ns.SetTex(parts.flash, "castFlash")
        parts.flash:SetBlendMode("ADD")
        parts.flash:SetAlpha(0)
        local anim = bar:CreateAnimationGroup()
        local fade = anim:CreateAnimation("Alpha")
        fade:SetTarget(parts.flash)
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetDuration(FLASH_TIME)
        anim:SetToFinalAlpha(true)
        parts.anim = anim
        own[bar] = parts
    end
    local w, h = bar:GetWidth() or 0, bar:GetHeight() or 0
    local k = Thickness()
    local sx, sy = w / BAR_W * k, h / BAR_H * k
    parts.border:ClearAllPoints()
    parts.border:SetPoint("TOPLEFT", bar, "TOPLEFT", -OUT_X * sx, OUT_TOP * sy)
    parts.border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", OUT_X * sx, -OUT_BOTTOM * sy)
    local up = OPENING_UP * sy
    if bar.TypeLabel then ns.SetPointOnce(bar.TypeLabel, "LEFT", bar, "LEFT", LABEL_X, up) end
    if bar.TimeLabel then ns.SetPointOnce(bar.TimeLabel, "RIGHT", bar, "RIGHT", -LABEL_X, up) end
    parts.flash:SetAllPoints(parts.border)
    parts.border:Show()
    parts.flash:Show()
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
        parts.border:Hide()
        parts.flash:Hide()
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

ns.RegisterModule("swingTimers", { apply = Apply, restore = Restore })
