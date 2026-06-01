-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  LXNDXN QUANTUM OS  v3.1 · DELTA EDITION · MULTI-AGENT AI ORCHESTRATOR ║
-- ║  Author  : LXNDXN                                                       ║
-- ║  Engine  : Delta Executor (Mobile + PC Responsive)                      ║
-- ║  Version : 3.1.0-DE                                                     ║
-- ║  Theme   : Cyberpunk Noir · Neon Violet · Glassmorphic Pro              ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════════════
-- §1  ENVIRONMENT BOOTSTRAP
-- ═══════════════════════════════════════════════════════════════════════
local ENV = getgenv()
if ENV.QOS_Instance   then pcall(function() ENV.QOS_Instance:Destroy()   end) end
if ENV.QOS_OracleFloat then pcall(function() ENV.QOS_OracleFloat:Destroy() end) end
if ENV.QOS_Connections then for _, c in pairs(ENV.QOS_Connections) do pcall(function() c:Disconnect() end) end end

ENV.QOS_Connections  = {}
ENV.QOS_ActiveTab    = nil
ENV.QOS_Unlocked     = false
ENV.QOS_APIKey       = nil
ENV.QOS_DeviceMode   = nil

-- ═══════════════════════════════════════════════════════════════════════
-- §2  SERVICIOS
-- ═══════════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")

local LP         = Players.LocalPlayer
local PlayerGui  = LP:WaitForChild("PlayerGui")
local Character  = LP.Character or LP.CharacterAdded:Wait()
local Humanoid   = Character:FindFirstChildOfClass("Humanoid")
local DNAME      = LP.DisplayName
local UNAME      = LP.Name
local GNAME      = game.Name or "Roblox"

-- ═══════════════════════════════════════════════════════════════════════
-- §3  DETECCIÓN RESPONSIVE
-- ═══════════════════════════════════════════════════════════════════════
local function GetScreenSize()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function IsMobile()
    local ss = GetScreenSize()
    return ss.X < 600 or UserInputService.TouchEnabled
end

-- ═══════════════════════════════════════════════════════════════════════
-- §4  PALETA DE COLORES
-- ═══════════════════════════════════════════════════════════════════════
local C = {
    -- Primaries
    P1      = Color3.fromRGB(148, 28,  230),  -- Violet principal
    P2      = Color3.fromRGB(186, 80,  255),  -- Violet claro
    P3      = Color3.fromRGB( 78,  8,  140),  -- Violet oscuro
    -- Accents
    A1      = Color3.fromRGB(  0, 210,  255),  -- Cyan brillante
    A2      = Color3.fromRGB(  0, 140,  190),  -- Cyan medio
    A3      = Color3.fromRGB(255,  55,  150),  -- Pink accent
    A4      = Color3.fromRGB(255, 185,   45),  -- Gold
    -- Backgrounds (profundidad estratificada)
    BG0     = Color3.fromRGB(  3,   3,  11),   -- Más profundo
    BG1     = Color3.fromRGB(  7,   6,  19),   -- Panel base
    BG2     = Color3.fromRGB( 12,  11,  30),   -- Card
    BG3     = Color3.fromRGB( 18,  16,  42),   -- Card elevada
    BG4     = Color3.fromRGB( 24,  20,  56),   -- Hover/glass
    BGH     = Color3.fromRGB(  9,   7,  24),   -- Header
    BGS     = Color3.fromRGB(  5,   5,  15),   -- Sidebar
    -- Texto
    TW      = Color3.fromRGB(235, 232,  255),  -- Blanco
    TS      = Color3.fromRGB(165, 158,  205),  -- Suave
    TM      = Color3.fromRGB( 88,  82,  128),  -- Muted
    TG      = Color3.fromRGB(  0, 215,  125),  -- Verde
    TR      = Color3.fromRGB(255,  72,   72),  -- Rojo
    TY      = Color3.fromRGB(255, 208,   55),  -- Amarillo
    -- Borders
    BR0     = Color3.fromRGB( 45,  35,   88),  -- Normal
    BR1     = Color3.fromRGB(100,  55,  175),  -- Bright
    BR2     = Color3.fromRGB(148,  28,  230),  -- Glow
    -- Estado
    TON     = Color3.fromRGB(  0, 190,  115),
    TOFF    = Color3.fromRGB( 44,  40,   70),
    SBG     = Color3.fromRGB( 22,  18,   52),
    SFG     = Color3.fromRGB(148,  28,  230),
}

