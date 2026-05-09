-- Kaelen --
-- Asistente IA Premium para Roblox
-- Orquestador: Qwen3-Coder + Llama 3.3 70B + Gemma 3 (Fast Actions)
-- Version: 2.2 | Kaelen Systems
-- ============================================================

-- ============================================================
--  SERVICIOS
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
--  LIMPIAR INSTANCIA ANTERIOR
-- ============================================================
pcall(function()
    if CoreGui:FindFirstChild("KaelenUI") then
        CoreGui:FindFirstChild("KaelenUI"):Destroy()
    end
end)
pcall(function()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg and pg:FindFirstChild("KaelenUI") then
        pg:FindFirstChild("KaelenUI"):Destroy()
    end
end)

-- ============================================================
--  CONFIGURACIÓN
-- ============================================================
local CFG = {
    Version        = "2.2",
    OpenRouterURL  = "https://openrouter.ai/api/v1/chat/completions",
    ModelCoder     = "qwen/qwen3-coder:free",
    ModelReason    = "meta-llama/llama-3.3-70b-instruct:free",
    ModelFast      = "google/gemma-3-27b-it:free", -- Para comandos rápidos
    MaxTokens      = 1500,
    Temperature    = 0.72,
    MaxHistory     = 50,
    -- Dimensiones adaptadas para Móvil
    WIN_W          = 420,
    WIN_H          = 280, 
    C = {
        BG          = Color3.fromRGB(8,   8,  18),
        Surface     = Color3.fromRGB(15, 14,  30),
        Card        = Color3.fromRGB(21, 20,  40),
        CardHi      = Color3.fromRGB(30, 27,  58),
        Border      = Color3.fromRGB(52, 47, 100),
        BorderHi    = Color3.fromRGB(100, 68, 222),
        Accent      = Color3.fromRGB(112, 72, 255),
        AccentDim   = Color3.fromRGB(72,  42, 175),
        AccentGlow  = Color3.fromRGB(158, 118, 255),
        UserBub     = Color3.fromRGB(92,  52, 232),
        AIBub       = Color3.fromRGB(20,  19,  40),
        Text        = Color3.fromRGB(226, 222, 255),
        TextMuted   = Color3.fromRGB(118, 112, 172),
        TextDim     = Color3.fromRGB(72,   68, 128),
        Green       = Color3.fromRGB(68,  212, 132),
        Red         = Color3.fromRGB(255,  72,  98),
        Yellow      = Color3.fromRGB(255, 198,  68),
        White       = Color3.fromRGB(255, 255, 255),
    },
    Font    = Enum.Font.GothamBold,
    FontReg = Enum.Font.Gotham,
    FontMon = Enum.Font.Code,
}

-- ============================================================
--  ESTADO GLOBAL
-- ============================================================
local State = {
    APIKey          = "",
    KeyVerified     = false,
    IsOpen          = false,
    IsThinking      = false,
    Messages        = {},
    CurrentMode     = "Analista",
    CustomSysPrompt = "",
    ThinkTask       = nil,
    MsgCount        = 0,
    -- Estados del personaje
    IsFlying        = false,
    FlyConn         = nil,
    IsNoclipping    = false,
    NoclipConn      = nil,
    -- Arrastre botón
    BtnDragging     = false,
    BtnDragOrigin   = Vector2.new(0, 0),
    BtnPosOrigin    = UDim2.new(0, 0, 0, 0),
    BtnTotalMoved   = 0,
    -- Arrastre ventana
    WinDragging     = false,
    WinDragOrigin   = Vector2.new(0, 0),
    WinPosOrigin    = UDim2.new(0, 0, 0, 0),
}

-- ============================================================
--  MOTOR DE COMANDOS DEL PERSONAJE
-- ============================================================
local function SetFly(state)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    State.IsFlying = state
    if state then
        if State.FlyConn then return end
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp
        
        local bg = Instance.new("BodyGyro")
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
        
        State.FlyConn = RunService.RenderStepped:Connect(function()
            local cf = Camera.CFrame
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
            local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
            bv.Velocity = (cf.RightVector * move.X + cf.LookVector * move.Z + Vector3.new(0, up, 0)) * 50
            bg.CFrame = cf
        end)
    else
        if hrp:FindFirstChildOfClass("BodyVelocity") then hrp:FindFirstChildOfClass("BodyVelocity"):Destroy() end
        if hrp:FindFirstChildOfClass("BodyGyro") then hrp:FindFirstChildOfClass("BodyGyro"):Destroy() end
        if State.FlyConn then State.FlyConn:Disconnect(); State.FlyConn = nil end
    end
end

local function SetNoclip(state)
    State.IsNoclipping = state
    if state then
        if State.NoclipConn then return end
        State.NoclipConn = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if State.NoclipConn then
            State.NoclipConn:Disconnect()
            State.NoclipConn = nil
        end
    end
end

local function ExecuteAICommands(text)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if text:match("%[NOCLIP:on%]") then SetNoclip(true) end
    if text:match("%[NOCLIP:off%]") then SetNoclip(false) end
    if text:match("%[FLY:on%]") then SetFly(true) end
    if text:match("%[FLY:off%]") then SetFly(false) end
    
    if hum then
        local spd = text:match("%[SPEED:(%d+)%]")
        if spd then hum.WalkSpeed = tonumber(spd) end
        
        local jmp = text:match("%[JUMP:(%d+)%]")
        if jmp then hum.JumpPower = tonumber(jmp); hum.UseJumpPower = true end
        
        if text:match("%[HEAL%]") then hum.Health = hum.MaxHealth end
    end
end

