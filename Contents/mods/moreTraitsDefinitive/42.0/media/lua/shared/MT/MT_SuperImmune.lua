MT = MT or {}

local function Trigger(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage:isInfected() then
        return
    end

    if isClient() then
        MT.SendUpdateStats(player, { zombie_fever = 100, zombie_infection = 0, clear_wounds = true })
    else
        local stats = player:getStats()
        stats:set(CharacterStat.ZOMBIE_FEVER, 100)
        stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
        MT.ClearInfection(bodyDamage)

        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            if b:HasInjury() and b:isInfectedWound() then
                b:SetInfected(false)
                b:setInfectedWound(false)
            end
        end
    end

    local minimum = SandboxVars.MoreTraits.SuperImmuneMinDays or 10
    local maximum = SandboxVars.MoreTraits.SuperImmuneMaxDays or 30
    if minimum > maximum then
        minimum, maximum = maximum, minimum
    end

    local timeOfRecovery = 0
    if minimum == maximum + 1 then
        timeOfRecovery = minimum
    else
        timeOfRecovery = ZombRand(minimum, maximum + 1)
    end

    if player:hasTrait(CharacterTrait.FAST_HEALER) then
        timeOfRecovery = timeOfRecovery - 5
    end
    if player:hasTrait(CharacterTrait.SLOW_HEALER) then
        timeOfRecovery = timeOfRecovery + 5
    end
    timeOfRecovery = timeOfRecovery + MT.LuckDelta(player, -2)

    timeOfRecovery = math.max(minimum, math.min(maximum, timeOfRecovery))

    if playerdata.SuperImmuneHealedOnce and playerdata.SuperImmuneFirstInfectionBonus then
        timeOfRecovery = timeOfRecovery / 2
    end

    playerdata.SuperImmuneActive = true
    playerdata.SuperImmuneRecovery = (playerdata.SuperImmuneRecovery or 0) + timeOfRecovery

    if SandboxVars.MoreTraits.SuperImmuneWeakness then
        playerdata.SuperImmuneInfections = (playerdata.SuperImmuneInfections or 0) + 1
    end
end

local function RecoveryProcess(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) or not playerdata.SuperImmuneActive then
        return
    end

    local recoveryDays = math.min(playerdata.SuperImmuneRecovery or 10, SandboxVars.MoreTraits.SuperImmuneMaxDays or 30)
    local minutesPerDay = 1440
    local maxRecoveryMinutes = recoveryDays * minutesPerDay
    local timeElapsed = playerdata.SuperImmuneMinutesPassed or 0
    local speedRun = playerdata.QuickSuperImmune and 6 or 1

    local stats = player:getStats()
    local illness = stats:get(CharacterStat.ZOMBIE_FEVER)
    local startIllness = illness

    if timeElapsed < maxRecoveryMinutes then
        playerdata.SuperImmuneTextSaid = false

        local illnessChange = 0
        if timeElapsed <= 360 then
            illnessChange = ZombRand(100, 501) / 6000
        else
            local isLateStage = timeElapsed >= (maxRecoveryMinutes / 2)
            local low = isLateStage and 5 or 10
            local high = isLateStage and 36 or 46
            illnessChange = (25 - ZombRand(low, high)) / 600
        end

        illness = illness - (illnessChange * speedRun)

        local healValue = 0
        if player:hasTrait(CharacterTrait.FAST_HEALER) then
            healValue = -0.25 / 60
        elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
            healValue = 0.25 / 60
        end

        illness = illness + (healValue * speedRun)

        if illness < 26 then
            illness = illness + (0.166 * speedRun)
        end

        if illness > 89 and not playerdata.SuperImmuneLethal then
            illness = illness - (0.333 * speedRun)
        end

        illness = illness - (playerdata.SuperImmuneMinutesWellFed / 50)
        playerdata.SuperImmuneAbsoluteWellFedAmount = (playerdata.SuperImmuneAbsoluteWellFedAmount or 0)
                + playerdata.SuperImmuneMinutesWellFed
        playerdata.SuperImmuneMinutesWellFed = 0

        local totalTime = speedRun
        if playerdata.SuperImmuneAbsoluteWellFedAmount > 60 then
            totalTime = totalTime + speedRun
            playerdata.SuperImmuneAbsoluteWellFedAmount = playerdata.SuperImmuneAbsoluteWellFedAmount - 60
        end
        playerdata.SuperImmuneMinutesPassed = timeElapsed + totalTime

        if illness < 15 then
            illness = 50
            if isClient() then
                MT.SendUpdateStats(player, { zombie_fever = illness })
            else
                stats:set(CharacterStat.ZOMBIE_FEVER, illness)
            end
        end
    else
        if illness > 0 then
            if not playerdata.SuperImmuneFeverNotified then
                MT.Announce(player, "SuperImmuneAnnounce", getText("UI_trait_superimmune_feverbreak"), true, HaloTextHelper.getColorGreen())
                playerdata.SuperImmuneFeverNotified = true
            end

            local breakInfectionMultiplier = 1.0
            if player:hasTrait(CharacterTrait.FAST_HEALER) then
                breakInfectionMultiplier = 1.5
            elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
                breakInfectionMultiplier = 0.5
            end

            illness = math.max(0, illness - (breakInfectionMultiplier * speedRun))

            playerdata.SuperImmuneInfections = 0
        else
            MT.Announce(player, "SuperImmuneAnnounce", getText("UI_trait_superimmune_fullheal"), true, HaloTextHelper.getColorGreen())

            playerdata.SuperImmuneActive = false
            playerdata.SuperImmuneMinutesPassed = 0
            playerdata.SuperImmuneRecovery = 0
            playerdata.SuperImmuneHealedOnce = true
            playerdata.SuperImmuneAbsoluteWellFedAmount = 0
            playerdata.SuperImmuneInfections = 0
            playerdata.SuperImmuneLethal = false
            playerdata.SuperImmuneTextSaid = false
            playerdata.SuperImmuneFeverNotified = false
        end

        if illness == 0 and not playerdata.SuperImmuneTextSaid then
            MT.Announce(player, "SuperImmuneAnnounce", getText("UI_trait_superimmunewon"), true, HaloTextHelper.getColorGreen())
            playerdata.SuperImmuneTextSaid = true
        end
    end

    if illness ~= startIllness then
        if isClient() then
            MT.SendUpdateStats(player, { zombie_fever = illness })
        else
            stats:set(CharacterStat.ZOMBIE_FEVER, illness)
        end
    end
end

local function FakeInfectionHealthLoss(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.superimmune) then
        return
    end
    if not playerdata.SuperImmuneActive then
        return
    end

    local maxHealth = isClient() and 20 or 15
    if player:hasTrait(ToadTraitsRegistries.indefatigable) then
        maxHealth = isClient() and 30 or 25
    end

    local stats = player:getStats()
    local illness = stats:get(CharacterStat.ZOMBIE_FEVER)

    if SandboxVars.MoreTraits.SuperImmuneWeakness then
        local limit = 4

        if playerdata.SuperImmuneHealedOnce then
            limit = 5
        end

        if player:hasTrait(CharacterTrait.FAST_HEALER) then
            limit = limit + 1
        elseif player:hasTrait(CharacterTrait.SLOW_HEALER) then
            limit = limit - 1
        end

        if playerdata.SuperImmuneInfections >= limit then
            maxHealth = 0
            illness = 100
            playerdata.SuperImmuneLethal = true
        else
            playerdata.SuperImmuneLethal = false
        end
    end

    local bodyDamage = player:getBodyDamage()
    local currentHealth = bodyDamage:getOverallBodyHealth()
    local targetHealth = math.max(maxHealth, 100 - illness)

    if currentHealth >= targetHealth or currentHealth > maxHealth then
        local parts = bodyDamage:getBodyParts()
        local damageAmount = 1.0

        if illness >= 50 then
            damageAmount = 3.0
        elseif illness >= 25 then
            damageAmount = 1.5
        end

        if playerdata.SuperImmuneLethal then
            damageAmount = damageAmount + 10.0
        end

        if illness >= 50 and currentHealth > maxHealth + 5 then
            damageAmount = damageAmount + 5.0
        end

        local randomBodyPart = parts:get(ZombRand(0, parts:size() - 1))

        if isClient() then
            MT.SendBodyPartMechanics(player, { bodyPart = BodyPartType.ToIndex(randomBodyPart:getType()), partDamage = damageAmount })
        else
            randomBodyPart:AddDamage(damageAmount)
        end
    end

    if illness >= 10 then
        local stress = stats:get(CharacterStat.STRESS)
        if stress <= (illness / 100) then
            local newStress = math.min(1.0, stress + 0.01)
            if isClient() then
                MT.SendUpdateStats(player, { stress = newStress })
            else
                stats:set(CharacterStat.STRESS, newStress)
            end
        end
    end
end

local function HungerCheck(player, playerdata)
    if not (player:hasTrait(ToadTraitsRegistries.superimmune) and playerdata.SuperImmuneActive) then
        return
    end

    local stats = player:getStats()

    if player:isGodMod() then
        playerdata.SuperImmuneTextSaid = false
        playerdata.SuperImmuneActive = false
        playerdata.SuperImmuneMinutesPassed = 0
        playerdata.SuperImmuneRecovery = 0
        playerdata.SuperImmuneAbsoluteWellFedAmount = 0
        playerdata.SuperImmuneMinutesWellFed = 0
        playerdata.SuperImmuneInfections = 0
        playerdata.SuperImmuneLethal = false
        if isClient() then
        MT.SendUpdateStats(player, { zombie_fever = 0, zombie_infection = 0 })
        else
            stats:set(CharacterStat.ZOMBIE_FEVER, 0)
            stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
        end
        return
    end

    if stats:get(CharacterStat.HUNGER) <= 0 then
        playerdata.SuperImmuneMinutesWellFed = (playerdata.SuperImmuneMinutesWellFed or 0) + 1
    end
end

MT.SuperImmune = {
    Trigger = Trigger,
    RecoveryProcess = RecoveryProcess,
    FakeInfectionHealthLoss = FakeInfectionHealthLoss,
    HungerCheck = HungerCheck,
}

return MT