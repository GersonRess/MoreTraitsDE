require "TimedActions/ISBaseTimedAction"

if not MTQuickSlowBridge then
MTQuickSlowBridge = {}
local M = MTQuickSlowBridge
local MARKER = "^MTQS:"

M.originalAdjustMaxTime = ISBaseTimedAction.adjustMaxTime or function(self, maxTime) return maxTime end

function M.encodedName(name, duration)
    return MARKER .. tostring(duration)
end

function M.decodedDuration(name)
    if type(name) ~= "string" then return nil end
    local value = name:match("^%^MTQS:(.+)$")
    if not value then return nil end
    return tonumber(value)
end

local function clampedDuration(base, decided)
    if not (base and decided) then return base end
    if base <= 0 then return decided end
    local low = base * 0.15
    local high = base * 4.0
    if decided < low then return low end
    if decided > high then return high end
    return decided
end
M.clampedDuration = clampedDuration

function ISBaseTimedAction:adjustMaxTime(maxTime)
    if self.mtQuickSlowApplied then return maxTime end
    if MTClientLogic and MTClientLogic.adjustMaxTime then
        return MTClientLogic.adjustMaxTime(self, maxTime)
    end
    local decided = M.decodedDuration(self.name)
    if decided then return M.clampedDuration(maxTime, decided) end
    return maxTime
end
end