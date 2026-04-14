local _, ns = ...

---------------------------------------------------------------------------
-- Layout constants (shared across all panels)
---------------------------------------------------------------------------
local MARGIN           = 16
local INDENT           = 24
local TITLE_Y          = -16
local CONTENT_Y        = -46
local CHECKBOX_SPACING = 28
local ROW_HEIGHT       = 22
local TITLE_BTN_Y      = -12
local TITLE_BTN_W      = 80
local TITLE_BTN_H      = 26
local SCROLL_RIGHT     = -30
local FALLBACK_WIDTH   = 500
local SEP_COLOR        = { 0.5, 0.5, 0.5, 0.5 }

-- Font constants
local FONT_TITLE       = "GameFontNormalLarge"
local FONT_HEADER      = "GameFontNormal"
local FONT_DATA        = "GameFontHighlightSmall"
local FONT_HIGHLIGHT   = "GameFontHighlight"

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function CreateCheckbox(parent, x, y, text, tooltip, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(text)
    cb.Text:ClearAllPoints()
    cb.Text:SetPoint("LEFT", cb, "RIGHT", 3, 0)
    cb:SetScript("OnClick", function(self) setter(self:GetChecked()) end)
    if tooltip then cb.tooltipText = tooltip end
    cb._getter = getter
    return cb
end

local function CreateSmallButton(parent, width, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, ROW_HEIGHT)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function MakeHeader(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "ARTWORK", FONT_HEADER)
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function MakeSeparator(parent, x, y)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", x, y)
    sep:SetPoint("RIGHT", parent, "RIGHT", -MARGIN, 0)
    sep:SetColorTexture(unpack(SEP_COLOR))
    return sep
end

local function SetScrollChildWidth(scrollFrame, scrollChild)
    local w = scrollFrame:GetWidth()
    scrollChild:SetWidth((w and w > 0) and w or FALLBACK_WIDTH)
end

function ns:InitSettings()
    local L = self.L
    local db = self.db

    ---------------------------------------------------------------------------
    -- Main category (landing page)
    ---------------------------------------------------------------------------
    local mainPanel = CreateFrame("Frame")
    local mainTitle = mainPanel:CreateFontString(nil, "ARTWORK", FONT_TITLE)
    mainTitle:SetPoint("TOPLEFT", MARGIN, TITLE_Y)
    mainTitle:SetText("TradeLedger v1.0.0")

    local mainDesc = mainPanel:CreateFontString(nil, "ARTWORK", FONT_HIGHLIGHT)
    mainDesc:SetPoint("TOPLEFT", MARGIN, -44)
    mainDesc:SetText(L.SUCCESS_ALERTS_TIP)

    -- Confirm dialogs
    StaticPopupDialogs["TRADELEDGER_RESET_CONFIRM"] = {
        text = L.SETTINGS_RESET_CONFIRM,
        button1 = YES, button2 = NO,
        OnAccept = function()
            ns:StopAllAutoMessages()
            ns:ResetDB()
            ns:Print(L.SETTINGS_RESET)
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }

    StaticPopupDialogs["TRADELEDGER_CLEAR_HISTORY_CONFIRM"] = {
        text = L.HISTORY_CLEAR_CONFIRM,
        button1 = YES, button2 = NO,
        OnAccept = function()
            ns:ClearHistory()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true,
    }

    local resetBtn = CreateFrame("Button", nil, mainPanel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, TITLE_BTN_H)
    resetBtn:SetPoint("TOPLEFT", MARGIN, -80)
    resetBtn:SetText(L.SETTINGS_RESET_BTN)
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("TRADELEDGER_RESET_CONFIRM")
    end)

    local mainCategory = Settings.RegisterCanvasLayoutCategory(mainPanel, "TradeLedger")


    ---------------------------------------------------------------------------
    -- Subcategory 1: Trade Alerts
    ---------------------------------------------------------------------------
    local tradePanel = CreateFrame("Frame")
    local tradeCheckboxes = {}
    local editBox

    local function AddTradeCheckbox(x, y, text, tooltip, getter, setter)
        local cb = CreateCheckbox(tradePanel, x, y, text, tooltip, getter, setter)
        tradeCheckboxes[#tradeCheckboxes + 1] = cb
        return cb
    end

    local tradeTitle = tradePanel:CreateFontString(nil, "ARTWORK", FONT_TITLE)
    tradeTitle:SetPoint("TOPLEFT", MARGIN, TITLE_Y)
    tradeTitle:SetText(L.TAB_TRADE_ALERTS)

    local y = CONTENT_Y

    AddTradeCheckbox(MARGIN, y,
        L.SUCCESS_ALERTS, L.SUCCESS_ALERTS_TIP,
        function() return db.announceSuccess end,
        function(v) db.announceSuccess = v end)
    y = y - CHECKBOX_SPACING

    local channelDefs = {
        { key = "WHISPER", name = L.WHISPER_CHANNEL, tip = L.WHISPER_TIP },
        { key = "PARTY",   name = L.PARTY_CHANNEL,   tip = L.PARTY_TIP },
        { key = "RAID",    name = L.RAID_CHANNEL,     tip = L.RAID_TIP },
        { key = "GUILD",   name = L.GUILD_CHANNEL,    tip = L.GUILD_TIP },
    }
    for _, def in ipairs(channelDefs) do
        AddTradeCheckbox(MARGIN + INDENT, y,
            def.name, def.tip,
            function() return db.channels[def.key] end,
            function(v) db.channels[def.key] = v end)
        y = y - CHECKBOX_SPACING
    end

    AddTradeCheckbox(MARGIN, y,
        L.CANCEL_ALERTS, L.CANCEL_ALERTS_TIP,
        function() return db.announceCancel end,
        function(v) db.announceCancel = v end)
    y = y - CHECKBOX_SPACING

    AddTradeCheckbox(MARGIN, y,
        L.INCOMING_ALERTS, L.INCOMING_TIP,
        function() return db.announceIncoming end,
        function(v) db.announceIncoming = v end)
    y = y - CHECKBOX_SPACING

    AddTradeCheckbox(MARGIN, y,
        L.GOLD_THRESHOLD, L.GOLD_THRESHOLD_TIP,
        function() return db.goldThresholdEnabled end,
        function(v) db.goldThresholdEnabled = v end)
    y = y - CHECKBOX_SPACING

    local MAX_GOLD = 10000000

    editBox = CreateFrame("EditBox", nil, tradePanel, "InputBoxTemplate")
    editBox:SetSize(90, ROW_HEIGHT)
    editBox:SetPoint("TOPLEFT", MARGIN + INDENT, y)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(8)

    local unitLabel = tradePanel:CreateFontString(nil, "ARTWORK", FONT_HIGHLIGHT)
    unitLabel:SetPoint("LEFT", editBox, "RIGHT", 4, 0)
    unitLabel:SetText(L.GOLD_UNIT)

    local displayLabel = tradePanel:CreateFontString(nil, "ARTWORK", FONT_HIGHLIGHT)
    displayLabel:SetPoint("LEFT", editBox, "LEFT", 4, 0)

    local function FormatWithCommas(n)
        local s = tostring(n)
        local pos = #s % 3
        if pos == 0 then pos = 3 end
        local parts = { s:sub(1, pos) }
        for i = pos + 1, #s, 3 do
            parts[#parts + 1] = s:sub(i, i + 2)
        end
        return table.concat(parts, ",")
    end

    local function ShowFormatted()
        displayLabel:SetText(FormatWithCommas(db.goldThreshold))
        displayLabel:Show()
        editBox:Hide()
    end

    local function ShowEditable()
        displayLabel:Hide()
        editBox:SetNumber(db.goldThreshold)
        editBox:Show()
    end

    local function UpdateThreshold(newVal)
        newVal = math.min(MAX_GOLD, math.max(0, math.floor(newVal)))
        db.goldThreshold = newVal
        if editBox:IsShown() and editBox:HasFocus() then
            editBox:SetNumber(newVal)
        else
            ShowFormatted()
        end
    end

    local function CommitEditBox()
        UpdateThreshold(editBox:GetNumber() or 0)
    end

    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        if (self:GetNumber() or 0) > MAX_GOLD then self:SetNumber(MAX_GOLD) end
    end)
    editBox:SetScript("OnEnterPressed", function(self) CommitEditBox(); self:ClearFocus(); ShowFormatted() end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); ShowFormatted() end)
    editBox:SetScript("OnEditFocusLost", function(self) CommitEditBox(); ShowFormatted() end)

    local clickOverlay = CreateFrame("Button", nil, tradePanel)
    clickOverlay:SetAllPoints(editBox)
    clickOverlay:SetScript("OnClick", function() ShowEditable(); editBox:SetFocus() end)
    clickOverlay:SetFrameLevel(editBox:GetFrameLevel() + 10)

    local increments = {
        { val = 1000,    label = L.BTN_1K },
        { val = 10000,   label = L.BTN_10K },
        { val = 100000,  label = L.BTN_100K },
        { val = 1000000, label = L.BTN_1M },
    }
    local INC_BTN_W = 54
    local INC_BTN_GAP = 58
    for i, inc in ipairs(increments) do
        local x = MARGIN + INDENT + 115 + (i - 1) * INC_BTN_GAP
        CreateSmallButton(tradePanel, INC_BTN_W, "+" .. inc.label, function() UpdateThreshold(db.goldThreshold + inc.val) end)
            :SetPoint("TOPLEFT", x, y)
        CreateSmallButton(tradePanel, INC_BTN_W, "-" .. inc.label, function() UpdateThreshold(db.goldThreshold - inc.val) end)
            :SetPoint("TOPLEFT", x, y - CHECKBOX_SPACING)
    end

    -- Refresh
    local function RefreshTradePanel()
        for _, cb in ipairs(tradeCheckboxes) do
            cb:SetChecked(cb._getter())
        end
        ShowFormatted()
    end

    local tradePanelDirty = true
    tradePanel:SetScript("OnShow", function() tradePanelDirty = true end)
    tradePanel:SetScript("OnUpdate", function()
        if tradePanelDirty then tradePanelDirty = false; RefreshTradePanel() end
    end)

    
    ---------------------------------------------------------------------------
    -- Subcategory 2: Trade History
    ---------------------------------------------------------------------------
    local historyPanel = CreateFrame("Frame")

    local histTitle = historyPanel:CreateFontString(nil, "ARTWORK", FONT_TITLE)
    histTitle:SetPoint("TOPLEFT", MARGIN, TITLE_Y)
    histTitle:SetText(L.TAB_HISTORY)

    -- Title row: [checkbox text] [clear btn] right-aligned
    local clearBtn = CreateFrame("Button", nil, historyPanel, "UIPanelButtonTemplate")
    clearBtn:SetSize(TITLE_BTN_W, TITLE_BTN_H)
    clearBtn:SetPoint("TOPRIGHT", historyPanel, "TOPRIGHT", -MARGIN, TITLE_BTN_Y)
    clearBtn:SetText(L.HISTORY_CLEAR_BTN)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("TRADELEDGER_CLEAR_HISTORY_CONFIRM")
    end)

    local histCbLabel = historyPanel:CreateFontString(nil, "ARTWORK", FONT_HEADER)
    histCbLabel:SetPoint("RIGHT", clearBtn, "LEFT", -10, 0)
    histCbLabel:SetText(L.HISTORY_TOGGLE)

    local histCheckbox = CreateFrame("CheckButton", nil, historyPanel, "InterfaceOptionsCheckButtonTemplate")
    histCheckbox:SetPoint("RIGHT", histCbLabel, "LEFT", -2, 0)
    histCheckbox.Text:SetText("")
    histCheckbox:SetChecked(false)
    histCheckbox:SetScript("OnClick", function(self)
        db.history.enabled = self:GetChecked()
    end)
    histCheckbox._getter = function() return db.history.enabled end

    -- Column layout
    local HIST_HDR_Y = CONTENT_Y
    local FIXED_WIDTH = 230

    MakeHeader(historyPanel, MARGIN,       HIST_HDR_Y, L.HISTORY_COL_TIME)
    MakeHeader(historyPanel, MARGIN + 90,  HIST_HDR_Y, L.HISTORY_COL_STATUS)
    MakeHeader(historyPanel, MARGIN + 140, HIST_HDR_Y, L.HISTORY_COL_PARTNER)

    -- Split frame for Sent/Recv headers (1:1)
    local hdrSplit = CreateFrame("Frame", nil, historyPanel)
    hdrSplit:SetPoint("TOPLEFT", historyPanel, "TOPLEFT", MARGIN + FIXED_WIDTH, HIST_HDR_Y)
    hdrSplit:SetPoint("RIGHT", historyPanel, "RIGHT", -MARGIN - 16, 0)
    hdrSplit:SetHeight(16)

    local sentHdr = hdrSplit:CreateFontString(nil, "ARTWORK", FONT_HEADER)
    sentHdr:SetPoint("LEFT", hdrSplit, "LEFT", 0, 0)
    sentHdr:SetText(L.SENT)

    local recvHdr = hdrSplit:CreateFontString(nil, "ARTWORK", FONT_HEADER)
    recvHdr:SetPoint("LEFT", hdrSplit, "CENTER", 4, 0)
    recvHdr:SetText(L.RECV)

    MakeSeparator(historyPanel, MARGIN, HIST_HDR_Y - 16)

    local histNoEntries = historyPanel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    histNoEntries:SetPoint("TOPLEFT", MARGIN, HIST_HDR_Y - 30)
    histNoEntries:SetText(L.HISTORY_NO_ENTRIES)

    -- Detail divider + scrollable detail area at bottom
    local DETAIL_HEIGHT = 140

    local detailDivider = historyPanel:CreateTexture(nil, "ARTWORK")
    detailDivider:SetHeight(1)
    detailDivider:SetPoint("LEFT", historyPanel, "LEFT", MARGIN, 0)
    detailDivider:SetPoint("RIGHT", historyPanel, "RIGHT", -MARGIN, 0)
    detailDivider:SetPoint("BOTTOM", historyPanel, "BOTTOM", 0, DETAIL_HEIGHT + 10)
    detailDivider:SetColorTexture(unpack(SEP_COLOR))

    -- Detail scroll area
    local detailScroll = CreateFrame("ScrollFrame", nil, historyPanel, "UIPanelScrollFrameTemplate")
    detailScroll:SetPoint("TOPLEFT", detailDivider, "BOTTOMLEFT", 0, -10)
    detailScroll:SetPoint("BOTTOMRIGHT", historyPanel, "BOTTOMRIGHT", SCROLL_RIGHT, 8)

    local detailChild = CreateFrame("Frame")
    detailScroll:SetScrollChild(detailChild)

    local detailEmpty = historyPanel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    detailEmpty:SetPoint("TOP", detailDivider, "BOTTOM", 0, -30)
    detailEmpty:SetText(L.HISTORY_NO_SELECTION)

    -- Detail labels and values
    local DLBL_W = 50
    local DY_STEP = 18

    local function MakeDetailRow(parent, labelText, yOffset)
        local lbl = parent:CreateFontString(nil, "ARTWORK", FONT_HEADER)
        lbl:SetPoint("TOPLEFT", 0, yOffset)
        lbl:SetWidth(DLBL_W)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(labelText)
        lbl:Hide()

        local val = parent:CreateFontString(nil, "ARTWORK", FONT_HIGHLIGHT)
        val:SetPoint("TOPLEFT", DLBL_W + 6, yOffset)
        val:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        val:SetJustifyH("LEFT")
        val:SetWordWrap(false)
        val:Hide()

        return lbl, val
    end

    local dTimeLbl,    dTimeVal    = MakeDetailRow(detailChild, L.HISTORY_COL_TIME, 0)
    local dStatusLbl,  dStatusVal  = MakeDetailRow(detailChild, L.HISTORY_COL_STATUS, -DY_STEP)
    local dPartnerLbl, dPartnerVal = MakeDetailRow(detailChild, L.HISTORY_COL_PARTNER, -DY_STEP * 2)
    local dSentLbl,    dSentVal    = MakeDetailRow(detailChild, L.SENT, -DY_STEP * 3)
    dSentVal:SetWordWrap(true)
    local dRecvLbl,    dRecvVal    = MakeDetailRow(detailChild, L.RECV, 0)

    local allDetailWidgets = {
        dTimeLbl, dTimeVal, dStatusLbl, dStatusVal,
        dPartnerLbl, dPartnerVal, dSentLbl, dSentVal,
        dRecvLbl, dRecvVal,
    }

    local function FormatEntryItems(items, gold)
        local parts = {}
        for slot = 1, 7 do
            if items[slot] then
                local s = items[slot].name
                if items[slot].quantity and items[slot].quantity > 1 then
                    s = s .. " x" .. items[slot].quantity
                end
                parts[#parts + 1] = s
            end
        end
        local money = ns:FormatMoney(gold)
        if money then parts[#parts + 1] = money end
        return #parts > 0 and table.concat(parts, ", ") or "-"
    end

    local function ShowDetail(e)
        detailEmpty:Hide()
        for _, w in ipairs(allDetailWidgets) do w:Show() end

        SetScrollChildWidth(detailScroll, detailChild)

        dTimeVal:SetText(date("%Y-%m-%d %H:%M:%S", e.time))
        if e.success then
            dStatusVal:SetText("|cFF00FF00" .. L.HISTORY_OK .. "|r")
        else
            dStatusVal:SetText("|cFFFF0000" .. L.HISTORY_FAIL .. "|r")
        end
        dPartnerVal:SetText(e.partner or "?")
        dSentVal:SetText(FormatEntryItems(e.myItems, e.myGold))

        dRecvLbl:ClearAllPoints()
        dRecvVal:ClearAllPoints()
        dRecvLbl:SetPoint("TOPLEFT", dSentVal, "BOTTOMLEFT", -(DLBL_W + 6), -6)
        dRecvVal:SetPoint("TOPLEFT", dSentVal, "BOTTOMLEFT", 0, -6)
        dRecvVal:SetPoint("RIGHT", detailChild, "RIGHT", 0, 0)
        dRecvVal:SetWordWrap(true)
        dRecvVal:SetText(FormatEntryItems(e.theirItems, e.theirGold))

        C_Timer.After(0, function()
            local bottom = -(dRecvVal:GetBottom() or 0) + (detailChild:GetTop() or 0) + 10
            detailChild:SetHeight(math.max(bottom, DETAIL_HEIGHT - 20))
        end)
    end

    local function ClearDetail()
        detailEmpty:Show()
        for _, w in ipairs(allDetailWidgets) do w:Hide() end
        detailChild:SetHeight(1)
    end

    -- ScrollFrame for list entries (above detail divider)
    local histScroll = CreateFrame("ScrollFrame", nil, historyPanel, "UIPanelScrollFrameTemplate")
    histScroll:SetPoint("TOPLEFT", MARGIN, HIST_HDR_Y - 20)
    histScroll:SetPoint("RIGHT", historyPanel, "RIGHT", SCROLL_RIGHT, 0)
    histScroll:SetPoint("BOTTOM", detailDivider, "TOP", 0, 8)

    local scrollChild = CreateFrame("Frame")
    histScroll:SetScrollChild(scrollChild)

    local historyRows = {}
    local selectedRowBg = nil

    local function RefreshHistoryPanel()
        for _, row in ipairs(historyRows) do row:Hide(); row:SetParent(nil) end
        wipe(historyRows)
        ClearDetail()

        histCheckbox:SetChecked(db.history.enabled)

        local entries = db.history.entries
        local count = #entries

        if count == 0 then
            histNoEntries:Show()
            scrollChild:SetSize(1, 1)
            return
        end
        histNoEntries:Hide()

        SetScrollChildWidth(histScroll, scrollChild)
        scrollChild:SetHeight(math.max(1, count * ROW_HEIGHT))

        for displayIdx = 1, count do
            local e = entries[count - displayIdx + 1]
            local row = CreateFrame("Button", nil, scrollChild)
            row:SetHeight(ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -(displayIdx - 1) * ROW_HEIGHT)
            row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

            local rowBg = row:CreateTexture(nil, "BACKGROUND")
            rowBg:SetAllPoints()
            rowBg:SetColorTexture(1, 1, 1, 0)

            row:SetScript("OnEnter", function()
                if selectedRowBg ~= rowBg then rowBg:SetColorTexture(1, 1, 1, 0.08) end
            end)
            row:SetScript("OnLeave", function()
                if selectedRowBg ~= rowBg then rowBg:SetColorTexture(1, 1, 1, 0) end
            end)
            row:SetScript("OnClick", function()
                if selectedRowBg and selectedRowBg ~= rowBg then
                    selectedRowBg:SetColorTexture(1, 1, 1, 0)
                end
                selectedRowBg = rowBg
                rowBg:SetColorTexture(0.3, 0.5, 0.8, 0.3)
                ShowDetail(e)
            end)

            local timeText = row:CreateFontString(nil, "ARTWORK", FONT_DATA)
            timeText:SetPoint("LEFT", 0, 0)
            timeText:SetText(date("%m/%d %H:%M", e.time))

            local statusText = row:CreateFontString(nil, "ARTWORK", FONT_DATA)
            statusText:SetPoint("LEFT", 90, 0)
            if e.success then
                statusText:SetText("|cFF00FF00" .. L.HISTORY_OK .. "|r")
            else
                statusText:SetText("|cFFFF0000" .. L.HISTORY_FAIL .. "|r")
            end

            local partnerText = row:CreateFontString(nil, "ARTWORK", FONT_DATA)
            partnerText:SetPoint("LEFT", 140, 0)
            partnerText:SetWidth(80)
            partnerText:SetJustifyH("LEFT")
            partnerText:SetWordWrap(false)
            partnerText:SetText(e.partner or "?")

            -- Split frame for 1:1 Sent/Recv
            local splitFrame = CreateFrame("Frame", nil, row)
            splitFrame:SetPoint("LEFT", FIXED_WIDTH, 0)
            splitFrame:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            splitFrame:SetHeight(ROW_HEIGHT)

            local sentText = splitFrame:CreateFontString(nil, "ARTWORK", FONT_DATA)
            sentText:SetPoint("LEFT", splitFrame, "LEFT", 0, 0)
            sentText:SetPoint("RIGHT", splitFrame, "CENTER", -4, 0)
            sentText:SetJustifyH("LEFT")
            sentText:SetWordWrap(false)
            sentText:SetMaxLines(1)
            sentText:SetText(FormatEntryItems(e.myItems, e.myGold))

            local recvText = splitFrame:CreateFontString(nil, "ARTWORK", FONT_DATA)
            recvText:SetPoint("LEFT", splitFrame, "CENTER", 4, 0)
            recvText:SetPoint("RIGHT", splitFrame, "RIGHT", 0, 0)
            recvText:SetJustifyH("LEFT")
            recvText:SetWordWrap(false)
            recvText:SetMaxLines(1)
            recvText:SetText(FormatEntryItems(e.theirItems, e.theirGold))

            historyRows[#historyRows + 1] = row
        end
    end

    ns.RefreshHistoryPanel = RefreshHistoryPanel

    local historyPanelDirty = true
    historyPanel:SetScript("OnShow", function() historyPanelDirty = true end)
    historyPanel:SetScript("OnUpdate", function()
        if historyPanelDirty then historyPanelDirty = false; RefreshHistoryPanel() end
    end)
    histScroll:SetScript("OnSizeChanged", function()
        historyPanelDirty = true
    end)


    ---------------------------------------------------------------------------
    -- Subcategory 3: Auto Message
    ---------------------------------------------------------------------------
    local autoPanel = CreateFrame("Frame")

    local autoTitle = autoPanel:CreateFontString(nil, "ARTWORK", FONT_TITLE)
    autoTitle:SetPoint("TOPLEFT", MARGIN, TITLE_Y)
    autoTitle:SetText(L.TAB_AUTO_MESSAGE)

    local COL_CHANNEL = MARGIN
    local COL_INTERVAL = 100
    local COL_MESSAGE = 160
    local rowFrames = {}

    local addBtn = CreateFrame("Button", nil, autoPanel, "UIPanelButtonTemplate")
    addBtn:SetSize(TITLE_BTN_W, TITLE_BTN_H)
    addBtn:SetPoint("TOPRIGHT", autoPanel, "TOPRIGHT", -MARGIN, TITLE_BTN_Y)
    addBtn:SetText(L.AUTO_MSG_ADD)

    local headerY = CONTENT_Y
    local ACTIONS_RIGHT_OFFSET = -(MARGIN + 46 + 4 + 46 + 4 + 50)

    MakeHeader(autoPanel, COL_CHANNEL,  headerY, L.AUTO_MSG_CHANNEL)
    MakeHeader(autoPanel, COL_INTERVAL, headerY, L.AUTO_MSG_INTERVAL)
    MakeHeader(autoPanel, COL_MESSAGE,  headerY, L.AUTO_MSG_MESSAGE)
    local actionsHeader = autoPanel:CreateFontString(nil, "ARTWORK", FONT_HEADER)
    actionsHeader:SetPoint("TOPLEFT", autoPanel, "TOPRIGHT", ACTIONS_RIGHT_OFFSET, headerY)
    actionsHeader:SetText(L.AUTO_MSG_ACTIONS)

    MakeSeparator(autoPanel, COL_CHANNEL, headerY - 16)

    local noEntriesText = autoPanel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
    noEntriesText:SetPoint("TOPLEFT", COL_CHANNEL, headerY - 30)
    noEntriesText:SetText(L.AUTO_MSG_NO_ENTRIES)

    -- ScrollFrame for auto message list
    local autoScroll = CreateFrame("ScrollFrame", nil, autoPanel, "UIPanelScrollFrameTemplate")
    autoScroll:SetPoint("TOPLEFT", COL_CHANNEL, headerY - 20)
    autoScroll:SetPoint("BOTTOMRIGHT", autoPanel, "BOTTOMRIGHT", SCROLL_RIGHT, 10)

    local autoScrollChild = CreateFrame("Frame")
    autoScroll:SetScrollChild(autoScrollChild)

    local function RefreshAutoMessageList()
        for _, row in ipairs(rowFrames) do row:Hide(); row:SetParent(nil) end
        wipe(rowFrames)

        local entries = db.autoMessages
        if #entries == 0 then
            noEntriesText:Show()
            autoScrollChild:SetSize(1, 1)
            return
        end
        noEntriesText:Hide()

        SetScrollChildWidth(autoScroll, autoScrollChild)
        autoScrollChild:SetHeight(math.max(1, #entries * ROW_HEIGHT))

        for i, entry in ipairs(entries) do
            local row = CreateFrame("Frame", nil, autoScrollChild)
            row:SetHeight(ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
            row:SetPoint("RIGHT", autoScrollChild, "RIGHT", 0, 0)

            local chText = row:CreateFontString(nil, "ARTWORK", FONT_DATA)
            chText:SetPoint("LEFT", 0, 0)
            chText:SetWidth(75)
            chText:SetJustifyH("LEFT")
            chText:SetWordWrap(false)
            local chDisplay = L["AUTO_MSG_CH_" .. entry.channel] or entry.channel
            if entry.channel == "WHISPER" and entry.target and entry.target ~= "" then
                chDisplay = chDisplay .. ": " .. entry.target
            end
            chText:SetText(chDisplay)

            local intText = row:CreateFontString(nil, "ARTWORK", FONT_DATA)
            intText:SetPoint("LEFT", COL_INTERVAL - COL_CHANNEL, 0)
            intText:SetText(string.format(L.AUTO_MSG_SEC, entry.interval or 60))

            local delBtn = CreateSmallButton(row, 46, L.AUTO_MSG_DELETE, function()
                ns:StopAutoMessage(i)
                table.remove(db.autoMessages, i)
                ns:RestartAllAutoMessages()
                RefreshAutoMessageList()
            end)
            delBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

            local editBtn = CreateSmallButton(row, 46, L.AUTO_MSG_EDIT, function()
                ns:ShowAutoMessageDialog(i, RefreshAutoMessageList)
            end)
            editBtn:SetPoint("RIGHT", delBtn, "LEFT", -4, 0)

            local toggleBtn = CreateSmallButton(row, 50,
                entry.enabled and L.AUTO_MSG_ON or L.AUTO_MSG_OFF,
                function()
                    entry.enabled = not entry.enabled
                    ns:RestartAllAutoMessages()
                    RefreshAutoMessageList()
                end)
            toggleBtn:SetPoint("RIGHT", editBtn, "LEFT", -4, 0)

            local msgText = row:CreateFontString(nil, "ARTWORK", FONT_DATA)
            msgText:SetPoint("LEFT", COL_MESSAGE - COL_CHANNEL, 0)
            msgText:SetPoint("RIGHT", toggleBtn, "LEFT", -8, 0)
            msgText:SetJustifyH("LEFT")
            msgText:SetWordWrap(false)
            msgText:SetMaxLines(1)
            msgText:SetText((entry.message or ""):gsub("\n", " "))

            if not entry.enabled then
                chText:SetTextColor(0.5, 0.5, 0.5)
                intText:SetTextColor(0.5, 0.5, 0.5)
                msgText:SetTextColor(0.5, 0.5, 0.5)
            end

            rowFrames[#rowFrames + 1] = row
        end
    end

    addBtn:SetScript("OnClick", function()
        ns:ShowAutoMessageDialog(nil, RefreshAutoMessageList)
    end)

    ns.RefreshAutoMessageList = RefreshAutoMessageList

    local autoPanelDirty = true
    autoPanel:SetScript("OnShow", function() autoPanelDirty = true end)
    autoPanel:SetScript("OnUpdate", function()
        if autoPanelDirty then autoPanelDirty = false; RefreshAutoMessageList() end
    end)
    autoScroll:SetScript("OnSizeChanged", function()
        autoPanelDirty = true
    end)

    ---------------------------------------------------------------------------
    -- Register categories
    ---------------------------------------------------------------------------
    local tradeSub   = Settings.RegisterCanvasLayoutSubcategory(mainCategory, tradePanel, L.TAB_TRADE_ALERTS)
    local historySub = Settings.RegisterCanvasLayoutSubcategory(mainCategory, historyPanel, L.TAB_HISTORY)
    local autoMsgSub = Settings.RegisterCanvasLayoutSubcategory(mainCategory, autoPanel, L.TAB_AUTO_MESSAGE)

    Settings.RegisterAddOnCategory(mainCategory)
    ns.settingsCategory = mainCategory
end
