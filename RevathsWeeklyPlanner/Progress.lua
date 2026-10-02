local _, ns = ...

local function Public(value)
    if issecretvalue and issecretvalue(value) then error("Weekly progress is restricted") end
    return value
end

local function Number(value)
    value = Public(value)
    assert(type(value) == "number" and value >= 0)
    return value
end

local function Read(reader)
    local ok, value = pcall(reader)
    if ok then return value end
end

-- Named Midnight weeklies: track accepted/completed variants, never assume all are offered.
local eventQuests = {
    [89289] = { name = "Favor of the Court", event = "Saltheril's Soiree" },
    [89507] = { name = "Abundant Offerings", event = "Abundance" },
    [90573] = { name = "Fortify the Runestones: Magisters", event = "Saltheril's Soiree" },
    [90574] = { name = "Fortify the Runestones: Blood Knights", event = "Saltheril's Soiree" },
    [90575] = { name = "Fortify the Runestones: Farstriders", event = "Saltheril's Soiree" },
    [90576] = { name = "Fortify the Runestones: Shades of the Row", event = "Saltheril's Soiree" },
    [93889] = { name = "Midnight: Saltheril's Soiree", event = "Saltheril's Soiree" },
}
for id, definition in pairs(ns.namedWeeklyQuests or {}) do
    if not eventQuests[id] then eventQuests[id] = definition end
end

local function Text(value, fallback)
    value = Public(value)
    return type(value) == "string" and value ~= "" and value or fallback
end

local function QuestName(id, fallback)
    local name = C_QuestLog.GetTitleForQuestID and Read(function() return Text(C_QuestLog.GetTitleForQuestID(id)) end)
    if name then return name end
    if C_QuestLog.RequestLoadQuestByID then
        ns.weeklyQuestRequests = ns.weeklyQuestRequests or {}
        local now = GetServerTime()
        if not ns.weeklyQuestRequests[id] or now - ns.weeklyQuestRequests[id] >= 30 then
            ns.weeklyQuestRequests[id] = now
            pcall(C_QuestLog.RequestLoadQuestByID, id)
        end
    end
    return fallback
end

local function RewardItemLevel(activityID, now)
    if not C_WeeklyRewards.GetExampleRewardItemHyperlinks or not C_Item then return end
    return Read(function()
        local link = Public(C_WeeklyRewards.GetExampleRewardItemHyperlinks(Number(activityID)))
        if type(link) ~= "string" then return end
        local level = C_Item.GetDetailedItemLevelInfo and Public(C_Item.GetDetailedItemLevelInfo(link))
        if type(level) == "number" and level > 0 then return level end
        if C_Item.GetItemInfoInstant and C_Item.RequestLoadItemDataByID then
            local id = Number(C_Item.GetItemInfoInstant(link))
            ns.weeklyItemRequests = ns.weeklyItemRequests or {}
            if not ns.weeklyItemRequests[id] or now - ns.weeklyItemRequests[id] >= 30 then
                ns.weeklyItemRequests[id] = now
                pcall(C_Item.RequestLoadItemDataByID, id)
            end
        end
    end)
end

