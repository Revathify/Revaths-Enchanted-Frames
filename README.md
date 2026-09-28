# Revath's Enchanted Frames

<p align="center"><img src="RevathsEnchantedFrames/Media/RevathsEnchantedFrames.png" alt="Revath's Enchanted Frames" width="360"></p>

Revath's Enchanted Frames is a modular World of Warcraft Retail addon suite that combines a customizable mailbox replacement, an advanced macro workshop, account-wide item-count tooltips, and an auction-house companion under one shared parent addon and one Blizzard Settings category.

## Modules

- **Revath's Enchanted Frames** — shared parent, suite metadata, author information, and centralized Blizzard Settings pages.
- **Revath's Enchanted Mailbox** — inbox tools, New Mail editor, contacts, quick attachments, alt tracking, Modern and Classic skins, palettes, fonts, opacity, and scaling.
- **Revath's Enchanted Macros** — separate account and character macro libraries, curated class/spec templates, icon picker, drag-to-action-bar, syntax suggestions, usable-item suggestions, and Modern or Classic skins.
- **Revath's Enchanted Tooltips** — account-wide bag, bank, and Warband-bank item totals with Shift details per character.
- **Revath's Enchanted Auction House** — a docked companion to Blizzard's native Auction House. It adds a reviewed BoE/crafted-item sell queue, tracked-recipe materials, a manual full-market scan, shopping lists, price history, and tooltip values while keeping Blizzard's categories, icons, quantities, coin displays, and checkout.

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

Blizzard's Auction House remains visible, with its category browser, item icons, quantities, and coin displays. Revath's companion docks beside it by default. In Sell, select one auctionable bag item or queue BoE, explicitly marked crafted items, or all sellable stacks; reagent-bag items are included. Queued rows are labeled. **Check live price** looks up the lowest current listing, but it is optional: **Review in Sell** opens Blizzard's Sell view, where you can enter or adjust the price, review quantity and deposit, and confirm each post. The Crafting tab gathers basic materials from recipes marked **Track Recipe** in Professions (the star only favorites a recipe), showing owned and missing counts and searching native Buy for each reagent. The Prices tab can run a full auction snapshot on demand and save observed per-item values for tooltips; the game may throttle repeat scans. `/rah` shows or hides the companion at an auctioneer. No background scanning or unattended trading occurs.

## Compatibility

- World of Warcraft Retail / Midnight 12.1 (`Interface: 120100`)
- Optional LibSharedMedia font discovery through compatible installed addons
- No external network access from inside the game

## Author and support

Created by **Revath#2331 (Revathify)**.

Support the project at [Buy Me a Coffee](https://buymeacoffee.com/revath).
