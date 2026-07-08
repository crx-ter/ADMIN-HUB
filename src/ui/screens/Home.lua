local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Gradient = require(script.Parent.Parent.Parent.primitives.gradient)

local Home = {}
Home.__index = Home

local RunService = game:GetService("RunService")

function Home.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_fps = 0,
		_ping = 0,
		_connections = {},
		_favorites = {},
		_recentCommands = {},
		_loading = true,
	}, Home)

	self._frame = InstanceUtils.New("ScrollingFrame", {
		Name = "HomeScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = parent,
	})

	local container = InstanceUtils.New("Frame", {
		Name = "Container",
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Parent = self._frame,
	})

	self._avatarFrame = Glass.new({
		Name = "Avatar",
		Parent = container,
		Size = UDim2.new(0, 80, 0, 80),
		Position = UDim2.fromOffset(0, 16),
		CornerRadius = 40,
		Transparency = 0.2,
		BorderGlow = true,
		Gradient = {
			Color1 = theme:GetColor("Primary"),
			Color2 = theme:GetColor("Secondary"),
			Alpha = 0.3,
		},
	})

	local avatarFill = InstanceUtils.New("Frame", {
		Name = "AvatarFill",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = theme:GetColor("SurfaceLight"),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = self._avatarFrame,
	})
	local avatarFillCorner = InstanceUtils.MakeCorner(38)
	avatarFillCorner.Parent = avatarFill

	local avatarIcon = InstanceUtils.New("TextLabel", {
		Name = "Icon",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "U",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 32,
		Font = Enum.Font.GothamBold,
		Parent = avatarFill,
	})

	self._playerName = InstanceUtils.New("TextLabel", {
		Name = "PlayerName",
		Size = UDim2.new(1, -96, 0, 28),
		Position = UDim2.fromOffset(96, 20),
		BackgroundTransparency = 1,
		Text = "Player",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 22 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	self._displayName = InstanceUtils.New("TextLabel", {
		Name = "DisplayName",
		Size = UDim2.new(1, -96, 0, 18),
		Position = UDim2.fromOffset(96, 48),
		BackgroundTransparency = 1,
		Text = "@player",
		TextColor3 = theme:GetColor("TextSecondary"),
		TextSize = 14 * theme.Scale,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	self._statsRow = InstanceUtils.New("Frame", {
		Name = "StatsRow",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 112),
		BackgroundTransparency = 1,
		Parent = container,
	})

	self._statChips = {}
	local statData = {
		{Name = "FPS", Icon = "F", Value = "0"},
		{Name = "Ping", Icon = "P", Value = "0ms"},
		{Name = "Clock", Icon = "T", Value = "00:00"},
	}
	local chipWidth = (1 - 0.04) / 3

	for i, data in ipairs(statData) do
		local chip = Glass.new({
			Name = data.Name .. "Chip",
			Parent = self._statsRow,
			Size = UDim2.new(chipWidth, -4, 0, 42),
			Position = UDim2.new((i - 1) * (chipWidth + 0.02), 0, 0, 4),
			CornerRadius = 10,
			Transparency = 0.35,
		})

		local chipIcon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.fromOffset(8, 12),
			BackgroundTransparency = 1,
			Text = data.Icon,
			TextColor3 = theme:GetColor("Primary"),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Parent = chip,
		})

		local chipValue = InstanceUtils.New("TextLabel", {
			Name = "Value",
			Size = UDim2.new(1, -30, 0, 18),
			Position = UDim2.fromOffset(28, 6),
			BackgroundTransparency = 1,
			Text = data.Value,
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 16 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		local chipLabel = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -30, 0, 14),
			Position = UDim2.fromOffset(28, 24),
			BackgroundTransparency = 1,
			Text = data.Name,
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		self._statChips[data.Name] = {Frame = chip, Value = chipValue}
	end

	self._quickActions = InstanceUtils.New("Frame", {
		Name = "QuickActions",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 170),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local qaTitle = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = "Quick Actions",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._quickActions,
	})

	local qaGrid = InstanceUtils.New("Frame", {
		Name = "Grid",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 28),
		BackgroundTransparency = 1,
		Parent = self._quickActions,
	})

	local qaButtons = {
		{Name = "Rejoin", Icon = "R", Color = theme:GetColor("Primary")},
		{Name = "Server Hop", Icon = "S", Color = theme:GetColor("Secondary")},
		{Name = "Reset Char", Icon = "X", Color = theme:GetColor("Warning")},
		{Name = "Anti-AFK", Icon = "A", Color = theme:GetColor("Accent")},
	}

	local gridWidth = (1 - 0.04) / 2
	self._qaFrames = {}

	for i, data in ipairs(qaButtons) do
		local row = math.floor((i - 1) / 2)
		local col = (i - 1) % 2

		local btn = Glass.new({
			Name = data.Name,
			Parent = qaGrid,
			Size = UDim2.new(gridWidth, -4, 0, 56),
			Position = UDim2.new(col * (gridWidth + 0.04), 0, row * 64, 0),
			CornerRadius = 12,
			Transparency = 0.35,
			Gradient = {
				Color1 = data.Color,
				Color2 = data.Color,
				Alpha = 0.1,
			},
		})

		local btnIcon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.fromOffset(10, 8),
			BackgroundTransparency = 1,
			Text = data.Icon,
			TextColor3 = data.Color,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Parent = btn,
		})

		local btnLabel = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -16, 0, 16),
			Position = UDim2.fromOffset(8, 32),
			BackgroundTransparency = 1,
			Text = data.Name,
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 12 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		table.insert(self._qaFrames, btn)
	end

	qaGrid.Size = UDim2.new(1, 0, 0, 128)

	self._favoritesSection = InstanceUtils.New("Frame", {
		Name = "FavoritesSection",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 170 + 128 + 16),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local favHeader = InstanceUtils.New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = self._favoritesSection,
	})

	local favTitle = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "Favorites",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = favHeader,
	})

	local seeAllBtn = Glass.new({
		Name = "SeeAll",
		Parent = favHeader,
		Size = UDim2.new(0, 60, 0, 24),
		Position = UDim2.new(1, -60, 0, 3),
		CornerRadius = 12,
		Transparency = 0.6,
	})
	local seeAllText = InstanceUtils.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "See All",
		TextColor3 = theme:GetColor("TextSecondary"),
		TextSize = 11,
		Font = Enum.Font.GothamSemibold,
		Parent = seeAllBtn,
	})

	self._favScroll = InstanceUtils.New("Frame", {
		Name = "FavScroll",
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self._favoritesSection,
	})

	self._favList = InstanceUtils.New("Frame", {
		Name = "FavList",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = self._favScroll,
	})

	self._favoritesSection.Size = UDim2.new(1, 0, 0, 86)

	self._recentSection = InstanceUtils.New("Frame", {
		Name = "RecentSection",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, self._favoritesSection.Position.Y.Offset + 86 + 8),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local recentHeader = InstanceUtils.New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = self._recentSection,
	})

	local recentTitle = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "Recent",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = recentHeader,
	})

	self._recentList = InstanceUtils.New("Frame", {
		Name = "RecentList",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		Parent = self._recentSection,
	})

	self._recentSection.Size = UDim2.new(1, 0, 0, 40)

	self._shimmer = InstanceUtils.New("Frame", {
		Name = "Shimmer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = true,
		Parent = container,
		ZIndex = 100,
	})

	local shimmerGrad = Gradient.new({
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 24, 39)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(31, 41, 55)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(17, 24, 39)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(31, 41, 55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 24, 39)),
		}),
		Rotation = 45,
		Parent = self._shimmer,
	})
	self._shimmerGrad = shimmerGrad

	self._shimmerConn = RunService.RenderStepped:Connect(function(dt)
		if self._shimmer and self._shimmerGrad and self._shimmer.Visible then
			local offset = self._shimmerGrad.Offset
			self._shimmerGrad.Offset = Vector2.new(offset.X - dt * 0.3, offset.Y)
		end
	end)

	task.delay(2, function()
		if self._destroyed then return end
		self._loading = false
		if self._shimmer then
			TweenKit.new(self._shimmer, {BackgroundTransparency = 1}, 0.4, "OutQuad")
			task.delay(0.5, function()
				if self._shimmer then self._shimmer.Visible = false end
			end)
		end
	end)

	self:_startStats()
	self:_updateCanvas()

	return self
