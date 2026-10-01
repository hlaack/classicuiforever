local _, ns = ...

-- Colour themes in two layers: a piece's copy as drawn (custom/) under its metal alone (custom-metal/) in the theme's
-- colour; flat colour cuts one colour to that metal (a mask), or to a tinted piece's own art. A layer follows its
-- piece's shown state, alpha, crop and draw layer each frame while on, so button states carry it too.

local B = ns.bronze
local THEMES = B.THEMES
local METAL_FROM, METAL_TO = "\\custom\\", "\\custom-metal\\"

local weak = { __mode = "k" }
local layers = setmetatable({}, weak)   -- copy piece -> { tex, on, metal, wrap, mask, masked, drawLayer, sub }
local flats = setmetatable({}, weak)    -- tinted piece -> { tex, on, mask, masked, atlas, file, drawLayer, sub }
local LISTS = { layers, flats }
local job

local function Custom()
    local theme = THEMES[ns.ThemeName() or ""]
    return theme and theme.colorCopies and theme or nil
end

local function Mask(piece, layer)
    local mask = layer.mask
    if not mask then
        mask = piece:GetParent():CreateMaskTexture()
        mask:SetAllPoints(piece)
        layer.mask = mask
    end
    if not layer.masked then
        layer.tex:AddMaskTexture(mask)
        layer.masked = true
    end
    if piece.GetHorizTile then
        mask:SetHorizTile(piece:GetHorizTile())
        mask:SetVertTile(piece:GetVertTile())
    end
    return mask
end

local function Unmask(layer)
    if not layer.masked then return end
    layer.tex:RemoveMaskTexture(layer.mask)
    layer.masked = false
end

-- A flat layer's shape follows the piece's own art: its atlas, else its file. False: nothing to cut it to.
local function OwnShape(piece, layer)
    local atlas = piece:GetAtlas()
    if ns.IsSecret(atlas) then return layer.atlas ~= nil or layer.file ~= nil end
    if atlas then
        if atlas ~= layer.atlas then
            layer.atlas, layer.file = atlas, nil
            layer.mask:SetAtlas(atlas)
        end
        return true
    end
    local file = piece:GetTexture()
    if ns.IsSecret(file) then return layer.file ~= nil end
    if not file then return false end
    if file ~= layer.file or layer.atlas then
        layer.atlas, layer.file = nil, file
        layer.mask:SetTexture(file, piece:GetHorizTile() and "REPEAT" or "CLAMP", piece:GetVertTile() and "REPEAT" or "CLAMP")
    end
    return true
end

local function Follow(piece, layer)
    local tex = layer.tex
    local shown = piece:IsShown() and (not layer.own or OwnShape(piece, layer))
    ns.SetShownIf(tex, shown)
    if not shown or not piece:IsVisible() then return end
    local alpha = piece:GetAlpha()
    if not ns.IsSecret(alpha) then ns.SetAlphaIf(tex, alpha) end
    if not layer.atlas then (layer.masked and layer.mask or tex):SetTexCoord(piece:GetTexCoord()) end
    local drawLayer, sub = piece:GetDrawLayer()
    if drawLayer ~= layer.drawLayer or sub ~= layer.sub then
        layer.drawLayer, layer.sub = drawLayer, sub
        tex:SetDrawLayer(drawLayer, math.min(7, (sub or 0) + 1))
    end
end

local function FollowAll()
    local any = false
    for _, list in ipairs(LISTS) do
        for piece, layer in pairs(list) do
            if layer.on then
                any = true
                Follow(piece, layer)
            end
        end
    end
    if not any then job:Sleep() end
end
job = ns.Sched.Job({ name = "theme.layers", every = 0, awake = false, fn = FollowAll })

local function Tint(layer, theme)
    layer.tex:SetVertexColor(theme.tint[1], theme.tint[2], theme.tint[3])
end

