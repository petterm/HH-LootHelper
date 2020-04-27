local _, LootHelper = ...
LootHelper = LibStub("AceAddon-3.0"):NewAddon(
    LootHelper, "HH-LootHelper",
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceComm-3.0",
    "AceSerializer-3.0"
)
_G.HHLootHelper = LootHelper


--[[

  TODO:
  - Add remote sync for loot pickups
  - Add readonly mode (with sync updates from ML)

  Bugs:
  - LootRow player name color is wrong when changing name in an archived raid

]]

-- Server time as timestamp
local function timestamp()
    local serverHour, serverMinute = GetGameTime()
    return time({year=date("%Y"), month=date("%m"), day=date("%d"), hour=serverHour, min=serverMinute})
end

-- A before B if A has a higher roll result
local function rollEntrySort(a, b)
    return a.result > b.result
end

-- New rolls at the top
local function rollHistoricSort(a, b)
    return a.date > b.date
end

local defaults = {
    profile = {
        viewArchive = nil,
        activeRolls = {},
        historicRolls = {},
    },
    realm = {
        currentRaid = nil,
        archivedRaids = {},
        penalty = 20,
        lootQualityThreshold = 1,
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
        show = {
            type = "execute",
            name = "Open loot window",
            desc = "Open the loot window",
            func = function() LootHelper:Show() end,
            order = 13,
            width = "full",
        },
        newRaid = {
            type = "execute",
            name = "New raid",
            desc = "Start tracking a new raid",
            func = function() LootHelper:NewRaid() end,
            order = 2,
            width = 1.77,
        },
        closeRaid = {
            type = "execute",
            name = "Close raid",
            desc = "Close the currently tracked raid",
            func = function() LootHelper:CloseRaid() end,
            order = 3,
            width = 1.77,
        },
        debugAddSelf = {
            type = "execute",
            name = "Debug Add self loot",
            desc = "...",
            func = function() LootHelper:TestLootItemSelf() end,
            order = 4,
            width = 1.77,
        },
        debugAddOther = {
            type = "execute",
            name = "Debug Add other loot",
            desc = "...",
            func = function() LootHelper:TestLootItemOther() end,
            order = 5,
            width = 1.77,
        },
        debugBossKill = {
            type = "execute",
            name = "Debug Flag boss killed",
            desc = "...",
            func = function() LootHelper:TestBossKill() end,
            order = 6,
            width = 1.77,
        },
        showArchive = {
            type = "select",
            name = "View archived raid",
            desc = "Select archived raid to view",
            values = function()
                local values = {}
                values[0] = '- None -'
                for _, v in ipairs(LootHelper:GetArchivedRaids()) do
                    values[v.id] = v.label
                end
                return values
            end,
            get = function()
                return LootHelper:GetSelectedArchivedRaid() or 0
            end,
            set = function(_, value)
                if value ~= 0 then
                    LootHelper:SelectArchivedRaid(value)
                    LootHelper:Show()
                else
                    LootHelper:SelectArchivedRaid()
                    LootHelper.UI:UpdateLoot(LootHelper:GetSelectedRaidData())
                end
                LootHelper:LDBUpdate()
            end,
            order = 7,
            width = "full",
        },
        addLoot = {
            type = "input",
            name = "Add loot item",
            desc = "Add loot item to current raid",
            usage = "<player> <item>",
            set = function(_, value)
                LootHelper:ItemLootedManual(value)
            end,
            order = 8,
            width = "full",
        },
    }
}

