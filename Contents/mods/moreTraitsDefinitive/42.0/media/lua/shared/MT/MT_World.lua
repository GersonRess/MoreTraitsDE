MT = MT or {}

local UMBRELLA_TYPES = {
    ["UmbrellaRed"] = true,
    ["UmbrellaBlue"] = true,
    ["UmbrellaWhite"] = true,
    ["UmbrellaBlack"] = true,
}

local function Albino(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.albino) then
        return
    end

    local bodyDamage = player:getBodyDamage()
    local head = bodyDamage:getBodyPart(BodyPartType.Head)
    local modpain = playerdata.AlbinoTimeSpentOutside or 0

    if isClient() then
        local currentTime = getTimestampMs()
        playerdata.lastAlbinoUpdate = playerdata.lastAlbinoUpdate or 0
        if currentTime < playerdata.lastAlbinoUpdate + 1000 then
            return
        end
        playerdata.lastAlbinoUpdate = currentTime
    end

    local finalPain = 0
    if player:isOutside() then
        local tod = getGameTime():getTimeOfDay()
        if tod > 8 and tod < 17 then
            local stats = player:getStats()
            if stats:get(CharacterStat.PAIN) < 25 and not playerdata.bisAlbinoOutside then
                MT.Announce(player, "AlbinoAnnounce", getText("UI_trait_albino"), false, HaloTextHelper.getColorRed())
                playerdata.bisAlbinoOutside = true
            end

            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()
            local hasUmbrella = (primary and UMBRELLA_TYPES[primary:getType()])
                    or (secondary and UMBRELLA_TYPES[secondary:getType()])
            finalPain = hasUmbrella and (modpain / 1.5) or modpain
        else
            if modpain > 0 then
                finalPain = modpain / 2
            end
        end
    else
        playerdata.bisAlbinoOutside = false
        if modpain > 0 then
            finalPain = modpain / 4
        end
    end

    if isClient() then
        playerdata.fAlbinoLastSentPain = playerdata.fAlbinoLastSentPain or 0
        if math.abs(finalPain - playerdata.fAlbinoLastSentPain) >= 1 then
            MT.SendBodyPartMechanics(player, { bodyPart = BodyPartType.ToIndex(BodyPartType.Head), partPain = finalPain })
            playerdata.fAlbinoLastSentPain = finalPain
        end
    else
        head:setAdditionalPain(finalPain)
    end
end

local function AlbinoTimer(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.albino) then
        return
    end
    playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside or 0

    if player:isOutside() then
        local tod = getGameTime():getTimeOfDay()
        if tod > 8 and tod < 17 then
            if playerdata.AlbinoTimeSpentOutside < 40 then
                local primary = player:getPrimaryHandItem()
                local secondary = player:getSecondaryHandItem()
                local hasUmbrella = (primary and UMBRELLA_TYPES[primary:getType()])
                        or (secondary and UMBRELLA_TYPES[secondary:getType()])
                local increment = hasUmbrella and 0.5 or 1
                playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside + increment
            end
        elseif playerdata.AlbinoTimeSpentOutside >= 1 then
            playerdata.AlbinoTimeSpentOutside = playerdata.AlbinoTimeSpentOutside - 1
        end
    else
        if playerdata.AlbinoTimeSpentOutside > 0 then
            playerdata.AlbinoTimeSpentOutside = math.max(0, playerdata.AlbinoTimeSpentOutside - 2)
        end
    end
end

local FastGimpVector = Vector2.new(0, 0)

local function TryMoveUnmodded(player, x, y)
    return pcall(function()
        player:moveUnmodded(x, y)
    end)
end

