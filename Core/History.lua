local _, ns = ...

local SEVEN_DAYS = 7 * 24 * 60 * 60

-- Remove entries older than 7 days
function ns:PruneHistory()
    local entries = self.db.history.entries
    local cutoff = time() - SEVEN_DAYS
    local i = 1
    while i <= #entries do
        if entries[i].time < cutoff then
            table.remove(entries, i)
        else
            i = i + 1
        end
    end
end

function ns:SaveTrade(partner, myItems, theirItems, myGold, theirGold, success)
    if not self.db.history.enabled then return end

    local entry = {
        time       = time(),
        partner    = partner,
        myItems    = {},
        theirItems = {},
        myGold     = myGold or 0,
        theirGold  = theirGold or 0,
        success    = success,
    }

    for i = 1, 7 do
        if myItems[i] and myItems[i].name then
            entry.myItems[i] = { name = myItems[i].name, quantity = myItems[i].quantity }
        end
        if theirItems[i] and theirItems[i].name then
            entry.theirItems[i] = { name = theirItems[i].name, quantity = theirItems[i].quantity }
        end
    end

    local entries = self.db.history.entries
    entries[#entries + 1] = entry
    while #entries > self.db.history.maxEntries do
        table.remove(entries, 1)
    end
end

function ns:ClearHistory()
    self.db.history.entries = {}
    self:Print(self.L.HISTORY_CLEARED)
    if self.RefreshHistoryPanel then self:RefreshHistoryPanel() end
end

function ns:FormatEntryItems(items, gold)
    local parts = {}
    for slot = 1, 7 do
        if items[slot] then
            local s = items[slot].name
            if items[slot].quantity and items[slot].quantity > 1 then
                s = s .. " x" .. items[slot].quantity
            end
            parts[#parts + 1] = s
        end
    end
    local money = self:FormatMoney(gold)
    if money then parts[#parts + 1] = money end
    return #parts > 0 and table.concat(parts, ", ") or "-"
end

local function StatusText(L, success)
    if success then return "|cFF00FF00" .. L.HISTORY_OK .. "|r" end
    return "|cFFFF0000" .. L.HISTORY_FAIL .. "|r"
end

function ns:HistoryDetail(e)
    return {
        time    = date("%Y-%m-%d %H:%M:%S", e.time),
        status  = StatusText(self.L, e.success),
        partner = e.partner or "?",
        sent    = self:FormatEntryItems(e.myItems, e.myGold),
        recv    = self:FormatEntryItems(e.theirItems, e.theirGold),
    }
end

function ns:HistoryRows()
    local entries = self.db.history.entries
    local rows = {}
    for i = #entries, 1, -1 do
        local e = entries[i]
        rows[#rows + 1] = {
            entry   = e,
            time    = date("%m/%d %H:%M", e.time),
            status  = StatusText(self.L, e.success),
            partner = e.partner or "?",
            sent    = self:FormatEntryItems(e.myItems, e.myGold),
            recv    = self:FormatEntryItems(e.theirItems, e.theirGold),
        }
    end
    return rows
end
