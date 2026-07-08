local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Card = require(script.Parent.Parent.Parent.components.Card)
local Dialog = require(script.Parent.Parent.Parent.components.Dialog)

local Checkpoints = {}
Checkpoints.__index = Checkpoints

function Checkpoints.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_checkpoints = props.Checkpoints or {},
		_onSave = props.OnSave or function() end,
		_onTeleport = props.OnTeleport or function() end,
		_onUpdate = props.OnUpdate or function() end,
		_onDuplicate = props.OnDuplicate or function() end,
		_onRename = props.OnRename or function() end,
		_onDelete = props.OnDelete or function() end,
		_currentPosition = props.CurrentPosition or Vector3.new(0, 0, 0),
		_checkpointItems = {},
		_contextMenu = nil,
	}, Checkpoints)

	self._frame = InstanceUtils.New("Frame", {
		Name = "CheckpointsScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self._saveBtn = Glass.new({
		Name = "SaveButton",
		Parent = self._frame,
		Size = UDim2.new(1, -24, 0, 52),
		Position = UDim2.fromOffset(12, 12),
		CornerRadius = 14,
		Transparency = 0.25,
		BorderGlow = true,
		Gradient = {
			Color1 = theme:GetColor("Primary"),
			Color2 = theme:GetColor("Secondary"),
			Alpha = 0.2,
		},
	})

	local saveIcon = InstanceUtils.New("TextLabel", {
		Name = "Icon",
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.fromOffset(14, 15),
		BackgroundTransparency = 1,
		Text = "S",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = self._saveBtn,
	})

	local saveLabel = InstanceUtils.New("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.fromOffset(44, 0),
		BackgroundTransparency = 1,
		Text = "Save Current Position",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._saveBtn,
	})

	self._saveBtn.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._onSave()
		end
	end)

	self._listFrame = InstanceUtils.New("ScrollingFrame", {
		Name = "CheckpointList",
		Size = UDim2.new(1, -24, 1, -76),
		Position = UDim2.fromOffset(12, 72),
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
		BackgroundTransparency = 1,
		Visible = #self._checkpoints == 0,
		Parent = self._listFrame,
	})

	local emptyIcon = InstanceUtils.New("TextLabel", {
		Name = "EmptyIcon",
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.fromScale(0.5, 0.3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "📍",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 36,
		Font = Enum.Font.GothamBold,
		Parent = self._emptyState,
	})

	local emptyText = InstanceUtils.New("TextLabel", {
		Name = "EmptyText",
		Size = UDim2.new(1, -40, 0, 24),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "Save your first checkpoint",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		Parent = self._emptyState,
	})

	local emptySubtext = InstanceUtils.New("TextLabel", {
		Name = "EmptySubtext",
		Size = UDim2.new(1, -40, 0, 18),
		Position = UDim2.fromScale(0.5, 0.52),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "Tap the button above to save your current position",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 12 * theme.Scale,
		Font = Enum.Font.Gotham,
		Parent = self._emptyState,
	})

	self._emptyState.Size = UDim2.new(1, 0, 1, 0)

	self:_rebuildList()

	return self
end

function Checkpoints:SetCurrentPosition(pos)
	self._currentPosition = pos
	self:_updateDistances()
end

function Checkpoints:_updateDistances()
	local theme = Theme.GetGlobal()
	for i, item in ipairs(self._checkpointItems) do
		local dist = (item.Data.Position - self._currentPosition).Magnitude
		local distLabel = item.Frame:FindFirstChild("Distance", true)
		if distLabel then
			distLabel.Text = ("%.1f studs"):format(dist)
		end
	end
end

function Checkpoints:_rebuildList()
	for _, child in ipairs(self._listContainer:GetChildren()) do
		child:Destroy()
	end
	self._checkpointItems = {}

	if #self._checkpoints == 0 then
		self._emptyState.Visible = true
		self._listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	self._emptyState.Visible = false

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cp in ipairs(self._checkpoints) do
		local dist = (cp.Position - self._currentPosition).Magnitude

		local card = Glass.new({
			Name = "CP_" .. (cp.Name or "Checkpoint"),
			Parent = self._listContainer,
			Size = UDim2.new(1, 0, 0, 120),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 14,
			Transparency = 0.3,
			Shadow = true,
		})

		local nameLabel = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 10),
			BackgroundTransparency = 1,
			Text = cp.Name or "Checkpoint",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 16 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local timeLabel = InstanceUtils.New("TextLabel", {
			Name = "Time",
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 34),
			BackgroundTransparency = 1,
			Text = cp.Time or "Just now",
			TextColor3 = theme:GetColor("TextSecondary"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local coords = ("%.1f, %.1f, %.1f"):format(cp.Position.X, cp.Position.Y, cp.Position.Z)
		local coordLabel = InstanceUtils.New("TextLabel", {
			Name = "Coords",
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 52),
			BackgroundTransparency = 1,
			Text = coords,
			TextColor3 = theme:GetColor("Accent"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local distLabel = InstanceUtils.New("TextLabel", {
			Name = "Distance",
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 70),
			BackgroundTransparency = 1,
			Text = ("%.1f studs"):format(dist),
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local actionRow = InstanceUtils.New("Frame", {
			Name = "Actions",
			Size = UDim2.new(1, -24, 0, 30),
			Position = UDim2.fromOffset(12, 88),
			BackgroundTransparency = 1,
			Parent = card,
		})

		local actions = {
			{Name = "Teleport", Color = theme:GetColor("Primary"), Icon = "T"},
			{Name = "Update", Color = theme:GetColor("Secondary"), Icon = "U"},
			{Name = "More", Color = theme:GetColor("TextMuted"), Icon = "⋮"},
		}

		local btnWidth = (1 - 0.04) / 3

		for j, action in ipairs(actions) do
			local btn = Glass.new({
				Name = action.Name .. "Btn",
				Parent = actionRow,
				Size = UDim2.new(btnWidth, -4, 1, 0),
				Position = UDim2.new((j - 1) * (btnWidth + 0.02), 0, 0, 0),
				CornerRadius = 8,
				Transparency = 0.5,
			})

			local btnText = InstanceUtils.New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = action.Name,
				TextColor3 = action.Color,
				TextSize = 11 * theme.Scale,
				Font = Enum.Font.GothamSemibold,
				Parent = btn,
			})

			local cpIndex = i
			local cpData = cp
			btn.InputBegan:Connect(function(input)
				if self._destroyed then return end
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					if action.Name == "Teleport" then
						self._onTeleport(cpData)
					elseif action.Name == "Update" then
						self._onUpdate(cpData)
					elseif action.Name == "More" then
						self:_showContextMenu(cpData, input)
					end
				end
			end)
		end

		local longPress = false
		local pressTimer = nil
		card.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch then
				pressTimer = task.delay(0.5, function()
					longPress = true
					self:_showQuickActions(cp)
				end)
			end
		end)
		card.InputEnded:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch then
				if pressTimer then
					pressTimer:Cancel()
					pressTimer = nil
				end
				if not longPress then
					self._onTeleport(cp)
				end
				longPress = false
			end
		end})

		table.insert(self._checkpointItems, {Frame = card, Data = cp})
		yOffset = yOffset + 128
	end

	self._listContainer.Size = UDim2.new(1, 0, 0, yOffset)
	self._listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function Checkpoints:_showContextMenu(cp, input)
	if self._contextMenu then
		self._contextMenu:Destroy()
	end

	local theme = Theme.GetGlobal()
	local menuItems = {
		{Text = "Duplicate", Icon = "D", Callback = function()
			self._onDuplicate(cp)
		end},
		{Text = "Rename", Icon = "R", Callback = function()
			self._onRename(cp)
		end},
		{Text = "Delete", Icon = "X", Color = theme:GetColor("Error"), Callback = function()
			Dialog.Show(self._frame, {
				Title = "Delete Checkpoint",
				Message = "Are you sure you want to delete '" .. (cp.Name or "this checkpoint") .. "'?",
				Buttons = {
					{Text = "Cancel", Callback = function() end},
					{Text = "Delete", Primary = true, Callback = function()
						self._onDelete(cp)
					end},
				},
			})
		end},
	}

	local menuHeight = #menuItems * 44 + 8
	self._contextMenu = Glass.new({
		Name = "ContextMenu",
		Parent = self._frame,
		Size = UDim2.new(0, 180, 0, menuHeight),
		Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
		CornerRadius = 12,
		Transparency = 0.15,
		Shadow = true,
		ZIndex = 200,
	})

	local yOff = 4
	for _, item in ipairs(menuItems) do
		local itemFrame = InstanceUtils.New("Frame", {
			Name = item.Text,
			Size = UDim2.new(1, -16, 0, 40),
			Position = UDim2.fromOffset(8, yOff),
			BackgroundTransparency = 1,
			Parent = self._contextMenu,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.fromOffset(8, 10),
			BackgroundTransparency = 1,
			Text = item.Icon or "",
			TextColor3 = item.Color or theme:GetColor("TextPrimary"),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Parent = itemFrame,
		})

		local label = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(34, 0),
			BackgroundTransparency = 1,
			Text = item.Text,
			TextColor3 = item.Color or theme:GetColor("TextPrimary"),
			TextSize = 14 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = itemFrame,
		})

		itemFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				item.Callback()
				if self._contextMenu then
					self._contextMenu:Destroy()
					self._contextMenu = nil
				end
			end
		end)

		yOff = yOff + 44
	end
end

function Checkpoints:_showQuickActions(cp)
	Dialog.Show(self._frame, {
		Title = cp.Name or "Checkpoint",
		Message = ("Position: %.1f, %.1f, %.1f"):format(cp.Position.X, cp.Position.Y, cp.Position.Z),
		Buttons = {
			{Text = "Teleport", Primary = true, Callback = function()
				self._onTeleport(cp)
			end},
			{Text = "Cancel", Callback = function() end},
		},
	})
end

function Checkpoints:SetCheckpoints(checkpoints)
	self._checkpoints = checkpoints or {}
	self:_rebuildList()
end

function Checkpoints:GetFrame()
	return self._frame
end

function Checkpoints:Destroy()
	self._destroyed = true
	if self._contextMenu then
		self._contextMenu:Destroy()
		self._contextMenu = nil
	end
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._checkpointItems = {}
end

return Checkpoints