-- Offline test under Lua 5.4 for the social window's foot tabs: retail's client has a Who tab of its own, which leaves
-- the row while ours stands in it and comes back when ours goes (Social/SocialWindow.lua).
-- Run from the addon root: lua tools/tests/social_tabs_test.lua (CI runs every tools/tests/*_test.lua).
-- luacheck: std lua54
-- luacheck: ignore 111 112 113 121 212

local ROOT = (arg and arg[0] or ""):gsub("[\\/]tools[\\/]tests[\\/][^\\/]*$", "")
if ROOT == (arg and arg[0]) or ROOT == "" then ROOT = "." end

local failed = 0
local function Check(ok, what)
    if not ok then
        failed = failed + 1
        print("FAIL: " .. what)
    end
end

local quiet = { __index = function() return function() end end }

local function Addon(onForever)
    local ns = setmetatable({}, quiet)
    ns.OnForever = function() return onForever end
    -- Our art replaces the client's atlas.
    ns.Dress = function(tex) tex.atlas = nil end
    ns.SetAlphaIf = function(region, alpha) region.alpha = alpha end
    ns.WhenCalm = function(_, fn) fn() end
    return ns
end

local function Load(file, ns)
    assert(loadfile(ROOT .. "/" .. file))("ClassicUIForever", ns)
end

InCombatLockdown = function() return false end

------------------------------------------------------------------ the client's Who tab

local Tab = {}
Tab.__index = Tab
function Tab:IsShown() return self.shown end
function Tab:ClearAllPoints() self.after = nil end
function Tab:SetPoint(point, rel) if point == "LEFT" then self.after = rel end end
function Tab:EnableMouse(on) self.mouse = on end

local function NewTab() return setmetatable({ shown = true, mouse = true, alpha = 1 }, Tab) end

local function Social(clientWho)
    FriendsFrame = {}
    for i = 1, 8 do _G["FriendsFrameTab" .. i] = nil end
    FriendsFrameTab1, FriendsFrameTab3, FriendsFrameTab4 = NewTab(), NewTab(), NewTab()
    FriendsFrameTab2 = clientWho and NewTab() or nil
    FRIEND_TAB_WHO = clientWho and 2 or nil
    local ns = Addon(not clientWho)
    Load("Social/SocialWindow.lua", ns)
    ns.social.whoTab = NewTab()
    return ns.social
end

do
    local S = Social(true)
    Check(S.ClientWhoTab(true) == true, "retail: the client's Who tab is taken")
    S.PlaceTabs()
    Check(FriendsFrameTab2.alpha == 0 and FriendsFrameTab2.mouse == false, "retail: it is unseen and takes no mouse")
    Check(S.whoTab.after == FriendsFrameTab1, "retail: our Who tab stands after Friends")
    Check(FriendsFrameTab3.after == S.whoTab, "retail: Raid follows our tabs, not the client's Who tab")
    Check(S.ClientWhoTab(true) == false, "retail: taking it twice changes nothing")

    Check(S.ClientWhoTab(false) == true, "retail: the tab is handed back")
    S.PlaceTabs()
    Check(FriendsFrameTab2.alpha == 1 and FriendsFrameTab2.mouse == true, "retail: handed back, it shows and takes the mouse")
    Check(FriendsFrameTab3.after == FriendsFrameTab2, "retail: handed back, it stands in the row again")
end

do
    local S = Social(false)
    Check(S.ClientWhoTab(true) == false, "Forever: no client Who tab to take")
    S.PlaceTabs()
    Check(FriendsFrameTab3.after == S.whoTab, "Forever: the row is Friends, Who, then the client's others")
end

if failed > 0 then
    print(failed .. " check(s) failed")
    os.exit(1)
end
print("social_tabs_test: ok")
