-- IslandGeneratorService.luau  (One Piece Edition)
-- Infinite procedural world — islands auto-generate around players.
-- Chunk grid: 600×600 studs per cell.  Starting island is at chunk(0,0).
-- Uses seeded deterministic rand per chunk so islands are always the same.

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local IslandGeneratorService = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
local CHUNK_SIZE       = 600          -- studs per chunk
local GEN_RADIUS       = 2            -- chunks around player to generate
local ISLAND_CHANCE    = 0.55         -- probability chunk gets an island
local ISLAND_WATER_Y   = -2           -- island base starts here
local ISLAND_TOP_Y     = 14           -- island ground surface Y

-- Island themes by Manhattan distance from origin
local THEMES = {
	[0] = "foosha",     -- home island (already built, skip gen)
	[1] = "coastal",    -- East Blue style
	[2] = "marine",     -- Marine base
	[3] = "rocky",      -- Rocky cliffs
	[4] = "jungle",     -- Dense jungle
	[5] = "snowy",      -- Drum Island style
	[6] = "desert",     -- Alabasta style
	[7] = "skypiea",    -- Floating island / Skypiea
	[8] = "ruins",      -- Ancient ruins
}
local function getTheme(cx, cz)
	local dist = math.abs(cx) + math.abs(cz)
	return THEMES[math.min(dist, 8)] or "ruins"
end