-- ═══════════════════════════════════════════════════════════════════════
-- §5  TWEEN INFOS
-- ═══════════════════════════════════════════════════════════════════════
local TI = {
    SNAP    = TweenInfo.new(0.10, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    FAST    = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out),
    MED     = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    SLOW    = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    BOUNCE  = TweenInfo.new(0.48, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    SPRING  = TweenInfo.new(0.60, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    SINE    = TweenInfo.new(1.40, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
    PULSE   = TweenInfo.new(1.00, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut, -1, true),
}

-- ═══════════════════════════════════════════════════════════════════════
-- §6  UTILIDADES UI
-- ═══════════════════════════════════════════════════════════════════════
local function Make(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do pcall(function() i[k] = v end) end
    if parent then i.Parent = parent end
    return i
end

local function MkFrame(p, par)  return Make("Frame",          p, par) end
local function MkLabel(p, par)  return Make("TextLabel",      p, par) end
local function MkBtn(p, par)    return Make("TextButton",     p, par) end
local function MkBox(p, par)    return Make("TextBox",        p, par) end
local function MkImg(p, par)    return Make("ImageLabel",     p, par) end
local function MkScroll(p, par) return Make("ScrollingFrame", p, par) end

local function Tw(inst, ti, props) return TweenService:Create(inst, ti, props):Play() end

local function Corner(r, p)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c
end

local function Stroke(thick, color, p)
    local s = Instance.new("UIStroke"); s.Thickness = thick
    s.Color = color or C.BR0; s.Parent = p; return s
end

local function Pad(t, r, b, l, p)
    local u = Instance.new("UIPadding")
    u.PaddingTop = UDim.new(0, t or 0); u.PaddingRight  = UDim.new(0, r or 0)
    u.PaddingBottom = UDim.new(0, b or 0); u.PaddingLeft = UDim.new(0, l or 0)
    u.Parent = p; return u
end

local function ListL(props, p)
    local l = Instance.new("UIListLayout")
    for k, v in pairs(props or {}) do pcall(function() l[k] = v end) end
    l.Parent = p; return l
end

local function GridL(props, p)
    local g = Instance.new("UIGridLayout")
    for k, v in pairs(props or {}) do pcall(function() g[k] = v end) end
    g.Parent = p; return g
end

local function Grad(c0, c1, rot, p)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 90
    g.Parent = p; return g
end

local function Track(conn) table.insert(ENV.QOS_Connections, conn); return conn end

local function PulseStroke(s, a, b)
    task.spawn(function()
        local d = true
        while s and s.Parent do
            Tw(s, TI.SINE, {Color = d and b or a}); task.wait(1.4); d = not d
        end
    end)
end

local function Typewrite(lbl, txt, spd)
    spd = spd or 0.035; lbl.Text = ""
    task.spawn(function()
        for i = 1, #txt do lbl.Text = txt:sub(1, i); task.wait(spd) end
    end)
end

local function Hover(btn, off, on)
    btn.MouseEnter:Connect(function() Tw(btn, TI.FAST, {BackgroundColor3 = on}) end)
    btn.MouseLeave:Connect(function() Tw(btn, TI.FAST, {BackgroundColor3 = off}) end)
end

-- Partículas flotantes genéricas
local function SpawnParticles(parent, count, zIdx)
    for i = 1, count do
        local sz = math.random(2, 5)
        local px = MkFrame({
            Size = UDim2.new(0, sz, 0, sz),
            Position = UDim2.new(math.random() * 0.96, 0, math.random() * 0.96, 0),
            BackgroundColor3 = (i%3==0) and C.P1 or (i%3==1) and C.A1 or C.A3,
            BackgroundTransparency = 0.5, ZIndex = zIdx or 3,
        }, parent)
        Corner(sz, px)
        task.spawn(function()
            while px and px.Parent do
                Tw(px, TweenInfo.new(3.5 + math.random() * 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(math.random() * 0.96, 0, math.random() * 0.96, 0),
                    BackgroundTransparency = 0.1 + math.random() * 0.75,
                })
                task.wait(3.5 + math.random() * 4)
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- §7  ROOT GUI
-- ═══════════════════════════════════════════════════════════════════════
local ScreenGui = Make("ScreenGui", {
    Name = "QuantumOS_v31", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, PlayerGui)

ENV.QOS_Instance = ScreenGui

local BG = MkFrame({
    Name = "BG", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.BG0, BorderSizePixel = 0, ZIndex = 1,
}, ScreenGui)

-- Grid de fondo sutil
MkImg({
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Image = "rbxassetid://6370457276",
    ImageColor3 = C.P1, ImageTransparency = 0.955, ZIndex = 2,
}, BG)

SpawnParticles(BG, 16, 3)

-- ═══════════════════════════════════════════════════════════════════════
-- §8  AI MULTI-AGENT SYSTEM
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
    STRATEGY = {icon="⚔", name="Strategy Agent", color=Color3.fromRGB(225,55,55)},
    CREATIVE = {icon="🎨", name="Creative Agent", color=Color3.fromRGB(195,100,255)},
    FAST     = {icon="⚡", name="Fast Agent",     color=Color3.fromRGB(255,220,55)},
}
AI.SYS = {
    ORCH = [[Eres el Orquestador del Quantum OS (Roblox). Analiza y responde SOLO este JSON (sin texto extra):
{"agent":"GAME|CODE|STRATEGY|CREATIVE|FAST","reason":"motivo"}
GAME=mecánicas/items/juego, CODE=scripts/lua/errores, STRATEGY=builds/estrategia, CREATIVE=ideas/personalización, FAST=saludos/simples
Juego actual: ]]..GNAME,
    GAME     = "Eres el Game Analyst del Quantum OS. Experto en '"..GNAME.."'. Analiza mecánicas, items, bosses, mapas con detalle. Responde en español, máx 130 palabras.",
    CODE     = "Eres el Code Expert del Quantum OS. Experto Lua/Roblox para Delta Executor. Ayuda con scripts, bugs, optimización. Responde en español con código limpio. Máx 160 palabras.",
    STRATEGY = "Eres el Strategy Agent del Quantum OS. Experto en '"..GNAME.."'. Estrategias óptimas, builds, rutas de farming. Responde en español, conciso. Máx 130 palabras.",
    CREATIVE = "Eres el Creative Agent del Quantum OS. Ayudas con ideas de personalización, roleplay, diseño UI para Roblox. Responde en español con entusiasmo. Máx 110 palabras.",
    FAST     = "Eres el asistente rápido del Quantum OS para '"..GNAME.."'. Breve, amigable, directo en español. Máx 70 palabras.",
}

-- Llamada base HTTP a OpenRouter
local function OR_Call(model, sys, usr, maxTok)
    maxTok = maxTok or 320
    local key = ENV.QOS_APIKey
    if not key or key == "" then return nil, "Sin API Key" end
    local ok, res = pcall(function()
        local body = HttpService:JSONEncode({
            model = model, max_tokens = maxTok,
            messages = {{role="system",content=sys},{role="user",content=usr}},
        })
        local r = HttpService:RequestAsync({
            Url    = "https://openrouter.ai/api/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer "..key,
                ["Content-Type"]  = "application/json",
                ["HTTP-Referer"]  = "https://lxndxn-qos.rblx",
                ["X-Title"]       = "LXNDXN Quantum OS",
            },
            Body = body,
        })
        if r.StatusCode ~= 200 then return nil, "HTTP "..r.StatusCode end
        local d = HttpService:JSONDecode(r.Body)
        if d.error then return nil, d.error.message or "API error" end
        return d.choices and d.choices[1] and d.choices[1].message and d.choices[1].message.content
    end)
    if ok then return res, nil else return nil, tostring(res) end
end

-- ── FIX: Verificación robusta de API Key ──────────────────────────────
-- No buscamos "OK" literal; cualquier respuesta no-vacía y sin error = válida
local function VerifyAPIKey(key, cb)
    task.spawn(function()
        local oldKey = ENV.QOS_APIKey
        ENV.QOS_APIKey = key
        local ok, err = pcall(function()
            local body = HttpService:JSONEncode({
                model = AI.MODEL.FAST,
                max_tokens = 16,
                messages = {{role="user", content="Di: listo"}},
            })
            local r = HttpService:RequestAsync({
                Url    = "https://openrouter.ai/api/v1/chat/completions",
                Method = "POST",
                Headers = {
                    ["Authorization"] = "Bearer "..key,
                    ["Content-Type"]  = "application/json",
                    ["HTTP-Referer"]  = "https://lxndxn-qos.rblx",
                    ["X-Title"]       = "LXNDXN Quantum OS",
                },
                Body = body,
            })
            if r.StatusCode == 200 then
                local d = HttpService:JSONDecode(r.Body)
                -- Cualquier respuesta válida de choices == API key funciona
                if d.choices and d.choices[1] then
                    return true
                elseif d.error then
                    error(d.error.message or "invalid_key")
                end
            elseif r.StatusCode == 401 then
                error("API Key inválida (401)")
            elseif r.StatusCode == 402 then
                error("Sin créditos en cuenta (402)")
            elseif r.StatusCode == 429 then
                error("Rate limit alcanzado (429)")
            else
                error("HTTP "..r.StatusCode)
            end
        end)
        if ok then
            cb(true, "Conexión verificada")
        else
            ENV.QOS_APIKey = oldKey
            cb(false, tostring(err):gsub(".*: ",""))
        end
    end)
end

-- Oracle multi-agente
local function OracleQuery(msg, onThink, onAgent, onResp, onErr)
    task.spawn(function()
        if onThink then onThink("Orquestador analizando...") end
        local orchRes = OR_Call(AI.ORCH, AI.SYS.ORCH, msg, 80)
        local agentKey = "FAST"
        if orchRes then
            local ok2, dec = pcall(function() return HttpService:JSONDecode(orchRes) end)
            if ok2 and dec and dec.agent then agentKey = dec.agent end
        end
        local meta = AI.META[agentKey] or AI.META.FAST
        if onAgent then onAgent(agentKey, meta) end
        if onThink then onThink(meta.icon.." "..meta.name.." procesando...") end
        local resp, err = OR_Call(AI.MODEL[agentKey] or AI.MODEL.FAST,
            AI.SYS[agentKey] or AI.SYS.FAST, msg, 320)
        if resp then
            if onResp then onResp(resp, meta) end
        else
            if onErr then onErr(err or "Error desconocido") end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- §9  NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════
local NT = {
    INFO    = {icon="ℹ", c=C.A1,  bg=Color3.fromRGB(0,24,42)},
    SUCCESS = {icon="✓", c=C.TG,  bg=Color3.fromRGB(0,34,16)},
    WARNING = {icon="⚠", c=C.TY,  bg=Color3.fromRGB(44,28,0)},
    ERROR   = {icon="✕", c=C.TR,  bg=Color3.fromRGB(52,0,0)},
    ORACLE  = {icon="🔮",c=C.P2,  bg=Color3.fromRGB(24,0,52)},
    SYSTEM  = {icon="⬡", c=C.P1,  bg=Color3.fromRGB(16,4,38)},
    AI      = {icon="🤖",c=C.A4,  bg=Color3.fromRGB(36,26,0)},
}
local nStack, NW, NH, NM = {}, 300, 72, 8
local toastQ, toastActive = {}, false

local PushNotif, ShowToast

PushNotif = function(title, body, typ, dur)
    typ = typ or "INFO"; dur = dur or 3.5
    local t = NT[typ] or NT.INFO
    if #nStack >= 4 then return end
    local slot = #nStack + 1; table.insert(nStack, slot)
    local yOff = -(slot * (NH + NM))
    local NF = MkFrame({
        Size = UDim2.new(0, NW, 0, NH),
        Position = UDim2.new(1, 14, 1, yOff),
        BackgroundColor3 = t.bg, ZIndex = 1100 + slot,
    }, ScreenGui)
    Corner(14, NF); Stroke(1, t.c, NF)
    -- Barra izquierda coloreada
    local Acc = MkFrame({Size=UDim2.new(0,3,1,-16), Position=UDim2.new(0,0,0,8),
        BackgroundColor3=t.c, ZIndex=1101+slot}, NF)
    Corner(2, Acc)
    MkLabel({Size=UDim2.new(0,38,1,0), BackgroundTransparency=1,
        Text=t.icon, TextSize=19, TextColor3=t.c, ZIndex=1102+slot}, NF)
    MkLabel({Size=UDim2.new(1,-62,0,22), Position=UDim2.new(0,50,0,9),
        BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamBold,
        TextSize=12, TextColor3=C.TW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1102+slot}, NF)
    MkLabel({Size=UDim2.new(1,-62,0,22), Position=UDim2.new(0,50,0,30),
        BackgroundTransparency=1, Text=body, Font=Enum.Font.Gotham,
        TextSize=10, TextColor3=C.TS, TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1102+slot}, NF)
    local PBG = MkFrame({Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=C.SBG, ZIndex=1103+slot}, NF)
    local PF = MkFrame({Size=UDim2.new(1,0,1,0), BackgroundColor3=t.c, ZIndex=1104+slot}, PBG)
    local CBtn = MkBtn({Size=UDim2.new(0,20,0,20), Position=UDim2.new(1,-24,0,4),
        BackgroundTransparency=1, Text="✕", Font=Enum.Font.GothamBold,
        TextSize=10, TextColor3=C.TM, ZIndex=1105+slot}, NF)
    Tw(NF, TI.BOUNCE, {Position=UDim2.new(1, -(NW+12), 1, yOff)})
    Tw(PF, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size=UDim2.new(0, 0, 1, 0)})
    local function Dismiss()
        Tw(NF, TI.MED, {Position=UDim2.new(1, 14, 1, yOff)}); task.wait(0.38)
        pcall(function() local idx=table.find(nStack,slot); if idx then table.remove(nStack,idx) end; NF:Destroy() end)
    end
    CBtn.MouseButton1Click:Connect(Dismiss)
    task.delay(dur, function() pcall(Dismiss) end)
end

ShowToast = function(title, body, icon, dur)
    dur = dur or 3
    table.insert(toastQ, {title=title, body=body, icon=icon or "⬡", dur=dur})
    if toastActive then return end
    toastActive = true
    task.spawn(function()
        while #toastQ > 0 do
            local t = table.remove(toastQ, 1)
            local T = MkFrame({
                Size=UDim2.new(0,290,0,66), Position=UDim2.new(1,14,1,-84),
                BackgroundColor3=C.BG3, ZIndex=1000,
            }, ScreenGui)
            Corner(14, T); Stroke(2, C.BR1, T)
            Grad(C.BG3, Color3.fromRGB(28, 16, 60), 135, T)
            MkLabel({Size=UDim2.new(0,42,1,0), BackgroundTransparency=1, Text=t.icon, TextSize=22, ZIndex=1001}, T)
            MkLabel({Size=UDim2.new(1,-52,0,22), Position=UDim2.new(0,46,0,9), BackgroundTransparency=1,
                Text=t.title, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.TW,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1001}, T)
            MkLabel({Size=UDim2.new(1,-52,0,20), Position=UDim2.new(0,46,0,32), BackgroundTransparency=1,
                Text=t.body, Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TS,
                TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=1001}, T)
            Tw(T, TI.MED, {Position=UDim2.new(1,-(302),1,-84)})
            task.wait(t.dur)
            Tw(T, TI.MED, {Position=UDim2.new(1,14,1,-84)}); task.wait(0.4)
            T:Destroy(); task.wait(0.25)
        end
        toastActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- §10  BOOT SCREEN
-- ═══════════════════════════════════════════════════════════════════════
local function CreateBoot()
    local Boot = MkFrame({
        Name="Boot", Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG0, ZIndex=100,
    }, ScreenGui)
    Grad(C.BG0, Color3.fromRGB(8, 4, 22), 135, Boot)

    local W = MkFrame({
        Size=UDim2.new(0,360,0,400), Position=UDim2.new(0.5,-180,0.5,-200),
        BackgroundColor3=C.BG2, BackgroundTransparency=0.28, ZIndex=101,
    }, Boot)
    Corner(28, W)
    local ws = Stroke(1, C.P1, W); PulseStroke(ws, C.P3, C.P2)

    -- Glow externo
    local Glow = MkFrame({
        Size=UDim2.new(1.5,0,1.4,0), Position=UDim2.new(-0.25,0,-0.2,0),
        BackgroundColor3=C.P1, BackgroundTransparency=0.92, ZIndex=100,
    }, W); Corner(60, Glow)
    task.spawn(function()
        while Glow and Glow.Parent do
            Tw(Glow,TI.SINE,{BackgroundTransparency=0.94}); task.wait(1.4)
            Tw(Glow,TI.SINE,{BackgroundTransparency=0.89}); task.wait(1.4)
        end
    end)

    SpawnParticles(W, 8, 102)

    local Logo = MkLabel({
        Size=UDim2.new(1,0,0,80), Position=UDim2.new(0,0,0,20),
        BackgroundTransparency=1, Text="⬡", Font=Enum.Font.GothamBold,
        TextSize=66, TextColor3=C.P1, ZIndex=103,
    }, W)
    task.spawn(function()
        while Logo and Logo.Parent do
            Tw(Logo,TI.SINE,{TextColor3=C.P2,TextTransparency=0.08}); task.wait(1.4)
            Tw(Logo,TI.SINE,{TextColor3=C.P1,TextTransparency=0}); task.wait(1.4)
        end
    end)

    MkLabel({Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,104),
        BackgroundTransparency=1, Text="QUANTUM OS  v3.1",
        Font=Enum.Font.GothamBold, TextSize=22, TextColor3=C.TW, ZIndex=103}, W)

    local Badge = MkLabel({
        Size=UDim2.new(0,210,0,24), Position=UDim2.new(0.5,-105,0,135),
        BackgroundColor3=C.P3, BackgroundTransparency=0.3,
        Text="✦ DELTA EDITION · MULTI-AGENT AI ✦",
        Font=Enum.Font.GothamSemibold, TextSize=10, TextColor3=C.A1, ZIndex=103,
    }, W); Corner(12, Badge)

    local WelL = MkLabel({Size=UDim2.new(1,-40,0,40), Position=UDim2.new(0,20,0,172),
        BackgroundTransparency=1, Text="", Font=Enum.Font.Gotham,
        TextSize=13, TextColor3=C.TW, TextWrapped=true, ZIndex=103}, W)

    local SubL = MkLabel({Size=UDim2.new(1,-40,0,36), Position=UDim2.new(0,20,0,216),
        BackgroundTransparency=1, Text="", Font=Enum.Font.Gotham,
        TextSize=11, TextColor3=C.TS, TextWrapped=true, ZIndex=103}, W)

    local PBG = MkFrame({
        Size=UDim2.new(1,-40,0,5), Position=UDim2.new(0,20,0,300),
        BackgroundColor3=C.SBG, ZIndex=103,
    }, W); Corner(3, PBG)
    local PF = MkFrame({Size=UDim2.new(0,0,1,0), BackgroundColor3=C.P1, ZIndex=104}, PBG)
    Corner(3, PF); Grad(C.P1, C.A1, 0, PF)
    local PL = MkLabel({Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,4),
        BackgroundTransparency=1, Text="Inicializando...",
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=C.TM, ZIndex=103}, PBG)

    MkLabel({Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-20),
        BackgroundTransparency=1, Text="LXNDXN · Delta Edition · Multi-Agent AI v3.1",
        Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TM, ZIndex=103}, W)

    task.spawn(function()
        task.wait(0.5)
        Typewrite(WelL, "Hola, "..DNAME..". Iniciando Quantum OS v3.1...", 0.04)
        task.wait(1.8)
        Typewrite(SubL, "Sistema Multi-Agente AI cargando...\nOrquestador · 5 Agentes Especializados.", 0.03)
        task.wait(1.4)
        local steps = {
            {0.14,"Cargando kernel..."},{0.30,"Verificando Delta Executor..."},
            {0.46,"Inicializando UI responsive..."},{0.62,"Conectando Orquestador AI..."},
            {0.76,"Activando agentes especializados..."},{0.90,"Estableciendo sesión..."},
            {1.00,"Listo. Autenticación requerida."},
        }
        for _, s in ipairs(steps) do
            Tw(PF, TI.MED, {Size=UDim2.new(s[1],0,1,0)}); PL.Text = s[2]; task.wait(0.40)
        end
        task.wait(0.5)
        Tw(Boot, TI.SLOW, {BackgroundTransparency=1})
        Tw(W,    TI.SLOW, {BackgroundTransparency=1})
        task.wait(0.65); Boot:Destroy()
    end)
    return Boot
end

-- ═══════════════════════════════════════════════════════════════════════
-- §11  LOGIN SCREEN (Responsive · fix verificación)
-- ═══════════════════════════════════════════════════════════════════════
local function CreateLogin(onSuccess)
    local mobile = IsMobile()
    local ss = GetScreenSize()

    -- Dimensiones adaptativas
    local PW  = mobile and math.min(ss.X - 24, 380) or 440
    local PH  = mobile and 480 or 560
    local PX  = (ss.X - PW) / 2
    local PY  = mobile and math.max(8, (ss.Y - PH) / 2) or (ss.Y - PH) / 2

    local titleSz    = mobile and 20 or 26
    local subSz      = mobile and 11 or 13
    local inputSz    = mobile and 13 or 14
    local btnSz      = mobile and 15 or 16
    local logoSz     = mobile and 46 or 60
    local logoFrameH = mobile and 60 or 80
    local logoFrameW = mobile and 60 or 80

    local LS = MkFrame({
        Name="Login", Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG0, ZIndex=90,
    }, ScreenGui)
    Grad(Color3.fromRGB(3,2,12), Color3.fromRGB(12,5,32), 150, LS)

    -- Scan lines animadas
    task.spawn(function()
        while LS and LS.Parent do
            local line = MkFrame({
                Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,-0.02,0),
                BackgroundColor3=C.P1, BackgroundTransparency=0.88, ZIndex=91,
            }, LS)
            Tw(line, TweenInfo.new(3+math.random()*3, Enum.EasingStyle.Linear), {Position=UDim2.new(0,0,1.02,0)})
            task.wait(4+math.random()*4); pcall(function() line:Destroy() end)
        end
    end)

    -- Hexágonos decorativos
    local hexPos = {{0.05,0.08},{0.88,0.06},{0.02,0.82},{0.90,0.88},{0.50,0.02},{0.50,0.96}}
    for _, hp in ipairs(hexPos) do
        local hl = MkLabel({
            Size=UDim2.new(0,70,0,70),
            Position=UDim2.new(hp[1]-0.035,0,hp[2]-0.06,0),
            BackgroundTransparency=1, Text="⬡", Font=Enum.Font.GothamBold,
            TextSize=62, TextColor3=C.P1, TextTransparency=0.90, ZIndex=91,
        }, LS)
        task.spawn(function()
            local d=true
            while hl and hl.Parent do
                Tw(hl,TI.SINE,{TextTransparency=d and 0.93 or 0.84}); task.wait(1.6+math.random()*2); d=not d
            end
        end)
    end

    SpawnParticles(LS, 14, 91)

    -- ── PANEL PRINCIPAL ──────────────────────────────────────────────
    local Panel = MkFrame({
        Name="LoginPanel",
        Size=UDim2.new(0,PW,0,PH),
        Position=UDim2.new(0,PX,0,PY),
        BackgroundColor3=Color3.fromRGB(10,8,26),
        BackgroundTransparency=0.10, ZIndex=92,
    }, LS)
    Corner(24, Panel)
    local PS = Stroke(1, C.BR1, Panel); PulseStroke(PS, C.P3, C.P2)

    -- Glow interno del panel
    local PGlow = MkFrame({
        Size=UDim2.new(1.3,0,1.2,0), Position=UDim2.new(-0.15,0,-0.1,0),
        BackgroundColor3=C.P1, BackgroundTransparency=0.93, ZIndex=91,
    }, Panel); Corner(50, PGlow)

    SpawnParticles(Panel, 6, 93)

    -- Línea decorativa superior (gradiente)
    local TopLine = MkFrame({
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=C.P1, ZIndex=93,
    }, Panel); Corner(24, TopLine)
    Grad(C.P3, C.A1, 0, TopLine)

    -- ── LOGO (compacto en móvil) ──────────────────────────────────────
    local logoY = mobile and 18 or 26
    local LF = MkFrame({
        Size=UDim2.new(0,logoFrameW,0,logoFrameH),
        Position=UDim2.new(0.5,-logoFrameW/2,0,logoY),
        BackgroundColor3=C.P3, BackgroundTransparency=0.25, ZIndex=93,
    }, Panel); Corner(logoFrameW/2, LF)
    Stroke(2, C.P1, LF); Grad(Color3.fromRGB(50,8,100), C.P3, 135, LF)

    local LI = MkLabel({
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
        Text="⬡", Font=Enum.Font.GothamBold, TextSize=logoSz, TextColor3=C.P1, ZIndex=94,
    }, LF)
    task.spawn(function()
        while LI and LI.Parent do
            Tw(LI,TI.SINE,{TextColor3=C.A1}); task.wait(1.4)
            Tw(LI,TI.SINE,{TextColor3=C.P1}); task.wait(1.4)
        end
    end)

    -- Anillo exterior
    local LR = MkFrame({
        Size=UDim2.new(0,logoFrameW+18,0,logoFrameH+18),
        Position=UDim2.new(0.5,-(logoFrameW+18)/2,0,logoY-9),
        BackgroundTransparency=1, ZIndex=93,
    }, Panel); Corner((logoFrameW+18)/2, LR)
    Stroke(1, C.P1, LR)

    -- ── TÍTULOS ──────────────────────────────────────────────────────
    local titleY = logoY + logoFrameH + 14
    MkLabel({
        Size=UDim2.new(1,0,0,titleSz+6), Position=UDim2.new(0,0,0,titleY),
        BackgroundTransparency=1, Text="QUANTUM OS",
        Font=Enum.Font.GothamBold, TextSize=titleSz, TextColor3=C.TW, ZIndex=93,
    }, Panel)

    MkLabel({
        Size=UDim2.new(1,0,0,subSz+6), Position=UDim2.new(0,0,0,titleY+titleSz+8),
        BackgroundTransparency=1, Text="Multi-Agent AI · Delta Edition · v3.1",
        Font=Enum.Font.GothamSemibold, TextSize=subSz, TextColor3=C.A1, ZIndex=93,
    }, Panel)

    -- Badges de agentes (más pequeños en móvil)
    local badgeY = titleY + titleSz + subSz + 22
    local BadgeRow = MkFrame({
        Size=UDim2.new(1,-32,0,mobile and 22 or 24),
        Position=UDim2.new(0,16,0,badgeY),
        BackgroundTransparency=1, ZIndex=93,
    }, Panel)
    ListL({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,4)}, BadgeRow)

    for _, ab in ipairs({{"🎮","Game"},{"💻","Code"},{"⚔","Strat"},{"🎨","Art"},{"⚡","Fast"}}) do
        local B = MkLabel({
            Size=UDim2.new(0,0,1,0), AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=Color3.fromRGB(18,6,44),
            Text=ab[1].." "..ab[2], Font=Enum.Font.Gotham,
            TextSize=mobile and 9 or 10, TextColor3=C.TS, ZIndex=94,
        }, BadgeRow)
        Corner(10, B); Stroke(1, C.P3, B); Pad(0,7,0,7,B)
    end

    -- ── SEPARADOR ────────────────────────────────────────────────────
    local sepY = badgeY + (mobile and 26 or 32)
    local Sep = MkFrame({Size=UDim2.new(0.75,0,0,1), Position=UDim2.new(0.125,0,0,sepY),
        BackgroundColor3=C.BR0, ZIndex=93}, Panel)
    Grad(C.BG0, C.BR1, 0, Sep)

    -- ── LABEL API KEY ────────────────────────────────────────────────
    local fieldY = sepY + (mobile and 10 or 16)
    MkLabel({
        Size=UDim2.new(1,-32,0,16), Position=UDim2.new(0,16,0,fieldY),
        BackgroundTransparency=1, Text="OPENROUTER API KEY",
        Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=93,
    }, Panel)

    -- ── INPUT BOX ────────────────────────────────────────────────────
    local inputY = fieldY + 20
    local inputH = mobile and 46 or 50
    local KB = MkBox({
        Size=UDim2.new(1,-32,0,inputH), Position=UDim2.new(0,16,0,inputY),
        BackgroundColor3=Color3.fromRGB(8,6,22), BorderSizePixel=0,
        Text="", PlaceholderText="sk-or-v1-xxxxxxxxxxxxxxxxxx",
        Font=Enum.Font.Code, TextSize=inputSz, TextColor3=C.TW,
        PlaceholderColor3=C.TM, ClearTextOnFocus=false, ZIndex=94,
    }, Panel); Corner(12, KB)
    local KBS = Stroke(1, C.BR0, KB)
    Pad(0,14,0,14,KB)
    KB.Focused:Connect(function()  Tw(KBS,TI.FAST,{Color=C.P1}) end)
    KB.FocusLost:Connect(function() Tw(KBS,TI.FAST,{Color=C.BR0}) end)

    -- ── STATUS ───────────────────────────────────────────────────────
    local statusY = inputY + inputH + 4
    local SL = MkLabel({
        Size=UDim2.new(1,-32,0,mobile and 18 or 20),
        Position=UDim2.new(0,16,0,statusY),
        BackgroundTransparency=1, Text="",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TM,
        TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=93,
    }, Panel)

    -- ── SPINNER ──────────────────────────────────────────────────────
    local spinnerY = statusY
    local Spinner = MkLabel({
        Size=UDim2.new(0,30,0,30),
        Position=UDim2.new(0.5,-15,0,spinnerY),
        BackgroundTransparency=1, Text="◌",
        Font=Enum.Font.GothamBold, TextSize=24,
        TextColor3=C.A1, Visible=false, ZIndex=95,
    }, Panel)

    -- ── BOTÓN VERIFICAR ──────────────────────────────────────────────
    local btnY = statusY + (mobile and 24 or 28)
    local btnH = mobile and 48 or 52
    local LBtn = MkBtn({
        Size=UDim2.new(1,-32,0,btnH), Position=UDim2.new(0,16,0,btnY),
        BackgroundColor3=C.P1, BorderSizePixel=0,
        Text="⚡  VERIFICAR API KEY",
        Font=Enum.Font.GothamBold, TextSize=btnSz, TextColor3=Color3.new(1,1,1), ZIndex=94,
    }, Panel); Corner(14, LBtn)
    Grad(Color3.fromRGB(120,18,200), Color3.fromRGB(72,0,165), 135, LBtn)
    Hover(LBtn, C.P1, C.P2)

    -- ── OBTENER KEY ──────────────────────────────────────────────────
    local getKeyY = btnY + btnH + (mobile and 8 or 12)
    local GKBtn = MkBtn({
        Size=UDim2.new(1,-32,0,mobile and 36 or 40),
        Position=UDim2.new(0,16,0,getKeyY),
        BackgroundColor3=Color3.fromRGB(12,10,30), BorderSizePixel=0,
        Text="🔑  Obtener API Key gratuita →",
        Font=Enum.Font.GothamSemibold, TextSize=mobile and 11 or 12,
        TextColor3=C.A1, ZIndex=94,
    }, Panel); Corner(12, GKBtn)
    Stroke(1, C.A2, GKBtn)
    GKBtn.MouseEnter:Connect(function() Tw(GKBtn,TI.FAST,{BackgroundColor3=Color3.fromRGB(0,24,44),TextColor3=C.TW}) end)
    GKBtn.MouseLeave:Connect(function() Tw(GKBtn,TI.FAST,{BackgroundColor3=Color3.fromRGB(12,10,30),TextColor3=C.A1}) end)
    GKBtn.MouseButton1Click:Connect(function()
        pcall(function() setclipboard("https://openrouter.ai/keys") end)
        SL.Text = "✓ openrouter.ai/keys copiado al portapapeles"
        SL.TextColor3 = C.A1
    end)

    -- ── FOOTER ───────────────────────────────────────────────────────
    MkLabel({
        Size=UDim2.new(1,-32,0,14), Position=UDim2.new(0,16,1,-26),
        BackgroundTransparency=1,
        Text="🔒 Key usada localmente · No almacenada · LXNDXN v3.1",
        Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TM,
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=93,
    }, Panel)

    -- ── LÓGICA DE VERIFICACIÓN (FIX) ─────────────────────────────────
    local function DoVerify()
        local key = KB.Text:gsub("%s+","")
        if key == "" then
            SL.Text="⚠ Ingresa tu API Key de OpenRouter."; SL.TextColor3=C.TY
            Tw(KB,TI.FAST,{BackgroundColor3=Color3.fromRGB(28,12,8)})
            task.wait(0.6); Tw(KB,TI.FAST,{BackgroundColor3=Color3.fromRGB(8,6,22)})
            return
        end

        LBtn.Visible=false; Spinner.Visible=true
        SL.Text="Conectando con OpenRouter..."; SL.TextColor3=C.A1

        local spinActive = true
        task.spawn(function()
            local frames={"◌","◍","◎","●","◎","◍"}; local idx=1
            while spinActive do
                Spinner.Text=frames[idx]; idx=idx%#frames+1; task.wait(0.09)
            end
        end)

        VerifyAPIKey(key, function(success, msg)
            spinActive=false; Spinner.Visible=false; LBtn.Visible=true
            if success then
                ENV.QOS_APIKey = key
                SL.Text="✓ Verificada · Conexión establecida"; SL.TextColor3=C.TG
                Tw(LBtn,TI.FAST,{BackgroundColor3=C.TON}); LBtn.Text="✓  CONECTADO"
                task.wait(0.9)
                Tw(LS,TI.MED,{BackgroundTransparency=1}); task.wait(0.4); LS:Destroy(); onSuccess()
            else
                SL.Text="✗ "..(msg or "Key inválida. Revisa tu cuenta en openrouter.ai")
                SL.TextColor3=C.TR
                -- Shake
                for _ = 1,5 do
                    Tw(Panel,TI.SNAP,{Position=UDim2.new(0,PX+6,0,PY)}); task.wait(0.05)
                    Tw(Panel,TI.SNAP,{Position=UDim2.new(0,PX-6,0,PY)}); task.wait(0.05)
                end
                Tw(Panel,TI.SNAP,{Position=UDim2.new(0,PX,0,PY)})
            end
        end)
    end

    LBtn.MouseButton1Click:Connect(DoVerify)
    KB.FocusLost:Connect(function(enter) if enter then DoVerify() end end)
    return LS
