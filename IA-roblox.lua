-- ==============================================================================
-- SECCION 1 -- ENVIRONMENT BOOTSTRAP (compatible con Delta)
-- ==============================================================================

-- Helpers de compatibilidad estilo Infinite Yield
local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

-- Funciones de executor con fallbacks seguros
local cloneref_fn    = missing("function", cloneref, function(...) return ... end)
local everyClipboard = missing("function", setclipboard or toclipboard or set_clipboard)
local httprequest_fn = missing("function", request or http_request or (syn and syn.request))
local queueteleport  = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport))
local sethidden_fn   = missing("function", sethiddenproperty or set_hidden_property)
local gethidden_fn   = missing("function", gethiddenproperty or get_hidden_property)

local ENV = getgenv and getgenv() or _G
if not ENV then ENV = {} end

-- Limpieza de instancias anteriores
if ENV.QOS_Instance    then pcall(function() ENV.QOS_Instance:Destroy()    end) end
if ENV.QOS_OracleFloat then pcall(function() ENV.QOS_OracleFloat:Destroy() end) end
if ENV.QOS_Connections then
    for _, c in pairs(ENV.QOS_Connections) do pcall(function() c:Disconnect() end) end
end

ENV.QOS_Connections   = {}
ENV.QOS_ActiveTab     = nil
ENV.QOS_Unlocked      = false
ENV.QOS_OpenRouterKey = nil
ENV.QOS_DeviceMode    = nil
ENV.QOS_CommandHistory = {}
ENV.QOS_Aliases        = {}
ENV.QOS_Toggles        = {}
ENV.QOS_Prefix         = ";"

-- ==============================================================================
-- SECCION 2 -- SERVICIOS Y REFERENCIAS
-- ==============================================================================

-- Cache de servicios estilo Infinite Yield
local Services = setmetatable({}, {
    __index = function(self, name)
        local ok, svc = pcall(function()
            return cloneref_fn(game:GetService(name))
        end)
        if ok then rawset(self, name, svc); return svc
        else error("Invalid Service: " .. tostring(name)) end
    end
})

local Players          = Services.Players
local TweenService     = Services.TweenService
local RunService       = Services.RunService
local UserInputService = Services.UserInputService
local HttpService      = Services.HttpService
local MarketplaceService = Services.MarketplaceService
local TeleportService  = Services.TeleportService
local SoundService     = Services.SoundService
local Lighting         = Services.Lighting
local StarterGui       = Services.StarterGui

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = cloneref_fn(LocalPlayer:WaitForChild("PlayerGui"))
local IYMouse      = cloneref_fn(LocalPlayer:GetMouse())
local PlaceId      = game.PlaceId
local JobId        = game.JobId

