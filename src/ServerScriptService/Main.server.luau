local Players = game:GetService("Players")

local systemsFolder = script.Parent.Systems

local RemoteService = require(systemsFolder.RemoteService)
local ProfileService = require(systemsFolder.ProfileService)
local EconomyService = require(systemsFolder.EconomyService)
local WeatherService = require(systemsFolder.WeatherService)
local StoryService = require(systemsFolder.StoryService)

local services = {
	RemoteService = RemoteService,
	ProfileService = ProfileService,
}

RemoteService.init()
ProfileService.startAutosaveLoop()
EconomyService.init(services)
WeatherService.init(services)
StoryService.init(services)

Players.PlayerAdded:Connect(function(player)
	ProfileService.loadProfile(player)
end)

for _, player in Players:GetPlayers() do
	ProfileService.loadProfile(player)
end
