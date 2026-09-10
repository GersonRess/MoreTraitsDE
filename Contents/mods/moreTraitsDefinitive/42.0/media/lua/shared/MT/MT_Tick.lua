MT = MT or {}

local function OnPlayerUpdate(player)
    if not player then
        return
    end
    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    if internalTick >= 30 then
        local bodyDamage = player:getBodyDamage()
        local isInfected = bodyDamage:isInfected()
        local justGotInfected = (not playerdata.bWasInfected and isInfected)

        MT.Combat.Amputee(player, justGotInfected)
        playerdata.bWasInfected = isInfected
        MT.World.VehicleCheck(player)
        MT.Nutrition.FoodUpdate(player)
        MT.World.ClothingUpdate(player)
    elseif internalTick == 20 then
        MT.State.FearfulUpdate(player, playerdata)
    elseif internalTick == 10 then
        MT.SuperImmune.Trigger(player, playerdata)
    end

    MT.Rest.SecondWind(player, playerdata)
    MT.Indefatigable.Trigger(player, playerdata)
    MT.State.CheckDepress(player, playerdata)
    MT.State.Blissful(player)
    MT.State.Hardy(player, playerdata)
    MT.Alcohol.Update(player, playerdata)
    MT.Combat.BatteringRam(player, playerdata)
    MT.State.BouncerUpdate(player, playerdata)
    MT.State.BadTeeth(player, playerdata)
    MT.World.Albino(player, playerdata)
    MT.State.CheckForPlayerBuiltContainer(player, playerdata)
    MT.Nutrition.IdealWeight(player, playerdata)
    MT.Combat.NoodleLegs(player)

    internalTick = internalTick + 1
    if internalTick > 30 then
        internalTick = 0
    end
end

local function OnPlayerMove(player)
    if not player then
        return
    end
    MT.World.FastGimpMove(player)
end

local function OnWeaponHitCharacter(actor, target, weapon, damage)
    MT.Combat.MeleeTraits(actor, target, weapon, damage)
    MT.Combat.ActionHero(actor, target, weapon, damage)
    MT.Combat.Mundane(actor, target, weapon, damage)
    MT.Combat.Unwavering(actor, target, weapon, damage)
    MT.Combat.Martial(actor, target, weapon, damage)
end

local function OnWeaponSwing(actor, weapon)
    MT.Combat.ProGun(actor, weapon)
end

local function AddXP(player, perk, amount, xpBoost)
    MT.XP.SpecializationAndAntiGun(player, perk, amount)
    MT.XP.GymGoer(player, perk, amount)
end

local function LevelPerk(player, perk)
    MT.XP.FixSpecialization(player, perk)
end

local function OnPlayerGetDamage(player, _, __)
    MT.State.PlayerHit(player, _, __)
end

local function OnEquipPrimary(player, item)
    MT.Combat.OnEquipPrimary(player, item)
end

local function OnEquipSecondary(player, item)
    MT.Combat.OnEquipSecondary(player, item)
end

local function EveryOneMinute()
    local player = getPlayer()
    if not player then
        return
    end
    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    MT.State.Paranoia(player, playerdata)
    MT.State.Butter(player)
    MT.Containers.UnHighlightScrounger(player, playerdata)
    MT.World.LeadFoot(player)
    MT.XP.GymGoerUpdate(player, playerdata)
    MT.SuperImmune.HungerCheck(player, playerdata)
    MT.Rest.RestfulSleeperWakeUp(player, playerdata)
    MT.World.AlbinoTimer(player, playerdata)
    MT.Combat.TerminatorGun(player)
    MT.Weapons.BurnWardPatient(player, playerdata)
    MT.SuperImmune.RecoveryProcess(player, playerdata)
    MT.SuperImmune.FakeInfectionHealthLoss(player, playerdata)
    MT.State.Immunocompromised(player)
    MT.State.CheckSelfHarm(player)
    MT.State.CheckBloodTraits(player)
    MT.Rest.QuickRest(player, playerdata)
end

local function EveryHours()
    local player = getPlayer()
    if not player then
        return
    end
    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    MT.Alcohol.Tick(player, playerdata)
    MT.Alcohol.Poison(player, playerdata)
    MT.Rest.SecondWindRecharge(player, playerdata)
    MT.Indefatigable.Recharge(player, playerdata)
    MT.Rest.RestfulSleeper(player, playerdata)
    MT.State.Depressive(player, playerdata)
    MT.Combat.UpdateUnwavering(player, playerdata)

    if player:hasTrait(ToadTraitsRegistries.ingenuitive) and not playerdata.IngenuitiveActivated then
        MT.Creation.LearnAllRecipes(player)
        playerdata.IngenuitiveActivated = true
    end

    local bodyParts = player:getBodyDamage():getBodyParts()
    if bodyParts then
        for _, list in ipairs({ playerdata.InjuredBodyList, playerdata.TraitInjuredBodyList }) do
            for i = #list, 1, -1 do
                local part = bodyParts:get(list[i])
                if not part or not part:HasInjury() then
                    table.remove(list, i)
                end
            end
        end
    end
end

Events.OnPlayerUpdate.Add(OnPlayerUpdate)
Events.OnPlayerMove.Add(OnPlayerMove)
Events.OnWeaponHitCharacter.Add(OnWeaponHitCharacter)
Events.OnWeaponSwing.Add(OnWeaponSwing)
Events.AddXP.Add(AddXP)
Events.LevelPerk.Add(LevelPerk)
Events.EveryOneMinute.Add(EveryOneMinute)
Events.EveryHours.Add(EveryHours)
Events.OnPlayerGetDamage.Add(OnPlayerGetDamage)
Events.OnEquipPrimary.Add(OnEquipPrimary)
Events.OnEquipSecondary.Add(OnEquipSecondary)
Events.OnRefreshInventoryWindowContainers.Add(MT.Containers.ContainerEvents)