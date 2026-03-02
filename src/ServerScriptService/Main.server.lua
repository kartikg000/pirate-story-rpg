local Players = game:GetService("Players")

local systemsFolder = script.Parent.Systems

local RemoteService = require(systemsFolder.RemoteService)
local ProfileService = require(systemsFolder.ProfileService)
local EconomyService = require(systemsFolder.EconomyService)
local WeatherService = require(systemsFolder.WeatherService)
local WorldStateService = require(systemsFolder.WorldStateService)
local StoryService = require(systemsFolder.StoryService)
local HungerService = require(systemsFolder.HungerService)

local services = {
	RemoteService = RemoteService,
	ProfileService = ProfileService,
	WorldStateService = WorldStateService,
}

print("[MainServer] Booting PirateStoryRPG services...")

RemoteService.init()
ProfileService.startAutosaveLoop()
EconomyService.init(services)
WeatherService.init(services)
StoryService.init(services)
HungerService.init(services)

print("[MainServer] Services initialized")

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