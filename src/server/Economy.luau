-- Brainrot Bay: the economy. The server owns every dollar: buying,
-- placing, selling and the per-second earnings tick all run here, and the
-- client only displays the snapshots this module broadcasts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FormatUtil"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))
local Leaderboard = require(script.Parent:WaitForChild("Leaderboard"))

local Economy = {}

local stateUpdateEvent = nil
local notifyEvent = nil
local sellEvent = nil

function Economy.Notify(player, text, kind)
	if notifyEvent == nil then
		return
	end
	notifyEvent:FireClient(player, { Text = text, Kind = kind or "info" })
end

function Economy.NotifyAll(text, kind)
	if notifyEvent == nil then
		return
	end
	notifyEvent:FireAllClients({ Text = text, Kind = kind or "info" })
end

-- Buying: the prompt hands us the model; we re-check everything, because
-- a prompt trigger is a client claim, not a fact.
function Economy.TryBuyBrainrot(player, model, entry)
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	if data.Carrying ~= nil then
		Economy.Notify(player, "You are already carrying a brainrot! Drop it at your base first.", "warn")
		return false
	end
	if GameState.GetFreeSlot(player) == nil then
		Economy.Notify(player, "Your base is full! Sell or rebirth to make room.", "warn")
		return false
	end
	if not GameState.SpendCash(player, entry.Cost) then
		Economy.Notify(player, "Not enough cash for " .. entry.Name .. " (" .. FormatUtil.FormatMoney(entry.Cost) .. ").", "warn")
		return false
	end
	local mutationName = model:GetAttribute("Mutation") or "Normal"
	if not WorldBuilder.AttachToPlayer(model, player) then
		GameState.AddCash(player, entry.Cost)
		return false
	end
	data.Carrying = model
	data.CarryingInfo = { BrainrotId = entry.Id, Mutation = mutationName }
	data.StolenFrom = nil
	data.HasBought = true
	Economy.Notify(
		player,
		"Bought " .. Catalog.DisplayName(entry, mutationName) .. "! Run home to your base!",
		"good"
	)
	return true
end

-- Carrying ends at home: the brainrot takes the first free slot and
-- starts earning. Called by the auto-place loop and by the steal system.
function Economy.PlaceCarriedBrainrot(player)
	local data = GameState.GetPlayerData(player)
	if data == nil or data.Carrying == nil or data.CarryingInfo == nil then
		return false
	end
	local slot = GameState.GetFreeSlot(player)
	if slot == nil then
		return false
	end
	local model = data.Carrying
	local info = data.CarryingInfo
	local stolenFrom = data.StolenFrom
	WorldBuilder.PlaceOnSlot(model, data.BaseIndex, slot)
	table.insert(data.Placed, {
		BrainrotId = info.BrainrotId,
		Mutation = info.Mutation,
		Slot = slot,
		Model = model,
		PlacedAt = os.clock(),
	})
	data.Carrying = nil
	data.CarryingInfo = nil
	data.StolenFrom = nil
	data.HasPlaced = true
	StealSystem.CreateStealPrompt(model, player)
	local entry = Catalog.GetEntry(info.BrainrotId)
	if entry ~= nil then
		if stolenFrom ~= nil then
			Economy.Notify(player, "Stolen " .. Catalog.DisplayName(entry, info.Mutation) .. " secured on your base!", "good")
			Economy.Notify(stolenFrom, player.Name .. " stole your " .. entry.Name .. "!", "bad")
		else
			Economy.Notify(
				player,
				entry.Name .. " placed! Now earning " .. FormatUtil.FormatRate(Catalog.EffectiveRate(entry, info.Mutation, GameState.GetRebirthMultiplier(data.Rebirths))) .. ".",
				"good"
			)
		end
	end
	return true
end

-- Used when a save file restores a player's placed brainrots on join.
function Economy.PlaceLoadedBrainrot(player, brainrotId, mutationName)
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	local entry = Catalog.GetEntry(brainrotId)
	if entry == nil then
		return false
	end
	local slot = GameState.GetFreeSlot(player)
	if slot == nil then
		return false
	end
	local model = WorldBuilder.BuildBrainrotModel(entry, mutationName)
	model.Parent = game:GetService("Workspace")
	WorldBuilder.PlaceOnSlot(model, data.BaseIndex, slot)
	table.insert(data.Placed, {
		BrainrotId = brainrotId,
		Mutation = mutationName,
		Slot = slot,
		Model = model,
		PlacedAt = os.clock(),
	})
	StealSystem.CreateStealPrompt(model, player)
	return true
end

