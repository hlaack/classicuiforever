-- Offline test under Lua 5.4 for ns.WindowMicro (UI/WindowOpeners.lua): a micro button's click opens our window while
-- taken, its own click comes back when let go, a click another addon set since is left alone, and in quick keybind
-- mode a click opens nothing.
-- Run from the addon root: lua tools/tests/window_openers_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 122 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL " .. what)
    end
end

local function Button()
    local b = { scripts = {} }
    function b:GetScript(name) return self.scripts[name] end
    function b:SetScript(name, fn) self.scripts[name] = fn end
    return b
end

local keybinding = false
KeybindFrames_InQuickKeybindMode = function() return keybinding end
local ns = {}
assert(loadfile(ROOT .. "/UI/WindowOpeners.lua"))("ClassicUIForever", ns)

local opened = 0
local own = function() end
TestMicroA, TestMicroB = Button(), Button()
TestMicroA:SetScript("OnClick", own)
local take = ns.WindowMicro({ "TestMicroA", "TestMicroB", "TestMicroMissing" }, function() opened = opened + 1 end)

take(true)
TestMicroA.scripts.OnClick()
Check(opened == 1, "a taken button opens our window")
take(true)
TestMicroA.scripts.OnClick()
Check(opened == 2, "taking again changes nothing")
keybinding = true
TestMicroA.scripts.OnClick()
Check(opened == 2, "in quick keybind mode a click opens nothing")
keybinding = false

take(false)
Check(TestMicroA.scripts.OnClick == own, "let go, the button's own click is back")
Check(TestMicroB.scripts.OnClick == nil, "a button with no click of its own is left with none")

take(true)
local other = function() end
TestMicroA:SetScript("OnClick", other)
take(false)
Check(TestMicroA.scripts.OnClick == other, "a click set since by someone else is left alone")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("window_openers_test: ok")
