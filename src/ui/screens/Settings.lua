local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Observer = require(script.Parent.Parent.Parent.core.observer)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Section = require(script.Parent.Parent.Parent.components.Section)
local ColorPicker = require(script.Parent.Parent.Parent.components.ColorPicker)
local Slider = require(script.Parent.Parent.Parent.components.Slider)
local Toggle = require(script.Parent.Parent.Parent.components.Toggle)
local Dialog = require(script.Parent.Parent.Parent.components.Dialog)

local Settings = {}
Settings.__index = Settings

local PRESETS = {
	Ocean = {
		Primary = Color3.fromRGB(6, 182, 212),
		Secondary = Color3.fromRGB(59, 130, 246),
		Name = "Ocean",
	},
	Purple = {
		Primary = Color3.fromRGB(139, 92, 246),
		Secondary = Color3.fromRGB(236, 72, 153),
		Name = "Purple",
	},
	Emerald = {
		Primary = Color3.fromRGB(16, 185, 129),
		Secondary = Color3.fromRGB(34, 197, 94),
		Name = "Emerald",
	},
	Rose = {
		Primary = Color3.fromRGB(239, 68, 68),
		Secondary = Color3.fromRGB(244, 63, 94),
		Name = "Rose",
	},
	Amber = {
		Primary = Color3.fromRGB(251, 191, 36),
		Secondary = Color3.fromRGB(245, 158, 11),
		Name = "Amber",
	},
}

function Settings.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()
	local settingsStore = props.Store or Observer.new({
		PrimaryColor = theme:GetColor("Primary"),
		SecondaryColor = theme:GetColor("Secondary"),
		Transparency = theme.PanelTransparency or 0.4,
		Blur = theme.BlurIntensity or 12,
		Scale = 1.0,
		ShowFPS = true,
		ShowPing = true,
		ShowClock = true,
		ShowFloatingButton = true,
		AnimationSpeed = theme.AnimationSpeed or 1.0,
	})

	local self = setmetatable({
		_destroyed = false,
		_store = settingsStore,
		_sections = {},
		_controls = {},
	}, Settings)

	self._frame = InstanceUtils.New("ScrollingFrame", {
		Name = "SettingsScreen",
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
		Size = UDim2.new(1, -24, 0, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Parent = self._frame,
	})

	local title = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 8),
		BackgroundTransparency = 1,
		Text = "Settings",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 22 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	self:_buildThemeSection(container)
	self:_buildAppearanceSection(container)
	self:_buildBehaviorSection(container)
	self:_buildAnimationSection(container)
	self:_buildPresetsSection(container)
	self:_buildDangerZone(container)

	self:_updateCanvas()

	return self
end

function Settings:_buildThemeSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "ThemeSection",
		Title = "THEME",
		Icon = "T",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = false,
	})

	local content = section:GetContent()

	self._controls.PrimaryColor = ColorPicker.new(content, {
		Name = "PrimaryColor",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 0),
		Label = "Primary Color",
		Default = theme:GetColor("Primary"),
		OnChange = function(color)
			self._store:Set("PrimaryColor", color)
			theme:SetPrimary(color)
		end,
	})

	self._controls.SecondaryColor = ColorPicker.new(content, {
		Name = "SecondaryColor",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 60),
		Label = "Secondary Color",
		Default = theme:GetColor("Secondary"),
		OnChange = function(color)
			self._store:Set("SecondaryColor", color)
			theme:SetSecondary(color)
		end,
	})

	section:AddChild(self._controls.PrimaryColor._frame)
	section:AddChild(self._controls.SecondaryColor._frame)

	table.insert(self._sections, section)
end

function Settings:_buildAppearanceSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "AppearanceSection",
		Title = "APPEARANCE",
		Icon = "A",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	self._controls.Transparency = Slider.new(content, {
		Name = "TransparencySlider",
		Width = 280,
		Label = "Panel Transparency",
		Min = 0.3,
		Max = 0.7,
		Step = 0.05,
		Default = theme.PanelTransparency or 0.4,
		OnChange = function(val)
			self._store:Set("Transparency", val)
			theme.PanelTransparency = val
		end,
	})

	self._controls.Blur = Slider.new(content, {
		Name = "BlurSlider",
		Width = 280,
		Label = "Blur Intensity",
		Min = 0,
		Max = 20,
		Step = 1,
		Default = theme.BlurIntensity or 12,
		OnChange = function(val)
			self._store:Set("Blur", val)
			theme.BlurIntensity = val
		end,
	})

	self._controls.Scale = Slider.new(content, {
		Name = "ScaleSlider",
		Width = 280,
		Label = "UI Scale",
		Min = 0.7,
		Max = 1.5,
		Step = 0.05,
		Default = 1.0,
		OnChange = function(val)
			self._store:Set("Scale", val)
			theme.Scale = val
		end,
	})

	section:AddChild(self._controls.Transparency._frame)
	section:AddChild(self._controls.Blur._frame)
	section:AddChild(self._controls.Scale._frame)

	table.insert(self._sections, section)
