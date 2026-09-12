require "TimedActions/ISBaseTimedAction"

local o_adjustMaxTime = ISBaseTimedAction.adjustMaxTime

function ISBaseTimedAction:adjustMaxTime(maxTime)
    maxTime = o_adjustMaxTime(self, maxTime)
    if maxTime > 1 then
        maxTime = MT.QuickSlowTraitCheck(self, maxTime)
    end
    return maxTime
end

local function patchInventoryTransfer()
    if _G["ISInventoryTransferAction"] then
        local o_new = ISInventoryTransferAction.new
        function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
            local o = o_new(self, character, item, srcContainer, destContainer, time)
            if o and o.queueList then
                for _, queued in ipairs(o.queueList) do
                    if queued.time and queued.time > 1 then
                        queued.time = MT.QuickSlowTraitCheck(o, queued.time)
                    end
                end
            end
            return o
        end
    end
end

if isClient() or not isServer() then
    patchInventoryTransfer()
end