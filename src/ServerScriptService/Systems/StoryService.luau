-- StoryService.luau
-- Server-authoritative quest state machine — Levels 1-5.
-- Public: init(services)  sendCurrentState(services, player)  handleQuestAction(services, player, actionId)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames       = require(ReplicatedStorage.Shared.Net.RemoteNames)

local StoryService = {}

-- ── Level definitions ─────────────────────────────────────────────────────────
local LEVELS = {
	[1] = {
		title = "Level 1 — Chicken Dash",
		steps = {"steal_chicken", "meet_friends", "board_ship"},
		objectives = {
			steal_chicken = "Steal the roast chicken from the market stall!",
			meet_friends  = "Meet your crew in the sunny field.",
			board_ship    = "Reach the harbor and board the old pirate ship.",
		},
		reward = 100,
	},
	[2] = {
		title = "Level 2 — Out to Sea",
		steps = {"hoist_sail", "spot_treasure_map", "fight_crab"},
		objectives = {
			hoist_sail        = "Hoist the sails at the ship's wheel!",
			spot_treasure_map = "Climb to the crow's nest and spot the treasure map!",
			fight_crab        = "Defeat the giant sand crab at the eastern rock!",
		},
		reward = 150,
	},
	[3] = {
		title = "Level 3 — Storm Crossing",
		steps = {"man_the_helm", "patch_hull", "anchor_safe"},
		objectives = {
			man_the_helm = "Grab the helm and steer into the raging storm!",
			patch_hull   = "Find the hull leak and patch it before the ship sinks!",
			anchor_safe  = "Drop anchor in the calm cove beyond the storm!",
		},
		reward = 200,
	},
	[4] = {
		title = "Level 4 — Sunken Grotto",
		steps = {"dive_in", "collect_pearls", "escape_shark"},
		objectives = {
			dive_in        = "Leap off the bow and dive into the glowing grotto!",
			collect_pearls = "Collect the 3 glowing pearls from the ancient reef!",
			escape_shark   = "Swim back to the ladder — the shark is right behind you!",
		},
		reward = 250,
	},
	[5] = {
		title = "Level 5 — Rival Captain",
		steps = {"board_rival", "steal_flag", "claim_victory"},
		objectives = {
			board_rival   = "Swing across to the rival captain's ship!",
			steal_flag    = "Snatch the rival captain's flag from the mast!",
			claim_victory = "Return to your ship and raise the captured flag!",
		},
		reward = 350,
	},
}

local MAX_LEVEL = #LEVELS

-- ── helpers ───────────────────────────────────────────────────────────────────
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
			chapter   = "🏴‍☠️ All Levels Complete!",
			objective = "The Heart of Tides awaits. The ultimate treasure is near!",
			level     = profile.storyLevel,
		}
	end
	local stepId = getCurrentStep(profile)
	if not stepId then
		return {
			chapter   = lvlDef.title .. " — Complete!",
			objective = "Head back to the ship to set sail for the next voyage!",
			level     = profile.storyLevel,
		}
	end
	return {
		chapter   = lvlDef.title,
		objective = lvlDef.objectives[stepId],
		level     = profile.storyLevel,
	}
end

-- ── public API ────────────────────────────────────────────────────────────────
function StoryService.handleQuestAction(services, player: Player, actionId: string)
	local profile = services.ProfileService.getProfile(player)
	if not profile then return end

	local stepId, lvlDef = getCurrentStep(profile)
	if not stepId then return end
	if actionId ~= stepId then return end

	profile.storyFlags[stepId] = true
	print(string.format("[StoryService] %s completed '%s' (Level %d)", player.Name, stepId, profile.storyLevel))

	-- Check whether all steps in this level are now done
	local allDone = true
	for _, s in lvlDef.steps do
		if not profile.storyFlags[s] then allDone = false; break end
	end

	if allDone then
		services.ProfileService.incrementCoins(player, lvlDef.reward)
		print(string.format("[StoryService] 🎉 Level %d complete! +%d coins → %s", profile.storyLevel, lvlDef.reward, player.Name))
		-- Fire cinematic level-complete title card
		local lcRemote = services.RemoteService.getRemote("LevelComplete")
		if lcRemote then
			lcRemote:FireClient(player, {title = lvlDef.title .. " — Complete!", reward = lvlDef.reward})
		end
		if profile.storyLevel < MAX_LEVEL then
			task.wait(1.5)
			profile.storyLevel = profile.storyLevel + 1
		end
	end

	StoryService.sendCurrentState(services, player)
end

function StoryService.init(services)
	local remoteService     = services.RemoteService
	local questActionRemote = remoteService.getRemote(RemoteNames.RequestQuestAction)

	questActionRemote.OnServerEvent:Connect(function(player, actionId)
		if not remoteService.guard(player) then return end
		if type(actionId) ~= "string" then return end
		StoryService.handleQuestAction(services, player, actionId)
	end)

	print("[StoryService] Initialised — " .. MAX_LEVEL .. " levels loaded")
end

function StoryService.sendCurrentState(services, player: Player)
	local profile = services.ProfileService.getProfile(player)
	if not profile then return end
	local remote = services.RemoteService.getRemote(RemoteNames.StoryStateUpdated)
	remote:FireClient(player, buildPayload(profile))
end

return StoryService
