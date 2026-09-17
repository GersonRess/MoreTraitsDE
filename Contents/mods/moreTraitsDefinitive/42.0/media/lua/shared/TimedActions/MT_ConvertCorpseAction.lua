require "TimedActions/ISBaseTimedAction";

MTConvertCorpseAction = ISBaseTimedAction:derive("MTConvertCorpseAction");
MTConvertCorpseAction.CONVERT_OUTPUT = {
    ["Mince Corpse into Fertilizer"] = { item = "Base.CompostBag", duration = 25 },
    ["Extract Propane From Corpse"] = { item = "Base.PropaneTank", duration = 50 },
};

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
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Low")
    self.character:reportEvent("EventLootItem")
    self.sound = self.character:playSound(self.corpseBody:getPickUpSound())
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
    -- heard (gated on the context menu), double-check authority here
    local known = self.character:getKnownRecipes()
    if not known or not known:contains(self.recipe) then
        return false
    end
    local conf = MTConvertCorpseAction.CONVERT_OUTPUT[self.recipe]
    if not conf then
        return false
    end
    local inventory = self.character:getInventory()
    local item = inventory:AddItem(conf.item)
    if item ~= nil then
        sendAddItemToContainer(inventory, item)
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