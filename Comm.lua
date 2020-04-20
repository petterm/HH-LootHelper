local name, private = ...
local LootHelper = _G.HHLootHelper

local PREFIX = "hhlh"

function LootHelper:CommInit()
    self:RegisterComm(PREFIX)
end


function LootHelper:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end

    local type, data = self:Deserialize(message)

    if type == "RAID_UPDATE" then
    end

    if type == "ITEM_LOOTED" then
        LootHelper:ItemLooted(data, true)
    end
end


function LootHelper:CommSyncActiveRaid(raidData)
    local message = self:Serialize("RAID_UPDATE", raidData)
    self:SendCommMessage(PREFIX, message, "RAID")
end


function LootHelper:CommSendItemLooted(loot, raidOwner)
    local message = self:Serialize("ITEM_LOOTED", loot)
    self:SendCommMessage(PREFIX, message, "WHISPER", raidOwner)
end