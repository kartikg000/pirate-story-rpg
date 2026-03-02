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

local RemoteService         = require(systemsFolder.RemoteService)
local ProfileService        = require(systemsFolder.ProfileService)
local EconomyService        = require(systemsFolder.EconomyService)
local WeatherService        = require(systemsFolder.WeatherService)
local WorldStateService     = require(systemsFolder.WorldStateService)
local StoryService          = require(systemsFolder.StoryService)
local HungerService         = require(systemsFolder.HungerService)
local WorldBuilderService   = require(systemsFolder.WorldBuilderService)
local CinematicLightingService = require(systemsFolder.CinematicLightingService)
local PowerService          = require(systemsFolder.PowerService)
local ShipService           = require(systemsFolder.ShipService)
local IslandGeneratorService = require(systemsFolder.IslandGeneratorService)

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

local function safeInit(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		warn("[MainServer] FAILED to init " .. name .. ": " .. tostring(err))
	else
		print("[MainServer] OK: " .. name)
	end
end

safeInit("RemoteService",         function() RemoteService.init() end)
safeInit("CinematicLighting",    function() CinematicLightingService.init() end)
safeInit("ProfileAutosave",      function() ProfileService.startAutosaveLoop() end)
safeInit("EconomyService",       function() EconomyService.init(services) end)
safeInit("WeatherService",       function() WeatherService.init(services) end)
safeInit("StoryService",         function() StoryService.init(services) end)
safeInit("HungerService",        function() HungerService.init(services) end)
safeInit("ShipService",           function() ShipService.init(services) end)
safeInit("WorldBuilderService",  function() WorldBuilderService.init(services) end)
safeInit("PowerService",         function() PowerService.init(services) end)
safeInit("IslandGenerator",      function() IslandGeneratorService.init(services) end)

print("[MainServer] All services initialised")

Players.PlayerAdded:Connect(function(player)
	ProfileService.loadProfile(player)
	HungerService.sendCurrentState(services, player)
	StoryService.sendCurrentState(services, player)
end)

for _, player in Players:GetPlayers() do
	ProfileService.loadProfile(player)
	HungerService.sendCurrentState(services, player)
	StoryService.sendCurrentState(services, player)
end