local _, ns = ...

-- The game's damage meter windows in the professions window's look: one box in the game menu's metal border, stone
-- over the trainer's divider bar, marble (or a talent tree) under it. Chrome only, never rows or data; dressed as the
-- meter shows and after clicks, in the next frame.

local EDGE = 16
local INSET = EDGE / 4
local OUT = 4           -- the box's metal past the window's sides and foot
-- The meter's header is 32 with its rows right under it: extra height (option) goes over the window, and its
-- buttons and title rise to the stone's middle.
ns.METER_HEADER_MIN, ns.METER_HEADER_MAX = 0, 16
local BASE_TOP = -2
-- The client's header: minimize 19 tall; the timer's top 4 under the button's (the title hangs off the timer).
local MIN_H, TIMER_UNDER = 19, 4

local function HeaderExtra()
    local extra = tonumber(ns.db and ns.db.meterHeader) or 6
    return math.max(ns.METER_HEADER_MIN, math.min(ns.METER_HEADER_MAX, extra))
end

local KNOB_IN = 3       -- the divider's ends inside the side rails
local DIVIDER_Y = -28   -- the divider bar's middle, at the foot of the meter's 32 px header
-- The trainer's bar sheet: a 256 px run with its left knob, then a 76 px right end, each 16 rows round an 8 px bar.
local BAR_FILE = "Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar"
local BAR_H, BAR_END_W = 16, 76
local MARBLE_TILE, MARBLE = { coords = { 0, 1, 0, 1 } }, 1.35
local CLIENT_BACK = "damagemeters-background"
-- Body backgrounds: the marble, or a 1.x talent tree drawn at its own size from its top right corner, cropped.
local TALENT_ART = "Interface\\TalentFrame\\"
local TREES = { "DruidBalance", "DruidFeralCombat", "DruidRestoration", "HunterBeastMastery", "HunterMarksmanship",
    "HunterSurvival", "MageArcane", "MageFire", "MageFrost", "PaladinHoly", "PaladinProtection", "PaladinCombat",
    "PriestDiscipline", "PriestHoly", "PriestShadow", "RogueAssassination", "RogueCombat", "RogueSubtlety",
    "ShamanElementalCombat", "ShamanEnhancement", "ShamanRestoration", "WarlockCurses", "WarlockSummoning",
    "WarlockDestruction", "WarriorArms", "WarriorFury", "WarriorProtection" }
