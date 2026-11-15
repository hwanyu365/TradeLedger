local support = load_source("scripts/test-support.lua")

local DAY = 24 * 60 * 60

describe("History", function()
    it("TC#15 장부 항목은 시각·상대·양쪽 아이템(이름·수량, 링크 없음)·골드(없으면 0)·성공 여부, 장부를 끄면 저장하지 않는다", function()
        local ns = support.addon()
        ns:SaveTrade("Bob",
            { [1] = support.item("Potion", 3, "link1"), [3] = support.item("Ore", 1, "link3"), [8] = support.item("X", 1) },
            { [2] = support.item("Gem", 2, "link2") },
            nil, 50000, true)
        eq(ns.db.history.entries, { {
            time = support.now, partner = "Bob",
            myItems = { [1] = { name = "Potion", quantity = 3 }, [3] = { name = "Ore", quantity = 1 } },
            theirItems = { [2] = { name = "Gem", quantity = 2 } },
            myGold = 0, theirGold = 50000, success = true,
        } })

        ns.db.history.enabled = false
        ns:SaveTrade("Carol", {}, {}, 0, 0, false)
        eq(#ns.db.history.entries, 1)
    end)

    it("TC#16 최대 개수를 넘으면 가장 오래된 항목부터 지운다", function()
        local ns = support.addon()
        eq(ns.db.history.maxEntries, 50)
        ns.db.history.maxEntries = 3
        for i = 1, 5 do ns:SaveTrade("p" .. i, {}, {}, 0, 0, true) end
        local partners = {}
        for i, e in ipairs(ns.db.history.entries) do partners[i] = e.partner end
        eq(partners, { "p3", "p4", "p5" })
    end)

    it("TC#17 로드할 때 7일보다 오래된 항목만 지우고, 그 뒤 저장할 때는 지우지 않는다", function()
        local now = 1700000000
        local function e(name, age) return { time = now - age, partner = name } end
        local ns = support.addon({ now = now, db = { history = { entries = {
            e("old1", 7 * DAY + 1), e("edge", 7 * DAY), e("old2", 30 * DAY), e("new", 0),
        } } } })
        local partners = {}
        for i, x in ipairs(ns.db.history.entries) do partners[i] = x.partner end
        eq(partners, { "edge", "new" })

        table.insert(ns.db.history.entries, 1, e("stale", 30 * DAY))
        ns:SaveTrade("later", {}, {}, 0, 0, true)
        eq(ns.db.history.entries[1].partner, "stale")
        eq(#ns.db.history.entries, 4)
    end)

    it("TC#18 전체 삭제는 장부를 비우고 안내를 출력하며, 장부 패널이 있으면 갱신한다", function()
        local ns = support.addon({ historyPanel = true })
        ns:SaveTrade("Bob", {}, {}, 0, 0, true)
        local before = #support.rec.chat
        ns:ClearHistory()
        eq(ns.db.history.entries, {})
        eq(#support.rec.chat, before + 1)
        eq(support.rec.chat[#support.rec.chat].msg, "|cFF00CCFF[TradeLedger]|r Trade history cleared.")
        eq(ns.calls.historyRefresh, 1)

        local plain = support.addon()
        plain:SaveTrade("Bob", {}, {}, 0, 0, true)
        plain:ClearHistory()
        eq(plain.db.history.entries, {})
    end)
end)

describe("History panel text", function()
    it("TC#35 장부 목록은 최신 순이고, 줄·상세는 시각 형식·결과 색·상대·아이템과 골드 요약을 보여 준다", function()
        local ns = support.addon()
        local t1 = os.time({ year = 2026, month = 11, day = 5, hour = 9, min = 7, sec = 3 })
        local t2 = os.time({ year = 2026, month = 11, day = 15, hour = 21, min = 30, sec = 59 })
        local older = { time = t1, partner = "Bob", success = true, myGold = 10203, theirGold = 0,
            myItems = { [3] = { name = "Ore", quantity = 1 }, [1] = { name = "Potion", quantity = 3 } }, theirItems = {} }
        local newer = { time = t2, success = false, myGold = 0, theirGold = 50000, myItems = {}, theirItems = {} }
        ns.db.history.entries = { older, newer }

        local rows = ns:HistoryRows()
        eq(#rows, 2)
        eq(rows[1].entry, newer)
        eq(rows[2], { entry = older, time = "11/05 09:07", status = "|cFF00FF00OK|r", partner = "Bob",
            sent = "Potion x3, Ore, 1g2s3c", recv = "-" })
        eq(rows[1].status, "|cFFFF0000Cancel|r")
        eq(rows[1].partner, "?")
        eq(rows[1].recv, "5g")

        eq(ns:HistoryDetail(newer), { time = "2026-11-15 21:30:59", status = "|cFFFF0000Cancel|r", partner = "?",
            sent = "-", recv = "5g" })

        ns.db.history.entries = {}
        eq(ns:HistoryRows(), {})

        local ko = support.addon({ locale = "koKR" })
        eq(ko:HistoryDetail(older).status, "|cFF00FF00성공|r")
        eq(ko:HistoryDetail(newer).status, "|cFFFF0000취소|r")
    end)
end)
