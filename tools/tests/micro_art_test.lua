-- Offline test under Lua 5.4: every micro button of ours (Bar/BandMicro.lua) has its 1.x sheet named in
-- Bar/BarSkins.lua's MICRO_ART. Without the entry the whole 32x64 sheet is squeezed into the 29x37 button.
-- Run from the addon root: lua tools/tests/micro_art_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local function Read(path)
    local file = assert(io.open(ROOT .. "/" .. path, "r"))
    local text = file:read("a")
    file:close()
    return text
end

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL: " .. what)
    end
end

local skins = Read("Bar/BarSkins.lua")
local art = skins:match("local MICRO_ART = (%b{})")
Check(art ~= nil, "MICRO_ART is found in Bar/BarSkins.lua")

local sheets = {}
for name in Read("Art/TextureData.lua"):match('for _, name in ipairs%((%b{})%) do%s+for _, state'):gmatch('"(%w+)"') do
    sheets[name] = true
end

local count = 0
for name in Read("Bar/BandMicro.lua"):gmatch('CreateFrame%("Button", "(ForeverClassicUI%w+MicroButton)"') do
    count = count + 1
    local sheet = art and art:match(name .. ' = "(%w+)"')
    Check(sheet ~= nil, name .. " has a MICRO_ART entry")
    Check(sheet == nil or sheets[sheet], name .. "'s sheet " .. tostring(sheet) .. " is a 1.x micro sheet")
end
Check(count >= 3, "BandMicro.lua's own micro buttons are found (" .. count .. ")")

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("micro_art_test: ok")