local table, string = table, string
local deformat = LibStub("HH-Deformat").Deformat
local bossID = LibStub("LibBossIDs-1.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
AceConfig:RegisterOptionsTable("HH-LootHelper", optionsTable, { "hhlh" })
local blizzOptionsFrame = AceConfigDialog:AddToBlizOptions("HH-LootHelper", "HH Loot Helper")

--[[========================================================
                        SETUP
========================================================]]--
function LootHelper:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("HHLootHelperDB", defaults)
    self.ldb = LibStub("LibDataBroker-1.1"):NewDataObject("HHLootHelper", {
        type = "data source",
        label = "HHLootHelper",
        text  = LootHelper:LDBText(),
        OnTooltipShow = function(tooltip)
            LootHelper:LDBShowTooltip(tooltip)
        end,
        OnClick = function(_, button)
            if ( button == "LeftButton" ) then
                if LootHelper.UI.frame and LootHelper.UI.frame:IsVisible() then
                    LootHelper.UI:Hide()
                else
                    LootHelper:Show()
                end
            elseif ( button == "RightButton" ) then
                InterfaceOptionsFrame_OpenToCategory(blizzOptionsFrame)
            end
        end,
    })
    self.Comm.Initialize()
end


function LootHelper:OnEnable()
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("CHAT_MSG_RAID_WARNING")
end


--[[========================================================
                    EVENT HANDLERS
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
    local player, roll, min, max = deformat(msg, RANDOM_ROLL_RESULT)
    if player and min == "1" and max == "100" then
        self:AddRoll(player, roll)
    end
end


-- Roll events
function LootHelper:COMBAT_LOG_EVENT_UNFILTERED()
    local _, eventType, _, _, _, _, _, sourceGUID, sourceName = CombatLogGetCurrentEventInfo()
    if eventType == "UNIT_DIED" and sourceGUID then
        local mobID = 0
        local mobIDStr = select(6, strsplit("-", sourceGUID))
        if (mobIDStr) then
            mobID = tonumber(mobIDStr)
        end

        if bossID.BossIDs[mobID] then
            self:FlagBossDeath(sourceName)
            return
        end

        -- Special case for Majordomo ads, since the boss does not die
        if mobID == 11663 then
            self:FlagBossDeath("Majordomo Executus")
            return
        end
    end
end


-- New loot roll announce
local itemLinkPattern = "|c%x+|Hitem:%d+[:%d]+|h%[.+%]|h|r"
function LootHelper:CHAT_MSG_RAID_WARNING(_, msg) -- , _, _, _, player)
    -- Look for item link in message
    if string.find(msg, itemLinkPattern) then
        local raidData = self:GetSelectedRaidData()
        if not raidData or self:ReadOnly(raidData) then return end
        self:Print("Found item link message")
        self:ArchiveRolls()
    end
end


--[[========================================================
                        CORE
========================================================]]--


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


function LootHelper:ItemLooted(loot, isRemote)
    local raidData = self:GetSelectedRaidData()
    if not raidData then return end

    -- Only Epic+ items
    if loot.itemQuality < self.db.realm.lootQualityThreshold then return end

    if self:ReadOnly(raidData) then
        -- Send addon message in case owner was out of range
        if raidData.active and raidData.owner then
            self.Comm:SendItemLooted(loot, raidData.owner)
        end
    else
        if isRemote and self:LootIsDuplicate(loot, raidData) then
            return
        end

        -- Add loot to master raid list as MS
        loot.lootAction = "MS"
        loot.index = #raidData.loot + 1
        loot.playerClass = self:GetPlayerClass(loot.player)
        loot.bossKill = raidData.bossKill

        raidData.loot[loot.index] = loot
        raidData.version = raidData.version + 1

        self.Comm:SendLootAdded(loot, raidData)

        -- TODO: Show popup UI to change to OS or Shard
    end

    self.UI:UpdateLoot(raidData)
    -- Only want to scroll down when items are added, not on all updates.
    -- Dont like this coupling but oh well.
    -- if self.UI.frame then self.UI.frame.lootFrame:ScrollToBottom() end
end


function LootHelper:ItemChanged(index, newPlayer, newAction)
    local raidData = self:GetSelectedRaidData()
    if self:ReadOnly(raidData) then return end

    -- Item entry in loot list has changed somehow
    -- Changed loot status MS/OS/Shard
    -- Changed player (traded after the fact)
    if newPlayer ~= nil then
        raidData.loot[index].player = newPlayer
        raidData.loot[index].playerClass = self:GetPlayerClass(newPlayer)
    end
    if newAction ~= nil then
        raidData.loot[index].lootAction = newAction
    end

    raidData.version = raidData.version + 1

    self.Comm:SendLootUpdated(raidData.loot[index], raidData)

    -- Should sync with other players
    self.UI:UpdateLoot(raidData)
end


function LootHelper:NewRaid(callback)
    -- if not UnitInRaid("player") then
    --     self:Print("Raid tracking failed. Player is not in a raid.")
    --     return
    -- end

    -- Archive previous raid
    self:CloseRaid()

    -- Start new raid entry
    self.db.realm.currentRaid = {
        active = true,
        date = timestamp(),
        loot = {},
        owner = UnitName("player"),
        penalty = self.db.realm.penalty,
        players = self:GetRaidPlayers(),
        version = 1,
    }

    self.Comm:SendRaidNew(self.db.realm.currentRaid)

    self:Print("New raid tracking started!")
    self:LDBUpdate()

    if callback ~= nil then
        callback(self.db.realm.currentRaid)
    end
end


function LootHelper:CloseRaid()
    local currentRaid = self.db.realm.currentRaid
    if not currentRaid then return end
    if self:ReadOnly(currentRaid) then
        self:Print("Close raid failed. Raid is read-only")
        return
    end

    -- Archive previous raid
    currentRaid.active = false
    self.db.realm.archivedRaids[currentRaid.date] = currentRaid

    self.Comm:SendRaidClosed(currentRaid)

    self.db.realm.currentRaid = nil
    self.db.profile.viewArchive = currentRaid.date

    self.UI.UpdateLoot(currentRaid)
    self:LDBUpdate()
end


function LootHelper:UpdateRaidPlayers()
    local raidData = self:GetSelectedRaidData()
    if raidData and raidData.active then
        self.db.realm.currentRaid.players = self:GetRaidPlayers()
    end
end


function LootHelper:FlagBossDeath(bossName)
    local raidData = self:GetSelectedRaidData()
    if raidData and not self:ReadOnly(raidData) then
        raidData.bossKill = bossName
    end
end


function LootHelper:SelectArchivedRaid(id)
    if id ~= 0 then
        self.db.profile.viewArchive = id
    else
        self.db.profile.viewArchive = nil
    end
    self.UI:UpdateLoot(self:GetSelectedRaidData())
    self:LDBUpdate()
end


--[[========================================================
                        Rolls
========================================================]]--


function LootHelper:AddRoll(player, roll)
    local activeRolls = self:GetActiveRolls()
    local penalty = 0

    local raidData = self:GetSelectedRaidData()
    if raidData and not self:ReadOnly(raidData) then
        penalty = self:GetPlayerPenalty(player, nil, raidData)
    end

    local result = roll + penalty

    local entry = {
        player = player,
        playerClass = self:GetPlayerClass(player),
        roll = roll,
        penalty = penalty,
        result = result,
        date = timestamp(),
    }

    tinsert(activeRolls, entry)
    table.sort(activeRolls, rollEntrySort)
    self.UI:UpdateRolls(activeRolls)
    self:LDBUpdate()
end


local archiveTmpTbl = {}
function LootHelper:ArchiveRolls()
    local activeRolls = self:GetActiveRolls()
    local historicRolls = self:GetHistoricRolls()

    for i=0, #activeRolls do
        tinsert(historicRolls, activeRolls[i])
    end

    -- Clear activeRolls
    wipe(activeRolls)

    -- Remove old rolls
    local now = timestamp()
    local limit = now - (10*60)

    for _, v in ipairs(historicRolls) do
        if v.date > limit then
            tinsert(archiveTmpTbl, v)
        end
    end
    wipe(historicRolls)

    for _, v in ipairs(archiveTmpTbl) do
        tinsert(historicRolls, v)
    end
    wipe(archiveTmpTbl)

    -- Sort new rolls first
    table.sort(historicRolls, rollHistoricSort)

    self.UI:UpdateRolls(activeRolls, historicRolls)
    self:LDBUpdate()
end


function LootHelper:ActivateArchivedRoll(rollIndex)
    local activeRolls = self:GetActiveRolls()
    local historicRolls = self:GetHistoricRolls()

    -- Remove from history
    local archivedEntry = tremove(historicRolls, rollIndex)

    -- Add to active and sort
    tinsert(activeRolls, archivedEntry)
    table.sort(activeRolls, rollEntrySort)

    self.UI:UpdateRolls(activeRolls, historicRolls)
end


--[[========================================================
                        Data
========================================================]]--


function LootHelper:ReadOnly(raidData)
    return raidData and (
        raidData.owner ~= UnitName("player") or
        not raidData.active
    )
end

--[[
    {
        date = timestamp(),
        player = player,
        itemName = itemName,
        itemID = itemID,
        itemLink = itemLink,
        itemQuality = itemQuality,
        itemTexture = itemTexture,
        ammount = ammount,
    }
]]
function LootHelper:LootIsDuplicate(loot, raidData)
    local raidLoot = raidData.loot

    local lastLoot = raidLoot.loot[#raidLoot.loot]
    if lastLoot.itemID == loot.itemID
        and lastLoot.player == loot.player
        and lastLoot.date == loot.date
    then
        return true
    end

    for _, v in ipairs(raidLoot) do
        if v.itemID == loot.itemID
            and v.player == loot.player
            and v.date <= (loot.date + 60)
            and v.date >= (loot.date - 60)
        then
            return true
        end
    end
    return false
end


-- Calcualte rolling players penalty and modify to result
  -- Skip OS items
  -- Add rules for special items that should not count penalties
function LootHelper:GetPlayerPenalty(player, itemID, raidData)
    if itemID and self.db.realm.noPenaltyItems[itemID] then return 0 end

    local penalty = 0
    for _, loot in ipairs(raidData.loot) do
        if loot.player == player and loot.lootAction == "MS" then
            penalty = penalty - raidData.penalty
        end
    end
    return penalty
end


function LootHelper:GetPlayerClass(playerName)
    local raidData = self:GetSelectedRaidData()
    for _, playerData in ipairs(raidData.players) do
        if playerData.name == playerName then
            return playerData.class
        end
    end
    return nil
end


function LootHelper:GetSelectedRaidData()
    if self.db.profile.viewArchive then
        return self.db.realm.archivedRaids[self.db.profile.viewArchive]
    end
    return self.db.realm.currentRaid
end


function LootHelper:GetActiveRolls()
    return self.db.profile.activeRolls
end


function LootHelper:GetHistoricRolls()
    return self.db.profile.historicRolls
end


local function archivedRaidsSort(a, b)
    return a.id < b.id
end
function LootHelper:GetArchivedRaids()
    local raids = {}
    for k in pairs(self.db.realm.archivedRaids) do
        tinsert(raids, {
            id = k,
            label = date("%y-%m-%d %H:%M:%S", k)
        })
    end
    table.sort(raids, archivedRaidsSort)
    return raids
end


function LootHelper:GetSelectedArchivedRaid()
    local selectedLabel = "- None -"
    if self.db.profile.viewArchive then
        selectedLabel = date("%y-%m-%d %H:%M:%S", self.db.profile.viewArchive)
    end
    return self.db.profile.viewArchive, selectedLabel
end


--[[========================================================
                        UI
========================================================]]--

-- Show loot UI
-- UI should be read only for players that are not ML
-- Archive rolls that are old?
function LootHelper:Show()
    self:UpdateRaidPlayers()
    self.UI:Create()
    self.UI:UpdateLoot(self:GetSelectedRaidData())
    self.UI:UpdateRolls(self:GetActiveRolls(), self:GetHistoricRolls())
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

    return self:GetItemInfo(item, player, ammount)
end


function LootHelper:GetItemInfo(item, player, ammount)
    local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(item)
    if not itemName then
        return nil
    end

    local _, _, itemID = string.find(itemLink, "item:(%d+):")

    -- Invalid item looted?
    if not itemName or not itemID or not itemQuality then
        return nil
    end

    return {
        date = timestamp(),
        player = player,
        itemName = itemName,
        itemID = itemID,
        itemLink = itemLink,
        itemQuality = itemQuality,
        itemTexture = itemTexture,
        ammount = ammount,
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
    local players
    local index

    if not UnitInRaid("player") then
        -- return nil

        -- TEMP
        players = {
            { name = UnitName("player"), class = select(2, UnitClass("player")) },
            { name = "Meche", class = "WARRIOR" },
            { name = "Grillspett", class = "PRIEST" },
            { name = "Hubbé", class = "HUNTER"},
            { name = "Deaurion", class = "WARRIOR" },
        }
        index = 4

        table.sort(players, raidPlayerSort)
        return players, index
    end

    players = {}
    index = 0

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
                    LibDataBroker
========================================================]]--


function LootHelper:LDBShowTooltip(tooltip)
        --[[
    Display the tool tip for this LDB.
    Note: This returns
    --]]
    tooltip = tooltip or GameTooltip

    -- Show the LDB addon title in green
    tooltip:AddLine("HH Loot Helper")

    tooltip:AddDoubleLine("Left click:", "|cffffffffOpen raid window|r")
    tooltip:AddDoubleLine("Right click:", "|cffffffffOpen options|r")

    local activeRolls = self:GetActiveRolls()
    if #activeRolls > 0 then
        tooltip:AddLine(" ")

        for _, roll in ipairs(activeRolls) do
            tooltip:AddDoubleLine(
                string.format("|c%s%s|r", RAID_CLASS_COLORS[roll.playerClass or "WARRIOR"].colorStr, roll.player),
                string.format("|cff888888%d  %d|r  |cffffffff%d|r", roll.roll, roll.penalty, roll.result)
            )
        end
    end
end


function LootHelper:LDBUpdate()
    self.ldb.text = self:LDBText()
end


function LootHelper:LDBText()
    if self.db.profile.viewArchive then
        return "Archive - "..date("%y-%m-%d %H:%M ", self.db.profile.viewArchive).."  "
    end

    local raidData = self:GetSelectedRaidData()
    if raidData then
        local activeRolls = self:GetActiveRolls()
        -- Have active rolls and best roll is less than 2 minutes old
        if #activeRolls > 0 and activeRolls[1].date + 180 > time() then
            local roll = activeRolls[1]
            local msg = "|c%s%s|r |cff888888%s|r |cffffffff-|r |cff888888%s|r |cffffffff- %s|r  "
            return string.format(
                msg,
                RAID_CLASS_COLORS[roll.playerClass].colorStr,
                roll.player,
                roll.roll,
                roll.penalty,
                roll.result
            )
        end

        local text = "Raid active - "
        if raidData.owner == UnitName("player") then
            text = text.."(own)  "
        else
            text = text.."("..raidData.owner..")  "
        end
        return text
    end
    return "Inactive  "
end


--[[========================================================
                        TEST
========================================================]]--


function LootHelper:TestItem()
    local items = {
        18816,
        18814,
    }
    local itemID = items[math.random(1, #items)]
    local itemName, itemLink = GetItemInfo(itemID)

    if itemName == nil or itemLink == nil then
        self:Print("Error receiving item information. Probably too early after login?")
    end

    return itemName, itemLink
end


-- TODO: Add LOOT_ITEM_SELF_MULTIPLE
function LootHelper:TestLootItemSelf()
    local _, itemLink = self:TestItem()
    local msg = string.format(LOOT_ITEM_SELF, itemLink)
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
    local msg = string.format(LOOT_ITEM, player.name, itemLink)
    self:CHAT_MSG_LOOT("CHAT_MSG_LOOT", msg)
end


function LootHelper:TestBossKill()
    self:FlagBossDeath("Test boss")
end
