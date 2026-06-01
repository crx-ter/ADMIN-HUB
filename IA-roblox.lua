-- ═══════════════════════════════════════════════════════════════════════════════
-- LXNDXN QUANTUM OS v3.0 — DELTA EDITION · MULTI-AGENT AI ORCHESTRATOR
-- Author  : LXNDXN
-- Engine  : Delta Executor (Mobile-Optimised Roblox Lua)
-- Version : 3.0.0-DE
-- Theme   : Cyberpunk Dark · Neon Purple · Glassmorphic
-- AI      : OpenRouter Multi-Agent · Orchestrator: llama-3.3-70b-instruct
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 1 - ENVIRONMENT BOOTSTRAP
-- ═══════════════════════════════════════════════════════════════════════════════

local ENV = getgenv()

if ENV.QuantumOS_Instance   then pcall(function() ENV.QuantumOS_Instance:Destroy()   end) end
if ENV.QuantumOS_OracleFloat then pcall(function() ENV.QuantumOS_OracleFloat:Destroy() end) end
if ENV.QuantumOS_Connections then
    for _, c in pairs(ENV.QuantumOS_Connections) do pcall(function() c:Disconnect() end) end
end

ENV.QuantumOS_Connections   = {}
ENV.QuantumOS_ActiveTab     = nil
ENV.QuantumOS_Unlocked      = false
ENV.QuantumOS_OpenRouterKey = nil   -- Se llena al login
ENV.QuantumOS_DeviceMode    = nil   -- "mobile" o "pc"

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 2 - SERVICIOS Y REFERENCIAS
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
-- SECCIÓN 3 - PALETA DE COLORES Y CONSTANTES
-- ═══════════════════════════════════════════════════════════════════════════════

local C = {
    PURPLE_NEON   = Color3.fromRGB(160,  32, 240),
    PURPLE_DIM    = Color3.fromRGB( 90,  15, 140),
    PURPLE_GLOW   = Color3.fromRGB(180,  80, 255),
    CYAN_NEON     = Color3.fromRGB(  0, 220, 255),
    CYAN_DIM      = Color3.fromRGB(  0, 140, 180),
    PINK_NEON     = Color3.fromRGB(255,  60, 160),
    GOLD_NEON     = Color3.fromRGB(255, 195,  50),

    BG_DEEP       = Color3.fromRGB(  4,   4,  14),
    BG_PANEL      = Color3.fromRGB( 10,  10,  26),
    BG_CARD       = Color3.fromRGB( 16,  16,  40),
    BG_SIDEBAR    = Color3.fromRGB(  6,   6,  18),
    BG_GLASS      = Color3.fromRGB( 22,  18,  48),
    BG_HEADER     = Color3.fromRGB( 12,   8,  30),

    TEXT_WHITE    = Color3.fromRGB(230, 230, 255),
    TEXT_SOFT     = Color3.fromRGB(160, 155, 200),
    TEXT_MUTED    = Color3.fromRGB( 90,  85, 130),
    TEXT_GREEN    = Color3.fromRGB(  0, 220, 130),
    TEXT_RED      = Color3.fromRGB(255,  70,  70),
    TEXT_YELLOW   = Color3.fromRGB(255, 210,  60),

    ACCENT_A      = Color3.fromRGB(160,  32, 240),
    ACCENT_B      = Color3.fromRGB(  0, 180, 255),
    BORDER        = Color3.fromRGB( 60,  45, 110),
    BORDER_BRIGHT = Color3.fromRGB(120,  60, 200),

    TOGGLE_ON     = Color3.fromRGB(  0, 190, 120),
    TOGGLE_OFF    = Color3.fromRGB( 50,  45,  75),
    SLIDER_BG     = Color3.fromRGB( 28,  22,  60),
    SLIDER_FILL   = Color3.fromRGB(160,  32, 240),
}

local TI_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TI_MED    = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_SLOW   = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TI_SINE   = TweenInfo.new(1.20, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)
local TI_PULSE  = TweenInfo.new(0.90, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut, -1, true)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 4 - UTILIDADES UI
-- ═══════════════════════════════════════════════════════════════════════════════

local function Make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do pcall(function() inst[k] = v end) end
    if parent then inst.Parent = parent end
    return inst
end

local function MakeFrame(p, par)  return Make("Frame",           p, par) end
local function MakeLabel(p, par)  return Make("TextLabel",       p, par) end
local function MakeButton(p, par) return Make("TextButton",      p, par) end
local function MakeBox(p, par)    return Make("TextBox",         p, par) end
local function MakeImage(p, par)  return Make("ImageLabel",      p, par) end
local function MakeScroll(p, par) return Make("ScrollingFrame",  p, par) end

local function Tween(inst, info, props) return TweenService:Create(inst, info, props):Play() end

local function Corner(r, parent)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = parent; return c
end

local function Stroke(thickness, color, parent)
    local s = Instance.new("UIStroke"); s.Thickness = thickness; s.Color = color or C.BORDER; s.Parent = parent; return s
end

local function Padding(t, r, b, l, parent)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0); p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0); p.PaddingLeft   = UDim.new(0, l or 0)
    p.Parent = parent; return p
end

local function ListLayout(props, parent)
    local l = Instance.new("UIListLayout")
    for k, v in pairs(props or {}) do pcall(function() l[k] = v end) end
    l.Parent = parent; return l
end

local function GridLayout(props, parent)
    local g = Instance.new("UIGridLayout")
    for k, v in pairs(props or {}) do pcall(function() g[k] = v end) end
    g.Parent = parent; return g
end

local function TrackConn(conn) table.insert(ENV.QuantumOS_Connections, conn); return conn end

local function Gradient(c0, c1, rot, parent)
    local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90; g.Parent = parent; return g
end

local function HoverGlow(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function() Tween(btn, TI_FAST, {BackgroundColor3 = hoverColor}) end)
    btn.MouseLeave:Connect(function() Tween(btn, TI_FAST, {BackgroundColor3 = normalColor}) end)
end

local function Typewriter(label, text, speed)
    speed = speed or 0.04; label.Text = ""
    task.spawn(function()
        for i = 1, #text do label.Text = string.sub(text, 1, i); task.wait(speed) end
    end)
end

local function PulseStroke(stroke, c1, c2)
    task.spawn(function()
        local dir = true
        while stroke and stroke.Parent do
            Tween(stroke, TI_SINE, {Color = dir and c2 or c1}); task.wait(1.2); dir = not dir
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 5 - RAÍZ DEL GUI
-- ═══════════════════════════════════════════════════════════════════════════════

local ScreenGui = Make("ScreenGui", {
    Name="QuantumOS_v30", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
}, PlayerGui)

ENV.QuantumOS_Instance = ScreenGui

local BG = MakeFrame({
    Name="Background", Size=UDim2.fromScale(1,1),
    BackgroundColor3=C.BG_DEEP, BorderSizePixel=0, ZIndex=1,
}, ScreenGui)

MakeImage({
    Name="GridTexture", Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
    Image="rbxassetid://6370457276", ImageColor3=C.PURPLE_NEON, ImageTransparency=0.94, ZIndex=2,
}, BG)

-- Partículas de fondo animadas
local function SpawnBGParticles()
    for i = 1, 18 do
        local size = math.random(2, 5)
        local px = MakeFrame({
            Size=UDim2.new(0,size,0,size),
            Position=UDim2.new(math.random()*0.98, 0, math.random()*0.98, 0),
            BackgroundColor3=(i%3==0) and C.PURPLE_NEON or (i%3==1) and C.CYAN_NEON or C.PINK_NEON,
            BackgroundTransparency=0.5, ZIndex=3,
        }, BG)
        Corner(size, px)
        task.spawn(function()
            while px and px.Parent do
                local rx,ry = math.random()*0.96, math.random()*0.96
                Tween(px, TweenInfo.new(3+math.random()*4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position=UDim2.new(rx,0,ry,0), BackgroundTransparency=0.1+math.random()*0.7
                })
                task.wait(3+math.random()*4)
            end
        end)
    end
end
SpawnBGParticles()

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 6 - MULTI-AGENT AI SYSTEM (OpenRouter Orchestrator)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Orquestador principal: llama-3.3-70b-instruct (decide qué agente usar)
-- Agentes especializados:
--   GAME_ANALYST   → nvidia/nemotron-3-super-120b-a12b:free
--   CODE_EXPERT    → qwen/qwen3-coder:free
--   STRATEGY_AGENT → deepseek/deepseek-v4-flash:free
--   CREATIVE_AGENT → google/gemma-4-31b-it:free
--   FAST_AGENT     → meta-llama/llama-3.2-3b-instruct:free

local AI = {}

AI.ORCHESTRATOR = "meta-llama/llama-3.3-70b-instruct:free"
AI.AGENTS = {
    GAME_ANALYST   = "nvidia/nemotron-3-super-120b-a12b:free",
    CODE_EXPERT    = "qwen/qwen3-coder:free",
    STRATEGY_AGENT = "deepseek/deepseek-v4-flash:free",
    CREATIVE_AGENT = "google/gemma-4-31b-it:free",
    FAST_AGENT     = "meta-llama/llama-3.2-3b-instruct:free",
}

AI.SYSTEM_PROMPTS = {
    ORCHESTRATOR = [[Eres el Orquestador del Quantum OS, un OS para Roblox con IA multi-agente.
Tu tarea: analizar el mensaje del usuario y responder en JSON con:
{"agent":"GAME_ANALYST|CODE_EXPERT|STRATEGY_AGENT|CREATIVE_AGENT|FAST_AGENT","reason":"por qué","context":"información relevante del juego: ]]..GAME_NAME..[["}
Reglas:
- GAME_ANALYST: preguntas sobre el juego, items, NPCs, mecánicas
- CODE_EXPERT: scripts, errores de código, Lua, exploits
- STRATEGY_AGENT: estrategias, builds, speedruns, eficiencia
- CREATIVE_AGENT: ideas, roleplay, personalización, creatividad
- FAST_AGENT: saludos, preguntas simples, respuestas cortas
Solo responde el JSON, sin texto adicional.]],

    GAME_ANALYST   = "Eres un experto analista del juego de Roblox '"..GAME_NAME.."'. Analiza mecánicas, items, bosses, mapas y da consejos detallados y precisos. Responde en español, máximo 120 palabras.",
    CODE_EXPERT    = "Eres un experto en Lua y scripting de Roblox para el executor Delta. Ayuda con scripts, errores, optimización de código. Responde en español con código bien documentado, máximo 150 palabras.",
    STRATEGY_AGENT = "Eres un estratega experto en '"..GAME_NAME.."'. Das estrategias óptimas, builds, rutas de farming, guías paso a paso. Responde en español, conciso y útil, máximo 120 palabras.",
    CREATIVE_AGENT = "Eres un asistente creativo para Roblox. Ayudas con ideas de personalización, roleplay, builds creativos, diseño de UIs. Responde en español con entusiasmo, máximo 100 palabras.",
    FAST_AGENT     = "Eres el asistente rápido del Quantum OS para '"..GAME_NAME.."'. Responde de forma breve, amigable y directa en español. Máximo 60 palabras.",
}

AI.AGENT_META = {
    GAME_ANALYST   = {icon="🎮", name="Game Analyst",    color=Color3.fromRGB(255,140,0)},
    CODE_EXPERT    = {icon="💻", name="Code Expert",     color=Color3.fromRGB(0,220,180)},
    STRATEGY_AGENT = {icon="⚔", name="Strategy Agent",  color=Color3.fromRGB(220,50,50)},
    CREATIVE_AGENT = {icon="🎨", name="Creative Agent",  color=Color3.fromRGB(200,100,255)},
    FAST_AGENT     = {icon="⚡", name="Fast Agent",      color=Color3.fromRGB(255,220,60)},
}

-- Función base de llamada HTTP a OpenRouter
local function OR_Call(model, systemPrompt, userMsg, maxTokens)
    maxTokens = maxTokens or 300
    local key = ENV.QuantumOS_OpenRouterKey
    if not key or key == "" then return nil, "Sin API Key" end

    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({
            model = model,
            max_tokens = maxTokens,
            messages = {
                {role="system", content=systemPrompt},
                {role="user",   content=userMsg},
            },
        })
        local response = HttpService:RequestAsync({
            Url    = "https://openrouter.ai/api/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. key,
                ["Content-Type"]  = "application/json",
                ["HTTP-Referer"]  = "https://lxndxn-quantumos.rblx",
                ["X-Title"]       = "LXNDXN Quantum OS",
            },
            Body = body,
        })
        if response.StatusCode ~= 200 then
            return nil, "HTTP " .. response.StatusCode
        end
        local data = HttpService:JSONDecode(response.Body)
        return data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content
    end)

    if ok then return result, nil
    else return nil, tostring(result) end
end

