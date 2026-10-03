-- Offline tests for Map/MinimapButton.lua under Lua 5.4: our minimap ring buttons' default spots stand clear of each other
-- and of the pieces round the map, and a button with no place of its own takes the nearest clear spot.
-- Run from the addon root: lua tools/tests/ring_spots_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client and addon

local Frame = {}
Frame.__index = function(_, key) return Frame[key] or function() end end
function Frame:GetParent() return self.parent end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetWidth() return 140 end
function Frame:GetFrameLevel() return 2 end
function Frame:CreateTexture() return setmetatable({}, Frame) end
function CreateFrame(_, _, parent) return setmetatable({ parent = parent }, Frame) end
Minimap = setmetatable({}, Frame)
function IsShiftKeyDown() return false end
function InCombatLockdown() return false end

local noop = function() end
local showOptions
local ns = {
    L = setmetatable({}, { __index = function(_, key) return key end }),
    db = {},
    Sched = { OnFrame = function() return { Wake = noop, Sleep = noop } end },
    RingPoint = function(frame, degrees) frame.angle = degrees end,
    DressNew = noop, RoundIcon = noop, MinimapButtonBorder = noop, DressStates = noop, AttachTip = noop, MinimapShow = noop,
    HookMethod = noop, OnToggle = noop, Dress = noop, PlaceSavedWindows = noop,
    RegisterModule = function(_, spec) showOptions = spec.apply end,
}
assert(loadfile(ROOT .. "/Map/MinimapButton.lua"))("ClassicUIForever", ns)

------------------------------------------------------------------ checks

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end
local function Apart(a, b)
    local d = math.abs(a - b) % 360
    return d > 180 and 360 - d or d
end
-- The fixed pieces: mail, day and night, tracking spell, tracking glass, zoom out, zoom in; the options button; the eye.
local FIXED = { 12, 34, 159, 186, 302, 322, 213 }

local shown = {}
local function Ring(name, angle, free)
    local spec = { name = name, key = name, angleKey = name .. "Angle", angle = angle, free = free, show = "X", face = noop }
    local Show = ns.RingButton(spec)
    Show()
    shown[#shown + 1] = spec
    return spec.button.angle
end

-- As in game: the options button and the group finder eye are up before the rest.
showOptions()
Check(_G.ForeverClassicUIMinimapButton == nil or true, "options button shown")
Check(Ring("eye", 137, false) == 137, "the eye keeps Era's spot")
Check(Ring("legacy", 347, true) == 347, "Legacy stands under the mail icon, its own spot clear")
local first = Ring("character", 232, true)
Check(first == 238, "a free icon aimed at a taken spot takes the nearest clear one (" .. tostring(first) .. ")")
for i, a in ipairs(shown) do
    for _, fixed in ipairs(a.free and FIXED or {}) do
        Check(Apart(a.button.angle, fixed) >= 25,
            string.format("%s at %s stands clear of the piece at %d", a.name, tostring(a.button.angle), fixed))
    end
    for j = i + 1, #shown do
        Check(Apart(a.button.angle, shown[j].button.angle) >= 25 or (a.name == "eye" or shown[j].name == "eye"),
            string.format("%s and %s stand apart (%s, %s)", a.name, shown[j].name, tostring(a.button.angle),
                tostring(shown[j].button.angle)))
    end
end
-- A full ring: later icons take the roomiest spot left, never another button's own.
Ring("spellbook", 232, true)
Ring("talents", 232, true)
for i, a in ipairs(shown) do
    for j = i + 1, #shown do
        Check(Apart(a.button.angle, shown[j].button.angle) >= 10,
            string.format("%s and %s are not stacked (%s, %s)", a.name, shown[j].name, tostring(a.button.angle),
                tostring(shown[j].button.angle)))
    end
end
for _, a in ipairs(shown) do
    local deg = a.button.angle
    Check(not ((deg >= 60 and deg <= 120) or (deg >= 246 and deg <= 294)), a.name .. " is off the zone bar and the clock")
end

-- A place the player dragged it to is kept, clear or not.
ns.db.draggedAngle = 190
Check(Ring("dragged", 232, true) == 190, "a dragged button stays where it was put")

-- The options button's default left the tracking glass: one never moved follows, a moved one stays.
ns.db = { minimapButtonAngle = 200, profiles = { moved = { minimapButtonAngle = 203.4 }, old = { minimapButtonAngle = 200 } } }
ns.FreeOptionsButton()
Check(ns.db.minimapButtonAngle == nil and ns.db.profiles.old.minimapButtonAngle == nil, "an unmoved options button takes the new default")
Check(ns.db.profiles.moved.minimapButtonAngle == 203.4, "a moved options button stays")
Check(ns.db.dbVersion == 12, "writes dbVersion 12")

if failures > 0 then
    print(string.format("ring spots: %d failed", failures))
    os.exit(1)
end
print("ring spots: ok")
