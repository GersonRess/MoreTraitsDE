MT = MT or {}

local function Trigger(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.indefatigable) then
        return
    end

    if
    playerdata.bindefatigable or (SandboxVars.MoreTraits.IndefatigableOneUse and playerdata.indefatigabledisabled)
    then
        return
    end

    local bodyDamage = player:getBodyDamage()
    local triggerHealth = isClient() and 25 or 15

    if not (bodyDamage:getHealth() < triggerHealth or (not isClient() and player:isDeathDragDown())) then
        return
    end

    local zombies = getCell():getZombieList()

    if getActivatedMods():contains("MTAddonIndefatigableLol") then
        getSoundManager():PlaySound("indefatigabletheme", false, 0):setVolume(0.5)
    end

    if zombies and zombies:size() >= 3 then
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            if zombie:DistTo(player) <= 3.0 then
                zombie:setStaggerBack(true)
                zombie:setKnockedDown(true)
            end
        end
    end

    if not isClient() and player:isDeathDragDown() then
        playerdata.IndefatigableHasBeenDraggedDown = true
        player:setPlayingDeathSound(false)
        player:setDeathDragDown(false)
        player:setHitReaction("EvasiveBlocked")
    end

    local partIndexes = {}
    local bodyParts = bodyDamage:getBodyParts()
    for i = 0, bodyParts:size() - 1 do
        table.insert(partIndexes, i)
        local b = bodyParts:get(i)
        if not MT.TableContains(playerdata.TraitInjuredBodyList, i) then
            b:RestoreToFullHealth()
        else
            b:SetHealth(100)
        end
    end
    bodyDamage:setOverallBodyHealth(100)

    if isClient() then
        MT.SendBodyPartMechanics(player, { bodyParts = partIndexes, indefatigable = true, skipRestoreList = playerdata.TraitInjuredBodyList })
    end

    if bodyDamage:IsInfected() then
        if not playerdata.indefatigablecuredinfection or SandboxVars.MoreTraits.IndefatigableOneUse then
            if isClient() then
                MT.SendUpdateStats(player, { zombie_fever = 0, zombie_infection = 0, panic = 0, clear_wounds = true })
            else
                local stats = player:getStats()
                MT.ClearInfection(bodyDamage)
                stats:set(CharacterStat.PANIC, 0)
                stats:set(CharacterStat.ZOMBIE_FEVER, 0)
                stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
            end
            playerdata.SuperImmuneTextSaid = false
            playerdata.SuperImmuneActive = false
            playerdata.SuperImmuneMinutesPassed = 0
            playerdata.indefatigablecuredinfection = true
        end
    end

    playerdata.bindefatigable = true
    playerdata.indefatigablecooldown = 0

    HaloTextHelper.addTextWithArrow(player, getText("UI_trait_indefatigable"), true, HaloTextHelper.getColorGreen())

    if SandboxVars.MoreTraits.IndefatigableOneUse then
        playerdata.indefatigabledisabled = true
    end
end

local function Recharge(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.indefatigable) or not playerdata.bindefatigable then
        return
    end

    local recharge = (SandboxVars.MoreTraits.IndefatigableRecharge or 7) * 24

    local multiplier = 1
    if playerdata.indefatigablecuredinfection then
        multiplier = multiplier * 2
    end
    if playerdata.IndefatigableHasBeenDraggedDown then
        multiplier = multiplier * 2
    end

    local totalRequired = recharge * multiplier

    playerdata.indefatigablecooldown = (playerdata.indefatigablecooldown or 0) + 1

    if playerdata.indefatigablecooldown >= totalRequired then
        playerdata.indefatigablecooldown = 0
        playerdata.bindefatigable = false
        playerdata.indefatigablecuredinfection = false
        playerdata.IndefatigableHasBeenDraggedDown = false
        playerdata.indefatigabledisabled = false
        player:Say(getText("UI_trait_indefatigablecooldown"))
    end
end

MT.Indefatigable = {
    Trigger = Trigger,
    Recharge = Recharge,
}

return MT