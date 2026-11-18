-- Brainrot Bay: one tiny wrapper around the Notify RemoteEvent so every
-- server system can toast the player without depending on the economy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Notify = {}

local notifyEvent = nil

local function getEvent()
	if notifyEvent == nil then
		notifyEvent = ReplicatedStorage:WaitForChild("Notify")
	end
	return notifyEvent
end

function Notify.Player(player, text, kind)
	getEvent():FireClient(player, { Text = text, Kind = kind or "info" })
end

function Notify.All(text, kind)
	getEvent():FireAllClients({ Text = text, Kind = kind or "info" })
end

return Notify
