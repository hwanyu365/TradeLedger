local support = load_source("scripts/test-support.lua")

describe("Config", function()
    it("TC#1 TOC 가 TradeLedgerDB 를 SavedVariables 로 선언하고, 로드한 DB 가 그 전역에 묶인다", function()
        local toc = assert(io.open("TradeLedger.toc", "r")):read("*a")
        eq(toc:match("\n## SavedVariables:%s*([^\r\n]+)"), "TradeLedgerDB")

        local ns = support.addon({ db = nil })
        eq(TradeLedgerDB, ns.db)

        local saved = { announceSuccess = false }
        ns = support.addon({ db = saved })
        eq(rawequal(ns.db, saved), true)
        eq(rawequal(TradeLedgerDB, saved), true)
    end)

    it("TC#2 없는 키만 기본값으로 채우고(중첩 포함) 있는 값과 모르는 키는 유지, 옛 채널 SAY·PRINT 는 지운다", function()
        local ns = support.addon({ db = nil })
        eq(ns.db, {
            channels = { WHISPER = true, PARTY = false, RAID = false, GUILD = false },
            announceSuccess = true, announceCancel = true, announceIncoming = false,
            goldThresholdEnabled = false, goldThreshold = 1000,
            autoMessages = {},
            history = { enabled = true, maxEntries = 50, entries = {} },
        })

        local entry = { time = support.now, partner = "Bob", myItems = {}, theirItems = {}, myGold = 0, theirGold = 0, success = true }
        local saved = {
            channels = { WHISPER = false, GUILD = true, SAY = true, PRINT = true },
            goldThreshold = 5000,
            history = { maxEntries = 10, entries = { entry } },
            legacyKey = "kept",
        }
        ns = support.addon({ db = saved })
        eq(ns.db.channels, { WHISPER = false, GUILD = true, PARTY = false, RAID = false })
        eq(ns.db.goldThreshold, 5000)
        eq(ns.db.goldThresholdEnabled, false)
        eq(ns.db.history.maxEntries, 10)
        eq(ns.db.history.enabled, true)
        eq(ns.db.history.entries, { entry })
        eq(ns.db.legacyKey, "kept")
        eq(ns.db.autoMessages, {})
        eq(ns.db.announceSuccess, true)
    end)

    it("TC#3 TradeLedgerDB 가 없고 옛 TradeAnnounceDB 가 있으면 그 표를 옮기고, 둘 다 있으면 TradeLedgerDB 를 쓴다", function()
        local old = { goldThreshold = 77 }
        local ns = support.addon({ db = nil, oldDb = old })
        eq(rawequal(ns.db, old), true)
        eq(TradeAnnounceDB, nil)
        eq(ns.db.goldThreshold, 77)

        local current = { goldThreshold = 1 }
        local old2 = { goldThreshold = 2 }
        ns = support.addon({ db = current, oldDb = old2 })
        eq(rawequal(ns.db, current), true)
        eq(ns.db.goldThreshold, 1)
        eq(rawequal(TradeAnnounceDB, old2), true)
    end)

    it("TC#27 ResetDB 는 같은 표를 비우고 기본값으로 채운다 → 설정·장부·자동 메시지가 모두 기본값", function()
        local ns = support.addon({ db = {
            goldThreshold = 5000,
            channels = { GUILD = true },
            autoMessages = { { channel = "GUILD", message = "hi", enabled = true } },
            history = { enabled = false, entries = { { time = support.now, partner = "Bob" } } },
        } })
        local db = ns.db
        ns:ResetDB()
        eq(rawequal(ns.db, db), true)
        eq(rawequal(TradeLedgerDB, db), true)
        eq(ns.db, ns.DEFAULTS)
        eq(ns.db.history.entries, {})
        eq(ns.db.autoMessages, {})
    end)
end)
