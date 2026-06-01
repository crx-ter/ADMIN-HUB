-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  LXNDXN QUANTUM OS  v4.0 · DELTA EDITION · MULTI-AGENT AI ORCHESTRATOR ║
-- ║  Author  : LXNDXN                                                       ║
-- ║  Design  : Professional Dark UI · Single Window · Tabbed                ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

local ENV = getgenv()
if ENV.QOS_Instance then pcall(function() ENV.QOS_Instance:Destroy() end) end
if ENV.QOS_Connections then
    for _, c in pairs(ENV.QOS_Connections) do pcall(function() c:Disconnect() end) end
end
ENV.QOS_Connections = {}
ENV.QOS_ActiveTab   = nil
ENV.QOS_Unlocked    = false
ENV.QOS_APIKey      = nil
ENV.QOS_DeviceMode  = nil

-- ═══════════════════════════════════════════════════════════════════════
-- SERVICIOS
-- ═══════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LP        = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid  = Character:FindFirstChildOfClass("Humanoid")
local DNAME     = LP.DisplayName
local UNAME     = LP.Name
local GNAME     = game.Name or "Roblox"

-- ═══════════════════════════════════════════════════════════════════════
-- RESPONSIVE
-- ═══════════════════════════════════════════════════════════════════════
local function SS() return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720) end
local function IsMobile() local s=SS() return s.X < 650 or UserInputService.TouchEnabled end

-- ═══════════════════════════════════════════════════════════════════════
-- PALETA
-- ═══════════════════════════════════════════════════════════════════════
local C = {
    -- Backgrounds
    BG0  = Color3.fromRGB(8,   8,  14),   -- más oscuro
    BG1  = Color3.fromRGB(12,  12,  20),   -- base
    BG2  = Color3.fromRGB(17,  17,  28),   -- panel
    BG3  = Color3.fromRGB(22,  22,  36),   -- card
    BG4  = Color3.fromRGB(28,  28,  45),   -- hover
    BGS  = Color3.fromRGB(10,  10,  17),   -- sidebar
    BGH  = Color3.fromRGB(14,  14,  22),   -- header
    -- Acento principal (violeta/delta)
    P1   = Color3.fromRGB(130,  80, 255),  -- violeta
    P2   = Color3.fromRGB(160, 110, 255),  -- violeta claro
    P3   = Color3.fromRGB( 80,  40, 180),  -- violeta oscuro
    -- Acento secundario (cyan)
    A1   = Color3.fromRGB( 80, 180, 255),  -- cyan
    A2   = Color3.fromRGB( 40, 140, 220),  -- cyan oscuro
    -- Texto
    TW   = Color3.fromRGB(230, 230, 240),  -- blanco
    TS   = Color3.fromRGB(150, 150, 175),  -- secundario
    TM   = Color3.fromRGB( 80,  80, 105),  -- muted
    TG   = Color3.fromRGB( 60, 210, 120),  -- verde
    TR   = Color3.fromRGB(255,  70,  70),  -- rojo
    TY   = Color3.fromRGB(255, 200,  60),  -- amarillo
    -- Borders
    BR0  = Color3.fromRGB( 35,  35,  55),  -- sutil
    BR1  = Color3.fromRGB( 60,  50, 110),  -- medio
    BR2  = Color3.fromRGB( 95,  70, 200),  -- bright
    -- Toggle
    TON  = Color3.fromRGB( 50, 200, 120),
    TOFF = Color3.fromRGB( 40,  40,  65),
}

-- ═══════════════════════════════════════════════════════════════════════
-- TWEEN INFOS
-- ═══════════════════════════════════════════════════════════════════════
local TI = {
    SNAP   = TweenInfo.new(0.08, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out),
    MED    = TweenInfo.new(0.28, Enum.EasingStyle.Quart,   Enum.EasingDirection.Out),
    SLOW   = TweenInfo.new(0.50, Enum.EasingStyle.Quint,   Enum.EasingDirection.Out),
    BOUNCE = TweenInfo.new(0.45, Enum.EasingStyle.Back,    Enum.EasingDirection.Out),
    SINE   = TweenInfo.new(1.40, Enum.EasingStyle.Sine,    Enum.EasingDirection.InOut),
    PULSE  = TweenInfo.new(1.00, Enum.EasingStyle.Sine,    Enum.EasingDirection.InOut, -1, true),
}

-- ═══════════════════════════════════════════════════════════════════════
-- UTILIDADES
-- ═══════════════════════════════════════════════════════════════════════
local function Make(class, props, parent)
    local i = Instance.new(class)
    for k,v in pairs(props) do pcall(function() i[k]=v end) end
    if parent then i.Parent=parent end
    return i
end
local function MkFrame(p,par)  return Make("Frame",p,par) end
local function MkLabel(p,par)  return Make("TextLabel",p,par) end
local function MkBtn(p,par)    return Make("TextButton",p,par) end
local function MkBox(p,par)    return Make("TextBox",p,par) end
local function MkScroll(p,par) return Make("ScrollingFrame",p,par) end
local function Tw(i,ti,props)  TweenService:Create(i,ti,props):Play() end
local function Corner(r,p)     local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=p;return c end
local function Stroke(t,col,p) local s=Instance.new("UIStroke");s.Thickness=t;s.Color=col or C.BR0;s.Parent=p;return s end
local function Pad(t,r,b,l,p)
    local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,t or 0);u.PaddingRight=UDim.new(0,r or 0)
    u.PaddingBottom=UDim.new(0,b or 0);u.PaddingLeft=UDim.new(0,l or 0)
    u.Parent=p;return u
end
local function ListL(props,p)
    local l=Instance.new("UIListLayout")
    for k,v in pairs(props or {}) do pcall(function() l[k]=v end) end
    l.Parent=p;return l
end
local function Grad(c0,c1,rot,p)
    local g=Instance.new("UIGradient")
    g.Color=ColorSequence.new(c0,c1);g.Rotation=rot or 90;g.Parent=p;return g
end
local function Track(conn) table.insert(ENV.QOS_Connections,conn);return conn end

