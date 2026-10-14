require "TimedActions/ISBaseTimedAction";

MTConvertCorpseAction = ISBaseTimedAction:derive("MTConvertCorpseAction");
MTConvertCorpseAction.CONVERT_OUTPUT = {
    ["Mince Corpse into Fertilizer"] = { item = "Base.CompostBag", duration = 250, sound = "MaleZombieEating" },
    ["Extract Propane From Corpse"] = { item = "Base.PropaneTank", duration = 200, sound = "SliceMeat", xp = { Perks.Cooking, 10 } },
};

MTConvertCorpseAction.MISSING_KEYS = {
    mortar = "UI_corpseconvert_missing_mortar",
    knife = "UI_corpseconvert_missing_knife",
    holder = "UI_corpseconvert_missing_holder",
};

function MTConvertCorpseAction.checkMaterials(character, corpseBody, recipe)
    local result = { ok = false, missing = {}, items = {} }
    if character == nil or corpseBody == nil then
        return result
    end
    -- Extract Propane From Corpse only requires the corpse
    if recipe == "Extract Propane From Corpse" then
        result.ok = true
        return result
    end
    -- Mince Corpse into Fertilizer: mortar + knife (not dull) + dirt/compost holder
    local inventory = character:getInventory()
    local hasTool = function(tag, predicate)
        return inventory:getFirstTagEvalRecurse(tag, predicate or function() return true end) ~= nil
    end
    if not hasTool(ItemTag.MORTAR_PESTLE) then
        table.insert(result.missing, MTConvertCorpseAction.MISSING_KEYS.mortar)
    end
    if not hasTool(ItemTag.SHARP_KNIFE, function(item) return not item:isDull() end) then
        table.insert(result.missing, MTConvertCorpseAction.MISSING_KEYS.knife)
    end
    result.items.holder = inventory:getFirstTagEvalRecurse(ItemTag.HOLD_DIRT, function() return true end)
    if result.items.holder == nil then
        result.items.holder = inventory:getFirstTagEvalRecurse(ItemTag.HOLD_COMPOST, function() return true end)
    end
    if result.items.holder == nil then
        table.insert(result.missing, MTConvertCorpseAction.MISSING_KEYS.holder)
    end
    result.ok = #result.missing == 0
    return result
end

function MTConvertCorpseAction:isValid()
    if self.corpseBody == nil then return false end
    if self.character:getSquare():canReachTo(self.corpseBody:getSquare()) ~= true then return false end
    if self.corpseBody:getStaticMovingObjectIndex() < 0 then return false end
    if isClient() then return true end
    return self.character:isDraggingCorpse() == false
end

function MTConvertCorpseAction:waitToStart()
    self.character:faceThisObject(self.corpseBody)
    return self.character:shouldBeTurning()
end

function MTConvertCorpseAction:update()
    self.corpse:setJobDelta(self:getJobDelta())
    self.character:faceThisObject(self.corpseBody)
    self.character:setMetabolicTarget(Metabolics.MediumWork)
end

function MTConvertCorpseAction:start()
    if self.corpse then
        self.corpse:setJobType(getText("ContextMenu_Grab"))
        self.corpse:setJobDelta(0.0)
    end
    local conf = MTConvertCorpseAction.CONVERT_OUTPUT[self.recipe]
    local sound = conf and conf.sound or self.corpseBody:getPickUpSound()
    self.sound = self.character:playSound(sound)
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
end

function MTConvertCorpseAction:stop()
    self:stopSound()
    if self.corpse then self.corpse:setJobDelta(0.0) end
    ISBaseTimedAction.stop(self)
end

function MTConvertCorpseAction:perform()
    self:stopSound()
    forceDropHeavyItems(self.character)
    if self.corpse then self.corpse:setJobDelta(0.0) end
    -- caller already produced the item / removed the corpse in complete()
    -- the container the player uses to store items.
    ISBaseTimedAction.perform(self)
end

function MTConvertCorpseAction:complete()
    if self.corpseBody == nil then
        return false
    end
    -- recipe must be known and all materials present (authority like the original recipe)
    local known = self.character:getKnownRecipes()
    if not known or not known:contains(self.recipe) then
        return false
    end
    local conf = MTConvertCorpseAction.CONVERT_OUTPUT[self.recipe]
    if not conf then
        return false
    end
    local materials = MTConvertCorpseAction.checkMaterials(self.character, self.corpseBody, self.recipe)
    if not materials.ok then
        return false
    end
    local inventory = self.character:getInventory()
    if self.recipe ~= "Extract Propane From Corpse" then
        -- keep tools: 40% chance to lose 1 condition point
        local function degrade(item)
            if item ~= nil and item:getCondition() > 0 and ZombRand(100) < 40 then
                item:setCondition(item:getCondition() - 1)
            end
        end
        local mortar = inventory:getFirstTagEvalRecurse(ItemTag.MORTAR_PESTLE, function() return true end)
        local knife = inventory:getFirstTagEvalRecurse(ItemTag.SHARP_KNIFE, function(item) return not item:isDull() end)
        degrade(mortar)
        degrade(knife)
        -- consume the exact sack the recipe detected (vanilla sync pattern)
        local holder = materials.items.holder
        if holder ~= nil then
            inventory:Remove(holder)
            sendRemoveItemFromContainer(inventory, holder)
        end
    end
    local item = inventory:AddItem(conf.item)
    if item ~= nil then
        sendAddItemToContainer(inventory, item)
    end
    if conf.xp ~= nil and conf.xp[1] ~= nil and conf.xp[2] ~= nil then
        self.character:getXp():AddXP(conf.xp[1], conf.xp[2], false)
    end
    self.corpseBody:getSquare():removeCorpse(self.corpseBody, false)
    return true
end

function MTConvertCorpseAction:getDuration()
    local conf = MTConvertCorpseAction.CONVERT_OUTPUT[self.recipe]
    if conf then
        return conf.duration
    end
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 20
end

function MTConvertCorpseAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function MTConvertCorpseAction:new(character, corpseBody, recipe)
    local o = ISBaseTimedAction.new(self, character)
    o.corpseBody = corpseBody
    o.recipe = recipe
    if corpseBody ~= nil then
        o.corpse = corpseBody:getItem()
    end
    o.maxTime = o:getDuration()
    o.forceProgressBar = true
    return o
end