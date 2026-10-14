local function isModActivated(modName)
    local mods = getActivatedMods()
    for i = 0, mods:size() - 1 do
        local id = mods:get(i)
        if id == modName then
            return true
        end
        if string.sub(id, -string.len(modName) - 1) == "/" .. modName then
            return true
        end
    end
    return false
end


local function removeTraits()
    local traitDefs = CharacterTraitDefinition.characterTraitDefinitions
    local traitsToRemove = {}

    if isModActivated("DrivingSkill") then
        table.insert(traitsToRemove, "expertdriver")
    end

    if isModActivated("ScavengingSkill") or isModActivated("ScavengingSkillFixed") then
        table.insert(traitsToRemove, "scrounger")
    end

    if #traitsToRemove == 0 then return end

    local removedEnums = {}
    for _, traitName in ipairs(traitsToRemove) do
        local traitEnum = ToadTraitsRegistries[traitName]

        if traitEnum and traitDefs:containsKey(traitEnum) then
            traitDefs:remove(traitEnum)
            table.insert(removedEnums, traitEnum)
        end
    end

    if #removedEnums == 0 then return end

    local allDefs = CharacterTraitDefinition.getTraits()
    for i = 0, allDefs:size() - 1 do
        local mutuallyExclusive = allDefs:get(i):getMutuallyExclusiveTraits()
        for _, removedEnum in ipairs(removedEnums) do
            if mutuallyExclusive:contains(removedEnum) then
                mutuallyExclusive:remove(removedEnum)
            end
        end
    end
end


Events.OnGameBoot.Add(removeTraits)