end

function Settings:_buildBehaviorSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "BehaviorSection",
		Title = "BEHAVIOR",
		Icon = "B",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()
	local toggleY = 0

	self._controls.ShowFPS = Toggle.new(content, {
		Name = "ShowFPS",
		Default = true,
		Label = "Show FPS",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowFPS", val)
		end,
	})
	toggleY = toggleY + 36

	self._controls.ShowPing = Toggle.new(content, {
		Name = "ShowPing",
		Default = true,
		Label = "Show Ping",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowPing", val)
		end,
	})
	toggleY = toggleY + 36

	self._controls.ShowClock = Toggle.new(content, {
		Name = "ShowClock",
		Default = true,
		Label = "Show Clock",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowClock", val)
		end,
	})
	toggleY = toggleY + 36

	self._controls.ShowFloatingButton = Toggle.new(content, {
		Name = "ShowFloatingButton",
		Default = true,
		Label = "Floating Button",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowFloatingButton", val)
		end,
	})

	section:AddChild(self._controls.ShowFPS._frame)
	section:AddChild(self._controls.ShowPing._frame)
	section:AddChild(self._controls.ShowClock._frame)
	section:AddChild(self._controls.ShowFloatingButton._frame)

	table.insert(self._sections, section)
end

function Settings:_buildAnimationSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "AnimationSection",
		Title = "ANIMATION",
		Icon = "N",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	self._controls.AnimationSpeed = Slider.new(content, {
		Name = "AnimSpeedSlider",
		Width = 280,
		Label = "Animation Speed",
		Min = 0.3,
		Max = 2.0,
		Step = 0.1,
		Default = theme.AnimationSpeed or 1.0,
		OnChange = function(val)
			self._store:Set("AnimationSpeed", val)
			theme.AnimationSpeed = val
		end,
	})

	section:AddChild(self._controls.AnimationSpeed._frame)

	table.insert(self._sections, section)
end

function Settings:_buildPresetsSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "PresetsSection",
		Title = "PRESETS",
		Icon = "P",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	local presetRow = InstanceUtils.New("Frame", {
		Name = "PresetRow",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = content,
	})

	local presetWidth = (1 - 0.04) / 3

	local idx = 0
	for _, presetData in pairs(PRESETS) do
		local row = math.floor(idx / 3)
		local col = idx % 3

		local btn = Glass.new({
			Name = presetData.Name .. "Preset",
			Parent = presetRow,
			Size = UDim2.new(presetWidth, -4, 0, 50),
			Position = UDim2.new(col * (presetWidth + 0.02), 0, row * 56, 4),
			CornerRadius = 10,
			Transparency = 0.4,
		})

		local colorSwatch = InstanceUtils.New("Frame", {
			Name = "Swatch",
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.fromScale(0.5, 0.25),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = presetData.Primary,
			BorderSizePixel = 0,
			Parent = btn,
		})
		local swatchCorner = InstanceUtils.MakeCorner(6)
		swatchCorner.Parent = colorSwatch

		local btnLabel = InstanceUtils.New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.fromScale(0.5, 0.6),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = presetData.Name,
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			Parent = btn,
		})

		local presetName = presetData.Name
		btn.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:_applyPreset(presetName)
			end
		end)

		idx = idx + 1
	end

	local presetRowHeight = math.ceil(idx / 3) * 56 + 8
	presetRow.Size = UDim2.new(1, 0, 0, presetRowHeight)

	section:AddChild(presetRow)

	table.insert(self._sections, section)
end

