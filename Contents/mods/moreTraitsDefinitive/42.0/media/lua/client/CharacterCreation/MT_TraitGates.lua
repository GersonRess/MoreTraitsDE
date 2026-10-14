require "MT/MT_TraitGates"

local originalIsTraitEnabled = CharacterCreationProfession.isTraitEnabled

function CharacterCreationProfession:isTraitEnabled(trait)
    if originalIsTraitEnabled(self, trait) then
        return MT.isTraitSelectable(trait)
    end
    return false
end

local originalSetVisible = CharacterCreationProfession.setVisible

function CharacterCreationProfession:setVisible(visible, joypadData)
    originalSetVisible(self, visible, joypadData)
    if visible and self.listboxTrait then
        self:repopulateTraitLists()
    end
end

local function refreshCreationLists()
    local creation = MainScreen.instance and MainScreen.instance.charCreationProfession
    if creation and creation.listboxTrait then
        creation:repopulateTraitLists()
    end
end

local originalSetSandboxVars = SandboxOptionsScreen.setSandboxVars

function SandboxOptionsScreen:setSandboxVars()
    originalSetSandboxVars(self)
    refreshCreationLists()
end
