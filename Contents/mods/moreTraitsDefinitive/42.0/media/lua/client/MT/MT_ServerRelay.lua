local function onServerCommand(module, command, args)
    if module ~= "MoreTraitsDefinitive" then
        return
    end

    if command ~= "RamKnockdown" then
        return
    end

    local knocks = args and args.knocks
    if type(knocks) ~= "table" or #knocks == 0 then
        return
    end

    local cell = getCell()
    if not cell then
        return
    end

    local zombies = cell:getZombieList()
    if not zombies then
        return
    end

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)

        for j = 1, #knocks do
            if MT.RamKnockMatches(zombie, knocks[j]) then
                MT.RamKnockdown(zombie, 2.0)
                break
            end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