local function Hover(btn, colOff, colOn)
    btn.MouseEnter:Connect(function() Tw(btn,TI.FAST,{BackgroundColor3=colOn}) end)
    btn.MouseLeave:Connect(function() Tw(btn,TI.FAST,{BackgroundColor3=colOff}) end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- ROOT GUI
-- ═══════════════════════════════════════════════════════════════════════
local ScreenGui = Make("ScreenGui",{
    Name="QuantumOS_v4", ResetOnSpawn=false, IgnoreGuiInset=true,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
}, PlayerGui)
ENV.QOS_Instance = ScreenGui

-- Fondo oscuro global
local BG = MkFrame({
    Name="BG", Size=UDim2.fromScale(1,1),
    BackgroundColor3=C.BG0, BorderSizePixel=0, ZIndex=1, Visible=false,
}, ScreenGui)

-- ═══════════════════════════════════════════════════════════════════════
-- AI SYSTEM
-- ═══════════════════════════════════════════════════════════════════════
local AI = {}
AI.ORCH  = "meta-llama/llama-3.3-70b-instruct:free"
AI.MODEL = {
    GAME     = "nvidia/nemotron-3-super-120b-a12b:free",
    CODE     = "qwen/qwen3-coder:free",
    STRATEGY = "deepseek/deepseek-v4-flash:free",
    CREATIVE = "google/gemma-4-31b-it:free",
    FAST     = "meta-llama/llama-3.2-3b-instruct:free",
}
AI.META = {
    GAME     = {icon="🎮", name="Game Analyst",   color=Color3.fromRGB(255,145,0)},
    CODE     = {icon="💻", name="Code Expert",    color=Color3.fromRGB(0,220,180)},
    STRATEGY = {icon="⚔",  name="Strategy Agent", color=Color3.fromRGB(225,55,55)},
    CREATIVE = {icon="🎨", name="Creative Agent", color=Color3.fromRGB(195,100,255)},
    FAST     = {icon="⚡", name="Fast Agent",     color=Color3.fromRGB(255,220,55)},
}
AI.SYS = {
    ORCH     = [[Eres el Orquestador del Quantum OS (Roblox). Responde SOLO este JSON sin texto extra:
{"agent":"GAME|CODE|STRATEGY|CREATIVE|FAST","reason":"motivo"}
GAME=mecánicas/items/juego, CODE=scripts/lua/errores, STRATEGY=builds/estrategia, CREATIVE=ideas/personalización, FAST=saludos/simples
Juego actual: ]]..GNAME,
    GAME     = "Eres el Game Analyst del Quantum OS. Experto en '"..GNAME.."'. Analiza mecánicas, items, bosses con detalle. Responde en español, máx 130 palabras.",
    CODE     = "Eres el Code Expert del Quantum OS. Experto Lua/Roblox para Delta Executor. Ayuda con scripts, bugs, optimización. Responde en español con código limpio. Máx 160 palabras.",
    STRATEGY = "Eres el Strategy Agent del Quantum OS. Experto en '"..GNAME.."'. Estrategias óptimas, builds, farming. Responde en español, conciso. Máx 130 palabras.",
    CREATIVE = "Eres el Creative Agent del Quantum OS. Ideas de personalización, roleplay, diseño para Roblox. Responde en español con entusiasmo. Máx 110 palabras.",
    FAST     = "Eres el asistente rápido del Quantum OS para '"..GNAME.."'. Breve, amigable, directo en español. Máx 70 palabras.",
}

local function OR_Call(model, sys, usr, maxTok)
    maxTok = maxTok or 320
    local key = ENV.QOS_APIKey
    if not key or key=="" then return nil,"Sin API Key" end
    local ok, res = pcall(function()
        local body = HttpService:JSONEncode({
            model=model, max_tokens=maxTok,
            messages={{role="system",content=sys},{role="user",content=usr}},
        })
        local r = HttpService:RequestAsync({
            Url="https://openrouter.ai/api/v1/chat/completions", Method="POST",
            Headers={
                ["Authorization"]="Bearer "..key,
                ["Content-Type"]="application/json",
                ["HTTP-Referer"]="https://lxndxn-qos.rblx",
                ["X-Title"]="LXNDXN Quantum OS",
            }, Body=body,
        })
        if r.StatusCode ~= 200 then error("HTTP "..r.StatusCode) end
        local d = HttpService:JSONDecode(r.Body)
        if d.error then error(d.error.message or "API error") end
        return d.choices and d.choices[1] and d.choices[1].message and d.choices[1].message.content
    end)
    if ok then return res,nil else return nil,tostring(res) end
end

-- VERIFY API KEY (fix rate limit)
local function VerifyAPIKey(key, cb)
    task.spawn(function()
        local ok, err = pcall(function()
            local body = HttpService:JSONEncode({
                model=AI.MODEL.FAST, max_tokens=16,
                messages={{role="user",content="hola"}},
            })
            local r = HttpService:RequestAsync({
                Url="https://openrouter.ai/api/v1/chat/completions", Method="POST",
                Headers={
                    ["Authorization"]="Bearer "..key,
                    ["Content-Type"]="application/json",
                    ["HTTP-Referer"]="https://lxndxn-qos.rblx",
                    ["X-Title"]="LXNDXN Quantum OS",
                }, Body=body,
            })
            if r.StatusCode==200 or r.StatusCode==429 then
                return true
            elseif r.StatusCode==401 then
                error("API Key inválida · Revisa que sea correcta")
            elseif r.StatusCode==402 then
                error("Sin créditos · Verifica tu cuenta OpenRouter")
            elseif r.StatusCode==403 then
                error("Acceso denegado · Cuenta suspendida")
            else
                local ok2,d=pcall(function() return HttpService:JSONDecode(r.Body) end)
                if ok2 and d and d.error then error(d.error.message or "Error") else error("HTTP "..r.StatusCode) end
            end
        end)
        if ok then ENV.QOS_APIKey=key; cb(true,"Conexión verificada")
        else cb(false,tostring(err):gsub(".*: ","")) end
    end)
end

local function OracleQuery(msg, onThink, onAgent, onResp, onErr)
    task.spawn(function()
        if onThink then onThink("Orquestador analizando...") end
        local orchRes = OR_Call(AI.ORCH, AI.SYS.ORCH, msg, 80)
        local agentKey = "FAST"
        if orchRes then
            local ok2,dec = pcall(function() return HttpService:JSONDecode(orchRes) end)
            if ok2 and dec and dec.agent then agentKey=dec.agent end
        end
        local meta = AI.META[agentKey] or AI.META.FAST
        if onAgent then onAgent(agentKey,meta) end
        if onThink then onThink(meta.icon.." "..meta.name.." procesando...") end
        local resp,err = OR_Call(AI.MODEL[agentKey] or AI.MODEL.FAST, AI.SYS[agentKey] or AI.SYS.FAST, msg, 320)
        if resp then if onResp then onResp(resp,meta) end
        else if onErr then onErr(err or "Error desconocido") end end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════
local NT = {
    INFO    = {icon="ℹ", c=C.A1,  bg=Color3.fromRGB(10,20,35)},
    SUCCESS = {icon="✓", c=C.TG,  bg=Color3.fromRGB(5,28,15)},
    WARNING = {icon="⚠", c=C.TY,  bg=Color3.fromRGB(35,25,5)},
    ERROR   = {icon="✕", c=C.TR,  bg=Color3.fromRGB(40,5,5)},
    ORACLE  = {icon="🔮",c=C.P2,  bg=Color3.fromRGB(20,5,45)},
    SYSTEM  = {icon="⬡", c=C.P1,  bg=Color3.fromRGB(15,5,35)},
}
local nStack, NW, NH, NM = {}, 290, 68, 8

local function PushNotif(title, body, typ, dur)
    typ=typ or "INFO"; dur=dur or 3.5
    local t=NT[typ] or NT.INFO
    if #nStack>=4 then return end
    local slot=#nStack+1; table.insert(nStack,slot)
    local yOff=-(slot*(NH+NM))
    local NF=MkFrame({
        Size=UDim2.new(0,NW,0,NH), Position=UDim2.new(1,14,1,yOff),
        BackgroundColor3=t.bg, ZIndex=1100+slot,
    },ScreenGui)
    Corner(10,NF); Stroke(1,t.c,NF)
    local Acc=MkFrame({Size=UDim2.new(0,3,1,-12),Position=UDim2.new(0,0,0,6),BackgroundColor3=t.c,ZIndex=1101+slot},NF); Corner(2,Acc)
    MkLabel({Size=UDim2.new(0,36,1,0),BackgroundTransparency=1,Text=t.icon,TextSize=17,TextColor3=t.c,ZIndex=1102+slot},NF)
    MkLabel({Size=UDim2.new(1,-58,0,20),Position=UDim2.new(0,44,0,10),BackgroundTransparency=1,Text=title,
        Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1102+slot},NF)
    MkLabel({Size=UDim2.new(1,-58,0,20),Position=UDim2.new(0,44,0,28),BackgroundTransparency=1,Text=body,
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1102+slot},NF)
    local PBG=MkFrame({Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,1,-2),BackgroundColor3=C.BG3,ZIndex=1103+slot},NF)
    local PF=MkFrame({Size=UDim2.new(1,0,1,0),BackgroundColor3=t.c,ZIndex=1104+slot},PBG)
    local CBtn=MkBtn({Size=UDim2.new(0,18,0,18),Position=UDim2.new(1,-22,0,4),BackgroundTransparency=1,
        Text="✕",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.TM,ZIndex=1105+slot},NF)
    Tw(NF,TI.BOUNCE,{Position=UDim2.new(1,-(NW+10),1,yOff)})
    Tw(PF,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,1,0)})
    local function Dismiss()
        Tw(NF,TI.MED,{Position=UDim2.new(1,14,1,yOff)}); task.wait(0.35)
        pcall(function() local idx=table.find(nStack,slot); if idx then table.remove(nStack,idx) end; NF:Destroy() end)
    end
    CBtn.MouseButton1Click:Connect(Dismiss)
    task.delay(dur,function() pcall(Dismiss) end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOOT SCREEN
-- ═══════════════════════════════════════════════════════════════════════
local function CreateBoot()
    local Boot=MkFrame({Name="Boot",Size=UDim2.fromScale(1,1),BackgroundColor3=C.BG0,ZIndex=200},ScreenGui)

    local W=MkFrame({
        Size=UDim2.new(0,340,0,320), Position=UDim2.new(0.5,-170,0.5,-160),
        BackgroundColor3=C.BG2, ZIndex=201,
    },Boot); Corner(20,W); Stroke(1,C.BR1,W)

    -- Logo area
    local LogoF=MkFrame({Size=UDim2.new(0,72,0,72),Position=UDim2.new(0.5,-36,0,28),BackgroundColor3=C.P3,ZIndex=202},W)
    Corner(36,LogoF); Stroke(2,C.P1,LogoF)
    local LogoL=MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="Δ",Font=Enum.Font.GothamBold,TextSize=38,TextColor3=C.TW,ZIndex=203},LogoF)
    task.spawn(function()
        while LogoL and LogoL.Parent do
            Tw(LogoL,TI.SINE,{TextColor3=C.P2}); task.wait(1.4)
            Tw(LogoL,TI.SINE,{TextColor3=C.TW}); task.wait(1.4)
        end
    end)

    MkLabel({Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,112),BackgroundTransparency=1,
        Text="QUANTUM OS",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=C.TW,ZIndex=202},W)
    MkLabel({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,140),BackgroundTransparency=1,
        Text="v4.0 · Delta Edition · Multi-Agent AI",Font=Enum.Font.Gotham,TextSize=11,TextColor3=C.A1,ZIndex=202},W)

    local WelL=MkLabel({Size=UDim2.new(1,-40,0,32),Position=UDim2.new(0,20,0,168),BackgroundTransparency=1,
        Text="",Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TS,TextWrapped=true,ZIndex=202},W)

    local PBG=MkFrame({Size=UDim2.new(1,-40,0,4),Position=UDim2.new(0,20,0,248),BackgroundColor3=C.BG4,ZIndex=202},W); Corner(2,PBG)
    local PF=MkFrame({Size=UDim2.new(0,0,1,0),BackgroundColor3=C.P1,ZIndex=203},PBG); Corner(2,PF)
    Grad(C.P1,C.A1,0,PF)
    local PL=MkLabel({Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,5),BackgroundTransparency=1,
        Text="Iniciando...",Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,ZIndex=202},PBG)

    MkLabel({Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-18),BackgroundTransparency=1,
        Text="LXNDXN · Delta Edition · v4.0",Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,ZIndex=202},W)

    task.spawn(function()
        task.wait(0.4)
        WelL.Text="Bienvenido, "..DNAME.." · Cargando sistema..."
        task.wait(1.2)
        local steps={
            {0.15,"Cargando kernel..."},{0.30,"Inicializando UI..."},
            {0.50,"Conectando AI Multi-Agente..."},{0.70,"Activando agentes..."},
            {0.88,"Verificando executor..."},{1.0,"Listo."},
        }
        for _,s in ipairs(steps) do
            Tw(PF,TI.MED,{Size=UDim2.new(s[1],0,1,0)}); PL.Text=s[2]; task.wait(0.38)
        end
        task.wait(0.5)
        Tw(Boot,TI.SLOW,{BackgroundTransparency=1})
        task.wait(0.6); Boot:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- LOGIN
-- ═══════════════════════════════════════════════════════════════════════
local function CreateLogin(onSuccess)
    local mob=IsMobile(); local s=SS()
    local PW=mob and math.min(s.X-24,380) or 420
    local PH=mob and 460 or 520
    local PX=(s.X-PW)/2; local PY=math.max(8,(s.Y-PH)/2)

    local LS=MkFrame({Name="Login",Size=UDim2.fromScale(1,1),BackgroundColor3=C.BG0,ZIndex=90},ScreenGui)

    local Panel=MkFrame({
        Size=UDim2.new(0,PW,0,PH), Position=UDim2.new(0,PX,0,PY),
        BackgroundColor3=C.BG2, ZIndex=92,
    },LS); Corner(18,Panel); Stroke(1,C.BR1,Panel)

    -- Top accent line
    local TL=MkFrame({Size=UDim2.new(1,0,0,3),BackgroundColor3=C.P1,ZIndex=93},Panel)
    Corner(18,TL); Grad(C.P3,C.A1,0,TL)

    -- Logo
    local LF=MkFrame({Size=UDim2.new(0,64,0,64),Position=UDim2.new(0.5,-32,0,22),BackgroundColor3=C.P3,ZIndex=93},Panel)
    Corner(32,LF); Stroke(2,C.P1,LF)
    local LI=MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="Δ",Font=Enum.Font.GothamBold,TextSize=36,TextColor3=C.TW,ZIndex=94},LF)
    task.spawn(function()
        while LI and LI.Parent do Tw(LI,TI.SINE,{TextColor3=C.P2}); task.wait(1.4); Tw(LI,TI.SINE,{TextColor3=C.TW}); task.wait(1.4) end
    end)

    MkLabel({Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,0,96),BackgroundTransparency=1,
        Text="QUANTUM OS",Font=Enum.Font.GothamBold,TextSize=mob and 19 or 22,TextColor3=C.TW,ZIndex=93},Panel)
    MkLabel({Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,0,124),BackgroundTransparency=1,
        Text="Multi-Agent AI · Delta Edition",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.A1,ZIndex=93},Panel)

    -- Divider
    MkFrame({Size=UDim2.new(0.8,0,0,1),Position=UDim2.new(0.1,0,0,152),BackgroundColor3=C.BR0,ZIndex=93},Panel)

    -- Label
    MkLabel({Size=UDim2.new(1,-32,0,14),Position=UDim2.new(0,16,0,162),BackgroundTransparency=1,
        Text="OPENROUTER API KEY",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=93},Panel)

    -- Input
    local KB=MkBox({
        Size=UDim2.new(1,-32,0,44),Position=UDim2.new(0,16,0,178),
        BackgroundColor3=C.BG4,Text="",PlaceholderText="sk-or-v1-xxxxxxxxxxxxxxxxxx",
        Font=Enum.Font.Code,TextSize=12,TextColor3=C.TW,PlaceholderColor3=C.TM,
        ClearTextOnFocus=false,ZIndex=94,
    },Panel); Corner(10,KB); Pad(0,12,0,12,KB)
    local KBS=Stroke(1,C.BR0,KB)
    KB.Focused:Connect(function() Tw(KBS,TI.FAST,{Color=C.P1}) end)
    KB.FocusLost:Connect(function() Tw(KBS,TI.FAST,{Color=C.BR0}) end)

    -- Status
    local SL=MkLabel({Size=UDim2.new(1,-32,0,18),Position=UDim2.new(0,16,0,226),BackgroundTransparency=1,
        Text="",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TM,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=93},Panel)

    local Spinner=MkLabel({Size=UDim2.new(0,28,0,28),Position=UDim2.new(0.5,-14,0,226),BackgroundTransparency=1,
        Text="◌",Font=Enum.Font.GothamBold,TextSize=22,TextColor3=C.A1,Visible=false,ZIndex=95},Panel)

    -- Verify button
    local LBtn=MkBtn({
        Size=UDim2.new(1,-32,0,mob and 46 or 50),Position=UDim2.new(0,16,0,250),
        BackgroundColor3=C.P1,Text="⚡  VERIFICAR API KEY",
        Font=Enum.Font.GothamBold,TextSize=mob and 13 or 14,TextColor3=Color3.new(1,1,1),ZIndex=94,
    },Panel); Corner(12,LBtn); Grad(Color3.fromRGB(100,50,220),Color3.fromRGB(60,20,160),135,LBtn)
    Hover(LBtn,C.P1,C.P2)

    -- Get key button
    local GK=MkBtn({
        Size=UDim2.new(1,-32,0,38),Position=UDim2.new(0,16,0,mob and 306 or 310),
        BackgroundColor3=C.BG3,Text="🔑  Obtener API Key gratuita →",
        Font=Enum.Font.GothamSemibold,TextSize=11,TextColor3=C.A1,ZIndex=94,
    },Panel); Corner(10,GK); Stroke(1,C.BR1,GK)
    GK.MouseEnter:Connect(function() Tw(GK,TI.FAST,{BackgroundColor3=C.BG4}) end)
    GK.MouseLeave:Connect(function() Tw(GK,TI.FAST,{BackgroundColor3=C.BG3}) end)
    GK.MouseButton1Click:Connect(function()
        pcall(function() setclipboard("https://openrouter.ai/keys") end)
        SL.Text="✓ openrouter.ai/keys copiado"; SL.TextColor3=C.A1
    end)

    -- Footer
    MkLabel({Size=UDim2.new(1,-32,0,14),Position=UDim2.new(0,16,1,-22),BackgroundTransparency=1,
        Text="🔒 Key usada localmente · No almacenada · LXNDXN v4.0",
        Font=Enum.Font.Gotham,TextSize=8,TextColor3=C.TM,ZIndex=93},Panel)

    -- Verify logic
    local function DoVerify()
        local key=KB.Text:gsub("%s+","")
        if key=="" then SL.Text="⚠ Ingresa tu API Key."; SL.TextColor3=C.TY; return end
        LBtn.Visible=false; Spinner.Visible=true
        SL.Text="Conectando con OpenRouter..."; SL.TextColor3=C.A1
        local spin=true
        task.spawn(function()
            local fr={"◌","◍","◎","●","◎","◍"}; local i=1
            while spin do Spinner.Text=fr[i]; i=i%#fr+1; task.wait(0.09) end
        end)
        VerifyAPIKey(key,function(success,msg)
            spin=false; Spinner.Visible=false; LBtn.Visible=true
            if success then
                SL.Text="✓ Verificada · Conectado"; SL.TextColor3=C.TG
                Tw(LBtn,TI.FAST,{BackgroundColor3=C.TON}); LBtn.Text="✓  CONECTADO"
                task.wait(0.8); Tw(LS,TI.MED,{BackgroundTransparency=1}); task.wait(0.4); LS:Destroy(); onSuccess()
            else
                SL.Text="✗ "..(msg or "Key inválida"); SL.TextColor3=C.TR
                for _=1,4 do
                    Tw(Panel,TI.SNAP,{Position=UDim2.new(0,PX+5,0,PY)}); task.wait(0.05)
                    Tw(Panel,TI.SNAP,{Position=UDim2.new(0,PX-5,0,PY)}); task.wait(0.05)
                end
                Tw(Panel,TI.SNAP,{Position=UDim2.new(0,PX,0,PY)})
            end
        end)
    end
    LBtn.MouseButton1Click:Connect(DoVerify)
    KB.FocusLost:Connect(function(e) if e then DoVerify() end end)
    return LS
