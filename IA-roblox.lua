-- ==============================================================================
-- SECCION 1 -- BOOTSTRAP & COMPATIBILIDAD DELTA
-- ==============================================================================

local function safefn(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local cloneref_fn    = safefn("function", cloneref,    function(...) return ... end)
local everyClipboard = safefn("function", setclipboard or toclipboard or set_clipboard, nil)
local httprequest_fn = safefn("function", request or http_request or (syn and syn.request), nil)
local queueteleport  = safefn("function", queue_on_teleport or (syn and syn.queue_on_teleport), nil)
local sethidden_fn   = safefn("function", sethiddenproperty or set_hidden_property, nil)

local ENV = getgenv and getgenv() or _G or {}

-- Limpieza de instancias previas
if ENV.QOS_Instance    then pcall(function() ENV.QOS_Instance:Destroy()    end) end
if ENV.QOS_OracleFloat then pcall(function() ENV.QOS_OracleFloat:Destroy() end) end
if ENV.QOS_Connections then
    for _, c in pairs(ENV.QOS_Connections) do pcall(function() c:Disconnect() end) end
end

-- Reset flags de estado para evitar bugs al re-ejecutar
ENV.QOS_FlyActive     = false
ENV.QOS_NoclipActive  = false
ENV.QOS_EspActive     = false
ENV.QOS_AntiAim       = false
ENV.QOS_InvisActive   = false
ENV.QOS_AntiAFK       = false
ENV.QOS_Connections   = {}
ENV.QOS_ActiveTab     = nil
ENV.QOS_Unlocked      = false
ENV.QOS_OpenRouterKey = nil
ENV.QOS_DeviceMode    = nil
ENV.QOS_CommandHistory = {}
ENV.QOS_Aliases       = {}
ENV.QOS_Toggles       = {}
ENV.QOS_Prefix        = ";"

-- ==============================================================================
-- SECCION 2 -- SERVICIOS
-- ==============================================================================

local Services = setmetatable({}, {
    __index = function(self, name)
        local ok, svc = pcall(function()
            return cloneref_fn(game:GetService(name))
        end)
        if ok then rawset(self, name, svc); return svc
        else error("Invalid Service: " .. tostring(name)) end
    end
})

local Players            = Services.Players
local TweenService       = Services.TweenService
local RunService         = Services.RunService
local UserInputService   = Services.UserInputService
local HttpService        = Services.HttpService
local MarketplaceService = Services.MarketplaceService
local TeleportService    = Services.TeleportService
local Lighting           = Services.Lighting
local StarterGui         = Services.StarterGui

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = cloneref_fn(LocalPlayer:WaitForChild("PlayerGui"))
local IYMouse     = cloneref_fn(LocalPlayer:GetMouse())
local PlaceId     = game.PlaceId
local JobId       = game.JobId

local IsOnMobile = false
xpcall(function()
    IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
    IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

local DISPLAY_NAME = LocalPlayer.DisplayName
local USERNAME     = LocalPlayer.Name
local GAME_NAME    = game.Name or "Roblox"

pcall(function()
    local info = MarketplaceService:GetProductInfo(PlaceId)
    if info and info.Name then GAME_NAME = info.Name end
end)

-- ==============================================================================
-- SECCION 3 -- PALETA GLASS / TRANSPARENTE
-- Estilo: frosted glass, acentos cyan/blanco suave, sin negro puro ni morado oscuro
-- ==============================================================================

local C = {
    -- Acentos principales (cyan/blanco en lugar de morado)
    ACCENT_1    = Color3.fromRGB( 80, 200, 255),  -- Cyan brillante (principal)
    ACCENT_2    = Color3.fromRGB(140, 230, 255),  -- Cyan claro
    ACCENT_3    = Color3.fromRGB(255, 255, 255),  -- Blanco puro
    ACCENT_GOLD = Color3.fromRGB(255, 215,  80),  -- Dorado
    ACCENT_GRN  = Color3.fromRGB( 80, 230, 160),  -- Verde
    ACCENT_RED  = Color3.fromRGB(255,  90,  90),  -- Rojo

    -- Fondos glass (todos semi-transparentes, se aplican con BackgroundTransparency)
    GLASS_DARK   = Color3.fromRGB( 15,  20,  30),  -- Panel base (usa transparencia 0.55)
    GLASS_MED    = Color3.fromRGB( 22,  30,  45),  -- Cards (usa transparencia 0.45)
    GLASS_LIGHT  = Color3.fromRGB( 35,  45,  65),  -- Hover / activo (usa transparencia 0.35)
    GLASS_ULTRA  = Color3.fromRGB( 50,  65,  90),  -- Muy claro (usa transparencia 0.2)
    GLASS_BORDER = Color3.fromRGB( 80, 130, 180),  -- Bordes glass

    -- Header / Sidebar glass
    HEADER_BG   = Color3.fromRGB( 12,  18,  28),
    SIDEBAR_BG  = Color3.fromRGB( 10,  16,  24),
    CONTENT_BG  = Color3.fromRGB(  8,  14,  22),

    -- Texto
    TEXT_WHITE  = Color3.fromRGB(240, 245, 255),
    TEXT_SOFT   = Color3.fromRGB(170, 185, 210),
    TEXT_MUTED  = Color3.fromRGB( 90, 110, 145),
    TEXT_GREEN  = Color3.fromRGB( 80, 230, 160),
    TEXT_RED    = Color3.fromRGB(255,  90,  90),
    TEXT_YELLOW = Color3.fromRGB(255, 215,  80),
    TEXT_CYAN   = Color3.fromRGB( 80, 200, 255),

    -- Toggles y sliders
    TOGGLE_ON   = Color3.fromRGB( 60, 210, 150),
    TOGGLE_OFF  = Color3.fromRGB( 45,  55,  75),
    SLIDER_BG   = Color3.fromRGB( 30,  42,  60),
    SLIDER_FILL = Color3.fromRGB( 80, 200, 255),

    -- Notificaciones
    NOTIF_INFO  = Color3.fromRGB(  0,  60, 100),
    NOTIF_OK    = Color3.fromRGB(  0,  60,  35),
    NOTIF_WARN  = Color3.fromRGB( 60,  45,   0),
    NOTIF_ERR   = Color3.fromRGB( 70,  10,  10),
    NOTIF_AI    = Color3.fromRGB( 20,  40,  70),
    NOTIF_SYS   = Color3.fromRGB( 10,  35,  65),
}

-- Transparencias estandar para el estilo glass
local GT = {
    PANEL   = 0.55,  -- Fondo principal
    CARD    = 0.45,  -- Cards normales
    HOVER   = 0.35,  -- Al hacer hover
    ACTIVE  = 0.20,  -- Tab activo
    HEADER  = 0.50,  -- Header
    SIDEBAR = 0.55,  -- Sidebar
    BORDER  = 0.30,  -- Bordes
}

local TI_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_SINE   = TweenInfo.new(1.20, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)

-- ==============================================================================
-- SECCION 4 -- UTILIDADES UI
-- ==============================================================================

local function Make(class, props, parent)
    local ok, inst = pcall(Instance.new, class)
    if not ok then return nil end
    for k, v in pairs(props or {}) do pcall(function() inst[k] = v end) end
    if parent then inst.Parent = parent end
    return inst
end

local function MakeFrame(p, par)  return Make("Frame",          p, par) end
local function MakeLabel(p, par)  return Make("TextLabel",      p, par) end
local function MakeButton(p, par) return Make("TextButton",     p, par) end
local function MakeBox(p, par)    return Make("TextBox",        p, par) end
local function MakeScroll(p, par) return Make("ScrollingFrame", p, par) end
local function MakeImage(p, par)  return Make("ImageLabel",     p, par) end

local function Tween(inst, info, props)
    if not inst or not inst.Parent then return end
    TweenService:Create(inst, info, props):Play()
end

local function Corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
    return c
end

local function Stroke(thickness, color, transparency, parent)
    -- Acepta 3 o 4 args; si transparency es un Instance, es el parent (compat)
    if type(transparency) ~= "number" then
        parent = transparency
        transparency = 0
    end
    local s = Instance.new("UIStroke")
    s.Thickness = thickness
    s.Color = color or C.GLASS_BORDER
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function Padding(t, r, b, l, parent)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.Parent = parent
    return p
end

local function ListLayout(props, parent)
    local l = Instance.new("UIListLayout")
    for k, v in pairs(props or {}) do pcall(function() l[k] = v end) end
    l.Parent = parent
    return l
end

local function TrackConn(conn)
    if conn then table.insert(ENV.QOS_Connections, conn) end
    return conn
end

local function Gradient(c0, c1, rot, parent)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent   = parent
    return g
end

-- Hover glass effect
local function HoverGlass(btn, normalT, hoverT)
    normalT = normalT or GT.CARD
    hoverT  = hoverT  or GT.HOVER
    btn.MouseEnter:Connect(function() Tween(btn, TI_FAST, {BackgroundTransparency = hoverT}) end)
    btn.MouseLeave:Connect(function() Tween(btn, TI_FAST, {BackgroundTransparency = normalT}) end)
end

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

local function Typewriter(label, text, speed)
    speed = speed or 0.03
    label.Text = ""
    task.spawn(function()
        for i = 1, #text do
            if not label or not label.Parent then break end
            label.Text = string.sub(text, 1, i)
            task.wait(speed)
        end
    end)
end

-- Blur de fondo (efecto glass real)
local function AddBlur(parent)
    local blur = Make("BlurEffect", {Size = 8}, Services.Lighting)
    return blur
end

-- ==============================================================================
-- SECCION 5 -- RAIZ DEL GUI (fondo glass)
-- ==============================================================================

local ScreenGui = Make("ScreenGui", {
    Name            = "QuantumOS_v41",
    ResetOnSpawn    = false,
    IgnoreGuiInset  = true,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 999,
}, PlayerGui)
ENV.QOS_Instance = ScreenGui

-- Fondo glass oscuro semi-transparente (NO negro sólido)
local BG = MakeFrame({
    Name                   = "Background",
    Size                   = UDim2.fromScale(1, 1),
    BackgroundColor3       = C.GLASS_DARK,
    BackgroundTransparency = GT.PANEL,
    BorderSizePixel        = 0,
    ZIndex                 = 1,
}, ScreenGui)

-- Gradiente sutil en el fondo
Gradient(
    Color3.fromRGB(10, 18, 30),
    Color3.fromRGB(20, 35, 55),
    135, BG
)

-- ==============================================================================
-- SECCION 6 -- SISTEMA DE COMANDOS (Logica Infinite Yield pura)
-- Source IY: https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source
-- ==============================================================================

local Commands      = {}
local CommandAliases = {}

-- Helpers de jugador (estilo IY exacto)
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

-- GetPlayerFromArg: devuelve player, tabla de players, o nil
-- Exacto al patron de IY
local function GetPlayerFromArg(arg)
    if not arg then return nil end
    local low = arg:lower()
    if low == "me" then return LocalPlayer end
    if low == "all" then
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            list[#list + 1] = p
        end
        return list
    end
    if low == "others" then
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then list[#list + 1] = p end
        end
        return list
    end
    for _, p in ipairs(Players:GetPlayers()) do
        local n = p.Name:lower()
        local d = p.DisplayName:lower()
        if n == low or d == low then return p end
        if n:sub(1, #low) == low or d:sub(1, #low) == low then return p end
    end
    return nil
end

-- Registro estilo IY
local function AddCommand(names, description, args, func)
    local primary = names[1]
    Commands[primary] = {
        names       = names,
        description = description,
        args        = args or {},
        func        = func,
        primary     = primary,
    }
    for i = 2, #names do
        CommandAliases[names[i]] = primary
    end
end

-- Forward declarations
local PushNotification
local ShowToast
local ParseAndExecute

-- ==============================================================================
-- COMANDOS (logica basada en Infinite Yield)
-- ==============================================================================

-- FLY: usa BodyVelocity + BodyGyro como IY original
AddCommand({"fly", "fl"}, "Activa/desactiva vuelo", {"velocidad (opcional)"}, function(args)
    local speed = tonumber(args[1]) or 50
    local root  = GetRootPart()
    local hum   = GetHumanoid()

    if ENV.QOS_FlyActive then
        ENV.QOS_FlyActive = false
        if ENV.QOS_FlyConn then
            pcall(function() ENV.QOS_FlyConn:Disconnect() end)
            ENV.QOS_FlyConn = nil
        end
        -- Limpiar instancias de vuelo
        if root then
            local bv = root:FindFirstChild("QOS_BV")
            local bg = root:FindFirstChild("QOS_BG")
            pcall(function() if bv then bv:Destroy() end end)
            pcall(function() if bg then bg:Destroy() end end)
        end
        if hum then hum.PlatformStand = false end
        PushNotification("Fly", "Vuelo desactivado", "INFO", 3)
        return
    end

    if not root or not hum then
        PushNotification("Fly", "No hay personaje", "ERROR", 3)
        return
    end

    ENV.QOS_FlyActive = true
    hum.PlatformStand = true

    -- Instancias nombradas para poder limpiarlas
    local bodyVel  = Instance.new("BodyVelocity")
    bodyVel.Name   = "QOS_BV"
    bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bodyVel.Velocity = Vector3.new()
    bodyVel.Parent   = root

    local bodyGyro  = Instance.new("BodyGyro")
    bodyGyro.Name   = "QOS_BG"
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.D      = 100
    bodyGyro.Parent = root

    ENV.QOS_FlyConn = RunService.Heartbeat:Connect(function()
        if not ENV.QOS_FlyActive then return end
        local char2 = GetCharacter()
        if not char2 then return end
        local root2 = char2:FindFirstChild("HumanoidRootPart") or char2:FindFirstChild("Torso")
        if not root2 then return end
        local cam = workspace.CurrentCamera
        local dir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0, 1, 0)
        end
        local bv2 = root2:FindFirstChild("QOS_BV")
        local bg2 = root2:FindFirstChild("QOS_BG")
        if bv2 then
            bv2.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.new()
        end
        if bg2 then
            bg2.CFrame = cam.CFrame
        end
    end)
    TrackConn(ENV.QOS_FlyConn)
    PushNotification("Fly", "Vuelo ON  vel=" .. speed .. " | WASD+Space/Ctrl", "SUCCESS", 3)
end)

AddCommand({"speed", "sp", "ws"}, "Cambia WalkSpeed", {"velocidad"}, function(args)
    local val = tonumber(args[1]) or 16
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = val end
    PushNotification("Speed", "WalkSpeed = " .. val, "SUCCESS", 3)
end)

AddCommand({"jump", "jp", "jh"}, "Cambia JumpPower/Height", {"altura"}, function(args)
    local val = tonumber(args[1]) or 50
    local hum = GetHumanoid()
    if not hum then PushNotification("Jump", "Sin Humanoid", "ERROR", 3); return end
    if hum.UseJumpPower then
        hum.JumpPower = val
    else
        hum.JumpHeight = val
    end
    PushNotification("Jump", "Altura = " .. val, "SUCCESS", 3)
end)

-- NOCLIP: toggle limpio, desconecta bien
AddCommand({"noclip", "nc"}, "Activa/desactiva noclip", {}, function()
    ENV.QOS_NoclipActive = not ENV.QOS_NoclipActive
    if ENV.QOS_NoclipActive then
        ENV.QOS_NoclipConn = TrackConn(RunService.Stepped:Connect(function()
            local char = GetCharacter()
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end))
        PushNotification("Noclip", "Colisiones OFF", "SUCCESS", 3)
    else
        if ENV.QOS_NoclipConn then
            pcall(function() ENV.QOS_NoclipConn:Disconnect() end)
            ENV.QOS_NoclipConn = nil
        end
        PushNotification("Noclip", "Colisiones ON", "INFO", 3)
    end
end)

-- TELEPORT: offset seguro
AddCommand({"tp", "teleport"}, "Teleporta a un jugador o coordenadas", {"jugador | x y z"}, function(args)
    local root = GetRootPart()
    if not root then PushNotification("TP", "Sin personaje", "ERROR", 3); return end
    -- Intentar coordenadas primero
    local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if x and y and z then
        root.CFrame = CFrame.new(x, y, z)
        PushNotification("TP", "Teleportado a " .. x.."/"..y.."/"..z, "SUCCESS", 3)
        return
    end
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then
        PushNotification("TP", "No uses 'all' con tp", "ERROR", 3); return
    end
    if not target then PushNotification("TP", "Jugador no encontrado", "ERROR", 3); return end
    local tChar = target.Character
    local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
    if root and tRoot then
        root.CFrame = tRoot.CFrame + Vector3.new(0, 3.5, 0)
        PushNotification("TP", "Teleportado a " .. target.DisplayName, "SUCCESS", 3)
    else
        PushNotification("TP", "No se pudo teleportar", "ERROR", 3)
    end
end)

AddCommand({"bringtp", "bring", "btp"}, "Trae a un jugador hacia ti", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then PushNotification("Bring", "No uses 'all'", "ERROR", 3); return end
    if not target then PushNotification("Bring", "Jugador no encontrado", "ERROR", 3); return end
    local root  = GetRootPart()
    local tChar = target.Character
    local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
    if root and tRoot then
        tRoot.CFrame = root.CFrame + root.CFrame.RightVector * 3.5
        PushNotification("Bring", "Traje a " .. target.DisplayName, "SUCCESS", 3)
    else
        PushNotification("Bring", "Sin character objetivo", "ERROR", 3)
    end
end)

-- GOD MODE
AddCommand({"godmode", "god", "gm"}, "Activa God Mode local", {}, function()
    local hum = GetHumanoid()
    if not hum then PushNotification("God", "Sin Humanoid", "ERROR", 3); return end
    ENV.QOS_GodActive = not (ENV.QOS_GodActive or false)
    if ENV.QOS_GodActive then
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
        -- Mantener salud infinita
        ENV.QOS_GodConn = TrackConn(hum.HealthChanged:Connect(function()
            if ENV.QOS_GodActive then
                hum.MaxHealth = math.huge
                hum.Health    = math.huge
            end
        end))
        PushNotification("God Mode", "Salud infinita ON", "SUCCESS", 3)
    else
        hum.MaxHealth = 100
        hum.Health    = 100
        if ENV.QOS_GodConn then
            pcall(function() ENV.QOS_GodConn:Disconnect() end)
            ENV.QOS_GodConn = nil
        end
        PushNotification("God Mode", "God Mode OFF", "INFO", 3)
    end
end)

-- ESP: usa Highlight (objeto correcto en Roblox moderno, no SelectionBox)
AddCommand({"esp", "wallhack", "wh"}, "Activa/desactiva ESP de jugadores", {}, function()
    if ENV.QOS_EspActive then
        ENV.QOS_EspActive = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("QOS_ESP")
                if h then h:Destroy() end
            end
        end
        if ENV.QOS_EspAddedConn then
            pcall(function() ENV.QOS_EspAddedConn:Disconnect() end)
            ENV.QOS_EspAddedConn = nil
        end
        PushNotification("ESP", "ESP desactivado", "INFO", 3)
        return
    end

    ENV.QOS_EspActive = true

    local function ApplyESP(player)
        if player == LocalPlayer then return end
        local function OnChar(char)
            if not ENV.QOS_EspActive then return end
            -- Limpiar anterior
            local old = char:FindFirstChild("QOS_ESP")
            if old then old:Destroy() end
            -- Highlight es el objeto correcto para ESP en Roblox
            local h = Instance.new("Highlight")
            h.Name               = "QOS_ESP"
            h.Adornee            = char
            h.FillColor          = Color3.fromRGB(80, 200, 255)
            h.OutlineColor       = Color3.fromRGB(255, 255, 255)
            h.FillTransparency   = 0.75
            h.OutlineTransparency = 0
            h.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent             = char
        end
        if player.Character then OnChar(player.Character) end
        TrackConn(player.CharacterAdded:Connect(function(c)
            if ENV.QOS_EspActive then OnChar(c) end
        end))
    end

    for _, p in ipairs(Players:GetPlayers()) do ApplyESP(p) end
    ENV.QOS_EspAddedConn = TrackConn(Players.PlayerAdded:Connect(ApplyESP))
    PushNotification("ESP", "ESP activado (Highlight)", "SUCCESS", 3)
end)

-- INVISIBLE local
AddCommand({"invisible", "invis", "inv"}, "Activa/desactiva invisibilidad local", {}, function()
    local char = GetCharacter()
    if not char then PushNotification("Invis", "Sin personaje", "ERROR", 3); return end
    ENV.QOS_InvisActive = not ENV.QOS_InvisActive
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            if ENV.QOS_InvisActive then
                part.LocalTransparencyModifier = 1
            else
                part.LocalTransparencyModifier = 0
            end
        end
    end
    PushNotification("Invisible",
        ENV.QOS_InvisActive and "Invisible ON (local)" or "Visible ON",
        ENV.QOS_InvisActive and "SUCCESS" or "INFO", 3)
end)

-- ANTI-AIM
AddCommand({"antiaim", "aa"}, "Activa/desactiva anti-aim de cabeza", {}, function()
    ENV.QOS_AntiAim = not ENV.QOS_AntiAim
    local char = GetCharacter()
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            local oldBG = head:FindFirstChild("QOS_AntiAimGyro")
            if oldBG then oldBG:Destroy() end
            if ENV.QOS_AntiAim then
                local bg = Instance.new("BodyGyro", head)
                bg.Name       = "QOS_AntiAimGyro"
                bg.MaxTorque  = Vector3.new(1e9, 1e9, 1e9)
                bg.D          = 50
                task.spawn(function()
                    while ENV.QOS_AntiAim and head and head.Parent do
                        bg.CFrame = CFrame.new(head.Position) * CFrame.Angles(0, tick() * 10, 0)
                        task.wait()
                    end
                    pcall(function() bg:Destroy() end)
                end)
            end
        end
    end
    PushNotification("Anti-Aim",
        ENV.QOS_AntiAim and "Anti-Aim ON" or "Anti-Aim OFF",
        ENV.QOS_AntiAim and "SUCCESS" or "INFO", 3)
end)

-- FOV
AddCommand({"fov", "setfov"}, "Cambia FOV de camara", {"valor (1-120)"}, function(args)
    local val = math.clamp(tonumber(args[1]) or 70, 1, 120)
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = val end
    PushNotification("FOV", "FieldOfView = " .. val, "SUCCESS", 3)
end)

-- GRAVITY
AddCommand({"gravity", "grav"}, "Cambia la gravedad", {"valor"}, function(args)
    workspace.Gravity = tonumber(args[1]) or 196.2
    PushNotification("Gravity", "Gravedad = " .. workspace.Gravity, "SUCCESS", 3)
end)

-- LIGHTING
AddCommand({"settime", "time"}, "Cambia la hora del juego (0-24)", {"hora"}, function(args)
    local val = math.clamp(math.floor(tonumber(args[1]) or 12), 0, 23)
    Lighting.TimeOfDay = string.format("%02d:00:00", val)
    PushNotification("Hora", "Hora = " .. val .. ":00", "SUCCESS", 3)
end)

AddCommand({"fog", "setfog"}, "Cambia la niebla", {"distancia"}, function(args)
    local val = tonumber(args[1]) or 100000
    Lighting.FogEnd   = val
    Lighting.FogStart = 0
    PushNotification("Fog", "FogEnd = " .. val, "SUCCESS", 3)
end)

AddCommand({"brightness", "br"}, "Cambia el brillo", {"valor"}, function(args)
    Lighting.Brightness = tonumber(args[1]) or 2
    PushNotification("Brightness", "Brillo = " .. Lighting.Brightness, "SUCCESS", 3)
end)

AddCommand({"fullbright", "fb"}, "Activa/desactiva fullbright", {}, function()
    ENV.QOS_Fullbright = not (ENV.QOS_Fullbright or false)
    Lighting.Brightness    = ENV.QOS_Fullbright and 10  or 2
    Lighting.GlobalShadows = not ENV.QOS_Fullbright
    Lighting.FogEnd        = ENV.QOS_Fullbright and 1e6 or 1000
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
    cc.Brightness = ENV.QOS_Fullbright and 0.3 or 0
    PushNotification("Fullbright",
        ENV.QOS_Fullbright and "Fullbright ON" or "Fullbright OFF",
        ENV.QOS_Fullbright and "SUCCESS" or "INFO", 3)
end)

-- UTILIDADES
AddCommand({"rejoin", "rj"}, "Vuelve a unirte al mismo servidor", {}, function()
    if queueteleport then
        queueteleport(string.format(
            'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")',
            PlaceId, JobId
        ))
    end
    pcall(function() TeleportService:TeleportToPlaceInstance(PlaceId, JobId) end)
    PushNotification("Rejoin", "Reconectando...", "INFO", 3)
end)

AddCommand({"server", "newserver", "ns", "hop"}, "Salta a un servidor nuevo", {}, function()
    pcall(function() TeleportService:Teleport(PlaceId) end)
    PushNotification("Server Hop", "Cambiando servidor...", "INFO", 3)
end)

AddCommand({"copy", "copyname"}, "Copia el nombre de usuario de un jugador", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then target = target[1] end
    if not target then PushNotification("Copy", "Jugador no encontrado", "ERROR", 3); return end
    if everyClipboard then
        pcall(function() everyClipboard(target.Name) end)
        PushNotification("Copiado", target.Name, "SUCCESS", 3)
    else
        PushNotification("Copy", "setclipboard no disponible", "WARNING", 3)
    end
end)

AddCommand({"players", "lp", "listplayers"}, "Lista de jugadores en el servidor", {}, function()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        list[#list + 1] = (p == LocalPlayer and "[TU] " or "") .. p.DisplayName .. " (@" .. p.Name .. ")"
    end
    PushNotification("Jugadores (" .. #list .. ")", table.concat(list, "  |  "), "INFO", 7)
end)

AddCommand({"reset"}, "Resetea tu personaje", {}, function()
    local hum = GetHumanoid()
    if hum then hum.Health = 0 end
end)

AddCommand({"kill"}, "Mata un personaje (solo local)", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    local targets = type(target) == "table" and target or (target and {target} or nil)
    if not targets then PushNotification("Kill", "Jugador no encontrado", "ERROR", 3); return end
    for _, p in ipairs(targets) do
        if p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Health = 0 end
        end
    end
    local name = type(target) == "table" and "all" or target.DisplayName
    PushNotification("Kill", "Kill: " .. name .. " (local)", "SUCCESS", 3)
end)

AddCommand({"size", "charsize"}, "Cambia el tamaño del personaje", {"escala"}, function(args)
    local scale = tonumber(args[1]) or 1
    local char  = GetCharacter()
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("NumberValue") then
            local n = obj.Name
            if n == "HeadScale" or n == "BodyHeightScale"
            or n == "BodyWidthScale" or n == "BodyDepthScale" then
                pcall(function() obj.Value = scale end)
            end
        end
    end
    PushNotification("Size", "Escala = " .. scale, "SUCCESS", 3)
end)

AddCommand({"walkto", "wt"}, "Camina hacia un jugador", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then return end
    if not target then PushNotification("WalkTo", "Jugador no encontrado", "ERROR", 3); return end
    local hum   = GetHumanoid()
    local tChar = target.Character
    local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
    if hum and tRoot then
        hum:MoveTo(tRoot.Position)
        PushNotification("WalkTo", "Caminando hacia " .. target.DisplayName, "INFO", 3)
    end
end)

AddCommand({"chat"}, "Envia un chat como tu personaje", {"mensaje..."}, function(args)
    if #args == 0 then return end
    local msg = table.concat(args, " ")
    local ok, err = pcall(function() LocalPlayer:Chat(msg) end)
    if ok then
        PushNotification("Chat", "Enviado: " .. msg, "SUCCESS", 3)
    else
        PushNotification("Chat", "Error: " .. tostring(err), "ERROR", 3)
    end
end)

AddCommand({"prefix"}, "Cambia el prefijo de comandos", {"prefijo (1 caracter)"}, function(args)
    if args[1] and #args[1] == 1 then
        ENV.QOS_Prefix = args[1]
        PushNotification("Prefijo", "Prefijo = " .. args[1], "SUCCESS", 3)
    else
        PushNotification("Prefijo", "Prefijo actual: " .. ENV.QOS_Prefix, "INFO", 3)
    end
end)

AddCommand({"alias"}, "Crea un alias para un comando", {"alias", "comando"}, function(args)
    if #args < 2 then PushNotification("Alias", "Uso: alias <nombre> <cmd>", "WARNING", 3); return end
    local aliasName = args[1]
    local targetCmd = args[2]
    ENV.QOS_Aliases[aliasName]  = targetCmd
    CommandAliases[aliasName]   = targetCmd
    PushNotification("Alias", "'" .. aliasName .. "' -> '" .. targetCmd .. "'", "SUCCESS", 3)
end)

AddCommand({"help", "h", "cmds"}, "Lista de comandos disponibles", {"busqueda (opcional)"}, function(args)
    local search = args[1] and args[1]:lower() or nil
    local found  = {}
    for name, cmd in pairs(Commands) do
        if not search
        or name:find(search, 1, true)
        or cmd.description:lower():find(search, 1, true) then
            found[#found + 1] = name .. " - " .. cmd.description
        end
    end
    table.sort(found)
    PushNotification(
        "Comandos (" .. #found .. ")",
        table.concat(found, "  |  "),
        "INFO", 9
    )
end)

AddCommand({"antiafk", "aafk"}, "Activa/desactiva anti-AFK", {}, function()
    ENV.QOS_AntiAFK = not (ENV.QOS_AntiAFK or false)
    if ENV.QOS_AntiAFK then
        task.spawn(function()
            while ENV.QOS_AntiAFK do
                pcall(function()
                    local vim = Services.VirtualInputManager
                    vim:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                    vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
                task.wait(55)
            end
        end)
        PushNotification("Anti-AFK", "Anti-AFK ON", "SUCCESS", 3)
    else
        PushNotification("Anti-AFK", "Anti-AFK OFF", "INFO", 3)
    end
end)

AddCommand({"zoom"}, "Cambia zoom maximo de camara", {"valor"}, function(args)
    local val = tonumber(args[1]) or 50
    pcall(function() Services.StarterPlayer.CameraMaxZoomDistance = val end)
    PushNotification("Zoom", "Max zoom = " .. val, "SUCCESS", 3)
end)

AddCommand({"nametag", "tag"}, "Oculta/muestra tu nametag", {}, function()
    ENV.QOS_TagHidden = not (ENV.QOS_TagHidden or false)
    local char = GetCharacter()
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            local bb = head:FindFirstChildOfClass("BillboardGui")
            if bb then bb.Enabled = not ENV.QOS_TagHidden end
        end
    end
    PushNotification("Nametag",
        ENV.QOS_TagHidden and "Nametag oculto" or "Nametag visible",
        "INFO", 3)
end)

-- ==============================================================================
-- PARSER DE COMANDOS (estilo IY: prefijo + cmd + args separados por espacios)
-- ==============================================================================

ParseAndExecute = function(input)
    if not input or input == "" then return false end
    input = input:match("^%s*(.-)%s*$")  -- trim

    local prefix = ENV.QOS_Prefix or ";"
    if input:sub(1, #prefix) ~= prefix then return false end
    input = input:sub(#prefix + 1)

    local tokens = {}
    for token in input:gmatch("%S+") do
        tokens[#tokens + 1] = token
    end
    if #tokens == 0 then return false end

    local cmdName = tokens[1]:lower()
    table.remove(tokens, 1)

    -- Resolver alias de usuario
    if ENV.QOS_Aliases[cmdName] then
        cmdName = ENV.QOS_Aliases[cmdName]
    end
    -- Resolver alias de comandos
    if CommandAliases[cmdName] then
        cmdName = CommandAliases[cmdName]
    end

    local cmd = Commands[cmdName]
    if cmd then
        -- Historial (max 60 entradas)
        local hist = ENV.QOS_CommandHistory
        local entry = prefix .. cmdName
        if #tokens > 0 then entry = entry .. " " .. table.concat(tokens, " ") end
        table.insert(hist, 1, entry)
        while #hist > 60 do table.remove(hist) end

        task.spawn(function()
            local ok, err = pcall(cmd.func, tokens)
            if not ok then
                PushNotification("Error", tostring(err):sub(1, 80), "ERROR", 4)
            end
        end)
        return true
    end

    PushNotification("Comando", "'" .. cmdName .. "' no existe. Usa " .. prefix .. "help", "WARNING", 3)
    return false
end

-- ==============================================================================
-- SECCION 7 -- NOTIFICACIONES (glass style)
-- ==============================================================================

local notifStack = {}
local NOTIF_W    = 300
local NOTIF_H    = 74
local NOTIF_M    = 6

local NotifTypes = {
    INFO    = {icon = "i",  color = C.ACCENT_1,    bg = C.NOTIF_INFO},
    SUCCESS = {icon = "v",  color = C.TEXT_GREEN,  bg = C.NOTIF_OK},
    WARNING = {icon = "!",  color = C.TEXT_YELLOW, bg = C.NOTIF_WARN},
    ERROR   = {icon = "x",  color = C.TEXT_RED,    bg = C.NOTIF_ERR},
    ORACLE  = {icon = "*",  color = C.ACCENT_2,    bg = C.NOTIF_AI},
    SYSTEM  = {icon = "#",  color = C.ACCENT_1,    bg = C.NOTIF_SYS},
    AI      = {icon = "AI", color = C.ACCENT_GOLD, bg = C.NOTIF_AI},
    CMD     = {icon = ">",  color = C.ACCENT_1,    bg = C.NOTIF_INFO},
}

PushNotification = function(title, body, typeName, duration)
    typeName = typeName or "INFO"
    duration = duration or 3.5
    local t  = NotifTypes[typeName] or NotifTypes.INFO
    if #notifStack >= 5 then return end

    local slot = #notifStack + 1
    notifStack[#notifStack + 1] = slot
    local yOff = -(slot * (NOTIF_H + NOTIF_M))

    -- Frame glass
    local NFrame = MakeFrame({
        Name                   = "Notif_" .. slot,
        Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H),
        Position               = UDim2.new(1, 16, 1, yOff),
        BackgroundColor3       = t.bg,
        BackgroundTransparency = 0.30,
        ZIndex                 = 1100 + slot,
    }, ScreenGui)
    if not NFrame then return end
    Corner(14, NFrame)
    Stroke(1, t.color, 0.3, NFrame)

    -- Barra lateral de acento
    local Acc = MakeFrame({
        Size                   = UDim2.new(0, 3, 0.8, 0),
        Position               = UDim2.new(0, 0, 0.1, 0),
        BackgroundColor3       = t.color,
        BackgroundTransparency = 0,
        ZIndex                 = 1101 + slot,
    }, NFrame)
    if Acc then Corner(2, Acc) end

    -- Badge de icono
    local IB = MakeFrame({
        Size                   = UDim2.new(0, 28, 0, 28),
        Position               = UDim2.new(0, 12, 0.5, -14),
        BackgroundColor3       = t.color,
        BackgroundTransparency = 0.7,
        ZIndex                 = 1102 + slot,
    }, NFrame)
    if IB then
        Corner(8, IB)
        MakeLabel({
            Size                   = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text                   = t.icon,
            Font                   = Enum.Font.GothamBold,
            TextSize               = 13,
            TextColor3             = t.color,
            ZIndex                 = 1103 + slot,
        }, IB)
    end

    -- Titulo
    MakeLabel({
        Size                   = UDim2.new(1, -58, 0, 22),
        Position               = UDim2.new(0, 50, 0, 8),
        BackgroundTransparency = 1,
        Text                   = title,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 13,
        TextColor3             = C.TEXT_WHITE,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 1102 + slot,
    }, NFrame)

    -- Cuerpo
    MakeLabel({
        Size                   = UDim2.new(1, -58, 0, 32),
        Position               = UDim2.new(0, 50, 0, 30),
        BackgroundTransparency = 1,
        Text                   = body,
        Font                   = Enum.Font.Gotham,
        TextSize               = 11,
        TextColor3             = C.TEXT_SOFT,
        TextWrapped            = true,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 1102 + slot,
    }, NFrame)

    -- Barra de progreso
    local PBG = MakeFrame({
        Size                   = UDim2.new(1, 0, 0, 2),
        Position               = UDim2.new(0, 0, 1, -2),
        BackgroundColor3       = C.SLIDER_BG,
        BackgroundTransparency = 0.5,
        ZIndex                 = 1103 + slot,
    }, NFrame)
    local PF = MakeFrame({
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundColor3       = t.color,
        BackgroundTransparency = 0.2,
        ZIndex                 = 1104 + slot,
    }, PBG)
    if PF then Corner(2, PF) end

    -- Boton cerrar
    local ClN = MakeButton({
        Size                   = UDim2.new(0, 22, 0, 22),
        Position               = UDim2.new(1, -26, 0, 4),
        BackgroundTransparency = 1,
        Text                   = "x",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 12,
        TextColor3             = C.TEXT_MUTED,
        ZIndex                 = 1105 + slot,
    }, NFrame)

    -- Animar entrada
    Tween(NFrame, TI_BOUNCE, {Position = UDim2.new(1, -(NOTIF_W + 10), 1, yOff)})
    if PF then
        Tween(PF, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
    end

    local dismissed = false
    local function Dismiss()
        if dismissed then return end
        dismissed = true
        Tween(NFrame, TI_MED, {Position = UDim2.new(1, 16, 1, yOff), BackgroundTransparency = 1})
        task.delay(0.35, function()
            pcall(function()
                local idx = table.find(notifStack, slot)
                if idx then table.remove(notifStack, idx) end
                NFrame:Destroy()
            end)
        end)
    end

    if ClN then ClN.MouseButton1Click:Connect(Dismiss) end
    task.delay(duration, function() pcall(Dismiss) end)
end

-- Toast rapido
local toastQueue  = {}
local toastActive = false

ShowToast = function(title, body, icon, dur)
    dur  = dur  or 2.5
    icon = icon or ">"
    toastQueue[#toastQueue + 1] = {title = title, body = body, icon = icon, dur = dur}
    if toastActive then return end
    toastActive = true
    task.spawn(function()
        while #toastQueue > 0 do
            local item = table.remove(toastQueue, 1)
            local T = MakeFrame({
                Size                   = UDim2.new(0, 290, 0, 60),
                Position               = UDim2.new(0.5, -145, 1, 10),
                BackgroundColor3       = C.GLASS_MED,
                BackgroundTransparency = 0.35,
                ZIndex                 = 1000,
            }, ScreenGui)
            if T then
                Corner(14, T)
                Stroke(1, C.ACCENT_1, 0.3, T)
                MakeLabel({
                    Size = UDim2.new(0, 34, 1, 0),
                    BackgroundTransparency = 1,
                    Text = item.icon,
                    Font = Enum.Font.GothamBold,
                    TextSize = 18,
                    TextColor3 = C.ACCENT_1,
                    ZIndex = 1001,
                }, T)
                MakeLabel({
                    Size = UDim2.new(1, -50, 0, 20),
                    Position = UDim2.new(0, 40, 0, 8),
                    BackgroundTransparency = 1,
                    Text = item.title,
                    Font = Enum.Font.GothamBold,
                    TextSize = 13,
                    TextColor3 = C.TEXT_WHITE,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 1001,
                }, T)
                MakeLabel({
                    Size = UDim2.new(1, -50, 0, 18),
                    Position = UDim2.new(0, 40, 0, 30),
                    BackgroundTransparency = 1,
                    Text = item.body,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = C.TEXT_SOFT,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 1001,
                }, T)
                Tween(T, TI_MED, {Position = UDim2.new(0.5, -145, 1, -72)})
                task.wait(item.dur)
                Tween(T, TI_MED, {Position = UDim2.new(0.5, -145, 1, 10), BackgroundTransparency = 1})
                task.wait(0.4)
                pcall(function() T:Destroy() end)
            end
            task.wait(0.2)
        end
        toastActive = false
    end)
end

-- ==============================================================================
-- SECCION 8 -- MULTI-AGENT AI (OpenRouter)
-- ==============================================================================

local AI = {}
AI.ORCHESTRATOR = "meta-llama/llama-3.3-70b-instruct:free"
AI.AGENTS = {
    GAME_ANALYST   = "nvidia/nemotron-3-super-120b-a12b:free",
    CODE_EXPERT    = "qwen/qwen3-coder:free",
    STRATEGY_AGENT = "deepseek/deepseek-v4-flash:free",
    CREATIVE_AGENT = "google/gemma-4-31b-it:free",
    FAST_AGENT     = "meta-llama/llama-3.2-3b-instruct:free",
}
AI.AGENT_META = {
    GAME_ANALYST   = {icon = "[G]", name = "Game Analyst",   color = Color3.fromRGB(255, 160,  60)},
    CODE_EXPERT    = {icon = "[C]", name = "Code Expert",    color = Color3.fromRGB( 60, 220, 180)},
    STRATEGY_AGENT = {icon = "[S]", name = "Strategy Agent", color = Color3.fromRGB(220,  80,  80)},
    CREATIVE_AGENT = {icon = "[A]", name = "Creative Agent", color = Color3.fromRGB(140, 200, 255)},
    FAST_AGENT     = {icon = "[F]", name = "Fast Agent",     color = Color3.fromRGB(255, 220,  60)},
}
AI.SYSTEM_PROMPTS = {
    ORCHESTRATOR   = "Eres el Orquestador de Quantum OS para Roblox. Analiza el mensaje y responde SOLO con JSON valido:\n{\"agent\":\"GAME_ANALYST|CODE_EXPERT|STRATEGY_AGENT|CREATIVE_AGENT|FAST_AGENT\",\"reason\":\"motivo breve\"}\nReglas: GAME_ANALYST=mecanicas/items/juego, CODE_EXPERT=scripts Lua/errores Delta, STRATEGY_AGENT=estrategias/builds, CREATIVE_AGENT=ideas/rol/diseño, FAST_AGENT=saludos/preguntas simples. Juego actual: " .. GAME_NAME,
    GAME_ANALYST   = "Eres un experto analista de '" .. GAME_NAME .. "' en Roblox. Responde en espanol, maximo 130 palabras. Se concreto y util.",
    CODE_EXPERT    = "Eres un experto en Lua y Delta Executor para Roblox. Ayuda con scripts, errores y optimizacion. Responde en espanol con codigo bien comentado, maximo 160 palabras. Si hay codigo, usa bloques Lua.",
    STRATEGY_AGENT = "Eres un estratega experto en '" .. GAME_NAME .. "'. Responde en espanol conciso con estrategias claras, maximo 130 palabras.",
    CREATIVE_AGENT = "Eres un asistente creativo para Roblox. Responde en espanol con entusiasmo y creatividad, maximo 110 palabras.",
    FAST_AGENT     = "Eres el asistente rapido de Quantum OS para Roblox '" .. GAME_NAME .. "'. Responde breve y amigable en espanol, maximo 70 palabras.",
}

local function OR_Call(model, sysPrompt, userMsg, maxTok)
    maxTok = maxTok or 300
    local key = ENV.QOS_OpenRouterKey
    if not key or key == "" then return nil, "Sin API Key" end

    local reqFn = httprequest_fn or request or http_request
    if not reqFn then return nil, "Sin HttpRequest en executor" end

    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({
            model      = model,
            max_tokens = maxTok,
            messages   = {
                {role = "system", content = sysPrompt},
                {role = "user",   content = userMsg},
            },
        })
        local resp = reqFn({
            Url    = "https://openrouter.ai/api/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. key,
                ["Content-Type"]  = "application/json",
                ["HTTP-Referer"]  = "https://quantumos-delta.rblx",
                ["X-Title"]       = "Quantum OS v4.1",
            },
            Body = body,
        })
        if not resp then return nil, "Sin respuesta" end
        if resp.StatusCode ~= 200 then
            return nil, "HTTP " .. tostring(resp.StatusCode)
        end
        local data = HttpService:JSONDecode(resp.Body)
        if data and data.choices and data.choices[1] then
            return data.choices[1].message and data.choices[1].message.content
        end
        return nil, "Sin contenido"
    end)
    if ok then return result, nil else return nil, tostring(result) end
end

local function VerifyAPIKey(key, callback)
    task.spawn(function()
        local old = ENV.QOS_OpenRouterKey
        ENV.QOS_OpenRouterKey = key
        local resp, err = OR_Call(
            AI.AGENTS.FAST_AGENT,
            "Eres un verificador de conexion. Responde SOLO la palabra: OK",
            "Verificacion de conexion. Responde: OK",
            15
        )
        if resp and #resp > 0 then
            callback(true, resp)
        else
            ENV.QOS_OpenRouterKey = old
            callback(false, err or "Sin respuesta del servidor")
        end
    end)
end

local function OracleQuery(userMsg, onThink, onAgent, onResponse, onError)
    task.spawn(function()
        if onThink then onThink("Orquestador analizando...") end
        local orchResp = OR_Call(AI.ORCHESTRATOR, AI.SYSTEM_PROMPTS.ORCHESTRATOR, userMsg, 80)
        local agentKey = "FAST_AGENT"
        if orchResp then
            local ok2, decoded = pcall(function() return HttpService:JSONDecode(orchResp) end)
            if ok2 and decoded and decoded.agent and AI.AGENTS[decoded.agent] then
                agentKey = decoded.agent
            end
        end
        local meta = AI.AGENT_META[agentKey] or AI.AGENT_META.FAST_AGENT
        if onAgent then onAgent(agentKey, meta) end
        if onThink then onThink(meta.name .. " respondiendo...") end
        local resp, err = OR_Call(
            AI.AGENTS[agentKey] or AI.AGENTS.FAST_AGENT,
            AI.SYSTEM_PROMPTS[agentKey] or AI.SYSTEM_PROMPTS.FAST_AGENT,
            userMsg, 360
        )
        if resp then
            if onResponse then onResponse(resp, meta) end
        else
            if onError then onError(err or "Error desconocido") end
        end
    end)
end

-- ==============================================================================
-- SECCION 9 -- BOOT SCREEN (glass)
-- ==============================================================================

local function CreateBootScreen()
    local Boot = MakeFrame({
        Name                   = "BootScreen",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.fromRGB(8, 14, 22),
        BackgroundTransparency = 0,
        ZIndex                 = 100,
    }, ScreenGui)
    Gradient(Color3.fromRGB(6, 12, 20), Color3.fromRGB(14, 24, 40), 135, Boot)

    -- Panel glass central
    local Center = MakeFrame({
        Size                   = UDim2.new(0, 360, 0, 420),
        Position               = UDim2.new(0.5, -180, 0.5, -210),
        BackgroundColor3       = C.GLASS_MED,
        BackgroundTransparency = 0.40,
        ZIndex                 = 101,
    }, Boot)
    Corner(24, Center)
    local cs = Stroke(1, C.GLASS_BORDER, 0.2, Center)
    PulseStroke(cs, C.GLASS_BORDER, C.ACCENT_1)

    -- Efecto scanlines sutiles
    for i = 1, 8 do
        MakeFrame({
            Size                   = UDim2.new(1, 0, 0, 1),
            Position               = UDim2.new(0, 0, i / 8, 0),
            BackgroundColor3       = Color3.fromRGB(80, 200, 255),
            BackgroundTransparency = 0.92,
            ZIndex                 = 102,
        }, Center)
    end

    -- Logo circular glass
    local LogoRing = MakeFrame({
        Size                   = UDim2.new(0, 84, 0, 84),
        Position               = UDim2.new(0.5, -42, 0, 28),
        BackgroundColor3       = C.GLASS_LIGHT,
        BackgroundTransparency = 0.50,
        ZIndex                 = 102,
    }, Center)
    Corner(42, LogoRing)
    local lrs = Stroke(2, C.ACCENT_1, 0, LogoRing)
    PulseStroke(lrs, C.ACCENT_1, C.ACCENT_2)

    local LogoLabel = MakeLabel({
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "Q",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 46,
        TextColor3             = C.ACCENT_1,
        ZIndex                 = 103,
    }, LogoRing)
    task.spawn(function()
        while LogoLabel and LogoLabel.Parent do
            Tween(LogoLabel, TI_SINE, {TextColor3 = C.ACCENT_2}); task.wait(1.2)
            Tween(LogoLabel, TI_SINE, {TextColor3 = C.ACCENT_1}); task.wait(1.2)
        end
    end)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 124),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS  v4.1",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 102,
    }, Center)

    local Badge = MakeLabel({
        Size = UDim2.new(0, 250, 0, 22),
        Position = UDim2.new(0.5, -125, 0, 157),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.40,
        Text = "DELTA EDITION  |  INFINITE YIELD ENGINE",
        Font = Enum.Font.GothamSemibold,
        TextSize = 10,
        TextColor3 = C.ACCENT_1,
        ZIndex = 102,
    }, Center)
    Corner(11, Badge)
    Stroke(1, C.ACCENT_1, 0.5, Badge)

    local WelcomeLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 0, 192),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        TextWrapped = true,
        ZIndex = 102,
    }, Center)

    local SubLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 248),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_SOFT,
        TextWrapped = true,
        ZIndex = 102,
    }, Center)

    -- Progress bar glass
    local ProgressBG = MakeFrame({
        Size = UDim2.new(1, -40, 0, 5),
        Position = UDim2.new(0, 20, 0, 310),
        BackgroundColor3 = C.SLIDER_BG,
        BackgroundTransparency = 0.4,
        ZIndex = 102,
    }, Center)
    Corner(3, ProgressBG)
    local ProgressFill = MakeFrame({
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = C.ACCENT_1,
        BackgroundTransparency = 0,
        ZIndex = 103,
    }, ProgressBG)
    Corner(3, ProgressFill)
    Gradient(C.ACCENT_1, C.ACCENT_2, 0, ProgressFill)

    local ProgressLabel = MakeLabel({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, 6),
        BackgroundTransparency = 1,
        Text = "Inicializando...",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 102,
    }, ProgressBG)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -20),
        BackgroundTransparency = 1,
        Text = "LXNDXN  |  Delta Executor  |  IY Engine  |  v4.1",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 102,
    }, Center)

    task.spawn(function()
        task.wait(0.5)
        Typewriter(WelcomeLabel, "Hola, " .. DISPLAY_NAME .. ". Iniciando Quantum OS v4.1...", 0.04)
        task.wait(1.8)
        Typewriter(SubLabel, "IY Engine cargando...\nMulti-Agente AI | 5 Agentes activos.", 0.03)
        task.wait(1.3)
        local steps = {
            {0.14, "Cargando kernel del OS..."},
            {0.28, "Verificando Delta Executor..."},
            {0.44, "Cargando comandos IY..."},
            {0.60, "Conectando Orquestador AI..."},
            {0.76, "Activando agentes..."},
            {0.90, "Estableciendo sesion..."},
            {1.00, "Todo listo."},
        }
        for _, step in ipairs(steps) do
            Tween(ProgressFill, TI_MED, {Size = UDim2.new(step[1], 0, 1, 0)})
            ProgressLabel.Text = step[2]
            task.wait(0.38)
        end
        task.wait(0.5)
        Tween(Boot, TI_SLOW, {BackgroundTransparency = 1})
        task.wait(0.65)
        pcall(function() Boot:Destroy() end)
    end)
    return Boot
