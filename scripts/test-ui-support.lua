-- usage (테스트 파일 안): local ui = load_source("scripts/test-ui-support.lua")
-- support.addon() 으로 만든 ns 에 UI 파일을 불러올 수 있게 프레임 API 대역을 전역에 넣는다.
-- 배치·모양은 검사하지 않는다 → 모르는 메서드·필드는 무엇이든 받아 주는 대역을 돌려주고, 스크립트·입력란 상태만 기록한다.
local ui = {}

local any
local anyMeta = {
    __index = function() return any end,
    __call = function() return any end,
}
any = setmetatable({}, anyMeta)

local Frame = {}
local frameMeta = {
    __index = function(_, k)
        if Frame[k] ~= nil then return Frame[k] end
        return any
    end,
}

local function newFrame(kind, parent, template)
    local f = setmetatable({
        kind = kind, parent = parent, template = template,
        scripts = {}, shown = true, focus = false, text = "", checked = false,
    }, frameMeta)
    f.Text = setmetatable({}, frameMeta)
    ui.frames[#ui.frames + 1] = f
    return f
end

function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:CreateFontString() return newFrame("FontString", self) end
function Frame:CreateTexture() return newFrame("Texture", self) end
function Frame:GetWidth() return 0 end
function Frame:GetHeight() return 0 end
function Frame:GetFrameLevel() return 0 end
function Frame:SetText(t) self.text = t == nil and "" or tostring(t) end
function Frame:GetText() return self.text end
function Frame:SetNumber(n) self.text = tostring(n) end
function Frame:GetNumber() return tonumber(self.text) end
function Frame:SetChecked(v) self.checked = v and true or false end
function Frame:GetChecked() return self.checked end
function Frame:Show() self.shown = true end
function Frame:IsShown() return self.shown end
function Frame:HasFocus() return self.focus end
function Frame:SetFocus() self.focus = true end
-- 런타임과 같이 ClearFocus 는 초점이 있을 때 OnEditFocusLost 를 부른다.
function Frame:ClearFocus()
    if not self.focus then return end
    self.focus = false
    if self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self) end
end
function Frame:Hide() self.shown = false end

-- 사용자가 입력란 내용을 바꾼 것처럼 OnTextChanged(userInput = true) 까지 부른다.
function ui.type(box, text)
    box.text = text
    if box.scripts.OnTextChanged then box.scripts.OnTextChanged(box, true) end
end

function ui.press(frame, script)
    frame.scripts[script](frame)
end

function ui.load(ns)
    ui.frames = {}
    CreateFrame = function(kind, _, parent, template) return newFrame(kind, parent, template) end
    StaticPopupDialogs = {}
    StaticPopup_Show = function() end
    YES, NO = "Yes", "No"
    Settings.RegisterCanvasLayoutCategory = function() return any end
    Settings.RegisterCanvasLayoutSubcategory = function() return any end
    Settings.RegisterAddOnCategory = function() end
    load_source("UI/Settings.lua", ns)
    ns:InitSettings()
    return ui
end

function ui.find(kind)
    local found = {}
    for _, f in ipairs(ui.frames) do
        if f.kind == kind then found[#found + 1] = f end
    end
    return found
end

return ui
