local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local UserInputService = game:GetService("UserInputService")

    local defaultKey = props.Default or Enum.KeyCode.F2
    local listening = false

    local self = setmetatable({
        _onChanged = props.OnChanged or function() end,
        _key = defaultKey,
        _listening = false,
        _destroyed = false,
    }, Keybind)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Keybind",
        Size = props.Size or UDim2.new(0, 280, 0, 44),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = theme:GetColor("Surface"),
        BorderSizePixel = 0,
        Parent = parent,
    })
    local frameCorner = InstanceUtils.MakeCorner(10)
    frameCorner.Parent = self._frame

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._keyDisplay = Glass.new({
        Name = "KeyDisplay",
        Parent = self._frame,
        Size = UDim2.new(0, 60, 0, 32),
        Position = UDim2.new(1, -70, 0, 6),
        CornerRadius = 8,
        Transparency = 0.5,
    })

    self._keyText = InstanceUtils.New("TextLabel", {
        Name = "KeyText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = self._key.Name or "F2",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        Parent = self._keyDisplay,
    })

    self._frame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_startListening()
        end
    end)

    return self
end

function Keybind:_startListening()
    if self._listening then return end
    self._listening = true
    self._keyText.Text = "..."
    self._keyText.TextColor3 = Theme.GetGlobal():GetColor("Primary")

    self._inputConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if self._destroyed then
            if self._inputConn then self._inputConn:Disconnect() end
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key ~= Enum.KeyCode.Unknown then
                self._key = key
                self._keyText.Text = key.Name
                self._keyText.TextColor3 = Theme.GetGlobal():GetColor("TextPrimary")
                self._listening = false
                self._onChanged(key)
                if self._inputConn then self._inputConn:Disconnect() end
            end
        end
    end)

    task.delay(5, function()
        if self._listening and not self._destroyed then
            self._listening = false
            self._keyText.Text = self._key.Name
            self._keyText.TextColor3 = Theme.GetGlobal():GetColor("TextPrimary")
            if self._inputConn then self._inputConn:Disconnect() end
        end
    end)
end

function Keybind:GetKey()
    return self._key
end

function Keybind:SetKey(key)
    self._key = key
    self._keyText.Text = key.Name
end

function Keybind:Destroy()
    self._destroyed = true
    if self._inputConn then self._inputConn:Disconnect() end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._keyDisplay = nil
    self._keyText = nil
    self._label = nil
end

return Keybind