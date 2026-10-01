local _, ns = ...

-- Hide micro buttons on the game's own micro menu while the classic bar is off: a pick is hidden (the game closes the gap
-- itself) and hidden again after the game shows it; shown again when the pick, the option or the game's bar goes.

local GAME_HIDE = {
    CharacterMicroButton = "hideMicroCharacter", SpellbookMicroButton = "hideMicroSpellbook",
    TalentMicroButton = "hideMicroTalents", PlayerSpellsMicroButton = "hideMicroTalents",
    ProfessionMicroButton = "hideProfessionsButton", QuestLogMicroButton = "hideMicroQuestLog",
    AchievementMicroButton = "hideMicroAchievements", LegacyMicroButton = "hideMicroLegacy",
    GuildMicroButton = "hideMicroGuild", LFDMicroButton = "hideMicroGroupFinder",
    CollectionsMicroButton = "hideMicroCollections", HelpMicroButton = "hideMicroHelp",
    StoreMicroButton = "hideMicroShop", MainMenuMicroButton = "hideMicroGameMenu",
}
local hidden = setmetatable({}, { __mode = "k" })   -- buttons we hid, shown again on hand-back

local function Picked(button)
    local key = GAME_HIDE[button:GetName() or ""]
    local db = ns.db
    return key ~= nil and db.hideMicroButtons == true and db[key] == true and not ns.ModuleInForce("classicBar")
end

-- Out of a fight only: the game lays its menu out again on the hide.
local function HideOne(button)
    if InCombatLockdown() then
        ns.WhenCalm("gameMicro." .. button:GetName(), function() HideOne(button) end)
        return
    end
    if not (Picked(button) and button:IsShown()) then return end
    hidden[button] = true
    button:Hide()
end

local function Sync()
    for name in pairs(GAME_HIDE) do
        local button = _G[name]
        if button then
            if Picked(button) then
                ns.Sched.AfterShow(button, "gameMicro", function() HideOne(button) end)
                HideOne(button)
            elseif hidden[button] then
                hidden[button] = nil
                button:Show()
            end
        end
    end
end

ns.RegisterModule("hideMicroButtons", { apply = Sync, restore = Sync })
