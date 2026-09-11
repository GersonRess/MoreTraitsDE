MT = MT or {}

local function GlassBody(player, playerData)
    local bodyDamage = player:getBodyDamage()
    local currenthp = bodyDamage:getOverallBodyHealth()
    local multiplier = getGameTime():getMultiplier()

    if playerData.glassBodyLastHP == nil then
        playerData.glassBodyLastHP = currenthp
        playerData.glassBodyInitialized = true
        return
    end

    if playerData.glassBodyInitialized == true then
        playerData.glassBodyInitialized = false
        playerData.glassBodyLastHP = currenthp
        return
    end

    if player:isAsleep() or multiplier > 4.0 then
        playerData.glassBodyLastHP = currenthp
        return
    end

    local lasthp = playerData.glassBodyLastHP

    if currenthp < lasthp then
        local difference = lasthp - currenthp
        if difference > 50 then
            playerData.glassBodyLastHP = currenthp
            return
        end

        local chance = 33
        local woundstrength = 10

        local luck = MT.LuckDelta(player, 5)
        chance = chance - luck
        woundstrength = woundstrength - luck

        chance = math.max(5, math.min(95, chance))
        woundstrength = math.max(5, math.min(25, woundstrength))

        local damage = difference * 2
        local fractureTime = 0
        local scratched = false
        local targetBodyPart = -1

        if ZombRand(100) <= chance then
            targetBodyPart = ZombRand(0, 17)
            if difference > 0.33 then
                fractureTime = ZombRand(20) + woundstrength
            elseif difference > 0.1 then
                scratched = true
            end
        end

        if targetBodyPart == -1 then
            return
        end

        if isClient() then
            local args = {
                damage = damage,
                partIndex = targetBodyPart,
                fractureTime = fractureTime,
                scratched = scratched,
            }
            sendClientCommand(player, "MoreTraitsDefinitive", "GlassBody", args)
        else
            bodyDamage:ReduceGeneralHealth(damage)
            local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(targetBodyPart))
            if fractureTime > 0 then
                if bodyPart:getFractureTime() <= 0 then
                    bodyPart:setFractureTime(fractureTime)
                end
            end
            if scratched then
                bodyPart:setScratched(true, true)
            end
        end
    end
    playerData.glassBodyLastHP = bodyDamage:getOverallBodyHealth()
end

local function PlayerHit(player, _, __)
    if not player or player:isDead() or player:isZombie() then
        return
    end

    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    local list = playerdata.InjuredBodyList
    local bodyDamage = player:getBodyDamage()
    local isInfected = bodyDamage:isInfected()

    local triedImmuno = false
    local blockedAnim = false
    local bodyParts = bodyDamage:getBodyParts()
    local bodyPartsSize = bodyParts:size()

    if player:hasTrait(ToadTraitsRegistries.evasive) then
        local currentState = player:getCurrentState()
        local isHitState = currentState == PlayerHitReactionState.instance()
        local isPVPState = currentState == PlayerHitReactionPVPState.instance()
                and SandboxVars.MoreTraits.EvasiveBlocksPVP

        if isHitState or isPVPState then
            for i = 0, bodyPartsSize - 1 do
                local bodyPart = bodyParts:get(i)

                if bodyPart:HasInjury() and not MT.TableContains(list, i) then
                    local dodgeChance = SandboxVars.MoreTraits.EvasiveChance or 0

                    local wasInfectedBefore = playerdata.EvasivePlayerInfected or false
                    if ZombRand(1, 101) <= dodgeChance then
                        if SandboxVars.MoreTraits.EvasiveAnimation then
                            player:setHitReaction("EvasiveBlocked")
                            blockedAnim = true
                        end

                        HaloTextHelper.addTextWithArrow(
                                player,
                                getText("UI_trait_dodgesay"),
                                true,
                                HaloTextHelper.getColorGreen()
                        )

                        if isClient() then
                            local args = {
                                partIndex = i,
                                wasInfectedBefore = wasInfectedBefore,
                                isInfected = isInfected,
                            }
                            sendClientCommand(player, "MoreTraitsDefinitive", "EvasiveDodge", args)
                        else
                            if bodyPart:IsInfected() and not wasInfectedBefore and isInfected then
                                bodyPart:SetInfected(false)
                                MT.ClearInfection(bodyDamage)
                                bodyDamage:setInfectionGrowthRate(0)
                            end

                            if bodyPart:bleeding() then
                                bodyPart:setBleedingTime(0)
                                bodyPart:setBleeding(false)
                            end

                            if bodyPart:scratched() then
                                bodyPart:setScratchTime(0)
                                bodyPart:setScratched(false, false)
                            end

                            if bodyPart:isCut() then
                                bodyPart:setCutTime(0)
                                bodyPart:setCut(false, false)
                            end

                            if bodyPart:bitten() then
                                bodyPart:SetBitten(false, false)
                                bodyPart:SetHealth(100.0)
                            end
                        end
                    else
                        table.insert(list, i)
                        if bodyPart:IsInfected() and not wasInfectedBefore and isInfected then
                            playerdata.EvasivePlayerInfected = true
                        end
                    end
                end
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.immunocompromised) and not triedImmuno then
        if player:getCurrentState() == PlayerHitReactionState.instance() then
            for i = 0, bodyPartsSize - 1 do
                local bodyPart = bodyParts:get(i)
                if bodyPart:HasInjury() and not MT.TableContains(list, i) then
                    table.insert(list, i)

                    local immunoChance = SandboxVars.MoreTraits.ImmunoChance or 25
                    if bodyDamage:isInfected() then
                        return
                    end

                    if ZombRand(1, 101) <= immunoChance then
                        if isClient() then
                            sendClientCommand(player, "MoreTraitsDefinitive", "InfectPlayer", {})
                        else
                            bodyDamage:setInfected(true)
                        end
                        triedImmuno = true
                    end
                    break
                end
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.unwavering) and not blockedAnim then
        if player:getCurrentState() == PlayerHitReactionState.instance() then
            local reaction = player:getHitReaction()
            if reaction == "Bite" or reaction == "BiteDefended" then
                player:setHitReaction("Unwavering" .. reaction)
                HaloTextHelper.addTextWithArrow(
                        player,
                        getText("UI_trait_unwavering"),
                        true,
                        HaloTextHelper.getColorGreen()
                )
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.glassbody) then
        GlassBody(player, playerdata)
    end
