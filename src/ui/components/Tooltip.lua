local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(parent, targetFrame, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local text = props.Text or ""

    local self = setmetatable({
        _visible = false,
        _destroyed = false,
    }, Tooltip)

    self._container = InstanceUtils.New("Frame", {
        Name = "TooltipContainer",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    self._tooltip = Glass.new({
        Name = "Tooltip",
        Parent = self._container,
        Size = UDim2.new(0, 0, 0, 28),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0.5, 1),
        CornerRadius = 8,
        Transparency = 0.1,
        Visible = false,
    })

    self._label = InstanceUtils.New("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self._tooltip,
    })

    targetFrame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            self:Show(input.Position)
        end
    end)

    targetFrame.InputEnded:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            self:Hide()
        end
    end)

    return self
end

function Tooltip:Show(position)
    if self._destroyed then return end
    self._visible = true

    local width = math.min(self._label.TextBounds.X + 24, 200)
    self._tooltip.Size = UDim2.new(0, width, 0, 28)

    if position then
        self._tooltip.Position = UDim2.fromOffset(position.X, position.Y - 8)
    end

    self._tooltip.Visible = true
    self._tooltip.BackgroundTransparency = 1
    TweenKit.new(self._tooltip, {BackgroundTransparency = 0.1}, 0.2, "OutQuad")
    self._tooltip.Size = UDim2.new(0, width, 0, 0)
    TweenKit.new(self._tooltip, {Size = UDim2.new(0, width, 0, 28)}, 0.2, "OutBack")
end

function Tooltip:Hide()
    if self._destroyed or not self._visible then return end
    self._visible = false
    TweenKit.new(self._tooltip, {BackgroundTransparency = 1}, 0.15, "InQuad")
    task.delay(0.15, function()
        if self._tooltip then
            self._tooltip.Visible = false
        end
    end)
end

function Tooltip:SetText(text)
    if self._label then
        self._label.Text = text
    end
end

function Tooltip:Destroy()
    self._destroyed = true
    if self._container then self._container:Destroy() end
    self._container = nil
    self._tooltip = nil
    self._label = nil
end

return Tooltip