-- Offline test under Lua 5.4 for the window chrome both clients share: retail's border corners start from Forever's
-- spots, so one lift puts the foot line and right rail in the same place on both (Windows/WindowChrome.lua).
-- Run from the addon root: lua tools/tests/window_corners_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL: " .. what)
    end
end

local quiet = { __index = function() return function() end end }

local function Addon(onForever)
    local ns = setmetatable({}, quiet)
    ns.OnForever = function() return onForever end
    -- Our art replaces the client's atlas.
    ns.Dress = function(tex) tex.atlas = nil end
    ns.SetAlphaIf = function(region, alpha) region.alpha = alpha end
    ns.WhenCalm = function(_, fn) fn() end
    return ns
end

local function Load(file, ns)
    assert(loadfile(ROOT .. "/" .. file))("ClassicUIForever", ns)
end

InCombatLockdown = function() return false end

------------------------------------------------------------------ border corners

local Corner = {}
Corner.__index = Corner
function Corner:GetPoint() return self.point, self.rel, self.relPoint, self.x, self.y end
function Corner:SetPoint(point, rel, relPoint, x, y) self.point, self.rel, self.relPoint, self.x, self.y = point, rel, relPoint, x, y end
function Corner:GetAtlas() return self.atlas end

local function NewCorner(point, x, y, atlas)
    return setmetatable({ point = point, relPoint = point, x = x, y = y, atlas = atlas }, Corner)
end

-- The standard metal border where each client hangs it.
local function Window(right, foot)
    return { NineSlice = {
        TopLeftCorner = NewCorner("TOPLEFT", -13, 16, "UI-Frame-PortraitMetal-CornerTopLeft"),
        TopRightCorner = NewCorner("TOPRIGHT", right, 16, "UI-Frame-Metal-CornerTopRight"),
        BottomLeftCorner = NewCorner("BOTTOMLEFT", -13, foot, "UI-Frame-Metal-CornerBottomLeft"),
        BottomRightCorner = NewCorner("BOTTOMRIGHT", right, foot, "UI-Frame-Metal-CornerBottomRight"),
    } }
end

local function Spots(frame)
    local slice = frame.NineSlice
    return slice.TopRightCorner.x, slice.BottomRightCorner.x, slice.BottomLeftCorner.y, slice.BottomRightCorner.y,
        slice.BottomLeftCorner.x
end

local function Chrome(onForever)
    local ns = Addon(onForever)
    Load("Windows/WindowChrome.lua", ns)
    ns.panels.active = true
    return ns.panels
end

do
    local forever, retail = Chrome(true), Chrome(false)
    local onForever, onRetail = Window(2, -8), Window(4, -3)
    forever.Reborder(onForever, false, 5)
    retail.Reborder(onRetail, false, 5)
    local fTop, fRight, fLeftY, fRightY, fLeftX = Spots(onForever)
    local rTop, rRight, rLeftY, rRightY, rLeftX = Spots(onRetail)
    Check(fTop == 2 and fRight == 2 and fLeftY == -3 and fRightY == -3, "Forever: the corners keep the client's spots, lifted")
    Check(rTop == fTop and rRight == fRight, "retail: the right corners stand where Forever's do")
    Check(rLeftY == fLeftY and rRightY == fRightY, "retail: the foot line stands where Forever's does")
    Check(rLeftX == fLeftX, "retail: the left corners are untouched")

    -- A second pass (a sized window re-bordered) starts from the same spots, not from our own.
    retail.Reborder(onRetail, false, 5)
    local top, right, leftY = Spots(onRetail)
    Check(top == 2 and right == 2 and leftY == -3, "retail: a second pass does not move the corners again")

    -- The client re-laid its border: its own spots and art are back, ours follow from the spots first read.
    local slice = onRetail.NineSlice
    slice.TopRightCorner.x, slice.BottomRightCorner.x = 4, 4
    slice.BottomLeftCorner.y, slice.BottomRightCorner.y = -3, -3
    retail.Reborder(onRetail, false, 10)
    top, right, leftY = Spots(onRetail)
    Check(top == 2 and right == 2 and leftY == 2, "retail: a border the client re-laid goes back to Forever's spots")

    -- Other borders (a dialog's) are not the standard metal: Forever leaves them, so retail does.
    local dialog = { NineSlice = { BottomLeftCorner = NewCorner("BOTTOMLEFT", -5, -5, "UI-Frame-DiamondMetal-CornerBottomLeft") } }
    retail.Reborder(dialog, false, 5)
    Check(dialog.NineSlice.BottomLeftCorner.y == 0, "retail: another border's corners keep their own spots")
end

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("window_corners_test: ok")
