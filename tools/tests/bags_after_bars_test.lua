-- Offline test under Lua 5.4 for the bag windows beside the right bars (Bar/BandWatch.lua). An item on the cursor (a
-- right-click equip puts one there for an instant) makes the client send a right bar the layout holds as default to
-- the screen's edge. Out of a fight our lane puts it back: the bags are placed after that, never before (they jumped
-- 39 sideways for a frame). In a fight the bar cannot be put back: the width beside the bars is the one our last pass
-- left, so the bags stay where they were (they went right and stayed there till the fight ended).
-- Run from the addon root: lua tools/tests/bags_after_bars_test.lua (CI runs every tools/tests/*_test.lua).
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

local handle = assert(io.open(ROOT .. "/Bar/BandWatch.lua", "r"))
local source = handle:read("a")
handle:close()

------------------------------------------------------------------ the lane's order

local from = source:find('placer:SetScript("OnUpdate"', 1, true)
Check(from ~= nil, "the lane's frame script is in the file")
local lane = from and source:sub(from) or ""
local bars = lane:find("SafeCall(PlaceTick", 1, true)
local bags = lane:find("SafeCall(AnchorOpenBags)", 1, true)
Check(bars ~= nil, "the lane puts the bars back (PlaceTick)")
Check(bags ~= nil, "the lane places the open bag windows (AnchorOpenBags)")
Check(bars and bags and bags > bars, "the bag windows are placed after the bars are put back")

-- Nowhere else: a second call ahead of the bars would bring the jump back. One definition and one guarded call.
local calls = 0
for _ in source:gmatch("AnchorOpenBags%s*%(") do calls = calls + 1 end
for _ in source:gmatch("SafeCall%(AnchorOpenBags") do calls = calls + 1 end
Check(calls == 2, "the bag windows are placed from one spot only (" .. calls .. " mentions)")

------------------------------------------------------------------ the width beside the bars, cut out of the file and run

local first = source:find("local function LiveSideWidth()", 1, true)
local last = source:find("B.SideColumnsWidth = SideColumnsWidth", 1, true)
Check(first and last and last > first, "the width's two functions are in the file")
local chunk = first and last and source:sub(first, last + #"B.SideColumnsWidth = SideColumnsWidth") or ""

local fight = false
local function Bar(left, right)
    return {
        left = left, right = right,
        IsVisible = function() return true end,
        GetAlpha = function() return 1 end,
        GetEffectiveScale = function() return 1 end,
        GetLeft = function(self) return self.left end,
        GetRight = function(self) return self.right end,
        GetWidth = function(self) return self.right - self.left end,
        GetHeight = function() return 498 end,
    }
end
-- His screen: the outer bar 2 in from the edge, the inner one 44 in.
local outer, inner = Bar(1479, 1515), Bar(1437, 1473)
local B = {}
local env = setmetatable({
    B = B, math = math, ipairs = ipairs,
    SideBarPair = function() return { outer, inner } end,
    InCombatLockdown = function() return fight end,
    UIParent = { GetRight = function() return 1517 end, GetEffectiveScale = function() return 1 end },
}, { __index = _G })
local run, err = load(chunk, "side width", "t", env)
Check(run ~= nil, "the width's functions load (" .. tostring(err) .. ")")
if run then run() end
local Width = B.SideColumnsWidth or function() return -1 end

Check(Width() == 80, "both right bars standing: 80 wide (" .. Width() .. ")")
-- Our pass placed everything: the snapshot keeps the width (B.Snapshot's line, checked below).
B.sideCalm = B.LiveSideWidth and B.LiveSideWidth()
Check(source:find("B.sideCalm = B.LiveSideWidth()", 1, true) ~= nil, "the band's snapshot keeps the width our pass left")

-- The client sends the inner bar to the edge, on top of the outer one.
inner.left, inner.right = 1476, 1512
Check(Width() == 41, "out of a fight the width is read live: 41 until the lane puts the bar back (" .. Width() .. ")")
fight = true
Check(Width() == 80, "in a fight the width is the one our last pass left: 80, the bags stay (" .. Width() .. ")")
fight = false
inner.left, inner.right = 1437, 1473
Check(Width() == 80, "the fight over and the bar back: 80, read live again (" .. Width() .. ")")
-- No pass yet this session: nothing kept, the live width answers in a fight too.
B.sideCalm = nil
fight = true
Check(Width() == 80, "in a fight with nothing kept: the live width (" .. Width() .. ")")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("bags_after_bars_test: ok")
