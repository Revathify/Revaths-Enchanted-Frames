# Revath's Enchanted Frames

<p align="center"><img src="RevathsEnchantedFrames/Media/RevathsEnchantedFrames.png" alt="Revath's Enchanted Frames" width="360"></p>

Revath's Enchanted Frames is a modular World of Warcraft Retail addon suite combining a customizable mailbox, macro workshop, account-wide item tooltips, weekly planner, and compact whisper messenger under one shared parent addon and Blizzard Settings category.

## Modules

- **Revath's Enchanted Frames** — shared parent, suite metadata, author information, and centralized Blizzard Settings pages.
- **Revath's Enchanted Mailbox** — inbox tools, New Mail editor, contacts, quick attachments, alt tracking, Modern and Classic skins, palettes, fonts, opacity, and scaling.
- **Revath's Enchanted Macros** — separate account and character macro libraries, curated class/spec templates, icon picker, drag-to-action-bar, syntax suggestions, usable-item suggestions, and Modern or Classic skins.
- **Revath's Enchanted Tooltips** — account-wide bag, bank, and Warband-bank item totals with Shift details per character.
- **Revath's Enchanted Weekly Planner** — personal goals for each character, automatic weekly resets, and an unfinished-only view.
- **Revath's Enchanted Whispers** — compact character and Battle.net conversations, saved drafts, unread counts, notification sounds, and native WoW styling.

## Release versions

The suite uses **Major.Minor.Hotfix**, starting with **4.1.0** for the expanded suite with the Weekly Planner.

- **Major**: a new frame/module or a major suite redesign (for example, `5.0.0`).
- **Minor**: new features within existing frames (for example, `4.2.0`).
- **Hotfix**: fixes to existing behavior (for example, `4.1.1`).

Before publishing, choose the appropriate version and update all six active addon manifests together. A major change resets Minor and Hotfix to zero; a minor change resets Hotfix to zero. Local Jenkins polls `main` every two minutes, validates and packages changes, and publishes that exact version. It never increments versions automatically and never replaces an already-published release. Enchanted Whispers introduces version **5.0.0**.

## Install or upgrade

1. Extract all six folders into `_retail_/Interface/AddOns/`, replacing the existing module folders when prompted:
   - `RevathsEnchantedFrames`
   - `RevathsMailbox`
   - `RevathsMacro`
   - `RevathsMailboxTooltipHelper`
   - `RevathsWeeklyPlanner`
   - `RevathsWhispers`
2. If upgrading from a release with Auction House support, disable or remove the old `RevathsAuctionHouse` folder from `Interface/AddOns`. That module is now obsolete and is excluded from releases.
3. Restart WoW or type `/reload`.

The existing child modules keep their technical folder IDs so WoW automatically loads your existing saved-variable files. Existing settings, macro preferences, and tracked item data migrate without a manual reset.

## Settings and commands

Open **Options → AddOns → Revath's Enchanted Frames** for the suite overview and Mailbox, Macros, Tooltips, Weekly Planner, and Whispers subpages.

- `/ref` or `/enchantedframes` opens the shared addon settings.
- `/rmail` or `/revathsmailbox` opens the mailbox while a mailbox NPC/object is active.
- `/rmacro` or `/macroworkshop` opens Revath's Enchanted Macros.
- `/rweekly` or `/rplanner` opens the Weekly Planner.
- `/rwhisper` or `/rwhispers` opens Enchanted Whispers; `/rwhisper Name-Realm` starts a character conversation.

The Weekly Planner also has a minimap icon. Click it to open or close the planner, or drag it around the minimap; its position is saved.

## Weekly Planner

Log into a character with the module enabled to add it to the roster, then open `/rweekly`. Select a character and type your own weekly goal, or choose a Raid, Dungeons, or Professions starter. Click a goal to complete or uncheck it, right-click to edit its wording, or use its × button to remove it. **Undo remove** restores the last deleted goal. Each character has separate goals and progress, and you can edit an offline alt's checklist. **Unfinished only** hides completed goals and characters; characters with no goals remain visible so you can set them up. Scroll the character or goal list for more entries. Drag the header to move the window or the bottom-right corner to resize it. Wider windows give goals more room; taller windows show more characters and goal or raid rows without changing text size. Position, dimensions, and appearance settings are saved. The Settings button opens mailbox-style Modern/Classic skin buttons and opacity/scale sliders inside the planner.

Personal goals are checked off manually. Four default goals appear automatically for every character: season raid bosses, completed M+ dungeons, tracked weekly quests, and filled Great Vault slots. Blizzard's weekly reset countdown clears completions automatically, including offline characters in the current region, while retaining the goals themselves. Resets are checked on login, when opening the planner, during edits, and once a minute while logged in. If reset timing is unavailable, progress is retained until Blizzard provides it again. The roster also imports characters saved by Enchanted Mailbox when that module is enabled. Existing goals survive when an imported alt logs in. Legacy mailbox entries without region metadata are assumed to belong to the current region; new entries record their region.

