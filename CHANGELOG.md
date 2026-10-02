# Changelog

## 4.6.0 - Drag roster ordering and reliable fonts

- Replaced roster arrow controls with drag-and-drop ordering, target highlighting and safe cancellation; existing custom order is preserved.
- Added shared font resolution, locale-aware native fallbacks, client font load probes and filtering of unavailable fonts in font menus.
- Fixed shared font names containing Outline incorrectly enabling outline styling in the planner.
- Saved verified WoW font findings and maintenance guidance in docs/WOW-FONTS.md and AGENTS.md, with regression checks in the build.

## 4.5.0 - Status colors and character order

- Colored available raid bosses green and killed bosses muted, with status colors for roster summaries, completed/in-progress goals and boss/quest/Vault hover details.
- Added an Order button and up/down controls for arranging the character roster, including the current character.
- Saved custom order per character across reloads, login identity upgrades, weekly resets and filtered views.
- Right-click the Order button to restore the original roster order.

## 4.4.0 - Tabbed character currencies

- Added Crests and Other resources tabs below the selected character's goals, remembering the selected tab.
- Added Voidlight Marl, Undercoin, Coffer Keys/shards, Field Accolades, Unalloyed Abundance, Resonance Crystals and other verified Midnight resources with currency icons and saved balances.
- Added independent resource scrolling, per-alt selection, hover details and safe offline/reset snapshots.
- Kept resource information outside goal completion totals and adapted the panel height to smaller windows.

## 4.3.0 - Clearer crest information

- Added Blizzard currency icons, saved with balances for offline alts.
- Replaced compact currency strings with separate crest, Owned and Can still earn columns.
- Added readable weekly/season allowances, limit-reached highlighting and refresh hints while retaining full totals on hover.

## 4.2.0 - Character crest information

- Moved crest balances and weekly/season allowances from the goal checklist to a matching information panel below the selected character's goals.
- Removed crests from completion totals and Choose goals; old manual overrides no longer affect their information.
- Retained per-character offline balances, allowance refresh hints, hover details and capture timestamps.
- Adjusted the goal list to fit above the panel when resizing the window.

## 4.1.0 - Suite versioning correction

- Established Major.Minor.Hotfix versioning for the suite with the new Weekly Planner frame and its expanded tracking features.
- Synchronized all five active addon manifests to 4.1.0.
- Releases now package the explicitly chosen version instead of automatically incrementing Hotfix on every push.
- Documented major releases for new frames, minor releases for features, and hotfix releases for fixes.

## Upcoming - More weekly activities and per-character goal selection

- Added Coffer Key and shard balances, weekly shard earnings and remaining allowance from Blizzard's currency counters.
- Added current-season Mistcrest balances and reported weekly/season earning limits, keeping spending separate from earnings.
- Added Midnight knowledge-source checklists for learned professions: weekly quest, treatise, weekly treasures and gathering/disenchanting drops.
- Added named goals for tracked Soiree, Abundance, Special Assignments, weekly dungeon/meta quests, Void Assaults, Coiled Isle weeklies and Prey reward hunts, including the four new Nightmare targets.
- Added Choose goals to hide/restore activities per character, exclude hidden activities from totals, and preserve preferences across resets.
- Preserved offline balances, expired weekly counters, retained safe snapshots on restricted/partial API reads, and kept manual completion available.

## Upcoming - Wider weekly goal tooltips

- Let goal tooltips grow to fit their longest entry, keeping titles, boss details, Vault slots and quest objectives on individual rows.

## Upcoming - Clickable default weekly goals

- Restored row and checkbox clicks for the four default goals, including offline alts.
- Saved manual completion until weekly reset while continuing to show real boss, quest, dungeon and Vault progress.
- Added Shift-click to restore automatic completion and described it in the goal tooltips.

## Upcoming - Weekly goal details and refreshed suite icons

- Added hover details for season raid boss kills and difficulty, completed M+ runs, all active Great Vault slots and available reward item levels, and tracked weekly quest status/objectives.
- Saved details for offline characters, labelled missing item data, refreshed cached rewards after item loading, and added Shift-scroll paging for long tooltips.
- Recognized Favor of the Court, Fortify the Runestones, Abundant Offerings and the Saltheril weekly meta quest when accepted or completed, including variants without a weekly frequency tag.
- Refreshed mailbox, macros, suite and tooltips addon icons in the planner's painted gold-and-cyan style, preserving transparent edges and the approved planner icon.