end

-- ═══════════════════════════════════════════════════════════════════════
-- COMPONENTES REUTILIZABLES
-- ═══════════════════════════════════════════════════════════════════════
local function MkToggle(parent, label, def, desc, onChange)
    local Row=MkFrame({Size=UDim2.new(1,0,0,54),BackgroundColor3=C.BG3,ZIndex=20},parent)
    Corner(10,Row); Stroke(1,C.BR0,Row)
    MkLabel({Size=UDim2.new(1,-80,0,18),Position=UDim2.new(0,14,0,10),BackgroundTransparency=1,
        Text=label,Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Row)
    if desc then
        MkLabel({Size=UDim2.new(1,-80,0,14),Position=UDim2.new(0,14,0,30),BackgroundTransparency=1,
            Text=desc,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TM,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Row)
    end
    local Tr=MkFrame({Size=UDim2.new(0,44,0,24),Position=UDim2.new(1,-56,0.5,-12),
        BackgroundColor3=def and C.TON or C.TOFF,ZIndex=21},Row); Corner(12,Tr)
    local Th=MkFrame({Size=UDim2.new(0,18,0,18),
        Position=def and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=Color3.new(1,1,1),ZIndex=22},Tr); Corner(9,Th)
    local state=def
    local TB=MkBtn({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=23},Tr)
    TB.MouseButton1Click:Connect(function()
        state=not state
        Tw(Tr,TI.FAST,{BackgroundColor3=state and C.TON or C.TOFF})
        Tw(Th,TI.FAST,{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if onChange then onChange(state) end
    end)
    return Row, function() return state end
end

local function MkSlider(parent, label, minV, maxV, defV, suf, desc, onChange)
    local Row=MkFrame({Size=UDim2.new(1,0,0,68),BackgroundColor3=C.BG3,ZIndex=20},parent)
    Corner(10,Row); Stroke(1,C.BR0,Row)
    MkLabel({Size=UDim2.new(1,-70,0,18),Position=UDim2.new(0,14,0,10),BackgroundTransparency=1,
        Text=label,Font=Enum.Font.GothamSemibold,TextSize=13,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Row)
    if desc then
        MkLabel({Size=UDim2.new(1,-70,0,13),Position=UDim2.new(0,14,0,28),BackgroundTransparency=1,
            Text=desc,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TM,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Row)
    end
    local VL=MkLabel({Size=UDim2.new(0,56,0,18),Position=UDim2.new(1,-68,0,10),BackgroundTransparency=1,
        Text=tostring(defV)..(suf or ""),Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=21},Row)
    local Tr=MkFrame({Size=UDim2.new(1,-28,0,5),Position=UDim2.new(0,14,0,50),BackgroundColor3=C.BG4,ZIndex=21},Row); Corner(3,Tr)
    local ratio=(defV-minV)/(maxV-minV)
    local Fi=MkFrame({Size=UDim2.new(ratio,0,1,0),BackgroundColor3=C.P1,ZIndex=22},Tr); Corner(3,Fi); Grad(C.P1,C.A1,0,Fi)
    local Kn=MkFrame({Size=UDim2.new(0,14,0,14),Position=UDim2.new(ratio,-7,0.5,-7),BackgroundColor3=C.TW,ZIndex=23},Tr)
    Corner(7,Kn); Stroke(2,C.P1,Kn)
    local drag=false
    local function Upd(x)
        local t2=math.clamp((x-Tr.AbsolutePosition.X)/Tr.AbsoluteSize.X,0,1)
        local v=math.floor(minV+t2*(maxV-minV))
        Tw(Fi,TI.SNAP,{Size=UDim2.new(t2,0,1,0)}); Tw(Kn,TI.SNAP,{Position=UDim2.new(t2,-7,0.5,-7)})
        VL.Text=v..(suf or ""); if onChange then onChange(v) end
    end
    Tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; Upd(i.Position.X) end
    end)
    Track(UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Upd(i.Position.X) end
    end))
    Track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end))
    return Row
end

local function SectionLabel(parent, text)
    local F=MkFrame({Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,ZIndex=20},parent)
    MkLabel({Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,
        Text=text,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},F)
    MkFrame({Size=UDim2.new(1,-14,0,1),Position=UDim2.new(0,14,1,-1),BackgroundColor3=C.BR0,ZIndex=21},F)
    return F
end

local function ActionBtn(parent, label, icon, color, onClick)
    color = color or C.P1
    local Btn=MkBtn({
        Size=UDim2.new(1,0,0,46),BackgroundColor3=C.BG3,
        Text="",ZIndex=20,
    },parent); Corner(10,Btn); Stroke(1,C.BR0,Btn)
    local Accent=MkFrame({Size=UDim2.new(0,3,0.55,0),Position=UDim2.new(0,0,0.225,0),BackgroundColor3=color,ZIndex=21},Btn); Corner(2,Accent)
    if icon then MkLabel({Size=UDim2.new(0,36,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=icon,TextSize=16,TextColor3=color,ZIndex=21},Btn) end
    MkLabel({Size=UDim2.new(1,-58,1,0),Position=UDim2.new(0,icon and 44 or 14,0,0),BackgroundTransparency=1,
        Text=label,Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=21},Btn)
    MkLabel({Size=UDim2.new(0,20,0,20),Position=UDim2.new(1,-28,0.5,-10),BackgroundTransparency=1,
        Text="›",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TM,ZIndex=21},Btn)
    Btn.MouseEnter:Connect(function() Tw(Btn,TI.FAST,{BackgroundColor3=C.BG4}) end)
    Btn.MouseLeave:Connect(function() Tw(Btn,TI.FAST,{BackgroundColor3=C.BG3}) end)
    Btn.MouseButton1Click:Connect(function() if onClick then onClick() end end)
    return Btn
end

-- ═══════════════════════════════════════════════════════════════════════
-- MÓDULOS GAMEPLAY
-- ═══════════════════════════════════════════════════════════════════════
local FlyMod={Active=false}
FlyMod.On=function()
    FlyMod.Active=true
    pcall(function()
        local hrp=Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local bg=Instance.new("BodyGyro"); bg.P=9e4; bg.D=1e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.Parent=hrp
        local bv=Instance.new("BodyVelocity"); bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Parent=hrp
        FlyMod._bg=bg; FlyMod._bv=bv
        if Humanoid then Humanoid.PlatformStand=true end
        Track(RunService.RenderStepped:Connect(function()
            if not FlyMod.Active then return end
            local cam=workspace.CurrentCamera; local dir=Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir=dir+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir=dir+Vector3.new(0,-1,0) end
            bv.Velocity=dir.Magnitude>0 and dir.Unit*70 or Vector3.new()
            bg.CFrame=cam.CFrame
        end))
    end)
end
FlyMod.Off=function()
    FlyMod.Active=false
    pcall(function()
        if FlyMod._bg then FlyMod._bg:Destroy() end
        if FlyMod._bv then FlyMod._bv:Destroy() end
        if Humanoid then Humanoid.PlatformStand=false end
    end)
end

local ESPMod={Active=false,HL={}}
ESPMod.On=function()
    ESPMod.Active=true
    task.spawn(function()
        while ESPMod.Active do
            for _,p in pairs(Players:GetPlayers()) do
                if p~=LP and p.Character and not ESPMod.HL[p.Name] then
                    local h=Instance.new("Highlight"); h.Name="QOS_ESP_"..p.Name
                    h.Adornee=p.Character; h.OutlineColor=C.A1; h.FillTransparency=0.65; h.Parent=p.Character
                    ESPMod.HL[p.Name]=h
                end
            end
            task.wait(2)
        end
    end)
end
ESPMod.Off=function()
    ESPMod.Active=false
    for _,h in pairs(ESPMod.HL) do pcall(function() h:Destroy() end) end; ESPMod.HL={}
end

local GodMod={Active=false}
GodMod.On=function() GodMod.Active=true; task.spawn(function()
    while GodMod.Active and Humanoid and Humanoid.Parent do
        pcall(function() Humanoid.Health=Humanoid.MaxHealth end); task.wait(0.1)
    end
end) end
GodMod.Off=function() GodMod.Active=false end

local NoClipMod={Active=false}
NoClipMod.On=function()
    NoClipMod.Active=true
    Track(RunService.Stepped:Connect(function()
        if not NoClipMod.Active then return end
        if Character then
            for _,p in pairs(Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end))
end
NoClipMod.Off=function() NoClipMod.Active=false end

local MovMod={}
MovMod.Speed=function(v) pcall(function() if Humanoid then Humanoid.WalkSpeed=v end end) end
MovMod.Jump=function(v)  pcall(function() if Humanoid then Humanoid.JumpPower=v end end) end

-- ═══════════════════════════════════════════════════════════════════════
-- VENTANA PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════════
local MainWin, Sidebar, ContentArea, CurrTabFrame = nil,nil,nil,nil
local SbBtns = {}

local function ClearContent()
    if CurrTabFrame then CurrTabFrame:Destroy(); CurrTabFrame=nil end
end

local function SetActiveTab(name)
    for tname,btn in pairs(SbBtns) do
        local act=(tname==name)
        Tw(btn,TI.FAST,{BackgroundColor3=act and C.P3 or Color3.fromRGB(0,0,0)})
        Tw(btn,TI.FAST,{BackgroundTransparency=act and 0 or 1})
        local ind=btn:FindFirstChild("Ind"); if ind then ind.Visible=act end
        local ic=btn:FindFirstChild("Icon"); if ic then
            Tw(ic,TI.FAST,{TextColor3=act and C.TW or C.TM})
        end
        local lb=btn:FindFirstChild("Lbl"); if lb then
            Tw(lb,TI.FAST,{TextColor3=act and C.TW or C.TS})
        end
    end
end

local function CreateMainWindow(mode)
    local mob=IsMobile()
    local SBW=mob and 190 or 210
    local HH=mob and 48 or 54

    MainWin=MkFrame({Name="MainWin",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=10},ScreenGui)
    BG.Visible=true

    -- ── HEADER ─────────────────────────────────────────────────────────
    local Header=MkFrame({
        Name="Header",Size=UDim2.new(1,0,0,HH),
        BackgroundColor3=C.BGH,ZIndex=12,
    },MainWin); Stroke(1,C.BR0,Header)

    -- Logo + título
    local HLogoF=MkFrame({Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,12,0.5,-15),BackgroundColor3=C.P3,ZIndex=13},Header)
    Corner(15,HLogoF)
    MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="Δ",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TW,ZIndex=14},HLogoF)

    MkLabel({Size=UDim2.new(0,160,0,18),Position=UDim2.new(0,50,0,mob and 6 or 8),BackgroundTransparency=1,
        Text="QUANTUM OS",Font=Enum.Font.GothamBold,TextSize=mob and 12 or 14,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},Header)
    MkLabel({Size=UDim2.new(0,160,0,12),Position=UDim2.new(0,50,0,mob and 25 or 28),BackgroundTransparency=1,
        Text="v4.0 · Multi-Agent AI",Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},Header)

    -- Game badge
    local GB=MkLabel({
        Size=UDim2.new(0,mob and 140 or 170,0,24),
        Position=UDim2.new(0.5,mob and -70 or -85,0.5,-12),
        BackgroundColor3=C.BG3,Text="🎮  "..GNAME:sub(1,14),
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,ZIndex=13,
    },Header); Corner(10,GB); Stroke(1,C.BR0,GB)

    -- Botones sistema (derecha)
    local SF=MkFrame({Size=UDim2.new(0,mob and 72 or 108,0,32),Position=UDim2.new(1,mob and -80 or -116,0.5,-16),BackgroundTransparency=1,ZIndex=13},Header)

    local function SysBtn(icon, col, xp, tip)
        local b=MkBtn({Size=UDim2.new(0,28,0,28),Position=UDim2.new(0,xp,0.5,-14),
            BackgroundColor3=C.BG3,Text=icon,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=col,ZIndex=14},SF)
        Corner(8,b); Hover(b,C.BG3,C.BG4); return b
    end

    local MinBtn=SysBtn("—",C.TS,0)
    local ClsBtn=SysBtn("✕",C.TR,mob and 36 or 72)
    if not mob then SysBtn("⚙",C.TS,36) end

    -- ── MINIMIZE / BOLITA ──────────────────────────────────────────────
    local RevealBall=MkBtn({
        Name="RevealBall",Size=UDim2.new(0,36,0,36),
        Position=UDim2.new(0,10,0.5,-18),
        BackgroundColor3=C.P3,Text="Δ",
        Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TW,
        Visible=false,ZIndex=999,
    },ScreenGui); Corner(18,RevealBall); Stroke(2,C.P1,RevealBall)
    task.spawn(function()
        while RevealBall and RevealBall.Parent do
            Tw(RevealBall,TI.SINE,{BackgroundColor3=C.P1}); task.wait(1.2)
            Tw(RevealBall,TI.SINE,{BackgroundColor3=C.P3}); task.wait(1.2)
        end
    end)

    local function HideOS()
        Tw(MainWin,TI.MED,{Size=UDim2.new(0,0,0,0)})
        task.delay(0.3,function()
            MainWin.Visible=false; BG.Visible=false; RevealBall.Visible=true
            Tw(RevealBall,TI.BOUNCE,{Size=UDim2.new(0,36,0,36)})
        end)
    end
    local function ShowOS()
        RevealBall.Visible=false; BG.Visible=true
        MainWin.Visible=true; Tw(MainWin,TI.BOUNCE,{Size=UDim2.fromScale(1,1)})
    end

    MinBtn.MouseButton1Click:Connect(HideOS)
    RevealBall.MouseButton1Click:Connect(ShowOS)
    ClsBtn.MouseButton1Click:Connect(function()
        Tw(MainWin,TI.MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.35); ScreenGui:Destroy()
    end)

    -- ── SIDEBAR ────────────────────────────────────────────────────────
    Sidebar=MkFrame({
        Name="Sidebar",Size=UDim2.new(0,SBW,1,-HH),Position=UDim2.new(0,0,0,HH),
        BackgroundColor3=C.BGS,ZIndex=11,
    },MainWin); Stroke(1,C.BR0,Sidebar)

    -- Perfil en sidebar
    local ProfF=MkFrame({Size=UDim2.new(1,-16,0,mob and 72 or 80),Position=UDim2.new(0,8,0,10),BackgroundColor3=C.BG3,ZIndex=12},Sidebar)
    Corner(12,ProfF); Stroke(1,C.BR0,ProfF)

    local Av=MkLabel({
        Size=UDim2.new(0,mob and 38 or 42,0,mob and 38 or 42),
        Position=UDim2.new(0,10,0.5,mob and -19 or -21),
        BackgroundColor3=C.P3,Text=DNAME:sub(1,2):upper(),
        Font=Enum.Font.GothamBold,TextSize=mob and 13 or 15,TextColor3=C.TW,ZIndex=13,
    },ProfF); Corner(21,Av); Stroke(2,C.P1,Av)

    local px=mob and 56 or 60
    MkLabel({Size=UDim2.new(1,-px-8,0,17),Position=UDim2.new(0,px,0,10),BackgroundTransparency=1,
        Text=DNAME,Font=Enum.Font.GothamBold,TextSize=mob and 11 or 12,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},ProfF)
    MkLabel({Size=UDim2.new(1,-px-8,0,13),Position=UDim2.new(0,px,0,28),BackgroundTransparency=1,
        Text="@"..UNAME,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13},ProfF)
    local OB=MkLabel({Size=UDim2.new(0,64,0,14),Position=UDim2.new(0,px,0,44),
        BackgroundColor3=Color3.fromRGB(0,40,18),Text="● AI Online",
        Font=Enum.Font.Gotham,TextSize=8,TextColor3=C.TG,ZIndex=13},ProfF); Corner(7,OB)

    -- Tabs scroll
    local TabScroll=MkScroll({
        Size=UDim2.new(1,0,1,-(mob and 94 or 104)),
        Position=UDim2.new(0,0,0,mob and 92 or 100),
        BackgroundTransparency=1,ScrollBarThickness=0,ZIndex=12,
    },Sidebar)
    local TabList=MkFrame({Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,ZIndex=12},TabScroll)
    ListL({Padding=UDim.new(0,1),SortOrder=Enum.SortOrder.LayoutOrder},TabList)

    local TABS={
        {name="START",          icon="⌂",  order=1},
        {name="SCRIPT HUB",     icon="⚡", order=2},
        {name="TOOLBOX",        icon="🛠", order=3},
        {name="SYSTEM SETTINGS",icon="⚙",  order=4},
        {name="FILE MANAGER",   icon="📁", order=5},
        {name="PROCESSES",      icon="📊", order=6},
        {name="MEDIA CENTER",   icon="🎵", order=7},
        {name="COMMUNITY",      icon="👥", order=8},
        {name="QUANTUM ORACLE", icon="🔮", order=9},
        {name="GAME BOOSTER",   icon="🚀", order=10},
        {name="CUSTOMIZER",     icon="🎨", order=11},
        {name="POWER",          icon="⏻",  order=12},
    }

    for _,tab in ipairs(TABS) do
        local Btn=MkBtn({
            Name=tab.name,
            Size=UDim2.new(1,-8,0,mob and 36 or 40),
            BackgroundColor3=Color3.fromRGB(0,0,0),
            BackgroundTransparency=1,Text="",LayoutOrder=tab.order,ZIndex=13,
        },TabList); Corner(8,Btn)

        local Ind=MkFrame({Name="Ind",Size=UDim2.new(0,3,0.5,0),Position=UDim2.new(0,0,0.25,0),
            BackgroundColor3=C.P1,Visible=false,ZIndex=14},Btn); Corner(2,Ind)

        local IconL=MkLabel({Name="Icon",Size=UDim2.new(0,24,1,0),Position=UDim2.new(0,12,0,0),
            BackgroundTransparency=1,Text=tab.icon,Font=Enum.Font.GothamBold,
            TextSize=mob and 14 or 15,TextColor3=C.TM,ZIndex=14},Btn)

        local LblL=MkLabel({Name="Lbl",Size=UDim2.new(1,-44,1,0),Position=UDim2.new(0,40,0,0),
            BackgroundTransparency=1,Text=tab.name,Font=Enum.Font.GothamSemibold,
            TextSize=mob and 9 or 10,TextColor3=C.TS,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=14},Btn)

        SbBtns[tab.name]=Btn

        Btn.MouseButton1Click:Connect(function()
            ClearContent(); SetActiveTab(tab.name); ENV.QOS_ActiveTab=tab.name
            local fk="QOS_Tab_"..tab.name:gsub("%s+","_")
            pcall(function() if _G[fk] then _G[fk]() end end)
        end)

        Btn.MouseEnter:Connect(function()
            if ENV.QOS_ActiveTab~=tab.name then Tw(Btn,TI.FAST,{BackgroundTransparency=0.75,BackgroundColor3=C.BG4}) end
        end)
        Btn.MouseLeave:Connect(function()
            if ENV.QOS_ActiveTab~=tab.name then Tw(Btn,TI.FAST,{BackgroundTransparency=1}) end
        end)
    end

    local TLL=TabList:FindFirstChildWhichIsA("UIListLayout")
    TLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabList.Size=UDim2.new(1,0,0,TLL.AbsoluteContentSize.Y+8)
    end)

    -- ── CONTENT AREA ───────────────────────────────────────────────────
    ContentArea=MkFrame({
        Name="ContentArea",Size=UDim2.new(1,-SBW,1,-HH),Position=UDim2.new(0,SBW,0,HH),
        BackgroundColor3=C.BG1,ZIndex=11,
    },MainWin)

    MainWin.Size=UDim2.new(0,0,0,0); MainWin.Position=UDim2.fromScale(0,0)
    Tw(MainWin,TI.BOUNCE,{Size=UDim2.fromScale(1,1)})
