-- Kaelen --
-- Asistente IA Premium para Roblox
-- Orquestador: Qwen3 Coder + Llama 3.3 70B via OpenRouter
-- Version: 2.0 | By: Kaelen Systems

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
--  CONFIGURACIÓN GLOBAL
-- ============================================================
local CONFIG = {
    Version = "2.0",
    AppName = "Kaelen",
    Author = "Kaelen Systems",
    OpenRouterBase = "https://openrouter.ai/api/v1/chat/completions",
    Models = {
        Coder  = "qwen/qwen3-coder",
        Reason = "meta-llama/llama-3.3-70b-instruct",
    },
    MaxTokens = 1200,
    Temperature = 0.7,
    MaxHistory = 40,
    -- Paleta
    Colors = {
        BG          = Color3.fromRGB(10, 10, 18),
        Surface     = Color3.fromRGB(18, 18, 30),
        Card        = Color3.fromRGB(24, 24, 40),
        Border      = Color3.fromRGB(60, 60, 100),
        Accent      = Color3.fromRGB(120, 80, 255),
        AccentSoft  = Color3.fromRGB(80, 50, 180),
        UserBubble  = Color3.fromRGB(100, 60, 240),
        AIBubble    = Color3.fromRGB(28, 28, 48),
        Text        = Color3.fromRGB(230, 230, 255),
        TextMuted   = Color3.fromRGB(130, 130, 180),
        Green       = Color3.fromRGB(80, 220, 140),
        Red         = Color3.fromRGB(255, 80, 100),
        White       = Color3.fromRGB(255, 255, 255),
    },
    Font = Enum.Font.GothamBold,
    FontReg = Enum.Font.Gotham,
}

-- ============================================================
--  ESTADO
-- ============================================================
local State = {
    APIKey       = "",
    KeyVerified  = false,
    IsOpen       = false,
    IsThinking   = false,
    Messages     = {},          -- historial de chat
    CurrentMode  = "Analista",  -- Programador | Analista | Creativo | Troll
    CustomSysPrompt = "",
    CurrentTab   = "Chat",
    ThinkDots    = 0,
    DragOffset   = Vector2.new(0, 0),
    IsDragging   = false,
}

-- ============================================================
--  SYSTEM PROMPTS POR MODO
-- ============================================================
local SYSTEM_PROMPTS = {
    Programador = [[Eres Kaelen, un experto élite en Lua y Roblox scripting.
Tu misión: generar, optimizar y debugear scripts Lua para Roblox con la máxima calidad.
- Siempre usa código limpio, comentado y modular.
- Detecta vulnerabilidades, memory leaks y race conditions.
- Explica cada solución con claridad técnica.
- Cuando generes scripts, usa bloques de código Lua correctamente formateados.
- Actúa como desarrollador senior con 15 años de experiencia en Roblox.]],

    Analista = [[Eres Kaelen, un analista de sistemas de juegos Roblox de élite.
Tu misión: analizar mecánicas, detectar vulnerabilidades, evaluar rendimiento y dar insights profundos.
- Analiza el contexto del juego cuando se te proporcione.
- Detecta posibles exploits, problemas de balanceo y errores de diseño.
- Da recomendaciones concretas y accionables.
- Combina análisis técnico con visión de game design.
- Sé directo, preciso y exhaustivo.]],

    Creativo = [[Eres Kaelen, un genio creativo especializado en diseño de juegos Roblox.
Tu misión: generar ideas innovadoras, mecánicas únicas y conceptos originales.
- Piensa fuera de la caja con propuestas sorprendentes.
- Combina géneros, mecánicas y estilos de forma inesperada.
- Da descripciones vívidas y detalladas de cada idea.
- Inspírate en los mejores juegos del mundo para crear algo único en Roblox.]],

    Troll = [[Eres Kaelen en modo Troll, especialista en mecánicas de juego caóticas y divertidas.
Tu misión: sugerir trolleos creativos, graciosos y SEGUROS (sin exploits, sin ban).
- Solo mecánicas dentro del juego, sin modificaciones externas.
- Enfócate en situaciones cómicas, sorpresas y reacciones divertidas.
- Mantén todo en el espíritu de diversión sana.
- Da ideas detalladas y ejecutables legítimamente.]],
}

-- ============================================================
--  UTILIDADES
-- ============================================================
local function Tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.Colors.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function MakePadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 8)
    p.PaddingBottom = UDim.new(0, bottom or 8)
    p.PaddingLeft   = UDim.new(0, left   or 8)
    p.PaddingRight  = UDim.new(0, right  or 8)
    p.Parent = parent
    return p
end

