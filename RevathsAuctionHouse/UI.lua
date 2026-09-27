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
local frame, status, title, subtitle, tabButtons = nil, nil, nil, nil, {}
local panes, activeTab, searchBox, browseRows, shoppingRows, ownedRows, historyRows = {}, "Browse", nil, {}, {}, {}, {}
local browseOffset, shoppingOffset, ownedOffset, historyOffset = 0, 0, 0, 0
local browseResults, ownedAuctions = {}, {}
local selectedWatch, selectedAuction, selectedHistory
local watchPriceBox, watchDetails, auctionDetails, historyDetails, historyPoints
local refreshBrowse, refreshShopping, refreshOwned, refreshHistory, applyAppearance
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
    if refreshBrowse then refreshBrowse() end
    SetStatus("Searching for " .. term .. "...")
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
            local ok = pcall(AuctionHouseFrame.SelectBrowseResult, AuctionHouseFrame, result)
            if not ok then SetStatus("Open this result in Blizzard's Buy tab.") end
        end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end
    local instruction = Font(pane, 11, true); instruction:SetPoint("BOTTOMLEFT", 18, 51)
    instruction:SetText("Click to open purchase · Right-click to add to Shopping")
    local native = Button(pane, "Blizzard Buy", 125, 30); native:SetPoint("BOTTOMLEFT", 18, 13)
    native:SetScript("OnClick", function() SelectNativeTab("Buy") end)
    local sell = Button(pane, "Blizzard Sell", 125, 30); sell:SetPoint("LEFT", native, "RIGHT", 8, 0)
    sell:SetScript("OnClick", function() SelectNativeTab("Sell") end)
    local prev = Button(pane, "Previous", 84, 30); prev:SetPoint("BOTTOMRIGHT", -108, 13)
    local nextButton = Button(pane, "Next", 84, 30); nextButton:SetPoint("BOTTOMRIGHT", -16, 13)
    prev:SetScript("OnClick", function() browseOffset = math.max(0, browseOffset - #browseRows); refreshBrowse() end)
    nextButton:SetScript("OnClick", function() browseOffset = math.min(math.max(0, #browseResults - #browseRows), browseOffset + #browseRows); refreshBrowse() end)
    pane:EnableMouseWheel(true)
    pane:SetScript("OnMouseWheel", function(_, delta)
        browseOffset = math.max(0, math.min(math.max(0, #browseResults - #browseRows), browseOffset - delta * 3))
        refreshBrowse()
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
    shoppingRows = PageRows(pane, -74, 6, 39)
    for _, row in ipairs(shoppingRows) do
        row:SetScript("OnClick", function(self)
            selectedWatch = self.record
            if selectedWatch then
                watchPriceBox:SetText(selectedWatch.maxPrice and selectedWatch.maxPrice > 0 and tostring(selectedWatch.maxPrice / 10000) or "")
                watchDetails:SetText((selectedWatch.name or "Item") .. "  ·  last seen " .. ns:Money((ns.db.prices[tostring(selectedWatch.itemID)] or {}).last))
            end
        end)
    end
    watchDetails = Font(pane, 12); watchDetails:SetPoint("BOTTOMLEFT", 18, 122); watchDetails:SetWidth(515)
    watchDetails:SetText("Select an item to set a maximum price.")
    local maxLabel = Font(pane, 11, true); maxLabel:SetPoint("BOTTOMLEFT", 18, 92); maxLabel:SetText("MAX PRICE (GOLD)")
    watchPriceBox = Edit(pane, 105, 30); watchPriceBox:SetPoint("BOTTOMLEFT", 18, 55)
    watchPriceBox:SetNumeric(false)
    local save = Button(pane, "Save limit", 92, 30); save:SetPoint("LEFT", watchPriceBox, "RIGHT", 7, 0)
    save:SetScript("OnClick", function()
        if not selectedWatch then return end
        local gold = tonumber(watchPriceBox:GetText())
        if not gold or gold < 0 then SetStatus("Enter a valid maximum gold price."); return end
        selectedWatch.maxPrice = math.floor(gold * 10000 + 0.5)
        refreshShopping(); SetStatus("Shopping price limit saved.")
    end)
    local find = Button(pane, "Search item", 99, 30); find:SetPoint("LEFT", save, "RIGHT", 7, 0)
    find:SetScript("OnClick", function() if selectedWatch then SelectTab("Browse"); Search(selectedWatch.name) end end)
    local remove = Button(pane, "Remove", 78, 30); remove:SetPoint("LEFT", find, "RIGHT", 7, 0)
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
    ownedRows = PageRows(pane, -74, 6, 39)
    for _, row in ipairs(ownedRows) do
        row:SetScript("OnClick", function(self)
            selectedAuction = self.auction
            if selectedAuction then
                local name = ItemName(selectedAuction.itemKey)
                auctionDetails:SetText(name .. "  ·  buyout " .. ns:Money(SafeNumber(selectedAuction.buyoutAmount)))
            end
        end)
    end
    auctionDetails = Font(pane, 12); auctionDetails:SetPoint("BOTTOMLEFT", 18, 117); auctionDetails:SetWidth(518)
    auctionDetails:SetText("Select an auction to inspect it.")
    local refresh = Button(pane, "Refresh", 94, 30); refresh:SetPoint("BOTTOMLEFT", 18, 62)
    refresh:SetScript("OnClick", function()
        if C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions then pcall(C_AuctionHouse.QueryOwnedAuctions, {}) end
        refreshOwned()
    end)
    local check = Button(pane, "Check market", 115, 30); check:SetPoint("LEFT", refresh, "RIGHT", 7, 0)
    check:SetScript("OnClick", function()
        if not selectedAuction then return end
        local name = ItemName(selectedAuction.itemKey)
        SelectTab("Browse"); Search(name)
        SetStatus("Compare the lowest market price with your listing before cancelling.")
    end)
    local cancel = Button(pane, "Cancel selected", 120, 30); cancel:SetPoint("LEFT", check, "RIGHT", 7, 0)
    cancel:SetScript("OnClick", function()
        if not selectedAuction or not selectedAuction.auctionID then return end
        local ok, canCancel = pcall(C_AuctionHouse.CanCancelAuction, selectedAuction.auctionID)
        if not ok or not canCancel then
            SetStatus("This auction cannot be cancelled now."); return
        end
        StaticPopup_Show("REVATHS_AUCTION_CANCEL", nil, nil, selectedAuction.auctionID)
    end)
    local native = Button(pane, "Blizzard Auctions", 126, 30); native:SetPoint("LEFT", cancel, "RIGHT", 7, 0)
    native:SetScript("OnClick", function() SelectNativeTab("Auctions") end)
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
    historyRows = PageRows(pane, -74, 6, 39)
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
    historyDetails = Font(pane, 12); historyDetails:SetPoint("BOTTOMLEFT", 18, 166)
    historyDetails:SetText("Select an item to see recent daily observations.")
    historyPoints = Font(pane, 12, true); historyPoints:SetPoint("TOPLEFT", historyDetails, "BOTTOMLEFT", 0, -8)
    historyPoints:SetJustifyV("TOP")
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
    local blizzard = Button(pane, "Open Blizzard AddOn settings", 260, 35); blizzard:SetPoint("BOTTOMLEFT", 18, 22)
    blizzard:SetScript("OnClick", function()
        if SlashCmdList.REVATHSENCHANTEDFRAMES then SlashCmdList.REVATHSENCHANTEDFRAMES() end
    end)
    pane.controls = { skin = skin, palette = palette, opacity = opacity, scale = scale, tooltip = tooltip }
end

function ns:RefreshSettings()
    local controls = panes.Settings and panes.Settings.controls
    if not controls then return end
    controls.skin.label:SetText("Skin: " .. (self.db.skin == "classic" and "Classic" or "Modern"))
    controls.palette.label:SetText("Palette: " .. self.db.palette)
    controls.opacity.label:SetText(string.format("Opacity: %d%%", self.db.opacity * 100))
    controls.scale.label:SetText(string.format("Scale: %d%%", self.db.scale * 100))
    controls.tooltip.label:SetText("Price in item tooltips: " .. (self.db.showTooltipPrice and "On" or "Off"))
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
    GameTooltip:AddLine("Enchanted AH last seen: " .. ns:Money(record.last), 0.32, 0.85, 0.9)
end

function ns:Initialize()
    frame = Panel(UIParent, "RevathsEnchantedAuctionHouseFrame")
    frame:SetSize(570, 640)
    frame:SetFrameStrata("HIGH")
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
    close:SetScript("OnClick", function() frame:Hide() end)
    local tabNames = { "Browse", "Shopping", "Auctions", "Prices", "Settings" }
    for i, name in ipairs(tabNames) do
        local tab = Button(frame, name, 103, 29)
        tab:SetPoint("TOPLEFT", 15 + (i - 1) * 109, -74)
        tab:SetScript("OnClick", function() SelectTab(name) end)
        tabButtons[name] = tab
        local pane = Panel(frame)
        pane:SetPoint("TOPLEFT", 12, -111); pane:SetPoint("BOTTOMRIGHT", -12, 44)
        panes[name] = pane
    end
    status = Font(frame, 11, true)
    status:SetPoint("BOTTOMLEFT", 20, 15); status:SetPoint("RIGHT", -20, 0)
    status:SetText("Open an auctioneer to search the live market.")
    BuildBrowse(); BuildShopping(); BuildOwned(); BuildHistory(); BuildSettings()
    StaticPopupDialogs.REVATHS_AUCTION_CANCEL = {
        text = "Cancel this auction? A cancellation cost may apply.", button1 = YES, button2 = NO,
        OnAccept = function(_, auctionID)
            local ok, canCancel = pcall(C_AuctionHouse.CanCancelAuction, auctionID)
            if auctionID and ok and canCancel then
                C_AuctionHouse.CancelAuction(auctionID)
            end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
            if tooltip == GameTooltip then AddTooltipPrice() end
        end)
    else
        GameTooltip:HookScript("OnTooltipSetItem", AddTooltipPrice)
    end
    applyAppearance()
    SelectTab("Browse")
    frame:Hide()
end

function ns:ShowForAuctionHouse()
    if not frame or not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return end
    frame:ClearAllPoints()
    if self.db.window.x and self.db.window.y then
        frame:SetPoint("CENTER", UIParent, "CENTER", self.db.window.x, self.db.window.y)
    elseif AuctionHouseFrame:GetRight() and UIParent:GetRight() and UIParent:GetRight() - AuctionHouseFrame:GetRight() > frame:GetWidth() + 20 then
        frame:SetPoint("TOPLEFT", AuctionHouseFrame, "TOPRIGHT", 8, 0)
    else
        frame:SetPoint("TOPRIGHT", AuctionHouseFrame, "TOPLEFT", -8, 0)
    end
    frame:Show()
    SelectTab(activeTab)
end

function ns:Hide() if frame then frame:Hide() end end

function ns:Toggle()
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
        print("|cff2eb8c7Revath's Enchanted Auction House:|r Visit an auctioneer first.")
        return
    end
    if frame:IsShown() then frame:Hide() else self:ShowForAuctionHouse() end
end

function ns:OnBrowseResults()
    if not self.db or not C_AuctionHouse then return end
    local ok, results = pcall(C_AuctionHouse.GetBrowseResults)
    if not ok or type(results) ~= "table" then return end
    browseResults = results
    for i = 1, math.min(#results, 300) do
        local result = results[i]
        local id = result.itemKey and result.itemKey.itemID
        local price = SafeNumber(result.minPrice)
        if id and price then self:RememberPrice(id, ItemName(result.itemKey), price) end
    end
    if refreshBrowse then refreshBrowse() end
    if refreshShopping then refreshShopping() end
    if refreshHistory then refreshHistory() end
    SetStatus(string.format("%d results. Click to buy, right-click to watch.", #results))
end

function ns:RefreshShopping() if refreshShopping then refreshShopping() end end
function ns:RefreshOwned() if refreshOwned then refreshOwned() end end

function RevathsEnchantedAuctionHouse_ApplySettings()
    if ns.db and applyAppearance then applyAppearance() end
end
