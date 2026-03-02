-- CinematicLightingService.luau
-- Sets up Nolan-style physically-based lighting: Future tech, dramatic atmosphere,
-- bloom, sun rays, cinematic color grade. WeatherService overrides per-tick on top.

local Lighting = game:GetService("Lighting")

local CinematicLightingService = {}

function CinematicLightingService.init()
	-- ── Technology & Global ──────────────────────────────────────────────────
	Lighting.Technology      = Enum.Technology.Future   -- full PBR / reflection
	Lighting.GlobalShadows   = true
	Lighting.Brightness      = 2.8
	Lighting.ClockTime       = 10.5   -- 10:30 AM golden-morning
	Lighting.GeographicLatitude = 18  -- tropics
	Lighting.FogEnd          = 2200
	Lighting.FogStart        = 900
	Lighting.FogColor        = Color3.fromRGB(180, 196, 210)

	-- Ambient: slightly blue-purple like Nolan (no pure white fill)
	Lighting.Ambient         = Color3.fromRGB(55, 52, 72)
	Lighting.OutdoorAmbient  = Color3.fromRGB(105, 98, 118)

	-- Sky
	local sky                = Instance.new("Sky")
	sky.SkyboxBk             = "rbxassetid://159454291"
	sky.SkyboxDn             = "rbxassetid://159454291"
	sky.SkyboxFt             = "rbxassetid://159454291"
	sky.SkyboxLf             = "rbxassetid://159454291"
	sky.SkyboxRt             = "rbxassetid://159454291"
	sky.SkyboxUp             = "rbxassetid://159454291"
	sky.StarCount            = 3500
	sky.MoonAngularSize      = 11
	sky.SunAngularSize       = 5
	sky.MoonTextureId        = "rbxassetid://6444320592"
	sky.Parent               = Lighting

	-- ── Atmosphere ────────────────────────────────────────────────────────────
	-- Remove any existing atmosphere on Terrain
	for _, c in game:GetService("Workspace").Terrain:GetChildren() do
		if c:IsA("Atmosphere") then c:Destroy() end
	end
	local atm            = Instance.new("Atmosphere")
	atm.Density          = 0.42
	atm.Offset           = 0.06
	atm.Haze             = 0.38
	atm.Glare            = 0.05
	atm.Color            = Color3.fromRGB(199, 190, 160)     -- warm horizon dust
	atm.Decay            = Color3.fromRGB(82,  70,  110)     -- purple-cool zenith
	atm.Parent           = Lighting

	-- ── Bloom ─────────────────────────────────────────────────────────────────
	-- Remove existing
	for _, c in Lighting:GetChildren() do
		if c:IsA("BloomEffect") or c:IsA("ColorCorrectionEffect") or
		   c:IsA("SunRaysEffect") or c:IsA("DepthOfFieldEffect") then
			c:Destroy()
		end
	end

	local bloom          = Instance.new("BloomEffect")
	bloom.Intensity      = 0.72
	bloom.Size           = 30
	bloom.Threshold      = 0.85
	bloom.Parent         = Lighting

	-- ── Sun Rays ──────────────────────────────────────────────────────────────
	local rays           = Instance.new("SunRaysEffect")
	rays.Intensity       = 0.12
	rays.Spread          = 0.55
	rays.Parent          = Lighting

	-- ── Cinematic Color Correction (Nolan signature: teal shadows, orange mids) ──
	local cc             = Instance.new("ColorCorrectionEffect")
	cc.Name              = "CinematicGrade"
	cc.Brightness        = -0.015         -- ever-so-slightly darker overall
	cc.Contrast          = 0.14           -- punchy shadows
	cc.Saturation        = 0.18           -- vivid but not cartoony
	cc.TintColor         = Color3.fromRGB(248, 247, 255)  -- ultra-subtle cool cast
	cc.Parent            = Lighting

	print("[CinematicLightingService] ✅  Future tech lighting, bloom, sun rays, PBR atmosphere loaded")
end

return CinematicLightingService
