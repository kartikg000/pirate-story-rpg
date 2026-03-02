-- CinematicController.client.lua
-- Client-only: letterbox bars, dynamic DOF, vignette, level-complete title card.
-- Runs alongside the HUD, never conflicts with HudBootstrap.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Camera            = game:GetService("Workspace").CurrentCamera

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared",10):WaitForChild("Net",5):WaitForChild("RemoteNames",5))

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local sg            = Instance.new("ScreenGui")
sg.Name             = "CinematicOverlay"
sg.ResetOnSpawn     = false
sg.DisplayOrder     = 100
sg.IgnoreGuiInset   = true
sg.Parent           = playerGui

-- ── 2.39:1 Letterbox bars ─────────────────────────────────────────────────────
-- Each bar occupies ~10.5% of screen height for a widescreen feel
local topBar        = Instance.new("Frame")
topBar.Name         = "TopBar"
topBar.Size         = UDim2.new(1, 0, 0.105, 0)
topBar.Position     = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topBar.BorderSizePixel  = 0
topBar.ZIndex       = 10
topBar.Parent       = sg

local btmBar        = Instance.new("Frame")
btmBar.Name         = "BtmBar"
btmBar.Size         = UDim2.new(1, 0, 0.105, 0)
btmBar.Position     = UDim2.new(0, 0, 0.895, 0)
btmBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
btmBar.BorderSizePixel  = 0
btmBar.ZIndex       = 10
btmBar.Parent       = sg

-- ── Vignette ──────────────────────────────────────────────────────────────────
local vignette      = Instance.new("ImageLabel")
vignette.Name       = "Vignette"
vignette.Size       = UDim2.new(1, 0, 1, 0)
vignette.BackgroundTransparency = 1
-- Built-in rbxasset circular gradient (dark edges, transparent centre)
vignette.Image      = "rbxassetid://1066952510"
vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
vignette.ImageTransparency = 0.36
vignette.ScaleType  = Enum.ScaleType.Stretch
vignette.ZIndex     = 9
vignette.Parent     = sg

-- ── Depth of Field (client-side Lighting child) ──────────────────────────────
local dof           = Instance.new("DepthOfFieldEffect")
dof.Name            = "CineDOF"
dof.NearIntensity   = 0.6
dof.FarIntensity    = 0.5
dof.FocusDistance   = 30
dof.InFocusRadius   = 28
dof.Parent          = game:GetService("Lighting")

-- Adapt DOF focus to camera--character distance every frame (when away from props)
local dofAdapt = true
local function getDOFTarget()
	local char = player.Character
	if not char then return 30 end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return 30 end
	local dist = (Camera.CFrame.Position - root.Position).Magnitude
	return math.clamp(dist * 0.9, 10, 120)
end

RunService.Heartbeat:Connect(function()
	if not dofAdapt then return end
	local target = getDOFTarget()
	dof.FocusDistance = target
	dof.InFocusRadius = math.clamp(target * 0.55, 12, 60)
end)

-- ── Title card system (Level Complete) ───────────────────────────────────────
local titleHolder   = Instance.new("Frame")
titleHolder.Name    = "TitleCard"
titleHolder.Size    = UDim2.new(1, 0, 1, 0)
titleHolder.BackgroundTransparency = 1
titleHolder.ZIndex  = 15
titleHolder.Visible = false
titleHolder.Parent  = sg

local cinemaFlash   = Instance.new("Frame")
cinemaFlash.Size    = UDim2.new(1,0,1,0)
cinemaFlash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
cinemaFlash.BackgroundTransparency = 1
cinemaFlash.BorderSizePixel = 0
cinemaFlash.ZIndex  = 14
cinemaFlash.Parent  = sg

