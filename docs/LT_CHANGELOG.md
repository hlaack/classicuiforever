# Legacy Talents Changelog

All notable changes to the Classic Legacy Talents window in ClassicUI Forever are documented here.

## [Unreleased]

### Added
- Classic Legacy window, Phase 1: the Legacy trees in the old talent window. Professions, Adventure and Resourcefulness are its foot tabs, each on an Era talent background (Druid Restoration, Hunter Beast Mastery and Warrior Protection). Perks show as classic talent buttons with rank plates, branches and arrows. Click to stage a point, right-click to take a staged point back, Apply Changes to keep them, and the undo button to drop them. Legacy Points left show at the foot.
- `/fcui legacy` opens and closes the classic Legacy window. The Legacy button and the minimap icon still open the game's own window until a later phase.
- An account with no Legacy Point yet sees a note in the window instead of an empty tree.
- The window's text in English, German, Spanish, French and Italian, using the game's own wording for the title and tree names where the client has it.
- Planning for the Challenges and Reward Track pages, built from the add-on's existing Classic lists and art.
- This changelog, to track the Legacy work apart from the add-on's own changelog.

### Changed
- The talents window's tree drawing and data reading are now shared code that the Legacy window also uses. The talents window looks and works as before.

### Known issues
- Not yet checked in game: spending and taking back points, Apply Changes and undo, and opening the window in a fight. The window and the trees' layout were checked on the beta.
- A Legacy tree wider than four columns would be cut off at the window's right edge.
- A perk where you choose between options shows only its first option.
- The classic Legacy window is not available with the gamepad interface on.
