-- ShipController.client.lua
-- Handles player-side ship steering when at the ship's helm.
-- Listens for ShipBoarded / ShipLeft remotes from ShipService.
-- Sends throttle+steer via ShipControl remote every frame while on ship.

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local playerGui = lp:WaitForChild("PlayerGui")

-- ── Wait for RemoteService remotes ───────────────────────────────────────────
local remotesFolder = ReplicatedStorage:WaitForChild("GameRemotes", 20)

local function getRemote(name)
	if not remotesFolder then return nil end
	return remotesFolder:WaitForChild(name, 10)
end

local shipControlRemote = getRemote("ShipControl")
local shipBoardedRemote = getRemote("ShipBoarded")
local shipLeftRemote    = getRemote("ShipLeft")

-- ── HUD ───────────────────────────────────────────────────────────────────────
local function buildHud()
	local sg = Instance.new("ScreenGui")
	sg.Name            = "ShipHud"
	sg.ResetOnSpawn    = false
	sg.Enabled         = false
	sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	sg.Parent          = playerGui

	local frame = Instance.new("Frame")
	frame.Name             = "HelmFrame"
	frame.Size             = UDim2.new(0, 260, 0, 90)
	frame.Position         = UDim2.new(0.5, -130, 1, -120)
	frame.BackgroundColor3 = Color3.fromRGB(8, 16, 32)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel  = 0
	frame.Parent           = sg
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

	-- Title label
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.4, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(255, 220, 60)
	title.Font       = Enum.Font.GothamBold
	title.TextSize   = 15
	title.Text       = "⚓ At the Helm — Going Merry"
	title.Parent     = frame

	-- Controls hint
	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, -10, 0.35, 0)
	hint.Position = UDim2.new(0, 5, 0.42, 0)
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Color3.fromRGB(175, 210, 255)
	hint.Font       = Enum.Font.Gotham
	hint.TextSize   = 13
	hint.Text       = "W/S — Throttle   •   A/D — Steer   •   [E] Exit"
	hint.Parent     = frame

	-- Speed readout
	local speed = Instance.new("TextLabel")
	speed.Name = "SpeedLabel"
	speed.Size = UDim2.new(1, -10, 0.3, 0)
	speed.Position = UDim2.new(0, 5, 0.7, 0)
	speed.BackgroundTransparency = 1
	speed.TextColor3 = Color3.fromRGB(120, 240, 120)
	speed.Font       = Enum.Font.GothamMono
	speed.TextSize   = 13
	speed.Text       = "Throttle: 0   Steer: 0"
	speed.Parent     = frame

	return sg, speed
end

local helmGui, speedLabel = buildHud()

-- ── State ─────────────────────────────────────────────────────────────────────
local onShip  = false
local throttle = 0
local steer    = 0
local sendConn = nil

local function setHudVisible(visible)
	helmGui.Enabled = visible
end

-- ── Input helpers ─────────────────────────────────────────────────────────────
local KEY_BIND = {
	[Enum.KeyCode.W] = function() throttle =  1 end,
	[Enum.KeyCode.S] = function() throttle = -1 end,
	[Enum.KeyCode.A] = function() steer    = -1 end,
	[Enum.KeyCode.D] = function() steer    =  1 end,
}
local KEY_RESET = {
	[Enum.KeyCode.W] = function() if throttle ==  1 then throttle = 0 end end,
	[Enum.KeyCode.S] = function() if throttle == -1 then throttle = 0 end end,
	[Enum.KeyCode.A] = function() if steer    == -1 then steer    = 0 end end,
	[Enum.KeyCode.D] = function() if steer    ==  1 then steer    = 0 end end,
}

local inputBeganConn, inputEndedConn

local function attachInput()
	inputBeganConn = UserInputService.InputBegan:Connect(function(inp, processed)
		if processed or _G.DialogueOpen then return end
		local fn = KEY_BIND[inp.KeyCode]
		if fn then fn() end
	end)
	inputEndedConn = UserInputService.InputEnded:Connect(function(inp)
		local fn = KEY_RESET[inp.KeyCode]
		if fn then fn() end
	end)
end

local function detachInput()
	if inputBeganConn then inputBeganConn:Disconnect() inputBeganConn = nil end
	if inputEndedConn then inputEndedConn:Disconnect() inputEndedConn = nil end
	throttle = 0; steer = 0
end

-- Send ship control to server at regular intervals
local SEND_RATE = 0.05
local sendAcc = 0

local function startSendLoop()
	if sendConn then sendConn:Disconnect() end
	sendConn = RunService.Heartbeat:Connect(function(dt)
		if not onShip then return end
		if _G.DialogueOpen then throttle = 0; steer = 0 end
		sendAcc = sendAcc + dt
		if sendAcc < SEND_RATE then return end
		sendAcc = 0
		if shipControlRemote then
			shipControlRemote:FireServer({throttle = throttle, steer = steer})
		end
		if speedLabel then
			speedLabel.Text = ("Throttle: %d   Steer: %d"):format(throttle, steer)
		end
	end)
end

local function stopSendLoop()
	if sendConn then sendConn:Disconnect() sendConn = nil end
	-- final zero command so ship stops
	if shipControlRemote then
		shipControlRemote:FireServer({throttle = 0, steer = 0})
	end
end

-- ── Boarding / leaving callbacks ──────────────────────────────────────────────
local function onBoarded()
	onShip = true
	setHudVisible(true)
	attachInput()
	startSendLoop()
end

local function onLeft()
	if not onShip then return end
	onShip = false
	detachInput()
	stopSendLoop()
	setHudVisible(false)
end

-- ── Remote listeners ─────────────────────────────────────────────────────────
if shipBoardedRemote then
	shipBoardedRemote.OnClientEvent:Connect(function()
		onBoarded()
	end)
end

if shipLeftRemote then
	shipLeftRemote.OnClientEvent:Connect(function()
		onLeft()
	end)
end

-- Clean up if character respawns (auto-disembarks)
lp.CharacterAdded:Connect(function()
	onLeft()
end)

print("[ShipController] Ready — waiting for ShipBoarded signal")
