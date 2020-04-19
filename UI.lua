local name, private = ...
local LootHelper = _G.HHLootHelper
UI = {}
LootHelper.UI = UI

UI_CREATED = false

--[[
-- backdrop with border
ALPrivate.BOX_BORDER_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
]]

local CLASS_NAMES_WITH_COLORS = LootHelper:GetColoredClassNames()


local function FrameOnDragStart(self, arg1)
    if arg1 == "LeftButton" then
        self:StartMoving()
    end
end


local function FrameOnDragStop(self)
    self:StopMovingOrSizing()
end


local function FrameOnShow(self)

end


function UI:Update(raidData)
    raidData = raidData or {}
    if self.frame then
        self.frame.lootFrame:Update(raidData.loot)
        self.frame.activeRolls:Update(raidData.activeRolls)
        self.frame.historicRolls:Update(raidData.historicRolls)
    end
end


function UI:Show()
    self.frame:Show()
end


function UI:Hide()
    self.frame:Hide()
end


local ROLL_FRAME_COUNT = 1
local function CreateRollFrame()
    ROLL_FRAME_COUNT = ROLL_FRAME_COUNT + 1

    local frameName = "HHLootHelper_UI-RollFrame-"..ROLL_FRAME_COUNT
    
    local frame = CreateFrame("Frame", frameName)
    frame:ClearAllPoints()
    frame:EnableMouse(true)
    frame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                        tile = true, tileSize = 16, edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    frame:SetBackdropColor(0,0,0,1)

    return frame
end


function UI:Create()
    if UI_CREATED then return end
    UI_CREATED = true

    local frameName = "HHLootHelper_UI-Frame"

    local frame = CreateFrame("Frame", frameName)
    -- frame:ClearAllPoints()
    frame:SetParent(UIParent)
    -- frame:SetPoint(db.point[1], db.point[2], db.point[3], db.point[4], db.point[5])
    frame:SetPoint("CENTER")
    frame:SetWidth(920)
    frame:SetHeight(630)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton", "RightButton")
    frame:SetScript("OnMouseDown", FrameOnDragStart)
    frame:SetScript("OnMouseUp", FrameOnDragStop)
    frame:SetScript("OnShow", FrameOnShow)
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame:SetBackdropColor(0.45,0.45,0.45,1)
    frame:Hide()
    tinsert(UISpecialFrames, frameName)	-- allow ESC close

    frame.CloseButton = CreateFrame("Button", frameName.."-CloseButton", frame, "UIPanelCloseButton")
    frame.CloseButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    frame.titleFrame = CreateFrame("Frame")
    frame.titleFrame:ClearAllPoints()
    frame.titleFrame:SetParent(frame)
	frame.titleFrame:SetPoint("TOPLEFT", frame, 10, -7)
	frame.titleFrame:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -30, -25)
    frame.titleFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame.titleFrame:SetBackdropColor(0.2,0.2,0.2,1)

    frame.titleFrame.text = frame.titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.titleFrame.text:SetAllPoints(frame.titleFrame)
    frame.titleFrame.text:SetJustifyH("CENTER")
    frame.titleFrame.text:SetText("HH Loot Helper")

    frame.newRaid = CreateFrame("Button", frameName.."-NewRaid", nil, "UIPanelButtonTemplate")
    frame.newRaid:ClearAllPoints()
    frame.newRaid:SetParent(frame)
    frame.newRaid:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
    frame.newRaid:SetScript("OnClick", function() LootHelper:NewRaid() end)
    frame.newRaid:SetText("New raid")
    frame.newRaid:SetWidth(150)

    frame.closeRaid = CreateFrame("Button", frameName.."-CloseRaid", nil, "UIPanelButtonTemplate")
    frame.closeRaid:ClearAllPoints()
    frame.closeRaid:SetParent(frame)
    frame.closeRaid:SetPoint("TOPLEFT", frame.newRaid, "TOPRIGHT", 5, 0)
    frame.closeRaid:SetScript("OnClick", function() LootHelper:CloseRaid() end)
    frame.closeRaid:SetText("Close raid")
    frame.closeRaid:SetWidth(150)

    frame.archiveRolls = CreateFrame("Button", frameName.."-ArchiveRolls", nil, "UIPanelButtonTemplate")
    frame.archiveRolls:ClearAllPoints()
    frame.archiveRolls:SetParent(frame)
    frame.archiveRolls:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -35)
    frame.archiveRolls:SetScript("OnClick", function() LootHelper:ArchiveRolls() end)
    frame.archiveRolls:SetText("Archive rolls")
    frame.archiveRolls:SetWidth(150)

    frame.lootFrame = UI.CreateLootFrame()
    frame.lootFrame:ClearAllPoints()
    frame.lootFrame:SetParent(frame)
    frame.lootFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -60)

    frame.activeRolls = UI.CreateRollFrame(true)
    frame.activeRolls:ClearAllPoints()
    frame.activeRolls:SetParent(frame)
    frame.activeRolls:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -60)
    frame.activeRolls:SetHeight(250)

    frame.historicRolls = UI.CreateRollFrame(false)
    frame.historicRolls:ClearAllPoints()
    frame.historicRolls:SetParent(frame)
    frame.historicRolls:SetPoint("TOPLEFT", frame.activeRolls, "BOTTOMLEFT", 0, -10)
    frame.historicRolls:SetHeight(290)

    self.frame = frame
end




