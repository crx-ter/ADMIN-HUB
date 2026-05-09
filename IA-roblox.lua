--[[
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ██╗  ██╗ █████╗ ███████╗██╗     ███████╗███╗   ██╗           ║
║   ██║ ██╔╝██╔══██╗██╔════╝██║     ██╔════╝████╗  ██║           ║
║   █████╔╝ ███████║█████╗  ██║     █████╗  ██╔██╗ ██║           ║
║   ██╔═██╗ ██╔══██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║           ║
║   ██║  ██╗██║  ██║███████╗███████╗███████╗██║ ╚████║           ║
║   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝           ║
║                                                                  ║
║   KAELEN AI  ·  VERSION 3.0 PHANTOM EDITION                     ║
║   Triple-Engine Orchestrator  ·  Mobile-First Architecture      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════════════════════════════════
-- [1] SERVICIOS
-- ══════════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ══════════════════════════════════════════════════════════════════
-- [2] LIMPIEZA ANTI-DUPLICACIÓN
-- ══════════════════════════════════════════════════════════════════
for _, gui in ipairs({CoreGui, LocalPlayer:WaitForChild("PlayerGui", 3)}) do
    if gui then
        pcall(function()
            local old = gui:FindFirstChild("KaelenUI_v3")
            if old then old:Destroy() end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [3] CONFIGURACIÓN GLOBAL
-- ══════════════════════════════════════════════════════════════════
local CFG = {
    Version      = "3.0 Phantom",
    ApiURL       = "https://openrouter.ai/api/v1/chat/completions",
    MaxTokens    = 2000,
    Temperature  = 0.72,
    MaxHistory   = 60,

    -- Modelos
    M = {
        Fast   = "google/gemma-3-27b-it:free",
        Coder  = "qwen/qwen3-coder:free",
        Reason = "meta-llama/llama-3.3-70b-instruct:free",
    },

    -- Dimensiones de ventana
    W = { W = 460, H = 520 },

    -- Paleta de colores refinada
    C = {
        -- Fondos
        BG          = Color3.fromRGB(6,   6,  14),
        Surface     = Color3.fromRGB(11,  10,  24),
        Card        = Color3.fromRGB(17,  16,  36),
        CardHover   = Color3.fromRGB(24,  22,  48),

        -- Bordes
        Border      = Color3.fromRGB(40,  36,  82),
        BorderHi    = Color3.fromRGB(90,  60, 200),

        -- Acento principal (índigo eléctrico)
        Accent      = Color3.fromRGB(100,  58, 248),
        AccentDim   = Color3.fromRGB( 62,  34, 160),
        AccentGlow  = Color3.fromRGB(148, 108, 255),
        AccentSoft  = Color3.fromRGB( 30,  20,  70),

        -- Burbujas de chat
        UserBubble  = Color3.fromRGB( 78,  42, 220),
        AIBubble    = Color3.fromRGB( 16,  15,  34),

        -- Texto
        Text        = Color3.fromRGB(230, 226, 255),
        TextSub     = Color3.fromRGB(148, 140, 200),
        TextDim     = Color3.fromRGB( 70,  64, 120),
        White       = Color3.fromRGB(255, 255, 255),
        Black       = Color3.fromRGB(  0,   0,   0),

        -- Estados
        Success     = Color3.fromRGB( 56, 210, 120),
        Danger      = Color3.fromRGB(255,  60,  86),
        Warning     = Color3.fromRGB(255, 190,  50),
        Info        = Color3.fromRGB( 50, 180, 255),
    },

    -- Fuentes
    F = {
        Bold    = Enum.Font.GothamBold,
        Semi    = Enum.Font.GothamSemibold,
        Regular = Enum.Font.Gotham,
        Mono    = Enum.Font.Code,
    },
}

-- ══════════════════════════════════════════════════════════════════
-- [4] ESTADO DE LA APLICACIÓN
-- ══════════════════════════════════════════════════════════════════
local S = {
    APIKey       = "",
    Verified     = false,
    WinOpen      = false,
    Thinking     = false,
    Messages     = {},
    MsgCount     = 0,
    Mode         = "Analista",
    CustomSys    = "",
    ThinkThread  = nil,
    ActivePanel  = "Key",

    -- Motor físico
    Fly          = { Active = false, Conn = nil },
    Noclip       = { Active = false, Conn = nil },

    -- Drag botón flotante
    BtnDrag = {
        Active     = false,
        Origin     = Vector2.zero,
        PosOrigin  = UDim2.new(0,0,0,0),
        TotalMoved = 0,
    },

    -- Drag ventana
    WinDrag = {
        Active    = false,
        Origin    = Vector2.zero,
        PosOrigin = UDim2.new(0,0,0,0),
    },
}

-- ══════════════════════════════════════════════════════════════════
-- [5] UTILIDADES DE UI  ──  Framework minimalista interno
-- ══════════════════════════════════════════════════════════════════

local function Tween(obj, props, t, style, dir)
    if not obj or not obj.Parent then return end
    local ti = TweenInfo.new(
        t     or 0.25,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(obj, ti, props)
    tw:Play()
    return tw
end

local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 12)
    c.Parent = p
    return c
end

local function Stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color              = col   or CFG.C.Border
    s.Thickness          = thick or 1
    s.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function Pad(p, t, b, l, r)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, t or 8)
    pad.PaddingBottom = UDim.new(0, b or 8)
    pad.PaddingLeft   = UDim.new(0, l or 8)
    pad.PaddingRight  = UDim.new(0, r or 8)
    pad.Parent = p
    return pad
end

local function VList(p, gap, ha)
    local l = Instance.new("UIListLayout")
    l.FillDirection      = Enum.FillDirection.Vertical
    l.HorizontalAlignment = ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment  = Enum.VerticalAlignment.Top
    l.Padding            = UDim.new(0, gap or 0)
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function HList(p, gap, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection      = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
    l.VerticalAlignment  = va or Enum.VerticalAlignment.Center
    l.Padding            = UDim.new(0, gap or 0)
    l.SortOrder          = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function Gradient(p, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent   = p
    return g
end

-- Constructores base
local function Frame(parent, size, pos, bg, transp, z, name)
    local f = Instance.new("Frame")
    f.Size                  = size   or UDim2.new(1,0,1,0)
    f.Position              = pos    or UDim2.new(0,0,0,0)
    f.BackgroundColor3      = bg     or CFG.C.Card
    f.BackgroundTransparency= transp or 0
    f.ZIndex                = z      or 2
    f.BorderSizePixel       = 0
    if name then f.Name = name end
    f.Parent = parent
    return f
end

local function Label(parent, size, pos, text, col, ts, font, xa, z)
    local l = Instance.new("TextLabel")
    l.Size                  = size  or UDim2.new(1,0,0,20)
    l.Position              = pos   or UDim2.new(0,0,0,0)
    l.BackgroundTransparency= 1
    l.Text                  = text  or ""
    l.TextColor3            = col   or CFG.C.Text
    l.TextSize              = ts    or 13
    l.Font                  = font  or CFG.F.Regular
    l.TextXAlignment        = xa    or Enum.TextXAlignment.Left
    l.ZIndex                = z     or 2
    l.TextWrapped           = true
    l.BorderSizePixel       = 0
    l.Parent = parent
    return l
end

local function Button(parent, size, pos, bg, text, tc, ts, font, z)
    local b = Instance.new("TextButton")
    b.Size                  = size  or UDim2.new(1,0,0,40)
    b.Position              = pos   or UDim2.new(0,0,0,0)
    b.BackgroundColor3      = bg    or CFG.C.Accent
    b.Text                  = text  or ""
    b.TextColor3            = tc    or CFG.C.White
    b.TextSize              = ts    or 13
    b.Font                  = font  or CFG.F.Bold
    b.ZIndex                = z     or 2
    b.AutoButtonColor       = false
    b.BorderSizePixel       = 0
    b.Parent = parent
    return b
end

local function Scroll(parent, size, pos, z)
    local s = Instance.new("ScrollingFrame")
    s.Size                  = size or UDim2.new(1,0,1,0)
    s.Position              = pos  or UDim2.new(0,0,0,0)
    s.BackgroundTransparency= 1
    s.ScrollBarThickness    = 2
    s.ScrollBarImageColor3  = CFG.C.Accent
    s.CanvasSize            = UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    s.ZIndex                = z or 2
    s.BorderSizePixel       = 0
    s.Parent = parent
    return s
end

local function TextBox(parent, size, pos, placeholder, z)
    local tb = Instance.new("TextBox")
    tb.Size                   = size or UDim2.new(1,0,0,36)
    tb.Position               = pos  or UDim2.new(0,0,0,0)
    tb.BackgroundColor3       = CFG.C.Card
    tb.BackgroundTransparency = 0.1
    tb.Text                   = ""
    tb.PlaceholderText        = placeholder or ""
    tb.TextColor3             = CFG.C.Text
    tb.PlaceholderColor3      = CFG.C.TextDim
    tb.TextSize               = 11
    tb.Font                   = CFG.F.Regular
    tb.ClearTextOnFocus       = false
    tb.ZIndex                 = z or 2
    tb.BorderSizePixel        = 0
    tb.Parent = parent
    return tb
end

-- ══════════════════════════════════════════════════════════════════
-- [6] MOTOR FÍSICO  ──  Fly · Noclip · Speed · Jump · Heal
-- ══════════════════════════════════════════════════════════════════

local function SetFly(on)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    S.Fly.Active = on

    if on then
        if S.Fly.Conn then return end

        local bv = Instance.new("BodyVelocity")
        bv.Name      = "_KFlyV"
        bv.Velocity  = Vector3.zero
        bv.MaxForce  = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent    = hrp

        local bg = Instance.new("BodyGyro")
        bg.Name      = "_KFlyG"
        bg.P         = 90000
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame    = hrp.CFrame
        bg.Parent    = hrp

        S.Fly.Conn = RunService.RenderStepped:Connect(function()
            local cam = Camera.CFrame
            local mv  = Vector3.zero
            local UIS = UserInputService

            if UIS:IsKeyDown(Enum.KeyCode.W) then mv += cam.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= cam.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= cam.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv += cam.RightVector end

            local vy = 0
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then vy =  1 end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vy = -1 end

            local dir = mv * Vector3.new(1,0,1)
            if dir.Magnitude > 0 then dir = dir.Unit end

            bv.Velocity = dir * 55 + Vector3.new(0, vy * 55, 0)
            bg.CFrame   = cam
        end)
    else
        if S.Fly.Conn then S.Fly.Conn:Disconnect(); S.Fly.Conn = nil end
        for _, n in ipairs({"_KFlyV", "_KFlyG"}) do
            local p = hrp:FindFirstChild(n)
            if p then p:Destroy() end
        end
    end
end

local function SetNoclip(on)
    S.Noclip.Active = on

    if on then
        if S.Noclip.Conn then return end
        S.Noclip.Conn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    else
        if S.Noclip.Conn then S.Noclip.Conn:Disconnect(); S.Noclip.Conn = nil end
        local char = LocalPlayer.Character
        if char then
            for _, n in ipairs({"HumanoidRootPart","UpperTorso","Torso","Head"}) do
                local p = char:FindFirstChild(n)
                if p and p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

local function ParseAICommands(text)
    if type(text) ~= "string" then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if text:match("%[FLY:on%]")    then SetFly(true)    end
    if text:match("%[FLY:off%]")   then SetFly(false)   end
    if text:match("%[NOCLIP:on%]") then SetNoclip(true)  end
    if text:match("%[NOCLIP:off%]")then SetNoclip(false) end

    if hum then
        local spd = text:match("%[SPEED:(%d+)%]")
        if spd then hum.WalkSpeed = tonumber(spd) end

        local jmp = text:match("%[JUMP:(%d+)%]")
        if jmp then
            hum.UseJumpPower = true
            hum.JumpPower    = tonumber(jmp)
        end

        if text:match("%[HEAL%]") then hum.Health = hum.MaxHealth end
    end
end

-- ══════════════════════════════════════════════════════════════════
-- [7] PROMPTS DEL SISTEMA
-- ══════════════════════════════════════════════════════════════════
local CMD_BLOCK = [[

══ CONTROL DIRECTO DEL JUEGO ══
Tienes acceso al motor físico del juego. Cuando el usuario pida acciones sobre su personaje, incluye UNA de estas etiquetas exactas en tu respuesta:

  [FLY:on]       → Activar vuelo
  [FLY:off]      → Desactivar vuelo
  [NOCLIP:on]    → Atravesar paredes
  [NOCLIP:off]   → Restaurar colisiones
  [SPEED:número] → Cambiar velocidad (ej: [SPEED:80])
  [JUMP:número]  → Cambiar salto (ej: [JUMP:180])
  [HEAL]         → Curar al jugador al máximo

Confirma la acción con una respuesta breve y natural.
]]

local PROMPTS = {
    Programador = [[
Eres Kaelen, experto definitivo en Lua/Luau para Roblox.
MISIÓN: Generar scripts limpios, modulares y robustos con calidad de producción.
- Usa task.spawn/task.delay, evita wait() heredado.
- Comenta el código de forma clara y concisa.
- Detecta y corrige vulnerabilidades proactivamente.
- Encapsula siempre el código en bloques ```lua.
]] .. CMD_BLOCK,

    Analista = [[
Eres Kaelen, analista experto en arquitectura y seguridad de juegos Roblox.
MISIÓN: Analizar profundamente mecánicas, detectar exploits y evaluar rendimiento.
- Estructura: Arquitectura → Vulnerabilidades → Rendimiento → Recomendaciones.
- Prioriza hallazgos por severidad: 🔴 Crítica · 🟠 Alta · 🟡 Media · 🟢 Baja.
- Sé técnico, directo y proporciona soluciones concretas.
]] .. CMD_BLOCK,

    Creativo = [[
Eres Kaelen, Game Designer especializado en experiencias únicas para Roblox.
MISIÓN: Concebir mecánicas originales, sistemas de progresión y retención.
- Detalla Core Game Loops y ganchos de jugabilidad.
- Propón sistemas de economía y monetización ética.
- Sé descriptivo, entusiasta y visionario.
]] .. CMD_BLOCK,

    Asistente = [[
Eres Kaelen, asistente general inteligente integrado en Roblox.
Responde preguntas, explica conceptos, ayuda con tareas generales.
Sé claro, útil y conciso. Usa ejemplos cuando sea útil.
]] .. CMD_BLOCK,
}

-- ══════════════════════════════════════════════════════════════════
-- [8] RED  ──  HTTP / OpenRouter
-- ══════════════════════════════════════════════════════════════════

local function GetHTTP()
    local candidates = {
        function() return request     end,
        function() return http_request end,
        function() return syn and syn.request end,
        function() return fluxus and fluxus.request end,
        function() return KRNL_request end,
        function() return getgenv and getgenv().request end,
        function() return http and http.request end,
    }
    for _, fn in ipairs(candidates) do
        local ok, f = pcall(fn)
        if ok and type(f) == "function" then return f end
    end
    return nil
end

local function CallAPI(model, messages, sysPrompt)
    if not S.Verified or S.APIKey == "" then
        return nil, "API Key no verificada."
    end

    local http = GetHTTP()
    if not http then
        return nil, "Tu ejecutor no soporta peticiones HTTP (request)."
    end

    -- Construir payload
    local payload = { role = "system", content = sysPrompt }
    local msgs = {}
    if sysPrompt and #sysPrompt > 0 then
        table.insert(msgs, payload)
    end
    for _, m in ipairs(messages) do
        if m.role and m.content then
            table.insert(msgs, { role = m.role, content = m.content })
        end
    end

    local ok, body = pcall(HttpService.JSONEncode, HttpService, {
        model       = model,
        max_tokens  = CFG.MaxTokens,
        temperature = CFG.Temperature,
        messages    = msgs,
    })
    if not ok then return nil, "Error al codificar JSON." end

    local ok2, res = pcall(http, {
        Url     = CFG.ApiURL,
        Method  = "POST",
        Headers = {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. S.APIKey,
        },
        Body = body,
    })

    if not ok2 then return nil, "Petición HTTP bloqueada: " .. tostring(res) end
    if type(res) ~= "table" then return nil, "Respuesta inválida del servidor." end

    if res.StatusCode ~= 200 then
        local msg = "HTTP " .. tostring(res.StatusCode)
        pcall(function()
            local d = HttpService:JSONDecode(res.Body)
            if d and d.error then msg = msg .. " · " .. tostring(d.error.message) end
        end)
        return nil, msg
    end

    local ok3, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not ok3 then return nil, "JSON de respuesta corrupto." end

    if data and data.choices and data.choices[1] then
        local content = data.choices[1].message and data.choices[1].message.content
        if content then return content, nil end
    end

    return nil, "La API no devolvió texto en la respuesta."
end

local function VerifyKey(key)
    local bk, bv = S.APIKey, S.Verified
    S.APIKey, S.Verified = key, true

    local _, err = CallAPI(CFG.M.Fast,
        {{ role = "user", content = "Responde solo: OK" }},
        "Responde exactamente con: OK"
    )

    if err then
        S.APIKey, S.Verified = bk, bv
        return false, err
    end
    return true, nil
end

-- ══════════════════════════════════════════════════════════════════
-- [9] ORQUESTADOR  ──  Routing inteligente de modelos
-- ══════════════════════════════════════════════════════════════════
local KW_CODE   = {"script","lua","código","codigo","función","funcion","optimiza","debug","module","require","pcall"}
local KW_ACTION = {"vuela","volar","fly","noclip","paredes","velocidad","speed","salto","jump","cura","heal","atraviesa","activa","pon mi","hazme","hazlo"}

local function HasKeyword(text, list)
    local t = text:lower()
    for _, w in ipairs(list) do
        if t:find(w, 1, true) then return true end
    end
    return false
end

local function Orchestrate(userText, history)
    local sysPmt = (#S.CustomSys > 0) and S.CustomSys or (PROMPTS[S.Mode] or PROMPTS.Analista)

    -- Ruta ACCIÓN → Gemma (rápido)
    if HasKeyword(userText, KW_ACTION) then
        local r, e = CallAPI(CFG.M.Fast, history, sysPmt)
        if e then return nil, "Motor rápido: " .. e end
        return "⚡ **Acción · Gemma-3**\n\n" .. r, nil
    end

    -- Ruta CÓDIGO → Qwen3 (generación) + Llama (revisión)
    if HasKeyword(userText, KW_CODE) or S.Mode == "Programador" then
        local r1, e1 = CallAPI(CFG.M.Coder, history,
            sysPmt .. "\n\n[FASE GENERACIÓN]: Produce únicamente el código Lua solicitado.")
        if e1 then return nil, "Generador de código: " .. e1 end

        local reviewMsgs = {{
            role    = "user",
            content = "El usuario pidió:\n" .. userText ..
                      "\n\nCódigo generado por Qwen3:\n```lua\n" .. r1 .. "\n```\n\n" ..
                      "Revisa, corrige errores si los hay y presenta la versión final explicada."
        }}
        local r2, e2 = CallAPI(CFG.M.Reason, reviewMsgs,
            "Eres el módulo supervisor. Revisa y mejora el código Lua presentado.")
        if e2 then
            return "⚡ **Qwen3-Coder** *(sin revisión)*\n\n" .. r1, nil
        end
        return "🔀 **Dual Engine · Qwen3 + Llama 3.3**\n\n" .. r2, nil
    end

    -- Ruta GENERAL → Llama 3.3
    local r, e = CallAPI(CFG.M.Reason, history, sysPmt)
    if e then return nil, "Motor de razonamiento: " .. e end
    return "🧠 **Llama 3.3 70B**\n\n" .. r, nil
end

-- ══════════════════════════════════════════════════════════════════
-- [10] CONTEXTO DEL JUEGO
-- ══════════════════════════════════════════════════════════════════
local function GameContext()
    local t = {}
    pcall(function() t.game    = game.Name           end)
    pcall(function() t.placeId = tostring(game.PlaceId) end)
    pcall(function() t.players = tostring(#Players:GetPlayers()) end)
    pcall(function() t.me      = LocalPlayer.Name    end)

    local ok, j = pcall(HttpService.JSONEncode, HttpService, t)
    return ok and j or "{}"
end

-- ══════════════════════════════════════════════════════════════════
-- [11] CONSTRUCCIÓN DE LA INTERFAZ
-- ══════════════════════════════════════════════════════════════════
print("[Kaelen v3] Construyendo interfaz...")

-- ScreenGui raíz
local GUI = Instance.new("ScreenGui")
GUI.Name             = "KaelenUI_v3"
GUI.ResetOnSpawn     = false
GUI.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder     = 9999
GUI.IgnoreGuiInset   = true

-- Inyección segura
if not pcall(function() GUI.Parent = CoreGui end) then
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ─────────────────────────────────────────────────────────────────
-- BOTÓN FLOTANTE
-- ─────────────────────────────────────────────────────────────────
local FAB = Instance.new("ImageButton")
FAB.Name              = "FAB"
FAB.Size              = UDim2.new(0, 52, 0, 52)
FAB.Position          = UDim2.new(1, -66, 0.62, -26)
FAB.BackgroundColor3  = CFG.C.Accent
FAB.Image             = ""
FAB.AutoButtonColor   = false
FAB.ZIndex            = 600
FAB.BorderSizePixel   = 0
FAB.Parent            = GUI

Corner(FAB, 26)
Stroke(FAB, CFG.C.AccentGlow, 1.5)
Gradient(FAB, Color3.fromRGB(128, 78, 255), Color3.fromRGB(76, 38, 196), 135)

-- Halo del botón
local Halo = Frame(FAB, UDim2.new(0,86,0,86), UDim2.new(0.5,-43,0.5,-43),
    CFG.C.Accent, 0.75, 599, "Halo")
Corner(Halo, 43)

-- Letra K
local FabK = Label(FAB, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "K", CFG.C.White, 22, CFG.F.Bold, Enum.TextXAlignment.Center, 601)

-- Animación del halo
task.spawn(function()
    while FAB and FAB.Parent do
        Tween(Halo, {BackgroundTransparency=0.55, Size=UDim2.new(0,96,0,96), Position=UDim2.new(0.5,-48,0.5,-48)}, 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.6)
        Tween(Halo, {BackgroundTransparency=0.88, Size=UDim2.new(0,72,0,72), Position=UDim2.new(0.5,-36,0.5,-36)}, 1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.6)
    end
end)

-- ─────────────────────────────────────────────────────────────────
-- VENTANA PRINCIPAL
-- ─────────────────────────────────────────────────────────────────
local WIN = Frame(GUI,
    UDim2.new(0, CFG.W.W, 0, CFG.W.H),
    UDim2.new(0.5, -CFG.W.W/2, 0.5, -CFG.W.H/2),
    CFG.C.BG, 0, 400, "MainWindow")
WIN.ClipsDescendants = true
WIN.Visible          = false

Corner(WIN, 20)
Stroke(WIN, Color3.fromRGB(52, 42, 110), 1)

-- Degradado de fondo sutil
do
    local bg = Frame(WIN, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), CFG.C.BG, 0, 399, "BG")
    Gradient(bg, Color3.fromRGB(9,8,22), Color3.fromRGB(5,5,12), 145)
end

-- Barra superior de color
local TopBar = Frame(WIN, UDim2.new(1,0,0,2), UDim2.new(0,0,0,0),
    CFG.C.Accent, 0, 401, "TopBar")
Gradient(TopBar, Color3.fromRGB(160, 100, 255), Color3.fromRGB(70, 30, 190), 0)

-- Partículas de fondo
for i = 1, 10 do
    local sz = math.random(2, 4)
    local dot = Frame(WIN,
        UDim2.new(0,sz,0,sz),
        UDim2.new(math.random(3,97)/100, 0, math.random(3,97)/100, 0),
        CFG.C.Accent, 0.7, 398, "Dot")
    Corner(dot, sz)
    task.spawn(function()
        task.wait(math.random() * 4)
        while dot and dot.Parent do
            local d1 = math.random() * 2.5 + 0.8
            Tween(dot, {BackgroundTransparency=0.2}, d1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(d1)
            local d2 = math.random() * 2.5 + 0.8
            Tween(dot, {BackgroundTransparency=0.85}, d2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(d2)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
-- HEADER
-- ─────────────────────────────────────────────────────────────────
local Header = Frame(WIN, UDim2.new(1,0,0,52), UDim2.new(0,0,0,0),
    CFG.C.Surface, 0.15, 401, "Header")
Corner(Header, 20)
Gradient(Header, Color3.fromRGB(22,16,52), Color3.fromRGB(10,8,24), 110)

-- Logo círculo
local LogoCirc = Frame(Header, UDim2.new(0,34,0,34), UDim2.new(0,12,0.5,-17),
    CFG.C.Accent, 0, 402, "Logo")
Corner(LogoCirc, 17)
Gradient(LogoCirc, Color3.fromRGB(150,90,255), Color3.fromRGB(80,36,205), 135)
Label(LogoCirc, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), "K",
    CFG.C.White, 17, CFG.F.Bold, Enum.TextXAlignment.Center, 403)

-- Títulos
local HTitle = Label(Header, UDim2.new(0,220,0,20), UDim2.new(0,54,0,8),
    "Kaelen AI  ·  Phantom", CFG.C.White, 14, CFG.F.Bold, Enum.TextXAlignment.Left, 402)
local HSubt  = Label(Header, UDim2.new(0,260,0,14), UDim2.new(0,54,0,28),
    "v3.0  ·  " .. S.Mode, CFG.C.TextSub, 9, CFG.F.Regular, Enum.TextXAlignment.Left, 402)

-- Indicador de estado
local StatusDot = Frame(Header, UDim2.new(0,8,0,8), UDim2.new(1,-50,0.5,-4),
    CFG.C.Danger, 0, 402, "StatusDot")
Corner(StatusDot, 4)

-- Botón cerrar
local BtnClose = Button(Header, UDim2.new(0,30,0,30), UDim2.new(1,-40,0.5,-15),
    Color3.fromRGB(200,50,68), "✕", CFG.C.White, 13, CFG.F.Bold, 402)
Corner(BtnClose, 15)

-- ─────────────────────────────────────────────────────────────────
-- BARRA DE TABS
-- ─────────────────────────────────────────────────────────────────
local TabBar = Frame(WIN, UDim2.new(1,-20,0,34), UDim2.new(0,10,0,57),
    CFG.C.Card, 0.1, 401, "TabBar")
Corner(TabBar, 10)
Stroke(TabBar, CFG.C.Border, 1)
HList(TabBar, 4)
Pad(TabBar, 3, 3, 4, 4)

local TAB_NAMES   = {"Chat", "Modos", "Config"}
local TabRefs     = {}

local function HighlightTab(name)
    for _, td in ipairs(TabRefs) do
        local active = td.name == name
        Tween(td.btn, {BackgroundColor3 = active and CFG.C.Accent or CFG.C.Card,
            BackgroundTransparency = active and 0 or 0.55}, 0.2)
        Tween(td.lbl, {TextColor3 = active and CFG.C.White or CFG.C.TextSub}, 0.2)
    end
end

-- ─────────────────────────────────────────────────────────────────
-- CONTENEDOR DE PANELES
-- ─────────────────────────────────────────────────────────────────
local PanelHost = Frame(WIN, UDim2.new(1,-20,1,-100), UDim2.new(0,10,0,96),
    CFG.C.Black, 1, 400, "PanelHost")

-- ══════════════════════════════════════════════════════════════════
-- PANEL: KEY SYSTEM
-- ══════════════════════════════════════════════════════════════════
local PanelKey = Frame(PanelHost, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    CFG.C.Black, 1, 401, "PanelKey")
VList(PanelKey, 10, Enum.HorizontalAlignment.Center)
Pad(PanelKey, 16, 10, 4, 4)

-- Ícono candado
local LockWrap = Frame(PanelKey, UDim2.new(0,56,0,56), UDim2.new(0,0,0,0),
    CFG.C.AccentSoft, 0, 402, "LockWrap")
LockWrap.LayoutOrder = 1
Corner(LockWrap, 28)
Stroke(LockWrap, CFG.C.Accent, 1.5)
Label(LockWrap, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), "🔑",
    CFG.C.White, 24, CFG.F.Regular, Enum.TextXAlignment.Center, 403)

-- Textos
local KeyTitle = Label(PanelKey, UDim2.new(1,0,0,22), UDim2.new(0,0,0,0),
    "Activar Kaelen Premium", CFG.C.White, 16, CFG.F.Bold,
    Enum.TextXAlignment.Center, 402)
KeyTitle.LayoutOrder = 2

local KeySub = Label(PanelKey, UDim2.new(1,0,0,28), UDim2.new(0,0,0,0),
    "Introduce tu API Key de OpenRouter para continuar.", CFG.C.TextSub, 10,
    CFG.F.Regular, Enum.TextXAlignment.Center, 402)
KeySub.LayoutOrder = 3

-- Input
local KeyInput = TextBox(PanelKey, UDim2.new(1,-8,0,38), UDim2.new(0,0,0,0),
    "sk-or-v1-...", 402)
KeyInput.LayoutOrder    = 4
KeyInput.Font           = CFG.F.Mono
KeyInput.TextSize       = 10
Corner(KeyInput, 10)
Stroke(KeyInput, CFG.C.Border, 1)
Pad(KeyInput, 0, 0, 12, 12)

-- Botón verificar
local BtnVerify = Button(PanelKey, UDim2.new(1,-8,0,38), UDim2.new(0,0,0,0),
    CFG.C.Accent, "Conectar y Activar", CFG.C.White, 12, CFG.F.Bold, 402)
BtnVerify.LayoutOrder = 5
Corner(BtnVerify, 10)
Gradient(BtnVerify, Color3.fromRGB(138,85,255), Color3.fromRGB(82,38,200), 135)

-- Botón bypass (oculto por defecto)
local BtnBypass = Button(PanelKey, UDim2.new(1,-8,0,26), UDim2.new(0,0,0,0),
    CFG.C.Warning, "⚠ Guardar sin verificar (bypass de red)", CFG.C.Black, 9, CFG.F.Bold, 402)
BtnBypass.LayoutOrder = 6
BtnBypass.Visible     = false
Corner(BtnBypass, 6)

-- Log de estado
local KeyLog = Label(PanelKey, UDim2.new(1,0,0,44), UDim2.new(0,0,0,0),
    "", CFG.C.TextSub, 10, CFG.F.Regular, Enum.TextXAlignment.Center, 402)
KeyLog.LayoutOrder = 7

-- ══════════════════════════════════════════════════════════════════
-- PANEL: CHAT
-- ══════════════════════════════════════════════════════════════════
local PanelChat = Frame(PanelHost, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    CFG.C.Black, 1, 401, "PanelChat")
PanelChat.Visible = false

-- Área de mensajes con scroll
local MsgScroll = Scroll(PanelChat, UDim2.new(1,0,1,-72), UDim2.new(0,0,0,0), 402)
VList(MsgScroll, 8)
Pad(MsgScroll, 6, 6, 4, 4)

-- Indicador de "pensando"
local ThinkFr = Frame(MsgScroll, UDim2.new(0,160,0,30), UDim2.new(0,0,0,0),
    CFG.C.AIBubble, 0.05, 403, "ThinkFr")
ThinkFr.LayoutOrder = 99999
ThinkFr.Visible     = false
Corner(ThinkFr, 15)
Stroke(ThinkFr, CFG.C.Border, 1)
Pad(ThinkFr, 0, 0, 12, 12)
local ThinkLbl = Label(ThinkFr, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "Procesando...", CFG.C.TextSub, 10, CFG.F.Regular, Enum.TextXAlignment.Left, 404)

-- Barra de entrada
local InputBar = Frame(PanelChat, UDim2.new(1,0,0,68), UDim2.new(0,0,1,-68),
    CFG.C.Surface, 0.12, 402, "InputBar")
Corner(InputBar, 14)
Stroke(InputBar, CFG.C.Border, 1)

local ChatInput = TextBox(InputBar, UDim2.new(1,-48,0,36), UDim2.new(0,6,0,6),
    "Escribe un mensaje o comando...", 403)
ChatInput.MultiLine = false
Corner(ChatInput, 8)
Pad(ChatInput, 0, 0, 10, 10)

local BtnSend = Button(InputBar, UDim2.new(0,36,0,36), UDim2.new(1,-42,0,6),
    CFG.C.Accent, "➤", CFG.C.White, 14, CFG.F.Bold, 403)
Corner(BtnSend, 8)
Gradient(BtnSend, Color3.fromRGB(140,88,255), Color3.fromRGB(80,36,200), 135)

-- Quick action bar
local QBar = Frame(InputBar, UDim2.new(1,-8,0,22), UDim2.new(0,4,0,44),
    CFG.C.Black, 1, 403, "QBar")
HList(QBar, 5)

local QUICK_CMDS = {
    { icon = "🎮", label = "Analizar", id = "analyze" },
    { icon = "🚀", label = "Volar",    id = "fly"     },
    { icon = "👻", label = "Noclip",   id = "noclip"  },
    { icon = "⚡", label = "Speed×2",  id = "speed2"  },
    { icon = "🗑", label = "Limpiar",  id = "clear"   },
}
local QBtnRefs = {}
for _, qd in ipairs(QUICK_CMDS) do
    local qb = Button(QBar, UDim2.new(0,0,1,0), UDim2.new(0,0,0,0),
        CFG.C.Card, qd.icon .. " " .. qd.label, CFG.C.TextSub, 9, CFG.F.Regular, 404)
    qb.AutomaticSize          = Enum.AutomaticSize.X
    qb.BackgroundTransparency = 0.3
    Corner(qb, 5)
    Pad(qb, 1, 1, 5, 5)
    table.insert(QBtnRefs, { btn = qb, id = qd.id })
end

-- ══════════════════════════════════════════════════════════════════
-- PANEL: MODOS
-- ══════════════════════════════════════════════════════════════════
local PanelModes = Scroll(PanelHost, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), 401)
PanelModes.Name    = "PanelModes"
PanelModes.Visible = false
VList(PanelModes, 6, Enum.HorizontalAlignment.Center)
Pad(PanelModes, 8, 8, 0, 0)

local ModesTitle = Label(PanelModes, UDim2.new(1,0,0,20), UDim2.new(0,0,0,0),
    "Personalidad del Orquestador", CFG.C.White, 13, CFG.F.Bold,
    Enum.TextXAlignment.Center, 402)
ModesTitle.LayoutOrder = 0

local MODES_DATA = {
    { name = "Programador", icon = "💻", col = Color3.fromRGB(60, 190, 255),  desc = "Scripts Lua, optimización y debug." },
    { name = "Analista",    icon = "🔍", col = Color3.fromRGB(100, 72, 255),   desc = "Arquitectura, seguridad y exploits." },
    { name = "Creativo",    icon = "🎨", col = Color3.fromRGB(255, 130, 70),   desc = "Diseño de mecánicas y experiencias." },
    { name = "Asistente",   icon = "🤖", col = Color3.fromRGB(50, 210, 140),   desc = "Ayuda general e información." },
}

local ModeCardRefs = {}
for idx, md in ipairs(MODES_DATA) do
    local active = md.name == S.Mode
    local card   = Button(PanelModes, UDim2.new(1,0,0,54), UDim2.new(0,0,0,0),
        CFG.C.Card, "", CFG.C.White, 13, CFG.F.Bold, 402)
    card.BackgroundTransparency = active and 0.05 or 0.3
    card.LayoutOrder = idx
    Corner(card, 12)
    local cstroke = Stroke(card, active and CFG.C.Accent or CFG.C.Border, active and 1.5 or 1)

    -- Ícono
    local ic = Frame(card, UDim2.new(0,38,0,38), UDim2.new(0,10,0.5,-19),
        md.col, 0.12, 403, "IC")
    Corner(ic, 19)
    Label(ic, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), md.icon,
        CFG.C.White, 18, CFG.F.Regular, Enum.TextXAlignment.Center, 404)

    Label(card, UDim2.new(1,-66,0,16), UDim2.new(0,56,0,10),
        md.name, CFG.C.White, 12, CFG.F.Bold, Enum.TextXAlignment.Left, 403)
    Label(card, UDim2.new(1,-66,0,14), UDim2.new(0,56,0,28),
        md.desc, CFG.C.TextSub, 9, CFG.F.Regular, Enum.TextXAlignment.Left, 403)

    local badge = Frame(card, UDim2.new(0,8,0,8), UDim2.new(1,-18,0.5,-4),
        md.col, active and 0 or 1, 403, "Badge")
    Corner(badge, 4)

    table.insert(ModeCardRefs, { card=card, stroke=cstroke, badge=badge, name=md.name, col=md.col })

    card.MouseButton1Click:Connect(function()
        S.Mode = md.name
        HSubt.Text = "v3.0  ·  " .. S.Mode
        for _, r in ipairs(ModeCardRefs) do
            local on = r.name == md.name
            Tween(r.card,  {BackgroundTransparency = on and 0.05 or 0.3}, 0.2)
            Tween(r.badge, {BackgroundTransparency = on and 0    or 1},   0.2)
            r.stroke.Color     = on and CFG.C.Accent or CFG.C.Border
            r.stroke.Thickness = on and 1.5          or 1
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- PANEL: CONFIG
-- ══════════════════════════════════════════════════════════════════
local PanelCfg = Scroll(PanelHost, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), 401)
PanelCfg.Name    = "PanelCfg"
PanelCfg.Visible = false
VList(PanelCfg, 8, Enum.HorizontalAlignment.Center)
Pad(PanelCfg, 8, 8, 0, 0)

local CfgTitle = Label(PanelCfg, UDim2.new(1,0,0,20), UDim2.new(0,0,0,0),
    "Configuración del Sistema", CFG.C.White, 13, CFG.F.Bold,
    Enum.TextXAlignment.Center, 402)
CfgTitle.LayoutOrder = 0

-- Tarjeta de info de motores
local EngCard = Frame(PanelCfg, UDim2.new(1,0,0,80), UDim2.new(0,0,0,0),
    CFG.C.Card, 0.1, 402, "EngCard")
EngCard.LayoutOrder = 1
Corner(EngCard, 12)
Stroke(EngCard, CFG.C.Border, 1)
Pad(EngCard, 8, 8, 12, 12)
Label(EngCard, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "⚡ Motor Rápido  →  Gemma-3 27B (acciones)\n" ..
    "🔵 Motor Código  →  Qwen3-Coder (scripts)\n" ..
    "🟣 Motor Razón   →  Llama 3.3 70B (análisis)\n" ..
    "🔀 Modo Dual     →  Qwen3 + Llama (revisión)",
    CFG.C.TextSub, 9, CFG.F.Mono, Enum.TextXAlignment.Left, 403)

-- Prompt personalizado
local CfgSysLabel = Label(PanelCfg, UDim2.new(1,0,0,14), UDim2.new(0,0,0,0),
    "Prompt del sistema personalizado:", CFG.C.TextSub, 9, CFG.F.Bold,
    Enum.TextXAlignment.Left, 402)
CfgSysLabel.LayoutOrder = 2

local CustomSysBox = Instance.new("TextBox")
CustomSysBox.Name                   = "CustomSys"
CustomSysBox.Size                   = UDim2.new(1,0,0,60)
CustomSysBox.BackgroundColor3       = CFG.C.Card
CustomSysBox.BackgroundTransparency = 0.1
CustomSysBox.Text                   = ""
CustomSysBox.PlaceholderText        = "Deja vacío para usar el prompt del modo activo..."
CustomSysBox.TextColor3             = CFG.C.Text
CustomSysBox.PlaceholderColor3      = CFG.C.TextDim
CustomSysBox.TextSize               = 10
CustomSysBox.Font                   = CFG.F.Regular
CustomSysBox.MultiLine              = true
CustomSysBox.ClearTextOnFocus       = false
CustomSysBox.ZIndex                 = 402
CustomSysBox.LayoutOrder            = 3
CustomSysBox.BorderSizePixel        = 0
CustomSysBox.TextXAlignment         = Enum.TextXAlignment.Left
CustomSysBox.TextYAlignment         = Enum.TextYAlignment.Top
CustomSysBox.Parent                 = PanelCfg
Corner(CustomSysBox, 10)
Stroke(CustomSysBox, CFG.C.Border, 1)
Pad(CustomSysBox, 6, 6, 10, 10)

CustomSysBox:GetPropertyChangedSignal("Text"):Connect(function()
    S.CustomSys = CustomSysBox.Text
end)

-- Estado físico
local PhysCard = Frame(PanelCfg, UDim2.new(1,0,0,50), UDim2.new(0,0,0,0),
    CFG.C.Card, 0.1, 402, "PhysCard")
PhysCard.LayoutOrder = 4
Corner(PhysCard, 12)
Stroke(PhysCard, CFG.C.Border, 1)
Pad(PhysCard, 8, 8, 12, 12)
local PhysLbl = Label(PhysCard, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "✈ Vuelo: OFF     👻 Noclip: OFF", CFG.C.TextSub, 10, CFG.F.Mono,
    Enum.TextXAlignment.Left, 403)

local function RefreshPhysLabel()
    PhysLbl.Text = (S.Fly.Active and "✈ Vuelo: 🟢 ON" or "✈ Vuelo: ⭕ OFF") ..
                   "     " ..
                   (S.Noclip.Active and "👻 Noclip: 🟢 ON" or "👻 Noclip: ⭕ OFF")
end
RefreshPhysLabel()

-- Botones de config
local BtnClear = Button(PanelCfg, UDim2.new(1,0,0,34), UDim2.new(0,0,0,0),
    CFG.C.Card, "🗑  Borrar historial de chat", CFG.C.TextSub, 11, CFG.F.Bold, 402)
BtnClear.BackgroundTransparency = 0.2
BtnClear.LayoutOrder = 5
Corner(BtnClear, 10)
Stroke(BtnClear, CFG.C.Border, 1)

local BtnReset = Button(PanelCfg, UDim2.new(1,0,0,34), UDim2.new(0,0,0,0),
    CFG.C.Danger, "⚠  Resetear API Key", CFG.C.White, 11, CFG.F.Bold, 402)
BtnReset.BackgroundTransparency = 0.25
BtnReset.LayoutOrder = 6
Corner(BtnReset, 10)

-- ─────────────────────────────────────────────────────────────────
-- CONSTRUCCIÓN FINAL DE TABS (requiere referencias de paneles)
-- ─────────────────────────────────────────────────────────────────
local PANELS = {
    Key    = PanelKey,
    Chat   = PanelChat,
    Modos  = PanelModes,
    Config = PanelCfg,
}
local ALL_PANELS = { PanelKey, PanelChat, PanelModes, PanelCfg }

local function ShowPanel(name)
    for _, p in ipairs(ALL_PANELS) do p.Visible = false end
    local t = PANELS[name]
    if t then t.Visible = true end
    S.ActivePanel = name
end

-- Crear tabs ahora que ShowPanel existe
local SwitchTab  -- forward declaration, se usa en click
SwitchTab = function(name)
    if not S.Verified and name ~= "Key" then return end
    HighlightTab(name)
    ShowPanel(name)
end

for _, tname in ipairs(TAB_NAMES) do
    local tb = Button(TabBar, UDim2.new(0,96,1,0), UDim2.new(0,0,0,0),
        CFG.C.Card, "", CFG.C.White, 11, CFG.F.Bold, 402)
    tb.BackgroundTransparency = 0.55
    Corner(tb, 8)
    local tl = Label(tb, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), tname,
        CFG.C.TextSub, 11, CFG.F.Bold, Enum.TextXAlignment.Center, 403)
    table.insert(TabRefs, { name=tname, btn=tb, lbl=tl })
    tb.MouseButton1Click:Connect(function() SwitchTab(tname) end)
end

-- ══════════════════════════════════════════════════════════════════
-- [12] LÓGICA DE CHAT
-- ══════════════════════════════════════════════════════════════════

local function ScrollBottom()
    task.delay(0.05, function()
        if MsgScroll and MsgScroll.Parent then
            MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y + 9999)
        end
    end)
end

local function PushMessage(role, text)
    table.insert(S.Messages, { role = role, content = text })
    if #S.Messages > CFG.MaxHistory then table.remove(S.Messages, 1) end
    S.MsgCount += 1

    local isUser = role == "user"
    local row    = Frame(MsgScroll, UDim2.new(1,0,0,0), UDim2.new(0,0,0,0),
        CFG.C.Black, 1, 403, "Row_" .. S.MsgCount)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.LayoutOrder   = S.MsgCount

    local bubble = Frame(row, UDim2.new(0.86,0,0,0),
        UDim2.new(isUser and 0.14 or 0, 0, 0, 0),
        isUser and CFG.C.UserBubble or CFG.C.AIBubble, 0.06, 404, "Bubble")
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    Corner(bubble, 14)
    Pad(bubble, 8, 8, 12, 12)
    if not isUser then Stroke(bubble, CFG.C.Border, 1) end
    VList(bubble, 4, isUser and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left)

    -- Autor
    local authorTxt = isUser and ("🧑 " .. LocalPlayer.Name) or "⬡ Kaelen"
    local authorCol = isUser and Color3.fromRGB(180, 150, 255) or CFG.C.AccentGlow
    local xa        = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    local aLbl = Label(bubble, UDim2.new(1,0,0,12), UDim2.new(0,0,0,0),
        authorTxt, authorCol, 9, CFG.F.Bold, xa, 405)
    aLbl.LayoutOrder = 1

    -- Texto
    local tLbl = Label(bubble, UDim2.new(1,0,0,0), UDim2.new(0,0,0,0),
        text, CFG.C.Text, 11, CFG.F.Regular, xa, 405)
    tLbl.AutomaticSize = Enum.AutomaticSize.Y
    tLbl.LayoutOrder   = 2

    -- Animación entrada
    bubble.BackgroundTransparency = 1
    tLbl.TextTransparency         = 1
    aLbl.TextTransparency         = 1
    Tween(bubble, {BackgroundTransparency = 0.06}, 0.28)
    Tween(tLbl,   {TextTransparency = 0}, 0.28)
    Tween(aLbl,   {TextTransparency = 0}, 0.28)

    ScrollBottom()
end

local function SetThinking(on)
    S.Thinking              = on
    ThinkFr.Visible         = on
    ThinkFr.LayoutOrder     = S.MsgCount + 1

    if on then
        if S.ThinkThread then task.cancel(S.ThinkThread) end
        S.ThinkThread = task.spawn(function()
            local frames = {"⬤○○", "⬤⬤○", "⬤⬤⬤", "○⬤⬤", "○○⬤", "○○○"}
            local i = 1
            while S.Thinking do
                if ThinkLbl and ThinkLbl.Parent then
                    ThinkLbl.Text = "Orquestador  " .. frames[i]
                end
                i = (i % #frames) + 1
                task.wait(0.25)
            end
        end)
        ScrollBottom()
    else
        if S.ThinkThread then task.cancel(S.ThinkThread); S.ThinkThread = nil end
    end
end

local function Send(rawText)
    local text = rawText and rawText:match("^%s*(.-)%s*$") or ""
    if text == "" or S.Thinking then return end
    ChatInput.Text = ""

    PushMessage("user", text)
    SetThinking(true)

    task.spawn(function()
        local reply, err = Orchestrate(text, S.Messages)
        SetThinking(false)

        if err then
            PushMessage("assistant", "⚠️ **Error del sistema:**\n" .. err)
        else
            ParseAICommands(reply)
            RefreshPhysLabel()
            PushMessage("assistant", reply or "Sin respuesta.")
        end
    end)
end

local function ClearChat()
    for _, c in ipairs(MsgScroll:GetChildren()) do
        if c:IsA("Frame") and c.Name ~= "ThinkFr" then c:Destroy() end
    end
    S.Messages  = {}
    S.MsgCount  = 0
end

-- ══════════════════════════════════════════════════════════════════
-- [13] EVENTOS DE BOTONES
-- ══════════════════════════════════════════════════════════════════

-- Enviar mensaje
BtnSend.MouseButton1Click:Connect(function() Send(ChatInput.Text) end)
ChatInput.FocusLost:Connect(function(enter)
    if enter then Send(ChatInput.Text) end
end)

-- Quick commands
for _, qr in ipairs(QBtnRefs) do
    qr.btn.MouseButton1Click:Connect(function()
        local id = qr.id
        if     id == "analyze" then Send("🎮 Analiza en profundidad este juego:\n" .. GameContext())
        elseif id == "fly"     then Send("Por favor activa mi vuelo para desplazarme libremente.")
        elseif id == "noclip"  then Send("Activa el noclip para que pueda atravesar paredes.")
        elseif id == "speed2"  then Send("Pon mi velocidad al doble de lo normal (WalkSpeed 32).")
        elseif id == "clear"   then
            ClearChat()
            PushMessage("assistant", "🗑 Historial y memoria limpiados correctamente.")
        end
    end)
end

-- Verificar key
BtnVerify.MouseButton1Click:Connect(function()
    local raw = KeyInput.Text
    local key = raw:match("^%s*(.-)%s*$") or ""

    if #key < 10 then
        KeyLog.TextColor3 = CFG.C.Warning
        KeyLog.Text       = "⚠ La clave parece demasiado corta."
        return
    end

    BtnVerify.Text                  = "⏳ Verificando..."
    BtnVerify.BackgroundTransparency= 0.3
    KeyLog.TextColor3               = CFG.C.TextSub
    KeyLog.Text                     = "Conectando con OpenRouter..."
    BtnBypass.Visible               = false

    task.spawn(function()
        local ok, err = VerifyKey(key)

        if ok then
            S.APIKey  = key
            S.Verified = true
            StatusDot.BackgroundColor3 = CFG.C.Success
            Tween(StatusDot, {BackgroundColor3 = CFG.C.Success}, 0.4)

            KeyLog.TextColor3 = CFG.C.Success
            KeyLog.Text       = "✅ Conexión establecida. ¡Kaelen activo!"
            BtnVerify.Text    = "✔ Activado"

            task.wait(1.0)
            SwitchTab("Chat")
            PushMessage("assistant",
                "⬡ **¡Sistema inicializado!**\n\n" ..
                "Motor triple-engine operativo. Puedes escribir libremente o usar los botones rápidos.\n\n" ..
                "Prueba:\n• «Activa el noclip»\n• «Pon mi velocidad en 90»\n• «Crea un script de admin»"
            )
        else
            KeyLog.TextColor3 = CFG.C.Danger
            KeyLog.Text       = "❌ " .. tostring(err)
            BtnVerify.Text    = "Reintentar"
            BtnVerify.BackgroundTransparency = 0
            if key:match("^sk%-or%-") then BtnBypass.Visible = true end
        end
    end)
end)

-- Bypass
BtnBypass.MouseButton1Click:Connect(function()
    local key = (KeyInput.Text:match("^%s*(.-)%s*$") or "")
    if #key > 0 then
        S.APIKey  = key
        S.Verified = true
        StatusDot.BackgroundColor3 = CFG.C.Warning
        KeyLog.TextColor3          = CFG.C.Warning
        KeyLog.Text                = "⚠ Key guardada sin verificación."
        task.wait(0.8)
        SwitchTab("Chat")
    end
end)

-- Borrar historial
BtnClear.MouseButton1Click:Connect(function()
    ClearChat()
end)

-- Reset key
BtnReset.MouseButton1Click:Connect(function()
    S.APIKey   = ""
    S.Verified = false
    StatusDot.BackgroundColor3 = CFG.C.Danger
    KeyInput.Text = ""
    KeyLog.Text   = ""
    BtnVerify.Text = "Conectar y Activar"
    BtnVerify.BackgroundTransparency = 0
    ClearChat()
    ShowPanel("Key")
    HighlightTab("Chat")
end)

-- Cerrar ventana
BtnClose.MouseButton1Click:Connect(function()
    -- Definido más abajo, usar variable forward
end)

-- ══════════════════════════════════════════════════════════════════
-- [14] ABRIR / CERRAR VENTANA  ──  Animaciones fluidas
-- ══════════════════════════════════════════════════════════════════

local function OpenWindow()
    if S.WinOpen then return end
    S.WinOpen = true

    -- Animar desde la posición del FAB
    local ox = FAB.Position.X.Scale
    local oy = FAB.Position.X.Offset + 26
    local yy = FAB.Position.Y.Scale
    local yo = FAB.Position.Y.Offset + 26

    WIN.Size     = UDim2.new(0,0,0,0)
    WIN.Position = UDim2.new(ox, oy, yy, yo)
    WIN.Visible  = true

    Tween(WIN,
        { Size     = UDim2.new(0, CFG.W.W, 0, CFG.W.H),
          Position = UDim2.new(0.5, -CFG.W.W/2, 0.5, -CFG.W.H/2) },
        0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Animar halo del FAB al abrir
    Tween(FAB, {BackgroundTransparency = 0.3}, 0.2)
end

local function CloseWindow()
    if not S.WinOpen then return end
    S.WinOpen = false

    local tx = FAB.Position.X.Scale
    local to = FAB.Position.X.Offset + 26
    local ty = FAB.Position.Y.Scale
    local tyo= FAB.Position.Y.Offset + 26

    Tween(WIN,
        { Size     = UDim2.new(0,0,0,0),
          Position = UDim2.new(tx, to, ty, tyo) },
        0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

    Tween(FAB, {BackgroundTransparency = 0}, 0.2)

    task.delay(0.26, function()
        if WIN and WIN.Parent then WIN.Visible = false end
    end)
end

BtnClose.MouseButton1Click:Connect(CloseWindow)

-- Tecla K (PC)
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.K then
        if S.WinOpen then CloseWindow() else OpenWindow() end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [15] DRAG  ──  Botón flotante  &  Ventana principal
--               FIX COMPLETO PARA TOUCH EN DELTA / MÓVIL
-- ══════════════════════════════════════════════════════════════════

-- ── FAB touch / drag ──────────────────────────────────────────────
FAB.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        S.BtnDrag.Active     = true
        S.BtnDrag.Origin     = Vector2.new(inp.Position.X, inp.Position.Y)
        S.BtnDrag.PosOrigin  = FAB.Position
        S.BtnDrag.TotalMoved = 0
    end
end)

FAB.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        -- Tap (sin movimiento) → abrir/cerrar
        if S.BtnDrag.TotalMoved < 8 then
            if S.WinOpen then CloseWindow() else OpenWindow() end
        end
        -- Siempre terminar el drag al soltar
        S.BtnDrag.Active     = false
        S.BtnDrag.TotalMoved = 0
    end
end)

-- ── Header drag (ventana) ──────────────────────────────────────────
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        S.WinDrag.Active    = true
        S.WinDrag.Origin    = Vector2.new(inp.Position.X, inp.Position.Y)
        S.WinDrag.PosOrigin = WIN.Position
    end
end)

-- ── Movimiento unificado ───────────────────────────────────────────
UserInputService.InputChanged:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end

    local pos = Vector2.new(inp.Position.X, inp.Position.Y)

    -- Mover FAB
    if S.BtnDrag.Active then
        local delta = pos - S.BtnDrag.Origin
        S.BtnDrag.TotalMoved = delta.Magnitude
        if S.BtnDrag.TotalMoved > 8 then
            FAB.Position = UDim2.new(
                S.BtnDrag.PosOrigin.X.Scale,
                S.BtnDrag.PosOrigin.X.Offset + delta.X,
                S.BtnDrag.PosOrigin.Y.Scale,
                S.BtnDrag.PosOrigin.Y.Offset + delta.Y
            )
        end
    end

    -- Mover ventana
    if S.WinDrag.Active then
        local delta = pos - S.WinDrag.Origin
        WIN.Position = UDim2.new(
            S.WinDrag.PosOrigin.X.Scale,
            S.WinDrag.PosOrigin.X.Offset + delta.X,
            S.WinDrag.PosOrigin.Y.Scale,
            S.WinDrag.PosOrigin.Y.Offset + delta.Y
        )
    end
end)

-- ── Soltar todo al levantar el dedo/mouse ─────────────────────────
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        S.WinDrag.Active = false
        -- BtnDrag se gestiona en FAB.InputEnded
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- [16] INICIO
-- ══════════════════════════════════════════════════════════════════
ShowPanel("Key")
HighlightTab("Chat")

print("╔═══════════════════════════════════════╗")
print("║  KAELEN v3.0 PHANTOM  ·  READY        ║")
print("║  Toca el botón K para abrir la UI     ║")
print("╚═══════════════════════════════════════╝")
