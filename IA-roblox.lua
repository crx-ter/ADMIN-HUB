-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 1 - ENVIRONMENT BOOTSTRAP
-- ═══════════════════════════════════════════════════════════════════════════════

-- FIX: getgenv() puede no existir en algunas versiones de Delta → fallback a _G
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

-- Limpiar instancias previas de forma segura
if ENV.QuantumOS_Instance    then pcall(function() ENV.QuantumOS_Instance:Destroy()    end) end
if ENV.QuantumOS_OracleFloat then pcall(function() ENV.QuantumOS_OracleFloat:Destroy() end) end
if ENV.QuantumOS_Connections then
    for _, c in pairs(ENV.QuantumOS_Connections) do pcall(function() c:Disconnect() end) end
end

ENV.QuantumOS_Connections   = {}
ENV.QuantumOS_ActiveTab     = nil
ENV.QuantumOS_Unlocked      = false
ENV.QuantumOS_OpenRouterKey = nil
ENV.QuantumOS_DeviceMode    = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 2 - SERVICIOS Y REFERENCIAS
-- ═══════════════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui", 10)

-- FIX: Esperar personaje y Humanoid con timeout para evitar nil call
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
-- FIX: WaitForChild con timeout en vez de FindFirstChildOfClass directo
local Humanoid  = Character:WaitForChild("Humanoid", 5)

-- FIX: Validar que el nombre del juego no sea nil
local DISPLAY_NAME = LocalPlayer.DisplayName or LocalPlayer.Name or "Jugador"
local USERNAME     = LocalPlayer.Name or "unknown"
local GAME_NAME    = (game.Name and game.Name ~= "") and game.Name or "Roblox"
local PLACE_ID     = game.PlaceId or 0

-- Re-enlazar personaje si muere y respawnea
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid  = newChar:WaitForChild("Humanoid", 5)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 3 - PALETA DE COLORES
-- ═══════════════════════════════════════════════════════════════════════════════

local C = {
    PURPLE_NEON = Color3.fromRGB(160, 32, 240),
    PURPLE_DIM  = Color3.fromRGB( 90, 15, 140),
    PURPLE_GLOW = Color3.fromRGB(180, 80, 255),
    CYAN_NEON   = Color3.fromRGB(  0,220, 255),
    CYAN_DIM    = Color3.fromRGB(  0,140, 180),
    PINK_NEON   = Color3.fromRGB(255, 60, 160),
    GOLD_NEON   = Color3.fromRGB(255,195,  50),

    BG_DEEP     = Color3.fromRGB(  4,  4, 14),
    BG_PANEL    = Color3.fromRGB( 10, 10, 26),
    BG_CARD     = Color3.fromRGB( 16, 16, 40),
    BG_SIDEBAR  = Color3.fromRGB(  6,  6, 18),
    BG_GLASS    = Color3.fromRGB( 22, 18, 48),
    BG_HEADER   = Color3.fromRGB( 12,  8, 30),

    TEXT_WHITE  = Color3.fromRGB(230,230,255),
    TEXT_SOFT   = Color3.fromRGB(160,155,200),
    TEXT_MUTED  = Color3.fromRGB( 90, 85,130),
    TEXT_GREEN  = Color3.fromRGB(  0,220,130),
    TEXT_RED    = Color3.fromRGB(255, 70, 70),
    TEXT_YELLOW = Color3.fromRGB(255,210, 60),

    BORDER        = Color3.fromRGB( 60, 45,110),
    BORDER_BRIGHT = Color3.fromRGB(120, 60,200),
    TOGGLE_ON     = Color3.fromRGB(  0,190,120),
    TOGGLE_OFF    = Color3.fromRGB( 50, 45, 75),
    SLIDER_BG     = Color3.fromRGB( 28, 22, 60),
    SLIDER_FILL   = Color3.fromRGB(160, 32,240),
}

local TI_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_SINE   = TweenInfo.new(1.20, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 4 - UTILIDADES UI
-- ═══════════════════════════════════════════════════════════════════════════════

-- FIX: Make ahora usa pcall en cada propiedad individualmente para evitar crashes
-- si una propiedad no existe en la versión del engine.
local function Make(class, props, parent)
    local ok, inst = pcall(Instance.new, class)
    if not ok or not inst then return nil end
    for k, v in pairs(props) do
        pcall(function() inst[k] = v end)
    end
    if parent then pcall(function() inst.Parent = parent end) end
    return inst
end

local function MakeFrame(p,par)  return Make("Frame",          p,par) end
local function MakeLabel(p,par)  return Make("TextLabel",      p,par) end
local function MakeButton(p,par) return Make("TextButton",     p,par) end
local function MakeBox(p,par)    return Make("TextBox",        p,par) end
local function MakeScroll(p,par) return Make("ScrollingFrame", p,par) end

-- FIX: Tween con guard para evitar crash si inst es nil
local function Tween(inst, info, props)
    if not inst or not inst.Parent then return end
    pcall(function() TweenService:Create(inst, info, props):Play() end)
end

local function Corner(r, parent)
    if not parent then return end
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
    return c
end

local function Stroke(thickness, color, parent)
    if not parent then return end
    local s = Instance.new("UIStroke")
    s.Thickness = thickness
    s.Color = color or C.BORDER
    s.Parent = parent
    return s
end

local function Padding(t, r, b, l, parent)
    if not parent then return end
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.Parent = parent
    return p
end

local function ListLayout(props, parent)
    if not parent then return end
    local l = Instance.new("UIListLayout")
    for k, v in pairs(props or {}) do pcall(function() l[k] = v end) end
    l.Parent = parent
    return l
end

local function TrackConn(conn)
    if conn then table.insert(ENV.QuantumOS_Connections, conn) end
    return conn
end

local function Gradient(c0, c1, rot, parent)
    if not parent then return end
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent   = parent
    return g
end

local function HoverGlow(btn, n, h)
    if not btn then return end
    btn.MouseEnter:Connect(function()  Tween(btn, TI_FAST, {BackgroundColor3 = h}) end)
    btn.MouseLeave:Connect(function()  Tween(btn, TI_FAST, {BackgroundColor3 = n}) end)
end

local function Typewriter(label, text, speed)
    if not label then return end
    speed = speed or 0.04
    label.Text = ""
    task.spawn(function()
        for i = 1, #text do
            if not label or not label.Parent then break end
            label.Text = string.sub(text, 1, i)
            task.wait(speed)
        end
    end)
end

local function PulseStroke(stroke, c1, c2)
    if not stroke then return end
    task.spawn(function()
        local dir = true
        while stroke and stroke.Parent do
            Tween(stroke, TI_SINE, {Color = dir and c2 or c1})
            task.wait(1.2)
            dir = not dir
        end
    end)
end

-- FIX: Helper para auto-resize de ScrollingFrame al cambiar contenido
local function AutoScrollSize(listLayout, scrollFrame, extraPad)
    extraPad = extraPad or 20
    if not listLayout or not scrollFrame then return end
    local function upd()
        if scrollFrame and scrollFrame.Parent then
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + extraPad)
        end
    end
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
    upd()
end

-- FIX: Helper para auto-resize de Frame hijo de lista
local function AutoListSize(listLayout, frame, extraPad)
    extraPad = extraPad or 8
    if not listLayout or not frame then return end
    local function upd()
        if frame and frame.Parent then
            frame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y + extraPad)
        end
    end
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)
    upd()
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 5 - RAÍZ DEL GUI
-- ═══════════════════════════════════════════════════════════════════════════════

local ScreenGui = Make("ScreenGui", {
    Name              = "QuantumOS_v31",
    ResetOnSpawn      = false,
    IgnoreGuiInset    = true,
    ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
    DisplayOrder      = 999,
}, PlayerGui)
ENV.QuantumOS_Instance = ScreenGui

local BG = MakeFrame({
    Name              = "Background",
    Size              = UDim2.fromScale(1, 1),
    BackgroundColor3  = C.BG_DEEP,
    BorderSizePixel   = 0,
    ZIndex            = 1,
}, ScreenGui)

Make("ImageLabel", {
    Size               = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image              = "rbxassetid://6370457276",
    ImageColor3        = C.PURPLE_NEON,
    ImageTransparency  = 0.94,
    ZIndex             = 2,
}, BG)

-- Partículas de fondo flotantes
local function SpawnBGParticles()
    for i = 1, 18 do
        local sz = math.random(2, 5)
        local px = MakeFrame({
            Size                  = UDim2.new(0, sz, 0, sz),
            Position              = UDim2.new(math.random() * 0.97, 0, math.random() * 0.97, 0),
            BackgroundColor3      = (i % 3 == 0) and C.PURPLE_NEON or (i % 3 == 1) and C.CYAN_NEON or C.PINK_NEON,
            BackgroundTransparency = 0.5,
            ZIndex                = 3,
        }, BG)
        if px then Corner(sz, px) end
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(3 + math.random() * 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position              = UDim2.new(math.random() * 0.96, 0, math.random() * 0.96, 0),
                    BackgroundTransparency = 0.1 + math.random() * 0.75,
                })
                task.wait(3 + math.random() * 4)
            end
        end)
    end
end
SpawnBGParticles()

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 6 - MULTI-AGENT AI SYSTEM (OpenRouter)
-- ═══════════════════════════════════════════════════════════════════════════════

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
    GAME_ANALYST   = {icon = "🎮", name = "Game Analyst",   color = Color3.fromRGB(255, 140,   0)},
    CODE_EXPERT    = {icon = "💻", name = "Code Expert",    color = Color3.fromRGB(  0, 220, 180)},
    STRATEGY_AGENT = {icon = "⚔",  name = "Strategy Agent", color = Color3.fromRGB(220,  50,  50)},
    CREATIVE_AGENT = {icon = "🎨", name = "Creative Agent", color = Color3.fromRGB(200, 100, 255)},
    FAST_AGENT     = {icon = "⚡", name = "Fast Agent",     color = Color3.fromRGB(255, 220,  60)},
}
AI.SYSTEM_PROMPTS = {
    ORCHESTRATOR   = "Eres el Orquestador de Quantum OS para Roblox. Analiza el mensaje y responde SOLO con JSON sin texto extra:\n{\"agent\":\"GAME_ANALYST|CODE_EXPERT|STRATEGY_AGENT|CREATIVE_AGENT|FAST_AGENT\",\"reason\":\"motivo\"}\nReglas: GAME_ANALYST=mecánicas/items/juego, CODE_EXPERT=scripts/Lua/errores, STRATEGY_AGENT=estrategias/builds, CREATIVE_AGENT=ideas/rol/personalización, FAST_AGENT=saludos/preguntas simples. Juego actual: " .. GAME_NAME,
    GAME_ANALYST   = "Eres un experto analista de '" .. GAME_NAME .. "' en Roblox. Da consejos precisos sobre mecánicas, items, bosses y mapas. Responde en español, máximo 130 palabras.",
    CODE_EXPERT    = "Eres un experto en Lua y scripting para Delta Executor en Roblox. Ayuda con scripts, errores y optimización. Responde en español con código bien comentado, máximo 160 palabras.",
    STRATEGY_AGENT = "Eres un estratega experto en '" .. GAME_NAME .. "'. Das estrategias óptimas, rutas de farm y guías paso a paso. Responde en español conciso, máximo 130 palabras.",
    CREATIVE_AGENT = "Eres un asistente creativo para Roblox. Ayudas con ideas de personalización, roleplay y builds creativos. Responde en español con entusiasmo, máximo 110 palabras.",
    FAST_AGENT     = "Eres el asistente rápido de Quantum OS para Roblox '" .. GAME_NAME .. "'. Responde breve y amigable en español, máximo 70 palabras.",
}

