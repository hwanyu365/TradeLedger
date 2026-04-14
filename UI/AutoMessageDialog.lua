local _, ns = ...

local dialog = nil

-- Channel definitions: { key, displayKey (locale), needsTarget }
local CHANNEL_DEFS = {
    { key = "TRADE",   localeKey = "AUTO_MSG_CH_TRADE" },
    { key = "WHISPER", localeKey = "AUTO_MSG_CH_WHISPER", needsTarget = true },
    { key = "PARTY",   localeKey = "AUTO_MSG_CH_PARTY" },
    { key = "RAID",    localeKey = "AUTO_MSG_CH_RAID" },
    { key = "GUILD",   localeKey = "AUTO_MSG_CH_GUILD" },
}

local INTERVAL_MIN = 10
local INTERVAL_MAX = 600
local INTERVAL_STEP = 5
local MARGIN = 16

local function GetChannelDisplay(key)
    local L = ns.L
    for _, def in ipairs(CHANNEL_DEFS) do
        if def.key == key then
            return L[def.localeKey] or key
        end
    end
    return key
end

local function EnsureDialog()
    if dialog then return dialog end

    local L = ns.L

    -- Main frame with custom backdrop (semi-transparent like settings)
    local f = CreateFrame("Frame", "TradeLedgerAutoMsgDialog", UIParent, "BackdropTemplate")
    f:SetSize(450, 300)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 26,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    f:Hide()

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -14)
    f.title:SetText("TradeLedger - " .. L.TAB_AUTO_MESSAGE)

    local ROW_H = 32
    local yOff = -46

    ---------------------------------------------------------------------------
    -- Channel: UIDropDownMenu
    ---------------------------------------------------------------------------
    local chLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    chLabel:SetPoint("TOPLEFT", MARGIN, yOff - 4)
    chLabel:SetText(L.AUTO_MSG_CHANNEL)

    local dropdown = CreateFrame("Frame", "TradeLedgerChDropdown", f, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 90, yOff + 2)
    UIDropDownMenu_SetWidth(dropdown, 130)
    f.dropdown = dropdown

    f.selectedChannel = CHANNEL_DEFS[1].key  -- TRADE default

    -- Whisper target EditBox (inline, right of dropdown)
    local tEdit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    tEdit:SetSize(150, 22)
    tEdit:SetPoint("LEFT", dropdown, "RIGHT", 0, 2)
    tEdit:SetAutoFocus(false)
    tEdit:Hide()
    f.targetEdit = tEdit

    local function UpdateChannelFields()
        if f.selectedChannel == "WHISPER" then
            tEdit:Show()
        else
            tEdit:Hide()
        end
    end

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, def in ipairs(CHANNEL_DEFS) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = L[def.localeKey] or def.key
            info.value = def.key
            info.checked = (f.selectedChannel == def.key)
            info.func = function(btn)
                f.selectedChannel = btn.value
                UIDropDownMenu_SetText(dropdown, L[CHANNEL_DEFS[1].localeKey])
                for _, d in ipairs(CHANNEL_DEFS) do
                    if d.key == btn.value then
                        UIDropDownMenu_SetText(dropdown, L[d.localeKey] or d.key)
                        break
                    end
                end
                CloseDropDownMenus()
                UpdateChannelFields()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    yOff = yOff - ROW_H

    ---------------------------------------------------------------------------
    -- Interval: Slider
    ---------------------------------------------------------------------------
    local intLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    intLabel:SetPoint("TOPLEFT", MARGIN, yOff - 4)
    intLabel:SetText(L.AUTO_MSG_INTERVAL)

    local slider = CreateFrame("Slider", "TradeLedgerIntervalSlider", f, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 106, yOff - 2)
    slider:SetSize(200, 17)
    slider:SetMinMaxValues(INTERVAL_MIN, INTERVAL_MAX)
    slider:SetValueStep(INTERVAL_STEP)
    slider:SetObeyStepOnDrag(true)
    slider:SetValue(60)

    slider.Low:SetText(INTERVAL_MIN .. "s")
    slider.High:SetText(INTERVAL_MAX .. "s")

    local sliderValueText = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sliderValueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)

    local function UpdateSliderText(val)
        sliderValueText:SetText(string.format(L.AUTO_MSG_SEC, val))
    end
    UpdateSliderText(60)

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / INTERVAL_STEP + 0.5) * INTERVAL_STEP
        UpdateSliderText(val)
    end)

    f.slider = slider
    f.UpdateSliderText = UpdateSliderText

    yOff = yOff - ROW_H

    ---------------------------------------------------------------------------
    -- Message: MultiLine EditBox with background
    ---------------------------------------------------------------------------
    local msgLabel = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    msgLabel:SetPoint("TOPLEFT", MARGIN, yOff)
    msgLabel:SetText(L.AUTO_MSG_MESSAGE)
    yOff = yOff - 18

    -- Background frame for message area (symmetric margins)
    local msgBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    msgBg:SetPoint("TOPLEFT", MARGIN, yOff)
    msgBg:SetPoint("RIGHT", f, "RIGHT", -MARGIN, 0)
    msgBg:SetHeight(110)
    msgBg:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    msgBg:SetBackdropColor(0, 0, 0, 0.5)
    msgBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    local msgScroll = CreateFrame("ScrollFrame", nil, msgBg, "UIPanelScrollFrameTemplate")
    msgScroll:SetPoint("TOPLEFT", 6, -6)
    msgScroll:SetPoint("BOTTOMRIGHT", -24, 6)

    local msgEdit = CreateFrame("EditBox", nil, msgScroll)
    msgEdit:SetMultiLine(true)
    msgEdit:SetAutoFocus(false)
    msgEdit:SetFontObject("ChatFontNormal")
    msgEdit:SetWidth(msgScroll:GetWidth() or 350)
    msgEdit:SetHyperlinksEnabled(true)
    msgEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    msgScroll:SetScrollChild(msgEdit)
    f.messageEdit = msgEdit

    -- Click background to focus editbox
    msgBg:EnableMouse(true)
    msgBg:SetScript("OnMouseDown", function() msgEdit:SetFocus() end)

    -- Track focus state for link insertion
    local isEditBoxFocused = false
    msgEdit:SetScript("OnEditFocusGained", function() isEditBoxFocused = true end)
    msgEdit:SetScript("OnEditFocusLost", function() isEditBoxFocused = false end)

    -- Hook HandleModifiedItemClick for Shift+Click link insertion
    hooksecurefunc("HandleModifiedItemClick", function(link)
        if f:IsShown() and isEditBoxFocused and link then
            msgEdit:Insert(link)
        end
    end)

    if ChatFrameUtil and ChatFrameUtil.InsertLink then
        hooksecurefunc(ChatFrameUtil, "InsertLink", function(link)
            if f:IsShown() and isEditBoxFocused and link then
                msgEdit:Insert(link)
            end
        end)
    end

    ---------------------------------------------------------------------------
    -- OK / Cancel buttons
    ---------------------------------------------------------------------------
    local btnOK = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnOK:SetSize(100, 26)
    btnOK:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -8, 22)
    btnOK:SetText(L.AUTO_MSG_CONFIRM)
    f.okButton = btnOK

    local btnCancel = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnCancel:SetSize(100, 26)
    btnCancel:SetPoint("BOTTOMLEFT", f, "BOTTOM", 8, 22)
    btnCancel:SetText(L.AUTO_MSG_CANCEL)
    btnCancel:SetScript("OnClick", function() f:Hide() end)

    dialog = f
    return f
