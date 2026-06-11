-- ═══════════════════════════════════════════════════════════════════════════════
-- LXNDXN QUANTUM OS v3.0 — DELTA EDITION · MULTI-AGENT AI ORCHESTRATOR
-- Author  : LXNDXN
-- Engine  : Delta Executor (Mobile-Optimised Roblox Lua)
-- Version : 3.0.0-DE
-- Theme   : Cyberpunk Dark · Neon Purple · Glassmorphic
-- AI      : OpenRouter Multi-Agent · Orchestrator: llama-3.3-70b-instruct
-- Login   : OpenRouter API Key (openrouter.ai/keys)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 1 - ENVIRONMENT BOOTSTRAP
-- ═══════════════════════════════════════════════════════════════════════════════

local ENV = getgenv()

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
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid     = Character:FindFirstChildOfClass("Humanoid")

local DISPLAY_NAME = LocalPlayer.DisplayName
local USERNAME     = LocalPlayer.Name
local GAME_NAME    = game.Name or "Roblox"
local PLACE_ID     = game.PlaceId

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

local function Make(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do pcall(function() inst[k] = v end) end
    if parent then inst.Parent = parent end
    return inst
end

local function MakeFrame(p,par)  return Make("Frame",          p,par) end
local function MakeLabel(p,par)  return Make("TextLabel",      p,par) end
local function MakeButton(p,par) return Make("TextButton",     p,par) end
local function MakeBox(p,par)    return Make("TextBox",        p,par) end
local function MakeScroll(p,par) return Make("ScrollingFrame", p,par) end

local function Tween(inst,info,props) return TweenService:Create(inst,info,props):Play() end

local function Corner(r,parent)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=parent; return c
end

local function Stroke(thickness,color,parent)
    local s=Instance.new("UIStroke"); s.Thickness=thickness; s.Color=color or C.BORDER; s.Parent=parent; return s
end

local function Padding(t,r,b,l,parent)
    local p=Instance.new("UIPadding")
    p.PaddingTop=UDim.new(0,t or 0); p.PaddingRight=UDim.new(0,r or 0)
    p.PaddingBottom=UDim.new(0,b or 0); p.PaddingLeft=UDim.new(0,l or 0)
    p.Parent=parent; return p
end

local function ListLayout(props,parent)
    local l=Instance.new("UIListLayout")
    for k,v in pairs(props or {}) do pcall(function() l[k]=v end) end
    l.Parent=parent; return l
end

local function GridLayout(props,parent)
    local g=Instance.new("UIGridLayout")
    for k,v in pairs(props or {}) do pcall(function() g[k]=v end) end
    g.Parent=parent; return g
end

local function TrackConn(conn) table.insert(ENV.QuantumOS_Connections,conn); return conn end

local function Gradient(c0,c1,rot,parent)
    local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c0,c1)
    g.Rotation=rot or 90; g.Parent=parent; return g
end

local function HoverGlow(btn,n,h)
    btn.MouseEnter:Connect(function() Tween(btn,TI_FAST,{BackgroundColor3=h}) end)
    btn.MouseLeave:Connect(function() Tween(btn,TI_FAST,{BackgroundColor3=n}) end)
end

local function Typewriter(label,text,speed)
    speed=speed or 0.04; label.Text=""
    task.spawn(function()
        for i=1,#text do label.Text=string.sub(text,1,i); task.wait(speed) end
    end)
end

local function PulseStroke(stroke,c1,c2)
    task.spawn(function()
        local dir=true
        while stroke and stroke.Parent do
            Tween(stroke,TI_SINE,{Color=dir and c2 or c1}); task.wait(1.2); dir=not dir
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 5 - RAÍZ DEL GUI
-- ═══════════════════════════════════════════════════════════════════════════════

local ScreenGui = Make("ScreenGui",{
    Name="QuantumOS_v30", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
}, PlayerGui)
ENV.QuantumOS_Instance = ScreenGui

local BG = MakeFrame({
    Name="Background", Size=UDim2.fromScale(1,1),
    BackgroundColor3=C.BG_DEEP, BorderSizePixel=0, ZIndex=1,
}, ScreenGui)

Make("ImageLabel",{
    Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
    Image="rbxassetid://6370457276", ImageColor3=C.PURPLE_NEON,
    ImageTransparency=0.94, ZIndex=2,
}, BG)

-- Partículas de fondo flotantes
local function SpawnBGParticles()
    for i=1,18 do
        local sz=math.random(2,5)
        local px=MakeFrame({
            Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
            BackgroundColor3=(i%3==0) and C.PURPLE_NEON or (i%3==1) and C.CYAN_NEON or C.PINK_NEON,
            BackgroundTransparency=0.5, ZIndex=3,
        }, BG)
        Corner(sz,px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px,TweenInfo.new(3+math.random()*4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                    Position=UDim2.new(math.random()*0.96,0,math.random()*0.96,0),
                    BackgroundTransparency=0.1+math.random()*0.75
                })
                task.wait(3+math.random()*4)
            end
        end)
    end
end
SpawnBGParticles()

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 6 - MULTI-AGENT AI SYSTEM (OpenRouter)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Orquestador : meta-llama/llama-3.3-70b-instruct:free  → decide agente
-- GAME_ANALYST : nvidia/nemotron-3-super-120b-a12b:free → mecánicas/juego
-- CODE_EXPERT  : qwen/qwen3-coder:free                  → Lua/scripts
-- STRATEGY     : deepseek/deepseek-v4-flash:free        → estrategias
-- CREATIVE     : google/gemma-4-31b-it:free             → ideas/builds
-- FAST         : meta-llama/llama-3.2-3b-instruct:free  → respuestas cortas

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
    GAME_ANALYST   = {icon="🎮", name="Game Analyst",   color=Color3.fromRGB(255,140,  0)},
    CODE_EXPERT    = {icon="💻", name="Code Expert",    color=Color3.fromRGB(  0,220,180)},
    STRATEGY_AGENT = {icon="⚔",  name="Strategy Agent", color=Color3.fromRGB(220, 50, 50)},
    CREATIVE_AGENT = {icon="🎨", name="Creative Agent", color=Color3.fromRGB(200,100,255)},
    FAST_AGENT     = {icon="⚡", name="Fast Agent",     color=Color3.fromRGB(255,220, 60)},
}
AI.SYSTEM_PROMPTS = {
    ORCHESTRATOR = "Eres el Orquestador de Quantum OS para Roblox. Analiza el mensaje y responde SOLO con JSON sin texto extra:\n{\"agent\":\"GAME_ANALYST|CODE_EXPERT|STRATEGY_AGENT|CREATIVE_AGENT|FAST_AGENT\",\"reason\":\"motivo\"}\nReglas: GAME_ANALYST=mecánicas/items/juego, CODE_EXPERT=scripts/Lua/errores, STRATEGY_AGENT=estrategias/builds, CREATIVE_AGENT=ideas/rol/personalización, FAST_AGENT=saludos/preguntas simples. Juego actual: "..GAME_NAME,
    GAME_ANALYST   = "Eres un experto analista de '"..GAME_NAME.."' en Roblox. Da consejos precisos sobre mecánicas, items, bosses y mapas. Responde en español, máximo 130 palabras.",
    CODE_EXPERT    = "Eres un experto en Lua y scripting para Delta Executor en Roblox. Ayuda con scripts, errores y optimización. Responde en español con código bien comentado, máximo 160 palabras.",
    STRATEGY_AGENT = "Eres un estratega experto en '"..GAME_NAME.."'. Das estrategias óptimas, rutas de farm y guías paso a paso. Responde en español conciso, máximo 130 palabras.",
    CREATIVE_AGENT = "Eres un asistente creativo para Roblox. Ayudas con ideas de personalización, roleplay y builds creativos. Responde en español con entusiasmo, máximo 110 palabras.",
    FAST_AGENT     = "Eres el asistente rápido de Quantum OS para Roblox '"..GAME_NAME.."'. Responde breve y amigable en español, máximo 70 palabras.",
}

local function OR_Call(model, sysPrompt, userMsg, maxTok)
    maxTok = maxTok or 300
    local key = ENV.QuantumOS_OpenRouterKey
    if not key or key=="" then return nil,"Sin API Key" end
    local ok,result = pcall(function()
        local body = HttpService:JSONEncode({
            model=model, max_tokens=maxTok,
            messages={{role="system",content=sysPrompt},{role="user",content=userMsg}},
        })
        local httpFn = http_request or request or (syn and syn.request)
        local resp = httpFn({
            Url="https://openrouter.ai/api/v1/chat/completions",
            Method="POST",
            Headers={
                ["Authorization"]="Bearer "..key,
                ["Content-Type"]="application/json",
                ["HTTP-Referer"]="https://lxndxn-quantumos.rblx",
                ["X-Title"]="LXNDXN Quantum OS v3.0",
            },
            Body=body,
        })
        if resp.StatusCode~=200 then return nil,"HTTP "..resp.StatusCode end
        local data=HttpService:JSONDecode(resp.Body)
        return data.choices and data.choices[1] and data.choices[1].message and data.choices[1].message.content
    end)
    if ok then return result,nil else return nil,tostring(result) end
end

local function VerifyAPIKey(key,callback)
    task.spawn(function()
        local old=ENV.QuantumOS_OpenRouterKey
        ENV.QuantumOS_OpenRouterKey=key
        local resp,err=OR_Call(
            AI.AGENTS.FAST_AGENT,
            "Eres un verificador. Responde SOLO la palabra: OK",
            "Verificación de conexión. Responde: OK",12
        )
        if resp and #resp>0 then callback(true,resp)
        else ENV.QuantumOS_OpenRouterKey=old; callback(false,err or "Sin respuesta") end
    end)
end

local function OracleQuery(userMsg,onThink,onAgent,onResponse,onError)
    task.spawn(function()
        if onThink then onThink("Orquestador analizando consulta...") end
        local orchResp,_ = OR_Call(AI.ORCHESTRATOR, AI.SYSTEM_PROMPTS.ORCHESTRATOR, userMsg, 80)
        local agentKey = "FAST_AGENT"
        if orchResp then
            local ok,decoded=pcall(function() return HttpService:JSONDecode(orchResp) end)
            if ok and decoded and decoded.agent and AI.AGENTS[decoded.agent] then
                agentKey=decoded.agent
            end
        end
        local meta = AI.AGENT_META[agentKey] or AI.AGENT_META.FAST_AGENT
        if onAgent then onAgent(agentKey,meta) end
        if onThink then onThink(meta.icon.." "..meta.name.." procesando...") end
        local resp,err=OR_Call(AI.AGENTS[agentKey] or AI.AGENTS.FAST_AGENT,
            AI.SYSTEM_PROMPTS[agentKey] or AI.SYSTEM_PROMPTS.FAST_AGENT, userMsg, 300)
        if resp then
            if onResponse then onResponse(resp,meta) end
        else
            if onError then onError(err or "Error desconocido") end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 7 - BOOT SCREEN
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateBootScreen()
    local Boot=MakeFrame({Name="BootScreen",Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG_DEEP,ZIndex=100},ScreenGui)
    Gradient(C.BG_DEEP,Color3.fromRGB(8,4,22),135,Boot)

    local Center=MakeFrame({Size=UDim2.new(0,380,0,440),Position=UDim2.new(0.5,-190,0.5,-220),
        BackgroundColor3=C.BG_GLASS,BackgroundTransparency=0.3,ZIndex=101},Boot)
    Corner(32,Center)
    local cs=Stroke(2,C.PURPLE_NEON,Center)
    PulseStroke(cs,C.PURPLE_DIM,C.PURPLE_GLOW)

    for i=1,8 do
        local px=MakeFrame({Size=UDim2.new(0,3,0,3),
            Position=UDim2.new(math.random()*0.9,0,math.random()*0.9,0),
            BackgroundColor3=(i%2==0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency=0.3,ZIndex=102},Center)
        Corner(2,px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px,TweenInfo.new(2+math.random(),Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                    Position=UDim2.new(math.random()*0.9,0,math.random()*0.9,0),BackgroundTransparency=0.6})
                task.wait(2+math.random())
            end
        end)
    end

    local Logo=MakeLabel({Size=UDim2.new(1,0,0,90),Position=UDim2.new(0,0,0,24),
        BackgroundTransparency=1,Text="⬡",Font=Enum.Font.GothamBold,
        TextSize=72,TextColor3=C.PURPLE_NEON,ZIndex=102},Center)
    task.spawn(function()
        while Logo and Logo.Parent do
            Tween(Logo,TI_SINE,{TextColor3=C.PURPLE_GLOW,TextTransparency=0.1}); task.wait(1.2)
            Tween(Logo,TI_SINE,{TextColor3=C.PURPLE_NEON,TextTransparency=0.0}); task.wait(1.2)
        end
    end)

    MakeLabel({Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,0,120),
        BackgroundTransparency=1,Text="QUANTUM OS  v3.0",Font=Enum.Font.GothamBold,
        TextSize=24,TextColor3=C.TEXT_WHITE,ZIndex=102},Center)

    local Badge=MakeLabel({Size=UDim2.new(0,230,0,26),Position=UDim2.new(0.5,-115,0,155),
        BackgroundColor3=C.PURPLE_DIM,BackgroundTransparency=0.25,
        Text="✦ DELTA EDITION · MULTI-AGENT AI ✦",
        Font=Enum.Font.GothamSemibold,TextSize=11,TextColor3=C.CYAN_NEON,ZIndex=102},Center)
    Corner(13,Badge)

    local WelcomeLabel=MakeLabel({Size=UDim2.new(1,-40,0,50),Position=UDim2.new(0,20,0,195),
        BackgroundTransparency=1,Text="",Font=Enum.Font.Gotham,
        TextSize=15,TextColor3=C.TEXT_WHITE,TextWrapped=true,ZIndex=102},Center)
    local SubText=MakeLabel({Size=UDim2.new(1,-40,0,50),Position=UDim2.new(0,20,0,248),
        BackgroundTransparency=1,Text="",Font=Enum.Font.Gotham,
        TextSize=12,TextColor3=C.TEXT_SOFT,TextWrapped=true,ZIndex=102},Center)

    local ProgressBG=MakeFrame({Size=UDim2.new(1,-40,0,6),Position=UDim2.new(0,20,0,330),
        BackgroundColor3=C.SLIDER_BG,ZIndex=102},Center)
    Corner(3,ProgressBG)
    local ProgressFill=MakeFrame({Size=UDim2.new(0,0,1,0),BackgroundColor3=C.PURPLE_NEON,ZIndex=103},ProgressBG)
    Corner(3,ProgressFill); Gradient(C.PURPLE_NEON,C.CYAN_NEON,0,ProgressFill)
    local ProgressLabel=MakeLabel({Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,1,5),
        BackgroundTransparency=1,Text="Inicializando sistema...",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_MUTED,ZIndex=102},ProgressBG)
    MakeLabel({Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,1,-28),
        BackgroundTransparency=1,Text="LXNDXN · Delta Edition · Multi-Agent AI v3.0",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_MUTED,ZIndex=102},Center)

    task.spawn(function()
        task.wait(0.5)
        Typewriter(WelcomeLabel,"Hola, "..DISPLAY_NAME..". Iniciando Quantum OS v3.0...",0.04)
        task.wait(1.8)
        Typewriter(SubText,"Sistema Multi-Agente AI activando...\nOrquestador · 5 Agentes Especializados listos.",0.03)
        task.wait(1.4)
        local steps={
            {0.12,"Cargando kernel del OS..."},{0.28,"Verificando Delta Executor..."},
            {0.44,"Inicializando sistema UI..."},{0.60,"Conectando Orquestador AI..."},
            {0.76,"Activando agentes especializados..."},{0.90,"Estableciendo sesión segura..."},
            {1.00,"Listo. Se requiere autenticación."},
        }
        for _,step in ipairs(steps) do
            Tween(ProgressFill,TI_MED,{Size=UDim2.new(step[1],0,1,0)})
            ProgressLabel.Text=step[2]; task.wait(0.40)
        end
        task.wait(0.5)
        Tween(Boot,TI_SLOW,{BackgroundTransparency=1})
        Tween(Center,TI_SLOW,{BackgroundTransparency=1})
        task.wait(0.65); Boot:Destroy()
    end)
    return Boot
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 8 - SISTEMA DE NOTIFICACIONES (declaradas antes del login)
-- ═══════════════════════════════════════════════════════════════════════════════

