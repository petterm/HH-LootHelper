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
    self.lootAction = lootData.lootAction
    self.itemLink = lootData.itemLink
    self.frame.item.icon:SetTexture(lootData.itemTexture)
    self.frame.item.name:SetText("|c"..ITEM_COLORS[lootData.itemQuality or 0]..lootData.itemName.."|r")
    self.frame.player.text:SetText("|c"..classColor..lootData.player.."|r")

    -- MS & OS toggle button
    if lootData.lootAction == "MS" then
        self.frame.buttonMS:SetText("|cffebd634".."MS".."|r")
    elseif lootData.lootAction == "OS" then
        self.frame.buttonMS:SetText("|cffdddddd".."OS".."|r")
    else
        self.frame.buttonMS:SetText("|cffdddddd".."--".."|r")
    end

    if readOnly then
        self.frame.buttonMS:Disable()
    else
        self.frame.buttonMS:Enable()
    end

    -- Hide button
    if lootData.lootAction == "HIDDEN" then
        self.frame.buttonHide.text:SetText("|cffc9a43e(Hidden)|r")
        self.frame.buttonHide:Disable()
    else
        if readOnly then
            self.frame.buttonHide.text:SetText("")
            self.frame.buttonHide:Disable()
        else
            self.frame.buttonHide.text:SetText("|cff999999Hide|r")
            self.frame.buttonHide:Enable()
        end
    end
end

local function ShowTooltip(lootRow)
    GameTooltip:ClearLines()
    GameTooltip:SetOwner(lootRow.frame.item, "ANCHOR_RIGHT", -120, -5)
    GameTooltip:SetHyperlink(lootRow.itemLink)
    GameTooltip:Show()
end

local function HideTooltip()
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

local function SetLootActionToggle(lootRow)
    if lootRow.lootAction == "MS" then
        LootHelper:ItemChanged(lootRow.lootIndex, nil, "OS")
    else
        LootHelper:ItemChanged(lootRow.lootIndex, nil, "MS")
    end
end

local function SetLootActionHidden(lootRow)
    LootHelper:ItemChanged(lootRow.lootIndex, nil, "HIDDEN")
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

    frame.prefix = CreateFrame("Frame", frameName.."_Prefix")
    frame.prefix:SetParent(frame)
    frame.prefix:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.prefix:SetHeight(15)
    frame.prefix:SetWidth(540)

    frame.prefix.title = frame.prefix:CreateFontString(frameName.."Prefix-Title", "ARTWORK", "GameFontNormalSmall")
    frame.prefix.title:SetParent(frame.prefix)
    frame.prefix.title:SetPoint("TOPLEFT", frame.prefix, "TOPLEFT", 31, -1)
    frame.prefix.title:SetText("|cffaaaaaaBoss name|r")

    frame.prefix.hrl = frame.prefix:CreateTexture(frameName.."Prefix-HRLeft")
    frame.prefix.hrl:SetParent(frame.prefix)
    frame.prefix.hrl:SetPoint("TOPLEFT", frame.prefix, "TOPLEFT", 3, 2)
    frame.prefix.hrl:SetPoint("TOPRIGHT", frame.prefix.title, "TOPLEFT", -3, 3)
    frame.prefix.hrl:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    frame.prefix.hrl:SetTexCoord(0.81, 0.94, 0.5, 1)

    frame.prefix.hrr = frame.prefix:CreateTexture(frameName.."Prefix-HRRight")
    frame.prefix.hrr:SetParent(frame.prefix)
    frame.prefix.hrr:SetPoint("TOPLEFT", frame.prefix.title, "TOPRIGHT", 3, 3)
    frame.prefix.hrr:SetPoint("TOPRIGHT", frame.prefix, "TOPRIGHT", -3, 2)
    frame.prefix.hrr:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    frame.prefix.hrr:SetTexCoord(0.81, 0.94, 0.5, 1)

    frame.prefix:Hide()

    -- frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    -- frame:SetBackdropColor(1,0,0,1)
    frame.item = CreateFrame("Frame", frameName.."_Item")
    frame.item:SetParent(frame)
    frame.item:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
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
    frame.buttonMS = CreateFrame("Button", frameName.."_ButtonMS", nil, "UIPanelButtonTemplate")
    frame.buttonMS:SetParent(frame)
    frame.buttonMS:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 4)
    frame.buttonMS:SetText("MS")
    frame.buttonMS:SetScript("OnClick", function() SetLootActionToggle(self) end)

    frame.buttonHide = CreateFrame("Button", frameName.."_ButtonHide")
    frame.buttonHide:SetParent(frame)
    frame.buttonHide:SetPoint("TOPRIGHT", frame.buttonMS, "TOPLEFT", -3, 0)
    frame.buttonHide:SetWidth(60)
    frame.buttonHide:SetHeight(23)
    frame.buttonHide:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    frame.buttonHide:SetScript("OnClick", function() SetLootActionHidden(self) end)

    frame.buttonHide.text = frame:CreateFontString( frameName.."_ButtonHide-Text", "ARTWORK", "GameFontNormal")
    frame.buttonHide.text:SetPoint("CENTER", frame.buttonHide, "CENTER", 0, 0)
    frame.buttonHide.text:SetJustifyH("CENTER")
    frame.buttonHide.text:SetText("|cff999999Hide|r")

    return self
end
