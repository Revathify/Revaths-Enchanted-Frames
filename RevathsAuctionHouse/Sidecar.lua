local _, ns = ...

-- Blizzard keeps its category tree, result cells, coin displays, and protected
-- checkout. This companion only adds planning tools beside that native frame.
local companion, statusText, detailText, heading, hint, limitBox, rangeText
local tabs, rows, actions, labels, buttons = {}, {}, {}, {}, {}
local activeTab, entries, offset, selected = "Sell", {}, 0, nil
local queue, pendingPrice, pendingPost = {}, nil, nil
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
                    local loaded, bindType = pcall(function()
                        return select(14, C_Item.GetItemInfo(info.hyperlink or info.itemID))
                    end)
                    list[#list + 1] = {
                        itemID = info.itemID, name = info.itemName or ItemName(info.itemID),
                        icon = info.iconFileID or ItemIcon(info.itemID), count = info.stackCount or 1,
                        bag = bag, slot = slot, location = location,
                        boe = not info.isBound and loaded and bindType == (Enum.ItemBind and Enum.ItemBind.OnEquip or 2),
                    }
                    bagScan.eligible = bagScan.eligible + 1
                end
            end
        end
    end
    return list
end

local function SameStack(a, b)
    return a and b and a.bag == b.bag and a.slot == b.slot and a.itemID == b.itemID
end

local function QueueIndex(item)
    for index, queued in ipairs(queue) do
        if SameStack(item, queued) then return index end
    end
end

