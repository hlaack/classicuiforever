local _, ns = ...

-- One-time welcome note. The game cannot open a browser, so links open a copy box.

local O = ns.options
local TITLE = O.TITLE
local WIDTH = 420
local CURSEFORGE_URL = "https://www.curseforge.com/projects/1700043"
local GITHUB_URL = "https://github.com/wowaddonmaker/classicuiforever/issues"

local BODY = "This addon is a work in progress. Some pieces are still being measured against the old interface and will be finished before launch."
    .. "\n\nIf something looks wrong, say so. Every report helps. Reach us on CurseForge or on GitHub issues; the buttons below give you the address to copy."
    .. "\n\nAs in classic, there is no professions button (professions open from the spellbook) and the reagent bag is a round button on hover. Both can be changed under Classic bar in the settings."
    .. "\n\nAny piece that misbehaves can be switched back to the modern look in the options window."

local OnForever = ns.OnForever

ns.Popup("FCUI_COPY_LINK", {
    text = "%s\n\nPress Ctrl+C to copy",
    button1 = CLOSE or "Close",
    hasEditBox = 1,
    editBoxWidth = 360,
    OnShow = function(self, data)
        local box = ns.PopupEditBox(self)
        if box then
            box:SetText(data or "")
            box:HighlightText()
            box:SetFocus()
        end
    end,
    -- Read-only: typed text is reverted.
    EditBoxOnTextChanged = function(self, data)
        if self:GetText() ~= (data or "") then
            self:SetText(data or "")
            self:HighlightText()
        end
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
})

local function CopyLink(label, url)
    StaticPopup_Show("FCUI_COPY_LINK", label, nil, url)
end

local function CopyCurseForge() CopyLink(TITLE .. " on CurseForge", CURSEFORGE_URL) end
local function CopyGitHub() CopyLink(TITLE .. " issues on GitHub", GITHUB_URL) end
O.CopyCurseForge, O.CopyGitHub = CopyCurseForge, CopyGitHub

-- CurseForge and GitHub buttons; the caller anchors them.
function O.FeedbackButtons(parent, width)
    local curse = ns.PanelButton(parent, "CurseForge", width)
    curse:SetScript("OnClick", CopyCurseForge)
    local github = ns.PanelButton(parent, "GitHub issues", width)
    github:SetScript("OnClick", CopyGitHub)
    return curse, github
end

local window

-- The note's text block under the header, as wide as the window allows.
local function BodyText(frame, text)
    local body = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -50)
    body:SetWidth(WIDTH - 48)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(2)
    body:SetText(text)
    return body
end

local function Build()
    local frame = O.DialogWindow("ForeverClassicUIWelcome", 120)
    ns.DialogHeader(frame, TITLE)

    local body = BodyText(frame, BODY)
    local signoff = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    signoff:SetPoint("TOP", body, "BOTTOM", 0, -14)
    signoff:SetJustifyH("CENTER")
    signoff:SetText(OnForever() and "Enjoy WoW Forever!" or "")

    local curse, github = O.FeedbackButtons(frame, 120)
    local okay = ns.PanelButton(frame, "Okay", 90)
    okay:SetScript("OnClick", function() frame:Hide() end)

    curse:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -4, 50)
    github:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 4, 50)
    okay:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)

    frame:SetScript("OnHide", function()
        ns.db.welcomed = true
        -- The layout question follows.
        ns.CheckLayoutPosition()
    end)

    frame:SetSize(WIDTH, 50 + body:GetStringHeight() + (OnForever() and 30 or 0) + 100)
    return frame
end

function ns.ShowWelcome()
    if not window then window = Build() end
    window:Show()
end

-- Chat link in the game's link blue, handled by OnItemRef.
local function Link(target, label)
    return "|cff70d6ff|Hfcui:" .. target .. "|h[" .. label .. "]|h|r"
end

-- Runs in every hyperlink click.
local function OnItemRef(link)
    local target = type(link) == "string" and link:match("^fcui:(%w+)")
    if target == "status" then
        if ns.ShowStatus then ns.ShowStatus() end
    elseif target == "news" then
        ns.ShowWhatsNew()
    elseif target == "bars" then
        ns.ShowBarsNote()
    end
end

-- Hooked on first use, once.
local function HookLinks()
    ns.HookGlobal("SetItemRef", OnItemRef)
end

