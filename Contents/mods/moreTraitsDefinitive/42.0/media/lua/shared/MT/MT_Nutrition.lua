MT = MT or {}

local function SetFoodState(food, state, player)
    local itemdata = food:getModData()
    local curUnhappyChange = food:getUnhappyChange()
    local curBoredomChange = food:getBoredomChange()
    local curHungChange = food:getHungChange()
    local curCookTime = food:getMinutesToCook()
    local curBurnTime = food:getMinutesToBurn()
    local curGoodHot = food:isGoodHot()
    local curBadInMicrowave = food:isBadInMicrowave()
    local curBadCold = food:isBadCold()
    local curDangerousUncooked = food:isbDangerousUncooked()
    local curStressChange = food:getStressChange()
    local curThirstChange = food:getThirstChange()
    local curEndChange = food:getEndChange()
    local curFatChange = food:getFatigueChange()
    local curSpices = tostring(food:getSpices())
    local curState = itemdata.sFoodState
    local curStage = itemdata.iFoodStage

    if curState ~= nil and curHungChange ~= nil then
        local oldHungChange = itemdata.origHungChange
        local oldSpices = itemdata.origSpices
        if curHungChange ~= oldHungChange or curSpices ~= oldSpices then
            curState = nil
        end
    end
    if curState == nil then
        local comparativechange = 0
        if food:isFrozen() == true then
            comparativechange = comparativechange + 30
        end
        if food:isRotten() == true then
            comparativechange = comparativechange + 10
        end
        if food:isFresh() == false then
            comparativechange = comparativechange + 10
        end
        itemdata.origUnhappyChange = curUnhappyChange - comparativechange
        itemdata.origBoredomChange = curBoredomChange - comparativechange
        itemdata.origHungChange = curHungChange
        itemdata.origCookTime = curCookTime
        itemdata.origBurnTime = curBurnTime
        itemdata.origGoodHot = curGoodHot
        itemdata.origBadInMicrowave = curBadInMicrowave
        itemdata.origBadCold = curBadCold
        itemdata.origDangerousUncooked = curDangerousUncooked
        itemdata.origStressChange = curStressChange
        itemdata.origThirstChange = curThirstChange
        itemdata.origEndChange = curEndChange
        itemdata.origFatChange = curFatChange
        itemdata.origSpices = curSpices
        if itemdata.iFoodStage == nil then
            itemdata.iFoodStage = 0
        end
        itemdata.sFoodState = "Normal"
    elseif
    curState == "Gourmand" and player:hasTrait(ToadTraitsRegistries.gourmand) == false
            or curState == "Ascetic" and player:hasTrait(ToadTraitsRegistries.ascetic) == false
    then
        state = "Normal"
    end
    if state == "Gourmand" then
        if food:isIsCookable() == true and food:isCooked() == false and curStage == 0 then
            food:setMinutesToCook(itemdata.origCookTime * 0.5)
            food:setMinutesToBurn(itemdata.origBurnTime * 2)
            itemdata.iFoodStage = 1
        end

        if food:isCooked() == true and food:isRotten() == false and curStage ~= 2 then
            local food_happy = itemdata.origUnhappyChange
            local food_bored = itemdata.origBoredomChange
            local food_hunger = itemdata.origHungChange
            local food_thirst = itemdata.origThirstChange
            local food_end = itemdata.origEndChange
            local food_stress = itemdata.origStressChange
            local food_fatigue = itemdata.origFatChange
            if food_happy >= 0 then
                food_happy = 0
            else
                food_happy = food_happy * 1.5
            end
            if food_bored >= 0 then
                food_bored = 0
            else
                food_bored = food_bored * 1.5
            end
            if food_thirst >= 0 then
                food_thirst = food_thirst * 0.5
            else
                food_thirst = food_thirst * 1.5
            end
            if food_end >= 0 then
                food_end = -5
            else
                food_end = food_end * 1.5
            end
            if food_stress >= 0 then
                food_stress = -10
            else
                food_stress = food_stress * 1.5
            end
            if food_fatigue >= 0 then
                food_fatigue = -5
            else
                food_fatigue = food_fatigue * 1.5
            end
            food_hunger = food_hunger * 1.5
            food:setThirstChange(food_thirst)
            food:setUnhappyChange(food_happy)
            food:setBoredomChange(food_bored)
            food:setHungChange(food_hunger)
            food:setGoodHot(false)
            food:setBadInMicrowave(false)
            food:setBadCold(false)
            food:setAge(0)
            food:updateAge()
            itemdata.iFoodStage = 2
            food:update()
        end
        itemdata.sFoodState = "Gourmand"
    elseif state == "Normal" then
        food:setUnhappyChange(itemdata.origUnhappyChange)
        food:setBoredomChange(itemdata.origBoredomChange)
        food:setHungChange(itemdata.origHungChange)
        food:setMinutesToCook(itemdata.origCookTime)
        food:setMinutesToBurn(itemdata.origBurnTime)
        food:setBadInMicrowave(itemdata.origBadInMicrowave)
        food:setGoodHot(itemdata.origGoodHot)
        food:setBadCold(itemdata.origBadCold)
        food:setbDangerousUncooked(itemdata.origDangerousUncooked)
        food:setEndChange(itemdata.origEndChange)
        food:setStressChange(itemdata.origStressChange)
        food:setThirstChange(itemdata.origThirstChange)
        food:setFatigueChange(itemdata.origFatChange)
        if itemdata.iFoodStage == nil then
            itemdata.iFoodStage = 0
        end
        itemdata.sFoodState = "Normal"
    elseif state == "Ascetic" then
        if food:isIsCookable() == true and food:isCooked() == false and curStage == 0 then
            local cookTime = itemdata.origCookTime
            food:setMinutesToCook(cookTime * 1.5)
            food:setMinutesToBurn((cookTime * 1.5) + ((itemdata.origBurnTime - cookTime) * 0.5))
            food:setUnhappyChange(0)
            food:setBoredomChange(0)
            food:setGoodHot(false)
            food:setBadCold(false)
            itemdata.iFoodStage = 1
        end
        if food:isPackaged() == true then
            local food_happy = itemdata.origUnhappyChange
            local food_bored = itemdata.origBoredomChange
            local food_end = itemdata.origEndChange
            local food_stress = itemdata.origStressChange
            if food_happy < 0 then
                food:setUnhappyChange(0)
            end
            if food_bored < 0 then
                food:setBoredomChange(0)
            end
            if food_end < 0 then
                food:setEndChange(0)
            end
            if food_stress < 0 then
                food:setStressChange(0)
            end
        end
        if food:isCooked() == true and food:isRotten() == false and curStage ~= 2 then
            local food_happy = itemdata.origUnhappyChange
            local food_bored = itemdata.origBoredomChange
            local food_hunger = itemdata.origHungChange
            local food_thirst = itemdata.origThirstChange
            local food_end = itemdata.origEndChange
            local food_stress = itemdata.origStressChange
            if food_happy >= 0 then
                food_happy = -10
            else
                food_happy = food_happy * -1
            end
            if food_bored >= 0 then
                food_bored = -10
            else
                food_bored = food_bored * -1
            end
            if food_thirst >= 0 then
                food_thirst = food_thirst * 2
            else
                food_thirst = -10
            end
            if food_end >= 0 then
                food_end = food_end * 2
            else
                food_end = 10
            end
            if food_stress >= 0 then
                food_stress = food_stress * 2
            else
                food_stress = 10
            end
            food_hunger = food_hunger * 0.75
            food:setUnhappyChange(food_happy)
            food:setBoredomChange(food_bored)
            food:setHungChange(food_hunger)
            food:setGoodHot(itemdata.origGoodHot)
            food:setBadInMicrowave(itemdata.origBadInMicrowave)
            food:setBadCold(itemdata.origBadCold)
            food:setEndChange(food_end)
            food:setStressChange(food_stress)
            food:update()
            itemdata.iFoodStage = 2
        end
        itemdata.sFoodState = "Ascetic"
    end
