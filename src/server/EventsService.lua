-- ServerScript: EventsService.lua
-- Handles hazards, supply drops, storm logic
-- Manages timed events and environmental dangers during matches

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Config = require(ReplicatedFirst.Config)
local PlayerStats = require(script.Parent.PlayerStats)

-- Try to load BalanceConfig for tunable values
local BalanceConfig = nil
pcall(function()
    BalanceConfig = require(ReplicatedFirst:WaitForChild("BalanceConfig", 2))
end)

local EventsService = {}
EventsService.activeMatch = false
EventsService.matchStartTime = 0
EventsService.eventSchedule = {}
EventsService.currentStormPhase = 0
EventsService.stormActive = false
EventsService.supplyDropActive = false
EventsService.stormDamageConnection = nil

-- RemoteEvents for client communication
local eventsRemoteEvent = Instance.new("RemoteEvent")
eventsRemoteEvent.Name = "EventsRemoteEvent"
eventsRemoteEvent.Parent = ReplicatedStorage

-- Get storm config value (from BalanceConfig if available, otherwise defaults)
local function getStormValue(key, default, phase)
    if BalanceConfig and BalanceConfig.Storm then
        if phase and BalanceConfig.Storm[key] and BalanceConfig.Storm[key][phase] then
            return BalanceConfig.Storm[key][phase]
        elseif BalanceConfig.Storm[key] then
            return BalanceConfig.Storm[key]
        end
    end
    return default
end

-- Storm boundary management
local function calculateStormPosition(currentPhase)
    -- Calculate storm boundary based on current phase
    -- Get phase size ratio from BalanceConfig
    local phaseSize = getStormValue("PHASE_SIZE", nil, currentPhase)
    if not phaseSize then
        -- Fallback calculation
        local totalPhases = Config.STORM_PHASES
        phaseSize = (totalPhases - currentPhase) / totalPhases
    end
    
    local currentRadius = Config.ARENA_SIZE * 0.5 * phaseSize
    return currentRadius, Vector3.new(0, 0, 0) -- Assuming arena center is at origin
end

-- Get storm damage for current phase
local function getStormDamage(phase)
    return getStormValue("PHASE_DAMAGE", phase, phase) -- Default damage = phase number
end

-- Start storm damage application
local function startStormDamage(phase, startRadius, endRadius, center, duration)
    -- Stop existing damage connection
    if EventsService.stormDamageConnection then
        EventsService.stormDamageConnection:Disconnect()
    end
    
    local damagePerSecond = getStormDamage(phase)
    local startTime = tick()
    
    -- Initialize current radius
    EventsService.currentRadius = startRadius
    
    print(string.format("Starting storm damage: shrinking %.0f -> %.0f over %ds, %d dmg/s", startRadius, endRadius, duration, damagePerSecond))
    
    EventsService.stormDamageConnection = RunService.Heartbeat:Connect(function(dt)
        if not EventsService.stormActive then
            EventsService.stormDamageConnection:Disconnect()
            return
        end
        
        -- Calculate current interpolated radius
        local elapsed = tick() - startTime
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local currentRadius = startRadius + (endRadius - startRadius) * alpha
        
        -- Update state for smooth transitions
        EventsService.currentRadius = currentRadius
        
        -- Apply damage to players outside the current radius
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - center).Magnitude
                    if distance > currentRadius then
                        -- Player is in the storm
                        local damage = damagePerSecond * dt
                        PlayerStats:applyDamage(player, damage, "STORM")
                    end
                end
            end
        end
    end)
end

-- Activate the next storm phase
function EventsService:activateStormPhase(phase)
    if phase > Config.STORM_PHASES then
        return
    end
    
    EventsService.currentStormPhase = phase
    EventsService.stormActive = true
    
    -- Calculate shrinking parameters
    -- Use current tracked radius if available, otherwise calculate from previous phase
    -- This fixes the "Skipping Phases" bug where it would jump to a tiny radius
    local startRadius = EventsService.currentRadius
    
    if not startRadius then
        if phase > 1 then
            startRadius, _ = calculateStormPosition(phase - 1)
        else
            startRadius = Config.ARENA_SIZE * 0.5
        end
    end
    
    local targetRadius, center = calculateStormPosition(phase)
    
    -- Get duration
    local duration = getStormValue("PHASE_DURATIONS", nil, phase)
    if not duration then
        -- Fallback timing
        if phase == 1 then duration = 300
        elseif phase == 2 then duration = 240
        elseif phase == 3 then duration = 180
        elseif phase == 4 then duration = 120
        elseif phase == 5 then duration = 90
        else duration = 60
        end
    end
    
    print("[EventsService] Activating storm phase " .. phase .. ", shrinking " .. math.floor(startRadius) .. " -> " .. math.floor(targetRadius) .. " over " .. duration .. "s")
    
    -- Play storm warning sound via AudioService
    local success, AudioService = pcall(function()
        return require(script.Parent.AudioService)
    end)
    if success and AudioService then
        AudioService:playStormWarning(phase)
    end
    
    -- Notify all clients about the storm phase (Pass Duration, StartRadius, AND Damage)
    local damagePerSecond = getStormDamage(phase)
    eventsRemoteEvent:FireAllClients("STORM_PHASE_ACTIVE", phase, targetRadius, center, duration, startRadius, damagePerSecond)
    
    -- Start applying storm damage with gradual shrinking
    startStormDamage(phase, startRadius, targetRadius, center, duration)
    
    -- Schedule next phase if not final phase
    if phase < Config.STORM_PHASES then
        -- Cancel any existing scheduled phase to prevent double activation if skipped manually
        if EventsService._nextPhaseTask then
            task.cancel(EventsService._nextPhaseTask)
        end

        EventsService._nextPhaseTask = task.delay(duration, function()
             EventsService:activateStormPhase(phase + 1)
        end)
    end
