local InstanceUtils = require(script.Parent.Parent.utils.instance)

local Gradient = {}

function Gradient.new(props)
    props = props or {}
    local grad = InstanceUtils.New("UIGradient", {
        Color = props.Color or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
        }),
        Rotation = props.Rotation or 45,
        Transparency = props.Transparency or NumberSequence.new(0),
        Offset = props.Offset or Vector2.new(0, 0),
        Parent = props.Parent,
    })
    return grad
end

function Gradient.Primary(parent)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(59, 130, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246)),
        }),
        Rotation = 45,
        Parent = parent,
    })
end

function Gradient.Secondary(parent)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212)),
        }),
        Rotation = 45,
        Parent = parent,
    })
end

function Gradient.Accent(parent)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 182, 212)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246)),
        }),
        Rotation = 45,
        Parent = parent,
    })
end

function Gradient.Text(parent, color1, color2)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1 or Color3.fromRGB(241, 245, 249)),
            ColorSequenceKeypoint.new(1, color2 or Color3.fromRGB(148, 163, 184)),
        }),
        Rotation = 0,
        Parent = parent,
    })
end

return Gradient