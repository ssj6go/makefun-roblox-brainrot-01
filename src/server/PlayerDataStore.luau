-- Brainrot Bay: persistence. Cash, rebirths and placed brainrots save to
-- a DataStore on leave and every minute, and load back on join. Every
-- DataStore call is wrapped in pcall: in Studio playtests without API
-- access the game simply starts fresh instead of breaking.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Notify = require(script.Parent:WaitForChild("Notify"))

local PlayerDataStore = {}

local store = nil

local function getStore()
	if store == nil then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(Config.DataStoreName)
		end)
		if ok then
			store = result
		end
	end
	return store
end

local function dataKey(player)
	return "player_" .. player.UserId
end

function PlayerDataStore.SavePlayerData(player)
	local dataStore = getStore()
	if dataStore == nil then
		return false
	end
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	local placed = {}
	for _, record in ipairs(data.Placed) do
		table.insert(placed, { BrainrotId = record.BrainrotId, Mutation = record.Mutation })
	end
	local payload = {
		Cash = data.Cash,
		Rebirths = data.Rebirths,
		TotalEarned = data.TotalEarned,
		Placed = placed,
	}
	local ok, err = pcall(function()
		dataStore:SetAsync(dataKey(player), payload)
	end)
	if not ok then
		warn("Brainrot Bay: failed to save " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

function PlayerDataStore.LoadPlayerData(player)
	local dataStore = getStore()
	if dataStore == nil then
		return false
	end
	local ok, saved = pcall(function()
		return dataStore:GetAsync(dataKey(player))
	end)
	if not ok or type(saved) ~= "table" then
		return false
	end
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	if type(saved.Cash) == "number" then
		data.Cash = math.max(0, saved.Cash)
	end
	if type(saved.Rebirths) == "number" then
		data.Rebirths = math.max(0, math.floor(saved.Rebirths))
	end
	if type(saved.TotalEarned) == "number" then
		data.TotalEarned = math.max(0, saved.TotalEarned)
	end
	if type(saved.Placed) == "table" then
		for _, record in ipairs(saved.Placed) do
			if type(record) == "table" and Catalog.GetEntry(record.BrainrotId) ~= nil then
				Economy.PlaceLoadedBrainrot(player, record.BrainrotId, record.Mutation or "Normal")
			end
		end
	end
	if data.Rebirths > 0 or #data.Placed > 0 then
		Notify.Player(player, "Welcome back! Your base was restored.", "good")
	end
	return true
end

function PlayerDataStore.StartPlayerDataStore()
	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveSeconds)
			for _, player in ipairs(Players:GetPlayers()) do
				PlayerDataStore.SavePlayerData(player)
			end
		end
	end)
end

return PlayerDataStore
