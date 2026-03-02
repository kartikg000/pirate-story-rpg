-- ShipService.luau  (One Piece Edition)
-- Manages the sailing Going Merry ship.
-- Player boards via ProximityPrompt on the ship wheel.
-- Client sends ShipControl remote (throttle, steer) while at helm.
-- Server moves all ship parts every heartbeat (anchored parts, CFrame-locked).

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames   = require(ReplicatedStorage.Shared.Net.RemoteNames)

local ShipService = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- CONSTANTS
-- ══════════════════════════════════════════════════════════════════════════════
local SHIP_SPEED       = 50   -- studs/sec forward
local SHIP_TURN_SPEED  = 60   -- degrees/sec
local SHIP_WATER_Y     = 3    -- Y center of ship hull at sea level
local SPAWN_OFFSET     = Vector3.new(0, 0, 80)  -- from dock, out to sea

-- Ship part layout — offsets from hull center
local PART_LAYOUT = {
	{n="SailHull",    sz=Vector3.new(44,18,22), off=Vector3.new(0,0,0),      col="Bright orange",      mat="WoodPlanks"},
	{n="SailDeck",    sz=Vector3.new(44, 3,22), off=Vector3.new(0,10,0),     col="Medium dark flesh",  mat="WoodPlanks"},
	{n="SailBow",     sz=Vector3.new(14,12,22), off=Vector3.new(26,-4,0),    col="Bright orange",      mat="WoodPlanks"},
	{n="SailMast",    sz=Vector3.new(3, 55, 3), off=Vector3.new(-8,37,0),    col="Reddish brown",      mat="WoodPlanks"},
	{n="SailSail",    sz=Vector3.new(0.5,28,20),off=Vector3.new(-8,43,0),    col="White",              mat="Fabric"},
	{n="SailJolly",   sz=Vector3.new(10, 7,0.5),off=Vector3.new(-8,65,0),    col="White",              mat="Fabric"},
	{n="SailJollyHat",sz=Vector3.new(9, 2,0.5), off=Vector3.new(-8,71,0),    col="Bright yellow",      mat="Fabric"},
	{n="SailLantern", sz=Vector3.new(2, 3, 2),  off=Vector3.new(18,14,0),    col="Bright yellow",      mat="Neon"},
	{n="SailRailing1",sz=Vector3.new(44,1.5,1), off=Vector3.new(0,12,11.5),  col="Reddish brown",      mat="WoodPlanks"},
	{n="SailRailing2",sz=Vector3.new(44,1.5,1), off=Vector3.new(0,12,-11.5), col="Reddish brown",      mat="WoodPlanks"},
	-- Helm wheel
	{n="SailWheel",   sz=Vector3.new(4, 5, 1),  off=Vector3.new(-14,13,0),   col="Reddish brown",      mat="Wood"},
	-- Cannon on deck
	{n="SailCannon",  sz=Vector3.new(6,4,4),    off=Vector3.new(12,12,8),    col="Dark orange",        mat="DiamondPlate"},
}

-- ══════════════════════════════════════════════════════════════════════════════
-- PER-PLAYER SHIP STATE
-- ══════════════════════════════════════════════════════════════════════════════
local shipStates   = {}   -- [userId] = {parts, cframe, throttle, steer, helmPart}
local playerShips  = {}   -- [userId] = folder in workspace

local function getShipFolder()
	local ws = game:GetService("Workspace")
	local f  = ws:FindFirstChild("SailingShips")
	if not f then
		f      = Instance.new("Folder")
		f.Name = "SailingShips"
		f.Parent = ws
	end
	return f
end

-- ── build one sailing ship model and return part list + helm reference ────────
local function buildShip(rootCFrame)
	local folder = Instance.new("Folder")
	folder.Name  = "GoingMerry"
	folder.Parent = getShipFolder()

	local parts = {}
	for _, pd in PART_LAYOUT do
		local p           = Instance.new("Part")
		p.Name            = pd.n
		p.Size            = pd.sz
		p.CFrame          = rootCFrame * CFrame.new(pd.off)
		p.BrickColor      = BrickColor.new(pd.col)
		p.Material        = Enum.Material[pd.mat] or Enum.Material.SmoothPlastic
		p.Anchored        = true
		p.CanCollide      = true
		p.Parent          = folder
		parts[pd.n] = {part=p, offCF=CFrame.new(pd.off)}
	end

	-- Add a ship deck Seat (not VehicleSeat) for standing on
	local seat = Instance.new("Seat")
	seat.Name           = "SailHelm"
	seat.Size           = Vector3.new(4, 1, 4)
	seat.CFrame         = rootCFrame * CFrame.new(-14, 12, 0)
	seat.BrickColor     = BrickColor.new("Reddish brown")
	seat.Material       = Enum.Material.WoodPlanks
	seat.Anchored       = true
	seat.Parent         = folder
	parts["SailHelm"] = {part=seat, offCF=CFrame.new(-14,12,0)}

	-- Lantern light
	local light = Instance.new("PointLight")
	light.Brightness = 5; light.Color = Color3.fromRGB(255,200,100); light.Range = 20
	light.Parent = parts["SailLantern"].part

	return folder, parts, seat
end

