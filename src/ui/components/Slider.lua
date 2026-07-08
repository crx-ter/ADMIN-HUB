local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Throttle = require(script.Parent.Parent.Parent.core.throttle)

local Slider = {}
Slider.__index = Slider

function Slider.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local min = props.Min or 0
    local max = props.Max or 100
    local val = props.Default or min
    local step = props.Step or 1

    local self = setmetatable({
        _onChange = props.OnChange or function() end,
        _value = val,
        _min = min,
        _max = max,
        _step = step,
        _destroyed = false,
        _dragging = false,
    }, Slider)

    local width = props.Width or 280
    local height = 40

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Slider",
        Size = UDim2.new(0, width, 0, height),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 13 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    local trackY = 24
    self._track = InstanceUtils.New("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, trackY),
        BackgroundColor3 = Color3.fromRGB(45, 55, 72),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    local trackCorner = InstanceUtils.MakeCorner(3)
    trackCorner.Parent = self._track

    self._fill = InstanceUtils.New("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme:GetColor("Primary"),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = self._track,
    })
    local fillCorner = InstanceUtils.MakeCorner(3)
    fillCorner.Parent = self._fill

    self._knob = InstanceUtils.New("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.fromOffset(0, -6),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = self._track,
    })
    local knobCorner = InstanceUtils.MakeCorner(9)
    knobCorner.Parent = self._knob

    self._valueText = InstanceUtils.New("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 50, 0, 16),
        Position = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(val),
        TextColor3 = theme:GetColor("TextSecondary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self._frame,
    })

    self._updatePosition = Throttle:FrameRate(function(inputPos)
        if self._destroyed then return end
        local trackPos = self._track.AbsolutePosition
        local trackSize = self._track.AbsoluteSize.X
        local relativeX = math.clamp(inputPos.X - trackPos.X, 0, trackSize)
        local normalized = relativeX / trackSize
        local rawValue = self._min + (self._max - self._min) * normalized
        local steppedValue = math.floor(rawValue / self._step + 0.5) * self._step
        local clampedValue = math.clamp(steppedValue, self._min, self._max)
        self._value = clampedValue
        self:_updateVisuals()
        if self._onChange then
            self._onChange(self._value)
        end
    end)

    self._track.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = true
            self._updatePosition(input.Position)
        end
    end)

    self._inputConnection = game:GetService("UserInputService").InputChanged:Connect(function(input)
        if self._destroyed or not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            self._updatePosition(input.Position)
        end
    end)

    self._endConnection = game:GetService("UserInputService").InputEnded:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
        end
    end)

    self:_updateVisuals()

    return self
end

function Slider:_updateVisuals()
    local normalized = (self._value - self._min) / (self._max - self._min)
    local trackWidth = self._track.AbsoluteSize.X
    local knobX = normalized * trackWidth

    self._fill.Size = UDim2.fromScale(normalized, 1)
    TweenKit.new(self._knob, {Position = UDim2.fromOffset(knobX - 9, -6)}, 0.1, "OutQuad")

    if self._valueText then
        local display = self._value
        if self._value == math.floor(self._value) then
            self._valueText.Text = tostring(math.floor(self._value))
        else
            self._valueText.Text = string.format("%.1f", self._value)
        end
    end
end

function Slider:GetValue()
    return self._value
end

function Slider:SetValue(val)
    val = math.clamp(val, self._min, self._max)
    if val ~= self._value then
        self._value = val
        self:_updateVisuals()
        if self._onChange then
            self._onChange(self._value)
        end
    end
end

function Slider:Destroy()
    self._destroyed = true
    if self._inputConnection then self._inputConnection:Disconnect() end
    if self._endConnection then self._endConnection:Disconnect() end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._track = nil
    self._fill = nil
    self._knob = nil
    self._valueText = nil
end

return Slider