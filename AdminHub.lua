-- ============================================================
-- Kaelen
-- Super AI Orquestador para Desarrollo y Testing de Juegos Roblox
-- Modelos: Qwen3 Coder + Llama 3.3 70B via OpenRouter
-- Versión: 2.0 Premium | Optimizado para Móvil y PC
-- ============================================================
-- INSTRUCCIONES DE USO:
-- 1. Inserta este script como LocalScript dentro de StarterPlayerScripts
-- 2. Reemplaza "TU_API_KEY_AQUI" con tu API Key de OpenRouter
-- 3. ¡Ejecuta tu juego y presiona el botón flotante de Kaelen!
-- ============================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- CONFIGURACIÓN PRINCIPAL - EDITA AQUÍ TU API KEY
-- ============================================================
local CONFIG = {
    OPENROUTER_API_KEY = "TU_API_KEY_AQUI", -- Pon tu API Key de OpenRouter aquí
    MODEL_CODER    = "qwen/qwen3-coder:free",           -- Especialista en Lua/Scripts
    MODEL_ANALYST  = "meta-llama/llama-3.3-70b-instruct:free", -- Especialista en análisis
    MAX_TOKENS     = 1500,
    TIMEOUT        = 30,
    VERSION        = "2.0",
    AUTHOR         = "Kaelen AI System",
}

-- ============================================================
-- SISTEMA DE TEMAS (COLORES)
-- ============================================================
local THEMES = {
    Dark = {
        BG_PRIMARY    = Color3.fromRGB(12, 12, 18),
        BG_SECONDARY  = Color3.fromRGB(20, 20, 30),
        BG_CARD       = Color3.fromRGB(28, 28, 42),
        BG_INPUT      = Color3.fromRGB(22, 22, 35),
        ACCENT        = Color3.fromRGB(99, 102, 241),   -- Indigo
        ACCENT_GLOW   = Color3.fromRGB(139, 92, 246),   -- Violet
        TEXT_PRIMARY  = Color3.fromRGB(240, 240, 255),
        TEXT_SECONDARY= Color3.fromRGB(140, 140, 180),
        TEXT_MUTED    = Color3.fromRGB(80, 80, 110),
        BUBBLE_USER   = Color3.fromRGB(79, 70, 229),
        BUBBLE_AI     = Color3.fromRGB(32, 32, 52),
        BORDER        = Color3.fromRGB(50, 50, 80),
        SUCCESS       = Color3.fromRGB(52, 211, 153),
        WARNING       = Color3.fromRGB(251, 191, 36),
        ERROR         = Color3.fromRGB(239, 68, 68),
        CODE_BG       = Color3.fromRGB(15, 15, 25),
    },
    Light = {
        BG_PRIMARY    = Color3.fromRGB(245, 245, 255),
        BG_SECONDARY  = Color3.fromRGB(235, 235, 250),
        BG_CARD       = Color3.fromRGB(255, 255, 255),
        BG_INPUT      = Color3.fromRGB(240, 240, 252),
        ACCENT        = Color3.fromRGB(79, 70, 229),
        ACCENT_GLOW   = Color3.fromRGB(109, 40, 217),
        TEXT_PRIMARY  = Color3.fromRGB(15, 15, 35),
        TEXT_SECONDARY= Color3.fromRGB(80, 80, 120),
        TEXT_MUTED    = Color3.fromRGB(150, 150, 190),
        BUBBLE_USER   = Color3.fromRGB(79, 70, 229),
        BUBBLE_AI     = Color3.fromRGB(230, 230, 245),
        BORDER        = Color3.fromRGB(200, 200, 225),
        SUCCESS       = Color3.fromRGB(16, 185, 129),
        WARNING       = Color3.fromRGB(217, 119, 6),
        ERROR         = Color3.fromRGB(220, 38, 38),
        CODE_BG       = Color3.fromRGB(220, 220, 240),
    }
}

-- Accent Colors disponibles
local ACCENT_COLORS = {
    Indigo  = { main = Color3.fromRGB(99,102,241),  glow = Color3.fromRGB(139,92,246)  },
    Cyan    = { main = Color3.fromRGB(6,182,212),   glow = Color3.fromRGB(34,211,238)  },
    Rose    = { main = Color3.fromRGB(244,63,94),   glow = Color3.fromRGB(251,113,133) },
    Emerald = { main = Color3.fromRGB(16,185,129),  glow = Color3.fromRGB(52,211,153)  },
    Amber   = { main = Color3.fromRGB(245,158,11),  glow = Color3.fromRGB(251,191,36)  },
}

-- ============================================================
-- ESTADO GLOBAL DE KAELEN
-- ============================================================
local State = {
    isOpen        = false,
    isDragging    = false,
    currentTheme  = "Dark",
    currentAccent = "Indigo",
    currentMode   = "Analista",   -- Programador | Analista | Creativo | Debug
    messages      = {},           -- Historial de conversación
    isThinking    = false,
    customSysPrompt = "",
    activeTab     = "Chat",       -- Chat | Modos | Config
    theme         = THEMES.Dark,
    accent        = ACCENT_COLORS.Indigo,
    dragStartPos  = Vector2.new(0, 0),
    btnStartPos   = UDim2.new(0, 0, 0, 0),
    inputText     = "",
    scrollPos     = 0,
    messageCount  = 0,
}

-- ============================================================
-- PROMPTS DEL SISTEMA POR MODO
-- ============================================================
local MODE_PROMPTS = {
    Programador = [[Eres Kaelen, un experto en programación Lua para Roblox con 15+ años de experiencia.
Tu especialidad es crear, optimizar y debugear scripts de Roblox. 
Cuando generes código:
- Siempre incluye comentarios explicativos en español
- Usa buenas prácticas de Roblox (LocalScript vs Script, RemoteEvents, etc.)
- Indica si el código va en LocalScript, Script o ModuleScript
- Detecta y explica errores comunes
- Optimiza para rendimiento móvil y PC
Responde siempre en español. Sé preciso, técnico y detallado.]],

    Analista = [[Eres Kaelen, un analista experto en juegos de Roblox y sistemas de gameplay.
Tu especialidad es analizar mecánicas de juego, identificar bugs, y sugerir mejoras.
Cuando analices un juego o sistema:
- Identifica problemas de balance y gameplay
- Sugiere optimizaciones y mejoras concretas
- Explica el impacto de cada cambio
- Piensa en la experiencia del jugador
- Considera rendimiento en dispositivos móviles
Responde siempre en español. Sé analítico, creativo y orientado a soluciones.]],

    Creativo = [[Eres Kaelen, un diseñador creativo de experiencias en Roblox.
Tu especialidad es generar ideas innovadoras, mecánicas únicas y contenido creativo.
Cuando ayudes con ideas:
- Genera conceptos originales y detallados
- Explica cómo implementar cada idea técnicamente
- Considera la diversión y engagement del jugador
- Sugiere variaciones y expansiones de ideas
- Piensa en tendencias actuales de juegos Roblox
Responde siempre en español. Sé inspirador, detallado y lleno de ideas.]],

    Debug = [[Eres Kaelen, un experto en debugging y testing de juegos Roblox.
Tu especialidad es encontrar y solucionar bugs, optimizar rendimiento y testear sistemas.
Cuando hagas debugging:
- Identifica la causa raíz del problema
- Proporciona soluciones paso a paso
- Explica por qué ocurrió el error
- Sugiere cómo prevenir errores similares
- Incluye código corregido y testeable
- Menciona casos edge que podrían causar problemas
Responde siempre en español. Sé metódico, preciso y exhaustivo.]],
}

-- ============================================================
-- UTILIDADES
-- ============================================================
local Utils = {}