local function FastGimpMove(player)
    if not player or not player:isLocalPlayer() then
        return
    end

    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    local hasFast = player:hasTrait(ToadTraitsRegistries.fast)
    local hasGimp = player:hasTrait(ToadTraitsRegistries.gimp)
    if not hasFast and not hasGimp then
        return
    end

    local timeMult = getGameTime():getTrueMultiplier()
    local pathfindingBehaviour = player:getPathFindBehavior2()
    local isPathfinding = pathfindingBehaviour:isMovingUsingPathFind()

    if isPathfinding and timeMult > 1.1 then
        return
    end

    if isPathfinding and hasGimp then
        local square = player:getCurrentSquare()
        local dir = player:getDir()

        if square then
            local nextSquare = square:getAdjacentSquare(dir)
            if nextSquare and (square:isBlockedTo(nextSquare) or square:isWindowTo(nextSquare)) then
                return
            end
        end
    end

    local modifier = 0
    if hasFast then
        if player:isSprinting() then
            modifier = SandboxVars.MoreTraits.FastSprint or 0.75
        elseif player:isRunning() then
            modifier = SandboxVars.MoreTraits.FastRunning or 0.5
        elseif player:isWalking() then
            modifier = SandboxVars.MoreTraits.FastWalking or 0.25
        end
    elseif hasGimp then
        if player:isSprinting() then
            modifier = SandboxVars.MoreTraits.GimpSprint or -0.25
        elseif player:isRunning() then
            modifier = SandboxVars.MoreTraits.GimpRunning or -0.5
        elseif player:isWalking() then
            modifier = SandboxVars.MoreTraits.GimpWalking or -0.75
        end
    end

    if modifier == 0 then
        return
    end

    if not player:isPlayerMoving() then
        return
    end

    player:getDeferredMovement(FastGimpVector)

    local rawX = FastGimpVector:getX()
    local rawY = FastGimpVector:getY()

    if hasGimp then
        modifier = modifier * 0.9
    end

    local x = rawX * modifier
    local y = rawY * modifier
    TryMoveUnmodded(player, x, y)
end

local function VehicleCheck(player)
    if getActivatedMods():contains("DrivingSkill") then
        return
    end

    if player:isDriving() then
        local vehicle = player:getVehicle()
        local vmd = vehicle:getModData()
        if vmd.fRegulatorSpeed == nil then
            vmd.bUpdated = nil
        end
        if vmd.bUpdated == nil then
            vmd.fBrakingForce = vehicle:getBrakingForce()
            vmd.fMaxSpeed = vehicle:getMaxSpeed()
            vmd.iEngineQuality = vehicle:getEngineQuality()
            vmd.iEngineLoudness = vehicle:getEngineLoudness()
            vmd.iEnginePower = vehicle:getEnginePower()
            vmd.iMass = vehicle:getMass()
            vmd.iInitialMass = vehicle:getInitialMass()
            vmd.fOffRoadEfficiency = vehicle:getScript():getOffroadEfficiency()
            vmd.fRegulatorSpeed = vehicle:getRegulatorSpeed()
            vmd.sState = "Normal"
            vmd.bUpdated = true
        else
            if player:hasTrait(ToadTraitsRegistries.expertdriver) and vmd.sState ~= "ExpertDriver" then
                vehicle:setBrakingForce(vmd.fBrakingForce * 2)
                vehicle:setEngineFeature(vmd.iEngineQuality * 2, vmd.iEngineLoudness * 0.25, vmd.iEnginePower * 3)
                vehicle:setMaxSpeed(vmd.fMaxSpeed * 1.25)
                vehicle:setMass(vmd.iMass * 0.5)
                vehicle:setInitialMass(vmd.iInitialMass * 0.5)
                vehicle:updateTotalMass()
                vehicle:getScript():setOffroadEfficiency(vmd.fOffRoadEfficiency * 2)
                vehicle:setRegulatorSpeed(vmd.fRegulatorSpeed * 2)
                vmd.sState = "ExpertDriver"
                vehicle:update()
            end
            if player:hasTrait(ToadTraitsRegistries.poordriver) and vmd.sState ~= "PoorDriver" then
                vehicle:setBrakingForce(vmd.fBrakingForce * 0.5)
                vehicle:setEngineFeature(vmd.iEngineQuality * 0.5, vmd.iEngineLoudness * 1.5, vmd.iEnginePower * 0.66)
                vehicle:setMaxSpeed(vmd.fMaxSpeed * 0.75)
                vehicle:setMass(vmd.iMass * 1.33)
                vehicle:setInitialMass(vmd.iInitialMass * 1.33)
                vehicle:updateTotalMass()
                vehicle:getScript():setOffroadEfficiency(vmd.fOffRoadEfficiency * 0.5)
                vehicle:setRegulatorSpeed(vmd.fRegulatorSpeed * 0.66)
                vmd.sState = "PoorDriver"
                vehicle:update()
            end
            if
            not player:hasTrait(ToadTraitsRegistries.expertdriver)
                    and not player:hasTrait(ToadTraitsRegistries.poordriver)
                    and vmd.sState ~= "Normal"
            then
                vehicle:setBrakingForce(vmd.fBrakingForce)
                vehicle:setEngineFeature(vmd.iEngineQuality, vmd.iEngineLoudness, vmd.iEnginePower)
                vehicle:setMaxSpeed(vmd.fMaxSpeed)
                vehicle:setMass(vmd.iMass)
                vehicle:setInitialMass(vmd.iInitialMass)
                vehicle:updateTotalMass()
                vehicle:getScript():setOffroadEfficiency(vmd.fOffRoadEfficiency)
                vehicle:setRegulatorSpeed(vmd.fRegulatorSpeed)
                vmd.sState = "Normal"
                vehicle:update()
            end
        end
    end