-- The metal layer as drawn, or flat: one colour cut to the metal's shape.
local function Shape(piece, layer)
    local tex = layer.tex
    if ns.FlatOn(piece) then
        tex:SetColorTexture(1, 1, 1)
        Mask(piece, layer):SetTexture(layer.metal, unpack(layer.wrap, 1, 3))
    else
        Unmask(layer)
        tex:SetTexture(layer.metal, unpack(layer.wrap, 1, 3))
    end
end

-- copyPath: the custom copy the piece now shows (extra args as its SetTexture had), or nil for none.
function ns.PaintCopy(piece, copyPath, ...)
    if not (piece and piece.GetParent) then return end
    local layer = layers[piece]
    local theme = copyPath and Custom()
    if not theme then
        if layer and layer.on then
            layer.on = false
            layer.tex:Hide()
        end
        return
    end
    if not layer then
        layer = { tex = piece:GetParent():CreateTexture(nil, "ARTWORK"), wrap = {} }
        layers[piece] = layer
    end
    local tex = layer.tex
    layer.metal = copyPath:gsub(METAL_FROM, METAL_TO)
    local wrap = layer.wrap
    wrap[1], wrap[2], wrap[3] = ...
    Shape(piece, layer)
    tex:SetAllPoints(piece)
    tex:SetBlendMode(piece:GetBlendMode())
    if piece.GetHorizTile then
        tex:SetHorizTile(piece:GetHorizTile())
        tex:SetVertTile(piece:GetVertTile())
    end
    layer.drawLayer, layer.on = nil, true
    Tint(layer, theme)
    Follow(piece, layer)
    job:Wake()
end

-- A tinted piece in one flat colour (r, g, b: its tint) cut to its own art while its part is flat; nil r: none.
function ns.PaintFlat(piece, r, g, b)
    local layer = flats[piece]
    if not (r and piece.GetAtlas and ns.FlatOn(piece)) then
        if layer and layer.on then
            layer.on = false
            layer.tex:Hide()
        end
        return
    end
    if not layer then
        layer = { tex = piece:GetParent():CreateTexture(nil, "ARTWORK"), own = true }
        layer.tex:SetAllPoints(piece)
        layer.tex:SetColorTexture(1, 1, 1)
        flats[piece] = layer
        Mask(piece, layer)
    end
    layer.tex:SetVertexColor(r, g, b)
    layer.on, layer.drawLayer, layer.atlas, layer.file = true, nil, nil, nil
    Follow(piece, layer)
    job:Wake()
end

-- A flat row or the theme changed: copy layers cut again; a flat row repaints the tinted pieces now, even in a fight.
ns.OnToggle(function(key)
    if not B.THEME_KEYS[key] then return end
    for piece, layer in pairs(layers) do
        if layer.on then Shape(piece, layer) end
    end
    if key == "themeFlat" or key:find("^flat") then ns.RepaintTints() end
end)

function ns.FlatLayersShown()
    local count = 0
    for _, list in ipairs(LISTS) do
        for _, layer in pairs(list) do
            if layer.on and layer.masked and layer.tex:IsShown() then count = count + 1 end
        end
    end
    return count
end

-- Every layer and tinted piece repainted in the theme's colour now.
local function Retint()
    ns.ThemeName()
    local theme = Custom()
    if theme then
        for _, layer in pairs(layers) do
            if layer.on then Tint(layer, theme) end
        end
    end
    ns.RepaintBronze()
    if ns.QueueApply then ns.QueueApply() end
end

-- The picked custom colour, saved and painted.
function ns.SetThemeColor(r, g, b)
    ns.db.themeColor = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5))
    Retint()
end

-- Dark's slider (0-100), saved and painted.
function ns.SetThemeDarkness(level)
    ns.db.themeDarkness = math.max(0, math.min(100, math.floor((tonumber(level) or ns.DARKNESS_DEFAULT) + 0.5)))
    Retint()
end