-- ============================================================
--  SYSTEM PROMPTS POR MODO
-- ============================================================
local COMMAND_INSTRUCTIONS = [[
IMPORTANTE - CONTROL DEL JUGADOR:
El usuario puede pedirte que alteres su personaje o el juego. Si te lo pide, DEBES incluir uno de estos comandos exactos en tu respuesta para que el motor interno los ejecute:
- Volar: [FLY:on] o [FLY:off]
- Atravesar paredes (Noclip): [NOCLIP:on] o [NOCLIP:off]
- Cambiar velocidad: [SPEED:numero] (ej. [SPEED:100])
- Cambiar salto: [JUMP:numero] (ej. [JUMP:50])
- Curar: [HEAL]
Responde siempre de manera concisa y confirmando la acción.
]]

local PROMPTS = {
    Programador = [[Eres Kaelen, el mejor experto en Roblox Lua del mundo con 15 años de experiencia.
MISIÓN: Crear, optimizar, debugear y analizar scripts Lua para Roblox.
REGLAS ESTRICTAS:
- Todo código debe ser limpio, modular y bien comentado.
- Usa patrones modernos: task.spawn, task.delay.
- Explica brevemente cada decisión técnica importante.
]] .. COMMAND_INSTRUCTIONS,

    Analista = [[Eres Kaelen, analista de sistemas de juegos Roblox de élite.
MISIÓN: Analizar en profundidad mecánicas, detectar vulnerabilidades, evaluar arquitectura y rendimiento.
REGLAS ESTRICTAS:
- Combina análisis técnico profundo con visión de game design.
- Sé directo, exhaustivo y usa estructura de secciones clara.
]] .. COMMAND_INSTRUCTIONS,

    Creativo = [[Eres Kaelen, genio creativo especializado en diseño de experiencias Roblox únicas.
MISIÓN: Generar ideas innovadoras, mecánicas originales y conceptos.
REGLAS ESTRICTAS:
- Piensa fuera de la caja.
- Sé descriptivo, entusiasta y detallado.
]] .. COMMAND_INSTRUCTIONS,

    Troll = [[Eres Kaelen en modo Troll, maestro del caos creativo.
MISIÓN: Proponer trolleos ingeniosos.
REGLAS ESTRICTAS:
- SOLO mecánicas que existen dentro del juego. Cero cheats externos.
- Sé creativo, gracioso y específico.
]] .. COMMAND_INSTRUCTIONS,
}

-- ============================================================
--  UTILIDADES UI
-- ============================================================
local function Tween(obj, props, t, style, dir)
    local tw = TweenService:Create(obj, TweenInfo.new(t or 0.28, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function Corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function Stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or CFG.C.Border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Pad(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 8)
    p.PaddingBottom = UDim.new(0, b or 8)
    p.PaddingLeft   = UDim.new(0, l or 8)
    p.PaddingRight  = UDim.new(0, r or 8)
    p.Parent = parent
    return p
end

local function VLayout(parent, padding, halign)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = Enum.FillDirection.Vertical
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = Enum.VerticalAlignment.Top
    l.Padding             = UDim.new(0, padding or 0)
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function HLayout(parent, padding, valign)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = valign or Enum.VerticalAlignment.Center
    l.Padding             = UDim.new(0, padding or 0)
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = parent
    return l
end

local function Gradient(parent, c0, c1, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c0),
        ColorSequenceKeypoint.new(1, c1),
    })
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function Frame(parent, size, pos, bg, bgTrans, zIndex, name)
    local f = Instance.new("Frame")
    f.Size                  = size or UDim2.new(1, 0, 1, 0)
    f.Position              = pos  or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3      = bg or CFG.C.Card
    f.BackgroundTransparency = bgTrans or 0
    f.ZIndex                = zIndex or 2
    f.BorderSizePixel       = 0
    if name then f.Name = name end
    f.Parent = parent
    return f
end

local function Label(parent, size, pos, text, color, textSize, font, halign, zIndex)
    local l = Instance.new("TextLabel")
    l.Size                  = size or UDim2.new(1, 0, 0, 20)
    l.Position              = pos  or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text                  = text or ""
    l.TextColor3            = color or CFG.C.Text
    l.TextSize              = textSize or 13
    l.Font                  = font or CFG.FontReg
    l.TextXAlignment        = halign or Enum.TextXAlignment.Left
    l.ZIndex                = zIndex or 2
    l.TextWrapped           = true
    l.BorderSizePixel       = 0
    l.Parent = parent
    return l
end

local function Button(parent, size, pos, bg, text, textColor, textSize, font, zIndex)
    local b = Instance.new("TextButton")
    b.Size                  = size or UDim2.new(1, 0, 0, 40)
    b.Position              = pos  or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3      = bg or CFG.C.Accent
    b.Text                  = text or ""
    b.TextColor3            = textColor or CFG.C.White
    b.TextSize              = textSize or 13
    b.Font                  = font or CFG.Font
    b.ZIndex                = zIndex or 2
    b.AutoButtonColor       = false
    b.BorderSizePixel       = 0
    b.Parent = parent
    return b
end

local function Scroll(parent, size, pos, zIndex)
    local s = Instance.new("ScrollingFrame")
    s.Size                   = size or UDim2.new(1, 0, 1, 0)
    s.Position               = pos  or UDim2.new(0, 0, 0, 0)
    s.BackgroundTransparency = 1
    s.ScrollBarThickness     = 3
    s.ScrollBarImageColor3   = CFG.C.Accent
    s.CanvasSize             = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    s.ZIndex                 = zIndex or 2
    s.BorderSizePixel        = 0
    s.Parent = parent
    return s
end

