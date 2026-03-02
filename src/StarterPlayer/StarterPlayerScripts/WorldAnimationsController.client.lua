-- WorldAnimationsController.client.lua
-- Adds life to static world geometry: floating food, pulsing quest zones,
-- bobbing ship, flickering torches, swimming sea birds, wave shimmer.

local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace   = game:GetService("Workspace")

-- Wait for the world folder to exist
local world = Workspace:WaitForChild("PirateWorld", 30)
if not world then return end

local t0 = tick()

-- ── Floating food items ───────────────────────────────────────────────────────
local FOOD_NAMES = {"Coconut", "Mango", "Fish"}
local foodParts  = {}
local foodOrigins = {}

for _, child in world:GetChildren() do
	for _, fname in FOOD_NAMES do
		if child.Name == fname then
			table.insert(foodParts, child)
			foodOrigins[child] = child.Position
			break
		end
	end
end

-- ── Zone pulse data ────────────────────────────────────────────────────────────
local zoneParts = {}
for _, child in world:GetChildren() do
	if string.find(child.Name, "_Zone") then
		table.insert(zoneParts, {part = child, base = child.Transparency})
	end
end

-- ── Ship bobbing ───────────────────────────────────────────────────────────────
local shipParts = {}
local shipOrigins = {}
local SHIP_NAMES = {"ShipHull","ShipDeck","ShipBow","Mast","Sail1","Crownest","ShipWheel","ShipLantern"}
for _, name in SHIP_NAMES do
	local p = world:FindFirstChild(name)
	if p then
		table.insert(shipParts, p)
		shipOrigins[p] = p.CFrame
	end
end

-- ── Torch flicker ──────────────────────────────────────────────────────────────
local torchLight = nil
local torchBase  = 4
do
	local torch = world:FindFirstChild("VillageTorch")
	if torch then
		torchLight = torch:FindFirstChildOfClass("PointLight")
		if torchLight then torchBase = torchLight.Brightness end
	end
end

-- ── Ocean shimmer ─────────────────────────────────────────────────────────────
local ocean = world:FindFirstChild("Ocean")
local oceanBase = ocean and ocean.Transparency or 0.45

-- ── Sea birds (small neon balls that patrol) ──────────────────────────────────
-- Create 4 sea bird parts on client only (no lag on server)
local birds = {}
for i = 1, 4 do
	local b = Instance.new("Part")
	b.Name          = "SeaBird" .. i
	b.Size          = Vector3.new(1.2, 0.5, 2.2)
	b.BrickColor    = BrickColor.new("White")
	b.Material      = Enum.Material.SmoothPlastic
	b.Anchored      = true
	b.CanCollide    = false
	b.CastShadow    = false
	b.CFrame        = CFrame.new(
		math.random(-80, 160),
		math.random(55, 80),
		math.random(-60, 60)
	)
	b.Parent = world
	birds[i] = {part = b, angle = (i-1) * (math.pi*2/4), radius = 60 + i*12, height = 60 + i*6}
end

-- ── Main animation loop ───────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
	local t = tick() - t0

	-- Float food items (sine wave up/down)
	for i, fp in foodParts do
		local origin = foodOrigins[fp]
		if origin then
			local y = origin.Y + math.sin(t * 1.8 + i * 1.1) * 0.55
			fp.Position = Vector3.new(origin.X, y, origin.Z)
			fp.CFrame   = CFrame.new(fp.Position) * CFrame.Angles(0, t * 0.9 + i, 0)
		end
	end

	-- Pulse quest zones (transparency in/out, subtle)
	for _, zd in zoneParts do
		zd.part.Transparency = zd.base + math.sin(t * 2.2) * 0.06
	end

	-- Bob the ship very gently (4-second period)
	local shipY  = math.sin(t * 0.5) * 0.35
	local shipTilt = math.sin(t * 0.38) * 0.008
	for _, sp in shipParts do
		local orig = shipOrigins[sp]
		if orig then
			sp.CFrame = orig * CFrame.new(0, shipY, 0) * CFrame.Angles(shipTilt, 0, shipTilt * 0.5)
		end
	end

	-- Flicker torch light
	if torchLight then
		torchLight.Brightness = torchBase + math.sin(t * 14.3) * 0.6
			+ math.sin(t * 28.7) * 0.25
	end

	-- Ocean shimmer
	if ocean then
		ocean.Transparency = oceanBase + math.sin(t * 0.7) * 0.03
	end

	-- Sea bird patrol (lazy circles at different heights)
	for i, bd in birds do
		bd.angle = bd.angle + 0.003
		local x   = math.cos(bd.angle) * bd.radius
		local z   = math.sin(bd.angle) * bd.radius * 0.6
		local y   = bd.height + math.sin(t * 0.8 + i) * 3
		bd.part.CFrame = CFrame.new(x + 65, y, z)
			* CFrame.Angles(0, bd.angle + math.pi, math.sin(t * 2.2 + i) * 0.15)
	end
end)