local function GetGameContext()
    local info = {
        GameName     = game.Name or "Desconocido",
        PlaceId      = game.PlaceId or 0,
        JobId        = game.JobId or "N/A",
        PlayerCount  = #Players:GetPlayers(),
        LocalPlayer  = LocalPlayer.Name,
        Character    = LocalPlayer.Character and "Presente" or "Ausente",
    }
    local services = {}
    for _, s in ipairs({"ReplicatedStorage","ServerStorage","Workspace","StarterGui","StarterPack"}) do
        pcall(function()
            local svc = game:GetService(s)
            if svc then table.insert(services, s..":"..#svc:GetChildren().." hijos") end
        end)
    end
    info.Services = table.concat(services, ", ")
    return HttpService:JSONEncode(info)
end

-- ============================================================
--  HTTP / OPENROUTER
-- ============================================================
local function CallOpenRouter(model, messages, sysPrompt)
    if not State.KeyVerified or State.APIKey == "" then
        return nil, "API Key no verificada"
    end
    local body = {
        model       = model,
        max_tokens  = CONFIG.MaxTokens,
        temperature = CONFIG.Temperature,
        messages    = messages,
    }
    if sysPrompt and sysPrompt ~= "" then
        table.insert(body.messages, 1, {role="system", content=sysPrompt})
    end
    local ok, res = pcall(function()
        return syn and syn.request or (http and http.request) or
               (request) or nil
    end)
    local reqFunc = ok and res or nil
    if not reqFunc then
        -- fallback HttpService (solo funciona en exploits con http habilitado)
        return nil, "No se encontró función HTTP compatible"
    end
    local response = reqFunc({
        Url = CONFIG.OpenRouterBase,
        Method = "POST",
        Headers = {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. State.APIKey,
            ["HTTP-Referer"]  = "https://roblox.com",
            ["X-Title"]       = "Kaelen AI",
        },
        Body = HttpService:JSONEncode(body),
    })
    if not response or response.StatusCode ~= 200 then
        local code = response and response.StatusCode or "sin respuesta"
        return nil, "Error HTTP " .. tostring(code)
    end
    local data = HttpService:JSONDecode(response.Body)
    if data and data.choices and data.choices[1] then
        return data.choices[1].message.content, nil
    end
    return nil, "Respuesta inesperada del servidor"
end

-- Verificar API Key (llamada ligera)
local function VerifyAPIKey(key)
    local tempKey = State.APIKey
    State.APIKey = key
    State.KeyVerified = true  -- temporal para que pase el check
    local testMsg = {{role="user", content="Di solo: OK"}}
    local res, err = CallOpenRouter(CONFIG.Models.Reason, testMsg, "Responde solo 'OK'.")
    if err then
        State.APIKey = tempKey
        State.KeyVerified = false
        return false, err
    end
    State.KeyVerified = true
    return true, nil
end

-- Orquestador: combina Coder + Reason
local function OrchestrateKaelen(userMessage, history)
    local sysPrompt = State.CustomSysPrompt ~= "" and State.CustomSysPrompt
                      or SYSTEM_PROMPTS[State.CurrentMode]
    
    -- Detectar si es petición de código
    local isCode = userMessage:lower():match("script") or
                   userMessage:lower():match("lua") or
                   userMessage:lower():match("código") or
                   userMessage:lower():match("codigo") or
                   userMessage:lower():match("función") or
                   userMessage:lower():match("funcion") or
                   userMessage:lower():match("crea") or
                   userMessage:lower():match("genera") or
                   userMessage:lower():match("optimiza") or
                   userMessage:lower():match("debug")

    -- Construir historial para la API
    local apiMessages = {}
    for _, m in ipairs(history) do
        table.insert(apiMessages, {role = m.role, content = m.content})
    end
    table.insert(apiMessages, {role = "user", content = userMessage})

    local finalResponse = ""

    if isCode or State.CurrentMode == "Programador" then
        -- Modo código: primero Coder, luego Reason refina
        local coderSys = SYSTEM_PROMPTS.Programador .. "\n\nEres el componente de código de Kaelen. Genera el script Lua solicitado con calidad máxima."
        local codeRes, codeErr = CallOpenRouter(CONFIG.Models.Coder, apiMessages, coderSys)
        if codeErr then
            -- Fallback solo a Reason
            local res, err = CallOpenRouter(CONFIG.Models.Reason, apiMessages, sysPrompt)
            if err then return nil, err end
            finalResponse = res
        else
            -- Reason refina y añade análisis
            local refineMessages = {
                {role = "user", content = "El componente Coder de Kaelen generó esto:\n\n" .. codeRes .. "\n\nPetición original del usuario: " .. userMessage .. "\n\nRefina, analiza vulnerabilidades si las hay, y presenta la respuesta final de forma clara y completa como Kaelen."}
            }
            local refinedRes, _ = CallOpenRouter(CONFIG.Models.Reason, refineMessages, sysPrompt)
            finalResponse = refinedRes or codeRes
        end
    else
        -- Modo razonamiento/análisis: principalmente Reason con contexto
        local res, err = CallOpenRouter(CONFIG.Models.Reason, apiMessages, sysPrompt)
        if err then return nil, err end
        finalResponse = res
    end

    return finalResponse, nil
end

-- ============================================================
--  CONSTRUCCIÓN DE UI
-- ============================================================

-- Limpiar instancia anterior si existe
pcall(function()
    if CoreGui:FindFirstChild("KaelenUI") then
        CoreGui:FindFirstChild("KaelenUI"):Destroy()
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KaelenUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ============================================================
--  BOTÓN FLOTANTE
-- ============================================================
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "FloatBtn"
FloatBtn.Size = UDim2.new(0, 58, 0, 58)
FloatBtn.Position = UDim2.new(1, -80, 0.5, -29)
FloatBtn.BackgroundColor3 = CONFIG.Colors.Accent
FloatBtn.Text = ""
FloatBtn.ZIndex = 100
FloatBtn.Parent = ScreenGui

MakeCorner(FloatBtn, 29)
MakeStroke(FloatBtn, Color3.fromRGB(160, 120, 255), 2)

-- Glow del botón
local BtnGlow = Instance.new("ImageLabel")
BtnGlow.Size = UDim2.new(1.6, 0, 1.6, 0)
BtnGlow.Position = UDim2.new(-0.3, 0, -0.3, 0)
BtnGlow.BackgroundTransparency = 1
BtnGlow.Image = "rbxassetid://5028857084"
BtnGlow.ImageColor3 = CONFIG.Colors.Accent
BtnGlow.ImageTransparency = 0.5
BtnGlow.ZIndex = 99
BtnGlow.Parent = FloatBtn

local BtnIcon = Instance.new("TextLabel")
BtnIcon.Size = UDim2.new(1, 0, 1, 0)
BtnIcon.BackgroundTransparency = 1
BtnIcon.Text = "K"
BtnIcon.TextColor3 = CONFIG.Colors.White
BtnIcon.TextSize = 22
BtnIcon.Font = CONFIG.Font
BtnIcon.ZIndex = 101
BtnIcon.Parent = FloatBtn

-- Pulso animado del botón
local function PulseButton()
    while true do
        Tween(BtnGlow, {ImageTransparency = 0.2}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
        Tween(BtnGlow, {ImageTransparency = 0.7}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.2)
    end
end
task.spawn(PulseButton)

-- Arrastre del botón flotante
local btnDragging = false
local btnDragStart, btnStartPos

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragStart = input.Position
        btnStartPos = FloatBtn.Position
    end
end)

FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                        input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnDragStart
        FloatBtn.Position = UDim2.new(
            btnStartPos.X.Scale,
            btnStartPos.X.Offset + delta.X,
            btnStartPos.Y.Scale,
            btnStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
--  VENTANA PRINCIPAL
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 380, 0, 580)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -290)
MainFrame.BackgroundColor3 = CONFIG.Colors.BG
MainFrame.BackgroundTransparency = 0.05
MainFrame.ClipsDescendants = true
MainFrame.Visible = false
MainFrame.ZIndex = 50
MainFrame.Parent = ScreenGui

MakeCorner(MainFrame, 20)
MakeStroke(MainFrame, Color3.fromRGB(80, 60, 140), 1.5)

-- Gradiente de fondo
local BGGrad = Instance.new("UIGradient")
BGGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 10, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 20)),
})
BGGrad.Rotation = 135
BGGrad.Parent = MainFrame