-- FIX: OR_Call mejorado con timeout implícito y mejor manejo de errores HTTP
local function OR_Call(model, sysPrompt, userMsg, maxTok)
    maxTok = maxTok or 300
    local key = ENV.QuantumOS_OpenRouterKey
    if not key or key == "" then return nil, "Sin API Key" end

    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({
            model       = model,
            max_tokens  = maxTok,
            messages    = {
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
                ["X-Title"]       = "LXNDXN Quantum OS v3.1",
            },
            Body = body,
        })
        -- FIX: Validar StatusCode antes de decodificar
        if resp.StatusCode ~= 200 then
            return nil, "HTTP Error " .. resp.StatusCode .. ": " .. tostring(resp.Body):sub(1, 80)
        end
        local data = HttpService:JSONDecode(resp.Body)
        -- FIX: Navegación segura por la respuesta
        if data and data.choices and data.choices[1] and
           data.choices[1].message and data.choices[1].message.content then
            return data.choices[1].message.content
        end
        return nil, "Respuesta vacía del servidor"
    end)

    if ok then
        -- result puede ser {nil, errMsg} o un string
        if type(result) == "table" then
            return result[1], result[2]
        end
        return result, nil
    else
        return nil, tostring(result)
    end
end

-- FIX: VerifyAPIKey más robusto — acepta cualquier respuesta no vacía como válida
local function VerifyAPIKey(key, callback)
    task.spawn(function()
        local old = ENV.QuantumOS_OpenRouterKey
        ENV.QuantumOS_OpenRouterKey = key
        local resp, err = OR_Call(
            AI.AGENTS.FAST_AGENT,
            "Eres un verificador. Responde SOLO la palabra: OK",
            "Verificación. Responde: OK",
            12
        )
        if resp and #tostring(resp) > 0 then
            callback(true, resp)
        else
            ENV.QuantumOS_OpenRouterKey = old
            callback(false, err or "Sin respuesta del servidor")
        end
    end)
end

-- FIX: OracleQuery con fallback seguro si el orquestador devuelve JSON inválido
local function OracleQuery(userMsg, onThink, onAgent, onResponse, onError)
    task.spawn(function()
        if onThink then onThink("Orquestador analizando consulta...") end

        local orchResp, _ = OR_Call(AI.ORCHESTRATOR, AI.SYSTEM_PROMPTS.ORCHESTRATOR, userMsg, 80)
        local agentKey = "FAST_AGENT"

        if orchResp then
            -- FIX: Intentar parsear JSON, ignorar basura extra que el modelo pueda añadir
            local cleanJson = orchResp:match("{.-}")
            if cleanJson then
                local ok, decoded = pcall(function() return HttpService:JSONDecode(cleanJson) end)
                if ok and decoded and decoded.agent and AI.AGENTS[decoded.agent] then
                    agentKey = decoded.agent
                end
            end
        end

        local meta = AI.AGENT_META[agentKey] or AI.AGENT_META.FAST_AGENT
        if onAgent then onAgent(agentKey, meta) end
        if onThink then onThink(meta.icon .. " " .. meta.name .. " procesando...") end

        local resp, err = OR_Call(
            AI.AGENTS[agentKey]        or AI.AGENTS.FAST_AGENT,
            AI.SYSTEM_PROMPTS[agentKey] or AI.SYSTEM_PROMPTS.FAST_AGENT,
            userMsg, 300
        )

        if resp and #tostring(resp) > 0 then
            if onResponse then onResponse(resp, meta) end
        else
            if onError then onError(err or "Error desconocido") end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 7 - BOOT SCREEN
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateBootScreen()
    local Boot = MakeFrame({Name = "BootScreen", Size = UDim2.fromScale(1,1),
        BackgroundColor3 = C.BG_DEEP, ZIndex = 100}, ScreenGui)
    Gradient(C.BG_DEEP, Color3.fromRGB(8, 4, 22), 135, Boot)

    local Center = MakeFrame({Size = UDim2.new(0,380,0,440), Position = UDim2.new(0.5,-190,0.5,-220),
        BackgroundColor3 = C.BG_GLASS, BackgroundTransparency = 0.3, ZIndex = 101}, Boot)
    Corner(32, Center)
    local cs = Stroke(2, C.PURPLE_NEON, Center)
    PulseStroke(cs, C.PURPLE_DIM, C.PURPLE_GLOW)

    for i = 1, 8 do
        local sz = math.random(2, 5)
        local px = MakeFrame({
            Size                  = UDim2.new(0, sz, 0, sz),
            Position              = UDim2.new(math.random() * 0.9, 0, math.random() * 0.9, 0),
            BackgroundColor3      = (i % 2 == 0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency = 0.3,
            ZIndex                = 102,
        }, Center)
        if px then Corner(2, px) end
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(2 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position              = UDim2.new(math.random() * 0.9, 0, math.random() * 0.9, 0),
                    BackgroundTransparency = 0.6,
                })
                task.wait(2 + math.random())
            end
        end)
    end

    local Logo = MakeLabel({Size = UDim2.new(1,0,0,90), Position = UDim2.new(0,0,0,24),
        BackgroundTransparency = 1, Text = "⬡", Font = Enum.Font.GothamBold,
        TextSize = 72, TextColor3 = C.PURPLE_NEON, ZIndex = 102}, Center)
    task.spawn(function()
        while Logo and Logo.Parent do
            Tween(Logo, TI_SINE, {TextColor3 = C.PURPLE_GLOW, TextTransparency = 0.1})
            task.wait(1.2)
            Tween(Logo, TI_SINE, {TextColor3 = C.PURPLE_NEON, TextTransparency = 0.0})
            task.wait(1.2)
        end
    end)

    MakeLabel({Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,0,120),
        BackgroundTransparency = 1, Text = "QUANTUM OS  v3.1", Font = Enum.Font.GothamBold,
        TextSize = 24, TextColor3 = C.TEXT_WHITE, ZIndex = 102}, Center)

    local Badge = MakeLabel({Size = UDim2.new(0,230,0,26), Position = UDim2.new(0.5,-115,0,155),
        BackgroundColor3 = C.PURPLE_DIM, BackgroundTransparency = 0.25,
        Text = "✦ DELTA EDITION · MULTI-AGENT AI ✦",
        Font = Enum.Font.GothamSemibold, TextSize = 11, TextColor3 = C.CYAN_NEON, ZIndex = 102}, Center)
    Corner(13, Badge)

    local WelcomeLabel = MakeLabel({Size = UDim2.new(1,-40,0,50), Position = UDim2.new(0,20,0,195),
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham,
        TextSize = 15, TextColor3 = C.TEXT_WHITE, TextWrapped = true, ZIndex = 102}, Center)
    local SubText = MakeLabel({Size = UDim2.new(1,-40,0,50), Position = UDim2.new(0,20,0,248),
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham,
        TextSize = 12, TextColor3 = C.TEXT_SOFT, TextWrapped = true, ZIndex = 102}, Center)

    local ProgressBG = MakeFrame({Size = UDim2.new(1,-40,0,6), Position = UDim2.new(0,20,0,330),
        BackgroundColor3 = C.SLIDER_BG, ZIndex = 102}, Center)
    Corner(3, ProgressBG)
    local ProgressFill = MakeFrame({Size = UDim2.new(0,0,1,0), BackgroundColor3 = C.PURPLE_NEON, ZIndex = 103}, ProgressBG)
    Corner(3, ProgressFill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, ProgressFill)

    local ProgressLabel = MakeLabel({Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,1,5),
        BackgroundTransparency = 1, Text = "Inicializando sistema...",
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.TEXT_MUTED, ZIndex = 102}, ProgressBG)
    MakeLabel({Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,1,-28),
        BackgroundTransparency = 1, Text = "LXNDXN · Delta Edition · Multi-Agent AI v3.1",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.TEXT_MUTED, ZIndex = 102}, Center)

    task.spawn(function()
        task.wait(0.5)
        Typewriter(WelcomeLabel, "Hola, " .. DISPLAY_NAME .. ". Iniciando Quantum OS v3.1...", 0.04)
        task.wait(1.8)
        Typewriter(SubText, "Sistema Multi-Agente AI activando...\nOrquestador · 5 Agentes Especializados listos.", 0.03)
        task.wait(1.4)
        local steps = {
            {0.12, "Cargando kernel del OS..."},
            {0.28, "Verificando Delta Executor..."},
            {0.44, "Inicializando sistema UI..."},
            {0.60, "Conectando Orquestador AI..."},
            {0.76, "Activando agentes especializados..."},
            {0.90, "Estableciendo sesión segura..."},
            {1.00, "Listo. Se requiere autenticación."},
        }
        for _, step in ipairs(steps) do
            Tween(ProgressFill, TI_MED, {Size = UDim2.new(step[1], 0, 1, 0)})
            if ProgressLabel and ProgressLabel.Parent then ProgressLabel.Text = step[2] end
            task.wait(0.40)
        end
        task.wait(0.5)
        Tween(Boot,   TI_SLOW, {BackgroundTransparency = 1})
        Tween(Center, TI_SLOW, {BackgroundTransparency = 1})
        task.wait(0.65)
        pcall(function() Boot:Destroy() end)
    end)

    return Boot
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 8 - SISTEMA DE NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

local NotifTypes = {
    INFO    = {icon = "ℹ", color = C.CYAN_NEON,  bg = Color3.fromRGB(0,28,48)},
    SUCCESS = {icon = "✓", color = C.TEXT_GREEN,  bg = Color3.fromRGB(0,38,18)},
    WARNING = {icon = "⚠", color = C.TEXT_YELLOW, bg = Color3.fromRGB(48,32,0)},
    ERROR   = {icon = "✕", color = C.TEXT_RED,    bg = Color3.fromRGB(58,0,0)},
    ORACLE  = {icon = "🔮",color = C.PURPLE_GLOW, bg = Color3.fromRGB(28,0,58)},
    SYSTEM  = {icon = "⬡", color = C.PURPLE_NEON, bg = Color3.fromRGB(18,4,42)},
    AI      = {icon = "🤖",color = C.GOLD_NEON,   bg = Color3.fromRGB(40,30,0)},
}
local notifStack = {}
local NOTIF_W = 295
local NOTIF_H = 70
local NOTIF_M = 8

