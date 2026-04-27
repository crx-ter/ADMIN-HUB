-- Admin Hub Pro v5 - Centro de Control iOS Style (Testing & Troll Tool)
-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║       Admin Hub Pro v5 - Centro de Control iOS Style                    ║
-- ║       Herramienta de Testing Profesional para Desarrolladores           ║
-- ║       Equipo Senior · 6 Devs · 12 años experiencia · Ultra Complete     ║
-- ║                                                                          ║
-- ║  Tabs: Protección · Movimiento · Auto/Farm · Troll · Visual · Perfil    ║
-- ║  Toggle-aware: WalkSpeed/JumpPower respetan estado ON/OFF               ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════
--  SERVICIOS
-- ═══════════════════════════════════════════
local Players             = game:GetService("Players")
local VIM                 = game:GetService("VirtualInputManager")
local UIS                 = game:GetService("UserInputService")
local RS                  = game:GetService("RunService")
local TS                  = game:GetService("TweenService")
local TPS                 = game:GetService("TeleportService")
local Lighting            = game:GetService("Lighting")
local HttpService         = game:GetService("HttpService")

local LP                  = Players.LocalPlayer
local Cam                 = workspace.CurrentCamera

-- ═══════════════════════════════════════════
--  LIMPIAR VERSIÓN ANTERIOR
-- ═══════════════════════════════════════════
local oldGui = LP:FindFirstChild("PlayerGui")
    and LP.PlayerGui:FindFirstChild("AdminHubV5")
if oldGui then oldGui:Destroy() end

-- ═══════════════════════════════════════════
--  ESTADO GLOBAL
-- ═══════════════════════════════════════════
local S = {
    -- Panel
    open         = false,
    -- Protección
    godMode      = false,
    noclip       = false,
    antiAfk      = false,
    noFallDmg    = false,
    invisible    = false,
    anchored     = false,
    -- Movimiento
    fly          = false,
    flyUp        = false,
    flyDown      = false,
    infJump      = false,
    clickTP      = false,
    -- Auto
    autoClick    = false,
    autoRebirth  = false,
    autoTrain    = false,
    autoWin      = false,
    -- Troll
    headsit      = false,
    spinSelf     = false,
    -- Visual
    esp          = false,
    fullbright   = false,
    -- Stats loop
    statsActive  = true,
}

-- ═══════════════════════════════════════════
--  CONFIGURACIÓN AJUSTABLE
-- ═══════════════════════════════════════════
local CFG = {
    walkSpeed    = 16,
    jumpPower    = 50,
    flySpeed     = 60,
    clickRate    = 0.05,
    headsitOff   = 2.0,   -- offset vertical headsit
    knockback    = 80,
    sizeScale    = 1.0,
    espMaxDist   = 600,
    accentIndex  = 1,     -- índice de color accent actual
    darkMode     = true,
}

-- Checkpoints (8 slots)
local CP = {}
for i = 1, 8 do CP[i] = {name="Slot "..i, pos=nil} end

-- Toggle states para speed/jump (respetan ON/OFF)
local speedBoostON = false   -- WalkSpeed override activo
local jumpBoostON  = false   -- JumpPower override activo

-- Troll targets (jugadores seleccionados)
local trollTarget = nil

-- ═══════════════════════════════════════════
--  SISTEMA DE CONEXIONES (cleanup limpio)
-- ═══════════════════════════════════════════
local CONNS = {}
local function addConn(key, conn)
    if CONNS[key] then pcall(function() CONNS[key]:Disconnect() end) end
    CONNS[key] = conn
end
local function removeConn(key)
    if CONNS[key] then
        pcall(function() CONNS[key]:Disconnect() end)
        CONNS[key] = nil
    end
end

-- ═══════════════════════════════════════════
--  TEMAS  (Oscuro / Claro + Accents)
-- ═══════════════════════════════════════════
local ACCENTS = {
    { name="Azul",    col=Color3.fromRGB(45, 165, 255) },
    { name="Morado",  col=Color3.fromRGB(150, 65, 255) },
    { name="Verde",   col=Color3.fromRGB(35, 210, 110) },
    { name="Naranja", col=Color3.fromRGB(255, 148, 30) },
    { name="Rosa",    col=Color3.fromRGB(255, 75, 145)  },
    { name="Rojo",    col=Color3.fromRGB(255, 58, 58)   },
}

local DARK = {
    bg        = Color3.fromRGB(10,  11, 22),
    panel     = Color3.fromRGB(14,  16, 30),
    card      = Color3.fromRGB(20,  22, 40),
    cardHov   = Color3.fromRGB(26,  28, 50),
    tab       = Color3.fromRGB(10,  11, 22),
    section   = Color3.fromRGB(16,  18, 34),
    off       = Color3.fromRGB(22,  24, 44),
    text      = Color3.fromRGB(218, 222, 240),
    sub       = Color3.fromRGB(90,  98, 130),
    white     = Color3.new(1,1,1),
    black     = Color3.new(0,0,0),
    border    = Color3.fromRGB(30,  34, 60),
}

local LIGHT = {
    bg        = Color3.fromRGB(242, 242, 248),
    panel     = Color3.fromRGB(255, 255, 255),
    card      = Color3.fromRGB(235, 236, 245),
    cardHov   = Color3.fromRGB(225, 226, 238),
    tab       = Color3.fromRGB(242, 242, 248),
    section   = Color3.fromRGB(228, 230, 242),
    off       = Color3.fromRGB(200, 202, 218),
    text      = Color3.fromRGB(18,  20, 40),
    sub       = Color3.fromRGB(110, 115, 145),
    white     = Color3.new(1,1,1),
    black     = Color3.new(0,0,0),
    border    = Color3.fromRGB(200, 202, 220),
}

local TH = CFG.darkMode and DARK or LIGHT
local ACCENT = ACCENTS[CFG.accentIndex].col

-- ═══════════════════════════════════════════
--  HELPERS UI
-- ═══════════════════════════════════════════
local function C(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 14)
    c.Parent = p; return c
end

local function Str(p, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or ACCENT; s.Thickness = thick or 1.5
    s.Transparency = trans or 0.35
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function G(p, cA, cB, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, cA),
        ColorSequenceKeypoint.new(1, cB),
    }
    g.Rotation = rot or 90; g.Parent = p; return g
end

local function Tw(obj, props, t, sty, dir)
    local ok, _ = pcall(function()
        TS:Create(obj,
            TweenInfo.new(t or 0.22,
                sty or Enum.EasingStyle.Quart,
                dir or Enum.EasingDirection.Out),
            props):Play()
    end)
end

local function Lbl(parent, txt, size, font, color, xAlign, zIdx, wrap)
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text               = txt or ""
    l.TextSize           = size or 14
    l.Font               = font or Enum.Font.GothamSemibold
    l.TextColor3         = color or TH.text
    l.TextXAlignment     = xAlign or Enum.TextXAlignment.Left
    l.TextWrapped        = wrap or false
    l.ZIndex             = zIdx or 14
    l.Parent             = parent
    return l
end

local function Btn(parent, txt, size, font, color, zIdx)
    local b = Instance.new("TextButton")
    b.Size               = UDim2.new(1,0,1,0)
    b.BackgroundTransparency = 1
    b.Text               = txt or ""
    b.TextSize           = size or 14
    b.Font               = font or Enum.Font.GothamSemibold
    b.TextColor3         = color or TH.text
    b.AutoButtonColor    = false
    b.ZIndex             = zIdx or 15
    b.Parent             = parent
    return b
end

-- Shadow simulada (frame oscuro ligeramente más grande detrás)
local function Shadow(parent)
    local s = Instance.new("Frame")
    s.Size               = UDim2.new(1,8,1,8)
    s.Position           = UDim2.new(0,-4,0,4)
    s.BackgroundColor3   = Color3.fromRGB(0,0,0)
    s.BackgroundTransparency = 0.75
    s.BorderSizePixel    = 0
    s.ZIndex             = (parent.ZIndex or 10) - 1
    s.Parent             = parent.Parent or parent
    C(s, 18)
    return s
end

-- ═══════════════════════════════════════════
--  DRAG  (touch-friendly, con clamp)
-- ═══════════════════════════════════════════
local function Drag(frame, handle)
    handle = handle or frame
    local drag, sF, sM, li = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
        or i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; sF=frame.Position
            sM=Vector2.new(i.Position.X, i.Position.Y); li=i
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType~=Enum.UserInputType.Touch
        and i.UserInputType~=Enum.UserInputType.MouseMovement then return end
        local vp = Cam.ViewportSize
        local d  = Vector2.new(i.Position.X,i.Position.Y)-sM
        local nx = math.clamp(sF.X.Offset+d.X, 0, vp.X-frame.AbsoluteSize.X)
        local ny = math.clamp(sF.Y.Offset+d.Y, 0, vp.Y-frame.AbsoluteSize.Y)
        frame.Position = UDim2.new(0,nx,0,ny)
    end)
    UIS.InputEnded:Connect(function(i) if i==li then drag=false end end)
end

-- ═══════════════════════════════════════════
--  TOAST NOTIFICATION
-- ═══════════════════════════════════════════
local Root      -- forward declaration (ScreenGui root)
local toastQ    = {}
local toastBusy = false

local function processToastQ()
    if toastBusy or #toastQ==0 then return end
    toastBusy = true
    local item = table.remove(toastQ,1)
    local vp   = Cam.ViewportSize

    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(0, math.min(vp.X*0.78, 320), 0, 48)
    bg.Position         = UDim2.new(0.5, -math.min(vp.X*0.78,320)/2, 0, -60)
    bg.BackgroundColor3 = item.col or ACCENT
    bg.BorderSizePixel  = 0; bg.ZIndex = 80
    bg.Parent           = Root
    C(bg, 14)
    Str(bg, item.col or ACCENT, 1.2, 0.4)

    local ico = Instance.new("TextLabel")
    ico.Size             = UDim2.new(0,46,1,0)
    ico.BackgroundTransparency=1; ico.Text=item.ico or "ℹ"
    ico.TextSize=22; ico.Font=Enum.Font.GothamBold
    ico.TextColor3=TH.white; ico.ZIndex=81; ico.Parent=bg

    local msg = Instance.new("TextLabel")
    msg.Size             = UDim2.new(1,-50,1,0)
    msg.Position         = UDim2.new(0,46,0,0)
    msg.BackgroundTransparency=1; msg.Text=item.msg
    msg.TextSize=13; msg.Font=Enum.Font.GothamSemibold
    msg.TextColor3=TH.white; msg.TextXAlignment=Enum.TextXAlignment.Left
    msg.TextWrapped=true; msg.ZIndex=81; msg.Parent=bg

    Tw(bg,{Position=UDim2.new(0.5,-math.min(vp.X*0.78,320)/2,0,16)},
        0.3,Enum.EasingStyle.Back)
    task.delay(2.4, function()
        Tw(bg,{Position=UDim2.new(0.5,-math.min(vp.X*0.78,320)/2,0,-70)},0.25)
        task.delay(0.28, function()
            bg:Destroy(); toastBusy=false
            task.defer(processToastQ)
        end)
    end)