-- Efecto gloss top
local GlossTop = Instance.new("Frame")
GlossTop.Size = UDim2.new(1, 0, 0, 2)
GlossTop.Position = UDim2.new(0, 0, 0, 0)
GlossTop.BackgroundColor3 = Color3.fromRGB(140, 100, 255)
GlossTop.BackgroundTransparency = 0.3
GlossTop.BorderSizePixel = 0
GlossTop.ZIndex = 51
GlossTop.Parent = MainFrame

-- ============================================================
--  HEADER
-- ============================================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 56)
Header.BackgroundColor3 = CONFIG.Colors.Surface
Header.BackgroundTransparency = 0.3
Header.ZIndex = 52
Header.Parent = MainFrame

MakeCorner(Header, 20)
local HeaderStroke = MakeStroke(Header, Color3.fromRGB(70, 50, 120), 1)

local HeaderGrad = Instance.new("UIGradient")
HeaderGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 60)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 12, 35)),
})
HeaderGrad.Rotation = 90
HeaderGrad.Parent = Header

-- Logo K
local LogoCircle = Instance.new("Frame")
LogoCircle.Size = UDim2.new(0, 34, 0, 34)
LogoCircle.Position = UDim2.new(0, 12, 0.5, -17)
LogoCircle.BackgroundColor3 = CONFIG.Colors.Accent
LogoCircle.ZIndex = 53
LogoCircle.Parent = Header
MakeCorner(LogoCircle, 17)

local LogoText = Instance.new("TextLabel")
LogoText.Size = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text = "K"
LogoText.TextColor3 = CONFIG.Colors.White
LogoText.TextSize = 16
LogoText.Font = CONFIG.Font
LogoText.ZIndex = 54
LogoText.Parent = LogoCircle

-- Título
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 160, 0, 20)
TitleLabel.Position = UDim2.new(0, 56, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Kaelen"
TitleLabel.TextColor3 = CONFIG.Colors.White
TitleLabel.TextSize = 17
TitleLabel.Font = CONFIG.Font
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 53
TitleLabel.Parent = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(0, 200, 0, 16)
SubLabel.Position = UDim2.new(0, 56, 0, 30)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "AI Systems v2.0 • " .. State.CurrentMode
SubLabel.TextColor3 = CONFIG.Colors.TextMuted
SubLabel.TextSize = 11
SubLabel.Font = CONFIG.FontReg
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.ZIndex = 53
SubLabel.Parent = Header

-- Botón cerrar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
CloseBtn.BackgroundTransparency = 0.3
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = CONFIG.Colors.White
CloseBtn.TextSize = 13
CloseBtn.Font = CONFIG.Font
CloseBtn.ZIndex = 54
CloseBtn.Parent = Header
MakeCorner(CloseBtn, 16)

-- Indicador de estado
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -56, 0.5, -4)
StatusDot.BackgroundColor3 = CONFIG.Colors.Red
StatusDot.ZIndex = 54
StatusDot.Parent = Header
MakeCorner(StatusDot, 4)

-- ============================================================
--  TABS
-- ============================================================
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 36)
TabBar.Position = UDim2.new(0, 12, 0, 60)
TabBar.BackgroundColor3 = CONFIG.Colors.Card
TabBar.BackgroundTransparency = 0.2
TabBar.ZIndex = 52
TabBar.Parent = MainFrame
MakeCorner(TabBar, 10)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar
MakePadding(TabBar, 4, 4, 4, 4)

local Tabs = {"Chat", "Modos", "Config"}
local TabButtons = {}

local function SetActiveTab(name)
    State.CurrentTab = name
    for _, info in pairs(TabButtons) do
        if info.name == name then
            Tween(info.btn, {BackgroundColor3 = CONFIG.Colors.Accent, BackgroundTransparency = 0}, 0.2)
            Tween(info.lbl, {TextColor3 = CONFIG.Colors.White}, 0.2)
        else
            Tween(info.btn, {BackgroundColor3 = CONFIG.Colors.Card, BackgroundTransparency = 0.5}, 0.2)
            Tween(info.lbl, {TextColor3 = CONFIG.Colors.TextMuted}, 0.2)
        end
    end
    -- Mostrar/ocultar paneles
end

for _, tabName in ipairs(Tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 1, 0)
    btn.BackgroundColor3 = CONFIG.Colors.Card
    btn.BackgroundTransparency = 0.5
    btn.Text = tabName
    btn.TextColor3 = CONFIG.Colors.TextMuted
    btn.TextSize = 12
    btn.Font = CONFIG.Font
    btn.ZIndex = 53
    btn.Parent = TabBar
    MakeCorner(btn, 8)
    table.insert(TabButtons, {name = tabName, btn = btn, lbl = btn})
    btn.MouseButton1Click:Connect(function()
        SetActiveTab(tabName)
    end)
end

-- ============================================================
--  PANEL KEY SYSTEM
-- ============================================================
local KeyPanel = Instance.new("Frame")
KeyPanel.Size = UDim2.new(1, -24, 1, -108)
KeyPanel.Position = UDim2.new(0, 12, 0, 100)
KeyPanel.BackgroundTransparency = 1
KeyPanel.ZIndex = 52
KeyPanel.Visible = true
KeyPanel.Parent = MainFrame

local KeyLayout = Instance.new("UIListLayout")
KeyLayout.FillDirection = Enum.FillDirection.Vertical
KeyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
KeyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
KeyLayout.Padding = UDim.new(0, 14)
KeyLayout.Parent = KeyPanel

