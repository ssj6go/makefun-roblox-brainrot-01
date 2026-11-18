-- Brainrot Bay: the home beacon. While the player carries a brainrot, a
-- tall green beam marks their own base so the dash home never needs a
-- map. Purely client-side: the server never trusts it for placement.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local stateUpdateEvent = ReplicatedStorage:WaitForChild("StateUpdate")

local beacon = nil

local function showBeacon(baseCenter)
	if beacon ~= nil then
		return
	end
	beacon = Instance.new("Part")
	beacon.Name = "HomeBeacon"
	beacon.Size = Vector3.new(3, 60, 3)
	beacon.Position = Vector3.new(baseCenter.x, 30, baseCenter.z)
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.CanQuery = false
	beacon.Transparency = 0.55
	beacon.Color = Color3.fromRGB(80, 255, 120)
	beacon.Material = Enum.Material.Neon
	beacon.Parent = Workspace

	local ring = Instance.new("Part")
	ring.Name = "BeaconRing"
	ring.Size = Vector3.new(14, 0.4, 14)
	ring.Position = Vector3.new(baseCenter.x, 1.4, baseCenter.z)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Transparency = 0.4
	ring.Color = Color3.fromRGB(80, 255, 120)
	ring.Material = Enum.Material.Neon
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = beacon
end

local function hideBeacon()
	if beacon ~= nil then
		beacon:Destroy()
		beacon = nil
	end
end

stateUpdateEvent.OnClientEvent:Connect(function(state)
	if state == nil then
		return
	end
	if state.Carrying ~= nil and state.BaseCenter ~= nil then
		showBeacon(state.BaseCenter)
	else
		hideBeacon()
	end
end)
