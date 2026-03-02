local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- ══════════════════════════════════════════════════════════════════════════════
-- CRITICAL: Create SpawnLocation and safety floor BEFORE any service loads
-- so the player character always has somewhere to land on first spawn.
-- ══════════════════════════════════════════════════════════════════════════════
local function createSpawnFloor()
	-- Safety ground slab (invisible, covers spawn area while world builds)
	local floor = Instance.new("Part")
	floor.Name     = "SafetyFloor"
	floor.Size     = CFrame and Vector3.new(400, 4, 400) or Vector3.new(400, 4, 400)
	floor.CFrame   = CFrame.new(-90, 13, 0)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Transparency = 1          -- invisible; world geometry will cover it
	floor.BrickColor = BrickColor.new("Medium green")
	floor.Parent   = Workspace

	-- SpawnLocation sitting on top of the safety floor
	local sp = Instance.new("SpawnLocation")
	sp.Name       = "SpawnLocation"
	sp.Size       = Vector3.new(16, 1, 16)
	sp.CFrame     = CFrame.new(-90, 16, 10)
	sp.BrickColor = BrickColor.new("Bright yellow")
	sp.Neutral    = true
	sp.Duration   = 0
	sp.Anchored   = true
	sp.Transparency = 1            -- hidden; world geometry covers it
	sp.Parent     = Workspace
end
createSpawnFloor()

local systemsFolder = script.Parent.Systems

local function safeRequire(name)
	local ok, result = pcall(require, systemsFolder[name])
	if not ok then
		warn("[MainServer] FAILED to require " .. name .. ": " .. tostring(result))
		return nil
	end
	print("[MainServer] required " .. name)
	return result
end

local RemoteService         = safeRequire("RemoteService")
local ProfileService        = safeRequire("ProfileService")
local EconomyService        = safeRequire("EconomyService")
local WeatherService        = safeRequire("WeatherService")
local WorldStateService     = safeRequire("WorldStateService")
local StoryService          = safeRequire("StoryService")
local HungerService         = safeRequire("HungerService")
local WorldBuilderService   = safeRequire("WorldBuilderService")
local CinematicLightingService = safeRequire("CinematicLightingService")
local PowerService          = safeRequire("PowerService")
local ShipService           = safeRequire("ShipService")
local IslandGeneratorService = safeRequire("IslandGeneratorService")

local services = {
	RemoteService       = RemoteService,
	ProfileService      = ProfileService,
	WorldStateService   = WorldStateService,
	HungerService       = HungerService,
	StoryService        = StoryService,
	PowerService        = PowerService,
	ShipService         = ShipService,
	IslandGeneratorService = IslandGeneratorService,
}

print("[MainServer] Booting One Piece RPG services...")

local function safeInit(name, svc, fn)
	if not svc then warn("[MainServer] SKIP (nil) " .. name); return end
	local ok, err = pcall(fn)
	if not ok then
		warn("[MainServer] FAILED to init " .. name .. ": " .. tostring(err))
	else
		print("[MainServer] OK: " .. name)
	end
end

safeInit("RemoteService",        RemoteService,           function() RemoteService.init() end)
safeInit("CinematicLighting",    CinematicLightingService,function() CinematicLightingService.init() end)
safeInit("ProfileAutosave",      ProfileService,          function() ProfileService.startAutosaveLoop() end)
safeInit("EconomyService",       EconomyService,          function() EconomyService.init(services) end)
safeInit("WeatherService",       WeatherService,          function() WeatherService.init(services) end)
safeInit("StoryService",         StoryService,            function() StoryService.init(services) end)
safeInit("HungerService",        HungerService,           function() HungerService.init(services) end)
safeInit("ShipService",          ShipService,             function() ShipService.init(services) end)
safeInit("WorldBuilderService",  WorldBuilderService,     function() WorldBuilderService.init(services) end)
safeInit("PowerService",         PowerService,            function() PowerService.init(services) end)
safeInit("IslandGenerator",      IslandGeneratorService,  function() IslandGeneratorService.init(services) end)

print("[MainServer] All services initialised")

Players.PlayerAdded:Connect(function(player)
	if ProfileService  then ProfileService.loadProfile(player) end
	if HungerService   then HungerService.sendCurrentState(services, player) end
	if StoryService    then StoryService.sendCurrentState(services, player) end
end)

for _, player in Players:GetPlayers() do
	if ProfileService  then ProfileService.loadProfile(player) end
	if HungerService   then HungerService.sendCurrentState(services, player) end
	if StoryService    then StoryService.sendCurrentState(services, player) end
end