function Settings:_buildDangerZone(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "DangerZone",
		Title = "DANGER ZONE",
		Icon = "!",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	local resetBtn = Glass.new({
		Name = "ResetAll",
		Parent = content,
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 8),
		CornerRadius = 12,
		Transparency = 0.3,
		BorderGlow = true,
		Gradient = {
			Color1 = theme:GetColor("Error"),
			Color2 = theme:GetColor("Error"),
			Alpha = 0.15,
		},
	})

	local resetIcon = InstanceUtils.New("TextLabel", {
		Name = "Icon",
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.fromOffset(12, 14),
		BackgroundTransparency = 1,
		Text = "!",
		TextColor3 = theme:GetColor("Error"),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = resetBtn,
	})

	local resetLabel = InstanceUtils.New("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -48, 1, 0),
		Position = UDim2.fromOffset(40, 0),
		BackgroundTransparency = 1,
		Text = "Reset All Settings",
		TextColor3 = theme:GetColor("Error"),
		TextSize = 15 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = resetBtn,
	})

	resetBtn.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dialog.Show(self._frame, {
				Title = "Reset Settings",
				Message = "Are you sure you want to reset all settings to default? This cannot be undone.",
				Buttons = {
					{Text = "Cancel", Callback = function() end},
					{Text = "Reset", Primary = true, Callback = function()
						self:_resetAll()
					end},
				},
			})
		end
	end)

	section:AddChild(resetBtn)

	table.insert(self._sections, section)
end

function Settings:_applyPreset(name)
	local preset = PRESETS[name]
	if not preset then return end

	local theme = Theme.GetGlobal()
	theme:SetPrimary(preset.Primary)
	theme:SetSecondary(preset.Secondary)

	self._store:Set("PrimaryColor", preset.Primary)
	self._store:Set("SecondaryColor", preset.Secondary)

	if self._controls.PrimaryColor then
		self._controls.PrimaryColor:SetColor(preset.Primary)
	end
	if self._controls.SecondaryColor then
		self._controls.SecondaryColor:SetColor(preset.Secondary)
	end
end

function Settings:_resetAll()
	local theme = Theme.GetGlobal()
	local defaultTheme = Theme.new()

	theme:SetPrimary(defaultTheme:GetColor("Primary"))
	theme:SetSecondary(defaultTheme:GetColor("Secondary"))
	theme.PanelTransparency = 0.4
	theme.BlurIntensity = 12
	theme.Scale = 1.0
	theme.AnimationSpeed = 1.0

	self._store:BatchSet({
		PrimaryColor = defaultTheme:GetColor("Primary"),
		SecondaryColor = defaultTheme:GetColor("Secondary"),
		Transparency = 0.4,
		Blur = 12,
		Scale = 1.0,
		ShowFPS = true,
		ShowPing = true,
		ShowClock = true,
		ShowFloatingButton = true,
		AnimationSpeed = 1.0,
	})

	if self._controls.PrimaryColor then
		self._controls.PrimaryColor:SetColor(defaultTheme:GetColor("Primary"))
	end
	if self._controls.SecondaryColor then
		self._controls.SecondaryColor:SetColor(defaultTheme:GetColor("Secondary"))
	end
	if self._controls.Transparency then
		self._controls.Transparency:SetValue(0.4)
	end
	if self._controls.Blur then
		self._controls.Blur:SetValue(12)
	end
	if self._controls.Scale then
		self._controls.Scale:SetValue(1.0)
	end
	if self._controls.AnimationSpeed then
		self._controls.AnimationSpeed:SetValue(1.0)
	end
	if self._controls.ShowFPS then
		self._controls.ShowFPS:SetValue(true)
	end
	if self._controls.ShowPing then
		self._controls.ShowPing:SetValue(true)
	end
	if self._controls.ShowClock then
		self._controls.ShowClock:SetValue(true)
	end
	if self._controls.ShowFloatingButton then
		self._controls.ShowFloatingButton:SetValue(true)
	end
end

function Settings:_updateCanvas()
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
	self._frame.CanvasSize = UDim2.new(0, 0, 0, maxY + 40)
end

function Settings:GetStore()
	return self._store
end

function Settings:GetFrame()
	return self._frame
end

function Settings:Destroy()
	self._destroyed = true
	for _, section in ipairs(self._sections) do
		section:Destroy()
	end
	self._sections = {}
	for _, control in pairs(self._controls) do
		if control.Destroy then
			control:Destroy()
		end
	end
	self._controls = {}
	if self._frame then self._frame:Destroy() end
	self._frame = nil
end

return Settings