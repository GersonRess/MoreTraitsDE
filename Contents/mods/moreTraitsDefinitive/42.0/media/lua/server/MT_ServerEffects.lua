MT = MT or {}

MT.ServerEffects = MT.ServerEffects or {}

local RAM_COOLDOWN = 5
local RAM_SERVER_REACH = 1.6
local RAM_SERVER_REACH_SQ = RAM_SERVER_REACH * RAM_SERVER_REACH
local RELAY_RANGE = 64
local BOUNCER_ZOMBIES = 3
local BOUNCER_GATE = 3
local INDEFATIGABLE_RANGE = 3.0
local INDEFATIGABLE_ZOMBIES = 3
local INDEFATIGABLE_GATE = 10
local TRIP_GATE = 3
local HIT_REACTION_GATE = 1

local function gateOpen(player, key, seconds)
    local playerdata = player:getModData()
    if not playerdata then
        return false
    end
    local now = getTimestamp()
    local last = playerdata[key]
    if last ~= nil and (now - last) < seconds then
        return false
    end
    playerdata[key] = now
    return true
end

local function applyRamHit(player, zombie, endurance)
    if not player:hasTrait(ToadTraitsRegistries.martial) then
        return
    end
    if not SandboxVars.MoreTraits.BatteringRamMartialCombo then
        return
    end
    if player:getPrimaryHandItem() ~= nil and not SandboxVars.MoreTraits.MartialWeapons then
        return
    end

    local damageMult = 1.0
    if endurance < 0.25 then
        damageMult = 0.25
    elseif endurance < 0.5 then
        damageMult = 0.5
    elseif endurance < 0.75 then
        damageMult = 0.75
    end

    local finalDamage = (ZombRand(10, 61) / 100) * damageMult
    zombie:setHealth(zombie:getHealth() - finalDamage)
    if zombie:getHealth() <= 0 then
        zombie:Kill(player)
    end
end

function MT.ServerEffects.BatteringRam(player, args)
    if not player or not player:hasTrait(ToadTraitsRegistries.batteringram) then
        return
    end

    if MT.HasLegFracture(player) then
        return
    end

    local square = player:getCurrentSquare()
    if not square or square:has(IsoObjectType.tree) then
        return
    end

    local knocks = args and args.knocks
    if type(knocks) ~= "table" or #knocks == 0 then
        return
    end

    local px = player:getX()
    local py = player:getY()

    local others = getOnlinePlayers()
    if others ~= nil then
        for i = 0, others:size() - 1 do
            local other = others:get(i)
            if other ~= nil and other ~= player then
                local dx = math.abs(other:getX() - px)
                local dy = math.abs(other:getY() - py)
                if dx <= RELAY_RANGE and dy <= RELAY_RANGE then
                    sendServerCommand(other, "MoreTraitsDefinitive", "RamKnockdown", { knocks = knocks })
                end
            end
        end
    end

    local enemies = player:getSpottedList()
    if not enemies or enemies:size() == 0 then
        return
    end

    local stats = player:getStats()
    local fitness = math.max(1, player:getPerkLevel(Perks.Fitness))
    local enduranceReduction = (10 / fitness) * 0.01
    local endurance = stats:get(CharacterStat.ENDURANCE)
    local timestamp = getTimestamp()

    for i = 0, enemies:size() - 1 do
        local enemy = enemies:get(i)
        if enemy and enemy:isZombie() then
            local dx = enemy:getX() - px
            local dy = enemy:getY() - py

            if dx * dx + dy * dy <= RAM_SERVER_REACH_SQ then
                for j = 1, #knocks do
                    if MT.RamKnockMatches(enemy, knocks[j]) then
                        local enemyData = enemy:getModData()
                        if not enemyData.lastRamTime or (timestamp > enemyData.lastRamTime + RAM_COOLDOWN) then
                            enemyData.lastRamTime = timestamp
                            MT.RamKnockdown(enemy, 2.0)
                            endurance = math.max(0, endurance - enduranceReduction)
                            if not isClient() then
                                stats:set(CharacterStat.ENDURANCE, endurance)
                            end
                            applyRamHit(player, enemy, endurance)
                        end
                        break
                    end
                end
            end
        end
    end
end

function MT.ServerEffects.Bouncer(player)
    if not player or not player:hasTrait(ToadTraitsRegistries.bouncer) then
        return
    end

    if not gateOpen(player, "MTLastBouncerRequest", BOUNCER_GATE) then
        return
    end

    local distance = SandboxVars.MoreTraits.BouncerDistance or 1.75
    local enemies = player:getSpottedList()
    if not enemies or enemies:size() < BOUNCER_ZOMBIES then
        return
    end

    local closeEnemyCount = 0

    for i = 0, enemies:size() - 1 do
        local enemy = enemies:get(i)
        if enemy and enemy:isZombie() and enemy:DistTo(player) <= distance then
            closeEnemyCount = closeEnemyCount + 1
            if closeEnemyCount >= BOUNCER_ZOMBIES then
                if not enemy:isKnockedDown() then
                    enemy:setStaggerBack(true)
                end
                return
            end
        end
    end
end

function MT.ServerEffects.Indefatigable(player, args)
    if not player or not player:hasTrait(ToadTraitsRegistries.indefatigable) then
        return
    end

    local playerdata = player:getModData()
    if not playerdata then
        return
    end

    if not gateOpen(player, "MTLastIndefatigableRequest", INDEFATIGABLE_GATE) then
        return
    end

    local cell = getCell()
    local zombies = cell and cell:getZombieList() or nil

    if zombies and zombies:size() >= INDEFATIGABLE_ZOMBIES then
        for i = 0, zombies:size() - 1 do
            local zombie = zombies:get(i)
            if zombie:DistTo(player) <= INDEFATIGABLE_RANGE then
                zombie:setStaggerBack(true)
                zombie:setKnockedDown(true)
            end
        end
    end

    if player:isDeathDragDown() or (args and args.deathDragDown) then
        playerdata.IndefatigableHasBeenDraggedDown = true
        player:setPlayingDeathSound(false)
        player:setDeathDragDown(false)
        player:setHitReaction("EvasiveBlocked")
    end
end

function MT.ServerEffects.TripFall(player)
    if not gateOpen(player, "MTLastTripRequest", TRIP_GATE) then
        return
    end

    local side = ZombRand(2) == 0 and "left" or "right"
    player:setBumpFallType("FallForward")
    player:setBumpType(side)
    player:setBumpDone(false)
    player:setBumpFall(true)
    player:reportEvent("wasBumped")
end

function MT.ServerEffects.SetHitReaction(player, args)
    if not player or not player:hasTrait(ToadTraitsRegistries.unwavering) then
        return
    end

    if not gateOpen(player, "MTLastHitReactionRequest", HIT_REACTION_GATE) then
        return
    end

    local reaction = args and args.reaction
    if type(reaction) ~= "string" or not reaction:match("^UnwaveringBite") then
        return
    end

    player:setHitReaction(reaction)
end

return MT