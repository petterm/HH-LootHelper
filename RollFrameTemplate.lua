local name, private = ...
local LootHelper = _G.HHLootHelper
local UI = LootHelper.UI

local ROLL_ROW_HEIGHT = 20
local WINDOW_WIDTH = 320

local function Update(self, rolls)
    rolls = rolls or {}

    local exisitingRows = #self.rows
    local rollCount = #rolls
    local missingRows = rollCount - exisitingRows
    if missingRows > 0 then
        for i = 1, missingRows do
            local currentRow = exisitingRows + i
            self.rows[currentRow] = UI.CreateRollRow(self.isActiveList)
            self.rows[currentRow]:SetHeight(ROLL_ROW_HEIGHT)
            self.rows[currentRow]:SetWidth(WINDOW_WIDTH - 35)
            self.rows[currentRow]:SetParent(self.scrollChild)
            self.rows[currentRow].rowIndex = currentRow

            if currentRow == 1 then
                self.rows[currentRow]:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -5)
            else
                self.rows[currentRow]:SetPoint("TOPLEFT", self.rows[currentRow - 1].frame, "BOTTOMLEFT", 0, 0)
            end
        end
    end

    -- For rolls in db
    for i = 1, #self.rows do
        -- update row
        if i <= rollCount then
            self.rows[i]:Update(rolls[i])
            self.rows[i]:Show()
        else
            self.rows[i]:Hide()
        end
    end

    self.scrollChild:SetHeight(math.max(10 + (rollCount * ROLL_ROW_HEIGHT), self:GetHeight()))
end


function UI.CreateRollFrame(isActiveList)
    local frameName = "HHLootHelper_UI-RollFrame"
    if isActiveList then
        frameName = frameName.."Active"
    else
        frameName = frameName.."Historic"
    end

    local scrollFrameName = frameName.."-ScrollFrame"
    local scrollFrame = CreateFrame("ScrollFrame", scrollFrameName, nil, "UIPanelScrollFrameTemplate")
    scrollFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                        tile = true, tileSize = 16, edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }})
    scrollFrame:SetBackdropColor(0,0,0,1)
    scrollFrame:SetWidth(WINDOW_WIDTH)

    scrollFrame.scrollChild = CreateFrame("Frame", frameName)
    scrollFrame.scrollChild:SetWidth(WINDOW_WIDTH)
    scrollFrame.scrollChild:SetHeight(100)

    scrollFrame.scrollupbutton = _G[scrollFrameName.."ScrollBarScrollUpButton"];
    scrollFrame.scrollupbutton:ClearAllPoints();
    scrollFrame.scrollupbutton:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -4, -4);
    
    scrollFrame.scrolldownbutton = _G[scrollFrameName.."ScrollBarScrollDownButton"];
    scrollFrame.scrolldownbutton:ClearAllPoints();
    scrollFrame.scrolldownbutton:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", -4, 4);
    
    scrollFrame.scrollbar = _G[scrollFrameName.."ScrollBar"];
    scrollFrame.scrollbar:ClearAllPoints();
    scrollFrame.scrollbar:SetPoint("TOP", scrollFrame.scrollupbutton, "BOTTOM", 0, -4);
    scrollFrame.scrollbar:SetPoint("BOTTOM", scrollFrame.scrolldownbutton, "TOP", 0, 4);

    scrollFrame:SetScrollChild(scrollFrame.scrollChild)

    scrollFrame.Update = Update
    scrollFrame.rows = {}
    scrollFrame.isActiveList = isActiveList

    return scrollFrame
end