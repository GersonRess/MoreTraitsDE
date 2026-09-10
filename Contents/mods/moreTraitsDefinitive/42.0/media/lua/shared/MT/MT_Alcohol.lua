MT = MT or {}

local function Update(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

    local stats = player:getStats()
    local drunkness = stats:get(CharacterStat.INTOXICATION)
    local hoursSinceDrink = playerdata.iHoursSinceDrink or 0
    local hoursThreshold = (SandboxVars.MoreTraits.AlcoholicFrequency or 24) * 1.5
    local divider = 5

    if hoursThreshold <= 2 then
        divider = 0.1
    elseif hoursThreshold <= 5 then
        divider = 0.2
    elseif hoursThreshold <= 10 then
        divider = 0.5
    elseif hoursThreshold <= 20 then
        divider = 1
    end

    local withdrawalIntensity = hoursSinceDrink / divider
    local args = {}
    local updateStats = false

    if drunkness >= 10 then
        if not playerdata.bSatedDrink then
            playerdata.bSatedDrink = true
            HaloTextHelper.addTextWithArrow(
                    player,
                    getText("UI_trait_alcoholicsatisfied"),
                    true,
                    HaloTextHelper.getColorGreen()
            )
        end
        playerdata.iHoursSinceDrink = 0
        args.anger = 0
        args.stress = 0
        updateStats = true
    end

    if drunkness > 0 then
        if internalTick and internalTick >= 25 then
            args.fatigue = math.max(0, stats:get(CharacterStat.FATIGUE) - 0.01)
            updateStats = true
        end
    end

    if not playerdata.bSatedDrink then
        if hoursSinceDrink > hoursThreshold then
            local currentPain = stats:get(CharacterStat.PAIN)
            args.pain = math.min(100, currentPain + (withdrawalIntensity * 0.1))
            updateStats = true
        end

        if internalTick == 30 then
            local anger = stats:get(CharacterStat.ANGER)
            local stress = stats:get(CharacterStat.STRESS)
            local angerLimit = 0.05 + (withdrawalIntensity * 0.1) / 3
            local stressLimit = 0.15 + (withdrawalIntensity * 0.1) / 2

            if anger < angerLimit then
                args.anger = anger + 0.01
                updateStats = true
            end
            if stress < stressLimit then
                args.stress = stress + 0.01
                updateStats = true
            end
        end
    end

    if updateStats then
        if isClient() then
            MT.SendUpdateStats(player, args)
        else
            if args.anger then
                stats:set(CharacterStat.ANGER, args.anger)
            end
            if args.stress then
                stats:set(CharacterStat.STRESS, args.stress)
            end
            if args.fatigue then
                stats:set(CharacterStat.FATIGUE, args.fatigue)
            end
            if args.pain then
                stats:set(CharacterStat.PAIN, args.pain)
            end
        end
    end
end

local function Tick(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

    local hourThreshold = SandboxVars.MoreTraits.AlcoholicFrequency or 24

    if player:hasTrait(ToadTraitsRegistries.lucky) then
        hourThreshold = hourThreshold + (4 * luckimpact)
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        hourThreshold = hourThreshold - (2 * luckimpact)
    end

    if player:hasTrait(ToadTraitsRegistries.lightdrinker) then
        hourThreshold = hourThreshold - 2
    end

    playerdata.iHoursSinceDrink = (playerdata.iHoursSinceDrink or 0) + 1

    if playerdata.bSatedDrink then
        if playerdata.iHoursSinceDrink >= hourThreshold then
            local divider = 4
            if hourThreshold <= 2 then
                divider = 0.1
            elseif hourThreshold <= 5 then
                divider = 0.2
            elseif hourThreshold <= 10 then
                divider = 0.5
            elseif hourThreshold <= 20 then
                divider = 1
            end

            if ZombRand(100) <= (hourThreshold / divider) then
                playerdata.bSatedDrink = false
                HaloTextHelper.addTextWithArrow(
                        player,
                        getText("UI_trait_alcoholicneed"),
                        false,
                        HaloTextHelper.getColorRed()
                )
            end
        end
    else
        MT.Announce(player, "DrinkNotifier", getText("UI_trait_alcoholicneed"), false, HaloTextHelper.getColorRed())
    end
end

local function Poison(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.drinker) then
        return
    end

    playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown or 24

    local isSuffering = false
    local hourThreshold = SandboxVars.MoreTraits.AlcoholicWithdrawal or 72
    if playerdata.iHoursSinceDrink > hourThreshold and not playerdata.bSatedDrink then
        isSuffering = true
    end

    if isSuffering and playerdata.iWithdrawalCooldown <= 0 then
        HaloTextHelper.addTextWithArrow(
                player,
                getText("UI_trait_alcoholicwithdrawal"),
                false,
                HaloTextHelper.getColorRed()
        )

        local poisonLevel = 0
        if SandboxVars.MoreTraits.NonlethalAlcoholic then
            poisonLevel = 20
        else
            local divider = 5
            if hourThreshold <= 2 then
                divider = 0.5
            elseif hourThreshold <= 5 then
                divider = 0.75
            elseif hourThreshold <= 10 then
                divider = 1
            elseif hourThreshold <= 20 then
                divider = 2
            elseif hourThreshold <= 24 then
                divider = 4
            elseif hourThreshold <= 48 then
                divider = 5
            end

            poisonLevel = math.min(100, playerdata.iHoursSinceDrink / divider)
        end

        if isClient() then
            MT.SendUpdateStats(player, { poison = poisonLevel })
        else
            local stats = player:getStats()
            stats:set(CharacterStat.POISON, poisonLevel)
        end

        playerdata.iWithdrawalCooldown = ZombRand(12, 24)
    end

    if playerdata.iWithdrawalCooldown > 0 then
        playerdata.iWithdrawalCooldown = playerdata.iWithdrawalCooldown - 1
    end
end

MT.Alcohol = {
    Update = Update,
    Tick = Tick,
    Poison = Poison,
}

return MT