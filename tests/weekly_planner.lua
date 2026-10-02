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
    "SetTextInsets", "SetJustifyV", "RegisterEvent", "SetResizable", "SetResizeBounds", "StartSizing", "SetOrientation", "SetThumbTexture", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetTexture", "SetColorTexture", "SetTexCoord", "SetVertexColor"}) do methods[name] = noop end
function methods:CreateTexture() return object("Texture", nil, self) end
for _, state in ipairs({"Normal", "Pushed", "Highlight"}) do
    methods["Set" .. state .. "Texture"] = function(self, path)
        assert(type(path) == "string" and path ~= "", "Button texture setters require an asset")
        self[state .. "Texture"] = self[state .. "Texture"] or self:CreateTexture()
    end
    methods["Get" .. state .. "Texture"] = function(self) return self[state .. "Texture"] end
end
function methods:CreateFontString() return object("FontString", nil, self) end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:SetAlpha(alpha) self.alpha = alpha end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text or "" end
function methods:SetPoint(...) self.point = {...} end
function methods:SetHeight(height) self.height = height end
function methods:SetWidth(width) self.width = width end
function methods:SetSize(width, height)
    self.width, self.height = width, height
    if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,width,height) end
end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetValue(value)
    local changed = self.value ~= value
    self.value = value
    if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
end
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
for _, f in ipairs(objects) do
    if f.kindButton then
        for _, state in ipairs({"Normal", "Pushed", "Highlight"}) do
            assert(f[state .. "Texture"].alpha == 0, "Modern skin hides Classic button textures")
        end
    end
end
ns.db.skin = "classic"; ns:ApplyAppearance()
for _, f in ipairs(objects) do
    if f.kindButton then
        for _, state in ipairs({"Normal", "Pushed", "Highlight"}) do
            assert(f[state .. "Texture"].alpha == 1, "Classic textures return after switching skins")
        end
    end
end
ns.db.skin = "modern"; ns:ApplyAppearance()
local originalFontSize = input.fontSize
RevathsWeeklyPlannerFrame:SetSize(960,700)
assert(ns.db.window.width == 960 and ns.db.window.height == 700, "save dimensions")
assert(input.width == 608 and input.fontSize == originalFontSize, "resize layout without scaling text")
local visibleGoals = 0
for _,f in ipairs(objects) do if f.goalID and visible(f) then visibleGoals = visibleGoals+1 end end
assert(visibleGoals > 6, "taller window exposes more goal rows")
click("Settings"); assert(not input:IsShown(), "in-window Appearance hides checklist editor")
click("Classic"); assert(ns.db.skin == "classic")
click("Modern"); assert(ns.db.skin == "modern")
local opacitySlider
for _,f in ipairs(objects) do
    if f.kind == "Slider" and f.value == ns.db.opacity then opacitySlider=f; break end
end
assert(opacitySlider, "mailbox-style opacity slider exists")
opacitySlider:SetValue(.55); assert(ns.db.opacity == .55, "opacity range matches mailbox")
click("Weekly goals"); assert(input:IsShown())
RevathsWeeklyPlannerFrame:SetSize(720,500)
assert(input.width == 368 and ns.db.window.width == 720, "restore default dimensions")
ns:Toggle(); assert(not RevathsWeeklyPlannerFrame:IsShown())
print("Weekly Planner tests passed: persistence, per-alt goals, editing, filters, regional resets, offline catch-up, unavailable timing, undo, mailbox imports, raid snapshots, combat deferral, restricted data, expiration, and UI interactions.")

-- Exercise the automatic rows through the real UI handlers too.
assert(loadfile("RevathsWeeklyPlanner/Progress.lua"))("RevathsWeeklyPlanner",ns)
RevathsEnchantedWeeklyPlanner_Open(); click("Me")
local automaticTitle = ns:GetGoals(bob)[1].title
local automaticRow = click(automaticTitle,"RightButton")
assert(type(automaticRow.goalID)=="string" and automaticRow.check.enabled==true)
assert(not automaticRow.remove:IsShown() and not input.focused, "default titles cannot be edited or removed")
automaticRow.scripts.OnClick(automaticRow,"LeftButton")
assert(ns:GetGoals(bob)[1].done and automaticRow.check.checked, "click default goal row to complete")
automaticRow.check.scripts.OnClick()
assert(not ns:GetGoals(bob)[1].done, "click default checkbox to reopen")
print("Automatic goal UI controls passed.")

