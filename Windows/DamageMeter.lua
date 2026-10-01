local _, ns = ...

-- The game's damage meter windows in the 1.x tooltip rim, its modern header bar gone. Window chrome only: nothing of
-- the meter's rows or data is touched. Windows are dressed as the meter shows and after a click (new windows come
-- from its menu), in the next frame, outside the meter's own code.

local RIM_OUT = 4
local FALLBACK_MAX = 5
-- 1.x art for its buttons: the old minus and plus for minimize; the chat's square arrow button for the type list,
-- and the same square with the arrow taken out (ours) behind the gear and the session letter.
local BTN = "Interface\\Buttons\\UI-"
local MEDIA = "Interface\\AddOns\\ClassicUIForever\\media\\"
local ARROW = { up = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up", down = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down" }
local BLANK = { up = MEDIA .. "UI-ChatIcon-Blank-Up", down = MEDIA .. "UI-ChatIcon-Blank-Down" }
local GEAR = "Interface\\Buttons\\UI-OptionsButton"
local FACE, GLYPH = 24, 14

local active = false
local rims = setmetatable({}, { __mode = "k" })    -- session window -> our rim
local faces = setmetatable({}, { __mode = "k" })   -- meter button -> our face (and glyph)

local function Windows()
    return tonumber(_G.MAX_DAMAGE_METER_SESSION_WINDOWS) or FALLBACK_MAX
end

-- The meter re-sets the minimize art on every minimize: dressed again after each click.
local function DressMinimize(window)
    local button = window.MinimizeButton
    local container = window.MinimizeContainer
    if not (button and container) then return end
    local minimized = not container:IsShown()
    local face = minimized and "PlusButton" or "MinusButton"
    button:GetNormalTexture():SetTexture(BTN .. face .. "-Up")
    button:GetPushedTexture():SetTexture(BTN .. face .. "-Down")
    button:GetHighlightTexture():SetTexture(BTN .. "PlusButton-Hilight")
end

local function Press(face, down)
    face.tex:SetTexture(down and face.art.down or face.art.up)
    if face.glyph then ns.SetPointOnce(face.glyph, "CENTER", face.tex, "CENTER", down and 1 or 0, down and -1 or 0) end
end

-- A square classic face on a meter button, under its own text; centred at the minimize button's height (dy).
local function Face(button, art, glyph, hide, dy)
    if not button then return end
    if hide then ns.SetAlphaIf(hide, 0) end
    local face = faces[button]
    if not face then
        face = { art = art }
        face.tex = button:CreateTexture(nil, "BACKGROUND", nil, 7)
        face.tex:SetSize(FACE, FACE)
        if glyph then
            face.glyph = button:CreateTexture(nil, "ARTWORK", nil, 7)
            face.glyph:SetSize(GLYPH, GLYPH)
            face.glyph:SetTexture(glyph)
        end
        faces[button] = face
        button:HookScript("OnMouseDown", function() Press(face, true) end)
        button:HookScript("OnMouseUp", function() Press(face, false) end)
    end
    face.hidden = hide
    ns.SetPointOnce(face.tex, "CENTER", button, "CENTER", 0, dy or 0)
    face.tex:Show()
    if face.glyph then face.glyph:Show() end
    Press(face, false)
end

-- How far below or above the minimize button's middle a region sits (both in the window's units).
local function OffsetTo(minimize, region)
    local _, my = minimize:GetCenter()
    local _, ry = region:GetCenter()
    if not (my and ry) or ns.AnySecret(my, ry) then return 0 end
    return my - ry
end

local function DressButtons(window)
    local minimize = window.MinimizeButton
    if not minimize then return end
    local settings, session, kind = window.SettingsDropdown, window.SessionDropdown, window.DamageMeterTypeDropdown
    -- In one row with the minimize button, on its middle line.
    if settings then ns.SetPointOnce(settings, "RIGHT", minimize, "LEFT", -3, 0) end
    if session and settings then ns.SetPointOnce(session, "RIGHT", settings, "LEFT", -3, 0) end
    Face(settings, BLANK, GEAR, settings and settings.Icon)
    Face(session, BLANK, nil, session and session.Background)
    if session and session.Arrow then ns.SetAlphaIf(session.Arrow, 0) end
    if kind and kind.Arrow then Face(kind, ARROW, nil, kind.Arrow, OffsetTo(minimize, kind)) end
end

local function Dress(window)
    local rim = rims[window]
    if not rim then
        rim = ns.TipRim(window, -RIM_OUT, RIM_OUT, RIM_OUT, -RIM_OUT)
        -- In the container the meter hides when minimized, so the rim goes with it.
        if window.MinimizeContainer then rim:SetParent(window.MinimizeContainer) end
        rims[window] = rim
    end
    rim:Show()
    if window.Header then ns.SetAlphaIf(window.Header, 0) end
    DressMinimize(window)
    DressButtons(window)
end

local function DressAll()
    if not active then return end
    for i = 1, Windows() do
        local window = _G["DamageMeterSessionWindow" .. i]
        if window then ns.SafeCall(Dress, window) end
    end
end

local function Soon()
    if active then ns.Sched.NextFrame("damageMeter.dress", DressAll) end
end

local watching = false
local function Watch()
    if watching or not _G.DamageMeter then return end
    watching = true
    ns.Sched.OnVisible(_G.DamageMeter, "damageMeter.shown", function(shown) if shown then Soon() end end)
    ns.EventFrame("GLOBAL_MOUSE_UP", Soon)
end

local function Apply()
    active = true
    Watch()
    DressAll()
end

local function Restore()
    if not active then return end
    active = false
    for window, rim in pairs(rims) do
        rim:Hide()
        if window.Header then ns.SetAlphaIf(window.Header, 1) end
    end
    for _, face in pairs(faces) do
        face.tex:Hide()
        if face.glyph then face.glyph:Hide() end
        if face.hidden then ns.SetAlphaIf(face.hidden, 1) end
    end
end

ns.RegisterModule("damageMeter", { apply = Apply, restore = Restore })
