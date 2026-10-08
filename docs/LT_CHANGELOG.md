# Legacy Talents Changelog

All notable changes to the Classic Legacy Talents window in ClassicUI Forever are documented here.

## [Unreleased]

### Added
- Classic Legacy window, Phase 4: the window is a piece of its own, **Legacy window** under Character and spells in the options. On by default.
  - The Legacy button, its minimap icon and the game's Legacy key open the classic window instead of the game's. Turned off, they open the game's window again after a reload.
  - **Background** under Legacy window picks what stands behind the trees: each tree's Era talent art (the default), or parchment, marble or stone for all three.
  - The window can be moved in ClassicUI Forever Windows (edit mode), as the talents window.
  - With the gamepad interface on at login, the game's Legacy window stays.
- Classic Legacy window, Phase 3: a Reward Track page, the third of the window's page tabs.
  - A bar shows the way from the last reward reached to the next, with the Legacy Points needed under it.
  - Each milestone of the track is a heading with its rewards below in Classic's quest reward buttons, two to a row, as in the quest log. Rewards reached are lit; the rest are grey.
  - The page opens at the next reward. Hover a reward for its tooltip; shift-click an item or spell reward to link it in chat.
  - An account with no Legacy Point yet sees a note in place of the track.
- Classic Legacy window, Phase 2: a Challenges page, in the shape of Classic Era's trade skill window.
  - The challenge categories are folding headers, each showing how many of its challenges are done, with an All button to fold or unfold every one.
  - Each challenge shows the Legacy Points it gives. Completed ones are grey.
  - A Filter drop-down shows or hides completed and incomplete challenges.
  - The picked challenge appears below the list: its icon, points, completion date, description and steps, with a progress bar for a counted step. The pane scrolls when the text runs long.
  - Shift-click a challenge to link it in chat.
- The window's pages sit down its right edge on the spellbook's skill line tabs: Legacy Tree, Challenges and Reward Track.
- On the Challenges and Reward Track pages, the bar under the title shows the Legacy Points earned out of all that the challenges give.
- Classic Legacy window, Phase 1: the Legacy trees in the old talent window. Professions, Adventure and Resourcefulness are its foot tabs, each on an Era talent background (Druid Restoration, Hunter Beast Mastery and Warrior Protection). Perks show as classic talent buttons with rank plates, branches and arrows. Click to stage a point, right-click to take a staged point back, Apply Changes to keep them, and the undo button to drop them. Legacy Points left show at the foot.
- `/fcui legacy` opens and closes the classic Legacy window. With Legacy window turned off, it says so in chat.
- An account with no Legacy Point yet sees a note in the window instead of an empty tree.
- The window's text in English, German, Spanish, French and Italian, using the game's own wording for the title, tabs, tree names and filters where the client has it.
- This changelog, to track the Legacy work apart from the add-on's own changelog.

### Changed
- The talents window's tree drawing and data reading are now shared code that the Legacy window also uses. The talents window looks and works as before.
- The spellbook's skill line tabs and the trade skill window's list colors and folding are now shared code that the Legacy window also uses. The spellbook and trade skill window look and work as before.
- The quest log's reward buttons are now shared code that the Legacy window also uses. The quest log looks and works as before.

### Fixed
- The Challenges and Reward Track pages no longer cover the bottom of the portrait, and leave a gap under the Legacy Points bar. Their stone now starts under Classic Era's class trainer divider bar instead of a bare edge.
- A window opened beside the classic Legacy window no longer covers its page tabs: the next window stands clear of them, as beside the spellbook.

### Known issues
- Nested challenge categories are listed one after another, not indented under their parent.
- A challenge with many steps lists them all; there is no search box yet.
- A Legacy tree wider than four columns would be cut off at the window's right edge.
- A perk where you choose between options shows only its first option.
- The classic Legacy window is not available with the gamepad interface on.

## Changes to the add-on's existing files

The Legacy window reuses the add-on's own windows and art instead of copying them, which the convention checker requires (rules DUP and DUPFN). Where a piece it needed lived inside an existing file, that piece moved into a shared helper and the original file now calls the helper. Each change below is meant to leave the original window looking and working as before. The "Checked in game" line says how far that was confirmed on the beta.

