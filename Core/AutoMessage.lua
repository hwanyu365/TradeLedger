local _, ns = ...

ns.autoMessageTimers = {}

ns.AUTO_MSG_INTERVAL_MIN = 10
ns.AUTO_MSG_INTERVAL_MAX = 600
ns.AUTO_MSG_INTERVAL_STEP = 5

-- 거래 같은 공개 채널은 WoW 가 사용자 입력 없이 보낸 메시지를 막는다 → 타이머로 보낼 수 있는 채널만 둔다.
ns.AUTO_MSG_CHANNELS = { "WHISPER", "PARTY", "RAID", "GUILD" }

function ns:IsAutoMessageChannel(channel)
    for _, key in ipairs(self.AUTO_MSG_CHANNELS) do
        if key == channel then return true end
    end
    return false
end

function ns:AutoMessageDialogChannel(entry)
    if entry and self:IsAutoMessageChannel(entry.channel) then return entry.channel end
    return self.AUTO_MSG_CHANNELS[1]
end

function ns:NotifyUnsendableAutoMessages()
    for _, entry in ipairs(self.db.autoMessages) do
        if not self:IsAutoMessageChannel(entry.channel) then
            self:Print(self.L.AUTO_MSG_TRADE_BLOCKED)
            return
        end
    end
end

function ns:BuildAutoMessageEntry(previous, channel, interval, message, target)
    local step = self.AUTO_MSG_INTERVAL_STEP
    interval = math.floor(interval / step + 0.5) * step
    return {
        channel  = channel,
        interval = math.max(self.AUTO_MSG_INTERVAL_MIN, interval),
        message  = message or "",
        enabled  = not previous or previous.enabled ~= false,
        target   = target,
    }
end

function ns:SendAutoMessage(entry)
    if not entry or not entry.enabled then return end
    local msg = entry.message
    if not msg or msg == "" then return end

    local channel = entry.channel
    if channel == "GUILD" and IsInGuild() then
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
    if not entry or not entry.enabled or not self:IsAutoMessageChannel(entry.channel) then return end
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
