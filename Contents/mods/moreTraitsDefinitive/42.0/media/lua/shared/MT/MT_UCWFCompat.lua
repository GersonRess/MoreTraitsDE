if isClient() and not isServer() then
	return
end

local Attempts = 0

local function patchUCWF()
	if not UnifiedCarryWeightFramework then
		return false
	end
	local originalRecomputeAll = UnifiedCarryWeightFramework.recomputeAll
	if not originalRecomputeAll or UnifiedCarryWeightFramework.MTPatched then
		return true
	end

	UnifiedCarryWeightFramework.recomputeAll = function(player)
		originalRecomputeAll(player)

		local players = {}
		if player then
			players[1] = player
		else
			local online = getOnlinePlayers()
			if online then
				for i = 0, online:size() - 1 do
					players[#players + 1] = online:get(i)
				end
			end
			if #players == 0 then
				local localPlayer = getPlayer()
				if localPlayer then
					players[1] = localPlayer
				end
			end
		end

		for _, p in ipairs(players) do
			if ToadTraitsRegistries and MT and MT.Weight and MT.Weight.Apply then
				if p:hasTrait(ToadTraitsRegistries.packmule) or p:hasTrait(ToadTraitsRegistries.packmouse) then
					MT.Weight.Apply(p)
				end
			end
		end
	end

	UnifiedCarryWeightFramework.MTPatched = true
	return true
end

local function PendingPatch()
	Attempts = Attempts + 1
	if patchUCWF() or Attempts > 40 then
		Events.OnTick.Remove(PendingPatch)
	end
end

Events.OnGameBoot.Add(patchUCWF)
Events.OnServerStarted.Add(patchUCWF)
Events.OnTick.Add(PendingPatch)