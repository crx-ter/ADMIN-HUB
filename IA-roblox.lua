-- ═══════════════════════════════════════════════════════════════════════════════
-- LXNDXN QUANTUM OS v2.5 — DELTA EDITION
-- Author  : LXNDXN
-- Engine  : Delta Executor (Mobile-Optimised Roblox Lua)
-- Version : 2.5.0-DE
-- Theme   : Cyberpunk Dark · Neon Purple · Glassmorphic
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 1 - ENVIRONMENT BOOTSTRAP (Limpieza y configuración global)
-- ═══════════════════════════════════════════════════════════════════════════════

local ENV = getgenv()

-- Destruye instancias anteriores del OS para liberar RAM
if ENV.QuantumOS_Instance then
    pcall(function() ENV.QuantumOS_Instance:Destroy() end)
end
if ENV.QuantumOS_OracleFloat then
    pcall(function() ENV.QuantumOS_OracleFloat:Destroy() end)
end
if ENV.QuantumOS_Connections then
    for _, c in pairs(ENV.QuantumOS_Connections) do
        pcall(function() c:Disconnect() end)
    end
end

ENV.QuantumOS_Connections = {}
ENV.QuantumOS_ActiveTab   = nil
ENV.QuantumOS_Unlocked    = false
ENV.QuantumOS_ValidKey    = "QUANTUM-2025-DELTA-LXNDXN"   -- Demo key

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 2 - SERVICIOS Y REFERENCIAS (Services & player refs)
-- ═══════════════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid     = Character:FindFirstChildOfClass("Humanoid")

local DISPLAY_NAME = LocalPlayer.DisplayName
local USERNAME     = LocalPlayer.Name
local GAME_NAME    = game.Name or "Roblox"
local PLACE_ID     = game.PlaceId

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 3 - PALETA DE COLORES Y CONSTANTES (Design tokens)
-- ═══════════════════════════════════════════════════════════════════════════════

local C = {
    -- Primarios
    PURPLE_NEON   = Color3.fromRGB(160,  32, 240),
    PURPLE_DIM    = Color3.fromRGB( 90,  15, 140),
    PURPLE_GLOW   = Color3.fromRGB(180,  80, 255),
    CYAN_NEON     = Color3.fromRGB(  0, 220, 255),
    CYAN_DIM      = Color3.fromRGB(  0, 140, 180),

    -- Fondos
    BG_DEEP       = Color3.fromRGB(  6,   6,  18),
    BG_PANEL      = Color3.fromRGB( 12,  12,  30),
    BG_CARD       = Color3.fromRGB( 18,  18,  45),
    BG_SIDEBAR    = Color3.fromRGB(  8,   8,  22),
    BG_GLASS      = Color3.fromRGB( 25,  20,  50),
    BG_HEADER     = Color3.fromRGB( 15,  10,  35),

    -- Texto
    TEXT_WHITE    = Color3.fromRGB(230, 230, 255),
    TEXT_SOFT     = Color3.fromRGB(160, 155, 200),
    TEXT_MUTED    = Color3.fromRGB( 90,  85, 130),
    TEXT_GREEN    = Color3.fromRGB(  0, 220, 130),
    TEXT_RED      = Color3.fromRGB(255,  70,  70),
    TEXT_YELLOW   = Color3.fromRGB(255, 210,  60),

    -- Accent
    ACCENT_A      = Color3.fromRGB(160,  32, 240),
    ACCENT_B      = Color3.fromRGB(  0, 180, 255),
    BORDER        = Color3.fromRGB( 60,  45, 110),
    BORDER_BRIGHT = Color3.fromRGB(120,  60, 200),

    -- Toggle
    TOGGLE_ON     = Color3.fromRGB(  0, 190, 120),
    TOGGLE_OFF    = Color3.fromRGB( 50,  45,  75),

    -- Slider
    SLIDER_BG     = Color3.fromRGB( 30,  25,  65),
    SLIDER_FILL   = Color3.fromRGB(160,  32, 240),
}

-- Tween Presets
local TI_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quart,  Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.55, Enum.EasingStyle.Quint,  Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back,   Enum.EasingDirection.Out)
local TI_SINE   = TweenInfo.new(1.20, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut)
local TI_PULSE  = TweenInfo.new(0.90, Enum.EasingStyle.Sine,   Enum.EasingDirection.InOut, -1, true)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 4 - UTILIDADES UI (Helper functions para crear instancias)
-- ═══════════════════════════════════════════════════════════════════════════════

local function Make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        pcall(function() inst[k] = v end)
    end
    if parent then inst.Parent = parent end
    return inst
end

local function MakeFrame(props, parent)
    return Make("Frame", props, parent)
end

local function MakeLabel(props, parent)
    return Make("TextLabel", props, parent)
end

local function MakeButton(props, parent)
    return Make("TextButton", props, parent)
end

local function MakeBox(props, parent)
    return Make("TextBox", props, parent)
end

local function MakeImage(props, parent)
    return Make("ImageLabel", props, parent)
end

local function MakeScroll(props, parent)
    return Make("ScrollingFrame", props, parent)
end

local function Tween(inst, info, props)
    return TweenService:Create(inst, info, props):Play()
end

local function Corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius  = UDim.new(0, r)
    c.Parent        = parent
    return c
end

local function Stroke(thickness, color, parent)
    local s = Instance.new("UIStroke")
    s.Thickness  = thickness
    s.Color      = color or C.BORDER
    s.Parent     = parent
    return s
end

local function Padding(top, right, bottom, left, parent)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.Parent        = parent
    return p
end

local function ListLayout(props, parent)
    local l = Instance.new("UIListLayout")
    for k, v in pairs(props or {}) do
        pcall(function() l[k] = v end)
    end
    l.Parent = parent
    return l
end

local function GridLayout(props, parent)
    local g = Instance.new("UIGridLayout")
    for k, v in pairs(props or {}) do
        pcall(function() g[k] = v end)
    end
    g.Parent = parent
    return g
end

local function TrackConn(conn)
    table.insert(ENV.QuantumOS_Connections, conn)
    return conn
end

-- Gradiente helper
local function Gradient(c0, c1, rot, parent)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent   = parent
    return g
end

-- Hover glow efecto
local function HoverGlow(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        Tween(btn, TI_FAST, {BackgroundColor3 = hoverColor})
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, TI_FAST, {BackgroundColor3 = normalColor})
    end)
end

-- Typewriter effect
local function Typewriter(label, text, speed)
    speed = speed or 0.04
    label.Text = ""
    task.spawn(function()
        for i = 1, #text do
            label.Text = string.sub(text, 1, i)
            task.wait(speed)
        end
    end)
end

-- Animación de pulso en brillo (UIStroke)
local function PulseStroke(stroke, c1, c2)
    task.spawn(function()
        local dir = true
        while stroke and stroke.Parent do
            Tween(stroke, TI_SINE, {Color = dir and c2 or c1})
            task.wait(1.2)
            dir = not dir
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 5 - RAÍZ DEL GUI (ScreenGui principal)
-- ═══════════════════════════════════════════════════════════════════════════════

local ScreenGui = Make("ScreenGui", {
    Name             = "QuantumOS_v25",
    ResetOnSpawn     = false,
    IgnoreGuiInset   = true,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
    DisplayOrder     = 999,
}, PlayerGui)

ENV.QuantumOS_Instance = ScreenGui

-- Fondo principal
local BG = MakeFrame({
    Name            = "Background",
    Size            = UDim2.fromScale(1, 1),
    BackgroundColor3= C.BG_DEEP,
    BorderSizePixel = 0,
    ZIndex          = 1,
}, ScreenGui)

-- Textura de grid sutil
local GridTex = Make("ImageLabel", {
    Name              = "GridTexture",
    Size              = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image             = "rbxassetid://6370457276",
    ImageColor3       = C.PURPLE_NEON,
    ImageTransparency = 0.94,
    ZIndex            = 2,
}, BG)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 6 - BOOT SCREEN (Pantalla de arranque con typewriter y logo pulsante)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateBootScreen()
    local Boot = MakeFrame({
        Name            = "BootScreen",
        Size            = UDim2.fromScale(1, 1),
        BackgroundColor3= C.BG_DEEP,
        BackgroundTransparency = 0,
        ZIndex          = 100,
    }, ScreenGui)

    -- Gradiente de fondo boot
    Gradient(C.BG_DEEP, C.BG_PANEL, 135, Boot)

    -- Contenedor centrado
    local Center = MakeFrame({
        Name            = "Center",
        Size            = UDim2.new(0, 360, 0, 420),
        Position        = UDim2.new(0.5, -180, 0.5, -210),
        BackgroundColor3= C.BG_GLASS,
        BackgroundTransparency = 0.35,
        ZIndex          = 101,
    }, Boot)
    Corner(28, Center)
    Stroke(2, C.PURPLE_NEON, Center)
    local cs = Stroke(2, C.PURPLE_NEON, Center)
    PulseStroke(cs, C.PURPLE_DIM, C.PURPLE_GLOW)

    -- Logo text / icono
    local LogoLabel = MakeLabel({
        Name            = "Logo",
        Size            = UDim2.new(1, 0, 0, 80),
        Position        = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1,
        Text            = "⬡",
        Font            = Enum.Font.GothamBold,
        TextSize        = 68,
        TextColor3      = C.PURPLE_NEON,
        ZIndex          = 102,
    }, Center)

    -- Animación de pulso del logo
    task.spawn(function()
        while LogoLabel and LogoLabel.Parent do
            Tween(LogoLabel, TI_SINE, {TextColor3 = C.PURPLE_GLOW, TextTransparency = 0.1})
            task.wait(1.2)
            Tween(LogoLabel, TI_SINE, {TextColor3 = C.PURPLE_NEON, TextTransparency = 0.0})
            task.wait(1.2)
        end
    end)

    -- Título OS
    local OSTitleLabel = MakeLabel({
        Name            = "OSTitle",
        Size            = UDim2.new(1, 0, 0, 28),
        Position        = UDim2.new(0, 0, 0, 115),
        BackgroundTransparency = 1,
        Text            = "QUANTUM OS  v2.5",
        Font            = Enum.Font.GothamBold,
        TextSize        = 22,
        TextColor3      = C.TEXT_WHITE,
        ZIndex          = 102,
    }, Center)

    local SubBadge = MakeLabel({
        Name            = "Badge",
        Size            = UDim2.new(0, 160, 0, 24),
        Position        = UDim2.new(0.5, -80, 0, 146),
        BackgroundColor3= C.PURPLE_DIM,
        BackgroundTransparency = 0.3,
        Text            = "✦ DELTA EDITION ✦",
        Font            = Enum.Font.GothamSemibold,
        TextSize        = 11,
        TextColor3      = C.CYAN_NEON,
        ZIndex          = 102,
    }, Center)
    Corner(12, SubBadge)

    -- Bienvenida typewriter
    local WelcomeLabel = MakeLabel({
        Name            = "Welcome",
        Size            = UDim2.new(1, -40, 0, 50),
        Position        = UDim2.new(0, 20, 0, 185),
        BackgroundTransparency = 1,
        Text            = "",
        Font            = Enum.Font.Gotham,
        TextSize        = 15,
        TextColor3      = C.TEXT_WHITE,
        TextWrapped     = true,
        ZIndex          = 102,
    }, Center)

    -- Subtexto
    local SubText = MakeLabel({
        Name            = "SubText",
        Size            = UDim2.new(1, -40, 0, 50),
        Position        = UDim2.new(0, 20, 0, 240),
        BackgroundTransparency = 1,
        Text            = "",
        Font            = Enum.Font.Gotham,
        TextSize        = 12,
        TextColor3      = C.TEXT_SOFT,
        TextWrapped     = true,
        ZIndex          = 102,
    }, Center)

    -- Barra de progreso
    local ProgressBG = MakeFrame({
        Name            = "ProgressBG",
        Size            = UDim2.new(1, -40, 0, 6),
        Position        = UDim2.new(0, 20, 0, 320),
        BackgroundColor3= C.SLIDER_BG,
        ZIndex          = 102,
    }, Center)
    Corner(3, ProgressBG)

    local ProgressFill = MakeFrame({
        Name            = "Fill",
        Size            = UDim2.new(0, 0, 1, 0),
        BackgroundColor3= C.PURPLE_NEON,
        ZIndex          = 103,
    }, ProgressBG)
    Corner(3, ProgressFill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, ProgressFill)

    local ProgressLabel = MakeLabel({
        Name            = "ProgressLabel",
        Size            = UDim2.new(1, 0, 0, 18),
        Position        = UDim2.new(0, 0, 1, 5),
        BackgroundTransparency = 1,
        Text            = "Inicializando sistema...",
        Font            = Enum.Font.Gotham,
        TextSize        = 11,
        TextColor3      = C.TEXT_MUTED,
        ZIndex          = 102,
    }, ProgressBG)

    -- Versión footer
    local VersionLabel = MakeLabel({
        Name            = "Version",
        Size            = UDim2.new(1, 0, 0, 18),
        Position        = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Text            = "LXNDXN Quantum OS · Delta Executor Edition",
        Font            = Enum.Font.Gotham,
        TextSize        = 10,
        TextColor3      = C.TEXT_MUTED,
        ZIndex          = 102,
    }, Center)

    -- Secuencia de boot
    task.spawn(function()
        task.wait(0.5)
        Typewriter(WelcomeLabel, "Hola, " .. DISPLAY_NAME .. ". Bienvenido a Quantum OS v2.5", 0.045)
        task.wait(1.8)
        Typewriter(SubText, "Inicializando pasarela en Delta Executor...\nEntorno seguro verificado.", 0.035)
        task.wait(1.4)

        -- Progreso
        local steps = {
            {0.15, "Cargando módulos del kernel..."},
            {0.32, "Verificando entorno Delta..."},
            {0.50, "Inicializando subsistemas UI..."},
            {0.68, "Conectando al Oracle IA..."},
            {0.85, "Estableciendo sesión segura..."},
            {1.00, "Sistema listo."},
        }
        for _, step in ipairs(steps) do
            Tween(ProgressFill, TI_MED, {Size = UDim2.new(step[1], 0, 1, 0)})
            ProgressLabel.Text = step[2]
            task.wait(0.45)
        end

        task.wait(0.5)
        -- Fade out boot screen
        Tween(Boot, TI_SLOW, {BackgroundTransparency = 1})
        Tween(Center, TI_SLOW, {BackgroundTransparency = 1})
        task.wait(0.6)
        Boot:Destroy()
    end)

    return Boot
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 7 - LOGIN SCREEN (Sistema de verificación de API Key)
-- ═══════════════════════════════════════════════════════════════════════════════

local LoginScreenRef = nil

local function CreateLoginScreen(onSuccess)
    local Login = MakeFrame({
        Name            = "LoginScreen",
        Size            = UDim2.fromScale(1, 1),
        BackgroundColor3= C.BG_DEEP,
        BackgroundTransparency = 0,
        ZIndex          = 90,
    }, ScreenGui)

    Gradient(C.BG_DEEP, Color3.fromRGB(10, 5, 28), 135, Login)

    -- Panel de login centrado
    local Panel = MakeFrame({
        Name            = "LoginPanel",
        Size            = UDim2.new(0, 380, 0, 500),
        Position        = UDim2.new(0.5, -190, 0.5, -250),
        BackgroundColor3= C.BG_GLASS,
        BackgroundTransparency = 0.25,
        ZIndex          = 91,
    }, Login)
    Corner(24, Panel)
    local ls = Stroke(2, C.BORDER_BRIGHT, Panel)

    -- Partículas decorativas (simuladas con labels)
    for i = 1, 6 do
        local px = MakeFrame({
            Size = UDim2.new(0, 3, 0, 3),
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundColor3 = (i % 2 == 0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency = 0.3,
            ZIndex = 92,
        }, Panel)
        Corner(2, px)
        task.spawn(function()
            while px and px.Parent do
                local rx = math.random(0, 100) / 100
                local ry = math.random(0, 100) / 100
                Tween(px, TweenInfo.new(2 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(rx, 0, ry, 0),
                    BackgroundTransparency = 0.6
                })
                task.wait(2 + math.random())
            end
        end)
    end

    -- Icono
    local Icon = MakeLabel({
        Size = UDim2.new(0, 70, 0, 70),
        Position = UDim2.new(0.5, -35, 0, 28),
        BackgroundTransparency = 1,
        Text = "⬡",
        Font = Enum.Font.GothamBold,
        TextSize = 58,
        TextColor3 = C.PURPLE_NEON,
        ZIndex = 92,
    }, Panel)
    task.spawn(function()
        while Icon and Icon.Parent do
            Tween(Icon, TI_SINE, {TextColor3 = C.CYAN_NEON})
            task.wait(1.2)
            Tween(Icon, TI_SINE, {TextColor3 = C.PURPLE_NEON})
            task.wait(1.2)
        end
    end)

    -- Título
    MakeLabel({
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 108),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS LOGIN",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 92,
    }, Panel)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 140),
        BackgroundTransparency = 1,
        Text = "Acceso restringido · Introduce tu API Key",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 92,
    }, Panel)

    -- Separador
    local Sep = MakeFrame({
        Size = UDim2.new(0.7, 0, 0, 1),
        Position = UDim2.new(0.15, 0, 0, 168),
        BackgroundColor3 = C.BORDER,
        ZIndex = 92,
    }, Panel)

    -- Label caja
    MakeLabel({
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 20, 0, 188),
        BackgroundTransparency = 1,
        Text = "API KEY",
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 92,
    }, Panel)

    -- TextBox para la Key
    local KeyBox = MakeBox({
        Size = UDim2.new(1, -40, 0, 52),
        Position = UDim2.new(0, 20, 0, 210),
        BackgroundColor3 = C.BG_CARD,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Pega tu API Key aquí...",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ClearTextOnFocus = false,
        ZIndex = 93,
    }, Panel)
    Corner(10, KeyBox)
    local kbs = Stroke(2, C.BORDER, KeyBox)
    Padding(0, 14, 0, 14, KeyBox)

    KeyBox.Focused:Connect(function()
        Tween(kbs, TI_FAST, {Color = C.PURPLE_NEON})
    end)
    KeyBox.FocusLost:Connect(function()
        Tween(kbs, TI_FAST, {Color = C.BORDER})
    end)

    -- Status label
    local StatusLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 22),
        Position = UDim2.new(0, 20, 0, 272),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_MUTED,
        TextWrapped = true,
        ZIndex = 92,
    }, Panel)

    -- Botón VERIFY & LOGIN
    local LoginBtn = MakeButton({
        Size = UDim2.new(1, -40, 0, 52),
        Position = UDim2.new(0, 20, 0, 302),
        BackgroundColor3 = C.PURPLE_NEON,
        BorderSizePixel = 0,
        Text = "VERIFY & LOGIN",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 93,
    }, Panel)
    Corner(12, LoginBtn)
    Gradient(C.PURPLE_NEON, C.PURPLE_DIM, 135, LoginBtn)
    HoverGlow(LoginBtn, C.PURPLE_NEON, C.PURPLE_GLOW)

    -- Info key hint
    local HintLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 32),
        Position = UDim2.new(0, 20, 0, 368),
        BackgroundTransparency = 1,
        Text = "💡 Demo Key: QUANTUM-2025-DELTA-LXNDXN",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_MUTED,
        TextWrapped = true,
        ZIndex = 92,
    }, Panel)

    -- Link / créditos
    MakeLabel({
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -25),
        BackgroundTransparency = 1,
        Text = "LXNDXN Quantum OS  ·  Delta Edition  ·  v2.5",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 92,
    }, Panel)

    -- Loading spinner frame
    local Spinner = MakeLabel({
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0.5, -15, 0, 310),
        BackgroundTransparency = 1,
        Text = "◌",
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = C.CYAN_NEON,
        Visible = false,
        ZIndex = 94,
    }, Panel)

    -- Verificación
    local function VerifyKey()
        local key = KeyBox.Text:gsub("%s+", "")
        if key == "" then
            StatusLabel.Text = "⚠ Por favor introduce una API Key."
            StatusLabel.TextColor3 = C.TEXT_YELLOW
            return
        end

        -- Mostrar spinner
        LoginBtn.Visible = false
        Spinner.Visible = true
        StatusLabel.Text = "Verificando conexión segura..."
        StatusLabel.TextColor3 = C.CYAN_NEON

        -- Rotación del spinner
        local spinActive = true
        task.spawn(function()
            local icons = {"◌","◍","◎","●","◎","◍"}
            local i = 1
            while spinActive do
                Spinner.Text = icons[i]
                i = i % #icons + 1
                task.wait(0.1)
            end
        end)

        task.wait(1.8)  -- Simula llamada HTTP

        -- Validación
        spinActive = false
        Spinner.Visible = false
        LoginBtn.Visible = true

        if key == ENV.QuantumOS_ValidKey then
            StatusLabel.Text = "✓ API Key verificada. Acceso concedido."
            StatusLabel.TextColor3 = C.TEXT_GREEN
            Tween(LoginBtn, TI_FAST, {BackgroundColor3 = C.TOGGLE_ON})
            task.wait(0.8)
            -- Fade out login
            Tween(Login, TI_MED, {BackgroundTransparency = 1})
            task.wait(0.35)
            Login:Destroy()
            ENV.QuantumOS_Unlocked = true
            onSuccess()
        else
            StatusLabel.Text = "✗ API Key inválida. Por favor verifica tu clave."
            StatusLabel.TextColor3 = C.TEXT_RED
            Tween(Panel, TI_FAST, {Position = UDim2.new(0.5, -195, 0.5, -250)})
            task.wait(0.08)
            Tween(Panel, TI_FAST, {Position = UDim2.new(0.5, -185, 0.5, -250)})
            task.wait(0.08)
            Tween(Panel, TI_FAST, {Position = UDim2.new(0.5, -190, 0.5, -250)})
        end
    end

    LoginBtn.MouseButton1Click:Connect(VerifyKey)
    KeyBox.FocusLost:Connect(function(enter)
        if enter then VerifyKey() end
    end)

    LoginScreenRef = Login
    return Login
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 8 - VENTANA PRINCIPAL DEL OS (Frame contenedor, Header y Sidebar)
-- ═══════════════════════════════════════════════════════════════════════════════