end

-- ═══════════════════════════════════════════════════════════════════════
-- HELPER: CONTENT HEADER
-- ═══════════════════════════════════════════════════════════════════════
local function ContentHeader(parent, title, subtitle)
    local mob=IsMobile()
    local H=MkFrame({Size=UDim2.new(1,0,0,mob and 52 or 60),BackgroundColor3=C.BG2,ZIndex=19},parent)
    Stroke(1,C.BR0,H)
    local Acc=MkFrame({Size=UDim2.new(0,3,0,mob and 28 or 34),Position=UDim2.new(0,14,0,mob and 12 or 13),BackgroundColor3=C.P1,ZIndex=20},H)
    Corner(2,Acc); Grad(C.P1,C.A1,90,Acc)
    MkLabel({Size=UDim2.new(1,-30,0,22),Position=UDim2.new(0,24,0,mob and 8 or 10),BackgroundTransparency=1,
        Text=title,Font=Enum.Font.GothamBold,TextSize=mob and 14 or 16,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=20},H)
    if subtitle then
        MkLabel({Size=UDim2.new(1,-30,0,13),Position=UDim2.new(0,24,0,mob and 32 or 36),BackgroundTransparency=1,
            Text=subtitle,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=20},H)
    end
    return H
end

local function ScrollTab(name)
    local Tab=MkFrame({Name="T_"..name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab
    local Sc=MkScroll({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=3,
        ScrollBarImageColor3=C.BR1,ZIndex=15},Tab)
    local Li=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},Sc)
    ListL({Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},Li)
    Pad(0,0,24,0,Li)
    local LL=Li:FindFirstChildWhichIsA("UIListLayout")
    LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sc.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+24)
    end)
    return Tab, Sc, Li
end

