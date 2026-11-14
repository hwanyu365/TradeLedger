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
