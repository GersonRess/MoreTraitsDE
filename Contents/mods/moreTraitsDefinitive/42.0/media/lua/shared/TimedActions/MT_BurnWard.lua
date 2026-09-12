local function isBurnedAverse(character)
    if not character then return false end

    if not SandboxVars.MoreTraits or not SandboxVars.MoreTraits.BurnedFireAversion then
        return false
    end

    if character:hasTrait(ToadTraitsRegistries.burned) then
        if not isServer() then
            HaloTextHelper.addText(character, getText("UI_burnedstop"), "", HaloTextHelper.getColorRed())
        end
        return true
    end
    return false
end

local function lightFromLiteratureNew(o_new, aversionFn)
    return function(self, character, item, lighter, campfire, fuelAmt)
        local o = o_new(self, character, item, lighter, campfire, fuelAmt)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local function lightFromKindleNew(o_new, aversionFn)
    return function(self, character, plank, item, campfire)
        local o = o_new(self, character, plank, item, campfire)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local function lightFromPetrolNew(o_new, aversionFn)
    return function(self, character, campfire, lighter, petrol, maxTime)
        local o = o_new(self, character, campfire, lighter, petrol, maxTime)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local function bbqLightFromKindleNew(o_new, aversionFn)
    return function(self, character, plank, item, bbq)
        local o = o_new(self, character, plank, item, bbq)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local function bbqLightFromLiteratureNew(o_new, aversionFn)
    return function(self, character, item, lighter, bbq)
        local o = o_new(self, character, item, lighter, bbq)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local function bbqLightFromPetrolNew(o_new, aversionFn)
    return function(self, character, bbq, lighter, petrol)
        local o = o_new(self, character, bbq, lighter, petrol)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local function burnCorpseActionNew(o_new, aversionFn)
    return function(self, character, corpse, lighter, petrol)
        local o = o_new(self, character, corpse, lighter, petrol)
        if o and aversionFn(character) then
            function o:isValid()
                return false
            end
        end
        return o
    end
end

local fireClasses = {
    { "ISLightFromLiterature", lightFromLiteratureNew },
    { "ISLightFromKindle", lightFromKindleNew },
    { "ISLightFromPetrol", lightFromPetrolNew },
    { "ISBBQLightFromKindle", bbqLightFromKindleNew },
    { "ISBBQLightFromLiterature", bbqLightFromLiteratureNew },
    { "ISBBQLightFromPetrol", bbqLightFromPetrolNew },
    { "ISBurnCorpseAction", burnCorpseActionNew },
}

for _, entry in ipairs(fireClasses) do
    MT.PatchFireBlock(entry[1], isBurnedAverse, entry[2])
end