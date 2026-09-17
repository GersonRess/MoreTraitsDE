MT = MT or {}
MT.Weight = MT.Weight or {}

local function ComputeBase(player)
	local bonus = 0
	if player:hasTrait(ToadTraitsRegistries.packmule) then
		bonus = (SandboxVars.MoreTraits.WeightPackMule or 10) - 8 + math.floor(player:getPerkLevel(Perks.Strength) / 5)
	elseif player:hasTrait(ToadTraitsRegistries.packmouse) then
		bonus = (SandboxVars.MoreTraits.WeightPackMouse or 6) - 8
	else
		bonus = (SandboxVars.MoreTraits.WeightDefault or 8) - 8
	end
	return math.floor(8 + bonus + (SandboxVars.MoreTraits.WeightGlobalMod or 0))
end
MT.Weight.ComputeBase = ComputeBase

local function SetBase(player, newBase)
	pcall(function() player:setMaxWeightBase(newBase) end)
end

local function Apply(player)
	if type(player) ~= "userdata" then
		return nil
	end
	local newBase = ComputeBase(player)
	SetBase(player, newBase)
	return newBase
end
MT.Weight.Apply = Apply

local CHECK_EVERY = 30
local WINDOW_CHECKS = 240

if isClient() and not isServer() then
	local pending = {}
	local attempts = {}
	local tickCount = 0
	local handlerRegistered = false

	local function SendRequest(player)
		local newBase = ComputeBase(player)
		sendClientCommand(player, "MoreTraitsDefinitive", "MT_updateWeight", { weight = newBase })
	end

	local function DisarmIfIdle()
		for key in pairs(pending) do
			return
		end
		if handlerRegistered then
			Events.OnTick.Remove(OnTick)
			handlerRegistered = false
		end
	end

	local function OnTick()
		tickCount = tickCount + 1
		if tickCount % CHECK_EVERY ~= 0 then
			return
		end

		for player in pairs(pending) do
			attempts[player] = (attempts[player] or 0) + 1
			SendRequest(player)

			if attempts[player] >= WINDOW_CHECKS then
				pending[player] = nil
				attempts[player] = nil
			end
		end

		DisarmIfIdle()
	end

	local function ArmRetry(player)
		if not pending[player] then
			pending[player] = true
			attempts[player] = 0
		end
		if not handlerRegistered then
			Events.OnTick.Add(OnTick)
			handlerRegistered = true
		end
	end

	local function Request(player)
		if type(player) ~= "userdata" then
			return
		end
		SendRequest(player)
		ArmRetry(player)
	end

	local function OnCreatePlayer(playerIndex, player)
		if type(playerIndex) == "userdata" then
			player = playerIndex
		end
		Request(player)
	end

	local function OnCreateUI()
		Request(getPlayer())
	end

	Events.OnCreatePlayer.Add(OnCreatePlayer)
	Events.OnCreateUI.Add(OnCreateUI)

	Events.LevelPerk.Add(function(player, perk, level, addBuffer)
		if perk == Perks.Strength and player then
			Request(player)
		end
	end)

	Events.EveryHours.Add(function()
		Request(getPlayer())
	end)

	return
end

local serverOverride = {}

local function RegisterServerWeight(player, weight)
	if type(player) == "userdata" and weight then
		serverOverride[player:getUsername()] = weight
		SetBase(player, weight)
	end
end
MT.Weight.RegisterServerWeight = RegisterServerWeight

local pending = {}
local attempts = {}
local tickCount = 0
local handlerRegistered = false

local function ApplyPlayer(player)
	local override = serverOverride[player:getUsername()]
	if override then
		SetBase(player, override)
		return override
	end
	return Apply(player)
end

local function DisarmIfIdle()
	for key in pairs(pending) do
		return
	end
	if handlerRegistered then
		Events.OnTick.Remove(OnTick)
		handlerRegistered = false
	end
end

local function OnTick()
	tickCount = tickCount + 1
	if tickCount % CHECK_EVERY ~= 0 then
		return
	end

	for player in pairs(pending) do
		attempts[player] = (attempts[player] or 0) + 1
		ApplyPlayer(player)

		if attempts[player] >= WINDOW_CHECKS then
			pending[player] = nil
			attempts[player] = nil
		end
	end

	DisarmIfIdle()
end

local function ArmRetry(player)
	if type(player) ~= "userdata" or pending[player] then
		return
	end
	pending[player] = true
	attempts[player] = 0
	if not handlerRegistered then
		Events.OnTick.Add(OnTick)
		handlerRegistered = true
	end
end

local function TryApply(player)
	if type(player) ~= "userdata" then
		return
	end
	ApplyPlayer(player)
	ArmRetry(player)
end

local function ApplyAll()
	local players = getOnlinePlayers()
	if not players then
		TryApply(getPlayer())
		return
	end
	for i = 0, players:size() - 1 do
		TryApply(players:get(i))
	end
end

local function OnCreatePlayer(playerIndex, player)
	if type(playerIndex) == "userdata" then
		player = playerIndex
	end
	TryApply(player)
end

Events.OnCreatePlayer.Add(OnCreatePlayer)

Events.LevelPerk.Add(function(player, perk, level, addBuffer)
	if perk == Perks.Strength and player then
		TryApply(player)
	end
end)

Events.EveryHours.Add(function()
	if getOnlinePlayers() and getOnlinePlayers():size() > 0 then
		ApplyAll()
	else
		TryApply(getPlayer())
	end
end)