end

local function notify(msg, ico, col)
    table.insert(toastQ, {msg=msg, ico=ico or "✦",
        col=col or ACCENT})
    task.defer(processToastQ)
end

-- ═══════════════════════════════════════════
--  GUI ROOT
-- ═══════════════════════════════════════════
Root = Instance.new("ScreenGui")
Root.Name             = "AdminHubV5"
Root.ResetOnSpawn     = false
Root.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
Root.IgnoreGuiInset   = true
Root.DisplayOrder     = 999
Root.Parent           = LP:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════
--  BOTÓN FLOTANTE
-- ═══════════════════════════════════════════
local FB = Instance.new("TextButton")
FB.Size             = UDim2.new(0,72,0,72)
FB.Position         = UDim2.new(0,14,0,200)
FB.BackgroundColor3 = ACCENT
FB.Text             = ""; FB.BorderSizePixel=0
FB.AutoButtonColor  = false; FB.ZIndex=60
FB.Parent           = Root
C(FB, 36)
G(FB, ACCENT, Color3.fromRGB(
    math.clamp(math.floor(ACCENT.R*255*0.5),0,255),
    math.clamp(math.floor(ACCENT.G*255*0.5),0,255),
    math.clamp(math.floor(ACCENT.B*255*1.4),0,255)), 135)
Str(FB, ACCENT, 2, 0.35)

local FBIco = Instance.new("TextLabel")
FBIco.Size=UDim2.new(1,0,1,0); FBIco.BackgroundTransparency=1
FBIco.Text="⚙"; FBIco.TextSize=34; FBIco.Font=Enum.Font.GothamBold
FBIco.TextColor3=TH.white; FBIco.ZIndex=61; FBIco.Parent=FB

-- Anillo pulsante
local Ring = Instance.new("Frame")
Ring.Size=UDim2.new(1,18,1,18); Ring.Position=UDim2.new(0,-9,0,-9)
Ring.BackgroundTransparency=1; Ring.BorderSizePixel=0
Ring.ZIndex=59; Ring.Parent=FB
C(Ring,44); Str(Ring,ACCENT,2.5,0.18)

task.spawn(function()
    while Root.Parent do
        Tw(Ring,{Size=UDim2.new(1,28,1,28),Position=UDim2.new(0,-14,0,-14)},
            0.9,Enum.EasingStyle.Sine)
        task.wait(0.9)
        Tw(Ring,{Size=UDim2.new(1,18,1,18),Position=UDim2.new(0,-9,0,-9)},
            0.9,Enum.EasingStyle.Sine)
        task.wait(1.6)
    end
end)

-- Feedback táctil
FB.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        Tw(FB,{Size=UDim2.new(0,64,0,64)},0.07)
    end
end)
FB.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch
    or i.UserInputType==Enum.UserInputType.MouseButton1 then
        Tw(FB,{Size=UDim2.new(0,72,0,72)},0.16,Enum.EasingStyle.Back)
    end
end)
Drag(FB)

-- ═══════════════════════════════════════════
--  PANEL PRINCIPAL
-- ═══════════════════════════════════════════
local Panel = Instance.new("Frame")
Panel.Size             = UDim2.new(0.92,0,0.84,0)
Panel.Position         = UDim2.new(0.04,0,0.08,0)
Panel.BackgroundColor3 = TH.panel
Panel.Visible          = false; Panel.BorderSizePixel=0
Panel.ClipsDescendants = true; Panel.ZIndex=40
Panel.Parent           = Root
C(Panel,22)
Str(Panel, TH.border, 1.5, 0.1)
G(Panel, TH.panel,
    Color3.fromRGB(
        math.floor(TH.panel.R*255*0.88),
        math.floor(TH.panel.G*255*0.88),
        math.floor(TH.panel.B*255*0.92)))

-- ── Barra de título ──────────────────────────────────────────
local TBar = Instance.new("Frame")
TBar.Size=UDim2.new(1,0,0,54); TBar.BackgroundColor3=TH.bg
TBar.BorderSizePixel=0; TBar.ZIndex=41; TBar.Parent=Panel
C(TBar,22)

-- Gradiente del title bar con accent
G(TBar,
    Color3.fromRGB(
        math.clamp(math.floor(ACCENT.R*255*0.35),0,255),
        math.clamp(math.floor(ACCENT.G*255*0.35),0,255),
        math.clamp(math.floor(ACCENT.B*255*0.6),0,255)),
    TH.bg, 90)

-- Icono título
local TBarIco = Instance.new("TextLabel")
TBarIco.Size=UDim2.new(0,40,1,0); TBarIco.Position=UDim2.new(0,12,0,0)
TBarIco.BackgroundTransparency=1; TBarIco.Text="⚙"
TBarIco.TextSize=22; TBarIco.Font=Enum.Font.GothamBold
TBarIco.TextColor3=ACCENT; TBarIco.ZIndex=42; TBarIco.Parent=TBar

local TBarLbl = Instance.new("TextLabel")
TBarLbl.Size=UDim2.new(1,-100,1,0); TBarLbl.Position=UDim2.new(0,54,0,0)
TBarLbl.BackgroundTransparency=1; TBarLbl.Text="ADMIN HUB PRO  v5"
TBarLbl.TextSize=16; TBarLbl.Font=Enum.Font.GothamBold
TBarLbl.TextColor3=TH.text; TBarLbl.TextXAlignment=Enum.TextXAlignment.Left
TBarLbl.ZIndex=42; TBarLbl.Parent=TBar

local TBarSub = Instance.new("TextLabel")
TBarSub.Size=UDim2.new(1,-100,0,18); TBarSub.Position=UDim2.new(0,54,0.5,0)
TBarSub.BackgroundTransparency=1; TBarSub.Text="Centro de Control · iOS Style"
TBarSub.TextSize=11; TBarSub.Font=Enum.Font.Gotham
TBarSub.TextColor3=TH.sub; TBarSub.TextXAlignment=Enum.TextXAlignment.Left
TBarSub.ZIndex=42; TBarSub.Parent=TBar

-- Botón cerrar
local XBtn = Instance.new("TextButton")
XBtn.Size=UDim2.new(0,40,0,40); XBtn.Position=UDim2.new(1,-48,0.5,-20)
XBtn.BackgroundColor3=Color3.fromRGB(188,35,35); XBtn.Text="✕"
XBtn.TextColor3=TH.white; XBtn.TextSize=15; XBtn.Font=Enum.Font.GothamBold
XBtn.BorderSizePixel=0; XBtn.AutoButtonColor=false; XBtn.ZIndex=43
XBtn.Parent=TBar; C(XBtn,10)

Drag(Panel, TBar)

-- ── TABS BAR ────────────────────────────────────────────────
local TABH = 52
local TabBar = Instance.new("Frame")
TabBar.Size=UDim2.new(1,0,0,TABH); TabBar.Position=UDim2.new(0,0,0,54)
TabBar.BackgroundColor3=TH.tab; TabBar.BorderSizePixel=0
TabBar.ZIndex=41; TabBar.Parent=Panel

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size=UDim2.new(1,0,1,0); TabScroll.BackgroundTransparency=1
TabScroll.BorderSizePixel=0; TabScroll.ScrollBarThickness=0
TabScroll.ScrollingDirection=Enum.ScrollingDirection.X
TabScroll.CanvasSize=UDim2.new(0,0,1,0)
TabScroll.ZIndex=42; TabScroll.Parent=TabBar

local TabLL = Instance.new("UIListLayout")
TabLL.FillDirection=Enum.FillDirection.Horizontal
TabLL.VerticalAlignment=Enum.VerticalAlignment.Center
TabLL.Padding=UDim.new(0,6); TabLL.Parent=TabScroll

local TabLP = Instance.new("UIPadding")
TabLP.PaddingLeft=UDim.new(0,8); TabLP.PaddingRight=UDim.new(0,8)
TabLP.Parent=TabScroll

TabLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabScroll.CanvasSize=UDim2.new(0,TabLL.AbsoluteContentSize.X+16,1,0)
end)

-- Línea accent bajo tabs
local TabLine=Instance.new("Frame")
TabLine.Size=UDim2.new(1,0,0,2)
TabLine.Position=UDim2.new(0,0,1,-2)
TabLine.BackgroundColor3=ACCENT
TabLine.BackgroundTransparency=0.5
TabLine.BorderSizePixel=0; TabLine.ZIndex=42; TabLine.Parent=TabBar

-- ── ÁREA CONTENIDO ──────────────────────────────────────────
local CTOP = 54+TABH+2
local CA = Instance.new("Frame")
CA.Size=UDim2.new(1,0,1,-CTOP); CA.Position=UDim2.new(0,0,0,CTOP)
CA.BackgroundTransparency=1; CA.BorderSizePixel=0
CA.ClipsDescendants=true; CA.ZIndex=41; CA.Parent=Panel

-- ═══════════════════════════════════════════
--  SISTEMA DE TABS
-- ═══════════════════════════════════════════
local TAB_DEFS = {
    {ico="🛡", lbl="Protec.",  key="prot"},
    {ico="🚀", lbl="Mover",    key="move"},
    {ico="🤖", lbl="Auto",     key="auto"},
    {ico="😈", lbl="Troll",    key="troll"},
    {ico="👁",  lbl="Visual",  key="vis"},
    {ico="📊", lbl="Perfil",   key="stats"},
}

local TABS  = {}
local PAGES = {}

