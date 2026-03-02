-- WorldBuilderService.luau  (One Piece Edition)
-- Procedurally creates Foosha Village, the Going Merry, Arlong's ship, and
-- quest trigger zones for the full East Blue → Grand Line journey.
-- Works fully in Studio, no assets required.

local Players     = game:GetService("Players")
local WorldBuilderService = {}

-- ── helpers ──────────────────────────────────────────────────────────────────
local function part(name, size, cframe, color, material, parent)
	local p       = Instance.new("Part")
	p.Name        = name
	p.Size        = size
	p.CFrame      = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
	p.BrickColor  = BrickColor.new(color)
	p.Material    = Enum.Material[material] or Enum.Material.SmoothPlastic
	p.Anchored    = true
	p.Parent      = parent
	return p
end

local function wedge(name, size, cframe, color, parent)
	local p      = Instance.new("WedgePart")
	p.Name       = name
	p.Size       = size
	p.CFrame     = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
	p.BrickColor = BrickColor.new(color)
	p.Material   = Enum.Material.SmoothPlastic
	p.Anchored   = true
	p.Parent     = parent
	return p
end

local function billboard(parent, text, yOffset)
	local bg = Instance.new("BillboardGui")
	bg.Size          = UDim2.new(0, 220, 0, 48)
	bg.StudsOffset   = Vector3.new(0, yOffset or 4, 0)
	bg.AlwaysOnTop   = false
	bg.Parent        = parent
	local frame      = Instance.new("Frame")
	frame.Size       = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent     = bg
	local corner     = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent    = frame
	local lbl        = Instance.new("TextLabel")
	lbl.Size         = UDim2.new(1, -8, 1, 0)
	lbl.Position     = UDim2.fromOffset(4, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3   = Color3.fromRGB(255, 220, 60)
	lbl.Font         = Enum.Font.GothamBold
	lbl.TextSize     = 15
	lbl.TextWrapped  = true
	lbl.Text         = text
	lbl.Parent       = frame
	return lbl
end

local function zone(name, size, pos, labelText, parent)
	local z = part(name .. "_Zone", size, CFrame.new(pos), "Bright yellow", "Neon", parent)
	z.Transparency = 0.82
	z.CanCollide   = false
	-- Cinematic zone billboard
	local bg    = Instance.new("BillboardGui")
	bg.Size          = UDim2.new(0, 270, 0, 54)
	bg.StudsOffset   = Vector3.new(0, size.Y / 2 + 4.5, 0)
	bg.AlwaysOnTop   = false
	bg.MaxDistance   = 55
	bg.Parent        = z
	local frame = Instance.new("Frame")
	frame.Size               = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3   = Color3.fromRGB(5, 8, 18)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel    = 0
	frame.Parent             = bg
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0,8); fc.Parent = frame
	local acc = Instance.new("Frame")
	acc.Size               = UDim2.new(0, 3, 0.65, 0)
	acc.Position           = UDim2.new(0, 6, 0.175, 0)
	acc.BackgroundColor3   = Color3.fromRGB(255, 215, 60)
	acc.BorderSizePixel    = 0
	acc.Parent             = frame
	local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0,2); ac.Parent = acc
	local lbl = Instance.new("TextLabel")
	lbl.Size               = UDim2.new(1, -18, 1, 0)
	lbl.Position           = UDim2.fromOffset(14, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3         = Color3.fromRGB(255, 228, 80)
	lbl.Font               = Enum.Font.GothamBold
	lbl.TextSize           = 15
	lbl.TextWrapped        = true
	lbl.Text               = labelText
	lbl.Parent             = frame
	return z
end

-- ProximityPrompt helper
local function prompt(parent, actionText, objectText, dist)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText            = actionText or "Interact"
	pp.ObjectText            = objectText or ""
	pp.MaxActivationDistance = dist or 10
	pp.HoldDuration          = 0
	pp.RequiresLineOfSight   = false
	pp.Parent                = parent
	return pp
end

-- ── main build ───────────────────────────────────────────────────────────────
-- ── NPC dialogue tables (arc-keyed) ──────────────────────────────────────────
local NPC_DIALOGUE = {
	Zoro = {
		[1] = {
			"(tied to a post) I've been waiting here for three days. Hungry.",
			"Even restrained, I've counted twelve guards. Manageable.",
			"If you're going to recruit me, cut the ropes now. We argue directions later.",
		},
		[2] = {
			"There's an entire fleet out there. Krieg doesn't deserve that cook.",
			"Sanji kicked me once. Decent form. He should see the Grand Line.",
			"Three swords or two legs — we board and we finish this.",
		},
		[3] = {
			"Arlong hit Nami's sister. That's all I needed to hear.",
			"His arms are harder than steel — that's just extra motivation.",
			"Stay out of my fight or get out of the way.",
		},
	},
	Nami = {
		[1] = {"Shanks' hat is at the cliff shrine. Don't just stand there.", "That hat is worth more to you than gold."},
		[2] = {"I've already charted three routes to the Grand Line.", "Two nearly get us killed. The third definitely does."},
		[3] = {"I mapped every inch of these sea islands. Arlong took my work.", "Now I take it back. All of it."},
	},
	Usopp = {
		[1] = {"I'm Usopp! Captain of the 8000-strong Usopp Pirates!", "...They're all on sick leave currently.", "But I'll be the greatest sniper on the seas — that's no lie!"},
		[2] = {"The Going Merry will hold. I reinforced the hull myself.", "...Mostly myself. Zoro watched."},
		[3] = {"Five thousand Fishmen surround the island! I can handle it!", "...I'll handle the ones on the left side at least."},
	},
	Sanji = {
		[1] = {"You need a cook? I make the best food on the East Blue.", "...And I'll kick anyone who wastes it."},
		[2] = {"Don Krieg wants to destroy the Baratie. Over my dead body.", "This restaurant is my home. No pirate touches it."},
		[3] = {"Nami-san needs our help. That's all I need to hear.", "Don't slow me down."},
	},
	Chopper = {
		[1] = {"I'm not cute. I'm a doctor who happens to eat a Devil Fruit.", "Don't pat my head. ...Well, maybe once is okay."},
		[2] = {"Drum Island was cold but I learned everything from Dr. Hiluluk.", "I'll cure any disease. That was his dream. Now it's mine."},
		[3] = {"My Rumble Ball lets me transform six forms.", "Horn Point for charging, Heavy Point for power — choose wisely!"},
	},
}

local function fireDialogue(remoteService, player, speaker, services)
	local npcData = NPC_DIALOGUE[speaker]
	if not npcData then return end
	local profile = services.ProfileService.getProfile(player)
	local arc     = profile and math.clamp(math.floor((profile.storyLevel or 1) / 8) + 1, 1, 3) or 1
	local lines   = npcData[arc] or npcData[1]
	local r = remoteService.getRemote("ShowDialogue")
	if r then r:FireClient(player, {speaker=speaker, lines=lines}) end
end

function WorldBuilderService.init(services)
	local hungerService  = services.HungerService
	local storyService   = services.StoryService
	local remoteService  = services.RemoteService
	local ws             = game:GetService("Workspace")

	local w = Instance.new("Folder")
	w.Name   = "OnePieceWorld"
	w.Parent = ws

	-- ── ocean & sky ──────────────────────────────────────────────────────────
	part("Ocean",       Vector3.new(2000,  4, 2000), CFrame.new(0, -8,  0),   "Bright blue",      "SmoothPlastic", w).Transparency = 0.45
	part("OceanFloor",  Vector3.new(2000, 20, 2000), CFrame.new(0, -18, 0),   "Sand yellow",      "Sand",          w)
	local atm = Instance.new("Atmosphere")
	atm.Density    = 0.36
	atm.Offset     = 0.08
	atm.Haze       = 0.5
	atm.Parent     = ws.Terrain

	-- ── main island ──────────────────────────────────────────────────────────
	part("IslandBase",  Vector3.new(340, 22, 340),  CFrame.new(0,  -3, 0),   "Sand yellow",    "Grass",     w)
	part("IslandTop",   Vector3.new(300, 10, 300),  CFrame.new(0,   8, 0),   "Medium green",   "Grass",     w)

	-- ── Foosha Village (Level 1 — find_hat) ─────────────────────────────────
	part("VillageGround", Vector3.new(70, 4, 70),   CFrame.new(-105, 14, 0), "Nougat",         "Cobblestone", w)
	for i = 1, 3 do
		local ox = -120 + (i - 1) * 22
		part("Hut"..i,     Vector3.new(14, 18, 14), CFrame.new(ox,       26, -8), "Reddish brown",  "Brick",       w)
		wedge("Roof"..i,   Vector3.new(14,  6, 14), CFrame.new(ox,       38, -8), "Bright red",     w)
	end
	-- Makino's bar & pub (marine post stand-in)
	part("Bar",            Vector3.new(10,  1, 6),  CFrame.new(-100,     17, 12), "Brick yellow",   "WoodPlanks",  w)
	part("BarCanopy",      Vector3.new(12,  0.5, 7),CFrame.new(-100,     20, 12), "Bright red",     "SmoothPlastic",w)
	-- torch
	part("VillageTorch",   Vector3.new(1,   8, 1),  CFrame.new(-115,     21, 14), "Dark orange",    "SmoothPlastic",w)
	local tfl = Instance.new("PointLight")
	tfl.Brightness = 4; tfl.Color = Color3.fromRGB(255, 160, 60); tfl.Range = 16
	tfl.Parent = w.VillageTorch

	-- Cliff shrine with Shanks' straw hat (barrel on cliff top)
	local cliffBase = part("CliffBase", Vector3.new(16, 26, 16), CFrame.new(-130, 26, -30), "Sand yellow", "Grass", w)
	local hatBarrel = part("StrawHat", Vector3.new(4, 3, 4), CFrame.new(-130, 42, -30), "Brick yellow", "SmoothPlastic", w)
	hatBarrel.Shape = Enum.PartType.Cylinder
	billboard(hatBarrel, "🎩 Shanks' Straw Hat", 4)
	local hatPP = prompt(hatBarrel, "Take", "Shanks' Straw Hat", 9)
	hatPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "find_hat") end)

	-- ── Field — Straw Hat crew gather point ──────────────────────────────────
	part("Field",          Vector3.new(90, 4,  90),  CFrame.new(0,       14, 0),   "Bright green",   "Grass",     w)
	-- some trees
	for _, tp in {{-20, 0, -25}, {15, 0, 28}, {-30, 0, 20}} do
		part("TreeTrunk"..tp[1], Vector3.new(4,22,4), CFrame.new(tp[1], 25, tp[3]), "Reddish brown", "WoodPlanks", w)
		part("TreeTop" ..tp[1], Vector3.new(16,14,16),CFrame.new(tp[1], 42, tp[3]), "Bright green",  "Grass",      w)
	end
	-- Straw Hat crew NPCs — each triggers their own quest step when talked to
	local CREW = {
		{name="Zoro",  color="Bright green",  questStep="meet_zoro",      pos=Vector3.new(-8,  21, -10)},
		{name="Nami",  color="Bright orange", questStep="find_nami",      pos=Vector3.new(2,   21, -10)},
		{name="Usopp", color="Tan",           questStep="recruit_usopp",  pos=Vector3.new(12,  21, -10)},
		{name="Sanji", color="Bright yellow", questStep="recruit_sanji",  pos=Vector3.new(22,  21, -10)},
		{name="Chopper",color="Bright red",   questStep="recruit_chopper",pos=Vector3.new(32,  21, -10)},
	}
	for _, c in CREW do
		local npcPart = part(c.name.."_NPC", Vector3.new(4, 10, 4), CFrame.new(c.pos), c.color, "SmoothPlastic", w)
		billboard(npcPart, c.name, 7)
		local eyeDot = part(c.name.."_Eyes", Vector3.new(2.5, 1, 0.5),
			CFrame.new(c.pos.X, c.pos.Y+5, c.pos.Z-2), "White", "Neon", w)
		eyeDot.Transparency = 0
		local npcPP = prompt(npcPart, "Talk", c.name, 11)
		local cname = c.name
		local cstep = c.questStep
		npcPP.Triggered:Connect(function(p)
			-- Always show character dialogue
			fireDialogue(remoteService, p, cname, services)
			-- Advance quest step if it's currently active
			storyService.handleQuestAction(services, p, cstep)
		end)
	end

	-- ── harbor & dock (Going Merry boarding point) ───────────────────────────
	part("Harbor",        Vector3.new(90, 4, 50),   CFrame.new(110,      14, 0),   "Dark orange",    "Cobblestone", w)
	part("Dock",          Vector3.new(90, 5, 30),   CFrame.new(110,      15, 0),   "Reddish brown",  "WoodPlanks",  w)
	-- dock planks
	for i = 0, 8 do
		part("Plank"..i,  Vector3.new(88, 1, 3),    CFrame.new(110, 18, -10+(i*3)), "Medium dark flesh","WoodPlanks",w)
	end

	-- ── Going Merry (Straw Hat's first ship) ────────────────────────────────
	part("ShipHull",     Vector3.new(44, 18, 22),   CFrame.new(165,      9, 0),    "Bright orange",  "WoodPlanks",  w)
	part("ShipDeck",     Vector3.new(44,  3, 22),   CFrame.new(165,      19, 0),   "Medium dark flesh","WoodPlanks",w)
	part("ShipBow",      Vector3.new(22, 18, 22),   CFrame.new(165+22, 5, 0)*CFrame.Angles(0,0,-0.18),"Bright orange","WoodPlanks",w)
	part("Mast",         Vector3.new(3,  55, 3),    CFrame.new(165,      46, 0),   "Reddish brown",  "WoodPlanks",  w)
	-- Jolly Roger (Straw Hat skull)
	part("JollyRoger",   Vector3.new(12, 9, 0.5),   CFrame.new(165,      72, 0),   "White",          "Fabric",      w)
	part("JollyRogerHat",Vector3.new(10, 2, 0.5),   CFrame.new(165,      79, 0),   "Bright yellow",  "Fabric",      w)
	part("Sail1",        Vector3.new(0.5,30, 20),   CFrame.new(165,      52, 0),   "White",          "Fabric",      w)
	local crownest = part("Crownest", Vector3.new(8, 4, 8), CFrame.new(165, 75, 0), "Reddish brown", "Wood", w)
	local crestPP = prompt(crownest, "Look Out", "Crow's Nest", 10)
	crestPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "recruit_usopp") end)
	local shipWheel = part("ShipWheel", Vector3.new(4, 5, 1), CFrame.new(152, 22, 0), "Reddish brown", "Wood", w)
	local wfl = Instance.new("PointLight")
	wfl.Brightness = 3; wfl.Color = Color3.fromRGB(255, 200, 100); wfl.Range = 14
	wfl.Parent = shipWheel
	part("ShipLantern",  Vector3.new(2, 3, 2),      CFrame.new(178,      23, 0),   "Bright yellow",  "Neon",        w)
	billboard(shipWheel, "⚓ Going Merry", 5)
	-- ShipService boarding prompt (WASD sailing)
	if services.ShipService then
		services.ShipService.addBoardingPrompt(services, shipWheel)
	end
	local wheelPP = prompt(shipWheel, "Sail", "Ship's Wheel", 10)
	-- Wheel handles arc-progression steps
	wheelPP.Triggered:Connect(function(p)
		local profile = services.ProfileService.getProfile(p)
		if not profile then return end
		local step =
			profile.storyLevel == 1 and "recruit_usopp"
			or profile.storyLevel == 2 and "set_sail_grandline"
			or profile.storyLevel == 3 and "read_nami_map"
			or profile.storyLevel == 4 and "escape_smoker" or nil
		if step then storyService.handleQuestAction(services, p, step) end
	end)

	-- Baratie sea restaurant rock / Don Krieg's fleet marker
	part("BaratieRock",  Vector3.new(20, 14, 20),   CFrame.new(210,      10, -60),  "Medium stone grey","SmoothPlastic",w)
	part("BaratieTop",   Vector3.new(22, 6, 22),    CFrame.new(210,      20, -60),  "Dark stone grey", "SmoothPlastic",w)
	-- Krieg prop (dark hull wedge)
	local kriegShip = part("KriegFlag", Vector3.new(8, 5, 8), CFrame.new(210, 24, -60), "Dark stone grey", "SmoothPlastic", w)
	billboard(kriegShip, "⚓ Don Krieg's Fleet", 5)
	local kriegPP = prompt(kriegShip, "Fight!", "Don Krieg", 12)
	kriegPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "stop_krieg") end)

	-- Grand Line entrance / storm zone
	part("GrandLineGate",Vector3.new(10, 1, 10),    CFrame.new(250,      18, 0),   "Dark blue-violet","Neon",        w).Transparency = 0.5
	-- Arlong Park wall breach point
	local arlongWall = part("ArlongWall", Vector3.new(5, 6, 5), CFrame.new(168, 13, 10), "Cyan", "Neon", w)
	arlongWall.Transparency = 0.45
	billboard(arlongWall, "🐟 Arlong Park Entrance", 5)
	local arlongWallPP = prompt(arlongWall, "Smash", "Arlong Park", 9)
	arlongWallPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "destroy_arlong_park") end)
	part("CalmBelt", Vector3.new(30, 4, 30), CFrame.new(280, 14, 60), "Bright blue", "SmoothPlastic", w).Transparency = 0.55

	-- Loguetown / Execution Platform (Level 4)
	local platform = part("ExecutionPlatform", Vector3.new(20, 20, 20), CFrame.new(160, 5, -90), "Dark stone grey", "SmoothPlastic", w)
	platform.Transparency = 0.3
	billboard(platform, "⚔️ Gold Roger's Platform", 12)
	local platformPP = prompt(platform, "Stand Here", "Execution Platform", 14)
	platformPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "visit_execution_platform") end)

	local rogerSword = part("RogerSword", Vector3.new(12, 8, 12), CFrame.new(185, 5, -100), "Bright yellow", "Neon", w)
	rogerSword.Transparency = 0.35
	billboard(rogerSword, "⚔️ Legendary Cutlass", 6)
	local swordPP = prompt(rogerSword, "Buy", "Legendary Cutlass", 12)
	swordPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "find_gold_roger_sword") end)

	local smokerZone = part("SmokerChase", Vector3.new(3, 20, 3), CFrame.new(155, 10, -80), "White", "SmoothPlastic", w)
	billboard(smokerZone, "💨 Escape Smoker!", 12)
	local smokerPP = prompt(smokerZone, "Run!", "Escape Smoker", 10)
	smokerPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "escape_smoker") end)

	-- Arlong's Sawshark Vessel (villain ship, dark blue)
	part("ArlongHull",   Vector3.new(44, 18, 22),   CFrame.new(330, 9, 60),       "Dark blue",       "WoodPlanks",  w)
	part("ArlongDeck",   Vector3.new(44, 3, 22),    CFrame.new(330, 19, 60),      "Dark blue-violet","WoodPlanks",  w)
	part("ArlongMast",   Vector3.new(3, 55, 3),     CFrame.new(330, 46, 60),      "Black",           "WoodPlanks",  w)
	-- Shark fin detail
	wedge("SharkFin",    Vector3.new(6, 12, 14),    CFrame.new(330, 22, 70),      "Dark blue",       w)
	local arlongFlag = part("ArlongFlag", Vector3.new(10, 7, 0.5), CFrame.new(330, 76, 60), "Cyan", "Fabric", w)
	billboard(arlongFlag, "🦈 Arlong's Sawshark Ship", 5)
	local arlongPP = prompt(arlongFlag, "Board!", "Arlong's Ship", 10)
	arlongPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "destroy_arlong_park") end)
	local boardArlongPP = prompt(w.ArlongDeck, "Fight Arlong!", "Arlong Park", 16)
	boardArlongPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "destroy_arlong_park") end)

	-- ──────────────────────────────────────────────────────────────────────────
	-- SPAWN LOCATION (world-visible version; invisible safety one already exists)
	local existingSP = ws:FindFirstChild("SpawnLocation")
	if existingSP then
		-- Update position/appearance now that world is built; keep Transparency=1
		existingSP.CFrame = CFrame.new(-90, 17, 10)
	else
		local sp = Instance.new("SpawnLocation")
		sp.Size        = Vector3.new(16, 1, 16)
		sp.CFrame      = CFrame.new(-90, 17, 10)
		sp.BrickColor  = BrickColor.new("Bright yellow")
		sp.Neutral     = true
		sp.Duration    = 0
		sp.Anchored    = true
		sp.Parent      = ws
	end

	-- ── TRIGGER ZONES (One Piece) ────────────────────────────────────────────
	-- Arc 1, Level 1 — Romance Dawn
	local z_hat     = zone("L1_Hat",      Vector3.new(14, 9, 14),  Vector3.new(-130,     43, -30), "Find Shanks' Straw Hat!",   w)
	local z_zoro    = zone("L1_Zoro",     Vector3.new(18, 9, 18),  Vector3.new(0,        21, -10), "Free Zoro at Shells Town!",  w)
	local z_usopp   = zone("L1_Usopp",    Vector3.new(20, 9, 22),  Vector3.new(145,      22, 0),   "Recruit Usopp!",             w)
	-- Arc 1, Level 2 — Baratie
	local z_krieg   = zone("L2_Krieg",    Vector3.new(16, 9, 16),  Vector3.new(210,      24, -60), "Defeat Don Krieg's Fleet!",  w)
	local z_sanji   = zone("L2_Sanji",    Vector3.new(10, 6, 10),  Vector3.new(165,      76, 0),   "Recruit Sanji!",             w)
	local z_grandl  = zone("L2_GrandL",   Vector3.new(8, 9, 5),    Vector3.new(152,      24, 0),   "Sail for the Grand Line!",   w)
	-- Arc 2, Level 3 — Arlong Park
	local z_nami    = zone("L3_Nami",     Vector3.new(8, 9, 5),    Vector3.new(152,      24, 0),   "Follow Nami to Arlong!",     w)
	local z_arlong  = zone("L3_Arlong",   Vector3.new(9, 9, 9),    Vector3.new(168,      17, 10),  "Smash Arlong Park!",         w)
	local z_charts  = zone("L3_Charts",   Vector3.new(25, 6, 25),  Vector3.new(280,      17, 60),  "Recover Nami's Sea Charts!", w)
	-- Arc 3, Level 4 — Loguetown
	local z_platform= zone("L4_Platform", Vector3.new(14, 9, 14),  Vector3.new(160,      14, -90), "Stand on Roger's Platform!", w)
	local z_sword   = zone("L4_Sword",    Vector3.new(16, 9, 16),  Vector3.new(185,      10, -100),"Buy the Legendary Cutlass!", w)
	local z_smoker  = zone("L4_Smoker",   Vector3.new(9, 22, 9),   Vector3.new(155,      15, -80), "Escape Smoker!",             w)
	-- Arc 4, Level 5 — Drum Island
	local z_drum    = zone("L5_Drum",     Vector3.new(20, 9, 22),  Vector3.new(310,      22, 60),  "Climb Drum Rockies!",        w)
	local z_chopper = zone("L5_Chopper",  Vector3.new(14, 9, 14),  Vector3.new(330,      78, 60),  "Recruit Chopper!",           w)
	local z_wapol   = zone("L5_Wapol",    Vector3.new(20, 9, 22),  Vector3.new(165,      22, 0),   "Defeat Wapol!",              w)

	local ZONE_MAP = {
		[z_hat]      = "find_hat",
		[z_zoro]     = "meet_zoro",
		[z_usopp]    = "recruit_usopp",
		[z_krieg]    = "stop_krieg",
		[z_sanji]    = "recruit_sanji",
		[z_grandl]   = "set_sail_grandline",
		[z_nami]     = "find_nami",
		[z_arlong]   = "destroy_arlong_park",
		[z_charts]   = "read_nami_map",
		[z_platform] = "visit_execution_platform",
		[z_sword]    = "find_gold_roger_sword",
		[z_smoker]   = "escape_smoker",
		[z_drum]     = "climb_drum_rockies",
		[z_chopper]  = "recruit_chopper",
		[z_wapol]    = "defeat_wapol",
	}

	local debounce = {}
	for zonePart, actionId in ZONE_MAP do
		local aid = actionId
		local zp  = zonePart
		zp.Touched:Connect(function(hit)
			local char = hit.Parent
			local p    = Players:GetPlayerFromCharacter(char)
			if not p then return end
			local key  = p.UserId .. aid
			local now  = tick()
			if debounce[key] and now - debounce[key] < 3 then return end
			debounce[key] = now
			storyService.handleQuestAction(services, p, aid)
		end)
	end

	-- ── FOOD PICKUPS ──────────────────────────────────────────────────────────
	local FOODS = {
		{name="Coconut",  pos=Vector3.new(-85,     20, -15), heal=25, color="Sand yellow"},
		{name="Mango",    pos=Vector3.new(-85,     20,  18), heal=20, color="Bright orange"},
		{name="Coconut",  pos=Vector3.new(  8,     21, -22), heal=25, color="Sand yellow"},
		{name="Fish",     pos=Vector3.new( 22,     21,  25), heal=30, color="Bright blue"},
		{name="Fish",     pos=Vector3.new(108,     20, -12), heal=30, color="Bright blue"},
		{name="Mango",    pos=Vector3.new( 95,     20,  15), heal=20, color="Bright orange"},
		{name="Coconut",  pos=Vector3.new(175,     22,  10), heal=25, color="Sand yellow"},
	}

	local eatDebounce = {}
	for _, f in FOODS do
		local fp = part(f.name, Vector3.new(3.5, 3.5, 3.5), CFrame.new(f.pos), f.color, "Neon", w)
		fp.Shape = Enum.PartType.Ball
		billboard(fp, f.name .. "  +" .. f.heal .. " Hunger", 3.5)

		local heal  = f.heal
		local fname = f.name
		local fpos  = tostring(f.pos)

		-- ProximityPrompt (primary — press E)
		local foodPP = prompt(fp, "Eat", f.name, 7)
		foodPP.Triggered:Connect(function(p)
			local key = p.UserId .. fname .. fpos
			local now = tick()
			if eatDebounce[key] and now - eatDebounce[key] < 6 then return end
			eatDebounce[key] = now
			hungerService.feedPlayer(services, p, heal)
		end)
		-- Touched fallback (walk through)
		fp.Touched:Connect(function(hit)
			local char = hit.Parent
			local p    = Players:GetPlayerFromCharacter(char)
			if not p then return end
			local key  = p.UserId .. fname .. fpos
			local now  = tick()
			if eatDebounce[key] and now - eatDebounce[key] < 6 then return end
			eatDebounce[key] = now
			hungerService.feedPlayer(services, p, heal)
		end)
	end

	print("[WorldBuilder] ✅  Foosha Village, Going Merry, Arlong's ship, 15 trigger zones, 7 food pickups — One Piece world built")

	-- ══════════════════════════════════════════════════════════════════════════
	-- DETAIL PASS — props, scenery, atmosphere
	-- ══════════════════════════════════════════════════════════════════════════

	-- ── Sandy beach ring around island border ─────────────────────────────────
	part("BeachN", Vector3.new(340, 5, 30),  CFrame.new(  0, 9,  -165), "Sand yellow",  "Sand",       w)
	part("BeachS", Vector3.new(340, 5, 30),  CFrame.new(  0, 9,   165), "Sand yellow",  "Sand",       w)
	part("BeachE", Vector3.new(30, 5,  280), CFrame.new( 165, 9,    0), "Sand yellow",  "Sand",       w)
	part("BeachW", Vector3.new(30, 5,  280), CFrame.new(-165, 9,    0), "Sand yellow",  "Sand",       w)

	-- ── More palm trees (variety of sizes) ───────────────────────────────────
	local PALMS = {
		{  -140, 16,  40, 1.0},  {  -150, 16, -30, 0.8},
		{   -60, 16,  55, 1.1},  {   -70, 16, -55, 0.9},
		{    50, 16,  55, 1.2},  {   -45, 16,   0, 0.7},
		{   60,  16, -50, 1.0},  {  140,  16,  30, 0.9},
	}
	for i, tp in PALMS do
		local s = tp[4]
		part("Palm"..i.."Trunk", Vector3.new(2*s, 20*s, 2*s), CFrame.new(tp[1], 16+10*s, tp[3])*CFrame.Angles(0,0,0.06*i), "Reddish brown",  "Bark",  w)
		part("Palm"..i.."Top",   Vector3.new(12*s, 7*s, 12*s), CFrame.new(tp[1]+1, 16+21*s, tp[3]),                          "Bright green",   "Grass", w)
		part("Palm"..i.."Top2",  Vector3.new(8*s,  4*s, 10*s), CFrame.new(tp[1]-2, 16+22*s, tp[3]+1)*CFrame.Angles(0,0.5,0.1),"Medium green",   "Grass", w)
	end

	-- ── Lighthouse on NW corner ───────────────────────────────────────────────
	part("LighthouseBase",  Vector3.new(10, 30, 10),  CFrame.new(-140, 27, -120), "White",          "Brick",       w)
	part("LighthouseMid",   Vector3.new(8,  16, 8),   CFrame.new(-140, 48, -120), "Institutional white","Brick",   w)
	part("LighthouseTop",   Vector3.new(8,  6,  8),   CFrame.new(-140, 59, -120), "Bright red",     "SmoothPlastic",w)
	part("LighthouseLight", Vector3.new(4,  4,  4),   CFrame.new(-140, 63, -120), "Bright yellow",  "Neon",        w)
	local lhLight = Instance.new("PointLight")
	lhLight.Brightness = 8; lhLight.Color = Color3.fromRGB(255, 240, 180); lhLight.Range = 120; lhLight.Shadows = true
	lhLight.Parent = w.LighthouseLight
	billboard(w.LighthouseLight, "⚓ Lighthouse", 5)

	-- ── Village detail — barrels, crates, fence, fire ─────────────────────────
	-- Barrels
	for i = 1, 3 do
		local b = part("Barrel"..i, Vector3.new(3, 4, 3), CFrame.new(-115+(i*5), 18, 28), "Reddish brown", "WoodPlanks", w)
		b.Shape = Enum.PartType.Cylinder
	end
	-- Water barrel
	local wb = part("WaterBarrel", Vector3.new(3, 5, 3), CFrame.new(-90, 18, 28), "Dark blue", "WoodPlanks", w)
	wb.Shape = Enum.PartType.Cylinder
	-- Crates at stall
	part("Crate1", Vector3.new(5, 5, 5), CFrame.new(-107, 19, 20), "Brick yellow",  "WoodPlanks", w)
	part("Crate2", Vector3.new(5, 5, 5), CFrame.new(-113, 19, 20), "Dark orange",   "WoodPlanks", w)
	part("Crate3", Vector3.new(5, 4, 5), CFrame.new(-107, 24, 20), "Brick yellow",  "WoodPlanks", w)
	-- Fence posts around village
	for i = 0, 7 do
		part("FencePost"..i, Vector3.new(1, 5, 1), CFrame.new(-140 + i*10, 19, -30), "Brown", "WoodPlanks", w)
		if i < 7 then
			part("FenceRail"..i, Vector3.new(10, 1, 0.5), CFrame.new(-135 + i*10, 21, -30), "Brown", "WoodPlanks", w)
		end
	end
	-- Village campfire
	local fireBase  = part("CampfireBase",  Vector3.new(4, 1, 4), CFrame.new(-90, 18, -22), "Medium dark flesh", "WoodPlanks", w)
	local fireLogs  = part("CampfireLogs",  Vector3.new(3, 2, 3), CFrame.new(-90, 19, -22), "Reddish brown",     "WoodPlanks", w)
	fireLogs.Shape  = Enum.PartType.Ball
	local fireGlow  = part("CampfireGlow",  Vector3.new(2, 3, 2), CFrame.new(-90, 21, -22), "Bright orange",     "Neon",       w)
	fireGlow.Shape  = Enum.PartType.Ball
	local fireLight = Instance.new("PointLight")
	fireLight.Brightness = 5; fireLight.Color = Color3.fromRGB(255, 130, 40); fireLight.Range = 18; fireLight.Shadows = true
	fireLight.Parent = fireGlow
	local smoke = Instance.new("Smoke")
	smoke.Color = Color3.fromRGB(120, 110, 100)
	smoke.Opacity = 0.12; smoke.RiseVelocity = 5; smoke.Size = 1.5
	smoke.Parent = fireGlow

	-- ── Harbor & dock detail ──────────────────────────────────────────────────
	-- Crates at dock
	for i = 1, 4 do
		part("DockCrate"..i, Vector3.new(6, 5, 6),
			CFrame.new(90 + (i%2)*7, 20, 12-(i*6)),
			i%2==0 and "Dark orange" or "Brick yellow", "WoodPlanks", w)
	end
	-- Dock railings
	for i = 0, 5 do
		part("DockRailL"..i, Vector3.new(1, 5, 1), CFrame.new(80 + i*7, 21, -13), "Reddish brown", "WoodPlanks", w)
		part("DockRailR"..i, Vector3.new(1, 5, 1), CFrame.new(80 + i*7, 21,  13), "Reddish brown", "WoodPlanks", w)
	end
	part("DockRailTop",  Vector3.new(42, 1, 1), CFrame.new(100, 24, -13), "Reddish brown", "WoodPlanks", w)
	part("DockRailTopR", Vector3.new(42, 1, 1), CFrame.new(100, 24,  13), "Reddish brown", "WoodPlanks", w)
	-- Anchor
	part("Anchor", Vector3.new(5, 9, 2), CFrame.new(88, 19, 0), "Dark stone grey", "Metal", w)
	billboard(w.Anchor, "⚓ Anchor", 7)
	-- Cannon on dock
	local cannon = part("DockCannon", Vector3.new(5, 5, 12), CFrame.new(130, 20, -4)*CFrame.Angles(0, 0.3, 0), "Dark stone grey", "Metal", w)
	cannon.Shape = Enum.PartType.Cylinder
	-- Cannonballs pile
	for i = 1, 3 do
		local cb = part("Cannonball"..i, Vector3.new(2.5,2.5,2.5), CFrame.new(126+(i*1.5), 19, -8), "Dark stone grey", "Metal", w)
		cb.Shape = Enum.PartType.Ball
	end
	-- Dock lanterns
	for i = 0, 2 do
		local dlp = part("DockLanternPost"..i, Vector3.new(1, 10, 1), CFrame.new(85+i*20, 24, -15), "Reddish brown", "WoodPlanks", w)
		local dll = part("DockLantern"..i,     Vector3.new(2, 3, 2),  CFrame.new(85+i*20, 30, -15), "Bright yellow",  "Neon",       w)
		local dLight = Instance.new("PointLight")
		dLight.Brightness = 3; dLight.Color = Color3.fromRGB(255, 200, 80); dLight.Range = 22; dLight.Shadows = true
		dLight.Parent = dll
	end

	-- ── Ship detail ───────────────────────────────────────────────────────────
	-- Rope coils
	part("RopeCoil1", Vector3.new(4, 1, 4), CFrame.new(155, 21, 6), "Brick yellow",      "Fabric", w)
	part("RopeCoil2", Vector3.new(3, 1, 3), CFrame.new(175, 21, -7),"Brick yellow",      "Fabric", w)
	-- Ship cannons on deck (both sides)
	for i = 0, 1 do
		local sc = part("ShipCannon"..i..".L", Vector3.new(4, 4, 11), CFrame.new(158+i*16, 21, 9)*CFrame.Angles(0,0,0), "Dark stone grey", "Metal", w)
		sc.Shape = Enum.PartType.Cylinder
		local sc2 = sc:Clone(); sc2.Name = "ShipCannon"..i..".R"; sc2.CFrame = CFrame.new(158+i*16, 21, -9)*CFrame.Angles(0,math.pi,0); sc2.Parent = w
	end
	-- Treasure chest on deck (quest reward visual)
	part("TreasureChestBody",  Vector3.new(6, 4, 4), CFrame.new(172, 22, 5), "Dark orange",   "WoodPlanks",   w)
	part("TreasureChestLid",   Vector3.new(6, 2, 4), CFrame.new(172, 25, 5)*CFrame.Angles(0.3,0,0), "Dark orange",   "WoodPlanks",   w)
	part("TreasureChestGold",  Vector3.new(5, 1, 3), CFrame.new(172, 23, 5), "Bright yellow", "Neon",          w).Transparency = 0.3
	local tcLight = Instance.new("PointLight")
	tcLight.Brightness = 2; tcLight.Color = Color3.fromRGB(255, 215, 60); tcLight.Range = 10
	tcLight.Parent = w.TreasureChestGold
	billboard(w.TreasureChestBody, "🏴 Treasure Chest", 5)
	-- Ship flag
	part("ShipFlag", Vector3.new(8, 5, 0.4), CFrame.new(165, 100, 0)*CFrame.Angles(0,0,-0.05), "Bright blue", "Fabric", w)
	part("ShipFlagSkull", Vector3.new(5, 3, 0.4), CFrame.new(165, 100, 0)*CFrame.Angles(0,0,-0.05), "White", "Neon", w).Transparency = 0.4
	-- Ship steering cabin back wall
	part("SteeringCabin", Vector3.new(14, 10, 3), CFrame.new(147, 24, 0), "Reddish brown", "Wood", w)
	-- Hanging lanterns x2
	part("HangLantern1", Vector3.new(2, 3, 2), CFrame.new(160, 27, 8),  "Bright yellow", "Neon", w)
	part("HangLantern2", Vector3.new(2, 3, 2), CFrame.new(160, 27, -8), "Bright yellow", "Neon", w)
	for _, ln in {"HangLantern1","HangLantern2"} do
		local hl = Instance.new("PointLight"); hl.Brightness=2.5; hl.Color=Color3.fromRGB(255,190,70); hl.Range=14; hl.Parent=w[ln]
	end

	-- ── Rock formations and coral near island ─────────────────────────────────
	local ROCKS = {{-160,5,-90,9,16},{170,5,-80,7,12},{-180,5,100,11,18},{200,5,80,6,10},{-170,5,50,8,14}}
	for i, r in ROCKS do
		part("Rock"..i,    Vector3.new(r[4], r[5],  r[4]), CFrame.new(r[1], -3+r[5]/2, r[3]),  "Dark stone grey", "Rock",         w)
		part("RockTop"..i, Vector3.new(r[4]-2, 5, r[4]-2), CFrame.new(r[1]+1, r[5]-1, r[3]-1),"Medium stone grey","SmoothPlastic",w)
	end
	-- Coral patches (neon for underwater feel in shallow water)
	local CORALS = {{160,-5,-40,"Cyan"},{175,-5,-55,"Hot pink"},{190,-5,-45,"Bright orange"},{155,-5,-65,"Cyan"}}
	for i, c in CORALS do
		local co = part("Coral"..i, Vector3.new(5,8,5), CFrame.new(c[1], c[2]+4, c[3]), c[4], "Neon", w)
		co.Transparency = 0.35
	end

	-- ── Grotto atmosphere ─────────────────────────────────────────────────────
	-- Bioluminescent walls
	for i = 1, 6 do
		local angle = (i/6) * math.pi * 2
		local cx = 165 + math.cos(angle)*9
		local cz = -92 + math.sin(angle)*9
		local gwall = part("GrottoWall"..i, Vector3.new(4, 18, 4), CFrame.new(cx, 2, cz), "Dark blue", "SmoothPlastic", w)
		gwall.Transparency = 0.15
		local glow = part("GrottoGlow"..i, Vector3.new(2, 2, 2), CFrame.new(cx, 5+i*1.5, cz), "Cyan", "Neon", w)
		glow.Shape = Enum.PartType.Ball
		glow.Transparency = 0.3
		local gl = Instance.new("PointLight"); gl.Color = Color3.fromRGB(60,220,220); gl.Brightness=1.5; gl.Range=14; gl.Parent=glow
	end

	-- ── Rival ship detail ─────────────────────────────────────────────────────
	-- Rival skulls on hull
	-- Rival ship mast light
	part("RivalSail",   Vector3.new(0.5, 28, 18), CFrame.new(330, 50, 60),  "Dark stone grey","Fabric", w)
	part("RivalCabin",  Vector3.new(14, 10, 3),   CFrame.new(316, 24, 60),  "Dark stone grey","Wood",   w)
	part("RivalMast",   Vector3.new(3,  50,  3),  CFrame.new(330, 40, 60),  "Reddish brown",  "WoodPlanks", w)
	-- Skulls on railing (dark neon orbs)
	for i = 0, 3 do
		local skull = part("RivalSkull"..i, Vector3.new(2,2,2), CFrame.new(320+i*8, 22, 71), "Dark stone grey", "SmoothPlastic", w)
		skull.Shape = Enum.PartType.Ball
	end
	local rivalLight = Instance.new("PointLight"); rivalLight.Brightness=1.5; rivalLight.Color=Color3.fromRGB(180,30,30); rivalLight.Range=40; rivalLight.Parent=w.RivalMast

	print("[WorldBuilder] ✅  Detail pass complete — lighthouse, palms, shore, barrels, crates, dock, cannons, treasure chest, grotto, coral, rival details built")
end

return WorldBuilderService

