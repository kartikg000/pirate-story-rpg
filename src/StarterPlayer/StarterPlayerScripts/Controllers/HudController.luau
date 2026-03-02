local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local HudController = {}

local function makeLabel(parent: Instance, name: string, yPos: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(20, 28, 36)
	label.TextColor3 = Color3.fromRGB(235, 240, 255)
	label.Size = UDim2.new(0, 420, 0, 32)
	label.Position = UDim2.fromOffset(18, yPos)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "..."
	label.Parent = parent
	return label
end

function HudController.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes")

	local playerStateRemote = remotes:WaitForChild(RemoteNames.PlayerStateUpdated)
	local storyStateRemote = remotes:WaitForChild(RemoteNames.StoryStateUpdated)
	local weatherRemote = remotes:WaitForChild(RemoteNames.WeatherStateUpdated)

	local gui = Instance.new("ScreenGui")
	gui.Name = "PirateHud"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local hungerLabel = makeLabel(gui, "HungerLabel", 18)
	local coinsLabel = makeLabel(gui, "CoinsLabel", 56)
	local storyLabel = makeLabel(gui, "StoryLabel", 94)
	local worldLabel = makeLabel(gui, "WorldLabel", 132)

	hungerLabel.Text = "Hunger: --"
	coinsLabel.Text = "Coins: --"
	storyLabel.Text = "Objective: Loading..."
	worldLabel.Text = "World: Loading..."

	playerStateRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end

		if type(payload.hunger) == "number" then
			hungerLabel.Text = string.format("Hunger: %d/%d", math.floor(payload.hunger + 0.5), 100)
		end
		if type(payload.coins) == "number" then
			coinsLabel.Text = string.format("Coins: %d", math.floor(payload.coins))
		end
	end)

	storyStateRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		local chapter = type(payload.chapter) == "string" and payload.chapter or "Story"
		local objective = type(payload.objective) == "string" and payload.objective or "No objective"
		storyLabel.Text = string.format("%s | %s", chapter, objective)
	end)

	weatherRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		local weather = type(payload.name) == "string" and payload.name or "Unknown"
		local season = type(payload.season) == "string" and payload.season or "Unknown"
		local moon = type(payload.moonPhase) == "string" and payload.moonPhase or "Unknown"
		worldLabel.Text = string.format("World: %s | %s | %s", weather, season, moon)
	end)
end

return HudController
