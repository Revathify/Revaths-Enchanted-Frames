local addonName, ns = ...

ns.name = addonName
ns.title = "Revath's Enchanted Frames"
ns.author = "Revath#2331 (Revathify)"
ns.support = "https://buymeacoffee.com/revath"
ns.version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version"))
    or (GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")) or "unknown"

local function InitializeDatabase()
    if type(RevathsEnchantedFramesDB) ~= "table" then RevathsEnchantedFramesDB = {} end
    RevathsEnchantedFramesDB.version = 1
    RevathsEnchantedFramesDB.modules = type(RevathsEnchantedFramesDB.modules) == "table" and RevathsEnchantedFramesDB.modules or {}
    ns.db = RevathsEnchantedFramesDB
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, _, loadedName)
    if loadedName ~= addonName then return end
    InitializeDatabase()
    if ns.RegisterSettings then ns:RegisterSettings() end
end)

function ns:OpenSettings()
    if Settings and Settings.OpenToCategory and self.settingsCategoryID then
        Settings.OpenToCategory(self.settingsCategoryID)
    elseif InterfaceOptionsFrame_OpenToCategory and self.settingsPanel then
        InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.settingsPanel)
    end
end

SLASH_REVATHSENCHANTEDFRAMES1 = "/ref"
SLASH_REVATHSENCHANTEDFRAMES2 = "/enchantedframes"
SlashCmdList.REVATHSENCHANTEDFRAMES = function() ns:OpenSettings() end
