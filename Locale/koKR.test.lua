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
