local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local ProfileService = {}

local STORE_NAME = "PirateStoryRPG_Profile_v1"
local store = DataStoreService:GetDataStore(STORE_NAME)

local profilesByUserId: {[number]: any} = {}
local sessionLocks: {[number]: string} = {}

local function defaultProfile()
	return {
		coins = GameConfig.StarterCoins,
		hunger = GameConfig.MaxHunger,
		unlockedCosmetics = {
			starter_bandana = true,
		},
		equippedCosmetic = "starter_bandana",
		storyLevel = 1,
		storyFlags = {},
		lastLoginUnix = os.time(),
	}
end

local function getKey(userId: number): string
	return string.format("profile_%d", userId)
end

local function withRetry(callback)
	local attempts = 0
	while attempts < 4 do
		attempts += 1
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		task.wait(0.6 * attempts)
	end
	return false, nil
end

function ProfileService.loadProfile(player: Player)
	local lockToken = string.format("%d_%d", player.UserId, os.time())
	sessionLocks[player.UserId] = lockToken

	local success, data = withRetry(function()
		return store:GetAsync(getKey(player.UserId))
	end)

	local profile = data
	if not success or type(profile) ~= "table" then
		profile = defaultProfile()
	end

	profile.lastLoginUnix = os.time()
	profilesByUserId[player.UserId] = profile
end

function ProfileService.getProfile(player: Player)
	return profilesByUserId[player.UserId]
end

function ProfileService.saveProfile(player: Player)
	local profile = profilesByUserId[player.UserId]
	if not profile then
		return
	end

	local expectedLock = sessionLocks[player.UserId]
	if not expectedLock then
		return
	end

	withRetry(function()
		store:UpdateAsync(getKey(player.UserId), function(old)
			if sessionLocks[player.UserId] ~= expectedLock then
				return old
			end
			return profile
		end)
	end)
end

function ProfileService.incrementCoins(player: Player, amount: number)
	local profile = profilesByUserId[player.UserId]
	if not profile then
		return
	end
	profile.coins = math.max(0, profile.coins + amount)
end

function ProfileService.trySpendCoins(player: Player, amount: number): boolean
	local profile = profilesByUserId[player.UserId]
	if not profile then
		return false
	end
	if amount < 0 or profile.coins < amount then
		return false
	end
	profile.coins -= amount
	return true
end

function ProfileService.startAutosaveLoop()
	task.spawn(function()
		while true do
			task.wait(GameConfig.SaveIntervalSeconds)
			for _, player in Players:GetPlayers() do
				ProfileService.saveProfile(player)
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	ProfileService.saveProfile(player)
	profilesByUserId[player.UserId] = nil
	sessionLocks[player.UserId] = nil
end)

return ProfileService
