local _, ns = ...

local scan = { waiting = false, processing = false, total = 0, index = 0, seen = {} }

local function PlainNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return type(value) == "number" and value or nil
end

local function Report(message)
    if ns.SetStatus then ns:SetStatus(message) end
    if ns.RefreshMarket then ns:RefreshMarket() end
end

function ns:IsMarketScanActive()
    return scan.waiting or scan.processing
end

function ns:StartMarketScan()
    if self:IsMarketScanActive() then Report("A market scan is already running."); return false end
    if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
        Report("Visit an auctioneer before scanning the market."); return false
    end
    if not C_AuctionHouse or not C_AuctionHouse.ReplicateItems then
        Report("Full market scans are unavailable on this client."); return false
    end
    scan.waiting, scan.processing, scan.total, scan.index, scan.seen = true, false, 0, 0, {}
    local ok = pcall(C_AuctionHouse.ReplicateItems)
    if not ok then
        scan.waiting = false
        Report("Full scan is unavailable or throttled. Try again later.")
        return false
    end
    Report("Market scan requested. Waiting for auction data...")
    C_Timer.After(30, function()
        if scan.waiting then
            scan.waiting = false
            Report("No scan results arrived. The full-scan cooldown may still be active.")
        end
    end)
    return true
end

local function FinishScan()
    local now, unique = time(), 0
    for itemID, candidate in pairs(scan.seen) do
        local key = tostring(itemID)
        local record = ns.db.prices[key] or {}
        if not ns.db.prices[key] then ns.db.priceCount = (ns.db.priceCount or 0) + 1 end
        record.name = candidate.name or record.name or ("Item #" .. key)
        record.last = candidate.price
        record.updated = now
        record.source = "Full scan"
        record.points = record.points or {}
        ns.db.prices[key] = record
        unique = unique + 1
    end
    ns.db.marketScan = { at = now, auctions = scan.total, items = unique }
    if (ns.db.priceCount or 0) > 22000 then
        local entries = {}
        for key, record in pairs(ns.db.prices) do
            entries[#entries + 1] = { key = key, updated = record.updated or 0 }
        end
        table.sort(entries, function(a, b) return a.updated > b.updated end)
        for index = 20001, #entries do ns.db.prices[entries[index].key] = nil end
        ns.db.priceCount = math.min(#entries, 20000)
    end
    scan.waiting, scan.processing, scan.seen = false, false, {}
    Report(string.format("Scan complete: %d auctions, %d item values saved.", scan.total, unique))
end

local function ProcessChunk()
    if not scan.processing then return end
    local last = math.min(scan.total - 1, scan.index + 249)
    for index = scan.index, last do
        local ok, name, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID =
            pcall(C_AuctionHouse.GetReplicateItemInfo, index)
        count, buyout, itemID = PlainNumber(count), PlainNumber(buyout), PlainNumber(itemID)
        if ok and itemID and count and count > 0 and buyout and buyout > 0 then
            local unitPrice = math.ceil(buyout / count)
            local candidate = scan.seen[itemID]
            if not candidate or unitPrice < candidate.price then
                scan.seen[itemID] = { name = name, price = unitPrice }
            end
        end
    end
    scan.index = last + 1
    if scan.index < scan.total then
        if scan.index % 2500 == 0 then Report(string.format("Scanning auctions: %d / %d", scan.index, scan.total)) end
        C_Timer.After(0, ProcessChunk)
    else
        FinishScan()
    end
end

function ns:OnReplicateListUpdate()
    if not scan.waiting or scan.processing then return end
    local ok, total = pcall(C_AuctionHouse.GetNumReplicateItems)
    total = ok and PlainNumber(total) or nil
    if not total or total <= 0 then
        scan.waiting = false
        Report("The scan returned no auction data. Try again later.")
        return
    end
    scan.waiting, scan.processing, scan.total, scan.index, scan.seen = false, true, total, 0, {}
    Report(string.format("Scanning %d auctions in small batches...", total))
    ProcessChunk()
end
