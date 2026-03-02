-- OnePieceConfig.luau
-- Master data for the One Piece Roblox RPG.
-- Contains: Arcs, Crew, Devil Fruits, Haki, Villains, Cosmetics.

local Config = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- STRAW HAT CREW
-- Joined progressively as the game advances through arcs.
-- ══════════════════════════════════════════════════════════════════════════════
Config.CREW = {
	{
		id       = "zoro",
		name     = "Roronoa Zoro",
		role     = "Swordsman",
		joinArc  = 1,   -- East Blue (Shells Town)
		color    = Color3.fromRGB(0, 180, 80),
		quote    = "I'm going to be the world's greatest swordsman!",
		dialogue = {
			[1]  = "You really did eat a Devil Fruit, huh? Don't expect me to save you if you fall in the ocean.",
			[2]  = "That Arlong thinks fish-men are better than humans. I'll cut that arrogance right out of him.",
			[3]  = "Loguetown... the Gold Roger executed right here. Makes you feel it.",
			[4]  = "This desert is brutal. But I've trained in worse. Let's move.",
			[5]  = "Enel calls himself a God. He's just another enemy for me to beat.",
			[6]  = "Robin... she's been alone her whole life. We protect our own.",
			[7]  = "Thriller Bark? A ghost ship bigger than an island. Only in the Grand Line.",
			[8]  = "Ace... Luffy will never forgive himself if something happens to him.",
			[9]  = "Punk Hazard. Split between fire and ice. Sounds like a good warm-up.",
			[10] = "Doflamingo runs Dressrosa like a puppet master. Cut every string.",
			[11] = "Kaido. The creature who cannot die. Then I'll just have to try harder.",
		},
	},
	{
		id       = "nami",
		name     = "Nami",
		role     = "Navigator",
		joinArc  = 2,   -- Arlong Park
		color    = Color3.fromRGB(255, 165, 0),
		quote    = "I'm not your friend! I'm a navigator!",
		dialogue = {
			[1]  = "You fought Zoro for his swords? You're insane.",
			[2]  = "Arlong took everything from my village. This is MY fight too.",
			[3]  = "The Log Pose is set! Next stop — the Grand Line. No turning back now.",
			[4]  = "I can read the weather in Alabasta... but this storm is unlike anything I've charted.",
			[5]  = "Sky Island? An island in the clouds? Even I couldn't map THAT.",
			[6]  = "Robin said 'I want to live.' That's enough for me. We're going to Enies Lobby.",
			[7]  = "Gecko Moria stole your shadow? Get it back before sunrise or you turn to dust!",
			[8]  = "The war at Marineford... I've never seen Luffy look like that before.",
			[9]  = "This island is split — one side fire, one side ice. Typical Grand Line nonsense.",
			[10] = "Dressrosa has a dark history under Doflamingo. Let's rewrite the chart.",
			[11] = "Wano is a closed country. No Log Pose works here. We navigate by star.",
		},
	},
	{
		id       = "usopp",
		name     = "Usopp",
		role     = "Sniper",
		joinArc  = 1,   -- East Blue (Kaya's Village)
		color    = Color3.fromRGB(200, 140, 60),
		quote    = "I am the great Captain Usopp! 8000 followers await my word!",
		dialogue = {
			[1]  = "Ha ha ha! I, the great Captain Usopp, will defeat you! ...Please don't hurt me.",
			[2]  = "Arlong's crew has armored skin. My slingshot will find the weak spots, I promise!",
			[3]  = "Loguetown is where the Pirate King was born AND executed. Kinda unlucky...",
			[4]  = "I'm not scared of a desert! ...It's the giant lizards I'm scared of.",
			[5]  = "God Enel has mantra — he can read our minds! But he can't read what DOESN'T exist... my lies!",
			[6]  = "I should have stayed... I should have fought harder. For Robin.",
			[7]  = "Perona's Negative Hollows make you feel hopeless... but I'm already a coward! It had no effect!",
			[8]  = "Ace is Luffy's brother. I never knew. We have to pay back that debt.",
			[9]  = "I'm Usopp — greatest sniper! (Please let there be nothing dangerous on this frozen fire island.)",
			[10] = "This is a COLOSSEUM fight. My new slingshot will find the range easily. Easily!",
			[11] = "Wano's samurai are incredible! I've totally trained just as hard. Definitely.",
		},
	},
	{
		id       = "sanji",
		name     = "Sanji",
		role     = "Cook",
		joinArc  = 1,   -- Baratie (East Blue)
		color    = Color3.fromRGB(255, 220, 80),
		quote    = "Food is a gift from the heavens. I'll feed anyone who's hungry.",
		dialogue = {
			[1]  = "Cook's honor: I'll never fight with my hands. My legs are all I need.",
			[2]  = "Nami-san~! Don't worry, I'll defeat every fish-man for your beautiful smile!",
			[3]  = "Loguetown. The end of East Blue and the beginning of everything else.",
			[4]  = "The sands of Alabasta burn. I'll cook something to keep everyone's spirits up.",
			[5]  = "Sky Island cuisine might be something special. Once we deal with Enel, obviously.",
			[6]  = "Robin chose death once already. We're telling the whole world she has the right to live.",
			[7]  = "Thriller Bark food is probably terrible. A chef's nightmare.",
			[8]  = "The Navy has Akainu... the man who killed Ace. My flames burn cold next to that.",
			[9]  = "A scientist experimenting on children? I'll kick him into next week.",
			[10] = "Dressrosa. I sense a beautiful woman is somewhere in this country.",
			[11] = "Wano soba noodles! I must learn the recipe. After we defeat Kaido.",
		},
	},
	{
		id       = "chopper",
		name     = "Tony Tony Chopper",
		role     = "Doctor",
		joinArc  = 4,   -- Drum Island / Alabasta saga
		color    = Color3.fromRGB(80, 210, 240),
		quote    = "I'm not happy that you called me cute! ...okay maybe a little.",
		dialogue = {
			[4]  = "I ate the Human-Human Fruit and became something between reindeer and human. Drum Island taught me medicine is for saving people.",
			[5]  = "Sky Island has strange plants. My Rumble Ball needs 6 hours between uses — critical weakness.",
			[6]  = "Patch Robin's wounds? She's been fighting since she was eight years old. That's not okay.",
			[7]  = "Hogback... you were a brilliant doctor who sold out everything. I'll never forgive you.",
			[8]  = "Luffy's taking on the whole Navy to save Ace. As his doctor, I have to stay and help.",
			[9]  = "Caesar's gas weapons won't affect me — I researched an antidote. Maybe.",
			[10] = "Dressrosa's sick children — I'll cure every one of them!",
			[11] = "Wano's doctors are amazing! We'll need everyone healthy to fight Kaido.",
		},
	},
	{
		id       = "robin",
		name     = "Nico Robin",
		role     = "Archaeologist",
		joinArc  = 4,   -- Post-Alabasta
		color    = Color3.fromRGB(180, 80, 200),
		quote    = "I want to live.",
		dialogue = {
			[4]  = "I spent twenty years running. The Poneglyph in Alabasta guided me here. Now I stay.",
			[5]  = "The golden bell of Skypiea... it's connected to Laugh Tale. I must read every inscription.",
			[6]  = "My message to the World Government: I heard the Buster Call for the first time when I was eight. I will not run again.",
			[7]  = "Moria controls dead bodies with shadow power. Grotesque... but also scientifically fascinating.",
			[8]  = "The history I seek is connected to the Void Century. The Navy will never let me stop.",
			[9]  = "The Poneglyphs speak of a weapon called Pluton. The information on this island is dangerous.",
			[10] = "Doflamingo was a Celestial Dragon once. The cruelty inherent in that bloodline runs deep.",
			[11] = "Wano holds a Road Poneglyph. The path to Laugh Tale continues.",
		},
	},
	{
		id       = "franky",
		name     = "Franky",
		role     = "Shipwright",
		joinArc  = 6,   -- Water 7 / Enies Lobby
		color    = Color3.fromRGB(30, 120, 255),
		quote    = "SUPER! I built the Thousand Sunny with my own hands!",
		dialogue = {
			[6]  = "The Going Merry gave her last breath. So I built the Thousand Sunny — for the crew's future. SUPER!",
			[7]  = "Thriller Bark is a ship bigger than Oars. As a shipwright, I'm equal parts horrified and impressed.",
			[8]  = "Marineford burns. The Thousand Sunny is waiting. Luffy — we sail when you're ready.",
			[9]  = "FRANKY SHOGUN! I brought a giant mech robot to Punk Hazard. You're welcome.",
			[10] = "Dressrosa toy soldiers — those are real people transformed! My weapons will free them all!",
			[11] = "Wano samurai tech meets Vegapunk science at Kaido's mountain. SUPER challenge!",
		},
	},
	{
		id       = "brook",
		name     = "Brook",
		role     = "Musician / Swordsman",
		joinArc  = 7,   -- Thriller Bark
		color    = Color3.fromRGB(240, 240, 240),
		quote    = "Yohohoho! May I see your panties? SKULL JOKE!",
		dialogue = {
			[7]  = "Fifty years I waited on Thriller Bark alone... Soul King Brook is finally going home. Yohohoho!",
			[8]  = "I cannot die — but I felt death grip the crew at Marineford. Music does not mend all wounds.",
			[9]  = "Punk Hazard... even a skeleton feels cold here.",
			[10] = "Dressrosa has flamenco dancing! I would tap my feet but... they're bones. Yohohoho!",
			[11] = "Wano — they have shamisen! I must jam with Lord Yasuie's musicians. For the soul!",
		},
	},
	{
		id       = "jinbei",
		name     = "Jinbei",
		role     = "Helmsman",
		joinArc  = 8,   -- Post-Marineford / Fish-Man Island
		color    = Color3.fromRGB(20, 60, 180),
		quote    = "I will take the helm of the Thousand Sunny!",
		dialogue = {
			[8]  = "I poured my blood into Luffy's veins at Marineford. My life is bound to this crew now.",
			[9]  = "Punk Hazard has connections to the New Fishman Pirates' drug trade. I'll look into it.",
			[10] = "Doflamingo held Fish-Man Island in his shadow. That debt is repaid today.",
			[11] = "Kaido and Big Mom in alliance — this is the fiercest battle the world will see. Strike true!",
		},
	},
}

-- ══════════════════════════════════════════════════════════════════════════════
-- DEVIL FRUITS
-- ══════════════════════════════════════════════════════════════════════════════
Config.DEVIL_FRUITS = {
	GumGum = {
		id        = "GumGum",
		realName  = "Hito Hito no Mi, Model: Nika",
		display   = "Gum-Gum Fruit (Mythical Zoan)",
		type      = "Mythical Zoan",
		user      = "Luffy",
		moves     = {
			basic   = { name = "Gum-Gum Pistol",   desc = "Stretching straight punch." },
			power   = { name = "Gum-Gum Bazooka",  desc = "Two-fisted stretched double punch." },
			special = { name = "Gum-Gum Gatling",  desc = "Rapid-fire barrage of stretched fists." },
		},
		gears     = {
			[2] = { name = "Gear Second",  desc = "Blood pumping accelerates — speed and power multiplied. Red steam aura." },
			[3] = { name = "Gear Third",   desc = "Inflate bone marrow — limbs become giant. Massive damage, slight slowdown." },
			[4] = { name = "Gear Fourth",  desc = "Bounce-Man — compressed rubber with Armament Haki. Extreme speed and power." },
		},
	},
}

-- ══════════════════════════════════════════════════════════════════════════════
-- HAKI SYSTEM
-- ══════════════════════════════════════════════════════════════════════════════
Config.HAKI = {
	Observation = {
		id       = "Observation",
		name     = "Kenbunshoku Haki",
		display  = "Observation Haki",
		desc     = "Sense enemy intent. Dodge attacks you cannot see.",
		unlockArc= 5,  -- Skypiea (Mantra)
		levels   = {
			[1] = "Basic aura sensing — slight dodge boost.",
			[2] = "Future sight glimpse — brief slow-motion warning.",
			[3] = "Full future sight — predict enemy moves 2 seconds ahead.",
		},
	},
	Armament = {
		id       = "Armament",
		name     = "Busoshoku Haki",
		display  = "Armament Haki",
		desc     = "Harden body and weapons with invisible armor. Damage Logia users.",
		unlockArc= 6,  -- Enies Lobby
		levels   = {
			[1] = "Basic coat — slight damage boost, can hit Logia.",
			[2] = "Full armor — significantly increased strength and defense.",
			[3] = "Emission — project Haki outward, remote damage without contact.",
		},
	},
	Conquerors = {
		id       = "Conquerors",
		name     = "Haoshoku Haki",
		display  = "Conqueror's Haki",
		desc     = "The rarest Haki. Overwhelm weak-willed enemies with your spirit alone.",
		unlockArc= 8,  -- Marineford
		levels   = {
			[1] = "Burst — AoE knockdown of nearby weak enemies.",
			[2] = "Advanced — lightning aura coating on attacks.",
			[3] = "Perfected — imbue weapons; clash creates lightning shockwave.",
		},
	},
}

-- ══════════════════════════════════════════════════════════════════════════════
-- VILLAINS
-- ══════════════════════════════════════════════════════════════════════════════
Config.VILLAINS = {
	[1]  = { name = "Buggy the Clown",    arc = "East Blue — Orange Town",     fruit = "Bara Bara no Mi (Chop-Chop)",         threat = 1 },
	[2]  = { name = "Arlong",             arc = "East Blue — Arlong Park",      fruit = "Saw-Sword (no fruit)",               threat = 2 },
	[3]  = { name = "Smoker",             arc = "Loguetown",                    fruit = "Moku Moku no Mi (Smoke-Smoke)",       threat = 2 },
	[4]  = { name = "Crocodile",          arc = "Alabasta",                     fruit = "Suna Suna no Mi (Sand-Sand Logia)",   threat = 4 },
	[5]  = { name = "Enel",               arc = "Skypiea",                      fruit = "Goro Goro no Mi (Thunder-Thunder)",   threat = 5 },
	[6]  = { name = "Rob Lucci",          arc = "Enies Lobby",                  fruit = "Neko Neko no Mi, Leopard Zoan",       threat = 6 },
	[7]  = { name = "Gecko Moria",        arc = "Thriller Bark",                fruit = "Kage Kage no Mi (Shadow-Shadow)",     threat = 5 },
	[8]  = { name = "Akainu",             arc = "Marineford",                   fruit = "Magu Magu no Mi (Magma-Magma Logia)", threat = 9 },
	[9]  = { name = "Caesar Clown",       arc = "Punk Hazard",                  fruit = "Gasu Gasu no Mi (Gas-Gas Logia)",     threat = 6 },
	[10] = { name = "Doflamingo",         arc = "Dressrosa",                    fruit = "Ito Ito no Mi (String-String)",       threat = 8 },
	[11] = { name = "Kaido",              arc = "Wano Country",                 fruit = "Uo Uo no Mi, Model: Azure Dragon",    threat = 10 },
}

-- ══════════════════════════════════════════════════════════════════════════════
-- SHIPS
-- ══════════════════════════════════════════════════════════════════════════════
Config.SHIPS = {
	{ id = "going_merry",    name = "Going Merry",    arcRange = {1, 5},   color = Color3.fromRGB(200, 200, 200) },
	{ id = "thousand_sunny", name = "Thousand Sunny", arcRange = {6, 11},  color = Color3.fromRGB(240, 220, 50)  },
}

-- ══════════════════════════════════════════════════════════════════════════════
-- COSMETICS (Berry Shop)
-- ══════════════════════════════════════════════════════════════════════════════
Config.COSMETICS = {
	{ id = "straw_hat",      name = "Straw Hat",           price = 0,    desc = "Luffy's iconic straw hat. A promise from Shanks." },
	{ id = "red_vest",       name = "Red Vest",            price = 200,  desc = "Luffy's classic red vest from the East Blue." },
	{ id = "gear2_aura",     name = "Gear Second Aura",    price = 500,  desc = "Red steam trails follow your every move." },
	{ id = "gear4_coat",     name = "Gear Fourth Coat",    price = 800,  desc = "Massive tattoo-patterned bouncing-man look." },
	{ id = "jolly_roger",    name = "Straw Hat Jolly Roger",price = 150, desc = "The skull with the straw hat. Fly it proud." },
	{ id = "wano_kimono",    name = "Wano Kimono",         price = 1000, desc = "The kimono Luffy wore during the raid on Onigashima." },
}

-- ══════════════════════════════════════════════════════════════════════════════
-- BOUNTY MILESTONES (replaces coin display for flavor)
-- Bounty increases with arc completion
-- ══════════════════════════════════════════════════════════════════════════════
Config.BOUNTY_BY_ARC = {
	[0]  = 0,
	[1]  = 30000000,    -- 30M  — East Blue clears
	[2]  = 100000000,   -- 100M — Arlong Park, Navy takes notice
	[3]  = 100000000,   -- still 100M through Loguetown
	[4]  = 300000000,   -- 300M — Alabasta, declared enemy of World Gov.
	[5]  = 400000000,   -- 400M — Skypiea, God Enel defeated
	[6]  = 800000000,   -- 400M->800M — Enies Lobby, declared war on World Gov.
	[7]  = 1100000000,  -- 1.1B — Thriller Bark
	[8]  = 1500000000,  -- 1.5B — Post-Marineford
	[9]  = 1500000000,  -- same through Punk Hazard
	[10] = 3000000000,  -- 3B   — Post-Dressrosa
	[11] = 3000000000,  -- Final arc
}

return Config
