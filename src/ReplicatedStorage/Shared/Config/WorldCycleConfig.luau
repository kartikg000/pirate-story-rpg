local WorldCycleConfig = {
	Seasons = {
		"Summer",
		"Spring",
		"Monsoon",
		"Winter",
	},
	SeasonDurationSeconds = 8 * 60,
	MoonPhases = {
		"NewMoon",
		"WaxingCrescent",
		"FirstQuarter",
		"WaxingGibbous",
		"FullMoon",
		"WaningGibbous",
		"LastQuarter",
		"WaningCrescent",
	},
	MoonPhaseDurationSeconds = 150,
	RareEvents = {
		Tsunami = {
			cooldownSeconds = 240,
			chancePerWeatherCheck = 0.08,
			durationSeconds = 35,
		},
		SuperStorm = {
			cooldownSeconds = 180,
			chancePerWeatherCheck = 0.12,
			durationSeconds = 50,
		},
	},
}

return WorldCycleConfig
