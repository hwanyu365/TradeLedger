local support = load_source("scripts/test-support.lua")

local function keys(t)
    local out = {}
    for k in pairs(t) do out[#out + 1] = k end
    table.sort(out)
    return out
end

describe("Locale", function()
    it("TC#4 enUS 가 기본이고 koKR 클라이언트에서만 koKR 로 덮어쓰며, 두 로케일의 키 집합이 같다", function()
        eq(support.addon({ locale = "enUS" }).L.SENT, "Sent")
        eq(support.addon({ locale = "deDE" }).L.SENT, "Sent")
        eq(support.addon({ locale = "koKR" }).L.SENT, "보냄")

        support.stub_wow({ locale = "enUS" })
        local en = { L = {} }
        load_source("Locale/enUS.lua", en)

        support.stub_wow({ locale = "koKR" })
        local ko = { L = {} }
        load_source("Locale/koKR.lua", ko)

        eq(keys(ko.L), keys(en.L))
    end)
end)

describe("Locale reset notice", function()
    it("TC#31 설정 초기화 확인·완료 문구는 자동 메시지와 거래 장부가 지워진다는 것을 알린다", function()
        local en = support.addon({ locale = "enUS" }).L
        for _, key in ipairs({ "SETTINGS_RESET_CONFIRM", "SETTINGS_RESET" }) do
            local s = en[key]:lower()
            eq(s:find("auto message", 1, true) ~= nil, true, "enUS " .. key)
            eq(s:find("trade history", 1, true) ~= nil, true, "enUS " .. key)
        end
        local ko = support.addon({ locale = "koKR" }).L
        for _, key in ipairs({ "SETTINGS_RESET_CONFIRM", "SETTINGS_RESET" }) do
            eq(ko[key]:find("자동 메시지", 1, true) ~= nil, true, "koKR " .. key)
            eq(ko[key]:find("거래 기록", 1, true) ~= nil, true, "koKR " .. key)
        end
    end)
end)