local function InnerList(parent)
    local F=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},parent)
    ListL({Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},F)
    Pad(10,14,4,14,F)
    return F
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: START
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_START"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("START")
    ContentHeader(Li,"START  ⌂","Panel de inicio · Quantum OS v4.0")

    -- Stats cards 2x2
    local GF=MkFrame({Size=UDim2.new(1,0,0,mob and 100 or 112),BackgroundTransparency=1,ZIndex=15},Li)
    local SG=MkFrame({Size=UDim2.new(1,-28,1,-12),Position=UDim2.new(0,14,0,6),BackgroundTransparency=1,ZIndex=15},GF)
    local UG=Instance.new("UIGridLayout"); UG.CellSize=UDim2.new(0.5,-6,1,-4); UG.CellPadding=UDim2.new(0,6,0,4); UG.Parent=SG

    for _,s in ipairs({
        {l="Jugador",v=DNAME:sub(1,10),i="👤",c=C.P2},
        {l="Juego",v=GNAME:sub(1,12),i="🎮",c=C.A1},
        {l="AI Status",v="Online",i="🤖",c=C.TG},
        {l="Agentes",v="5 activos",i="⬡",c=C.TY},
    }) do
        local Card=MkFrame({BackgroundColor3=C.BG3,ZIndex=16},SG); Corner(10,Card); Stroke(1,C.BR0,Card)
        MkLabel({Size=UDim2.new(0,28,0,26),Position=UDim2.new(0,8,0,5),BackgroundTransparency=1,Text=s.i,TextSize=16,ZIndex=17},Card)
        MkLabel({Size=UDim2.new(1,-12,0,16),Position=UDim2.new(0,6,0,30),BackgroundTransparency=1,
            Text=s.v,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=s.c,ZIndex=17},Card)
        MkLabel({Size=UDim2.new(1,-12,0,12),Position=UDim2.new(0,6,0,47),BackgroundTransparency=1,
            Text=s.l,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,ZIndex=17},Card)
    end

    -- Agentes section
    SectionLabel(Li,"AGENTES ACTIVOS")
    local ALi=InnerList(Li)
    for _,ag in ipairs({
        {i="⬡",n="Orquestador",m="llama-3.3-70b",d="Dirige el flujo multi-agente"},
        {i="🎮",n="Game Analyst",m="nemotron-120b",d="Análisis del juego actual"},
        {i="💻",n="Code Expert",m="qwen3-coder",d="Scripts y código Lua"},
        {i="⚔",n="Strategy Agent",m="deepseek-v4",d="Estrategias y builds"},
        {i="🎨",n="Creative Agent",m="gemma-4-31b",d="Ideas y personalización"},
    }) do
        local AC=MkFrame({Size=UDim2.new(1,0,0,mob and 50 or 56),BackgroundColor3=C.BG3,ZIndex=16},ALi)
        Corner(10,AC); Stroke(1,C.BR0,AC)
        local IB=MkFrame({Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,10,0.5,-16),BackgroundColor3=C.P3,ZIndex=17},AC); Corner(8,IB)
        MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=ag.i,TextSize=16,ZIndex=18},IB)
        MkLabel({Size=UDim2.new(1,-160,0,18),Position=UDim2.new(0,50,0,8),BackgroundTransparency=1,
            Text=ag.n,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},AC)
        MkLabel({Size=UDim2.new(1,-160,0,13),Position=UDim2.new(0,50,0,26),BackgroundTransparency=1,
            Text=ag.d,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},AC)
        local MB=MkLabel({Size=UDim2.new(0,mob and 94 or 100,0,18),Position=UDim2.new(1,-(mob and 106 or 112),0.5,-9),
            BackgroundColor3=Color3.fromRGB(0,30,14),Text="● "..ag.m,
            Font=Enum.Font.Gotham,TextSize=8,TextColor3=C.TG,ZIndex=17},AC); Corner(9,MB)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: SCRIPT HUB
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_SCRIPT_HUB"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("SCRIPT_HUB")
    ContentHeader(Li,"SCRIPT HUB  ⚡","Scripts verificados · "..GNAME)

    -- Search bar
    local SearchF=MkFrame({Size=UDim2.new(1,-28,0,38),BackgroundColor3=C.BG3,ZIndex=15},Li)
    Corner(10,SearchF); Stroke(1,C.BR0,SearchF); Pad(0,14,0,14,SearchF)
    MkLabel({Size=UDim2.new(0,18,1,0),BackgroundTransparency=1,Text="🔍",TextSize=14,ZIndex=16},SearchF)
    local SBox=MkBox({Size=UDim2.new(1,-24,1,0),Position=UDim2.new(0,22,0,0),BackgroundTransparency=1,
        Text="",PlaceholderText="Buscar scripts...",Font=Enum.Font.Gotham,TextSize=12,
        TextColor3=C.TW,PlaceholderColor3=C.TM,ZIndex=16},SearchF)

    -- Categories
    local CatF=MkFrame({Size=UDim2.new(1,-28,0,30),BackgroundTransparency=1,ZIndex=15},Li)
    ListL({FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)},CatF)
    Pad(0,14,0,14,CatF)
    for _,cat in ipairs({"TODOS","NO KEY","VERIFICADOS","KEY REQ."}) do
        local CB=MkBtn({Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=cat=="TODOS" and C.P3 or C.BG3,
            Text=cat,Font=Enum.Font.GothamBold,TextSize=9,
            TextColor3=cat=="TODOS" and C.TW or C.TS,ZIndex=16},CatF)
        Corner(8,CB); Pad(0,10,0,10,CB)
        if cat~="TODOS" then Stroke(1,C.BR0,CB) end
    end

    -- Scripts
    SectionLabel(Li,"SCRIPTS DISPONIBLES")
    local SLi=InnerList(Li)

    local scripts={
        {t="Auto Farm v5.2",a="LXNDXN",v=true,nokey=true,sc="print('AutoFarm ON')"},
        {t="ESP Pro · All Players",a="QuantumDev",v=true,nokey=true,sc="print('ESP ON')"},
        {t="Infinite Jump",a="DeltaFarm",v=false,nokey=true,sc="print('InfJump ON')"},
        {t="Speed Hack x10",a="LXNDXN",v=true,nokey=false,sc="print('Speed ON')"},
        {t="God Mode Bypass",a="NullSec",v=false,nokey=true,sc="print('GodMode ON')"},
        {t="Auto Collect Items",a="QuantumDev",v=true,nokey=true,sc="print('AutoCollect ON')"},
        {t="Teleport Any Player",a="LXNDXN",v=true,nokey=false,sc="print('Teleport ON')"},
        {t="Aimbot Pro",a="DeltaFarm",v=false,nokey=true,sc="print('Aimbot ON')"},
    }

    for _,s in ipairs(scripts) do
        local Card=MkFrame({Size=UDim2.new(1,0,0,mob and 70 or 78),BackgroundColor3=C.BG3,ZIndex=16},SLi)
        Corner(10,Card); Stroke(1,C.BR0,Card)

        local IcF=MkFrame({Size=UDim2.new(0,mob and 42 or 48,0,mob and 42 or 48),
            Position=UDim2.new(0,10,0.5,mob and -21 or -24),BackgroundColor3=C.P3,ZIndex=17},Card); Corner(10,IcF)
        MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="⚡",TextSize=20,ZIndex=18},IcF)

        local lx=mob and 62 or 68
        MkLabel({Size=UDim2.new(1,-(lx+170),0,18),Position=UDim2.new(0,lx,0,mob and 10 or 12),
            BackgroundTransparency=1,Text=s.t,Font=Enum.Font.GothamBold,TextSize=mob and 11 or 12,
            TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Card)
        MkLabel({Size=UDim2.new(1,-(lx+170),0,13),Position=UDim2.new(0,lx,0,mob and 28 or 32),
            BackgroundTransparency=1,Text="by "..s.a,Font=Enum.Font.Gotham,TextSize=9,
            TextColor3=C.TS,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Card)

        local tags=MkFrame({Size=UDim2.new(1,-(lx+170),0,16),Position=UDim2.new(0,lx,0,mob and 46 or 52),
            BackgroundTransparency=1,ZIndex=17},Card)
        ListL({FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4)},tags)
        if s.v then
            local VB=MkLabel({Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
                BackgroundColor3=Color3.fromRGB(0,35,16),Text="✓ Verificado",
                Font=Enum.Font.Gotham,TextSize=8,TextColor3=C.TG,ZIndex=18},tags)
            Corner(5,VB); Pad(0,5,0,5,VB)
        end
        if s.nokey then
            local NK=MkLabel({Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
                BackgroundColor3=Color3.fromRGB(0,24,40),Text="NO KEY",
                Font=Enum.Font.Gotham,TextSize=8,TextColor3=C.A1,ZIndex=18},tags)
            Corner(5,NK); Pad(0,5,0,5,NK)
        end

        -- Buttons
        local ExB=MkBtn({Size=UDim2.new(0,mob and 68 or 76,0,mob and 26 or 28),
            Position=UDim2.new(1,-(mob and 158 or 174),0.5,mob and -13 or -14),
            BackgroundColor3=C.P1,Text="▶ EJECUTAR",Font=Enum.Font.GothamBold,
            TextSize=9,TextColor3=Color3.new(1,1,1),ZIndex=17},Card); Corner(7,ExB)
        Hover(ExB,C.P1,C.P2)
        ExB.MouseButton1Click:Connect(function()
            pcall(function() loadstring(s.sc)() end)
            PushNotif("Script",s.t.." ejecutado","SUCCESS",3)
        end)

        local SvB=MkBtn({Size=UDim2.new(0,mob and 58 or 64,0,mob and 26 or 28),
            Position=UDim2.new(1,-(mob and 82 or 90),0.5,mob and -13 or -14),
            BackgroundColor3=C.BG4,Text="💾 GUARDAR",Font=Enum.Font.Gotham,
            TextSize=9,TextColor3=C.TS,ZIndex=17},Card); Corner(7,SvB); Stroke(1,C.BR0,SvB)
        SvB.MouseButton1Click:Connect(function()
            PushNotif("Guardado",s.t.." guardado","INFO",2)
        end)

        local IB2=MkBtn({Size=UDim2.new(0,mob and 14 or 16,0,mob and 26 or 28),
            Position=UDim2.new(1,-18,0.5,mob and -13 or -14),
            BackgroundColor3=C.BG4,Text="⋮",Font=Enum.Font.GothamBold,
            TextSize=14,TextColor3=C.TS,ZIndex=17},Card); Corner(5,IB2)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: TOOLBOX
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_TOOLBOX"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("TOOLBOX")
    ContentHeader(Li,"TOOLBOX  🛠","Herramientas del executor · "..GNAME)

    -- CHARACTER section
    SectionLabel(Li,"CHARACTER")
    local CLi=InnerList(Li)

    MkSlider(CLi,"WalkSpeed",0,300,16,"",nil,function(v) MovMod.Speed(v) end)
    MkSlider(CLi,"JumpPower",0,200,50,"",nil,function(v) MovMod.Jump(v) end)

    local flyState=false
    local _,getFly=MkToggle(CLi,"Fly","No-Clip activado","Volar libremente · WASD+Q/E",function(s)
        flyState=s
        if s then FlyMod.On() else FlyMod.Off() end
    end)
    MkToggle(CLi,"No-Clip",false,"Atravesar paredes",function(s)
        if s then NoClipMod.On() else NoClipMod.Off() end
    end)

    -- WORLD section
    SectionLabel(Li,"WORLD")
    local WLi=InnerList(Li)
    MkToggle(WLi,"Day/Night Cycle",false,"Alterna día y noche",function(s)
        pcall(function() game:GetService("Lighting").ClockTime=s and 14 or 0 end)
    end)
    MkToggle(WLi,"Remove Textures",false,"Elimina texturas para más FPS",function(s)
        pcall(function()
            for _,v in pairs(workspace:GetDescendants()) do
                if v:IsA("SpecialMesh") then v.TextureId=s and "" or v.TextureId end
            end
        end)
    end)
    MkToggle(WLi,"Environmental Immunity",false,"Inmune al entorno",nil)

    -- VISUALS section
    SectionLabel(Li,"VISUALS")
    local VLi=InnerList(Li)
    MkToggle(VLi,"Player ESP",false,"Ver jugadores a través de paredes",function(s)
        if s then ESPMod.On() else ESPMod.Off() end
    end)
    MkToggle(VLi,"God Mode",false,"Salud siempre al máximo",function(s)
        if s then GodMod.On() else GodMod.Off() end
    end)
    MkToggle(VLi,"Skybox",true,"Cielo personalizado",nil)
    MkToggle(VLi,"Item ESP",false,"Ver items en el mapa",nil)
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: SYSTEM SETTINGS
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_SYSTEM_SETTINGS"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("SYSTEM_SETTINGS")
    ContentHeader(Li,"SYSTEM SETTINGS  ⚙","Configuración del sistema")

    -- API Key card
    SectionLabel(Li,"GENERAL")
    local GLi=InnerList(Li)

    local KC=MkFrame({Size=UDim2.new(1,0,0,64),BackgroundColor3=C.BG3,ZIndex=16},GLi)
    Corner(10,KC); Stroke(1,C.BR0,KC)
    MkLabel({Size=UDim2.new(1,-120,0,18),Position=UDim2.new(0,14,0,10),BackgroundTransparency=1,
        Text="OpenRouter API Key",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},KC)
    local km=ENV.QOS_APIKey and ("sk-or-v1-..."..ENV.QOS_APIKey:sub(-6)) or "No configurada"
    MkLabel({Size=UDim2.new(1,-120,0,14),Position=UDim2.new(0,14,0,30),BackgroundTransparency=1,
        Text=km,Font=Enum.Font.Code,TextSize=9,TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},KC)
    local KS=MkLabel({Size=UDim2.new(0,76,0,18),Position=UDim2.new(1,-88,0.5,-9),
        BackgroundColor3=Color3.fromRGB(0,36,16),Text="● Conectada",
        Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TG,ZIndex=17},KC); Corner(9,KS)

    -- Language dropdown (visual only)
    local LangF=MkFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG3,ZIndex=16},GLi)
    Corner(10,LangF); Stroke(1,C.BR0,LangF)
    MkLabel({Size=UDim2.new(1,-130,0,18),Position=UDim2.new(0,14,0,15),BackgroundTransparency=1,
        Text="Language",Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},LangF)
    local LangVal=MkBtn({Size=UDim2.new(0,100,0,28),Position=UDim2.new(1,-112,0.5,-14),
        BackgroundColor3=C.BG4,Text="Español  ⌄",Font=Enum.Font.Gotham,TextSize=10,
        TextColor3=C.TW,ZIndex=17},LangF); Corner(8,LangVal); Stroke(1,C.BR1,LangVal)

    -- Theme
    local ThemeF=MkFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG3,ZIndex=16},GLi)
    Corner(10,ThemeF); Stroke(1,C.BR0,ThemeF)
    MkLabel({Size=UDim2.new(1,-130,0,18),Position=UDim2.new(0,14,0,15),BackgroundTransparency=1,
        Text="Theme",Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},ThemeF)
    local ThemeVal=MkBtn({Size=UDim2.new(0,80,0,28),Position=UDim2.new(1,-92,0.5,-14),
        BackgroundColor3=C.BG4,Text="Dark  ⌄",Font=Enum.Font.Gotham,TextSize=10,
        TextColor3=C.TW,ZIndex=17},ThemeF); Corner(8,ThemeVal); Stroke(1,C.BR1,ThemeVal)

    -- Performance section
    SectionLabel(Li,"PERFORMANCE")
    local PLi=InnerList(Li)

    local cpuBar=MkFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG3,ZIndex=16},PLi); Corner(10,cpuBar); Stroke(1,C.BR0,cpuBar)
    MkLabel({Size=UDim2.new(1,-80,0,16),Position=UDim2.new(0,14,0,8),BackgroundTransparency=1,Text="CPU Usage",Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},cpuBar)
    local cpuPBG=MkFrame({Size=UDim2.new(1,-28,0,5),Position=UDim2.new(0,14,0,32),BackgroundColor3=C.BG4,ZIndex=17},cpuBar); Corner(3,cpuPBG)
    local cpuPF=MkFrame({Size=UDim2.new(0.3,0,1,0),BackgroundColor3=C.TG,ZIndex=18},cpuPBG); Corner(3,cpuPF); Grad(C.TG,C.A1,0,cpuPF)
    MkLabel({Size=UDim2.new(0,48,0,16),Position=UDim2.new(1,-60,0,8),BackgroundTransparency=1,Text="30%",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TG,ZIndex=17},cpuBar)

    local ramBar=MkFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG3,ZIndex=16},PLi); Corner(10,ramBar); Stroke(1,C.BR0,ramBar)
    MkLabel({Size=UDim2.new(1,-80,0,16),Position=UDim2.new(0,14,0,8),BackgroundTransparency=1,Text="RAM Usage",Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},ramBar)
    local ramPBG=MkFrame({Size=UDim2.new(1,-28,0,5),Position=UDim2.new(0,14,0,32),BackgroundColor3=C.BG4,ZIndex=17},ramBar); Corner(3,ramPBG)
    local ramPF=MkFrame({Size=UDim2.new(0.45,0,1,0),BackgroundColor3=C.TY,ZIndex=18},ramPBG); Corner(3,ramPF); Grad(C.TY,C.A1,0,ramPF)
    MkLabel({Size=UDim2.new(0,48,0,16),Position=UDim2.new(1,-60,0,8),BackgroundTransparency=1,Text="45%",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TY,ZIndex=17},ramBar)

    MkSlider(PLi,"FPS Limit",30,240,120," FPS","Límite de fotogramas",nil)

    -- Security section
    SectionLabel(Li,"SECURITY")
    local SELi=InnerList(Li)
    ActionBtn(SELi,"Key Management","🔑",C.P2,function()
        PushNotif("Key Management","Gestión de keys próximamente","INFO",3)
    end)
    MkToggle(SELi,"Anti-Detección",true,"Protección contra detección",nil)
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: QUANTUM ORACLE (Chat AI)
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_QUANTUM_ORACLE"]=function()
    local mob=IsMobile()
    local Tab=MkFrame({Name="T_ORACLE",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab
    local HH=mob and 52 or 60
    ContentHeader(Tab,"QUANTUM ORACLE  🔮","Multi-Agent AI · "..GNAME)

    -- AI info bar
    local InfoBar=MkFrame({Size=UDim2.new(1,-24,0,mob and 56 or 64),Position=UDim2.new(0,12,0,HH+6),
        BackgroundColor3=C.BG3,ZIndex=16},Tab); Corner(10,InfoBar); Stroke(1,C.BR1,InfoBar)

    local OrbF=MkFrame({Size=UDim2.new(0,mob and 38 or 44,0,mob and 38 or 44),
        Position=UDim2.new(0,10,0.5,mob and -19 or -22),BackgroundColor3=C.P3,ZIndex=17},InfoBar); Corner(mob and 19 or 22,OrbF)
    MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="🔮",TextSize=mob and 18 or 22,ZIndex=18},OrbF)
    task.spawn(function() while OrbF and OrbF.Parent do Tw(OrbF,TI.SINE,{BackgroundColor3=C.P1}); task.wait(1.2); Tw(OrbF,TI.SINE,{BackgroundColor3=C.P3}); task.wait(1.2) end end)

    local ox=(mob and 38 or 44)+18
    MkLabel({Size=UDim2.new(1,-ox-12,0,18),Position=UDim2.new(0,ox,0,mob and 10 or 12),BackgroundTransparency=1,
        Text="QUANTUM ORACLE · Multi-Agent AI",Font=Enum.Font.GothamBold,TextSize=mob and 11 or 13,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},InfoBar)
    local AgBadge=MkLabel({Size=UDim2.new(1,-ox-12,0,14),Position=UDim2.new(0,ox,0,mob and 30 or 34),BackgroundTransparency=1,
        Text="Orch: llama-3.3-70b · 5 Agentes listos",Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},InfoBar)

    -- Suggestions
    local SugY=HH+(mob and 68 or 78)
    local SugF=MkFrame({Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,SugY),BackgroundTransparency=1,ZIndex=16},Tab)
    ListL({FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)},SugF)

    -- Chat scroll
    local chatY=SugY+32
    local inputH=mob and 48 or 52
    local ChatSc=MkScroll({
        Size=UDim2.new(1,-24,1,-(chatY+inputH+12)),
        Position=UDim2.new(0,12,0,chatY),
        BackgroundColor3=Color3.fromRGB(4,4,10),ScrollBarThickness=3,ScrollBarImageColor3=C.BR1,ZIndex=15,
    },Tab); Corner(10,ChatSc); Stroke(1,C.BR0,ChatSc)

    local ChatLi=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=15},ChatSc)
    ListL({Padding=UDim.new(0,8)},ChatLi); Pad(8,8,8,8,ChatLi)

    local function AddMsg(txt,isUser,meta)
        local bub=MkFrame({
            Size=UDim2.new(0.88,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            Position=isUser and UDim2.new(0.12,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3=isUser and C.P3 or C.BG3,
            BackgroundTransparency=isUser and 0.05 or 0.1,ZIndex=16,
        },ChatLi); Corner(12,bub); Pad(9,12,9,12,bub)
        if not isUser and meta then
            MkLabel({Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,
                Text=meta.icon.." "..meta.name,Font=Enum.Font.GothamBold,
                TextSize=9,TextColor3=meta.color,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},bub)
        end
        local yy=(not isUser and meta) and 17 or 0
        MkLabel({Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,yy),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,Text=txt,Font=Enum.Font.Gotham,TextSize=mob and 11 or 12,TextColor3=C.TW,
            TextWrapped=true,TextXAlignment=isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,ZIndex=17},bub)
        task.wait(0.04)
        ChatSc.CanvasSize=UDim2.new(0,0,0,ChatLi.AbsoluteContentSize.Y+16)
        ChatSc.CanvasPosition=Vector2.new(0,ChatLi.AbsoluteContentSize.Y)
    end

    local ThinkB=nil
    local function ShowThink(txt)
        if ThinkB then pcall(function() ThinkB:Destroy() end) end
        ThinkB=MkFrame({Size=UDim2.new(0.44,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=C.BG3,BackgroundTransparency=0.25,ZIndex=16},ChatLi)
        Corner(10,ThinkB); Pad(6,10,6,10,ThinkB)
        MkLabel({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,
            Text="◌ "..txt,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TM,TextWrapped=true,ZIndex=17},ThinkB)
        task.wait(0.04)
        ChatSc.CanvasSize=UDim2.new(0,0,0,ChatLi.AbsoluteContentSize.Y+16)
        ChatSc.CanvasPosition=Vector2.new(0,ChatLi.AbsoluteContentSize.Y)
    end
    local function HideThink() if ThinkB then pcall(function() ThinkB:Destroy() end); ThinkB=nil end end

    AddMsg("🔮 Hola, "..DNAME.."!\n\nSoy el Quantum Oracle con Multi-Agent AI.\nJuego detectado: '"..GNAME.."'\n\nEl Orquestador dirigirá tu consulta al agente ideal:\n🎮 Game · 💻 Code · ⚔ Strategy · 🎨 Creative · ⚡ Fast\n\n¿En qué puedo ayudarte?",false,{icon="🔮",name="Quantum Oracle",color=C.P2})

    -- Suggestions
    local suggs={"¿Mejores scripts?","Fix error Lua","¿Cómo farmear?","Estrategia rápida","Script auto-farm"}
    for _,sg in ipairs(suggs) do
        local SB=MkBtn({Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.BG3,Text=sg,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.A1,ZIndex=17},SugF)
        Corner(8,SB); Pad(0,8,0,8,SB); Stroke(1,C.BR1,SB)
        SB.MouseEnter:Connect(function() Tw(SB,TI.FAST,{BackgroundColor3=C.BG4}) end)
        SB.MouseLeave:Connect(function() Tw(SB,TI.FAST,{BackgroundColor3=C.BG3}) end)
        SB.MouseButton1Click:Connect(function() end) -- set to input below after creation
    end

    -- Input
    local InputF=MkFrame({
        Size=UDim2.new(1,-24,0,inputH),Position=UDim2.new(0,12,1,-(inputH+8)),
        BackgroundColor3=C.BG3,ZIndex=16,
    },Tab); Corner(12,InputF); Stroke(1,C.BR0,InputF)

    local CI=MkBox({
        Size=UDim2.new(1,-54,1,-2),Position=UDim2.new(0,12,0,1),
        BackgroundTransparency=1,Text="",PlaceholderText="Pregunta al Oracle...",
        Font=Enum.Font.Gotham,TextSize=mob and 11 or 12,TextColor3=C.TW,
        PlaceholderColor3=C.TM,ClearTextOnFocus=false,ZIndex=17,
    },InputF)

    local SndBtn=MkBtn({
        Size=UDim2.new(0,38,0,34),Position=UDim2.new(1,-44,0.5,-17),
        BackgroundColor3=C.P1,Text="▶",Font=Enum.Font.GothamBold,
        TextSize=13,TextColor3=Color3.new(1,1,1),ZIndex=17,
    },InputF); Corner(9,SndBtn); Hover(SndBtn,C.P1,C.P2)

    -- Wire sugg buttons
    for _,b in pairs(SugF:GetChildren()) do
        if b:IsA("TextButton") then
            b.MouseButton1Click:Connect(function() CI.Text=b.Text end)
        end
    end

    local waiting=false
    local function DoSend()
        if waiting then return end
        local msg=CI.Text:match("^%s*(.-)%s*$")
        if msg=="" then return end
        CI.Text=""; waiting=true; SndBtn.Text="◌"
        AddMsg(msg,true)
        OracleQuery(msg,
            function(t) ShowThink(t); AgBadge.Text="⬡ "..t end,
            function(k,m) ShowThink(m.icon.." "..m.name.." respondiendo..."); AgBadge.Text=m.icon.." Activo: "..m.name end,
            function(r,m) HideThink(); AddMsg(r,false,m); waiting=false; SndBtn.Text="▶"; AgBadge.Text="Orch: llama-3.3-70b · 5 Agentes listos" end,
            function(e) HideThink(); AddMsg("❌ Error: "..tostring(e).."\nVerifica tu API Key en Settings.",false,{icon="❌",name="Sistema",color=C.TR}); waiting=false; SndBtn.Text="▶" end
        )
    end
    SndBtn.MouseButton1Click:Connect(DoSend)
    CI.FocusLost:Connect(function(e) if e then DoSend() end end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: GAME BOOSTER
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_GAME_BOOSTER"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("GAME_BOOSTER")
    ContentHeader(Li,"GAME BOOSTER  🚀","Optimización FPS · "..GNAME)

    -- Boost card
    local BC=MkFrame({Size=UDim2.new(1,-28,0,mob and 88 or 100),BackgroundColor3=C.BG3,ZIndex=16},Li)
    MkFrame({Size=UDim2.new(1,-28,0,mob and 88 or 100),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1},Li)
    -- fix: add to inner list
    local BCWrap=InnerList(Li)

    local BC2=MkFrame({Size=UDim2.new(1,0,0,mob and 90 or 102),BackgroundColor3=C.BG3,ZIndex=16},BCWrap)
    Corner(12,BC2); Stroke(2,C.P1,BC2); Grad(Color3.fromRGB(14,6,36),Color3.fromRGB(40,0,80),135,BC2)
    MkLabel({Size=UDim2.new(1,-120,0,22),Position=UDim2.new(0,14,0,14),BackgroundTransparency=1,
        Text="🚀 QUANTUM BOOST MODE",Font=Enum.Font.GothamBold,TextSize=mob and 13 or 15,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},BC2)
    MkLabel({Size=UDim2.new(1,-120,0,30),Position=UDim2.new(0,14,0,38),BackgroundTransparency=1,
        Text="Elimina partículas, texturas y reduce\nrender para máximo FPS.",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},BC2)
    local BB=MkBtn({Size=UDim2.new(0,80,0,34),Position=UDim2.new(1,-92,0.5,-17),
        BackgroundColor3=C.TON,Text="ACTIVAR",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.new(1,1,1),ZIndex=17},BC2)
    Corner(9,BB)
    local boosted=false
    BB.MouseButton1Click:Connect(function()
        boosted=not boosted; BB.Text=boosted and "ACTIVO ✓" or "ACTIVAR"
        Tw(BB,TI.FAST,{BackgroundColor3=boosted and C.P1 or C.TON})
        if boosted then
            pcall(function()
                for _,v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled=false end
                    if v:IsA("SpecialMesh") then v.TextureId="" end
                end
            end)
            PushNotif("Boost","Modo Quantum Boost activado","SUCCESS",3)
        end
    end)

    SectionLabel(Li,"OPCIONES")
    local OLi=InnerList(Li)
    MkToggle(OLi,"Desactivar Partículas",false,"Elimina ParticleEmitters",function(s)
        for _,v in pairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") then v.Enabled=not s end end
    end)
    MkToggle(OLi,"Desactivar Sombras",false,"Mejora rendimiento",function(s)
        pcall(function() game:GetService("Lighting").GlobalShadows=not s end)
    end)
    MkToggle(OLi,"Anti-Lag Mode",false,"Reduce latencia",nil)
    MkSlider(OLi,"Simulation Throttle",1,100,100,"%","Calidad de simulación",nil)
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: FILE MANAGER
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_FILE_MANAGER"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("FILE_MANAGER")
    ContentHeader(Li,"FILE MANAGER  📁","Gestor de scripts · Delta Executor")

    local SBar=MkFrame({Size=UDim2.new(1,-28,0,38),BackgroundColor3=C.BG3,ZIndex=15},Li)
    Corner(10,SBar); Stroke(1,C.BR0,SBar); Pad(0,14,0,14,SBar)
    MkBox({Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text="",PlaceholderText="Buscar scripts...",
        Font=Enum.Font.Gotham,TextSize=12,TextColor3=C.TW,PlaceholderColor3=C.TM,ZIndex=16},SBar)
    local SaveBtn=MkBtn({Size=UDim2.new(0,50,0,28),Position=UDim2.new(1,-58,0.5,-14),
        BackgroundColor3=C.P1,Text="Save",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TW,ZIndex=16},SBar)
    Corner(8,SaveBtn)

    local folders={
        {n="LOCAL SCRIPTS",i="📁",count=4},
        {n="CLOUD SCRIPTS",i="☁",count=12},
        {n="TEMPLATES",i="📋",count=6},
    }
    for _,f in ipairs(folders) do
        local FLi=InnerList(Li)
        local FRow=MkFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG3,ZIndex=16},FLi)
        Corner(10,FRow); Stroke(1,C.BR0,FRow)
        MkLabel({Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,12,0.5,-12),BackgroundTransparency=1,Text=f.i,TextSize=18,ZIndex=17},FRow)
        MkLabel({Size=UDim2.new(1,-120,0,18),Position=UDim2.new(0,44,0,15),BackgroundTransparency=1,
            Text=f.n,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},FRow)
        MkLabel({Size=UDim2.new(0,30,0,18),Position=UDim2.new(1,-70,0,15),BackgroundTransparency=1,
            Text=tostring(f.count),Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.TS,ZIndex=17},FRow)
        local ChevBtn=MkBtn({Size=UDim2.new(0,32,0,32),Position=UDim2.new(1,-38,0.5,-16),
            BackgroundColor3=C.BG4,Text="›",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=C.TS,ZIndex=17},FRow)
        Corner(8,ChevBtn)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: PROCESSES
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_PROCESSES"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("PROCESSES")
    ContentHeader(Li,"PROCESSES & LOGS  📊","Monitor en tiempo real")

    SectionLabel(Li,"SCRIPTS ACTIVOS")
    local SLi=InnerList(Li)
    for _,p in ipairs({
        {n="Auto Farm v5.2",  v="by LXNDXN",     res="1 GB",  pct=0.15,c=C.TG},
        {n="Anime Defenders Hub",v="by QuantumDev",res="70 MB",pct=0.03,c=C.A1},
    }) do
        local PRow=MkFrame({Size=UDim2.new(1,0,0,60),BackgroundColor3=C.BG3,ZIndex=16},SLi)
        Corner(10,PRow); Stroke(1,C.BR0,PRow)
        local IcF2=MkFrame({Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,10,0.5,-18),BackgroundColor3=C.P3,ZIndex=17},PRow); Corner(8,IcF2)
        MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="⚡",TextSize=16,ZIndex=18},IcF2)
        MkLabel({Size=UDim2.new(1,-210,0,17),Position=UDim2.new(0,54,0,10),BackgroundTransparency=1,
            Text=p.n,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},PRow)
        MkLabel({Size=UDim2.new(1,-210,0,13),Position=UDim2.new(0,54,0,28),BackgroundTransparency=1,
            Text=p.v,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TS,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},PRow)
        MkLabel({Size=UDim2.new(0,60,0,17),Position=UDim2.new(1,-188,0,10),BackgroundTransparency=1,
            Text=p.res,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.TS,ZIndex=17},PRow)
        local PctBG=MkFrame({Size=UDim2.new(0,80,0,5),Position=UDim2.new(1,-188,0,34),BackgroundColor3=C.BG4,ZIndex=17},PRow); Corner(3,PctBG)
        local PctF=MkFrame({Size=UDim2.new(p.pct,0,1,0),BackgroundColor3=p.c,ZIndex=18},PctBG); Corner(3,PctF)
        MkLabel({Size=UDim2.new(0,40,0,17),Position=UDim2.new(1,-100,0,10),BackgroundTransparency=1,
            Text=math.floor(p.pct*100).."%",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=p.c,ZIndex=17},PRow)
    end

    SectionLabel(Li,"EXECUTION LOG")
    local LLi=InnerList(Li)
    local LogF=MkFrame({Size=UDim2.new(1,0,0,160),BackgroundColor3=Color3.fromRGB(4,4,10),ZIndex=16},LLi)
    Corner(10,LogF); Stroke(1,C.BR0,LogF); Pad(10,12,10,12,LogF)
    local LogSc=MkScroll({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=2,ZIndex=17},LogF)
    local LogLi=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=17},LogSc)
    ListL({Padding=UDim.new(0,2)},LogLi)
    local logs={
        "Execution log: Server/MainupoinShiipt",
        "Execution log: Server/iroeonrreecdoots",
        "Execution log: Server/itoiongmememoi/teoterernod)",
        "Execution log: Server/teasrttovs.otocesseat)",
        "Execution log: Server/ova/bscooroctosls",
        "Execution log: Server/Szecutiovsabegbite",
        "Execution log: Execution scripta: does",
    }
    for _,log in ipairs(logs) do
        MkLabel({Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Text=log,
            Font=Enum.Font.Code,TextSize=9,TextColor3=C.TM,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=18},LogLi)
    end
    local LLLL=LogLi:FindFirstChildWhichIsA("UIListLayout")
    if LLLL then LLLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        LogSc.CanvasSize=UDim2.new(0,0,0,LLLL.AbsoluteContentSize.Y)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: MEDIA CENTER
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_MEDIA_CENTER"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("MEDIA_CENTER")
    ContentHeader(Li,"MEDIA CENTER  🎵","Reproductor multimedia")

    local PLi=InnerList(Li)

    -- Now playing card
    local NPC=MkFrame({Size=UDim2.new(1,0,0,mob and 90 or 104),BackgroundColor3=C.BG3,ZIndex=16},PLi)
    Corner(12,NPC); Stroke(1,C.BR0,NPC)
    -- Album art
    local Art=MkFrame({Size=UDim2.new(0,mob and 64 or 72,0,mob and 64 or 72),
        Position=UDim2.new(0,14,0.5,mob and -32 or -36),BackgroundColor3=C.P3,ZIndex=17},NPC)
    Corner(8,Art); Grad(C.P3,Color3.fromRGB(0,40,80),135,Art)
    MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="🎵",TextSize=24,ZIndex=18},Art)
    -- Track info
    local tx=mob and 88 or 100
    MkLabel({Size=UDim2.new(1,-tx-60,0,18),Position=UDim2.new(0,tx,0,mob and 14 or 18),BackgroundTransparency=1,
        Text="Now Playing:",Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},NPC)
    MkLabel({Size=UDim2.new(1,-tx-60,0,20),Position=UDim2.new(0,tx,0,mob and 28 or 34),BackgroundTransparency=1,
        Text="Neo-Cyber Funk",Font=Enum.Font.GothamBold,TextSize=mob and 13 or 15,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},NPC)
    -- Progress bar
    local PBar=MkFrame({Size=UDim2.new(1,-tx-14,0,4),Position=UDim2.new(0,tx,0,mob and 52 or 60),BackgroundColor3=C.BG4,ZIndex=17},NPC)
    Corner(2,PBar)
    local PFill=MkFrame({Size=UDim2.new(0.42,0,1,0),BackgroundColor3=C.P1,ZIndex=18},PBar); Corner(2,PFill); Grad(C.P1,C.A1,0,PFill)
    -- Controls
    local CtrlF=MkFrame({Size=UDim2.new(1,-tx-14,0,26),Position=UDim2.new(0,tx,0,mob and 60 or 70),BackgroundTransparency=1,ZIndex=17},NPC)
    ListL({FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,8)},CtrlF)
    for _,ctrl in ipairs({"⏮","▶","⏭","🔀"}) do
        local isPlay=(ctrl=="▶")
        local CB2=MkBtn({
            Size=UDim2.new(0,isPlay and 32 or 24,0,isPlay and 32 or 24),
            BackgroundColor3=isPlay and C.P1 or C.BG4,
            Text=ctrl,Font=Enum.Font.GothamBold,TextSize=isPlay and 14 or 12,
            TextColor3=C.TW,ZIndex=18,
        },CtrlF); Corner(isPlay and 16 or 8,CB2)
    end

    -- Playlist
    SectionLabel(Li,"PLAYLIST")
    local QLi=InnerList(Li)
    for _,track in ipairs({
        {n="Neo-Cyber Funk",d="3:42",active=true},
        {n="Neon Dreams",d="4:15",active=false},
        {n="Delta Pulse",d="2:58",active=false},
        {n="Quantum Beat",d="5:01",active=false},
    }) do
        local TR=MkFrame({Size=UDim2.new(1,0,0,46),BackgroundColor3=track.active and C.P3 or C.BG3,ZIndex=16},QLi)
        Corner(8,TR); if track.active then Stroke(1,C.P1,TR) else Stroke(1,C.BR0,TR) end
        MkLabel({Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,10,0.5,-11),BackgroundTransparency=1,
            Text=track.active and "▶" or "♪",TextSize=14,TextColor3=track.active and C.P2 or C.TM,ZIndex=17},TR)
        MkLabel({Size=UDim2.new(1,-80,0,18),Position=UDim2.new(0,38,0,14),BackgroundTransparency=1,
            Text=track.n,Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=track.active and C.TW or C.TS,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},TR)
        MkLabel({Size=UDim2.new(0,40,0,18),Position=UDim2.new(1,-50,0,14),BackgroundTransparency=1,
            Text=track.d,Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TM,ZIndex=17},TR)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: COMMUNITY
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_COMMUNITY"]=function()
    local Tab,Sc,Li=ScrollTab("COMMUNITY")
    ContentHeader(Li,"COMMUNITY  👥","Discord · Foro · Top Contributors")

    local CLi=InnerList(Li)
    ActionBtn(CLi,"Discord Server","💬",Color3.fromRGB(88,101,242),function()
        pcall(function() setclipboard("https://discord.gg/lxndxn") end)
        PushNotif("Discord","Link copiado al portapapeles","SUCCESS",3)
    end)
    ActionBtn(CLi,"Foro de Scripts","📝",C.A1,function()
        PushNotif("Foro","Próximamente disponible","INFO",3)
    end)
    ActionBtn(CLi,"Top Contributors","🏆",C.TY,nil)

    SectionLabel(Li,"TOP CONTRIBUTORS")
    local TLi=InnerList(Li)
    for i,u in ipairs({"LXNDXN","QuantumDev","DeltaFarm","NullSec","ProScripter"}) do
        local URow=MkFrame({Size=UDim2.new(1,0,0,48),BackgroundColor3=C.BG3,ZIndex=16},TLi)
        Corner(8,URow); Stroke(1,C.BR0,URow)
        local rank=tostring(i)
        local rc=i==1 and C.TY or i==2 and C.TS or i==3 and Color3.fromRGB(180,100,50) or C.TM
        MkLabel({Size=UDim2.new(0,24,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,
            Text=rank,Font=Enum.Font.GothamBold,TextSize=13,TextColor3=rc,ZIndex=17},URow)
        MkLabel({Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,36,0.5,-16),BackgroundColor3=C.P3,ZIndex=17},URow)
        MkLabel({Size=UDim2.new(1,-160,0,18),Position=UDim2.new(0,76,0,15),BackgroundTransparency=1,
            Text=u,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TW,
            TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},URow)
        MkLabel({Size=UDim2.new(0,80,0,18),Position=UDim2.new(1,-90,0,15),BackgroundTransparency=1,
            Text=tostring(math.random(50,500)).." scripts",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,ZIndex=17},URow)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: CUSTOMIZER
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_CUSTOMIZER"]=function()
    local Tab,Sc,Li=ScrollTab("CUSTOMIZER")
    ContentHeader(Li,"CUSTOMIZER  🎨","Personaliza el Quantum OS")

    SectionLabel(Li,"UI CUSTOMIZATION")
    local ULi=InnerList(Li)

    -- Primary color preview
    local ColRow=MkFrame({Size=UDim2.new(1,0,0,54),BackgroundColor3=C.BG3,ZIndex=16},ULi)
    Corner(10,ColRow); Stroke(1,C.BR0,ColRow)
    MkLabel({Size=UDim2.new(1,-80,0,18),Position=UDim2.new(0,14,0,10),BackgroundTransparency=1,
        Text="Primary Color",Font=Enum.Font.GothamSemibold,TextSize=12,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},ColRow)
    local ColPrev=MkFrame({Size=UDim2.new(0,120,0,26),Position=UDim2.new(0,14,0,24),BackgroundColor3=C.P1,ZIndex=17},ColRow)
    Corner(6,ColPrev); Grad(C.P1,C.A1,0,ColPrev)

    MkSlider(ULi,"Rojo primario",0,255,130,"",nil,nil)
    MkSlider(ULi,"Verde primario",0,255,80,"",nil,nil)
    MkSlider(ULi,"Azul primario",0,255,255,"",nil,nil)
    MkSlider(ULi,"Transparencia panel",0,80,10,"%",nil,nil)

    SectionLabel(Li,"EFFECTS")
    local ELi=InnerList(Li)
    MkToggle(ELi,"Efecto Glassmorphic",true,"Transparencia en paneles",nil)
    MkToggle(ELi,"Animaciones",true,"Transiciones animadas",nil)
    MkToggle(ELi,"Partículas UI",false,"Partículas decorativas",nil)
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB: POWER
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_POWER"]=function()
    local mob=IsMobile()
    local Tab,Sc,Li=ScrollTab("POWER")
    ContentHeader(Li,"POWER  ⏻","Opciones de sesión")

    SectionLabel(Li,"ACCIONES")
    local ALi=InnerList(Li)

    ActionBtn(ALi,"Reiniciar Quantum OS","🔄",C.TY,function()
        ScreenGui:Destroy(); task.wait(0.3)
        PushNotif("Sistema","Reiniciando...","SYSTEM",2)
    end)
    ActionBtn(ALi,"Minimizar UI","—",C.TS,function()
        -- trigger hide
        local MB=ScreenGui:FindFirstChild("RevealBall",true)
        PushNotif("UI","Interfaz minimizada · Toca la bolita para abrir","INFO",3)
    end)
    ActionBtn(ALi,"Limpiar Conexiones","♻",C.A1,function()
        for _,c in pairs(ENV.QOS_Connections) do pcall(function() c:Disconnect() end) end
        ENV.QOS_Connections={}
        PushNotif("Sistema","Conexiones limpiadas","SUCCESS",2)
    end)
    ActionBtn(ALi,"Desconectar del Juego","🚪",C.TY,function()
        pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
    end)

    -- Danger zone
    SectionLabel(Li,"ZONA PELIGROSA")
    local DLi=InnerList(Li)
    local CloseBtn=MkBtn({
        Size=UDim2.new(1,0,0,mob and 48 or 54),BackgroundColor3=Color3.fromRGB(40,8,8),
        Text="✕  CERRAR QUANTUM OS",Font=Enum.Font.GothamBold,
        TextSize=mob and 13 or 14,TextColor3=C.TR,ZIndex=16,
    },DLi); Corner(10,CloseBtn); Stroke(1,C.TR,CloseBtn)
    Hover(CloseBtn,Color3.fromRGB(40,8,8),Color3.fromRGB(60,10,10))
    CloseBtn.MouseButton1Click:Connect(function()
        Tw(ScreenGui,TI.MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.35); ScreenGui:Destroy()
    end)

    -- Version info
    local VF=MkFrame({Size=UDim2.new(1,0,0,mob and 54 or 60),BackgroundColor3=C.BG3,ZIndex=16},DLi)
    Corner(10,VF); Stroke(1,C.BR0,VF)
    MkLabel({Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,10),BackgroundTransparency=1,
        Text="QUANTUM OS v4.0 · Delta Edition",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=C.TW,ZIndex=17},VF)
    MkLabel({Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,28),BackgroundTransparency=1,
        Text="Multi-Agent AI · 5 Agentes · OpenRouter · LXNDXN",Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,ZIndex=17},VF)
    MkLabel({Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,42),BackgroundTransparency=1,
        Text="Modo: "..(ENV.QOS_DeviceMode or "Auto"):upper().." · Juego: "..GNAME:sub(1,20),
        Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,ZIndex=17},VF)
