local database
local currentCharacterKey
local isBankOpen = false

local function getCharacterKey()
    return (GetRealmName() or "Unknown Realm") .. " - " .. UnitName("player")
end

local function getItemID(itemLinkOrID)
    if type(itemLinkOrID) == "number" then return itemLinkOrID end
    if type(itemLinkOrID) == "string" then return C_Item.GetItemInfoInstant(itemLinkOrID) end
end

local function isSoulboundItem(containerID, slot)
    if not C_TooltipInfo or not C_TooltipInfo.GetBagItem then return false end
    local tooltipData = C_TooltipInfo.GetBagItem(containerID, slot)
    local soulboundText = string.lower(ITEM_SOULBOUND or "Soulbound")
    for _, line in ipairs(tooltipData and tooltipData.lines or {}) do
        if line.leftText and string.find(string.lower(line.leftText), soulboundText, 1, true) then return true end
    end
    return false
end

local function addContainerItems(containerID, counts)
    if type(containerID) ~= "number" then return end
    local slotCount = C_Container.GetContainerNumSlots(containerID) or 0
    for slot = 1, slotCount do
        local itemInfo = C_Container.GetContainerItemInfo(containerID, slot)
        if itemInfo then
            local itemID = getItemID(itemInfo.itemID or itemInfo.hyperlink)
            if itemID and not isSoulboundItem(containerID, slot) then
                counts[itemID] = (counts[itemID] or 0) + (itemInfo.stackCount or 1)
            end
        end
    end
end

local function scanCharacter()
    local bags = {}
    addContainerItems(0, bags)
    for bagID = 1, 5 do addContainerItems(bagID, bags) end
    local character = database.characters[currentCharacterKey] or {}
    character.bags = bags
    if isBankOpen then
        local bank = {}
        addContainerItems(-2, bank)
        for bagID = 6, 11 do addContainerItems(bagID, bank) end
        addContainerItems(5, bank)
        character.bank = bank
    end
    database.characters[currentCharacterKey] = character
end

local function scanWarbandBank()
    local warbandBank = {}
    local accountBankTabs
    if C_Bank and C_Bank.FetchPurchasedBankTabIDs then
        local accountBankType = Enum and Enum.BankType and Enum.BankType.Account or 2
        accountBankTabs = C_Bank.FetchPurchasedBankTabIDs(accountBankType)
    end
    if accountBankTabs then
        for _, containerID in ipairs(accountBankTabs) do addContainerItems(containerID, warbandBank) end
    else
        for containerID = 12, 16 do addContainerItems(containerID, warbandBank) end
    end
    database.warbandBank = warbandBank
end

local function getTotals(itemID)
    local total, currentCount = 0, 0
    local warbandCount = (database.warbandBank and database.warbandBank[itemID]) or 0
    local characterCounts = {}
    for characterKey, counts in pairs(database.characters) do
        local count = ((counts.bags or {})[itemID] or 0) + ((counts.bank or {})[itemID] or 0)
        total = total + count
        if count > 0 then characterCounts[characterKey] = count end
        if characterKey == currentCharacterKey then currentCount = count end
    end
    return total + warbandCount, currentCount, warbandCount, characterCounts
end

local function addTooltipCount(tooltip, data)
    if not database or not database.enabled or tooltip.rmbthAddedItemID then return end
    local itemID = data and getItemID(data.id)
    if not itemID then local _, itemLink = tooltip:GetItem(); itemID = getItemID(itemLink) end
    if not itemID or not database.characters then return end
    local total, currentCount, warbandCount, characterCounts = getTotals(itemID)
    if total == 0 then return end
    tooltip:AddLine(string.format("Enchanted Total: %d", total), 0.45, 0.8, 1)
    if IsShiftKeyDown() then
        tooltip:AddLine(string.format("This character: %d", currentCount), 0.75, 0.75, 0.75)
        if warbandCount > 0 then tooltip:AddLine(string.format("Warbound Bank: %d", warbandCount), 0.75, 0.75, 0.75) end
        local otherCharacters = {}
        for characterKey, count in pairs(characterCounts) do
            if characterKey ~= currentCharacterKey then otherCharacters[#otherCharacters + 1] = { name = characterKey, count = count } end
        end
        table.sort(otherCharacters, function(left, right) return left.name < right.name end)
        for _, character in ipairs(otherCharacters) do tooltip:AddLine(string.format("%s: %d", character.name, character.count), 0.75, 0.75, 0.75) end
    end
    tooltip.rmbthAddedItemID = itemID
    tooltip:Show()
end

function RevathsEnchantedTooltips_SetEnabled(enabled)
    database.enabled = enabled == true
end

RevathsMailboxTooltipHelper_SetEnabled = RevathsEnchantedTooltips_SetEnabled

local function rescan()
    if database and currentCharacterKey then
        scanCharacter()
        if isBankOpen then scanWarbandBank() end
    end
end

local function initialize()
    local parentSettings = type(RevathsMailboxDB) == "table" and RevathsMailboxDB.settings
    local defaultEnabled = not parentSettings or parentSettings.tooltipHelperEnabled ~= false
    database = RevathsMailboxTooltipHelperDB or { version = 1, enabled = defaultEnabled, characters = {} }
    if parentSettings then database.enabled = parentSettings.tooltipHelperEnabled ~= false
    else database.enabled = database.enabled ~= false end
    database.characters = database.characters or {}
    RevathsMailboxTooltipHelperDB = database
    currentCharacterKey = getCharacterKey()
    rescan()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("BANKFRAME_CLOSED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
eventFrame:RegisterEvent("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "RevathsMailboxTooltipHelper" then
        initialize()
    elseif event == "PLAYER_LOGIN" and not database then
        initialize()
    elseif event == "BANKFRAME_OPENED" then
        isBankOpen = true; rescan()
    elseif event == "BANKFRAME_CLOSED" then
        isBankOpen = false
    else
        rescan()
    end
end)

if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, addTooltipCount)
else
    GameTooltip:HookScript("OnTooltipSetItem", addTooltipCount)
    ItemRefTooltip:HookScript("OnTooltipSetItem", addTooltipCount)
end

GameTooltip:HookScript("OnTooltipCleared", function(tooltip) tooltip.rmbthAddedItemID = nil end)
ItemRefTooltip:HookScript("OnTooltipCleared", function(tooltip) tooltip.rmbthAddedItemID = nil end)