function Utils.getGameContext()
    local gameName = "Desconocido"
    local placeId  = game.PlaceId
    local jobId    = game.JobId

    -- Intentar obtener nombre del juego
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(placeId).Name
    end)

    local playerCount = #Players:GetPlayers()
    local character   = player.Character
    local charPos     = "N/A"
    if character and character:FindFirstChild("HumanoidRootPart") then
        local pos = character.HumanoidRootPart.Position
        charPos   = string.format("(%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z)
    end

    -- Obtener scripts en el workspace (para contexto de desarrollo)
    local scriptCount = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            scriptCount = scriptCount + 1
        end
    end

    return string.format(
        "[CONTEXTO DEL JUEGO]\nNombre: %s\nPlace ID: %s\nJob ID: %s\nJugadores: %d\nPosición: %s\nScripts en Workspace: %d\nPing: %d ms",
        gameName, tostring(placeId), tostring(jobId):sub(1,8).."...",
        playerCount, charPos, scriptCount,
        math.floor(player:GetNetworkPing() * 1000)
    )
end

function Utils.truncateHistory(messages, maxMessages)
    -- Mantener máximo N mensajes para no exceder tokens
    maxMessages = maxMessages or 12
    if #messages > maxMessages then
        local newMessages = {}
        for i = #messages - maxMessages + 1, #messages do
            table.insert(newMessages, messages[i])
        end
        return newMessages
    end
    return messages
end

function Utils.createTween(obj, props, duration, style, direction)
    style     = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    return TweenService:Create(obj, info, props)
end

function Utils.copyToClipboard(text)
    -- En Roblox no hay clipboard nativo, mostramos notificación
    StarterGui:SetCore("SendNotification", {
        Title   = "Kaelen",
        Text    = "Código copiado (usa Ctrl+C en Output)",
        Duration = 3,
    })
    print("[KAELEN - CÓDIGO COPIADO]\n" .. text)
end

function Utils.formatCode(text)
    -- Detectar bloques de código y formatearlos
    return text:gsub("```lua(.-)```", function(code)
        return "\n[CÓDIGO LUA]\n" .. code:match("^%s*(.-)%s*$") .. "\n[/CÓDIGO]"
    end):gsub("```(.-)```", function(code)
        return "\n[CÓDIGO]\n" .. code:match("^%s*(.-)%s*$") .. "\n[/CÓDIGO]"
    end)
end

-- ============================================================
-- SISTEMA DE ORQUESTACIÓN DE IA
-- ============================================================
local KaelenAI = {}

-- Determinar qué modelo usar según el tipo de petición
function KaelenAI.selectModel(userMessage, mode)
    local msg = userMessage:lower()

    -- Palabras clave que indican necesidad de código
    local codeKeywords = {
        "script", "código", "code", "lua", "función", "function",
        "loop", "while", "for", "if", "then", "local", "variable",
        "bug", "error", "fix", "arregla", "optimiza", "crea el script",
        "haz un script", "módulo", "remotevent", "bindableevent",
        "tween", "gui", "frame", "textlabel", "part", "workspace",
        "datastore", "remoteevent", "remotefunciton", "service",
        "pcall", "spawn", "coroutine", "table", "string", "math",
        "executor", "farm", "auto", "hack", "exploit", "admin"
    }

    -- Palabras clave que indican análisis/creatividad
    local analysisKeywords = {
        "analiza", "análisis", "qué piensas", "mejora", "sugerencia",
        "idea", "mecánica", "gameplay", "balance", "jugador", "experiencia",
        "qué debería", "cómo puedo", "explica", "describe", "por qué",
        "estrategia", "diseño", "concepto", "crea", "genera ideas"
    }

    local codeScore    = 0
    local analysisScore = 0

    for _, keyword in ipairs(codeKeywords) do
        if msg:find(keyword) then codeScore = codeScore + 1 end
    end
    for _, keyword in ipairs(analysisKeywords) do
        if msg:find(keyword) then analysisScore = analysisScore + 1 end
    end

    -- Por modo siempre usar el más adecuado
    if mode == "Programador" or mode == "Debug" then
        return CONFIG.MODEL_CODER, "coder"
    elseif mode == "Analista" or mode == "Creativo" then
        return CONFIG.MODEL_ANALYST, "analyst"
    end

    -- Auto-selección por contenido
    if codeScore > analysisScore then
        return CONFIG.MODEL_CODER, "coder"
    else
        return CONFIG.MODEL_ANALYST, "analyst"
    end
end

-- Llamada a la API de OpenRouter
function KaelenAI.callAPI(model, messages, systemPrompt)
    local headers = {
        ["Content-Type"]    = "application/json",
        ["Authorization"]   = "Bearer " .. CONFIG.OPENROUTER_API_KEY,
        ["HTTP-Referer"]    = "https://roblox.com",
        ["X-Title"]         = "Kaelen-Roblox-AI",
    }

    -- Construir mensajes con system prompt
    local apiMessages = {
        { role = "system", content = systemPrompt }
    }

    -- Agregar historial de conversación
    for _, msg in ipairs(messages) do
        table.insert(apiMessages, {
            role    = msg.role,
            content = msg.content
        })
    end

    local body = HttpService:JSONEncode({
        model      = model,
        messages   = apiMessages,
        max_tokens = CONFIG.MAX_TOKENS,
        temperature = 0.7,
        top_p      = 0.9,
    })

    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url     = "https://openrouter.ai/api/v1/chat/completions",
            Method  = "POST",
            Headers = headers,
            Body    = body,
        })
    end)

    if not success then
        return nil, "Error de conexión: " .. tostring(response)
    end

    if response.StatusCode ~= 200 then
        return nil, "Error API (" .. response.StatusCode .. "): Verifica tu API Key de OpenRouter"
    end

    local ok, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
    if not ok then
        return nil, "Error procesando respuesta de la API"
    end

    if data.error then
        return nil, "Error del modelo: " .. (data.error.message or "desconocido")
    end

    if data.choices and data.choices[1] and data.choices[1].message then
        return data.choices[1].message.content, nil
    end

    return nil, "Respuesta vacía del modelo"
end

-- Función principal de orquestación
function KaelenAI.think(userMessage, conversationHistory, mode, customSysPrompt, callback)
    -- Seleccionar modelo según contexto
    local model, modelType = KaelenAI.selectModel(userMessage, mode)

    -- Construir system prompt
    local basePrompt = MODE_PROMPTS[mode] or MODE_PROMPTS.Analista
    local gameContext = Utils.getGameContext()

    local systemPrompt = basePrompt .. "\n\n" .. gameContext

    if customSysPrompt and customSysPrompt ~= "" then
        systemPrompt = systemPrompt .. "\n\n[INSTRUCCIONES ADICIONALES DEL USUARIO]\n" .. customSysPrompt
    end

    -- Indicador del modelo activo
    systemPrompt = systemPrompt .. string.format(
        "\n\n[SISTEMA KAELEN v%s]\nModelo activo: %s\nModo: %s\nResponde SIEMPRE en español. Sé extremadamente útil y detallado.",
        CONFIG.VERSION, modelType == "coder" and "Qwen3 Coder (Especialista Lua)" or "Llama 3.3 70B (Analista Avanzado)", mode
    )

    -- Limitar historial para no exceder tokens
    local trimmedHistory = Utils.truncateHistory(conversationHistory, 10)

    -- Hacer la llamada en un hilo separado
    task.spawn(function()
        local response, err = KaelenAI.callAPI(model, trimmedHistory, systemPrompt)

        if callback then
            callback(response, err, modelType)
        end
    end)
end

-- ============================================================
-- CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO
-- ============================================================
local UI = {}
local Elements = {} -- Referencias a elementos UI

function UI.init()
    -- ScreenGui principal
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name             = "KaelenAI"
    screenGui.ResetOnSpawn     = false
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset   = true
    screenGui.DisplayOrder     = 999
    screenGui.Parent           = playerGui

    Elements.screenGui = screenGui

    UI.createFloatingButton(screenGui)
    UI.createMainWindow(screenGui)
    UI.createNotificationSystem(screenGui)

    -- Añadir mensaje de bienvenida
    UI.addMessage("assistant", [[¡Hola! Soy **Kaelen**, tu asistente IA para desarrollo en Roblox. 🚀

Estoy equipado con dos modelos de IA especializados:
• **Qwen3 Coder** → Scripts Lua, debugging, optimización
• **Llama 3.3 70B** → Análisis de gameplay, ideas creativas

**¿Qué puedo hacer por ti hoy?**
• Crear o arreglar scripts Lua
• Analizar sistemas de tu juego
• Detectar y solucionar bugs
• Sugerir mejoras y mecánicas
• Optimizar rendimiento

Selecciona un modo arriba o escríbeme directamente. ¡Estoy listo!]], "analyst")

    return screenGui
end

