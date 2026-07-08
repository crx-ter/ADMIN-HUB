local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Card = {}
Card.__index = Card

function Card.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _destroyed = false,
    }, Card)

    self._frame = Glass.new({
        Name = props.Name or "Card",
        Parent = parent,
        Size = props.Size or UDim2.new(0, 280, 0, 100),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = props.CornerRadius or 14,
        Transparency = props.Transparency or 0.3,
        Shadow = true,
        BorderGlow = props.Highlight or false,
    })

    if props.Header then
        self._header = InstanceUtils.New("TextLabel", {
            Name = "Header",
            Size = UDim2.new(1, -24, 0, 24),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Text = props.Header,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 16 * theme.Scale,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    if props.Subheader then
        self._subheader = InstanceUtils.New("TextLabel", {
            Name = "Subheader",
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.fromOffset(12, props.Header and 36 or 12),
            BackgroundTransparency = 1,
            Text = props.Subheader,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 13 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    if props.Content then
        local contentY = 12
        if props.Header then contentY = contentY + 24 end
        if props.Subheader then contentY = contentY + 20 end

        self._content = InstanceUtils.New("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.fromOffset(12, contentY),
            BackgroundTransparency = 1,
            Text = props.Content,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 12 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = self._frame,
        })
        self._content.Size = UDim2.new(1, -24, 0, self._content.TextBounds.Y + 4)
    end

    if props.Footer then
        local footerY = 12
        if props.Header then footerY = footerY + 24 end
        if props.Subheader then footerY = footerY + 20 end
        if self._content then footerY = footerY + self._content.Size.Y.Offset + 4 end

        self._footer = InstanceUtils.New("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, -24, 0, 32),
            Position = UDim2.fromOffset(12, footerY),
            BackgroundTransparency = 1,
            Parent = self._frame,
        })
    end

    return self
end

function Card:GetFrame()
    return self._frame
end

function Card:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._header = nil
    self._subheader = nil
    self._content = nil
    self._footer = nil
end

return Card