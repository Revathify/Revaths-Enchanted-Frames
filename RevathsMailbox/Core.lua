local addonName, ns = ...
local MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE or 16

ns.name = addonName
ns.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")) or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "unknown"
ns.colors = {
    bg = { 0.035, 0.047, 0.071, 0.98 },
    panel = { 0.065, 0.082, 0.115, 0.98 },
    panelAlt = { 0.09, 0.11, 0.15, 1 },
    border = { 0.18, 0.23, 0.31, 1 },
    accent = { 0.18, 0.72, 0.78, 1 },
    accent2 = { 0.40, 0.86, 0.69, 1 },
    text = { 0.90, 0.93, 0.96, 1 },
    muted = { 0.56, 0.62, 0.70, 1 },
    danger = { 0.92, 0.33, 0.38, 1 },
}

local events = CreateFrame("Frame")
ns.events = events

local function RealmKey()
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    return realm or "UnknownRealm"
end

local function NormalizeRealm(realm)
    realm = type(realm) == "string" and realm or "UnknownRealm"
    return string.lower((realm:gsub("[%s%-']", "")))
end

local function StoredRealmKey(realm)
    realm = type(realm) == "string" and realm or "UnknownRealm"
    return (realm:gsub("[%s%-']", ""))
end

function ns:CharacterKey()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
    if not name or not realm then return nil end
    return NormalizeRealm(realm) .. ":" .. string.lower(name)
end

function ns:MigrateCharacters()
    local migrated = {}
    for _, character in pairs(self.db.characters) do
        if type(character) == "table" and character.name then
            character.realmKey = StoredRealmKey(character.realmKey or character.realm)
            local identity = NormalizeRealm(character.realmKey or character.realm) .. ":" .. string.lower(character.name)
            local existing = migrated[identity]
            if not existing then
                migrated[identity] = character
            else
                local newest, older = existing, character
                if (character.lastSeen or 0) > (existing.lastSeen or 0) then newest, older = character, existing end
                if (newest.money or 0) == 0 and (older.money or 0) > 0 then newest.money = older.money end
                if (older.level or 0) > (newest.level or 0) then newest.level = older.level end
                newest.classFile = newest.classFile or older.classFile
                newest.faction = newest.faction or older.faction
                newest.realm = newest.realm or older.realm
                local newestScan = newest.inbox and newest.inbox.scannedAt or 0
                local olderScan = older.inbox and older.inbox.scannedAt or 0
                if olderScan > newestScan or not newest.inbox then newest.inbox = older.inbox end
                newest.lastSeen = math.max(newest.lastSeen or 0, older.lastSeen or 0)
                migrated[identity] = newest
            end
        end
    end
    self.db.characters = migrated
end

function ns:ImportLegacyDatabase(legacy)
    if type(legacy) ~= "table" then return end
    if type(legacy.settings) == "table" and not next(RevathsMailboxDB.settings or {}) then
        RevathsMailboxDB.settings = legacy.settings
    end
    if type(legacy.characters) ~= "table" then return end
    for key, character in pairs(legacy.characters) do
        local importKey = "legacy:" .. tostring(key)
        while RevathsMailboxDB.characters[importKey] do importKey = "legacy:" .. importKey end
        RevathsMailboxDB.characters[importKey] = character
    end
end