-- Verificar API Key con llamada real al modelo rápido
local function VerifyAPIKey(key, callback)
    task.spawn(function()
        local oldKey = ENV.QuantumOS_OpenRouterKey
        ENV.QuantumOS_OpenRouterKey = key
        local response, err = OR_Call(
            AI.AGENTS.FAST_AGENT,
            "Eres un asistente de verificación. Responde solo: OK",
            "Verifica esta conexión. Responde solo con la palabra: OK",
            10
        )
        if response and (response:find("OK") or #response > 0) then
            callback(true, response)
        else
            ENV.QuantumOS_OpenRouterKey = oldKey
            callback(false, err or "Respuesta inválida")
        end
    end)
end

-- Función principal del oráculo multi-agente
local function OracleQuery(userMsg, onThink, onAgent, onResponse, onError)
    task.spawn(function()
        -- Paso 1: Orquestador decide qué agente usar
        if onThink then onThink("Orquestador analizando consulta...") end

        local orchResponse, orchErr = OR_Call(
            AI.ORCHESTRATOR,
            AI.SYSTEM_PROMPTS.ORCHESTRATOR,
            userMsg,
            80
        )

        local agentKey = "FAST_AGENT"
        if orchResponse then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(orchResponse) end)
            if ok and decoded and decoded.agent then
                agentKey = decoded.agent
            end
        end

        local meta = AI.AGENT_META[agentKey] or AI.AGENT_META.FAST_AGENT
        if onAgent then onAgent(agentKey, meta) end

        -- Paso 2: Agente especializado responde
        if onThink then onThink(meta.icon .. " " .. meta.name .. " procesando...") end

        local agentModel  = AI.AGENTS[agentKey] or AI.AGENTS.FAST_AGENT
        local agentPrompt = AI.SYSTEM_PROMPTS[agentKey] or AI.SYSTEM_PROMPTS.FAST_AGENT

        local response, err = OR_Call(agentModel, agentPrompt, userMsg, 300)

        if response then
            if onResponse then onResponse(response, meta) end
        else
            if onError then onError(err or "Error desconocido") end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 7 - BOOT SCREEN
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateBootScreen()
    local Boot = MakeFrame({
        Name="BootScreen", Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG_DEEP, ZIndex=100,
    }, ScreenGui)
    Gradient(C.BG_DEEP, Color3.fromRGB(8,4,22), 135, Boot)

    local Center = MakeFrame({
        Size=UDim2.new(0,380,0,440), Position=UDim2.new(0.5,-190,0.5,-220),
        BackgroundColor3=C.BG_GLASS, BackgroundTransparency=0.3, ZIndex=101,
    }, Boot)
    Corner(32, Center)
    local cs = Stroke(2, C.PURPLE_NEON, Center)
    PulseStroke(cs, C.PURPLE_DIM, C.PURPLE_GLOW)

    -- Partículas del boot
    for i = 1, 8 do
        local px = MakeFrame({
            Size=UDim2.new(0,3,0,3),
            Position=UDim2.new(math.random()*0.9,0,math.random()*0.9,0),
            BackgroundColor3=(i%2==0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency=0.3, ZIndex=102,
        }, Center)
        Corner(2, px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(2+math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position=UDim2.new(math.random()*0.9,0,math.random()*0.9,0), BackgroundTransparency=0.6
                })
                task.wait(2+math.random())
            end
        end)
    end

    local LogoLabel = MakeLabel({
        Size=UDim2.new(1,0,0,90), Position=UDim2.new(0,0,0,24),
        BackgroundTransparency=1, Text="⬡", Font=Enum.Font.GothamBold,
        TextSize=72, TextColor3=C.PURPLE_NEON, ZIndex=102,
    }, Center)

    task.spawn(function()
        while LogoLabel and LogoLabel.Parent do
            Tween(LogoLabel, TI_SINE, {TextColor3=C.PURPLE_GLOW, TextTransparency=0.1}); task.wait(1.2)
            Tween(LogoLabel, TI_SINE, {TextColor3=C.PURPLE_NEON, TextTransparency=0.0}); task.wait(1.2)
        end
    end)

    MakeLabel({
        Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,120),
        BackgroundTransparency=1, Text="QUANTUM OS  v3.0",
        Font=Enum.Font.GothamBold, TextSize=24, TextColor3=C.TEXT_WHITE, ZIndex=102,
    }, Center)

    local Badge = MakeLabel({
        Size=UDim2.new(0,200,0,26), Position=UDim2.new(0.5,-100,0,155),
        BackgroundColor3=C.PURPLE_DIM, BackgroundTransparency=0.25,
        Text="✦ DELTA EDITION · MULTI-AGENT AI ✦",
        Font=Enum.Font.GothamSemibold, TextSize=11, TextColor3=C.CYAN_NEON, ZIndex=102,
    }, Center)
    Corner(13, Badge)

    local WelcomeLabel = MakeLabel({
        Size=UDim2.new(1,-40,0,50), Position=UDim2.new(0,20,0,195),
        BackgroundTransparency=1, Text="", Font=Enum.Font.Gotham,
        TextSize=15, TextColor3=C.TEXT_WHITE, TextWrapped=true, ZIndex=102,
    }, Center)

    local SubText = MakeLabel({
        Size=UDim2.new(1,-40,0,50), Position=UDim2.new(0,20,0,248),
        BackgroundTransparency=1, Text="", Font=Enum.Font.Gotham,
        TextSize=12, TextColor3=C.TEXT_SOFT, TextWrapped=true, ZIndex=102,
    }, Center)

    local ProgressBG = MakeFrame({
        Size=UDim2.new(1,-40,0,6), Position=UDim2.new(0,20,0,330),
        BackgroundColor3=C.SLIDER_BG, ZIndex=102,
    }, Center)
    Corner(3, ProgressBG)
    local ProgressFill = MakeFrame({Size=UDim2.new(0,0,1,0), BackgroundColor3=C.PURPLE_NEON, ZIndex=103}, ProgressBG)
    Corner(3, ProgressFill)
    Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, ProgressFill)

    local ProgressLabel = MakeLabel({
        Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,1,5),
        BackgroundTransparency=1, Text="Inicializando sistema...",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED, ZIndex=102,
    }, ProgressBG)

    MakeLabel({
        Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,1,-28),
        BackgroundTransparency=1, Text="LXNDXN · Delta Edition · Multi-Agent AI v3.0",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED, ZIndex=102,
    }, Center)

    task.spawn(function()
        task.wait(0.5)
        Typewriter(WelcomeLabel, "Hola, " .. DISPLAY_NAME .. ". Iniciando Quantum OS v3.0...", 0.04)
        task.wait(1.8)
        Typewriter(SubText, "Sistema Multi-Agente AI cargando...\nOrquestador · 5 Agentes Especializados activos.", 0.03)
        task.wait(1.4)
        local steps = {
            {0.12, "Cargando kernel del OS..."},
            {0.28, "Verificando Delta Executor..."},
            {0.44, "Inicializando sistema UI..."},
            {0.60, "Conectando al Orquestador AI..."},
            {0.74, "Activando agentes especializados..."},
            {0.88, "Estableciendo sesión segura..."},
            {1.00, "Sistema listo. Acceso requerido."},
        }
        for _, step in ipairs(steps) do
            Tween(ProgressFill, TI_MED, {Size=UDim2.new(step[1],0,1,0)})
            ProgressLabel.Text = step[2]; task.wait(0.42)
        end
        task.wait(0.5)
        Tween(Boot,   TI_SLOW, {BackgroundTransparency=1})
        Tween(Center, TI_SLOW, {BackgroundTransparency=1})
        task.wait(0.65)
        Boot:Destroy()
    end)

    return Boot
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 8 - LOGIN SCREEN ÉPICO (Full-screen · OpenRouter API Key)
-- ═══════════════════════════════════════════════════════════════════════════════

local LoginScreenRef = nil
local toastQueue = {}
local toastActive = false
local ShowToast   -- forward declaration
local PushNotification  -- forward declaration

