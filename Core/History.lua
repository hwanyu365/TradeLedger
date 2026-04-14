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
