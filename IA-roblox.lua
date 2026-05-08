-- ============================================================
--  Kaelen v2.3
--  Asistente IA Premium para Roblox Studio / Testing
--  Orquestador: Qwen3-Coder + Llama 3.3 70B via OpenRouter
--  By: Kaelen Systems | 2025
-- ============================================================

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")
local Workspace      = game:GetService("Workspace")

local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()
local Camera         = Workspace.CurrentCamera

-- ============================================================
--  CONFIGURACIÓN GLOBAL
-- ============================================================
local CONFIG = {
    Version      = "2.3",
    AppName      = "Kaelen",
    Author       = "Kaelen Systems",
    OpenRouterBase = "https://openrouter.ai/api/v1/chat/completions",
    Models = {
        Coder    = "qwen/qwen3-coder:free",
        Reason   = "meta-llama/llama-3.3-70b-instruct:free",
        Fast     = "google/gemma-3-27b-it:free",
    },
    MaxTokens    = 1800,
    Temperature  = 0.72,
    MaxHistory   = 50,
    StatsRefresh = 0.1,   -- segundos entre actualización del panel de stats
    Colors = {
        BG          = Color3.fromRGB(8,  8,  18),
        Surface     = Color3.fromRGB(16, 16, 28),
        Card        = Color3.fromRGB(22, 22, 38),
        CardHover   = Color3.fromRGB(30, 28, 52),
        Border      = Color3.fromRGB(55, 55, 95),
        BorderGlow  = Color3.fromRGB(110, 75, 240),
        Accent      = Color3.fromRGB(120, 80, 255),
        AccentSoft  = Color3.fromRGB(80,  50, 180),
        AccentGlow  = Color3.fromRGB(150, 110, 255),
        UserBubble  = Color3.fromRGB(95,  58, 230),
        AIBubble    = Color3.fromRGB(26,  26, 46),
        Text        = Color3.fromRGB(228, 228, 255),
        TextMuted   = Color3.fromRGB(120, 120, 170),
        TextDim     = Color3.fromRGB(80,  80,  120),
        Green       = Color3.fromRGB(80,  220, 140),
        GreenDark   = Color3.fromRGB(30,  90,  60),
        Red         = Color3.fromRGB(255, 75,  95),
        RedDark     = Color3.fromRGB(90,  30,  40),
        Yellow      = Color3.fromRGB(255, 210, 80),
        Cyan        = Color3.fromRGB(80,  210, 255),
        White       = Color3.fromRGB(255, 255, 255),
        HeaderBG    = Color3.fromRGB(14,  12,  30),
    },
    Font     = Enum.Font.GothamBold,
    FontReg  = Enum.Font.Gotham,
    FontMono = Enum.Font.Code,
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
    CurrentTab      = "Chat",
    IsDragging      = false,
    DragOffset      = Vector2.new(0, 0),

    -- Features de movimiento/juego
    FlyEnabled      = false,
    FlySpeed        = 60,
    FlyConnection   = nil,
    FlyBodyVelocity = nil,
    FlyBodyGyro     = nil,

    InfJumpEnabled  = false,
    InfJumpConn     = nil,

    ClickTPEnabled  = false,
    ClickTPConn     = nil,

    HeadsitEnabled  = false,

    Checkpoints     = {},   -- tabla: {name, position, cframe}
    MaxCheckpoints  = 10,

    StatsConnection = nil,
    StatsVisible    = false,

    -- Comandos IA → juego
    LastAICommand   = nil,
}

-- ============================================================
--  SYSTEM PROMPTS
-- ============================================================
local SYSTEM_PROMPTS = {
    Programador = [[Eres Kaelen, desarrollador élite en Lua y Roblox scripting con 15 años de experiencia.
MISIÓN: Generar, optimizar y debugear scripts Lua para Roblox con calidad máxima.
- Código limpio, comentado, modular y eficiente.
- Detecta memory leaks, race conditions y vulnerabilidades.
- Explica soluciones con claridad técnica profesional.
- Usa bloques de código Lua correctamente formateados.
- Incluye manejo de errores con pcall/xpcall cuando corresponda.
- Sugiere mejoras proactivamente aunque no se pidan.
FORMATO: Responde en español. Usa emojis para claridad. Código en bloques.
CONTEXTO: El usuario es el desarrollador del juego, no un exploiter.]],

    Analista = [[Eres Kaelen, analista élite de sistemas de juegos Roblox.
MISIÓN: Analizar mecánicas, detectar vulnerabilidades, evaluar rendimiento y dar insights profundos.
- Analiza el contexto del juego cuando se proporcione datos.
- Detecta posibles exploits desde la perspectiva del desarrollador para parchearlos.
- Recomendaciones concretas, accionables y priorizadas.
- Combina análisis técnico con visión de game design.
- Evalúa arquitectura de código, estructura de datos y flujos de red.
FORMATO: Responde en español. Estructurado, directo y exhaustivo.]],

    Creativo = [[Eres Kaelen en modo Creativo, genio del diseño de juegos Roblox.
MISIÓN: Ideas innovadoras, mecánicas únicas y conceptos sorprendentes.
- Piensa fuera de la caja, combina géneros y estilos inesperados.
- Descripciones vívidas y detalladas con ejemplos de implementación.
- Inspiración en los mejores juegos del mundo adaptada a Roblox.
- Incluye snippets de código cuando sean relevantes para ilustrar ideas.
FORMATO: Responde en español. Entusiasta, descriptivo y técnicamente viable.]],

    Troll = [[Eres Kaelen en modo Testing Social, especialista en mecánicas de testing divertidas.
MISIÓN: Sugerir mecánicas de prueba creativas, cómicas y 100% legítimas dentro del juego.
- Solo mecánicas dentro de los sistemas del juego, sin nada externo.
- Situaciones cómicas para probar reacciones de NPCs o sistemas.
- Mantén todo en el espíritu de testing de desarrollo sano.
- Ideas detalladas y ejecutables con el executor interno del estudio.
FORMATO: Responde en español. Creativo, divertido pero profesional.]],

    Modificador = [[Eres Kaelen en modo Modificador de Personaje, asistente de control del jugador en tiempo real.
MISIÓN: Interpretar comandos del usuario para modificar su personaje o entorno dentro de Roblox Studio para testing.
CONTEXTO: El usuario es el desarrollador, necesita mover su personaje, cambiar velocidad, teletransportarse, etc. para navegar y testear su mundo rápidamente.

COMANDOS DISPONIBLES QUE PUEDES EJECUTAR:
- VELOCIDAD: "modifica mi velocidad a X" → responde: ACTION:SET_SPEED:X
- GRAVEDAD: "cambia gravedad a X" → responde: ACTION:SET_GRAVITY:X
- TAMAÑO: "hazme gigante/pequeño" o "escálame a X" → responde: ACTION:SET_SCALE:X
- TELEPORT: "llévame a X,Y,Z" → responde: ACTION:TELEPORT:X:Y:Z
- VOLAR: "activa vuelo" / "desactiva vuelo" → responde: ACTION:FLY:ON o ACTION:FLY:OFF
- VELOCIDAD_VUELO: "vuelo a X" → responde: ACTION:FLY_SPEED:X
- SALTO_INF: "activa salto infinito" → responde: ACTION:INF_JUMP:ON
- SALUD: "dame full salud" / "ponme salud X" → responde: ACTION:SET_HEALTH:X
- INVISIBILIDAD: "hazme invisible" / "hazme visible" → responde: ACTION:INVISIBLE:ON o ACTION:INVISIBLE:OFF
- LIMPIAR: "reset personaje" → responde: ACTION:RESET_CHAR
- CHECKPOINT: "guarda checkpoint como X" → responde: ACTION:SAVE_CHECKPOINT:X
- IR_CHECKPOINT: "ve al checkpoint X" → responde: ACTION:GOTO_CHECKPOINT:X

REGLAS:
- Si el usuario dice algo como "ponme velocidad 200" o "vuelo rapido" o "quiero ser enorme", interpreta y ejecuta la acción más apropiada.
- Responde SIEMPRE con la línea ACTION: al principio, seguida de una explicación amigable.
- Si el valor es ambiguo (ej: "muy rápido"), usa un valor razonable (velocidad 200, escala 3, etc).
- Si el comando no corresponde a ninguna acción, responde normalmente como analista.
FORMATO: ACTION primero, luego explicación breve en español.]],
}

-- ============================================================
--  UTILIDADES UI
-- ============================================================
local function Tween(obj, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(duration or 0.3, style, direction), props)
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

local function MakeShadow(parent)
    -- Shadow desactivada para evitar problemas de ZIndex y clicks bloqueados
    -- en algunos executors de Roblox Studio. No afecta la funcionalidad.
    return nil
end

local function MakeGradient(parent, c0, c1, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c0),
        ColorSequenceKeypoint.new(1, c1),
    })
    g.Rotation = rotation or 135
    g.Parent = parent
    return g
end

