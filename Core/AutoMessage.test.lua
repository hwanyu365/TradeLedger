local support = load_source("scripts/test-support.lua")

local function sent() return support.rec.sent end

describe("AutoMessage", function()
    it("TC#20 켜져 있고 메시지가 있을 때만, 채널 조건이 맞을 때만 보낸다", function()
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
        eq(#sent(), 0)
        eq(support.rec.channelLookup, "Trade")

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
            { msg = "t", chatType = "CHANNEL", target = 2 },
        })

        C_ChatInfo.SendChatMessage = function() error("blocked") end
        send({ channel = "TRADE", message = "t", enabled = true })
        raises(function() send({ channel = "GUILD", message = "g", enabled = true }) end, "blocked")
    end)

    it("TC#21 켜진 항목마다 간격(숫자 아니면 60, 1 미만이면 1)의 반복 타이머를 두고, 다시 시작·중지하면 이전 타이머를 끄며, 삭제 뒤 전체 재시작하면 새 순번의 항목을 보낸다", function()
        local ns = support.addon({ guild = true })
        local list = ns.db.autoMessages
        list[1] = { channel = "GUILD", message = "a", enabled = true, interval = 30 }
        list[2] = { channel = "GUILD", message = "b", enabled = false, interval = 30 }
        list[3] = { channel = "GUILD", message = "c", enabled = true, interval = "abc" }
        list[4] = { channel = "GUILD", message = "d", enabled = true, interval = 0 }

        ns:StartAllAutoMessages()
        local t = ns.autoMessageTimers
        eq(t[1].interval, 30)
        eq(t[2], nil)
        eq(t[3].interval, 60)
        eq(t[4].interval, 1)

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
        eq(t[1] ~= nil and t[3] ~= nil and t[4] ~= nil and t[2] == nil, true)

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
