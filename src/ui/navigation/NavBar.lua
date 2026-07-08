local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Button = require(script.Parent.Parent.Parent.components.Button)

local NavBar = {}
NavBar.__index = NavBar

local NAV_ITEMS = {
	{Name = "Home", Icon = "H", Label = "Home"},
	{Name = "Commands", Icon = "C", Label = "Commands"},
	{Name = "Favorites", Icon = "F", Label = "Favorites"},
	{Name = "Checkpoints", Icon = "P", Label = "Points"},
	{Name = "Settings", Icon = "S", Label = "Settings"},
}

function NavBar.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_activeIndex = props.DefaultIndex or 1,
		_onNavigate = props.OnNavigate or function() end,
		_destroyed = false,
		_items = {},
		_badges = {},
	}, NavBar)

	local barHeight = 64

	self._frame = Glass.new({
		Name = "NavBar",
		Parent = parent,
		Size = UDim2.new(1, 0, 0, barHeight),
		Position = UDim2.new(0, 0, 1, -barHeight),
		AnchorPoint = Vector2.new(0, 0),
		CornerRadius = 0,
		Transparency = 0.3,
		Shadow = true,
	})

	local topBorder = InstanceUtils.New("Frame", {
		Name = "TopBorder",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = theme:GetColor("Border"),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = self._frame,
	})

	self._indicator = InstanceUtils.New("Frame", {
		Name = "Indicator",
		Size = UDim2.new(0, 40, 0, 3),
		Position = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme:GetColor("Primary"),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = self._frame,
	})
	local indicatorCorner = InstanceUtils.MakeCorner(1.5)
	indicatorCorner.Parent = self._indicator

	local itemCount = #NAV_ITEMS
	local itemWidth = 1 / itemCount

	for i, itemData in ipairs(NAV_ITEMS) do
		local isActive = i == self._activeIndex

		local item = InstanceUtils.New("Frame", {
			Name = itemData.Name,
			Size = UDim2.new(itemWidth, 0, 1, 0),
			Position = UDim2.new((i - 1) * itemWidth, 0, 0, 8),
			BackgroundTransparency = 1,
			Parent = self._frame,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.fromScale(0.5, 0.15),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = itemData.Icon,
			TextColor3 = isActive and theme:GetColor("Primary") or theme:GetColor("TextMuted"),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Parent = item,
		})

		local label = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -4, 0, 16),
			Position = UDim2.fromScale(0.5, 0.55),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = itemData.Label,
			TextColor3 = isActive and theme:GetColor("TextPrimary") or theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.GothamSemibold,
			Parent = item,
		})

		local badge = nil
		local badgeText = nil
		if props.Badges and props.Badges[i] then
			badge = InstanceUtils.New("Frame", {
				Name = "Badge",
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.fromScale(0.65, 0.05),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = theme:GetColor("Error"),
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
				Parent = item,
			})
			local badgeCorner = InstanceUtils.MakeCorner(9)
			badgeCorner.Parent = badge

			badgeText = InstanceUtils.New("TextLabel", {
				Name = "BadgeText",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = tostring(props.Badges[i]),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				Parent = badge,
			})
		end

		self._items[i] = {
			Frame = item,
			Icon = icon,
			Label = label,
			Badge = badge,
			BadgeText = badgeText,
		}

		item.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:SetActive(i)
			end
		end)
	end

	self:_updateIndicator(false)

	return self
end

function NavBar:SetActive(index, animate)
	if self._destroyed then return end
	if index < 1 or index > #NAV_ITEMS then return end
	if animate == nil then animate = true end

	local oldIndex = self._activeIndex
	self._activeIndex = index

	local theme = Theme.GetGlobal()

	if oldIndex and self._items[oldIndex] then
		local old = self._items[oldIndex]
		old.Icon.TextColor3 = theme:GetColor("TextMuted")
		old.Label.TextColor3 = theme:GetColor("TextMuted")
	end

	local active = self._items[index]
	active.Icon.TextColor3 = theme:GetColor("Primary")
	active.Label.TextColor3 = theme:GetColor("TextPrimary")

	self:_updateIndicator(animate)
	self._onNavigate(NAV_ITEMS[index].Name, index)
end

function NavBar:_updateIndicator(animate)
	local itemCount = #NAV_ITEMS
	local itemWidth = self._frame.AbsoluteSize.X / itemCount
	local targetX = (self._activeIndex - 0.5) * itemWidth

	if animate then
		TweenKit.new(self._indicator, {Position = UDim2.fromOffset(targetX - 20, 0)}, 0.3, "OutBack")
	else
		self._indicator.Position = UDim2.fromOffset(targetX - 20, 0)
	end
end

function NavBar:GetActive()
	return self._activeIndex
end

function NavBar:SetBadge(index, count)
	if self._destroyed then return end
	if self._items[index] then
		local item = self._items[index]
		if count and count > 0 then
			if not item.Badge then
				local theme = Theme.GetGlobal()
				item.Badge = InstanceUtils.New("Frame", {
					Name = "Badge",
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.fromScale(0.65, 0.05),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = theme:GetColor("Error"),
					BackgroundTransparency = 0.1,
					BorderSizePixel = 0,
					Parent = item.Frame,
				})
				local badgeCorner = InstanceUtils.MakeCorner(9)
				badgeCorner.Parent = item.Badge

				item.BadgeText = InstanceUtils.New("TextLabel", {
					Name = "BadgeText",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = tostring(count),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 10,
					Font = Enum.Font.GothamBold,
					Parent = item.Badge,
				})
			else
				item.Badge.Visible = true
				item.BadgeText.Text = tostring(count)
			end
		elseif item.Badge then
			item.Badge.Visible = false
		end
	end
end

function NavBar:GetFrame()
	return self._frame
end

function NavBar:Destroy()
	self._destroyed = true
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._items = {}
end

return NavBar