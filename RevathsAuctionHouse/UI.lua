local _, ns = ...

local PALETTES = {
    midnight = { 0.11, 0.72, 0.78 }, arcane = { 0.67, 0.48, 0.94 },
    emerald = { 0.32, 0.78, 0.55 }, crimson = { 0.91, 0.40, 0.43 },
    royal = { 0.34, 0.60, 0.94 }, graphite = { 0.72, 0.76, 0.82 },
}
local PALETTE_ORDER = { "midnight", "arcane", "emerald", "crimson", "royal", "graphite" }
local FONT_PATHS = {
    friz = STANDARD_TEXT_FONT, frizOutline = STANDARD_TEXT_FONT,
    arial = "Fonts\\ARIALN.TTF", arialOutline = "Fonts\\ARIALN.TTF",
    morpheus = "Fonts\\MORPHEUS.TTF", morpheusOutline = "Fonts\\MORPHEUS.TTF",
    skurri = "Fonts\\SKURRI.TTF", skurriOutline = "Fonts\\SKURRI.TTF",
}
local frame, status, title, subtitle, tabButtons, nativeReturn, nativeBlocker = nil, nil, nil, nil, {}, nil, nil
local panes, activeTab, searchBox, browseRows, shoppingRows, ownedRows, historyRows, sellRows, craftRows = {}, "Browse", nil, {}, {}, {}, {}, {}, {}
local browseOffset, shoppingOffset, ownedOffset, historyOffset, craftOffset = 0, 0, 0, 0, 0
local browseResults, ownedAuctions = {}, {}
local selectedWatch, selectedAuction, selectedHistory, selectedBrowse, selectedSell, selectedMaterial, selectedCraftResult
local usingNative = false
local watchPriceBox, watchDetails, auctionDetails, historyDetails, historyPoints, marketDetails
local browseDetails, browseCheckout, sellDetails, sellQuantity, sellPrice, sellDuration, sellEstimate, craftDetails, craftCheckout
local refreshBrowse, refreshShopping, refreshOwned, refreshHistory, refreshSell, refreshCrafting, applyAppearance
local allText, allPanels = {}, {}

local function Accent()
    return PALETTES[ns.db and ns.db.palette] or PALETTES.midnight
end

local function SafeNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return type(value) == "number" and value or nil
end

local function SetStatus(message)
    if status then status:SetText(message or "") end
end