-- What's New: new features only (fixes are the changelog's, one button away), by version, newest first. A player gets
-- the chat line once per new version, and the box shows only the versions since the one they saw last.
local WHATSNEW = {
    { id = 5, version = "0.11.4",
        { "Fixes", "The group finder's new player friendly flag lines up with the role icons. Details in the full changelog." },
    },
    { id = 4, version = "0.11.2",
        { "Fixes", "Tabs take the mouse on the tab itself, a profession cast from the spellbook closes the book in a fight, and the loot window's header is clean. Details in the full changelog." },
    },
    { id = 3, version = "0.11.1",
        { "Classic bar pieces", "As in classic, the professions button is off the micro menu (professions open from the spellbook) and the reagent bag is a round button on hover, so bars 2 and 3 fit between the gryphons. Both are rows under Classic bar in the options." },
    },
    { id = 2, version = "0.11.0",
        { "Windows edit mode", "Tick Windows in edit mode to move and resize the character sheet, spellbook, talents, quest log, professions and map." },
        { "Profiles", "A Profiles tab in the options keeps named settings per character." },
        { "Bronze or Dark", "The custom theme comes in Forever's bronze or a dark charcoal. See the Custom theme toggle in the options." },
        { "Classic bar", "The bars are no longer reduced in size by default. The bar now carries the latency bar, key ring and reagent bag as classic did; each can be moved in edit mode or hidden under Classic bar in the options." },
        { "Minimap buttons", "Other addons' minimap buttons can gather behind one button on the ring. See the Collect addon buttons toggle in the options." },
        { "Options", "Quests and Map sections, and new rows for the map frame, loot window, loot rolls, hiding the game's tracker, the professions button and the key text." },
        { "Reset classic layout", "Puts the windows, tracker, gryphons, bar pieces and layout settings back at once." },
    },
}
local LATEST = WHATSNEW[1].id
local GOLD, GREY = "|cffffd100", "|cffa0a0a0"
local CHANGELOG_URL = "https://github.com/wowaddonmaker/classicuiforever/blob/main/CHANGELOG.md"
local NEWS_WIDTH, NEWS_BODY_MAX, NEWS_WHEEL = 480, 260, 28
local NEWS_HEADER = { width = 320 }   -- the plate: "What's New in x.y.z" runs past the stock 256

local function CopyChangelog() CopyLink(TITLE .. " changelog on GitHub", CHANGELOG_URL) end

-- The entries of every version newer than seen, each version headed by its number when there is more than one.
local function NewsText(seen)
    local sections = {}
    for _, section in ipairs(WHATSNEW) do
        if section.id > seen then sections[#sections + 1] = section end
    end
    if #sections == 0 then sections[1] = WHATSNEW[1] end
    local lines = {}
    for _, section in ipairs(sections) do
        if #sections > 1 then lines[#lines + 1] = GREY .. section.version .. "|r" end
        for _, entry in ipairs(section) do lines[#lines + 1] = GOLD .. entry[1] .. ":|r " .. entry[2] end
    end
    return table.concat(lines, "\n")
end

local newsWindow
local function BuildNews()
    local frame = O.DialogWindow("ForeverClassicUIWhatsNew", 120)
    ns.DialogHeader(frame, "What's New in " .. WHATSNEW[1].version, NEWS_HEADER)
    -- The list in a clipped box that scrolls by wheel when it runs past NEWS_BODY_MAX.
    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -50)
    scroll:SetWidth(NEWS_WIDTH - 48)
    scroll:EnableMouseWheel(true)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(NEWS_WIDTH - 48)
    scroll:SetScrollChild(child)
    local body = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", child, "TOPLEFT", 0, 0)
    body:SetWidth(NEWS_WIDTH - 48)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetSpacing(3)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local most = math.max(0, child:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(most, math.max(0, self:GetVerticalScroll() - delta * NEWS_WHEEL)))
    end)
    local note = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOP", scroll, "BOTTOM", 0, -10)
    note:SetText("Bug fixes are in the full changelog.")
    local changelog = ns.PanelButton(frame, "Full changelog", 120)
    changelog:SetScript("OnClick", CopyChangelog)
    changelog:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -4, 20)
    local okay = ns.PanelButton(frame, "Okay", 90)
    okay:SetScript("OnClick", function() frame:Hide() end)
    okay:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 4, 20)
    -- Refilled on every show: the versions since the one the player saw last.
    frame.Fill = function(_, seen)
        body:SetText(NewsText(seen))
        local height = math.ceil(body:GetStringHeight())
        child:SetHeight(height)
        local shown = math.min(height, NEWS_BODY_MAX)
        scroll:SetHeight(shown)
        scroll:SetVerticalScroll(0)
        frame:SetSize(NEWS_WIDTH, 50 + shown + 10 + 14 + 16 + 22 + 20)
    end
    return frame
