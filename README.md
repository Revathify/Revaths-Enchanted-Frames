# Revath's Enchanted Frames

<p align="center"><img src="RevathsEnchantedFrames/Media/RevathsEnchantedFrames.png" alt="Revath's Enchanted Frames" width="360"></p>

Revath's Enchanted Frames is a modular World of Warcraft Retail addon suite that combines a customizable mailbox replacement, an advanced macro workshop, account-wide item-count tooltips, and an auction-house companion under one shared parent addon and one Blizzard Settings category.

## Modules

- **Revath's Enchanted Frames** — shared parent, suite metadata, author information, and centralized Blizzard Settings pages.
- **Revath's Enchanted Mailbox** — inbox tools, New Mail editor, contacts, quick attachments, alt tracking, Modern and Classic skins, palettes, fonts, opacity, and scaling.
- **Revath's Enchanted Macros** — separate account and character macro libraries, curated class/spec templates, icon picker, drag-to-action-bar, syntax suggestions, usable-item suggestions, and Modern or Classic skins.
- **Revath's Enchanted Tooltips** — account-wide bag, bank, and Warband-bank item totals with Shift details per character.
- **Revath's Enchanted Auction House** — a compact Sell / Buy companion below Blizzard's native Auction House. Queue bag items at the lowest live price and bulk-add missing tracked-recipe materials to buy.

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

Blizzard's Auction House remains visible. A 190-pixel-high companion sits below its tabs with just **Sell** and **Buy**, and three scrollable item rows. In Sell, select bag items and use **Add selected**, right-click rows to toggle them in the queue, or use **Add all bags** (including the reagent bag). **Sell lowest** prepares the first queued stack at the lowest live buyout, matching the item level for equipment. Review the quantity, price, duration, and deposit and click Blizzard's Post button; after a successful post, the next stack is prepared automatically. **Stop** pauses the queue; **Clear queue** removes it. Missing prices, errors, or moved stacks stop the sequence and keep the queue for review. In Buy, enter an item ID or link and quantity, or use **Add tracked recipes** to collect basic reagents from recipes marked **Track Recipe** in Professions (the star only favorites a recipe). Shared materials are combined before subtracting owned inventory; re-importing recipes updates shortages without duplicating them. Reagents use the saved quality choice, or the first listed quality by default. **Find in Buy** opens the exact material and fills its commodity quantity. Confirm purchases in Blizzard's window, then **Done / next** removes the current entry and searches the next. `/rah` shows or hides the companion at an auctioneer. Posting and purchases require Blizzard's confirmation.

## Compatibility

- World of Warcraft Retail / Midnight 12.1 (`Interface: 120100`)
- Optional LibSharedMedia font discovery through compatible installed addons
- No external network access from inside the game

## Author and support

Created by **Revath#2331 (Revathify)**.

Support the project at [Buy Me a Coffee](https://buymeacoffee.com/revath).
