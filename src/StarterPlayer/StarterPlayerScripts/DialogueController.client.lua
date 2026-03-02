-- DialogueController.client.lua
-- Shows NPC dialogue boxes when ShowDialogue remote fires.
-- Dialogue advances on click or Enter, auto-closes after last line.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared",10):WaitForChild("Net",5):WaitForChild("RemoteNames",5))

-- ── Build dialogue GUI ────────────────────────────────────────────────────────
local sg            = Instance.new("ScreenGui")
sg.Name             = "DialogueGui"
sg.ResetOnSpawn     = false
sg.DisplayOrder     = 50
sg.Enabled          = false
sg.Parent           = playerGui

-- Dark cinematic panel anchored at bottom-centre (above letterbox)
local panel         = Instance.new("Frame")
panel.Name          = "DialoguePanel"
panel.Size          = UDim2.new(0.72, 0, 0, 130)
panel.Position      = UDim2.new(0.14, 0, 0.68, 0)
panel.BackgroundColor3 = Color3.fromRGB(8, 14, 24)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent        = sg
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 10)
pCorner.Parent = panel

-- Gold left accent bar
local accent        = Instance.new("Frame")
accent.Size         = UDim2.new(0, 4, 1, -16)
accent.Position     = UDim2.fromOffset(10, 8)
accent.BackgroundColor3 = Color3.fromRGB(255, 215, 60)
accent.BorderSizePixel  = 0
accent.Parent       = panel
local accCorner = Instance.new("UICorner")
accCorner.CornerRadius = UDim.new(0, 2)
accCorner.Parent = accent

-- Speaker name
local speakerLbl    = Instance.new("TextLabel")
speakerLbl.Name     = "Speaker"
speakerLbl.Size     = UDim2.new(1, -80, 0, 26)
speakerLbl.Position = UDim2.fromOffset(22, 8)
speakerLbl.BackgroundTransparency = 1
speakerLbl.TextColor3 = Color3.fromRGB(255, 215, 60)
speakerLbl.Font     = Enum.Font.GothamBold
speakerLbl.TextSize = 16
speakerLbl.TextXAlignment = Enum.TextXAlignment.Left
speakerLbl.Text     = "Sam"
speakerLbl.Parent   = panel

-- Dialogue text (wrapping)
local dialogueLbl   = Instance.new("TextLabel")
dialogueLbl.Name    = "DialogueText"
dialogueLbl.Size    = UDim2.new(1, -40, 0, 72)
dialogueLbl.Position = UDim2.fromOffset(22, 36)
dialogueLbl.BackgroundTransparency = 1
dialogueLbl.TextColor3 = Color3.fromRGB(225, 230, 240)
dialogueLbl.Font    = Enum.Font.GothamMedium
dialogueLbl.TextSize = 16
dialogueLbl.TextWrapped = true
dialogueLbl.TextXAlignment = Enum.TextXAlignment.Left
dialogueLbl.TextYAlignment = Enum.TextYAlignment.Top
dialogueLbl.Text    = ""
dialogueLbl.Parent  = panel

-- "Next / [E]" hint
local nextHint      = Instance.new("TextLabel")
nextHint.Size       = UDim2.new(0, 70, 0, 22)
nextHint.Position   = UDim2.new(1, -78, 1, -28)
nextHint.BackgroundTransparency = 1
nextHint.TextColor3 = Color3.fromRGB(140, 150, 170)
nextHint.Font       = Enum.Font.GothamMedium
nextHint.TextSize   = 13
nextHint.Text       = "[E] Next"
nextHint.Parent     = panel

-- ── Typewriter effect ─────────────────────────────────────────────────────────
local typeThread = nil
local function typeWrite(text, onDone)
	if typeThread then task.cancel(typeThread) end
	dialogueLbl.Text = ""
	typeThread = task.spawn(function()
		local i = 0
		while i < #text do
			i = i + 1
			dialogueLbl.Text = string.sub(text, 1, i)
			task.wait(0.025)
		end
		typeThread = nil
		if onDone then onDone() end
	end)
end

-- ── Dialogue queue system ─────────────────────────────────────────────────────
local isShowing   = false
local lineQueue   = {}
local currentLine = 0
local currentSpeaker = ""

local function closeDialogue()
	if typeThread then task.cancel(typeThread); typeThread = nil end
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}):Play()
	task.delay(0.3, function()
		sg.Enabled = false
		panel.BackgroundTransparency = 0.08
		isShowing = false
	end)
end

local function showNextLine()
	currentLine = currentLine + 1
	if currentLine > #lineQueue then
		closeDialogue()
		return
	end
	speakerLbl.Text = currentSpeaker
	nextHint.Text   = currentLine < #lineQueue and "[E] Next" or "[E] Close"
	typeWrite(lineQueue[currentLine])
end

local function openDialogue(speaker, lines)
	if isShowing then return end
	isShowing     = true
	lineQueue     = lines
	currentLine   = 0
	currentSpeaker = speaker

	sg.Enabled = true
	panel.BackgroundTransparency = 1
	TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.08}):Play()

	task.delay(0.1, showNextLine)
end

-- Advance on E / F / Space / click
-- NOTE: gp (gameProcessed) can be true when a ProximityPrompt just consumed E,
-- so we intentionally bypass the guard whenever dialogue is actively showing.
UserInputService.InputBegan:Connect(function(input, gp)
	-- When dialogue is open, intercept E/F/Space regardless of gameProcessed
	if not isShowing then
		if gp then return end
	end
	if not isShowing then return end

	local isAdvanceKey = input.KeyCode == Enum.KeyCode.E
		or input.KeyCode == Enum.KeyCode.F
		or input.KeyCode == Enum.KeyCode.Space
		or input.UserInputType == Enum.UserInputType.MouseButton1

	if not isAdvanceKey then return end

	if typeThread then
		-- First press: skip typewriter, show full line immediately
		task.cancel(typeThread)
		typeThread = nil
		dialogueLbl.Text = lineQueue[currentLine] or ""
	else
		-- Second press: advance to next line (or close)
		showNextLine()
	end
end)

-- ── Wire ShowDialogue remote ──────────────────────────────────────────────────
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 15)
	if not remotes then return end
	local showDialogueRemote = remotes:WaitForChild(RemoteNames.ShowDialogue, 10)
	if not showDialogueRemote then return end

	showDialogueRemote.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then return end
		local speaker = type(data.speaker) == "string" and data.speaker or "???"
		local lines   = type(data.lines)   == "table"  and data.lines   or {"..."}
		openDialogue(speaker, lines)
	end)
end)