## Upcoming - Transparent planner icon

- Removed the planner icon's square background while preserving the book artwork and transparent edges in the WoW texture.
- Removed minimap texture cropping so the complete book silhouette remains visible.

## Upcoming - Planner identity and automatic weekly goals

- Added a dedicated enchanted-book icon for the planner minimap button, window header, and addon list.
- New blank macros now use the automatic question-mark icon so #showtooltip can resolve spell icons.
- Added automatic default goals for current-season raid bosses, completed M+ runs, tracked weekly quests, and Great Vault slots.
- Used Blizzard counters and season encounter data, saved offline snapshots, protected automatic rows from manual edits, and expired progress at weekly reset.
- Added regression coverage for default goal data, secret values, previous-week Vault rewards, and automatic row controls.

## Upcoming - Resizable planner and appearance controls

- Added a bottom-right resize handle, saved dimensions, and lists that expand with the window while keeping text size unchanged.
- Added an in-window Appearance panel with mailbox-style Modern/Classic buttons and opacity/scale sliders.
- Matched mailbox opacity and scale ranges and opacity differences between backgrounds, panels, inputs, and buttons.

## Upcoming - Weekly Planner Modern skin fix

- Fixed the planner failing to open in Modern skin because button texture setters rejected nil assets.
- Hide Classic button textures in Modern skin and restore them when switching back to Classic.
- Added stricter texture API mocks and regression checks for switching between both skins.

## Upcoming - Planner styling and raid lockouts

- Added a draggable Weekly Planner minimap icon with saved position and click-to-toggle access.
- Matched the suite's Modern palettes, branded header, differentiated panels, and Classic dialog/button textures.
- Imported Enchanted Mailbox characters and preserved goals when imported alts log in.
- Added a Raid Lockouts tab with saved raid IDs, difficulty, boss kill details, and individual reset timing.
- Saved dated offline-alt snapshots, refreshed current-character raid data on login and successful encounters, and preserved cached information when data is unavailable.
- Added roster, raid capture, combat deferral, expiration, restricted-data, and tab interaction regression checks.

## Upcoming — Enchanted Weekly Planner

- Added a separate Weekly Planner module with personal weekly goals and progress for each logged-in character.
- Added manual completion, editable goals, starter goals, undo removal, and an unfinished-only filter for goals and characters.
- Used Blizzard's regional weekly reset timing to clear completion checks, including offline alts, while preserving goals.
- Added shared appearance settings, saved window position, /rweekly and /rplanner commands, release packaging, and reset regression checks.

## Upcoming — Retire Auction House module

- Marked Auction House obsolete and stopped loading its runtime files, retaining the source for reference.
- Removed its settings page and excluded it from suite packaging and version bumps.
- Updated installation instructions to disable or remove the old Auction House folder when upgrading.

## Upcoming — Compact Auction House companion

- Replaced the tall side panel with a 190-pixel-high Sell / Buy companion below Blizzard's AH tabs.
- Added individual and bulk bag queues that prepare each stack at the lowest live price and advance after a confirmed native post.
- Added item/link and quantity entry plus bulk tracked-recipe imports to the Buy queue; shared reagent requirements subtract inventory once, and repeat imports do not duplicate shortages.
- Kept posting and purchase confirmation in Blizzard's window, with stop, removal, and queue-clearing controls.

## Upcoming — Sell companion usability

- Included the reagent bag in sellable-item discovery and showed how many occupied slots were checked when nothing qualifies.
- Made queue results visible on item rows and added clear feedback when BoE or marked-item queues find nothing.
- Added an explicit queue-all-sellable action; selecting an individual item can now open Blizzard's Sell view directly.
- Made live-price lookup optional, so unavailable search results no longer block a manual price and secure review in Blizzard's Sell view.

## Upcoming — LFG invite safety