-- The tree art's pieces: painted 300 x 331 (the right files 44 of 64 columns, the lower 75 of 128 rows).
local TREE_BLANK_RIGHT = 20
local TREE_PIECES = {
    { key = "TopRight", w = 64, h = 256 }, { key = "TopLeft", w = 256, h = 256 },
    { key = "BottomRight", w = 64, h = 75, v1 = 75 / 128 }, { key = "BottomLeft", w = 256, h = 75, v1 = 75 / 128 },
}
ns.METER_BACKGROUNDS = { { key = "marble", label = "Marble" } }
for _, tree in ipairs(TREES) do
    local class, spec = tree:match("^(%u%l+)(.+)$")
    ns.METER_BACKGROUNDS[#ns.METER_BACKGROUNDS + 1] = { key = tree, label = class .. ": " .. spec:gsub("(%l)(%u)", "%1 %2") }
end
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
local sources = setmetatable({}, { __mode = "k" })   -- detail window -> our box
local boxes = setmetatable({}, { __mode = "k" })   -- session window -> its box, divider, floors and tree
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
    -- Centred on the stone at any header height; the timer keeps the client's place under the button.
    local mid = boxes[window] and boxes[window].mid
    if mid then
        ns.SetPointOnce(minimize, "RIGHT", mid, "RIGHT", -3, 0)
        if window.SessionTimer then
            ns.SetPointOnce(window.SessionTimer, "TOPLEFT", mid, "LEFT", 1, MIN_H / 2 - TIMER_UNDER)
        end
    end
    local settings, session, kind = window.SettingsDropdown, window.SessionDropdown, window.DamageMeterTypeDropdown
    -- In one row with the minimize button, on its middle line.
    if settings then ns.SetPointOnce(settings, "RIGHT", minimize, "LEFT", -3, 0) end
    if session and settings then ns.SetPointOnce(session, "RIGHT", settings, "LEFT", -3, 0) end
    Face(settings, BLANK, GEAR, settings and settings.Icon)
    Face(session, BLANK, nil, session and session.Background)
    if session and session.Arrow then ns.SetAlphaIf(session.Arrow, 0) end
    if kind and kind.Arrow then Face(kind, ARROW, nil, kind.Arrow, OffsetTo(minimize, kind)) end
end

local function BarPiece(box, u1, v0, v1)
    local tex = box:CreateTexture(nil, "OVERLAY")
    ns.SetFile(tex, BAR_FILE)
    tex:SetTexCoord(0, u1, v0, v1)
    tex:SetHeight(BAR_H)
    return tex
end

-- Under the meter's rows and buttons: one level below the window.
local function Boxes(window)
    local pair = boxes[window]
    if pair then return pair end
    local level = math.max(0, window:GetFrameLevel() - 1)
    local box = ns.SkillInsetBox(window, EDGE, true)
    box:SetFrameLevel(level)
    local stone = ns.TileTex(box:CreateTexture(nil, "BACKGROUND"), "rockBg")
    stone:SetPoint("TOPLEFT", box, "TOPLEFT", INSET, -INSET)
    stone:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", OUT - INSET, DIVIDER_Y)
    -- The divider across the whole box, its knobs on the side rails as on the trainer.
    local barEnd = BarPiece(box, BAR_END_W / 256, 0.25, 0.5)
    barEnd:SetWidth(BAR_END_W)
    barEnd:SetPoint("TOPRIGHT", window, "TOPRIGHT", OUT - KNOB_IN, DIVIDER_Y + BAR_H / 2)
    local barRun = BarPiece(box, 1, 0, 0.25)
    barRun:SetPoint("TOPLEFT", window, "TOPLEFT", -OUT + KNOB_IN, DIVIDER_Y + BAR_H / 2)
    barRun:SetPoint("TOPRIGHT", barEnd, "TOPLEFT")
    -- The body in the container the meter hides when minimized: marble, and the tree art clipped over it.
    local body = CreateFrame("Frame", nil, window.MinimizeContainer or window)
    body:SetFrameLevel(level)
    body:SetPoint("TOPLEFT", window, "TOPLEFT", INSET - OUT, DIVIDER_Y)
    body:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", OUT - INSET, INSET - OUT)
    local floor = ns.TileTex(body:CreateTexture(nil, "BACKGROUND"), "marbleBg", MARBLE_TILE, MARBLE)
    floor:SetAllPoints(body)
    local clip = CreateFrame("Frame", nil, body)
    clip:SetAllPoints(body)
    clip:SetClipsChildren(true)
    local canvas = CreateFrame("Frame", nil, clip)
    canvas:SetAllPoints(clip)
    local tree = {}
    for i, piece in ipairs(TREE_PIECES) do
        local tex = canvas:CreateTexture(nil, "BACKGROUND")
        tex:SetSize(piece.w, piece.h)
        tex:SetTexCoord(0, 1, 0, piece.v1 or 1)
        tree[i] = tex
    end
    tree[1]:SetPoint("TOPRIGHT", canvas, "TOPRIGHT", TREE_BLANK_RIGHT, 0)
    tree[2]:SetPoint("TOPRIGHT", tree[1], "TOPLEFT")
    tree[3]:SetPoint("TOPRIGHT", tree[1], "BOTTOMRIGHT")
    tree[4]:SetPoint("TOPRIGHT", tree[3], "TOPLEFT")
    -- The stone that shows: from the metal's inner edge to the divider bar's top (its 8 px bar mid-sheet).
    local mid = CreateFrame("Frame", nil, box)
    mid:SetPoint("TOPLEFT", stone, "TOPLEFT")
    mid:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", 0, DIVIDER_Y + BAR_H / 4)
    pair = { mid = mid, box = box, bar = { barRun, barEnd }, body = body, floor = floor, canvas = canvas, tree = tree }
    boxes[window] = pair
    return pair
end

-- Minimized, the box closes under the stone and the divider goes.
local function Fold(window, pair)
    local open = not window.MinimizeContainer or window.MinimizeContainer:IsShown()
    local extra = HeaderExtra()
    if pair.open == open and pair.extra == extra then return end
    pair.open, pair.extra = open, extra
    local box = pair.box
    ns.SetPointOnce(box, "TOPLEFT", window, "TOPLEFT", -OUT, BASE_TOP + HeaderExtra())
    if open then
        box:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", OUT, -OUT)
    else
        -- Minimized, the divider is the foot: the box's own edge tucked under the bar, so the stone ends where it does open.
        box:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", OUT, DIVIDER_Y - BAR_H / 4)
    end
end

-- The picked tree's files, or none for the marble.
local function PaintTree(pair)
    local pick = ns.db and ns.db.meterBackground
    local name = pick ~= "marble" and pick or nil
    if pair.treeName == name then return end
    pair.treeName = name
    for i, piece in ipairs(TREE_PIECES) do
        if name then pair.tree[i]:SetTexture(TALENT_ART .. name .. "-" .. piece.key) end
    end
    pair.canvas:SetShown(name ~= nil)
end

-- The detail window a row opens: the meter's marble in the metal border, the old scroll bar and close button.
local function DressSource(window)
    local source = window.MinimizeContainer and window.MinimizeContainer.SourceWindow
    if not source then return end
    local box = sources[source]
    if not box then
        box = ns.SkillInsetBox(source, EDGE)
        box:SetFrameLevel(math.max(0, source:GetFrameLevel() - 1))
        box:SetPoint("TOPLEFT", source, "TOPLEFT", -OUT, OUT)
        box:SetPoint("BOTTOMRIGHT", source, "BOTTOMRIGHT", OUT, -OUT)
        sources[source] = box
        ns.SkinMinimalScrollBar(source.ScrollBar)
        if source.CloseButton then ns.SkinCloseButton(source.CloseButton, true) end
    end
    box:Show()
    if source.Background then ns.SetAlphaIf(source.Background, 0) end
end

local function Dress(window)
    local pair = Boxes(window)
    pair.box:Show()
    pair.body:Show()
    Fold(window, pair)
    if window.Header then ns.SetAlphaIf(window.Header, 0) end
    -- The meter's own back goes; its opacity setting fades our marble instead.
    local back = window.MinimizeContainer and window.MinimizeContainer.Background
    if back then
        if back:GetTexture() then back:SetTexture(nil) end
        local alpha = back:GetAlpha()
        if type(alpha) == "number" and not ns.IsSecret(alpha) then
            pair.floor:SetAlpha(alpha)
        end
    end
    PaintTree(pair)
    DressMinimize(window)
    DressButtons(window)
    DressSource(window)
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
    for source, box in pairs(sources) do
        box:Hide()
        if source.Background then ns.SetAlphaIf(source.Background, 1) end
    end
    for window, pair in pairs(boxes) do
        pair.box:Hide()
        pair.body:Hide()
        if window.Header and window.MinimizeButton then
            ns.SetPointOnce(window.MinimizeButton, "TOPRIGHT", window.Header, "TOPRIGHT", -3, -5)
        end
        if window.Header and window.SessionTimer then
            ns.SetPointOnce(window.SessionTimer, "TOPLEFT", window.Header, "TOPLEFT", 1, -9)
        end
        if window.Header then ns.SetAlphaIf(window.Header, 1) end
        local back = window.MinimizeContainer and window.MinimizeContainer.Background
        if back then back:SetAtlas(CLIENT_BACK) end
    end
    for _, face in pairs(faces) do
        face.tex:Hide()
        if face.glyph then face.glyph:Hide() end
        if face.hidden then ns.SetAlphaIf(face.hidden, 1) end
    end
end

-- The header height picked in the options.
function ns.SetMeterHeader(value)
    ns.db.meterHeader = math.max(ns.METER_HEADER_MIN, math.min(ns.METER_HEADER_MAX, math.floor(tonumber(value) or 6)))
    DressAll()
end

-- A background picked in the options.
function ns.SetMeterBackground(key, value)
    ns.db[key] = value
    DressAll()
end

ns.RegisterModule("damageMeter", { apply = Apply, restore = Restore })
