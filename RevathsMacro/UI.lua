local _, ns = ...

local PALETTES = {
    midnight = {
        label = "Midnight Cyan", background = { 0.025, 0.032, 0.050 }, panel = { 0.055, 0.070, 0.105 },
        panelAlt = { 0.080, 0.100, 0.145 }, input = { 0.015, 0.022, 0.036 }, border = { 0.18, 0.30, 0.40 },
        accent = { 0.20, 0.78, 0.82 }, accent2 = { 0.40, 0.86, 0.69 },
    },
    arcane = {
        label = "Arcane Violet", background = { 0.050, 0.035, 0.080 }, panel = { 0.085, 0.060, 0.125 },
        panelAlt = { 0.115, 0.080, 0.165 }, input = { 0.035, 0.025, 0.060 }, border = { 0.30, 0.22, 0.42 },
        accent = { 0.66, 0.40, 0.94 }, accent2 = { 0.91, 0.55, 0.96 },
    },
    emerald = {
        label = "Emerald Grove", background = { 0.025, 0.060, 0.050 }, panel = { 0.045, 0.095, 0.075 },
        panelAlt = { 0.060, 0.125, 0.100 }, input = { 0.018, 0.046, 0.038 }, border = { 0.16, 0.34, 0.27 },
        accent = { 0.18, 0.78, 0.53 }, accent2 = { 0.55, 0.91, 0.48 },
    },
    crimson = {
        label = "Crimson Ember", background = { 0.070, 0.030, 0.035 }, panel = { 0.115, 0.048, 0.055 },
        panelAlt = { 0.150, 0.064, 0.070 }, input = { 0.052, 0.022, 0.026 }, border = { 0.38, 0.18, 0.20 },
        accent = { 0.91, 0.28, 0.34 }, accent2 = { 1.00, 0.62, 0.34 },
    },
    royal = {
        label = "Royal Blue", background = { 0.025, 0.040, 0.080 }, panel = { 0.042, 0.070, 0.125 },
        panelAlt = { 0.060, 0.095, 0.165 }, input = { 0.018, 0.032, 0.062 }, border = { 0.16, 0.28, 0.46 },
        accent = { 0.25, 0.57, 0.96 }, accent2 = { 0.55, 0.78, 1.00 },
    },
    graphite = {
        label = "Graphite Gray", background = { 0.050, 0.052, 0.058 }, panel = { 0.080, 0.083, 0.092 },
        panelAlt = { 0.110, 0.114, 0.125 }, input = { 0.035, 0.037, 0.043 }, border = { 0.28, 0.29, 0.32 },
        accent = { 0.62, 0.65, 0.70 }, accent2 = { 0.84, 0.86, 0.89 },
    },
}

local COLORS = {
    background = { 0.025, 0.032, 0.050, 0.97 }, panel = { 0.055, 0.070, 0.105, 1 },
    panelAlt = { 0.080, 0.100, 0.145, 1 }, input = { 0.015, 0.022, 0.036, 1 }, parchment = { 0.015, 0.022, 0.036, 1 },
    border = { 0.18, 0.30, 0.40, 1 }, accent = { 0.20, 0.78, 0.82, 1 },
    accent2 = { 0.40, 0.86, 0.69, 1 }, text = { 0.92, 0.95, 0.98, 1 },
    muted = { 0.57, 0.66, 0.75, 1 }, danger = { 0.95, 0.35, 0.38, 1 },
    ink = { 0.10, 0.040, 0.012, 1 },
}

local CLASSIC_COLORS = {
    background = { 0.030, 0.024, 0.014 }, panel = { 0.040, 0.030, 0.016 },
    panelAlt = { 0.090, 0.055, 0.022 }, input = { 0.025, 0.018, 0.009 }, parchment = { 0.055, 0.040, 0.022 },
    border = { 0.58, 0.48, 0.30 }, accent = { 0.96, 0.72, 0.20 },
    accent2 = { 0.98, 0.83, 0.43 }, text = { 1.00, 0.92, 0.72 },
    muted = { 0.76, 0.64, 0.43 }, danger = { 0.96, 0.35, 0.24 },
}

