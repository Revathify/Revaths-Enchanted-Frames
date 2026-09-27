local addonName, ns = ...

ns.name = addonName
ns.version = _G.RevathsEnchantedFramesVersion
    or (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("RevathsEnchantedFrames", "Version"))
    or "unknown"

local function InitializeDatabase()
    if type(RevathsAuctionHouseDB) ~= "table" then RevathsAuctionHouseDB = {} end
    local db = RevathsAuctionHouseDB
    db.skin = db.skin == "classic" and "classic" or "modern"
    db.palette = type(db.palette) == "string" and db.palette or "midnight"
    db.font = type(db.font) == "string" and db.font or "friz"
    db.opacity = math.max(0.60, math.min(1, tonumber(db.opacity) or 0.96))
    db.scale = math.max(0.70, math.min(1.15, tonumber(db.scale) or 1))
    db.window = type(db.window) == "table" and db.window or {}
    db.searches = type(db.searches) == "table" and db.searches or {}
    db.shopping = type(db.shopping) == "table" and db.shopping or {}
    db.prices = type(db.prices) == "table" and db.prices or {}
    local priceCount = 0
    for _ in pairs(db.prices) do priceCount = priceCount + 1 end
    db.priceCount = priceCount
    db.craftSelections = type(db.craftSelections) == "table" and db.craftSelections or {}
    db.reagentChoices = type(db.reagentChoices) == "table" and db.reagentChoices or {}
    db.marketScan = type(db.marketScan) == "table" and db.marketScan or {}
    if db.showTooltipPrice == nil then db.showTooltipPrice = true end
    if db.showCompanion == nil then db.showCompanion = true end
    ns.db = db
end

function ns:Money(copper)
    copper = tonumber(copper) or 0
    if copper <= 0 then return "—" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local coins = math.floor(copper % 100)
    if gold > 0 then return string.format("%dg %02ds %02dc", gold, silver, coins) end
    if silver > 0 then return string.format("%ds %02dc", silver, coins) end
    return string.format("%dc", coins)
end

function ns:RememberSearch(term)
    term = strtrim(term or "")
    if term == "" then return end
    for index = #self.db.searches, 1, -1 do
        if self.db.searches[index]:lower() == term:lower() then table.remove(self.db.searches, index) end
    end
    table.insert(self.db.searches, 1, term)
    while #self.db.searches > 20 do table.remove(self.db.searches) end
end

function ns:RememberPrice(itemID, name, copper)
    if type(itemID) ~= "number" or type(copper) ~= "number" or copper <= 0 then return end
    local key = tostring(itemID)
    local newRecord = self.db.prices[key] == nil
    local record = self.db.prices[key] or { points = {} }
    record.name = name or record.name or ("Item " .. key)
    record.last = copper
    record.updated = time()
    record.source = "Browse"
    local points = record.points
    local today = date("%Y-%m-%d")
    if points[#points] and points[#points].day == today then
        points[#points].price = copper
    else
        points[#points + 1] = { day = today, price = copper }
        while #points > 30 do table.remove(points, 1) end
    end
    self.db.prices[key] = record
    if newRecord then
        self.db.priceCount = (self.db.priceCount or 0) + 1
        if self.db.priceCount > 22000 then
            local entries = {}
            for id, entry in pairs(self.db.prices) do entries[#entries + 1] = { id = id, updated = entry.updated or 0 } end
            table.sort(entries, function(a, b) return a.updated > b.updated end)
            for i = 20001, #entries do self.db.prices[entries[i].id] = nil end
            self.db.priceCount = math.min(#entries, 20000)
        end
    end
end

function ns:WatchItem(itemID, name)
    if not itemID then return end
    local key = tostring(itemID)
    self.db.shopping[key] = self.db.shopping[key] or { itemID = itemID, name = name or ("Item " .. key), maxPrice = 0 }
    if name then self.db.shopping[key].name = name end
    if self.RefreshShopping then self:RefreshShopping() end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("AUCTION_HOUSE_SHOW")
events:RegisterEvent("AUCTION_HOUSE_CLOSED")
events:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
events:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
events:RegisterEvent("OWNED_AUCTIONS_UPDATED")
events:RegisterEvent("AUCTION_CANCELED")
events:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("AUCTION_HOUSE_SHOW_ERROR")
events:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
events:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
events:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
events:SetScript("OnEvent", function(_, event, loadedName)
    if event == "ADDON_LOADED" then
        if loadedName ~= addonName then return end
        InitializeDatabase()
        if ns.Initialize then ns:Initialize() end
    elseif event == "AUCTION_HOUSE_SHOW" then
        C_Timer.After(0, function()
            if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
                if ns.ShowForAuctionHouse then ns:ShowForAuctionHouse() end
            else
                C_Timer.After(0.1, function()
                    if ns.ShowForAuctionHouse then ns:ShowForAuctionHouse() end
                end)
            end
        end)
    elseif event == "AUCTION_HOUSE_CLOSED" then
        if ns.Hide then ns:Hide() end
    elseif event == "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or event == "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" then
        if ns.OnBrowseResults then ns:OnBrowseResults() end
    elseif event == "OWNED_AUCTIONS_UPDATED" or event == "AUCTION_CANCELED" then
        if ns.RefreshOwned then ns:RefreshOwned() end
    elseif event == "AUCTION_HOUSE_AUCTION_CREATED" then
        if ns.RefreshOwned then ns:RefreshOwned() end
        if ns.RefreshSell then ns:RefreshSell() end
        if ns.OnAuctionCreated then ns:OnAuctionCreated() end
    elseif event == "BAG_UPDATE_DELAYED" then
        if ns.RefreshSell then ns:RefreshSell() end
    elseif event == "AUCTION_HOUSE_SHOW_ERROR" then
        if ns.OnAuctionError then ns:OnAuctionError(loadedName) end
    elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
        if ns.OnReplicateListUpdate then ns:OnReplicateListUpdate() end
    elseif event == "ITEM_SEARCH_RESULTS_UPDATED" or event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
        if ns.OnSellPriceResults then ns:OnSellPriceResults(event, loadedName) end
    end
end)

SLASH_REVATHSAUCTIONHOUSE1 = "/rah"
SLASH_REVATHSAUCTIONHOUSE2 = "/rauction"
SlashCmdList.REVATHSAUCTIONHOUSE = function()
    if ns.Toggle then ns:Toggle() end
end
