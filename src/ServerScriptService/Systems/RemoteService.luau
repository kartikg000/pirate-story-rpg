local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Net.RemoteNames)

local RemoteService = {}

local remotesFolder: Folder
local callWindowByPlayer: {[number]: {count: number, secondStamp: number}} = {}

local function ensureRemote(name: string): RemoteEvent
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotesFolder
	return event
end

local function isRateLimited(player: Player): boolean
	local now = os.time()
	local state = callWindowByPlayer[player.UserId]
	if not state or state.secondStamp ~= now then
		callWindowByPlayer[player.UserId] = {count = 1, secondStamp = now}
		return false
	end

	state.count += 1
	return state.count > GameConfig.RemoteRateLimitPerSecond
end

function RemoteService.init()
	local existingFolder = ReplicatedStorage:FindFirstChild("GameRemotes")
	if existingFolder and existingFolder:IsA("Folder") then
		remotesFolder = existingFolder
	else
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "GameRemotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for _, remoteName in RemoteNames do
		ensureRemote(remoteName)
	end

	Players.PlayerRemoving:Connect(function(player)
		callWindowByPlayer[player.UserId] = nil
	end)
end

function RemoteService.getRemote(name: string): RemoteEvent
	return ensureRemote(name)
end

function RemoteService.guard(player: Player): boolean
	return not isRateLimited(player)
end

return RemoteService