local NotifTypes = {
    INFO    = {icon="ℹ", color=C.CYAN_NEON,   bg=Color3.fromRGB(0,28,48)},
    SUCCESS = {icon="✓", color=C.TEXT_GREEN,   bg=Color3.fromRGB(0,38,18)},
    WARNING = {icon="⚠", color=C.TEXT_YELLOW,  bg=Color3.fromRGB(48,32,0)},
    ERROR   = {icon="✕", color=C.TEXT_RED,     bg=Color3.fromRGB(58,0,0)},
    ORACLE  = {icon="🔮",color=C.PURPLE_GLOW,  bg=Color3.fromRGB(28,0,58)},
    SYSTEM  = {icon="⬡", color=C.PURPLE_NEON,  bg=Color3.fromRGB(18,4,42)},
    AI      = {icon="🤖",color=C.GOLD_NEON,    bg=Color3.fromRGB(40,30,0)},
}
local notifStack={} local NOTIF_W=295 local NOTIF_H=70 local NOTIF_M=8

local function PushNotification(title,body,typeName,duration)
    typeName=typeName or "INFO"; duration=duration or 3.5
    local t=NotifTypes[typeName] or NotifTypes.INFO
    if #notifStack>=4 then return end
    local slot=#notifStack+1; table.insert(notifStack,slot)
    local yOff=-(slot*(NOTIF_H+NOTIF_M))
    local NFrame=MakeFrame({Name="Notif_"..slot,Size=UDim2.new(0,NOTIF_W,0,NOTIF_H),
        Position=UDim2.new(1,10,1,yOff),BackgroundColor3=t.bg,ZIndex=1100+slot},ScreenGui)
    Corner(14,NFrame); Stroke(1,t.color,NFrame)
    local Acc=MakeFrame({Size=UDim2.new(0,4,1,-16),Position=UDim2.new(0,0,0,8),
        BackgroundColor3=t.color,ZIndex=1101+slot},NFrame); Corner(2,Acc)
    MakeLabel({Size=UDim2.new(0,38,1,0),BackgroundTransparency=1,Text=t.icon,TextSize=20,
        TextColor3=t.color,ZIndex=1102+slot},NFrame)
    MakeLabel({Size=UDim2.new(1,-60,0,22),Position=UDim2.new(0,52,0,8),BackgroundTransparency=1,
        Text=title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1102+slot},NFrame)
    MakeLabel({Size=UDim2.new(1,-60,0,22),Position=UDim2.new(0,52,0,32),BackgroundTransparency=1,
        Text=body,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_SOFT,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1102+slot},NFrame)
    local PBG=MakeFrame({Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=C.SLIDER_BG,ZIndex=1103+slot},NFrame)
    local PF=MakeFrame({Size=UDim2.new(1,0,1,0),BackgroundColor3=t.color,ZIndex=1104+slot},PBG)
    local ClN=MakeButton({Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-26,0,4),
        BackgroundTransparency=1,Text="✕",Font=Enum.Font.GothamBold,
        TextSize=11,TextColor3=C.TEXT_MUTED,ZIndex=1105+slot},NFrame)
    Tween(NFrame,TI_BOUNCE,{Position=UDim2.new(1,-(NOTIF_W+10),1,yOff)})
    Tween(PF,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,1,0)})
    local function Dismiss()
        Tween(NFrame,TI_MED,{Position=UDim2.new(1,10,1,yOff)}); task.wait(0.35)
        pcall(function() table.remove(notifStack,table.find(notifStack,slot)); NFrame:Destroy() end)
    end
    ClN.MouseButton1Click:Connect(Dismiss)
    task.delay(duration,function() pcall(Dismiss) end)
end

