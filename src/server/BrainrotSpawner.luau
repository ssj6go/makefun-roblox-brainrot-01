-- Brainrot Bay: the conveyor spawner. New brainrots appear at the rainbow
-- portal, walk the belt east, and leave unclaimed at the far end. Buying
-- one is a ProximityPrompt the server answers: the client never decides
-- a purchase.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local BrainrotSpawner = {}

local rng = Random.new()
local conveyorModels = {} -- list of { Model, Entry, Mutation, WalkPhase }
local conveyorFolder = nil

local function isOnConveyor(model)
	for _, record in ipairs(conveyorModels) do
		if record.Model == model then
			return true
		end
	end
	return false
end

function BrainrotSpawner.RemoveFromConveyor(model)
	for index, record in ipairs(conveyorModels) do
		if record.Model == model then
			table.remove(conveyorModels, index)
			return record
		end
	end
	return nil
end

function BrainrotSpawner.GetConveyorCount()
	return #conveyorModels
end

local function createBuyPrompt(model, entry)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ObjectText = Catalog.DisplayName(entry, model:GetAttribute("Mutation"))
	prompt.ActionText = "Buy"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(player)
		if not isOnConveyor(model) then
			return
		end
		local bought = Economy.TryBuyBrainrot(player, model, entry)
		if bought then
			BrainrotSpawner.RemoveFromConveyor(model)
			prompt:Destroy()
		end
	end)
end

function BrainrotSpawner.SpawnBrainrot()
	if #conveyorModels >= Config.MaxConveyorBrainrots then
		return nil
	end
	local entry = Catalog.PickRandomEntry(rng)
	local mutation = Catalog.RollMutation(rng)
	local model = WorldBuilder.BuildBrainrotModel(entry, mutation.Name)
	model:SetAttribute("Cost", entry.Cost)
	model.Parent = conveyorFolder
	local root = model.PrimaryPart
	root.CFrame = CFrame.new(Config.ConveyorStartX, 1.3, Config.ConveyorZ)
	createBuyPrompt(model, entry)
	table.insert(conveyorModels, {
		Model = model,
		Entry = entry,
		Mutation = mutation.Name,
		WalkPhase = rng:NextNumber() * math.pi * 2,
	})
	return model
end

-- One Heartbeat moves every walking brainrot: steady eastward march with
-- a little waddle bob, and a clean exit at the far end of the belt.
local function startConveyorLoop()
	RunService.Heartbeat:Connect(function(dt)
		for index = #conveyorModels, 1, -1 do
			local record = conveyorModels[index]
			local model = record.Model
			local root = model.PrimaryPart
			if root == nil then
				table.remove(conveyorModels, index)
			else
				record.WalkPhase += dt * 6
				local newX = root.Position.X + Config.ConveyorSpeed * dt
				if newX >= Config.ConveyorEndX then
					model:Destroy()
					table.remove(conveyorModels, index)
				else
					local bob = math.sin(record.WalkPhase) * 0.25
					local tilt = math.sin(record.WalkPhase) * 0.12
					root.CFrame = CFrame.new(newX, 1.3 + bob, Config.ConveyorZ)
						* CFrame.Angles(0, math.rad(90), tilt)
				end
			end
		end
	end)
end

function BrainrotSpawner.StartSpawner()
	conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "ConveyorBrainrots"
	conveyorFolder.Parent = Workspace

	startConveyorLoop()

	task.spawn(function()
		-- Seed the belt so the first player sees a full cast at once.
		for _ = 1, 4 do
			BrainrotSpawner.SpawnBrainrot()
			task.wait(0.2)
		end
		while true do
			task.wait(Config.SpawnIntervalSeconds)
			BrainrotSpawner.SpawnBrainrot()
		end
	end)
end

-- A dropped brainrot (tsunami, or a thief who got swept) comes back as a
-- free spawn on the belt so it is never lost from the game.
function BrainrotSpawner.RespawnBrainrotOnConveyor(entryId, mutationName)
	local entry = Catalog.GetEntry(entryId)
	if entry == nil then
		return nil
	end
	local mutation = Catalog.GetMutation(mutationName) or Catalog.Mutations[1]
	local model = WorldBuilder.BuildBrainrotModel(entry, mutation.Name)
	model:SetAttribute("Cost", entry.Cost)
	model.Parent = conveyorFolder
	local root = model.PrimaryPart
	root.CFrame = CFrame.new(Config.ConveyorStartX, 1.3, Config.ConveyorZ)
	createBuyPrompt(model, entry)
	table.insert(conveyorModels, {
		Model = model,
		Entry = entry,
		Mutation = mutation.Name,
		WalkPhase = 0,
	})
	return model
end

return BrainrotSpawner