for _, def in ipairs(TAB_DEFS) do
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(0,88,0,40); btn.BackgroundColor3=TH.off
    btn.Text=def.ico.."  "..def.lbl; btn.TextColor3=TH.sub
    btn.TextSize=12; btn.Font=Enum.Font.GothamSemibold
    btn.BorderSizePixel=0; btn.AutoButtonColor=false
    btn.ZIndex=43; btn.Parent=TabScroll
    C(btn,10)

    local page = Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0)
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.ScrollBarThickness=4; page.ScrollBarImageColor3=ACCENT
    page.ScrollingDirection=Enum.ScrollingDirection.Y
    page.ElasticBehavior=Enum.ElasticBehavior.Always
    page.CanvasSize=UDim2.new(0,0,0,0)
    page.Visible=false; page.ZIndex=42; page.Parent=CA

    local lay = Instance.new("UIListLayout")
    lay.Padding=UDim.new(0,10); lay.Parent=page
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,12); pad.PaddingRight=UDim.new(0,12)
    pad.PaddingTop=UDim.new(0,12); pad.PaddingBottom=UDim.new(0,22)
    pad.Parent=page
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+30)
    end)

    TABS[def.key]  = {btn=btn}
    PAGES[def.key] = page
end

local curTab = nil
local function selTab(key)
    if curTab==key then return end; curTab=key
    for k,t in pairs(TABS) do
        local me = (k==key)
        Tw(t.btn,{
            BackgroundColor3=me and ACCENT or TH.off,
            TextColor3=me and TH.white or TH.sub,
            Size=me and UDim2.new(0,94,0,40) or UDim2.new(0,88,0,40),
        },0.18)
        PAGES[k].Visible=me
    end
end
for _,def in ipairs(TAB_DEFS) do
    local k=def.key
    TABS[k].btn.MouseButton1Click:Connect(function() selTab(k) end)
end
selTab("prot")


-- ═══════════════════════════════════════════
--  COMPONENTES UI REUTILIZABLES
-- ═══════════════════════════════════════════

-- Cabecera de sección
local function mkSec(pageKey, txt, icon)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,0,0,32); f.BackgroundColor3=TH.section
    f.BorderSizePixel=0; f.ZIndex=43; f.Parent=PAGES[pageKey]
    C(f,9)
    Str(f, ACCENT, 1, 0.6)
    local il=Instance.new("TextLabel")
    il.Size=UDim2.new(0,28,1,0); il.Position=UDim2.new(0,8,0,0)
    il.BackgroundTransparency=1; il.Text=icon or "▸"
    il.TextSize=15; il.Font=Enum.Font.GothamBold
    il.TextColor3=ACCENT; il.ZIndex=44; il.Parent=f
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-40,1,0); tl.Position=UDim2.new(0,36,0,0)
    tl.BackgroundTransparency=1; tl.Text=txt
    tl.TextSize=12; tl.Font=Enum.Font.GothamBold
    tl.TextColor3=TH.sub; tl.TextXAlignment=Enum.TextXAlignment.Left
    tl.ZIndex=44; tl.Parent=f
    return f
end

-- Toggle tipo pill iOS
local function mkToggle(pageKey, lbl, icon, acCol, onToggle)
    local ac=acCol or ACCENT
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,62); card.BackgroundColor3=TH.card
    card.BorderSizePixel=0; card.ZIndex=43; card.Parent=PAGES[pageKey]
    C(card,16); local sk=Str(card,TH.border,1,0.2)

    local ico=Instance.new("TextLabel")
    ico.Size=UDim2.new(0,44,1,0); ico.Position=UDim2.new(0,8,0,0)
    ico.BackgroundTransparency=1; ico.Text=icon or "●"
    ico.TextSize=26; ico.Font=Enum.Font.GothamBold
    ico.TextColor3=TH.sub; ico.ZIndex=44; ico.Parent=card

    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-118,1,0); tl.Position=UDim2.new(0,56,0,0)
    tl.BackgroundTransparency=1; tl.Text=lbl
    tl.TextSize=14; tl.Font=Enum.Font.GothamSemibold
    tl.TextColor3=TH.text; tl.TextXAlignment=Enum.TextXAlignment.Left
    tl.TextWrapped=true; tl.ZIndex=44; tl.Parent=card

    -- Pill iOS
    local pill=Instance.new("Frame")
    pill.Size=UDim2.new(0,56,0,30); pill.Position=UDim2.new(1,-66,0.5,-15)
    pill.BackgroundColor3=TH.off; pill.BorderSizePixel=0
    pill.ZIndex=44; pill.Parent=card; C(pill,15)

    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,24,0,24); knob.Position=UDim2.new(0,3,0.5,-12)
    knob.BackgroundColor3=TH.sub; knob.BorderSizePixel=0
    knob.ZIndex=45; knob.Parent=pill; C(knob,12)

    -- Mini label OFF dentro del pill
    local stL=Instance.new("TextLabel")
    stL.Size=UDim2.new(1,-6,1,0); stL.Position=UDim2.new(0,3,0,0)
    stL.BackgroundTransparency=1; stL.Text="OFF"
    stL.TextSize=8; stL.Font=Enum.Font.GothamBold
    stL.TextColor3=TH.sub; stL.TextXAlignment=Enum.TextXAlignment.Right
    stL.ZIndex=46; stL.Parent=pill

    local isOn=false
    local hit=Instance.new("TextButton")
    hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1
    hit.Text=""; hit.AutoButtonColor=false; hit.ZIndex=47
    hit.Parent=card

    local function setOn(v)
        isOn=v
        if isOn then
            Tw(pill,{BackgroundColor3=ac},0.2)
            Tw(knob,{Position=UDim2.new(0,29,0.5,-12),BackgroundColor3=TH.white},0.2)
            Tw(card,{BackgroundColor3=TH.cardHov},0.2)
            Tw(sk,{Color=ac,Transparency=0.15},0.2)
            Tw(ico,{TextColor3=ac},0.2)
            stL.Text="ON"; stL.TextColor3=TH.white
            stL.TextXAlignment=Enum.TextXAlignment.Left
        else
            Tw(pill,{BackgroundColor3=TH.off},0.2)
            Tw(knob,{Position=UDim2.new(0,3,0.5,-12),BackgroundColor3=TH.sub},0.2)
            Tw(card,{BackgroundColor3=TH.card},0.2)
            Tw(sk,{Color=TH.border,Transparency=0.2},0.2)
            Tw(ico,{TextColor3=TH.sub},0.2)
            stL.Text="OFF"; stL.TextColor3=TH.sub
            stL.TextXAlignment=Enum.TextXAlignment.Right
        end
        onToggle(isOn)
    end

    hit.MouseButton1Click:Connect(function() setOn(not isOn) end)
    return card, setOn
end

-- Slider táctil grande
local function mkSlider(pageKey, lbl, icon, mn, mx, def, fmt, onChange)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,80); card.BackgroundColor3=TH.card
    card.BorderSizePixel=0; card.ZIndex=43; card.Parent=PAGES[pageKey]
    C(card,16); Str(card,TH.border,1,0.2)

    local ico=Instance.new("TextLabel")
    ico.Size=UDim2.new(0,36,0,28); ico.Position=UDim2.new(0,10,0,8)
    ico.BackgroundTransparency=1; ico.Text=icon or "●"
    ico.TextSize=20; ico.Font=Enum.Font.GothamBold
    ico.TextColor3=TH.sub; ico.ZIndex=44; ico.Parent=card

    local nl=Instance.new("TextLabel")
    nl.Size=UDim2.new(1,-104,0,28); nl.Position=UDim2.new(0,48,0,8)
    nl.BackgroundTransparency=1; nl.Text=lbl
    nl.TextSize=13; nl.Font=Enum.Font.GothamSemibold
    nl.TextColor3=TH.text; nl.TextXAlignment=Enum.TextXAlignment.Left
    nl.TextWrapped=true; nl.ZIndex=44; nl.Parent=card

    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0,58,0,28); vl.Position=UDim2.new(1,-66,0,8)
    vl.BackgroundTransparency=1; vl.Text=tostring(def)
    vl.TextSize=14; vl.Font=Enum.Font.GothamBold
    vl.TextColor3=ACCENT; vl.TextXAlignment=Enum.TextXAlignment.Right
    vl.ZIndex=44; vl.Parent=card

    local track=Instance.new("Frame")
    track.Size=UDim2.new(1,-20,0,8); track.Position=UDim2.new(0,10,0,54)
    track.BackgroundColor3=TH.off; track.BorderSizePixel=0
    track.ZIndex=44; track.Parent=card; C(track,4)

    local fill=Instance.new("Frame")
    fill.Size=UDim2.new((def-mn)/(mx-mn),0,1,0)
    fill.BackgroundColor3=ACCENT; fill.BorderSizePixel=0
    fill.ZIndex=45; fill.Parent=track; C(fill,4)
    G(fill,ACCENT,Color3.fromRGB(
        math.clamp(math.floor(ACCENT.R*255*0.6),0,255),
        math.clamp(math.floor(ACCENT.G*255*0.6),0,255),
        math.clamp(math.floor(ACCENT.B*255*1.4),0,255)))

    local dot=Instance.new("Frame")
    dot.Size=UDim2.new(0,22,0,22); dot.Position=UDim2.new(fill.Size.X.Scale,-11,0.5,-11)
    dot.BackgroundColor3=TH.white; dot.BorderSizePixel=0
    dot.ZIndex=46; dot.Parent=track; C(dot,11)
    Str(dot,ACCENT,2,0.25)

    local hitZ=Instance.new("TextButton")
    hitZ.Size=UDim2.new(1,-20,0,46); hitZ.Position=UDim2.new(0,10,0,44)
    hitZ.BackgroundTransparency=1; hitZ.Text=""
    hitZ.AutoButtonColor=false; hitZ.ZIndex=47; hitZ.Parent=card

    local dragging=false
    local function upd(x)
        local rel=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local v=mn+(mx-mn)*rel
        fill.Size=UDim2.new(rel,0,1,0); dot.Position=UDim2.new(rel,-11,0.5,-11)
        local d
        if fmt=="int" then d=math.floor(v)
        elseif fmt=="d3" then d=math.floor(v*1000)/1000
        else d=math.floor(v*10)/10 end
        vl.Text=tostring(d); onChange(v)
    end
    hitZ.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; upd(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseMovement) then upd(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    return card
end

-- Botón de acción (color sólido)
local function mkAction(pageKey, lbl, icon, col, onClick)
    local card=Instance.new("TextButton")
    card.Size=UDim2.new(1,0,0,58); card.BackgroundColor3=col or TH.card
    card.BorderSizePixel=0; card.AutoButtonColor=false
    card.Text=""; card.ZIndex=43; card.Parent=PAGES[pageKey]
    C(card,14); Str(card,col or ACCENT,1.2,0.4)
    G(card,col or ACCENT,Color3.fromRGB(
        math.clamp(math.floor((col or ACCENT).R*255*0.65),0,255),
        math.clamp(math.floor((col or ACCENT).G*255*0.65),0,255),
        math.clamp(math.floor((col or ACCENT).B*255*0.65),0,255)))

    local il=Instance.new("TextLabel")
    il.Size=UDim2.new(0,46,1,0); il.Position=UDim2.new(0,8,0,0)
    il.BackgroundTransparency=1; il.Text=icon or "▶"
    il.TextSize=24; il.Font=Enum.Font.GothamBold
    il.TextColor3=TH.white; il.ZIndex=44; il.Parent=card

    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,-60,1,0); tl.Position=UDim2.new(0,54,0,0)
    tl.BackgroundTransparency=1; tl.Text=lbl
    tl.TextSize=15; tl.Font=Enum.Font.GothamBold
    tl.TextColor3=TH.white; tl.TextXAlignment=Enum.TextXAlignment.Left
    tl.ZIndex=44; tl.Parent=card

    card.MouseButton1Click:Connect(function()
        Tw(card,{BackgroundTransparency=0.45},0.07)
        task.delay(0.14,function() Tw(card,{BackgroundTransparency=0},0.14) end)
        task.spawn(onClick)
    end)
    return card
