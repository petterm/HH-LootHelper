local name, private = ...
local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI
local playerList

local ITEM_COLORS = LootHelper:GetItemColors()

local function Update(self, lootData, readOnly)
    --[[
        -- lootData --
        date = time({year=date("%Y"), month=date("%m"), day=date("%d"), hour=serverHour, min=serverMinute}),
        player = player,
        itemName = itemName,
        itemID = itemID,
        itemLink = itemLink,
        itemQuality = itemQuality,
        itemTexture = itemTexture,
        ammount = ammount
    ]]

    local classColor = "ffaaaaaa" --n!!
    if lootData.playerClass then
        classColor = RAID_CLASS_COLORS[lootData.playerClass].colorStr
    end

    self.readOnly = readOnly
    self.lootIndex = lootData.index
    self.itemLink = lootData.itemLink
    self.frame.item.icon:SetTexture(lootData.itemTexture)
    self.frame.item.name:SetText("|c"..ITEM_COLORS[lootData.itemQuality or 0]..lootData.itemName.."|r")
    self.frame.player.text:SetText("|c"..classColor..lootData.player.."|r")
    
    if lootData.lootAction == "MS" then self.frame.buttonMS:Disable() else self.frame.buttonMS:Enable() end
    if lootData.lootAction == "OS" then self.frame.buttonOS:Disable() else self.frame.buttonOS:Enable() end
    if lootData.lootAction == "IGNORE" then self.frame.buttonIG:Disable() else self.frame.buttonIG:Enable() end
end

local function ShowTooltip(lootRow)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(lootRow.frame.item, "ANCHOR_RIGHT", -120, -5)
    GameTooltip:SetHyperlink(lootRow.itemLink)
    GameTooltip:Show()
end

local function HideTooltip(lootRow)
    GameTooltip:Hide()
end

local function OnChangeItemPlayer(lootRow)
    if lootRow.readOnly then return end

    if not playerList then
        playerList = UI.frame.lootFrame.playerList
    end

    local raidData = LootHelper:GetSelectedRaidData()

    playerList:Update(lootRow.lootIndex, raidData)
    playerList:Show()
end

local function SetLootActionMS(lootRow)
    LootHelper:ItemChanged(lootRow.lootIndex, nil, "MS")
end

local function SetLootActionOS(lootRow)
    LootHelper:ItemChanged(lootRow.lootIndex, nil, "OS")
end

local function SetLootActionIgnore(lootRow)
    LootHelper:ItemChanged(lootRow.lootIndex, nil, "IGNORE")
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

local LOOT_ROW_COUNT = 0
function UI.CreateLootRow()
    LOOT_ROW_COUNT = LOOT_ROW_COUNT + 1
    local frameName = "HHLootHelper_UI-LootRow-"..LOOT_ROW_COUNT
    local self = {}

    self.Update = Update
    self.SetParent = SetParent
    self.SetPoint = SetPoint
    self.SetWidth = SetWidth
    self.SetHeight = SetHeight
    self.Show = Show
    self.Hide = Hide

    self.frame = CreateFrame("Frame", frameName)
    local frame = self.frame

    -- frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    -- frame:SetBackdropColor(1,0,0,1)
    frame.item = CreateFrame("Frame", frameName.."_Item")
    frame.item:SetParent(frame)
    frame.item:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    frame.item:SetScript("OnEnter", function() ShowTooltip(self) end)
    frame.item:SetScript("OnLeave", function() HideTooltip(self) end)
    frame.item:SetHeight(26)
    frame.item:SetWidth(231)

    frame.item.icon = frame:CreateTexture(frameName.."_Icon")
    frame.item.icon:SetParent(frame.item)
    frame.item.icon:SetPoint("TOPLEFT", frame.item, "TOPLEFT", 0, 0)
    frame.item.icon:SetHeight(26)
    frame.item.icon:SetWidth(26)
    frame.item.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    frame.item.name = frame:CreateFontString(frameName.."_Name", "ARTWORK", "GameFontNormal")
    frame.item.name:SetParent(frame.item)
    frame.item.name:SetPoint("TOPLEFT", frame.item.icon, "TOPRIGHT", 4, 0)
    frame.item.name:SetJustifyH("LEFT")
    frame.item.name:SetWidth(205)
    frame.item.name:SetHeight(26)
    frame.item.name:SetText("|c"..ITEM_COLORS[4].."[Item name]")

    frame.player = CreateFrame("Button", frameName.."_Player")
    frame.player:SetParent(frame)
    frame.player:SetPoint("TOPLEFT", frame.item, "TOPRIGHT", 3, 0)
    frame.player:SetWidth(125)
    frame.player:SetHeight(26)
    frame.player:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    frame.player:SetScript("OnClick", function() OnChangeItemPlayer(self) end)

    frame.player.text = frame:CreateFontString(frameName.."_Player", "ARTWORK", "GameFontNormal")
    frame.player.text:SetPoint("TOPLEFT", frame.player, "TOPLEFT", 0, -6)
    frame.player.text:SetJustifyH("LEFT")
    frame.player.text:SetText("[Player name]")

    -- Buttons
    frame.buttonIG = CreateFrame("Button", frameName.."_ButtonIG", nil, "UIPanelButtonTemplate")
    frame.buttonIG:SetParent(frame)
    frame.buttonIG:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -2)
    frame.buttonIG:SetWidth(60)
    frame.buttonIG:SetText("Ignore")
    frame.buttonIG:SetScript("OnClick", function() SetLootActionIgnore(self) end)

    frame.buttonOS = CreateFrame("Button", frameName.."_ButtonOS", nil, "UIPanelButtonTemplate")
    frame.buttonOS:SetParent(frame)
    frame.buttonOS:SetPoint("TOPRIGHT", frame.buttonIG, "TOPLEFT", -3, 0)
    frame.buttonOS:SetText("OS")
    frame.buttonOS:SetScript("OnClick", function() SetLootActionOS(self) end)

    frame.buttonMS = CreateFrame("Button", frameName.."_ButtonMS", nil, "UIPanelButtonTemplate")
    frame.buttonMS:SetParent(frame)
    frame.buttonMS:SetPoint("TOPRIGHT", frame.buttonOS, "TOPLEFT", -3, 0)
    frame.buttonMS:SetText("MS")
    frame.buttonMS:SetScript("OnClick", function() SetLootActionMS(self) end)

    return self
end
