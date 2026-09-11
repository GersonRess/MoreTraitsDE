-- More Traits Definitive: core utilities and shared state.

if not isServer() then
    if PZAPI and PZAPI.ModOptions then
        MT_Config = PZAPI.ModOptions:getOptions("moreTraitsDefinitive")
    end
end

skipxpadd = false
luckimpact = 1.0
MTModVersion = 42.20

MT = MT or {}

MT.playerDataDefaults = {
    MTModVersion = MTModVersion,
    internalTick = 0,
    secondwinddisabled = false,
    secondwindrecoveredfatigue = false,
    secondwindcooldown = 0,
    bToadTraitDepressed = false,
    indefatigablecooldown = 0,
    indefatigablecuredinfection = false,
    indefatigabledisabled = false,
    bindefatigable = false,
    IndefatigableHasBeenDraggedDown = false,
    bSatedDrink = true,
    iHoursSinceDrink = 0,
    iTimesCannibal = 0,
    fPreviousHealthFromFoodTimer = 1000,
    bWasInfected = false,
    iHardyEndurance = 5,
    iHardyMaxEndurance = 5,
    iHardyInterval = 1000,
    iWithdrawalCooldown = 24,
    iParanoiaCooldown = 10,
    SuperImmuneRecovery = 0,
    SuperImmuneActive = false,
    SuperImmuneMinutesPassed = 0,
    SuperImmuneTextSaid = false,
    SuperImmuneHealedOnce = false,
    SuperImmuneMinutesWellFed = 0,
    SuperImmuneAbsoluteWellFedAmount = 0,
    SuperImmuneInfections = 0,
    SuperImmuneLethal = false,
    MotionActive = false,
    HasSlept = false,
    FatigueWhenSleeping = 0,
    NeckHadPain = false,
    ContainerTraitIllegal = false,
    ContainerTraitPlayerCurrentPositionX = 0,
    ContainerTraitPlayerCurrentPositionY = 0,
    AlbinoTimeSpentOutside = 0,
    isMTAlcoholismInitialized = false,
    iBouncercooldown = 0,
    bisInfected = false,
    bisAlbinoOutside = false,
    bWasJustSprinting = false,
    InjuredBodyList = {},
    UnwaveringInjurySpeedChanged = false,
    OldCalories = 810,
    IngenuitiveActivated = false,
    EvasivePlayerInfected = false,
    TraitInjuredBodyList = {},
    isSleeping = false,
    QuickRestActive = false,
    QuickRestEndurance = -1,
    QuickRestFinished = false,
    AntiGunProcessing = false,
}

function MT.InitPlayerData(player, playerdata)
    local pd = playerdata or player:getModData()
    for key, defaultValue in pairs(MT.playerDataDefaults) do
        if pd[key] == nil then
            pd[key] = defaultValue
        end
    end
    if type(pd.MTModVersion) == "string" then
        pd.MTModVersion = tonumber(pd.MTModVersion) or MTModVersion
    end
    return pd
end

function MT.AddXP(player, perk, amount, xpBoost)
    player:getXp():AddXP(perk, amount, xpBoost or false, false, false)
end

function MT.LevelPerkByAmount(player, perk, amount)
    local currentLevel = player:getPerkLevel(perk)
    local targetLevel = math.min(10, currentLevel + amount)
    for i = currentLevel + 1, targetLevel do
        player:LevelPerk(perk)
        player:getXp():setXPToLevel(perk, i)
    end
end

function MT.GameSpeedMultiplier()
    local gamespeed = UIManager.getSpeedControls():getCurrentGameSpeed()
    local multiplier = 1
    if gamespeed == 2 then
        multiplier = 5
    elseif gamespeed == 3 then
        multiplier = 20
    elseif gamespeed == 4 then
        multiplier = 40
    end
    return multiplier
end

function MT.TableContains(t, e)
    for _, value in pairs(t) do
        if value == e then
            return true
        end
    end
    return false
end

function MT.TableLength(t)
    local count = 0
    if type(t) == "table" then
        for _ in pairs(t) do
            count = count + 1
        end
    else
        count = 1
    end
    return count
end