-- ============================================================
--  CONTEXTO DEL JUEGO
-- ============================================================
local function GetGameContext()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local pos  = hrp and hrp.Position or Vector3.new(0, 0, 0)

    local info = {
        GameName    = game.Name,
        PlaceId     = tostring(game.PlaceId),
        PlayerCount = tostring(#Players:GetPlayers()),
        PlayerName  = LocalPlayer.Name,
        Position    = string.format("(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z),
        WalkSpeed   = hum and tostring(hum.WalkSpeed) or "N/A",
        JumpPower   = hum and tostring(hum.JumpPower) or "N/A",
        Health      = hum and string.format("%.0f/%.0f", hum.Health, hum.MaxHealth) or "N/A",
    }

    local services = {}
    for _, s in ipairs({"ReplicatedStorage","ServerStorage","Workspace","StarterGui","StarterPack","ServerScriptService"}) do
        pcall(function()
            local svc = game:GetService(s)
            if svc then
                table.insert(services, s .. ":" .. #svc:GetChildren())
            end
        end)
    end
    info.ServiceCounts = table.concat(services, " | ")

    local scriptCount = 0
    pcall(function()
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
                scriptCount += 1
            end
        end
    end)
    info.TotalScripts = tostring(scriptCount)

    return HttpService:JSONEncode(info)
end

-- ============================================================
--  FPS TRACKER GLOBAL (no bloqueante)
-- ============================================================
local _kaelenFPS = 60
RunService.Heartbeat:Connect(function(dt)
    _kaelenFPS = math.floor(1 / math.max(dt, 0.001))
end)

-- ============================================================
--  STATS EN TIEMPO REAL (datos para el panel)
-- ============================================================
local function GetRealtimeStats()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if not char or not hrp or not hum then
        return {pos="N/A", speed="N/A", health="N/A", maxhp="N/A", ws="N/A", jp="N/A", fly=State.FlyEnabled, infjump=State.InfJumpEnabled}
    end

    local vel = hrp.Velocity
    local speed = math.floor(math.sqrt(vel.X^2 + vel.Z^2))
    local pos   = hrp.Position

    return {
        pos     = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z),
        speed   = tostring(speed),
        vspeed  = string.format("%.1f", vel.Y),
        health  = string.format("%.0f", hum.Health),
        maxhp   = string.format("%.0f", hum.MaxHealth),
        ws      = string.format("%.0f", hum.WalkSpeed),
        jp      = string.format("%.0f", hum.JumpPower),
        fly     = State.FlyEnabled,
        infjump = State.InfJumpEnabled,
        clicktp = State.ClickTPEnabled,
        fps     = tostring(_kaelenFPS),
    }
end

-- ============================================================
--  HTTP / OPENROUTER
-- ============================================================
local function GetHTTPFunc()
    local funcs = {
        function() return syn and syn.request end,
        function() return http and http.request end,
        function() return http_request end,
        function() return request end,
        function() return fluxus and fluxus.request end,
    }
    for _, f in ipairs(funcs) do
        local ok, fn = pcall(f)
        if ok and fn then return fn end
    end
    return nil
end

local function CallOpenRouter(model, messages, sysPrompt, maxTokens)
    if not State.KeyVerified or State.APIKey == "" then
        return nil, "API Key no verificada"
    end

    local body = {
        model       = model,
        max_tokens  = maxTokens or CONFIG.MaxTokens,
        temperature = CONFIG.Temperature,
        messages    = {},
    }

    if sysPrompt and sysPrompt ~= "" then
        table.insert(body.messages, {role = "system", content = sysPrompt})
    end
    for _, m in ipairs(messages) do
        table.insert(body.messages, {role = m.role, content = m.content})
    end

    local reqFunc = GetHTTPFunc()
    if not reqFunc then
        return nil, "No se encontró función HTTP compatible (syn.request / request)"
    end

    local ok, response = pcall(function()
        return reqFunc({
            Url    = CONFIG.OpenRouterBase,
            Method = "POST",
            Headers = {
                ["Content-Type"]  = "application/json",
                ["Authorization"] = "Bearer " .. State.APIKey,
                ["HTTP-Referer"]  = "https://roblox.com",
                ["X-Title"]       = "Kaelen AI v2.3",
            },
            Body = HttpService:JSONEncode(body),
        })
    end)

    if not ok then return nil, "Error al hacer la petición: " .. tostring(response) end
    if not response or response.StatusCode ~= 200 then
        local code = response and response.StatusCode or "sin respuesta"
        local msg  = ""
        pcall(function()
            local d = HttpService:JSONDecode(response.Body)
            msg = d and d.error and d.error.message or ""
        end)
        return nil, "Error HTTP " .. tostring(code) .. (msg ~= "" and ": " .. msg or "")
    end

    local ok2, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not ok2 then return nil, "Error al parsear respuesta JSON" end
    if data and data.choices and data.choices[1] then
        return data.choices[1].message.content, nil
    end
    return nil, "Respuesta inesperada del servidor"
end

local function VerifyAPIKey(key)
    local prev = {State.APIKey, State.KeyVerified}
    State.APIKey = key
    State.KeyVerified = true
    local res, err = CallOpenRouter(CONFIG.Models.Fast, {{role="user", content="Responde solo: OK"}}, "Responde solo 'OK'.", 20)
    if err then
        State.APIKey       = prev[1]
        State.KeyVerified  = prev[2]
        return false, err
    end
    return true, nil
end

-- ============================================================
--  ORQUESTADOR IA v2.3
-- ============================================================
local function ParseAIAction(response)
    -- Busca líneas ACTION:COMANDO:VALOR en la respuesta
    local line = response:match("ACTION:([^\n]+)")
    if not line then return nil end
    local parts = {}
    for p in line:gmatch("[^:]+") do
        table.insert(parts, p)
    end
    if #parts < 1 then return nil end
    return parts  -- {COMANDO, VALOR, ...}
end

local function OrchestrateKaelen(userMessage, history)
    -- Detectar si es comando de personaje/mundo
    local isCharCmd = userMessage:lower():match("velocidad") or
                      userMessage:lower():match("volar") or
                      userMessage:lower():match("vuelo") or
                      userMessage:lower():match("gravedad") or
                      userMessage:lower():match("teleport") or
                      userMessage:lower():match("llevar") or
                      userMessage:lower():match("escala") or
                      userMessage:lower():match("tama") or
                      userMessage:lower():match("salud") or
                      userMessage:lower():match("invisible") or
                      userMessage:lower():match("checkpoint") or
                      userMessage:lower():match("salto") or
                      userMessage:lower():match("hazme") or
                      userMessage:lower():match("modifica") or
                      userMessage:lower():match("ponme") or
                      userMessage:lower():match("cambia mi") or
                      userMessage:lower():match("rapidez") or
                      userMessage:lower():match("rapido") or
                      userMessage:lower():match("rapida")

    -- Detectar si es petición de código
    local isCode = userMessage:lower():match("script") or
                   userMessage:lower():match("%blua%b") or
                   userMessage:lower():match("c[oó]digo") or
                   userMessage:lower():match("funci[oó]n") or
                   userMessage:lower():match("crea ") or
                   userMessage:lower():match("genera ") or
                   userMessage:lower():match("optimiza") or
                   userMessage:lower():match("debug") or
                   userMessage:lower():match("arregla") or
                   userMessage:lower():match("modulo") or
                   userMessage:lower():match("m[oó]dulo")

    local sysPrompt = State.CustomSysPrompt ~= "" and State.CustomSysPrompt
                      or SYSTEM_PROMPTS[State.CurrentMode]

    -- Construir mensajes con contexto
    local apiMessages = {}
    local startIdx = math.max(1, #history - 16)
    for i = startIdx, #history do
        table.insert(apiMessages, {role = history[i].role, content = history[i].content})
    end
    table.insert(apiMessages, {role = "user", content = userMessage})

    local finalResponse = ""

    if isCharCmd then
        -- Modo Modificador: usa Fast model con el prompt especializado
        local charSys = SYSTEM_PROMPTS.Modificador
        local res, err = CallOpenRouter(CONFIG.Models.Fast, apiMessages, charSys, 400)
        if err then
            -- fallback a Reason
            res, err = CallOpenRouter(CONFIG.Models.Reason, apiMessages, SYSTEM_PROMPTS.Modificador, 400)
            if err then return nil, err end
        end
        finalResponse = res or "No pude interpretar el comando."

    elseif isCode or State.CurrentMode == "Programador" then
        -- Pipeline: Coder genera → Reason refina
        local coderSys = SYSTEM_PROMPTS.Programador ..
            "\n\nEres el módulo de código de Kaelen. Genera el script Lua con calidad máxima y sin cortes." ..
            "\n\nContexto del juego: " .. GetGameContext()
        local codeRes, codeErr = CallOpenRouter(CONFIG.Models.Coder, apiMessages, coderSys, 1800)

        if codeErr then
            -- Fallback directo a Reason
            local res, err = CallOpenRouter(CONFIG.Models.Reason, apiMessages, sysPrompt)
            if err then return nil, err end
            finalResponse = res
        else
            -- Reason revisa y presenta
            local refineMsg = {{
                role = "user",
                content = "El módulo Coder de Kaelen generó:\n\n" .. codeRes ..
                          "\n\nPetición original: " .. userMessage ..
                          "\n\nRevisa, detecta posibles errores, y presenta la respuesta final clara y completa como Kaelen v2.3."
            }}
            local refined, _ = CallOpenRouter(CONFIG.Models.Reason, refineMsg, sysPrompt, 900)
            finalResponse = refined or codeRes
        end
    else
        -- Análisis / Creativo / Troll → Reason principal con contexto
        local ctxSys = sysPrompt .. "\n\nContexto actual del juego: " .. GetGameContext()
        local res, err = CallOpenRouter(CONFIG.Models.Reason, apiMessages, ctxSys)
        if err then return nil, err end
        finalResponse = res
    end

    return finalResponse, nil
end

-- ============================================================
--  EJECUTOR DE ACCIONES IA
-- ============================================================
local function ExecuteAIAction(actionParts)
    if not actionParts or #actionParts < 1 then return "⚠️ Acción vacía." end

    local cmd    = actionParts[1]:upper():gsub("%s+", "")
    local val1   = actionParts[2] and tonumber(actionParts[2]) or 0
    local val2   = actionParts[3] and tonumber(actionParts[3]) or 0
    local val3   = actionParts[4] and tonumber(actionParts[4]) or 0
    local strVal = actionParts[2] or ""

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")

    if cmd == "SET_SPEED" then
        if hum then
            local speed = math.clamp(val1, 1, 9999)
            hum.WalkSpeed = speed
            return string.format("✅ Velocidad establecida a **%d**", speed)
        end
        return "❌ No se encontró el personaje."

    elseif cmd == "SET_GRAVITY" then
        local grav = math.clamp(val1, -500, 500)
        Workspace.Gravity = grav
        return string.format("✅ Gravedad cambiada a **%d**", grav)

    elseif cmd == "SET_SCALE" then
        if char then
            local scale = math.clamp(val1, 0.1, 10)
            pcall(function()
                for _, part in ipairs({"BodyHeightScale","BodyWidthScale","BodyDepthScale","HeadScale","BodyTypeScale"}) do
                    local desc = char:FindFirstChildOfClass("Humanoid") and
                                 char:FindFirstChildOfClass("Humanoid"):FindFirstChild("BodyColors") or nil
                    local hDesc = LocalPlayer:FindFirstChildOfClass("HumanoidDescription")
                    if hDesc then
                        hDesc.BodyTypeScale = math.clamp(val1 - 1, 0, 1)
                        hDesc.HeadScale = scale
                        hDesc.DepthScale = scale
                        hDesc.HeightScale = scale
                        hDesc.ProportionScale = math.clamp(val1 - 1, 0, 1)
                        hDesc.WidthScale = scale
                        hum:ApplyDescription(hDesc)
                    end
                end
            end)
            return string.format("✅ Escala del personaje → **%.1fx**", scale)
        end
        return "❌ No se encontró el personaje."

    elseif cmd == "TELEPORT" then
        if hrp then
            local target = Vector3.new(
                val1 ~= 0 and val1 or hrp.Position.X,
                val2 ~= 0 and val2 or hrp.Position.Y,
                val3 ~= 0 and val3 or hrp.Position.Z
            )
            hrp.CFrame = CFrame.new(target)
            return string.format("✅ Teleportado a **(%.1f, %.1f, %.1f)**", target.X, target.Y, target.Z)
        end
        return "❌ No se encontró el personaje."

    elseif cmd == "FLY" then
        local on = strVal:upper() == "ON"
        if on then
            -- Activar vuelo (manejado externamente por el módulo Fly)
            State.FlyEnabled = true
            return "✅ **Vuelo activado** · Usa el panel Tools para controlarlo."
        else
            State.FlyEnabled = false
            if State.FlyBodyVelocity then pcall(function() State.FlyBodyVelocity:Destroy() end) end
            if State.FlyBodyGyro    then pcall(function() State.FlyBodyGyro:Destroy()    end) end
            return "✅ **Vuelo desactivado**"
        end

    elseif cmd == "FLY_SPEED" then
        State.FlySpeed = math.clamp(val1, 10, 9999)
        return string.format("✅ Velocidad de vuelo → **%d**", State.FlySpeed)

    elseif cmd == "INF_JUMP" then
        State.InfJumpEnabled = strVal:upper() == "ON"
        return State.InfJumpEnabled and "✅ **Salto Infinito activado**" or "✅ **Salto Infinito desactivado**"

    elseif cmd == "SET_HEALTH" then
        if hum then
            local hp = math.clamp(val1, 0, hum.MaxHealth)
            hum.Health = hp
            return string.format("✅ Salud → **%.0f / %.0f**", hp, hum.MaxHealth)
        end
        return "❌ No se encontró humanoid."

    elseif cmd == "INVISIBLE" then
        if char then
            local invis = strVal:upper() == "ON"
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = invis and 1 or 0
                end
            end
            return invis and "✅ **Personaje invisible**" or "✅ **Personaje visible**"
        end
        return "❌ No se encontró el personaje."

    elseif cmd == "RESET_CHAR" then
        if hum then
            hum.Health = 0
            return "✅ **Personaje reseteado**"
        end
        return "❌ No se encontró humanoid."

    elseif cmd == "SAVE_CHECKPOINT" then
        if hrp then
            local name = strVal ~= "" and strVal or ("CP" .. (#State.Checkpoints + 1))
            if #State.Checkpoints >= State.MaxCheckpoints then
                table.remove(State.Checkpoints, 1)
            end
            table.insert(State.Checkpoints, {
                name   = name,
                cf     = hrp.CFrame,
                pos    = hrp.Position,
            })
            return string.format("✅ **Checkpoint '%s' guardado** en (%.1f, %.1f, %.1f)",
                name, hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
        end
        return "❌ No se encontró el personaje."

    elseif cmd == "GOTO_CHECKPOINT" then
        if hrp then
            for _, cp in ipairs(State.Checkpoints) do
                if cp.name:lower() == strVal:lower() then
                    hrp.CFrame = cp.cf
                    return string.format("✅ Teletransportado al checkpoint **'%s'**", cp.name)
                end
            end
            -- Si no encuentra por nombre, va al último
            if #State.Checkpoints > 0 then
                local last = State.Checkpoints[#State.Checkpoints]
                hrp.CFrame = last.cf
                return string.format("✅ Teletransportado al último checkpoint **'%s'**", last.name)
            end
            return "❌ No se encontró el checkpoint '" .. strVal .. "'."
        end
        return "❌ No se encontró el personaje."

    else
        return nil  -- No es una acción reconocida
    end
end

-- ============================================================
--  MÓDULO FLY
-- ============================================================
local FlyModule = {}

function FlyModule.Start()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end

    FlyModule.Stop()
    State.FlyEnabled = true
    hum.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent   = hrp
    State.FlyBodyVelocity = bv

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D = 100
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    State.FlyBodyGyro = bg

    State.FlyConnection = RunService.Heartbeat:Connect(function()
        if not State.FlyEnabled then FlyModule.Stop() return end

        local char2 = LocalPlayer.Character
        local hrp2  = char2 and char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 then FlyModule.Stop() return end

        local cam  = Camera
        local spd  = State.FlySpeed
        local dir  = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) or
           UserInputService:IsKeyDown(Enum.KeyCode.E) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
           UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            dir = dir - Vector3.new(0, 1, 0)
        end

        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * spd
        else
            bv.Velocity = bv.Velocity * 0.82  -- deceleración suave
        end

        bg.CFrame = CFrame.new(Vector3.zero, cam.CFrame.LookVector)
    end)

    return true
end

function FlyModule.Stop()
    State.FlyEnabled = false
    pcall(function()
        if State.FlyConnection then
            State.FlyConnection:Disconnect()
            State.FlyConnection = nil
        end
    end)
    pcall(function()
        if State.FlyBodyVelocity then
            State.FlyBodyVelocity:Destroy()
            State.FlyBodyVelocity = nil
        end
    end)
    pcall(function()
        if State.FlyBodyGyro then
            State.FlyBodyGyro:Destroy()
            State.FlyBodyGyro = nil
        end
    end)
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

-- ============================================================
--  MÓDULO INFINITE JUMP
-- ============================================================
local InfJumpModule = {}

function InfJumpModule.Start()
    InfJumpModule.Stop()
    State.InfJumpEnabled = true
    State.InfJumpConn = UserInputService.JumpRequest:Connect(function()
        if not State.InfJumpEnabled then InfJumpModule.Stop() return end
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hrp then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function InfJumpModule.Stop()
    State.InfJumpEnabled = false
    if State.InfJumpConn then
        pcall(function() State.InfJumpConn:Disconnect() end)
        State.InfJumpConn = nil
    end
end

-- ============================================================
--  MÓDULO CLICK TELEPORT
-- ============================================================
local ClickTPModule = {}

function ClickTPModule.Start()
    ClickTPModule.Stop()
    State.ClickTPEnabled = true
    State.ClickTPConn = Mouse.Button1Down:Connect(function()
        if not State.ClickTPEnabled then ClickTPModule.Stop() return end
        local target = Mouse.Hit
        if target then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
            end
        end
    end)
end

function ClickTPModule.Stop()
    State.ClickTPEnabled = false
    if State.ClickTPConn then
        pcall(function() State.ClickTPConn:Disconnect() end)
        State.ClickTPConn = nil
    end
end

-- ============================================================
--  MÓDULO HEADSIT
-- ============================================================
local HeadsitModule = {}

function HeadsitModule.SitOnPlayer(targetName)
    local target = Players:FindFirstChild(targetName)
    if not target then return false, "Jugador no encontrado: " .. targetName end
    local tChar = target.Character
    local tHead = tChar and tChar:FindFirstChild("Head")
    if not tHead then return false, "No se encontró la cabeza de " .. targetName end

    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum  = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHRP then return false, "No se encontró tu personaje." end

    myHRP.CFrame = CFrame.new(tHead.Position + Vector3.new(0, 3, 0))
    if myHum then myHum.Sit = true end
    return true, "✅ Sentado en la cabeza de " .. targetName
end

-- ============================================================
--  MÓDULO CHECKPOINTS (UI)
-- ============================================================
local CheckpointModule = {}

function CheckpointModule.Save(name)
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "No se encontró el personaje." end

    name = name ~= "" and name or ("CP" .. (#State.Checkpoints + 1))
    if #State.Checkpoints >= State.MaxCheckpoints then
        table.remove(State.Checkpoints, 1)
    end
    table.insert(State.Checkpoints, {
        name = name,
        cf   = hrp.CFrame,
        pos  = hrp.Position,
    })
    return true, string.format("Checkpoint '%s' guardado", name)
end

function CheckpointModule.Load(index)
    local cp = State.Checkpoints[index]
    if not cp then return false, "Checkpoint no encontrado" end
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "No se encontró el personaje." end
    hrp.CFrame = cp.cf
    return true, string.format("Teletransportado a '%s'", cp.name)
end

-- ============================================================
--  ELIMINAR GUI ANTERIOR Y CREAR SCREENGUI
-- ============================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = PlayerGui:FindFirstChild("KaelenUI_v23")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "KaelenUI_v23"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = PlayerGui

-- ============================================================
--  BOTÓN FLOTANTE
-- ============================================================
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name            = "FloatBtn"
FloatBtn.Size            = UDim2.new(0, 60, 0, 60)
FloatBtn.Position        = UDim2.new(1, -80, 0.5, -30)
FloatBtn.BackgroundColor3 = CONFIG.Colors.Accent
FloatBtn.Text            = ""
FloatBtn.ZIndex          = 200
FloatBtn.Parent          = ScreenGui
MakeCorner(FloatBtn, 30)
MakeStroke(FloatBtn, CONFIG.Colors.AccentGlow, 2)

local BtnGlow = Instance.new("ImageLabel")
BtnGlow.Size              = UDim2.new(1.7, 0, 1.7, 0)
BtnGlow.Position          = UDim2.new(-0.35, 0, -0.35, 0)
BtnGlow.BackgroundTransparency = 1
BtnGlow.Image             = "rbxassetid://5028857084"
BtnGlow.ImageColor3       = CONFIG.Colors.Accent
BtnGlow.ImageTransparency = 0.5
BtnGlow.ZIndex            = 199
BtnGlow.Parent            = FloatBtn

MakeGradient(FloatBtn,
    Color3.fromRGB(140, 90, 255),
    Color3.fromRGB(80, 50, 200),
    135
)

local BtnInnerCircle = Instance.new("Frame")
BtnInnerCircle.Size = UDim2.new(0, 44, 0, 44)
BtnInnerCircle.Position = UDim2.new(0.5, -22, 0.5, -22)
BtnInnerCircle.BackgroundColor3 = Color3.fromRGB(160, 120, 255)
BtnInnerCircle.BackgroundTransparency = 0.7
BtnInnerCircle.ZIndex = 200
BtnInnerCircle.Parent = FloatBtn
MakeCorner(BtnInnerCircle, 22)

local BtnIcon = Instance.new("TextLabel")
BtnIcon.Size             = UDim2.new(1, 0, 1, 0)
BtnIcon.BackgroundTransparency = 1
BtnIcon.Text             = "K"
BtnIcon.TextColor3       = CONFIG.Colors.White
BtnIcon.TextSize         = 24
BtnIcon.Font             = CONFIG.Font
BtnIcon.ZIndex           = 201
BtnIcon.Parent           = FloatBtn

-- Pulso del botón
task.spawn(function()
    while true do
        Tween(BtnGlow, {ImageTransparency = 0.15}, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
        Tween(BtnGlow, {ImageTransparency = 0.65}, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.4)
    end
end)

-- Drag del botón flotante
local btnDragging  = false
local btnDragStart, btnStartPos

FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        btnDragging  = true
        btnDragStart = inp.Position
        btnStartPos  = FloatBtn.Position
    end
end)

FloatBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        btnDragging = false
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if btnDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or
                        inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - btnDragStart
        FloatBtn.Position = UDim2.new(
            btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X,
            btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
--  VENTANA PRINCIPAL
-- ============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 420, 0, 640)
MainFrame.Position         = UDim2.new(0.5, -210, 0.5, -320)
MainFrame.BackgroundColor3 = CONFIG.Colors.BG
MainFrame.BackgroundTransparency = 0.02
MainFrame.ClipsDescendants = true
MainFrame.Visible          = false
MainFrame.ZIndex           = 100
MainFrame.Parent           = ScreenGui
MakeCorner(MainFrame, 22)
MakeStroke(MainFrame, Color3.fromRGB(75, 55, 130), 1.5)
MakeShadow(MainFrame)

MakeGradient(MainFrame,
    Color3.fromRGB(10, 9, 22),
    Color3.fromRGB(6, 6, 16),
    160
)

-- Línea de acento top
local AccentLine = Instance.new("Frame")
AccentLine.Size             = UDim2.new(1, 0, 0, 2)
AccentLine.BackgroundTransparency = 0
AccentLine.BorderSizePixel  = 0
AccentLine.ZIndex           = 101
AccentLine.Parent           = MainFrame
MakeGradient(AccentLine,
    Color3.fromRGB(100, 60, 220),
    Color3.fromRGB(180, 130, 255),
    90
)

-- Arrastre de MainFrame
local frameDragging   = false
local frameDragStart
local frameStartPos

-- ============================================================
--  HEADER
-- ============================================================
local Header = Instance.new("Frame")
Header.Name             = "Header"
Header.Size             = UDim2.new(1, 0, 0, 60)
Header.Position         = UDim2.new(0, 0, 0, 2)
Header.BackgroundColor3 = CONFIG.Colors.HeaderBG
Header.BackgroundTransparency = 0.15
Header.ZIndex           = 102
Header.Parent           = MainFrame
MakeCorner(Header, 22)
MakeStroke(Header, Color3.fromRGB(55, 40, 100), 1)

-- Logo circle
local LogoCircle = Instance.new("Frame")
LogoCircle.Size             = UDim2.new(0, 38, 0, 38)
LogoCircle.Position         = UDim2.new(0, 14, 0.5, -19)
LogoCircle.BackgroundColor3 = CONFIG.Colors.Accent
LogoCircle.ZIndex           = 103
LogoCircle.Parent           = Header
MakeCorner(LogoCircle, 19)
MakeGradient(LogoCircle,
    Color3.fromRGB(150, 100, 255),
    Color3.fromRGB(80, 50, 200),
    135
)
MakeStroke(LogoCircle, Color3.fromRGB(180, 140, 255), 1.5)

local LogoText = Instance.new("TextLabel")
LogoText.Size             = UDim2.new(1, 0, 1, 0)
LogoText.BackgroundTransparency = 1
LogoText.Text             = "K"
LogoText.TextColor3       = CONFIG.Colors.White
LogoText.TextSize         = 18
LogoText.Font             = CONFIG.Font
LogoText.ZIndex           = 104
LogoText.Parent           = LogoCircle

-- Título y subtítulo
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size             = UDim2.new(0, 120, 0, 22)
TitleLabel.Position         = UDim2.new(0, 62, 0, 10)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text             = "Kaelen"
TitleLabel.TextColor3       = CONFIG.Colors.White
TitleLabel.TextSize         = 18
TitleLabel.Font             = CONFIG.Font
TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left
TitleLabel.ZIndex           = 103
TitleLabel.Parent           = Header

local SubLabel = Instance.new("TextLabel")
SubLabel.Name               = "SubLabel"
SubLabel.Size               = UDim2.new(0, 220, 0, 15)
SubLabel.Position           = UDim2.new(0, 62, 0, 34)
SubLabel.BackgroundTransparency = 1
SubLabel.Text               = "AI Systems v2.3  ·  " .. State.CurrentMode
SubLabel.TextColor3         = CONFIG.Colors.TextMuted
SubLabel.TextSize           = 10
SubLabel.Font               = CONFIG.FontReg
SubLabel.TextXAlignment     = Enum.TextXAlignment.Left
SubLabel.ZIndex             = 103
SubLabel.Parent             = Header

-- Indicador estado
local StatusDot = Instance.new("Frame")
StatusDot.Size              = UDim2.new(0, 9, 0, 9)
StatusDot.Position          = UDim2.new(1, -60, 0.5, -4)
StatusDot.BackgroundColor3  = CONFIG.Colors.Red
StatusDot.ZIndex            = 104
StatusDot.Parent            = Header
MakeCorner(StatusDot, 5)

-- Botón minimizar
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 30, 0, 30)
MinBtn.Position         = UDim2.new(1, -74, 0.5, -15)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 190, 50)
MinBtn.BackgroundTransparency = 0.3
MinBtn.Text             = "─"
MinBtn.TextColor3       = CONFIG.Colors.White
MinBtn.TextSize         = 14
MinBtn.Font             = CONFIG.Font
MinBtn.ZIndex           = 104
MinBtn.Parent           = Header
MakeCorner(MinBtn, 15)

-- Botón cerrar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 30, 0, 30)
CloseBtn.Position         = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = CONFIG.Colors.Red
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = CONFIG.Colors.White
CloseBtn.TextSize         = 13
CloseBtn.Font             = CONFIG.Font
CloseBtn.ZIndex           = 104
CloseBtn.Parent           = Header
MakeCorner(CloseBtn, 15)

-- Arrastre del header
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        frameDragging  = true
        frameDragStart = inp.Position
        frameStartPos  = MainFrame.Position
    end
end)
Header.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        frameDragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if frameDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - frameDragStart
        MainFrame.Position = UDim2.new(
            frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
--  TAB BAR
-- ============================================================
local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -24, 0, 38)
TabBar.Position         = UDim2.new(0, 12, 0, 66)
TabBar.BackgroundColor3 = CONFIG.Colors.Card
TabBar.BackgroundTransparency = 0.25
TabBar.ZIndex           = 102
TabBar.Parent           = MainFrame
MakeCorner(TabBar, 11)
MakeStroke(TabBar, CONFIG.Colors.Border, 1)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection      = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
TabLayout.Padding            = UDim.new(0, 3)
TabLayout.Parent             = TabBar
MakePadding(TabBar, 4, 4, 4, 4)

-- Tabs: Chat | Modos | Tools | Stats | Config
local TABS = {
    {name = "Chat",   icon = "💬"},
    {name = "Modos",  icon = "🎯"},
    {name = "Tools",  icon = "🔧"},
    {name = "Stats",  icon = "📊"},
    {name = "Config", icon = "⚙️"},
}
local TabButtons = {}

local function SetActiveTab(name)
    State.CurrentTab = name
    for _, info in pairs(TabButtons) do
        local isActive = info.name == name
        Tween(info.btn, {
            BackgroundColor3    = isActive and CONFIG.Colors.Accent or CONFIG.Colors.Card,
            BackgroundTransparency = isActive and 0 or 0.6,
        }, 0.2)
        info.lbl.TextColor3 = isActive and CONFIG.Colors.White or CONFIG.Colors.TextMuted
    end
end

for _, tab in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 68, 1, 0)
    btn.BackgroundColor3 = CONFIG.Colors.Card
    btn.BackgroundTransparency = 0.6
    btn.Text             = ""
    btn.ZIndex           = 103
    btn.Parent           = TabBar
    MakeCorner(btn, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = tab.icon .. " " .. tab.name
    lbl.TextColor3       = CONFIG.Colors.TextMuted
    lbl.TextSize         = 11
    lbl.Font             = CONFIG.Font
    lbl.ZIndex           = 104
    lbl.Parent           = btn

    table.insert(TabButtons, {name = tab.name, btn = btn, lbl = lbl})
    btn.MouseButton1Click:Connect(function()
        if tab.name ~= "Chat" and not State.KeyVerified then return end
        SetActiveTab(tab.name)
        -- Mostrar/ocultar paneles se hace en ShowPanel
    end)
end

-- ============================================================
--  CONTENEDOR DE PANELES (debajo del TabBar)
-- ============================================================
local PanelContainer = Instance.new("Frame")
PanelContainer.Size             = UDim2.new(1, -24, 1, -118)
PanelContainer.Position         = UDim2.new(0, 12, 0, 110)
PanelContainer.BackgroundTransparency = 1
PanelContainer.ClipsDescendants = true
PanelContainer.ZIndex           = 102
PanelContainer.Parent           = MainFrame

-- ============================================================
--  PANEL: KEY SYSTEM
-- ============================================================
local KeyPanel = Instance.new("Frame")
KeyPanel.Size             = UDim2.new(1, 0, 1, 0)
KeyPanel.BackgroundTransparency = 1
KeyPanel.ZIndex           = 103
KeyPanel.Visible          = true
KeyPanel.Parent           = PanelContainer

local KeyLayout = Instance.new("UIListLayout")
KeyLayout.FillDirection      = Enum.FillDirection.Vertical
KeyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
KeyLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
KeyLayout.Padding            = UDim.new(0, 16)
KeyLayout.Parent             = KeyPanel

-- Ícono
local LockIcon = Instance.new("TextLabel")
LockIcon.Size             = UDim2.new(0, 78, 0, 78)
LockIcon.BackgroundColor3 = CONFIG.Colors.Card
LockIcon.Text             = "🔑"
LockIcon.TextSize         = 36
LockIcon.Font             = CONFIG.FontReg
LockIcon.TextColor3       = CONFIG.Colors.White
LockIcon.ZIndex           = 104
LockIcon.LayoutOrder      = 1
LockIcon.Parent           = KeyPanel
MakeCorner(LockIcon, 39)
MakeStroke(LockIcon, CONFIG.Colors.Accent, 2)

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size             = UDim2.new(1, 0, 0, 26)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text             = "Activar Kaelen v2.3"
KeyTitle.TextColor3       = CONFIG.Colors.White
KeyTitle.TextSize         = 19
KeyTitle.Font             = CONFIG.Font
KeyTitle.LayoutOrder      = 2
KeyTitle.Parent           = KeyPanel

local KeySub = Instance.new("TextLabel")
KeySub.Size             = UDim2.new(1, 0, 0, 36)
KeySub.BackgroundTransparency = 1
KeySub.Text             = "Introduce tu API Key de OpenRouter\npara desbloquear todas las funciones"
KeySub.TextColor3       = CONFIG.Colors.TextMuted
KeySub.TextSize         = 12
KeySub.Font             = CONFIG.FontReg
KeySub.TextWrapped      = true
KeySub.LayoutOrder      = 3
KeySub.Parent           = KeyPanel

local KeyInput = Instance.new("TextBox")
KeyInput.Size             = UDim2.new(1, 0, 0, 48)
KeyInput.BackgroundColor3 = CONFIG.Colors.Card
KeyInput.BackgroundTransparency = 0.1
KeyInput.Text             = ""
KeyInput.PlaceholderText  = "sk-or-v1-xxxxxxxxxxxxxxxxxxxx"
KeyInput.TextColor3       = CONFIG.Colors.Text
KeyInput.PlaceholderColor3 = CONFIG.Colors.TextMuted
KeyInput.TextSize         = 13
KeyInput.Font             = CONFIG.FontReg
KeyInput.ClearTextOnFocus = false
KeyInput.ZIndex           = 104
KeyInput.LayoutOrder      = 4
KeyInput.Parent           = KeyPanel
MakeCorner(KeyInput, 12)
MakeStroke(KeyInput, CONFIG.Colors.Border, 1)
MakePadding(KeyInput, 0, 0, 14, 14)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size             = UDim2.new(1, 0, 0, 48)
VerifyBtn.BackgroundColor3 = CONFIG.Colors.Accent
VerifyBtn.Text             = "Verificar y Activar"
VerifyBtn.TextColor3       = CONFIG.Colors.White
VerifyBtn.TextSize         = 15
VerifyBtn.Font             = CONFIG.Font
VerifyBtn.ZIndex           = 104
VerifyBtn.LayoutOrder      = 5
VerifyBtn.Parent           = KeyPanel
MakeCorner(VerifyBtn, 12)
MakeGradient(VerifyBtn,
    Color3.fromRGB(145, 95, 255),
    Color3.fromRGB(85, 55, 210),
    135
)

local KeyStatusLabel = Instance.new("TextLabel")
KeyStatusLabel.Size             = UDim2.new(1, 0, 0, 22)
KeyStatusLabel.BackgroundTransparency = 1
KeyStatusLabel.Text             = ""
KeyStatusLabel.TextColor3       = CONFIG.Colors.TextMuted
KeyStatusLabel.TextSize         = 12
KeyStatusLabel.Font             = CONFIG.FontReg
KeyStatusLabel.LayoutOrder      = 6
KeyStatusLabel.Parent           = KeyPanel

-- ============================================================
--  PANEL: CHAT
-- ============================================================
local ChatPanel = Instance.new("Frame")
ChatPanel.Size             = UDim2.new(1, 0, 1, 0)
ChatPanel.BackgroundTransparency = 1
ChatPanel.ZIndex           = 103
ChatPanel.Visible          = false
ChatPanel.Parent           = PanelContainer

-- Área de scroll de mensajes
local MsgScroll = Instance.new("ScrollingFrame")
MsgScroll.Size             = UDim2.new(1, 0, 1, -96)
MsgScroll.BackgroundTransparency = 1
MsgScroll.ScrollBarThickness = 3
MsgScroll.ScrollBarImageColor3 = CONFIG.Colors.Accent
MsgScroll.CanvasSize       = UDim2.new(0, 0, 0, 0)
MsgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MsgScroll.ZIndex           = 104
MsgScroll.Parent           = ChatPanel

local MsgLayout = Instance.new("UIListLayout")
MsgLayout.FillDirection    = Enum.FillDirection.Vertical
MsgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
MsgLayout.Padding          = UDim.new(0, 10)
MsgLayout.Parent           = MsgScroll
MakePadding(MsgScroll, 10, 10, 10, 10)

-- Indicador Thinking
local ThinkFrame = Instance.new("Frame")
ThinkFrame.Size             = UDim2.new(0, 160, 0, 34)
ThinkFrame.BackgroundColor3 = CONFIG.Colors.AIBubble
ThinkFrame.BackgroundTransparency = 0.1
ThinkFrame.Visible          = false
ThinkFrame.ZIndex           = 105
ThinkFrame.LayoutOrder      = 9999
ThinkFrame.Parent           = MsgScroll
MakeCorner(ThinkFrame, 17)
MakeStroke(ThinkFrame, CONFIG.Colors.Border, 1)
MakePadding(ThinkFrame, 0, 0, 14, 14)

local ThinkLabel = Instance.new("TextLabel")
ThinkLabel.Size             = UDim2.new(1, 0, 1, 0)
ThinkLabel.BackgroundTransparency = 1
ThinkLabel.Text             = "⬡ Kaelen pensando ●○○"
ThinkLabel.TextColor3       = CONFIG.Colors.Accent
ThinkLabel.TextSize         = 12
ThinkLabel.Font             = CONFIG.FontReg
ThinkLabel.ZIndex           = 106
ThinkLabel.Parent           = ThinkFrame

-- Área de input
local InputFrame = Instance.new("Frame")
InputFrame.Size             = UDim2.new(1, 0, 0, 92)
InputFrame.Position         = UDim2.new(0, 0, 1, -92)
InputFrame.BackgroundColor3 = CONFIG.Colors.Surface
InputFrame.BackgroundTransparency = 0.15
InputFrame.ZIndex           = 104
InputFrame.Parent           = ChatPanel
MakeCorner(InputFrame, 16)
MakeStroke(InputFrame, CONFIG.Colors.Border, 1)

local ChatInput = Instance.new("TextBox")
ChatInput.Size             = UDim2.new(1, -58, 0, 44)
ChatInput.Position         = UDim2.new(0, 10, 0, 8)
ChatInput.BackgroundColor3 = CONFIG.Colors.Card
ChatInput.BackgroundTransparency = 0.1
ChatInput.Text             = ""
ChatInput.PlaceholderText  = "Escribe o dile a Kaelen qué hacer..."
ChatInput.TextColor3       = CONFIG.Colors.Text
ChatInput.PlaceholderColor3 = CONFIG.Colors.TextMuted
ChatInput.TextSize         = 13
ChatInput.Font             = CONFIG.FontReg
ChatInput.MultiLine        = false
ChatInput.ClearTextOnFocus = false
ChatInput.ZIndex           = 105
ChatInput.Parent           = InputFrame
MakeCorner(ChatInput, 10)
MakePadding(ChatInput, 0, 0, 12, 12)
MakeStroke(ChatInput, CONFIG.Colors.Border, 1)

local SendBtn = Instance.new("TextButton")
SendBtn.Size             = UDim2.new(0, 44, 0, 44)
SendBtn.Position         = UDim2.new(1, -54, 0, 8)
SendBtn.BackgroundColor3 = CONFIG.Colors.Accent
SendBtn.Text             = "➤"
SendBtn.TextColor3       = CONFIG.Colors.White
SendBtn.TextSize         = 20
SendBtn.Font             = CONFIG.Font
SendBtn.ZIndex           = 105
SendBtn.Parent           = InputFrame
MakeCorner(SendBtn, 10)
MakeGradient(SendBtn,
    Color3.fromRGB(145, 95, 255),
    Color3.fromRGB(85, 55, 210),
    135
)

-- Botones rápidos
local QuickBtnFrame = Instance.new("Frame")
QuickBtnFrame.Size             = UDim2.new(1, 0, 0, 32)
QuickBtnFrame.Position         = UDim2.new(0, 0, 0, 56)
QuickBtnFrame.BackgroundTransparency = 1
QuickBtnFrame.ZIndex           = 105
QuickBtnFrame.Parent           = InputFrame

local QuickLayout2 = Instance.new("UIListLayout")
QuickLayout2.FillDirection     = Enum.FillDirection.Horizontal
QuickLayout2.Padding           = UDim.new(0, 4)
QuickLayout2.VerticalAlignment = Enum.VerticalAlignment.Center
QuickLayout2.Parent            = QuickBtnFrame
MakePadding(QuickBtnFrame, 2, 2, 10, 10)

local QuickCmds = {
    {label = "🎮 Analizar", cmd = "ANALYZE"},
    {label = "🔍 Bugs",     cmd = "BUGS"},
    {label = "💻 Script",   cmd = "SCRIPT"},
    {label = "📋 Copiar",   cmd = "EXPORT"},
    {label = "🗑 Limpiar",  cmd = "CLEAR"},
}

for _, qc in ipairs(QuickCmds) do
    local qb = Instance.new("TextButton")
    qb.Size             = UDim2.new(0, 0, 1, 0)
    qb.AutomaticSize    = Enum.AutomaticSize.X
    qb.BackgroundColor3 = CONFIG.Colors.Card
    qb.BackgroundTransparency = 0.3
    qb.Text             = qc.label
    qb.TextColor3       = CONFIG.Colors.TextMuted
    qb.TextSize         = 10
    qb.Font             = CONFIG.FontReg
    qb.ZIndex           = 106
    qb.Parent           = QuickBtnFrame
    MakeCorner(qb, 7)
    MakePadding(qb, 2, 2, 7, 7)
end

-- ============================================================
--  PANEL: MODOS
-- ============================================================
local ModesPanel = Instance.new("Frame")
ModesPanel.Size             = UDim2.new(1, 0, 1, 0)
ModesPanel.BackgroundTransparency = 1
ModesPanel.ZIndex           = 103
ModesPanel.Visible          = false
ModesPanel.Parent           = PanelContainer

local ModesLayout = Instance.new("UIListLayout")
ModesLayout.FillDirection   = Enum.FillDirection.Vertical
ModesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ModesLayout.Padding         = UDim.new(0, 10)
ModesLayout.Parent          = ModesPanel
MakePadding(ModesPanel, 14, 14, 0, 0)

local ModeTitle = Instance.new("TextLabel")
ModeTitle.Size              = UDim2.new(1, 0, 0, 26)
ModeTitle.BackgroundTransparency = 1
ModeTitle.Text              = "Modo de Operación"
ModeTitle.TextColor3        = CONFIG.Colors.White
ModeTitle.TextSize          = 16
ModeTitle.Font              = CONFIG.Font
ModeTitle.LayoutOrder       = 1
ModeTitle.Parent            = ModesPanel

local ModeSubtitle = Instance.new("TextLabel")
ModeSubtitle.Size           = UDim2.new(1, 0, 0, 20)
ModeSubtitle.BackgroundTransparency = 1
ModeSubtitle.Text           = "Selecciona cómo quieres que Kaelen responda"
ModeSubtitle.TextColor3     = CONFIG.Colors.TextMuted
ModeSubtitle.TextSize       = 11
ModeSubtitle.Font           = CONFIG.FontReg
ModeSubtitle.LayoutOrder    = 2
ModeSubtitle.Parent         = ModesPanel

local ModeConfigs = {
    {name = "Programador", icon = "💻", desc = "Scripts Lua premium, optimización y debugging profundo"},
    {name = "Analista",    icon = "🔍", desc = "Análisis de juego, arquitectura y detección de vulnerabilidades"},
    {name = "Creativo",    icon = "🎨", desc = "Ideas innovadoras, mecánicas únicas y diseño de sistemas"},
    {name = "Troll",       icon = "😈", desc = "Testing social divertido con mecánicas legítimas del juego"},
}

local ModeBtnObjects = {}
for idx, mc in ipairs(ModeConfigs) do
    local isActive = mc.name == State.CurrentMode

    local mf = Instance.new("TextButton")
    mf.Size             = UDim2.new(1, 0, 0, 72)
    mf.BackgroundColor3 = isActive and CONFIG.Colors.AccentSoft or CONFIG.Colors.Card
    mf.BackgroundTransparency = isActive and 0.1 or 0.3
    mf.Text             = ""
    mf.ZIndex           = 104
    mf.LayoutOrder      = idx + 2
    mf.Parent           = ModesPanel
    MakeCorner(mf, 14)
    MakeStroke(mf, isActive and CONFIG.Colors.Accent or CONFIG.Colors.Border, isActive and 2 or 1)

    local mIcon = Instance.new("TextLabel")
    mIcon.Size          = UDim2.new(0, 44, 0, 44)
    mIcon.Position      = UDim2.new(0, 14, 0.5, -22)
    mIcon.BackgroundColor3 = CONFIG.Colors.BG
    mIcon.BackgroundTransparency = 0.4
    mIcon.Text          = mc.icon
    mIcon.TextSize      = 22
    mIcon.Font          = CONFIG.FontReg
    mIcon.TextColor3    = CONFIG.Colors.White
    mIcon.ZIndex        = 105
    mIcon.Parent        = mf
    MakeCorner(mIcon, 22)

    local mName = Instance.new("TextLabel")
    mName.Size          = UDim2.new(1, -70, 0, 22)
    mName.Position      = UDim2.new(0, 68, 0, 12)
    mName.BackgroundTransparency = 1
    mName.Text          = mc.name
    mName.TextColor3    = isActive and CONFIG.Colors.White or CONFIG.Colors.Text
    mName.TextSize      = 15
    mName.Font          = CONFIG.Font
    mName.TextXAlignment = Enum.TextXAlignment.Left
    mName.ZIndex        = 105
    mName.Parent        = mf

    local mDesc = Instance.new("TextLabel")
    mDesc.Size          = UDim2.new(1, -70, 0, 30)
    mDesc.Position      = UDim2.new(0, 68, 0, 34)
    mDesc.BackgroundTransparency = 1
    mDesc.Text          = mc.desc
    mDesc.TextColor3    = CONFIG.Colors.TextMuted
    mDesc.TextSize      = 11
    mDesc.Font          = CONFIG.FontReg
    mDesc.TextWrapped   = true
    mDesc.TextXAlignment = Enum.TextXAlignment.Left
    mDesc.ZIndex        = 105
    mDesc.Parent        = mf

    -- Badge "Activo"
    local badge = Instance.new("TextLabel")
    badge.Size          = UDim2.new(0, 50, 0, 20)
    badge.Position      = UDim2.new(1, -62, 0, 10)
    badge.BackgroundColor3 = CONFIG.Colors.Accent
    badge.BackgroundTransparency = isActive and 0 or 1
    badge.Text          = "Activo"
    badge.TextColor3    = CONFIG.Colors.White
    badge.TextSize      = 10
    badge.Font          = CONFIG.Font
    badge.ZIndex        = 106
    badge.Parent        = mf
    MakeCorner(badge, 10)

    table.insert(ModeBtnObjects, {name = mc.name, btn = mf, nameLbl = mName, badge = badge})

    mf.MouseButton1Click:Connect(function()
        State.CurrentMode = mc.name
        SubLabel.Text = "AI Systems v2.3  ·  " .. mc.name

        for _, mb in pairs(ModeBtnObjects) do
            local active = mb.name == mc.name
            Tween(mb.btn, {
                BackgroundColor3 = active and CONFIG.Colors.AccentSoft or CONFIG.Colors.Card,
                BackgroundTransparency = active and 0.1 or 0.3,
            }, 0.25)
            mb.badge.BackgroundTransparency = active and 0 or 1
        end

        -- Feedback visual
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = CONFIG.Colors.Accent
        flash.BackgroundTransparency = 0.7
        flash.ZIndex = 200
        flash.Parent = mf
        MakeCorner(flash, 14)
        Tween(flash, {BackgroundTransparency = 1}, 0.4)
        task.delay(0.4, function() flash:Destroy() end)
    end)
end

-- ============================================================
--  PANEL: TOOLS (Features de movimiento)
-- ============================================================
local ToolsPanel = Instance.new("ScrollingFrame")
ToolsPanel.Size             = UDim2.new(1, 0, 1, 0)
ToolsPanel.BackgroundTransparency = 1
ToolsPanel.ScrollBarThickness = 3
ToolsPanel.ScrollBarImageColor3 = CONFIG.Colors.Accent
ToolsPanel.CanvasSize       = UDim2.new(0, 0, 0, 0)
ToolsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
ToolsPanel.ZIndex           = 103
ToolsPanel.Visible          = false
ToolsPanel.Parent           = PanelContainer

local ToolsLayout = Instance.new("UIListLayout")
ToolsLayout.FillDirection   = Enum.FillDirection.Vertical
ToolsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ToolsLayout.Padding         = UDim.new(0, 10)
ToolsLayout.Parent          = ToolsPanel
MakePadding(ToolsPanel, 10, 10, 0, 0)

-- Helper: crear botón toggle para Tools
local function MakeToolToggle(parent, label, icon, layoutOrder)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 58)
    row.BackgroundColor3 = CONFIG.Colors.Card
    row.BackgroundTransparency = 0.25
    row.ZIndex           = 104
    row.LayoutOrder      = layoutOrder
    row.Parent           = parent
    MakeCorner(row, 14)
    MakeStroke(row, CONFIG.Colors.Border, 1)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size   = UDim2.new(0, 40, 0, 40)
    iconLbl.Position = UDim2.new(0, 10, 0.5, -20)
    iconLbl.BackgroundColor3 = CONFIG.Colors.BG
    iconLbl.BackgroundTransparency = 0.3
    iconLbl.Text   = icon
    iconLbl.TextSize = 20
    iconLbl.Font   = CONFIG.FontReg
    iconLbl.TextColor3 = CONFIG.Colors.White
    iconLbl.ZIndex = 105
    iconLbl.Parent = row
    MakeCorner(iconLbl, 20)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size   = UDim2.new(0, 180, 0, 22)
    nameLbl.Position = UDim2.new(0, 60, 0.5, -11)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text   = label
    nameLbl.TextColor3 = CONFIG.Colors.Text
    nameLbl.TextSize = 14
    nameLbl.Font   = CONFIG.Font
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.ZIndex = 105
    nameLbl.Parent = row

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size  = UDim2.new(0, 68, 0, 30)
    toggleBtn.Position = UDim2.new(1, -78, 0.5, -15)
    toggleBtn.BackgroundColor3 = CONFIG.Colors.RedDark
    toggleBtn.Text  = "OFF"
    toggleBtn.TextColor3 = CONFIG.Colors.Text
    toggleBtn.TextSize = 13
    toggleBtn.Font  = CONFIG.Font
    toggleBtn.ZIndex = 105
    toggleBtn.Parent = row
    MakeCorner(toggleBtn, 15)
    MakeStroke(toggleBtn, CONFIG.Colors.Red, 1)

    return row, toggleBtn, nameLbl
end

-- Helper: crear sección de título en Tools
local function MakeToolSection(parent, title, order)
    local sec = Instance.new("TextLabel")
    sec.Size             = UDim2.new(1, 0, 0, 22)
    sec.BackgroundTransparency = 1
    sec.Text             = title
    sec.TextColor3       = CONFIG.Colors.Accent
    sec.TextSize         = 12
    sec.Font             = CONFIG.Font
    sec.TextXAlignment   = Enum.TextXAlignment.Left
    sec.ZIndex           = 104
    sec.LayoutOrder      = order
    sec.Parent           = parent
    return sec
end

-- Sección: MOVIMIENTO
MakeToolSection(ToolsPanel, "── MOVIMIENTO ──────────────────", 1)

-- FLY
local flyRow, flyToggle = MakeToolToggle(ToolsPanel, "Fly Mode", "🛸", 2)
local flySpeedRow = Instance.new("Frame")
flySpeedRow.Size = UDim2.new(1, 0, 0, 48)
flySpeedRow.BackgroundColor3 = CONFIG.Colors.Card
flySpeedRow.BackgroundTransparency = 0.4
flySpeedRow.ZIndex = 104
flySpeedRow.LayoutOrder = 3
flySpeedRow.Parent = ToolsPanel
MakeCorner(flySpeedRow, 12)
MakeStroke(flySpeedRow, CONFIG.Colors.Border, 1)

local flySpeedLbl = Instance.new("TextLabel")
flySpeedLbl.Size = UDim2.new(0, 140, 0, 20)
flySpeedLbl.Position = UDim2.new(0, 12, 0.5, -10)
flySpeedLbl.BackgroundTransparency = 1
flySpeedLbl.Text = "🚀 Velocidad Vuelo: 60"
flySpeedLbl.TextColor3 = CONFIG.Colors.TextMuted
flySpeedLbl.TextSize = 12
flySpeedLbl.Font = CONFIG.FontReg
flySpeedLbl.TextXAlignment = Enum.TextXAlignment.Left
flySpeedLbl.ZIndex = 105
flySpeedLbl.Parent = flySpeedRow

local flySlider = Instance.new("Frame")
flySlider.Size = UDim2.new(0, 140, 0, 8)
flySlider.Position = UDim2.new(1, -155, 0.5, -4)
flySlider.BackgroundColor3 = CONFIG.Colors.Border
flySlider.ZIndex = 105
flySlider.Parent = flySpeedRow
MakeCorner(flySlider, 4)

local flySliderFill = Instance.new("Frame")
flySliderFill.Size = UDim2.new(0.12, 0, 1, 0)
flySliderFill.BackgroundColor3 = CONFIG.Colors.Accent
flySliderFill.ZIndex = 106
flySliderFill.Parent = flySlider
MakeCorner(flySliderFill, 4)

-- Infinite Jump
local infRow, infToggle = MakeToolToggle(ToolsPanel, "Infinite Jump", "🦘", 4)

-- Click TP
local ctpRow, ctpToggle = MakeToolToggle(ToolsPanel, "Click Teleport", "🖱️", 5)

-- Walk Speed control
local wsRow = Instance.new("Frame")
wsRow.Size = UDim2.new(1, 0, 0, 58)
wsRow.BackgroundColor3 = CONFIG.Colors.Card
wsRow.BackgroundTransparency = 0.25
wsRow.ZIndex = 104
wsRow.LayoutOrder = 6
wsRow.Parent = ToolsPanel
MakeCorner(wsRow, 14)
MakeStroke(wsRow, CONFIG.Colors.Border, 1)

local wsIconL = Instance.new("TextLabel")
wsIconL.Size = UDim2.new(0, 40, 0, 40)
wsIconL.Position = UDim2.new(0, 10, 0.5, -20)
wsIconL.BackgroundColor3 = CONFIG.Colors.BG
wsIconL.BackgroundTransparency = 0.3
wsIconL.Text = "🏃"
wsIconL.TextSize = 20
wsIconL.Font = CONFIG.FontReg
wsIconL.ZIndex = 105
wsIconL.Parent = wsRow
MakeCorner(wsIconL, 20)

local wsLabel = Instance.new("TextLabel")
wsLabel.Size = UDim2.new(0, 100, 0, 20)
wsLabel.Position = UDim2.new(0, 60, 0.5, -10)
wsLabel.BackgroundTransparency = 1
wsLabel.Text = "Walk Speed"
wsLabel.TextColor3 = CONFIG.Colors.Text
wsLabel.TextSize = 13
wsLabel.Font = CONFIG.Font
wsLabel.TextXAlignment = Enum.TextXAlignment.Left
wsLabel.ZIndex = 105
wsLabel.Parent = wsRow

local wsInput = Instance.new("TextBox")
wsInput.Size = UDim2.new(0, 80, 0, 30)
wsInput.Position = UDim2.new(1, -90, 0.5, -15)
wsInput.BackgroundColor3 = CONFIG.Colors.BG
wsInput.BackgroundTransparency = 0.2
wsInput.Text = "16"
wsInput.TextColor3 = CONFIG.Colors.Text
wsInput.TextSize = 14
wsInput.Font = CONFIG.FontMono
wsInput.ZIndex = 105
wsInput.Parent = wsRow
MakeCorner(wsInput, 8)
MakeStroke(wsInput, CONFIG.Colors.Border, 1)
MakePadding(wsInput, 0, 0, 10, 10)

wsInput.FocusLost:Connect(function()
    local v = tonumber(wsInput.Text)
    if v then
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = math.clamp(v, 1, 9999)
            wsInput.Text = tostring(math.clamp(v, 1, 9999))
        end
    else
        wsInput.Text = "16"
    end
end)

-- Sección: CHECKPOINTS
MakeToolSection(ToolsPanel, "── CHECKPOINTS ─────────────────", 7)

local cpSaveRow = Instance.new("Frame")
cpSaveRow.Size = UDim2.new(1, 0, 0, 58)
cpSaveRow.BackgroundColor3 = CONFIG.Colors.Card
cpSaveRow.BackgroundTransparency = 0.25
cpSaveRow.ZIndex = 104
cpSaveRow.LayoutOrder = 8
cpSaveRow.Parent = ToolsPanel
MakeCorner(cpSaveRow, 14)
MakeStroke(cpSaveRow, CONFIG.Colors.Border, 1)

local cpNameInput = Instance.new("TextBox")
cpNameInput.Size = UDim2.new(0, 140, 0, 32)
cpNameInput.Position = UDim2.new(0, 12, 0.5, -16)
cpNameInput.BackgroundColor3 = CONFIG.Colors.BG
cpNameInput.BackgroundTransparency = 0.2
cpNameInput.Text = ""
cpNameInput.PlaceholderText = "Nombre del CP..."
cpNameInput.TextColor3 = CONFIG.Colors.Text
cpNameInput.PlaceholderColor3 = CONFIG.Colors.TextDim
cpNameInput.TextSize = 12
cpNameInput.Font = CONFIG.FontReg
cpNameInput.ClearTextOnFocus = false
cpNameInput.ZIndex = 105
cpNameInput.Parent = cpSaveRow
MakeCorner(cpNameInput, 8)
MakeStroke(cpNameInput, CONFIG.Colors.Border, 1)
MakePadding(cpNameInput, 0, 0, 10, 10)

local cpSaveBtn = Instance.new("TextButton")
cpSaveBtn.Size = UDim2.new(0, 90, 0, 32)
cpSaveBtn.Position = UDim2.new(1, -102, 0.5, -16)
cpSaveBtn.BackgroundColor3 = CONFIG.Colors.Green
cpSaveBtn.BackgroundTransparency = 0.2
cpSaveBtn.Text = "💾 Guardar"
cpSaveBtn.TextColor3 = CONFIG.Colors.White
cpSaveBtn.TextSize = 12
cpSaveBtn.Font = CONFIG.Font
cpSaveBtn.ZIndex = 105
cpSaveBtn.Parent = cpSaveRow
MakeCorner(cpSaveBtn, 8)

-- Lista de checkpoints
local cpListScroll = Instance.new("ScrollingFrame")
cpListScroll.Size = UDim2.new(1, 0, 0, 120)
cpListScroll.BackgroundColor3 = CONFIG.Colors.Card
cpListScroll.BackgroundTransparency = 0.5
cpListScroll.ScrollBarThickness = 2
cpListScroll.ScrollBarImageColor3 = CONFIG.Colors.Accent
cpListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
cpListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
cpListScroll.ZIndex = 104
cpListScroll.LayoutOrder = 9
cpListScroll.Parent = ToolsPanel
MakeCorner(cpListScroll, 12)
MakeStroke(cpListScroll, CONFIG.Colors.Border, 1)
MakePadding(cpListScroll, 4, 4, 6, 6)

local cpListLayout = Instance.new("UIListLayout")
cpListLayout.FillDirection = Enum.FillDirection.Vertical
cpListLayout.Padding = UDim.new(0, 4)
cpListLayout.Parent = cpListScroll

local function RefreshCPList()
    for _, c in ipairs(cpListScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    if #State.Checkpoints == 0 then
        local nocp = Instance.new("TextLabel")
        nocp.Size = UDim2.new(1, 0, 0, 30)
        nocp.BackgroundTransparency = 1
        nocp.Text = "Sin checkpoints guardados"
        nocp.TextColor3 = CONFIG.Colors.TextDim
        nocp.TextSize = 11
        nocp.Font = CONFIG.FontReg
        nocp.ZIndex = 105
        nocp.Parent = cpListScroll
        return
    end
    for i, cp in ipairs(State.Checkpoints) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 32)
        row.BackgroundColor3 = CONFIG.Colors.Card
        row.BackgroundTransparency = 0.1
        row.ZIndex = 105
        row.Parent = cpListScroll
        MakeCorner(row, 8)

        local cpNameL = Instance.new("TextLabel")
        cpNameL.Size = UDim2.new(0, 160, 1, 0)
        cpNameL.Position = UDim2.new(0, 8, 0, 0)
        cpNameL.BackgroundTransparency = 1
        cpNameL.Text = "📍 " .. cp.name .. string.format("  (%.0f,%.0f,%.0f)", cp.pos.X, cp.pos.Y, cp.pos.Z)
        cpNameL.TextColor3 = CONFIG.Colors.Text
        cpNameL.TextSize = 11
        cpNameL.Font = CONFIG.FontReg
        cpNameL.TextXAlignment = Enum.TextXAlignment.Left
        cpNameL.ZIndex = 106
        cpNameL.Parent = row

        local cpLoadBtn = Instance.new("TextButton")
        cpLoadBtn.Size = UDim2.new(0, 50, 0, 22)
        cpLoadBtn.Position = UDim2.new(1, -56, 0.5, -11)
        cpLoadBtn.BackgroundColor3 = CONFIG.Colors.Accent
        cpLoadBtn.Text = "IR"
        cpLoadBtn.TextColor3 = CONFIG.Colors.White
        cpLoadBtn.TextSize = 11
        cpLoadBtn.Font = CONFIG.Font
        cpLoadBtn.ZIndex = 106
        cpLoadBtn.Parent = row
        MakeCorner(cpLoadBtn, 11)
        local idx = i
        cpLoadBtn.MouseButton1Click:Connect(function()
            local ok2, msg = CheckpointModule.Load(idx)
            Tween(cpLoadBtn, {BackgroundColor3 = ok2 and CONFIG.Colors.Green or CONFIG.Colors.Red}, 0.2)
            task.delay(0.8, function() Tween(cpLoadBtn, {BackgroundColor3 = CONFIG.Colors.Accent}, 0.2) end)
        end)
    end
end

cpSaveBtn.MouseButton1Click:Connect(function()
    local name = cpNameInput.Text
    local ok2, msg = CheckpointModule.Save(name)
    cpNameInput.Text = ""
    RefreshCPList()
    Tween(cpSaveBtn, {BackgroundColor3 = ok2 and CONFIG.Colors.Green or CONFIG.Colors.Red}, 0.2)
    task.delay(0.8, function() Tween(cpSaveBtn, {BackgroundColor3 = CONFIG.Colors.Green}, 0.2) end)
end)

-- Sección: TROLLING (testing social)
MakeToolSection(ToolsPanel, "── TESTING SOCIAL ───────────────", 10)

local headsitRow = Instance.new("Frame")
headsitRow.Size = UDim2.new(1, 0, 0, 58)
headsitRow.BackgroundColor3 = CONFIG.Colors.Card
headsitRow.BackgroundTransparency = 0.25
headsitRow.ZIndex = 104
headsitRow.LayoutOrder = 11
headsitRow.Parent = ToolsPanel
MakeCorner(headsitRow, 14)
MakeStroke(headsitRow, CONFIG.Colors.Border, 1)

local hsIcon = Instance.new("TextLabel")
hsIcon.Size = UDim2.new(0, 40, 0, 40)
hsIcon.Position = UDim2.new(0, 10, 0.5, -20)
hsIcon.BackgroundColor3 = CONFIG.Colors.BG
hsIcon.BackgroundTransparency = 0.3
hsIcon.Text = "🪑"
hsIcon.TextSize = 20
hsIcon.Font = CONFIG.FontReg
hsIcon.ZIndex = 105
hsIcon.Parent = headsitRow
MakeCorner(hsIcon, 20)

local hsInput = Instance.new("TextBox")
hsInput.Size = UDim2.new(0, 130, 0, 32)
hsInput.Position = UDim2.new(0, 60, 0.5, -16)
hsInput.BackgroundColor3 = CONFIG.Colors.BG
hsInput.BackgroundTransparency = 0.2
hsInput.Text = ""
hsInput.PlaceholderText = "Nombre jugador..."
hsInput.TextColor3 = CONFIG.Colors.Text
hsInput.PlaceholderColor3 = CONFIG.Colors.TextDim
hsInput.TextSize = 12
hsInput.Font = CONFIG.FontReg
hsInput.ClearTextOnFocus = false
hsInput.ZIndex = 105
hsInput.Parent = headsitRow
MakeCorner(hsInput, 8)
MakeStroke(hsInput, CONFIG.Colors.Border, 1)
MakePadding(hsInput, 0, 0, 10, 10)

local hsBtn = Instance.new("TextButton")
hsBtn.Size = UDim2.new(0, 70, 0, 32)
hsBtn.Position = UDim2.new(1, -80, 0.5, -16)
hsBtn.BackgroundColor3 = CONFIG.Colors.Yellow
hsBtn.BackgroundTransparency = 0.2
hsBtn.Text = "🪑 Sit"
hsBtn.TextColor3 = CONFIG.Colors.BG
hsBtn.TextSize = 12
hsBtn.Font = CONFIG.Font
hsBtn.ZIndex = 105
hsBtn.Parent = headsitRow
MakeCorner(hsBtn, 8)

hsBtn.MouseButton1Click:Connect(function()
    local ok2, msg = HeadsitModule.SitOnPlayer(hsInput.Text)
    Tween(hsBtn, {BackgroundColor3 = ok2 and CONFIG.Colors.Green or CONFIG.Colors.Red}, 0.2)
    task.delay(1, function() Tween(hsBtn, {BackgroundColor3 = CONFIG.Colors.Yellow}, 0.2) end)
end)

-- ============================================================
--  PANEL: STATS
-- ============================================================
local StatsPanel = Instance.new("Frame")
StatsPanel.Size             = UDim2.new(1, 0, 1, 0)
StatsPanel.BackgroundTransparency = 1
StatsPanel.ZIndex           = 103
StatsPanel.Visible          = false
StatsPanel.Parent           = PanelContainer

local StatsLayout = Instance.new("UIListLayout")
StatsLayout.FillDirection   = Enum.FillDirection.Vertical
StatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
StatsLayout.Padding         = UDim.new(0, 8)
StatsLayout.Parent          = StatsPanel
MakePadding(StatsPanel, 10, 10, 0, 0)

local StatsTitle = Instance.new("TextLabel")
StatsTitle.Size = UDim2.new(1, 0, 0, 26)
StatsTitle.BackgroundTransparency = 1
StatsTitle.Text = "📊 Panel de Stats en Tiempo Real"
StatsTitle.TextColor3 = CONFIG.Colors.White
StatsTitle.TextSize = 15
StatsTitle.Font = CONFIG.Font
StatsTitle.LayoutOrder = 1
StatsTitle.Parent = StatsPanel

-- Helper: crear tarjeta de stat
local function MakeStatCard(parent, label, id, order, color)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 54)
    card.BackgroundColor3 = CONFIG.Colors.Card
    card.BackgroundTransparency = 0.2
    card.ZIndex = 104
    card.LayoutOrder = order
    card.Parent = parent
    MakeCorner(card, 12)
    MakeStroke(card, color or CONFIG.Colors.Border, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = CONFIG.Colors.TextMuted
    lbl.TextSize = 12
    lbl.Font = CONFIG.FontReg
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 105
    lbl.Parent = card

    local val = Instance.new("TextLabel")
    val.Name = id .. "_val"
    val.Size = UDim2.new(0.5, -14, 1, 0)
    val.Position = UDim2.new(0.5, 0, 0, 0)
    val.BackgroundTransparency = 1
    val.Text = "—"
    val.TextColor3 = color or CONFIG.Colors.Cyan
    val.TextSize = 16
    val.Font = CONFIG.Font
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.ZIndex = 105
    val.Parent = card

    return card, val
end

local _, statPosVal   = MakeStatCard(StatsPanel, "📍 Posición",          "pos",    2,  CONFIG.Colors.Cyan)
local _, statSpdVal   = MakeStatCard(StatsPanel, "🏃 Velocidad (H)",     "spd",    3,  CONFIG.Colors.Green)
local _, statVSpdVal  = MakeStatCard(StatsPanel, "↕ Velocidad (V)",      "vspd",   4,  CONFIG.Colors.Yellow)
local _, statHpVal    = MakeStatCard(StatsPanel, "❤️ Salud",             "hp",     5,  CONFIG.Colors.Red)
local _, statWSVal    = MakeStatCard(StatsPanel, "👟 WalkSpeed",         "ws",     6,  CONFIG.Colors.Accent)
local _, statJPVal    = MakeStatCard(StatsPanel, "🦘 JumpPower",         "jp",     7,  CONFIG.Colors.AccentGlow)

-- Flags de features activas
local flagsCard = Instance.new("Frame")
flagsCard.Size = UDim2.new(1, 0, 0, 60)
flagsCard.BackgroundColor3 = CONFIG.Colors.Card
flagsCard.BackgroundTransparency = 0.2
flagsCard.ZIndex = 104
flagsCard.LayoutOrder = 8
flagsCard.Parent = StatsPanel
MakeCorner(flagsCard, 12)
MakeStroke(flagsCard, CONFIG.Colors.Border, 1)
MakePadding(flagsCard, 0, 0, 14, 14)

local flagsLayout = Instance.new("UIListLayout")
flagsLayout.FillDirection = Enum.FillDirection.Horizontal
flagsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
flagsLayout.Padding = UDim.new(0, 8)
flagsLayout.Parent = flagsCard
flagsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local function MakeFlag(parent, label)
    local f = Instance.new("TextLabel")
    f.Size = UDim2.new(0, 0, 0, 28)
    f.AutomaticSize = Enum.AutomaticSize.X
    f.BackgroundColor3 = CONFIG.Colors.RedDark
    f.BackgroundTransparency = 0.2
    f.Text = label
    f.TextColor3 = CONFIG.Colors.Text
    f.TextSize = 11
    f.Font = CONFIG.Font
    f.ZIndex = 105
    f.Parent = parent
    MakeCorner(f, 14)
    MakePadding(f, 2, 2, 8, 8)
    return f
end

local flyFlag     = MakeFlag(flagsCard, "🛸 FLY")
local infJFlag    = MakeFlag(flagsCard, "🦘 INF-J")
local ctpFlag     = MakeFlag(flagsCard, "🖱️ CTP")

-- Actualizar stats en tiempo real
task.spawn(function()
    while true do
        task.wait(CONFIG.StatsRefresh)
        pcall(function()
            if State.CurrentTab ~= "Stats" then return end

            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            if not hrp or not hum then
                statPosVal.Text   = "N/A"
                statSpdVal.Text   = "N/A"
                statVSpdVal.Text  = "N/A"
                statHpVal.Text    = "N/A"
                statWSVal.Text    = "N/A"
                statJPVal.Text    = "N/A"
                return
            end

            local vel   = hrp.Velocity
            local pos   = hrp.Position
            local hspd  = math.floor(math.sqrt(vel.X^2 + vel.Z^2))

            statPosVal.Text   = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
            statSpdVal.Text   = tostring(hspd) .. " s/u"
            statVSpdVal.Text  = string.format("%.1f s/u", vel.Y)
            statHpVal.Text    = string.format("%.0f / %.0f", hum.Health, hum.MaxHealth)
            statWSVal.Text    = string.format("%.0f", hum.WalkSpeed)
            statJPVal.Text    = string.format("%.0f", hum.JumpPower)

            -- Actualizar flags
            flyFlag.BackgroundColor3 = State.FlyEnabled and CONFIG.Colors.GreenDark or CONFIG.Colors.RedDark
            flyFlag.TextColor3       = State.FlyEnabled and CONFIG.Colors.Green     or CONFIG.Colors.Red
            infJFlag.BackgroundColor3 = State.InfJumpEnabled and CONFIG.Colors.GreenDark or CONFIG.Colors.RedDark
            infJFlag.TextColor3       = State.InfJumpEnabled and CONFIG.Colors.Green     or CONFIG.Colors.Red
            ctpFlag.BackgroundColor3  = State.ClickTPEnabled and CONFIG.Colors.GreenDark or CONFIG.Colors.RedDark
            ctpFlag.TextColor3        = State.ClickTPEnabled and CONFIG.Colors.Green     or CONFIG.Colors.Red
        end)
    end
end)

-- ============================================================
--  PANEL: CONFIG
-- ============================================================
local ConfigPanel = Instance.new("ScrollingFrame")
ConfigPanel.Size            = UDim2.new(1, 0, 1, 0)
ConfigPanel.BackgroundTransparency = 1
ConfigPanel.ScrollBarThickness = 3
ConfigPanel.ScrollBarImageColor3 = CONFIG.Colors.Accent
ConfigPanel.CanvasSize      = UDim2.new(0, 0, 0, 0)
ConfigPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
ConfigPanel.ZIndex          = 103
ConfigPanel.Visible         = false
ConfigPanel.Parent          = PanelContainer

local CfgLayout = Instance.new("UIListLayout")
CfgLayout.FillDirection     = Enum.FillDirection.Vertical
CfgLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
CfgLayout.Padding           = UDim.new(0, 10)
CfgLayout.Parent            = ConfigPanel
MakePadding(ConfigPanel, 12, 12, 0, 0)

local CfgTitle = Instance.new("TextLabel")
CfgTitle.Size              = UDim2.new(1, 0, 0, 26)
CfgTitle.BackgroundTransparency = 1
CfgTitle.Text              = "⚙️ Configuración"
CfgTitle.TextColor3        = CONFIG.Colors.White
CfgTitle.TextSize          = 16
CfgTitle.Font              = CONFIG.Font
CfgTitle.LayoutOrder       = 1
CfgTitle.Parent            = ConfigPanel

-- System Prompt
local SysLabel = Instance.new("TextLabel")
SysLabel.Size = UDim2.new(1, 0, 0, 20)
SysLabel.BackgroundTransparency = 1
SysLabel.Text = "System Prompt personalizado:"
SysLabel.TextColor3 = CONFIG.Colors.TextMuted
SysLabel.TextSize = 12
SysLabel.Font = CONFIG.FontReg
SysLabel.TextXAlignment = Enum.TextXAlignment.Left
SysLabel.ZIndex = 104
SysLabel.LayoutOrder = 2
SysLabel.Parent = ConfigPanel

local SysPromptInput = Instance.new("TextBox")
SysPromptInput.Size = UDim2.new(1, 0, 0, 90)
SysPromptInput.BackgroundColor3 = CONFIG.Colors.Card
SysPromptInput.BackgroundTransparency = 0.1
SysPromptInput.Text = ""
SysPromptInput.PlaceholderText = "Deja vacío para usar los prompts predefinidos..."
SysPromptInput.TextColor3 = CONFIG.Colors.Text
SysPromptInput.PlaceholderColor3 = CONFIG.Colors.TextMuted
SysPromptInput.TextSize = 12
SysPromptInput.Font = CONFIG.FontReg
SysPromptInput.MultiLine = true
SysPromptInput.ClearTextOnFocus = false
SysPromptInput.ZIndex = 104
SysPromptInput.LayoutOrder = 3
SysPromptInput.Parent = ConfigPanel
MakeCorner(SysPromptInput, 12)
MakeStroke(SysPromptInput, CONFIG.Colors.Border, 1)
MakePadding(SysPromptInput, 8, 8, 10, 10)

local SaveSysBtn = Instance.new("TextButton")
SaveSysBtn.Size = UDim2.new(1, 0, 0, 42)
SaveSysBtn.BackgroundColor3 = CONFIG.Colors.Accent
SaveSysBtn.Text = "💾 Guardar System Prompt"
SaveSysBtn.TextColor3 = CONFIG.Colors.White
SaveSysBtn.TextSize = 13
SaveSysBtn.Font = CONFIG.Font
SaveSysBtn.ZIndex = 104
SaveSysBtn.LayoutOrder = 4
SaveSysBtn.Parent = ConfigPanel
MakeCorner(SaveSysBtn, 12)
MakeGradient(SaveSysBtn,
    Color3.fromRGB(120, 80, 240),
    Color3.fromRGB(75, 50, 190),
    135
)

-- Temperatura
local TempLabel = Instance.new("TextLabel")
TempLabel.Size = UDim2.new(1, 0, 0, 20)
TempLabel.BackgroundTransparency = 1
TempLabel.Text = "Temperatura IA: 0.72"
TempLabel.TextColor3 = CONFIG.Colors.TextMuted
TempLabel.TextSize = 12
TempLabel.Font = CONFIG.FontReg
TempLabel.TextXAlignment = Enum.TextXAlignment.Left
TempLabel.ZIndex = 104
TempLabel.LayoutOrder = 5
TempLabel.Parent = ConfigPanel

local TempSliderBG = Instance.new("Frame")
TempSliderBG.Size = UDim2.new(1, 0, 0, 10)
TempSliderBG.BackgroundColor3 = CONFIG.Colors.Border
TempSliderBG.ZIndex = 104
TempSliderBG.LayoutOrder = 6
TempSliderBG.Parent = ConfigPanel
MakeCorner(TempSliderBG, 5)

local TempSliderFill = Instance.new("Frame")
TempSliderFill.Size = UDim2.new(0.72, 0, 1, 0)
TempSliderFill.BackgroundColor3 = CONFIG.Colors.Accent
TempSliderFill.ZIndex = 105
TempSliderFill.Parent = TempSliderBG
MakeCorner(TempSliderFill, 5)

-- Botón reset key
local ResetKeyBtn = Instance.new("TextButton")
ResetKeyBtn.Size = UDim2.new(1, 0, 0, 42)
ResetKeyBtn.BackgroundColor3 = CONFIG.Colors.Red
ResetKeyBtn.BackgroundTransparency = 0.3
ResetKeyBtn.Text = "🔒 Resetear API Key"
ResetKeyBtn.TextColor3 = CONFIG.Colors.White
ResetKeyBtn.TextSize = 13
ResetKeyBtn.Font = CONFIG.Font
ResetKeyBtn.ZIndex = 104
ResetKeyBtn.LayoutOrder = 7
ResetKeyBtn.Parent = ConfigPanel
MakeCorner(ResetKeyBtn, 12)

local InfoCard = Instance.new("Frame")
InfoCard.Size = UDim2.new(1, 0, 0, 80)
InfoCard.BackgroundColor3 = CONFIG.Colors.Card
InfoCard.BackgroundTransparency = 0.3
InfoCard.ZIndex = 104
InfoCard.LayoutOrder = 8
InfoCard.Parent = ConfigPanel
MakeCorner(InfoCard, 12)
MakeStroke(InfoCard, CONFIG.Colors.Border, 1)
MakePadding(InfoCard, 10, 10, 12, 12)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 1, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Kaelen v2.3  ·  Kaelen Systems\n" ..
                 "Modelos: Qwen3-Coder + Llama 3.3 70B + Gemma 3 27B\n" ..
                 "Via: OpenRouter API  |  Modo: " .. State.CurrentMode
InfoLabel.TextColor3 = CONFIG.Colors.TextMuted
InfoLabel.TextSize = 11
InfoLabel.Font = CONFIG.FontReg
InfoLabel.TextWrapped = true
InfoLabel.ZIndex = 105
InfoLabel.Parent = InfoCard

-- ============================================================
--  FUNCIÓN: AGREGAR MENSAJE AL CHAT
-- ============================================================
local function AddMessage(role, content)
    table.insert(State.Messages, {role = role, content = content})
    if #State.Messages > CONFIG.MaxHistory then
        table.remove(State.Messages, 1)
    end

    local isUser = (role == "user")
    local isAction = (role == "action")

    local bubble = Instance.new("Frame")
    bubble.Size = UDim2.new(isAction and 1 or 0.84, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.BackgroundColor3 = isUser   and CONFIG.Colors.UserBubble
                           or isAction and CONFIG.Colors.GreenDark
                           or CONFIG.Colors.AIBubble
    bubble.BackgroundTransparency = 0.08
    bubble.ZIndex = 105
    bubble.LayoutOrder = #State.Messages
    bubble.Parent = MsgScroll
    if isUser then
        bubble.Position = UDim2.new(0.16, 0, 0, 0)
    end
    MakeCorner(bubble, 16)
    if not isUser then
        MakeStroke(bubble, isAction and CONFIG.Colors.Green or CONFIG.Colors.Border, 1)
    end
    MakePadding(bubble, 8, 8, 12, 12)

    local bubLayout = Instance.new("UIListLayout")
    bubLayout.FillDirection = Enum.FillDirection.Vertical
    bubLayout.Padding = UDim.new(0, 4)
    bubLayout.HorizontalAlignment = isUser and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    bubLayout.Parent = bubble

    local authorLabel = Instance.new("TextLabel")
    authorLabel.Size = UDim2.new(1, 0, 0, 14)
    authorLabel.BackgroundTransparency = 1
    authorLabel.Text = isUser   and ("🧑 " .. LocalPlayer.Name)
                    or isAction and "⚙️ Sistema"
                    or "⬡ Kaelen"
    authorLabel.TextColor3 = isUser   and Color3.fromRGB(190, 155, 255)
                          or isAction and CONFIG.Colors.Green
                          or CONFIG.Colors.AccentGlow
    authorLabel.TextSize = 10
    authorLabel.Font = CONFIG.Font
    authorLabel.TextXAlignment = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    authorLabel.ZIndex = 106
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
    msgLabel.ZIndex = 106
    msgLabel.LayoutOrder = 2
    msgLabel.Parent = bubble

    -- Botón copiar (solo IA)
    if not isUser and not isAction then
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 76, 0, 22)
        copyBtn.BackgroundColor3 = CONFIG.Colors.Card
        copyBtn.BackgroundTransparency = 0.2
        copyBtn.Text = "📋 Copiar"
        copyBtn.TextColor3 = CONFIG.Colors.TextMuted
        copyBtn.TextSize = 10
        copyBtn.Font = CONFIG.FontReg
        copyBtn.ZIndex = 106
        copyBtn.LayoutOrder = 3
        copyBtn.Parent = bubble
        MakeCorner(copyBtn, 7)
        copyBtn.MouseButton1Click:Connect(function()
            pcall(function() setclipboard(content) end)
            copyBtn.Text = "✅ Copiado"
            task.delay(2, function() copyBtn.Text = "📋 Copiar" end)
        end)
    end

    -- Scroll al fondo
    task.delay(0.06, function()
        MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y)
    end)

    -- Animación entrada
    bubble.BackgroundTransparency = 1
    Tween(bubble, {BackgroundTransparency = isUser and 0.08 or (isAction and 0.15 or 0.08)}, 0.28)
end

-- ============================================================
--  THINKING INDICATOR
-- ============================================================
local thinkCoroutine = nil

local function ShowThinking(show)
    State.IsThinking = show
    ThinkFrame.Visible = show
    if show then
        ThinkFrame.LayoutOrder = #State.Messages + 9999
        if thinkCoroutine then task.cancel(thinkCoroutine) end
        thinkCoroutine = task.spawn(function()
            local dots = {"⬡ Kaelen pensando ●○○", "⬡ Kaelen pensando ●●○", "⬡ Kaelen pensando ●●●",
                          "⬡ Kaelen pensando ○●●", "⬡ Kaelen pensando ○○●", "⬡ Kaelen pensando ○○○"}
            local i = 1
            while State.IsThinking do
                ThinkLabel.Text = dots[i]
                i = (i % #dots) + 1
                task.wait(0.28)
            end
        end)
        task.delay(0.05, function()
            MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y)
        end)
    else
        if thinkCoroutine then task.cancel(thinkCoroutine) end
        thinkCoroutine = nil
    end
end

-- ============================================================
--  ENVIAR MENSAJE (con detección de acciones IA)
-- ============================================================
local function SendMessage()
    if State.IsThinking then return end
    local text = ChatInput.Text
    if not text or text:gsub("%s", "") == "" then return end
    ChatInput.Text = ""

    AddMessage("user", text)
    ShowThinking(true)

    task.spawn(function()
        local response, err = OrchestrateKaelen(text, State.Messages)
        ShowThinking(false)

        if err then
            AddMessage("assistant", "⚠️ **Error:** " .. tostring(err) ..
                "\n\nVerifica tu API Key en ⚙️ Configuración.")
            return
        end

        local resp = response or "Sin respuesta del servidor."

        -- Intentar detectar y ejecutar acciones IA
        local actionParts = ParseAIAction(resp)
        if actionParts then
            local actionResult = ExecuteAIAction(actionParts)
            -- Mostrar respuesta de IA SIN la línea ACTION:
            local cleanResp = resp:gsub("ACTION:[^\n]*\n?", "")
            cleanResp = cleanResp:gsub("^%s+", ""):gsub("%s+$", "")
            if cleanResp ~= "" then
                AddMessage("assistant", cleanResp)
            end
            if actionResult then
                AddMessage("action", actionResult)
            end
        else
            AddMessage("assistant", resp)
        end
    end)
end

-- ============================================================
--  BOTONES RÁPIDOS CHAT
-- ============================================================
local function HandleQuickCmd(cmd)
    if cmd == "ANALYZE" then
        local ctx = GetGameContext()
        ChatInput.Text = "🎮 Analiza este juego en profundidad:\n\n" .. ctx .. "\n\nDame un análisis completo: mecánicas, puntos fuertes, débiles y recomendaciones de mejora."
        SendMessage()
    elseif cmd == "BUGS" then
        local ctx = GetGameContext()
        ChatInput.Text = "🔍 Analiza posibles bugs y vulnerabilidades:\n\n" .. ctx .. "\n\nComo desarrollador necesito saber qué puntos débiles tiene mi juego para reforzarlos."
        SendMessage()
    elseif cmd == "SCRIPT" then
        ChatInput.Text = "💻 Necesito un script Lua para Roblox que "
        -- No enviar, dejar que el usuario complete
    elseif cmd == "EXPORT" then
        local export = "=== Kaelen AI v2.3 - Chat Exportado ===\n"
        export = export .. os.date() .. " | Modo: " .. State.CurrentMode .. "\n\n"
        for _, m in ipairs(State.Messages) do
            if m.role == "user" then
                export = export .. "[TÚ]: " .. m.content .. "\n\n"
            elseif m.role == "assistant" then
                export = export .. "[KAELEN]: " .. m.content .. "\n\n"
            end
        end
        pcall(function() setclipboard(export) end)
        AddMessage("action", "✅ Conversación copiada al portapapeles (" .. #State.Messages .. " mensajes)")
    elseif cmd == "CLEAR" then
        for _, child in ipairs(MsgScroll:GetChildren()) do
            if child:IsA("Frame") and child ~= ThinkFrame then
                child:Destroy()
            end
        end
        State.Messages = {}
        AddMessage("assistant", "🗑️ Historial limpiado.\n\n¿En qué te puedo ayudar?")
    end
end

for _, child in ipairs(QuickBtnFrame:GetChildren()) do
    if child:IsA("TextButton") then
        local cmdName = ""
        for _, qc in ipairs(QuickCmds) do
            if child.Text == qc.label then cmdName = qc.cmd break end
        end
        child.MouseButton1Click:Connect(function()
            if cmdName ~= "" then HandleQuickCmd(cmdName) end
        end)
        -- Hover effect
        child.MouseEnter:Connect(function()
            Tween(child, {BackgroundTransparency = 0.1, TextColor3 = CONFIG.Colors.Text}, 0.15)
        end)
        child.MouseLeave:Connect(function()
            Tween(child, {BackgroundTransparency = 0.3, TextColor3 = CONFIG.Colors.TextMuted}, 0.15)
        end)
    end
end

SendBtn.MouseButton1Click:Connect(SendMessage)
ChatInput.FocusLost:Connect(function(enter)
    if enter then SendMessage() end
end)

-- ============================================================
--  TOOL TOGGLES LÓGICA
-- ============================================================
local function UpdateToggle(btn, enabled)
    btn.Text = enabled and "ON" or "OFF"
    Tween(btn, {
        BackgroundColor3 = enabled and CONFIG.Colors.GreenDark or CONFIG.Colors.RedDark,
    }, 0.2)
    MakeStroke(btn, enabled and CONFIG.Colors.Green or CONFIG.Colors.Red, 1)
    btn.TextColor3 = enabled and CONFIG.Colors.Green or CONFIG.Colors.Red
end

flyToggle.MouseButton1Click:Connect(function()
    if State.FlyEnabled then
        FlyModule.Stop()
    else
        local ok = FlyModule.Start()
        if not ok then
            AddMessage("action", "❌ No se pudo activar el vuelo. ¿Tienes personaje?")
            return
        end
    end
    UpdateToggle(flyToggle, State.FlyEnabled)
end)

infToggle.MouseButton1Click:Connect(function()
    if State.InfJumpEnabled then
        InfJumpModule.Stop()
    else
        InfJumpModule.Start()
    end
    UpdateToggle(infToggle, State.InfJumpEnabled)
end)

ctpToggle.MouseButton1Click:Connect(function()
    if State.ClickTPEnabled then
        ClickTPModule.Stop()
    else
        ClickTPModule.Start()
    end
    UpdateToggle(ctpToggle, State.ClickTPEnabled)
end)

-- Slider vuelo (drag simplificado)
local flySliderDrag = false
flySlider.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        flySliderDrag = true
    end
end)
flySlider.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        flySliderDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if flySliderDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = math.clamp((inp.Position.X - flySlider.AbsolutePosition.X) / flySlider.AbsoluteSize.X, 0, 1)
        flySliderFill.Size = UDim2.new(rel, 0, 1, 0)
        local speed = math.floor(10 + rel * 490)  -- 10..500
        State.FlySpeed = speed
        flySpeedLbl.Text = "🚀 Velocidad Vuelo: " .. speed
    end
end)

-- ============================================================
--  VERIFICACIÓN API KEY
-- ============================================================
VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyInput.Text:gsub("%s", "")
    if key == "" then
        KeyStatusLabel.TextColor3 = CONFIG.Colors.Red
        KeyStatusLabel.Text = "⚠️ Introduce tu API Key primero"
        return
    end
    VerifyBtn.Text = "Verificando..."
    Tween(VerifyBtn, {BackgroundColor3 = CONFIG.Colors.AccentSoft}, 0.2)
    KeyStatusLabel.Text = ""

    task.spawn(function()
        local ok, err = VerifyAPIKey(key)
        if ok then
            State.APIKey     = key
            State.KeyVerified = true
            KeyStatusLabel.TextColor3 = CONFIG.Colors.Green
            KeyStatusLabel.Text = "✅ API Key válida · Kaelen activado"
            Tween(StatusDot, {BackgroundColor3 = CONFIG.Colors.Green}, 0.5)
            task.wait(0.7)
            KeyPanel.Visible = false
            SetActiveTab("Chat")
            ChatPanel.Visible = true
            AddMessage("assistant",
                "⬡ Hola, soy **Kaelen v2.3**.\n\n" ..
                "Estoy completamente operativo. Combino **Qwen3-Coder**, **Llama 3.3 70B** y **Gemma 3 27B** " ..
                "para darte la mejor asistencia en tu juego.\n\n" ..
                "🎮 **Lo que puedo hacer:**\n" ..
                "• Analizar tu juego y detectar bugs/vulnerabilidades\n" ..
                "• Crear y optimizar scripts Lua completos\n" ..
                "• **Controlar tu personaje por voz** (dime: *modifica mi velocidad a 200*, *activa vuelo*, *teletranspórtame a X,Y,Z*...)\n" ..
                "• Panel de stats en tiempo real · Checkpoints · Fly · ClickTP\n\n" ..
                "¿Por dónde empezamos? 🚀"
            )
        else
            State.KeyVerified = false
            KeyStatusLabel.TextColor3 = CONFIG.Colors.Red
            KeyStatusLabel.Text = "❌ Key inválida: " .. (err or "error desconocido")
            VerifyBtn.Text = "Verificar y Activar"
            Tween(VerifyBtn, {BackgroundColor3 = CONFIG.Colors.Accent}, 0.3)
        end
    end)
end)

-- ============================================================
--  CONFIG HANDLERS
-- ============================================================
SaveSysBtn.MouseButton1Click:Connect(function()
    State.CustomSysPrompt = SysPromptInput.Text
    SaveSysBtn.Text = "✅ Guardado"
    Tween(SaveSysBtn, {BackgroundColor3 = CONFIG.Colors.Green}, 0.2)
    task.delay(2, function()
        SaveSysBtn.Text = "💾 Guardar System Prompt"
        Tween(SaveSysBtn, {BackgroundColor3 = CONFIG.Colors.Accent}, 0.3)
    end)
end)

ResetKeyBtn.MouseButton1Click:Connect(function()
    State.APIKey      = ""
    State.KeyVerified = false
    State.Messages    = {}
    Tween(StatusDot, {BackgroundColor3 = CONFIG.Colors.Red}, 0.3)
    -- Limpiar mensajes
    for _, c in ipairs(MsgScroll:GetChildren()) do
        if c:IsA("Frame") and c ~= ThinkFrame then c:Destroy() end
    end
    -- Desactivar features
    FlyModule.Stop()
    InfJumpModule.Stop()
    ClickTPModule.Stop()
    -- Volver a key panel
    for _, p in ipairs({ChatPanel, ModesPanel, ToolsPanel, StatsPanel, ConfigPanel}) do
        p.Visible = false
    end
    KeyPanel.Visible = true
    KeyInput.Text = ""
    KeyStatusLabel.Text = ""
    VerifyBtn.Text = "Verificar y Activar"
    Tween(VerifyBtn, {BackgroundColor3 = CONFIG.Colors.Accent}, 0.3)
    SetActiveTab("Chat")
end)

-- ============================================================
--  LÓGICA DE TABS → mostrar/ocultar paneles
-- ============================================================
local PanelMap = {
    Chat   = ChatPanel,
    Modos  = ModesPanel,
    Tools  = ToolsPanel,
    Stats  = StatsPanel,
    Config = ConfigPanel,
}

local function ShowPanel(tabName)
    if not State.KeyVerified and tabName ~= "Chat" then return end
    for name, panel in pairs(PanelMap) do
        panel.Visible = (name == tabName)
    end
    SetActiveTab(tabName)
    -- Actualizar checkpoints si abrimos Tools
    if tabName == "Tools" then
        RefreshCPList()
    end
end

for _, info in pairs(TabButtons) do
    info.btn.MouseButton1Click:Connect(function()
        ShowPanel(info.name)
    end)
end

-- ============================================================
--  ABRIR / CERRAR VENTANA
-- ============================================================
local isMinimized = false

local function OpenWindow()
    State.IsOpen = true
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.Position = UDim2.new(
        FloatBtn.Position.X.Scale,
        FloatBtn.Position.X.Offset + 30,
        FloatBtn.Position.Y.Scale,
        FloatBtn.Position.Y.Offset + 30
    )
    Tween(MainFrame, {
        Size     = UDim2.new(0, 420, 0, 640),
        Position = UDim2.new(0.5, -210, 0.5, -320),
    }, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function CloseWindow()
    State.IsOpen = false
    Tween(MainFrame, {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(
            FloatBtn.Position.X.Scale,
            FloatBtn.Position.X.Offset + 30,
            FloatBtn.Position.Y.Scale,
            FloatBtn.Position.Y.Offset + 30
        ),
    }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.26, function() MainFrame.Visible = false end)
end

local function ToggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        Tween(MainFrame, {Size = UDim2.new(0, 420, 0, 62)}, 0.3, Enum.EasingStyle.Quart)
        MinBtn.Text = "□"
    else
        Tween(MainFrame, {Size = UDim2.new(0, 420, 0, 640)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        MinBtn.Text = "─"
    end
end

FloatBtn.MouseButton1Click:Connect(function()
    if not btnDragging then
        if State.IsOpen then CloseWindow() else OpenWindow() end
    end
end)

CloseBtn.MouseButton1Click:Connect(CloseWindow)
MinBtn.MouseButton1Click:Connect(ToggleMinimize)

-- Hover effects en botones de cerrar/minimizar
CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, {BackgroundTransparency = 0}, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, {BackgroundTransparency = 0.2}, 0.15)
end)
MinBtn.MouseEnter:Connect(function()
    Tween(MinBtn, {BackgroundTransparency = 0}, 0.15)
end)
MinBtn.MouseLeave:Connect(function()
    Tween(MinBtn, {BackgroundTransparency = 0.3}, 0.15)
end)

-- ============================================================
--  HOVER EN BOTONES DEL TAB BAR
-- ============================================================
for _, info in pairs(TabButtons) do
    info.btn.MouseEnter:Connect(function()
        if State.CurrentTab ~= info.name then
            Tween(info.btn, {BackgroundTransparency = 0.4}, 0.12)
        end
    end)
    info.btn.MouseLeave:Connect(function()
        if State.CurrentTab ~= info.name then
            Tween(info.btn, {BackgroundTransparency = 0.6}, 0.12)
        end
    end)
end

-- ============================================================
--  HOVER EN BOTÓN FLOTANTE
-- ============================================================
FloatBtn.MouseEnter:Connect(function()
    Tween(FloatBtn, {BackgroundColor3 = CONFIG.Colors.AccentGlow}, 0.2)
    Tween(BtnIcon, {TextSize = 26}, 0.2, Enum.EasingStyle.Back)
end)
FloatBtn.MouseLeave:Connect(function()
    Tween(FloatBtn, {BackgroundColor3 = CONFIG.Colors.Accent}, 0.2)
    Tween(BtnIcon, {TextSize = 24}, 0.2)
end)

-- ============================================================
--  INICIALIZACIÓN
-- ============================================================
SetActiveTab("Chat")

if not State.KeyVerified then
    KeyPanel.Visible   = true
    ChatPanel.Visible  = false
    ModesPanel.Visible = false
    ToolsPanel.Visible = false
    StatsPanel.Visible = false
    ConfigPanel.Visible = false
end

print("╔════════════════════════════════╗")
print("║   Kaelen v2.3  ·  AI Systems  ║")
print("║   Toca [K] para abrir          ║")
print("╚════════════════════════════════╝")
print("[ Kaelen ] Modelos activos:")
print("  → Coder:   " .. CONFIG.Models.Coder)
print("  → Razonamiento: " .. CONFIG.Models.Reason)
print("  → Rápido:  " .. CONFIG.Models.Fast)
print("[ Kaelen ] Features: Fly · InfJump · ClickTP · Checkpoints · Stats · Headsit · AI CharControl")