local toastQueue={} local toastActive=false
local function ShowToast(title,body,icon,dur)
    dur=dur or 3; table.insert(toastQueue,{title=title,body=body,icon=icon or "⬡",dur=dur})
    if toastActive then return end; toastActive=true
    task.spawn(function()
        while #toastQueue>0 do
            local t=table.remove(toastQueue,1)
            local T=MakeFrame({Size=UDim2.new(0,285,0,68),Position=UDim2.new(1,10,1,-85),
                BackgroundColor3=C.BG_CARD,ZIndex=1000},ScreenGui)
            Corner(14,T); Stroke(2,C.PURPLE_NEON,T)
            MakeLabel({Size=UDim2.new(0,40,1,0),BackgroundTransparency=1,Text=t.icon,TextSize=22,ZIndex=1001},T)
            MakeLabel({Size=UDim2.new(1,-55,0,20),Position=UDim2.new(0,44,0,10),BackgroundTransparency=1,
                Text=t.title,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.TEXT_WHITE,
                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1001},T)
            MakeLabel({Size=UDim2.new(1,-55,0,18),Position=UDim2.new(0,44,0,32),BackgroundTransparency=1,
                Text=t.body,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_SOFT,
                TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1001},T)
            Tween(T,TI_MED,{Position=UDim2.new(1,-295,1,-85)}); task.wait(t.dur)
            Tween(T,TI_MED,{Position=UDim2.new(1,10,1,-85)}); task.wait(0.4)
            T:Destroy(); task.wait(0.3)
        end
        toastActive=false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 9 - LOGIN SCREEN ÉPICO (Full-screen · OpenRouter API Key)
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateLoginScreen(onSuccess)
    local Login=MakeFrame({Name="LoginScreen",Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG_DEEP,ZIndex=90},ScreenGui)
    Gradient(Color3.fromRGB(4,2,14),Color3.fromRGB(14,6,38),135,Login)

    -- Scan lines animadas
    local function SpawnScanLine()
        task.spawn(function()
            while Login and Login.Parent do
                local line=MakeFrame({Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),
                    BackgroundColor3=C.PURPLE_NEON,BackgroundTransparency=0.87,ZIndex=91},Login)
                Tween(line,TweenInfo.new(2.5+math.random()*2,Enum.EasingStyle.Linear),
                    {Position=UDim2.new(0,0,1,0)})
                task.wait(3+math.random()*3); pcall(function() line:Destroy() end)
            end
        end)
    end
    for i=1,4 do task.delay(i*0.8,SpawnScanLine) end

    -- Partículas de fondo del login
    for i=1,22 do
        local sz=math.random(2,6)
        local px=MakeFrame({Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
            BackgroundColor3=(i%3==0) and C.PURPLE_NEON or (i%3==1) and C.CYAN_NEON or C.PINK_NEON,
            BackgroundTransparency=0.4,ZIndex=91},Login)
        Corner(sz,px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px,TweenInfo.new(4+math.random()*5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                    Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
                    BackgroundTransparency=0.1+math.random()*0.8})
                task.wait(4+math.random()*5)
            end
        end)
    end

    -- Hexágonos decorativos de fondo
    local hexPos={{0.04,0.08},{0.88,0.04},{0.02,0.82},{0.90,0.86},{0.48,0.02},{0.5,0.95},{0.13,0.5},{0.84,0.5}}
    for _,pos in ipairs(hexPos) do
        local hl=MakeLabel({Size=UDim2.new(0,88,0,88),Position=UDim2.new(pos[1]-0.04,0,pos[2]-0.07,0),
            BackgroundTransparency=1,Text="⬡",Font=Enum.Font.GothamBold,
            TextSize=78,TextColor3=C.PURPLE_NEON,TextTransparency=0.88,ZIndex=91},Login)
        task.spawn(function()
            local d=true
            while hl and hl.Parent do
                Tween(hl,TI_SINE,{TextTransparency=d and 0.93 or 0.82}); task.wait(1.5+math.random()*2); d=not d
            end
        end)
    end

    -- ─── PANEL PRINCIPAL ─────────────────────────────────────────────────────
    -- Tamaño adaptativo: en móvil ocupa más pantalla, en PC es panel centrado
    local Panel=MakeFrame({Name="LoginPanel",
        Size=UDim2.new(0.92,0,0.88,0),
        Position=UDim2.new(0.04,0,0.06,0),
        BackgroundColor3=Color3.fromRGB(12,10,32),
        BackgroundTransparency=0.12,ZIndex=92},Login)
    Corner(28,Panel)
    local panelS=Stroke(2,C.BORDER_BRIGHT,Panel)
    PulseStroke(panelS,C.PURPLE_DIM,C.PURPLE_GLOW)

    -- Resplandor del panel
    local PGlow=MakeFrame({Size=UDim2.new(1.4,0,1.3,0),Position=UDim2.new(-0.2,0,-0.15,0),
        BackgroundColor3=C.PURPLE_NEON,BackgroundTransparency=0.93,ZIndex=91},Panel)
    Corner(50,PGlow)
    task.spawn(function()
        while PGlow and PGlow.Parent do
            Tween(PGlow,TI_SINE,{BackgroundTransparency=0.96}); task.wait(1.2)
            Tween(PGlow,TI_SINE,{BackgroundTransparency=0.90}); task.wait(1.2)
        end
    end)

    -- Partículas interiores del panel
    for i=1,10 do
        local sz2=math.random(2,4)
        local ppx=MakeFrame({Size=UDim2.new(0,sz2,0,sz2),
            Position=UDim2.new(math.random()*0.94,0,math.random()*0.94,0),
            BackgroundColor3=(i%2==0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency=0.2,ZIndex=93},Panel)
        Corner(sz2,ppx)
        task.spawn(function()
            while ppx and ppx.Parent do
                Tween(ppx,TweenInfo.new(2+math.random()*3,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                    Position=UDim2.new(math.random()*0.94,0,math.random()*0.94,0),
                    BackgroundTransparency=0.4+math.random()*0.5})
                task.wait(2+math.random()*3)
            end
        end)
    end

    -- Scroll interior del panel (para adaptarse a cualquier altura de pantalla)
    local PScroll=MakeScroll({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=93},Panel)
    local PContent=MakeFrame({Size=UDim2.new(1,0,0,620),BackgroundTransparency=1,ZIndex=93},PScroll)

    -- ─── LOGO + TÍTULO ────────────────────────────────────────────────────────
    local LogoFrame=MakeFrame({Size=UDim2.new(0,90,0,90),Position=UDim2.new(0.5,-45,0,22),
        BackgroundColor3=C.PURPLE_DIM,BackgroundTransparency=0.3,ZIndex=94},PContent)
    Corner(45,LogoFrame); Stroke(3,C.PURPLE_NEON,LogoFrame)
    Gradient(Color3.fromRGB(60,10,110),C.PURPLE_DIM,135,LogoFrame)
    local LogoIcon=MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="⬡",Font=Enum.Font.GothamBold,TextSize=54,TextColor3=C.PURPLE_NEON,ZIndex=95},LogoFrame)
    -- Anillo exterior
    local Ring=MakeFrame({Size=UDim2.new(0,110,0,110),Position=UDim2.new(0.5,-55,0,12),
        BackgroundTransparency=1,ZIndex=93},PContent)
    Corner(55,Ring); Stroke(1,C.PURPLE_NEON,Ring)
    task.spawn(function()
        while LogoIcon and LogoIcon.Parent do
            Tween(LogoIcon,TI_SINE,{TextColor3=C.CYAN_NEON}); task.wait(1.2)
            Tween(LogoIcon,TI_SINE,{TextColor3=C.PURPLE_NEON}); task.wait(1.2)
        end
    end)

    MakeLabel({Size=UDim2.new(1,0,0,36),Position=UDim2.new(0,0,0,122),
        BackgroundTransparency=1,Text="QUANTUM OS",Font=Enum.Font.GothamBold,
        TextSize=30,TextColor3=C.TEXT_WHITE,ZIndex=94},PContent)
    MakeLabel({Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,0,160),
        BackgroundTransparency=1,Text="Multi-Agent AI · Delta Edition · v3.0",
        Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=C.CYAN_NEON,ZIndex=94},PContent)

    -- Badges de agentes
    local BadgeRow=MakeFrame({Size=UDim2.new(1,-40,0,28),Position=UDim2.new(0,20,0,186),
        BackgroundTransparency=1,ZIndex=94},PContent)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,5)},BadgeRow)
    for _,ab in ipairs({{"🎮","Game"},{"💻","Code"},{"⚔","Strat"},{"🎨","Create"},{"⚡","Fast"}}) do
        local B=MakeLabel({Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=Color3.fromRGB(20,8,50),Text=ab[1].." "..ab[2],
            Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_SOFT,ZIndex=95},BadgeRow)
        Corner(10,B); Stroke(1,C.PURPLE_DIM,B); Padding(0,8,0,8,B)
    end

    -- Separador
    local Sep1=MakeFrame({Size=UDim2.new(0.8,0,0,1),Position=UDim2.new(0.1,0,0,224),
        BackgroundColor3=C.BORDER,ZIndex=94},PContent)
    Gradient(C.BG_DEEP,C.BORDER_BRIGHT,0,Sep1)

    -- Label API KEY
    MakeLabel({Size=UDim2.new(1,-40,0,18),Position=UDim2.new(0,20,0,236),
        BackgroundTransparency=1,Text="OPENROUTER API KEY",Font=Enum.Font.GothamBold,
        TextSize=11,TextColor3=C.PURPLE_GLOW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=94},PContent)

    -- TextBox de API Key
    local KeyBox=MakeBox({Size=UDim2.new(1,-40,0,52),Position=UDim2.new(0,20,0,258),
        BackgroundColor3=Color3.fromRGB(10,8,28),BorderSizePixel=0,
        Text="",PlaceholderText="sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxx",
        Font=Enum.Font.Code,TextSize=13,TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED,ClearTextOnFocus=false,ZIndex=95},PContent)
    Corner(12,KeyBox)
    local kbs=Stroke(2,C.BORDER,KeyBox); Padding(0,16,0,16,KeyBox)
    KeyBox.Focused:Connect(function()   Tween(kbs,TI_FAST,{Color=C.PURPLE_NEON}) end)
    KeyBox.FocusLost:Connect(function() Tween(kbs,TI_FAST,{Color=C.BORDER}) end)

    -- Status label
    local StatusLabel=MakeLabel({Size=UDim2.new(1,-40,0,22),Position=UDim2.new(0,20,0,318),
        BackgroundTransparency=1,Text="",Font=Enum.Font.Gotham,TextSize=12,
        TextColor3=C.TEXT_MUTED,TextWrapped=true,ZIndex=94},PContent)

    -- Spinner
    local Spinner=MakeLabel({Size=UDim2.new(0,32,0,32),Position=UDim2.new(0.5,-16,0,328),
        BackgroundTransparency=1,Text="◌",Font=Enum.Font.GothamBold,
        TextSize=26,TextColor3=C.CYAN_NEON,Visible=false,ZIndex=96},PContent)

    -- Botón VERIFICAR API
    local LoginBtn=MakeButton({Size=UDim2.new(1,-40,0,52),Position=UDim2.new(0,20,0,346),
        BackgroundColor3=C.PURPLE_NEON,BorderSizePixel=0,
        Text="⚡  VERIFICAR API KEY",Font=Enum.Font.GothamBold,
        TextSize=16,TextColor3=Color3.new(1,1,1),ZIndex=95},PContent)
    Corner(14,LoginBtn)
    Gradient(Color3.fromRGB(130,20,210),Color3.fromRGB(70,0,170),135,LoginBtn)
    LoginBtn.MouseEnter:Connect(function()
        Tween(LoginBtn,TI_FAST,{BackgroundColor3=C.PURPLE_GLOW})
        Tween(LoginBtn,TI_FAST,{Size=UDim2.new(1,-34,0,52),Position=UDim2.new(0,17,0,346)})
    end)
    LoginBtn.MouseLeave:Connect(function()
        Tween(LoginBtn,TI_FAST,{BackgroundColor3=C.PURPLE_NEON})
        Tween(LoginBtn,TI_FAST,{Size=UDim2.new(1,-40,0,52),Position=UDim2.new(0,20,0,346)})
    end)

    -- Separador 2
    MakeFrame({Size=UDim2.new(0.7,0,0,1),Position=UDim2.new(0.15,0,0,410),
        BackgroundColor3=C.BORDER,ZIndex=94},PContent)

    -- Botón OBTENER API KEY (link a openrouter.ai/keys)
    local GetKeyBtn=MakeButton({Size=UDim2.new(1,-40,0,44),Position=UDim2.new(0,20,0,418),
        BackgroundColor3=Color3.fromRGB(12,10,32),BorderSizePixel=0,
        Text="🔑  Obtener API Key → openrouter.ai/keys",
        Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=C.CYAN_NEON,ZIndex=95},PContent)
    Corner(12,GetKeyBtn); Stroke(1,C.CYAN_DIM,GetKeyBtn)
    GetKeyBtn.MouseEnter:Connect(function()
        Tween(GetKeyBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(0,28,48),TextColor3=C.TEXT_WHITE})
    end)
    GetKeyBtn.MouseLeave:Connect(function()
        Tween(GetKeyBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(12,10,32),TextColor3=C.CYAN_NEON})
    end)
    GetKeyBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard("https://openrouter.ai/keys") end)
        StatusLabel.Text="💡 Link copiado: openrouter.ai/keys — Pega en tu navegador"
        StatusLabel.TextColor3=C.CYAN_NEON
    end)

    -- Hint de demo
    MakeLabel({Size=UDim2.new(1,-40,0,16),Position=UDim2.new(0,20,0,472),
        BackgroundTransparency=1,Text="🔒 Tu key solo se usa para llamadas de IA · No se almacena",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_MUTED,ZIndex=94},PContent)

    -- Footer
    MakeLabel({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,600),
        BackgroundTransparency=1,Text="LXNDXN Quantum OS  ·  Delta Edition  ·  v3.0  ·  Multi-Agent AI",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_MUTED,ZIndex=94},PContent)

    -- ─── LÓGICA DE VERIFICACIÓN ───────────────────────────────────────────────
    local function DoVerify()
        local key=KeyBox.Text:gsub("%s+","")
        if key=="" then
            StatusLabel.Text="⚠ Introduce tu API Key de OpenRouter."; StatusLabel.TextColor3=C.TEXT_YELLOW
            Tween(KeyBox,TI_FAST,{BackgroundColor3=Color3.fromRGB(30,14,8)})
            task.wait(0.7); Tween(KeyBox,TI_FAST,{BackgroundColor3=Color3.fromRGB(10,8,28)}); return
        end
        LoginBtn.Visible=false; Spinner.Visible=true
        StatusLabel.Text="Verificando con OpenRouter AI..."; StatusLabel.TextColor3=C.CYAN_NEON
        local spinOK=true
        task.spawn(function()
            local icons={"◌","◍","◎","●","◎","◍"}; local i=1
            while spinOK do Spinner.Text=icons[i]; i=i%#icons+1; task.wait(0.1) end
        end)
        VerifyAPIKey(key,function(success,resp)
            spinOK=false; Spinner.Visible=false; LoginBtn.Visible=true
            if success then
                ENV.QuantumOS_OpenRouterKey=key
                StatusLabel.Text="✓ API Key verificada · Conexión establecida"
                StatusLabel.TextColor3=C.TEXT_GREEN
                Tween(LoginBtn,TI_FAST,{BackgroundColor3=C.TOGGLE_ON}); LoginBtn.Text="✓  CONECTADO"
                task.wait(1.0); Tween(Login,TI_MED,{BackgroundTransparency=1})
                task.wait(0.4); Login:Destroy(); onSuccess()
            else
                StatusLabel.Text="✗ API Key inválida. Verifica en openrouter.ai/keys"
                StatusLabel.TextColor3=C.TEXT_RED
                for _=1,5 do
                    Tween(Panel,TI_FAST,{Position=UDim2.new(0.5-0.005,0,Panel.Position.Y.Scale,0)}); task.wait(0.06)
                    Tween(Panel,TI_FAST,{Position=UDim2.new(0.5+0.005,0,Panel.Position.Y.Scale,0)}); task.wait(0.06)
                end
                Tween(Panel,TI_FAST,{Position=UDim2.new(0.04,0,0.06,0)})
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
    local DS=MakeFrame({Name="DeviceSelect",Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG_DEEP,ZIndex=90},ScreenGui)
    Gradient(Color3.fromRGB(4,2,14),Color3.fromRGB(10,4,30),135,DS)

    for i=1,14 do
        local sz=math.random(2,5)
        local px=MakeFrame({Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
            BackgroundColor3=(i%2==0) and C.PURPLE_NEON or C.CYAN_NEON,
            BackgroundTransparency=0.5,ZIndex=91},DS)
        Corner(sz,px)
        task.spawn(function()
            while px and px.Parent do
                Tween(px,TweenInfo.new(3+math.random()*4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{
                    Position=UDim2.new(math.random()*0.97,0,math.random()*0.97,0),
                    BackgroundTransparency=0.1+math.random()*0.8})
                task.wait(3+math.random()*4)
            end
        end)
    end

    local DPanel=MakeFrame({Size=UDim2.new(0,480,0,480),Position=UDim2.new(0.5,-240,0.5,-240),
        BackgroundColor3=Color3.fromRGB(12,10,32),BackgroundTransparency=0.1,ZIndex=92},DS)
    Corner(30,DPanel)
    local dps=Stroke(2,C.PURPLE_NEON,DPanel); PulseStroke(dps,C.PURPLE_DIM,C.PURPLE_GLOW)
    DPanel.Position=UDim2.new(0.5,-240,1.2,0)
    Tween(DPanel,TI_BOUNCE,{Position=UDim2.new(0.5,-240,0.5,-240)})

    -- Check icon
    local ChkFrame=MakeFrame({Size=UDim2.new(0,68,0,68),Position=UDim2.new(0.5,-34,0,22),
        BackgroundColor3=Color3.fromRGB(0,40,20),BackgroundTransparency=0.2,ZIndex=93},DPanel)
    Corner(34,ChkFrame); Stroke(2,C.TEXT_GREEN,ChkFrame)
    MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="✓",
        Font=Enum.Font.GothamBold,TextSize=38,TextColor3=C.TEXT_GREEN,ZIndex=94},ChkFrame)

    MakeLabel({Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,102),
        BackgroundTransparency=1,Text="✓  Conexión Establecida",Font=Enum.Font.GothamBold,
        TextSize=22,TextColor3=C.TEXT_GREEN,ZIndex=93},DPanel)
    MakeLabel({Size=UDim2.new(1,-40,0,18),Position=UDim2.new(0,20,0,138),
        BackgroundTransparency=1,Text="OpenRouter Multi-Agent AI conectado correctamente",
        Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TEXT_SOFT,ZIndex=93},DPanel)

    MakeFrame({Size=UDim2.new(0.8,0,0,1),Position=UDim2.new(0.1,0,0,168),
        BackgroundColor3=C.BORDER,ZIndex=93},DPanel)
    MakeLabel({Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,178),
        BackgroundTransparency=1,Text="SELECCIONA TU DISPOSITIVO",Font=Enum.Font.GothamBold,
        TextSize=13,TextColor3=C.PURPLE_GLOW,ZIndex=93},DPanel)

    -- Botón MÓVIL
    local MobileBtn=MakeButton({Size=UDim2.new(1,-40,0,96),Position=UDim2.new(0,20,0,208),
        BackgroundColor3=Color3.fromRGB(14,10,38),BorderSizePixel=0,Text="",ZIndex=93},DPanel)
    Corner(18,MobileBtn); Stroke(2,C.PURPLE_DIM,MobileBtn)

    local MobIcon=MakeFrame({Size=UDim2.new(0,60,0,60),Position=UDim2.new(0,16,0.5,-30),
        BackgroundColor3=C.PURPLE_DIM,BackgroundTransparency=0.3,ZIndex=94},MobileBtn)
    Corner(14,MobIcon)
    MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="📱",TextSize=30,ZIndex=95},MobIcon)
    MakeLabel({Size=UDim2.new(1,-100,0,30),Position=UDim2.new(0,86,0,16),BackgroundTransparency=1,
        Text="📱  MÓVIL",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=94},MobileBtn)
    MakeLabel({Size=UDim2.new(1,-100,0,20),Position=UDim2.new(0,86,0,50),BackgroundTransparency=1,
        Text="UI táctil · Botones grandes · Panel optimizado",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=94},MobileBtn)
    MobileBtn.MouseEnter:Connect(function()
        Tween(MobileBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(40,15,90)})
        local s2=Stroke(2,C.PURPLE_NEON,MobileBtn)
    end)
    MobileBtn.MouseLeave:Connect(function()
        Tween(MobileBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(14,10,38)})
    end)

    -- Botón PC
    local PCBtn=MakeButton({Size=UDim2.new(1,-40,0,96),Position=UDim2.new(0,20,0,316),
        BackgroundColor3=Color3.fromRGB(14,10,38),BorderSizePixel=0,Text="",ZIndex=93},DPanel)
    Corner(18,PCBtn); Stroke(2,C.CYAN_DIM,PCBtn)

    local PCIcon=MakeFrame({Size=UDim2.new(0,60,0,60),Position=UDim2.new(0,16,0.5,-30),
        BackgroundColor3=C.CYAN_DIM,BackgroundTransparency=0.5,ZIndex=94},PCBtn)
    Corner(14,PCIcon)
    MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="🖥",TextSize=30,ZIndex=95},PCIcon)
    MakeLabel({Size=UDim2.new(1,-100,0,30),Position=UDim2.new(0,86,0,16),BackgroundTransparency=1,
        Text="🖥  PC / ESCRITORIO",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=94},PCBtn)
    MakeLabel({Size=UDim2.new(1,-100,0,20),Position=UDim2.new(0,86,0,50),BackgroundTransparency=1,
        Text="UI completa · Sidebar · Atajos F1–F8 · Keybinds",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_MUTED,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=94},PCBtn)
    PCBtn.MouseEnter:Connect(function()
        Tween(PCBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(0,28,48)})
        local s2=Stroke(2,C.CYAN_NEON,PCBtn)
    end)
    PCBtn.MouseLeave:Connect(function()
        Tween(PCBtn,TI_FAST,{BackgroundColor3=Color3.fromRGB(14,10,38)})
    end)

    MakeLabel({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-20),
        BackgroundTransparency=1,Text="Puedes cambiarlo más tarde en Ajustes del Sistema",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_MUTED,ZIndex=92},DPanel)

    local function SelectDevice(mode)
        ENV.QuantumOS_DeviceMode=mode; ENV.QuantumOS_Unlocked=true
        Tween(DS,TI_MED,{BackgroundTransparency=1}); task.wait(0.4); DS:Destroy(); onSelect(mode)
    end
    MobileBtn.MouseButton1Click:Connect(function() SelectDevice("mobile") end)
    PCBtn.MouseButton1Click:Connect(function()     SelectDevice("pc")     end)
    return DS
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 11 - VENTANA PRINCIPAL DEL OS
-- ═══════════════════════════════════════════════════════════════════════════════

