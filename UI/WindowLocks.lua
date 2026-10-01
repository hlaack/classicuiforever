local _, ns = ...
local L = ns.L

local W = ns.windowEdit
local Plain = ns.Safe

-- Each window's lock beside its close button (the map's beside maximize): the same switch as Movable anytime (the map's
-- Unlock map). Shown while the mouse is on the title bar, or always with windowLocksAlways.
local LOCK = "Interface\\Buttons\\LockButton-"
local LOCK_ZONE_H = 40
local locks, zones, resets = {}, {}, {}   -- entry key -> its lock, its title bar zone, its reset
local RESET_TIP = { text = HUD_EDIT_MODE_RESET_POSITION or L["UI_RESET_POSITION"], r = 1, g = 1, b = 1, lines = { {
    L["UI_RESET_POSITION_TIP"], nil, nil, nil, true } } }

local function LockTip(entry)
    local map = entry.quests
    return { text = map and L["UI_MAP_LOCK"] or L["UI_WINDOW_LOCK"], r = 1, g = 1, b = 1, lines = { { function()
        if map then return W.IsFree(entry) and L["UI_UNLOCKED_DRAG_THE_MAP_BY"] or L["UI_LOCKED_CLICK_TO_DRAG_THE"] end
        return W.IsFree(entry) and L["UI_UNLOCKED_DRAG_THE_WINDOW_BY"] or L["UI_LOCKED_CLICK_TO_DRAG_THE_WINDOW"]
    end, nil, nil, nil, true } } }
end

-- Maximized, the map is the client's full screen and nothing of ours moves it: no lock then.
local function LockShown(entry)
    local lock = locks[entry.key]
    if not lock then return end
    local reset = resets[entry.key]
    local over = ns.db.windowLocksAlways or zones[entry.key]:IsMouseOver() or lock:IsMouseOver() or reset:IsMouseOver()
    local shown = over and not W.Full(entry, _G[entry.name])
    ns.SetShownIf(lock, shown)
    -- Only a window with a place of its own has one to reset.
    ns.SetShownIf(reset, shown and W.Places()[entry.key] ~= nil)
end

local function SyncLocks()
    for _, entry in ipairs(W.WINDOWS) do
        local lock = locks[entry.key]
        if lock then
            local state = W.IsFree(entry) and "Unlocked-" or "Locked-"
            lock:SetNormalTexture(LOCK .. state .. "Up")
            lock:SetPushedTexture(LOCK .. state .. "Down")
            -- Under the mouse, its tooltip says the new state at once.
            if GameTooltip:IsOwned(lock) then lock:GetScript("OnEnter")(lock) end
            LockShown(entry)
        end
    end
end

local function ToggleLock(entry)
    if entry.toggle then
        W.Set(entry.toggle, not W.IsFree(entry))
        ns.ToggleChanged(entry.toggle)
    else
        W.Freed()[entry.key] = not W.IsFree(entry) or nil
        W.PlaceAll()
    end
end

-- Beside the close button (the map's maximize), looked up on each show: our windows make theirs after they register.
local function PlaceLock(entry)
    local frame, lock = _G[entry.name], locks[entry.key]
    local beside = frame.close or frame.Close or frame.CloseButton
    if entry.quests then
        local border = frame.BorderFrame or frame
        beside = border.MaximizeMinimizeFrame or border.CloseButton
    end
    if beside then
        ns.SetPointOnce(lock, "RIGHT", beside, "LEFT", 2, 0)
    else
        ns.SetPointOnce(lock, "TOPRIGHT", frame, "TOPRIGHT", -56, -2)
    end
    -- The reset at the title bar's far left, level with the close button: away from it, so not pressed by mistake.
    local mid, top = nil, Plain(frame:GetTop())
    if beside then mid = Plain(select(2, beside:GetCenter())) end
    ns.SetPointOnce(resets[entry.key], "CENTER", frame, "TOPLEFT", W.STRIP_LEFT + 14, (mid and top) and mid - top or -24)
end

-- The title bar is watched while the window shows: a hover sensor over it would take the close button's hover.
local function MakeLock(entry)
    local frame = _G[entry.name]
    if entry.piece or locks[entry.key] or not frame then return end
    local parent = entry.quests and frame.BorderFrame or frame
    local lock = CreateFrame("Button", nil, parent)
    lock:SetSize(28, 28)
    -- Over the drag strip, which reaches under it.
    lock:SetFrameLevel(frame:GetFrameLevel() + 25)
    lock:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    lock:SetScript("OnClick", function() ToggleLock(entry) end)
    ns.AttachTip(lock, LockTip(entry))
    -- The lock's size, in the round gold of the model's rotate buttons (a turning arrow: back where it was).
    local reset = CreateFrame("Button", nil, parent)
    reset:SetSize(28, 28)
    reset:SetFrameLevel(frame:GetFrameLevel() + 25)
    reset:SetNormalTexture((ns.TexPath("rotateLeftUp")))
    reset:SetPushedTexture((ns.TexPath("rotateLeftDown")))
    reset:SetHighlightTexture((ns.TexPath("roundHighlight")))
    reset:GetHighlightTexture():SetBlendMode("ADD")
    reset:SetScript("OnClick", function()
        W.Reset(entry)
        SyncLocks()
    end)
    ns.AttachTip(reset, RESET_TIP)
    reset:Hide()
    resets[entry.key] = reset
    local zone = CreateFrame("Frame", nil, parent)
    zone:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    zone:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, -LOCK_ZONE_H)
    locks[entry.key], zones[entry.key] = lock, zone
    PlaceLock(entry)
    local function Shown() LockShown(entry) end
    ns.Sched.Attach(frame, { name = "windowLock", every = 0.1, fn = Shown })
    ns.Sched.AfterShow(frame, "windowLock", function()
        PlaceLock(entry)
        Shown()
    end)
    if entry.quests then ns.Sched.OnMove(frame, function() ns.Sched.NextFrame("windows.mapLock", Shown) end) end
end

ns.MakeWindowLock = MakeLock
ns.SyncWindowLocks = SyncLocks
ns.OnToggle(function(key) if key == "windowLocksAlways" then SyncLocks() end end)
