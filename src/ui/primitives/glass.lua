local InstanceUtils = require(script.Parent.Parent.utils.instance)
local Theme = require(script.Parent.Parent.core.theme)

local Glass = {}

function Glass.new(props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local frame = InstanceUtils.New("Frame", {
        Name = props.Name or "GlassPanel",
        Size = props.Size or UDim2.fromScale(1, 1),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = theme:GetColor("Surface"),
        BackgroundTransparency = props.Transparency or theme.PanelTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = props.ClipsDescendants or false,
        Parent = props.Parent,
    })

    local corner = InstanceUtils.MakeCorner(props.CornerRadius or 12)
    corner.Parent = frame

    local stroke = InstanceUtils.New("UIStroke", {
        Color = theme:GetColor("Border"),
        Transparency = 0.7,
        Thickness = 1,
        Parent = frame,
    })

    if props.Gradient then
        local grad = InstanceUtils.New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, props.Gradient.Color1 or theme:GetColor("Primary")),
                ColorSequenceKeypoint.new(1, props.Gradient.Color2 or theme:GetColor("Secondary")),
            }),
            Rotation = props.Gradient.Rotation or 45,
            Transparency = NumberSequence.new(props.Gradient.Alpha or 0.15),
            Parent = frame,
        })
    end

    if props.Shadow then
        local shadow = InstanceUtils.New("ImageLabel", {
            Name = "DropShadow",
            Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(16, 16),
            Position = UDim2.fromOffset(-8, -8),
            BackgroundTransparency = 1,
            Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.6,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(8, 8, 8, 8),
            ZIndex = frame.ZIndex - 1,
            Parent = frame,
        })
    end

    if props.BorderGlow then
        local glow = InstanceUtils.New("Frame", {
            Name = "BorderGlow",
            Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(4, 4),
            Position = UDim2.fromOffset(-2, -2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = frame.ZIndex - 1,
            Parent = frame,
        })
        local glowCorner = InstanceUtils.MakeCorner(props.CornerRadius and props.CornerRadius + 2 or 14)
        glowCorner.Parent = glow
        local glowGrad = InstanceUtils.New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme:GetColor("Primary")),
                ColorSequenceKeypoint.new(0.5, theme:GetColor("Secondary")),
                ColorSequenceKeypoint.new(1, theme:GetColor("Accent")),
            }),
            Rotation = 45,
            Transparency = NumberSequence.new(0.85),
            Parent = glow,
        })
    end

    return frame
end

return Glass