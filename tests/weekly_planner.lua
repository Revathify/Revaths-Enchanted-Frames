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
    "SetTextInsets", "SetJustifyV"}) do methods[name] = noop end
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
ns:Toggle(); assert(not RevathsWeeklyPlannerFrame:IsShown())
print("Weekly Planner tests passed: persistence, per-alt goals, editing, filters, regional resets, offline catch-up, unavailable timing, undo, and UI interactions.")
