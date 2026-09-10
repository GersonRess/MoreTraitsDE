local sharedPatches = {
    { "ISSplint", "TimedActions/ISSplint", function(self)
        return 140 - (self.character:getPerkLevel(Perks.Doctor) * 4)
    end },
    { "ISCutHair", "TimedActions/ISCutHair", function(self)
        return self.maxTime
    end },
    { "ISShovelAction", "Farming/TimedActions/ISShovelAction", function(self)
        return self.maxTime
    end },
    { "ISLightFromPetrol", "Camping/TimedActions/ISLightFromPetrol", function(self)
        return self.maxTime
    end },
    { "ISRemoveCampfireAction", "Camping/TimedActions/ISRemoveCampfireAction", function(self)
        return self.maxTime
    end },
    { "ISFluidTransferAction", "Fluids/ISFluidTransferAction", function(self)
        local baseTime = self.maxTime
        if not baseTime or baseTime == 0 then
            local amount = self.amount or 0
            baseTime = amount * ISFluidUtil.getTransferActionTimePerLiter()
            if baseTime < ISFluidUtil.getMinTransferActionTime() then
                baseTime = ISFluidUtil.getMinTransferActionTime()
            end
        end
        return baseTime
    end },
    { "ISDrinkFluidAction", "TimedActions/ISDrinkFluidAction", function(self)
        local baseTime = self.maxTime or 232
        if baseTime == 0 then baseTime = 232 end
        return baseTime
    end },
    { "ISPickAxeGroundCoverItem", "TimedActions/ISPickAxeGroundCoverItem", function(self)
        return 300 - (self.character:getPerkLevel(Perks.Strength) * 10)
    end },
    { "ISWringClothing", "TimedActions/ISWringClothing", function(self)
        local baseTime = 10
        if self.item and self.item.getWetness then
            baseTime = math.ceil(self.item:getWetness() * 5)
        end
        return baseTime
    end },
    { "ISFertilizeAction", "Farming/TimedActions/ISFertilizeAction", function(self)
        return self.maxTime
    end },
    { "ISWaterPlantAction", "Farming/TimedActions/ISWaterPlantAction", function(self)
        return self.maxTime
    end },
    { "ISCurePlantAction", "Farming/TimedActions/ISCurePlantAction", function(self)
        return self.maxTime
    end },
    { "ISHarvestPlantAction", "Farming/TimedActions/ISHarvestPlantAction", function(self)
        return self.maxTime
    end },
    { "ISInstallVehiclePart", "Vehicles/TimedActions/ISInstallVehiclePart", function(self)
        return self.maxTime
    end },
    { "ISEmptyWaterInTrough", "FeedingTrough/TimedActions/ISEmptyWaterInTrough", function(self)
        local baseTime = 100
        if self.objectTo and self.objectTo.getWater then
            baseTime = self.objectTo:getWater() * 4
        end
        return baseTime
    end },
}

local clientPatches = {
    { "ISReadWorldMap", "TimedActions/ISReadWorldMap", function()
        return 50
    end },
    { "ISAttachTrailerToVehicle", "Vehicles/TimedActions/ISAttachTrailerToVehicle", function()
        return 100
    end },
    { "ISDetachTrailerFromVehicle", "Vehicles/TimedActions/ISDetachTrailerFromVehicle", function()
        return 100
    end },
    { "ISOpenMechanicsUIAction", "Vehicles/TimedActions/ISOpenMechanicsUIAction", function(self)
        local cheat = getCore():getDebug() and getDebugOptions():getBoolean("Cheat.Vehicle.MechanicsAnywhere")
        if (self.vehicle:getScript() and self.vehicle:getScript():getWheelCount() == 0) or
           (ISVehicleMechanics.cheat or cheat) then
            return 1
        end
        return 200 - (self.character:getPerkLevel(Perks.Mechanics) * (200 / 15))
    end },
    { "ISMedicalCheckAction", "TimedActions/ISMedicalCheckAction", function(self)
        return 150 - (self.character:getPerkLevel(Perks.Doctor) * 2.5)
    end },
}

local function applyPatches(list)
    for _, p in ipairs(list) do
        local path = p[2]
        require(path)
        if _G[p[1]] then
            MT.PatchTimedAction(p[1], p[3])
        end
    end
end

local function isBuildAction()
    require "BuildingObjects/TimedActions/ISBuildAction"
    if not _G["ISBuildAction"] then return end

    local o_ISBuildAction_new = ISBuildAction.new
    ISBuildAction.getDuration = function(self, baseTime)
        if self.character and self.character:hasTrait(CharacterTrait.HANDY) then
            baseTime = baseTime - 50
        end
        return MT.QuickSlowTraitCheck(self, baseTime)
    end

    ISBuildAction.new = function(self, character, item, x, y, z, north, spriteName, time)
        local o = o_ISBuildAction_new(self, character, item, x, y, z, north, spriteName, time)
        if o.maxTime > 1 then
            o.maxTime = o:getDuration(o.maxTime)
        end
        return o
    end
end

local function isInventoryTransferAction()
    require "TimedActions/ISInventoryTransferAction"
    if not _G["ISInventoryTransferAction"] then return end
    local o_ISInventoryTransferAction_new = ISInventoryTransferAction.new
    function ISInventoryTransferAction:new(character, item, srcContainer, destContainer, time)
        local o = o_ISInventoryTransferAction_new(self, character, item, srcContainer, destContainer, time)
        if o.maxTime < 1 then return o end

        if o.queueList and o.queueList[1] then
            o.maxTime = o.queueList[1].time
        end

        o.maxTime = MT.QuickSlowTraitCheck(o, o.maxTime)

        if o.queueList and o.queueList[1] then
            o.queueList[1].time = o.maxTime
        end

        return o
    end
end

local function isWorker()
    for _, timedAction in pairs(_G) do
        if type(timedAction) == "table" and timedAction.getDuration then
            local original_getDuration = timedAction.getDuration
            timedAction.getDuration = function(self)
                local duration = original_getDuration(self)
                if not duration then return end
                if duration <= 1 then return duration end
                return MT.QuickSlowTraitCheck(self, duration)
            end
        end
    end
end

local function injectShared()
    applyPatches(sharedPatches)
end

local function injectClient()
    applyPatches(clientPatches)
    isBuildAction()
    isInventoryTransferAction()
end

Events.OnGameBoot.Add(isWorker)
Events.OnGameBoot.Add(injectShared)

if isClient() or not isServer() then
    Events.OnMainMenuEnter.Add(injectClient)
end