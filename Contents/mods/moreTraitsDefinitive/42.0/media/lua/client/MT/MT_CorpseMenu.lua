require "TimedActions/MT_ConvertCorpseAction";

MT_CorpseRecipes = {
    ["Mince Corpse into Fertilizer"] = true,
    ["Extract Propane From Corpse"] = true,
};

local MTCorpseTip = nil

local function getCorpseTip()
    if MTCorpseTip == nil then
        MTCorpseTip = ISToolTip:new()
        MTCorpseTip:initialise()
        MTCorpseTip:noBackground()
        MTCorpseTip:setVisible(false)
        MTCorpseTip.followMouse = true
    end
    return MTCorpseTip
end

local function showCorpseTip(menu, lines)
    local toolTip = getCorpseTip()
    toolTip:setName(getText("UI_corpseconvert_missing"))
    toolTip.description = table.concat(lines, "\n")
    toolTip.owner = menu
    toolTip:setVisible(true)
    toolTip:addToUIManager()
end

local function hideCorpseTip()
    if MTCorpseTip == nil then return end
    MTCorpseTip:setVisible(false)
    MTCorpseTip:removeFromUIManager()
    MTCorpseTip.owner = nil
end

local function onHighlightWorldItem(_option, _menu, _isHighlighted, _object)
    local player = getSpecificPlayer(_menu.player)
    if player == nil then return end
    local color = getCore():getWorldItemHighlightColor()
    _object:setHighlighted(_menu.player, _isHighlighted, false)
    _object:setHighlightColor(_menu.player, color)
    _object:setOutlineHighlight(_menu.player, _isHighlighted)
    _object:setOutlineHighlightCol(_menu.player, color)
    ISInventoryPage.OnObjectHighlighted(_menu.player, _object, _isHighlighted)
    if _option.MTMissingLines then
        if _isHighlighted then
            showCorpseTip(_menu, _option.MTMissingLines)
        else
            hideCorpseTip()
        end
    end
end

local function initHighlight(option, object)
    option.onHighlightParams = { object }
    option.onHighlight = onHighlightWorldItem
end

local function collectCorpses(playerObj)
    local corpses = {}
    local square = playerObj:getCurrentSquare()
    if square == nil then return corpses end
    local candidates = {}
    local list = square:getStaticMovingObjects()
    for i = 1, list:size() do
        table.insert(candidates, list:get(i - 1))
    end
    for d = 1, 8 do
        local adj = square:getAdjacentSquare(IsoDirections.fromIndex(d - 1))
        if adj then
            list = adj:getStaticMovingObjects()
            for i = 1, list:size() do
                table.insert(candidates, list:get(i - 1))
            end
        end
    end
    for _, obj in ipairs(candidates) do
        if instanceof(obj, "IsoDeadBody") and not obj:isAnimal() then
            table.insert(corpses, obj)
        end
    end
    table.sort(corpses, function(a, b)
        return a:DistToSquared(playerObj) < b:DistToSquared(playerObj)
    end)
    return corpses
end

local function onConvertCorpse(worldobjects, corpseBody, recipe)
    local playerObj = getPlayer()
    if playerObj == nil or corpseBody == nil then return end
    if playerObj:isSitOnGround() then
        playerObj:setVariable("forceGetUp", true)
    end
    local known = playerObj:getKnownRecipes()
    if known == nil or not known:contains(recipe) then return end
    ISTimedActionQueue.add(ISPathFindAction:pathToGrabCorpse(playerObj, corpseBody))
    if playerObj:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getPrimaryHandItem(), 50))
    end
    if playerObj:getSecondaryHandItem() and playerObj:getSecondaryHandItem() ~= playerObj:getPrimaryHandItem() then
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, playerObj:getSecondaryHandItem(), 50))
    end
    ISTimedActionQueue.add(MTConvertCorpseAction:new(playerObj, corpseBody, recipe))
end

local function addMissingToolTip(opt, missing)
    if not opt or #missing == 0 then return end
    local lines = {}
    for _, key in ipairs(missing) do
        table.insert(lines, getText(key))
    end
    opt.MTMissingLines = lines
end

local function addCorpseConvertSubmenu(playerObj, context, worldobjects)
    local known = playerObj:getKnownRecipes()
    if known == nil then return false end
    local anyKnown = false
    for recipe in pairs(MT_CorpseRecipes) do
        if known:contains(recipe) then
            anyKnown = true
            break
        end
    end
    if not anyKnown then return false end

    local corpses = collectCorpses(playerObj)
    if #corpses == 0 then return false end

    local subOption = context:addOption(getText("UI_antiquecorpseconvert"))
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(subOption, subMenu)

    for _, corpse in ipairs(corpses) do
        local corpseOption = subMenu:addOption(getText("IGUI_ItemCat_Corpse"))
        local corpseMenu = ISContextMenu:getNew(subMenu)
        subMenu:addSubMenu(corpseOption, corpseMenu)
        if ContainerButtonIcons then
            corpseOption.iconTexture = corpse:isFemale() and ContainerButtonIcons.inventoryfemale or ContainerButtonIcons.inventorymale
        end
        if corpse:getSquare():haveFire() then
            corpseOption.notAvailable = true
        end
        initHighlight(corpseOption, corpse)

        local corpseMissing = {}
        for recipe in pairs(MT_CorpseRecipes) do
            if known:contains(recipe) then
                local mat = MTConvertCorpseAction.checkMaterials(playerObj, corpse, recipe)
                local opt = corpseMenu:addOption(getText(recipe), worldobjects, onConvertCorpse, corpse, recipe)
                initHighlight(opt, corpse)
                if not mat.ok then
                    opt.notAvailable = true
                    addMissingToolTip(opt, mat.missing)
                    for _, key in ipairs(mat.missing) do
                        table.insert(corpseMissing, key)
                    end
                end
                if corpse:getSquare():haveFire() then
                    opt.notAvailable = true
                end
            end
        end
        if #corpseMissing > 0 then
            corpseOption.notAvailable = true
            addMissingToolTip(corpseOption, corpseMissing)
        end
    end
    return true
end

local function OnPreFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test then return end
    local playerObj = getSpecificPlayer(player)
    if playerObj == nil then return end
    if not isClient() then return end
    if playerObj:isDead() or playerObj:isAsleep() then return end
    if playerObj:getVehicle() then return end
    addCorpseConvertSubmenu(playerObj, context, worldobjects)
end

Events.OnPreFillWorldObjectContextMenu.Add(OnPreFillWorldObjectContextMenu)