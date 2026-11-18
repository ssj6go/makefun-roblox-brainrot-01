-- Brainrot Bay: builds the 3D world. The static ground, conveyor and base
-- platforms come from the Rojo project; this module grows everything else
-- at runtime: trees, lamps, slot pads, the portal arch, and every
-- brainrot character model, each one assembled from parts with its own
-- colours, accessory and floating name tag.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))
local FormatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FormatUtil"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local WorldBuilder = {}

local worldFolder = nil
local baseSigns = {} -- [baseIndex] = TextLabel of the base's sign

local function newPart(name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function buildTree(position, trunkHeight)
	local trunk = newPart(
		"TreeTrunk",
		Vector3.new(1.5, trunkHeight, 1.5),
		position + Vector3.new(0, trunkHeight / 2, 0),
		Color3.fromRGB(120, 80, 40),
		Enum.Material.Wood
	)
	trunk.Parent = worldFolder
	local leaves = newPart(
		"TreeLeaves",
		Vector3.new(6, 5, 6),
		position + Vector3.new(0, trunkHeight + 2, 0),
		Color3.fromRGB(50, 160, 60),
		Enum.Material.Grass
	)
	leaves.Shape = Enum.PartType.Ball
	leaves.Parent = worldFolder
end

local function buildLamp(position)
	local pole = newPart(
		"LampPole",
		Vector3.new(0.8, 6, 0.8),
		position + Vector3.new(0, 3, 0),
		Color3.fromRGB(70, 70, 80),
		Enum.Material.Metal
	)
	pole.Parent = worldFolder
	local head = newPart(
		"LampHead",
		Vector3.new(2, 1, 2),
		position + Vector3.new(0, 6.5, 0),
		Color3.fromRGB(255, 240, 150),
		Enum.Material.Neon
	)
	head.Parent = worldFolder
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 240, 150)
	light.Range = 18
	light.Brightness = 1
	light.Parent = head
end

local function buildSlotPads()
	for baseIndex = 1, Config.BaseCount do
		for slot = 1, Config.SlotsPerBase do
			local position = GameState.GetSlotPosition(baseIndex, slot)
			local pad = newPart(
				"SlotPad",
				Vector3.new(4.5, 0.3, 4.5),
				Vector3.new(position.X, 1.1, position.Z),
				Color3.fromRGB(255, 255, 255),
				Enum.Material.Neon
			)
			pad.Transparency = 0.5
			pad.CanCollide = false
			pad.Parent = worldFolder
		end
	end
end

local function buildBaseSign(baseIndex)
	local center = GameState.GetBaseCenter(baseIndex)
	local post = newPart(
		"BaseSignPost",
		Vector3.new(1, 7, 1),
		center + Vector3.new(0, 3.5, -Config.BaseSize / 2 - 1),
		Color3.fromRGB(90, 60, 30),
		Enum.Material.Wood
	)
	post.Parent = worldFolder
	local board = newPart(
		"BaseSignBoard",
		Vector3.new(10, 3.5, 0.6),
		center + Vector3.new(0, 7.5, -Config.BaseSize / 2 - 1),
		Color3.fromRGB(255, 240, 200),
		Enum.Material.WoodPlanks
	)
	board.Parent = worldFolder
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
	surfaceGui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "OwnerLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "EMPTY BASE"
	label.TextColor3 = Color3.fromRGB(60, 40, 20)
	label.TextSize = 28
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Parent = surfaceGui
	baseSigns[baseIndex] = label
end