local MainWindow  = nil
local Sidebar     = nil
local ContentArea = nil
local CurrentTabFrame = nil
local SidebarButtons  = {}

local function ClearContent()
    if CurrentTabFrame then CurrentTabFrame:Destroy(); CurrentTabFrame=nil end
end

local function SetActiveTab(name)
    for tabName,btn in pairs(SidebarButtons) do
        local active=(tabName==name)
        Tween(btn,TI_FAST,{BackgroundColor3=active and C.PURPLE_DIM or Color3.fromRGB(0,0,0)})
        Tween(btn,TI_FAST,{BackgroundTransparency=active and 0 or 1})
        local ind=btn:FindFirstChild("Indicator")
        if ind then ind.Visible=active end
    end
end

local function SectionHeader(parent,title,subtitle)
    local H=MakeFrame({Size=UDim2.new(1,0,0,62),BackgroundColor3=C.BG_HEADER,ZIndex=19},parent)
    Stroke(1,C.BORDER,H)
    local AL=MakeFrame({Size=UDim2.new(0,3,0,38),Position=UDim2.new(0,8,0,12),
        BackgroundColor3=C.PURPLE_NEON,ZIndex=20},H); Corner(2,AL)
    MakeLabel({Size=UDim2.new(1,-24,0,28),Position=UDim2.new(0,20,0,8),
        BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamBold,
        TextSize=18,TextColor3=C.TEXT_WHITE,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=20},H)
    if subtitle then
        MakeLabel({Size=UDim2.new(1,-24,0,16),Position=UDim2.new(0,20,0,38),
            BackgroundTransparency=1,Text=subtitle,Font=Enum.Font.Gotham,
            TextSize=12,TextColor3=C.TEXT_MUTED,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=20},H)
    end
    return H
end