assert(loadfile("RevathsWeeklyPlanner/Details.lua"))("RevathsWeeklyPlanner",ns)
local shiftDown = false
IsShiftKeyDown = function() return shiftDown end
shiftDown=true; automaticRow.scripts.OnClick(automaticRow,"LeftButton")
assert(not ns:GetGoals(bob)[1].manualCompletion, "Shift-click restores automatic completion")
shiftDown=false
GameTooltip = {
    SetOwner = function(self, owner) self.owner=owner end,
    ClearLines = function(self) self.lines={} end,
    AddLine = function(self, text) self.lines[#self.lines+1]=text end,
    Show = function(self) self.shown=true end,
    Hide = function(self) self.shown=false end,
}
local bosses = {}
for index=1,25 do bosses[index]={name="Hover boss "..index,raidName="Hover raid",killed=index==1} end
ns.db.characters[bob].weekly={raid={killed=1,total=25,bosses=bosses,capturedAt=GetServerTime()}}
ns:Refresh()
automaticRow.scripts.OnEnter(automaticRow)
assert(GameTooltip.shown and #GameTooltip.lines==14, "long hover details show a bounded page and scroll hint")
local firstPage=table.concat(GameTooltip.lines,"\n")
assert(firstPage:find("[Killed] Hover boss 1",1,true))
shiftDown=true; automaticRow.scripts.OnMouseWheel(automaticRow,-2)
assert(GameTooltip.shown and table.concat(GameTooltip.lines,"\n")~=firstPage, "Shift-wheel pages details without moving goals")
automaticRow.scripts.OnLeave(automaticRow); assert(not GameTooltip.shown)
automaticRow.scripts.OnEnter(automaticRow); click("Raid lockouts")
assert(not GameTooltip.shown, "switching tabs hides goal details")
click("Weekly goals"); automaticRow.scripts.OnEnter(automaticRow)
ns:Toggle(); assert(not GameTooltip.shown, "closing planner hides goal details")
print("Weekly hover details passed: saved data, bounded pages, Shift-scroll and tooltip cleanup.")

shiftDown=false
RevathsEnchantedWeeklyPlanner_Open(); click("Me"); click("Choose goals")
assert(not input:IsShown(), "visibility choices hide goal editor")
local chosenRow
for _,f in ipairs(objects) do if f.goalID=="auto:raid" and visible(f) then chosenRow=f; break end end
assert(chosenRow and chosenRow.check.checked, "visibility checkboxes show enabled goals regardless of completion")
chosenRow.scripts.OnClick(chosenRow,"LeftButton")
assert(ns.db.characters[bob].hiddenGoals["auto:raid"] and not chosenRow.check.checked)
click("Weekly goals")
for _,goal in ipairs(ns:GetGoals(bob)) do assert(goal.id~="auto:raid", "hidden goal disappears from checklist") end
click("Choose goals"); chosenRow.check.scripts.OnClick()
assert(not ns.db.characters[bob].hiddenGoals["auto:raid"] and chosenRow.check.checked, "restore hidden default through its checkbox")
click("Weekly goals")
print("Goal visibility UI passed: configure, hide and restore per-character goals.")

-- Crest balances are informational and switch with the selected offline alt.
assert(loadfile("RevathsWeeklyPlanner/Catalog.lua"))("RevathsWeeklyPlanner",ns)
assert(loadfile("RevathsWeeklyPlanner/Activities.lua"))("RevathsWeeklyPlanner",ns)
ns.db.characters[bob].resources={}
for id=3442,3446 do ns.db.characters[bob].resources[id]={name="Test crest "..id,quantity=id-3440,capturedAt=now} end
imported.resources={[3445]={name="Alt Hero crest",quantity=77,capturedAt=now}}
click("Me")
local crestRow
for _,f in ipairs(objects) do if f.entry and f.entry.name=="Test crest 3445" and visible(f) then crestRow=f end end
assert(crestRow and not crestRow.check, "crest panel has information rows without completion controls")
crestRow.scripts.OnEnter(crestRow)
assert(table.concat(GameTooltip.lines,"\n"):find("5 available (saved)",1,true), "crest hover shows saved amounts and update details")
crestRow.scripts.OnLeave(crestRow)
local visibleGoals=0
for _,f in ipairs(objects) do
    if f.goalID and visible(f) then
        assert(f.goalID~="auto:crests", "crests never appear in goal rows")
        visibleGoals=visibleGoals+1
    end
end
assert(visibleGoals*36+6<=RevathsWeeklyPlannerFrame.contentPanel.height, "minimum-size goal rows fit above the crest panel")
click("Cara")
for _,f in ipairs(objects) do if f.entry and f.entry.name=="Alt Hero crest" then crestRow=f end end
assert(crestRow.entry and crestRow.entry.quantity==77 and visible(crestRow), "selecting an offline alt refreshes its own crest panel")
click("Settings")
assert(not visible(crestRow), "appearance view hides crest information")
click("Weekly goals")
RevathsWeeklyPlannerFrame:SetSize(1200,900)
assert(visible(crestRow) and RevathsWeeklyPlannerFrame.contentPanel.height>500, "resizing retains room for goals and crest information")
print("Crest info UI passed: per-alt selection, saved balance details, separate noninteractive rows, tab visibility and resize layout.")
