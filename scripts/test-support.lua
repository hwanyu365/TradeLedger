-- usage (테스트 파일 안): local support = load_source("scripts/test-support.lua")
-- 테스트 환경 전역에 WoW API 대역을 넣고, TOC 순서대로 UI 를 뺀 파일을 불러온 ns 를 돌려준다.
-- 매 호출마다 새 ns·새 기록 → 테스트끼리 상태가 섞이지 않는다.
local support = {}

function support.stub_wow(opts)
    opts = opts or {}
    local rec = {
        sent = {},        -- { msg, chatType, language, target }
        chat = {},        -- DEFAULT_CHAT_FRAME 출력
        warnings = {},    -- RaidNotice_AddMessage 출력
        timers = {},      -- C_Timer.After 대기열
        tickers = {},     -- C_Timer.NewTicker 로 만든 것
        opened = {},      -- Settings.OpenToCategory 인자
    }
    support.rec = rec
    support.now = opts.now or 1700000000
    support.state = {
        guild = opts.guild or false,
        group = opts.group or false,
        raid = opts.raid or false,
        tradeChannel = 0,
        partnerText = nil,
        playerItems = {}, targetItems = {},  -- [slot] = { name, quantity, link }
        playerMoney = 0, targetMoney = 0,
    }
    local st = support.state

    time = function() return support.now end
    GetLocale = function() return opts.locale or "enUS" end
    wipe = function(t)
        for k in pairs(t) do t[k] = nil end
        return t
    end

    IsInGuild = function() return st.guild end
    IsInGroup = function() return st.group end
    IsInRaid = function() return st.raid end
    GetChannelName = function(name) rec.channelLookup = name; return st.tradeChannel end
    C_ChatInfo = {
        SendChatMessage = function(msg, chatType, language, target)
            rec.sent[#rec.sent + 1] = { msg = msg, chatType = chatType, language = language, target = target }
        end,
    }
    DEFAULT_CHAT_FRAME = {
        AddMessage = function(_, msg, r, g, b) rec.chat[#rec.chat + 1] = { msg = msg, r = r, g = g, b = b } end,
    }
    RaidWarningFrame = {}
    ChatTypeInfo = { RAID_WARNING = { r = 1, g = 0.3, b = 0.1 } }
    RaidNotice_AddMessage = function(frame, msg, info)
        rec.warnings[#rec.warnings + 1] = { frame = frame, msg = msg, info = info }
    end

    C_Timer = {
        After = function(delay, fn) rec.timers[#rec.timers + 1] = { delay = delay, fn = fn } end,
        NewTicker = function(interval, fn)
            local t = { interval = interval, fn = fn, cancelled = false }
            function t:Cancel() self.cancelled = true end
            rec.tickers[#rec.tickers + 1] = t
            return t
        end,
    }

    TradeFrameRecipientNameText = {
        GetText = function() return st.partnerText end,
    }
    GetTradePlayerItemInfo = function(i)
        local it = st.playerItems[i]
        if it then return it.name, nil, it.quantity end
    end
    GetTradePlayerItemLink = function(i) return st.playerItems[i] and st.playerItems[i].link end
    GetTradeTargetItemInfo = function(i)
        local it = st.targetItems[i]
        if it then return it.name, nil, it.quantity end
    end
    GetTradeTargetItemLink = function(i) return st.targetItems[i] and st.targetItems[i].link end
    GetPlayerTradeMoney = function() return st.playerMoney end
    GetTargetTradeMoney = function() return st.targetMoney end

    -- Core/Trade.lua 는 불러올 때 이벤트 프레임을 만든다 → 등록한 이벤트와 OnEvent 를 붙잡는다.
    CreateFrame = function()
        local f = { events = {}, scripts = {} }
        function f:RegisterEvent(e) self.events[e] = true end
        function f:UnregisterEvent(e) self.events[e] = nil end
        function f:SetScript(name, fn) self.scripts[name] = fn end
        rec.frame = f
        return f
    end
    SlashCmdList = {}
    C_AddOns = {
        GetAddOnMetadata = function(name, field)
            rec.metadata = { name, field }
            if name == "TradeLedger" and field == "Version" then return opts.version or "9.9.9" end
        end,
    }
    Settings = { OpenToCategory = function(id) rec.opened[#rec.opened + 1] = id end }

    TradeLedgerDB = opts.db
    TradeAnnounceDB = opts.oldDb
end

-- UI 파일은 프레임 배치가 중심이라 런타임 밖에서 불러오지 않는다 → UI 가 ns 에 넣는 함수는 기록만 하는 대역으로 둔다.
function support.addon(opts)
    opts = opts or {}
    support.stub_wow(opts)
    local ns = {}
    load_source("Init.lua", ns)
    load_source("Locale/enUS.lua", ns)
    load_source("Locale/koKR.lua", ns)
    load_source("Core/Config.lua", ns)
    load_source("Core/Formatter.lua", ns)
    load_source("Core/History.lua", ns)
    load_source("Core/AutoMessage.lua", ns)
    ns.calls = { settings = 0, dialog = {}, historyRefresh = 0 }
    function ns:InitSettings()
        self.calls.settings = self.calls.settings + 1
        if opts.settingsError then error(opts.settingsError) end
        self.settingsCategory = { GetID = function() return "TradeLedgerCategory" end }
    end
    function ns:ShowAutoMessageDialog(index, onSave)
        self.calls.dialog[#self.calls.dialog + 1] = { index = index, onSave = onSave }
    end
    if opts.historyPanel then
        function ns.RefreshHistoryPanel() ns.calls.historyRefresh = ns.calls.historyRefresh + 1 end
    end
    load_source("Core/Trade.lua", ns)
    if opts.load ~= false then
        support.fire("ADDON_LOADED", "TradeLedger")
    end
    return ns
end

function support.fire(event, ...)
    support.rec.frame.scripts.OnEvent(support.rec.frame, event, ...)
end

function support.run_timers()
    local q = support.rec.timers
    support.rec.timers = {}
    for _, t in ipairs(q) do t.fn() end
end

function support.item(name, quantity, link)
    return { name = name, quantity = quantity, link = link }
end

return support