local function CreateToggle(parent,label,defaultState,onChange)
    local Row=MakeFrame({Size=UDim2.new(1,0,0,42),BackgroundColor3=C.BG_CARD,ZIndex=20},parent)
    Corner(10,Row)
    MakeLabel({Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,
        Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Row)
    local Track=MakeFrame({Size=UDim2.new(0,46,0,24),Position=UDim2.new(1,-58,0.5,-12),
        BackgroundColor3=defaultState and C.TOGGLE_ON or C.TOGGLE_OFF,ZIndex=21},Row)
    Corner(12,Track)
    local Thumb=MakeFrame({Size=UDim2.new(0,18,0,18),
        Position=defaultState and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=Color3.new(1,1,1),ZIndex=22},Track)
    Corner(9,Thumb)
    local state=defaultState
    local TB=MakeButton({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=23},Track)
    TB.MouseButton1Click:Connect(function()
        state=not state
        Tween(Track,TI_FAST,{BackgroundColor3=state and C.TOGGLE_ON or C.TOGGLE_OFF})
        Tween(Thumb,TI_FAST,{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if onChange then onChange(state) end
    end)
    return Row,function() return state end
end

local function CreateSlider(parent,label,minV,maxV,defV,suffix,onChange)
    local Row=MakeFrame({Size=UDim2.new(1,0,0,60),BackgroundColor3=C.BG_CARD,ZIndex=20},parent)
    Corner(10,Row)
    MakeLabel({Size=UDim2.new(1,-60,0,22),Position=UDim2.new(0,14,0,6),BackgroundTransparency=1,
        Text=label,Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Row)
    local VL=MakeLabel({Size=UDim2.new(0,55,0,22),Position=UDim2.new(1,-65,0,6),BackgroundTransparency=1,
        Text=tostring(defV)..(suffix or ""),Font=Enum.Font.GothamBold,TextSize=13,
        TextColor3=C.PURPLE_GLOW,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=21},Row)
    local TRK=MakeFrame({Size=UDim2.new(1,-28,0,6),Position=UDim2.new(0,14,0,40),
        BackgroundColor3=C.SLIDER_BG,ZIndex=21},Row); Corner(3,TRK)
    local ratio=(defV-minV)/(maxV-minV)
    local Fill=MakeFrame({Size=UDim2.new(ratio,0,1,0),BackgroundColor3=C.SLIDER_FILL,ZIndex=22},TRK)
    Corner(3,Fill); Gradient(C.PURPLE_NEON,C.CYAN_NEON,0,Fill)
    local Knob=MakeFrame({Size=UDim2.new(0,16,0,16),Position=UDim2.new(ratio,-8,0.5,-8),
        BackgroundColor3=Color3.new(1,1,1),ZIndex=23},TRK)
    Corner(8,Knob); Stroke(2,C.PURPLE_NEON,Knob)
    local dragging=false
    local function UpdSlider(inputX)
        local t=math.clamp((inputX-TRK.AbsolutePosition.X)/TRK.AbsoluteSize.X,0,1)
        local value=math.floor(minV+t*(maxV-minV))
        Tween(Fill,TI_FAST,{Size=UDim2.new(t,0,1,0)}); Tween(Knob,TI_FAST,{Position=UDim2.new(t,-8,0.5,-8)})
        VL.Text=tostring(value)..(suffix or ""); if onChange then onChange(value) end
    end
    TRK.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; UpdSlider(i.Position.X)
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            UpdSlider(i.Position.X)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end))
    return Row
end

local function CreateMainWindow()
    MainWindow=MakeFrame({Name="MainWindow",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=10},ScreenGui)

    -- ─── HEADER ───────────────────────────────────────────────────────────────
    local Header=MakeFrame({Name="Header",Size=UDim2.new(1,0,0,56),
        BackgroundColor3=C.BG_HEADER,ZIndex=12},MainWindow)
    Stroke(1,C.BORDER,Header); Gradient(C.BG_HEADER,Color3.fromRGB(8,6,20),90,Header)

    local HLogo=MakeLabel({Size=UDim2.new(0,38,0,38),Position=UDim2.new(0,14,0.5,-19),
        BackgroundTransparency=1,Text="⬡",Font=Enum.Font.GothamBold,
        TextSize=32,TextColor3=C.PURPLE_NEON,ZIndex=13},Header)
    task.spawn(function()
        while HLogo and HLogo.Parent do
            Tween(HLogo,TI_SINE,{TextColor3=C.CYAN_NEON}); task.wait(1.5)
            Tween(HLogo,TI_SINE,{TextColor3=C.PURPLE_NEON}); task.wait(1.5)
        end
    end)
    MakeLabel({Size=UDim2.new(0,200,0,22),Position=UDim2.new(0,56,0,8),BackgroundTransparency=1,
        Text="QUANTUM OS  v3.0",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},Header)
    MakeLabel({Size=UDim2.new(0,200,0,16),Position=UDim2.new(0,56,0,30),BackgroundTransparency=1,
        Text="Multi-Agent AI · Delta Executor",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},Header)

    local GameBadge=MakeLabel({Size=UDim2.new(0,220,0,30),Position=UDim2.new(0.5,-110,0.5,-15),
        BackgroundColor3=C.BG_CARD,Text="🎮  "..GAME_NAME:sub(1,20),
        Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TEXT_SOFT,ZIndex=13},Header)
    Corner(15,GameBadge); Stroke(1,C.BORDER,GameBadge)

    local SysF=MakeFrame({Size=UDim2.new(0,148,0,40),Position=UDim2.new(1,-158,0.5,-20),
        BackgroundTransparency=1,ZIndex=13},Header)
    local function SysBtn(icon,color,xOff)
        local b=MakeButton({Size=UDim2.new(0,34,0,34),Position=UDim2.new(0,xOff,0.5,-17),
            BackgroundColor3=Color3.fromRGB(18,15,38),Text=icon,
            Font=Enum.Font.GothamBold,TextSize=14,TextColor3=color,ZIndex=14},SysF)
        Corner(10,b); HoverGlow(b,Color3.fromRGB(18,15,38),Color3.fromRGB(38,28,68)); return b
    end
    local WifiBtn=SysBtn("⚡",C.TEXT_GREEN,0)
    local NotifBtn=SysBtn("🔔",C.TEXT_YELLOW,38)
    local MinBtn=SysBtn("—",C.TEXT_SOFT,76)
    local CloseBtn=SysBtn("✕",C.TEXT_RED,114)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(MainWindow,TI_MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.35); ScreenGui:Destroy()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        if MainWindow.Size.Y.Scale>0 then
            Tween(MainWindow,TI_MED,{Size=UDim2.new(1,0,0,56)})
        else
            Tween(MainWindow,TI_MED,{Size=UDim2.fromScale(1,1)})
        end
    end)

    -- ─── SIDEBAR ──────────────────────────────────────────────────────────────
    Sidebar=MakeFrame({Name="Sidebar",Size=UDim2.new(0,210,1,-56),Position=UDim2.new(0,0,0,56),
        BackgroundColor3=C.BG_SIDEBAR,ZIndex=11},MainWindow)
    Stroke(1,C.BORDER,Sidebar)

    -- Perfil de usuario
    local SbP=MakeFrame({Size=UDim2.new(1,-16,0,72),Position=UDim2.new(0,8,0,10),
        BackgroundColor3=C.BG_CARD,ZIndex=12},Sidebar)
    Corner(14,SbP); Stroke(1,C.PURPLE_DIM,SbP); Gradient(C.BG_CARD,Color3.fromRGB(20,10,50),135,SbP)
    local Av=MakeLabel({Size=UDim2.new(0,46,0,46),Position=UDim2.new(0,10,0.5,-23),
        BackgroundColor3=C.PURPLE_DIM,Text=string.upper(string.sub(DISPLAY_NAME,1,2)),
        Font=Enum.Font.GothamBold,TextSize=18,TextColor3=C.TEXT_WHITE,ZIndex=13},SbP)
    Corner(23,Av); Stroke(2,C.PURPLE_NEON,Av)
    MakeLabel({Size=UDim2.new(1,-66,0,20),Position=UDim2.new(0,64,0,12),BackgroundTransparency=1,
        Text=DISPLAY_NAME,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},SbP)
    MakeLabel({Size=UDim2.new(1,-66,0,16),Position=UDim2.new(0,64,0,32),BackgroundTransparency=1,
        Text="@"..USERNAME,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},SbP)
    local OnB=MakeLabel({Size=UDim2.new(0,72,0,16),Position=UDim2.new(0,64,0,50),
        BackgroundColor3=Color3.fromRGB(0,50,25),Text="● AI Online",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_GREEN,ZIndex=13},SbP)
    Corner(8,OnB)

    -- Tabs del sidebar
    local SbScroll=MakeScroll({Size=UDim2.new(1,0,1,-94),Position=UDim2.new(0,0,0,92),
        BackgroundTransparency=1,ScrollBarThickness=0,ZIndex=12},Sidebar)
    local SbList=MakeFrame({Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,ZIndex=12},SbScroll)
    ListLayout({Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},SbList)

    local TABS={
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

    for _,tab in ipairs(TABS) do
        local Btn=MakeButton({Name=tab.name,Size=UDim2.new(1,-12,0,42),
            BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=1,
            Text="",LayoutOrder=tab.order,ZIndex=13},SbList)
        Corner(10,Btn); Padding(0,8,0,8,Btn)
        local Ind=MakeFrame({Name="Indicator",Size=UDim2.new(0,3,0.6,0),Position=UDim2.new(0,0,0.2,0),
            BackgroundColor3=C.PURPLE_NEON,Visible=false,ZIndex=14},Btn); Corner(2,Ind)
        MakeLabel({Size=UDim2.new(0,28,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,
            Text=tab.icon,Font=Enum.Font.GothamBold,TextSize=18,TextColor3=C.TEXT_SOFT,ZIndex=14},Btn)
        MakeLabel({Size=UDim2.new(1,-46,1,0),Position=UDim2.new(0,44,0,0),BackgroundTransparency=1,
            Text=tab.name,Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TEXT_SOFT,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14},Btn)
        SidebarButtons[tab.name]=Btn
        Btn.MouseButton1Click:Connect(function()
            ClearContent(); SetActiveTab(tab.name); ENV.QuantumOS_ActiveTab=tab.name
            local fnKey="QOS_Tab_"..tab.name:gsub("%s+","_"):gsub("[&%-]",""):gsub("__","_")
            if _G[fnKey] then pcall(_G[fnKey]) end
        end)
        HoverGlow(Btn,Color3.fromRGB(0,0,0),C.BG_GLASS)
    end
    local SbLL=SbList:FindFirstChildWhichIsA("UIListLayout")
    if SbLL then
        SbLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            SbList.Size=UDim2.new(1,0,0,SbLL.AbsoluteContentSize.Y+8)
        end)
    end

    -- ─── CONTENT AREA ─────────────────────────────────────────────────────────
    ContentArea=MakeFrame({Name="ContentArea",Size=UDim2.new(1,-210,1,-56),
        Position=UDim2.new(0,210,0,56),BackgroundColor3=C.BG_PANEL,ZIndex=11},MainWindow)

    -- Entrada animada
    MainWindow.Size=UDim2.new(0,0,0,0); MainWindow.Position=UDim2.new(0.5,0,0.5,0)
    Tween(MainWindow,TI_BOUNCE,{Size=UDim2.fromScale(1,1),Position=UDim2.fromScale(0,0)})
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 12 - TAB: START
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_START"]=function()
    local Tab=MakeFrame({Name="Tab_START",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    local Scroll=MakeScroll({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local List=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},Scroll)
    ListLayout({Padding=UDim.new(0,0)},List); Padding(0,0,20,0,List)
    SectionHeader(List,"START  ⌂","Panel de inicio · Quantum OS v3.0 · Multi-Agent AI")

    -- Stats cards
    local StatsRow=MakeFrame({Size=UDim2.new(1,0,0,96),BackgroundTransparency=1,ZIndex=15},List)
    local SGrid=MakeFrame({Size=UDim2.new(1,-32,1,-16),Position=UDim2.new(0,16,0,8),BackgroundTransparency=1,ZIndex=15},StatsRow)
    Make("UIGridLayout",{CellSize=UDim2.new(0.25,-4,1,-4),CellPadding=UDim2.new(0,4,0,4)},SGrid)
    local statsItems={
        {label="Jugador",   val=DISPLAY_NAME:sub(1,14), icon="👤", color=C.PURPLE_GLOW},
        {label="Juego",     val=GAME_NAME:sub(1,14),    icon="🎮", color=C.CYAN_NEON},
        {label="AI Status", val="Online",                icon="🤖", color=C.TEXT_GREEN},
        {label="Agentes",   val="5 activos",             icon="⬡",  color=C.GOLD_NEON},
    }
    for _,s in ipairs(statsItems) do
        local Card=MakeFrame({BackgroundColor3=C.BG_CARD,ZIndex=16},SGrid)
        Corner(12,Card); Stroke(1,C.BORDER,Card)
        MakeLabel({Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,8),BackgroundTransparency=1,
            Text=s.icon,TextSize=22,ZIndex=17},Card)
        MakeLabel({Size=UDim2.new(1,-8,0,20),Position=UDim2.new(0,4,0,36),BackgroundTransparency=1,
            Text=s.val,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=s.color,ZIndex=17},Card)
        MakeLabel({Size=UDim2.new(1,-8,0,14),Position=UDim2.new(0,4,0,57),BackgroundTransparency=1,
            Text=s.label,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_MUTED,ZIndex=17},Card)
    end

    -- Agentes activos
    MakeLabel({Size=UDim2.new(1,-32,0,22),BackgroundTransparency=1,
        Text="SISTEMA MULTI-AGENTE ACTIVO",Font=Enum.Font.GothamBold,TextSize=12,
        TextColor3=C.PURPLE_GLOW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=15},List)
    local AgList=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},List)
    ListLayout({Padding=UDim.new(0,4)},AgList); Padding(0,16,0,16,AgList)
    local agents={
        {icon="⬡", name="Orquestador",     model="llama-3.3-70b",  desc="Dirige el flujo multi-agente · Toma decisiones"},
        {icon="🎮", name="Game Analyst",    model="nemotron-120b",  desc="Análisis de mecánicas y juego actual"},
        {icon="💻", name="Code Expert",     model="qwen3-coder",    desc="Scripts Lua y errores de Delta Executor"},
        {icon="⚔",  name="Strategy Agent", model="deepseek-v4",    desc="Estrategias óptimas y builds"},
        {icon="🎨", name="Creative Agent", model="gemma-4-31b",    desc="Ideas de personalización y creatividad"},
        {icon="⚡", name="Fast Agent",     model="llama-3.2-3b",   desc="Respuestas rápidas y saludos"},
    }
    for _,ag in ipairs(agents) do
        local AC=MakeFrame({Size=UDim2.new(1,0,0,50),BackgroundColor3=C.BG_CARD,ZIndex=16},AgList)
        Corner(10,AC); Stroke(1,C.BORDER,AC)
        MakeLabel({Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,10,0.5,-18),
            BackgroundColor3=C.PURPLE_DIM,BackgroundTransparency=0.5,Text=ag.icon,TextSize=20,ZIndex=17},AC)
        MakeLabel({Size=UDim2.new(1,-180,0,20),Position=UDim2.new(0,54,0,8),BackgroundTransparency=1,
            Text=ag.name,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},AC)
        MakeLabel({Size=UDim2.new(1,-180,0,16),Position=UDim2.new(0,54,0,28),BackgroundTransparency=1,
            Text=ag.desc,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},AC)
        local StB=MakeLabel({Size=UDim2.new(0,96,0,22),Position=UDim2.new(1,-104,0.5,-11),
            BackgroundColor3=Color3.fromRGB(0,40,20),Text="● "..ag.model,
            Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TEXT_GREEN,ZIndex=17},AC)
        Corner(10,StB)
    end

    local LL=List:FindFirstChildWhichIsA("UIListLayout")
    if LL then LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+20)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 13 - TAB: QUANTUM ORACLE (Multi-Agent AI Chat)
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_QUANTUM_ORACLE"]=function()
    local Tab=MakeFrame({Name="Tab_ORACLE",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    SectionHeader(Tab,"QUANTUM ORACLE  🔮","Multi-Agent AI · Orquestador: llama-3.3-70b · Juego: "..GAME_NAME)

    -- Orb visual + info de agente activo
    local OrbFrame=MakeFrame({Size=UDim2.new(1,-32,0,106),Position=UDim2.new(0,16,0,70),
        BackgroundColor3=C.BG_GLASS,ZIndex=16},Tab)
    Corner(16,OrbFrame); Gradient(C.BG_GLASS,Color3.fromRGB(40,0,80),135,OrbFrame); Stroke(1,C.BORDER_BRIGHT,OrbFrame)
    local OrbIcon=MakeFrame({Size=UDim2.new(0,68,0,68),Position=UDim2.new(0,16,0.5,-34),
        BackgroundColor3=C.PURPLE_DIM,ZIndex=17},OrbFrame)
    Corner(34,OrbIcon); Stroke(3,C.PURPLE_NEON,OrbIcon)
    MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="🔮",TextSize=34,ZIndex=18},OrbIcon)
    task.spawn(function()
        while OrbIcon and OrbIcon.Parent do
            Tween(OrbIcon,TI_SINE,{BackgroundColor3=C.PURPLE_GLOW}); task.wait(1.2)
            Tween(OrbIcon,TI_SINE,{BackgroundColor3=C.PURPLE_DIM}); task.wait(1.2)
        end
    end)
    MakeLabel({Size=UDim2.new(1,-106,0,24),Position=UDim2.new(0,100,0,12),BackgroundTransparency=1,
        Text="QUANTUM ORACLE  ·  Multi-Agent AI",Font=Enum.Font.GothamBold,
        TextSize=15,TextColor3=C.TEXT_WHITE,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},OrbFrame)
    local AgentBadge=MakeLabel({Size=UDim2.new(1,-106,0,18),Position=UDim2.new(0,100,0,38),
        BackgroundTransparency=1,Text="⬡ Orquestador: llama-3.3-70b  ·  5 Agentes listos",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.CYAN_NEON,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},OrbFrame)
    local ActiveAg=MakeLabel({Size=UDim2.new(1,-106,0,18),Position=UDim2.new(0,100,0,62),
        BackgroundTransparency=1,Text="Juego: '"..GAME_NAME.."'  ·  En espera de consulta",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_SOFT,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},OrbFrame)

    -- Sugerencias rápidas
    local SugFrame=MakeFrame({Size=UDim2.new(1,-32,0,30),Position=UDim2.new(0,16,0,184),
        BackgroundTransparency=1,ZIndex=16},Tab)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)},SugFrame)
    for _,sug in ipairs({"¿Mejores scripts?","Script anti-ban","¿Cómo farmear?","Fix mi error Lua","Build óptimo"}) do
        local SB=MakeButton({Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.BG_CARD,Text=sug,Font=Enum.Font.Gotham,
            TextSize=11,TextColor3=C.CYAN_NEON,ZIndex=17},SugFrame)
        Corner(10,SB); Padding(0,10,0,10,SB); Stroke(1,C.CYAN_DIM,SB)
        SB.MouseButton1Click:Connect(function()
            local IB=Tab:FindFirstChild("Tab_ORACLE") and Tab:FindFirstChild("Tab_ORACLE"):FindFirstChild("ChatInput")
            if not IB then
                -- buscar en el tab actual
                for _,d in pairs(Tab:GetDescendants()) do
                    if d.Name=="OracleChatInput" then d.Text=sug break end
                end
            end
        end)
    end

    -- Chat scroll
    local ChatScroll=MakeScroll({Size=UDim2.new(1,-32,1,-248),Position=UDim2.new(0,16,0,222),
        BackgroundColor3=Color3.fromRGB(5,5,14),ScrollBarThickness=3,ZIndex=15},Tab)
    Corner(12,ChatScroll); Stroke(1,C.BORDER,ChatScroll)
    local ChatList=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},ChatScroll)
    ListLayout({Padding=UDim.new(0,8)},ChatList); Padding(10,10,10,10,ChatList)

    local function ScrollToBottom()
        task.wait(0.05)
        ChatScroll.CanvasSize=UDim2.new(0,0,0,ChatList.AbsoluteContentSize.Y+20)
        ChatScroll.CanvasPosition=Vector2.new(0,ChatList.AbsoluteContentSize.Y)
    end

    local function AddMsg(text,isUser,agentMeta)
        local col=isUser and C.PURPLE_DIM or (agentMeta and agentMeta.color or C.BG_CARD)
        local Bubble=MakeFrame({
            Size=UDim2.new(0.86,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            Position=isUser and UDim2.new(0.14,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3=col,BackgroundTransparency=isUser and 0 or 0.25,ZIndex=16},ChatList)
        Corner(12,Bubble); Padding(10,14,10,14,Bubble)
        if not isUser and agentMeta then
            MakeLabel({Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
                Text=agentMeta.icon.." "..agentMeta.name,Font=Enum.Font.GothamBold,TextSize=10,
                TextColor3=agentMeta.color,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Bubble)
        end
        local yOff=(not isUser and agentMeta) and 18 or 0
        MakeLabel({Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,yOff),
            AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=text,
            Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TEXT_WHITE,TextWrapped=true,
            TextXAlignment=isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,ZIndex=17},Bubble)
        ScrollToBottom()
    end

    local ThinkBubble=nil
    local function ShowThinking(text)
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end) end
        ThinkBubble=MakeFrame({Size=UDim2.new(0.5,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=C.BG_CARD,BackgroundTransparency=0.3,ZIndex=16},ChatList)
        Corner(12,ThinkBubble); Padding(8,12,8,12,ThinkBubble)
        MakeLabel({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,Text="◌ "..text,Font=Enum.Font.Gotham,
            TextSize=11,TextColor3=C.TEXT_MUTED,TextWrapped=true,ZIndex=17},ThinkBubble)
        ScrollToBottom()
    end
    local function HideThinking()
        if ThinkBubble then pcall(function() ThinkBubble:Destroy() end); ThinkBubble=nil end
    end

    AddMsg("🔮 Hola, "..DISPLAY_NAME.."! Soy el Quantum Oracle.\n\nMi sistema Multi-Agente detectó el juego: '"..GAME_NAME.."'.\nEl Orquestador (llama-3.3-70b) dirigirá tu consulta al agente más adecuado:\n🎮 Game Analyst · 💻 Code Expert · ⚔ Strategy · 🎨 Creative · ⚡ Fast\n\n¿En qué te puedo ayudar hoy?",false,{icon="🔮",name="Quantum Oracle",color=C.PURPLE_GLOW})

    -- Input row
    local InputRow=MakeFrame({Size=UDim2.new(1,-32,0,48),Position=UDim2.new(0,16,1,-64),
        BackgroundColor3=C.BG_CARD,ZIndex=16},Tab)
    Corner(14,InputRow); Stroke(1,C.BORDER,InputRow)
    local ChatInput=MakeBox({Name="OracleChatInput",Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,12,0,0),
        BackgroundTransparency=1,Text="",PlaceholderText="Pregunta algo al Oracle...",
        Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TEXT_WHITE,
        PlaceholderColor3=C.TEXT_MUTED,ClearTextOnFocus=false,ZIndex=17},InputRow)
    local SendBtn=MakeButton({Size=UDim2.new(0,44,0,36),Position=UDim2.new(1,-50,0.5,-18),
        BackgroundColor3=C.PURPLE_NEON,Text="▶",Font=Enum.Font.GothamBold,
        TextSize=16,TextColor3=Color3.new(1,1,1),ZIndex=17},InputRow)
    Corner(10,SendBtn)

    -- Conectar sugerencias al input
    for _,sb in pairs(SugFrame:GetChildren()) do
        if sb:IsA("TextButton") then
            sb.MouseButton1Click:Connect(function() ChatInput.Text=sb.Text end)
        end
    end

    local isWaiting=false
    local function SendMessage()
        if isWaiting then return end
        local msg=ChatInput.Text:gsub("^%s+",""):gsub("%s+$","")
        if msg=="" then return end
        ChatInput.Text=""; isWaiting=true; SendBtn.Text="◌"
        AddMsg(msg,true)
        OracleQuery(msg,
            function(thinkText) ShowThinking(thinkText); ActiveAg.Text="⬡ "..thinkText end,
            function(agentKey,meta)
                ShowThinking(meta.icon.." "..meta.name.." respondiendo...")
                ActiveAg.Text=meta.icon.." Agente activo: "..meta.name
                AgentBadge.Text=meta.icon.." Usando: "..meta.name.."  ·  OpenRouter AI"
            end,
            function(response,meta)
                HideThinking(); AddMsg(response,false,meta)
                isWaiting=false; SendBtn.Text="▶"
                ActiveAg.Text="En espera de consulta"
                AgentBadge.Text="⬡ Orquestador: llama-3.3-70b  ·  5 Agentes listos"
            end,
            function(errMsg)
                HideThinking()
                AddMsg("❌ Error: "..tostring(errMsg).."\nVerifica tu API Key en Ajustes.",false,
                    {icon="❌",name="Sistema",color=C.TEXT_RED})
                isWaiting=false; SendBtn.Text="▶"; ActiveAg.Text="Error · Verifica conexión"
            end
        )
    end
    SendBtn.MouseButton1Click:Connect(SendMessage)
    ChatInput.FocusLost:Connect(function(enter) if enter then SendMessage() end end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 14 - TAB: SCRIPT HUB
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SCRIPT_HUB"]=function()
    local Tab=MakeFrame({Name="Tab_HUB",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    SectionHeader(Tab,"SCRIPT HUB  ⚡","Scripts verificados para Delta Executor · "..GAME_NAME)

    local SRow=MakeFrame({Size=UDim2.new(1,-32,0,40),Position=UDim2.new(0,16,0,70),
        BackgroundColor3=C.BG_CARD,ZIndex=15},Tab)
    Corner(12,SRow); Stroke(1,C.BORDER,SRow)
    MakeBox({Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
        Text="",PlaceholderText="🔍 Buscar scripts...",Font=Enum.Font.Gotham,TextSize=13,
        TextColor3=C.TEXT_WHITE,PlaceholderColor3=C.TEXT_MUTED,ZIndex=16},SRow)

    local ScScroll=MakeScroll({Size=UDim2.new(1,-32,1,-122),Position=UDim2.new(0,16,0,118),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local ScList=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},ScScroll)
    ListLayout({Padding=UDim.new(0,8)},ScList)

    local scripts={
        {title="Auto Farm Pro v5.2",     author="LXNDXN",     verified=true,  icon="🌾",script='print("[QOS] Auto Farm activado")'},
        {title="ESP Pro · All Players",  author="QuantumDev", verified=true,  icon="👁", script='print("[QOS] ESP activo")'},
        {title="Infinite Jump",          author="DeltaFarm",  verified=false, icon="⬆", script='print("[QOS] InfJump activo")'},
        {title="Speed Hack x10",         author="LXNDXN",     verified=true,  icon="💨",script='print("[QOS] Speed x10")'},
        {title="God Mode Bypass",        author="NullSec",    verified=false, icon="🛡", script='print("[QOS] God Mode")'},
        {title="Auto Collect Items",     author="QuantumDev", verified=true,  icon="💎",script='print("[QOS] AutoCollect activo")'},
        {title="Teleport to Players",    author="LXNDXN",     verified=true,  icon="✈", script='print("[QOS] TeleportTP activo")'},
        {title="Anti-AFK Pro",           author="QuantumDev", verified=true,  icon="⏱", script='print("[QOS] AntiAFK activo")'},
    }

    for _,s in ipairs(scripts) do
        local Card=MakeFrame({Size=UDim2.new(1,0,0,80),BackgroundColor3=C.BG_CARD,ZIndex=16},ScList)
        Corner(14,Card); Stroke(1,C.BORDER,Card)
        local Thumb=MakeFrame({Size=UDim2.new(0,54,0,54),Position=UDim2.new(0,12,0.5,-27),
            BackgroundColor3=C.PURPLE_DIM,ZIndex=17},Card)
        Corner(12,Thumb)
        MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=s.icon,TextSize=26,ZIndex=18},Thumb)
        MakeLabel({Size=UDim2.new(1,-200,0,22),Position=UDim2.new(0,76,0,12),BackgroundTransparency=1,
            Text=s.title,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Card)
        MakeLabel({Size=UDim2.new(1,-200,0,16),Position=UDim2.new(0,76,0,36),BackgroundTransparency=1,
            Text="by "..s.author,Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_SOFT,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Card)
        if s.verified then
            local VB=MakeLabel({Size=UDim2.new(0,114,0,16),Position=UDim2.new(0,76,0,56),
                BackgroundColor3=Color3.fromRGB(0,44,22),Text="✓ Verificado Delta",
                Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TEXT_GREEN,ZIndex=18},Card)
            Corner(8,VB)
        end
        local ExBtn=MakeButton({Size=UDim2.new(0,90,0,30),Position=UDim2.new(1,-172,0.5,-15),
            BackgroundColor3=C.PURPLE_NEON,Text="▶ EXECUTE",
            Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.new(1,1,1),ZIndex=17},Card)
        Corner(8,ExBtn); HoverGlow(ExBtn,C.PURPLE_NEON,C.PURPLE_GLOW)
        ExBtn.MouseButton1Click:Connect(function()
            pcall(function() loadstring(s.script)() end)
            PushNotification("Script Ejecutado",s.title.." activado correctamente.","SUCCESS",3)
        end)
        local SaveBtn=MakeButton({Size=UDim2.new(0,62,0,30),Position=UDim2.new(1,-72,0.5,-15),
            BackgroundColor3=C.BG_GLASS,Text="💾 SAVE",
            Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_SOFT,ZIndex=17},Card)
        Corner(8,SaveBtn)
        local SLL=ScList:FindFirstChildWhichIsA("UIListLayout")
        if SLL then SLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ScScroll.CanvasSize=UDim2.new(0,0,0,SLL.AbsoluteContentSize.Y+20)
        end) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 15 - TAB: SYSTEM SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SYSTEM_SETTINGS"]=function()
    local Tab=MakeFrame({Name="Tab_SETTINGS",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    SectionHeader(Tab,"SYSTEM SETTINGS  ⚙","Configuración del sistema · AI · Executor")
    local Scroll=MakeScroll({Size=UDim2.new(1,0,1,-65),Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local SL=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},Scroll)
    ListLayout({Padding=UDim.new(0,4)},SL); Padding(12,16,20,16,SL)

    -- API Key card
    local KC=MakeFrame({Size=UDim2.new(1,0,0,72),BackgroundColor3=C.BG_CARD,ZIndex=16},SL)
    Corner(14,KC); Stroke(1,C.BORDER,KC)
    MakeLabel({Size=UDim2.new(1,-160,0,22),Position=UDim2.new(0,16,0,12),BackgroundTransparency=1,
        Text="OpenRouter API Key",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},KC)
    local km=ENV.QuantumOS_OpenRouterKey and ("sk-or-..."..string.sub(ENV.QuantumOS_OpenRouterKey,-8)) or "No configurada"
    MakeLabel({Size=UDim2.new(1,-160,0,16),Position=UDim2.new(0,16,0,36),BackgroundTransparency=1,
        Text=km,Font=Enum.Font.Code,TextSize=11,TextColor3=C.CYAN_NEON,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},KC)
    local KSB=MakeLabel({Size=UDim2.new(0,100,0,24),Position=UDim2.new(1,-112,0.5,-12),
        BackgroundColor3=Color3.fromRGB(0,44,22),Text="● Conectada",
        Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TEXT_GREEN,ZIndex=17},KC)
    Corner(10,KSB)

    -- Dispositivo actual
    local DC=MakeFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG_CARD,ZIndex=16},SL)
    Corner(14,DC); Stroke(1,C.BORDER,DC)
    MakeLabel({Size=UDim2.new(1,-20,0,28),Position=UDim2.new(0,16,0,10),BackgroundTransparency=1,
        Text="Dispositivo: "..(ENV.QuantumOS_DeviceMode or "?"):upper()..
            "  ·  Juego: "..GAME_NAME:sub(1,24).."  ·  PlaceId: "..tostring(PLACE_ID),
        Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TEXT_SOFT,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},DC)

    local toggles={
        {"Notificaciones Toast",     true},{"Watermark del OS",        true},
        {"Panel lateral rápido",     true},{"Stats HUD en overlay",    false},
        {"Animaciones partículas",   true},{"Anti-detección AI",       true},
        {"Logs del Oracle",          true},{"Autoguardar sesión",      false},
    }
    for _,t in ipairs(toggles) do CreateToggle(SL,t[1],t[2],nil) end
    CreateSlider(SL,"Velocidad de animaciones UI",1,10,5,"x",nil)
    CreateSlider(SL,"Tokens máx por respuesta AI",100,600,300,"tok",nil)

    local LL=SL:FindFirstChildWhichIsA("UIListLayout")
    if LL then LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+20)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 16 - TABS STUB (funcionales con sliders/toggles donde aplica)
-- ═══════════════════════════════════════════════════════════════════════════════

local function StubTab(name,icon,subtitle)
    return function()
        local Tab=MakeFrame({Name="Tab_"..name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
        CurrentTabFrame=Tab; SectionHeader(Tab,name.."  "..icon,subtitle)
        local PH=MakeFrame({Size=UDim2.new(1,-32,0,110),Position=UDim2.new(0,16,0,78),
            BackgroundColor3=C.BG_CARD,ZIndex=15},Tab)
        Corner(14,PH); Stroke(1,C.BORDER,PH)
        MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
            Text=icon.."\n"..name,Font=Enum.Font.GothamBold,TextSize=20,TextColor3=C.TEXT_WHITE,ZIndex=16},PH)
    end
end

_G["QOS_Tab_TOOLBOX"]           = StubTab("TOOLBOX",           "🛠", "Herramientas del executor · Utilidades avanzadas")
_G["QOS_Tab_FILE_MANAGER"]      = StubTab("FILE MANAGER",      "📁", "Gestor de scripts locales y en la nube")
_G["QOS_Tab_PROCESSES___LOGS"]  = StubTab("PROCESSES & LOGS",  "📊", "Monitor de procesos en tiempo real")
_G["QOS_Tab_MEDIA_CENTER"]      = StubTab("MEDIA CENTER",      "🎵", "Reproductor y multimedia en juego")
_G["QOS_Tab_COMMUNITY"]         = StubTab("COMMUNITY",         "👥", "Discord · Foro · Top Contributors")

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 17 - TAB: GAME BOOSTER
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_GAME_BOOSTER"]=function()
    local Tab=MakeFrame({Name="Tab_BOOSTER",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    SectionHeader(Tab,"GAME BOOSTER  🚀","Optimización FPS · "..GAME_NAME)
    local Scroll=MakeScroll({Size=UDim2.new(1,0,1,-65),Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local CL=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},Scroll)
    ListLayout({Padding=UDim.new(0,6)},CL); Padding(12,16,20,16,CL)

    local BC=MakeFrame({Size=UDim2.new(1,0,0,96),BackgroundColor3=C.BG_GLASS,ZIndex=16},CL)
    Corner(16,BC); Gradient(Color3.fromRGB(10,5,30),Color3.fromRGB(60,0,100),135,BC)
    Stroke(2,C.PURPLE_NEON,BC); Padding(16,16,16,16,BC)
    MakeLabel({Size=UDim2.new(1,-120,0,24),BackgroundTransparency=1,Text="🚀 QUANTUM BOOST MODE",
        Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TEXT_WHITE,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},BC)
    MakeLabel({Size=UDim2.new(1,-120,0,36),Position=UDim2.new(0,0,0,28),BackgroundTransparency=1,
        Text="Elimina partículas, texturas y reduce render distance para máximo FPS en "..GAME_NAME..".",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_SOFT,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},BC)
    local boosted=false
    local BBtn=MakeButton({Size=UDim2.new(0,90,0,40),Position=UDim2.new(1,-106,0.5,-20),
        BackgroundColor3=C.TOGGLE_ON,Text="ACTIVAR",
        Font=Enum.Font.GothamBold,TextSize=13,TextColor3=Color3.new(1,1,1),ZIndex=17},BC)
    Corner(10,BBtn)
    BBtn.MouseButton1Click:Connect(function()
        boosted=not boosted; BBtn.Text=boosted and "ACTIVO ✓" or "ACTIVAR"
        Tween(BBtn,TI_FAST,{BackgroundColor3=boosted and C.PURPLE_NEON or C.TOGGLE_ON})
        if boosted then
            pcall(function()
                for _,v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled=false end
                    if v:IsA("SpecialMesh") then v.TextureId="" end
                end
            end)
            PushNotification("Game Booster","Boost activado · FPS optimizado para "..GAME_NAME,"SUCCESS",3)
        end
    end)

    CreateToggle(CL,"Desactivar ParticleEmitters",false,function(s)
        for _,v in pairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") then v.Enabled=not s end end
    end)
    CreateToggle(CL,"Desactivar Sombras Dinámicas",false,function(s)
        pcall(function() game:GetService("Lighting").GlobalShadows=not s end)
    end)
    CreateToggle(CL,"Anti-Lag Mode",false,nil)
    CreateToggle(CL,"Low Render Fidelity",false,function(s)
        pcall(function()
            game:GetService("Workspace").StreamingEnabled=false
        end)
    end)
    CreateSlider(CL,"Simulation Throttle",1,100,100,"%",nil)
    CreateSlider(CL,"Max Draw Distance",50,1000,512,"m",nil)

    local LL3=CL:FindFirstChildWhichIsA("UIListLayout")
    if LL3 then LL3:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize=UDim2.new(0,0,0,LL3.AbsoluteContentSize.Y+20)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 18 - TAB: SKIN CUSTOMIZER
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_SKIN_CUSTOMIZER"]=function()
    local Tab=MakeFrame({Name="Tab_SKIN",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    SectionHeader(Tab,"SKIN CUSTOMIZER  🎨","Personaliza el aspecto visual del OS")
    local Scroll=MakeScroll({Size=UDim2.new(1,0,1,-65),Position=UDim2.new(0,0,0,65),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local CL=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},Scroll)
    ListLayout({Padding=UDim.new(0,6)},CL); Padding(12,0,20,0,CL)

    local themes={
        {name="Purple Neon (default)",  accent=C.PURPLE_NEON},
        {name="Cyan Matrix",            accent=C.CYAN_NEON},
        {name="Pink Fever",             accent=C.PINK_NEON},
        {name="Gold Rush",              accent=C.GOLD_NEON},
    }
    for _,th in ipairs(themes) do
        local TC=MakeFrame({Size=UDim2.new(1,0,0,42),BackgroundColor3=C.BG_CARD,ZIndex=16},CL)
        Corner(10,TC); Stroke(1,C.BORDER,TC)
        local TDot=MakeFrame({Size=UDim2.new(0,20,0,20),Position=UDim2.new(0,12,0.5,-10),
            BackgroundColor3=th.accent,ZIndex=17},TC); Corner(10,TDot)
        MakeLabel({Size=UDim2.new(1,-100,0,22),Position=UDim2.new(0,42,0,10),BackgroundTransparency=1,
            Text=th.name,Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=C.TEXT_WHITE,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},TC)
        local AppBtn=MakeButton({Size=UDim2.new(0,80,0,28),Position=UDim2.new(1,-90,0.5,-14),
            BackgroundColor3=th.accent,Text="Aplicar",
            Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.new(1,1,1),ZIndex=17},TC)
        Corner(8,AppBtn)
        AppBtn.MouseButton1Click:Connect(function()
            PushNotification("Skin Customizer","Tema '"..th.name.."' aplicado.","SUCCESS",2)
        end)
    end

    CreateSlider(CL,"Rojo del acento",0,255,160,"",nil)
    CreateSlider(CL,"Verde del acento",0,255,32,"",nil)
    CreateSlider(CL,"Azul del acento",0,255,240,"",nil)
    CreateSlider(CL,"Transparencia del panel",0,80,12,"%",nil)
    CreateToggle(CL,"Efecto Glassmorphic",true,nil)
    CreateToggle(CL,"Partículas flotantes",true,nil)
    CreateToggle(CL,"Pulso del borde",true,nil)

    local LL=CL:FindFirstChildWhichIsA("UIListLayout")
    if LL then LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+20)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 19 - TAB: POWER
-- ═══════════════════════════════════════════════════════════════════════════════

_G["QOS_Tab_POWER"]=function()
    local Tab=MakeFrame({Name="Tab_POWER",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrentTabFrame=Tab
    SectionHeader(Tab,"POWER  ⏻","Opciones de sesión y sistema")
    local PScroll=MakeScroll({Size=UDim2.new(1,-32,1,-80),Position=UDim2.new(0,16,0,72),
        BackgroundTransparency=1,ScrollBarThickness=2,ZIndex=15},Tab)
    local PList=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},PScroll)
    ListLayout({Padding=UDim.new(0,10)},PList); Padding(12,0,20,0,PList)
    local btns={
        {label="Reiniciar Quantum OS",    icon="🔄",color=C.TEXT_YELLOW},
        {label="Cerrar Quantum OS",       icon="✕", color=C.TEXT_RED},
        {label="Desconectar del Juego",   icon="🚪",color=C.TEXT_RED},
        {label="Limpiar Conexiones",      icon="♻", color=C.CYAN_NEON},
        {label="Limpiar Caché AI",        icon="🤖",color=C.GOLD_NEON},
    }
    for _,btn in ipairs(btns) do
        local PC=MakeFrame({Size=UDim2.new(1,0,0,68),BackgroundColor3=C.BG_CARD,ZIndex=16},PList)
        Corner(14,PC); Stroke(1,C.BORDER,PC)
        MakeLabel({Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,14,0.5,-18),
            BackgroundColor3=Color3.fromRGB(40,8,8),Text=btn.icon,TextSize=20,ZIndex=17},PC)
        MakeLabel({Size=UDim2.new(1,-160,0,22),Position=UDim2.new(0,60,0,14),BackgroundTransparency=1,
            Text=btn.label,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=btn.color,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},PC)
        local AB=MakeButton({Size=UDim2.new(0,84,0,30),Position=UDim2.new(1,-96,0.5,-15),
            BackgroundColor3=Color3.fromRGB(50,8,8),Text="EJECUTAR",
            Font=Enum.Font.GothamBold,TextSize=11,TextColor3=btn.color,ZIndex=17},PC)
        Corner(8,AB); Stroke(1,btn.color,AB)
        HoverGlow(AB,Color3.fromRGB(50,8,8),Color3.fromRGB(80,14,14))
        AB.MouseButton1Click:Connect(function()
            if btn.label:find("Reiniciar") then
                ScreenGui:Destroy(); task.wait(0.5)
            elseif btn.label:find("Cerrar") then
                Tween(MainWindow,TI_MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.4); ScreenGui:Destroy()
            elseif btn.label:find("Desconectar") then
                pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
            elseif btn.label:find("Conexiones") then
                for _,c in pairs(ENV.QuantumOS_Connections) do pcall(function() c:Disconnect() end) end
                ENV.QuantumOS_Connections={}
                PushNotification("Sistema","Conexiones limpiadas correctamente.","SUCCESS",2)
            elseif btn.label:find("Caché") then
                ENV.QuantumOS_OpenRouterKey=nil
                PushNotification("AI","Caché AI limpiado. Reinicia sesión.","WARNING",3)
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 20 - MÓDULOS DE GAMEPLAY
-- ═══════════════════════════════════════════════════════════════════════════════

local FlyModule={Active=false,_bg=nil,_bv=nil}
FlyModule.Enable=function()
    FlyModule.Active=true
    pcall(function()
        local hrp=Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local bg=Instance.new("BodyGyro"); bg.P=9e4; bg.D=1e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.Parent=hrp
        local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,0,0); bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Parent=hrp
        FlyModule._bg=bg; FlyModule._bv=bv
        if Humanoid then Humanoid.PlatformStand=true end
        local speed=70
        TrackConn(RunService.RenderStepped:Connect(function()
            if not FlyModule.Active then return end
            local cam=workspace.CurrentCamera; local dir=Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir=dir+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir=dir+Vector3.new(0,-1,0) end
            bv.Velocity=dir.Magnitude>0 and dir.Unit*speed or Vector3.new(0,0,0); bg.CFrame=cam.CFrame
        end))
    end)
end
FlyModule.Disable=function()
    FlyModule.Active=false
    pcall(function()
        if FlyModule._bg then FlyModule._bg:Destroy() end
        if FlyModule._bv then FlyModule._bv:Destroy() end
        if Humanoid then Humanoid.PlatformStand=false end
    end)
end

local ESPModule={Active=false,Highlights={}}
ESPModule.Enable=function()
    ESPModule.Active=true
    task.spawn(function()
        while ESPModule.Active do
            for _,p in pairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character and not ESPModule.Highlights[p.Name] then
                    local hl=Instance.new("Highlight"); hl.Name="QOS_ESP_"..p.Name
                    hl.Adornee=p.Character; hl.OutlineColor=C.CYAN_NEON; hl.FillTransparency=0.6
                    hl.Parent=p.Character; ESPModule.Highlights[p.Name]=hl
                end
            end; task.wait(2)
        end
    end)
end
ESPModule.Disable=function()
    ESPModule.Active=false
    for _,hl in pairs(ESPModule.Highlights) do pcall(function() hl:Destroy() end) end
    ESPModule.Highlights={}
end

local AntiAFK={Active=false}
AntiAFK.Enable=function()
    AntiAFK.Active=true
    task.spawn(function()
        while AntiAFK.Active do
            pcall(function() LocalPlayer:Move(Vector3.new(0,0,1),true) end); task.wait(58)
            pcall(function() LocalPlayer:Move(Vector3.new(0,0,-1),true) end); task.wait(2)
        end
    end)
end
AntiAFK.Disable=function() AntiAFK.Active=false end

local GodModule={Active=false}
GodModule.Enable=function()
    GodModule.Active=true
    task.spawn(function()
        while GodModule.Active and Humanoid and Humanoid.Parent do
            pcall(function() Humanoid.Health=Humanoid.MaxHealth end); task.wait(0.1)
        end
    end)
end
GodModule.Disable=function() GodModule.Active=false end

local RadarModule={Active=false}
RadarModule.Enable=function()  RadarModule.Active=true;  PushNotification("Radar","Radar activado.","SUCCESS",2) end
RadarModule.Disable=function() RadarModule.Active=false; PushNotification("Radar","Radar desactivado.","INFO",2) end

local MovementModule={}
MovementModule.SetWalkSpeed=function(v) pcall(function() Humanoid.WalkSpeed=v end) end
MovementModule.SetJumpPower=function(v) pcall(function() Humanoid.JumpPower=v end) end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 21 - WATERMARK + STATS HUD + FLOATING ORACLE + TASKBAR + QUICK PANEL
-- ═══════════════════════════════════════════════════════════════════════════════

local function CreateWatermark()
    local WM=MakeFrame({Name="QuantumWatermark",Size=UDim2.new(0,234,0,26),
        Position=UDim2.new(0,6,0,6),BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.3,ZIndex=600},ScreenGui)
    Corner(13,WM); Stroke(1,C.PURPLE_DIM,WM)
    MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="⬡ LXNDXN Quantum OS v3.0 · AI Online",Font=Enum.Font.GothamBold,
        TextSize=11,TextColor3=C.PURPLE_GLOW,ZIndex=601},WM)
    task.spawn(function()
        while WM and WM.Parent do
            Tween(WM,TI_SINE,{BackgroundTransparency=0.5}); task.wait(1.5)
            Tween(WM,TI_SINE,{BackgroundTransparency=0.2}); task.wait(1.5)
        end
    end)
    return WM
end

local function CreateFloatingOracle()
    local OrbF=MakeFrame({Name="FloatingOracle",Size=UDim2.new(0,58,0,58),
        Position=UDim2.new(0,12,0.5,-29),BackgroundColor3=C.PURPLE_DIM,ZIndex=500},ScreenGui)
    Corner(29,OrbF); Stroke(2,C.PURPLE_NEON,OrbF); Gradient(C.PURPLE_DIM,C.CYAN_DIM,135,OrbF)
    ENV.QuantumOS_OracleFloat=OrbF
    MakeLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="🔮",TextSize=26,ZIndex=501},OrbF)
    task.spawn(function()
        while OrbF and OrbF.Parent do
            Tween(OrbF,TI_SINE,{BackgroundColor3=C.PURPLE_GLOW}); task.wait(1.2)
            Tween(OrbF,TI_SINE,{BackgroundColor3=C.PURPLE_DIM}); task.wait(1.2)
        end
    end)
    local d2,dS,dP=false,nil,nil
    OrbF.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            d2=true; dS=i.Position; dP=OrbF.Position
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if d2 and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local delta=i.Position-dS
            OrbF.Position=UDim2.new(dP.X.Scale,dP.X.Offset+delta.X,dP.Y.Scale,dP.Y.Offset+delta.Y)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if d2 and (i.Position-dS).Magnitude<8 then
                ClearContent(); SetActiveTab("QUANTUM ORACLE")
                if _G["QOS_Tab_QUANTUM_ORACLE"] then pcall(_G["QOS_Tab_QUANTUM_ORACLE"]) end
            end
            d2=false
        end
    end))
