local _, ns = ...

local frame, characterTitle, progressText, resetText, statusText, input, addButton, filter, undoButton
local characterRows, goalRows, labels, surfaces = {}, {}, {}, {}
local selectedKey, editID, characterOffset, goalOffset = nil, nil, 0, 0
local accents = {
    midnight = { .20, .78, .82 }, arcane = { .66, .40, .94 }, emerald = { .18, .78, .53 },
    crimson = { .91, .28, .34 }, royal = { .25, .57, .96 }, graphite = { .62, .65, .70 },
}
local fonts = { friz = STANDARD_TEXT_FONT, arial = "Fonts\\ARIALN.TTF", morpheus = "Fonts\\MORPHEUS.TTF", skurri = "Fonts\\SKURRI.TTF" }

local function SafeText(text) return (text or ""):gsub("|", "||") end

local function Label(parent, size, muted)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label.size, label.muted = size, muted
    label:SetJustifyH("LEFT")
    labels[#labels + 1] = label
    return label
end

local function Surface(surface)
    surfaces[#surfaces + 1] = surface
    return surface
end

local function Style(surface)
    local classic = ns.db.skin == "classic"
    local accent = classic and { .96, .72, .20 } or (accents[ns.db.palette] or accents.midnight)
    surface:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = classic and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Buttons\\WHITE8X8",
        edgeSize = classic and 16 or 1, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    surface:SetBackdropColor(classic and .06 or .035, classic and .045 or .045, classic and .025 or .065, ns.db.opacity)
    surface:SetBackdropBorderColor(accent[1] * .5, accent[2] * .5, accent[3] * .5, 1)
end

local function Button(parent, text, width, height, callback)
    local button = Surface(CreateFrame("Button", nil, parent, "BackdropTemplate"))
    button:SetSize(width, height)
    button.label = Label(button, 12)
    button.label:SetPoint("CENTER"); button.label:SetText(text)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(.6, .85, .9, 1) end)
    button:SetScript("OnLeave", Style)
    return button
end

local function Status(text) if statusText then statusText:SetText(text or "") end end

local function CancelEdit()
    editID = nil
    input:SetText(""); input:ClearFocus(); addButton.label:SetText("Add goal")
end

local function SaveGoal()
    local ok, message = ns:SaveGoal(selectedKey, input:GetText(), editID)
    if not ok then Status(message); return end
    local editing = editID ~= nil
    CancelEdit(); goalOffset = 0; ns:Refresh()
    Status(editing and "Goal updated." or "Weekly goal added. Check it off when you finish it.")
end

local function ResetCountdown()
    if not ns.nextReset then return "Weekly reset time unavailable" end
    local seconds = math.max(0, ns.nextReset - GetServerTime())
    local days, hours = math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600)
    if days > 0 then return string.format("Resets in %dd %dh", days, hours) end
    return string.format("Resets in %dh %dm", hours, math.floor(seconds % 3600 / 60))
end

function ns:ApplyAppearance()
    if not frame or not self.db then return end
    frame:SetScale(self.db.scale)
    for _, surface in ipairs(surfaces) do Style(surface) end
    local key = self.db.font
    local outline = key:find("Outline") and "OUTLINE" or ""
    local path = fonts[key:gsub("Outline", "")] or STANDARD_TEXT_FONT
    if key:sub(1, 7) == "shared:" and LibStub then
        local media = LibStub("LibSharedMedia-3.0", true)
        path = media and media:Fetch("font", key:sub(8), true) or path
    end
    for _, label in ipairs(labels) do
        local ok, loaded = pcall(label.SetFont, label, path, label.size, outline)
        if not ok or loaded == false then label:SetFont(STANDARD_TEXT_FONT, label.size, "") end
        label:SetTextColor(label.muted and .65 or .95, label.muted and .73 or .96, label.muted and .80 or .98)
    end
    local ok, loaded = pcall(input.SetFont, input, path, 13, outline)
    if not ok or loaded == false then input:SetFont(STANDARD_TEXT_FONT, 13, "") end
    self:Refresh()
end

