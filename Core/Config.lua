local _, ns = ...

local DEFAULTS = {
    channels = {
        PARTY   = false,
        RAID    = false,
        GUILD   = false,
        WHISPER = true,
    },
    announceSuccess  = true,
    announceCancel   = true,
    announceIncoming = false,
    goldThresholdEnabled = false,
    goldThreshold    = 1000,
    autoMessages     = {},
    history = {
        enabled    = true,
        maxEntries = 50,
        entries    = {},
    },
}

local function MergeDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = {}
                MergeDefaults(target[k], v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            MergeDefaults(target[k], v)
        end
    end
end

function ns:InitDB()
    -- Migrate from old TradeAnnounceDB
    if TradeAnnounceDB and not TradeLedgerDB then
        TradeLedgerDB = TradeAnnounceDB
        TradeAnnounceDB = nil
    end
    if not TradeLedgerDB then
        TradeLedgerDB = {}
    end
    if TradeLedgerDB.channels then
        TradeLedgerDB.channels.SAY = nil
        TradeLedgerDB.channels.PRINT = nil
    end
    MergeDefaults(TradeLedgerDB, DEFAULTS)
    self.db = TradeLedgerDB
end

function ns:ResetDB()
    wipe(TradeLedgerDB)
    MergeDefaults(TradeLedgerDB, DEFAULTS)
end

ns.DEFAULTS = DEFAULTS
