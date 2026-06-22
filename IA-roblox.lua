-- Universal Silent Aim Premium Edition (Estable y 100% Funcional)
if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,
    ClassName = "Universal Silent Aim - Averiias Premium",
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

getgenv().SilentAimSettings = SilentAimSettings

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local mouse_box = Drawing.new("Square")
mouse_box.Visible = false
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(0, 255, 255)
mouse_box.Thickness = 2
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = false

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1.5
fov_circle.NumSides = 100
fov_circle.Radius = 130
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(0, 255, 255)

-- ==================== UI PREMIUM ====================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

-- Tema Nativo Premium (Sin hacks, no rompe interacciones)
Library.AccentColor = Color3.fromRGB(0, 255, 255)      -- Cyan Neón puro
Library.MainColor = Color3.fromRGB(22, 22, 27)         -- Fondo principal estilo Discord Oscuro
Library.BackgroundColor = Color3.fromRGB(15, 15, 20)   -- Fondos de los contenedores
Library.OutlineColor = Color3.fromRGB(50, 50, 60)      -- Bordes sutiles para dar profundidad
Library.FontColor = Color3.fromRGB(255, 255, 255)      -- Texto blanco puro para máxima legibilidad

local Window = Library:CreateWindow({
    Title = 'Universal Silent Aim • Premium',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- === UI TABS ===
local GeneralTab = Window:AddTab("General")

local MainBOX = GeneralTab:AddLeftTabbox("Main") do
    local Main = MainBOX:AddTab("Main")
    
    Main:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false})
    
    Main:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck})
    Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck})
    Main:AddDropdown("TargetPart", {Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}})
    Main:AddDropdown("Method", {Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {"Raycast","FindPartOnRay","FindPartOnRayWithWhitelist","FindPartOnRayWithIgnoreList","Mouse.Hit/Target"}})
    Main:AddSlider("HitChance", {Text = 'Hit Chance', Default = 100, Min = 0, Max = 100, Rounding = 1})
end

local FieldOfViewBOX = GeneralTab:AddLeftTabbox("Field Of View") do
    local Visuals = FieldOfViewBOX:AddTab("Visuals")
    Visuals:AddToggle("Visible", {Text = "Show FOV Circle"})
    Visuals:AddSlider("Radius", {Text = "FOV Radius", Min = 0, Max = 360, Default = 130})
    Visuals:AddToggle("MousePosition", {Text = "Show Target Indicator"})
end

Library:SetWatermark("Universal Silent Aim • Premium")