end

local function Butter(player)
    if not player:hasTrait(ToadTraitsRegistries.butterfingers) or not player:isPlayerMoving() then
        return
    end

    local basechance = 3
    local chanceinx = SandboxVars.MoreTraits.ButterfingersChance or 2000

    if player:hasTrait(CharacterTrait.ALL_THUMBS) then
        basechance = basechance + 1
    end
    if player:hasTrait(CharacterTrait.DEXTROUS) then
        basechance = basechance - 1
    end
    if player:hasTrait(ToadTraitsRegistries.packmule) then
        basechance = basechance - 1
    end
    if player:hasTrait(ToadTraitsRegistries.packmouse) then
        basechance = basechance + 1
    end
    basechance = basechance - MT.LuckDelta(player, 1)

    local weight = player:getInventoryWeight()
    local chancemod = math.floor(weight / 5)

    if player:isSprinting() then
        chancemod = chancemod + 10
    elseif player:IsRunning() then
        chancemod = chancemod + 5
    end

    local totalChance = basechance + chancemod

    if totalChance >= ZombRand(chanceinx) then
        if player:getSecondaryHandItem() ~= nil or player:getPrimaryHandItem() ~= nil then
            player:dropHandItems()
            HaloTextHelper.addTextWithArrow(
                    player,
                    getText("UI_butterfingers_triggered"),
                    false,
                    HaloTextHelper.getColorRed()
            )
            player:getEmitter():playSound("UIUnEquipItem")
        end
    end
end

local function Paranoia(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.paranoia) then
        return
    end

    if playerdata.iParanoiaCooldown > 0 then
        playerdata.iParanoiaCooldown = playerdata.iParanoiaCooldown - 1
        return
    end

    if player:isPlayerMoving() then
        local stats = player:getStats()
        local panic = stats:get(CharacterStat.PANIC)
        local stress = stats:get(CharacterStat.STRESS)

        local triggerThreshold = 1
        triggerThreshold = triggerThreshold + (stress * 2)

        if ZombRand(100) < triggerThreshold then
            local sm = getSoundManager()
            local surprised = sm:PlaySound("ZombieSurprisedPlayer", false, 0)
            if surprised then
                surprised:setVolume(0.05)
            end

            local newPanic = math.min(panic + 25, 100)
            local newStress = math.min(stress + 0.1, 1.0)

            if isClient() then
                MT.SendUpdateStats(player, { panic = newPanic, stress = newStress })
            else
                stats:set(CharacterStat.PANIC, newPanic)
                stats:set(CharacterStat.STRESS, newStress)
            end

            if not isServer() then
                local breathSound = player:isFemale() and "female_heavybreathpanic" or "male_heavybreathpanic"
                local breath = sm:PlaySound(breathSound, false, 5)
                if breath then
                    breath:setVolume(0.025)
                end
            end

            playerdata.iParanoiaCooldown = 30
        end
    end
