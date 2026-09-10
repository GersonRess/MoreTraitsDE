-- More Traits Definitive: creation hooks, starter items and starting perks.

MT = MT or {}

local function giveStarterItems(player)
    if isClient() then
        return
    end
    local inv = player:getInventory()

    if player:hasTrait(ToadTraitsRegistries.deprived) then
        player:clearWornItems()
        inv:removeAllItems()
        player:createKeyRing()
        if SandboxVars.MoreTraits.ForgivingDeprived then
            inv:AddItem("Base.Belt2")
        end
        return
    end

    if player:hasTrait(ToadTraitsRegistries.preparedfood) then
        local holder = inv:AddItem("Base.Plasticbag")

        if holder then
            local holderInv = holder:getItemContainer()
            local items = {
                "Base.TinOpener",
                "Base.CannedTomato",
                "Base.CannedPotato",
                "Base.CannedCarrots",
                "Base.CannedBroccoli",
                "Base.CannedCabbage",
                "Base.CannedEggplant",
            }
            for _, item in ipairs(items) do
                holderInv:AddItem(item)
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedammo) then
        local holder = inv:AddItem("Base.PistolCase1")

        if holder then
            local holderInv = holder:getItemContainer()
            local items = {
                "Base.Bullets9mmBox",
                "Base.Bullets45Box",
                "Base.Bullets44Box",
                "Base.Bullets38Box",
                "Base.3030Box",
                "Base.308Box",
                "Base.556Box",
                "Base.ShotgunShellsBox",
            }
            for _, item in ipairs(items) do
                holderInv:AddItem(item)
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedweapon) then
        local items = { "Base.BaseballBat_Can", "Base.HuntingKnife" }
        for _, item in ipairs(items) do
            inv:AddItem(item)
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedmedical) then
        local holder = inv:AddItem("Base.FirstAidKit")

        if holder then
            local holderInv = holder:getItemContainer()
            if holderInv then
                local items = {
                    "Base.Bandaid",
                    "Base.PillsAntiDep",
                    "Base.Disinfectant",
                    "Base.AlcoholWipes",
                    "Base.PillsBeta",
                    "Base.Pills",
                    "Base.SutureNeedle",
                    "Base.Tissue",
                    "Base.Tweezers",
                }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item)
                end
                local amount = SandboxVars.MoreTraits.PreparedMedicalBandageAmount or 4
                for i = 1, amount do
                    holderInv:AddItem("Base.Bandage")
                end
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedrepair) then
        local holder = inv:AddItem("Base.Toolbox")

        if holder then
            local holderInv = holder:getItemContainer()
            if holderInv then
                local items = { "Base.Screwdriver", "Base.Saw", "Base.Hammer", "Base.NailsBox" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item)
                end
                for i = 1, 8 do
                    holderInv:AddItem("Base.Garbagebag")
                end
            end
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcamp) then
        local holder = inv:AddItem("MoreTraits.Bag_SmallHikingBag")

        if holder then
            local holderInv = holder:getItemContainer()
            if holderInv then
                local items = {
                    "Base.Matches",
                    "Base.TentGreen_Packed",
                    "Base.BeefJerky",
                    "Base.Pop",
                    "Base.FishingRod",
                    "Base.FishingLine",
                    "Base.FishingHookBox",
                    "Base.Battery",
                    "Base.Torch",
                    "Base.WaterBottle",
                }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item)
                end
                for i = 1, 3 do
                    holderInv:AddItem("Base.Stone2")
                end
            end
            if player:getClothingItem_Back() == nil then
                player:setClothingItem_Back(holder)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedpack) then
        local holder = inv:AddItem("Base.Bag_NormalHikingBag")
        if holder and player:getClothingItem_Back() == nil then
            player:setClothingItem_Back(holder)
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcar) then
        local holder = inv:AddItem("Base.Bag_JanitorToolbox")

        if holder then
            local holderInv = holder:getItemContainer()
            if holderInv then
                local items = {
                    "Base.CarBattery1",
                    "Base.Screwdriver",
                    "Base.Wrench",
                    "Base.LugWrench",
                    "Base.TirePump",
                    "Base.Jack",
                }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item)
                end
            end
            if not player:getPrimaryHandItem() then
                player:setPrimaryHandItem(holder)
            end
        end
        if SandboxVars.MoreTraits.PreparedCarGasToggle then
            local gas = inv:AddItem("Base.PetrolCan")
            if not player:getSecondaryHandItem() then
                player:setSecondaryHandItem(gas)
            end
        end
    elseif player:hasTrait(ToadTraitsRegistries.preparedcoordination) then
        local holder = inv:AddItem("Base.Bag_FannyPackFront")

        local watch = inv:AddItem("Base.WristWatch_Right_DigitalBlack")

        if holder then
            local holderInv = holder:getItemContainer()
            if holderInv then
                local items = {
                    "Base.MuldraughMap",
                    "Base.RosewoodMap",
                    "Base.RiversideMap",
                    "Base.WestpointMap",
                    "Base.MarchRidgeMap",
                    "Base.LouisvilleMap1",
                    "Base.LouisvilleMap2",
                    "Base.LouisvilleMap3",
                    "Base.LouisvilleMap4",
                    "Base.LouisvilleMap5",
                    "Base.LouisvilleMap6",
                    "Base.LouisvilleMap7",
                    "Base.LouisvilleMap8",
                    "Base.LouisvilleMap9",
                    "Base.Pencil",
                    "Base.Eraser",
                }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item)
                end
            end
            if holder and not player:getWornItem(holder:getBodyLocation()) then
                player:setWornItem(holder:getBodyLocation(), holder)
            end
        end
        if watch and not player:getWornItem(watch:getBodyLocation()) then
            player:setWornItem(watch:getBodyLocation(), watch)
        end
    end

    if player:hasTrait(ToadTraitsRegistries.drinker) and SandboxVars.MoreTraits.AlcoholicFreeDrink then
        inv:AddItem("Base.Whiskey")
    end

    if player:hasTrait(CharacterTrait.TAILOR) then
        local holder = inv:AddItem("Base.SewingKit")

        if holder then
            local holderInv = holder:getItemContainer()
            if holderInv then
                local items = { "Base.Scissors", "Base.Needle" }
                for _, item in ipairs(items) do
                    holderInv:AddItem(item)
                end
                for i = 1, 4 do
                    holderInv:AddItem("Base.Thread")
                end
            end
        end
    end

    if player:hasTrait(CharacterTrait.SMOKER) and SandboxVars.MoreTraits.SmokerStart then
        local items = { "Base.CigarettePack", "Base.Lighter" }
        for _, item in ipairs(items) do
            inv:AddItem(item)
        end
    end
