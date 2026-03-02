-- WorldBuilderService.luau
-- Procedurally creates the island, ship, dock, all trigger zones (Levels 1-5)
-- and food pickup items. Works fully in Studio, no assets required.

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
-- ── NPC dialogue tables (level-keyed) ────────────────────────────────────────
local NPC_DIALOGUE = {
	Sam = {
		[1] = {
			"(whispering) Listen — the old merchant leaves the stall unguarded at noon.",
			"We grab that roast chicken, sprint through the alley, and meet back in the field. Fast.",
			"Don't get caught. I'm serious. These people know how to throw things.",
		},
		[2] = {
			"Right — we've cleared the harbor. The sea is open.",
			"I found a map fragment on that crab. There's an island three days east — the Sunken Grotto.",
			"Hoist the sails. Every hour counts.",
		},
		[3] = {
			"That wasn't a storm. That was a warning.",
			"The hull is cracked below the waterline — we patch it or we sink.",
			"I'll man the helm. You handle the repairs. Do it NOW.",
		},
		[4] = {
			"The pearls are down in the grotto. Old navigation charts say they unlock the treasure vault.",
			"One problem: there's something large down there. Something that circles.",
			"Dive fast. Collect all three. Don't linger.",
		},
		[5] = {
			"That's the Crimson Revenge — Captain Dread's flagship.",
			"He has the final chart piece. On his mast. Under his flag.",
			"We board. We take the flag. We come back. Simple as that. Let's go.",
		},
	},
	Rosa = {
		[1] = {"I've got the distraction covered. Just follow Sam's signal and run.", "And don't trip this time."},
		[2] = {"I spotted a crab the size of a wagon near the eastern rock.", "It's guarding something. Bring a weapon... or just improvise."},
		[3] = {"I'm patching the sails. The mast is holding, barely.", "Get below and seal that leak before we take on more water."},
		[4] = {"I'll keep the lantern lit on the bow. Three flashes means shark is near.", "Don't ignore three flashes."},
		[5] = {"Dread's crew is skeleton-thin. They won't expect a frontal boarding.", "I'll swing in from starboard. Cover your flank."},
	},
	Jin = {
		[1] = {"Reminds me of the merchant quarter back home.", "Though the chickens there were less... unguarded."},
		[2] = {"First time past the reef. Feels different out here.", "Bigger. Quieter. I like it."},
		[3] = {"I've sailed through worse. Once.", "...Actually no I haven't. Patch that hull fast."},
		[4] = {"The grotto glows blue-green from here. Bioluminescent algae, maybe.", "Beautiful. Also terrifying."},
		[5] = {"I've been waiting to face Dread since the harbour at Port Kiral.", "Today's the day."},
	},
}