end

local function Depressive(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.depressive) then
        return
    end
    if playerdata.bToadTraitDepressed then
        return
    end

    local baseChance = 2

    baseChance = baseChance - MT.LuckDelta(player, 1)

    if player:hasTrait(ToadTraitsRegistries.selfdestructive) then
        baseChance = baseChance + 1
    end

    if ZombRand(100) < baseChance then
        local stats = player:getStats()
        local currentUnhappiness = stats:get(CharacterStat.UNHAPPINESS)
        local newUnhappiness = math.min(100, currentUnhappiness + 25)

        if isClient() then
            MT.SendUpdateStats(player, { unhappiness = newUnhappiness })
        else
            stats:set(CharacterStat.UNHAPPINESS, newUnhappiness)
        end

        playerdata.bToadTraitDepressed = true
    end
end

local function CheckDepress(player, playerdata)
    local depressed = playerdata.bToadTraitDepressed
    if depressed then
        local stats = player:getStats()
        local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
        if unhappiness < 25 then
            playerdata.bToadTraitDepressed = false
        else
            if isClient() then
                MT.AccumStat(player, { d_unhappiness = -0.01 })
            else
                stats:set(CharacterStat.UNHAPPINESS, MT.Clamp(unhappiness - 0.01, 0, 100))
            end
        end
    end
end

local function CheckSelfHarm(player)
    if not player:hasTrait(ToadTraitsRegistries.selfdestructive) then
        return
    end

    local stats = player:getStats()
    local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
    local bodyDamage = player:getBodyDamage()
    local modifier = 3 - (player:hasTrait(ToadTraitsRegistries.depressive) and 1 or 0)
    local healthCap = 100 - (unhappiness / modifier)

    if unhappiness >= 25 and bodyDamage:getOverallBodyHealth() > healthCap then
        local damageAmount = 0.15
        local partIndexes = {}
        local parts = bodyDamage:getBodyParts()
        local partsSize = parts:size()

        for i = 0, partsSize - 1 do
            table.insert(partIndexes, i)
            if not isClient() then
                parts:get(i):AddDamage(damageAmount)
            end
        end

        if isClient() then
            MT.AccumBodyDamage(player, partIndexes, damageAmount)
        end
    end
end

local function Blissful(player)
    if not player:hasTrait(ToadTraitsRegistries.blissful) then
        return
    end

    local stats = player:getStats()
    local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
    local boredom = stats:get(CharacterStat.BOREDOM)

    local args = {}
    local updateStats = false

    if unhappiness > 0.05 then
        args.d_unhappiness = -math.min(0.01, unhappiness)
        updateStats = true
    end

    if boredom > 0.02 then
        args.d_boredom = -math.min(0.005, boredom)
        updateStats = true
    end

    if updateStats then
        if isClient() then
            MT.AccumStat(player, args)
        else
            if args.d_unhappiness then
                stats:set(CharacterStat.UNHAPPINESS, MT.Clamp(unhappiness - math.min(0.01, unhappiness), 0, 100))
            end
            if args.d_boredom then
                stats:set(CharacterStat.BOREDOM, MT.Clamp(boredom - math.min(0.005, boredom), 0, 100))
            end
        end
    end
end

local function BadTeeth(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.badteeth) then
        return
    end
    local bodyDamage = player:getBodyDamage()
    local healthTimer = bodyDamage:getHealthFromFoodTimer()

    if isClient() then
        local currentTime = getTimestampMs()
        playerdata.lastBadTeethUpdate = playerdata.lastBadTeethUpdate or 0

        if currentTime < playerdata.lastBadTeethUpdate + 1000 then
            playerdata.fPreviousHealthFromFoodTimer = healthTimer
            return
        end
        playerdata.lastBadTeethUpdate = currentTime
    end

    playerdata.fBadTeethLastSentPain = playerdata.fBadTeethLastSentPain or 0

    if healthTimer > 1000 and healthTimer > playerdata.fPreviousHealthFromFoodTimer then
        local painIncrease = (healthTimer - playerdata.fPreviousHealthFromFoodTimer) * 0.01
        local head = bodyDamage:getBodyPart(BodyPartType.Head)
        local newPain = math.min(head:getAdditionalPain() + painIncrease, 100)

        if isClient() then
            if math.abs(newPain - playerdata.fBadTeethLastSentPain) >= 1 then
                local headPart = BodyPartType.ToIndex(BodyPartType.Head)
                MT.SendBodyPartMechanics(player, { bodyPart = headPart, partPain = newPain })
                playerdata.fBadTeethLastSentPain = newPain
            end
        else
            head:setAdditionalPain(newPain)
        end
    end
    playerdata.fPreviousHealthFromFoodTimer = healthTimer
