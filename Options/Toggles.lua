local _, ns = ...

-- Private table the Options files share.
local O = {}
ns.options = O
O.TITLE = "ClassicUI Forever"

-- key, label, tooltip; parent makes it an indented sub-toggle, grayed while the parent is off; group starts a headed section;
-- radio groups rows where exactly one is on (drop: one drop down row); search adds words the search finds.
-- Order drives the options list, /fcui help and the reload prompt (Core ToggleTree); Status reads it. Kids follow their parent.
local SHOW_TIP = "Shown, only while the mouse is over the minimap, or hidden. Move it in ClassicUI Forever Windows (edit mode)."
ns.TOGGLES = {
    { "bronzeTheme", "Custom theme", "Recolors the classic look's metal (gryphons, borders, minimap rings, tooltips and item slots) in the color picked below.", group = "Look", search = "custom skin color dark mode" },
    { "themeBronze", "Bronze", "Forever's bronze instead of the old silver. Tooltips and menus show Forever's own art.", parent = "bronzeTheme", radio = "theme" },
    { "themeCustom", "Custom colour", "Metal in a colour you pick below. Tooltips and menus keep the 1.x shapes.", parent = "bronzeTheme", radio = "theme", search = "rgb hex color" },
    { "themeDark", "Dark", "Charcoal metal for a darker interface. Tooltips and menus keep the 1.x shapes, darkened.", parent = "bronzeTheme", radio = "theme" },
    { "panels", "Window frames", "The old metal border, round portrait, small X and stone title strip on the game's windows." },
    { "buttons", "Button style", "Square slot borders, the red attack flash and the old pressed and highlight art." },
    { "squareIcons", "Square icons", "Icons without the rounded mask, as in 1.x.", parent = "buttons" },
    { "hideKeyText", "Hide key text", "No key names on the action buttons.", parent = "buttons" },
    { "castAnim", "Hide cast animation", "Nothing plays over a button while its spell casts, as in 1.x. The cooldown swipe stays." },

    { "classicBar", "Classic bar", "The stone band with gryphons at the bottom: action buttons, page arrows, micro buttons, bags and the experience bar in their 1.x spots.", group = "Action bars" },
    { "microTips", "Micro button descriptions", "A line under each micro button's name saying what it opens, as in 1.x.", parent = "classicBar", search = "tooltip" },
    { "hideMicroButtons", "Hide micro buttons", "Takes the buttons picked below off the micro menu; the menu closes up.", parent = "classicBar", search = "micro menu buttons character spellbook talents professions quest guild group finder collections achievements legacy journal housing help" },
    { "hideMicroKeepSize", "Keep button size", "Hidden buttons still count toward the buttons' size, so the rest never grow.", parent = "hideMicroButtons" },
    { "hideMicroKeepWidth", "Keep the menu's width", "Hidden buttons leave their gap and the menu and its art keep their width, instead of closing up.", parent = "hideMicroButtons", search = "gap background" },
    { "hideMicroSpread", "Spread the rest evenly", "With the width kept, the remaining buttons spread across it so there are no gaps.", parent = "hideMicroKeepWidth", search = "gap spacing" },
    { "bandHoldsBars", "Band holds bars 2 and 3", "The micro menu's art widens so bars 2 and 3 never hang past the band's end, as on Era.", parent = "hideMicroButtons", search = "gap width bar 3" },
    { "hideMicroCharacter", "Character", "Hides the character button.", parent = "hideMicroButtons" },
    { "hideMicroSpellbook", "Spellbook", "Hides the spellbook button.", parent = "hideMicroButtons" },
    { "hideMicroTalents", "Talents", "Hides the talents button.", parent = "hideMicroButtons" },
    { "hideProfessionsButton", "Professions", "Hides the professions button, which 1.x did not have. Professions open from the spellbook.", parent = "hideMicroButtons" },
    { "hideMicroAchievements", "Achievements", "Hides the achievements button.", parent = "hideMicroButtons" },
    { "hideMicroQuestLog", "Quest log", "Hides the quest log button.", parent = "hideMicroButtons" },
    { "hideMicroLegacy", "Legacy", "Hides the legacy button.", parent = "hideMicroButtons" },
    { "hideMicroWorldMap", "World map", "Hides the world map button.", parent = "hideMicroButtons" },
    { "hideMicroGuild", "Guild", "Hides the guild button.", parent = "hideMicroButtons" },
    { "hideMicroGroupFinder", "Group finder", "Hides the group finder button.", parent = "hideMicroButtons" },
    { "hideMicroCollections", "Collections", "Hides the collections button.", parent = "hideMicroButtons" },
    { "lfgMinimapButton", "Group finder on the minimap", "With the group finder button hidden, Classic's eye button on the minimap opens it.", parent = "hideMicroGroupFinder", search = "lfg eye dungeon" },
    { "showGroupFinderButton", "Show: always", "Always shown, or only while the mouse is over the minimap.", parent = "lfgMinimapButton", radio = "groupFinderButtonShow", drop = true },
    { "hoverGroupFinderButton", "Show: on hover", "Always shown, or only while the mouse is over the minimap.", parent = "lfgMinimapButton", radio = "groupFinderButtonShow", drop = true },
    { "hideMicroHelp", "Help", "Hides the help button.", parent = "hideMicroButtons" },
    { "hideMicroGameMenu", "Game menu", "Hides the game menu button; Escape still opens the game menu.", parent = "hideMicroButtons" },
    { "hideStanceBar", "Hide stance bar", "Hides the stance, form and aura buttons on the classic bar.", parent = "classicBar", search = "forms auras shapeshift" },
    { "classicBarSize", "Classic-sized bars", "The classic bar at 1.x's size: 36 px buttons instead of the game's 45.", parent = "classicBar", search = "small size 36 45 game" },
    { "oneBar", "One bar", "The band ends after the twelve main slots. Bar 3, the micro menu and the bags stay where edit mode puts them.", parent = "classicBar" },
    { "eraBagSize", "Classic-sized bag slots", "Bag slots at Classic Era's size (37 px, 5 apart) on Era's own bag art. The band grows to fit.", parent = "classicBar", search = "bags big large 37" },
    { "reagentBagSlot", "Reagent bag: full slot", "The reagent bag in a full slot beside the bags, as on WoW Forever's own bar, with the key ring past it.", parent = "classicBar", radio = "reagentBag" },
    { "reagentBagRound", "Reagent bag: round button", "A small round reagent bag between the key ring and the last bag; the bag row keeps its 1.x length.", parent = "classicBar", radio = "reagentBag" },
    { "reagentBagHover", "Reagent bag: round on hover", "The round reagent bag shows only while the mouse is over the bags or the key ring, so the row reads as 1.x.", parent = "classicBar", radio = "reagentBag" },
    { "hideLatencyBar", "Hide latency bar", "Takes the old latency bar (green, yellow or red by your connection) off the band. The key ring closes up.", parent = "classicBar" },
    { "hideKeyRing", "Hide key ring", "Takes the key ring off the band. The latency bar closes up.", parent = "classicBar" },
    { "hideBagsArt", "Hide bags bar art", "The bags' own run of band art goes, on the bar or moved off it. The bag buttons stay. Separate from Action Bar 1's Hide Bar Art.", parent = "classicBar" },
    { "hideMicroArt", "Hide micro menu bar art", "The micro menu's own run of band art goes, on the bar or moved off it. The buttons stay. Separate from Action Bar 1's Hide Bar Art.", parent = "classicBar" },
    { "gryphonsOverBars", "Gryphons over bars", "The gryphons stand in front of the action buttons, so bars 2 and 3 run under them. Off, the bars cover the gryphons, as 1.x drew them.", parent = "classicBar" },
    { "bagsAboveRow", "Bags above bag buttons", "Opened bags stand above the bag buttons and follow them. Off, they open at the bottom right.", parent = "classicBar" },
    { "hideExtraBars", "Hide bars 6 to 8", "1.x had five bars. Bars 6 to 8 fade out and ignore clicks; their keybinds still work." },

    { "unitFrames", "Unit frames", "Player, target, focus, target of target, pet and party frames in the 1.x art. Off takes full effect after a reload.", group = "Unit frames" },
    { "unitFramePlayer", "Player", "The player frame in the old art.", parent = "unitFrames" },
    { "unitFrameTarget", "Target", "The target and target of target frames in the old art.", parent = "unitFrames" },
    { "unitFrameFocus", "Focus", "The focus frame in the old art.", parent = "unitFrames" },
    { "unitFramePet", "Pet", "The pet frame in the old art.", parent = "unitFrames" },
    { "unitFrameParty", "Party", "The party frames in the old art.", parent = "unitFrames" },
    { "classColorNames", "Class colored name box", "Players' name boxes on the player, target and focus frames take their class color.", parent = "unitFrames", search = "header background" },
    { "classColorHealth", "Class colored health", "Players' health bars take their class color instead of green.", parent = "unitFrames" },
    { "classicStatusFont", "Classic bar text font", "Health and power numbers in Classic Era's font: Arial Narrow 14, outlined.", parent = "unitFrames", search = "numbers text size arial" },
    { "barUnitTips", "Unit tooltip on bars", "Hovering a unit frame's health or power bar shows the unit's tooltip, as the portrait does.", parent = "unitFrames" },
    { "hoverBothNumbers", "Both numbers on hover", "With status text on Numeric or Percentage, hovering a bar shows the percentage and the value together.", parent = "unitFrames" },
    { "thickHealth", "Thick health bars", "A taller health bar on the player, target and focus frames.", parent = "unitFrames", search = "big bigger fat health" },
    { "thickHealthName", "Style: over the name", "The health bar takes the name box; the name moves over the frame and mana stays.", parent = "thickHealth", radio = "thickHealthStyle", drop = true },
    { "thickHealthPlayer", "Frames: Player", "The frames with the thick health bar.", parent = "thickHealth", checks = "thickHealthFrames", drop = true },
    { "thickHealthTarget", "Frames: Target", "The frames with the thick health bar.", parent = "thickHealth", checks = "thickHealthFrames", drop = true },
    { "thickHealthFocus", "Frames: Focus", "The frames with the thick health bar.", parent = "thickHealth", checks = "thickHealthFrames", drop = true },
    { "thickHealthMana", "Style: over the mana", "The health bar takes the mana slot; the mana bar is hidden.", parent = "thickHealth", radio = "thickHealthStyle", drop = true },
    { "eliteFrames", "Elite frames", "The gold dragon of an elite on the frames picked below.", parent = "unitFrames" },
    { "eliteFramePlayer", "Player", "Around your own portrait.", parent = "eliteFrames" },
    { "eliteFrameTarget", "Target", "On every target, not only elites; rares get the rare elite dragon.", parent = "eliteFrames" },
    { "eliteFrameFocus", "Focus", "On every focus, not only elites; rares get the rare elite dragon.", parent = "eliteFrames" },
    { "castBars", "Cast bars", "The 1.x cast bar border, spark and colors on player, pet, target, focus and boss bars." },
    { "castBarShake", "Shake on interrupt", "The game's shake when a cast is interrupted. Off: the bar holds red, then fades, as in classic.", parent = "castBars" },
    { "swingTimers", "Swing timers", "The game's swing timers in the 1.x cast bar's look, with a colour per hand.", search = "melee ranged auto attack" },
    { "resourceDisplay", "Personal resource display", "The game's personal resource display as 1.x nameplates: the old fill in the plate's border.", search = "prd health power under character" },
    { "comboPoints", "Combo points", "Five orbs down the target portrait's right side, as rogues and cat druids saw them in 1.x." },
    { "mirrorTimers", "Breath and fatigue bars", "The breath, fatigue and feign death timers in the old cast bar style." },
    { "hideBuffArrow", "Hide buff arrow", "The arrow that folds the buffs away shows only under the mouse." },

    { "namePlates", "Nameplates", "The 1.x plate: rounded border with the level, the name above, the cast bar below. Off takes full effect after a reload.", group = "Nameplates" },
    { "classColorPlates", "Class colors", "Players' plates take their class color.", parent = "namePlates" },
    { "fullPlates", "Always full plates", "Friendly players, NPCs and minor mobs get the full plate, not the game's simplified one." },
    { "hideLastNames", "Hide last names", "Turns off every surname setting, so only first names show. The game's own box stays in step." },

    { "gameMenu", "Game menu and dialogs", "The Escape menu, pop-up boxes, edit mode, quick keybind, chat settings, color picker and report box in the old dialog look.", group = "Dialogs" },
    { "settingsPanel", "Settings window", "The game's settings window with the look of today's Classic Era client: its frame, tabs, category bars, check boxes, sliders and drop downs." },
    { "lootWindow", "Loot window", "The 1.x loot window: the loot icon in its ring, old name boxes per row and a pager at the foot. Off takes full effect after a reload.", search = "loot frame" },
    { "lootRoll", "Loot rolls", "Need and greed boxes as in 1.x: dice for need, coin for greed, a red X to pass." },

    { "characterSheet", "Character sheet", "The 1.x character window. The arrow at its bottom right opens the TBC side panel with stats and the equipment manager.", group = "Character and spells" },
    { "statPanes", "Stat drop downs", "Two TBC stat boxes under the model, each with a drop down: General, Attributes, Melee, Ranged, Spell, Defense or Resistances.", parent = "characterSheet" },
    { "equipmentQuickButton", "Equipment manager button", "A small button above the gloves slot that opens the equipment manager. The side panel's arrow reaches it too.", parent = "characterSheet" },
    { "weaponSkillDetail", "Weapon skill detail", "Under a weapon skill on the Skills tab, WoW Forever's breakdown: hit and crit against an equal-level enemy and a raid boss, and glancing blows.", parent = "characterSheet" },
    { "spellBook", "Spellbook", "The 1.x parchment spellbook: twelve spells a page, school tabs down the right, page arrows and a pet tab." },
    { "spellBookTopRank", "Top ranks only", "Lists only the highest rank of each spell. Off, every rank shows, as in 1.x.", parent = "spellBook" },
    { "spellBookSearch", "Search box", "A search box on the spellbook that lists every known spell matching the words.", parent = "spellBook" },
    { "talents", "Talent window", "The old talent window: one tree at a time, tree tabs along the foot, rank plates and arrows. Click to stage a point, Learn to commit." },

    { "professionsBook", "Professions book", "The professions overview as the old two-page book, each profession with its emblem, rank bar and spells.", group = "Professions" },
    { "profBookBig", "Full size book", "The professions book at its full two-page size instead of the spellbook's. The button beside its close button switches it too.", parent = "professionsBook", search = "big large popout" },
    { "tradeSkill", "Profession windows", "A profession's window as the old trade skill window: recipes by difficulty color above, the chosen recipe and its reagents below." },
    { "tradeSkillSearch", "Recipe search", "A search box on a profession's window that lists only the matching recipes.", parent = "tradeSkill" },
    { "trainer", "Trainer window", "A trainer's window as the old one: services in green, red and gray, what they need and cost, and Train." },

    { "questLog", "Quest log", "The 1.x quest log in its own window. The quest button, key and tracker clicks open it instead of the map.", group = "Quests" },
    { "questLogDual", "Double pane", "The wider 3.x quest log: the list on the left, the quest on parchment beside it. Off is the 1.x single pane.", parent = "questLog" },
    { "questLevels", "Quest levels", "Each quest's level in front of its name on the map, in the tracker and in the quest log. This is the game's Show Quest Levels setting.", search = "level map filter" },
    { "questTracker", "Quest tracker", "Old stone headers and small collapse buttons on the objective tracker." },
    { "hideObjectiveTracker", "Hide objective tracker", "Hides the game's objective tracker, for a quest tracker from another addon. Its quest item buttons go with it. Changes wait for the end of a fight.", search = "quest watch objectives" },
    { "worldMap", "World map", "The old metal border, title strip and corner close button on the world map. Off takes full effect after a reload.", group = "Map" },
    { "mapNavBar", "Map navigation bar", "The game's own map layout: its navigation bar row, filter and pin buttons and coordinates. Off: Classic Era's map.", parent = "worldMap" },
    { "hideMapQuestButton", "Hide map quest button", "Hides the button at the map's bottom right that opens its quest list, for players who use the separate quest log.", search = "quest list toggle side panel expand" },
    { "questMapPane", "Map quest list", "The map's quest list in the quest log's style: dark list, plus and minus headers, 1.x colors, details on parchment." },
    { "mapFade", "Fade map while moving", "The map dims while you move. This is the game's own setting." },
    { "mapUnlocked", "Unlock map", "Drag the world map anywhere by its title bar, no edit mode needed. The lock at the map's top right switches this too.", search = "move map lock" },

    { "whoList", "Who list", "The 1.x Who tab on the social window, in sortable columns. /who answers into it.", group = "Social" },
    { "guildRoster", "Guild roster", "The 1.x guild tab: member count, guild message and the roster in sortable columns." },
    { "groupFinder", "Group finder", "The group finder at the social window's size, with the Who tab's side tabs. Needs Window frames on." },

    { "bags", "Bag windows", "The 1.x bag windows: bag art with the portrait ring, the money strip and the old slots. Off takes full effect after a reload.", group = "Bags" },
    { "oneBag", "One bag", "All bags open as one window in the old art. This is the game's Combine Bags setting." },
    { "bagsBesideBars", "Bags clear side bars", "Opened bags start left of the side action bars instead of covering them." },

    { "minimap", "Minimap", "The round 1.x minimap with the zone name on top and the old tracking, zoom, mail and clock spots.", group = "Minimap and chat" },
    { "classicTracking", "Tracking icon", "Your tracking spell's icon in a ring on the minimap, as in classic. Right-click it to stop tracking.", parent = "minimap" },
    { "showMinimapZone", "Zone name: shown", SHOW_TIP, parent = "minimap", radio = "minimapZoneShow", drop = true },
    { "hoverMinimapZone", "Zone name: on hover", SHOW_TIP, parent = "minimap", radio = "minimapZoneShow", drop = true },
    { "hideMinimapZone", "Zone name: hidden", SHOW_TIP, parent = "minimap", radio = "minimapZoneShow", drop = true },
    { "showMinimapTracking", "Tracking: shown", SHOW_TIP, parent = "minimap", radio = "minimapTrackingShow", drop = true },
    { "hoverMinimapTracking", "Tracking: on hover", SHOW_TIP, parent = "minimap", radio = "minimapTrackingShow", drop = true },
    { "hideMinimapTracking", "Tracking: hidden", SHOW_TIP, parent = "minimap", radio = "minimapTrackingShow", drop = true },
    { "showMinimapMail", "Mail icon: shown", SHOW_TIP, parent = "minimap", radio = "minimapMailShow", drop = true },
    { "hoverMinimapMail", "Mail icon: on hover", SHOW_TIP, parent = "minimap", radio = "minimapMailShow", drop = true },
    { "hideMinimapMail", "Mail icon: hidden", SHOW_TIP, parent = "minimap", radio = "minimapMailShow", drop = true },
    { "showMinimapZoomIn", "Zoom in: shown", SHOW_TIP, parent = "minimap", radio = "minimapZoomInShow", drop = true },
    { "hoverMinimapZoomIn", "Zoom in: on hover", SHOW_TIP, parent = "minimap", radio = "minimapZoomInShow", drop = true },
    { "hideMinimapZoomIn", "Zoom in: hidden", SHOW_TIP, parent = "minimap", radio = "minimapZoomInShow", drop = true },
    { "showMinimapZoomOut", "Zoom out: shown", SHOW_TIP, parent = "minimap", radio = "minimapZoomOutShow", drop = true },
    { "hoverMinimapZoomOut", "Zoom out: on hover", SHOW_TIP, parent = "minimap", radio = "minimapZoomOutShow", drop = true },
    { "hideMinimapZoomOut", "Zoom out: hidden", SHOW_TIP, parent = "minimap", radio = "minimapZoomOutShow", drop = true },
    { "showMinimapClock", "Clock: shown", SHOW_TIP, parent = "minimap", radio = "minimapClockShow", drop = true },
    { "hoverMinimapClock", "Clock: on hover", SHOW_TIP, parent = "minimap", radio = "minimapClockShow", drop = true },
    { "hideMinimapClock", "Clock: hidden", SHOW_TIP, parent = "minimap", radio = "minimapClockShow", drop = true },
    { "showMinimapDiel", "Day and night: shown", SHOW_TIP, parent = "minimap", radio = "minimapDielShow", drop = true },
    { "hoverMinimapDiel", "Day and night: on hover", SHOW_TIP, parent = "minimap", radio = "minimapDielShow", drop = true },
    { "hideMinimapDiel", "Day and night: hidden", SHOW_TIP, parent = "minimap", radio = "minimapDielShow", drop = true },
    { "showMinimapCalendar", "Calendar: shown", SHOW_TIP, parent = "minimap", radio = "minimapCalendarShow", drop = true, search = "date events" },
    { "hoverMinimapCalendar", "Calendar: on hover", SHOW_TIP, parent = "minimap", radio = "minimapCalendarShow", drop = true },
    { "hideMinimapCalendar", "Calendar: hidden", SHOW_TIP, parent = "minimap", radio = "minimapCalendarShow", drop = true },
    { "showMinimapCoords", "Coordinates: shown", SHOW_TIP, parent = "minimap", radio = "minimapCoordsShow", drop = true, search = "coords position" },
    { "hoverMinimapCoords", "Coordinates: on hover", SHOW_TIP, parent = "minimap", radio = "minimapCoordsShow", drop = true },
    { "hideMinimapCoords", "Coordinates: hidden", SHOW_TIP, parent = "minimap", radio = "minimapCoordsShow", drop = true },
    { "hideMinimapBorder", "Hide minimap border", "Takes the ring off the minimap.", parent = "minimap", search = "ring frame" },
    { "hideMinimapHeader", "Hide minimap header", "Takes the bar with the zone name off the top of the minimap. The name stays.", parent = "minimap", search = "zone bar top" },
    { "hideButtonBorders", "Hide button borders", "Takes the rings off the minimap's buttons: tracking, mail, clock, day and night, and other addons' buttons.", parent = "minimap", search = "ring icons" },
    { "calendarZone", "Calendar spot: by the zone name", "Where the calendar sits. By the zone name is a small square with the date; behind day and night, clicking the icon opens it.", parent = "minimap", radio = "calendarSpot", drop = true, search = "square banner" },
    { "calendarRing", "Calendar spot: on the ring", "Where the calendar sits. By the zone name is a small square with the date; behind day and night, clicking the icon opens it.", parent = "minimap", radio = "calendarSpot", drop = true },
    { "calendarBehind", "Calendar spot: behind day and night", "Where the calendar sits. By the zone name is a small square with the date; behind day and night, clicking the icon opens it.", parent = "minimap", radio = "calendarSpot", drop = true },
    { "minimapButton", "Options button", "A button on the minimap ring that opens these options. Drag it around the ring." },
    { "showOptionsButton", "Show: always", "Always shown, or only while the mouse is over the minimap.", parent = "minimapButton", radio = "optionsButtonShow", drop = true },
    { "hoverOptionsButton", "Show: on hover", "Always shown, or only while the mouse is over the minimap.", parent = "minimapButton", radio = "optionsButtonShow", drop = true },
    { "minimapCollector", "Collect addon buttons", "The other addons' minimap buttons gathered behind one button on the ring; click it for a grid of them. Drag it around the ring.", search = "minimap icons bag" },
    { "showAddonBag", "Show: always", "Always shown, or only while the mouse is over the minimap.", parent = "minimapCollector", radio = "addonBagShow", drop = true },
    { "hoverAddonBag", "Show: on hover", "Always shown, or only while the mouse is over the minimap.", parent = "minimapCollector", radio = "addonBagShow", drop = true },
    { "classicChat", "Chat buttons", "The chat buttons in one column down the chat's left, as in 1.x. The scroll bar goes; arrows and the wheel scroll." },
    { "hideChatButtons", "Hide chat buttons", "Takes every button off the left of the chat, so it can sit at the screen's edge. The mouse wheel scrolls; Shift with it jumps to the top or bottom.", parent = "classicChat", search = "flush left edge" },
    { "chatScrollBar", "Chat scroll bar", "WoW Forever's scroll bar on the right of the chat. 1.x had none.", parent = "classicChat", search = "scrollbar right" },

    { "gameDamageNumbers", "Damage numbers", "The game's floating damage over your targets. This is the game's own setting.", group = "Other" },
    { "damageMeter", "Damage meter", "The game's damage meter windows in the 1.x tooltip rim.", search = "dps meter recount details" },
    { "welcomeNote", "Welcome note", "The welcome note on a character's first login with the addon." },
    { "addonMessages", "Addon messages", "The addon's lines in chat at login: what's new after an update and notes such as the one about the bars. Off keeps chat quiet.", search = "chat login lines quiet" },
}

-- Radio rows: key -> its group's keys (Core ToggleChanged keeps exactly one on).
ns.TOGGLE_RADIO = {}
do
    local groups = {}
    for _, entry in ipairs(ns.TOGGLES) do
        local name = entry.radio
        if name then
            local group = groups[name] or {}
            groups[name] = group
            group[#group + 1] = entry[1]
            ns.TOGGLE_RADIO[entry[1]] = group
        end
    end
end
