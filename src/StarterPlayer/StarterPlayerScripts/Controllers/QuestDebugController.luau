local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local QuestDebugController = {}

local ACTION_KEYS = {
	[Enum.KeyCode.One]   = "find_hat",
	[Enum.KeyCode.Two]   = "meet_zoro",
	[Enum.KeyCode.Three] = "recruit_usopp",
	[Enum.KeyCode.Four]  = "stop_krieg",
	[Enum.KeyCode.Five]  = "recruit_sanji",
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
