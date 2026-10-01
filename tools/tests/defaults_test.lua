-- Offline lock on ns.DB_DEFAULTS. Profiles keep only what differs from the defaults, so a changed default flips every
-- existing save: it needs a dbVersion bump and a migration keeping old saves' values (ns.KeepOldLook).
-- Run from the addon root: lua tools/tests/defaults_test.lua [--write] (CI runs every tools/tests/*_test.lua).
-- --write records the current defaults in tools/tests/defaults_lock.lua.
-- luacheck: std lua54
-- luacheck: ignore 121

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end
local LOCK_FILE = ROOT .. "/tools/tests/defaults_lock.lua"

local ns = {}
GetLocale = GetLocale or function() return "enUS" end
assert(loadfile(ROOT .. "/Core/Localization.lua"))("ClassicUIForever", ns)
assert(loadfile(ROOT .. "/Locales/enUS.lua"))("ClassicUIForever", ns)
assert(loadfile(ROOT .. "/Core/Defaults.lua"))("ClassicUIForever", ns)
local defaults = ns.DB_DEFAULTS

local keys = {}
for k, v in pairs(defaults) do
    if type(v) ~= "table" then keys[#keys + 1] = k end
end
table.sort(keys)

if arg and arg[1] == "--write" then
    local out = { "-- Written by: lua tools/tests/defaults_test.lua --write. Never edit by hand.", "return {" }
    for _, k in ipairs(keys) do out[#out + 1] = string.format("    %s = %q,", k, defaults[k]) end
    out[#out + 1] = "}"
    local f = assert(io.open(LOCK_FILE, "w"))
    f:write(table.concat(out, "\n"), "\n")
    f:close()
    print("defaults: lock written")
    os.exit(0)
end

local lockChunk = loadfile(LOCK_FILE)
if not lockChunk then
    print("FAIL: no defaults lock; run lua tools/tests/defaults_test.lua --write")
    os.exit(1)
end
local lock = lockChunk()
local changed, moved = {}, {}
for _, k in ipairs(keys) do
    if lock[k] == nil then
        moved[#moved + 1] = "+" .. k
    elseif k ~= "dbVersion" and lock[k] ~= defaults[k] then
        changed[#changed + 1] = string.format("%s %s -> %s", k, tostring(lock[k]), tostring(defaults[k]))
    end
end
for k in pairs(lock) do
    if defaults[k] == nil then moved[#moved + 1] = "-" .. k end
end

local failed = false
if #changed > 0 and lock.dbVersion == defaults.dbVersion then
    failed = true
    print("FAIL: defaults changed without a dbVersion bump: " .. table.concat(changed, ", "))
    print("  Bump dbVersion, migrate old saves to keep their values, then run with --write.")
elseif #changed > 0 or lock.dbVersion ~= defaults.dbVersion then
    failed = true
    print("FAIL: dbVersion bumped; once its migration keeps old saves' values, run with --write.")
end
if #moved > 0 then
    failed = true
    print("FAIL: keys added or removed (no migration needed), run with --write: " .. table.concat(moved, ", "))
end
print(failed and "defaults: lock differs" or "defaults: locked")
os.exit(failed and 1 or 0)
