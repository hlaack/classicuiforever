-- Offline tests for Art/BronzeClient.lua under Lua 5.4: client art handed back keeps the client's crop.
-- Run from the addon root: lua tools/tests/bronze_client_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client

-- A texture: a file (client file id or our copy's path) or an atlas, which brings its own crop.
local Tex = {}
Tex.__index = Tex
local function NewTex(file, coords) return setmetatable({ file = file, coords = coords }, Tex) end
function Tex:SetTexture(file)
    self.file, self.atlas = file, nil
    return true
end
function Tex:GetTexture() return self.file end
function Tex:SetTexCoord(...) self.coords = { ... } end
function Tex:GetTexCoord() return table.unpack(self.coords) end
function Tex:SetAtlas(atlas)
    self.atlas, self.file, self.coords = atlas, "atlas:" .. atlas, { 0, 1, 0, 1 }
end
function Tex:GetAtlas() return self.atlas end
function Tex:SetHorizTile() end
function Tex:SetVertTile() end
function Tex:IsObjectType(kind) return kind == "Texture" end

C_Texture = { GetAtlasInfo = function() return nil end }

------------------------------------------------------------------ the addon

local themeOn = true
local noop = function() end
local job = { Wake = noop, Kick = noop, Sleep = noop, Burst = noop }
local ns = { db = {}, bronze = { tinted = {}, swapped = {}, THEME_KEYS = {} } }
ns.BronzeCopy = function(name) return themeOn and ("copy\\" .. name) or nil end
ns.BronzeOn = function() return themeOn end
ns.IsSecret = function() return false end
ns.IsForbidden = function() return false end
ns.EachRegionProtected, ns.EachChildProtected, ns.EachChild = noop, noop, noop
ns.Sched = { Job = function() return job end, OnVisible = noop }
ns.OnToggle, ns.RegisterEvents, ns.UntintGameArt, ns.PaintCopy, ns.BronzeRim = noop, noop, noop, noop, noop
ns.EventFrame = function() return {} end
ns.ThemeTurned = function() return false end

assert(loadfile(ROOT .. "/Art/BronzeClient.lua"))("ClassicUIForever", ns)

------------------------------------------------------------------ checks

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end
local function Coords(tex) return table.concat(tex.coords, ",") end

-- A red panel button's middle slice (SecureUIPanelTemplates.xml): file 130828, the sheet's 0.09375 to 0.53125.
local MIDDLE = "0.09375,0.53125,0,0.6875"
local middle = NewTex(130828, { 0.09375, 0.53125, 0, 0.6875 })
ns.BronzeClientTexture(middle)
Check(middle.file == "copy\\UI-Panel-Button-Up.tga", "theme on: the middle slice shows the copy (" .. tostring(middle.file) .. ")")
Check(Coords(middle) == MIDDLE, "theme on: the middle slice keeps its crop (" .. Coords(middle) .. ")")
ns.BronzeClientTexture(middle, true)
Check(middle.file == 130828, "handed back: the client's file again (" .. tostring(middle.file) .. ")")
Check(Coords(middle) == MIDDLE, "handed back: the middle slice keeps its crop, not the whole sheet (" .. Coords(middle) .. ")")
-- One theme to another: handed back, then the new copy on the same crop.
ns.BronzeClientTexture(middle)
Check(Coords(middle) == MIDDLE, "theme turned: the middle slice keeps its crop (" .. Coords(middle) .. ")")

-- An atlas piece (the game menu's red button) gets its atlas back, with the atlas's own crop.
local cap = NewTex(nil, { 0, 1, 0, 1 })
cap:SetAtlas("128-RedButton-Left")
ns.BronzeClientTexture(cap)
Check(cap.file == "copy\\RedButtonCaps.tga", "theme on: the cap shows the packed copy (" .. tostring(cap.file) .. ")")
ns.BronzeClientTexture(cap, true)
Check(cap.atlas == "128-RedButton-Left" and Coords(cap) == "0,1,0,1", "handed back: the cap's atlas and its crop")

if failures > 0 then
    print(string.format("bronze client: %d failed", failures))
    os.exit(1)
end
print("bronze client: ok")
