print("MT_EatFood | v12 loaded")

function MT_EatFoodApplyPain(action)
    local character = action and action.character
    if not character then return end
    local item = action.item
    if not item or item:hasComponent(ComponentType.FluidContainer) then return end
    local badteeth = ToadTraitsRegistries.badteeth
    if not badteeth then
        print("MT_EatFood | no badteeth reference found")
        return
    end
    if isClient() then return end
    if not character:hasTrait(badteeth) then
        print("MT_EatFood | player without badteeth trait")
        return
    end
    local bodyDamage = character:getBodyDamage()
    local head = bodyDamage and (bodyDamage:getBodyPart(BodyPartType.Head)
            or bodyDamage:getBodyPart(BodyPartType.ToIndex(BodyPartType.Head)))
    if not head then
        print("MT_EatFood | head is nil")
        return
    end
    local before = head:getAdditionalPain()
    if before ~= before then
        head:setAdditionalPain(0)
        before = 0
    end
    local painIncrease = 25
    head:setAdditionalPain(math.min(before + painIncrease, 100))
    print("MT_EatFood | PAIN +" .. painIncrease .. " head " .. before .. "->" .. head:getAdditionalPain() .. " (" .. character:getUsername() .. ")")
end

local mtEatOldComplete = ISEatFoodAction.complete
function ISEatFoodAction:complete()
    local result = mtEatOldComplete(self)
    MT_EatFoodApplyPain(self)
    return result
end

Events.OnGameBoot.Add(function()
    if MT_EatFoodInstalled then return end
    MT_EatFoodInstalled = true
    local cur = ISEatFoodAction.complete
    if cur ~= mtEatOldComplete then
        ISEatFoodAction.complete = function(self)
            local r = cur(self)
            MT_EatFoodApplyPain(self)
            return r
        end
    end
    print("MT_EatFood | reinstalled")
end)