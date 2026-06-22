-- Universal Silent Aim
if not game:IsLoaded() then game.Loaded:Wait() end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()

-- Tema
Library.Theme.MainColor = Color3.fromRGB(15, 15, 20)
Library.Theme.BackgroundColor = Color3.fromRGB(20, 20, 25)
Library.Theme.AccentColor = Color3.fromRGB(0, 255, 255)
Library.Theme.OutlineColor = Color3.fromRGB(40, 40, 50)
Library.Theme.FontColor = Color3.fromRGB(245, 245, 250)

Library:SetWatermark("Universal Silent Aim Premium")

local Window = Library:CreateWindow({
    Title = 'Universal Silent Aim',
    Center = true,
    AutoShow = true,
    TabPadding = 12
})

-- Variables
local SilentAimSettings = {
    Enabled = false,
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    Method = "Raycast",
    FOVRadius = 130,
    FOVVisible = false,
    ShowTarget = false,
    Prediction = false,
    PredictionAmount = 0.165,
    HitChance = 100
}

-- ==================== UI ====================
task.spawn(function()
    task.wait(0.8)
    local coreGui = game:GetService("CoreGui")
    local function Style(instance)
        if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
            instance.Font = Enum.Font.GothamMedium
            if instance.TextSize < 15 then instance.TextSize = 15 end
        end
        if instance:IsA("Frame") and instance.Size.Y.Offset > 15 then
            local c = Instance.new("UICorner", instance)
            c.CornerRadius = UDim.new(0, 10)
            local s = Instance.new("UIStroke", instance)
            s.Color = Color3.fromRGB(0, 255, 255)
            s.Thickness = 1.5
            s.Transparency = 0.35
        end
    end
    
    for _, gui in ipairs(coreGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui:FindFirstChildWhichIsA("TextLabel", true) then
            for _, v in ipairs(gui:GetDescendants()) do
                Style(v)
            end
            gui.DescendantAdded:Connect(Style)
        end
    end
end)

-- Tabs
local General = Window:AddTab("General")

local Main = General:AddLeftTabbox("Main"):AddTab("Main")
Main:AddToggle("Enabled", {Text = "Silent Aim Enabled", Default = false}):AddKeyPicker("ToggleKey", {Default = "RightAlt"})
Main:AddToggle("TeamCheck", {Text = "Team Check", Default = false})
Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = false})
Main:AddDropdown("TargetPart", {Text = "Target Part", Default = "HumanoidRootPart", Values = {"Head", "HumanoidRootPart", "Random"}})
Main:AddDropdown("Method", {Text = "Method", Default = "Raycast", Values = {"Raycast", "Mouse.Hit/Target"}})
Main:AddSlider("HitChance", {Text = "Hit Chance (%)", Default = 100, Min = 0, Max = 100})

local Visuals = General:AddLeftTabbox("Visuals"):AddTab("Visuals")
Visuals:AddToggle("ShowFOV", {Text = "Show FOV Circle", Default = false})
Visuals:AddSlider("Radius", {Text = "FOV Radius", Default = 130, Min = 0, Max = 500})
Visuals:AddToggle("ShowTarget", {Text = "Show Target Indicator", Default = false})

print("✅ Diseño Premium cargado - Prueba activando Enabled")