-- ============================================================
--  CONTEXTO DEL JUEGO
-- ============================================================
local function GetGameContext()
    local ctx = {}
    pcall(function() ctx.GameName    = game.Name end)
    pcall(function() ctx.PlaceId     = tostring(game.PlaceId) end)
    pcall(function() ctx.JobId       = game.JobId end)
    pcall(function() ctx.PlayerCount = tostring(#Players:GetPlayers()) end)
    pcall(function() ctx.MyName      = LocalPlayer.Name end)
    return HttpService:JSONEncode(ctx)
end

-- ============================================================
--  HTTP / OPENROUTER
-- ============================================================
local function FindRequestFunction()
    local attempts = {
        function() return syn and syn.request end,
        function() return http and http.request end,
        function() return http_request end,
        function() return request end,
        function() return KRNL_request end,
        function() return fluxus and fluxus.request end,
        function() return (getgenv and getgenv().request) end,
    }
    for _, fn in ipairs(attempts) do
        local ok, f = pcall(fn)
        if ok and type(f) == "function" then return f end
    end
    return nil
end

local function CallAPI(model, messages, systemPrompt)
    if not State.KeyVerified or State.APIKey == "" then return nil, "API Key no verificada." end
    local reqFn = FindRequestFunction()
    if not reqFn then return nil, "Tu executor no soporta 'request'." end

    local apiMsgs = {}
    if systemPrompt and systemPrompt ~= "" then
        table.insert(apiMsgs, { role = "system", content = systemPrompt })
    end
    for _, m in ipairs(messages) do
        table.insert(apiMsgs, { role = m.role, content = m.content })
    end

    local payload = { model = model, max_tokens = CFG.MaxTokens, temperature = CFG.Temperature, messages = apiMsgs }

    local ok, resp = pcall(function()
        return reqFn({
            Url    = CFG.OpenRouterURL,
            Method = "POST",
            Headers = {
                ["Content-Type"]  = "application/json",
                ["Authorization"] = "Bearer " .. State.APIKey,
                ["HTTP-Referer"]  = "https://www.roblox.com",
                ["X-Title"]       = "Kaelen AI v2.2",
            },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if not ok then return nil, "Error de red: " .. tostring(resp) end
    if not resp then return nil, "Sin respuesta del servidor" end
    if resp.StatusCode ~= 200 then return nil, "HTTP " .. tostring(resp.StatusCode) end

    local ok2, data = pcall(HttpService.JSONDecode, HttpService, resp.Body)
    if not ok2 then return nil, "Error parseando JSON" end
    if data and data.choices and data.choices[1] and data.choices[1].message then
        return data.choices[1].message.content, nil
    end
    return nil, "Estructura inesperada"
end

local function VerifyAPIKey(key)
    local prevKey = State.APIKey; local prevVerified = State.KeyVerified
    State.APIKey = key; State.KeyVerified = true
    local res, err = CallAPI(CFG.ModelFast, {{ role = "user", content = "OK" }}, "Responde OK")
    if err then State.APIKey = prevKey; State.KeyVerified = prevVerified; return false, err end
    return true, nil
end

-- ============================================================
--  ORQUESTADOR KAELEN (OPTIMIZADO PARA LATENCIA Y ACCIÓN)
-- ============================================================
local CODE_KEYWORDS = {"script","lua","código","codigo","optimiza","debug","module"}
local ACTION_KEYWORDS = {"vuela", "volar", "fly", "noclip", "atravies", "paredes", "velocidad", "speed", "salto", "jump", "cura", "heal", "vida", "activa", "pon"}

local function MatchesAny(text, keywords)
    local lower = text:lower()
    for _, kw in ipairs(keywords) do
        if lower:find(kw, 1, true) then return true end
    end
    return false
end

local function BuildApiHistory(messages)
    local out = {}
    for _, m in ipairs(messages) do table.insert(out, { role = m.role, content = m.content }) end
    return out
end

local function OrchestrateKaelen(userMessage, history)
    local sys = (State.CustomSysPrompt ~= "" and State.CustomSysPrompt) or PROMPTS[State.CurrentMode] or PROMPTS.Analista
    local apiHistory = BuildApiHistory(history)

    local isAction = MatchesAny(userMessage, ACTION_KEYWORDS)
    local isCode = MatchesAny(userMessage, CODE_KEYWORDS) and not isAction 

    -- RUTA RÁPIDA: Si es un comando de jugador, usamos el modelo "Fast" para 0 latencia
    if isAction then
        local result, err = CallAPI(CFG.ModelFast, apiHistory, sys)
        if err then return nil, err end
        return "⚡ [Acción Rápida]\n" .. result, nil
    end

    -- RUTA PROFUNDA: Si es código, doble pase (Coder -> Llama)
    if isCode then
        local codeResult, codeErr = CallAPI(CFG.ModelCoder, apiHistory, sys)
        if codeErr then return nil, "Error Coder: " .. codeErr end

        local reviewMsgs = {{role = "user", content = "Revisa este código y dame la versión final:\n```lua\n" .. codeResult .. "\n```"}}
        local reviewed, revErr = CallAPI(CFG.ModelReason, reviewMsgs, sys)
        
        if revErr then return "⚡ [Qwen3-Coder]\n\n" .. codeResult, nil end
        return "⚡ [Orquestador — Qwen3 + Llama 3.3]\n\n" .. reviewed, nil
    end

    -- RUTA NORMAL: Charla regular
    local result, err = CallAPI(CFG.ModelReason, apiHistory, sys)
    if err then return nil, err end
    return "⬡ [Llama 3.3 70B]\n\n" .. result, nil
end

-- ============================================================
--  SCREEN GUI
-- ============================================================
local ScreenGui       = Instance.new("ScreenGui")
ScreenGui.Name        = "KaelenUI"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 9999
ScreenGui.IgnoreGuiInset  = true

local pgOk = pcall(function() ScreenGui.Parent = CoreGui end)
if not pgOk then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ============================================================
--  BOTÓN FLOTANTE [Adaptado Mobile]
-- ============================================================
local FloatBtn        = Instance.new("ImageButton")
FloatBtn.Name         = "FloatBtn"
FloatBtn.Size         = UDim2.new(0, 48, 0, 48)
FloatBtn.Position     = UDim2.new(1, -60, 0.6, -24)
FloatBtn.BackgroundColor3 = CFG.C.Accent
FloatBtn.Image        = ""
FloatBtn.AutoButtonColor = false
FloatBtn.ZIndex       = 500
FloatBtn.BorderSizePixel = 0
FloatBtn.Parent       = ScreenGui
Corner(FloatBtn, 24)
Stroke(FloatBtn, CFG.C.AccentGlow, 2)
Gradient(FloatBtn, Color3.fromRGB(135, 92, 255), Color3.fromRGB(88, 48, 205), 135)

local BtnGlow = Instance.new("ImageLabel")
BtnGlow.Size              = UDim2.new(0, 80, 0, 80)
BtnGlow.Position          = UDim2.new(0.5, -40, 0.5, -40)
BtnGlow.BackgroundTransparency = 1
BtnGlow.Image             = "rbxassetid://5028857084"
BtnGlow.ImageColor3       = CFG.C.Accent
BtnGlow.ImageTransparency = 0.45
BtnGlow.ZIndex            = 499
BtnGlow.Parent            = FloatBtn

local BtnK = Label(FloatBtn, UDim2.new(1,0,1,0), nil, "K", CFG.C.White, 20, CFG.Font, Enum.TextXAlignment.Center, 501)

task.spawn(function()
    while FloatBtn and FloatBtn.Parent do
        Tween(BtnGlow, { ImageTransparency = 0.12, Size = UDim2.new(0, 90, 0, 90), Position = UDim2.new(0.5, -45, 0.5, -45) }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.5)
        Tween(BtnGlow, { ImageTransparency = 0.6, Size = UDim2.new(0, 70, 0, 70), Position = UDim2.new(0.5, -35, 0.5, -35) }, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.5)
    end
end)

FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        State.BtnDragging   = true
        State.BtnDragOrigin = Vector2.new(inp.Position.X, inp.Position.Y)
        State.BtnPosOrigin  = FloatBtn.Position
        State.BtnTotalMoved = 0
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if State.BtnDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - State.BtnDragOrigin
        State.BtnTotalMoved = delta.Magnitude
        if State.BtnTotalMoved > 7 then
            FloatBtn.Position = UDim2.new(State.BtnPosOrigin.X.Scale, State.BtnPosOrigin.X.Offset + delta.X, State.BtnPosOrigin.Y.Scale, State.BtnPosOrigin.Y.Offset + delta.Y)
        end
    end
    if State.WinDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - State.WinDragOrigin
        MainWin.Position = UDim2.new(State.WinPosOrigin.X.Scale, State.WinPosOrigin.X.Offset + delta.X, State.WinPosOrigin.Y.Scale, State.WinPosOrigin.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        State.WinDragging = false
        if State.BtnDragging then
            local moved = State.BtnTotalMoved
            State.BtnDragging = false; State.BtnTotalMoved = 0
            if moved <= 7 then
                if State.IsOpen then CloseWindow() else OpenWindow() end
            end
        end
    end
end)

-- ============================================================
--  VENTANA PRINCIPAL
-- ============================================================
local W = CFG.WIN_W; local H = CFG.WIN_H

local MainWin = Frame(ScreenGui, UDim2.new(0, W, 0, H), UDim2.new(0.5, -W/2, 0.5, -H/2), CFG.C.BG, 0, 400, "MainWin")
MainWin.ClipsDescendants = true
MainWin.Visible          = false
Corner(MainWin, 18)
Stroke(MainWin, Color3.fromRGB(65, 52, 128), 1.5)
Gradient(MainWin, Color3.fromRGB(10, 9, 22), Color3.fromRGB(6, 6, 15), 155)

local TopLine = Frame(MainWin, UDim2.new(1, 0, 0, 2), UDim2.new(0,0,0,0), CFG.C.Accent, 0, 401)
Gradient(TopLine, Color3.fromRGB(165, 105, 255), Color3.fromRGB(78, 38, 198), 0)

for i = 1, 8 do
    local px = math.random(5, 95) / 100; local py = math.random(5, 95) / 100; local ps = math.random(2, 5)
    local dot = Frame(MainWin, UDim2.new(0, ps, 0, ps), UDim2.new(px, 0, py, 0), CFG.C.Accent, 0.65, 400)
    Corner(dot, ps)
    task.spawn(function()
        task.wait(math.random()*3)
        while dot and dot.Parent do
            Tween(dot, {BackgroundTransparency=0.25}, math.random()*2+1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(math.random()*2+1)
            Tween(dot, {BackgroundTransparency=0.82}, math.random()*2+1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(math.random()*2+1)
        end
    end)
end

local Header = Frame(MainWin, UDim2.new(1, 0, 0, 45), UDim2.new(0, 0, 0, 0), CFG.C.Surface, 0.2, 401, "Header")
Corner(Header, 18)
Gradient(Header, Color3.fromRGB(26, 20, 58), Color3.fromRGB(12, 10, 28), 100)

local LogoCircle = Frame(Header, UDim2.new(0, 30, 0, 30), UDim2.new(0, 10, 0.5, -15), CFG.C.Accent, 0, 402)
Corner(LogoCircle, 15)
Gradient(LogoCircle, Color3.fromRGB(145, 95, 255), Color3.fromRGB(82, 42, 200), 135)
Label(LogoCircle, UDim2.new(1,0,1,0), nil, "K", CFG.C.White, 16, CFG.Font, Enum.TextXAlignment.Center, 403)

local TitleLbl = Label(Header, UDim2.new(0, 200, 0, 18), UDim2.new(0, 48, 0, 6), "Kaelen", CFG.C.White, 15, CFG.Font, Enum.TextXAlignment.Left, 402)
local SubLbl   = Label(Header, UDim2.new(0, 240, 0, 14), UDim2.new(0, 48, 0, 24), "AI Systems v2.2  •  " .. State.CurrentMode, CFG.C.TextMuted, 9, CFG.FontReg, Enum.TextXAlignment.Left, 402)

local StatusDot = Frame(Header, UDim2.new(0, 8, 0, 8), UDim2.new(1, -45, 0.5, -4), CFG.C.Red, 0, 402)
Corner(StatusDot, 4)

local CloseBtn = Button(Header, UDim2.new(0, 28, 0, 28), UDim2.new(1, -36, 0.5, -14), Color3.fromRGB(198, 52, 72), "✕", CFG.C.White, 13, CFG.Font, 402)
Corner(CloseBtn, 14)

Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        State.WinDragging  = true; State.WinDragOrigin = Vector2.new(inp.Position.X, inp.Position.Y); State.WinPosOrigin  = MainWin.Position
    end
end)

local TabBar = Frame(MainWin, UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 50), CFG.C.Card, 0.12, 401)
Corner(TabBar, 10); Stroke(TabBar, CFG.C.Border, 1); HLayout(TabBar, 5, Enum.VerticalAlignment.Center); Pad(TabBar, 3, 3, 4, 4)

local TAB_NAMES = { "Chat", "Modos", "Config" }
local TabBtns   = {}
local function ShowPanel(name) end

local function SetTab(name)
    for _, tb in pairs(TabBtns) do
        if tb.name == name then
            Tween(tb.btn, {BackgroundColor3 = CFG.C.Accent, BackgroundTransparency = 0}, 0.2); Tween(tb.lbl, {TextColor3 = CFG.C.White}, 0.2)
        else
            Tween(tb.btn, {BackgroundColor3 = CFG.C.Card, BackgroundTransparency = 0.6}, 0.2); Tween(tb.lbl, {TextColor3 = CFG.C.TextMuted}, 0.2)
        end
    end
end

for _, name in ipairs(TAB_NAMES) do
    local btn = Button(TabBar, UDim2.new(0, 90, 1, 0), nil, CFG.C.Card, "", CFG.C.White, 11, CFG.Font, 402)
    btn.BackgroundTransparency = 0.6; Corner(btn, 8)
    local lbl = Label(btn, UDim2.new(1,0,1,0), nil, name, CFG.C.TextMuted, 11, CFG.Font, Enum.TextXAlignment.Center, 403)
    table.insert(TabBtns, {name=name, btn=btn, lbl=lbl})
    btn.MouseButton1Click:Connect(function() if State.KeyVerified then SetTab(name); ShowPanel(name) end end)
end

local PanelBox = Frame(MainWin, UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 86), Color3.fromRGB(0,0,0), 1, 400)

local KeyPanel = Frame(PanelBox, UDim2.new(1,0,1,0), nil, Color3.fromRGB(0,0,0), 1, 401, "KeyPanel")
VLayout(KeyPanel, 8, Enum.HorizontalAlignment.Center); Pad(KeyPanel, 10, 10, 0, 0)

local LockFrame = Frame(KeyPanel, UDim2.new(0, 50, 0, 50), nil, CFG.C.Card, 0.08, 402)
LockFrame.LayoutOrder = 1; Corner(LockFrame, 25); Stroke(LockFrame, CFG.C.Accent, 2)
Label(LockFrame, UDim2.new(1,0,1,0), nil, "🔑", CFG.C.White, 22, CFG.FontReg, Enum.TextXAlignment.Center, 403)

local KTitle = Label(KeyPanel, UDim2.new(1,0,0,22), nil, "Activar Kaelen", CFG.C.White, 16, CFG.Font, Enum.TextXAlignment.Center, 402); KTitle.LayoutOrder = 2
local KSub = Label(KeyPanel, UDim2.new(1,0,0,30), nil, "Introduce tu API Key de OpenRouter", CFG.C.TextMuted, 10, CFG.FontReg, Enum.TextXAlignment.Center, 402); KSub.LayoutOrder = 3

local KeyInput = Instance.new("TextBox")
KeyInput.Size = UDim2.new(1, -8, 0, 36); KeyInput.BackgroundColor3 = CFG.C.Card; KeyInput.BackgroundTransparency = 0.08
KeyInput.Text = ""; KeyInput.PlaceholderText = "sk-or-v1-xxxxxxxx"
KeyInput.TextColor3 = CFG.C.Text; KeyInput.PlaceholderColor3 = CFG.C.TextDim; KeyInput.TextSize = 11; KeyInput.Font = CFG.FontMon
KeyInput.ZIndex = 402; KeyInput.LayoutOrder = 4; KeyInput.BorderSizePixel = 0; KeyInput.Parent = KeyPanel
Corner(KeyInput, 10); Stroke(KeyInput, CFG.C.Border, 1); Pad(KeyInput, 0, 0, 10, 10)

local VerifyBtn = Button(KeyPanel, UDim2.new(1, -8, 0, 36), nil, CFG.C.Accent, "Verificar y Activar  ✦", CFG.C.White, 12, CFG.Font, 402)
VerifyBtn.LayoutOrder = 5; Corner(VerifyBtn, 10); Gradient(VerifyBtn, Color3.fromRGB(142, 92, 255), Color3.fromRGB(84, 44, 202), 135)

local KStatus = Label(KeyPanel, UDim2.new(1,0,0,16), nil, "", CFG.C.TextMuted, 10, CFG.FontReg, Enum.TextXAlignment.Center, 402); KStatus.LayoutOrder = 6

local ChatPanel = Frame(PanelBox, UDim2.new(1,0,1,0), nil, Color3.fromRGB(0,0,0), 1, 401, "ChatPanel"); ChatPanel.Visible = false
local MsgScroll = Scroll(ChatPanel, UDim2.new(1, 0, 1, -70), UDim2.new(0,0,0,0), 402)
VLayout(MsgScroll, 8, Enum.HorizontalAlignment.Left); Pad(MsgScroll, 6, 6, 4, 4)

local ThinkFrame = Frame(MsgScroll, UDim2.new(0, 140, 0, 28), nil, CFG.C.AIBub, 0.05, 403, "ThinkFrame")
ThinkFrame.LayoutOrder = 9999; ThinkFrame.Visible = false; Corner(ThinkFrame, 14); Stroke(ThinkFrame, CFG.C.Border, 1); Pad(ThinkFrame, 0, 0, 10, 10)
local ThinkLbl = Label(ThinkFrame, UDim2.new(1,0,1,0), nil, "Kaelen pensando ●○○", CFG.C.TextMuted, 11, CFG.FontReg, Enum.TextXAlignment.Left, 404)

local InputBar = Frame(ChatPanel, UDim2.new(1, 0, 0, 66), UDim2.new(0, 0, 1, -66), CFG.C.Surface, 0.18, 402)
Corner(InputBar, 12); Stroke(InputBar, CFG.C.Border, 1)

local ChatInput = Instance.new("TextBox")
ChatInput.Size = UDim2.new(1, -44, 0, 34); ChatInput.Position = UDim2.new(0, 6, 0, 6); ChatInput.BackgroundColor3 = CFG.C.Card; ChatInput.BackgroundTransparency = 0.08
ChatInput.Text = ""; ChatInput.PlaceholderText = "Pregúntale o pídele algo..."; ChatInput.TextColor3 = CFG.C.Text; ChatInput.PlaceholderColor3 = CFG.C.TextDim; ChatInput.TextSize = 11; ChatInput.Font = CFG.FontReg
ChatInput.ZIndex = 403; ChatInput.BorderSizePixel = 0; ChatInput.Parent = InputBar
Corner(ChatInput, 8); Pad(ChatInput, 0, 0, 10, 10)

local SendBtn = Button(InputBar, UDim2.new(0, 34, 0, 34), UDim2.new(1, -38, 0, 6), CFG.C.Accent, "➤", CFG.C.White, 14, CFG.Font, 403)
Corner(SendBtn, 8); Gradient(SendBtn, Color3.fromRGB(142, 92, 255), Color3.fromRGB(84, 44, 202), 135)

local QuickBar = Frame(InputBar, UDim2.new(1, -8, 0, 22), UDim2.new(0, 4, 0, 42), Color3.fromRGB(0,0,0), 1, 403)
HLayout(QuickBar, 5, Enum.VerticalAlignment.Center)

local QUICK_CMDS = { { icon = "🎮", label = "Analizar", id = "analyze" }, { icon = "🚀", label = "Volar", id = "fly" }, { icon = "👻", label = "Noclip", id = "noclip" }, { icon = "🗑",  label = "Limpiar", id = "clear" } }
local QuickRefs = {}
for _, qc in ipairs(QUICK_CMDS) do
    local qb = Button(QuickBar, UDim2.new(0, 0, 1, 0), nil, CFG.C.Card, qc.icon .. " " .. qc.label, CFG.C.TextMuted, 9, CFG.FontReg, 404)
    qb.AutomaticSize = Enum.AutomaticSize.X; qb.BackgroundTransparency = 0.3; Corner(qb, 5); Pad(qb, 1, 1, 5, 5)
    table.insert(QuickRefs, { btn = qb, id = qc.id })
end

local ModesPanel = Scroll(PanelBox, UDim2.new(1,0,1,0), nil, 401); ModesPanel.Name = "ModesPanel"; ModesPanel.Visible = false
VLayout(ModesPanel, 6, Enum.HorizontalAlignment.Center); Pad(ModesPanel, 4, 4, 0, 0)
Label(ModesPanel, UDim2.new(1,0,0,20), nil, "Modo de Kaelen", CFG.C.White, 14, CFG.Font, Enum.TextXAlignment.Center, 402).LayoutOrder = 0
Label(ModesPanel, UDim2.new(1,0,0,14), nil, "Elige cómo razona Kaelen", CFG.C.TextMuted, 9, CFG.FontReg, Enum.TextXAlignment.Center, 402).LayoutOrder = 1

local MODE_LIST = {
    { name = "Programador", icon = "💻", col = Color3.fromRGB(78, 198, 255), desc = "Scripts Lua, optimización y debugging" },
    { name = "Analista",    icon = "🔍", col = Color3.fromRGB(112, 72, 255), desc = "Análisis de juego y vulnerabilidades" },
    { name = "Creativo",    icon = "🎨", col = Color3.fromRGB(255, 138, 78), desc = "Ideas innovadoras de mecánicas" },
    { name = "Troll",       icon = "😈", col = Color3.fromRGB(255, 78, 128), desc = "Trolleos creativos en el juego" },
}
local ModeRefs = {}
for i, md in ipairs(MODE_LIST) do
    local active = (md.name == State.CurrentMode)
    local card = Button(ModesPanel, UDim2.new(1, 0, 0, 50), nil, CFG.C.Card, "", CFG.C.White, 13, CFG.Font, 402)
    card.BackgroundTransparency = active and 0.05 or 0.3; card.LayoutOrder = i + 1; Corner(card, 10)
    local cardStroke = Stroke(card, active and CFG.C.Accent or CFG.C.Border, active and 1.5 or 1)
    local iconCircle = Frame(card, UDim2.new(0, 34, 0, 34), UDim2.new(0, 10, 0.5, -17), md.col, 0.12, 403); Corner(iconCircle, 17)
    Label(iconCircle, UDim2.new(1,0,1,0), nil, md.icon, CFG.C.White, 16, CFG.FontReg, Enum.TextXAlignment.Center, 404)
    Label(card, UDim2.new(1, -60, 0, 16), UDim2.new(0, 52, 0, 8), md.name, CFG.C.White, 12, CFG.Font, Enum.TextXAlignment.Left, 403)
    Label(card, UDim2.new(1, -60, 0, 14), UDim2.new(0, 52, 0, 26), md.desc, CFG.C.TextMuted, 9, CFG.FontReg, Enum.TextXAlignment.Left, 403)
    local badge = Frame(card, UDim2.new(0, 8, 0, 8), UDim2.new(1, -16, 0.5, -4), md.col, active and 0 or 1, 403); Corner(badge, 4)
    table.insert(ModeRefs, { card = card, stroke = cardStroke, badge = badge, name = md.name, col = md.col })
    card.MouseButton1Click:Connect(function()
        State.CurrentMode = md.name; SubLbl.Text = "AI Systems v2.2  •  " .. State.CurrentMode
        for _, mr in pairs(ModeRefs) do
            local isNow = (mr.name == md.name)
            Tween(mr.card,  { BackgroundTransparency = isNow and 0.05 or 0.3 }, 0.22); Tween(mr.badge, { BackgroundTransparency = isNow and 0 or 1 }, 0.22)
        end
    end)
end

local ConfigPanel = Scroll(PanelBox, UDim2.new(1,0,1,0), nil, 401); ConfigPanel.Name = "ConfigPanel"; ConfigPanel.Visible = false
VLayout(ConfigPanel, 8, Enum.HorizontalAlignment.Center); Pad(ConfigPanel, 4, 4, 0, 0)
Label(ConfigPanel, UDim2.new(1,0,0,20), nil, "Configuración", CFG.C.White, 14, CFG.Font, Enum.TextXAlignment.Center, 402).LayoutOrder = 0

local InfoCard = Frame(ConfigPanel, UDim2.new(1,0,0,55), nil, CFG.C.Card, 0.18, 402); InfoCard.LayoutOrder = 4; Corner(InfoCard, 10); Stroke(InfoCard, CFG.C.Border, 1); Pad(InfoCard, 6, 6, 10, 10)
Label(InfoCard, UDim2.new(1,0,1,0), nil, "⚡ Kaelen v2.2 — Triple Engine\n🟢 Fast: Gemma 3 (Comandos)\n🔵 Coder: Qwen3 (Scripts)\n🟣 Reason: Llama 3.3 (Análisis)", CFG.C.TextMuted, 9, CFG.FontReg, Enum.TextXAlignment.Left, 403)

local ClearHistBtn = Button(ConfigPanel, UDim2.new(1,0,0,32), nil, CFG.C.Card, "🗑  Borrar Historial", CFG.C.TextMuted, 11, CFG.Font, 402)
ClearHistBtn.LayoutOrder = 5; ClearHistBtn.BackgroundTransparency = 0.2; Corner(ClearHistBtn, 10); Stroke(ClearHistBtn, CFG.C.Border, 1)

local ResetKeyBtn = Button(ConfigPanel, UDim2.new(1,0,0,32), nil, CFG.C.Red, "⚠  Resetear API Key", CFG.C.White, 11, CFG.Font, 402)
ResetKeyBtn.LayoutOrder = 6; ResetKeyBtn.BackgroundTransparency = 0.28; Corner(ResetKeyBtn, 10)

local PANEL_MAP = { Key = KeyPanel, Chat = ChatPanel, Modos = ModesPanel, Config = ConfigPanel }
local ALL_PANELS = { KeyPanel, ChatPanel, ModesPanel, ConfigPanel }

ShowPanel = function(name)
    for _, p in ipairs(ALL_PANELS) do p.Visible = false end
    if PANEL_MAP[name] then PANEL_MAP[name].Visible = true end
end

local function ScrollBottom()
    task.delay(0.06, function() if MsgScroll and MsgScroll.Parent then MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y + 9999) end end)
end

local function AddMessage(role, content)
    table.insert(State.Messages, { role = role, content = content })
    if #State.Messages > CFG.MaxHistory then table.remove(State.Messages, 1) end
    State.MsgCount = State.MsgCount + 1

    local isUser = (role == "user")
    local row = Frame(MsgScroll, UDim2.new(1, 0, 0, 0), nil, Color3.fromRGB(0,0,0), 1, 403); row.AutomaticSize = Enum.AutomaticSize.Y; row.LayoutOrder = State.MsgCount
    local bub = Frame(row, UDim2.new(0.84, 0, 0, 0), nil, isUser and CFG.C.UserBub or CFG.C.AIBub, 0.05, 404)
    bub.AutomaticSize = Enum.AutomaticSize.Y; bub.Position = isUser and UDim2.new(0.16, 0, 0, 0) or UDim2.new(0, 0, 0, 0); Corner(bub, 12); if not isUser then Stroke(bub, CFG.C.Border, 1) end; Pad(bub, 8, 8, 10, 10)
    VLayout(bub, 4, isUser and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left)

    local authLbl = Label(bub, UDim2.new(1,0,0,12), nil, isUser and ("🧑 " .. LocalPlayer.Name) or "⬡ Kaelen", isUser and Color3.fromRGB(185, 158, 255) or CFG.C.Accent, 9, CFG.Font, isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left, 405); authLbl.LayoutOrder = 1
    local contentLbl = Label(bub, UDim2.new(1,0,0,0), nil, content, CFG.C.Text, 11, CFG.FontReg, isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left, 405); contentLbl.AutomaticSize = Enum.AutomaticSize.Y; contentLbl.LayoutOrder = 2

    bub.BackgroundTransparency = 1; Tween(bub, { BackgroundTransparency = 0.05 }, 0.28); ScrollBottom()
end

function SetThinking(active)
    State.IsThinking = active; ThinkFrame.Visible = active
    if active then
        ThinkFrame.LayoutOrder = State.MsgCount + 1
        if State.ThinkTask then task.cancel(State.ThinkTask) end
        State.ThinkTask = task.spawn(function()
            local frames = { "●○○", "●●○", "●●●", "○●●", "○○●", "○○○" }
            local i = 1
            while State.IsThinking do if ThinkLbl and ThinkLbl.Parent then ThinkLbl.Text = "Kaelen pensando " .. frames[i] end; i = i % #frames + 1; task.wait(0.28) end
        end)
        ScrollBottom()
    else
        if State.ThinkTask then task.cancel(State.ThinkTask); State.ThinkTask = nil end
    end
end

local function DoSend(text)
    text = (text or ""):match("^%s*(.-)%s*$")
    if text == "" or State.IsThinking then return end
    ChatInput.Text = ""
    AddMessage("user", text)
    SetThinking(true)
    task.spawn(function()
        local response, err = OrchestrateKaelen(text, State.Messages)
        SetThinking(false)
        if err then
            AddMessage("assistant", "⚠️ Error:\n" .. tostring(err))
        else
            ExecuteAICommands(response)
            AddMessage("assistant", response or "(Sin respuesta)")
        end
    end)
end

SendBtn.MouseButton1Click:Connect(function() DoSend(ChatInput.Text) end)
ChatInput.FocusLost:Connect(function(enter) if enter then DoSend(ChatInput.Text) end end)

for _, qr in pairs(QuickRefs) do
    qr.btn.MouseButton1Click:Connect(function()
        local id = qr.id
        if id == "analyze" then DoSend("🎮 Analiza este juego: " .. GetGameContext())
        elseif id == "fly" then DoSend("Kaelen, activa mi modo vuelo")
        elseif id == "noclip" then DoSend("Kaelen, activa el noclip (atravesar paredes)")
        elseif id == "clear" then
            for _, child in ipairs(MsgScroll:GetChildren()) do if child:IsA("Frame") and child.Name ~= "ThinkFrame" then child:Destroy() end end
            State.Messages = {}; State.MsgCount = 0; AddMessage("assistant", "🗑 Historial limpiado.")
        end
    end)
end

VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text:match("^%s*(.-)%s*$")
    if key == "" then return end
    VerifyBtn.Text = "⏳  Conectando..."; VerifyBtn.BackgroundTransparency = 0.3; KStatus.Text = "Verificando..."
    task.spawn(function()
        local ok, err = VerifyAPIKey(key)
        if ok then
            State.APIKey = key; State.KeyVerified = true
            KStatus.TextColor3 = CFG.C.Green; KStatus.Text = "✅  Activado"; Tween(StatusDot, { BackgroundColor3 = CFG.C.Green }, 0.5)
            VerifyBtn.Text = "✦  Activo"; VerifyBtn.BackgroundTransparency = 0.2; task.wait(0.85); ShowPanel("Chat"); SetTab("Chat")
            AddMessage("assistant", "⬡ Hola. Ahora soy mucho más rápido para ejecutar tus comandos.\n\nPuedes pedirme:\n• Activa el noclip\n• Ponme modo vuelo\n• Dame velocidad 100")
        else
            State.KeyVerified = false; KStatus.TextColor3 = CFG.C.Red; KStatus.Text = "❌  " .. (err or "Key inválida"); VerifyBtn.Text = "Verificar  ✦"; VerifyBtn.BackgroundTransparency = 0
        end
    end)
end)

ClearHistBtn.MouseButton1Click:Connect(function()
    State.Messages = {}; State.MsgCount = 0
    for _, child in ipairs(MsgScroll:GetChildren()) do if child:IsA("Frame") and child.Name ~= "ThinkFrame" then child:Destroy() end end
end)

ResetKeyBtn.MouseButton1Click:Connect(function()
    State.APIKey = ""; State.KeyVerified = false; State.Messages = {}; State.MsgCount = 0
    KeyInput.Text = ""; KStatus.Text = ""; Tween(StatusDot, { BackgroundColor3 = CFG.C.Red }, 0.4)
    for _, child in ipairs(MsgScroll:GetChildren()) do if child:IsA("Frame") and child.Name ~= "ThinkFrame" then child:Destroy() end end
    ShowPanel("Key")
end)

function OpenWindow()
    State.IsOpen = true; MainWin.Visible = true
    local ox = FloatBtn.Position.X.Offset + 24; local oy = FloatBtn.Position.Y.Offset + 24
    MainWin.Size = UDim2.new(0, 0, 0, 0); MainWin.Position = UDim2.new(FloatBtn.Position.X.Scale, ox, FloatBtn.Position.Y.Scale, oy)
    Tween(MainWin, { Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0.5, -W/2, 0.5, -H/2) }, 0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function CloseWindow()
    State.IsOpen = false
    local ox = FloatBtn.Position.X.Offset + 24; local oy = FloatBtn.Position.Y.Offset + 24
    Tween(MainWin, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(FloatBtn.Position.X.Scale, ox, FloatBtn.Position.Y.Scale, oy) }, 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.28, function() if MainWin and MainWin.Parent then MainWin.Visible = false end end)
end

CloseBtn.MouseButton1Click:Connect(CloseWindow)

ShowPanel("Key"); SetTab("Chat")
