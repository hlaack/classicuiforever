-- Offline test for the achievements button's migration (Bar/GameMicro.lua) under Lua 5.4: the button became hidden
-- by default, and an install from before keeps it showing, in the account and in every profile (profiles hold only
-- what differs from the defaults, so an unset one would flip with the default).
-- Run from the addon root: lua tools/tests/micro_keep_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local ns = setmetatable({}, { __index = function() return function() end end })
assert(loadfile(ROOT .. "/Bar/GameMicro.lua"))("ClassicUIForever", ns)

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL " .. what)
    end
end

ns.db = { dbVersion = 13, hideMicroAchievements = false,
    profiles = { plain = {}, picked = { hideMicroAchievements = true }, odd = "not a table" } }
ns.KeepAchievementsButton()
Check(ns.db.hideMicroAchievements == false, "the account keeps the button showing")
Check(ns.db.profiles.plain.hideMicroAchievements == false, "a profile that never touched it keeps the button showing")
Check(ns.db.profiles.picked.hideMicroAchievements == true, "a profile that hid it keeps it hidden")
Check(ns.db.dbVersion == 14, "the save is marked migrated")

-- A save from before the key was ever written.
ns.db = { dbVersion = 3 }
ns.KeepAchievementsButton()
Check(ns.db.hideMicroAchievements == false, "an older save without the key keeps the button showing")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("micro_keep_test: ok")
