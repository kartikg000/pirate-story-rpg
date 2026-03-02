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

local services = {
	RemoteService       = RemoteService,
	ProfileService      = ProfileService,
	WorldStateService   = WorldStateService,
	HungerService       = HungerService,
	StoryService        = StoryService,
}

print("[MainServer] Booting PirateStoryRPG services...")

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
safeInit("WorldBuilderService",  function() WorldBuilderService.init(services) end)

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