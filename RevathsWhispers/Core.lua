local _, ns = ...
ns.icon = "Interface\\AddOns\\RevathsWhispers\\Media\\WhispersIcon"
local MAX_CHATS, MAX_MESSAGES = 50, 100
local function Public(value)
    return not (issecretvalue and issecretvalue(value))
end
ns.Public = Public
local function Text(value)
    return Public(value) and type(value) == "string"
end
local function Now() return time() end

function ns:Initialize()
    RevathsWhispersDB = type(RevathsWhispersDB) == "table" and RevathsWhispersDB or {}
    self.db = RevathsWhispersDB
    self.db.settings = type(self.db.settings) == "table" and self.db.settings or {}
    local s = self.db.settings
    s.font, s.skin = s.font or "friz", s.skin or "native"
    s.fontSize = math.max(10, math.min(20, tonumber(s.fontSize) or 12))
    s.opacity = math.max(.55, math.min(1, tonumber(s.opacity) or .96))
    s.sound = s.sound or "tell"
    self.db.characters = type(self.db.characters) == "table" and self.db.characters or {}
    local id = UnitGUID("player")
    if not Text(id) then return false end
    self.db.characters[id] = self.db.characters[id] or { chats = {} }
    self.store = self.db.characters[id]
    self.store.chats = self.store.chats or {}
    self.restrictions = {}
    self.bnReady = {}
    return true
end

function ns:Locked()
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return true end
    -- The state-change event is authoritative while the API is dispatching it.
    for _, kind in ipairs({1, 2, 3, 4, 5}) do
        local state = self.restrictions and self.restrictions[kind]
        if state == 1 or state == 2 then return true end
        if state == nil and C_RestrictedActions and C_RestrictedActions.IsAddOnRestrictionActive
            and C_RestrictedActions.IsAddOnRestrictionActive(kind) then return true end
    end
    return false
end

