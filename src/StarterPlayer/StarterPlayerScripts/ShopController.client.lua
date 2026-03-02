-- ShopController.client.lua
-- Cosmetic shop UI. Press [B] to open/close.
-- Glows the button when affordable, dims when not.
-- Fires RequestBuyCosmetic → server validates and deducts coins.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared", 10):WaitForChild("Net", 5):WaitForChild("RemoteNames", 5))

-- ── Coin state (updated by PlayerStateUpdated remote) ────────────────────────
local currentCoins = 0

-- ── Cosmetic catalogue ────────────────────────────────────────────────────────
local SHOP_ITEMS = {
	{id = "ocean_coat",     label = "Ocean Coat",     price = 150, icon = "⚓"},
	{id = "captain_hat",    label = "Captain's Hat",  price = 220, icon = "🎩"},
	{id = "storm_cloak",    label = "Storm Cloak",    price = 300, icon = "🌊"},
	{id = "sun_gold_trim",  label = "Sun Gold Trim",  price = 400, icon = "☀️"},
}

-- ── Build GUI ─────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name             = "ShopGui"
sg.ResetOnSpawn     = false
sg.DisplayOrder     = 20
sg.Enabled          = false   -- hidden until B pressed
sg.Parent           = playerGui

-- Backdrop (dark panel)
local backdrop = Instance.new("Frame")
backdrop.Name                 = "Backdrop"
backdrop.Size                 = UDim2.new(0, 360, 0, 440)
backdrop.Position             = UDim2.new(0.5, -180, 0.5, -220)
backdrop.BackgroundColor3     = Color3.fromRGB(12, 20, 34)
backdrop.BackgroundTransparency = 0.08
backdrop.BorderSizePixel      = 0
backdrop.Parent               = sg
local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 12)
bCorner.Parent = backdrop

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 60, 100)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = backdrop
local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 12)
tbCorner.Parent = titleBar
local titleLbl = Instance.new("TextLabel")
titleLbl.Size               = UDim2.new(1, -60, 1, 0)
titleLbl.Position           = UDim2.fromOffset(16, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.TextColor3         = Color3.fromRGB(255, 220, 80)
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextSize           = 20
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
titleLbl.Text               = "🏴‍☠️  Pirate Outfitter"
titleLbl.Parent             = titleBar

-- Coin balance display
local coinDisplay = Instance.new("TextLabel")
coinDisplay.Name                = "CoinDisplay"
coinDisplay.Size                = UDim2.new(1, -20, 0, 28)
coinDisplay.Position            = UDim2.new(0, 10, 0, 54)
coinDisplay.BackgroundTransparency = 1
coinDisplay.TextColor3          = Color3.fromRGB(255, 200, 60)
coinDisplay.Font                = Enum.Font.GothamMedium
coinDisplay.TextSize            = 16
coinDisplay.TextXAlignment      = Enum.TextXAlignment.Left
coinDisplay.Text                = "💰 Your Coins: —"
coinDisplay.Parent              = backdrop

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size               = UDim2.new(0, 36, 0, 36)
closeBtn.Position           = UDim2.new(1, -44, 0, 7)
closeBtn.BackgroundColor3   = Color3.fromRGB(180, 40, 40)
closeBtn.TextColor3         = Color3.fromRGB(255,255,255)
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.TextSize           = 18
closeBtn.Text               = "✕"
closeBtn.BorderSizePixel    = 0
closeBtn.Parent             = backdrop
local cBtnCorner = Instance.new("UICorner")
cBtnCorner.CornerRadius = UDim.new(0, 8)
cBtnCorner.Parent = closeBtn

-- Scrolling frame for items
local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, -20, 1, -100)
scroll.Position             = UDim2.new(0, 10, 0, 90)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 5
scroll.CanvasSize           = UDim2.new(0, 0, 0, #SHOP_ITEMS * 88)
scroll.Parent               = backdrop

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
listLayout.Padding      = UDim.new(0, 8)
listLayout.Parent       = scroll

-- ── Create item rows ──────────────────────────────────────────────────────────
local itemRows = {}   -- {id, buyBtn, priceLbl, card}

local function makeItemRow(item, index)
	local card = Instance.new("Frame")
	card.Name                 = item.id
	card.Size                 = UDim2.new(1, 0, 0, 78)
	card.BackgroundColor3     = Color3.fromRGB(20, 38, 60)
	card.BackgroundTransparency = 0.1
	card.BorderSizePixel      = 0
	card.LayoutOrder           = index
	card.Parent               = scroll
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	-- Icon
	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size               = UDim2.new(0, 60, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
	iconLbl.Font               = Enum.Font.GothamBold
	iconLbl.TextSize           = 30
	iconLbl.Text               = item.icon
	iconLbl.Parent             = card

	-- Item name
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size               = UDim2.new(0, 170, 0, 30)
	nameLbl.Position           = UDim2.fromOffset(64, 8)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3         = Color3.fromRGB(240, 240, 240)
	nameLbl.Font               = Enum.Font.GothamBold
	nameLbl.TextSize            = 16
	nameLbl.TextXAlignment      = Enum.TextXAlignment.Left
	nameLbl.Text               = item.label
	nameLbl.Parent             = card

	-- Price label
	local priceLbl = Instance.new("TextLabel")
	priceLbl.Name              = "PriceLbl"
	priceLbl.Size              = UDim2.new(0, 170, 0, 26)
	priceLbl.Position          = UDim2.fromOffset(64, 40)
	priceLbl.BackgroundTransparency = 1
	priceLbl.Font              = Enum.Font.GothamMedium
	priceLbl.TextSize           = 14
	priceLbl.TextXAlignment     = Enum.TextXAlignment.Left
	priceLbl.Text              = "💰 " .. item.price .. " coins"
	priceLbl.Parent            = card

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name               = "BuyBtn"
	buyBtn.Size               = UDim2.new(0, 80, 0, 36)
	buyBtn.Position           = UDim2.new(1, -90, 0.5, -18)
	buyBtn.BackgroundColor3   = Color3.fromRGB(40, 160, 80)
	buyBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
	buyBtn.Font               = Enum.Font.GothamBold
	buyBtn.TextSize           = 15
	buyBtn.Text               = "Buy"
	buyBtn.BorderSizePixel    = 0
	buyBtn.Parent             = card
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = buyBtn

	table.insert(itemRows, {id = item.id, price = item.price, buyBtn = buyBtn, priceLbl = priceLbl, card = card})
	return card
end

for i, item in SHOP_ITEMS do
	makeItemRow(item, i)
end

-- ── Open/close toggle ─────────────────────────────────────────────────────────
local shopOpen = false
local function setShopOpen(open)
	shopOpen = open
	sg.Enabled = open
	if open then
		backdrop.BackgroundTransparency = 0.08
		TweenService:Create(backdrop, TweenInfo.new(0.15), {BackgroundTransparency = 0.08}):Play()
	end
end

closeBtn.MouseButton1Click:Connect(function() setShopOpen(false) end)

-- ── Hotkey B ──────────────────────────────────────────────────────────────────
-- Also add a small HUD toggle button
local shopHotkey = Instance.new("ScreenGui")
shopHotkey.Name            = "ShopHotkeyHint"
shopHotkey.ResetOnSpawn    = false
shopHotkey.DisplayOrder    = 9
shopHotkey.Parent          = playerGui
local hotkeyBtn = Instance.new("TextButton")
hotkeyBtn.Size             = UDim2.new(0, 120, 0, 36)
hotkeyBtn.Position         = UDim2.new(1, -138, 1, -60)
hotkeyBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 100)
hotkeyBtn.BackgroundTransparency = 0.2
hotkeyBtn.TextColor3       = Color3.fromRGB(255, 220, 80)
hotkeyBtn.Font             = Enum.Font.GothamBold
hotkeyBtn.TextSize         = 14
hotkeyBtn.Text             = "🛒 Shop [B]"
hotkeyBtn.BorderSizePixel  = 0
hotkeyBtn.Parent           = shopHotkey
local hkCorner = Instance.new("UICorner")
hkCorner.CornerRadius = UDim.new(0, 8)
hkCorner.Parent = hotkeyBtn
hotkeyBtn.MouseButton1Click:Connect(function() setShopOpen(not shopOpen) end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B then
		setShopOpen(not shopOpen)
	end
end)

-- ── Update affordability display ──────────────────────────────────────────────
local function refreshAffordability()
	coinDisplay.Text = "💰 Your Coins: " .. currentCoins
	for _, row in itemRows do
		local canAfford = currentCoins >= row.price
		row.buyBtn.BackgroundColor3 = canAfford
			and Color3.fromRGB(40, 160, 80)
			or  Color3.fromRGB(90, 90, 90)
		row.buyBtn.Text   = canAfford and "Buy" or "💸"
		row.priceLbl.TextColor3 = canAfford
			and Color3.fromRGB(120, 220, 120)
			or  Color3.fromRGB(180, 80, 80)
	end
end

-- ── Wire remotes ──────────────────────────────────────────────────────────────
task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("GameRemotes", 15)
	if not remotes then return end

	-- Track coins from PlayerStateUpdated
	local playerStateRemote = remotes:WaitForChild(RemoteNames.PlayerStateUpdated, 10)
	if playerStateRemote then
		playerStateRemote.OnClientEvent:Connect(function(data)
			if data and data.coins then
				currentCoins = data.coins
				refreshAffordability()
			end
		end)
	end

	-- Buy button clicks
	local buyRemote = remotes:WaitForChild(RemoteNames.RequestBuyCosmetic, 10)
	if not buyRemote then return end

	for _, row in itemRows do
		local rid = row.id
		local btn = row.buyBtn
		btn.MouseButton1Click:Connect(function()
			if currentCoins < row.price then return end
			btn.Text             = "..."
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			buyRemote:FireServer(rid)
			-- re-enable after short delay (server will send updated coins)
			task.delay(1.5, function()
				refreshAffordability()
			end)
		end)
	end
end)

refreshAffordability()