end

function ns:ShowAutoMessageDialog(editIndex, onSave)
    local f = EnsureDialog()
    local L = self.L

    -- Reset fields
    f.targetEdit:SetText("")
    f.targetEdit:Hide()
    f.slider:SetValue(60)
    f.UpdateSliderText(60)
    f.messageEdit:SetText("")
    f.selectedChannel = CHANNEL_DEFS[1].key
    UIDropDownMenu_SetText(f.dropdown, GetChannelDisplay(f.selectedChannel))

    -- Fill existing values for edit
    if editIndex then
        local entry = self.db.autoMessages[editIndex]
        if entry then
            f.selectedChannel = entry.channel or CHANNEL_DEFS[1].key
            UIDropDownMenu_SetText(f.dropdown, GetChannelDisplay(f.selectedChannel))
            local interval = entry.interval or 60
            interval = math.max(INTERVAL_MIN, math.min(INTERVAL_MAX, interval))
            f.slider:SetValue(interval)
            f.UpdateSliderText(interval)
            f.messageEdit:SetText(entry.message or "")
            if entry.channel == "WHISPER" then
                f.targetEdit:Show()
                f.targetEdit:SetText(entry.target or "")
            end
        end
    end

    -- OK handler
    f.okButton:SetScript("OnClick", function()
        local sliderVal = f.slider:GetValue()
        sliderVal = math.floor(sliderVal / INTERVAL_STEP + 0.5) * INTERVAL_STEP

        local entry = {
            channel  = f.selectedChannel,
            interval = math.max(INTERVAL_MIN, sliderVal),
            message  = f.messageEdit:GetText() or "",
            enabled  = editIndex and self.db.autoMessages[editIndex].enabled or true,
            target   = f.targetEdit:GetText(),
        }

        if editIndex then
            self.db.autoMessages[editIndex] = entry
        else
            self.db.autoMessages[#self.db.autoMessages + 1] = entry
        end

        self:RestartAllAutoMessages()
        if onSave then onSave() end
        f:Hide()
    end)

    f:Show()
end
