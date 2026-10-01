-- Run from the repository root with Lua 5.1+.
local frames, timers = {}, {}
local methods = {}
local function noop() end
local function frame(kind, name)
    local f = setmetatable({ kind = kind, name = name, shown = true, scripts = {}, width = 800, scale = 1 }, { __index = methods })
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
setmetatable(methods, { __index = function() return noop end })
function methods:CreateFontString() return frame('FontString') end
function methods:CreateTexture() return frame('Texture') end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:GetWidth() return self.width end
function methods:SetScale(s) self.scale = s end
function methods:GetEffectiveScale() return self.scale end
function methods:SetText(text) self.text = text end
function methods:GetText() return self.text or '' end
function methods:SetPoint(...) self.point = {...} end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:HookScript(event, fn) self.scripts[event] = fn end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:Show() self.shown = true end
function methods:IsShown() return self.shown end
function methods:SetShown(v) self.shown = v end
function methods:SetQuantity(q) self.quantity = q end
function methods:SetAmount(p) self.amount = p end
CreateFrame = frame
STANDARD_TEXT_FONT = 'font'
NUM_BAG_SLOTS = 4
UIParent = frame('Frame')
GameTooltip = frame('Tooltip')
C_Timer = { After = function(delay, fn) timers[#timers + 1] = {delay, fn} end }
Enum = { BagIndex = { ReagentBag = 5 }, ItemCommodityStatus = { Unknown = 0, Item = 1, Commodity = 2 }, CraftingReagentType = { Basic = 0 } }
AuctionHouseFrameDisplayMode = { CommoditiesSell = 1, ItemSell = 2 }
local bags = {
    [0] = { {itemID = 100, stackCount = 10, hyperlink = 'item:100'}, {itemID = 200, stackCount = 1, hyperlink = 'item:200'} },
    [5] = { {itemID = 101, stackCount = 5, hyperlink = 'item:101'} },
}
C_Container = {
    GetContainerNumSlots = function(bag) return bags[bag] and #bags[bag] or 0 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
}
ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot)
    return {bag = bag, slot = slot, IsEqualTo = function(self, other) return self.bag == other.bag and self.slot == other.slot end}
end }
local held = { [100] = 3 }
C_Item = { GetItemNameByID = function(id) return 'Item ' .. id end, GetItemIconByID = function() return 1 end,
    GetItemCount = function(id) return held[id] or 0 end }
local prices = { [100] = {90, 70}, [101] = {60} }
local itemResults = { {itemKey = {itemID = 200, itemLevel = 20}, buyoutAmount = 10},
    {itemKey = {itemID = 200, itemLevel = 30}, buyoutAmount = 150},
    {itemKey = {itemID = 200, itemLevel = 30}, buyoutAmount = 120} }
local browseResults = {}
C_AuctionHouse = {
    IsSellItemValid = function() return true end,
    GetItemKeyFromItem = function(location) local info = C_Container.GetContainerItemInfo(location.bag, location.slot); return {itemID = info.itemID, itemLevel = info.itemID == 200 and 30 or 0} end,
    GetItemCommodityStatus = function(location) return C_Container.GetContainerItemInfo(location.bag, location.slot).itemID == 200 and 1 or 2 end,
    GetNumCommoditySearchResults = function(id) return #(prices[id] or {}) end,
    GetCommoditySearchResultInfo = function(id, i) return {unitPrice = prices[id][i]} end,
    GetNumItemSearchResults = function() return #itemResults end,
    GetItemSearchResultInfo = function(_, i) return itemResults[i] end,
    GetBrowseResults = function() return browseResults end,
}
AuctionHouseFrame = frame('Frame')
AuctionHouseFrame.SearchBar = frame('Frame')
AuctionHouseFrame.BuyTab = {Click = noop}
AuctionHouseFrame.SellTab = {Click = noop}
function AuctionHouseFrame:GetDisplayMode() return self.mode end
function AuctionHouseFrame:SetPostItem(location)
    self.mode = C_AuctionHouse.GetItemCommodityStatus(location) == 2 and 1 or 2
    local sell = self.mode == 1 and self.CommoditiesSellFrame or self.ItemSellFrame
    sell.location = location