end

-- ==============================================================================
-- SECCION 10 -- LOGIN SCREEN (glass)
-- ==============================================================================

local function CreateLoginScreen(onSuccess)
    local Login = MakeFrame({
        Name                   = "LoginScreen",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundColor3       = Color3.fromRGB(8, 14, 22),
        BackgroundTransparency = 0,
        ZIndex                 = 90,
    }, ScreenGui)
    Gradient(Color3.fromRGB(6, 12, 20), Color3.fromRGB(16, 26, 44), 135, Login)

    -- Panel glass principal
    local Panel = MakeFrame({
        Name                   = "LoginPanel",
        Size                   = UDim2.new(0.90, 0, 0, 600),
        Position               = UDim2.new(0.05, 0, 0.5, -300),
        BackgroundColor3       = C.GLASS_MED,
        BackgroundTransparency = 0.35,
        ZIndex                 = 92,
    }, Login)
    Corner(24, Panel)
    local panelS = Stroke(1, C.GLASS_BORDER, 0.1, Panel)
    PulseStroke(panelS, C.GLASS_BORDER, C.ACCENT_1)

    -- Logo
    local LogoRing = MakeFrame({
        Size = UDim2.new(0, 78, 0, 78),
        Position = UDim2.new(0.5, -39, 0, 22),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.45,
        ZIndex = 94,
    }, Panel)
    Corner(39, LogoRing)
    Stroke(2, C.ACCENT_1, 0, LogoRing)

    local LIcon = MakeLabel({
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "Q",
        Font = Enum.Font.GothamBold,
        TextSize = 44,
        TextColor3 = C.ACCENT_1,
        ZIndex = 95,
    }, LogoRing)
    task.spawn(function()
        while LIcon and LIcon.Parent do
            Tween(LIcon, TI_SINE, {TextColor3 = C.ACCENT_2}); task.wait(1.2)
            Tween(LIcon, TI_SINE, {TextColor3 = C.ACCENT_1}); task.wait(1.2)
        end
    end)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 112),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS",
        Font = Enum.Font.GothamBold,
        TextSize = 26,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 94,
    }, Panel)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 146),
        BackgroundTransparency = 1,
        Text = "Multi-Agent AI  |  Delta Edition  |  v4.1",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = C.ACCENT_1,
        ZIndex = 94,
    }, Panel)

    -- Badges de agentes
    local BadgeRow = MakeFrame({
        Size = UDim2.new(1, -40, 0, 24),
        Position = UDim2.new(0, 20, 0, 175),
        BackgroundTransparency = 1,
        ZIndex = 94,
    }, Panel)
    ListLayout({
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 4),
    }, BadgeRow)
    for _, ab in ipairs({{"[G]", "Game"}, {"[C]", "Code"}, {"[S]", "Strat"}, {"[A]", "Art"}, {"[F]", "Fast"}}) do
        local B = MakeLabel({
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = C.GLASS_LIGHT,
            BackgroundTransparency = 0.5,
            Text = ab[1] .. " " .. ab[2],
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = C.TEXT_SOFT,
            ZIndex = 95,
        }, BadgeRow)
        Corner(10, B)
        Stroke(1, C.GLASS_BORDER, 0.4, B)
        Padding(0, 8, 0, 8, B)
    end

    -- Separador
    MakeFrame({
        Size = UDim2.new(0.85, 0, 0, 1),
        Position = UDim2.new(0.075, 0, 0, 212),
        BackgroundColor3 = C.GLASS_BORDER,
        BackgroundTransparency = 0.5,
        ZIndex = 94,
    }, Panel)

    -- Label API Key
    MakeLabel({
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 20, 0, 222),
        BackgroundTransparency = 1,
        Text = "OPENROUTER API KEY",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.ACCENT_1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 94,
    }, Panel)

    -- TextBox API Key glass
    local KeyBox = MakeBox({
        Size = UDim2.new(1, -40, 0, 48),
        Position = UDim2.new(0, 20, 0, 244),
        BackgroundColor3 = C.GLASS_DARK,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "sk-or-v1-xxxxxxxxxxxxxxxxxx",
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ClearTextOnFocus = false,
        ZIndex = 95,
    }, Panel)
    Corner(12, KeyBox)
    local kbs = Stroke(1, C.GLASS_BORDER, 0.3, KeyBox)
    Padding(0, 14, 0, 14, KeyBox)
    KeyBox.Focused:Connect(function()   Tween(kbs, TI_FAST, {Color = C.ACCENT_1, Transparency = 0}) end)
    KeyBox.FocusLost:Connect(function() Tween(kbs, TI_FAST, {Color = C.GLASS_BORDER, Transparency = 0.3}) end)

    -- Status
    local StatusLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 22),
        Position = UDim2.new(0, 20, 0, 300),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_MUTED,
        TextWrapped = true,
        ZIndex = 94,
    }, Panel)

    -- Spinner
    local Spinner = MakeLabel({
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0.5, -15, 0, 312),
        BackgroundTransparency = 1,
        Text = "o",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = C.ACCENT_1,
        Visible = false,
        ZIndex = 96,
    }, Panel)

    -- Boton VERIFICAR glass
    local LoginBtn = MakeButton({
        Size = UDim2.new(1, -40, 0, 48),
        Position = UDim2.new(0, 20, 0, 330),
        BackgroundColor3 = C.ACCENT_1,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Text = ">> VERIFICAR API KEY <<",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 95,
    }, Panel)
    Corner(12, LoginBtn)
    Stroke(1, C.ACCENT_1, 0.2, LoginBtn)

    LoginBtn.MouseEnter:Connect(function()
        Tween(LoginBtn, TI_FAST, {BackgroundTransparency = 0, Size = UDim2.new(1, -30, 0, 48), Position = UDim2.new(0, 15, 0, 330)})
    end)
    LoginBtn.MouseLeave:Connect(function()
        Tween(LoginBtn, TI_FAST, {BackgroundTransparency = 0.15, Size = UDim2.new(1, -40, 0, 48), Position = UDim2.new(0, 20, 0, 330)})
    end)

    -- Separador 2
    MakeFrame({
        Size = UDim2.new(0.7, 0, 0, 1),
        Position = UDim2.new(0.15, 0, 0, 394),
        BackgroundColor3 = C.GLASS_BORDER,
        BackgroundTransparency = 0.5,
        ZIndex = 94,
    }, Panel)

    -- Boton Obtener Key
    local GetKeyBtn = MakeButton({
        Size = UDim2.new(1, -40, 0, 40),
        Position = UDim2.new(0, 20, 0, 402),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Text = "[KEY] Obtener API Key -> openrouter.ai/keys",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = C.ACCENT_1,
        ZIndex = 95,
    }, Panel)
    Corner(12, GetKeyBtn)
    Stroke(1, C.ACCENT_1, 0.5, GetKeyBtn)
    GetKeyBtn.MouseEnter:Connect(function() Tween(GetKeyBtn, TI_FAST, {BackgroundTransparency = 0.3}) end)
    GetKeyBtn.MouseLeave:Connect(function() Tween(GetKeyBtn, TI_FAST, {BackgroundTransparency = 0.5}) end)
    GetKeyBtn.MouseButton1Click:Connect(function()
        if everyClipboard then pcall(function() everyClipboard("https://openrouter.ai/keys") end) end
        StatusLabel.Text = "Link copiado: openrouter.ai/keys"
        StatusLabel.TextColor3 = C.ACCENT_1
    end)

    -- Hint
    MakeLabel({
        Size = UDim2.new(1, -40, 0, 14),
        Position = UDim2.new(0, 20, 0, 452),
        BackgroundTransparency = 1,
        Text = "[i] Tu key solo se usa para llamadas de IA - No se almacena externamente",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        TextWrapped = true,
        ZIndex = 94,
    }, Panel)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 578),
        BackgroundTransparency = 1,
        Text = "LXNDXN Quantum OS  |  Delta Edition  |  v4.1  |  IY Engine",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 94,
    }, Panel)

    -- Logica de verificacion
    local function DoVerify()
        local key = KeyBox.Text:gsub("%s+", "")
        if key == "" then
            StatusLabel.Text = "[!] Introduce tu API Key de OpenRouter."
            StatusLabel.TextColor3 = C.TEXT_YELLOW
            Tween(KeyBox, TI_FAST, {BackgroundColor3 = Color3.fromRGB(40, 20, 10)})
            task.wait(0.7)
            Tween(KeyBox, TI_FAST, {BackgroundColor3 = C.GLASS_DARK})
            return
        end
        LoginBtn.Visible = false
        Spinner.Visible  = true
        StatusLabel.Text = "Verificando con OpenRouter..."
        StatusLabel.TextColor3 = C.ACCENT_1

        local spinOK = true
        task.spawn(function()
            local icons = {"o", "0", "O", "Q", "O", "0"}
            local i = 1
            while spinOK do
                Spinner.Text = icons[i]
                i = i % #icons + 1
                task.wait(0.12)
            end
        end)

        VerifyAPIKey(key, function(success, resp)
            spinOK = false
            Spinner.Visible  = false
            LoginBtn.Visible = true
            if success then
                ENV.QOS_OpenRouterKey = key
                StatusLabel.Text      = "[v] API Key verificada | Conexion establecida"
                StatusLabel.TextColor3 = C.TEXT_GREEN
                Tween(LoginBtn, TI_FAST, {BackgroundColor3 = C.TOGGLE_ON, BackgroundTransparency = 0.1})
                LoginBtn.Text = "[v]  CONECTADO - Entrando..."
                task.wait(0.9)
                Tween(Login, TI_MED, {BackgroundTransparency = 1})
                task.wait(0.4)
                pcall(function() Login:Destroy() end)
                onSuccess()
            else
                StatusLabel.Text      = "[x] API Key invalida. Verifica en openrouter.ai/keys"
                StatusLabel.TextColor3 = C.TEXT_RED
                -- Shake animation
                local ox = Panel.Position.X.Scale
                local oy = Panel.Position.Y.Scale
                for _ = 1, 5 do
                    Tween(Panel, TI_FAST, {Position = UDim2.new(ox + 0.008, 0, oy, 0)}); task.wait(0.06)
                    Tween(Panel, TI_FAST, {Position = UDim2.new(ox - 0.008, 0, oy, 0)}); task.wait(0.06)
                end
                Tween(Panel, TI_FAST, {Position = UDim2.new(0.05, 0, 0.5, -300)})
            end
        end)
    end
    LoginBtn.MouseButton1Click:Connect(DoVerify)
    KeyBox.FocusLost:Connect(function(enter) if enter then DoVerify() end end)
    return Login
