local playerScripts = script.Parent
local controllers = playerScripts.Controllers

require(controllers.WeatherController).start()
