-- VfxController.client.lua
-- Responds to WeatherStateUpdated and applies client-side VFX:
--   Storm     → screen lightning flash + thunder shake
--   SnowFront → falling snow particles in workspace
--   Tsunami   → red wave warning banner + rumble effect
--   BlueSkyDay/GoldenSunset/etc → clear lingering effects

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Net", 5):WaitForChild("RemoteNames", 5))

-- ── VFX layer ScreenGui ───────────────────────────────────────────────────────
local vfxSg = Instance.new("ScreenGui")
vfxSg.Name          = "PirateVFX"
vfxSg.ResetOnSpawn  = false
vfxSg.DisplayOrder  = 5
vfxSg.IgnoreGuiInset = true
vfxSg.Parent        = playerGui

-- Lightning overlay (full screen flash)
local lightningFrame = Instance.new("Frame")
lightningFrame.Size                 = UDim2.new(1, 0, 1, 0)
lightningFrame.BackgroundColor3     = Color3.fromRGB(220, 240, 255)
lightningFrame.BackgroundTransparency = 1
lightningFrame.BorderSizePixel      = 0
lightningFrame.ZIndex               = 2
lightningFrame.Name                 = "LightningOverlay"
lightningFrame.Parent               = vfxSg

-- Tsunami warning banner
local waveFrame = Instance.new("Frame")
waveFrame.Size               = UDim2.new(1, 0, 0, 64)
waveFrame.Position           = UDim2.new(0, 0, 0, 0)
waveFrame.BackgroundColor3   = Color3.fromRGB(180, 30, 30)
waveFrame.BackgroundTransparency = 0.1
waveFrame.BorderSizePixel    = 0
waveFrame.Visible            = false
waveFrame.Name               = "TsunamiWarning"
waveFrame.Parent             = vfxSg
local waveCorner = Instance.new("UICorner")
waveCorner.Parent = waveFrame
local waveLbl = Instance.new("TextLabel")
waveLbl.Size               = UDim2.new(1, 0, 1, 0)
waveLbl.BackgroundTransparency = 1
waveLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
waveLbl.Font               = Enum.Font.GothamBold
waveLbl.TextSize           = 22
waveLbl.Text               = "⚠️  TSUNAMI WARNING — HIGH GROUND NOW!"
waveLbl.Parent             = waveFrame

-- Color correction for storm (dark + desaturate)
local colorCorrect = Instance.new("ColorCorrectionEffect")
colorCorrect.Name       = "StormCC"
colorCorrect.Brightness = 0
colorCorrect.Contrast   = 0
colorCorrect.Saturation = 0
colorCorrect.Enabled    = false
colorCorrect.Parent     = game:GetService("Lighting")

-- Blur for underwater (Level 4 grotto vibe / storm)
local blur = Instance.new("BlurEffect")
blur.Name   = "StormBlur"
blur.Size   = 0
blur.Parent = game:GetService("Lighting")

-- ── State tracking ────────────────────────────────────────────────────────────
local currentWeather  = ""
local snowFolder      = nil  -- holds snow particle parts
local lightningThread = nil
local shakeConn       = nil

-- ── helpers ───────────────────────────────────────────────────────────────────
local function flash()
	local tw = TweenService:Create(lightningFrame,
		TweenInfo.new(0.04, Enum.EasingStyle.Linear),
		{BackgroundTransparency = 0.2})
	tw:Play()
	tw.Completed:Wait()
	local tw2 = TweenService:Create(lightningFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1})
	tw2:Play()
end

local function startLightning()
	if lightningThread then return end
	lightningThread = task.spawn(function()
		while currentWeather == "Storm" do
			task.wait(math.random(2, 6))
			if currentWeather ~= "Storm" then break end
			flash()
			-- double bolt sometimes
			if math.random() < 0.3 then
				task.wait(0.12)
				flash()
			end
		end
		lightningThread = nil
	end)
end

