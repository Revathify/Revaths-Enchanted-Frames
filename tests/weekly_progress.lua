-- Run from repository root: lua5.1 tests/weekly_progress.lua
local now, resetAt = 1800000000, 1800003600
local frames, timers = {}, {}
GetServerTime = function() return now end
date = os.date
GetCurrentRegion = function() return 3 end
UnitFullName = function() return "Alice", "Test Realm" end
GetRealmName = function() return "Test Realm" end
UnitGUID = function() return "Player-Alice" end
UnitClass = function() return "Mage", "MAGE" end
InCombatLockdown = function() return false end
SlashCmdList = {}
C_DateAndTime = {GetSecondsUntilWeeklyReset = function() return resetAt-now end}
C_Timer = {NewTicker = function() end, After = function(_, fn) timers[#timers+1] = fn end}
CreateFrame = function()
    local frame = {RegisterEvent = function() end, SetScript = function(self,_,fn) self.handler=fn end}
    frames[#frames+1] = frame; return frame
end
Enum = {WeeklyRewardChestThresholdType = {Raid=1,Activities=2,World=3,RankedPvP=4}, QuestFrequency={Weekly=2}}
local activities, encounters = {}, {}
for kind = 1, 4 do
    for index,threshold in ipairs({2,4,8}) do
        activities[#activities+1] = {id=kind*10+index,type=kind,index=index,threshold=threshold,progress=kind==4 and 99 or 4}
    end
end
for id=1,8 do encounters[#encounters+1]={encounterID=id,bestDifficulty=id<=2 and 15 or 0} end
encounters[#encounters+1]={encounterID=1,bestDifficulty=14}
local claimable, fail, secret = false,false,false
local itemLoaded, itemRestricted, requestedItem = false,false,nil
C_Item = {
    GetDetailedItemLevelInfo = function() if itemRestricted then error("restricted item") end; return itemLoaded and 285 or nil end,
    GetItemInfoInstant = function() return 123 end,
    RequestLoadItemDataByID = function(id) requestedItem=id end,
}
EJ_GetEncounterInfo = function(id) return "Boss "..id,nil,nil,nil,nil,99 end
EJ_GetInstanceInfo = function() return "Season Raid" end
GetDifficultyInfo = function(id) return id==15 and "Heroic" or "Normal" end
C_WeeklyRewards = {
    CanClaimRewards = function() return claimable end,
    GetActivities = function() if fail then error("Unavailable") end; return activities end,
    GetActivityEncounterInfo = function() return encounters end,
    GetExampleRewardItemHyperlinks = function(id) assert(id); return "item:123" end,
}
local runs = {{mapChallengeModeID=1,level=5},{mapChallengeModeID=2,level=10},{mapChallengeModeID=1,level=7}}
C_ChallengeMode = {GetMapUIInfo = function(id) return "Dungeon "..id end}
C_MythicPlus = {
    GetRunHistory = function(previous,incomplete,season)
        assert(not previous and not incomplete and season, "request current-week completed runs")
        return runs
    end,
    RequestMapInfo = function() end,
}
local quests = {{questID=101,title="Weekly A",frequency=2,isHeader=false},
    {questID=102,title="Daily A",frequency=1,isHeader=false}}
local completed = {}
C_QuestLog = {
    GetNumQuestLogEntries = function() return #quests end,
    GetInfo = function(index) return quests[index] end,
    IsQuestFlaggedCompleted = function(id) return completed[id] or false end,
    IsOnQuest = function(id) for _,quest in ipairs(quests) do if quest.questID==id then return true end end; return false end,
    IsComplete = function() return false end,
    GetQuestObjectives = function() return {{text="Collect supplies: 2/5",numFulfilled=2,numRequired=5}} end,
}
issecretvalue = function(value) return secret and value == 4 end
local ns = {}
assert(loadfile("RevathsWeeklyPlanner/Core.lua"))("RevathsWeeklyPlanner",ns)
assert(loadfile("RevathsWeeklyPlanner/Progress.lua"))("RevathsWeeklyPlanner",ns)
assert(loadfile("RevathsWeeklyPlanner/Details.lua"))("RevathsWeeklyPlanner",ns)
frames[1].handler(nil,"ADDON_LOADED","RevathsWeeklyPlanner")
frames[1].handler(nil,"PLAYER_LOGIN")
local key,character = ns.currentKey,ns.db.characters[ns.currentKey]
assert(#ns:GetGoals(key)==4, "default goals appear without adding anything")
ns:CaptureWeeklyProgress()
assert(not character.weekly.dungeons, "wait for authoritative M+ map update")
frames[2].handler(nil,"CHALLENGE_MODE_MAPS_UPDATE")
timers[#timers]()
local weekly = character.weekly
assert(weekly.raid.total==8 and weekly.raid.killed==2, "season boss count deduplicates difficulties")
assert(weekly.dungeons.count==3 and weekly.vault.dungeonTarget==8, "M+ count and seasonal target")
assert(weekly.vault.filled==6 and weekly.vault.total==9, "nine active Vault slots; exclude inactive PvP row")
local goals=ns:GetGoals(key)
assert(goals[1].title:find("2/8",1,true) and goals[2].title:find("3/8",1,true))
assert(goals[3].title:find("0/1 tracked",1,true) and goals[4].title:find("6/9",1,true))
assert(#character.goals==0 and goals[1].automatic, "built-ins do not become manual saved goals")
assert(ns:ToggleGoal(key,goals[1].id) and ns:GetGoals(key)[1].done, "default goals support manual completion")
ns:CaptureWeeklyProgress()
assert(ns:GetGoals(key)[1].done and weekly.raid.killed==2, "automatic refresh preserves manual completion and real counters")
ns:InitializeDatabase()
assert(ns:GetGoals(key)[1].done, "manual completion survives database reload")
assert(ns:ToggleGoal(key,goals[1].id) and not ns:GetGoals(key)[1].done, "click again to reopen default goal")
ns:ResetGoalOverride(key,goals[1].id)
assert(not ns:GetGoals(key)[1].manualCompletion, "restore automatic progress")
assert(not ns:ToggleGoal(key,"auto:invalid"), "unknown IDs cannot create overrides")
assert(weekly.raid.bosses[1].killed and weekly.raid.bosses[1].difficulty=="Heroic", "boss names and best difficulty are saved")
assert(weekly.dungeons.runs[1].level==10, "dungeon hover details sorted by level")
assert(#weekly.vault.slots==9 and requestedItem==123, "save every active slot and request uncached reward item")
local _,lines = ns:GetGoalDetails(key,"auto:vault")
assert(table.concat(lines,"\n"):find("item level unavailable / loading",1,true), "uncached rewards are explicit")
itemLoaded=true; frames[2].handler(nil,"ITEM_DATA_LOAD_RESULT",123,true); timers[#timers]()
_,lines=ns:GetGoalDetails(key,"auto:vault")
assert(table.concat(lines,"\n"):find("item level 285",1,true), "item load updates saved reward levels")
itemRestricted=true; ns:CaptureWeeklyProgress()
assert(weekly.vault.filled==6 and weekly.raid.killed==2, "restricted optional reward details do not discard counters")
itemRestricted=false
_,lines=ns:GetGoalDetails(key,"auto:raid")
local tooltip=table.concat(lines,"\n")
assert(tooltip:find("[Killed] Boss 1 - Heroic",1,true) and tooltip:find("[Remaining] Boss 8",1,true))
quests[#quests+1]={questID=89507,title="Abundant Offerings",frequency=0,isHeader=false}
quests[#quests+1]={questID=89289,title="Favor of the Court",frequency=0,isHeader=false}
completed[90573]=true
ns:CaptureWeeklyProgress()
assert(weekly.quests[89507].event=="Abundance" and weekly.quests[89289].event=="Saltheril's Soiree", "recognize event quests even without weekly frequency")
assert(weekly.quests[90573].done and not weekly.quests[90574], "discover completed variant without inventing unoffered variants")
_,lines=ns:GetGoalDetails(key,"auto:quests")
assert(table.concat(lines,"\n"):find("Collect supplies: 2/5",1,true), "quest objectives appear in details")
-- Return to the original one-quest fixture for completion/filter/reset checks.
weekly.quests[89507],weekly.quests[89289],weekly.quests[90573]=nil,nil,nil
completed[90573]=nil
quests={}
frames[2].handler(nil,"QUEST_TURNED_IN",101)
timers[#timers]()
assert(character.weekly.quests[101].done, "retain turned-in weekly after leaving quest log")
ns.db.unfinishedOnly=true
assert(#ns:GetGoals(key)==3, "completed weekly quest goal hides in unfinished filter")
ns.db.unfinishedOnly=false
local savedVault=weekly.vault
fail=true; ns:CaptureWeeklyProgress()
assert(weekly.vault==savedVault, "API errors preserve saved progress")
fail=false; secret=true; ns:CaptureWeeklyProgress()
assert(weekly.vault==savedVault, "restricted values preserve saved progress")
secret=false; claimable=true; ns:CaptureWeeklyProgress()
assert(weekly.vault==savedVault, "unclaimed previous-week reward is not imported as current progress")
local offline={name="Alt",realm="Test Realm",region=3,goals={},nextID=1,weekly=weekly,resetAt=resetAt}
ns.db.characters.alt=offline
assert(ns:GetGoals("alt")[2].title:find("3/8",1,true), "offline alt reads its saved snapshot")
_,lines=ns:GetGoalDetails("alt","auto:dungeons")
assert(table.concat(lines,"\n"):find("+10 Dungeon 2",1,true) and table.concat(lines,"\n"):find("Offline snapshot",1,true), "offline detail data belongs to the selected alt")
assert(ns:ToggleGoal("alt","auto:raid") and ns:GetGoals("alt")[1].done and not ns:GetGoals(key)[1].done, "manual completion belongs to selected alt")
assert(ns:ToggleGoal(key,"auto:quests") and not ns:GetDefaultGoals(character)[3].done, "manual false can reopen automatically completed goal")
ns:CaptureWeeklyProgress()
assert(not ns:GetDefaultGoals(character)[3].done, "explicit false survives automatic updates")
now=resetAt+1; resetAt=resetAt+604800
ns:CheckWeeklyReset()
assert(not character.weekly and not offline.weekly, "weekly reset expires automatic progress for offline alts")
assert(not character.weeklyOverrides and not offline.weeklyOverrides, "weekly reset expires manual overrides for all alts")
assert(#ns:GetGoals(key)==4 and not ns:GetGoals(key)[1].done, "default goals survive reset with unknown progress")
claimable=false; ns:CaptureWeeklyProgress()
assert(not next(character.weekly.quests), "weekly quest discovery starts fresh after reset")
print("Automatic weekly goal tests passed: seasonal raid totals, M+ counters, nine Vault slots, tracked quests, offline snapshots, reset, API failures and restricted values.")