end

local function learnAllRecipes(player)
    local recipes = getScriptManager():getAllCraftRecipes()
    local ingenuitveLimit = SandboxVars.MoreTraits.IngenuitiveLimit

    if ingenuitveLimit then
        local unknownRecipes = {}
        local percentToLearn = (SandboxVars.MoreTraits.IngenuitiveLimitAmount or 50) * 0.01

        for i = 0, recipes:size() - 1 do
            local recipe = recipes:get(i)
            if recipe:needToBeLearn() then
                table.insert(unknownRecipes, recipe:getName())
            end
        end

        local totalUnknown = #unknownRecipes
        if totalUnknown > 0 then
            local targetAmount = math.floor(totalUnknown * percentToLearn)
            local learnedCount = 0

            while learnedCount < targetAmount and #unknownRecipes > 0 do
                local randomIndex = ZombRand(1, #unknownRecipes + 1)
                local recipeName = table.remove(unknownRecipes, randomIndex)

                player:learnRecipe(recipeName)
                learnedCount = learnedCount + 1
            end
        end
    else
        for i = 0, recipes:size() - 1 do
            local recipe = recipes:get(i)
            if recipe:needToBeLearn() then
                player:learnRecipe(recipe:getName())
            end
        end
    end
end

local function initStartPerks(player, playerdata)
    local bodyDamage = player:getBodyDamage()
    local damage = 20
    local bandagestrength = 5
    local splintstrength = 0.9
    local fracturetime = 50
    local scratchtimemod = 20
    local bleedtimemod = 10

    if SandboxVars.MoreTraits.LuckImpact then
        luckimpact = SandboxVars.MoreTraits.LuckImpact * 0.01
    end

    MT.InitPlayerData(player, playerdata)

    damage = damage + MT.LuckDelta(player, -5)
    bandagestrength = bandagestrength + MT.LuckDelta(player, 2)
    fracturetime = fracturetime + MT.LuckDelta(player, -5)
    splintstrength = splintstrength + MT.LuckDelta(player, 0.1)
    scratchtimemod = scratchtimemod + MT.LuckDelta(player, -5)
    bleedtimemod = bleedtimemod + MT.LuckDelta(player, -2)

    if player:hasTrait(ToadTraitsRegistries.injured) then
        local TraitInjuredBodyList = playerdata.TraitInjuredBodyList
        local iterations = ZombRand(1, 4) + 1
        local doburns = SandboxVars.MoreTraits.InjuredBurns ~= false

        for i = 1, iterations do
            local randompart = ZombRand(0, 16)
            local b = bodyDamage:getBodyPart(BodyPartType.FromIndex(randompart))

            if b:HasInjury() then
                randompart = ZombRand(0, 16)
                b = bodyDamage:getBodyPart(BodyPartType.FromIndex(randompart))
            end

            if not b:HasInjury() then
                local injury = ZombRand(0, 5)
                b:AddDamage(damage)

                if injury <= 1 then
                    b:setScratched(true, true)
                elseif injury == 2 and doburns then
                    b:setBurned()
                    b:setBurnTime(ZombRand(50) + damage)
                    b:setNeedBurnWash(false)
                elseif injury == 3 then
                    b:setCut(true, true)
                else
                    b:setDeepWounded(true)
                    b:setStitched(true)
                end

                b:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage")
                table.insert(TraitInjuredBodyList, randompart)
            end
        end
        bodyDamage:setInfected(false)
    end

    if player:hasTrait(ToadTraitsRegistries.broke) then
        local leg = bodyDamage:getBodyPart(BodyPartType.LowerLeg_R)
        leg:AddDamage(damage)
        leg:setFractureTime(fracturetime)
        leg:setSplint(true, splintstrength)
        leg:setSplintItem("Base.Splint")
        leg:setBandaged(true, bandagestrength, true, "Base.AlcoholBandage")
        table.insert(playerdata.TraitInjuredBodyList, BodyPartType.ToIndex(BodyPartType.LowerLeg_R))
        bodyDamage:setInfected(false)
    end

    if player:hasTrait(ToadTraitsRegistries.burned) then
        for i = 0, bodyDamage:getBodyParts():size() - 1 do
            local b = bodyDamage:getBodyParts():get(i)
            b:setBurned()
            b:setBurnTime(ZombRand(10, 100) + damage)
            b:setNeedBurnWash(false)
            b:setBandaged(true, ZombRand(1, 10) + bandagestrength, true, "Base.AlcoholBandage")
            table.insert(playerdata.TraitInjuredBodyList, i)
        end
    end

    if player:hasTrait(ToadTraitsRegistries.ingenuitive) then
        learnAllRecipes(player)
        playerdata.IngenuitiveActivated = true
    end

    if player:hasTrait(ToadTraitsRegistries.noxpshooter) then
        MT.LevelPerkByAmount(player, Perks.Aiming, 2)
    end

    if player:hasTrait(ToadTraitsRegistries.noxptechnician) then
        MT.LevelPerkByAmount(player, Perks.Mechanics, 1)
        MT.LevelPerkByAmount(player, Perks.Electricity, 2)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpfirstaid) then
        MT.LevelPerkByAmount(player, Perks.Doctor, 3)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpaxe) then
        MT.LevelPerkByAmount(player, Perks.Axe, 2)
        MT.LevelPerkByAmount(player, Perks.Woodwork, 1)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpmaintenance) then
        MT.LevelPerkByAmount(player, Perks.Maintenance, 2)
    end

    if player:hasTrait(ToadTraitsRegistries.noxpsneaky) then
        MT.LevelPerkByAmount(player, Perks.Sneak, 2)
        MT.LevelPerkByAmount(player, Perks.Lightfoot, 1)
    end

    if player:hasTrait(ToadTraitsRegistries.terminator) then
        MT.LevelPerkByAmount(player, Perks.Aiming, 3)
        MT.LevelPerkByAmount(player, Perks.Reloading, 2)
        MT.LevelPerkByAmount(player, Perks.Nimble, 1)
    end