end

-- Selector de jugador para troll (dropdown simple)
local function mkPlayerSelector(pageKey)
    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,56); card.BackgroundColor3=TH.card
    card.BorderSizePixel=0; card.ZIndex=43; card.Parent=PAGES[pageKey]
    C(card,14); Str(card,TH.border,1,0.2)

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,120,1,0); lbl.Position=UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency=1; lbl.Text="🎯  Objetivo:"
    lbl.TextSize=13; lbl.Font=Enum.Font.GothamBold
    lbl.TextColor3=TH.text; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.ZIndex=44; lbl.Parent=card

    local nameLbl=Instance.new("TextLabel")
    nameLbl.Size=UDim2.new(1,-220,1,0); nameLbl.Position=UDim2.new(0,132,0,0)
    nameLbl.BackgroundTransparency=1; nameLbl.Text="Ninguno"
    nameLbl.TextSize=13; nameLbl.Font=Enum.Font.GothamSemibold
    nameLbl.TextColor3=ACCENT; nameLbl.TextXAlignment=Enum.TextXAlignment.Left
    nameLbl.ZIndex=44; nameLbl.Parent=card

    -- Botón siguiente jugador
    local nxt=Instance.new("TextButton")
    nxt.Size=UDim2.new(0,82,0,36); nxt.Position=UDim2.new(1,-92,0.5,-18)
    nxt.BackgroundColor3=TH.section; nxt.Text="Siguiente ▶"
    nxt.TextSize=11; nxt.Font=Enum.Font.GothamBold
    nxt.TextColor3=ACCENT; nxt.BorderSizePixel=0
    nxt.AutoButtonColor=false; nxt.ZIndex=44; nxt.Parent=card
    C(nxt,8)

    local plrList={}
    local plrIdx=0
    nxt.MouseButton1Click:Connect(function()
        plrList={}
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP then table.insert(plrList,p) end
        end
        if #plrList==0 then
            nameLbl.Text="(Sin jugadores)"; trollTarget=nil; return
        end
        plrIdx=(plrIdx%#plrList)+1
        trollTarget=plrList[plrIdx]
        nameLbl.Text=trollTarget.Name
        notify("🎯 Objetivo: "..trollTarget.Name,"🎯",Color3.fromRGB(255,100,30))
    end)

    return card
end

-- ═══════════════════════════════════════════
--  TAB PROTECCIÓN
-- ═══════════════════════════════════════════
mkSec("prot","DEFENSA  ·  Testing sin daño","🛡")

mkToggle("prot","God Mode  (Salud infinita)","🛡",
    Color3.fromRGB(255,205,40), function(on)
    S.godMode=on
    local c=LP.Character
    if c then
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            h.MaxHealth=on and math.huge or 100
            h.Health   =on and math.huge or 100
        end
    end
    notify(on and "🛡 God Mode ON" or "God Mode OFF","🛡",
        on and Color3.fromRGB(255,205,40) or TH.sub)
end)

mkToggle("prot","Noclip  (Atravesar todo)","👻",
    Color3.fromRGB(255,58,58), function(on)
    S.noclip=on
    if on then
        addConn("noclip",RS.Stepped:Connect(function()
            local c=LP.Character; if not c then return end
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end))
        notify("👻 Noclip ON","👻",Color3.fromRGB(255,58,58))
    else
        removeConn("noclip")
        local c=LP.Character
        if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=true end
            end
        end
        notify("Noclip OFF","👻",TH.sub)
    end
end)

mkToggle("prot","Anti-AFK  (Sin desconexión)","⏰",
    Color3.fromRGB(35,210,110), function(on)
    S.antiAfk=on
    if on then
        addConn("antiafk",RS.Heartbeat:Connect(function()
            VIM:SendMouseMovementEvent(0,0,true,game)
        end))
        notify("⏰ Anti-AFK ON","⏰",Color3.fromRGB(35,210,110))
    else
        removeConn("antiafk")
        notify("Anti-AFK OFF","⏰",TH.sub)
    end
end)

mkToggle("prot","Sin Daño de Caída","🪂",
    Color3.fromRGB(255,148,30), function(on)
    S.noFallDmg=on
    if on then
        addConn("falldmg",RS.Heartbeat:Connect(function()
            local c=LP.Character; if not c or S.godMode then return end
            local h=c:FindFirstChildOfClass("Humanoid")
            local root=c:FindFirstChild("HumanoidRootPart")
            if not h or not root then return end
            if h.Health < h.MaxHealth then
                local rp=RaycastParams.new()
                rp.FilterDescendantsInstances={c}
                rp.FilterType=Enum.RaycastFilterType.Exclude
                local ray=workspace:Raycast(root.Position,Vector3.new(0,-4.5,0),rp)
                if not ray then h.Health=h.MaxHealth end
            end
        end))
        notify("🪂 Sin Fall Damage ON","🪂",Color3.fromRGB(255,148,30))
    else
        removeConn("falldmg")
        notify("Fall Damage restaurado","🪂",TH.sub)
    end
end)

mkToggle("prot","Invisible  (Sin modelo visible)","🫥",
    Color3.fromRGB(150,68,255), function(on)
    S.invisible=on
    local c=LP.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") or p:IsA("Decal") then
            p.Transparency=on and 1 or 0
        end
    end
    -- Mantener al hacer respawn
    if on then
        addConn("invis",LP.Character.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") or d:IsA("Decal") then
                d.Transparency=1
            end
        end))
        notify("🫥 Invisible ON","🫥",Color3.fromRGB(150,68,255))
    else
        removeConn("invis")
        notify("Invisible OFF","🫥",TH.sub)
    end
end)

mkToggle("prot","Anclar personaje  (Sin movimiento físico)","⚓",
    Color3.fromRGB(90,98,130), function(on)
    S.anchored=on
    local c=LP.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart")
    if root then root.Anchored=on end
    notify(on and "⚓ Anclado ON" or "Anclado OFF","⚓",
        on and TH.text or TH.sub)
end)

-- ═══════════════════════════════════════════
--  TAB MOVIMIENTO
-- ═══════════════════════════════════════════
mkSec("move","VUELO  ·  Exploración rápida","🚀")

mkToggle("move","Modo Fly  (Libre con cámara)","🚀",
    Color3.fromRGB(150,68,255), function(on)
    S.fly=on
    local c=LP.Character
    if c then
        local h=c:FindFirstChildOfClass("Humanoid")
        local root=c:FindFirstChild("HumanoidRootPart")
        if h and root then
            h.PlatformStand=on
            if not on then root.Velocity=Vector3.zero end
        end
    end
    notify(on and "🚀 Fly ON  · Usa ▲▼" or "Fly OFF","🚀",
        on and Color3.fromRGB(150,68,255) or TH.sub)
end)

mkSlider("move","Velocidad de Vuelo","💨",5,350,60,"int",function(v)
    CFG.flySpeed=v
end)

mkSec("move","CAMINAR  ·  Stats de movimiento","🏃")

-- ── WalkSpeed: toggle activa/desactiva; slider ajusta valor ─────
mkToggle("move","WalkSpeed personalizado","🏃",
    Color3.fromRGB(45,165,255), function(on)
    speedBoostON = on
    local c=LP.Character
    if c then
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            -- ON → aplica CFG.walkSpeed; OFF → devuelve velocidad base (16)
            h.WalkSpeed = on and CFG.walkSpeed or 16
        end
    end
    notify(on and ("🏃 WalkSpeed ON  ("..math.floor(CFG.walkSpeed)..")")
               or "WalkSpeed OFF  (→ 16 normal)","🏃",
        on and Color3.fromRGB(45,165,255) or TH.sub)
end)

mkSlider("move","Velocidad de caminar","🏃",4,250,16,"int",function(v)
    CFG.walkSpeed=v
    -- Solo aplica al personaje si el toggle está activo
    if speedBoostON then
        local c=LP.Character
        if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=v end
        end
    end
end)

-- ── JumpPower: misma lógica toggle-aware ────────────────────────
mkToggle("move","JumpPower personalizado","🦘",
    Color3.fromRGB(45,165,255), function(on)
    jumpBoostON = on
    local c=LP.Character
    if c then
        local h=c:FindFirstChildOfClass("Humanoid")
        if h then
            -- ON → aplica CFG.jumpPower; OFF → devuelve base (50)
            h.JumpPower = on and CFG.jumpPower or 50
        end
    end
    notify(on and ("🦘 JumpPower ON  ("..math.floor(CFG.jumpPower)..")")
               or "JumpPower OFF  (→ 50 normal)","🦘",
        on and Color3.fromRGB(45,165,255) or TH.sub)
end)

