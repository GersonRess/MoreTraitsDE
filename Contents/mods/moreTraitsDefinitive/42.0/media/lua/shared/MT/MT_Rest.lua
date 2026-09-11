MT = MT or {}

local function SecondWind(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.secondwind) or playerdata.secondwinddisabled then
        return
    end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local fatigue = stats:get(CharacterStat.FATIGUE)

    if endurance < 0.5 or fatigue > 0.8 then
        local enemies = player:getSpottedList()
        if enemies:size() < 3 then
            return
        end

        local zombiesNearPlayer = 0
        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i)
            if enemy:isZombie() and enemy:DistTo(player) <= 5 then
                zombiesNearPlayer = zombiesNearPlayer + 1
            end
            if zombiesNearPlayer > 2 then
                break
            end
        end

        if zombiesNearPlayer > 2 then
            local args = { endurance = 1.0 }

            if fatigue > 0.4 then
                args.fatigue = 0.4
                if fatigue > 0.6 then
                    playerdata.secondwindrecoveredfatigue = true
                end
            end

            if isClient() then
                MT.SendUpdateStats(player, args)
            else
                stats:set(CharacterStat.ENDURANCE, args.endurance)
                if args.fatigue then
                    stats:set(CharacterStat.FATIGUE, args.fatigue)
                end
            end

            playerdata.iHardyEndurance = 5
            playerdata.secondwindcooldown = 0
            playerdata.secondwinddisabled = true
            HaloTextHelper.addTextWithArrow(
                    player,
                    getText("UI_trait_secondwind"),
                    true,
                    HaloTextHelper.getColorGreen()
            )
        end
    end
end

local function SecondWindRecharge(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.secondwind) or playerdata.secondwinddisabled then
        return
    end

    local cooldown = SandboxVars.MoreTraits.SecondWindCooldown or 14
    local recharge = cooldown * 12

    if playerdata.secondwindrecoveredfatigue then
        recharge = recharge * 2
    end
    playerdata.secondwindcooldown = (playerdata.secondwindcooldown or 0) + 1

    if playerdata.secondwindcooldown >= recharge then
        playerdata.secondwindcooldown = 0
        playerdata.secondwinddisabled = false
        playerdata.secondwindrecoveredfatigue = false
        player:Say(getText("UI_trait_secondwindcooldown"))
    end
end

local function RestfulSleeper(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.restfulsleeper) or not player:isAsleep() then
        return
    end

    local stats = player:getStats()
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local neck = player:getBodyDamage():getBodyPart(BodyPartType.Neck)

    playerdata.HasSlept = true
    playerdata.NeckHadPain = neck:getAdditionalPain() > 0
    playerdata.FatigueWhenSleeping = fatigue

    local reduction = 0.05
    if fatigue >= 0.6 then
        reduction = 0.2
    elseif fatigue >= 0.2 then
        reduction = 0.1
    end
    local newFatigue = math.max(0, fatigue - reduction)

    if isClient() then
        MT.SendUpdateStats(player, { fatigue = newFatigue })
    else
        stats:set(CharacterStat.FATIGUE, newFatigue)
    end
end

local function RestfulSleeperWakeUp(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.restfulsleeper) then
        return
    end

    local stats = player:getStats()
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local isAsleep = player:isAsleep()

    if isAsleep and fatigue <= 0 then
        player:forceAwake()
        playerdata.FatigueWhenSleeping = 0
        return
    end

    if isAsleep then
        playerdata.FatigueWhenSleeping = fatigue
        return
    end

    if playerdata.HasSlept then
        if fatigue > (playerdata.FatigueWhenSleeping or 0) then
            if isClient() then
                MT.SendUpdateStats(player, { fatigue = playerdata.FatigueWhenSleeping })
            else
                stats:set(CharacterStat.FATIGUE, playerdata.FatigueWhenSleeping)
            end
        end

        playerdata.HasSlept = false
        playerdata.FatigueWhenSleeping = 0

        if not playerdata.NeckHadPain then
            local neck = player:getBodyDamage():getBodyPart(BodyPartType.Neck)
            if neck:getAdditionalPain() > 0 then
                if isClient() then
                    MT.SendBodyPartMechanics(player, { bodyPart = BodyPartType.ToIndex(BodyPartType.Neck), partPain = 0 })
                else
                    neck:setAdditionalPain(0)
                end
            end
        end
    end
end

local function QuickRest(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.quickrest) then
        return
    end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local isSittingGround = player:isSitOnGround()
    local isRestingFurniture = player:isResting() or player:isSittingOnFurniture()

    if endurance < 1 and (isSittingGround or isRestingFurniture) then
        local enduranceGain = 0.055

        if isRestingFurniture then
            enduranceGain = 0.12
        end

        local fatigue = stats:get(CharacterStat.FATIGUE)
        local multiplier = 1.0 - (fatigue * 0.8)
        local finalGain = enduranceGain * multiplier
        local newEndurance = math.min(1.0, endurance + finalGain)

        if isClient() then
            MT.AccumStat(player, { d_endurance = finalGain })
        end
        stats:set(CharacterStat.ENDURANCE, newEndurance)

        playerdata.QuickRestActive = true
        return
    end

    if playerdata.QuickRestActive then
        if endurance >= 1 or (not isSittingGround and not isRestingFurniture) then
            if endurance >= 1 and (isSittingGround or isRestingFurniture) then
                HaloTextHelper.addText(player, getText("UI_quickrestfullendurance"), "", HaloTextHelper.getColorGreen())
            end
            playerdata.QuickRestActive = false
        end
    end
end

MT.Rest = {
    SecondWind = SecondWind,
    SecondWindRecharge = SecondWindRecharge,
    RestfulSleeper = RestfulSleeper,
    RestfulSleeperWakeUp = RestfulSleeperWakeUp,
    QuickRest = QuickRest,
}

return MT