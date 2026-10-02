local _, ns = ...

local function Public(value)
    if issecretvalue and issecretvalue(value) then error("Restricted activity data") end
    return value
end
local function Number(value) value=Public(value); assert(type(value)=="number" and value>=0); return value end
local function Read(fn) local ok,value=pcall(fn); if ok then return value end end
local function Text(value, fallback) value=Public(value); return type(value)=="string" and value~="" and value or fallback end

local function Currency(id)
    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end
    return Read(function()
        local info=Public(C_CurrencyInfo.GetCurrencyInfo(id))
        assert(type(info)=="table")
        if Public(info.isTypeUnused)==true then return false end
        return { id=id, name=Text(info.name,"Currency "..id), quantity=Number(info.quantity),
            earned=Number(info.quantityEarnedThisWeek), weeklyCap=Number(info.maxWeeklyQuantity),
            seasonCap=Number(info.maxQuantity), totalEarned=Number(info.totalEarned),
            weekly=Public(info.canEarnPerWeek)==true, seasonal=Public(info.useTotalEarnedForMaxQty)==true,
            capturedAt=GetServerTime() }
    end)
end

function ns:CaptureActivities(character, snapshot)
    character.resources=character.resources or {}
    snapshot.currencies=snapshot.currencies or {}
    -- Balances persist across resets; earned/limit snapshots expire with this week's progress.
    for _, id in ipairs({3028,3310,3442,3443,3444,3445,3446}) do
        local currency=Currency(id)
        if currency then
            snapshot.currencies[id]=currency
            character.resources[id]={ name=currency.name, quantity=currency.quantity, capturedAt=currency.capturedAt }
        elseif currency==false then snapshot.currencies[id]=nil; character.resources[id]=nil end
    end
    local roster = GetProfessions and GetProfessionInfo and Read(function()
        local first,second=GetProfessions()
        local result={}
        for _, slot in pairs({Public(first),Public(second)}) do
            local name,_,_,_,_,_,baseID=GetProfessionInfo(slot)
            baseID=Number(baseID)
            local definition=self.knowledgeCatalog[baseID]
            if definition then
                local entry={name=Text(name,"Profession"), skill=definition.skill}
                local learned=C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID and Read(function()
                    local info=Public(C_TradeSkillUI.GetProfessionInfoBySkillLineID(definition.skill))
                    return Number(info.skillLevel)>0
                end)
                entry.learned=learned
                if learned==nil and character.professions and character.professions[baseID] then entry.learned=character.professions[baseID].learned end
                result[baseID]=entry
            end
        end
        return result
    end)
    if roster then character.professions=roster end
    snapshot.professions=snapshot.professions or {}
    for baseID, profession in pairs(character.professions or {}) do
        if profession.learned then
            local progress=Read(function()
                local definition=self.knowledgeCatalog[baseID]
                local sources={}
                local completed=false
                for _, id in ipairs(definition.weekly) do if Public(C_QuestLog.IsQuestFlaggedCompleted(id)) then completed=true end end
                sources[#sources+1]={name="Weekly profession quest",done=completed}
                sources[#sources+1]={name="Thalassian Treatise",done=Public(C_QuestLog.IsQuestFlaggedCompleted(definition.treatise))==true}
                for index,id in ipairs(definition.treasures or {}) do
                    sources[#sources+1]={name="Weekly treasure "..index,done=Public(C_QuestLog.IsQuestFlaggedCompleted(id))==true}
                end
                for index,id in ipairs(definition.drops or {}) do
                    sources[#sources+1]={name="Weekly gathering / disenchanting drop "..index,done=Public(C_QuestLog.IsQuestFlaggedCompleted(id))==true}
                end
                local done=0
                for _, source in ipairs(sources) do if source.done then done=done+1 end end
                return {sources=sources,done=done,total=#sources,capturedAt=GetServerTime()}
            end)
            if progress then snapshot.professions[baseID]=progress end
        end
    end
end

local function Allowance(currency)
    if currency.weekly and currency.weeklyCap>0 then return currency.earned,currency.weeklyCap,"Weekly" end
    if currency.seasonal and currency.seasonCap>0 then return currency.totalEarned,currency.seasonCap,"Season" end
end
local function CurrencyLines(currency)
    local lines={currency.name..": "..currency.quantity.." available"}
    local earned,cap,kind=Allowance(currency)
    if cap then
        lines[#lines+1]=string.format("%s earnings: %d/%d - %d remaining",kind,earned,cap,math.max(0,cap-earned))
    else lines[#lines+1]="No earning limit reported by Blizzard." end
    return lines
end

-- Informational balances belong to the selected character, never the goal checklist.
function ns:GetCrestInfo(character)
    local rows = {}
    local currencies = character and character.weekly and character.weekly.currencies or {}
    local balances = character and character.resources or {}
    for id = 3442, 3446 do
        local currency, balance = currencies[id], balances[id]
        if currency then
            local earned, cap, kind = Allowance(currency)
            rows[#rows + 1] = { name = currency.name, quantity = currency.quantity,
                summary = cap and string.format("%d held | %s %d/%d | %d left", currency.quantity, kind, earned, cap, math.max(0, cap-earned))
                    or (currency.quantity .. " held | No earning limit"),
                details = CurrencyLines(currency), capturedAt = currency.capturedAt }
        elseif balance then
            rows[#rows + 1] = { name = balance.name, quantity = balance.quantity,
                summary = balance.quantity .. " held (saved) | Allowance needs refresh",
                details = {balance.name .. ": " .. balance.quantity .. " available (saved)",
                    "Log into this character to refresh the earning allowance."}, capturedAt = balance.capturedAt }
        end
    end
    return rows
end

function ns:GetAdditionalGoals(character)
    local snapshot,goals=character.weekly or {},{}
    local currencies=snapshot.currencies or {}
    local shards=currencies[3310]
    local balances=character.resources or {}
    if shards or balances[3310] or balances[3028] then
        local earned,cap
        if shards then earned,cap=Allowance(shards) end
        local details=shards and CurrencyLines(shards) or {"Log into this character to refresh this week's shard earnings."}
        if balances[3028] then details[#details+1]="Restored Coffer Keys available: "..balances[3028].quantity end
        if balances[3310] then details[#details+1]="Unconverted shards available: "..balances[3310].quantity end
        details[#details+1]="Converting or spending keys does not reduce shards earned this week."
        goals[#goals+1]={id="auto:shards",automatic=true,done=cap and earned>=cap or false,details=details,
            capturedAt=shards and shards.capturedAt or (balances[3028] or balances[3310]).capturedAt,
            title="Coffer keys / shards - "..(cap and string.format("%d/%d earned",earned,cap) or (shards and "No earning limit" or "Log in to update"))}
    end
    local professions={}
    for baseID,profession in pairs(character.professions or {}) do professions[#professions+1]={id=baseID,info=profession} end
    table.sort(professions,function(a,b) return a.info.name<b.info.name end)
    for _,entry in ipairs(professions) do
        if entry.info.learned~=false then
            local progress=(snapshot.professions or {})[entry.id]
            local details={"Tracks weekly sources, not total knowledge points or one-time treasures."}
            for _,source in ipairs(progress and progress.sources or {}) do details[#details+1]=(source.done and "[Done] " or "[Remaining] ")..source.name end
            if not progress then details[#details+1]="Learn Midnight skills and open this character's profession window to refresh." end
            goals[#goals+1]={id="auto:profession:"..entry.id,automatic=true,done=progress and progress.done>=progress.total or false,
                details=details,capturedAt=progress and progress.capturedAt,
                title=entry.info.name.." knowledge sources - "..(progress and string.format("%d/%d",progress.done,progress.total) or "Waiting for profession data")}
        end
    end
    for _,group in ipairs(self.worldCatalog) do
        local done,total,details=0,0,{}
        for _,id in ipairs(group.quests) do
            local quest=(snapshot.quests or {})[id]
            if quest then
                total=total+1; if quest.done then done=done+1 end
                details[#details+1]=(quest.done and "[Done] " or (quest.ready and "[Ready to turn in] " or "[In progress] "))..quest.name
                if not quest.done then for _,objective in ipairs(quest.objectives or {}) do details[#details+1]="  "..objective.text end end
            end
        end
        if total>0 then
            local target=group.target or total
            details[#details+1]=group.target and "Counts distinct weekly reward hunt flags; repeated hunts are not additional weekly rewards."
                or "Only accepted or completed quests are counted; unoffered variants are excluded."
            goals[#goals+1]={id="auto:world:"..group.key,automatic=true,done=done>=target,details=details,capturedAt=snapshot.questsUpdatedAt,
                title=group.name.." - "..string.format("%d/%d",done,target)}
        end
    end
    return goals
end