-- Deteccion de mobile al estilo Infinite Yield
local IsOnMobile = false
xpcall(function()
    IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
    IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

local DISPLAY_NAME = LocalPlayer.DisplayName
local USERNAME     = LocalPlayer.Name
local GAME_NAME    = game.Name or "Roblox"

-- Deteccion del nombre del juego con MarketplaceService
pcall(function()
    local info = MarketplaceService:GetProductInfo(PlaceId)
    if info and info.Name then GAME_NAME = info.Name end
end)

-- ==============================================================================
-- SECCION 3 -- PALETA DE COLORES Y TWEEN INFO
-- ==============================================================================

local C = {
    PURPLE_NEON = Color3.fromRGB(160, 32, 240),
    PURPLE_DIM  = Color3.fromRGB( 90, 15, 140),
    PURPLE_GLOW = Color3.fromRGB(200,100, 255),
    CYAN_NEON   = Color3.fromRGB(  0, 220, 255),
    CYAN_DIM    = Color3.fromRGB(  0, 140, 180),
    PINK_NEON   = Color3.fromRGB(255,  60, 160),
    GOLD_NEON   = Color3.fromRGB(255, 195,  50),
    GREEN_NEON  = Color3.fromRGB(  0, 220, 130),

    BG_DEEP     = Color3.fromRGB(  4,   4,  14),
    BG_PANEL    = Color3.fromRGB( 10,  10,  26),
    BG_CARD     = Color3.fromRGB( 16,  16,  40),
    BG_SIDEBAR  = Color3.fromRGB(  6,   6,  18),
    BG_GLASS    = Color3.fromRGB( 22,  18,  48),
    BG_HEADER   = Color3.fromRGB( 12,   8,  30),

    TEXT_WHITE  = Color3.fromRGB(230, 230, 255),
    TEXT_SOFT   = Color3.fromRGB(160, 155, 200),
    TEXT_MUTED  = Color3.fromRGB( 90,  85, 130),
    TEXT_GREEN  = Color3.fromRGB(  0, 220, 130),
    TEXT_RED    = Color3.fromRGB(255,  70,  70),
    TEXT_YELLOW = Color3.fromRGB(255, 210,  60),

    BORDER        = Color3.fromRGB( 60,  45, 110),
    BORDER_BRIGHT = Color3.fromRGB(120,  60, 200),
    TOGGLE_ON     = Color3.fromRGB(  0, 190, 120),
    TOGGLE_OFF    = Color3.fromRGB( 50,  45,  75),
    SLIDER_BG     = Color3.fromRGB( 28,  22,  60),
    SLIDER_FILL   = Color3.fromRGB(160,  32, 240),
    CMDBAR_BG     = Color3.fromRGB(  8,   6,  22),
}

local TI_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_SINE   = TweenInfo.new(1.20, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)
local TI_SPIN   = TweenInfo.new(0.8,  Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)

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

local function MakeFrame(p,par)   return Make("Frame",          p, par) end
local function MakeLabel(p,par)   return Make("TextLabel",      p, par) end
local function MakeButton(p,par)  return Make("TextButton",     p, par) end
local function MakeBox(p,par)     return Make("TextBox",        p, par) end
local function MakeScroll(p,par)  return Make("ScrollingFrame", p, par) end
local function MakeImage(p,par)   return Make("ImageLabel",     p, par) end

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

local function Stroke(thickness, color, parent)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness
    s.Color = color or C.BORDER
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

local function GridLayout(props, parent)
    local g = Instance.new("UIGridLayout")
    for k, v in pairs(props or {}) do pcall(function() g[k] = v end) end
    g.Parent = parent
    return g
end

local function TrackConn(conn)
    table.insert(ENV.QOS_Connections, conn)
    return conn
end

local function Gradient(c0, c1, rot, parent)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent   = parent
    return g
end

local function HoverGlow(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()  Tween(btn, TI_FAST, {BackgroundColor3 = hoverColor}) end)
    btn.MouseLeave:Connect(function()  Tween(btn, TI_FAST, {BackgroundColor3 = normalColor}) end)
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
    speed = speed or 0.035
    label.Text = ""
    task.spawn(function()
        for i = 1, #text do
            if not label or not label.Parent then break end
            label.Text = string.sub(text, 1, i)
            task.wait(speed)
        end
    end)
end

local function AnimateSize(frame, target, info)
    Tween(frame, info or TI_BOUNCE, {Size = target})
end

local function SineFloat(frame, amplitude, period)
    task.spawn(function()
        local t = 0
        while frame and frame.Parent do
            t = t + task.wait(0.016)
            local offset = math.sin(t * (2 * math.pi / period)) * amplitude
            pcall(function()
                frame.Position = UDim2.new(
                    frame.Position.X.Scale, frame.Position.X.Offset,
                    frame.Position.Y.Scale, frame.Position.Y.Offset + offset
                )
            end)
        end
    end)
end

-- Particulas estilo QOS
local function SpawnParticles(parent, count, zIndex)
    count = count or 12
    for i = 1, count do
        local sz = math.random(2, 5)
        local colors = {C.PURPLE_NEON, C.CYAN_NEON, C.PINK_NEON, C.PURPLE_GLOW}
        local px = MakeFrame({
            Size = UDim2.new(0, sz, 0, sz),
            Position = UDim2.new(math.random() * 0.96, 0, math.random() * 0.96, 0),
            BackgroundColor3 = colors[i % #colors + 1],
            BackgroundTransparency = 0.4,
            ZIndex = zIndex or 3,
        }, parent)
        if px then
            Corner(sz, px)
            task.spawn(function()
                while px and px.Parent do
                    local newX = math.random() * 0.96
                    local newY = math.random() * 0.96
                    local newT = 0.1 + math.random() * 0.75
                    Tween(px, TweenInfo.new(3 + math.random() * 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Position = UDim2.new(newX, 0, newY, 0),
                        BackgroundTransparency = newT,
                    })
                    task.wait(3 + math.random() * 4)
                end
            end)
        end
    end
end

-- ==============================================================================
-- SECCION 5 -- RAIZ DEL GUI
-- ==============================================================================

local ScreenGui = Make("ScreenGui", {
    Name = "QuantumOS_v40",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, PlayerGui)
ENV.QOS_Instance = ScreenGui

local BG = MakeFrame({
    Name = "Background",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.BG_DEEP,
    BorderSizePixel = 0,
    ZIndex = 1,
}, ScreenGui)

SpawnParticles(BG, 18, 3)

-- ==============================================================================
-- SECCION 6 -- SISTEMA DE COMANDOS (Logica Infinite Yield)
-- Comandos al estilo IY: prefijo + nombre + argumentos separados por espacio
-- ==============================================================================

local Commands = {}
local CommandAliases = {}

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function GetPlayerFromArg(arg)
    if not arg then return nil end
    arg = arg:lower()
    if arg == "me" then return LocalPlayer end
    if arg == "all" then return Players:GetPlayers() end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(arg, 1, true) or p.DisplayName:lower():find(arg, 1, true) then
            return p
        end
    end
    return nil
end

-- Registro de comandos estilo Infinite Yield
local function AddCommand(names, description, args, func)
    local primary = names[1]
    local cmd = {
        names       = names,
        description = description,
        args        = args or {},
        func        = func,
        primary     = primary,
    }
    Commands[primary] = cmd
    for i = 2, #names do
        CommandAliases[names[i]] = primary
    end
end

-- Notificacion de ayuda (declarada antes de comandos)
local PushNotification -- forward declaration

-- ==============================================================================
-- COMANDOS (inspirados en Infinite Yield)
-- ==============================================================================

-- MOVIMIENTO
AddCommand({"fly", "fl"}, "Activa vuelo libre", {"velocidad (opcional)"}, function(args)
    local speed = tonumber(args[1]) or 50
    local char  = GetCharacter()
    local root  = GetRootPart()
    if not char or not root then PushNotification("Error","No hay personaje","ERROR",3); return end

    if ENV.QOS_FlyActive then
        ENV.QOS_FlyActive = false
        if ENV.QOS_FlyConn then pcall(function() ENV.QOS_FlyConn:Disconnect() end) end
        local hum = GetHumanoid()
        if hum then hum.PlatformStand = false end
        PushNotification("Fly OFF","Vuelo desactivado","INFO",3)
        return
    end

    ENV.QOS_FlyActive = true
    local hum = GetHumanoid()
    if hum then hum.PlatformStand = true end

    local bodyVel  = Instance.new("BodyVelocity",  root)
    local bodyGyro = Instance.new("BodyGyro",       root)
    bodyVel.MaxForce  = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bodyGyro.D = 100

    ENV.QOS_FlyConn = RunService.Heartbeat:Connect(function()
        if not ENV.QOS_FlyActive then
            bodyVel:Destroy(); bodyGyro:Destroy(); return
        end
        local cam = workspace.CurrentCamera
        local dir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        bodyVel.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.new()
        bodyGyro.CFrame = cam.CFrame
    end)
    TrackConn(ENV.QOS_FlyConn)
    PushNotification("Fly ON","Vuelo activado - vel: " .. speed .. " | WASD+Space","SUCCESS",3)
end)

AddCommand({"speed", "sp"}, "Cambia la velocidad de movimiento", {"velocidad"}, function(args)
    local val = tonumber(args[1]) or 16
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = val end
    PushNotification("Speed","WalkSpeed = " .. val,"SUCCESS",3)
end)

AddCommand({"jump", "jp"}, "Cambia la altura de salto", {"altura"}, function(args)
    local val = tonumber(args[1]) or 50
    local hum = GetHumanoid()
    if hum then hum.JumpPower = val end
    PushNotification("Jump","JumpPower = " .. val,"SUCCESS",3)
end)

AddCommand({"noclip", "nc"}, "Activa/desactiva noclip", {}, function()
    ENV.QOS_NoclipActive = not ENV.QOS_NoclipActive
    if ENV.QOS_NoclipActive then
        ENV.QOS_NoclipConn = RunService.Stepped:Connect(function()
            local char = GetCharacter()
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        TrackConn(ENV.QOS_NoclipConn)
        PushNotification("Noclip ON","Colisiones desactivadas","SUCCESS",3)
    else
        if ENV.QOS_NoclipConn then pcall(function() ENV.QOS_NoclipConn:Disconnect() end) end
        PushNotification("Noclip OFF","Colisiones restauradas","INFO",3)
    end
end)

AddCommand({"tp", "teleport"}, "Teleporta a un jugador", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then PushNotification("Error","No uses 'all' para tp","ERROR",3); return end
    if not target then PushNotification("Error","Jugador no encontrado","ERROR",3); return end
    local char    = GetCharacter()
    local tChar   = target.Character
    local root    = GetRootPart()
    local tRoot   = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
    if root and tRoot then
        root.CFrame = tRoot.CFrame + Vector3.new(0, 3, 0)
        PushNotification("Teleport","Teleportado a " .. target.DisplayName,"SUCCESS",3)
    else
        PushNotification("Error","No se pudo teleportar","ERROR",3)
    end
end)

AddCommand({"bringtp", "btp"}, "Trae un jugador hacia ti", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then PushNotification("Error","No uses 'all' con bringtp","ERROR",3); return end
    if not target then PushNotification("Error","Jugador no encontrado","ERROR",3); return end
    local root  = GetRootPart()
    local tChar = target.Character
    local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
    if root and tRoot then
        tRoot.CFrame = root.CFrame + Vector3.new(3, 0, 0)
        PushNotification("BringTP","Traje a " .. target.DisplayName,"SUCCESS",3)
    end
end)

-- VISUAL / JUGADOR
AddCommand({"invisible", "invis", "inv"}, "Activa/desactiva invisibilidad local", {}, function()
    local char = GetCharacter()
    if not char then return end
    ENV.QOS_InvisActive = not ENV.QOS_InvisActive
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = ENV.QOS_InvisActive and 1 or 0
        end
    end
    PushNotification("Invisible", ENV.QOS_InvisActive and "Activado" or "Desactivado",
        ENV.QOS_InvisActive and "SUCCESS" or "INFO", 3)
end)

AddCommand({"esp", "wallhack"}, "Activa/desactiva ESP de jugadores", {"color (opcional)"}, function(args)
    if ENV.QOS_EspActive then
        ENV.QOS_EspActive = false
        -- Remover highlights
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("QOS_ESP_Highlight")
                if h then h:Destroy() end
            end
        end
        PushNotification("ESP OFF","ESP desactivado","INFO",3)
        return
    end
    ENV.QOS_EspActive = true
    local function ApplyEsp(player)
        if player == LocalPlayer then return end
        local function OnChar(char)
            if not ENV.QOS_EspActive then return end
            local existing = char:FindFirstChild("QOS_ESP_Highlight")
            if existing then existing:Destroy() end
            local h = Instance.new("SelectionBox")
            h.Name = "QOS_ESP_Highlight"
            h.Adornee = char
            h.Color3 = C.PURPLE_NEON
            h.LineThickness = 0.05
            h.SurfaceTransparency = 0.8
            h.SurfaceColor3 = Color3.fromRGB(80,0,160)
            h.Parent = char
        end
        if player.Character then OnChar(player.Character) end
        player.CharacterAdded:Connect(function(c) if ENV.QOS_EspActive then OnChar(c) end end)
    end
    for _, p in pairs(Players:GetPlayers()) do ApplyEsp(p) end
    Players.PlayerAdded:Connect(ApplyEsp)
    PushNotification("ESP ON","ESP de jugadores activado","SUCCESS",3)
end)

AddCommand({"godmode", "god"}, "Activa modo dios (requiere permisos del juego)", {}, function()
    local hum = GetHumanoid()
    if hum then
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
        PushNotification("God Mode","MaxHealth = Infinito","SUCCESS",3)
    else
        PushNotification("Error","No se encontro Humanoid","ERROR",3)
    end
end)

AddCommand({"antiaim", "aa"}, "Activa/desactiva anti-aim de cabeza", {}, function()
    ENV.QOS_AntiAim = not ENV.QOS_AntiAim
    local char = GetCharacter()
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            if ENV.QOS_AntiAim then
                local bg = Instance.new("BodyGyro", head)
                bg.Name  = "QOS_AntiAimGyro"
                bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
                bg.D = 50
                task.spawn(function()
                    while ENV.QOS_AntiAim and head and head.Parent do
                        bg.CFrame = CFrame.new(head.Position) * CFrame.Angles(0, tick() * 8, 0)
                        task.wait()
                    end
                    pcall(function() bg:Destroy() end)
                end)
            else
                local bg = head:FindFirstChild("QOS_AntiAimGyro")
                if bg then bg:Destroy() end
            end
        end
    end
    PushNotification("Anti-Aim", ENV.QOS_AntiAim and "Activado" or "Desactivado",
        ENV.QOS_AntiAim and "SUCCESS" or "INFO", 3)
end)

AddCommand({"fov", "setfov"}, "Cambia el FOV de la camara", {"valor"}, function(args)
    local val = tonumber(args[1]) or 70
    local cam = workspace.CurrentCamera
    if cam then
        cam.FieldOfView = math.clamp(val, 1, 120)
        PushNotification("FOV","FieldOfView = " .. cam.FieldOfView,"SUCCESS",3)
    end
end)

AddCommand({"zoom", "maxzoom"}, "Cambia el zoom maximo de camara", {"valor"}, function(args)
    local val = tonumber(args[1]) or 50
    pcall(function()
        local StarterPlayer = Services.StarterPlayer
        StarterPlayer.CameraMaxZoomDistance = val
    end)
    PushNotification("Zoom","Max zoom = " .. val,"SUCCESS",3)
end)

-- UTILIDADES
AddCommand({"rejoin", "rj"}, "Vuelve a unirte a este servidor", {}, function()
    if queueteleport then
        queueteleport(string.format(
            'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")',
            PlaceId, JobId
        ))
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId)
    end
end)

AddCommand({"server", "newserver", "ns"}, "Te une a un servidor nuevo/random", {}, function()
    TeleportService:Teleport(PlaceId)
    PushNotification("Server Hop","Cambiando de servidor...","INFO",3)
end)

AddCommand({"copy", "copyname"}, "Copia el nombre de un jugador", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if not target then PushNotification("Error","Jugador no encontrado","ERROR",3); return end
    if everyClipboard then
        everyClipboard(target.Name)
        PushNotification("Copiado",target.Name .. " copiado al portapapeles","SUCCESS",3)
    end
end)

AddCommand({"players", "listplayers", "lp"}, "Muestra la lista de jugadores", {}, function()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        table.insert(list, (p == LocalPlayer and "[TU] " or "") .. p.DisplayName .. " (@" .. p.Name .. ")")
    end
    PushNotification("Jugadores (" .. #list .. ")", table.concat(list, " | "), "INFO", 6)
end)

AddCommand({"time", "gametime"}, "Muestra la hora del juego", {}, function()
    local t = Lighting.TimeOfDay
    PushNotification("Hora del Juego", tostring(t), "INFO", 3)
end)

AddCommand({"settime"}, "Cambia la hora del juego", {"hora (0-24)"}, function(args)
    local val = tonumber(args[1]) or 12
    Lighting.TimeOfDay = string.format("%02d:00:00", math.clamp(math.floor(val), 0, 23))
    PushNotification("Hora","Hora ajustada a " .. val .. ":00","SUCCESS",3)
end)

AddCommand({"fog", "setfog"}, "Cambia la niebla del ambiente", {"distancia"}, function(args)
    local val = tonumber(args[1]) or 1000
    Lighting.FogEnd   = val
    Lighting.FogStart = 0
    PushNotification("Fog","FogEnd = " .. val,"SUCCESS",3)
end)

AddCommand({"brightness", "br"}, "Cambia el brillo del mapa", {"valor"}, function(args)
    Lighting.Brightness = tonumber(args[1]) or 2
    PushNotification("Brightness","Brillo = " .. Lighting.Brightness,"SUCCESS",3)
end)

AddCommand({"gravity", "grav"}, "Cambia la gravedad", {"valor"}, function(args)
    workspace.Gravity = tonumber(args[1]) or 196.2
    PushNotification("Gravity","Gravedad = " .. workspace.Gravity,"SUCCESS",3)
end)

AddCommand({"chat"}, "Envia un mensaje de chat como tu personaje", {"mensaje..."}, function(args)
    if #args == 0 then return end
    local msg = table.concat(args, " ")
    local ok, err = pcall(function()
        Services.Players.LocalPlayer:Chat(msg)
    end)
    if not ok then
        PushNotification("Chat","No se pudo enviar: " .. tostring(err),"ERROR",3)
    else
        PushNotification("Chat","Enviado: " .. msg,"SUCCESS",3)
    end
end)

AddCommand({"prefix"}, "Cambia el prefijo de comandos", {"prefijo"}, function(args)
    if args[1] and #args[1] == 1 then
        ENV.QOS_Prefix = args[1]
        PushNotification("Prefijo","Prefijo cambiado a: " .. args[1],"SUCCESS",3)
    else
        PushNotification("Prefijo","Prefijo actual: " .. ENV.QOS_Prefix,"INFO",3)
    end
end)

AddCommand({"alias"}, "Crea un alias para un comando", {"alias", "comando"}, function(args)
    if #args < 2 then PushNotification("Alias","Uso: alias <nombre> <comando>","WARNING",3); return end
    ENV.QOS_Aliases[args[1]] = args[2]
    CommandAliases[args[1]] = args[2]
    PushNotification("Alias","Alias '" .. args[1] .. "' -> '" .. args[2] .. "' creado","SUCCESS",3)
end)

AddCommand({"help", "h", "cmds"}, "Muestra la lista de comandos", {"busqueda (opcional)"}, function(args)
    local search = args[1] and args[1]:lower() or nil
    local found = {}
    for name, cmd in pairs(Commands) do
        if not search or name:find(search, 1, true) or cmd.description:lower():find(search, 1, true) then
            table.insert(found, name .. " - " .. cmd.description)
        end
    end
    table.sort(found)
    PushNotification("Comandos (" .. #found .. ")", table.concat(found, " | "), "INFO", 8)
end)

AddCommand({"reset"}, "Resetea tu personaje", {}, function()
    local hum = GetHumanoid()
    if hum then hum.Health = 0 end
end)

AddCommand({"kill"}, "Mata a un jugador (solo local)", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if not target then PushNotification("Error","Jugador no encontrado","ERROR",3); return end
    if type(target) == "table" then
        for _, p in pairs(target) do
            if p.Character then
                local h = p.Character:FindFirstChildOfClass("Humanoid")
                if h then h.Health = 0 end
            end
        end
        PushNotification("Kill","Todos eliminados (local)","SUCCESS",3)
    else
        if target.Character then
            local h = target.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Health = 0 end
        end
        PushNotification("Kill","Eliminado a " .. target.DisplayName .. " (local)","SUCCESS",3)
    end
end)

AddCommand({"size", "charsize"}, "Cambia el tamanio de tu personaje", {"escala"}, function(args)
    local scale = tonumber(args[1]) or 1
    local char  = GetCharacter()
    if not char then return end
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("NumberValue") and obj.Parent:IsA("BodyColors") == false then
            if obj.Name == "HeadScale" or obj.Name == "BodyHeightScale"
                or obj.Name == "BodyWidthScale" or obj.Name == "BodyDepthScale" then
                pcall(function() obj.Value = scale end)
            end
        end
    end
    PushNotification("Tamano","Escala = " .. scale,"SUCCESS",3)
end)

AddCommand({"walkto", "walktp"}, "Camina hacia un jugador", {"jugador"}, function(args)
    local target = GetPlayerFromArg(args[1])
    if type(target) == "table" then return end
    if not target then PushNotification("Error","Jugador no encontrado","ERROR",3); return end
    local char  = GetCharacter()
    local tChar = target and target.Character
    local tRoot = tChar and (tChar:FindFirstChild("HumanoidRootPart") or tChar:FindFirstChild("Torso"))
    local hum   = GetHumanoid()
    if hum and tRoot then
        hum:MoveTo(tRoot.Position)
        PushNotification("WalkTo","Caminando hacia " .. target.DisplayName,"INFO",3)
    end
end)

-- ==============================================================================
-- PARSER DE COMANDOS (estilo IY: prefijo+comando arg1 arg2...)
-- ==============================================================================

local function ParseAndExecute(input)
    if not input or input == "" then return false end
    input = input:gsub("^%s+", ""):gsub("%s+$", "")

    -- Verificar prefijo
    local prefix = ENV.QOS_Prefix or ";"
    if input:sub(1, #prefix) ~= prefix then return false end
    input = input:sub(#prefix + 1)

    -- Dividir en tokens
    local tokens = {}
    for token in input:gmatch("%S+") do
        table.insert(tokens, token)
    end
    if #tokens == 0 then return false end

    local cmdName = tokens[1]:lower()
    table.remove(tokens, 1)

    -- Buscar alias de usuario primero
    if ENV.QOS_Aliases[cmdName] then
        cmdName = ENV.QOS_Aliases[cmdName]
    end
    -- Luego alias registrados
    if CommandAliases[cmdName] then
        cmdName = CommandAliases[cmdName]
    end

    local cmd = Commands[cmdName]
    if cmd then
        -- Agregar al historial
        local hist = ENV.QOS_CommandHistory
        table.insert(hist, 1, (ENV.QOS_Prefix or ";") .. cmdName .. " " .. table.concat(tokens, " "))
        if #hist > 50 then table.remove(hist, #hist) end

        task.spawn(function()
            local ok, err = pcall(cmd.func, tokens)
            if not ok then
                PushNotification("Error de Comando", tostring(err), "ERROR", 4)
            end
        end)
        return true
    end
    PushNotification("Comando no encontrado", "'" .. cmdName .. "' no existe. Usa ;help","WARNING",3)
    return false
end

-- ==============================================================================
-- SECCION 7 -- SISTEMA DE NOTIFICACIONES PREMIUM
-- ==============================================================================

local NotifTypes = {
    INFO    = {icon = "i",  color = C.CYAN_NEON,    bg = Color3.fromRGB(0, 28, 48)},
    SUCCESS = {icon = "v",  color = C.TEXT_GREEN,    bg = Color3.fromRGB(0, 38, 18)},
    WARNING = {icon = "!",  color = C.TEXT_YELLOW,   bg = Color3.fromRGB(48, 32, 0)},
    ERROR   = {icon = "x",  color = C.TEXT_RED,      bg = Color3.fromRGB(58, 0, 0)},
    ORACLE  = {icon = "*",  color = C.PURPLE_GLOW,   bg = Color3.fromRGB(28, 0, 58)},
    SYSTEM  = {icon = "#",  color = C.PURPLE_NEON,   bg = Color3.fromRGB(18, 4, 42)},
    AI      = {icon = "AI", color = C.GOLD_NEON,     bg = Color3.fromRGB(40, 30, 0)},
    CMD     = {icon = ">",  color = C.CYAN_NEON,     bg = Color3.fromRGB(0, 20, 40)},
}

local notifStack = {}
local NOTIF_W = 300
local NOTIF_H = 72
local NOTIF_M = 6

PushNotification = function(title, body, typeName, duration)
    typeName = typeName or "INFO"
    duration = duration or 3.5
    local t = NotifTypes[typeName] or NotifTypes.INFO
    if #notifStack >= 5 then return end

    local slot = #notifStack + 1
    table.insert(notifStack, slot)
    local yOff = -(slot * (NOTIF_H + NOTIF_M))

    local NFrame = MakeFrame({
        Name = "Notif_" .. slot,
        Size = UDim2.new(0, NOTIF_W, 0, NOTIF_H),
        Position = UDim2.new(1, 16, 1, yOff),
        BackgroundColor3 = t.bg,
        ZIndex = 1100 + slot,
    }, ScreenGui)
    if not NFrame then return end
    Corner(14, NFrame)
    Stroke(1, t.color, NFrame)

    -- Barra de acento
    local Acc = MakeFrame({
        Size = UDim2.new(0, 4, 1, -16),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = t.color,
        ZIndex = 1101 + slot,
    }, NFrame)
    if Acc then Corner(2, Acc) end

    -- Icono badge
    local IconBg = MakeFrame({
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(0, 12, 0.5, -14),
        BackgroundColor3 = t.color,
        BackgroundTransparency = 0.7,
        ZIndex = 1102 + slot,
    }, NFrame)
    if IconBg then
        Corner(8, IconBg)
        MakeLabel({
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = t.icon,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = t.color,
            ZIndex = 1103 + slot,
        }, IconBg)
    end

    -- Titulo
    MakeLabel({
        Size = UDim2.new(1, -56, 0, 22),
        Position = UDim2.new(0, 50, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 1102 + slot,
    }, NFrame)

    -- Cuerpo
    MakeLabel({
        Size = UDim2.new(1, -56, 0, 30),
        Position = UDim2.new(0, 50, 0, 32),
        BackgroundTransparency = 1,
        Text = body,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_SOFT,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1102 + slot,
    }, NFrame)

    -- Progress bar
    local PBG = MakeFrame({
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = C.SLIDER_BG,
        ZIndex = 1103 + slot,
    }, NFrame)
    local PF = MakeFrame({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = t.color,
        ZIndex = 1104 + slot,
    }, PBG)
    Corner(2, PF)

    -- Boton cerrar
    local ClN = MakeButton({
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 4),
        BackgroundTransparency = 1,
        Text = "x",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 1105 + slot,
    }, NFrame)

    -- Animar entrada
    Tween(NFrame, TI_BOUNCE, {Position = UDim2.new(1, -(NOTIF_W + 10), 1, yOff)})
    Tween(PF, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})

    local dismissed = false
    local function Dismiss()
        if dismissed then return end
        dismissed = true
        Tween(NFrame, TI_MED, {Position = UDim2.new(1, 16, 1, yOff)})
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
local toastQueue = {}
local toastActive = false
local function ShowToast(title, body, icon, dur)
    dur = dur or 2.5
    icon = icon or ">"
    table.insert(toastQueue, {title = title, body = body, icon = icon, dur = dur})
    if toastActive then return end
    toastActive = true
    task.spawn(function()
        while #toastQueue > 0 do
            local t = table.remove(toastQueue, 1)
            local T = MakeFrame({
                Size = UDim2.new(0, 280, 0, 62),
                Position = UDim2.new(0.5, -140, 1, 10),
                BackgroundColor3 = C.BG_CARD,
                ZIndex = 1000,
            }, ScreenGui)
            if T then
                Corner(14, T)
                Stroke(2, C.PURPLE_NEON, T)
                MakeLabel({
                    Size = UDim2.new(0, 34, 1, 0),
                    BackgroundTransparency = 1,
                    Text = t.icon,
                    Font = Enum.Font.GothamBold,
                    TextSize = 18,
                    TextColor3 = C.PURPLE_GLOW,
                    ZIndex = 1001,
                }, T)
                MakeLabel({
                    Size = UDim2.new(1, -50, 0, 20),
                    Position = UDim2.new(0, 40, 0, 8),
                    BackgroundTransparency = 1,
                    Text = t.title,
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
                    Text = t.body,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = C.TEXT_SOFT,
                    TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 1001,
                }, T)
                Tween(T, TI_MED, {Position = UDim2.new(0.5, -140, 1, -75)})
                task.wait(t.dur)
                Tween(T, TI_MED, {Position = UDim2.new(0.5, -140, 1, 10)})
                task.wait(0.4)
                T:Destroy()
            end
            task.wait(0.2)
        end
        toastActive = false
    end)
end

-- ==============================================================================
-- SECCION 8 -- MULTI-AGENT AI SYSTEM (OpenRouter)
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
    GAME_ANALYST   = {icon = "[G]", name = "Game Analyst",   color = Color3.fromRGB(255, 140,   0)},
    CODE_EXPERT    = {icon = "[C]", name = "Code Expert",    color = Color3.fromRGB(  0, 220, 180)},
    STRATEGY_AGENT = {icon = "[S]", name = "Strategy Agent", color = Color3.fromRGB(220,  50,  50)},
    CREATIVE_AGENT = {icon = "[A]", name = "Creative Agent", color = Color3.fromRGB(200, 100, 255)},
    FAST_AGENT     = {icon = "[F]", name = "Fast Agent",     color = Color3.fromRGB(255, 220,  60)},
}
AI.SYSTEM_PROMPTS = {
    ORCHESTRATOR   = "Eres el Orquestador de Quantum OS para Roblox. Analiza el mensaje y responde SOLO con JSON:\n{\"agent\":\"GAME_ANALYST|CODE_EXPERT|STRATEGY_AGENT|CREATIVE_AGENT|FAST_AGENT\",\"reason\":\"motivo\"}\nReglas: GAME_ANALYST=mecanicas/items/juego, CODE_EXPERT=scripts/Lua/errores, STRATEGY_AGENT=estrategias/builds, CREATIVE_AGENT=ideas/rol, FAST_AGENT=saludos/preguntas simples. Juego: " .. GAME_NAME,
    GAME_ANALYST   = "Eres un experto analista de '" .. GAME_NAME .. "' en Roblox. Responde en espanol, max 130 palabras.",
    CODE_EXPERT    = "Eres un experto en Lua y Delta Executor para Roblox. Ayuda con scripts, errores y optimizacion. Responde en espanol con codigo bien comentado, max 160 palabras.",
    STRATEGY_AGENT = "Eres un estratega experto en '" .. GAME_NAME .. "'. Responde en espanol conciso, max 130 palabras.",
    CREATIVE_AGENT = "Eres un asistente creativo para Roblox. Responde en espanol con entusiasmo, max 110 palabras.",
    FAST_AGENT     = "Eres el asistente rapido de Quantum OS para Roblox '" .. GAME_NAME .. "'. Responde breve y amigable en espanol, max 70 palabras.",
}

local function OR_Call(model, sysPrompt, userMsg, maxTok)
    maxTok = maxTok or 300
    local key = ENV.QOS_OpenRouterKey
    if not key or key == "" then return nil, "Sin API Key" end
    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({
            model = model,
            max_tokens = maxTok,
            messages = {
                {role = "system", content = sysPrompt},
                {role = "user",   content = userMsg},
            },
        })
        local resp = HttpService:RequestAsync({
            Url    = "https://openrouter.ai/api/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. key,
                ["Content-Type"]  = "application/json",
                ["HTTP-Referer"]  = "https://lxndxn-quantumos.rblx",
                ["X-Title"]       = "LXNDXN Quantum OS v4.0",
            },
            Body = body,
        })
        if resp.StatusCode ~= 200 then return nil, "HTTP " .. resp.StatusCode end
        local data = HttpService:JSONDecode(resp.Body)
        return data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content
    end)
    if ok then return result, nil else return nil, tostring(result) end
end

local function VerifyAPIKey(key, callback)
    task.spawn(function()
        local old = ENV.QOS_OpenRouterKey
        ENV.QOS_OpenRouterKey = key
        local resp, err = OR_Call(
            AI.AGENTS.FAST_AGENT,
            "Eres un verificador. Responde SOLO la palabra: OK",
            "Verificacion de conexion. Responde: OK", 12
        )
        if resp and #resp > 0 then
            callback(true, resp)
        else
            ENV.QOS_OpenRouterKey = old
            callback(false, err or "Sin respuesta")
        end
    end)
end

local function OracleQuery(userMsg, onThink, onAgent, onResponse, onError)
    task.spawn(function()
        if onThink then onThink("Orquestador analizando consulta...") end
        local orchResp, _ = OR_Call(AI.ORCHESTRATOR, AI.SYSTEM_PROMPTS.ORCHESTRATOR, userMsg, 80)
        local agentKey = "FAST_AGENT"
        if orchResp then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(orchResp) end)
            if ok and decoded and decoded.agent and AI.AGENTS[decoded.agent] then
                agentKey = decoded.agent
            end
        end
        local meta = AI.AGENT_META[agentKey] or AI.AGENT_META.FAST_AGENT
        if onAgent then onAgent(agentKey, meta) end
        if onThink then onThink(meta.name .. " procesando...") end
        local resp, err = OR_Call(
            AI.AGENTS[agentKey] or AI.AGENTS.FAST_AGENT,
            AI.SYSTEM_PROMPTS[agentKey] or AI.SYSTEM_PROMPTS.FAST_AGENT,
            userMsg, 350
        )
        if resp then
            if onResponse then onResponse(resp, meta) end
        else
            if onError then onError(err or "Error desconocido") end
        end
    end)
end

-- ==============================================================================
-- SECCION 9 -- BOOT SCREEN ANIMADO
-- ==============================================================================

local function CreateBootScreen()
    local Boot = MakeFrame({
        Name = "BootScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.BG_DEEP,
        ZIndex = 100,
    }, ScreenGui)
    Gradient(C.BG_DEEP, Color3.fromRGB(8, 4, 22), 135, Boot)

    local Center = MakeFrame({
        Size = UDim2.new(0, 360, 0, 430),
        Position = UDim2.new(0.5, -180, 0.5, -215),
        BackgroundColor3 = C.BG_GLASS,
        BackgroundTransparency = 0.25,
        ZIndex = 101,
    }, Boot)
    Corner(28, Center)
    local cs = Stroke(2, C.PURPLE_NEON, Center)
    PulseStroke(cs, C.PURPLE_DIM, C.PURPLE_GLOW)

    SpawnParticles(Center, 8, 102)

    -- Logo central
    local LogoFrame = MakeFrame({
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0.5, -40, 0, 22),
        BackgroundColor3 = C.PURPLE_DIM,
        BackgroundTransparency = 0.25,
        ZIndex = 102,
    }, Center)
    Corner(40, LogoFrame)
    Stroke(3, C.PURPLE_NEON, LogoFrame)
    Gradient(Color3.fromRGB(60,10,110), C.PURPLE_DIM, 135, LogoFrame)

    local LogoLabel = MakeLabel({
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "Q",
        Font = Enum.Font.GothamBold,
        TextSize = 48,
        TextColor3 = C.PURPLE_NEON,
        ZIndex = 103,
    }, LogoFrame)
    task.spawn(function()
        while LogoLabel and LogoLabel.Parent do
            Tween(LogoLabel, TI_SINE, {TextColor3 = C.CYAN_NEON}); task.wait(1.2)
            Tween(LogoLabel, TI_SINE, {TextColor3 = C.PURPLE_NEON}); task.wait(1.2)
        end
    end)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 114),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS  v4.0",
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 102,
    }, Center)

    -- Badge
    local Badge = MakeLabel({
        Size = UDim2.new(0, 240, 0, 24),
        Position = UDim2.new(0.5, -120, 0, 150),
        BackgroundColor3 = C.PURPLE_DIM,
        BackgroundTransparency = 0.2,
        Text = "DELTA EDITION  |  MULTI-AGENT AI",
        Font = Enum.Font.GothamSemibold,
        TextSize = 11,
        TextColor3 = C.CYAN_NEON,
        ZIndex = 102,
    }, Center)
    Corner(12, Badge)

    local WelcomeLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 0, 188),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        TextWrapped = true,
        ZIndex = 102,
    }, Center)

    local SubLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 44),
        Position = UDim2.new(0, 20, 0, 244),
        BackgroundTransparency = 1,
        Text = "",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_SOFT,
        TextWrapped = true,
        ZIndex = 102,
    }, Center)

    -- Barra de progreso
    local ProgressBG = MakeFrame({
        Size = UDim2.new(1, -40, 0, 6),
        Position = UDim2.new(0, 20, 0, 318),
        BackgroundColor3 = C.SLIDER_BG,
        ZIndex = 102,
    }, Center)
    Corner(3, ProgressBG)
    local ProgressFill = MakeFrame({Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.PURPLE_NEON, ZIndex = 103}, ProgressBG)
    Corner(3, ProgressFill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, ProgressFill)

    local ProgressLabel = MakeLabel({
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, 5),
        BackgroundTransparency = 1,
        Text = "Inicializando sistema...",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 102,
    }, ProgressBG)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, -22),
        BackgroundTransparency = 1,
        Text = "LXNDXN  |  Delta Edition  |  Infinite Yield Engine  |  v4.0",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 102,
    }, Center)

    -- Animacion de boot
    task.spawn(function()
        task.wait(0.5)
        Typewriter(WelcomeLabel, "Hola, " .. DISPLAY_NAME .. ". Iniciando Quantum OS v4.0...", 0.04)
        task.wait(1.8)
        Typewriter(SubLabel, "Sistema Multi-Agente AI iniciando...\nInfinite Yield Engine | 5 Agentes listos.", 0.03)
        task.wait(1.4)
        local steps = {
            {0.12, "Cargando kernel del OS..."},
            {0.28, "Verificando Delta Executor..."},
            {0.44, "Cargando comandos Infinite Yield..."},
            {0.60, "Conectando Orquestador AI..."},
            {0.76, "Activando agentes especializados..."},
            {0.90, "Estableciendo sesion segura..."},
            {1.00, "Listo. Se requiere autenticacion."},
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
-- SECCION 10 -- LOGIN SCREEN PREMIUM
-- ==============================================================================

local function CreateLoginScreen(onSuccess)
    local Login = MakeFrame({
        Name = "LoginScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.BG_DEEP,
        ZIndex = 90,
    }, ScreenGui)
    Gradient(Color3.fromRGB(4, 2, 14), Color3.fromRGB(14, 6, 38), 135, Login)

    -- Scan lines animadas
    local function SpawnScanLine()
        task.spawn(function()
            while Login and Login.Parent do
                local line = MakeFrame({
                    Size = UDim2.new(1, 0, 0, 1),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = C.PURPLE_NEON,
                    BackgroundTransparency = 0.88,
                    ZIndex = 91,
                }, Login)
                Tween(line, TweenInfo.new(3 + math.random() * 2, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(0, 0, 1, 0)
                })
                task.wait(3 + math.random() * 3)
                pcall(function() line:Destroy() end)
            end
        end)
    end
    for i = 1, 4 do task.delay(i * 0.8, SpawnScanLine) end

    SpawnParticles(Login, 20, 91)

    -- Panel principal adaptado a movil
    local Panel = MakeFrame({
        Name = "LoginPanel",
        Size = UDim2.new(0.92, 0, 0, 620),
        Position = UDim2.new(0.04, 0, 0.5, -310),
        BackgroundColor3 = Color3.fromRGB(12, 10, 32),
        BackgroundTransparency = 0.1,
        ZIndex = 92,
    }, Login)
    Corner(28, Panel)
    local panelS = Stroke(2, C.BORDER_BRIGHT, Panel)
    PulseStroke(panelS, C.PURPLE_DIM, C.PURPLE_GLOW)

    SpawnParticles(Panel, 8, 93)

    -- Logo en panel
    local LogoF = MakeFrame({
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0.5, -40, 0, 22),
        BackgroundColor3 = C.PURPLE_DIM,
        BackgroundTransparency = 0.25,
        ZIndex = 94,
    }, Panel)
    Corner(40, LogoF)
    Stroke(3, C.PURPLE_NEON, LogoF)
    Gradient(Color3.fromRGB(60,10,110), C.PURPLE_DIM, 135, LogoF)
    local LIcon = MakeLabel({
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "Q",
        Font = Enum.Font.GothamBold,
        TextSize = 46,
        TextColor3 = C.PURPLE_NEON,
        ZIndex = 95,
    }, LogoF)
    task.spawn(function()
        while LIcon and LIcon.Parent do
            Tween(LIcon, TI_SINE, {TextColor3 = C.CYAN_NEON}); task.wait(1.2)
            Tween(LIcon, TI_SINE, {TextColor3 = C.PURPLE_NEON}); task.wait(1.2)
        end
    end)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 34),
        Position = UDim2.new(0, 0, 0, 114),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS",
        Font = Enum.Font.GothamBold,
        TextSize = 28,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 94,
    }, Panel)

    MakeLabel({
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 150),
        BackgroundTransparency = 1,
        Text = "Multi-Agent AI  |  Delta Edition  |  v4.0",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = C.CYAN_NEON,
        ZIndex = 94,
    }, Panel)

    -- Badges de agentes
    local BadgeRow = MakeFrame({
        Size = UDim2.new(1, -40, 0, 26),
        Position = UDim2.new(0, 20, 0, 178),
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
            BackgroundColor3 = Color3.fromRGB(20, 8, 50),
            Text = ab[1] .. " " .. ab[2],
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = C.TEXT_SOFT,
            ZIndex = 95,
        }, BadgeRow)
        Corner(10, B)
        Stroke(1, C.PURPLE_DIM, B)
        Padding(0, 7, 0, 7, B)
    end

    -- Separador
    MakeFrame({
        Size = UDim2.new(0.8, 0, 0, 1),
        Position = UDim2.new(0.1, 0, 0, 218),
        BackgroundColor3 = C.BORDER,
        ZIndex = 94,
    }, Panel)

    -- Label API Key
    MakeLabel({
        Size = UDim2.new(1, -40, 0, 18),
        Position = UDim2.new(0, 20, 0, 228),
        BackgroundTransparency = 1,
        Text = "OPENROUTER API KEY",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 94,
    }, Panel)

    -- TextBox API Key
    local KeyBox = MakeBox({
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 0, 250),
        BackgroundColor3 = Color3.fromRGB(10, 8, 28),
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxx",
        Font = Enum.Font.Code,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ClearTextOnFocus = false,
        ZIndex = 95,
    }, Panel)
    Corner(12, KeyBox)
    local kbs = Stroke(2, C.BORDER, KeyBox)
    Padding(0, 14, 0, 14, KeyBox)
    KeyBox.Focused:Connect(function()   Tween(kbs, TI_FAST, {Color = C.PURPLE_NEON}) end)
    KeyBox.FocusLost:Connect(function() Tween(kbs, TI_FAST, {Color = C.BORDER}) end)

    -- Status label
    local StatusLabel = MakeLabel({
        Size = UDim2.new(1, -40, 0, 22),
        Position = UDim2.new(0, 20, 0, 308),
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
        Position = UDim2.new(0.5, -15, 0, 320),
        BackgroundTransparency = 1,
        Text = "o",
        Font = Enum.Font.GothamBold,
        TextSize = 24,
        TextColor3 = C.CYAN_NEON,
        Visible = false,
        ZIndex = 96,
    }, Panel)

    -- Boton VERIFICAR
    local LoginBtn = MakeButton({
        Size = UDim2.new(1, -40, 0, 50),
        Position = UDim2.new(0, 20, 0, 338),
        BackgroundColor3 = C.PURPLE_NEON,
        BorderSizePixel = 0,
        Text = ">> VERIFICAR API KEY <<",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 95,
    }, Panel)
    Corner(14, LoginBtn)
    Gradient(Color3.fromRGB(130, 20, 210), Color3.fromRGB(70, 0, 170), 135, LoginBtn)
    LoginBtn.MouseEnter:Connect(function()
        Tween(LoginBtn, TI_FAST, {Size = UDim2.new(1, -30, 0, 50), Position = UDim2.new(0, 15, 0, 338)})
    end)
    LoginBtn.MouseLeave:Connect(function()
        Tween(LoginBtn, TI_FAST, {Size = UDim2.new(1, -40, 0, 50), Position = UDim2.new(0, 20, 0, 338)})
    end)

    -- Separador 2
    MakeFrame({
        Size = UDim2.new(0.7, 0, 0, 1),
        Position = UDim2.new(0.15, 0, 0, 402),
        BackgroundColor3 = C.BORDER,
        ZIndex = 94,
    }, Panel)

    -- Boton Obtener API Key
    local GetKeyBtn = MakeButton({
        Size = UDim2.new(1, -40, 0, 44),
        Position = UDim2.new(0, 20, 0, 410),
        BackgroundColor3 = Color3.fromRGB(12, 10, 32),
        BorderSizePixel = 0,
        Text = "[KEY] Obtener API Key -> openrouter.ai/keys",
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextColor3 = C.CYAN_NEON,
        ZIndex = 95,
    }, Panel)
    Corner(12, GetKeyBtn)
    Stroke(1, C.CYAN_DIM, GetKeyBtn)
    HoverGlow(GetKeyBtn, Color3.fromRGB(12,10,32), Color3.fromRGB(0,28,48))
    GetKeyBtn.MouseButton1Click:Connect(function()
        if everyClipboard then
            pcall(function() everyClipboard("https://openrouter.ai/keys") end)
        end
        StatusLabel.Text = "Link copiado: openrouter.ai/keys"
        StatusLabel.TextColor3 = C.CYAN_NEON
    end)

    -- Hint seguridad
    MakeLabel({
        Size = UDim2.new(1, -40, 0, 16),
        Position = UDim2.new(0, 20, 0, 462),
        BackgroundTransparency = 1,
        Text = "[i] Tu key solo se usa en llamadas de IA - No se almacena",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 94,
    }, Panel)

    -- Footer
    MakeLabel({
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 596),
        BackgroundTransparency = 1,
        Text = "LXNDXN Quantum OS  |  Delta Edition  |  v4.0  |  Infinite Yield Engine",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 94,
    }, Panel)

    -- Logica de verificacion
    local function DoVerify()
        local key = KeyBox.Text:gsub("%s+", "")
        if key == "" then
            StatusLabel.Text = "[!] Introduce tu API Key de OpenRouter."
            StatusLabel.TextColor3 = C.TEXT_YELLOW
            Tween(KeyBox, TI_FAST, {BackgroundColor3 = Color3.fromRGB(30, 14, 8)})
            task.wait(0.7)
            Tween(KeyBox, TI_FAST, {BackgroundColor3 = Color3.fromRGB(10, 8, 28)})
            return
        end
        LoginBtn.Visible = false
        Spinner.Visible = true
        StatusLabel.Text = "Verificando con OpenRouter AI..."
        StatusLabel.TextColor3 = C.CYAN_NEON
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
            Spinner.Visible = false
            LoginBtn.Visible = true
            if success then
                ENV.QOS_OpenRouterKey = key
                StatusLabel.Text = "[v] API Key verificada | Conexion establecida"
                StatusLabel.TextColor3 = C.TEXT_GREEN
                Tween(LoginBtn, TI_FAST, {BackgroundColor3 = C.TOGGLE_ON})
                LoginBtn.Text = "[v]  CONECTADO"
                task.wait(1.0)
                Tween(Login, TI_MED, {BackgroundTransparency = 1})
                task.wait(0.4)
                pcall(function() Login:Destroy() end)
                onSuccess()
            else
                StatusLabel.Text = "[x] API Key invalida. Verifica en openrouter.ai/keys"
                StatusLabel.TextColor3 = C.TEXT_RED
                -- Shake animation
                for _ = 1, 6 do
                    local ox = Panel.Position.X.Scale
                    local oy = Panel.Position.Y.Scale
                    Tween(Panel, TI_FAST, {Position = UDim2.new(ox + 0.006, 0, oy, 0)}); task.wait(0.05)
                    Tween(Panel, TI_FAST, {Position = UDim2.new(ox - 0.006, 0, oy, 0)}); task.wait(0.05)
                end
                Tween(Panel, TI_FAST, {Position = UDim2.new(0.04, 0, 0.5, -310)})
            end
        end)
    end
    LoginBtn.MouseButton1Click:Connect(DoVerify)
    KeyBox.FocusLost:Connect(function(enter) if enter then DoVerify() end end)
    return Login
