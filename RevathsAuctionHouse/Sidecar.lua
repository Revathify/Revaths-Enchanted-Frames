local _, ns = ...

-- A small queue below Blizzard's AH. Blizzard owns posting and checkout.
local companion, statusText, detailText, rangeText, itemBox, quantityBox
local tabs, rows, actions, labels, buttons = {}, {}, {}, {}, {}
local activeTab, entries, offset, selected = "Sell", {}, 0, nil
local queue, pendingPrice, pendingPost = {}, nil, nil
local bulkSelling, refreshRows, selectTab, priceNext = false, nil, nil, nil
local pendingBuy
local bagScan = { scanned = 0, eligible = 0 }

local FONT_PATHS = {
    friz = STANDARD_TEXT_FONT, frizOutline = STANDARD_TEXT_FONT,
    arial = "Fonts\\ARIALN.TTF", arialOutline = "Fonts\\ARIALN.TTF",
    morpheus = "Fonts\\MORPHEUS.TTF", morpheusOutline = "Fonts\\MORPHEUS.TTF",
    skurri = "Fonts\\SKURRI.TTF", skurriOutline = "Fonts\\SKURRI.TTF",
}
local ACCENTS = {
    midnight = { .11, .72, .78 }, arcane = { .67, .48, .94 }, emerald = { .32, .78, .55 },
    crimson = { .91, .40, .43 }, royal = { .34, .60, .94 }, graphite = { .72, .76, .82 },
}

local function PlainNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return type(value) == "number" and value or nil
end

local function Money(copper)
    copper = PlainNumber(copper)
    if not copper or copper <= 0 then return "—" end
    if GetCoinTextureString then return GetCoinTextureString(math.floor(copper)) end
    return ns:Money(copper)
end

