MT = MT or {}

MT.Combat = MT.Combat or {}

local function MeleeTraits(actor, target, weapon, damage)
    if not actor or not target or not weapon or not target:isZombie() then
        return
    end

    local player = actor
    local weaponData = weapon:getModData()
    local totalDamage = 0

    if weaponData.iLastWeaponCond == nil then
        weaponData.iLastWeaponCond = weapon:getCondition()
    end

    local hasBlade = player:hasTrait(ToadTraitsRegistries.problade)
    local hasBlunt = player:hasTrait(ToadTraitsRegistries.problunt)
    local hasSpear = player:hasTrait(ToadTraitsRegistries.prospear)

    if (hasBlade or hasBlunt or hasSpear) and not player:hasTrait(ToadTraitsRegistries.mundane) then
        local traitActive = false
        local critchance = 5

        if hasBlade
            and (
                weapon:isOfWeaponCategory(WeaponCategory.AXE)
                    or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE)
                    or weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE)
            )
        then
            critchance = critchance
                + player:getPerkLevel(Perks.Axe)
                + player:getPerkLevel(Perks.LongBlade)
                + player:getPerkLevel(Perks.SmallBlade)
            traitActive = true
        elseif hasBlunt
            and (
                weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLUNT)
                    or weapon:isOfWeaponCategory(WeaponCategory.BLUNT)
            )
        then
            critchance = critchance + player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.SmallBlunt)
            traitActive = true
        elseif hasSpear and weapon:isOfWeaponCategory(WeaponCategory.SPEAR) then
            critchance = critchance + player:getPerkLevel(Perks.Spear)
            traitActive = true
        end

        if traitActive then
            if player:hasTrait(ToadTraitsRegistries.lucky) then
                critchance = critchance + MT.LuckDelta(player, 1)
            end

            local currentDamage = damage
            if ZombRand(0, 101) <= critchance then
                currentDamage = currentDamage * 2
            end

            totalDamage = totalDamage + ((currentDamage * 1.2) * 0.1)

            if weaponData.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1)
                end
            end
        end
    end

    if player:hasTrait(ToadTraitsRegistries.tavernbrawler) then
        local isImprovised = false
        local whitelist = {
            "ToolWeapon",
            "WeaponCrafted",
            "CookingWeapon",
            "HouseholdWeapon",
            "FirstAidWeapon",
            "GardeningWeapon",
            "SportsWeapon",
            "MaterialWeapon",
            "JunkWeapon",
            "InstrumentWeapon",
            "BrokenWeapon",
            "VehicleMaintenanceWeapon",
        }

        if weapon:isOfWeaponCategory(WeaponCategory.IMPROVISED)
            or MT.TableContains(whitelist, weapon:getDisplayCategory() or "")
        then
            isImprovised = true
        end

        if isImprovised then
            local multiplier = 1
            local repairChance = 50

            if weapon:isOfWeaponCategory(WeaponCategory.SPEAR) then
                repairChance = 0
                multiplier = 0.25
            end

            repairChance = repairChance + MT.LuckDelta(player, 5)
            if player:hasTrait(ToadTraitsRegistries.lucky) then
                multiplier = multiplier + 0.1
            elseif player:hasTrait(ToadTraitsRegistries.unlucky) then
                multiplier = multiplier - 0.1
            end

            if weapon:getConditionLowerChance() <= 2 then
                repairChance = repairChance + 25
                multiplier = multiplier + 0.5
            end

            totalDamage = totalDamage + ((damage * multiplier) * 0.1)

            if weaponData.iLastWeaponCond > weapon:getCondition()
                and ZombRand(0, 101) <= math.min(95, repairChance)
            then
                if weapon:getCondition() < weapon:getConditionMax() then
                    weapon:setCondition(weapon:getCondition() + 1)
                end
            end
        end
    end

    if totalDamage > 0 then
        MT.KillZombie(target, player, totalDamage)
    end

    weaponData.iLastWeaponCond = weapon:getCondition()