local function Font(parent, size, muted)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text.baseSize = size or 12
    text.muted = muted
    text:SetFont(STANDARD_TEXT_FONT, text.baseSize, "")
    text:SetTextColor(muted and 0.72 or 0.96, muted and 0.80 or 0.96, muted and 0.86 or 1)
    text:SetJustifyH("LEFT")
    allText[#allText + 1] = text
    return text
end

local function Panel(parent, name)
    local panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
    allPanels[#allPanels + 1] = panel
    return panel
end

local function PaintPanel(panel, strong)
    local classic = ns.db and ns.db.skin == "classic"
    panel:SetBackdrop({
        bgFile = classic and "Interface\\DialogFrame\\UI-DialogBox-Background" or "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = classic and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = classic and 22 or 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    panel:SetBackdropColor(classic and 0.055 or 0.055, classic and 0.040 or 0.066, classic and 0.025 or 0.095, strong and (ns.db.opacity or 0.96) or 0.88)
    local accent = Accent()
    panel:SetBackdropBorderColor(accent[1] * 0.62, accent[2] * 0.62, accent[3] * 0.62, 0.9)
end

local function Button(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    allPanels[#allPanels + 1] = button
    button.label = Font(button, 12)
    button.label:SetPoint("CENTER")
    button.label:SetText(label)
    button:SetScript("OnEnter", function(self)
        local accent = Accent()
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
    end)
    button:SetScript("OnLeave", function(self) PaintPanel(self) end)
    return button
end

local function Edit(parent, width, height)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    box:SetSize(width, height)
    allPanels[#allPanels + 1] = box
    box:SetFont(STANDARD_TEXT_FONT, 13, "")
    box:SetTextColor(1, 1, 1)
    box:SetAutoFocus(false)
    box:SetTextInsets(9, 9, 4, 4)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function ItemName(itemKey, fallback)
    if not itemKey or not itemKey.itemID then return fallback or "Unknown item" end
    local ok, info = pcall(C_AuctionHouse.GetItemKeyInfo, itemKey)
    if ok and info and info.itemName then return info.itemName, info.iconFileID end
    return fallback or ("Item #" .. tostring(itemKey.itemID))
end

local function SelectNativeTab(which)
    local auctionFrame = AuctionHouseFrame
    if not auctionFrame or not auctionFrame:IsShown() then SetStatus("Visit an auctioneer first."); return end
    local tab = which == "Sell" and auctionFrame.SellTab or which == "Auctions" and auctionFrame.AuctionsTab or auctionFrame.BuyTab
    if tab and tab.Click then tab:Click()
    elseif auctionFrame.SetDisplayMode and AuctionHouseFrameDisplayMode then
        local mode = which == "Sell" and AuctionHouseFrameDisplayMode.ItemSell or which == "Auctions" and AuctionHouseFrameDisplayMode.Auctions or AuctionHouseFrameDisplayMode.Buy
        if mode then auctionFrame:SetDisplayMode(mode) end
    end
end

local function ShowNative(which)
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return end
    usingNative = true
    if frame then frame:Hide() end
    if nativeBlocker then nativeBlocker:Hide() end
    AuctionHouseFrame:SetAlpha(1)
    if nativeReturn then
        nativeReturn:ClearAllPoints()
        nativeReturn:SetPoint("TOP", AuctionHouseFrame, "TOP", 0, 19)
        nativeReturn:Show()
    end
    if which then SelectNativeTab(which) end
end

local function Search(term)
    term = strtrim(term or "")
    if term == "" then SetStatus("Type an item name to search."); return end
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then SetStatus("Visit an auctioneer first."); return end
    if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then
        SetStatus("Auction House is busy. Try again in a moment."); return
    end
    ns:RememberSearch(term)
    if searchBox then searchBox:SetText(term); searchBox:ClearFocus() end
    browseOffset = 0
    browseResults = {}
    selectedBrowse = nil
    if browseCheckout then browseCheckout:SetEnabled(false) end
    if browseDetails then browseDetails:SetText("Searching for " .. term .. "...") end
    if refreshBrowse then refreshBrowse() end
    SetStatus("Searching for " .. term .. "...")
    local categories = AuctionHouseFrame.GetCategoriesList and AuctionHouseFrame:GetCategoriesList()
    if categories and categories.SetSelectedCategory then categories:SetSelectedCategory(nil) end
    local ok = pcall(AuctionHouseFrame.SendBrowseQuery, AuctionHouseFrame, term, nil, nil, {})
    if not ok then SetStatus("Search unavailable. Try the Blizzard Buy tab.") end
end

local function PageRows(parent, top, count, rowHeight)
    local rows = {}
    for index = 1, count do
        local row = Button(parent, "", 534, rowHeight - 3)
        row:SetPoint("TOPLEFT", 14, top - (index - 1) * rowHeight)
        row.label:Hide()
        row.name = Font(row, 13)
        row.name:SetPoint("LEFT", 10, 0)
        row.name:SetWidth(254)
        row.meta = Font(row, 11, true)
        row.meta:SetPoint("RIGHT", -10, 0)
        row.meta:SetWidth(238)
        row.meta:SetJustifyH("RIGHT")
        rows[index] = row
    end
    return rows
end

local function SelectTab(name)
    activeTab = name
    for key, pane in pairs(panes) do pane:SetShown(key == name) end
    for key, button in pairs(tabButtons) do
        button.label:SetTextColor(key == name and 0.36 or 0.91, key == name and 0.92 or 0.94, key == name and 1 or 1)
    end
    if name == "Browse" then refreshBrowse()
    elseif name == "Sell" then refreshSell(true)
    elseif name == "Crafting" then refreshCrafting()
    elseif name == "Shopping" then refreshShopping()
    elseif name == "Auctions" then
        if C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions then pcall(C_AuctionHouse.QueryOwnedAuctions, {}) end
        refreshOwned()
    elseif name == "Prices" then refreshHistory() end
end

local function BuildBrowse()
    local pane = panes.Browse
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Find an auction")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43); hint:SetText("Search current listings. Select a result to buy through Blizzard's confirmation screen.")
    searchBox = Edit(pane, 365, 32); searchBox:SetPoint("TOPLEFT", 18, -68)
    searchBox:SetScript("OnEnterPressed", function(self) Search(self:GetText()) end)
    local searchButton = Button(pane, "Search", 86, 32); searchButton:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)
    searchButton:SetScript("OnClick", function() Search(searchBox:GetText()) end)
    local previous = Button(pane, "History", 75, 32); previous:SetPoint("LEFT", searchButton, "RIGHT", 6, 0)
    previous:SetScript("OnClick", function()
        local history = ns.db.searches
        if #history == 0 then SetStatus("No recent searches yet."); return end
        local current = searchBox:GetText() or ""
        local index = 1
        for i, term in ipairs(history) do if term == current then index = i % #history + 1; break end end
        searchBox:SetText(history[index]); Search(history[index])
    end)
    local caption = Font(pane, 11, true); caption:SetPoint("TOPLEFT", 18, -110)
    caption:SetText("ITEM                                                QUANTITY             LOWEST PRICE")
    browseRows = PageRows(pane, -135, 8, 35)
    for _, row in ipairs(browseRows) do
        row:SetScript("OnClick", function(self, mouseButton)
            local result = self.result
            if not result or not AuctionHouseFrame then return end
            if mouseButton == "RightButton" then
                if result.itemKey then
                    ns:WatchItem(result.itemKey.itemID, self.itemName)
                    SetStatus("Added " .. (self.itemName or "item") .. " to Shopping.")
                end
                return
            end
            selectedBrowse = result
            if browseDetails then
                browseDetails:SetText((self.itemName or "Item") .. "\n\nAvailable: " .. tostring(result.totalQuantity or 0)
                    .. "\nLowest: " .. ns:Money(SafeNumber(result.minPrice))
                    .. "\n\nCheckout uses Blizzard's secure buy screen. Return to Revath's window afterward.")
            end
            if browseCheckout then browseCheckout:SetEnabled(true) end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
    local instruction = Font(pane, 11, true); instruction:SetPoint("BOTTOMLEFT", 18, 51)
    instruction:SetText("Click to inspect · Right-click to add to Shopping")
    local native = Button(pane, "Blizzard Buy", 125, 30); native:SetPoint("BOTTOMLEFT", 18, 13)
    native:SetScript("OnClick", function() ShowNative("Buy") end)
    local sell = Button(pane, "Sell an item", 125, 30); sell:SetPoint("LEFT", native, "RIGHT", 8, 0)
    sell:SetScript("OnClick", function() SelectTab("Sell") end)
    local prev = Button(pane, "Previous", 84, 30); prev:SetPoint("BOTTOMRIGHT", -108, 13)
    local nextButton = Button(pane, "Next", 84, 30); nextButton:SetPoint("BOTTOMRIGHT", -16, 13)
    prev:SetScript("OnClick", function() browseOffset = math.max(0, browseOffset - #browseRows); refreshBrowse() end)
    nextButton:SetScript("OnClick", function() browseOffset = math.min(math.max(0, #browseResults - #browseRows), browseOffset + #browseRows); refreshBrowse() end)
    pane:EnableMouseWheel(true)
    pane:SetScript("OnMouseWheel", function(_, delta)
        browseOffset = math.max(0, math.min(math.max(0, #browseResults - #browseRows), browseOffset - delta * 3))
        refreshBrowse()
    end)
    local detailsPanel = Panel(pane); detailsPanel:SetPoint("TOPLEFT", 570, -16); detailsPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    browseDetails = Font(detailsPanel, 14); browseDetails:SetPoint("TOPLEFT", 17, -20); browseDetails:SetPoint("RIGHT", -16, 0)
    browseDetails:SetJustifyV("TOP"); browseDetails:SetText("Select a result for its price and purchase options.")
    browseCheckout = Button(detailsPanel, "Open secure checkout", 250, 34)
    browseCheckout:SetPoint("BOTTOMLEFT", 17, 18); browseCheckout:SetEnabled(false)
    browseCheckout:SetScript("OnClick", function()
        if not selectedBrowse then return end
        local ok = pcall(AuctionHouseFrame.SelectBrowseResult, AuctionHouseFrame, selectedBrowse)
        if ok then ShowNative() else SetStatus("This listing is no longer available. Search again.") end
    end)
end

refreshBrowse = function()
    if not panes.Browse or not panes.Browse:IsShown() then return end
    for index, row in ipairs(browseRows) do
        local result = browseResults[browseOffset + index]
        row.result = result
        row:SetShown(result ~= nil)
        if result then
            local name = ItemName(result.itemKey)
            row.itemName = name
            row.name:SetText(name)
            row.meta:SetText(string.format("%s   ·   %s", tostring(result.totalQuantity or 0), ns:Money(SafeNumber(result.minPrice))))
        end
    end
end

local sellItems, sellQueue = {}, {}
local pendingPriceQuery, pendingQueueItem
local queuePriceReady = false
local UpdateSellEstimate
local function SelectSellItem(record)
    selectedSell = record
    if not record then return end
    local marked = ns.db.craftSelections[tostring(record.itemID)]
    sellDetails:SetText(record.name .. "\nAvailable in stack: " .. record.quantity
        .. (record.boe and "\nBind on equip" or "") .. (marked and "\nMarked for crafted-item queue" or ""))
    sellQuantity:SetText(tostring(record.quantity))
    local price = ns.db.prices[tostring(record.itemID)]
    sellPrice:SetText(price and price.last and string.format("%.4f", price.last / 10000) or "")
    UpdateSellEstimate()
end
local function QueueItems(predicate)
    local existing = {}
    for _, item in ipairs(sellQueue) do existing[item.bag .. ":" .. item.slot] = true end
    local added = 0
    for _, item in ipairs(sellItems) do
        local key = item.bag .. ":" .. item.slot
        if predicate(item) and not existing[key] then
            sellQueue[#sellQueue + 1] = item
            existing[key] = true; added = added + 1
        end
    end
    SetStatus(string.format("Added %d stacks; %d waiting for review. Prices are checked live, one at a time.", added, #sellQueue))
    queuePriceReady = false
    if sellQueue[1] then SelectSellItem(sellQueue[1]) end
end
local function PriceQueueHead()
    local item = sellQueue[1]
    if not item then SetStatus("The sell queue is empty."); return end
    SelectSellItem(item)
    queuePriceReady = false
    if C_Container.GetContainerItemID(item.bag, item.slot) ~= item.itemID then
        SetStatus("That stack moved. Rescan and rebuild the sell queue."); return
    end
    local ok, valid = pcall(C_AuctionHouse.IsSellItemValid, item.location, false)
    if not ok or not valid then SetStatus("The first queued stack is no longer auctionable. Rescan your bags."); return end
    local keyOk, itemKey = pcall(C_AuctionHouse.GetItemKeyFromItem, item.location)
    if not keyOk or not itemKey then SetStatus("Could not identify this item for a live price search."); return end
    local infoOk, keyInfo = pcall(C_AuctionHouse.GetItemKeyInfo, itemKey)
    local commodity = infoOk and keyInfo and keyInfo.isCommodity
    if not AuctionHouseFrame or not AuctionHouseFrame.QueryItem then
        SetStatus("Live pricing is unavailable; check the price in Blizzard's Sell view."); return
    end
    local context = commodity and AuctionHouseSearchContext.SellCommodities or AuctionHouseSearchContext.SellItems
    local sent = pcall(AuctionHouseFrame.QueryItem, AuctionHouseFrame, context, itemKey)
    if not sent then SetStatus("Could not start a live price search. Try again in a moment."); return end
    pendingPriceQuery = { itemID = item.itemID, key = itemKey, commodity = commodity, bag = item.bag, slot = item.slot }
    SetStatus("Checking the lowest current listing for " .. item.name .. "…")
end
UpdateSellEstimate = function()
    if not sellEstimate then return end
    if not selectedSell then sellEstimate:SetText("Select an item to see its estimated deposit."); return end
    local quantity = tonumber(sellQuantity:GetText())
    local gold = tonumber(sellPrice:GetText())
    if not quantity or quantity < 1 or not gold or gold <= 0 then
        sellEstimate:SetText("Enter a quantity and price to estimate the deposit."); return
    end
    local copper = math.floor(gold * 10000 + 0.5)
    local ok, commodityStatus = pcall(C_AuctionHouse.GetItemCommodityStatus, selectedSell.location)
    local isCommodity = ok and commodityStatus == Enum.ItemCommodityStatus.Commodity
    local depositOk, deposit
    if isCommodity then
        depositOk, deposit = pcall(C_AuctionHouse.CalculateCommodityDeposit, selectedSell.itemID, sellDuration, quantity)
    else
        depositOk, deposit = pcall(C_AuctionHouse.CalculateItemDeposit, selectedSell.location, sellDuration, quantity)
    end
    sellEstimate:SetText("Gross: " .. ns:Money(quantity * copper)
        .. "\nDeposit: " .. (depositOk and ns:Money(SafeNumber(deposit)) or "Unavailable"))
end

local function ScanSellItems()
    sellItems = {}
    if not C_Container or not C_AuctionHouse or not ItemLocation then return end
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
                local ok, valid = pcall(C_AuctionHouse.IsSellItemValid, location, false)
                if ok and valid then
                    sellItems[#sellItems + 1] = { location = location, itemID = info.itemID,
                        name = info.itemName or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(info.itemID)) or ("Item #" .. info.itemID),
                        quantity = info.stackCount or 1, bag = bag, slot = slot,
                        boe = not info.isBound and (function()
                            local loaded, bindType = pcall(function()
                                return select(14, C_Item.GetItemInfo(info.hyperlink or info.itemID))
                            end)
                            return loaded and bindType == (Enum.ItemBind and Enum.ItemBind.OnEquip or 2)
                        end)() }
                end
            end
        end
    end
end

local function BuildSell()
    local pane = panes.Sell
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Sell from your bags")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43)
    hint:SetText("Queue BoE stacks or right-click to mark crafted items. Review and confirm each posting.")
    sellRows = PageRows(pane, -74, 9, 39)
    for _, row in ipairs(sellRows) do
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(self, button)
            if not self.record then return end
            if button == "RightButton" then
                local key = tostring(self.record.itemID)
                ns.db.craftSelections[key] = not ns.db.craftSelections[key] or nil
                SetStatus(ns.db.craftSelections[key] and "Marked for crafted-item queue." or "Removed crafted-item mark.")
                refreshSell()
            end
            SelectSellItem(self.record)
        end)
    end
    local detailsPanel = Panel(pane); detailsPanel:SetPoint("TOPLEFT", 570, -16); detailsPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    sellDetails = Font(detailsPanel, 14); sellDetails:SetPoint("TOPLEFT", 17, -20); sellDetails:SetPoint("RIGHT", -15, 0)
    sellDetails:SetText("Choose an item from your bags.\n\nA remembered price is a local observation, not a recommended sale price.")
    local quantityLabel = Font(detailsPanel, 11, true); quantityLabel:SetPoint("TOPLEFT", 17, -115); quantityLabel:SetText("QUANTITY")
    sellQuantity = Edit(detailsPanel, 125, 31); sellQuantity:SetPoint("TOPLEFT", 17, -135)
    sellQuantity:SetScript("OnTextChanged", UpdateSellEstimate)
    local priceLabel = Font(detailsPanel, 11, true); priceLabel:SetPoint("TOPLEFT", 17, -184); priceLabel:SetText("BUYOUT PRICE (GOLD)")
    sellPrice = Edit(detailsPanel, 156, 31); sellPrice:SetPoint("TOPLEFT", 17, -204)
    sellPrice:SetScript("OnTextChanged", UpdateSellEstimate)
    local priceHint = Font(detailsPanel, 11, true); priceHint:SetPoint("TOPLEFT", 17, -247)
    priceHint:SetText("Price per item. Confirm the final deposit before posting.")
    local durationLabel = Font(detailsPanel, 11, true); durationLabel:SetPoint("TOPLEFT", 17, -284); durationLabel:SetText("DURATION")
    sellDuration = 2
    local durationButton = Button(detailsPanel, "24 hours", 156, 31); durationButton:SetPoint("TOPLEFT", 17, -305)
    durationButton:SetScript("OnClick", function()
        sellDuration = sellDuration % 3 + 1
        durationButton.label:SetText(({ "12 hours", "24 hours", "48 hours" })[sellDuration])
        UpdateSellEstimate()
    end)
    sellEstimate = Font(detailsPanel, 12, true); sellEstimate:SetPoint("TOPLEFT", 17, -356)
    sellEstimate:SetWidth(310); sellEstimate:SetText("Select an item to see its estimated deposit.")
    local post = Button(detailsPanel, "Review & post", 250, 35); post:SetPoint("BOTTOMLEFT", 17, 61)
    post:SetScript("OnClick", function()
        if not selectedSell then SetStatus("Choose an item first."); return end
        if sellQueue[1] and sellQueue[1].bag == selectedSell.bag and sellQueue[1].slot == selectedSell.slot
            and not queuePriceReady then
            SetStatus("Use Price next to check the lowest current listing before reviewing this queued auction.")
            return
        end
        local quantity = tonumber(sellQuantity:GetText())
        local gold = tonumber(sellPrice:GetText())
        if not quantity or quantity < 1 or quantity > selectedSell.quantity or quantity ~= math.floor(quantity) then
            SetStatus("Enter a valid quantity from this stack."); return
        end
        if not gold or gold <= 0 then SetStatus("Enter a buyout price in gold."); return end
        local copper = math.floor(gold * 10000 + 0.5)
        if copper < 1 then SetStatus("Price must be at least one copper."); return end
        local location = selectedSell.location
        if C_Container.GetContainerItemID(selectedSell.bag, selectedSell.slot) ~= selectedSell.itemID then
            SetStatus("That stack moved. Rescan your bags before posting."); return
        end
        local ok, valid = pcall(C_AuctionHouse.IsSellItemValid, location, false)
        if not ok or not valid then SetStatus("This item cannot be posted now."); return end
        ShowNative("Sell")
        local prepared, accepted = pcall(AuctionHouseFrame.SetPostItem, AuctionHouseFrame, location)
        if not prepared or accepted == false then SetStatus("Could not prepare this item in Blizzard's Sell view."); return end
        local displayMode = AuctionHouseFrame:GetDisplayMode()
        local sellFrame = displayMode == AuctionHouseFrameDisplayMode.CommoditiesSell and AuctionHouseFrame.CommoditiesSellFrame
            or displayMode == AuctionHouseFrameDisplayMode.ItemSell and AuctionHouseFrame.ItemSellFrame
        if not sellFrame or not sellFrame.GetItem or not sellFrame:GetItem() then
            SetStatus("Complete this special item in Blizzard's Sell view."); return
        end
        if sellFrame.QuantityInput then sellFrame.QuantityInput:SetQuantity(quantity) end
        if sellFrame.PriceInput then sellFrame.PriceInput:SetAmount(copper) end
        if sellFrame.Duration then sellFrame.Duration:SetDuration(sellDuration) end
        if sellFrame.UpdatePostState then sellFrame:UpdatePostState() end
        if sellQueue[1] and sellQueue[1].bag == selectedSell.bag and sellQueue[1].slot == selectedSell.slot then
            pendingQueueItem = { bag = selectedSell.bag, slot = selectedSell.slot }
        end
        SetStatus("Review the deposit and confirm posting in Blizzard's Sell view.")
    end)
    local native = Button(detailsPanel, "Use Blizzard Sell", 250, 33); native:SetPoint("BOTTOMLEFT", 17, 17)
    native:SetScript("OnClick", function() ShowNative("Sell") end)
    local queueBoe = Button(pane, "Queue BoE", 104, 28); queueBoe:SetPoint("BOTTOMLEFT", 18, 13)
    queueBoe:SetScript("OnClick", function() ScanSellItems(); QueueItems(function(item) return item.boe end); refreshSell() end)
    local queueMarked = Button(pane, "Queue marked", 113, 28); queueMarked:SetPoint("LEFT", queueBoe, "RIGHT", 6, 0)
    queueMarked:SetScript("OnClick", function() ScanSellItems(); QueueItems(function(item) return ns.db.craftSelections[tostring(item.itemID)] end); refreshSell() end)
    local priceNext = Button(pane, "Price next", 96, 28); priceNext:SetPoint("LEFT", queueMarked, "RIGHT", 6, 0)
    priceNext:SetScript("OnClick", PriceQueueHead)
    local prev = Button(pane, "‹", 52, 28); prev:SetPoint("LEFT", priceNext, "RIGHT", 6, 0)
    local nextButton = Button(pane, "›", 52, 28); nextButton:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    prev:SetScript("OnClick", function() pane.sellOffset = math.max(0, (pane.sellOffset or 0) - #sellRows); refreshSell() end)
    nextButton:SetScript("OnClick", function() pane.sellOffset = (pane.sellOffset or 0) + #sellRows; refreshSell() end)
    pane:EnableMouseWheel(true)
    pane:SetScript("OnMouseWheel", function(_, delta)
        pane.sellOffset = math.max(0, math.min(math.max(0, #sellItems - #sellRows), (pane.sellOffset or 0) - delta * 3))
        refreshSell()
    end)
end

refreshSell = function(rescan)
    if not panes.Sell or not panes.Sell:IsShown() then return end
    if rescan then ScanSellItems() end
    local pane = panes.Sell
    pane.sellOffset = math.min(pane.sellOffset or 0, math.max(0, #sellItems - #sellRows))
    for index, row in ipairs(sellRows) do
        local record = sellItems[pane.sellOffset + index]
        row.record = record; row:SetShown(record ~= nil)
        if record then
            row.name:SetText(record.name)
            row.meta:SetText("x" .. record.quantity .. (record.boe and " · BoE" or "")
                .. (ns.db.craftSelections[tostring(record.itemID)] and " · MARKED" or ""))
        end
    end
end

local trackedMaterials, trackedRecipeCount = {}, 0
local function ShowMaterial(material)
    selectedMaterial, selectedCraftResult = material, nil
    if craftCheckout then craftCheckout:SetEnabled(false) end
    if not material then
        craftDetails:SetText("Select a material from a tracked recipe.")
        return
    end
    local price = (ns.db.prices[tostring(material.itemID)] or {}).last
    craftDetails:SetText(material.recipeName .. "\n\n" .. material.name
        .. "\nRequired: " .. tostring(material.required) .. "    Owned: " .. tostring(material.held)
        .. "\nMissing: " .. tostring(material.missing)
        .. "\nLast observed: " .. ns:Money(price)
        .. "\nEstimated missing cost: " .. ns:Money(price and price * material.missing)
        .. (#material.variants > 1 and "\n\nMultiple reagent qualities are available." or ""))
end

local function BuildCrafting()
    local pane = panes.Crafting
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Tracked recipe materials")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43)
    hint:SetText("Recipes tracked in Professions. Review missing materials and search each one here.")
    craftRows = PageRows(pane, -74, 9, 39)
    for _, row in ipairs(craftRows) do
        row:SetScript("OnClick", function(self) ShowMaterial(self.material) end)
    end
    local detailsPanel = Panel(pane); detailsPanel:SetPoint("TOPLEFT", 570, -16); detailsPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    craftDetails = Font(detailsPanel, 14); craftDetails:SetPoint("TOPLEFT", 17, -20); craftDetails:SetWidth(310)
    craftDetails:SetJustifyV("TOP"); craftDetails:SetText("Select a material from a tracked recipe.")
    local quality = Button(detailsPanel, "Change reagent quality", 250, 32); quality:SetPoint("TOPLEFT", 17, -252)
    quality:SetScript("OnClick", function()
        if not selectedMaterial or #selectedMaterial.variants <= 1 then return end
        local slotKey = selectedMaterial.slotKey
        ns:CycleReagentVariant(selectedMaterial)
        refreshCrafting()
        for _, material in ipairs(trackedMaterials) do
            if material.slotKey == slotKey then ShowMaterial(material); break end
        end
    end)
    local find = Button(detailsPanel, "Search material", 250, 34); find:SetPoint("TOPLEFT", 17, -302)
    find:SetScript("OnClick", function()
        if not selectedMaterial then return end
        selectedCraftResult = nil
        craftCheckout:SetEnabled(false)
        Search(selectedMaterial.name)
        SetStatus("Finding listings for " .. selectedMaterial.name .. "...")
    end)
    craftCheckout = Button(detailsPanel, "Open secure checkout", 250, 34)
    craftCheckout:SetPoint("TOPLEFT", 17, -347); craftCheckout:SetEnabled(false)
    craftCheckout:SetScript("OnClick", function()
        if not selectedCraftResult then return end
        local ok = pcall(AuctionHouseFrame.SelectBrowseResult, AuctionHouseFrame, selectedCraftResult)
        if ok then ShowNative() else SetStatus("That listing is unavailable. Search again.") end
    end)
    local refresh = Button(pane, "Refresh recipes", 124, 28); refresh:SetPoint("BOTTOMLEFT", 18, 13)
    refresh:SetScript("OnClick", function() refreshCrafting() end)
    local prev = Button(pane, "Previous", 84, 28); prev:SetPoint("LEFT", refresh, "RIGHT", 7, 0)
    local nextButton = Button(pane, "Next", 84, 28); nextButton:SetPoint("LEFT", prev, "RIGHT", 7, 0)
    prev:SetScript("OnClick", function() craftOffset = math.max(0, craftOffset - #craftRows); refreshCrafting() end)
    nextButton:SetScript("OnClick", function() craftOffset = craftOffset + #craftRows; refreshCrafting() end)
end

refreshCrafting = function()
    if not panes.Crafting or not panes.Crafting:IsShown() then return end
    trackedMaterials, trackedRecipeCount = ns:GetTrackedMaterials()
    craftOffset = math.min(craftOffset, math.max(0, #trackedMaterials - #craftRows))
    for index, row in ipairs(craftRows) do
        local material = trackedMaterials[craftOffset + index]
        row.material = material; row:SetShown(material ~= nil)
        if material then
            row.name:SetText(material.name)
            row.meta:SetText(string.format("Need %d · Own %d", material.required, material.held))
        end
    end
    if trackedRecipeCount == 0 then
        craftDetails:SetText("No tracked recipes found. Track a recipe in the Professions window, then click Refresh recipes.")
    elseif #trackedMaterials == 0 then
        craftDetails:SetText("Tracked recipes have no basic item reagents available to list.")
    end
end

local function SortedWatch()
    local list = {}
    for _, item in pairs(ns.db.shopping) do list[#list + 1] = item end
    table.sort(list, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)
    return list
end

local function BuildShopping()
    local pane = panes.Shopping
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Shopping list")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43)
    hint:SetText("Keep account-wide items and target prices. Right-click a Browse result to add it.")
    shoppingRows = PageRows(pane, -74, 9, 39)
    for _, row in ipairs(shoppingRows) do
        row:SetScript("OnClick", function(self)
            selectedWatch = self.record
            if selectedWatch then
                watchPriceBox:SetText(selectedWatch.maxPrice and selectedWatch.maxPrice > 0 and tostring(selectedWatch.maxPrice / 10000) or "")
                watchDetails:SetText((selectedWatch.name or "Item") .. "\n\nLast seen: " .. ns:Money((ns.db.prices[tostring(selectedWatch.itemID)] or {}).last))
            end
        end)
    end
    local detailsPanel = Panel(pane); detailsPanel:SetPoint("TOPLEFT", 570, -16); detailsPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    watchDetails = Font(detailsPanel, 14); watchDetails:SetPoint("TOPLEFT", 17, -20); watchDetails:SetWidth(310)
    watchDetails:SetText("Select an item to set a maximum price.")
    local maxLabel = Font(detailsPanel, 11, true); maxLabel:SetPoint("TOPLEFT", 17, -135); maxLabel:SetText("MAX PRICE (GOLD)")
    watchPriceBox = Edit(detailsPanel, 156, 30); watchPriceBox:SetPoint("TOPLEFT", 17, -157)
    watchPriceBox:SetNumeric(false)
    local save = Button(detailsPanel, "Save limit", 143, 30); save:SetPoint("TOPLEFT", 17, -209)
    save:SetScript("OnClick", function()
        if not selectedWatch then return end
        local gold = tonumber(watchPriceBox:GetText())
        if not gold or gold < 0 then SetStatus("Enter a valid maximum gold price."); return end
        selectedWatch.maxPrice = math.floor(gold * 10000 + 0.5)
        refreshShopping(); SetStatus("Shopping price limit saved.")
    end)
    local find = Button(detailsPanel, "Search item", 143, 30); find:SetPoint("LEFT", save, "RIGHT", 7, 0)
    find:SetScript("OnClick", function() if selectedWatch then SelectTab("Browse"); Search(selectedWatch.name) end end)
    local remove = Button(detailsPanel, "Remove from list", 293, 30); remove:SetPoint("TOPLEFT", 17, -249)
    remove:SetScript("OnClick", function()
        if not selectedWatch then return end
        ns.db.shopping[tostring(selectedWatch.itemID)] = nil
        selectedWatch = nil; watchDetails:SetText("Select an item to set a maximum price.")
        refreshShopping()
    end)
    local prev = Button(pane, "Previous", 84, 28); prev:SetPoint("BOTTOMLEFT", 18, 13)
    local nextButton = Button(pane, "Next", 84, 28); nextButton:SetPoint("LEFT", prev, "RIGHT", 7, 0)
    prev:SetScript("OnClick", function() shoppingOffset = math.max(0, shoppingOffset - #shoppingRows); refreshShopping() end)
    nextButton:SetScript("OnClick", function() shoppingOffset = shoppingOffset + #shoppingRows; refreshShopping() end)
end

refreshShopping = function()
    if not panes.Shopping or not panes.Shopping:IsShown() then return end
    local list = SortedWatch()
    shoppingOffset = math.min(shoppingOffset, math.max(0, #list - #shoppingRows))
    for index, row in ipairs(shoppingRows) do
        local record = list[shoppingOffset + index]
        row.record = record; row:SetShown(record ~= nil)
        if record then
            local latest = (ns.db.prices[tostring(record.itemID)] or {}).last
            local deal = latest and record.maxPrice and record.maxPrice > 0 and latest <= record.maxPrice
            row.name:SetText((deal and "[PRICE OK] " or "") .. (record.name or "Unknown item"))
            row.meta:SetText(ns:Money(latest) .. (record.maxPrice and record.maxPrice > 0 and ("  /  " .. ns:Money(record.maxPrice)) or ""))
        end
    end
end

local function BuildOwned()
    local pane = panes.Auctions
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Your auctions")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43)
    hint:SetText("Review active listings. Select one before checking or cancelling it.")
    ownedRows = PageRows(pane, -74, 9, 39)
    for _, row in ipairs(ownedRows) do
        row:SetScript("OnClick", function(self)
            selectedAuction = self.auction
            if selectedAuction then
                local name = ItemName(selectedAuction.itemKey)
                auctionDetails:SetText(name .. "\n\nQuantity: " .. tostring(selectedAuction.quantity or 1)
                    .. "\nBuyout: " .. ns:Money(SafeNumber(selectedAuction.buyoutAmount)))
            end
        end)
    end
    local detailsPanel = Panel(pane); detailsPanel:SetPoint("TOPLEFT", 570, -16); detailsPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    auctionDetails = Font(detailsPanel, 14); auctionDetails:SetPoint("TOPLEFT", 17, -20); auctionDetails:SetWidth(310)
    auctionDetails:SetText("Select an auction to inspect it.")
    local refresh = Button(detailsPanel, "Refresh", 143, 30); refresh:SetPoint("TOPLEFT", 17, -162)
    refresh:SetScript("OnClick", function()
        if C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions then pcall(C_AuctionHouse.QueryOwnedAuctions, {}) end
        refreshOwned()
    end)
    local check = Button(detailsPanel, "Check market", 143, 30); check:SetPoint("LEFT", refresh, "RIGHT", 7, 0)
    check:SetScript("OnClick", function()
        if not selectedAuction then return end
        local name = ItemName(selectedAuction.itemKey)
        SelectTab("Browse"); Search(name)
        SetStatus("Compare the lowest market price with your listing before cancelling.")
    end)
    local cancel = Button(detailsPanel, "Cancel selected", 143, 30); cancel:SetPoint("TOPLEFT", 17, -203)
    cancel:SetScript("OnClick", function()
        if not selectedAuction or not selectedAuction.auctionID then return end
        local ok, canCancel = pcall(C_AuctionHouse.CanCancelAuction, selectedAuction.auctionID)
        if not ok or not canCancel then
            SetStatus("This auction cannot be cancelled now."); return
        end
        local costOk, cost = pcall(C_AuctionHouse.GetCancelCost, selectedAuction.auctionID)
        StaticPopup_Show("REVATHS_AUCTION_CANCEL", costOk and ns:Money(SafeNumber(cost)) or "unknown", nil, selectedAuction.auctionID)
    end)
    local native = Button(detailsPanel, "Blizzard Auctions", 143, 30); native:SetPoint("LEFT", cancel, "RIGHT", 7, 0)
    native:SetScript("OnClick", function() ShowNative("Auctions") end)
    local prev = Button(pane, "Previous", 84, 28); prev:SetPoint("BOTTOMLEFT", 18, 13)
    local nextButton = Button(pane, "Next", 84, 28); nextButton:SetPoint("LEFT", prev, "RIGHT", 7, 0)
    prev:SetScript("OnClick", function() ownedOffset = math.max(0, ownedOffset - #ownedRows); refreshOwned() end)
    nextButton:SetScript("OnClick", function() ownedOffset = ownedOffset + #ownedRows; refreshOwned() end)
end

refreshOwned = function()
    if not panes.Auctions or not panes.Auctions:IsShown() or not C_AuctionHouse then return end
    local ok, list = pcall(C_AuctionHouse.GetOwnedAuctions)
    ownedAuctions = ok and type(list) == "table" and list or {}
    ownedOffset = math.min(ownedOffset, math.max(0, #ownedAuctions - #ownedRows))
    for index, row in ipairs(ownedRows) do
        local auction = ownedAuctions[ownedOffset + index]
        row.auction = auction; row:SetShown(auction ~= nil)
        if auction then
            row.name:SetText(ItemName(auction.itemKey))
            row.meta:SetText("x" .. tostring(auction.quantity or 1) .. "  ·  " .. ns:Money(SafeNumber(auction.buyoutAmount)))
        end
    end
end

local function SortedPrices()
    local list = {}
    for id, record in pairs(ns.db.prices) do list[#list + 1] = { id = id, record = record } end
    table.sort(list, function(a, b) return (a.record.updated or 0) > (b.record.updated or 0) end)
    return list
end

local function BuildHistory()
    local pane = panes.Prices
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Price history")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43)
    hint:SetText("Local observations from your searches. Prices are per item and never fetched in the background.")
    historyRows = PageRows(pane, -74, 9, 39)
    for _, row in ipairs(historyRows) do
        row:SetScript("OnClick", function(self)
            selectedHistory = self.entry
            if not selectedHistory then return end
            local record = selectedHistory.record
            historyDetails:SetText((record.name or "Item") .. "  ·  last seen " .. ns:Money(record.last))
            local lines = {}
            for i = #record.points, math.max(1, #record.points - 5), -1 do
                local point = record.points[i]
                lines[#lines + 1] = point.day .. "   " .. ns:Money(point.price)
            end
            historyPoints:SetText(table.concat(lines, "\n"))
        end)
    end
    local detailsPanel = Panel(pane); detailsPanel:SetPoint("TOPLEFT", 570, -16); detailsPanel:SetPoint("BOTTOMRIGHT", -16, 16)
    historyDetails = Font(detailsPanel, 14); historyDetails:SetPoint("TOPLEFT", 17, -20); historyDetails:SetWidth(310)
    historyDetails:SetText("Select an item to see recent daily observations.")
    historyPoints = Font(detailsPanel, 13, true); historyPoints:SetPoint("TOPLEFT", 17, -115)
    historyPoints:SetWidth(310)
    historyPoints:SetJustifyV("TOP")
    local scanButton = Button(detailsPanel, "Scan full Auction House", 250, 34)
    scanButton:SetPoint("BOTTOMLEFT", 17, 79)
    scanButton:SetScript("OnClick", function() ns:StartMarketScan() end)
    marketDetails = Font(detailsPanel, 11, true)
    marketDetails:SetPoint("BOTTOMLEFT", 17, 20); marketDetails:SetWidth(310)
    marketDetails:SetText("No full scan has been saved yet.")
    local prev = Button(pane, "Previous", 84, 28); prev:SetPoint("BOTTOMLEFT", 18, 13)
    local nextButton = Button(pane, "Next", 84, 28); nextButton:SetPoint("LEFT", prev, "RIGHT", 7, 0)
    prev:SetScript("OnClick", function() historyOffset = math.max(0, historyOffset - #historyRows); refreshHistory() end)
    nextButton:SetScript("OnClick", function() historyOffset = historyOffset + #historyRows; refreshHistory() end)
end

refreshHistory = function()
    if not panes.Prices or not panes.Prices:IsShown() then return end
    local list = SortedPrices()
    historyOffset = math.min(historyOffset, math.max(0, #list - #historyRows))
    for index, row in ipairs(historyRows) do
        local entry = list[historyOffset + index]
        row.entry = entry; row:SetShown(entry ~= nil)
        if entry then
            row.name:SetText(entry.record.name or ("Item #" .. entry.id))
            row.meta:SetText(ns:Money(entry.record.last))
        end
    end
end

local function BuildSettings()
    local pane = panes.Settings
    local heading = Font(pane, 18); heading:SetPoint("TOPLEFT", 18, -16); heading:SetText("Appearance settings")
    local hint = Font(pane, 11, true); hint:SetPoint("TOPLEFT", 18, -43)
    hint:SetText("These controls mirror Blizzard Options > AddOns > Enchanted Frames > Auction House.")
    local skin = Button(pane, "", 230, 35); skin:SetPoint("TOPLEFT", 18, -88)
    skin:SetScript("OnClick", function()
        ns.db.skin = ns.db.skin == "modern" and "classic" or "modern"
        applyAppearance(); ns:RefreshSettings()
    end)
    local palette = Button(pane, "", 230, 35); palette:SetPoint("TOPLEFT", 18, -137)
    palette:SetScript("OnClick", function()
        for i, value in ipairs(PALETTE_ORDER) do
            if value == ns.db.palette then ns.db.palette = PALETTE_ORDER[i % #PALETTE_ORDER + 1]; break end
        end
        applyAppearance(); ns:RefreshSettings()
    end)
    local opacity = Button(pane, "", 230, 35); opacity:SetPoint("TOPLEFT", 18, -186)
    opacity:SetScript("OnClick", function()
        ns.db.opacity = ns.db.opacity >= 1 and 0.60 or math.min(1, ns.db.opacity + 0.05)
        applyAppearance(); ns:RefreshSettings()
    end)
    local scale = Button(pane, "", 230, 35); scale:SetPoint("TOPLEFT", 18, -235)
    scale:SetScript("OnClick", function()
        ns.db.scale = ns.db.scale >= 1.15 and 0.70 or math.min(1.15, ns.db.scale + 0.05)
        applyAppearance(); ns:RefreshSettings()
    end)
    local tooltip = Button(pane, "", 325, 35); tooltip:SetPoint("TOPLEFT", 18, -284)
    tooltip:SetScript("OnClick", function()
        ns.db.showTooltipPrice = not ns.db.showTooltipPrice
        ns:RefreshSettings()
    end)
    local mode = Button(pane, "", 325, 35); mode:SetPoint("TOPLEFT", 18, -333)
    mode:SetScript("OnClick", function()
        ns.db.useReplacement = not ns.db.useReplacement
        ns:RefreshSettings()
        if not ns.db.useReplacement then ShowNative() end
    end)
    local blizzard = Button(pane, "Open Blizzard AddOn settings", 260, 35); blizzard:SetPoint("BOTTOMLEFT", 18, 22)
    blizzard:SetScript("OnClick", function()
        if SlashCmdList.REVATHSENCHANTEDFRAMES then SlashCmdList.REVATHSENCHANTEDFRAMES() end
    end)
    pane.controls = { skin = skin, palette = palette, opacity = opacity, scale = scale, tooltip = tooltip, mode = mode }
end

function ns:RefreshSettings()
    local controls = panes.Settings and panes.Settings.controls
    if not controls then return end
    controls.skin.label:SetText("Skin: " .. (self.db.skin == "classic" and "Classic" or "Modern"))
    controls.palette.label:SetText("Palette: " .. self.db.palette)
    controls.opacity.label:SetText(string.format("Opacity: %d%%", self.db.opacity * 100))
    controls.scale.label:SetText(string.format("Scale: %d%%", self.db.scale * 100))
    controls.tooltip.label:SetText("Price in item tooltips: " .. (self.db.showTooltipPrice and "On" or "Off"))
    controls.mode.label:SetText("Default view: " .. (self.db.useReplacement and "Revath replacement" or "Blizzard"))
    if RevathsEnchantedFrames_RefreshSettings then RevathsEnchantedFrames_RefreshSettings() end
end

applyAppearance = function()
    if not frame or not ns.db then return end
    for _, panel in ipairs(allPanels) do PaintPanel(panel, panel == frame) end
    frame:SetScale(ns.db.scale)
    local accent = Accent()
    title:SetTextColor(accent[1], accent[2], accent[3])
    local fontPath = FONT_PATHS[ns.db.font]
    if not fontPath and ns.db.font:find("^shared:") and LibStub then
        local media = LibStub("LibSharedMedia-3.0", true)
        fontPath = media and media:Fetch("font", ns.db.font:sub(8), true)
    end
    fontPath = fontPath or STANDARD_TEXT_FONT
    local flags = ns.db.font:find("Outline") and "OUTLINE" or ""
    for _, text in ipairs(allText) do
        local ok, loaded = pcall(text.SetFont, text, fontPath, text.baseSize or 12, flags)
        if not ok or loaded == false then text:SetFont(STANDARD_TEXT_FONT, text.baseSize or 12, "") end
    end
    ns:RefreshSettings()
end

local function AddTooltipPrice()
    if not ns.db or not ns.db.showTooltipPrice then return end
    local _, link = GameTooltip:GetItem()
    local id = link and tonumber(link:match("item:(%d+)"))
    local record = id and ns.db.prices[tostring(id)]
    if not record or not record.last then return end
    GameTooltip:AddLine("Enchanted AH: " .. (GetCoinTextureString and GetCoinTextureString(record.last) or ns:Money(record.last)), 0.32, 0.85, 0.9)
    if record.updated then
        GameTooltip:AddLine((record.source or "Observed") .. " · " .. date("%d %b %H:%M", record.updated), 0.70, 0.78, 0.82)
    end
end

function ns:Initialize()
    frame = Panel(UIParent, "RevathsEnchantedAuctionHouseFrame")
    frame:SetSize(960, 670)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(110)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local uiX, uiY = UIParent:GetCenter()
        ns.db.window.x, ns.db.window.y = x - uiX, y - uiY
    end)
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(48, 48); icon:SetPoint("TOPLEFT", 16, -10)
    icon:SetTexture("Interface\\AddOns\\RevathsAuctionHouse\\Media\\IconSmall.png")
    title = Font(frame, 20); title:SetPoint("TOPLEFT", 72, -17); title:SetText("REVATH'S ENCHANTED AUCTION HOUSE")
    subtitle = Font(frame, 10, true); subtitle:SetPoint("TOPLEFT", 73, -43)
    subtitle:SetText("SEARCH, SHOPPING, PRICES & YOUR AUCTIONS")
    local close = Button(frame, "x", 29, 26); close:SetPoint("TOPRIGHT", -14, -15)
    close:SetScript("OnClick", function()
        if AuctionHouseFrame and AuctionHouseFrame:IsShown() then HideUIPanel(AuctionHouseFrame) else frame:Hide() end
    end)
    local blizzard = Button(frame, "Blizzard view", 110, 26); blizzard:SetPoint("RIGHT", close, "LEFT", -8, 0)
    blizzard:SetScript("OnClick", function() ShowNative() end)
    local tabSpecs = {
        { "Browse", "Buy", 15, 140 }, { "Sell", "Sell", 163, 140 },
        { "Auctions", "Auctions", 311, 140 }, { "Crafting", "Crafting", 470, 110 },
        { "Shopping", "Shopping", 588, 110 }, { "Prices", "Prices", 706, 100 },
        { "Settings", "Settings", 814, 120 },
    }
    for _, spec in ipairs(tabSpecs) do
        local name, label, x, width = unpack(spec)
        local tab = Button(frame, label, width, 29)
        tab:SetPoint("TOPLEFT", x, -74)
        tab:SetScript("OnClick", function() SelectTab(name) end)
        tabButtons[name] = tab
        local pane = Panel(frame)
        pane:SetPoint("TOPLEFT", 12, -111); pane:SetPoint("BOTTOMRIGHT", -12, 44)
        panes[name] = pane
    end
    status = Font(frame, 11, true)
    status:SetPoint("BOTTOMLEFT", 20, 15); status:SetPoint("RIGHT", -20, 0)
    status:SetText("Open an auctioneer to search the live market.")
    BuildBrowse(); BuildSell(); BuildOwned(); BuildCrafting(); BuildShopping(); BuildHistory(); BuildSettings()
    StaticPopupDialogs.REVATHS_AUCTION_CANCEL = {
        text = "Cancel this auction? Estimated cost: %s", button1 = YES, button2 = NO,
        OnAccept = function(_, auctionID)
            local ok, canCancel = pcall(C_AuctionHouse.CanCancelAuction, auctionID)
            if auctionID and ok and canCancel then
                C_AuctionHouse.CancelAuction(auctionID)
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    nativeReturn = Button(UIParent, "Return to Revath", 145, 30)
    nativeReturn:SetFrameStrata("DIALOG")
    nativeReturn:SetPoint("TOP", UIParent, "TOP", 0, -100)
    nativeReturn:SetScript("OnClick", function() ns:ShowForAuctionHouse(true) end)
    nativeReturn:Hide()
    nativeBlocker = CreateFrame("Frame", nil, UIParent)
    nativeBlocker:SetFrameStrata("HIGH")
    nativeBlocker:SetFrameLevel(100)
    nativeBlocker:EnableMouse(true)
    nativeBlocker:Hide()
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if tooltip == GameTooltip then AddTooltipPrice() end
        end)
    else
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltipPrice)
    end
    applyAppearance()
    SelectTab("Browse")
    self:RefreshMarket()
    frame:Hide()
end

function ns:ShowForAuctionHouse(forceReplacement)
    if not frame or not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return end
    if not forceReplacement and not self.db.useReplacement then ShowNative(); return end
    usingNative = false
    AuctionHouseFrame:SetAlpha(0)
    if nativeReturn then nativeReturn:Hide() end
    if nativeBlocker then
        nativeBlocker:ClearAllPoints()
        nativeBlocker:SetAllPoints(AuctionHouseFrame)
        nativeBlocker:Show()
    end
    frame:ClearAllPoints()
    if self.db.window.x and self.db.window.y then
        frame:SetPoint("CENTER", UIParent, "CENTER", self.db.window.x, self.db.window.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    frame:Show()
    SelectTab(activeTab)
end

function ns:Hide()
    if frame then frame:Hide() end
    if nativeReturn then nativeReturn:Hide() end
    if nativeBlocker then nativeBlocker:Hide() end
    if AuctionHouseFrame then AuctionHouseFrame:SetAlpha(1) end
    usingNative = false
end

function ns:Toggle()
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
        print("|cff2eb8c7Revath's Enchanted Auction House:|r Visit an auctioneer first.")
        return
    end
    if usingNative then self:ShowForAuctionHouse(true)
    elseif frame:IsShown() then ShowNative()
    else self:ShowForAuctionHouse(true) end
end

function ns:OnBrowseResults()
    if not self.db or not C_AuctionHouse then return end
    local ok, results = pcall(C_AuctionHouse.GetBrowseResults)
    if not ok or type(results) ~= "table" then return end
    browseResults = results
    if activeTab == "Crafting" and selectedMaterial then
        selectedCraftResult = nil
        for _, result in ipairs(results) do
            if result.itemKey and result.itemKey.itemID == selectedMaterial.itemID then
                if not selectedCraftResult or (SafeNumber(result.minPrice) or math.huge) < (SafeNumber(selectedCraftResult.minPrice) or math.huge) then
                    selectedCraftResult = result
                end
            end
        end
        local match = selectedCraftResult
        ShowMaterial(selectedMaterial)
        selectedCraftResult = match
        if match then
            local result = match
            craftDetails:SetText(craftDetails:GetText() .. "\n\nLive lowest: " .. ns:Money(SafeNumber(result.minPrice)))
            craftCheckout:SetEnabled(true)
        else
            craftDetails:SetText(craftDetails:GetText() .. "\n\nNo matching listing found in this search.")
        end
    end
    for i = 1, math.min(#results, 300) do
        local result = results[i]
        local id = result.itemKey and result.itemKey.itemID
        local price = SafeNumber(result.minPrice)
        if id and price then self:RememberPrice(id, ItemName(result.itemKey), price) end
    end
    if refreshBrowse then refreshBrowse() end
    if refreshShopping then refreshShopping() end
    if refreshHistory then refreshHistory() end
    SetStatus(string.format("%d results. Click to inspect, right-click to watch.", #results))
end

function ns:RefreshShopping() if refreshShopping then refreshShopping() end end
function ns:RefreshOwned() if refreshOwned then refreshOwned() end end
function ns:RefreshSell() if refreshSell then refreshSell(true) end end
function ns:OnSellPriceResults(event, loadedKey)
    local query = pendingPriceQuery
    if not query or ((event == "COMMODITY_SEARCH_RESULTS_UPDATED") ~= (query.commodity == true)) then return end
    local loadedID = type(loadedKey) == "table" and loadedKey.itemID or loadedKey
    if loadedID and loadedID ~= query.itemID then return end
    pendingPriceQuery = nil
    local lowest
    if query.commodity then
        local ok, result = pcall(C_AuctionHouse.GetCommoditySearchResultInfo, query.itemID, 1)
        if ok and result then lowest = SafeNumber(result.unitPrice) end
    else
        local ok, count = pcall(C_AuctionHouse.GetNumItemSearchResults, query.key)
        if ok and count then
            for index = 1, math.min(count, 100) do
                local got, result = pcall(C_AuctionHouse.GetItemSearchResultInfo, query.key, index)
                local price = got and result and SafeNumber(result.buyoutAmount)
                if price and price > 0 then lowest = math.min(lowest or price, price) end
            end
        end
    end
    if not lowest then SetStatus("No current buyout found. Enter a price manually or try Blizzard's Sell view."); return end
    self:RememberPrice(query.itemID, selectedSell and selectedSell.name or ("Item #" .. query.itemID), lowest)
    if selectedSell and selectedSell.bag == query.bag and selectedSell.slot == query.slot then
        sellPrice:SetText(string.format("%.4f", lowest / 10000))
        queuePriceReady = true
    end
    SetStatus("Matched the lowest current listing: " .. self:Money(lowest) .. " per item. Review before posting.")
end
function ns:OnAuctionCreated()
    if not pendingQueueItem then return end
    local posted = pendingQueueItem
    pendingQueueItem = nil
    queuePriceReady = false
    if sellQueue[1] and sellQueue[1].bag == posted.bag and sellQueue[1].slot == posted.slot then
        table.remove(sellQueue, 1)
    end
    C_Timer.After(0.1, function()
        if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
            ns:ShowForAuctionHouse(true)
            SelectTab("Sell")
            ScanSellItems(); refreshSell()
            if sellQueue[1] then SelectSellItem(sellQueue[1]) end
            SetStatus(string.format("Auction posted. %d queued stacks remain; price the next one when ready.", #sellQueue))
        end
    end)
end
function ns:RefreshMarket()
    if marketDetails and self.db then
        local snapshot = self.db.marketScan or {}
        if snapshot.at then
            marketDetails:SetText(string.format("Last scan: %s\n%d auctions · %d item values",
                date("%d %b %H:%M", snapshot.at), snapshot.auctions or 0, snapshot.items or 0))
        else
            marketDetails:SetText("No full scan has been saved yet.")
        end
    end
    if refreshHistory then refreshHistory() end
    if refreshShopping then refreshShopping() end
end
function ns:SetStatus(message) SetStatus(message) end
function ns:OnAuctionError(errorID)
    SetStatus("The Auction House declined that action. Check the price, item, or available funds.")
end

function RevathsEnchantedAuctionHouse_ApplySettings()
    if ns.db and applyAppearance then
        applyAppearance()
        if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
            if ns.db.useReplacement and usingNative then ns:ShowForAuctionHouse(true)
            elseif not ns.db.useReplacement and frame and frame:IsShown() then ShowNative() end
        end
    end
end
