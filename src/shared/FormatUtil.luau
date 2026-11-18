-- Brainrot Bay: small formatting helpers shared by server and client.
-- Money is always shown short ($12.4K) so HUD labels stay readable.

local FormatUtil = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function FormatUtil.FormatMoney(amount)
	amount = math.floor(amount + 0.5)
	local negative = amount < 0
	amount = math.abs(amount)
	local tier = 1
	while amount >= 1000 and tier < #SUFFIXES do
		amount /= 1000
		tier += 1
	end
	local text
	if tier == 1 then
		text = tostring(math.floor(amount))
	elseif amount >= 100 then
		text = string.format("%d%s", math.floor(amount + 0.5), SUFFIXES[tier])
	elseif amount >= 10 then
		text = string.format("%.1f%s", amount, SUFFIXES[tier])
	else
		text = string.format("%.2f%s", amount, SUFFIXES[tier])
	end
	if negative then
		return "-$" .. text
	end
	return "$" .. text
end

function FormatUtil.FormatRate(perSecond)
	return FormatUtil.FormatMoney(perSecond) .. "/s"
end

function FormatUtil.FormatCountdown(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%d:%02d", minutes, rest)
end

return FormatUtil