end

-- ═══════════════════════════════════════════════════════════════════════
-- §12  DEVICE SELECTION
-- ═══════════════════════════════════════════════════════════════════════
local function CreateDeviceSelect(onSelect)
    local ss = GetScreenSize()
    local mobile = IsMobile()
    local PW = mobile and math.min(ss.X-24, 360) or 440
    local PH = mobile and 400 or 450
    local PX = (ss.X-PW)/2
    local PY = math.max(8,(ss.Y-PH)/2)

    local DS = MkFrame({Name="DevSel", Size=UDim2.fromScale(1,1),
        BackgroundColor3=C.BG0, ZIndex=90}, ScreenGui)
    Grad(Color3.fromRGB(3,2,12), Color3.fromRGB(10,4,28), 140, DS)
    SpawnParticles(DS, 12, 91)

    local DP = MkFrame({
        Size=UDim2.new(0,PW,0,PH), Position=UDim2.new(0,PX,1.2,0),
        BackgroundColor3=Color3.fromRGB(10,8,26), BackgroundTransparency=0.08, ZIndex=92,
    }, DS)
    Corner(24, DP)
    local DPS = Stroke(1, C.P1, DP); PulseStroke(DPS, C.P3, C.P2)
    Tw(DP, TI.BOUNCE, {Position=UDim2.new(0,PX,0,PY)})

    -- Check icon
    local CI = MkLabel({
        Size=UDim2.new(0,56,0,56), Position=UDim2.new(0.5,-28,0,22),
        BackgroundColor3=Color3.fromRGB(0,36,16), BackgroundTransparency=0.25,
        Text="✓", Font=Enum.Font.GothamBold, TextSize=32, TextColor3=C.TG, ZIndex=93,
    }, DP); Corner(28, CI); Stroke(2, C.TG, CI)

    MkLabel({Size=UDim2.new(1,0,0,28), Position=UDim2.new(0,0,0,88),
        BackgroundTransparency=1, Text="✓  Conexión Establecida",
        Font=Enum.Font.GothamBold, TextSize=mobile and 18 or 22, TextColor3=C.TG, ZIndex=93}, DP)

    MkLabel({Size=UDim2.new(1,-32,0,16), Position=UDim2.new(0,16,0,120),
        BackgroundTransparency=1, Text="OpenRouter AI conectado · Selecciona tu modo",
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=C.TS, ZIndex=93}, DP)

    MkFrame({Size=UDim2.new(0.7,0,0,1), Position=UDim2.new(0.15,0,0,148),
        BackgroundColor3=C.BR0, ZIndex=93}, DP)

    MkLabel({Size=UDim2.new(1,0,0,18), Position=UDim2.new(0,0,0,158),
        BackgroundTransparency=1, Text="SELECCIONA TU DISPOSITIVO",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.P2, ZIndex=93}, DP)

    local function DevBtn(icon, label, desc, yPos, strokeC)
        local B = MkBtn({
            Size=UDim2.new(1,-32,0,mobile and 78 or 86),
            Position=UDim2.new(0,16,0,yPos),
            BackgroundColor3=Color3.fromRGB(12,9,32), BorderSizePixel=0, Text="", ZIndex=93,
        }, DP); Corner(16, B)
        local BS = Stroke(1, strokeC, B)
        MkLabel({Size=UDim2.new(0,50,0,50), Position=UDim2.new(0,14,0.5,-25),
            BackgroundTransparency=1, Text=icon, TextSize=30, ZIndex=94}, B)
        MkLabel({Size=UDim2.new(1,-80,0,24), Position=UDim2.new(0,72,0,14),
            BackgroundTransparency=1, Text=label, Font=Enum.Font.GothamBold,
            TextSize=mobile and 16 or 18, TextColor3=C.TW,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=94}, B)
        MkLabel({Size=UDim2.new(1,-80,0,18), Position=UDim2.new(0,72,0,38),
            BackgroundTransparency=1, Text=desc, Font=Enum.Font.Gotham,
            TextSize=10, TextColor3=C.TM, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=94}, B)
        B.MouseEnter:Connect(function()
            Tw(B,TI.FAST,{BackgroundColor3=Color3.fromRGB(30,12,72)})
            BS.Color = strokeC == C.P1 and C.P2 or C.A1
        end)
        B.MouseLeave:Connect(function()
            Tw(B,TI.FAST,{BackgroundColor3=Color3.fromRGB(12,9,32)}); BS.Color=strokeC
        end)
        return B
    end

    local MB = DevBtn("📱","📱  MÓVIL","UI táctil optimizada · Botones grandes", mobile and 178 or 186, C.P1)
    local PB = DevBtn("🖥","🖥  PC / ESCRITORIO","Sidebar completo · Atajos F1–F8", mobile and 266 or 282, C.A1)

    MkLabel({Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-20),
        BackgroundTransparency=1, Text="Configurable en Ajustes posteriormente",
        Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TM, ZIndex=92}, DP)

    local function SelDev(mode)
        ENV.QOS_DeviceMode = mode; ENV.QOS_Unlocked = true
        Tw(DS,TI.MED,{BackgroundTransparency=1}); task.wait(0.4); DS:Destroy(); onSelect(mode)
    end
    MB.MouseButton1Click:Connect(function() SelDev("mobile") end)
    PB.MouseButton1Click:Connect(function() SelDev("pc")     end)
    return DS
