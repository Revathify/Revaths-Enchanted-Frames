-- Run from the repository root with Lua 5.1.
local now, reset = 1800000000, 1800003600
GetServerTime=function() return now end
GetCurrentRegion=function() return 3 end
UnitFullName=function() return "Alice","Realm" end
UnitGUID=function() return "Player-Alice" end
UnitClass=function() return "Mage","MAGE" end
GetRealmName=function() return "Realm" end
InCombatLockdown=function() return false end
date=os.date
SlashCmdList={}
C_DateAndTime={GetSecondsUntilWeeklyReset=function() return reset-now end}
C_Timer={After=function() end,NewTicker=function() end}
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
Enum={QuestFrequency={Weekly=2}}
local completed={[93691]=true,[93530]=true,[88673]=true,[88674]=true,[88675]=true,
    [90573]=true,[91095]=true,[91096]=true}
local quests={{questID=89507,title="Abundant Offerings",frequency=0,isHeader=false},
    {questID=91097,title="Prey hunt",frequency=0,isHeader=false}}
C_QuestLog={
    GetNumQuestLogEntries=function() return #quests end,
    GetInfo=function(index) return quests[index] end,
    GetTitleForQuestID=function(id) return "Quest "..id end,
    IsQuestFlaggedCompleted=function(id) return completed[id] or false end,
    IsOnQuest=function(id) for _,q in ipairs(quests) do if q.questID==id then return true end end; return false end,
    IsComplete=function() return false end,
    GetQuestObjectives=function() return {{text="Collect: 2/5",numFulfilled=2,numRequired=5}} end,
}
C_TaskQuest={IsActive=function(id) return id==91390 end}
GetProfessions=function() return 1,2 end
local failProfession=false
GetProfessionInfo=function(index)
    if failProfession then error("restricted profession") end
    return index==1 and "Blacksmithing" or "Mining",nil,10,100,nil,nil,index==1 and 164 or 186
end
C_TradeSkillUI={GetProfessionInfoBySkillLineID=function() return {skillLevel=10} end}
local currencies={}
local function Currency(id,name,quantity,earned,weeklyCap,seasonCap,totalEarned,weekly,seasonal)
    currencies[id]={name=name,quantity=quantity,quantityEarnedThisWeek=earned,maxWeeklyQuantity=weeklyCap,
        maxQuantity=seasonCap,totalEarned=totalEarned,canEarnPerWeek=weekly,useTotalEarnedForMaxQty=seasonal,isTypeUnused=false}
end
Currency(3028,"Restored Coffer Keys",3,0,0,0,0,false,false)
Currency(3310,"Coffer Key Shards",50,450,600,0,0,true,false)
Currency(3445,"Hero Mistcrest",20,0,0,1000,650,false,true)
Currency(3442,"Adventurer Mistcrest",9,0,0,0,0,false,false)
currencies[3445].iconFileID=123456
Currency(3316,"Voidlight Marl",12500,0,0,0,0,false,false)
Currency(2803,"Undercoin",0,0,0,0,0,false,false)
Currency(3405,"Field Accolade",30,200,900,0,0,true,false)
currencies[3316].iconFileID=654321
local failCurrency=false
local secretValue={}
issecretvalue=function(value) return value==secretValue end
C_CurrencyInfo={GetCurrencyInfo=function(id) if failCurrency then error("restricted currency") end; return currencies[id] end}
local ns={}
for _,file in ipairs({"Core","Catalog","Activities","Progress","Details"}) do
    assert(loadfile("RevathsWeeklyPlanner/"..file..".lua"))("RevathsWeeklyPlanner",ns)
end
ns:InitializeDatabase(); ns:TrackCurrentCharacter(); ns:CaptureWeeklyProgress()
local key=ns.currentKey
local character=ns.db.characters[key]
local function Goal(id,targetKey)
    for _,goal in ipairs(ns:GetGoals(targetKey or key,true)) do if goal.id==id then return goal end end
