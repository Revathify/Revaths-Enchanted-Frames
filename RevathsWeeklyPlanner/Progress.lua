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
        local filled, total, target, seen = 0, 0, 0, {}
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
                end
            end
        end
        assert(total > 0)
        return { filled = filled, total = total, dungeonTarget = target, capturedAt = now }
    end)
    if vault then snapshot.vault = vault end
    local raid = types and C_WeeklyRewards and Read(function()
        if C_WeeklyRewards.CanClaimRewards and Public(C_WeeklyRewards.CanClaimRewards()) then return end
        local encounters = Public(C_WeeklyRewards.GetActivityEncounterInfo(types.Raid, 1))
        assert(type(encounters) == "table" and #encounters > 0)
        local bosses, killed, total = {}, 0, 0
        for _, encounter in ipairs(encounters) do
            local id, difficulty = Number(encounter.encounterID), Number(encounter.bestDifficulty)
            bosses[id] = math.max(bosses[id] or 0, difficulty)
        end
        for _, difficulty in pairs(bosses) do total = total + 1; if difficulty > 0 then killed = killed + 1 end end
        return { killed = killed, total = total, capturedAt = now }
    end)
    if raid then snapshot.raid = raid end
    local runs = self.mythicDataReady and C_MythicPlus and Read(function()
        local history = Public(C_MythicPlus.GetRunHistory(false, false, true))
        assert(type(history) == "table")
        return { count = #history, capturedAt = now }
    end)
    if runs then snapshot.dungeons = runs end
    if C_QuestLog and Enum and Enum.QuestFrequency then
        local quests = Read(function()
            local known = {}
            for id, quest in pairs(snapshot.quests) do known[id] = { name = quest.name, done = quest.done } end
            for index = 1, Number(C_QuestLog.GetNumQuestLogEntries()) do
                local info = Public(C_QuestLog.GetInfo(index))
                if info and not Public(info.isHeader) and Public(info.frequency) == Enum.QuestFrequency.Weekly then
                    local id, name = Number(info.questID), Public(info.title)
                    assert(type(name) == "string")
                    known[id] = known[id] or { name = name, done = false }
                end
            end
            for id, quest in pairs(known) do
                if Public(C_QuestLog.IsQuestFlaggedCompleted(id)) then quest.done = true end
            end
            return known
        end)
        if quests then snapshot.quests, snapshot.questsUpdatedAt = quests, now end
    end
    character.weekly = snapshot
    if self.Refresh then self:Refresh() end
end

function ns:GetDefaultGoals(character)
    local snapshot = character.weekly or {}
    local raid, runs, vault = snapshot.raid, snapshot.dungeons, snapshot.vault
    local done, total = 0, 0
    for _, quest in pairs(snapshot.quests or {}) do total = total + 1; if quest.done then done = done + 1 end end
    local target = vault and vault.dungeonTarget > 0 and vault.dungeonTarget or nil
    return {
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
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "WEEKLY_REWARDS_UPDATE", "CHALLENGE_MODE_COMPLETED",
    "CHALLENGE_MODE_MAPS_UPDATE", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_REGEN_ENABLED", "ENCOUNTER_END" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, questID, encounterName, difficultyID, groupSize, success)
    if not ns.db or not ns.currentKey then return end
    if event == "ENCOUNTER_END" and ((issecretvalue and issecretvalue(success)) or success ~= 1) then return end
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
