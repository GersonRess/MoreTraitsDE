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
        local anger = stats:get(CharacterStat.ANGER)
        local stress = stats:get(CharacterStat.STRESS)
        if anger > 0 then
            args.d_anger = -anger
            updateStats = true
        end
        if stress > 0 then
            args.d_stress = -stress
            updateStats = true
        end
    end

    if drunkness > 0 then
        if playerdata.internalTick and playerdata.internalTick >= 25 then
            local fatigue = stats:get(CharacterStat.FATIGUE)
            if fatigue > 0 then
                args.d_fatigue = -math.min(0.01, fatigue)
                updateStats = true
            end
        end
    end

    if not playerdata.bSatedDrink then
        if hoursSinceDrink > hoursThreshold then
            local currentPain = stats:get(CharacterStat.PAIN)
            args.d_pain = math.min(100 - currentPain, withdrawalIntensity * 0.1)
            updateStats = true
        end

        if playerdata.internalTick == 30 then
            local anger = stats:get(CharacterStat.ANGER)
            local stress = stats:get(CharacterStat.STRESS)
            local angerLimit = 0.05 + (withdrawalIntensity * 0.1) / 3
            local stressLimit = 0.15 + (withdrawalIntensity * 0.1) / 2

            if anger < angerLimit then
                args.d_anger = math.min(0.01, angerLimit - anger)
                updateStats = true
            end
            if stress < stressLimit then
                args.d_stress = math.min(0.01, stressLimit - stress)
                updateStats = true
            end
        end
    end

    if updateStats then
        if isClient() then
            MT.AccumStat(player, args)
        else
            local anger = args.d_anger
            local stress = args.d_stress
            local fatigue = args.d_fatigue
            local pain = args.d_pain
            if anger then
                stats:set(CharacterStat.ANGER, MT.Clamp(stats:get(CharacterStat.ANGER) + anger, 0, 1))
            end
            if stress then
                stats:set(CharacterStat.STRESS, MT.Clamp(stats:get(CharacterStat.STRESS) + stress, 0, 1))
            end
            if fatigue then
                stats:set(CharacterStat.FATIGUE, MT.Clamp(stats:get(CharacterStat.FATIGUE) + fatigue, 0, 1))
            end
            if pain then
                stats:set(CharacterStat.PAIN, MT.Clamp(stats:get(CharacterStat.PAIN) + pain, 0, 100))
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