end

local function onCreatePlayer(playerindex, player)
    if not player then
        return
    end
    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    local wornItems = player:getWornItems()
    for i = wornItems:size() - 1, 0, -1 do
        local item = wornItems:getItemByIndex(i)
        if item:IsClothing() then
            local itemdata = item:getModData()
            itemdata.sState = nil
        end
    end
    MT.InitPlayerData(player, playerdata)
    if not isServer() then
        if PZAPI and PZAPI.ModOptions then
            MT_Config = PZAPI.ModOptions:getOptions("moreTraitsDefinitive")
        end
    end
    if getGameTime():getModData().MTModVersion == nil then
        getGameTime():getModData().MTModVersion = "Before 15 January 2023"
    end
end

local function onInitWorld()
    if getGameTime():getModData().MTModVersion == nil then
        getGameTime():getModData().MTModVersion = MTModVersion
    end
end

local function onNewGame(player)
    if not player then
        return
    end
    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    giveStarterItems(player)
    initStartPerks(player, playerdata)
end

MT.Creation = {
    GiveStarterItems = giveStarterItems,
    LearnAllRecipes = learnAllRecipes,
    InitStartPerks = initStartPerks,
}

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnInitWorld.Add(onInitWorld)
Events.OnNewGame.Add(onNewGame)