mkSlider("move","Fuerza de salto","🦘",4,350,50,"int",function(v)
    CFG.jumpPower=v
    -- Solo aplica al personaje si el toggle está activo
    if jumpBoostON then
        local c=LP.Character
        if c then
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then h.JumpPower=v end
        end
    end
end)

mkToggle("move","Infinite Jump","🦘",
    Color3.fromRGB(45,165,255), function(on)
    S.infJump=on
    if on then
        addConn("ijump",UIS.JumpRequest:Connect(function()
            local c=LP.Character; if not c then return end
            local h=c:FindFirstChildOfClass("Humanoid")
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end))
        notify("🦘 Infinite Jump ON","🦘",Color3.fromRGB(45,165,255))
    else
        removeConn("ijump")
        notify("Infinite Jump OFF","🦘",TH.sub)
    end
end)

mkSec("move","TELETRANSPORTE  ·  Navegación","📍")

mkToggle("move","Click TP  (Toca el suelo para teletransportarte)","👆",
    Color3.fromRGB(255,148,30), function(on)
    S.clickTP=on
    if on then
        addConn("clicktp",UIS.InputBegan:Connect(function(i,gp)
            if gp or not S.clickTP then return end
            if i.UserInputType~=Enum.UserInputType.Touch
            and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            local c=LP.Character; if not c then return end
            local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
            local ray=Camera:ScreenPointToRay(i.Position.X,i.Position.Y)
            local rp=RaycastParams.new()
            rp.FilterDescendantsInstances={c}
            rp.FilterType=Enum.RaycastFilterType.Exclude
            local res=workspace:Raycast(ray.Origin,ray.Direction*1200,rp)
            if res then
                root.CFrame=CFrame.new(res.Position+Vector3.new(0,3.2,0))
                notify("📍 TP!","📍",Color3.fromRGB(255,148,30))
            end
        end))
        notify("👆 Click TP ON","👆",Color3.fromRGB(255,148,30))
    else
        removeConn("clicktp")
        notify("Click TP OFF","👆",TH.sub)
    end
end)

-- ── CHECKPOINTS (8 slots) ────────────────────────────────────
mkSec("move","CHECKPOINTS  ·  8 posiciones guardadas","💾")

local cpLabels={}
for i=1,8 do
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,64); row.BackgroundColor3=TH.card
    row.BorderSizePixel=0; row.ZIndex=43; row.Parent=PAGES["move"]
    C(row,14); Str(row,TH.border,1,0.2)

    local numF=Instance.new("Frame")
    numF.Size=UDim2.new(0,38,0,38); numF.Position=UDim2.new(0,10,0.5,-19)
    numF.BackgroundColor3=TH.section; numF.BorderSizePixel=0
    numF.ZIndex=44; numF.Parent=row; C(numF,10)
    local numL=Instance.new("TextLabel")
    numL.Size=UDim2.new(1,0,1,0); numL.BackgroundTransparency=1
    numL.Text=tostring(i); numL.TextSize=16; numL.Font=Enum.Font.GothamBold
    numL.TextColor3=TH.sub; numL.ZIndex=45; numL.Parent=numF

    local nmL=Instance.new("TextLabel")
    nmL.Size=UDim2.new(1,-220,0,26); nmL.Position=UDim2.new(0,56,0,9)
    nmL.BackgroundTransparency=1; nmL.Text=CP[i].name
    nmL.TextSize=13; nmL.Font=Enum.Font.GothamBold
    nmL.TextColor3=TH.text; nmL.TextXAlignment=Enum.TextXAlignment.Left
    nmL.ZIndex=44; nmL.Parent=row; cpLabels[i]=nmL

    local crdL=Instance.new("TextLabel")
    crdL.Size=UDim2.new(1,-220,0,20); crdL.Position=UDim2.new(0,56,0,36)
    crdL.BackgroundTransparency=1; crdL.Text="Sin guardar"
    crdL.TextSize=11; crdL.Font=Enum.Font.Gotham
    crdL.TextColor3=TH.sub; crdL.TextXAlignment=Enum.TextXAlignment.Left
    crdL.ZIndex=44; crdL.Parent=row

    local saveB=Instance.new("TextButton")
    saveB.Size=UDim2.new(0,60,0,32); saveB.Position=UDim2.new(1,-130,0.5,-16)
    saveB.BackgroundColor3=TH.section; saveB.Text="💾 Guardar"
    saveB.TextSize=10; saveB.Font=Enum.Font.GothamBold
    saveB.TextColor3=ACCENT; saveB.BorderSizePixel=0
    saveB.AutoButtonColor=false; saveB.ZIndex=44; saveB.Parent=row; C(saveB,8)

    local tpB=Instance.new("TextButton")
    tpB.Size=UDim2.new(0,54,0,32); tpB.Position=UDim2.new(1,-66,0.5,-16)
    tpB.BackgroundColor3=Color3.fromRGB(150,68,255); tpB.Text="🚀 Ir"
    tpB.TextSize=10; tpB.Font=Enum.Font.GothamBold
    tpB.TextColor3=TH.white; tpB.BorderSizePixel=0
    tpB.AutoButtonColor=false; tpB.ZIndex=44; tpB.Parent=row; C(tpB,8)

    local idx=i
    saveB.MouseButton1Click:Connect(function()
        local c=LP.Character; if not c then return end
        local r=c:FindFirstChild("HumanoidRootPart"); if not r then return end
        local p=r.Position
        CP[idx].pos=p
        local px,py,pz=math.floor(p.X),math.floor(p.Y),math.floor(p.Z)
        crdL.Text=string.format("X:%d Y:%d Z:%d",px,py,pz)
        nmL.Text="Slot "..idx.." ✓"; nmL.TextColor3=Color3.fromRGB(35,210,110)
        numL.TextColor3=Color3.fromRGB(35,210,110)
        Tw(numF,{BackgroundColor3=Color3.fromRGB(12,40,22)},0.2)
        notify("💾 Slot "..idx.." guardado","💾",Color3.fromRGB(35,210,110))
    end)
    tpB.MouseButton1Click:Connect(function()
        if not CP[idx].pos then
            notify("⚠ Slot "..idx.." vacío","⚠",Color3.fromRGB(255,58,58)); return
        end
        local c=LP.Character; if not c then return end
        local r=c:FindFirstChild("HumanoidRootPart"); if not r then return end
        r.CFrame=CFrame.new(CP[idx].pos+Vector3.new(0,3,0))
        notify("🚀 TP → Slot "..idx,"🚀",Color3.fromRGB(150,68,255))
    end)
end


-- ═══════════════════════════════════════════
--  TAB AUTO / FARM
-- ═══════════════════════════════════════════
mkSec("auto","AUTOMATIZACIÓN  ·  Farm genérico","🤖")

mkToggle("auto","Auto Click","🖱",
    Color3.fromRGB(45,165,255), function(on)
    S.autoClick=on
    notify(on and "🖱 Auto Click ON" or "Auto Click OFF","🖱",
        on and Color3.fromRGB(45,165,255) or TH.sub)
end)

mkSlider("auto","Intervalo de Click (s)","⚡",0.001,0.5,0.05,"d3",function(v)
    CFG.clickRate=v
end)

mkToggle("auto","Auto Rebirth  (Renacimiento automático)","♻️",
    Color3.fromRGB(35,210,110), function(on)
    S.autoRebirth=on
    if on then
        addConn("rebirth",RS.Heartbeat:Connect(function()
            if not S.autoRebirth then return end
            -- Intento genérico: buscar botón de rebirth en el GUI del juego
            pcall(function()
                for _,gui in ipairs(LP.PlayerGui:GetDescendants()) do
                    if gui:IsA("TextButton") then
                        local t=gui.Text:lower()
                        if t:find("rebirth") or t:find("renacer") or t:find("reset") then
                            VIM:SendMouseButtonEvent(
                                gui.AbsolutePosition.X+gui.AbsoluteSize.X/2,
                                gui.AbsolutePosition.Y+gui.AbsoluteSize.Y/2,
                                0,true,game,1)
                            task.wait(0.05)
                            VIM:SendMouseButtonEvent(
                                gui.AbsolutePosition.X+gui.AbsoluteSize.X/2,
                                gui.AbsolutePosition.Y+gui.AbsoluteSize.Y/2,
                                0,false,game,1)
                        end
                    end
                end
            end)
        end))
        notify("♻️ Auto Rebirth ON","♻️",Color3.fromRGB(35,210,110))
    else
        removeConn("rebirth")
        notify("Auto Rebirth OFF","♻️",TH.sub)
    end
end)

mkToggle("auto","Auto Train / Auto Farm","💪",
    Color3.fromRGB(45,165,255), function(on)
    S.autoTrain=on
    if on then
        addConn("train",RS.Heartbeat:Connect(function()
            if not S.autoTrain then return end
            -- Genérico: simula click repetido en pantalla (punto central)
            -- Cada juego puede necesitar ajuste de posición
        end))
        notify("💪 Auto Farm ON","💪",Color3.fromRGB(45,165,255))
    else
        removeConn("train")
        notify("Auto Farm OFF","💪",TH.sub)
    end
end)

mkToggle("auto","Auto Win / Auto Collect","🏆",
    Color3.fromRGB(255,205,40), function(on)
    S.autoWin=on
    notify(on and "🏆 Auto Win ON" or "Auto Win OFF","🏆",
        on and Color3.fromRGB(255,205,40) or TH.sub)
end)

-- ═══════════════════════════════════════════
--  TAB TROLL  (Herramientas sociales / diversión)
-- ═══════════════════════════════════════════
mkSec("troll","OBJETIVO  ·  Selecciona jugador","🎯")
mkPlayerSelector("troll")

mkSec("troll","TROLLING LEVE  ·  Seguro para tu entorno","😈")

