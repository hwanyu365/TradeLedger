local support = load_source("scripts/test-support.lua")

local fire = function(...) support.fire(...) end
local GOLD = 10000

local function open(partner)
    support.state.partnerText = partner
    fire("TRADE_SHOW")
end

local function complete()
    fire("TRADE_ACCEPT_UPDATE", 1, 1)
    fire("TRADE_CLOSED")
end

local function entries(ns) return ns.db.history.entries end

describe("Trade", function()
    it("TC#5 자기 ADDON_LOADED 에서만 초기화하고, 설정 패널이 실패해도 나머지(장부 정리·자동 메시지·로드 안내)는 진행한다", function()
        local ns = support.addon({ load = false })
        eq(support.rec.frame.events.ADDON_LOADED, true)
        fire("ADDON_LOADED", "OtherAddon")
        eq(ns.db, nil)
        eq(ns.calls.settings, 0)

        fire("ADDON_LOADED", "TradeLedger")
        eq(ns.db ~= nil, true)
        eq(ns.calls.settings, 1)
        eq(support.rec.chat[#support.rec.chat].msg, "|cFF00CCFF[TradeLedger]|r v9.9.9 loaded. /tl to open settings.")
        eq(support.rec.frame.events.ADDON_LOADED, nil)
        eq(support.rec.metadata, { "TradeLedger", "Version" })

        ns = support.addon({
            settingsError = "boom",
            now = 1700000000,
            db = {
                history = { entries = { { time = 1, partner = "old" } } },
                autoMessages = { { channel = "GUILD", message = "a", enabled = true, interval = 30 } },
            },
        })
        eq(support.rec.chat[1].msg:find("Settings panel failed", 1, true) ~= nil, true)
        eq(support.rec.chat[1].msg:find("boom", 1, true) ~= nil, true)
        eq(entries(ns), {})
        eq(ns.autoMessageTimers[1].interval, 30)
        eq(support.rec.chat[2].msg, "|cFF00CCFF[TradeLedger]|r v9.9.9 loaded. /tl to open settings.")
    end)

    it("TC#6 거래 상대는 거래창 상대 이름이고, 이름이 없으면 Unknown 이며 귓속말을 보내지 않는다", function()
        local ns = support.addon()
        open("Bob")
        complete()
        eq(support.rec.sent[1].chatType, "WHISPER")
        eq(support.rec.sent[1].target, "Bob")
        eq(entries(ns)[1].partner, "Bob")

        for _, text in ipairs({ "", false }) do
            ns = support.addon()
            open(text or nil)
            complete()
            eq(support.rec.sent, {})
            eq(entries(ns)[1].partner, "Unknown")
        end
    end)

    it("TC#7 거래 중 슬롯·골드 변경을 따라가고, 양쪽 수락 시 아이템이 있는 슬롯과 골드를 다시 읽으며 이벤트 없이 비워진 슬롯은 남는다", function()
        local ns = support.addon()
        local st = support.state
        open("Bob")
        st.playerItems[1] = support.item("Potion", 2, "lp")
        fire("TRADE_PLAYER_ITEM_CHANGED", 1)
        st.playerItems[2] = support.item("Removed", 1)
        fire("TRADE_PLAYER_ITEM_CHANGED", 2)
        st.playerItems[2] = nil
        fire("TRADE_PLAYER_ITEM_CHANGED", 2)
        st.targetItems[4] = support.item("Gem", 1, "lg")
        fire("TRADE_TARGET_ITEM_CHANGED", 4)
        st.playerMoney, st.targetMoney = 5 * GOLD, 0
        fire("TRADE_MONEY_CHANGED")

        st.targetItems[5] = support.item("Gone", 1)
        fire("TRADE_TARGET_ITEM_CHANGED", 5)
        fire("TRADE_ACCEPT_UPDATE", 1, 0)
        st.targetItems[5] = nil
        st.targetItems[6] = support.item("Late", 3)
        st.targetMoney = 7 * GOLD
        fire("TRADE_ACCEPT_UPDATE", 1, 1)
        fire("TRADE_CLOSED")

        local e = entries(ns)[1]
        eq(e.myItems, { [1] = { name = "Potion", quantity = 2 } })
        eq(e.theirItems, { [4] = { name = "Gem", quantity = 1 }, [5] = { name = "Gone", quantity = 1 }, [6] = { name = "Late", quantity = 3 } })
        eq(e.myGold, 5 * GOLD)
        eq(e.theirGold, 7 * GOLD)
        eq(support.rec.sent[1].msg, "[TradeLedger] Bob: Sent(lp x2, 5g) / Recv(lg, Gone, Late x3, 7g)")
    end)

    it("TC#8 양쪽 수락 뒤 창이 닫히면 완료로 한 번 알리고 장부에 성공으로 남긴다. 완료 알림을 끄면 알림·금액 경고·장부 모두 하지 않는다", function()
        local ns = support.addon()
        open("Bob")
        complete()
        fire("TRADE_CLOSED")
        support.run_timers()
        eq(#support.rec.sent, 1)
        eq(support.rec.sent[1].msg, "[TradeLedger] Bob: Sent(nothing) / Recv(nothing)")
        eq(#entries(ns), 1)
        eq(entries(ns)[1].success, true)

        ns = support.addon()
        ns.db.announceSuccess = false
        ns.db.goldThresholdEnabled = true
        support.state.targetMoney = 5000 * GOLD
        open("Bob")
        complete()
        eq(support.rec.sent, {})
        eq(support.rec.warnings, {})
        eq(entries(ns), {})
    end)

    it("TC#9 취소는 취소 이벤트면 즉시, 수락 없이 창이 닫히면 0.1초 뒤 한 번만 알리고 장부에 실패로 남긴다. 취소 알림을 끄면 둘 다 하지 않는다", function()
        local ns = support.addon()
        open("Bob")
        fire("TRADE_REQUEST_CANCEL")
        fire("TRADE_CLOSED")
        support.run_timers()
        eq(#support.rec.sent, 1)
        eq(support.rec.sent[1].msg, "[TradeLedger] Bob trade cancelled")
        eq(entries(ns)[1].success, false)

        ns = support.addon()
        open("Bob")
        fire("TRADE_ACCEPT_UPDATE", 1, 0)
        fire("TRADE_CLOSED")
        eq(#support.rec.sent, 0)
        eq(support.rec.timers[1].delay, 0.1)
        support.run_timers()
        eq(#support.rec.sent, 1)
        eq(#entries(ns), 1)

        ns = support.addon()
        open("Bob")
        fire("TRADE_CLOSED")
        fire("TRADE_REQUEST_CANCEL")
        support.run_timers()
        eq(#support.rec.sent, 1)
        eq(#entries(ns), 1)

        ns = support.addon()
        ns.db.announceCancel = false
        open("Bob")
        fire("TRADE_REQUEST_CANCEL")
        open("Bob")
        fire("TRADE_CLOSED")
        support.run_timers()
        eq(support.rec.sent, {})
        eq(entries(ns), {})
    end)

    it("TC#10 켠 채널 중 길드(소속)·파티(그룹)·공격대(공격대)·귓속말(상대 이름 있음)로 보내고, 본인 대화창에는 출력하지 않는다", function()
        local ns = support.addon({ guild = true, group = true, raid = true })
        for k in pairs(ns.db.channels) do ns.db.channels[k] = true end
        local chatBefore = #support.rec.chat
        open("Bob")
        complete()
        local types = {}
        for i, s in ipairs(support.rec.sent) do types[i] = s.chatType end
        eq(types, { "GUILD", "PARTY", "RAID", "WHISPER" })
        eq(#support.rec.chat, chatBefore)

        ns = support.addon()
        for k in pairs(ns.db.channels) do ns.db.channels[k] = true end
        open(nil)
        complete()
        eq(support.rec.sent, {})

        ns = support.addon({ guild = true, group = true, raid = true })
        for k in pairs(ns.db.channels) do ns.db.channels[k] = false end
        open("Bob")
        complete()
        eq(support.rec.sent, {})
        eq(#entries(ns), 1)
    end)

    it("TC#12 금액 경고는 켜져 있고 기준이 0 보다 클 때, 완료 거래에서 한쪽 골드가 기준 이상이면 큰 쪽 금액으로 띄운다", function()
        local function trade(opts)
            local ns = support.addon()
            ns.db.goldThresholdEnabled = opts.enabled
            ns.db.goldThreshold = opts.threshold
            support.state.playerMoney, support.state.targetMoney = opts.mine, opts.theirs
            open("Bob")
            if opts.cancel then
                fire("TRADE_MONEY_CHANGED")
                fire("TRADE_REQUEST_CANCEL")
            else
                complete()
            end
            return support.rec.warnings
        end

        local w = trade({ enabled = true, threshold = 1000, mine = 2000 * GOLD, theirs = 1000 * GOLD })
        eq(#w, 1)
        eq(w[1].msg, "|cFFFFD700[TradeLedger] High-value trade: 2000g|r")
        eq(w[1].frame, RaidWarningFrame)
        eq(w[1].info, ChatTypeInfo.RAID_WARNING)

        eq(#trade({ enabled = true, threshold = 1000, mine = 0, theirs = 1000 * GOLD }), 1)
        eq(trade({ enabled = true, threshold = 1000, mine = 0, theirs = 1000 * GOLD - 1 }), {})
        eq(trade({ enabled = false, threshold = 1000, mine = 0, theirs = 5000 * GOLD }), {})
        eq(trade({ enabled = true, threshold = 0, mine = 0, theirs = 5000 * GOLD }), {})
        eq(trade({ enabled = true, threshold = 1000, mine = 0, theirs = 5000 * GOLD, cancel = true }), {})
    end)

    it("TC#13 거래 요청 알림을 켜면 요청자 이름을 본인 대화창에 띄운다", function()
        local ns = support.addon()
        local before = #support.rec.chat
        fire("TRADE_REQUEST", "Alice")
        eq(#support.rec.chat, before)

        ns.db.announceIncoming = true
        fire("TRADE_REQUEST", nil)
        eq(#support.rec.chat, before)
        fire("TRADE_REQUEST", "Alice")
        eq(support.rec.chat[#support.rec.chat], { msg = "|cFF00CCFF[TradeLedger]|r Trade request from Alice", r = 0.8, g = 0.8, b = 0.2 })
    end)

    it("TC#29 /tl·/tradeledger: 인자 없음·모르는 인자는 설정 창, add 는 자동 메시지 추가, testdata [N] 은 장부(기본 20건, 최대 개수 안에서)·자동 메시지에 시험 항목을 넣는다", function()
        local ns = support.addon()
        eq(SLASH_TRADELEDGER1, "/tl")
        eq(SLASH_TRADELEDGER2, "/tradeledger")
        local cmd = SlashCmdList.TRADELEDGER

        cmd("")
        cmd("whatever")
        eq(support.rec.opened, { "TradeLedgerCategory", "TradeLedgerCategory" })

        cmd("ADD")
        eq(#ns.calls.dialog, 1)
        eq(ns.calls.dialog[1].index, nil)

        ns.db.history.enabled = false
        cmd("testdata 3")
        eq(#entries(ns), 3)
        eq(ns.db.history.enabled, false)
        eq(#ns.db.autoMessages, 3)
        for _, m in ipairs(ns.db.autoMessages) do eq(m.enabled, false) end
        cmd("testdata 9")
        eq(#ns.db.autoMessages, 8)

        ns = support.addon()
        SlashCmdList.TRADELEDGER("testdata")
        eq(#entries(ns), 20)
        eq(#ns.db.autoMessages, 5)

        ns = support.addon()
        ns.db.history.maxEntries = 3
        ns:SaveTrade("real", {}, {}, 0, 0, true)
        SlashCmdList.TRADELEDGER("testdata 5")
        eq(#entries(ns), 3)
        for _, e in ipairs(entries(ns)) do eq(e.partner ~= "real", true) end
    end)
end)
