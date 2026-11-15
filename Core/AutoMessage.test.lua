local support = load_source("scripts/test-support.lua")

local function sent() return support.rec.sent end

describe("AutoMessage", function()
    it("TC#20 켜져 있고 메시지가 있을 때만, 채널 조건이 맞을 때만 보내고, 거래 채널에 들어가 있어도 거래 항목은 보내지 않는다", function()
        local ns = support.addon({ guild = true })
        local function send(e) ns:SendAutoMessage(e) end

        send(nil)
        send({ channel = "GUILD", message = "hi", enabled = false })
        send({ channel = "GUILD", message = "", enabled = true })
        send({ channel = "GUILD", enabled = true })
        eq(#sent(), 0)

        support.state.guild = false
        send({ channel = "GUILD", message = "hi", enabled = true })
        send({ channel = "PARTY", message = "hi", enabled = true })
        send({ channel = "RAID", message = "hi", enabled = true })
        send({ channel = "WHISPER", message = "hi", enabled = true, target = "" })
        send({ channel = "WHISPER", message = "hi", enabled = true })
        send({ channel = "SAY", message = "hi", enabled = true })
        send({ channel = "TRADE", message = "hi", enabled = true })
        send({ channel = "UNKNOWN", message = "hi", enabled = true })
        eq(#sent(), 0)

        support.state.guild, support.state.group, support.state.raid = true, true, true
        support.state.tradeChannel = 2
        send({ channel = "GUILD", message = "g", enabled = true })
        send({ channel = "PARTY", message = "p", enabled = true })
        send({ channel = "RAID", message = "r", enabled = true })
        send({ channel = "WHISPER", message = "w", enabled = true, target = "Bob" })
        send({ channel = "TRADE", message = "t", enabled = true })
        eq(sent(), {
            { msg = "g", chatType = "GUILD" },
            { msg = "p", chatType = "PARTY" },
            { msg = "r", chatType = "RAID" },
            { msg = "w", chatType = "WHISPER", target = "Bob" },
        })
        eq(support.rec.channelLookup, nil)

        C_ChatInfo.SendChatMessage = function() error("blocked") end
        raises(function() send({ channel = "GUILD", message = "g", enabled = true }) end, "blocked")
    end)

    it("TC#21 켜진 항목마다(거래 항목 제외) 간격(숫자 아니면 60, 1 미만이면 1)의 반복 타이머를 두고, 다시 시작·중지하면 이전 타이머를 끄며, 삭제 뒤 전체 재시작하면 새 순번의 항목을 보낸다", function()
        local ns = support.addon({ guild = true })
        local list = ns.db.autoMessages
        list[1] = { channel = "GUILD", message = "a", enabled = true, interval = 30 }
        list[2] = { channel = "GUILD", message = "b", enabled = false, interval = 30 }
        list[3] = { channel = "GUILD", message = "c", enabled = true, interval = "abc" }
        list[4] = { channel = "GUILD", message = "d", enabled = true, interval = 0 }
        list[5] = { channel = "TRADE", message = "e", enabled = true, interval = 30 }

        ns:StartAllAutoMessages()
        local t = ns.autoMessageTimers
        eq(t[1].interval, 30)
        eq(t[2], nil)
        eq(t[3].interval, 60)
        eq(t[4].interval, 1)
        eq(t[5], nil)

        t[1].fn()
        eq(support.rec.sent, { { msg = "a", chatType = "GUILD" } })

        local first = t[1]
        ns:StartAutoMessage(1)
        eq(first.cancelled, true)
        eq(t[1].cancelled, false)

        ns:StopAutoMessage(1)
        eq(t[1], nil)

        local third = t[3]
        ns:RestartAllAutoMessages()
        eq(third.cancelled, true)
        eq(t[1] ~= nil and t[3] ~= nil and t[4] ~= nil and t[2] == nil and t[5] == nil, true)

        ns:StopAllAutoMessages()
        eq(next(ns.autoMessageTimers), nil)

        support.rec.sent = {}
        table.remove(list, 1)
        ns:RestartAllAutoMessages()
        eq(ns.autoMessageTimers[1], nil)
        ns.autoMessageTimers[2].fn()
        ns.autoMessageTimers[3].fn()
        eq(support.rec.sent, { { msg = "c", chatType = "GUILD" }, { msg = "d", chatType = "GUILD" } })
    end)
end)

describe("AutoMessage entry", function()
    it("TC#30 저장 값은 간격을 5초 단위로 반올림(최소 10)하고, 새 항목은 켜고 편집은 편집 전 켜짐·꺼짐을 유지한다", function()
        local ns = support.addon()
        eq(ns:BuildAutoMessageEntry(nil, "TRADE", 62, "hi", ""),
            { channel = "TRADE", interval = 60, message = "hi", enabled = true, target = "" })
        eq(ns:BuildAutoMessageEntry(nil, "WHISPER", 63, nil, "Bob"),
            { channel = "WHISPER", interval = 65, message = "", enabled = true, target = "Bob" })
        eq(ns:BuildAutoMessageEntry(nil, "GUILD", 3, "x", "").interval, 10)

        eq(ns:BuildAutoMessageEntry({ enabled = true }, "GUILD", 60, "x", "").enabled, true)
        eq(ns:BuildAutoMessageEntry({ enabled = false }, "GUILD", 60, "x", "").enabled, false)
    end)
end)

describe("AutoMessage channels", function()
    it("TC#33 거래는 보낼 수 있는 채널이 아니고, 편집 대화상자는 그런 항목을 기본 채널로 보여 주며, 로드할 때 거래 항목이 있으면 한 번 안내한다", function()
        local ns = support.addon()
        eq(ns.AUTO_MSG_CHANNELS, { "WHISPER", "PARTY", "RAID", "GUILD" })
        eq(ns:IsAutoMessageChannel("GUILD"), true)
        eq(ns:IsAutoMessageChannel("TRADE"), false)
        eq(ns:AutoMessageDialogChannel(nil), "WHISPER")
        eq(ns:AutoMessageDialogChannel({ channel = "TRADE" }), "WHISPER")
        eq(ns:AutoMessageDialogChannel({ channel = "UNKNOWN" }), "WHISPER")
        eq(ns:AutoMessageDialogChannel({ channel = "GUILD" }), "GUILD")

        local blocked = "|cFF00CCFF[TradeLedger]|r Auto messages to the Trade channel are blocked by WoW and are not sent. Edit them to another channel or delete them."
        local function loaded(opts)
            support.addon(opts)
            local found = 0
            for _, line in ipairs(support.rec.chat) do
                if line.msg:find("Trade channel", 1, true) or line.msg:find("거래 채널", 1, true) then found = found + 1 end
            end
            return found, support.rec.chat[#support.rec.chat].msg
        end

        local guildOnly = { autoMessages = { { channel = "GUILD", message = "g", enabled = true, interval = 60 } } }
        eq((loaded({ db = guildOnly })), 0)

        local withTrade = { autoMessages = {
            { channel = "TRADE", message = "a", enabled = false, interval = 60 },
            { channel = "TRADE", message = "b", enabled = true, interval = 60 },
        } }
        local n, last = loaded({ db = withTrade })
        eq(n, 1)
        eq(last, blocked)

        n, last = loaded({ db = withTrade, locale = "koKR" })
        eq(n, 1)
        eq(last, "|cFF00CCFF[TradeLedger]|r 거래 채널 자동 메시지는 WoW 가 막아 보내지 않습니다. 다른 채널로 편집하거나 삭제하세요.")
    end)
end)
