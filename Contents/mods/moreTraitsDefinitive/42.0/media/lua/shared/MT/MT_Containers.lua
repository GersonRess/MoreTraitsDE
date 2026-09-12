MT = MT or {}

local function Scrounger(page, player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.scrounger) then
        return
    end

    local modifier = 1.0 + (SandboxVars.MoreTraits.ScroungerLootModifier or 30) * 0.01
    local baseChance = SandboxVars.MoreTraits.ScroungerItemChance or 10

    modifier = modifier + MT.LuckDelta(player, 0.1)
    baseChance = baseChance + MT.LuckDelta(player, 5)

    for _, v in ipairs(page.backpacks) do
        local inventory = v.inventory
        local containerObj = inventory:getParent()

        if containerObj and inventory:getType() ~= "floor" then
            local modData = containerObj:getModData()

            if
            not modData.bScroungerorIncomprehensiveRolled
                    and instanceof(containerObj, "IsoObject")
                    and not instanceof(containerObj, "IsoDeadBody")
            then
                modData.bScroungerorIncomprehensiveRolled = true
                containerObj:transmitModData()

                if playerdata.ContainerTraitIllegal then
                    playerdata.ContainerTraitIllegal = false
                    return
                end

                if ZombRand(100) <= baseChance then
                    local items = inventory:getItems()
                    if not items or items:isEmpty() then
                        return
                    end

                    local processedItems = {}
                    local itemsToSpawn = {}

                    for i = 0, items:size() - 1 do
                        local item = items:get(i)
                        local fullType = item:getFullType()

                        if not processedItems[fullType] then
                            processedItems[fullType] = true
                            local count = inventory:getNumberOfItem(fullType)

                            if fullType == "Base.CigaretteSingle" or fullType == "Base.Nails" then
                                count = math.floor(count / 20)
                            end

                            local currentItemChance = baseChance
                            if item:getCategory() == "Food" or item:IsDrainable() then
                                currentItemChance = currentItemChance + 10
                            elseif item:IsWeapon() then
                                currentItemChance = currentItemChance + 5
                            end

                            local n = 0
                            if count == 1 then
                                if ZombRand(100) <= currentItemChance then
                                    n = 1
                                end
                            elseif count > 1 and count < 5 then
                                n = math.floor(count * modifier)
                            elseif count >= 5 then
                                n = math.floor((count * modifier) * 2)
                            end

                            if n > 0 then
                                for j = 1, n do
                                    if isClient() then
                                        table.insert(itemsToSpawn, fullType)
                                    else
                                        inventory:AddItem(fullType)
                                    end
                                end

                                MT.Announce(player, "ScroungerAnnounce", getText("UI_trait_scrounger") .. ": " .. item:getName(), true, HaloTextHelper.getColorGreen())
                            end
                        end
                    end

                    if isClient() and #itemsToSpawn > 0 then
                    MT.RequestContainerLoot(player, containerObj, "Scrounger", itemsToSpawn)
                end
                end
            end
        end
    end
end

local function UnHighlightScrounger(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.scrounger) then
        return
    end

    local highlight = false
    local highlightTime = 1

    if not isServer() and MT_Config then
        highlight = MT_Config:getOption("ScroungerHighlight"):getValue()
        highlightTime = MT_Config:getOption("ScroungerHighlightTime"):getValue()
    end

    if not isServer() and not highlight then
        return
    end

    playerdata.scroungerHighlightsTbl = playerdata.scroungerHighlightsTbl or {}
    local highlights = playerdata.scroungerHighlightsTbl
    local maxTime = highlightTime * 10

    local remove = {}
    for containerObj, timer in pairs(highlights) do
        if timer >= maxTime then
            containerObj:setHighlighted(false)
            table.insert(remove, containerObj)
        else
            highlights[containerObj] = timer + 1
        end
    end
end