-- ============================================================
-- BOTÓN FLOTANTE CIRCULAR
-- ============================================================
function UI.createFloatingButton(parent)
    -- Contenedor del botón (arrastrable)
    local btnContainer = Instance.new("Frame")
    btnContainer.Name            = "KaelenBtnContainer"
    btnContainer.Size            = UDim2.new(0, 70, 0, 70)
    btnContainer.Position        = UDim2.new(1, -90, 0.75, 0)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex          = 100
    btnContainer.Parent          = parent

    Elements.btnContainer = btnContainer

    -- Sombra/Glow exterior
    local glow = Instance.new("ImageLabel")
    glow.Name             = "Glow"
    glow.Size             = UDim2.new(1, 30, 1, 30)
    glow.Position         = UDim2.new(0, -15, 0, -15)
    glow.BackgroundTransparency = 1
    glow.Image            = "rbxassetid://5028857084"
    glow.ImageColor3      = State.accent.glow
    glow.ImageTransparency = 0.5
    glow.ZIndex           = 99
    glow.Parent           = btnContainer
    Elements.btnGlow = glow

    -- Botón principal
    local btn = Instance.new("TextButton")
    btn.Name              = "KaelenBtn"
    btn.Size              = UDim2.new(1, 0, 1, 0)
    btn.Position          = UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3  = State.accent.main
    btn.Text              = ""
    btn.ZIndex            = 101
    btn.AutoButtonColor   = false
    btn.Parent            = btnContainer

    -- Esquinas circulares
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn

    -- Gradiente en el botón
    local gradient = Instance.new("UIGradient")
    gradient.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,180,255)),
    })
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.5),
    })
    gradient.Rotation = 135
    gradient.Parent   = btn

    -- Icono K de Kaelen
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Name              = "Icon"
    iconLabel.Size              = UDim2.new(1, 0, 1, 0)
    iconLabel.Position          = UDim2.new(0, 0, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text              = "K"
    iconLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize          = 28
    iconLabel.Font              = Enum.Font.GothamBold
    iconLabel.ZIndex            = 102
    iconLabel.Parent            = btn
    Elements.btnIcon = iconLabel

    -- Indicador de "pensando" (puntito animado)
    local thinkDot = Instance.new("Frame")
    thinkDot.Name              = "ThinkDot"
    thinkDot.Size              = UDim2.new(0, 14, 0, 14)
    thinkDot.Position          = UDim2.new(1, -14, 0, 0)
    thinkDot.BackgroundColor3  = State.theme.SUCCESS
    thinkDot.Visible           = false
    thinkDot.ZIndex            = 103
    thinkDot.Parent            = btn
    Instance.new("UICorner", thinkDot).CornerRadius = UDim.new(1,0)
    Elements.thinkDot = thinkDot

    Elements.floatingBtn = btn

    -- ============================================================
    -- LÓGICA DE ARRASTRE DEL BOTÓN
    -- ============================================================
    local isDragging    = false
    local dragStartMouse = Vector2.new()
    local dragStartPos  = UDim2.new()
    local hasMoved      = false
    local DRAG_THRESHOLD = 5

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isDragging    = true
            hasMoved      = false
            dragStartMouse = input.Position
            dragStartPos  = btnContainer.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
         or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStartMouse
            if math.abs(delta.X) > DRAG_THRESHOLD or math.abs(delta.Y) > DRAG_THRESHOLD then
                hasMoved = true
            end

            if hasMoved then
                local viewport   = workspace.CurrentCamera.ViewportSize
                local newX = dragStartPos.X.Scale * viewport.X + dragStartPos.X.Offset + delta.X
                local newY = dragStartPos.Y.Scale * viewport.Y + dragStartPos.Y.Offset + delta.Y

                -- Mantener dentro de pantalla
                newX = math.clamp(newX, 10, viewport.X - 80)
                newY = math.clamp(newY, 10, viewport.Y - 80)

                btnContainer.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                if not hasMoved then
                    -- Click sin arrastre = abrir/cerrar
                    UI.toggleWindow()
                end
            end
        end
    end)

    -- Animación de pulso del botón
    task.spawn(function()
        while true do
            if not State.isThinking then
                Utils.createTween(glow, {ImageTransparency = 0.3}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
                task.wait(1.2)
                Utils.createTween(glow, {ImageTransparency = 0.7}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
                task.wait(1.2)
            else
                -- Pulso rápido cuando está pensando
                Utils.createTween(glow, {ImageTransparency = 0.1}, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
                task.wait(0.4)
                Utils.createTween(glow, {ImageTransparency = 0.7}, 0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut):Play()
                task.wait(0.4)
            end
        end
    end)
end

-- ============================================================
-- VENTANA PRINCIPAL DE KAELEN
-- ============================================================
function UI.createMainWindow(parent)
    local theme = State.theme

    -- Ventana principal
    local window = Instance.new("Frame")
    window.Name             = "KaelenWindow"
    window.Size             = UDim2.new(0, 360, 0, 580)
    window.Position         = UDim2.new(0.5, -180, 0.5, -290)
    window.BackgroundColor3 = theme.BG_PRIMARY
    window.BackgroundTransparency = 0.05
    window.Visible          = false
    window.ZIndex           = 50
    window.ClipsDescendants = true
    window.Parent           = parent

    local winCorner = Instance.new("UICorner")
    winCorner.CornerRadius = UDim.new(0, 20)
    winCorner.Parent = window

    -- Borde elegante
    local winBorder = Instance.new("UIStroke")
    winBorder.Color     = theme.BORDER
    winBorder.Thickness = 1
    winBorder.Transparency = 0.3
    winBorder.Parent    = window

    Elements.mainWindow = window
    Elements.winBorder  = winBorder

    -- Sombra de la ventana
    local shadowFrame = Instance.new("ImageLabel")
    shadowFrame.Name              = "Shadow"
    shadowFrame.Size              = UDim2.new(1, 40, 1, 40)
    shadowFrame.Position          = UDim2.new(0, -20, 0, -10)
    shadowFrame.BackgroundTransparency = 1
    shadowFrame.Image             = "rbxassetid://5028857084"
    shadowFrame.ImageColor3       = Color3.fromRGB(0, 0, 0)
    shadowFrame.ImageTransparency = 0.6
    shadowFrame.ZIndex            = 49
    shadowFrame.Parent            = window

    UI.createWindowHeader(window)
    UI.createTabBar(window)
    UI.createChatArea(window)
    UI.createInputArea(window)
    UI.createModesTab(window)
    UI.createConfigTab(window)

    -- Ocultar tabs que no son chat
    Elements.modesPanel.Visible  = false
    Elements.configPanel.Visible = false
end

-- Header de la ventana
function UI.createWindowHeader(parent)
    local theme = State.theme

    local header = Instance.new("Frame")
    header.Name             = "Header"
    header.Size             = UDim2.new(1, 0, 0, 58)
    header.Position         = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = theme.BG_SECONDARY
    header.BackgroundTransparency = 0.1
    header.ZIndex           = 55
    header.Parent           = parent

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 20)
    headerCorner.Parent = header

    -- Fix para redondear solo esquinas superiores
    local headerFix = Instance.new("Frame")
    headerFix.Size              = UDim2.new(1, 0, 0.5, 0)
    headerFix.Position          = UDim2.new(0, 0, 0.5, 0)
    headerFix.BackgroundColor3  = theme.BG_SECONDARY
    headerFix.BackgroundTransparency = 0.1
    headerFix.ZIndex            = 54
    headerFix.Parent            = header

    -- Logo/Icono
    local logoFrame = Instance.new("Frame")
    logoFrame.Size             = UDim2.new(0, 36, 0, 36)
    logoFrame.Position         = UDim2.new(0, 14, 0.5, -18)
    logoFrame.BackgroundColor3 = State.accent.main
    logoFrame.ZIndex           = 56
    logoFrame.Parent           = header
    Instance.new("UICorner", logoFrame).CornerRadius = UDim.new(0, 10)

    local logoText = Instance.new("TextLabel")
    logoText.Size              = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text              = "K"
    logoText.TextColor3        = Color3.fromRGB(255,255,255)
    logoText.TextSize          = 20
    logoText.Font              = Enum.Font.GothamBold
    logoText.ZIndex            = 57
    logoText.Parent            = logoFrame

    -- Título
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name            = "Title"
    titleLabel.Size            = UDim2.new(0, 100, 0, 22)
    titleLabel.Position        = UDim2.new(0, 58, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text            = "Kaelen"
    titleLabel.TextColor3      = theme.TEXT_PRIMARY
    titleLabel.TextSize        = 18
    titleLabel.Font            = Enum.Font.GothamBold
    titleLabel.TextXAlignment  = Enum.TextXAlignment.Left
    titleLabel.ZIndex          = 56
    titleLabel.Parent          = header

    -- Subtítulo (modelo activo)
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name           = "Subtitle"
    subtitleLabel.Size           = UDim2.new(0, 180, 0, 18)
    subtitleLabel.Position       = UDim2.new(0, 58, 0, 30)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text           = "● Modo: " .. State.currentMode
    subtitleLabel.TextColor3     = State.accent.main
    subtitleLabel.TextSize       = 11
    subtitleLabel.Font           = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.ZIndex         = 56
    subtitleLabel.Parent         = header
    Elements.subtitleLabel = subtitleLabel

    -- Botón cerrar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name             = "CloseBtn"
    closeBtn.Size             = UDim2.new(0, 32, 0, 32)
    closeBtn.Position         = UDim2.new(1, -46, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize         = 13
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.ZIndex           = 57
    closeBtn.AutoButtonColor  = false
    closeBtn.Parent           = header
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

    closeBtn.MouseButton1Click:Connect(function()
        UI.closeWindow()
    end)

    -- Hover effect en close
    closeBtn.MouseEnter:Connect(function()
        Utils.createTween(closeBtn, {BackgroundTransparency = 0.3}, 0.15):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        Utils.createTween(closeBtn, {BackgroundTransparency = 0}, 0.15):Play()
    end)

    -- Botón analizar juego
    local analyzeBtn = Instance.new("TextButton")
    analyzeBtn.Name             = "AnalyzeBtn"
    analyzeBtn.Size             = UDim2.new(0, 32, 0, 32)
    analyzeBtn.Position         = UDim2.new(1, -84, 0.5, -16)
    analyzeBtn.BackgroundColor3 = State.accent.main
    analyzeBtn.BackgroundTransparency = 0.2
    analyzeBtn.Text             = "🔍"
    analyzeBtn.TextSize         = 15
    analyzeBtn.Font             = Enum.Font.Gotham
    analyzeBtn.ZIndex           = 57
    analyzeBtn.AutoButtonColor  = false
    analyzeBtn.Parent           = header
    Instance.new("UICorner", analyzeBtn).CornerRadius = UDim.new(1, 0)

    analyzeBtn.MouseButton1Click:Connect(function()
        local context = Utils.getGameContext()
        local msg = "Analiza el estado actual de mi juego y dame un reporte detallado:\n" .. context
        UI.sendMessage(msg)
    end)

    analyzeBtn.MouseEnter:Connect(function()
        Utils.createTween(analyzeBtn, {BackgroundTransparency = 0}, 0.15):Play()
    end)
    analyzeBtn.MouseLeave:Connect(function()
        Utils.createTween(analyzeBtn, {BackgroundTransparency = 0.2}, 0.15):Play()
    end)
end

-- Barra de pestañas
function UI.createTabBar(parent)
    local theme = State.theme

    local tabBar = Instance.new("Frame")
    tabBar.Name             = "TabBar"
    tabBar.Size             = UDim2.new(1, -28, 0, 38)
    tabBar.Position         = UDim2.new(0, 14, 0, 62)
    tabBar.BackgroundColor3 = theme.BG_CARD
    tabBar.ZIndex           = 55
    tabBar.Parent           = parent
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 12)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection  = Enum.FillDirection.Horizontal
    tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    tabLayout.Padding        = UDim.new(0, 4)
    tabLayout.Parent         = tabBar

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft   = UDim.new(0, 4)
    tabPadding.PaddingRight  = UDim.new(0, 4)
    tabPadding.PaddingTop    = UDim.new(0, 4)
    tabPadding.PaddingBottom = UDim.new(0, 4)
    tabPadding.Parent        = tabBar

    local tabs = {
        { name = "Chat",   icon = "💬", order = 1 },
        { name = "Modos",  icon = "⚡", order = 2 },
        { name = "Config", icon = "⚙️", order = 3 },
    }

    Elements.tabButtons = {}

    for _, tabData in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name             = tabData.name .. "Tab"
        tabBtn.Size             = UDim2.new(1/3, -4, 1, 0)
        tabBtn.BackgroundColor3 = tabData.name == "Chat" and State.accent.main or theme.BG_SECONDARY
        tabBtn.BackgroundTransparency = tabData.name == "Chat" and 0 or 0.3
        tabBtn.Text             = tabData.icon .. " " .. tabData.name
        tabBtn.TextColor3       = tabData.name == "Chat" and Color3.fromRGB(255,255,255) or theme.TEXT_SECONDARY
        tabBtn.TextSize         = 12
        tabBtn.Font             = Enum.Font.GothamSemibold
        tabBtn.LayoutOrder      = tabData.order
        tabBtn.ZIndex           = 56
        tabBtn.AutoButtonColor  = false
        tabBtn.Parent           = tabBar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)

        Elements.tabButtons[tabData.name] = tabBtn

        tabBtn.MouseButton1Click:Connect(function()
            UI.switchTab(tabData.name)
        end)
    end
end

function UI.switchTab(tabName)
    State.activeTab = tabName
    local theme = State.theme

    -- Actualizar visual de tabs
    for name, btn in pairs(Elements.tabButtons) do
        if name == tabName then
            Utils.createTween(btn, {BackgroundColor3 = State.accent.main, BackgroundTransparency = 0}, 0.2):Play()
            btn.TextColor3 = Color3.fromRGB(255,255,255)
        else
            Utils.createTween(btn, {BackgroundColor3 = theme.BG_SECONDARY, BackgroundTransparency = 0.3}, 0.2):Play()
            btn.TextColor3 = theme.TEXT_SECONDARY
        end
    end

    -- Mostrar/ocultar paneles
    Elements.chatArea.Visible   = tabName == "Chat"
    Elements.inputArea.Visible  = tabName == "Chat"
    Elements.modesPanel.Visible = tabName == "Modos"
    Elements.configPanel.Visible = tabName == "Config"
end

-- ============================================================
-- ÁREA DE CHAT
-- ============================================================
function UI.createChatArea(parent)
    local theme = State.theme

    local chatContainer = Instance.new("Frame")
    chatContainer.Name             = "ChatArea"
    chatContainer.Size             = UDim2.new(1, -16, 1, -180)
    chatContainer.Position         = UDim2.new(0, 8, 0, 106)
    chatContainer.BackgroundTransparency = 1
    chatContainer.ZIndex           = 52
    chatContainer.ClipsDescendants = true
    chatContainer.Parent           = parent
    Elements.chatArea = chatContainer

    -- ScrollingFrame para el chat
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name               = "ChatScroll"
    scrollFrame.Size               = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position           = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarThickness = 3
    scrollFrame.ScrollBarImageColor3 = State.accent.main
    scrollFrame.ScrollBarImageTransparency = 0.5
    scrollFrame.CanvasSize         = UDim2.new(0, 0, 0, 0)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.ZIndex             = 53
    scrollFrame.Parent             = chatContainer
    Elements.chatScroll = scrollFrame

    -- Layout de mensajes
    local msgLayout = Instance.new("UIListLayout")
    msgLayout.FillDirection = Enum.FillDirection.Vertical
    msgLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    msgLayout.Padding       = UDim.new(0, 8)
    msgLayout.Parent        = scrollFrame

    local msgPadding = Instance.new("UIPadding")
    msgPadding.PaddingLeft   = UDim.new(0, 8)
    msgPadding.PaddingRight  = UDim.new(0, 8)
    msgPadding.PaddingTop    = UDim.new(0, 8)
    msgPadding.PaddingBottom = UDim.new(0, 8)
    msgPadding.Parent        = scrollFrame

    Elements.msgLayout  = msgLayout
    Elements.msgPadding = msgPadding
end

-- Crear burbuja de mensaje
function UI.addMessage(role, text, modelType)
    local theme    = State.theme
    local isUser   = role == "user"
    local scroll   = Elements.chatScroll

    State.messageCount = State.messageCount + 1

    -- Frame contenedor del mensaje
    local msgFrame = Instance.new("Frame")
    msgFrame.Name              = "Msg_" .. State.messageCount
    msgFrame.Size              = UDim2.new(1, 0, 0, 0)
    msgFrame.BackgroundTransparency = 1
    msgFrame.AutomaticSize     = Enum.AutomaticSize.Y
    msgFrame.LayoutOrder       = State.messageCount
    msgFrame.ZIndex            = 54
    msgFrame.Parent            = scroll

    -- Burbuja
    local bubble = Instance.new("Frame")
    bubble.Name              = "Bubble"
    bubble.Size              = UDim2.new(0.80, 0, 0, 0)
    bubble.AutomaticSize     = Enum.AutomaticSize.Y
    bubble.BackgroundColor3  = isUser and State.accent.main or theme.BG_CARD
    bubble.Position          = isUser and UDim2.new(0.20, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    bubble.ZIndex            = 55
    bubble.Parent            = msgFrame
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 14)

    -- Borde sutil en burbuja AI
    if not isUser then
        local bubbleBorder = Instance.new("UIStroke")
        bubbleBorder.Color       = theme.BORDER
        bubbleBorder.Thickness   = 1
        bubbleBorder.Transparency = 0.5
        bubbleBorder.Parent      = bubble
    end

    -- Padding de la burbuja
    local bPad = Instance.new("UIPadding")
    bPad.PaddingLeft   = UDim.new(0, 12)
    bPad.PaddingRight  = UDim.new(0, 12)
    bPad.PaddingTop    = UDim.new(0, 10)
    bPad.PaddingBottom = UDim.new(0, 10)
    bPad.Parent        = bubble

    -- Layout interno de la burbuja
    local bubbleLayout = Instance.new("UIListLayout")
    bubbleLayout.FillDirection = Enum.FillDirection.Vertical
    bubbleLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    bubbleLayout.Padding       = UDim.new(0, 6)
    bubbleLayout.Parent        = bubble

    -- Etiqueta del modelo (solo para AI)
    if not isUser then
        local modelLabel = Instance.new("TextLabel")
        modelLabel.Size              = UDim2.new(1, 0, 0, 14)
        modelLabel.BackgroundTransparency = 1
        modelLabel.Text              = modelType == "coder" and "⚡ Qwen3 Coder" or "🧠 Llama 3.3 70B"
        modelLabel.TextColor3        = State.accent.main
        modelLabel.TextSize          = 10
        modelLabel.Font              = Enum.Font.GothamSemibold
        modelLabel.TextXAlignment    = Enum.TextXAlignment.Left
        modelLabel.LayoutOrder       = 0
        modelLabel.ZIndex            = 56
        modelLabel.Parent            = bubble
    end

    -- Texto del mensaje
    local msgText = Instance.new("TextLabel")
    msgText.Name              = "MsgText"
    msgText.Size              = UDim2.new(1, 0, 0, 0)
    msgText.AutomaticSize     = Enum.AutomaticSize.Y
    msgText.BackgroundTransparency = 1
    msgText.Text              = text
    msgText.TextColor3        = isUser and Color3.fromRGB(255,255,255) or theme.TEXT_PRIMARY
    msgText.TextSize          = 13
    msgText.Font              = Enum.Font.Gotham
    msgText.TextWrapped       = true
    msgText.TextXAlignment    = Enum.TextXAlignment.Left
    msgText.LayoutOrder       = 1
    msgText.ZIndex            = 56
    msgText.Parent            = bubble

    -- Botones de acción para mensajes AI (copiar, etc.)
    if not isUser then
        local actionRow = Instance.new("Frame")
        actionRow.Size              = UDim2.new(1, 0, 0, 24)
        actionRow.BackgroundTransparency = 1
        actionRow.AutomaticSize     = Enum.AutomaticSize.X
        actionRow.LayoutOrder       = 2
        actionRow.ZIndex            = 56
        actionRow.Parent            = bubble

        local actionLayout = Instance.new("UIListLayout")
        actionLayout.FillDirection  = Enum.FillDirection.Horizontal
        actionLayout.SortOrder      = Enum.SortOrder.LayoutOrder
        actionLayout.Padding        = UDim.new(0, 6)
        actionLayout.Parent         = actionRow

        -- Botón copiar
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size              = UDim2.new(0, 60, 0, 22)
        copyBtn.BackgroundColor3  = theme.BG_INPUT
        copyBtn.Text              = "📋 Copiar"
        copyBtn.TextColor3        = theme.TEXT_SECONDARY
        copyBtn.TextSize          = 10
        copyBtn.Font              = Enum.Font.Gotham
        copyBtn.LayoutOrder       = 1
        copyBtn.ZIndex            = 57
        copyBtn.AutoButtonColor   = false
        copyBtn.Parent            = actionRow
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

        copyBtn.MouseButton1Click:Connect(function()
            Utils.copyToClipboard(text)
            copyBtn.Text = "✅ Copiado"
            task.delay(2, function()
                copyBtn.Text = "📋 Copiar"
            end)
        end)
    end

    -- Timestamp
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size              = UDim2.new(1, 0, 0, 12)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text              = os.date("%H:%M")
    timeLabel.TextColor3        = theme.TEXT_MUTED
    timeLabel.TextSize          = 10
    timeLabel.Font              = Enum.Font.Gotham
    timeLabel.TextXAlignment    = isUser and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    timeLabel.ZIndex            = 54
    timeLabel.Parent            = msgFrame

    -- Animación de entrada
    bubble.BackgroundTransparency = 1
    msgText.TextTransparency = 1

    Utils.createTween(bubble, {BackgroundTransparency = isUser and 0 or 0}, 0.25):Play()
    Utils.createTween(msgText, {TextTransparency = 0}, 0.3):Play()

    -- Auto-scroll al fondo
    task.defer(function()
        Elements.chatScroll.CanvasPosition = Vector2.new(
            0,
            math.max(0, Elements.chatScroll.AbsoluteCanvasSize.Y - Elements.chatScroll.AbsoluteSize.Y)
        )
    end)

    -- Guardar en historial
    table.insert(State.messages, {
        role    = role == "user" and "user" or "assistant",
        content = text
    })

    return msgFrame
end

-- Indicador "Kaelen pensando..."
function UI.showThinking(show)
    State.isThinking = show
    Elements.thinkDot.Visible = show

    if show then
        -- Crear burbuja de "pensando"
        local thinkFrame = Instance.new("Frame")
        thinkFrame.Name              = "ThinkingBubble"
        thinkFrame.Size              = UDim2.new(1, 0, 0, 46)
        thinkFrame.BackgroundTransparency = 1
        thinkFrame.LayoutOrder       = 9999
        thinkFrame.ZIndex            = 54
        thinkFrame.Parent            = Elements.chatScroll

        local thinkBubble = Instance.new("Frame")
        thinkBubble.Size             = UDim2.new(0, 140, 1, 0)
        thinkBubble.BackgroundColor3 = State.theme.BG_CARD
        thinkBubble.ZIndex           = 55
        thinkBubble.Parent           = thinkFrame
        Instance.new("UICorner", thinkBubble).CornerRadius = UDim.new(0, 14)

        local thinkLabel = Instance.new("TextLabel")
        thinkLabel.Size              = UDim2.new(1, -16, 1, 0)
        thinkLabel.Position          = UDim2.new(0, 8, 0, 0)
        thinkLabel.BackgroundTransparency = 1
        thinkLabel.Text              = "Kaelen pensando"
        thinkLabel.TextColor3        = State.theme.TEXT_SECONDARY
        thinkLabel.TextSize          = 12
        thinkLabel.Font              = Enum.Font.GothamItalic
        thinkLabel.ZIndex            = 56
        thinkLabel.Parent            = thinkBubble
        Elements.thinkLabel = thinkLabel

        -- Animación de puntos
        local dots = 0
        Elements.thinkAnim = task.spawn(function()
            while State.isThinking do
                dots = (dots % 3) + 1
                thinkLabel.Text = "Kaelen pensando" .. string.rep(".", dots)
                task.wait(0.4)
            end
        end)

        Elements.thinkFrame = thinkFrame

        -- Scroll al fondo
        task.defer(function()
            Elements.chatScroll.CanvasPosition = Vector2.new(
                0,
                math.max(0, Elements.chatScroll.AbsoluteCanvasSize.Y - Elements.chatScroll.AbsoluteSize.Y)
            )
        end)
    else
        -- Remover burbuja de pensando
        if Elements.thinkFrame then
            Elements.thinkFrame:Destroy()
            Elements.thinkFrame = nil
        end
        if Elements.thinkAnim then
            task.cancel(Elements.thinkAnim)
            Elements.thinkAnim = nil
        end
    end
end

-- ============================================================
-- ÁREA DE INPUT
-- ============================================================
function UI.createInputArea(parent)
    local theme = State.theme

    local inputArea = Instance.new("Frame")
    inputArea.Name             = "InputArea"
    inputArea.Size             = UDim2.new(1, -16, 0, 68)
    inputArea.Position         = UDim2.new(0, 8, 1, -76)
    inputArea.BackgroundColor3 = theme.BG_SECONDARY
    inputArea.BackgroundTransparency = 0.05
    inputArea.ZIndex           = 55
    inputArea.Parent           = parent
    Instance.new("UICorner", inputArea).CornerRadius = UDim.new(0, 16)

    local inputBorder = Instance.new("UIStroke")
    inputBorder.Color     = State.accent.main
    inputBorder.Thickness = 1
    inputBorder.Transparency = 0.6
    inputBorder.Parent    = inputArea
    Elements.inputBorder  = inputBorder

    Elements.inputArea = inputArea

    -- TextBox de entrada
    local textBox = Instance.new("TextBox")
    textBox.Name              = "InputBox"
    textBox.Size              = UDim2.new(1, -60, 1, -16)
    textBox.Position          = UDim2.new(0, 12, 0, 8)
    textBox.BackgroundTransparency = 1
    textBox.Text              = ""
    textBox.PlaceholderText   = "Escribe tu pregunta o código..."
    textBox.PlaceholderColor3 = theme.TEXT_MUTED
    textBox.TextColor3        = theme.TEXT_PRIMARY
    textBox.TextSize          = 13
    textBox.Font              = Enum.Font.Gotham
    textBox.TextWrapped       = true
    textBox.TextXAlignment    = Enum.TextXAlignment.Left
    textBox.TextYAlignment    = Enum.TextYAlignment.Center
    textBox.MultiLine         = false
    textBox.ClearTextOnFocus  = false
    textBox.ZIndex            = 56
    textBox.Parent            = inputArea
    Elements.textBox = textBox

    -- Focus glow effect
    textBox.Focused:Connect(function()
        Utils.createTween(inputBorder, {Transparency = 0, Thickness = 1.5}, 0.2):Play()
    end)
    textBox.FocusLost:Connect(function(enterPressed)
        Utils.createTween(inputBorder, {Transparency = 0.6, Thickness = 1}, 0.2):Play()
        if enterPressed then
            UI.sendMessage(textBox.Text)
        end
    end)

    -- Botón enviar
    local sendBtn = Instance.new("TextButton")
    sendBtn.Name             = "SendBtn"
    sendBtn.Size             = UDim2.new(0, 42, 0, 42)
    sendBtn.Position         = UDim2.new(1, -52, 0.5, -21)
    sendBtn.BackgroundColor3 = State.accent.main
    sendBtn.Text             = "➤"
    sendBtn.TextColor3       = Color3.fromRGB(255,255,255)
    sendBtn.TextSize         = 18
    sendBtn.Font             = Enum.Font.GothamBold
    sendBtn.ZIndex           = 57
    sendBtn.AutoButtonColor  = false
    sendBtn.Parent           = inputArea
    Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(1, 0)
    Elements.sendBtn = sendBtn

    sendBtn.MouseButton1Click:Connect(function()
        UI.sendMessage(textBox.Text)
    end)

    sendBtn.MouseEnter:Connect(function()
        Utils.createTween(sendBtn, {BackgroundColor3 = State.accent.glow}, 0.15):Play()
    end)
    sendBtn.MouseLeave:Connect(function()
        Utils.createTween(sendBtn, {BackgroundColor3 = State.accent.main}, 0.15):Play()
    end)

    -- Sugerencias rápidas
    UI.createQuickSuggestions(parent)
end

-- Sugerencias rápidas
function UI.createQuickSuggestions(parent)
    local theme = State.theme

    local suggestions = {
        "🐛 Debug mi juego",
        "📜 Crear script Lua",
        "⚡ Optimizar código",
        "🎮 Analizar mecánica",
        "💡 Dar ideas",
    }

    local suggFrame = Instance.new("Frame")
    suggFrame.Name             = "Suggestions"
    suggFrame.Size             = UDim2.new(1, -16, 0, 28)
    suggFrame.Position         = UDim2.new(0, 8, 1, -82)
    suggFrame.BackgroundTransparency = 1
    suggFrame.ZIndex           = 55
    suggFrame.Parent           = parent
    Elements.suggestionsFrame = suggFrame

    local suggLayout = Instance.new("UIListLayout")
    suggLayout.FillDirection = Enum.FillDirection.Horizontal
    suggLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    suggLayout.Padding       = UDim.new(0, 5)
    suggLayout.Parent        = suggFrame

    local scrollSugg = Instance.new("ScrollingFrame")
    scrollSugg.Size              = UDim2.new(1, 0, 1, 0)
    scrollSugg.BackgroundTransparency = 1
    scrollSugg.ScrollBarThickness = 0
    scrollSugg.ScrollingDirection = Enum.ScrollingDirection.X
    scrollSugg.CanvasSize        = UDim2.new(0, 0, 1, 0)
    scrollSugg.AutomaticCanvasSize = Enum.AutomaticSize.X
    scrollSugg.ZIndex            = 55
    scrollSugg.Parent            = suggFrame

    local innerLayout = Instance.new("UIListLayout")
    innerLayout.FillDirection = Enum.FillDirection.Horizontal
    innerLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    innerLayout.Padding       = UDim.new(0, 5)
    innerLayout.Parent        = scrollSugg

    for i, sugg in ipairs(suggestions) do
        local chip = Instance.new("TextButton")
        chip.Size              = UDim2.new(0, 0, 1, -4)
        chip.AutomaticSize     = Enum.AutomaticSize.X
        chip.Position          = UDim2.new(0, 0, 0, 2)
        chip.BackgroundColor3  = theme.BG_CARD
        chip.Text              = "  " .. sugg .. "  "
        chip.TextColor3        = theme.TEXT_SECONDARY
        chip.TextSize          = 11
        chip.Font              = Enum.Font.Gotham
        chip.LayoutOrder       = i
        chip.ZIndex            = 56
        chip.AutoButtonColor   = false
        chip.Parent            = scrollSugg
        Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 10)

        chip.MouseButton1Click:Connect(function()
            Elements.textBox.Text = sugg:gsub("^%S+%s*", "") -- quitar emoji
            Elements.textBox:CaptureFocus()
        end)

        chip.MouseEnter:Connect(function()
            Utils.createTween(chip, {BackgroundColor3 = State.accent.main, TextColor3 = Color3.fromRGB(255,255,255)}, 0.15):Play()
        end)
        chip.MouseLeave:Connect(function()
            Utils.createTween(chip, {BackgroundColor3 = theme.BG_CARD, TextColor3 = theme.TEXT_SECONDARY}, 0.15):Play()
        end)
    end
end

-- ============================================================
-- PANEL DE MODOS
-- ============================================================
function UI.createModesTab(parent)
    local theme = State.theme

    local modesPanel = Instance.new("Frame")
    modesPanel.Name             = "ModesPanel"
    modesPanel.Size             = UDim2.new(1, -16, 1, -180)
    modesPanel.Position         = UDim2.new(0, 8, 0, 106)
    modesPanel.BackgroundTransparency = 1
    modesPanel.ZIndex           = 52
    modesPanel.Parent           = parent
    Elements.modesPanel = modesPanel

    local modesLayout = Instance.new("UIListLayout")
    modesLayout.FillDirection = Enum.FillDirection.Vertical
    modesLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    modesLayout.Padding       = UDim.new(0, 10)
    modesLayout.Parent        = modesPanel

    local modesPadding = Instance.new("UIPadding")
    modesPadding.PaddingTop    = UDim.new(0, 10)
    modesPadding.PaddingBottom = UDim.new(0, 10)
    modesPadding.Parent        = modesPanel

    -- Título
    local title = Instance.new("TextLabel")
    title.Size              = UDim2.new(1, 0, 0, 24)
    title.BackgroundTransparency = 1
    title.Text              = "Selecciona el Modo de Kaelen"
    title.TextColor3        = theme.TEXT_PRIMARY
    title.TextSize          = 15
    title.Font              = Enum.Font.GothamBold
    title.LayoutOrder       = 0
    title.ZIndex            = 53
    title.Parent            = modesPanel

    local modes = {
        {
            name  = "Programador",
            icon  = "⚡",
            desc  = "Especialista en Lua, scripts y código",
            color = Color3.fromRGB(99, 102, 241),
            model = "Qwen3 Coder"
        },
        {
            name  = "Analista",
            icon  = "🧠",
            desc  = "Análisis de gameplay y sistemas del juego",
            color = Color3.fromRGB(16, 185, 129),
            model = "Llama 3.3 70B"
        },
        {
            name  = "Creativo",
            icon  = "🎨",
            desc  = "Ideas creativas y diseño de mecánicas",
            color = Color3.fromRGB(244, 63, 94),
            model = "Llama 3.3 70B"
        },
        {
            name  = "Debug",
            icon  = "🐛",
            desc  = "Detección y solución de bugs en tiempo real",
            color = Color3.fromRGB(245, 158, 11),
            model = "Qwen3 Coder"
        },
    }

    for i, modeData in ipairs(modes) do
        local card = Instance.new("TextButton")
        card.Name              = modeData.name .. "Card"
        card.Size              = UDim2.new(1, 0, 0, 68)
        card.BackgroundColor3  = State.currentMode == modeData.name and modeData.color or theme.BG_CARD
        card.BackgroundTransparency = State.currentMode == modeData.name and 0.1 or 0
        card.Text              = ""
        card.LayoutOrder       = i
        card.ZIndex            = 53
        card.AutoButtonColor   = false
        card.Parent            = modesPanel
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

        if State.currentMode == modeData.name then
            local cardBorder = Instance.new("UIStroke")
            cardBorder.Color     = modeData.color
            cardBorder.Thickness = 1.5
            cardBorder.Parent    = card
        end

        local cardLayout = Instance.new("UIListLayout")
        cardLayout.FillDirection = Enum.FillDirection.Horizontal
        cardLayout.SortOrder     = Enum.SortOrder.LayoutOrder
        cardLayout.Padding       = UDim.new(0, 0)
        cardLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        cardLayout.Parent        = card

        -- Icono
        local iconFrame = Instance.new("Frame")
        iconFrame.Size              = UDim2.new(0, 68, 1, 0)
        iconFrame.BackgroundTransparency = 1
        iconFrame.LayoutOrder       = 1
        iconFrame.ZIndex            = 54
        iconFrame.Parent            = card

        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size              = UDim2.new(1, 0, 1, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text              = modeData.icon
        iconLabel.TextSize          = 26
        iconLabel.Font              = Enum.Font.Gotham
        iconLabel.ZIndex            = 55
        iconLabel.Parent            = iconFrame

        -- Info
        local infoFrame = Instance.new("Frame")
        infoFrame.Size              = UDim2.new(1, -68, 1, 0)
        infoFrame.BackgroundTransparency = 1
        infoFrame.LayoutOrder       = 2
        infoFrame.ZIndex            = 54
        infoFrame.Parent            = card

        local infoLayout = Instance.new("UIListLayout")
        infoLayout.FillDirection    = Enum.FillDirection.Vertical
        infoLayout.SortOrder        = Enum.SortOrder.LayoutOrder
        infoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        infoLayout.Padding          = UDim.new(0, 2)
        infoLayout.Parent           = infoFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size              = UDim2.new(1, -10, 0, 20)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text              = modeData.name
        nameLabel.TextColor3        = State.currentMode == modeData.name and modeData.color or theme.TEXT_PRIMARY
        nameLabel.TextSize          = 14
        nameLabel.Font              = Enum.Font.GothamBold
        nameLabel.TextXAlignment    = Enum.TextXAlignment.Left
        nameLabel.LayoutOrder       = 1
        nameLabel.ZIndex            = 55
        nameLabel.Parent            = infoFrame

        local descLabel = Instance.new("TextLabel")
        descLabel.Size              = UDim2.new(1, -10, 0, 16)
        descLabel.BackgroundTransparency = 1
        descLabel.Text              = modeData.desc
        descLabel.TextColor3        = theme.TEXT_SECONDARY
        descLabel.TextSize          = 11
        descLabel.Font              = Enum.Font.Gotham
        descLabel.TextWrapped       = true
        descLabel.TextXAlignment    = Enum.TextXAlignment.Left
        descLabel.LayoutOrder       = 2
        descLabel.ZIndex            = 55
        descLabel.Parent            = infoFrame

        local modelLabel = Instance.new("TextLabel")
        modelLabel.Size             = UDim2.new(1, -10, 0, 13)
        modelLabel.BackgroundTransparency = 1
        modelLabel.Text             = "Modelo: " .. modeData.model
        modelLabel.TextColor3       = modeData.color
        modelLabel.TextSize         = 10
        modelLabel.Font             = Enum.Font.GothamSemibold
        modelLabel.TextXAlignment   = Enum.TextXAlignment.Left
        modelLabel.LayoutOrder      = 3
        modelLabel.ZIndex           = 55
        modelLabel.Parent           = infoFrame

        card.MouseButton1Click:Connect(function()
            State.currentMode = modeData.name
            Elements.subtitleLabel.Text = "● Modo: " .. modeData.name
            -- Ir al chat con confirmación
            UI.switchTab("Chat")
            UI.addMessage("assistant",
                string.format("Modo **%s** activado. Ahora me especializo en %s usando %s. ¿En qué te ayudo?",
                modeData.name, modeData.desc:lower(), modeData.model),
                modeData.model:find("Qwen") and "coder" or "analyst"
            )
        end)

        card.MouseEnter:Connect(function()
            if State.currentMode ~= modeData.name then
                Utils.createTween(card, {BackgroundColor3 = modeData.color, BackgroundTransparency = 0.8}, 0.15):Play()
            end
        end)
        card.MouseLeave:Connect(function()
            if State.currentMode ~= modeData.name then
                Utils.createTween(card, {BackgroundColor3 = theme.BG_CARD, BackgroundTransparency = 0}, 0.15):Play()
            end
        end)
    end
end

-- ============================================================
-- PANEL DE CONFIGURACIÓN
-- ============================================================
function UI.createConfigTab(parent)
    local theme = State.theme

    local configPanel = Instance.new("ScrollingFrame")
    configPanel.Name               = "ConfigPanel"
    configPanel.Size               = UDim2.new(1, -16, 1, -80)
    configPanel.Position           = UDim2.new(0, 8, 0, 106)
    configPanel.BackgroundTransparency = 1
    configPanel.ScrollBarThickness = 3
    configPanel.ScrollBarImageColor3 = State.accent.main
    configPanel.CanvasSize         = UDim2.new(0, 0, 0, 0)
    configPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    configPanel.ZIndex             = 52
    configPanel.Parent             = parent
    Elements.configPanel = configPanel

    local configLayout = Instance.new("UIListLayout")
    configLayout.FillDirection = Enum.FillDirection.Vertical
    configLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    configLayout.Padding       = UDim.new(0, 12)
    configLayout.Parent        = configPanel

    local configPad = Instance.new("UIPadding")
    configPad.PaddingTop    = UDim.new(0, 10)
    configPad.PaddingBottom = UDim.new(0, 20)
    configPad.Parent        = configPanel

    -- SECCIÓN: Tema
    UI.createConfigSection(configPanel, "🎨 Apariencia", 1, function(section)
        -- Selector de tema
        UI.createConfigLabel(section, "Tema de color:", 2)

        local themeRow = Instance.new("Frame")
        themeRow.Size              = UDim2.new(1, 0, 0, 36)
        themeRow.BackgroundTransparency = 1
        themeRow.LayoutOrder       = 3
        themeRow.ZIndex            = 54
        themeRow.Parent            = section

        local themeLayout = Instance.new("UIListLayout")
        themeLayout.FillDirection  = Enum.FillDirection.Horizontal
        themeLayout.SortOrder      = Enum.SortOrder.LayoutOrder
        themeLayout.Padding        = UDim.new(0, 8)
        themeLayout.Parent         = themeRow

        for _, themeName in ipairs({"Dark", "Light"}) do
            local themeBtn = Instance.new("TextButton")
            themeBtn.Size             = UDim2.new(0, 80, 1, 0)
            themeBtn.BackgroundColor3 = State.currentTheme == themeName and State.accent.main or theme.BG_CARD
            themeBtn.Text             = themeName == "Dark" and "🌙 Oscuro" or "☀️ Claro"
            themeBtn.TextColor3       = State.currentTheme == themeName and Color3.fromRGB(255,255,255) or theme.TEXT_PRIMARY
            themeBtn.TextSize         = 12
            themeBtn.Font             = Enum.Font.GothamSemibold
            themeBtn.ZIndex           = 55
            themeBtn.AutoButtonColor  = false
            themeBtn.Parent           = themeRow
            Instance.new("UICorner", themeBtn).CornerRadius = UDim.new(0, 10)

            themeBtn.MouseButton1Click:Connect(function()
                State.currentTheme = themeName
                State.theme = THEMES[themeName]
                -- Notificación
                StarterGui:SetCore("SendNotification", {
                    Title   = "Kaelen",
                    Text    = "Tema '" .. themeName .. "' aplicado. Recarga para ver cambios completos.",
                    Duration = 3,
                })
            end)
        end

        -- Selector de accent
        UI.createConfigLabel(section, "Color de acento:", 4)

        local accentRow = Instance.new("Frame")
        accentRow.Size              = UDim2.new(1, 0, 0, 32)
        accentRow.BackgroundTransparency = 1
        accentRow.LayoutOrder       = 5
        accentRow.ZIndex            = 54
        accentRow.Parent            = section

        local accentLayout = Instance.new("UIListLayout")
        accentLayout.FillDirection  = Enum.FillDirection.Horizontal
        accentLayout.SortOrder      = Enum.SortOrder.LayoutOrder
        accentLayout.Padding        = UDim.new(0, 6)
        accentLayout.Parent         = accentRow

        for accentName, accentColors in pairs(ACCENT_COLORS) do
            local accentBtn = Instance.new("TextButton")
            accentBtn.Size             = UDim2.new(0, 36, 1, 0)
            accentBtn.BackgroundColor3 = accentColors.main
            accentBtn.Text             = State.currentAccent == accentName and "✓" or ""
            accentBtn.TextColor3       = Color3.fromRGB(255,255,255)
            accentBtn.TextSize         = 14
            accentBtn.Font             = Enum.Font.GothamBold
            accentBtn.ZIndex           = 55
            accentBtn.AutoButtonColor  = false
            accentBtn.Parent           = accentRow
            Instance.new("UICorner", accentBtn).CornerRadius = UDim.new(1, 0)

            accentBtn.MouseButton1Click:Connect(function()
                State.currentAccent = accentName
                State.accent = accentColors
                StarterGui:SetCore("SendNotification", {
                    Title   = "Kaelen",
                    Text    = "Acento '" .. accentName .. "' aplicado!",
                    Duration = 2,
                })
            end)
        end
    end)

    -- SECCIÓN: Prompt personalizado
    UI.createConfigSection(configPanel, "🧠 Prompt Personalizado", 2, function(section)
        UI.createConfigLabel(section, "Instrucciones adicionales para Kaelen:", 2)

        local promptBox = Instance.new("TextBox")
        promptBox.Name              = "CustomPromptBox"
        promptBox.Size              = UDim2.new(1, 0, 0, 80)
        promptBox.BackgroundColor3  = theme.BG_INPUT
        promptBox.PlaceholderText   = "Ej: Siempre incluye comentarios en cada línea de código. Usa nombres de variables en español..."
        promptBox.PlaceholderColor3 = theme.TEXT_MUTED
        promptBox.Text              = State.customSysPrompt
        promptBox.TextColor3        = theme.TEXT_PRIMARY
        promptBox.TextSize          = 12
        promptBox.Font              = Enum.Font.Gotham
        promptBox.TextWrapped       = true
        promptBox.TextXAlignment    = Enum.TextXAlignment.Left
        promptBox.TextYAlignment    = Enum.TextYAlignment.Top
        promptBox.MultiLine         = true
        promptBox.ClearTextOnFocus  = false
        promptBox.LayoutOrder       = 3
        promptBox.ZIndex            = 55
        promptBox.Parent            = section
        Instance.new("UICorner", promptBox).CornerRadius = UDim.new(0, 10)

        local promptPad = Instance.new("UIPadding")
        promptPad.PaddingAll = UDim.new(0, 8)
        promptPad.Parent = promptBox

        promptBox.FocusLost:Connect(function()
            State.customSysPrompt = promptBox.Text
        end)

        local saveBtn = Instance.new("TextButton")
        saveBtn.Size             = UDim2.new(1, 0, 0, 34)
        saveBtn.BackgroundColor3 = State.accent.main
        saveBtn.Text             = "💾 Guardar Prompt"
        saveBtn.TextColor3       = Color3.fromRGB(255,255,255)
        saveBtn.TextSize         = 13
        saveBtn.Font             = Enum.Font.GothamSemibold
        saveBtn.LayoutOrder      = 4
        saveBtn.ZIndex           = 55
        saveBtn.AutoButtonColor  = false
        saveBtn.Parent           = section
        Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)

        saveBtn.MouseButton1Click:Connect(function()
            State.customSysPrompt = promptBox.Text
            StarterGui:SetCore("SendNotification", {
                Title   = "Kaelen",
                Text    = "Prompt personalizado guardado!",
                Duration = 2,
            })
        end)
    end)

    -- SECCIÓN: Info del sistema
    UI.createConfigSection(configPanel, "ℹ️ Información", 3, function(section)
        local infoText = string.format(
            "Kaelen v%s\nModelo Coder: Qwen3 Coder\nModelo Analista: Llama 3.3 70B\nVía: OpenRouter API\nDesarrollado para testing de juegos Roblox",
            CONFIG.VERSION
        )

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size              = UDim2.new(1, 0, 0, 80)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Text              = infoText
        infoLabel.TextColor3        = theme.TEXT_SECONDARY
        infoLabel.TextSize          = 11
        infoLabel.Font              = Enum.Font.Gotham
        infoLabel.TextWrapped       = true
        infoLabel.TextXAlignment    = Enum.TextXAlignment.Left
        infoLabel.TextYAlignment    = Enum.TextYAlignment.Top
        infoLabel.LayoutOrder       = 2
        infoLabel.ZIndex            = 54
        infoLabel.Parent            = section

        -- Botón limpiar chat
        local clearBtn = Instance.new("TextButton")
        clearBtn.Size             = UDim2.new(1, 0, 0, 34)
        clearBtn.BackgroundColor3 = theme.ERROR or Color3.fromRGB(239,68,68)
        clearBtn.BackgroundTransparency = 0.2
        clearBtn.Text             = "🗑️ Limpiar Conversación"
        clearBtn.TextColor3       = Color3.fromRGB(255,255,255)
        clearBtn.TextSize         = 13
        clearBtn.Font             = Enum.Font.GothamSemibold
        clearBtn.LayoutOrder      = 3
        clearBtn.ZIndex           = 55
        clearBtn.AutoButtonColor  = false
        clearBtn.Parent           = section
        Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 10)

        clearBtn.MouseButton1Click:Connect(function()
            -- Limpiar historial
            State.messages = {}
            State.messageCount = 0
            for _, child in ipairs(Elements.chatScroll:GetChildren()) do
                if child:IsA("Frame") or child:IsA("TextLabel") then
                    child:Destroy()
                end
            end
            UI.addMessage("assistant", "Conversación limpiada. ¡Empecemos de nuevo! ¿En qué te ayudo?", "analyst")
            UI.switchTab("Chat")
        end)

        -- Botón exportar al Output
        local exportBtn = Instance.new("TextButton")
        exportBtn.Size             = UDim2.new(1, 0, 0, 34)
        exportBtn.BackgroundColor3 = theme.SUCCESS or Color3.fromRGB(52, 211, 153)
        exportBtn.BackgroundTransparency = 0.2
        exportBtn.Text             = "📤 Exportar al Output"
        exportBtn.TextColor3       = Color3.fromRGB(255,255,255)
        exportBtn.TextSize         = 13
        exportBtn.Font             = Enum.Font.GothamSemibold
        exportBtn.LayoutOrder      = 4
        exportBtn.ZIndex           = 55
        exportBtn.AutoButtonColor  = false
        exportBtn.Parent           = section
        Instance.new("UICorner", exportBtn).CornerRadius = UDim.new(0, 10)

        exportBtn.MouseButton1Click:Connect(function()
            print("\n========== KAELEN - EXPORTACIÓN DE CONVERSACIÓN ==========")
            for i, msg in ipairs(State.messages) do
                print(string.format("[%d] %s:\n%s\n", i, msg.role:upper(), msg.content))
            end
            print("==========================================================\n")
            StarterGui:SetCore("SendNotification", {
                Title   = "Kaelen",
                Text    = "Conversación exportada al Output de Studio!",
                Duration = 3,
            })
        end)
    end)
