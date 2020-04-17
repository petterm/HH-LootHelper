local name, private = ...
local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

local ITEM_COLORS = {}
for i=0,7 do
    local _, _, _, itemQuality = GetItemQualityColor(i)
    ITEM_COLORS[i] = itemQuality
end

local function OnButtonClick(self)

end

local function SetParent(self, parent)
    self.frame:SetParent(parent)
end

local function SetPoint(self, ...)
    self.frame:SetPoint(...)
end

local function SetWidth(self, ...)
    self.frame:SetWidth(...)
end

local function SetHeight(self, ...)
    self.frame:SetHeight(...)
end


local LOOT_FRAME_COUNT = 0
function UI.CreateLootFrame()
    LOOT_FRAME_COUNT = LOOT_FRAME_COUNT + 1
    local frameName = "HHLootHelper_UI-LootFrame-"..LOOT_FRAME_COUNT
    local self = {}

    -- TEMP
    local itemName = "[Item name]"
    local itemQuality = 4

    self.SetParent = SetParent
    self.SetPoint = SetPoint
    self.SetWidth = SetWidth
    self.SetHeight = SetHeight

    self.frame = CreateFrame("Frame", frameName)
    local frame = self.frame

    -- frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    -- frame:SetBackdropColor(1,0,0,1)

    frame.icon = frame:CreateTexture(frameName.."_Icon")
    frame.icon:SetParent(frame)
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.icon:SetHeight(26)
    frame.icon:SetWidth(26)
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    frame.name = frame:CreateFontString(frameName.."_Name", "ARTWORK", "GameFontNormal")
    frame.name:SetParent(frame)
    frame.name:SetPoint("TOPLEFT", frame.icon, "TOPRIGHT", 4, 0)
    frame.name:SetJustifyH("LEFT")
    frame.name:SetWidth(205)
    frame.name:SetHeight(26)
    frame.name:SetText("|c"..ITEM_COLORS[itemQuality or 0]..itemName)

    frame.player = frame:CreateFontString(frameName.."_Player", "ARTWORK", "GameFontNormalSmall")
    frame.player:SetParent(frame)
    frame.player:SetPoint("TOPLEFT", frame.name, "TOPRIGHT", 3, 0)
    frame.player:SetJustifyH("LEFT")
    frame.player:SetText("[Player name]")
    frame.player:SetWidth(105)
    frame.player:SetHeight(26)

    -- Buttons
    frame.buttonIG = CreateFrame("BUTTON", frameName.."_ButtonIG", nil, "UIPanelButtonTemplate")
    frame.buttonIG:SetParent(frame)
    frame.buttonIG:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -2)
    frame.buttonIG:SetWidth(60)
    frame.buttonIG:SetText("Ignore")
    frame.buttonIG:SetScript("OnClick", OnButtonClick)

    frame.buttonOS = CreateFrame("BUTTON", frameName.."_ButtonOS", nil, "UIPanelButtonTemplate")
    frame.buttonOS:SetParent(frame)
    frame.buttonOS:SetPoint("TOPRIGHT", frame.buttonIG, "TOPLEFT", -3, 0)
    frame.buttonOS:SetText("OS")
    frame.buttonOS:SetScript("OnClick", OnButtonClick)

    frame.buttonMS = CreateFrame("BUTTON", frameName.."_ButtonMS", nil, "UIPanelButtonTemplate")
    frame.buttonMS:SetParent(frame)
    frame.buttonMS:SetPoint("TOPRIGHT", frame.buttonOS, "TOPLEFT", -3, 0)
    frame.buttonMS:SetText("MS")
    frame.buttonMS:SetScript("OnClick", OnButtonClick)

    return self
end