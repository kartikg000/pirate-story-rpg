local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local QuestDebugController = {}

local ACTION_KEYS = {
	[Enum.KeyCode.One] = "steal_chicken",
	[Enum.KeyCode.Two] = "meet_friends",
	[Enum.KeyCode.Three] = "board_ship",
}

function QuestDebugController.start()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
	local questRemote = remotes:WaitForChild(RemoteNames.RequestQuestAction)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local actionId = ACTION_KEYS[input.KeyCode]
		if not actionId then
			return
		end

		questRemote:FireServer(actionId)
		print(string.format("[QuestDebug] Sent action: %s", actionId))
	end)
end

return QuestDebugController