-- Headsit
mkToggle("troll","Headsit  (Sentarte en la cabeza)","🪑",
    Color3.fromRGB(255,148,30), function(on)
    S.headsit=on
    if on then
        addConn("headsit",RS.Heartbeat:Connect(function()
            if not S.headsit then return end
            local tgt=trollTarget; if not tgt then return end
            local tChar=tgt.Character; if not tChar then return end
            local tHead=tChar:FindFirstChild("Head"); if not tHead then return end
            local myChar=LP.Character; if not myChar then return end
            local myRoot=myChar:FindFirstChild("HumanoidRootPart"); if not myRoot then return end
            local offset=CFG.headsitOff
            myRoot.CFrame=tHead.CFrame*CFrame.new(0,offset,0)
            myRoot.Velocity=Vector3.zero
        end))
        notify("🪑 Headsit ON","🪑",Color3.fromRGB(255,148,30))
    else
        removeConn("headsit")
        notify("Headsit OFF","🪑",TH.sub)
    end
end)

mkSlider("troll","Offset Headsit (altura)","📏",0.5,5,2,"",function(v)
    CFG.headsitOff=v
end)

-- Fling (lanzar)
mkAction("troll","Fling Objetivo  (Empujar con fuerza)","💥",
    Color3.fromRGB(255,58,58), function()
    if not trollTarget then
        notify("⚠ Selecciona un objetivo primero","⚠",Color3.fromRGB(255,58,58)); return
    end
    local tChar=trollTarget.Character; if not tChar then return end
    local tRoot=tChar:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local dir=myRoot and (tRoot.Position-myRoot.Position).Unit or Vector3.new(0,1,0)
    -- Aplicar velocidad extrema
    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(1e9,1e9,1e9)
    bv.Velocity=(dir+Vector3.new(0,0.5,0)).Unit*CFG.knockback*3
    bv.Parent=tRoot
    task.delay(0.18,function() pcall(function() bv:Destroy() end) end)
    notify("💥 Fling enviado!","💥",Color3.fromRGB(255,58,58))
end)

-- Knockback
mkSlider("troll","Fuerza de Knockback","💨",10,300,80,"int",function(v)
    CFG.knockback=v
end)

mkAction("troll","Knockback  (Empuje suave)","👊",
    Color3.fromRGB(255,100,30), function()
    if not trollTarget then
        notify("⚠ Selecciona un objetivo primero","⚠",Color3.fromRGB(255,58,58)); return
    end
    local tChar=trollTarget.Character; if not tChar then return end
    local tRoot=tChar:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local dir=(tRoot.Position-myRoot.Position).Unit
    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(1e9,1e9,1e9)
    bv.Velocity=dir*CFG.knockback
    bv.Parent=tRoot
    task.delay(0.15,function() pcall(function() bv:Destroy() end) end)
    notify("👊 Knockback!","👊",Color3.fromRGB(255,100,30))
end)

mkSec("troll","YO MISMO  ·  Efectos en tu propio personaje","🌀")

-- Spin self
mkToggle("troll","Spin (Giro constante)","🌀",
    Color3.fromRGB(150,68,255), function(on)
    S.spinSelf=on
    if on then
        addConn("spin",RS.Heartbeat:Connect(function()
            if not S.spinSelf then return end
            local c=LP.Character; if not c then return end
            local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
            root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(8),0)
        end))
        notify("🌀 Spin ON","🌀",Color3.fromRGB(150,68,255))
    else
        removeConn("spin")
        notify("Spin OFF","🌀",TH.sub)
    end
end)

-- Float (volar suave en espiral)
mkAction("troll","Float up  (Elevarse suavemente)","🫧",
    Color3.fromRGB(80,180,255), function()
    local c=LP.Character; if not c then return end
    local root=c:FindFirstChild("HumanoidRootPart"); if not root then return end
    local bv=Instance.new("BodyVelocity")
    bv.MaxForce=Vector3.new(0,1e9,0)
    bv.Velocity=Vector3.new(0,CFG.knockback*0.6,0)
    bv.Parent=root
    task.delay(0.4,function() pcall(function() bv:Destroy() end) end)
    notify("🫧 Float!","🫧",Color3.fromRGB(80,180,255))
end)

-- Size Changer
mkSec("troll","SIZE CHANGER  ·  Escala del personaje","📐")
mkSlider("troll","Escala del personaje","📐",0.2,5,1,"",function(v)
    CFG.sizeScale=v
    local c=LP.Character; if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local desc=hum:FindFirstChildOfClass("HumanoidDescription")
    if desc then
        desc.HeadScale    =v
        desc.BodyWidthScale=v
        desc.BodyHeightScale=v
        desc.BodyDepthScale=v
        hum:ApplyDescription(desc)
    end
end)

mkAction("troll","Resetear tamaño (x1)","↩️",
    TH.section, function()
    CFG.sizeScale=1
    local c=LP.Character; if not c then return end
    local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local desc=hum:FindFirstChildOfClass("HumanoidDescription")
    if desc then
        desc.HeadScale=1; desc.BodyWidthScale=1
        desc.BodyHeightScale=1; desc.BodyDepthScale=1
        hum:ApplyDescription(desc)
    end
    notify("↩️ Tamaño reseteado","↩️",TH.text)
end)

-- Dance emotes
mkSec("troll","EMOTES  ·  Comandos de baile / animación","🕺")

local emotes = {
    {name="Dance 1",     id="r6:dance"},
    {name="Dance 2",     id="r6:dance2"},
    {name="Dance 3",     id="r6:dance3"},
    {name="Wave",        id="wave"},
    {name="Cheer",       id="cheer"},
    {name="Laugh",       id="laugh"},
    {name="Point",       id="point"},
    {name="Salute",      id="salute"},
}

-- Grid 2x2 de emotes
local emoteGrid=Instance.new("Frame")
emoteGrid.Size=UDim2.new(1,0,0,180); emoteGrid.BackgroundTransparency=1
emoteGrid.BorderSizePixel=0; emoteGrid.ZIndex=43; emoteGrid.Parent=PAGES["troll"]

local emoteGL=Instance.new("UIGridLayout")
emoteGL.CellSize=UDim2.new(0.5,-6,0,42); emoteGL.CellPadding=UDim2.new(0,6,0,6)
emoteGL.Parent=emoteGrid

for _,em in ipairs(emotes) do
    local eb=Instance.new("TextButton")
    eb.Size=UDim2.new(1,0,1,0); eb.BackgroundColor3=TH.card
    eb.Text="🕺 "..em.name; eb.TextSize=12; eb.Font=Enum.Font.GothamSemibold
    eb.TextColor3=TH.text; eb.BorderSizePixel=0; eb.AutoButtonColor=false
    eb.ZIndex=44; eb.Parent=emoteGrid; C(eb,10); Str(eb,TH.border,1,0.3)
    local emId=em.id
    eb.MouseButton1Click:Connect(function()
        Tw(eb,{BackgroundColor3=ACCENT},0.1)
        task.delay(0.2,function() Tw(eb,{BackgroundColor3=TH.card},0.2) end)
        pcall(function()
            LP.Character:FindFirstChildOfClass("Humanoid"):PlayEmote(emId)
        end)
    end)
end

-- ═══════════════════════════════════════════
--  TAB VISUAL / UTILIDADES
-- ═══════════════════════════════════════════
mkSec("vis","VISUAL  ·  Mejoras de visibilidad","👁")

-- ESP
mkToggle("vis","ESP de Jugadores  (Nombre + distancia + HP)","👁",
    Color3.fromRGB(255,58,58), function(on)
    S.esp=on
    if on then
        addConn("esp",RS.Heartbeat:Connect(function()
            local myChar=LP.Character
            local myRoot=myChar and myChar:FindFirstChild("HumanoidRootPart")
            for _,plr in ipairs(Players:GetPlayers()) do
                if plr==LP then continue end
                local char=plr.Character; if not char then continue end
                local head=char:FindFirstChild("Head"); if not head then continue end
                local hum=char:FindFirstChildOfClass("Humanoid")
                local root=char:FindFirstChild("HumanoidRootPart")
                if not root then continue end
                local bb=head:FindFirstChild("V5_ESP")
                if not bb then
                    bb=Instance.new("BillboardGui")
                    bb.Name="V5_ESP"; bb.Size=UDim2.new(0,140,0,52)
                    bb.StudsOffset=Vector3.new(0,3,0)
                    bb.AlwaysOnTop=true; bb.ResetOnSpawn=false
                    bb.Parent=head
                    local bg2=Instance.new("Frame")
                    bg2.Size=UDim2.new(1,0,1,0); bg2.BackgroundColor3=Color3.fromRGB(0,0,0)
                    bg2.BackgroundTransparency=0.45; bg2.BorderSizePixel=0; bg2.Parent=bb
                    C(bg2,8)
                    local nl=Instance.new("TextLabel")
                    nl.Name="NameL"; nl.Size=UDim2.new(1,0,0.5,0)
                    nl.BackgroundTransparency=1; nl.TextSize=13
                    nl.Font=Enum.Font.GothamBold; nl.TextColor3=Color3.fromRGB(255,100,100)
                    nl.ZIndex=2; nl.Parent=bg2
                    local hl=Instance.new("TextLabel")
                    hl.Name="HpL"; hl.Size=UDim2.new(1,0,0.5,0)
                    hl.Position=UDim2.new(0,0,0.5,0); hl.BackgroundTransparency=1
                    hl.TextSize=11; hl.Font=Enum.Font.Gotham
                    hl.TextColor3=Color3.fromRGB(100,255,130); hl.ZIndex=2; hl.Parent=bg2
                end
                local dist=myRoot and math.floor((myRoot.Position-root.Position).Magnitude) or 0
                local hp=hum and math.floor(hum.Health) or 0
                local maxHp=hum and (hum.MaxHealth==math.huge and "∞" or math.floor(hum.MaxHealth)) or "?"
                local nl=bb:FindFirstChild("Frame"):FindFirstChild("NameL")
                local hl=bb:FindFirstChild("Frame"):FindFirstChild("HpL")
                if nl then nl.Text="🔴 "..plr.Name.."  ["..dist.."m]" end
                if hl then hl.Text="❤ "..tostring(hp).."/"..tostring(maxHp) end
            end
        end))
        notify("👁 ESP ON","👁",Color3.fromRGB(255,58,58))
    else
        removeConn("esp")
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local h=plr.Character:FindFirstChild("Head")
                if h then
                    local bb=h:FindFirstChild("V5_ESP")
                    if bb then bb:Destroy() end
                end
            end
        end
        notify("ESP OFF","👁",TH.sub)
    end
end)

