-- Offline test under Lua 5.4 for the gryphons' places per edit mode layout (UI/WindowLayouts.lua, issue 126). They are
-- kept as the game keeps its own pieces: each layout has its record, a layout picked wears it, Save writes the active
-- layout's, a preset holds none (the game asks for a new layout, which takes the places as it is made), a new
-- character picking a layout gets its places, and an install from before records keeps its one old place on its own
-- layouts. A preset is always home: a place worn there could never be saved away again.
-- Run from the addon root: lua tools/tests/piece_layouts_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 122 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client and addon

Enum = { EditModeLayoutType = { Preset = 0, Account = 1, Character = 2 } }
local PRESET, ACCOUNT, CHARACTER = 0, 1, 2
local clock = 0
function GetTime() return clock end

local layouts, active, editing
EditModeManagerFrame = { GetLayouts = function() return layouts end }
local function Layout(name, kind) return { layoutName = name, layoutType = kind } end

local returned = 0
local ns
local function Table(key)
    if type(ns.db[key]) ~= "table" then ns.db[key] = {} end
    return ns.db[key]
end
ns = {
    db = {}, char = {}, EMPTY = {},
    DbTable = Table,
    EditMode = { Live = function() return editing end },
    ActiveLayoutInfo = function() return layouts and layouts[active] end,
    EventFrame = function() end,
    Sched = { NextFrame = function(_, fn) fn() end },
    windowEdit = {
        WINDOWS = { { key = "character" }, { key = "gryphonLeft", gameEdit = true }, { key = "gryphonRight", gameEdit = true } },
        Places = function() return Table("windowPos") end,
        Scales = function() return Table("windowScale") end,
        Return = function() returned = returned + 1 end,
        PlaceAll = function() end, LayHandle = function() end, Refresh = function() end,
    },
}
assert(loadfile(ROOT .. "/UI/WindowLayouts.lua"))("ClassicUIForever", ns)
local W = ns.windowEdit
local Sync = W.SyncLayoutSpots

------------------------------------------------------------------ the checks

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL " .. what)
    end
end
local function At(key)
    local pos = ns.db.windowPos and ns.db.windowPos[key]
    return pos and (pos[1] .. "," .. pos[2]) or "home"
end
local function Move(key, x, y) Table("windowPos")[key] = { x, y } end
local function Pick(name)
    for i, layout in ipairs(layouts) do
        if layout.layoutName == name then active = i end
    end
    Sync()
end

-- A fresh install on a game preset.
layouts = { Layout("Modern", PRESET), Layout("Classic", PRESET), Layout("Other", ACCOUNT) }
active, editing = 1, false
Sync()
Check(At("gryphonLeft") == "home", "fresh install, a preset: the gryphon at home")

-- Edit mode: a gryphon moved on the preset, Save pressed.
editing = true
W.LayoutEditBegan()
Move("gryphonLeft", 100, 200)
Check(W.SaveLayoutSpots() == false, "Save on a preset writes nothing: the game asks for a new layout")
Check(ns.db.layoutSpots == nil, "no record for a preset")

-- The game makes the layout asked for and picks it.
table.insert(layouts, Layout("Mine", ACCOUNT))
Pick("Mine")
Check(At("gryphonLeft") == "100,200", "the new layout takes the place as it is made (" .. At("gryphonLeft") .. ")")
Check(ns.db.layoutSpots and ns.db.layoutSpots.Mine ~= nil, "and has its record")

-- Layouts picked wear their own.
Pick("Modern")
Check(At("gryphonLeft") == "home" and returned > 0, "back on the preset: home again")
Pick("Mine")
Check(At("gryphonLeft") == "100,200", "the layout picked again: its place")
Move("gryphonLeft", 300, 400)
Table("windowScale").gryphonLeft = 1.2
Check(W.SaveLayoutSpots() == true, "Save on a layout of the player's writes its record")
Pick("Other")
Check(At("gryphonLeft") == "home" and ns.db.windowScale.gryphonLeft == nil, "a layout with no record: home, its own size")
Pick("Mine")
Check(At("gryphonLeft") == "300,400" and ns.db.windowScale.gryphonLeft == 1.2, "the saved place and size come back")

-- A change left unsaved is no part of the record.
Move("gryphonLeft", 999, 999)
Pick("Other")
Pick("Mine")
Check(At("gryphonLeft") == "300,400", "an unsaved move is dropped by a layout switch")