local function QueueWhere(predicate, label)
    local existing, added = {}, 0
    for _, item in ipairs(queue) do existing[item.bag .. ":" .. item.slot] = true end
    entries = ScanBags()
    for _, item in ipairs(entries) do
        local key = item.bag .. ":" .. item.slot
        if predicate(item) and not existing[key] then
            queue[#queue + 1] = item; existing[key] = true; added = added + 1
        end
    end
    selected = queue[1]
    if added > 0 then
        SetStatus(string.format("Added %d %s stacks. %d queued; review each in Blizzard Sell.", added, label, #queue))
    elseif bagScan.unavailable then
        SetStatus("Bag or auction APIs are unavailable. Reload at an auctioneer.")
    elseif #entries == 0 then
        SetStatus(string.format("No auctionable bag items found (%d occupied slots checked).", bagScan.scanned))
    elseif label == "marked" then
        SetStatus("Nothing marked. Right-click a sellable item row to mark it.")
    else
        SetStatus(string.format("No new %s stacks. %d sellable items found; %d already queued.", label, #entries, #queue))
    end
end

local function PriceNext()
    local item = selected or queue[1]
    if not item then SetStatus("Select a bag item or queue one first."); return end
    selected = item
    if C_Container.GetContainerItemID(item.bag, item.slot) ~= item.itemID then
        SetStatus("This stack moved. Rebuild the queue."); return
    end
    local ok, key = pcall(C_AuctionHouse.GetItemKeyFromItem, item.location)
    if not ok or not key then SetStatus("Could not identify this item for pricing."); return end
    local got, keyInfo = pcall(C_AuctionHouse.GetItemKeyInfo, key)
    local commodity = got and keyInfo and keyInfo.isCommodity == true
    local context = commodity and AuctionHouseSearchContext.SellCommodities or AuctionHouseSearchContext.SellItems
    local native = Native()
    if not native or not native.QueryItem then return end
    pendingPrice = { key = key, itemID = item.itemID, commodity = commodity, item = item }
    local sent = pcall(native.QueryItem, native, context, key)
    if not sent then pendingPrice = nil; SetStatus("Live price search could not start."); return end
    SetStatus("Checking the lowest current listing for " .. item.name .. "…")
    local request = pendingPrice
    C_Timer.After(12, function()
        if pendingPrice == request then
            pendingPrice = nil
            SetStatus("No live price response arrived. Try again or use Blizzard's Sell view.")
        end
    end)
end

local function ReviewPost()
    local native, item = Native(), selected or queue[1]
    if not native or not item then SetStatus("Select a bag item or queue one first."); return end
    if C_Container.GetContainerItemID(item.bag, item.slot) ~= item.itemID then
        SetStatus("This stack moved. Rebuild the queue."); return
    end
    if native.SellTab then native.SellTab:Click() end
    local ok, accepted = pcall(native.SetPostItem, native, item.location)
    if not ok or accepted == false then SetStatus("Blizzard's Sell view could not prepare this item."); return end
    local mode = native:GetDisplayMode()
    local sell = mode == AuctionHouseFrameDisplayMode.CommoditiesSell and native.CommoditiesSellFrame
        or mode == AuctionHouseFrameDisplayMode.ItemSell and native.ItemSellFrame
    if not sell or not sell.GetItem or not sell:GetItem() then
        SetStatus("Finish this special item in Blizzard's Sell view."); return
    end
    if sell.QuantityInput then sell.QuantityInput:SetQuantity(item.count) end
    if item.livePrice and sell.PriceInput then sell.PriceInput:SetAmount(item.livePrice) end
    -- Leave Blizzard's duration choice intact; its control is not a SetDuration widget.
    if sell.UpdatePostState then sell:UpdatePostState() end
    pendingPost = QueueIndex(item) and item or nil
    SetStatus(item.livePrice and "Review quantity, price, and deposit in Blizzard Sell; confirm there."
        or "Blizzard Sell is ready. Enter a price, review the deposit, then confirm there.")
end

local function WatchEntries()
    local list = {}
    for _, watch in pairs(ns.db.shopping) do list[#list + 1] = watch end
    table.sort(list, function(a, b) return (a.name or ""):lower() < (b.name or ""):lower() end)
    return list
end

local function PriceEntries()
    local list = {}
    for id, record in pairs(ns.db.prices) do
        list[#list + 1] = { itemID = tonumber(id), name = record.name or ItemName(id), record = record }
    end
    table.sort(list, function(a, b) return (a.record.updated or 0) > (b.record.updated or 0) end)
    return list
end

local function RefreshDetails()
    if not detailText then return end
    if activeTab == "Sell" then
        if selected then
            local mark = ns.db.craftSelections[tostring(selected.itemID)] and " · marked" or ""
            local queued = QueueIndex(selected)
            detailText:SetText(selected.name .. "  x" .. selected.count .. mark .. (queued and " · queued #" .. queued or "") .. "\n"
                .. "Lowest live: " .. Money(selected.livePrice) .. "   Queue: " .. #queue .. " stacks"
                .. "\nSelect a row, then Review in Sell. Price lookup is optional.")
        else
            detailText:SetText(string.format("%d auctionable stacks in bags (%d occupied slots checked).\n"
                .. "Select a row to sell it. Right-click to mark a crafted item; bulk-queue below.",
                bagScan.eligible, bagScan.scanned))
        end
    elseif activeTab == "Crafting" then
        detailText:SetText(selected and (selected.recipeName .. "\n" .. selected.name .. ": need "
            .. selected.required .. ", own " .. selected.held .. ", missing " .. selected.missing
            .. "\nLast seen: " .. Money((ns.db.prices[tostring(selected.itemID)] or {}).last))
            or "Track a recipe with the Track Recipe checkbox in Professions (the star only favorites it).")
    elseif activeTab == "Shopping" then
        detailText:SetText(selected and ((selected.name or ItemName(selected.itemID)) .. "\n"
            .. "Last seen: " .. Money((ns.db.prices[tostring(selected.itemID)] or {}).last)
            .. "   Limit: " .. Money(selected.maxPrice))
            or "Right-click a Blizzard browse result to watch it. Set a maximum price here.")
    else
        local scan = ns.db.marketScan or {}
        detailText:SetText(selected and (selected.name .. "\nLast seen: " .. Money(selected.record.last)
            .. "\n" .. (selected.record.source or "Observed") .. " · " .. date("%d %b %H:%M", selected.record.updated or time()))
            or (scan.at and string.format("Last scan: %s · %d auctions · %d item values",
                date("%d %b %H:%M", scan.at), scan.auctions or 0, scan.items or 0)
                or "No full-market snapshot saved. Scans are manual and game-throttled."))
    end
end

local function RefreshRows()
    if not companion or not companion:IsShown() then return end
    offset = math.min(offset, math.max(0, #entries - #rows))
    if rangeText then
        rangeText:SetText(#entries == 0 and "0 items" or string.format("%d–%d / %d", offset + 1, math.min(#entries, offset + #rows), #entries))
    end
    for index, row in ipairs(rows) do
        local entry = entries[offset + index]
        row.entry = entry
        row:SetShown(entry ~= nil)
        if entry then
            row.icon:SetTexture(entry.icon or ItemIcon(entry.itemID))
            row.name:SetText(entry.name or ItemName(entry.itemID))
            if activeTab == "Sell" then
                local queued = QueueIndex(entry)
                row.meta:SetText("x" .. entry.count .. (entry.boe and " · BoE" or "")
                    .. (ns.db.craftSelections[tostring(entry.itemID)] and " · MARKED" or "")
                    .. (queued and " · QUEUED #" .. queued or ""))
            elseif activeTab == "Crafting" then
                row.meta:SetText("Need " .. entry.missing .. " · own " .. entry.held)
            elseif activeTab == "Shopping" then
                row.meta:SetText("Limit " .. Money(entry.maxPrice))
            else
                row.meta:SetText(Money(entry.record.last))
            end
        end
    end
    RefreshDetails()
end

local function ConfigureActions()
    local function SetAction(index, label, callback)
        local button = actions[index]
        button.label:SetText(label); button:SetScript("OnClick", callback); button:Show()
    end
    for _, button in ipairs(actions) do button:Hide() end
    if activeTab == "Sell" then
        SetAction(1, "Queue BoE", function() QueueWhere(function(item) return item.boe end, "BoE"); RefreshRows() end)
        SetAction(2, "Queue marked", function() QueueWhere(function(item) return ns.db.craftSelections[tostring(item.itemID)] end, "marked"); RefreshRows() end)
        SetAction(3, "Queue all sellable", function() QueueWhere(function() return true end, "sellable"); RefreshRows() end)
        SetAction(4, "Check live price", function() PriceNext(); RefreshRows() end)
        SetAction(5, "Review in Sell", function() ReviewPost(); RefreshRows() end)
    elseif activeTab == "Crafting" then
        SetAction(1, "Find in Buy", function() if selected then SearchNative(selected.name) end end)
        SetAction(2, "Open result", function()
            if not selected then return end
            local results = C_AuctionHouse.GetBrowseResults()
            for _, result in ipairs(results or {}) do
                if result.itemKey and result.itemKey.itemID == selected.itemID then
                    AuctionHouseFrame:SelectBrowseResult(result); return
                end
            end
            SetStatus("Search this material first, then choose a Blizzard result.")
        end)
        SetAction(3, "Next quality", function()
            if selected and #selected.variants > 1 then
                local slot = selected.slotKey
                ns:CycleReagentVariant(selected)
                entries = ns:GetTrackedMaterials()
                for _, material in ipairs(entries) do if material.slotKey == slot then selected = material; break end end
                RefreshRows()
            end
        end)
        SetAction(4, "Refresh recipes", function() entries = ns:GetTrackedMaterials(); selected = nil; RefreshRows() end)
    elseif activeTab == "Shopping" then
        SetAction(1, "Find in Buy", function() if selected then SearchNative(selected.name or ItemName(selected.itemID)) end end)
        SetAction(2, "Remove watch", function()
            if selected then ns.db.shopping[tostring(selected.itemID)] = nil; entries = WatchEntries(); selected = nil; RefreshRows() end
        end)
        SetAction(3, "Save price limit", function()
            if not selected then return end
            local gold = tonumber(limitBox:GetText())
            if not gold or gold < 0 then SetStatus("Enter a non-negative gold amount."); return end
            selected.maxPrice = math.floor(gold * 10000 + .5)
            RefreshRows(); SetStatus("Shopping price limit saved.")
        end)
        SetAction(4, "Watch first Buy result", function()
            local results = C_AuctionHouse.GetBrowseResults()
            local result = results and results[1]
            if not result or not result.itemKey then
                SetStatus("Search an item in Blizzard's Buy tab first."); return
            end
            local itemID = result.itemKey.itemID
            local info = C_AuctionHouse.GetItemKeyInfo(result.itemKey)
            ns:WatchItem(itemID, info and info.itemName or ItemName(itemID))
            entries = WatchEntries(); RefreshRows()
            SetStatus("Added the first Blizzard Buy result to Shopping.")
        end)
    else
        SetAction(1, "Scan market", function() ns:StartMarketScan() end)
        SetAction(2, "Find in Buy", function() if selected then SearchNative(selected.name) end end)
    end
    limitBox:SetShown(activeTab == "Shopping")
end

local function SelectTab(name)
    activeTab, offset, selected = name, 0, nil
    if name == "Sell" then entries = ScanBags()
    elseif name == "Crafting" then entries = ns:GetTrackedMaterials()
    elseif name == "Shopping" then entries = WatchEntries()
    else entries = PriceEntries() end
    heading:SetText(({ Sell = "Sell queue", Crafting = "Tracked recipe materials",
        Shopping = "Shopping list", Prices = "Market prices" })[name])
    hint:SetText(({ Sell = "Select a stack or queue in bulk. Price lookup is optional; every post needs confirmation.",
        Crafting = "Track Recipe in Professions, then find missing reagents.",
        Shopping = "Watched items and your maximum prices.",
        Prices = "Observed values; full scan only when you request it." })[name])
    for tabName, tab in pairs(tabs) do
        tab.label:SetText((tabName == name and "› " or "") .. tabName)
    end
    ConfigureActions(); RefreshRows()
end

local function PlaceCompanion()
    local native = Native()
    if not native or not companion then return end
    companion:ClearAllPoints()
    local scale = companion:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width = companion:GetWidth() * scale
    if (native:GetRight() or 0) + width + 10 < UIParent:GetRight() then
        companion:SetPoint("TOPLEFT", native, "TOPRIGHT", 8, 0)
    else
        companion:SetPoint("TOPRIGHT", native, "TOPLEFT", -8, 0)
    end
end

local function ApplyAppearance()
    if not companion or not ns.db then return end
    companion:SetScale(ns.db.scale or 1)
    Style(companion)
    if limitBox then Style(limitBox) end
    for _, button in ipairs(buttons) do Style(button) end
    local path = FONT_PATHS[ns.db.font] or STANDARD_TEXT_FONT
    for _, label in ipairs(labels) do
        label:SetFont(path, label.baseSize, ns.db.font and ns.db.font:find("Outline") and "OUTLINE" or "")
        label:SetTextColor(label.muted and .72 or .96, label.muted and .80 or .96, label.muted and .86 or 1)
    end
    PlaceCompanion()
end

local function Build()
    if companion then return end
    companion = CreateFrame("Frame", "RevathsAuctionCompanion", UIParent, "BackdropTemplate")
    companion:SetSize(455, 615)
    companion:SetFrameStrata("MEDIUM")
    companion:SetClampedToScreen(true)
    companion:EnableMouse(true)
    local emblem = companion:CreateTexture(nil, "ARTWORK")
    emblem:SetSize(42, 42); emblem:SetPoint("TOPLEFT", 12, -10)
    emblem:SetTexture("Interface\\AddOns\\RevathsAuctionHouse\\Media\\IconSmall.png")
    local title = Text(companion, 17); title:SetPoint("TOPLEFT", 59, -15)
    title:SetText("REVATH'S ENCHANTED AUCTIONS")
    local caption = Text(companion, 10, true); caption:SetPoint("TOPLEFT", 60, -38)
    caption:SetText("COMPANION TO BLIZZARD'S AUCTION HOUSE")
    local close = Button(companion, "×", 27, 27); close:SetPoint("TOPRIGHT", -12, -13)
    close:SetScript("OnClick", function() companion:Hide() end)
    local settings = Button(companion, "Settings", 70, 27); settings:SetPoint("RIGHT", close, "LEFT", -6, 0)
    settings:SetScript("OnClick", function()
        if SlashCmdList.REVATHSENCHANTEDFRAMES then SlashCmdList.REVATHSENCHANTEDFRAMES() end
    end)
    local tabNames = { "Sell", "Crafting", "Shopping", "Prices" }
    for index, name in ipairs(tabNames) do
        local tab = Button(companion, name, 101, 29)
        tab:SetPoint("TOPLEFT", 16 + (index - 1) * 106, -68)
        tab:SetScript("OnClick", function() SelectTab(name) end)
        tabs[name] = tab
    end
    heading = Text(companion, 16); heading:SetPoint("TOPLEFT", 17, -108)
    rangeText = Text(companion, 10, true); rangeText:SetPoint("TOPRIGHT", -77, -111)
    local previous = Button(companion, "‹", 25, 23); previous:SetPoint("TOPRIGHT", -43, -105)
    previous:SetScript("OnClick", function() offset = math.max(0, offset - #rows); RefreshRows() end)
    local following = Button(companion, "›", 25, 23); following:SetPoint("TOPRIGHT", -15, -105)
    following:SetScript("OnClick", function() offset = math.min(math.max(0, #entries - #rows), offset + #rows); RefreshRows() end)
    hint = Text(companion, 11, true); hint:SetPoint("TOPLEFT", 17, -132)
    hint:SetWidth(415)
    for index = 1, 8 do
        local row = Button(companion, "", 420, 32)
        row:SetPoint("TOPLEFT", 17, -163 - (index - 1) * 34)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(27, 27); row.icon:SetPoint("LEFT", 4, 0)
        row.name = Text(row, 12); row.name:SetPoint("TOPLEFT", 38, -4); row.name:SetWidth(240)
        row.meta = Text(row, 10, true); row.meta:SetPoint("BOTTOMLEFT", 38, 3); row.meta:SetWidth(370)
        row.label:Hide()
        row:SetScript("OnClick", function(self, button)
            local entry = self.entry
            if not entry then return end
            if button == "RightButton" and activeTab == "Sell" then
                local key = tostring(entry.itemID)
                ns.db.craftSelections[key] = not ns.db.craftSelections[key] or nil
                SetStatus(ns.db.craftSelections[key] and "Marked for crafted-item queue." or "Mark removed.")
            elseif button == "RightButton" and activeTab == "Shopping" then
                ns.db.shopping[tostring(entry.itemID)] = nil
                entries = WatchEntries(); selected = nil
            else
                selected = entry
                if activeTab == "Shopping" then
                    limitBox:SetText(string.format("%.4f", (entry.maxPrice or 0) / 10000))
                end
            end
            RefreshRows()
        end)
        rows[index] = row
    end
    companion:EnableMouseWheel(true)
    companion:SetScript("OnMouseWheel", function(_, delta)
        offset = math.max(0, math.min(math.max(0, #entries - #rows), offset - delta * 3))
        RefreshRows()
    end)
    detailText = Text(companion, 12)
    detailText:SetPoint("TOPLEFT", 18, -444); detailText:SetWidth(420)
    detailText:SetJustifyV("TOP")
    limitBox = CreateFrame("EditBox", nil, companion, "BackdropTemplate")
    limitBox:SetSize(95, 25); limitBox:SetPoint("BOTTOMRIGHT", -17, 93)
    limitBox:SetAutoFocus(false); limitBox:SetFont(STANDARD_TEXT_FONT, 13, "")
    limitBox:SetTextColor(1, 1, 1)
    limitBox:SetTextInsets(8, 8, 3, 3)
    limitBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    actions[1] = Button(companion, "", 134, 29); actions[1]:SetPoint("BOTTOMLEFT", 17, 71)
    actions[2] = Button(companion, "", 134, 29); actions[2]:SetPoint("LEFT", actions[1], "RIGHT", 7, 0)
    actions[3] = Button(companion, "", 134, 29); actions[3]:SetPoint("LEFT", actions[2], "RIGHT", 7, 0)
    actions[4] = Button(companion, "", 203, 29); actions[4]:SetPoint("BOTTOMLEFT", 17, 37)
    actions[5] = Button(companion, "", 203, 29); actions[5]:SetPoint("LEFT", actions[4], "RIGHT", 7, 0)
    statusText = Text(companion, 11, true)
    statusText:SetPoint("BOTTOMLEFT", 18, 14); statusText:SetWidth(420)
    statusText:SetText("Blizzard's browsing and checkout remain available beside this panel.")
    companion:Hide()
    ApplyAppearance()
end

function ns:ShowForAuctionHouse(force)
    local native = Native()
    if not native then return end
    if not force and self.db.showCompanion == false then return end
    Build(); ApplyAppearance(); companion:Show(); SelectTab(activeTab)
end

function ns:Hide()
    if companion then companion:Hide() end
end

function ns:Toggle()
    if not Native() then
        print("|cff2eb8c7Revath's Enchanted Auction House:|r Visit an auctioneer first.")
    elseif companion and companion:IsShown() then companion:Hide()
    else self:ShowForAuctionHouse(true) end
end

function ns:RefreshSell()
    if companion and companion:IsShown() and activeTab == "Sell" then
        entries = ScanBags(); RefreshRows()
    end
end

function ns:OnSellPriceResults(event, loadedKey)
    local query = pendingPrice
    if not query or ((event == "COMMODITY_SEARCH_RESULTS_UPDATED") ~= query.commodity) then return end
    local loadedID = type(loadedKey) == "table" and loadedKey.itemID or loadedKey
    if loadedID and loadedID ~= query.itemID then return end
    pendingPrice = nil
    local lowest
    if query.commodity then
        local ok, info = pcall(C_AuctionHouse.GetCommoditySearchResultInfo, query.itemID, 1)
        if ok and info then lowest = PlainNumber(info.unitPrice) end
    else
        local ok, count = pcall(C_AuctionHouse.GetNumItemSearchResults, query.key)
        if ok then
            for index = 1, math.min(count or 0, 100) do
                local got, info = pcall(C_AuctionHouse.GetItemSearchResultInfo, query.key, index)
                local price = got and info and PlainNumber(info.buyoutAmount)
                if price and price > 0 then lowest = math.min(lowest or price, price) end
            end
        end
    end
    if not lowest or lowest <= 0 then
        SetStatus("No current buyout found. Price this one in Blizzard's Sell view."); return
    end
    query.item.livePrice = lowest
    ns:RememberPrice(query.itemID, query.item.name, lowest)
    RefreshDetails()
    SetStatus("Lowest current listing: " .. Money(lowest) .. " per item. Review before posting.")
end

function ns:OnAuctionCreated()
    if not pendingPost then return end
    local index = QueueIndex(pendingPost)
    if index then table.remove(queue, index) end
    pendingPost = nil
    selected = queue[1]
    self:RefreshSell()
    SetStatus(string.format("Posted. %d queued stacks remain; select the next and review it.", #queue))
end

function ns:OnAuctionError()
    pendingPost = nil
    SetStatus("Blizzard declined that auction. Check the item, price, or available funds.")
end

function ns:OnBrowseResults()
    local ok, results = pcall(C_AuctionHouse.GetBrowseResults)
    if ok and type(results) == "table" then
        for index = 1, math.min(#results, 300) do
            local result = results[index]
            local id = result.itemKey and result.itemKey.itemID
            local price = PlainNumber(result.minPrice)
            if id and price and price > 0 then
                local infoOK, keyInfo = pcall(C_AuctionHouse.GetItemKeyInfo, result.itemKey)
                self:RememberPrice(id, infoOK and keyInfo and keyInfo.itemName or ItemName(id), price)
            end
        end
    end
    if companion and companion:IsShown() and activeTab == "Shopping" then RefreshRows() end
end

function ns:RefreshMarket()
    if companion and companion:IsShown() and activeTab == "Prices" then
        if not self:IsMarketScanActive() then entries = PriceEntries() end
        RefreshRows()
    end
end

function ns:RefreshShopping()
    if companion and companion:IsShown() and activeTab == "Shopping" then
        entries = WatchEntries(); RefreshRows()
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
    -- The companion is not a replacement for Blizzard's frame. Never change
    -- its alpha or place a mouse-blocking layer over it.
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if tooltip == GameTooltip then AddTooltipPrice() end
        end)
    else
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltipPrice)
    end
end

function RevathsEnchantedAuctionHouse_ApplySettings()
    if not ns.db then return end
    if companion then
        ApplyAppearance()
        if ns.db.showCompanion == false then companion:Hide()
        elseif Native() then ns:ShowForAuctionHouse(true) end
    elseif ns.db.showCompanion ~= false and Native() then ns:ShowForAuctionHouse(true) end
end