end

-- ═══════════════════════════════════════════════════════════════════════
-- §13  VENTANA PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════════
local MainWin, Sidebar, ContentArea, CurrTabFrame = nil,nil,nil,nil
local SbBtns = {}

local function ClearContent()
    if CurrTabFrame then CurrTabFrame:Destroy(); CurrTabFrame=nil end
end

local function SetActiveTab(name)
    for tname, btn in pairs(SbBtns) do
        local act = (tname == name)
        Tw(btn, TI.FAST, {BackgroundColor3=act and C.P3 or Color3.fromRGB(0,0,0)})
        Tw(btn, TI.FAST, {BackgroundTransparency=act and 0 or 1})
        local ind = btn:FindFirstChild("Ind")
        if ind then ind.Visible=act end
    end
end

local function CreateMainWindow()
    local mobile = IsMobile()
    local SBW = mobile and 185 or 210  -- sidebar width
    local HH  = mobile and 50 or 56    -- header height

    MainWin = MkFrame({
        Name="MainWin", Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1, ZIndex=10,
    }, ScreenGui)

    -- ── HEADER ────────────────────────────────────────────────────────
    local Header = MkFrame({
        Name="Header", Size=UDim2.new(1,0,0,HH),
        BackgroundColor3=C.BGH, ZIndex=12,
    }, MainWin)
    Stroke(1, C.BR0, Header)
    Grad(C.BGH, Color3.fromRGB(7,5,18), 90, Header)

    -- Logo
    local HL = MkLabel({
        Size=UDim2.new(0,32,0,32), Position=UDim2.new(0,12,0.5,-16),
        BackgroundTransparency=1, Text="⬡", Font=Enum.Font.GothamBold,
        TextSize=28, TextColor3=C.P1, ZIndex=13,
    }, Header)
    task.spawn(function()
        while HL and HL.Parent do
            Tw(HL,TI.SINE,{TextColor3=C.A1}); task.wait(1.5)
            Tw(HL,TI.SINE,{TextColor3=C.P1}); task.wait(1.5)
        end
    end)

    MkLabel({Size=UDim2.new(0,180,0,mobile and 18 or 20), Position=UDim2.new(0,48,0,mobile and 7 or 8),
        BackgroundTransparency=1, Text="QUANTUM OS  v3.1",
        Font=Enum.Font.GothamBold, TextSize=mobile and 13 or 15, TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, Header)

    MkLabel({Size=UDim2.new(0,180,0,14), Position=UDim2.new(0,48,0,mobile and 27 or 30),
        BackgroundTransparency=1, Text="Multi-Agent AI · Delta",
        Font=Enum.Font.Gotham, TextSize=mobile and 9 or 11, TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, Header)

    -- Game badge (centro)
    local GB = MkLabel({
        Size=UDim2.new(0,mobile and 160 or 200,0,mobile and 24 or 28),
        Position=UDim2.new(0.5,(mobile and -80 or -100),0.5,mobile and -12 or -14),
        BackgroundColor3=C.BG3, Text="🎮  "..GNAME:sub(1,16),
        Font=Enum.Font.Gotham, TextSize=mobile and 10 or 12, TextColor3=C.TS, ZIndex=13,
    }, Header); Corner(12, GB); Stroke(1, C.BR0, GB)

    -- Botones sistema
    local SF = MkFrame({
        Size=UDim2.new(0,mobile and 112 or 148,0,36),
        Position=UDim2.new(1,mobile and -118 or -158,0.5,-18),
        BackgroundTransparency=1, ZIndex=13,
    }, Header)

    local function SysBtn(icon, color, x)
        local b = MkBtn({
            Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,x,0.5,-15),
            BackgroundColor3=Color3.fromRGB(16,13,34), Text=icon,
            Font=Enum.Font.GothamBold, TextSize=12, TextColor3=color, ZIndex=14,
        }, SF); Corner(9, b)
        Hover(b, Color3.fromRGB(16,13,34), Color3.fromRGB(32,24,60)); return b
    end
    local WB  = SysBtn("⚡",C.TG, 0)
    local NB  = SysBtn("🔔",C.TY, 34)
    local MinB= SysBtn("—", C.TS, 68)
    local ClB = SysBtn("✕",C.TR, 102)

    ClB.MouseButton1Click:Connect(function()
        Tw(MainWin,TI.MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.35); ScreenGui:Destroy()
    end)
    local visible2 = true
    MinB.MouseButton1Click:Connect(function()
        visible2 = not visible2
        if visible2 then MainWin.Visible=true; Tw(MainWin,TI.MED,{Size=UDim2.fromScale(1,1)})
        else Tw(MainWin,TI.MED,{Size=UDim2.new(1,0,0,HH)}); task.delay(0.35,function() pcall(function() end) end) end
    end)

    -- ── SIDEBAR ───────────────────────────────────────────────────────
    Sidebar = MkFrame({
        Name="Sidebar", Size=UDim2.new(0,SBW,1,-HH), Position=UDim2.new(0,0,0,HH),
        BackgroundColor3=C.BGS, ZIndex=11,
    }, MainWin)
    Stroke(1, C.BR0, Sidebar)
    -- Línea lateral decorativa
    local SBAccent = MkFrame({
        Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
        BackgroundColor3=C.P1, BackgroundTransparency=0.7, ZIndex=12,
    }, Sidebar)

    -- Perfil
    local Prof = MkFrame({
        Size=UDim2.new(1,-14,0,mobile and 64 or 72),
        Position=UDim2.new(0,7,0,8),
        BackgroundColor3=C.BG3, ZIndex=12,
    }, Sidebar); Corner(14, Prof); Stroke(1, C.P3, Prof)
    Grad(C.BG3, Color3.fromRGB(18,8,44), 135, Prof)

    local AV = MkLabel({
        Size=UDim2.new(0,mobile and 40 or 44,0,mobile and 40 or 44),
        Position=UDim2.new(0,9,0.5,mobile and -20 or -22),
        BackgroundColor3=C.P3,
        Text=DNAME:sub(1,2):upper(),
        Font=Enum.Font.GothamBold, TextSize=mobile and 15 or 17, TextColor3=C.TW, ZIndex=13,
    }, Prof); Corner(22, AV); Stroke(2, C.P1, AV)

    MkLabel({Size=UDim2.new(1,-60,0,18), Position=UDim2.new(0,57,0,10),
        BackgroundTransparency=1, Text=DNAME,
        Font=Enum.Font.GothamBold, TextSize=mobile and 11 or 12, TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, Prof)
    MkLabel({Size=UDim2.new(1,-60,0,14), Position=UDim2.new(0,57,0,28),
        BackgroundTransparency=1, Text="@"..UNAME,
        Font=Enum.Font.Gotham, TextSize=mobile and 9 or 10, TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13}, Prof)

    local OB = MkLabel({
        Size=UDim2.new(0,68,0,14), Position=UDim2.new(0,57,0,44),
        BackgroundColor3=Color3.fromRGB(0,44,20), Text="● AI Online",
        Font=Enum.Font.Gotham, TextSize=9, TextColor3=C.TG, ZIndex=13,
    }, Prof); Corner(7, OB)

    -- Tabs scroll
    local SS = MkScroll({
        Size=UDim2.new(1,0,1,(mobile and -80 or -90)),
        Position=UDim2.new(0,0,0,(mobile and 80 or 88)),
        BackgroundTransparency=1, ScrollBarThickness=0, ZIndex=12,
    }, Sidebar)
    local SL2 = MkFrame({Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, ZIndex=12}, SS)
    ListL({Padding=UDim.new(0,1), SortOrder=Enum.SortOrder.LayoutOrder}, SL2)

    local TABS = {
        {name="START",            icon="⌂", order=1},
        {name="SCRIPT HUB",       icon="⚡", order=2},
        {name="SYSTEM SETTINGS",  icon="⚙", order=3},
        {name="TOOLBOX",          icon="🛠", order=4},
        {name="FILE MANAGER",     icon="📁", order=5},
        {name="PROCESSES & LOGS", icon="📊", order=6},
        {name="MEDIA CENTER",     icon="🎵", order=7},
        {name="COMMUNITY",        icon="👥", order=8},
        {name="QUANTUM ORACLE",   icon="🔮", order=9},
        {name="GAME BOOSTER",     icon="🚀", order=10},
        {name="SKIN CUSTOMIZER",  icon="🎨", order=11},
        {name="POWER",            icon="⏻",  order=12},
    }

    for _, tab in ipairs(TABS) do
        local Btn = MkBtn({
            Name=tab.name,
            Size=UDim2.new(1,-10,0,mobile and 38 or 42),
            BackgroundColor3=Color3.fromRGB(0,0,0),
            BackgroundTransparency=1, Text="", LayoutOrder=tab.order, ZIndex=13,
        }, SL2); Corner(9, Btn); Pad(0,6,0,6,Btn)

        local Ind = MkFrame({
            Name="Ind", Size=UDim2.new(0,3,0.55,0),
            Position=UDim2.new(0,0,0.225,0),
            BackgroundColor3=C.P1, Visible=false, ZIndex=14,
        }, Btn); Corner(2, Ind)

        MkLabel({Size=UDim2.new(0,26,1,0), Position=UDim2.new(0,10,0,0),
            BackgroundTransparency=1, Text=tab.icon,
            Font=Enum.Font.GothamBold, TextSize=mobile and 16 or 17,
            TextColor3=C.TS, ZIndex=14}, Btn)
        MkLabel({Size=UDim2.new(1,-42,1,0), Position=UDim2.new(0,40,0,0),
            BackgroundTransparency=1, Text=tab.name,
            Font=Enum.Font.GothamSemibold, TextSize=mobile and 10 or 11,
            TextColor3=C.TS, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14}, Btn)

        SbBtns[tab.name] = Btn
        Btn.MouseButton1Click:Connect(function()
            ClearContent(); SetActiveTab(tab.name); ENV.QOS_ActiveTab=tab.name
            local fnKey="QOS_Tab_"..tab.name:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
            pcall(function() _G[fnKey]() end)
        end)
        Hover(Btn, Color3.fromRGB(0,0,0), C.BG4)
    end

    local SLL = SL2:FindFirstChildWhichIsA("UIListLayout")
    SLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        SL2.Size = UDim2.new(1,0,0,SLL.AbsoluteContentSize.Y+8)
    end)

    -- ── CONTENT AREA ─────────────────────────────────────────────────
    ContentArea = MkFrame({
        Name="ContentArea",
        Size=UDim2.new(1,-SBW,1,-HH),
        Position=UDim2.new(0,SBW,0,HH),
        BackgroundColor3=C.BG1, ZIndex=11,
    }, MainWin)

    MainWin.Size = UDim2.new(0,0,0,0); MainWin.Position=UDim2.new(0.5,0,0.5,0)
    Tw(MainWin, TI.BOUNCE, {Size=UDim2.fromScale(1,1), Position=UDim2.fromScale(0,0)})
end

-- ═══════════════════════════════════════════════════════════════════════
-- §14  COMPONENTES REUTILIZABLES
-- ═══════════════════════════════════════════════════════════════════════
local function MkToggle(parent, label, def, onChange)
    local Row = MkFrame({Size=UDim2.new(1,0,0,44), BackgroundColor3=C.BG3, ZIndex=20}, parent)
    Corner(10, Row)
    MkLabel({Size=UDim2.new(1,-72,1,0), Position=UDim2.new(0,14,0,0),
        BackgroundTransparency=1, Text=label, Font=Enum.Font.Gotham,
        TextSize=13, TextColor3=C.TW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21}, Row)
    local Tr = MkFrame({Size=UDim2.new(0,46,0,24), Position=UDim2.new(1,-58,0.5,-12),
        BackgroundColor3=def and C.TON or C.TOFF, ZIndex=21}, Row); Corner(12, Tr)
    local Th = MkFrame({Size=UDim2.new(0,18,0,18),
        Position=def and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9),
        BackgroundColor3=Color3.new(1,1,1), ZIndex=22}, Tr); Corner(9, Th)
    local state = def
    local TB = MkBtn({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=23},Tr)
    TB.MouseButton1Click:Connect(function()
        state = not state
        Tw(Tr,TI.FAST,{BackgroundColor3=state and C.TON or C.TOFF})
        Tw(Th,TI.FAST,{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)})
        if onChange then onChange(state) end
    end)
    return Row
