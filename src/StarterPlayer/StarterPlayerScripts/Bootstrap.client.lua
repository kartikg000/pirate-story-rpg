local playerScripts = script.Parent
local controllers = playerScripts.Controllers

require(controllers.WeatherController).start()
require(controllers.HudController).start()
require(controllers.QuestDebugController).start()