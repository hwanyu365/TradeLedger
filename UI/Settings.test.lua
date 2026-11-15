local support = load_source("scripts/test-support.lua")
local ui = load_source("scripts/test-ui-support.lua")

describe("Settings", function()
    it("TC#32 금액 기준 입력란: Enter·초점 해제는 입력값(상한 보정)을 저장하고, Esc 는 입력을 버리고 저장된 값을 유지한다", function()
        local ns = support.addon()
        ns.db.goldThreshold = 1000
        ui.load(ns)
        local boxes = ui.find("EditBox")
        eq(#boxes, 1)
        local box = boxes[1]

        box:SetFocus()
        ui.type(box, "2500")
        ui.press(box, "OnEnterPressed")
        eq(ns.db.goldThreshold, 2500)
        eq(box:HasFocus(), false)

        box:SetFocus()
        ui.type(box, "3000")
        box:ClearFocus()
        eq(ns.db.goldThreshold, 3000)

        box:SetFocus()
        ui.type(box, "99999999")
        eq(box:GetNumber(), 10000000)
        ui.press(box, "OnEnterPressed")
        eq(ns.db.goldThreshold, 10000000)

        ns.db.goldThreshold = 4000
        box:SetFocus()
        ui.type(box, "123")
        ui.press(box, "OnEscapePressed")
        eq(ns.db.goldThreshold, 4000)
        eq(box:HasFocus(), false)
        eq(box:IsShown(), false)
    end)
end)