### Moved into new shared helpers
- **Skills/Talents.lua** and **Skills/TalentsTree.lua**: the talent window's frame, tree view, talent buttons, branches and arrows, tooltip, foot (undo, points left, Apply Changes) and foot tabs moved to **UI/TalentWindow.lua** (`ns.TalentWindow`, `ns.DrawTalentTab`, `ns.TalentWindowShown`, `ns.TalentButtons`). The tree reader moved to **UI/TraitTree.lua** (`ns.ReadTraitTree`). Talents.lua keeps everything that is the talents window's own: class backgrounds, inspect, the key binding, the micro button and the module. Checked in game: the talents window looks and works as before.
  - Merging 0.20.3: the author's shift-click into a macro (#124) changed the talent button's click, which had moved; it was carried over unchanged into `Button_OnClick` in UI/TalentWindow.lua, so Legacy perks get it too. **tools/tests/spells_window_test.lua** now reads that file instead of Skills/Talents.lua. Checked in game: a talent shift-clicked into an open macro gives its name.
- **Spells/SpellBook.lua**: the skill line tab down the book's right edge (`CreateSkillTab`) now builds its art with **UI/SkillLineTab.lua** (`ns.SkillLineTab`). The tab's scripts and id stay in SpellBook.lua. Checked in game: the side tabs work as before.
- **Quest/QuestLogDetail.lua**: the 1.x quest reward button (`RewardButton`) now comes from **UI/RewardSlot.lua** (`ns.RewardSlot`); the quest log still sets its scale, scripts and contents. Checked in game: the quest log's rewards look and work as before.
- **Windows/DamageMeter.lua**: the class trainer's divider bar pieces (`BarPiece`) now come from **UI/DividerBar.lua** (`ns.DividerBar`); the meter still places them. Checked in game: the divider looks as before.

### Additions to existing shared code
- **Skills/SkillShell.lua**: `SkillList.Paint(row, picked, color)` (a list row's picked and unpicked colors) and `SkillList.Fold(line, collapsed)` (a header's fold on click), both taken from Skills/TradeSkill.lua. `panel.tabStones` (the stone strips over the All tab's top and right side) is now exposed so the Legacy window's divider can take their place. No change to how the trade skill or trainer window lays them out. Checked in game: the trade skill window's list works as before.
- **Skills/TradeSkill.lua**: its row colors and header folding now call `SkillList.Paint` and `SkillList.Fold`. Checked in game.
- **UI/Windows.lua**: `ns.SetSlotWidth(frame, width)` keeps a window's slot width in the window manager's own weak table. It replaces the spellbook's `fcuiSlotWidth` field, which the FRAMEFIELD rule counts. The spellbook calls it with `ns.SIDE_TAB_SLOT` (392, as before), and the Legacy window uses the same width so a window beside it clears its side tabs. Checked in game: windows stand side by side as before.
- **UI/TalentWindow.lua**: `ns.RimBar(parent, height, color)` (the skill bars' rimmed bar, filled when given a color) and `ns.TalentTreeShown(frame, shown)` (the tree swapped out for another page).

- **UI/TalentWindow.lua**: a tree's background can be one plain backdrop (parchment, marble or stone) instead of Era's art; the talents window still draws its class art.
- **UI/WindowKey.lua** (new): `ns.WindowKey(name, binding, press, escName)`, a game key binding that opens a window of ours. The Legacy window uses it; the talents, quest log, guild and professions windows still bind their own keys, and could move to it later.

### Other existing files
- **Core/Defaults.lua**: `legacyWindow` (on) and `legacyBackground` ("era") in the defaults, `legacyWindow` in the module order after `talents`, and a reload notice for turning it off (the Legacy button's click is handed back, as the talents button's).
- **Options/Toggles.lua**: the Legacy window row under Character and spells, after Talents, on WoW Forever only. It goes in through `FOREVER_ROWS`, beside the existing `RETAIL_ROWS`, and the one loop that adds them now takes whichever table the client needs.
- **Options/OptionsWindow.lua**: the Background drop-down under Legacy window.
- **Core/Profiles.lua**: `legacyBackground` is kept per profile, as the damage meter's background.
- **UI/WindowList.lua**: the Legacy window's entry, so edit mode can move it.
- **tools/tests/new_keys.lua** and **tools/tests/defaults_lock.lua**: the two new settings (the lock is written by `lua tools/tests/defaults_test.lua --write`).
- **CHANGELOG.md**: an Unreleased entry for the Legacy window. What's New and the version number are left for the release.
- **Options/Options.lua**: `/fcui legacy` opens the classic Legacy window and is listed in `/fcui help`.
- **ClassicUIForever.toc**: the new UI, Legacy and `Locales/*_Legacy.lua` files.
- **.luacheckrc**: read globals the Legacy window uses: the achievement API, `FormatShortDate`, `C_MajorFactions`, `RenownRewardUtil` and `C_MountJournal`.
- **tools/CONVENTIONS.md**: the Legacy folder in the folder map, and the new shared helpers in the helper table.
- **.gitignore**: Claude Code's own files (`CLAUDE.md`, `.claude/`, `.mcp.json`) are kept out of the repository.
