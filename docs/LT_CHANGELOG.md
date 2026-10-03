# Legacy Talents Changelog

All notable changes to the Classic Legacy Talents window in ClassicUI Forever are documented here.

## [Unreleased]

### Added
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
- `/fcui legacy` opens and closes the classic Legacy window. The Legacy button and the minimap icon still open the game's own window until a later phase.
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
- Not yet checked in game: spending and taking back points, Apply Changes and undo, and opening the window in a fight. The window and the trees' layout were checked on the beta.
- Not yet checked in game: the Challenges list and detail updating as challenges progress or are earned.
- Not yet checked in game: the Reward Track page opening at the next reward once some are earned. Its layout, reward names, icons and tooltips were checked on the beta.
- Nested challenge categories are listed one after another, not indented under their parent.
- A challenge with many steps lists them all; there is no search box yet.
- A Legacy tree wider than four columns would be cut off at the window's right edge.
- A perk where you choose between options shows only its first option.
- The classic Legacy window is not available with the gamepad interface on.
