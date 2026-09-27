# Revath's Enchanted Frames

<p align="center"><img src="RevathsEnchantedFrames/Media/RevathsEnchantedFrames.png" alt="Revath's Enchanted Frames" width="360"></p>

Revath's Enchanted Frames is a modular World of Warcraft Retail addon suite that combines a customizable mailbox replacement, an advanced macro workshop, account-wide item-count tooltips, and an auction-house companion under one shared parent addon and one Blizzard Settings category.

## Modules

- **Revath's Enchanted Frames** — shared parent, suite metadata, author information, and centralized Blizzard Settings pages.
- **Revath's Enchanted Mailbox** — inbox tools, New Mail editor, contacts, quick attachments, alt tracking, Modern and Classic skins, palettes, fonts, opacity, and scaling.
- **Revath's Enchanted Macros** — separate account and character macro libraries, curated class/spec templates, icon picker, drag-to-action-bar, syntax suggestions, usable-item suggestions, and Modern or Classic skins.
- **Revath's Enchanted Tooltips** — account-wide bag, bank, and Warband-bank item totals with Shift details per character.
- **Revath's Enchanted Auction House** — live auction search, recent searches, account-wide shopping list and price limits, locally observed price history, and your active auctions. Buying, selling, and cancellation use Blizzard's protected Auction House controls.

## Install or upgrade

1. Extract all five folders into `_retail_/Interface/AddOns/`, replacing the existing module folders when prompted:
   - `RevathsEnchantedFrames`
   - `RevathsMailbox`
   - `RevathsMacro`
   - `RevathsMailboxTooltipHelper`
   - `RevathsAuctionHouse`
2. Restart WoW or type `/reload`.

The existing child modules keep their technical folder IDs so WoW automatically loads your existing saved-variable files. The Auction House is a new optional child module with its own saved data. Existing settings, macro preferences, and tracked item data migrate without a manual reset.

## Settings and commands

Open **Options → AddOns → Revath's Enchanted Frames** for the suite overview and Mailbox, Macros, Tooltips, and Auction House subpages.

- `/ref` or `/enchantedframes` opens the shared addon settings.
- `/rmail` or `/revathsmailbox` opens the mailbox while a mailbox NPC/object is active.
- `/rmacro` or `/macroworkshop` opens Revath's Enchanted Macros.
- `/rah` or `/rauction` toggles the auction companion while at an auctioneer.

The auction companion opens alongside Blizzard's Auction House. Search results can be opened in Blizzard's buy pane or right-clicked into a shopping list. Your auction listings can be reviewed and cancelled with an explicit confirmation. Price history records only prices observed during your own searches; it is not a global market database or a background scanner.

## Compatibility

- World of Warcraft Retail / Midnight 12.1 (`Interface: 120100`)
- Optional LibSharedMedia font discovery through compatible installed addons
- No external network access from inside the game

## Author and support

Created by **Revath#2331 (Revathify)**.

Support the project at [Buy Me a Coffee](https://buymeacoffee.com/revath).
