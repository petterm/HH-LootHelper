local _, LootHelper = ...
LootHelper = LibStub("AceAddon-3.0"):NewAddon(
    LootHelper, "HH-LootHelper",
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceComm-3.0"
)
_G.HHLootHelper = LootHelper


--[[

  TODO:
  - Add class colors to player names
  - Add remote sync for loot pickups
  - Add readonly mode (with sync updates from ML)

]]





LOOT_ACTION_MS = "MS"
LOOT_ACTION_OS = "OS"
LOOT_ACTION_IGNORE = "IGNORE"

local defaults = {
    realm = {
        currentRaid = nil,
        archivedRaids = {},
        penalty = 20,
        lootQualityThreshold = 4,
        noPenaltyItems = {
            18703, -- Ancient Petrified Leaf
            18646, -- The Eye of Divinity
        },
    },
}

local optionsTable = {
    type='group',
    name = "Held Hostile Loot Helper",
    desc = "Some tools to manage loot in PUG groups",
    icon = [[Interface\Icons\INV_Misc_GroupNeedMore]],
    args = {
        newRaid = {
            type = "execute",
            name = "New raid",
            desc = "Start tracking a new raid",
            func = function() LootHelper:NewRaid() end,
            order = 1,
            width = "half",
        },
        closeRaid = {
            type = "execute",
            name = "Close raid",
            desc = "Close the currently tracked raid",
            func = function() LootHelper:CloseRaid() end,
            order = 2,
            width = "half",
        },
        show = {
            type = "execute",
            name = "Open loot window",
            desc = "Open the loot window",
            func = function() LootHelper:Show() end,
            order = 3,
            width = "full",
        },
        debugAddSelf = {
            type = "execute",
            name = "Debug Add self loot",
            desc = "...",
            func = function() LootHelper:TestLootItemSelf() end,
            order = 4,
            width = "half",
        },
        debugAddOther = {
            type = "execute",
            name = "Debug Add other loot",
            desc = "...",
            func = function() LootHelper:TestLootItemOther() end,
            order = 5,
            width = "half",
        },
    }
}

local table, string = table, string
local deformat = LibStub("HH-Deformat").Deformat
local gui = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
AceConfig:RegisterOptionsTable("HH-LootHelper", optionsTable, { "hhlh" })
AceConfigDialog:AddToBlizOptions("HH-LootHelper", "HH Loot Helper")


--[[========================================================
                        SETUP
========================================================]]--
function LootHelper:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("HHLootHelperDB", defaults)
end


function LootHelper:OnEnable()
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("CHAT_MSG_RAID_WARNING")

    -- TODO: Enter raid instance event. Show popup to start new raid?
    
    -- self:RegisterChatCommand("hhlhtest", "TestLootItemSelf")
    -- self:RegisterChatCommand("hhlhtestother", "TestLootItemOther")

    -- self:Show()
end


--[[========================================================
                        CORE
========================================================]]--


-- Loot events
function LootHelper:CHAT_MSG_LOOT(_, msg)
    local loot = self:LootDecode( msg )
    if loot ~= nil then
        self:ItemLooted(loot)
    end
end


-- Roll events
function LootHelper:CHAT_MSG_SYSTEM(_, msg)
    local player, result, min, max = deformat(msg, RANDOM_ROLL_RESULT)
    if player and min == 1 and max == 100 then
        self:AddRoll(player, roll)
    end
end


-- New loot roll announce
function LootHelper:CHAT_MSG_RAID_WARNING(_, msg)
    -- Look for item link in message
    -- if ... then
    --     self:ItemAnnounced(itemName, itemLink, itemID)
    -- end
end


function LootHelper:ItemAnnounced(itemName, itemLink, itemID)
    -- Mark all previous rolls as old
    self:ArchiveRolls()

    -- Set item as "current roll item"
    -- To show in UI with rolls?

    -- show roll result ui
end


function LootHelper:ItemLooted(loot)
    if self.db.realm.currentRaid == nil then return end

    -- Only Epic items
    -- TODO: Is this correct?
    if loot.itemQuality < self.db.realm.lootQualityThreshold then return end

    if self:IsMasterLooter() then
        -- Add loot to master raid list as MS
        loot.lootAction = LOOT_ACTION_MS
        loot.index = table.getn(self.db.realm.currentRaid.loot) + 1
        self.db.realm.currentRaid.loot[loot.index] = loot

        -- Show popup UI to change to OS or Shard
    else
        -- Send addon message in case ML was out of range
    end
