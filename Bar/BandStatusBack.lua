local _, ns = ...
local B = ns.band

-- The XP and reputation bars' client look, kept at the first dress and handed back as the band goes; Era's backing.

local backs = setmetatable({}, { __mode = "k" })   -- status bar -> Era's half-black backing
B.statusBacks = backs   -- read by the dev addon's fight check
local looks = setmetatable({}, { __mode = "k" })   -- bar -> its rested run and tick as the client drew them
local fades = setmetatable({}, { __mode = "k" })   -- fade animation -> { duration, start delay }
local skinned = setmetatable({}, { __mode = "k" })   -- tick -> wearing the old marker
local FADES = { "FadeInAnimation", "FadeOutAnimation" }
local FULL = { 0, 1, 0, 1 }
local TICK = { coords = FULL, fill = true, tint = true }
local TICK_HL = { coords = FULL, fill = true }

-- Era's half-black backing for the client's light one: over the rested run, under the fill, sized with the bar.
function B.StatusBacking(status)
    if status.Background then status.Background:SetAlpha(0) end
    local back = backs[status] or status:CreateTexture(nil, "BACKGROUND", nil, 1)
    backs[status] = back
    back:SetAllPoints(status)
    back:SetColorTexture(0, 0, 0, 0.5)
    back:SetShown(ns.db.statusBarBacking ~= false)
end

-- Backings follow the option at once, in a fight too; off with the band.
local function ShowBacks()
    local on = B.active and ns.db.statusBarBacking ~= false
    for _, back in pairs(backs) do back:SetShown(on) end
end
ns.OnToggle(function(key) if key == "statusBarBacking" then ShowBacks() end end)

-- Fades cut to 0.02 s, not 0: the client picks a swap's direction at each fade's end, and a 0 s fade never ran.
function B.CutStatusFades(container)
    for _, key in ipairs(FADES) do
        local group = container[key]
        if group and group.GetAnimations then
            for _, anim in ipairs({ group:GetAnimations() }) do
                if not fades[anim] and anim.SetStartDelay then
                    fades[anim] = { anim:GetDuration(), anim:GetStartDelay() }
                    anim:SetDuration(0.02)
                    anim:SetStartDelay(0)
                end
            end
        end
    end
end

-- Before the first dress: the rested run and tick as the client's files draw them.
function B.KeepStatusLook(bar)
    if looks[bar] then return end
    local run, tick = bar.ExhaustionLevelFillBar, bar.ExhaustionTick
    local look = {}
    if run then
        look.atlas, look.height, look.parent = run:GetAtlas(), run:GetHeight(), run:GetParent()
        local layer, sub = run:GetDrawLayer()
        if not ns.AnySecret(layer, sub) then look.layer, look.sub = layer, sub end
    end
    if tick then
        look.tickW, look.tickH = tick:GetSize()
        look.normal = tick.Normal and tick.Normal:GetAtlas()
        look.highlight = tick.Highlight and tick.Highlight:GetAtlas()
    end
    looks[bar] = look
end

function B.SkinTick(tick)
    if skinned[tick] then return end
    skinned[tick] = true
    tick:SetSize(32, 32)
    ns.Dress(tick.Normal, "exhaustionTick", TICK, tick)
    ns.Dress(tick.Highlight, "exhaustionTickHighlight", TICK_HL, tick)
end

local function TickBack(tick, look)
    skinned[tick] = nil
    tick:SetSize(look.tickW, look.tickH)
    local normal, highlight = tick.Normal, tick.Highlight
    if normal and look.normal then
        ns.UntintBronze(normal)
        ns.UnswapBronze(normal)
        normal:SetAtlas(look.normal)
    end
    if highlight and look.highlight then
        ns.UnswapBronze(highlight)
        highlight:SetAtlas(look.highlight)
    end
end

-- Band off, sizes already back: the client's fill (white, its atlas), backing, run, tick and fades.
function B.StatusLookBack()
    ShowBacks()
    for anim, was in pairs(fades) do
        anim:SetDuration(was[1])
        anim:SetStartDelay(was[2])
    end
    wipe(fades)
    for bar, look in pairs(looks) do
        local status, run, tick = bar.StatusBar, bar.ExhaustionLevelFillBar, bar.ExhaustionTick
        if status then
            if status.fcuiAtlas then status:SetStatusBarTexture(status.fcuiAtlas) end
            status:SetStatusBarColor(1, 1, 1)
            if status.Background then status.Background:SetAlpha(1) end
        end
        if run and look.atlas then
            run:SetParent(look.parent)
            if look.layer then run:SetDrawLayer(look.layer, look.sub) end
            run:SetAtlas(look.atlas)
            run:SetVertexColor(1, 1, 1, 1)
            ns.SetPointOnce(run, "BOTTOMLEFT", look.parent, "BOTTOMLEFT", 0, 0)
            run:SetHeight(look.height)
        end
        if tick and look.tickW then
            TickBack(tick, look)
            -- The client sizes the run and places the tick only on XP events: once now, at its own width.
            if tick.UpdateTickPosition then tick:UpdateTickPosition() end
        end
    end
end
