local _, ns = ...

-- The client's profession extras on the old trade skill window (Skills/TradeSkill.lua): its filters as Era's checkbox
-- menu, the slots in a submenu, and Wrath's chain link beside the title.

-- Normal on the top half, its glow on the bottom.
local LINK_ART = "Interface\\TradeSkillFrame\\UI-TradeSkill-LinkButton"

-- The client's slot filter, as its own menu has it: Check All, Uncheck All, then each slot this profession makes.
local function SetAllSlots(shown)
    local api = C_TradeSkillUI
    for i = 1, api.GetAllFilterableInventorySlotsCount() do api.SetInventorySlotFilter(i, shown) end
end

local function SlotEntries()
    local api = C_TradeSkillUI
    local entries = {
        { CHECK_ALL or "Check All", click = function() SetAllSlots(true) end },
        { UNCHECK_ALL or "Uncheck All", click = function() SetAllSlots(false) end },
    }
    for i = 1, api.GetAllFilterableInventorySlotsCount() do
        entries[#entries + 1] = { api.GetFilterableInventorySlotName(i),
            check = function() return not api.IsInventorySlotFiltered(i) end,
            toggle = function() api.SetInventorySlotFilter(i, api.IsInventorySlotFiltered(i)) end }
    end
    return entries
end

-- Era's checkbox menu over the client's filters; Slots only where this profession makes gear.
function ns.TradeSkillFilterEntries()
    local api = C_TradeSkillUI
    local entries = {
        { CRAFT_IS_MAKEABLE or "Have Materials", check = api.GetOnlyShowMakeableRecipes,
            toggle = function() api.SetOnlyShowMakeableRecipes(not api.GetOnlyShowMakeableRecipes()) end },
        { TRADESKILL_FILTER_HAS_SKILL_UP or "Has Skill Up", check = api.GetOnlyShowSkillUpRecipes,
            toggle = function() api.SetOnlyShowSkillUpRecipes(not api.GetOnlyShowSkillUpRecipes()) end },
    }
    local slots = api.GetAllFilterableInventorySlotsCount and api.GetAllFilterableInventorySlotsCount() or 0
    if slots > 0 then entries[#entries + 1] = { TRADESKILL_FILTER_SLOTS or "Slots", sub = SlotEntries } end
    local R = ns.tradeReagents
    if not ns.OnForever() then
        entries[#entries + 1] = { _G.PROFESSION_RECIPES_SHOW_UNLEARNED or "", check = R.Unlearned, toggle = R.ToggleUnlearned }
    end
    return entries
end

-- The profession's link in chat, the chat opened if shut.
function ns.TradeSkillLink(panel)
    local link = ns.NewFrame("Button", nil, panel)
    link:SetSize(32, 16)
    link:SetFrameLevel(panel:GetFrameLevel() + 13)
    link:SetNormalTexture(LINK_ART)
    link:GetNormalTexture():SetTexCoord(0, 1, 0, 0.5)
    link:SetHighlightTexture(LINK_ART, "ADD")
    link:GetHighlightTexture():SetTexCoord(0, 1, 0.5, 1)
    link:SetScript("OnClick", function()
        local text = C_TradeSkillUI.GetTradeSkillListLink and C_TradeSkillUI.GetTradeSkillListLink()
        if text and not ChatFrameUtil.InsertLink(text) then ChatFrameUtil.OpenChat(text) end
    end)
    link:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(LINK_TRADESKILL_TOOLTIP or "", nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    link:SetScript("OnLeave", GameTooltip_Hide)
    link:Hide()
    return link
end

-- Just right of the title's words (centred text), on the player's own professions only.
function ns.PlaceTradeSkillLink(link, title)
    local api = C_TradeSkillUI
    local own = not (api.IsTradeSkillLinked and api.IsTradeSkillLinked()) and not (api.IsTradeSkillGuild and api.IsTradeSkillGuild())
        and not (api.IsNPCCrafting and api.IsNPCCrafting())
    local linkable = own and title ~= nil and api.CanTradeSkillListLink and api.CanTradeSkillListLink() and true or false
    ns.SetShownIf(link, linkable)
    if linkable then ns.SetPointOnce(link, "LEFT", title, "CENTER", math.floor((title:GetStringWidth() or 0) / 2) + 5, 0) end
end