-- One Piece island names by theme
local ISLAND_NAMES = {
	coastal = {"Orange Town", "Shells Town", "Cocoyasi Village", "Conomi Islands", "Gecko Islands"},
	marine  = {"Marine Base G-7", "Marine HQ Outpost", "Shells Town Guard Post", "Marine Station"},
	rocky   = {"Reverse Mountain", "Twin Capes", "East Blue Passage", "Rocky Shore"},
	jungle  = {"Calm Belt Shore", "Primeval Forest Isle", "Serpent Isle"},
	snowy   = {"Drum Island", "Wapol's Kingdom", "Sakura Kingdom", "Blizzard Cape"},
	desert  = {"Little Garden", "Alabasta Border", "Sandy Isle", "Crocus Isle"},
	skypiea = {"Jaya Seaport", "Mock Town", "Upper Yard Approach", "Shandora Ruins"},
	ruins   = {"Florian Triangle", "Thriller Bark Outskirts", "Moondrift Isle"},
	foosha  = {"Foosha Village"},
}
local function islandName(theme, seed)
	local list = ISLAND_NAMES[theme] or {"Unknown Isle"}
	return list[(seed % #list) + 1]
end

-- ══════════════════════════════════════════════════════════════════════════════
-- GENERATION HELPERS
-- ══════════════════════════════════════════════════════════════════════════════
local generatedChunks = {}  -- [key] = true

local function chunkKey(cx, cz) return cx .. "," .. cz end

local function seededRand(cx, cz, idx)
	-- Simple deterministic hash → 0..1
	local v = (cx * 73856093) ~ (cz * 19349663) ~ (idx * 83492791)
	v = v % 1000000
	return v / 1000000
end

local ws = game:GetService("Workspace")

local function getWorldFolder()
	local f = ws:FindFirstChild("ProceduralIslands")
	if not f then
		f = Instance.new("Folder"); f.Name = "ProceduralIslands"; f.Parent = ws
	end
	return f
end

-- Part builder
local function mkpart(name, size, cf, color, mat, parent)
	local p = Instance.new("Part")
	p.Name     = name; p.Size = size
	p.CFrame   = typeof(cf)=="CFrame" and cf or CFrame.new(cf)
	p.BrickColor = BrickColor.new(color)
	p.Material = Enum.Material[mat] or Enum.Material.SmoothPlastic
	p.Anchored = true; p.Parent = parent
	return p
end
local function mkwedge(name, size, cf, color, parent)
	local p = Instance.new("WedgePart")
	p.Name = name; p.Size = size
	p.CFrame = typeof(cf)=="CFrame" and cf or CFrame.new(cf)
	p.BrickColor = BrickColor.new(color)
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.Parent = parent
	return p
end
local function mkbillboard(parent, text, yOff)
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0,240,0,50); bg.StudsOffset = Vector3.new(0,yOff or 5,0)
	bg.AlwaysOnTop = false; bg.Parent = parent
	local fr = Instance.new("Frame"); fr.Size = UDim2.new(1,0,1,0)
	fr.BackgroundColor3 = Color3.fromRGB(8,12,24); fr.BackgroundTransparency=0.15
	fr.BorderSizePixel=0; fr.Parent=bg
	Instance.new("UICorner",fr).CornerRadius = UDim.new(0,8)
	local lb = Instance.new("TextLabel"); lb.Size=UDim2.new(1,-8,1,0)
	lb.Position=UDim2.fromOffset(4,0); lb.BackgroundTransparency=1
	lb.TextColor3=Color3.fromRGB(255,220,60); lb.Font=Enum.Font.GothamBold
	lb.TextSize=14; lb.TextWrapped=true; lb.Text=text; lb.Parent=fr
end
local function mkprompt(parent, action, obj, dist)
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText=action; pp.ObjectText=obj
	pp.MaxActivationDistance=dist or 10
	pp.HoldDuration=0; pp.RequiresLineOfSight=false
	pp.Parent=parent; return pp
end

-- ══════════════════════════════════════════════════════════════════════════════
-- ISLAND BUILDERS — one function per theme
-- ══════════════════════════════════════════════════════════════════════════════
type BuildCtx = {
	f: Instance,      -- parent folder
	ox: number, oz: number,  -- island centre world coords
	r: (idx: number) -> number,  -- seeded rand 0..1
	services: any,
}

local function addFood(ctx, x, z, foodType)
	local colors = {Coconut="Sand yellow", Mango="Bright orange", Fish="Bright blue", Bread="Brick yellow", Meat="Bright red"}
	local heals  = {Coconut=25, Mango=20, Fish=30, Bread=15, Meat=35}
	local y = ISLAND_TOP_Y + 4
	local fp = mkpart(foodType, Vector3.new(3.5,3.5,3.5), CFrame.new(x,y,z), colors[foodType] or "White", "Neon", ctx.f)
	fp.Shape = Enum.PartType.Ball
	mkbillboard(fp, foodType.." +"..heals[foodType].." Hunger", 3.5)
	local pp = mkprompt(fp, "Eat", foodType, 7)
	local heal = heals[foodType] or 20
	local hs   = ctx.services.HungerService
	local svcs = ctx.services
	pp.Triggered:Connect(function(p) hs.feedPlayer(svcs, p, heal) end)
	fp.Touched:Connect(function(hit)
		local char = hit.Parent
		local p = Players:GetPlayerFromCharacter(char)
		if p then hs.feedPlayer(svcs, p, heal) end
	end)
end

local function addNPC(ctx, x, z, npcName, lines, color)
	local npc = mkpart(npcName.."_NPC", Vector3.new(4,10,4), CFrame.new(x, ISLAND_TOP_Y+8, z), color or "Bright blue", "SmoothPlastic", ctx.f)
	mkbillboard(npc, npcName, 8)
	local pp  = mkprompt(npc, "Talk", npcName, 10)
	local srv = ctx.services.RemoteService
	pp.Triggered:Connect(function(p)
		local r = srv.getRemote("ShowDialogue")
		if r then r:FireClient(p, {speaker=npcName, lines=lines}) end
	end)
end

-- ── Coastal island (East Blue style) ─────────────────────────────────────────
local function buildCoastal(ctx)
	local ox, oz = ctx.ox, ctx.oz; local r = ctx.r; local f = ctx.f
	local sz = 140 + r(1)*60
	mkpart("CoastalIsland", Vector3.new(sz,22,sz), CFrame.new(ox,-3,oz), "Sand yellow", "Grass", f)
	mkpart("CoastalTop",    Vector3.new(sz-30,10,sz-30), CFrame.new(ox,8,oz), "Medium green", "Grass", f)
	-- beach ring
	mkpart("BeachN",Vector3.new(sz,5,20),CFrame.new(ox,7,oz-sz/2+10),"Sand yellow","Sand",f)
	mkpart("BeachS",Vector3.new(sz,5,20),CFrame.new(ox,7,oz+sz/2-10),"Sand yellow","Sand",f)
	-- 2-3 huts
	local numHuts = 2 + math.floor(r(2)*2)
	for i = 1, numHuts do
		local hx = ox + (r(10+i)-0.5)*sz*0.5
		local hz = oz + (r(20+i)-0.5)*sz*0.5
		mkpart("Hut"..i, Vector3.new(12,16,12), CFrame.new(hx,ISLAND_TOP_Y+8,hz), "Reddish brown","Brick",f)
		mkwedge("Roof"..i,Vector3.new(12,5,12),CFrame.new(hx,ISLAND_TOP_Y+19,hz),"Bright red",f)
	end
	-- palm trees
	for i = 1, 4 do
		local tx = ox+(r(30+i)-0.5)*sz*0.6; local tz = oz+(r(40+i)-0.5)*sz*0.6
		mkpart("Palm"..i.."T",Vector3.new(2,18,2),CFrame.new(tx,ISLAND_TOP_Y+9,tz),"Reddish brown","Bark",f)
		mkpart("Palm"..i.."L",Vector3.new(10,6,10),CFrame.new(tx,ISLAND_TOP_Y+20,tz),"Bright green","Grass",f)
	end
	-- food
	local foods = {"Coconut","Mango","Fish"}
	for i = 1, 3 do
		addFood(ctx, ox+(r(50+i)-0.5)*sz*0.4, oz+(r(60+i)-0.5)*sz*0.4, foods[i])
	end
	-- NPC
	local npcs = {
		{"Old Fisherman", {"The sea here is calm. Too calm.", "Something stirs in the Grand Line..."}, "Sand yellow"},
		{"Merchant Woman", {"I trade anything from the East Blue.", "Rum, maps, Devil Fruit rumours — name your price."}, "Bright orange"},
		{"Pirate Scout",  {"I spotted a Marine patrol two leagues north.", "Keep your head down and your sails low."}, "Dark orange"},
	}
	local n = npcs[1 + math.floor(r(70)*#npcs)]
	addNPC(ctx, ox+r(71)*20-10, oz+r(72)*20-10, n[1], n[2], n[3])
end

-- ── Marine base ───────────────────────────────────────────────────────────────
local function buildMarine(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	mkpart("MarineIsland",Vector3.new(160,22,160),CFrame.new(ox,-3,oz),"Sand yellow","Cobblestone",f)
	mkpart("MarineTop",   Vector3.new(130,10,130),CFrame.new(ox,8,oz),"Institutional white","SmoothPlastic",f)
	-- fort walls
	for _, side in {{0,-55},{0,55},{-55,0},{55,0}} do
		mkpart("Wall",Vector3.new(5,16,100),CFrame.new(ox+side[1],ISLAND_TOP_Y+8,oz+side[2]),"Institutional white","Brick",f)
	end
	mkpart("MarineFlag",Vector3.new(8,6,0.5),CFrame.new(ox,ISLAND_TOP_Y+30,oz),"Bright blue","Fabric",f)
	mkbillboard(w and w or mkpart("FlagPole",Vector3.new(2,20,2),CFrame.new(ox,ISLAND_TOP_Y+20,oz),"White","SmoothPlastic",f),"⚓ Marine Base",8)
	addFood(ctx, ox-10, oz-10, "Bread")
	addFood(ctx, ox+10, oz+10, "Fish")
	local lines = {
		"By order of the World Government, halt!",
		"Straw Hat Luffy — your bounty rises.",
		"This base is under Marine jurisdiction. Turn back."
	}
	addNPC(ctx, ox+20, oz+20, "Marine Captain", lines, "Bright blue")
end

-- ── Rocky cliff island ────────────────────────────────────────────────────────
local function buildRocky(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	mkpart("RockyBase",Vector3.new(180,30,180),CFrame.new(ox,-8,oz),"Dark stone grey","Rock",f)
	mkpart("RockyMid", Vector3.new(130,20,130),CFrame.new(ox, 8,oz),"Medium stone grey","Rock",f)
	mkpart("RockyTop", Vector3.new(80, 14, 80),CFrame.new(ox+r(1)*20-10,20,oz+r(2)*20-10),"Dark stone grey","Rock",f)
	-- spire
	mkwedge("Spire",Vector3.new(20,40,20),CFrame.new(ox,35,oz),"Medium stone grey",f)
	-- cave mouth
	local cave = mkpart("Cave",Vector3.new(14,14,4),CFrame.new(ox,ISLAND_TOP_Y+4,oz+40),"Black","SmoothPlastic",f)
	mkbillboard(cave,"🗺 Mysterious Cave",8)
	local pp = mkprompt(cave,"Explore","Sea Cave",12)
	pp.Triggered:Connect(function(p)
		local r2 = ctx.services.RemoteService.getRemote("ShowDialogue")
		if r2 then r2:FireClient(p,{speaker="Cave",lines={"The darkness is thick here...","Ancient markings line the walls.","A treasure map fragment gleams in the corner — but something else lurks."}}) end
	end)
	addFood(ctx, ox-20, oz+20, "Coconut")
	addFood(ctx, ox+25, oz-15, "Fish")
	addNPC(ctx,ox-30,oz-20,"Treasure Hunter",{"This island hides the treasure of an old pirate king.","I've been digging for three years. Getting closer."},"Dark orange")
end

-- ── Jungle island ─────────────────────────────────────────────────────────────
local function buildJungle(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	mkpart("JungleBase",Vector3.new(200,22,200),CFrame.new(ox,-3,oz),"Medium green","Grass",f)
	mkpart("JungleTop", Vector3.new(170,10,170),CFrame.new(ox, 8,oz),"Bright green","Grass",f)
	-- dense trees
	for i = 1, 10 do
		local tx=ox+(r(i)-0.5)*150; local tz=oz+(r(i+10)-0.5)*150
		local th = 20+r(i+20)*15
		mkpart("JTrunk"..i,Vector3.new(3,th,3),CFrame.new(tx,ISLAND_TOP_Y+th/2,tz),"Reddish brown","WoodPlanks",f)
		mkpart("JLeaf"..i,Vector3.new(14+r(i+30)*4,8,14+r(i+40)*4),CFrame.new(tx,ISLAND_TOP_Y+th+4,tz),"Bright green","Grass",f)
	end
	-- ancient giant flower prop
	local flower = mkpart("GiantFlower",Vector3.new(10,10,10),CFrame.new(ox,ISLAND_TOP_Y+5,oz+10),"Bright pink","SmoothPlastic",f)
	flower.Shape = Enum.PartType.Ball
	mkbillboard(flower,"🌸 Giant Sea Blossom",8)
	addFood(ctx, ox-15,oz-10,"Mango"); addFood(ctx, ox+10,oz+20,"Coconut"); addFood(ctx, ox-5,oz+30,"Meat")
	addNPC(ctx,ox+20,oz-20,"Tribal Elder",{"This jungle has stood for a thousand years.","The giant snake doesn't take kindly to outsiders.","But if you bring it food — it lets you pass."},"Medium green")
end

-- ── Snowy island (Drum Island style) ─────────────────────────────────────────
local function buildSnowy(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	mkpart("SnowyBase",Vector3.new(180,22,180),CFrame.new(ox,-3,oz),"White","Glacier",f)
	mkpart("SnowyTop", Vector3.new(150,12,150),CFrame.new(ox,9,oz),"White","Glacier",f)
	-- drum rockies style peaks
	for i = 1, 3 do
		local px=ox+(r(i)-0.5)*80; local pz=oz+(r(i+3)-0.5)*80
		mkpart("SnowPeak"..i,Vector3.new(30,50+r(i+6)*30,30),CFrame.new(px,30,pz),"White","Glacier",f)
		mkwedge("SnowTip"..i,Vector3.new(30,20,30),CFrame.new(px,70+r(i+6)*10,pz),"Institutional white",f)
	end
	-- frozen shrine
	local shrine = mkpart("FrozenShrine",Vector3.new(12,12,12),CFrame.new(ox,ISLAND_TOP_Y+6,oz),"Cyan","SmoothPlastic",f)
	mkbillboard(shrine,"❄️ Frozen Shrine",10)
	local pp = mkprompt(shrine,"Examine","Ice Shrine",10)
	pp.Triggered:Connect(function(p)
		local r2 = ctx.services.RemoteService.getRemote("ShowDialogue")
		if r2 then r2:FireClient(p,{speaker="Shrine",lines={"A rumble ball is sealed within the ice.","A reindeer once came here seeking medical knowledge.","The island still weeps for Dr. Hiluluk."}}) end
	end)
	addFood(ctx, ox-20,oz+15,"Meat"); addFood(ctx, ox+20,oz-15,"Fish")
	addNPC(ctx,ox-25,oz-25,"Frozen Doctor",{"This blizzard never stops. We call it the Drum.","The castle above — Wapol's old keep. Empty now.","Chopper left. The island blooms with cherry blossoms in his memory."},"White")
end

-- ── Desert island (Alabasta style) ────────────────────────────────────────────
local function buildDesert(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	mkpart("DesertBase",Vector3.new(200,22,200),CFrame.new(ox,-3,oz),"Sand yellow","Sand",f)
	mkpart("DesertTop", Vector3.new(170,8,170),CFrame.new(ox,7,oz),"Nougat","Sand",f)
	-- sandstone ruins / pillars
	for i = 1, 5 do
		local px=ox+(r(i)-0.5)*120; local pz=oz+(r(i+5)-0.5)*120
		mkpart("SandPillar"..i,Vector3.new(7,20+r(i+10)*15,7),CFrame.new(px,ISLAND_TOP_Y+15,pz),"Nougat","Brick",f)
	end
	-- oasis pool
	mkpart("Oasis",Vector3.new(20,2,20),CFrame.new(ox,ISLAND_TOP_Y+1,oz),"Bright blue","SmoothPlastic",f).Transparency=0.4
	local palmX,palmZ = ox+12,oz+5
	mkpart("OasisPalm",Vector3.new(2,16,2),CFrame.new(palmX,ISLAND_TOP_Y+8,palmZ),"Reddish brown","Bark",f)
	mkpart("OasisLeaf",Vector3.new(10,5,10),CFrame.new(palmX,ISLAND_TOP_Y+18,palmZ),"Bright green","Grass",f)
	mkbillboard(w and w or mkpart("OasisSign",Vector3.new(1,1,1),CFrame.new(ox,ISLAND_TOP_Y+5,oz-15),"Sand yellow","SmoothPlastic",f),"🐪 Desert Oasis",6)
	addFood(ctx, ox-10,oz+10,"Bread"); addFood(ctx, ox+15,oz-10,"Meat"); addFood(ctx, ox-20,oz-20,"Coconut")
	addNPC(ctx,ox+25,oz+20,"Desert Rebel",{"We used to be Alabasta's eastern outpost.","Crocodile's agents burned it. We remained.","If you seek the ancient poneglyph — look beneath the pyramid."},"Nougat")
end

-- ── Skypiea floating ruins ────────────────────────────────────────────────────
local function buildSkypiea(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	-- Main floating island higher up
	local floatY = 80
	mkpart("SkyBase",Vector3.new(160,20,160),CFrame.new(ox,floatY,oz),"Bright yellowish green","Grass",f)
	mkpart("SkyTop", Vector3.new(130,8,130),CFrame.new(ox,floatY+12,oz),"Bright green","Grass",f)
	-- stalactites hanging below
	for i = 1, 6 do
		local sx=ox+(r(i)-0.5)*130; local sz=oz+(r(i+6)-0.5)*130
		mkwedge("Stalagtite"..i,Vector3.new(8,15+r(i+12)*10,8),
			CFrame.new(sx,floatY-10,sz)*CFrame.Angles(math.pi,0,0),"Nougat",f)
	end
	-- golden bell tower
	mkpart("BellTower",Vector3.new(10,30,10),CFrame.new(ox,floatY+26,oz),"Bright yellow","SmoothPlastic",f)
	mkpart("Bell",     Vector3.new(8,8,8),CFrame.new(ox,floatY+50,oz),"Bright yellow","SmoothPlastic",f)
	mkbillboard(mkpart("BellTop",Vector3.new(1,1,1),CFrame.new(ox,floatY+58,oz),"Bright yellow","Neon",f),"🔔 Shandora's Bell",10)
	-- divine lightning pillar
	local pillar = mkpart("DivinePillar",Vector3.new(3,60,3),CFrame.new(ox+40,floatY+30,oz+40),"Bright yellow","Neon",f)
	pillar.Transparency = 0.6
	-- small sky islands around
	for i = 1, 3 do
		local mini_x=ox+(r(50+i)-0.5)*200; local mini_z=oz+(r(60+i)-0.5)*200
		local mini_y=floatY + (r(70+i)-0.5)*40
		mkpart("MiniSky"..i,Vector3.new(40,8,40),CFrame.new(mini_x,mini_y,mini_z),"Bright green","Grass",f)
		if i==1 then addFood({f=f,services=ctx.services,r=r},mini_x,mini_z,"Coconut") end
	end
	addFood(ctx,ox-10,oz-10,"Mango"); addFood(ctx,ox+15,oz+15,"Coconut")
	addNPC(ctx,ox-20,oz+20,"Shandoran Warrior",{"We rang the Golden Bell so Roger could hear it.","He heard it. Across all the seas he heard it.","Now Enel is gone. The sky is ours again."},"Bright yellow")
end

-- ── Ancient ruins ─────────────────────────────────────────────────────────────
local function buildRuins(ctx)
	local ox, oz = ctx.ox, ctx.oz; local f = ctx.f; local r = ctx.r
	mkpart("RuinsBase",Vector3.new(190,22,190),CFrame.new(ox,-3,oz),"Dark stone grey","Rock",f)
	mkpart("RuinsTop", Vector3.new(160,10,160),CFrame.new(ox,8,oz),"Medium stone grey","Cobblestone",f)
	-- crumbling walls
	for i = 1, 4 do
		local wx=ox+(r(i)-0.5)*130; local wz=oz+(r(i+4)-0.5)*130
		local wlen=30+r(i+8)*40
		mkpart("Wall"..i,Vector3.new(wlen,12+r(i)*8,4),CFrame.new(wx,ISLAND_TOP_Y+6,wz),"Dark stone grey","Brick",f)
	end
	-- central poneglyph-style stone
	local stone = mkpart("Poneglyph",Vector3.new(10,14,10),CFrame.new(ox,ISLAND_TOP_Y+7,oz),"Dark blue-violet","SmoothPlastic",f)
	mkbillboard(stone,"📜 Ancient Stone  [Poneglyph]",10)
	local pp = mkprompt(stone,"Read","Poneglyph",10)
	pp.Triggered:Connect(function(p)
		local r2 = ctx.services.RemoteService.getRemote("ShowDialogue")
		if r2 then r2:FireClient(p,{speaker="Poneglyph",lines={
			"The ancient script glows under your fingertips...",
			"'The One Piece — the treasure of the Pirate King — rests beyond the Final Island.'",
			"'Laugh Tale. Those who reach the end shall inherit the dawn.'"
		}}) end
	end)
	-- treasure chest
	local chest = mkpart("TreasureChest",Vector3.new(5,5,5),CFrame.new(ox+20,ISLAND_TOP_Y+5,oz-20),"Bright yellow","WoodPlanks",f)
	mkbillboard(chest,"💰 Treasure Chest",5)
	local cpp = mkprompt(chest,"Open","Treasure Chest",8)
	cpp.Triggered:Connect(function(p)
		local reward = 50 + math.floor(r(99)*100)
		ctx.services.ProfileService.incrementCoins(p, reward)
		local r2 = ctx.services.RemoteService.getRemote("ShowDialogue")
		if r2 then r2:FireClient(p,{speaker="Treasure",lines={"You found "..reward.." Berries!","The chest holds a faded logbook too.","'Beware the calm belt...'"}}) end
	end)
	addFood(ctx,ox-25,oz+15,"Fish"); addFood(ctx,ox+20,oz+20,"Bread")
	addNPC(ctx,ox+30,oz-25,"Archaeologist",{"I've spent my life decoding Poneglyphs.","This one speaks of joy — Joy Boy's promise.","The void century holds the answer. We just can't tell anyone."},"Cyan")
end

-- ══════════════════════════════════════════════════════════════════════════════
-- CHUNK GENERATION DISPATCHER
-- ══════════════════════════════════════════════════════════════════════════════
local BUILDERS = {
	coastal = buildCoastal, marine = buildMarine,  rocky   = buildRocky,
	jungle  = buildJungle,  snowy  = buildSnowy,   desert  = buildDesert,
	skypiea = buildSkypiea, ruins  = buildRuins,
}

local function generateChunk(cx, cz, services)
	local key = chunkKey(cx, cz)
	if generatedChunks[key] then return end
	generatedChunks[key] = true

	-- chunk (0,0) = home island, already built by WorldBuilderService
	if cx == 0 and cz == 0 then return end

	-- decide if this chunk has an island
	local roll = seededRand(cx, cz, 1)
	if roll > ISLAND_CHANCE then return end  -- empty ocean chunk

	-- island centre with small random offset
	local ox = cx * CHUNK_SIZE + (seededRand(cx, cz, 2) - 0.5) * 150
	local oz = cz * CHUNK_SIZE + (seededRand(cx, cz, 3) - 0.5) * 150

	local theme = getTheme(cx, cz)
	local seed  = math.floor(seededRand(cx, cz, 4) * 1000)
	local name  = islandName(theme, seed)

	local folder = Instance.new("Folder")
	folder.Name  = "Island_" .. key
	folder.Parent = getWorldFolder()

	local rFn = function(idx) return seededRand(cx + idx*0.1, cz + idx*0.1, idx) end

	local ctx = {f=folder, ox=ox, oz=oz, r=rFn, services=services}

	-- Add name billboard on a tall pole at island edge
	local pole = mkpart("NamePole",Vector3.new(2,40,2),CFrame.new(ox, ISLAND_TOP_Y+20, oz-80),"Reddish brown","WoodPlanks",folder)
	mkbillboard(pole, "📍 " .. name, 22)

	-- Build themed content
	local builder = BUILDERS[theme]
	if builder then
		local ok, err = pcall(builder, ctx)
		if not ok then warn("[IslandGen] chunk "..key.." error: "..tostring(err)) end
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TRACKING
-- ══════════════════════════════════════════════════════════════════════════════
local lastChunks = {}   -- [userId] = {cx, cz}

local function playerChunk(player)
	local char = player.Character
	if not char then return nil, nil end
	local hrp  = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, nil end
	local pos = hrp.Position
	return math.round(pos.X / CHUNK_SIZE), math.round(pos.Z / CHUNK_SIZE)
end

local function checkPlayer(player, services)
	local cx, cz = playerChunk(player)
	if not cx then return end

	local uid = player.UserId
	local last = lastChunks[uid]
	if last and last[1] == cx and last[2] == cz then return end
	lastChunks[uid] = {cx, cz}

	-- Generate radius around player
	for dx = -GEN_RADIUS, GEN_RADIUS do
		for dz = -GEN_RADIUS, GEN_RADIUS do
			task.defer(function()
				generateChunk(cx + dx, cz + dz, services)
			end)
		end
	end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PUBLIC
-- ══════════════════════════════════════════════════════════════════════════════
function IslandGeneratorService.init(services)
	-- Pre-generate starting area chunks
	for dx = -1, 1 do
		for dz = -1, 1 do
			task.delay(2 + (dx+1)*0.3 + (dz+1)*0.1, function()
				generateChunk(dx, dz, services)
			end)
		end
	end

	-- Periodic check loop
	local tick_acc = 0
	RunService.Heartbeat:Connect(function(dt)
		tick_acc = tick_acc + dt
		if tick_acc < 3 then return end
		tick_acc = 0
		for _, p in Players:GetPlayers() do
			task.spawn(checkPlayer, p, services)
		end
	end)

	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(2)
			checkPlayer(p, services)
		end)
	end)

	print("[IslandGenerator] Procedural infinite world active — chunk size " .. CHUNK_SIZE)
end

return IslandGeneratorService
