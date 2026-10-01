local _, ns = ...

local frame, characterTitle, progressText, resetText, statusText, input, addButton, filter, undoButton
local characterRows, goalRows, labels, surfaces = {}, {}, {}, {}
local selectedKey, editID, characterOffset, goalOffset = nil, nil, 0, 0
local view, raidOffset = "goals", 0
local raidRows, goalControls = {}, {}
local characterCapacity, goalCapacity = 7, 6
local appearancePanel, modernButton, classicButton, opacitySlider, scaleSlider, opacityValue, scaleValue
local refreshingAppearance = false
local raidStatus, refreshRaids, headerGlow, headerLine, titlePlate, goalsTab, raidsTab
local palettes = {
    midnight = { bg={.035,.047,.071}, panel={.065,.082,.115}, button={.09,.11,.15}, input={.025,.034,.052}, border={.18,.23,.31} },
    arcane = { bg={.050,.035,.080}, panel={.085,.060,.125}, button={.105,.070,.155}, input={.035,.025,.060}, border={.30,.22,.42} },
    emerald = { bg={.025,.060,.050}, panel={.045,.095,.075}, button={.052,.115,.090}, input={.018,.046,.038}, border={.16,.34,.27} },
    crimson = { bg={.070,.030,.035}, panel={.115,.048,.055}, button={.135,.052,.058}, input={.052,.022,.026}, border={.38,.18,.20} },
    royal = { bg={.025,.040,.080}, panel={.042,.070,.125}, button={.052,.082,.145}, input={.018,.032,.062}, border={.16,.28,.46} },
    graphite = { bg={.050,.052,.058}, panel={.080,.083,.092}, button={.105,.109,.120}, input={.035,.037,.043}, border={.28,.29,.32} },
}

local accents = {
    midnight = { .18, .72, .78 }, arcane = { .66, .40, .94 }, emerald = { .18, .78, .53 },
    crimson = { .91, .28, .34 }, royal = { .25, .57, .96 }, graphite = { .62, .65, .70 },
}
local function Accent()
    return ns.db.skin == "classic" and { .96,.72,.20 } or (accents[ns.db.palette] or accents.midnight)
end

local fonts = { friz = STANDARD_TEXT_FONT, arial = "Fonts\\ARIALN.TTF", morpheus = "Fonts\\MORPHEUS.TTF", skurri = "Fonts\\SKURRI.TTF" }

local function SafeText(text) return (text or ""):gsub("|", "||") end

local hoveredGoal, detailOffset = nil, 0
local function HideGoalDetails()
    if hoveredGoal and GameTooltip then GameTooltip:Hide() end
    hoveredGoal, detailOffset = nil, 0
