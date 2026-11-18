-- Brainrot Bay: rebirth. Spend a growing pile of cash to reset to the
-- starting money with an empty base, and earn a permanent +50% income
-- multiplier for every rebirth. The long game for players who have
-- filled their base with the best cast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FormatUtil"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Notify = require(script.Parent:WaitForChild("Notify"))

local RebirthSystem = {}

local rebirthEvent = nil

function RebirthSystem.TryRebirth(player)
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	local cost = GameState.GetRebirthCost(data.Rebirths)
	if data.Cash < cost then
		Notify.Player(
			player,
			"Rebirth costs " .. FormatUtil.FormatMoney(cost) .. ". Keep earning!",
			"warn"
		)
		return false
	end
	if data.Carrying ~= nil then
		Notify.Player(player, "Place what you are carrying before you rebirth.", "warn")
		return false
	end

	-- The old cast is donated to the meme museum: their models go away.
	for _, record in ipairs(data.Placed) do
		if record.Model ~= nil then
			record.Model:Destroy()
		end
	end
	data.Placed = {}
	data.Cash = Config.StartingCash
	data.Rebirths += 1

	local multiplier = GameState.GetRebirthMultiplier(data.Rebirths)
	Notify.Player(
		player,
		"REBIRTH #" .. data.Rebirths .. "! Income is now x" .. string.format("%.1f", multiplier) .. " forever!",
		"rebirth"
	)
	Notify.All(player.Name .. " rebirthed! Their income is now x" .. string.format("%.1f", multiplier) .. ".", "info")
	return true
end

function RebirthSystem.StartRebirthSystem()
	rebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent")
	rebirthEvent.OnServerEvent:Connect(function(player)
		RebirthSystem.TryRebirth(player)
	end)
end

return RebirthSystem