-- Icono lock
local LockIcon = Instance.new("TextLabel")
LockIcon.Size = UDim2.new(0, 70, 0, 70)
LockIcon.BackgroundColor3 = CONFIG.Colors.Card
LockIcon.Text = "🔑"
LockIcon.TextSize = 32
LockIcon.Font = CONFIG.FontReg
LockIcon.TextColor3 = CONFIG.Colors.White
LockIcon.ZIndex = 53
LockIcon.LayoutOrder = 1
LockIcon.Parent = KeyPanel
MakeCorner(LockIcon, 35)
MakeStroke(LockIcon, CONFIG.Colors.Accent, 2)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, 0, 0, 24)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "Activar Kaelen"
KeyTitle.TextColor3 = CONFIG.Colors.White
KeyTitle.TextSize = 18
KeyTitle.Font = CONFIG.Font
KeyTitle.ZIndex = 53
KeyTitle.LayoutOrder = 2
KeyTitle.Parent = KeyPanel

local KeySub = Instance.new("TextLabel")
KeySub.Size = UDim2.new(1, 0, 0, 32)
KeySub.BackgroundTransparency = 1
KeySub.Text = "Introduce tu API Key de OpenRouter\npara desbloquear Kaelen AI"
KeySub.TextColor3 = CONFIG.Colors.TextMuted
KeySub.TextSize = 12
KeySub.Font = CONFIG.FontReg
KeySub.TextWrapped = true
KeySub.ZIndex = 53
KeySub.LayoutOrder = 3
KeySub.Parent = KeyPanel

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, 0, 0, 44)
KeyInput.BackgroundColor3 = CONFIG.Colors.Card
KeyInput.BackgroundTransparency = 0.1
KeyInput.Text = ""
KeyInput.PlaceholderText = "sk-or-v1-xxxxxxxxxxxx"
KeyInput.TextColor3 = CONFIG.Colors.Text
KeyInput.PlaceholderColor3 = CONFIG.Colors.TextMuted
KeyInput.TextSize = 13
KeyInput.Font = CONFIG.FontReg
KeyInput.ClearTextOnFocus = false
KeyInput.ZIndex = 53
KeyInput.LayoutOrder = 4
KeyInput.Parent = KeyPanel
MakeCorner(KeyInput, 10)
MakeStroke(KeyInput, CONFIG.Colors.Border, 1)
MakePadding(KeyInput, 0, 0, 12, 12)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, 0, 0, 44)
VerifyBtn.BackgroundColor3 = CONFIG.Colors.Accent
VerifyBtn.Text = "Verificar y Activar"
VerifyBtn.TextColor3 = CONFIG.Colors.White
VerifyBtn.TextSize = 14
VerifyBtn.Font = CONFIG.Font
VerifyBtn.ZIndex = 53
VerifyBtn.LayoutOrder = 5
VerifyBtn.Parent = KeyPanel
MakeCorner(VerifyBtn, 10)

local KeyStatusLabel = Instance.new("TextLabel")
KeyStatusLabel.Size = UDim2.new(1, 0, 0, 20)
KeyStatusLabel.BackgroundTransparency = 1
KeyStatusLabel.Text = ""
KeyStatusLabel.TextColor3 = CONFIG.Colors.TextMuted
KeyStatusLabel.TextSize = 12
KeyStatusLabel.Font = CONFIG.FontReg
KeyStatusLabel.ZIndex = 53
KeyStatusLabel.LayoutOrder = 6
KeyStatusLabel.Parent = KeyPanel

-- ============================================================
--  PANEL CHAT
-- ============================================================
local ChatPanel = Instance.new("Frame")
ChatPanel.Size = UDim2.new(1, -24, 1, -110)
ChatPanel.Position = UDim2.new(0, 12, 0, 100)
ChatPanel.BackgroundTransparency = 1
ChatPanel.ZIndex = 52
ChatPanel.Visible = false
ChatPanel.Parent = MainFrame

-- Scroll de mensajes
local MsgScroll = Instance.new("ScrollingFrame")
MsgScroll.Size = UDim2.new(1, 0, 1, -100)
MsgScroll.BackgroundTransparency = 1
MsgScroll.ScrollBarThickness = 3
MsgScroll.ScrollBarImageColor3 = CONFIG.Colors.Accent
MsgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MsgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MsgScroll.ZIndex = 53
MsgScroll.Parent = ChatPanel

local MsgLayout = Instance.new("UIListLayout")
MsgLayout.FillDirection = Enum.FillDirection.Vertical
MsgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
MsgLayout.Padding = UDim.new(0, 8)
MsgLayout.Parent = MsgScroll
MakePadding(MsgScroll, 8, 8, 8, 8)

-- Thinking indicator
local ThinkFrame = Instance.new("Frame")
ThinkFrame.Size = UDim2.new(0, 120, 0, 32)
ThinkFrame.BackgroundColor3 = CONFIG.Colors.AIBubble
ThinkFrame.BackgroundTransparency = 0.1
ThinkFrame.Visible = false
ThinkFrame.ZIndex = 54
ThinkFrame.LayoutOrder = 9999
ThinkFrame.Parent = MsgScroll
MakeCorner(ThinkFrame, 16)
MakeStroke(ThinkFrame, CONFIG.Colors.Border, 1)

local ThinkLabel = Instance.new("TextLabel")
ThinkLabel.Size = UDim2.new(1, -8, 1, 0)
ThinkLabel.Position = UDim2.new(0, 8, 0, 0)
ThinkLabel.BackgroundTransparency = 1
ThinkLabel.Text = "Kaelen pensando●●●"
ThinkLabel.TextColor3 = CONFIG.Colors.TextMuted
ThinkLabel.TextSize = 12
ThinkLabel.Font = CONFIG.FontReg
ThinkLabel.ZIndex = 55
ThinkLabel.Parent = ThinkFrame

-- Input area
local InputFrame = Instance.new("Frame")
InputFrame.Size = UDim2.new(1, 0, 0, 88)
InputFrame.Position = UDim2.new(0, 0, 1, -88)
InputFrame.BackgroundColor3 = CONFIG.Colors.Surface
InputFrame.BackgroundTransparency = 0.2
InputFrame.ZIndex = 53
InputFrame.Parent = ChatPanel
MakeCorner(InputFrame, 14)
MakeStroke(InputFrame, CONFIG.Colors.Border, 1)

