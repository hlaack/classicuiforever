local _, ns = ...

-- The talent window's data: this client's single tree (three groups; nodes with position, ranks, edges)
-- read into three lists of talents on a grid (ns.ReadTraitTree, UI/TraitTree.lua).

local TL = ns.talents

-- unit: nil for the player, or the inspected unit (its own read-only config).
local function ConfigID(unit)
    if unit then
        return Constants and Constants.TraitConsts and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or -1
    end
    local spec = C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup and C_SpecializationInfo.GetActiveSpecGroup()
    local id = spec and C_SpecializationInfo.GetCombatConfigIDForSpecGroup and C_SpecializationInfo.GetCombatConfigIDForSpecGroup(spec)
    if not id and C_ClassTalents and C_ClassTalents.GetActiveConfigID then id = C_ClassTalents.GetActiveConfigID() end
    return id
end

-- The tree read into three lists of talents on a grid.
function TL.ReadTree(unit)
    local configID = ConfigID(unit)
    if not configID or not C_Traits then return nil end
    local config = C_Traits.GetConfigInfo(configID)
    local treeID = config and config.treeIDs and config.treeIDs[1]
    return ns.ReadTraitTree(configID, treeID, unit and { inspect = true } or nil)
end