local function Incomprehensive(page, player)
    if not player:hasTrait(ToadTraitsRegistries.incomprehensive) then
        return
    end

    local baseChance = SandboxVars.MoreTraits.IncomprehensiveChance or 10

    baseChance = baseChance + MT.LuckDelta(player, -5)

    for _, v in ipairs(page.backpacks) do
        local inventory = v.inventory
        local containerObj = inventory:getParent()

        if containerObj and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") then
            local modData = containerObj:getModData()

            if not modData.bScroungerorIncomprehensiveRolled and containerObj:getContainer() then
                modData.bScroungerorIncomprehensiveRolled = true
                containerObj:transmitModData()

                if ZombRand(100) <= baseChance then
                    local container = containerObj:getContainer()
                    local items = container:getItems()
                    local processedItems = {}
                    local itemsToRemove = {}

                    for i = 0, items:size() - 1 do
                        local item = items:get(i)
                        if item then
                            local fullType = item:getFullType()

                            if not processedItems[fullType] then
                                processedItems[fullType] = true

                                local count = container:getNumberOfItem(fullType)
                                if fullType == "Base.CigaretteSingle" or fullType == "Base.Nails" then
                                    count = math.floor(count / 20)
                                end

                                local removeCount = 0
                                if count == 1 then
                                    local bChance = 5 + MT.LuckDelta(player, -5)

                                    if item:IsFood() or item:IsDrainable() then
                                        bChance = bChance + 10
                                    end
                                    if item:IsWeapon() then
                                        bChance = bChance + 5
                                    end

                                    if ZombRand(100) <= bChance then
                                        removeCount = 1
                                    end
                                elseif count > 1 then
                                    removeCount = 1
                                    if count >= 5 then
                                        removeCount = 2
                                    end
                                end

                                if removeCount > 0 then
                                    for j = 1, removeCount do
                                        table.insert(itemsToRemove, fullType)
                                    end

                                    MT.Announce(player, "ScroungerAnnounce", getText("UI_trait_incomprehensive") .. " : " .. item:getName(), false, HaloTextHelper.getColorRed())
                                end
                            end
                        end
                    end

                    if #itemsToRemove > 0 then
                        if isClient() then
                            MT.RequestContainerLoot(player, containerObj, "Incomprehensive", itemsToRemove)
                        else
                            for _, type in ipairs(itemsToRemove) do
                                local itemObj = container:FindAndReturn(type)
                                if itemObj then
                                    container:Remove(itemObj)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function Antique(page, player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.antique) then
        return
    end

    local HoursForLootRespawn = SandboxVars.HoursForLootRespawn or 0
    local AllowRespawn = HoursForLootRespawn > 0

    local baseChance = 10
    local roll = SandboxVars.MoreTraits.AntiqueChance or 1500

    baseChance = baseChance + MT.LuckDelta(player, 1)
    if player:hasTrait(CharacterTrait.DEXTROUS) then
        baseChance = baseChance + 1
    end
    if player:hasTrait(CharacterTrait.ALL_THUMBS) then
        baseChance = baseChance - 1
    end
    if player:hasTrait(ToadTraitsRegistries.scrounger) then
        baseChance = baseChance + 1
    end
    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then
        baseChance = baseChance - 1
    end
    if baseChance < 1 then
        baseChance = 1
    end

    local worldAgeHours = GameTime:getInstance():getWorldAgeHours()

    for _, v in ipairs(page.backpacks) do
        local inv = v.inventory
        if inv and inv:getParent() then
            local containerObj = inv:getParent()
            local modData = containerObj:getModData()

            if
            instanceof(containerObj, "IsoObject")
                    and not instanceof(containerObj, "IsoDeadBody")
                    and containerObj:getContainer()
            then
                local shouldRoll = false

                if not modData.bAntiqueRolled then
                    modData.bAntiqueRolled = true
                    modData.bHoursWhenChecked = worldAgeHours
                    modData.AllowRespawn = true
                    containerObj:transmitModData()
                    shouldRoll = true
                elseif AllowRespawn and modData.AllowRespawn and modData.bAntiqueRolled then
                    local container = containerObj:getContainer()
                    if container:isHasBeenLooted()
                        and (modData.bHoursWhenChecked + HoursForLootRespawn) <= worldAgeHours then
                        local maxItems = SandboxVars.MaxItemsForLootRespawn or 5
                        if not container:getItems() or container:getItems():size() < maxItems then
                            modData.bHoursWhenChecked = worldAgeHours
                            containerObj:transmitModData()
                            shouldRoll = true
                        end
                    end
                end

                if shouldRoll then
                    if playerdata.ContainerTraitIllegal then
                        playerdata.ContainerTraitIllegal = false
                        if AllowRespawn then
                            modData.AllowRespawn = false
                            containerObj:transmitModData()
                        end
                        return
                    end

                    local container = containerObj:getContainer()
                    local type = container:getType()
                    local isAllowedType = (type == "crate" or type == "metal_shelves")
                    local isAnywhere = SandboxVars.MoreTraits.AntiqueAnywhere == true

                    if (isAllowedType or isAnywhere) and ZombRand(roll) <= baseChance then
                        local antiqueItemsList = {
                            "MoreTraits.AntiqueAxe",
                            "MoreTraits.Thumper",
                            "MoreTraits.ObsidianBlade",
                            "MoreTraits.Bag_PackerBag",
                            "MoreTraits.BloodyCrowbar",
                            "MoreTraits.Slugger",
                            "MoreTraits.AntiqueJacket",
                            "MoreTraits.AntiqueVest",
                            "MoreTraits.AntiqueBoots",
                            "MoreTraits.AntiqueSpear",
                            "MoreTraits.AntiqueHammer",
                            "MoreTraits.AntiqueKatana",
                            "MoreTraits.AntiqueMag1",
                            "MoreTraits.AntiqueMag2",
                            "MoreTraits.AntiqueMag3",
                        }

                        local itemType = antiqueItemsList[ZombRand(#antiqueItemsList) + 1]
                        if isClient() then
                            MT.RequestContainerLoot(player, containerObj, "Antique", { itemType })
                        else
                            container:AddItem(itemType)
                        end
                    end
                end
            end
        end
    end
end

local function Vagabond(page, player)
    if not player:hasTrait(ToadTraitsRegistries.vagabond) then
        return
    end

    local baseChance = SandboxVars.MoreTraits.VagabondChance or 33
    baseChance = baseChance + MT.LuckDelta(player, 5)

    for _, v in ipairs(page.backpacks) do
        local inv = v.inventory
        if inv and inv:getParent() then
            local containerObj = inv:getParent()
            local modData = containerObj:getModData()

            if
            not modData.bVagbondRolled
                    and instanceof(containerObj, "IsoObject")
                    and not instanceof(containerObj, "IsoDeadBody")
                    and containerObj:getContainer()
            then
                local container = containerObj:getContainer()
                if container:getType() == "bin" then
                    modData.bVagbondRolled = true
                    containerObj:transmitModData()

                    local extra = SandboxVars.MoreTraits.VagabondGuaranteedExtraLoot or 1
                    local iterations = ZombRand(0, 3) + extra
                    local itemsFound = {}

                    local vagabondItems = {
                        "Base.BreadSlices",
                        "Base.Pizza",
                        "Base.Hotdog",
                        "Base.Corndog",
                        "Base.OpenBeans",
                        "Base.CannedChiliOpen",
                        "Base.WatermelonSmashed",
                        "Base.DogfoodOpen",
                        "Base.CannedCornedBeefOpen",
                        "Base.CannedBologneseOpen",
                        "Base.CannedCarrotsOpen",
                        "Base.CannedCornOpen",
                        "Base.CannedMushroomSoupOpen",
                        "Base.CannedPeasOpen",
                        "Base.CannedPotatoOpen",
                        "Base.CannedSardinesOpen",
                        "Base.CannedTomatoOpen",
                        "Base.TinnedSoupOpen",
                        "Base.TunaTinOpen",
                        "Base.CannedFruitCocktailOpen",
                        "Base.CannedPeachesOpen",
                        "Base.CannedPineappleOpen",
                        "Base.MushroomGeneric1",
                        "Base.MushroomGeneric2",
                        "Base.MushroomGeneric3",
                        "Base.MushroomGeneric4",
                        "Base.MushroomGeneric5",
                        "Base.MushroomGeneric6",
                        "Base.MushroomGeneric7",
                    }

                    for i = 1, iterations do
                        if ZombRand(100) <= baseChance then
                            local itemType = vagabondItems[ZombRand(#vagabondItems) + 1]
                            local itemName = getScriptManager():getItem(itemType):getDisplayName()

                            if isClient() then
                                table.insert(itemsFound, itemType)
                            else
                                container:AddItem(itemType)
                            end

                            if itemName then
                                MT.Announce(player, "VagabondAnnounce", getText("UI_trait_vagabond") .. " : " .. itemName, true, HaloTextHelper.getColorGreen())
                            end
                        end
                    end

                    if isClient() and #itemsFound > 0 then
                        MT.RequestContainerLoot(player, containerObj, "Vagabond", itemsFound)
                    end
                end
            end
        end
    end
end

local function GraveRobber(page, player)
    if not player or not player:hasTrait(ToadTraitsRegistries.graverobber) then
        return
    end

    for _, v in ipairs(page.backpacks) do
        local inv = v.inventory
        if inv and inv:getParent() then
            local containerObj = inv:getParent()

            if instanceof(containerObj, "IsoDeadBody") then
                local modData = containerObj:getModData()

                if not modData.bGraveRobberRolled then
                    modData.bGraveRobberRolled = true
                    containerObj:transmitModData()

                    local sandboxChance = SandboxVars.MoreTraits.GraveRobberChance or 1.0
                    local chance = sandboxChance * 10

                    chance = chance + MT.LuckDelta(player, 2)
                    if player:hasTrait(ToadTraitsRegistries.scrounger) then
                        chance = chance + 2
                    end
                    if player:hasTrait(ToadTraitsRegistries.incomprehensive) then
                        chance = chance - 2
                    end

                    chance = math.max(1, chance)

                    if ZombRand(0, 1001) <= chance then
                        local itemsFound = {}
                        local graveRobberLootTable = {
                            {
                                chance = 10,
                                items = {
                                    "Base.Apple",
                                    "Base.Avocado",
                                    "Base.Banana",
                                    "Base.BellPepper",
                                    "Base.BeerCan",
                                    "Base.BeefJerky",
                                    "Base.Bread",
                                    "Base.Broccoli",
                                    "Base.Butter",
                                    "Base.CandyPackage",
                                    "Base.TinnedBeans",
                                    "Base.CannedCarrots2",
                                    "Base.CannedChili",
                                    "Base.CannedCorn",
                                    "Base.CannedCornedBeef",
                                    "Base.CannedMushroomSoup",
                                    "Base.CannedPeas",
                                    "Base.CannedPotato2",
                                    "Base.CannedSardines",
                                    "Base.CannedTomato2",
                                    "Base.TunaTin",
                                },
                            },
                            {
                                chance = 20,
                                items = {
                                    "Base.PillsAntiDep",
                                    "Base.AlcoholWipes",
                                    "Base.AlcoholedCottonBalls",
                                    "Base.Pills",
                                    "Base.PillsSleepingTablets",
                                    "Base.Tissue",
                                    "Base.ToiletPaper",
                                    "Base.PillsVitamins",
                                    "Base.Bandaid",
                                    "Base.Bandage",
                                    "Base.CottonBalls",
                                    "Base.Splint",
                                    "Base.AlcoholBandage",
                                    "Base.AlcoholRippedSheets",
                                    "Base.SutureNeedle",
                                    "Base.Tweezers",
                                    "Base.WildGarlicCataplasm",
                                    "Base.ComfreyCataplasm",
                                    "Base.PlantainCataplasm",
                                    "Base.Disinfectant",
                                },
                            },
                            {
                                chance = 30,
                                items = {
                                    "Base.223Box",
                                    "Base.308Box",
                                    "Base.Bullets38Box",
                                    "Base.Bullets44Box",
                                    "Base.Bullets45Box",
                                    "Base.556Box",
                                    "Base.Bullets9mmBox",
                                    "Base.ShotgunShellsBox",
                                    "Base.DoubleBarrelShotgun",
                                    "Base.Shotgun",
                                    "Base.ShotgunSawnoff",
                                    "Base.Pistol",
                                    "Base.Pistol2",
                                    "Base.Pistol3",
                                    "Base.AssaultRifle",
                                    "Base.AssaultRifle2",
                                    "Base.VarmintRifle",
                                    "Base.HuntingRifle",
                                    "Base.556Clip",
                                    "Base.M14Clip",
                                    "Base.308Clip",
                                    "Base.223Clip",
                                    "Base.44Clip",
                                    "Base.45Clip",
                                    "Base.9mmClip",
                                    "Base.Revolver_Short",
                                    "Base.Revolver_Long",
                                    "Base.Revolver",
                                },
                            },
                            {
                                chance = 40,
                                items = {
                                    "Base.Aerosolbomb",
                                    "Base.Axe",
                                    "Base.BaseballBat",
                                    "Base.SpearCrafted",
                                    "Base.Crowbar",
                                    "Base.FlameTrap",
                                    "Base.HandAxe",
                                    "Base.HuntingKnife",
                                    "Base.Katana",
                                    "Base.PipeBomb",
                                    "Base.Sledgehammer",
                                    "Base.Shovel",
                                    "Base.SmokeBomb",
                                    "Base.WoodAxe",
                                    "Base.GardenFork",
                                    "Base.WoodenLance",
                                    "Base.SpearBreadKnife",
                                    "Base.SpearButterKnife",
                                    "Base.SpearFork",
                                    "Base.SpearLetterOpener",
                                    "Base.SpearScalpel",
                                    "Base.SpearSpoon",
                                    "Base.SpearScissors",
                                    "Base.SpearHandFork",
                                    "Base.SpearScrewdriver",
                                    "Base.SpearHuntingKnife",
                                    "Base.SpearMachete",
                                    "Base.SpearIcePick",
                                    "Base.SpearKnife",
                                    "Base.Machete",
                                    "Base.GardenHoe",
                                },
                            },
                            {
                                chance = 50,
                                items = {
                                    "Base.Bag_SurvivorBag",
                                    "Base.Bag_BigHikingBag",
                                    "Base.Bag_DuffelBag",
                                    "Base.Bag_FannyPackFront",
                                    "Base.Bag_NormalHikingBag",
                                    "Base.Bag_ALICEpack",
                                    "Base.Bag_ALICEpack_Army",
                                    "Base.Bag_Schoolbag",
                                    "Base.SackOnions",
                                    "Base.SackPotatoes",
                                    "Base.SackCarrots",
                                    "Base.SackCabbages",
                                },
                            },
                            {
                                chance = 60,
                                items = {
                                    "Base.Hat_SPHhelmet",
                                    "Base.Jacket_CoatArmy",
                                    "Base.Hat_BalaclavaFull",
                                    "Base.Hat_BicycleHelmet",
                                    "Base.Shoes_BlackBoots",
                                    "Base.Hat_CrashHelmet",
                                    "Base.HolsterDouble",
                                    "Base.Hat_Fireman",
                                    "Base.Jacket_Fireman",
                                    "Base.Trousers_Fireman",
                                    "Base.Hat_FootballHelmet",
                                    "Base.Hat_GasMask",
                                    "Base.Ghillie_Trousers",
                                    "Base.Ghillie_Top",
                                    "Base.Gloves_LeatherGloves",
                                    "Base.JacketLong_Random",
                                    "Base.Shoes_ArmyBoots",
                                    "Base.Vest_BulletArmy",
                                    "Base.Hat_Army",
                                    "Base.Hat_HardHat_Miner",
                                    "Base.Hat_NBCmask",
                                    "Base.Vest_BulletPolice",
                                    "Base.Hat_RiotHelmet",
                                    "Base.AmmoStrap_Shells",
                                },
                            },
                            {
                                chance = 70,
                                items = {
                                    "Base.CarBattery1",
                                    "Base.CarBattery2",
                                    "Base.CarBattery3",
                                    "Base.Extinguisher",
                                    "Base.PetrolCan",
                                    "Base.ConcretePowder",
                                    "Base.PlasterPowder",
                                    "Base.BarbedWire",
                                    "Base.Log",
                                    "Base.SheetMetal",
                                    "Base.MotionSensor",
                                    "Base.ModernTire1",
                                    "Base.ModernTire2",
                                    "Base.ModernTire3",
                                    "Base.ModernSuspension1",
                                    "Base.ModernSuspension2",
                                    "Base.ModernSuspension3",
                                    "Base.ModernCarMuffler1",
                                    "Base.ModernCarMuffler2",
                                    "Base.ModernCarMuffler3",
                                    "Base.ModernBrake1",
                                    "Base.ModernBrake2",
                                    "Base.ModernBrake3",
                                    "Base.smallSheetMetal",
                                    "Base.Speaker",
                                    "Base.EngineParts",
                                    "Base.LogStacks2",
                                    "Base.LogStacks3",
                                    "Base.LogStacks4",
                                    "Base.NailsBox",
                                },
                            },
                            {
                                chance = 80,
                                items = {
                                    "Base.ComicBook",
                                    "Base.ElectronicsMag4",
                                    "Base.HerbalistMag",
                                    "Base.MetalworkMag1",
                                    "Base.MetalworkMag2",
                                    "Base.MetalworkMag3",
                                    "Base.MetalworkMag4",
                                    "Base.HuntingMag1",
                                    "Base.HuntingMag2",
                                    "Base.HuntingMag3",
                                    "Base.FarmingMag1",
                                    "Base.MechanicMag1",
                                    "Base.MechanicMag2",
                                    "Base.MechanicMag3",
                                    "Base.CookingMag1",
                                    "Base.CookingMag2",
                                    "Base.EngineerMagazine1",
                                    "Base.EngineerMagazine2",
                                    "Base.ElectronicsMag1",
                                    "Base.ElectronicsMag2",
                                    "Base.ElectronicsMag3",
                                    "Base.ElectronicsMag5",
                                    "Base.FishingMag1",
                                    "Base.FishingMag2",
                                    "Base.Book",
                                    "MoreTraits.MedicalMag1",
                                    "MoreTraits.MedicalMag2",
                                    "MoreTraits.MedicalMag3",
                                    "MoreTraits.MedicalMag4",
                                    "MoreTraits.AntiqueMag1",
                                    "MoreTraits.AntiqueMag2",
                                    "MoreTraits.AntiqueMag3",
                                },
                            },
                            {
                                chance = 90,
                                items = {
                                    "Base.DumbBell",
                                    "Base.EggCarton",
                                    "Base.HomeAlarm",
                                    "Base.HotDog",
                                    "Base.HottieZ",
                                    "Base.Icecream",
                                    "Base.Machete",
                                    "Base.Revolver_Long",
                                    "Base.MeatPatty",
                                    "Base.Milk",
                                    "Base.MuttonChop",
                                    "Base.Padlock",
                                    "Base.PorkChop",
                                    "Base.Wine",
                                    "Base.Wine2",
                                    "Base.Whiskey",
                                    "Base.Ham",
                                },
                            },
                            {
                                chance = 95,
                                items = {
                                    "Base.PropaneTank",
                                    "Base.BlowTorch",
                                    "Base.Woodglue",
                                    "Base.DuctTape",
                                    "Base.Rope",
                                    "Base.Extinguisher",
                                },
                            },
                            {
                                chance = 100,
                                items = {
                                    "Base.Spiffo",
                                    "Base.SpiffoSuit",
                                    "Base.Hat_Spiffo",
                                    "Base.SpiffoTail",
                                    "Base.Generator",
                                },
                            },
                        }

                        local extra = SandboxVars.MoreTraits.GraveRobberGuaranteedLoot or 1
                        local iterations = ZombRand(0, 3) + extra

                        for i = 1, iterations do
                            local roll = ZombRand(0, 101)
                            for _, entry in ipairs(graveRobberLootTable) do
                                if roll <= entry.chance then
                                    local itemType = entry.items[ZombRand(#entry.items) + 1]
                                    table.insert(itemsFound, itemType)
                                    break
                                end
                            end
                        end

                        if #itemsFound > 0 then
                            MT.Announce(player, "GraveRobberAnnounce", getText("UI_trait_graverobber"), true, HaloTextHelper.getColorGreen())

                            if isClient() then
                                MT.RequestContainerLoot(player, containerObj, "GraveRobber", itemsFound)
                            else
                                local bodyInv = containerObj:getContainer()
                                for _, itemType in ipairs(itemsFound) do
                                    bodyInv:AddItem(itemType)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function Gourmand(page, player)
    if not player:hasTrait(ToadTraitsRegistries.gourmand) then
        return
    end

    local baseChance = 33 + MT.LuckDelta(player, 10)

    for _, v in ipairs(page.backpacks) do
        local inventory = v.inventory
        local containerObj = inventory:getParent()

        if containerObj and instanceof(containerObj, "IsoObject") and not instanceof(containerObj, "IsoDeadBody") then
            local modData = containerObj:getModData()

            if not modData.bGourmandRolled and containerObj:getContainer() then
                modData.bGourmandRolled = true
                containerObj:transmitModData()

                local container = containerObj:getContainer()
                local items = container:getItems()
                local itemsToSwap = {}

                for l = 0, items:size() - 1 do
                    local item = items:get(l)
                    if item and item:getCategory() == "Food" and (item:isRotten() or not item:isFresh()) then
                        if ZombRand(100) < baseChance then
                            table.insert(itemsToSwap, item:getFullType())

                            MT.Announce(player, "GourmandAnnounce", getText("UI_trait_gourmand") .. ": " .. item:getName(), true, HaloTextHelper.getColorGreen())
                        end
                    end
                end

                if #itemsToSwap > 0 then
                    if isClient() then
                        MT.RequestContainerLoot(player, containerObj, "Gourmand", itemsToSwap)
                    else
                        for _, fullType in ipairs(itemsToSwap) do
                            local oldItem = container:FindAndReturn(fullType)
                            if oldItem then
                                container:Remove(oldItem)
                                container:AddItem(fullType)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function ContainerEvents(iSInventoryPage, state)
    local page = iSInventoryPage
    if state == "end" then
        local player = getPlayer()
        if not player then
            return
        end
        local playerdata = player:getModData()
        if not playerdata then
            return
        end

        Incomprehensive(page, player)
        Scrounger(page, player, playerdata)
        Vagabond(page, player)
        Gourmand(page, player)
        Antique(page, player, playerdata)
        GraveRobber(page, player)
    end
end

MT.Containers = {
    ContainerEvents = ContainerEvents,
    Scrounger = Scrounger,
    UnHighlightScrounger = UnHighlightScrounger,
    Incomprehensive = Incomprehensive,
    Antique = Antique,
    Vagabond = Vagabond,
    GraveRobber = GraveRobber,
    Gourmand = Gourmand,
}

return MT