end


function LootHelper:ItemChanged(index, newPlayer, newAction)
    self:Print("ItemChanged", index, newPlayer, newAction)
    -- if not self:IsMasterLooter() then return end
    
    -- Item entry in loot list has changed somehow
    -- Changed loot status MS/OS/Shard
    -- Changed player (traded after the fact)
    if newPlayer ~= nil then
        self.db.realm.currentRaid.loot[index].player = newPlayer
    end
    if newAction ~= nil then
        self.db.realm.currentRaid.loot[index].lootAction = newAction
    end

    -- Should sync with other players
    self.UI:Update()
end


-- A before B if A has a higher roll result
function rollEntrySort(a, b)
    return a.result >= b.result
end
function LootHelper:AddRoll(player, roll)
    if not self:IsMasterLooter() then return end

    local penalty = self:GetPlayerPenalty(player)
    local result = roll - penalty
    
    local serverHour, serverMinute = GetGameTime()
    local entry = {
        player = player,
        roll = roll,
        penalty = penalty,
        result = result,
        date = time({year=date("%Y"), month=date("%m"), day=date("%d"), hour=serverHour, min=serverMinute}),
    }

    local activeRolls = self.db.realm.currentRaid.activeRolls
    table.insert(activeRolls, entry)
    table.sort(activeRolls, rollEntrySort)
end


-- Calcualte rolling players penalty and modify to result
  -- Skip OS items
  -- Add rules for special items that should not count penalties
function LootHelper:GetPlayerPenalty(player, itemID)
    if self.db.realm.noPenaltyItems[itemID] then return 0 end

    local penalty = 0
    for _, loot in ipairs(self.db.realm.currentRaid.loot) do
        if loot.player == player and loot.lootAction == LOOT_ACTION_MS then
            penalty = penalty - self.db.realm.currentRaid.penalty
        end
    end
    return penalty
end


function LootHelper:ArchiveRolls()
    local activeRolls = self.db.realm.currentRaid.activeRolls
    local historicRolls = self.db.realm.currentRaid.historicRolls

    for i=table.getn(activeRolls), 1, -1 do
        -- TODO: Update index
        table.insert(historicRolls, 1, activeRolls[i])
    end
    -- Clear activeRolls
    for k in pairs(activeRolls) do
        activeRolls[k] = nil
    end
end


function LootHelper:ActivateArchivedRoll(rollIndex)
    self:Print("ActivateArchivedRoll", rollIndex)
    local activeRolls = self.db.realm.currentRaid.activeRolls
    local historicRolls = self.db.realm.currentRaid.historicRolls
    
    -- Remove from history
    local archivedEntry = historicRolls[rollIndex]
    table.remove(historicRolls, rollIndex)

    -- Add to active and sort
    table.insert(activeRolls, archivedEntry)
    table.sort(activeRolls, rollEntrySort)
end


function LootHelper:NewRaid(callback)
    if not self:IsMasterLooter() then
        self:Print("Raid tracking failed. Player is not Master Looter in a raid.")
        return
    end

    -- Archive previous raid
    if self.db.realm.currentRaid ~= nil then
        self.db.realm.archivedRaids[self.db.realm.currentRaid.date] = self.db.realm.currentRaid
    end

    -- Start new raid entry
    local serverHour, serverMinute = GetGameTime()
    self.db.realm.currentRaid = {
        date = time({year=date("%Y"), month=date("%m"), day=date("%d"), hour=serverHour, min=serverMinute}),
        penalty = self.db.realm.penalty,
        loot = {},
        activeRolls = {},
        historicRolls = {},
        -- TODO:
        -- Owner tag? Or just require that only ML may modify?
        -- Might be messy if we try to synchronize while ML changes..
    }

    self:Print("New raid tracking started!")

    if callback ~= nil then
        callback(self.db.realm.currentRaid)
    end
end


function LootHelper:CloseRaid()
    -- Archive previous raid
    if self.db.realm.currentRaid ~= nil then
        self.db.realm.archivedRaids[self.db.realm.currentRaid.date] = self.db.realm.currentRaid
    end

    self.db.realm.currentRaid = nil
end


function LootHelper:IsMasterLooter()
    lootMethod, masterlooterPartyID = GetLootMethod()
    return lootMethod == "master" and masterlooterPartyID == 0
