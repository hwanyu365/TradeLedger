local ADDON_NAME, ns = ...

local frame = CreateFrame("Frame")

-- Trade state
local tradeState = {
    active = false, partner = "Unknown", bothAccepted = false, cancelled = false,
    myItems = {}, theirItems = {}, myGold = 0, theirGold = 0,
}

local function ResetTradeState()
    tradeState.active       = false
    tradeState.partner      = "Unknown"
    tradeState.bothAccepted = false
    tradeState.cancelled    = false
    tradeState.myItems      = {}
    tradeState.theirItems   = {}
    tradeState.myGold       = 0
    tradeState.theirGold    = 0
end

local function SnapshotAllSlots()
    for i = 1, 7 do
        local name, _, numItems = GetTradePlayerItemInfo(i)
        if name then
            tradeState.myItems[i] = { link = GetTradePlayerItemLink(i), name = name, quantity = numItems or 1 }
        end
        local tName, _, tQty = GetTradeTargetItemInfo(i)
        if tName then
            tradeState.theirItems[i] = { link = GetTradeTargetItemLink(i), name = tName, quantity = tQty or 1 }
        end
    end
    tradeState.myGold    = GetPlayerTradeMoney() or 0
    tradeState.theirGold = GetTargetTradeMoney() or 0
end

-- Announcement
local function SendAnnouncement(localLines, chatMsg)
    local db = ns.db
    if not chatMsg then return end
    if db.channels.GUILD and IsInGuild() then
        C_ChatInfo.SendChatMessage(chatMsg, "GUILD")
    end
    if db.channels.PARTY and IsInGroup() then
        C_ChatInfo.SendChatMessage(chatMsg, "PARTY")
    end
    if db.channels.RAID and IsInRaid() then
        C_ChatInfo.SendChatMessage(chatMsg, "RAID")
    end
    if db.channels.WHISPER and tradeState.partner ~= "Unknown" then
        C_ChatInfo.SendChatMessage(chatMsg, "WHISPER", nil, tradeState.partner)
    end
end

local function CheckGoldThreshold(myGold, theirGold)
    if not ns.db.goldThresholdEnabled then return end
    local threshold = ns.db.goldThreshold
    if threshold <= 0 then return end
    local thresholdCopper = threshold * 10000
    if myGold >= thresholdCopper or theirGold >= thresholdCopper then
        local msg = string.format(ns.L.HIGH_VALUE_TRADE, ns:FormatMoney(math.max(myGold, theirGold)))
        RaidNotice_AddMessage(RaidWarningFrame,
            "|cFFFFD700[TradeLedger] " .. msg .. "|r", ChatTypeInfo["RAID_WARNING"])
    end
end

local function AnnounceSuccess()
    if not ns.db.announceSuccess then return end
    local localLines = ns:FormatSuccessLocal(tradeState.partner, tradeState.myItems, tradeState.theirItems, tradeState.myGold, tradeState.theirGold)
    local chatMsg = ns:FormatSuccessChat(tradeState.partner, tradeState.myItems, tradeState.theirItems, tradeState.myGold, tradeState.theirGold)
    SendAnnouncement(localLines, chatMsg)
    CheckGoldThreshold(tradeState.myGold, tradeState.theirGold)
    ns:SaveTrade(tradeState.partner, tradeState.myItems, tradeState.theirItems, tradeState.myGold, tradeState.theirGold, true)
end

local function AnnounceCancelled()
    if not ns.db.announceCancel then return end
    SendAnnouncement(ns:FormatCancelLocal(tradeState.partner), ns:FormatCancelChat(tradeState.partner))
    ns:SaveTrade(tradeState.partner, tradeState.myItems, tradeState.theirItems, tradeState.myGold, tradeState.theirGold, false)
end

-- Event handlers
local eventHandlers = {
    ADDON_LOADED = function(addonName)
        if addonName ~= ADDON_NAME then return end
        ns:InitDB()
        local ok, err = pcall(ns.InitSettings, ns)
        if not ok then
            ns:Print("|cFFFF0000Settings panel failed: " .. tostring(err) .. "|r")
        end
        ns:PruneHistory()
        ns:StartAllAutoMessages()
        ns:Print(ns.L.LOADED)
        frame:UnregisterEvent("ADDON_LOADED")
    end,

    TRADE_SHOW = function()
        ResetTradeState()
        tradeState.active = true
        if TradeFrameRecipientNameText then
            local name = TradeFrameRecipientNameText:GetText()
            if name and name ~= "" then tradeState.partner = name end
        end
    end,

    TRADE_ACCEPT_UPDATE = function(playerAccepted, targetAccepted)
        if not tradeState.active then return end
        if playerAccepted == 1 and targetAccepted == 1 then
            tradeState.bothAccepted = true
            SnapshotAllSlots()
        end
    end,

    TRADE_CLOSED = function()
        if not tradeState.active then return end
        if tradeState.bothAccepted then
            AnnounceSuccess()
            ResetTradeState()
            return
        end
        C_Timer.After(0.1, function()
            if tradeState.active and not tradeState.cancelled then
                AnnounceCancelled()
                ResetTradeState()
            end
        end)
    end,

    TRADE_REQUEST_CANCEL = function()
        if not tradeState.active then return end
        tradeState.cancelled = true
        AnnounceCancelled()
        ResetTradeState()
    end,

    TRADE_REQUEST = function(name)
        if ns.db.announceIncoming and name then
            DEFAULT_CHAT_FRAME:AddMessage(ns:FormatIncomingLocal(name), 0.8, 0.8, 0.2)
        end
    end,

    TRADE_PLAYER_ITEM_CHANGED = function(slotIndex)
        if not tradeState.active then return end
        local name, _, numItems = GetTradePlayerItemInfo(slotIndex)
        if name then
            tradeState.myItems[slotIndex] = { link = GetTradePlayerItemLink(slotIndex), name = name, quantity = numItems or 1 }
        else
            tradeState.myItems[slotIndex] = nil
        end
    end,

    TRADE_TARGET_ITEM_CHANGED = function(slotIndex)
        if not tradeState.active then return end
        local name, _, quantity = GetTradeTargetItemInfo(slotIndex)
        if name then
            tradeState.theirItems[slotIndex] = { link = GetTradeTargetItemLink(slotIndex), name = name, quantity = quantity or 1 }
        else
            tradeState.theirItems[slotIndex] = nil
        end
    end,

    TRADE_MONEY_CHANGED = function()
        if not tradeState.active then return end
        tradeState.myGold    = GetPlayerTradeMoney() or 0
        tradeState.theirGold = GetTargetTradeMoney() or 0
    end,
}

frame:SetScript("OnEvent", function(self, event, ...)
    local handler = eventHandlers[event]
    if handler then handler(...) end
end)
for event in pairs(eventHandlers) do
    frame:RegisterEvent(event)
end

-- Slash commands
local function HandleSlashCommand(input)
    local args = {}
    for word in input:gmatch("%S+") do args[#args + 1] = word:lower() end
    local cmd = args[1] or ""

    if cmd == "add" then
        ns:ShowAutoMessageDialog(nil, ns.RefreshAutoMessageList)
        return
    end

    -- Default: open settings panel
    Settings.OpenToCategory(ns.settingsCategory:GetID())
end

SLASH_TRADELEDGER1 = "/tl"
SLASH_TRADELEDGER2 = "/tradeledger"
SlashCmdList["TRADELEDGER"] = HandleSlashCommand
