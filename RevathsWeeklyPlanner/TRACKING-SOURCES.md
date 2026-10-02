# Additional weekly tracking: verification notes

Verified 2 October 2026. Implemented independently; referenced addon data is used to identify game IDs and reset semantics, not to copy tracker implementations.

## Currency counters and caps

[Blizzard CurrencyInfo API documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua) defines quantity, quantityEarnedThisWeek, maxWeeklyQuantity, canEarnPerWeek, totalEarned, maxQuantity, useTotalEarnedForMaxQty and isTypeUnused. Balance is never treated as weekly earnings. Weekly earning allowances use the weekly fields; rolling season allowances use totalEarned/maxQuantity. A zero limit is shown as no reported earning limit, never replaced with an invented cap.

- Restored Coffer Key: [3028](https://www.wowhead.com/currency=3028/restored-coffer-key).
- Midnight Coffer Key Shards: [3310](https://www.wowhead.com/currency=3310/coffer-key-shards). The client supplies the earning cap; the implementation does not hardcode 600 or infer earned keys from key inventory changes.
- Midnight Season 2 Mistcrests: 3442 Adventurer, 3443 Veteran, 3444 Champion, [3445 Hero](https://www.wowhead.com/currency=3445/hero-mistcrest), [3446 Myth](https://www.wowhead.com/currency=3446/myth-mistcrest). Retired currencies are excluded via isTypeUnused. This catalog is season-specific and must be reviewed for the next season.

## Additional resource currencies

The resource ID catalogue was checked against [SavedInstances' authored Currency.lua catalogue](https://github.com/SavedInstances/SavedInstances/blob/master/SavedInstances/Modules/Currency.lua): Voidlight Marl 3316, Undercoin 2803, Field Accolade 3405, Unalloyed Abundance 3377, Resonance Crystals 2815, Shard of Dundun 3376, Brimming Arcana 3379, Luminous Dust 3385, Remnant of Anguish 3392, Uncontaminated Void Sample 3400, Angler Pearls 3373, Illusionary Coin 3393, Twilight's Blade Insignia 3319, Corrosive Coin 3448 and Coiled Filament 3546. The Other resources tab also shows Coffer Keys 3028 and shards 3310. Labels, icons, balances and earning limits are read from Blizzard; unavailable/retired currencies are excluded instead of assigned invented balances. Saved balances persist across weekly resets; earning snapshots require refreshing by logging into the character. Resources do not create new checklist goals. Long lists scroll within the information panel.

## Profession sources

[WeeklyKnowledge's authored game data](https://github.com/DennisRas/WeeklyKnowledge/tree/main/Data/Objectives) identifies Midnight weekly quests, treatise usage flags, weekly treasure flags, and gathering/disenchanting flags. [Skill-line definitions](https://github.com/DennisRas/WeeklyKnowledge/blob/main/Data/SkillLineVariants.lua) map expansion skill lines to primary professions. These are factual quest/skill identifiers; our checklist and snapshot implementation is original.

[Blizzard TradeSkillUI API documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua) exposes GetProfessionInfoBySkillLineID. The character's primary professions are read first, and Midnight skill level must be positive to scan their flags. Unknown expansion skill data stays labelled unknown; foreign professions are excluded.

Sources count completed weekly tasks, not a claimed universal knowledge-point maximum. First crafts, one-time treasures, reputation rewards, catch-up knowledge, monthly Darkmoon quests, unused knowledge in bags and patron orders are outside this checklist. Gathering/treatise/treasure flags reflect the game's consumption/completion state and may differ from possession of an unconsumed item.

## World quests and Prey

[SavedInstances' authored quest catalog](https://github.com/SavedInstances/SavedInstances/blob/master/SavedInstances/Modules/Progress.lua) provides profession weekly/treatise IDs, Midnight weekly pools, Special Assignments, dungeon quests, Void Assaults, Coiled Isle quests and the four-reward Prey milestone. New meta variants are cross-checked with [WoWWeekly's catalog](https://github.com/blat001/wow-weekly/blob/main/Constants.lua). Unaccepted/unavailable pool members never inflate the denominator. Named groups appear after a relevant quest is accepted, active as a world quest, or completed. Their labels show the tracked subset, not every potentially offered quest.

Season 2 Nightmare hunts add [Janoa 95021](https://www.wowhead.com/quest=95021/prey-janoa-the-fang-nightmare), [Kursak 95022](https://www.wowhead.com/quest=95022/prey-kursak-the-coiled-nightmare), [Batani 95023](https://www.wowhead.com/quest=95023/prey-batani-the-scaled-nightmare), and [Kadani 95024](https://www.wowhead.com/quest=95024/prey-kadani-the-claw-nightmare). One-time introductory Prey chains are not included. Hunt progress counts distinct weekly reward completion flags, not unrestricted repeated hunts. Abundance tracks its weekly quest objectives, not a fabricated lifetime/run counter.

## Snapshot and display behavior

Balances and profession identity persist for offline alts with timestamps; weekly earnings, source flags and named quest snapshots expire at the regional weekly reset. Failed/restricted reads preserve safe snapshots. Hidden-goal preferences survive resets, while manual completion overrides expire. The quest summary does not add duplicate completion credit when named world/profession activities are present. Live in-game validation is still needed for cache/loading behavior; regression fixtures verify reset, limits, conversion, partial APIs and UI interactions.
