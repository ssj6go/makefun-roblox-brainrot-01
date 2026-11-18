-- Brainrot Bay: the meme tsunami. Every two minutes a warning sounds,
-- then a wall of water sweeps the map west to east. Anyone caught
-- outside their own base is washed back to spawn and drops whatever they
-- were carrying; a dropped brainrot is never lost, it returns to its
-- owner or to the conveyor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BrainrotSpawner = require(script.Parent:WaitForChild("BrainrotSpawner"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local Notify = require(script.Parent:WaitForChild("Notify"))

local TsunamiEvent = {}

local waveRunning = false
local secondsToNextWave = Config.WaveIntervalSeconds

function TsunamiEvent.GetWaveState()
	local state = GameState.GetWaveState()
	if state.Phase == "calm" then
		return { Phase = "calm", SecondsLeft = secondsToNextWave }
	end
	return state
end

-- Drops what a player carries. A stolen brainrot goes home to its
-- victim's base; a bought one returns to the conveyor as a free spawn.
local function dropCarriedBrainrot(player)
	local data = GameState.GetPlayerData(player)
	if data == nil or data.Carrying == nil or data.CarryingInfo == nil then
		return
	end
	local model = data.Carrying
	local info = data.CarryingInfo
	local stolenFrom = data.StolenFrom
	data.Carrying = nil
	data.CarryingInfo = nil
	data.StolenFrom = nil
	WorldBuilder.DetachFromPlayer(model)
	model:Destroy()

	if stolenFrom ~= nil and GameState.GetPlayerData(stolenFrom) ~= nil then
		Economy.PlaceLoadedBrainrot(stolenFrom, info.BrainrotId, info.Mutation)
		Notify.Player(stolenFrom, "The wave washed your stolen brainrot back home!", "good")
	else
		BrainrotSpawner.RespawnBrainrotOnConveyor(info.BrainrotId, info.Mutation)
	end
end

local function washPlayerToSpawn(player)
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	dropCarriedBrainrot(player)
	root.CFrame = CFrame.new(0, 3, 95)
	Notify.Player(player, "The tsunami washed you back to spawn!", "bad")
end

local function buildWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(6, 24, 220)
	wall.Position = Vector3.new(Config.WaveStartX, 12, 0)
	wall.Anchored = true
	wall.CanCollide = false
	wall.Transparency = 0.35
	wall.Color = Color3.fromRGB(60, 140, 255)
	wall.Material = Enum.Material.Glass
	wall.Parent = Workspace
	return wall
end

function TsunamiEvent.RunWave()
	if waveRunning then
		return
	end
	waveRunning = true

	-- Warning phase: the HUD counts down and the banner screams.
	GameState.SetWaveState("warning", Config.WaveWarningSeconds)
	Notify.All("TSUNAMI INCOMING! Get back to your base!", "bad")
	for remaining = Config.WaveWarningSeconds, 1, -1 do
		GameState.SetWaveState("warning", remaining)
		task.wait(1)
	end

	-- Sweep phase: the wall crosses the map; anyone it touches outside
	-- their own base gets washed to spawn.
	GameState.SetWaveState("sweep", Config.WaveSweepSeconds)
	local wall = buildWaveWall()
	local alreadyWashed = {}
	local sweepStart = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - sweepStart
		local progress = math.clamp(elapsed / Config.WaveSweepSeconds, 0, 1)
		local wallX = Config.WaveStartX + (Config.WaveEndX - Config.WaveStartX) * progress
		wall.Position = Vector3.new(wallX, 12, 0)
		GameState.SetWaveState("sweep", math.ceil(Config.WaveSweepSeconds - elapsed))
		for player, data in pairs(GameState.GetAllPlayerData()) do
			if alreadyWashed[player] == nil then
				local character = player.Character
				local root = character ~= nil and character:FindFirstChild("HumanoidRootPart") or nil
				if root ~= nil and math.abs(root.Position.X - wallX) < 5 then
					if data.BaseIndex == nil or not GameState.IsInsideBase(root.Position, data.BaseIndex) then
						alreadyWashed[player] = true
						washPlayerToSpawn(player)
					end
				end
			end
		end
		if progress >= 1 then
			connection:Disconnect()
		end
	end)

	task.wait(Config.WaveSweepSeconds + 0.5)
	if wall ~= nil then
		wall:Destroy()
	end
	GameState.SetWaveState("calm", 0)
	secondsToNextWave = Config.WaveIntervalSeconds
	waveRunning = false
	Notify.All("The tsunami passed. The conveyor is open again!", "info")
end

function TsunamiEvent.StartTsunami()
	task.spawn(function()
		while true do
			for remaining = Config.WaveIntervalSeconds, 1, -1 do
				secondsToNextWave = remaining
				task.wait(1)
			end
			TsunamiEvent.RunWave()
		end
	end)
end

-- Used by the tour helper so reviewers can see a wave on demand.
function TsunamiEvent.ForceWave()
	if waveRunning then
		return false
	end
	task.spawn(TsunamiEvent.RunWave)
	return true
end

return TsunamiEvent