end

local function ActionHero(actor, target, weapon, damage)
    if not weapon then
        return
    end
    if not actor then
        return
    end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.actionhero) then
        return
    end

    if weapon:getType() == "BareHands" and not player:hasTrait(ToadTraitsRegistries.martial) then
        return
    end

    local enemies = player:getSpottedList()
    local critchance = 10
    local multiplier = 0.1
    local localDamage = damage * 0.5

    if enemies and enemies:size() > 0 then
        for i = 0, enemies:size() - 1 do
            local enemy = enemies:get(i)
            if enemy:isZombie() then
                local distance = enemy:DistTo(player)
                if distance < 2 then
                    critchance = critchance + 10
                    multiplier = multiplier + 1.0
                elseif distance < 5 then
                    critchance = critchance + 5
                    multiplier = multiplier + 0.4
                elseif distance < 10 then
                    critchance = critchance + 2
                    multiplier = multiplier + 0.2
                end
            end
        end
    end

    critchance = critchance + MT.LuckDelta(player, 5)

    if target:isZombie() and ZombRand(0, 101) <= critchance and not player:hasTrait(ToadTraitsRegistries.mundane) then
        localDamage = localDamage * 5
    end

    local extraDamage = (localDamage * multiplier) * 0.1
    MT.KillZombie(target, player, extraDamage)
end

local function Mundane(actor, target, weapon, damage)
    if not weapon then
        return
    end
    if not actor then
        return
    end
    local player = actor
    local weapondata = weapon:getModData()
    if not weapondata then
        return
    end

    if weapondata.origCritChance == nil then
        weapondata.origCritChance = weapon:getCriticalChance()
    end

    if player:hasTrait(ToadTraitsRegistries.mundane) then
        weapon:setCriticalChance(1)
    else
        if weapon:getCriticalChance() ~= weapondata.origCritChance then
            weapon:setCriticalChance(weapondata.origCritChance)
        end
    end
end

local function Unwavering(actor, target, weapon, damage)
    if not actor or not target or not weapon then
        return
    end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.unwavering) then
        return
    end

    if weapon:getType() == "BareHands" and not player:hasTrait(ToadTraitsRegistries.martial) then
        return
    end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local fatigue = stats:get(CharacterStat.FATIGUE)
    local pain = stats:get(CharacterStat.PAIN)

    local extraDamageMult = 0
    local maxBoost = SandboxVars.MoreTraits.UnwaveringDamageBoost or 2.0
    local bonus = maxBoost - 1.0

    if endurance <= 0.25 or fatigue >= 0.8 or pain >= 75 then
        extraDamageMult = maxBoost
    elseif endurance <= 0.50 or fatigue >= 0.7 or pain >= 50 then
        extraDamageMult = 1.0 + (bonus * 0.5)
    elseif endurance <= 0.75 or fatigue >= 0.6 or pain >= 20 then
        extraDamageMult = 1.0 + (bonus * 0.25)
    end

    if extraDamageMult <= 0 then
        return
    end

    local extraDamage = damage * extraDamageMult
    MT.KillZombie(target, player, extraDamage)
end