end

local function MkSlider(parent, label, minV, maxV, defV, suf, onChange)
    local Row = MkFrame({Size=UDim2.new(1,0,0,62), BackgroundColor3=C.BG3, ZIndex=20}, parent)
    Corner(10, Row)
    MkLabel({Size=UDim2.new(1,-64,0,22), Position=UDim2.new(0,14,0,7),
        BackgroundTransparency=1, Text=label, Font=Enum.Font.Gotham,
        TextSize=13, TextColor3=C.TW, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=21}, Row)
    local VL = MkLabel({Size=UDim2.new(0,54,0,22), Position=UDim2.new(1,-64,0,7),
        BackgroundTransparency=1, Text=defV..(suf or ""),
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=21}, Row)
    local Tr = MkFrame({Size=UDim2.new(1,-28,0,5), Position=UDim2.new(0,14,0,42),
        BackgroundColor3=C.SBG, ZIndex=21}, Row); Corner(3,Tr)
    local ratio = (defV-minV)/(maxV-minV)
    local Fi = MkFrame({Size=UDim2.new(ratio,0,1,0), BackgroundColor3=C.SFG, ZIndex=22}, Tr)
    Corner(3,Fi); Grad(C.P1,C.A1,0,Fi)
    local Kn = MkFrame({Size=UDim2.new(0,14,0,14), Position=UDim2.new(ratio,-7,0.5,-7),
        BackgroundColor3=Color3.new(1,1,1), ZIndex=23}, Tr); Corner(7,Kn); Stroke(2,C.P1,Kn)
    local drag=false
    local function Upd(x)
        local t=math.clamp((x-Tr.AbsolutePosition.X)/Tr.AbsoluteSize.X,0,1)
        local v=math.floor(minV+t*(maxV-minV))
        Tw(Fi,TI.SNAP,{Size=UDim2.new(t,0,1,0)}); Tw(Kn,TI.SNAP,{Position=UDim2.new(t,-7,0.5,-7)})
        VL.Text=v..(suf or ""); if onChange then onChange(v) end
    end
    Tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; Upd(i.Position.X)
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then Upd(i.Position.X) end
    end))
    Track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end))
    return Row
end

local function SecHeader(parent, title, sub)
    local H = MkFrame({Size=UDim2.new(1,0,0,IsMobile() and 54 or 62), BackgroundColor3=C.BGH, ZIndex=19}, parent)
    Stroke(1, C.BR0, H)
    Grad(C.BGH, Color3.fromRGB(7,5,18), 90, H)
    local AL = MkFrame({
        Size=UDim2.new(0,3,0,IsMobile() and 32 or 38),
        Position=UDim2.new(0,8,0,IsMobile() and 11 or 12),
        BackgroundColor3=C.P1, ZIndex=20,
    }, H); Corner(2,AL)
    Grad(C.P1, C.A1, 90, AL)
    MkLabel({Size=UDim2.new(1,-24,0,26), Position=UDim2.new(0,20,0,IsMobile() and 6 or 8),
        BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamBold,
        TextSize=IsMobile() and 15 or 18, TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=20}, H)
    if sub then
        MkLabel({Size=UDim2.new(1,-24,0,14), Position=UDim2.new(0,20,0,IsMobile() and 34 or 38),
            BackgroundTransparency=1, Text=sub, Font=Enum.Font.Gotham,
            TextSize=10, TextColor3=C.TM, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=20}, H)
    end
    return H
end

-- ═══════════════════════════════════════════════════════════════════════
-- §15  TAB: START
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_START"] = function()
    local Tab = MkFrame({Name="T_START", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=15}, ContentArea)
    CurrTabFrame = Tab
    local Sc = MkScroll({Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ScrollBarThickness=3, ZIndex=15}, Tab)
    local Li = MkFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=15}, Sc)
    ListL({Padding=UDim.new(0,0)}, Li); Pad(0,0,24,0,Li)
    SecHeader(Li, "START  ⌂", "Panel de inicio · Quantum OS v3.1")

    -- Stats cards
    local SR = MkFrame({Size=UDim2.new(1,0,0,88), BackgroundTransparency=1, ZIndex=15}, Li)
    local SG = MkFrame({Size=UDim2.new(1,-28,1,-12), Position=UDim2.new(0,14,0,6), BackgroundTransparency=1, ZIndex=15}, SR)
    GridL({CellSize=UDim2.new(0.25,-4,1,-4), CellPadding=UDim2.new(0,4,0,4)}, SG)

    for _, s in ipairs({
        {label="Jugador",   val=DNAME:sub(1,10), icon="👤", c=C.P2},
        {label="Juego",     val=GNAME:sub(1,12), icon="🎮", c=C.A1},
        {label="AI Status", val="Online",         icon="🤖", c=C.TG},
        {label="Agentes",   val="5 activos",      icon="⬡",  c=C.A4},
    }) do
        local Card=MkFrame({BackgroundColor3=C.BG3,ZIndex=16},SG); Corner(12,Card)
        Stroke(1,C.BR0,Card); Grad(C.BG3,Color3.fromRGB(16,8,36),135,Card)
        MkLabel({Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,0,8),BackgroundTransparency=1,Text=s.icon,TextSize=18,ZIndex=17},Card)
        MkLabel({Size=UDim2.new(1,-6,0,18),Position=UDim2.new(0,3,0,32),BackgroundTransparency=1,
            Text=s.val,Font=Enum.Font.GothamBold,TextSize=11,TextColor3=s.c,ZIndex=17},Card)
        MkLabel({Size=UDim2.new(1,-6,0,13),Position=UDim2.new(0,3,0,51),BackgroundTransparency=1,
            Text=s.label,Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TM,ZIndex=17},Card)
    end

    -- Agentes
    MkLabel({Size=UDim2.new(1,-32,0,20), BackgroundTransparency=1, Text="AGENTES ACTIVOS",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=15}, Li)

    local AL2 = MkFrame({Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1, ZIndex=15}, Li)
    ListL({Padding=UDim.new(0,3)}, AL2); Pad(0,14,0,14,AL2)

    for _, ag in ipairs({
        {icon="⬡",name="Orquestador",   model="llama-3.3-70b", desc="Dirige el flujo multi-agente"},
        {icon="🎮",name="Game Analyst",  model="nemotron-120b", desc="Análisis del juego actual"},
        {icon="💻",name="Code Expert",   model="qwen3-coder",   desc="Scripts y código Lua"},
        {icon="⚔", name="Strategy Agent",model="deepseek-v4",  desc="Estrategias y builds"},
        {icon="🎨",name="Creative Agent",model="gemma-4-31b",   desc="Ideas y personalización"},
    }) do
        local AC=MkFrame({Size=UDim2.new(1,0,0,IsMobile() and 46 or 52),BackgroundColor3=C.BG2,ZIndex=16},AL2)
        Corner(10,AC); Stroke(1,C.BR0,AC)
        Grad(C.BG2,Color3.fromRGB(14,8,34),135,AC)
        MkLabel({Size=UDim2.new(0,34,0,34),Position=UDim2.new(0,8,0.5,-17),
            BackgroundColor3=C.P3,BackgroundTransparency=0.4,Text=ag.icon,TextSize=18,ZIndex=17},AC)
        MkLabel({Size=UDim2.new(1,-160,0,18),Position=UDim2.new(0,50,0,8),
            BackgroundTransparency=1,Text=ag.name,Font=Enum.Font.GothamBold,
            TextSize=12,TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},AC)
        MkLabel({Size=UDim2.new(1,-160,0,14),Position=UDim2.new(0,50,0,26),
            BackgroundTransparency=1,Text=ag.desc,Font=Enum.Font.Gotham,
            TextSize=10,TextColor3=C.TM,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},AC)
        local Sb=MkLabel({Size=UDim2.new(0,86,0,20),Position=UDim2.new(1,-96,0.5,-10),
            BackgroundColor3=Color3.fromRGB(0,36,18),Text="● "..ag.model,
            Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TG,ZIndex=17},AC); Corner(9,Sb)
    end

    local LL=Li:FindFirstChildWhichIsA("UIListLayout")
    if LL then LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sc.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+24)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════
