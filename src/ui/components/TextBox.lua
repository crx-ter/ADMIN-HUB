local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local TextBox = {}
TextBox.__index = TextBox

function TextBox.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _onChanged = props.OnChanged or function() end,
        _onFocused = props.OnFocused or function() end,
        _onFocusLost = props.OnFocusLost or function() end,
        _destroyed = false,
        _focused = false,
    }, TextBox)

    self._frame = Glass.new({
        Name = props.Name or "TextBox",
        Parent = parent,
        Size = props.Size or UDim2.new(0, 280, 0, 44),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = 10,
        Transparency = 0.5,
    })

    self._icon = nil
    if props.Icon then
        self._icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = theme:GetColor("TextMuted"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self._frame,
        })
    end

    local iconOffset = props.Icon and 40 or 12

    self._placeholder = InstanceUtils.New("TextLabel", {
        Name = "Placeholder",
        Size = UDim2.new(1, -(iconOffset + 4), 1, 0),
        Position = UDim2.fromOffset(iconOffset, 0),
        BackgroundTransparency = 1,
        Text = props.Placeholder or "Type here...",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })

    self._input = InstanceUtils.New("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -(iconOffset + 4), 1, 0),
        Position = UDim2.fromOffset(iconOffset, 0),
        BackgroundTransparency = 1,
        Text = props.Text or "",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "",
        ClearTextOnFocus = false,
        Parent = self._frame,
    })

    if props.Password then
        self._input.PlaceholderText = "••••••••"
    end

    self._clearButton = nil
    if props.Clearable ~= false then
        self._clearButton = InstanceUtils.New("TextButton", {
            Name = "Clear",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -32, 0, 10),
            BackgroundTransparency = 1,
            Text = "X",
            TextColor3 = theme:GetColor("TextMuted"),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Visible = false,
            Parent = self._frame,
        })
        self._clearButton.MouseButton1Click:Connect(function()
            self._input.Text = ""
            self._onChanged("")
            self._clearButton.Visible = false
            self._placeholder.Visible = true
        end)
    end

    self._input.Focused:Connect(function()
        self._focused = true
        TweenKit.new(self._frame, {BackgroundTransparency = 0.25}, 0.2, "OutQuad")
        self._placeholder.Visible = false
        if self._clearButton then
            self._clearButton.Visible = #self._input.Text > 0
        end
        self._onFocused()
    end)

    self._input.FocusLost:Connect(function(enterPressed)
        self._focused = false
        TweenKit.new(self._frame, {BackgroundTransparency = 0.5}, 0.2, "OutQuad")
        if #self._input.Text == 0 then
            self._placeholder.Visible = true
        end
        if self._clearButton then
            self._clearButton.Visible = false
        end
        self._onFocusLost(self._input.Text, enterPressed)
    end)

    self._input:GetPropertyChangedSignal("Text"):Connect(function()
        if self._onChanged then
            self._onChanged(self._input.Text)
        end
        if self._clearButton then
            self._clearButton.Visible = self._focused and #self._input.Text > 0
        end
    end)

    return self
end

function TextBox:GetText()
    return self._input.Text
end

function TextBox:SetText(text)
    self._input.Text = text
    self._placeholder.Visible = #text == 0
end

function TextBox:Focus()
    self._input:CaptureFocus()
end

function TextBox:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._input = nil
    self._placeholder = nil
    self._clearButton = nil
    self._icon = nil
end

return TextBox