local function Martial(actor, target, weapon, damage)
    if not actor or not target or not weapon then
        return
    end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.martial) then
        return
    end

    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    local stats = player:getStats()
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local isBareHands = (weapon:getType() == "BareHands")

    local allow = true
    if not SandboxVars.MoreTraits.MartialWeapons and player:getPrimaryHandItem() ~= nil then
        allow = false
    end

    if isBareHands and allow then
        local scaling = (SandboxVars.MoreTraits.MartialScaling or 100) * 0.01
        local blunt = player:getPerkLevel(Perks.SmallBlunt)
        local critchance = (5 + blunt) * scaling

        critchance = critchance + MT.LuckDelta(player, 1)

        local damageAdj = 1.0
        if endurance < 0.25 then
            damageAdj = 0.25
        elseif endurance < 0.5 then
            damageAdj = 0.5
        elseif endurance < 0.75 then
            damageAdj = 0.75
        end

        local martialDamage = damage
        if target:isZombie()
            and ZombRand(0, 101) <= critchance
            and not player:hasTrait(ToadTraitsRegistries.mundane)
        then
            martialDamage = martialDamage * 4
        end

        martialDamage = martialDamage * 0.1 * damageAdj * scaling

        MT.Announce(
            player,
            "MartialDamage",
            "Damage: " .. tostring(MT.Round(martialDamage, 3)),
            " ",
            HaloTextHelper.getColorGreen()
        )

        MT.KillZombie(target, player, martialDamage)

        local newEndurance = math.max(0, endurance - 0.002)
        if isClient() then
            MT.SendUpdateStats(player, { endurance = newEndurance })
        else
            stats:set(CharacterStat.ENDURANCE, newEndurance)
        end
        MT.AddXP(player, Perks.SmallBlunt, martialDamage * 2 * blunt)
    end
end

local function ProGun(actor, weapon)
    if not actor or not weapon then
        return
    end
    local player = actor
    if not player:hasTrait(ToadTraitsRegistries.progun) then
        return
    end

    local weapondata = weapon:getModData()
    if not weapondata then
        return
    end

    local aiming = player:getPerkLevel(Perks.Aiming)
    local reloading = player:getPerkLevel(Perks.Reloading)
    local chance = aiming + reloading + 10

    local isFirearm = false
    if weapon:isRanged() then
        isFirearm = true
    elseif weapon.getSubCategory and weapon:getSubCategory() == "Firearm" then
        isFirearm = true
    end

    if isFirearm then
        chance = chance + MT.LuckDelta(player, 1)

        if weapondata.iLastWeaponCond == nil then
            weapondata.iLastWeaponCond = weapon:getCondition()
        end
        if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
            if weapon:getCondition() < weapon:getConditionMax() then
                weapon:setCondition(weapon:getCondition() + 1)
            end
        end

        weapondata.iLastWeaponCond = weapon:getCondition()

        if not weapon.getMaxAmmo or not weapon.getCurrentAmmoCount then
            return
        end

        local currentCapacity = weapon:getCurrentAmmoCount()
        local maxCapacity = weapon:getMaxAmmo()
        if SandboxVars.MoreTraits.ProwessGunsAmmoRestore and ZombRand(0, 101) <= chance then
            if currentCapacity < maxCapacity and currentCapacity > 0 then
                if isClient() then
                    sendClientCommand(player, "MoreTraitsDefinitive", "ProwessGuns", { weaponID = weapon:getID() })
                else
                    weapon:setCurrentAmmoCount(currentCapacity + 1)
                end

                MT.Announce(player, "ProwessGunsAmmo", getText("UI_progunammo"), true, HaloTextHelper.getColorGreen())
            end
        end
    end
end

