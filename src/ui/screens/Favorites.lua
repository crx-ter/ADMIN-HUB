local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)

local Favorites = {}
Favorites.__index = Favorites

function Favorites.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_favorites = props.Favorites or {},
		_onToggleFavorite = props.OnToggleFavorite or function() end,
		_onExecute = props.OnExecute or function() end,
		_onClearAll = props.OnClearAll or function() end,
		_commandItems = {},
	}, Favorites)

	self._frame = InstanceUtils.New("Frame", {
		Name = "FavoritesScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self._header = InstanceUtils.New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, -24, 0, 44),
		Position = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = self._frame,
	})

	local title = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Text = "Favorites",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 22 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._header,
	})

	local clearBtn = Glass.new({
		Name = "ClearAll",
		Parent = self._header,
		Size = UDim2.new(0, 70, 0, 28),
		Position = UDim2.new(1, -70, 0, 8),
		CornerRadius = 14,
		Transparency = 0.5,
	})
	local clearText = InstanceUtils.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "Clear All",
		TextColor3 = theme:GetColor("Error"),
		TextSize = 12,
		Font = Enum.Font.GothamSemibold,
		Parent = clearBtn,
	})
	clearBtn.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._onClearAll()
		end
	end)

	self._listFrame = InstanceUtils.New("ScrollingFrame", {
		Name = "FavList",
		Size = UDim2.new(1, -24, 1, -68),
		Position = UDim2.fromOffset(12, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = self._frame,
	})

	self._listContainer = InstanceUtils.New("Frame", {
		Name = "ListContainer",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = self._listFrame,
	})

	self._emptyState = InstanceUtils.New("Frame", {
		Name = "EmptyState",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = #self._favorites == 0,
		Parent = self._listFrame,
	})

	local emptyIcon = InstanceUtils.New("TextLabel", {
		Name = "EmptyIcon",
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.fromScale(0.5, 0.35),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "☆",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 40,
		Font = Enum.Font.GothamBold,
		Parent = self._emptyState,
	})

	local emptyText = InstanceUtils.New("TextLabel", {
		Name = "EmptyText",
		Size = UDim2.new(1, -40, 0, 24),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "No favorites yet",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		Parent = self._emptyState,
	})

	local emptySubtext = InstanceUtils.New("TextLabel", {
		Name = "EmptySubtext",
		Size = UDim2.new(1, -40, 0, 18),
		Position = UDim2.fromScale(0.5, 0.58),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "Tap the star on any command to add it here",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 12 * theme.Scale,
		Font = Enum.Font.Gotham,
		Parent = self._emptyState,
	})

	self._emptyState.Size = UDim2.new(1, 0, 1, 0)

	self:_rebuildList()

	return self
end

function Favorites:_rebuildList()
	for _, child in ipairs(self._listContainer:GetChildren()) do
		child:Destroy()
	end
	self._commandItems = {}

	if #self._favorites == 0 then
		self._emptyState.Visible = true
		self._listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	self._emptyState.Visible = false

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cmd in ipairs(self._favorites) do
		local card = Glass.new({
			Name = "Fav_" .. cmd.Name,
			Parent = self._listContainer,
			Size = UDim2.new(1, 0, 0, 64),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 12,
			Transparency = 0.35,
			Shadow = true,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.fromOffset(10, 18),
			BackgroundTransparency = 1,
			Text = cmd.Icon or "C",
			TextColor3 = theme:GetColor("Warning"),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local nameLabel = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(1, -100, 0, 20),
			Position = UDim2.fromOffset(46, 12),
			BackgroundTransparency = 1,
			Text = cmd.Name or "Command",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 15 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local descLabel = InstanceUtils.New("TextLabel", {
			Name = "Description",
			Size = UDim2.new(1, -100, 0, 16),
			Position = UDim2.fromOffset(46, 34),
			BackgroundTransparency = 1,
			Text = cmd.Description or "No description",
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local starBtn = InstanceUtils.New("TextButton", {
			Name = "Star",
			Size = UDim2.new(0, 32, 0, 32),
			Position = UDim2.new(1, -40, 0, 16),
			BackgroundTransparency = 1,
			Text = "★",
			TextColor3 = theme:GetColor("Warning"),
			TextSize = 20,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local cmdName = cmd.Name
		starBtn.MouseButton1Click:Connect(function()
			if self._destroyed then return end
			self._onToggleFavorite(cmdName, false)
		end})

		card.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self._onExecute(cmd.Name)
			end
		end)

		table.insert(self._commandItems, {Frame = card, Data = cmd})
		yOffset = yOffset + 70
	end

	self._listContainer.Size = UDim2.new(1, 0, 0, yOffset)
	self._listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function Favorites:SetFavorites(favorites)
	self._favorites = favorites or {}
	self:_rebuildList()
end

function Favorites:GetFrame()
	return self._frame
end

function Favorites:Destroy()
	self._destroyed = true
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._commandItems = {}
end

return Favorites