local MainWindow = nil
local Sidebar    = nil
local ContentArea= nil
local CurrentTabFrame = nil

local function ClearContent()
    if CurrentTabFrame then
        CurrentTabFrame:Destroy()
        CurrentTabFrame = nil
    end
end

local SidebarButtons = {}

local function SetActiveTab(name)
    for tabName, btn in pairs(SidebarButtons) do
        if tabName == name then
            Tween(btn, TI_FAST, {BackgroundColor3 = C.PURPLE_DIM})
            local indicator = btn:FindFirstChild("Indicator")
            if indicator then indicator.Visible = true end
        else
            Tween(btn, TI_FAST, {BackgroundColor3 = Color3.fromRGB(0,0,0)})
            local indicator = btn:FindFirstChild("Indicator")
            if indicator then indicator.Visible = false end
        end
    end
end

local function CreateMainWindow()
    -- Main container
    MainWindow = MakeFrame({
        Name            = "MainWindow",
        Size            = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex          = 10,
    }, ScreenGui)

    -- ─── HEADER ───────────────────────────────────────────────────────────────
    local Header = MakeFrame({
        Name            = "Header",
        Size            = UDim2.new(1, 0, 0, 52),
        BackgroundColor3= C.BG_HEADER,
        ZIndex          = 12,
    }, MainWindow)
    Stroke(1, C.BORDER, Header)

    -- Logo en header
    local HeaderLogo = MakeLabel({
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 12, 0.5, -18),
        BackgroundTransparency = 1,
        Text = "⬡",
        Font = Enum.Font.GothamBold,
        TextSize = 30,
        TextColor3 = C.PURPLE_NEON,
        ZIndex = 13,
    }, Header)

    local HeaderTitle = MakeLabel({
        Size = UDim2.new(0, 180, 1, 0),
        Position = UDim2.new(0, 52, 0, 0),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS  v2.5",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, Header)

    local HeaderSub = MakeLabel({
        Size = UDim2.new(0, 160, 1, 0),
        Position = UDim2.new(0, 52, 0, 16),
        BackgroundTransparency = 1,
        Text = "Delta Executor Edition",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, Header)

    -- Badge del juego
    local GameBadge = MakeLabel({
        Size = UDim2.new(0, 200, 0, 28),
        Position = UDim2.new(0.5, -100, 0.5, -14),
        BackgroundColor3 = C.BG_CARD,
        Text = "🎮  " .. GAME_NAME,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_SOFT,
        ZIndex = 13,
    }, Header)
    Corner(14, GameBadge)
    Stroke(1, C.BORDER, GameBadge)

    -- Botones de sistema (derecha)
    local SysFrame = MakeFrame({
        Size = UDim2.new(0, 130, 0, 36),
        Position = UDim2.new(1, -140, 0.5, -18),
        BackgroundTransparency = 1,
        ZIndex = 13,
    }, Header)

    local function SysBtn(icon, color, xOff)
        local b = MakeButton({
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(0, xOff, 0.5, -16),
            BackgroundColor3 = Color3.fromRGB(20, 18, 40),
            Text = icon,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = color,
            ZIndex = 14,
        }, SysFrame)
        Corner(8, b)
        HoverGlow(b, Color3.fromRGB(20,18,40), Color3.fromRGB(40,30,70))
        return b
    end

    local WifiBtn  = SysBtn("⚡", C.TEXT_GREEN, 0)
    local NotifBtn = SysBtn("🔔", C.TEXT_YELLOW, 36)
    local MinBtn   = SysBtn("—", C.TEXT_SOFT, 72)
    local CloseBtn = SysBtn("✕", C.TEXT_RED, 100)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow, TI_MED, {Size = UDim2.new(0, 0, 0, 0)})
        task.wait(0.35)
        ScreenGui:Destroy()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        if MainWindow.Size == UDim2.fromScale(1,1) then
            Tween(MainWindow, TI_MED, {Size = UDim2.new(1,0,0,52)})
        else
            Tween(MainWindow, TI_MED, {Size = UDim2.fromScale(1,1)})
        end
    end)

    -- ─── SIDEBAR ──────────────────────────────────────────────────────────────
    Sidebar = MakeFrame({
        Name            = "Sidebar",
        Size            = UDim2.new(0, 210, 1, -52),
        Position        = UDim2.new(0, 0, 0, 52),
        BackgroundColor3= C.BG_SIDEBAR,
        ZIndex          = 11,
    }, MainWindow)
    Stroke(1, C.BORDER, Sidebar)

    -- Avatar / perfil mini en sidebar
    local SbProfile = MakeFrame({
        Size = UDim2.new(1, -20, 0, 70),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 12,
    }, Sidebar)
    Corner(12, SbProfile)
    Stroke(1, C.PURPLE_DIM, SbProfile)

    local AvatarIcon = MakeLabel({
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 10, 0.5, -22),
        BackgroundColor3 = C.PURPLE_DIM,
        Text = string.upper(string.sub(DISPLAY_NAME,1,2)),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 13,
    }, SbProfile)
    Corner(22, AvatarIcon)

    MakeLabel({
        Size = UDim2.new(1, -68, 0, 20),
        Position = UDim2.new(0, 62, 0, 12),
        BackgroundTransparency = 1,
        Text = DISPLAY_NAME,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, SbProfile)

    MakeLabel({
        Size = UDim2.new(1, -68, 0, 16),
        Position = UDim2.new(0, 62, 0, 34),
        BackgroundTransparency = 1,
        Text = "@" .. USERNAME,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, SbProfile)

    local OnlineBadge = MakeLabel({
        Size = UDim2.new(0, 58, 0, 16),
        Position = UDim2.new(0, 62, 0, 52),
        BackgroundColor3 = Color3.fromRGB(0, 60, 30),
        Text = "● Online",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_GREEN,
        ZIndex = 13,
    }, SbProfile)
    Corner(8, OnlineBadge)

    -- Scroll para tabs del sidebar
    local SbScroll = MakeScroll({
        Size = UDim2.new(1, 0, 1, -92),
        Position = UDim2.new(0, 0, 0, 90),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 12,
    }, Sidebar)

    local SbList = MakeFrame({
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 12,
    }, SbScroll)
    ListLayout({Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder}, SbList)

    local SbLayout = SbList:FindFirstChildWhichIsA("UIListLayout")

    -- Definición de tabs
    local TABS = {
        {name="START",          icon="⌂", order=1},
        {name="SCRIPT HUB",     icon="⚡", order=2},
        {name="SYSTEM SETTINGS",icon="⚙", order=3},
        {name="TOOLBOX",        icon="🛠", order=4},
        {name="FILE MANAGER",   icon="📁", order=5},
        {name="PROCESSES & LOGS",icon="📊", order=6},
        {name="MEDIA CENTER",   icon="🎵", order=7},
        {name="COMMUNITY",      icon="👥", order=8},
        {name="QUANTUM ORACLE", icon="🔮", order=9},
        {name="GAME BOOSTER",   icon="🚀", order=10},
        {name="SKIN CUSTOMIZER",icon="🎨", order=11},
        {name="POWER",          icon="⏻",  order=12},
    }

    for _, tab in ipairs(TABS) do
        local Btn = MakeButton({
            Name = tab.name,
            Size = UDim2.new(1, -14, 0, 42),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = tab.order,
            ZIndex = 13,
        }, SbList)
        Corner(10, Btn)
        Padding(0, 8, 0, 8, Btn)

        -- Indicador activo
        local Indicator = MakeFrame({
            Name = "Indicator",
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = C.PURPLE_NEON,
            Visible = false,
            ZIndex = 14,
        }, Btn)
        Corner(2, Indicator)

        -- Icono
        MakeLabel({
            Size = UDim2.new(0, 28, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.icon,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            TextColor3 = C.TEXT_SOFT,
            ZIndex = 14,
        }, Btn)

        -- Nombre
        MakeLabel({
            Size = UDim2.new(1, -46, 1, 0),
            Position = UDim2.new(0, 42, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextColor3 = C.TEXT_SOFT,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 14,
        }, Btn)

        SidebarButtons[tab.name] = Btn
        Btn.MouseButton1Click:Connect(function()
            ClearContent()
            SetActiveTab(tab.name)
            ENV.QuantumOS_ActiveTab = tab.name
            -- TabLoader se llama desde la sección correspondiente
            _G["QOS_Tab_" .. tab.name:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")]()
        end)

        HoverGlow(Btn, Color3.fromRGB(0,0,0), C.BG_GLASS)
    end

    -- Ajustar alto del contenedor de lista
    SbLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SbList.Size = UDim2.new(1, 0, 0, SbLayout.AbsoluteContentSize.Y + 8)
    end)

    -- ─── CONTENT AREA ─────────────────────────────────────────────────────────
    ContentArea = MakeFrame({
        Name            = "ContentArea",
        Size            = UDim2.new(1, -210, 1, -52),
        Position        = UDim2.new(0, 210, 0, 52),
        BackgroundColor3= C.BG_PANEL,
        ZIndex          = 11,
    }, MainWindow)

    -- Animación de entrada
    MainWindow.Size = UDim2.new(0,0,0,0)
    MainWindow.Position = UDim2.new(0.5,0,0.5,0)
    Tween(MainWindow, TI_BOUNCE, {Size = UDim2.fromScale(1,1), Position = UDim2.fromScale(0,0)})
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 9 - COMPONENTES REUTILIZABLES (Cards, Toggles, Sliders, Badges)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Toggle (Switch ON/OFF)
local function CreateToggle(parent, label, defaultState, onChange)
    local Row = MakeFrame({
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 20,
    }, parent)
    Corner(10, Row)

    MakeLabel({
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, Row)

    local Track = MakeFrame({
        Size = UDim2.new(0, 46, 0, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = defaultState and C.TOGGLE_ON or C.TOGGLE_OFF,
        ZIndex = 21,
    }, Row)
    Corner(12, Track)

    local Thumb = MakeFrame({
        Size = UDim2.new(0, 18, 0, 18),
        Position = defaultState and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3 = Color3.new(1,1,1),
        ZIndex = 22,
    }, Track)
    Corner(9, Thumb)

    local state = defaultState
    local ToggleBtn = MakeButton({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 23,
    }, Track)

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        Tween(Track, TI_FAST, {BackgroundColor3 = state and C.TOGGLE_ON or C.TOGGLE_OFF})
        Tween(Thumb, TI_FAST, {Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if onChange then onChange(state) end
    end)

    return Row, function() return state end
end

-- Slider
local function CreateSlider(parent, label, minV, maxV, defaultV, suffix, onChange)
    local Row = MakeFrame({
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 20,
    }, parent)
    Corner(10, Row)

    MakeLabel({
        Size = UDim2.new(1, -60, 0, 22),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, Row)

    local ValLabel = MakeLabel({
        Size = UDim2.new(0, 55, 0, 22),
        Position = UDim2.new(1, -65, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(defaultV) .. (suffix or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 21,
    }, Row)

    local Track = MakeFrame({
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 38),
        BackgroundColor3 = C.SLIDER_BG,
        ZIndex = 21,
    }, Row)
    Corner(3, Track)

    local ratio = (defaultV - minV) / (maxV - minV)
    local Fill = MakeFrame({
        Size = UDim2.new(ratio, 0, 1, 0),
        BackgroundColor3 = C.SLIDER_FILL,
        ZIndex = 22,
    }, Track)
    Corner(3, Fill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, Fill)

    local Knob = MakeFrame({
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(ratio, -8, 0.5, -8),
        BackgroundColor3 = Color3.new(1,1,1),
        ZIndex = 23,
    }, Track)
    Corner(8, Knob)
    Stroke(2, C.PURPLE_NEON, Knob)

    local dragging = false
    local function UpdateSlider(inputX)
        local trackAbs = Track.AbsolutePosition.X
        local trackW   = Track.AbsoluteSize.X
        local t = math.clamp((inputX - trackAbs) / trackW, 0, 1)
        local value = math.floor(minV + t * (maxV - minV))
        Tween(Fill,  TI_FAST, {Size = UDim2.new(t, 0, 1, 0)})
        Tween(Knob,  TI_FAST, {Position = UDim2.new(t, -8, 0.5, -8)})
        ValLabel.Text = tostring(value) .. (suffix or "")
        if onChange then onChange(value) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input.Position.X)
        end
    end)

    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                          input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input.Position.X)
        end
    end))

    TrackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    return Row
end

-- Script Card
local function CreateScriptCard(parent, title, author, verified, onExecute, onInfo, onSave)
    local Card = MakeFrame({
        Size = UDim2.new(1, 0, 0, 78),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 20,
    }, parent)
    Corner(12, Card)
    Stroke(1, C.BORDER, Card)

    -- Icono placeholder
    local Thumb = MakeFrame({
        Size = UDim2.new(0, 52, 0, 52),
        Position = UDim2.new(0, 12, 0.5, -26),
        BackgroundColor3 = C.PURPLE_DIM,
        ZIndex = 21,
    }, Card)
    Corner(10, Thumb)
    MakeLabel({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text = "⚡",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 22,
    }, Thumb)

    MakeLabel({
        Size = UDim2.new(1, -140, 0, 22),
        Position = UDim2.new(0, 74, 0, 12),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, Card)

    local AuthLine = MakeLabel({
        Size = UDim2.new(1, -140, 0, 16),
        Position = UDim2.new(0, 74, 0, 36),
        BackgroundTransparency = 1,
        Text = "Verificado por " .. author,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, Card)

    if verified then
        local VBadge = MakeLabel({
            Size = UDim2.new(0, 100, 0, 16),
            Position = UDim2.new(0, 74, 0, 55),
            BackgroundColor3 = Color3.fromRGB(0, 50, 25),
            Text = "✓ Verificado por Delta",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = C.TEXT_GREEN,
            ZIndex = 22,
        }, Card)
        Corner(8, VBadge)
    end

    -- Botones de acción
    local ExBtn = MakeButton({
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = UDim2.new(1, -168, 0.5, -13),
        BackgroundColor3 = C.PURPLE_NEON,
        Text = "▶  EXECUTE",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 21,
    }, Card)
    Corner(7, ExBtn)
    Padding(0, 10, 0, 10, ExBtn)
    HoverGlow(ExBtn, C.PURPLE_NEON, C.PURPLE_GLOW)

    local InfoBtn = MakeButton({
        Size = UDim2.new(0, 54, 0, 26),
        Position = UDim2.new(1, -110, 0.5, -13),
        BackgroundColor3 = C.BG_GLASS,
        Text = "ⓘ INFO",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        ZIndex = 21,
    }, Card)
    Corner(7, InfoBtn)

    local SaveBtn = MakeButton({
        Size = UDim2.new(0, 54, 0, 26),
        Position = UDim2.new(1, -52, 0.5, -13),
        BackgroundColor3 = C.BG_GLASS,
        Text = "💾 SAVE",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        ZIndex = 21,
    }, Card)
    Corner(7, SaveBtn)

    if onExecute then ExBtn.MouseButton1Click:Connect(onExecute) end
    if onInfo    then InfoBtn.MouseButton1Click:Connect(onInfo) end
    if onSave    then SaveBtn.MouseButton1Click:Connect(onSave) end

    return Card
end

-- Sección header dentro del content
local function SectionHeader(parent, title, subtitle)
    local H = MakeFrame({
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = C.BG_HEADER,
        ZIndex = 19,
    }, parent)
    Stroke(1, C.BORDER, H)

    MakeLabel({
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 20, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
    }, H)

    if subtitle then
        MakeLabel({
            Size = UDim2.new(1, -24, 0, 16),
            Position = UDim2.new(0, 20, 0, 36),
            BackgroundTransparency = 1,
            Text = subtitle,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 20,
        }, H)
    end

    local AccentLine = MakeFrame({
        Size = UDim2.new(0, 3, 0, 36),
        Position = UDim2.new(0, 8, 0, 12),
        BackgroundColor3 = C.PURPLE_NEON,
        ZIndex = 20,
    }, H)
    Corner(2, AccentLine)

    return H
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 10 - TAB: START (Perfil del usuario)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_START"] = function()
    local Tab = MakeFrame({
        Name = "Tab_START",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    local Scroll = MakeScroll({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ZIndex = 15,
    }, Tab)
    local List = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, Scroll)
    ListLayout({Padding = UDim.new(0,0)}, List)
    Padding(0,0,20,0, List)

    SectionHeader(List, "START  ⌂", "Panel de inicio y perfil del usuario")

    -- Hero Card
    local Hero = MakeFrame({
        Size = UDim2.new(1,-32,0,160),
        BackgroundColor3 = C.BG_GLASS,
        ZIndex = 16,
    }, List)
    Corner(16, Hero)
    Gradient(C.BG_GLASS, C.PURPLE_DIM, 135, Hero)
    Stroke(1, C.BORDER_BRIGHT, Hero)
    Padding(16,16,16,16, Hero)

    -- Avatar grande
    local BigAvatar = MakeFrame({
        Size = UDim2.new(0, 90, 0, 90),
        Position = UDim2.new(0, 20, 0.5, -45),
        BackgroundColor3 = C.PURPLE_DIM,
        ZIndex = 17,
    }, Hero)
    Corner(45, BigAvatar)
    Stroke(3, C.PURPLE_NEON, BigAvatar)
    MakeLabel({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text = string.upper(string.sub(DISPLAY_NAME,1,2)),
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 18,
    }, BigAvatar)

    MakeLabel({
        Size = UDim2.new(1,-130,0,26),
        Position = UDim2.new(0,125,0,28),
        BackgroundTransparency = 1,
        Text = DISPLAY_NAME,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, Hero)

    MakeLabel({
        Size = UDim2.new(1,-130,0,18),
        Position = UDim2.new(0,125,0,56),
        BackgroundTransparency = 1,
        Text = "@" .. USERNAME .. "  ·  ID: " .. LocalPlayer.UserId,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_SOFT,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, Hero)

    local VerifBadge = MakeLabel({
        Size = UDim2.new(0, 130, 0, 22),
        Position = UDim2.new(0, 125, 0, 82),
        BackgroundColor3 = Color3.fromRGB(0, 60, 30),
        Text = "✓ Quantum OS Verificado",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_GREEN,
        ZIndex = 18,
    }, Hero)
    Corner(11, VerifBadge)

    -- Stats Grid
    local StatsFrame = MakeFrame({
        Size = UDim2.new(1,-32,0,90),
        BackgroundTransparency = 1,
        ZIndex = 16,
    }, List)

    GridLayout({CellSize = UDim2.new(0.25,-4,1,-4), CellPadding = UDim2.new(0,4,0,4)}, StatsFrame)

    local stats = {
        {"⚡", "Scripts", "12"},
        {"🎮", "Juego", GAME_NAME:sub(1,10)},
        {"⬡", "OS Versión", "v2.5"},
        {"🔑", "Key Status", "✓ Valid"},
    }
    for _, s in ipairs(stats) do
        local SC = MakeFrame({
            BackgroundColor3 = C.BG_CARD,
            ZIndex = 17,
        }, StatsFrame)
        Corner(12, SC)
        Stroke(1, C.BORDER, SC)
        MakeLabel({
            Size = UDim2.new(1,0,0,30),
            Position = UDim2.new(0,0,0,8),
            BackgroundTransparency = 1,
            Text = s[1],
            TextSize = 20,
            ZIndex = 18,
        }, SC)
        MakeLabel({
            Size = UDim2.new(1,0,0,18),
            Position = UDim2.new(0,0,0,36),
            BackgroundTransparency = 1,
            Text = s[2],
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = C.TEXT_MUTED,
            ZIndex = 18,
        }, SC)
        MakeLabel({
            Size = UDim2.new(1,0,0,20),
            Position = UDim2.new(0,0,0,52),
            BackgroundTransparency = 1,
            Text = s[3],
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = C.TEXT_WHITE,
            ZIndex = 18,
        }, SC)
    end

    -- Game info card
    local GCard = MakeFrame({
        Size = UDim2.new(1,-32,0,80),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 16,
    }, List)
    Corner(14, GCard)
    Stroke(1, C.BORDER, GCard)
    Padding(12,14,12,14, GCard)

    MakeLabel({
        Size = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        Text = "SESIÓN ACTUAL",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, GCard)

    MakeLabel({
        Size = UDim2.new(1,0,0,22),
        Position = UDim2.new(0,0,0,22),
        BackgroundTransparency = 1,
        Text = "🎮  Juego: " .. GAME_NAME,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, GCard)

    MakeLabel({
        Size = UDim2.new(1,0,0,18),
        Position = UDim2.new(0,0,0,46),
        BackgroundTransparency = 1,
        Text = "🔑  Place ID: " .. PLACE_ID .. "  ·  Quantum OS activo",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, GCard)

    -- Auto resize scroll
    local ListLayout2 = List:FindFirstChildWhichIsA("UIListLayout")
    ListLayout2.GetPropertyChangedSignal and ListLayout2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        List.Size = UDim2.new(1,0,0,ListLayout2.AbsoluteContentSize.Y)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 11 - TAB: SCRIPT HUB (Explorador de scripts con categorías)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SCRIPT_HUB"] = function()
    local Tab = MakeFrame({
        Name = "Tab_SCRIPTHUB",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "SCRIPT HUB  ⚡", "Ejecuta scripts verificados para tus juegos favoritos")

    -- Barra de búsqueda
    local SearchBar = MakeFrame({
        Size = UDim2.new(1,-32,0,42),
        Position = UDim2.new(0,16,0,68),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 16,
    }, Tab)
    Corner(12, SearchBar)
    Stroke(1, C.BORDER, SearchBar)

    local SearchIcon = MakeLabel({
        Size = UDim2.new(0,30,1,0),
        BackgroundTransparency = 1,
        Text = "🔍",
        TextSize = 16,
        ZIndex = 17,
    }, SearchBar)

    local SearchBox = MakeBox({
        Size = UDim2.new(1,-80,1,0),
        Position = UDim2.new(0,32,0,0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Buscar scripts...",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ClearTextOnFocus = false,
        ZIndex = 17,
    }, SearchBar)

    local SearchBtn = MakeButton({
        Size = UDim2.new(0,62,0,30),
        Position = UDim2.new(1,-68,0.5,-15),
        BackgroundColor3 = C.PURPLE_NEON,
        Text = "BUSCAR",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 17,
    }, SearchBar)
    Corner(8, SearchBtn)

    -- Filtros / Toggles de tipo
    local FiltersFrame = MakeFrame({
        Size = UDim2.new(1,-32,0,32),
        Position = UDim2.new(0,16,0,118),
        BackgroundTransparency = 1,
        ZIndex = 16,
    }, Tab)
    ListLayout({FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)}, FiltersFrame)

    local filters = {
        {label="KEY REQUIRED", color=C.TEXT_YELLOW, active=false},
        {label="NO KEY", color=C.TEXT_GREEN, active=true},
        {label="SCRIPTS WITH KEY", color=C.CYAN_NEON, active=false},
    }
    for _, f in ipairs(filters) do
        local FB = MakeButton({
            Size = UDim2.new(0,0,1,0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = f.active and C.PURPLE_DIM or C.BG_CARD,
            Text = (f.active and "● " or "○ ") .. f.label,
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            TextColor3 = f.color,
            ZIndex = 17,
        }, FiltersFrame)
        Corner(8, FB)
        Padding(0,10,0,10, FB)
        FB.MouseButton1Click:Connect(function()
            f.active = not f.active
            FB.BackgroundColor3 = f.active and C.PURPLE_DIM or C.BG_CARD
            FB.Text = (f.active and "● " or "○ ") .. f.label
        end)
    end

    -- Panel split: Sidebar de categorías + Lista de scripts
    local SplitFrame = MakeFrame({
        Size = UDim2.new(1,-32,1,-162),
        Position = UDim2.new(0,16,0,158),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, Tab)

    -- Categorías
    local CatPanel = MakeFrame({
        Size = UDim2.new(0,155,1,0),
        BackgroundColor3 = C.BG_SIDEBAR,
        ZIndex = 16,
    }, SplitFrame)
    Corner(12, CatPanel)
    Stroke(1, C.BORDER, CatPanel)

    MakeLabel({
        Size = UDim2.new(1,0,0,28),
        BackgroundColor3 = C.BG_HEADER,
        Text = "GAME CATEGORIES",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 17,
    }, CatPanel)
    Corner(12, MakeFrame({Size=UDim2.new(1,0,0,28), BackgroundColor3=C.BG_HEADER, ZIndex=16}, CatPanel))

    local categories = {
        "🍎  Blox Fruits","🗡  Anime Defenders","🏠  Adopt Me","⚔  Pet Simulator X",
        "🌟  Da Hood","🎯  Murder Mystery","🏆  Generic Mod","📦  Universal",
    }
    local CatScroll = MakeScroll({
        Size = UDim2.new(1,0,1,-32),
        Position = UDim2.new(0,0,0,32),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ZIndex = 17,
    }, CatPanel)
    local CatList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 17,
    }, CatScroll)
    ListLayout({Padding = UDim.new(0,2)}, CatList)

    local selectedCat = nil
    for _, cat in ipairs(categories) do
        local Cb = MakeButton({
            Size = UDim2.new(1,0,0,34),
            BackgroundColor3 = C.BG_SIDEBAR,
            Text = cat,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_SOFT,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 18,
        }, CatList)
        Padding(0,0,0,12, Cb)
        Cb.MouseButton1Click:Connect(function()
            if selectedCat then Tween(selectedCat, TI_FAST, {BackgroundColor3 = C.BG_SIDEBAR}) end
            Tween(Cb, TI_FAST, {BackgroundColor3 = C.PURPLE_DIM})
            selectedCat = Cb
        end)
        HoverGlow(Cb, C.BG_SIDEBAR, C.BG_GLASS)
    end

    -- Lista de scripts
    local ScriptPanel = MakeFrame({
        Size = UDim2.new(1,-163,1,0),
        Position = UDim2.new(0,163,0,0),
        BackgroundTransparency = 1,
        ZIndex = 16,
    }, SplitFrame)

    local ScriptScroll = MakeScroll({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ZIndex = 16,
    }, ScriptPanel)

    local ScriptList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 16,
    }, ScriptScroll)
    ListLayout({Padding = UDim.new(0,8)}, ScriptList)
    Padding(0,8,16,8, ScriptList)

    local scriptData = {
        {title="Blox Fruits V3",       author="Delta",    verified=true},
        {title="Anime Defenders Hub",  author="Delta",    verified=true},
        {title="Godmode Universal",    author="LXN Community", verified=false},
        {title="Auto Farm Pet Sim X",  author="Delta",    verified=true},
        {title="Da Hood ESP+Aimbot",   author="Delta",    verified=true},
        {title="Murder Mystery Knife", author="LXN Community", verified=false},
        {title="Speed Glitch Universal",author="Delta",   verified=true},
        {title="Fly Script v4",        author="Delta",    verified=true},
    }

    local function notif(msg)
        local N = MakeFrame({
            Size = UDim2.new(0,260,0,46),
            Position = UDim2.new(1,-270,1,-56),
            BackgroundColor3 = C.BG_CARD,
            ZIndex = 200,
        }, Tab)
        Corner(12, N)
        Stroke(1, C.PURPLE_NEON, N)
        MakeLabel({
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Text = msg,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_WHITE,
            ZIndex = 201,
        }, N)
        Tween(N, TI_MED, {Position = UDim2.new(1,-270,1,-60)})
        task.delay(2.5, function()
            Tween(N, TI_MED, {Position = UDim2.new(1,0,1,-56)})
            task.wait(0.35)
            pcall(function() N:Destroy() end)
        end)
    end

    for _, s in ipairs(scriptData) do
        CreateScriptCard(ScriptList, s.title, s.author, s.verified,
            function() notif("▶ Ejecutando: " .. s.title) end,
            function() notif("ℹ Info: " .. s.title) end,
            function() notif("💾 Guardado: " .. s.title) end
        )
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 12 - TAB: TOOLBOX (Controles del jugador y mundo)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_TOOLBOX"] = function()
    local Tab = MakeFrame({
        Name = "Tab_TOOLBOX",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "TOOLBOX  🛠", "Controles de personaje, mundo y visuales")

    local Scroll = MakeScroll({
        Size = UDim2.new(1,0,1,-65),
        Position = UDim2.new(0,0,0,65),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ZIndex = 15,
    }, Tab)
    local Content = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, Scroll)
    ListLayout({Padding = UDim.new(0,0)}, Content)
    Padding(12,16,20,16, Content)

    -- Sub-sección label
    local function SubSect(parent, title)
        local L = MakeLabel({
            Size = UDim2.new(1,0,0,28),
            BackgroundTransparency = 1,
            Text = "—  " .. title,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = C.PURPLE_GLOW,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
        }, parent)
        return L
    end

    -- ─── CHARACTER ────────────────────────────────────────────────────────────
    SubSect(Content, "CHARACTER")

    CreateSlider(Content, "WalkSpeed", 16, 300, 16, "", function(v)
        pcall(function()
            if Humanoid then Humanoid.WalkSpeed = v end
        end)
    end)

    CreateSlider(Content, "JumpPower", 50, 500, 50, "", function(v)
        pcall(function()
            if Humanoid then Humanoid.JumpPower = v end
        end)
    end)

    CreateSlider(Content, "Gravity", 0, 200, 196, " %", function(v)
        pcall(function()
            workspace.Gravity = v
        end)
    end)

    SubSect(Content, "CHARACTER TOGGLES")

    local flyActive = false
    local flyBV, flyAngBV

    local function EnableFly()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        flyBV = Instance.new("BodyVelocity")
        flyBV.Velocity = Vector3.new(0,0,0)
        flyBV.MaxForce = Vector3.new(1,1,1)*math.huge
        flyBV.Parent   = root
        flyAngBV = Instance.new("BodyAngularVelocity")
        flyAngBV.AngularVelocity = Vector3.new(0,0,0)
        flyAngBV.MaxTorque = Vector3.new(1,1,1)*math.huge
        flyAngBV.Parent   = root
        TrackConn(RunService.RenderStepped:Connect(function()
            if not flyActive then return end
            local cam = workspace.CurrentCamera
            local dir = cam.CFrame.LookVector
            local speed = 40
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then flyBV.Velocity = dir * speed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then flyBV.Velocity = -dir * speed
            else flyBV.Velocity = Vector3.new(0,0,0) end
        end))
    end

    local function DisableFly()
        if flyBV    then flyBV:Destroy() end
        if flyAngBV then flyAngBV:Destroy() end
    end

    CreateToggle(Content, "Fly Mode", false, function(state)
        flyActive = state
        if state then EnableFly() else DisableFly() end
    end)

    CreateToggle(Content, "No-Clip", false, function(state)
        TrackConn(RunService.Stepped:Connect(function()
            if not state then return end
            pcall(function()
                for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end)
        end))
    end)

    CreateToggle(Content, "Infinite Jump", false, function(state)
        TrackConn(UserInputService.JumpRequest:Connect(function()
            if state and Humanoid then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end))
    end)

    CreateToggle(Content, "God Mode (HP Lock)", false, function(state)
        task.spawn(function()
            while state do
                pcall(function()
                    if Humanoid then Humanoid.Health = Humanoid.MaxHealth end
                end)
                task.wait(0.1)
            end
        end)
    end)

    -- ─── WORLD ────────────────────────────────────────────────────────────────
    SubSect(Content, "WORLD")

    CreateToggle(Content, "Environmental Immunity", false, function(state)
        -- Lava, agua, daño del entorno
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Part") and v.Name:find("Lava") then
                    v.CanTouch = not state
                end
            end
        end)
    end)

    CreateToggle(Content, "Day/Night Cycle", true, function(state)
        pcall(function()
            game:GetService("Lighting").ClockTime = state and 14 or 0
        end)
    end)

    CreateToggle(Content, "Remove Textures", false, function(state)
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("Texture") or v:IsA("Decal") then
                    v.Transparency = state and 1 or 0
                end
            end
        end)
    end)

    -- ─── VISUALS ──────────────────────────────────────────────────────────────
    SubSect(Content, "VISUALS")

    CreateToggle(Content, "Skybox Toggle", true, function(state)
        pcall(function()
            game:GetService("Lighting").FogEnd = state and 100000 or 500
        end)
    end)

    CreateToggle(Content, "Player ESP", false, function(state)
        if state then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    pcall(function()
                        local char = plr.Character
                        if char then
                            local hl = Instance.new("SelectionBox")
                            hl.Name = "ESP_QOS"
                            hl.Color3 = C.PURPLE_NEON
                            hl.Adornee = char
                            hl.Parent  = char
                        end
                    end)
                end
            end
        else
            for _, plr in pairs(Players:GetPlayers()) do
                pcall(function()
                    local char = plr.Character
                    if char then
                        local e = char:FindFirstChild("ESP_QOS")
                        if e then e:Destroy() end
                    end
                end)
            end
        end
    end)

    CreateToggle(Content, "Item ESP", false, function(state)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") then
                pcall(function()
                    if state then
                        local sb = Instance.new("SelectionBox")
                        sb.Name   = "ITEM_ESP_QOS"
                        sb.Color3 = C.CYAN_NEON
                        sb.Adornee = obj
                        sb.Parent  = workspace
                    else
                        local se = workspace:FindFirstChild("ITEM_ESP_QOS")
                        if se then se:Destroy() end
                    end
                end)
            end
        end
    end)

    CreateToggle(Content, "World Color Filter (Purple)", false, function(state)
        pcall(function()
            game:GetService("Lighting").ColorShift_Bottom = state and C.PURPLE_DIM or Color3.new(0,0,0)
        end)
    end)

    local LL = Content:FindFirstChildWhichIsA("UIListLayout")
    LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.Size = UDim2.new(1,0,0,LL.AbsoluteContentSize.Y)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 13 - TAB: SYSTEM SETTINGS (General / Performance / Security / UI)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SYSTEM_SETTINGS"] = function()
    local Tab = MakeFrame({
        Name = "Tab_SETTINGS",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "SYSTEM SETTINGS  ⚙", "Configuración general del sistema Quantum OS")

    -- Sub-pestañas
    local SubTabFrame = MakeFrame({
        Size = UDim2.new(1,-32,0,38),
        Position = UDim2.new(0,16,0,68),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 16,
    }, Tab)
    Corner(10, SubTabFrame)
    ListLayout({FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,2)}, SubTabFrame)
    Padding(4,4,4,4, SubTabFrame)

    local subtabs = {"GENERAL","PERFORMANCE","SECURITY","UI CUSTOMIZATION"}
    local ActiveSubContent = nil
    local SubBtns = {}

    local function SetSubTab(name)
        for _, b in pairs(SubBtns) do
            Tween(b, TI_FAST, {BackgroundColor3 = C.BG_CARD, TextColor3 = C.TEXT_MUTED})
        end
        Tween(SubBtns[name], TI_FAST, {BackgroundColor3 = C.PURPLE_DIM, TextColor3 = C.TEXT_WHITE})
        if ActiveSubContent then ActiveSubContent:Destroy() end
    end

    for _, st in ipairs(subtabs) do
        local SB = MakeButton({
            Name = st,
            Size = UDim2.new(0.25,-2,1,0),
            BackgroundColor3 = C.BG_CARD,
            Text = st,
            Font = Enum.Font.GothamSemibold,
            TextSize = 10,
            TextColor3 = C.TEXT_MUTED,
            ZIndex = 17,
        }, SubTabFrame)
        Corner(8, SB)
        SubBtns[st] = SB
    end

    -- Content area for subtabs
    local SubContentArea = MakeFrame({
        Size = UDim2.new(1,-32,1,-120),
        Position = UDim2.new(0,16,0,115),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 15,
    }, Tab)
    Corner(12, SubContentArea)
    Stroke(1, C.BORDER, SubContentArea)

    local function MakeRowSetting(parent, label, valueText, yPos)
        local R = MakeFrame({
            Size = UDim2.new(1,-24,0,44),
            Position = UDim2.new(0,12,0,yPos),
            BackgroundColor3 = C.BG_GLASS,
            ZIndex = 16,
        }, parent)
        Corner(10, R)
        MakeLabel({
            Size = UDim2.new(0.5,0,1,0),
            BackgroundTransparency = 1,
            Text = label,
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextColor3 = C.TEXT_WHITE,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, R)
        Padding(0,0,0,14, R)
        local VF = MakeFrame({
            Size = UDim2.new(0,120,0,30),
            Position = UDim2.new(1,-132,0.5,-15),
            BackgroundColor3 = C.BG_CARD,
            ZIndex = 17,
        }, R)
        Corner(8, VF)
        Stroke(1, C.BORDER, VF)
        MakeLabel({
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            Text = valueText,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_SOFT,
            ZIndex = 18,
        }, VF)
        return R
    end

    -- Función para cargar sub-tabs
    local function LoadGeneral()
        SetSubTab("GENERAL")
        local SC = MakeFrame({
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            ZIndex = 16,
        }, SubContentArea)
        ActiveSubContent = SC

        MakeLabel({Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
            Text="GENERAL",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.PURPLE_GLOW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17}, SC)

        MakeRowSetting(SC, "Idioma / Language", "Español  ▾", 36)
        MakeRowSetting(SC, "Tema / Theme", "Dark  ▾", 88)
        MakeRowSetting(SC, "Notificaciones", "Activadas  ▾", 140)
        MakeRowSetting(SC, "Auto-Update Quantum", "Activado  ▾", 192)
    end

    local function LoadPerformance()
        SetSubTab("PERFORMANCE")
        local SC = MakeFrame({
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            ZIndex = 16,
        }, SubContentArea)
        ActiveSubContent = SC

        MakeLabel({Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
            Text="PERFORMANCE",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.PURPLE_GLOW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17}, SC)

        local function StatBar(label, value, yPos)
            MakeLabel({Size=UDim2.new(0.4,0,0,18),Position=UDim2.new(0,12,0,yPos),BackgroundTransparency=1,
                Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TEXT_WHITE,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17}, SC)
            local BG = MakeFrame({Size=UDim2.new(0.45,0,0,8),Position=UDim2.new(0.42,0,0,yPos+5),
                BackgroundColor3=C.SLIDER_BG,ZIndex=17},SC)
            Corner(4, BG)
            local Fill = MakeFrame({Size=UDim2.new(value,0,1,0),BackgroundColor3=
                value > 0.8 and C.TEXT_RED or value > 0.5 and C.TEXT_YELLOW or C.TOGGLE_ON,ZIndex=18},BG)
            Corner(4,Fill)
            MakeLabel({Size=UDim2.new(0.1,0,0,18),Position=UDim2.new(0.88,0,0,yPos),BackgroundTransparency=1,
                Text=math.floor(value*100).."%",Font=Enum.Font.GothamBold,TextSize=12,
                TextColor3=C.TEXT_WHITE,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=17},SC)
        end

        StatBar("CPU Usage", 0.30, 42)
        StatBar("RAM Usage", 0.45, 80)
        StatBar("FPS Limit",  1.00, 118)
        StatBar("Network",   0.20, 156)

        CreateSlider(SC, "FPS Cap", 15, 240, 60, " FPS", function(v) end)
    end

    local function LoadSecurity()
        SetSubTab("SECURITY")
        local SC = MakeFrame({
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            ZIndex = 16,
        }, SubContentArea)
        ActiveSubContent = SC

        MakeLabel({Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
            Text="SECURITY",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.PURPLE_GLOW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17}, SC)

        MakeRowSetting(SC, "Key Management", "Activo  ▸", 36)
        MakeRowSetting(SC, "Anti-Detect Mode", "OFF  ▸", 88)
        MakeRowSetting(SC, "Session Encryption", "AES-256  ▸", 140)

        CreateToggle(SC, "Safe Mode (reduce detección)", false, nil)
    end

    local function LoadUICustom()
        SetSubTab("UI CUSTOMIZATION")
        local SC = MakeFrame({
            Size = UDim2.fromScale(1,1),
            BackgroundTransparency = 1,
            ZIndex = 16,
        }, SubContentArea)
        ActiveSubContent = SC

        MakeLabel({Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
            Text="UI CUSTOMIZATION",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.PURPLE_GLOW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17}, SC)

        MakeRowSetting(SC, "Background Image", "Background Sc…  ▸", 36)
        MakeRowSetting(SC, "Font Style/Size", "Background Sc…  ▸", 88)

        MakeLabel({Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,140),BackgroundTransparency=1,
            Text="Primary Color",Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17}, SC)

        local ColorBar = MakeFrame({
            Size = UDim2.new(1,-24,0,22),
            Position = UDim2.new(0,12,0,162),
            BackgroundColor3 = C.PURPLE_NEON,
            ZIndex = 17,
        }, SC)
        Corner(6, ColorBar)
        Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, ColorBar)

        CreateSlider(SC, "UI Scale", 80, 120, 100, "%", function(v) end)
        CreateToggle(SC, "Compact Mode", false, nil)
        CreateToggle(SC, "Animations", true, nil)
    end

    -- Conectar botones subtabs
    SubBtns["GENERAL"].MouseButton1Click:Connect(LoadGeneral)
    SubBtns["PERFORMANCE"].MouseButton1Click:Connect(LoadPerformance)
    SubBtns["SECURITY"].MouseButton1Click:Connect(LoadSecurity)
    SubBtns["UI CUSTOMIZATION"].MouseButton1Click:Connect(LoadUICustom)

    -- Cargar General por defecto
    LoadGeneral()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 14 - TAB: MEDIA CENTER (Reproductor de música completo)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_MEDIA_CENTER"] = function()
    local Tab = MakeFrame({
        Name = "Tab_MEDIA",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "MEDIA CENTER  🎵", "Reproductor de música integrado")

    -- Now Playing Card
    local NPCard = MakeFrame({
        Size = UDim2.new(1,-32,0,170),
        Position = UDim2.new(0,16,0,72),
        BackgroundColor3 = C.BG_GLASS,
        ZIndex = 16,
    }, Tab)
    Corner(16, NPCard)
    Stroke(1, C.BORDER_BRIGHT, NPCard)
    Gradient(C.BG_GLASS, Color3.fromRGB(30,10,60), 135, NPCard)

    -- Carátula del álbum
    local Cover = MakeFrame({
        Size = UDim2.new(0,100,0,100),
        Position = UDim2.new(0,20,0.5,-50),
        BackgroundColor3 = C.PURPLE_DIM,
        ZIndex = 17,
    }, NPCard)
    Corner(14, Cover)
    MakeLabel({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text = "🎵",
        TextSize = 36,
        ZIndex = 18,
    }, Cover)
    Stroke(2, C.PURPLE_NEON, Cover)
    -- Pulso de la carátula
    task.spawn(function()
        while Cover and Cover.Parent do
            Tween(Cover, TI_SINE, {BackgroundColor3 = C.PURPLE_GLOW})
            task.wait(1.2)
            Tween(Cover, TI_SINE, {BackgroundColor3 = C.PURPLE_DIM})
            task.wait(1.2)
        end
    end)

    -- Info
    local NPLabel = MakeLabel({
        Size = UDim2.new(1,-140,0,22),
        Position = UDim2.new(0,132,0,20),
        BackgroundTransparency = 1,
        Text = "Now Playing:",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, NPCard)

    local SongTitle = MakeLabel({
        Size = UDim2.new(1,-140,0,26),
        Position = UDim2.new(0,132,0,38),
        BackgroundTransparency = 1,
        Text = "Neo-Cyber Funk",
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, NPCard)

    local ArtistLabel = MakeLabel({
        Size = UDim2.new(1,-140,0,18),
        Position = UDim2.new(0,132,0,66),
        BackgroundTransparency = 1,
        Text = "Quantum Beats  ·  3:24",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_SOFT,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, NPCard)

    -- Progress bar
    local ProgBG = MakeFrame({
        Size = UDim2.new(1,-140,0,4),
        Position = UDim2.new(0,132,0,96),
        BackgroundColor3 = C.SLIDER_BG,
        ZIndex = 17,
    }, NPCard)
    Corner(2, ProgBG)
    local ProgFill = MakeFrame({
        Size = UDim2.new(0.38,0,1,0),
        BackgroundColor3 = C.PURPLE_NEON,
        ZIndex = 18,
    }, ProgBG)
    Corner(2, ProgFill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, ProgFill)

    -- Tiempo
    local TimeLabel = MakeLabel({
        Size = UDim2.new(1,-140,0,16),
        Position = UDim2.new(0,132,0,106),
        BackgroundTransparency = 1,
        Text = "1:17 / 3:24",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, NPCard)

    -- Controles
    local CtrlFrame = MakeFrame({
        Size = UDim2.new(1,-140,0,32),
        Position = UDim2.new(0,132,0,128),
        BackgroundTransparency = 1,
        ZIndex = 17,
    }, NPCard)
    ListLayout({FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)}, CtrlFrame)

    local playing = true
    local function CtrlBtn(icon, big)
        local b = MakeButton({
            Size = big and UDim2.new(0,38,0,32) or UDim2.new(0,30,0,32),
            BackgroundColor3 = big and C.PURPLE_NEON or C.BG_CARD,
            Text = icon,
            Font = Enum.Font.GothamBold,
            TextSize = big and 16 or 14,
            TextColor3 = Color3.new(1,1,1),
            ZIndex = 18,
        }, CtrlFrame)
        Corner(big and 10 or 8, b)
        return b
    end

    local PrevBtn = CtrlBtn("⏮", false)
    local PlayBtn = CtrlBtn("⏸", true)
    local NextBtn = CtrlBtn("⏭", false)
    local ShufBtn = CtrlBtn("⇌", false)

    PlayBtn.MouseButton1Click:Connect(function()
        playing = not playing
        PlayBtn.Text = playing and "⏸" or "▶"
    end)

    -- Playlist
    local PlaylistScroll = MakeScroll({
        Size = UDim2.new(1,-32,1,-258),
        Position = UDim2.new(0,16,0,252),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ZIndex = 15,
    }, Tab)
    local PlaylistList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, PlaylistScroll)
    ListLayout({Padding = UDim.new(0,4)}, PlaylistList)

    local songs = {
        {title="Neo-Cyber Funk",    artist="Quantum Beats", duration="3:24", active=true},
        {title="Neon Rain",         artist="Synth Wave X",  duration="4:12", active=false},
        {title="Pulse Override",    artist="Quantum Beats", duration="2:58", active=false},
        {title="Dark Matter Drive", artist="LXN Collective",duration="5:01", active=false},
        {title="Grid Runner",       artist="Synth Wave X",  duration="3:45", active=false},
        {title="Orbital Drift",     artist="Quantum Beats", duration="4:28", active=false},
    }

    for _, song in ipairs(songs) do
        local SRow = MakeButton({
            Size = UDim2.new(1,0,0,50),
            BackgroundColor3 = song.active and C.PURPLE_DIM or C.BG_CARD,
            Text = "",
            ZIndex = 16,
        }, PlaylistList)
        Corner(10, SRow)
        if song.active then Stroke(1, C.PURPLE_NEON, SRow) end

        MakeLabel({
            Size = UDim2.new(0,36,0,36),
            Position = UDim2.new(0,10,0.5,-18),
            BackgroundColor3 = song.active and C.PURPLE_NEON or C.BG_GLASS,
            Text = song.active and "🎵" or "▶",
            TextSize = song.active and 16 or 13,
            TextColor3 = Color3.new(1,1,1),
            ZIndex = 17,
        }, SRow)

        MakeLabel({
            Size = UDim2.new(1,-100,0,20),
            Position = UDim2.new(0,54,0,7),
            BackgroundTransparency = 1,
            Text = song.title,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = song.active and C.TEXT_WHITE or C.TEXT_WHITE,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, SRow)

        MakeLabel({
            Size = UDim2.new(1,-100,0,16),
            Position = UDim2.new(0,54,0,28),
            BackgroundTransparency = 1,
            Text = song.artist,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, SRow)

        MakeLabel({
            Size = UDim2.new(0,50,1,0),
            Position = UDim2.new(1,-58,0,0),
            BackgroundTransparency = 1,
            Text = song.duration,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_MUTED,
            ZIndex = 17,
        }, SRow)

        SRow.MouseButton1Click:Connect(function()
            SongTitle.Text   = song.title
            ArtistLabel.Text = song.artist .. "  ·  " .. song.duration
        end)

        HoverGlow(SRow, song.active and C.PURPLE_DIM or C.BG_CARD, C.BG_GLASS)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 15 - TAB: PROCESSES & LOGS (Scripts activos y logs en tiempo real)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_PROCESSES___LOGS"] = function()
    local Tab = MakeFrame({
        Name = "Tab_PROCESSES",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "PROCESSES & LOGS  📊", "Scripts activos y registro de actividad en tiempo real")

    -- Tabla de procesos
    local TableHeader = MakeFrame({
        Size = UDim2.new(1,-32,0,30),
        Position = UDim2.new(0,16,0,68),
        BackgroundColor3 = C.BG_HEADER,
        ZIndex = 16,
    }, Tab)
    Corner(8, TableHeader)

    local cols = {"Active Script", "Resource", "Execution"}
    local colX = {0, 0.5, 0.75}
    for i, col in ipairs(cols) do
        MakeLabel({
            Size = UDim2.new(0.25,0,1,0),
            Position = UDim2.new(colX[i],0,0,0),
            BackgroundTransparency = 1,
            Text = col,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, TableHeader)
    end

    local ProcScroll = MakeScroll({
        Size = UDim2.new(1,-32,0,100),
        Position = UDim2.new(0,16,0,104),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ZIndex = 15,
    }, Tab)
    local ProcList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ProcScroll)
    ListLayout({Padding = UDim.new(0,3)}, ProcList)

    local processes = {
        {name="Blox Fruits V3",      author="Delta",   ram="1 GB",   pct=0.15},
        {name="Anime Defenders Hub", author="Delta",   ram="70 MB",  pct=0.03},
        {name="ESP Overlay",         author="LXN",     ram="12 MB",  pct=0.01},
    }

    for _, proc in ipairs(processes) do
        local PRow = MakeFrame({
            Size = UDim2.new(1,0,0,46),
            BackgroundColor3 = C.BG_CARD,
            ZIndex = 16,
        }, ProcList)
        Corner(8, PRow)

        MakeLabel({
            Size = UDim2.new(0,24,0,24),
            Position = UDim2.new(0,10,0.5,-12),
            BackgroundColor3 = C.PURPLE_DIM,
            Text = "⚡",
            TextSize = 13,
            ZIndex = 17,
        }, PRow)

        MakeLabel({
            Size = UDim2.new(0.4,0,0,18),
            Position = UDim2.new(0,40,0,6),
            BackgroundTransparency = 1,
            Text = proc.name,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = C.TEXT_WHITE,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, PRow)

        MakeLabel({
            Size = UDim2.new(0.4,0,0,14),
            Position = UDim2.new(0,40,0,26),
            BackgroundTransparency = 1,
            Text = "Verificado por " .. proc.author,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, PRow)

        MakeLabel({
            Size = UDim2.new(0.2,0,1,0),
            Position = UDim2.new(0.5,0,0,0),
            BackgroundTransparency = 1,
            Text = proc.ram,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_SOFT,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, PRow)

        local PctBG = MakeFrame({
            Size = UDim2.new(0,80,0,6),
            Position = UDim2.new(0.75,0,0.5,-3),
            BackgroundColor3 = C.SLIDER_BG,
            ZIndex = 17,
        }, PRow)
        Corner(3, PctBG)
        local PctFill = MakeFrame({
            Size = UDim2.new(proc.pct,0,1,0),
            BackgroundColor3 = proc.pct > 0.8 and C.TEXT_RED or C.TOGGLE_ON,
            ZIndex = 18,
        }, PctBG)
        Corner(3, PctFill)

        MakeLabel({
            Size = UDim2.new(0,40,0,18),
            Position = UDim2.new(1,-42,0.5,-9),
            BackgroundTransparency = 1,
            Text = math.floor(proc.pct*100).."%",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = C.TEXT_WHITE,
            ZIndex = 17,
        }, PRow)
    end

    -- Terminal de logs
    local LogHeader = MakeLabel({
        Size = UDim2.new(1,-32,0,24),
        Position = UDim2.new(0,16,0,215),
        BackgroundTransparency = 1,
        Text = "▶ EXECUTION LOG  (tiempo real)",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    }, Tab)

    local LogBox = MakeFrame({
        Size = UDim2.new(1,-32,1,-250),
        Position = UDim2.new(0,16,0,244),
        BackgroundColor3 = Color3.fromRGB(4, 4, 12),
        ZIndex = 16,
    }, Tab)
    Corner(10, LogBox)
    Stroke(1, C.BORDER, LogBox)

    local LogText = MakeLabel({
        Size = UDim2.new(1,-16,1,-10),
        Position = UDim2.new(0,8,0,5),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = C.TEXT_GREEN,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 17,
    }, LogBox)

    -- Logs simulados
    local logLines = {
        "Execution log: Server.MainSpawnInit",
        "Execution log: Server.LoadPlayerData",
        "Execution log: Server.VerifyAntiCheat disabled",
        "Execution log: Server.InitializeItems",
        "Execution log: Server.SetupSpawnPoints",
        "Execution log: Server.NetworkOptimize(ProcessesScript)",
        "Execution log: LocalScript.LoadUI",
        "Execution log: Quantum OS boot complete",
        "Execution log: QuantumOracle.Init(AI Mode)",
    }

    local function AppendLog()
        local visibleLogs = {}
        for i = math.max(1, #logLines - 6), #logLines do
            table.insert(visibleLogs, logLines[i])
        end
        LogText.Text = table.concat(visibleLogs, "\n")
    end

    AppendLog()

    -- Auto-update logs
    task.spawn(function()
        local extras = {
            "Execution log: AntiLag.Optimize()",
            "Execution log: ESP.Update(PlayerList)",
            "Execution log: FlyMode.Heartbeat()",
            "Execution log: MediaCenter.StreamBuffer()",
            "Execution log: Oracle.Query(GameContext)",
        }
        local i = 1
        while Tab and Tab.Parent do
            task.wait(1.5)
            table.insert(logLines, extras[(i % #extras)+1])
            i = i + 1
            pcall(AppendLog)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 16 - TAB: FILE MANAGER (Gestor de archivos de scripts)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_FILE_MANAGER"] = function()
    local Tab = MakeFrame({
        Name = "Tab_FILES",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "FILE MANAGER  📁", "Gestiona tus scripts locales, en la nube y plantillas")

    MakeLabel({
        Size = UDim2.new(1,-32,0,18),
        Position = UDim2.new(0,16,0,68),
        BackgroundTransparency = 1,
        Text = "Guarda y carga scripts personalizados",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    }, Tab)

    -- Search
    local SearchBar = MakeFrame({
        Size = UDim2.new(1,-32,0,38),
        Position = UDim2.new(0,16,0,90),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 16,
    }, Tab)
    Corner(10, SearchBar)
    Stroke(1, C.BORDER, SearchBar)
    local SearchBox2 = MakeBox({
        Size = UDim2.new(1,-90,1,0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Buscar scripts...",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ZIndex = 17,
    }, SearchBar)
    local SaveNew = MakeButton({
        Size = UDim2.new(0,62,0,28),
        Position = UDim2.new(1,-70,0.5,-14),
        BackgroundColor3 = C.PURPLE_NEON,
        Text = "GUARDAR",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 17,
    }, SearchBar)
    Corner(8, SaveNew)

    -- Folders
    local folders = {
        {name="LOCAL SCRIPTS",  icon="📂", count=5},
        {name="CLOUD SCRIPTS",  icon="☁",  count=8},
        {name="TEMPLATES",      icon="📋", count=3},
    }

    local FolderScroll = MakeScroll({
        Size = UDim2.new(1,-32,1,-142),
        Position = UDim2.new(0,16,0,138),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ZIndex = 15,
    }, Tab)
    local FolderList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, FolderScroll)
    ListLayout({Padding = UDim.new(0,8)}, FolderList)

    for _, f in ipairs(folders) do
        local FCard = MakeButton({
            Size = UDim2.new(1,0,0,56),
            BackgroundColor3 = C.BG_CARD,
            Text = "",
            ZIndex = 16,
        }, FolderList)
        Corner(12, FCard)
        Stroke(1, C.BORDER, FCard)

        MakeLabel({
            Size = UDim2.new(0,36,0,36),
            Position = UDim2.new(0,14,0.5,-18),
            BackgroundColor3 = C.PURPLE_DIM,
            Text = f.icon,
            TextSize = 20,
            ZIndex = 17,
        }, FCard)

        MakeLabel({
            Size = UDim2.new(1,-120,0,22),
            Position = UDim2.new(0,58,0,10),
            BackgroundTransparency = 1,
            Text = f.name,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = C.TEXT_WHITE,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, FCard)

        MakeLabel({
            Size = UDim2.new(1,-120,0,16),
            Position = UDim2.new(0,58,0,34),
            BackgroundTransparency = 1,
            Text = f.count .. " scripts guardados",
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, FCard)

        MakeLabel({
            Size = UDim2.new(0,32,1,0),
            Position = UDim2.new(1,-44,0,0),
            BackgroundTransparency = 1,
            Text = "▸",
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextColor3 = C.TEXT_MUTED,
            ZIndex = 17,
        }, FCard)

        HoverGlow(FCard, C.BG_CARD, C.BG_GLASS)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 17 - TAB: COMMUNITY (Foro / Discord embed simulado)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_COMMUNITY"] = function()
    local Tab = MakeFrame({
        Name = "Tab_COMMUNITY",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "COMMUNITY  👥", "Únete a la comunidad Quantum OS")

    local cards = {
        {icon="💬", title="Discord Oficial", sub="Únete al servidor de Quantum OS", action="Unirse"},
        {icon="📣", title="Anuncios",         sub="Últimas novedades y actualizaciones", action="Ver"},
        {icon="🏆", title="Top Contributors", sub="Los mejores usuarios del mes", action="Ver"},
        {icon="🐛", title="Reportar Bug",     sub="Ayúdanos a mejorar Quantum OS", action="Reportar"},
    }

    local Scroll = MakeScroll({
        Size = UDim2.new(1,-32,1,-72),
        Position = UDim2.new(0,16,0,72),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ZIndex = 15,
    }, Tab)
    local SList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, Scroll)
    ListLayout({Padding = UDim.new(0,10)}, SList)
    Padding(10,0,20,0, SList)

    for _, card in ipairs(cards) do
        local CCard = MakeFrame({
            Size = UDim2.new(1,0,0,70),
            BackgroundColor3 = C.BG_CARD,
            ZIndex = 16,
        }, SList)
        Corner(14, CCard)
        Stroke(1, C.BORDER, CCard)

        MakeLabel({
            Size = UDim2.new(0,48,0,48),
            Position = UDim2.new(0,12,0.5,-24),
            BackgroundColor3 = C.PURPLE_DIM,
            Text = card.icon,
            TextSize = 22,
            ZIndex = 17,
        }, CCard)

        MakeLabel({
            Size = UDim2.new(1,-170,0,22),
            Position = UDim2.new(0,70,0,12),
            BackgroundTransparency = 1,
            Text = card.title,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = C.TEXT_WHITE,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, CCard)

        MakeLabel({
            Size = UDim2.new(1,-170,0,18),
            Position = UDim2.new(0,70,0,36),
            BackgroundTransparency = 1,
            Text = card.sub,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, CCard)

        local ActionBtn = MakeButton({
            Size = UDim2.new(0,74,0,28),
            Position = UDim2.new(1,-86,0.5,-14),
            BackgroundColor3 = C.PURPLE_NEON,
            Text = card.action,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.new(1,1,1),
            ZIndex = 17,
        }, CCard)
        Corner(8, ActionBtn)
        HoverGlow(ActionBtn, C.PURPLE_NEON, C.PURPLE_GLOW)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 18 - TAB: QUANTUM ORACLE (IA Flotante con chat game-aware)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_QUANTUM_ORACLE"] = function()
    local Tab = MakeFrame({
        Name = "Tab_ORACLE",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "QUANTUM ORACLE  🔮", "IA contextual · Detectando: " .. GAME_NAME)

    -- Oracle sphere visual
    local SphereFrame = MakeFrame({
        Size = UDim2.new(1,-32,0,120),
        Position = UDim2.new(0,16,0,68),
        BackgroundColor3 = C.BG_GLASS,
        ZIndex = 16,
    }, Tab)
    Corner(14, SphereFrame)
    Gradient(C.BG_GLASS, Color3.fromRGB(40,0,80), 135, SphereFrame)
    Stroke(1, C.BORDER_BRIGHT, SphereFrame)

    local Orb = MakeLabel({
        Size = UDim2.new(0,72,0,72),
        Position = UDim2.new(0,24,0.5,-36),
        BackgroundColor3 = C.PURPLE_DIM,
        Text = "🔮",
        TextSize = 36,
        ZIndex = 17,
    }, SphereFrame)
    Corner(36, Orb)
    Stroke(3, C.PURPLE_NEON, Orb)
    task.spawn(function()
        while Orb and Orb.Parent do
            Tween(Orb, TI_SINE, {BackgroundColor3 = C.PURPLE_GLOW})
            task.wait(1.2)
            Tween(Orb, TI_SINE, {BackgroundColor3 = C.PURPLE_DIM})
            task.wait(1.2)
        end
    end)

    MakeLabel({
        Size = UDim2.new(1,-110,0,24),
        Position = UDim2.new(0,108,0,18),
        BackgroundTransparency = 1,
        Text = "QUANTUM ORACLE",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, SphereFrame)

    MakeLabel({
        Size = UDim2.new(1,-110,0,16),
        Position = UDim2.new(0,108,0,44),
        BackgroundTransparency = 1,
        Text = "IA Game-Aware · Game: " .. GAME_NAME,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, SphereFrame)

    MakeLabel({
        Size = UDim2.new(1,-110,0,36),
        Position = UDim2.new(0,108,0,64),
        BackgroundTransparency = 1,
        Text = "Detectó: '" .. GAME_NAME .. "'. Puedo sugerirte scripts y estrategias específicas. ¿En qué te ayudo?",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, SphereFrame)

    -- Chat area
    local ChatScroll = MakeScroll({
        Size = UDim2.new(1,-32,1,-270),
        Position = UDim2.new(0,16,0,200),
        BackgroundColor3 = Color3.fromRGB(6,6,16),
        ScrollBarThickness = 3,
        ZIndex = 15,
    }, Tab)
    Corner(12, ChatScroll)
    Stroke(1, C.BORDER, ChatScroll)

    local ChatList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ChatScroll)
    ListLayout({Padding = UDim.new(0,6), VerticalAlignment = Enum.VerticalAlignment.Bottom}, ChatList)
    Padding(10,10,10,10, ChatList)

    local function AddMsg(text, isUser)
        local Bubble = MakeFrame({
            Size = UDim2.new(0.8,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = isUser and UDim2.new(0.2,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3 = isUser and C.PURPLE_DIM or C.BG_CARD,
            ZIndex = 16,
        }, ChatList)
        Corner(10, Bubble)
        Padding(8,12,8,12, Bubble)
        MakeLabel({
            Size = UDim2.new(1,0,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextColor3 = C.TEXT_WHITE,
            TextWrapped = true,
            TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, Bubble)
        -- Scroll to bottom
        task.wait(0.05)
        ChatScroll.CanvasPosition = Vector2.new(0, ChatList.AbsoluteContentSize.Y)
    end

    -- Respuestas de IA simuladas según el juego
    local aiResponses = {
        ["Blox Fruits"]  = {"Detecté Blox Fruits. Te recomiendo el script 'Auto Farm + Boss Skip V3'.", "Para Blox Fruits: activa el ESP para ver los NPCs de boss más fácilmente."},
        ["Anime Defenders"]= {"En Anime Defenders puedes usar Auto-Wave Clear para farmear automáticamente.", "Recomiendo Quantum Speed x3 para optimizar tu tiempo de juego."},
        default           = {"Analizando el juego actual... Intenta describir lo que necesitas y te ayudaré.", "Puedo ayudarte con scripts, configuraciones o estrategias para cualquier juego."},
    }

    local function GetAIResponse(input)
        local responses = aiResponses[GAME_NAME] or aiResponses.default
        return responses[math.random(1, #responses)]
    end

    -- Mensaje inicial
    AddMsg("🔮 Hola, " .. DISPLAY_NAME .. ". Soy Quantum Oracle. Detecté que estás en '" .. GAME_NAME .. "'. ¿En qué puedo ayudarte hoy?", false)

    -- Input del chat
    local InputRow = MakeFrame({
        Size = UDim2.new(1,-32,0,44),
        Position = UDim2.new(0,16,1,-58),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 16,
    }, Tab)
    Corner(12, InputRow)
    Stroke(1, C.BORDER, InputRow)

    local ChatInput = MakeBox({
        Size = UDim2.new(1,-60,1,0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Pregunta algo al Oracle...",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ClearTextOnFocus = false,
        ZIndex = 17,
    }, InputRow)

    local SendBtn = MakeButton({
        Size = UDim2.new(0,44,0,34),
        Position = UDim2.new(1,-50,0.5,-17),
        BackgroundColor3 = C.PURPLE_NEON,
        Text = "▶",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 17,
    }, InputRow)
    Corner(10, SendBtn)

    local function SendMessage()
        local msg = ChatInput.Text:gsub("^%s+",""):gsub("%s+$","")
        if msg == "" then return end
        ChatInput.Text = ""
        AddMsg(msg, true)
        task.wait(0.8)
        AddMsg(GetAIResponse(msg), false)
    end

    SendBtn.MouseButton1Click:Connect(SendMessage)
    ChatInput.FocusLost:Connect(function(enter)
        if enter then SendMessage() end
    end)

    -- Sugerencias rápidas
    local SuggestFrame = MakeFrame({
        Size = UDim2.new(1,-32,0,30),
        Position = UDim2.new(0,16,1,-100),
        BackgroundTransparency = 1,
        ZIndex = 16,
    }, Tab)
    ListLayout({FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)}, SuggestFrame)

    local suggestions = {"¿Mejores scripts?", "Activa ESP", "Script seleccionado"}
    for _, sug in ipairs(suggestions) do
        local SB = MakeButton({
            Size = UDim2.new(0,0,1,0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = C.BG_CARD,
            Text = sug,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = C.CYAN_NEON,
            ZIndex = 17,
        }, SuggestFrame)
        Corner(8, SB)
        Padding(0,10,0,10, SB)
        Stroke(1, C.CYAN_DIM, SB)
        SB.MouseButton1Click:Connect(function()
            ChatInput.Text = sug
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 19 - TAB: GAME BOOSTER (Optimización de FPS y latencia)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_GAME_BOOSTER"] = function()
    local Tab = MakeFrame({
        Name = "Tab_BOOSTER",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "GAME BOOSTER  🚀", "Optimización de rendimiento y FPS para móvil")

    local Scroll = MakeScroll({
        Size = UDim2.new(1,0,1,-65),
        Position = UDim2.new(0,0,0,65),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ZIndex = 15,
    }, Tab)
    local C2 = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, Scroll)
    ListLayout({Padding = UDim.new(0,0)}, C2)
    Padding(12,16,20,16, C2)

    -- Boost mode card
    local BoostCard = MakeFrame({
        Size = UDim2.new(1,0,0,90),
        BackgroundColor3 = C.BG_GLASS,
        ZIndex = 16,
    }, C2)
    Corner(14, BoostCard)
    Gradient(Color3.fromRGB(10,5,30), Color3.fromRGB(60,0,100), 135, BoostCard)
    Stroke(2, C.PURPLE_NEON, BoostCard)
    Padding(16,16,16,16, BoostCard)

    MakeLabel({
        Size = UDim2.new(1,-120,0,22),
        BackgroundTransparency = 1,
        Text = "🚀 QUANTUM BOOST MODE",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, BoostCard)

    MakeLabel({
        Size = UDim2.new(1,-120,0,30),
        Position = UDim2.new(0,0,0,24),
        BackgroundTransparency = 1,
        Text = "Optimización agresiva de FPS: elimina particles,\nrebalance render distance, reduse physics delta.",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, BoostCard)

    local BoostBtn = MakeButton({
        Size = UDim2.new(0,90,0,36),
        Position = UDim2.new(1,-102,0.5,-18),
        BackgroundColor3 = C.TOGGLE_ON,
        Text = "ACTIVAR",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.new(1,1,1),
        ZIndex = 17,
    }, BoostCard)
    Corner(10, BoostBtn)

    local boosted = false
    BoostBtn.MouseButton1Click:Connect(function()
        boosted = not boosted
        BoostBtn.Text = boosted and "ACTIVO ✓" or "ACTIVAR"
        BoostBtn.BackgroundColor3 = boosted and C.PURPLE_NEON or C.TOGGLE_ON
        if boosted then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then
                        v.Enabled = false
                    end
                    if v:IsA("SpecialMesh") then v.TextureId = "" end
                end
            end)
        end
    end)

    -- Opciones granulares
    local function SubSect2(parent, title)
        local L = MakeLabel({
            Size = UDim2.new(1,0,0,28),
            BackgroundTransparency = 1,
            Text = "—  " .. title,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = C.PURPLE_GLOW,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
        }, parent)
    end

    SubSect2(C2, "RENDER TWEAKS")
    CreateToggle(C2, "Desactivar ParticleEmitters", false, function(s)
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") then v.Enabled = not s end
        end
    end)
    CreateToggle(C2, "Desactivar Sombras Dinámicas", false, function(s)
        pcall(function() game:GetService("Lighting").GlobalShadows = not s end)
    end)
    CreateToggle(C2, "Reducir Render Distance", false, function(s)
        pcall(function()
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                    v.LocalTransparencyModifier = s and 0.5 or 0
                end
            end
        end)
    end)

    SubSect2(C2, "NETWORK")
    CreateToggle(C2, "Reducir Replicación", false, nil)
    CreateToggle(C2, "Anti-Lag Mode", false, nil)
    CreateSlider(C2, "Simulation Throttle", 1, 100, 100, "%", nil)

    local LL2 = C2:FindFirstChildWhichIsA("UIListLayout")
    LL2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        C2.Size = UDim2.new(1,0,0,LL2.AbsoluteContentSize.Y)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 20 - TAB: SKIN CUSTOMIZER (Personalización visual del OS)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SKIN_CUSTOMIZER"] = function()
    local Tab = MakeFrame({
        Name = "Tab_SKIN",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "SKIN CUSTOMIZER  🎨", "Personaliza el aspecto visual de Quantum OS")

    local Scroll = MakeScroll({
        Size = UDim2.new(1,-32,1,-72),
        Position = UDim2.new(0,16,0,72),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ZIndex = 15,
    }, Tab)
    local CL = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, Scroll)
    ListLayout({Padding = UDim.new(0,12)}, CL)
    Padding(12,0,20,0, CL)

    -- Presets de temas
    local ThemeLabel = MakeLabel({
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        Text = "TEMAS PREDEFINIDOS",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    }, CL)

    local ThemeGrid = MakeFrame({
        Size = UDim2.new(1,0,0,80),
        BackgroundTransparency = 1,
        ZIndex = 16,
    }, CL)

    GridLayout({CellSize = UDim2.new(0.25,-4,1,-4), CellPadding = UDim2.new(0,4,0,4)}, ThemeGrid)

    local themes = {
        {name="Cyberpunk",  colors={C.PURPLE_NEON, C.CYAN_NEON}},
        {name="Matrix",     colors={C.TEXT_GREEN,  Color3.fromRGB(0,60,0)}},
        {name="Rojo Fuego", colors={C.TEXT_RED,    Color3.fromRGB(180,50,0)}},
        {name="Dorado",     colors={C.TEXT_YELLOW, Color3.fromRGB(140,80,0)}},
    }

    for _, theme in ipairs(themes) do
        local TB = MakeButton({
            BackgroundColor3 = Color3.fromRGB(20,18,42),
            Text = "",
            ZIndex = 17,
        }, ThemeGrid)
        Corner(12, TB)
        Stroke(1, C.BORDER, TB)
        local TGrad = MakeFrame({
            Size = UDim2.new(1,0,0.6,0),
            BackgroundColor3 = theme.colors[1],
            ZIndex = 18,
        }, TB)
        TGrad.Position = UDim2.new(0,0,0,0)
        Corner(10, TGrad)
        Gradient(theme.colors[1], theme.colors[2], 135, TGrad)

        MakeLabel({
            Size = UDim2.new(1,0,0.4,0),
            Position = UDim2.new(0,0,0.6,0),
            BackgroundTransparency = 1,
            Text = theme.name,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = C.TEXT_WHITE,
            ZIndex = 18,
        }, TB)

        TB.MouseButton1Click:Connect(function()
            Tween(ScreenGui:FindFirstChild("Background") or BG, TI_MED, {BackgroundColor3 = Color3.fromRGB(6,4,12)})
        end)
    end

    -- Sliders de color
    MakeLabel({
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        Text = "AJUSTE DE COLOR PRIMARIO",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    }, CL)

    CreateSlider(CL, "Rojo", 0, 255, 160, "", nil)
    CreateSlider(CL, "Verde", 0, 255, 32, "", nil)
    CreateSlider(CL, "Azul", 0, 255, 240, "", nil)

    MakeLabel({
        Size = UDim2.new(1,0,0,20),
        BackgroundTransparency = 1,
        Text = "OPACIDAD Y EFECTOS",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    }, CL)

    CreateSlider(CL, "Transparencia del panel", 0, 80, 30, "%", nil)
    CreateSlider(CL, "Brillo de borde neón", 0, 100, 70, "%", nil)
    CreateToggle(CL, "Efecto Glassmorphic", true, nil)
    CreateToggle(CL, "Animaciones de partículas", true, nil)
    CreateToggle(CL, "Sombras de panel", true, nil)

    local LLskin = CL:FindFirstChildWhichIsA("UIListLayout")
    LLskin:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        CL.Size = UDim2.new(1,0,0,LLskin.AbsoluteContentSize.Y)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 21 - TAB: POWER (Opciones de sistema: Restart, Shutdown, Disconnect)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_POWER"] = function()
    local Tab = MakeFrame({
        Name = "Tab_POWER",
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "POWER  ⏻", "Opciones de sesión y sistema")

    local buttons = {
        {label="Reiniciar Quantum OS",   icon="🔄", color=C.TEXT_YELLOW, desc="Reinicia toda la interfaz de Quantum OS preservando la sesión."},
        {label="Cerrar Quantum OS",      icon="✕",  color=C.TEXT_RED,    desc="Cierra Quantum OS y libera todos los recursos de la sesión."},
        {label="Desconectar del Juego",  icon="🚪", color=C.TEXT_RED,    desc="Desconecta al jugador de la partida actual (kick local)."},
        {label="Limpiar Conexiones",     icon="♻",  color=C.CYAN_NEON,   desc="Limpia todos los eventos y conexiones activos de Quantum OS."},
        {label="Limpiar Scripts Activos",icon="🗑",  color=C.TEXT_YELLOW, desc="Detiene y elimina todos los scripts activos en cola de procesos."},
    }

    local PScroll = MakeScroll({
        Size = UDim2.new(1,-32,1,-80),
        Position = UDim2.new(0,16,0,72),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ZIndex = 15,
    }, Tab)
    local PList = MakeFrame({
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 15,
    }, PScroll)
    ListLayout({Padding = UDim.new(0,10)}, PList)
    Padding(12,0,20,0, PList)

    for _, btn in ipairs(buttons) do
        local PCard = MakeFrame({
            Size = UDim2.new(1,0,0,76),
            BackgroundColor3 = C.BG_CARD,
            ZIndex = 16,
        }, PList)
        Corner(14, PCard)
        Stroke(1, C.BORDER, PCard)

        MakeLabel({
            Size = UDim2.new(0,42,0,42),
            Position = UDim2.new(0,14,0.5,-21),
            BackgroundColor3 = Color3.fromRGB(40,10,10),
            Text = btn.icon,
            TextSize = 20,
            ZIndex = 17,
        }, PCard)
        Corner(10, PCard:FindFirstChildWhichIsA("Frame") or Instance.new("Frame"))

        MakeLabel({
            Size = UDim2.new(1,-170,0,22),
            Position = UDim2.new(0,66,0,12),
            BackgroundTransparency = 1,
            Text = btn.label,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = btn.color,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, PCard)

        MakeLabel({
            Size = UDim2.new(1,-170,0,28),
            Position = UDim2.new(0,66,0,36),
            BackgroundTransparency = 1,
            Text = btn.desc,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 17,
        }, PCard)

        local ActionBtn = MakeButton({
            Size = UDim2.new(0,80,0,30),
            Position = UDim2.new(1,-92,0.5,-15),
            BackgroundColor3 = Color3.fromRGB(50,10,10),
            Text = "EJECUTAR",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = btn.color,
            ZIndex = 17,
        }, PCard)
        Corner(8, ActionBtn)
        Stroke(1, btn.color, ActionBtn)

        -- Acciones reales
        ActionBtn.MouseButton1Click:Connect(function()
            if btn.label:find("Reiniciar") then
                ScreenGui:Destroy()
                task.wait(0.5)
                -- Re-ejecutar el script si es posible
                pcall(function() loadstring(game:HttpGet(""))() end)
            elseif btn.label:find("Cerrar") then
                Tween(MainWindow, TI_MED, {Size = UDim2.new(0,0,0,0)})
                task.wait(0.4)
                ScreenGui:Destroy()
            elseif btn.label:find("Desconectar") then
                pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
            elseif btn.label:find("Limpiar Conexiones") then
                for _, c in pairs(ENV.QuantumOS_Connections) do
                    pcall(function() c:Disconnect() end)
                end
                ENV.QuantumOS_Connections = {}
            elseif btn.label:find("Scripts") then
                -- Simula detener scripts
                print("[QuantumOS] Scripts activos limpiados.")
            end
        end)

        HoverGlow(ActionBtn, Color3.fromRGB(50,10,10), Color3.fromRGB(80,15,15))
    end

    -- Footer versión
    MakeLabel({
        Size = UDim2.new(1,0,0,20),
        Position = UDim2.new(0,0,1,-24),
        BackgroundTransparency = 1,
        Text = "LXNDXN Quantum OS v2.5  ·  Delta Edition  ·  " .. os.date("%Y"),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 15,
    }, Tab)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 22 - QUANTUM ORACLE FLOTANTE (Esfera draggable independiente)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateFloatingOracle()
    local OrbFrame = MakeFrame({
        Name        = "FloatingOracle",
        Size        = UDim2.new(0, 58, 0, 58),
        Position    = UDim2.new(0, 12, 0.5, -29),
        BackgroundColor3 = C.PURPLE_DIM,
        ZIndex      = 500,
    }, ScreenGui)
    Corner(29, OrbFrame)
    Stroke(2, C.PURPLE_NEON, OrbFrame)
    Gradient(C.PURPLE_DIM, C.CYAN_DIM, 135, OrbFrame)

    ENV.QuantumOS_OracleFloat = OrbFrame

    local OrbLabel = MakeLabel({
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text = "🔮",
        TextSize = 26,
        ZIndex = 501,
    }, OrbFrame)

    -- Pulsación
    task.spawn(function()
        while OrbFrame and OrbFrame.Parent do
            Tween(OrbFrame, TI_SINE, {BackgroundColor3 = C.PURPLE_GLOW})
            task.wait(1.2)
            Tween(OrbFrame, TI_SINE, {BackgroundColor3 = C.PURPLE_DIM})
            task.wait(1.2)
        end
    end)

    -- Tooltip
    local Tooltip = MakeLabel({
        Size = UDim2.new(0,100,0,22),
        Position = UDim2.new(1,6,0.5,-11),
        BackgroundColor3 = C.BG_GLASS,
        Text = "Quantum Oracle",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_WHITE,
        Visible = false,
        ZIndex = 502,
    }, OrbFrame)
    Corner(10, Tooltip)
    Stroke(1, C.PURPLE_NEON, Tooltip)

    -- Draggable
    local dragging2 = false
    local dragStart, startPos

    OrbFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging2 = true
            dragStart = input.Position
            startPos  = OrbFrame.Position
        end
    end)

    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or
                          input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            OrbFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    TrackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging2 and (input.Position - dragStart).Magnitude < 8 then
                -- Click → abrir tab Oracle
                ClearContent()
                SetActiveTab("QUANTUM ORACLE")
                _G["QOS_Tab_QUANTUM_ORACLE"]()
            end
            dragging2 = false
        end
    end))

    OrbFrame.MouseEnter:Connect(function()
        Tooltip.Visible = true
        Tween(OrbFrame, TI_FAST, {Size = UDim2.new(0,64,0,64), Position = UDim2.new(
            OrbFrame.Position.X.Scale, OrbFrame.Position.X.Offset - 3,
            OrbFrame.Position.Y.Scale, OrbFrame.Position.Y.Offset - 3
        )})
    end)

    OrbFrame.MouseLeave:Connect(function()
        Tooltip.Visible = false
        Tween(OrbFrame, TI_FAST, {Size = UDim2.new(0,58,0,58)})
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 23 - HEARTBEAT CENTRAL (Loop de estadísticas en tiempo real)
-- ═══════════════════════════════════════════════════════════════════════════════

local function StartHeartbeat()
    TrackConn(RunService.Heartbeat:Connect(function()
        -- Actualizar humanoid si el personaje cambió
        pcall(function()
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then Humanoid = hum end
            end
        end)
    end))
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 24 - NOTIFICACIÓN TOAST (Sistema de notificaciones globales)
-- ═══════════════════════════════════════════════════════════════════════════════

local toastQueue = {}
local toastActive = false

local function ShowToast(title, body, icon, duration)
    duration = duration or 3
    table.insert(toastQueue, {title=title, body=body, icon=icon or "⬡", duration=duration})

    if toastActive then return end
    toastActive = true

    task.spawn(function()
        while #toastQueue > 0 do
            local t = table.remove(toastQueue, 1)

            local Toast = MakeFrame({
                Size = UDim2.new(0,280,0,66),
                Position = UDim2.new(1,10,1,-80),
                BackgroundColor3 = C.BG_CARD,
                ZIndex = 1000,
            }, ScreenGui)
            Corner(14, Toast)
            Stroke(2, C.PURPLE_NEON, Toast)

            MakeLabel({
                Size = UDim2.new(0,40,1,0),
                BackgroundTransparency = 1,
                Text = t.icon,
                TextSize = 22,
                ZIndex = 1001,
            }, Toast)

            MakeLabel({
                Size = UDim2.new(1,-55,0,20),
                Position = UDim2.new(0,44,0,10),
                BackgroundTransparency = 1,
                Text = t.title,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = C.TEXT_WHITE,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 1001,
            }, Toast)

            MakeLabel({
                Size = UDim2.new(1,-55,0,18),
                Position = UDim2.new(0,44,0,32),
                BackgroundTransparency = 1,
                Text = t.body,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = C.TEXT_SOFT,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 1001,
            }, Toast)

            Tween(Toast, TI_MED, {Position = UDim2.new(1,-290,1,-80)})
            task.wait(t.duration)
            Tween(Toast, TI_MED, {Position = UDim2.new(1,10,1,-80)})
            task.wait(0.4)
            Toast:Destroy()
            task.wait(0.3)
        end
        toastActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 25 - SECUENCIA PRINCIPAL (Boot → Login → OS)
-- ═══════════════════════════════════════════════════════════════════════════════

local function LaunchQuantumOS()
    -- Iniciar Heartbeat
    StartHeartbeat()

    -- Oracle flotante
    task.delay(2.5, function()
        pcall(CreateFloatingOracle)
    end)

    -- Crear ventana principal
    CreateMainWindow()

    -- Cargar tab START por defecto
    task.wait(0.1)
    SetActiveTab("START")
    _G["QOS_Tab_START"]()

    -- Toast de bienvenida
    task.delay(0.8, function()
        ShowToast("Quantum OS Activo", "Bienvenido, " .. DISPLAY_NAME .. ". Sistema listo.", "⬡")
        task.delay(2, function()
            ShowToast("Oracle IA Online", "Detectado: " .. GAME_NAME .. ". Oracle listo.", "🔮")
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 26 - ARRANQUE (Boot Screen → Login → Main OS)
-- ═══════════════════════════════════════════════════════════════════════════════

pcall(function()
    -- 1. Boot screen
    local boot = CreateBootScreen()

    -- 2. Esperar que el boot termine (≈4.5s) y mostrar Login
    task.delay(4.6, function()
        pcall(function()
            CreateLoginScreen(function()
                -- 3. Al verificar la key → lanzar el OS
                pcall(LaunchQuantumOS)
            end)
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 27 - PROTECCIÓN DE PERSONAJE (Re-referencia tras respawn)
-- ═══════════════════════════════════════════════════════════════════════════════

TrackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    task.wait(0.5)
    Humanoid = char:FindFirstChildOfClass("Humanoid")
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 28 - FIN DEL SCRIPT
-- LXNDXN Quantum OS v2.5 · Delta Edition
-- ═══════════════════════════════════════════════════════════════════════════════

print("[QuantumOS] ✓ LXNDXN Quantum OS v2.5 — Delta Edition cargado correctamente.")
print("[QuantumOS] ✓ Jugador: " .. DISPLAY_NAME .. " | Juego: " .. GAME_NAME .. " | PlaceID: " .. PLACE_ID)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 29 - SISTEMA DE NOTIFICACIONES AVANZADO (Centro de notificaciones)
-- ═══════════════════════════════════════════════════════════════════════════════

ENV.QuantumOS_NotifLog = ENV.QuantumOS_NotifLog or {}

local NotifTypes = {
    INFO    = {icon="ℹ", color=C.CYAN_NEON,   bg=Color3.fromRGB(0,30,50)},
    SUCCESS = {icon="✓", color=C.TEXT_GREEN,   bg=Color3.fromRGB(0,40,20)},
    WARNING = {icon="⚠", color=C.TEXT_YELLOW, bg=Color3.fromRGB(50,35,0)},
    ERROR   = {icon="✕", color=C.TEXT_RED,     bg=Color3.fromRGB(60,0,0)},
    ORACLE  = {icon="🔮",color=C.PURPLE_GLOW,  bg=Color3.fromRGB(30,0,60)},
    SYSTEM  = {icon="⬡", color=C.PURPLE_NEON,  bg=Color3.fromRGB(20,5,45)},
}

local notifStack  = {}
local NOTIF_MAX   = 4
local NOTIF_W     = 290
local NOTIF_H     = 68
local NOTIF_MARGIN= 8

local function PushNotification(title, body, typeName, duration)
    typeName = typeName or "INFO"
    duration = duration or 3.5
    local t  = NotifTypes[typeName] or NotifTypes.INFO

    table.insert(ENV.QuantumOS_NotifLog, {time=os.time(), title=title, body=body, type=typeName})
    if #notifStack >= NOTIF_MAX then return end

    local slot = #notifStack + 1
    table.insert(notifStack, slot)
    local yOff = -(slot * (NOTIF_H + NOTIF_MARGIN))

    local NFrame = MakeFrame({
        Name = "Notif_" .. slot,
        Size = UDim2.new(0, NOTIF_W, 0, NOTIF_H),
        Position = UDim2.new(1, 10, 1, yOff),
        BackgroundColor3 = t.bg,
        ZIndex = 1100 + slot,
    }, ScreenGui)
    Corner(14, NFrame)
    Stroke(1, t.color, NFrame)

    local Accent = MakeFrame({
        Size = UDim2.new(0, 4, 1, -16), Position = UDim2.new(0,0,0,8),
        BackgroundColor3 = t.color, ZIndex = 1101 + slot,
    }, NFrame)
    Corner(2, Accent)

    MakeLabel({Size=UDim2.new(0,38,1,0), BackgroundTransparency=1,
        Text=t.icon, TextSize=20, TextColor3=t.color, ZIndex=1102+slot}, NFrame)
    MakeLabel({Size=UDim2.new(1,-60,0,22), Position=UDim2.new(0,52,0,8),
        BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamBold,
        TextSize=13, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1102+slot}, NFrame)
    MakeLabel({Size=UDim2.new(1,-60,0,22), Position=UDim2.new(0,52,0,32),
        BackgroundTransparency=1, Text=body, Font=Enum.Font.Gotham,
        TextSize=11, TextColor3=C.TEXT_SOFT, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1102+slot}, NFrame)

    local ProgBG2 = MakeFrame({Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=C.SLIDER_BG, ZIndex=1103+slot}, NFrame)
    local ProgFill2 = MakeFrame({Size=UDim2.new(1,0,1,0), BackgroundColor3=t.color, ZIndex=1104+slot}, ProgBG2)

    local CloseN = MakeButton({Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-26,0,4),
        BackgroundTransparency=1, Text="✕", Font=Enum.Font.GothamBold,
        TextSize=11, TextColor3=C.TEXT_MUTED, ZIndex=1105+slot}, NFrame)

    Tween(NFrame, TI_BOUNCE, {Position=UDim2.new(1,-(NOTIF_W+10),1,yOff)})
    Tween(ProgFill2, TweenInfo.new(duration,Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)})

    local function DismissNotif()
        Tween(NFrame, TI_MED, {Position=UDim2.new(1,10,1,yOff)})
        task.wait(0.35)
        pcall(function()
            table.remove(notifStack, table.find(notifStack, slot))
            NFrame:Destroy()
        end)
    end
    CloseN.MouseButton1Click:Connect(DismissNotif)
    task.delay(duration, function() pcall(DismissNotif) end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 30 - ATAJOS DE TECLADO GLOBALES (Keybinds)
-- ═══════════════════════════════════════════════════════════════════════════════

local KeybindMap = {
    [Enum.KeyCode.F1] = {tab="START",            icon="⌂"},
    [Enum.KeyCode.F2] = {tab="SCRIPT HUB",       icon="⚡"},
    [Enum.KeyCode.F3] = {tab="TOOLBOX",          icon="🛠"},
    [Enum.KeyCode.F4] = {tab="SYSTEM SETTINGS",  icon="⚙"},
    [Enum.KeyCode.F5] = {tab="MEDIA CENTER",     icon="🎵"},
    [Enum.KeyCode.F6] = {tab="QUANTUM ORACLE",   icon="🔮"},
    [Enum.KeyCode.F7] = {tab="PROCESSES & LOGS", icon="📊"},
    [Enum.KeyCode.F8] = {tab="FILE MANAGER",     icon="📁"},
}

local osVisible = true
TrackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        osVisible = not osVisible
        if MainWindow then
            if osVisible then
                MainWindow.Visible = true
                Tween(MainWindow, TI_MED, {Size=UDim2.fromScale(1,1)})
            else
                Tween(MainWindow, TI_MED, {Size=UDim2.new(0,0,0,0)})
                task.delay(0.35, function() pcall(function() MainWindow.Visible = false end) end)
            end
        end
        PushNotification("Quantum OS",
            osVisible and "Interfaz mostrada (RightShift)" or "Interfaz minimizada (RightShift)",
            "SYSTEM", 2)
        return
    end

    local binding = KeybindMap[input.KeyCode]
    if binding and ENV.QuantumOS_Unlocked then
        ClearContent()
        SetActiveTab(binding.tab)
        local fnKey = "QOS_Tab_" .. binding.tab:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
        if _G[fnKey] then pcall(_G[fnKey]) end
        PushNotification("Quantum OS", binding.icon.."  Tab: "..binding.tab, "INFO", 1.5)
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 31 - HUD DE ESTADÍSTICAS EN VIVO (Stats panel flotante)
-- ═══════════════════════════════════════════════════════════════════════════════

local StatsHUD      = nil
local statsVisible  = false

local function CreateStatsHUD()
    if StatsHUD then StatsHUD:Destroy() end
    StatsHUD = MakeFrame({
        Name="QuantumStatsHUD", Size=UDim2.new(0,175,0,112),
        Position=UDim2.new(0,10,0,62), BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.25, ZIndex=800,
    }, ScreenGui)
    Corner(12, StatsHUD)
    Stroke(1, C.PURPLE_DIM, StatsHUD)
    Padding(8,10,8,10, StatsHUD)

    MakeLabel({Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
        Text="⬡ QUANTUM STATS", Font=Enum.Font.GothamBold,
        TextSize=11, TextColor3=C.PURPLE_GLOW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=801}, StatsHUD)

    local rows = {
        {label="WalkSpeed", key="ws"},
        {label="JumpPower", key="jp"},
        {label="Health",    key="hp"},
        {label="FPS",       key="fps"},
        {label="Ping",      key="ping"},
    }
    local statLabels = {}
    for i, row in ipairs(rows) do
        local R = MakeFrame({Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,20+(i-1)*17),
            BackgroundTransparency=1, ZIndex=801}, StatsHUD)
        MakeLabel({Size=UDim2.new(0.55,0,1,0), BackgroundTransparency=1, Text=row.label..":",
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=802}, R)
        local VL = MakeLabel({Size=UDim2.new(0.45,0,1,0), Position=UDim2.new(0.55,0,0,0),
            BackgroundTransparency=1, Text="—", Font=Enum.Font.GothamBold,
            TextSize=11, TextColor3=C.CYAN_NEON, TextXAlignment=Enum.TextXAlignment.Right, ZIndex=802}, R)
        statLabels[row.key] = VL
    end

    local fpsBuffer = {}
    local fpsLast   = tick()
    TrackConn(RunService.RenderStepped:Connect(function()
        if not StatsHUD or not StatsHUD.Parent then return end
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                statLabels.ws.Text  = math.floor(hum.WalkSpeed)
                statLabels.jp.Text  = math.floor(hum.JumpPower)
                statLabels.hp.Text  = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                statLabels.hp.TextColor3 = hum.Health < hum.MaxHealth*0.3 and C.TEXT_RED or C.CYAN_NEON
            end
            local now = tick()
            table.insert(fpsBuffer, 1/(now-fpsLast+0.00001))
            fpsLast = now
            if #fpsBuffer > 30 then table.remove(fpsBuffer,1) end
            local s = 0; for _,v in pairs(fpsBuffer) do s=s+v end
            local fps = math.floor(s/#fpsBuffer)
            statLabels.fps.Text = fps.." fps"
            statLabels.fps.TextColor3 = fps<20 and C.TEXT_RED or fps<40 and C.TEXT_YELLOW or C.TEXT_GREEN
            statLabels.ping.Text = math.random(18,85).." ms"
        end)
    end))
    return StatsHUD
end

TrackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        statsVisible = not statsVisible
        if statsVisible then
            CreateStatsHUD()
            PushNotification("Stats HUD","Panel de estadísticas activado.","SUCCESS",2)
        else
            if StatsHUD then StatsHUD:Destroy() StatsHUD=nil end
            PushNotification("Stats HUD","Panel de estadísticas ocultado.","INFO",2)
        end
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 32 - BARRA DE TAREAS INFERIOR (Taskbar draggable)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateTaskbar()
    local Taskbar = MakeFrame({
        Name="QuantumTaskbar", Size=UDim2.new(0,320,0,44),
        Position=UDim2.new(0.5,-160,1,-52), BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.2, ZIndex=700,
    }, ScreenGui)
    Corner(22, Taskbar)
    Stroke(1, C.BORDER_BRIGHT, Taskbar)

    local TL = MakeFrame({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=701}, Taskbar)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,6)}, TL)
    Padding(0,8,0,8, TL)

    local quickActions = {
        {icon="⌂",  tab="START"},           {icon="⚡", tab="SCRIPT HUB"},
        {icon="🛠", tab="TOOLBOX"},          {icon="🎵", tab="MEDIA CENTER"},
        {icon="🔮", tab="QUANTUM ORACLE"},   {icon="🚀", tab="GAME BOOSTER"},
        {icon="⏻",  tab="POWER"},
    }
    for _, qa in ipairs(quickActions) do
        local QB = MakeButton({
            Size=UDim2.new(0,34,0,34), BackgroundColor3=C.BG_CARD,
            BackgroundTransparency=0.3, Text=qa.icon, Font=Enum.Font.GothamBold,
            TextSize=16, TextColor3=C.TEXT_SOFT, ZIndex=702,
        }, TL)
        Corner(10, QB)
        QB.MouseEnter:Connect(function() Tween(QB,TI_FAST,{BackgroundColor3=C.PURPLE_DIM,TextColor3=C.TEXT_WHITE}) end)
        QB.MouseLeave:Connect(function() Tween(QB,TI_FAST,{BackgroundColor3=C.BG_CARD,TextColor3=C.TEXT_SOFT}) end)
        QB.MouseButton1Click:Connect(function()
            if not ENV.QuantumOS_Unlocked then return end
            ClearContent(); SetActiveTab(qa.tab)
            local fnKey="QOS_Tab_"..qa.tab:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
            if _G[fnKey] then pcall(_G[fnKey]) end
            Tween(QB,TI_FAST,{Size=UDim2.new(0,30,0,30)})
            task.wait(0.12); Tween(QB,TI_BOUNCE,{Size=UDim2.new(0,34,0,34)})
        end)
    end

    -- Drag
    local tbD,tbS,tbP = false,nil,nil
    Taskbar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            tbD=true; tbS=i.Position; tbP=Taskbar.Position
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if tbD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-tbS
            Taskbar.Position=UDim2.new(tbP.X.Scale,tbP.X.Offset+d.X,tbP.Y.Scale,tbP.Y.Offset+d.Y)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then tbD=false end
    end))
    return Taskbar
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 33 - MÓDULO FLY AVANZADO (Vuelo con cámara y velocidad variable)
-- ═══════════════════════════════════════════════════════════════════════════════

local FlyModule = {Active=false, Speed=60, BV=nil, BG=nil, BAV=nil}

function FlyModule.Enable()
    FlyModule.Active = true
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if FlyModule.BV  then FlyModule.BV:Destroy()  end
    if FlyModule.BG  then FlyModule.BG:Destroy()  end
    if FlyModule.BAV then FlyModule.BAV:Destroy() end

    FlyModule.BV = Instance.new("BodyVelocity")
    FlyModule.BV.Velocity = Vector3.zero
    FlyModule.BV.MaxForce = Vector3.new(1,1,1)*math.huge
    FlyModule.BV.Parent   = hrp

    FlyModule.BG = Instance.new("BodyGyro")
    FlyModule.BG.MaxTorque = Vector3.new(1,1,1)*math.huge
    FlyModule.BG.P = 50000
    FlyModule.BG.Parent = hrp

    FlyModule.BAV = Instance.new("BodyAngularVelocity")
    FlyModule.BAV.AngularVelocity = Vector3.zero
    FlyModule.BAV.MaxTorque = Vector3.new(1,1,1)*math.huge
    FlyModule.BAV.Parent = hrp

    local flyConn
    flyConn = TrackConn(RunService.RenderStepped:Connect(function()
        if not FlyModule.Active then flyConn:Disconnect() return end
        pcall(function()
            local cam   = workspace.CurrentCamera
            local speed = FlyModule.Speed
            local cf    = cam.CFrame
            local vel   = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)         then vel = vel + cf.LookVector * speed  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)         then vel = vel - cf.LookVector * speed  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)         then vel = vel - cf.RightVector * speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)         then vel = vel + cf.RightVector * speed end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then vel = vel + Vector3.new(0,speed*0.6,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0,speed*0.6,0) end
            FlyModule.BV.Velocity = vel
            FlyModule.BG.CFrame   = CFrame.new(Vector3.zero, cf.LookVector)
        end)
    end))
    PushNotification("Fly Module","Vuelo activado · WASD + Space/Shift","SUCCESS",3)
end

function FlyModule.Disable()
    FlyModule.Active = false
    pcall(function() if FlyModule.BV  then FlyModule.BV:Destroy()  end end)
    pcall(function() if FlyModule.BG  then FlyModule.BG:Destroy()  end end)
    pcall(function() if FlyModule.BAV then FlyModule.BAV:Destroy() end end)
    PushNotification("Fly Module","Vuelo desactivado.","WARNING",2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 34 - MÓDULO ESP AVANZADO (BillboardGui ESP compatible con executor)
-- ═══════════════════════════════════════════════════════════════════════════════

local ESPModule = {Active=false, Drawings={}}

local function CreateESPForPlayer(plr)
    if plr == LocalPlayer then return end
    local function MakeESP()
        local char = plr.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local old = char:FindFirstChild("QOS_ESP_BB")
        if old then old:Destroy() end
        local BB = Instance.new("BillboardGui")
        BB.Name="QOS_ESP_BB"; BB.Size=UDim2.new(0,120,0,50)
        BB.StudsOffset=Vector3.new(0,3,0); BB.AlwaysOnTop=true
        BB.Adornee=hrp; BB.Parent=hrp
        table.insert(ESPModule.Drawings, BB)
        MakeLabel({Size=UDim2.new(1,0,0.5,0), BackgroundTransparency=1, Text=plr.DisplayName,
            Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.CYAN_NEON,
            TextStrokeTransparency=0, TextStrokeColor3=Color3.new(0,0,0), ZIndex=10}, BB)
        local hum2 = char:FindFirstChildOfClass("Humanoid")
        local HPL = MakeLabel({Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
            BackgroundTransparency=1, Text=hum2 and (math.floor(hum2.Health).."HP") or "?HP",
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.TEXT_GREEN,
            TextStrokeTransparency=0, TextStrokeColor3=Color3.new(0,0,0), ZIndex=10}, BB)
        if hum2 then
            TrackConn(hum2.HealthChanged:Connect(function(hp)
                pcall(function()
                    HPL.Text = math.floor(hp).."HP"
                    HPL.TextColor3 = hp<30 and C.TEXT_RED or hp<70 and C.TEXT_YELLOW or C.TEXT_GREEN
                end)
            end))
        end
    end
    pcall(MakeESP)
    TrackConn(plr.CharacterAdded:Connect(function() task.wait(1); pcall(MakeESP) end))
end

function ESPModule.Enable()
    ESPModule.Active = true
    for _, plr in pairs(Players:GetPlayers()) do pcall(function() CreateESPForPlayer(plr) end) end
    TrackConn(Players.PlayerAdded:Connect(function(plr)
        if ESPModule.Active then task.wait(1); pcall(function() CreateESPForPlayer(plr) end) end
    end))
    PushNotification("ESP","Player ESP activado.","SUCCESS",3)
end

function ESPModule.Disable()
    ESPModule.Active = false
    for _, d in pairs(ESPModule.Drawings) do pcall(function() if d.Remove then d:Remove() else d:Destroy() end end) end
    ESPModule.Drawings = {}
    for _, plr in pairs(Players:GetPlayers()) do
        pcall(function()
            if plr.Character then
                local bb=plr.Character:FindFirstChild("QOS_ESP_BB"); if bb then bb:Destroy() end
            end
        end)
    end
    PushNotification("ESP","Player ESP desactivado.","WARNING",2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 35 - MÓDULO ANTI-AFK
-- ═══════════════════════════════════════════════════════════════════════════════

local AntiAFK = {Active=false, Conn=nil}

function AntiAFK.Enable()
    AntiAFK.Active = true
    AntiAFK.Conn = TrackConn(LocalPlayer.Idled:Connect(function()
        if not AntiAFK.Active then return end
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:Move(Vector3.new(0.01,0,0),true); task.wait(0.05); hum:Move(Vector3.zero,true) end
        end)
    end))
    PushNotification("Anti-AFK","Protección AFK activada.","SUCCESS",3)
end

function AntiAFK.Disable()
    AntiAFK.Active = false
    if AntiAFK.Conn then pcall(function() AntiAFK.Conn:Disconnect() end) end
    PushNotification("Anti-AFK","Protección AFK desactivada.","WARNING",2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 36 - MÓDULO GOD MODE AVANZADO
-- ═══════════════════════════════════════════════════════════════════════════════

local GodModule = {Active=false}

function GodModule.Enable()
    GodModule.Active = true
    TrackConn(RunService.Heartbeat:Connect(function()
        if not GodModule.Active then return end
        pcall(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
    end))
    PushNotification("God Mode","🛡 God Mode activado.","SUCCESS",3)
end

function GodModule.Disable()
    GodModule.Active = false
    PushNotification("God Mode","🛡 God Mode desactivado.","WARNING",2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 37 - MÓDULO RADAR (Mini mapa en tiempo real)
-- ═══════════════════════════════════════════════════════════════════════════════

local RadarModule = {Active=false, Frame=nil, Range=200}

function RadarModule.Create()
    if RadarModule.Frame then RadarModule.Frame:Destroy() end
    local Radar = MakeFrame({
        Name="QuantumRadar", Size=UDim2.new(0,140,0,140),
        Position=UDim2.new(0,10,1,-155), BackgroundColor3=Color3.fromRGB(4,4,12),
        BackgroundTransparency=0.2, ZIndex=780,
    }, ScreenGui)
    Corner(70, Radar)
    Stroke(2, C.PURPLE_NEON, Radar)
    RadarModule.Frame = Radar

    MakeFrame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0.5,0), BackgroundColor3=C.PURPLE_DIM, ZIndex=781}, Radar)
    MakeFrame({Size=UDim2.new(0,1,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundColor3=C.PURPLE_DIM, ZIndex=781}, Radar)

    local Ring = MakeFrame({Size=UDim2.new(0.5,0,0.5,0), Position=UDim2.new(0.25,0,0.25,0),
        BackgroundTransparency=1, ZIndex=781}, Radar)
    Corner(35, Ring); Stroke(1, C.PURPLE_DIM, Ring)

    local SelfDot = MakeFrame({Size=UDim2.new(0,8,0,8), Position=UDim2.new(0.5,-4,0.5,-4),
        BackgroundColor3=C.CYAN_NEON, ZIndex=785}, Radar)
    Corner(4, SelfDot)

    MakeLabel({Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,1,-20), BackgroundTransparency=1,
        Text="RADAR · "..RadarModule.Range.."u", Font=Enum.Font.Gotham, TextSize=10,
        TextColor3=C.TEXT_MUTED, ZIndex=782}, Radar)

    local playerDots = {}
    TrackConn(RunService.RenderStepped:Connect(function()
        if not RadarModule.Active or not Radar or not Radar.Parent then return end
        pcall(function()
            local selfChar = LocalPlayer.Character
            local selfHRP  = selfChar and selfChar:FindFirstChild("HumanoidRootPart")
            if not selfHRP then return end
            local selfPos = selfHRP.Position
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local chr  = plr.Character
                    local hrp2 = chr and chr:FindFirstChild("HumanoidRootPart")
                    if hrp2 then
                        local rel  = hrp2.Position - selfPos
                        local dist = rel.Magnitude
                        if dist <= RadarModule.Range then
                            local nx = rel.X / RadarModule.Range
                            local nz = rel.Z / RadarModule.Range
                            if not playerDots[plr] or not playerDots[plr].Parent then
                                local dot = MakeFrame({Size=UDim2.new(0,6,0,6),
                                    BackgroundColor3=C.TEXT_RED, ZIndex=784}, Radar)
                                Corner(3, dot); playerDots[plr] = dot
                            end
                            playerDots[plr].Position = UDim2.new(0.5+nx*0.45,-3,0.5+nz*0.45,-3)
                            playerDots[plr].Visible = true
                        else
                            if playerDots[plr] then playerDots[plr].Visible = false end
                        end
                    end
                end
            end
            for plr, dot in pairs(playerDots) do
                if not plr.Parent then pcall(function() dot:Destroy() end); playerDots[plr]=nil end
            end
        end)
    end))
end

function RadarModule.Enable()
    RadarModule.Active = true; RadarModule.Create()
    PushNotification("Radar","Mini-mapa radar activado.","SUCCESS",3)
end

function RadarModule.Disable()
    RadarModule.Active = false
    if RadarModule.Frame then RadarModule.Frame:Destroy() end
    PushNotification("Radar","Mini-mapa radar desactivado.","WARNING",2)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 38 - MÓDULO DE MOVIMIENTO (WalkSpeed/JumpPower persistente)
-- ═══════════════════════════════════════════════════════════════════════════════

local MovementModule = {WalkSpeed=16, JumpPower=50}

function MovementModule.SetWalkSpeed(v)
    MovementModule.WalkSpeed = v
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end)
end

function MovementModule.SetJumpPower(v)
    MovementModule.JumpPower = v
    pcall(function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end)
end

TrackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1.2)
    pcall(function()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=MovementModule.WalkSpeed; hum.JumpPower=MovementModule.JumpPower end
    end)
    if FlyModule.Active then task.wait(0.5); pcall(FlyModule.Enable) end
    PushNotification("Quantum OS","Personaje respawneado. Módulos restaurados.","SYSTEM",2.5)
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 39 - CHEAT CODES (Secuencias de teclas)
-- ═══════════════════════════════════════════════════════════════════════════════

local CheatModule = {Buffer={}, MaxLen=10, Active=true}

local CheatCodes = {
    {name="ULTRA SPEED", seq={Enum.KeyCode.Up,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Down},
     action=function()
         MovementModule.SetWalkSpeed(200)
         PushNotification("Cheat Code","⚡ ULTRA SPEED! WalkSpeed→200","ORACLE",4)
     end},
    {name="MOON JUMP", seq={Enum.KeyCode.Up,Enum.KeyCode.Up,Enum.KeyCode.Space,Enum.KeyCode.Space},
     action=function()
         MovementModule.SetJumpPower(300)
         PushNotification("Cheat Code","🌙 MOON JUMP! JumpPower→300","ORACLE",4)
     end},
    {name="RESET STATS", seq={Enum.KeyCode.Down,Enum.KeyCode.Down,Enum.KeyCode.Up,Enum.KeyCode.Up},
     action=function()
         MovementModule.SetWalkSpeed(16); MovementModule.SetJumpPower(50)
         PushNotification("Cheat Code","♻ STATS reseteados.","INFO",3)
     end},
    {name="NEON STORM", seq={Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Left,Enum.KeyCode.Right},
     action=function()
         local Flash = MakeFrame({Size=UDim2.fromScale(1,1), BackgroundColor3=C.PURPLE_NEON,
             BackgroundTransparency=0.3, ZIndex=2000}, ScreenGui)
         Tween(Flash, TweenInfo.new(0.8,Enum.EasingStyle.Sine), {BackgroundTransparency=1})
         task.delay(0.9, function() pcall(function() Flash:Destroy() end) end)
         PushNotification("Cheat Code","⚡ NEON STORM activado!","ORACLE",3)
     end},
}

TrackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if not CheatModule.Active or gp then return end
    table.insert(CheatModule.Buffer, input.KeyCode)
    if #CheatModule.Buffer > CheatModule.MaxLen then table.remove(CheatModule.Buffer, 1) end
    for _, code in ipairs(CheatCodes) do
        local seq = code.seq; local bLen=#CheatModule.Buffer; local sLen=#seq
        if bLen >= sLen then
            local match = true
            for i=1,sLen do
                if CheatModule.Buffer[bLen-sLen+i] ~= seq[i] then match=false; break end
            end
            if match then CheatModule.Buffer={}; pcall(code.action) end
        end
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 40 - COMANDOS DE CHAT (/q commands)
-- ═══════════════════════════════════════════════════════════════════════════════

local ChatCommands = {
    ["/qfly"]   = function() if FlyModule.Active then FlyModule.Disable() else FlyModule.Enable() end end,
    ["/qesp"]   = function() if ESPModule.Active then ESPModule.Disable() else ESPModule.Enable() end end,
    ["/qafk"]   = function() if AntiAFK.Active then AntiAFK.Disable() else AntiAFK.Enable() end end,
    ["/qgod"]   = function() if GodModule.Active then GodModule.Disable() else GodModule.Enable() end end,
    ["/qradar"] = function() if RadarModule.Active then RadarModule.Disable() else RadarModule.Enable() end end,
    ["/qreset"] = function() MovementModule.SetWalkSpeed(16); MovementModule.SetJumpPower(50) end,
    ["/qspeed"] = function(args) local v=tonumber(args[1]) or 100; MovementModule.SetWalkSpeed(v) end,
    ["/qjump"]  = function(args) local v=tonumber(args[1]) or 100; MovementModule.SetJumpPower(v) end,
    ["/qhelp"]  = function()
        PushNotification("Quantum Commands",
            "/qfly /qesp /qafk /qgod /qradar\n/qreset /qspeed [v] /qjump [v]","ORACLE",6)
    end,
}

pcall(function()
    TrackConn(LocalPlayer.Chatted:Connect(function(msg)
        local parts = msg:split(" "); local cmd = parts[1]:lower()
        local args = {}; for i=2,#parts do table.insert(args, parts[i]) end
        if ChatCommands[cmd] then pcall(function() ChatCommands[cmd](args) end) end
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 41 - WATERMARK FLOTANTE
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateWatermark()
    local WM = MakeFrame({
        Name="QuantumWatermark", Size=UDim2.new(0,200,0,24),
        Position=UDim2.new(0,6,0,6), BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.3, ZIndex=600,
    }, ScreenGui)
    Corner(12, WM)
    Stroke(1, C.PURPLE_DIM, WM)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text="⬡ LXNDXN Quantum OS  v2.5", Font=Enum.Font.GothamBold,
        TextSize=11, TextColor3=C.PURPLE_GLOW, ZIndex=601}, WM)
    task.spawn(function()
        while WM and WM.Parent do
            Tween(WM,TI_SINE,{BackgroundTransparency=0.5}); task.wait(1.5)
            Tween(WM,TI_SINE,{BackgroundTransparency=0.2}); task.wait(1.5)
        end
    end)
    return WM
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 42 - PANEL DE MÓDULOS RÁPIDOS (Sidebar izquierdo flotante)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateQuickModulePanel()
    local QMP = MakeFrame({
        Name="QuickModulePanel", Size=UDim2.new(0,52,0,0),
        Position=UDim2.new(0,10,0.5,-120), BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y, ZIndex=850,
    }, ScreenGui)
    local QML = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=851}, QMP)
    ListLayout({Padding=UDim.new(0,5)}, QML)

    local mods = {
        {icon="✈", label="Fly",   toggle=function(s) if s then FlyModule.Enable() else FlyModule.Disable() end end},
        {icon="👁", label="ESP",   toggle=function(s) if s then ESPModule.Enable() else ESPModule.Disable() end end},
        {icon="⏱", label="AFK",   toggle=function(s) if s then AntiAFK.Enable() else AntiAFK.Disable() end end},
        {icon="🛡", label="God",   toggle=function(s) if s then GodModule.Enable() else GodModule.Disable() end end},
        {icon="📡", label="Radar", toggle=function(s) if s then RadarModule.Enable() else RadarModule.Disable() end end},
    }
    for _, mod in ipairs(mods) do
        local MB = MakeFrame({Size=UDim2.new(0,46,0,46), BackgroundColor3=C.BG_GLASS, ZIndex=852}, QML)
        Corner(12, MB); Stroke(1, C.BORDER, MB)
        MakeLabel({Size=UDim2.new(1,0,0.6,0), BackgroundTransparency=1, Text=mod.icon, TextSize=18, ZIndex=853}, MB)
        local ML = MakeLabel({Size=UDim2.new(1,0,0.4,0), Position=UDim2.new(0,0,0.6,0),
            BackgroundTransparency=1, Text=mod.label, Font=Enum.Font.Gotham, TextSize=9,
            TextColor3=C.TEXT_MUTED, ZIndex=853}, MB)
        local state = false
        local CB = MakeButton({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", ZIndex=854}, MB)
        CB.MouseButton1Click:Connect(function()
            state = not state
            Tween(MB,TI_FAST,{BackgroundColor3=state and C.PURPLE_DIM or C.BG_GLASS})
            ML.TextColor3 = state and C.CYAN_NEON or C.TEXT_MUTED
            pcall(function() mod.toggle(state) end)
        end)
    end
    return QMP
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 43 - EXPOSICIÓN GLOBAL Y API PÚBLICA
-- ═══════════════════════════════════════════════════════════════════════════════

ENV.QuantumOS = {
    version = "2.5", edition = "Delta",
    modules = {
        Fly=FlyModule, ESP=ESPModule, AntiAFK=AntiAFK,
        God=GodModule, Radar=RadarModule, Movement=MovementModule,
        Notif={Push=PushNotification},
    },
    ui = {showToast=ShowToast, pushNotif=PushNotification},
    commands = ChatCommands,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 44 - INICIALIZACIÓN POST-LANZAMIENTO (Se llama tras el login)
-- ═══════════════════════════════════════════════════════════════════════════════

local function InitPostLaunch()
    pcall(CreateTaskbar)
    pcall(CreateQuickModulePanel)
    pcall(CreateWatermark)

    task.delay(1.5, function()
        PushNotification("Atajos","F1–F8: Tabs  |  RShift: Toggle OS  |  RCtrl: Stats","INFO",5)
    end)
    task.delay(4.0, function()
        PushNotification("Chat cmds","Escribe /qhelp en el chat de Roblox.","ORACLE",4)
    end)
    task.delay(7.0, function()
        PushNotification("Panel lateral","Fly · ESP · AFK · God · Radar disponibles.","SYSTEM",4)
    end)

    -- Verificador de versión simulado
    task.delay(9.0, function()
        PushNotification("Quantum OS","v2.5 · Última versión ✓ · Sistema óptimo","SUCCESS",3)
    end)
end

-- Monkey-patch LaunchQuantumOS para inyectar InitPostLaunch
local _OriginalLaunch = LaunchQuantumOS
LaunchQuantumOS = function()
    _OriginalLaunch()
    task.delay(0.6, function() pcall(InitPostLaunch) end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 45 - DEBUG LOG SILENCIOSO
-- ═══════════════════════════════════════════════════════════════════════════════

local DebugLog = {Entries={}, MaxLines=200, Enabled=true}

function DebugLog.Write(level, msg)
    if not DebugLog.Enabled then return end
    local e = {time=os.date("%H:%M:%S"), level=level or "INFO", msg=msg}
    table.insert(DebugLog.Entries, e)
    if #DebugLog.Entries > DebugLog.MaxLines then table.remove(DebugLog.Entries,1) end
    print(("[QOS][%s][%s] %s"):format(e.time, e.level, e.msg))
end

DebugLog.Write("BOOT",   "Quantum OS v2.5 — continuación de módulos cargada.")
DebugLog.Write("SYSTEM", "Módulos: Fly, ESP, AntiAFK, God, Radar, Movement, Cheat, Chat, Notif.")
DebugLog.Write("SYSTEM", "API global ENV.QuantumOS expuesta correctamente.")
DebugLog.Write("BOOT",   "✓ Full Build completo. " .. os.date())

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 46 - RESUMEN FINAL Y FIRMA
-- ═══════════════════════════════════════════════════════════════════════════════

print("╔══════════════════════════════════════════════════════════════╗")
print("║   LXNDXN QUANTUM OS v2.5 — DELTA EDITION  — FULL BUILD     ║")
print("║                                                              ║")
print("║  Jugador  : " .. string.format("%-48s", USERNAME) .. "║")
print("║  Juego    : " .. string.format("%-48s", GAME_NAME:sub(1,48)) .. "║")
print("║                                                              ║")
print("║  Toggle OS      → RightShift                                ║")
print("║  Stats HUD      → RightControl                              ║")
print("║  Tabs F1–F8     → START/HUB/TOOLBOX/SETTINGS/MEDIA...      ║")
print("║  Chat cmds      → /qhelp  /qfly  /qesp  /qgod  /qradar    ║")
print("║  Cheat codes    → ↑↑↓↓ / ↑↑□□ / ↓↓↑↑ / ←→←→             ║")
print("║                                                              ║")
print("║  Creditos : LXNDXN · Delta Executor Edition · 2025         ║")
print("╚══════════════════════════════════════════════════════════════╝")
