-- StoryService.luau  (One Piece Edition)
-- Server-authoritative quest state machine covering 11 arcs / 24 levels.
-- Public: init(services)  sendCurrentState(services, player)  handleQuestAction(services, player, actionId)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames       = require(ReplicatedStorage.Shared.Net.RemoteNames)

local StoryService = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- ARC + LEVEL DEFINITIONS
-- ══════════════════════════════════════════════════════════════════════════════
local LEVELS = {
	-- ARC 1 — EAST BLUE
	[1] = {
		arc = 1, title = "Arc 1 — Romance Dawn", island = "Foosha Village", villain = "None yet",
		steps = {"find_hat", "meet_zoro", "recruit_usopp"},
		objectives = {
			find_hat      = "Find Shanks' straw hat at the cliff shrine!",
			meet_zoro     = "Free Roronoa Zoro from the Marine base at Shells Town!",
			recruit_usopp = "Visit Syrup Village and recruit the brave sniper Usopp!",
		},
		reward = 80, bountyGain = 30000000, crewUnlock = "zoro", powerUnlock = nil,
	},
	[2] = {
		arc = 1, title = "Arc 1 — Baratie & The Cook", island = "Baratie Restaurant", villain = "Don Krieg",
		steps = {"stop_krieg", "recruit_sanji", "set_sail_grandline"},
		objectives = {
			stop_krieg         = "Defeat Don Krieg's fleet at the Baratie sea restaurant!",
			recruit_sanji      = "Convince Sanji to leave the Baratie and join the crew!",
			set_sail_grandline = "Man the Going Merry — sail for the Grand Line!",
		},
		reward = 100, bountyGain = 0, crewUnlock = "sanji", powerUnlock = nil,
	},
	-- ARC 2 — ARLONG PARK
	[3] = {
		arc = 2, title = "Arc 2 — Nami's Tears", island = "Cocoyasi Village", villain = "Arlong",
		steps = {"find_nami", "destroy_arlong_park", "read_nami_map"},
		objectives = {
			find_nami           = "Follow Nami to Arlong Park — her village is enslaved!",
			destroy_arlong_park = "Gum-Gum Pistol through Arlong's fish-man castle!",
			read_nami_map       = "Retrieve Nami's sea charts and free Cocoyasi Village!",
		},
		reward = 150, bountyGain = 70000000, crewUnlock = "nami", powerUnlock = nil,
	},
	-- ARC 3 — LOGUETOWN
	[4] = {
		arc = 3, title = "Arc 3 — End of East Blue", island = "Loguetown", villain = "Smoker",
		steps = {"visit_execution_platform", "find_gold_roger_sword", "escape_smoker"},
		objectives = {
			visit_execution_platform = "Stand on Gold Roger's execution platform!",
			find_gold_roger_sword    = "Buy the legendary cutlass at Loguetown market!",
			escape_smoker            = "Flee from White Hunter Smoker into the Grand Line!",
		},
		reward = 120, bountyGain = 0, crewUnlock = nil, powerUnlock = nil,
	},
	-- ARC 4 — ALABASTA SAGA
	[5] = {
		arc = 4, title = "Arc 4 — Drum Island Snow", island = "Drum Island", villain = "Wapol",
		steps = {"climb_drum_rockies", "recruit_chopper", "defeat_wapol"},
		objectives = {
			climb_drum_rockies = "Carry Nami through the snowstorm up Drum Rockies!",
			recruit_chopper    = "Befriend the reindeer doctor Tony Tony Chopper!",
			defeat_wapol       = "Defeat the selfish king Wapol!",
		},
		reward = 180, bountyGain = 0, crewUnlock = "chopper", powerUnlock = nil,
	},
	[6] = {
		arc = 4, title = "Arc 4 — Alabasta Desert March", island = "Alabasta", villain = "Crocodile",
		steps = {"cross_desert", "find_baroque_works", "reach_alubarna"},
		objectives = {
			cross_desert       = "March across Alabasta's desert to reach the capital Alubarna!",
			find_baroque_works = "Uncover Baroque Works' plot to start a civil war!",
			reach_alubarna     = "Race to Alubarna — stop the civil war!",
		},
		reward = 220, bountyGain = 0, crewUnlock = nil, powerUnlock = nil,
	},
	[7] = {
		arc = 4, title = "Arc 4 — Crocodile Showdown", island = "Alabasta (Tomb of Kings)", villain = "Crocodile",
		steps = {"first_clash_crocodile", "use_water", "final_gum_gum_storm"},
		objectives = {
			first_clash_crocodile = "First clash with Crocodile — his sand drains your strength!",
			use_water             = "Soak yourself in water — wet skin defeats sand absorption!",
			final_gum_gum_storm   = "Burst underground and launch Gum-Gum Storm into the sky!",
		},
		reward = 280, bountyGain = 200000000, crewUnlock = "robin", powerUnlock = nil,
	},
	-- ARC 5 — SKYPIEA
	[8] = {
		arc = 5, title = "Arc 5 — Climb to the Sky", island = "Jaya / Knock-Up Stream", villain = "Bellamy",
		steps = {"find_jaya_clue", "defeat_bellamy", "ride_knockup_stream"},
		objectives = {
			find_jaya_clue      = "Search Jaya Island for the Upper Yard map!",
			defeat_bellamy      = "Teach Bellamy a lesson — Spring-Spring Fruit trickster!",
			ride_knockup_stream = "Pilot the Going Merry into the Knock-Up Stream!",
		},
		reward = 200, bountyGain = 100000000, crewUnlock = nil, powerUnlock = "Observation_1",
	},
	[9] = {
		arc = 5, title = "Arc 5 — God Enel", island = "Skypiea — Upper Yard", villain = "Enel",
		steps = {"explore_upper_yard", "survive_survival_game", "defeat_enel"},
		objectives = {
			explore_upper_yard    = "Explore Upper Yard and uncover Skypiea's ancient history!",
			survive_survival_game = "Survive Enel's cruel 5-person survival game!",
			defeat_enel           = "Rubber beats lightning — strike God Enel down!",
		},
		reward = 300, bountyGain = 0, crewUnlock = nil, powerUnlock = "Observation_2",
	},
	-- ARC 6 — WATER 7 / ENIES LOBBY
	[10] = {
		arc = 6, title = "Arc 6 — Water Seven", island = "Water 7", villain = "CP9 (Lucci)",
		steps = {"sell_gold", "going_merry_farewell", "find_robin"},
		objectives = {
			sell_gold            = "Sell Skypiea gold at Water 7's auction houses!",
			going_merry_farewell = "The Going Merry is too damaged — say your goodbyes.",
			find_robin           = "Robin surrendered to CP9 — track them to the Sea Train!",
		},
		reward = 250, bountyGain = 0, crewUnlock = "franky", powerUnlock = "Armament_1",
	},
	[11] = {
		arc = 6, title = "Arc 6 — Enies Lobby Assault", island = "Enies Lobby", villain = "Rob Lucci",
		steps = {"ring_golden_bell", "declare_war", "defeat_rob_lucci"},
		objectives = {
			ring_golden_bell = "Climb Enies Lobby tower and ring the golden bell!",
			declare_war      = "Burn the World Government flag — declare war for Robin!",
			defeat_rob_lucci = "Gum-Gum vs Rokuogan — defeat Rob Lucci of CP9!",
		},
		reward = 400, bountyGain = 400000000, crewUnlock = nil, powerUnlock = "Armament_2",
	},
	-- ARC 7 — THRILLER BARK
	[12] = {
		arc = 7, title = "Arc 7 — Ship of Shadows", island = "Thriller Bark", villain = "Gecko Moria",
		steps = {"board_thriller_bark", "recruit_brook", "recover_shadows"},
		objectives = {
			board_thriller_bark = "Board the massive ghost ship Thriller Bark before dawn!",
			recruit_brook       = "Free the living skeleton Brook from Gecko Moria's collection!",
			recover_shadows     = "Moria stole your crew's shadows — recover them before sunrise!",
		},
		reward = 350, bountyGain = 300000000, crewUnlock = "brook", powerUnlock = nil,
	},
	[13] = {
		arc = 7, title = "Arc 7 — Oars and Moria", island = "Thriller Bark", villain = "Oars / Moria",
		steps = {"defeat_oars", "final_thriller_battle", "zoro_sacrifice"},
		objectives = {
			defeat_oars           = "Combine attacks to take down the zombie giant Oars!",
			final_thriller_battle = "Moria enters Oars — Gear Third finisher!",
			zoro_sacrifice        = "Witness Zoro take all of Luffy's pain from Kuma...",
		},
		reward = 420, bountyGain = 0, crewUnlock = nil, powerUnlock = nil,
	},
	-- ARC 8 — MARINEFORD
	[14] = {
		arc = 8, title = "Arc 8 — Impel Down Break-in", island = "Impel Down", villain = "Magellan",
		steps = {"infiltrate_impel_down", "survive_magellan_poison", "escape_with_allies"},
		objectives = {
			infiltrate_impel_down   = "Sneak into Impel Down — the world's most secure prison!",
			survive_magellan_poison = "Survive Magellan's Hydra poison — find an antidote!",
			escape_with_allies      = "Free Crocodile, Ivankov, and 200 prisoners — break OUT!",
		},
		reward = 380, bountyGain = 0, crewUnlock = "jinbei", powerUnlock = "Conquerors_1",
	},
	[15] = {
		arc = 8, title = "Arc 8 — Marineford War", island = "Marineford", villain = "Akainu",
		steps = {"reach_execution_platform", "save_ace", "survive_akainu"},
		objectives = {
			reach_execution_platform = "Fight through the entire Navy — reach Ace!",
			save_ace                 = "Break Ace's chains — the brothers are reunited!",
			survive_akainu           = "Akainu's magma killed Ace... survive long enough for Shanks.",
		},
		reward = 500, bountyGain = 400000000, crewUnlock = nil, powerUnlock = "Conquerors_2",
	},
	[16] = {
		arc = 8, title = "Arc 8 — The Two Years", island = "Rusukaina (Training)", villain = "None",
		steps = {"train_with_rayleigh", "master_haki", "reunite_at_sabaody"},
		objectives = {
			train_with_rayleigh  = "Train under Dark King Rayleigh — learn Haki basics!",
			master_haki          = "Endure 2 years of Haki training — all three types!",
			reunite_at_sabaody   = "Return to Sabaody — the whole crew reunites!",
		},
		reward = 450, bountyGain = 0, crewUnlock = nil, powerUnlock = "Gear_4_preview",
	},
	-- ARC 9 — PUNK HAZARD
	[17] = {
		arc = 9, title = "Arc 9 — Punk Hazard Arrival", island = "Punk Hazard", villain = "Caesar Clown",
		steps = {"explore_fire_side", "explore_ice_side", "find_kidnapped_children"},
		objectives = {
			explore_fire_side       = "Navigate the burning half of Punk Hazard!",
			explore_ice_side        = "Cross the frozen half — find Caesar's secret labs!",
			find_kidnapped_children = "Caesar kidnapped children for experiments — rescue them!",
		},
		reward = 300, bountyGain = 0, crewUnlock = nil, powerUnlock = "Armament_3",
	},
	[18] = {
		arc = 9, title = "Arc 9 — Caesar Clown", island = "Punk Hazard", villain = "Caesar & Vergo",
		steps = {"defeat_vergo", "neutralize_smiley", "capture_caesar"},
		objectives = {
			defeat_vergo      = "Defeat the corrupt Navy commander Vergo!",
			neutralize_smiley = "Stop gas-weapon monster Smiley from spreading!",
			capture_caesar    = "Capture Caesar Clown for Law's plan!",
		},
		reward = 380, bountyGain = 0, crewUnlock = nil, powerUnlock = nil,
	},
	-- ARC 10 — DRESSROSA
	[19] = {
		arc = 10, title = "Arc 10 — Dressrosa Colosseum", island = "Dressrosa", villain = "Doflamingo",
		steps = {"enter_colosseum", "fight_as_lucy", "reach_birdcage"},
		objectives = {
			enter_colosseum = "Enter the Corrida Colosseum as 'Lucy' — fight for Ace's fruit!",
			fight_as_lucy   = "Battle through all blocks — warriors from the New World!",
			reach_birdcage  = "Doflamingo's Birdcage activates — strings slice everything!",
		},
		reward = 400, bountyGain = 0, crewUnlock = nil, powerUnlock = "Gear_4_Bounceman",
	},
	[20] = {
		arc = 10, title = "Arc 10 — String vs Rubber", island = "Dressrosa (Royal Palace)", villain = "Doflamingo",
		steps = {"law_saves_riku", "gear_fourth_first", "king_kong_gun"},
		objectives = {
			law_saves_riku   = "Push back the Birdcage — citizens hold the strings!",
			gear_fourth_first= "Activate Gear Fourth for the first time — Bounce Man!",
			king_kong_gun    = "Gum-Gum King Kong Gun — end Doflamingo's Paramount Delusion!",
		},
		reward = 550, bountyGain = 1500000000, crewUnlock = nil, powerUnlock = nil,
	},
	-- ARC 11 — WANO
	[21] = {
		arc = 11, title = "Arc 11 — Wano Act 1", island = "Wano Country", villain = "Orochi / Beast Pirates",
		steps = {"infiltrate_wano", "find_tama", "escape_gifters"},
		objectives = {
			infiltrate_wano = "Wash ashore in Wano — disguise as a soba cook!",
			find_tama       = "Find little Tama before the Beast Pirates do!",
			escape_gifters  = "Escape the Gifters — SMILE fruit users of the Beast Pirates!",
		},
		reward = 400, bountyGain = 0, crewUnlock = nil, powerUnlock = nil,
	},
	[22] = {
		arc = 11, title = "Arc 11 — Wano Act 2: Udon Prison", island = "Wano — Udon Prison", villain = "Kaido (Dragon)",
		steps = {"first_clash_kaido", "survive_udon", "free_prisoners"},
		objectives = {
			first_clash_kaido = "Kaido defeats you in one strike. Get back up.",
			survive_udon      = "Endure Udon prison — forge strength in chains!",
			free_prisoners    = "Awaken the samurai alliance — free Udon!",
		},
		reward = 450, bountyGain = 0, crewUnlock = nil, powerUnlock = "Conquerors_3",
	},
	[23] = {
		arc = 11, title = "Arc 11 — Onigashima Fire Festival", island = "Onigashima", villain = "Kaido & Big Mom",
		steps = {"infiltrate_onigashima", "rooftop_five_vs_two", "advanced_conquerors"},
		objectives = {
			infiltrate_onigashima = "Storm Onigashima with the full alliance under Fire Festival cover!",
			rooftop_five_vs_two   = "Five Supernovas vs Kaido and Big Mom on the rooftop!",
			advanced_conquerors   = "Coat your attacks with Conqueror's Haki — lightning from your fists!",
		},
		reward = 520, bountyGain = 0, crewUnlock = nil, powerUnlock = "Gear_5_preview",
	},
	[24] = {
		arc = 11, title = "Arc 11 — Gear Five: The Sun God", island = "Onigashima Skull Dome", villain = "Kaido (Full Power)",
		steps = {"gear_5_awakening", "drums_of_liberation", "final_punch_kaido"},
		objectives = {
			gear_5_awakening    = "The Gum-Gum Fruit awakens — Mythical Human-Human Model: Nika!",
			drums_of_liberation = "The Drums of Liberation beat — hope rises across all of Wano!",
			final_punch_kaido   = "Freedom Punch — Kaido falls. Wano is free.",
		},
		reward = 800, bountyGain = 1500000000, crewUnlock = nil, powerUnlock = "Gear_5",
	},
}