function ns:InitDatabase()
    if type(RevathsMailboxDB) ~= "table" then RevathsMailboxDB = {} end
    RevathsMailboxDB.characters = RevathsMailboxDB.characters or {}
    RevathsMailboxDB.settings = RevathsMailboxDB.settings or {}
    self:ImportLegacyDatabase(RevathsMailDB)
    self:ImportLegacyDatabase(AltMailDB)
    RevathsMailDB = nil
    AltMailDB = nil
    RevathsMailboxDB.settings.scale = math.max(0.65, math.min(1.10, tonumber(RevathsMailboxDB.settings.scale) or 1))
    RevathsMailboxDB.settings.modernOpacity = math.max(0.55, math.min(1, tonumber(RevathsMailboxDB.settings.modernOpacity) or 0.96))
    if type(RevathsMailboxDB.settings.palette) ~= "string" then RevathsMailboxDB.settings.palette = "midnight" end
    if type(RevathsMailboxDB.settings.font) ~= "string" then RevathsMailboxDB.settings.font = "friz" end
    if RevathsMailboxDB.settings.showOfflineContacts == nil then RevathsMailboxDB.settings.showOfflineContacts = true end
    if RevathsMailboxDB.settings.tooltipHelperEnabled == nil then RevathsMailboxDB.settings.tooltipHelperEnabled = true end
    if RevathsMailboxDB.settings.skin ~= "classic" then RevathsMailboxDB.settings.skin = "modern" end
    self.db = RevathsMailboxDB
    self:MigrateCharacters()
    RevathsMailboxDB.version = 4
    self:UpdateCharacter(true)
end

function ns:UpdateCharacter(preserveKnownMoney)
    if not self.db then return end
    local key = self:CharacterKey()
    if not key then return end
    local entry = self.db.characters[key] or {}
    local _, classFile = UnitClass("player")
    entry.name = UnitName("player")
    entry.realm = GetRealmName()
    entry.realmKey = RealmKey()
    entry.classFile = classFile
    entry.level = UnitLevel("player")
    entry.faction = UnitFactionGroup("player")
    local currentMoney = GetMoney and GetMoney()
    if type(currentMoney) == "number" then
        if not (preserveKnownMoney and currentMoney == 0 and (entry.money or 0) > 0) then
            entry.money = currentMoney
        end
    end
    entry.money = entry.money or 0
    entry.lastSeen = time()
    entry.inbox = entry.inbox or { loaded = 0, total = 0, unread = 0, money = 0, items = 0 }
    self.db.characters[key] = entry
    self.character = entry
end

function ns:ScanInbox()
    if not self.character or not GetInboxNumItems then return end
    local loaded, total = GetInboxNumItems()
    local summary = { loaded = loaded or 0, total = total or loaded or 0, unread = 0, money = 0, items = 0 }
    for i = 1, summary.loaded do
        local _, _, _, _, money, _, _, hasItem, wasRead = GetInboxHeaderInfo(i)
        summary.money = summary.money + (money or 0)
        if not wasRead then summary.unread = summary.unread + 1 end
        if hasItem then
            for slot = 1, MAX_RECEIVE do
                if GetInboxItem(i, slot) then summary.items = summary.items + 1 end
            end
        end
    end
    summary.scannedAt = time()
    self.character.inbox = summary
    self.character.money = GetMoney()
    self.character.lastSeen = time()
end

