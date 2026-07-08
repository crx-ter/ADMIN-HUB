local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Button = {}
Button.__index = Button

function Button.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _onClick = props.OnClick or function() end,
        _enabled = props.Enabled ~= false,
        _destroyed = false,
    }, Button)

    local size = props.Size or UDim2.new(0, 200, 0, 48)
    local pos = props.Position or UDim2.fromOffset(0, 0)

    self._frame = Glass.new({
        Name = props.Name or "Button",
        Parent = parent,
        Size = size,
        Position = pos,
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = props.CornerRadius or 10,
        Transparency = 0.35,
        Shadow = true,
        BorderGlow = props.Variant == "Primary" and true or false,
        Gradient = props.Variant == "Primary" and {
            Color1 = theme:GetColor("Primary"),
            Color2 = theme:GetColor("Secondary"),
            Alpha = 0.2,
        } or nil,
    })

    if props.Icon then
        self._icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(16, 14),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self._frame,
        })
    end

    self._label = InstanceUtils.New("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.fromOffset(props.Icon and 44 or 16, 0),
        BackgroundTransparency = 1,
        Text = props.Text or "Button",
        TextColor3 = props.Variant == "Primary" and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextPrimary"),
        TextSize = 15 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        Parent = self._frame,
    })

    if props.Description then
        self._desc = InstanceUtils.New("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -32, 0, 16),
            Position = UDim2.new(0, props.Icon and 44 or 16, 0, 26),
            BackgroundTransparency = 1,
            Text = props.Description,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 11 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._ripple = InstanceUtils.New("Frame", {
        Name = "Ripple",
        Size = UDim2.fromScale(0, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self._frame,
    })
    local rippleCorner = InstanceUtils.MakeCorner(100)
    rippleCorner.Parent = self._ripple

    self._connection = self._frame.InputBegan:Connect(function(input)
        if not self._enabled or self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_onPress()
        end
    end)

    self._endConnection = self._frame.InputEnded:Connect(function(input)
        if not self._enabled or self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_onRelease()
        end
    end)

    return self
end

function Button:_onPress()
    TweenKit.new(self._frame, {BackgroundTransparency = 0.5}, 0.1, "InQuad")
    TweenKit.new(self._frame, {Size = self._frame.Size - UDim2.fromOffset(2, 2)}, 0.1, "InQuad")
    self:_showRipple()
end

function Button:_onRelease()
    TweenKit.new(self._frame, {BackgroundTransparency = 0.35}, 0.2, "OutQuad")
    TweenKit.new(self._frame, {Size = self._frame.Size + UDim2.fromOffset(2, 2)}, 0.2, "OutBack")
    if self._onClick then
        self._onClick()
    end
end

function Button:_showRipple()
    if not self._ripple then return end
    self._ripple.Visible = true
    self._ripple.Size = UDim2.fromScale(0, 0)
    self._ripple.BackgroundTransparency = 0.8
    TweenKit.new(self._ripple, {Size = UDim2.fromScale(2, 2), BackgroundTransparency = 1}, 0.4, "OutQuad")
    task.delay(0.5, function()
        if self._ripple then
            self._ripple.Visible = false
        end
    end)
end

function Button:SetText(text)
    if self._label then
        self._label.Text = text
    end
end

function Button:SetEnabled(enabled)
    self._enabled = enabled
    if self._label then
        self._label.TextTransparency = enabled and 0 or 0.5
    end
end

function Button:SetOnClick(callback)
    self._onClick = callback
end

function Button:Destroy()
    self._destroyed = true
    if self._connection then self._connection:Disconnect() end
    if self._endConnection then self._endConnection:Disconnect() end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._label = nil
    self._icon = nil
    self._ripple = nil
end

return Button