end

-- Deploy supply drop
function EventsService:deploySupplyDrop()
    if EventsService.supplyDropActive then
        return -- Don't deploy multiple at once
    end
    
    EventsService.supplyDropActive = true
    
    -- Calculate random position within arena but not in center
    local angle = math.random() * 2 * math.pi
    -- Reduce distance to avoid edges where sky lobby might interact oddly vs visual boundary
    local distance = math.random(Config.ARENA_SIZE * 0.25, Config.ARENA_SIZE * 0.40) 
    local position = Vector3.new(
        math.cos(angle) * distance,
        150, -- Standard drop height (matches client config)
        math.sin(angle) * distance
    )
    
    local dropId = "Drop_" .. tick()
    print("Deploying supply drop " .. dropId .. " at position: " .. tostring(position))
    
    -- Notify clients about supply drop (for visual + sound)
    eventsRemoteEvent:FireAllClients("SUPPLY_DROP_DEPLOYED", position, dropId)
    
    -- Simulate parachute drop time (matches client visuals)
    task.wait(12) 
    
    -- Activate supply drop location
    eventsRemoteEvent:FireAllClients("SUPPLY_DROP_LANDED", position, dropId)
    
    -- Spawn actual loot interactable
    local success, LootDistribution = pcall(function()
        return require(script.Parent.LootDistribution)
    end)
    
    if success and LootDistribution then
        -- Spawn the Supply Drop trigger and loot
        -- The position should be ground level ideally, but spawnSupplyDrop handles raycast
        local groundPos = Vector3.new(position.X, 0, position.Z)
        
        -- Raycast to find exact ground
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        -- Filter Lobby AND LobbySpawn (named explicitly in DefaultSpawn)
        local exclusions = {
             game.Workspace:FindFirstChild("Loot"), 
             game.Workspace:FindFirstChild("Lobby"),
             game.Workspace:FindFirstChild("LobbySpawn")
        }
        rayParams.FilterDescendantsInstances = exclusions
        
        -- Raycast downwards from 200 studs (below possible sky lobby)
        local rayRes = workspace:Raycast(Vector3.new(position.X, 200, position.Z), Vector3.new(0, -300, 0), rayParams)
        if rayRes then
            groundPos = rayRes.Position
        end
        
        LootDistribution:spawnSupplyDrop(groundPos, dropId)
    end
    
    -- Mark as inactive after a period
    task.wait(300) -- Supply drop stays active for 5 minutes
    EventsService.supplyDropActive = false
    
    -- Schedule next supply drop randomly
    task.wait(math.random(300, 600)) -- 5-10 minutes until next drop
    EventsService:deploySupplyDrop()
end