local function PushNotification(title, body, typeName, duration)
    typeName = typeName or "INFO"
    duration = duration or 3.5
    local t = NotifTypes[typeName] or NotifTypes.INFO
    if #notifStack >= 4 then return end
    local slot = #notifStack + 1
    table.insert(notifStack, slot)
    local yOff = -(slot * (NOTIF_H + NOTIF_M))
    local NFrame = MakeFrame({
        Name             = "Notif_" .. slot,
        Size             = UDim2.new(0, NOTIF_W, 0, NOTIF_H),
        Position         = UDim2.new(1, 10, 1, yOff),
        BackgroundColor3 = t.bg,
        ZIndex           = 1100 + slot,
    }, ScreenGui)
    if not NFrame then return end
    Corner(14, NFrame); Stroke(1, t.color, NFrame)
    MakeFrame({Size = UDim2.new(0,4,1,-16), Position = UDim2.new(0,0,0,8),
        BackgroundColor3 = t.color, ZIndex = 1101 + slot}, NFrame)
    MakeLabel({Size = UDim2.new(0,38,1,0), BackgroundTransparency = 1, Text = t.icon, TextSize = 20,
        TextColor3 = t.color, ZIndex = 1102 + slot}, NFrame)
    MakeLabel({Size = UDim2.new(1,-60,0,22), Position = UDim2.new(0,52,0,8), BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1102 + slot}, NFrame)
    MakeLabel({Size = UDim2.new(1,-60,0,22), Position = UDim2.new(0,52,0,32), BackgroundTransparency = 1,
        Text = body, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.TEXT_SOFT, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1102 + slot}, NFrame)
    local PBG = MakeFrame({Size = UDim2.new(1,0,0,2), Position = UDim2.new(0,0,1,-2),
        BackgroundColor3 = C.SLIDER_BG, ZIndex = 1103 + slot}, NFrame)
    local PF = MakeFrame({Size = UDim2.new(1,0,1,0), BackgroundColor3 = t.color, ZIndex = 1104 + slot}, PBG)
    local ClN = MakeButton({Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-26,0,4),
        BackgroundTransparency = 1, Text = "✕", Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = C.TEXT_MUTED, ZIndex = 1105 + slot}, NFrame)
    Tween(NFrame, TI_BOUNCE, {Position = UDim2.new(1, -(NOTIF_W + 10), 1, yOff)})
    Tween(PF, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
    local function Dismiss()
        Tween(NFrame, TI_MED, {Position = UDim2.new(1, 10, 1, yOff)})
        task.wait(0.35)
        pcall(function()
            local idx = table.find(notifStack, slot)
            if idx then table.remove(notifStack, idx) end
            NFrame:Destroy()
        end)
    end
    if ClN then ClN.MouseButton1Click:Connect(Dismiss) end
    task.delay(duration, function() pcall(Dismiss) end)
end

local toastQueue  = {}
local toastActive = false
local function ShowToast(title, body, icon, dur)
    dur = dur or 3
    table.insert(toastQueue, {title = title, body = body, icon = icon or "⬡", dur = dur})
    if toastActive then return end
    toastActive = true
    task.spawn(function()
        while #toastQueue > 0 do
            local t = table.remove(toastQueue, 1)
            local T = MakeFrame({Size = UDim2.new(0,285,0,68), Position = UDim2.new(1,10,1,-85),
                BackgroundColor3 = C.BG_CARD, ZIndex = 1000}, ScreenGui)
            if T then
                Corner(14, T); Stroke(2, C.PURPLE_NEON, T)
                MakeLabel({Size = UDim2.new(0,40,1,0), BackgroundTransparency = 1,
                    Text = t.icon, TextSize = 22, ZIndex = 1001}, T)
                MakeLabel({Size = UDim2.new(1,-55,0,20), Position = UDim2.new(0,44,0,10),
                    BackgroundTransparency = 1, Text = t.title, Font = Enum.Font.GothamBold,
                    TextSize = 13, TextColor3 = C.TEXT_WHITE, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1001}, T)
                MakeLabel({Size = UDim2.new(1,-55,0,18), Position = UDim2.new(0,44,0,32),
                    BackgroundTransparency = 1, Text = t.body, Font = Enum.Font.Gotham,
                    TextSize = 11, TextColor3 = C.TEXT_SOFT, TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 1001}, T)
                Tween(T, TI_MED, {Position = UDim2.new(1,-295,1,-85)})
                task.wait(t.dur)
                Tween(T, TI_MED, {Position = UDim2.new(1,10,1,-85)})
                task.wait(0.4)
                pcall(function() T:Destroy() end)
            end
            task.wait(0.3)
        end
        toastActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 9 - LOGIN SCREEN (OpenRouter API Key)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateLoginScreen(onSuccess)
    local Login = MakeFrame({Name = "LoginScreen", Size = UDim2.fromScale(1,1),
        BackgroundColor3 = C.BG_DEEP, ZIndex = 90}, ScreenGui)
    Gradient(Color3.fromRGB(4,2,14), Color3.fromRGB(14,6,38), 135, Login)

    -- Scan lines
    local function SpawnScanLine()
        task.spawn(function()
            while Login and Login.Parent do
                local line = MakeFrame({Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,0),
                    BackgroundColor3 = C.PURPLE_NEON, BackgroundTransparency = 0.87, ZIndex = 91}, Login)
                Tween(line, TweenInfo.new(2.5 + math.random() * 2, Enum.EasingStyle.Linear),
                    {Position = UDim2.new(0,0,1,0)})
                task.wait(3 + math.random() * 3)
                pcall(function() line:Destroy() end)
            end
        end)
    end
    for i = 1, 4 do task.delay(i * 0.8, SpawnScanLine) end

    -- Partículas
    for i = 1, 22 do
        local sz = math.random(2, 6)
        local px = MakeFrame({Size = UDim2.new(0,sz,0,sz),
            Position = UDim2.new(math.random() * 0.97, 0, math.random() * 0.97, 0),
            BackgroundColor3 = (i % 3 == 0) and C.PURPLE_NEON or (i % 3 == 1) and C.CYAN_NEON or C.PINK_NEON,
            BackgroundTransparency = 0.4, ZIndex = 91}, Login)
        if px then Corner(sz, px) end
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(4 + math.random() * 5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(math.random() * 0.97, 0, math.random() * 0.97, 0),
                    BackgroundTransparency = 0.1 + math.random() * 0.8,
                })
                task.wait(4 + math.random() * 5)
            end
        end)
    end

    -- Hexágonos decorativos
    local hexPos = {{0.04,0.08},{0.88,0.04},{0.02,0.82},{0.90,0.86},{0.48,0.02},{0.5,0.95},{0.13,0.5},{0.84,0.5}}
    for _, pos in ipairs(hexPos) do
        local hl = MakeLabel({Size = UDim2.new(0,88,0,88), Position = UDim2.new(pos[1]-0.04,0,pos[2]-0.07,0),
            BackgroundTransparency = 1, Text = "⬡", Font = Enum.Font.GothamBold,
            TextSize = 78, TextColor3 = C.PURPLE_NEON, TextTransparency = 0.88, ZIndex = 91}, Login)
        task.spawn(function()
            local d = true
            while hl and hl.Parent do
                Tween(hl, TI_SINE, {TextTransparency = d and 0.93 or 0.82})
                task.wait(1.5 + math.random() * 2)
                d = not d
            end
        end)
    end

    -- Panel principal (adaptativo móvil)
    local Panel = MakeFrame({Name = "LoginPanel",
        Size     = UDim2.new(0.92, 0, 0.88, 0),
        Position = UDim2.new(0.04, 0, 0.06, 0),
        BackgroundColor3    = Color3.fromRGB(12,10,32),
        BackgroundTransparency = 0.12,
        ZIndex = 92}, Login)
    Corner(28, Panel)
    local panelS = Stroke(2, C.BORDER_BRIGHT, Panel)
    PulseStroke(panelS, C.PURPLE_DIM, C.PURPLE_GLOW)

    -- Scroll interior
    local PScroll = MakeScroll({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
        ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 93}, Panel)
    local PContent = MakeFrame({Size = UDim2.new(1,0,0,640), BackgroundTransparency = 1, ZIndex = 93}, PScroll)

    -- Logo
    local LogoFrame = MakeFrame({Size = UDim2.new(0,90,0,90), Position = UDim2.new(0.5,-45,0,22),
        BackgroundColor3 = C.PURPLE_DIM, BackgroundTransparency = 0.3, ZIndex = 94}, PContent)
    Corner(45, LogoFrame); Stroke(3, C.PURPLE_NEON, LogoFrame)
    Gradient(Color3.fromRGB(60,10,110), C.PURPLE_DIM, 135, LogoFrame)
    local LogoIcon = MakeLabel({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1,
        Text = "⬡", Font = Enum.Font.GothamBold, TextSize = 54, TextColor3 = C.PURPLE_NEON, ZIndex = 95}, LogoFrame)
    task.spawn(function()
        while LogoIcon and LogoIcon.Parent do
            Tween(LogoIcon, TI_SINE, {TextColor3 = C.CYAN_NEON}); task.wait(1.2)
            Tween(LogoIcon, TI_SINE, {TextColor3 = C.PURPLE_NEON}); task.wait(1.2)
        end
    end)

    MakeLabel({Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,122),
        BackgroundTransparency = 1, Text = "QUANTUM OS", Font = Enum.Font.GothamBold,
        TextSize = 30, TextColor3 = C.TEXT_WHITE, ZIndex = 94}, PContent)
    MakeLabel({Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,0,0,160),
        BackgroundTransparency = 1, Text = "Multi-Agent AI · Delta Edition · v3.1",
        Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = C.CYAN_NEON, ZIndex = 94}, PContent)

    -- Badges agentes
    local BadgeRow = MakeFrame({Size = UDim2.new(1,-40,0,28), Position = UDim2.new(0,20,0,186),
        BackgroundTransparency = 1, ZIndex = 94}, PContent)
    ListLayout({FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0,5)}, BadgeRow)
    for _, ab in ipairs({{"🎮","Game"},{"💻","Code"},{"⚔","Strat"},{"🎨","Create"},{"⚡","Fast"}}) do
        local B = MakeLabel({Size = UDim2.new(0,0,1,0), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(20,8,50), Text = ab[1].." "..ab[2],
            Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.TEXT_SOFT, ZIndex = 95}, BadgeRow)
        if B then Corner(10, B); Stroke(1, C.PURPLE_DIM, B); Padding(0,8,0,8,B) end
    end

    -- Separador
    MakeFrame({Size = UDim2.new(0.8,0,0,1), Position = UDim2.new(0.1,0,0,224),
        BackgroundColor3 = C.BORDER, ZIndex = 94}, PContent)

    -- Label API KEY
    MakeLabel({Size = UDim2.new(1,-40,0,18), Position = UDim2.new(0,20,0,236),
        BackgroundTransparency = 1, Text = "OPENROUTER API KEY", Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = C.PURPLE_GLOW, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 94}, PContent)

    -- TextBox API Key
    local KeyBox = MakeBox({Size = UDim2.new(1,-40,0,52), Position = UDim2.new(0,20,0,258),
        BackgroundColor3 = Color3.fromRGB(10,8,28), BorderSizePixel = 0,
        Text = "", PlaceholderText = "sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxx",
        Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED, ClearTextOnFocus = false, ZIndex = 95}, PContent)
    Corner(12, KeyBox)
    local kbs = Stroke(2, C.BORDER, KeyBox)
    Padding(0,16,0,16, KeyBox)
    KeyBox.Focused:Connect(function()   Tween(kbs, TI_FAST, {Color = C.PURPLE_NEON}) end)
    KeyBox.FocusLost:Connect(function() Tween(kbs, TI_FAST, {Color = C.BORDER})      end)

    -- Status label
    local StatusLabel = MakeLabel({Size = UDim2.new(1,-40,0,26), Position = UDim2.new(0,20,0,318),
        BackgroundTransparency = 1, Text = "", Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = C.TEXT_MUTED, TextWrapped = true, ZIndex = 94}, PContent)

    -- Spinner
    local Spinner = MakeLabel({Size = UDim2.new(0,32,0,32), Position = UDim2.new(0.5,-16,0,330),
        BackgroundTransparency = 1, Text = "◌", Font = Enum.Font.GothamBold,
        TextSize = 26, TextColor3 = C.CYAN_NEON, Visible = false, ZIndex = 96}, PContent)

    -- Botón VERIFICAR API
    local LoginBtn = MakeButton({Size = UDim2.new(1,-40,0,52), Position = UDim2.new(0,20,0,350),
        BackgroundColor3 = C.PURPLE_NEON, BorderSizePixel = 0,
        Text = "⚡  VERIFICAR API KEY", Font = Enum.Font.GothamBold,
        TextSize = 16, TextColor3 = Color3.new(1,1,1), ZIndex = 95}, PContent)
    Corner(14, LoginBtn)
    Gradient(Color3.fromRGB(130,20,210), Color3.fromRGB(70,0,170), 135, LoginBtn)
    HoverGlow(LoginBtn, C.PURPLE_NEON, C.PURPLE_GLOW)

    -- Separador 2
    MakeFrame({Size = UDim2.new(0.7,0,0,1), Position = UDim2.new(0.15,0,0,414),
        BackgroundColor3 = C.BORDER, ZIndex = 94}, PContent)

    -- Botón OBTENER KEY
    local GetKeyBtn = MakeButton({Size = UDim2.new(1,-40,0,44), Position = UDim2.new(0,20,0,422),
        BackgroundColor3 = Color3.fromRGB(12,10,32), BorderSizePixel = 0,
        Text = "🔑  Obtener API Key → openrouter.ai/keys",
        Font = Enum.Font.GothamSemibold, TextSize = 13, TextColor3 = C.CYAN_NEON, ZIndex = 95}, PContent)
    Corner(12, GetKeyBtn); Stroke(1, C.CYAN_DIM, GetKeyBtn)
    HoverGlow(GetKeyBtn, Color3.fromRGB(12,10,32), Color3.fromRGB(0,28,48))
    GetKeyBtn.MouseButton1Click:Connect(function()
        -- FIX: setclipboard puede no existir en todos los executors → pcall
        local copied = pcall(function() setclipboard("https://openrouter.ai/keys") end)
        StatusLabel.Text = copied and "💡 Link copiado: openrouter.ai/keys — Pega en tu navegador"
            or "🌐 Ve a: openrouter.ai/keys"
        StatusLabel.TextColor3 = C.CYAN_NEON
    end)

    MakeLabel({Size = UDim2.new(1,-40,0,16), Position = UDim2.new(0,20,0,476),
        BackgroundTransparency = 1, Text = "🔒 Tu key solo se usa para llamadas de IA · No se almacena",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.TEXT_MUTED, ZIndex = 94}, PContent)

    MakeLabel({Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,0,610),
        BackgroundTransparency = 1, Text = "LXNDXN Quantum OS  ·  Delta Edition  ·  v3.1  ·  Multi-Agent AI",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.TEXT_MUTED, ZIndex = 94}, PContent)

    -- Lógica de verificación
    local function DoVerify()
        local key = KeyBox.Text:gsub("%s+", "")
        if key == "" then
            StatusLabel.Text = "⚠ Introduce tu API Key de OpenRouter."
            StatusLabel.TextColor3 = C.TEXT_YELLOW
            Tween(KeyBox, TI_FAST, {BackgroundColor3 = Color3.fromRGB(30,14,8)})
            task.wait(0.7)
            Tween(KeyBox, TI_FAST, {BackgroundColor3 = Color3.fromRGB(10,8,28)})
            return
        end
        LoginBtn.Visible = false
        Spinner.Visible  = true
        StatusLabel.Text = "Verificando con OpenRouter AI..."
        StatusLabel.TextColor3 = C.CYAN_NEON
        local spinOK = true
        task.spawn(function()
            local icons = {"◌","◍","◎","●","◎","◍"}
            local i = 1
            while spinOK do
                if Spinner and Spinner.Parent then Spinner.Text = icons[i] end
                i = i % #icons + 1
                task.wait(0.1)
            end
        end)
        VerifyAPIKey(key, function(success, resp)
            spinOK = false
            if Spinner and Spinner.Parent then Spinner.Visible = false end
            if LoginBtn and LoginBtn.Parent then LoginBtn.Visible = true end
            if success then
                ENV.QuantumOS_OpenRouterKey = key
                StatusLabel.Text = "✓ API Key verificada · Conexión establecida"
                StatusLabel.TextColor3 = C.TEXT_GREEN
                Tween(LoginBtn, TI_FAST, {BackgroundColor3 = C.TOGGLE_ON})
                if LoginBtn and LoginBtn.Parent then LoginBtn.Text = "✓  CONECTADO" end
                task.wait(1.0)
                Tween(Login, TI_MED, {BackgroundTransparency = 1})
                task.wait(0.4)
                pcall(function() Login:Destroy() end)
                onSuccess()
            else
                StatusLabel.Text = "✗ API Key inválida. Verifica en openrouter.ai/keys\n" .. tostring(resp or "")
                StatusLabel.TextColor3 = C.TEXT_RED
                -- Shake de panel
                local origPos = Panel.Position
                for _ = 1, 5 do
                    Tween(Panel, TI_FAST, {Position = UDim2.new(origPos.X.Scale - 0.005, 0, origPos.Y.Scale, 0)})
                    task.wait(0.06)
                    Tween(Panel, TI_FAST, {Position = UDim2.new(origPos.X.Scale + 0.005, 0, origPos.Y.Scale, 0)})
                    task.wait(0.06)
                end
                Tween(Panel, TI_FAST, {Position = origPos})
            end
        end)
    end

    LoginBtn.MouseButton1Click:Connect(DoVerify)
    KeyBox.FocusLost:Connect(function(enter) if enter then DoVerify() end end)
    return Login
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 10 - DEVICE SELECTION SCREEN
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateDeviceSelectionScreen(onSelect)
    local DS = MakeFrame({Name = "DeviceSelect", Size = UDim2.fromScale(1,1),
        BackgroundColor3 = C.BG_DEEP, ZIndex = 90}, ScreenGui)
    Gradient(Color3.fromRGB(4,2,14), Color3.fromRGB(10,4,30), 135, DS)

    for i = 1, 14 do
        local sz = math.random(2, 5)
        local px = MakeFrame({Size = UDim2.new(0,sz,0,sz),
            Position = UDim2.new(math.random() * 0.97, 0, math.random() * 0.97, 0),
            BackgroundColor3 = (i % 2 == 0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency = 0.5, ZIndex = 91}, DS)
        if px then Corner(sz, px) end
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(3 + math.random() * 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(math.random() * 0.97, 0, math.random() * 0.97, 0),
                    BackgroundTransparency = 0.1 + math.random() * 0.8,
                })
                task.wait(3 + math.random() * 4)
            end
        end)
    end

    local DPanel = MakeFrame({Size = UDim2.new(0,480,0,480), Position = UDim2.new(0.5,-240,0.5,-240),
        BackgroundColor3 = Color3.fromRGB(12,10,32), BackgroundTransparency = 0.1, ZIndex = 92}, DS)
    Corner(30, DPanel)
    local dps = Stroke(2, C.PURPLE_NEON, DPanel)
    PulseStroke(dps, C.PURPLE_DIM, C.PURPLE_GLOW)
    DPanel.Position = UDim2.new(0.5,-240,1.2,0)
    Tween(DPanel, TI_BOUNCE, {Position = UDim2.new(0.5,-240,0.5,-240)})

    -- Check icon
    local ChkFrame = MakeFrame({Size = UDim2.new(0,68,0,68), Position = UDim2.new(0.5,-34,0,22),
        BackgroundColor3 = Color3.fromRGB(0,40,20), BackgroundTransparency = 0.2, ZIndex = 93}, DPanel)
    Corner(34, ChkFrame); Stroke(2, C.TEXT_GREEN, ChkFrame)
    MakeLabel({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "✓",
        Font = Enum.Font.GothamBold, TextSize = 38, TextColor3 = C.TEXT_GREEN, ZIndex = 94}, ChkFrame)

    MakeLabel({Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,102),
        BackgroundTransparency = 1, Text = "✓  Conexión Establecida", Font = Enum.Font.GothamBold,
        TextSize = 22, TextColor3 = C.TEXT_GREEN, ZIndex = 93}, DPanel)
    MakeLabel({Size = UDim2.new(1,-40,0,18), Position = UDim2.new(0,20,0,138),
        BackgroundTransparency = 1, Text = "OpenRouter Multi-Agent AI conectado correctamente",
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.TEXT_SOFT, ZIndex = 93}, DPanel)

    MakeFrame({Size = UDim2.new(0.8,0,0,1), Position = UDim2.new(0.1,0,0,168),
        BackgroundColor3 = C.BORDER, ZIndex = 93}, DPanel)
    MakeLabel({Size = UDim2.new(1,0,0,22), Position = UDim2.new(0,0,0,178),
        BackgroundTransparency = 1, Text = "SELECCIONA TU DISPOSITIVO", Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = C.PURPLE_GLOW, ZIndex = 93}, DPanel)

    -- Botón MÓVIL
    local MobileBtn = MakeButton({Size = UDim2.new(1,-40,0,96), Position = UDim2.new(0,20,0,208),
        BackgroundColor3 = Color3.fromRGB(14,10,38), BorderSizePixel = 0, Text = "", ZIndex = 93}, DPanel)
    Corner(18, MobileBtn); Stroke(2, C.PURPLE_DIM, MobileBtn)
    local MobIcon = MakeFrame({Size = UDim2.new(0,60,0,60), Position = UDim2.new(0,16,0.5,-30),
        BackgroundColor3 = C.PURPLE_DIM, BackgroundTransparency = 0.3, ZIndex = 94}, MobileBtn)
    Corner(14, MobIcon)
    MakeLabel({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "📱", TextSize = 30, ZIndex = 95}, MobIcon)
    MakeLabel({Size = UDim2.new(1,-100,0,30), Position = UDim2.new(0,86,0,16), BackgroundTransparency = 1,
        Text = "📱  MÓVIL", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 94}, MobileBtn)
    MakeLabel({Size = UDim2.new(1,-100,0,20), Position = UDim2.new(0,86,0,50), BackgroundTransparency = 1,
        Text = "UI táctil · Botones grandes · Panel optimizado",
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.TEXT_MUTED,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 94}, MobileBtn)
    HoverGlow(MobileBtn, Color3.fromRGB(14,10,38), Color3.fromRGB(40,15,90))

    -- Botón PC
    local PCBtn = MakeButton({Size = UDim2.new(1,-40,0,96), Position = UDim2.new(0,20,0,316),
        BackgroundColor3 = Color3.fromRGB(14,10,38), BorderSizePixel = 0, Text = "", ZIndex = 93}, DPanel)
    Corner(18, PCBtn); Stroke(2, C.CYAN_DIM, PCBtn)
    local PCIcon = MakeFrame({Size = UDim2.new(0,60,0,60), Position = UDim2.new(0,16,0.5,-30),
        BackgroundColor3 = C.CYAN_DIM, BackgroundTransparency = 0.5, ZIndex = 94}, PCBtn)
    Corner(14, PCIcon)
    MakeLabel({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "🖥", TextSize = 30, ZIndex = 95}, PCIcon)
    MakeLabel({Size = UDim2.new(1,-100,0,30), Position = UDim2.new(0,86,0,16), BackgroundTransparency = 1,
        Text = "🖥  PC / ESCRITORIO", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 94}, PCBtn)
    MakeLabel({Size = UDim2.new(1,-100,0,20), Position = UDim2.new(0,86,0,50), BackgroundTransparency = 1,
        Text = "UI completa · Sidebar · Atajos F1–F8 · Keybinds",
        Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.TEXT_MUTED,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 94}, PCBtn)
    HoverGlow(PCBtn, Color3.fromRGB(14,10,38), Color3.fromRGB(0,28,48))

    MakeLabel({Size = UDim2.new(1,0,0,16), Position = UDim2.new(0,0,1,-20),
        BackgroundTransparency = 1, Text = "Puedes cambiarlo más tarde en Ajustes del Sistema",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.TEXT_MUTED, ZIndex = 92}, DPanel)

    local function SelectDevice(mode)
        ENV.QuantumOS_DeviceMode = mode
        ENV.QuantumOS_Unlocked   = true
        Tween(DS, TI_MED, {BackgroundTransparency = 1})
        task.wait(0.4)
        pcall(function() DS:Destroy() end)
        onSelect(mode)
    end
    MobileBtn.MouseButton1Click:Connect(function() SelectDevice("mobile") end)
    PCBtn.MouseButton1Click:Connect(function()     SelectDevice("pc")     end)
    return DS
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 11 - VENTANA PRINCIPAL DEL OS
-- ═══════════════════════════════════════════════════════════════════════════════

