local _, ns = ...

-- The 1.x class trainer's horizontal divider: a metal bar with a knob at each end, as between its list and detail.

-- The sheet: a 256 px run with its left knob, then a 76 px right end, each 16 rows round an 8 px bar.
local BAR_FILE = "Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar"
local BAR_H, BAR_END_W = 16, 76

local function BarPiece(owner, u1, v0, v1)
    local tex = owner:CreateTexture(nil, "OVERLAY")
    ns.SetFile(tex, BAR_FILE)
    tex:SetTexCoord(0, u1, v0, v1)
    tex:SetHeight(BAR_H)
    return tex
end

-- DividerBar(owner) -> run, end: the run (left knob) and right end, sized but unplaced; the caller sets the end's
-- TOPRIGHT and the run's TOPLEFT, the run then meets the end. Both 16 tall round the 8 px bar.
function ns.DividerBar(owner)
    local barEnd = BarPiece(owner, BAR_END_W / 256, 0.25, 0.5)
    barEnd:SetWidth(BAR_END_W)
    local barRun = BarPiece(owner, 1, 0, 0.25)
    return barRun, barEnd
end
