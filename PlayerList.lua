local name, private = ...
local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

--[[
    TODO
    - Fix anchor location to follow main window (Strata related?)
]]


local playerList

local function SetParent(self, parent)
    self.frame:SetParent(parent)
end

local function SetPoint(self, ...)
    self.frame:SetPoint(...)
end

local function SetFrameStrata(self, ...)
    self.frame:SetFrameStrata(...)
end

local function Show(self, ...)
    self.frame:Show(...)
end

local function Hide(self, ...)
    self.frame:Hide(...)
end

local function UpdateRow(self, player, playerClass)
    local colorStr = RAID_CLASS_COLORS[playerClass or "WARRIOR"].colorStr
    self.text:SetText("|c"..colorStr..player.."|r")
    self.player = player
end

local function Update(self, itemIndex)
    self.itemIndex = itemIndex

    local data = LootHelper.db.realm.currentRaid

    local playerCount = #data.players
    for i = 1, 40 do
        if i <= playerCount then
            self.players[i]:Update(data.players[i].name, data.players[i].class)
            self.players[i]:Show()
        else
            self.players[i]:Hide()
        end
    end

    self.frame:Show()
end

function UI.CreatePlayerList()
    self = {}
    local frameName = "HHLootHelper_UI-PlayerList"
    local frame = CreateFrame("Frame", frameName)
    self.frame = frame
    self.SetPoint = SetPoint
    self.SetParent = SetParent
    self.SetFrameStrata = SetFrameStrata
    self.Show = Show
    self.Hide = Hide
    self.Update = Update
    self.players = {}

    frame:ClearAllPoints()
    frame:SetWidth(620)
    frame:SetHeight(220)
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame:SetBackdropColor(0,0,0,1)
    frame:SetScript("OnHide", function() frame:Hide() end)
    
    for i = 1, 40 do
        playerFrameName = frameName.."-PlayerFrame"..i
        local playerFrame = CreateFrame("Button", playerFrameName)
        playerFrame:ClearAllPoints()
        playerFrame:SetParent(frame)
        playerFrame:SetWidth(150)
        playerFrame:SetHeight(20)
        playerFrame:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        playerFrame:SetScript("OnMouseDown", function()
            LootHelper:ItemChanged(self.itemIndex, playerFrame.player, nil)
            frame:Hide()
        end)

        playerFrame.Update = UpdateRow
        playerFrame.playerIndex = i
        playerFrame.text = playerFrame:CreateFontString(playerFrameName.."-Text", "ARTWORK", "GameFontNormalSmall")
        playerFrame.text:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", 5, -5)
        playerFrame.text:SetJustifyH("LEFT")
        playerFrame.text:SetText("[Player "..i.."]")
        if mod(i, 10) == 1 then
            if i == 1 then
                playerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10)
            else
                playerFrame:SetPoint("TOPLEFT", self.players[i-10], "TOPRIGHT", 0, 0)
            end
        else
            playerFrame:SetPoint("TOPLEFT", self.players[i-1], "BOTTOMLEFT", 0, 0)
        end

        self.players[i] = playerFrame
    end

    frame:Hide()
    playerList = self
    return self
end