end

-- The versions the chat line offered (whatsNewFrom), else the newest one alone (a fresh install was offered none).
function ns.ShowWhatsNew()
    if not newsWindow then newsWindow = BuildNews() end
    local from = tonumber(ns.db and ns.db.whatsNewFrom) or 0
    if from <= 0 or from >= LATEST then from = LATEST - 1 end
    newsWindow:Fill(from)
    newsWindow:Show()
end

-- For players coming from 0.11.0 (list 2), whose bar pieces flipped back with 0.11.1.
local BARS_NOTE = "0.11.0 put a professions button and a full-size reagent bag on the classic bar, which made it too wide for bars 2 and 3. 0.11.1 goes back to the classic pieces: no professions button (professions open from the spellbook) and a round reagent bag on hover."
    .. "\n\nIf you moved bars 2 and 3 to work around it, they now sit centred between the gryphons on their own: select one in edit mode and press Reset To Default Position, or drag it back. Every piece can be switched either way under Classic bar in the addon settings."

local barsWindow
function ns.ShowBarsNote()
    if not barsWindow then
        local frame = O.DialogWindow("ForeverClassicUIBarsNote", 120)
        ns.DialogHeader(frame, "Your bars")
        local body = BodyText(frame, BARS_NOTE)
        local check = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        check:SetSize(26, 26)
        check:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
        ns.SkinCheckbox(check)
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 2, 0)
        label:SetText("Don't show this again")
        check:SetScript("OnClick", function(self) ns.db.barsNoteOff = self:GetChecked() and true or false end)
        frame.check = check
        local okay = ns.PanelButton(frame, "Okay", 90)
        okay:SetScript("OnClick", function() frame:Hide() end)
        okay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -22, 20)
        frame:SetSize(WIDTH, 50 + body:GetStringHeight() + 70)
        barsWindow = frame
    end
    barsWindow.check:SetChecked(ns.db.barsNoteOff == true)
    barsWindow:Show()
end

-- Every login for a player who came from 0.11.0, until the note's box is ticked; the Addon messages row hushes it.
function ns.AnnounceBarsNote()
    if not ns.db or not ns.db.barsNote or ns.db.barsNoteOff or ns.db.addonMessages == false then return end
    HookLinks()
    ns.Print("Bars not where you expect? See " .. Link("bars", "here") .. ".")
end

-- Once per new version, as a chat line with a link; the dev addon clears the mark to see it again.
function ns.AnnounceWhatsNew()
    if not ns.db then return end
    local seen = tonumber(ns.db.whatsNewSeen) or 0
    if seen >= LATEST then return end
    ns.db.whatsNewFrom = seen
    ns.db.whatsNewSeen = LATEST
    if seen == 2 then ns.db.barsNote = true end
    if ns.db.addonMessages == false then return end
    HookLinks()
    local version = ns.AddonVersion and ns.AddonVersion() or ""
    ns.Print("updated to " .. version .. ". See what's new " .. Link("news", "here") .. ".")
end

-- Chat link for any addon message; installs the click handler.
function ns.ChatLink(target, label)
    HookLinks()
    return Link(target, label)
end

-- Ran the addon before the beta kept saved variables (1.60.1 70009): the classic layout survived.
local function Returning()
    return ns.ClassicLayoutActive()
end

-- A new player gets the welcome, then the layout question as it closes; everyone else the What's New, once per list.
function ns.FirstRun()
    if not ns.db then return end
    if not ns.db.welcomed and Returning() then ns.db.welcomed = true end
    if ns.db.welcomed then
        ns.SafeCall(ns.AnnounceWhatsNew)
        ns.SafeCall(ns.AnnounceBarsNote)
        ns.CheckLayoutPosition()
        return
    end
    -- The welcome stands in for this list.
    ns.db.whatsNewSeen = LATEST
    if ns.db.welcomeNote == false then
        ns.db.welcomed = true
        ns.CheckLayoutPosition()
        return
    end
    ns.ShowWelcome()
end