end

local function Hardy(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.hardy) then
        return
    end

    local currentTime = getTimestampMs()
    playerdata.lastHardyUpdate = playerdata.lastHardyUpdate or 0
    if currentTime < playerdata.lastHardyUpdate + 1000 then
        return
    end
    playerdata.lastHardyUpdate = currentTime

    local stats = player:getStats()
    local currentEndurance = stats:get(CharacterStat.ENDURANCE)
    local regenAmount = 0.05
    if SandboxVars.MoreTraits.HardyEndurance then
        regenAmount = SandboxVars.MoreTraits.HardyEndurance / 500
    end

    local args = {}
    local updateStats = false

    if currentEndurance < 0.85 and playerdata.iHardyEndurance >= 1 then
        args.endurance = math.min(currentEndurance + regenAmount, 1.0)
        playerdata.iHardyEndurance = playerdata.iHardyEndurance - 1
        updateStats = true

        MT.Announce(
            player,
            "HardyNotifier",
            getText("UI_trait_hardyendurance") .. " : " .. playerdata.iHardyEndurance,
            false,
            HaloTextHelper.getColorRed()
        )
    elseif currentEndurance >= 1.0 and playerdata.iHardyEndurance < playerdata.iHardyMaxEndurance then
        args.endurance = currentEndurance - regenAmount
        playerdata.iHardyEndurance = playerdata.iHardyEndurance + 1
        updateStats = true

        MT.Announce(
            player,
            "HardyNotifier",
            getText("UI_trait_hardyendurance") .. " : " .. playerdata.iHardyEndurance,
            true,
            HaloTextHelper.getColorGreen()
        )
    end

    if updateStats then
        if isClient() then
            MT.SendUpdateStats(player, args)
        else
            stats:set(CharacterStat.ENDURANCE, args.endurance)
        end
    end
end

local function BouncerUpdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.bouncer) then
        return
    end

    if playerdata.iBouncercooldown > 0 then
        playerdata.iBouncercooldown = playerdata.iBouncercooldown - 1
        return
    end

    local chance = SandboxVars.MoreTraits.BouncerEffectiveness or 5
    local cooldown = SandboxVars.MoreTraits.BouncerCooldown or 60
    local distance = SandboxVars.MoreTraits.BouncerDistance or 1.75

    chance = chance + MT.LuckDelta(player, 1)

    local enemies = player:getSpottedList()
    if enemies:size() < 3 then
        return
    end

    local closeEnemyCount = 0

    for i = 0, enemies:size() - 1 do
        local enemy = enemies:get(i)
        if enemy:isZombie() and enemy:DistTo(player) <= distance then
            closeEnemyCount = closeEnemyCount + 1
            if closeEnemyCount >= 3 then
                if not enemy:isKnockedDown() and ZombRand(0, 101) <= chance then
                    enemy:setStaggerBack(true)
                    playerdata.iBouncercooldown = cooldown
                    break
                end
            end
        end
    end
end

local function CheckForPlayerBuiltContainer(player, playerdata)
    if player:isPerformingAnAction() and not player:isPlayerMoving() then
        playerdata.ContainerTraitIllegal = true
        playerdata.ContainerTraitPlayerCurrentPositionX = player:getX()
        playerdata.ContainerTraitPlayerCurrentPositionY = player:getY()
    end
    if
    playerdata.ContainerTraitIllegal == true
            and player:getX() ~= playerdata.ContainerTraitPlayerCurrentPositionX
            and player:getY() ~= playerdata.ContainerTraitPlayerCurrentPositionY
    then
        playerdata.ContainerTraitIllegal = false
        playerdata.ContainerTraitPlayerCurrentPositionX = 0
        playerdata.ContainerTraitPlayerCurrentPositionY = 0
    end
end