end

-- ═══════════════════════════════════════════════════════════════════════
-- WATERMARK
-- ═══════════════════════════════════════════════════════════════════════
local function CreateWatermark()
    local WM=MkFrame({Name="WM",Size=UDim2.new(0,200,0,22),Position=UDim2.new(0,6,0,4),
        BackgroundColor3=C.BG3,BackgroundTransparency=0.3,ZIndex=600},ScreenGui)
    Corner(10,WM); Stroke(1,C.BR0,WM)
    MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="Δ LXNDXN Quantum OS v4.0 · AI",Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.P2,ZIndex=601},WM)
end

-- ═══════════════════════════════════════════════════════════════════════
-- KEYBOARD SHORTCUTS
-- ═══════════════════════════════════════════════════════════════════════
local KM={
    [Enum.KeyCode.F1]={t="START"},
    [Enum.KeyCode.F2]={t="SCRIPT HUB"},
    [Enum.KeyCode.F3]={t="TOOLBOX"},
    [Enum.KeyCode.F4]={t="SYSTEM SETTINGS"},
    [Enum.KeyCode.F5]={t="MEDIA CENTER"},
    [Enum.KeyCode.F6]={t="QUANTUM ORACLE"},
    [Enum.KeyCode.F7]={t="PROCESSES"},
    [Enum.KeyCode.F8]={t="FILE MANAGER"},
}