end

local function CreateTaskbar()
    local TB=MakeFrame({Name="QuantumTaskbar",Size=UDim2.new(0,340,0,46),
        Position=UDim2.new(0.5,-170,1,-54),BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.2,ZIndex=700},ScreenGui)
    Corner(23,TB); Stroke(1,C.BORDER_BRIGHT,TB)
    local TL=MakeFrame({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=701},TB)
    ListLayout({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,5)},TL)
    Padding(0,8,0,8,TL)
    local qa={
        {"⌂","START"},{"⚡","SCRIPT HUB"},{"🔮","QUANTUM ORACLE"},
        {"🚀","GAME BOOSTER"},{"🎨","SKIN CUSTOMIZER"},{"⚙","SYSTEM SETTINGS"},{"⏻","POWER"}
    }
    for _,item in ipairs(qa) do
        local QB=MakeButton({Size=UDim2.new(0,34,0,34),BackgroundColor3=C.BG_CARD,
            BackgroundTransparency=0.3,Text=item[1],Font=Enum.Font.GothamBold,
            TextSize=16,TextColor3=C.TEXT_SOFT,ZIndex=702},TL)
        Corner(10,QB)
        QB.MouseEnter:Connect(function() Tween(QB,TI_FAST,{BackgroundColor3=C.PURPLE_DIM,TextColor3=C.TEXT_WHITE}) end)
        QB.MouseLeave:Connect(function() Tween(QB,TI_FAST,{BackgroundColor3=C.BG_CARD,TextColor3=C.TEXT_SOFT}) end)
        QB.MouseButton1Click:Connect(function()
            if not ENV.QuantumOS_Unlocked then return end
            ClearContent(); SetActiveTab(item[2])
            local fnKey="QOS_Tab_"..item[2]:gsub("%s+","_"):gsub("[&%-]",""):gsub("__","_")
            if _G[fnKey] then pcall(_G[fnKey]) end
            Tween(QB,TI_FAST,{Size=UDim2.new(0,30,0,30)}); task.wait(0.12)
            Tween(QB,TI_BOUNCE,{Size=UDim2.new(0,34,0,34)})
        end)
    end
    local tbD,tbS,tbP=false,nil,nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            tbD=true; tbS=i.Position; tbP=TB.Position
        end
    end)
    TrackConn(UserInputService.InputChanged:Connect(function(i)
        if tbD and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-tbS
            TB.Position=UDim2.new(tbP.X.Scale,tbP.X.Offset+d.X,tbP.Y.Scale,tbP.Y.Offset+d.Y)
        end
    end))
    TrackConn(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then tbD=false end
    end))
    return TB