-- The earnings tick: every placed brainrot pays its rate, multiplied by
-- its mutation and the owner's rebirth multiplier, once a second.
function Economy.GrantEarnings()
	for player, data in pairs(GameState.GetAllPlayerData()) do
		local income = GameState.GetIncomePerSecond(player)
		if income > 0 then
			GameState.AddCash(player, income * Config.EarningsTickSeconds)
		end
	end
end

-- Sell the weakest placed brainrot for half its price.
function Economy.TrySellWeakest(player)
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	local record = GameState.GetWeakestPlacedRecord(player)
	if record == nil then
		Economy.Notify(player, "Nothing to sell yet.", "warn")
		return false
	end
	local entry = Catalog.GetEntry(record.BrainrotId)
	if entry == nil then
		return false
	end
	local refund = math.floor(entry.Cost * Config.SellRefundFraction)
	GameState.RemovePlacedRecord(player, record.Model)
	if record.Model ~= nil then
		record.Model:Destroy()
	end
	GameState.AddCash(player, refund)
	Economy.Notify(player, "Sold " .. entry.Name .. " for " .. FormatUtil.FormatMoney(refund) .. ".", "info")
	return true
end

-- One snapshot per second per player: cash, income, carrying, timers and
-- the leaderboard. The HUD never computes money itself.
local function buildStateSnapshot(player, data)
	local carryingName = nil
	if data.CarryingInfo ~= nil then
		local entry = Catalog.GetEntry(data.CarryingInfo.BrainrotId)
		if entry ~= nil then
			carryingName = Catalog.DisplayName(entry, data.CarryingInfo.Mutation)
		end
	end
	local placed = {}
	for _, record in ipairs(data.Placed) do
		local entry = Catalog.GetEntry(record.BrainrotId)
		if entry ~= nil then
			table.insert(placed, {
				Name = Catalog.DisplayName(entry, record.Mutation),
				Rarity = entry.Rarity,
				Rate = Catalog.EffectiveRate(entry, record.Mutation, GameState.GetRebirthMultiplier(data.Rebirths)),
			})
		end
	end
	local now = os.clock()
	return {
		Cash = data.Cash,
		IncomePerSecond = GameState.GetIncomePerSecond(player),
		Rebirths = data.Rebirths,
		RebirthMultiplier = GameState.GetRebirthMultiplier(data.Rebirths),
		RebirthCost = GameState.GetRebirthCost(data.Rebirths),
		Placed = placed,
		PlacedCount = #data.Placed,
		SlotsTotal = Config.SlotsPerBase,
		Carrying = carryingName,
		BaseCenter = GameState.GetBaseCenterTable(data.BaseIndex or 1),
		BaseIndex = data.BaseIndex,
		HasBought = data.HasBought,
		HasPlaced = data.HasPlaced,
		StealCooldownLeft = math.max(0, data.LastStealAt + Config.StealCooldownSeconds - now),
		BaseShieldLeft = math.max(0, data.BaseShieldUntil - now),
		BaseLockLeft = math.max(0, data.BaseLockUntil - now),
		BaseLockReadyIn = math.max(0, data.BaseLockReadyAt - now),
		WaveState = GameState.GetWaveState(),
		Leaderboard = Leaderboard.GetTopPlayers(),
	}
end

function Economy.BroadcastState()
	if stateUpdateEvent == nil then
		return
	end
	for player, data in pairs(GameState.GetAllPlayerData()) do
		stateUpdateEvent:FireClient(player, buildStateSnapshot(player, data))
	end
end

function Economy.GetStateSnapshot(player)
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return nil
	end
	return buildStateSnapshot(player, data)
end

local function startAutoPlaceLoop()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for player, data in pairs(GameState.GetAllPlayerData()) do
				if data.Carrying ~= nil and data.BaseIndex ~= nil then
					local character = player.Character
					local root = character ~= nil and character:FindFirstChild("HumanoidRootPart") or nil
					if root ~= nil and GameState.IsInsideBase(root.Position, data.BaseIndex) then
						Economy.PlaceCarriedBrainrot(player)
					end
				end
			end
		end
	end)
end

function Economy.StartEconomy()
	stateUpdateEvent = ReplicatedStorage:WaitForChild("StateUpdate")
	notifyEvent = ReplicatedStorage:WaitForChild("Notify")
	sellEvent = ReplicatedStorage:WaitForChild("SellEvent")

	sellEvent.OnServerEvent:Connect(function(player)
		Economy.TrySellWeakest(player)
	end)

	task.spawn(function()
		while true do
			task.wait(Config.EarningsTickSeconds)
			Economy.GrantEarnings()
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.StateBroadcastSeconds)
			Economy.BroadcastState()
		end
	end)

	startAutoPlaceLoop()
end

return Economy