local function CreateLoginScreen(onSuccess)
    local Login = MakeFrame({
        Name="LoginScreen", Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG_DEEP, ZIndex=90,
    }, ScreenGui)

    -- Fondo con gradiente épico
    Gradient(Color3.fromRGB(4,2,14), Color3.fromRGB(14,6,38), 135, Login)

    -- Líneas de scan animadas
    local function SpawnScanLine()
        task.spawn(function()
            while Login and Login.Parent do
                local line = MakeFrame({
                    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,0),
                    BackgroundColor3=C.PURPLE_NEON, BackgroundTransparency=0.85, ZIndex=91,
                }, Login)
                Tween(line, TweenInfo.new(2.5+math.random()*2, Enum.EasingStyle.Linear), {Position=UDim2.new(0,0,1,0)})
                task.wait(3+math.random()*3)
                pcall(function() line:Destroy() end)
            end
        end)
    end
    for i = 1, 4 do task.delay(i*0.7, SpawnScanLine) end

    -- Partículas de fondo del login
    for i = 1, 20 do
        local size = math.random(2, 6)
        local px = MakeFrame({
            Size=UDim2.new(0,size,0,size),
            Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
            BackgroundColor3=(i%3==0) and C.PURPLE_NEON or (i%3==1) and C.CYAN_NEON or C.PINK_NEON,
            BackgroundTransparency=0.4, ZIndex=91,
        }, Login)
        Corner(size, px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(4+math.random()*5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
                    BackgroundTransparency=0.1+math.random()*0.8
                })
                task.wait(4+math.random()*5)
            end
        end)
    end

    -- Hexágonos decorativos (fondo)
    local hexPositions = {
        {0.05,0.1},{0.9,0.05},{0.02,0.8},{0.92,0.85},{0.5,0.02},{0.5,0.97},
        {0.15,0.5},{0.85,0.5},
    }
    for _, pos in ipairs(hexPositions) do
        local hexLabel = MakeLabel({
            Size=UDim2.new(0,80,0,80),
            Position=UDim2.new(pos[1]-0.04,0,pos[2]-0.07,0),
            BackgroundTransparency=1, Text="⬡", Font=Enum.Font.GothamBold,
            TextSize=70, TextColor3=C.PURPLE_NEON, TextTransparency=0.88, ZIndex=91,
        }, Login)
        task.spawn(function()
            local dir = true
            while hexLabel and hexLabel.Parent do
                Tween(hexLabel, TI_SINE, {TextTransparency=dir and 0.92 or 0.82})
                task.wait(1.5+math.random()*2); dir = not dir
            end
        end)
    end

    -- ─── PANEL PRINCIPAL (centrado, glassmorphic) ─────────────────────────────
    local Panel = MakeFrame({
        Name="LoginPanel",
        Size=UDim2.new(0,420,0,580),
        Position=UDim2.new(0.5,-210,0.5,-290),
        BackgroundColor3=Color3.fromRGB(12,10,32),
        BackgroundTransparency=0.15, ZIndex=92,
    }, Login)
    Corner(28, Panel)
    local panelStroke = Stroke(2, C.BORDER_BRIGHT, Panel)
    PulseStroke(panelStroke, C.PURPLE_DIM, C.PURPLE_GLOW)

    -- Brillo de fondo del panel
    local PanelGlow = MakeFrame({
        Size=UDim2.new(1.4,0,1.3,0), Position=UDim2.new(-0.2,0,-0.15,0),
        BackgroundColor3=C.PURPLE_NEON, BackgroundTransparency=0.93, ZIndex=91,
    }, Panel)
    Corner(50, PanelGlow)
    task.spawn(function()
        while PanelGlow and PanelGlow.Parent do
            Tween(PanelGlow, TI_SINE, {BackgroundTransparency=0.95}); task.wait(1.2)
            Tween(PanelGlow, TI_SINE, {BackgroundTransparency=0.90}); task.wait(1.2)
        end
    end)

    -- Partículas interiores del panel
    for i = 1, 8 do
        local size2 = math.random(2, 4)
        local ppx = MakeFrame({
            Size=UDim2.new(0,size2,0,size2),
            Position=UDim2.new(math.random()*0.94,0,math.random()*0.94,0),
            BackgroundColor3=(i%2==0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency=0.2, ZIndex=93,
        }, Panel)
        Corner(size2, ppx)
        task.spawn(function()
            while ppx and ppx.Parent do
                Tween(ppx, TweenInfo.new(2+math.random()*3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position=UDim2.new(math.random()*0.94,0,math.random()*0.94,0),
                    BackgroundTransparency=0.4+math.random()*0.5
                })
                task.wait(2+math.random()*3)
            end
        end)
    end

    -- Logo Hex con anillos
    local LogoFrame = MakeFrame({
        Size=UDim2.new(0,90,0,90), Position=UDim2.new(0.5,-45,0,28),
        BackgroundColor3=C.PURPLE_DIM, BackgroundTransparency=0.3, ZIndex=93,
    }, Panel)
    Corner(45, LogoFrame)
    Stroke(3, C.PURPLE_NEON, LogoFrame)
    Gradient(Color3.fromRGB(60,10,110), C.PURPLE_DIM, 135, LogoFrame)

    local LogoIcon = MakeLabel({
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text="⬡", Font=Enum.Font.GothamBold, TextSize=54, TextColor3=C.PURPLE_NEON, ZIndex=94,
    }, LogoFrame)

    -- Anillo exterior pulsante
    local LogoRing = MakeFrame({
        Size=UDim2.new(0,110,0,110), Position=UDim2.new(0.5,-55,0,18),
        BackgroundTransparency=1, ZIndex=93,
    }, Panel)
    Corner(55, LogoRing)
    Stroke(1, C.PURPLE_NEON, LogoRing)
    task.spawn(function()
        while LogoFrame and LogoFrame.Parent do
            Tween(LogoIcon, TI_SINE, {TextColor3=C.CYAN_NEON}); task.wait(1.2)
            Tween(LogoIcon, TI_SINE, {TextColor3=C.PURPLE_NEON}); task.wait(1.2)
        end
    end)

    -- Título principal
    MakeLabel({
        Size=UDim2.new(1,0,0,34), Position=UDim2.new(0,0,0,128),
        BackgroundTransparency=1, Text="QUANTUM OS",
        Font=Enum.Font.GothamBold, TextSize=28, TextColor3=C.TEXT_WHITE, ZIndex=93,
    }, Panel)

    MakeLabel({
        Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,163),
        BackgroundTransparency=1, Text="Multi-Agent AI · Delta Edition · v3.0",
        Font=Enum.Font.GothamSemibold, TextSize=13, TextColor3=C.CYAN_NEON, ZIndex=93,
    }, Panel)

    -- Badges de agentes
    local BadgeRow = MakeFrame({
        Size=UDim2.new(1,-40,0,26), Position=UDim2.new(0,20,0,190),
        BackgroundTransparency=1, ZIndex=93,
    }, Panel)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center, Padding=UDim.new(0,5)}, BadgeRow)

    local agentBadges = {{"🎮","Game"}, {"💻","Code"}, {"⚔","Strat"}, {"🎨","Create"}, {"⚡","Fast"}}
    for _, ab in ipairs(agentBadges) do
        local B = MakeLabel({
            Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=Color3.fromRGB(20,8,50),
            Text=ab[1].." "..ab[2], Font=Enum.Font.Gotham, TextSize=10,
            TextColor3=C.TEXT_SOFT, ZIndex=94,
        }, BadgeRow)
        Corner(10, B)
        Stroke(1, C.PURPLE_DIM, B)
        Padding(0,8,0,8,B)
    end

    -- Separador
    local Sep = MakeFrame({
        Size=UDim2.new(0.8,0,0,1), Position=UDim2.new(0.1,0,0,226),
        BackgroundColor3=C.BORDER, ZIndex=93,
    }, Panel)
    Gradient(C.BG_DEEP, C.BORDER_BRIGHT, 0, Sep)

    -- Label "API KEY"
    MakeLabel({
        Size=UDim2.new(1,-40,0,18), Position=UDim2.new(0,20,0,240),
        BackgroundTransparency=1, Text="OPENROUTER API KEY",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.PURPLE_GLOW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=93,
    }, Panel)

    -- Input de API Key
    local KeyBox = MakeBox({
        Size=UDim2.new(1,-40,0,52), Position=UDim2.new(0,20,0,262),
        BackgroundColor3=Color3.fromRGB(10,8,28), BorderSizePixel=0,
        Text="", PlaceholderText="sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxx",
        Font=Enum.Font.Code, TextSize=13, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=94,
    }, Panel)
    Corner(12, KeyBox)
    local kbs = Stroke(2, C.BORDER, KeyBox)
    Padding(0,16,0,16,KeyBox)

    KeyBox.Focused:Connect(function() Tween(kbs, TI_FAST, {Color=C.PURPLE_NEON}) end)
    KeyBox.FocusLost:Connect(function() Tween(kbs, TI_FAST, {Color=C.BORDER}) end)

    -- Status label
    local StatusLabel = MakeLabel({
        Size=UDim2.new(1,-40,0,22), Position=UDim2.new(0,20,0,322),
        BackgroundTransparency=1, Text="",
        Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.TEXT_MUTED,
        TextWrapped=true, ZIndex=93,
    }, Panel)

    -- Spinner de carga
    local Spinner = MakeLabel({
        Size=UDim2.new(0,32,0,32), Position=UDim2.new(0.5,-16,0,332),
        BackgroundTransparency=1, Text="◌", Font=Enum.Font.GothamBold,
        TextSize=26, TextColor3=C.CYAN_NEON, Visible=false, ZIndex=95,
    }, Panel)

    -- Botón VERIFICAR API
    local LoginBtn = MakeButton({
        Size=UDim2.new(1,-40,0,52), Position=UDim2.new(0,20,0,350),
        BackgroundColor3=C.PURPLE_NEON, BorderSizePixel=0,
        Text="⚡  VERIFICAR API KEY",
        Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.new(1,1,1), ZIndex=94,
    }, Panel)
    Corner(14, LoginBtn)
    Gradient(Color3.fromRGB(130,20,210), Color3.fromRGB(80,0,180), 135, LoginBtn)

    LoginBtn.MouseEnter:Connect(function()
        Tween(LoginBtn, TI_FAST, {BackgroundColor3=C.PURPLE_GLOW})
        Tween(LoginBtn, TI_FAST, {Size=UDim2.new(1,-36,0,52)})
    end)
    LoginBtn.MouseLeave:Connect(function()
        Tween(LoginBtn, TI_FAST, {BackgroundColor3=C.PURPLE_NEON})
        Tween(LoginBtn, TI_FAST, {Size=UDim2.new(1,-40,0,52)})
    end)

    -- Separador 2
    MakeFrame({
        Size=UDim2.new(0.7,0,0,1), Position=UDim2.new(0.15,0,0,414),
        BackgroundColor3=C.BORDER, ZIndex=93,
    }, Panel)

    -- Botón OBTENER API KEY
    local GetKeyBtn = MakeButton({
        Size=UDim2.new(1,-40,0,40), Position=UDim2.new(0,20,0,422),
        BackgroundColor3=Color3.fromRGB(14,12,35), BorderSizePixel=0,
        Text="🔑  Obtener API Key de OpenRouter →",
        Font=Enum.Font.GothamSemibold, TextSize=13, TextColor3=C.CYAN_NEON, ZIndex=94,
    }, Panel)
    Corner(12, GetKeyBtn)
    Stroke(1, C.CYAN_DIM, GetKeyBtn)

    GetKeyBtn.MouseEnter:Connect(function()
        Tween(GetKeyBtn, TI_FAST, {BackgroundColor3=Color3.fromRGB(0,30,50)})
        Tween(GetKeyBtn, TI_FAST, {TextColor3=C.TEXT_WHITE})
    end)
    GetKeyBtn.MouseLeave:Connect(function()
        Tween(GetKeyBtn, TI_FAST, {BackgroundColor3=Color3.fromRGB(14,12,35)})
        Tween(GetKeyBtn, TI_FAST, {TextColor3=C.CYAN_NEON})
    end)

    -- Al hacer clic en "Obtener API Key" intentamos abrir la URL
    GetKeyBtn.MouseButton1Click:Connect(function()
        -- En Delta executor intentamos abrir la URL
        pcall(function()
            local ok = pcall(function() setclipboard("https://openrouter.ai/keys") end)
        end)
        StatusLabel.Text = "💡 Ve a: openrouter.ai/keys — Link copiado al portapapeles"
        StatusLabel.TextColor3 = C.CYAN_NEON
    end)

    -- Footer info
    MakeLabel({
        Size=UDim2.new(1,-40,0,18), Position=UDim2.new(0,20,0,472),
        BackgroundTransparency=1,
        Text="🔒 Tu key se usa solo para llamadas de IA · No se almacena",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=93,
    }, Panel)

    MakeLabel({
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-22),
        BackgroundTransparency=1,
        Text="LXNDXN Quantum OS  ·  Delta Edition  ·  v3.0  ·  Multi-Agent AI",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED, ZIndex=93,
    }, Panel)

    -- ─── Función de verificación ──────────────────────────────────────────────
    local function DoVerify()
        local key = KeyBox.Text:gsub("%s+","")
        if key == "" then
            StatusLabel.Text = "⚠ Por favor introduce tu API Key de OpenRouter."
            StatusLabel.TextColor3 = C.TEXT_YELLOW
            Tween(KeyBox, TI_FAST, {BackgroundColor3=Color3.fromRGB(30,15,10)})
            task.wait(0.6); Tween(KeyBox, TI_FAST, {BackgroundColor3=Color3.fromRGB(10,8,28)})
            return
        end

        LoginBtn.Visible  = false
        Spinner.Visible   = true
        StatusLabel.Text  = "Conectando con OpenRouter AI..."
        StatusLabel.TextColor3 = C.CYAN_NEON

        -- Animación spinner
        local spinActive = true
        task.spawn(function()
            local icons = {"◌","◍","◎","●","◎","◍"}
            local i = 1
            while spinActive do
                Spinner.Text = icons[i]; i = i % #icons + 1; task.wait(0.1)
            end
        end)

        -- Verificar la key real
        VerifyAPIKey(key, function(success, resp)
            spinActive  = false
            Spinner.Visible  = false
            LoginBtn.Visible = true

            if success then
                ENV.QuantumOS_OpenRouterKey = key
                StatusLabel.Text = "✓ API Key verificada · Conexión establecida con OpenRouter"
                StatusLabel.TextColor3 = C.TEXT_GREEN
                Tween(LoginBtn, TI_FAST, {BackgroundColor3=C.TOGGLE_ON})
                LoginBtn.Text = "✓  CONECTADO"
                task.wait(1.0)

                -- Fade out login → pantalla de selección de dispositivo
                Tween(Login, TI_MED, {BackgroundTransparency=1})
                task.wait(0.4)
                Login:Destroy()
                onSuccess()
            else
                StatusLabel.Text = "✗ API Key inválida o sin conexión. Verifica tu key."
                StatusLabel.TextColor3 = C.TEXT_RED
                -- Shake del panel
                for _ = 1, 5 do
                    Tween(Panel, TI_FAST, {Position=UDim2.new(0.5,-215,0.5,-290)}); task.wait(0.06)
                    Tween(Panel, TI_FAST, {Position=UDim2.new(0.5,-205,0.5,-290)}); task.wait(0.06)
                end
                Tween(Panel, TI_FAST, {Position=UDim2.new(0.5,-210,0.5,-290)})
            end
        end)
    end

    LoginBtn.MouseButton1Click:Connect(DoVerify)
    KeyBox.FocusLost:Connect(function(enter) if enter then DoVerify() end end)

    LoginScreenRef = Login
    return Login
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 9 - DEVICE SELECTION SCREEN (después del login)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateDeviceSelectionScreen(onSelect)
    local DS = MakeFrame({
        Name="DeviceSelect", Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG_DEEP, ZIndex=90,
    }, ScreenGui)
    Gradient(Color3.fromRGB(4,2,14), Color3.fromRGB(10,4,30), 135, DS)

    -- Partículas
    for i = 1, 12 do
        local size = math.random(2,5)
        local px = MakeFrame({
            Size=UDim2.new(0,size,0,size),
            Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
            BackgroundColor3=(i%2==0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency=0.5, ZIndex=91,
        }, DS)
        Corner(size, px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px, TweenInfo.new(3+math.random()*4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
                    BackgroundTransparency=0.1+math.random()*0.8
                })
                task.wait(3+math.random()*4)
            end
        end)
    end

    -- Panel central
    local DPanel = MakeFrame({
        Size=UDim2.new(0,460,0,460), Position=UDim2.new(0.5,-230,0.5,-230),
        BackgroundColor3=Color3.fromRGB(12,10,32), BackgroundTransparency=0.1, ZIndex=92,
    }, DS)
    Corner(28, DPanel)
    local dps = Stroke(2, C.PURPLE_NEON, DPanel)
    PulseStroke(dps, C.PURPLE_DIM, C.PURPLE_GLOW)

    -- Animación de entrada
    DPanel.Position = UDim2.new(0.5,-230,1.2,0)
    Tween(DPanel, TI_BOUNCE, {Position=UDim2.new(0.5,-230,0.5,-230)})

    -- Icono de éxito
    local CheckIcon = MakeLabel({
        Size=UDim2.new(0,64,0,64), Position=UDim2.new(0.5,-32,0,28),
        BackgroundColor3=Color3.fromRGB(0,40,20), BackgroundTransparency=0.2,
        Text="✓", Font=Enum.Font.GothamBold, TextSize=36, TextColor3=C.TEXT_GREEN, ZIndex=93,
    }, DPanel)
    Corner(32, CheckIcon)
    Stroke(2, C.TEXT_GREEN, CheckIcon)

    -- Título
    MakeLabel({
        Size=UDim2.new(1,0,0,32), Position=UDim2.new(0,0,0,104),
        BackgroundTransparency=1, Text="✓  Conexión Establecida",
        Font=Enum.Font.GothamBold, TextSize=22, TextColor3=C.TEXT_GREEN, ZIndex=93,
    }, DPanel)

    MakeLabel({
        Size=UDim2.new(1,-40,0,18), Position=UDim2.new(0,20,0,140),
        BackgroundTransparency=1, Text="OpenRouter Multi-Agent AI conectado · Selecciona tu dispositivo",
        Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.TEXT_SOFT, ZIndex=93,
    }, DPanel)

    -- Separador
    MakeFrame({
        Size=UDim2.new(0.8,0,0,1), Position=UDim2.new(0.1,0,0,168),
        BackgroundColor3=C.BORDER, ZIndex=93,
    }, DPanel)

    MakeLabel({
        Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0,178),
        BackgroundTransparency=1, Text="SELECCIONA TU DISPOSITIVO",
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.PURPLE_GLOW, ZIndex=93,
    }, DPanel)

    -- ─── Botón MÓVIL ─────────────────────────────────────────────────────────
    local MobileBtn = MakeButton({
        Size=UDim2.new(1,-40,0,90), Position=UDim2.new(0,20,0,206),
        BackgroundColor3=Color3.fromRGB(14,10,38), BorderSizePixel=0,
        Text="", ZIndex=93,
    }, DPanel)
    Corner(18, MobileBtn)
    Stroke(2, C.PURPLE_DIM, MobileBtn)

    MakeLabel({Size=UDim2.new(0,60,0,60), Position=UDim2.new(0,16,0.5,-30),
        BackgroundColor3=C.PURPLE_DIM, BackgroundTransparency=0.3,
        Text="📱", TextSize=32, ZIndex=94}, MobileBtn)
    Corner(14, MobileBtn:FindFirstChildWhichIsA("Frame") or Instance.new("Frame"))

    MakeLabel({
        Size=UDim2.new(1,-100,0,28), Position=UDim2.new(0,86,0,18),
        BackgroundTransparency=1, Text="📱  MÓVIL",
        Font=Enum.Font.GothamBold, TextSize=20, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=94,
    }, MobileBtn)
    MakeLabel({
        Size=UDim2.new(1,-100,0,20), Position=UDim2.new(0,86,0,48),
        BackgroundTransparency=1, Text="UI adaptada para pantalla táctil · Botones grandes",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=94,
    }, MobileBtn)

    MobileBtn.MouseEnter:Connect(function()
        Tween(MobileBtn, TI_FAST, {BackgroundColor3=Color3.fromRGB(40,15,90)})
        Stroke(2, C.PURPLE_NEON, MobileBtn)
    end)
    MobileBtn.MouseLeave:Connect(function()
        Tween(MobileBtn, TI_FAST, {BackgroundColor3=Color3.fromRGB(14,10,38)})
    end)

    -- ─── Botón PC ─────────────────────────────────────────────────────────────
    local PCBtn = MakeButton({
        Size=UDim2.new(1,-40,0,90), Position=UDim2.new(0,20,0,308),
        BackgroundColor3=Color3.fromRGB(14,10,38), BorderSizePixel=0,
        Text="", ZIndex=93,
    }, DPanel)
    Corner(18, PCBtn)
    Stroke(2, C.CYAN_DIM, PCBtn)

    MakeLabel({Size=UDim2.new(0,60,0,60), Position=UDim2.new(0,16,0.5,-30),
        BackgroundColor3=C.CYAN_DIM, BackgroundTransparency=0.5,
        Text="🖥", TextSize=32, ZIndex=94}, PCBtn)

    MakeLabel({
        Size=UDim2.new(1,-100,0,28), Position=UDim2.new(0,86,0,18),
        BackgroundTransparency=1, Text="🖥  PC / ESCRITORIO",
        Font=Enum.Font.GothamBold, TextSize=20, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=94,
    }, PCBtn)
    MakeLabel({
        Size=UDim2.new(1,-100,0,20), Position=UDim2.new(0,86,0,48),
        BackgroundTransparency=1, Text="UI completa con sidebar · Atajos de teclado F1–F8",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=94,
    }, PCBtn)

    PCBtn.MouseEnter:Connect(function()
        Tween(PCBtn, TI_FAST, {BackgroundColor3=Color3.fromRGB(0,30,50)})
        Stroke(2, C.CYAN_NEON, PCBtn)
    end)
    PCBtn.MouseLeave:Connect(function()
        Tween(PCBtn, TI_FAST, {BackgroundColor3=Color3.fromRGB(14,10,38)})
    end)

    -- Footer
    MakeLabel({
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-22),
        BackgroundTransparency=1,
        Text="Puedes cambiar esto más tarde en Ajustes",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED, ZIndex=92,
    }, DPanel)

    local function SelectDevice(mode)
        ENV.QuantumOS_DeviceMode  = mode
        ENV.QuantumOS_Unlocked    = true
        Tween(DS, TI_MED, {BackgroundTransparency=1})
        task.wait(0.4)
        DS:Destroy()
        onSelect(mode)
    end

    MobileBtn.MouseButton1Click:Connect(function() SelectDevice("mobile") end)
    PCBtn.MouseButton1Click:Connect(function()     SelectDevice("pc")     end)

    return DS
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 10 - VENTANA PRINCIPAL DEL OS
-- ═══════════════════════════════════════════════════════════════════════════════

