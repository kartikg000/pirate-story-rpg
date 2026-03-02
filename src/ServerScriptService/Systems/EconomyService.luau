local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local EconomyService = {}

-- Prices in Berries (stored as profile.coins internally)
local COSMETIC_PRICES = {
	straw_hat    = 0,     -- starter, free
	red_vest     = 200,
	gear2_aura   = 500,
	gear4_coat   = 800,
	jolly_roger  = 150,
	wano_kimono  = 1000,
}

function EconomyService.init(services)
	local remoteService = services.RemoteService
	local profileService = services.ProfileService

	local buyRemote = remoteService.getRemote(RemoteNames.RequestBuyCosmetic)
	buyRemote.OnServerEvent:Connect(function(player, cosmeticId)
		if not remoteService.guard(player) then
			return
		end
		if type(cosmeticId) ~= "string" then
			return
		end

		local price = COSMETIC_PRICES[cosmeticId]
		if not price then
			return
		end

		local profile = profileService.getProfile(player)
		if not profile then
			return
		end
		if profile.unlockedCosmetics[cosmeticId] then
			return
		end

		local spent = profileService.trySpendCoins(player, price)
		if not spent then
			return
		end

		profile.unlockedCosmetics[cosmeticId] = true
	end)
end

return EconomyService
