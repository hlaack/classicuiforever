-- Offline test for the trade skill window's reagent sums (Skills/TradeSkillReagents.lua) under Lua 5.4.
-- Retail: a slot's tiers count as one, a craft hands the game its tiered slots filled lowest first or best first, the
-- expansion shown is ours to pick. Forever: bags only, no expansions, every recipe ours to run.
-- Run from the addon root: lua tools/tests/trade_reagents_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 122 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local failures = 0
local function Check(what, got, want)
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL %s: got %s, want %s", what, tostring(got), tostring(want)))
    end
end

Enum = { CraftingReagentType = { Basic = 1, Modifying = 0, Finishing = 2 }, TradeskillSlotDataType = { Reagent = 1, ModifiedReagent = 2 } }

-- itemID -> { bags, banks }
local stock = { [101] = { 2, 3 }, [102] = { 1, 0 }, [103] = { 4, 0 }, [200] = { 5, 5 } }
C_Item = { GetItemCount = function(itemID, bank)
    local have = stock[itemID] or { 0, 0 }
    return have[1] + (bank and have[2] or 0)
end }

local tiered = { reagentType = 1, dataSlotType = 2, dataSlotIndex = 7, quantityRequired = 6,
    reagents = { { itemID = 101 }, { itemID = 102 }, { itemID = 103 } } }
local plain = { reagentType = 1, dataSlotType = 1, dataSlotIndex = 1, quantityRequired = 2, reagents = { { itemID = 200 } } }
local optional = { reagentType = 0, dataSlotType = 2, dataSlotIndex = 9, quantityRequired = 1, reagents = { { itemID = 300 } } }
local schematic = { reagentSlotSchematics = { tiered, plain, optional } }
local lines = { { professionID = 31, expansionName = "New" }, { professionID = 21, expansionName = "Old" } }
C_TradeSkillUI = {
    GetRecipeSchematic = function() return schematic end,
    GetChildProfessionInfos = function() return lines end,
    GetChildProfessionInfo = function() return { professionID = 21 } end,
}

local function Load(forever)
    local ns = { EMPTY = {}, OnForever = function() return forever end }
    assert(loadfile(ROOT .. "/Skills/TradeSkillReagents.lua"))("ClassicUIForever", ns)
    return ns.tradeReagents
end

------------------------------------------------------------------ retail

local R = Load(false)
local needs = R.Read(1)
Check("basic slots read", #needs, 2)
Check("tiers and banks count as one", R.Have(tiered), 10)
Check("tiered recipe", R.Tiered(schematic), true)

local function Shape(list)
    local parts = {}
    for _, info in ipairs(list) do parts[#parts + 1] = info.reagent.itemID .. "x" .. info.quantity .. "@" .. info.dataSlotIndex end
    return table.concat(parts, " ")
end
Check("lowest tier first", Shape(R.Infos(needs, false)), "101x5@7 102x1@7")
Check("best tier first", Shape(R.Infos(needs, true)), "103x4@7 102x1@7 101x1@7")
Check("no tiered slot, nothing handed over", R.Infos({ needs[2] }, false), nil)

Check("optional reagents are extras", R.HasExtras({}, schematic), true)
Check("an optional slot does not block", R.GameOnly({}, schematic), false)
Check("salvage is the game's", R.GameOnly({ isSalvageRecipe = true }, schematic), true)
optional.required = true
Check("a required extra slot is the game's", R.GameOnly({}, schematic), true)
optional.required = nil

Check("the game's own expansion first", R.Line().professionID, 21)
R.PickLine(31)
Check("ours once picked", R.Line().professionID, 31)
R.PickLine(99)
Check("a pick from another profession falls back", R.Line().professionID, 21)

------------------------------------------------------------------ Forever

R = Load(true)
Check("Forever counts bags only", R.Have(tiered), 7)
Check("Forever has no expansions", R.Line(), nil)
Check("Forever runs every recipe", R.GameOnly({ isEnchantingRecipe = true }, schematic), false)
Check("Forever shows no extras line", R.HasExtras({ supportsQualities = true }, schematic), false)

print(failures == 0 and "trade reagents: ok" or ("trade reagents: " .. failures .. " failures"))
if failures > 0 then os.exit(1) end
