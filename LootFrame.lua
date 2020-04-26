local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

local LOOT_ROW_HEIGHT = 28


-- local function ScrollToBottom(self)
--     self:SetVerticalScroll(self.scrollChild:GetHeight()-1)
-- end


local function Update(self, raidLootData, readOnly)
    raidLootData = raidLootData or {}
    -- Check #rows and #items
    -- Create new rows

    local exisitingRows = #self.rows
    local lootCount = #raidLootData
    local missingRows = lootCount - exisitingRows
    if missingRows > 0 then
        for i = 1, missingRows do
            local currentRow = exisitingRows + i
            self.rows[currentRow] = UI.CreateLootRow()
            self.rows[currentRow]:SetHeight(LOOT_ROW_HEIGHT)
            self.rows[currentRow]:SetWidth(540)
            self.rows[currentRow]:SetParent(self.scrollChild)

            if currentRow == 1 then
                self.rows[currentRow]:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -5)
            else
                self.rows[currentRow]:SetPoint("TOPLEFT", self.rows[currentRow - 1].frame, "BOTTOMLEFT", 0, 0)
            end
        end
    end

    -- For loot in db
    local lootIndex = lootCount
    local height = 15
    for i = 1, #self.rows do
        local currentRow = self.rows[i]
        -- update row
        if lootIndex > 0 then
            -- currentRow:Update(raidLootData[lootIndex], readOnly)
            currentRow:Update(raidLootData[i], readOnly)
            currentRow:Show()
            lootIndex = lootIndex - 1

            if raidLootData[i].bossKill and (i == 1 or raidLootData[i].bossKill ~= raidLootData[i-1].bossKill) then
                height = height + LOOT_ROW_HEIGHT + 15
                currentRow:SetHeight(LOOT_ROW_HEIGHT + 15)
                currentRow.frame.prefix.title:SetText("|cffaaaaaa"..raidLootData[i].bossKill.."|r")
                currentRow.frame.prefix:Show()
            else
                height = height + LOOT_ROW_HEIGHT
                currentRow:SetHeight(LOOT_ROW_HEIGHT)
                currentRow.frame.prefix:Hide()
            end
        else
            currentRow:Hide()
        end
    end
    self.scrollChild:SetHeight(math.max(height, self:GetHeight()))
end


function UI.CreateLootFrame()
    local frameName = "HHLootHelper_UI-LootFrame"

    local scrollFrameName = frameName.."-ScrollFrame"
    local scrollFrame = CreateFrame("ScrollFrame", scrollFrameName, nil, "UIPanelScrollFrameTemplate")
    scrollFrame:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    scrollFrame:SetBackdropColor(0,0,0,1)
    scrollFrame:ClearAllPoints()
    scrollFrame:SetWidth(570)
    scrollFrame:SetHeight(550)

    scrollFrame.scrollChild = CreateFrame("Frame", frameName)
    scrollFrame.scrollChild:SetWidth(570)
    scrollFrame.scrollChild:SetHeight(550)

    scrollFrame.scrollupbutton = _G[scrollFrameName.."ScrollBarScrollUpButton"];
    scrollFrame.scrollupbutton:ClearAllPoints();
    scrollFrame.scrollupbutton:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -2, -2);

    scrollFrame.scrolldownbutton = _G[scrollFrameName.."ScrollBarScrollDownButton"];
    scrollFrame.scrolldownbutton:ClearAllPoints();
    scrollFrame.scrolldownbutton:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -2, 2);

    scrollFrame.scrollbar = _G[scrollFrameName.."ScrollBar"];
    scrollFrame.scrollbar:ClearAllPoints();
    scrollFrame.scrollbar:SetPoint("TOP", scrollFrame.scrollupbutton, "BOTTOM", 0, -2);
    scrollFrame.scrollbar:SetPoint("BOTTOM", scrollFrame.scrolldownbutton, "TOP", 0, 2);

    scrollFrame:SetScrollChild(scrollFrame.scrollChild)

    scrollFrame.Update = Update
    -- scrollFrame.ScrollToBottom = ScrollToBottom
    scrollFrame.rows = {}

    scrollFrame.playerList = UI.CreatePlayerList()
    scrollFrame.playerList:SetParent(scrollFrame)
    scrollFrame.playerList:SetPoint("CENTER", UI.frame, "CENTER", 0, 0)
    scrollFrame.playerList:SetFrameStrata("HIGH")

    return scrollFrame
end

