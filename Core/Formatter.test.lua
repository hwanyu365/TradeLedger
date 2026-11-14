local support = load_source("scripts/test-support.lua")

describe("Formatter", function()
    it("TC#11 금액·아이템 목록·완료·취소 채팅 문구 형식", function()
        local ns = support.addon()

        eq(ns:FormatMoney(nil), nil)
        eq(ns:FormatMoney(0), nil)
        eq(ns:FormatMoney(10203), "1g2s3c")
        eq(ns:FormatMoney(10000), "1g")
        eq(ns:FormatMoney(120005), "12g5c")
        eq(ns:FormatMoney(5), "5c")

        local mine = {
            [1] = support.item("Potion", 3, "|cffffffff|Hitem:1|h[Potion]|h|r"),
            [2] = support.item("Ore", 1),
            [8] = support.item("Ignored", 1),
        }
        eq(ns:FormatSuccessChat("Bob", mine, {}, 10203, 0),
            "[TradeLedger] Bob: Sent(|cffffffff|Hitem:1|h[Potion]|h|r x3, Ore, 1g2s3c) / Recv(nothing)")
        eq(ns:FormatSuccessChat("Bob", {}, {}, 0, 50000), "[TradeLedger] Bob: Sent(nothing) / Recv(5g)")
        eq(ns:FormatCancelChat("Bob"), "[TradeLedger] Bob trade cancelled")

        local ko = support.addon({ locale = "koKR" })
        eq(ko:FormatSuccessChat("밥", {}, {}, 0, 0), "[TradeLedger] 밥: 보냄(없음) / 받음(없음)")
    end)
end)