local ChatInput = Instance.new("TextBox")
ChatInput.Size = UDim2.new(1, -56, 0, 42)
ChatInput.Position = UDim2.new(0, 8, 0, 8)
ChatInput.BackgroundColor3 = CONFIG.Colors.Card
ChatInput.BackgroundTransparency = 0.1
ChatInput.Text = ""
ChatInput.PlaceholderText = "Pregúntale algo a Kaelen..."
ChatInput.TextColor3 = CONFIG.Colors.Text
ChatInput.PlaceholderColor3 = CONFIG.Colors.TextMuted
ChatInput.TextSize = 13
ChatInput.Font = CONFIG.FontReg
ChatInput.MultiLine = false
ChatInput.ClearTextOnFocus = false
ChatInput.ZIndex = 54
ChatInput.Parent = InputFrame
MakeCorner(ChatInput, 10)
MakePadding(ChatInput, 0, 0, 10, 10)

local SendBtn = Instance.new("TextButton")
SendBtn.Size = UDim2.new(0, 42, 0, 42)
SendBtn.Position = UDim2.new(1, -50, 0, 8)
SendBtn.BackgroundColor3 = CONFIG.Colors.Accent
SendBtn.Text = "➤"
SendBtn.TextColor3 = CONFIG.Colors.White
SendBtn.TextSize = 18
SendBtn.Font = CONFIG.Font
SendBtn.ZIndex = 54
SendBtn.Parent = InputFrame
MakeCorner(SendBtn, 10)

-- Botones rápidos
local QuickBtnFrame = Instance.new("Frame")
QuickBtnFrame.Size = UDim2.new(1, 0, 0, 30)
QuickBtnFrame.Position = UDim2.new(0, 0, 0, 54)
QuickBtnFrame.BackgroundTransparency = 1
QuickBtnFrame.ZIndex = 54
QuickBtnFrame.Parent = InputFrame

local QuickLayout = Instance.new("UIListLayout")
QuickLayout.FillDirection = Enum.FillDirection.Horizontal
QuickLayout.Padding = UDim.new(0, 4)
QuickLayout.VerticalAlignment = Enum.VerticalAlignment.Center
QuickLayout.Parent = QuickBtnFrame
MakePadding(QuickBtnFrame, 2, 2, 8, 8)

local QuickCommands = {"🎮 Analizar Juego", "🔍 Vulnerabilidades", "📋 Exportar", "🗑 Limpiar"}

for _, cmd in ipairs(QuickCommands) do
    local qb = Instance.new("TextButton")
    qb.Size = UDim2.new(0, 0, 1, 0)
    qb.AutomaticSize = Enum.AutomaticSize.X
    qb.BackgroundColor3 = CONFIG.Colors.Card
    qb.BackgroundTransparency = 0.3
    qb.Text = cmd
    qb.TextColor3 = CONFIG.Colors.TextMuted
    qb.TextSize = 10
    qb.Font = CONFIG.FontReg
    qb.ZIndex = 55
    qb.Parent = QuickBtnFrame
    MakeCorner(qb, 6)
    MakePadding(qb, 2, 2, 6, 6)
end

-- ============================================================
--  PANEL MODOS
-- ============================================================
local ModesPanel = Instance.new("Frame")
ModesPanel.Size = UDim2.new(1, -24, 1, -110)
ModesPanel.Position = UDim2.new(0, 12, 0, 100)
ModesPanel.BackgroundTransparency = 1
ModesPanel.ZIndex = 52
ModesPanel.Visible = false
ModesPanel.Parent = MainFrame

local ModesLayout = Instance.new("UIListLayout")
ModesLayout.FillDirection = Enum.FillDirection.Vertical
ModesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ModesLayout.Padding = UDim.new(0, 10)
ModesLayout.Parent = ModesPanel
MakePadding(ModesPanel, 12, 12, 0, 0)

local ModeTitle = Instance.new("TextLabel")
ModeTitle.Size = UDim2.new(1, 0, 0, 24)
ModeTitle.BackgroundTransparency = 1
ModeTitle.Text = "Modo de Kaelen"
ModeTitle.TextColor3 = CONFIG.Colors.White
ModeTitle.TextSize = 16
ModeTitle.Font = CONFIG.Font
ModeTitle.ZIndex = 53
ModeTitle.Parent = ModesPanel

local ModeConfigs = {
    {name="Programador", icon="💻", desc="Scripts Lua, optimización y debugging"},
    {name="Analista",    icon="🔍", desc="Análisis de juego y vulnerabilidades"},
    {name="Creativo",    icon="🎨", desc="Ideas innovadoras y diseño de mecánicas"},
    {name="Troll",       icon="😈", desc="Ideas de trolleo divertidas y seguras"},
}

