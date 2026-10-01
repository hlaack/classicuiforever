local _, ns = ...

-- Flat colour: which part (its row under Flat colour) a themed piece belongs to, by a tag from its painter, else by
-- the frames it sits in; anything else counts as the windows' part.

local PART_ROOTS = {
    flatBars = { "ForeverClassicUIBar", "ForeverClassicUIMicroGroup", "ForeverClassicUIBagsExtra", "MainActionBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
        "StanceBar", "PetActionBar", "PossessActionBar", "BagsBar", "MicroMenuContainer", "StatusTrackingBarManager" },
    flatUnitFrames = { "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "PartyFrame", "TargetFrameToT",
        "FocusFrameToT", "PlayerCastingBarFrame", "PetCastingBarFrame", "TargetFrameSpellBar", "FocusFrameSpellBar",
        "MirrorTimerContainer", "SwingTimerMainHandFrame", "SwingTimerOffHandFrame", "SwingTimerRangedFrame" },
    flatMinimap = { "MinimapCluster", "Minimap" },
    flatCharacter = { "CharacterFrame" },
    flatSpellbook = { "PlayerSpellsFrame", "SpellBookFrame", "ForeverClassicUISpellBook" },
}
local DEPTH = 16

local weak = { __mode = "k" }
local tags = setmetatable({}, weak)       -- piece -> part, from its painter
local parts = setmetatable({}, weak)      -- piece -> part, worked out once
local rootPart = setmetatable({}, weak)   -- frame -> part
local buttons = setmetatable({}, weak)    -- action buttons
local stale = true

function ns.FlatTag(piece, part)
    if not piece then return end
    tags[piece] = part
    parts[piece] = nil
end

local function AddButton(button) buttons[button] = true end

local function Roots()
    for part, names in pairs(PART_ROOTS) do
        for _, name in ipairs(names) do
            local frame = _G[name]
            if frame then rootPart[frame] = part end
        end
    end
    if ns.ForEachActionButton then ns.ForEachActionButton(AddButton) end
end

local function PartOf(piece)
    local frame = piece:GetParent()
    for _ = 1, DEPTH do
        if not frame or frame == UIParent or ns.IsForbidden(frame) then break end
        if buttons[frame] then return "flatButtons" end
        local part = rootPart[frame]
        if part then return part end
        local name = frame:GetName()
        if name and name:find("^NamePlate%d") then return "flatNameplates" end
        frame = frame:GetParent()
    end
    return "flatWindows"
end

-- True while Flat colour is on with a theme and the piece's part is ticked.
function ns.FlatOn(piece)
    local db = ns.db
    if not (db and db.themeFlat == true and ns.ThemeName()) then return false end
    if stale then
        stale = false
        wipe(parts)
        Roots()
    end
    local part = tags[piece] or parts[piece]
    if not part then
        part = PartOf(piece)
        parts[piece] = part
    end
    return db[part] ~= false
end

-- Windows and bars that load later: their pieces are placed again.
ns.EventFrame("ADDON_LOADED", function() stale = true end)