local titleText     = Instance.new("TextLabel")
titleText.Size      = UDim2.new(0.7, 0, 0, 80)
titleText.Position  = UDim2.new(0.15, 0, 0.38, 0)
titleText.BackgroundTransparency = 1
titleText.TextColor3 = Color3.fromRGB(255, 228, 120)
titleText.Font      = Enum.Font.GothamBold
titleText.TextSize  = 38
titleText.TextStrokeTransparency = 0.4
titleText.TextStrokeColor3 = Color3.fromRGB(0,0,0)
titleText.TextXAlignment = Enum.TextXAlignment.Center
titleText.Text      = ""
titleText.ZIndex    = 16
titleText.Parent    = titleHolder

local subText       = Instance.new("TextLabel")
subText.Size        = UDim2.new(0.7, 0, 0, 40)
subText.Position    = UDim2.new(0.15, 0, 0.52, 0)
subText.BackgroundTransparency = 1
subText.TextColor3  = Color3.fromRGB(200, 255, 200)
subText.Font        = Enum.Font.GothamMedium
subText.TextSize    = 22
subText.TextStrokeTransparency = 0.5
subText.TextStrokeColor3 = Color3.fromRGB(0,0,0)
subText.TextXAlignment = Enum.TextXAlignment.Center
subText.Text        = ""
subText.ZIndex      = 16
subText.Parent      = titleHolder

-- Separator lines (cinematic horizontal bars flanking title)
local lineL         = Instance.new("Frame")
lineL.Size          = UDim2.new(0.2, 0, 0, 2)
lineL.Position      = UDim2.new(0.05, 0, 0.47, 0)
lineL.BackgroundColor3 = Color3.fromRGB(255, 228, 120)
lineL.BorderSizePixel = 0
lineL.ZIndex        = 16
lineL.Parent        = titleHolder
local lineR         = Instance.new("Frame")
lineR.Size          = UDim2.new(0.2, 0, 0, 2)
lineR.Position      = UDim2.new(0.75, 0, 0.47, 0)
lineR.BackgroundColor3 = Color3.fromRGB(255, 228, 120)
lineR.BorderSizePixel = 0
lineR.ZIndex        = 16
lineR.Parent        = titleHolder

local function playTitleCard(title, subtitle)
	titleText.Text  = title
	subText.Text    = subtitle or ""

	-- White flash
	cinemaFlash.BackgroundTransparency = 0.0
	TweenService:Create(cinemaFlash, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}):Play()

	-- Fade in title
	titleHolder.Visible = true
	titleText.TextTransparency    = 1
	subText.TextTransparency      = 1
	lineL.BackgroundTransparency  = 1
	lineR.BackgroundTransparency  = 1
	local fadeIn = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(titleText, fadeIn, {TextTransparency = 0}):Play()
	TweenService:Create(subText,   fadeIn, {TextTransparency = 0}):Play()
	TweenService:Create(lineL,     fadeIn, {BackgroundTransparency = 0}):Play()
	TweenService:Create(lineR,     fadeIn, {BackgroundTransparency = 0}):Play()

	-- Hold, then fade out
	task.delay(3.2, function()
		local fadeOut = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(titleText, fadeOut, {TextTransparency = 1}):Play()
		TweenService:Create(subText,   fadeOut, {TextTransparency = 1}):Play()
		TweenService:Create(lineL,     fadeOut, {BackgroundTransparency = 1}):Play()
		TweenService:Create(lineR,     fadeOut, {BackgroundTransparency = 1}):Play()
		task.delay(0.95, function() titleHolder.Visible = false end)
	end)
end

-- ── Wire LevelComplete remote ─────────────────────────────────────────────────
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 15)
	if not remotes then return end
	local levelCompleteRemote = remotes:WaitForChild(RemoteNames.LevelComplete, 10)
	if not levelCompleteRemote then return end

	levelCompleteRemote.OnClientEvent:Connect(function(data)
		if not data then return end
		playTitleCard(
			data.title or "Level Complete",
			string.format("+ %d coins", data.reward or 0)
		)
	end)
end)
