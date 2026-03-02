export type ProfileData = {
	coins: number,
	hunger: number,
	unlockedCosmetics: {[string]: boolean},
	equippedCosmetic: string,
	storyLevel: number,
	storyFlags: {[string]: boolean},
	lastLoginUnix: number,
}

export type WeatherState = {
	name: string,
	durationSeconds: number,
	clockTime: number,
	fogEnd: number,
	brightness: number,
	atmosphereDensity: number,
	atmosphereHaze: number,
	atmosphereGlare: number,
	colorTint: Color3,
}

return {}
