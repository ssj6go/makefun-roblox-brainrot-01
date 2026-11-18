-- Brainrot Bay: server bootstrap. Builds the world, starts every system,
-- and wires player join/leave: base assignment, leaderstats, save
-- loading and saving. Systems start in dependency order so no module
-- ever requires a half-built neighbour.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local TsunamiEvent = require(script.Parent:WaitForChild("TsunamiEvent"))
local RebirthSystem = require(script.Parent:WaitForChild("RebirthSystem"))
local PlayerDataStore = require(script.Parent:WaitForChild("PlayerDataStore"))
local Notify = require(script.Parent:WaitForChild("Notify"))

local function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Cash"
	cashValue.Value = Config.StartingCash
	cashValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	return leaderstats
end

local function syncLeaderstats(player)
	local data = GameState.GetPlayerData(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if data == nil or leaderstats == nil then
		return
	end
	local cashValue = leaderstats:FindFirstChild("Cash")
	if cashValue ~= nil then
		cashValue.Value = math.floor(data.Cash)
	end
	local rebirthValue = leaderstats:FindFirstChild("Rebirths")
	if rebirthValue ~= nil then
		rebirthValue.Value = data.Rebirths
	end
end

local function onPlayerAdded(player)
	GameState.CreatePlayerData(player)
	local baseIndex = GameState.AssignBase(player)
	createLeaderstats(player)
	if baseIndex ~= nil then
		WorldBuilder.SetBaseSignOwner(baseIndex, player.Name)
	end
	PlayerDataStore.LoadPlayerData(player)
	syncLeaderstats(player)
	Notify.Player(player, "Welcome to Brainrot Bay! Buy a brainrot at the conveyor, then run it home!", "info")
end

local function onPlayerRemoving(player)
	local data = GameState.GetPlayerData(player)
	if data ~= nil and data.Carrying ~= nil then
		data.Carrying:Destroy()
	end
	PlayerDataStore.SavePlayerData(player)
	if data ~= nil and data.BaseIndex ~= nil then
		WorldBuilder.ClearBaseSign(data.BaseIndex)
	end
	GameState.RemovePlayerData(player)
end

-- World first, then the systems that fill it.
WorldBuilder.BuildWorld()
StealSystem.StartStealSystem()
Economy.StartEconomy()
BrainrotSpawner.StartSpawner()
TsunamiEvent.StartTsunami()
RebirthSystem.StartRebirthSystem()
PlayerDataStore.StartPlayerDataStore()

-- The client asks for one full snapshot on join instead of waiting for
-- the next broadcast tick.
local getStateFunction = ReplicatedStorage:WaitForChild("GetStateFunction")
getStateFunction.OnServerInvoke = function(player)
	return Economy.GetStateSnapshot(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Keep the built-in player-list leaderboard in step with the real money.
task.spawn(function()
	while true do
		task.wait(Config.StateBroadcastSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			syncLeaderstats(player)
		end
	end
end)

print("Brainrot Bay server ready: conveyor, bases, tsunami and rebirths live.")
