local _, ns = ...

-- Classic's group finder eye on the minimap ring, with the micro menu's group finder button hidden or not. Its click goes
-- through a secure pad onto that button, so the finder opens in the player's name. Face: the first eye frame, cropped.

local EYE = { layer = "ARTWORK", coords = { 0.019, 0.106, 0.0375, 0.2125 }, w = 24, h = 24, point = "CENTER", relPoint = "TOPLEFT",
    x = ns.RING_ICON_FACE.x, y = ns.RING_ICON_FACE.y }

local function Wanted()
    return ns.db and ns.db.lfgMinimapButton == true and _G.LFDMicroButton ~= nil
end

-- The eye showed only with the micro button hidden: an install from before with that button showing keeps no eye, in the
-- account and every profile. Runs before the defaults fill.
function ns.KeepGroupFinderEye()
    local db = ns.db
    local function Keep(t)
        if t.hideMicroButtons == false or t.hideMicroGroupFinder == false then t.lfgMinimapButton = false end
    end
    Keep(db)
    for _, shot in pairs(type(db.profiles) == "table" and db.profiles or {}) do
        if type(shot) == "table" then Keep(shot) end
    end
    db.dbVersion = 8
end

local padded = false
local ShowRing, HideRing = ns.RingButton({
    name = "ForeverClassicUIGroupFinderButton",
    key = "minimapGroupFinder",
    angleKey = "lfgButtonAngle",
    angle = 137,   -- Era's LFG eye spot (backdrop top left +25, -28)
    show = "GroupFinderButton",
    face = function(icon) ns.Dress(icon, "lfgEye", EYE) end,
    tip = { anchor = "ANCHOR_LEFT", text = function()
        local name = _G.LFG_BUTTON or "Group Finder"
        return MicroButtonTooltipText and MicroButtonTooltipText(name, "TOGGLEGROUPFINDER") or name
    end, r = 1, g = 1, b = 1 },
})

local function Apply()
    if not Wanted() then
        HideRing()
        return
    end
    ShowRing()
    local button = _G.ForeverClassicUIGroupFinderButton
    if button and not padded then
        padded = true
        ns.MapPad(button, "MEDIUM", nil, _G.LFDMicroButton)
    end
end

ns.RegisterModule("lfgMinimapButton", { apply = Apply, restore = HideRing })
