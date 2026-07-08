local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Theme = require(script.Parent.Parent.Parent.core.theme)

local Responsive = {}

local SMALL_PHONE = 400
local PHONE = 600
local TABLET = 900

local UserInputService = game:GetService("UserInputService")

function Responsive.GetDeviceType(screenSize)
	if screenSize < SMALL_PHONE then
		return "SmallPhone"
	elseif screenSize < PHONE then
		return "Phone"
	elseif screenSize < TABLET then
		return "Tablet"
	else
		return "Phablet"
	end
end

function Responsive.IsLandscape()
	return UserInputService.KeyboardEnabled and UserInputService.TouchEnabled
		and game:GetService("GuiService"):GetScreenResolution().X > game:GetService("GuiService"):GetScreenResolution().Y
		or false
end

function Responsive.GetScale()
	local theme = Theme.GetGlobal()
	local viewport = game:GetService("GuiService"):GetScreenResolution()
	local minDim = math.min(viewport.X, viewport.Y)
	local deviceType = Responsive.GetDeviceType(minDim)
	local baseScale = theme.Scale or 1.0

	local deviceScale
	if deviceType == "SmallPhone" then
		deviceScale = 0.85
	elseif deviceType == "Phone" then
		deviceScale = 1.0
	elseif deviceType == "Tablet" then
		deviceScale = 1.15
	else
		deviceScale = 1.25
	end

	if Responsive.IsLandscape() then
		deviceScale = deviceScale * 0.9
	end

	local scale = InstanceUtils.New("UIScale", {
		Scale = baseScale * deviceScale,
	})
	return scale
end

function Responsive.GetSafeAreaInsets()
	local top = 0
	local bottom = 0
	local success, result = pcall(function()
		local guiService = game:GetService("GuiService")
		if guiService:GetScreenResolution().Y > 0 then
			local insets = guiService:GetGuiInsets()
			top = insets.Top
			bottom = insets.Bottom
		end
	end)
	if not success then
		top = 0
		bottom = 0
	end
	return top, bottom
end

function Responsive.GetSizeClass(screenSize)
	if screenSize < SMALL_PHONE then
		return "Compact"
	elseif screenSize < PHONE then
		return "Regular"
	else
		return "Regular"
	end
end

Responsive.SMALL_PHONE = SMALL_PHONE
Responsive.PHONE = PHONE
Responsive.TABLET = TABLET

return Responsive