local function moveParts(parts, rootCF)
	for _, pd in parts do
		pd.part.CFrame = rootCF * pd.offCF
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BOARD / DISEMBARK
-- ══════════════════════════════════════════════════════════════════════════════
local function boardShip(services, player)
	local userId = player.UserId
	if shipStates[userId] then return end  -- already on ship

	-- Spawn ship a bit off the dock
	local char = player.Character
	if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local spawnCF = CFrame.new(hrp.Position.X + SPAWN_OFFSET.X, SHIP_WATER_Y, hrp.Position.Z + SPAWN_OFFSET.Z)
	local folder, parts, helm = buildShip(spawnCF)

	playerShips[userId] = folder
	shipStates[userId]  = {
		parts    = parts,
		cframe   = spawnCF,
		throttle = 0,
		steer    = 0,
		helm     = helm,
		folder   = folder,
		remoteService = services.RemoteService,
		boardPos = hrp.CFrame,   -- saved so disembark returns here safely
	}

	-- Wait briefly for parts to replicate to client before teleporting
	task.delay(0.4, function()
		if not char.Parent then return end  -- character may have respawned
		local hrp2 = char:FindFirstChild("HumanoidRootPart")
		if not hrp2 then return end
		local state2 = shipStates[userId]
		if not state2 then return end
		-- Teleport onto the helm seat (deck top + character half-height)
		local helmCF = state2.cframe * CFrame.new(-14, 16, 0)
		hrp2.CFrame = helmCF
	end)

	-- ProximityPrompt on helm to disembark
	local disembarkPP = Instance.new("ProximityPrompt")
	disembarkPP.Name                 = "DisembarkPrompt"
	disembarkPP.ActionText           = "Disembark"
	disembarkPP.ObjectText           = "Going Merry"
	disembarkPP.MaxActivationDistance = 8
	disembarkPP.HoldDuration         = 0.5
	disembarkPP.RequiresLineOfSight  = false
	disembarkPP.Parent               = helm

	disembarkPP.Triggered:Connect(function(p)
		if p == player then
			local remote = services.RemoteService.getRemote(RemoteNames.ShipLeft)
			if remote then remote:FireClient(player) end
			leaveShip(services, player)
		end
	end)

	-- Notify client
	local remote = services.RemoteService.getRemote(RemoteNames.ShipBoarded)
	if remote then
		remote:FireClient(player, {
			position = {x = spawnCF.X, y = spawnCF.Y, z = spawnCF.Z}
		})
	end
end

function leaveShip(services, player)
	local userId = player.UserId
	local state  = shipStates[userId]
	if not state then return end

	-- Teleport player back to where they boarded (safe land position)
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local safeCF = state.boardPos or CFrame.new(0, 50, 0)
			-- lift slightly so they land on top rather than inside geometry
			hrp.CFrame = safeCF + Vector3.new(0, 8, 0)
		end
	end

	if state.folder and state.folder.Parent then
		state.folder:Destroy()
	end
	shipStates[userId]  = nil
	playerShips[userId] = nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- MOVEMENT LOOP
-- ══════════════════════════════════════════════════════════════════════════════
local function startMovementLoop()
	RunService.Heartbeat:Connect(function(dt)
		for userId, state in shipStates do
			local throttle = state.throttle
			local steer    = state.steer
			if throttle == 0 and steer == 0 then continue end

			local cf = state.cframe
			-- Rotate
			local newCF = cf * CFrame.Angles(0, math.rad(-steer * SHIP_TURN_SPEED * dt), 0)
			-- Advance forward
			newCF = CFrame.new(
				newCF.Position.X + newCF.LookVector.X * throttle * SHIP_SPEED * dt,
				SHIP_WATER_Y,
				newCF.Position.Z + newCF.LookVector.Z * throttle * SHIP_SPEED * dt
			) * CFrame.Angles(0, math.atan2(-newCF.LookVector.X, -newCF.LookVector.Z), 0)

			state.cframe = newCF
			moveParts(state.parts, newCF)

			-- Carry the player with the ship (anchored parts don't do this automatically)
			local shipPlayer = Players:GetPlayerByUserId(userId)
			if shipPlayer and shipPlayer.Character then
				local pHrp = shipPlayer.Character:FindFirstChild("HumanoidRootPart")
				if pHrp then
					local delta = newCF * cf:Inverse()
					pHrp.CFrame = delta * pHrp.CFrame
				end
			end
		end
	end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PUBLIC
-- ══════════════════════════════════════════════════════════════════════════════
function ShipService.addBoardingPrompt(services, wheelPart)
	local pp = Instance.new("ProximityPrompt")
	pp.Name                  = "BoardShipPrompt"
	pp.ActionText            = "Board Ship"
	pp.ObjectText            = "Going Merry"
	pp.MaxActivationDistance = 12
	pp.HoldDuration          = 0.5
	pp.RequiresLineOfSight   = false
	pp.Parent                = wheelPart

	pp.Triggered:Connect(function(player)
		boardShip(services, player)
	end)
end

function ShipService.init(services)
	-- Listen for ship control from client
	local controlRemote = services.RemoteService.getRemote(RemoteNames.ShipControl)
	if controlRemote then
		controlRemote.OnServerEvent:Connect(function(player, data)
			if not services.RemoteService.guard(player) then return end
			local state = shipStates[player.UserId]
			if not state then return end
			if type(data) == "table" then
				state.throttle = math.clamp(tonumber(data.throttle) or 0, -1, 1)
				state.steer    = math.clamp(tonumber(data.steer)    or 0, -1, 1)
			end
		end)
	end

	-- Clean up on player leave
	Players.PlayerRemoving:Connect(function(player)
		leaveShip(services, player)
	end)

	startMovementLoop()
	print("[ShipService] Going Merry sailing system ready")
end

return ShipService
