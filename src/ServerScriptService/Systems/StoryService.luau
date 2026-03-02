local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local StoryService = {}

local LEVEL_1_STEPS = {
	"steal_chicken",
	"meet_friends",
	"board_ship",
}

local OBJECTIVE_TEXT = {
	steal_chicken = "Steal the roast chicken and run!",
	meet_friends = "Meet your crew in the sunny field.",
	board_ship = "Reach the harbor and board the old pirate ship.",
}

local function getCurrentStep(profile)
	for _, stepId in LEVEL_1_STEPS do
		if not profile.storyFlags[stepId] then
			return stepId
		end
	end
	return nil
end

local function buildStoryPayload(profile)
	local stepId = getCurrentStep(profile)
	if not stepId then
		return {
			chapter = "Level 1 Complete",
			objective = "Sail into the open sea.",
			level = profile.storyLevel,
		}
	end

	return {
		chapter = "Level 1: Chicken Dash",
		objective = OBJECTIVE_TEXT[stepId],
		level = profile.storyLevel,
	}
end

function StoryService.init(services)
	local remoteService = services.RemoteService
	local profileService = services.ProfileService
	local storyStateRemote = remoteService.getRemote(RemoteNames.StoryStateUpdated)
	local questActionRemote = remoteService.getRemote(RemoteNames.RequestQuestAction)

	questActionRemote.OnServerEvent:Connect(function(player, actionId)
		if not remoteService.guard(player) then
			return
		end
		if type(actionId) ~= "string" then
			return
		end

		local profile = profileService.getProfile(player)
		if not profile then
			return
		end

		local expectedStep = getCurrentStep(profile)
		if not expectedStep then
			return
		end
		if actionId ~= expectedStep then
			return
		end

		profile.storyFlags[actionId] = true
		if actionId == "board_ship" then
			profile.storyLevel = math.max(profile.storyLevel, 2)
			profileService.incrementCoins(player, 100)
		end

		storyStateRemote:FireClient(player, buildStoryPayload(profile))
	end)
end

function StoryService.sendCurrentState(services, player: Player)
	local profile = services.ProfileService.getProfile(player)
	if not profile then
		return
	end

	local storyStateRemote = services.RemoteService.getRemote(RemoteNames.StoryStateUpdated)
	storyStateRemote:FireClient(player, buildStoryPayload(profile))
end

return StoryService
