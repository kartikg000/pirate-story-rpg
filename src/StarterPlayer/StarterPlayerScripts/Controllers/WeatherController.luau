local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local WeatherController = {}

function WeatherController.start()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
	local weatherRemote = remotes:WaitForChild(RemoteNames.WeatherStateUpdated)

	weatherRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if type(payload.name) ~= "string" then
			return
		end
		print(string.format("[Weather] %s | Clock %.2f", payload.name, payload.clockTime or -1))
	end)
end

return WeatherController
