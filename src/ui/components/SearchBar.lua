local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local SearchBar = {}
SearchBar.__index = SearchBar

function SearchBar.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _onSearch = props.OnSearch or function() end,
        _onFocus = props.OnFocus or function() end,
        _onBlur = props.OnBlur or function() end,
        _destroyed = false,
        _debounceTimer = nil,
    }, SearchBar)

    self._frame = Glass.new({
        Name = props.Name or "SearchBar",
        Parent = parent,
        Size = props.Size or UDim2.new(0, 280, 0, 40),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = 20,
        Transparency = 0.45,
        BorderGlow = true,
    })

    self._icon = InstanceUtils.New("TextLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.fromOffset(12, 11),
        BackgroundTransparency = 1,
        Text = "Q",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = self._frame,
    })

    self._placeholder = InstanceUtils.New("TextLabel", {
        Name = "Placeholder",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1,
        Text = props.Placeholder or "Search commands...",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })

    self._input = InstanceUtils.New("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "",
        ClearTextOnFocus = false,
        Parent = self._frame,
    })

    self._clearButton = InstanceUtils.New("TextButton", {
        Name = "Clear",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0, 10),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Visible = false,
        Parent = self._frame,
    })

    self._resultsFrame = nil
    self._resultsVisible = false

    self._input.Focused:Connect(function()
        self._placeholder.Visible = false
        self._clearButton.Visible = #self._input.Text > 0
        self._onFocus()
    end)

    self._input.FocusLost:Connect(function()
        if #self._input.Text == 0 then
            self._placeholder.Visible = true
        end
        self._clearButton.Visible = false
        self._onBlur()
    end)

    self._input:GetPropertyChangedSignal("Text"):Connect(function()
        local text = self._input.Text
        self._placeholder.Visible = #text == 0
        self._clearButton.Visible = #text > 0
        if self._debounceTimer then
            self._debounceTimer:Cancel()
        end
        self._debounceTimer = task.delay(0.15, function()
            if not self._destroyed then
                self._onSearch(text)
            end
        end)
    end)

    self._clearButton.MouseButton1Click:Connect(function()
        self._input.Text = ""
        self._onSearch("")
    end)

    return self
end

function SearchBar:GetText()
    return self._input.Text
end

function SearchBar:SetText(text)
    self._input.Text = text
end

function SearchBar:Focus()
    self._input:CaptureFocus()
end

function SearchBar:Destroy()
    self._destroyed = true
    if self._debounceTimer then
        self._debounceTimer:Cancel()
    end
    if self._frame then self._frame:Destroy() end
    if self._resultsFrame then self._resultsFrame:Destroy() end
    self._frame = nil
    self._input = nil
    self._placeholder = nil
    self._icon = nil
    self._clearButton = nil
    self._resultsFrame = nil
end

return SearchBar