local _, ns = ...

-- The game's personal resource display as 1.x nameplates: the old fill (the game still colours it by health and power
-- type), the plate's border round each bar without its level slot, a plain dark back. It follows each bar's size.

local FILL_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local BACK_ATLAS = "UI-HUD-CoolDownManager-Bar-BG"
local BAR_ATLAS = "UI-HUD-CoolDownManager-Bar"
local BACK = { 0, 0, 0, 0.5 }
-- The plate sheet's lower half: an 8 px bar with 4 px rails above and below, a round end 5 past the bar's end.
local PLATE_V0, PLATE_V1, PLATE_BAR_H, PLATE_END = 0.5, 1, 8, 5
local CAP_U, RAIL_U1 = 8 / 128, 48 / 128   -- round end with the rail's start; a plain run of rail

local active = false
local own = setmetatable({}, { __mode = "k" })    -- status bar -> { left, mid, right, back }

local function Bars()
    local prd = _G.PersonalResourceDisplayFrame
    if not prd then return nil end
    local container = prd.HealthBarsContainer
    return container and container.healthBar, prd.PowerBar, prd.AlternatePowerBar
end

local function FindBack(region, parts)
    if region.GetAtlas and region:GetAtlas() == BACK_ATLAS then parts.back = region end
end

-- Scaled to the bar's height: left end, rail stretched along, the left end mirrored.
local function Fit(bar)
    local parts = own[bar]
    if not parts then return end
    local k = (bar:GetHeight() or 0) / PLATE_BAR_H
    local out, cap, rail = PLATE_END * k, CAP_U * 128 * k, PLATE_BAR_H / 2 * k
    local left, mid, right = parts.left, parts.mid, parts.right
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", bar, "TOPLEFT", -out, rail)
    left:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", cap - out, -rail)
    right:ClearAllPoints()
    right:SetPoint("TOPRIGHT", bar, "TOPRIGHT", out, rail)
    right:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", out - cap, -rail)
    mid:ClearAllPoints()
    mid:SetPoint("TOPLEFT", left, "TOPRIGHT")
    mid:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
end

local function Piece(bar, u0, u1)
    local tex = bar:CreateTexture(nil, "OVERLAY", nil, 2)
    ns.SetTex(tex, "nameplateBorder")
    tex:SetTexCoord(u0, u1, PLATE_V0, PLATE_V1)
    return tex
end

local function ShowFrame(parts, shown)
    parts.left:SetShown(shown)
    parts.mid:SetShown(shown)
    parts.right:SetShown(shown)
end

local function Resized(bar)
    if active then Fit(bar) end
end

local function Dress(bar)
    if not bar then return end
    local parts = own[bar]
    if not parts then
        parts = {}
        parts.left = Piece(bar, 0, CAP_U)
        parts.mid = Piece(bar, CAP_U, RAIL_U1)
        parts.right = Piece(bar, CAP_U, 0)
        ns.EachRegion(bar, FindBack, parts)
        own[bar] = parts
        ns.HookScriptOnce(bar, "OnSizeChanged", Resized)
    end
    bar:SetStatusBarTexture(FILL_TEXTURE)
    if parts.back then parts.back:SetColorTexture(BACK[1], BACK[2], BACK[3], BACK[4]) end
    ShowFrame(parts, true)
    Fit(bar)
end

local function Undress(bar)
    local parts = bar and own[bar]
    if not parts then return end
    bar:SetStatusBarTexture(BAR_ATLAS)
    if parts.back then parts.back:SetAtlas(BACK_ATLAS) end
    ShowFrame(parts, false)
end

local function Apply()
    active = true
    local health, power, alternate = Bars()
    ns.SafeCall(Dress, health)
    ns.SafeCall(Dress, power)
    ns.SafeCall(Dress, alternate)
end

local function Restore()
    if not active then return end
    active = false
    local health, power, alternate = Bars()
    ns.SafeCall(Undress, health)
    ns.SafeCall(Undress, power)
    ns.SafeCall(Undress, alternate)
end

ns.RegisterModule("resourceDisplay", { apply = Apply, restore = Restore })