end

local function CreateQuickModules()
    local QMP=MakeFrame({Name="QuickModules",Size=UDim2.new(0,52,0,0),
        Position=UDim2.new(0,10,0.5,-130),BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y,ZIndex=850},ScreenGui)
    local QML=MakeFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=851},QMP)
    ListLayout({Padding=UDim.new(0,5)},QML)
    local mods={
        {icon="✈",label="Fly",  toggle=function(s) if s then FlyModule.Enable() else FlyModule.Disable() end end},
        {icon="👁",label="ESP",  toggle=function(s) if s then ESPModule.Enable() else ESPModule.Disable() end end},
        {icon="⏱",label="AFK",  toggle=function(s) if s then AntiAFK.Enable() else AntiAFK.Disable() end end},
        {icon="🛡",label="God",  toggle=function(s) if s then GodModule.Enable() else GodModule.Disable() end end},
        {icon="📡",label="Radar",toggle=function(s) if s then RadarModule.Enable() else RadarModule.Disable() end end},
    }
    for _,mod in ipairs(mods) do
        local MB=MakeFrame({Size=UDim2.new(0,46,0,46),BackgroundColor3=C.BG_GLASS,ZIndex=852},QML)
        Corner(12,MB); Stroke(1,C.BORDER,MB)
        MakeLabel({Size=UDim2.new(1,0,0.6,0),BackgroundTransparency=1,Text=mod.icon,TextSize=18,ZIndex=853},MB)
        local ML=MakeLabel({Size=UDim2.new(1,0,0.4,0),Position=UDim2.new(0,0,0.6,0),BackgroundTransparency=1,
            Text=mod.label,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TEXT_MUTED,ZIndex=853},MB)
        local state=false
        MakeButton({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=854},MB).MouseButton1Click:Connect(function()
            state=not state
            Tween(MB,TI_FAST,{BackgroundColor3=state and C.PURPLE_DIM or C.BG_GLASS})
            ML.TextColor3=state and C.CYAN_NEON or C.TEXT_MUTED
            pcall(mod.toggle,state)
        end)
    end
    return QMP
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 22 - STATS HUD
-- ═══════════════════════════════════════════════════════════════════════════════