end
local function sellFrame()
    local sell = frame('Frame'); sell.PriceInput = frame('Input'); sell.QuantityInput = frame('Input')
    function sell:GetItem() return self.location end
    function sell:CachePendingPost() end
    return sell
end
AuctionHouseFrame.ItemSellFrame = sellFrame()
AuctionHouseFrame.CommoditiesSellFrame = sellFrame()
AuctionHouseFrame.CommoditiesBuyFrame = frame('Frame')
AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay = frame('Frame')
function AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay:SetQuantitySelected(q) self.quantity = q end
function AuctionHouseFrame:SelectBrowseResult(result) self.opened = result.itemKey.itemID end
function hooksecurefunc(object, method, hook)
    local old = object[method]
    object[method] = function(...) old(...); hook(...) end
end
local tracked = {1, 2}
C_TradeSkillUI = {
    GetRecipesTracked = function() return tracked end,
    GetRecipeSchematic = function(id) return {name = 'Recipe ' .. id, reagentSlotSchematics = {
        {required = true, reagentType = 0, quantityRequired = id == 1 and 5 or 7, reagents = {{itemID = 100}, {itemID = 102}}},
        {required = false, reagentType = 1, quantityRequired = 99, reagents = {{itemID = 999}}},
    }} end,
}
local ns = {db = {shopping = {}, prices = {}, reagentChoices = {}, skin = 'modern'}}
function ns:Money(p) return tostring(p) end
function ns:RememberPrice(id, name, p) self.db.prices[tostring(id)] = {name = name, last = p} end
function ns:WatchItem(id, name) self.db.shopping[tostring(id)] = self.db.shopping[tostring(id)] or {itemID = id, name = name} end
assert(loadfile('RevathsAuctionHouse/Crafting.lua'))('test', ns)
assert(loadfile('RevathsAuctionHouse/Sidecar.lua'))('test', ns)
ns:Initialize(); ns:ShowForAuctionHouse()
local function click(text)
    for _, f in ipairs(frames) do
        if f.kind == 'Button' and f.label and f.label.text == text and f.scripts.OnClick then f.scripts.OnClick(f, 'LeftButton'); return end
    end
    error('No button: ' .. text)
end
local function statusContains(text)
    for _, f in ipairs(frames) do if f.kind == 'FontString' and f.text and f.text:find(text, 1, true) then return true end end
    return false
end
local function runAdvance()
    local pending = timers; timers = {}
    for _, t in ipairs(pending) do if t[1] == .2 then t[2]() end end
end
assert(RevathsAuctionCompanion.height == 190)
assert(RevathsAuctionCompanion.point[3] == 'BOTTOMLEFT')
click('Add all bags'); assert(statusContains('3 stacks queued'))
click('Sell lowest')
ns:OnSellPriceResults('COMMODITY_SEARCH_RESULTS_UPDATED', 101)
assert(AuctionHouseFrame.CommoditiesSellFrame.PriceInput.amount == 0, 'unrelated response must be ignored')
ns:OnSellPriceResults('COMMODITY_SEARCH_RESULTS_UPDATED', 100)
assert(AuctionHouseFrame.CommoditiesSellFrame.PriceInput.amount == 70)
assert(AuctionHouseFrame.CommoditiesSellFrame.QuantityInput.quantity == 10)
ns:OnAuctionCreated(); assert(AuctionHouseFrame.CommoditiesSellFrame:GetItem().slot == 1, 'no advance without native post')
local sell = AuctionHouseFrame.CommoditiesSellFrame
sell:CachePendingPost(sell:GetItem(), 1, 10)
bags[0][1] = nil
ns:OnAuctionCreated(); runAdvance()
assert(AuctionHouseFrame.mode == 2)
local full, requested = false, false
C_AuctionHouse.HasFullItemSearchResults = function() return full end
C_AuctionHouse.RequestMoreItemSearchResults = function() requested = true end
local equipmentKey = {itemID = 200, itemLevel = 30}
ns:OnSellPriceResults('ITEM_SEARCH_RESULTS_UPDATED', equipmentKey)
assert(requested and AuctionHouseFrame.ItemSellFrame.PriceInput.amount == 0, 'wait for full equipment prices')
full = true
ns:OnSellPriceResults('ITEM_SEARCH_RESULTS_ADDED', equipmentKey)
assert(AuctionHouseFrame.ItemSellFrame.PriceInput.amount == 120, 'match equipment level')
sell = AuctionHouseFrame.ItemSellFrame
sell:CachePendingPost(sell:GetItem(), 1, 1)
ns:OnAuctionCreated(); runAdvance()
ns:OnSellPriceResults('COMMODITY_SEARCH_RESULTS_UPDATED', 101)
assert(AuctionHouseFrame.CommoditiesSellFrame.PriceInput.amount == 60, 'advance to reagent bag')
click('Stop'); ns:OnAuctionCreated(); assert(statusContains('Stopped. Sell queue kept.'))
click('Clear queue')
click('› Sell') -- no tab switch; exercise queue reset
click('Buy')
click('Add tracked recipes')
assert(ns.db.shopping['100'].quantity == 9, '5 + 7 required minus 3 held')
assert(ns.db.shopping['999'] == nil, 'optional reagents excluded')
click('Add tracked recipes'); assert(ns.db.shopping['100'].quantity == 9, 'repeat import is idempotent')
local itemBox, quantityBox
for _, f in ipairs(frames) do
    if f.kind == 'EditBox' then if f.width == 228 then itemBox = f elseif f.width == 54 then quantityBox = f end end