end

function Home:_startStats()
	local stats = game:GetService("Stats")
	local perfStats = stats.PerformanceStats

	self._connections[#self._connections + 1] = RunService.RenderStepped:Connect(function()
		if self._destroyed then return end
		self._fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
		if self._statChips["FPS"] then
			self._statChips["FPS"].Value.Text = tostring(self._fps)
		end
	end)

	self._connections[#self._connections + 1] = game:GetService("Players").LocalPlayer:GetNetworkPing():Connect(function()
		return
	end)

	spawn(function()
		while not self._destroyed do
			local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
			if self._statChips["Ping"] then
				self._statChips["Ping"].Value.Text = tostring(ping) .. "ms"
			end
			wait(1)
		end
	end)

	spawn(function()
		while not self._destroyed do
			local timeStr = os.date("%I:%M")
			if self._statChips["Clock"] then
				self._statChips["Clock"].Value.Text = timeStr
			end
			wait(30)
		end
	end)
end

function Home:SetRecentCommands(commands)
	self._recentCommands = commands or {}
	self:_rebuildRecent()
end

function Home:SetFavorites(favorites)
	self._favorites = favorites or {}
	self:_rebuildFavorites()
end

function Home:_rebuildFavorites()
	for _, child in ipairs(self._favList:GetChildren()) do
		child:Destroy()
	end

	local theme = Theme.GetGlobal()
	local xOffset = 0

	for i, fav in ipairs(self._favorites) do
		local chip = Glass.new({
			Name = "FavChip",
			Parent = self._favList,
			Size = UDim2.new(0, 80, 0, 36),
			Position = UDim2.fromOffset(xOffset, 6),
			CornerRadius = 18,
			Transparency = 0.4,
		})
		local chipText = InstanceUtils.New("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = fav.Name or "Item",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 12 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			Parent = chip,
		})
		xOffset = xOffset + 88
	end

	self._favList.Size = UDim2.new(0, xOffset, 1, 0)