-- Activate special hazard event
function EventsService:activateHazardEvent(eventType)
    print("Activating hazard event: " .. eventType)
    
    local eventData = {}
    
    if eventType == "ACID_RAIN" then
        -- Acid rain in random area (Modified to be localized so players can escape)
        eventData.type = "ACID_RAIN"
        eventData.position = Vector3.new(
            math.random(-Config.ARENA_SIZE/2.2, Config.ARENA_SIZE/2.2),
            0,
            math.random(-Config.ARENA_SIZE/2.2, Config.ARENA_SIZE/2.2)
        )
        eventData.radius = 300 
        eventData.duration = 60
    elseif eventType == "POISON_FOG" then
        -- Poison fog in random area
        eventData.type = "POISON_FOG"
        eventData.position = Vector3.new(
            math.random(-Config.ARENA_SIZE/2.2, Config.ARENA_SIZE/2.2),
            0,
            math.random(-Config.ARENA_SIZE/2.2, Config.ARENA_SIZE/2.2)
        )
        eventData.radius = 60 
        eventData.duration = 45
    elseif eventType == "WILDFIRE" then
        -- Wildfire spreading
        eventData.type = "WILDFIRE"
        eventData.position = Vector3.new(
            math.random(-Config.ARENA_SIZE/2.2, Config.ARENA_SIZE/2.2),
            0,
            math.random(-Config.ARENA_SIZE/2.2, Config.ARENA_SIZE/2.2)
        )
        eventData.radius = 50
        eventData.duration = 90
    end
    
    -- Notify clients about hazard event
    eventsRemoteEvent:FireAllClients("HAZARD_EVENT", eventData)
    
    -- Apply hazard effects periodically
    local hazardConnection
    local endTime = tick() + eventData.duration
    
    -- Track time for periodic damage application (every 1s)
    local lastDamageTime = 0
    
    hazardConnection = RunService.Heartbeat:Connect(function(dt)
        if tick() >= endTime then
            hazardConnection:Disconnect()
            eventsRemoteEvent:FireAllClients("HAZARD_EVENT_END", eventData.type)
            print("Hazard event ended: " .. eventType)
            return
        end
        
        -- Throttle damage checks to once per second approx
        -- But since Heartbeat is fast, we can accumulate dt or just check tick
        local now = tick()
        if now - lastDamageTime < 1 then return end
        lastDamageTime = now
        
        -- Apply hazard effects to players in area
        if eventData.type == "ACID_RAIN" then
            -- Acid Rain: Damages players exposed to sky WITHIN radius
            for _, player in pairs(game.Players:GetPlayers()) do
                 if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
                     -- Check distance
                     local dist = (player.Character.HumanoidRootPart.Position - eventData.position).Magnitude
                     if dist < eventData.radius then
                         local head = player.Character.Head
                         -- Raycast up to check for cover
                         local rayOrigin = head.Position
                         local rayDir = Vector3.new(0, 50, 0)
                         local rayParams = RaycastParams.new()
                         rayParams.FilterDescendantsInstances = {player.Character}
                         rayParams.FilterType = Enum.RaycastFilterType.Exclude
                         
                         local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
                         if not result then -- No cover found, takes damage
                             PlayerStats:applyDamage(player, 2, "ACID")
                         end
                     end
                 end
            end
        elseif eventData.type == "POISON_FOG" then
            -- Poison fog: periodic damage
            for _, player in pairs(game.Players:GetPlayers()) do
                 if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                     local dist = (player.Character.HumanoidRootPart.Position - eventData.position).Magnitude
                     if dist < eventData.radius then
                         PlayerStats:applyDamage(player, 1, "POISON")
                     end
                 end
            end
        elseif eventData.type == "WILDFIRE" then
            -- Wildfire: ongoing damage
             for _, player in pairs(game.Players:GetPlayers()) do
                 if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                     local dist = (player.Character.HumanoidRootPart.Position - eventData.position).Magnitude
                     if dist < eventData.radius then
                         PlayerStats:applyDamage(player, 4, "FIRE")
                     end
                 end
            end
        end
    end)
end

-- Initialize match events
-- Reset match events
function EventsService:resetMatch()
    print("[EventsService] Resetting match events")
    EventsService.activeMatch = false
    EventsService.stormActive = false
    EventsService.supplyDropActive = false
    
    -- Disconnect loops
    if EventsService.stormDamageConnection then
        EventsService.stormDamageConnection:Disconnect()
        EventsService.stormDamageConnection = nil
    end
    
    -- Cancel scheduled tasks
    if EventsService._nextPhaseTask then
        task.cancel(EventsService._nextPhaseTask)
        EventsService._nextPhaseTask = nil
    end
    
    if EventsService._initialDelayTask then
        task.cancel(EventsService._initialDelayTask)
        EventsService._initialDelayTask = nil
    end
    
    if EventsService._supplyDropTask then
        task.cancel(EventsService._supplyDropTask)
        EventsService._supplyDropTask = nil
    end
    
    -- Cleanup visual hazards
    eventsRemoteEvent:FireAllClients("MATCH_ENDED")
end

-- Initialize match events
function EventsService:initializeMatch()
    if EventsService.activeMatch then
        return
    end
    
    EventsService:resetMatch() -- Ensure clean slate
    
    EventsService.activeMatch = true
    EventsService.matchStartTime = tick()
    EventsService.currentStormPhase = 0
    EventsService.supplyDropActive = false
    
    print("Initializing match events...")
    
    -- Start storm progression after a delay
    -- Use stored task handle so we can cancel it
    EventsService._initialDelayTask = task.delay(300, function()
        if EventsService.activeMatch then
            EventsService:activateStormPhase(1)
        end
    end)
    
    -- Start periodic supply drops after a delay
    EventsService._supplyDropTask = task.delay(120, function()
        if EventsService.activeMatch then
            EventsService:deploySupplyDrop()
        end
    end)
    
    -- Schedule random hazard events during match
    coroutine.wrap(function()
        while EventsService.activeMatch do
            task.wait(math.random(240, 480)) -- 4-8 minutes between hazard events
            
            if EventsService.activeMatch then
                local hazardTypes = {"ACID_RAIN", "POISON_FOG", "WILDFIRE"}
                local randomHazard = hazardTypes[math.random(1, #hazardTypes)]
                EventsService:activateHazardEvent(randomHazard)
            end
        end
    end)()
end

-- Initialize events service
function EventsService.init()
    print("EventsService initialized")
    
    -- Connect to remote events from other services if needed
    eventsRemoteEvent.OnServerEvent:Connect(function(player, action, ...)
        -- Handle client requests if needed
    end)
end

return EventsService