end
local function ShowGoalDetails(row)
    if not GameTooltip or not ns.GetGoalDetails then return end
    if not row:IsShown() or view ~= "goals" then HideGoalDetails(); return end
    local title, lines = ns:GetGoalDetails(selectedKey, row.goalID)
    if not title then HideGoalDetails(); return end
    if hoveredGoal ~= row then detailOffset = 0 end
    hoveredGoal = row
    local pageSize = 12
    detailOffset = math.max(0, math.min(detailOffset, math.max(0, #lines - pageSize)))
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(SafeText(title), 1, .82, .3, true)
    for index = detailOffset + 1, math.min(#lines, detailOffset + pageSize) do
        GameTooltip:AddLine(SafeText(lines[index]), .9, .93, .96, true)
    end
    if #lines > pageSize then GameTooltip:AddLine("Hold Shift and scroll for more details", .55, .7, .8, true) end
    GameTooltip:Show()
end

local function Label(parent, size, muted)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label.size, label.muted = size, muted
    label:SetJustifyH("LEFT")
    labels[#labels + 1] = label
    return label
end

local function Surface(surface, role)
    surface.role = role or "button"
    surfaces[#surfaces + 1] = surface
    return surface
end

local function Style(surface)
    local classic = ns.db.skin == "classic"
    local palette = palettes[ns.db.palette] or palettes.midnight
    local bg = classic and (surface.role == "bg" and {.030,.024,.014} or {.040,.030,.016}) or palette[surface.role]
    local border = classic and {.58,.48,.30} or palette.border
    surface:SetBackdrop({ bgFile = classic and "Interface\\DialogFrame\\UI-DialogBox-Background" or "Interface\\Buttons\\WHITE8X8",
        edgeFile = classic and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = classic and (surface.role == "bg" and 32 or 22) or (surface.role == "bg" and 16 or 12),
        insets = { left = classic and 7 or 3, right = classic and 7 or 3, top = classic and 7 or 3, bottom = classic and 7 or 3 } })
    local opacity = ns.db.opacity + (surface.role == "panel" and .02 or (surface.role == "bg" and 0 or .04))
    surface:SetBackdropColor(bg[1], bg[2], bg[3], classic and 1 or math.min(1, opacity))
    surface:SetBackdropBorderColor(border[1], border[2], border[3], 1)
    if surface.kindButton then
        if classic then
            surface:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
            surface:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
            surface:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
            surface:GetNormalTexture():SetAlpha(1)
            surface:GetPushedTexture():SetAlpha(1)
            surface:GetHighlightTexture():SetAlpha(1)
            surface:GetNormalTexture():SetTexCoord(0, .625, 0, .6875)
            surface:GetPushedTexture():SetTexCoord(0, .625, 0, .6875)
            surface:GetHighlightTexture():SetTexCoord(0, .625, 0, .6875)
            surface:GetNormalTexture():SetVertexColor(.78,.20,.08)
            surface:GetPushedTexture():SetVertexColor(.58,.09,.035)
            surface:GetHighlightTexture():SetVertexColor(1,.72,.18,.55)
            surface:SetBackdropColor(0,0,0,0); surface:SetBackdropBorderColor(0,0,0,0)
        else
            -- Button asset setters reject nil; hide existing Classic textures instead.
            for _, state in ipairs({ "Normal", "Pushed", "Highlight" }) do
                local texture = surface["Get" .. state .. "Texture"](surface)
                if texture then texture:SetAlpha(0) end
            end
        end
    end
end

local function Button(parent, text, width, height, callback)
    local button = Surface(CreateFrame("Button", nil, parent, "BackdropTemplate"))
    button.kindButton = true
    button:SetSize(width, height)
    button.label = Label(button, 12)
    button.label:SetPoint("CENTER"); button.label:SetText(text)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self) local c = Accent(); self:SetBackdropBorderColor(c[1], c[2], c[3], 1) end)
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
    local c = Accent()
    headerGlow:SetColorTexture(c[1], c[2], c[3], .12)
    headerLine:SetColorTexture(c[1], c[2], c[3], .45)
    titlePlate:SetShown(self.db.skin == "classic")
    local border = self.db.skin == "classic" and {.58,.48,.30} or (palettes[self.db.palette] or palettes.midnight).border
    for _, slider in ipairs({opacitySlider,scaleSlider}) do
        slider.track:SetColorTexture(border[1],border[2],border[3],.8)
    end
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
        local color = self.db.skin == "classic" and (label.muted and {.76,.64,.43} or {1,.92,.72})
            or (label.muted and {.56,.62,.70} or {.90,.93,.96})
        label:SetTextColor(color[1], color[2], color[3])
    end
    local ok, loaded = pcall(input.SetFont, input, path, 13, outline)
    if not ok or loaded == false then input:SetFont(STANDARD_TEXT_FONT, 13, "") end
    self:Refresh()
end

function ns:Refresh()
    if not frame or not frame:IsShown() or not self.db then return end
    local characters = self:GetCharacters(view == "raids")
    if not selectedKey or not self.db.characters[selectedKey] then selectedKey = self.currentKey end
    local visibleSelection = false
    for _, entry in ipairs(characters) do if entry.key == selectedKey then visibleSelection = true end end
    if not visibleSelection and characters[1] then
        selectedKey = characters[1].key; goalOffset = 0; CancelEdit()
    end
    characterOffset = math.max(0, math.min(characterOffset, #characters - characterCapacity))
    for index, row in ipairs(characterRows) do
        local entry = characters[characterOffset + index]
        row.key = entry and entry.key
        row:SetShown(entry ~= nil and index <= characterCapacity)
        if entry then
            local character = entry.character
            row.label:SetText((entry.key == selectedKey and "› " or "") .. SafeText(character.name))
            local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[character.class]
            row.label:SetTextColor(color and color.r or .95, color and color.g or .96, color and color.b or .98)
            if view == "raids" then
                local killed, bosses = 0, 0
                for _, raid in ipairs(character.raids or {}) do
                    if raid.resetAt > GetServerTime() then killed = killed + raid.killed; bosses = bosses + #raid.bosses end
                end
                row.meta:SetText(character.raidsUpdatedAt and string.format("%d / %d bosses", killed, bosses) or "Not scanned")
            else
                row.meta:SetText(entry.total == 0 and "No goals yet" or string.format("%d / %d complete", entry.done, entry.total))
            end
            row.realm:SetText(SafeText(character.realm))
        end
    end
    local character = self.db.characters[selectedKey]
    characterTitle:SetText(character and SafeText(character.name .. " — " .. character.realm) or "Your weekly goals")
    local done, total = 0, 0
    if character then done, total = self:GetProgress(character) end
    progressText:SetText(string.format("%d / %d complete · Default goals update automatically; right-click personal goals to edit", done, total))
    resetText:SetText(ResetCountdown())
    local accent = Accent()
    goalsTab.label:SetTextColor(view == "goals" and accent[1] or .56, view == "goals" and accent[2] or .62, view == "goals" and accent[3] or .70)
    raidsTab.label:SetTextColor(view == "raids" and accent[1] or .56, view == "raids" and accent[2] or .62, view == "raids" and accent[3] or .70)
    filter:SetChecked(self.db.unfinishedOnly)
    undoButton:SetShown(view == "goals" and self.removedGoal ~= nil)
    local goals = self:GetGoals(selectedKey)
    goalOffset = math.max(0, math.min(goalOffset, #goals - goalCapacity))
    for index, row in ipairs(goalRows) do
        local goal = goals[goalOffset + index]
        if hoveredGoal == row and row.goalID ~= (goal and goal.id) then HideGoalDetails() end
        row.goalID = goal and goal.id
        row:SetShown(view == "goals" and goal ~= nil and index <= goalCapacity)
        if goal then
            row.check:SetChecked(goal.done == true)
            row.check:SetEnabled(not goal.automatic)
            row.remove:SetShown(not goal.automatic)
            row.label:SetText(SafeText(goal.title))
            row.label:SetTextColor(goal.done and .45 or .95, goal.done and .78 or .96, goal.done and .60 or .98)
        end
    end
    frame.empty:SetShown(view == "goals" and #goals == 0)
    frame.empty:SetText(total == 0 and "What would you like to finish this week?\nAdd a goal below, or choose a starter goal."
        or "All goals complete for this character.\nTurn off Unfinished only to see or change them.")
    for _, control in ipairs(goalControls) do control:SetShown(view == "goals") end
    appearancePanel:SetShown(view == "appearance")
    if view == "appearance" then
        characterTitle:SetText("Appearance")
        progressText:SetText("Choose your skin and transparency; drag the corner to resize.")
        refreshingAppearance = true
        opacitySlider:SetValue(self.db.opacity); scaleSlider:SetValue(self.db.scale)
        refreshingAppearance = false
        local c = Accent()
        modernButton.label:SetTextColor(self.db.skin == "modern" and c[1] or .56, self.db.skin == "modern" and c[2] or .62, self.db.skin == "modern" and c[3] or .70)
        classicButton.label:SetTextColor(self.db.skin == "classic" and c[1] or .56, self.db.skin == "classic" and c[2] or .62, self.db.skin == "classic" and c[3] or .70)
    end
    refreshRaids:SetShown(view == "raids")
    raidStatus:SetShown(view == "raids")
    if view == "raids" then
        progressText:SetText("Saved raid IDs and boss kills · Scroll for more")
        local entries = self:GetRaidEntries(selectedKey)
        raidOffset = math.max(0, math.min(raidOffset, #entries - goalCapacity))
        for index, row in ipairs(raidRows) do
            local entry = entries[raidOffset + index]
            row:SetShown(entry ~= nil and index <= goalCapacity)
            if entry then
                local c = Accent()
                if entry.raid then
                    local raid = entry.raid
                    row.label:SetText(SafeText(raid.name .. " · " .. raid.difficultyName) .. string.format("  %d/%d", raid.killed, #raid.bosses))
                    row.label:SetTextColor(c[1], c[2], c[3])
                    local hours = math.ceil((raid.resetAt - GetServerTime()) / 3600)
                    row.meta:SetText("ID: " .. SafeText(tostring(raid.id or "Unavailable")) .. " · Resets in " .. hours .. "h" .. (raid.extended and " · Extended" or ""))
                else
                    row.label:SetText((entry.boss.killed and "[Killed]  " or "[Available]  ") .. SafeText(entry.boss.name))
                    row.label:SetTextColor(entry.boss.killed and .40 or .90, entry.boss.killed and .86 or .93, entry.boss.killed and .69 or .96)
                    row.meta:SetText("")
                end
            end
        end
        local stamp = character and character.raidsUpdatedAt
        local updated = stamp and ("Saved " .. date("%d %b, %H:%M", stamp)) or "Log into this character to collect raid information."
        raidStatus:SetText(updated .. (selectedKey ~= self.currentKey and " · Offline snapshot" or ""))
        frame.empty:SetShown(#entries == 0)
        frame.empty:SetText(stamp and "No active saved raid lockouts."
            or "Raid details will appear after logging into this character.\nMailbox data supplies the roster; raid details come from Blizzard.")
        if selectedKey == self.currentKey and self.raidInfoUnavailable then raidStatus:SetText("Raid data unavailable; keeping the last saved snapshot.") end
    else
        for _, row in ipairs(raidRows) do row:Hide() end
    end
    if hoveredGoal then ShowGoalDetails(hoveredGoal) end
end

function ns:LayoutWindow()
    if not frame or not input then return end
    local width,height = frame:GetWidth(),frame:GetHeight()
    local contentWidth = width-250
    characterCapacity = math.min(#characterRows,math.floor((height-230)/38))
    goalCapacity = math.min(#goalRows,math.floor((height-274)/36))
    frame.rosterPanel:SetHeight(height-226)
    frame.contentPanel:SetSize(contentWidth+8,height-268)
    appearancePanel:SetSize(contentWidth+8,height-268)
    for _,row in ipairs(goalRows) do row:SetWidth(contentWidth); row.label:SetWidth(contentWidth-75) end
    for _,row in ipairs(raidRows) do row:SetWidth(contentWidth); row.label:SetWidth(contentWidth-18); row.meta:SetWidth(contentWidth-18) end
    input:SetWidth(contentWidth-102)
    characterTitle:SetWidth(contentWidth); progressText:SetWidth(contentWidth)
    statusText:SetWidth(contentWidth-16); raidStatus:SetWidth(contentWidth)
    frame.empty:SetWidth(contentWidth-40)
    self.db.window.width,self.db.window.height = width,height
    self:Refresh()
end

local function Build()
    if frame then return end
    frame = Surface(CreateFrame("Frame", "RevathsWeeklyPlannerFrame", UIParent, "BackdropTemplate"), "bg")
    frame:SetResizable(true); frame:SetResizeBounds(720, 500, 1200, 900)
    frame:SetSize(math.max(720, math.min(1200, tonumber(ns.db.window.width) or 720)),
        math.max(500, math.min(900, tonumber(ns.db.window.height) or 500))); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true)
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
        ns.db.window.x, ns.db.window.y = x - parentX * scale, y - parentY * scale
        frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", ns.db.window.x, ns.db.window.y)
    end)
    headerGlow = frame:CreateTexture(nil, "BACKGROUND")
    headerGlow:SetPoint("TOPLEFT", 5, -5); headerGlow:SetPoint("TOPRIGHT", -5, -5); headerGlow:SetHeight(72)
    titlePlate = frame:CreateTexture(nil, "BORDER")
    titlePlate:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header"); titlePlate:SetSize(460, 84); titlePlate:SetPoint("TOP", 0, 14)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\RevathsWeeklyPlanner\\Media\\PlannerIcon"); icon:SetSize(40,40); icon:SetPoint("TOPLEFT", 20,-14)
    local title = Label(frame, 20); title:SetPoint("TOPLEFT", 76, -18); title:SetText("REVATH'S ENCHANTED PLANNER")
    local subtitle = Label(frame, 11, true); subtitle:SetPoint("TOPLEFT", 76,-44); subtitle:SetText("Weekly goals · Characters · Raid lockouts")
    headerLine = frame:CreateTexture(nil, "ARTWORK")
    headerLine:SetPoint("TOPLEFT", 18,-78); headerLine:SetPoint("TOPRIGHT", -18,-78); headerLine:SetHeight(2)
    local rosterPanel = Surface(CreateFrame("Frame", nil, frame, "BackdropTemplate"), "panel")
    rosterPanel:SetPoint("TOPLEFT", 14,-128); rosterPanel:SetSize(202,274)
    frame.rosterPanel = rosterPanel
    local contentPanel = Surface(CreateFrame("Frame", nil, frame, "BackdropTemplate"), "panel")
    contentPanel:SetPoint("TOPLEFT", 228,-166); contentPanel:SetSize(478,232)
    frame.contentPanel = contentPanel
    local function SetView(nextView)
        view = nextView; raidOffset = 0; CancelEdit(); Status(""); ns:Refresh()
        if nextView == "raids" then ns:RequestRaidRefresh() end
    end
    goalsTab = Button(frame, "Weekly goals", 112,26, function() SetView("goals") end); goalsTab:SetPoint("TOPLEFT",232,-89)
    raidsTab = Button(frame, "Raid lockouts", 112,26, function() SetView("raids") end); raidsTab:SetPoint("LEFT",goalsTab,"RIGHT",6,0)
    local close = Button(frame, "×", 28, 28, function() frame:Hide() end); close:SetPoint("TOPRIGHT", -12, -12)
    local settings = Button(frame, "Settings", 78, 28, function()
        SetView("appearance")
    end); settings:SetPoint("RIGHT", close, "LEFT", -6, 0)
    filter = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    filter:SetPoint("TOPLEFT", 12, -54); filter:SetSize(26, 26)
    filter:SetScript("OnClick", function(self)
        ns.db.unfinishedOnly = self:GetChecked() == true
        characterOffset, goalOffset = 0, 0; CancelEdit(); ns:Refresh()
    end)
    local filterLabel = Label(frame, 12); filterLabel:SetPoint("LEFT", filter, "RIGHT", 4, 0); filterLabel:SetText("Unfinished only")
    resetText = Label(frame, 12, true); resetText:SetPoint("TOPRIGHT", -18, -63)
    local rosterTitle = Label(frame, 13); rosterTitle:SetPoint("TOPLEFT", 18, -99); rosterTitle:SetText("CHARACTERS")
    local mine = Button(frame, "Me", 36, 24, function()
        selectedKey = ns.currentKey; goalOffset = 0; CancelEdit()
        -- Explicitly selecting a finished character makes its goals visible.
        ns.db.unfinishedOnly = false; ns:Refresh()
    end); mine:SetPoint("TOPLEFT", 175, -92)
    characterTitle = Label(frame, 15); characterTitle:SetPoint("TOPLEFT", 232, -124); characterTitle:SetWidth(470)
    progressText = Label(frame, 10, true); progressText:SetPoint("TOPLEFT", 232, -148); progressText:SetWidth(470)
    for index = 1, 20 do
        local row = Button(frame, "", 194, 36, function(self)
            selectedKey = self.key; goalOffset, raidOffset = 0, 0; CancelEdit(); ns:Refresh()
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
    for index = 1, 20 do
        local row = Button(frame, "", 470, 32, function(self, mouseButton)
            if type(self.goalID) == "string" then
                Status("Default goals update automatically for the logged-in character."); return
            end
            if mouseButton == "RightButton" then
                for _, goal in ipairs(ns:GetGoals(selectedKey)) do
                    if goal.id == self.goalID then
                        editID = goal.id; input:SetText(goal.title); input:SetFocus(); addButton.label:SetText("Save goal")
                        Status("Edit the goal below. Press Escape to cancel."); break
                    end
                end
            else ns:ToggleGoal(selectedKey, self.goalID); ns:Refresh() end
        end)
        row:SetPoint("TOPLEFT", 232, -174 - (index - 1) * 36)
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
        row.remove = remove
        row:SetScript("OnEnter", function(self)
            local c = Accent(); self:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            ShowGoalDetails(self)
        end)
        row:SetScript("OnLeave", function(self) Style(self); HideGoalDetails() end)
        row.check:SetScript("OnEnter", function() ShowGoalDetails(row) end)
        row.check:SetScript("OnLeave", HideGoalDetails)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function(self, delta)
            if hoveredGoal == self and IsShiftKeyDown and IsShiftKeyDown() then
                detailOffset = detailOffset - delta * 6; ShowGoalDetails(self)
            else HideGoalDetails(); goalOffset = math.max(0, goalOffset - delta); ns:Refresh() end
        end)
        goalRows[index] = row
    end
    for index = 1, 20 do
        local row = Surface(CreateFrame("Frame", nil, frame, "BackdropTemplate"), "panel")
        row:SetSize(470,32); row:SetPoint("TOPLEFT",232,-174-(index-1)*36)
        row.label = Label(row,11); row.label:SetPoint("TOPLEFT",8,-3); row.label:SetWidth(452); row.label:SetWordWrap(false)
        row.meta = Label(row,9,true); row.meta:SetPoint("BOTTOMLEFT",8,3); row.meta:SetWidth(452); row.meta:SetWordWrap(false)
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel",function(_,delta) raidOffset = math.max(0,raidOffset-delta); ns:Refresh() end)
        raidRows[index] = row
    end
    refreshRaids = Button(frame, "Refresh raid data", 140,26,function()
        ns:RequestRaidRefresh(); Status("Refreshing the logged-in character's raid information.")
    end); refreshRaids:SetPoint("BOTTOMLEFT",232,70)
    raidStatus = Label(frame,11,true); raidStatus:SetPoint("BOTTOMLEFT",232,46); raidStatus:SetWidth(470)
    frame.empty = Label(contentPanel, 13, true); frame.empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 245, -190); frame.empty:SetWidth(430)
    local starters = { {"Raid", "Finish my raid goal"}, {"Dungeons", "Finish my weekly dungeon goal"}, {"Professions", "Finish my profession weeklies"} }
    for index, starter in ipairs(starters) do
        local button = Button(frame, starter[1], 108, 26, function()
            local ok, message = ns:SaveGoal(selectedKey, starter[2])
            ns:Refresh(); Status(ok and "Starter goal added. Right-click it to make it your own." or message)
        end); button:SetPoint("BOTTOMLEFT", 232 + (index - 1) * 113, 70)
        goalControls[#goalControls + 1] = button
    end
    undoButton = Button(frame, "Undo remove", 126, 26, function()
        local ok = ns:UndoRemove(); ns:Refresh(); Status(ok and "Goal restored." or "A goal with that name already exists.")
    end); undoButton:SetPoint("BOTTOMRIGHT", -18, 70)
    input = Surface(CreateFrame("EditBox", nil, frame, "BackdropTemplate"), "input")
    input:SetSize(368, 28); input:SetPoint("BOTTOMLEFT", 232, 34); input:SetAutoFocus(false)
    input:SetMaxBytes(160); input:SetTextInsets(8, 8, 4, 4); input:SetTextColor(1, 1, 1)
    input:SetScript("OnEnterPressed", SaveGoal)
    input:SetScript("OnEscapePressed", function() CancelEdit(); Status("Editing cancelled.") end)
    addButton = Button(frame, "Add goal", 96, 28, SaveGoal); addButton:SetPoint("LEFT", input, "RIGHT", 6, 0)
    goalControls[#goalControls + 1] = input
    goalControls[#goalControls + 1] = addButton
    local tip = Label(frame, 10, true); tip:SetPoint("BOTTOMLEFT", 18, 64); tip:SetWidth(192)
    tip:SetText("Mailbox characters included.\nScroll either list for more.")
    local manual = Label(frame, 10, true); manual:SetPoint("BOTTOMLEFT", 18, 26); manual:SetWidth(192)
    manual:SetText("Default goals update automatically.\nPersonal goals: check off yourself.")
    statusText = Label(frame, 11, true); statusText:SetPoint("BOTTOMLEFT", 232, 12); statusText:SetWidth(470); statusText:SetWordWrap(false)
    statusText:SetText("Type a weekly goal above and press Enter.")
    appearancePanel = Surface(CreateFrame("Frame", nil, frame, "BackdropTemplate"), "panel")
    appearancePanel:SetPoint("TOPLEFT",228,-166); appearancePanel:SetSize(478,232)
    modernButton = Button(appearancePanel,"Modern",130,32,function() ns.db.skin = "modern"; ns:ApplyAppearance() end)
    modernButton:SetPoint("TOPLEFT",18,-18)
    classicButton = Button(appearancePanel,"Classic",130,32,function() ns.db.skin = "classic"; ns:ApplyAppearance() end)
    classicButton:SetPoint("LEFT",modernButton,"RIGHT",12,0)
    local hint = Label(appearancePanel,11,true); hint:SetPoint("TOPLEFT",18,-59)
    hint:SetText("Modern: palettes and transparency. Classic: old-WoW frames.")
    local function Slider(label, y, minimum, maximum, getter, setter)
        local caption = Label(appearancePanel,12,true); caption:SetPoint("TOPLEFT",18,y); caption:SetText(label)
        local valueText = Label(appearancePanel,12); valueText:SetPoint("TOPLEFT",258,y)
        local slider = CreateFrame("Slider",nil,appearancePanel)
        slider:SetPoint("TOPLEFT",18,y-25); slider:SetSize(290,18)
        slider:SetOrientation("HORIZONTAL"); slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
        slider:SetMinMaxValues(minimum,maximum); slider:SetValueStep(.05); slider:SetObeyStepOnDrag(true)
        local track = slider:CreateTexture(nil,"BACKGROUND")
        track:SetColorTexture(.18,.23,.31,.8); track:SetPoint("LEFT",2,0); track:SetPoint("RIGHT",-2,0); track:SetHeight(4)
        slider.track = track
        slider:SetScript("OnValueChanged",function(_,value)
            valueText:SetText(string.format("%d%%",value*100))
            if refreshingAppearance then return end
            setter(math.max(minimum,math.min(maximum,value))); ns:ApplyAppearance()
        end)
        slider:SetValue(getter())
        return slider,valueText
    end
    refreshingAppearance = true
    opacitySlider,opacityValue = Slider("MODERN OPACITY",-93,.55,1,function() return ns.db.opacity end,function(v) ns.db.opacity=v end)
    scaleSlider,scaleValue = Slider("WINDOW SCALE",-167,.65,1.10,function() return ns.db.scale end,function(v) ns.db.scale=v end)
    refreshingAppearance = false
    local more = Button(appearancePanel,"Palette / font",124,26,function()
        if SlashCmdList.REVATHSENCHANTEDFRAMES then SlashCmdList.REVATHSENCHANTEDFRAMES() end
    end); more:SetPoint("BOTTOMRIGHT",-18,18)
    local resize = CreateFrame("Button",nil,frame)
    resize:SetSize(18,18); resize:SetPoint("BOTTOMRIGHT",-5,5)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown",function(_,button) if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end end)
    local function StopResize()
        frame:StopMovingOrSizing()
        local x,y = frame:GetCenter()
        local px,py = UIParent:GetCenter()
        local scale = UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
        ns.db.window.x,ns.db.window.y = x-px*scale,y-py*scale
        frame:ClearAllPoints(); frame:SetPoint("CENTER",UIParent,"CENTER",ns.db.window.x,ns.db.window.y)
    end
    resize:SetScript("OnMouseUp",StopResize)
    frame:SetScript("OnSizeChanged",function() ns:LayoutWindow() end)
    frame:SetScript("OnHide",function() HideGoalDetails(); frame:StopMovingOrSizing(); CancelEdit() end)
    ns:LayoutWindow()
    frame:SetScript("OnShow", function() ns:ImportMailboxCharacters(); ns:CheckWeeklyReset(); ns:Refresh(); ns:RequestRaidRefresh(); if ns.CaptureWeeklyProgress then ns:CaptureWeeklyProgress() end end)
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

local minimapButton

function ns:InitializeMinimap()
    if minimapButton or not self.db or not Minimap then return end
    local angle = tonumber(self.db.minimapAngle)
    self.db.minimapAngle = angle and angle == angle and math.abs(angle) < math.huge and angle % 360 or 225
    local button = CreateFrame("Button", "RevathsWeeklyPlannerMinimapButton", Minimap)
    minimapButton = button
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\RevathsWeeklyPlanner\\Media\\PlannerIcon")
    icon:SetSize(20, 20); icon:SetPoint("CENTER")
    icon:SetTexCoord(0, 1, 0, 1)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54); border:SetPoint("TOPLEFT")
    local function Position()
        local radians = math.rad(ns.db.minimapAngle)
        local radius = math.min(Minimap:GetWidth(), Minimap:GetHeight()) / 2 + 10
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
    end
    button:SetScript("OnClick", function() ns:Toggle() end)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:SetText(ns.title)
        GameTooltip:AddLine("Click to open your weekly planner.", 1, 1, 1)
        GameTooltip:AddLine("Drag to move around the minimap.", .56, .62, .70)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function()
        GameTooltip:Hide()
        button:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            if not centerX or not centerY then return end
            local scale = Minimap:GetEffectiveScale()
            ns.db.minimapAngle = math.deg(math.atan2(y / scale - centerY, x / scale - centerX)) % 360
            Position()
        end)
    end)
    button:SetScript("OnDragStop", function() button:SetScript("OnUpdate", nil) end)
    button:HookScript("OnHide", function() button:SetScript("OnUpdate", nil) end)
    Minimap:HookScript("OnSizeChanged", Position)
    Position()
end
