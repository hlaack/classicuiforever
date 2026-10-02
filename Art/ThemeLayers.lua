local _, ns = ...

-- Colour themes in two layers: a piece's copy as drawn (custom/) under its metal alone (custom-metal/) in the theme's
-- colour. Flat colour adds the piece's stone panels (custom-flat/, one tone between the frame's lines) on top, in the
-- theme's colour. Each layer follows its piece's shown state, alpha, crop and draw layer.

local B = ns.bronze
local THEMES = B.THEMES

local weak = { __mode = "k" }
local layers = setmetatable({}, weak)   -- copy piece -> { tex, cells, on, metal, flat, copy, wrap, drawLayer, sub }
local flats = setmetatable({}, weak)    -- tinted piece -> { cells, on, flat, drawLayer, sub }
local LISTS = { layers, flats }
local own = setmetatable({}, weak)       -- our layer textures
local job

local function Theme()
    return THEMES[ns.ThemeName() or ""]
end

-- The metal-only copy of a theme copy, whatever theme folder the copy is in.
local function MetalPath(copyPath)
    return (copyPath:gsub("\\[^\\]+\\([^\\]+)$", "\\custom-metal\\%1"))
end

local function NewTex(piece)
    local tex = piece:GetParent():CreateTexture(nil, "ARTWORK")
    own[tex] = true
    tex:SetAllPoints(piece)
    return tex
end

local function FollowOne(tex, on, shown, alpha, piece)
    if not tex then return end
    ns.SetShownIf(tex, on and shown)
    if not (on and shown) then return end
    if alpha then ns.SetAlphaIf(tex, alpha) end
    tex:SetTexCoord(piece:GetTexCoord())
end

local function Follow(piece, layer)
    local shown = piece:IsShown() and piece:IsVisible()
    local alpha = shown and piece:GetAlpha() or nil
    if ns.IsSecret(alpha) then alpha = nil end
    FollowOne(layer.tex, layer.metal, shown, alpha, piece)
    FollowOne(layer.cells, layer.flat, shown, alpha, piece)
    if not shown then return end
    local drawLayer, sub = piece:GetDrawLayer()
    if drawLayer ~= layer.drawLayer or sub ~= layer.sub then
        layer.drawLayer, layer.sub = drawLayer, sub
        if layer.tex then layer.tex:SetDrawLayer(drawLayer, math.min(7, (sub or 0) + 1)) end
        if layer.cells then layer.cells:SetDrawLayer(drawLayer, math.min(7, (sub or 0) + 2)) end
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

local function Hide(layer)
    if not (layer and layer.on) then return end
    layer.on = false
    if layer.tex then layer.tex:Hide() end
    if layer.cells then layer.cells:Hide() end
end

local function Tiles(tex, piece)
    if not piece.GetHorizTile then return end
    tex:SetHorizTile(piece:GetHorizTile())
    tex:SetVertTile(piece:GetVertTile())
end

local function Tint(layer, theme)
    local t = theme.tint
    if layer.tex then layer.tex:SetVertexColor(t[1], t[2], t[3]) end
    if layer.cells then layer.cells:SetVertexColor(t[1], t[2], t[3]) end
end

-- The metal layer under colour themes; the stone panels on top while the piece's part is flat.
local function Shape(piece, layer)
    local theme = Theme()
    local flat = theme and ns.FlatOn(piece) and ns.FlatCopy(layer.copy)
    layer.metal, layer.flat = theme and theme.colorCopies or nil, flat and true or nil
    if not (layer.metal or layer.flat) then
        Hide(layer)
        return
    end
    local wrap = layer.wrap
    if layer.metal then
        layer.tex = layer.tex or NewTex(piece)
        layer.tex:SetTexture(MetalPath(layer.copy), unpack(wrap, 1, 3))
        layer.tex:SetBlendMode(piece:GetBlendMode())
        Tiles(layer.tex, piece)
    end
    if flat then
        layer.cells = layer.cells or NewTex(piece)
        layer.cells:SetTexture(flat, unpack(wrap, 1, 3))
        Tiles(layer.cells, piece)
    end
    layer.on, layer.drawLayer = true, nil
    Tint(layer, theme)
