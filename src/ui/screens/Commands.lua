local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local SearchBar = require(script.Parent.Parent.Parent.components.SearchBar)

local Commands = {}
Commands.__index = Commands

local CategoriesModule = require(script.Parent.Parent.Parent.features.commands.Categories)

local CATEGORIES = {"All"}
local CATEGORY_ICONS = {["All"] = "Q"}
for _, cat in ipairs(CategoriesModule.GetAll()) do
    table.insert(CATEGORIES, cat.name)
    CATEGORY_ICONS[cat.name] = cat.icon
end

function Commands.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_commands = props.Commands or {},
		_allCommands = props.Commands or {},
		_activeCategory = "All",
		_searchQuery = "",
		_onToggleFavorite = props.OnToggleFavorite or function() end,
		_onExecute = props.OnExecute or function() end,
		_favorites = props.Favorites or {},
		_categoryChips = {},
		_commandItems = {},
	}, Commands)

	self._frame = InstanceUtils.New("Frame", {
		Name = "CommandsScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self._searchBar = SearchBar.new(self._frame, {
		Name = "CommandSearch",
		Size = UDim2.new(1, -24, 0, 40),
		Position = UDim2.fromOffset(12, 12),
		Placeholder = "Search commands...",
		OnSearch = function(query)
			self._searchQuery = query
			self:_filterCommands()
		end,
	})

	self._categoryRow = InstanceUtils.New("Frame", {
		Name = "CategoryRow",
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, 60),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self._frame,
	})

	self._categoryList = InstanceUtils.New("Frame", {
		Name = "CategoryList",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = self._categoryRow,
	})

	self:_buildCategoryChips()

	self._listFrame = InstanceUtils.New("ScrollingFrame", {
		Name = "CommandList",
		Size = UDim2.new(1, -24, 1, -112),
		Position = UDim2.fromOffset(12, 108),
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

	self._refreshIndicator = InstanceUtils.New("Frame", {
		Name = "RefreshIndicator",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, -60),
		BackgroundColor3 = theme:GetColor("Primary"),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Visible = false,
		Parent = self._frame,
	})
	local refreshCorner = InstanceUtils.MakeCorner(6)
	refreshCorner.Parent = self._refreshIndicator

	self:_rebuildList()

	return self
end

function Commands:_buildCategoryChips()
	local theme = Theme.GetGlobal()
	local xOffset = 12

	for i, category in ipairs(CATEGORIES) do
		local isActive = category == self._activeCategory

		local chip = Glass.new({
			Name = category .. "Chip",
			Parent = self._categoryList,
			Size = UDim2.new(0, 0, 0, 32),
			Position = UDim2.fromOffset(xOffset, 6),
			CornerRadius = 16,
			Transparency = isActive and 0.2 or 0.5,
			Gradient = isActive and {
				Color1 = theme:GetColor("Primary"),
				Color2 = theme:GetColor("Secondary"),
				Alpha = 0.25,
			} or nil,
			BorderGlow = isActive or false,
		})

		local chipLabel = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = category,
			TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextSecondary"),
			TextSize = 13 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			Parent = chip,
		})
		chipLabel.Size = UDim2.new(0, chipLabel.TextBounds.X + 24, 1, 0)
		chip.Size = UDim2.new(0, chipLabel.TextBounds.X + 32, 0, 32)

		local labelX = (chip.Size.X.Offset - chipLabel.TextBounds.X) / 2
		chipLabel.Position = UDim2.fromOffset(labelX, 0)

		local catIndex = i
		chip.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self._activeCategory = category
				self:_refreshCategoryChips()
				self:_filterCommands()
			end
		end)

		self._categoryChips[category] = chip
		xOffset = xOffset + chip.Size.X.Offset + 8
	end

	self._categoryList.Size = UDim2.new(0, xOffset + 12, 1, 0)
end

function Commands:_refreshCategoryChips()
	local theme = Theme.GetGlobal()
	for category, chip in pairs(self._categoryChips) do
		local isActive = category == self._activeCategory
		local label = chip:FindFirstChild("Label")
		if label then
			label.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextSecondary")
		end
		TweenKit.new(chip, {BackgroundTransparency = isActive and 0.2 or 0.5}, 0.2, "OutQuad")
	end
end

function Commands:_filterCommands()
	local query = self._searchQuery:lower()
	self._commands = {}

	for _, cmd in ipairs(self._allCommands) do
		local matchesCategory = self._activeCategory == "All" or cmd.Category == self._activeCategory
		local matchesSearch = #query == 0 or cmd.Name:lower():find(query, 1, true) or (cmd.Description or ""):lower():find(query, 1, true)
		if matchesCategory and matchesSearch then
			table.insert(self._commands, cmd)
		end
	end

	self:_rebuildList()
end

function Commands:_rebuildList()
	for _, child in ipairs(self._listContainer:GetChildren()) do
		child:Destroy()
	end

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cmd in ipairs(self._commands) do
		local isFavorited = self._favorites[cmd.Name] or false

		local card = Glass.new({
			Name = "Cmd_" .. cmd.Name,
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
			TextColor3 = theme:GetColor("Primary"),
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
			Text = isFavorited and "★" or "☆",
			TextColor3 = isFavorited and theme:GetColor("Warning") or theme:GetColor("TextMuted"),
			TextSize = 20,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local cmdName = cmd.Name
		starBtn.MouseButton1Click:Connect(function()
			if self._destroyed then return end
			local newFav = not self._favorites[cmdName]
			self._favorites[cmdName] = newFav
			starBtn.Text = newFav and "★" or "☆"
			starBtn.TextColor3 = newFav and theme:GetColor("Warning") or theme:GetColor("TextMuted")
			self._onToggleFavorite(cmdName, newFav)
		end)

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

function Commands:Refresh()
	self:_refreshCategoryChips()
	self:_filterCommands()
	TweenKit.new(self._refreshIndicator, {Size = UDim2.new(1, 0, 0, 3)}, 0.3, "OutQuad")
	task.delay(0.6, function()
		if self._refreshIndicator then
			TweenKit.new(self._refreshIndicator, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, "InQuad")
		end
	end)
end

function Commands:SetCommands(commands)
	self._allCommands = commands
	self:_filterCommands()
end

function Commands:SetFavorites(favorites)
	self._favorites = favorites or {}
	self:_rebuildList()
end

function Commands:GetFrame()
	return self._frame
end

function Commands:Destroy()
	self._destroyed = true
	if self._searchBar then self._searchBar:Destroy() end
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._commands = {}
	self._commandItems = {}
end

return Commands