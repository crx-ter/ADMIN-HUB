local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Section = {}
Section.__index = Section

function Section.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _collapsed = false,
        _destroyed = false,
    }, Section)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Section",
        Size = props.Size or UDim2.new(0, 280, 0, 40),
        Position = props.Position or UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = parent,
    })

    self._header = InstanceUtils.New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })

    local headerSize = 40

    if props.Icon then
        self._icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(0, 10),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = theme:GetColor("Primary"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self._header,
        })
    end

    self._title = InstanceUtils.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.fromOffset(props.Icon and 28 or 0, 10),
        BackgroundTransparency = 1,
        Text = props.Title or "Section",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 16 * theme.Scale,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._header,
    })

    if props.Count then
        self._count = InstanceUtils.New("Frame", {
            Name = "Count",
            Size = UDim2.new(0, 24, 0, 20),
            Position = UDim2.new(1, -32, 0, 10),
            BackgroundColor3 = theme:GetColor("Surface"),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = self._header,
        })
        local countCorner = InstanceUtils.MakeCorner(10)
        countCorner.Parent = self._count
        self._countText = InstanceUtils.New("TextLabel", {
            Name = "CountText",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = tostring(props.Count),
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 11 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            Parent = self._count,
        })
    end

    -- Separator
    local sep = InstanceUtils.New("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme:GetColor("Border"),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Parent = self._header,
    })

    self._content = InstanceUtils.New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })

    if props.Collapsible ~= false then
        self._header.InputBegan:Connect(function(input)
            if self._destroyed then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_toggle()
            end
        end)
    end

    return self
end

function Section:_toggle()
    self._collapsed = not self._collapsed
    if self._collapsed then
        local targetHeight = self._content.Size.Y.Offset
        TweenKit.new(self._content, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, "InQuad")
        self._frame.Size = UDim2.new(self._frame.Size.X.Scale, self._frame.Size.X.Offset, 0, 40)
    else
        local contentHeight = self:_calculateContentHeight()
        TweenKit.new(self._content, {Size = UDim2.new(1, 0, 0, contentHeight)}, 0.25, "OutQuad")
        self._frame.Size = UDim2.new(self._frame.Size.X.Scale, self._frame.Size.X.Offset, 0, 40 + contentHeight)
    end
end

function Section:_calculateContentHeight()
    local maxY = 0
    for _, child in ipairs(self._content:GetChildren()) do
        if child:IsA("GuiObject") then
            local bottom = child.Position.Y.Offset + child.Size.Y.Offset
            if bottom > maxY then
                maxY = bottom
            end
        end
    end
    return maxY
end

function Section:GetContent()
    return self._content
end

function Section:AddChild(child)
    child.Parent = self._content
    local contentHeight = self:_calculateContentHeight()
    self._content.Size = UDim2.new(1, 0, 0, contentHeight)
    self._frame.Size = UDim2.new(self._frame.Size.X.Scale, self._frame.Size.X.Offset, 0, 40 + contentHeight)
    return child
end

function Section:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._header = nil
    self._content = nil
    self._title = nil
    self._icon = nil
    self._count = nil
    self._countText = nil
end

return Section