end

-- Helper: crear sección de configuración
function UI.createConfigSection(parent, title, order, contentFn)
    local theme = State.theme

    local section = Instance.new("Frame")
    section.Size              = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize     = Enum.AutomaticSize.Y
    section.BackgroundColor3  = theme.BG_CARD
    section.LayoutOrder       = order
    section.ZIndex            = 53
    section.Parent            = parent
    Instance.new("UICorner", section).CornerRadius = UDim.new(0, 14)

    local secLayout = Instance.new("UIListLayout")
    secLayout.FillDirection = Enum.FillDirection.Vertical
    secLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    secLayout.Padding       = UDim.new(0, 8)
    secLayout.Parent        = section

    local secPad = Instance.new("UIPadding")
    secPad.PaddingAll = UDim.new(0, 12)
    secPad.Parent     = section

    local secTitle = Instance.new("TextLabel")
    secTitle.Size              = UDim2.new(1, 0, 0, 20)
    secTitle.BackgroundTransparency = 1
    secTitle.Text              = title
    secTitle.TextColor3        = theme.TEXT_PRIMARY
    secTitle.TextSize          = 13
    secTitle.Font              = Enum.Font.GothamBold
    secTitle.TextXAlignment    = Enum.TextXAlignment.Left
    secTitle.LayoutOrder       = 1
    secTitle.ZIndex            = 54
    secTitle.Parent            = section

    contentFn(section)
    return section