-- §16  TAB: QUANTUM ORACLE (Chat Multi-Agente)
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_QUANTUM_ORACLE"] = function()
    local Tab = MkFrame({Name="T_ORACLE",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab
    local mobile=IsMobile()
    SecHeader(Tab,"QUANTUM ORACLE  🔮","Multi-Agent AI · "..GNAME)

    local HH2 = mobile and 54 or 62

    -- Orb info bar
    local OBar = MkFrame({
        Size=UDim2.new(1,-24,0,mobile and 90 or 104),
        Position=UDim2.new(0,12,0,HH2+6),
        BackgroundColor3=C.BG4, ZIndex=16,
    }, Tab); Corner(14,OBar)
    Stroke(1,C.BR1,OBar); Grad(C.BG4,Color3.fromRGB(36,0,72),135,OBar)

    local Orb=MkLabel({
        Size=UDim2.new(0,mobile and 60 or 70,0,mobile and 60 or 70),
        Position=UDim2.new(0,mobile and 12 or 16,0.5,mobile and -30 or -35),
        BackgroundColor3=C.P3,Text="🔮",TextSize=mobile and 28 or 34,ZIndex=17,
    },OBar); Corner(35,Orb); Stroke(2,C.P1,Orb)
    task.spawn(function()
        while Orb and Orb.Parent do
            Tw(Orb,TI.SINE,{BackgroundColor3=C.P2}); task.wait(1.2)
            Tw(Orb,TI.SINE,{BackgroundColor3=C.P3}); task.wait(1.2)
        end
    end)

    local orbX = (mobile and 60 or 70) + (mobile and 22 or 28)
    MkLabel({Size=UDim2.new(1,-orbX-12,0,22),Position=UDim2.new(0,orbX,0,mobile and 12 or 14),
        BackgroundTransparency=1,Text="QUANTUM ORACLE · Multi-Agent AI",
        Font=Enum.Font.GothamBold,TextSize=mobile and 13 or 15,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},OBar)
    local AgBadge=MkLabel({Size=UDim2.new(1,-orbX-12,0,16),Position=UDim2.new(0,orbX,0,mobile and 36 or 40),
        BackgroundTransparency=1,Text="⬡ Orch: llama-3.3-70b · 5 Agentes",
        Font=Enum.Font.Gotham,TextSize=mobile and 10 or 11,TextColor3=C.A1,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},OBar)
    local AgStatus=MkLabel({Size=UDim2.new(1,-orbX-12,0,14),Position=UDim2.new(0,orbX,0,mobile and 56 or 62),
        BackgroundTransparency=1,Text="En espera · '"..GNAME.."' detectado",
        Font=Enum.Font.Gotham,TextSize=mobile and 9 or 10,TextColor3=C.TS,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},OBar)

    -- Sugerencias
    local SugY = HH2 + (mobile and 102 or 118)
    local SugF=MkFrame({Size=UDim2.new(1,-24,0,mobile and 26 or 30),Position=UDim2.new(0,12,0,SugY),
        BackgroundTransparency=1,ZIndex=16},Tab)
    ListL({FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,5)},SugF)

    -- Chat scroll
    local chatY = SugY + (mobile and 32 or 38)
    local chatH2 = mobile and 50 or 58
    local ChatSc=MkScroll({
        Size=UDim2.new(1,-24,1,-(chatY+chatH2+12)),
        Position=UDim2.new(0,12,0,chatY),
        BackgroundColor3=Color3.fromRGB(4,4,12),ScrollBarThickness=3,ZIndex=15,
    },Tab); Corner(12,ChatSc); Stroke(1,C.BR0,ChatSc)

    local ChatLi=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},ChatSc)
    ListL({Padding=UDim.new(0,7)},ChatLi); Pad(8,8,8,8,ChatLi)

    local function AddMsg(txt, isUser, meta)
        local bubble=MkFrame({
            Size=UDim2.new(0.87,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            Position=isUser and UDim2.new(0.13,0,0,0) or UDim2.new(0,0,0,0),
            BackgroundColor3=isUser and C.P3 or (meta and meta.color and Color3.fromRGB(
                math.floor(meta.color.R*255*0.15), math.floor(meta.color.G*255*0.15), math.floor(meta.color.B*255*0.15)
            ) or C.BG3),
            BackgroundTransparency=isUser and 0.1 or 0.15, ZIndex=16,
        },ChatLi); Corner(12,bubble); Pad(9,12,9,12,bubble)
        if not isUser and meta then
            local ab=MkLabel({Size=UDim2.new(1,0,0,15),BackgroundTransparency=1,
                Text=meta.icon.." "..meta.name,Font=Enum.Font.GothamBold,
                TextSize=9,TextColor3=meta.color,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},bubble)
        end
        local yy=(not isUser and meta) and 18 or 0
        MkLabel({Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,yy),
            AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,
            Text=txt,Font=Enum.Font.Gotham,TextSize=mobile and 11 or 12,TextColor3=C.TW,
            TextWrapped=true,TextXAlignment=isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
            ZIndex=17},bubble)
        task.wait(0.04)
        ChatSc.CanvasSize=UDim2.new(0,0,0,ChatLi.AbsoluteContentSize.Y+16)
        ChatSc.CanvasPosition=Vector2.new(0,ChatLi.AbsoluteContentSize.Y)
    end

    local ThinkB=nil
    local function ShowThink(txt)
        if ThinkB then pcall(function() ThinkB:Destroy() end) end
        ThinkB=MkFrame({Size=UDim2.new(0.45,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundColor3=C.BG3,BackgroundTransparency=0.3,ZIndex=16},ChatLi)
        Corner(12,ThinkB); Pad(7,10,7,10,ThinkB)
        MkLabel({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            BackgroundTransparency=1,Text="◌ "..txt,Font=Enum.Font.Gotham,
            TextSize=10,TextColor3=C.TM,TextWrapped=true,ZIndex=17},ThinkB)
        task.wait(0.04)
        ChatSc.CanvasSize=UDim2.new(0,0,0,ChatLi.AbsoluteContentSize.Y+16)
        ChatSc.CanvasPosition=Vector2.new(0,ChatLi.AbsoluteContentSize.Y)
    end
    local function HideThink() if ThinkB then pcall(function() ThinkB:Destroy() end); ThinkB=nil end end

    -- Mensaje inicial
    AddMsg("🔮 Hola, "..DNAME.."! Soy el Quantum Oracle con sistema Multi-Agent AI.\n\nJuego detectado: '"..GNAME.."'\nEl Orquestador dirigirá tu consulta al agente ideal:\n🎮 Game · 💻 Code · ⚔ Strategy · 🎨 Creative · ⚡ Fast\n\n¿En qué te ayudo?", false, {icon="🔮",name="Quantum Oracle",color=C.P2})

    -- Input
    local InputF=MkFrame({
        Size=UDim2.new(1,-24,0,mobile and 46 or 50),
        Position=UDim2.new(0,12,1,-(mobile and 56 or 62)),
        BackgroundColor3=C.BG3,ZIndex=16,
    },Tab); Corner(14,InputF); Stroke(1,C.BR0,InputF)

    local CI2=MkBox({
        Size=UDim2.new(1,-56,1,0),Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1,Text="",PlaceholderText="Pregunta al Oracle...",
        Font=Enum.Font.Gotham,TextSize=mobile and 12 or 13,TextColor3=C.TW,
        PlaceholderColor3=C.TM,ClearTextOnFocus=false,ZIndex=17,
    },InputF)
    local SndBtn=MkBtn({
        Size=UDim2.new(0,40,0,34),Position=UDim2.new(1,-46,0.5,-17),
        BackgroundColor3=C.P1,Text="▶",Font=Enum.Font.GothamBold,
        TextSize=15,TextColor3=Color3.new(1,1,1),ZIndex=17,
    },InputF); Corner(10,SndBtn)

    -- Sugerencias (rellena después de crear el chat)
    local suggs={"¿Mejores scripts?","Script anti-ban","¿Cómo farmear?","Fix error Lua","Estrategia rápida"}
    for _, sg in ipairs(suggs) do
        local SB2=MkBtn({
            Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=C.BG3,Text=sg,Font=Enum.Font.Gotham,
            TextSize=mobile and 9 or 10,TextColor3=C.A1,ZIndex=17,
        },SugF); Corner(10,SB2); Pad(0,8,0,8,SB2); Stroke(1,C.A2,SB2)
        SB2.MouseButton1Click:Connect(function() CI2.Text=sg end)
    end

    local waiting=false
    local function DoSend()
        if waiting then return end
        local msg=CI2.Text:match("^%s*(.-)%s*$")
        if msg=="" then return end
        CI2.Text=""; waiting=true; SndBtn.Text="◌"
        AddMsg(msg,true)
        OracleQuery(msg,
            function(t) ShowThink(t); AgStatus.Text="⬡ "..t end,
            function(k,m) ShowThink(m.icon.." "..m.name.." respondiendo..."); AgStatus.Text=m.icon.." Activo: "..m.name; AgBadge.Text=m.icon.." Usando: "..m.name.." · OpenRouter" end,
            function(r,m) HideThink(); AddMsg(r,false,m); waiting=false; SndBtn.Text="▶"; AgStatus.Text="En espera"; AgBadge.Text="⬡ Orch: llama-3.3-70b · 5 Agentes" end,
            function(e) HideThink(); AddMsg("❌ Error: "..tostring(e).."\nVerifica tu API Key en Ajustes.",false,{icon="❌",name="Sistema",color=C.TR}); waiting=false; SndBtn.Text="▶" end
        )
    end

    SndBtn.MouseButton1Click:Connect(DoSend)
    CI2.FocusLost:Connect(function(e) if e then DoSend() end end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- §17  TAB: SCRIPT HUB
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_SCRIPT_HUB"] = function()
    local Tab=MkFrame({Name="T_HUB",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab
    local mobile=IsMobile()
    SecHeader(Tab,"SCRIPT HUB  ⚡","Scripts verificados · "..GNAME)
    local HH3=mobile and 54 or 62

    local SRow=MkFrame({Size=UDim2.new(1,-24,0,38),Position=UDim2.new(0,12,0,HH3+8),
        BackgroundColor3=C.BG3,ZIndex=15},Tab); Corner(12,SRow); Stroke(1,C.BR0,SRow)
    MkBox({Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,Text="",PlaceholderText="🔍 Buscar scripts...",
        Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.TW,PlaceholderColor3=C.TM,ZIndex=16},SRow)

    local SSc=MkScroll({Size=UDim2.new(1,-24,1,-(HH3+58)),Position=UDim2.new(0,12,0,HH3+54),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local SLi=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},SSc)
    ListL({Padding=UDim.new(0,7)},SLi)

    for _, s in ipairs({
        {t="Auto Farm v5.2",       a="LXNDXN",     v=true,  sc="print('Auto Farm activado')"},
        {t="ESP Pro · All Players",a="QuantumDev",  v=true,  sc="print('ESP activo')"},
        {t="Infinite Jump",        a="DeltaFarm",   v=false, sc="print('InfJump activo')"},
        {t="Speed Hack x10",       a="LXNDXN",      v=true,  sc="print('Speed x10')"},
        {t="God Mode Bypass",      a="NullSec",      v=false, sc="print('God Mode')"},
        {t="Auto Collect Items",   a="QuantumDev",   v=true,  sc="print('AutoCollect')"},
    }) do
        local Card=MkFrame({Size=UDim2.new(1,0,0,mobile and 72 or 80),BackgroundColor3=C.BG2,ZIndex=16},SLi)
        Corner(14,Card); Stroke(1,C.BR0,Card)
        Grad(C.BG2,Color3.fromRGB(12,8,28),135,Card)

        local Th=MkFrame({Size=UDim2.new(0,mobile and 46 or 52,0,mobile and 46 or 52),
            Position=UDim2.new(0,10,0.5,mobile and -23 or -26),BackgroundColor3=C.P3,ZIndex=17},Card)
        Corner(12,Th)
        MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="⚡",
            Font=Enum.Font.GothamBold,TextSize=22,TextColor3=C.TW,ZIndex=18},Th)

        local lx=mobile and 66 or 72
        MkLabel({Size=UDim2.new(1,-(lx+180),0,20),Position=UDim2.new(0,lx,0,mobile and 10 or 12),
            BackgroundTransparency=1,Text=s.t,Font=Enum.Font.GothamBold,
            TextSize=mobile and 12 or 13,TextColor3=C.TW,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Card)
        MkLabel({Size=UDim2.new(1,-(lx+180),0,14),Position=UDim2.new(0,lx,0,mobile and 30 or 34),
            BackgroundTransparency=1,Text="by "..s.a,Font=Enum.Font.Gotham,
            TextSize=10,TextColor3=C.TS,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},Card)
        if s.v then
            local VB=MkLabel({Size=UDim2.new(0,100,0,14),Position=UDim2.new(0,lx,0,mobile and 48 or 54),
                BackgroundColor3=Color3.fromRGB(0,40,18),Text="✓ Verificado Delta",
                Font=Enum.Font.Gotham,TextSize=9,TextColor3=C.TG,ZIndex=18},Card); Corner(7,VB)
        end

        local ExB=MkBtn({Size=UDim2.new(0,80,0,mobile and 26 or 28),Position=UDim2.new(1,-164,0.5,mobile and -13 or -14),
            BackgroundColor3=C.P1,Text="▶ RUN",Font=Enum.Font.GothamBold,
            TextSize=10,TextColor3=Color3.new(1,1,1),ZIndex=17},Card); Corner(8,ExB)
        Hover(ExB,C.P1,C.P2)
        ExB.MouseButton1Click:Connect(function()
            pcall(function() loadstring(s.sc)() end)
            PushNotif("Script Ejecutado",s.t.." activado.","SUCCESS",3)
        end)

        local SvB=MkBtn({Size=UDim2.new(0,62,0,mobile and 26 or 28),Position=UDim2.new(1,-76,0.5,mobile and -13 or -14),
            BackgroundColor3=C.BG4,Text="💾 SAVE",Font=Enum.Font.Gotham,
            TextSize=10,TextColor3=C.TS,ZIndex=17},Card); Corner(8,SvB)

        local SLL2=SLi:FindFirstChildWhichIsA("UIListLayout")
        if SLL2 then SLL2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            SSc.CanvasSize=UDim2.new(0,0,0,SLL2.AbsoluteContentSize.Y+16)
        end) end
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- §18  TAB: SYSTEM SETTINGS
-- ═══════════════════════════════════════════════════════════════════════
_G["QOS_Tab_SYSTEM_SETTINGS"] = function()
    local Tab=MkFrame({Name="T_SET",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab
    local mobile=IsMobile(); local HH3=mobile and 54 or 62
    SecHeader(Tab,"SYSTEM SETTINGS  ⚙","Configuración · AI · Executor")
    local Sc=MkScroll({Size=UDim2.new(1,0,1,-HH3),Position=UDim2.new(0,0,0,HH3),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local SLi=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},Sc)
    ListL({Padding=UDim.new(0,3)},SLi); Pad(10,14,24,14,SLi)

    -- API Key card
    local KC=MkFrame({Size=UDim2.new(1,0,0,64),BackgroundColor3=C.BG3,ZIndex=16},SLi)
    Corner(14,KC); Stroke(1,C.BR0,KC)
    Grad(C.BG3,Color3.fromRGB(16,4,40),135,KC)
    MkLabel({Size=UDim2.new(1,-120,0,20),Position=UDim2.new(0,14,0,10),
        BackgroundTransparency=1,Text="OpenRouter API Key",
        Font=Enum.Font.GothamBold,TextSize=13,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},KC)
    local km=ENV.QOS_APIKey and ("sk-or-..."..ENV.QOS_APIKey:sub(-6)) or "No configurada"
    MkLabel({Size=UDim2.new(1,-120,0,16),Position=UDim2.new(0,14,0,32),
        BackgroundTransparency=1,Text=km,Font=Enum.Font.Code,
        TextSize=10,TextColor3=C.A1,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},KC)
    local KS=MkLabel({Size=UDim2.new(0,80,0,20),Position=UDim2.new(1,-92,0.5,-10),
        BackgroundColor3=Color3.fromRGB(0,40,18),Text="● Conectada",
        Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.TG,ZIndex=17},KC); Corner(9,KS)

    for _, s in ipairs({
        {"Notificaciones Toast",true,nil},{"Watermark OS",true,nil},
        {"Panel lateral rápido",true,nil},{"Stats HUD en overlay",false,nil},
        {"Animaciones partículas",true,nil},{"Anti-detección",true,nil},
    }) do MkToggle(SLi,s[1],s[2],s[3]) end

    MkLabel({Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,
        Text="MODO: "..(ENV.QOS_DeviceMode or "?"):upper(),
        Font=Enum.Font.GothamBold,TextSize=11,TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=16},SLi)

    local LL2=SLi:FindFirstChildWhichIsA("UIListLayout")
    if LL2 then LL2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sc.CanvasSize=UDim2.new(0,0,0,LL2.AbsoluteContentSize.Y+24)
    end) end
end

-- ═══════════════════════════════════════════════════════════════════════
-- §19  TABS STUB + GAME BOOSTER + SKIN CUSTOMIZER + POWER
-- ═══════════════════════════════════════════════════════════════════════
local function StubTab(name, icon, sub)
    return function()
        local Tab=MkFrame({Name="T_"..name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
        CurrTabFrame=Tab; SecHeader(Tab,name.."  "..icon,sub)
        local PC=MkFrame({Size=UDim2.new(1,-24,0,100),Position=UDim2.new(0,12,0,(IsMobile() and 54 or 62)+10),
            BackgroundColor3=C.BG3,ZIndex=15},Tab); Corner(14,PC); Stroke(1,C.BR0,PC)
        MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=icon.."\n"..name,
            Font=Enum.Font.GothamBold,TextSize=18,TextColor3=C.TW,ZIndex=16},PC)
    end
end

_G["QOS_Tab_TOOLBOX"]           = StubTab("TOOLBOX","🛠","Herramientas del executor")
_G["QOS_Tab_FILE_MANAGER"]      = StubTab("FILE MANAGER","📁","Gestor de scripts")
_G["QOS_Tab_PROCESSES___LOGS"]  = StubTab("PROCESSES & LOGS","📊","Monitor en tiempo real")
_G["QOS_Tab_MEDIA_CENTER"]      = StubTab("MEDIA CENTER","🎵","Reproductor y multimedia")
_G["QOS_Tab_COMMUNITY"]         = StubTab("COMMUNITY","👥","Discord · Foro · Top Contributors")

_G["QOS_Tab_GAME_BOOSTER"] = function()
    local Tab=MkFrame({Name="T_BOOST",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab; local mobile=IsMobile(); local HH3=mobile and 54 or 62
    SecHeader(Tab,"GAME BOOSTER  🚀","Optimización FPS · "..GNAME)
    local Sc=MkScroll({Size=UDim2.new(1,0,1,-HH3),Position=UDim2.new(0,0,0,HH3),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local Li=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},Sc)
    ListL({Padding=UDim.new(0,4)},Li); Pad(10,14,24,14,Li)

    local BC=MkFrame({Size=UDim2.new(1,0,0,mobile and 82 or 94),BackgroundColor3=C.BG4,ZIndex=16},Li)
    Corner(16,BC); Grad(Color3.fromRGB(8,4,26),Color3.fromRGB(52,0,88),135,BC); Stroke(2,C.P1,BC)
    Pad(14,14,14,14,BC)
    MkLabel({Size=UDim2.new(1,-106,0,22),BackgroundTransparency=1,Text="🚀 QUANTUM BOOST MODE",
        Font=Enum.Font.GothamBold,TextSize=mobile and 14 or 16,TextColor3=C.TW,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},BC)
    MkLabel({Size=UDim2.new(1,-106,0,28),Position=UDim2.new(0,0,0,26),BackgroundTransparency=1,
        Text="Elimina partículas, texturas y reduce render para máximo FPS.",
        Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TS,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},BC)
    local BB=MkBtn({Size=UDim2.new(0,82,0,36),Position=UDim2.new(1,-94,0.5,-18),
        BackgroundColor3=C.TON,Text="ACTIVAR",Font=Enum.Font.GothamBold,
        TextSize=12,TextColor3=Color3.new(1,1,1),ZIndex=17},BC); Corner(10,BB)
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
            PushNotif("Boost","Modo boost activado · FPS optimizado.","SUCCESS",3)
        end
    end)

    MkToggle(Li,"Desactivar ParticleEmitters",false,function(s)
        for _,v in pairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") then v.Enabled=not s end end
    end)
    MkToggle(Li,"Desactivar Sombras",false,function(s)
        pcall(function() game:GetService("Lighting").GlobalShadows=not s end)
    end)
    MkToggle(Li,"Anti-Lag Mode",false,nil)
    MkSlider(Li,"Simulation Throttle",1,100,100,"%",nil)

    local LL3=Li:FindFirstChildWhichIsA("UIListLayout")
    if LL3 then LL3:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sc.CanvasSize=UDim2.new(0,0,0,LL3.AbsoluteContentSize.Y+24)
    end) end
end

_G["QOS_Tab_SKIN_CUSTOMIZER"] = function()
    local Tab=MkFrame({Name="T_SKIN",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab; local mobile=IsMobile(); local HH3=mobile and 54 or 62
    SecHeader(Tab,"SKIN CUSTOMIZER  🎨","Personaliza el OS")
    local Sc=MkScroll({Size=UDim2.new(1,0,1,-HH3),Position=UDim2.new(0,0,0,HH3),
        BackgroundTransparency=1,ScrollBarThickness=3,ZIndex=15},Tab)
    local Li=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},Sc)
    ListL({Padding=UDim.new(0,4)},Li); Pad(10,14,24,14,Li)
    MkSlider(Li,"Rojo primario",0,255,148,"",nil)
    MkSlider(Li,"Verde primario",0,255,28,"",nil)
    MkSlider(Li,"Azul primario",0,255,230,"",nil)
    MkSlider(Li,"Transparencia panel",0,80,28,"%",nil)
    MkToggle(Li,"Efecto Glassmorphic",true,nil)
    MkToggle(Li,"Animaciones partículas",true,nil)
    local LL=Li:FindFirstChildWhichIsA("UIListLayout")
    if LL then LL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Sc.CanvasSize=UDim2.new(0,0,0,LL.AbsoluteContentSize.Y+24)
    end) end
end

_G["QOS_Tab_POWER"] = function()
    local Tab=MkFrame({Name="T_PWR",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=15},ContentArea)
    CurrTabFrame=Tab; local mobile=IsMobile(); local HH3=mobile and 54 or 62
    SecHeader(Tab,"POWER  ⏻","Opciones de sesión")
    local Sc=MkScroll({Size=UDim2.new(1,-24,1,-(HH3+10)),Position=UDim2.new(0,12,0,HH3+6),
        BackgroundTransparency=1,ScrollBarThickness=2,ZIndex=15},Tab)
    local Li=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=15},Sc)
    ListL({Padding=UDim.new(0,8)},Li); Pad(10,0,24,0,Li)
    for _,b in ipairs({
        {l="Reiniciar Quantum OS",  i="🔄",c=C.TY},
        {l="Cerrar Quantum OS",     i="✕",c=C.TR},
        {l="Desconectar del Juego", i="🚪",c=C.TR},
        {l="Limpiar Conexiones",    i="♻",c=C.A1},
    }) do
        local PC2=MkFrame({Size=UDim2.new(1,0,0,mobile and 64 or 72),BackgroundColor3=C.BG3,ZIndex=16},Li)
        Corner(14,PC2); Stroke(1,C.BR0,PC2)
        MkLabel({Size=UDim2.new(0,40,0,40),Position=UDim2.new(0,12,0.5,-20),
            BackgroundColor3=Color3.fromRGB(36,8,8),Text=b.i,TextSize=18,ZIndex=17},PC2)
        MkLabel({Size=UDim2.new(1,-150,0,20),Position=UDim2.new(0,60,0,12),
            BackgroundTransparency=1,Text=b.l,Font=Enum.Font.GothamBold,
            TextSize=mobile and 12 or 13,TextColor3=b.c,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=17},PC2)
        local AB=MkBtn({Size=UDim2.new(0,72,0,mobile and 26 or 28),Position=UDim2.new(1,-84,0.5,-13),
            BackgroundColor3=Color3.fromRGB(46,8,8),Text="EJECUTAR",
            Font=Enum.Font.GothamBold,TextSize=10,TextColor3=b.c,ZIndex=17},PC2)
        Corner(8,AB); Stroke(1,b.c,AB)
        AB.MouseButton1Click:Connect(function()
            if b.l:find("Reiniciar") then ScreenGui:Destroy(); task.wait(0.5)
            elseif b.l:find("Cerrar") then Tw(MainWin,TI.MED,{Size=UDim2.new(0,0,0,0)}); task.wait(0.4); ScreenGui:Destroy()
            elseif b.l:find("Desconectar") then pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId) end)
            elseif b.l:find("Conexiones") then
                for _,c in pairs(ENV.QOS_Connections) do pcall(function() c:Disconnect() end) end
                ENV.QOS_Connections={}; PushNotif("Sistema","Conexiones limpiadas.","SUCCESS",2)
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- §20  MÓDULOS DE GAMEPLAY
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
        local spd=70
        Track(RunService.RenderStepped:Connect(function()
            if not FlyMod.Active then return end
            local cam=workspace.CurrentCamera; local dir=Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir=dir+Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir=dir+Vector3.new(0,-1,0) end
            bv.Velocity=dir.Magnitude>0 and dir.Unit*spd or Vector3.new()
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

local AFKMod={Active=false}
AFKMod.On=function() AFKMod.Active=true; task.spawn(function()
    while AFKMod.Active do pcall(function() LP:Move(Vector3.new(0,0,1),true) end); task.wait(58)
    pcall(function() LP:Move(Vector3.new(0,0,-1),true) end); task.wait(2) end
end) end
AFKMod.Off=function() AFKMod.Active=false end

local GodMod={Active=false}
GodMod.On=function() GodMod.Active=true; task.spawn(function()
    while GodMod.Active and Humanoid and Humanoid.Parent do
        pcall(function() Humanoid.Health=Humanoid.MaxHealth end); task.wait(0.1)
    end
end) end
GodMod.Off=function() GodMod.Active=false end

local RadarMod={Active=false}
RadarMod.On=function() RadarMod.Active=true; PushNotif("Radar","Radar activado.","SUCCESS",3) end
RadarMod.Off=function() RadarMod.Active=false; PushNotif("Radar","Radar desactivado.","INFO",2) end

local MovMod={}
MovMod.Speed=function(v) pcall(function() Humanoid.WalkSpeed=v end) end
MovMod.Jump=function(v)  pcall(function() Humanoid.JumpPower=v end) end

-- ═══════════════════════════════════════════════════════════════════════
-- §21  WATERMARK, FLOATING ORACLE, TASKBAR, QUICK PANEL
-- ═══════════════════════════════════════════════════════════════════════
local function CreateWatermark()
    local WM=MkFrame({Name="Watermark",Size=UDim2.new(0,222,0,24),
        Position=UDim2.new(0,6,0,6),BackgroundColor3=C.BG4,
        BackgroundTransparency=0.28,ZIndex=600},ScreenGui)
    Corner(12,WM); Stroke(1,C.P3,WM)
    MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
        Text="⬡ LXNDXN Quantum OS v3.1 · AI",
        Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.P2,ZIndex=601},WM)
    task.spawn(function()
        while WM and WM.Parent do
            Tw(WM,TI.SINE,{BackgroundTransparency=0.50}); task.wait(1.5)
            Tw(WM,TI.SINE,{BackgroundTransparency=0.22}); task.wait(1.5)
        end
    end)
