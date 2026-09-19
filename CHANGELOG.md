# Changelog

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
