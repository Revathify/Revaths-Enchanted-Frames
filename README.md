# Revath's Enchanted Frames

<p align="center"><img src="RevathsEnchantedFrames/Media/RevathsEnchantedFrames.png" alt="Revath's Enchanted Frames" width="360"></p>

Revath's Enchanted Frames is a modular World of Warcraft Retail addon suite that combines a customizable mailbox replacement, an advanced macro workshop, account-wide item-count tooltips, and a personal weekly planner under one shared parent addon and one Blizzard Settings category.

## Modules

- **Revath's Enchanted Frames** — shared parent, suite metadata, author information, and centralized Blizzard Settings pages.
- **Revath's Enchanted Mailbox** — inbox tools, New Mail editor, contacts, quick attachments, alt tracking, Modern and Classic skins, palettes, fonts, opacity, and scaling.
- **Revath's Enchanted Macros** — separate account and character macro libraries, curated class/spec templates, icon picker, drag-to-action-bar, syntax suggestions, usable-item suggestions, and Modern or Classic skins.
- **Revath's Enchanted Tooltips** — account-wide bag, bank, and Warband-bank item totals with Shift details per character.
- **Revath's Enchanted Weekly Planner** — personal goals for each character, automatic weekly resets, and an unfinished-only view.

## Release versions

The suite uses **Major.Minor.Hotfix**, starting with **4.1.0** for the expanded suite with the Weekly Planner.

- **Major**: a new frame/module or a major suite redesign (for example, `5.0.0`).
- **Minor**: new features within existing frames (for example, `4.2.0`).
- **Hotfix**: fixes to existing behavior (for example, `4.1.1`).

Before publishing, choose the appropriate version and update all five active addon manifests together. A major change resets Minor and Hotfix to zero; a minor change resets Hotfix to zero. Pushing to `main` builds and publishes that exact version. The release workflow never increments it automatically, and an already-published version is skipped rather than replaced.

## Install or upgrade

1. Extract all five folders into `_retail_/Interface/AddOns/`, replacing the existing module folders when prompted:
   - `RevathsEnchantedFrames`
   - `RevathsMailbox`
   - `RevathsMacro`
   - `RevathsMailboxTooltipHelper`
   - `RevathsWeeklyPlanner`
2. If upgrading from a release with Auction House support, disable or remove the old `RevathsAuctionHouse` folder from `Interface/AddOns`. That module is now obsolete and is excluded from releases.
3. Restart WoW or type `/reload`.

The existing child modules keep their technical folder IDs so WoW automatically loads your existing saved-variable files. Existing settings, macro preferences, and tracked item data migrate without a manual reset.

## Settings and commands

Open **Options → AddOns → Revath's Enchanted Frames** for the suite overview and Mailbox, Macros, Tooltips, and Weekly Planner subpages.

- `/ref` or `/enchantedframes` opens the shared addon settings.
- `/rmail` or `/revathsmailbox` opens the mailbox while a mailbox NPC/object is active.
- `/rmacro` or `/macroworkshop` opens Revath's Enchanted Macros.
- `/rweekly` or `/rplanner` opens the Weekly Planner.

The Weekly Planner also has a minimap icon. Click it to open or close the planner, or drag it around the minimap; its position is saved.

## Weekly Planner

Log into a character with the module enabled to add it to the roster, then open `/rweekly`. Select a character and type your own weekly goal, or choose a Raid, Dungeons, or Professions starter. Click a goal to complete or uncheck it, right-click to edit its wording, or use its × button to remove it. **Undo remove** restores the last deleted goal. Each character has separate goals and progress, and you can edit an offline alt's checklist. **Unfinished only** hides completed goals and characters; characters with no goals remain visible so you can set them up. Scroll the character or goal list for more entries. Drag the header to move the window or the bottom-right corner to resize it. Wider windows give goals more room; taller windows show more characters and goal or raid rows without changing text size. Position, dimensions, and appearance settings are saved. The Settings button opens mailbox-style Modern/Classic skin buttons and opacity/scale sliders inside the planner.

Personal goals are checked off manually. Four default goals appear automatically for every character: season raid bosses, completed M+ dungeons, tracked weekly quests, and filled Great Vault slots. Blizzard's weekly reset countdown clears completions automatically, including offline characters in the current region, while retaining the goals themselves. Resets are checked on login, when opening the planner, during edits, and once a minute while logged in. If reset timing is unavailable, progress is retained until Blizzard provides it again. The roster also imports characters saved by Enchanted Mailbox when that module is enabled. Existing goals survive when an imported alt logs in. Legacy mailbox entries without region metadata are assumed to belong to the current region; new entries record their region.

Select **Raid lockouts** to see saved raid IDs, difficulty, killed and available bosses, and remaining reset time. Blizzard supplies this data for the logged-in character; login, opening the window, and successful boss kills request a refresh. **Refresh raid data** always updates the logged-in character. Offline alts display their last saved snapshot and its capture time; log into each alt once to collect its raid details. Expired snapshots disappear using the raid's own reset time, including extended lockouts. Unfinished only hides killed boss rows. API failures or restricted data preserve the previous snapshot. Personal checklist goals remain manual and independent of raid progress. The automatic raid goal reads the current-season encounter list from Blizzard's Great Vault data and counts each boss once across difficulties. M+ progress counts current-week completed runs; its target follows the final dungeon Vault threshold. Vault progress counts the active raid, dungeon, and world/PvP rows (normally nine slots). Weekly quest progress counts weekly-tagged quests accepted while the addon is enabled, retaining turn-ins until reset; it does not discover every available weekly quest. Unavailable counters show a waiting message, and unclaimed previous-week Vault rewards are not counted as current progress. Offline alts keep their last captured counters until reset.

The planner now uses the same palette colours, panel styling, branded header, and Classic dialog/button textures as the mailbox and macro frames. Appearance preferences remain configurable on the Weekly Planner settings page.

Crest balances and earning allowances appear in an information panel below the selected character's goals. They do not count as goals or completion targets. Hover a crest for full earning details and its update time. Offline alts show their own saved balances; log into that character to refresh expired allowances.

## Compatibility

- World of Warcraft Retail / Midnight 12.1 (`Interface: 120100`)
- Optional LibSharedMedia font discovery through compatible installed addons
- No external network access from inside the game

## Author and support

Created by **Revath#2331 (Revathify)**.

Support the project at [Buy Me a Coffee](https://buymeacoffee.com/revath).

New blank macros default to Blizzard's question-mark (automatic) icon, so `#showtooltip SPELLNAME` can choose the spell icon. Existing macros and explicitly selected icons keep their choice.
