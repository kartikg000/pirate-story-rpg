local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local EconomyService = {}

local COSMETIC_PRICES = {
	ocean_coat = 150,
	captain_hat = 220,
	storm_cloak = 300,
	sun_gold_trim = 400,
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
