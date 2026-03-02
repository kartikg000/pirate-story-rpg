local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local HungerService = {}

local TICK_SECONDS = 2

local function clampHunger(value: number): number
	return math.clamp(value, 0, GameConfig.MaxHunger)
end

function HungerService.init(services)
	local remoteService = services.RemoteService
	local profileService = services.ProfileService
	local playerStateRemote = remoteService.getRemote(RemoteNames.PlayerStateUpdated)

	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)

			for _, player in Players:GetPlayers() do
				local profile = profileService.getProfile(player)
				if profile then
					local decay = (GameConfig.HungerDecayPerMinute / 60) * TICK_SECONDS
					profile.hunger = clampHunger(profile.hunger - decay)

					playerStateRemote:FireClient(player, {
						hunger = profile.hunger,
						coins = profile.coins,
						storyLevel = profile.storyLevel,
					})
				end
			end
		end
	end)
end

function HungerService.sendCurrentState(services, player: Player)
	local profile = services.ProfileService.getProfile(player)
	if not profile then
		return
	end

	local playerStateRemote = services.RemoteService.getRemote(RemoteNames.PlayerStateUpdated)
	playerStateRemote:FireClient(player, {
		hunger = profile.hunger,
		coins = profile.coins,
		storyLevel = profile.storyLevel,
	})
end

function HungerService.feedPlayer(services, player: Player, amount: number): boolean
	if amount <= 0 then
		return false
	end

	local profile = services.ProfileService.getProfile(player)
	if not profile then
		return false
	end

	profile.hunger = clampHunger(profile.hunger + amount)
	return true
end

return HungerService
