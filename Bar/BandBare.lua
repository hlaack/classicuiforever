local _, ns = ...
local B = ns.band

-- Bar 1's Hide Bar Art on our layout counts only as the player's own tick in edit mode (ns.db.barArtHidden): the
-- layout holds one value, and a write to it from elsewhere left the band bare for a player who never asked.

local touched = false   -- the box flipped in this edit session
local seenFlag, seenOurs

-- Bar 1's Hide Bar Art entry in the active layout's data, or nil.
function B.LayoutArtEntry()
    local info = ns.ActiveLayoutInfo()
    local bars, setting = Enum.EditModeActionBarSystemIndices, Enum.EditModeActionBarSetting
    if not (info and type(info.systems) == "table" and bars and setting) then return nil end
    for _, system in ipairs(info.systems) do
        if system.system == Enum.EditModeSystem.ActionBar and system.systemIndex == bars.MainBar
            and type(system.settings) == "table" then
            for _, entry in ipairs(system.settings) do
                if type(entry) == "table" and entry.setting == setting.HideBarArt then return entry end
            end
        end
    end
end

-- An install from before keeps what its layout holds, read from the data the first time our layout is up (the bar's
-- own field is set later in the client's pass).
local function KeepOld()
    if not ns.ClassicLayoutActive() then return end
    local entry = B.LayoutArtEntry()
    ns.db.barArtKeep = nil
    ns.db.barArtHidden = entry ~= nil and entry.value == 1
end

-- Runs before the defaults fill.
function ns.KeepBarArt()
    ns.db.barArtKeep = true
    ns.db.dbVersion = 9
end

-- Bar 1's art hidden: the client's flag, on our layout only with the player's tick behind it.
function B.BarBare(bar)
    if ns.db.barArtKeep then KeepOld() end
    if not (bar and bar.hideBarArt == true) then return false end
    return ns.db.barArtHidden == true or touched or not ns.ClassicLayoutActive()
end

-- The band's watch beat: a flip of the box on our layout while edit mode is up is the player's, and what it reads as
-- edit mode shuts is kept. A layout switch flips it too, and is not a tick.
function B.WatchArtTick(editing)
    local bar = ns.GetMainBar()
    if not bar or (not editing and seenFlag == nil) then return end
    local flag, ours = bar.hideBarArt == true, ns.ClassicLayoutActive()
    if ours and seenOurs and flag ~= seenFlag then touched = true end
    if editing then
        seenFlag, seenOurs = flag, ours
        return
    end
    if touched and ours then ns.db.barArtHidden = flag end
    touched, seenFlag, seenOurs = false, nil, nil
end
