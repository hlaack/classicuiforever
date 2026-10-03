-- Offline tests for Map/MinimapGroupFinder.lua under Lua 5.4: the minimap eye shows on its own option, the micro button
-- hidden or not, and an install from before with that button showing keeps no eye.
-- Run from the addon root: lua tools/tests/group_finder_eye_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client and addon

LFDMicroButton = {}
local shown = false
local apply
local noop = function() end
local ns = {
    RING_ICON_FACE = { x = 0, y = 0 },
    RingButton = function() return function() shown = true end, function() shown = false end end,
    RegisterModule = function(_, spec) apply = spec.apply end,
    Dress = noop, MapPad = noop,
}
assert(loadfile(ROOT .. "/Map/MinimapGroupFinder.lua"))("ClassicUIForever", ns)

------------------------------------------------------------------ checks

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end

-- The eye with the micro button showing: what the player asked for.
ns.db = { lfgMinimapButton = true, hideMicroButtons = true, hideMicroGroupFinder = false }
apply()
Check(shown, "the eye shows with the micro button shown")
ns.db.hideMicroGroupFinder = true
apply()
Check(shown, "the eye shows with the micro button hidden")
ns.db.lfgMinimapButton = false
apply()
Check(not shown, "unchecked, no eye")

-- Upgraders: an eye that did not show before stays off; one that did stays on.
ns.db = {
    hideMicroGroupFinder = false, dbVersion = 7,
    profiles = { showing = { hideMicroButtons = false }, hidden = {}, picked = { lfgMinimapButton = true, hideMicroGroupFinder = false } },
}
ns.KeepGroupFinderEye()
Check(ns.db.lfgMinimapButton == false, "account with the micro button showing: no eye")
Check(ns.db.profiles.showing.lfgMinimapButton == false, "profile with every micro button showing: no eye")
Check(ns.db.profiles.hidden.lfgMinimapButton == nil, "profile with the button hidden keeps the default eye")
Check(ns.db.profiles.picked.lfgMinimapButton == false, "the eye never showed beside the button before: off")
Check(ns.db.dbVersion == 8, "writes dbVersion 8")

if failures > 0 then
    print(string.format("group finder eye: %d failed", failures))
    os.exit(1)
end
print("group finder eye: ok")