end
itemBox:SetText('item:100'); quantityBox:SetText('4'); click('Add item')
assert(ns.db.shopping['100'].quantity == 13)
click('Add tracked recipes'); assert(ns.db.shopping['100'].quantity == 13, 'manual quantities preserved')
held[100] = 20; click('Add tracked recipes'); assert(ns.db.shopping['100'].quantity == 4)
tracked = {}; click('Add tracked recipes'); assert(ns.db.shopping['100'].quantity == 4)
quantityBox:SetText('-1'); click('Add item'); assert(ns.db.shopping['100'].quantity == 4, 'reject invalid quantity')
click('Find in Buy'); browseResults = {{itemKey = {itemID = 999}}, {itemKey = {itemID = 100}}}
ns:OnBrowseResults()
assert(AuctionHouseFrame.opened == 100, 'open exact quality item')
assert(AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.quantity == 4)
AuctionHouseFrame.opened = nil; ns:OnBrowseResults(); assert(rawget(AuctionHouseFrame, 'opened') == nil, 'ignore later browse events')
click('Done / next'); assert(ns.db.shopping['100'] == nil)
click('Sell'); click('Add all bags'); click('Sell lowest')
local key = {itemID = 200, itemLevel = 30}
itemResults = {}; ns:OnSellPriceResults('ITEM_SEARCH_RESULTS_UPDATED', key)
assert(statusContains('No live buyout found. Queue kept'))
click('Sell lowest'); click('Stop'); ns:OnSellPriceResults('ITEM_SEARCH_RESULTS_UPDATED', key)
assert(statusContains('Stopped. Sell queue kept.'))
click('Sell lowest'); bags[0][2].stackCount = 2
ns:OnSellPriceResults('ITEM_SEARCH_RESULTS_UPDATED', key)
assert(statusContains('Sell selection changed'))
click('Clear queue'); click('Add all bags'); click('Sell lowest')
itemResults = {{itemKey = key, buyoutAmount = 120}}
ns:OnSellPriceResults('ITEM_SEARCH_RESULTS_UPDATED', key)
sell = AuctionHouseFrame.ItemSellFrame
sell:CachePendingPost(sell:GetItem(), 1, 2)
ns:OnAuctionCreated(); runAdvance()
assert(AuctionHouseFrame.mode == 2, 'wait for all multisell auctions')
ns:OnAuctionCreated(); runAdvance()
assert(AuctionHouseFrame.mode == 1, 'advance after entire multisell')
ns:Hide(); ns:OnSellPriceResults('COMMODITY_SEARCH_RESULTS_UPDATED', 101)
assert(not RevathsAuctionCompanion:IsShown())
print('Auction companion tests passed: docking, queues, live pricing, confirmation, recipe aggregation, repeat imports, and buying quantities.')
