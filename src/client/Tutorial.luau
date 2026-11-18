-- Brainrot Bay: the tutorial. Four short steps that advance on what the
-- player actually does (buy, then place), so a new player is never
-- reading instructions for something they already did.

local Tutorial = {}

local STEPS = {
	{
		Title = "1. Visit the conveyor",
		Body = "Walk to the rainbow portal in the middle of the map. Brainrots walk the belt from west to east.",
	},
	{
		Title = "2. Buy a brainrot",
		Body = "Stand next to a brainrot and press E to buy it. Rarer ones cost more and earn more per second.",
	},
	{
		Title = "3. Run it home!",
		Body = "Carry your brainrot back to YOUR base (follow the green beacon). It places itself and starts earning.",
	},
	{
		Title = "4. Grow rich, stay safe",
		Body = "Fill all 6 slots, watch the tsunami timer, lock your base against thieves, and rebirth for a permanent boost!",
	},
}

local currentStep = 1
local panel = nil
local titleLabel = nil
local bodyLabel = nil
local finished = false

local function render()
	if panel == nil then
		return
	end
	if finished then
		panel.Visible = false
		return
	end
	panel.Visible = true
	local step = STEPS[currentStep]
	titleLabel.Text = step.Title
	bodyLabel.Text = step.Body
end

function Tutorial.AttachToPanel(panelFrame, title, body)
	panel = panelFrame
	titleLabel = title
	bodyLabel = body
	render()
end

function Tutorial.AdvanceTo(step)
	if finished then
		return
	end
	if step > currentStep and step <= #STEPS then
		currentStep = step
		render()
	end
end

-- The HUD calls this on every state snapshot: buying advances to step 3,
-- placing advances to step 4, and step 4 dismisses itself after a while.
function Tutorial.UpdateFromState(state)
	if finished then
		return
	end
	if state.HasPlaced then
		Tutorial.AdvanceTo(4)
		if not finished then
			finished = true
			task.delay(12, function()
				if panel ~= nil then
					panel.Visible = false
				end
			end)
		end
	elseif state.HasBought then
		Tutorial.AdvanceTo(3)
	end
end

function Tutorial.Toggle()
	if finished then
		return
	end
	if panel ~= nil then
		panel.Visible = not panel.Visible
	end
end

return Tutorial