local MAX_LEVEL = #LEVELS

-- ──────────────────────────────── HELPERS ────────────────────────────────────
local function getCurrentStep(profile)
	local lvlDef = LEVELS[profile.storyLevel]
	if not lvlDef then return nil, nil end
	for _, stepId in lvlDef.steps do
		if not profile.storyFlags[stepId] then
			return stepId, lvlDef
		end
	end
	return nil, lvlDef
end

local function buildPayload(profile)
	local lvlDef = LEVELS[profile.storyLevel]
	if not lvlDef then
		return {
			arc       = 11,
			chapter   = "🏴‍☠️ King of the Pirates!",
			objective = "One Piece found. The freedom of the seas is yours.",
			level     = profile.storyLevel,
			island    = "Laugh Tale",
			villain   = "None",
			bounty    = profile.bounty or 3000000000,
		}
	end
	local stepId = getCurrentStep(profile)
	if not stepId then
		return {
			arc       = lvlDef.arc,
			chapter   = lvlDef.title .. " — Complete!",
			objective = "Set sail for the next island!",
			level     = profile.storyLevel,
			island    = lvlDef.island,
			villain   = lvlDef.villain,
			bounty    = profile.bounty or 0,
		}
	end
	return {
		arc       = lvlDef.arc,
		chapter   = lvlDef.title,
		objective = lvlDef.objectives[stepId],
		level     = profile.storyLevel,
		island    = lvlDef.island,
		villain   = lvlDef.villain,
		bounty    = profile.bounty or 0,
	}