local MainWindow      = nil
local Sidebar         = nil
local ContentArea     = nil
local CurrentTabFrame = nil
local SidebarButtons  = {}

local function ClearContent()
    if CurrentTabFrame and CurrentTabFrame.Parent then
        pcall(function() CurrentTabFrame:Destroy() end)
    end
    CurrentTabFrame = nil
end

local function SetActiveTab(name)
    for tabName, btn in pairs(SidebarButtons) do
        if btn and btn.Parent then
            local active = (tabName == name)
            Tween(btn, TI_FAST, {
                BackgroundColor3      = active and C.PURPLE_DIM or Color3.fromRGB(0,0,0),
                BackgroundTransparency = active and 0 or 1,
            })
            local ind = btn:FindFirstChild("Indicator")
            if ind then ind.Visible = active end
        end
    end
end

local function SectionHeader(parent, title, subtitle)
    local H = MakeFrame({Size = UDim2.new(1,0,0,62), BackgroundColor3 = C.BG_HEADER, ZIndex = 19}, parent)
    if not H then return end
    Stroke(1, C.BORDER, H)
    local AL = MakeFrame({Size = UDim2.new(0,3,0,38), Position = UDim2.new(0,8,0,12),
        BackgroundColor3 = C.PURPLE_NEON, ZIndex = 20}, H)
    if AL then Corner(2, AL) end
    MakeLabel({Size = UDim2.new(1,-24,0,28), Position = UDim2.new(0,20,0,8),
        BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold,
        TextSize = 18, TextColor3 = C.TEXT_WHITE, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 20}, H)
    if subtitle then
        MakeLabel({Size = UDim2.new(1,-24,0,16), Position = UDim2.new(0,20,0,38),
            BackgroundTransparency = 1, Text = subtitle, Font = Enum.Font.Gotham,
            TextSize = 12, TextColor3 = C.TEXT_MUTED, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 20}, H)
    end
    return H