end

local function FoodUpdate(player)
    local plyinv = player:getInventory()
    local items = plyinv:getItems()
    local itemCount = items:size()

    local state = "Normal"
    if player:hasTrait(ToadTraitsRegistries.gourmand) then
        state = "Gourmand"
    elseif player:hasTrait(ToadTraitsRegistries.ascetic) then
        state = "Ascetic"
    end

    for i = 0, itemCount - 1 do
        local item = items:get(i)
        if item and item:getCategory() == "Food" then
            SetFoodState(item, state, player)
        end
    end
end

local function IdealWeight(player, playerdata)
    if not player:hasTrait(ToadTraitsRegistries.idealweight) then
        return
    end

    local nutrition = player:getNutrition()
    local currentCalories = nutrition:getCalories()
    local weight = nutrition:getWeight()

    if playerdata.OldCalories == nil then
        playerdata.OldCalories = currentCalories
        return
    end

    local oldCalories = playerdata.OldCalories

    if currentCalories > oldCalories then
        local caloriesChange = currentCalories - oldCalories

        if weight <= 78 then
            nutrition:setCalories(currentCalories + (caloriesChange * 0.5))
        elseif weight >= 82 then
            nutrition:setCalories(currentCalories - (caloriesChange * 0.25))
        end
    end

    playerdata.OldCalories = nutrition:getCalories()
end

MT.Nutrition = {
    SetFoodState = SetFoodState,
    FoodUpdate = FoodUpdate,
    IdealWeight = IdealWeight,
}

return MT