end

-- Helper: label de configuración
function UI.createConfigLabel(parent, text, order)
    local label = Instance.new("TextLabel")
    label.Size              = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text              = text
    label.TextColor3        = State.theme.TEXT_SECONDARY
    label.TextSize          = 11
    label.Font              = Enum.Font.Gotham
    label.TextXAlignment    = Enum.TextXAlignment.Left
    label.LayoutOrder       = order
    label.ZIndex            = 54
    label.Parent            = parent
    return label
end

-- ============================================================
-- SISTEMA DE NOTIFICACIONES
-- ============================================================
function UI.createNotificationSystem(parent)
    local notifFrame = Instance.new("Frame")
    notifFrame.Name             = "NotifFrame"
    notifFrame.Size             = UDim2.new(0, 260, 0, 0)
    notifFrame.Position         = UDim2.new(0.5, -130, 0, 20)
    notifFrame.BackgroundTransparency = 1
    notifFrame.AutomaticSize   = Enum.AutomaticSize.Y
    notifFrame.ZIndex          = 200
    notifFrame.Parent          = parent
    Elements.notifFrame = notifFrame
end

function UI.showNotif(message, type)
    local colors = {
        info    = State.accent.main,
        success = Color3.fromRGB(52, 211, 153),
        error   = Color3.fromRGB(239, 68, 68),
        warning = Color3.fromRGB(245, 158, 11),
    }

    local notif = Instance.new("Frame")
    notif.Size              = UDim2.new(1, 0, 0, 40)
    notif.BackgroundColor3  = State.theme.BG_CARD
    notif.BackgroundTransparency = 0.1
    notif.ZIndex            = 201
    notif.Parent            = Elements.notifFrame
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)

    local colorBar = Instance.new("Frame")
    colorBar.Size             = UDim2.new(0, 4, 1, -8)
    colorBar.Position         = UDim2.new(0, 8, 0, 4)
    colorBar.BackgroundColor3 = colors[type] or State.accent.main
    colorBar.ZIndex           = 202
    colorBar.Parent           = notif
    Instance.new("UICorner", colorBar).CornerRadius = UDim.new(1, 0)

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size              = UDim2.new(1, -24, 1, 0)
    msgLabel.Position          = UDim2.new(0, 20, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text              = message
    msgLabel.TextColor3        = State.theme.TEXT_PRIMARY
    msgLabel.TextSize          = 12
    msgLabel.Font              = Enum.Font.Gotham
    msgLabel.TextWrapped       = true
    msgLabel.ZIndex            = 202
    msgLabel.Parent            = notif

    -- Animación entrada
    notif.BackgroundTransparency = 1
    msgLabel.TextTransparency = 1
    Utils.createTween(notif, {BackgroundTransparency = 0.1}, 0.3):Play()
    Utils.createTween(msgLabel, {TextTransparency = 0}, 0.3):Play()

    task.delay(3, function()
        Utils.createTween(notif, {BackgroundTransparency = 1}, 0.3):Play()
        Utils.createTween(msgLabel, {TextTransparency = 1}, 0.3):Play()
        task.wait(0.3)
        notif:Destroy()
    end)
end

-- ============================================================
-- LÓGICA PRINCIPAL: ABRIR/CERRAR/ENVIAR
-- ============================================================
function UI.toggleWindow()
    if State.isOpen then
        UI.closeWindow()
    else
        UI.openWindow()
    end
end

function UI.openWindow()
    State.isOpen = true
    local win = Elements.mainWindow

    -- Posicionar cerca del botón
    local btnPos  = Elements.btnContainer.Position
    local viewport = workspace.CurrentCamera.ViewportSize

    local winX = btnPos.X.Offset - 370
    local winY = btnPos.Y.Offset - 290

    -- Mantener en pantalla
    winX = math.clamp(winX, 10, viewport.X - 370)
    winY = math.clamp(winY, 10, viewport.Y - 590)

    win.Position = UDim2.new(0, winX, 0, winY)
    win.Size     = UDim2.new(0, 0, 0, 0)
    win.Visible  = true

    Utils.createTween(win, {Size = UDim2.new(0, 360, 0, 580)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()

    -- Animar icono del botón
    Utils.createTween(Elements.btnIcon, {TextTransparency = 0.3}, 0.2):Play()
end

function UI.closeWindow()
    State.isOpen = false
    local win = Elements.mainWindow

    local tween = Utils.createTween(win, {Size = UDim2.new(0, 0, 0, 0)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    tween:Play()
    tween.Completed:Connect(function()
        win.Visible = false
    end)

    Utils.createTween(Elements.btnIcon, {TextTransparency = 0}, 0.2):Play()
end

-- Enviar mensaje al AI
function UI.sendMessage(text)
    text = text and text:match("^%s*(.-)%s*$") or "" -- trim

    if text == "" then return end
    if State.isThinking then
        UI.showNotif("Kaelen está pensando, espera un momento...", "warning")
        return
    end

    -- Mostrar mensaje del usuario
    UI.addMessage("user", text, nil)

    -- Limpiar input
    Elements.textBox.Text = ""

    -- Mostrar indicador de pensando
    UI.showThinking(true)

    -- Deshabilitar botón enviar
    Elements.sendBtn.BackgroundTransparency = 0.5

    -- Llamar a la IA
    KaelenAI.think(
        text,
        State.messages,
        State.currentMode,
        State.customSysPrompt,
        function(response, err, modelType)
            -- Ocultar "pensando"
            UI.showThinking(false)

            -- Rehabilitar botón
            Elements.sendBtn.BackgroundTransparency = 0

            if err then
                UI.addMessage("assistant",
                    "⚠️ Error al conectar con la IA:\n" .. err ..
                    "\n\nVerifica que:\n1. Tu API Key de OpenRouter sea válida\n2. HttpService esté habilitado en el juego",
                    "analyst"
                )
                UI.showNotif("Error de conexión con la IA", "error")
            else
                local formattedResponse = Utils.formatCode(response or "Sin respuesta")
                UI.addMessage("assistant", formattedResponse, modelType)
            end
        end
    )
end

-- ============================================================
-- COMANDO RÁPIDO: Analizar contexto completo del juego
-- ============================================================
local function analyzeFullGame()
    if State.isThinking then return end

    local context = Utils.getGameContext()

    -- Obtener errores recientes de scripts
    local scriptErrors = {}
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("Script") or desc:IsA("LocalScript") then
            table.insert(scriptErrors, "- " .. desc:GetFullName())
        end
    end

    local fullContext = context
    if #scriptErrors > 0 then
        fullContext = fullContext .. "\n\n[SCRIPTS ENCONTRADOS]\n" .. table.concat(scriptErrors, "\n"):sub(1, 500)
    end

    local msg = "Haz un análisis completo de desarrollo de mi juego. Identifica posibles problemas, errores de scripts, y dame recomendaciones específicas para mejorar:\n\n" .. fullContext

    UI.sendMessage(msg)
end

-- ============================================================
-- INICIALIZACIÓN FINAL
-- ============================================================

-- Verificar HttpService
local httpEnabled = false
pcall(function()
    httpEnabled = HttpService.HttpEnabled
end)

-- Esperar a que el jugador cargue completamente
player.CharacterAdded:Wait()
task.wait(1)

-- Inicializar UI
local gui = UI.init()

-- Mensaje de inicio en Output
print("╔═══════════════════════════════════════╗")
print("║           KAELEN AI v" .. CONFIG.VERSION .. "             ║")
print("║   Asistente IA Premium para Roblox    ║")
print("║  Qwen3 Coder + Llama 3.3 70B          ║")
print("╚═══════════════════════════════════════╝")

if CONFIG.OPENROUTER_API_KEY == "TU_API_KEY_AQUI" then
    print("⚠️  ADVERTENCIA: Configura tu API Key de OpenRouter en CONFIG.OPENROUTER_API_KEY")
    warn("Kaelen: API Key no configurada. Ve a la línea de CONFIG y pon tu clave de OpenRouter.")
else
    print("✅ Kaelen inicializado correctamente.")
    print("📡 API Key configurada.")
end

if not httpEnabled then
    warn("Kaelen: HttpService no está habilitado. Actívalo en Game Settings > Security.")
end

print("💡 Tip: Presiona el botón flotante 'K' para abrir Kaelen.")
print("═══════════════════════════════════════════")

-- ============================================================
-- FIN DEL SCRIPT KAELEN
-- ============================================================