local MainWindow = nil
local Sidebar    = nil
local ContentArea= nil
local CurrentTabFrame = nil

local function ClearContent()
    if CurrentTabFrame then CurrentTabFrame:Destroy(); CurrentTabFrame = nil end
end

local SidebarButtons = {}

local function SetActiveTab(name)
    for tabName, btn in pairs(SidebarButtons) do
        local isActive = (tabName == name)
        Tween(btn, TI_FAST, {BackgroundColor3=isActive and C.PURPLE_DIM or Color3.fromRGB(0,0,0)})
        Tween(btn, TI_FAST, {BackgroundTransparency=isActive and 0 or 1})
        local indicator = btn:FindFirstChild("Indicator")
        if indicator then indicator.Visible = isActive end
    end
end

local function CreateMainWindow()
    MainWindow = MakeFrame({
        Name="MainWindow", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=10,
    }, ScreenGui)

    -- ─── HEADER ───────────────────────────────────────────────────────────────
    local Header = MakeFrame({
        Name="Header", Size=UDim2.new(1,0,0,56),
        BackgroundColor3=C.BG_HEADER, ZIndex=12,
    }, MainWindow)
    Stroke(1, C.BORDER, Header)
    Gradient(C.BG_HEADER, Color3.fromRGB(8,6,20), 90, Header)

    local HeaderLogo = MakeLabel({
        Size=UDim2.new(0,38,0,38), Position=UDim2.new(0,14,0.5,-19),
        BackgroundTransparency=1, Text="⬡", Font=Enum.Font.GothamBold,
        TextSize=32, TextColor3=C.PURPLE_NEON, ZIndex=13,
    }, Header)
    task.spawn(function()
        while HeaderLogo and HeaderLogo.Parent do
            Tween(HeaderLogo, TI_SINE, {TextColor3=C.CYAN_NEON}); task.wait(1.5)
            Tween(HeaderLogo, TI_SINE, {TextColor3=C.PURPLE_NEON}); task.wait(1.5)
        end
    end)

    MakeLabel({
        Size=UDim2.new(0,200,0,22), Position=UDim2.new(0,56,0,8),
        BackgroundTransparency=1, Text="QUANTUM OS  v3.0",
        Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    }, Header)

    MakeLabel({
        Size=UDim2.new(0,200,0,16), Position=UDim2.new(0,56,0,30),
        BackgroundTransparency=1, Text="Multi-Agent AI · Delta Executor",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    }, Header)

    -- Badge del juego (centro)
    local GameBadge = MakeLabel({
        Size=UDim2.new(0,220,0,30), Position=UDim2.new(0.5,-110,0.5,-15),
        BackgroundColor3=C.BG_CARD, Text="🎮  " .. GAME_NAME,
        Font=Enum.Font.Gotham, TextSize=12, TextColor3=C.TEXT_SOFT, ZIndex=13,
    }, Header)
    Corner(15, GameBadge)
    Stroke(1, C.BORDER, GameBadge)

    -- Botones sistema (derecha)
    local SysFrame = MakeFrame({
        Size=UDim2.new(0,148,0,40), Position=UDim2.new(1,-158,0.5,-20),
        BackgroundTransparency=1, ZIndex=13,
    }, Header)

    local function SysBtn(icon, color, xOff)
        local b = MakeButton({
            Size=UDim2.new(0,34,0,34), Position=UDim2.new(0,xOff,0.5,-17),
            BackgroundColor3=Color3.fromRGB(18,15,38), Text=icon,
            Font=Enum.Font.GothamBold, TextSize=14, TextColor3=color, ZIndex=14,
        }, SysFrame)
        Corner(10, b)
        HoverGlow(b, Color3.fromRGB(18,15,38), Color3.fromRGB(38,28,68))
        return b
    end

    local WifiBtn  = SysBtn("⚡", C.TEXT_GREEN,  0)
    local NotifBtn = SysBtn("🔔", C.TEXT_YELLOW, 38)
    local MinBtn   = SysBtn("—",  C.TEXT_SOFT,   76)
    local CloseBtn = SysBtn("✕", C.TEXT_RED,    114)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow, TI_MED, {Size=UDim2.new(0,0,0,0)})
        task.wait(0.35); ScreenGui:Destroy()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        if MainWindow.Size.Y.Scale > 0 then
            Tween(MainWindow, TI_MED, {Size=UDim2.new(1,0,0,56)})
        else
            Tween(MainWindow, TI_MED, {Size=UDim2.fromScale(1,1)})
        end
    end)

    -- ─── SIDEBAR ──────────────────────────────────────────────────────────────
    Sidebar = MakeFrame({
        Name="Sidebar", Size=UDim2.new(0,210,1,-56), Position=UDim2.new(0,0,0,56),
        BackgroundColor3=C.BG_SIDEBAR, ZIndex=11,
    }, MainWindow)
    Stroke(1, C.BORDER, Sidebar)

    -- Perfil
    local SbProfile = MakeFrame({
        Size=UDim2.new(1,-16,0,72), Position=UDim2.new(0,8,0,10),
        BackgroundColor3=C.BG_CARD, ZIndex=12,
    }, Sidebar)
    Corner(14, SbProfile)
    Stroke(1, C.PURPLE_DIM, SbProfile)
    Gradient(C.BG_CARD, Color3.fromRGB(20,10,50), 135, SbProfile)

    local AvatarIcon = MakeLabel({
        Size=UDim2.new(0,46,0,46), Position=UDim2.new(0,10,0.5,-23),
        BackgroundColor3=C.PURPLE_DIM, Text=string.upper(string.sub(DISPLAY_NAME,1,2)),
        Font=Enum.Font.GothamBold, TextSize=18, TextColor3=C.TEXT_WHITE, ZIndex=13,
    }, SbProfile)
    Corner(23, AvatarIcon)
    Stroke(2, C.PURPLE_NEON, AvatarIcon)

    MakeLabel({
        Size=UDim2.new(1,-66,0,20), Position=UDim2.new(0,64,0,12),
        BackgroundTransparency=1, Text=DISPLAY_NAME,
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    }, SbProfile)

    MakeLabel({
        Size=UDim2.new(1,-66,0,16), Position=UDim2.new(0,64,0,32),
        BackgroundTransparency=1, Text="@"..USERNAME,
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    }, SbProfile)

    local OnlineBadge = MakeLabel({
        Size=UDim2.new(0,72,0,16), Position=UDim2.new(0,64,0,50),
        BackgroundColor3=Color3.fromRGB(0,50,25), Text="● AI Online",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_GREEN, ZIndex=13,
    }, SbProfile)
    Corner(8, OnlineBadge)

    -- Scroll de tabs
    local SbScroll = MakeScroll({
        Size=UDim2.new(1,0,1,-94), Position=UDim2.new(0,0,0,92),
        BackgroundTransparency=1, ScrollBarThickness=0,
        ScrollingDirection=Enum.ScrollingDirection.Y, ZIndex=12,
    }, Sidebar)

    local SbList = MakeFrame({
        Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, ZIndex=12,
    }, SbScroll)
    ListLayout({Padding=UDim.new(0,2), SortOrder=Enum.SortOrder.LayoutOrder}, SbList)

    local TABS = {
        {name="START",            icon="⌂",  order=1},
        {name="SCRIPT HUB",       icon="⚡",  order=2},
        {name="SYSTEM SETTINGS",  icon="⚙",  order=3},
        {name="TOOLBOX",          icon="🛠",  order=4},
        {name="FILE MANAGER",     icon="📁",  order=5},
        {name="PROCESSES & LOGS", icon="📊",  order=6},
        {name="MEDIA CENTER",     icon="🎵",  order=7},
        {name="COMMUNITY",        icon="👥",  order=8},
        {name="QUANTUM ORACLE",   icon="🔮",  order=9},
        {name="GAME BOOSTER",     icon="🚀",  order=10},
        {name="SKIN CUSTOMIZER",  icon="🎨",  order=11},
        {name="POWER",            icon="⏻",   order=12},
    }

    for _, tab in ipairs(TABS) do
        local Btn = MakeButton({
            Name=tab.name, Size=UDim2.new(1,-12,0,42),
            BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=1,
            Text="", LayoutOrder=tab.order, ZIndex=13,
        }, SbList)
        Corner(10, Btn)
        Padding(0,8,0,8,Btn)

        local Indicator = MakeFrame({
            Name="Indicator", Size=UDim2.new(0,3,0.6,0), Position=UDim2.new(0,0,0.2,0),
            BackgroundColor3=C.PURPLE_NEON, Visible=false, ZIndex=14,
        }, Btn)
        Corner(2, Indicator)

        MakeLabel({
            Size=UDim2.new(0,28,1,0), Position=UDim2.new(0,12,0,0),
            BackgroundTransparency=1, Text=tab.icon,
            Font=Enum.Font.GothamBold, TextSize=18, TextColor3=C.TEXT_SOFT, ZIndex=14,
        }, Btn)

        MakeLabel({
            Size=UDim2.new(1,-46,1,0), Position=UDim2.new(0,44,0,0),
            BackgroundTransparency=1, Text=tab.name,
            Font=Enum.Font.GothamSemibold, TextSize=12, TextColor3=C.TEXT_SOFT,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14,
        }, Btn)

        SidebarButtons[tab.name] = Btn
        Btn.MouseButton1Click:Connect(function()
            ClearContent(); SetActiveTab(tab.name); ENV.QuantumOS_ActiveTab = tab.name
            local fnKey = "QOS_Tab_"..tab.name:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
            pcall(function() _G[fnKey]() end)
        end)
        HoverGlow(Btn, Color3.fromRGB(0,0,0), C.BG_GLASS)
    end

    local SbLayout = SbList:FindFirstChildWhichIsA("UIListLayout")
    SbLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SbList.Size = UDim2.new(1,0,0,SbLayout.AbsoluteContentSize.Y+8)
    end)

    -- ─── CONTENT AREA ─────────────────────────────────────────────────────────
    ContentArea = MakeFrame({
        Name="ContentArea", Size=UDim2.new(1,-210,1,-56), Position=UDim2.new(0,210,0,56),
        BackgroundColor3=C.BG_PANEL, ZIndex=11,
    }, MainWindow)

    -- Entrada animada
    MainWindow.Size = UDim2.new(0,0,0,0); MainWindow.Position = UDim2.new(0.5,0,0.5,0)
    Tween(MainWindow, TI_BOUNCE, {Size=UDim2.fromScale(1,1), Position=UDim2.fromScale(0,0)})
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 11 - COMPONENTES REUTILIZABLES
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateToggle(parent, label, defaultState, onChange)
    local Row = MakeFrame({Size=UDim2.new(1,0,0,42), BackgroundColor3=C.BG_CARD, ZIndex=20}, parent)
    Corner(10, Row)
    MakeLabel({
        Size=UDim2.new(1,-70,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text=label, Font=Enum.Font.Gotham,
        TextSize=13, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21,
    }, Row)
    local Track = MakeFrame({
        Size=UDim2.new(0,46,0,24), Position=UDim2.new(1,-58,0.5,-12),
        BackgroundColor3=defaultState and C.TOGGLE_ON or C.TOGGLE_OFF, ZIndex=21,
    }, Row)
    Corner(12, Track)
    local Thumb = MakeFrame({
        Size=UDim2.new(0,18,0,18),
        Position=defaultState and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=Color3.new(1,1,1), ZIndex=22,
    }, Track)
    Corner(9, Thumb)
    local state = defaultState
    local ToggleBtn = MakeButton({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", ZIndex=23}, Track)
    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        Tween(Track, TI_FAST, {BackgroundColor3=state and C.TOGGLE_ON or C.TOGGLE_OFF})
        Tween(Thumb, TI_FAST, {Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if onChange then onChange(state) end
    end)
    return Row, function() return state end
end

local function CreateSlider(parent, label, minV, maxV, defaultV, suffix, onChange)
    local Row = MakeFrame({Size=UDim2.new(1,0,0,60), BackgroundColor3=C.BG_CARD, ZIndex=20}, parent)
    Corner(10, Row)
    MakeLabel({
        Size=UDim2.new(1,-60,0,22), Position=UDim2.new(0,14,0,6),
        BackgroundTransparency=1, Text=label, Font=Enum.Font.Gotham,
        TextSize=13, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21,
    }, Row)
    local ValLabel = MakeLabel({
        Size=UDim2.new(0,55,0,22), Position=UDim2.new(1,-65,0,6),
        BackgroundTransparency=1, Text=tostring(defaultV)..(suffix or ""),
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.PURPLE_GLOW,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=21,
    }, Row)
    local Track = MakeFrame({
        Size=UDim2.new(1,-28,0,6), Position=UDim2.new(0,14,0,40),
        BackgroundColor3=C.SLIDER_BG, ZIndex=21,
    }, Row)
    Corner(3, Track)
    local ratio = (defaultV-minV)/(maxV-minV)
    local Fill = MakeFrame({Size=UDim2.new(ratio,0,1,0), BackgroundColor3=C.SLIDER_FILL, ZIndex=22}, Track)
    Corner(3, Fill); Gradient(C.PURPLE_NEON, C.CYAN_NEON, 0, Fill)
    local Knob = MakeFrame({
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(ratio,-8,0.5,-8),
        BackgroundColor3=Color3.new(1,1,1), ZIndex=23,
    }, Track)
    Corner(8, Knob); Stroke(2, C.PURPLE_NEON, Knob)

    local dragging = false
    local function UpdateSlider(inputX)
        local t = math.clamp((inputX-Track.AbsolutePosition.X)/Track.AbsoluteSize.X, 0, 1)
        local value = math.floor(minV+t*(maxV-minV))
        Tween(Fill,TI_FAST,{Size=UDim2.new(t,0,1,0)}); Tween(Knob,TI_FAST,{Position=UDim2.new(t,-8,0.5,-8)})
        ValLabel.Text = tostring(value)..(suffix or ""); if onChange then onChange(value) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; UpdateSlider(input.Position.X)
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            UpdateSlider(input.Position.X)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end))
    return Row
end

local function SectionHeader(parent, title, subtitle)
    local H = MakeFrame({Size=UDim2.new(1,0,0,62), BackgroundColor3=C.BG_HEADER, ZIndex=19}, parent)
    Stroke(1, C.BORDER, H)
    local AccentLine = MakeFrame({
        Size=UDim2.new(0,3,0,38), Position=UDim2.new(0,8,0,12),
        BackgroundColor3=C.PURPLE_NEON, ZIndex=20,
    }, H)
    Corner(2, AccentLine)
    MakeLabel({
        Size=UDim2.new(1,-24,0,28), Position=UDim2.new(0,20,0,8),
        BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamBold,
        TextSize=18, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=20,
    }, H)
    if subtitle then
        MakeLabel({
            Size=UDim2.new(1,-24,0,16), Position=UDim2.new(0,20,0,38),
            BackgroundTransparency=1, Text=subtitle, Font=Enum.Font.Gotham,
            TextSize=12, TextColor3=C.TEXT_MUTED, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=20,
        }, H)
    end
    return H
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 12 - SISTEMA DE NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

local NotifTypes = {
    INFO    = {icon="ℹ", color=C.CYAN_NEON,   bg=Color3.fromRGB(0,28,48)},
    SUCCESS = {icon="✓", color=C.TEXT_GREEN,   bg=Color3.fromRGB(0,38,18)},
    WARNING = {icon="⚠", color=C.TEXT_YELLOW, bg=Color3.fromRGB(48,32,0)},
    ERROR   = {icon="✕", color=C.TEXT_RED,     bg=Color3.fromRGB(58,0,0)},
    ORACLE  = {icon="🔮",color=C.PURPLE_GLOW,  bg=Color3.fromRGB(28,0,58)},
    SYSTEM  = {icon="⬡", color=C.PURPLE_NEON,  bg=Color3.fromRGB(18,4,42)},
    AI      = {icon="🤖",color=C.GOLD_NEON,    bg=Color3.fromRGB(40,30,0)},
}

local notifStack = {}
local NOTIF_MAX  = 4
local NOTIF_W    = 295
local NOTIF_H    = 70
local NOTIF_M    = 8

PushNotification = function(title, body, typeName, duration)
    typeName = typeName or "INFO"; duration = duration or 3.5
    local t  = NotifTypes[typeName] or NotifTypes.INFO
    if #notifStack >= NOTIF_MAX then return end
    local slot = #notifStack + 1
    table.insert(notifStack, slot)
    local yOff = -(slot*(NOTIF_H+NOTIF_M))

    local NFrame = MakeFrame({
        Name="Notif_"..slot, Size=UDim2.new(0,NOTIF_W,0,NOTIF_H),
        Position=UDim2.new(1,10,1,yOff), BackgroundColor3=t.bg, ZIndex=1100+slot,
    }, ScreenGui)
    Corner(14, NFrame); Stroke(1, t.color, NFrame)
    local Accent = MakeFrame({Size=UDim2.new(0,4,1,-16), Position=UDim2.new(0,0,0,8),
        BackgroundColor3=t.color, ZIndex=1101+slot}, NFrame)
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
    local ProgBG = MakeFrame({Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=C.SLIDER_BG, ZIndex=1103+slot}, NFrame)
    local ProgFill = MakeFrame({Size=UDim2.new(1,0,1,0), BackgroundColor3=t.color, ZIndex=1104+slot}, ProgBG)
    local CloseN = MakeButton({Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-26,0,4),
        BackgroundTransparency=1, Text="✕", Font=Enum.Font.GothamBold,
        TextSize=11, TextColor3=C.TEXT_MUTED, ZIndex=1105+slot}, NFrame)

    Tween(NFrame, TI_BOUNCE, {Position=UDim2.new(1,-(NOTIF_W+10),1,yOff)})
    Tween(ProgFill, TweenInfo.new(duration,Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,1,0)})

    local function DismissNotif()
        Tween(NFrame, TI_MED, {Position=UDim2.new(1,10,1,yOff)}); task.wait(0.35)
        pcall(function() table.remove(notifStack, table.find(notifStack,slot)); NFrame:Destroy() end)
    end
    CloseN.MouseButton1Click:Connect(DismissNotif)
    task.delay(duration, function() pcall(DismissNotif) end)