Select **Raid lockouts** to see saved raid IDs, difficulty, killed and available bosses, and remaining reset time. Blizzard supplies this data for the logged-in character; login, opening the window, and successful boss kills request a refresh. **Refresh raid data** always updates the logged-in character. Offline alts display their last saved snapshot and its capture time; log into each alt once to collect its raid details. Expired snapshots disappear using the raid's own reset time, including extended lockouts. Unfinished only hides killed boss rows. API failures or restricted data preserve the previous snapshot. Personal checklist goals remain manual and independent of raid progress. The automatic raid goal reads the current-season encounter list from Blizzard's Great Vault data and counts each boss once across difficulties. M+ progress counts current-week completed runs; its target follows the final dungeon Vault threshold. Vault progress counts the active raid, dungeon, and world/PvP rows (normally nine slots). Weekly quest progress counts weekly-tagged quests accepted while the addon is enabled, retaining turn-ins until reset; it does not discover every available weekly quest. Unavailable counters show a waiting message, and unclaimed previous-week Vault rewards are not counted as current progress. Offline alts keep their last captured counters until reset.

The planner now uses the same palette colours, panel styling, branded header, and Classic dialog/button textures as the mailbox and macro frames. Appearance preferences remain configurable on the Weekly Planner settings page.

The information panel below the selected character's goals has **Crests** and **Other resources** tabs with currency icons, **Owned** amounts and **Can still earn** allowances. Other resources includes Voidlight Marl, Undercoin, Coffer Keys/shards, Field Accolades, Unalloyed Abundance, Resonance Crystals and additional Midnight resources. Scroll within the panel for more currencies; switching characters resets its scroll position and keeps your selected tab. They do not count as goals or completion targets. Hover a crest for full earning details and its update time. Offline alts show their own saved balances; log into that character to refresh expired allowances.

Drag a character onto another row to reorder the roster, dropping above or below its middle to place it before or after that character. **Order** shows all characters, including filtered ones; click **Done** when finished. Scroll while dragging to reach more characters. Dropping outside the roster cancels the move. Your order is saved across logins and weekly resets; all characters appear while ordering, including ones hidden by Unfinished only. Right-click the order button to restore the default order. Available raid bosses are green, killed bosses are muted, completed goals are green and progress is amber. Hover details use corresponding status colors for bosses, quests and Vault slots.

Font discovery checks the client's actual font files and installed shared-media providers, with a native UI font fallback. Research and future maintenance rules are saved in [WoW font findings](docs/WOW-FONTS.md).

## Enchanted Whispers

The default window is **540 × 360**, with a **138-pixel conversation list**. Drag the header to move it or the lower-right handle to resize it, independently of font size. Search or scroll the conversation list; unread counts and saved-draft indicators help you switch between chats. Use **New** for a character name, **Friends** for an online Battle.net friend, and Enter or **Send** to send. Chat history and drafts are saved separately for each logged-in character. **Clear** asks before removing a conversation. Storage is bounded to 50 conversations and 100 messages per conversation; unread chats and drafts are never automatically evicted.

Click the matching minimap icon to open or close Whispers, right-click for its settings, or drag to reposition it. Settings include Native WoW, Modern, and Classic-inspired appearances, verified built-in and shared-media fonts, opacity, message size, and optional incoming-message popups outside combat. Notifications support Blizzard sounds, registered LibSharedMedia sounds, or a custom in-game addon sound path. Select **Custom file**, enter a path such as `Interface\AddOns\MyMedia\sound.ogg`, and use **Test sound**. The sound file must be installed before starting WoW.

Ordinary combat does not automatically open the window or take keyboard focus. Public whisper events are handled normally, without modifying Blizzard chat frames or intercepting their protected functions. When Blizzard restricts addon chat access in encounters, M+, PvP, or other restricted contexts, sending is disabled and drafts are retained. Restricted/secret text is never compared, converted, stored, or displayed; use Blizzard chat there. Battle.net conversations use BattleTags as identities rather than trusting account IDs saved from another session. After logging back in, select that friend from **Friends** or receive a new message before sending from their saved conversation.

Mailbox, Macros, and Weekly Planner now offer an optional **Native WoW window border** in their shared settings pages. This reuses Blizzard's native chrome while keeping their established layouts, palettes, and controls.

## Builds and releases

All CI and packaging run in the [local Jenkins project](http://localhost:8088/job/enchanted-frames/) using the repository's `Jenkinsfile`. GitHub Actions workflows have been retired. Jenkins requires the local controller and Docker build daemon to be running; turning the computer off pauses polling and builds.

Each build checks the six manifest versions, validates active Lua sources with Lua 5.1, runs all behavior tests, verifies referenced manifest files, and checks the resulting ZIP. Jenkins archives the ZIP and a source-commit/SHA-256 report. Publishing runs only after validation and uses the project's existing GitHub credential. A draft release receives the tested ZIP before becoming public; existing public versions are left untouched. Use **Build with Parameters** and disable `PUBLISH_RELEASE` for a validation-only build. See [Jenkins setup](docs/JENKINS.md).

## Compatibility

- World of Warcraft Retail / Midnight 12.1 (`Interface: 120100`)
- Optional LibSharedMedia font discovery through compatible installed addons
- No external network access from inside the game

## Author and support

Created by **Revath#2331 (Revathify)**.

Support the project at [Buy Me a Coffee](https://buymeacoffee.com/revath).

New blank macros default to Blizzard's question-mark (automatic) icon, so `#showtooltip SPELLNAME` can choose the spell icon. Existing macros and explicitly selected icons keep their choice.