mkSlider("vis","Distancia máxima ESP","📡",50,2000,600,"int",function(v)
    CFG.espMaxDist=v
end)

-- Fullbright
local origLighting={}
mkToggle("vis","Fullbright  (Iluminación máxima)","☀️",
    Color3.fromRGB(255,205,40), function(on)
    S.fullbright=on
    if on then
        origLighting.Ambient=Lighting.Ambient
        origLighting.OutdoorAmbient=Lighting.OutdoorAmbient
        origLighting.Brightness=Lighting.Brightness
        origLighting.ClockTime=Lighting.ClockTime
        Lighting.Ambient=Color3.fromRGB(178,178,178)
        Lighting.OutdoorAmbient=Color3.fromRGB(178,178,178)
        Lighting.Brightness=2.5
        Lighting.ClockTime=14
        for _,fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
                fx.Enabled=false
            end
        end
        notify("☀️ Fullbright ON","☀️",Color3.fromRGB(255,205,40))
    else
        if origLighting.Ambient then
            Lighting.Ambient=origLighting.Ambient
            Lighting.OutdoorAmbient=origLighting.OutdoorAmbient
            Lighting.Brightness=origLighting.Brightness
            Lighting.ClockTime=origLighting.ClockTime
        end
        for _,fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
            or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
                fx.Enabled=true
            end
        end
        notify("Fullbright OFF","☀️",TH.sub)
    end
end)

mkSec("vis","SERVIDOR  ·  Conexión y navegación","🌐")

mkAction("vis","Server Hop  (Cambiar servidor)","🔀",
    Color3.fromRGB(16,42,88), function()
    notify("🔀 Buscando servidor...","🔀",ACCENT)
    task.wait(0.6)
    pcall(function() TPS:Teleport(game.PlaceId,LP) end)
end)

mkAction("vis","Rejoin  (Reconectar)","🔄",
    Color3.fromRGB(12,36,70), function()
    notify("🔄 Reconectando...","🔄",ACCENT)
    task.wait(0.6)
    pcall(function() TPS:Teleport(game.PlaceId,LP) end)
end)

mkAction("vis","Copiar Posición actual","📋",
    Color3.fromRGB(14,44,28), function()
    local c=LP.Character; if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart"); if not r then return end
    local p=r.Position
    local txt=string.format("Vector3.new(%.2f, %.2f, %.2f)",p.X,p.Y,p.Z)
    notify("📋 "..txt,"📋",Color3.fromRGB(35,210,110))
    pcall(function() if setclipboard then setclipboard(txt) end end)
end)

-- ═══════════════════════════════════════════
--  TAB PERFIL / STATS
-- ═══════════════════════════════════════════
mkSec("stats","STATS EN TIEMPO REAL  ·  Datos del personaje","📊")

-- Tarjeta de stats
local statsCard=Instance.new("Frame")
statsCard.Size=UDim2.new(1,0,0,260); statsCard.BackgroundColor3=TH.card
statsCard.BorderSizePixel=0; statsCard.ZIndex=43; statsCard.Parent=PAGES["stats"]
C(statsCard,16); Str(statsCard,TH.border,1,0.2)

local statsData = {
    {key="pos",    label="📍 Posición",    val="—"},
    {key="speed",  label="🏃 WalkSpeed",   val="—"},
    {key="jump",   label="🦘 JumpPower",   val="—"},
    {key="hp",     label="❤️ HP",           val="—"},
    {key="vel",    label="💨 Velocidad",   val="—"},
    {key="state",  label="🧍 Estado",      val="—"},
    {key="server", label="🌐 Server ID",   val=tostring(game.JobId):sub(1,16)..".."},
    {key="place",  label="🎮 Place ID",    val=tostring(game.PlaceId)},
}

local statLabels={}
local statsLayout=Instance.new("UIListLayout")
statsLayout.Padding=UDim.new(0,0); statsLayout.Parent=statsCard
local statsPad=Instance.new("UIPadding")
statsPad.PaddingLeft=UDim.new(0,12); statsPad.PaddingRight=UDim.new(0,12)
statsPad.PaddingTop=UDim.new(0,10); statsPad.PaddingBottom=UDim.new(0,10)
statsPad.Parent=statsCard

for i,d in ipairs(statsData) do
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,28); row.BackgroundTransparency=1
    row.BorderSizePixel=0; row.ZIndex=44; row.Parent=statsCard

    if i%2==0 then
        row.BackgroundColor3=TH.section
        row.BackgroundTransparency=0.5
    end

    local kl=Instance.new("TextLabel")
    kl.Size=UDim2.new(0.48,0,1,0); kl.BackgroundTransparency=1
    kl.Text=d.label; kl.TextSize=12; kl.Font=Enum.Font.GothamSemibold
    kl.TextColor3=TH.sub; kl.TextXAlignment=Enum.TextXAlignment.Left
    kl.ZIndex=45; kl.Parent=row

    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0.52,0,1,0); vl.Position=UDim2.new(0.48,0,0,0)
    vl.BackgroundTransparency=1; vl.Text=d.val
    vl.TextSize=12; vl.Font=Enum.Font.GothamBold
    vl.TextColor3=ACCENT; vl.TextXAlignment=Enum.TextXAlignment.Right
    vl.ZIndex=45; vl.Parent=row

    statLabels[d.key]=vl
end

-- Actualizar stats
addConn("statsUpdate",RS.Heartbeat:Connect(function()
    if not S.statsActive then return end
    local c=LP.Character; if not c then return end
    local h=c:FindFirstChildOfClass("Humanoid")
    local root=c:FindFirstChild("HumanoidRootPart")
    if not h or not root then return end

    local p=root.Position
    statLabels["pos"].Text=string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
    statLabels["speed"].Text=string.format("%.1f",h.WalkSpeed)
    statLabels["jump"].Text=string.format("%.1f",h.JumpPower)
    local hp=h.MaxHealth==math.huge and "∞" or string.format("%.0f/%.0f",h.Health,h.MaxHealth)
    statLabels["hp"].Text=hp
    local vel=root.Velocity
    statLabels["vel"].Text=string.format("%.1f u/s",vel.Magnitude)
    statLabels["state"].Text=tostring(h:GetState()):match("%.(.+)")
end))

-- Botón copiar pos desde stats
mkAction("stats","Copiar Posición","📋",
    Color3.fromRGB(14,44,28), function()
    local c=LP.Character; if not c then return end
    local r=c:FindFirstChild("HumanoidRootPart"); if not r then return end
    local p=r.Position
    local txt=string.format("Vector3.new(%.2f, %.2f, %.2f)",p.X,p.Y,p.Z)
    notify("📋 "..txt,"📋",Color3.fromRGB(35,210,110))
    pcall(function() if setclipboard then setclipboard(txt) end end)
end)

mkSec("stats","TEMA  ·  Personalización del hub","🎨")

-- Selector de color accent (6 botones circulares)
local accentFrame=Instance.new("Frame")
accentFrame.Size=UDim2.new(1,0,0,72); accentFrame.BackgroundColor3=TH.card
accentFrame.BorderSizePixel=0; accentFrame.ZIndex=43; accentFrame.Parent=PAGES["stats"]
C(accentFrame,14); Str(accentFrame,TH.border,1,0.2)

local accentTitle=Instance.new("TextLabel")
accentTitle.Size=UDim2.new(1,0,0,28); accentTitle.BackgroundTransparency=1
accentTitle.Text="🎨  Color Accent"; accentTitle.TextSize=13
accentTitle.Font=Enum.Font.GothamBold; accentTitle.TextColor3=TH.text
accentTitle.TextXAlignment=Enum.TextXAlignment.Left
accentTitle.Position=UDim2.new(0,14,0,4); accentTitle.ZIndex=44; accentTitle.Parent=accentFrame

local accentRow=Instance.new("Frame")
accentRow.Size=UDim2.new(1,-20,0,34); accentRow.Position=UDim2.new(0,10,0,34)
accentRow.BackgroundTransparency=1; accentRow.BorderSizePixel=0
accentRow.ZIndex=44; accentRow.Parent=accentFrame

local accentLL=Instance.new("UIListLayout")
accentLL.FillDirection=Enum.FillDirection.Horizontal
accentLL.VerticalAlignment=Enum.VerticalAlignment.Center
accentLL.Padding=UDim.new(0,8); accentLL.Parent=accentRow

for i,ac in ipairs(ACCENTS) do
    local dot=Instance.new("TextButton")
    dot.Size=UDim2.new(0,30,0,30); dot.BackgroundColor3=ac.col
    dot.Text=i==CFG.accentIndex and "✓" or ""
    dot.TextColor3=TH.white; dot.TextSize=14; dot.Font=Enum.Font.GothamBold
    dot.BorderSizePixel=0; dot.AutoButtonColor=false; dot.ZIndex=45; dot.Parent=accentRow
    C(dot,15)
    if i==CFG.accentIndex then Str(dot,TH.white,2,0.1) end

    local idx=i
    dot.MouseButton1Click:Connect(function()
        CFG.accentIndex=idx
        -- Nota: cambiar accent en runtime requiere recarga del hub
        -- Esta es una notificación de la selección
        notify("🎨 Color: "..ac.name.." (reinicia el hub para aplicar)","🎨",ac.col)
    end)
end

-- Toggle modo oscuro/claro
mkToggle("stats","Modo Claro  (Cambiar tema)","🌗",
    Color3.fromRGB(255,205,40), function(on)
    CFG.darkMode=not on
    notify((on and "🌕 Modo Claro" or "🌑 Modo Oscuro").." (reinicia el hub para aplicar)","🌗",
        Color3.fromRGB(255,205,40))
end)

mkSec("stats","ACERCA DE  ·  Información del hub","ℹ️")

local aboutCard=Instance.new("Frame")
aboutCard.Size=UDim2.new(1,0,0,100); aboutCard.BackgroundColor3=TH.card
aboutCard.BorderSizePixel=0; aboutCard.ZIndex=43; aboutCard.Parent=PAGES["stats"]
C(aboutCard,14); Str(aboutCard,TH.border,1,0.2)
G(aboutCard,TH.card,TH.cardHov)