end

ShowToast = function(title, body, icon, duration)
    duration = duration or 3
    table.insert(toastQueue, {title=title, body=body, icon=icon or "⬡", duration=duration})
    if toastActive then return end
    toastActive = true
    task.spawn(function()
        while #toastQueue > 0 do
            local t = table.remove(toastQueue,1)
            local Toast = MakeFrame({
                Size=UDim2.new(0,285,0,68), Position=UDim2.new(1,10,1,-85),
                BackgroundColor3=C.BG_CARD, ZIndex=1000,
            }, ScreenGui)
            Corner(14, Toast); Stroke(2, C.PURPLE_NEON, Toast)
            MakeLabel({Size=UDim2.new(0,40,1,0), BackgroundTransparency=1, Text=t.icon, TextSize=22, ZIndex=1001}, Toast)
            MakeLabel({Size=UDim2.new(1,-55,0,20), Position=UDim2.new(0,44,0,10), BackgroundTransparency=1,
                Text=t.title, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TEXT_WHITE,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1001}, Toast)
            MakeLabel({Size=UDim2.new(1,-55,0,18), Position=UDim2.new(0,44,0,32), BackgroundTransparency=1,
                Text=t.body, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT,
                TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1001}, Toast)
            Tween(Toast, TI_MED, {Position=UDim2.new(1,-295,1,-85)})
            task.wait(t.duration)
            Tween(Toast, TI_MED, {Position=UDim2.new(1,10,1,-85)}); task.wait(0.4)
            Toast:Destroy(); task.wait(0.3)
        end
        toastActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 13 - TAB: START
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_START"] = function()
    local Tab = MakeFrame({Name="Tab_START", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    local Scroll = MakeScroll({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local List = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,0)}, List); Padding(0,0,20,0,List)
    SectionHeader(List, "START  ⌂", "Panel de inicio · Quantum OS v3.0 · Multi-Agent AI")

    -- Stats cards
    local StatsRow = MakeFrame({Size=UDim2.new(1,0,0,90), BackgroundTransparency=1, ZIndex=15}, List)
    local StatsItems = {
        {label="Jugador",   val=DISPLAY_NAME,     icon="👤", color=C.PURPLE_GLOW},
        {label="Juego",     val=GAME_NAME:sub(1,16), icon="🎮", color=C.CYAN_NEON},
        {label="AI Status", val="Online",         icon="🤖", color=C.TEXT_GREEN},
        {label="Agentes",   val="5 activos",      icon="⬡",  color=C.GOLD_NEON},
    }
    local SGrid = MakeFrame({Size=UDim2.new(1,-32,1,-16), Position=UDim2.new(0,16,0,8), BackgroundTransparency=1, ZIndex=15}, StatsRow)
    GridLayout({CellSize=UDim2.new(0.25,-4,1,-4), CellPadding=UDim2.new(0,4,0,4)}, SGrid)

    for _, stat in ipairs(StatsItems) do
        local Card = MakeFrame({BackgroundColor3=C.BG_CARD, ZIndex=16}, SGrid)
        Corner(12, Card); Stroke(1, C.BORDER, Card); Gradient(C.BG_CARD, Color3.fromRGB(18,10,40), 135, Card)
        MakeLabel({Size=UDim2.new(1,0,0,26), Position=UDim2.new(0,0,0,10), BackgroundTransparency=1,
            Text=stat.icon, TextSize=20, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,20), Position=UDim2.new(0,4,0,36), BackgroundTransparency=1,
            Text=stat.val, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=stat.color, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-8,0,14), Position=UDim2.new(0,4,0,57), BackgroundTransparency=1,
            Text=stat.label, Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_MUTED, ZIndex=17}, Card)
    end

    -- Agentes status
    local AgentHdr = MakeLabel({Size=UDim2.new(1,-32,0,20), BackgroundTransparency=1,
        Text="AGENTES MULTI-IA ACTIVOS", Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=C.PURPLE_GLOW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=15}, List)

    local agentsInfo = {
        {key="ORCHESTRATOR", icon="⬡", name="Orquestador",     model="llama-3.3-70b", desc="Dirige el flujo multi-agente"},
        {key="GAME_ANALYST",   icon="🎮", name="Game Analyst",    model="nemotron-120b",  desc="Análisis del juego actual"},
        {key="CODE_EXPERT",    icon="💻", name="Code Expert",     model="qwen3-coder",    desc="Scripts y código Lua"},
        {key="STRATEGY_AGENT", icon="⚔", name="Strategy Agent",  model="deepseek-v4",    desc="Estrategias y builds"},
        {key="CREATIVE_AGENT", icon="🎨", name="Creative Agent",  model="gemma-4-31b",    desc="Ideas y personalización"},
    }

    local AgentList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, List)
    ListLayout({Padding=UDim.new(0,4)}, AgentList); Padding(0,16,0,16,AgentList)

    for _, ag in ipairs(agentsInfo) do
        local ACard = MakeFrame({Size=UDim2.new(1,0,0,52), BackgroundColor3=C.BG_CARD, ZIndex=16}, AgentList)
        Corner(10, ACard); Stroke(1, C.BORDER, ACard)
        MakeLabel({Size=UDim2.new(0,38,0,38), Position=UDim2.new(0,10,0.5,-19),
            BackgroundColor3=C.PURPLE_DIM, BackgroundTransparency=0.5,
            Text=ag.icon, TextSize=20, ZIndex=17}, ACard)
        MakeLabel({Size=UDim2.new(1,-180,0,20), Position=UDim2.new(0,56,0,8),
            BackgroundTransparency=1, Text=ag.name, Font=Enum.Font.GothamBold,
            TextSize=13, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, ACard)
        MakeLabel({Size=UDim2.new(1,-180,0,16), Position=UDim2.new(0,56,0,28),
            BackgroundTransparency=1, Text=ag.desc, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.TEXT_MUTED, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, ACard)
        local StatusBadge = MakeLabel({Size=UDim2.new(0,90,0,22), Position=UDim2.new(1,-100,0.5,-11),
            BackgroundColor3=Color3.fromRGB(0,40,20), Text="● "..ag.model,
            Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TEXT_GREEN, ZIndex=17}, ACard)
        Corner(10, StatusBadge)
    end

    local LL = List:FindFirstChildWhichIsA("UIListLayout")
    if LL then LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+20)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 14 - TAB: QUANTUM ORACLE (Multi-Agent AI Chat)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_QUANTUM_ORACLE"] = function()
    local Tab = MakeFrame({Name="Tab_ORACLE", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "QUANTUM ORACLE  🔮", "Multi-Agent AI · Orquestador: llama-3.3-70b · Juego: "..GAME_NAME)

    -- Orb visual
    local SphereFrame = MakeFrame({
        Size=UDim2.new(1,-32,0,110), Position=UDim2.new(0,16,0,68),
        BackgroundColor3=C.BG_GLASS, ZIndex=16,
    }, Tab)
    Corner(16, SphereFrame); Gradient(C.BG_GLASS, Color3.fromRGB(40,0,80), 135, SphereFrame)
    Stroke(1, C.BORDER_BRIGHT, SphereFrame)

    local Orb = MakeLabel({
        Size=UDim2.new(0,70,0,70), Position=UDim2.new(0,18,0.5,-35),
        BackgroundColor3=C.PURPLE_DIM, Text="🔮", TextSize=34, ZIndex=17,
    }, SphereFrame)
    Corner(35, Orb); Stroke(3, C.PURPLE_NEON, Orb)
    task.spawn(function()
        while Orb and Orb.Parent do
            Tween(Orb, TI_SINE, {BackgroundColor3=C.PURPLE_GLOW}); task.wait(1.2)
            Tween(Orb, TI_SINE, {BackgroundColor3=C.PURPLE_DIM});  task.wait(1.2)
        end
    end)

    local OracleName = MakeLabel({Size=UDim2.new(1,-120,0,24), Position=UDim2.new(0,100,0,14),
        BackgroundTransparency=1, Text="QUANTUM ORACLE  ·  Multi-Agent AI",
        Font=Enum.Font.GothamBold, TextSize=15, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, SphereFrame)

    local AgentBadge = MakeLabel({Size=UDim2.new(1,-120,0,18), Position=UDim2.new(0,100,0,40),
        BackgroundTransparency=1, Text="⬡ Orquestador: llama-3.3-70b  ·  5 Agentes listos",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, SphereFrame)

    local ActiveAgentLabel = MakeLabel({Size=UDim2.new(1,-120,0,16), Position=UDim2.new(0,100,0,62),
        BackgroundTransparency=1, Text="Detectado: '"..GAME_NAME.."'  ·  En espera de consulta",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, SphereFrame)

    -- Chat scroll
    local ChatScroll = MakeScroll({
        Size=UDim2.new(1,-32,1,-260), Position=UDim2.new(0,16,0,188),
        BackgroundColor3=Color3.fromRGB(5,5,14), ScrollBarThickness=3, ZIndex=15,
    }, Tab)
    Corner(12, ChatScroll); Stroke(1, C.BORDER, ChatScroll)

    local ChatList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ChatScroll)
    ListLayout({Padding=UDim.new(0,8)}, ChatList); Padding(10,10,10,10,ChatList)

    local function AddMsg(text, isUser, agentMeta)
        local color = isUser and C.PURPLE_DIM or (agentMeta and agentMeta.color or C.BG_CARD)
        local Bubble = MakeFrame({
            Size=UDim2.new(0.85,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            Position=isUser and UDim2.new(0.15,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3=color, BackgroundTransparency=isUser and 0 or 0.2, ZIndex=16,
        }, ChatList)
        Corner(12, Bubble); Padding(10,14,10,14,Bubble)

        -- Badge del agente (si no es usuario)
        if not isUser and agentMeta then
            local ABadge = MakeLabel({
                Size=UDim2.new(1,0,0,16), BackgroundTransparency=1,
                Text=agentMeta.icon.." "..agentMeta.name,
                Font=Enum.Font.GothamBold, TextSize=10,
                TextColor3=agentMeta.color, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17,
            }, Bubble)
        end

        local yOffset = (not isUser and agentMeta) and 20 or 0
        MakeLabel({
            Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,yOffset),
            AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Text=text, Font=Enum.Font.Gotham,
            TextSize=12, TextColor3=C.TEXT_WHITE, TextWrapped=true,
            TextXAlignment=isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left, ZIndex=17,
        }, Bubble)

        task.wait(0.05)
        ChatScroll.CanvasSize = UDim2.new(0,0,0,ChatList.AbsoluteContentSize.Y+20)
        ChatScroll.CanvasPosition = Vector2.new(0, ChatList.AbsoluteContentSize.Y)
    end

    -- Función de "pensando..."
    local ThinkBubble = nil
    local function ShowThinking(text)
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end) end
        ThinkBubble = MakeFrame({
            Size=UDim2.new(0.5,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=C.BG_CARD, BackgroundTransparency=0.3, ZIndex=16,
        }, ChatList)
        Corner(12, ThinkBubble); Padding(8,12,8,12,ThinkBubble)
        MakeLabel({
            Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1, Text="◌ "..text, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.TEXT_MUTED, TextWrapped=true, ZIndex=17,
        }, ThinkBubble)
        task.wait(0.05)
        ChatScroll.CanvasSize = UDim2.new(0,0,0,ChatList.AbsoluteContentSize.Y+20)
        ChatScroll.CanvasPosition = Vector2.new(0, ChatList.AbsoluteContentSize.Y)
    end

    local function HideThinking()
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end); ThinkBubble = nil end
    end

    -- Mensaje inicial
    AddMsg("🔮 Hola, "..DISPLAY_NAME.."! Soy el Quantum Oracle. Mi sistema Multi-Agent AI detectó: '"..GAME_NAME.."'.\n\nEl Orquestador (llama-3.3-70b) dirigirá tu consulta al agente más adecuado:\n🎮 Game Analyst · 💻 Code Expert · ⚔ Strategy · 🎨 Creative · ⚡ Fast\n\n¿En qué te ayudo?", false, {icon="🔮", name="Quantum Oracle", color=C.PURPLE_GLOW})

    -- Input del chat
    local InputRow = MakeFrame({
        Size=UDim2.new(1,-32,0,46), Position=UDim2.new(0,16,1,-60),
        BackgroundColor3=C.BG_CARD, ZIndex=16,
    }, Tab)
    Corner(14, InputRow); Stroke(1, C.BORDER, InputRow)

    local ChatInput = MakeBox({
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1, Text="", PlaceholderText="Pregunta algo al Oracle...",
        Font=Enum.Font.Gotham, TextSize=13, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ClearTextOnFocus=false, ZIndex=17,
    }, InputRow)

    local SendBtn = MakeButton({
        Size=UDim2.new(0,44,0,36), Position=UDim2.new(1,-50,0.5,-18),
        BackgroundColor3=C.PURPLE_NEON, Text="▶", Font=Enum.Font.GothamBold,
        TextSize=16, TextColor3=Color3.new(1,1,1), ZIndex=17,
    }, InputRow)
    Corner(10, SendBtn)

    local isWaiting = false

    local function SendMessage()
        if isWaiting then return end
        local msg = ChatInput.Text:gsub("^%s+",""):gsub("%s+$","")
        if msg == "" then return end
        ChatInput.Text = ""
        isWaiting = true
        SendBtn.Text = "◌"
        AddMsg(msg, true)

        OracleQuery(
            msg,
            function(thinkText)   -- onThink
                ShowThinking(thinkText)
                ActiveAgentLabel.Text = "⬡ "..thinkText
            end,
            function(agentKey, meta) -- onAgent
                ShowThinking(meta.icon.." "..meta.name.." respondiendo...")
                ActiveAgentLabel.Text = meta.icon.." Agente activo: "..meta.name
                AgentBadge.Text = meta.icon.." Usando: "..meta.name.."  ·  OpenRouter AI"
            end,
            function(response, meta) -- onResponse
                HideThinking()
                AddMsg(response, false, meta)
                isWaiting = false
                SendBtn.Text = "▶"
                ActiveAgentLabel.Text = "En espera de consulta"
                AgentBadge.Text = "⬡ Orquestador: llama-3.3-70b  ·  5 Agentes listos"
            end,
            function(errMsg)      -- onError
                HideThinking()
                AddMsg("❌ Error de conexión: "..tostring(errMsg).."\nVerifica tu API Key en Ajustes.", false, {icon="❌", name="Sistema", color=C.TEXT_RED})
                isWaiting = false; SendBtn.Text = "▶"
                ActiveAgentLabel.Text = "Error · Verifica conexión"
            end
        )
    end

    SendBtn.MouseButton1Click:Connect(SendMessage)
    ChatInput.FocusLost:Connect(function(enter) if enter then SendMessage() end end)

    -- Sugerencias rápidas
    local SuggestFrame = MakeFrame({
        Size=UDim2.new(1,-32,0,32), Position=UDim2.new(0,16,1,-100),
        BackgroundTransparency=1, ZIndex=16,
    }, Tab)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6)}, SuggestFrame)

    local suggestions = {"¿Mejores scripts?", "Script anti-ban", "¿Cómo farmear?", "Fix mi error Lua", "Estrategia rápida"}
    for _, sug in ipairs(suggestions) do
        local SB = MakeButton({
            Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.BG_CARD, Text=sug,
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.CYAN_NEON, ZIndex=17,
        }, SuggestFrame)
        Corner(10, SB); Padding(0,10,0,10,SB); Stroke(1, C.CYAN_DIM, SB)
        SB.MouseButton1Click:Connect(function() ChatInput.Text = sug end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 15 - TAB: SCRIPT HUB
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SCRIPT_HUB"] = function()
    local Tab = MakeFrame({Name="Tab_HUB", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "SCRIPT HUB  ⚡", "Scripts verificados para "..GAME_NAME)

    local SearchRow = MakeFrame({
        Size=UDim2.new(1,-32,0,40), Position=UDim2.new(0,16,0,70),
        BackgroundColor3=C.BG_CARD, ZIndex=15,
    }, Tab)
    Corner(12, SearchRow); Stroke(1, C.BORDER, SearchRow)
    local SBox = MakeBox({
        Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text="", PlaceholderText="🔍 Buscar scripts...",
        Font=Enum.Font.Gotham, TextSize=13, TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED, ZIndex=16,
    }, SearchRow)

    local ScriptScroll = MakeScroll({
        Size=UDim2.new(1,-32,1,-122), Position=UDim2.new(0,16,0,118),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15,
    }, Tab)
    local ScriptList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, ScriptScroll)
    ListLayout({Padding=UDim.new(0,8)}, ScriptList)

    local scripts = {
        {title="Auto Farm v5.2",        author="LXNDXN",     verified=true,  script="print('Auto Farm activado')"},
        {title="ESP Pro · All Players", author="QuantumDev", verified=true,  script="print('ESP activo')"},
        {title="Infinite Jump",         author="DeltaFarm",  verified=false, script="print('InfJump activo')"},
        {title="Speed Hack x10",        author="LXNDXN",     verified=true,  script="print('Speed x10')"},
        {title="God Mode Bypass",       author="NullSec",    verified=false, script="print('God Mode')"},
        {title="Auto Collect Items",    author="QuantumDev", verified=true,  script="print('AutoCollect')"},
    }

    for _, s in ipairs(scripts) do
        local Card = MakeFrame({Size=UDim2.new(1,0,0,80), BackgroundColor3=C.BG_CARD, ZIndex=16}, ScriptList)
        Corner(14, Card); Stroke(1, C.BORDER, Card)

        local Thumb = MakeFrame({Size=UDim2.new(0,54,0,54), Position=UDim2.new(0,12,0.5,-27),
            BackgroundColor3=C.PURPLE_DIM, ZIndex=17}, Card)
        Corner(12, Thumb)
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="⚡",
            Font=Enum.Font.GothamBold, TextSize=24, TextColor3=C.TEXT_WHITE, ZIndex=18}, Thumb)

        MakeLabel({Size=UDim2.new(1,-200,0,22), Position=UDim2.new(0,76,0,12),
            BackgroundTransparency=1, Text=s.title, Font=Enum.Font.GothamBold,
            TextSize=14, TextColor3=C.TEXT_WHITE, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)
        MakeLabel({Size=UDim2.new(1,-200,0,16), Position=UDim2.new(0,76,0,36),
            BackgroundTransparency=1, Text="by "..s.author, Font=Enum.Font.Gotham,
            TextSize=11, TextColor3=C.TEXT_SOFT, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, Card)

        if s.verified then
            local VBadge = MakeLabel({Size=UDim2.new(0,110,0,16), Position=UDim2.new(0,76,0,56),
                BackgroundColor3=Color3.fromRGB(0,44,22), Text="✓ Verificado Delta",
                Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TEXT_GREEN, ZIndex=18}, Card)
            Corner(8, VBadge)
        end

        local ExBtn = MakeButton({
            Size=UDim2.new(0,90,0,28), Position=UDim2.new(1,-172,0.5,-14),
            BackgroundColor3=C.PURPLE_NEON, Text="▶ EXECUTE",
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=Color3.new(1,1,1), ZIndex=17,
        }, Card)
        Corner(8, ExBtn)
        HoverGlow(ExBtn, C.PURPLE_NEON, C.PURPLE_GLOW)
        ExBtn.MouseButton1Click:Connect(function()
            pcall(function() loadstring(s.script)() end)
            PushNotification("Script Ejecutado", s.title.." activado correctamente.", "SUCCESS", 3)
        end)

        local SaveBtn = MakeButton({
            Size=UDim2.new(0,62,0,28), Position=UDim2.new(1,-70,0.5,-14),
            BackgroundColor3=C.BG_GLASS, Text="💾 SAVE",
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, ZIndex=17,
        }, Card)
        Corner(8, SaveBtn)

        local SL = ScriptList:FindFirstChildWhichIsA("UIListLayout")
        if SL then SL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ScriptScroll.CanvasSize = UDim2.new(0,0,0,SL.AbsoluteContentSize.Y+20)
        end) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 16 - TABS RESTANTES (Stubs funcionales)
-- ═══════════════════════════════════════════════════════════════════════════════

local function StubTab(name, icon, subtitle)
    return function()
        local Tab = MakeFrame({Name="Tab_"..name, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
        CurrentTabFrame = Tab
        SectionHeader(Tab, name.."  "..icon, subtitle)
        -- Placeholder
        local PlaceCard = MakeFrame({
            Size=UDim2.new(1,-32,0,120), Position=UDim2.new(0,16,0,80),
            BackgroundColor3=C.BG_CARD, ZIndex=15,
        }, Tab)
        Corner(14, PlaceCard); Stroke(1, C.BORDER, PlaceCard)
        MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=icon.."\n"..name,
            Font=Enum.Font.GothamBold, TextSize=20, TextColor3=C.TEXT_WHITE, ZIndex=16}, PlaceCard)
    end
end

_G["QOS_Tab_SYSTEM_SETTINGS"] = function()
    local Tab = MakeFrame({Name="Tab_SETTINGS", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "SYSTEM SETTINGS  ⚙", "Configuración del sistema · AI · Executor")

    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-65), Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local SList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,0)}, SList); Padding(12,16,20,16,SList)

    -- API Key info
    local KeyCard = MakeFrame({Size=UDim2.new(1,0,0,72), BackgroundColor3=C.BG_CARD, ZIndex=16}, SList)
    Corner(14, KeyCard); Stroke(1, C.BORDER, KeyCard)
    MakeLabel({Size=UDim2.new(1,-160,0,22), Position=UDim2.new(0,16,0,12),
        BackgroundTransparency=1, Text="OpenRouter API Key",
        Font=Enum.Font.GothamBold, TextSize=14, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KeyCard)
    local keyMasked = ENV.QuantumOS_OpenRouterKey and ("sk-or-..."..string.sub(ENV.QuantumOS_OpenRouterKey,-8)) or "No configurada"
    MakeLabel({Size=UDim2.new(1,-160,0,16), Position=UDim2.new(0,16,0,36),
        BackgroundTransparency=1, Text=keyMasked,
        Font=Enum.Font.Code, TextSize=11, TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, KeyCard)
    local KeyStatus = MakeLabel({Size=UDim2.new(0,90,0,22), Position=UDim2.new(1,-106,0.5,-11),
        BackgroundColor3=Color3.fromRGB(0,44,22), Text="● Conectada",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.TEXT_GREEN, ZIndex=17}, KeyCard)
    Corner(10, KeyStatus)

    -- Toggles de sistema
    local settingsToggles = {
        {"Notificaciones Toast",     true,  nil},
        {"Watermark del OS",         true,  nil},
        {"Panel lateral rápido",     true,  nil},
        {"Stats HUD en overlay",     false, nil},
        {"Animaciones de partículas",true,  nil},
        {"Anti-detección",           true,  nil},
    }
    for _, s in ipairs(settingsToggles) do CreateToggle(SList, s[1], s[2], s[3]) end

    -- Selector de dispositivo
    local DevLabel = MakeLabel({Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
        Text="MODO DE DISPOSITIVO: "..(ENV.QuantumOS_DeviceMode or "?"):upper(),
        Font=Enum.Font.GothamBold, TextSize=12, TextColor3=C.PURPLE_GLOW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=16}, SList)

    local LL2 = SList:FindFirstChildWhichIsA("UIListLayout")
    if LL2 then LL2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,LL2.AbsoluteContentSize.Y+20)
    end) end
