local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local isOn = props.Default or false

    local self = setmetatable({
        _onToggle = props.OnToggle or function() end,
        _value = isOn,
        _destroyed = false,
    }, Toggle)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Toggle",
        Size = UDim2.new(0, 50, 0, 28),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = isOn and theme:GetColor("Primary") or Color3.fromRGB(45, 55, 72),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    local corner = InstanceUtils.MakeCorner(14)
    corner.Parent = self._frame

    self._knob = InstanceUtils.New("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, isOn and 26 or 3, 0, 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    local knobCorner = InstanceUtils.MakeCorner(11)
    knobCorner.Parent = self._knob

    local knobStroke = InstanceUtils.New("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.85,
        Thickness = 0.5,
        Parent = self._knob,
    })

    self._label = nil
    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0, 0, 1, 0),
            Position = UDim2.new(0, 60, 0, 0),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame.Parent or parent,
        })
        self._label.Size = UDim2.new(0, self._label.TextBounds.X + 2, 1, 0)
    end

    self._frame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_toggle()
        end
    end)

    return self
end

function Toggle:_toggle()
    self._value = not self._value
    self:_animate()
    if self._onToggle then
        self._onToggle(self._value)
    end
end

function Toggle:_animate()
    local targetPos = self._value and 26 or 3
    local targetColor = self._value and Theme.GetGlobal():GetColor("Primary") or Color3.fromRGB(45, 55, 72)

    TweenKit.new(self._frame, {BackgroundColor3 = targetColor}, 0.2, "OutQuad")
    TweenKit.new(self._knob, {
        Position = UDim2.new(0, targetPos, 0, 3),
        Size = UDim2.new(0, 22, 0, 22),
    }, 0.25, "OutBack")
end

function Toggle:SetValue(val)
    if val ~= self._value then
        self._value = val
        self:_animate()
    end
end

function Toggle:GetValue()
    return self._value
end

function Toggle:SetOnToggle(callback)
    self._onToggle = callback
end

function Toggle:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    if self._label then self._label:Destroy() end
    self._frame = nil
    self._knob = nil
    self._label = nil
end

return Toggle