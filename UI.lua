local name, private = ...
local LootHelper = _G.HHLootHelper
UI = {}
LootHelper.UI = UI
UI.showHidden = true

UI_CREATED = false
FRAME_HEIGHT_WITH_BUTTONS = 620
FRAME_HEIGHT_WITHOUT_BUTTONS = 600

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


local visibleLoot = {}
function UI:Update(raidData)
    wipe(visibleLoot)
    raidData = raidData or {}
    local readOnly = LootHelper:ReadOnly(raidData)

    if self.frame then
        if readOnly then
            self.frame.titleFrame.text:SetText("HH Loot Helper - |cffff5555".."READ ONLY".."|r")
            -- self.frame.buttonFrame:Hide()
            -- self.frame:SetHeight(FRAME_HEIGHT_WITHOUT_BUTTONS)
        else
            self.frame.titleFrame.text:SetText("HH Loot Helper")
            -- self.frame.buttonFrame:Show()
            -- self.frame:SetHeight(FRAME_HEIGHT_WITH_BUTTONS)
        end

        if raidData.loot and not UI.showHidden then
            for k, loot in ipairs(raidData.loot) do
                if loot.lootAction ~= "HIDDEN" then
                    tinsert(visibleLoot, loot)
                end
            end
            self.frame.lootFrame:Update(visibleLoot, readOnly)
        else
            self.frame.lootFrame:Update(raidData.loot, readOnly)
        end


        self.frame.activeRolls:Update(raidData.activeRolls)
        self.frame.historicRolls:Update(raidData.historicRolls)
    end
end


function UI:Show()
    self.frame:Show()
    -- self.frame.lootFrame:ScrollToBottom()
end


function UI:Hide()
    self.frame:Hide()
end


function UI:ToggleHiddenLoot()
    self.showHidden = not self.showHidden
    if self.showHidden then
        self.frame.buttonFrame.toggleHidden:SetText("Hide loot")
    else
        self.frame.buttonFrame.toggleHidden:SetText("Show loot")
    end
    self:Update(LootHelper:GetSelectedRaidData())
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
    frame:SetHeight(FRAME_HEIGHT_WITH_BUTTONS)
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

    local buttonFrameName = frameName.."-Buttons"
    frame.buttonFrame = CreateFrame("Frame", buttonFrameName)
    frame.buttonFrame:ClearAllPoints()
    frame.buttonFrame:SetParent(frame)
    frame.buttonFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    frame.buttonFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -30)
    frame.buttonFrame:SetHeight(25)

    frame.buttonFrame.newRaid = CreateFrame("Button", buttonFrameName.."-NewRaid", nil, "UIPanelButtonTemplate")
    frame.buttonFrame.newRaid:ClearAllPoints()
    frame.buttonFrame.newRaid:SetParent(frame.buttonFrame)
    frame.buttonFrame.newRaid:SetPoint("TOPLEFT", frame.buttonFrame, "TOPLEFT", 0, 0)
    frame.buttonFrame.newRaid:SetScript("OnClick", function() LootHelper:NewRaid() end)
    frame.buttonFrame.newRaid:SetText("New raid")
    frame.buttonFrame.newRaid:SetWidth(150)

    frame.buttonFrame.closeRaid = CreateFrame("Button", buttonFrameName.."-CloseRaid", nil, "UIPanelButtonTemplate")
    frame.buttonFrame.closeRaid:ClearAllPoints()
    frame.buttonFrame.closeRaid:SetParent(frame.buttonFrame)
    frame.buttonFrame.closeRaid:SetPoint("TOPLEFT", frame.buttonFrame.newRaid, "TOPRIGHT", 5, 0)
    frame.buttonFrame.closeRaid:SetScript("OnClick", function() LootHelper:CloseRaid() end)
    frame.buttonFrame.closeRaid:SetText("Close raid")
    frame.buttonFrame.closeRaid:SetWidth(150)

    frame.buttonFrame.toggleHidden = CreateFrame("Button", buttonFrameName.."-ToggleHidden", nil, "UIPanelButtonTemplate")
    frame.buttonFrame.toggleHidden:ClearAllPoints()
    frame.buttonFrame.toggleHidden:SetParent(frame.buttonFrame)
    frame.buttonFrame.toggleHidden:SetPoint("TOPLEFT", frame.buttonFrame.closeRaid, "TOPRIGHT", 5, 0)
    frame.buttonFrame.toggleHidden:SetScript("OnClick", function() self:ToggleHiddenLoot() end)
    frame.buttonFrame.toggleHidden:SetText("Hide loot")
    frame.buttonFrame.toggleHidden:SetWidth(150)

    frame.buttonFrame.archiveRolls = CreateFrame("Button", buttonFrameName.."-ArchiveRolls", nil, "UIPanelButtonTemplate")
    frame.buttonFrame.archiveRolls:ClearAllPoints()
    frame.buttonFrame.archiveRolls:SetParent(frame.buttonFrame)
    frame.buttonFrame.archiveRolls:SetPoint("TOPRIGHT", frame.buttonFrame, "TOPRIGHT", 0, 0)
    frame.buttonFrame.archiveRolls:SetScript("OnClick", function() LootHelper:ArchiveRolls() end)
    frame.buttonFrame.archiveRolls:SetText("Archive rolls")
    frame.buttonFrame.archiveRolls:SetWidth(150)

    frame.lootFrame = UI.CreateLootFrame()
    frame.lootFrame:ClearAllPoints()
    frame.lootFrame:SetParent(frame)
    frame.lootFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)

    frame.historicRolls = UI.CreateRollFrame(false)
    frame.historicRolls:ClearAllPoints()
    frame.historicRolls:SetParent(frame)
    frame.historicRolls:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    frame.historicRolls:SetHeight(290)

    frame.activeRolls = UI.CreateRollFrame(true)
    frame.activeRolls:ClearAllPoints()
    frame.activeRolls:SetParent(frame)
    frame.activeRolls:SetPoint("BOTTOMRIGHT", frame.historicRolls, "TOPRIGHT", 0, 10)
    frame.activeRolls:SetHeight(250)

    self.frame = frame
end




