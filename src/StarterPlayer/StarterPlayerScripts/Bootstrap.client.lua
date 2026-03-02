-- Bootstrap.client.lua
-- Self-contained: no WaitForChild hangs, no module chain failures
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- ── Immediate visible proof this script ran ──────────────────────────────────
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)

if playerGui then
	local sg = Instance.new("ScreenGui")
	sg.Name = "PirateHud"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 10
	sg.Parent = playerGui

	local function makeLabel(name, y, bg)
		local f = Instance.new("Frame")
		f.Name = name .. "Frame"
		f.BackgroundColor3 = bg or Color3.fromRGB(18, 28, 40)
		f.BackgroundTransparency = 0.15
		f.Size = UDim2.new(0, 420, 0, 34)
		f.Position = UDim2.fromOffset(18, y)
		f.BorderSizePixel = 0
		f.Parent = sg
		local r = Instance.new("UICorner")
		r.CornerRadius = UDim.new(0, 6)
		r.Parent = f
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, -10, 1, 0)
		lbl.Position = UDim2.fromOffset(8, 0)
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 15
		lbl.TextColor3 = Color3.fromRGB(240, 248, 255)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Text = name .. ": loading..."
		lbl.Parent = f
		return lbl
	end

	local hungerLbl  = makeLabel("Hunger",  18)
	local coinsLbl   = makeLabel("Coins",   58)
	local storyLbl   = makeLabel("Story",   98)
	local worldLbl   = makeLabel("World",  138)
	local statusLbl  = makeLabel("Status", 178, Color3.fromRGB(30, 90, 40))
	statusLbl.Text = "Status: Bootstrap OK"

	-- ── Wire remotes once GameRemotes folder exists ───────────────────────────
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 15)
		if not remotes then
			statusLbl.Parent.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
			statusLbl.Text = "Status: GameRemotes not found (server may not have started)"
			return
		end

		statusLbl.Text = "Status: Remotes found — connected"

		local playerStateRemote = remotes:WaitForChild("PlayerStateUpdated", 10)
		local storyStateRemote  = remotes:WaitForChild("StoryStateUpdated",  10)
		local weatherRemote     = remotes:WaitForChild("WeatherStateUpdated", 10)

		if playerStateRemote then
			playerStateRemote.OnClientEvent:Connect(function(p)
				if type(p) ~= "table" then return end
				if type(p.hunger) == "number" then
					hungerLbl.Text = string.format("Hunger: %d / 100", math.floor(p.hunger + 0.5))
				end
				if type(p.coins) == "number" then
					coinsLbl.Text = string.format("Coins: %d", math.floor(p.coins))
				end
			end)
		end

		if storyStateRemote then
			storyStateRemote.OnClientEvent:Connect(function(p)
				if type(p) ~= "table" then return end
				local chapter = type(p.chapter) == "string" and p.chapter or "Story"
				local obj     = type(p.objective) == "string" and p.objective or "..."
				storyLbl.Text = string.format("%s  |  %s", chapter, obj)
			end)
		end

		if weatherRemote then
			weatherRemote.OnClientEvent:Connect(function(p)
				if type(p) ~= "table" then return end
				local w  = type(p.name)      == "string" and p.name      or "?"
				local s  = type(p.season)    == "string" and p.season    or "?"
				local m  = type(p.moonPhase) == "string" and p.moonPhase or "?"
				worldLbl.Text = string.format("World: %s  %s  %s", w, s, m)
			end)
		end

		-- Quest debug keys 1/2/3
		local questRemote = remotes:WaitForChild("RequestQuestAction", 10)
		local KEYS = {
			[Enum.KeyCode.One]   = "steal_chicken",
			[Enum.KeyCode.Two]   = "meet_friends",
			[Enum.KeyCode.Three] = "board_ship",
		}
		if questRemote then
			UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				local action = KEYS[input.KeyCode]
				if action then
					questRemote:FireServer(action)
				end
			end)
		end
	end)
end