end

-- ──────────────────────────────── PUBLIC API ──────────────────────────────────
function StoryService.handleQuestAction(services, player, actionId)
	local profile = services.ProfileService.getProfile(player)
	if not profile then return end
	if type(actionId) ~= "string" then return end

	local stepId, lvlDef = getCurrentStep(profile)
	if not stepId then return end
	if actionId ~= stepId then return end

	profile.storyFlags[stepId] = true

	local allDone = true
	for _, s in lvlDef.steps do
		if not profile.storyFlags[s] then allDone = false; break end
	end

	if allDone then
		-- Award berries
		services.ProfileService.incrementCoins(player, lvlDef.reward)
		-- Award bounty
		if lvlDef.bountyGain and lvlDef.bountyGain > 0 then
			profile.bounty = (profile.bounty or 0) + lvlDef.bountyGain
		end
		-- Power unlock flag
		if lvlDef.powerUnlock then
			profile.storyFlags["POWER_" .. lvlDef.powerUnlock] = true
		end

		-- LevelComplete cinematic
		local lcRemote = services.RemoteService.getRemote(RemoteNames.LevelComplete)
		if lcRemote then
			lcRemote:FireClient(player, {
				levelTitle  = lvlDef.title,
				island      = lvlDef.island,
				villain     = lvlDef.villain,
				reward      = lvlDef.reward,
				bountyGain  = lvlDef.bountyGain,
				powerUnlock = lvlDef.powerUnlock,
				crewUnlock  = lvlDef.crewUnlock,
			})
		end

		-- Advance
		if profile.storyLevel < MAX_LEVEL then
			task.wait(1.5)
			profile.storyLevel = profile.storyLevel + 1
		else
			profile.storyLevel = MAX_LEVEL + 1
		end
	end

	StoryService.sendCurrentState(services, player)
end

function StoryService.init(services)
	local remoteService     = services.RemoteService
	local questActionRemote = remoteService.getRemote(RemoteNames.RequestQuestAction)
	if questActionRemote then
		questActionRemote.OnServerEvent:Connect(function(player, actionId)
			if not remoteService.guard(player) then return end
			StoryService.handleQuestAction(services, player, actionId)
		end)
	end
	print("[StoryService] One Piece Edition — " .. MAX_LEVEL .. " levels across 11 arcs")
end

function StoryService.sendCurrentState(services, player)
	local profile = services.ProfileService.getProfile(player)
	if not profile then return end
	local remote = services.RemoteService.getRemote(RemoteNames.StoryStateUpdated)
	if remote then remote:FireClient(player, buildPayload(profile)) end
end

return StoryService