local function TerminatorGun(player)
    local item = player:getPrimaryHandItem()
    if not item or item:getCategory() ~= "Weapon" or item:getSubCategory() ~= "Firearm" then
        return
    end

    local itemdata = item:getModData()
    if not itemdata then
        return
    end

    local hasTerminator = player:hasTrait(ToadTraitsRegistries.terminator)
    local hasAntigun = player:hasTrait(ToadTraitsRegistries.antigun)

    if not itemdata.OGrange then
        itemdata.OGrange = item:getMaxRange()
        itemdata.OGaimingtime = item:getAimingTime()
        itemdata.OGjamchance = item:getJamGunChance()
        itemdata.OGmindmg = item:getMinDamage()
        itemdata.OGmaxdmg = item:getMaxDamage()
        itemdata.MTstate = "Normal"
    end

    local playerstate = player:getCurrentState()
    local isAiming = playerstate == PlayerAimState.instance() or playerstate == PlayerStrafeState.instance()

    if isAiming then
        local stats = player:getStats()
        local stress = stats:get(CharacterStat.STRESS)
        local panic = stats:get(CharacterStat.PANIC)
        local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
        local args = {}
        local updateStats = false

        if hasTerminator then
            if stress > 0 then
                args.d_stress = -math.min(0.01, stress)
                updateStats = true
            end
            if panic > 0 then
                args.d_panic = -math.min(10, panic)
                updateStats = true
            end
        elseif hasAntigun then
            args.d_unhappiness = 0.6
            updateStats = true
        end

        if updateStats then
            if isClient() then
                MT.AccumStat(player, args)
            else
                if args.d_panic then
                    stats:set(CharacterStat.PANIC, MT.Clamp(stats:get(CharacterStat.PANIC) - math.min(10, stats:get(CharacterStat.PANIC)), 0, 100))
                end
                if args.d_stress then
                    stats:set(CharacterStat.STRESS, MT.Clamp(stats:get(CharacterStat.STRESS) - math.min(0.01, stats:get(CharacterStat.STRESS)), 0, 1))
                end
                if args.d_unhappiness then
                    stats:set(CharacterStat.UNHAPPINESS, MT.Clamp(stats:get(CharacterStat.UNHAPPINESS) + 0.6, 0, 100))
                end
            end
        end
    end

    if hasTerminator and itemdata.MTstate ~= "Terminator" then
        item:setAimingTime(itemdata.OGaimingtime * 2)
        item:setMaxRange(itemdata.OGrange + 5)
        item:setJamGunChance(itemdata.OGjamchance / 2)
        item:setMinDamage(itemdata.OGmindmg * 1.25)
        item:setMaxDamage(itemdata.OGmaxdmg * 1.25)
        itemdata.MTstate = "Terminator"
    elseif hasAntigun and itemdata.MTstate ~= "antigun" then
        item:setAimingTime(itemdata.OGaimingtime * 0.8)
        item:setMaxRange(math.max(5, itemdata.OGrange - 5))
        itemdata.MTstate = "antigun"
    elseif not hasTerminator and not hasAntigun and itemdata.MTstate ~= "Normal" then
        item:setAimingTime(itemdata.OGaimingtime)
        item:setMaxRange(itemdata.OGrange)
        item:setJamGunChance(itemdata.OGjamchance)
        item:setMinDamage(itemdata.OGmindmg)
        item:setMaxDamage(itemdata.OGmaxdmg)
        itemdata.MTstate = "Normal"
    end
end

