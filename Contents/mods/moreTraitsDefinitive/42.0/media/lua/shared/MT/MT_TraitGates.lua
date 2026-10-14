MT = MT or {}

MT.traitKeyByName = nil

MT.traitKeyOfType = function(traitType)
    if not ToadTraitsRegistries or not traitType then
        return nil
    end
    local name = traitType:getName()
    if MT.traitKeyByName == nil then
        MT.traitKeyByName = {}
        for key, traitReg in pairs(ToadTraitsRegistries) do
            MT.traitKeyByName[traitReg:getName()] = key
        end
    end
    return MT.traitKeyByName[name]
end

MT.isTraitAllowed = function(characterTrait)
    if not characterTrait then return true end
    local key = MT.traitKeyOfType(characterTrait)
    if not key then return true end
    if getSandboxOptions then
        local option = getSandboxOptions():getOptionByName("MoreTraitsList." .. key)
        if option and option.getValue then
            return option:getValue()
        end
    end
    local page = SandboxVars and SandboxVars.MoreTraitsList
    if not page then return true end
    local value = page[key]
    return value == nil or value
end

MT.isTraitSelectable = function(trait)
    if not trait then return true end
    return MT.isTraitAllowed(trait:getType())
end
