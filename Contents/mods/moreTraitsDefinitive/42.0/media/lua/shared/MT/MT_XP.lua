MT = MT or {}

MT.XP = MT.XP or {}

local SPEC_PERKS = {
    [ToadTraitsRegistries.specweapons] = {
        Perks.Axe,
        Perks.Blunt,
        Perks.LongBlade,
        Perks.SmallBlade,
        Perks.Maintenance,
        Perks.SmallBlunt,
        Perks.Spear,
    },
    [ToadTraitsRegistries.specfood] = {
        Perks.Cooking,
        Perks.Farming,
        Perks.PlantScavenging,
        Perks.Trapping,
        Perks.Fishing,
        Perks.Foraging,
        Perks.Tracking,
        Perks.Husbandry,
        Perks.Butchering,
    },
    [ToadTraitsRegistries.specguns] = { Perks.Aiming, Perks.Reloading },
    [ToadTraitsRegistries.specmove] = { Perks.Lightfoot, Perks.Nimble, Perks.Sprinting, Perks.Sneak },
    [ToadTraitsRegistries.speccrafting] = {
        Perks.Blacksmith,
        Perks.Woodwork,
        Perks.Carving,
        Perks.Electricity,
        Perks.MetalWelding,
        Perks.Mechanics,
        Perks.Tailoring,
        Perks.Glassmaking,
        Perks.Masonry,
        Perks.Pottery,
        Perks.FlintKnapping,
    },
    [ToadTraitsRegistries.specaid] = { Perks.Doctor },
}

local function SpecializationAndAntiGun(player, perk, amount)
    if skipxpadd or not amount or amount <= 0 then
        return
    end

    local hasAnySpec = false
    for trait in pairs(SPEC_PERKS) do
        if player:hasTrait(trait) then
            hasAnySpec = true
            break
        end
    end

    local hasAntiGun = player:hasTrait(ToadTraitsRegistries.antigun)
    if not hasAntiGun and not hasAnySpec then
        return
    end
    if perk == Perks.Fitness or perk == Perks.Strength then
        return
    end
    if player:getPerkLevel(perk) >= 10 then
        return
    end

    local totalPenaltyMultiplier = 0

    if hasAnySpec then
        local isCurrentPerkSpecialized = false
        for trait, perks in pairs(SPEC_PERKS) do
            if player:hasTrait(trait) then
                for _, p in ipairs(perks) do
                    if perk == p then
                        isCurrentPerkSpecialized = true
                        break
                    end
                end
            end
            if isCurrentPerkSpecialized then
                break
            end
        end

        if not isCurrentPerkSpecialized then
            local specModifier = (SandboxVars.MoreTraits.SpecializationXPPercent or 75) * 0.01
            totalPenaltyMultiplier = totalPenaltyMultiplier + specModifier
        end
    end

    if hasAntiGun and perk == Perks.Aiming then
        totalPenaltyMultiplier = totalPenaltyMultiplier + 0.25
    end

    if totalPenaltyMultiplier > 0 then
        local finalPenalty = math.min(totalPenaltyMultiplier, 0.95)
        local xpToRemove = amount * finalPenalty

        skipxpadd = true
        MT.AddXP(player, perk, -xpToRemove)
        skipxpadd = false
    end
end

local function FixSpecialization(player, perk)
    if not perk then
        return
    end
    if player:getXp():getXP(perk) < 0 then
        player:getXp():setXPToLevel(perk, player:getPerkLevel(perk))
    end
end

local function GymGoer(player, perk, amount)
    if not amount or amount <= 0 or not player:hasTrait(ToadTraitsRegistries.gymgoer) then
        return
    end

    local playerdata = player:getModData()
    if not playerdata or playerdata.GymGoerProcessing then
        return
    end

    local isFitnessState = FitnessState ~= nil and player:getCurrentState() == FitnessState.instance()
    local isPerks = (perk == Perks.Fitness or perk == Perks.Strength)

    if not (isPerks and isFitnessState) then
        return
    end

    playerdata.GymGoerProcessing = true

    local modifier = (SandboxVars.MoreTraits.GymGoerPercent or 200) or 200
    local bonusMultiplier = ((modifier * 0.01) - 1) * 0.1

    if bonusMultiplier > 0 then
        MT.AddXP(player, perk, amount * bonusMultiplier)
    end

    playerdata.GymGoerProcessing = false
end

local function GymGoerUpdate(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.gymgoer) then
        return
    end
    if not SandboxVars.MoreTraits.GymGoerNoExerciseFatigue then
        return
    end

    local fitness = player:getFitness()
    if not fitness then
        return
    end

    if not playerdata.GymGoerStiffnessList then
        playerdata.GymGoerStiffnessList = {
            fitness:getCurrentExeStiffnessInc("arms") or 0,
            fitness:getCurrentExeStiffnessInc("legs") or 0,
            fitness:getCurrentExeStiffnessInc("chest") or 0,
            fitness:getCurrentExeStiffnessInc("abs") or 0,
        }
    end

    local muscleGroups = {
        {
            name = "arms",
            parts = {
                BodyPartType.UpperArm_L,
                BodyPartType.UpperArm_R,
                BodyPartType.ForeArm_L,
                BodyPartType.ForeArm_R,
                BodyPartType.Hand_L,
                BodyPartType.Hand_R,
            },
        },
        {
            name = "legs",
            parts = {
                BodyPartType.UpperLeg_L,
                BodyPartType.UpperLeg_R,
                BodyPartType.LowerLeg_L,
                BodyPartType.LowerLeg_R,
            },
        },
        { name = "chest", parts = { BodyPartType.Torso_Upper } },
        { name = "abs", parts = { BodyPartType.Torso_Lower } },
    }

    local stiffnessList = playerdata.GymGoerStiffnessList
    for i, group in ipairs(muscleGroups) do
        local currentStiffness = fitness:getCurrentExeStiffnessInc(group.name) or 0
        local recordedPeak = stiffnessList[i] or 0

        if recordedPeak > 0 and (currentStiffness == 0 or currentStiffness < (recordedPeak / 2)) then
            if isClient() then
                local bodyParts = {}
                for _, partType in ipairs(group.parts) do
                    table.insert(bodyParts, BodyPartType.ToIndex(partType))
                end
                sendClientCommand(
                    player,
                    "MoreTraitsDefinitive",
                    "ProcessBodyPartMechanics",
                    { bodyParts = bodyParts, partStiffness = 0, clearStrain = true }
                )
            else
                for _, partType in ipairs(group.parts) do
                    local part = player:getBodyDamage():getBodyPart(partType)
                    if part then
                        part:setStiffness(0)
                        fitness:removeStiffnessValue(BodyPartType.ToString(partType))
                    end
                end
            end
            stiffnessList[i] = 0
        elseif currentStiffness > recordedPeak then
            stiffnessList[i] = currentStiffness
        end
    end
end

MT.XP.SpecializationAndAntiGun = SpecializationAndAntiGun
MT.XP.FixSpecialization = FixSpecialization
MT.XP.GymGoer = GymGoer
MT.XP.GymGoerUpdate = GymGoerUpdate