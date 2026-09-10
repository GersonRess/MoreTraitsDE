MT = MT or {}

local function BurnWardPatient(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.burned) then
        return
    end

    if playerdata.MTModVersion < 3 or not SandboxVars.MoreTraits.BurnedFireAversion then
        return
    end

    local pX, pY, pZ = player:getX(), player:getY(), player:getZ()
    local distance = SandboxVars.MoreTraits.BurnedDistance or 10
    local closestDist = distance
    local foundFire = false

    local cell = getCell()
    for dy = -distance, distance do
        for dx = -distance, distance do
            if (dx * dx + dy * dy) <= (distance * distance) then
                local square = cell:getGridSquare(pX + dx, pY + dy, pZ)

                if square and square:haveFire() then
                    local d = square:DistTo(pX, pY)
                    if d < closestDist then
                        closestDist = d
                        foundFire = true
                    end
                end
            end
        end
    end

    if foundFire then
        local stats = player:getStats()
        local intensity = 1 - (closestDist / distance)
        local panicGain = math.max(0, SandboxVars.MoreTraits.BurnedPanic * intensity)
        local stressGain = math.max(0, (SandboxVars.MoreTraits.BurnedStress / 1000) * intensity)

        if isClient() then
            MT.SendUpdateStats(player, { panic = panicGain, stress = stressGain })
        else
            stats:set(CharacterStat.PANIC, panicGain)
            stats:set(CharacterStat.STRESS, stressGain)
        end
    end
end

local function HandleGordanite(player, item, itemType)
    local moddata = item:getModData()
    if not moddata then
        return
    end

    if player:hasTrait(ToadTraitsRegistries.gordanite) then
        if not moddata.MTHasBeenModified then
            moddata.MinDamage = item:getMinDamage()
            moddata.MaxDamage = item:getMaxDamage()
            moddata.PushBack = item:getPushBackMod()
            moddata.DoorDamage = item:getDoorDamage()
            moddata.TreeDamage = item:getTreeDamage()
            moddata.CriticalChance = item:getCriticalChance()
            moddata.SwingTime = item:getSwingTime()
            moddata.BaseSpeed = item:getBaseSpeed()
            moddata.MinimumSwing = item:getMinimumSwingTime()
            moddata.MTHasBeenModified = true

            if not getActivatedMods():contains("VorpalWeapons") then
                item:setName(item:getName() .. "+")
            end
        end

        local longBluntLvl = player:getPerkLevel(Perks.Blunt)
        local strengthlvl = player:getPerkLevel(Perks.Strength)
        local floatmod = (longBluntLvl + strengthlvl) / 2 * 0.1

        local modifier = (SandboxVars.MoreTraits.GordaniteEffectiveness or 100) * 0.01
        floatmod = floatmod * modifier
        longBluntLvl = longBluntLvl * modifier
        strengthlvl = strengthlvl * modifier

        local stats = {
            minDmg = moddata.MinDamage + 0.1 + floatmod / 2,
            maxDmg = moddata.MaxDamage + 0.1 + floatmod / 2,
            pushBack = moddata.PushBack + 0.1 + floatmod,
            doorDmg = moddata.DoorDamage + 7 + strengthlvl + longBluntLvl,
            treeDmg = moddata.TreeDamage + 15 + strengthlvl + longBluntLvl * 2,
            crit = moddata.CriticalChance + (strengthlvl + longBluntLvl) / 2,
            swing = moddata.SwingTime - 0.2 - floatmod,
            speed = moddata.BaseSpeed + 0.1 + floatmod,
            length = 0.4 + floatmod / 2,
            minSwing = moddata.MinimumSwing - 0.2 - floatmod,
        }
        item:setMinDamage(stats.minDmg)
        item:setMaxDamage(stats.maxDmg)
        item:setPushBackMod(stats.pushBack)
        item:setDoorDamage(stats.doorDmg)
        item:setTreeDamage(stats.treeDmg)
        item:setCriticalChance(stats.crit)
        item:setSwingTime(stats.swing)
        item:setBaseSpeed(stats.speed)
        item:setWeaponLength(stats.length)
        item:setMinimumSwingTime(stats.minSwing)

        local tooltipKey = (itemType == "Crowbar" or itemType == "CrowbarForged") and "Tooltip_MoreTraits_ItemBoost"
                or "Tooltip_MoreTraits_BloodyItemBoost"
        item:setTooltip(getText(tooltipKey))

        if isClient() then
            sendClientCommand(player, "MoreTraitsDefinitive", "ApplyGordanite", { itemID = item:getID(), stats = stats })
        end
    elseif moddata.MTHasBeenModified then
        item:setMinDamage(moddata.MinDamage)
        item:setMaxDamage(moddata.MaxDamage)
        item:setPushBackMod(moddata.PushBack)
        item:setDoorDamage(moddata.DoorDamage)
        item:setTreeDamage(moddata.TreeDamage)
        item:setCriticalChance(moddata.CriticalChance)
        item:setSwingTime(moddata.SwingTime)
        item:setBaseSpeed(moddata.BaseSpeed)
        item:setWeaponLength(0.4)
        item:setMinimumSwingTime(moddata.MinimumSwing)

        if not getActivatedMods():contains("VorpalWeapons") then
            local name = item:getName()
            if string.sub(name, -1) == "+" then
                item:setName(string.sub(name, 1, -2))
            end
        end

        local tooltip = (itemType == "BloodyCrowbar") and getText("Tooltip_MoreTraits_BloodyCrowbar") or nil
        item:setTooltip(tooltip)

        moddata.MTHasBeenModified = false

        if isClient() then
            sendClientCommand(player, "MoreTraitsDefinitive", "RevertGordanite", { itemID = item:getID() })
        end
    end
end

MT.Weapons = {
    BurnWardPatient = BurnWardPatient,
    HandleGordanite = HandleGordanite,
}

return MT