local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local _activeMenu = nil

function ContextMenu.Show(parent, position, items)
    ContextMenu.Close()

    local theme = Theme.GetGlobal()
    local itemHeight = 40
    local totalHeight = #items * itemHeight

    local overlay = InstanceUtils.New("Frame", {
        Name = "ContextOverlay",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local screenSize = parent.AbsoluteSize
    local menuWidth = 200
    local xPos = math.min(position.X, screenSize.X - menuWidth - 8)
    local yPos = math.min(position.Y, screenSize.Y - totalHeight - 8)

    local menu = Glass.new({
        Name = "ContextMenu",
        Parent = overlay,
        Size = UDim2.new(0, menuWidth, 0, totalHeight),
        Position = UDim2.fromOffset(xPos, yPos),
        CornerRadius = 12,
        Transparency = 0.1,
        Shadow = true,
        BorderGlow = true,
    })

    menu.Size = UDim2.new(0, menuWidth, 0, 0)
    TweenKit.new(menu, {Size = UDim2.new(0, menuWidth, 0, totalHeight)}, 0.2, "OutBack")

    for i, item in ipairs(items) do
        local itemFrame = InstanceUtils.New("Frame", {
            Name = "Item_" .. i,
            Size = UDim2.new(1, 0, 0, itemHeight),
            Position = UDim2.new(0, 0, 0, (i - 1) * itemHeight),
            BackgroundTransparency = 1,
            Parent = menu,
        })

        if item.Icon then
            local icon = InstanceUtils.New("TextLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.fromOffset(12, 11),
                BackgroundTransparency = 1,
                Text = item.Icon,
                TextColor3 = item.Destructive and theme:GetColor("Error") or theme:GetColor("TextSecondary"),
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                Parent = itemFrame,
            })
        end

        local textLabel = InstanceUtils.New("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.fromOffset(item.Icon and 36 or 12, 0),
            BackgroundTransparency = 1,
            Text = item.Text or "",
            TextColor3 = item.Destructive and theme:GetColor("Error") or theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = itemFrame,
        })

        if i < #items then
            local sep = InstanceUtils.New("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.new(0, 12, 1, -1),
                BackgroundColor3 = theme:GetColor("Border"),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                Parent = itemFrame,
            })
        end

        itemFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                ContextMenu.Close()
                if item.Callback then
                    item.Callback()
                end
            end
        end)
    end

    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local absPos = Vector2.new(input.Position.X, input.Position.Y)
            local menuAbsPos = menu.AbsolutePosition
            local menuAbsSize = menu.AbsoluteSize
            local inMenu = absPos.X >= menuAbsPos.X and absPos.X <= menuAbsPos.X + menuAbsSize.X
                and absPos.Y >= menuAbsPos.Y and absPos.Y <= menuAbsPos.Y + menuAbsSize.Y
            if not inMenu then
                ContextMenu.Close()
            end
        end
    end)

    _activeMenu = overlay
    return overlay
end

function ContextMenu.Close()
    if _activeMenu then
        _activeMenu:Destroy()
        _activeMenu = nil
    end
end

return ContextMenu