end
local function CrestDetails()
    local lines={}
    for _, row in ipairs(ns:GetCrestInfo(character)) do
        for _, line in ipairs(row.details) do lines[#lines+1]=line end
    end
    return table.concat(lines,"\n")
end
local resources=ns:GetResourceInfo(character)
assert(resources[1].name=="Voidlight Marl" and resources[1].quantity==12500 and resources[1].icon==654321)
assert(resources[2].name=="Undercoin" and resources[2].quantity==0, "zero is a known balance, not missing data")
local field
for _,row in ipairs(resources) do if row.name=="Field Accolade" then field=row end end
assert(field.allowance=="700 more this week", "resource allowances follow Blizzard counters")
local function Details(id) local _,lines=ns:GetGoalDetails(key,id); return table.concat(lines,"\n") end
local hero
for _,row in ipairs(ns:GetCrestInfo(character)) do if row.name=="Hero Mistcrest" then hero=row end end
assert(hero.icon==123456 and character.resources[3445].icon==123456, "real currency icons are saved for offline characters")
assert(hero.allowance=="350 more this season" and hero.quantity==20, "human-readable allowance stays separate from owned currency")
currencies[3445].iconFileID=secretValue; ns:CaptureWeeklyProgress()
assert(character.resources[3445].icon==123456, "restricted icon metadata preserves the previous public icon without losing balances")
currencies[3445].iconFileID=123456
currencies[3445].totalEarned=1000; ns:CaptureWeeklyProgress()
for _,row in ipairs(ns:GetCrestInfo(character)) do if row.name=="Hero Mistcrest" then assert(row.atLimit and row.allowance=="Limit reached") end end
currencies[3445].totalEarned=650; ns:CaptureWeeklyProgress()
assert(not Goal("auto:crests"), "crest information never appears as a selectable goal")
assert(Goal("auto:shards").title:find("450/600",1,true))
assert(Details("auto:shards"):find("150 remaining",1,true) and Details("auto:shards"):find("Keys available: 3",1,true))
currencies[3310].quantity=0; currencies[3028].quantity=2; ns:CaptureWeeklyProgress()
assert(Goal("auto:shards").title:find("450/600",1,true),"spending/conversion must not alter earned count")
assert(CrestDetails():find("Season earnings: 650/1000 - 350 remaining",1,true),"season cap uses total earned, not balance")
assert(not CrestDetails():find("Weekly earnings",1,true),"never invent a weekly cap for season-limited crests")
assert(Goal("auto:profession:164").title:find("2/4",1,true),"weekly quest and treasure completion")
assert(Goal("auto:profession:186").title:find("3/8",1,true),"gathering-drop slots and treatise")
assert(not Goal("auto:profession:171"),"hide foreign professions")
assert(Goal("auto:world:soiree").title:find("1/1",1,true),"unoffered faction variants do not inflate total")
assert(Goal("auto:world:preynormal").title:find("2/4",1,true),"distinct prey reward flags count toward verified milestone")
assert(Goal("auto:world:assignments") and Goal("auto:world:abundance"),"active world assignments and accepted event quests have named rows")
assert(Goal("auto:quests").countsForProgress==false,"aggregate quest summary does not double count named activities")
local saved=character.weekly.currencies[3310]
failCurrency=true; failProfession=true; ns:CaptureWeeklyProgress()
assert(character.resources[3316].quantity==12500, "failed resource reads retain saved balances")
assert(character.weekly.currencies[3310]==saved and Goal("auto:profession:164"),"partial/restricted APIs preserve snapshots")
failCurrency=false; failProfession=false
currencies[3310].quantity=secretValue; ns:CaptureWeeklyProgress()
assert(character.weekly.currencies[3310]==saved,"secret numeric values cannot overwrite safe currency data")
currencies[3310].quantity=0
currencies[3310].maxWeeklyQuantity=750; ns:CaptureWeeklyProgress()
assert(Goal("auto:shards").title:find("450/750",1,true),"limits follow live API updates")
currencies[3445].isTypeUnused=true; ns:CaptureWeeklyProgress()
assert(not CrestDetails():find("Hero Mistcrest",1,true),"retired currencies disappear")
ns.db.characters.alt={name="Alt",realm="Realm",region=3,goals={},nextID=1,weekly=character.weekly,
    resources=character.resources,professions=character.professions,resetAt=reset}
character.weeklyOverrides={ ["auto:crests"]=true }
character.hiddenGoals={ ["auto:crests"]=true }
local crestRows=ns:GetCrestInfo(character)
assert(#crestRows==1 and crestRows[1].quantity==9, "old completion/visibility overrides never hide crest information")
local _,before=ns:GetProgress(character)
character.resources[3443]={name="Veteran Mistcrest",quantity=77,capturedAt=now}
local _,withCrests=ns:GetProgress(character)
assert(before==withCrests, "crest balances never change completion totals")
assert(ns:GetCrestInfo({resources={[3443]={name="Veteran Mistcrest",quantity=12,capturedAt=now}}})[1].quantity==12,
    "offline selected characters use their own saved balance")
ns:ToggleGoalVisibility(key,"auto:shards")
local _,after=ns:GetProgress(character)
assert(after==before-1 and #ns:GetGoals(key,true)>#ns:GetGoals(key),"hidden goals leave progress totals but remain configurable")
assert(Goal("auto:shards","alt"),"visibility preferences are per character")
ns:ToggleGoal(key,"auto:world:abundance")
assert(Goal("auto:world:abundance").done,"new named goals retain manual completion")
ns:InitializeDatabase(); assert(character.hiddenGoals["auto:shards"],"preferences survive reload")
now=reset+1; reset=reset+604800; completed={}; ns:CheckWeeklyReset()
assert(ns:GetResourceInfo(character)[1].quantity==12500 and ns:GetResourceInfo(character)[1].stale, "offline resource balances survive weekly reset while allowances expire")
assert(not character.weekly and character.resources[3028].quantity==2,"weekly reset clears earnings, preserves saved balances")
assert(character.hiddenGoals["auto:shards"] and not character.weeklyOverrides,"visibility survives reset; completion does not")
assert(Goal("auto:profession:164").title:find("Waiting",1,true),"offline profession weeklies wait for fresh flags after reset")
assert(CrestDetails():find("Log into",1,true),"offline crest balances remain visible without stale earning limits")
print("Weekly activity tests passed: currency limits, conversion, profession sources, named events, Prey, partial APIs, offline/reset behavior and per-character visibility.")