end

local function CreateToggle(parent, label, defaultState, onChange)
    local Row = MakeFrame({Size = UDim2.new(1,0,0,42), BackgroundColor3 = C.BG_CARD, ZIndex = 20}, parent)
    if not Row then return nil, function() return defaultState end end
    Corner(10, Row)
    MakeLabel({Size = UDim2.new(1,-70,1,0), Position = UDim2.new(0,14,0,0), BackgroundTransparency = 1,
        Text = label, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21}, Row)
    local Track = MakeFrame({Size = UDim2.new(0,46,0,24), Position = UDim2.new(1,-58,0.5,-12),
        BackgroundColor3 = defaultState and C.TOGGLE_ON or C.TOGGLE_OFF, ZIndex = 21}, Row)
    Corner(12, Track)
    local Thumb = MakeFrame({Size = UDim2.new(0,18,0,18),
        Position = defaultState and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3 = Color3.new(1,1,1), ZIndex = 22}, Track)
    Corner(9, Thumb)
    local state = defaultState
    local TB = MakeButton({Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "", ZIndex = 23}, Track)
    if TB then
        TB.MouseButton1Click:Connect(function()
            state = not state
            Tween(Track, TI_FAST, {BackgroundColor3 = state and C.TOGGLE_ON or C.TOGGLE_OFF})
            Tween(Thumb, TI_FAST, {Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
            if onChange then onChange(state) end
        end)
    end
    return Row, function() return state end
end

local function CreateSlider(parent, label, minV, maxV, defV, suffix, onChange)
    local Row = MakeFrame({Size = UDim2.new(1,0,0,60), BackgroundColor3 = C.BG_CARD, ZIndex = 20}, parent)
    if not Row then return nil end
    Corner(10, Row)
    MakeLabel({Size = UDim2.new(1,-60,0,22), Position = UDim2.new(0,14,0,6), BackgroundTransparency = 1,
        Text = label, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 21}, Row)
    local VL = MakeLabel({Size = UDim2.new(0,55,0,22), Position = UDim2.new(1,-65,0,6), BackgroundTransparency = 1,
        Text = tostring(defV) .. (suffix or ""), Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = C.PURPLE_GLOW, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 21}, Row)
    local TRK = MakeFrame({Size = UDim2.new(1,-28,0,6), Position = UDim2.new(0,14,0,40),
        BackgroundColor3 = C.SLIDER_BG, ZIndex = 21}, Row)
    Corner(3, TRK)
    local ratio = (defV - minV) / math.max(maxV - minV, 1)
    local Fill = MakeFrame({Size = UDim2.new(ratio,0,1,0), BackgroundColor3 = C.SLIDER_FILL, ZIndex = 22}, TRK)
    Corner(3, Fill); Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, Fill)
    local Knob = MakeFrame({Size = UDim2.new(0,16,0,16), Position = UDim2.new(ratio,-8,0.5,-8),
        BackgroundColor3 = Color3.new(1,1,1), ZIndex = 23}, TRK)
    Corner(8, Knob); Stroke(2, C.PURPLE_NEON, Knob)
    local dragging = false
    local function UpdSlider(inputX)
        if not TRK or not TRK.Parent then return end
        local t = math.clamp((inputX - TRK.AbsolutePosition.X) / math.max(TRK.AbsoluteSize.X, 1), 0, 1)
        local value = math.floor(minV + t * (maxV - minV))
        Tween(Fill, TI_FAST, {Size = UDim2.new(t,0,1,0)})
        Tween(Knob, TI_FAST, {Position = UDim2.new(t,-8,0.5,-8)})
        if VL and VL.Parent then VL.Text = tostring(value) .. (suffix or "") end
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

local function CreateMainWindow()
    MainWindow = MakeFrame({Name = "MainWindow", Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, ZIndex = 10}, ScreenGui)

    -- HEADER
    local Header = MakeFrame({Name = "Header", Size = UDim2.new(1,0,0,56),
        BackgroundColor3 = C.BG_HEADER, ZIndex = 12}, MainWindow)
    Stroke(1, C.BORDER, Header)
    Gradient(C.BG_HEADER, Color3.fromRGB(8,6,20), 90, Header)

    local HLogo = MakeLabel({Size = UDim2.new(0,38,0,38), Position = UDim2.new(0,14,0.5,-19),
        BackgroundTransparency = 1, Text = "⬡", Font = Enum.Font.GothamBold,
        TextSize = 32, TextColor3 = C.PURPLE_NEON, ZIndex = 13}, Header)
    task.spawn(function()
        while HLogo and HLogo.Parent do
            Tween(HLogo, TI_SINE, {TextColor3 = C.CYAN_NEON}); task.wait(1.5)
            Tween(HLogo, TI_SINE, {TextColor3 = C.PURPLE_NEON}); task.wait(1.5)
        end
    end)
    MakeLabel({Size = UDim2.new(0,200,0,22), Position = UDim2.new(0,56,0,8), BackgroundTransparency = 1,
        Text = "QUANTUM OS  v3.1", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13}, Header)
    MakeLabel({Size = UDim2.new(0,200,0,16), Position = UDim2.new(0,56,0,30), BackgroundTransparency = 1,
        Text = "Multi-Agent AI · Delta Executor", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13}, Header)

    local GameBadge = MakeLabel({Size = UDim2.new(0,220,0,30), Position = UDim2.new(0.5,-110,0.5,-15),
        BackgroundColor3 = C.BG_CARD, Text = "🎮  " .. GAME_NAME:sub(1,20),
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.TEXT_SOFT, ZIndex = 13}, Header)
    if GameBadge then Corner(15, GameBadge); Stroke(1, C.BORDER, GameBadge) end

    local SysF = MakeFrame({Size = UDim2.new(0,148,0,40), Position = UDim2.new(1,-158,0.5,-20),
        BackgroundTransparency = 1, ZIndex = 13}, Header)
    local function SysBtn(icon, color, xOff)
        local b = MakeButton({Size = UDim2.new(0,34,0,34), Position = UDim2.new(0,xOff,0.5,-17),
            BackgroundColor3 = Color3.fromRGB(18,15,38), Text = icon,
            Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = color, ZIndex = 14}, SysF)
        if b then Corner(10, b); HoverGlow(b, Color3.fromRGB(18,15,38), Color3.fromRGB(38,28,68)) end
        return b
    end
    local WifiBtn  = SysBtn("⚡", C.TEXT_GREEN,   0)
    local NotifBtn = SysBtn("🔔", C.TEXT_YELLOW,  38)
    local MinBtn   = SysBtn("—",  C.TEXT_SOFT,    76)
    local CloseBtn = SysBtn("✕",  C.TEXT_RED,    114)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow, TI_MED, {Size = UDim2.new(0,0,0,0)})
        task.wait(0.35)
        pcall(function() ScreenGui:Destroy() end)
    end)
    MinBtn.MouseButton1Click:Connect(function()
        -- FIX: toggle minimize por altura (escalar)
        local isMin = MainWindow.Size.Y.Scale < 0.1
        Tween(MainWindow, TI_MED, {Size = isMin and UDim2.fromScale(1,1) or UDim2.new(1,0,0,56)})
    end)

    -- SIDEBAR
    Sidebar = MakeFrame({Name = "Sidebar", Size = UDim2.new(0,210,1,-56), Position = UDim2.new(0,0,0,56),
        BackgroundColor3 = C.BG_SIDEBAR, ZIndex = 11}, MainWindow)
    Stroke(1, C.BORDER, Sidebar)

    -- Perfil usuario
    local SbP = MakeFrame({Size = UDim2.new(1,-16,0,72), Position = UDim2.new(0,8,0,10),
        BackgroundColor3 = C.BG_CARD, ZIndex = 12}, Sidebar)
    Corner(14, SbP); Stroke(1, C.PURPLE_DIM, SbP)
    Gradient(C.BG_CARD, Color3.fromRGB(20,10,50), 135, SbP)
    local Av = MakeLabel({Size = UDim2.new(0,46,0,46), Position = UDim2.new(0,10,0.5,-23),
        BackgroundColor3 = C.PURPLE_DIM, Text = string.upper(string.sub(DISPLAY_NAME,1,2)),
        Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.TEXT_WHITE, ZIndex = 13}, SbP)
    if Av then Corner(23, Av); Stroke(2, C.PURPLE_NEON, Av) end
    MakeLabel({Size = UDim2.new(1,-66,0,20), Position = UDim2.new(0,64,0,12), BackgroundTransparency = 1,
        Text = DISPLAY_NAME, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13}, SbP)
    MakeLabel({Size = UDim2.new(1,-66,0,16), Position = UDim2.new(0,64,0,32), BackgroundTransparency = 1,
        Text = "@" .. USERNAME, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.CYAN_NEON,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13}, SbP)
    local OnB = MakeLabel({Size = UDim2.new(0,72,0,16), Position = UDim2.new(0,64,0,50),
        BackgroundColor3 = Color3.fromRGB(0,50,25), Text = "● AI Online",
        Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.TEXT_GREEN, ZIndex = 13}, SbP)
    if OnB then Corner(8, OnB) end

    -- Tabs
    local SbScroll = MakeScroll({Size = UDim2.new(1,0,1,-94), Position = UDim2.new(0,0,0,92),
        BackgroundTransparency = 1, ScrollBarThickness = 0, ZIndex = 12}, Sidebar)
    local SbList = MakeFrame({Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, ZIndex = 12}, SbScroll)
    local sbLL = ListLayout({Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder}, SbList)

    local TABS = {
        {name = "START",            icon = "⌂",  order = 1},
        {name = "SCRIPT HUB",       icon = "⚡",  order = 2},
        {name = "SYSTEM SETTINGS",  icon = "⚙",  order = 3},
        {name = "TOOLBOX",          icon = "🛠",  order = 4},
        {name = "FILE MANAGER",     icon = "📁",  order = 5},
        {name = "PROCESSES & LOGS", icon = "📊",  order = 6},
        {name = "MEDIA CENTER",     icon = "🎵",  order = 7},
        {name = "COMMUNITY",        icon = "👥",  order = 8},
        {name = "QUANTUM ORACLE",   icon = "🔮",  order = 9},
        {name = "GAME BOOSTER",     icon = "🚀",  order = 10},
        {name = "SKIN CUSTOMIZER",  icon = "🎨",  order = 11},
        {name = "POWER",            icon = "⏻",   order = 12},
    }

    for _, tab in ipairs(TABS) do
        local Btn = MakeButton({Name = tab.name, Size = UDim2.new(1,-12,0,42),
            BackgroundColor3 = Color3.fromRGB(0,0,0), BackgroundTransparency = 1,
            Text = "", LayoutOrder = tab.order, ZIndex = 13}, SbList)
        if not Btn then continue end
        Corner(10, Btn); Padding(0,8,0,8, Btn)
        local Ind = MakeFrame({Name = "Indicator", Size = UDim2.new(0,3,0.6,0), Position = UDim2.new(0,0,0.2,0),
            BackgroundColor3 = C.PURPLE_NEON, Visible = false, ZIndex = 14}, Btn)
        if Ind then Corner(2, Ind) end
        MakeLabel({Size = UDim2.new(0,28,1,0), Position = UDim2.new(0,12,0,0), BackgroundTransparency = 1,
            Text = tab.icon, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.TEXT_SOFT, ZIndex = 14}, Btn)
        MakeLabel({Size = UDim2.new(1,-46,1,0), Position = UDim2.new(0,44,0,0), BackgroundTransparency = 1,
            Text = tab.name, Font = Enum.Font.GothamSemibold, TextSize = 12, TextColor3 = C.TEXT_SOFT,
            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14}, Btn)
        SidebarButtons[tab.name] = Btn
        Btn.MouseButton1Click:Connect(function()
            ClearContent(); SetActiveTab(tab.name); ENV.QuantumOS_ActiveTab = tab.name
            -- FIX: clave de función más limpia y consistente
            local fnKey = "QOS_Tab_" .. tab.name:gsub("[^%w]", "_"):gsub("_+", "_"):gsub("_$", "")
            if _G[fnKey] then
                pcall(_G[fnKey])
            else
                -- FIX: Mostrar mensaje si tab no tiene función implementada
                local ph = MakeFrame({Name="Tab_Placeholder", Size=UDim2.fromScale(1,1),
                    BackgroundTransparency=1, ZIndex=15}, ContentArea)
                CurrentTabFrame = ph
                MakeLabel({Size=UDim2.new(1,0,0,40), Position=UDim2.new(0,0,0.4,0),
                    BackgroundTransparency=1, Text="🚧 " .. tab.name .. " — Próximamente",
                    Font=Enum.Font.GothamBold, TextSize=18, TextColor3=C.TEXT_MUTED, ZIndex=16}, ph)
            end
        end)
        HoverGlow(Btn, Color3.fromRGB(0,0,0), C.BG_GLASS)
    end

    -- FIX: usar helper para auto-resize del sidebar scroll
    if sbLL then AutoListSize(sbLL, SbList, 8) end
    if sbLL and SbScroll then AutoScrollSize(sbLL, SbScroll, 8) end

    -- CONTENT AREA
    ContentArea = MakeFrame({Name = "ContentArea", Size = UDim2.new(1,-210,1,-56),
        Position = UDim2.new(0,210,0,56), BackgroundColor3 = C.BG_PANEL, ZIndex = 11}, MainWindow)

    -- Animación de entrada
    MainWindow.Size     = UDim2.new(0,0,0,0)
    MainWindow.Position = UDim2.new(0.5,0,0.5,0)
    Tween(MainWindow, TI_BOUNCE, {Size = UDim2.fromScale(1,1), Position = UDim2.fromScale(0,0)})
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 12 - TAB: START
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_START"] = function()
    local Tab = MakeFrame({Name="Tab_START", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    local Scroll = MakeScroll({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local List   = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    local LL = ListLayout({Padding=UDim.new(0,0)}, List)
    Padding(0,0,20,0, List)
    SectionHeader(List, "START  ⌂", "Panel de inicio · Quantum OS v3.1 · Multi-Agent AI")

    -- Stats cards
    local StatsRow = MakeFrame({Size=UDim2.new(1,0,0,96), BackgroundTransparency=1, ZIndex=15}, List)
    local SGrid = MakeFrame({Size=UDim2.new(1,-32,1,-16), Position=UDim2.new(0,16,0,8), BackgroundTransparency=1, ZIndex=15}, StatsRow)
    Make("UIGridLayout", {CellSize=UDim2.new(0.25,-4,1,-4), CellPadding=UDim2.new(0,4,0,4)}, SGrid)
    local statsItems = {
        {label="Jugador",   val=DISPLAY_NAME:sub(1,14), icon="👤", color=C.PURPLE_GLOW},
        {label="Juego",     val=GAME_NAME:sub(1,14),    icon="🎮", color=C.CYAN_NEON},
        {label="AI Status", val="Online",                icon="🤖", color=C.TEXT_GREEN},
        {label="Agentes",   val="5 activos",             icon="⬡",  color=C.GOLD_NEON},
    }
    for _, s in ipairs(statsItems) do
        local Card = MakeFrame({BackgroundColor3=C.BG_CARD, ZIndex=16}, SGrid)
        if Card then Corner(12, Card); Stroke(1, C.BORDER, Card) end
        MakeLabel({Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,8), BackgroundTransparency=1,
            Text=s.icon, TextSize=22, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,20), Position=UDim2.new(0,4,0,36), BackgroundTransparency=1,
            Text=s.val, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=s.color, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,14), Position=UDim2.new(0,4,0,57), BackgroundTransparency=1,
            Text=s.label, Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED, ZIndex=17}, Card)
    end

    MakeLabel({Size=UDim2.new(1,-32,0,22), BackgroundTransparency=1,
        Text="SISTEMA MULTI-AGENTE ACTIVO", Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=C.PURPLE_GLOW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=15}, List)
    local AgList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, List)
    ListLayout({Padding=UDim.new(0,4)}, AgList); Padding(0,16,0,16, AgList)

    local agents = {
        {icon="⬡", name="Orquestador",     model="llama-3.3-70b",  desc="Dirige el flujo multi-agente · Toma decisiones"},
        {icon="🎮", name="Game Analyst",    model="nemotron-120b",  desc="Análisis de mecánicas y juego actual"},
        {icon="💻", name="Code Expert",     model="qwen3-coder",    desc="Scripts Lua y errores de Delta Executor"},
        {icon="⚔",  name="Strategy Agent", model="deepseek-v4",    desc="Estrategias óptimas y builds"},
        {icon="🎨", name="Creative Agent",  model="gemma-4-31b",    desc="Ideas de personalización y creatividad"},
        {icon="⚡", name="Fast Agent",      model="llama-3.2-3b",   desc="Respuestas rápidas y saludos"},
    }
    for _, ag in ipairs(agents) do
        local AC = MakeFrame({Size=UDim2.new(1,0,0,50), BackgroundColor3=C.BG_CARD, ZIndex=16}, AgList)
        if AC then Corner(10, AC); Stroke(1, C.BORDER, AC) end
        MakeLabel({Size=UDim2.new(0,36,0,36), Position=UDim2.new(0,10,0.5,-18),
            BackgroundColor3=C.PURPLE_DIM, BackgroundTransparency=0.5, Text=ag.icon, TextSize=20, ZIndex=17}, AC)
        MakeLabel({Size=UDim2.new(1,-180,0,20), Position=UDim2.new(0,54,0,8), BackgroundTransparency=1,
            Text=ag.name, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AC)
        MakeLabel({Size=UDim2.new(1,-180,0,16), Position=UDim2.new(0,54,0,28), BackgroundTransparency=1,
            Text=ag.desc, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AC)
        local StB = MakeLabel({Size=UDim2.new(0,96,0,22), Position=UDim2.new(1,-104,0.5,-11),
            BackgroundColor3=Color3.fromRGB(0,40,20), Text="● "..ag.model,
            Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TEXT_GREEN, ZIndex=17}, AC)
        if StB then Corner(10, StB) end
    end

    -- FIX: usar helpers en vez de conexiones inline repetidas
    if LL then AutoScrollSize(LL, Scroll, 20) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 13 - TAB: QUANTUM ORACLE
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_QUANTUM_ORACLE"] = function()
    local Tab = MakeFrame({Name="Tab_ORACLE", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "QUANTUM ORACLE  🔮", "Multi-Agent AI · Orquestador: llama-3.3-70b · " .. GAME_NAME)

    -- Orb visual
    local OrbFrame = MakeFrame({Size=UDim2.new(1,-32,0,106), Position=UDim2.new(0,16,0,70),
        BackgroundColor3=C.BG_GLASS, ZIndex=16}, Tab)
    if OrbFrame then
        Corner(16, OrbFrame)
        Gradient(C.BG_GLASS, Color3.fromRGB(40,0,80), 135, OrbFrame)
        Stroke(1, C.BORDER_BRIGHT, OrbFrame)
    end
    local OrbIcon = MakeFrame({Size=UDim2.new(0,68,0,68), Position=UDim2.new(0,16,0.5,-34),
        BackgroundColor3=C.PURPLE_DIM, ZIndex=17}, OrbFrame)
    if OrbIcon then Corner(34, OrbIcon); Stroke(3, C.PURPLE_NEON, OrbIcon) end
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="🔮", TextSize=34, ZIndex=18}, OrbIcon)
    task.spawn(function()
        while OrbIcon and OrbIcon.Parent do
            Tween(OrbIcon, TI_SINE, {BackgroundColor3=C.PURPLE_GLOW}); task.wait(1.2)
            Tween(OrbIcon, TI_SINE, {BackgroundColor3=C.PURPLE_DIM});  task.wait(1.2)
        end
    end)
    MakeLabel({Size=UDim2.new(1,-106,0,24), Position=UDim2.new(0,100,0,12), BackgroundTransparency=1,
        Text="QUANTUM ORACLE  ·  Multi-Agent AI", Font=Enum.Font.GothamBold,
        TextSize=15, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)
    local AgentBadge = MakeLabel({Size=UDim2.new(1,-106,0,18), Position=UDim2.new(0,100,0,38),
        BackgroundTransparency=1, Text="⬡ Orquestador: llama-3.3-70b  ·  5 Agentes listos",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)
    local ActiveAg = MakeLabel({Size=UDim2.new(1,-106,0,18), Position=UDim2.new(0,100,0,62),
        BackgroundTransparency=1, Text="Juego: '" .. GAME_NAME .. "'  ·  En espera de consulta",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, OrbFrame)

    -- Sugerencias rápidas
    local SugFrame = MakeFrame({Size=UDim2.new(1,-32,0,30), Position=UDim2.new(0,16,0,184),
        BackgroundTransparency=1, ZIndex=16}, Tab)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6)}, SugFrame)
    local sugs = {"¿Mejores scripts?","Script anti-ban","¿Cómo farmear?","Fix mi error Lua","Build óptimo"}
    for _, sug in ipairs(sugs) do
        local SB = MakeButton({Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.BG_CARD, Text=sug, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.CYAN_NEON, ZIndex=17}, SugFrame)
        if SB then Corner(10, SB); Padding(0,10,0,10, SB); Stroke(1, C.CYAN_DIM, SB) end
    end

    -- Chat scroll
    local ChatScroll = MakeScroll({Size=UDim2.new(1,-32,1,-248), Position=UDim2.new(0,16,0,222),
        BackgroundColor3=Color3.fromRGB(5,5,14), ScrollBarThickness=3, ZIndex=15}, Tab)
    if ChatScroll then Corner(12, ChatScroll); Stroke(1, C.BORDER, ChatScroll) end
    local ChatList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ChatScroll)
    ListLayout({Padding=UDim.new(0,8)}, ChatList)
    Padding(10,10,10,10, ChatList)

    local function ScrollToBottom()
        task.wait(0.05)
        if ChatScroll and ChatScroll.Parent and ChatList and ChatList.Parent then
            ChatScroll.CanvasSize     = UDim2.new(0,0,0,ChatList.AbsoluteContentSize.Y + 20)
            ChatScroll.CanvasPosition = Vector2.new(0, ChatList.AbsoluteContentSize.Y)
        end
    end

    local function AddMsg(text, isUser, agentMeta)
        if not ChatList or not ChatList.Parent then return end
        local col = isUser and C.PURPLE_DIM or (agentMeta and agentMeta.color or C.BG_CARD)
        local Bubble = MakeFrame({
            Size=UDim2.new(0.86,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            Position=isUser and UDim2.new(0.14,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3=col, BackgroundTransparency=isUser and 0 or 0.25, ZIndex=16,
        }, ChatList)
        if not Bubble then return end
        Corner(12, Bubble); Padding(10,14,10,14, Bubble)
        if not isUser and agentMeta then
            MakeLabel({Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
                Text=agentMeta.icon.." "..agentMeta.name, Font=Enum.Font.GothamBold, TextSize=10,
                TextColor3=agentMeta.color, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Bubble)
        end
        local yOff = (not isUser and agentMeta) and 18 or 0
        MakeLabel({Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,yOff),
            AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Text=text,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.TEXT_WHITE, TextWrapped=true,
            TextXAlignment=isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left, ZIndex=17}, Bubble)
        ScrollToBottom()
    end

    local ThinkBubble = nil
    local function ShowThinking(text)
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end) end
        if not ChatList or not ChatList.Parent then return end
        ThinkBubble = MakeFrame({Size=UDim2.new(0.5,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=C.BG_CARD, BackgroundTransparency=0.3, ZIndex=16}, ChatList)
        if ThinkBubble then Corner(12, ThinkBubble); Padding(8,12,8,12, ThinkBubble) end
        MakeLabel({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Text="◌ "..text, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.TEXT_MUTED, TextWrapped=true, ZIndex=17}, ThinkBubble)
        ScrollToBottom()
    end
    local function HideThinking()
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end); ThinkBubble=nil end
    end

    AddMsg("🔮 Hola, " .. DISPLAY_NAME .. "! Soy el Quantum Oracle.\n\nJuego detectado: '" .. GAME_NAME ..
        "'.\nEl Orquestador dirigirá tu consulta al agente más adecuado:\n🎮 Game Analyst · 💻 Code Expert · ⚔ Strategy · 🎨 Creative · ⚡ Fast\n\n¿En qué te puedo ayudar?",
        false, {icon="🔮", name="Quantum Oracle", color=C.PURPLE_GLOW})

    -- Input row
    local InputRow = MakeFrame({Size=UDim2.new(1,-32,0,48), Position=UDim2.new(0,16,1,-64),
        BackgroundColor3=C.BG_CARD, ZIndex=16}, Tab)
    if InputRow then Corner(14, InputRow); Stroke(1, C.BORDER, InputRow) end
    local ChatInput = MakeBox({Name="OracleChatInput", Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text="", PlaceholderText="Pregunta algo al Oracle...",
        Font=Enum.Font.Gotham, TextSize=13, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=17}, InputRow)
    local SendBtn = MakeButton({Size=UDim2.new(0,44,0,36), Position=UDim2.new(1,-50,0.5,-18),
        BackgroundColor3=C.PURPLE_NEON, Text="▶", Font=Enum.Font.GothamBold,
        TextSize=16, TextColor3=Color3.new(1,1,1), ZIndex=17}, InputRow)
    if SendBtn then Corner(10, SendBtn) end

    -- Conectar sugerencias al input
    if SugFrame then
        for _, sb in pairs(SugFrame:GetChildren()) do
            if sb:IsA("TextButton") then
                sb.MouseButton1Click:Connect(function()
                    if ChatInput and ChatInput.Parent then ChatInput.Text = sb.Text end
                end)
            end
        end
    end

    local isWaiting = false
    local function SendMessage()
        if isWaiting or not ChatInput or not ChatInput.Parent then return end
        local msg = ChatInput.Text:gsub("^%s+",""):gsub("%s+$","")
        if msg == "" then return end
        ChatInput.Text = ""
        isWaiting = true
        if SendBtn and SendBtn.Parent then SendBtn.Text = "◌" end
        AddMsg(msg, true)
        OracleQuery(msg,
            function(thinkText)
                ShowThinking(thinkText)
                if ActiveAg and ActiveAg.Parent then ActiveAg.Text = "⬡ " .. thinkText end
            end,
            function(agentKey, meta)
                ShowThinking(meta.icon .. " " .. meta.name .. " respondiendo...")
                if ActiveAg  and ActiveAg.Parent  then ActiveAg.Text  = meta.icon .. " Agente activo: " .. meta.name end
                if AgentBadge and AgentBadge.Parent then AgentBadge.Text = meta.icon .. " Usando: " .. meta.name .. "  ·  OpenRouter AI" end
            end,
            function(response, meta)
                HideThinking()
                AddMsg(response, false, meta)
                isWaiting = false
                if SendBtn    and SendBtn.Parent    then SendBtn.Text    = "▶" end
                if ActiveAg   and ActiveAg.Parent   then ActiveAg.Text   = "En espera de consulta" end
                if AgentBadge and AgentBadge.Parent then AgentBadge.Text = "⬡ Orquestador: llama-3.3-70b  ·  5 Agentes listos" end
            end,
            function(errMsg)
                HideThinking()
                AddMsg("❌ Error: " .. tostring(errMsg) .. "\nVerifica tu API Key en Ajustes.", false,
                    {icon="❌", name="Sistema", color=C.TEXT_RED})
                isWaiting = false
                if SendBtn  and SendBtn.Parent  then SendBtn.Text  = "▶" end
                if ActiveAg and ActiveAg.Parent then ActiveAg.Text = "Error · Verifica conexión" end
            end
        )
    end
    if SendBtn  then SendBtn.MouseButton1Click:Connect(SendMessage) end
    if ChatInput then ChatInput.FocusLost:Connect(function(enter) if enter then SendMessage() end end) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 14 - TAB: SCRIPT HUB
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SCRIPT_HUB"] = function()
    local Tab = MakeFrame({Name="Tab_HUB", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "SCRIPT HUB  ⚡", "Scripts verificados para Delta Executor · " .. GAME_NAME)

    local SRow = MakeFrame({Size=UDim2.new(1,-32,0,40), Position=UDim2.new(0,16,0,70),
        BackgroundColor3=C.BG_CARD, ZIndex=15}, Tab)
    if SRow then Corner(12, SRow); Stroke(1, C.BORDER, SRow) end
    MakeBox({Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1,
        Text="", PlaceholderText="🔍 Buscar scripts...", Font=Enum.Font.Gotham, TextSize=13,
        TextColor3=C.TEXT_WHITE, PlaceholderColor3=C.TEXT_MUTED, ZIndex=16}, SRow)

    local ScScroll = MakeScroll({Size=UDim2.new(1,-32,1,-122), Position=UDim2.new(0,16,0,118),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local ScList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ScScroll)
    local scLL = ListLayout({Padding=UDim.new(0,8)}, ScList)

    local scripts = {
        {title="Auto Farm Pro v5.2",    author="LXNDXN",     verified=true,  icon="🌾", script='print("[QOS] Auto Farm activado")'},
        {title="ESP Pro · All Players", author="QuantumDev", verified=true,  icon="👁",  script='print("[QOS] ESP activo")'},
        {title="Infinite Jump",         author="DeltaFarm",  verified=false, icon="⬆",  script='print("[QOS] InfJump activo")'},
        {title="Speed Hack x10",        author="LXNDXN",     verified=true,  icon="💨", script='print("[QOS] Speed x10")'},
        {title="God Mode Bypass",       author="NullSec",    verified=false, icon="🛡",  script='print("[QOS] God Mode")'},
        {title="Auto Collect Items",    author="QuantumDev", verified=true,  icon="💎", script='print("[QOS] AutoCollect activo")'},
        {title="Teleport to Players",   author="LXNDXN",     verified=true,  icon="✈",  script='print("[QOS] TeleportTP activo")'},
        {title="Anti-AFK Pro",          author="QuantumDev", verified=true,  icon="⏱",  script='print("[QOS] AntiAFK activo")'},
    }

    for _, s in ipairs(scripts) do
        local Card = MakeFrame({Size=UDim2.new(1,0,0,80), BackgroundColor3=C.BG_CARD, ZIndex=16}, ScList)
        if not Card then continue end
        Corner(14, Card); Stroke(1, C.BORDER, Card)
        local Thumb = MakeFrame({Size=UDim2.new(0,54,0,54), Position=UDim2.new(0,12,0.5,-27),
            BackgroundColor3=C.PURPLE_DIM, ZIndex=17}, Card)
        if Thumb then Corner(12, Thumb) end
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=s.icon, TextSize=26, ZIndex=18}, Thumb)
        MakeLabel({Size=UDim2.new(1,-200,0,22), Position=UDim2.new(0,76,0,12), BackgroundTransparency=1,
            Text=s.title, Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-200,0,16), Position=UDim2.new(0,76,0,36), BackgroundTransparency=1,
            Text="by "..s.author, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
        if s.verified then
            local VB = MakeLabel({Size=UDim2.new(0,114,0,16), Position=UDim2.new(0,76,0,56),
                BackgroundColor3=Color3.fromRGB(0,44,22), Text="✓ Verificado Delta",
                Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_GREEN, ZIndex=18}, Card)
            if VB then Corner(8, VB) end
        end
        local ExBtn = MakeButton({Size=UDim2.new(0,90,0,30), Position=UDim2.new(1,-172,0.5,-15),
            BackgroundColor3=C.PURPLE_NEON, Text="▶ EXECUTE",
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), ZIndex=17}, Card)
        if ExBtn then
            Corner(8, ExBtn); HoverGlow(ExBtn, C.PURPLE_NEON, C.PURPLE_GLOW)
            ExBtn.MouseButton1Click:Connect(function()
                -- FIX: loadstring con pcall robusto y feedback de error
                local ok, err = pcall(function() loadstring(s.script)() end)
                if ok then
                    PushNotification("Script Ejecutado", s.title .. " activado correctamente.", "SUCCESS", 3)
                else
                    PushNotification("Error en Script", tostring(err):sub(1,60), "ERROR", 4)
                end
            end)
        end
        local SaveBtn = MakeButton({Size=UDim2.new(0,62,0,30), Position=UDim2.new(1,-72,0.5,-15),
            BackgroundColor3=C.BG_GLASS, Text="💾 SAVE",
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, ZIndex=17}, Card)
        if SaveBtn then Corner(8, SaveBtn) end
    end

    -- FIX: usar helper para auto-resize
    if scLL then AutoScrollSize(scLL, ScScroll, 20) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 15 - TAB: SYSTEM SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SYSTEM_SETTINGS"] = function()
    local Tab = MakeFrame({Name="Tab_SETTINGS", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "SYSTEM SETTINGS  ⚙", "Configuración del sistema · AI · Executor")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-65), Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    local sLL = ListLayout({Padding=UDim.new(0,4)}, SL)
    Padding(12,16,20,16, SL)

    -- API Key card
    local KC = MakeFrame({Size=UDim2.new(1,0,0,112), BackgroundColor3=C.BG_CARD, ZIndex=16}, SL)
    if not KC then return end
    Corner(14, KC); Stroke(1, C.BORDER, KC)
    MakeLabel({Size=UDim2.new(1,-160,0,22), Position=UDim2.new(0,16,0,12), BackgroundTransparency=1,
        Text="OpenRouter API Key", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KC)
    local KeyStatus = MakeLabel({Size=UDim2.new(0,130,0,22), Position=UDim2.new(1,-146,0,12),
        BackgroundColor3=(ENV.QuantumOS_OpenRouterKey and ENV.QuantumOS_OpenRouterKey~="")
            and Color3.fromRGB(0,44,22) or Color3.fromRGB(44,8,8),
        Text=(ENV.QuantumOS_OpenRouterKey and ENV.QuantumOS_OpenRouterKey~="") and "● Conectado" or "○ Sin Key",
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=(ENV.QuantumOS_OpenRouterKey and ENV.QuantumOS_OpenRouterKey~="") and C.TEXT_GREEN or C.TEXT_RED,
        ZIndex=17}, KC)
    if KeyStatus then Corner(10, KeyStatus) end
    local KeyDisplay = MakeLabel({Size=UDim2.new(1,-32,0,18), Position=UDim2.new(0,16,0,38),
        BackgroundTransparency=1,
        Text = ENV.QuantumOS_OpenRouterKey and ENV.QuantumOS_OpenRouterKey~=""
            and "sk-or-..." .. ENV.QuantumOS_OpenRouterKey:sub(-6) or "Sin API Key configurada",
        Font=Enum.Font.Code, TextSize=11,
        TextColor3 = ENV.QuantumOS_OpenRouterKey and ENV.QuantumOS_OpenRouterKey~="" and C.TEXT_GREEN or C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KC)
    local NewKeyBox = MakeBox({Size=UDim2.new(1,-120,0,32), Position=UDim2.new(0,16,0,64),
        BackgroundColor3=Color3.fromRGB(10,8,28), BorderSizePixel=0,
        Text="", PlaceholderText="Nueva API Key...", Font=Enum.Font.Code,
        TextSize=12, TextColor3=C.TEXT_WHITE, PlaceholderColor3=C.TEXT_MUTED,
        ClearTextOnFocus=false, ZIndex=17}, KC)
    if NewKeyBox then Corner(8, NewKeyBox); Stroke(1, C.BORDER, NewKeyBox); Padding(0,8,0,8, NewKeyBox) end
    local SaveKeyBtn = MakeButton({Size=UDim2.new(0,96,0,32), Position=UDim2.new(1,-112,0,64),
        BackgroundColor3=C.PURPLE_NEON, Text="Guardar",
        Font=Enum.Font.GothamBold, TextSize=12, TextColor3=Color3.new(1,1,1), ZIndex=17}, KC)
    if SaveKeyBtn then
        Corner(8, SaveKeyBtn)
        SaveKeyBtn.MouseButton1Click:Connect(function()
            if not NewKeyBox or not NewKeyBox.Parent then return end
            local newKey = NewKeyBox.Text:gsub("%s+","")
            if #newKey < 10 then
                PushNotification("Key Inválida", "La key parece demasiado corta.", "WARNING", 3)
                return
            end
            ENV.QuantumOS_OpenRouterKey = newKey
            NewKeyBox.Text = ""
            if KeyStatus and KeyStatus.Parent then
                KeyStatus.Text = "● Conectado"; KeyStatus.TextColor3 = C.TEXT_GREEN
                KeyStatus.BackgroundColor3 = Color3.fromRGB(0,44,22)
            end
            if KeyDisplay and KeyDisplay.Parent then
                KeyDisplay.Text = "sk-or-..." .. newKey:sub(-6); KeyDisplay.TextColor3 = C.TEXT_GREEN
            end
            PushNotification("API Key Guardada", "OpenRouter key actualizada.", "SUCCESS", 3)
        end)
    end

    -- Toggles del sistema
    local function SettingLabel(text)
        MakeLabel({Size=UDim2.new(1,0,0,24), BackgroundTransparency=1, Text=text,
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.PURPLE_GLOW,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, SL)
    end

    SettingLabel("RENDIMIENTO")
    CreateToggle(SL, "Partículas de Fondo", true, function(v)
        if BG then for _, p in pairs(BG:GetChildren()) do
            if p:IsA("Frame") and p.Size.X.Offset <= 6 then p.Visible = v end
        end end
    end)
    CreateToggle(SL, "Animaciones UI", true, function(v)
        -- placeholder: podrías deshabilitar tweens globalmente
    end)

    SettingLabel("INTERFAZ")
    CreateSlider(SL, "Transparencia del Panel", 0, 80, 12, "%", function(v)
        -- FIX: aplicar a ContentArea si existe
        if ContentArea and ContentArea.Parent then
            ContentArea.BackgroundTransparency = v / 100
        end
    end)

    SettingLabel("DISPOSITIVO")
    CreateToggle(SL, "Modo Móvil Activo", ENV.QuantumOS_DeviceMode == "mobile", function(v)
        ENV.QuantumOS_DeviceMode = v and "mobile" or "pc"
        PushNotification("Modo Cambiado", v and "Modo móvil activado." or "Modo PC activado.", "INFO", 2)
    end)

    SettingLabel("ACERCA DE")
    local AboutCard = MakeFrame({Size=UDim2.new(1,0,0,54), BackgroundColor3=C.BG_CARD, ZIndex=16}, SL)
    if AboutCard then Corner(10, AboutCard); Stroke(1, C.BORDER, AboutCard) end
    MakeLabel({Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,16,0,0), BackgroundTransparency=1,
        Text="LXNDXN Quantum OS v3.1  ·  Delta Edition  ·  Multi-Agent AI\nOpenRouter · 5 Agentes · Modo: "..(ENV.QuantumOS_DeviceMode or "no seleccionado"),
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, AboutCard)

    if sLL then AutoScrollSize(sLL, Scroll, 20) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 16 - FLUJO PRINCIPAL DE INICIO
-- ═══════════════════════════════════════════════════════════════════════════════

local function StartOS()
    CreateMainWindow()
    -- Abrir START por defecto
    task.wait(0.5)
    local startBtn = SidebarButtons["START"]
    if startBtn then
        SetActiveTab("START")
        ENV.QuantumOS_ActiveTab = "START"
        pcall(_G["QOS_Tab_START"])
    end
    -- Notificación de bienvenida
    task.wait(0.8)
    PushNotification("Sistema Activo", "Quantum OS v3.1 iniciado · " .. GAME_NAME, "SYSTEM", 4)
    ShowToast("🔮 Quantum Oracle", "Multi-Agent AI listo · 5 agentes activos", "🤖", 3)
end

-- FIX: Flujo completo con manejo de errores en cada etapa
local function Init()
    local ok, err = pcall(CreateBootScreen)
    if not ok then warn("[QOS] Boot screen error: " .. tostring(err)) end

    -- Esperar a que termine el boot (~4.5s) antes de mostrar login
    task.wait(4.8)

    local loginOK, loginErr = pcall(function()
        CreateLoginScreen(function()
            -- Tras login exitoso → selección de dispositivo
            local devOK, devErr = pcall(function()
                CreateDeviceSelectionScreen(function(mode)
                    -- Tras seleccionar dispositivo → OS principal
                    local osOK, osErr = pcall(StartOS)
                    if not osOK then
                        warn("[QOS] OS start error: " .. tostring(osErr))
                        PushNotification("Error al iniciar OS", tostring(osErr):sub(1,60), "ERROR", 5)
                    end
                end)
            end)
            if not devOK then
                warn("[QOS] Device selection error: " .. tostring(devErr))
                -- FIX: Si la pantalla de dispositivo falla, saltar directo al OS
                pcall(StartOS)
            end
        end)
    end)

    if not loginOK then
        warn("[QOS] Login screen error: " .. tostring(loginErr))
    end
end

-- FIX: Envolver todo el inicio en pcall para que un error no rompa el executor
local initOK, initErr = pcall(Init)
if not initOK then
    warn("[LXNDXN QOS] Error crítico de inicialización: " .. tostring(initErr))
end
