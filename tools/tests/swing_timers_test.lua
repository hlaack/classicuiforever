-- Offline test for the swing timers' flash (Units/SwingTimers.lua) under Lua 5.4. The flash once read the game's bar
-- each frame; after a weapon change in a fight that value is secret for the rest of the session, and math on it failed
-- every frame (351 errors a session). Now each swing is timed by our own clock from the game's swing event: a swing
-- running out flashes, a new swing past half the last one's time flashes, and the bar's value is never read.
-- Run from the addon root: lua tools/tests/swing_timers_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client and addon

local Region = {}
Region.__index = function(_, key) return Region[key] or function() end end
local function New() return setmetatable({}, Region) end
function Region:CreateTexture() return New() end
function Region:CreateAnimation() return New() end
function Region:GetHeight() return 13 end

-- A secret number, as our code meets one: any math or compare on it is an error.
local function Refuse() error("attempt to perform arithmetic on a secret number value") end
local SECRET = setmetatable({}, { __sub = Refuse, __add = Refuse, __mul = Refuse, __lt = Refuse, __le = Refuse })

local clock = 0
function GetTime() return clock end
Enum = { PlayerSwingType = { MainHand = 0, OffHand = 1, Ranged = 2 } }
unpack = table.unpack

local reads = 0
local function Timer(global)
    local bar = New()
    bar.plays = 0
    function bar:GetValue()
        reads = reads + 1
        return SECRET
    end
    function bar:CreateAnimationGroup()
        local anim = New()
        anim.Play = function() bar.plays = bar.plays + 1 end
        return anim
    end
    for _, key in ipairs({ "Pip", "TypeLabel", "TypeLabelShadow", "TimeLabel" }) do bar[key] = New() end
    local timer = New()
    timer.StatusBar, timer.Background, timer.Border = bar, New(), New()
    _G[global] = timer
    return bar
end
-- No off hand window on this character.
local main, ranged = Timer("SwingTimerMainHandFrame"), Timer("SwingTimerRangedFrame")

local apply, restore, onEvent, registered
local jobs = {}
local ns = setmetatable({ db = {} }, { __index = function() return function() end end })
ns.L = setmetatable({}, { __index = function(_, key) return key end })
ns.IsSecret = function(value) return value == SECRET end
ns.AnySecret = function(a, b) return a == SECRET or b == SECRET end
ns.SafeCall = function(fn, ...) return fn(...) end
ns.RegisterModule = function(_, module) apply, restore = module.apply, module.restore end
ns.EventFrame = function(events, handler)
    onEvent, registered = handler, events
    return { UnregisterAllEvents = function() registered = nil end }
end
ns.RegisterEvents = function(_, events) registered = events end
ns.Sched = { Attach = function(_, spec)
    local job = {}
    jobs[#jobs + 1] = { job = job, fn = spec.fn }
    return job
end }

assert(loadfile(ROOT .. "/Units/SwingTimers.lua"))("ClassicUIForever", ns)
apply()

------------------------------------------------------------------ the checks

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL " .. what)
    end
end
-- The flashes a bar started since the last ask.
local seen = {}
local function Flashes(bar)
    local count = bar.plays - (seen[bar] or 0)
    seen[bar] = bar.plays
    return count
end
-- One drawn frame at a time: every shown timer's watch runs.
local function Frame(at)
    clock = at
    for _, entry in ipairs(jobs) do
        local ok, err = pcall(entry.fn, entry.job)
        Check(ok, "the watch runs clean at " .. at .. " (" .. tostring(err) .. ")")
    end
end
local function Event(at, event, duration, hand)
    clock = at
    local ok, err = pcall(onEvent, nil, event, duration, hand)
    Check(ok, event .. " runs clean at " .. at .. " (" .. tostring(err) .. ")")
end

Check(#jobs == 2 and onEvent ~= nil, "a watch per swing timer, and the swing event heard")
Check(registered and registered[1] == "PLAYER_SWING", "the swing event is registered")

-- A swing running out.
Event(0, "PLAYER_SWING", 2, 0)
Check(Flashes(main) == 0, "a first swing: no flash as it starts")
Frame(1)
Frame(1.9)
Check(Flashes(main) == 0, "the swing running: no flash")
Frame(2)
Check(Flashes(main) == 1, "the swing run out: one flash")
Frame(2.1)
Frame(3)
Check(Flashes(main) == 0, "and only one")

-- A new swing before the last ran out.
Event(10, "PLAYER_SWING", 2, 0)
Event(11.5, "PLAYER_SWING", 2, 0)
Check(Flashes(main) == 1, "a new swing past half the last one's time: a flash")
Frame(12)
Check(Flashes(main) == 0, "the old end passes unseen: the clock restarted")
Frame(13.5)
Check(Flashes(main) == 1, "the new swing run out: a flash")
Event(20, "PLAYER_SWING", 2, 0)
Event(20.5, "PLAYER_SWING", 2, 0)
Check(Flashes(main) == 0, "a new swing before half the last one's time: no flash")
Frame(22.5)
Flashes(main)

-- The other hands.
Event(30, "PLAYER_SWING", 3, 2)
Frame(33)
Check(Flashes(ranged) == 1 and Flashes(main) == 0, "a ranged swing flashes the ranged bar alone")
Event(34, "PLAYER_SWING", 2, 1)
Frame(36)
Check(Flashes(ranged) == 0 and Flashes(main) == 0, "an off hand swing with no off hand timer: nothing")

-- The timer hidden as its swing ran out: nothing on its return.
Event(40, "PLAYER_SWING", 2, 0)
Frame(50)
Check(Flashes(main) == 0, "a swing that ran out long ago: no flash")

-- A weapon changed mid swing: the game restarts its bar on a time we cannot read.
Event(60, "PLAYER_SWING", 2, 0)
Event(61, "WEAPON_SLOT_CHANGED")
Frame(62)
Check(Flashes(main) == 0, "a weapon change stops the clock: no flash at the old end")
Event(63, "PLAYER_SWING", 2, 0)
Check(Flashes(main) == 0, "the next swing starts a clock without a flash")
Frame(65)
Check(Flashes(main) == 1, "and flashes as it runs out")

-- A secret payload takes no math.
Event(70, "PLAYER_SWING", 2, 0)
Event(71.5, "PLAYER_SWING", SECRET, 0)
Frame(72)
Frame(75)
Check(Flashes(main) == 0, "a secret duration: no error, the clock stops, no flash")
Event(80, "PLAYER_SWING", 2, SECRET)
Frame(82)
Check(Flashes(main) == 0, "a secret hand: no error, no flash")

Check(reads == 0, "the bar's value is never read (" .. reads .. " reads)")

-- The flash turned off in the options.
ns.db.swingFlash = false
Event(90, "PLAYER_SWING", 2, 0)
Event(91.5, "PLAYER_SWING", 2, 0)
Frame(93.5)
Check(Flashes(main) == 0, "flash turned off: none")
ns.db.swingFlash = nil

-- The module off: the event is let go and nothing flashes.
restore()
Check(registered == nil, "turned off: the swing event is let go")
Event(100, "PLAYER_SWING", 2, 0)
Frame(102)
Check(Flashes(main) == 0, "turned off: no flash")
apply()
Check(registered and registered[1] == "PLAYER_SWING", "turned on again: the swing event is heard again")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("swing_timers_test: ok")