end

_G["QOS_Tab_TOOLBOX"]           = StubTab("TOOLBOX",           "🛠", "Herramientas del executor")
_G["QOS_Tab_FILE_MANAGER"]      = StubTab("FILE MANAGER",      "📁", "Gestor de scripts locales y en la nube")
_G["QOS_Tab_PROCESSES___LOGS"]  = StubTab("PROCESSES & LOGS",  "📊", "Monitor de procesos en tiempo real")
_G["QOS_Tab_MEDIA_CENTER"]      = StubTab("MEDIA CENTER",      "🎵", "Reproductor y multimedia")
_G["QOS_Tab_COMMUNITY"]         = StubTab("COMMUNITY",         "👥", "Discord · Foro · Top Contributors")

_G["QOS_Tab_GAME_BOOSTER"] = function()
    local Tab = MakeFrame({Name="Tab_BOOSTER", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "GAME BOOSTER  🚀", "Optimización FPS y rendimiento para "..GAME_NAME)

    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-65), Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local C2 = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,0)}, C2); Padding(12,16,20,16,C2)

    local BoostCard = MakeFrame({Size=UDim2.new(1,0,0,94), BackgroundColor3=C.BG_GLASS, ZIndex=16}, C2)
    Corner(16, BoostCard); Gradient(Color3.fromRGB(10,5,30), Color3.fromRGB(60,0,100), 135, BoostCard)
    Stroke(2, C.PURPLE_NEON, BoostCard); Padding(16,16,16,16,BoostCard)
    MakeLabel({Size=UDim2.new(1,-120,0,24), BackgroundTransparency=1, Text="🚀 QUANTUM BOOST MODE",
        Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, BoostCard)
    MakeLabel({Size=UDim2.new(1,-120,0,30), Position=UDim2.new(0,0,0,28), BackgroundTransparency=1,
        Text="Elimina partículas, texturas innecesarias y reduce render distance para máximo FPS.",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TEXT_SOFT, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, BoostCard)
    local BoostBtn = MakeButton({
        Size=UDim2.new(0,90,0,38), Position=UDim2.new(1,-106,0.5,-19),
        BackgroundColor3=C.TOGGLE_ON, Text="ACTIVAR",
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=Color3.new(1,1,1), ZIndex=17,
    }, BoostCard)
    Corner(10, BoostBtn)
    local boosted = false
    BoostBtn.MouseButton1Click:Connect(function()
        boosted = not boosted; BoostBtn.Text = boosted and "ACTIVO ✓" or "ACTIVAR"
        BoostBtn.BackgroundColor3 = boosted and C.PURPLE_NEON or C.TOGGLE_ON
        if boosted then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled = false end
                    if v:IsA("SpecialMesh") then v.TextureId = "" end
                end
            end)
            PushNotification("Game Booster","Modo boost activado · FPS optimizado.","SUCCESS",3)
        end
    end)

    CreateToggle(C2, "Desactivar ParticleEmitters", false, function(s)
        for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") then v.Enabled=not s end end
    end)
    CreateToggle(C2, "Desactivar Sombras Dinámicas", false, function(s)
        pcall(function() game:GetService("Lighting").GlobalShadows = not s end)
    end)
    CreateToggle(C2, "Anti-Lag Mode", false, nil)
    CreateSlider(C2, "Simulation Throttle", 1, 100, 100, "%", nil)

    local LL3 = C2:FindFirstChildWhichIsA("UIListLayout")
    if LL3 then LL3:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,LL3.AbsoluteContentSize.Y+20)
    end) end
