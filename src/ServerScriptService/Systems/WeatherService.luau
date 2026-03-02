local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local WeatherConfig = require(ReplicatedStorage.Shared.Config.WeatherConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local WeatherService = {}

local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local bloom: BloomEffect
local sunRays: SunRaysEffect

local cycleIndex = 1
local cycleStart = os.clock()
local currentState = WeatherConfig.Cycle[1]

local function ensurePostFX()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Parent = Lighting

	colorCorrection = Lighting:FindFirstChild("GameColorCorrection") :: ColorCorrectionEffect
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "GameColorCorrection"
		colorCorrection.Parent = Lighting
	end

	bloom = Lighting:FindFirstChild("GameBloom") :: BloomEffect
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "GameBloom"
		bloom.Intensity = 0.18
		bloom.Size = 24
		bloom.Threshold = 1
		bloom.Parent = Lighting
	end

	sunRays = Lighting:FindFirstChild("GameSunRays") :: SunRaysEffect
	if not sunRays then
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Name = "GameSunRays"
		sunRays.Intensity = 0.035
		sunRays.Spread = 0.7
		sunRays.Parent = Lighting
	end
end

local function applyState(state)
	Lighting.Technology = Enum.Technology.Future
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
	Lighting.ClockTime = state.clockTime
	Lighting.Brightness = state.brightness
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.45
	Lighting.FogEnd = state.fogEnd

	atmosphere.Density = state.atmosphereDensity
	atmosphere.Haze = state.atmosphereHaze
	atmosphere.Glare = state.atmosphereGlare
	atmosphere.Color = state.colorTint
	atmosphere.Decay = Color3.fromRGB(106, 112, 128)

	colorCorrection.TintColor = state.colorTint
	colorCorrection.Contrast = 0.04
	colorCorrection.Saturation = 0.08

	if state.name == "Storm" then
		bloom.Intensity = 0.08
		sunRays.Intensity = 0.01
	elseif state.name == "MoonlitNight" then
		bloom.Intensity = 0.12
		sunRays.Intensity = 0
	else
		bloom.Intensity = 0.18
		sunRays.Intensity = 0.035
	end
end

local function nextState()
	cycleIndex += 1
	if cycleIndex > #WeatherConfig.Cycle then
		cycleIndex = 1
	end
	currentState = WeatherConfig.Cycle[cycleIndex]
	cycleStart = os.clock()
	applyState(currentState)
end

function WeatherService.init(services)
	ensurePostFX()
	applyState(currentState)

	local remote = services.RemoteService.getRemote(RemoteNames.WeatherStateUpdated)

	task.spawn(function()
		while true do
			local elapsed = os.clock() - cycleStart
			if elapsed >= currentState.durationSeconds then
				nextState()
			end

			remote:FireAllClients({
				name = currentState.name,
				clockTime = Lighting.ClockTime,
				fogEnd = Lighting.FogEnd,
				ts = os.time(),
			})
			task.wait(GameConfig.WeatherBroadcastIntervalSeconds)
		end
	end)
end

return WeatherService
