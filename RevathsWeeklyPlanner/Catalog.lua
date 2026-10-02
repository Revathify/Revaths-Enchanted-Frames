local _, ns = ...

-- Midnight quest/skill IDs. Verification links and reset semantics: TRACKING-SOURCES.md.
ns.knowledgeCatalog = {
    [171] = { skill=2906, weekly={93690}, treatise=95127, treasures={93528,93529} },
    [164] = { skill=2907, weekly={93691}, treatise=95128, treasures={93530,93531} },
    [333] = { skill=2909, weekly={93697,93698,93699}, treatise=95129, treasures={93532,93533}, drops={95048,95049,95050,95051,95052,95053} },
    [202] = { skill=2910, weekly={93692}, treatise=95138, treasures={93534,93535} },
    [182] = { skill=2912, weekly={93700,93701,93702,93703,93704}, treatise=95130, drops={81425,81426,81427,81428,81429,81430} },
    [773] = { skill=2913, weekly={93693}, treatise=95131, treasures={93536,93537} },
    [755] = { skill=2914, weekly={93694}, treatise=95133, treasures={93538,93539} },
    [165] = { skill=2915, weekly={93695}, treatise=95134, treasures={93540,93541} },
    [186] = { skill=2916, weekly={93705,93706,93707,93708,93709}, treatise=95135, drops={88673,88674,88675,88676,88677,88678} },
    [393] = { skill=2917, weekly={93710,93711,93712,93713,93714}, treatise=95136, drops={88534,88549,88537,88536,88530,88529} },
    [197] = { skill=2918, weekly={93696}, treatise=95137, treasures={93542,93543} },
}
ns.worldCatalog = {
    { key="soiree", name="Saltheril's Soiree", quests={89289,90573,90574,90575,90576} },
    { key="abundance", name="Abundance", quests={89507} },
    { key="assignments", name="Special Assignments", quests={91390,91796,92063,92139,92145,93013,93244,93438} },
    { key="dungeonquest", name="Weekly dungeon quest", quests={93751,93752,93753,93754,93755,93756,93757,93758} },
    { key="meta", name="Midnight weekly", quests={93766,93767,93769,93889,93890,93892,93909,93910,93911,93912,93913,94457,95842,96727,98172,98232} },
    { key="assaults", name="Void Assaults", quests={94385,94386} },
    { key="surge", name="Turn Back the Surge", quests={96995} },
    { key="vaults", name="Purging the Vaults", quests={95520} },
    { key="preynormal", name="Prey - Normal", target=4, quests={91095,91096,91097,91098,91099,91100,91101,91102,91103,91104,91105,91106,91107,91108,91109,91110,91111,91112,91113,91114,91115,91116,91117,91118,91119,91120,91121,91122,91123,91124} },
    { key="preyhard", name="Prey - Hard", target=4, quests={91210,91212,91214,91216,91218,91220,91222,91224,91226,91228,91230,91232,91234,91236,91238,91240,91242,91243,91244,91245,91246,91247,91248,91249,91250,91251,91252,91253,91254,91255} },
    { key="preynightmare", name="Prey - Nightmare", target=4, quests={91211,91213,91215,91217,91219,91221,91223,91225,91227,91229,91231,91233,91235,91237,91239,91241,91256,91257,91258,91259,91260,91261,91262,91263,91264,91265,91266,91267,91268,91269,95021,95022,95023,95024} },
}
ns.namedWeeklyQuests = {}
for _, group in ipairs(ns.worldCatalog) do
    for _, id in ipairs(group.quests) do ns.namedWeeklyQuests[id] = { name="Quest " .. id, event=group.name } end
end
for _, profession in pairs(ns.knowledgeCatalog) do
    for _, id in ipairs(profession.weekly) do ns.namedWeeklyQuests[id] = { name="Profession weekly", event="Professions" } end
end
