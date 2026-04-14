local _, ns = ...

ns.autoMessageTimers = {}

function ns:SendAutoMessage(entry)
    if not entry or not entry.enabled then return end
    local msg = entry.message
    if not msg or msg == "" then return end

    local channel = entry.channel
    if channel == "TRADE" then
        local channelNum = GetChannelName("Trade")
        if channelNum and channelNum > 0 then
            pcall(C_ChatInfo.SendChatMessage, msg, "CHANNEL", nil, channelNum)
        end
    elseif channel == "GUILD" and IsInGuild() then
        C_ChatInfo.SendChatMessage(msg, "GUILD")
    elseif channel == "PARTY" and IsInGroup() then
        C_ChatInfo.SendChatMessage(msg, "PARTY")
    elseif channel == "RAID" and IsInRaid() then
        C_ChatInfo.SendChatMessage(msg, "RAID")
    elseif channel == "WHISPER" and entry.target and entry.target ~= "" then
        C_ChatInfo.SendChatMessage(msg, "WHISPER", nil, entry.target)
    end
end

function ns:StartAutoMessage(index)
    self:StopAutoMessage(index)
    local entry = self.db.autoMessages[index]
    if not entry or not entry.enabled then return end
    local interval = tonumber(entry.interval) or 60
    if interval < 1 then interval = 1 end

    self.autoMessageTimers[index] = C_Timer.NewTicker(interval, function()
        self:SendAutoMessage(entry)
    end)
end

function ns:StopAutoMessage(index)
    if self.autoMessageTimers[index] then
        self.autoMessageTimers[index]:Cancel()
        self.autoMessageTimers[index] = nil
    end
end

function ns:StartAllAutoMessages()
    for i, entry in ipairs(self.db.autoMessages) do
        if entry.enabled then
            self:StartAutoMessage(i)
        end
    end
end

function ns:StopAllAutoMessages()
    for i in pairs(self.autoMessageTimers) do
        self:StopAutoMessage(i)
    end
end

function ns:RestartAllAutoMessages()
    self:StopAllAutoMessages()
    self:StartAllAutoMessages()
end