end

-- ==============================================================================
-- SECCION 11 -- VENTANA PRINCIPAL
-- ==============================================================================

local MainWindow  = nil
local Sidebar     = nil
local ContentArea = nil
local CurrentTabFrame = nil
local SidebarButtons  = {}

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
            BackgroundColor3    = active and C.PURPLE_DIM or Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = active and 0 or 1,
        })
        local ind = btn:FindFirstChild("Indicator")
        if ind then ind.Visible = active end
    end
end

local function SectionHeader(parent, title, subtitle)
    local H = MakeFrame({
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = C.BG_HEADER,
        ZIndex = 19,
    }, parent)
    Stroke(1, C.BORDER, H)
    local AL = MakeFrame({
        Size = UDim2.new(0, 3, 0, 36),
        Position = UDim2.new(0, 10, 0, 12),
        BackgroundColor3 = C.PURPLE_NEON,
        ZIndex = 20,
    }, H)
    Corner(2, AL)
    MakeLabel({
        Size = UDim2.new(1, -26, 0, 26),
        Position = UDim2.new(0, 22, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
    }, H)
    if subtitle then
        MakeLabel({
            Size = UDim2.new(1, -26, 0, 15),
            Position = UDim2.new(0, 22, 0, 36),
            BackgroundTransparency = 1,
            Text = subtitle,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = C.TEXT_MUTED,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 20,
        }, H)
    end
    return H
end

local function CreateToggleWidget(parent, label, defaultState, onChange)
    local Row = MakeFrame({
        Size = UDim2.new(1, 0, 0, 42),
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
        Position = defaultState and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 22,
    }, Track)
    Corner(9, Thumb)
    local state = defaultState
    local TB = MakeButton({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", ZIndex = 23}, Track)
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
    local Row = MakeFrame({Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.BG_CARD, ZIndex = 20}, parent)
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
    local VL = MakeLabel({
        Size = UDim2.new(0, 55, 0, 22),
        Position = UDim2.new(1, -65, 0, 6),
        BackgroundTransparency = 1,
        Text = tostring(defV) .. (suffix or ""),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.PURPLE_GLOW,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 21,
    }, Row)
    local TRK = MakeFrame({
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 0, 40),
        BackgroundColor3 = C.SLIDER_BG,
        ZIndex = 21,
    }, Row)
    Corner(3, TRK)
    local ratio = (defV - minV) / (maxV - minV)
    local Fill = MakeFrame({Size = UDim2.new(ratio, 0, 1, 0), BackgroundColor3 = C.SLIDER_FILL, ZIndex = 22}, TRK)
    Corner(3, Fill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, Fill)
    local Knob = MakeFrame({
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(ratio, -8, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 23,
    }, TRK)
    Corner(8, Knob)
    Stroke(2, C.PURPLE_NEON, Knob)
    local dragging = false
    local function UpdSlider(inputX)
        local t = math.clamp((inputX - TRK.AbsolutePosition.X) / TRK.AbsoluteSize.X, 0, 1)
        local value = math.floor(minV + t * (maxV - minV))
        Tween(Fill, TI_FAST, {Size = UDim2.new(t, 0, 1, 0)})
        Tween(Knob, TI_FAST, {Position = UDim2.new(t, -8, 0.5, -8)})
        VL.Text = tostring(value) .. (suffix or "")
        if onChange then onChange(value) end
    end
    TRK.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; UpdSlider(i.Position.X)
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            UpdSlider(i.Position.X)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
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
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 10,
    }, ScreenGui)

    -- HEADER
    local Header = MakeFrame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundColor3 = C.BG_HEADER,
        ZIndex = 12,
    }, MainWindow)
    Stroke(1, C.BORDER, Header)
    Gradient(C.BG_HEADER, Color3.fromRGB(8, 6, 20), 90, Header)

    local HLogo = MakeLabel({
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(0, 12, 0.5, -18),
        BackgroundTransparency = 1,
        Text = "Q",
        Font = Enum.Font.GothamBold,
        TextSize = 28,
        TextColor3 = C.PURPLE_NEON,
        ZIndex = 13,
    }, Header)
    task.spawn(function()
        while HLogo and HLogo.Parent do
            Tween(HLogo, TI_SINE, {TextColor3 = C.CYAN_NEON}); task.wait(1.5)
            Tween(HLogo, TI_SINE, {TextColor3 = C.PURPLE_NEON}); task.wait(1.5)
        end
    end)

    MakeLabel({
        Size = UDim2.new(0, 180, 0, 20),
        Position = UDim2.new(0, 52, 0, 8),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS  v4.0",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, Header)
    MakeLabel({
        Size = UDim2.new(0, 180, 0, 14),
        Position = UDim2.new(0, 52, 0, 30),
        BackgroundTransparency = 1,
        Text = "IY Engine  |  Delta Executor",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, Header)

    local GameBadge = MakeLabel({
        Size = UDim2.new(0, 200, 0, 28),
        Position = UDim2.new(0.5, -100, 0.5, -14),
        BackgroundColor3 = C.BG_CARD,
        Text = "[G]  " .. GAME_NAME:sub(1, 18),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_SOFT,
        ZIndex = 13,
    }, Header)
    Corner(14, GameBadge)
    Stroke(1, C.BORDER, GameBadge)

    -- Botones sistema
    local SysF = MakeFrame({
        Size = UDim2.new(0, 140, 0, 38),
        Position = UDim2.new(1, -150, 0.5, -19),
        BackgroundTransparency = 1,
        ZIndex = 13,
    }, Header)
    local function SysBtn(label, color, xOff)
        local b = MakeButton({
            Size = UDim2.new(0, 32, 0, 32),
            Position = UDim2.new(0, xOff, 0.5, -16),
            BackgroundColor3 = Color3.fromRGB(18, 15, 38),
            Text = label,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = color,
            ZIndex = 14,
        }, SysF)
        Corner(10, b)
        HoverGlow(b, Color3.fromRGB(18, 15, 38), Color3.fromRGB(38, 28, 68))
        return b
    end
    SysBtn("W", C.TEXT_GREEN, 0)  -- WiFi/Status
    SysBtn("N", C.TEXT_YELLOW, 36) -- Notif
    local MinBtn   = SysBtn("-", C.TEXT_SOFT, 72)
    local CloseBtn = SysBtn("X", C.TEXT_RED,  108)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow, TI_MED, {Size = UDim2.new(0, 0, 0, 0)})
        task.wait(0.35)
        pcall(function() ScreenGui:Destroy() end)
    end)
    local minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Tween(MainWindow, TI_MED, {Size = UDim2.new(1, 0, 0, 54)})
        else
            Tween(MainWindow, TI_MED, {Size = UDim2.fromScale(1, 1)})
        end
    end)

    -- SIDEBAR
    Sidebar = MakeFrame({
        Name = "Sidebar",
        Size = UDim2.new(0, 204, 1, -54),
        Position = UDim2.new(0, 0, 0, 54),
        BackgroundColor3 = C.BG_SIDEBAR,
        ZIndex = 11,
    }, MainWindow)
    Stroke(1, C.BORDER, Sidebar)

    -- Perfil de usuario
    local SbP = MakeFrame({
        Size = UDim2.new(1, -16, 0, 70),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = C.BG_CARD,
        ZIndex = 12,
    }, Sidebar)
    Corner(14, SbP)
    Stroke(1, C.PURPLE_DIM, SbP)
    Gradient(C.BG_CARD, Color3.fromRGB(20, 10, 50), 135, SbP)

    local Av = MakeLabel({
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 10, 0.5, -22),
        BackgroundColor3 = C.PURPLE_DIM,
        Text = string.upper(string.sub(DISPLAY_NAME, 1, 2)),
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 13,
    }, SbP)
    Corner(22, Av)
    Stroke(2, C.PURPLE_NEON, Av)

    MakeLabel({
        Size = UDim2.new(1, -64, 0, 18),
        Position = UDim2.new(0, 62, 0, 10),
        BackgroundTransparency = 1,
        Text = DISPLAY_NAME,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
    }, SbP)
    MakeLabel({
        Size = UDim2.new(1, -64, 0, 14),
        Position = UDim2.new(0, 62, 0, 30),
        BackgroundTransparency = 1,
        Text = "@" .. USERNAME,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 13,
    }, SbP)
    local OnB = MakeLabel({
        Size = UDim2.new(0, 70, 0, 14),
        Position = UDim2.new(0, 62, 0, 48),
        BackgroundColor3 = Color3.fromRGB(0, 50, 25),
        Text = "* AI Online",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_GREEN,
        ZIndex = 13,
    }, SbP)
    Corner(7, OnB)

    -- Tabs del Sidebar
    local SbScroll = MakeScroll({
        Size = UDim2.new(1, 0, 1, -90),
        Position = UDim2.new(0, 0, 0, 88),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ZIndex = 12,
    }, Sidebar)
    local SbList = MakeFrame({
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 12,
    }, SbScroll)
    ListLayout({Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, SbList)

    local TABS = {
        {name = "START",            icon = "#",  label = "Inicio",         order = 1},
        {name = "CMD_BAR",          icon = ">",  label = "Comandos IY",    order = 2},
        {name = "SCRIPT_HUB",       icon = "!",  label = "Script Hub",     order = 3},
        {name = "QUANTUM_ORACLE",   icon = "*",  label = "Oracle AI",      order = 4},
        {name = "PLAYER_MODS",      icon = "P",  label = "Player Mods",    order = 5},
        {name = "WORLD_MODS",       icon = "W",  label = "World Mods",     order = 6},
        {name = "ESP_VISUALS",      icon = "E",  label = "ESP & Visuals",  order = 7},
        {name = "TELEPORT",         icon = "T",  label = "Teleport",       order = 8},
        {name = "GAME_BOOSTER",     icon = "B",  label = "Game Booster",   order = 9},
        {name = "SYSTEM_SETTINGS",  icon = "S",  label = "Ajustes",        order = 10},
        {name = "POWER",            icon = "O",  label = "Power",          order = 11},
    }

    for _, tab in ipairs(TABS) do
        local Btn = MakeButton({
            Name = tab.name,
            Size = UDim2.new(1, -12, 0, 40),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            LayoutOrder = tab.order,
            ZIndex = 13,
        }, SbList)
        Corner(10, Btn)
        Padding(0, 8, 0, 8, Btn)

        local Ind = MakeFrame({
            Name = "Indicator",
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = C.PURPLE_NEON,
            Visible = false,
            ZIndex = 14,
        }, Btn)
        Corner(2, Ind)

        MakeLabel({
            Size = UDim2.new(0, 24, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.icon,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = C.TEXT_MUTED,
            ZIndex = 14,
        }, Btn)
        MakeLabel({
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.new(0, 38, 0, 0),
            BackgroundTransparency = 1,
            Text = tab.label,
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
            ENV.QOS_ActiveTab = tab.name
            local fnKey = "QOS_Tab_" .. tab.name
            if _G[fnKey] then pcall(_G[fnKey]) end
        end)
        HoverGlow(Btn, Color3.fromRGB(0,0,0), C.BG_GLASS)
    end

    local SbLL = SbList:FindFirstChildWhichIsA("UIListLayout")
    if SbLL then
        SbLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            SbList.Size = UDim2.new(1, 0, 0, SbLL.AbsoluteContentSize.Y + 8)
        end)
    end

    -- CONTENT AREA
    ContentArea = MakeFrame({
        Name = "ContentArea",
        Size = UDim2.new(1, -204, 1, -54),
        Position = UDim2.new(0, 204, 0, 54),
        BackgroundColor3 = C.BG_PANEL,
        ZIndex = 11,
    }, MainWindow)

    -- Entrada animada
    MainWindow.Size = UDim2.new(0, 0, 0, 0)
    MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
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
    Padding(0, 0, 20, 0, List)

    SectionHeader(List, "[Q] START  |  Quantum OS v4.0", "Panel de inicio - Infinite Yield Engine - Delta Edition")

    -- Stats Cards
    local StatsRow = MakeFrame({Size=UDim2.new(1,0,0,88), BackgroundTransparency=1, ZIndex=15}, List)
    local SGrid = MakeFrame({Size=UDim2.new(1,-24,1,-16), Position=UDim2.new(0,12,0,8), BackgroundTransparency=1, ZIndex=15}, StatsRow)
    Make("UIGridLayout", {CellSize=UDim2.new(0.25,-4,1,-4), CellPadding=UDim2.new(0,4,0,4)}, SGrid)
    local statsItems = {
        {label="Jugador",   val=DISPLAY_NAME:sub(1,12), icon="P", color=C.PURPLE_GLOW},
        {label="Juego",     val=GAME_NAME:sub(1,12),    icon="G", color=C.CYAN_NEON},
        {label="AI Status", val="Online",                 icon="A", color=C.TEXT_GREEN},
        {label="Comandos",  val=tostring(#(function() local t={} for k in pairs(Commands) do t[#t+1]=k end return t end())), icon="C", color=C.GOLD_NEON},
    }
    for _, s in ipairs(statsItems) do
        local Card = MakeFrame({BackgroundColor3=C.BG_CARD, ZIndex=16}, SGrid)
        Corner(12, Card)
        Stroke(1, C.BORDER, Card)
        MakeLabel({Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,6), BackgroundTransparency=1,
            Text="[" .. s.icon .. "]", TextSize=14, Font=Enum.Font.GothamBold, TextColor3=s.color, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,18), Position=UDim2.new(0,4,0,32), BackgroundTransparency=1,
            Text=s.val, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=s.color, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,13), Position=UDim2.new(0,4,0,52), BackgroundTransparency=1,
            Text=s.label, Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED, ZIndex=17}, Card)
    end

    -- Agentes activos
    local agents = {
        {icon="[O]", name="Orquestador",     model="llama-3.3-70b",   desc="Dirige el flujo multi-agente"},
        {icon="[G]", name="Game Analyst",    model="nemotron-120b",   desc="Analisis de mecanicas de juego"},
        {icon="[C]", name="Code Expert",     model="qwen3-coder",     desc="Scripts Lua y errores Delta"},
        {icon="[S]", name="Strategy Agent",  model="deepseek-v4",     desc="Estrategias optimas y builds"},
        {icon="[A]", name="Creative Agent",  model="gemma-4-31b",     desc="Ideas y personalizacion"},
        {icon="[F]", name="Fast Agent",      model="llama-3.2-3b",    desc="Respuestas rapidas"},
    }
    local AgTitle = MakeFrame({Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, ZIndex=15}, List)
    MakeLabel({Size=UDim2.new(1,-24,1,0), Position=UDim2.new(0,12,0,0), BackgroundTransparency=1,
        Text="SISTEMA MULTI-AGENTE ACTIVO", Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=C.PURPLE_GLOW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=15}, AgTitle)

    local AgList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, List)
    ListLayout({Padding=UDim.new(0,4)}, AgList)
    Padding(0, 12, 0, 12, AgList)

    for _, ag in ipairs(agents) do
        local AC = MakeFrame({Size=UDim2.new(1,0,0,48), BackgroundColor3=C.BG_CARD, ZIndex=16}, AgList)
        Corner(10, AC)
        Stroke(1, C.BORDER, AC)
        local IconF = MakeFrame({Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,10,0.5,-17),
            BackgroundColor3=C.PURPLE_DIM, BackgroundTransparency=0.4, ZIndex=17}, AC)
        Corner(8, IconF)
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=ag.icon,
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.PURPLE_GLOW, ZIndex=18}, IconF)
        MakeLabel({Size=UDim2.new(1,-180,0,18), Position=UDim2.new(0,52,0,7), BackgroundTransparency=1,
            Text=ag.name, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AC)
        MakeLabel({Size=UDim2.new(1,-180,0,14), Position=UDim2.new(0,52,0,26), BackgroundTransparency=1,
            Text=ag.desc, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AC)
        local StB = MakeLabel({Size=UDim2.new(0,100,0,20), Position=UDim2.new(1,-108,0.5,-10),
            BackgroundColor3=Color3.fromRGB(0,40,20), Text="* " .. ag.model,
            Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TEXT_GREEN, ZIndex=17}, AC)
        Corner(10, StB)
    end

    local LL = List:FindFirstChildWhichIsA("UIListLayout")
    if LL then
        LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, LL.AbsoluteContentSize.Y + 20)
        end)
    end