end


--[[========================================================
                        UI
========================================================]]--

function LootHelper:Show()
    -- Show loot UI
    -- UI should be read only for players that are not ML
    
    -- Archive rolls that are old?

    -- self:UIBase()
    self.UI:Create()
    self.UI:Show()
end


function LootHelper:UIBase()
    -- Main UI frame
    local frame = gui:Create("Frame")
    frame:SetTitle("HH Loot Helper")
    frame:SetWidth(800)
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget) gui:Release(widget) end)

    local loot = self:UILoot()
    -- loot:SetRelativeWidth(0.6)
    frame:AddChild(loot)
    local rolls = self:UIRolls()
    rolls:SetRelativeWidth(0.4)
    frame:AddChild(rolls)

    return frame
end


function LootHelper:UIRolls()
    -- Rolls frame
    local frame = gui:Create("SimpleGroup")
    frame:SetFullHeight(true)
    frame:SetLayout("Fill")

    scroll = gui:Create("ScrollFrame")
    scroll:SetLayout("List")

    -- Includes current rolls and historic rolls
    scroll:AddChild(self:UIRollsActive())
    scroll:AddChild(self:UIRollsHistory())

    frame:AddChild(scroll)

    return frame
end


function LootHelper:UIRollsActive()
    -- Rolls that are relevant to current item
    local frame = gui:Create("SimpleGroup")
    local heading = gui:Create("Heading")
    heading:SetText("Active rolls")

    local rolls = self.db.realm.currentRaid.activeRolls
    for index, roll in ipairs(rolls) do
        local rollFrame = self:UIRollsActiveEntry(roll)
        frame:AddChild(rollFrame)
    end
    
    return frame
end


function LootHelper:UIRollsActiveEntry(roll)
    local frame = gui:Create("SimpleGroup")
    frame:SetFullWidth(true)
    frame:SetLayout("Flow")

    local player = gui:Create("Label")
    player:SetText(roll.player)
    player:SetFontObject(GameFontNormalSmall)
    player:SetRelativeWidth(0.7)
    frame:AddChild(player)

    local roll = gui:Create("Label")
    roll:SetText(roll.roll)
    roll:SetFontObject(GameFontNormalSmall)
    roll:SetColor(0.4, 0.4, 0.4)
    roll:SetRelativeWidth(0.1)
    frame:AddChild(roll)

    local penalty = gui:Create("Label")
    penalty:SetText(-roll.penalty)
    penalty:SetFontObject(GameFontNormalSmall)
    penalty:SetColor(0.4, 0.4, 0.4)
    penalty:SetRelativeWidth(0.1)
    frame:AddChild(penalty)

    local score = gui:Create("Label")
    score:SetText(roll.score)
    score:SetFontObject(GameFontNormalSmall)
    score:SetRelativeWidth(0.1)
    frame:AddChild(score)

    return frame
end


function LootHelper:UIRollsHistory()
    -- Previous rolls made before current item was announced
    -- Hide rolls that are too old?
    -- Button to "activate" a roll to include it in active-list
    local frame = gui:Create("SimpleGroup")
    local heading = gui:Create("Heading")
    heading:SetText("Past rolls")

    local rolls = self.db.realm.currentRaid.historicRolls
    for index, roll in ipairs(rolls) do
        local rollFrame = self:UIRollsHistoryEntry(roll)
        frame:AddChild(rollFrame)
    end
    
    return frame
end


function LootHelper:UIRollsHistoryEntry(roll)
    local frame = gui:Create("SimpleGroup")
    frame:SetFullWidth(true)
    frame:SetLayout("Flow")

    local player = gui:Create("InteractiveLabel")
    player:SetText(roll.player)
    player:SetFontObject(GameFontNormalSmall)
    player:SetColor(0.4, 0.4, 0.4)
    player:SetRelativeWidth(0.7)
    -- TODO: Expects local index but entry property is original index from creation
    player:SetCallback("OnClick", function() self:ActivateArchivedRoll(roll.index) end)
    frame:AddChild(player)

    local roll = gui:Create("Label")
    roll:SetText(roll.roll)
    roll:SetFontObject(GameFontNormalSmall)
    roll:SetColor(0.4, 0.4, 0.4)
    roll:SetRelativeWidth(0.1)
    frame:AddChild(roll)

    local penalty = gui:Create("Label")
    penalty:SetText(-roll.penalty)
    penalty:SetFontObject(GameFontNormalSmall)
    penalty:SetColor(0.4, 0.4, 0.4)
    penalty:SetRelativeWidth(0.1)
    frame:AddChild(penalty)

    local score = gui:Create("Label")
    score:SetText(roll.score)
    score:SetFontObject(GameFontNormalSmall)
    score:SetColor(0.4, 0.4, 0.4)
    score:SetRelativeWidth(0.1)
    frame:AddChild(score)

    return frame
