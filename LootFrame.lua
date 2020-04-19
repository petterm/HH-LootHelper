local name, private = ...
local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

local LOOT_ROW_HEIGHT = 28

local function Update(self, raidLootData)
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
            self.rows[currentRow].rowIndex = currentRow

            if currentRow == 1 then
                self.rows[currentRow]:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -5)
            else
                self.rows[currentRow]:SetPoint("TOPLEFT", self.rows[currentRow - 1].frame, "BOTTOMLEFT", 0, 0)
            end
        end
    end
    
    -- For loot in db
    local lootIndex = lootCount
    for i = 1, #self.rows do
        -- update row
        if lootIndex > 0 then
            self.rows[i]:Update(raidLootData[lootIndex])
            self.rows[i]:Show()
            lootIndex = lootIndex - 1
        else
            self.rows[i]:Hide()
        end
    end

    self.scrollChild:SetHeight(math.max(10 + (lootCount * LOOT_ROW_HEIGHT), self:GetHeight()))
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
    scrollFrame.rows = {}

    scrollFrame.playerList = UI.CreatePlayerList()
    scrollFrame.playerList:SetParent(scrollFrame)
    scrollFrame.playerList:SetPoint("CENTER", UI.frame, "CENTER", 0, 0)
    scrollFrame.playerList:SetFrameStrata("HIGH")

    return scrollFrame
end

