local _, ns = ...

local PREFIX = "|cFF00CCFF[TradeLedger]|r"
local PREFIX_PLAIN = "[TradeLedger]"

function ns:FormatMoney(copper)
    if not copper or copper == 0 then return nil end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100
    local parts = {}
    if gold > 0 then parts[#parts + 1] = gold .. "g" end
    if silver > 0 then parts[#parts + 1] = silver .. "s" end
    if cop > 0 then parts[#parts + 1] = cop .. "c" end
    return table.concat(parts, "")
end

local function FormatItemList(items)
    local parts = {}
    for i = 1, 7 do
        local item = items[i]
        if item and item.name then
            local entry = item.link or item.name
            if item.quantity and item.quantity > 1 then
                entry = entry .. " x" .. item.quantity
            end
            parts[#parts + 1] = entry
        end
    end
    return parts
end

function ns:FormatTradeSuccess(partner, myItems, theirItems, myGold, theirGold)
    local L = self.L
    local sentItems = FormatItemList(myItems)
    local recvItems = FormatItemList(theirItems)

    local sentMoney = self:FormatMoney(myGold)
    local recvMoney = self:FormatMoney(theirGold)

    if sentMoney then sentItems[#sentItems + 1] = sentMoney end
    if recvMoney then recvItems[#recvItems + 1] = recvMoney end

    local sentStr = #sentItems > 0 and table.concat(sentItems, ", ") or L.NOTHING
    local recvStr = #recvItems > 0 and table.concat(recvItems, ", ") or L.NOTHING

    return sentStr, recvStr
end

function ns:FormatSuccessLocal(partner, myItems, theirItems, myGold, theirGold)
    local L = self.L
    local sentStr, recvStr = self:FormatTradeSuccess(partner, myItems, theirItems, myGold, theirGold)
    local lines = {}
    lines[#lines + 1] = PREFIX .. " " .. string.format(L.TRADE_COMPLETE, partner)
    lines[#lines + 1] = "  " .. L.SENT .. " -> " .. sentStr
    lines[#lines + 1] = "  " .. L.RECV .. " <- " .. recvStr
    return lines
end

function ns:FormatSuccessChat(partner, myItems, theirItems, myGold, theirGold)
    local L = self.L
    local sentStr, recvStr = self:FormatTradeSuccess(partner, myItems, theirItems, myGold, theirGold)
    return PREFIX_PLAIN .. " " .. partner .. ": " .. L.SENT .. "(" .. sentStr .. ") / " .. L.RECV .. "(" .. recvStr .. ")"
end

function ns:FormatCancelLocal(partner)
    return PREFIX .. " " .. string.format(self.L.TRADE_CANCEL, partner)
end

function ns:FormatCancelChat(partner)
    return PREFIX_PLAIN .. " " .. string.format(self.L.TRADE_CANCEL, partner)
end

function ns:FormatIncomingLocal(name)
    return PREFIX .. " " .. string.format(self.L.TRADE_REQUEST_FROM, name)
end
