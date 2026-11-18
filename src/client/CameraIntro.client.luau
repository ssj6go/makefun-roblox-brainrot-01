-- Brainrot Bay: the intro camera. On the first spawn the camera sweeps
-- once over the conveyor and the bases, then hands control back to the
-- player. Short, skippable by moving, and wrapped in pcall so a hiccup
-- here can never break the game.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local INTRO_SECONDS = 4
local introDone = false

local function playIntroCamera()
	if introDone then
		return
	end
	introDone = true
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart")

	local ok = pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		local startPos = Vector3.new(-50, 30, 45)
		local endPos = Vector3.new(10, 18, 40)
		camera.CFrame = CFrame.new(startPos, Vector3.new(0, 0, 0))
		local sweep = TweenService:Create(
			camera,
			TweenInfo.new(INTRO_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ CFrame = CFrame.new(endPos, root.Position) }
		)
		sweep:Play()
		sweep.Completed:Wait()
	end)
	if ok then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
	end
end

player.CharacterAdded:Connect(function()
	task.delay(0.5, playIntroCamera)
end)
if player.Character ~= nil then
	task.delay(0.5, playIntroCamera)
end