local ModeBtns = {}
for _, mc in ipairs(ModeConfigs) do
    local mf = Instance.new("TextButton")
    mf.Size = UDim2.new(1, 0, 0, 64)
    mf.BackgroundColor3 = CONFIG.Colors.Card
    mf.BackgroundTransparency = mc.name == State.CurrentMode and 0 or 0.3
    mf.Text = ""
    mf.ZIndex = 53
    mf.Parent = ModesPanel
    MakeCorner(mf, 12)
    MakeStroke(mf, mc.name == State.CurrentMode and CONFIG.Colors.Accent or CONFIG.Colors.Border, 1.5)

    local mIcon = Instance.new("TextLabel")
    mIcon.Size = UDim2.new(0, 40, 0, 40)
    mIcon.Position = UDim2.new(0, 12, 0.5, -20)
    mIcon.BackgroundTransparency = 1
    mIcon.Text = mc.icon
    mIcon.TextSize = 24
    mIcon.Font = CONFIG.FontReg
    mIcon.ZIndex = 54
    mIcon.Parent = mf

    local mName = Instance.new("TextLabel")
    mName.Size = UDim2.new(1, -60, 0, 20)
    mName.Position = UDim2.new(0, 58, 0, 12)
    mName.BackgroundTransparency = 1
    mName.Text = mc.name
    mName.TextColor3 = CONFIG.Colors.White
    mName.TextSize = 14
    mName.Font = CONFIG.Font
    mName.TextXAlignment = Enum.TextXAlignment.Left
    mName.ZIndex = 54
    mName.Parent = mf

    local mDesc = Instance.new("TextLabel")
    mDesc.Size = UDim2.new(1, -60, 0, 16)
    mDesc.Position = UDim2.new(0, 58, 0, 34)
    mDesc.BackgroundTransparency = 1
    mDesc.Text = mc.desc
    mDesc.TextColor3 = CONFIG.Colors.TextMuted
    mDesc.TextSize = 11
    mDesc.Font = CONFIG.FontReg
    mDesc.TextXAlignment = Enum.TextXAlignment.Left
    mDesc.ZIndex = 54
    mDesc.Parent = mf

    table.insert(ModeBtns, {btn=mf, name=mc.name})

    mf.MouseButton1Click:Connect(function()
        State.CurrentMode = mc.name
        SubLabel.Text = "AI Systems v2.0 • " .. State.CurrentMode
        for _, mb in pairs(ModeBtns) do
            if mb.name == mc.name then
                Tween(mb.btn, {BackgroundTransparency = 0}, 0.2)
                MakeStroke(mb.btn, CONFIG.Colors.Accent, 1.5)
            else
                Tween(mb.btn, {BackgroundTransparency = 0.3}, 0.2)
                MakeStroke(mb.btn, CONFIG.Colors.Border, 1.5)
            end
        end
    end)
end

-- ============================================================
--  PANEL CONFIG
-- ============================================================
local ConfigPanel = Instance.new("Frame")
ConfigPanel.Size = UDim2.new(1, -24, 1, -110)
ConfigPanel.Position = UDim2.new(0, 12, 0, 100)
ConfigPanel.BackgroundTransparency = 1
ConfigPanel.ZIndex = 52
ConfigPanel.Visible = false
ConfigPanel.Parent = MainFrame

local ConfigLayout = Instance.new("UIListLayout")
ConfigLayout.FillDirection = Enum.FillDirection.Vertical
ConfigLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ConfigLayout.Padding = UDim.new(0, 10)
ConfigLayout.Parent = ConfigPanel
MakePadding(ConfigPanel, 12, 12, 0, 0)

local CfgTitle = Instance.new("TextLabel")
CfgTitle.Size = UDim2.new(1, 0, 0, 24)
CfgTitle.BackgroundTransparency = 1
CfgTitle.Text = "Configuración"
CfgTitle.TextColor3 = CONFIG.Colors.White
CfgTitle.TextSize = 16
CfgTitle.Font = CONFIG.Font
CfgTitle.ZIndex = 53
CfgTitle.Parent = ConfigPanel

local SysPromptLabel = Instance.new("TextLabel")
SysPromptLabel.Size = UDim2.new(1, 0, 0, 20)
SysPromptLabel.BackgroundTransparency = 1
SysPromptLabel.Text = "System Prompt personalizado:"
SysPromptLabel.TextColor3 = CONFIG.Colors.TextMuted
SysPromptLabel.TextSize = 12
SysPromptLabel.Font = CONFIG.FontReg
SysPromptLabel.TextXAlignment = Enum.TextXAlignment.Left
SysPromptLabel.ZIndex = 53
SysPromptLabel.Parent = ConfigPanel

local SysPromptInput = Instance.new("TextBox")
SysPromptInput.Size = UDim2.new(1, 0, 0, 80)
SysPromptInput.BackgroundColor3 = CONFIG.Colors.Card
SysPromptInput.BackgroundTransparency = 0.1
SysPromptInput.Text = ""
SysPromptInput.PlaceholderText = "Ej: Responde siempre en inglés técnico..."
SysPromptInput.TextColor3 = CONFIG.Colors.Text
SysPromptInput.PlaceholderColor3 = CONFIG.Colors.TextMuted
SysPromptInput.TextSize = 12
SysPromptInput.Font = CONFIG.FontReg
SysPromptInput.MultiLine = true
SysPromptInput.ClearTextOnFocus = false
SysPromptInput.ZIndex = 53
SysPromptInput.Parent = ConfigPanel
MakeCorner(SysPromptInput, 10)
MakeStroke(SysPromptInput, CONFIG.Colors.Border, 1)
MakePadding(SysPromptInput, 8, 8, 10, 10)

local SaveSysBtn = Instance.new("TextButton")
SaveSysBtn.Size = UDim2.new(1, 0, 0, 38)
SaveSysBtn.BackgroundColor3 = CONFIG.Colors.Accent
SaveSysBtn.Text = "Guardar System Prompt"
SaveSysBtn.TextColor3 = CONFIG.Colors.White
SaveSysBtn.TextSize = 13
SaveSysBtn.Font = CONFIG.Font
SaveSysBtn.ZIndex = 53
SaveSysBtn.Parent = ConfigPanel
MakeCorner(SaveSysBtn, 10)

local ResetKeyBtn = Instance.new("TextButton")
ResetKeyBtn.Size = UDim2.new(1, 0, 0, 38)
ResetKeyBtn.BackgroundColor3 = CONFIG.Colors.Red
ResetKeyBtn.BackgroundTransparency = 0.3
ResetKeyBtn.Text = "Resetear API Key"
ResetKeyBtn.TextColor3 = CONFIG.Colors.White
ResetKeyBtn.TextSize = 13
ResetKeyBtn.Font = CONFIG.Font
ResetKeyBtn.ZIndex = 53
ResetKeyBtn.Parent = ConfigPanel
MakeCorner(ResetKeyBtn, 10)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 60)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Kaelen v2.0\nModelos: Qwen3-Coder + Llama 3.3 70B\nvía OpenRouter API"
InfoLabel.TextColor3 = CONFIG.Colors.TextMuted
InfoLabel.TextSize = 11
InfoLabel.Font = CONFIG.FontReg
InfoLabel.TextWrapped = true
InfoLabel.ZIndex = 53
InfoLabel.Parent = ConfigPanel