local function FearfulUpdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.fearful) then
        return
    end

    local stats = player:getStats()
    local panic = stats:get(CharacterStat.PANIC)

    if panic > 5 then
        local chance = 3 + (panic / 10)

        if player:hasTrait(CharacterTrait.COWARDLY) then
            chance = chance + 1
        end
        chance = chance - MT.LuckDelta(player, 1)

        if ZombRand(0, 1000) <= chance then
            local text = ""
            local radius = 0
            local volume = 0

            if panic <= 25 then
                text = "UI_fearful_slightpanic"
                radius, volume = 5, 10
            elseif panic <= 50 then
                text = "UI_fearful_panic"
                radius, volume = 10, 15
            elseif panic <= 75 then
                text = "UI_fearful_strongpanic"
                radius, volume = 20, 25
            else
                text = "UI_fearful_extremepanic"
                radius, volume = 25, 50
            end
            player:Say(getText(text))
            addSound(player, player:getX(), player:getY(), player:getZ(), radius, volume)

            if getActivatedMods():contains("ToadTraitsDynamic") then
                playerdata.MTDFearfulCount = (playerdata.MTDFearfulCount or 0) + 1
            end
        end
    end
end

local function CheckBloodTraits(player)
    local isAnemic = player:hasTrait(ToadTraitsRegistries.anemic)
    local isThick = player:hasTrait(ToadTraitsRegistries.thickblood)
    if not isAnemic and not isThick then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if bodyDamage:getNumPartsBleeding() <= 0 then
        return
    end

    local parts = bodyDamage:getBodyParts()
    local anemicParts = {}
    local thickParts = {}

    for i = 0, parts:size() - 1 do
        local b = parts:get(i)
        if b:bleeding() and not b:IsBleedingStemmed() then
            local isNeck = (b:getType() == BodyPartType.Neck)
            local isHead = (b:getType() == BodyPartType.Head)

            if isAnemic then
                local adjust = 0.4
                if isNeck or isHead then
                    adjust = adjust * 2
                end
                table.insert(anemicParts, { part = i, amount = adjust })
            elseif isThick then
                local adjust = 0.15
                if isNeck or isHead then
                    adjust = adjust * 2
                end
                table.insert(thickParts, { part = i, amount = adjust })
            end
        end
    end

    if #anemicParts > 0 then
        if isClient() then
            for _, data in ipairs(anemicParts) do
                MT.SendBodyPartMechanics(player, { bodyPart = data.part, partHealthReduce = data.amount })
            end
        else
            for _, data in ipairs(anemicParts) do
                parts:get(data.part):ReduceHealth(data.amount)
            end
        end
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_anemic"), false, HaloTextHelper.getColorRed())
    end
    if #thickParts > 0 then
        if isClient() then
            for _, data in ipairs(thickParts) do
                MT.SendBodyPartMechanics(player, { bodyPart = data.part, partHealthAdd = data.amount })
            end
        else
            for _, data in ipairs(thickParts) do
                parts:get(data.part):AddHealth(data.amount)
            end
        end
        HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickblood"), true, HaloTextHelper.getColorGreen())
    end
end

local function Immunocompromised(player)
    if not player:hasTrait(ToadTraitsRegistries.immunocompromised) then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage:HasInjury() then
        return
    end

    local infectionIncrease = 0.05

    if isClient() then
        sendClientCommand(player, "MoreTraitsDefinitive", "Immunocompromised", { infectionIncrease = infectionIncrease })
    else
        local parts = bodyDamage:getBodyParts()
        for i = 0, parts:size() - 1 do
            local b = parts:get(i)
            local infectionValue = b:getWoundInfectionLevel()
            if infectionValue >= 10.0 then
                return
            end
            if b:isInfectedWound() and b:getAlcoholLevel() <= 0 then
                b:setWoundInfectionLevel(infectionValue + infectionIncrease)
            end
        end
    end
end

MT.State = {
    PlayerHit = PlayerHit,
    GlassBody = GlassBody,
    Butter = Butter,
    Paranoia = Paranoia,
    Depressive = Depressive,
    CheckDepress = CheckDepress,
    CheckSelfHarm = CheckSelfHarm,
    Blissful = Blissful,
    BadTeeth = BadTeeth,
    Hardy = Hardy,
    BouncerUpdate = BouncerUpdate,
    CheckForPlayerBuiltContainer = CheckForPlayerBuiltContainer,
    FearfulUpdate = FearfulUpdate,
    CheckBloodTraits = CheckBloodTraits,
    Immunocompromised = Immunocompromised,
}

return MT