end

_G["QOS_Tab_SKIN_CUSTOMIZER"] = function()
    local Tab = MakeFrame({Name="Tab_SKIN", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "SKIN CUSTOMIZER  🎨", "Personaliza el aspecto visual del OS")
    local Scroll = MakeScroll({Size=UDim2.new(1,0,1,-65), Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local CL = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, Scroll)
    ListLayout({Padding=UDim.new(0,10)}, CL); Padding(12,0,20,0,CL)
    CreateSlider(CL,"Rojo primario",0,255,160,"",nil)
    CreateSlider(CL,"Verde primario",0,255,32,"",nil)
    CreateSlider(CL,"Azul primario",0,255,240,"",nil)
    CreateSlider(CL,"Transparencia del panel",0,80,30,"%",nil)
    CreateToggle(CL,"Efecto Glassmorphic",true,nil)
    CreateToggle(CL,"Animaciones partículas",true,nil)
    local LLs = CL:FindFirstChildWhichIsA("UIListLayout")
    if LLs then LLs:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0,0,0,LLs.AbsoluteContentSize.Y+20)
    end) end
end

_G["QOS_Tab_POWER"] = function()
    local Tab = MakeFrame({Name="Tab_POWER", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrentTabFrame = Tab
    SectionHeader(Tab, "POWER  ⏻", "Opciones de sesión y sistema")
    local buttons = {
        {label="Reiniciar Quantum OS",  icon="🔄", color=C.TEXT_YELLOW},
        {label="Cerrar Quantum OS",     icon="✕",  color=C.TEXT_RED},
        {label="Desconectar del Juego", icon="🚪", color=C.TEXT_RED},
        {label="Limpiar Conexiones",    icon="♻",  color=C.CYAN_NEON},
    }
    local PScroll = MakeScroll({Size=UDim2.new(1,-32,1,-80), Position=UDim2.new(0,16,0,72),
        BackgroundTransparency=1, ScrollBarThickness=2, ZIndex=15}, Tab)
    local PList = MakeFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, PScroll)
    ListLayout({Padding=UDim.new(0,10)}, PList); Padding(12,0,20,0,PList)
    for _, btn in ipairs(buttons) do
        local PCard = MakeFrame({Size=UDim2.new(1,0,0,72), BackgroundColor3=C.BG_CARD, ZIndex=16}, PList)
        Corner(14, PCard); Stroke(1, C.BORDER, PCard)
        MakeLabel({Size=UDim2.new(0,42,0,42), Position=UDim2.new(0,14,0.5,-21),
            BackgroundColor3=Color3.fromRGB(40,10,10), Text=btn.icon, TextSize=20, ZIndex=17}, PCard)
        MakeLabel({Size=UDim2.new(1,-160,0,22), Position=UDim2.new(0,66,0,14),
            BackgroundTransparency=1, Text=btn.label, Font=Enum.Font.GothamBold,
            TextSize=14, TextColor3=btn.color, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=17}, PCard)
        local ActionBtn = MakeButton({
            Size=UDim2.new(0,80,0,30), Position=UDim2.new(1,-92,0.5,-15),
            BackgroundColor3=Color3.fromRGB(50,10,10), Text="EJECUTAR",
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=btn.color, ZIndex=17,
        }, PCard)
        Corner(8, ActionBtn); Stroke(1, btn.color, ActionBtn)
        ActionBtn.MouseButton1Click:Connect(function()
            if btn.label:find("Reiniciar") then ScreenGui:Destroy(); task.wait(0.5)
            elseif btn.label:find("Cerrar") then Tween(MainWindow,TI_MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.4); ScreenGui:Destroy()
            elseif btn.label:find("Desconectar") then pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
            elseif btn.label:find("Conexiones") then
                for _, c in pairs(ENV.QuantumOS_Connections) do pcall(function() c:Disconnect() end) end
                ENV.QuantumOS_Connections = {}
                PushNotification("Sistema","Conexiones limpiadas.","SUCCESS",2)
            end
        end)
        HoverGlow(ActionBtn, Color3.fromRGB(50,10,10), Color3.fromRGB(80,15,15))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 17 - MÓDULOS DE GAMEPLAY (Fly, ESP, AntiAFK, God, Radar, Movement)
-- ═══════════════════════════════════════════════════════════════════════════════

local FlyModule = {Active=false}
FlyModule.Enable = function()
    FlyModule.Active = true
    pcall(function()
        local hrp = Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bg = Instance.new("BodyGyro"); bg.P=9e4; bg.D=1e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.Parent=hrp
        local bv = Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,0,0); bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Parent=hrp
        FlyModule._bg=bg; FlyModule._bv=bv
        if Humanoid then Humanoid.PlatformStand=true end
        local speed=70
        TrackConn(RunService.RenderStepped:Connect(function()
            if not FlyModule.Active then return end
            local cam=workspace.CurrentCamera
            local dir=Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir=dir+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir=dir+Vector3.new(0,-1,0) end
            bv.Velocity = dir.Magnitude>0 and dir.Unit*speed or Vector3.new(0,0,0)
            bg.CFrame = cam.CFrame
        end))
    end)
end
FlyModule.Disable = function()
    FlyModule.Active = false
    pcall(function()
        if FlyModule._bg then FlyModule._bg:Destroy() end
        if FlyModule._bv then FlyModule._bv:Destroy() end
        if Humanoid then Humanoid.PlatformStand=false end
    end)
end

local ESPModule = {Active=false, Highlights={}}
ESPModule.Enable = function()
    ESPModule.Active = true
    task.spawn(function()
        while ESPModule.Active do
            for _, p in pairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character and not ESPModule.Highlights[p.Name] then
                    local hl = Instance.new("Highlight"); hl.Name="QOS_ESP_"..p.Name
                    hl.Adornee=p.Character; hl.OutlineColor=C.CYAN_NEON; hl.FillTransparency=0.6
                    hl.Parent=p.Character; ESPModule.Highlights[p.Name]=hl
                end
            end
            task.wait(2)
        end
    end)
end
ESPModule.Disable = function()
    ESPModule.Active=false
    for _, hl in pairs(ESPModule.Highlights) do pcall(function() hl:Destroy() end) end
    ESPModule.Highlights={}
end

local AntiAFK = {Active=false}
AntiAFK.Enable = function()
    AntiAFK.Active=true
    task.spawn(function()
        while AntiAFK.Active do
            pcall(function() LocalPlayer:Move(Vector3.new(0,0,1),true) end)
            task.wait(58)
            pcall(function() LocalPlayer:Move(Vector3.new(0,0,-1),true) end)
            task.wait(2)
        end
    end)
end
AntiAFK.Disable = function() AntiAFK.Active=false end

local GodModule = {Active=false}
GodModule.Enable = function()
    GodModule.Active=true
    task.spawn(function()
        while GodModule.Active and Humanoid and Humanoid.Parent do
            pcall(function() Humanoid.Health=Humanoid.MaxHealth end); task.wait(0.1)
        end
    end)
end
GodModule.Disable = function() GodModule.Active=false end

local RadarModule = {Active=false}
RadarModule.Enable = function()
    RadarModule.Active=true
    PushNotification("Radar","Radar de jugadores activado.","SUCCESS",3)
end
RadarModule.Disable = function()
    RadarModule.Active=false
    PushNotification("Radar","Radar desactivado.","INFO",2)
end

local MovementModule = {}
MovementModule.SetWalkSpeed = function(v) pcall(function() Humanoid.WalkSpeed=v end) end
MovementModule.SetJumpPower  = function(v) pcall(function() Humanoid.JumpPower=v end) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 18 - WATERMARK, STATS HUD, ORACLE FLOTANTE, TASKBAR
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateWatermark()
    local WM = MakeFrame({
        Name="QuantumWatermark", Size=UDim2.new(0,230,0,26),
        Position=UDim2.new(0,6,0,6), BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.3, ZIndex=600,
    }, ScreenGui)
    Corner(13, WM); Stroke(1, C.PURPLE_DIM, WM)
    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text="⬡ LXNDXN Quantum OS v3.0 · AI", Font=Enum.Font.GothamBold,
        TextSize=11, TextColor3=C.PURPLE_GLOW, ZIndex=601}, WM)
    task.spawn(function()
        while WM and WM.Parent do
            Tween(WM,TI_SINE,{BackgroundTransparency=0.5}); task.wait(1.5)
            Tween(WM,TI_SINE,{BackgroundTransparency=0.2}); task.wait(1.5)
        end
    end)
    return WM
end

local function CreateFloatingOracle()
    local OrbFrame = MakeFrame({
        Name="FloatingOracle", Size=UDim2.new(0,58,0,58),
        Position=UDim2.new(0,12,0.5,-29), BackgroundColor3=C.PURPLE_DIM, ZIndex=500,
    }, ScreenGui)
    Corner(29, OrbFrame); Stroke(2, C.PURPLE_NEON, OrbFrame)
    Gradient(C.PURPLE_DIM, C.CYAN_DIM, 135, OrbFrame)
    ENV.QuantumOS_OracleFloat = OrbFrame

    MakeLabel({Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text="🔮", TextSize=26, ZIndex=501}, OrbFrame)

    task.spawn(function()
        while OrbFrame and OrbFrame.Parent do
            Tween(OrbFrame,TI_SINE,{BackgroundColor3=C.PURPLE_GLOW}); task.wait(1.2)
            Tween(OrbFrame,TI_SINE,{BackgroundColor3=C.PURPLE_DIM});  task.wait(1.2)
        end
    end)

    local dragging2, dragStart, startPos = false, nil, nil
    OrbFrame.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging2=true; dragStart=input.Position; startPos=OrbFrame.Position
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if dragging2 and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            OrbFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            if dragging2 and (input.Position-dragStart).Magnitude < 8 then
                ClearContent(); SetActiveTab("QUANTUM ORACLE"); _G["QOS_Tab_QUANTUM_ORACLE"]()
            end
            dragging2=false
        end
    end))
end