function MT.Deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[MT.Deepcopy(orig_key)] = MT.Deepcopy(orig_value)
        end
        setmetatable(copy, MT.Deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function MT.Round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

function MT.ClearInfection(bodyDamage)
    bodyDamage:setInfected(false)
    bodyDamage:setInfectionMortalityDuration(-1)
    bodyDamage:setInfectionTime(-1)
end

function MT.LuckDelta(player, amount)
    if player:hasTrait(ToadTraitsRegistries.lucky) then
        return amount * luckimpact
    elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
        return -amount * luckimpact
    end
    return 0
end

function MT.SendUpdateStats(player, args)
    sendClientCommand(player, "MoreTraitsDefinitive", "UpdateStats", args)
end

function MT.SendBodyPartMechanics(player, args)
    sendClientCommand(player, "MoreTraitsDefinitive", "BodyPartMechanics", args)
end

MT._statAcc = {}
MT._bodyAcc = {}

function MT.Clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

function MT.AccumStat(player, deltas)
    if not isClient() or not player then
        return
    end
    local key = player:getOnlineID()
    local acc = MT._statAcc[key]
    if not acc then
        acc = {}
        MT._statAcc[key] = acc
    end
    for field, delta in pairs(deltas) do
        if type(delta) == "number" and delta ~= 0 then
            acc["d_" .. field] = (acc["d_" .. field] or 0) + delta
        end
    end
end

function MT.AccumBodyDamage(player, partIndexes, damage)
    if not isClient() or not player then
        return
    end
    local key = player:getOnlineID()
    local acc = MT._bodyAcc[key]
    if not acc then
        acc = { parts = {}, damage = 0 }
        MT._bodyAcc[key] = acc
    end
    for _, index in ipairs(partIndexes) do
        acc.parts[index] = true
    end
    acc.damage = acc.damage + damage
end

function MT.FlushAccum(player)
    if not isClient() or not player then
        return
    end
    local key = player:getOnlineID()
    local acc = MT._statAcc[key]
    if acc then
        MT._statAcc[key] = nil
        MT.SendUpdateStats(player, acc)
    end
    local bacc = MT._bodyAcc[key]
    if bacc then
        MT._bodyAcc[key] = nil
        local parts = {}
        for index in pairs(bacc.parts) do
            parts[#parts + 1] = index
        end
        if #parts > 0 and bacc.damage ~= 0 then
            MT.SendBodyPartMechanics(player, { bodyParts = parts, partDamage = bacc.damage })
        end
    end
end

function MT.Announce(player, optionKey, text, ...)
    if isServer() or not MT_Config then return end
    local opt = MT_Config:getOption(optionKey)
    if not opt or not opt:getValue() then return end
    HaloTextHelper.addTextWithArrow(player, text, ...)
end

function MT.KillZombie(target, player, damage)
    local targetData = target:getModData()
    if not targetData or target:isDead() then return end
    local newHealth = target:getHealth() - damage
    if newHealth > 0 then
        target:setHealth(newHealth)
        return
    end
    if not targetData.TraitKillProcessed then
        targetData.TraitKillProcessed = true
        target:Kill(player)
        if target:isZombie() then
            player:setZombieKills(player:getZombieKills() + 1)
        end
    end
end

function MT.QuickSlowTraitCheck(self, baseTime)
    if baseTime <= 1 then return baseTime end
    if type(self) ~= "table" or not self.character then return baseTime end
    if self.character:isTimedActionInstant() then return 1 end

    local isQuick = self.character:hasTrait(ToadTraitsRegistries.quickworker)
    local isSlow = self.character:hasTrait(ToadTraitsRegistries.slowworker)

    if not isQuick and not isSlow then
        return baseTime
    end

    local modifier = 0

    if isQuick then
        modifier = (SandboxVars.MoreTraits.QuickWorkerScaler or 50) * 0.01
    elseif isSlow then
        modifier = (SandboxVars.MoreTraits.SlowWorkerScaler or 50) * 0.01
    end

    if self.Type == "ISReadABook" then
        if self.character:hasTrait(CharacterTrait.FAST_READER) then
            modifier = modifier * (isQuick and 1.25 or 0.75)
        elseif self.character:hasTrait(CharacterTrait.SLOW_READER) then
            modifier = modifier * (isQuick and 0.75 or 1.25)
        else
            modifier = modifier * 1.0
        end
    end

    local bonus = 0
    if ZombRand(100) <= 10 then
        if self.character:hasTrait(ToadTraitsRegistries.lucky) then
            bonus = bonus + (0.25 * (luckimpact or 1))
        end
        if self.character:hasTrait(CharacterTrait.DEXTROUS) then
            bonus = bonus + 0.25
        end
        if self.character:hasTrait(ToadTraitsRegistries.unlucky) then
            bonus = bonus - (0.25 * (luckimpact or 1))
        end
        if self.character:hasTrait(CharacterTrait.ALL_THUMBS) then
            bonus = bonus - 0.25
        end
    end

    if isQuick then
        local finalReduction = math.max(0, modifier + bonus)
        baseTime = baseTime - (baseTime * finalReduction)
    elseif isSlow then
        local finalPenalty = math.max(0, modifier - bonus)
        baseTime = baseTime + (baseTime * finalPenalty)
    end

    return math.max(1, baseTime)
end

function MT.PatchTimedAction(class, baseTimeFn)
    if not _G[class] then return end
    local C = _G[class]
    C.getDuration = function(self)
        return MT.QuickSlowTraitCheck(self, baseTimeFn(self))
    end
    local o_new = C.new
    if o_new then
        C.new = function(self, ...)
            local o = o_new(self, ...)
            if o then
                o.maxTime = o:getDuration()
            end
            return o
        end
    end
end

function MT.PatchFireBlock(class, aversionFn)
    local C = _G[class]
    if not C then return end
    local o_new = C.new
    C.new = function(self, ...)
        local o = o_new(self, ...)
        local character = select(1, ...)
        if aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

function MT.RequestContainerLoot(player, containerObj, command, items)
    sendClientCommand(player, "MoreTraitsDefinitive", command, {
        x = containerObj:getX(),
        y = containerObj:getY(),
        z = containerObj:getZ(),
        items = items,
    })
end