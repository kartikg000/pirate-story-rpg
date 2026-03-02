local Players = game:GetService("Players")

local function ensureDiagnosticLabel(text: string, color: Color3)
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
	if not playerGui then
		return
	end

	local gui = playerGui:FindFirstChild("BootstrapDiag")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "BootstrapDiag"
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
	end

	local label = gui:FindFirstChild("Status")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Status"
		label.Size = UDim2.new(0, 620, 0, 34)
		label.Position = UDim2.fromOffset(20, 176)
		label.BackgroundTransparency = 0.2
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = gui
	end

	label.BackgroundColor3 = color
	label.Text = text
end

local function startController(controllers: Instance, moduleName: string)
	local moduleScript = controllers:FindFirstChild(moduleName)
	if not moduleScript then
		ensureDiagnosticLabel("Missing module: " .. moduleName, Color3.fromRGB(140, 37, 37))
		warn("[Bootstrap] Missing module: " .. moduleName)
		return
	end

	local okRequire, moduleOrError = pcall(require, moduleScript)
	if not okRequire then
		ensureDiagnosticLabel("Require failed: " .. moduleName, Color3.fromRGB(140, 37, 37))
		warn("[Bootstrap] Require failed for " .. moduleName .. ": " .. tostring(moduleOrError))
		return
	end

	if type(moduleOrError) ~= "table" or type(moduleOrError.start) ~= "function" then
		ensureDiagnosticLabel("Invalid controller: " .. moduleName, Color3.fromRGB(140, 37, 37))
		warn("[Bootstrap] Invalid controller module: " .. moduleName)
		return
	end

	local okStart, startError = pcall(moduleOrError.start)
	if not okStart then
		ensureDiagnosticLabel("Start failed: " .. moduleName, Color3.fromRGB(140, 37, 37))
		warn("[Bootstrap] Start failed for " .. moduleName .. ": " .. tostring(startError))
		return
	end
end

local playerScripts = script.Parent
local controllers = playerScripts:WaitForChild("Controllers")

startController(controllers, "WeatherController")
startController(controllers, "HudController")
startController(controllers, "QuestDebugController")

ensureDiagnosticLabel("Bootstrap loaded (controllers started)", Color3.fromRGB(32, 110, 52))