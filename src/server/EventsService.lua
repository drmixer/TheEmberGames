-- ServerScript: EventsService.lua
-- Handles hazards, supply drops, storm logic
-- Manages timed events and environmental dangers during matches

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(script.Parent.shared.Config)
local PlayerStats = require(script.Parent.server.PlayerStats)

local EventsService = {}
EventsService.activeMatch = false
EventsService.matchStartTime = 0
EventsService.eventSchedule = {}
EventsService.currentStormPhase = 0
EventsService.stormActive = false
EventsService.supplyDropActive = false

-- RemoteEvents for client communication
local eventsRemoteEvent = Instance.new("RemoteEvent")
eventsRemoteEvent.Name = "EventsRemoteEvent"
eventsRemoteEvent.Parent = ReplicatedStorage

-- Storm boundary management
local function calculateStormPosition(currentPhase)
    -- Calculate storm boundary based on current phase
    -- Phase 1: Arena at full size, Phase 7: Very small center area
    local totalPhases = Config.STORM_PHASES
    local phaseRatio = (totalPhases - currentPhase) / totalPhases
    local currentRadius = Config.ARENA_SIZE * 0.5 * phaseRatio
    return currentRadius, Vector3.new(0, 0, 0) -- Assuming arena center is at origin
end

-- Activate the next storm phase
function EventsService:activateStormPhase(phase)
    if phase > Config.STORM_PHASES then
        print("Final storm phase reached")
        return
    end
    
    EventsService.currentStormPhase = phase
    local radius, center = calculateStormPosition(phase)
    
    print("Activating storm phase " .. phase .. ", radius: " .. radius)
    
    -- Notify all clients about the storm phase
    eventsRemoteEvent:FireAllClients("STORM_PHASE_ACTIVE", phase, radius, center)
    
    -- Schedule next phase if not final phase
    if phase < Config.STORM_PHASES then
        local nextPhaseTime = 0
        if phase == 1 then nextPhaseTime = 300 -- 5 minutes for first phase
        elseif phase == 2 then nextPhaseTime = 240 -- 4 minutes for second phase
        elseif phase == 3 then nextPhaseTime = 180 -- 3 minutes for third phase
        elseif phase == 4 then nextPhaseTime = 120 -- 2 minutes for fourth phase
        elseif phase == 5 then nextPhaseTime = 90  -- 1.5 minutes for fifth phase
        else nextPhaseTime = 60 -- 1 minute for final phases
        end
        
        wait(nextPhaseTime)
        EventsService:activateStormPhase(phase + 1)
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
    local distance = math.random(Config.ARENA_SIZE * 0.25, Config.ARENA_SIZE * 0.4) -- Avoid center area
    local position = Vector3.new(
        math.cos(angle) * distance,
        100, -- High altitude
        math.sin(angle) * distance
    )
    
    print("Deploying supply drop at position: " .. tostring(position))
    
    -- Notify clients about supply drop
    eventsRemoteEvent:FireAllClients("SUPPLY_DROP_DEPLOYED", position)
    
    -- Simulate parachute drop
    wait(8) -- Time for drop to reach ground
    
    -- Activate supply drop location
    eventsRemoteEvent:FireAllClients("SUPPLY_DROP_LANDED", position)
    
    -- Mark as inactive after a period
    wait(300) -- Supply drop stays active for 5 minutes
    EventsService.supplyDropActive = false
    
    -- Schedule next supply drop randomly
    wait(math.random(300, 600)) -- 5-10 minutes until next drop
    EventsService:deploySupplyDrop()
end

-- Activate special hazard event
function EventsService:activateHazardEvent(eventType)
    print("Activating hazard event: " .. eventType)
    
    local eventData = {}
    
    if eventType == "FLOOD" then
        -- Flood event in specific area
        eventData.type = "FLOOD"
        eventData.position = Vector3.new(math.random(-Config.ARENA_SIZE/4, Config.ARENA_SIZE/4), 0, math.random(-Config.ARENA_SIZE/4, Config.ARENA_SIZE/4))
        eventData.radius = 50
        eventData.duration = 60
    elseif eventType == "POISON_FOG" then
        -- Poison fog in random area
        eventData.type = "POISON_FOG"
        eventData.position = Vector3.new(math.random(-Config.ARENA_SIZE/4, Config.ARENA_SIZE/4), 0, math.random(-Config.ARENA_SIZE/4, Config.ARENA_SIZE/4))
        eventData.radius = 30
        eventData.duration = 45
    elseif eventType == "WILDFIRE" then
        -- Wildfire spreading
        eventData.type = "WILDFIRE"
        eventData.position = Vector3.new(math.random(-Config.ARENA_SIZE/3, Config.ARENA_SIZE/3), 0, math.random(-Config.ARENA_SIZE/3, Config.ARENA_SIZE/3))
        eventData.radius = 20
        eventData.duration = 90
    end
    
    -- Notify clients about hazard event
    eventsRemoteEvent:FireAllClients("HAZARD_EVENT", eventData)
    
    -- Apply hazard effects periodically
    local hazardConnection
    local endTime = tick() + eventData.duration
    hazardConnection = RunService.Heartbeat:Connect(function()
        if tick() >= endTime then
            hazardConnection:Disconnect()
            eventsRemoteEvent:FireAllClients("HAZARD_EVENT_END", eventData.type)
            print("Hazard event ended: " .. eventType)
            return
        end
        
        -- Apply hazard effects to players in area
        if eventData.type == "FLOOD" then
            -- Flood: players may drown if submerged
        elseif eventData.type == "POISON_FOG" then
            -- Poison fog: periodic damage
        elseif eventData.type == "WILDFIRE" then
            -- Wildfire: ongoing damage
        end
    end)
end

-- Initialize match events
function EventsService:initializeMatch()
    if EventsService.activeMatch then
        return
    end
    
    EventsService.activeMatch = true
    EventsService.matchStartTime = tick()
    EventsService.currentStormPhase = 0
    EventsService.supplyDropActive = false
    
    print("Initializing match events...")
    
    -- Start storm progression after a delay
    wait(300) -- Wait 5 minutes before first storm phase
    EventsService:activateStormPhase(1)
    
    -- Start periodic supply drops after a delay
    wait(120) -- First supply drop after 2 minutes
    EventsService:deploySupplyDrop()
    
    -- Schedule random hazard events during match
    coroutine.wrap(function()
        while EventsService.activeMatch do
            wait(math.random(240, 480)) -- 4-8 minutes between hazard events
            
            if EventsService.activeMatch then
                local hazardTypes = {"FLOOD", "POISON_FOG", "WILDFIRE"}
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