-- Offline test under Lua 5.4 for the comma of the minimap's coordinates (Map/Minimap.lua CommaShift). The line was
-- measured ten times a second on a scratch string, standing still included. Now it is measured only when the line or
-- its font changes; the shift is the same as before and the anchors are still held on every beat.
-- Run from the addon root: lua tools/tests/coords_comma_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL " .. what)
    end
end

local handle = assert(io.open(ROOT .. "/Map/Minimap.lua", "r"))
local source = handle:read("a")
handle:close()

local first = source:find("local commaScratch, commaOn", 1, true)
local last = source:find("local function DrainDielRing", 1, true)
Check(first and last and last > first, "the comma's function is in the file")
local chunk = first and last and (source:sub(first, last - 1) .. "\nreturn CommaShift, function(on) commaOn = on end") or ""

------------------------------------------------------------------ the stub client

-- A font's widths: digits half the size, a comma or a point a quarter.
local function Width(line, size)
    local width = 0
    for char in line:gmatch(".") do width = width + ((char == "," or char == ".") and size / 4 or size / 2) end
    return width
end

local measures = 0
local scratch = { size = 0, line = "" }
function scratch:SetFont(_, size) self.size = size end
function scratch:SetText(line) self.line, measures = line, measures + 1 end
function scratch:GetStringWidth() return Width(self.line, self.size) end

local text = { line = "42.1, 67.9", size = 10 }
function text:GetText() return self.line end
function text:GetFont() return "Fonts\\FRIZQT__.TTF", self.size, "" end
function text:GetStringWidth() return Width(self.line, self.size) end
local coords = { CoordText = text }

local placed, shiftSet = 0, nil
local env = setmetatable({
    UIParent = { CreateFontString = function() return scratch end },
    ns = {
        IsSecret = function() return false end,
        SetTwoPointsIf = function(region, _, rel, _, x, y, _, _, _, x2)
            placed = placed + 1
            shiftSet = (region == text and rel == coords and y == 0 and x == x2) and x or nil
        end,
    },
}, { __index = _G })
local run, err = load(chunk, "comma shift", "t", env)
Check(run ~= nil, "the function loads (" .. tostring(err) .. ")")
local CommaShift, SetOn
if run then CommaShift, SetOn = run() end
CommaShift, SetOn = CommaShift or function() end, SetOn or function() end

-- The comma under the middle: half the line, less what stands before the comma and half the comma.
local function Wanted()
    local cut = text.line:find(",", 1, true)
    if not cut then return 0 end
    return Width(text.line, text.size) / 2 - Width(text.line:sub(1, cut - 1), text.size) - Width(",", text.size) / 2
end

------------------------------------------------------------------ checks

-- Off (the module's hand-back): nothing is read or placed.
CommaShift(coords)
Check(measures == 0 and placed == 0, "with the comma off nothing is measured or placed")

SetOn(true)
CommaShift(coords)
Check(measures == 2, "a new line is measured (" .. measures .. " scratch writes)")
Check(shiftSet == Wanted(), "the line slides by the comma's distance from the middle (" .. tostring(shiftSet) .. ")")

-- Standing still: ten beats, no measure, the anchors asked for on each.
for _ = 1, 10 do CommaShift(coords) end
Check(measures == 2, "standing still measures nothing (" .. measures .. " scratch writes)")
Check(placed == 11, "the anchors are held on every beat (" .. placed .. ")")
Check(shiftSet == Wanted(), "standing still keeps the shift")

-- A step: the numbers change width.
text.line = "100.0, 7.5"
CommaShift(coords)
Check(measures == 4, "a changed line is measured again (" .. measures .. ")")
Check(shiftSet == Wanted(), "the new line's shift (" .. tostring(shiftSet) .. ")")

-- Classic fonts toggled: same line, other size.
text.size = 12
CommaShift(coords)
Check(measures == 6, "a changed font is measured again (" .. measures .. ")")
Check(shiftSet == Wanted(), "the new font's shift (" .. tostring(shiftSet) .. ")")

-- A line with no comma sits where the game put it.
text.line = "---"
CommaShift(coords)
Check(shiftSet == 0, "a line without a comma is not slid")

-- Off and on again with the same line: the kept shift goes back on, unmeasured.
text.line = "100.0, 7.5"
CommaShift(coords)
local before = measures
SetOn(false)
CommaShift(coords)
SetOn(true)
placed = 0
CommaShift(coords)
Check(measures == before and placed == 1 and shiftSet == Wanted(), "turned on again, the kept shift is placed")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("coords_comma_test: ok")