-- ============================================================
--  LÓGICA DE TABS (SHOW/HIDE)
-- ============================================================
local PanelMap = {
    Chat   = ChatPanel,
    Modos  = ModesPanel,
    Config = ConfigPanel,
}

local function ShowPanel(tabName)
    for name, panel in pairs(PanelMap) do
        panel.Visible = (name == tabName)
    end
    SetActiveTab(tabName)
end

for _, info in pairs(TabButtons) do
    info.btn.MouseButton1Click:Connect(function()
        if State.KeyVerified then
            ShowPanel(info.name)
        end
    end)
end

-- ============================================================
--  FUNCIÓN AGREGAR MENSAJE AL CHAT
-- ============================================================
local function AddMessage(role, content)
    -- Guardar en historial
    table.insert(State.Messages, {role=role, content=content})
    if #State.Messages > CONFIG.MaxHistory then
        table.remove(State.Messages, 1)
    end

    -- Crear burbuja
    local isUser = (role == "user")
    local bubble = Instance.new("Frame")
    bubble.Size = UDim2.new(0.82, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.BackgroundColor3 = isUser and CONFIG.Colors.UserBubble or CONFIG.Colors.AIBubble
    bubble.BackgroundTransparency = 0.05
    bubble.ZIndex = 54
    bubble.LayoutOrder = #State.Messages
    bubble.Parent = MsgScroll
    if isUser then
        bubble.Position = UDim2.new(0.18, 0, 0, 0)
    end
    MakeCorner(bubble, 14)
    if not isUser then
        MakeStroke(bubble, CONFIG.Colors.Border, 1)
    end
    MakePadding(bubble, 8, 8, 12, 12)

    -- Header de la burbuja
    local authorLabel = Instance.new("TextLabel")
    authorLabel.Size = UDim2.new(1, 0, 0, 14)
    authorLabel.BackgroundTransparency = 1
    authorLabel.Text = isUser and ("🧑 " .. LocalPlayer.Name) or "⬡ Kaelen"
    authorLabel.TextColor3 = isUser and Color3.fromRGB(200, 170, 255) or CONFIG.Colors.Accent
    authorLabel.TextSize = 10
    authorLabel.Font = CONFIG.Font
    authorLabel.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    authorLabel.ZIndex = 55
    authorLabel.LayoutOrder = 1
    authorLabel.Parent = bubble

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0, 0)
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = content
    msgLabel.TextColor3 = CONFIG.Colors.Text
    msgLabel.TextSize = 13
    msgLabel.Font = CONFIG.FontReg
    msgLabel.TextWrapped = true
    msgLabel.RichText = true
    msgLabel.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    msgLabel.ZIndex = 55
    msgLabel.LayoutOrder = 2
    msgLabel.Parent = bubble

    -- Botón copiar (solo mensajes de Kaelen)
    if not isUser then
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 70, 0, 22)
        copyBtn.BackgroundColor3 = CONFIG.Colors.Card
        copyBtn.BackgroundTransparency = 0.2
        copyBtn.Text = "📋 Copiar"
        copyBtn.TextColor3 = CONFIG.Colors.TextMuted
        copyBtn.TextSize = 10
        copyBtn.Font = CONFIG.FontReg
        copyBtn.ZIndex = 55
        copyBtn.LayoutOrder = 3
        copyBtn.Parent = bubble
        MakeCorner(copyBtn, 6)
        copyBtn.MouseButton1Click:Connect(function()
            setclipboard(content)
            copyBtn.Text = "✅ Copiado"
            task.delay(2, function() copyBtn.Text = "📋 Copiar" end)
        end)
    end

    -- Layout vertical de la burbuja
    local bubLayout = Instance.new("UIListLayout")
    bubLayout.FillDirection = Enum.FillDirection.Vertical
    bubLayout.Padding = UDim.new(0, 4)
    bubLayout.HorizontalAlignment = isUser and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    bubLayout.Parent = bubble

    -- Scroll al fondo
    task.delay(0.05, function()
        MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y)
    end)

    -- Animación de entrada
    bubble.BackgroundTransparency = 1
    Tween(bubble, {BackgroundTransparency = 0.05}, 0.25)
end

-- ============================================================
--  ANIMACIÓN THINKING
-- ============================================================
local thinkCoroutine = nil

local function ShowThinking(show)
    State.IsThinking = show
    ThinkFrame.Visible = show
    if show then
        ThinkFrame.LayoutOrder = #State.Messages + 1
        if thinkCoroutine then task.cancel(thinkCoroutine) end
        thinkCoroutine = task.spawn(function()
            local dots = {"●○○", "●●○", "●●●", "○●●", "○○●", "○○○"}
            local i = 1
            while State.IsThinking do
                ThinkLabel.Text = "Kaelen pensando " .. dots[i]
                i = (i % #dots) + 1
                task.wait(0.3)
            end
        end)
        task.delay(0.05, function()
            MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y)
        end)
    else
        if thinkCoroutine then task.cancel(thinkCoroutine) end
    end
end

-- ============================================================
--  ENVIAR MENSAJE
-- ============================================================
local function SendMessage()
    if State.IsThinking then return end
    local text = ChatInput.Text
    if text == "" or text == nil then return end
    ChatInput.Text = ""

    AddMessage("user", text)
    ShowThinking(true)

    task.spawn(function()
        local response, err = OrchestrateKaelen(text, State.Messages)
        ShowThinking(false)
        if err then
            AddMessage("assistant", "⚠️ Error: " .. tostring(err) .. "\n\nVerifica tu API Key en Configuración.")
        else
            AddMessage("assistant", response or "Sin respuesta.")
        end
    end)
end

SendBtn.MouseButton1Click:Connect(SendMessage)
ChatInput.FocusLost:Connect(function(enter)
    if enter then SendMessage() end
end)

