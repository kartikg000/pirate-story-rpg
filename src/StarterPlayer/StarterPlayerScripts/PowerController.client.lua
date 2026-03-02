-- PowerController.client.lua  (One Piece Edition)
-- Handles local ability input, stamina / cooldown display, and VFX for the player.
-- Keys: Q = Pistol, E = Bazooka, R = Gatling, F = Gear2, G = Gear3, V = Gear4, C = Conquerors, X = Gear5

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local player      = Players.LocalPlayer
local playerGui   = player.PlayerGui

-- ══════════════════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════════════════
local stamina    = 100
local cooldowns  = {}   -- abilityId → remaining seconds (updated from server)

-- Local optimistic cooldowns (so input feels instant even before server echo)
local localCooldownEnd = {}   -- abilityId → tick() end time

-- Map keys to ability IDs
local KEY_MAP = {
	Q = "pistol",
	E = "bazooka",
	R = "gatling",
	F = "gear2",
	G = "gear3",
	V = "gear4",
	C = "conquerors",
	X = "gear5",
}

-- Gear VFX colour palette
local VFX_COLORS = {
	pistol     = Color3.fromRGB(255, 220, 100),
	bazooka    = Color3.fromRGB(255, 140, 40),
	gatling    = Color3.fromRGB(255, 80, 20),
	gear2      = Color3.fromRGB(200, 40, 40),   -- red steam
	gear3      = Color3.fromRGB(80, 200, 255),  -- blue inflate
	gear4      = Color3.fromRGB(30, 30, 80),    -- dark armament
	conquerors = Color3.fromRGB(100, 50, 150),  -- purple lightning
	gear5      = Color3.fromRGB(255, 255, 255), -- white/gold sun
}

-- Dialogue-open guard (set by DialogueController if present)
-- PowerController reads _G.DialogueOpen to avoid blocking E key
-- (same integration used by the original E-key fix)

-- ══════════════════════════════════════════════════════════════════════════════
-- VFX
-- ══════════════════════════════════════════════════════════════════════════════
local function flashScreen(color, alpha, duration)
	local gui = playerGui:FindFirstChild("PowerGui")
	if not gui then return end
	local flash = gui:FindFirstChild("FlashFrame")
	if not flash then return end
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - alpha
	TweenService:Create(flash, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	}):Play()
end