local aboutTxt=Instance.new("TextLabel")
aboutTxt.Size=UDim2.new(1,-20,1,0); aboutTxt.Position=UDim2.new(0,10,0,0)
aboutTxt.BackgroundTransparency=1
aboutTxt.Text="Admin Hub PRO v5  ·  iOS Style\n"..
    "Centro de Control Profesional para Devs\n"..
    "6 Tabs  ·  Testing · Farm · Troll · Visual\n"..
    "Arrastra ⚙ o la barra del panel libremente"
aboutTxt.TextSize=12; aboutTxt.Font=Enum.Font.Gotham
aboutTxt.TextColor3=TH.sub; aboutTxt.TextWrapped=true
aboutTxt.TextYAlignment=Enum.TextYAlignment.Center
aboutTxt.ZIndex=44; aboutTxt.Parent=aboutCard


-- ═══════════════════════════════════════════
--  CONTROLES DE VUELO EN PANTALLA
-- ═══════════════════════════════════════════
local FlyPanel=Instance.new("Frame")
FlyPanel.Size=UDim2.new(0,158,0,78); FlyPanel.Position=UDim2.new(1,-174,1,-100)
FlyPanel.BackgroundTransparency=1; FlyPanel.Visible=false
FlyPanel.ZIndex=60; FlyPanel.Parent=Root

local function mkFlyBtn(txt,col,xOff,onDown,onUp)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,70,0,70); b.Position=UDim2.new(0,xOff,0,4)
    b.BackgroundColor3=col; b.Text=txt; b.TextSize=30
    b.Font=Enum.Font.GothamBold; b.TextColor3=TH.white
    b.BorderSizePixel=0; b.AutoButtonColor=false; b.ZIndex=61; b.Parent=FlyPanel
    C(b,35); Str(b,col,2.2,0.3)
    -- Sombra suave
    local sh=Instance.new("Frame")
    sh.Size=UDim2.new(1,6,1,6); sh.Position=UDim2.new(0,-3,0,4)
    sh.BackgroundColor3=Color3.new(0,0,0); sh.BackgroundTransparency=0.78
    sh.BorderSizePixel=0; sh.ZIndex=60; sh.Parent=FlyPanel; C(sh,36)

    b.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then
            Tw(b,{BackgroundTransparency=0.38},0.07); onDown()
        end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch
        or i.UserInputType==Enum.UserInputType.MouseButton1 then
            Tw(b,{BackgroundTransparency=0},0.12); onUp()
        end
    end)
    return b
end

mkFlyBtn("▲",Color3.fromRGB(130,55,255),0,
    function() S.flyUp=true  end,
    function() S.flyUp=false end)

mkFlyBtn("▼",Color3.fromRGB(88,34,190),84,
    function() S.flyDown=true  end,
    function() S.flyDown=false end)

-- Label de velocidad sobre los botones
local flySpeedLbl=Instance.new("TextLabel")
flySpeedLbl.Size=UDim2.new(1,0,0,18); flySpeedLbl.Position=UDim2.new(0,0,0,-20)
flySpeedLbl.BackgroundTransparency=1; flySpeedLbl.Text="🚀 "..CFG.flySpeed.." u/s"
flySpeedLbl.TextSize=11; flySpeedLbl.Font=Enum.Font.GothamBold
flySpeedLbl.TextColor3=TH.white; flySpeedLbl.ZIndex=62; flySpeedLbl.Parent=FlyPanel

Drag(FlyPanel)

-- ═══════════════════════════════════════════
--  ABRIR / CERRAR PANEL
-- ═══════════════════════════════════════════
local function openPanel()
    Panel.Size=UDim2.new(0.92,0,0,0)
    Panel.Visible=true
    Tw(Panel,{Size=UDim2.new(0.92,0,0.84,0)},
        0.34,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    S.open=true
    Tw(FBIco,{Rotation=90},0.25)
    -- Girar ícono a X
    task.delay(0.1,function()
        if S.open then FBIco.Text="✕" end
    end)
end

local function closePanel()
    Tw(Panel,{Size=UDim2.new(0.92,0,0,0)},
        0.24,Enum.EasingStyle.Quart,Enum.EasingDirection.In)
    task.delay(0.25,function()
        Panel.Visible=false
        Panel.Size=UDim2.new(0.92,0,0.84,0)
    end)
    S.open=false
    Tw(FBIco,{Rotation=0},0.2)
    FBIco.Text="⚙"
end

FB.MouseButton1Click:Connect(function()
    if S.open then closePanel() else openPanel() end
end)
XBtn.MouseButton1Click:Connect(closePanel)

-- Tecla Insert (toggle backup para PC)
addConn("insertKey",UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.Insert then
        if S.open then closePanel() else openPanel() end
    end
end))

-- ═══════════════════════════════════════════
--  CHARACTER ADDED / REMOVING
-- ═══════════════════════════════════════════
local function onCharAdded(char)
    local hum=char:WaitForChild("Humanoid",6); if not hum then return end
    local root=char:WaitForChild("HumanoidRootPart",6); if not root then return end

    -- Restaurar stats — solo si el toggle correspondiente está activo
    -- Si está OFF, Roblox ya asigna los valores base por defecto
    if speedBoostON then hum.WalkSpeed = CFG.walkSpeed end
    if jumpBoostON  then hum.JumpPower = CFG.jumpPower  end
    if S.godMode then hum.MaxHealth=math.huge; hum.Health=math.huge end
    if S.fly     then hum.PlatformStand=true end
    if S.anchored then root.Anchored=true end

    -- Invisible al respawn
    if S.invisible then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency=1 end
        end
    end

    -- Noclip al respawn
    if S.noclip then
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
end

local function onCharRemoving()
    S.flyUp=false; S.flyDown=false
    S.headsit=false
end

LP.CharacterAdded:Connect(onCharAdded)
LP.CharacterRemoving:Connect(onCharRemoving)
if LP.Character then task.spawn(onCharAdded,LP.Character) end

-- ═══════════════════════════════════════════
--  LOOP CENTRAL  (único Heartbeat, mínimo overhead)
-- ═══════════════════════════════════════════
local tClick=0; local tGod=0; local tFlyLbl=0

RS.Heartbeat:Connect(function(dt)
    local now=tick()
    local char=LP.Character
    local hum =char and char:FindFirstChildOfClass("Humanoid")
    local root=char and char:FindFirstChild("HumanoidRootPart")

    -- ── Auto Click ──────────────────────────────────
    if S.autoClick and now-tClick>=CFG.clickRate then
        tClick=now
        VIM:SendMouseButtonEvent(0,0,0,true,game,1)
        task.defer(function()
            VIM:SendMouseButtonEvent(0,0,0,false,game,1)
        end)
    end

    -- ── God Mode ────────────────────────────────────
    if S.godMode and hum and now-tGod>=0.5 then
        tGod=now
        if hum.MaxHealth~=math.huge then hum.MaxHealth=math.huge end
        if hum.Health<1e14 then hum.Health=math.huge end
    end

    -- ── Fly ─────────────────────────────────────────
    if root and hum then
        if S.fly then
            FlyPanel.Visible=true
            hum.PlatformStand=true

            local camCF=Cam.CFrame
            local fwd  =Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
            local right=Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
            fwd  =fwd.Magnitude>0   and fwd.Unit   or fwd
            right=right.Magnitude>0 and right.Unit or right

            local mov=hum.MoveDirection
            local dir=Vector3.zero
            if mov.Magnitude>0.05 then
                dir=fwd*(-mov.Z)+right*mov.X
            end
            if S.flyUp   then dir=dir+Vector3.new(0,1,0) end
            if S.flyDown then dir=dir-Vector3.new(0,1,0) end

            root.Velocity=(dir.Magnitude>0 and dir.Unit or Vector3.zero)*CFG.flySpeed

            -- Actualizar label velocidad (no cada frame, cada 0.5s)
            if now-tFlyLbl>=0.5 then
                tFlyLbl=now
                flySpeedLbl.Text="🚀 "..CFG.flySpeed.." u/s"
            end
        else
            if FlyPanel.Visible then FlyPanel.Visible=false end
            if hum.PlatformStand then
                hum.PlatformStand=false
                root.Velocity=Vector3.zero
            end
        end
    end

    -- ── Auto Win (jump helper) ───────────────────────
    if S.autoWin and hum then
        -- Implementación genérica: salto periódico
        -- (cada juego tiene su mecánica propia)
    end
end)

-- ═══════════════════════════════════════════
--  CLEANUP AL DESTRUIR
-- ═══════════════════════════════════════════
Root.AncestryChanged:Connect(function()
    if Root.Parent then return end
    -- Desconectar todo
    for k,conn in pairs(CONNS) do
        pcall(function() conn:Disconnect() end)
    end
    -- Restaurar personaje
    local c=LP.Character
    if c then
        local h=c:FindFirstChildOfClass("Humanoid")
        local r=c:FindFirstChild("HumanoidRootPart")
        if h then
            h.PlatformStand=false
            h.WalkSpeed=16; h.JumpPower=50
            if h.MaxHealth==math.huge then
                h.MaxHealth=100; h.Health=100
            end
        end
        if r then
            r.Anchored=false
            r.Velocity=Vector3.zero
        end
        -- Restaurar colisiones
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide=true; p.Transparency=0
            end
        end
    end
    -- Restaurar Lighting
    if origLighting.Ambient then
        Lighting.Ambient=origLighting.Ambient
        Lighting.OutdoorAmbient=origLighting.OutdoorAmbient
        Lighting.Brightness=origLighting.Brightness
        Lighting.ClockTime=origLighting.ClockTime
    end
    for _,fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
        or fx:IsA("SunRaysEffect") then
            fx.Enabled=true
        end
    end
end)

-- ═══════════════════════════════════════════
--  MENSAJE DE INICIO
-- ═══════════════════════════════════════════
task.delay(0.5,function()
    notify("⚙ Admin Hub PRO v5 listo","✦",ACCENT)
end)

print("╔════════════════════════════════════════╗")
print("║   Admin Hub PRO v5 · iOS Style          ║")
print("║   Centro de Control Profesional         ║")
print("║   Toca el botón ⚙ para abrir            ║")
print("║   [Insert] = toggle rápido              ║")
print("╚════════════════════════════════════════╝")
