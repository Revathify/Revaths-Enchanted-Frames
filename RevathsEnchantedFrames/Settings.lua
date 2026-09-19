local _, ns = ...

local PALETTES = {
    { key = "midnight", label = "Midnight Cyan" }, { key = "arcane", label = "Arcane Violet" },
    { key = "emerald", label = "Emerald Grove" }, { key = "crimson", label = "Crimson Ember" },
    { key = "royal", label = "Royal Blue" }, { key = "graphite", label = "Graphite Gray" },
}
local FONTS = {
    { key = "friz", label = "Friz Quadrata" }, { key = "frizOutline", label = "Friz Outlined" },
    { key = "arial", label = "Arial Narrow" }, { key = "arialOutline", label = "Arial Outlined" },
    { key = "morpheus", label = "Morpheus" }, { key = "morpheusOutline", label = "Morpheus Outlined" },
    { key = "skurri", label = "Skurri" }, { key = "skurriOutline", label = "Skurri Outlined" },
}
local SKINS = { { key = "modern", label = "Modern" }, { key = "classic", label = "Classic" } }

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
    panel:SetScript("OnShow", function(self) for _, refresh in ipairs(self.refreshers) do refresh() end end)
    return panel
end

local function Label(panel, text, y, template)
    local label = panel:CreateFontString(nil, "ARTWORK", template or "GameFontNormal")
    label:SetPoint("TOPLEFT", 24, y); label:SetText(text)
    return label
end

local function AddCycle(panel, y, labelText, options, getter, setter, apply)
    Label(panel, labelText, y)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", 24, y - 24); button:SetSize(250, 30)
    local function Refresh()
        local key = getter()
        for _, option in ipairs(options) do if option.key == key then button:SetText(option.label); return end end
        button:SetText(options[1].label)
    end
    button:SetScript("OnClick", function()
        local current, index = getter(), 1
        for i, option in ipairs(options) do if option.key == current then index = i; break end end
        local nextOption = options[(index % #options) + 1]
        setter(nextOption.key); apply(); Refresh()
    end)
    panel.refreshers[#panel.refreshers + 1] = Refresh
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
    panel.refreshers[#panel.refreshers + 1] = function()
        refreshing = true; slider:SetValue(getter()); refreshing = false
        value:SetText(formatter(getter()))
    end
    return slider
end

local function AddCheckbox(panel, y, labelText, getter, setter, apply)
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", 20, y); check:SetSize(28, 28)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 6, 0); label:SetText(labelText)
    check:SetScript("OnClick", function(self) setter(self:GetChecked() == true); apply(self:GetChecked() == true) end)
    panel.refreshers[#panel.refreshers + 1] = function() check:SetChecked(getter()) end
    return check
end

local function AddModuleStatus(panel, y, title, addonID, description)
    local enabled = not C_AddOns or not C_AddOns.IsAddOnEnabled or C_AddOns.IsAddOnEnabled(addonID)
    local name = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", 24, y); name:SetText((enabled and "|cff55dd88●|r  " or "|cffdd5555●|r  ") .. title)
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
    Label(overview, "SUPPORT", -466, "GameFontNormalSmall")
    Label(overview, self.support, -488, "GameFontHighlight")
    Label(overview, "Open these settings with /ref or /enchantedframes.", -536, "GameFontHighlightSmall")

    local mailboxPanel = CreatePanel("Revath's Enchanted Mailbox", "Account-wide appearance and mailbox behavior. Changes apply immediately when the mailbox module is loaded.")
    AddCycle(mailboxPanel, -96, "Skin", SKINS, function() return EnsureMailboxSettings().skin end, function(v) EnsureMailboxSettings().skin = v end, ApplyMailbox)
    AddCycle(mailboxPanel, -170, "Modern color palette", PALETTES, function() return EnsureMailboxSettings().palette end, function(v) EnsureMailboxSettings().palette = v end, ApplyMailbox)
    AddCycle(mailboxPanel, -244, "Font", FONTS, function() return EnsureMailboxSettings().font end, function(v) EnsureMailboxSettings().font = v end, ApplyMailbox)
    AddSlider(mailboxPanel, -326, "Modern opacity", 0.55, 1, 0.05, function() return EnsureMailboxSettings().modernOpacity end, function(v) EnsureMailboxSettings().modernOpacity = v end, ApplyMailbox, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(mailboxPanel, -410, "Window scale", 0.65, 1.10, 0.05, function() return EnsureMailboxSettings().scale end, function(v) EnsureMailboxSettings().scale = v end, ApplyMailbox, function(v) return string.format("%d%%", v * 100) end)
    AddCheckbox(mailboxPanel, -486, "Show offline contacts", function() return EnsureMailboxSettings().showOfflineContacts ~= false end, function(v) EnsureMailboxSettings().showOfflineContacts = v end, ApplyMailbox)

    local macroPanel = CreatePanel("Revath's Enchanted Macros", "Appearance controls for the macro editor. Its font-size buttons remain available inside the editor as well.")
    AddCycle(macroPanel, -96, "Skin", SKINS, function() return EnsureMacroSettings().skin end, function(v) EnsureMacroSettings().skin = v end, ApplyMacros)
    AddCycle(macroPanel, -170, "Modern color palette", PALETTES, function() return EnsureMacroSettings().palette end, function(v) EnsureMacroSettings().palette = v end, ApplyMacros)
    AddCycle(macroPanel, -244, "Font", FONTS, function() return EnsureMacroSettings().font end, function(v) EnsureMacroSettings().font = v end, ApplyMacros)
    AddSlider(macroPanel, -326, "Window opacity", 0.55, 1, 0.05, function() return EnsureMacroSettings().opacity end, function(v) EnsureMacroSettings().opacity = v end, ApplyMacros, function(v) return string.format("%d%%", v * 100) end)
    AddSlider(macroPanel, -410, "Editor font size", 10, 24, 1, function() return EnsureMacroSettings().fontSize end, function(v) EnsureMacroSettings().fontSize = v end, ApplyMacros, function(v) return string.format("%d px", v) end)

    local tooltipPanel = CreatePanel("Revath's Enchanted Tooltips", "Control account-wide item totals shown in item tooltips. Hold Shift over an item for the character breakdown.")
    AddCheckbox(tooltipPanel, -102, "Show account-wide item totals", function() return EnsureMailboxSettings().tooltipHelperEnabled ~= false end, function(v) EnsureMailboxSettings().tooltipHelperEnabled = v end, ApplyTooltips)
    Label(tooltipPanel, "The module records bags on login and bag updates, banks while open, and purchased Warband-bank tabs when available.", -154, "GameFontHighlightSmall"):SetWidth(600)

    self.settingsPanel = overview
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
end
