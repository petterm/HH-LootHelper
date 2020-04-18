local name, private = ...
local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

local function Update(self)
    local lootData = LootHelper.db.realm.currentRaid.loot

    -- Check #rows and #items
    -- Create new rows
    local exisitingRows = #self.rows
    local lootCount = #lootData
    local missingRows = lootCount - exisitingRows
    if missingRows > 0 then
        for i = 1, missingRows do
            local currentRow = exisitingRows + i
            self.rows[currentRow] = UI.CreateLootRow()
            self.rows[currentRow]:SetHeight(28)
            self.rows[currentRow]:SetWidth(540)
            self.rows[currentRow]:SetParent(self)
            self.rows[currentRow].rowIndex = currentRow

            if currentRow == 1 then
                self.rows[currentRow]:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
            else
                self.rows[currentRow]:SetPoint("TOPLEFT", self.rows[currentRow - 1].frame, "BOTTOMLEFT", 0, 0)
            end
        end
    end
    
    -- For loot in db
    for i = 1, #self.rows do
        -- update row
        if i <= lootCount then
            self.rows[i]:Update(lootData[i])
            self.rows[i]:Show()
        else
            self.rows[i]:Hide()
        end
    end

end

function UI.CreateLootFrame()
    local frameName = "HHLootHelper_UI-LootFrame"

    local frame = CreateFrame("Frame", frameName)
    frame:ClearAllPoints()
    frame:SetWidth(560)
    frame:SetHeight(550)
    frame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    frame:SetBackdropColor(0,0,0,1)

    frame.Update = Update

    frame.playerList = UI.CreatePlayerList()
    frame.playerList:SetParent(frame)
    frame.playerList:SetFrameStrata("DIALOG")
    frame.playerList:SetPoint("CENTER", UI.frame, "CENTER", 0, 0)

    frame.rows = {}

    return frame
end

