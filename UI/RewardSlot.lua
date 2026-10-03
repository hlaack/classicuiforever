local _, ns = ...

-- The 1.x quest reward button at its native 147 x 41: the icon, the old name plate beside it, a count and the name.

-- RewardSlot(parent, onEnter, onClick) -> a shown button with .icon, .nameBox, .count and .name; scale and place are the caller's.
function ns.RewardSlot(parent, onEnter, onClick)
    local button = ns.NewFrame("Button", nil, parent)
    button:SetSize(147, 41)
    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(39, 39)
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.nameBox = button:CreateTexture(nil, "BACKGROUND", nil, 1)
    ns.SetTex(button.nameBox, "lootNameFrame")
    button.nameBox:SetTexCoord(0, 1, 0, 1)
    button.nameBox:SetSize(128, 64)
    button.nameBox:SetPoint("LEFT", button.icon, "RIGHT", -10, 0)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -1, 1)
    button.name = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    button.name:SetSize(90, 36)
    button.name:SetPoint("LEFT", button.nameBox, "LEFT", 15, 0)
    button.name:SetJustifyH("LEFT")
    button.name:SetWordWrap(true)
    button.name:SetMaxLines(3)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", ns.HideTip)
    button:SetScript("OnClick", onClick)
    return button
end
