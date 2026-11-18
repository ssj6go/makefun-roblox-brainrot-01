-- Brainrot Bay: the leaderboard. Pure in-memory ranking by cash, rebuilt
-- from GameState on every broadcast, so it never disagrees with the
-- money the server actually holds.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local Leaderboard = {}

function Leaderboard.GetTopPlayers()
	local rows = {}
	for player, data in pairs(GameState.GetAllPlayerData()) do
		table.insert(rows, {
			Name = player.Name,
			Cash = data.Cash,
			Rebirths = data.Rebirths,
			IncomePerSecond = GameState.GetIncomePerSecond(player),
		})
	end
	table.sort(rows, function(a, b)
		return a.Cash > b.Cash
	end)
	while #rows > Config.LeaderboardSize do
		table.remove(rows)
	end
	return rows
end

return Leaderboard
