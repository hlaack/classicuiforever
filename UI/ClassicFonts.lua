local _, ns = ...

-- Classic fonts: text as Classic Era draws it, measured there (/efd fonts). Small counts and key labels in Era's thick
-- monochrome outline, the PvP zone line at Era's size; plate names (Units/NamePlates.lua) and pet bar numbers
-- (Units/PartyPetFrames.lua) read ns.ClassicFonts(). Only fonts change, so it answers in a fight too.

local MONO = "THICKOUTLINE, MONOCHROME"
local FONT_OBJECTS = { "NumberFontNormalSmall", "NumberFontNormalSmallGray", "NumberFont_OutlineThick_Mono_Small" }
local ZONE_LINES = { PVPInfoTextString = 26, PVPArenaTextString = 26 }
local saved = {}   -- font object or string -> { file, size, flags } as the game had it

function ns.ClassicFonts()
    return ns.db ~= nil and ns.db.classicFonts ~= false and ns.ModuleInForce("classicFonts")
end

local function Keep(object)
    if not saved[object] then saved[object] = { object:GetFont() } end
    return saved[object]
end

local function Apply()
    for _, name in ipairs(FONT_OBJECTS) do
        local font = _G[name]
        if font then
            local was = Keep(font)
            if was[1] then font:SetFont(was[1], was[2], MONO) end
        end
    end
    for name, size in pairs(ZONE_LINES) do
        local line = _G[name]
        if line then
            local was = Keep(line)
            if was[1] then line:SetFont(was[1], size, was[3]) end
        end
    end
end

local function Restore()
    for object, was in pairs(saved) do
        if was[1] then object:SetFont(was[1], was[2], was[3]) end
    end
    wipe(saved)
end

ns.RegisterModule("classicFonts", { apply = Apply, restore = Restore, inFight = true })
