local _, ns = ...

-- Only format saved public data here; hovering an offline alt never queries the current character.
function ns:GetGoalDetails(key, goalID)
    local character = self.db.characters[key]
    if not character then return end
    local goal
    for _, entry in ipairs(self:GetGoals(key)) do if entry.id == goalID then goal = entry; break end end
    if not goal then return end
    local lines, snapshot, stamp = {}, character.weekly or {}, nil
    local function Add(text) lines[#lines + 1] = text end
    if goalID == "auto:raid" then
        local raid = snapshot.raid
        stamp = raid and raid.capturedAt
        local lastRaid
        for _, boss in ipairs(raid and raid.bosses or {}) do
            if lastRaid ~= boss.raidName then Add(boss.raidName); lastRaid = boss.raidName end
            Add((boss.killed and "[Killed] " or "[Remaining] ") .. boss.name .. (boss.difficulty and " - " .. boss.difficulty or ""))
        end
        if #lines == 0 then Add("Log into this character to load the season's raid encounters.") end
    elseif goalID == "auto:vault" then
        local vault = snapshot.vault
        stamp = vault and vault.capturedAt
        for _, slot in ipairs(vault and vault.slots or {}) do
            local reward = slot.unlocked and (slot.itemLevel and ("Unlocked - item level " .. slot.itemLevel) or "Unlocked - item level unavailable / loading")
                or string.format("Locked - %d/%d", slot.progress, slot.threshold)
            Add(slot.row .. " slot " .. slot.index .. ": " .. reward)
        end
        if #lines == 0 then Add("Open the Great Vault on this character to refresh reward details.") end
        if snapshot.rewardPending then Add("Last week's reward is unclaimed; displayed details are the last saved snapshot.") end
    elseif goalID == "auto:dungeons" then
        local dungeons = snapshot.dungeons
        stamp = dungeons and dungeons.capturedAt
        for _, run in ipairs(dungeons and dungeons.runs or {}) do
            Add((run.level and ("+" .. run.level .. " ") or "") .. run.name)
        end
        if #lines == 0 then Add(dungeons and "No completed M+ runs recorded this week." or "Log into this character to load completed M+ runs.") end
    elseif goalID == "auto:quests" then
        stamp = snapshot.questsUpdatedAt
        local quests = {}
        for _, quest in pairs(snapshot.quests or {}) do quests[#quests + 1] = quest end
        table.sort(quests, function(a,b) if a.done ~= b.done then return not a.done end; return a.name < b.name end)
        for _, quest in ipairs(quests) do
            local status = quest.done and "Completed" or (quest.ready and "Ready to turn in" or (quest.active and "In progress" or "No longer in quest log"))
            Add("[" .. status .. "] " .. quest.name)
            if quest.event then Add("  Event: " .. quest.event) end
            if not quest.done then
                for _, objective in ipairs(quest.objectives or {}) do Add("  " .. objective.text) end
            end
        end
        if #lines == 0 then Add("Pick up weekly quests to track their progress here.") end
        Add("Includes accepted weekly quests, Favor of the Court, Fortify the Runestones and Abundant Offerings.")
    else
        Add(goal.done and "Completed this week." or "Click to mark complete; right-click to edit.")
    end
    if stamp then Add("Updated " .. date("%d %b, %H:%M", stamp)) end
    if key ~= self.currentKey then Add("Offline snapshot - log into this character to refresh.") end
    if goal.automatic then
        Add(goal.manualCompletion and "Completion set manually for this week." or "Completion follows live progress.")
        Add("Click to check off; Shift-click to restore automatic completion.")
    end
    return goal.title, lines
end
