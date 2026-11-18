-- Brainrot Bay: stealing. A rival can hold E on a brainrot placed on
-- someone else's base and carry it home, but the victim gets a shield, a
-- lock button and a cooldown on the thief, so stealing stays a daring
-- raid instead of griefing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local Notify = require(script.Parent:WaitForChild("Notify"))

local StealSystem = {}

local lockBaseEvent = nil

function StealSystem.CreateStealPrompt(model, owner)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ObjectText = model.Name
	prompt.ActionText = "Steal"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = Config.StealHoldSeconds
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(thief)
		StealSystem.TrySteal(thief, owner, model, prompt)
	end)
end

local function isBaseProtected(owner)
	local data = GameState.GetPlayerData(owner)
	if data == nil then
		return true
	end
	local now = os.clock()
	if now < data.BaseShieldUntil then
		return true
	end
	if now < data.BaseLockUntil then
		return true
	end
	return false
end

function StealSystem.TrySteal(thief, owner, model, prompt)
	if thief == owner then
		return false
	end
	local thiefData = GameState.GetPlayerData(thief)
	local ownerData = GameState.GetPlayerData(owner)
	if thiefData == nil or ownerData == nil then
		return false
	end
	if thiefData.Carrying ~= nil then
		Notify.Player(thief, "Your hands are full! Place what you carry first.", "warn")
		return false
	end
	if GameState.GetFreeSlot(thief) == nil then
		Notify.Player(thief, "Your base is full! No room for stolen goods.", "warn")
		return false
	end
	local now = os.clock()
	if now < thiefData.LastStealAt + Config.StealCooldownSeconds then
		Notify.Player(thief, "Stealing is on cooldown. Lay low for a bit.", "warn")
		return false
	end
	if isBaseProtected(owner) then
		Notify.Player(thief, "That base is shielded! Come back later.", "warn")
		return false
	end
	local record = GameState.GetPlacedRecord(owner, model)
	if record == nil then
		return false
	end
	if now < record.PlacedAt + Config.NewPlacementLockSeconds then
		Notify.Player(thief, "That brainrot was just placed and cannot be stolen yet.", "warn")
		return false
	end

	GameState.RemovePlacedRecord(owner, model)
	if prompt ~= nil then
		prompt:Destroy()
	end
	if not WorldBuilder.AttachToPlayer(model, thief) then
		-- Attach failed (thief respawning?): put the brainrot back.
		WorldBuilder.PlaceOnSlot(model, ownerData.BaseIndex, record.Slot)
		table.insert(ownerData.Placed, record)
		StealSystem.CreateStealPrompt(model, owner)
		return false
	end
	thiefData.Carrying = model
	thiefData.CarryingInfo = { BrainrotId = record.BrainrotId, Mutation = record.Mutation }
	thiefData.StolenFrom = owner
	thiefData.LastStealAt = now
	ownerData.BaseShieldUntil = now + Config.BaseShieldSeconds

	local entry = Catalog.GetEntry(record.BrainrotId)
	local displayName = entry ~= nil and Catalog.DisplayName(entry, record.Mutation) or "a brainrot"
	Notify.Player(thief, "You stole " .. displayName .. "! RUN HOME before the wave!", "good")
	Notify.Player(owner, thief.Name .. " stole your " .. displayName .. "! Your base is shielded for "
		.. Config.BaseShieldSeconds .. "s.", "bad")
	return true
end

-- The owner's defence: lock the base for 30 seconds. While locked, every
-- steal prompt on the base is disabled.
function StealSystem.TryLockBase(player)
	local data = GameState.GetPlayerData(player)
	if data == nil then
		return false
	end
	local now = os.clock()
	if now < data.BaseLockReadyAt then
		Notify.Player(player, "Base lock is recharging.", "warn")
		return false
	end
	data.BaseLockUntil = now + Config.BaseLockSeconds
	data.BaseLockReadyAt = now + Config.BaseLockCooldownSeconds
	for _, record in ipairs(data.Placed) do
		if record.Model ~= nil and record.Model.PrimaryPart ~= nil then
			local prompt = record.Model.PrimaryPart:FindFirstChild("StealPrompt")
			if prompt ~= nil then
				prompt.Enabled = false
			end
		end
	end
	Notify.Player(player, "Base locked for " .. Config.BaseLockSeconds .. " seconds!", "good")
	task.delay(Config.BaseLockSeconds, function()
		for _, record in ipairs(data.Placed) do
			if record.Model ~= nil and record.Model.PrimaryPart ~= nil then
				local prompt = record.Model.PrimaryPart:FindFirstChild("StealPrompt")
				if prompt ~= nil then
					prompt.Enabled = true
				end
			end
		end
	end)
	return true
end

function StealSystem.StartStealSystem()
	lockBaseEvent = ReplicatedStorage:WaitForChild("LockBaseEvent")
	lockBaseEvent.OnServerEvent:Connect(function(player)
		StealSystem.TryLockBase(player)
	end)
end

return StealSystem
