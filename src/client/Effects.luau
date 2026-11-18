-- Brainrot Bay: client-side juice. Toasts, the big centre banner, the
-- floating "+$120" gains and a little confetti burst for rebirths. All
-- cosmetic: nothing here touches money or state.

local TweenService = game:GetService("TweenService")

local Effects = {}

local toastArea = nil
local bannerFrame = nil
local bannerTitle = nil
local bannerSubtitle = nil
local toastCount = 0

local KIND_COLORS = {
	info = Color3.fromRGB(80, 160, 255),
	good = Color3.fromRGB(80, 220, 120),
	warn = Color3.fromRGB(255, 200, 60),
	bad = Color3.fromRGB(255, 90, 90),
	rebirth = Color3.fromRGB(200, 120, 255),
}

function Effects.AttachToastArea(area)
	toastArea = area
end

function Effects.AttachBanner(frame, title, subtitle)
	bannerFrame = frame
	bannerTitle = title
	bannerSubtitle = subtitle
end

function Effects.ShowToast(text, kind)
	if toastArea == nil then
		return
	end
	toastCount += 1
	if toastCount > 4 then
		local oldest = toastArea:FindFirstChildWhichIsA("TextLabel")
		if oldest ~= nil then
			oldest:Destroy()
			toastCount -= 1
		end
	end
	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.Size = UDim2.new(1, 0, 0, 30)
	toast.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	toast.BackgroundTransparency = 0.25
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.Text = text
	toast.TextSize = 17
	toast.Font = Enum.Font.SourceSansBold
	toast.TextTruncate = Enum.TextTruncate.AtEnd
	toast.Parent = toastArea
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	local stripe = Instance.new("Frame")
	stripe.Name = "Stripe"
	stripe.Size = UDim2.new(0, 5, 1, 0)
	stripe.BackgroundColor3 = KIND_COLORS[kind or "info"] or KIND_COLORS.info
	stripe.BorderSizePixel = 0
	stripe.Parent = toast

	task.delay(5, function()
		local fade = TweenService:Create(
			toast,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		fade:Play()
		fade.Completed:Wait()
		toast:Destroy()
		toastCount -= 1
	end)
end

function Effects.ShowBanner(title, subtitle, seconds)
	if bannerFrame == nil then
		return
	end
	bannerTitle.Text = title
	bannerSubtitle.Text = subtitle or ""
	bannerFrame.Visible = true
	bannerFrame.BackgroundTransparency = 0.15
	task.delay(seconds or 4, function()
		local fade = TweenService:Create(
			bannerFrame,
			TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		fade:Play()
		fade.Completed:Wait()
		bannerFrame.Visible = false
	end)
end

function Effects.ConfettiBurst(parent)
	local colors = {
		Color3.fromRGB(255, 90, 90),
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(90, 220, 120),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(200, 120, 255),
	}
	for i = 1, 24 do
		local piece = Instance.new("Frame")
		piece.Size = UDim2.fromOffset(10, 14)
		piece.Position = UDim2.new(0.5, math.random(-160, 160), 0.25, 0)
		piece.BackgroundColor3 = colors[(i % #colors) + 1]
		piece.BorderSizePixel = 0
		piece.Rotation = math.random(0, 360)
		piece.Parent = parent
		local fall = TweenService:Create(
			piece,
			TweenInfo.new(1.4 + math.random() * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = UDim2.new(0.5, math.random(-320, 320), 1, 0),
				Rotation = math.random(-720, 720),
			}
		)
		fall:Play()
		fall.Completed:Connect(function()
			piece:Destroy()
		end)
	end
end

return Effects