function ns:Conversations(search)
    local result = {}
    search = Text(search) and search:lower() or ""
    for _, chat in pairs(self.store and self.store.chats or {}) do
        if search == "" or chat.label:lower():find(search, 1, true) then result[#result + 1] = chat end
    end
    table.sort(result, function(a,b)
        if a.updated == b.updated then return a.key < b.key end
        return a.updated > b.updated
    end)
    return result
end

function ns:GetChat(kind, target, label)
    if not self.store or not Public(target) then return end
    if kind == "wow" then
        if not Text(target) then return end
        target = target:match("^%s*(.-)%s*$")
        if target == "" or #target > 100 or target:find("[%s|]") then return end
    elseif kind == "bn" then
        if type(target) ~= "number" or target <= 0 then return end
    else return end
    local identity
    if kind == "bn" then
        local api = C_BattleNet and C_BattleNet.GetAccountInfoByID
        local ok, info
        if api then ok, info = pcall(api, target) end
        if not ok or not info or not Text(info.battleTag) or info.battleTag == "" then return end
        identity = info.battleTag:lower()
    end
    local key = kind .. ":" .. (kind == "wow" and target:lower() or identity)
    if kind == "bn" then self.bnReady[key] = target end
    local chat = self.store.chats[key]
    if not chat then
        local chats = self:Conversations()
        if #chats >= MAX_CHATS then
            -- Never evict an unread conversation, a draft, or the selected chat.
            local victim
            for i = #chats, 1, -1 do
                local c = chats[i]
                if (c.unread or 0) == 0 and (c.draft or "") == "" and c.key ~= self.selected then victim = c; break end
            end
            if not victim then return end
            self.store.chats[victim.key] = nil
        end
        chat = {key=key, kind=kind, target=target, label=Text(label) and label or tostring(target), messages={}, unread=0, draft="", updated=Now()}
        self.store.chats[key] = chat
    elseif Text(label) then chat.label = label; chat.target = target end
    return chat
end

function ns:Select(key)
    local chat = self.store and self.store.chats[key]
    if not chat then return end
    self.selected = key
    chat.unread = 0
    if self.Refresh then self:Refresh(true) end
    return chat
end

function ns:Notify()
    local s = self.db.settings
    if s.sound == "none" then return end
    if s.sound == "custom" and Text(s.soundPath) and s.soundPath ~= "" then
        PlaySoundFile(s.soundPath, "Master")
    elseif s.sound:sub(1,7) == "shared:" and LibStub then
        local media = LibStub("LibSharedMedia-3.0", true)
        local path = media and media:Fetch("sound", s.sound:sub(8), true)
        if Text(path) then PlaySoundFile(path, "Master") end
    elseif SOUNDKIT then
        local id = s.sound == "raid" and SOUNDKIT.RAID_WARNING or SOUNDKIT.TELL_MESSAGE
        if id then PlaySound(id, "Master") end
    end
end

function ns:Receive(kind, text, target, label, outgoing)
    -- Check secrecy before type checks, comparisons, formatting, or persistence.
    if self:Locked() or not Text(text) or not Public(target) or not Text(label) then return end
    local chat = self:GetChat(kind, target, label)
    if not chat then return end
    chat.messages[#chat.messages + 1] = { text=text, outgoing=outgoing == true, at=Now() }
    if #chat.messages > MAX_MESSAGES then table.remove(chat.messages, 1) end
    chat.updated = Now()
    local visible = self.frame and self.frame:IsShown() and self.selected == chat.key
    if not outgoing then
        chat.unread = visible and 0 or (chat.unread or 0) + 1
        if not visible then self:Notify() end
        -- Avoid popup/focus stealing during combat; capture public messages normally.
        if self.db.settings.openOnWhisper and not (InCombatLockdown and InCombatLockdown()) then
            if not self.frame or not self.frame:IsShown() then self:Open(chat.key) end
        end
    end
    if self.Refresh then self:Refresh(false, chat.key) end
    return chat
end

function ns:Send(chat, text)
    if not chat or not Text(text) or text:match("^%s*$") then return false, "Write a message first." end
    chat.draft = text
    if self:Locked() then return false, "Whispers are restricted here. Your draft is saved; use Blizzard chat." end
    if #text > 255 then return false, "Keep messages within 255 bytes." end
    if chat.kind == "bn" and not self.bnReady[chat.key] then return false, "Reconnect this Battle.net friend from Friends before sending." end
    if chat.kind == "bn" then
        local api=C_BattleNet and C_BattleNet.GetAccountInfoByID
        local ok,info
        if api then ok,info=pcall(api,self.bnReady[chat.key]) end
        if not ok or not info or not Text(info.battleTag) or "bn:"..info.battleTag:lower()~=chat.key then
            self.bnReady[chat.key]=nil
            return false,"Battle.net contact changed. Reconnect from Friends; your draft is saved."
        end
    end
    local send
    if chat.kind == "bn" then send = C_BattleNet and C_BattleNet.SendWhisper or BNSendWhisper
    else send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage end
    if not send then return false, "Whisper sending is unavailable." end
    local ok, result
    if chat.kind == "bn" then ok, result = pcall(send, self.bnReady[chat.key], text)
    else ok, result = pcall(send, text, "WHISPER", nil, chat.target) end
    if not ok or result == false then return false, "Could not send. Your draft is saved." end
    -- CHAT_MSG_*_INFORM records the actual outgoing echo; don't duplicate it here.
    chat.draft = ""
    return true
end

function ns:Delete(key)
    if self.store then self.store.chats[key] = nil end
    if self.selected == key then self.selected = nil end
    if self.Refresh then self:Refresh(true) end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        if not ns:Initialize() then return end
        for _, name in ipairs({"CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "ADDON_RESTRICTION_STATE_CHANGED"}) do events:RegisterEvent(name) end
        ns:Build()
    elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
        local kind, state = ...
        if Public(kind) and Public(state) then ns.restrictions[kind] = state end
        if ns.Refresh then ns:Refresh(false) end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then ns:Refresh(false)
    else
        local text, sender, _, _, _, _, _, _, _, _, _, _, accountID = ...
        local bn = event == "CHAT_MSG_BN_WHISPER" or event == "CHAT_MSG_BN_WHISPER_INFORM"
        ns:Receive(bn and "bn" or "wow", text, bn and accountID or sender, sender,
            event == "CHAT_MSG_WHISPER_INFORM" or event == "CHAT_MSG_BN_WHISPER_INFORM")
    end
end)
ns.events = events
