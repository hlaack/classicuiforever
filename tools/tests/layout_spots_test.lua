-- Offline tests for Options/Layout.lua under Lua 5.4: the classic layout's durability beside the side bars (pinned bars
-- leave the client's right-side container at the screen edge) and buffs at Era's spots; pieces a player placed stay.
-- Run from the addon root: lua tools/tests/layout_spots_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client

Enum = {
    EditModeSystem = { ObjectiveTracker = 12, AuraFrame = 7, DurabilityFrame = 20, ActionBar = 0 },
    EditModeAuraFrameSystemIndices = { BuffFrame = 1, DebuffFrame = 2 },
}
local durabilityScale = 1
DurabilityFrame = { GetScale = function() return durabilityScale end }

------------------------------------------------------------------ the addon

local noop = function() end
local sideWidth = 98
local layout, reported
local ns = {
    L = setmetatable({}, { __index = function(_, key) return key end }),
    options = { TITLE = "ClassicUI Forever" },
    db = {},
    band = { SideColumnsWidth = function() return sideWidth end },
    ActiveLayoutInfo = function() return layout end,
    ReloadPopup = noop, Popup = noop,
    SafeCall = function(fn, ...) return xpcall(fn, function(err) reported = err end, ...) end,
}
assert(loadfile(ROOT .. "/Options/Layout.lua"))("ClassicUIForever", ns)

------------------------------------------------------------------ checks

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end
local function Spot(system)
    local a = system.anchorInfo
    return string.format("%s %s %s %g,%g default %s", a.point, tostring(a.relativeTo), a.relativePoint, a.offsetX, a.offsetY,
        tostring(system.isInDefaultPosition))
end

-- Forever's Classic preset as the classic layout starts: every piece at its default.
local function Preset()
    return {
        { system = Enum.EditModeSystem.DurabilityFrame, isInDefaultPosition = true,
            anchorInfo = { point = "RIGHT", relativeTo = "UIParent", relativePoint = "RIGHT", offsetX = 0, offsetY = 0 } },
        { system = Enum.EditModeSystem.AuraFrame, systemIndex = 1, isInDefaultPosition = true,
            anchorInfo = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "TOPRIGHT", offsetX = -255, offsetY = -10 } },
        { system = Enum.EditModeSystem.AuraFrame, systemIndex = 2, isInDefaultPosition = true,
            anchorInfo = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "TOPRIGHT", offsetX = -270, offsetY = -155 } },
    }
end

ns.sessionEnding = true
layout = { layoutName = "ClassicUI Forever", systems = Preset() }
local doll, buffs, debuffs = layout.systems[1], layout.systems[2], layout.systems[3]
Check(ns.PlaceClassicSpots() == true, "a fresh copy of the preset changes")
Check(Spot(doll) == "TOPRIGHT UIParent TOPRIGHT -103,-192 default false", "durability beside the side bars, Era's height: " .. Spot(doll))
Check(Spot(buffs) == "TOPRIGHT UIParent TOPRIGHT -187,-13 default false", "buffs at Era's spot: " .. Spot(buffs))
Check(Spot(debuffs) == "TOPRIGHT UIParent TOPRIGHT -202,-152 default false", "debuffs at Era's spot: " .. Spot(debuffs))
Check(ns.PlaceClassicSpots() == false, "a second pass writes nothing")

-- One side column turned off: ours follows.
sideWidth = 50
Check(ns.PlaceClassicSpots() == true, "the side bars changed: durability follows")
Check(Spot(doll) == "TOPRIGHT UIParent TOPRIGHT -55,-192 default false", "durability follows the side bars: " .. Spot(doll))

-- Placed by the player in edit mode: left alone.
doll.anchorInfo = { point = "BOTTOMLEFT", relativeTo = "UIParent", relativePoint = "BOTTOMLEFT", offsetX = 300, offsetY = 400 }
buffs.anchorInfo = { point = "TOPRIGHT", relativeTo = "UIParent", relativePoint = "TOPRIGHT", offsetX = -300, offsetY = -13 }
sideWidth = 98
Check(ns.PlaceClassicSpots() == false, "pieces the player placed stay")
Check(Spot(doll) == "BOTTOMLEFT UIParent BOTTOMLEFT 300,400 default false", "the player's durability spot stays: " .. Spot(doll))
Check(Spot(buffs) == "TOPRIGHT UIParent TOPRIGHT -300,-13 default false", "the player's buff spot stays: " .. Spot(buffs))

-- A doll at 200%: offsets are in its scale.
layout = { layoutName = "ClassicUI Forever", systems = Preset() }
durabilityScale = 2
ns.PlaceClassicSpots()
Check(Spot(layout.systems[1]) == "TOPRIGHT UIParent TOPRIGHT -51.5,-96 default false", "a 200% doll: " .. Spot(layout.systems[1]))
durabilityScale = 1

-- Reset classic layout: a piece dragged round the minimap ring goes back to its own spot, with the placed windows.
local classicActive = ns.ClassicLayoutActive
ns.ClassicLayoutActive = function() return true end
function InCombatLockdown() return false end
ns.DB_DEFAULTS = {}
ns.WINDOW_LIST = { { key = "minimapAddonBag", ringKey = "minimapCollectorAngle" }, { key = "character" } }
ns.db = { layoutJobs = { reset = true }, minimapCollectorAngle = 7.4, windowPos = { character = {} } }
-- The rest of the reset is other files' work.
setmetatable(ns, { __index = function() return noop end })
ns.RunLayoutJobsBeforePin()
setmetatable(ns, nil)
ns.ClassicLayoutActive = classicActive
Check(ns.db.minimapCollectorAngle == nil and ns.db.windowPos == nil, "the reset clears ring spots and window places")
ns.db = {}

-- Another layout, or outside the session's end write: nothing.
layout = { layoutName = "Mine", systems = Preset() }
Check(ns.PlaceClassicSpots() == false and layout.systems[1].isInDefaultPosition == true, "a player's own layout is never touched")
layout = { layoutName = "ClassicUI Forever", systems = Preset() }
ns.sessionEnding = false
Check(ns.PlaceClassicSpots() == false and layout.systems[2].anchorInfo.offsetX == -255, "nothing mid-session")

-- The reload press: the classic layout failing to build still leaves Era's size written after it, and the error is
-- reported, not swallowed (a first setup lost its size that way, with nothing to see).
local sized = false
reported = nil
ns.sessionEnding = true
ns.db = { layoutJobs = { classic = { counts = {} }, eraScale = true } }
ns.BandPinAnchors = function() return {} end
ns.EraScaleAfterPin = function() sized = true end
EditModeManagerFrame = { layoutInfo = { layouts = {} }, GetLayouts = function() return {} end }
C_EditMode = { SaveLayouts = noop, SetActiveLayout = noop }
EditModePresetLayoutManager = { GetCopyOfPresetLayouts = function() error("no presets on this client") end }
ns.RunLayoutJobsAfterPin()
Check(sized, "Era's size is written though the layout step failed")
Check(type(reported) == "string" and reported:find("no presets on this client", 1, true) ~= nil, "the layout step's error is reported")
Check(ns.db.layoutJobs == nil, "the jobs are taken off, so a failing one does not run at every reload")
ns.sessionEnding = false

if failures > 0 then
    print(string.format("layout spots: %d failed", failures))
    os.exit(1)
end
print("layout spots: ok")
