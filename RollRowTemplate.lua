local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

local function Update(self, roll)
    local classColor = "ffaaaaaa" --n!!
    if roll.playerClass then
        classColor = RAID_CLASS_COLORS[roll.playerClass].colorStr
    end

    self.frame.player:SetText("|c"..classColor..roll.player.."|r")
    self.frame.roll:SetText(roll.roll)
    self.frame.penalty:SetText(roll.penalty)
    self.frame.result:SetText(roll.result)
end

local function OnActivateHistoricRoll(rollRow)
    LootHelper:ActivateArchivedRoll(rollRow.rollIndex)
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

local function Show(self, ...)
    self.frame:Show(...)
end

local function Hide(self, ...)
    self.frame:Hide(...)
end


local ROLL_ROW_COUNT_ACTIVE = 0
local ROLL_ROW_COUNT_HISTORIC = 0
function UI.CreateRollRow(isActiveRoll)
    local frameName = "HHLootHelper_UI-RollRow"
    local self = {}

    if isActiveRoll then
        ROLL_ROW_COUNT_ACTIVE = ROLL_ROW_COUNT_ACTIVE + 1
        frameName = frameName.."-Active-"..ROLL_ROW_COUNT_ACTIVE
    else
        ROLL_ROW_COUNT_HISTORIC = ROLL_ROW_COUNT_HISTORIC + 1
        frameName = frameName.."-Historic-"..ROLL_ROW_COUNT_HISTORIC
    end

    self.Update = Update
    self.SetParent = SetParent
    self.SetPoint = SetPoint
    self.SetWidth = SetWidth
    self.SetHeight = SetHeight
    self.Show = Show
    self.Hide = Hide

    if not isActiveRoll then
        self.frame = CreateFrame("Button", frameName)
        self.frame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        self.frame:SetScript("OnClick", function() OnActivateHistoricRoll(self) end)
    else
        self.frame = CreateFrame("Frame", frameName)
    end
    local frame = self.frame

    frame.player = frame:CreateFontString(frameName.."_Name", "ARTWORK", "GameFontNormal")
    frame.player:SetParent(frame)
    frame.player:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, 0)
    frame.player:SetWidth(155)
    frame.player:SetHeight(18)
    frame.player:SetText("|c"..RAID_CLASS_COLORS["WARRIOR"].colorStr.."Player".."|r")
    frame.player:SetJustifyH("LEFT")

    frame.result = frame:CreateFontString(frameName.."_Result", "ARTWORK", "GameFontNormal")
    frame.result:SetParent(frame)
    frame.result:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 0)
    frame.result:SetWidth(40)
    frame.result:SetHeight(18)
    frame.result:SetText("60")
    frame.result:SetTextColor(0.9, 0.9, 0.9, 1)
    frame.result:SetJustifyH("RIGHT")

    frame.penalty = frame:CreateFontString(frameName.."_Penalty", "ARTWORK", "GameFontNormal")
    frame.penalty:SetParent(frame)
    frame.penalty:SetPoint("TOPRIGHT", frame.result, "TOPLEFT", 4, 0)
    frame.penalty:SetWidth(50)
    frame.penalty:SetHeight(18)
    frame.penalty:SetText("-140")
    frame.penalty:SetTextColor(0.5, 0.5, 0.5, 1)
    frame.penalty:SetJustifyH("RIGHT")

    frame.roll = frame:CreateFontString(frameName.."_Roll", "ARTWORK", "GameFontNormal")
    frame.roll:SetParent(frame)
    frame.roll:SetPoint("TOPRIGHT", frame.penalty, "TOPLEFT", 4, 0)
    frame.roll:SetWidth(40)
    frame.roll:SetHeight(18)
    frame.roll:SetText("100")
    frame.roll:SetTextColor(0.5, 0.5, 0.5, 1)
    frame.roll:SetJustifyH("RIGHT")

    return self
end