end


function LootHelper:UILoot()
    -- All previously looted items with who looted them
    -- New items at top or bottom?
    local uiLootFrame = gui:Create("SimpleGroup")
    uiLootFrame:SetFullHeight(true)
    uiLootFrame:SetWidth(540)
    uiLootFrame:SetLayout("Fill")

    uiLootScrollFrame = gui:Create("ScrollFrame")
    uiLootScrollFrame:SetLayout("List")
    
    local lootList = self.db.realm.currentRaid.loot
    for index, loot in ipairs(lootList) do
        local lootFrame = self:UILootEntry(loot)
        uiLootScrollFrame:AddChild(lootFrame)
    end

    uiLootFrame:AddChild(uiLootScrollFrame)

    return uiLootFrame
end


function LootHelper:UILootEntry(loot)
    -- local frame = gui:Create("InlineGroup")
    local frame = gui:Create("SimpleGroup")
    frame:SetFullWidth(true)
    frame:SetLayout("Flow")

    local item = gui:Create("InteractiveLabel")
    item:SetWidth(250)
    item:SetText(loot.itemName)
    item:SetColor(
        ITEM_QUALITY_COLORS[loot.itemQuality].r,
        ITEM_QUALITY_COLORS[loot.itemQuality].g,
        ITEM_QUALITY_COLORS[loot.itemQuality].b
    )
    item:SetImage(loot.itemTexture)
    item:SetImageSize(24, 24)
    item:SetFontObject(GameFontNormal)
    item:SetCallback("OnEnter", function() self:ShowItemTooltip(loot, item) end)
    item:SetCallback("OnLeave", function() if self.itemTooltip ~= nil then self.itemTooltip:Hide() end end)
    frame:AddChild(item)

    local player = gui:Create("InteractiveLabel")
    player:SetWidth(100)
    player:SetText(loot.player)
    player:SetFontObject(GameFontNormalSmall)
    player:SetCallback("OnClick", function() self:Print("Loot player click", loot.itemName, loot.player) end)
    frame:AddChild(player)

    -- Action buttons
    local action = gui:Create("SimpleGroup")
    action:SetLayout("Flow")
    action:SetWidth(170)

    local ms = gui:Create("Button")
    ms:SetText("MS")
    ms:SetWidth(55)
    if loot.lootAction == LOOT_ACTION_MS then ms:SetDisabled(true) else ms:SetDisabled(false) end
    action:AddChild(ms)

    local os = gui:Create("Button")
    os:SetText("OS")
    os:SetWidth(55)
    if loot.lootAction == LOOT_ACTION_OS then os:SetDisabled(true) else os:SetDisabled(false) end
    action:AddChild(os)

    local ignore = gui:Create("Button")
    ignore:SetText("--")
    ignore:SetWidth(55)
    if loot.lootAction == LOOT_ACTION_IGNORE then ignore:SetDisabled(true) else ignore:SetDisabled(false) end
    action:AddChild(ignore)

    ms:SetCallback("OnClick", function()
        self:ItemChanged(loot.index, nil, LOOT_ACTION_MS)
        ms:SetDisabled(true)
        os:SetDisabled(false)
        ignore:SetDisabled(false)
    end)
    os:SetCallback("OnClick", function()
        self:ItemChanged(loot.index, nil, LOOT_ACTION_OS)
        ms:SetDisabled(false)
        os:SetDisabled(true)
        ignore:SetDisabled(false)
    end)
    ignore:SetCallback("OnClick", function()
        self:ItemChanged(loot.index, nil, LOOT_ACTION_IGNORE)
        ms:SetDisabled(false)
        os:SetDisabled(false)
        ignore:SetDisabled(true)
    end)

    frame:AddChild(action)

    -- Try to include some rolls that were made for the item?

    return frame
end


