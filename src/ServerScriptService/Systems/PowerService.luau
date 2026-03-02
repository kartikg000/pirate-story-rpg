-- PowerService.luau  (One Piece Edition)
-- Manages Devil Fruit abilities, Haki tiers, and Gear unlocks.
-- Abilities cost stamina (managed server-side). Client sends RequestUseAbility.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames       = require(ReplicatedStorage.Shared.Net.RemoteNames)

local PowerService = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- ABILITY DEFINITIONS
-- Cooldowns in seconds, staminaCost 0-100
-- ══════════════════════════════════════════════════════════════════════════════
local ABILITIES = {
	-- Basic — always available
	pistol = {
		id         = "pistol",
		name       = "Gum-Gum Pistol",
		desc       = "Stretching forward punch. Core attack.",
		key        = "Q",
		cooldown   = 1.5,
		staminaCost= 10,
		requirePower = nil,
		vfxTag     = "Pistol",
	},
	bazooka = {
		id         = "bazooka",
		name       = "Gum-Gum Bazooka",
		desc       = "Two-fisted double punch — wider AoE.",
		key        = "E",
		cooldown   = 3,
		staminaCost= 20,
		requirePower = nil,
		vfxTag     = "Bazooka",
	},
	gatling = {
		id         = "gatling",
		name       = "Gum-Gum Gatling",
		desc       = "Rapid-fire stretched fist barrage.",
		key        = "R",
		cooldown   = 6,
		staminaCost= 35,
		requirePower = nil,
		vfxTag     = "Gatling",
	},
	-- Gear Second
	gear2 = {
		id         = "gear2",
		name       = "Gear Second",
		desc       = "Pump blood faster — speed and power surge. 15s duration.",
		key        = "F",
		cooldown   = 30,
		staminaCost= 40,
		requirePower = "Gear_4_preview",  -- unlocked after 2yr training
		vfxTag     = "Gear2",
	},
	-- Gear Third
	gear3 = {
		id         = "gear3",
		name       = "Gear Third — Gigant Pistol",
		desc       = "Inflate bone marrow — giant fist smash.",
		key        = "G",
		cooldown   = 20,
		staminaCost= 50,
		requirePower = "Gear_4_preview",
		vfxTag     = "Gear3",
	},
	-- Gear Fourth Bounceman
	gear4 = {
		id         = "gear4",
		name       = "Gear Fourth — Bounce Man",
		desc       = "Armament Haki compressed rubber — extreme speed and power. 30s duration.",
		key        = "V",
		cooldown   = 60,
		staminaCost= 80,
		requirePower = "Gear_4_Bounceman",
		vfxTag     = "Gear4",
	},
	-- Conqueror's Haki burst
	conquerors = {
		id         = "conquerors",
		name       = "Conqueror's Haki Burst",
		desc       = "Overwhelming spirit — stun nearby weak enemies.",
		key        = "C",
		cooldown   = 45,
		staminaCost= 60,
		requirePower = "Conquerors_1",
		vfxTag     = "CoqHaki",
	},
	-- Gear Five
	gear5 = {
		id         = "gear5",
		name       = "Gear Five — Sun God Nika",
		desc       = "Full Mythical Zoan awakening — ultimate form. Reality becomes cartoon.",
		key        = "X",
		cooldown   = 120,
		staminaCost= 100,
		requirePower = "Gear_5",
		vfxTag     = "Gear5",
	},
}

-- Stamina regen per second
local STAMINA_REGEN = 8

-- ══════════════════════════════════════════════════════════════════════════════
-- PER-PLAYER STATE
-- stamina: 0-100, cooldowns: {abilityId: number (time remaining)}
-- ══════════════════════════════════════════════════════════════════════════════
local playerStamina  = {}  -- [userId] = number
local playerCooldown = {}  -- [userId][abilityId] = tick() when ability can be used next

-- ──────────────────────────────── HELPERS ─────────────────────────────────────
local function ensurePlayer(userId)
	if not playerStamina[userId] then
		playerStamina[userId] = 100
	end
	if not playerCooldown[userId] then
		playerCooldown[userId] = {}
	end
end

local function hasUnlock(profile, requirePower)
	if not requirePower then return true end
	return profile.storyFlags and profile.storyFlags["POWER_" .. requirePower] == true
end

local function canUseAbility(userId, abilityId)
	local cds = playerCooldown[userId]
	if not cds then return false end
	local readyAt = cds[abilityId] or 0
	return tick() >= readyAt
end

local function buildPowerPayload(userId)
	local stamina  = playerStamina[userId] or 100
	local cds      = playerCooldown[userId] or {}
	local cooldowns = {}
	local now = tick()
	for id, readyAt in cds do
		cooldowns[id] = math.max(0, readyAt - now)
	end
	return {
		stamina   = stamina,
		cooldowns = cooldowns,
	}
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PUBLIC
-- ══════════════════════════════════════════════════════════════════════════════
function PowerService.handleUseAbility(services, player, abilityId)
	local userId  = player.UserId
	local profile = services.ProfileService.getProfile(player)
	if not profile then return end
	ensurePlayer(userId)

	local ability = ABILITIES[abilityId]
	if not ability then return end

	-- Check unlock
	if not hasUnlock(profile, ability.requirePower) then
		return  -- ability not unlocked yet
	end

	-- Check cooldown
	if not canUseAbility(userId, abilityId) then
		return
	end

	-- Check stamina
	local stamina = playerStamina[userId]
	if stamina < ability.staminaCost then
		return
	end

	-- Consume
	playerStamina[userId] = stamina - ability.staminaCost
	playerCooldown[userId][abilityId] = tick() + ability.cooldown

	-- Broadcast updated power state to that player
	local powerRemote = services.RemoteService.getRemote(RemoteNames.PowerStateUpdated)
	if powerRemote then
		powerRemote:FireClient(player, buildPowerPayload(userId))
	end

	-- Send ability VFX tag back to ALL clients nearby (simplified broadcast)
	-- In a real game you'd use a proper AoE check; for now fire to all
	local Players = game:GetService("Players")
	for _, p in Players:GetPlayers() do
		local vfxRemote = services.RemoteService.getRemote(RemoteNames.AbilityVfx)
		if vfxRemote then
			vfxRemote:FireClient(p, {
				userId    = userId,
				abilityId = abilityId,
				vfxTag    = ability.vfxTag,
			})
		end
	end
end

function PowerService.init(services)
	local Players  = game:GetService("Players")

	-- Stamina regen loop
	task.spawn(function()
		while true do
			task.wait(1)
			for userId, stamina in playerStamina do
				local newVal = math.min(100, stamina + STAMINA_REGEN)
				playerStamina[userId] = newVal
			end
		end
	end)

	-- Listen for requests
	local abilityRemote = services.RemoteService.getRemote(RemoteNames.RequestUseAbility)
	if abilityRemote then
		abilityRemote.OnServerEvent:Connect(function(player, abilityId)
			if type(abilityId) ~= "string" then return end
			if not services.RemoteService.guard(player) then return end
			PowerService.handleUseAbility(services, player, abilityId)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		ensurePlayer(player.UserId)
	end)
	Players.PlayerRemoving:Connect(function(player)
		playerStamina[player.UserId]  = nil
		playerCooldown[player.UserId] = nil
	end)

	print("[PowerService] One Piece power system ready — " .. #(function()
		local t = {} for k in ABILITIES do t[#t+1]=k end return t
	end)() .. " abilities loaded")
end

-- Export ability list for client reference
PowerService.ABILITIES = ABILITIES

return PowerService