end

local function CreateFloatOracle()
    local OF=MkFrame({Name="FloatOrb",Size=UDim2.new(0,54,0,54),
        Position=UDim2.new(0,10,0.5,-27),BackgroundColor3=C.P3,ZIndex=500},ScreenGui)
    Corner(27,OF); Stroke(2,C.P1,OF); Grad(C.P3,C.A2,135,OF)
    ENV.QOS_OracleFloat=OF
    MkLabel({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="🔮",TextSize=24,ZIndex=501},OF)
    task.spawn(function()
        while OF and OF.Parent do
            Tw(OF,TI.SINE,{BackgroundColor3=C.P2}); task.wait(1.2)
            Tw(OF,TI.SINE,{BackgroundColor3=C.P3}); task.wait(1.2)
        end
    end)
    local dr2,ds2,dp2=false,nil,nil
    OF.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dr2=true; ds2=i.Position; dp2=OF.Position
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(i)
        if dr2 and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds2; OF.Position=UDim2.new(dp2.X.Scale,dp2.X.Offset+d.X,dp2.Y.Scale,dp2.Y.Offset+d.Y)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if dr2 and (i.Position-ds2).Magnitude<8 then
                ClearContent(); SetActiveTab("QUANTUM ORACLE"); _G["QOS_Tab_QUANTUM_ORACLE"]()
            end
            dr2=false
        end
    end))
end