end

local function LeadFoot(player)
    if not player:hasTrait(ToadTraitsRegistries.leadfoot) then
        return
    end

    local shoes = player:getClothingItem_Feet()
    if not shoes then
        return
    end

    local itemdata = shoes:getModData()
    if not itemdata then
        return
    end

    if itemdata.origStomp == nil then
        itemdata.origStomp = shoes:getStompPower()
        itemdata.stompState = "Normal"
    end

    if itemdata.stompState ~= "LeadFoot" then
        local newstomp = (itemdata.origStomp * 2) + 1
        shoes:setStompPower(newstomp)
        itemdata.stompState = "LeadFoot"
    end
end

local function ClothingUpdate(_player)
    local player = _player
    local state = "Normal"
    local wornItems = player:getWornItems()
    local inventory = player:getInventory()
    if player:hasTrait(ToadTraitsRegistries.fitted) then
        state = "Fitted"
    end
    if wornItems ~= nil and wornItems:size() > 1 then
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            if item:IsClothing() then
                local itemdata = item:getModData()
                if itemdata.sState ~= nil and itemdata.sState ~= "Normal" and wornItems:contains(item) == false then
                    item:setRunSpeedModifier(itemdata.iOrigRunSpeedMod)
                    item:setCombatSpeedModifier(itemdata.iOrigCombatSpeedMod)
                    item:setActualWeight(itemdata.iOrigWeight)
                    itemdata.sState = "Normal"
                end
            end
        end
        for i = wornItems:size() - 1, 0, -1 do
            local item = wornItems:getItemByIndex(i)
            if item:IsClothing() then
                local itemdata = item:getModData()
                if itemdata.sState == nil then
                    itemdata.sState = "Normal"
                    itemdata.iOrigRunSpeedMod = item:getRunSpeedModifier()
                    itemdata.iOrigCombatSpeedMod = item:getCombatSpeedModifier()
                    itemdata.iOrigWeight = item:getActualWeight()
                end
                if state ~= itemdata.sState then
                    if itemdata.iOrigRunSpeedMod ~= nil and itemdata.iOrigRunSpeedMod < 1 then
                        if state == "Fitted" then
                            item:setRunSpeedModifier(1.0)
                        else
                            item:setRunSpeedModifier(itemdata.iOrigRunSpeedMod)
                        end
                    end
                    if itemdata.iOrigCombatSpeedMod ~= nil and itemdata.iOrigCombatSpeedMod < 1 then
                        if state == "Fitted" then
                            item:setCombatSpeedModifier(1.0)
                        else
                            item:setCombatSpeedModifier(itemdata.iOrigCombatSpeedMod)
                        end
                    end
                    if itemdata.iOrigWeight ~= nil then
                        if state == "Fitted" then
                            item:setActualWeight(itemdata.iOrigWeight * 0.5)
                        else
                            item:setActualWeight(itemdata.iOrigWeight)
                        end
                    end
                    itemdata.sState = state
                    player:setWornItems(wornItems)
                end
            end
        end
    end
end

MT.World = {
    Albino = Albino,
    AlbinoTimer = AlbinoTimer,
    FastGimpMove = FastGimpMove,
    VehicleCheck = VehicleCheck,
    LeadFoot = LeadFoot,
    ClothingUpdate = ClothingUpdate,
}

return MT