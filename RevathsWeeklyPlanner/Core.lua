local addonName, ns = ...

ns.title = "Revath's Enchanted Weekly Planner"

local function Now() return GetServerTime() end
local function Region() return GetCurrentRegion and GetCurrentRegion() or 0 end

local function NextReset(now)
    if not C_DateAndTime or not C_DateAndTime.GetSecondsUntilWeeklyReset then return end
    local ok, seconds = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset)
    if not ok or (issecretvalue and issecretvalue(seconds)) or type(seconds) ~= "number"
        or seconds <= 0 or seconds > 8 * 86400 then return end
    return now + seconds
end

function ns:InitializeDatabase()
    if type(RevathsWeeklyPlannerDB) ~= "table" then RevathsWeeklyPlannerDB = {} end
    self.db = RevathsWeeklyPlannerDB
    local db = self.db
    db.characters = type(db.characters) == "table" and db.characters or {}
    db.skin = db.skin == "classic" and "classic" or "modern"
    db.palette = type(db.palette) == "string" and db.palette or "midnight"
    db.font = type(db.font) == "string" and db.font or "friz"
    db.opacity = math.max(.60, math.min(1, tonumber(db.opacity) or .96))
    db.scale = math.max(.70, math.min(1.15, tonumber(db.scale) or 1))
    db.window = type(db.window) == "table" and db.window or {}
    db.unfinishedOnly = db.unfinishedOnly == true
    for key, character in pairs(db.characters) do
        if type(character) ~= "table" then
            db.characters[key] = nil
        else
            character.goals = type(character.goals) == "table" and character.goals or {}
            local valid, largestID = {}, 0
            for _, goal in ipairs(character.goals) do
                if type(goal) == "table" and type(goal.id) == "number" and type(goal.title) == "string" then
                    goal.done = goal.done == true
                    valid[#valid + 1] = goal
                    largestID = math.max(largestID, goal.id)
                end
            end
            character.goals = valid
            character.nextID = math.max(tonumber(character.nextID) or 1, largestID + 1)
        end
    end
end

function ns:CheckWeeklyReset()
    if not self.db then return end
    local now = Now()
    local nextReset = NextReset(now)
    self.nextReset = nextReset
    -- No guessed weekday or client timezone: keep progress if Blizzard's clock is unavailable.
    if not nextReset then return end
    for _, character in pairs(self.db.characters) do
        if character.region == Region() then
            if type(character.resetAt) == "number" and now >= character.resetAt then
                for _, goal in ipairs(character.goals) do goal.done = false end
            end
            character.resetAt = nextReset
        end
    end
end

function ns:TrackCurrentCharacter()
    if not self.db then return end
    local name, realm = UnitFullName("player")
    if not name then return end
    realm = realm and realm ~= "" and realm or GetRealmName()
    local guid = UnitGUID("player")
    local key = tostring(Region()) .. ":" .. (guid or (realm .. ":" .. name))
    local character = self.db.characters[key]
    if not character and self.FindCharacter then
        local previousKey
        previousKey, character = self:FindCharacter(name, realm, Region())
        if character then
            self.db.characters[previousKey] = nil
            self.db.characters[key] = character
            if self.removedGoal and self.removedGoal.key == previousKey then self.removedGoal.key = key end
        end
    end
    if not character then
        character = { goals = {}, nextID = 1 }
        self.db.characters[key] = character
    end
    character.name, character.realm, character.region = name, realm, Region()
    character.class = select(2, UnitClass("player"))
    character.lastSeen = Now()
    self.currentKey = key
    self:CheckWeeklyReset()
    if self.InitializeMinimap then self:InitializeMinimap() end
    if self.Refresh then self:Refresh() end
end

function ns:GetProgress(character)
    local done = 0
    for _, goal in ipairs(character.goals) do if goal.done then done = done + 1 end end
    return done, #character.goals
end

function ns:GetCharacters(includeRaids)
    local list = {}
    if not self.db then return list end
    for key, character in pairs(self.db.characters) do
        local done, total = self:GetProgress(character)
        local pendingRaid = false
        if includeRaids then
            for _, raid in ipairs(character.raids or {}) do
                if raid.resetAt > Now() and raid.killed < #raid.bosses then pendingRaid = true end
            end
        end
        if character.region == Region() and (not self.db.unfinishedOnly or total == 0 or done < total or pendingRaid) then
            list[#list + 1] = { key = key, character = character, done = done, total = total }
        end
    end
    table.sort(list, function(a, b)
        if (a.key == self.currentKey) ~= (b.key == self.currentKey) then return a.key == self.currentKey end
        local aName = (a.character.name or "") .. (a.character.realm or "")
        local bName = (b.character.name or "") .. (b.character.realm or "")
        return aName < bName
    end)
    return list
end

function ns:GetGoals(key)
    local character = self.db and self.db.characters[key]
    local list = {}
    for _, goal in ipairs(character and character.goals or {}) do
        if not self.db.unfinishedOnly or not goal.done then list[#list + 1] = goal end
    end
    return list
end

local function CleanTitle(title)
    if type(title) ~= "string" then return end
    title = title:gsub("[\r\n\t]", " "):match("^%s*(.-)%s*$")
    if title == "" then return end
    -- Keep saved text bounded without cutting a UTF-8 character in half.
    if #title > 160 then return end
    return title
end

function ns:SaveGoal(key, title, editID)
    self:CheckWeeklyReset()
    local character = self.db and self.db.characters[key]
    title = CleanTitle(title)
    if not character then return false, "Log into a character first." end
    if not title then return false, "Enter a short weekly goal." end
    for _, goal in ipairs(character.goals) do
        if goal.id ~= editID and goal.title:lower() == title:lower() then return false, "That goal is already on this character's list." end
    end
    if editID then
        for _, goal in ipairs(character.goals) do
            if goal.id == editID then goal.title = title; return true end
        end
        return false, "That goal has been removed. Add it again instead."
    end
    local id = character.nextID
    character.nextID = id + 1
    character.goals[#character.goals + 1] = { id = id, title = title, done = false }
    return true
end

function ns:ToggleGoal(key, id)
    self:CheckWeeklyReset()
    local character = self.db and self.db.characters[key]
    for _, goal in ipairs(character and character.goals or {}) do
        if goal.id == id then goal.done = not goal.done; return true end
    end
end

function ns:RemoveGoal(key, id)
    local character = self.db and self.db.characters[key]
    for index, goal in ipairs(character and character.goals or {}) do
        if goal.id == id then
            self.removedGoal = { key = key, index = index, resetAt = character.resetAt, goal = table.remove(character.goals, index) }
            return true
        end
    end
end

function ns:UndoRemove()
    self:CheckWeeklyReset()
    local removed = self.removedGoal
    local character = removed and self.db.characters[removed.key]
    if not character then return false end
    for _, goal in ipairs(character.goals) do
        if goal.title:lower() == removed.goal.title:lower() then return false end
    end
    -- A deleted goal restored after a reset must not carry last week's completion.
    if removed.resetAt and self.nextReset and Now() >= removed.resetAt then removed.goal.done = false end
    table.insert(character.goals, math.min(removed.index, #character.goals + 1), removed.goal)
    self.removedGoal = nil
    return true
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        ns:InitializeDatabase()
        if ns.ImportMailboxCharacters then ns:ImportMailboxCharacters() end
        if IsLoggedIn and IsLoggedIn() then
            ns:TrackCurrentCharacter()
            if ns.RequestRaidRefresh then ns:RequestRaidRefresh() end
        end
        C_Timer.NewTicker(60, function()
            ns:CheckWeeklyReset()
            if ns.Refresh then ns:Refresh() end
        end)
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        ns:TrackCurrentCharacter()
    end
end)

SLASH_REVATHSWEEKLYPLANNER1 = "/rweekly"
SLASH_REVATHSWEEKLYPLANNER2 = "/rplanner"
SlashCmdList.REVATHSWEEKLYPLANNER = function() if ns.Toggle then ns:Toggle() end end