function WorldBuilderService.init(services)
	local hungerService  = services.HungerService
	local storyService   = services.StoryService
	local remoteService  = services.RemoteService
	local ws             = game:GetService("Workspace")

	local function fireDialogue(player, speaker, level)
		local npcData = NPC_DIALOGUE[speaker]
		if not npcData then return end
		local profile = services.ProfileService.getProfile(player)
		local lvl     = profile and math.clamp(profile.storyLevel, 1, 5) or 1
		local lines   = npcData[lvl] or npcData[1]
		remoteService.getRemote("ShowDialogue"):FireClient(player, {speaker=speaker, lines=lines})
	end

	local w = Instance.new("Folder")
	w.Name   = "PirateWorld"
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

	-- ── village (Level 1 — steal_chicken) ────────────────────────────────────
	part("VillageGround", Vector3.new(70, 4, 70),   CFrame.new(-105, 14, 0), "Nougat",         "Cobblestone", w)
	for i = 1, 3 do
		local ox = -120 + (i - 1) * 22
		part("Hut"..i,     Vector3.new(14, 18, 14), CFrame.new(ox,       26, -8), "Reddish brown",  "Brick",       w)
		wedge("Roof"..i,   Vector3.new(14,  6, 14), CFrame.new(ox,       38, -8), "Bright red",     w)
	end
	-- market stall
	part("Stall",          Vector3.new(10,  1, 6),  CFrame.new(-100,     17, 12), "Brick yellow",   "WoodPlanks",  w)
	part("StallCanopy",    Vector3.new(12,  0.5, 7),CFrame.new(-100,     20, 12), "Bright red",     "SmoothPlastic",w)
	-- torch
	part("VillageTorch",   Vector3.new(1,   8, 1),  CFrame.new(-115,     21, 14), "Dark orange",    "SmoothPlastic",w)
	local tfl = Instance.new("PointLight")
	tfl.Brightness = 4; tfl.Color = Color3.fromRGB(255, 160, 60); tfl.Range = 16
	tfl.Parent = w.VillageTorch

	-- Chicken prop (ball in stall)
	local chicken = part("Chicken",   Vector3.new(3, 3, 3),    CFrame.new(-97,      19, 12), "White",          "SmoothPlastic",w)
	chicken.Shape = Enum.PartType.Ball
	billboard(chicken, "🍗 Roast Chicken", 4)
	local chickenPP = prompt(chicken, "Grab", "Roast Chicken", 9)
	chickenPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "steal_chicken") end)

	-- ── field (Level 1 — meet_friends) ───────────────────────────────────────
	part("Field",          Vector3.new(90, 4,  90),  CFrame.new(0,       14, 0),   "Bright green",   "Grass",     w)
	-- some trees
	for _, tp in {{-20, 0, -25}, {15, 0, 28}, {-30, 0, 20}} do
		part("TreeTrunk"..tp[1], Vector3.new(4,22,4), CFrame.new(tp[1], 25, tp[3]), "Reddish brown", "WoodPlanks", w)
		part("TreeTop" ..tp[1], Vector3.new(16,14,16),CFrame.new(tp[1], 42, tp[3]), "Bright green",  "Grass",      w)
	end
	-- crew NPCs — colored humanoid stand-ins with dialogue + quest trigger
	local CREW = {
		{name="Sam",  color="Bright blue",   isQuestNPC=true},
		{name="Rosa", color="Bright red",    isQuestNPC=false},
		{name="Jin",  color="Bright yellow", isQuestNPC=false},
	}
	for i, c in CREW do
		local npcPart = part(c.name.."_NPC", Vector3.new(4, 10, 4), CFrame.new(-18+(i*10), 21, -10), c.color, "SmoothPlastic", w)
		billboard(npcPart, c.name, 7)
		-- Eye-level dot
		local eyeDot = part(c.name.."_Eyes", Vector3.new(2.5,1,0.5), CFrame.new(-18+(i*10), 26, -10+(-0.5)), "White", "Neon", w)
		eyeDot.Transparency = 0
		local npcPP = prompt(npcPart, "Talk", c.name, 11)
		local cname = c.name
		local isQN  = c.isQuestNPC
		npcPP.Triggered:Connect(function(p)
			-- Always show dialogue
			fireDialogue(p, cname, nil)
			-- Sam also advances meet_friends quest
			if isQN then
				storyService.handleQuestAction(services, p, "meet_friends")
			end
		end)
	end

	-- ── harbor & dock (Level 1 — board_ship, Level 2+) ───────────────────────
	part("Harbor",        Vector3.new(90, 4, 50),   CFrame.new(110,      14, 0),   "Dark orange",    "Cobblestone", w)
	part("Dock",          Vector3.new(90, 5, 30),   CFrame.new(110,      15, 0),   "Reddish brown",  "WoodPlanks",  w)
	-- dock planks
	for i = 0, 8 do
		part("Plank"..i,  Vector3.new(88, 1, 3),    CFrame.new(110, 18, -10+(i*3)), "Medium dark flesh","WoodPlanks",w)
	end

	-- ── player-ship ──────────────────────────────────────────────────────────
	part("ShipHull",     Vector3.new(44, 18, 22),   CFrame.new(165,      9, 0),    "Dark orange",    "WoodPlanks",  w)
	part("ShipDeck",     Vector3.new(44,  3, 22),   CFrame.new(165,      19, 0),   "Medium dark flesh","WoodPlanks",w)
	part("ShipBow",      Vector3.new(22, 18, 22),   CFrame.new(165+22, 5, 0)*CFrame.Angles(0,0,-0.18),"Dark orange","WoodPlanks",w)
	part("Mast",         Vector3.new(3,  55, 3),    CFrame.new(165,      46, 0),   "Reddish brown",  "WoodPlanks",  w)
	part("Sail1",        Vector3.new(0.5,30, 20),   CFrame.new(165,      52, 0),   "White",          "Fabric",      w)
	local crownest = part("Crownest", Vector3.new(8, 4, 8), CFrame.new(165, 75, 0), "Reddish brown", "Wood", w)
	local crestPP = prompt(crownest, "Look Out", "Crow's Nest", 10)
	crestPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "spot_treasure_map") end)
	local shipWheel = part("ShipWheel", Vector3.new(4, 5, 1), CFrame.new(152, 22, 0), "Reddish brown", "Wood", w)
	local wfl = Instance.new("PointLight")
	wfl.Brightness = 3; wfl.Color = Color3.fromRGB(255, 200, 100); wfl.Range = 14
	wfl.Parent = shipWheel
	part("ShipLantern",  Vector3.new(2, 3, 2),      CFrame.new(178,      23, 0),   "Bright yellow",  "Neon",        w)
	local wheelPP = prompt(shipWheel, "Use", "Ship's Wheel", 10)
	-- Wheel handles: board_ship (L1), hoist_sail (L2), man_the_helm (L3), claim_victory (L5)
	wheelPP.Triggered:Connect(function(p)
		local profile = services.ProfileService.getProfile(p)
		if not profile then return end
		local step = profile.storyLevel == 1 and "board_ship"
			or profile.storyLevel == 2 and "hoist_sail"
			or profile.storyLevel == 3 and "man_the_helm"
			or profile.storyLevel == 5 and "claim_victory" or nil
		if step then storyService.handleQuestAction(services, p, step) end
	end)

	-- eastern rock (Level 2 — fight_crab)
	part("EasternRock",  Vector3.new(20, 14, 20),   CFrame.new(210,      10, -60),  "Medium stone grey","SmoothPlastic",w)
	part("RockTop",      Vector3.new(22, 6, 22),    CFrame.new(210,      20, -60),  "Dark stone grey", "SmoothPlastic",w)
	-- crab prop
	local crab = part("GiantCrab", Vector3.new(8, 5, 8), CFrame.new(210, 24, -60), "Bright red", "SmoothPlastic", w)
	billboard(crab, "🦀 Giant Sand Crab", 5)
	local crabPP = prompt(crab, "Fight!", "Giant Sand Crab", 12)
	crabPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "fight_crab") end)

	-- storm zone (Level 3)
	part("StormMarker",  Vector3.new(10, 1, 10),    CFrame.new(250,      18, 0),   "Dark blue-violet","Neon",        w).Transparency = 0.5
	local hullLeak = part("HullLeak", Vector3.new(5, 6, 5), CFrame.new(168, 13, 10), "Bright blue", "Neon", w)
	hullLeak.Transparency = 0.45
	billboard(hullLeak, "⚠️ Hull Breach!", 5)
	local leakPP = prompt(hullLeak, "Patch", "Hull Breach", 9)
	leakPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "patch_hull") end)
	part("CalmCove", Vector3.new(30, 4, 30), CFrame.new(280, 14, 60), "Bright blue", "SmoothPlastic", w).Transparency = 0.55

	-- grotto (Level 4)
	local grotto = part("GrottoEntrance", Vector3.new(20, 20, 20), CFrame.new(160, 5, -90), "Dark blue", "SmoothPlastic", w)
	grotto.Transparency = 0.3
	billboard(grotto, "🌊 Sunken Grotto", 12)
	local grottoPP = prompt(grotto, "Dive In", "Sunken Grotto", 14)
	grottoPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "dive_in") end)

	local pearls = part("ReefPearls", Vector3.new(12, 8, 12), CFrame.new(185, 5, -100), "Cyan", "Neon", w)
	pearls.Transparency = 0.35
	billboard(pearls, "💎 Ancient Pearls", 6)
	local pearlsPP = prompt(pearls, "Collect", "Glowing Pearls", 12)
	pearlsPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "collect_pearls") end)

	local ladder = part("EscapeLadder", Vector3.new(3, 20, 3), CFrame.new(155, 10, -80), "Reddish brown", "Wood", w)
	billboard(ladder, "🏃 Escape Route!", 12)
	local ladderPP = prompt(ladder, "Climb!", "Escape Ladder", 10)
	ladderPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "escape_shark") end)

	-- rival ship (Level 5)
	part("RivalHull",    Vector3.new(44, 18, 22),   CFrame.new(330, 9, 60),       "Dark stone grey","WoodPlanks",   w)
	part("RivalDeck",    Vector3.new(44, 3, 22),    CFrame.new(330, 19, 60),      "Medium stone grey","WoodPlanks", w)
	part("RivalMast",    Vector3.new(3, 55, 3),     CFrame.new(330, 46, 60),      "Dark stone grey","WoodPlanks",   w)
	local rivalFlag = part("RivalFlag", Vector3.new(10, 7, 0.5), CFrame.new(330, 76, 60), "Bright red", "Fabric", w)
	billboard(rivalFlag, "☠️ Rival Captain's Flag", 5)
	local flagPP = prompt(rivalFlag, "Steal", "Rival Flag", 10)
	flagPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "steal_flag") end)
	-- Board rival: ProximityPrompt on rival deck
	local boardRivalPP = prompt(w.RivalDeck, "Board!", "Rival Ship", 16)
	boardRivalPP.Triggered:Connect(function(p) storyService.handleQuestAction(services, p, "board_rival") end)

	-- ──────────────────────────────────────────────────────────────────────────
	-- SPAWN LOCATION
	local sp = Instance.new("SpawnLocation")
	sp.Size        = Vector3.new(16, 1, 16)
	sp.CFrame      = CFrame.new(-90, 19, 35)
	sp.BrickColor  = BrickColor.new("Bright yellow")
	sp.Neutral     = true
	sp.Duration    = 0
	sp.Parent      = ws

	-- ── TRIGGER ZONES ─────────────────────────────────────────────────────────
	-- Level 1
	local z_chicken = zone("L1_Chicken",  Vector3.new(14, 9, 14),  Vector3.new(-97,      20, 12), "Steal the Chicken!",   w)
	local z_friends = zone("L1_Friends",  Vector3.new(18, 9, 18),  Vector3.new(0,        21, -10),"Meet Your Crew",        w)
	local z_board   = zone("L1_Board",    Vector3.new(20, 9, 22),  Vector3.new(145,      22, 0),  "Board the Ship!",      w)
	-- Level 2
	local z_wheel   = zone("L2_Wheel",    Vector3.new(8, 9, 5),    Vector3.new(152,      24, 0),  "Hoist the Sails!",     w)
	local z_crows   = zone("L2_Crows",    Vector3.new(10, 6, 10),  Vector3.new(165,      76, 0),  "Spot the Map!",        w)
	local z_crab    = zone("L2_Crab",     Vector3.new(16, 9, 16),  Vector3.new(210,      24, -60),"Fight the Crab!",      w)
	-- Level 3
	local z_helm    = zone("L3_Helm",     Vector3.new(8, 9, 5),    Vector3.new(152,      24, 0),  "Man the Helm!",        w)
	local z_leak    = zone("L3_Leak",     Vector3.new(9, 9, 9),    Vector3.new(168,      17, 10), "Patch the Hull!",      w)
	local z_cove    = zone("L3_Cove",     Vector3.new(25, 6, 25),  Vector3.new(280,      17, 60), "Anchor at Safe Cove!", w)
	-- Level 4
	local z_dive    = zone("L4_Dive",     Vector3.new(14, 9, 14),  Vector3.new(160,      14, -90),"Dive into the Grotto!", w)
	local z_pearls  = zone("L4_Pearls",   Vector3.new(16, 9, 16),  Vector3.new(185,      10, -100),"Collect the Pearls!",  w)
	local z_escape  = zone("L4_Escape",   Vector3.new(9, 22, 9),   Vector3.new(155,      15, -80),"Escape the Shark!",    w)
	-- Level 5
	local z_rival   = zone("L5_Rival",    Vector3.new(20, 9, 22),  Vector3.new(310,      22, 60), "Board the Rival Ship!",w)
	local z_flag    = zone("L5_Flag",     Vector3.new(14, 9, 14),  Vector3.new(330,      78, 60), "Steal the Flag!",      w)
	local z_victory = zone("L5_Victory",  Vector3.new(20, 9, 22),  Vector3.new(165,      22, 0),  "Claim Victory!",       w)

	local ZONE_MAP = {
		[z_chicken] = "steal_chicken",
		[z_friends] = "meet_friends",
		[z_board]   = "board_ship",
		[z_wheel]   = "hoist_sail",
		[z_crows]   = "spot_treasure_map",
		[z_crab]    = "fight_crab",
		[z_helm]    = "man_the_helm",
		[z_leak]    = "patch_hull",
		[z_cove]    = "anchor_safe",
		[z_dive]    = "dive_in",
		[z_pearls]  = "collect_pearls",
		[z_escape]  = "escape_shark",
		[z_rival]   = "board_rival",
		[z_flag]    = "steal_flag",
		[z_victory] = "claim_victory",
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

	print("[WorldBuilder] ✅  Island, ship, rival ship, 15 trigger zones, 7 food pickups — built")
end

return WorldBuilderService