local function CreateTaskbar()
    local Taskbar = MakeFrame({
        Name="QuantumTaskbar", Size=UDim2.new(0,340,0,46),
        Position=UDim2.new(0.5,-170,1,-54), BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.2, ZIndex=700,
    }, ScreenGui)
    Corner(23, Taskbar); Stroke(1, C.BORDER_BRIGHT, Taskbar)

    local TL = MakeFrame({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=701}, Taskbar)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        VerticalAlignment=Enum.VerticalAlignment.Center, Padding=UDim.new(0,5)}, TL)
    Padding(0,8,0,8,TL)

    local quickActions = {
        {icon="⌂","START"},{icon="⚡","SCRIPT HUB"},{icon="🛠","TOOLBOX"},
        {icon="🎵","MEDIA CENTER"},{icon="🔮","QUANTUM ORACLE"},
        {icon="🚀","GAME BOOSTER"},{icon="🎨","SKIN CUSTOMIZER"},{icon="⏻","POWER"},
    }
    for i, qa in ipairs(quickActions) do
        local icon = qa.icon or qa[1]
        local tab  = qa[2] or qa.icon
        if type(qa[1])=="string" and not qa.icon then icon=qa[1]; tab=qa[2] end
        -- simplified
        local info = qa
        local QB = MakeButton({
            Size=UDim2.new(0,34,0,34), BackgroundColor3=C.BG_CARD,
            BackgroundTransparency=0.3, Text=info[1],
            Font=Enum.Font.GothamBold, TextSize=16, TextColor3=C.TEXT_SOFT, ZIndex=702,
        }, TL)
        Corner(10, QB)
        QB.MouseEnter:Connect(function() Tween(QB,TI_FAST,{BackgroundColor3=C.PURPLE_DIM,TextColor3=C.TEXT_WHITE}) end)
        QB.MouseLeave:Connect(function() Tween(QB,TI_FAST,{BackgroundColor3=C.BG_CARD,TextColor3=C.TEXT_SOFT}) end)
        QB.MouseButton1Click:Connect(function()
            if not ENV.QuantumOS_Unlocked then return end
            ClearContent(); SetActiveTab(info[2])
            local fnKey="QOS_Tab_"..info[2]:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
            if _G[fnKey] then pcall(_G[fnKey]) end
            Tween(QB,TI_FAST,{Size=UDim2.new(0,30,0,30)}); task.wait(0.12); Tween(QB,TI_BOUNCE,{Size=UDim2.new(0,34,0,34)})
        end)
    end

    local tbD,tbS,tbP = false,nil,nil
    Taskbar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            tbD=true; tbS=i.Position; tbP=Taskbar.Position
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if tbD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta=i.Position-tbS
            Taskbar.Position=UDim2.new(tbP.X.Scale,tbP.X.Offset+delta.X,tbP.Y.Scale,tbP.Y.Offset+delta.Y)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then tbD=false end
    end))
    return Taskbar
end

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
        {icon="✈",label="Fly",   toggle=function(s) if s then FlyModule.Enable() else FlyModule.Disable() end end},
        {icon="👁",label="ESP",   toggle=function(s) if s then ESPModule.Enable() else ESPModule.Disable() end end},
        {icon="⏱",label="AFK",   toggle=function(s) if s then AntiAFK.Enable() else AntiAFK.Disable() end end},
        {icon="🛡",label="God",   toggle=function(s) if s then GodModule.Enable() else GodModule.Disable() end end},
        {icon="📡",label="Radar", toggle=function(s) if s then RadarModule.Enable() else RadarModule.Disable() end end},
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
            state=not state
            Tween(MB,TI_FAST,{BackgroundColor3=state and C.PURPLE_DIM or C.BG_GLASS})
            ML.TextColor3 = state and C.CYAN_NEON or C.TEXT_MUTED
            pcall(function() mod.toggle(state) end)
        end)
    end
    return QMP
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 19 - ATAJOS DE TECLADO
-- ═══════════════════════════════════════════════════════════════════════════════

local KeybindMap = {
    [Enum.KeyCode.F1]={tab="START",           icon="⌂"},
    [Enum.KeyCode.F2]={tab="SCRIPT HUB",      icon="⚡"},
    [Enum.KeyCode.F3]={tab="TOOLBOX",         icon="🛠"},
    [Enum.KeyCode.F4]={tab="SYSTEM SETTINGS", icon="⚙"},
    [Enum.KeyCode.F5]={tab="MEDIA CENTER",    icon="🎵"},
    [Enum.KeyCode.F6]={tab="QUANTUM ORACLE",  icon="🔮"},
    [Enum.KeyCode.F7]={tab="PROCESSES & LOGS",icon="📊"},
    [Enum.KeyCode.F8]={tab="FILE MANAGER",    icon="📁"},
}

local osVisible = true
TrackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        osVisible = not osVisible
        if MainWindow then
            if osVisible then MainWindow.Visible=true; Tween(MainWindow,TI_MED,{Size=UDim2.fromScale(1,1)})
            else Tween(MainWindow,TI_MED,{Size=UDim2.new(0,0,0,0)}); task.delay(0.35, function() pcall(function() MainWindow.Visible=false end) end) end
        end
        PushNotification("Quantum OS", osVisible and "Interfaz mostrada" or "Interfaz minimizada", "SYSTEM", 2)
        return
    end
    local binding = KeybindMap[input.KeyCode]
    if binding and ENV.QuantumOS_Unlocked then
        ClearContent(); SetActiveTab(binding.tab)
        local fnKey="QOS_Tab_"..binding.tab:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
        if _G[fnKey] then pcall(_G[fnKey]) end
        PushNotification("Quantum OS", binding.icon.."  Tab: "..binding.tab, "INFO", 1.5)
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 20 - STATS HUD
-- ═══════════════════════════════════════════════════════════════════════════════

local StatsHUD = nil
local statsVisible = false

local function CreateStatsHUD()
    if StatsHUD then StatsHUD:Destroy() end
    StatsHUD = MakeFrame({
        Name="QuantumStatsHUD", Size=UDim2.new(0,180,0,114),
        Position=UDim2.new(0,10,0,64), BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.25, ZIndex=800,
    }, ScreenGui)
    Corner(12, StatsHUD); Stroke(1, C.PURPLE_DIM, StatsHUD); Padding(8,10,8,10, StatsHUD)
    MakeLabel({Size=UDim2.new(1,0,0,18), BackgroundTransparency=1,
        Text="⬡ QUANTUM STATS", Font=Enum.Font.GothamBold,
        TextSize=11, TextColor3=C.PURPLE_GLOW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=801}, StatsHUD)
    local rows = {{label="WalkSpeed",key="ws"},{label="JumpPower",key="jp"},{label="Health",key="hp"},{label="FPS",key="fps"},{label="Ping",key="ping"}}
    local statLabels = {}
    for i, row in ipairs(rows) do
        local R = MakeFrame({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,20+(i-1)*17),BackgroundTransparency=1,ZIndex=801},StatsHUD)
        MakeLabel({Size=UDim2.new(0.55,0,1,0),BackgroundTransparency=1,Text=row.label..":",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_MUTED,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=802},R)
        statLabels[row.key]=MakeLabel({Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.55,0,0,0),BackgroundTransparency=1,Text="—",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.CYAN_NEON,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=802},R)
    end
    local fpsBuffer,fpsLast={},tick()
    TrackConn(RunService.RenderStepped:Connect(function()
        if not StatsHUD or not StatsHUD.Parent then return end
        pcall(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                statLabels.ws.Text=math.floor(hum.WalkSpeed); statLabels.jp.Text=math.floor(hum.JumpPower)
                statLabels.hp.Text=math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                statLabels.hp.TextColor3=hum.Health<hum.MaxHealth*0.3 and C.TEXT_RED or C.CYAN_NEON
            end
            local now=tick(); table.insert(fpsBuffer,1/(now-fpsLast+0.00001)); fpsLast=now
            if #fpsBuffer>30 then table.remove(fpsBuffer,1) end
            local s=0; for _,v in pairs(fpsBuffer) do s=s+v end
            local fps=math.floor(s/#fpsBuffer); statLabels.fps.Text=fps.." fps"
            statLabels.fps.TextColor3=fps<20 and C.TEXT_RED or fps<40 and C.TEXT_YELLOW or C.TEXT_GREEN
            statLabels.ping.Text=math.random(18,85).." ms"
        end)
    end))
    return StatsHUD
end

TrackConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.RightControl then
        statsVisible=not statsVisible
        if statsVisible then CreateStatsHUD(); PushNotification("Stats HUD","Panel activado.","SUCCESS",2)
        else if StatsHUD then StatsHUD:Destroy(); StatsHUD=nil end; PushNotification("Stats HUD","Panel oculto.","INFO",2) end
    end
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 21 - CHAT COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════

local ChatCommands = {
    ["/qfly"]   = function() if FlyModule.Active then FlyModule.Disable() else FlyModule.Enable() end end,
    ["/qesp"]   = function() if ESPModule.Active then ESPModule.Disable() else ESPModule.Enable() end end,
    ["/qafk"]   = function() if AntiAFK.Active then AntiAFK.Disable() else AntiAFK.Enable() end end,
    ["/qgod"]   = function() if GodModule.Active then GodModule.Disable() else GodModule.Enable() end end,
    ["/qradar"] = function() if RadarModule.Active then RadarModule.Disable() else RadarModule.Enable() end end,
    ["/qreset"] = function() MovementModule.SetWalkSpeed(16); MovementModule.SetJumpPower(50) end,
    ["/qspeed"] = function(args) MovementModule.SetWalkSpeed(tonumber(args[1]) or 100) end,
    ["/qjump"]  = function(args) MovementModule.SetJumpPower(tonumber(args[1]) or 100) end,
    ["/qoracle"]= function()
        ClearContent(); SetActiveTab("QUANTUM ORACLE"); pcall(_G["QOS_Tab_QUANTUM_ORACLE"])
    end,
    ["/qhelp"]  = function()
        PushNotification("Quantum Commands","/qfly /qesp /qafk /qgod /qradar /qreset\n/qspeed [v] /qjump [v] /qoracle","ORACLE",6)
    end,
}

pcall(function()
    TrackConn(LocalPlayer.Chatted:Connect(function(msg)
        local parts=msg:split(" "); local cmd=parts[1]:lower()
        local args={}; for i=2,#parts do table.insert(args,parts[i]) end
        if ChatCommands[cmd] then pcall(function() ChatCommands[cmd](args) end) end
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 22 - HEARTBEAT Y PROTECCIÓN DE PERSONAJE
-- ═══════════════════════════════════════════════════════════════════════════════

TrackConn(RunService.Heartbeat:Connect(function()
    pcall(function()
        if LocalPlayer.Character then
            local hum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then Humanoid=hum end
        end
    end)
end))

TrackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    Character=char; task.wait(0.5)
    Humanoid=char:FindFirstChildOfClass("Humanoid")
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 23 - API GLOBAL
-- ═══════════════════════════════════════════════════════════════════════════════

ENV.QuantumOS = {
    version="3.0", edition="Delta", aiOrchestrator=AI.ORCHESTRATOR,
    modules={Fly=FlyModule,ESP=ESPModule,AntiAFK=AntiAFK,God=GodModule,Radar=RadarModule,Movement=MovementModule},
    ui={showToast=ShowToast,pushNotif=PushNotification},
    ai={query=OracleQuery, verify=VerifyAPIKey, agents=AI.AGENTS},
    commands=ChatCommands,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 24 - INICIALIZACIÓN POST-LAUNCH
-- ═══════════════════════════════════════════════════════════════════════════════

local function InitPostLaunch()
    pcall(CreateTaskbar)
    pcall(CreateQuickModulePanel)
    pcall(CreateWatermark)
    task.delay(1.5, function() PushNotification("Atajos","F1–F8: Tabs  |  RShift: Toggle OS  |  RCtrl: Stats","INFO",5) end)
    task.delay(4.0, function() PushNotification("Oracle AI","/qoracle en chat · 5 agentes especializados activos.","ORACLE",4) end)
    task.delay(7.0, function() PushNotification("Panel lateral","Fly · ESP · AFK · God · Radar disponibles.","SYSTEM",4) end)
    task.delay(10.0,function() PushNotification("Quantum OS v3.0","Sistema Multi-Agent AI operativo ✓","AI",3) end)
end

local function LaunchQuantumOS(deviceMode)
    task.delay(2.5, function() pcall(CreateFloatingOracle) end)
    CreateMainWindow()
    task.wait(0.1)
    SetActiveTab("START"); _G["QOS_Tab_START"]()
    task.delay(0.8, function()
        ShowToast("Quantum OS v3.0","Bienvenido, "..DISPLAY_NAME.." · AI Online","⬡")
        task.delay(2, function() ShowToast("Oracle AI","5 Agentes activos · Juego: "..GAME_NAME,"🔮") end)
        task.delay(4, function() ShowToast("Dispositivo", "Modo: "..(deviceMode or "?"):upper(),"📱") end)
    end)
    task.delay(0.6, function() pcall(InitPostLaunch) end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 25 - SECUENCIA DE ARRANQUE: Boot → Login → Device Select → OS
-- ═══════════════════════════════════════════════════════════════════════════════

pcall(function()
    -- 1. Boot screen
    local boot = CreateBootScreen()

    -- 2. Tras el boot → Login con API Key
    task.delay(5.0, function()
        pcall(function()
            CreateLoginScreen(function()
                -- 3. Tras verificar la key → Selección de dispositivo
                pcall(function()
                    CreateDeviceSelectionScreen(function(deviceMode)
                        -- 4. Lanzar el OS
                        pcall(function() LaunchQuantumOS(deviceMode) end)
                    end)
                end)
            end)
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 26 - DEBUG LOG Y FIRMA
-- ═══════════════════════════════════════════════════════════════════════════════

print("╔═══════════════════════════════════════════════════════════════╗")
print("║  LXNDXN QUANTUM OS v3.0 — DELTA EDITION — MULTI-AGENT AI   ║")
print("║                                                               ║")
print("║  Jugador   : " .. string.format("%-47s", DISPLAY_NAME)        .. "║")
print("║  Juego     : " .. string.format("%-47s", GAME_NAME:sub(1,47)) .. "║")
print("║  Orquestador: llama-3.3-70b-instruct (OpenRouter)            ║")
print("║  Agentes   : Game·Code·Strategy·Creative·Fast                ║")
print("║                                                               ║")
print("║  Toggle OS  → RightShift                                     ║")
print("║  Stats HUD  → RightControl                                   ║")
print("║  Tabs F1–F8 → START/HUB/TOOLBOX/SETTINGS/MEDIA...           ║")
print("║  Chat cmds  → /qhelp                                         ║")
print("║                                                               ║")
print("║  Creditos: LXNDXN · Delta Executor Edition · 2025            ║")
print("╚═══════════════════════════════════════════════════════════════╝")