local function Text(parent, size, muted)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label.baseSize, label.muted = size, muted
    label:SetJustifyH("LEFT")
    labels[#labels + 1] = label
    return label
end

local function Style(frame)
    local accent = ACCENTS[ns.db.palette] or ACCENTS.midnight
    frame:SetBackdrop({
        bgFile = ns.db.skin == "classic" and "Interface\\DialogFrame\\UI-DialogBox-Background" or "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = ns.db.skin == "classic" and "Interface\\DialogFrame\\UI-DialogBox-Border" or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = ns.db.skin == "classic" and 22 or 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    frame:SetBackdropColor(.055, .065, .09, ns.db.opacity or .96)
    frame:SetBackdropBorderColor(accent[1] * .7, accent[2] * .7, accent[3] * .7, 1)
end

local function Button(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width, height)
    button.label = Text(button, 12)
    button.label:SetPoint("CENTER")
    button.label:SetText(text)
    button:SetScript("OnEnter", function(self)
        local accent = ACCENTS[ns.db.palette] or ACCENTS.midnight
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
    end)
    button:SetScript("OnLeave", Style)
    buttons[#buttons + 1] = button
    return button
end

local function SetStatus(message)
    if statusText then statusText:SetText(message or "") end
end

function ns:SetStatus(message) SetStatus(message) end

local function Native()
    return AuctionHouseFrame and AuctionHouseFrame:IsShown() and AuctionHouseFrame or nil
end

local function ItemName(itemID)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    return name or ("Item #" .. tostring(itemID))
end

local function ItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
        if ok and icon then return icon end
    end
    return 134400
end

local function SearchNative(name)
    local native = Native()
    if not native or not native.SearchBar then return end
    if native.BuyTab then native.BuyTab:Click() end
    local categories = native.GetCategoriesList and native:GetCategoriesList()
    if categories and categories.SetSelectedCategory then categories:SetSelectedCategory(nil) end
    native:SetSearchText(name)
    native.SearchBar:StartSearch()
    SetStatus("Searching Blizzard's Buy tab for " .. name .. ".")
end

local function ScanBags()
    local list = {}
    bagScan = { scanned = 0, eligible = 0 }
    if not C_Container or not C_AuctionHouse or not ItemLocation then
        bagScan.unavailable = true
        return list
    end
    local reagentBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or 5
    for bag = 0, math.max(NUM_BAG_SLOTS or 4, reagentBag) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                bagScan.scanned = bagScan.scanned + 1
                local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
                local ok, valid = pcall(C_AuctionHouse.IsSellItemValid, location, false)
                if ok and valid then
                    list[#list + 1] = {
                        itemID = info.itemID, name = info.itemName or ItemName(info.itemID),
                        icon = info.iconFileID or ItemIcon(info.itemID), count = info.stackCount or 1,
                        bag = bag, slot = slot, location = location,
                        link = info.hyperlink,
                    }
                    bagScan.eligible = bagScan.eligible + 1
                end
            end
        end
    end
    return list
end

local function SameStack(a, b)
    return a and b and a.bag == b.bag and a.slot == b.slot and a.itemID == b.itemID and a.link == b.link
end

local function QueueIndex(item)
    for index, queued in ipairs(queue) do
        if SameStack(item, queued) then return index end
    end
end


local function StopSelling()
    bulkSelling, pendingPrice, pendingPost = false, nil, nil
    pendingBuy = nil
end

local function QueueItem(item)
    if item and not QueueIndex(item) then queue[#queue + 1] = item end
end

local function ShoppingEntries()
    local list = {}
    for _, item in pairs(ns.db.shopping) do list[#list + 1] = item end
    table.sort(list, function(a, b) return (a.name or "") < (b.name or "") end)
    return list
end

local function SellFrame(native)
    local mode = native:GetDisplayMode()
    if mode == AuctionHouseFrameDisplayMode.CommoditiesSell then return native.CommoditiesSellFrame end
    if mode == AuctionHouseFrameDisplayMode.ItemSell then return native.ItemSellFrame end
end

local function StackValid(item)
    local info = C_Container.GetContainerItemInfo(item.bag, item.slot)
    return info and info.itemID == item.itemID and info.hyperlink == item.link
        and not info.isLocked and info.stackCount == item.count
end

priceNext = function()
    if pendingPrice or pendingPost then
        SetStatus("Confirm this item in Blizzard Sell, or Stop before changing the queue."); return
    end
    local native, item = Native(), queue[1]
    if not native or not item then StopSelling(); SetStatus("Add bag items to the sell queue first."); return end
    if not StackValid(item) then
        StopSelling(); SetStatus("A queued stack changed or moved. Clear the queue and add it again."); return
    end
    local ok, key = pcall(C_AuctionHouse.GetItemKeyFromItem, item.location)
    local got, commodityStatus = pcall(C_AuctionHouse.GetItemCommodityStatus, item.location)
    if not ok or not key or not got or commodityStatus == Enum.ItemCommodityStatus.Unknown then
        StopSelling(); SetStatus("Item data is unavailable. Try again after it loads."); return
    end
    local commodity = commodityStatus == Enum.ItemCommodityStatus.Commodity
    selected = item
    -- SetPostItem starts Blizzard's own price query; record our request first.
    local request = { key = key, itemID = item.itemID, commodity = commodity, item = item }
    pendingPrice = request
    if native.SellTab then native.SellTab:Click() end
    local prepared, accepted = pcall(native.SetPostItem, native, item.location)
    local sell = SellFrame(native)
    local location = sell and sell:GetItem()
    if not prepared or accepted == false or not location or not location:IsEqualTo(item.location) then
        StopSelling(); SetStatus("Could not prepare this item in Blizzard Sell. Try again."); return
    end
    if not commodity and sell.SetSecondaryPriceInputEnabled then sell:SetSecondaryPriceInputEnabled(false) end
    sell.QuantityInput:SetQuantity(item.count)
    sell.PriceInput:SetAmount(0)
    sell:UpdatePostState()
    SetStatus("Checking the lowest live price for " .. item.name .. "…")
    refreshRows()
    C_Timer.After(12, function()
        if pendingPrice == request then
            StopSelling(); SetStatus("Price lookup timed out. Retry Sell lowest; the queue is kept.")
        end
    end)
end

local function AddTrackedMaterials()
    pendingBuy = nil
    local requirements, recipes = ns:GetTrackedShoppingMaterials()
    local added = 0
    for _, material in ipairs(requirements) do
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(material.itemID) end
        local key = tostring(material.itemID)
        local item = ns.db.shopping[key]
        -- Re-importing recipes sets the current shortage instead of adding it twice.
        if not item then
            item = { itemID = material.itemID, name = material.name, maxPrice = 0 }
            ns.db.shopping[key] = item
        end
        item.recipeQuantity = material.missing
        item.quantity = (item.manualQuantity or 0) + material.missing
        if item.quantity <= 0 then ns.db.shopping[key] = nil else added = added + 1 end
    end
    -- Clear materials belonging to recipes that are no longer tracked.
    local current = {}
    for _, material in ipairs(requirements) do current[tostring(material.itemID)] = true end
    for key, item in pairs(ns.db.shopping) do
        if item.recipeQuantity and not current[key] then
            item.recipeQuantity = nil
            item.quantity = item.manualQuantity or 0
            if item.quantity == 0 then ns.db.shopping[key] = nil end
        end
    end
    entries = ShoppingEntries(); selected = nil; refreshRows()
    SetStatus(recipes == 0 and "Use Track Recipe in Professions, then Add tracked recipes."
        or string.format("%d tracked recipes: %d missing materials queued to buy.", recipes, added))
end

local function AddBuyItem()
    pendingBuy = nil
    local text = itemBox:GetText() or ""
    local id = tonumber(text:match("item:(%d+)")) or tonumber(text)
    local quantity = tonumber(quantityBox:GetText())
    if not id or id < 1 or id ~= math.floor(id) or not quantity or quantity < 1 or quantity ~= math.floor(quantity) then
        SetStatus("Enter an item ID or link, and a whole quantity of at least 1."); return
    end
    ns:WatchItem(id, ItemName(id))
    if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    local item = ns.db.shopping[tostring(id)]
    item.manualQuantity = (item.manualQuantity or (item.recipeQuantity and 0 or item.quantity) or 0) + quantity
    item.quantity = item.manualQuantity + (item.recipeQuantity or 0)
    entries = ShoppingEntries(); selected = item; refreshRows()
    itemBox:ClearFocus(); quantityBox:ClearFocus()
    SetStatus("Added " .. item.name .. " x" .. quantity .. " to Buy.")
end

local function FindBuyItem()
    local item = selected or entries[1]
    if not item then SetStatus("Add items or tracked recipe materials first."); return end
    selected = item
    pendingBuy = item
    local request = item
    C_Timer.After(12, function()
        if pendingBuy == request then
            pendingBuy = nil
            SetStatus("No matching Buy result arrived. Retry Find in Buy, or check Blizzard's filters.")
        end
    end)
    SearchNative(item.name or ItemName(item.itemID))
    refreshRows()
end

local function ConfigureActions()
    local function Action(index, label, callback)
        local button = actions[index]
        button.label:SetText(label); button:SetScript("OnClick", callback)
    end
    itemBox:SetShown(activeTab == "Buy"); quantityBox:SetShown(activeTab == "Buy")
    if activeTab == "Sell" then
        Action(1, "Add selected", function()
            QueueItem(selected); refreshRows(); SetStatus(#queue .. " stacks queued to sell.")
        end)
        Action(2, "Add all bags", function()
            entries = ScanBags()
            for _, item in ipairs(entries) do QueueItem(item) end
            refreshRows(); SetStatus(#queue .. " stacks queued to sell. Right-click rows to remove.")
        end)
        Action(3, "Sell lowest", function() bulkSelling = true; priceNext() end)
        Action(4, "Stop", function() StopSelling(); SetStatus("Stopped. Sell queue kept.") end)
        Action(5, "Clear queue", function() StopSelling(); queue = {}; refreshRows(); SetStatus("Sell queue cleared.") end)
        Action(6, "Refresh bags", function() entries = ScanBags(); refreshRows() end)
    else
        Action(1, "Add item", AddBuyItem)
        Action(2, "Add tracked recipes", AddTrackedMaterials)
        Action(3, "Find in Buy", FindBuyItem)
        Action(4, "Done / next", function()
            pendingBuy = nil
            if selected then ns.db.shopping[tostring(selected.itemID)] = nil end
            entries = ShoppingEntries(); selected = entries[1]; refreshRows(); FindBuyItem()
        end)
        Action(5, "Remove selected", function()
            pendingBuy = nil
            if selected then ns.db.shopping[tostring(selected.itemID)] = nil end
            entries = ShoppingEntries(); selected = nil; refreshRows()
        end)
        Action(6, "Clear buy queue", function()
            pendingBuy = nil
            ns.db.shopping = {}; entries = {}; selected = nil; refreshRows()
        end)
    end
end

refreshRows = function()
    if not companion or not companion:IsShown() then return end
    offset = math.min(offset, math.max(0, #entries - #rows))
    rangeText:SetText(#entries == 0 and "0 items" or string.format("%d–%d / %d", offset + 1, math.min(#entries, offset + #rows), #entries))
    for index, row in ipairs(rows) do
        local item = entries[offset + index]
        row.entry = item; row:SetShown(item ~= nil)
        if item then
            row.icon:SetTexture(item.icon or ItemIcon(item.itemID))
            row.name:SetText((selected and (activeTab == "Sell" and SameStack(selected, item) or selected == item)) and ("› " .. item.name) or item.name)
            row.meta:SetText(activeTab == "Sell" and ("x" .. item.count .. (QueueIndex(item) and " · queued" or "")) or ("Buy x" .. (item.quantity or 1)))
        end
    end
    detailText:SetText(activeTab == "Sell" and (#queue .. " queued · Confirm each post above; the next item is prepared automatically.")
        or "Item ID / link + quantity · Track Recipe materials use missing counts. Confirm purchases above.")
end

selectTab = function(name)
    if name ~= activeTab then StopSelling() end
    activeTab, offset, selected = name, 0, nil
    entries = name == "Sell" and ScanBags() or ShoppingEntries()
    for tabName, tab in pairs(tabs) do tab.label:SetText((tabName == name and "› " or "") .. tabName) end
    ConfigureActions(); refreshRows()
end

local function ApplyAppearance()
    if not companion or not ns.db then return end
    local native = Native()
    if not native then return end
    companion:SetScale(ns.db.scale or 1)
    -- Match the AH's visual width even when its scale differs from our settings.
    local width = native:GetWidth() * native:GetEffectiveScale() / companion:GetEffectiveScale()
    companion:SetWidth(math.max(760, width))
    companion:ClearAllPoints()
    companion:SetPoint("TOPLEFT", native, "BOTTOMLEFT", 0, -32)
    Style(companion); Style(itemBox); Style(quantityBox)
    for _, button in ipairs(buttons) do Style(button) end
    local path = FONT_PATHS[ns.db.font] or STANDARD_TEXT_FONT
    for _, label in ipairs(labels) do
        label:SetFont(path, label.baseSize, ns.db.font and ns.db.font:find("Outline") and "OUTLINE" or "")
        label:SetTextColor(label.muted and .72 or .96, label.muted and .80 or .96, label.muted and .86 or 1)
    end
end

local function EditBox(width)
    local box = CreateFrame("EditBox", nil, companion, "BackdropTemplate")
    box:SetSize(width, 24); box:SetAutoFocus(false); box:SetFont(STANDARD_TEXT_FONT, 12, "")
    box:SetTextColor(1, 1, 1); box:SetTextInsets(6, 6, 2, 2)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function Build()
    if companion then return end
    companion = CreateFrame("Frame", "RevathsAuctionCompanion", AuctionHouseFrame, "BackdropTemplate")
    companion:SetSize(800, 190); companion:SetFrameStrata("MEDIUM"); companion:EnableMouse(true)
    local title = Text(companion, 12); title:SetPoint("TOPLEFT", 12, -12); title:SetText("Revath's AH")
    for index, name in ipairs({ "Sell", "Buy" }) do
        local tab = Button(companion, name, 66, 24); tab:SetPoint("TOPLEFT", 114 + (index - 1) * 70, -7)
        tab:SetScript("OnClick", function() selectTab(name) end); tabs[name] = tab
    end
    rangeText = Text(companion, 10, true); rangeText:SetPoint("TOPLEFT", 270, -13)
    local previous = Button(companion, "‹", 24, 24); previous:SetPoint("TOPLEFT", 367, -7)
    previous:SetScript("OnClick", function() offset = math.max(0, offset - #rows); refreshRows() end)
    local following = Button(companion, "›", 24, 24); following:SetPoint("LEFT", previous, "RIGHT", 4, 0)
    following:SetScript("OnClick", function() offset = math.min(math.max(0, #entries - #rows), offset + #rows); refreshRows() end)
    local close = Button(companion, "×", 24, 24); close:SetPoint("TOPRIGHT", -10, -7)
    close:SetScript("OnClick", function() ns:Hide() end)
    for index = 1, 3 do
        local row = Button(companion, "", 404, 28); row:SetPoint("TOPLEFT", 12, -38 - (index - 1) * 30)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(22, 22); row.icon:SetPoint("LEFT", 4, 0)
        row.name = Text(row, 12); row.name:SetPoint("LEFT", 31, 0); row.name:SetWidth(260)
        row.meta = Text(row, 10, true); row.meta:SetPoint("RIGHT", -6, 0); row.meta:SetWidth(100); row.meta:SetJustifyH("RIGHT")
        row.label:Hide()
        row:SetScript("OnClick", function(self, button)
            if not self.entry then return end
            selected = self.entry
            if activeTab == "Buy" then pendingBuy = nil end
            if button == "RightButton" then
                if activeTab == "Sell" then
                    if bulkSelling then SetStatus("Stop selling before editing the queue."); return end
                    local queued = QueueIndex(selected)
                    if queued then table.remove(queue, queued) else QueueItem(selected) end
                else
                    ns.db.shopping[tostring(selected.itemID)] = nil; entries = ShoppingEntries(); selected = nil
                end
            end
            refreshRows()
        end)
        rows[index] = row
    end
    companion:EnableMouseWheel(true)
    companion:SetScript("OnMouseWheel", function(_, delta)
        offset = math.max(0, math.min(math.max(0, #entries - #rows), offset - delta * 3)); refreshRows()
    end)
    itemBox = EditBox(228); itemBox:SetPoint("TOPRIGHT", -76, -8)
    quantityBox = EditBox(54); quantityBox:SetPoint("LEFT", itemBox, "RIGHT", 4, 0); quantityBox:SetText("1")
    itemBox:SetScript("OnReceiveDrag", function(self)
        local kind, id, link = GetCursorInfo()
        if kind == "item" then self:SetText(link or tostring(id)); ClearCursor() end
    end)
    itemBox:SetScript("OnEnterPressed", AddBuyItem); quantityBox:SetScript("OnEnterPressed", AddBuyItem)
    for index = 1, 6 do
        local button = Button(companion, "", 146, 28)
        button:SetPoint("TOPRIGHT", -12 - ((index - 1) % 2 == 0 and 152 or 0), -38 - math.floor((index - 1) / 2) * 30)
        actions[index] = button
    end
    detailText = Text(companion, 11, true); detailText:SetPoint("TOPLEFT", 12, -136); detailText:SetPoint("RIGHT", -12, 0)
    statusText = Text(companion, 11); statusText:SetPoint("TOPLEFT", 12, -158); statusText:SetPoint("RIGHT", -12, 0); statusText:SetHeight(26)
    statusText:SetJustifyV("TOP"); statusText:SetText("Select bag items and add them to Sell, or add missing materials to Buy.")
    companion:HookScript("OnHide", StopSelling)
    companion:Hide(); ApplyAppearance()
end

function ns:ShowForAuctionHouse(force)
    if not Native() or (not force and self.db.showCompanion == false) then return end
    Build(); ApplyAppearance(); companion:Show(); selectTab(activeTab)
end

function ns:Hide()
    StopSelling()
    if companion then companion:Hide() end
end

function ns:Toggle()
    if not Native() then print("|cff2eb8c7Revath's AH:|r Visit an auctioneer first.")
    elseif companion and companion:IsShown() then self:Hide()
    else self:ShowForAuctionHouse(true) end
end

function ns:RefreshSell()
    if companion and companion:IsShown() and activeTab == "Sell" then entries = ScanBags(); refreshRows() end
end

function ns:OnSellPriceResults(event, loadedKey)
    local query = pendingPrice
    if not query or ((event == "COMMODITY_SEARCH_RESULTS_UPDATED") ~= query.commodity) then return end
    local loadedID = type(loadedKey) == "table" and loadedKey.itemID or loadedKey
    if loadedID ~= query.itemID then return end
    local native = Native()
    local sell = native and SellFrame(native)
    local location = sell and sell:GetItem()
    if not bulkSelling or not StackValid(query.item) or not location or not location:IsEqualTo(query.item.location) then
        StopSelling(); SetStatus("Sell selection changed. Retry Sell lowest when ready."); return
    end
    if not query.commodity and C_AuctionHouse.HasFullItemSearchResults
        and not C_AuctionHouse.HasFullItemSearchResults(loadedKey) then
        if C_AuctionHouse.RequestMoreItemSearchResults then
            pcall(C_AuctionHouse.RequestMoreItemSearchResults, loadedKey)
        end
        return
    end
    local lowest
    if query.commodity then
        local ok, count = pcall(C_AuctionHouse.GetNumCommoditySearchResults, query.itemID)
        if ok then
            for index = 1, count or 0 do
                local got, result = pcall(C_AuctionHouse.GetCommoditySearchResultInfo, query.itemID, index)
                local price = got and result and PlainNumber(result.unitPrice)
                if price and price > 0 then lowest = math.min(lowest or price, price) end
            end
        end
    else
        local ok, count = pcall(C_AuctionHouse.GetNumItemSearchResults, loadedKey)
        if ok then
            for index = 1, count or 0 do
                local got, result = pcall(C_AuctionHouse.GetItemSearchResultInfo, loadedKey, index)
                local price = got and result and PlainNumber(result.buyoutAmount)
                -- Blizzard's equipment query may include other item levels.
                if price and price > 0 and result.itemKey and result.itemKey.itemLevel == query.key.itemLevel then
                    lowest = math.min(lowest or price, price)
                end
            end
        end
    end
    pendingPrice = nil
    if not lowest then StopSelling(); SetStatus("No live buyout found. Queue kept; set this item's price in Blizzard Sell."); return end
    query.item.livePrice = lowest
    sell.PriceInput:SetAmount(lowest); sell.QuantityInput:SetQuantity(query.item.count); sell:UpdatePostState()
    -- Never invoke a protected post from a search event or timer.
    pendingPost = query.item
    pendingPost.commodity = query.commodity
    pendingPost.submitted = nil
    ns:RememberPrice(query.itemID, query.item.name, lowest)
    SetStatus("Lowest: " .. Money(lowest) .. " · Confirm Post above. " .. #queue .. " stacks remain.")
    refreshRows()
end

function ns:OnAuctionCreated()
    if not pendingPost then return end
    -- Only consume a queue entry after the native post button was used for it.
    if not pendingPost.submitted then return end
    pendingPost.remaining = pendingPost.remaining - 1
    if pendingPost.remaining > 0 then return end
    local index = QueueIndex(pendingPost)
    if index then
        local info = C_Container.GetContainerItemInfo(pendingPost.bag, pendingPost.slot)
        if pendingPost.postedQuantity < pendingPost.count and info and info.hyperlink == pendingPost.link then
            pendingPost.count = info.stackCount
        else
            table.remove(queue, index)
        end
    end
    pendingPost = nil
    self:RefreshSell()
    if bulkSelling and #queue > 0 then
        C_Timer.After(.2, function() if bulkSelling and Native() then priceNext() end end)
    else
        StopSelling(); SetStatus("Sell queue complete.")
    end
end

function ns:OnAuctionError()
    StopSelling(); SetStatus("Auction action failed. Queue kept; review Blizzard's message and retry.")
end

function ns:OnItemDataLoaded(itemID)
    local item = self.db.shopping[tostring(itemID)]
    if item then item.name = ItemName(itemID); self:RefreshShopping() end
end

function ns:RefreshShopping()
    if companion and companion:IsShown() and activeTab == "Buy" then entries = ShoppingEntries(); refreshRows() end
end

function ns:OnBrowseResults()
    if not Native() or activeTab ~= "Buy" or not pendingBuy then return end
    local item = pendingBuy
    -- Open only the exact requested material, preserving reagent quality.
    for _, result in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
        if result.itemKey and result.itemKey.itemID == item.itemID then
            pendingBuy = nil
            AuctionHouseFrame:SelectBrowseResult(result)
            local buy = AuctionHouseFrame.CommoditiesBuyFrame
            if buy and buy:IsShown() and buy.BuyDisplay then buy.BuyDisplay:SetQuantitySelected(item.quantity or 1) end
            SetStatus("Buy " .. (item.quantity or 1) .. " × " .. item.name .. " above, then Done / next.")
            return
        end
    end
end

local function AddTooltipPrice()
    if not ns.db or not ns.db.showTooltipPrice then return end
    local _, link = GameTooltip:GetItem()
    local itemID = link and tonumber(link:match("item:(%d+)"))
    local record = itemID and ns.db.prices[tostring(itemID)]
    if not record or not record.last then return end
    GameTooltip:AddLine("Enchanted AH: " .. Money(record.last), .32, .85, .9)
    if record.updated then
        GameTooltip:AddLine((record.source or "Observed") .. " · " .. date("%d %b %H:%M", record.updated), .70, .78, .82)
    end
end

function ns:Initialize()
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if tooltip == GameTooltip then AddTooltipPrice() end
        end)
    else
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltipPrice)
    end
    local hooked = false
    local function HookPost()
        if hooked or not AuctionHouseFrame or not AuctionHouseFrame.ItemSellFrame or not AuctionHouseFrame.CommoditiesSellFrame then return end
        hooked = true
        hooksecurefunc(AuctionHouseFrame, "SetPostItem", function(_, location)
            if pendingPost and location and not location:IsEqualTo(pendingPost.location) then
                StopSelling(); SetStatus("Sell item changed. Queue kept; retry when ready.")
            end
        end)
        hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(_, mode)
            if bulkSelling and mode ~= AuctionHouseFrameDisplayMode.CommoditiesSell
                and mode ~= AuctionHouseFrameDisplayMode.ItemSell then StopSelling() end
        end)
        for _, sell in ipairs({ AuctionHouseFrame.ItemSellFrame, AuctionHouseFrame.CommoditiesSellFrame }) do
            hooksecurefunc(sell, "CachePendingPost", function(self, location, duration, quantity)
                if pendingPost and location and location:IsEqualTo(pendingPost.location) then
                    pendingPost.submitted = true
                    pendingPost.remaining = pendingPost.commodity and 1 or quantity
                    pendingPost.postedQuantity = quantity
                end
            end)
        end
    end
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:SetScript("OnEvent", HookPost)
    HookPost()
end

function RevathsEnchantedAuctionHouse_ApplySettings()
    if not ns.db then return end
    if companion then ApplyAppearance() end
    if ns.db.showCompanion == false then ns:Hide()
    elseif Native() then ns:ShowForAuctionHouse(true) end
end
