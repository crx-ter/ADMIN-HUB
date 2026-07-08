local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local defaultColor = props.Default or Color3.fromRGB(59, 130, 246)

    local self = setmetatable({
        _onChange = props.OnChange or function() end,
        _color = defaultColor,
        _open = false,
        _destroyed = false,
    }, ColorPicker)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "ColorPicker",
        Size = props.Size or UDim2.new(0, 280, 0, 50),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, -18),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 12 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._swatch = Glass.new({
        Name = "Swatch",
        Parent = self._frame,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.fromOffset(0, 0),
        CornerRadius = 10,
        Transparency = 0.2,
    })

    self._colorFill = InstanceUtils.New("Frame", {
        Name = "ColorFill",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = defaultColor,
        BorderSizePixel = 0,
        Parent = self._swatch,
    })
    local fillCorner = InstanceUtils.MakeCorner(8)
    fillCorner.Parent = self._colorFill

    self._hexLabel = InstanceUtils.New("TextLabel", {
        Name = "Hex",
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.fromOffset(52, 0),
        BackgroundTransparency = 1,
        Text = "#" .. self:_rgbToHex(defaultColor),
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })

    self._pickerContainer = InstanceUtils.New("Frame", {
        Name = "PickerContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        Parent = self._frame,
    })

    self._pickerPanel = Glass.new({
        Name = "PickerPanel",
        Parent = self._pickerContainer,
        Size = UDim2.new(1, 0, 0, 200),
        CornerRadius = 12,
        Transparency = 0.3,
        Shadow = true,
    })

    self:_buildHueBar()
    self:_buildSaturationBrightness()
    self:_buildPresets()

    self._swatch.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_toggle()
        end
    end)

    return self
end

function ColorPicker:_buildHueBar()
    local bar = InstanceUtils.New("Frame", {
        Name = "HueBar",
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = self._pickerPanel,
    })
    local barCorner = InstanceUtils.MakeCorner(8)
    barCorner.Parent = bar

    local hueGrad = InstanceUtils.New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = bar,
    })

    self._hueSlider = InstanceUtils.New("Frame", {
        Name = "HueSlider",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.fromOffset(0, -1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = bar,
    })
    local sliderCorner = InstanceUtils.MakeCorner(9)
    sliderCorner.Parent = self._hueSlider
end

function ColorPicker:_buildSaturationBrightness()
    local sb = InstanceUtils.New("Frame", {
        Name = "SatBright",
        Size = UDim2.new(1, -20, 0, 120),
        Position = UDim2.fromOffset(10, 34),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        Parent = self._pickerPanel,
    })
    local sbCorner = InstanceUtils.MakeCorner(8)
    sbCorner.Parent = sb

    local whiteGrad = InstanceUtils.New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Rotation = 90,
        Parent = sb,
    })

    local blackGrad = InstanceUtils.New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
        }),
        Parent = sb,
    })
end

function ColorPicker:_buildPresets()
    local presets = {
        Color3.fromRGB(59, 130, 246),
        Color3.fromRGB(139, 92, 246),
        Color3.fromRGB(6, 182, 212),
        Color3.fromRGB(34, 197, 94),
        Color3.fromRGB(251, 191, 36),
        Color3.fromRGB(239, 68, 68),
        Color3.fromRGB(236, 72, 153),
        Color3.fromRGB(255, 255, 255),
    }

    for i, color in ipairs(presets) do
        local swatch = InstanceUtils.New("Frame", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 10 + (i - 1) * 34, 0, 166),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = self._pickerPanel,
        })
        local swatchCorner = InstanceUtils.MakeCorner(6)
        swatchCorner.Parent = swatch

        swatch.InputBegan:Connect(function(input)
            if self._destroyed then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_setColor(color)
            end
        end)
    end
end

function ColorPicker:_rgbToHex(color)
    return string.format("%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

function ColorPicker:_setColor(color)
    self._color = color
    self._colorFill.BackgroundColor3 = color
    self._hexLabel.Text = "#" .. self:_rgbToHex(color)
    if self._onChange then
        self._onChange(color)
    end
end

function ColorPicker:_toggle()
    if self._open then
        self:_close()
    else
        self:_open()
    end
end

function ColorPicker:_open()
    self._open = true
    self._pickerContainer.Visible = true
    TweenKit.new(self._pickerContainer, {Size = UDim2.new(1, 0, 0, 200)}, 0.25, "OutQuad")
end

function ColorPicker:_close()
    self._open = false
    TweenKit.new(self._pickerContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, "InQuad")
    task.delay(0.2, function()
        if not self._open and self._pickerContainer then
            self._pickerContainer.Visible = false
        end
    end)
end

function ColorPicker:GetColor()
    return self._color
end

function ColorPicker:SetColor(color)
    self:_setColor(color)
end

function ColorPicker:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._swatch = nil
    self._colorFill = nil
    self._pickerContainer = nil
    self._pickerPanel = nil
end

return ColorPicker