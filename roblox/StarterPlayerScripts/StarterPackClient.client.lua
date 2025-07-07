--[[
	StarterPackClient.client.lua
	Client-side handler for the Starter Pack 80 R$ game pass. Responsible for showing the
	first-session popup, prompting the purchase, and hiding itself after purchase
	or the player opts to close it.
--]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- TODO: Replace with your actual GamePass ID
local STARTER_PACK_PASS_ID = 12345678

-- Time (in seconds) after which the popup reappears if the player clicked "Maybe later"
local REMINDER_COOLDOWN = 15 * 60 -- 15 minutes

local player = Players.LocalPlayer

---------------------------------------------------------------------
-- Utility: check ownership (safe pcall wrapper)
---------------------------------------------------------------------
local function ownsStarterPack()
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, STARTER_PACK_PASS_ID)
	end)
	return success and result
end

---------------------------------------------------------------------
-- GUI Construction (purely runtime – no pre-built objects required)
---------------------------------------------------------------------
local function createPopupGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StarterPackPopup"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false -- start hidden
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.new(0, 400, 0, 260)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- UICorner for rounded edges
	local corner = Instance.new("UICorner")
	corner.Parent = frame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "Starter Pack"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 32
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Parent = frame

	-- Value Text
	local valueText = Instance.new("TextLabel")
	valueText.Name = "ValueText"
	valueText.Text = "230 R$ value → 80 R$"
	valueText.Font = Enum.Font.GothamMedium
	valueText.TextSize = 18
	valueText.TextColor3 = Color3.fromRGB(200, 200, 200)
	valueText.BackgroundTransparency = 1
	valueText.Position = UDim2.new(0, 0, 0, 50)
	valueText.Size = UDim2.new(1, 0, 0, 30)
	valueText.Parent = frame

	-- (Optional) Thumbnail placeholder
	local thumb = Instance.new("ImageLabel")
	thumb.Name = "Thumbnail"
	thumb.BackgroundTransparency = 1
	thumb.Size = UDim2.new(0, 200, 0, 90)
	thumb.Position = UDim2.new(0.5, -100, 0, 90)
	thumb.Image = "rbxassetid://0" -- replace with your composed ship thumbnail assetId
	thumb.Parent = frame

	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyButton"
	buyBtn.Text = "Buy for 80 R$"
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextSize = 24
	buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	buyBtn.Size = UDim2.new(0, 180, 0, 50)
	buyBtn.Position = UDim2.new(0.5, -190, 1, -60)
	buyBtn.Parent = frame

	local buyCorner = Instance.new("UICorner")
	buyCorner.Parent = buyBtn

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Text = "Maybe Later"
	closeBtn.Font = Enum.Font.Gotham
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	closeBtn.Size = UDim2.new(0, 150, 0, 40)
	closeBtn.Position = UDim2.new(1, -160, 1, -50)
	closeBtn.Parent = frame

	local closeCorner = Instance.new("UICorner")
	closeCorner.Parent = closeBtn

	return screenGui, buyBtn, closeBtn
end

local popupGui, buyButton, closeButton = createPopupGui()

---------------------------------------------------------------------
-- Popup control logic
---------------------------------------------------------------------
local popupVisible = false
local optedOutSession = false

local function hidePopup()
	popupGui.Enabled = false
	popupVisible = false
end

local function showPopup()
	if popupVisible then return end
	if ownsStarterPack() then return end
	popupGui.Enabled = true
	popupVisible = true
end

-- Initial show attempt after character loads
player.CharacterAdded:Wait()
showPopup()

---------------------------------------------------------------------
-- Button callbacks
---------------------------------------------------------------------

buyButton.MouseButton1Click:Connect(function()
	MarketplaceService:PromptGamePassPurchase(player, STARTER_PACK_PASS_ID)
end)

closeButton.MouseButton1Click:Connect(function()
	optedOutSession = true
	hidePopup()

	-- Reshow after cooldown
	task.delay(REMINDER_COOLDOWN, function()
		if not optedOutSession and not ownsStarterPack() then
			showPopup()
		end
	end)
end)

---------------------------------------------------------------------
-- Hide GUI automatically once the purchase completes
---------------------------------------------------------------------
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(gamePassId, wasPurchased)
	if gamePassId == STARTER_PACK_PASS_ID and wasPurchased then
		hidePopup()
	end
end)