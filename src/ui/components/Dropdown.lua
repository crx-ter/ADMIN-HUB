local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local items = props.Items or {}
    local selected = props.Default or (items[1] and items[1].Value) or nil

    local self = setmetatable({
        _onSelect = props.OnSelect or function() end,
        _items = items,
        _selected = selected,
        _open = false,
        _destroyed = false,
    }, Dropdown)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Dropdown",
        Size = props.Size or UDim2.new(0, 280, 0, 44),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, -18),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 12 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._header = Glass.new({
        Name = "Header",
        Parent = self._frame,
        Size = UDim2.new(1, 0, 0, 44),
        Position = UDim2.fromOffset(0, 0),
        CornerRadius = 10,
        Transparency = 0.5,
    })

    self._headerText = InstanceUtils.New("TextLabel", {
        Name = "Selected",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = self:_getDisplayText(selected),
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._header,
    })

    self._arrow = InstanceUtils.New("TextLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0, 12),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = self._header,
    })

    self._dropContainer = InstanceUtils.New("Frame", {
        Name = "DropContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        Parent = self._frame,
    })

    self._dropPanel = Glass.new({
        Name = "DropPanel",
        Parent = self._dropContainer,
        Size = UDim2.new(1, 0, 0, 0),
        CornerRadius = 10,
        Transparency = 0.3,
        Shadow = true,
    })

    self._itemButtons = {}
    self:_buildItems()

    self._header.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_toggle()
        end
    end)

    return self
end

function Dropdown:_getDisplayText(value)
    for _, item in ipairs(self._items) do
        if item.Value == value then
            return item.Text or tostring(value)
        end
    end
    return "Select..."
end

function Dropdown:_buildItems()
    for _, btn in ipairs(self._itemButtons) do
        if btn then btn:Destroy() end
    end
    self._itemButtons = {}

    local itemHeight = 40
    local totalHeight = #self._items * itemHeight

    self._dropPanel.Size = UDim2.new(1, 0, 0, totalHeight)

    for i, item in ipairs(self._items) do
        local itemFrame = InstanceUtils.New("Frame", {
            Name = "Item_" .. i,
            Size = UDim2.new(1, 0, 0, itemHeight),
            Position = UDim2.new(0, 0, 0, (i - 1) * itemHeight),
            BackgroundTransparency = 1,
            Parent = self._dropPanel,
        })

        local isSelected = item.Value == self._selected

        if isSelected then
            local sel = InstanceUtils.New("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = theme:GetColor("Primary"),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                Parent = itemFrame,
            })
            local selCorner = InstanceUtils.MakeCorner(0)
            selCorner.Parent = sel
        end

        local itemText = InstanceUtils.New("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = item.Text or tostring(item.Value),
            TextColor3 = isSelected and theme:GetColor("Primary") or theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = itemFrame,
        })

        if item.Description then
            itemText.Size = UDim2.new(1, -24, 0, 20)
            itemText.Position = UDim2.fromOffset(12, 4)
            local desc = InstanceUtils.New("TextLabel", {
                Name = "Desc",
                Size = UDim2.new(1, -24, 0, 14),
                Position = UDim2.fromOffset(12, 24),
                BackgroundTransparency = 1,
                Text = item.Description,
                TextColor3 = theme:GetColor("TextMuted"),
                TextSize = 11 * theme.Scale,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = itemFrame,
            })
        end

        if i < #self._items then
            local sep = InstanceUtils.New("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.new(0, 12, 1, 0),
                BackgroundColor3 = theme:GetColor("Border"),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                Parent = itemFrame,
            })
        end

        itemFrame.InputBegan:Connect(function(input)
            if self._destroyed then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self._selected = item.Value
                self._headerText.Text = item.Text or tostring(item.Value)
                self._onSelect(item.Value)
                self:_close()
            end
        end)

        table.insert(self._itemButtons, itemFrame)
    end
end

function Toggle:_toggle()
    if self._open then
        self:_close()
    else
        self:_open()
    end
end

function Dropdown:_open()
    self._open = true
    self._dropContainer.Visible = true
    self._arrow.Text = "^"
    local totalHeight = #self._items * 40
    self._dropContainer.Size = UDim2.new(1, 0, 0, 0)
    TweenKit.new(self._dropContainer, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.25, "OutQuad")
end

function Dropdown:_close()
    self._open = false
    self._arrow.Text = "v"
    TweenKit.new(self._dropContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, "InQuad")
    task.delay(0.2, function()
        if not self._open and self._dropContainer then
            self._dropContainer.Visible = false
        end
    end)
end

function Dropdown:SetItems(items)
    self._items = items
    self:_buildItems()
    if self._selected == nil and #items > 0 then
        self._selected = items[1].Value
        self._headerText.Text = items[1].Text or tostring(items[1].Value)
    end
end

function Dropdown:GetValue()
    return self._selected
end

function Dropdown:SetValue(value)
    self._selected = value
    self._headerText.Text = self:_getDisplayText(value)
end

function Dropdown:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._header = nil
    self._dropPanel = nil
    self._dropContainer = nil
    self._itemButtons = {}
end

return Dropdown