local function stopLightning()
	currentWeather = ""    -- signal loop to stop
	lightningThread = nil  -- will be GC'd naturally
end

local function createSnow()
	if snowFolder then return end
	local char = player.Character
	if not char then return end
	snowFolder = Instance.new("Folder")
	snowFolder.Name   = "SnowVFX"
	snowFolder.Parent = game:GetService("Workspace")

	-- 5 snow emitter spheres scattered high above
	for i = 1, 5 do
		local emPart = Instance.new("Part")
		emPart.Size         = Vector3.new(1, 1, 1)
		emPart.CFrame       = CFrame.new(math.random(-100, 200), 90, math.random(-50, 60))
		emPart.Anchored     = true
		emPart.Transparency = 1
		emPart.CanCollide   = false
		emPart.Parent       = snowFolder

		local pe = Instance.new("ParticleEmitter")
		pe.Texture        = "rbxassetid://6442506380"   -- built-in snowflake
		pe.Rate           = 80
		pe.Lifetime       = NumberRange.new(4, 7)
		pe.Speed          = NumberRange.new(8, 18)
		pe.SpreadAngle    = Vector2.new(30, 30)
		pe.Rotation       = NumberRange.new(0, 360)
		pe.RotSpeed       = NumberRange.new(-45, 45)
		pe.Size           = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 0.15),
		})
		pe.Transparency   = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		pe.Color          = ColorSequence.new(Color3.fromRGB(210, 230, 255))
		pe.Parent         = emPart
	end
end

local function removeSnow()
	if snowFolder then
		snowFolder:Destroy()
		snowFolder = nil
	end
end

local function applyStorm()
	colorCorrect.Enabled    = true
	colorCorrect.Brightness = -0.08
	colorCorrect.Saturation = -0.5
	TweenService:Create(blur, TweenInfo.new(1.5), {Size = 4}):Play()
	startLightning()
	waveFrame.Visible = false
end

local function applySnow()
	colorCorrect.Enabled    = true
	colorCorrect.Brightness = 0.05
	colorCorrect.Saturation = -0.4
	TweenService:Create(blur, TweenInfo.new(1.5), {Size = 2}):Play()
	createSnow()
	waveFrame.Visible = false
end

local function applyTsunami()
	waveFrame.Visible = true
	colorCorrect.Enabled    = true
	colorCorrect.Brightness = -0.1
	colorCorrect.Saturation = -0.3
	startLightning()
end

local function clearAll()
	stopLightning()
	removeSnow()
	waveFrame.Visible = false
	TweenService:Create(blur, TweenInfo.new(2), {Size = 0}):Play()
	TweenService:Create(colorCorrect,
		TweenInfo.new(2),
		{Brightness = 0, Saturation = 0, Contrast = 0}
	):Play()
	task.delay(2.1, function() colorCorrect.Enabled = false end)
end

-- ── Wire remote ───────────────────────────────────────────────────────────────
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 15)
	if not remotes then return end
	local weatherRemote = remotes:WaitForChild(RemoteNames.WeatherStateUpdated, 10)
	if not weatherRemote then return end

	weatherRemote.OnClientEvent:Connect(function(data)
		if not data then return end

		local weather    = data.name or ""
		local events     = data.activeEvents or {}

		-- Check tsunami override
		local hasTsunami = false
		for _, ev in events do
			if ev == "Tsunami" then hasTsunami = true; break end
		end

		if hasTsunami then
			if currentWeather ~= "Tsunami" then
				currentWeather = "Tsunami"
				task.spawn(applyTsunami)
			end
			return
		end

		if weather == currentWeather then return end
		currentWeather = weather
		clearAll()

		if weather == "Storm" then
			task.spawn(applyStorm)
		elseif weather == "SnowFront" then
			task.spawn(applySnow)
		end
		-- BlueSkyDay, GoldenSunset, PinkSunset, MoonlitNight → just clearAll above
	end)
end)
