local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- TODO: Replace with your actual GamePass ID from the Creator Dashboard
local STARTER_PACK_PASS_ID = 12345678

-- Path in ServerStorage that contains the two ship models to grant
local SHIPS_FOLDER = game:GetService("ServerStorage"):WaitForChild("StarterPackShips", 10)
if not SHIPS_FOLDER then
	warn("[StarterPackHandler] Could not find the StarterPackShips folder in ServerStorage. Ships will not be granted.")
	return
end

---------------------------------------------------------------------
-- Utility: give both ships to the provided player (idempotent)
---------------------------------------------------------------------
local function giveStarterShips(player)
	if not player or not player:IsDescendantOf(game) then
		return
	end

	-- Avoid duplicates by checking for an existing fleet folder
	if player:FindFirstChild("StarterFleet") then
		return
	end

	local fleetFolder = Instance.new("Folder")
	fleetFolder.Name = "StarterFleet"
	fleetFolder.Parent = player

	for _, ship in ipairs(SHIPS_FOLDER:GetChildren()) do
		local clone = ship:Clone()
		clone.Parent = fleetFolder
	end
end

---------------------------------------------------------------------
-- Grant ships on join if the player already owns the game pass
---------------------------------------------------------------------
local function onPlayerAdded(player)
	task.defer(function() -- run asynchronously so join isn\'t blocked
		local success, ownsPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, STARTER_PACK_PASS_ID)
		end)
		if success and ownsPass then
			giveStarterShips(player)
		end
	end)
end
Players.PlayerAdded:Connect(onPlayerAdded)

---------------------------------------------------------------------
-- Grant ships immediately after a successful purchase in-game
---------------------------------------------------------------------
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if wasPurchased and gamePassId == STARTER_PACK_PASS_ID then
		giveStarterShips(player)
	end
end)