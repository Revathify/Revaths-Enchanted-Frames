# Changelog

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
