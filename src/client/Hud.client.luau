-- Brainrot Bay: the HUD. Everything the player reads lives here, and
-- nothing is drawn in the top-left corner, where Roblox's own menu
-- buttons sit. The server sends one snapshot a second; this script only
-- displays it and fires the three buttons' RemoteEvents.
--
-- Keys are bound with ContextActionService, never InputBegan with
-- gameProcessedEvent: Roblox's default camera scripts swallow the arrow
-- keys before an InputBegan handler ever sees them.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FormatUtil"))
local Tutorial = require(script.Parent:WaitForChild("Tutorial"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local stateUpdateEvent = ReplicatedStorage:WaitForChild("StateUpdate")
local notifyEvent = ReplicatedStorage:WaitForChild("Notify")
local rebirthEvent = ReplicatedStorage:WaitForChild("RebirthEvent")
local lockBaseEvent = ReplicatedStorage:WaitForChild("LockBaseEvent")
local sellEvent = ReplicatedStorage:WaitForChild("SellEvent")
local getStateFunction = ReplicatedStorage:WaitForChild("GetStateFunction")

local lastWavePhase = "calm"
local lastRebirths = 0

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = playerGui

local function makePanel(name, position, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Position = position
	panel.Size = size
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	return panel
end

local function makeLabel(parent, name, position, size, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.SourceSansBold
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

local function makeButton(parent, name, position, size, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.Text = text
	button.TextSize = 17
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

-- Top centre: the money bar. Cash big, income and multiplier under it.
local topBar = makePanel("TopBar", UDim2.new(0.5, -190, 0, 12), UDim2.new(0, 380, 0, 64))
local cashLabel = makeLabel(topBar, "CashLabel", UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 34), "$100", 30, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel(topBar, "IncomeLabel", UDim2.new(0, 0, 0, 38), UDim2.new(1, 0, 0, 22), "$0/s  |  Rebirth x1.0", 17, Color3.fromRGB(220, 220, 220))

-- Under the money bar: the tsunami countdown pill.
local wavePill = makePanel("WavePill", UDim2.new(0.5, -150, 0, 84), UDim2.new(0, 300, 0, 30))
local waveLabel = makeLabel(wavePill, "WaveLabel", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), "Tsunami in 2:00", 17, Color3.fromRGB(140, 200, 255))

-- Top right: the leaderboard.
local leaderboardPanel = makePanel("Leaderboard", UDim2.new(1, -230, 0, 12), UDim2.new(0, 218, 0, 158))
makeLabel(leaderboardPanel, "LeaderboardTitle", UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 0, 22), "RICHEST PLAYERS", 16, Color3.fromRGB(255, 210, 60))
local leaderboardRows = {}
for i = 1, 5 do
	leaderboardRows[i] = makeLabel(
		leaderboardPanel,
		"Row" .. i,
		UDim2.new(0, 10, 0, 28 + (i - 1) * 24),
		UDim2.new(1, -20, 0, 22),
		"",
		15,
		Color3.fromRGB(230, 230, 230)
	)
end

-- Bottom left: the collection — what this base earns, slot by slot.
local collectionPanel = makePanel("Collection", UDim2.new(0, 12, 1, -196), UDim2.new(0, 250, 0, 184))
local collectionTitle = makeLabel(collectionPanel, "CollectionTitle", UDim2.new(0, 10, 0, 6), UDim2.new(1, -20, 0, 22), "MY BASE  (0/6)", 16, Color3.fromRGB(255, 210, 60))
local collectionRows = {}
for i = 1, 6 do
	collectionRows[i] = makeLabel(
		collectionPanel,
		"Slot" .. i,
		UDim2.new(0, 10, 0, 28 + (i - 1) * 24),
		UDim2.new(1, -20, 0, 22),
		"",
		15,
		Color3.fromRGB(230, 230, 230)
	)
end

-- Bottom centre: the carrying banner, then the three action buttons.
local carryingLabel = makeLabel(gui, "CarryingLabel", UDim2.new(0.5, -250, 1, -118), UDim2.new(0, 500, 0, 26), "", 19, Color3.fromRGB(255, 210, 60))
local buttonBar = makePanel("ButtonBar", UDim2.new(0.5, -260, 1, -88), UDim2.new(0, 520, 0, 56))
local rebirthButton = makeButton(buttonBar, "RebirthButton", UDim2.new(0, 10, 0, 10), UDim2.new(0, 160, 0, 36), "Rebirth ($5,000)", Color3.fromRGB(160, 80, 220))
local lockButton = makeButton(buttonBar, "LockButton", UDim2.new(0, 180, 0, 10), UDim2.new(0, 160, 0, 36), "Lock Base (L)", Color3.fromRGB(60, 120, 220))
local sellButton = makeButton(buttonBar, "SellButton", UDim2.new(0, 350, 0, 10), UDim2.new(0, 160, 0, 36), "Sell Weakest", Color3.fromRGB(200, 120, 40))

-- Left centre: the tutorial card.
local tutorialPanel = makePanel("Tutorial", UDim2.new(0, 12, 0.5, -70), UDim2.new(0, 250, 0, 140))
local tutorialTitle = makeLabel(tutorialPanel, "TutorialTitle", UDim2.new(0, 10, 0, 8), UDim2.new(1, -20, 0, 24), "", 18, Color3.fromRGB(255, 210, 60))
local tutorialBody = makeLabel(tutorialPanel, "TutorialBody", UDim2.new(0, 10, 0, 36), UDim2.new(1, -20, 0, 96), "", 15, Color3.fromRGB(235, 235, 235))
tutorialBody.TextWrapped = true
tutorialBody.TextXAlignment = Enum.TextXAlignment.Left
tutorialBody.TextYAlignment = Enum.TextYAlignment.Top
Tutorial.AttachToPanel(tutorialPanel, tutorialTitle, tutorialBody)

-- Centre: toasts stack here, and the big banner flashes over everything.
local toastArea = Instance.new("Frame")
toastArea.Name = "ToastArea"
toastArea.Position = UDim2.new(0.5, -220, 0, 124)
toastArea.Size = UDim2.new(0, 440, 0, 140)
toastArea.BackgroundTransparency = 1
toastArea.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.FillDirection = Enum.FillDirection.Vertical
toastLayout.Padding = UDim.new(0, 4)
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Parent = toastArea
Effects.AttachToastArea(toastArea)

local bannerFrame = makePanel("Banner", UDim2.new(0.5, -300, 0.3, -40), UDim2.new(0, 600, 0, 80))
bannerFrame.Visible = false
local bannerTitle = makeLabel(bannerFrame, "BannerTitle", UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 38), "", 30, Color3.fromRGB(255, 255, 255))
local bannerSubtitle = makeLabel(bannerFrame, "BannerSubtitle", UDim2.new(0, 0, 0, 46), UDim2.new(1, 0, 0, 26), "", 18, Color3.fromRGB(220, 220, 220))
Effects.AttachBanner(bannerFrame, bannerTitle, bannerSubtitle)

local function updateFromState(state)
	if state == nil then
		return
	end
	cashLabel.Text = FormatUtil.FormatMoney(state.Cash)
	incomeLabel.Text = FormatUtil.FormatRate(state.IncomePerSecond)
		.. "  |  Rebirth x" .. string.format("%.1f", state.RebirthMultiplier)

	local wave = state.WaveState or { Phase = "calm", SecondsLeft = 0 }
	if wave.Phase == "warning" then
		waveLabel.Text = "TSUNAMI IN " .. wave.SecondsLeft .. "s — RUN HOME!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
		if lastWavePhase ~= "warning" then
			Effects.ShowBanner("TSUNAMI INCOMING!", "Get back to your base NOW!", 4)
		end
	elseif wave.Phase == "sweep" then
		waveLabel.Text = "TSUNAMI SWEEPING THE MAP!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
	else
		waveLabel.Text = "Tsunami in " .. FormatUtil.FormatCountdown(wave.SecondsLeft)
		waveLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
	end
	lastWavePhase = wave.Phase

	for i = 1, 5 do
		local row = state.Leaderboard ~= nil and state.Leaderboard[i] or nil
		if row ~= nil then
			leaderboardRows[i].Text = i .. ". " .. row.Name .. " — " .. FormatUtil.FormatMoney(row.Cash)
		else
			leaderboardRows[i].Text = ""
		end
	end

	collectionTitle.Text = "MY BASE  (" .. state.PlacedCount .. "/" .. state.SlotsTotal .. ")"
	for i = 1, 6 do
		local placed = state.Placed ~= nil and state.Placed[i] or nil
		if placed ~= nil then
			collectionRows[i].Text = placed.Name .. " — " .. FormatUtil.FormatRate(placed.Rate)
		else
			collectionRows[i].Text = "— empty slot —"
		end
	end

	if state.Carrying ~= nil then
		carryingLabel.Text = "Carrying: " .. state.Carrying .. " — follow the green beacon home!"
	else
		carryingLabel.Text = ""
	end

	rebirthButton.Text = "Rebirth (" .. FormatUtil.FormatMoney(state.RebirthCost) .. ")"
	if state.Cash >= state.RebirthCost then
		rebirthButton.BackgroundColor3 = Color3.fromRGB(160, 80, 220)
	else
		rebirthButton.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
	end
	if state.BaseLockLeft > 0 then
		lockButton.Text = "Locked (" .. math.ceil(state.BaseLockLeft) .. "s)"
	elseif state.BaseLockReadyIn > 0 then
		lockButton.Text = "Lock recharging (" .. math.ceil(state.BaseLockReadyIn) .. "s)"
	else
		lockButton.Text = "Lock Base (L)"
	end
	if state.BaseShieldLeft > 0 then
		waveLabel.Text = waveLabel.Text .. "  |  Shield " .. math.ceil(state.BaseShieldLeft) .. "s"
	end

	if state.Rebirths > lastRebirths then
		Effects.ShowBanner("REBIRTH #" .. state.Rebirths .. "!", "Income x" .. string.format("%.1f", state.RebirthMultiplier) .. " forever!", 4)
		Effects.ConfettiBurst(gui)
	end
	lastRebirths = state.Rebirths

	Tutorial.UpdateFromState(state)
end

stateUpdateEvent.OnClientEvent:Connect(updateFromState)

notifyEvent.OnClientEvent:Connect(function(payload)
	if payload == nil or payload.Text == nil then
		return
	end
	Effects.ShowToast(payload.Text, payload.Kind)
	if payload.Kind == "rebirth" then
		Effects.ConfettiBurst(gui)
	end
end)

rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	lockBaseEvent:FireServer()
end)
sellButton.MouseButton1Click:Connect(function()
	sellEvent:FireServer()
end)

-- Keyboard shortcuts, bound the way Roblox wants: ContextActionService
-- sees keys the default camera scripts would otherwise swallow.
local function onRebirthKey(_actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		rebirthEvent:FireServer()
	end
	return Enum.ContextActionResult.Pass
end
local function onLockKey(_actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		lockBaseEvent:FireServer()
	end
	return Enum.ContextActionResult.Pass
end
local function onTutorialKey(_actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		Tutorial.Toggle()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("BrainrotRebirth", onRebirthKey, false, Enum.KeyCode.R)
ContextActionService:BindAction("BrainrotLockBase", onLockKey, false, Enum.KeyCode.L)
ContextActionService:BindAction("BrainrotTutorial", onTutorialKey, false, Enum.KeyCode.T)

-- One full snapshot at once, instead of waiting for the first tick.
local ok, initialState = pcall(function()
	return getStateFunction:InvokeServer()
end)
if ok then
	updateFromState(initialState)
end