- Stopped loading the retired full-window Auction House UI and its high-strata mouse blocker.
- Kept only the docked companion active; it no longer modifies Blizzard's Auction House frame alpha.
- Lowered companion layering so Blizzard dialogs retain priority.

## Upcoming — Auction House companion

- Restored Blizzard's native Auction House as the default so categories, icons, item quantities, and coin displays remain visible.
- Docked Revath's Sell Queue, Crafting, Shopping, and Prices tools beside the native window instead of hiding it.
- Kept live price checks and one-at-a-time, Blizzard-confirmed posting in the companion; recipe material searches now open native Buy results.
- Replaced the old full-window default setting with a show/hide companion preference.

## Upcoming — Familiar Auction House, smarter workflows

- Made Buy, Sell, and Auctions the primary tabs, with Crafting, Shopping, Prices, and Settings alongside them.
- Added a reviewed sell queue for auctionable BoE stacks and explicitly marked crafted items; each queued item can match the lowest current listing before the protected final post.
- Added tracked-recipe materials with owned/missing counts, reagent-quality selection, search, and secure checkout.
- Added a manual full-market scan that records observed item values for price views and tooltips; scans remain subject to Blizzard's cooldown.

## Upcoming — Full-size Auction House window

- Promoted Enchanted Auction House from a sidecar to the default, full-size auction window.
- Added a Sell tab for selecting auctionable bag items and preparing quantity, price, and duration before Blizzard's protected final post.
- Reorganized Browse, Shopping, Auctions, and Prices into a two-column workspace with clearer detail panels.
- Added a visible switch to Blizzard's view and a setting to choose the default view; `/rah` toggles between them at an auctioneer.
- Kept secure purchase and posting confirmation in Blizzard's native flow, with a return button to Revath's window.

## Upcoming — Enchanted Auction House

- Added Revath's Enchanted Auction House as a fifth, independently configurable addon folder with a new cyan-and-silver auction icon.
- Added a styled auction companion with live browse results, recent searches, an account-wide shopping list and price limits, locally observed price history, and active-auction review.
- Added price-history information to item tooltips and a confirmation before cancelling one of your own auctions.
- Kept purchases and posting in Blizzard's protected Auction House flow; no background scanning or automated trading.
- Added Auction House settings to the shared Blizzard AddOns category and synchronized the new module with build and release packaging.

## 3.0.14 — Enchanted Macros icon

- Added a dedicated Enchanted Macros emblem featuring a cyan-lit macro scroll and silver quill in the suite's visual style.
- Added the emblem to the Macros window header and addon metadata instead of reusing the Mailbox icon.

## 3.0.13 — Recipient autocomplete correction

- Recipient suggestions now open only while the player is actually typing.
- Selecting an alt, friend, guild member, or reply recipient no longer reopens autocomplete after the addon fills the name.

## 3.0.12 — Faster mail addressing and item macros

- Clicking an alt, friend, or guild member now commits the recipient immediately, suppresses the redundant name suggestion, and focuses the subject field.
- Added a Copy view for received mail with selectable message text and straightforward Ctrl+A / Ctrl+C support for text and URLs.
- Shift-clicking an item while Enchanted Macros is open now inserts a `/use Item Name` command at the macro cursor.

## 3.0.11 — Readable syntax assistant

- Increased the syntax-helper heading, suggestion labels, explanations, prompts, and full command preview for comfortable reading at normal gameplay scale.
- Increased suggestion row height and spacing so the larger type remains clean and uncluttered.
- Expanded the helper popup and castsequence syntax footer to prevent the larger text from crowding or clipping.

## 3.0.10 — Font-safe controls and clearer syntax help

- Replaced unsupported checkmark, menu, arrow, and status glyphs that appeared as rectangular boxes with font-safe styling.
- Added proper dropdown arrow textures to Mailbox, Macros, and Blizzard AddOns settings.
- Selected options now use accent colors and borders instead of font-dependent symbols.
- Removed the Support section from the Blizzard AddOns overview.
- Increased syntax-helper heading, detail, hint, and full-syntax font sizes.
- Expanded the syntax footer and popup width so the larger command example remains readable.

## 3.0.9 — Version synchronization safeguards

