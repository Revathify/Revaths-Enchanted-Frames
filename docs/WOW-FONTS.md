# WoW font findings and maintenance rules

Verified 2 October 2026 against [Blizzard Retail font definitions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Fonts_Shared/Mainline/GameFonts.xml) and [LibSharedMedia's authored locale support notes](https://www.wowace.com/projects/libsharedmedia-3-0/files/623746). These are client assets, not operating-system font family names.

## Font files

| Font | Roman client asset | Use |
| --- | --- | --- |
| Friz Quadrata | `Fonts\FRIZQT__.TTF` | Blizzard UI text; the suite resolves its default from `GameFontNormal:GetFont()` for the actual client. |
| Arial Narrow | `Fonts\ARIALN.TTF` | Compact readable text and numbers. |
| Morpheus | `Fonts\MORPHEUS.TTF` | Decorative headings; avoid making it the required small-text font. |
| Skurri | `Fonts\SKURRI.TTF` | Optional display font; require a successful client load probe. |

Russian definitions include `Fonts\FRIZQT___CYR.TTF` and `Fonts\MORPHEUS_CYR.TTF`. The resolver uses native UI text for Russian Skurri selection rather than assuming a Cyrillic file path. Korean/Chinese clients have their own font-family members; the suite uses their native UI font instead of forcing Roman files.

## Runtime rules

- Use `RevathsEnchantedFrames_ResolveFont` / `RevathsEnchantedFrames_ApplyFont` for selectable suite text. Load `Fonts.lua` before Settings and child module UIs.
- Validate optional assets with a protected `CreateFont():SetFont(path, 12, "")` probe. A false result or exception makes the font unavailable. Apply to the target safely too, and restore the native client font on failure.
- Discover custom fonts only from installed LibSharedMedia providers. The suite does not bundle arbitrary fonts or install Windows fonts. A missing provider must fall back safely; it must not make text disappear.
- Treat shared font names as opaque. `shared:Outline Test` is a font name, not an instruction to enable outline styling. Only built-in keys ending in `Outline` set the OUTLINE flag.
- A successful SetFont proves file loading, not complete Unicode coverage. Do not depend on Unicode arrow glyphs for controls; use native UI textures or text labels. Keep status text readable independently of color.
- Preserve font choice keys so existing saved settings continue to work. Font menus filter failed probes.
- Run `tests/fonts.lua` plus planner/UI checks when changing font handling. Live WoW remains the authority for installed media and glyph coverage; repository mocks cannot render game fonts.
