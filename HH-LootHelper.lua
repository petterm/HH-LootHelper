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

  Bugs:
  - LootRow player name color is wrong when changing name in an archived raid

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
        addLoot = {
            type = "input",
            name = "Add loot item",
            desc = "Add loot item to current raid",
            usage = "<player> <item>",
            set = function(info, value, ...)
                LootHelper:ItemLootedManual(value)
            end,
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


function LootHelper:ItemLootedManual(value)
    local splitLoc = string.find(value, " ")
    if not splitLoc then
        self:Print("Usage: <player name> <item link/itemID>")
        return
    end

    local player = string.sub(value, 1, splitLoc - 1)
    local item = string.sub(value, splitLoc +  1)
    if not player or not item then
        self:Print("Usage: <player name> <item link/itemID>")
        return
    end

    local loot = self:GetItemInfo(item, player)
    if loot == nil then
        self:Print("Invalid item to add")
    end

    self:ItemLooted(loot)
end


function LootHelper:ItemLooted(loot)
    local raidData = self:GetSelectedRaidData()
    if not raidData.active then return end

    -- Only Epic items
    if loot.itemQuality < self.db.realm.lootQualityThreshold then return end

    if self:IsMasterLooter() then
        -- Add loot to master raid list as MS
        loot.lootAction = LOOT_ACTION_MS
        loot.index = table.getn(raidData.loot) + 1
        loot.playerClass = self:GetPlayerClass(loot.player)
        raidData.loot[loot.index] = loot

        -- Show popup UI to change to OS or Shard
    else
        -- Send addon message in case ML was out of range
    end

    self.UI:Update(raidData)
end


function LootHelper:ItemChanged(index, newPlayer, newAction)
    local raidData = self:GetSelectedRaidData()
    if raidData.active and not self:IsMasterLooter() then return end
    
    -- Item entry in loot list has changed somehow
    -- Changed loot status MS/OS/Shard
    -- Changed player (traded after the fact)
    if newPlayer ~= nil then
        raidData.loot[index].player = newPlayer
    end
    if newAction ~= nil then
        raidData.loot[index].lootAction = newAction
    end

    -- Should sync with other players
    self.UI:Update(raidData)
end


-- A before B if A has a higher roll result
local function rollEntrySort(a, b)
    return a.result > b.result
end
function LootHelper:AddRoll(player, roll)
    local raidData = self:GetSelectedRaidData()
    if raidData.active and not self:IsMasterLooter() then return end

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

    local activeRolls = raidData.activeRolls
    table.insert(activeRolls, entry)
    table.sort(activeRolls, rollEntrySort)
end


-- Calcualte rolling players penalty and modify to result
  -- Skip OS items
  -- Add rules for special items that should not count penalties
function LootHelper:GetPlayerPenalty(player, itemID, raidData)
    if self.db.realm.noPenaltyItems[itemID] then return 0 end

    local penalty = 0
    for _, loot in ipairs(raidData.loot) do
        if loot.player == player and loot.lootAction == LOOT_ACTION_MS then
            penalty = penalty - raidData.penalty
        end
    end
    return penalty
end


function LootHelper:ArchiveRolls()
    local raidData = self:GetSelectedRaidData()
    if raidData.active and not self:IsMasterLooter() then return end

    local activeRolls = raidData.activeRolls
    local historicRolls = raidData.historicRolls

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
    local raidData = self:GetSelectedRaidData()
    if raidData.active and not self:IsMasterLooter() then return end

    local activeRolls = raidData.activeRolls
    local historicRolls = raidData.historicRolls
    
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
    self:CloseRaid()

    -- Start new raid entry
    local serverHour, serverMinute = GetGameTime()
    self.db.realm.currentRaid = {
        active = true,
        loot = {},
        activeRolls = {},
        historicRolls = {},
        date = time({year=date("%Y"), month=date("%m"), day=date("%d"), hour=serverHour, min=serverMinute}),
        penalty = self.db.realm.penalty,
        players = self:GetRaidPlayers()
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
        self.db.realm.currentRaid.active = false
        self.db.realm.archivedRaids[self.db.realm.currentRaid.date] = self.db.realm.currentRaid
    end

    self.db.realm.currentRaid = nil
end


function LootHelper:Update()
    local raidData = self:GetSelectedRaidData()
    if raidData and raidData.active then
        self.db.realm.currentRaid.players = self:GetRaidPlayers()
    end
end


function LootHelper:IsMasterLooter()
    return true
    -- lootMethod, masterlooterPartyID = GetLootMethod()
    -- return lootMethod == "master" and masterlooterPartyID == 0
end


function LootHelper:GetPlayerClass(playerName)
    local raidData = self:GetSelectedRaidData()
    for k, playerData in ipairs(raidData.players) do
        if playerData.name == playerName then
            return playerData.class
        end
    end
    return nil
end


function LootHelper:GetSelectedRaidData()
    -- return self.db.realm.currentRaid
    return self.db.realm.archivedRaids[1587228660]
end

--[[========================================================
                        UI
========================================================]]--

-- Show loot UI
-- UI should be read only for players that are not ML
-- Archive rolls that are old?
function LootHelper:Show()
    local raidData = self:GetSelectedRaidData()

    self:Update()
    self.UI:Create()
    self.UI:Update(raidData)
    self.UI:Show()
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
    
    return self:GetItemInfo(item, player)
end


function LootHelper:GetItemInfo(item, player)
    local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(item)
    if not itemName then
        return nil
    end

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

-- A before B if we return true
local function raidPlayerSort(a, b)
    if (a.class == b.class) then
        return a.name < b.name
    end
    return a.class < b.class
end
function LootHelper:GetRaidPlayers()
    local players = {}
    local index = 0
    
    if not UnitInRaid("player") then
        -- return nil

        -- TEMP
        players = {
            { name = "Meche", class = "WARRIOR" },
            { name = "Grillspett", class = "PRIEST" },
            { name = "Hubbé", class = "HUNTER"},
            { name = "Deaurion", class = "WARRIOR" },
        }
        index = 4

        table.sort(players, raidPlayerSort)
        return players, index
    end

    local players = {}
    local index = 0

    for i=1, MAX_RAID_MEMBERS do
        local name, _, _, _, class = GetRaidRosterInfo(i)
        if name ~= nil then
            index = index + 1
            players[index] = {
                name = name,
                class = strupper(class),
            }
        end
    end

    table.sort(players, raidPlayerSort)

    return players, index
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

    local players, count
    if UnitInRaid("player") then
        players, count = self:GetRaidPlayers()
    else
        local name = UnitName("player")
        local _, class = UnitClass("player")
        players = { name = name, class = strupper(class) }
        count = 1
    end

    local player = self:UtilCap(players[math.random(1, count)])
    msg = string.format(LOOT_ITEM, player.name, itemLink)
    self:CHAT_MSG_LOOT("CHAT_MSG_LOOT", msg)
end
