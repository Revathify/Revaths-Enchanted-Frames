-- Run from repository root: lua5.1 tests/weekly_progress.lua
local now, resetAt = 1800000000, 1800003600
local frames, timers = {}, {}
GetServerTime = function() return now end
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
        activities[#activities+1] = {type=kind,index=index,threshold=threshold,progress=kind==4 and 99 or 4}
    end
end
for id=1,8 do encounters[#encounters+1]={encounterID=id,bestDifficulty=id<=2 and 15 or 0} end
encounters[#encounters+1]={encounterID=1,bestDifficulty=14}
local claimable, fail, secret = false,false,false
C_WeeklyRewards = {
    CanClaimRewards = function() return claimable end,
    GetActivities = function() if fail then error("Unavailable") end; return activities end,
    GetActivityEncounterInfo = function() return encounters end,
}
local runs = {{},{},{}}
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
}
issecretvalue = function(value) return secret and value == 4 end
local ns = {}
assert(loadfile("RevathsWeeklyPlanner/Core.lua"))("RevathsWeeklyPlanner",ns)
assert(loadfile("RevathsWeeklyPlanner/Progress.lua"))("RevathsWeeklyPlanner",ns)
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
assert(not ns:ToggleGoal(key,goals[1].id), "automatic goals cannot be manually toggled")
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
now=resetAt+1; resetAt=resetAt+604800
ns:CheckWeeklyReset()
assert(not character.weekly and not offline.weekly, "weekly reset expires automatic progress for offline alts")
assert(#ns:GetGoals(key)==4 and not ns:GetGoals(key)[1].done, "default goals survive reset with unknown progress")
claimable=false; ns:CaptureWeeklyProgress()
assert(not next(character.weekly.quests), "weekly quest discovery starts fresh after reset")
print("Automatic weekly goal tests passed: seasonal raid totals, M+ counters, nine Vault slots, tracked quests, offline snapshots, reset, API failures and restricted values.")