-- A copy takes what stands; a rename keeps the record; a deleted layout's record goes.
table.insert(layouts, Layout("Copy", ACCOUNT))
Sync()
Check(ns.db.layoutSpots.Copy ~= nil and ns.db.layoutSpots.Copy.pos.gryphonLeft[1] == 300, "a copy made in edit mode takes the places")
layouts[4] = Layout("Renamed", ACCOUNT)
Sync()
Check(ns.db.layoutSpots.Renamed ~= nil and ns.db.layoutSpots.Mine == nil, "a renamed layout keeps its record")
Check(At("gryphonLeft") == "300,400", "and its place stands")
table.remove(layouts, 5)
Sync()
Check(ns.db.layoutSpots.Copy == nil, "a deleted layout's record goes")
editing = false

-- A new character on the same account picks the saved layout (the report).
ns.char = {}
Pick("Modern")
Pick("Renamed")
Check(At("gryphonLeft") == "300,400", "a new character picking the layout gets its places")

-- A character's own layout is kept with the character.
editing = true
table.insert(layouts, Layout("Solo", CHARACTER))
Pick("Solo")
Move("gryphonRight", 50, 60)
Check(W.SaveLayoutSpots() == true and ns.char.layoutSpots and ns.char.layoutSpots.Solo ~= nil, "a character layout's record is the character's")
Check(ns.db.layoutSpots.Solo == nil, "and not the account's")
editing = false

-- Save and Exit on a preset: the mode shuts first, the new layout comes a moment later and takes what was left unsaved.
Pick("Modern")
editing = true
W.LayoutEditBegan()
Move("gryphonLeft", 700, 800)
editing = false
W.LayoutEditLeft()
ns.db.windowPos.gryphonLeft = nil
table.insert(layouts, Layout("Exited", ACCOUNT))
clock = clock + 1
Pick("Exited")
Check(At("gryphonLeft") == "700,800", "a layout made as the mode shut takes the unsaved places (" .. At("gryphonLeft") .. ")")

-- Later than that press, a layout appearing is no part of it; out of edit mode nothing is made at all.
Pick("Modern")
editing = true
W.LayoutEditBegan()
Move("gryphonLeft", 11, 22)
editing = false
W.LayoutEditLeft()
ns.db.windowPos.gryphonLeft = nil
clock = clock + 60
table.insert(layouts, Layout("Late", ACCOUNT))
Sync()
Check(ns.db.layoutSpots.Late == nil, "a layout seen a minute later takes nothing")
table.insert(layouts, Layout("LoginPart", ACCOUNT))
Sync()
Check(ns.db.layoutSpots.LoginPart == nil, "a list growing out of edit mode makes no records")

-- An install from before records: its one old place stands on its own layouts without a record, never on a preset.
ns.db = { windowPos = { gryphonLeft = { 5, 6 }, character = { 1, 2 } } }
ns.char = {}
Pick("Modern")
ns.KeepPieceSpots()
Check(ns.db.layoutSpotsOld ~= nil and ns.db.layoutSpotsOld.pos.character == nil, "the upgrade keeps the pieces' old places, the pieces' alone")
layouts = { Layout("Modern", PRESET), Layout("Old", ACCOUNT) }
active = 2
Sync()
Check(At("gryphonLeft") == "5,6", "an old layout keeps the old place")
Pick("Modern")
Check(At("gryphonLeft") == "home", "a preset stands as the game ships it, whatever was moved before (" .. At("gryphonLeft") .. ")")
Check(ns.db.windowPos.character ~= nil, "a window's place is never touched")
Move("gryphonLeft", 70, 80)
Pick("Old")
Check(W.SaveLayoutSpots() == true, "saved on the old layout")
Pick("Modern")
Pick("Old")
Check(At("gryphonLeft") == "5,6", "an unsaved move on the preset did not reach the layout")

Check(ns.db.dbVersion == 15, "the upgrade step runs once: it writes its version")

-- The Classic layout button: our layout made or switched to stands with the gryphons home, not at the old places;
-- one the player saved there is kept on a switch and goes on a reset. Other layouts keep their records.
table.insert(layouts, Layout("ClassicUI Forever", ACCOUNT))
ns.HomeLayoutSpots("ClassicUI Forever")
Pick("ClassicUI Forever")
Check(At("gryphonLeft") == "home", "the classic layout set up: the gryphon home, not at the old place (" .. At("gryphonLeft") .. ")")
Move("gryphonLeft", 90, 91)
W.SaveLayoutSpots()
ns.HomeLayoutSpots("ClassicUI Forever")
Pick("Old")
Pick("ClassicUI Forever")
Check(At("gryphonLeft") == "90,91", "switched to again by the button: a place saved there is kept")
ns.HomeLayoutSpots("ClassicUI Forever", true)
Pick("Old")
Check(At("gryphonLeft") == "5,6", "the reset leaves the player's other layouts their records")
Pick("ClassicUI Forever")
Check(At("gryphonLeft") == "home", "the classic layout reset: home")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("piece_layouts_test: ok")
