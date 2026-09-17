local function OnClientCommand(module, command, player, args)
    if module ~= "MoreTraitsDefinitive" then
        return
    end
    if command == "HeadText" and args and args.key then
        local target = player or getPlayer()
        if target and target:isLocalPlayer() then
            HaloTextHelper.addTextWithArrow(
                    target,
                    getText(args.key),
                    args.arrow == 1,
                    args.green == 1 and HaloTextHelper.getColorGreen() or HaloTextHelper.getColorRed()
            )
        end
    end
end

Events.OnClientCommand.Add(OnClientCommand)