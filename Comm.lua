local LootHelper = _G.HHLootHelper
local realmDb = LootHelper.db.realm
local Comm = {}
LootHelper.Comm = Comm

local PREFIX = "hhlh"


-- Should I include version check?
local function CheckSameRaid(raidA, raidB)
    if not raidA or not raidB then
        return false
    end

    if raidA.owner ~= raidB.owner then
        return false
    end

    if raidA.date ~= raidB.date then
        return false
    end

    return true
end


function Comm:Initialize()
    LootHelper:RegisterComm(PREFIX, self.OnCommReceived)
end


function Comm:OnCommReceived(prefix, message, _, sender)
    if prefix ~= PREFIX then return end

    local type, data = self:Deserialize(message)

    if type(self[type]) == "function" then
        self[type](data, sender)
    end

    LootHelper:Print("Received unknown message "..type)
end


function Comm:SendCommMessageRaid(type, data)
    local message = self:Serialize(type, data)
    self:SendCommMessage(PREFIX, message, "RAID")
end


function Comm:SendCommMessageWhisper(type, data, player)
    local message = self:Serialize(type, data)
    self:SendCommMessage(PREFIX, message, "WHISPER", player)
end


--[[========================================================
                Received message handlers
========================================================]]--


-- MASTER EVENTS

-- Item was picked up by a player
-- data: loot (raw)
function Comm:ITEM_LOOTED(data)
    LootHelper:ItemLooted(data, true)
end


-- Client request a full update
-- data: { date }
function Comm:SYNC_REQUEST(data, sender)
    -- Check if I have the matching raid
    -- Send back the requested raid
    if realmDb.currentRaid.date == data.date then
        self:SendFullSyncResponse(realmDb.currentRaid, sender)
    elseif realmDb.archivedRaids[data.date] then
        self:SendFullSyncResponse(realmDb.archivedRaids[data.date], sender)
    end
end


-- CLIENT EVENTS

-- Loot entry was added to the raid
-- data: { owner, date, version, loot }
function Comm:LOOT_ADDED(data)
    local currentRaid = realmDb.currentRaid
    -- Check that I am following the matching raid
    if CheckSameRaid(currentRaid, data) then
        -- Check that I have the previous version of that raid
        if currentRaid.version == data.version - 1 then
            currentRaid.loot[data.loot.index] = data.loot
            currentRaid.version = data.version
            self.UI:Update(currentRaid)
        else
            -- Request full update
            self:SendFullSyncRequest(currentRaid)
        end
    end
end


-- Loot entry in the raid was updated
-- data: { owner, date, version, loot }
function Comm:LOOT_UPDATED(...)
    self:LOOT_ADDED(...)
end


-- data: currentRaid | archivedRaid
function Comm:FULL_SYNC(data, sender)
    local currentRaid = realmDb.currentRaid
    -- Did I request this sync?
    -- Set as current raid
    if CheckSameRaid(currentRaid, data) and currentRaid.awaitingSync then
        wipe(realmDb.currentRaid)
        realmDb.currentRaid = data
        self.UI:Update(realmDb.currentRaid)
        return
    end

    -- Is it an update for an archived raid?
    local archivedRaid = realmDb.archivedRaids[data.date]
    if CheckSameRaid(archivedRaid, data) and archivedRaid.awaitingSync then
        wipe(realmDb.archivedRaids[data.date])
        realmDb.archivedRaids[data.date] = data

        if LootHelper.db.profile.viewArchive == data.date then
            self.UI:Update(realmDb.archivedRaids[data.date])
        end
        return
    end

    LootHelper:Print("Unexpected FULL_SYNC from "..sender)
end


-- data: { owner, date, version }
function Comm:RAID_CLOSE(data, sender)
    local currentRaid = realmDb.currentRaid
    if CheckSameRaid(currentRaid, data) then
        if currentRaid.version == data.version then
            LootHelper:Print("Raid closed by "..sender..".")

            -- archive raid
            currentRaid.active = false
            realmDb.archivedRaids[currentRaid.date] = currentRaid

            -- remove active
            realmDb.currentRaid = nil

            -- set view archive, unless already viewing other archive
            if not LootHelper.db.profile.viewArchive then
                LootHelper.db.profile.viewArchive = currentRaid.date
                self.UI:Update(currentRaid)
            end
        else
            LootHelper:Print("Raid closed by "..sender..". ".."Missmatched version, requesting sync.")

            -- Archive the data we have and flag for sync
            currentRaid.active = false
            currentRaid.awaitingSync = true
            realmDb.archivedRaids[currentRaid.date] = currentRaid
            realmDb.currentRaid = nil

            self:SendFullSyncRequest(currentRaid)
        end
    end
end


-- data: currentRaid
function Comm:RAID_NEW(data, sender)
    if not realmDb.currentRaid then
        realmDb.currentRaid = data
        self.UI:Update(realmDb.currentRaid)
        LootHelper:Print("New raid by "..sender..".")
    else
        LootHelper:Print("New raid by "..sender.." ignored. Raid tracking already active.")
    end
end


--[[========================================================
                    Send Message
========================================================]]--


function Comm:SendItemLooted(loot, raidOwner)
    self:SendCommMessageWhisper("ITEM_LOOTED", loot, raidOwner)
end


function Comm:SendLootAdded(loot, raidData)
    self:SendCommMessageRaid("LOOT_ADDED", {
        owner = raidData.owner,
        date = raidData.date,
        version = raidData.version,
        loot = loot,
    })
end


function Comm:SendLootUpdated(loot, raidData)
    self:SendCommMessageRaid("LOOT_UPDATED", {
        owner = raidData.owner,
        date = raidData.date,
        version = raidData.version,
        loot = loot,
    })
end


function Comm:SendFullSyncRequest(raidData)
    if raidData.awaitingSync then
        LootHelper:Print("Duplicate sync request. Ignored")
        return
    end
    raidData.awaitingSync = true
    LootHelper:Print("Requesting full sync from "..raidData.owner)

    self:SendCommMessageWhisper("SYNC_REQUEST", { date = raidData.date }, raidData.owner)
end


function Comm:SendFullSyncResponse(raidData, requester)
    self:SendCommMessageWhisper("FULL_SYNC", raidData, requester)
end


function Comm:SendRaidNew(raidData)
    self:SendCommMessageRaid("RAID_NEW", raidData)
end


function Comm:SendRaidClosed(raidData)
    self:SendCommMessageRaid("RAID_CLOSE", {
        owner = raidData.owner,
        date = raidData.date,
        version = raidData.version,
    })
end
