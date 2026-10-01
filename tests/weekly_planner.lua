-- Run from the repository root: lua5.1 tests/weekly_planner.lua
local now, region, resetAt = 1800000000, 3, 1800003600
local available, identity = true, "Alice"
local eventFrame, ticker
GetServerTime = function() return now end
GetCurrentRegion = function() return region end
GetRealmName = function() return "Test Realm" end
UnitFullName = function() return identity, "Test Realm" end
UnitGUID = function() return "Player-" .. identity end
UnitClass = function() return "Mage", "MAGE" end
IsLoggedIn = function() return false end
C_DateAndTime = { GetSecondsUntilWeeklyReset = function() if available then return resetAt - now end end }
C_Timer = { NewTicker = function(_, fn) ticker = fn end }
SlashCmdList = {}
CreateFrame = function()
    eventFrame = { RegisterEvent = function() end, SetScript = function(self, _, fn) self.handler = fn end }
    return eventFrame
end
local ns = {}
assert(loadfile("RevathsWeeklyPlanner/Core.lua"))("RevathsWeeklyPlanner", ns)
eventFrame.handler(nil, "ADDON_LOADED", "OtherAddon")
assert(ns.db == nil, "ignore unrelated addon load")
eventFrame.handler(nil, "ADDON_LOADED", "RevathsWeeklyPlanner")
eventFrame.handler(nil, "PLAYER_LOGIN")
local alice = ns.currentKey
assert(ns.db.characters[alice].resetAt == resetAt)
assert(ns:SaveGoal(alice, "  Finish my raid  "))
assert(not ns:SaveGoal(alice, "FINISH MY RAID"), "reject duplicate goals")
assert(not ns:SaveGoal(alice, " \t\n"), "reject blank goals")
assert(not ns:SaveGoal(alice, string.rep("x", 161)), "bound saved titles")
assert(ns:SaveGoal(alice, "Weekly dungeons"))
assert(ns:ToggleGoal(alice, 1))
local done, total = ns:GetProgress(ns.db.characters[alice])
assert(done == 1 and total == 2)
assert(ns:SaveGoal(alice, "Clear my chosen raid", 1))
assert(ns.db.characters[alice].goals[1].done, "editing preserves completion")
assert(not ns:SaveGoal(alice, "Weekly dungeons", 1))
ns.db.unfinishedOnly = true
assert(#ns:GetGoals(alice) == 1, "hide completed goals")
ns:ToggleGoal(alice, 2)
assert(#ns:GetCharacters() == 0, "hide characters with all goals complete")
identity = "Bob"; ns:TrackCurrentCharacter()
local bob = ns.currentKey
assert(#ns:GetCharacters() == 1, "characters without goals can still be configured")
assert(ns:SaveGoal(bob, "Profession weekly")); ns:ToggleGoal(bob, 1)
ns.db.characters.foreign = {name = "OtherRegion", region = 1, resetAt = now + 1,
    goals = {{id = 1, title = "Other region goal", done = true}}, nextID = 2}
local originalCount = #ns.db.characters[alice].goals
now = resetAt + 1; resetAt = resetAt + 604800
ticker()
assert(not ns.db.characters[alice].goals[1].done, "reset offline alt")
assert(not ns.db.characters[bob].goals[1].done, "reset current character")
assert(ns.db.characters.foreign.goals[1].done, "do not use EU timing for another region")
assert(#ns.db.characters[alice].goals == originalCount, "keep goals across resets")
ns:ToggleGoal(bob, 1); now = now + 60; ticker()
assert(ns.db.characters[bob].goals[1].done, "do not reset twice in the same week")
ns:RemoveGoal(bob, 1); now = now + 60; ticker(); ns:UndoRemove()
assert(ns.db.characters[bob].goals[1].done, "undo preserves completion during the same week")
ns:RemoveGoal(bob, 1); now = resetAt + 2; resetAt = resetAt + 604800; ns:UndoRemove()
assert(not ns.db.characters[bob].goals[1].done, "undo after reset clears old completion")
ns:ToggleGoal(bob, 1); available = false; now = resetAt + 1; ticker()
assert(ns.db.characters[bob].goals[1].done, "API unavailability must not erase progress")
available = true; resetAt = resetAt + 604800; ticker()
assert(not ns.db.characters[bob].goals[1].done, "catch up once timing returns")
ns:ToggleGoal(bob, 1); now = resetAt; ticker()
assert(ns.db.characters[bob].goals[1].done, "zero countdown waits for new authoritative timing")
resetAt = resetAt + 604800; ticker()
assert(not ns.db.characters[bob].goals[1].done)
ns:ToggleGoal(bob, 1); now = resetAt + 2 * 604800 + 10; resetAt = resetAt + 3 * 604800; ticker()
assert(not ns.db.characters[bob].goals[1].done, "catch up across multiple offline weeks")
ns:RemoveGoal(bob, 1); assert(ns:SaveGoal(bob, "New goal"))
assert(ns.db.characters[bob].goals[1].id == 2, "do not reuse removed IDs")
assert(not ns:SaveGoal(bob, "Edit deleted goal", 1))
local saved = ns.db
ns:InitializeDatabase(); assert(ns.db == saved and ns.db.characters[bob].nextID == 3, "reload keeps data")
assert(ns:SaveGoal(bob, "Another goal"))
assert(ns.db.characters[bob].goals[2].id == 3)

-- Mailbox roster and authoritative raid snapshots.
assert(loadfile("RevathsWeeklyPlanner/Characters.lua"))("RevathsWeeklyPlanner", ns)
local raidEvents = eventFrame
RevathsMailboxDB = { characters = {
    bob = {name = "Bob", realm = "TestRealm", classFile = "MAGE", lastSeen = now},
    alt = {name = "Cara", realm = "Test Realm", classFile = "PRIEST", lastSeen = now - 100},
    foreign = {name = "FarAway", realm = "Test Realm", region = 1},
} }
ns:ImportMailboxCharacters()
local importedKey, imported = ns:FindCharacter("Cara", "TestRealm", region)
assert(imported and imported.class == "PRIEST", "import mailbox roster")
assert(not ns:FindCharacter("FarAway", "Test Realm", region), "skip other region")
local rosterCount = 0
for _ in pairs(ns.db.characters) do rosterCount = rosterCount + 1 end
ns:ImportMailboxCharacters()
local newCount = 0
for _ in pairs(ns.db.characters) do newCount = newCount + 1 end
assert(newCount == rosterCount, "idempotent import and realm normalization")
assert(ns:SaveGoal(importedKey, "Imported alt goal"))
identity = "Cara"; ns:TrackCurrentCharacter()
assert(ns.db.characters[importedKey] == nil and ns.db.characters[ns.currentKey] == imported, "promote imported identity to GUID")
assert(imported.goals[1].title == "Imported alt goal", "promotion preserves goals")
identity = "Bob"; ns:TrackCurrentCharacter()
local requests, inCombat, unavailableRaid = 0, false, false
RequestRaidInfo = function() requests = requests + 1 end
InCombatLockdown = function() return inCombat end
GetNumSavedInstances = function() if unavailableRaid then error("API unavailable") end; return 2 end
GetSavedInstanceInfo = function(index)
    return index == 1 and "Test Raid" or "Dungeon", 123456, 3600, 15, true, true, 0, index == 1, 20, "Heroic", 2, 1
end
GetSavedInstanceEncounterInfo = function(_, index) return "Boss " .. index, 1, index == 1 end
ns:RequestRaidRefresh()
assert(requests == 1 and not ns.db.characters[bob].raids, "wait for UPDATE_INSTANCE_INFO")
raidEvents.handler(nil, "UPDATE_INSTANCE_INFO")
local snapshot = ns.db.characters[bob].raids
assert(#snapshot == 1 and snapshot[1].id == 123456 and snapshot[1].killed == 1, "capture raid IDs, exclude dungeons")
assert(snapshot[1].bosses[1].killed and not snapshot[1].bosses[2].killed, "capture boss kill details")
for _, goal in ipairs(ns.db.characters[bob].goals) do goal.done = true end
ns.db.unfinishedOnly = true
local foundPending = false
for _, entry in ipairs(ns:GetCharacters(true)) do if entry.key == bob then foundPending = true end end
assert(foundPending, "raid filter retains characters with unfinished bosses even when their goals are complete")
for _, goal in ipairs(ns.db.characters[bob].goals) do goal.done = false end
assert(ns.db.characters[bob].raidsUpdatedAt == now and #ns:GetRaidEntries(bob) == 2, "unfinished filter keeps pending bosses")
ns.db.unfinishedOnly = false
assert(#ns:GetRaidEntries(bob) == 3, "full view includes killed bosses")
ns:RequestRaidRefresh(); unavailableRaid = true; ns:CaptureRaidInfo()
assert(ns.db.characters[bob].raids == snapshot and ns.raidInfoUnavailable, "failed query preserves snapshot")
unavailableRaid = false; inCombat = true; ns:CaptureRaidInfo()
assert(ns.pendingRaidInfo, "defer reads in combat")
inCombat = false; raidEvents.handler(nil, "PLAYER_REGEN_ENABLED")
assert(not ns.pendingRaidInfo and not ns.raidInfoUnavailable)
local previousSecret = issecretvalue
issecretvalue = function(value) return value == 123456 end
snapshot = ns.db.characters[bob].raids
ns:RequestRaidRefresh(); ns:CaptureRaidInfo()
assert(ns.db.characters[bob].raids == snapshot, "restricted values preserve snapshot")
issecretvalue = previousSecret
local raidExpiry = snapshot[1].resetAt
now = raidExpiry + 1
assert(#ns:GetRaidEntries(bob) == 0, "expired snapshots disappear even when extension was enabled")
-- Extended lockouts use their own expiry, rather than the checklist weekly reset.
snapshot[1].resetAt = now + 604800
ns.db.characters[bob].resetAt = now - 1
ns:CheckWeeklyReset()
assert(#ns:GetRaidEntries(bob) == 3, "weekly checklist reset retains active extended raids")
ns:RequestRaidRefresh(); ns:CaptureRaidInfo()
GetNumSavedInstances = function() return 0 end
ns:RequestRaidRefresh(); ns:CaptureRaidInfo()
assert(#ns.db.characters[bob].raids == 0, "successful empty query clears previous lockouts")
GetNumSavedInstances = function() return 2 end
ns:RequestRaidRefresh(); ns:CaptureRaidInfo()
C_Timer.After = function(_, fn) fn() end
local previousRequests = requests
raidEvents.handler(nil, "ENCOUNTER_END", 1, "Boss", 15, 20, 0)
assert(requests == previousRequests, "failed encounter does not request a refresh")
raidEvents.handler(nil, "ENCOUNTER_END", 1, "Boss", 15, 20, 1)
assert(requests == previousRequests + 1, "successful encounter requests fresh raid data")
date = os.date

-- Frame mocks exercise the actual UI handlers, without pretending to be the live WoW client.
local objects, methods = {}, {}
local function object(kind, name, parent)
    local f = setmetatable({kind = kind, name = name, parent = parent, shown = true, scripts = {}, scale = 1}, {__index = methods})
    objects[#objects + 1] = f
    if name then _G[name] = f end
    return f
end
local function noop() end
for _, name in ipairs({"SetJustifyH", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor", "SetFrameStrata",
    "SetClampedToScreen", "EnableMouse", "SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
    "ClearAllPoints", "SetWordWrap", "RegisterForClicks", "EnableMouseWheel", "SetAutoFocus", "SetMaxBytes",
    "SetTextInsets", "SetJustifyV", "SetTexture", "SetColorTexture", "SetTexCoord", "SetVertexColor"}) do methods[name] = noop end
function methods:CreateTexture() return object("Texture", nil, self) end
for _, state in ipairs({"Normal", "Pushed", "Highlight"}) do
    methods["Set" .. state .. "Texture"] = function(self, path) self[state .. "Texture"] = path and self:CreateTexture() or nil end
    methods["Get" .. state .. "Texture"] = function(self) return self[state .. "Texture"] end
end
function methods:CreateFontString() return object("FontString", nil, self) end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text or "" end
function methods:SetPoint(...) self.point = {...} end
function methods:SetHeight(height) self.height = height end
function methods:SetWidth(width) self.width = width end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:SetScale(scale) self.scale = scale end
function methods:GetEffectiveScale() return self.scale end
function methods:GetCenter() return 360, 250 end
function methods:SetChecked(checked) self.checked = checked end
function methods:GetChecked() return self.checked end
function methods:SetFont(path, size) assert(type(path) == "string"); self.font, self.fontSize = path, size; return true end
function methods:SetTextColor(...) self.color = {...} end
function methods:SetFocus() self.focused = true end
function methods:ClearFocus() self.focused = false end
function methods:IsShown() return self.shown end
function methods:Hide() self:SetShown(false) end
function methods:Show() self:SetShown(true) end
function methods:SetShown(shown)
    local changed = self.shown ~= shown
    self.shown = shown
    local fn = self.scripts[shown and "OnShow" or "OnHide"]
    if changed and fn then fn(self) end
end
CreateFrame = object
UIParent = object("Frame"); STANDARD_TEXT_FONT = "font"
UISpecialFrames = {}; RAID_CLASS_COLORS = {MAGE = {r = .4, g = .8, b = 1}}
assert(loadfile("RevathsWeeklyPlanner/UI.lua"))("RevathsWeeklyPlanner", ns)
local function visible(f) return f.shown and (not f.parent or visible(f.parent)) end
local function click(text, button)
    for _, f in ipairs(objects) do
        if f.kind == "Button" and visible(f) and f.label and f.label.text == text and f.scripts.OnClick then
            f.scripts.OnClick(f, button or "LeftButton"); return f
        end
    end
    error("Button not found: " .. text)
end
ns.db.unfinishedOnly = false
SlashCmdList.REVATHSWEEKLYPLANNER()
assert(RevathsWeeklyPlannerFrame:IsShown() and RevathsWeeklyPlannerFrame.height == 500)
assert(UISpecialFrames[1] == "RevathsWeeklyPlannerFrame")
RevathsEnchantedWeeklyPlanner_Open(); assert(RevathsWeeklyPlannerFrame:IsShown(), "Open keeps an already visible planner open")
local input, filter
for _, f in ipairs(objects) do
    if f.kind == "EditBox" then input = f end
    if f.kind == "CheckButton" and f.parent == RevathsWeeklyPlannerFrame then filter = f end
end
input:SetText("UI-added goal"); input.scripts.OnEnterPressed()
local goalCount = #ns.db.characters[bob].goals
assert(ns.db.characters[bob].goals[goalCount].title == "UI-added goal")
click("UI-added goal")
assert(ns.db.characters[bob].goals[goalCount].done)
local editedRow = click("UI-added goal", "RightButton")
assert(input.focused)
input:SetText("Renamed from UI"); click("Save goal")
assert(ns.db.characters[bob].goals[goalCount].title == "Renamed from UI")
for _, f in ipairs(objects) do
    if f.parent == editedRow and f.label and f.label.text == "×" then f.scripts.OnClick(); break end
end
assert(#ns.db.characters[bob].goals == goalCount - 1, "remove a goal through UI")
click("Undo remove"); assert(#ns.db.characters[bob].goals == goalCount, "UI undo restores the goal")
click("Raid"); assert(ns.db.characters[bob].goals[goalCount + 1].title == "Finish my raid goal")
filter:SetChecked(true); filter.scripts.OnClick(filter)
assert(ns.db.unfinishedOnly)
assert(#ns:GetGoals(bob) == goalCount, "UI unfinished filter")
ns.db.skin = "classic"; ns.db.font = "arialOutline"; ns:ApplyAppearance()
assert(input.font == "Fonts\\ARIALN.TTF")
ns.db.unfinishedOnly = false
for i = 1, 12 do assert(ns:SaveGoal(bob, "Extra goal " .. i)) end
ns:Refresh()
local goalRow
for _, f in ipairs(objects) do
    if f.kind == "Button" and f.goalID and visible(f) then goalRow = f; break end
end
goalRow.scripts.OnMouseWheel(nil, -50)
local sawLast = false
for _, f in ipairs(objects) do
    if f.kind == "Button" and visible(f) and f.label and f.label.text == "Extra goal 12" then sawLast = true end
end
assert(sawLast, "long goal lists remain accessible by scrolling")
click("Raid lockouts")
assert(not input:IsShown(), "raid tab hides goal editor")
local sawKilled, sawAvailable, sawID = false, false, false
for _, f in ipairs(objects) do
    if visible(f) and f.text then
        sawKilled = sawKilled or f.text:find("%[Killed%]") ~= nil
        sawAvailable = sawAvailable or f.text:find("%[Available%]") ~= nil
        sawID = sawID or f.text:find("ID: 123456", 1, true) ~= nil
    end
end
assert(sawKilled and sawAvailable and sawID, "raid UI displays killed bosses, available bosses and raid ID")
click("Cara")
local sawOfflineExplanation = false
for _, f in ipairs(objects) do
    if visible(f) and f.text and f.text:find("Log into this character", 1, true) then sawOfflineExplanation = true end
end
assert(sawOfflineExplanation, "offline mailbox alt explains missing raid data")
click("Me")
click("Refresh raid data"); assert(ns.awaitingRaidInfo)
click("Weekly goals"); assert(input:IsShown(), "return to checklist")
ns.db.skin = "modern"; ns:ApplyAppearance()
ns:Toggle(); assert(not RevathsWeeklyPlannerFrame:IsShown())
print("Weekly Planner tests passed: persistence, per-alt goals, editing, filters, regional resets, offline catch-up, unavailable timing, undo, mailbox imports, raid snapshots, combat deferral, restricted data, expiration, and UI interactions.")
