-- Offline test for the character sheet's side panel art (Character/EquipmentPane.lua) under Lua 5.4: its sheets are
-- cut in parts, and a part that continues another hangs on that part's edge. Placed by its own offsets from the panel,
-- the lower half left a one pixel see-through line at some interface sizes.
-- Run from the addon root: lua tools/tests/side_art_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client and addon

local Region = {}
Region.__index = function(_, key) return Region[key] or function() end end
local function New(kind) return setmetatable({ kind = kind, points = {} }, Region) end
local textures = {}
function Region:CreateTexture()
    local tex = New("texture")
    tex.on = self
    textures[#textures + 1] = tex
    return tex
end
function Region:SetPoint(point, rel, relPoint, x, y)
    self.points[#self.points + 1] = { point = point, rel = rel, relPoint = relPoint, x = x, y = y }
end
function Region:SetSize(w, h) self.w, self.h = w, h end
function Region:GetFrameLevel() return 1 end

PaperDollFrame = New("frame")
CreateFrame = function() return New("frame") end
UIParent = New("frame")

-- Anything the file asks of the addon at load is a function that does nothing.
local ns = setmetatable({ L = setmetatable({}, { __index = function(_, key) return key end }) },
    { __index = function() return function() end end })
ns.NewFrame = function() return New("frame") end
ns.SetTex = function(tex, key) tex.key = key end

assert(loadfile(ROOT .. "/Character/EquipmentPane.lua"))("ClassicUIForever", ns)

------------------------------------------------------------------ the checks

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL " .. what)
    end
end

local panel = ns.SidePanel("TestSidePanel", New("frame"))
Check(#textures >= 4, "the panel's art is cut in parts (" .. #textures .. ")")

local byKey = {}
for _, tex in ipairs(textures) do
    byKey[tex.key] = tex
    Check(#tex.points == 1, tostring(tex.key) .. " has one anchor")
end

-- The lower half hangs under the upper half, sheet for sheet.
for _, pair in ipairs({ { "charGeneralBotLeft", "charGeneralTopLeft" }, { "charGeneralBotRight", "charGeneralTopRight" } }) do
    local low, up = byKey[pair[1]], byKey[pair[2]]
    if low and up then
        local p = low.points[1]
        Check(p.rel == up and p.point == "TOPLEFT" and p.relPoint == "BOTTOMLEFT" and p.x == 0 and p.y == 0,
            pair[1] .. " hangs on the bottom edge of " .. pair[2])
    else
        Check(low == nil and up == nil, pair[1] .. " and " .. pair[2] .. " come as a pair")
    end
end
Check(byKey.charGeneralBotLeft or byKey.charGeneralBotRight, "the lower half is drawn")

-- A right sheet with a left one beside it hangs on that one's right edge.
for _, pair in ipairs({ { "charTabTopRight", "charTabTopLeft" }, { "charGeneralTopRight", "charGeneralTopLeft" } }) do
    local right, left = byKey[pair[1]], byKey[pair[2]]
    if right and left then
        local p = right.points[1]
        Check(p.rel == left and p.point == "TOPLEFT" and p.relPoint == "TOPRIGHT", pair[1] .. " hangs on the right edge of " .. pair[2])
    end
end

-- No part below the top row is placed by an offset of its own from the panel.
for _, tex in ipairs(textures) do
    local p = tex.points[1]
    if p and p.rel == panel then
        Check(tex.key == "charTabTopLeft" or tex.key == "charGeneralTopLeft" or tex.key == "charTabTopRight"
            or tex.key == "charGeneralTopRight", tostring(tex.key) .. " is placed from the panel, not from the part it continues")
    end
end

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("side_art_test: ok")