local FONTS = {
    { key = "friz", label = "Friz Quadrata", path = STANDARD_TEXT_FONT, flags = "" },
    { key = "frizOutline", label = "Friz Outlined", path = STANDARD_TEXT_FONT, flags = "OUTLINE" },
    { key = "arial", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF", flags = "" },
    { key = "arialOutline", label = "Arial Outlined", path = "Fonts\\ARIALN.TTF", flags = "OUTLINE" },
    { key = "morpheus", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF", flags = "" },
    { key = "morpheusOutline", label = "Morpheus Outlined", path = "Fonts\\MORPHEUS.TTF", flags = "OUTLINE" },
    { key = "skurri", label = "Skurri", path = "Fonts\\SKURRI.TTF", flags = "" },
    { key = "skurriOutline", label = "Skurri Outlined", path = "Fonts\\SKURRI.TTF", flags = "OUTLINE" },
}

local function DiscoverSharedMediaFonts()
    if not LibStub then return end
    local media = LibStub("LibSharedMedia-3.0", true)
    if not media or not media.HashTable then return end
    local knownPaths = {}
    for _, font in ipairs(FONTS) do knownPaths[string.lower(font.path)] = true end
    local registered = media:HashTable("font")
    if type(registered) ~= "table" then return end
    for name, path in pairs(registered) do
        if type(name) == "string" and type(path) == "string" and path ~= "" and not knownPaths[string.lower(path)] then
            local key = "shared:" .. name
            local exists = false
            for _, font in ipairs(FONTS) do if font.key == key then exists = true end end
            if not exists then
                FONTS[#FONTS + 1] = { key = key, label = name, path = path, flags = "", shared = true }
                knownPaths[string.lower(path)] = true
            end
        end
    end
end

-- WoW cannot access Reddit from Lua. This small, reviewable catalog is bundled with the addon.
-- Scores are snapshots from the linked threads, not live values.
local function WowheadMacro(classKey, classSlug, specSlug, specLabel, name, body, note)
    return {
        name = name, class = classKey, spec = specLabel, icon = "Interface\\Icons\\INV_Misc_QuestionMark",
        body = body, detail = specLabel .. " · Wowhead", score = 76,
        source = "https://www.wowhead.com/guide/classes/" .. classSlug .. "/" .. specSlug .. "/addons-macro-ui-imports",
        note = note,
    }
end

local INTERNET_MACROS = {
    {
        name = "Rescue Mouseover", class = "EVOKER", icon = "Interface\\Icons\\Ability_Evoker_Rescue",
        body = "#showtooltip Rescue\n/cast [@mouseover,help,nodead][] Rescue",
        detail = "239 upvotes · Evoker", score = 239,
        source = "https://reddit.com/r/wow/comments/102x6y8/",
        note = "Rescue the friendly unit under your cursor; otherwise use your normal target.",
    },
    {
        name = "Cursor Cast", icon = "Interface\\Icons\\Spell_Shadow_Shadowfury",
        body = "#showtooltip\n/cast [@cursor] SPELL NAME",
        detail = "119 upvotes · Template", score = 119,
        source = "https://reddit.com/r/wow/comments/102x6y8/",
        note = "Replace SPELL NAME. Skips the green targeting circle for ground-targeted abilities.",
    },
    {
        name = "Top Trinket", icon = "Interface\\Icons\\INV_Jewelry_Talisman_07",
        body = "#showtooltip\n/use 13",
        detail = "96 upvotes · Utility", score = 96,
        source = "https://reddit.com/r/wow/comments/102x6y8/",
        note = "Uses the trinket equipped in the upper trinket slot. Use 14 for the lower slot.",
    },
    {
        name = "Volume Toggle", icon = "Interface\\Icons\\INV_Misc_Horn_01",
        body = "/run local v=GetCVar(\"Sound_MasterVolume\"); SetCVar(\"Sound_MasterVolume\",v==\"1\" and .2 or 1)",
        detail = "45 upvotes · Quality of life", score = 45,
        source = "https://reddit.com/r/wow/comments/102x6y8/",
        note = "Toggles master volume between 100% and 20%.",
    },
    {
        name = "Modifier Stack", icon = "Interface\\Icons\\INV_Misc_Note_01",
        body = "#showtooltip\n/cast [mod:alt] SPELL B; [mod:shift] SPELL C; [mod:ctrl] SPELL D; SPELL A",
        detail = "21 upvotes · Template", score = 21,
        source = "https://reddit.com/r/wow/comments/102x6y8/",
        note = "Replace the four spell names to place several abilities on one keybind.",
    },
    {
        name = "Healthstone", icon = "Interface\\Icons\\INV_Stone_04",
        body = "#showtooltip Healthstone\n/stopcasting\n/use Healthstone",
        detail = "Community favorite · Survival", score = 5,
        source = "https://reddit.com/r/wow/comments/102x6y8/",
        note = "Stops the current cast before using a Healthstone. Review before use on a healer.",
    },
    {
        name = "Shadow Word: Death Focus", class = "PRIEST", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
        body = "#showtooltip Shadow Word: Death\n/cast [@focus,harm,nodead] Shadow Word: Death",
        detail = "Shadow Priest · Focus interrupt", score = 90,
        source = "Community template", note = "Casts Shadow Word: Death on your focus target.",
    },
    {
        name = "Vampiric Touch Mouseover", class = "PRIEST", icon = "Interface\\Icons\\Spell_Holy_Stoicism",
        body = "#showtooltip Vampiric Touch\n/cast [@mouseover,harm,nodead][] Vampiric Touch",
        detail = "Shadow Priest · DoT", score = 80,
        source = "Community template", note = "Applies Vampiric Touch to a hostile mouseover or your target.",
    },
    {
        name = "Devouring Plague", class = "PRIEST", icon = "Interface\\Icons\\Spell_Shadow_DevouringPlague",
        body = "#showtooltip Devouring Plague\n/cast [harm,nodead] Devouring Plague",
        detail = "Shadow Priest · Core", score = 70,
        source = "Community template", note = "A compact Devouring Plague button for Shadow Priests.",
    },
    { name = "Death Grip Focus", class = "DEATHKNIGHT", icon = "Interface\\Icons\\Spell_DeathKnight_Strangulate", body = "#showtooltip Death Grip\n/cast [@focus,harm,nodead][] Death Grip", detail = "Death Knight · Focus control", score = 85, source = "Community template", note = "Grips your hostile focus, otherwise your current target." },
    { name = "Sigil at Cursor", class = "DEMONHUNTER", icon = "Interface\\Icons\\Ability_DemonHunter_SigilOfFlame", body = "#showtooltip Sigil of Flame\n/cast [@cursor] Sigil of Flame", detail = "Demon Hunter · Fast ground cast", score = 85, source = "Community template", note = "Places Sigil of Flame at the cursor without the targeting circle." },
    { name = "Rebirth Mouseover", class = "DRUID", icon = "Interface\\Icons\\Spell_Nature_Reincarnation", body = "#showtooltip Rebirth\n/cast [@mouseover,help,dead][] Rebirth", detail = "Druid · Battle resurrection", score = 90, source = "Community template", note = "Battle-resurrects a dead friendly mouseover." },
    { name = "Trap at Cursor", class = "HUNTER", icon = "Interface\\Icons\\Spell_Frost_ChainsOfIce", body = "#showtooltip Freezing Trap\n/cast [@cursor] Freezing Trap", detail = "Hunter · Fast trap", score = 92, source = "Community template", note = "Drops Freezing Trap instantly at the cursor." },
    { name = "Counterspell Focus", class = "MAGE", icon = "Interface\\Icons\\Spell_Frost_IceShock", body = "#showtooltip Counterspell\n/cast [@focus,harm,nodead][] Counterspell", detail = "Mage · Focus interrupt", score = 90, source = "Community template", note = "Interrupts your hostile focus, otherwise your current target." },
    { name = "Tiger's Lust Mouseover", class = "MONK", icon = "Interface\\Icons\\Ability_Monk_TigersLust", body = "#showtooltip Tiger's Lust\n/cast [@mouseover,help,nodead][] Tiger's Lust", detail = "Monk · Utility", score = 84, source = "Community template", note = "Casts Tiger's Lust on a friendly mouseover." },
    { name = "Freedom Mouseover", class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_SealOfValor", body = "#showtooltip Blessing of Freedom\n/cast [@mouseover,help,nodead][] Blessing of Freedom", detail = "Paladin · Utility", score = 92, source = "Community template", note = "Casts Blessing of Freedom on a friendly mouseover." },
    { name = "Tricks Mouseover", class = "ROGUE", icon = "Interface\\Icons\\Ability_Rogue_TricksOftheTrade", body = "#showtooltip Tricks of the Trade\n/cast [@mouseover,help,nodead][] Tricks of the Trade", detail = "Rogue · Threat utility", score = 84, source = "Community template", note = "Casts Tricks of the Trade on a friendly mouseover." },
    { name = "Wind Shear Focus", class = "SHAMAN", icon = "Interface\\Icons\\Spell_Nature_Cyclone", body = "#showtooltip Wind Shear\n/cast [@focus,harm,nodead][] Wind Shear", detail = "Shaman · Focus interrupt", score = 92, source = "Community template", note = "Interrupts your hostile focus, otherwise your target." },
    { name = "Soulstone Mouseover", class = "WARLOCK", icon = "Interface\\Icons\\Spell_Shadow_SoulGem", body = "#showtooltip Soulstone\n/use [@mouseover,help][] Soulstone", detail = "Warlock · Resurrection", score = 88, source = "Community template", note = "Uses Soulstone on a friendly mouseover or your target." },
    { name = "Intervene Mouseover", class = "WARRIOR", icon = "Interface\\Icons\\Ability_Warrior_VictoryRush", body = "#showtooltip Intervene\n/cast [@mouseover,help,nodead][] Intervene", detail = "Warrior · Utility", score = 84, source = "Community template", note = "Intervenes to a friendly mouseover." },

    -- A concise selection from Wowhead's current per-specialization macro guides.
    WowheadMacro("DEATHKNIGHT", "death-knight", "blood", "Blood", "Focus Mind Freeze", "#showtooltip Mind Freeze\n/cast [@focus,harm,nodead][] Mind Freeze", "Interrupts a hostile focus and falls back to the current target."),
    WowheadMacro("DEATHKNIGHT", "death-knight", "frost", "Frost", "Pillar Obliterate", "#showtooltip Pillar of Frost\n/cast Pillar of Frost\n/cast Obliterate\n/cast Raise Dead", "Combines Pillar of Frost with the guide's Obliterate and Raise Dead sequence."),
    WowheadMacro("DEATHKNIGHT", "death-knight", "unholy", "Unholy", "Army Burst Setup", "#showtooltip Army of the Dead\n/cast Army of the Dead\n/use Tempered Potion\n/use 13\n/cast Dark Transformation", "Combines the guide's Army opener, potion, upper trinket, and Dark Transformation."),

    WowheadMacro("DEMONHUNTER", "demon-hunter", "devourer", "Devourer", "Void Metamorphosis Trinket", "#showtooltip Void Metamorphosis\n/cast Void Metamorphosis\n/use 13", "Activates Void Metamorphosis with the upper trinket."),
    WowheadMacro("DEMONHUNTER", "demon-hunter", "havoc", "Havoc", "Metamorphosis Self", "#showtooltip Metamorphosis\n/cast [@player] Metamorphosis", "Places Metamorphosis directly beneath your character."),
    WowheadMacro("DEMONHUNTER", "demon-hunter", "vengeance", "Vengeance", "Sigil of Flame Cursor", "#showtooltip Sigil of Flame\n/cast [@cursor] Sigil of Flame", "Places Sigil of Flame instantly at the cursor."),

    WowheadMacro("DRUID", "druid", "balance", "Balance", "Innervate Mouseover", "#showtooltip Innervate\n/cast [@mouseover,help,nodead][] Innervate", "Casts Innervate on a living friendly mouseover or the normal target."),
    WowheadMacro("DRUID", "druid", "feral", "Feral", "Berserk Burst", "#showtooltip Berserk\n/use Berserk\n/use Tiger's Fury\n/use 13\n/use Tempered Potion", "Combines the guide's Berserk, Tiger's Fury, trinket, and potion setup."),
    WowheadMacro("DRUID", "druid", "guardian", "Guardian", "Incarnation Trinket", "#showtooltip Incarnation: Guardian of Ursoc\n/use 13\n/cast Incarnation: Guardian of Ursoc", "Uses the upper trinket with Incarnation: Guardian of Ursoc."),
    WowheadMacro("DRUID", "druid", "restoration", "Restoration", "Rejuvenation Mouseover", "#showtooltip Rejuvenation\n/cast [@mouseover,help,nodead][] Rejuvenation", "Casts Rejuvenation on a living friendly mouseover or normal target."),

    WowheadMacro("EVOKER", "evoker", "augmentation", "Augmentation", "Prescience Mouseover", "#showtooltip Prescience(Bronze)\n/cast [@mouseover,help,nodead][] Prescience(Bronze)", "Casts Prescience on a living friendly mouseover or normal target."),
    WowheadMacro("EVOKER", "evoker", "devastation", "Devastation", "Dragonrage Cancel Deep Breath", "#showtooltip Dragonrage\n/cancelaura Deep Breath\n/cast Dragonrage", "Cancels Deep Breath before activating Dragonrage."),
    WowheadMacro("EVOKER", "evoker", "preservation", "Preservation", "Preservation Major Cooldown", "#showtooltip [known:Stasis] Stasis; [known:Dream Flight] Dream Flight; Dragonrage\n/use 13\n/use 14\n/cast [known:Stasis] Stasis; [known:Dream Flight] Dream Flight; Dragonrage", "Chooses the known major cooldown and activates available trinkets."),

    WowheadMacro("HUNTER", "hunter", "beast-mastery", "Beast Mastery", "Kill Command Pet Attack", "#showtooltip Kill Command\n/petattack\n/cast Kill Command", "Orders the pet to attack whenever Kill Command is used."),
    WowheadMacro("HUNTER", "hunter", "marksmanship", "Marksmanship", "Disengage Stopcast", "#showtooltip Disengage\n/stopcasting [nochanneling:Rapid Fire]\n/use Disengage", "Stops other casts for Disengage without cancelling Rapid Fire."),
    WowheadMacro("HUNTER", "hunter", "survival", "Survival", "Protected Turtle", "#showtooltip Aspect of the Turtle\n/cast !Aspect of the Turtle", "Prevents repeated presses from cancelling Aspect of the Turtle."),

    WowheadMacro("MAGE", "mage", "arcane", "Arcane", "Arcane Surge Trinket", "#showtooltip Arcane Surge\n/use 13\n/cast Arcane Surge\n/cqs", "Uses the upper trinket with Arcane Surge and clears queued spell input."),
    WowheadMacro("MAGE", "mage", "fire", "Fire", "Combustion Trinket", "#showtooltip Combustion\n/use 13\n/cast Combustion", "Uses the upper trinket with Combustion."),
    WowheadMacro("MAGE", "mage", "frost", "Frost", "Blizzard Cursor", "#showtooltip Blizzard\n/cast [@cursor] Blizzard", "Places Blizzard instantly at the cursor."),

    WowheadMacro("MONK", "monk", "brewmaster", "Brewmaster", "Ring of Peace Cursor", "#showtooltip Ring of Peace\n/cast [@cursor] Ring of Peace", "Places Ring of Peace instantly at the cursor."),
    WowheadMacro("MONK", "monk", "mistweaver", "Mistweaver", "Soothing Mist Mouseover", "#showtooltip Soothing Mist\n/cast [@mouseover,help,nodead][] Soothing Mist", "Casts Soothing Mist on a living friendly mouseover or normal target."),
    WowheadMacro("MONK", "monk", "windwalker", "Windwalker", "Focus Spear Hand Strike", "#showtooltip Spear Hand Strike\n/cast [@focus,harm,nodead][] Spear Hand Strike", "Interrupts a hostile focus and falls back to the current target."),

    WowheadMacro("PALADIN", "paladin", "holy", "Holy", "Holy Shock Mouseover", "#showtooltip Holy Shock\n/cast [@mouseover,exists][] Holy Shock", "Casts Holy Shock on the mouseover or normal target."),
    WowheadMacro("PALADIN", "paladin", "protection", "Protection", "Avenging Wrath Trinket", "#showtooltip Avenging Wrath\n/use 13\n/cast Avenging Wrath", "Uses the upper trinket with Avenging Wrath."),
    WowheadMacro("PALADIN", "paladin", "retribution", "Retribution", "Focus Rebuke", "#showtooltip Rebuke\n/cast [@focus,harm,nodead][] Rebuke", "Interrupts a hostile focus and falls back to the current target."),

    WowheadMacro("PRIEST", "priest", "discipline", "Discipline", "Smite Mouseover", "#showtooltip Smite\n/cast [@mouseover,harm,nodead,nochanneling:Penance,nochanneling:Dark Reprimand][nochanneling:Penance,nochanneling:Dark Reprimand] Smite", "Casts Smite at a hostile mouseover without cancelling Penance or Dark Reprimand."),
    WowheadMacro("PRIEST", "priest", "holy", "Holy", "Flash Heal Mouseover", "#showtooltip Flash Heal\n/cast [@mouseover,help,nodead][] Flash Heal", "Casts Flash Heal on a living friendly mouseover or normal target."),
    WowheadMacro("PRIEST", "priest", "shadow", "Shadow", "Shadow Word: Pain Mouseover", "#showtooltip Shadow Word: Pain\n/cast [@mouseover,harm,nodead][] Shadow Word: Pain", "Applies Shadow Word: Pain to a hostile mouseover or normal target."),

    WowheadMacro("ROGUE", "rogue", "assassination", "Assassination", "Deathmark Trinket", "#showtooltip Deathmark\n/use Deathmark\n/use 13", "Uses Deathmark with the upper trinket."),
    WowheadMacro("ROGUE", "rogue", "outlaw", "Outlaw", "Grappling Hook Cursor", "#showtooltip Grappling Hook\n/cast [@cursor] Grappling Hook", "Places Grappling Hook instantly at the cursor."),
    WowheadMacro("ROGUE", "rogue", "subtlety", "Subtlety", "Coup or Black Powder", "#showtooltip\n/cast Coup de Grace\n/cast Black Powder", "Attempts Coup de Grace, then falls back to Black Powder when unavailable."),

    WowheadMacro("SHAMAN", "shaman", "elemental", "Elemental", "Ascendance Burst", "#showtooltip Ascendance\n/use Ascendance\n/use 13\n/use Ancestral Swiftness\n/use Nature's Swiftness\n/use Tempered Potion", "Combines the guide's Ascendance burst actions with the upper trinket."),
    WowheadMacro("SHAMAN", "shaman", "enhancement", "Enhancement", "Healing Surge Self", "#showtooltip Healing Surge\n/cast [@player] Healing Surge", "Casts Healing Surge directly on yourself."),
    WowheadMacro("SHAMAN", "shaman", "restoration", "Restoration", "Riptide Mouseover", "#showtooltip Riptide\n/cast [@mouseover,help,nodead][] Riptide", "Applies the guide's mouseover-heal template to Riptide."),

    WowheadMacro("WARLOCK", "warlock", "affliction", "Affliction", "Soulstone Mouseover", "#showtooltip Soulstone\n/cast [@mouseover,exists][] Soulstone", "Uses Soulstone on the mouseover or normal target."),
    WowheadMacro("WARLOCK", "warlock", "demonology", "Demonology", "Shadowfury Cursor", "#showtooltip Shadowfury\n/cast [@cursor] Shadowfury", "Places Shadowfury instantly at the cursor."),
    WowheadMacro("WARLOCK", "warlock", "destruction", "Destruction", "Immolate Mouseover", "#showtooltip Immolate\n/cast [@mouseover,harm,nodead][] Immolate", "Applies Immolate to a hostile mouseover or normal target."),

    WowheadMacro("WARRIOR", "warrior", "arms", "Arms", "Stance Selector", "#showtooltip\n/cast [stance:2] !Defensive Stance; [known:386164] !Battle Stance; [known:386196] !Berserker Stance", "Selects the appropriate known stance without toggling it off."),
    WowheadMacro("WARRIOR", "warrior", "fury", "Fury", "Charge Victory Rush", "#showtooltip\n/cast Charge\n/cast Victory Rush\n/cancelaura Bladestorm", "Uses Charge or Victory Rush and permits cancelling Bladestorm."),
    WowheadMacro("WARRIOR", "warrior", "protection", "Protection", "Avatar Trinket", "#showtooltip Avatar\n/use 13\n/cast Avatar", "Uses the upper trinket with Avatar."),
}

local CLASS_ORDER = { "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR" }
local CLASS_LABELS = { DEATHKNIGHT = "Death Knight", DEMONHUNTER = "Demon Hunter", DRUID = "Druid", EVOKER = "Evoker", HUNTER = "Hunter", MAGE = "Mage", MONK = "Monk", PALADIN = "Paladin", PRIEST = "Priest", ROGUE = "Rogue", SHAMAN = "Shaman", WARLOCK = "Warlock", WARRIOR = "Warrior" }

local frame, mainArea, settingsPage, listPane, editorPane, rows, statusText, listScroll
local macroName, macroBody, bodyLabel, iconPreview, sourceBox, sourceLabel, noteText, editorFontValue
local editorTitle, editorHint, saveButton, deleteButton, classButton, classMenu
local modernSkinButton, classicSkinButton, headerLine
local rowButtons, tabs, styledFrames, styledText, fontObjects = {}, {}, {}, {}, {}
local selectedRecord, selectedIcon, activeSource = nil, nil, "account"
local settingsRefreshing = false
local function NotifySharedSettings()
    if RevathsEnchantedFrames_RefreshSettings then RevathsEnchantedFrames_RefreshSettings() end
end
local selectedInternetClass
local pendingScale, scaleDragging, scaleCommitToken
local iconPopup, iconButtons, iconChoices, iconScrollBar = nil, {}, {}, nil
local SelectSource

local function Color(role) return unpack(COLORS[role]) end

local function ApplyFrameBackdrop(object)
    local role = object.styleRole or "panel"
    local classic = ns.db and ns.db.skin == "classic"
    if classic and (role == "background" or role == "panel" or role == "parchment") then
        local outer = role == "background"
        object:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize = outer and 32 or role == "panel" and 22 or 18,
            insets = { left = outer and 11 or role == "panel" and 7 or 6, right = outer and 11 or role == "panel" and 7 or 6, top = outer and 11 or role == "panel" and 7 or 6, bottom = outer and 11 or role == "panel" and 7 or 6 },
        })
        if not object.classicTexture then
            object.classicTexture = object:CreateTexture(nil, "BACKGROUND", nil, 1)
            object.classicTexture:SetPoint("TOPLEFT", 7, -7)
            object.classicTexture:SetPoint("BOTTOMRIGHT", -7, 7)
        end
        if role == "parchment" then
            object.classicTexture:SetTexture("Interface\\QuestFrame\\QuestBG")
            object.classicTexture:SetTexCoord(0, 0.5859375, 0, 0.65625)
            object.classicTexture:SetVertexColor(0.12, 0.105, 0.085, 0.96)
        else
            object.classicTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
            object.classicTexture:SetTexCoord(0, 1, 0, 1)
            object.classicTexture:SetVertexColor(0.40, 0.32, 0.20, 0.44)
        end
        object.classicTexture:Show()
    elseif classic and object.isMacroRow then
        object:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        if object:GetNormalTexture() then object:GetNormalTexture():SetTexture(nil) end
        if object:GetPushedTexture() then object:GetPushedTexture():SetTexture(nil) end
        if object:GetHighlightTexture() then object:GetHighlightTexture():SetTexture(nil) end
        if object.classicTexture then object.classicTexture:Hide() end
        object:SetBackdropColor(Color("panelAlt"))
        object:SetBackdropBorderColor(Color(object.selected and "accent" or "border"))
        return
    elseif classic and object.isWorkshopButton then
        object:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        object:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        object:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        object:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        for _, texture in ipairs({ object:GetNormalTexture(), object:GetPushedTexture(), object:GetHighlightTexture() }) do
            if texture then texture:SetTexCoord(0, 0.625, 0, 0.6875) end
        end
        if object:GetNormalTexture() then object:GetNormalTexture():SetVertexColor(0.78, 0.20, 0.08, 1) end
        if object:GetPushedTexture() then object:GetPushedTexture():SetVertexColor(0.58, 0.09, 0.035, 1) end
        if object:GetHighlightTexture() then object:GetHighlightTexture():SetVertexColor(1, 0.72, 0.18, 0.55) end
        if object.classicTexture then object.classicTexture:Hide() end
        object:SetBackdropColor(0, 0, 0, 0)
        object:SetBackdropBorderColor(0, 0, 0, 0)
        return
    else
        object:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = role == "background" and 16 or 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        if object.isWorkshopButton then
            if object:GetNormalTexture() then object:GetNormalTexture():SetTexture(nil) end
            if object:GetPushedTexture() then object:GetPushedTexture():SetTexture(nil) end
            if object:GetHighlightTexture() then object:GetHighlightTexture():SetTexture(nil) end
        end
        if object.classicTexture then object.classicTexture:Hide() end
    end
    object:SetBackdropColor(Color(role))
    object:SetBackdropBorderColor(Color(object.selected and "accent" or "border"))
end

local function RegisterBackdrop(object, role)
    object.styleRole = role or "panel"
    styledFrames[object] = true
    ApplyFrameBackdrop(object)
end

local function Text(parent, size, role, justify)
    local object = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    object.baseSize = size or 12
    object.colorRole = role or "text"
    object:SetFont(STANDARD_TEXT_FONT, object.baseSize, "")
    object:SetTextColor(Color(object.colorRole))
    object:SetJustifyH(justify or "LEFT")
    styledText[object], fontObjects[object] = true, true
    return object
end

local function Button(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button.isWorkshopButton = true
    button:SetSize(width, height)
    RegisterBackdrop(button, "panelAlt")
    button.label = Text(button, 12, "text", "CENTER")
    button.label:SetPoint("CENTER")
    button.label:SetText(label)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(Color("accent")) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(Color(self.selected and "accent" or "border")) end)
    return button
end

local function AddDropdownArrow(button)
    local arrow = button:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(17, 17); arrow:SetPoint("RIGHT", -9, 0)
    local atlasLoaded = arrow.SetAtlas and pcall(arrow.SetAtlas, arrow, "common-dropdown-icon")
    if not atlasLoaded then arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up") end
    button.label:ClearAllPoints(); button.label:SetPoint("LEFT", 10, 0); button.label:SetPoint("RIGHT", -31, 0); button.label:SetJustifyH("CENTER")
    button.dropdownArrow = arrow
end

local function Edit(parent, multiline)
    local object = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    RegisterBackdrop(object, "input")
    object.baseSize = 13
    object:SetFont(STANDARD_TEXT_FONT, 13, "")
    object:SetTextColor(Color("text"))
    object:SetAutoFocus(false)
    object:SetMultiLine(multiline or false)
    object:SetTextInsets(10, 10, 7, 7)
    object:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    fontObjects[object] = true
    return object
end

local function SelectedFont()
    local key = ns.db and ns.db.font or "friz"
    for _, option in ipairs(FONTS) do if option.key == key then return option end end
    return FONTS[1]
end

local function LoadPalette()
    local classic = ns.db and ns.db.skin == "classic"
    local palette = classic and CLASSIC_COLORS or (PALETTES[ns.db and ns.db.palette or "midnight"] or PALETTES.midnight)
    local opacity = math.max(0.60, math.min(1, tonumber(ns.db and ns.db.opacity) or 0.97))
    for role, color in pairs(palette) do
        if role ~= "label" and COLORS[role] then
            COLORS[role][1], COLORS[role][2], COLORS[role][3] = color[1], color[2], color[3]
        end
    end
    COLORS.background[4] = classic and 1 or opacity
    if classic then
        COLORS.panel[4], COLORS.panelAlt[4], COLORS.input[4] = 1, 1, 1
    else
        COLORS.panel[4], COLORS.panelAlt[4], COLORS.input[4] = math.min(1, opacity + 0.02), math.min(1, opacity + 0.03), math.min(1, opacity + 0.03)
    end
    if not classic then
        COLORS.parchment[1], COLORS.parchment[2], COLORS.parchment[3] = COLORS.input[1], COLORS.input[2], COLORS.input[3]
    end
end

local function ApplyAppearance()
    LoadPalette()
    local option = SelectedFont()
    for object in pairs(styledFrames) do
        ApplyFrameBackdrop(object)
    end
    for object in pairs(styledText) do object:SetTextColor(Color(object.colorRole or "text")) end
    for object in pairs(fontObjects) do
        if object and object.SetFont then
            local _, currentSize = object:GetFont()
            local size = object == macroBody and (ns.db and ns.db.fontSize or 13) or object.baseSize or currentSize or 12
            local ok, loaded = pcall(object.SetFont, object, option.path, size, option.flags or "")
            if not ok or loaded == false then object:SetFont(STANDARD_TEXT_FONT, size, "") end
        end
    end
    if editorFontValue and ns.db then editorFontValue:SetText(string.format("%d px", tonumber(ns.db.fontSize) or 13)) end
    if macroBody then macroBody:SetTextColor(Color("text")) end
    if headerLine then headerLine:SetColorTexture(Color("accent")) end
    if modernSkinButton and classicSkinButton and ns.db then
        modernSkinButton.selected = ns.db.skin ~= "classic"
        classicSkinButton.selected = ns.db.skin == "classic"
        modernSkinButton.label:SetText("Modern")
        classicSkinButton.label:SetText("Classic")
        ApplyFrameBackdrop(modernSkinButton); ApplyFrameBackdrop(classicSkinButton)
    end
    if frame and not scaleDragging then frame:SetScale(ns.db and ns.db.scale or 1) end
end

local function ChangeEditorFontSize(delta)
    if not ns.db then return end
    ns.db.fontSize = math.max(10, math.min(24, (tonumber(ns.db.fontSize) or 13) + delta))
    ApplyAppearance()
    NotifySharedSettings()
end

local function PreserveWindowCenterAtScale(value)
    if not frame then return end
    local centerX, centerY = frame:GetCenter()
    frame:SetScale(value)
    if centerX and centerY and UIParent.GetCenter then
        local parentX, parentY = UIParent:GetCenter()
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", centerX - parentX, centerY - parentY)
        if ns.db and ns.db.window then
            ns.db.window.point, ns.db.window.relativePoint = "CENTER", "CENTER"
            ns.db.window.x, ns.db.window.y = centerX - parentX, centerY - parentY
        end
    end
end

local function CommitWindowScale()
    if not pendingScale or not ns.db or not frame then return end
    ns.db.scale = pendingScale
    PreserveWindowCenterAtScale(pendingScale)
    pendingScale = nil
end

local function SetStatus(message, isError)
    if not statusText then return end
    statusText.colorRole = isError and "danger" or "muted"
    statusText:SetTextColor(Color(statusText.colorRole))
    statusText:SetText(message or "")
end

local function SetEditor(record)
    selectedRecord = record
    selectedIcon = record and record.icon or "Interface\\Icons\\INV_Misc_Note_01"
    macroName:SetText(record and record.name or "")
    macroBody:SetText(record and record.body or "")
    iconPreview:SetTexture(selectedIcon)
    sourceBox:SetText(record and record.source or "")
    sourceLabel:SetShown(record ~= nil and record.kind == "internet")
    sourceBox:SetShown(record ~= nil and record.kind == "internet")
    noteText:SetText(record and record.note or "")
    noteText:SetShown(record ~= nil and record.kind == "internet")
    if deleteButton then deleteButton:SetShown(record ~= nil and record.index ~= nil and record.kind ~= "internet") end
    if record then
        SetStatus(record.kind == "internet" and "Community template loaded. Review placeholders before saving." or "Macro loaded and ready to edit.")
    else
        SetStatus(activeSource == "account" and "Ready for a new account macro." or "Ready for a new character macro.")
    end
end

local ICON_COLUMNS, ICON_VISIBLE_ROWS = 10, 9

local function UpdateVisibleIcons()
    if not iconPopup or not iconScrollBar then return end
    local rowOffset = math.floor((iconScrollBar:GetValue() or 0) + 0.5)
    local offset = rowOffset * ICON_COLUMNS
    for index, button in ipairs(iconButtons) do
        local icon = iconChoices[offset + index]
        button.iconValue = icon
        button:SetShown(icon ~= nil)
        if icon then button.icon:SetTexture(icon) end
    end
end

local function BuildIconPicker()
    if iconPopup then return end
    iconPopup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    iconPopup:SetSize(455, 430)
    iconPopup:SetFrameStrata("DIALOG")
    iconPopup:SetClampedToScreen(true)
    RegisterBackdrop(iconPopup, "panel")
    local title = Text(iconPopup, 14, "text")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Choose macro icon")
    local hint = Text(iconPopup, 10, "muted")
    hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    hint:SetText("Scroll through all Blizzard and addon-supplied macro icons")
    local close = Button(iconPopup, "Close", 70, 26)
    close:SetPoint("TOPRIGHT", -12, -10)
    close:SetScript("OnClick", function() iconPopup:Hide() end)
    local grid = CreateFrame("Frame", nil, iconPopup)
    grid:SetPoint("TOPLEFT", 12, -58); grid:SetSize(394, ICON_VISIBLE_ROWS * 39)
    for index = 1, ICON_COLUMNS * ICON_VISIBLE_ROWS do
        local button = CreateFrame("Button", nil, grid, "BackdropTemplate")
        button:SetSize(36, 36); RegisterBackdrop(button, "panelAlt")
        button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetPoint("TOPLEFT", 4, -4); button.icon:SetPoint("BOTTOMRIGHT", -4, 4); button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local column = (index - 1) % ICON_COLUMNS; local row = math.floor((index - 1) / ICON_COLUMNS)
        button:SetPoint("TOPLEFT", 2 + column * 39, -2 - row * 39)
        button:SetScript("OnClick", function(self)
            if not self.iconValue then return end
            selectedIcon = self.iconValue; iconPreview:SetTexture(self.iconValue); iconPopup:Hide(); SetStatus("Icon selected. Save the macro to apply it.")
        end)
        iconButtons[index] = button
    end
    iconScrollBar = CreateFrame("Slider", nil, iconPopup, "UIPanelScrollBarTemplate")
    iconScrollBar:SetPoint("TOPRIGHT", -9, -63); iconScrollBar:SetPoint("BOTTOMRIGHT", -9, 17)
    iconScrollBar:SetValueStep(1); iconScrollBar:SetObeyStepOnDrag(true)
    iconScrollBar:SetScript("OnValueChanged", UpdateVisibleIcons)
    iconPopup:EnableMouseWheel(true)
    iconPopup:SetScript("OnMouseWheel", function(_, delta)
        iconScrollBar:SetValue((iconScrollBar:GetValue() or 0) - delta * 3)
    end)
end

local function RefreshIconPicker()
    BuildIconPicker()
    if #iconChoices == 0 then
        local choices, seen = {}, {}
        local function append(source)
            if type(source) ~= "table" then return end
            for _, value in pairs(source) do
                if type(value) == "table" then value = value.fileID or value.icon or value.texture end
                if value and not seen[value] then choices[#choices + 1] = value; seen[value] = true end
            end
        end
        local macroIcons, itemIcons = {}, {}
        if GetMacroIcons then GetMacroIcons(macroIcons) end
        if GetMacroItemIcons then GetMacroItemIcons(itemIcons) end
        append(macroIcons); append(itemIcons)
        append(GetLooseMacroIcons and GetLooseMacroIcons())
        append(GetLooseMacroItemIcons and GetLooseMacroItemIcons())
        if #choices == 0 then
            choices = {
                "Interface\\Icons\\INV_Misc_QuestionMark", "Interface\\Icons\\INV_Misc_Note_01",
                "Interface\\Icons\\Spell_Shadow_Shadowfury", "Interface\\Icons\\Ability_Evoker_Rescue",
            }
        end
        iconChoices = choices
    end
    local totalRows = math.ceil(#iconChoices / ICON_COLUMNS)
    local maximum = math.max(0, totalRows - ICON_VISIBLE_ROWS)
    iconScrollBar:SetMinMaxValues(0, maximum); iconScrollBar:SetValue(0); iconScrollBar:SetShown(maximum > 0)
    UpdateVisibleIcons()
end

local function ShowIconPicker()
    RefreshIconPicker()
    iconPopup:ClearAllPoints()
    iconPopup:SetPoint("TOPRIGHT", editorPane, "TOPRIGHT", -12, -64)
    iconPopup:Show()
end

local function ClearEditor() SetEditor(nil); macroName:SetFocus() end

local function AccountRecords()
    local result = {}
    local globalCount = select(1, GetNumMacros()) or 0
    for index = 1, globalCount do
        local name, icon, body = GetMacroInfo(index)
        if name then result[#result + 1] = { kind = "account", index = index, name = name, icon = icon, body = body or "", detail = "Account macro" } end
    end
    return result
end

local function CharacterRecords()
    local result = {}
    local characterCount = select(2, GetNumMacros()) or 0
    local offset = MAX_ACCOUNT_MACROS or 120
    for slot = 1, characterCount do
        local index = offset + slot
        local name, icon, body = GetMacroInfo(index)
        if name then result[#result + 1] = { kind = "character", index = index, name = name, icon = icon, body = body or "", detail = "Character macro" } end
    end
    return result
end

local function RecordsForSource()
    if activeSource == "account" then return AccountRecords() end
    if activeSource == "character" then return CharacterRecords() end
    local result = {}
    local playerClass = UnitClass and select(2, UnitClass("player")) or nil
    selectedInternetClass = selectedInternetClass or playerClass or "PRIEST"
    for _, item in ipairs(INTERNET_MACROS) do
        if item.class == nil or item.class == selectedInternetClass then
            local copy = {}
            for key, value in pairs(item) do copy[key] = value end
            copy.kind = "internet"
            copy.classRank = copy.class == selectedInternetClass and 2 or 1
            result[#result + 1] = copy
        end
    end
    table.sort(result, function(a, b)
        if a.classRank ~= b.classRank then return a.classRank > b.classRank end
        return a.score > b.score
    end)
    return result
end

local function RefreshRows()
    for _, row in ipairs(rowButtons) do row:Hide() end
    local records = RecordsForSource()
    local rowHeight = ns.db and ns.db.compactRows and 39 or (activeSource == "internet" and 58 or 49)
    rows:SetHeight(math.max(1, #records * rowHeight))
    for slot, record in ipairs(records) do
        local row = rowButtons[slot]
        if not row then
            row = Button(rows, "", 228, 44)
            row.isMacroRow = true; ApplyFrameBackdrop(row)
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(32, 32); row.icon:SetPoint("LEFT", 6, 0); row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, -1); row.label:SetPoint("RIGHT", -6, 0); row.label:SetHeight(18); row.label:SetJustifyH("LEFT"); row.label:SetWordWrap(false); row.label:SetNonSpaceWrap(false)
            row.detail = Text(row, 10, "muted")
            row.detail:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -1); row.detail:SetPoint("RIGHT", -6, 0); row.detail:SetHeight(14); row.detail:SetJustifyH("LEFT"); row.detail:SetWordWrap(false); row.detail:SetNonSpaceWrap(false)
            rowButtons[slot] = row
        end
        row:SetSize(228, rowHeight - 5); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -((slot - 1) * rowHeight))
        row.label:SetText(record.name); row.detail:SetText(record.detail or ""); row.detail:SetShown(not (ns.db and ns.db.compactRows))
        row.icon:SetTexture(record.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row:SetScript("OnClick", function() SetEditor(record) end)
        row:RegisterForDrag("LeftButton")
        row:SetScript("OnDragStart", function()
            if record.index then
                PickupMacro(record.index)
            else
                SetStatus("Save this community macro first, then drag it to an action bar.", true)
            end
        end)
        row:Show()
    end
    local countLabel = activeSource == "internet" and string.format("%d curated templates", #records) or string.format("%d macros", #records)
    listPane.count:SetText(countLabel)
    if #records == 0 then SetStatus("No macros in this tab yet. Create one in the editor.") end
end

local function SaveMacro()
    local isCharacter = activeSource ~= "account"
    local name = string.gsub(macroName:GetText() or "", "^%s*(.-)%s*$", "%1")
    local body = macroBody:GetText() or ""
    if name == "" then SetStatus("Enter a macro name first.", true); return end
    if body == "" then SetStatus("Enter a macro body first.", true); return end
    if string.find(body, "SPELL NAME", 1, true) or string.find(body, "SPELL A", 1, true) then SetStatus("Replace the template spell names before saving.", true); return end
    local icon = selectedIcon
    if type(icon) == "string" and GetFileIDFromPath then
        local path = string.match(string.lower(icon), "%.blp$") and icon or (icon .. ".blp")
        local fileID = GetFileIDFromPath(path)
        if fileID and fileID > 0 then icon = fileID end
    end
    if type(icon) ~= "number" then icon = 134400 end
    local sameScope = selectedRecord and selectedRecord.index and selectedRecord.kind == (isCharacter and "character" or "account")
    local ok, result
    if sameScope then ok, result = pcall(EditMacro, selectedRecord.index, name, icon, body)
    else ok, result = pcall(CreateMacro, name, icon, body, isCharacter) end
    if ok and result ~= false and result ~= nil then
        local message = sameScope and "Macro updated." or (isCharacter and "Character macro created." or "Account macro created.")
        SelectSource(isCharacter and "character" or "account")
        SetStatus(message)
    else
        SetStatus("The game refused this change. Check macro limits and try outside combat.", true)
    end
end

local function DeleteSelectedMacro()
    if not selectedRecord or not selectedRecord.index or selectedRecord.kind == "internet" then return end
    if InCombatLockdown and InCombatLockdown() then SetStatus("Macros cannot be deleted during combat.", true); return end
    StaticPopup_Show("REVATHS_MACRO_DELETE", selectedRecord.name, nil, selectedRecord)
end

SelectSource = function(source)
    local changed = activeSource ~= source
    activeSource = source; settingsPage:Hide(); mainArea:Show()
    if classMenu then classMenu:Hide() end
    for key, tab in pairs(tabs) do
        tab.selected = key == source
        tab:SetBackdropColor(Color(tab.selected and "accent" or "panelAlt"))
        tab:SetBackdropBorderColor(Color(tab.selected and "accent" or "border"))
    end
    if editorTitle then
        if source == "account" then
            editorTitle:SetText("Account Macro Editor"); editorHint:SetText("Create and edit account-wide macros."); saveButton.label:SetText("Save Account Macro")
        elseif source == "character" then
            editorTitle:SetText("Character Macro Editor"); editorHint:SetText("Create and edit macros for this character."); saveButton.label:SetText("Save Character Macro")
        else
            editorTitle:SetText("Community Macro Editor"); editorHint:SetText("Review a class template before saving it to this character."); saveButton.label:SetText("Save to Character")
        end
        classButton:SetShown(source == "internet")
        listScroll:ClearAllPoints(); listScroll:SetPoint("TOPLEFT", 12, source == "internet" and -86 or -48); listScroll:SetPoint("BOTTOMRIGHT", -28, 12)
        if changed then SetEditor(nil) end
    end
    RefreshRows()
end

local function Slider(parent, label, y, minimum, maximum, step)
    local title = Text(parent, 11, "muted"); title:SetPoint("TOPLEFT", 28, y); title:SetText(label)
    local valueText = Text(parent, 11, "accent2", "RIGHT"); valueText:SetPoint("TOPRIGHT", -28, y); valueText:SetWidth(70)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetPoint("TOPLEFT", 28, y - 25); slider:SetPoint("TOPRIGHT", -28, y - 25); slider:SetHeight(18)
    slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step); slider:SetObeyStepOnDrag(true)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local track = slider:CreateTexture(nil, "BACKGROUND"); track:SetColorTexture(Color("border")); track:SetPoint("LEFT", 2, 0); track:SetPoint("RIGHT", -2, 0); track:SetHeight(4)
    return slider, valueText
end

local function BuildSettings()
    settingsPage = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    settingsPage:SetPoint("TOPLEFT", 22, -108); settingsPage:SetPoint("BOTTOMRIGHT", -22, 24); RegisterBackdrop(settingsPage, "panel")
    local title = Text(settingsPage, 19, "text"); title:SetPoint("TOPLEFT", 24, -22); title:SetText("Appearance settings")
    local hint = Text(settingsPage, 11, "muted"); hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7); hint:SetPoint("RIGHT", -24, 0); hint:SetWordWrap(false); hint:SetText("Choose a skin, font, and transparency. Resize the window from its lower-right corner.")
    local skinTitle = Text(settingsPage, 11, "muted"); skinTitle:SetPoint("TOPLEFT", 28, -82); skinTitle:SetText("WINDOW SKIN")
    modernSkinButton = Button(settingsPage, "Modern", 145, 34); modernSkinButton:SetPoint("TOPLEFT", 28, -103)
    classicSkinButton = Button(settingsPage, "Classic", 145, 34); classicSkinButton:SetPoint("LEFT", modernSkinButton, "RIGHT", 10, 0)
    modernSkinButton:SetScript("OnClick", function() ns.db.skin = "modern"; ApplyAppearance(); settingsPage:Refresh(); NotifySharedSettings() end)
    classicSkinButton:SetScript("OnClick", function() ns.db.skin = "classic"; ApplyAppearance(); settingsPage:Refresh(); NotifySharedSettings() end)
    local paletteTitle = Text(settingsPage, 11, "muted"); paletteTitle:SetPoint("TOPLEFT", 360, -82); paletteTitle:SetText("MODERN COLOR PALETTE")
    local paletteButton = Button(settingsPage, "", 280, 34); paletteButton:SetPoint("TOPLEFT", 360, -103)
    AddDropdownArrow(paletteButton)
    local paletteMenu = CreateFrame("Frame", nil, settingsPage, "BackdropTemplate")
    paletteMenu:SetSize(304, 220); paletteMenu:SetFrameLevel(settingsPage:GetFrameLevel() + 20); paletteMenu:SetClampedToScreen(true); RegisterBackdrop(paletteMenu, "panel"); paletteMenu:Hide()
    local paletteMenuTitle = Text(paletteMenu, 11, "muted"); paletteMenuTitle:SetPoint("TOPLEFT", 12, -10); paletteMenuTitle:SetText("SELECT COLOR PALETTE")
    local paletteOrder = { "midnight", "arcane", "emerald", "crimson", "royal", "graphite" }
    for index, key in ipairs(paletteOrder) do
        local option = PALETTES[key]
        local choice = Button(paletteMenu, option.label, 280, 27); choice:SetPoint("TOPLEFT", 12, -31 - (index - 1) * 29)
        choice:SetScript("OnClick", function()
            ns.db.palette = key; paletteMenu:Hide(); ApplyAppearance(); settingsPage:Refresh(); NotifySharedSettings()
        end)
    end
    paletteButton:SetScript("OnClick", function()
        paletteMenu:ClearAllPoints(); paletteMenu:SetPoint("TOPLEFT", paletteButton, "BOTTOMLEFT", 0, -6); paletteMenu:SetShown(not paletteMenu:IsShown())
    end)
    DiscoverSharedMediaFonts()
    local fontTitle = Text(settingsPage, 11, "muted"); fontTitle:SetPoint("TOPLEFT", 28, -165); fontTitle:SetText("ADDON FONT")
    local fontButton = Button(settingsPage, "", 300, 34); fontButton:SetPoint("TOPLEFT", 28, -186)
    AddDropdownArrow(fontButton)
    local fontMenu = CreateFrame("Frame", nil, settingsPage, "BackdropTemplate")
    fontMenu:SetSize(360, 250); fontMenu:SetFrameLevel(settingsPage:GetFrameLevel() + 20); fontMenu:SetClampedToScreen(true); RegisterBackdrop(fontMenu, "panel"); fontMenu:Hide()
    local fontMenuTitle = Text(fontMenu, 11, "muted"); fontMenuTitle:SetPoint("TOPLEFT", 12, -10); fontMenuTitle:SetText("SELECT FONT")
    local fontMenuButtons = {}
    for index = 1, 10 do
        local button = Button(fontMenu, "", 160, 29)
        local column = (index - 1) % 2; local row = math.floor((index - 1) / 2)
        button:SetPoint("TOPLEFT", 12 + column * 172, -30 - row * 34)
        fontMenuButtons[index] = button
    end
    local fontPrev = Button(fontMenu, "<", 28, 24); fontPrev:SetPoint("BOTTOMLEFT", 12, 10)
    local fontPage = Text(fontMenu, 10, "muted", "CENTER"); fontPage:SetPoint("BOTTOM", 0, 15); fontPage:SetWidth(80)
    local fontNext = Button(fontMenu, ">", 28, 24); fontNext:SetPoint("BOTTOMRIGHT", -12, 10)
    local fontMenuPage = 1
    local function RefreshFontMenu()
        DiscoverSharedMediaFonts()
        local pages = math.max(1, math.ceil(#FONTS / 10)); fontMenuPage = math.max(1, math.min(fontMenuPage, pages)); fontPage:SetText(string.format("%d / %d", fontMenuPage, pages))
        local start = (fontMenuPage - 1) * 10
        for index, button in ipairs(fontMenuButtons) do
            local option = FONTS[start + index]
            button:SetShown(option ~= nil)
            if option then
                button.label:SetText(option.label)
                button.label:SetFont(option.path, 11, option.flags or "")
                button.selected = option.key == ns.db.font
                ApplyFrameBackdrop(button)
                button:SetScript("OnClick", function()
                    ns.db.font = option.key; fontMenu:Hide(); settingsPage:Refresh(); ApplyAppearance(); NotifySharedSettings()
                end)
            end
        end
        fontPrev:SetEnabled(fontMenuPage > 1); fontNext:SetEnabled(fontMenuPage < pages)
    end
    fontPrev:SetScript("OnClick", function() fontMenuPage = fontMenuPage - 1; RefreshFontMenu() end)
    fontNext:SetScript("OnClick", function() fontMenuPage = fontMenuPage + 1; RefreshFontMenu() end)
    fontButton:SetScript("OnClick", function()
        RefreshFontMenu(); fontMenu:ClearAllPoints(); fontMenu:SetPoint("TOPLEFT", fontButton, "BOTTOMLEFT", 0, -6); fontMenu:Show()
    end)

    local opacity, opacityValue = Slider(settingsPage, "WINDOW OPACITY", -263, 0.55, 1, 0.05)
    opacity:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value * 20 + 0.5) / 20; opacityValue:SetText(string.format("%d%%", value * 100))
        if not settingsRefreshing then ns.db.opacity = value; ApplyAppearance(); NotifySharedSettings() end
    end)
    local version = Text(settingsPage, 11, "muted", "RIGHT"); version:SetPoint("BOTTOMRIGHT", -28, 31); version:SetText("Revath's Enchanted Macros  ·  " .. tostring(ns.version))
    function settingsPage:Refresh()
        settingsRefreshing = true
        local palette = PALETTES[ns.db.palette] or PALETTES.midnight
        paletteButton.label:SetText(palette.label)
        fontButton.label:SetText(SelectedFont().label); opacity:SetValue(ns.db.opacity); RefreshFontMenu()
        settingsRefreshing = false; ApplyAppearance()
    end
    settingsPage:Hide()
end

local function BuildUI()
    frame = CreateFrame("Frame", "RevathsMacroFrame", UIParent, "BackdropTemplate")
    local savedWidth = math.max(820, tonumber(ns.db.window.width) or 980)
    local savedHeight = math.max(640, tonumber(ns.db.window.height) or 640)
    frame:SetSize(savedWidth, savedHeight)
    if ns.db.window.x and ns.db.window.y then
        frame:SetPoint(ns.db.window.point or "CENTER", UIParent, ns.db.window.relativePoint or "CENTER", ns.db.window.x, ns.db.window.y)
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("HIGH"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(820, 640, 2400, 1800) end
    frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        ns.db.window.point, ns.db.window.relativePoint, ns.db.window.x, ns.db.window.y = point, relativePoint, x, y
    end)
    RegisterBackdrop(frame, "background")
    local close = Button(frame, "×", 32, 30); close:SetPoint("TOPRIGHT", -15, -15); close:SetScript("OnClick", function() frame:Hide() end)
    local settings = Button(frame, "Settings", 76, 30); settings:SetPoint("RIGHT", close, "LEFT", -7, 0)
    local title = Text(frame, 22, "text"); title:SetPoint("TOPLEFT", 24, -18); title:SetText("REVATH'S")
    local titleAccent = Text(frame, 22, "accent"); titleAccent:SetPoint("LEFT", title, "RIGHT", 6, 0); titleAccent:SetPoint("RIGHT", settings, "LEFT", -18, 0); titleAccent:SetWordWrap(false); titleAccent:SetText("ENCHANTED MACROS")
    local subtitle = Text(frame, 10, "muted"); subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -4); subtitle:SetPoint("RIGHT", settings, "LEFT", -18, 0); subtitle:SetWordWrap(false); subtitle:SetText("ACCOUNT, CHARACTER, AND COMMUNITY MACROS")
    headerLine = frame:CreateTexture(nil, "ARTWORK"); headerLine:SetHeight(2); headerLine:SetPoint("TOPLEFT", 22, -61); headerLine:SetPoint("RIGHT", -22, 0); headerLine:SetColorTexture(Color("accent")); headerLine:SetAlpha(0.45)
    settings:SetScript("OnClick", function()
        if settingsPage:IsShown() then SelectSource(activeSource) else mainArea:Hide(); settingsPage:Show(); settingsPage:Refresh() end
    end)

    tabs = {}
    local tabSpecs = {
        { key = "account", label = "Account Macros", width = 145 }, { key = "character", label = "Character Macros", width = 155 },
        { key = "internet", label = "From the Internet", width = 155 },
    }
    local previous
    for _, spec in ipairs(tabSpecs) do
        local tab = Button(frame, spec.label, spec.width, 31)
        if previous then tab:SetPoint("LEFT", previous, "RIGHT", 7, 0) else tab:SetPoint("TOPLEFT", 22, -70) end
        tab:SetScript("OnClick", function() SelectSource(spec.key) end); tabs[spec.key], previous = tab, tab
    end

    mainArea = CreateFrame("Frame", nil, frame); mainArea:SetPoint("TOPLEFT", 22, -108); mainArea:SetPoint("BOTTOMRIGHT", -22, 24)
    listPane = CreateFrame("Frame", nil, mainArea, "BackdropTemplate"); listPane:SetPoint("TOPLEFT"); listPane:SetPoint("BOTTOMLEFT"); listPane:SetWidth(270); RegisterBackdrop(listPane, "panel")
    local listTitle = Text(listPane, 14, "text"); listTitle:SetPoint("TOPLEFT", 16, -16); listTitle:SetText("MACROS")
    listPane.count = Text(listPane, 10, "muted", "RIGHT"); listPane.count:SetPoint("TOPRIGHT", -16, -19); listPane.count:SetWidth(120)
    local _, playerClass = UnitClass("player"); selectedInternetClass = playerClass or "PRIEST"
    classButton = Button(listPane, "", 228, 29); classButton:SetPoint("TOPLEFT", 12, -48); classButton.label:SetText("Class: " .. (CLASS_LABELS[selectedInternetClass] or selectedInternetClass)); classButton:Hide()
    classMenu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate"); classMenu:SetSize(360, 260); classMenu:SetFrameStrata("DIALOG"); classMenu:SetClampedToScreen(true); RegisterBackdrop(classMenu, "panel"); classMenu:Hide()
    local classTitle = Text(classMenu, 11, "muted"); classTitle:SetPoint("TOPLEFT", 12, -10); classTitle:SetText("SELECT CLASS")
    for index, classKey in ipairs(CLASS_ORDER) do
        local choice = Button(classMenu, CLASS_LABELS[classKey], 162, 27)
        local column = (index - 1) % 2; local row = math.floor((index - 1) / 2)
        choice:SetPoint("TOPLEFT", 12 + column * 174, -32 - row * 31)
        choice:SetScript("OnClick", function()
            selectedInternetClass = classKey; classButton.label:SetText("Class: " .. CLASS_LABELS[classKey]); classMenu:Hide(); SetEditor(nil); RefreshRows()
        end)
    end
    classButton:SetScript("OnClick", function()
        classMenu:ClearAllPoints(); classMenu:SetPoint("TOPLEFT", classButton, "BOTTOMLEFT", 0, -4); classMenu:SetShown(not classMenu:IsShown())
    end)
    listScroll = CreateFrame("ScrollFrame", nil, listPane, "UIPanelScrollFrameTemplate"); listScroll:SetPoint("TOPLEFT", 12, -48); listScroll:SetPoint("BOTTOMRIGHT", -28, 12)
    rows = CreateFrame("Frame", nil, listScroll); rows:SetSize(228, 1); listScroll:SetScrollChild(rows)

    editorPane = CreateFrame("Frame", nil, mainArea, "BackdropTemplate"); editorPane:SetPoint("TOPLEFT", listPane, "TOPRIGHT", 14, 0); editorPane:SetPoint("BOTTOMRIGHT"); RegisterBackdrop(editorPane, "panel")
    local iconCard = CreateFrame("Frame", nil, editorPane, "BackdropTemplate"); iconCard:SetSize(50, 50); iconCard:SetPoint("TOPRIGHT", -20, -18); RegisterBackdrop(iconCard, "panelAlt")
    iconPreview = iconCard:CreateTexture(nil, "ARTWORK"); iconPreview:SetPoint("TOPLEFT", 4, -4); iconPreview:SetPoint("BOTTOMRIGHT", -4, 4); iconPreview:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    editorTitle = Text(editorPane, 18, "text"); editorTitle:SetPoint("TOPLEFT", 20, -18); editorTitle:SetPoint("RIGHT", iconCard, "LEFT", -16, 0); editorTitle:SetWordWrap(false); editorTitle:SetText("Account Macro Editor")
    editorHint = Text(editorPane, 11, "muted"); editorHint:SetPoint("TOPLEFT", editorTitle, "BOTTOMLEFT", 0, -6); editorHint:SetPoint("RIGHT", iconCard, "LEFT", -16, 0); editorHint:SetWordWrap(false); editorHint:SetText("Create and edit account-wide macros.")
    local iconButton = Button(editorPane, "Change icon", 96, 25)
    iconButton:SetPoint("TOPRIGHT", -20, -66)
    iconButton:SetScript("OnClick", ShowIconPicker)
    local nameLabel = Text(editorPane, 11, "muted"); nameLabel:SetPoint("TOPLEFT", 20, -70); nameLabel:SetPoint("RIGHT", iconButton, "LEFT", -12, 0); nameLabel:SetWordWrap(false); nameLabel:SetText("MACRO NAME")
    macroName = Edit(editorPane); macroName:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -6); macroName:SetPoint("RIGHT", iconButton, "LEFT", -12, 0); macroName:SetHeight(35); macroName:SetMaxLetters(16)
    bodyLabel = Text(editorPane, 11, "muted"); bodyLabel:SetPoint("TOPLEFT", 20, -128); bodyLabel:SetPoint("RIGHT", -145, 0); bodyLabel:SetWordWrap(false); bodyLabel:SetText("MACRO BODY")
    local fontMinus = Button(editorPane, "-", 27, 23); fontMinus:SetPoint("TOPRIGHT", -57, -111)
    editorFontValue = Text(editorPane, 10, "accent2", "RIGHT"); editorFontValue:SetPoint("RIGHT", fontMinus, "LEFT", -7, 0); editorFontValue:SetWidth(40)
    local fontPlus = Button(editorPane, "+", 27, 23); fontPlus:SetPoint("TOPRIGHT", -20, -111)
    fontMinus:SetScript("OnClick", function() ChangeEditorFontSize(-1) end); fontPlus:SetScript("OnClick", function() ChangeEditorFontSize(1) end)
    macroBody = Edit(editorPane, true); macroBody.styleRole = "parchment"; ApplyFrameBackdrop(macroBody); macroBody:SetPoint("TOPLEFT", bodyLabel, "BOTTOMLEFT", 0, -6); macroBody:SetPoint("BOTTOMRIGHT", -20, 139); macroBody:SetMaxLetters(255)
    local suggestionPopup = CreateFrame("Frame", nil, editorPane, "BackdropTemplate"); suggestionPopup:SetSize(500, 224); suggestionPopup:SetFrameLevel(editorPane:GetFrameLevel() + 10); RegisterBackdrop(suggestionPopup, "panel"); suggestionPopup:Hide()
    local suggestionTitle = Text(suggestionPopup, 14, "muted"); suggestionTitle:SetPoint("TOPLEFT", 12, -10); suggestionTitle:SetText("SYNTAX HELP  ·  TAB: SELECT  ·  ENTER: INSERT")
    local suggestionHint = Text(suggestionPopup, 16, "muted"); suggestionHint:SetPoint("TOPLEFT", 16, -52); suggestionHint:SetWidth(440); suggestionHint:SetText("Start typing spell name"); suggestionHint:Hide()
    local suggestionSyntax = Text(suggestionPopup, 14, "accent2"); suggestionSyntax:SetPoint("BOTTOMLEFT", 14, 10); suggestionSyntax:SetPoint("RIGHT", -14, 0); suggestionSyntax:SetHeight(40); suggestionSyntax:SetWordWrap(true); suggestionSyntax:SetJustifyV("BOTTOM"); suggestionSyntax:SetText("Syntax:\n/castsequence [conditions] reset=target/combat/5 Spell One, Spell Two"); suggestionSyntax:Hide()
    local caretMeasure = macroBody:CreateFontString(nil, "OVERLAY"); caretMeasure:SetAlpha(0); caretMeasure:SetPoint("TOPLEFT", macroBody, "TOPLEFT")
    local commandCatalog = {
        { "/cast ", "Cast a spell" }, { "/castsequence ", "Cast spells in sequence" }, { "/castrandom ", "Cast one listed spell" },
        { "/use ", "Use an item or spell" }, { "/userandom ", "Use one listed item" }, { "/stopcasting", "Stop the current cast" },
        { "/cancelaura ", "Cancel one of your auras" }, { "/startattack", "Begin attacking" }, { "/stopattack", "Stop attacking" },
        { "/target ", "Target by unit or name" }, { "/targetexact ", "Target an exact name" }, { "/targetenemy", "Cycle hostile targets" },
        { "/targetenemyplayer", "Cycle hostile players" }, { "/targetfriend", "Cycle friendly targets" }, { "/targetfriendplayer", "Cycle friendly players" },
        { "/targetlasttarget", "Restore previous target" }, { "/targetlastenemy", "Restore previous enemy" }, { "/targetlastfriend", "Restore previous friend" },
        { "/focus ", "Set your focus target" }, { "/clearfocus", "Clear focus" }, { "/cleartarget", "Clear target" }, { "/assist ", "Target another unit's target" },
        { "/petattack", "Order pet to attack" }, { "/petfollow", "Order pet to follow" }, { "/petassist", "Set pet to assist" }, { "/petdefensive", "Set pet defensive" }, { "/petpassive", "Set pet passive" },
        { "/equip ", "Equip an item" }, { "/equipslot ", "Equip into a slot" }, { "/equipset ", "Equip an equipment set" },
        { "/click ", "Click a secure button" }, { "/dismount", "Dismount" }, { "/run ", "Run Lua code" }, { "/script ", "Run Lua code" },
        { "/console ", "Run a console command or set a CVar" },
        { "/say ", "Say a message" }, { "/party ", "Party message" }, { "/raid ", "Raid message" }, { "/instance ", "Instance message" }, { "/yell ", "Yell a message" }, { "/whisper ", "Whisper a player" },
        { "#showtooltip ", "Set action icon and tooltip" }, { "#show ", "Set action icon" },
    }
    local conditionalCatalog = {
        { "@player", "Your character" }, { "@target", "Current target" }, { "@focus", "Focus target" }, { "@mouseover", "Unit under cursor" }, { "@cursor", "Ground at cursor" }, { "@none", "Show targeting cursor" },
        { "@pet", "Your pet" }, { "@targettarget", "Your target's target" }, { "@party1", "First party member" }, { "@party2", "Second party member" }, { "@arena1", "First arena opponent" },
        { "help", "Friendly target" }, { "harm", "Hostile target" }, { "exists", "Target exists" }, { "dead", "Target is dead" }, { "nodead", "Target is alive" },
        { "combat", "In combat" }, { "nocombat", "Out of combat" }, { "mod:shift", "Shift held" }, { "mod:ctrl", "Ctrl held" }, { "mod:alt", "Alt held" }, { "nomod", "No modifier held" },
        { "group", "In a group" }, { "group:party", "In a party" }, { "group:raid", "In a raid" }, { "party", "Target is in party" }, { "raid", "Target is in raid" },
        { "stance:", "Stance or form number" }, { "form:", "Shapeshift form number" }, { "spec:", "Specialization number" }, { "known:", "Spell or talent known" }, { "channeling", "Currently channeling" }, { "nochanneling", "Not channeling" },
        { "button:", "Mouse button used" }, { "actionbar:", "Current action bar page" }, { "bonusbar:", "Current bonus bar" }, { "equipped:", "Item type equipped" },
        { "pet", "Pet exists" }, { "nopet", "No pet" }, { "vehicleui", "Vehicle UI active" }, { "overridebar", "Override bar active" }, { "possessbar", "Possess bar active" },
    }
    local castTargetCatalog = {
        { "@target", "Current target" }, { "@mouseover", "Unit under the mouse cursor" },
        { "@player", "Your character" }, { "@focus", "Your focus target" },
        { "@pet", "Your pet" }, { "@targettarget", "Your target's target" },
        { "@cursor", "Ground at the cursor" }, { "@none", "Open the ground-targeting cursor" },
    }
    local targetFilterCatalog = {
        { ",help,nodead", "Friendly and alive" }, { ",harm,nodead", "Hostile and alive" },
        { ",help,dead", "Friendly and dead" }, { ",harm,dead", "Hostile and dead" },
        { ",help", "Any friendly unit" }, { ",harm", "Any hostile unit" },
        { ",exists", "Only when the unit exists" }, { "] ", "No additional filter" },
    }
    local conditionalEndingCatalog = {
        { "][] ", "Otherwise use the normal target" },
        { "][@player] ", "Otherwise cast on yourself" },
        { "] ", "No fallback; stop if conditions fail" },
    }
    local commandLookup, spellNames, itemNames, consoleNames = {}, {}, {}, {}
    local itemCacheDirty = true
    for _, entry in ipairs(commandCatalog) do commandLookup[(entry[1]:match("^(%S+)") or entry[1]):lower()] = true end
    local function BuildSpellNames()
        if #spellNames > 0 then return end
        local seen = {}
        local function Add(name) if name and name ~= "" and not seen[name] then seen[name] = true; spellNames[#spellNames + 1] = name end end
        if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemName and Enum and Enum.SpellBookSpellBank then
            local bank = Enum.SpellBookSpellBank.Player
            for lineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
                local info = C_SpellBook.GetSpellBookSkillLineInfo(lineIndex)
                if info and not info.shouldHide then
                    for slot = (info.itemIndexOffset or 0) + 1, (info.itemIndexOffset or 0) + (info.numSpellBookItems or 0) do Add(C_SpellBook.GetSpellBookItemName(slot, bank)) end
                end
            end
        elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
            for tab = 1, GetNumSpellTabs() do
                local _, _, offset, count = GetSpellTabInfo(tab)
                for slot = (offset or 0) + 1, (offset or 0) + (count or 0) do Add(GetSpellBookItemName(slot, BOOKTYPE_SPELL)) end
            end
        end
        table.sort(spellNames)
    end
    local function BuildItemNames()
        if not itemCacheDirty then return end
        itemNames, itemCacheDirty = {}, false
        local seen = {}
        local function ItemSpell(itemID)
            local getter = C_Item and C_Item.GetItemSpell or GetItemSpell
            if not getter or not itemID then return nil end
            local ok, spellName = pcall(getter, itemID)
            return ok and spellName or nil
        end
        local function ItemIsUsable(itemID)
            local getter = C_Item and C_Item.IsUsableItem or IsUsableItem
            if not getter then return true end
            local ok, usable = pcall(getter, itemID)
            return not ok or usable ~= false
        end
        local function AddItem(name, itemID, detail)
            local key = name and name:lower()
            if key and name ~= "" and not seen[key] and ItemSpell(itemID) and ItemIsUsable(itemID) then
                seen[key] = true
                itemNames[#itemNames + 1] = { name = name, detail = detail }
            end
        end
        if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
            for bag = 0, NUM_BAG_SLOTS or 4 do
                for slot = 1, C_Container.GetContainerNumSlots(bag) do
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.itemID then
                        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(info.itemID) or (GetItemInfo and GetItemInfo(info.itemID))
                        AddItem(name, info.itemID, "Usable item in bags")
                    end
                end
            end
        end
        if GetInventoryItemID then
            for slot = 1, 19 do
                local itemID = GetInventoryItemID("player", slot)
                if itemID then
                    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID) or (GetItemInfo and GetItemInfo(itemID))
                    AddItem(name, itemID, "Equipped usable item")
                    if (slot == 13 or slot == 14) and ItemSpell(itemID) and ItemIsUsable(itemID) then
                        itemNames[#itemNames + 1] = { name = tostring(slot), detail = slot == 13 and "Upper equipped trinket" or "Lower equipped trinket" }
                    end
                end
            end
        end
        table.sort(itemNames, function(a, b) return a.name:lower() < b.name:lower() end)
    end
    local itemWatcher = CreateFrame("Frame")
    itemWatcher:RegisterEvent("BAG_UPDATE_DELAYED")
    itemWatcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    itemWatcher:SetScript("OnEvent", function() itemCacheDirty = true end)
    local function BuildConsoleNames()
        if #consoleNames > 0 then return end
        local seen = {}
        local getter = ConsoleGetAllCommands or (C_Console and C_Console.GetAllCommands)
        local commands = getter and getter() or nil
        if commands then
            for _, info in pairs(commands) do
                local name = info and info.command
                if name and name ~= "" and not seen[name:lower()] then
                    seen[name:lower()] = true
                    local detail = info.help
                    if not detail or detail == "" then detail = "Console command or CVar" end
                    consoleNames[#consoleNames + 1] = { name, detail }
                end
            end
        end
        if #consoleNames == 0 then
            consoleNames = {
                { "reloadui", "Reload the user interface" }, { "gxrestart", "Restart the graphics engine" },
                { "cvar_default ", "Restore a CVar to its default" }, { "cvar_reset ", "Restore a CVar to its startup value" },
                { "cvarlist ", "List CVars matching text" }, { "scriptErrors 1", "Show Lua errors" }, { "scriptErrors 0", "Hide Lua errors" },
            }
        end
        table.sort(consoleNames, function(a, b) return a[1]:lower() < b[1]:lower() end)
    end
    local suggestionButtons, matches, selectedSuggestion = {}, {}, 1
    local replaceStart, replaceEnd = 1, 0
    local sequenceSkipResetKey, sequenceEndedKey
    local UpdateSuggestions, QueueSuggestionRefresh
    for index = 1, 8 do
        local button = Button(suggestionPopup, "", 480, 31); button:SetPoint("TOPLEFT", 10, -34 - (index - 1) * 34)
        button.label.baseSize = 15; button.label:SetFont(STANDARD_TEXT_FONT, 15, "")
        button.label:SetJustifyH("LEFT"); button.label:ClearAllPoints(); button.label:SetPoint("LEFT", 9, 0); button.label:SetPoint("RIGHT", button, "CENTER", -7, 0)
        button.detail = Text(button, 13, "muted", "LEFT"); button.detail:SetPoint("LEFT", button, "CENTER", 7, 0); button.detail:SetPoint("RIGHT", -9, 0); button.detail:SetWordWrap(false)
        suggestionButtons[index] = button
    end
    local function PaintSuggestions()
        for index, button in ipairs(suggestionButtons) do
            local item = matches[index]
            button:SetShown(item ~= nil); button.selected = index == selectedSuggestion
            if item then button.label:SetText(item.label or item.insert); button.detail:SetText(item.detail or "") end
        end
        for index, button in ipairs(suggestionButtons) do button:SetBackdropBorderColor(Color(index == selectedSuggestion and "accent" or "border")) end
    end
    local function SuggestionStateKey(value, cursor)
        local before = value:sub(1, cursor)
        local line = before:match("([^\n]*)$") or ""
        local lineStart = cursor - #line + 1
        return value .. "\030" .. lineStart .. "\030" .. line
    end
    local function AcceptSuggestion(item)
        item = item or matches[selectedSuggestion]
        if not item then return end
        local text = macroBody:GetText() or ""
        local itemStart, itemEnd = item.replaceStart or replaceStart, item.replaceEnd or replaceEnd
        local updated = text:sub(1, itemStart - 1) .. item.insert .. text:sub(itemEnd + 1)
        local updatedCursor = itemStart - 1 + #item.insert
        sequenceEndedKey = item.endSequence and SuggestionStateKey(updated, updatedCursor) or nil
        macroBody:SetText(updated); macroBody:SetCursorPosition(updatedCursor); suggestionPopup:Hide(); matches = {}
        if item.skipReset then sequenceSkipResetKey = updated .. "\031" .. updatedCursor end
        if not item.endSequence and QueueSuggestionRefresh then QueueSuggestionRefresh() end
    end
    for index, button in ipairs(suggestionButtons) do
        button:SetScript("OnClick", function()
            local item = matches[index]
            selectedSuggestion = index
            macroBody:SetFocus()
            AcceptSuggestion(item)
        end)
    end
    local function AddMatches(catalog, prefix, limit)
        prefix = (prefix or ""):lower()
        for _, entry in ipairs(catalog) do
            if entry[1]:sub(1, #prefix):lower() == prefix then
                matches[#matches + 1] = { insert = entry[1], detail = entry[2] }
                if #matches >= (limit or 8) then return end
            end
        end
    end
    local function StripLeadingConditionBlocks(value)
        local remainder = value or ""
        while true do
            local _, finish = remainder:find("^%s*%b[]%s*")
            if not finish then return remainder end
            remainder = remainder:sub(finish + 1)
        end
    end
    local function LastTopLevelSeparator(value, separators)
        local depth, last = 0, 0
        for index = 1, #(value or "") do
            local character = value:sub(index, index)
            if character == "[" then
                depth = depth + 1
            elseif character == "]" then
                depth = math.max(0, depth - 1)
            elseif depth == 0 and separators[character] then
                last = index
            end
        end
        return last
    end
    local function ValidateMacro(text)
        local openCount = select(2, text:gsub("%[", "")); local closeCount = select(2, text:gsub("%]", ""))
        if openCount ~= closeCount then return "unmatched [ or ]" end
        for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed ~= "" and not trimmed:match("^[/#]") then return "each line must begin with / or #" end
            local command = trimmed:match("^([/#][%w]+)")
            if command and not commandLookup[command:lower()] then return "unknown command " .. command end
            if trimmed:lower():match("^/cast[%w]*%s+%(") then return "conditions use [square brackets], not (parentheses)" end
            if trimmed:sub(-1) == ";" then return "trailing ; creates an unconditional empty action" end
            local sequenceArguments = trimmed:match("^/castsequence%s+(.+)$")
            if sequenceArguments then
                for clause in (sequenceArguments .. ";"):gmatch("(.-);") do
                    local actionClause = StripLeadingConditionBlocks(clause)
                    local firstComma = actionClause:find(",", 1, true)
                    if firstComma then
                        local laterActions = actionClause:sub(firstComma + 1)
                        if laterActions:find("reset=", 1, true) then return "castsequence reset= belongs before the first action" end
                        if laterActions:find("%[") then return "castsequence conditions apply to the whole clause" end
                    end
                    local resetValue = actionClause:match("reset=([^%s]+)")
                    if resetValue then
                        for condition in resetValue:gmatch("[^/]+") do
                            local validWord = condition == "target" or condition == "combat" or condition == "shift" or condition == "ctrl" or condition == "alt"
                            local validTime = condition:match("^%d+%.?%d*$") ~= nil
                            if not validWord and not validTime then return "unsupported castsequence reset: " .. condition end
                        end
                    end
                end
            end
        end
        return nil
    end
    UpdateSuggestions = function()
        local text = macroBody:GetText() or ""; local cursor = macroBody:GetCursorPosition() or #text; local before = text:sub(1, cursor)
        local line = before:match("([^\n]*)$") or ""; local lineStart = cursor - #line + 1
        matches, selectedSuggestion = {}, 1
        suggestionHint:Hide()
        if sequenceEndedKey == SuggestionStateKey(text, cursor) then suggestionPopup:Hide(); return end
        local infoOnly, showSequenceSyntax = false, false
        local openBracket = line:match(".*()%[")
        if openBracket and not line:sub(openBracket):find("%]") then
            local conditionText = line:sub(openBracket + 1)
            local comma = conditionText:match(".*(),")
            local selectedTarget = conditionText:match("^(@[%w]+)$")
            if conditionText == "" then
                replaceStart, replaceEnd = cursor + 1, cursor
                AddMatches(castTargetCatalog, "")
                suggestionTitle:SetText("STEP 1/3  ·  CAST TARGET  ·  TAB TO SELECT  ·  ENTER TO INSERT")
            elseif selectedTarget then
                replaceStart, replaceEnd = cursor + 1, cursor
                AddMatches(targetFilterCatalog, "")
                suggestionTitle:SetText("STEP 2/3  ·  TARGET FILTER  ·  TAB TO SELECT  ·  ENTER TO INSERT")
            elseif comma and conditionText:sub(-1) ~= "," then
                local lastToken = conditionText:sub(comma + 1):match("^%s*(.-)%s*$") or ""
                local complete = false
                for _, entry in ipairs(conditionalCatalog) do if entry[1]:lower() == lastToken:lower() then complete = true; break end end
                if complete then
                    replaceStart, replaceEnd = cursor + 1, cursor
                    AddMatches(conditionalEndingCatalog, "")
                    suggestionTitle:SetText("STEP 3/3  ·  FALLBACK  ·  TAB TO SELECT  ·  ENTER TO INSERT")
                else
                    local tokenStart = openBracket + comma + 1
                    replaceStart, replaceEnd = lineStart + tokenStart - 1, cursor
                    AddMatches(conditionalCatalog, lastToken)
                    suggestionTitle:SetText("MACRO CONDITIONS  ·  TAB TO SELECT  ·  ENTER TO INSERT")
                end
            else
                local tokenStart = comma and (openBracket + comma + 1) or (openBracket + 1)
                local token = line:sub(tokenStart):match("^%s*(.-)%s*$") or ""
                replaceStart, replaceEnd = lineStart + tokenStart - 1, cursor
                AddMatches(conditionalCatalog, token)
                suggestionTitle:SetText("MACRO CONDITIONS  ·  TAB TO SELECT  ·  ENTER TO INSERT")
            end
        else
            local commandOnly = line:match("^%s*([/#][%w]*)$")
            if commandOnly then
                replaceStart, replaceEnd = lineStart + (line:find("[/#]") or 1) - 1, cursor
                AddMatches(commandCatalog, commandOnly)
                suggestionTitle:SetText("MACRO COMMANDS  ·  TAB TO SELECT  ·  ENTER TO INSERT")
            else
                local command, arguments = line:match("^%s*([/#][%w]+)%s+(.*)$")
                local commandLower = command and command:lower()
                local castCommands = { ["/cast"] = true, ["/castsequence"] = true, ["/castrandom"] = true }
                local itemCommands = { ["/use"] = true, ["/userandom"] = true }
                local tooltipCommands = { ["#showtooltip"] = true, ["#show"] = true }
                local suggestionCommands = castCommands[commandLower] or itemCommands[commandLower] or tooltipCommands[commandLower]
                if commandLower == "/console" then
                    BuildConsoleNames()
                    local prefix = arguments:match("^%s*(.-)%s*$") or ""
                    replaceStart, replaceEnd = cursor - #arguments + (arguments:find("%S") or (#arguments + 1)), cursor
                    AddMatches(consoleNames, prefix)
                    suggestionTitle:SetText("CONSOLE COMMANDS & CVARS  ·  TAB TO SELECT  ·  ENTER TO INSERT")
                elseif command and suggestionCommands then
                    local isCastSequence = commandLower == "/castsequence"
                    showSequenceSyntax = isCastSequence
                    local wantsSpells = castCommands[commandLower] or tooltipCommands[commandLower]
                    local wantsItems = itemCommands[commandLower] or tooltipCommands[commandLower]
                    if wantsSpells then BuildSpellNames() end
                    if wantsItems then BuildItemNames() end
                    local segmentStart = LastTopLevelSeparator(arguments, { [","] = true, [";"] = true }) + 1
                    local segment = arguments:sub(segmentStart); local afterConditions = StripLeadingConditionBlocks(segment)
                    local leading = #segment - #afterConditions; local prefix = afterConditions:match("^%s*(.-)%s*$") or ""
                    replaceStart, replaceEnd = cursor - #segment + leading + (afterConditions:find("%S") or (#afterConditions + 1)), cursor
                    local resetCatalog = {
                        { "reset=target ", "Target changes" }, { "reset=combat ", "Combat state changes" },
                        { "reset=5 ", "Five seconds without pressing" }, { "reset=target/5 ", "Target changes or five seconds" },
                        { "reset=combat/5 ", "Combat changes or five seconds" }, { "reset=target/combat ", "Target or combat changes" },
                        { "reset=target/combat/5 ", "Target, combat, or five seconds" },
                        { "reset=shift ", "Shift is pressed" }, { "reset=ctrl ", "Ctrl is pressed" }, { "reset=alt ", "Alt is pressed" },
                    }
                    local currentClause = arguments
                    local clauseStart = LastTopLevelSeparator(arguments, { [";"] = true }) + 1
                    currentClause = arguments:sub(clauseStart)
                    local clauseAfterConditions = StripLeadingConditionBlocks(currentClause)
                    local hasActionComma = LastTopLevelSeparator(clauseAfterConditions, { [","] = true }) > 0
                    local resetToken = isCastSequence and not hasActionComma and afterConditions:match("^%s*(reset=[^%s]*)%s*$") or nil
                    local sequenceAction = isCastSequence and not hasActionComma and afterConditions:match("^%s*reset=[^%s]+%s+(.*)$") or nil
                    if sequenceAction ~= nil then
                        local actionLeading = #segment - #sequenceAction
                        prefix = sequenceAction:match("^%s*(.-)%s*$") or ""
                        replaceStart, replaceEnd = cursor - #segment + actionLeading + (sequenceAction:find("%S") or (#sequenceAction + 1)), cursor
                    end
                    local partialReset = isCastSequence and not hasActionComma and sequenceAction == nil and prefix ~= "" and string.sub("reset=", 1, #prefix):lower() == prefix:lower()
                    local wantsReset = isCastSequence and sequenceAction == nil and (resetToken ~= nil or partialReset)
                    local showingTargets, sequenceSetup = false, false
                    if wantsReset then
                        local typedReset = resetToken or prefix
                        replaceStart, replaceEnd = cursor - #typedReset + 1, cursor
                        AddMatches(resetCatalog, typedReset)
                        suggestionTitle:SetText("CASTSEQUENCE RESET  ·  / COMBINES CONDITIONS")
                    elseif isCastSequence and not hasActionComma and prefix == "" and sequenceAction == nil then
                        sequenceSetup = true
                        replaceStart, replaceEnd = cursor + 1, cursor
                        local skippedReset = sequenceSkipResetKey == (text .. "\031" .. cursor)
                        if skippedReset then
                            infoOnly = true
                            suggestionHint:SetText("Start typing the first spell name")
                            suggestionHint:Show()
                            suggestionTitle:SetText("CASTSEQUENCE FIRST SPELL")
                        elseif not segment:find("%]") then
                            for index = 1, 4 do
                                local entry = castTargetCatalog[index]
                                matches[#matches + 1] = { insert = "[" .. entry[1], detail = entry[2] }
                            end
                            matches[#matches + 1] = { label = "Add reset condition...", insert = "reset=", detail = "Choose when the sequence returns to its first spell" }
                            matches[#matches + 1] = { label = "Skip target and reset; start first spell", insert = "", detail = "Continue without target or reset options", skipReset = true }
                            suggestionTitle:SetText("CASTSEQUENCE  ·  OPTIONAL TARGET OR RESET")
                        else
                            matches[#matches + 1] = { label = "Add reset condition...", insert = "reset=", detail = "Choose when the sequence returns to its first spell" }
                            matches[#matches + 1] = { label = "Skip reset; start first spell", insert = "", detail = "Keep the target conditions and choose a spell", skipReset = true }
                            suggestionTitle:SetText("CASTSEQUENCE  ·  CHOOSE RESET OR CONTINUE")
                        end
                    else
                        local supportsConditions = castCommands[commandLower]
                        if supportsConditions and not segment:find("%]") and (prefix == "" or prefix:sub(1, 1) == "@" or prefix:sub(1, 1) == "(") then
                            showingTargets = true
                            local targetPrefix = prefix:gsub("^[%[@%(]+", "")
                            for _, entry in ipairs(castTargetCatalog) do
                                if entry[1]:sub(2, #targetPrefix + 1):lower() == targetPrefix:lower() then
                                    matches[#matches + 1] = { insert = "[" .. entry[1], detail = entry[2] }
                                    if #matches >= 8 then break end
                                end
                            end
                            suggestionTitle:SetText("STEP 1/3  ·  CAST TARGET  ·  TAB TO SELECT  ·  ENTER TO INSERT")
                        end
                        local completeSpell = false
                        if prefix ~= "" and wantsSpells then
                            for _, name in ipairs(spellNames) do
                                if name:lower() == prefix:lower() then
                                    completeSpell = true
                                elseif name:sub(1, #prefix):lower() == prefix:lower() then
                                    matches[#matches + 1] = { insert = name, detail = "Known spell" }; if #matches >= 8 then break end
                                end
                            end
                        end
                        if isCastSequence and completeSpell then
                            table.insert(matches, 1, { label = "+ Add next spell", insert = ", ", detail = "Insert comma and continue the sequence", replaceStart = cursor + 1, replaceEnd = cursor })
                            table.insert(matches, 2, { label = "END MACRO", insert = "", detail = "Keep this as the final spell and stop guidance", replaceStart = cursor + 1, replaceEnd = cursor, endSequence = true })
                            while #matches > 8 do table.remove(matches) end
                        end
                    end
                    if #matches < 8 and prefix ~= "" and wantsItems then
                        for _, item in ipairs(itemNames) do
                            if item.name:sub(1, #prefix):lower() == prefix:lower() and item.name:lower() ~= prefix:lower() then
                                matches[#matches + 1] = { insert = item.name, detail = item.detail }; if #matches >= 8 then break end
                            end
                        end
                    end
                    if not wantsReset and prefix == "" and #matches == 0 then
                        infoOnly = true
                        suggestionHint:SetText(isCastSequence and hasActionComma and "Start typing the next spell name" or isCastSequence and "Start typing the first spell name" or wantsItems and wantsSpells and "Start typing spell or item name" or wantsItems and "Start typing item name" or "Start typing spell name")
                        suggestionHint:Show()
                    end
                    if not wantsReset and not showingTargets and not sequenceSetup then
                        suggestionTitle:SetText(isCastSequence and "CASTSEQUENCE ACTIONS  ·  COMMA STARTS THE NEXT ACTION" or wantsItems and wantsSpells and "KNOWN SPELLS & USABLE ITEMS  ·  TAB TO SELECT  ·  ENTER TO INSERT" or wantsItems and "USABLE ITEMS  ·  TAB TO SELECT  ·  ENTER TO INSERT" or "KNOWN SPELLS  ·  TAB TO SELECT  ·  ENTER TO INSERT")
                    end
                end
            end
        end
        if #matches == 0 and not infoOnly then suggestionPopup:Hide(); return end
        suggestionSyntax:SetShown(showSequenceSyntax)
        local currentLine = before:match("([^\n]*)$") or ""
        local fontPath, fontSize, fontFlags = macroBody:GetFont()
        caretMeasure:SetFont(fontPath or STANDARD_TEXT_FONT, fontSize or 13, fontFlags or ""); caretMeasure:SetText(currentLine)
        local innerWidth = math.max(1, (macroBody:GetWidth() or 400) - 20)
        local textWidth = caretMeasure:GetStringWidth() or 0
        local visualLine = 0
        local completedText = before:sub(1, math.max(0, #before - #currentLine))
        for previousLine in completedText:gmatch("([^\n]*)\n") do
            caretMeasure:SetText(previousLine)
            local previousWidth = caretMeasure:GetStringWidth() or 0
            visualLine = visualLine + math.max(1, math.ceil(math.max(1, previousWidth) / innerWidth))
        end
        visualLine = visualLine + math.floor(textWidth / innerWidth)
        local x = 10 + (textWidth % innerWidth)
        local lineHeight = (fontSize or 13) + 4
        local lineTop = 8 + (visualLine * lineHeight)
        local popupWidth = math.max(360, math.min(700, (macroBody:GetWidth() or 400) - 16))
        local footerHeight = showSequenceSyntax and 56 or 0
        local popupHeight = (infoOnly and 96 or (50 + (#matches * 34))) + footerHeight
        suggestionPopup:SetSize(popupWidth, popupHeight)
        for _, button in ipairs(suggestionButtons) do button:SetWidth(popupWidth - 20) end
        x = math.max(8, math.min(x, (macroBody:GetWidth() or 400) - popupWidth - 8))
        local belowY = lineTop + lineHeight + 3
        local maxY = math.max(8, (macroBody:GetHeight() or 300) - popupHeight - 8)
        local y = belowY <= maxY and belowY or math.max(8, lineTop - popupHeight - 3)
        suggestionPopup:ClearAllPoints(); suggestionPopup:SetPoint("TOPLEFT", macroBody, "TOPLEFT", x, -y); suggestionPopup:Show(); PaintSuggestions()
    end
    local refreshPending = false
    QueueSuggestionRefresh = function()
        if refreshPending then return end
        refreshPending = true
        C_Timer.After(0, function()
            refreshPending = false
            if macroBody:HasFocus() then UpdateSuggestions() end
        end)
    end
    macroBody:SetScript("OnTextChanged", function(self, userInput)
        local text = self:GetText() or ""; local problem = ValidateMacro(text)
        bodyLabel:SetText(string.format("MACRO BODY  %d / 255%s", string.len(text), problem and ("  ·  " .. problem) or "")); bodyLabel:SetTextColor(Color(problem and "danger" or "muted"))
        if userInput then sequenceEndedKey = nil end
        if self:HasFocus() then QueueSuggestionRefresh() end
    end)
    macroBody:SetScript("OnEditFocusGained", QueueSuggestionRefresh)
    macroBody:SetScript("OnCursorChanged", QueueSuggestionRefresh)
    macroBody:SetScript("OnTabPressed", function()
        if not suggestionPopup:IsShown() or #matches == 0 then return end
        local delta = IsShiftKeyDown and IsShiftKeyDown() and -1 or 1
        selectedSuggestion = ((selectedSuggestion - 1 + delta) % #matches) + 1
        PaintSuggestions()
    end)
    macroBody:SetScript("OnEnterPressed", function(self)
        if suggestionPopup:IsShown() and #matches > 0 then AcceptSuggestion(); return end
        self:Insert("\n")
    end)
    macroBody:SetScript("OnArrowPressed", function(_, key)
        if not suggestionPopup:IsShown() or #matches == 0 then return end
        selectedSuggestion = ((selectedSuggestion - 1 + (key == "DOWN" and 1 or -1)) % #matches) + 1; PaintSuggestions()
    end)
    macroName:SetScript("OnEscapePressed", function() macroName:ClearFocus() end)
    macroBody:SetScript("OnEscapePressed", function() macroBody:ClearFocus() end)
    sourceLabel = Text(editorPane, 10, "muted"); sourceLabel:SetPoint("BOTTOMLEFT", 20, 104); sourceLabel:SetText("SOURCE")
    sourceBox = Edit(editorPane); sourceBox:SetPoint("LEFT", sourceLabel, "RIGHT", 10, 0); sourceBox:SetPoint("RIGHT", -20, 0); sourceBox:SetHeight(27)
    sourceBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    sourceBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sourceBox:SetScript("OnTextChanged", function(self, userInput) if userInput and selectedRecord then self:SetText(selectedRecord.source or ""); self:HighlightText() end end)
    noteText = Text(editorPane, 10, "muted"); noteText:SetPoint("BOTTOMLEFT", 20, 78); noteText:SetPoint("RIGHT", -20, 0); noteText:SetWordWrap(true)
    local newButton = Button(editorPane, "New", 76, 31); newButton:SetPoint("BOTTOMLEFT", 20, 18); newButton:SetScript("OnClick", ClearEditor)
    saveButton = Button(editorPane, "Save Account Macro", 160, 31); saveButton:SetPoint("BOTTOMRIGHT", -12, 18); saveButton:SetScript("OnClick", SaveMacro)
    deleteButton = Button(editorPane, "Delete", 82, 31); deleteButton:SetPoint("RIGHT", saveButton, "LEFT", -8, 0); deleteButton:SetScript("OnClick", DeleteSelectedMacro); deleteButton:Hide()
    statusText = Text(editorPane, 10, "muted"); statusText:SetPoint("BOTTOMLEFT", newButton, "BOTTOMRIGHT", 12, 10); statusText:SetPoint("RIGHT", deleteButton, "LEFT", -10, 0); statusText:SetWordWrap(false)

    StaticPopupDialogs["REVATHS_MACRO_DELETE"] = {
        text = "Delete macro '%s'?", button1 = DELETE, button2 = CANCEL,
        OnAccept = function(_, record)
            local ok = record and record.index and pcall(DeleteMacro, record.index)
            if ok then SetEditor(nil); RefreshRows(); SetStatus("Macro deleted.") else SetStatus("The game refused to delete this macro.", true) end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }

    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(24, 24); resize:SetPoint("BOTTOMRIGHT", -1, 1); resize:SetFrameLevel(frame:GetFrameLevel() + 3)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText("Resize window"); GameTooltip:Show() end)
    resize:SetScript("OnLeave", function() GameTooltip:Hide() end)
    resize:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); ns.db.window.width, ns.db.window.height = frame:GetWidth(), frame:GetHeight() end)
    BuildSettings(); table.insert(UISpecialFrames, frame:GetName()); ApplyAppearance(); SetEditor(nil); SelectSource("account"); frame:Hide()
end

function ns:Initialize() BuildUI() end

function ns:RedirectBlizzardMacroFrame()
    if self.macroRedirectInstalled then return end

    local function Redirect()
        if self.redirectingMacroFrame then return end
        self.redirectingMacroFrame = true
        if MacroFrame then
            if HideUIPanel then HideUIPanel(MacroFrame) else MacroFrame:Hide() end
        end
        local function ShowReplacement()
            if frame and not frame:IsShown() then
                ApplyAppearance()
                SelectSource(activeSource)
                frame:Show()
            end
            self.redirectingMacroFrame = nil
        end
        if C_Timer and C_Timer.After then C_Timer.After(0, ShowReplacement) else ShowReplacement() end
    end

    local installed = false
    if MacroFrame then
        MacroFrame:HookScript("OnShow", Redirect)
        installed = true
    end
    for _, functionName in ipairs({ "MacroFrame_Show", "ShowMacroFrame" }) do
        if type(_G[functionName]) == "function" then
            hooksecurefunc(functionName, Redirect)
            installed = true
        end
    end
    self.macroRedirectInstalled = installed
end

function ns:Toggle()
    if not frame then return end
    if frame:IsShown() then
        frame:Hide()
    else
        ApplyAppearance(); SelectSource(activeSource); frame:Show()
    end
end

function RevathsEnchantedMacros_ApplySettings()
    if not frame or not ns.db then return end
    ApplyAppearance()
    if settingsPage and settingsPage:IsShown() and settingsPage.Refresh then settingsPage:Refresh() end
end
