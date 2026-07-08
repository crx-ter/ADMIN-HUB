local InstanceUtils = {}

function InstanceUtils.New(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        if k ~= "Children" then
            inst[k] = v
        end
    end
    if props.Children then
        for _, child in ipairs(props.Children) do
            child.Parent = inst
        end
    end
    return inst
end

function InstanceUtils.Tag(inst, tag)
    if inst:FindFirstChild("Tags") then
        inst.Tags.Value = inst.Tags.Value .. "," .. tag
    end
end

function InstanceUtils.SafeDestroy(inst)
    if inst and inst.Parent then
        inst:Destroy()
    end
end

function InstanceUtils.ClearChildren(inst)
    for _, child in ipairs(inst:GetChildren()) do
        child:Destroy()
    end
end

function InstanceUtils.MakeScreenGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name or "IYMobileReborn"
    sg.DisplayOrder = 10
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    return sg
end

function InstanceUtils.MakeCorner(radius)
    return InstanceUtils.New("UICorner", {CornerRadius = UDim.new(0, radius)})
end

function InstanceUtils.MakePadding(padding)
    return InstanceUtils.New("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding)
    })
end

function InstanceUtils.MakeStroke(thickness, color, transparency)
    return InstanceUtils.New("UIStroke", {
        Thickness = thickness or 1,
        Color = color or Color3.fromRGB(255, 255, 255),
        Transparency = transparency or 0.8
    })
end

function InstanceUtils.MakeGradient(color1, color2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
    g.Rotation = rotation or 45
    return g
end

return InstanceUtils