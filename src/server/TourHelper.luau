-- Brainrot Bay: tour helper for make.fun's reviewers. TOUR.json names
-- these functions so a reviewer in Studio can jump to each screenshot's
-- screen: the conveyor, a player's base, and a live tsunami. Every
-- function tolerates being called with a player or with no player at
-- all, and always acts on whoever is in the game.

local Players = game:GetService("Players")

local TsunamiEvent = require(script.Parent:WaitForChild("TsunamiEvent"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local TourHelper = {}

local function resolvePlayers(firstArg)
	if typeof(firstArg) == "Instance" and firstArg:IsA("Player") then
		return { firstArg }
	end
	return Players:GetPlayers()
end

local function teleportPlayers(targets, position)
	for _, player in ipairs(targets) do
		local character = player.Character
		local root = character ~= nil and character:FindFirstChild("HumanoidRootPart") or nil
		if root ~= nil then
			root.CFrame = CFrame.new(position)
		end
	end
end

function TourHelper.GotoConveyor(firstArg)
	teleportPlayers(resolvePlayers(firstArg), Vector3.new(-20, 3, 12))
	return true
end

function TourHelper.GotoBase(firstArg)
	local targets = resolvePlayers(firstArg)
	for _, player in ipairs(targets) do
		local data = GameState.GetPlayerData(player)
		local center = GameState.GetBaseCenter((data ~= nil and data.BaseIndex) or 1)
		teleportPlayers({ player }, Vector3.new(center.X, 3, center.Z + 8))
	end
	return true
end

function TourHelper.StartWave(_firstArg)
	return TsunamiEvent.ForceWave()
end

return TourHelper
