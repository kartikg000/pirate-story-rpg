local WorldStateService = {}

local state = {
	season = "Summer",
	moonPhase = "NewMoon",
	activeEvents = {},
}

function WorldStateService.setSeason(seasonName: string)
	state.season = seasonName
end

function WorldStateService.setMoonPhase(phaseName: string)
	state.moonPhase = phaseName
end

function WorldStateService.setEventActive(eventName: string, isActive: boolean)
	if isActive then
		state.activeEvents[eventName] = true
	else
		state.activeEvents[eventName] = nil
	end
end

function WorldStateService.snapshot()
	local events = {}
	for eventName, _ in state.activeEvents do
		events[#events + 1] = eventName
	end

	return {
		season = state.season,
		moonPhase = state.moonPhase,
		activeEvents = events,
	}
end

return WorldStateService
