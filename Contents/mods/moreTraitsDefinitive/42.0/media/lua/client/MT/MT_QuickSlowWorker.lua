require "TimedActions/MT_QuickSlowWorker"

if not MTClientLogic then
MTClientLogic = {}
end
local M = MTQuickSlowBridge
local C = MTClientLogic

function C.adjustMaxTime(action, maxTime)
    maxTime = M.originalAdjustMaxTime(action, maxTime or 50)
    if maxTime == -1 or not action.character then
        return maxTime
    end
    local newTime = MT.QuickSlowTraitCheck(action, maxTime)
    if newTime ~= maxTime then
        action.mtQuickSlowApplied = true
        action.name = M.encodedName(action.name, math.floor(newTime))
    end
    return newTime
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

patchInventoryTransfer()