function ns:GetAlts()
    local out = {}
    if not self.db then return out end
    local me = self:CharacterKey()
    for key, character in pairs(self.db.characters) do
        if key ~= me then out[#out + 1] = character end
    end
    table.sort(out, function(a, b)
        if (a.realmKey or "") == (b.realmKey or "") then return (a.name or "") < (b.name or "") end
        return (a.realm or "") < (b.realm or "")
    end)
    return out
end

function ns:GetRecipientName(character)
    if not character or not character.name then return "" end
    if character.realmKey and NormalizeRealm(character.realmKey) ~= NormalizeRealm(RealmKey()) then
        return character.name .. "-" .. StoredRealmKey(character.realmKey)
    end
    return character.name
end

function ns:GetContacts()
    local contacts, seen = {}, {}
    local playerName, playerRealm = UnitFullName and UnitFullName("player")
    playerName = playerName or UnitName("player")
    playerRealm = playerRealm or RealmKey()

    local function IsCurrentCharacter(name)
        if not name or not playerName then return false end
        local shortName, realm = string.match(name, "^([^-]+)%-(.+)$")
        shortName = shortName or name
        if string.lower(shortName) ~= string.lower(playerName) then return false end
        if not realm or realm == "" then return true end
        return NormalizeRealm(realm) == NormalizeRealm(playerRealm)
    end

    local function Add(name, kind, online, detail, classFile)
        if not name or name == "" then return end
        local key = Ambiguate and Ambiguate(name, "none") or name
        if IsCurrentCharacter(key) then return end
        local lowered = string.lower(key)
        local existing = seen[lowered]
        if existing then
            existing.sources[kind] = true
            if existing.kind ~= kind and not string.find(existing.kind, kind, 1, true) then
                existing.kind = existing.kind .. " / " .. kind
            end
            existing.online = existing.online or online
            return
        end
        local row = { name = key, kind = kind, online = online, detail = detail, classFile = classFile, sources = { [kind] = true } }
        seen[lowered] = row
        contacts[#contacts + 1] = row
    end

    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info then Add(info.name, "Friend", info.connected, info.area, nil) end
        end
    end

    if C_BattleNet and C_BattleNet.GetFriendAccountInfo and C_BattleNet.GetFriendNumGameAccounts and
       C_BattleNet.GetFriendGameAccountInfo and BNGetNumFriends then
        local numBNetFriends = BNGetNumFriends()
        for friendIndex = 1, (numBNetFriends or 0) do
            local numGameAccounts = C_BattleNet.GetFriendNumGameAccounts(friendIndex) or 0
            for accountIndex = 1, numGameAccounts do
                local game = C_BattleNet.GetFriendGameAccountInfo(friendIndex, accountIndex)
                local isWoW = game and (game.clientProgram == BNET_CLIENT_WOW or game.clientProgram == "WoW")
                local isCurrentProject = game and (not game.wowProjectID or not WOW_PROJECT_ID or game.wowProjectID == WOW_PROJECT_ID)
                local isCurrentRegion = game and game.isInCurrentRegion ~= false
                if isWoW and game.isOnline and isCurrentProject and isCurrentRegion and game.characterName then
                    local realm = game.realmName or game.realmDisplayName
                    local recipient = game.characterName
                    if realm and NormalizeRealm(realm) ~= NormalizeRealm(RealmKey()) then
                        recipient = recipient .. "-" .. StoredRealmKey(realm)
                    end
                    local location = game.areaName or game.realmDisplayName or realm or "Online"
                    Add(recipient, "Battle.net", true, "Battle.net friend · " .. location, game.classFilename)
                end
            end
        end
    end

    if IsInGuild() then
        for i = 1, GetNumGuildMembers() do
            local name, rank, _, level, _, zone, _, _, online, _, classFile = GetGuildRosterInfo(i)
            Add(name, "Guild", online, rank and (rank .. " · " .. (zone or "")) or zone, classFile)
        end
    end

    table.sort(contacts, function(a, b)
        if a.online ~= b.online then return a.online end
        if a.kind ~= b.kind then return a.kind < b.kind end
        return a.name < b.name
    end)
    return contacts
end

function ns:FormatMoney(copper)
    copper = math.max(0, tonumber(copper) or 0)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local coin = copper % 100
    if gold > 0 then return string.format("%dg %02ds %02dc", gold, silver, coin) end
    if silver > 0 then return string.format("%ds %02dc", silver, coin) end
    return string.format("%dc", coin)
end

function ns:FormatAge(timestamp)
    if not timestamp then return "Never" end
    local delta = math.max(0, time() - timestamp)
    if delta < 3600 then return math.floor(delta / 60) .. "m ago" end
    if delta < 86400 then return math.floor(delta / 3600) .. "h ago" end
    return math.floor(delta / 86400) .. "d ago"
end

function ns:DisableBlizzardMailbox()
    if MailFrame and MailFrame.UnregisterEvent then
        MailFrame:UnregisterEvent("MAIL_SHOW")
        MailFrame:SetAlpha(0)
        MailFrame:EnableMouse(false)
    end
end

local function IsMailboxInteraction(interactionType)
    local interactionTypes = Enum and Enum.PlayerInteractionType
    if not interactionTypes then return false end
    return interactionType == interactionTypes.MailInfo
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_MONEY")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("MAIL_SHOW")
events:RegisterEvent("MAIL_CLOSED")
events:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
events:RegisterEvent("MAIL_INBOX_UPDATE")
events:RegisterEvent("MAIL_SUCCESS")
events:RegisterEvent("MAIL_SEND_SUCCESS")
events:RegisterEvent("MAIL_FAILED")
events:RegisterEvent("FRIENDLIST_UPDATE")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("BN_CONNECTED")
events:RegisterEvent("BN_FRIEND_INFO_CHANGED")
events:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
events:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
events:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_UIMailPanel" then ns:DisableBlizzardMailbox() end
    elseif event == "PLAYER_LOGIN" then
        ns:InitDatabase()
        if C_AddOns and C_AddOns.LoadAddOn then
            C_AddOns.LoadAddOn("Blizzard_UIMailPanel")
        elseif LoadAddOn then
            LoadAddOn("Blizzard_UIMailPanel")
        end
        ns:DisableBlizzardMailbox()
        if C_FriendList and C_FriendList.ShowFriends then C_FriendList.ShowFriends() end
        if IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        ns:UpdateCharacter(true)
        if C_Timer and C_Timer.After then
            C_Timer.After(2, function()
                ns:UpdateCharacter(false)
                if ns.RefreshAlts then ns:RefreshAlts() end
            end)
        end
    elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_MONEY" or event == "BAG_UPDATE_DELAYED" then
        ns:UpdateCharacter(false)
        if ns.RefreshAlts then ns:RefreshAlts() end
    elseif event == "PLAYER_LOGOUT" then
        ns:UpdateCharacter(true)
    elseif event == "MAIL_SHOW" then
        ns.mailOpen = true
        ns:DisableBlizzardMailbox()
        ns:UpdateCharacter()
        CheckInbox()
        if ns.Show then ns:Show() end
    elseif event == "MAIL_CLOSED" then
        ns.mailOpen = false
        if ns.StopOpenAll then ns:StopOpenAll() end
        if ns.Hide then ns:Hide(true) end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and IsMailboxInteraction(arg1) then
        if ns.mailOpen then
            ns.mailOpen = false
            if ns.StopOpenAll then ns:StopOpenAll() end
            if ns.Hide then ns:Hide(true) end
        end
    elseif event == "MAIL_INBOX_UPDATE" then
        ns:ScanInbox()
        if ns.RefreshInbox then ns:RefreshInbox() end
        if ns.RefreshAlts then ns:RefreshAlts() end
        if ns.OnOpenAllMailEvent then ns:OnOpenAllMailEvent() end
    elseif event == "MAIL_SUCCESS" then
        if ns.OnOpenAllMailEvent then ns:OnOpenAllMailEvent() end
    elseif event == "MAIL_SEND_SUCCESS" then
        if ns.OnMailSent then ns:OnMailSent() end
    elseif event == "MAIL_FAILED" then
        local stopped = ns.StopOpenAll and ns:StopOpenAll("Open all stopped. Check your bag space and try again.", true)
        if not stopped and ns.SetStatus then ns:SetStatus("Mail action failed.", true) end
    elseif event == "FRIENDLIST_UPDATE" or event == "GUILD_ROSTER_UPDATE" or
           event == "BN_CONNECTED" or event == "BN_FRIEND_INFO_CHANGED" or
           event == "BN_FRIEND_LIST_SIZE_CHANGED" or event == "BN_FRIEND_ACCOUNT_ONLINE" or
           event == "BN_FRIEND_ACCOUNT_OFFLINE" then
        if ns.RefreshContacts then ns:RefreshContacts() end
    end
end)

SLASH_REVATHSMAILBOX1 = "/revathsmailbox"
SLASH_REVATHSMAILBOX2 = "/rmail"
SlashCmdList.REVATHSMAILBOX = function()
    if ns.mailOpen then ns:Show() else print("|cff2eb8c7Revath's Enchanted Mailbox:|r Visit a mailbox to open the interface.") end
end
