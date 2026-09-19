# Revath's Enchanted Frames

Revath's Enchanted Frames is a modular quality-of-life suite for World of Warcraft Retail. It brings an enhanced mailbox, a powerful macro workshop, and account-wide item ownership information together under one visual identity and one organized Blizzard AddOns settings category.

Each module can be managed independently, while shared appearance settings keep the suite consistent. Choose between Modern and Classic-inspired skins, select color palettes and fonts, adjust transparency and sizing, and apply changes immediately from either the addon windows or Blizzard Options.

## Revath's Enchanted Mailbox

Replace the standard mailbox workflow with a larger, clearer interface built for everyday mail management.

- Read and manage mail from a spacious two-pane inbox.
- Compose mail with recipient suggestions and quick access to friends, guild members, and known characters.
- Attach items and profession materials quickly.
- Track mailbox information and gold across your characters.
- Switch between Modern and Classic-inspired visual styles.
- Customize palette, font, opacity, and window scale.
- Open the mailbox with `/rmail` or `/revathsmailbox` while interacting with a mailbox.

## Revath's Enchanted Macros

Create and maintain macros in a dedicated editor designed to make Blizzard macro syntax easier to understand.

- Separate Account Macros and Character Macros into clear libraries.
- Browse curated class- and specialization-specific community templates.
- Choose from Blizzard's macro icons through a responsive, scrollable icon browser.
- Drag completed macros directly onto an action bar.
- Increase or decrease editor text size without leaving the editor.
- Use syntax assistance for macro commands, unit targets, conditionals, known spells, usable items, console commands, and cast sequences.
- Build advanced target conditions step by step, including mouseover, friendly, hostile, alive, dead, focus, player, and fallback behavior.
- Build `/castsequence` commands with guided target, reset, first-action, and next-action stages plus a complete syntax preview.
- Use `/rmacro` or `/macroworkshop` to open the editor.

## Revath's Enchanted Tooltips

See how many copies of an item you own without searching every character and storage location.

- Displays a clear **Owned Total** on item tooltips.
- Counts items from character bags, character banks, and available Warband-bank storage.
- Hold Shift to see the per-character breakdown.
- Enable or disable totals from the suite's Tooltips settings page.

## Shared settings and appearance

Open **Options → AddOns → Revath's Enchanted Frames** to access the suite overview and separate Mailbox, Macros, and Tooltips pages.

- Current values appear immediately when a settings page opens.
- Dropdown selectors provide clear skin, palette, and font choices.
- LibSharedMedia fonts from compatible installed addons are discovered automatically.
- Settings changed inside an addon window stay synchronized with Blizzard Options.
- Author, version, module status, and support information are available from the suite overview.
- `/ref` or `/enchantedframes` opens the shared settings directly.

## Modular installation

The release ZIP contains one parent addon and three feature modules:

- `RevathsEnchantedFrames` — shared framework and settings.
- `RevathsMailbox` — Revath's Enchanted Mailbox.
- `RevathsMacro` — Revath's Enchanted Macros.
- `RevathsMailboxTooltipHelper` — Revath's Enchanted Tooltips.

The established technical folder IDs are retained so existing mailbox settings, macro preferences, and tracked tooltip data continue to load after upgrading to the combined suite.

## Compatibility

- Designed for World of Warcraft Retail.
- Supports optional LibSharedMedia font collections.
- Uses only Blizzard's in-game addon APIs; no external network connection is required in game.

Created by **Revath#2331 (Revathify)**. Support development at [Buy Me a Coffee](https://buymeacoffee.com/revath).
