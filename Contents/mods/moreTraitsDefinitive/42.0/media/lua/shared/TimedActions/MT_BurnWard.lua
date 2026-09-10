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

local fireClasses = {
    "ISLightFromLiterature",
    "ISLightFromKindle",
    "ISLightFromPetrol",
    "ISBBQLightFromKindle",
    "ISBBQLightFromLiterature",
    "ISBBQLightFromPetrol",
    "ISBurnCorpseAction",
}

for _, class in ipairs(fireClasses) do
    MT.PatchFireBlock(class, isBurnedAverse)
end