local function CreateTaskbar()
    local TB=MkFrame({Name="Taskbar",Size=UDim2.new(0,320,0,44),
        Position=UDim2.new(0.5,-160,1,-52),BackgroundColor3=C.BG4,
        BackgroundTransparency=0.18,ZIndex=700},ScreenGui)
    Corner(22,TB); Stroke(1,C.BR1,TB)
    Grad(C.BG4,Color3.fromRGB(20,14,52),135,TB)

    local TL2=MkFrame({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=701},TB)
    ListL({FillDirection=Enum.FillDirection.Horizontal,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,4)},TL2)
    Pad(0,6,0,6,TL2)

    local qas={{"⌂","START"},{"⚡","SCRIPT HUB"},{"🛠","TOOLBOX"},{"🎵","MEDIA CENTER"},
               {"🔮","QUANTUM ORACLE"},{"🚀","GAME BOOSTER"},{"🎨","SKIN CUSTOMIZER"},{"⏻","POWER"}}
    for _,qa in ipairs(qas) do
        local QB=MkBtn({Size=UDim2.new(0,32,0,32),BackgroundColor3=C.BG3,
            BackgroundTransparency=0.25,Text=qa[1],Font=Enum.Font.GothamBold,
            TextSize=15,TextColor3=C.TS,ZIndex=702},TL2); Corner(9,QB)
        QB.MouseEnter:Connect(function() Tw(QB,TI.FAST,{BackgroundColor3=C.P3,TextColor3=C.TW}) end)
        QB.MouseLeave:Connect(function() Tw(QB,TI.FAST,{BackgroundColor3=C.BG3,TextColor3=C.TS}) end)
        QB.MouseButton1Click:Connect(function()
            if not ENV.QOS_Unlocked then return end
            ClearContent(); SetActiveTab(qa[2])
            local fk="QOS_Tab_"..qa[2]:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
            if _G[fk] then pcall(_G[fk]) end
            Tw(QB,TI.FAST,{Size=UDim2.new(0,28,0,28)}); task.wait(0.1); Tw(QB,TI.BOUNCE,{Size=UDim2.new(0,32,0,32)})
        end)
    end

    local td,ts,tp=false,nil,nil
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            td=true; ts=i.Position; tp=TB.Position
        end
    end)
    Track(UserInputService.InputChanged:Connect(function(i)
        if td and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ts; TB.Position=UDim2.new(tp.X.Scale,tp.X.Offset+d.X,tp.Y.Scale,tp.Y.Offset+d.Y)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then td=false end
    end))
end

local function CreateQuickPanel()
    local QP=MkFrame({Name="QuickPanel",Size=UDim2.new(0,48,0,0),
        Position=UDim2.new(0,8,0.5,-115),BackgroundTransparency=1,
        AutomaticSize=Enum.AutomaticSize.Y,ZIndex=850},ScreenGui)
    local QL=MkFrame({Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,ZIndex=851},QP)
    ListL({Padding=UDim.new(0,4)},QL)
    for _,m in ipairs({
        {i="✈",l="Fly",  fn=function(s) if s then FlyMod.On() else FlyMod.Off() end end},
        {i="👁",l="ESP",  fn=function(s) if s then ESPMod.On() else ESPMod.Off() end end},
        {i="⏱",l="AFK",  fn=function(s) if s then AFKMod.On() else AFKMod.Off() end end},
        {i="🛡",l="God",  fn=function(s) if s then GodMod.On() else GodMod.Off() end end},
        {i="📡",l="Radar",fn=function(s) if s then RadarMod.On() else RadarMod.Off() end end},
    }) do
        local MB2=MkFrame({Size=UDim2.new(0,44,0,44),BackgroundColor3=C.BG4,ZIndex=852},QL)
        Corner(11,MB2); Stroke(1,C.BR0,MB2)
        MkLabel({Size=UDim2.new(1,0,0.58,0),BackgroundTransparency=1,Text=m.i,TextSize=17,ZIndex=853},MB2)
        local ML2=MkLabel({Size=UDim2.new(1,0,0.42,0),Position=UDim2.new(0,0,0.58,0),
            BackgroundTransparency=1,Text=m.l,Font=Enum.Font.Gotham,TextSize=8,
            TextColor3=C.TM,ZIndex=853},MB2)
        local st=false
        local CB=MkBtn({Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=854},MB2)
        CB.MouseButton1Click:Connect(function()
            st=not st; Tw(MB2,TI.FAST,{BackgroundColor3=st and C.P3 or C.BG4})
            ML2.TextColor3=st and C.A1 or C.TM; pcall(function() m.fn(st) end)
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════
-- §22  ATAJOS DE TECLADO
-- ═══════════════════════════════════════════════════════════════════════
local KM={
    [Enum.KeyCode.F1]={t="START",           i="⌂"},
    [Enum.KeyCode.F2]={t="SCRIPT HUB",      i="⚡"},
    [Enum.KeyCode.F3]={t="TOOLBOX",         i="🛠"},
    [Enum.KeyCode.F4]={t="SYSTEM SETTINGS", i="⚙"},
    [Enum.KeyCode.F5]={t="MEDIA CENTER",    i="🎵"},
    [Enum.KeyCode.F6]={t="QUANTUM ORACLE",  i="🔮"},
    [Enum.KeyCode.F7]={t="PROCESSES & LOGS",i="📊"},
    [Enum.KeyCode.F8]={t="FILE MANAGER",    i="📁"},
}

local osVis=true
Track(UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.RightShift then
        osVis=not osVis
        if MainWin then
            if osVis then MainWin.Visible=true; Tw(MainWin,TI.MED,{Size=UDim2.fromScale(1,1)})
            else Tw(MainWin,TI.MED,{Size=UDim2.new(0,0,0,0)}); task.delay(0.35,function() pcall(function() end) end) end
        end
        PushNotif("Quantum OS",osVis and "Interfaz mostrada" or "Minimizado","SYSTEM",2)
        return
    end
    local b=KM[inp.KeyCode]
    if b and ENV.QOS_Unlocked then
        ClearContent(); SetActiveTab(b.t)
        local fk="QOS_Tab_"..b.t:gsub("%s+","_"):gsub("[&]",""):gsub("__","_")
        if _G[fk] then pcall(_G[fk]) end
        PushNotif("QOS",b.i.."  "..b.t,"INFO",1.5)
    end
end))

-- ═══════════════════════════════════════════════════════════════════════
-- §23  STATS HUD
-- ═══════════════════════════════════════════════════════════════════════
local StHUD, stVis = nil, false

local function CreateStatsHUD()
    if StHUD then StHUD:Destroy() end
    StHUD=MkFrame({Name="StHUD",Size=UDim2.new(0,172,0,108),
        Position=UDim2.new(0,8,0,60),BackgroundColor3=C.BG4,
        BackgroundTransparency=0.22,ZIndex=800},ScreenGui)
    Corner(12,StHUD); Stroke(1,C.P3,StHUD); Pad(7,9,7,9,StHUD)
    MkLabel({Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="⬡ QUANTUM STATS",
        Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.P2,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=801},StHUD)
    local rows={{k="ws",l="WalkSpeed"},{k="jp",l="JumpPower"},{k="hp",l="Health"},{k="fps",l="FPS"},{k="ping",l="Ping"}}
    local SL2={}
    for i,r in ipairs(rows) do
        local R=MkFrame({Size=UDim2.new(1,0,0,15),Position=UDim2.new(0,0,0,18+(i-1)*16),BackgroundTransparency=1,ZIndex=801},StHUD)
        MkLabel({Size=UDim2.new(0.55,0,1,0),BackgroundTransparency=1,Text=r.l..":",Font=Enum.Font.Gotham,TextSize=10,TextColor3=C.TM,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=802},R)
        SL2[r.k]=MkLabel({Size=UDim2.new(0.45,0,1,0),Position=UDim2.new(0.55,0,0,0),BackgroundTransparency=1,Text="—",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=C.A1,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=802},R)
    end
    local fb,fl={},tick()
    Track(RunService.RenderStepped:Connect(function()
        if not StHUD or not StHUD.Parent then return end
        pcall(function()
            local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then
                SL2.ws.Text=math.floor(h.WalkSpeed); SL2.jp.Text=math.floor(h.JumpPower)
                SL2.hp.Text=math.floor(h.Health).."/"..math.floor(h.MaxHealth)
                SL2.hp.TextColor3=h.Health<h.MaxHealth*0.3 and C.TR or C.A1
            end
            local n=tick(); table.insert(fb,1/(n-fl+1e-5)); fl=n
            if #fb>30 then table.remove(fb,1) end
            local s=0; for _,v in pairs(fb) do s=s+v end
            local fps=math.floor(s/#fb)
            SL2.fps.Text=fps.." fps"; SL2.fps.TextColor3=fps<20 and C.TR or fps<40 and C.TY or C.TG
            SL2.ping.Text=math.random(18,85).." ms"
        end)
    end))
end

Track(UserInputService.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.RightControl then
        stVis=not stVis
        if stVis then CreateStatsHUD(); PushNotif("Stats HUD","Panel activado.","SUCCESS",2)
        else if StHUD then StHUD:Destroy(); StHUD=nil end; PushNotif("Stats HUD","Oculto.","INFO",2) end
    end
end))

-- ═══════════════════════════════════════════════════════════════════════
-- §24  CHAT COMMANDS
-- ═══════════════════════════════════════════════════════════════════════
local CC={
    ["/qfly"]   =function() if FlyMod.Active then FlyMod.Off() else FlyMod.On() end end,
    ["/qesp"]   =function() if ESPMod.Active then ESPMod.Off() else ESPMod.On() end end,
    ["/qafk"]   =function() if AFKMod.Active then AFKMod.Off() else AFKMod.On() end end,
    ["/qgod"]   =function() if GodMod.Active then GodMod.Off() else GodMod.On() end end,
    ["/qradar"] =function() if RadarMod.Active then RadarMod.Off() else RadarMod.On() end end,
    ["/qreset"] =function() MovMod.Speed(16); MovMod.Jump(50) end,
    ["/qspeed"] =function(a) MovMod.Speed(tonumber(a[1]) or 100) end,
    ["/qjump"]  =function(a) MovMod.Jump(tonumber(a[1]) or 100) end,
    ["/qoracle"]=function() ClearContent(); SetActiveTab("QUANTUM ORACLE"); pcall(_G["QOS_Tab_QUANTUM_ORACLE"]) end,
    ["/qhelp"]  =function() PushNotif("Commands","/qfly /qesp /qafk /qgod /qradar /qspeed /qjump /qoracle","ORACLE",6) end,
}
pcall(function()
    Track(LP.Chatted:Connect(function(msg)
        local p=msg:split(" "); local cmd=p[1]:lower(); local a={}
        for i=2,#p do a[#a+1]=p[i] end
        if CC[cmd] then pcall(function() CC[cmd](a) end) end
    end))
end)

-- ═══════════════════════════════════════════════════════════════════════
-- §25  HEARTBEAT Y CHARACTER
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
-- §26  API GLOBAL
-- ═══════════════════════════════════════════════════════════════════════
ENV.QuantumOS={
    version="3.1", edition="Delta", orchestrator=AI.ORCH,
    modules={Fly=FlyMod,ESP=ESPMod,AFK=AFKMod,God=GodMod,Radar=RadarMod,Mov=MovMod},
    ui={toast=ShowToast,notif=PushNotif},
    ai={query=OracleQuery,verify=VerifyAPIKey,models=AI.MODEL},
    commands=CC,
}

-- ═══════════════════════════════════════════════════════════════════════
-- §27  POST-LAUNCH
-- ═══════════════════════════════════════════════════════════════════════
local function PostLaunch()
    pcall(CreateTaskbar)
    pcall(CreateQuickPanel)
    pcall(CreateWatermark)
    task.delay(1.5,function() PushNotif("Atajos","F1–F8: Tabs  |  RShift: Toggle  |  RCtrl: Stats","INFO",5) end)
    task.delay(4.0,function() PushNotif("Oracle AI","/qoracle · 5 agentes especializados listos.","ORACLE",4) end)
    task.delay(7.0,function() PushNotif("Quick Panel","Fly·ESP·AFK·God·Radar disponibles.","SYSTEM",4) end)
    task.delay(10,function()  PushNotif("Quantum OS v3.1","Sistema Multi-Agent AI operativo ✓","AI",3) end)
end

local function Launch(mode)
    task.delay(2.5,function() pcall(CreateFloatOracle) end)
    CreateMainWindow()
    task.wait(0.1)
    SetActiveTab("START"); _G["QOS_Tab_START"]()
    task.delay(0.8,function()
        ShowToast("Quantum OS v3.1","Bienvenido, "..DNAME.." · AI Online","⬡")
        task.delay(2,function() ShowToast("Oracle AI","5 Agentes · Juego: "..GNAME,"🔮") end)
        task.delay(4,function() ShowToast("Dispositivo","Modo: "..(mode or "?"):upper(),"📱") end)
    end)
    task.delay(0.6,function() pcall(PostLaunch) end)
end

-- ═══════════════════════════════════════════════════════════════════════
-- §28  SECUENCIA DE ARRANQUE
-- ═══════════════════════════════════════════════════════════════════════
pcall(function()
    CreateBoot()
    task.delay(5.0,function()
        pcall(function()
            CreateLogin(function()
                pcall(function()
                    CreateDeviceSelect(function(mode)
                        pcall(function() Launch(mode) end)
                    end)
                end)
            end)
        end)
    end)
end)

print("╔═══════════════════════════════════════════════════════════════╗")
print("║  LXNDXN QUANTUM OS v3.1 · DELTA EDITION · MULTI-AGENT AI    ║")
print("║  Jugador    : "..string.format("%-48s",DNAME)..                                 "║")
print("║  Juego      : "..string.format("%-48s",GNAME:sub(1,48))..                      "║")
print("║  Fix        : Verificación robusta · Responsive UI           ║")
print("║  Toggle OS  → RightShift                                     ║")
print("║  Stats HUD  → RightControl                                   ║")
print("║  Tabs F1–F8 → START/HUB/TOOLBOX/SETTINGS/MEDIA...           ║")
print("║  Chat cmds  → /qhelp                                         ║")
print("╚═══════════════════════════════════════════════════════════════╝")
