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

function UI:Show()
    self.frame:Show()
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
    LootHelper:Print("UI:Create", UI_CREATED)
    if UI_CREATED then return end
    UI_CREATED = true

    local frameName = "HHLootHelper_UI-Frame"

    local frame = CreateFrame("Frame", frameName)
    -- frame:ClearAllPoints()
    frame:SetParent(UIParent)
    -- frame:SetPoint(db.point[1], db.point[2], db.point[3], db.point[4], db.point[5])
    frame:SetPoint("CENTER")
    frame:SetWidth(920)
    frame:SetHeight(600)
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
    frame.titleFrame:SetBackdropColor(0.5,0,0.2,1)

    frame.titleFrame.text = frame.titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    frame.titleFrame.text:SetAllPoints(frame.titleFrame)
    frame.titleFrame.text:SetJustifyH("CENTER")
    frame.titleFrame.text:SetText("HH Loot Helper")

    frameName = "HHLootHelper_UI-LootFrame"

    frame.lootFrame = CreateFrame("Frame", frameName)
    frame.lootFrame:ClearAllPoints()
    frame.lootFrame:SetParent(frame)
    frame.lootFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
    frame.lootFrame:SetWidth(560)		-- Frame = 560, Abstand = 20, Button = 270
    frame.lootFrame:SetHeight(550)		-- Frame = 460, Abstand = 10, Button = 30
    frame.lootFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame.lootFrame:SetBackdropColor(0,0,0,1)
    frame.lootFrame.shownFrame = nil


    -- frame.lootFrame.lootBG = frame.lootFrame:CreateTexture(frameName.."-lootBG","BACKGROUND")
    -- frame.lootFrame.lootBG:SetPoint("TOPLEFT", frame.lootFrame, "TOPLEFT", 0, -30)
    -- frame.lootFrame.lootBG:SetWidth(560)
    -- frame.lootFrame.lootBG:SetHeight(450)
    -- frame.lootFrame.lootBG:SetTexCoord(0.1, 0.7, 0.1, 0.7)


    frame.activeRolls = CreateRollFrame()
    frame.activeRolls:ClearAllPoints()
    frame.activeRolls:SetParent(frame)
    frame.activeRolls:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -40)
    frame.activeRolls:SetWidth(320)
    frame.activeRolls:SetHeight(250)

    frame.historicRolls = CreateRollFrame()
    frame.historicRolls:ClearAllPoints()
    frame.historicRolls:SetParent(frame)
    frame.historicRolls:SetPoint("TOPLEFT", frame.activeRolls, "BOTTOMLEFT", 0, -10)
    frame.historicRolls:SetWidth(320)
    frame.historicRolls:SetHeight(290)




    self.frame = frame
end