local function BatteringRam(player, playerdata)
    if not player or not player:hasTrait(ToadTraitsRegistries.batteringram) then
        return
    end

    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    local bodyParts = {
        BodyPartType.UpperLeg_L,
        BodyPartType.UpperLeg_R,
        BodyPartType.LowerLeg_L,
        BodyPartType.LowerLeg_R,
        BodyPartType.Foot_L,
        BodyPartType.Foot_R,
    }
    local isInjured = false
    for _, partType in ipairs(bodyParts) do
        local part = bodyDamage:getBodyPart(partType)
        if part and part:getFractureTime() > 0 then
            isInjured = true
            break
        end
    end

    if player:isSprinting() and not isInjured then
        local enemies = player:getSpottedList()
        local nearbyZombies = false

        if enemies then
            for i = 0, enemies:size() - 1 do
                local enemy = enemies:get(i)
                if enemy and enemy:isZombie() and enemy:DistTo(player) <= 2 then
                    nearbyZombies = true
                    break
                end
            end
        end

        local inTree = player:getCurrentSquare():has(IsoObjectType.tree) or false

        if nearbyZombies and not inTree and enemies then
            local fitness = math.max(1, player:getPerkLevel(Perks.Fitness))
            local enduranceReduction = (10 / fitness) * 0.01
            local endurance = stats:get(CharacterStat.ENDURANCE)

            for i = 0, enemies:size() - 1 do
                local enemy = enemies:get(i)
                if enemy and enemy:isZombie() then
                    local distance = enemy:DistTo(player)
                    local enemyData = enemy:getModData()
                    local timestamp = getTimestamp()
                    local canBeHit = not enemyData.lastRamTime or (timestamp > enemyData.lastRamTime + 5)

                    if distance <= 1.5 and canBeHit and not enemy:isKnockedDown() then
                        enemy:setKnockedDown(true)
                        enemy:setStaggerBack(true)
                        enemy:setHitReaction("")
                        enemy:setPlayerAttackPosition("FRONT")
                        enemy:setHitForce(3.0)
                        enemy:reportEvent("wasHit")
                        enemyData.lastRamTime = timestamp

                        endurance = math.max(0, endurance - enduranceReduction)
                        stats:set(CharacterStat.ENDURANCE, endurance)

                        if player:hasTrait(ToadTraitsRegistries.martial)
                            and SandboxVars.MoreTraits.BatteringRamMartialCombo
                        then
                            local hasWeapon = player:getPrimaryHandItem() ~= nil
                            if SandboxVars.MoreTraits.MartialWeapons or not hasWeapon then
                                local damageMult = 1.0
                                local finalDamage = 0
                                if endurance < 0.25 then
                                    damageMult = 0.25
                                elseif endurance < 0.5 then
                                    damageMult = 0.5
                                elseif endurance < 0.75 then
                                    damageMult = 0.75
                                end
                                finalDamage = (ZombRand(10, 61) / 100) * damageMult
                                enemy:setHealth(enemy:getHealth() - finalDamage)
                                if enemy:getHealth() <= 0 then
                                    enemy:Kill(player)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function NoodleLegs(player)
    if not player or not player:hasTrait(ToadTraitsRegistries.noodlelegs) then
        return
    end

    if not player:isPlayerMoving() then
        return
    end

    local isRunning = player:isRunning()
    local isSprinting = player:isSprinting()
    if not (isRunning or isSprinting) then
        return
    end

    local sprinting = player:getPerkLevel(Perks.Sprinting)
    local nimble = player:getPerkLevel(Perks.Nimble)
    local tripChance = 500001 + (nimble * 12500) + (sprinting * 12500)

    if player:hasTrait(CharacterTrait.GRACEFUL) then
        tripChance = tripChance * 1.2
    end
    if player:hasTrait(CharacterTrait.CLUMSY) then
        tripChance = tripChance * 0.8
    end
    if player:hasTrait(ToadTraitsRegistries.lucky) then
        tripChance = tripChance * (1.05 * luckimpact)
    end
    if player:hasTrait(ToadTraitsRegistries.unlucky) then
        tripChance = tripChance * (0.95 * luckimpact)
    end

    if isSprinting then
        tripChance = tripChance * 0.6
    end

    if ZombRand(0, tripChance) <= 100 then
        local side = ZombRand(2) == 0 and "left" or "right"
        player:setBumpFallType("FallForward")
        player:setBumpType(side)
        player:setBumpDone(false)
        player:setBumpFall(true)
        player:reportEvent("wasBumped")
    end
end

local function UpdateUnwavering(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.unwavering) then
        return
    end
    if playerdata.UnwaveringInjurySpeedChanged then
        return
    end

    local bodyDamage = player:getBodyDamage()
    local parts = bodyDamage:getBodyParts()
    local partIndexes = {}

    local stats = {
        scratch = 30,
        cut = 30,
        deep = 60,
        burn = 60,
    }

    for i = 0, parts:size() - 1 do
        table.insert(partIndexes, i)

        local part = parts:get(i)
        part:setScratchSpeedModifier(part:getScratchSpeedModifier() + stats.scratch)
        part:setCutSpeedModifier(part:getCutSpeedModifier() + stats.cut)
        part:setDeepWoundSpeedModifier(part:getDeepWoundSpeedModifier() + stats.deep)
        part:setBurnSpeedModifier(part:getBurnSpeedModifier() + stats.burn)
    end

    if isClient() then
        MT.SendBodyPartMechanics(player, { bodyParts = partIndexes, unwaveringStats = stats })
    end

    playerdata.UnwaveringInjurySpeedChanged = true
