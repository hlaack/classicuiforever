-- Offline tests for Bar/BandBare.lua under Lua 5.4: on our layout bar 1's Hide Bar Art counts only as the player's own
-- tick in edit mode, an install from before keeps what its layout held, and another layout follows the client's flag.
-- Run from the addon root: lua tools/tests/bar_art_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client and addon

Enum = {
    EditModeSystem = { ActionBar = 0 },
    EditModeActionBarSystemIndices = { MainBar = 1, Bar2 = 2 },
    EditModeActionBarSetting = { NumIcons = 2, HideBarArt = 5 },
}
local bar = {}
local ours = true
local art = { setting = 5, value = 0 }
local layout = { systems = {
    { system = 0, systemIndex = 2, settings = { { setting = 2, value = 12 } } },
    { system = 0, systemIndex = 1, settings = { { setting = 2, value = 12 }, art } },
} }
local B = {}
local ns = {
    band = B,
    GetMainBar = function() return bar end,
    ClassicLayoutActive = function() return ours end,
    ActiveLayoutInfo = function() return layout end,
}
assert(loadfile(ROOT .. "/Bar/BandBare.lua"))("ClassicUIForever", ns)

-- The client's side of a tick, a layout switch or a write from elsewhere: the data and the bar's field together.
local function Flag(hidden)
    art.value = hidden and 1 or 0
    bar.hideBarArt = hidden
end

------------------------------------------------------------------ checks

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end

Check(B.LayoutArtEntry() == art, "bar 1's entry is found in the layout data")

-- A new install: hidden in the layout by another hand, never ticked.
ns.db = { barArtHidden = false }
Flag(true)
Check(B.BarBare(bar) == false, "hidden in our layout with no tick of the player's: the art shows")
B.WatchArtTick(false)
Check(ns.db.barArtHidden == false, "a beat out of edit mode records nothing")

-- Edit mode opened and shut with the box untouched.
B.WatchArtTick(true)
B.WatchArtTick(true)
B.WatchArtTick(false)
Check(ns.db.barArtHidden == false and B.BarBare(bar) == false, "edit mode opened and shut untouched: still shown")

-- The player unticks, then ticks: hidden from the tick on, and kept as edit mode shuts.
B.WatchArtTick(true)
Flag(false)
B.WatchArtTick(true)
Check(B.BarBare(bar) == false, "unticked: shown")
Flag(true)
B.WatchArtTick(true)
Check(B.BarBare(bar) == true, "ticked in edit mode: hidden at once")
B.WatchArtTick(false)
Check(ns.db.barArtHidden == true and B.BarBare(bar) == true, "the tick is kept as edit mode shuts")

-- Unticked again: shown and recorded; a tick between the last beat and the shut still counts.
B.WatchArtTick(true)
Flag(false)
B.WatchArtTick(false)
Check(ns.db.barArtHidden == false and B.BarBare(bar) == false, "unticked just before edit mode shuts: recorded")

-- A layout switch in edit mode flips the flag and is not a tick.
ns.db.barArtHidden = false
Flag(false)
B.WatchArtTick(true)
ours = false
Flag(true)
B.WatchArtTick(true)
Check(B.BarBare(bar) == true, "another layout follows the client's flag")
ours = true
B.WatchArtTick(true)
B.WatchArtTick(false)
Check(ns.db.barArtHidden == false and B.BarBare(bar) == false, "back on ours through a switch: no tick recorded")

-- Upgraders: hidden in our layout before, hidden still; shown before, a later write from elsewhere is not theirs.
ns.db = { dbVersion = 8 }
ns.KeepBarArt()
Check(ns.db.dbVersion == 9 and ns.db.barArtKeep == true, "the migration writes dbVersion 9 and waits for the layout")
Flag(true)
Check(B.BarBare(bar) == true and ns.db.barArtHidden == true and ns.db.barArtKeep == nil, "hidden before: kept hidden")
ns.db = { dbVersion = 8 }
ns.KeepBarArt()
Flag(false)
Check(B.BarBare(bar) == false and ns.db.barArtKeep == nil, "shown before: read once")
Flag(true)
Check(B.BarBare(bar) == false, "then hidden from elsewhere: the art shows")

-- An upgrader on another layout at the first login: read when ours is first up.
ns.db = { dbVersion = 8 }
ns.KeepBarArt()
ours = false
Flag(true)
Check(B.BarBare(bar) == true and ns.db.barArtKeep == true, "on another layout the read waits")
ours = true
Check(B.BarBare(bar) == true and ns.db.barArtHidden == true, "ours first up: its hidden art kept")

if failures > 0 then
    print(string.format("bar art: %d failed", failures))
    os.exit(1)
end
print("bar art: ok")
