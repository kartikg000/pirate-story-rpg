local RemoteNames = {
	RequestBuyCosmetic   = "RequestBuyCosmetic",
	RequestEquipCosmetic = "RequestEquipCosmetic",
	RequestQuestAction   = "RequestQuestAction",
	WeatherStateUpdated  = "WeatherStateUpdated",
	PlayerStateUpdated   = "PlayerStateUpdated",
	StoryStateUpdated    = "StoryStateUpdated",
	ShowDialogue         = "ShowDialogue",
	LevelComplete        = "LevelComplete",
	-- Power system (One Piece)
	RequestUseAbility    = "RequestUseAbility",
	PowerStateUpdated    = "PowerStateUpdated",
	AbilityVfx           = "AbilityVfx",
	-- Ship system
	ShipControl          = "ShipControl",   -- client → server {throttle, steer}
	ShipBoarded          = "ShipBoarded",   -- server → client
	ShipLeft             = "ShipLeft",      -- server → client
}

return RemoteNames
