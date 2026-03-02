-- Bootstrap.client.lua
-- Cinematic game HUD — hunger bar, coins, objective, world info, level badge.
-- Self-contained: no WaitForChild hangs, no module chain failures.
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

-- ── ScreenGui ─────────────────────────────────────────────────────────────────
local sg            = Instance.new("ScreenGui")
sg.Name             = "PirateHud"
sg.ResetOnSpawn     = false
sg.DisplayOrder     = 10
sg.IgnoreGuiInset   = true
sg.Parent           = playerGui

-- ── helper: rounded panel ────────────────────────────────────────────────────
local function panel(name, size, pos, bgColor, bgTrans, parent)
	local f = Instance.new("Frame")
	f.Name                 = name
	f.Size                 = size
	f.Position             = pos
	f.BackgroundColor3     = bgColor or Color3.fromRGB(8, 14, 26)
	f.BackgroundTransparency = bgTrans or 0.12
	f.BorderSizePixel      = 0
	f.Parent               = parent or sg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = f
	return f
end

local function label(parent, text, size, color, font, xalign)
	local l = Instance.new("TextLabel")
	l.Size               = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text               = text
	l.TextSize           = size or 16
	l.TextColor3         = color or Color3.fromRGB(220, 226, 240)
	l.Font               = font  or Enum.Font.GothamMedium
	l.TextXAlignment     = xalign or Enum.TextXAlignment.Left
	l.TextWrapped        = true
	l.Parent             = parent
	return l
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BOTTOM-LEFT: Hunger + Coins stack
-- ══════════════════════════════════════════════════════════════════════════════
local bottomLeft = Instance.new("Frame")
bottomLeft.Size               = UDim2.new(0, 240, 0, 90)
bottomLeft.Position           = UDim2.new(0, 18, 1, -110)
bottomLeft.BackgroundTransparency = 1
bottomLeft.Parent             = sg

-- ── Hunger panel ─────────────────────────────────────────────────────────────
local hungerPanel = panel("HungerPanel", UDim2.new(1,0,0,40), UDim2.new(0,0,0,0), Color3.fromRGB(8,14,26), 0.12, bottomLeft)
-- Icon
local hungerIcon = Instance.new("TextLabel")
hungerIcon.Size              = UDim2.new(0, 28, 1, 0)
hungerIcon.BackgroundTransparency = 1
hungerIcon.Text              = "🍖"
hungerIcon.TextSize          = 18
hungerIcon.Font              = Enum.Font.GothamMedium
hungerIcon.TextXAlignment    = Enum.TextXAlignment.Center
hungerIcon.Parent            = hungerPanel

-- Bar track
local barTrack = Instance.new("Frame")
barTrack.Size              = UDim2.new(1, -88, 0, 10)
barTrack.Position          = UDim2.new(0, 30, 0, 8)
barTrack.BackgroundColor3  = Color3.fromRGB(30, 40, 55)
barTrack.BorderSizePixel   = 0
barTrack.Parent            = hungerPanel
local btCorner = Instance.new("UICorner"); btCorner.CornerRadius = UDim.new(0,5); btCorner.Parent = barTrack