local function buildPortalArch()
	-- A rainbow arch over the conveyor's west end, where brainrots appear.
	local archColors = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(255, 170, 40),
		Color3.fromRGB(255, 235, 60),
		Color3.fromRGB(90, 220, 90),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(170, 100, 255),
	}
	for i, color in ipairs(archColors) do
		local angle = math.rad(180 - (i - 0.5) * (180 / #archColors))
		local radius = 9
		local x = Config.ConveyorStartX - 3
		local y = 1 + math.sin(angle) * radius
		local z = Config.ConveyorZ + math.cos(angle) * radius
		local segment = newPart(
			"ArchSegment",
			Vector3.new(1.6, 5.2, 1.6),
			Vector3.new(x, y, z),
			color,
			Enum.Material.Neon
		)
		segment.CFrame = CFrame.new(Vector3.new(x, y, z))
			* CFrame.Angles(-angle, 0, 0)
		segment.CanCollide = false
		segment.Parent = worldFolder
	end
end

local function buildFloatingCoins()
	-- A ring of spinning coins above the plaza, pure decoration.
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local coin = newPart(
			"FloatingCoin",
			Vector3.new(2.4, 2.4, 0.4),
			Vector3.new(math.cos(angle) * 22, 14, math.sin(angle) * 22),
			Color3.fromRGB(255, 210, 40),
			Enum.Material.Metal
		)
		coin.Shape = Enum.PartType.Cylinder
		coin.CFrame = CFrame.new(coin.Position) * CFrame.Angles(0, 0, math.rad(90))
		coin.CanCollide = false
		coin.Parent = worldFolder
	end
end

function WorldBuilder.BuildWorld()
	worldFolder = Instance.new("Folder")
	worldFolder.Name = "BrainrotBayWorld"
	worldFolder.Parent = Workspace

	-- Trees dotted around the ring road, clear of bases and conveyor.
	local treeSpots = {
		Vector3.new(-30, 0, 45), Vector3.new(30, 0, 45),
		Vector3.new(-30, 0, -45), Vector3.new(30, 0, -45),
		Vector3.new(-75, 0, 20), Vector3.new(75, 0, 20),
		Vector3.new(-75, 0, -20), Vector3.new(75, 0, -20),
		Vector3.new(0, 0, 88), Vector3.new(-55, 0, 75),
		Vector3.new(55, 0, 75), Vector3.new(0, 0, -88),
	}
	for _, spot in ipairs(treeSpots) do
		buildTree(spot, 5)
	end

	-- Lamps along the conveyor so the middle of the map glows at night.
	buildLamp(Vector3.new(-25, 0, 9))
	buildLamp(Vector3.new(0, 0, 9))
	buildLamp(Vector3.new(25, 0, 9))
	buildLamp(Vector3.new(-25, 0, -9))
	buildLamp(Vector3.new(0, 0, -9))
	buildLamp(Vector3.new(25, 0, -9))

	buildSlotPads()
	for baseIndex = 1, Config.BaseCount do
		buildBaseSign(baseIndex)
	end
	buildPortalArch()
	buildFloatingCoins()
end

function WorldBuilder.SetBaseSignOwner(baseIndex, ownerName)
	local label = baseSigns[baseIndex]
	if label ~= nil then
		label.Text = ownerName .. "'s BASE"
	end
end

function WorldBuilder.ClearBaseSign(baseIndex)
	local label = baseSigns[baseIndex]
	if label ~= nil then
		label.Text = "EMPTY BASE"
	end
end

-- Builds one brainrot's body: a chunky little character with a head, eyes
-- and the accessory that makes it recognisable, plus a floating name tag.
function WorldBuilder.BuildBrainrotModel(entry, mutationName)
	local mutation = Catalog.GetMutation(mutationName) or Catalog.Mutations[1]
	local bodyColor = entry.BodyColor
	if mutation.Color ~= nil then
		bodyColor = mutation.Color
	end

	local model = Instance.new("Model")
	model.Name = Catalog.DisplayName(entry, mutationName)

	local root = newPart("Root", Vector3.new(2.6, 2.6, 2.6), Vector3.new(0, 1.3, 0), bodyColor)
	root.Parent = model
	model.PrimaryPart = root

	local head = newPart("Head", Vector3.new(2.2, 1.8, 2.2), Vector3.new(0, 3.4, 0), bodyColor)
	head.Parent = model

	local eyeLeft = newPart("EyeLeft", Vector3.new(0.4, 0.6, 0.2), Vector3.new(-0.55, 3.6, 1.15), Color3.fromRGB(20, 20, 20))
	eyeLeft.Parent = model
	local eyeRight = newPart("EyeRight", Vector3.new(0.4, 0.6, 0.2), Vector3.new(0.55, 3.6, 1.15), Color3.fromRGB(20, 20, 20))
	eyeRight.Parent = model

	-- One accessory part per character, bolted on top or to the side.
	local accessory = nil
	if entry.Accessory == "toaster" then
		accessory = newPart("Toaster", Vector3.new(2, 1.4, 1.2), Vector3.new(0, 1.6, -1.8), entry.AccentColor, Enum.Material.Metal)
	elseif entry.Accessory == "sock" then
		accessory = newPart("Sock", Vector3.new(1, 1.8, 0.8), Vector3.new(1.6, 3.4, 0), entry.AccentColor)
	elseif entry.Accessory == "pillow" then
		accessory = newPart("Pillow", Vector3.new(2.8, 0.8, 1.8), Vector3.new(0, 4.7, 0), entry.AccentColor)
	elseif entry.Accessory == "noodles" then
		accessory = newPart("Noodles", Vector3.new(2, 0.8, 2), Vector3.new(0, 4.6, 0), entry.AccentColor)
		accessory.Shape = Enum.PartType.Ball
	elseif entry.Accessory == "meatball" then
		accessory = newPart("Meatball", Vector3.new(1.4, 1.4, 1.4), Vector3.new(1.5, 4.4, 0), entry.AccentColor)
		accessory.Shape = Enum.PartType.Ball
	elseif entry.Accessory == "peel" then
		accessory = newPart("Peel", Vector3.new(0.6, 2.4, 0.6), Vector3.new(-1.5, 3.8, 0), entry.AccentColor)
	elseif entry.Accessory == "discoBall" then
		accessory = newPart("DiscoBall", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, 5.2, 0), Color3.fromRGB(220, 220, 255), Enum.Material.Metal)
		accessory.Shape = Enum.PartType.Ball
	elseif entry.Accessory == "spoiler" then
		accessory = newPart("Spoiler", Vector3.new(3, 0.4, 1), Vector3.new(0, 2.6, -1.8), entry.AccentColor, Enum.Material.Metal)
	elseif entry.Accessory == "atom" then
		accessory = newPart("Atom", Vector3.new(1.8, 1.8, 1.8), Vector3.new(0, 5.2, 0), entry.AccentColor, Enum.Material.Neon)
		accessory.Shape = Enum.PartType.Ball
	elseif entry.Accessory == "laserEyes" then
		accessory = newPart("LaserBeam", Vector3.new(0.3, 0.3, 3), Vector3.new(0, 3.6, 2.6), Color3.fromRGB(255, 60, 60), Enum.Material.Neon)
	elseif entry.Accessory == "planet" then
		accessory = newPart("Planet", Vector3.new(2, 2, 2), Vector3.new(0, 5.4, 0), entry.AccentColor)
		accessory.Shape = Enum.PartType.Ball
	elseif entry.Accessory == "star" then
		accessory = newPart("Star", Vector3.new(1.6, 1.6, 0.4), Vector3.new(0, 5, 0), entry.AccentColor, Enum.Material.Neon)
	elseif entry.Accessory == "snowflake" then
		accessory = newPart("Snowflake", Vector3.new(2, 0.3, 2), Vector3.new(0, 5, 0), entry.AccentColor, Enum.Material.Glass)
	elseif entry.Accessory == "briefcase" then
		accessory = newPart("Briefcase", Vector3.new(1.6, 1.1, 0.7), Vector3.new(1.8, 1.4, 0), entry.AccentColor)
	end
	if accessory ~= nil then
		accessory.Parent = model
	end

	-- Weld every part to the root so the whole character moves as one.
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			part.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = root
		end
	end

	-- Floating name tag: name, rarity colour, dollars per second.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.fromOffset(180, 64)
	billboard.StudsOffset = Vector3.new(0, 5.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = Catalog.DisplayName(entry, mutationName)
	nameLabel.TextColor3 = (Catalog.GetRarity(entry.Rarity) or Catalog.Rarities[1]).Color
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = FormatUtil.FormatRate(entry.Rate * mutation.Multiplier)
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	rateLabel.TextSize = 16
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.Parent = billboard

	model:SetAttribute("BrainrotId", entry.Id)
	model:SetAttribute("Mutation", mutationName)
	return model
end

-- Carrying: the character rides above the player's head, welded on.
function WorldBuilder.AttachToPlayer(model, player)
	local character = player.Character
	if character == nil then
		return false
	end
	local head = character:FindFirstChild("Head")
	local root = model.PrimaryPart
	if head == nil or root == nil then
		return false
	end
	root.CFrame = head.CFrame * CFrame.new(0, 3.2, 0)
	root.Anchored = false
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = root
	weld.Parent = root
	return true
end

function WorldBuilder.DetachFromPlayer(model)
	local root = model.PrimaryPart
	if root == nil then
		return
	end
	local weld = root:FindFirstChild("CarryWeld")
	if weld ~= nil then
		weld:Destroy()
	end
	root.Anchored = true
end

-- Places a carried brainrot onto one of the owner's base slots.
function WorldBuilder.PlaceOnSlot(model, baseIndex, slotIndex)
	WorldBuilder.DetachFromPlayer(model)
	local position = GameState.GetSlotPosition(baseIndex, slotIndex)
	local root = model.PrimaryPart
	if root ~= nil then
		root.CFrame = CFrame.new(position)
		root.Anchored = true
	end
end

return WorldBuilder
