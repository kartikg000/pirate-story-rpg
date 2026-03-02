local Players = game:GetService("Players")

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