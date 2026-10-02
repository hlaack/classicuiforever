local _, ns = ...

-- Flat colour: which part (its row under Flat colour) a themed piece belongs to, by the frames it sits in; anything
-- else counts as the other windows' part.

local PART_ROOTS = {
    flatBars = { "ForeverClassicUIBar", "ForeverClassicUIMicroGroup", "ForeverClassicUIBagsExtra", "MainActionBar",
        "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7",
        "StanceBar", "PetActionBar", "PossessActionBar", "BagsBar", "MicroMenuContainer", "StatusTrackingBarManager" },
    flatCharacter = { "CharacterFrame" },
    flatSpellbook = { "PlayerSpellsFrame", "SpellBookFrame", "ForeverClassicUISpellBook" },
}
local DEPTH = 16

local weak = { __mode = "k" }
local parts = setmetatable({}, weak)      -- piece -> part, worked out once
local rootPart = setmetatable({}, weak)   -- frame -> part
local stale = true

local function Roots()
    for part, names in pairs(PART_ROOTS) do
        for _, name in ipairs(names) do
            local frame = _G[name]
            if frame then rootPart[frame] = part end
        end
    end
end

local function PartOf(piece)
    local frame = piece:GetParent()
    for _ = 1, DEPTH do
        if not frame or frame == UIParent or ns.IsForbidden(frame) then break end
        local part = rootPart[frame]
        if part then return part end
        frame = frame:GetParent()
    end
    return "flatWindows"
end

-- Read by the dev addon's flatdump probe.
function ns.FlatPartOf(piece) return parts[piece] or PartOf(piece) end

-- True while Flat colour is on with a theme and the piece's part is ticked.
function ns.FlatOn(piece)
    local db = ns.db
    if not (db and db.themeFlat == true and ns.ThemeName()) then return false end
    if stale then
        stale = false
        wipe(parts)
        Roots()
    end
    local part = parts[piece]
    if not part then
        part = PartOf(piece)
        parts[piece] = part
    end
    return db[part] ~= false
end

-- Windows and bars that load later: their pieces are placed again.
ns.EventFrame("ADDON_LOADED", function() stale = true end)