end

-- copyPath: the theme copy the piece now shows (extra args as its SetTexture had), or nil for none.
function ns.PaintCopy(piece, copyPath, ...)
    if not (piece and piece.GetParent) then return end
    local layer = layers[piece]
    local theme = copyPath and Theme()
    if not (theme and (theme.colorCopies or ns.FlatOn(piece))) then
        Hide(layer)
        return
    end
    if not layer then
        layer = { wrap = {} }
        layers[piece] = layer
    end
    local wrap = layer.wrap
    layer.copy, wrap[1], wrap[2], wrap[3] = copyPath, ...
    Shape(piece, layer)
    if not layer.on then return end
    Follow(piece, layer)
    job:Wake()
end

-- A tinted piece's stone panels (r, g, b: its tint) while its part is flat and its art has them; nil r: none.
function ns.PaintFlat(piece, r, g, b)
    local layer = flats[piece]
    local key = r and B.artKey[piece]
    local flat = key and ns.FlatOn(piece) and ns.FlatCopy((select(2, ns.TexPaths(key))))
    if not flat then
        Hide(layer)
        return
    end
    if not layer then
        layer = { cells = NewTex(piece) }
        flats[piece] = layer
    end
    layer.cells:SetTexture(flat)
    Tiles(layer.cells, piece)
    layer.cells:SetVertexColor(r, g, b)
    layer.on, layer.flat, layer.drawLayer = true, true, nil
    Follow(piece, layer)
    job:Wake()
end

-- A flat row or the theme changed: copy layers shaped again; a flat row repaints the tinted pieces now, even in a fight.
ns.OnToggle(function(key)
    if not B.THEME_KEYS[key] then return end
    for piece, layer in pairs(layers) do
        if layer.copy then
            Shape(piece, layer)
            if layer.on then Follow(piece, layer) end
        end
    end
    job:Wake()
    if key == "themeFlat" or key:find("^flat") then ns.RepaintTints() end
end)

-- Read by the dev addon's themedump probe: how the theme's layers hold a texture.
function ns.FlatState(texture)
    if own[texture] then return "our layer" end
    local layer = layers[texture]
    if layer then return layer.on and (layer.flat and "copy flat" or "copy metal") or "copy off" end
    layer = flats[texture]
    if layer then return layer.on and "tint flat" or "tint off" end
    return nil
end

-- Read by the dev addon's colour probes: how many copy layers are on, and a few seen ones as { file, r, g, b, shown }.
function ns.ThemeLayerSample(most)
    local on, out = 0, {}
    for _, layer in pairs(layers) do
        if layer.on and layer.tex then
            on = on + 1
            if #out < (most or 3) and layer.tex:IsVisible() then
                local r, g, b = layer.tex:GetVertexColor()
                out[#out + 1] = { file = layer.tex:GetTexture(), r = r, g = g, b = b, shown = layer.tex:IsShown() }
            end
        end
    end
    return on, out
end

function ns.FlatLayersShown()
    local count = 0
    for _, list in ipairs(LISTS) do
        for _, layer in pairs(list) do
            if layer.on and layer.flat and layer.cells:IsShown() then count = count + 1 end
        end
    end
    return count
end

local function Recolour()
    local theme = Theme()
    if theme then
        for _, layer in pairs(layers) do
            if layer.on then Tint(layer, theme) end
        end
    end
    ns.RepaintColours()
end

-- Each step of a drag only recolours; the full repaint and apply pass run once the control rests (they lagged a drag).
local SETTLE = 0.4
local movedAt = 0
local function Settle()
    if GetTime() - movedAt < SETTLE - 0.01 then return end
    ns.RepaintBronze()
    if ns.QueueApply then ns.QueueApply() end
end

local function Retint()
    Recolour()
    movedAt = GetTime()
    ns.Sched.AfterPerFrame("theme.settle", SETTLE, Settle)
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
