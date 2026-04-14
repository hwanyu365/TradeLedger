local ADDON_NAME, ns = ...

ns.L = {}
ns.ADDON_NAME = ADDON_NAME

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[TradeLedger]|r " .. msg)
end
