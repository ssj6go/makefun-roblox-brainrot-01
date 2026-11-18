-- Brainrot Bay: the server's single source of truth for player state.
-- Cash, inventory, rebirths, bases and cooldowns live here and nowhere
-- else; the client only ever sees snapshots the server sends it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local GameState = {}

-- [Player] = data table. A data table holds:
--   Cash, Rebirths, TotalEarned, Placed (list of placed records),
--   Carrying (model or nil), CarryingInfo (entry id + mutation or nil),
--   StolenFrom (victim player or nil), LastStealAt, BaseShieldUntil,
--   BaseLockUntil, BaseLockReadyAt, BaseIndex, HasBought, HasPlaced.
local playerData = {}

-- [baseIndex] = Player that owns it.
local baseOwners = {}

-- The tsunami's current phase, written by TsunamiEvent and read by the
-- economy's state snapshots: { Phase = "calm" | "warning" | "sweep",
-- SecondsLeft = number }.
local waveState = { Phase = "calm", SecondsLeft = 0 }

function GameState.SetWaveState(phase, secondsLeft)
	waveState.Phase = phase
	waveState.SecondsLeft = secondsLeft
end

function GameState.GetWaveState()
	return { Phase = waveState.Phase, SecondsLeft = waveState.SecondsLeft }
end

local function baseAngleRadians(baseIndex)
	-- Six plots at 30, 90, 150, 210, 270 and 330 degrees: none of them
	-- sits on the conveyor line that runs east-west through the middle.
	local degrees = 30 + (baseIndex - 1) * 60
	return math.rad(degrees)
end

function GameState.GetBaseCenter(baseIndex)
	local angle = baseAngleRadians(baseIndex)
	return Vector3.new(
		math.cos(angle) * Config.BaseRadius,
		0,
		math.sin(angle) * Config.BaseRadius
	)
end

function GameState.GetBaseCenterTable(baseIndex)
	local center = GameState.GetBaseCenter(baseIndex)
	return { x = center.X, z = center.Z }
end

function GameState.IsInsideBase(position, baseIndex)
	local center = GameState.GetBaseCenter(baseIndex)
	local half = Config.BaseSize / 2
	return math.abs(position.X - center.X) <= half and math.abs(position.Z - center.Z) <= half
end

function GameState.GetSlotPosition(baseIndex, slotIndex)
	-- Six slots in two rows of three inside the base.
	local center = GameState.GetBaseCenter(baseIndex)
	local column = (slotIndex - 1) % 3 -- 0, 1, 2
	local row = math.floor((slotIndex - 1) / 3) -- 0, 1
	return Vector3.new(center.X + (column - 1) * 7, 1.5, center.Z + (row - 0.5) * 8)
end

function GameState.CreatePlayerData(player)
	local data = {
		Cash = Config.StartingCash,
		Rebirths = 0,
		TotalEarned = 0,
		Placed = {},
		Carrying = nil,
		CarryingInfo = nil,
		StolenFrom = nil,
		LastStealAt = -math.huge,
		BaseShieldUntil = 0,
		BaseLockUntil = 0,
		BaseLockReadyAt = 0,
		BaseIndex = nil,
		HasBought = false,
		HasPlaced = false,
	}
	playerData[player] = data
	return data
end

function GameState.GetPlayerData(player)
	return playerData[player]
end

function GameState.RemovePlayerData(player)
	local data = playerData[player]
	if data ~= nil and data.BaseIndex ~= nil then
		baseOwners[data.BaseIndex] = nil
	end
	playerData[player] = nil
end

function GameState.AssignBase(player)
	local data = playerData[player]
	if data == nil then
		return nil
	end
	if data.BaseIndex ~= nil then
		return data.BaseIndex
	end
	for index = 1, Config.BaseCount do
		if baseOwners[index] == nil then
			baseOwners[index] = player
			data.BaseIndex = index
			return index
		end
	end
	-- More players than plots: share the last plot rather than stranding
	-- anyone without a base.
	baseOwners[Config.BaseCount] = player
	data.BaseIndex = Config.BaseCount
	return Config.BaseCount
end

function GameState.GetBaseOwner(baseIndex)
	return baseOwners[baseIndex]
end

function GameState.GetRebirthMultiplier(rebirths)
	return 1 + rebirths * Config.RebirthMultiplierStep
end

function GameState.GetRebirthCost(rebirths)
	return Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ rebirths)
end

function GameState.AddCash(player, amount)
	local data = playerData[player]
	if data == nil then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.TotalEarned += amount
	end
end

function GameState.SpendCash(player, amount)
	local data = playerData[player]
	if data == nil or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	return true
end

function GameState.GetIncomePerSecond(player)
	local data = playerData[player]
	if data == nil then
		return 0
	end
	local multiplier = GameState.GetRebirthMultiplier(data.Rebirths)
	local total = 0
	for _, record in ipairs(data.Placed) do
		local entry = Catalog.GetEntry(record.BrainrotId)
		if entry ~= nil then
			total += Catalog.EffectiveRate(entry, record.Mutation, multiplier)
		end
	end
	return total
end

function GameState.GetFreeSlot(player)
	local data = playerData[player]
	if data == nil then
		return nil
	end
	local used = {}
	for _, record in ipairs(data.Placed) do
		used[record.Slot] = true
	end
	for slot = 1, Config.SlotsPerBase do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

function GameState.GetPlacedRecord(player, model)
	local data = playerData[player]
	if data == nil then
		return nil
	end
	for _, record in ipairs(data.Placed) do
		if record.Model == model then
			return record
		end
	end
	return nil
end

function GameState.RemovePlacedRecord(player, model)
	local data = playerData[player]
	if data == nil then
		return nil
	end
	for index, record in ipairs(data.Placed) do
		if record.Model == model then
			table.remove(data.Placed, index)
			return record
		end
	end
	return nil
end

function GameState.GetWeakestPlacedRecord(player)
	local data = playerData[player]
	if data == nil or #data.Placed == 0 then
		return nil
	end
	local weakest = nil
	local weakestRate = math.huge
	local multiplier = GameState.GetRebirthMultiplier(data.Rebirths)
	for _, record in ipairs(data.Placed) do
		local entry = Catalog.GetEntry(record.BrainrotId)
		if entry ~= nil then
			local rate = Catalog.EffectiveRate(entry, record.Mutation, multiplier)
			if rate < weakestRate then
				weakestRate = rate
				weakest = record
			end
		end
	end
	return weakest
end

function GameState.GetAllPlayerData()
	return playerData
end

return GameState