Track(UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    local b=KM[inp.KeyCode]
    if b and ENV.QOS_Unlocked then
        ClearContent(); SetActiveTab(b.t)
        local fk="QOS_Tab_"..b.t:gsub("%s+","_")
        if _G[fk] then pcall(_G[fk]) end
        PushNotif("QOS",b.t,"INFO",1.5)
    end
end))

-- Chat commands
local CC={
    ["/qfly"]   =function() if FlyMod.Active then FlyMod.Off() else FlyMod.On() end; PushNotif("Fly","Fly "..(FlyMod.Active and "ON" or "OFF"),"INFO",2) end,
    ["/qesp"]   =function() if ESPMod.Active then ESPMod.Off() else ESPMod.On() end; PushNotif("ESP","ESP "..(ESPMod.Active and "ON" or "OFF"),"INFO",2) end,
    ["/qgod"]   =function() if GodMod.Active then GodMod.Off() else GodMod.On() end; PushNotif("God","God Mode "..(GodMod.Active and "ON" or "OFF"),"INFO",2) end,
    ["/qspeed"] =function(a) MovMod.Speed(tonumber(a[1]) or 100); PushNotif("Speed","WalkSpeed → "..(a[1] or "100"),"INFO",2) end,
    ["/qjump"]  =function(a) MovMod.Jump(tonumber(a[1]) or 100); PushNotif("Jump","JumpPower → "..(a[1] or "100"),"INFO",2) end,
    ["/qreset"] =function() MovMod.Speed(16); MovMod.Jump(50); PushNotif("Reset","Stats reseteados","SUCCESS",2) end,
    ["/qoracle"]=function() ClearContent(); SetActiveTab("QUANTUM ORACLE"); pcall(_G["QOS_Tab_QUANTUM_ORACLE"]) end,
    ["/qhelp"]  =function() PushNotif("Comandos","/qfly /qesp /qgod /qspeed /qjump /qreset /qoracle","ORACLE",6) end,
}
pcall(function()
    Track(LP.Chatted:Connect(function(msg)
        local p=msg:split(" "); local cmd=p[1]:lower(); local a={}
        for i=2,#p do a[#a+1]=p[i] end
        if CC[cmd] then pcall(function() CC[cmd](a) end) end
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════
-- HEARTBEAT & CHARACTER
-- ═══════════════════════════════════════════════════════════════════════
Track(RunService.Heartbeat:Connect(function()
    pcall(function()
        if LP.Character then
            local h=LP.Character:FindFirstChildOfClass("Humanoid"); if h then Humanoid=h end
        end
    end)
end))
Track(LP.CharacterAdded:Connect(function(c)
    Character=c; task.wait(0.5); Humanoid=c:FindFirstChildOfClass("Humanoid")
end))

-- ═══════════════════════════════════════════════════════════════════════
-- GLOBAL API
-- ═══════════════════════════════════════════════════════════════════════
ENV.QuantumOS={
    version="4.0", edition="Delta",
    modules={Fly=FlyMod,ESP=ESPMod,God=GodMod,NoClip=NoClipMod,Mov=MovMod},
    ui={notif=PushNotif},
    ai={query=OracleQuery,verify=VerifyAPIKey,models=AI.MODEL},
    commands=CC,
}

-- ═══════════════════════════════════════════════════════════════════════
-- LAUNCH
-- ═══════════════════════════════════════════════════════════════════════
local function PostLaunch()
    pcall(CreateWatermark)
    task.delay(1.2,function() PushNotif("Atajos","F1–F8: Tabs · RShift: Toggle","INFO",5) end)
    task.delay(3.5,function() PushNotif("Oracle AI","5 agentes especializados listos · /qhelp","ORACLE",4) end)
    task.delay(6.0,function() PushNotif("Quantum OS v4.0","Sistema Multi-Agent AI operativo ✓","SYSTEM",3) end)
end

local function Launch()
    ENV.QOS_Unlocked=true; ENV.QOS_DeviceMode="auto"
    CreateMainWindow()
    task.wait(0.15)
    SetActiveTab("START"); ENV.QOS_ActiveTab="START"; _G["QOS_Tab_START"]()
    task.delay(0.5,function() pcall(PostLaunch) end)
end

-- BOOT → LOGIN → MAIN
pcall(function()
    CreateBoot()
    task.delay(4.8,function()
        pcall(function()
            CreateLogin(function()
                task.wait(0.2); pcall(Launch)
            end)
        end)
    end)
end)

print("╔══════════════════════════════════════════════════════╗")
print("║  LXNDXN QUANTUM OS v4.0 · DELTA EDITION             ║")
print("║  Jugador : "..string.format("%-42s",DNAME).."║")
print("║  Juego   : "..string.format("%-42s",GNAME:sub(1,42)).."║")
print("║  F1–F8   : Tabs · /qhelp : Comandos                 ║")
print("╚══════════════════════════════════════════════════════╝")
