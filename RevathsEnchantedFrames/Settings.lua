local _, ns = ...

local PALETTES = {
    { key = "midnight", label = "Midnight Cyan" }, { key = "arcane", label = "Arcane Violet" },
    { key = "emerald", label = "Emerald Grove" }, { key = "crimson", label = "Crimson Ember" },
    { key = "royal", label = "Royal Blue" }, { key = "graphite", label = "Graphite Gray" },
}
local FONTS = {
    { key = "friz", label = "Friz Quadrata", path = STANDARD_TEXT_FONT, flags = "" },
    { key = "frizOutline", label = "Friz Outlined", path = STANDARD_TEXT_FONT, flags = "OUTLINE" },
    { key = "arial", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF", flags = "" },
    { key = "arialOutline", label = "Arial Outlined", path = "Fonts\\ARIALN.TTF", flags = "OUTLINE" },
    { key = "morpheus", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF", flags = "" },
    { key = "morpheusOutline", label = "Morpheus Outlined", path = "Fonts\\MORPHEUS.TTF", flags = "OUTLINE" },
    { key = "skurri", label = "Skurri", path = "Fonts\\SKURRI.TTF", flags = "" },
    { key = "skurriOutline", label = "Skurri Outlined", path = "Fonts\\SKURRI.TTF", flags = "OUTLINE" },
}
local SKINS = { { key = "modern", label = "Modern" }, { key = "classic", label = "Classic" } }

local function FontOptions()
    if LibStub then
        local media = LibStub("LibSharedMedia-3.0", true)
        local registered = media and media.HashTable and media:HashTable("font")
        if type(registered) == "table" then
            local knownKeys, knownPaths, additions = {}, {}, {}
            for _, font in ipairs(FONTS) do
                knownKeys[font.key] = true
                if type(font.path) == "string" and font.flags == "" then knownPaths[string.lower(font.path)] = true end
            end
            for name, path in pairs(registered) do
                local key = type(name) == "string" and "shared:" .. name
                local loweredPath = type(path) == "string" and string.lower(path)
                if key and loweredPath and path ~= "" and not knownKeys[key] and not knownPaths[loweredPath] then
                    additions[#additions + 1] = { key = key, label = name, path = path, flags = "" }
                    knownKeys[key], knownPaths[loweredPath] = true, true
                end
            end
            table.sort(additions, function(a, b) return string.lower(a.label) < string.lower(b.label) end)
            for _, font in ipairs(additions) do FONTS[#FONTS + 1] = font end
        end
    end
    return FONTS
end

local function EnsureMailboxSettings()
    if type(RevathsMailboxDB) ~= "table" then RevathsMailboxDB = {} end
    RevathsMailboxDB.settings = type(RevathsMailboxDB.settings) == "table" and RevathsMailboxDB.settings or {}
    local settings = RevathsMailboxDB.settings
    settings.skin = settings.skin == "classic" and "classic" or "modern"
    settings.palette = type(settings.palette) == "string" and settings.palette or "midnight"
    settings.font = type(settings.font) == "string" and settings.font or "friz"
    settings.modernOpacity = math.max(0.55, math.min(1, tonumber(settings.modernOpacity) or 0.96))
    settings.scale = math.max(0.65, math.min(1.10, tonumber(settings.scale) or 1))
    if settings.showOfflineContacts == nil then settings.showOfflineContacts = true end
    if settings.tooltipHelperEnabled == nil then settings.tooltipHelperEnabled = true end
    return settings
end

local function EnsureMacroSettings()
    if type(RevathsMacroDB) ~= "table" then RevathsMacroDB = {} end
    RevathsMacroDB.skin = RevathsMacroDB.skin == "classic" and "classic" or "modern"
    RevathsMacroDB.palette = type(RevathsMacroDB.palette) == "string" and RevathsMacroDB.palette or "midnight"
    RevathsMacroDB.font = type(RevathsMacroDB.font) == "string" and RevathsMacroDB.font or "friz"
    RevathsMacroDB.opacity = math.max(0.55, math.min(1, tonumber(RevathsMacroDB.opacity) or 0.96))
    RevathsMacroDB.fontSize = math.max(10, math.min(24, tonumber(RevathsMacroDB.fontSize) or 13))
    return RevathsMacroDB
end

local function ApplyMailbox()
    if RevathsEnchantedMailbox_ApplySettings then RevathsEnchantedMailbox_ApplySettings() end
end

local function ApplyMacros()
    if RevathsEnchantedMacros_ApplySettings then RevathsEnchantedMacros_ApplySettings() end
end

local function ApplyTooltips(enabled)
    local mailbox = EnsureMailboxSettings()
    mailbox.tooltipHelperEnabled = enabled == true
    if type(RevathsMailboxTooltipHelperDB) ~= "table" then RevathsMailboxTooltipHelperDB = {} end
    RevathsMailboxTooltipHelperDB.enabled = enabled == true
    if RevathsEnchantedTooltips_SetEnabled then RevathsEnchantedTooltips_SetEnabled(enabled)
    elseif RevathsMailboxTooltipHelper_SetEnabled then RevathsMailboxTooltipHelper_SetEnabled(enabled) end
end

local function CreatePanel(title, description)
    local panel = CreateFrame("Frame")
    panel.name = title
    local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    heading:SetPoint("TOPLEFT", 20, -20); heading:SetText(title)
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    subtitle:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -10); subtitle:SetPoint("RIGHT", -24, 0)
    subtitle:SetJustifyH("LEFT"); subtitle:SetText(description)
    panel.refreshers = {}
    function panel:RefreshValues() for _, refresh in ipairs(self.refreshers) do refresh() end end
    panel:SetScript("OnShow", function(self) self:RefreshValues() end)
    return panel
end

local function Label(panel, text, y, template)
    local label = panel:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    label:SetPoint("TOPLEFT", 24, y); label:SetText(text)
    return label
end

local function AddDropdown(panel, y, labelText, optionsProvider, getter, setter, apply)
    Label(panel, labelText, y)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 24, y - 24); button:SetSize(300, 30)
    local arrow = button:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(17, 17); arrow:SetPoint("RIGHT", -9, 0)
    local atlasLoaded = arrow.SetAtlas and pcall(arrow.SetAtlas, arrow, "common-dropdown-icon")
    if not atlasLoaded then arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up") end
    local buttonText = button:GetFontString()
    if buttonText then
        buttonText:ClearAllPoints(); buttonText:SetPoint("LEFT", 12, 0); buttonText:SetPoint("RIGHT", -32, 0); buttonText:SetJustifyH("CENTER")
    end
    local menu = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    menu:SetSize(320, 306); menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -4)
    menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetClampedToScreen(true)
    menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    menu:SetBackdropColor(0.035, 0.04, 0.055, 0.98); menu:SetBackdropBorderColor(0.22, 0.62, 0.75, 1)
    menu:EnableMouse(true); menu:EnableMouseWheel(true); menu:Hide(); menu.page = 1
    local rows, rowButtons = 10, {}
    for index = 1, rows do
        local choice = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
        choice:SetPoint("TOPLEFT", 10, -10 - ((index - 1) * 25)); choice:SetSize(300, 23)
        choice:SetScript("OnClick", function(self)
            if not self.optionKey then return end
            setter(self.optionKey); apply(); menu:Hide(); button:Refresh()
        end)
        rowButtons[index] = choice
    end
    local previous = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    previous:SetPoint("BOTTOMLEFT", 10, 9); previous:SetSize(42, 25); previous:SetText("<")
    local nextButton = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
    nextButton:SetPoint("BOTTOMRIGHT", -10, 9); nextButton:SetSize(42, 25); nextButton:SetText(">")
    local pageText = menu:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    pageText:SetPoint("BOTTOM", 0, 16)
    function menu:Refresh()
        local options = optionsProvider()
        local pages = math.max(1, math.ceil(#options / rows))
        self.page = math.max(1, math.min(self.page, pages))
        self:SetHeight((math.min(rows, #options) * 25) + 56)
        local offset = (self.page - 1) * rows
        for index, choice in ipairs(rowButtons) do
            local option = options[offset + index]
            choice.optionKey = option and option.key
            choice:SetShown(option ~= nil)
            if option then
                local selected = option.key == getter()
                choice:SetText(option.label)
                local fontString = choice:GetFontString()
                if fontString and option.path then
                    local ok, loaded = pcall(fontString.SetFont, fontString, option.path, 12, option.flags or "")
                    if not ok or loaded == false then fontString:SetFont(STANDARD_TEXT_FONT, 12, "") end
                elseif fontString then fontString:SetFont(STANDARD_TEXT_FONT, 12, "") end
                if fontString then
                    if selected then fontString:SetTextColor(1, 0.82, 0.18, 1)
                    else fontString:SetTextColor(1, 1, 1, 1) end
                end
            end
        end
        previous:SetEnabled(self.page > 1); nextButton:SetEnabled(self.page < pages)
        pageText:SetText(string.format("%d / %d  ·  %d choices", self.page, pages, #options))
    end
    previous:SetScript("OnClick", function() if menu.page > 1 then menu.page = menu.page - 1; menu:Refresh() end end)
    nextButton:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil(#optionsProvider() / rows))
        if menu.page < pages then menu.page = menu.page + 1; menu:Refresh() end
    end)
    menu:SetScript("OnMouseWheel", function(_, delta)
        local pages = math.max(1, math.ceil(#optionsProvider() / rows))
        menu.page = math.max(1, math.min(pages, menu.page - delta)); menu:Refresh()
    end)
    local function Refresh()
        local options = optionsProvider()
        local key = getter()
        for _, option in ipairs(options) do
            if option.key == key then
                button:SetText(option.label)
                local fontString = button:GetFontString()
                if fontString and option.path then
                    local ok, loaded = pcall(fontString.SetFont, fontString, option.path, 12, option.flags or "")
                    if not ok or loaded == false then fontString:SetFont(STANDARD_TEXT_FONT, 12, "") end
                elseif fontString then fontString:SetFont(STANDARD_TEXT_FONT, 12, "") end
                return
            end
        end
        button:SetText(options[1].label)
    end
    button.Refresh = Refresh
    button:SetScript("OnClick", function()
        menu.page = 1; menu:Refresh(); menu:SetShown(not menu:IsShown())
    end)
    panel.refreshers[#panel.refreshers + 1] = Refresh
    Refresh()
    return button
end

local sliderIndex = 0
local function AddSlider(panel, y, labelText, minimum, maximum, step, getter, setter, apply, formatter)
    Label(panel, labelText, y)
    local value = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    value:SetPoint("TOPLEFT", 292, y); value:SetWidth(70); value:SetJustifyH("RIGHT")
    sliderIndex = sliderIndex + 1
    local name = "RevathsEnchantedFramesOptionsSlider" .. sliderIndex
    local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 31, y - 37); slider:SetSize(250, 18)
    slider:SetMinMaxValues(minimum, maximum); slider:SetValueStep(step); slider:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText(tostring(minimum)); _G[name .. "High"]:SetText(tostring(maximum)); _G[name .. "Text"]:SetText("")
    local refreshing
    slider:SetScript("OnValueChanged", function(_, raw)
        local rounded = math.floor((raw / step) + 0.5) * step
        value:SetText(formatter(rounded))
        if not refreshing then setter(rounded); apply() end
    end)
    local function Refresh()
        refreshing = true; slider:SetValue(getter()); refreshing = false
        value:SetText(formatter(getter()))
    end
    panel.refreshers[#panel.refreshers + 1] = Refresh
    Refresh()
    return slider
end

local function AddCheckbox(panel, y, labelText, getter, setter, apply)
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, y); check:SetSize(28, 28)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 6, 0); label:SetText(labelText)
    check:SetScript("OnClick", function(self) setter(self:GetChecked() == true); apply(self:GetChecked() == true) end)
    local function Refresh() check:SetChecked(getter()) end
    panel.refreshers[#panel.refreshers + 1] = Refresh
    Refresh()
    return check
end

local function AddModuleStatus(panel, y, title, addonID, description)
    local enabled = not C_AddOns or not C_AddOns.IsAddOnEnabled or C_AddOns.IsAddOnEnabled(addonID)
    local name = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", 24, y); name:SetText((enabled and "|cff55dd88ENABLED|r  " or "|cffdd5555DISABLED|r  ") .. title)
    local detail = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    detail:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 20, -5); detail:SetWidth(560); detail:SetJustifyH("LEFT"); detail:SetText(description)
end

function ns:RegisterSettings()
    if self.settingsRegistered then return end
    self.settingsRegistered = true

    local overview = CreatePanel(self.title, "One parent addon with independently managed Mailbox, Macros, and Tooltips modules.")
    AddModuleStatus(overview, -104, "Revath's Enchanted Mailbox", "RevathsMailbox", "Mailbox replacement, contacts, alt tracking, quick attachments, and Modern or Classic skins.")
    AddModuleStatus(overview, -174, "Revath's Enchanted Macros", "RevathsMacro", "Account and character macro editing, curated templates, icon browser, drag-to-action-bar, and syntax assistance.")
    AddModuleStatus(overview, -244, "Revath's Enchanted Tooltips", "RevathsMailboxTooltipHelper", "Account-wide bag, bank, and Warband-bank item totals in item tooltips.")
    Label(overview, "AUTHOR", -338, "GameFontNormalSmall")
    Label(overview, self.author, -360, "GameFontHighlight")
    Label(overview, "VERSION", -402, "GameFontNormalSmall")
    Label(overview, tostring(self.version), -424, "GameFontHighlight")
    Label(overview, "Open these settings with /ref or /enchantedframes.", -472, "GameFontHighlightSmall")

    local mailboxPanel = CreatePanel("Revath's Enchanted Mailbox", "Account-wide appearance and mailbox behavior. Changes apply immediately when the mailbox module is loaded.")
    AddDropdown(mailboxPanel, -96, "Skin", function() return SKINS end, function() return EnsureMailboxSettings().skin end, function(v) EnsureMailboxSettings().skin = v end, ApplyMailbox)
    AddDropdown(mailboxPanel, -170, "Modern color palette", function() return PALETTES end, function() return EnsureMailboxSettings().palette end, function(v) EnsureMailboxSettings().palette = v end, ApplyMailbox)
    AddDropdown(mailboxPanel, -244, "Font", FontOptions, function() return EnsureMailboxSettings().font end, function(v) EnsureMailboxSettings().font = v end, ApplyMailbox)
    AddSlider(mailboxPanel, -326, "Modern opacity", 0.55, 1, 0.05, function() return EnsureMailboxSettings().modernOpacity end, function(v) EnsureMailboxSettings().modernOpacity = v end, ApplyMailbox, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(mailboxPanel, -410, "Window scale", 0.65, 1.10, 0.05, function() return EnsureMailboxSettings().scale end, function(v) EnsureMailboxSettings().scale = v end, ApplyMailbox, function(v) return string.format("%d%%", v * 100) end)
    AddCheckbox(mailboxPanel, -486, "Show offline contacts", function() return EnsureMailboxSettings().showOfflineContacts ~= false end, function(v) EnsureMailboxSettings().showOfflineContacts = v end, ApplyMailbox)

    local macroPanel = CreatePanel("Revath's Enchanted Macros", "Appearance controls for the macro editor. Its font-size buttons remain available inside the editor as well.")
    AddDropdown(macroPanel, -96, "Skin", function() return SKINS end, function() return EnsureMacroSettings().skin end, function(v) EnsureMacroSettings().skin = v end, ApplyMacros)
    AddDropdown(macroPanel, -170, "Modern color palette", function() return PALETTES end, function() return EnsureMacroSettings().palette end, function(v) EnsureMacroSettings().palette = v end, ApplyMacros)
    AddDropdown(macroPanel, -244, "Font", FontOptions, function() return EnsureMacroSettings().font end, function(v) EnsureMacroSettings().font = v end, ApplyMacros)
    AddSlider(macroPanel, -326, "Window opacity", 0.55, 1, 0.05, function() return EnsureMacroSettings().opacity end, function(v) EnsureMacroSettings().opacity = v end, ApplyMacros, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(macroPanel, -410, "Editor font size", 10, 24, 1, function() return EnsureMacroSettings().fontSize end, function(v) EnsureMacroSettings().fontSize = v end, ApplyMacros, function(v) return string.format("%d px", v) end)

    local tooltipPanel = CreatePanel("Revath's Enchanted Tooltips", "Control account-wide item totals shown in item tooltips. Hold Shift over an item for the character breakdown.")
    AddCheckbox(tooltipPanel, -102, "Show account-wide item totals", function() return EnsureMailboxSettings().tooltipHelperEnabled ~= false end, function(v) EnsureMailboxSettings().tooltipHelperEnabled = v end, ApplyTooltips)
    Label(tooltipPanel, "The module records bags on login and bag updates, banks while open, and purchased Warband-bank tabs when available.", -154, "GameFontHighlightSmall"):SetWidth(600)

    self.settingsPanel = overview
    self.settingsPanels = { overview, mailboxPanel, macroPanel, tooltipPanel }
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(overview, self.title)
        Settings.RegisterAddOnCategory(category)
        Settings.RegisterCanvasLayoutSubcategory(category, mailboxPanel, "Mailbox")
        Settings.RegisterCanvasLayoutSubcategory(category, macroPanel, "Macros")
        Settings.RegisterCanvasLayoutSubcategory(category, tooltipPanel, "Tooltips")
        self.settingsCategoryID = category:GetID()
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(overview)
        mailboxPanel.parent, macroPanel.parent, tooltipPanel.parent = self.title, self.title, self.title
        InterfaceOptions_AddCategory(mailboxPanel); InterfaceOptions_AddCategory(macroPanel); InterfaceOptions_AddCategory(tooltipPanel)
    end

    function RevathsEnchantedFrames_RefreshSettings()
        for _, panel in ipairs(ns.settingsPanels or {}) do
            if panel.RefreshValues then panel:RefreshValues() end
        end
    end
end
