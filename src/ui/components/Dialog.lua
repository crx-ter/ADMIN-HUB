local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Dialog = {}
Dialog.__index = Dialog

local _activeDialog = nil

function Dialog.Show(parent, props)
    if _activeDialog then
        _activeDialog:Destroy()
    end

    props = props or {}
    local theme = Theme.GetGlobal()
    local title = props.Title or "Dialog"
    local message = props.Message or ""
    local buttons = props.Buttons or {{Text = "OK", Primary = true}}
    local onClose = props.OnClose or function() end

    local overlay = InstanceUtils.New("Frame", {
        Name = "DialogOverlay",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = parent,
    })

    local dialog = Glass.new({
        Name = "Dialog",
        Parent = overlay,
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        CornerRadius = 16,
        Transparency = 0.15,
        Shadow = true,
        BorderGlow = true,
    })

    local titleLabel = InstanceUtils.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 28),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 18 * theme.Scale,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dialog,
    })

    local msgLabel = nil
    if message and #message > 0 then
        msgLabel = InstanceUtils.New("TextLabel", {
            Name = "Message",
            Size = UDim2.new(1, -32, 0, 40),
            Position = UDim2.fromOffset(16, 48),
            BackgroundTransparency = 1,
            Text = message,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = dialog,
        })

        local textHeight = msgLabel.TextBounds.Y
        msgLabel.Size = UDim2.new(1, -32, 0, math.max(40, textHeight + 8))
    end

    local contentY = (msgLabel and 48 + msgLabel.Size.Y.Offset) or 48
    local btnY = contentY + 16
    local btnCount = #buttons
    local btnWidth = math.min(120, (280 - (btnCount - 1) * 8) / btnCount)

    local btnContainer = InstanceUtils.New("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -16, 0, 40),
        Position = UDim2.new(0, 8, 0, btnY),
        BackgroundTransparency = 1,
        Parent = dialog,
    })

    for i, btn in ipairs(buttons) do
        local xPos = (i - 1) * (btnWidth + 8)
        local btnLabel = btn.Primary and "Button" or "Button"
        local frame = Glass.new({
            Name = "Btn_" .. (btn.Text or ""),
            Parent = btnContainer,
            Size = UDim2.new(0, btnWidth, 1, 0),
            Position = UDim2.fromOffset(xPos, 0),
            CornerRadius = 10,
            Transparency = btn.Primary and 0.2 or 0.4,
            Gradient = btn.Primary and {
                Color1 = theme:GetColor("Primary"),
                Color2 = theme:GetColor("Secondary"),
                Alpha = 0.3,
            } or nil,
            BorderGlow = btn.Primary or false,
        })

        local text = InstanceUtils.New("TextLabel", {
            Name = "Text",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = btn.Text or "Button",
            TextColor3 = btn.Primary and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            Parent = frame,
        })

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if btn.Callback then
                    btn.Callback()
                end
                self:Destroy()
            end
        end)
    end

    local totalHeight = btnY + 40 + 16
    dialog.Size = UDim2.new(0, 300, 0, totalHeight)

    dialog.Size = UDim2.new(0, 300, 0, 0)
    overlay.BackgroundTransparency = 1

    TweenKit.new(overlay, {BackgroundTransparency = 0.6}, 0.2, "OutQuad")
    TweenKit.new(dialog, {Size = UDim2.new(0, 300, 0, totalHeight)}, 0.3, "OutBack")

    _activeDialog = {
        Overlay = overlay,
        Dialog = dialog,
        OnClose = onClose,
        Destroy = function()
            if not overlay then return end
            TweenKit.new(overlay, {BackgroundTransparency = 1}, 0.15, "InQuad")
            TweenKit.new(dialog, {Size = UDim2.new(0, 300, 0, 0)}, 0.2, "InQuad")
            task.delay(0.25, function()
                if overlay then overlay:Destroy() end
            end)
            overlay = nil
            dialog = nil
            _activeDialog = nil
            onClose()
        end,
    }

    return _activeDialog
end

function Dialog.Close()
    if _activeDialog then
        _activeDialog:Destroy()
    end
end

return Dialog