- Made every in-game module display the parent Enchanted Frames suite version as the canonical version.
- Added release checks requiring all four addon manifests to contain the same version.
- Added post-package checks that inspect every manifest inside the finished ZIP.
- Moved tag creation and the version-bump push until after validation and packaging succeed.
- Added the same manifest and archive consistency checks to manual and pull-request builds.

## 3.0.8 — Mail gold visibility and persistent macro guidance

- Added larger gold-colored incoming-money amounts with coin icons to Mailbox inbox rows.
- Added a prominent **Gold Attached** block near the bottom of the selected message pane.
- Made macro suggestions refresh when the editor gains focus or the caret moves, including loaded macros.
- Kept castsequence guidance active throughout the workflow until **END MACRO** is explicitly selected.
- Fixed mouse selection so focusing the editor cannot replace the clicked suggestion before insertion.

## 3.0.7 — Castsequence state-machine fixes

- Made castsequence parsing ignore commas inside conditional blocks such as `[@mouseover,help,nodead]`.
- Added an explicit **Skip reset → first spell** choice after selecting target conditions.
- Added a clear `reset=` decision after the target step, followed by the reset-condition catalog.
- Added explicit **Add next spell** and **End sequence** choices after every completed spell.
- Preserved the guided flow after both keyboard and mouse selections.

## 3.0.6 — Unified Mailbox framing

- Rebuilt the Mailbox modern skin with the same softly rounded tooltip borders used by Enchanted Macros.
- Added matching layered outer, panel, input, button, and tab edges throughout the Mailbox.
- Added the Macros-style accent divider beneath the Mailbox header.
- Inset the header glow so it follows the curved outer frame instead of clipping through its border.
- Preserved the parchment-framed Classic skin and the existing Mailbox layout.

## 3.0.5 — Sequence workflow and layout fixes

- Moved the Mailbox Settings button into the header beside Close, matching Enchanted Macros.
- Fixed commas inside castsequence condition blocks being mistaken for action separators.
- Restored the optional reset stage after selecting a cast target and filters.
- Added an explicit **Add next spell** suggestion after completing a known sequence spell.
- Added a full `/castsequence` syntax preview to the suggestion footer.
- Removed the false condition-placement warning for valid condition blocks.
- Added a new transparent Enchanted Frames suite emblem and parent-addon icon.
- Added a detailed, website-ready feature description.

## 3.0.4 — Settings cleanup

- Removed the duplicate Tooltip Helper control from the Mailbox window.
- Tooltip totals are now managed exclusively from Blizzard Options → AddOns → Revath's Enchanted Frames → Tooltips.

## 3.0.3 — Castsequence syntax assistance

- Added syntax-aware `/castsequence` setup, reset, and action stages.
- Added combined reset suggestions such as `reset=target/combat/5`.
- Kept conditionals at the sequence-clause level instead of suggesting them between individual actions.
- Added separate guidance for the first spell and each comma-separated next spell.
- Rebuilt suggestion rows into aligned action and description columns.
- Anchored the suggestion popup below the active visual line, with an above-line fallback near the editor bottom.

## 3.0.2 — Shared settings improvements

- Replaced cycling settings buttons with clear dropdown selectors.
- Added immediate initial values for every shared appearance control.
- Added the full LibSharedMedia font catalog with pagination and mouse-wheel navigation.
- Synchronized Mailbox and Macros appearance values between their in-addon settings and Blizzard Options.
- Renamed the tooltip summary to **Owned Total** and increased its visual contrast.

## 3.0.0 — Enchanted Frames suite

- Renamed the project to **Revath's Enchanted Frames**.
- Added a shared parent addon and centralized Blizzard AddOns settings category.
- Renamed and reorganized the Mailbox, Macros, and Tooltips features as separate modules.
- Integrated the complete Macro Workshop into the suite.
- Preserved existing mailbox, macro, and tooltip saved-variable data for upgrades.
- Added Mailbox settings for skin, palette, font, opacity, scale, and offline contacts.
- Added Macros settings for skin, palette, font, opacity, and editor font size.
- Added a Tooltips enable/disable setting and suite author/support information.
- Updated packaging to ship all four addon folders in one release ZIP.