local function applyLocalVfx(abilityId)
	local char = player.Character
	if not char then return end

	local color = VFX_COLORS[abilityId] or Color3.fromRGB(255,255,255)

	if abilityId == "gear2" then
		-- Red steam particle burst on character
		flashScreen(Color3.fromRGB(180,30,30), 0.4, 1.2)
		-- Temporarily tint humanoid parts red
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				local orig = part.Color
				part.Color = Color3.fromRGB(200, 80, 80)
				task.delay(15, function() part.Color = orig end)
			end
		end

	elseif abilityId == "gear3" then
		-- Scale up right arm briefly
		flashScreen(Color3.fromRGB(60, 140, 220), 0.4, 0.8)
		local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
		if arm then
			local orig = arm.Size
			TweenService:Create(arm, TweenInfo.new(0.3), {Size = orig * 3}):Play()
			task.delay(2, function()
				TweenService:Create(arm, TweenInfo.new(0.5), {Size = orig}):Play()
			end)
		end

	elseif abilityId == "gear4" then
		-- Dark armament overlay
		flashScreen(Color3.fromRGB(10,10,30), 0.6, 1.5)
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				local orig = part.Color
				part.Color = Color3.fromRGB(20, 20, 50)
				task.delay(30, function() part.Color = orig end)
			end
		end

	elseif abilityId == "conquerors" then
		-- Purple lightning flash
		flashScreen(Color3.fromRGB(80, 0, 120), 0.7, 0.6)
		task.delay(0.1, function() flashScreen(Color3.fromRGB(210, 160, 255), 0.5, 0.8) end)

	elseif abilityId == "gear5" then
		-- Full white flash → golden tint
		flashScreen(Color3.fromRGB(255, 255, 255), 1, 0.2)
		task.delay(0.3, function()
			flashScreen(Color3.fromRGB(255, 220, 50), 0.7, 2)
		end)
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				local orig = part.Color
				part.Color = Color3.fromRGB(255, 235, 180)
				task.delay(60, function() part.Color = orig end)
			end
		end

	else
		-- Generic quick flash
		flashScreen(color, 0.3, 0.4)
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- POWER HUD  (stamina bar + ability icons row)
-- ══════════════════════════════════════════════════════════════════════════════
local function buildPowerGui()
	local existingGui = playerGui:FindFirstChild("PowerGui")
	if existingGui then existingGui:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name            = "PowerGui"
	gui.ResetOnSpawn    = false
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	gui.Parent          = playerGui

	-- Full-screen flash frame
	local flash = Instance.new("Frame")
	flash.Name                   = "FlashFrame"
	flash.Size                   = UDim2.fromScale(1, 1)
	flash.Position               = UDim2.fromScale(0, 0)
	flash.BackgroundColor3       = Color3.new(1,1,1)
	flash.BackgroundTransparency = 1
	flash.ZIndex                 = 100
	flash.Parent                 = gui

	-- Stamina bar background
	local staminaBg = Instance.new("Frame")
	staminaBg.Name                   = "StaminaBg"
	staminaBg.Size                   = UDim2.new(0, 200, 0, 14)
	staminaBg.Position               = UDim2.new(0, 16, 0, 200)
	staminaBg.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
	staminaBg.BackgroundTransparency = 0.3
	staminaBg.Parent                 = gui
	Instance.new("UICorner", staminaBg).CornerRadius = UDim.new(0, 6)

	-- Stamina bar fill
	local staminaFill = Instance.new("Frame")
	staminaFill.Name              = "StaminaFill"
	staminaFill.Size              = UDim2.new(1, 0, 1, 0)
	staminaFill.BackgroundColor3  = Color3.fromRGB(50, 200, 80)
	staminaFill.Parent            = staminaBg
	Instance.new("UICorner", staminaFill).CornerRadius = UDim.new(0, 6)

	local staminaLabel = Instance.new("TextLabel")
	staminaLabel.Name                   = "StaminaLabel"
	staminaLabel.Size                   = UDim2.new(0, 200, 0, 14)
	staminaLabel.Position               = UDim2.new(0, 16, 0, 185)
	staminaLabel.Text                   = "STAMINA"
	staminaLabel.TextColor3             = Color3.new(1,1,1)
	staminaLabel.TextSize               = 10
	staminaLabel.Font                   = Enum.Font.GothamBold
	staminaLabel.BackgroundTransparency = 1
	staminaLabel.Parent                 = gui

	-- Ability hotkey hints (a horizontal strip above stamina)
	local hints = {
		{"Q","Pistol"}, {"E","Bazooka"}, {"R","Gatling"},
		{"F","Gear2"},  {"G","Gear3"},   {"V","Gear4"},
		{"C","CoqHaki"},{"X","Gear5"},
	}
	local hintRow = Instance.new("Frame")
	hintRow.Name                   = "HintRow"
	hintRow.Size                   = UDim2.new(0, 16*8 + 4*7, 0, 36)
	hintRow.Position               = UDim2.new(0, 16, 0, 218)
	hintRow.BackgroundTransparency = 1
	hintRow.Parent                 = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding       = UDim.new(0, 4)
	layout.Parent        = hintRow

	for _, pair in hints do
		local key = pair[1]
		local lbl = pair[2]
		local box = Instance.new("Frame")
		box.Name                   = key
		box.Size                   = UDim2.new(0, 40, 0, 36)
		box.BackgroundColor3       = Color3.fromRGB(20,20,20)
		box.BackgroundTransparency = 0.3
		box.Parent                 = hintRow
		Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Size                   = UDim2.new(1, 0, 0.5, 0)
		keyLabel.Position               = UDim2.new(0,0,0,0)
		keyLabel.Text                   = key
		keyLabel.TextColor3             = Color3.fromRGB(255, 220, 60)
		keyLabel.TextSize               = 12
		keyLabel.Font                   = Enum.Font.GothamBold
		keyLabel.BackgroundTransparency = 1
		keyLabel.Parent                 = box

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name                  = "NameLabel"
		nameLabel.Size                  = UDim2.new(1, 0, 0.5, 0)
		nameLabel.Position              = UDim2.new(0,0,0.5,0)
		nameLabel.Text                  = lbl
		nameLabel.TextColor3            = Color3.fromRGB(180,180,180)
		nameLabel.TextSize              = 8
		nameLabel.Font                  = Enum.Font.Gotham
		nameLabel.BackgroundTransparency= 1
		nameLabel.Parent                = box

		-- cooldown overlay
		local cdOverlay = Instance.new("Frame")
		cdOverlay.Name                   = "CdOverlay"
		cdOverlay.Size                   = UDim2.new(1, 0, 1, 0)
		cdOverlay.BackgroundColor3       = Color3.new(0,0,0)
		cdOverlay.BackgroundTransparency = 1
		cdOverlay.ZIndex                 = 5
		cdOverlay.Parent                 = box
		Instance.new("UICorner", cdOverlay).CornerRadius = UDim.new(0, 5)
	end

	return gui
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UPDATE HUD  called every heartbeat
-- ══════════════════════════════════════════════════════════════════════════════
local function updateHud()
	local gui  = playerGui:FindFirstChild("PowerGui")
	if not gui then return end

	-- Stamina bar
	local fill = gui:FindFirstChild("StaminaBg") and gui.StaminaBg:FindFirstChild("StaminaFill")
	if fill then
		fill.Size = UDim2.new(stamina / 100, 0, 1, 0)
		fill.BackgroundColor3 = stamina > 60 and Color3.fromRGB(50,200,80)
			or stamina > 30 and Color3.fromRGB(220,180,30)
			or Color3.fromRGB(200,40,40)
	end

	-- Cooldown overlays
	local now  = tick()
	local row  = gui:FindFirstChild("HintRow")
	if not row then return end
	for key, abilityId in KEY_MAP do
		local box = row:FindFirstChild(key)
		if box then
			local cdOverlay = box:FindFirstChild("CdOverlay")
			if cdOverlay then
				local endTime = localCooldownEnd[abilityId] or 0
				local remaining = math.max(0, endTime - now)
				local maxCd = cooldowns[abilityId] or 0
				if remaining > 0 then
					cdOverlay.BackgroundTransparency = 0.5
				else
					cdOverlay.BackgroundTransparency = 1
				end
			end
		end
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ABILITY LOOKUP FROM CONFIG (to know which abilities are unlocked)
-- ══════════════════════════════════════════════════════════════════════════════
-- We keep a local list of unlocked flags received via LevelComplete / PowerStateUpdated
local unlockedFlags = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- INPUT
-- ══════════════════════════════════════════════════════════════════════════════
local function onInput(input, gameProcessed)
	if gameProcessed then return end
	if _G.DialogueOpen then return end  -- respect dialogue guard

	local keyName = input.KeyCode.Name
	local abilityId = KEY_MAP[keyName]
	if not abilityId then return end

	-- Optimistic local cooldown gate (server is authoritative but this prevents spam)
	local now = tick()
	if localCooldownEnd[abilityId] and localCooldownEnd[abilityId] > now then
		return
	end

	-- Optimistic cooldown set (rough; gets corrected by server echo)
	localCooldownEnd[abilityId] = now + 1.5  -- short local block

	-- Send request to server
	if _G.AbilityRemote then
		_G.AbilityRemote:FireServer(abilityId)
	end

	-- Immediate local VFX
	applyLocalVfx(abilityId)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- REMOTE LISTENERS
