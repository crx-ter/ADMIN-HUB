local Theme = {}
Theme.__index = Theme

local DEFAULT_PALETTE = {
    Background = Color3.fromRGB(7, 9, 15),
    Surface = Color3.fromRGB(17, 24, 39),
    SurfaceLight = Color3.fromRGB(31, 41, 55),
    Primary = Color3.fromRGB(59, 130, 246),
    Secondary = Color3.fromRGB(139, 92, 246),
    Accent = Color3.fromRGB(6, 182, 212),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(251, 191, 36),
    Error = Color3.fromRGB(239, 68, 68),
    TextPrimary = Color3.fromRGB(241, 245, 249),
    TextSecondary = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    Border = Color3.fromRGB(55, 65, 81),
    Glow = Color3.fromRGB(59, 130, 246),
}

local DEFAULT_SCALES = {
    XS = 0.75,
    SM = 0.875,
    MD = 1.0,
    LG = 1.125,
    XL = 1.25,
    XXL = 1.5,
}

function Theme.new(overrides)
    local self = setmetatable({}, Theme)
    self.Palette = {}
    for k, v in pairs(DEFAULT_PALETTE) do
        self.Palette[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            if type(v) == "table" and self.Palette[k] then
                for sk, sv in pairs(v) do
                    self.Palette[k] = sv
                end
            else
                self.Palette[k] = v
            end
        end
    end
    self.Scale = 1.0
    self.PanelTransparency = 0.4
    self.BlurIntensity = 12
    self.AnimationSpeed = 1.0
    self.Scales = DEFAULT_SCALES
    return self
end

function Theme:GetColor(name)
    return self.Palette[name] or self.Palette.TextPrimary
end

function Theme:SetPrimary(color)
    self.Palette.Primary = color
    self.Palette.Glow = color
end

function Theme:SetSecondary(color)
    self.Palette.Secondary = color
end

function Theme:GetSurfaceColor(transparency)
    local t = transparency or self.PanelTransparency
    return self.Palette.Surface, t
end

function Theme:GetBorderColor(transparency)
    return self.Palette.Border, 0.6
end

function Theme:GetAccentGradient()
    return {
        Color1 = self.Palette.Primary,
        Color2 = self.Palette.Secondary,
    }
end

function Theme:GetGlassProps(panel)
    panel.BackgroundColor3 = self.Palette.Surface
    panel.BackgroundTransparency = self.PanelTransparency
    local stroke = panel:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = panel
    end
    stroke.Color = self.Palette.Border
    stroke.Transparency = 0.7
    stroke.Thickness = 1
end

function Theme:ApplyGlass(panel)
    self:GetGlassProps(panel)
end

local _instance = Theme.new()

function Theme.GetGlobal()
    return _instance
end

function Theme.SetGlobal(theme)
    _instance = theme
end

return Theme