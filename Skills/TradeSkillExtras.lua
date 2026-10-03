local _, ns = ...

-- The client's profession extras on the old trade skill window (Skills/TradeSkill.lua): its filters as Era's checkbox
-- menu, the slots in a submenu.

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
    return entries
end