end

-- ==============================================================================
-- SECCION 11 -- VENTANA PRINCIPAL (glass)
-- ==============================================================================

local MainWindow    = nil
local Sidebar       = nil
local ContentArea   = nil
local CurrentTabFrame = nil
local SidebarButtons = {}

local function ClearContent()
    if CurrentTabFrame then
        pcall(function() CurrentTabFrame:Destroy() end)
        CurrentTabFrame = nil
    end
end

local function SetActiveTab(name)
    for tabName, btn in pairs(SidebarButtons) do
        local active = (tabName == name)
        Tween(btn, TI_FAST, {
            BackgroundTransparency = active and GT.ACTIVE or 1,
            BackgroundColor3       = active and C.GLASS_ULTRA or C.GLASS_DARK,
        })
        local ind = btn:FindFirstChild("Indicator")
        if ind then ind.Visible = active end
        for _, child in ipairs(btn:GetChildren()) do
            if child:IsA("TextLabel") then
                Tween(child, TI_FAST, {
                    TextColor3 = active and C.ACCENT_1 or C.TEXT_MUTED
                })
            end
        end
    end
end

local function SectionHeader(parent, title, subtitle)
    local H = MakeFrame({
        Size             = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = C.GLASS_MED,
        BackgroundTransparency = 0.45,
        ZIndex           = 20,
    }, parent)
    Stroke(1, C.GLASS_BORDER, 0.4, H)
    MakeLabel({
        Size = UDim2.new(1, -20, 0, 26),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, H)
    MakeLabel({
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 14, 0, 36),
        BackgroundTransparency = 1,
        Text = subtitle,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, H)
    return H
end

local function CreateToggleWidget(parent, label, defaultState, onChange)
    local Row = MakeFrame({
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.GLASS_MED,
        BackgroundTransparency = GT.CARD,
        ZIndex = 20,
    }, parent)
    Corner(10, Row)
    Stroke(1, C.GLASS_BORDER, 0.4, Row)
    MakeLabel({
        Size = UDim2.new(1, -72, 1, 0),
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
        BackgroundTransparency = 0.2,
        ZIndex = 21,
    }, Row)
    Corner(12, Track)
    local Thumb = MakeFrame({
        Size = UDim2.new(0, 18, 0, 18),
        Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        ZIndex = 22,
    }, Track)
    Corner(9, Thumb)
    local state = defaultState
    local TB = MakeButton({
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 23,
    }, Track)
    TB.MouseButton1Click:Connect(function()
        state = not state
        Tween(Track, TI_FAST, {BackgroundColor3 = state and C.TOGGLE_ON or C.TOGGLE_OFF})
        Tween(Thumb, TI_FAST, {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        })
        if onChange then onChange(state) end
    end)
    return Row, function() return state end
end

local function CreateSliderWidget(parent, label, minV, maxV, defV, suffix, onChange)
    local Row = MakeFrame({
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = C.GLASS_MED,
        BackgroundTransparency = GT.CARD,
        ZIndex = 20,
    }, parent)
    Corner(10, Row)
    Stroke(1, C.GLASS_BORDER, 0.4, Row)
    MakeLabel({
        Size = UDim2.new(1, -70, 0, 22),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, Row)
    local VL = MakeLabel({
        Size = UDim2.new(0, 58, 0, 22),
        Position = UDim2.new(1, -68, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(defV) .. (suffix or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.ACCENT_1,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 21,
    }, Row)
    local TRK = MakeFrame({
        Size = UDim2.new(1, -28, 0, 5),
        Position = UDim2.new(0, 14, 0, 42),
        BackgroundColor3 = C.SLIDER_BG,
        BackgroundTransparency = 0.3,
        ZIndex = 21,
    }, Row)
    Corner(3, TRK)
    local ratio = (defV - minV) / math.max(maxV - minV, 0.001)
    local Fill = MakeFrame({
        Size = UDim2.new(ratio, 0, 1, 0),
        BackgroundColor3 = C.SLIDER_FILL,
        BackgroundTransparency = 0.1,
        ZIndex = 22,
    }, TRK)
    Corner(3, Fill)
    Gradient(C.ACCENT_1, C.ACCENT_2, 0, Fill)
    local Knob = MakeFrame({
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(ratio, -8, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        ZIndex = 23,
    }, TRK)
    Corner(8, Knob)
    Stroke(2, C.ACCENT_1, 0.1, Knob)
    local dragging = false
    local function UpdSlider(inputX)
        local t2 = math.clamp((inputX - TRK.AbsolutePosition.X) / TRK.AbsoluteSize.X, 0, 1)
        local value = math.floor(minV + t2 * (maxV - minV))
        Tween(Fill, TI_FAST, {Size = UDim2.new(t2, 0, 1, 0)})
        Tween(Knob, TI_FAST, {Position = UDim2.new(t2, -8, 0.5, -8)})
        VL.Text = tostring(value) .. (suffix or "")
        if onChange then onChange(value) end
    end
    TRK.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; UpdSlider(i.Position.X)
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            UpdSlider(i.Position.X)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    return Row
end

-- ==============================================================================
-- SECCION 12 -- VENTANA PRINCIPAL + SIDEBAR
-- ==============================================================================

local function CreateMainWindow()
    MainWindow = MakeFrame({
        Name = "MainWindow",
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 10,
    }, ScreenGui)

    -- HEADER glass
    local Header = MakeFrame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = C.HEADER_BG,
        BackgroundTransparency = GT.HEADER,
        ZIndex = 12,
    }, MainWindow)
    Stroke(1, C.GLASS_BORDER, 0.5, Header)
    Gradient(C.HEADER_BG, Color3.fromRGB(10, 18, 32), 90, Header)

    -- Logo Q en header
    local HLogo = MakeLabel({
        Size = UDim2.new(0, 34, 0, 34),
        Position = UDim2.new(0, 12, 0.5, -17),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.5,
        Text = "Q",
        Font = Enum.Font.GothamBold,
        TextSize = 26,
        TextColor3 = C.ACCENT_1,
        ZIndex = 13,
    }, Header)
    Corner(17, HLogo)
    task.spawn(function()
        while HLogo and HLogo.Parent do
            Tween(HLogo, TI_SINE, {TextColor3 = C.ACCENT_2}); task.wait(1.5)
            Tween(HLogo, TI_SINE, {TextColor3 = C.ACCENT_1}); task.wait(1.5)
        end
    end)

    MakeLabel({
        Size = UDim2.new(0, 180, 0, 18),
        Position = UDim2.new(0, 52, 0, 8),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS  v4.1",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, Header)
    MakeLabel({
        Size = UDim2.new(0, 180, 0, 12),
        Position = UDim2.new(0, 52, 0, 29),
        BackgroundTransparency = 1,
        Text = "IY Engine  |  Delta",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.ACCENT_1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, Header)

    -- Badge del juego
    local GameBadge = MakeLabel({
        Size = UDim2.new(0, 200, 0, 26),
        Position = UDim2.new(0.5, -100, 0.5, -13),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.50,
        Text = GAME_NAME:sub(1, 20),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        ZIndex = 13,
    }, Header)
    Corner(13, GameBadge)
    Stroke(1, C.GLASS_BORDER, 0.4, GameBadge)

    -- Botones de sistema
    local SysF = MakeFrame({
        Size = UDim2.new(0, 80, 0, 36),
        Position = UDim2.new(1, -90, 0.5, -18),
        BackgroundTransparency = 1,
        ZIndex = 13,
    }, Header)

    local function SysBtn(lbl, col, xOff)
        local b = MakeButton({
            Size = UDim2.new(0, 30, 0, 30),
            Position = UDim2.new(0, xOff, 0.5, -15),
            BackgroundColor3 = C.GLASS_LIGHT,
            BackgroundTransparency = 0.55,
            Text = lbl,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = col,
            ZIndex = 14,
        }, SysF)
        Corner(8, b)
        HoverGlass(b, 0.55, 0.3)
        return b
    end

    local MinBtn   = SysBtn("-", C.TEXT_SOFT, 0)
    local CloseBtn = SysBtn("X", C.TEXT_RED, 40)

    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainWindow, TI_MED, {Size = UDim2.new(1, 0, 0, 52)})
        else
            Tween(MainWindow, TI_MED, {Size = UDim2.fromScale(1, 1)})
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow, TI_MED, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        task.wait(0.35)
        pcall(function() ScreenGui:Destroy() end)
    end)

    -- SIDEBAR glass
    Sidebar = MakeFrame({
        Name = "Sidebar",
        Size = UDim2.new(0, 198, 1, -52),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundColor3 = C.SIDEBAR_BG,
        BackgroundTransparency = GT.SIDEBAR,
        ZIndex = 11,
    }, MainWindow)
    Stroke(1, C.GLASS_BORDER, 0.5, Sidebar)

    -- Perfil de usuario
    local SbP = MakeFrame({
        Size = UDim2.new(1, -16, 0, 68),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.45,
        ZIndex = 12,
    }, Sidebar)
    Corner(12, SbP)
    Stroke(1, C.ACCENT_1, 0.5, SbP)

    local Av = MakeLabel({
        Size = UDim2.new(0, 42, 0, 42),
        Position = UDim2.new(0, 10, 0.5, -21),
        BackgroundColor3 = C.GLASS_ULTRA,
        BackgroundTransparency = 0.35,
        Text = string.upper(string.sub(DISPLAY_NAME, 1, 2)),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = C.ACCENT_1,
        ZIndex = 13,
    }, SbP)
    Corner(21, Av)
    Stroke(2, C.ACCENT_1, 0.2, Av)

    MakeLabel({
        Size = UDim2.new(1, -60, 0, 18),
        Position = UDim2.new(0, 58, 0, 10),
        BackgroundTransparency = 1,
        Text = DISPLAY_NAME,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
    }, SbP)
    MakeLabel({
        Size = UDim2.new(1, -60, 0, 13),
        Position = UDim2.new(0, 58, 0, 30),
        BackgroundTransparency = 1,
        Text = "@" .. USERNAME,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.ACCENT_1,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, SbP)
    local OnB = MakeLabel({
        Size = UDim2.new(0, 64, 0, 12),
        Position = UDim2.new(0, 58, 0, 46),
        BackgroundColor3 = C.GLASS_LIGHT,
        BackgroundTransparency = 0.5,
        Text = "* AI Online",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = C.TEXT_GREEN,
        ZIndex = 13,
    }, SbP)
    Corner(6, OnB)

    -- Tabs Sidebar
    local SbScroll = MakeScroll({
        Size = UDim2.new(1, 0, 1, -88),
        Position = UDim2.new(0, 0, 0, 86),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ZIndex = 12,
    }, Sidebar)
    local SbList = MakeFrame({
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 12,
    }, SbScroll)
    local SbLL = ListLayout({Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, SbList)

    local TABS = {
        {name = "START",           icon = "#",  label = "Inicio",        order = 1},
        {name = "CMD_BAR",         icon = ">",  label = "Comandos IY",   order = 2},
        {name = "SCRIPT_HUB",      icon = "!",  label = "Script Hub",    order = 3},
        {name = "QUANTUM_ORACLE",  icon = "*",  label = "Oracle AI",     order = 4},
        {name = "PLAYER_MODS",     icon = "P",  label = "Player Mods",   order = 5},
        {name = "WORLD_MODS",      icon = "W",  label = "World Mods",    order = 6},
        {name = "ESP_VISUALS",     icon = "E",  label = "ESP & Visuals", order = 7},
        {name = "TELEPORT",        icon = "T",  label = "Teleport",      order = 8},
        {name = "GAME_BOOSTER",    icon = "B",  label = "Game Booster",  order = 9},
        {name = "SYSTEM_SETTINGS", icon = "S",  label = "Ajustes",       order = 10},
        {name = "POWER",           icon = "O",  label = "Power",         order = 11},
    }

    for _, tab in ipairs(TABS) do
        local Btn = MakeButton({
            Name = tab.name,
            Size = UDim2.new(1, -12, 0, 38),
            BackgroundColor3 = C.GLASS_DARK,
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = tab.order,
            ZIndex = 13,
        }, SbList)
        Corner(9, Btn)
        Padding(0, 6, 0, 6, Btn)

        local Ind = MakeFrame({
            Name = "Indicator",
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = C.ACCENT_1,
            Visible = false,
            ZIndex = 14,
        }, Btn)
        Corner(2, Ind)

        MakeLabel({
            Size = UDim2.new(0, 22, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.icon,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = C.TEXT_MUTED,
            ZIndex = 14,
        }, Btn)
        MakeLabel({
            Size = UDim2.new(1, -38, 1, 0),
            Position = UDim2.new(0, 34, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.label,
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 14,
        }, Btn)

        SidebarButtons[tab.name] = Btn
        Btn.MouseButton1Click:Connect(function()
            ClearContent()
            SetActiveTab(tab.name)
            ENV.QOS_ActiveTab = tab.name
            local fnKey = "QOS_Tab_" .. tab.name
            if _G[fnKey] then pcall(_G[fnKey]) end
        end)
        HoverGlass(Btn, 1, GT.HOVER)
    end

    -- Auto-size SbList
    SbLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SbList.Size = UDim2.new(1, 0, 0, SbLL.AbsoluteContentSize.Y + 8)
        SbScroll.CanvasSize = UDim2.new(0, 0, 0, SbLL.AbsoluteContentSize.Y + 8)
    end)

    -- CONTENT AREA glass
    ContentArea = MakeFrame({
        Name = "ContentArea",
        Size = UDim2.new(1, -198, 1, -52),
        Position = UDim2.new(0, 198, 0, 52),
        BackgroundColor3 = C.CONTENT_BG,
        BackgroundTransparency = GT.PANEL,
        ZIndex = 11,
    }, MainWindow)

    -- Animacion de entrada
    Tween(MainWindow, TI_BOUNCE, {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
    })
end

-- ==============================================================================
-- SECCION 13 -- TAB: START
-- ==============================================================================

_G["QOS_Tab_START"] = function()
    local Tab = MakeFrame({Name="Tab_START", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    local Scroll = MakeScroll({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local List = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,0)}, List)
    Padding(0,0,20,0, List)

    SectionHeader(List, "[Q] INICIO  |  Quantum OS v4.1", "Glass Edition  |  IY Engine  |  Delta Executor")

    -- Stats cards glass
    local StatsRow = MakeFrame({Size=UDim2.new(1,0,0,90), BackgroundTransparency=1, ZIndex=15}, List)
    local SGrid = MakeFrame({Size=UDim2.new(1,-24,1,-16), Position=UDim2.new(0,12,0,8), BackgroundTransparency=1, ZIndex=15}, StatsRow)
    Make("UIGridLayout", {CellSize=UDim2.new(0.25,-4,1,-4), CellPadding=UDim2.new(0,4,0,4)}, SGrid)

    local cmdCount = 0
    for _ in pairs(Commands) do cmdCount = cmdCount + 1 end

    local statsItems = {
        {label="Jugador",   val=DISPLAY_NAME:sub(1,11), icon="P", color=C.ACCENT_1},
        {label="Juego",     val=GAME_NAME:sub(1,11),    icon="G", color=C.ACCENT_2},
        {label="AI Status", val="Online",               icon="A", color=C.TEXT_GREEN},
        {label="Comandos",  val=tostring(cmdCount),     icon="C", color=C.ACCENT_GOLD},
    }
    for _, s in ipairs(statsItems) do
        local Card = MakeFrame({
            BackgroundColor3 = C.GLASS_MED,
            BackgroundTransparency = GT.CARD,
            ZIndex = 16,
        }, SGrid)
        Corner(12, Card)
        Stroke(1, C.GLASS_BORDER, 0.4, Card)
        MakeLabel({Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,6), BackgroundTransparency=1,
            Text="["..s.icon.."]", TextSize=14, Font=Enum.Font.GothamBold, TextColor3=s.color, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,18), Position=UDim2.new(0,4,0,32), BackgroundTransparency=1,
            Text=s.val, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=s.color, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,13), Position=UDim2.new(0,4,0,52), BackgroundTransparency=1,
            Text=s.label, Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TEXT_MUTED, ZIndex=17}, Card)
    end

    -- Agentes activos
    local AgTitle = MakeFrame({Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, ZIndex=15}, List)
    MakeLabel({Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1,
        Text="SISTEMA MULTI-AGENTE ACTIVO", Font=Enum.Font.GothamBold, TextSize=11,
        TextColor3=C.ACCENT_1, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=15}, AgTitle)

    local AgList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, List)
    ListLayout({Padding=UDim.new(0,4)}, AgList)
    Padding(0,12,0,12, AgList)

    local agents = {
        {icon="[O]", name="Orquestador",   model="llama-3.3-70b",   desc="Dirige el flujo multi-agente",       color=C.ACCENT_1},
        {icon="[G]", name="Game Analyst",  model="nemotron-120b",   desc="Analisis de mecanicas de juego",     color=Color3.fromRGB(255,160,60)},
        {icon="[C]", name="Code Expert",   model="qwen3-coder",     desc="Scripts Lua y errores Delta",        color=Color3.fromRGB(60,220,180)},
        {icon="[S]", name="Strategy",      model="deepseek-v4",     desc="Estrategias y builds optimos",       color=Color3.fromRGB(220,80,80)},
        {icon="[A]", name="Creative",      model="gemma-4-31b",     desc="Ideas y personalizacion",            color=Color3.fromRGB(140,200,255)},
        {icon="[F]", name="Fast Agent",    model="llama-3.2-3b",    desc="Respuestas rapidas",                 color=Color3.fromRGB(255,220,60)},
    }
    for _, ag in ipairs(agents) do
        local AC = MakeFrame({Size=UDim2.new(1,0,0,46), BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD, ZIndex=16}, AgList)
        Corner(10, AC)
        Stroke(1, C.GLASS_BORDER, 0.4, AC)
        local IF2 = MakeFrame({Size=UDim2.new(0,32,0,32), Position=UDim2.new(0,10,0.5,-16),
            BackgroundColor3=ag.color, BackgroundTransparency=0.7, ZIndex=17}, AC)
        Corner(8, IF2)
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=ag.icon,
            Font=Enum.Font.GothamBold, TextSize=10, TextColor3=ag.color, ZIndex=18}, IF2)
        MakeLabel({Size=UDim2.new(1,-170,0,18), Position=UDim2.new(0,50,0,6), BackgroundTransparency=1,
            Text=ag.name, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AC)
        MakeLabel({Size=UDim2.new(1,-170,0,13), Position=UDim2.new(0,50,0,24), BackgroundTransparency=1,
            Text=ag.desc, Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AC)
        local StB = MakeLabel({Size=UDim2.new(0,100,0,18), Position=UDim2.new(1,-108,0.5,-9),
            BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5,
            Text="* " .. ag.model, Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TEXT_GREEN, ZIndex=17}, AC)
        Corner(9, StB)
    end

    local LL = List:FindFirstChildWhichIsA("UIListLayout")
    if LL then
        LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, LL.AbsoluteContentSize.Y + 20)
        end)
    end
end

-- ==============================================================================
-- SECCION 14 -- TAB: CMD BAR (Infinite Yield style)
-- ==============================================================================

_G["QOS_Tab_CMD_BAR"] = function()
    local Tab = MakeFrame({Name="Tab_CMD", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "[>] BARRA DE COMANDOS", "Infinite Yield Engine | Prefijo: " .. (ENV.QOS_Prefix or ";") .. " | Escribe un comando")

    local InfoBar = MakeFrame({Size=UDim2.new(1,-32,0,34), Position=UDim2.new(0,16,0,68),
        BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.45, ZIndex=15}, Tab)
    Corner(10, InfoBar)
    Stroke(1, C.ACCENT_1, 0.5, InfoBar)
    MakeLabel({Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1,
        Text="Prefijo: ["..ENV.QOS_Prefix.."]  |  Ej: "..ENV.QOS_Prefix.."fly 80  |  "..ENV.QOS_Prefix.."speed 200  |  "..ENV.QOS_Prefix.."help",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.ACCENT_1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, InfoBar)

    -- Command box glass
    local CmdFrame = MakeFrame({Size=UDim2.new(1,-32,0,54), Position=UDim2.new(0,16,0,110),
        BackgroundColor3=C.GLASS_DARK, BackgroundTransparency=0.35, ZIndex=15}, Tab)
    Corner(12, CmdFrame)
    local cmdStroke = Stroke(1, C.GLASS_BORDER, 0.3, CmdFrame)

    local CmdInput = MakeBox({
        Name="IY_CmdInput",
        Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText=ENV.QOS_Prefix.."comando arg1 arg2...",
        Font=Enum.Font.Code, TextSize=14, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=16}, CmdFrame)
    CmdInput.Focused:Connect(function()   Tween(cmdStroke, TI_FAST, {Color=C.ACCENT_1, Transparency=0}) end)
    CmdInput.FocusLost:Connect(function() Tween(cmdStroke, TI_FAST, {Color=C.GLASS_BORDER, Transparency=0.3}) end)

    local ExecBtn = MakeButton({Size=UDim2.new(0,78,0,38), Position=UDim2.new(1,-88,0.5,-19),
        BackgroundColor3=C.ACCENT_1, BackgroundTransparency=0.15,
        Text="EXEC", Font=Enum.Font.GothamBold, TextSize=13, TextColor3=Color3.new(1,1,1), ZIndex=16}, CmdFrame)
    Corner(10, ExecBtn)
    HoverGlass(ExecBtn, 0.15, 0)

    -- Historial
    local HistTitle = MakeFrame({Size=UDim2.new(1,-32,0,24), Position=UDim2.new(0,16,0,172),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="HISTORIAL",
        Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.ACCENT_1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, HistTitle)

    local HistScroll = MakeScroll({Size=UDim2.new(1,-32,1,-290), Position=UDim2.new(0,16,0,200),
        BackgroundColor3=C.GLASS_DARK, BackgroundTransparency=0.40, ScrollBarThickness=2, ZIndex=15}, Tab)
    Corner(10, HistScroll)
    Stroke(1, C.GLASS_BORDER, 0.5, HistScroll)
    local HistList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, HistScroll)
    ListLayout({Padding=UDim.new(0,2)}, HistList)
    Padding(6,8,6,8, HistList)

    local function RefreshHistory()
        for _, c in ipairs(HistList:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        for _, entry in ipairs(ENV.QOS_CommandHistory) do
            local Row = MakeButton({Size=UDim2.new(1,0,0,30),
                BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5, ZIndex=16}, HistList)
            Corner(7, Row)
            MakeLabel({Size=UDim2.new(0,16,1,0), BackgroundTransparency=1, Text=">",
                Font=Enum.Font.Code, TextSize=11, TextColor3=C.ACCENT_1, ZIndex=17}, Row)
            MakeLabel({Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,18,0,0), BackgroundTransparency=1,
                Text=entry, Font=Enum.Font.Code, TextSize=11, TextColor3=C.ACCENT_2,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Row)
            Row.MouseButton1Click:Connect(function()
                CmdInput.Text = entry
                CmdInput:CaptureFocus()
            end)
            HoverGlass(Row, 0.5, 0.3)
        end
        local hl = HistList:FindFirstChildWhichIsA("UIListLayout")
        if hl then HistScroll.CanvasSize = UDim2.new(0,0,0,hl.AbsoluteContentSize.Y+12) end
    end
    RefreshHistory()

    -- Quick commands
    local QuickTitle = MakeFrame({Size=UDim2.new(1,-32,0,24), Position=UDim2.new(0,16,1,-168),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="COMANDOS RAPIDOS",
        Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.ACCENT_1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, QuickTitle)

    local QScroll = MakeScroll({
        Size=UDim2.new(1,-32,0,90), Position=UDim2.new(0,16,1,-144),
        BackgroundTransparency=1, ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.X, ZIndex=15}, Tab)
    local QRow = MakeFrame({Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
        BackgroundTransparency=1, ZIndex=15}, QScroll)
    local QL = ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6)}, QRow)

    local quickCmds = {
        {label="Fly ON",       cmd=";fly 60"},
        {label="Fly OFF",      cmd=";fly"},
        {label="Speed 200",    cmd=";speed 200"},
        {label="Speed Reset",  cmd=";speed 16"},
        {label="NoClip",       cmd=";noclip"},
        {label="God Mode",     cmd=";godmode"},
        {label="ESP ON",       cmd=";esp"},
        {label="Anti-Aim",     cmd=";antiaim"},
        {label="Fullbright",   cmd=";fullbright"},
        {label="Inf Jump",     cmd=";jump 200"},
        {label="Lista Players",cmd=";players"},
        {label="Rejoin",       cmd=";rejoin"},
        {label="Anti-AFK",     cmd=";antiafk"},
    }
    for _, qc in ipairs(quickCmds) do
        local QB = MakeButton({Size=UDim2.new(0,108,0,36),
            BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD,
            BorderSizePixel=0, Text="", ZIndex=16}, QRow)
        Corner(10, QB)
        Stroke(1, C.GLASS_BORDER, 0.4, QB)
        MakeLabel({Size=UDim2.new(1,-16,0,16), Position=UDim2.new(0,8,0,3), BackgroundTransparency=1,
            Text=qc.label, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.ACCENT_1,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, QB)
        MakeLabel({Size=UDim2.new(1,-16,0,13), Position=UDim2.new(0,8,0,19), BackgroundTransparency=1,
            Text=qc.cmd, Font=Enum.Font.Code, TextSize=9, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, QB)
        QB.MouseButton1Click:Connect(function()
            CmdInput.Text = qc.cmd
            Tween(QB, TI_FAST, {BackgroundTransparency = GT.HOVER})
            task.wait(0.2)
            Tween(QB, TI_FAST, {BackgroundTransparency = GT.CARD})
        end)
        HoverGlass(QB, GT.CARD, GT.HOVER)
    end
    QL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        QScroll.CanvasSize = UDim2.new(0, QL.AbsoluteContentSize.X + 12, 0, 0)
    end)

    local function Execute()
        local input = CmdInput.Text
        if input == "" then return end
        Tween(ExecBtn, TI_FAST, {BackgroundColor3 = C.TOGGLE_ON, BackgroundTransparency = 0.1})
        -- Si no tiene prefijo, agregarlo automaticamente
        if input:sub(1, #ENV.QOS_Prefix) ~= ENV.QOS_Prefix then
            input = ENV.QOS_Prefix .. input
        end
        ParseAndExecute(input)
        CmdInput.Text = ""
        RefreshHistory()
        task.wait(0.3)
        Tween(ExecBtn, TI_FAST, {BackgroundColor3 = C.ACCENT_1, BackgroundTransparency = 0.15})
    end
    ExecBtn.MouseButton1Click:Connect(Execute)
    CmdInput.FocusLost:Connect(function(enter) if enter then Execute() end end)
end

-- ==============================================================================
-- SECCION 15 -- TAB: QUANTUM ORACLE
-- ==============================================================================

_G["QOS_Tab_QUANTUM_ORACLE"] = function()
    local Tab = MakeFrame({Name="Tab_ORACLE", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[*] QUANTUM ORACLE", "Multi-Agent AI | IY Engine | Juego: " .. GAME_NAME)

    -- Info panel glass
    local OrbFrame = MakeFrame({Size=UDim2.new(1,-32,0,88), Position=UDim2.new(0,16,0,68),
        BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.40, ZIndex=16}, Tab)
    Corner(14, OrbFrame)
    Stroke(1, C.ACCENT_1, 0.4, OrbFrame)

    local OrbBadge = MakeFrame({Size=UDim2.new(0,56,0,56), Position=UDim2.new(0,14,0.5,-28),
        BackgroundColor3=C.GLASS_ULTRA, BackgroundTransparency=0.40, ZIndex=17}, OrbFrame)
    Corner(28, OrbBadge)
    local obs = Stroke(2, C.ACCENT_1, 0, OrbBadge)
    PulseStroke(obs, C.ACCENT_1, C.ACCENT_2)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="AI",
        Font=Enum.Font.GothamBold, TextSize=20, TextColor3=C.ACCENT_1, ZIndex=18}, OrbBadge)

    MakeLabel({Size=UDim2.new(1,-96,0,20), Position=UDim2.new(0,82,0,10), BackgroundTransparency=1,
        Text="QUANTUM ORACLE  |  Multi-Agent AI",
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)
    local AgentBadge = MakeLabel({Size=UDim2.new(1,-96,0,15), Position=UDim2.new(0,82,0,33),
        BackgroundTransparency=1, Text="Orquestador: llama-3.3-70b  |  5 Agentes listos",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.ACCENT_1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)
    local ActiveAg = MakeLabel({Size=UDim2.new(1,-96,0,15), Position=UDim2.new(0,82,0,52),
        BackgroundTransparency=1, Text="Juego: '" .. GAME_NAME .. "'  |  En espera",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_SOFT, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)

    -- Sugerencias rapidas glass
    local SugFrame = MakeFrame({Size=UDim2.new(1,-32,0,26), Position=UDim2.new(0,16,0,163),
        BackgroundTransparency=1, ZIndex=16}, Tab)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4)}, SugFrame)
    local sugs = {"Mejores scripts?", "Fix error Lua", "Como farmear?", "Build optimo", "Anti-ban"}
    for _, sug in ipairs(sugs) do
        local SB = MakeButton({Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5,
            Text=sug, Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.ACCENT_1, ZIndex=17}, SugFrame)
        Corner(10, SB)
        Padding(0,8,0,8,SB)
        Stroke(1, C.ACCENT_1, 0.5, SB)
        SB.MouseButton1Click:Connect(function()
            for _, d in ipairs(Tab:GetDescendants()) do
                if d.Name == "OracleChatInput" then d.Text = sug end
            end
        end)
    end

    -- Chat scroll glass
    local ChatScroll = MakeScroll({Size=UDim2.new(1,-32,1,-236), Position=UDim2.new(0,16,0,196),
        BackgroundColor3=C.GLASS_DARK, BackgroundTransparency=0.40, ScrollBarThickness=2, ZIndex=15}, Tab)
    Corner(12, ChatScroll)
    Stroke(1, C.GLASS_BORDER, 0.5, ChatScroll)
    local ChatList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ChatScroll)
    ListLayout({Padding=UDim.new(0,8)}, ChatList)
    Padding(10,10,10,10, ChatList)

    local function ScrollBot()
        task.wait(0.05)
        local ll2 = ChatList:FindFirstChildWhichIsA("UIListLayout")
        local sz2 = ll2 and ll2.AbsoluteContentSize.Y or 0
        ChatScroll.CanvasSize    = UDim2.new(0,0,0,sz2+20)
        ChatScroll.CanvasPosition = Vector2.new(0, sz2)
    end

    local function AddMsg(text, isUser, meta)
        local col = isUser and C.GLASS_ULTRA or (meta and C.GLASS_MED or C.GLASS_DARK)
        local Bubble = MakeFrame({
            Size = UDim2.new(0.86,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            Position = isUser and UDim2.new(0.14,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3 = col,
            BackgroundTransparency = isUser and 0.25 or 0.45,
            ZIndex = 16,
        }, ChatList)
        Corner(12, Bubble)
        Padding(10,14,10,14, Bubble)
        if not isUser and meta then
            MakeLabel({Size=UDim2.new(1,0,0,17), BackgroundTransparency=1,
                Text=meta.icon.." "..meta.name, Font=Enum.Font.GothamBold, TextSize=10,
                TextColor3=meta.color, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Bubble)
        end
        local yOff = (not isUser and meta) and 17 or 0
        MakeLabel({
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,yOff),
            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
            Text=text, Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.TEXT_WHITE,
            TextWrapped=true,
            TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            ZIndex=17,
        }, Bubble)
        ScrollBot()
    end

    local ThinkBubble = nil
    local function ShowThinking(text)
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end) end
        ThinkBubble = MakeFrame({
            Size=UDim2.new(0.55,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=C.GLASS_MED, BackgroundTransparency=0.45, ZIndex=16,
        }, ChatList)
        Corner(12, ThinkBubble)
        Padding(8,12,8,12, ThinkBubble)
        MakeLabel({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Text="... " .. text, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.TEXT_MUTED, TextWrapped=true, ZIndex=17}, ThinkBubble)
        ScrollBot()
    end
    local function HideThinking()
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end); ThinkBubble = nil end
    end

    AddMsg("[AI] Hola, " .. DISPLAY_NAME .. "! Soy el Quantum Oracle.\n\nDetecte el juego: '" .. GAME_NAME .. "'\nEl Orquestador dirigira tu consulta al agente mas adecuado.\n\nEn que te puedo ayudar?",
        false, {icon="[AI]", name="Quantum Oracle", color=C.ACCENT_1})

    -- Input row glass
    local InputRow = MakeFrame({Size=UDim2.new(1,-32,0,44), Position=UDim2.new(0,16,1,-58),
        BackgroundColor3=C.GLASS_MED, BackgroundTransparency=0.35, ZIndex=16}, Tab)
    Corner(12, InputRow)
    Stroke(1, C.GLASS_BORDER, 0.3, InputRow)
    local ChatInput = MakeBox({Name="OracleChatInput",
        Size=UDim2.new(1,-56,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText="Pregunta algo al Oracle...",
        Font=Enum.Font.Gotham, TextSize=13, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=17}, InputRow)
    local SendBtn = MakeButton({Size=UDim2.new(0,40,0,32), Position=UDim2.new(1,-46,0.5,-16),
        BackgroundColor3=C.ACCENT_1, BackgroundTransparency=0.15,
        Text=">", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.new(1,1,1), ZIndex=17}, InputRow)
    Corner(9, SendBtn)
    HoverGlass(SendBtn, 0.15, 0)

    local isWaiting = false
    local function SendMessage()
        if isWaiting then return end
        local msg = ChatInput.Text:match("^%s*(.-)%s*$")
        if msg == "" then return end
        ChatInput.Text = ""
        isWaiting = true
        SendBtn.Text = "."
        AddMsg(msg, true)
        OracleQuery(msg,
            function(thinkText)
                ShowThinking(thinkText)
                ActiveAg.Text = "[O] " .. thinkText
            end,
            function(agentKey, meta)
                ShowThinking(meta.name .. " respondiendo...")
                ActiveAg.Text   = meta.icon .. " Agente: " .. meta.name
                AgentBadge.Text = meta.icon .. " Usando: " .. meta.name .. "  |  OpenRouter"
            end,
            function(response, meta)
                HideThinking()
                AddMsg(response, false, meta)
                isWaiting     = false
                SendBtn.Text  = ">"
                ActiveAg.Text = "En espera de consulta"
                AgentBadge.Text = "Orquestador: llama-3.3-70b  |  5 Agentes listos"
            end,
            function(errMsg)
                HideThinking()
                AddMsg("[ERROR] " .. tostring(errMsg) .. "\nVerifica tu API Key en Ajustes.", false,
                    {icon="[X]", name="Sistema", color=C.TEXT_RED})
                isWaiting     = false
                SendBtn.Text  = ">"
                ActiveAg.Text = "Error | Verifica conexion"
            end
        )
    end
    SendBtn.MouseButton1Click:Connect(SendMessage)
    ChatInput.FocusLost:Connect(function(enter) if enter then SendMessage() end end)
end

-- ==============================================================================
-- SECCION 16 -- TAB: SCRIPT HUB
-- ==============================================================================

_G["QOS_Tab_SCRIPT_HUB"] = function()
    local Tab = MakeFrame({Name="Tab_HUB", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[!] SCRIPT HUB", "Scripts verificados para Delta Executor | " .. GAME_NAME)

    local ScScroll = MakeScroll({Size=UDim2.new(1,-32,1,-72), Position=UDim2.new(0,16,0,72),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local ScList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ScList or ScScroll)
    -- Corrección: ScList debe parenter a ScScroll
    ScList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ScScroll)
    ListLayout({Padding=UDim.new(0,8)}, ScList)

    local scripts = {
        {title="Auto Farm Pro v5.2",    author="LXNDXN",     verified=true,  icon="F", desc="Auto farm optimizado para Delta",      color=C.ACCENT_GOLD, script='print("[QOS] Auto Farm ON")'},
        {title="ESP Highlight Pro",     author="QuantumDev", verified=true,  icon="E", desc="ESP con Highlight nativo Roblox",      color=C.ACCENT_1,    script='print("[QOS] ESP Highlight activo")'},
        {title="Infinite Jump v2",      author="DeltaFarm",  verified=false, icon="J", desc="Salta infinitamente sin limits",       color=C.TEXT_YELLOW, script='print("[QOS] InfJump activo")'},
        {title="Speed Hack x10",        author="LXNDXN",     verified=true,  icon="S", desc="Velocidad x10 suave y estable",        color=C.ACCENT_GRN,  script='print("[QOS] Speed x10")'},
        {title="God Mode Bypass",       author="NullSec",    verified=false, icon="G", desc="Salud infinita con listener",          color=C.TEXT_RED,    script='print("[QOS] God Mode")'},
        {title="Anti-AFK Pro",          author="QuantumDev", verified=true,  icon="A", desc="Evita el kick de AFK con VIM",        color=C.ACCENT_1,    script='print("[QOS] AntiAFK activo")'},
        {title="Fullbright Scene",      author="LXNDXN",     verified=true,  icon="L", desc="Ilumina la escena completamente",      color=C.ACCENT_2,    script='print("[QOS] Fullbright activo")'},
        {title="Teleport Players",      author="QuantumDev", verified=true,  icon="T", desc="Teleport rapido a jugadores",          color=C.TEXT_GREEN,  script='print("[QOS] TeleportTP activo")'},
    }

    for _, s in ipairs(scripts) do
        local Card = MakeFrame({Size=UDim2.new(1,0,0,76),
            BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD, ZIndex=16}, ScList)
        Corner(14, Card)
        Stroke(1, C.GLASS_BORDER, 0.4, Card)

        local Thumb = MakeFrame({Size=UDim2.new(0,50,0,50), Position=UDim2.new(0,10,0.5,-25),
            BackgroundColor3=s.color, BackgroundTransparency=0.65, ZIndex=17}, Card)
        Corner(12, Thumb)
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
            Text="["..s.icon.."]", Font=Enum.Font.GothamBold, TextSize=16,
            TextColor3=s.color, ZIndex=18}, Thumb)

        MakeLabel({Size=UDim2.new(1,-198,0,20), Position=UDim2.new(0,70,0,10), BackgroundTransparency=1,
            Text=s.title, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-198,0,14), Position=UDim2.new(0,70,0,30), BackgroundTransparency=1,
            Text="by "..s.author.."  |  "..s.desc, Font=Enum.Font.Gotham, TextSize=10,
            TextColor3=C.TEXT_SOFT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)

        if s.verified then
            local VB = MakeLabel({Size=UDim2.new(0,110,0,14), Position=UDim2.new(0,70,0,52),
                BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5, Text="[v] Delta Verified",
                Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TEXT_GREEN, ZIndex=18}, Card)
            Corner(7, VB)
        end

        local ExBtn = MakeButton({Size=UDim2.new(0,80,0,26), Position=UDim2.new(1,-160,0.5,-13),
            BackgroundColor3=C.ACCENT_1, BackgroundTransparency=0.15,
            Text="[>] EXEC", Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), ZIndex=17}, Card)
        Corner(8, ExBtn)
        ExBtn.MouseButton1Click:Connect(function()
            pcall(function() loadstring(s.script)() end)
            PushNotification("Script", s.title .. " ejecutado", "SUCCESS", 3)
        end)
        HoverGlass(ExBtn, 0.15, 0)

        local SaveBtn = MakeButton({Size=UDim2.new(0,62,0,26), Position=UDim2.new(1,-72,0.5,-13),
            BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5,
            Text="[*] SAVE", Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_SOFT, ZIndex=17}, Card)
        Corner(8, SaveBtn)
        Stroke(1, C.GLASS_BORDER, 0.4, SaveBtn)
    end

    local SLL = ScList:FindFirstChildWhichIsA("UIListLayout")
    if SLL then SLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScScroll.CanvasSize = UDim2.new(0,0,0,SLL.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 17 -- TAB: PLAYER MODS
-- ==============================================================================

_G["QOS_Tab_PLAYER_MODS"] = function()
    local Tab = MakeFrame({Name="Tab_PMODS", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[P] PLAYER MODS", "Modificaciones del personaje - IY Engine")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateSliderWidget(SL, "WalkSpeed", 0, 500, 16, "", function(v)
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v end
    end)
    CreateSliderWidget(SL, "JumpPower", 0, 500, 50, "", function(v)
        local hum = GetHumanoid()
        if not hum then return end
        if hum.UseJumpPower then hum.JumpPower = v else hum.JumpHeight = v end
    end)
    CreateSliderWidget(SL, "Gravedad", 0, 500, 196, "", function(v)
        workspace.Gravity = v
    end)
    CreateSliderWidget(SL, "FOV Camara", 10, 120, 70, "deg", function(v)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end)
    CreateSliderWidget(SL, "Tamaño Personaje", 1, 5, 1, "x", function(v)
        local char = GetCharacter()
        if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("NumberValue") then
                local n = obj.Name
                if n == "HeadScale" or n == "BodyHeightScale"
                or n == "BodyWidthScale" or n == "BodyDepthScale" then
                    pcall(function() obj.Value = v end)
                end
            end
        end
    end)

    CreateToggleWidget(SL, "No Clip", false, function(state)
        ENV.QOS_NoclipActive = state
        if state then
            if ENV.QOS_NoclipConn then pcall(function() ENV.QOS_NoclipConn:Disconnect() end) end
            ENV.QOS_NoclipConn = TrackConn(RunService.Stepped:Connect(function()
                local char = GetCharacter()
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end))
        else
            if ENV.QOS_NoclipConn then
                pcall(function() ENV.QOS_NoclipConn:Disconnect() end)
                ENV.QOS_NoclipConn = nil
            end
        end
    end)

    CreateToggleWidget(SL, "God Mode (local)", false, function(state)
        local hum = GetHumanoid()
        if hum then
            hum.MaxHealth = state and math.huge or 100
            hum.Health    = state and math.huge or hum.MaxHealth
        end
    end)

    CreateToggleWidget(SL, "Anti-AFK", false, function(state)
        ENV.QOS_AntiAFK = state
        if state then
            task.spawn(function()
                while ENV.QOS_AntiAFK do
                    pcall(function()
                        local vim = Services.VirtualInputManager
                        vim:SendKeyEvent(true,  Enum.KeyCode.Space, false, game)
                        vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                    task.wait(55)
                end
            end)
        end
    end)

    CreateToggleWidget(SL, "Invisible (local)", false, function(state)
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = state and 1 or 0
                end
            end
        end
    end)

    CreateToggleWidget(SL, "Vuelo (60 vel)", false, function(state)
        if state ~= ENV.QOS_FlyActive then
            ParseAndExecute(";fly 60")
        end
    end)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 18 -- TAB: WORLD MODS
-- ==============================================================================

_G["QOS_Tab_WORLD_MODS"] = function()
    local Tab = MakeFrame({Name="Tab_WMODS", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[W] WORLD MODS", "Modificaciones del mundo - Lighting - Ambiente")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateSliderWidget(SL, "Hora del Dia (0-23)", 0, 23, 12, "h", function(v)
        Lighting.TimeOfDay = string.format("%02d:00:00", v)
    end)
    CreateSliderWidget(SL, "Brillo (Brightness)", 0, 10, 2, "x", function(v)
        Lighting.Brightness = v
    end)
    CreateSliderWidget(SL, "Niebla (FogEnd)", 0, 10000, 100000, "m", function(v)
        Lighting.FogEnd = v; Lighting.FogStart = 0
    end)
    CreateSliderWidget(SL, "Saturacion", -1, 3, 0, "", function(v)
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
        cc.Saturation = v
    end)
    CreateSliderWidget(SL, "Contraste", -1, 3, 0, "", function(v)
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
        cc.Contrast = v
    end)

    CreateToggleWidget(SL, "Fullbright", false, function(state)
        ParseAndExecute(";fullbright")
    end)

    CreateToggleWidget(SL, "Quitar Sombras (FPS)", false, function(state)
        Lighting.GlobalShadows = not state
    end)

    CreateToggleWidget(SL, "Quitar Niebla", false, function(state)
        Lighting.FogEnd = state and 1e6 or 1000
    end)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 19 -- TAB: ESP & VISUALS
-- ==============================================================================

_G["QOS_Tab_ESP_VISUALS"] = function()
    local Tab = MakeFrame({Name="Tab_ESP", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[E] ESP & VISUALS", "ESP con Highlight nativo | Chams | Wireframe")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateToggleWidget(SL, "ESP Jugadores (Highlight)", false, function(state)
        if state ~= ENV.QOS_EspActive then ParseAndExecute(";esp") end
    end)

    CreateToggleWidget(SL, "Chams Neon (personaje tuyo)", false, function(state)
        local char = GetCharacter()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function()
                        p.Material = state and Enum.Material.Neon or Enum.Material.SmoothPlastic
                    end)
                end
            end
        end
    end)

    CreateToggleWidget(SL, "Wireframe del mapa", false, function(state)
        for _, obj in ipairs(workspace:GetDescendants()) do
            local char = GetCharacter()
            if obj:IsA("BasePart") and (not char or not obj:IsDescendantOf(char)) then
                pcall(function()
                    obj.Transparency = state and 0.87 or 0
                end)
            end
        end
    end)

    CreateToggleWidget(SL, "Anti-Aim (cabeza)", false, function(state)
        if state ~= ENV.QOS_AntiAim then ParseAndExecute(";antiaim") end
    end)

    CreateSliderWidget(SL, "Transparencia del mapa", 0, 100, 0, "%", function(v)
        for _, obj in ipairs(workspace:GetDescendants()) do
            local char = GetCharacter()
            if obj:IsA("BasePart") and (not char or not obj:IsDescendantOf(char)) then
                pcall(function() obj.Transparency = v / 100 end)
            end
        end
    end)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 20 -- TAB: TELEPORT
-- ==============================================================================

_G["QOS_Tab_TELEPORT"] = function()
    local Tab = MakeFrame({Name="Tab_TP", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[T] TELEPORT", "Teleportacion a jugadores - Coordenadas - Bring")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,6)}, SL)
    Padding(12,14,20,14, SL)

    local PlTitle = MakeFrame({Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, ZIndex=15}, SL)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="JUGADORES EN EL SERVIDOR",
        Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.ACCENT_1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, PlTitle)

    local function RefreshPlayers()
        for _, c in ipairs(SL:GetChildren()) do
            if c.Name == "PlayerTPCard" then c:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            local Card = MakeFrame({Name="PlayerTPCard", Size=UDim2.new(1,0,0,54),
                BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD, ZIndex=16}, SL)
            Corner(12, Card)
            Stroke(1, p == LocalPlayer and C.ACCENT_1 or C.GLASS_BORDER,
                p == LocalPlayer and 0.2 or 0.5, Card)

            local Av2 = MakeLabel({Size=UDim2.new(0,36,0,36), Position=UDim2.new(0,10,0.5,-18),
                BackgroundColor3=C.GLASS_ULTRA, BackgroundTransparency=0.4,
                Text=string.upper(string.sub(p.DisplayName,1,2)),
                Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.ACCENT_1, ZIndex=17}, Card)
            Corner(18, Av2)

            MakeLabel({Size=UDim2.new(1,-172,0,18), Position=UDim2.new(0,54,0,8), BackgroundTransparency=1,
                Text=p.DisplayName .. (p == LocalPlayer and " [TU]" or ""),
                Font=Enum.Font.GothamBold, TextSize=12, TextColor3=C.TEXT_WHITE,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
            MakeLabel({Size=UDim2.new(1,-172,0,13), Position=UDim2.new(0,54,0,28), BackgroundTransparency=1,
                Text="@" .. p.Name, Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)

            if p ~= LocalPlayer then
                local TPBtn = MakeButton({Size=UDim2.new(0,66,0,26), Position=UDim2.new(1,-144,0.5,-13),
                    BackgroundColor3=C.ACCENT_1, BackgroundTransparency=0.2,
                    Text="[T] Ir", Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), ZIndex=17}, Card)
                Corner(8, TPBtn)
                TPBtn.MouseButton1Click:Connect(function()
                    ParseAndExecute(";tp " .. p.Name)
                end)
                HoverGlass(TPBtn, 0.2, 0)

                local BringBtn = MakeButton({Size=UDim2.new(0,70,0,26), Position=UDim2.new(1,-68,0.5,-13),
                    BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5,
                    Text="[B] Traer", Font=Enum.Font.GothamSemibold, TextSize=10, TextColor3=C.TEXT_SOFT, ZIndex=17}, Card)
                Corner(8, BringBtn)
                Stroke(1, C.GLASS_BORDER, 0.4, BringBtn)
                BringBtn.MouseButton1Click:Connect(function()
                    ParseAndExecute(";bringtp " .. p.Name)
                end)
                HoverGlass(BringBtn, 0.5, 0.3)
            end
        end
    end
    RefreshPlayers()

    local RefBtn = MakeButton({Size=UDim2.new(1,0,0,36),
        BackgroundColor3=C.GLASS_LIGHT, BackgroundTransparency=0.5,
        BorderSizePixel=0, Text="[R] Actualizar lista de jugadores",
        Font=Enum.Font.GothamSemibold, TextSize=13, TextColor3=C.ACCENT_1, ZIndex=15}, SL)
    Corner(10, RefBtn)
    Stroke(1, C.ACCENT_1, 0.5, RefBtn)
    RefBtn.MouseButton1Click:Connect(RefreshPlayers)
    HoverGlass(RefBtn, 0.5, 0.3)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 21 -- TAB: GAME BOOSTER
-- ==============================================================================

_G["QOS_Tab_GAME_BOOSTER"] = function()
    local Tab = MakeFrame({Name="Tab_BOOST", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[B] GAME BOOSTER", "Optimizaciones de FPS y rendimiento para Delta")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateToggleWidget(SL, "Quitar sombras (FPS boost)", false, function(state)
        Lighting.GlobalShadows = not state
    end)
    CreateToggleWidget(SL, "Reducir texturas (FPS boost)", false, function(state)
        if state then
            task.spawn(function()
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") then
                        pcall(function() p.Material = Enum.Material.SmoothPlastic end)
                    end
                end
            end)
        end
    end)
    CreateToggleWidget(SL, "Quitar niebla", false, function(state)
        Lighting.FogEnd = state and 1e6 or 1000
    end)
    CreateToggleWidget(SL, "Ocultar otros jugadores", false, function(state)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = state and 1 or 0
                    end
                end
            end
        end
    end)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 22 -- TAB: SYSTEM SETTINGS
-- ==============================================================================

_G["QOS_Tab_SYSTEM_SETTINGS"] = function()
    local Tab = MakeFrame({Name="Tab_SETTINGS", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[S] AJUSTES", "Configuracion - API Key - Prefijo - Info del sistema")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    -- API Key card glass
    local KC = MakeFrame({Size=UDim2.new(1,0,0,96), BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD, ZIndex=16}, SL)
    Corner(14, KC)
    Stroke(1, C.GLASS_BORDER, 0.4, KC)
    MakeLabel({Size=UDim2.new(1,-20,0,20), Position=UDim2.new(0,14,0,10), BackgroundTransparency=1,
        Text="OpenRouter API Key", Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KC)
    MakeLabel({Size=UDim2.new(1,-20,0,14), Position=UDim2.new(0,14,0,30), BackgroundTransparency=1,
        Text="Estado: " .. (ENV.QOS_OpenRouterKey and "[v] Conectado" or "[x] No conectado"),
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3 = ENV.QOS_OpenRouterKey and C.TEXT_GREEN or C.TEXT_RED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KC)
    local ApiBox = MakeBox({Size=UDim2.new(1,-28,0,34), Position=UDim2.new(0,14,0,52),
        BackgroundColor3=C.GLASS_DARK, BackgroundTransparency=0.40, BorderSizePixel=0,
        Text=ENV.QOS_OpenRouterKey or "", PlaceholderText="sk-or-v1-...",
        Font=Enum.Font.Code, TextSize=12, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=17}, KC)
    Corner(8, ApiBox)
    Padding(0,10,0,10, ApiBox)
    Stroke(1, C.GLASS_BORDER, 0.3, ApiBox)
    ApiBox.FocusLost:Connect(function(enter)
        if enter then
            ENV.QOS_OpenRouterKey = ApiBox.Text:gsub("%s+","")
            PushNotification("API Key","Guardada en sesion","SUCCESS",3)
        end
    end)

    -- Prefijo
    local PrefixCard = MakeFrame({Size=UDim2.new(1,0,0,56), BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD, ZIndex=16}, SL)
    Corner(14, PrefixCard)
    Stroke(1, C.GLASS_BORDER, 0.4, PrefixCard)
    MakeLabel({Size=UDim2.new(1,-80,0,18), Position=UDim2.new(0,14,0,8), BackgroundTransparency=1,
        Text="Prefijo de comandos", Font=Enum.Font.GothamBold, TextSize=12, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, PrefixCard)
    MakeLabel({Size=UDim2.new(1,-80,0,12), Position=UDim2.new(0,14,0,28), BackgroundTransparency=1,
        Text="Caracter que activa los comandos (ej: ; . , !)",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, PrefixCard)
    local PBox = MakeBox({Size=UDim2.new(0,46,0,34), Position=UDim2.new(1,-58,0.5,-17),
        BackgroundColor3=C.GLASS_DARK, BackgroundTransparency=0.4, BorderSizePixel=0,
        Text=ENV.QOS_Prefix or ";",
        Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C.ACCENT_1,
        ClearTextOnFocus=false, ZIndex=17}, PrefixCard)
    Corner(8, PBox)
    Stroke(1, C.ACCENT_1, 0.4, PBox)
    PBox.FocusLost:Connect(function(enter)
        if enter and #PBox.Text >= 1 then
            ENV.QOS_Prefix = PBox.Text:sub(1,1)
            PushNotification("Prefijo","Nuevo prefijo: " .. ENV.QOS_Prefix,"SUCCESS",3)
        end
    end)

    -- Info del sistema
    local InfoCard = MakeFrame({Size=UDim2.new(1,0,0,86), BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD, ZIndex=16}, SL)
    Corner(14, InfoCard)
    Stroke(1, C.GLASS_BORDER, 0.4, InfoCard)
    local cmdCount2 = 0
    for _ in pairs(Commands) do cmdCount2 = cmdCount2 + 1 end
    local infoLines = {
        "[Q] Quantum OS v4.1 - Delta Edition - Glass UI",
        "[I] Jugador: " .. DISPLAY_NAME .. " (@" .. USERNAME .. ")",
        "[G] Juego: " .. GAME_NAME,
        "[J] PlaceId: " .. tostring(PlaceId),
        "[C] Comandos cargados: " .. cmdCount2,
    }
    ListLayout({Padding=UDim.new(0,1)}, InfoCard)
    Padding(8,12,8,12, InfoCard)
    for _, line in ipairs(infoLines) do
        MakeLabel({Size=UDim2.new(1,0,0,14), BackgroundTransparency=1, Text=line,
            Font=Enum.Font.Code, TextSize=10, TextColor3=C.TEXT_SOFT,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, InfoCard)
    end

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 23 -- TAB: POWER
-- ==============================================================================

_G["QOS_Tab_POWER"] = function()
    local Tab = MakeFrame({Name="Tab_POWER", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[O] POWER", "Opciones de sesion y servidor")

    local Center = MakeFrame({Size=UDim2.new(0,300,0,280), Position=UDim2.new(0.5,-150,0.5,-140),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    local PList = MakeFrame({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, Center)
    ListLayout({Padding=UDim.new(0,10), HorizontalAlignment=Enum.HorizontalAlignment.Center}, PList)

    local powerOpts = {
        {label="Rejoin (mismo server)",  desc="Vuelves al mismo servidor", color=C.ACCENT_1,    cmd=";rejoin"},
        {label="New Server (hop)",       desc="Saltas a otro servidor",    color=C.ACCENT_GOLD, cmd=";server"},
        {label="Reset Personaje",        desc="Matas tu personaje local",  color=C.TEXT_YELLOW, cmd=";reset"},
        {label="Cerrar Quantum OS",      desc="Destruye el GUI",           color=C.TEXT_RED,    cmd="CLOSE"},
    }
    for _, opt in ipairs(powerOpts) do
        local Btn = MakeButton({Size=UDim2.new(1,0,0,56),
            BackgroundColor3=C.GLASS_MED, BackgroundTransparency=GT.CARD,
            BorderSizePixel=0, Text="", ZIndex=16}, PList)
        Corner(14, Btn)
        Stroke(1, opt.color, 0.5, Btn)
        MakeLabel({Size=UDim2.new(1,-20,0,22), Position=UDim2.new(0,14,0,7), BackgroundTransparency=1,
            Text=opt.label, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=opt.color,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Btn)
        MakeLabel({Size=UDim2.new(1,-20,0,14), Position=UDim2.new(0,14,0,31), BackgroundTransparency=1,
            Text=opt.desc, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Btn)
        Btn.MouseButton1Click:Connect(function()
            if opt.cmd == "CLOSE" then
                Tween(MainWindow, TI_MED, {Size = UDim2.new(0,0,0,0), Position = UDim2.new(0.5,0,0.5,0)})
                task.wait(0.35)
                pcall(function() ScreenGui:Destroy() end)
            else
                ParseAndExecute(opt.cmd)
            end
        end)
        HoverGlass(Btn, GT.CARD, GT.HOVER)
    end
end

-- ==============================================================================
-- SECCION 24 -- KEYBINDS (F1-F5 estilo Infinite Yield)
-- ==============================================================================

local function SetupKeybinds()
    TrackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        local k = input.KeyCode

        if k == Enum.KeyCode.F1 then
            -- Toggle UI (minimize/restore)
            if MainWindow then
                local currentH = MainWindow.AbsoluteSize.Y
                local targetMinimized = currentH > 60
                Tween(MainWindow, TI_MED, {
                    Size = targetMinimized
                        and UDim2.new(1, 0, 0, 52)
                        or  UDim2.fromScale(1, 1)
                })
            end

        elseif k == Enum.KeyCode.F2 then
            ParseAndExecute(";fly 60")

        elseif k == Enum.KeyCode.F3 then
            ParseAndExecute(";noclip")

        elseif k == Enum.KeyCode.F4 then
            ParseAndExecute(";godmode")

        elseif k == Enum.KeyCode.F5 then
            ParseAndExecute(";esp")

        elseif k == Enum.KeyCode.RightShift then
            ParseAndExecute(";speed 200")
        end
    end))
end

-- ==============================================================================
-- SECCION 25 -- CHAT LISTENER (Estilo Infinite Yield)
-- ==============================================================================

local function SetupChatListener()
    local function OnChat(msg)
        if type(msg) ~= "string" then return end
        local prefix = ENV.QOS_Prefix or ";"
        if msg:sub(1, #prefix) == prefix then
            -- No ejecutar dos veces si ya fue disparado por el keybind/UI
            task.defer(function() ParseAndExecute(msg) end)
        end
    end

    -- TextChatService (Roblox moderno)
    pcall(function()
        local TCS = Services.TextChatService
        if TCS and TCS.MessageReceived then
            TrackConn(TCS.MessageReceived:Connect(function(msg)
                if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
                    OnChat(msg.Text or "")
                end
            end))
        end
    end)

    -- Fallback: LocalPlayer.Chatted
    pcall(function()
        TrackConn(LocalPlayer.Chatted:Connect(OnChat))
    end)
end

-- ==============================================================================
-- SECCION 26 -- FLOW PRINCIPAL
-- ==============================================================================

local function StartMainOS()
    CreateMainWindow()
    SetupKeybinds()
    SetupChatListener()

    -- Cargar tab START por defecto
    task.wait(0.6)
    local startBtn = SidebarButtons["START"]
    if startBtn then
        ClearContent()
        SetActiveTab("START")
        ENV.QOS_ActiveTab = "START"
        if _G["QOS_Tab_START"] then pcall(_G["QOS_Tab_START"]) end
    end

    -- Notificaciones de bienvenida
    local cmdCount3 = 0
    for _ in pairs(Commands) do cmdCount3 = cmdCount3 + 1 end

    task.delay(0.9, function()
        PushNotification(
            "Quantum OS v4.1  [GLASS]",
            "IY Engine activo | " .. cmdCount3 .. " comandos | Prefijo: " .. (ENV.QOS_Prefix or ";"),
            "SYSTEM", 5
        )
        task.wait(1.2)
        ShowToast("Multi-Agent AI", "5 agentes listos | Orquestador conectado", "[AI]", 3)
        task.wait(1.8)
        ShowToast("Keybinds", "F1=UI  F2=Fly  F3=Noclip  F4=God  F5=ESP  RShift=Speed200", ">", 4)
    end)
end

local function Launch()
    CreateBootScreen()
    task.wait(5.5)
    CreateLoginScreen(function()
        ENV.QOS_DeviceMode = IsOnMobile and "mobile" or "pc"
        ENV.QOS_Unlocked   = true
        StartMainOS()
    end)
end

-- ==============================================================================
-- INICIO
-- ==============================================================================

Launch()