end

function Home:_rebuildRecent()
	for _, child in ipairs(self._recentList:GetChildren()) do
		child:Destroy()
	end

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cmd in ipairs(self._recentCommands) do
		if i > 5 then break end

		local chip = Glass.new({
			Name = "RecentChip_" .. i,
			Parent = self._recentList,
			Size = UDim2.new(1, 0, 0, 34),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 8,
			Transparency = 0.4,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.fromOffset(8, 8),
			BackgroundTransparency = 1,
			Text = cmd.Icon or "C",
			TextColor3 = theme:GetColor("Primary"),
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Parent = chip,
		})

		local name = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(0, 100, 1, 0),
			Position = UDim2.fromOffset(30, 0),
			BackgroundTransparency = 1,
			Text = cmd.Name or "command",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 13 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		local time = InstanceUtils.New("TextLabel", {
			Name = "Time",
			Size = UDim2.new(0, 50, 1, 0),
			Position = UDim2.new(1, -54, 0, 0),
			BackgroundTransparency = 1,
			Text = cmd.Time or "now",
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.Gotham,
			Parent = chip,
		})

		yOffset = yOffset + 38
	end

	self._recentList.Size = UDim2.new(1, 0, 0, yOffset)
	self._recentSection.Size = UDim2.new(1, 0, 0, 34 + yOffset)
	self:_updateCanvas()
end

function Home:_updateCanvas()
	local children = self._frame:FindFirstChild("Container")
	if not children then return end
	local container = children
	local maxY = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			local bottom = child.Position.Y.Offset + child.Size.Y.Offset
			if bottom > maxY then
				maxY = bottom
			end
		end
	end
	self._frame.CanvasSize = UDim2.new(0, 0, 0, maxY + 80)
end

function Home:GetFrame()
	return self._frame
end

function Home:Destroy()
	self._destroyed = true
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
	if self._shimmerConn then
		self._shimmerConn:Disconnect()
		self._shimmerConn = nil
	end
	if self._frame then self._frame:Destroy() end
	self._frame = nil
end

return Home