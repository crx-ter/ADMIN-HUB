-- Universal Silent Aim Premium Edition (Corrección Visual Definitiva)
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

-- Aplicamos los colores oscuros/neón usando las propiedades nativas de Linoria
Library.AccentColor = Color3.fromRGB(0, 255, 255)      -- Cyan Neón para los botones y barras
Library.MainColor = Color3.fromRGB(20, 20, 25)         -- Fondo principal oscuro
Library.BackgroundColor = Color3.fromRGB(15, 15, 20)   -- Fondos secundarios (Sliders, toggles)
Library.OutlineColor = Color3.fromRGB(45, 45, 55)      -- Bordes limpios y discretos
Library.FontColor = Color3.fromRGB(245, 245, 250)      -- Texto claro

local Window = Library:CreateWindow({
    Title = 'Universal Silent Aim • Premium',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.25
})

-- Aplicar estilo premium de forma INTELIGENTE (Solo a la ventana exterior)
task.spawn(function()
    task.wait(0.5) 
    local coreGui = game:GetService("CoreGui")
    
    for _, gui in ipairs(coreGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            -- Buscamos el contenedor principal de LinoriaLib
            local mainFrame = gui:FindFirstChild("Main")
            if mainFrame and mainFrame:IsA("Frame") then
                
                -- Validamos que sea nuestra UI
                local isOurs = false
                for _, desc in ipairs(mainFrame:GetDescendants()) do
                    if desc:IsA("TextLabel") and string.find(desc.Text, "Universal Silent Aim") then
                        isOurs = true
                        break
                    end
                end
                
                if isOurs then
                    -- 1. MAGIA PARA MÓVIL: Escalamos TODA la UI para que los botones sean más grandes
                    -- Esto mantiene la estética de Linoria pero la hace fácil de tocar con los dedos
                    local scale = Instance.new("UIScale")
                    scale.Scale = 1.15 -- 15% más grande (Si lo sientes pequeño, súbelo a 1.25)
                    scale.Parent = mainFrame
                    
                    -- 2. Borde redondeado SOLO al contenedor principal
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = mainFrame
                    
                    -- 3. Resplandor Neón exterior (Limpio y sin arruinar lo de adentro)
                    local stroke = Instance.new("UIStroke")
                    stroke.Color = Color3.fromRGB(0, 255, 255)
                    stroke.Thickness = 1.5
                    stroke.Transparency = 0.2
                    stroke.Parent = mainFrame
                    
                    -- Redondeamos la barra superior para que acompañe el diseño
                    local topBar = mainFrame:FindFirstChild("Topbar") or mainFrame:FindFirstChild("TopBar")
                    if topBar then
                        local topCorner = Instance.new("UICorner")
                        topCorner.CornerRadius = UDim.new(0, 8)
                        topCorner.Parent = topBar
                    end
                    break
                end
            end
        end
    end
end)

-- === UI TABS (Exactamente igual que el original) ===
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