-- Bar fill
local barFill = Instance.new("Frame")
barFill.Name             = "HungerFill"
barFill.Size             = UDim2.new(1, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(240, 130, 50)
barFill.BorderSizePixel  = 0
barFill.Parent           = barTrack
local bfCorner = Instance.new("UICorner"); bfCorner.CornerRadius = UDim.new(0,5); bfCorner.Parent = barFill

-- Hunger number
local hungerNum = label(hungerPanel, "100/100", 13, Color3.fromRGB(220,160,80))
hungerNum.Size     = UDim2.new(0, 52, 1, 0)
hungerNum.Position = UDim2.new(1, -54, 0, 0)
hungerNum.TextXAlignment = Enum.TextXAlignment.Right

-- ── Coins panel ──────────────────────────────────────────────────────────────
local coinsPanel = panel("CoinsPanel", UDim2.new(1,0,0,36), UDim2.new(0,0,0,46), Color3.fromRGB(8,14,26), 0.12, bottomLeft)
local coinsIcon = Instance.new("TextLabel")
coinsIcon.Size             = UDim2.new(0, 28, 1, 0)
coinsIcon.BackgroundTransparency = 1
coinsIcon.Text             = "🪙"
coinsIcon.TextSize         = 18
coinsIcon.Font             = Enum.Font.GothamMedium
coinsIcon.TextXAlignment   = Enum.TextXAlignment.Center
coinsIcon.Parent           = coinsPanel
local coinsLbl = label(coinsPanel, "50", 18, Color3.fromRGB(255, 215, 60), Enum.Font.GothamBold)
coinsLbl.Size     = UDim2.new(1, -36, 1, 0)
coinsLbl.Position = UDim2.fromOffset(32, 0)

-- ══════════════════════════════════════════════════════════════════════════════
-- TOP-LEFT: Level badge
-- ══════════════════════════════════════════════════════════════════════════════
local lvlPanel = panel("LevelPanel", UDim2.new(0, 110, 0, 44), UDim2.new(0, 18, 0, 18),
	Color3.fromRGB(20, 40, 80), 0.08)
-- Gold left accent
local lvlAccent = Instance.new("Frame")
lvlAccent.Size             = UDim2.new(0, 3, 0.6, 0)
lvlAccent.Position         = UDim2.new(0, 8, 0.2, 0)
lvlAccent.BackgroundColor3 = Color3.fromRGB(255, 215, 60)
lvlAccent.BorderSizePixel  = 0
lvlAccent.Parent           = lvlPanel
local lvlC = Instance.new("UICorner"); lvlC.CornerRadius = UDim.new(0,2); lvlC.Parent = lvlAccent
local lvlTop = label(lvlPanel, "LEVEL", 9, Color3.fromRGB(160,170,200), Enum.Font.GothamBold)
lvlTop.Size     = UDim2.new(1, -18, 0, 16)
lvlTop.Position = UDim2.fromOffset(16, 4)
local lvlNum = label(lvlPanel, "1", 22, Color3.fromRGB(255, 215, 60), Enum.Font.GothamBold)
lvlNum.Size     = UDim2.new(1, -16, 0, 24)
lvlNum.Position = UDim2.fromOffset(16, 18)

-- ══════════════════════════════════════════════════════════════════════════════
-- TOP-CENTER: Objective bar
-- ══════════════════════════════════════════════════════════════════════════════
local objPanel = panel("ObjectivePanel", UDim2.new(0, 550, 0, 58), UDim2.new(0.5, -275, 0, 14),
	Color3.fromRGB(8, 14, 26), 0.08)
local objChapter = label(objPanel, "Chapter", 11, Color3.fromRGB(255, 215, 60), Enum.Font.GothamBold)
objChapter.Size     = UDim2.new(1, -16, 0, 18)
objChapter.Position = UDim2.fromOffset(14, 4)
objChapter.TextXAlignment = Enum.TextXAlignment.Center
local objText = label(objPanel, "Walk to a glowing zone to begin.", 14, Color3.fromRGB(220, 226, 240), Enum.Font.GothamMedium)
objText.Size     = UDim2.new(1, -16, 0, 26)
objText.Position = UDim2.fromOffset(8, 24)
objText.TextXAlignment = Enum.TextXAlignment.Center

-- Tip sub-line
local objTip = label(objPanel, "Press [E] near objects or NPCs to interact", 11, Color3.fromRGB(130, 145, 170))
objTip.Size     = UDim2.new(1, -16, 0, 14)
objTip.Position = UDim2.fromOffset(8, 44)
objTip.TextXAlignment = Enum.TextXAlignment.Center

-- ══════════════════════════════════════════════════════════════════════════════
-- TOP-RIGHT: World info (weather / season / moon)
-- ══════════════════════════════════════════════════════════════════════════════
local worldPanel = panel("WorldPanel", UDim2.new(0, 220, 0, 58), UDim2.new(1, -238, 0, 14),
	Color3.fromRGB(8, 14, 26), 0.12)
local worldWeather = label(worldPanel, "🌤  BlueSkyDay", 13, Color3.fromRGB(160, 200, 255))
worldWeather.Size     = UDim2.new(1, -10, 0, 20)
worldWeather.Position = UDim2.fromOffset(8, 4)
local worldSeason = label(worldPanel, "🌱 Summer  🌕 FullMoon", 11, Color3.fromRGB(140, 155, 175))
worldSeason.Size     = UDim2.new(1, -10, 0, 18)
worldSeason.Position = UDim2.fromOffset(8, 24)
local worldEvents = label(worldPanel, "", 11, Color3.fromRGB(255, 100, 80))
worldEvents.Size     = UDim2.new(1, -10, 0, 16)
worldEvents.Position = UDim2.fromOffset(8, 42)

-- ── Weather icons ─────────────────────────────────────────────────────────────
local WEATHER_ICONS = {
	BlueSkyDay   = "🌤 ", GoldenSunset = "🌇 ", PinkSunset   = "🌸 ",
	MoonlitNight = "🌕 ", Storm        = "⛈ ", SnowFront    = "❄️  ",
}

-- ══════════════════════════════════════════════════════════════════════════════
-- Wire remotes
-- ══════════════════════════════════════════════════════════════════════════════
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 15)
	if not remotes then
		objText.TextColor3 = Color3.fromRGB(255, 80, 80)
		objText.Text       = "⚠ Server connection failed"
		return
	end

	local playerStateRemote = remotes:WaitForChild("PlayerStateUpdated",  10)
	local storyStateRemote  = remotes:WaitForChild("StoryStateUpdated",   10)
	local weatherRemote     = remotes:WaitForChild("WeatherStateUpdated", 10)

	-- ── Player state ─────────────────────────────────────────────────────────
	if playerStateRemote then
		playerStateRemote.OnClientEvent:Connect(function(p)
			if type(p) ~= "table" then return end

			if type(p.hunger) == "number" then
				local pct  = math.clamp(p.hunger / 100, 0, 1)
				local displayH = math.floor(p.hunger + 0.5)
				hungerNum.Text = displayH .. "/100"
				TweenService:Create(barFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad),
					{Size = UDim2.new(pct, 0, 1, 0)}):Play()
				-- Colour shifts red below 30
				barFill.BackgroundColor3 = pct < 0.3
					and Color3.fromRGB(220, 60, 60)
					or pct < 0.6
						and Color3.fromRGB(230, 155, 50)
						or Color3.fromRGB(240, 130, 50)
			end

			if type(p.coins) == "number" then
				coinsLbl.Text = tostring(math.floor(p.coins))
			end

			if type(p.storyLevel) == "number" then
				lvlNum.Text = tostring(p.storyLevel)
			end
		end)
	end

	-- ── Story state ───────────────────────────────────────────────────────────
	if storyStateRemote then
		storyStateRemote.OnClientEvent:Connect(function(p)
			if type(p) ~= "table" then return end
			if type(p.chapter) == "string" then
				objChapter.Text = p.chapter
			end
			if type(p.objective) == "string" then
				objText.Text = p.objective
				objText.TextColor3 = Color3.fromRGB(220, 226, 240)
			end
			if type(p.level) == "number" then
				lvlNum.Text = tostring(p.level)
			end
		end)
	end

	-- ── Weather state ─────────────────────────────────────────────────────────
	if weatherRemote then
		weatherRemote.OnClientEvent:Connect(function(p)
			if type(p) ~= "table" then return end
			local wname = type(p.name)      == "string" and p.name      or "?"
			local season = type(p.season)   == "string" and p.season    or "?"
			local moon   = type(p.moonPhase)== "string" and p.moonPhase or "?"
			local events = type(p.activeEvents) == "table" and p.activeEvents or {}

			local icon = WEATHER_ICONS[wname] or "🌍 "
			worldWeather.Text = icon .. wname
			worldSeason.Text  = season .. "  •  " .. moon

			local evStr = #events > 0 and "⚡ " .. table.concat(events, ", ") or ""
			worldEvents.Text = evStr
		end)
	end

	-- ── Debug quick-action keys (fallback if ProximityPrompt unavailable) ────
	local questRemote = remotes:WaitForChild("RequestQuestAction", 10)
	if questRemote then
		local DEBUG_KEYS = {
			[Enum.KeyCode.One]   = "steal_chicken",
			[Enum.KeyCode.Two]   = "meet_friends",
			[Enum.KeyCode.Three] = "board_ship",
		}
		UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			local action = DEBUG_KEYS[input.KeyCode]
			if action then questRemote:FireServer(action) end
		end)
	end
end)
