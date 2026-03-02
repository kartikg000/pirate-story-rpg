local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local WeatherConfig = require(ReplicatedStorage.Shared.Config.WeatherConfig)
local WorldCycleConfig = require(ReplicatedStorage.Shared.Config.WorldCycleConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local WeatherService = {}

local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local bloom: BloomEffect
local sunRays: SunRaysEffect

local cycleIndex = 1
local cycleStart = os.clock()
local currentState = WeatherConfig.Cycle[1]
local seasonIndex = 1
local seasonStart = os.clock()
local moonPhaseIndex = 1
local moonPhaseStart = os.clock()
local activeEvents: {[string]: number} = {}
local lastEventTriggerTime: {[string]: number} = {
	Tsunami = 0,
	SuperStorm = 0,
}

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

local function getSeasonName(): string
	return WorldCycleConfig.Seasons[seasonIndex]
end

local function getMoonPhaseName(): string
	return WorldCycleConfig.MoonPhases[moonPhaseIndex]
end

local function collectActiveEvents(now: number): {string}
	local list = {}
	for eventName, endTime in activeEvents do
		if endTime > now then
			list[#list + 1] = eventName
		else
			activeEvents[eventName] = nil
		end
	end
	return list
end

local function tryTriggerRareEvent(now: number)
	for eventName, config in WorldCycleConfig.RareEvents do
		if now - (lastEventTriggerTime[eventName] or 0) >= config.cooldownSeconds then
			if math.random() < config.chancePerWeatherCheck then
				activeEvents[eventName] = now + config.durationSeconds
				lastEventTriggerTime[eventName] = now
			end
		end
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
	math.randomseed(os.clock() * 100000)
	applyState(currentState)
	services.WorldStateService.setSeason(getSeasonName())
	services.WorldStateService.setMoonPhase(getMoonPhaseName())

	local remote = services.RemoteService.getRemote(RemoteNames.WeatherStateUpdated)

	task.spawn(function()
		while true do
			local now = os.clock()
			local elapsed = now - cycleStart
			if elapsed >= currentState.durationSeconds then
				nextState()
			end

			if now - seasonStart >= WorldCycleConfig.SeasonDurationSeconds then
				seasonIndex += 1
				if seasonIndex > #WorldCycleConfig.Seasons then
					seasonIndex = 1
				end
				seasonStart = now
				services.WorldStateService.setSeason(getSeasonName())
			end

			if now - moonPhaseStart >= WorldCycleConfig.MoonPhaseDurationSeconds then
				moonPhaseIndex += 1
				if moonPhaseIndex > #WorldCycleConfig.MoonPhases then
					moonPhaseIndex = 1
				end
				moonPhaseStart = now
				services.WorldStateService.setMoonPhase(getMoonPhaseName())
			end

			tryTriggerRareEvent(now)
			local events = collectActiveEvents(now)
			services.WorldStateService.setEventActive("Tsunami", false)
			services.WorldStateService.setEventActive("SuperStorm", false)
			for _, eventName in events do
				services.WorldStateService.setEventActive(eventName, true)
			end

			remote:FireAllClients({
				name = currentState.name,
				clockTime = Lighting.ClockTime,
				fogEnd = Lighting.FogEnd,
				season = getSeasonName(),
				moonPhase = getMoonPhaseName(),
				activeEvents = events,
				ts = os.time(),
			})
			task.wait(GameConfig.WeatherBroadcastIntervalSeconds)
		end
	end)
end

return WeatherService