-- ══════════════════════════════════════════════════════════════════════════════
local function listenRemotes()
	-- Wait for remotes folder
	local Remotes = ReplicatedStorage:WaitForChild("GameRemotes", 10)
	if not Remotes then return end

	-- PowerStateUpdated — stamina + cooldown sync from server
	local powerUpdated = Remotes:WaitForChild(RemoteNames.PowerStateUpdated, 10)
	if powerUpdated then
		powerUpdated.OnClientEvent:Connect(function(payload)
			if payload.stamina then stamina = payload.stamina end
			if payload.cooldowns then
				local now = tick()
				for id, remaining in payload.cooldowns do
					cooldowns[id] = remaining
					localCooldownEnd[id] = now + remaining
				end
			end
		end)
	end

	-- LevelComplete — pick up powerUnlock flags
	local levelComplete = Remotes:WaitForChild("LevelComplete", 10)
	if levelComplete then
		levelComplete.OnClientEvent:Connect(function(data)
			if data and data.powerUnlock then
				unlockedFlags[data.powerUnlock] = true
			end
		end)
	end

	-- RequestUseAbility remote (for firing ability to server)
	_G.AbilityRemote = Remotes:WaitForChild(RemoteNames.RequestUseAbility, 10)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════════════════════════════════════════
local powerGui = buildPowerGui()

-- Heartbeat HUD update
RunService.Heartbeat:Connect(updateHud)

-- Input
UserInputService.InputBegan:Connect(onInput)

-- Remotes
task.spawn(listenRemotes)

print("[PowerController] One Piece ability system ready")