function ns:Refresh()
    if not frame or not frame:IsShown() or not self.db then return end
    local characters = self:GetCharacters()
    if not selectedKey or not self.db.characters[selectedKey] then selectedKey = self.currentKey end
    local visibleSelection = false
    for _, entry in ipairs(characters) do if entry.key == selectedKey then visibleSelection = true end end
    if not visibleSelection and characters[1] then
        selectedKey = characters[1].key; goalOffset = 0; CancelEdit()
    end
    characterOffset = math.max(0, math.min(characterOffset, #characters - #characterRows))
    for index, row in ipairs(characterRows) do
        local entry = characters[characterOffset + index]
        row.key = entry and entry.key
        row:SetShown(entry ~= nil)
        if entry then
            local character = entry.character
            row.label:SetText((entry.key == selectedKey and "› " or "") .. SafeText(character.name))
            local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[character.class]
            row.label:SetTextColor(color and color.r or .95, color and color.g or .96, color and color.b or .98)
            row.meta:SetText(entry.total == 0 and "No goals yet" or string.format("%d / %d complete", entry.done, entry.total))
            row.realm:SetText(SafeText(character.realm))
        end
    end
    local character = self.db.characters[selectedKey]
    characterTitle:SetText(character and SafeText(character.name .. " — " .. character.realm) or "Your weekly goals")
    local done, total = 0, 0
    if character then done, total = self:GetProgress(character) end
    progressText:SetText(string.format("%d / %d complete · Click to check off; right-click to edit", done, total))
    resetText:SetText(ResetCountdown())
    filter:SetChecked(self.db.unfinishedOnly)
    undoButton:SetShown(self.removedGoal ~= nil)
    local goals = self:GetGoals(selectedKey)
    goalOffset = math.max(0, math.min(goalOffset, #goals - #goalRows))
    for index, row in ipairs(goalRows) do
        local goal = goals[goalOffset + index]
        row.goalID = goal and goal.id
        row:SetShown(goal ~= nil)
        if goal then
            row.check:SetChecked(goal.done == true)
            row.label:SetText(SafeText(goal.title))
            row.label:SetTextColor(goal.done and .45 or .95, goal.done and .78 or .96, goal.done and .60 or .98)
        end
    end
    frame.empty:SetShown(#goals == 0)
    frame.empty:SetText(total == 0 and "What would you like to finish this week?\nAdd a goal below, or choose a starter goal."
        or "All goals complete for this character.\nTurn off Unfinished only to see or change them.")
end

local function Build()
    if frame then return end
    frame = Surface(CreateFrame("Frame", "RevathsWeeklyPlannerFrame", UIParent, "BackdropTemplate"))
    frame:SetSize(720, 500); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
    frame:EnableMouse(true); frame:SetMovable(true)
    local position = ns.db.window
    frame:SetPoint("CENTER", UIParent, "CENTER", tonumber(position.x) or 0, tonumber(position.y) or 0)
    local drag = CreateFrame("Frame", nil, frame)
    drag:SetPoint("TOPLEFT", 5, -5); drag:SetPoint("TOPRIGHT", -195, -5); drag:SetHeight(38)
    drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() frame:StartMoving() end)
    drag:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local x, y = frame:GetCenter()
        local scale = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
        local parentX, parentY = UIParent:GetCenter()
        ns.db.window = { x = x - parentX * scale, y = y - parentY * scale }
        frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", ns.db.window.x, ns.db.window.y)
    end)
    local title = Label(frame, 18); title:SetPoint("TOPLEFT", 18, -18); title:SetText("ENCHANTED WEEKLY PLANNER")
    local close = Button(frame, "×", 28, 28, function() frame:Hide() end); close:SetPoint("TOPRIGHT", -12, -12)
    local settings = Button(frame, "Settings", 78, 28, function()
        if SlashCmdList.REVATHSENCHANTEDFRAMES then SlashCmdList.REVATHSENCHANTEDFRAMES() end
    end); settings:SetPoint("RIGHT", close, "LEFT", -6, 0)
    filter = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    filter:SetPoint("TOPLEFT", 12, -52); filter:SetSize(26, 26)
    filter:SetScript("OnClick", function(self)
        ns.db.unfinishedOnly = self:GetChecked() == true
        characterOffset, goalOffset = 0, 0; CancelEdit(); ns:Refresh()
    end)
    local filterLabel = Label(frame, 12); filterLabel:SetPoint("LEFT", filter, "RIGHT", 4, 0); filterLabel:SetText("Unfinished only")
    resetText = Label(frame, 12, true); resetText:SetPoint("TOPRIGHT", -18, -61)
    local rosterTitle = Label(frame, 13); rosterTitle:SetPoint("TOPLEFT", 18, -99); rosterTitle:SetText("CHARACTERS")
    local mine = Button(frame, "Me", 36, 24, function()
        selectedKey = ns.currentKey; goalOffset = 0; CancelEdit()
        -- Explicitly selecting a finished character makes its goals visible.
        ns.db.unfinishedOnly = false; ns:Refresh()
    end); mine:SetPoint("TOPLEFT", 175, -92)
    characterTitle = Label(frame, 15); characterTitle:SetPoint("TOPLEFT", 232, -96); characterTitle:SetWidth(470)
    progressText = Label(frame, 10, true); progressText:SetPoint("TOPLEFT", 232, -121); progressText:SetWidth(470)
    for index = 1, 7 do
        local row = Button(frame, "", 194, 36, function(self)
            selectedKey = self.key; goalOffset = 0; CancelEdit(); ns:Refresh()
        end)
        row:SetPoint("TOPLEFT", 18, -134 - (index - 1) * 38)
        row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", 7, -5); row.label:SetWidth(116)
        row.label:SetWordWrap(false)
        row.meta = Label(row, 9, true); row.meta:SetPoint("TOPRIGHT", -6, -6); row.meta:SetWidth(69); row.meta:SetJustifyH("RIGHT")
        row.realm = Label(row, 9, true); row.realm:SetPoint("BOTTOMLEFT", 7, 4); row.realm:SetWidth(180)
        row.realm:SetWordWrap(false)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta)
            characterOffset = math.max(0, characterOffset - delta); ns:Refresh()
        end)
        characterRows[index] = row
    end
    for index = 1, 7 do
        local row = Button(frame, "", 470, 32, function(self, mouseButton)
            if mouseButton == "RightButton" then
                for _, goal in ipairs(ns:GetGoals(selectedKey)) do
                    if goal.id == self.goalID then
                        editID = goal.id; input:SetText(goal.title); input:SetFocus(); addButton.label:SetText("Save goal")
                        Status("Edit the goal below. Press Escape to cancel."); break
                    end
                end
            else ns:ToggleGoal(selectedKey, self.goalID); ns:Refresh() end
        end)
        row:SetPoint("TOPLEFT", 232, -148 - (index - 1) * 36)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.check:SetSize(26, 26); row.check:SetPoint("LEFT", 3, 0)
        row.check:SetScript("OnClick", function() ns:ToggleGoal(selectedKey, row.goalID); ns:Refresh() end)
        row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 35, 0); row.label:SetWidth(395); row.label:SetWordWrap(false)
        local remove = Button(row, "×", 24, 24, function()
            ns:RemoveGoal(selectedKey, row.goalID)
            if editID == row.goalID then CancelEdit() end
            ns:Refresh(); Status("Goal removed. Use Undo remove to restore it.")
        end); remove:SetPoint("RIGHT", -3, 0)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(_, delta) goalOffset = math.max(0, goalOffset - delta); ns:Refresh() end)
        goalRows[index] = row
    end
    frame.empty = Label(frame, 13, true); frame.empty:SetPoint("TOPLEFT", 245, -190); frame.empty:SetWidth(430)
    local starters = { {"Raid", "Finish my raid goal"}, {"Dungeons", "Finish my weekly dungeon goal"}, {"Professions", "Finish my profession weeklies"} }
    for index, starter in ipairs(starters) do
        local button = Button(frame, starter[1], 108, 26, function()
            local ok, message = ns:SaveGoal(selectedKey, starter[2])
            ns:Refresh(); Status(ok and "Starter goal added. Right-click it to make it your own." or message)
        end); button:SetPoint("TOPLEFT", 232 + (index - 1) * 113, -404)
    end
    undoButton = Button(frame, "Undo remove", 126, 26, function()
        local ok = ns:UndoRemove(); ns:Refresh(); Status(ok and "Goal restored." or "A goal with that name already exists.")
    end); undoButton:SetPoint("TOPRIGHT", -18, -404)
    input = Surface(CreateFrame("EditBox", nil, frame, "BackdropTemplate"))
    input:SetSize(368, 28); input:SetPoint("TOPLEFT", 232, -438); input:SetAutoFocus(false)
    input:SetMaxBytes(160); input:SetTextInsets(8, 8, 4, 4); input:SetTextColor(1, 1, 1)
    input:SetScript("OnEnterPressed", SaveGoal)
    input:SetScript("OnEscapePressed", function() CancelEdit(); Status("Editing cancelled.") end)
    addButton = Button(frame, "Add goal", 96, 28, SaveGoal); addButton:SetPoint("LEFT", input, "RIGHT", 6, 0)
    local tip = Label(frame, 10, true); tip:SetPoint("TOPLEFT", 18, -412); tip:SetWidth(192)
    tip:SetText("Log into alts to add them.\nScroll either list for more.")
    local manual = Label(frame, 10, true); manual:SetPoint("TOPLEFT", 18, -450); manual:SetWidth(192)
    manual:SetText("Personal checklist\nMark activities complete yourself.")
    statusText = Label(frame, 11, true); statusText:SetPoint("BOTTOMLEFT", 232, 12); statusText:SetWidth(470); statusText:SetWordWrap(false)
    statusText:SetText("Type a weekly goal above and press Enter.")
    frame:SetScript("OnHide", CancelEdit)
    frame:SetScript("OnShow", function() ns:CheckWeeklyReset(); ns:Refresh() end)
    UISpecialFrames[#UISpecialFrames + 1] = "RevathsWeeklyPlannerFrame"
    frame:Hide(); ns:ApplyAppearance()
end

function ns:Show()
    if not self.db or not self.currentKey then return end
    Build(); frame:Show()
end

function ns:Toggle()
    if frame and frame:IsShown() then frame:Hide() else self:Show() end
end

function RevathsEnchantedWeeklyPlanner_Open() ns:Show() end

function RevathsEnchantedWeeklyPlanner_ApplySettings()
    if ns.db then ns:ApplyAppearance() end
end
