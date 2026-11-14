local ADDON_NAME, ns = ...

ns.L = {}
ns.ADDON_NAME = ADDON_NAME
ns.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

function ns:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFF[TradeLedger]|r " .. msg)
end