end

local function Amputee(player, justGotInfected)
    if not player:hasTrait(ToadTraitsRegistries.amputee) or getActivatedMods():contains("Amputation") then
        return
    end

    local bodyDamage = player:getBodyDamage()
    if not justGotInfected and bodyDamage:getOverallBodyHealth() >= 100 then
        return
    end

    local parts = {
        BodyPartType.UpperArm_L,
        BodyPartType.ForeArm_L,
        BodyPartType.Hand_L,
    }

    local needToHeal = false
    for _, partType in ipairs(parts) do
        local part = bodyDamage:getBodyPart(partType)
        if part:HasInjury() then
            needToHeal = true
            if not isClient() then
                part:RestoreToFullHealth()
            end
        end
    end

    if needToHeal or justGotInfected then
        if isClient() then
            MT.SendUpdateStats(player, { zombie_fever = 0, zombie_infection = 0, clear_wounds = true, amputee = true })
        else
            if justGotInfected then
                local stats = player:getStats()
                MT.ClearInfection(bodyDamage)
                stats:set(CharacterStat.ZOMBIE_FEVER, 0)
                stats:set(CharacterStat.ZOMBIE_INFECTION, 0)
            end
        end
    end
end

local function OnEquipPrimary(player, item)
    if not player or not item then
        return
    end

    local isAmputee = player:hasTrait(ToadTraitsRegistries.amputee) or getActivatedMods():contains("Amputation")
    if isAmputee and (item:isTwoHandWeapon() or item:isRequiresEquippedBothHands()) then
        player:setPrimaryHandItem(nil)
        HaloTextHelper.addText(player, getText("UI_trait_amputee_missingarm"), "", HaloTextHelper.getColorRed())
        return
    end

    local itemType = item:getType()
    if player:hasTrait(ToadTraitsRegistries.burned) then
        local fireItems = {
            FlameTrap = true,
            FlameTrapTriggered = true,
            FlameTrapSensorV1 = true,
            FlameTrapSensorV2 = true,
            FlameTrapSensorV3 = true,
            FlameTrapRemote = true,
            Molotov = true,
        }
        if fireItems[itemType] then
            player:setPrimaryHandItem(nil)
            HaloTextHelper.addText(player, getText("UI_burnedcannotequip"), "", HaloTextHelper.getColorRed())
            return
        end
    end

    local crowbars = {
        Crowbar = true,
        CrowbarForged = true,
        BloodyCrowbar = true,
    }

    if crowbars[itemType] then
        MT.Weapons.HandleGordanite(player, item, itemType)
    end
end

local function OnEquipSecondary(player, item)
    if item == nil then
        return
    end

    if player:hasTrait(ToadTraitsRegistries.amputee) or getActivatedMods():contains("Amputation") then
        if item and item ~= nil then
            player:setSecondaryHandItem(nil)
            HaloTextHelper.addText(player, getText("UI_trait_amputee_missingarm"), HaloTextHelper.getColorRed())
        end
    end
end

MT.Combat.MeleeTraits = MeleeTraits
MT.Combat.ActionHero = ActionHero
MT.Combat.Mundane = Mundane
MT.Combat.Unwavering = Unwavering
MT.Combat.Martial = Martial
MT.Combat.ProGun = ProGun
MT.Combat.TerminatorGun = TerminatorGun
MT.Combat.BatteringRam = BatteringRam
MT.Combat.NoodleLegs = NoodleLegs
MT.Combat.UpdateUnwavering = UpdateUnwavering
MT.Combat.Amputee = Amputee
MT.Combat.OnEquipPrimary = OnEquipPrimary
MT.Combat.OnEquipSecondary = OnEquipSecondary