-- ============================================================
--  BOTONES RÁPIDOS LÓGICA
-- ============================================================
local function HandleQuickCmd(cmd)
    if cmd:find("Analizar Juego") then
        local ctx = GetGameContext()
        local msg = "🎮 Analiza este juego de Roblox en profundidad:\n\n" .. ctx .. "\n\nDame un análisis completo de mecánicas, puntos fuertes y débiles."
        ChatInput.Text = msg
        SendMessage()
    elseif cmd:find("Vulnerabilidades") then
        local ctx = GetGameContext()
        local msg = "🔍 Analiza posibles vulnerabilidades y exploits en este juego:\n\n" .. ctx .. "\n\nComo desarrollador del juego, necesito saber qué puntos débiles tiene mi juego para reforzarlos."
        ChatInput.Text = msg
        SendMessage()
    elseif cmd:find("Exportar") then
        local export = "=== Kaelen AI - Conversación Exportada ===\n"
        export = export .. "Fecha: " .. os.date() .. "\n"
        export = export .. "Modo: " .. State.CurrentMode .. "\n\n"
        for _, m in ipairs(State.Messages) do
            local rol = m.role == "user" and "Tú" or "Kaelen"
            export = export .. "[" .. rol .. "]: " .. m.content .. "\n\n"
        end
        setclipboard(export)
        AddMessage("assistant", "✅ Conversación copiada al portapapeles.")
    elseif cmd:find("Limpiar") then
        for _, child in ipairs(MsgScroll:GetChildren()) do
            if child:IsA("Frame") and child ~= ThinkFrame then
                child:Destroy()
            end
        end
        State.Messages = {}
        AddMessage("assistant", "🗑 Historial limpiado. ¿En qué te puedo ayudar?")
    end
end

for _, child in ipairs(QuickBtnFrame:GetChildren()) do
    if child:IsA("TextButton") then
        child.MouseButton1Click:Connect(function()
            HandleQuickCmd(child.Text)
        end)
    end
end

-- ============================================================
--  VERIFICACIÓN DE KEY
-- ============================================================
VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text
    if key == "" then
        KeyStatusLabel.TextColor3 = CONFIG.Colors.Red
        KeyStatusLabel.Text = "⚠️ Introduce tu API Key primero"
        return
    end
    VerifyBtn.Text = "Verificando..."
    VerifyBtn.BackgroundColor3 = CONFIG.Colors.AccentSoft
    KeyStatusLabel.Text = ""

    task.spawn(function()
        local ok, err = VerifyAPIKey(key)
        if ok then
            State.APIKey = key
            State.KeyVerified = true
            KeyStatusLabel.TextColor3 = CONFIG.Colors.Green
            KeyStatusLabel.Text = "✅ API Key válida · Kaelen activado"
            Tween(StatusDot, {BackgroundColor3 = CONFIG.Colors.Green}, 0.4)
            task.wait(0.8)
            -- Transición a chat
            KeyPanel.Visible = false
            ChatPanel.Visible = true
            ShowPanel("Chat")
            AddMessage("assistant", "⬡ Hola, soy **Kaelen**.\n\nEstoy listo. Soy un orquestador IA que combina **Qwen3-Coder** y **Llama 3.3 70B** para darte la mejor asistencia posible.\n\nPuedo ayudarte a:\n• 🔍 Analizar tu juego y detectar vulnerabilidades\n• 💻 Crear y optimizar scripts Lua\n• 🎮 Estrategias y análisis de mecánicas\n• 🎨 Ideas creativas para tu juego\n\n¿Por dónde empezamos?")
        else
            State.KeyVerified = false
            KeyStatusLabel.TextColor3 = CONFIG.Colors.Red
            KeyStatusLabel.Text = "❌ Key inválida: " .. (err or "error desconocido")
            VerifyBtn.Text = "Verificar y Activar"
            VerifyBtn.BackgroundColor3 = CONFIG.Colors.Accent
        end
    end)
end)

-- ============================================================
--  CONFIG HANDLERS
-- ============================================================
SaveSysBtn.MouseButton1Click:Connect(function()
    State.CustomSysPrompt = SysPromptInput.Text
    SaveSysBtn.Text = "✅ Guardado"
    task.delay(2, function() SaveSysBtn.Text = "Guardar System Prompt" end)
end)

ResetKeyBtn.MouseButton1Click:Connect(function()
    State.APIKey = ""
    State.KeyVerified = false
    State.Messages = {}
    Tween(StatusDot, {BackgroundColor3 = CONFIG.Colors.Red}, 0.3)
    KeyPanel.Visible = true
    ChatPanel.Visible = false
    ModesPanel.Visible = false
    ConfigPanel.Visible = false
    KeyInput.Text = ""
    KeyStatusLabel.Text = ""
    VerifyBtn.Text = "Verificar y Activar"
    VerifyBtn.BackgroundColor3 = CONFIG.Colors.Accent
end)

-- ============================================================
--  ABRIR / CERRAR VENTANA
-- ============================================================
local function OpenWindow()
    State.IsOpen = true
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(
        FloatBtn.Position.X.Scale,
        FloatBtn.Position.X.Offset + 29,
        FloatBtn.Position.Y.Scale,
        FloatBtn.Position.Y.Offset + 29
    )
    Tween(MainFrame, {
        Size = UDim2.new(0, 380, 0, 580),
        Position = UDim2.new(0.5, -190, 0.5, -290)
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function CloseWindow()
    State.IsOpen = false
    Tween(MainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(
            FloatBtn.Position.X.Scale,
            FloatBtn.Position.X.Offset + 29,
            FloatBtn.Position.Y.Scale,
            FloatBtn.Position.Y.Offset + 29
        )
    }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.26, function() MainFrame.Visible = false end)
end

FloatBtn.MouseButton1Click:Connect(function()
    if not btnDragging then
        if State.IsOpen then CloseWindow() else OpenWindow() end
    end
end)
CloseBtn.MouseButton1Click:Connect(CloseWindow)

-- ============================================================
--  INICIALIZACIÓN
-- ============================================================
SetActiveTab("Chat")

-- Iniciar con pantalla de key si no está verificado
if not State.KeyVerified then
    KeyPanel.Visible = true
    ChatPanel.Visible = false
    ModesPanel.Visible = false
    ConfigPanel.Visible = false
end

print("[ Kaelen v2.0 ] Cargado correctamente. Toca el botón K para abrir.")
print("[ Kaelen ] Modelos: " .. CONFIG.Models.Coder .. " + " .. CONFIG.Models.Reason)