function LootHelper:ShowItemTooltip(loot, parent)
    local linkTemplate = "item:%d:0:0:0:0:0:0:0"
    local link = string.format(linkTemplate, loot.itemID)

    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
end


function LootHelper:PrintTable(t)
    for key, value in pairs(t) do
        self:Print(key, value)
    end
end


------------
-- Decode Loot message
function LootHelper:LootDecode(msg)
    -- Other multiple
    local player, item, ammount = deformat(msg, LOOT_ITEM_MULTIPLE)
    
    -- Player multiple
    if not player or not ammount then
        player, item, ammount = deformat(msg, LOOT_ITEM_SELF_MULTIPLE)
    end
    
    -- Other single
    if not ammount then
        player, item = deformat(msg, LOOT_ITEM)
        ammount = 1
    end
    
    -- Self single
    if not player then
        item = deformat(msg, LOOT_ITEM_SELF)
        player = UnitName("player")
    end 
    
    -- System message was not a loot message
    if not item or not player then
        return nil
    end
    
    local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(item)
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    
    -- Invalid item looted?
    if not itemName or not itemID or not itemQuality then
        return nil
    end
    
    local serverHour, serverMinute = GetGameTime()
    return {
        date = time({year=date("%Y"), month=date("%m"), day=date("%d"), hour=serverHour, min=serverMinute}),
        player = player,
        itemName = itemName,
        itemID = itemID,
        itemLink = itemLink,
        itemQuality = itemQuality,
        itemTexture = itemTexture,
        ammount = ammount
    }
end



function LootHelper:GetRaidPlayers()
    if not UnitInRaid("player") then
        return nil, nil
    end

    local names = {}
    local index = 0

    for i=1, MAX_RAID_MEMBERS do
        local name = GetRaidRosterInfo(i)
        if name ~= nil then
            index = index + 1
            names[index] = name
        end
    end

    return names, index
end


---------------------
-- Capitalize first letter
function LootHelper:UtilCap( str )
    if string.len( str ) > 1 then
        str = string.upper( string.sub( str, 1, 1 ) ) .. string.lower( string.sub( str, 2 ) )
    else
        str = string.upper( str )
    end
    return str
end


local CLASS_COLOR_FORMAT = "|c%s%s|r"
local CLASS_NAMES_WITH_COLORS
function LootHelper:GetColoredClassNames()
	if not CLASS_NAMES_WITH_COLORS then
		CLASS_NAMES_WITH_COLORS = {}
		for k, v in pairs(RAID_CLASS_COLORS) do
			if v.colorStr then
				CLASS_NAMES_WITH_COLORS[k] = format(CLASS_COLOR_FORMAT,  v.colorStr, k)
			end
		end
	end
	return CLASS_NAMES_WITH_COLORS
end

local ITEM_COLORS
function LootHelper:GetItemColors()
    if not ITEM_COLORS then
        ITEM_COLORS = {}
        for i=0,7 do
            local _, _, _, itemQuality = GetItemQualityColor(i)
            ITEM_COLORS[i] = itemQuality
        end
    end
    return ITEM_COLORS
end


--[[========================================================
                        TEST
========================================================]]--

function LootHelper:TestItem()
    local items = {
        18816,
        18814,
    }
    local itemID = items[math.random(1, table.getn(items))]
    itemName, itemLink = GetItemInfo(itemID)

    if itemName == nil or itemLink == nil then
        self:Print("Error receiving item information. Probably too early after login?")
    end

    return itemName, itemLink
end


-- TODO: Add LOOT_ITEM_SELF_MULTIPLE
function LootHelper:TestLootItemSelf()
    local itemName, itemLink = self:TestItem()
    msg = string.format(LOOT_ITEM_SELF, itemLink)
    self:CHAT_MSG_LOOT("CHAT_MSG_LOOT", msg)
end


-- TODO: Add LOOT_ITEM_MULTIPLE
function LootHelper:TestLootItemOther()
    local itemName, itemLink = self:TestItem()
    if itemName == nil then return end

    local names, count
    if UnitInRaid("player") then
        names, count = self:GetRaidPlayers()
    else
        local name = UnitName("player")
        names = { name }
        count = 1
    end

    local player = self:UtilCap(names[math.random(1, count)])
    msg = string.format(LOOT_ITEM, player, itemLink)
    self:CHAT_MSG_LOOT("CHAT_MSG_LOOT", msg)
end
