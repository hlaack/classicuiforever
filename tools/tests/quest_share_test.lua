-- Offline tests for Quest/QuestLogShare.lua under Lua 5.4: one press of the quest log's Share runs the whole macro against
-- a stub of the game's map, whose quest rows exist only after its quest pane has shown, and shares the picked quest
-- whatever the map held before; what the press opened is shut again, and a stale pad presses nothing.
-- Run from the addon root: lua tools/tests/quest_share_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

------------------------------------------------------------------ the stub client

-- The game: the map, its quest pane, which headers are folded, the rows built at the pane's last showing.
local game = { map = false, pane = false, folded = { [1] = false }, rows = {}, details = nil, shared = {}, combat = false,
    grouped = true, cleanRows = true }
local QUESTS = { { header = 1, id = 11 }, { header = 1, id = 12 } }
local zone, openButton, closeButton, shareButton, backButton = {}, {}, {}, {}, {}
local headerButton = { questLogIndex = 1 }

local function BuildRows()
    game.rows = {}
    for _, quest in ipairs(QUESTS) do
        if not game.folded[quest.header] then game.rows[quest.id] = { questID = quest.id } end
    end
end
-- What each of the game's own buttons does when the macro's click reaches it.
local function Press(target, modifier)
    if target == zone then
        game.map = not game.map
        -- The map opens on the player's zone; the quest log is sorted for the zone the map is on.
        if game.map then game.sortedFor = "the player's zone" end
    elseif target == openButton and game.map then
        game.pane = true
        BuildRows()
    elseif target == closeButton then
        game.pane = false
    elseif target == headerButton and game.pane then
        game.folded[1] = not game.folded[1]
        BuildRows()
    elseif target == shareButton then
        if game.details then game.shared[#game.shared + 1] = game.details end
    elseif target == backButton then
        game.details = nil
    else
        for id, row in pairs(game.rows) do
            if row == target then game.details, game.sortedFor = id, "the quest's zone" end
        end
    end
end

WorldMapFrame = { IsShown = function() return game.map end, SidePanelToggle = { OpenButton = openButton, CloseButton = closeButton } }
QuestMapFrame = { IsShown = function() return game.pane end,
    DetailsFrame = { ShareButton = shareButton, BackFrame = { BackButton = backButton } } }
QuestScrollFrame = { headerFramePool = { EnumerateActive = function()
    local sent = false
    return function() if not sent and game.pane then sent = true return headerButton end end
end } }
MinimapCluster = { ZoneTextButton = zone }
QuestLogQuests_GetQuestButton = function(id) return game.rows[id] end
C_QuestLog = {
    GetNumQuestLogEntries = function() return 1 + #QUESTS end,
    GetInfo = function(i)
        if i == 1 then return { isHeader = true, isCollapsed = game.folded[1] } end
        return { questID = QUESTS[i - 1].id }
    end,
}
function InCombatLockdown() return game.combat end
function IsModifierKeyDown() return game.modifier == true end
function IsInGroup() return game.grouped end
function issecurevariable() return game.cleanRows end
local errors = {}
UIErrorsFrame = { AddMessage = function(_, text) errors[#errors + 1] = text end }

------------------------------------------------------------------ the stub addon

local proxies = {}
local selected, shareLit = 11, true
local ns = {
    L = setmetatable({}, { __index = function(_, key) return key end }),
    QL = {
        Frame = function() return { share = { IsVisible = function() return true end, IsEnabled = function() return shareLit end } } end,
        SelectedID = function() return selected end,
        QuestInLog = function(id) return { questID = id } end,
    },
    ClickProxy = function(name)
        local proxy = { name = name, attrs = {}, scripts = {} }
        function proxy:SetScript(script, fn) self.scripts[script] = fn end
        function proxy:GetName() return self.name end
        proxies[name] = proxy
        return proxy
    end,
    SetAttributeIf = function(proxy, key, value) proxy.attrs[key] = value end,
    SayNotInCombat = function() errors[#errors + 1] = "not in combat" end,
}
assert(loadfile(ROOT .. "/Quest/QuestLogShare.lua"))("ClassicUIForever", ns)
local QL = ns.QL

-- One press of the pad: the placer's macro text, each /click in order, then the pad's after.
local function PressPad(modifier)
    local text = QL.ShareMacro()
    if not text then return false end
    game.modifier = modifier
    for line in text:gmatch("[^\n]+") do
        local nomod, name = line:match("^/click (%[nomod%] )(%S+)$")
        if not name then name = line:match("^/click (%S+)$") end
        local proxy = assert(proxies[name], "the macro clicks a proxy that exists: " .. line)
        if not (nomod and modifier) then
            if proxy.scripts.PreClick then proxy.scripts.PreClick() end
            if proxy.attrs.clickbutton then Press(proxy.attrs.clickbutton, modifier) end
        end
    end
    QL.SharePadAfter()
    game.modifier = nil
    return true
end
local function Aimed()
    local n = 0
    for _, proxy in pairs(proxies) do
        if proxy.attrs.clickbutton and proxy.attrs.clickbutton ~= zone then n = n + 1 end
    end
    return n
end

------------------------------------------------------------------ checks

local failures = 0
local function Check(ok, what)
    if not ok then
        failures = failures + 1
        print("FAIL: " .. what)
    end
end

-- Fresh login: the map never shown, its pane shut, no rows. One press shares and leaves everything as it was.
Check(PressPad() == true, "a pad stands over Share for a shareable quest")
Check(#game.shared == 1 and game.shared[1] == 11, "the picked quest is shared with no row beforehand")
Check(game.map == false and game.pane == false, "the map and its quest pane are shut again")
Check(game.sortedFor == "the player's zone", "the quest log is sorted as before, not for the shared quest's zone")
Check(game.details == nil and Aimed() == 0 and #errors == 0, "nothing stays open or aimed, no error line")
Check(#QL.ShareMacro() < 255, "the macro fits a macro's length (" .. #QL.ShareMacro() .. ")")

-- Another quest picked: that one, not the last one's stale row.
selected = 12
PressPad()
Check(game.shared[2] == 12, "a newly picked quest is the one shared")

-- The quest's header folded: unfolded by its own button, then shared.
game.folded[1] = true
game.rows = {}
PressPad()
Check(game.shared[3] == 12 and game.folded[1] == false, "a quest under a folded header is shared")

-- The player keeps the map's quest pane open: it is not shut behind them.
game.pane = true
PressPad()
Check(game.shared[4] == 12 and game.pane == true and game.map == false, "a pane the player left open stays open")
game.pane = false

-- A modifier held: the map's own clicks are skipped, so nothing at all is pressed.
local before = #game.shared
PressPad(true)
Check(#game.shared == before and game.map == false and game.details == nil, "with a modifier held nothing is pressed")
Check(#errors == 0, "and no error line: the modifier was the player's")

-- Rows the game did not fill (tainted) are never pressed; the press says where to share instead.
game.cleanRows = false
PressPad()
Check(#game.shared == before and #errors == 1 and errors[1] == "QUEST_SHARE_FROM_THE_MAP", "a row not filled by the game is not pressed")
game.cleanRows, errors = true, {}

-- No pad while Share is unlit, the map is open, or in a fight; a stale pad's macro presses nothing.
shareLit = false
Check(QL.ShareMacro() == nil and proxies.FCUIQS1.attrs.clickbutton == nil, "Share unlit: no pad, the map's click unaimed")
shareLit, game.map = true, true
Check(QL.ShareMacro() == nil, "the world map open: no pad")
QL.ShareClick()
Check(errors[1] == "QUEST_CLOSE_THE_WORLD_MAP_THEN", "our own click says to close the map")
game.map, errors = false, {}
game.combat = true
Check(QL.ShareMacro() == nil, "in a fight: no pad")
QL.ShareClick()
Check(errors[1] == "not in combat", "our own click says not in combat")
game.combat, errors = false, {}
game.grouped = false
QL.ShareClick()
Check(errors[1] == "QUEST_YOU_ARE_NOT_IN_A", "alone: our own click says so")

if failures > 0 then
    print(string.format("quest share: %d failed", failures))
    os.exit(1)
end
print("quest share: ok")