end

-- ==============================================================================
-- SECCION 14 -- TAB: CMD BAR (Barra de Comandos Estilo Infinite Yield)
-- ==============================================================================

_G["QOS_Tab_CMD_BAR"] = function()
    local Tab = MakeFrame({Name="Tab_CMD", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "[>] BARRA DE COMANDOS", "Infinite Yield Engine - Prefijo: " .. (ENV.QOS_Prefix or ";") .. " - Escribe un comando")

    -- Instruccion del prefijo
    local InfoBar = MakeFrame({Size=UDim2.new(1,-32,0,36), Position=UDim2.new(0,16,0,68),
        BackgroundColor3=C.BG_GLASS, ZIndex=15}, Tab)
    Corner(10, InfoBar)
    Stroke(1, C.CYAN_DIM, InfoBar)
    MakeLabel({Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1,
        Text="Prefijo actual: [" .. (ENV.QOS_Prefix or ";") .. "]  |  Ejemplo: " .. (ENV.QOS_Prefix or ";") .. "fly 80  |  " .. (ENV.QOS_Prefix or ";") .. "help  |  " .. (ENV.QOS_Prefix or ";") .. "speed 200",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, InfoBar)

    -- Command bar GRANDE estilo IY
    local CmdFrame = MakeFrame({Size=UDim2.new(1,-32,0,56), Position=UDim2.new(0,16,0,112),
        BackgroundColor3=C.CMDBAR_BG, ZIndex=15}, Tab)
    Corner(14, CmdFrame)
    local cmdStroke = Stroke(2, C.PURPLE_DIM, CmdFrame)
    local CmdInput = MakeBox({Size=UDim2.new(1,-106,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText=";comando arg1 arg2...",
        Font=Enum.Font.Code, TextSize=15, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=16}, CmdFrame)
    CmdInput.Focused:Connect(function()   Tween(cmdStroke, TI_FAST, {Color=C.PURPLE_NEON}) end)
    CmdInput.FocusLost:Connect(function() Tween(cmdStroke, TI_FAST, {Color=C.PURPLE_DIM}) end)

    local ExecBtn = MakeButton({Size=UDim2.new(0,80,0,38), Position=UDim2.new(1,-90,0.5,-19),
        BackgroundColor3=C.PURPLE_NEON, BorderSizePixel=0,
        Text="EXEC", Font=Enum.Font.GothamBold, TextSize=13, TextColor3=Color3.new(1,1,1), ZIndex=16}, CmdFrame)
    Corner(10, ExecBtn)
    Gradient(Color3.fromRGB(130,20,210), Color3.fromRGB(70,0,170), 135, ExecBtn)

    -- Historial de comandos
    local HistTitle = MakeFrame({Size=UDim2.new(1,-32,0,26), Position=UDim2.new(0,16,0,176),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="HISTORIAL DE COMANDOS",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.PURPLE_GLOW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, HistTitle)

    local HistScroll = MakeScroll({Size=UDim2.new(1,-32,1,-208), Position=UDim2.new(0,16,0,204),
        BackgroundColor3=Color3.fromRGB(5,5,14), ScrollBarThickness=3, ZIndex=15}, Tab)
    Corner(10, HistScroll)
    Stroke(1, C.BORDER, HistScroll)
    local HistList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, HistScroll)
    ListLayout({Padding=UDim.new(0,2)}, HistList)
    Padding(6,8,6,8, HistList)

    local function RefreshHistory()
        for _, c in pairs(HistList:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
        end
        for i, entry in ipairs(ENV.QOS_CommandHistory) do
            local Row = MakeButton({Size=UDim2.new(1,0,0,32), BackgroundColor3=C.BG_CARD, ZIndex=16}, HistList)
            Corner(8, Row)
            MakeLabel({Size=UDim2.new(0,16,1,0), BackgroundTransparency=1, Text=">",
                Font=Enum.Font.Code, TextSize=12, TextColor3=C.PURPLE_NEON, ZIndex=17}, Row)
            MakeLabel({Size=UDim2.new(1,-36,1,0), Position=UDim2.new(0,20,0,0), BackgroundTransparency=1,
                Text=entry, Font=Enum.Font.Code, TextSize=12, TextColor3=C.CYAN_NEON,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Row)
            Row.MouseButton1Click:Connect(function()
                CmdInput.Text = entry
                CmdInput:CaptureFocus()
            end)
        end
        local hl = HistList:FindFirstChildWhichIsA("UIListLayout")
        if hl then HistScroll.CanvasSize = UDim2.new(0,0,0,hl.AbsoluteContentSize.Y+12) end
    end
    RefreshHistory()

    -- Listado de todos los comandos disponibles
    local AllCmdsTitle = MakeFrame({Size=UDim2.new(1,-32,0,26), Position=UDim2.new(0,16,1,-200),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    -- (se muestra en scroll de historial; para ver todos: ;help)

    local function Execute()
        local input = CmdInput.Text
        if input == "" then return end
        Tween(ExecBtn, TI_FAST, {BackgroundColor3 = C.TOGGLE_ON})
        ParseAndExecute(input)
        CmdInput.Text = ""
        RefreshHistory()
        task.wait(0.3)
        Tween(ExecBtn, TI_FAST, {BackgroundColor3 = C.PURPLE_NEON})
    end
    ExecBtn.MouseButton1Click:Connect(Execute)
    CmdInput.FocusLost:Connect(function(enter) if enter then Execute() end end)

    -- Comandos rapidos
    local QuickTitle = MakeFrame({Size=UDim2.new(1,-32,0,26), Position=UDim2.new(0,16,1,-174),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="COMANDOS RAPIDOS",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.PURPLE_GLOW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, QuickTitle)

    local QScroll = MakeScroll({Size=UDim2.new(1,-32,0,88), Position=UDim2.new(0,16,1,-148),
        BackgroundTransparency=1, ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.X, ZIndex=15}, Tab)
    local QRow = MakeFrame({Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
        BackgroundTransparency=1, ZIndex=15}, QScroll)
    local QL = ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6)}, QRow)

    local quickCmds = {
        {label="Fly ON",        cmd=";fly 60"},
        {label="Speed 200",     cmd=";speed 200"},
        {label="NoClip",        cmd=";noclip"},
        {label="God Mode",      cmd=";godmode"},
        {label="ESP ON",        cmd=";esp"},
        {label="Anti-Aim",      cmd=";antiaim"},
        {label="Inf Jump",      cmd=";jump 100"},
        {label="Speed Reset",   cmd=";speed 16"},
        {label="Gravity 50",    cmd=";gravity 50"},
        {label="Time 12",       cmd=";settime 12"},
        {label="Lista Players", cmd=";players"},
        {label="Rejoin",        cmd=";rejoin"},
    }
    for _, qc in ipairs(quickCmds) do
        local QB = MakeButton({Size=UDim2.new(0,110,0,36), BackgroundColor3=C.BG_CARD,
            BorderSizePixel=0, Text="", ZIndex=16}, QRow)
        Corner(10, QB)
        Stroke(1, C.BORDER, QB)
        MakeLabel({Size=UDim2.new(1,-16,0,16), Position=UDim2.new(0,8,0,4), BackgroundTransparency=1,
            Text=qc.label, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.CYAN_NEON,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, QB)
        MakeLabel({Size=UDim2.new(1,-16,0,14), Position=UDim2.new(0,8,0,20), BackgroundTransparency=1,
            Text=qc.cmd, Font=Enum.Font.Code, TextSize=10, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, QB)
        QB.MouseButton1Click:Connect(function()
            CmdInput.Text = qc.cmd
            Tween(QB, TI_FAST, {BackgroundColor3=C.PURPLE_DIM})
            task.wait(0.2)
            Tween(QB, TI_FAST, {BackgroundColor3=C.BG_CARD})
        end)
        HoverGlow(QB, C.BG_CARD, C.BG_GLASS)
    end
    QL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        QScroll.CanvasSize = UDim2.new(0, QL.AbsoluteContentSize.X + 12, 0, 0)
    end)
end

-- ==============================================================================
-- SECCION 15 -- TAB: QUANTUM ORACLE (Chat Multi-Agente)
-- ==============================================================================

_G["QOS_Tab_QUANTUM_ORACLE"] = function()
    local Tab = MakeFrame({Name="Tab_ORACLE", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab

    SectionHeader(Tab, "[*] QUANTUM ORACLE", "Multi-Agent AI | Orquestador: llama-3.3-70b | Juego: " .. GAME_NAME)

    -- Info del orbe
    local OrbFrame = MakeFrame({Size=UDim2.new(1,-32,0,100), Position=UDim2.new(0,16,0,68),
        BackgroundColor3=C.BG_GLASS, ZIndex=16}, Tab)
    Corner(16, OrbFrame)
    Gradient(C.BG_GLASS, Color3.fromRGB(40,0,80), 135, OrbFrame)
    Stroke(1, C.BORDER_BRIGHT, OrbFrame)

    local OrbBadge = MakeFrame({Size=UDim2.new(0,64,0,64), Position=UDim2.new(0,14,0.5,-32),
        BackgroundColor3=C.PURPLE_DIM, ZIndex=17}, OrbFrame)
    Corner(32, OrbBadge)
    Stroke(3, C.PURPLE_NEON, OrbBadge)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="AI",
        Font=Enum.Font.GothamBold, TextSize=22, TextColor3=C.PURPLE_GLOW, ZIndex=18}, OrbBadge)
    task.spawn(function()
        while OrbBadge and OrbBadge.Parent do
            Tween(OrbBadge, TI_SINE, {BackgroundColor3=C.PURPLE_GLOW}); task.wait(1.2)
            Tween(OrbBadge, TI_SINE, {BackgroundColor3=C.PURPLE_DIM}); task.wait(1.2)
        end
    end)

    MakeLabel({Size=UDim2.new(1,-106,0,22), Position=UDim2.new(0,90,0,12), BackgroundTransparency=1,
        Text="QUANTUM ORACLE  |  Multi-Agent AI",
        Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)
    local AgentBadge = MakeLabel({Size=UDim2.new(1,-106,0,16), Position=UDim2.new(0,90,0,36),
        BackgroundTransparency=1, Text="[O] Orquestador: llama-3.3-70b  |  5 Agentes listos",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)
    local ActiveAg = MakeLabel({Size=UDim2.new(1,-106,0,16), Position=UDim2.new(0,90,0,58),
        BackgroundTransparency=1, Text="Juego: '" .. GAME_NAME .. "'  |  En espera",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)

    -- Sugerencias rapidas
    local SugFrame = MakeFrame({Size=UDim2.new(1,-32,0,28), Position=UDim2.new(0,16,0,176),
        BackgroundTransparency=1, ZIndex=16}, Tab)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,5)}, SugFrame)
    local sugs = {"Mejores scripts?", "Error Lua fix", "Como farmear?", "Script anti-ban", "Build optimo"}
    for _, sug in ipairs(sugs) do
        local SB = MakeButton({Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.BG_CARD, Text=sug, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.CYAN_NEON, ZIndex=17}, SugFrame)
        Corner(10, SB)
        Padding(0,10,0,10,SB)
        Stroke(1, C.CYAN_DIM, SB)
    end

    -- Chat scroll
    local ChatScroll = MakeScroll({Size=UDim2.new(1,-32,1,-242), Position=UDim2.new(0,16,0,212),
        BackgroundColor3=Color3.fromRGB(5,5,14), ScrollBarThickness=3, ZIndex=15}, Tab)
    Corner(12, ChatScroll)
    Stroke(1, C.BORDER, ChatScroll)
    local ChatList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ChatScroll)
    ListLayout({Padding=UDim.new(0,8)}, ChatList)
    Padding(10,10,10,10, ChatList)

    local function ScrollBot()
        task.wait(0.05)
        local ll = ChatList:FindFirstChildWhichIsA("UIListLayout")
        local sz = ll and ll.AbsoluteContentSize.Y or 0
        ChatScroll.CanvasSize = UDim2.new(0,0,0,sz+20)
        ChatScroll.CanvasPosition = Vector2.new(0, sz)
    end

    local function AddMsg(text, isUser, meta)
        local col = isUser and C.PURPLE_DIM or (meta and meta.color or C.BG_CARD)
        local Bubble = MakeFrame({
            Size = UDim2.new(0.86,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            Position = isUser and UDim2.new(0.14,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3 = col,
            BackgroundTransparency = isUser and 0 or 0.25,
            ZIndex = 16,
        }, ChatList)
        Corner(12, Bubble)
        Padding(10,14,10,14, Bubble)
        if not isUser and meta then
            MakeLabel({Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
                Text=meta.icon .. " " .. meta.name, Font=Enum.Font.GothamBold, TextSize=10,
                TextColor3=meta.color, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Bubble)
        end
        local yOff = (not isUser and meta) and 18 or 0
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
            BackgroundColor3=C.BG_CARD, BackgroundTransparency=0.3, ZIndex=16,
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

    AddMsg("[AI] Hola, " .. DISPLAY_NAME .. "! Soy el Quantum Oracle.\n\nMi sistema Multi-Agente detecto el juego: '" .. GAME_NAME .. "'.\nEl Orquestador dirigira tu consulta al agente mas adecuado:\n[G] Game Analyst | [C] Code Expert | [S] Strategy | [A] Creative | [F] Fast\n\nEn que te puedo ayudar hoy?",
        false, {icon="[AI]", name="Quantum Oracle", color=C.PURPLE_GLOW})

    -- Conectar sugerencias
    for _, sb in pairs(SugFrame:GetChildren()) do
        if sb:IsA("TextButton") then
            local txt = sb.Text
            sb.MouseButton1Click:Connect(function()
                for _, d in pairs(Tab:GetDescendants()) do
                    if d.Name == "OracleChatInput" then d.Text = txt end
                end
            end)
        end
    end

    -- Input row
    local InputRow = MakeFrame({Size=UDim2.new(1,-32,0,46), Position=UDim2.new(0,16,1,-60),
        BackgroundColor3=C.BG_CARD, ZIndex=16}, Tab)
    Corner(13, InputRow)
    Stroke(1, C.BORDER, InputRow)
    local ChatInput = MakeBox({Name="OracleChatInput",
        Size=UDim2.new(1,-58,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text="",
        PlaceholderText="Pregunta algo al Oracle...",
        Font=Enum.Font.Gotham, TextSize=13, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=17}, InputRow)
    local SendBtn = MakeButton({Size=UDim2.new(0,42,0,34), Position=UDim2.new(1,-48,0.5,-17),
        BackgroundColor3=C.PURPLE_NEON, Text=">", Font=Enum.Font.GothamBold,
        TextSize=16, TextColor3=Color3.new(1,1,1), ZIndex=17}, InputRow)
    Corner(10, SendBtn)

    local isWaiting = false
    local function SendMessage()
        if isWaiting then return end
        local msg = ChatInput.Text:gsub("^%s+",""):gsub("%s+$","")
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
                ActiveAg.Text = meta.icon .. " Agente activo: " .. meta.name
                AgentBadge.Text = meta.icon .. " Usando: " .. meta.name .. "  |  OpenRouter AI"
            end,
            function(response, meta)
                HideThinking()
                AddMsg(response, false, meta)
                isWaiting = false
                SendBtn.Text = ">"
                ActiveAg.Text = "En espera de consulta"
                AgentBadge.Text = "[O] Orquestador: llama-3.3-70b  |  5 Agentes listos"
            end,
            function(errMsg)
                HideThinking()
                AddMsg("[ERROR] " .. tostring(errMsg) .. "\nVerifica tu API Key en Ajustes.", false,
                    {icon="[X]", name="Sistema", color=C.TEXT_RED})
                isWaiting = false
                SendBtn.Text = ">"
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

    local SRow = MakeFrame({Size=UDim2.new(1,-32,0,38), Position=UDim2.new(0,16,0,68),
        BackgroundColor3=C.BG_CARD, ZIndex=15}, Tab)
    Corner(12, SRow)
    Stroke(1, C.BORDER, SRow)
    MakeBox({Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1,
        Text="", PlaceholderText="[S] Buscar scripts...", Font=Enum.Font.Gotham, TextSize=13,
        TextColor3=C.TEXT_WHITE, PlaceholderColor3=C.TEXT_MUTED, ZIndex=16}, SRow)

    local ScScroll = MakeScroll({Size=UDim2.new(1,-32,1,-116), Position=UDim2.new(0,16,0,114),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local ScList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ScScroll)
    ListLayout({Padding=UDim.new(0,8)}, ScList)

    local scripts = {
        {title="Auto Farm Pro v5.2",    author="LXNDXN",     verified=true,  icon="F", desc="Auto farm optimizado",      script='print("[QOS] Auto Farm activado")'},
        {title="ESP Pro - All Players", author="QuantumDev", verified=true,  icon="E", desc="ESP con highlight color",    script='print("[QOS] ESP activo")'},
        {title="Infinite Jump v2",      author="DeltaFarm",  verified=false, icon="J", desc="Salta infinitamente",       script='print("[QOS] InfJump activo")'},
        {title="Speed Hack x10",        author="LXNDXN",     verified=true,  icon="S", desc="Velocidad x10 suave",       script='print("[QOS] Speed x10")'},
        {title="God Mode Bypass",       author="NullSec",    verified=false, icon="G", desc="Salud infinita bypass",     script='print("[QOS] God Mode")'},
        {title="Auto Collect Items",    author="QuantumDev", verified=true,  icon="C", desc="Recoleccion automatica",    script='print("[QOS] AutoCollect activo")'},
        {title="Teleport Players",      author="LXNDXN",     verified=true,  icon="T", desc="Teleport rapido a players", script='print("[QOS] TeleportTP activo")'},
        {title="Anti-AFK Pro",          author="QuantumDev", verified=true,  icon="A", desc="Evita el kick de AFK",     script='print("[QOS] AntiAFK activo")'},
    }

    for _, s in ipairs(scripts) do
        local Card = MakeFrame({Size=UDim2.new(1,0,0,78), BackgroundColor3=C.BG_CARD, ZIndex=16}, ScList)
        Corner(14, Card)
        Stroke(1, C.BORDER, Card)

        local Thumb = MakeFrame({Size=UDim2.new(0,52,0,52), Position=UDim2.new(0,10,0.5,-26),
            BackgroundColor3=C.PURPLE_DIM, ZIndex=17}, Card)
        Corner(12, Thumb)
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
            Text="[" .. s.icon .. "]", Font=Enum.Font.GothamBold, TextSize=16,
            TextColor3=C.PURPLE_GLOW, ZIndex=18}, Thumb)

        MakeLabel({Size=UDim2.new(1,-200,0,20), Position=UDim2.new(0,72,0,10), BackgroundTransparency=1,
            Text=s.title, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-200,0,14), Position=UDim2.new(0,72,0,32), BackgroundTransparency=1,
            Text="by " .. s.author .. "  |  " .. s.desc, Font=Enum.Font.Gotham, TextSize=11,
            TextColor3=C.TEXT_SOFT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)

        if s.verified then
            local VB = MakeLabel({Size=UDim2.new(0,116,0,16), Position=UDim2.new(0,72,0,54),
                BackgroundColor3=Color3.fromRGB(0,44,22), Text="[v] Verificado Delta",
                Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_GREEN, ZIndex=18}, Card)
            Corner(8, VB)
        end

        local ExBtn = MakeButton({Size=UDim2.new(0,88,0,28), Position=UDim2.new(1,-168,0.5,-14),
            BackgroundColor3=C.PURPLE_NEON, Text="[>] EXEC",
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), ZIndex=17}, Card)
        Corner(8, ExBtn)
        HoverGlow(ExBtn, C.PURPLE_NEON, C.PURPLE_GLOW)
        ExBtn.MouseButton1Click:Connect(function()
            pcall(function() loadstring(s.script)() end)
            PushNotification("Script Ejecutado", s.title .. " activado.", "SUCCESS", 3)
        end)

        local SaveBtn = MakeButton({Size=UDim2.new(0,66,0,28), Position=UDim2.new(1,-72,0.5,-14),
            BackgroundColor3=C.BG_GLASS, Text="[*] SAVE",
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, ZIndex=17}, Card)
        Corner(8, SaveBtn)
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
    SectionHeader(Tab, "[P] PLAYER MODS", "Modificaciones del personaje - Infinite Yield Engine")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateSliderWidget(SL, "WalkSpeed", 0, 500, 16, "", function(v)
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v end
    end)
    CreateSliderWidget(SL, "JumpPower", 0, 500, 50, "", function(v)
        local hum = GetHumanoid()
        if hum then hum.JumpPower = v end
    end)
    CreateSliderWidget(SL, "Gravedad", 0, 500, 196, "", function(v)
        workspace.Gravity = v
    end)
    CreateSliderWidget(SL, "FOV Camara", 10, 120, 70, "deg", function(v)
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = v end
    end)

    CreateToggleWidget(SL, "No Clip", false, function(state)
        ENV.QOS_NoclipActive = state
        if state then
            ENV.QOS_NoclipConn = RunService.Stepped:Connect(function()
                local char = GetCharacter()
                if char then
                    for _, p in pairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
            TrackConn(ENV.QOS_NoclipConn)
        elseif ENV.QOS_NoclipConn then
            pcall(function() ENV.QOS_NoclipConn:Disconnect() end)
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
        if state then
            ENV.QOS_AntiAFK = true
            task.spawn(function()
                while ENV.QOS_AntiAFK do
                    local vrs = game:GetService("VirtualInputManager")
                    pcall(function()
                        vrs:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        vrs:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    end)
                    task.wait(60)
                end
            end)
        else
            ENV.QOS_AntiAFK = false
        end
    end)

    CreateToggleWidget(SL, "Invisible (local)", false, function(state)
        local char = GetCharacter()
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = state and 1 or 0
                end
            end
        end
    end)

    CreateToggleWidget(SL, "Vuelo", false, function(state)
        ParseAndExecute(";fly 60")
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
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateSliderWidget(SL, "Hora del Dia (0-24)", 0, 24, 12, "h", function(v)
        Lighting.TimeOfDay = string.format("%02d:00:00", v)
    end)
    CreateSliderWidget(SL, "Brillo", 0, 10, 2, "x", function(v)
        Lighting.Brightness = v
    end)
    CreateSliderWidget(SL, "Niebla (FogEnd)", 0, 10000, 1000, "m", function(v)
        Lighting.FogEnd = v
    end)
    CreateSliderWidget(SL, "Saturacion de Color", -1, 10, 0, "", function(v)
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
        cc.Saturation = v
    end)
    CreateSliderWidget(SL, "Contraste", -1, 10, 0, "", function(v)
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
        cc.Contrast = v
    end)

    CreateToggleWidget(SL, "Fullbright", false, function(state)
        Lighting.Brightness = state and 10 or 2
        Lighting.FogEnd = state and 100000 or 1000
        Lighting.GlobalShadows = not state
        if state then
            local al = Instance.new("AmbientLight", Lighting)
            al.Name = "QOS_AmbientLight"
            al.Brightness = 1
        else
            local al = Lighting:FindFirstChild("QOS_AmbientLight")
            if al then al:Destroy() end
        end
    end)

    CreateToggleWidget(SL, "Rain Effect", false, function(state)
        if state then
            local part = Instance.new("Part", workspace)
            part.Name = "QOS_RainPart"
            part.Size = Vector3.new(50,1,50)
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            local root = GetRootPart()
            if root then part.CFrame = root.CFrame + Vector3.new(0,30,0) end
            local ps = Instance.new("ParticleEmitter", part)
            ps.Rate = 200
            ps.Speed = NumberRange.new(40,60)
            ps.Lifetime = NumberRange.new(2,3)
            ps.Direction = Vector3.new(0,-1,0)
            ps.SpreadAngle = Vector2.new(5,5)
        else
            local p = workspace:FindFirstChild("QOS_RainPart")
            if p then p:Destroy() end
        end
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
    SectionHeader(Tab, "[E] ESP & VISUALS", "Extra Sensory Perception - Selection Boxes - Tracers")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateToggleWidget(SL, "ESP Jugadores (SelectionBox)", false, function(state)
        ParseAndExecute(";esp")
    end)

    CreateToggleWidget(SL, "Chams - Sin Texturas", false, function(state)
        local char = GetCharacter()
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Material = state and Enum.Material.Neon or Enum.Material.SmoothPlastic
                end
            end
        end
    end)

    CreateToggleWidget(SL, "Wireframe Vision", false, function(state)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(GetCharacter() or game) then
                pcall(function()
                    obj.CastShadow  = not state
                    obj.Transparency = state and 0.85 or 0
                end)
            end
        end
    end)

    CreateSliderWidget(SL, "Transparencia del mapa", 0, 100, 0, "%", function(v)
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(GetCharacter() or workspace) then
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
    SectionHeader(Tab, "[T] TELEPORT", "Teleportacion de jugadores - Waypoints - Coordenadas")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,6)}, SL)
    Padding(12,14,20,14, SL)

    -- Lista de jugadores con botones de TP
    local PlTitle = MakeFrame({Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, ZIndex=15}, SL)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="JUGADORES EN EL SERVIDOR",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.PURPLE_GLOW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, PlTitle)

    local function RefreshPlayers()
        -- Limpiar previos
        for _, c in pairs(SL:GetChildren()) do
            if c.Name == "PlayerTPCard" then c:Destroy() end
        end
        for _, p in pairs(Players:GetPlayers()) do
            local Card = MakeFrame({Name="PlayerTPCard", Size=UDim2.new(1,0,0,56),
                BackgroundColor3=C.BG_CARD, ZIndex=16}, SL)
            Corner(12, Card)
            Stroke(1, p == LocalPlayer and C.PURPLE_NEON or C.BORDER, Card)

            local Av2 = MakeLabel({Size=UDim2.new(0,36,0,36), Position=UDim2.new(0,10,0.5,-18),
                BackgroundColor3=p == LocalPlayer and C.PURPLE_DIM or Color3.fromRGB(30,28,60),
                Text=string.upper(string.sub(p.DisplayName,1,2)),
                Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE, ZIndex=17}, Card)
            Corner(18, Av2)

            MakeLabel({Size=UDim2.new(1,-180,0,18), Position=UDim2.new(0,56,0,9), BackgroundTransparency=1,
                Text=p.DisplayName .. (p == LocalPlayer and " [TU]" or ""),
                Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
            MakeLabel({Size=UDim2.new(1,-180,0,14), Position=UDim2.new(0,56,0,29), BackgroundTransparency=1,
                Text="@" .. p.Name,
                Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)

            if p ~= LocalPlayer then
                local TPBtn = MakeButton({Size=UDim2.new(0,72,0,28), Position=UDim2.new(1,-152,0.5,-14),
                    BackgroundColor3=C.PURPLE_NEON, Text="[T] Ir",
                    Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), ZIndex=17}, Card)
                Corner(8, TPBtn)
                TPBtn.MouseButton1Click:Connect(function()
                    ParseAndExecute(";" .. "tp " .. p.Name)
                end)

                local BringBtn = MakeButton({Size=UDim2.new(0,72,0,28), Position=UDim2.new(1,-72,0.5,-14),
                    BackgroundColor3=C.BG_GLASS, Text="[B] Traer",
                    Font=Enum.Font.GothamSemibold, TextSize=11, TextColor3=C.TEXT_SOFT, ZIndex=17}, Card)
                Corner(8, BringBtn)
                Stroke(1, C.BORDER, BringBtn)
                BringBtn.MouseButton1Click:Connect(function()
                    ParseAndExecute(";" .. "bringtp " .. p.Name)
                end)
            end
        end
    end
    RefreshPlayers()

    -- Boton Refresh
    local RefBtn = MakeButton({Size=UDim2.new(1,0,0,38), BackgroundColor3=C.BG_GLASS,
        BorderSizePixel=0, Text="[R] Actualizar lista de jugadores",
        Font=Enum.Font.GothamSemibold, TextSize=13, TextColor3=C.CYAN_NEON, ZIndex=15}, SL)
    Corner(10, RefBtn)
    Stroke(1, C.CYAN_DIM, RefBtn)
    RefBtn.MouseButton1Click:Connect(RefreshPlayers)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 21 -- TAB: SYSTEM SETTINGS
-- ==============================================================================

_G["QOS_Tab_SYSTEM_SETTINGS"] = function()
    local Tab = MakeFrame({Name="Tab_SETTINGS", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[S] AJUSTES DEL SISTEMA", "Configuracion - AI - Executor - Preferencias")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    -- API Key Card
    local KC = MakeFrame({Size=UDim2.new(1,0,0,100), BackgroundColor3=C.BG_CARD, ZIndex=16}, SL)
    Corner(14, KC)
    Stroke(1, C.BORDER, KC)
    MakeLabel({Size=UDim2.new(1,-160,0,20), Position=UDim2.new(0,14,0,10), BackgroundTransparency=1,
        Text="OpenRouter API Key", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KC)
    MakeLabel({Size=UDim2.new(1,-160,0,14), Position=UDim2.new(0,14,0,30), BackgroundTransparency=1,
        Text="Estado: " .. (ENV.QOS_OpenRouterKey and "[v] Conectado" or "[x] No conectado"),
        Font=Enum.Font.Gotham, TextSize=12,
        TextColor3 = ENV.QOS_OpenRouterKey and C.TEXT_GREEN or C.TEXT_RED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KC)
    local ApiBox = MakeBox({Size=UDim2.new(1,-28,0,36), Position=UDim2.new(0,14,0,52),
        BackgroundColor3=Color3.fromRGB(8,6,20), BorderSizePixel=0,
        Text=ENV.QOS_OpenRouterKey or "", PlaceholderText="sk-or-v1-...",
        Font=Enum.Font.Code, TextSize=12, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=17}, KC)
    Corner(8, ApiBox)
    Padding(0,10,0,10, ApiBox)
    Stroke(1, C.BORDER, ApiBox)
    ApiBox.FocusLost:Connect(function(enter)
        if enter then
            ENV.QOS_OpenRouterKey = ApiBox.Text:gsub("%s+","")
            PushNotification("API Key","Clave guardada en sesion","SUCCESS",3)
        end
    end)

    -- Prefijo
    local PrefixCard = MakeFrame({Size=UDim2.new(1,0,0,60), BackgroundColor3=C.BG_CARD, ZIndex=16}, SL)
    Corner(14, PrefixCard)
    Stroke(1, C.BORDER, PrefixCard)
    MakeLabel({Size=UDim2.new(1,-80,0,20), Position=UDim2.new(0,14,0,8), BackgroundTransparency=1,
        Text="Prefijo de comandos", Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, PrefixCard)
    MakeLabel({Size=UDim2.new(1,-80,0,14), Position=UDim2.new(0,14,0,28), BackgroundTransparency=1,
        Text="Caracter que activa los comandos (ej: ; . , !)",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, PrefixCard)
    local PBox = MakeBox({Size=UDim2.new(0,50,0,36), Position=UDim2.new(1,-64,0.5,-18),
        BackgroundColor3=Color3.fromRGB(8,6,20), BorderSizePixel=0,
        Text=ENV.QOS_Prefix or ";",
        Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C.PURPLE_GLOW,
        ClearTextOnFocus=false, ZIndex=17}, PrefixCard)
    Corner(8, PBox)
    Stroke(1, C.PURPLE_DIM, PBox)
    PBox.FocusLost:Connect(function(enter)
        if enter and #PBox.Text == 1 then
            ENV.QOS_Prefix = PBox.Text
            PushNotification("Prefijo","Nuevo prefijo: " .. PBox.Text,"SUCCESS",3)
        end
    end)

    CreateToggleWidget(SL, "Particulas de fondo", true, function(state)
        -- placeholder; se necesitaria reinicio para efecto completo
    end)
    CreateToggleWidget(SL, "Notificaciones Toast", true, function(state)
        ENV.QOS_ToastsEnabled = state
    end)

    -- Info del sistema
    local InfoCard = MakeFrame({Size=UDim2.new(1,0,0,80), BackgroundColor3=C.BG_CARD, ZIndex=16}, SL)
    Corner(14, InfoCard)
    Stroke(1, C.BORDER, InfoCard)
    local infoLines = {
        "[Q] Quantum OS v4.0 - Delta Edition",
        "[I] Jugador: " .. DISPLAY_NAME .. " (@" .. USERNAME .. ")",
        "[G] Juego: " .. GAME_NAME,
        "[J] PlaceId: " .. PlaceId,
    }
    local ifl = ListLayout({Padding=UDim.new(0,2)}, InfoCard)
    Padding(8,12,8,12, InfoCard)
    for _, line in ipairs(infoLines) do
        MakeLabel({Size=UDim2.new(1,0,0,14), BackgroundTransparency=1, Text=line,
            Font=Enum.Font.Code, TextSize=11, TextColor3=C.TEXT_SOFT,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, InfoCard)
    end

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 22 -- TAB: POWER
-- ==============================================================================

_G["QOS_Tab_POWER"] = function()
    local Tab = MakeFrame({Name="Tab_POWER", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[O] POWER", "Opciones de sesion y conexion")

    local Center = MakeFrame({Size=UDim2.new(0,320,0,300), Position=UDim2.new(0.5,-160,0.5,-150),
        BackgroundTransparency=1, ZIndex=15}, Tab)
    local PList = MakeFrame({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, Center)
    ListLayout({Padding=UDim.new(0,10), HorizontalAlignment=Enum.HorizontalAlignment.Center}, PList)

    local powerOpts = {
        {label="Rejoin (mismo server)",     desc="Vuelves al mismo servidor", color=C.CYAN_NEON,    cmd=";rejoin"},
        {label="New Server (hop)",           desc="Saltas a otro servidor",    color=C.GOLD_NEON,   cmd=";server"},
        {label="Reset Personaje",            desc="Matas tu personaje local",  color=C.TEXT_YELLOW,  cmd=";reset"},
        {label="Cerrar Quantum OS",          desc="Destruye el GUI",           color=C.TEXT_RED,     cmd="CLOSE"},
    }
    for _, opt in ipairs(powerOpts) do
        local Btn = MakeButton({Size=UDim2.new(1,0,0,58), BackgroundColor3=C.BG_CARD,
            BorderSizePixel=0, Text="", ZIndex=16}, PList)
        Corner(14, Btn)
        Stroke(1, opt.color, Btn)
        MakeLabel({Size=UDim2.new(1,-20,0,22), Position=UDim2.new(0,14,0,8), BackgroundTransparency=1,
            Text=opt.label, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=opt.color,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Btn)
        MakeLabel({Size=UDim2.new(1,-20,0,14), Position=UDim2.new(0,14,0,32), BackgroundTransparency=1,
            Text=opt.desc, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Btn)
        Btn.MouseButton1Click:Connect(function()
            if opt.cmd == "CLOSE" then
                Tween(ScreenGui.MainWindow or ScreenGui:FindFirstChild("QuantumOS_v40"), TI_MED, {Size=UDim2.new(0,0,0,0)})
                task.wait(0.4)
                pcall(function() ScreenGui:Destroy() end)
            else
                ParseAndExecute(opt.cmd)
            end
        end)
        HoverGlow(Btn, C.BG_CARD, C.BG_GLASS)
    end
end

-- ==============================================================================
-- SECCION 23 -- KEYBINDS (Estilo Infinite Yield, usa InputBegan)
-- ==============================================================================

local function SetupKeybinds()
    TrackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        -- F1 = abrir/cerrar
        if input.KeyCode == Enum.KeyCode.F1 then
            if MainWindow then
                local vis = MainWindow.Size.Y.Scale > 0
                if vis then
                    Tween(MainWindow, TI_MED, {Size=UDim2.new(1,0,0,54)})
                else
                    Tween(MainWindow, TI_MED, {Size=UDim2.fromScale(1,1)})
                end
            end
        end
        -- F2 = Fly toggle
        if input.KeyCode == Enum.KeyCode.F2 then
            ParseAndExecute(";fly 60")
        end
        -- F3 = Noclip toggle
        if input.KeyCode == Enum.KeyCode.F3 then
            ParseAndExecute(";noclip")
        end
        -- F4 = God mode toggle
        if input.KeyCode == Enum.KeyCode.F4 then
            ParseAndExecute(";godmode")
        end
        -- F5 = ESP toggle
        if input.KeyCode == Enum.KeyCode.F5 then
            ParseAndExecute(";esp")
        end
        -- RightShift = Speed 200
        if input.KeyCode == Enum.KeyCode.RightShift then
            ParseAndExecute(";speed 200")
        end
    end))
end

-- ==============================================================================
-- SECCION 24 -- CHAT LISTENER (Estilo Infinite Yield)
-- Escucha el chat de Roblox para ejecutar comandos
-- ==============================================================================

local function SetupChatListener()
    local function OnChat(msg)
        if type(msg) ~= "string" then return end
        local prefix = ENV.QOS_Prefix or ";"
        if msg:sub(1, #prefix) == prefix then
            ParseAndExecute(msg)
        end
    end

    -- TextChatService listener
    local ok1 = pcall(function()
        local TextChatService = Services.TextChatService
        if TextChatService and TextChatService.MessageReceived then
            TrackConn(TextChatService.MessageReceived:Connect(function(msg)
                if msg.TextSource and msg.TextSource.UserId == LocalPlayer.UserId then
                    OnChat(msg.Text or "")
                end
            end))
        end
    end)

    -- Legacy chat listener
    if not ok1 then
        pcall(function()
            local ok2, SpeakingConns = pcall(function()
                local LSG = StarterGui:FindFirstChildWhichIsA("LocalScript", true)
                return LSG
            end)
        end)
    end

    -- Fallback: escuchar Humanoid Chatted
    pcall(function()
        if LocalPlayer then
            LocalPlayer.Chatted:Connect(function(msg)
                OnChat(msg)
            end)
        end
    end)
end

-- ==============================================================================
-- SECCION 25 -- GAME BOOSTER TAB
-- ==============================================================================

_G["QOS_Tab_GAME_BOOSTER"] = function()
    local Tab = MakeFrame({Name="Tab_BOOST", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "[B] GAME BOOSTER", "Optimizaciones de FPS y rendimiento")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-62), Position=UDim2.new(0,0,0,62),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,5)}, SL)
    Padding(12,14,20,14, SL)

    CreateToggleWidget(SL, "Quitar sombras (FPS boost)", false, function(state)
        Lighting.GlobalShadows = not state
    end)

    CreateToggleWidget(SL, "Reducir texturas (FPS boost)", false, function(state)
        if state then
            pcall(function()
                for _, p in pairs(workspace:GetDescendants()) do
                    if p:IsA("BasePart") then p.Material = Enum.Material.SmoothPlastic end
                end
            end)
        end
    end)

    CreateToggleWidget(SL, "Quitar niebla", false, function(state)
        Lighting.FogEnd = state and 100000 or 1000
    end)

    CreateToggleWidget(SL, "Ocultar otros jugadores (FPS)", false, function(state)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                p.Character:FindFirstChildWhichIsA("Model")
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = state and 1 or 0
                    end
                end
            end
        end
    end)

    CreateSliderWidget(SL, "LOD (calidad grafica)", 0, 4, 2, "", function(v)
        pcall(function()
            local SLevel = Enum.StreamingPauseMode[v] or Enum.StreamingPauseMode.Default
        end)
    end)

    local ll = SL:FindFirstChildWhichIsA("UIListLayout")
    if ll then ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+20)
    end) end
end

-- ==============================================================================
-- SECCION 26 -- FLOW PRINCIPAL
-- ==============================================================================

local function StartMainOS(deviceMode)
    CreateMainWindow()
    SetupKeybinds()
    SetupChatListener()

    -- Cargar tab START por defecto
    task.wait(0.55)
    local startBtn = SidebarButtons["START"]
    if startBtn then startBtn.MouseButton1Click:Fire() end

    -- Notificacion de bienvenida
    task.delay(0.9, function()
        PushNotification(
            "Quantum OS v4.0 Listo",
            "IY Engine activo | " .. tostring(#(function() local t={} for k in pairs(Commands) do t[#t+1]=k end return t end())) .. " comandos | Prefijo: " .. (ENV.QOS_Prefix or ";"),
            "SYSTEM", 5
        )
        task.wait(1)
        ShowToast("Multi-Agent AI", "5 agentes listos | Orquestador conectado", "[AI]", 3)
        task.wait(1.5)
        ShowToast("Keybinds activos", "F1=UI  F2=Fly  F3=Noclip  F4=God  F5=ESP", ">", 4)
    end)
end

local function Launch()
    CreateBootScreen()
    task.wait(5.5)
    CreateLoginScreen(function()
        -- Despues del login, seleccion de dispositivo inline (auto-detectado)
        local mode = IsOnMobile and "mobile" or "pc"
        ENV.QOS_DeviceMode = mode
        ENV.QOS_Unlocked   = true
        StartMainOS(mode)
    end)
end

-- ==============================================================================
-- INICIO
-- ==============================================================================

Launch()
