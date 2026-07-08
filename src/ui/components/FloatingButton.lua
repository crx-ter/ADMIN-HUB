local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)
local Observer = require(script.Parent.Parent.Parent.core.observer)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local FloatingButton = {}
FloatingButton.__index = FloatingButton

function FloatingButton.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _parent = parent,
        _onOpen = props.OnOpen or function() end,
        _onClose = props.OnClose or function() end,
        _visible = true,
        _dragging = false,
        _dragStart = nil,
        _frameStart = nil,
        _destroyed = false,
        _open = false,
        _size = 56,
        _padding = 8,
        _animating = false,
    }, FloatingButton)

    local inset = parent:FindFirstChildOfClass("Frame") and Vector2.new(0, 0) or Vector2.new(0, 0)
    local screenSize = parent.AbsoluteSize

    self._defaultPos = props.DefaultPosition or UDim2.new(1, -(self._size + self._padding), 1, -(self._size + self._padding + 80))

    self._frame = Glass.new({
        Name = "FloatingButton",
        Parent = parent,
        Size = UDim2.new(0, self._size, 0, self._size),
        Position = self._defaultPos,
        AnchorPoint = Vector2.new(0.5, 0.5),
        CornerRadius = self._size / 2,
        Transparency = 0.25,
        Shadow = true,
        BorderGlow = true,
    })

    self._pulse = InstanceUtils.New("Frame", {
        Name = "Pulse",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = theme:GetColor("Primary"),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    local pulseCorner = InstanceUtils.MakeCorner(self._size / 2)
    pulseCorner.Parent = self._pulse

    self._icon = InstanceUtils.New("TextLabel", {
        Name = "Icon",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "I",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        Parent = self._frame,
    })

    self._connectors = {}
    self:_connectEvents()
    self:_startPulseAnimation()

    self._frame.Visible = true
    return self
end

function FloatingButton:_connectEvents()
    local began = self._frame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = true
            self._dragStart = input.Position
            self._frameStart = UDim2.new(0, self._frame.AbsolutePosition.X, 0, self._frame.AbsolutePosition.Y)
            TweenKit.new(self._frame, {Size = UDim2.new(0, self._size - 4, 0, self._size - 4)}, 0.1, "OutQuad")
        end
    end)

    local changed = UserInputService.InputChanged:Connect(function(input)
        if self._destroyed or not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_onDrag(input.Position)
        end
    end)

    local ended = UserInputService.InputEnded:Connect(function(input)
        if self._destroyed or not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
            local delta = (input.Position - self._dragStart).Magnitude
            TweenKit.new(self._frame, {Size = UDim2.new(0, self._size, 0, self._size)}, 0.2, "OutBack")
            if delta < 15 then
                self:_onTap()
            else
                self:_onSnap()
            end
        end
    end)

    self._connectors = {began, changed, ended}
end

function FloatingButton:_onDrag(inputPos)
    if self._animating then return end

    local parentAbs = self._parent.AbsolutePosition
    local parentSize = self._parent.AbsoluteSize
    local halfSize = self._size / 2

    local x = math.clamp(inputPos.X - parentAbs.X - halfSize, self._padding, parentSize.X - self._size - self._padding)
    local y = math.clamp(inputPos.Y - parentAbs.Y - halfSize, self._padding + 40, parentSize.Y - self._size - self._padding)

    self._frame.Position = UDim2.fromOffset(x, y)
end

function FloatingButton:_onSnap()
    if self._animating then return end
    self._animating = true

    local parentSize = self._parent.AbsoluteSize
    local framePos = self._frame.AbsolutePosition
    local frameCenter = framePos + Vector2.new(self._size / 2, self._size / 2)
    local parentCenter = parentSize / 2

    local margins = {
        Left = frameCenter.X - 0,
        Right = parentSize.X - frameCenter.X,
        Top = frameCenter.Y - 0,
        Bottom = parentSize.Y - frameCenter.Y,
    }

    local minDist = math.min(margins.Left, margins.Right, margins.Top, margins.Bottom)
    local snapX, snapY

    if minDist == margins.Left then
        snapX = self._padding
    elseif minDist == margins.Right then
        snapX = parentSize.X - self._size - self._padding
    else
        snapX = framePos.X
    end

    local topMargins = {Left = margins.Left, Right = margins.Right}
    local minHoriz = math.min(topMargins.Left, topMargins.Right)

    if minDist == margins.Top then
        snapY = self._padding + 40
    elseif minDist == margins.Bottom then
        snapY = parentSize.Y - self._size - self._padding
    else
        snapY = framePos.Y
    end

    TweenKit.new(self._frame, {
        Position = UDim2.fromOffset(snapX, snapY),
    }, 0.3, "OutQuad")

    task.delay(0.3, function()
        self._animating = false
    end)
end

function FloatingButton:_onTap()
    if self._animating then return end
    self._animating = true

    if not self._open then
        self:Open()
    else
        self:Close()
    end
end

function FloatingButton:Open()
    if self._open or self._animating then return end
    self._open = true

    TweenKit.new(self._frame, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }, 0.2, "InQuad")

    task.delay(0.15, function()
        if not self._destroyed then
            self._frame.Visible = false
            self._animating = false
            self._onOpen()
        end
    end)
end

function FloatingButton:Close()
    if not self._open or self._animating then return end

    self._frame.Size = UDim2.new(0, 0, 0, 0)
    self._frame.BackgroundTransparency = 1
    self._frame.Visible = true

    task.delay(0.05, function()
        if self._destroyed then return end
        self._open = false
        self._animating = false

        TweenKit.new(self._frame, {
            Size = UDim2.new(0, self._size, 0, self._size),
            BackgroundTransparency = 0.25,
        }, 0.35, "OutBack")

        self._onClose()
    end)
end

function FloatingButton:_startPulseAnimation()
    if self._destroyed then return end

    local pulseRunning = true
    local cancelPulse = function()
        pulseRunning = false
    end

    spawn(function()
        while pulseRunning and not self._destroyed do
            task.wait(3)
            if not pulseRunning or self._destroyed then break end
            if self._pulse then
                TweenKit.new(self._pulse, {
                    Size = UDim2.fromScale(1.3, 1.3),
                    BackgroundTransparency = 0.95,
                }, 1.5, "OutQuad")
                task.wait(1.5)
                if not pulseRunning or not self._pulse then break end
                TweenKit.new(self._pulse, {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 0.85,
                }, 1.5, "OutQuad")
            end
        end
    end)

    self._cancelPulse = cancelPulse
end

function FloatingButton:SetPosition(pos)
    self._frame.Position = pos
end

function FloatingButton:GetPosition()
    return self._frame.Position
end

function FloatingButton:Destroy()
    self._destroyed = true
    if self._cancelPulse then self._cancelPulse() end
    for _, conn in ipairs(self._connectors) do
        if conn.Connected then conn:Disconnect() end
    end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._pulse = nil
    self._icon = nil
    self._connectors = {}
end

return FloatingButton