function ns:CaptureWeeklyProgress()
    if not self.db or not self.currentKey then return end
    if InCombatLockdown and InCombatLockdown() then self.pendingWeeklyProgress = true; return end
    self.pendingWeeklyProgress = nil
    self:CheckWeeklyReset()
    local character = self.db.characters[self.currentKey]
    local snapshot = character.weekly or { quests = {} }
    local now = GetServerTime()
    snapshot.quests = snapshot.quests or {}
    snapshot.rewardPending = C_WeeklyRewards and C_WeeklyRewards.CanClaimRewards and Read(function()
        return Public(C_WeeklyRewards.CanClaimRewards()) == true
    end) or false
    local types = Enum and Enum.WeeklyRewardChestThresholdType
    local vault = types and C_WeeklyRewards and Read(function()
        -- Avoid labelling an unclaimed previous-week reward as this week's progress.
        if C_WeeklyRewards.CanClaimRewards and Public(C_WeeklyRewards.CanClaimRewards()) then return end
        local activities = Public(C_WeeklyRewards.GetActivities())
        assert(type(activities) == "table" and #activities > 0)
        local world = false
        for _, activity in ipairs(activities) do
            if Public(activity.type) == types.World then world = true end
        end
        local thirdType = world and types.World or types.RankedPvP
        local filled, total, target, seen, slots = 0, 0, 0, {}, {}
        for _, activity in ipairs(activities) do
            local kind, index = Public(activity.type), Number(activity.index)
            if kind == types.Raid or kind == types.Activities or kind == thirdType then
                local key = tostring(kind) .. ":" .. index
                if not seen[key] then
                    seen[key] = true
                    local threshold, progress = Number(activity.threshold), Number(activity.progress)
                    total = total + 1
                    if threshold > 0 and progress >= threshold then filled = filled + 1 end
                    if kind == types.Activities then target = math.max(target, threshold) end
                    local rowName = kind == types.Raid and "Raid" or (kind == types.Activities and "Dungeons" or (world and "World / Delves" or "PvP"))
                    local unlocked = threshold > 0 and progress >= threshold
                    slots[#slots + 1] = { row = rowName, index = index, progress = progress, threshold = threshold,
                        unlocked = unlocked, itemLevel = unlocked and RewardItemLevel(activity.id, now) or nil }
                end
            end
        end
        assert(total > 0)
        table.sort(slots, function(a,b) if a.row == b.row then return a.index < b.index end; return a.row < b.row end)
        return { filled = filled, total = total, dungeonTarget = target, slots = slots, capturedAt = now }
    end)
    if vault then snapshot.vault = vault end
    local raid = types and C_WeeklyRewards and Read(function()
        if C_WeeklyRewards.CanClaimRewards and Public(C_WeeklyRewards.CanClaimRewards()) then return end
        local encounters = Public(C_WeeklyRewards.GetActivityEncounterInfo(types.Raid, 1))
        assert(type(encounters) == "table" and #encounters > 0)
        local bosses, killed, total, details = {}, 0, 0, {}
        for _, encounter in ipairs(encounters) do
            local id, difficulty = Number(encounter.encounterID), Number(encounter.bestDifficulty)
            bosses[id] = math.max(bosses[id] or 0, difficulty)
            if not details[id] then
                local identity = EJ_GetEncounterInfo and Read(function()
                    local name, _, _, _, _, instanceID = EJ_GetEncounterInfo(id)
                    local raidName = EJ_GetInstanceInfo and instanceID and EJ_GetInstanceInfo(Public(instanceID))
                    return { name = Text(name, "Boss " .. id), raidName = Text(raidName, "Season raid") }
                end)
                details[id] = identity or { name = "Boss " .. id, raidName = "Season raid" }
                details[id].id = id
                details[id].order = Read(function() return Number(encounter.uiOrder) end) or id
            end
        end
        local list = {}
        for id, difficulty in pairs(bosses) do
            total = total + 1; if difficulty > 0 then killed = killed + 1 end
            local boss = details[id]
            boss.killed = difficulty > 0
            boss.difficulty = difficulty > 0 and GetDifficultyInfo and Read(function() return Text(GetDifficultyInfo(difficulty)) end) or nil
            list[#list + 1] = boss
        end
        table.sort(list, function(a,b) if a.raidName == b.raidName then return a.order < b.order end; return a.raidName < b.raidName end)
        return { killed = killed, total = total, bosses = list, capturedAt = now }
    end)
    if raid then snapshot.raid = raid end
    local runs = self.mythicDataReady and C_MythicPlus and Read(function()
        local history = Public(C_MythicPlus.GetRunHistory(false, false, true))
        assert(type(history) == "table")
        local details = {}
        for index, run in ipairs(history) do
            local detail = Read(function()
                local mapID, level = Number(run.mapChallengeModeID), Number(run.level)
                local name = C_ChallengeMode and Text(C_ChallengeMode.GetMapUIInfo(mapID), "Dungeon " .. mapID) or ("Dungeon " .. mapID)
                return { name = name, level = level }
            end)
            details[index] = detail or { name = "Dungeon details unavailable" }
        end
        table.sort(details, function(a,b) return (a.level or 0) > (b.level or 0) end)
        return { count = #history, runs = details, capturedAt = now }
    end)
    if runs then snapshot.dungeons = runs end
    if C_QuestLog and Enum and Enum.QuestFrequency then
        local quests = Read(function()
            local known = {}
            for id, quest in pairs(snapshot.quests) do
                known[id] = { name = quest.name, done = quest.done, event = quest.event, objectives = quest.objectives, active = false }
            end
            for id, definition in pairs(eventQuests) do
                local active = C_QuestLog.IsOnQuest and Public(C_QuestLog.IsOnQuest(id))
                if not active and C_TaskQuest and C_TaskQuest.IsActive then active = Public(C_TaskQuest.IsActive(id)) end
                local completed = Public(C_QuestLog.IsQuestFlaggedCompleted(id))
                if active or completed then
                    local name = QuestName(id, known[id] and known[id].name or definition.name)
                    known[id] = known[id] or { name = name, done = false }
                    known[id].name = name
                    known[id].event, known[id].active = definition.event, active == true
                end
            end
            for index = 1, Number(C_QuestLog.GetNumQuestLogEntries()) do
                local info = Public(C_QuestLog.GetInfo(index))
                if info and not Public(info.isHeader) and (Public(info.frequency) == Enum.QuestFrequency.Weekly or eventQuests[Number(info.questID)]) then
                    local id, name = Number(info.questID), Public(info.title)
                    assert(type(name) == "string")
                    known[id] = known[id] or { name = name, done = false }
                    known[id].name, known[id].active = name, true
                    if eventQuests[id] then known[id].event = eventQuests[id].event end
                end
            end
            for id, quest in pairs(known) do
                if Public(C_QuestLog.IsQuestFlaggedCompleted(id)) then quest.done = true end
                quest.ready = not quest.done and C_QuestLog.IsComplete and Read(function() return Public(C_QuestLog.IsComplete(id)) == true end) or false
                if quest.active and C_QuestLog.GetQuestObjectives then
                    local objectives = Read(function()
                        local result = {}
                        for _, objective in ipairs(Public(C_QuestLog.GetQuestObjectives(id)) or {}) do
                            local text = Text(objective.text)
                            if text then
                                local fulfilled = objective.numFulfilled and Number(objective.numFulfilled)
                                local required = objective.numRequired and Number(objective.numRequired)
                                result[#result + 1] = { text = text, fulfilled = fulfilled, required = required }
                            end
                        end
                        return result
                    end)
                    if objectives then quest.objectives = objectives end
                end
            end
            return known
        end)
        if quests then snapshot.quests, snapshot.questsUpdatedAt = quests, now end
    end
    character.weekly = snapshot
    if self.CaptureActivities then self:CaptureActivities(character, snapshot) end
    if self.Refresh then self:Refresh() end
end

function ns:GetDefaultGoals(character)
    local snapshot = character.weekly or {}
    local raid, runs, vault = snapshot.raid, snapshot.dungeons, snapshot.vault
    local done, total = 0, 0
    for _, quest in pairs(snapshot.quests or {}) do total = total + 1; if quest.done then done = done + 1 end end
    local target = vault and vault.dungeonTarget > 0 and vault.dungeonTarget or nil
    local goals = {
        { id = "auto:raid", automatic = true, done = raid and raid.killed >= raid.total or false,
            title = "Kill season raid bosses - " .. (raid and string.format("%d/%d", raid.killed, raid.total) or "Waiting for raid data") },
        { id = "auto:dungeons", automatic = true, done = runs and target and runs.count >= target or false,
            title = "Finish M+ dungeons - " .. (runs and (target and string.format("%d/%d", runs.count, target) or (runs.count .. " completed")) or "Log in to update") },
        { id = "auto:quests", automatic = true, done = total > 0 and done >= total,
            title = "Finish weekly quests - " .. (total > 0 and string.format("%d/%d tracked", done, total) or "Pick up weekly quests") },
        { id = "auto:vault", automatic = true, done = vault and vault.filled >= vault.total or false,
            title = "Fill Great Vault slots - " .. (vault and string.format("%d/%d", vault.filled, vault.total)
                or (snapshot.rewardPending and "Claim last week's reward to refresh" or "Waiting for Vault data")) },
    }
    if self.GetAdditionalGoals then
        local additional = self:GetAdditionalGoals(character)
        for _, goal in ipairs(additional) do
            goals[#goals + 1] = goal
            if goal.id:find("auto:world:", 1, true) or goal.id:find("auto:profession:", 1, true) then goals[3].countsForProgress = false end
        end
    end
    for _, goal in ipairs(goals) do
        local override = character.weeklyOverrides and character.weeklyOverrides[goal.id]
        if type(override) == "boolean" then goal.done, goal.manualCompletion = override, true end
    end
    return goals
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "WEEKLY_REWARDS_UPDATE", "CHALLENGE_MODE_COMPLETED",
    "CHALLENGE_MODE_MAPS_UPDATE", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_REGEN_ENABLED", "ENCOUNTER_END", "ITEM_DATA_LOAD_RESULT",
    "CURRENCY_DISPLAY_UPDATE", "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "TRADE_SKILL_DATA_SOURCE_CHANGED", "QUEST_DATA_LOAD_RESULT" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, questID, encounterName, difficultyID, groupSize, success)
    if not ns.db or not ns.currentKey then return end
    if event == "ENCOUNTER_END" and ((issecretvalue and issecretvalue(success)) or success ~= 1) then return end
    if event == "ITEM_DATA_LOAD_RESULT" and ((issecretvalue and issecretvalue(questID)) or not ns.weeklyItemRequests or not ns.weeklyItemRequests[questID]) then return end
    if event == "QUEST_DATA_LOAD_RESULT" and ((issecretvalue and issecretvalue(questID)) or not ns.weeklyQuestRequests or not ns.weeklyQuestRequests[questID]) then return end
    if event == "QUEST_TURNED_IN" and not (issecretvalue and issecretvalue(questID)) then
        local snapshot = ns.db.characters[ns.currentKey].weekly
        if snapshot and snapshot.quests[questID] then snapshot.quests[questID].done = true end
    end
    if event == "PLAYER_REGEN_ENABLED" and not ns.pendingWeeklyProgress then return end
    if event == "CHALLENGE_MODE_MAPS_UPDATE" then ns.mythicDataReady = true end
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "CHALLENGE_MODE_COMPLETED" then
        if C_MythicPlus and C_MythicPlus.RequestMapInfo then
            ns.mythicDataReady = false
            pcall(C_MythicPlus.RequestMapInfo)
        end
    end
    -- Coalesce quest-log updates and wait for Blizzard's counters to refresh.
    if ns.weeklyRefreshScheduled then return end
    ns.weeklyRefreshScheduled = true
    C_Timer.After(1, function() ns.weeklyRefreshScheduled = nil; ns:CaptureWeeklyProgress() end)
end)