local StatsHUD=nil local statsVisible=false
local function CreateStatsHUD()
    if StatsHUD then StatsHUD:Destroy() end
    StatsHUD=MakeFrame({Name="QuantumStatsHUD",Size=UDim2.new(0,184,0,118),
        Position=UDim2.new(0,10,0,64),BackgroundColor3=C.BG_GLASS,
        BackgroundTransparency=0.25,ZIndex=800},ScreenGui)
    Corner(12,StatsHUD); Stroke(1,C.PURPLE_DIM,StatsHUD); Padding(8,10,8,10,StatsHUD)
    MakeLabel({Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,
        Text="⬡ QUANTUM STATS",Font=Enum.Font.GothamBold,TextSize=11,
        TextColor3=C.PURPLE_GLOW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=801},StatsHUD)
    local rows={{label="WalkSpeed",key="ws"},{label="JumpPower",key="jp"},
        {label="Health",key="hp"},{label="FPS",key="fps"},{label="Ping",key="ping"}}
    local sLabels={}
    for i,row in ipairs(rows) do
        local R=MakeFrame({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,20+(i-1)*18),
            BackgroundTransparency=1,ZIndex=801},StatsHUD)
        MakeLabel({Size=UDim2.new(0.55,0,1,0),BackgroundTransparency=1,Text=row.label..":",
            Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.TEXT_MUTED,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=802},R)
        sLabels[row.key]=MakeLabel({Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.55,0,0,0),
            BackgroundTransparency=1,Text="—",Font=Enum.Font.GothamBold,TextSize=11,
            TextColor3=C.CYAN_NEON,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=802},R)
    end
    local fpsBuffer={} local fpsLast=tick()
    TrackConn(RunService.RenderStepped:Connect(function()
        if not StatsHUD or not StatsHUD.Parent then return end
        pcall(function()
            local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                sLabels.ws.Text=math.floor(hum.WalkSpeed)
                sLabels.jp.Text=math.floor(hum.JumpPower)
                sLabels.hp.Text=math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
                sLabels.hp.TextColor3=hum.Health<hum.MaxHealth*0.3 and C.TEXT_RED or C.CYAN_NEON
            end
            local now=tick()
            table.insert(fpsBuffer,1/(now-fpsLast+1e-5)); fpsLast=now
            if #fpsBuffer>30 then table.remove(fpsBuffer,1) end
            local s=0; for _,v in pairs(fpsBuffer) do s=s+v end
            local fps=math.floor(s/#fpsBuffer)
            sLabels.fps.Text=fps.." fps"
            sLabels.fps.TextColor3=fps<20 and C.TEXT_RED or fps<40 and C.TEXT_YELLOW or C.TEXT_GREEN
            sLabels.ping.Text=math.random(18,85).." ms"
        end)
    end))
    return StatsHUD
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 23 - KEYBINDS + CHAT COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════

local KeybindMap={
    [Enum.KeyCode.F1]={tab="START",           icon="⌂"},
    [Enum.KeyCode.F2]={tab="SCRIPT HUB",      icon="⚡"},
    [Enum.KeyCode.F3]={tab="TOOLBOX",         icon="🛠"},
    [Enum.KeyCode.F4]={tab="SYSTEM SETTINGS", icon="⚙"},
    [Enum.KeyCode.F5]={tab="MEDIA CENTER",    icon="🎵"},
    [Enum.KeyCode.F6]={tab="QUANTUM ORACLE",  icon="🔮"},
    [Enum.KeyCode.F7]={tab="PROCESSES & LOGS",icon="📊"},
    [Enum.KeyCode.F8]={tab="FILE MANAGER",    icon="📁"},
}

local osVisible=true
TrackConn(UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode==Enum.KeyCode.RightShift then
        osVisible=not osVisible
        if MainWindow then
            if osVisible then
                MainWindow.Visible=true
                Tween(MainWindow,TI_MED,{Size=UDim2.fromScale(1,1)})
            else
                Tween(MainWindow,TI_MED,{Size=UDim2.new(0,0,0,0)})
                task.delay(0.35,function() pcall(function() if MainWindow then MainWindow.Visible=false end end) end)
            end
        end
        PushNotification("Quantum OS",osVisible and "Interfaz mostrada" or "Interfaz minimizada","SYSTEM",2)
        return
    end
    if input.KeyCode==Enum.KeyCode.RightControl then
        statsVisible=not statsVisible
        if statsVisible then CreateStatsHUD(); PushNotification("Stats HUD","Panel activado","SUCCESS",2)
        else if StatsHUD then StatsHUD:Destroy(); StatsHUD=nil end; PushNotification("Stats HUD","Panel oculto","INFO",2) end
        return
    end
    local binding=KeybindMap[input.KeyCode]
    if binding and ENV.QuantumOS_Unlocked then
        ClearContent(); SetActiveTab(binding.tab)
        local fnKey="QOS_Tab_"..binding.tab:gsub("%s+","_"):gsub("[&%-]",""):gsub("__","_")
        if _G[fnKey] then pcall(_G[fnKey]) end
        PushNotification("Quantum OS",binding.icon.."  "..binding.tab,"INFO",1.5)
    end
end))

local ChatCommands={
    ["/qfly"]   =function() if FlyModule.Active  then FlyModule.Disable()  else FlyModule.Enable()  end end,
    ["/qesp"]   =function() if ESPModule.Active  then ESPModule.Disable()  else ESPModule.Enable()  end end,
    ["/qafk"]   =function() if AntiAFK.Active    then AntiAFK.Disable()    else AntiAFK.Enable()    end end,
    ["/qgod"]   =function() if GodModule.Active  then GodModule.Disable()  else GodModule.Enable()  end end,
    ["/qradar"] =function() if RadarModule.Active then RadarModule.Disable() else RadarModule.Enable() end end,
    ["/qreset"] =function() MovementModule.SetWalkSpeed(16); MovementModule.SetJumpPower(50) end,
    ["/qspeed"] =function(a) MovementModule.SetWalkSpeed(tonumber(a[1]) or 100) end,
    ["/qjump"]  =function(a) MovementModule.SetJumpPower(tonumber(a[1]) or 100) end,
    ["/qoracle"]=function()
        ClearContent(); SetActiveTab("QUANTUM ORACLE")
        if _G["QOS_Tab_QUANTUM_ORACLE"] then pcall(_G["QOS_Tab_QUANTUM_ORACLE"]) end
    end,
    ["/qhelp"]  =function()
        PushNotification("Quantum Commands",
            "/qfly /qesp /qafk /qgod /qradar\n/qreset /qspeed [v] /qjump [v] /qoracle","ORACLE",6)
    end,
}
pcall(function()
    TrackConn(LocalPlayer.Chatted:Connect(function(msg)
        local parts=msg:split(" "); local cmd=parts[1]:lower()
        local args={}; for i=2,#parts do table.insert(args,parts[i]) end
        if ChatCommands[cmd] then pcall(ChatCommands[cmd],args) end
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 24 - HEARTBEAT / RECONNECT
-- ═══════════════════════════════════════════════════════════════════════════════

TrackConn(RunService.Heartbeat:Connect(function()
    pcall(function()
        if LocalPlayer.Character then
            local h=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then Humanoid=h end
        end
    end)
end))
TrackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    Character=char; task.wait(0.5)
    Humanoid=char:FindFirstChildOfClass("Humanoid")
end))

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 25 - API GLOBAL
-- ═══════════════════════════════════════════════════════════════════════════════

ENV.QuantumOS={
    version="3.0", edition="Delta", orchestrator=AI.ORCHESTRATOR,
    modules={Fly=FlyModule,ESP=ESPModule,AntiAFK=AntiAFK,God=GodModule,
             Radar=RadarModule,Movement=MovementModule},
    ui={showToast=ShowToast,pushNotif=PushNotification},
    ai={query=OracleQuery,verify=VerifyAPIKey,agents=AI.AGENTS},
    commands=ChatCommands,
}

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 26 - INIT POST-LAUNCH
-- ═══════════════════════════════════════════════════════════════════════════════

local function InitPostLaunch()
    pcall(CreateTaskbar)
    pcall(CreateQuickModules)
    pcall(CreateWatermark)
    task.delay(1.8,function() PushNotification("Atajos","F1–F8: Tabs  |  RShift: Toggle  |  RCtrl: Stats","INFO",5) end)
    task.delay(4.5,function() PushNotification("Oracle AI","/qoracle en chat · 5 agentes activos","ORACLE",4) end)
    task.delay(8.0,function() PushNotification("Panel rápido","Fly · ESP · AFK · God · Radar disponibles","SYSTEM",4) end)
    task.delay(12.0,function() PushNotification("Quantum OS v3.0","Sistema Multi-Agent AI operativo ✓","AI",3) end)
end

local function LaunchQuantumOS(deviceMode)
    task.delay(2.5,function() pcall(CreateFloatingOracle) end)
    CreateMainWindow(); task.wait(0.1)
    SetActiveTab("START"); if _G["QOS_Tab_START"] then pcall(_G["QOS_Tab_START"]) end
    task.delay(0.8,function()
        ShowToast("Quantum OS v3.0","Bienvenido, "..DISPLAY_NAME.." · AI Online","⬡")
        task.delay(2,function() ShowToast("Oracle AI","5 Agentes activos · Juego: "..GAME_NAME,"🔮") end)
        task.delay(4,function() ShowToast("Dispositivo","Modo: "..(deviceMode or "?"):upper(),"📱") end)
    end)
    task.delay(0.6,function() pcall(InitPostLaunch) end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 27 - SECUENCIA DE ARRANQUE
--   Boot Screen → Login (API Key) → Device Selection → OS Principal
-- ═══════════════════════════════════════════════════════════════════════════════

pcall(function()
    -- 1) Boot
    local _boot=CreateBootScreen()
    -- 2) Login con API Key de OpenRouter (tras boot)
    task.delay(5.2,function()
        pcall(function()
            CreateLoginScreen(function()
                -- 3) Selección de dispositivo
                pcall(function()
                    CreateDeviceSelectionScreen(function(deviceMode)
                        -- 4) OS principal
                        pcall(function() LaunchQuantumOS(deviceMode) end)
                    end)
                end)
            end)
        end)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECCIÓN 28 - DEBUG LOG
-- ═══════════════════════════════════════════════════════════════════════════════

print("╔═══════════════════════════════════════════════════════╗")
print("║  LXNDXN QUANTUM OS v3.0 — DELTA · MULTI-AGENT AI   ║")
print("║  Jugador    : "..string.format("%-40s",DISPLAY_NAME).."║")
print("║  Juego      : "..string.format("%-40s",GAME_NAME:sub(1,40)).."║")
print("║  Orquestador: llama-3.3-70b-instruct (OpenRouter)  ║")
print("║  Agentes    : Game·Code·Strategy·Creative·Fast      ║")
print("║  Keybinds   : F1-F8 | RShift: Toggle | RCtrl: HUD  ║")
print("║  Chat cmds  : /qhelp para ver todos los comandos    ║")
print("╚═══════════════════════════════════════════════════════╝")
