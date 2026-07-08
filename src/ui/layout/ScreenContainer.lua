local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Responsive = require(script.Parent.Responsive)

local ScreenContainer = {}

function ScreenContainer.new(parent, props)
	props = props or {}

	local topInset, bottomInset = Responsive.GetSafeAreaInsets()

	local frame = Glass.new({
		Name = props.Name or "ScreenContainer",
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		Transparency = 0,
		CornerRadius = 0,
	})

	local padding = InstanceUtils.New("UIPadding", {
		PaddingTop = UDim.new(0, topInset + 8),
		PaddingBottom = UDim.new(0, bottomInset + 8),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 0),
		Parent = frame,
	})

	return frame
end

return ScreenContainer