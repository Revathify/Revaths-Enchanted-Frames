local _, ns = ...

local function Identity(name, realm)
    return (realm or ""):lower():gsub("[%s%-']", "") .. ":" .. (name or ""):lower()
end

function ns:FindCharacter(name, realm, region)
    local identity = Identity(name, realm)
    for key, character in pairs(self.db.characters) do
        if character.region == region and Identity(character.name, character.realm) == identity then return key, character end
    end
end

function ns:ImportMailboxCharacters()
    if not self.db or type(RevathsMailboxDB) ~= "table" then return end
    local region = GetCurrentRegion and GetCurrentRegion() or 0
    for _, source in pairs(RevathsMailboxDB.characters or {}) do
        if type(source) == "table" and type(source.name) == "string" and type(source.realm) == "string"
            and (source.region == nil or source.region == region) then
            local key, character = self:FindCharacter(source.name, source.realm, region)
            if not character then
                key = tostring(region) .. ":mailbox:" .. Identity(source.name, source.realm)
                character = { name = source.name, realm = source.realm, region = region, goals = {}, nextID = 1 }
                self.db.characters[key] = character
            end
            character.class = character.class or source.classFile
            character.lastSeen = math.max(character.lastSeen or 0, source.lastSeen or 0)
        end
    end
end

local function Public(value)
    if issecretvalue and issecretvalue(value) then error("Raid information is restricted") end
    return value
end

function ns:RequestRaidRefresh()
    if not self.currentKey or not RequestRaidInfo then return end
    self.awaitingRaidInfo = true
    local ok = pcall(RequestRaidInfo)
    if not ok then
        self.raidInfoUnavailable = true
        if self.Refresh then self:Refresh() end
    end
end

function ns:CaptureRaidInfo()
    if not self.currentKey or not self.awaitingRaidInfo then return end
    if InCombatLockdown and InCombatLockdown() then self.pendingRaidInfo = true; return end
    self.pendingRaidInfo = nil
    local ok, raids = pcall(function()
        local result, now = {}, GetServerTime()
        local count = Public(GetNumSavedInstances())
        assert(type(count) == "number")
        for index = 1, count do
            local name, id, seconds, difficulty, locked, extended, idHigh, isRaid, maxPlayers,
                difficultyName, encounters, progress = GetSavedInstanceInfo(index)
            Public(isRaid); Public(locked); Public(extended)
            if isRaid and (locked or extended) then
                Public(name); Public(id); Public(seconds); Public(difficulty); Public(idHigh)
                Public(difficultyName); Public(encounters); Public(progress)
                assert(type(name) == "string" and type(seconds) == "number" and type(encounters) == "number")
                local raid = { name = name, id = id, idHigh = idHigh, difficultyID = difficulty,
                    difficultyName = difficultyName or "", resetAt = now + math.max(0, seconds),
                    extended = extended == true, bosses = {}, killed = 0 }
                for bossIndex = 1, encounters do
                    local bossName, _, killed = GetSavedInstanceEncounterInfo(index, bossIndex)
                    Public(bossName); Public(killed)
                    assert(type(bossName) == "string" and type(killed) == "boolean")
                    raid.bosses[#raid.bosses + 1] = { name = bossName, killed = killed }
                    if killed then raid.killed = raid.killed + 1 end
                end
                result[#result + 1] = raid
            end
        end
        return result
    end)
    local character = self.db.characters[self.currentKey]
    if ok then
        character.raids, character.raidsUpdatedAt = raids, GetServerTime()
        self.awaitingRaidInfo = nil
    end
    self.raidInfoUnavailable = not ok
    if self.Refresh then self:Refresh() end
end

function ns:GetRaidEntries(key)
    local character = self.db and self.db.characters[key]
    local entries, now = {}, GetServerTime()
    for _, raid in ipairs(character and character.raids or {}) do
        if raid.resetAt > now then
            entries[#entries + 1] = { raid = raid }
            for _, boss in ipairs(raid.bosses) do
                if not self.db.unfinishedOnly or not boss.killed then entries[#entries + 1] = { boss = boss } end
            end
        end
    end
    return entries
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UPDATE_INSTANCE_INFO", "ENCOUNTER_END", "PLAYER_REGEN_ENABLED" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, encounterID, encounterName, difficultyID, groupSize, success)
    if event == "UPDATE_INSTANCE_INFO" then ns:CaptureRaidInfo()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.pendingRaidInfo then ns:CaptureRaidInfo() end
    elseif event == "ENCOUNTER_END" then
        if success == 1 then C_Timer.After(2, function() ns:RequestRaidRefresh() end) end
    else
        if ns.db then ns:TrackCurrentCharacter(); ns:ImportMailboxCharacters(); ns:RequestRaidRefresh() end
    end
end)
