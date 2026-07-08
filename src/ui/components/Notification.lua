local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Notification = {}
Notification.__index = Notification

local _stack = {}
local _MAX_VISIBLE = 4
local _notifHeight = 64
local _spacing = 8
local _container = nil

function Notification.SetContainer(container)
    _container = container
end

function Notification.Show(props)
    if not _container then return end

    local theme = Theme.GetGlobal()
    props = props or {}

    local typeColors = {
        Info = theme:GetColor("Primary"),
        Success = theme:GetColor("Success"),
        Warning = theme:GetColor("Warning"),
        Error = theme:GetColor("Error"),
    }
    local notifColor = typeColors[props.Type] or typeColors.Info

    if #_stack >= _MAX_VISIBLE then
        local oldest = table.remove(_stack, 1)
        if oldest and oldest._destroy then
            oldest:_destroy()
        end
    end

    local yOffset = #_stack * (_notifHeight + _spacing)

    local notif = Glass.new({
        Name = "Notification",
        Parent = _container,
        Size = UDim2.new(1, -16, 0, _notifHeight),
        Position = UDim2.new(0, 8, 0, -_notifHeight),
        AnchorPoint = Vector2.new(0, 0),
        CornerRadius = 12,
        Transparency = 0.25,
        Shadow = true,
        BorderGlow = true,
    })

    local accent = InstanceUtils.New("Frame", {
        Name = "Accent",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = notifColor,
        BorderSizePixel = 0,
        Parent = notif,
    })
    local accentCorner = InstanceUtils.MakeCorner(1.5)
    accentCorner.Parent = accent

    if props.Icon then
        local icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(14, 22),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = notifColor,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = notif,
        })
    end

    local title = InstanceUtils.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.fromOffset(props.Icon and 42 or 16, 10),
        BackgroundTransparency = 1,
        Text = props.Title or "Notification",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local desc = InstanceUtils.New("TextLabel", {
        Name = "Description",
        Size = UDim2.new(1, -80, 0, 16),
        Position = UDim2.fromOffset(props.Icon and 42 or 16, 30),
        BackgroundTransparency = 1,
        Text = props.Description or "",
        TextColor3 = theme:GetColor("TextSecondary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local closeBtn = InstanceUtils.New("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = notif,
    })

    local instance = {
        _frame = notif,
        _destroyed = false,
    }

    function instance:_destroy()
        if self._destroyed then return end
        self._destroyed = true
        local idx = nil
        for i, n in ipairs(_stack) do
            if n == self then
                idx = i
                break
            end
        end
        if idx then
            table.remove(_stack, idx)
        end
        TweenKit.new(self._frame, {
            Position = UDim2.new(0, 8, 0, -_notifHeight),
            BackgroundTransparency = 1,
        }, 0.25, "InQuad")
        task.delay(0.3, function()
            if self._frame then
                self._frame:Destroy()
                self._frame = nil
            end
            Notification:_repositionAll()
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        instance:_destroy()
    end)

    table.insert(_stack, instance)

    notif.Position = UDim2.new(0, 8, 0, -_notifHeight)

    TweenKit.new(notif, {
        Position = UDim2.new(0, 8, 0, 8 + yOffset),
    }, 0.35, "OutBack")

    local duration = props.Duration or 4
    task.delay(duration, function()
        instance:_destroy()
    end)

    return instance
end

function Notification:_repositionAll()
    for i, notif in ipairs(_stack) do
        if notif._frame and not notif._destroyed then
            local targetY = 8 + (i - 1) * (_notifHeight + _spacing)
            TweenKit.new(notif._frame, {
                Position = UDim2.new(0, 8, 0, targetY),
            }, 0.25, "OutQuad")
        end
    end
end

function Notification.ClearAll()
    for i = #_stack, 1, -1 do
        local notif = _stack[i]
        if notif._destroy then
            notif:_destroy()
        end
    end
    _stack = {}
end

return Notification