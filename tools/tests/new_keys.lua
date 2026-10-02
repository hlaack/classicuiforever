-- What a player updating sees, one line per settings key added after the defaults lock (tools/tests/defaults_test.lua
-- refuses a new key without one). Kept as before: name where (Options/Layout.lua OLD_LOOK, a dbVersion migration).
-- The same for everyone: why that is fine (opt-in and off by default, or nothing on screen).
-- luacheck: std lua54
return {
    hideThreatGlow = "same for everyone: opt-in, off by default",
    plainQuestItems = "same for everyone: opt-in, off by default",
    plainNumbers = "same for everyone: mirrors the game's own setting, which only the player changes",
    hideMicroShop = "same for everyone: opt-in, off by default; the classic bar never shows the shop",
    classicFonts = "on for everyone, as the damage meter was: a new restyle, text as Classic Era draws it",
    platesOneSize = "same for everyone: opt-in, off by default; game settings written only on the click",
    themeFlat = "same for everyone: opt-in, off by default",
    flatBars = "same for everyone: a part of Flat colour, which is off by default",
    flatCharacter = "same for everyone: a part of Flat colour, which is off by default",
    flatSpellbook = "same for everyone: a part of Flat colour, which is off by default",
    flatWindows = "same for everyone: a part of Flat colour, which is off by default",
    flatHideBorders = "same for everyone: an option of Flat color, which is off by default",
    themeDarkness = "same for everyone: its default is the Dark theme's one shade, unchanged",
}
