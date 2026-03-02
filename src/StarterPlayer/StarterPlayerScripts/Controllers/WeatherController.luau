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

		local season = type(payload.season) == "string" and payload.season or "UnknownSeason"
		local moonPhase = type(payload.moonPhase) == "string" and payload.moonPhase or "UnknownMoon"
		local events = "none"
		if type(payload.activeEvents) == "table" and #payload.activeEvents > 0 then
			events = table.concat(payload.activeEvents, ",")
		end

		print(string.format(
			"[World] Weather=%s Clock=%.2f Season=%s Moon=%s Events=%s",
			payload.name,
			payload.clockTime or -1,
			season,
			moonPhase,
			events
		))
	end)
end

return WeatherController
