--[[
    ===========================================================================
    ██╗  ██╗ █████╗ ███████╗██╗     ███████╗███╗   ██╗
    ██║ ██╔╝██╔══██╗██╔════╝██║     ██╔════╝████╗  ██║
    █████╔╝ ███████║█████╗  ██║     █████╗  ██╔██╗ ██║
    ██╔═██╗ ██╔══██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║
    ██║  ██╗██║  ██║███████╗███████╗███████╗██║ ╚████║
    ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝
    
    KAELEN AI - ADVANCED ORCHESTRATOR FOR ROBLOX (MOBILE EDITION)
    Version: 2.3 Premium (Uncompressed & Robust Architecture)
    Engines: Qwen3-Coder (Scripts), Llama 3.3 (Analysis), Gemma 3 (Fast Actions)
    ===========================================================================
]]

-- ============================================================================
-- 1. SERVICIOS PRINCIPALES DEL SISTEMA (CARGA SEGURA)
-- ============================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local StatsService = game:GetService("Stats")

-- ============================================================================
-- 2. VARIABLES DE ENTORNO LOCALES
-- ============================================================================
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Aseguramos que el jugador y el personaje estén listos
if not LocalPlayer then
    warn("[Kaelen] LocalPlayer no encontrado. Esperando...")
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ============================================================================
-- 3. LIMPIEZA DE INSTANCIAS ANTERIORES (ANTI-DUPLICACIÓN)
-- ============================================================================
local function CleanupPreviousInstances()
    print("[Kaelen] Iniciando protocolo de limpieza de UI...")
    
    -- Limpiar en CoreGui
    local successCore, errCore = pcall(function()
        local oldUI = CoreGui:FindFirstChild("KaelenUI")
        if oldUI then
            oldUI:Destroy()
            print("[Kaelen] UI anterior eliminada de CoreGui.")
        end
    end)
    
    if not successCore then
        warn("[Kaelen] No se pudo acceder a CoreGui: " .. tostring(errCore))
    end
    
    -- Limpiar en PlayerGui (Fallback seguro para Delta)
    local successPlayer, errPlayer = pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local oldUI = playerGui:FindFirstChild("KaelenUI")
            if oldUI then
                oldUI:Destroy()
                print("[Kaelen] UI anterior eliminada de PlayerGui.")
            end
        end
    end)
    
    if not successPlayer then
        warn("[Kaelen] No se pudo limpiar PlayerGui: " .. tostring(errPlayer))
    end
end

CleanupPreviousInstances()

-- ============================================================================
-- 4. CONFIGURACIÓN GLOBAL (ESTRUCTURA EXPANDIDA)
-- ============================================================================
local CFG = {}
CFG.Version = "2.3 Premium"
CFG.Author = "Kaelen Systems"
CFG.OpenRouterURL = "https://openrouter.ai/api/v1/chat/completions"

-- Modelos de Inteligencia Artificial
CFG.Models = {}
CFG.Models.Coder = "qwen/qwen3-coder:free"
CFG.Models.Reason = "meta-llama/llama-3.3-70b-instruct:free"
CFG.Models.Fast = "google/gemma-3-27b-it:free"

-- Parámetros de la API
CFG.API = {}
CFG.API.MaxTokens = 1800
CFG.API.Temperature = 0.72
CFG.API.MaxHistory = 50

-- Dimensiones de la Ventana (Optimizadas para Mobile)
CFG.Window = {}
CFG.Window.Width = 440
CFG.Window.Height = 300

-- Paleta de Colores Profesionales
CFG.Colors = {}
CFG.Colors.Background = Color3.fromRGB(8, 8, 18)
CFG.Colors.Surface = Color3.fromRGB(15, 14, 30)
CFG.Colors.Card = Color3.fromRGB(21, 20, 40)
CFG.Colors.CardHighlight = Color3.fromRGB(30, 27, 58)
CFG.Colors.Border = Color3.fromRGB(52, 47, 100)
CFG.Colors.BorderHighlight = Color3.fromRGB(100, 68, 222)
CFG.Colors.Accent = Color3.fromRGB(112, 72, 255)
CFG.Colors.AccentDim = Color3.fromRGB(72, 42, 175)
CFG.Colors.AccentGlow = Color3.fromRGB(158, 118, 255)
CFG.Colors.UserBubble = Color3.fromRGB(92, 52, 232)
CFG.Colors.AIBubble = Color3.fromRGB(20, 19, 40)

-- Colores de Texto
CFG.Colors.Text = Color3.fromRGB(226, 222, 255)
CFG.Colors.TextMuted = Color3.fromRGB(118, 112, 172)
CFG.Colors.TextDim = Color3.fromRGB(72, 68, 128)

-- Colores de Estado
CFG.Colors.Success = Color3.fromRGB(68, 212, 132)
CFG.Colors.Danger = Color3.fromRGB(255, 72, 98)
CFG.Colors.Warning = Color3.fromRGB(255, 198, 68)
CFG.Colors.White = Color3.fromRGB(255, 255, 255)
CFG.Colors.Black = Color3.fromRGB(0, 0, 0)

-- Fuentes de Texto
CFG.Fonts = {}
CFG.Fonts.Bold = Enum.Font.GothamBold
CFG.Fonts.Regular = Enum.Font.Gotham
CFG.Fonts.Monospace = Enum.Font.Code

-- ============================================================================
-- 5. GESTOR DE ESTADO DEL SISTEMA (STATE MANAGER)
-- ============================================================================
local AppState = {}
AppState.APIKey = ""
AppState.KeyVerified = false
AppState.WindowOpen = false
AppState.IsThinking = false
AppState.Messages = {}
AppState.CurrentMode = "Analista"
AppState.CustomSystemPrompt = ""
AppState.ThinkTaskThread = nil
AppState.MessageCount = 0

-- Estados del Motor de Hacks/Comandos
AppState.Engine = {}
AppState.Engine.IsFlying = false
AppState.Engine.FlyConnection = nil
AppState.Engine.IsNoclipping = false
AppState.Engine.NoclipConnection = nil

-- Estados de Arrastre de Interfaz (Drag)
AppState.Drag = {}
AppState.Drag.ButtonDragging = false
AppState.Drag.ButtonDragOrigin = Vector2.new(0, 0)
AppState.Drag.ButtonPosOrigin = UDim2.new(0, 0, 0, 0)
AppState.Drag.ButtonTotalMoved = 0

AppState.Drag.WindowDragging = false
AppState.Drag.WindowDragOrigin = Vector2.new(0, 0)
AppState.Drag.WindowPosOrigin = UDim2.new(0, 0, 0, 0)

-- ============================================================================
-- 6. UTILIDADES DE INTERFAZ GRÁFICA (UI FRAMEWORK EXPANDIDO)
-- ============================================================================

--[[
    @function CreateTween
    @description Crea y reproduce una animación suave para un objeto.
    @param {Instance} object El objeto a animar.
    @param {table} properties Las propiedades a cambiar.
    @param {number} time Duración de la animación.
    @param {Enum.EasingStyle} style Estilo de la animación.
    @param {Enum.EasingDirection} direction Dirección de la animación.
]]
local function CreateTween(object, properties, duration, style, direction)
    if not object then return nil end
    
    local tweenInfo = TweenInfo.new(
        duration or 0.28,
        style or Enum.EasingStyle.Quart,
        direction or Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

--[[
    @function ApplyCorner
    @description Aplica bordes redondeados a un elemento de UI.
]]
local function ApplyCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    corner.Parent = parent
    return corner
end

--[[
    @function ApplyStroke
    @description Aplica un borde de color a un elemento de UI.
]]
local function ApplyStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or CFG.Colors.Border
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

--[[
    @function ApplyPadding
    @description Aplica márgenes internos a un elemento.
]]
local function ApplyPadding(parent, top, bottom, left, right)
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, top or 8)
    padding.PaddingBottom = UDim.new(0, bottom or 8)
    padding.PaddingLeft = UDim.new(0, left or 8)
    padding.PaddingRight = UDim.new(0, right or 8)
    padding.Parent = parent
    return padding
end

--[[
    @function CreateVerticalLayout
    @description Organiza los elementos hijos en una lista vertical.
]]
local function CreateVerticalLayout(parent, padding, horizontalAlignment)
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, padding or 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

--[[
    @function CreateHorizontalLayout
    @description Organiza los elementos hijos en una lista horizontal.
]]
local function CreateHorizontalLayout(parent, padding, verticalAlignment)
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = verticalAlignment or Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, padding or 0)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = parent
    return layout
end

--[[
    @function ApplyGradient
    @description Aplica un degradado de color a un fondo o texto.
]]
local function ApplyGradient(parent, colorStart, colorEnd, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorStart),
        ColorSequenceKeypoint.new(1, colorEnd),
    })
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

-- ============================================================================
-- 7. CLASES CONSTRUCTORAS DE UI (ALTO RENDIMIENTO)
-- ============================================================================

local function UI_Frame(parent, size, position, backgroundColor, transparency, zIndex, name)
    local frame = Instance.new("Frame")
    frame.Size = size or UDim2.new(1, 0, 1, 0)
    frame.Position = position or UDim2.new(0, 0, 0, 0)
    frame.BackgroundColor3 = backgroundColor or CFG.Colors.Card
    frame.BackgroundTransparency = transparency or 0
    frame.ZIndex = zIndex or 2
    frame.BorderSizePixel = 0
    if name then
        frame.Name = name
    end
    frame.Parent = parent
    return frame
end

local function UI_TextLabel(parent, size, position, text, color, textSize, font, horizontalAlign, zIndex)
    local label = Instance.new("TextLabel")
    label.Size = size or UDim2.new(1, 0, 0, 20)
    label.Position = position or UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = color or CFG.Colors.Text
    label.TextSize = textSize or 13
    label.Font = font or CFG.Fonts.Regular
    label.TextXAlignment = horizontalAlign or Enum.TextXAlignment.Left
    label.ZIndex = zIndex or 2
    label.TextWrapped = true
    label.BorderSizePixel = 0
    label.Parent = parent
    return label
end

local function UI_TextButton(parent, size, position, backgroundColor, text, textColor, textSize, font, zIndex)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.new(1, 0, 0, 40)
    button.Position = position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = backgroundColor or CFG.Colors.Accent
    button.Text = text or ""
    button.TextColor3 = textColor or CFG.Colors.White
    button.TextSize = textSize or 13
    button.Font = font or CFG.Fonts.Bold
    button.ZIndex = zIndex or 2
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.Parent = parent
    return button
end

local function UI_ScrollingFrame(parent, size, position, zIndex)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = size or UDim2.new(1, 0, 1, 0)
    scroll.Position = position or UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = CFG.Colors.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ZIndex = zIndex or 2
    scroll.BorderSizePixel = 0
    scroll.Parent = parent
    return scroll
end

-- ============================================================================
-- 8. MOTOR FÍSICO DE COMANDOS DEL JUGADOR (KAELEN ENGINE)
-- ============================================================================

--[[
    @function ActivateFly
    @description Activa o desactiva el modo de vuelo avanzado usando físicas.
    @param {boolean} state True para volar, False para caminar.
]]
local function ActivateFly(state)
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    AppState.Engine.IsFlying = state
    
    if state then
        -- Evitar múltiples conexiones
        if AppState.Engine.FlyConnection then return end
        
        print("[Kaelen Engine] Iniciando propulsor de vuelo...")
        
        -- Crear estabilizador de gravedad (BodyVelocity)
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "KaelenFlyVelocity"
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Parent = humanoidRootPart
        
        -- Crear estabilizador de rotación (BodyGyro)
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "KaelenFlyGyro"
        bodyGyro.P = 90000
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = humanoidRootPart.CFrame
        bodyGyro.Parent = humanoidRootPart
        
        -- Bucle de control asíncrono atado al RenderStepped
        AppState.Engine.FlyConnection = RunService.RenderStepped:Connect(function()
            local cameraCFrame = Camera.CFrame
            local moveDirection = Vector3.new(0, 0, 0)
            
            -- Detectar entradas de teclado (Soporte para PC si se usa)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
                moveDirection = moveDirection + Vector3.new(0, 0, -1) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
                moveDirection = moveDirection + Vector3.new(0, 0, 1) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
                moveDirection = moveDirection + Vector3.new(-1, 0, 0) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
                moveDirection = moveDirection + Vector3.new(1, 0, 0) 
            end
            
            -- Control de altura
            local verticalMovement = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                verticalMovement = 1
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                verticalMovement = -1
            end
            
            -- Calcular vector final
            local finalVelocity = (cameraCFrame.RightVector * moveDirection.X) + 
                                  (cameraCFrame.LookVector * moveDirection.Z) + 
                                  Vector3.new(0, verticalMovement, 0)
                                  
            -- Aplicar velocidad (Multiplicador de 50)
            bodyVelocity.Velocity = finalVelocity * 50
            bodyGyro.CFrame = cameraCFrame
        end)
    else
        print("[Kaelen Engine] Apagando propulsor de vuelo...")
        
        -- Limpiar componentes físicos
        local oldVelocity = humanoidRootPart:FindFirstChild("KaelenFlyVelocity")
        if oldVelocity then oldVelocity:Destroy() end
        
        local oldGyro = humanoidRootPart:FindFirstChild("KaelenFlyGyro")
        if oldGyro then oldGyro:Destroy() end
        
        -- Desconectar bucle
        if AppState.Engine.FlyConnection then
            AppState.Engine.FlyConnection:Disconnect()
            AppState.Engine.FlyConnection = nil
        end
    end
end

--[[
    @function ActivateNoclip
    @description Desactiva la colisión de todas las partes del personaje de forma continua.
    @param {boolean} state True para atravesar paredes, False para normal.
]]
local function ActivateNoclip(state)
    AppState.Engine.IsNoclipping = state
    
    if state then
        -- Evitar múltiples conexiones
        if AppState.Engine.NoclipConnection then return end
        
        print("[Kaelen Engine] Fase de colisión desactivada (Noclip ON)")
        
        -- Usar Stepped porque corre justo antes del cálculo de físicas del motor
        AppState.Engine.NoclipConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                -- Recorrer todas las partes del personaje de manera recursiva
                local descendants = character:GetDescendants()
                for i = 1, #descendants do
                    local part = descendants[i]
                    if part:IsA("BasePart") then
                        -- Forzar CanCollide a false en cada frame
                        if part.CanCollide == true then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    else
        print("[Kaelen Engine] Fase de colisión restaurada (Noclip OFF)")
        
        -- Desconectar el bucle
        if AppState.Engine.NoclipConnection then
            AppState.Engine.NoclipConnection:Disconnect()
            AppState.Engine.NoclipConnection = nil
        end
        
        -- Restaurar colisiones básicas para evitar caer por el mapa
        local character = LocalPlayer.Character
        if character then
            local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
            local head = character:FindFirstChild("Head")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if torso then torso.CanCollide = true end
            if head then head.CanCollide = true end
            if hrp then hrp.CanCollide = true end
        end
    end
end

--[[
    @function ProcessAIActionCommands
    @description Analiza la respuesta de la IA en busca de comandos ejecutables y los aplica.
    @param {string} text El mensaje devuelto por la IA.
]]
local function ProcessAIActionCommands(text)
    if not text or type(text) ~= "string" then return end
    
    local character = LocalPlayer.Character
    local humanoid = nil
    
    if character then
        humanoid = character:FindFirstChildOfClass("Humanoid")
    end
    
    -- Comando: Noclip
    if string.match(text, "%[NOCLIP:on%]") then
        ActivateNoclip(true)
    end
    
    if string.match(text, "%[NOCLIP:off%]") then
        ActivateNoclip(false)
    end
    
    -- Comando: Vuelo
    if string.match(text, "%[FLY:on%]") then
        ActivateFly(true)
    end
    
    if string.match(text, "%[FLY:off%]") then
        ActivateFly(false)
    end
    
    -- Comandos que requieren el Humanoid
    if humanoid then
        -- Comando: Velocidad
        local speedMatch = string.match(text, "%[SPEED:(%d+)%]")
        if speedMatch then
            local speedValue = tonumber(speedMatch)
            if speedValue then
                humanoid.WalkSpeed = speedValue
                print("[Kaelen Engine] Velocidad ajustada a: " .. tostring(speedValue))
            end
        end
        
        -- Comando: Salto
        local jumpMatch = string.match(text, "%[JUMP:(%d+)%]")
        if jumpMatch then
            local jumpValue = tonumber(jumpMatch)
            if jumpValue then
                humanoid.UseJumpPower = true
                humanoid.JumpPower = jumpValue
                print("[Kaelen Engine] Poder de salto ajustado a: " .. tostring(jumpValue))
            end
        end
        
        -- Comando: Curación
        if string.match(text, "%[HEAL%]") then
            humanoid.Health = humanoid.MaxHealth
            print("[Kaelen Engine] Personaje curado al máximo.")
        end
    end
end

-- ============================================================================
-- 9. GESTIÓN DE PROMPTS Y CONTEXTO
-- ============================================================================

local SYSTEM_INSTRUCTIONS_COMMANDS = [[
=========================================
INSTRUCCIONES CRÍTICAS DE CONTROL DEL JUEGO:
Como IA asistente, tienes acceso DIRECTO al motor del juego del usuario.
Si el usuario te pide que modifiques su personaje, altera la gravedad, o active algún modo, DEBES responder incluyendo UNA de las siguientes etiquetas exactas en tu respuesta:

1. Volar: Usa [FLY:on] para activar el vuelo, o [FLY:off] para desactivarlo.
2. Atravesar paredes (Noclip): Usa [NOCLIP:on] para activar el noclip, o [NOCLIP:off] para desactivarlo.
3. Cambiar velocidad: Usa [SPEED:numero] (por ejemplo [SPEED:120] para hacerlo muy rápido).
4. Cambiar salto: Usa [JUMP:numero] (por ejemplo [JUMP:200] para saltar muy alto).
5. Curar vida: Usa [HEAL] para regenerar la salud del jugador al 100%.

REGLA: Confirma amigablemente que has ejecutado la acción e inserta la etiqueta al final.
=========================================
]]

local SYSTEM_PROMPTS = {}

SYSTEM_PROMPTS.Programador = [[
Eres Kaelen, el experto definitivo en programación Lua para Roblox con más de 15 años de experiencia.
MISIÓN: Crear, optimizar, analizar y debugear scripts Lua con calidad de nivel AAA.

REGLAS DE PROGRAMACIÓN:
- Proporciona código limpio, altamente modular y exhaustivamente comentado.
- Utiliza las mejores prácticas modernas de Luau (task.spawn, task.delay, módulos robustos).
- Si detectas una vulnerabilidad o un yield innecesario, corrígelo y explícalo detalladamente.
- Siempre encapsula el código en bloques Markdown correctos.
]] .. SYSTEM_INSTRUCTIONS_COMMANDS

SYSTEM_PROMPTS.Analista = [[
Eres Kaelen, el analista de seguridad y arquitectura de sistemas Roblox más prestigioso.
MISIÓN: Analizar profunda y meticulosamente las mecánicas, detectar vulnerabilidades (exploits) y evaluar el rendimiento del cliente y servidor.

REGLAS DE ANÁLISIS:
- Estructura tus análisis con títulos claros (Arquitectura, Vulnerabilidades, Rendimiento).
- Prioriza los problemas por severidad (Crítica, Alta, Media, Baja).
- Sé directo, técnico y proporciona soluciones accionables.
]] .. SYSTEM_INSTRUCTIONS_COMMANDS

SYSTEM_PROMPTS.Creativo = [[
Eres Kaelen, un genio creativo y Game Designer especializado en experiencias únicas para Roblox.
MISIÓN: Concebir ideas revolucionarias, mecánicas originales y sistemas de retención de jugadores.

REGLAS DE DISEÑO:
- Piensa fuera de los estándares tradicionales.
- Detalla los bucles de juego (Core Game Loops) y ganchos de monetización de forma ética.
- Sé sumamente descriptivo y entusiasta en tus propuestas.
]] .. SYSTEM_INSTRUCTIONS_COMMANDS

SYSTEM_PROMPTS.Troll = [[
Eres Kaelen en modo "Troll", un maestro del caos y la diversión inofensiva.
MISIÓN: Sugerir ideas graciosas, trolleos y situaciones cómicas.

REGLAS DE DIVERSIÓN:
- TODO debe mantenerse dentro de los límites del motor y ser ejecutable en el juego.
- Sugiere formas creativas de confundir a los NPCs o interactuar graciosamente con las físicas.
]] .. SYSTEM_INSTRUCTIONS_COMMANDS

--[[
    @function CollectGameContext
    @description Recopila información técnica del servidor y cliente actual para la IA.
]]
local function CollectGameContext()
    local contextData = {}
    
    -- Recolección segura mediante pcalls para evitar que errores detengan el script
    pcall(function() contextData.GameName = game.Name end)
    pcall(function() contextData.PlaceId = tostring(game.PlaceId) end)
    pcall(function() contextData.JobId = game.JobId end)
    
    pcall(function() 
        local playersList = Players:GetPlayers()
        contextData.PlayerCount = tostring(#playersList) 
    end)
    
    pcall(function() 
        contextData.MyName = LocalPlayer.Name 
        contextData.MyUserId = tostring(LocalPlayer.UserId)
    end)
    
    local successJson, jsonOutput = pcall(function()
        return HttpService:JSONEncode(contextData)
    end)
    
    if successJson then
        return jsonOutput
    else
        return "{ \"error\": \"No se pudo serializar el contexto del juego\" }"
    end
end

-- ============================================================================
-- 10. MÓDULO DE RED (HTTP / OPENROUTER API V2)
--     CON SOPORTE EXTENDIDO PARA MULTIPLES EXECUTORS Y MANEJO DE ERRORES
-- ============================================================================

--[[
    @function GetExecutorRequestFunction
    @description Busca y devuelve la función HTTP adecuada según el ejecutor que esté usando el jugador.
]]
local function GetExecutorRequestFunction()
    local requestFunctions = {
        function() return request end,
        function() return http_request end,
        function() return http and http.request end,
        function() return syn and syn.request end,
        function() return fluxus and fluxus.request end,
        function() return KRNL_request end,
        function() return getgenv and getgenv().request end,
    }
    
    for i = 1, #requestFunctions do
        local success, func = pcall(requestFunctions[i])
        if success and type(func) == "function" then
            print("[Kaelen Network] Función de petición HTTP detectada exitosamente.")
            return func
        end
    end
    
    warn("[Kaelen Network] ¡CRÍTICO! Ninguna función HTTP compatible fue encontrada en el ejecutor.")
    return nil
end

--[[
    @function ExecuteApiCall
    @description Ejecuta la petición POST a OpenRouter con validación y manejo de errores extremo.
    @param {string} modelId El identificador del modelo (ej. qwen/qwen3-coder)
    @param {table} messageHistory El historial de mensajes.
    @param {string} systemPrompt Las instrucciones del sistema.
]]
local function ExecuteApiCall(modelId, messageHistory, systemPrompt)
    -- Validación 1: Verificar si hay API Key
    if not AppState.KeyVerified or AppState.APIKey == "" or AppState.APIKey == nil then
        return nil, "Sistema bloqueado: La API Key no ha sido validada."
    end
    
    -- Validación 2: Obtener el cliente HTTP
    local httpClient = GetExecutorRequestFunction()
    if not httpClient then
        return nil, "Error fatal: Tu ejecutor de scripts (Delta/Arceus/etc) no soporta peticiones HTTP web ('request')."
    end

    -- Preparar el arreglo de mensajes final
    local payloadMessages = {}
    
    -- Insertar el prompt del sistema si existe
    if systemPrompt and type(systemPrompt) == "string" and string.len(systemPrompt) > 0 then
        table.insert(payloadMessages, {
            role = "system",
            content = systemPrompt
        })
    end
    
    -- Copiar el historial de usuario
    for i = 1, #messageHistory do
        local msg = messageHistory[i]
        if msg and msg.role and msg.content then
            table.insert(payloadMessages, {
                role = msg.role,
                content = msg.content
            })
        end
    end

    -- Construir el cuerpo de la petición (Payload)
    local requestPayload = {
        model = modelId,
        max_tokens = CFG.API.MaxTokens,
        temperature = CFG.API.Temperature,
        messages = payloadMessages
    }

    -- Codificar a JSON de manera segura
    local successEncode, jsonBody = pcall(function()
        return HttpService:JSONEncode(requestPayload)
    end)
    
    if not successEncode then
        return nil, "Error interno: Falló la codificación JSON del payload."
    end

    -- Cabeceras (Headers)
    -- NOTA: Algunos ejecutores móviles como Delta fallan si pasas headers raros.
    -- Vamos a mantenerlo al estándar estricto requerido por OpenRouter.
    local requestHeaders = {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. tostring(AppState.APIKey)
    }

    print("[Kaelen Network] Enviando petición a OpenRouter (Modelo: " .. tostring(modelId) .. ")...")

    -- Ejecutar la petición HTTP protegida con pcall
    local successHttp, response = pcall(function()
        return httpClient({
            Url = CFG.OpenRouterURL,
            Method = "POST",
            Headers = requestHeaders,
            Body = jsonBody
        })
    end)

    -- Manejo de Errores Nivel 1: Falla en la ejecución del método
    if not successHttp then
        local errorDetail = tostring(response)
        warn("[Kaelen Network] Petición HTTP rechazada por el ejecutor: " .. errorDetail)
        return nil, "El ejecutor bloqueó la conexión: " .. errorDetail
    end

    -- Manejo de Errores Nivel 2: Respuesta nula
    if type(response) ~= "table" then
        warn("[Kaelen Network] La respuesta HTTP no es una tabla válida.")
        return nil, "Respuesta corrupta del servidor (No es una tabla)."
    end

    -- Manejo de Errores Nivel 3: Códigos de Estado HTTP
    local statusCode = response.StatusCode
    if statusCode ~= 200 then
        local httpErrorMsg = "Código HTTP " .. tostring(statusCode)
        
        -- Intentar extraer el mensaje de error de OpenRouter si existe
        local successExtract, parsedError = pcall(function()
            local decoded = HttpService:JSONDecode(response.Body)
            if decoded and decoded.error and decoded.error.message then
                return decoded.error.message
            end
            return nil
        end)
        
        if successExtract and parsedError then
            httpErrorMsg = httpErrorMsg .. " - " .. tostring(parsedError)
        else
            httpErrorMsg = httpErrorMsg .. " - Error desconocido del servidor."
        end
        
        warn("[Kaelen Network] Petición fallida: " .. httpErrorMsg)
        return nil, httpErrorMsg
    end

    -- Procesamiento de Respuesta Exitosa
    local successDecode, finalData = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not successDecode then
        warn("[Kaelen Network] Error decodificando el JSON de respuesta exitosa.")
        return nil, "El servidor respondió, pero el JSON estaba corrupto."
    end
    
    -- Extraer el texto generado
    if finalData and finalData.choices and type(finalData.choices) == "table" then
        local firstChoice = finalData.choices[1]
        if firstChoice and firstChoice.message and firstChoice.message.content then
            print("[Kaelen Network] Respuesta recibida correctamente.")
            return firstChoice.message.content, nil
        end
    end
    
    return nil, "La API respondió, pero no incluyó ningún texto válido en la estructura."
end

-- ============================================================================
-- 11. SISTEMA DE VERIFICACIÓN DE CLAVES (CON BYPASS PARA DELTA)
-- ============================================================================

--[[
    @function TestAPIKeyVerification
    @description Realiza una llamada HTTP mínima para comprobar si la Key es válida.
]]
local function TestAPIKeyVerification(keyToTest)
    print("[Kaelen Security] Iniciando prueba de verificación de API Key...")
    
    -- Respaldo de estados actuales
    local backupKey = AppState.APIKey
    local backupVerification = AppState.KeyVerified
    
    -- Inyectar temporalmente para la prueba
    AppState.APIKey = keyToTest
    AppState.KeyVerified = true
    
    -- Intentar llamada muy básica y rápida usando Gemma
    local testMessages = {
        { role = "user", content = "Responde exactamente con la palabra: CONNECTED" }
    }
    
    local responseText, errorMessage = ExecuteApiCall(CFG.Models.Fast, testMessages, "Responde lo que se te pide.")
    
    -- Evaluar resultado
    if errorMessage then
        warn("[Kaelen Security] Prueba fallida: " .. tostring(errorMessage))
        -- Restaurar estado previo
        AppState.APIKey = backupKey
        AppState.KeyVerified = backupVerification
        return false, errorMessage
    end
    
    print("[Kaelen Security] Verificación exitosa. Respuesta: " .. tostring(responseText))
    return true, nil
end

-- ============================================================================
-- 12. ORQUESTADOR DE INTELIGENCIA ARTIFICIAL (TRIPLE ENGINE ROUTING)
-- ============================================================================

local ROUTING_KEYWORDS = {}
ROUTING_KEYWORDS.Code = {"script", "lua", "código", "codigo", "optimiza", "debug", "module", "función", "funcion"}
ROUTING_KEYWORDS.Action = {"vuela", "volar", "fly", "noclip", "atravies", "paredes", "velocidad", "speed", "salto", "jump", "cura", "heal", "vida", "activa", "pon"}

--[[
    @function CheckKeywords
    @description Verifica si un texto contiene alguna palabra clave de un diccionario.
]]
local function CheckKeywords(inputText, dictionary)
    if not inputText then return false end
    
    local lowerText = string.lower(inputText)
    for i = 1, #dictionary do
        local keyword = string.lower(dictionary[i])
        if string.find(lowerText, keyword, 1, true) then
            return true
        end
    end
    
    return false
end

--[[
    @function CoreOrchestrator
    @description El cerebro principal de Kaelen. Decide qué modelo usar basándose en el prompt.
]]
local function CoreOrchestrator(userInputText, conversationHistory)
    -- Determinar el System Prompt a usar
    local activeSystemPrompt = ""
    if AppState.CustomSystemPrompt and string.len(AppState.CustomSystemPrompt) > 0 then
        activeSystemPrompt = AppState.CustomSystemPrompt
    else
        local modePrompt = SYSTEM_PROMPTS[AppState.CurrentMode]
        if modePrompt then
            activeSystemPrompt = modePrompt
        else
            activeSystemPrompt = SYSTEM_PROMPTS.Analista
        end
    end

    -- Analizar la intención del usuario
    local isActionIntent = CheckKeywords(userInputText, ROUTING_KEYWORDS.Action)
    local isCodeIntent = CheckKeywords(userInputText, ROUTING_KEYWORDS.Code)
    
    -- Si es acción, prioriza la velocidad (Gemma-3 Fast)
    if isActionIntent then
        print("[Kaelen Orchestrator] Intención de ACCIÓN detectada. Enrutando a Gemma-3 Fast...")
        
        local fastResponse, fastError = ExecuteApiCall(CFG.Models.Fast, conversationHistory, activeSystemPrompt)
        
        if fastError then
            return nil, "Fallo en motor Fast: " .. tostring(fastError)
        end
        
        return "⚡ [Acción Rápida - Gemma 3]\n\n" .. tostring(fastResponse), nil
    end

    -- Si es código, realiza un pase dual (Qwen3 -> Llama 3.3)
    if isCodeIntent or AppState.CurrentMode == "Programador" then
        print("[Kaelen Orchestrator] Intención de CÓDIGO detectada. Iniciando pase dual (Qwen3 -> Llama)...")
        
        -- Fase 1: Generación base con Qwen3 Coder
        local coderPrompt = activeSystemPrompt .. "\n\nIMPORTANTE: Eres el módulo generador (Qwen3). Concéntrate exclusivamente en generar el código Lua funcional."
        local coderResponse, coderError = ExecuteApiCall(CFG.Models.Coder, conversationHistory, coderPrompt)
        
        if coderError then
            warn("[Kaelen Orchestrator] Falló Qwen3, intentando fallback a Llama.")
            return nil, "Error en generación de código (Coder): " .. tostring(coderError)
        end
        
        print("[Kaelen Orchestrator] Código generado exitosamente. Pasando a revisión por Llama 3.3...")
        
        -- Fase 2: Revisión y explicación con Llama 3.3
        local reviewPrompt = "Eres el módulo supervisor (Llama 3.3). Revisa el siguiente código generado por Qwen3, corrige errores si existen, y presenta el código final de forma profesional y explicada."
        local reviewMessages = {
            {
                role = "user",
                content = "El usuario pidió:\n" .. userInputText .. "\n\nY el generador produjo esto:\n```lua\n" .. tostring(coderResponse) .. "\n```\nPor favor revísalo y entrégame la versión definitiva."
            }
        }
        
        local finalResponse, reviewError = ExecuteApiCall(CFG.Models.Reason, reviewMessages, reviewPrompt)
        
        if reviewError then
            warn("[Kaelen Orchestrator] Falló la revisión de Llama, entregando código crudo de Qwen3.")
            return "⚡ [Generador Qwen3-Coder (Sin revisión)]\n\n" .. tostring(coderResponse), nil
        end
        
        return "⚡ [Orquestador Dual - Qwen3 + Llama 3.3]\n\n" .. tostring(finalResponse), nil
    end

    -- Ruta normal (Chat general, análisis, creativo)
    print("[Kaelen Orchestrator] Intención general detectada. Enrutando a Llama 3.3 70B...")
    local reasonResponse, reasonError = ExecuteApiCall(CFG.Models.Reason, conversationHistory, activeSystemPrompt)
    
    if reasonError then
        return nil, "Error en razonamiento: " .. tostring(reasonError)
    end
    
    return "⬡ [Llama 3.3 70B Reasoner]\n\n" .. tostring(reasonResponse), nil
end

-- ============================================================================
-- 13. CONSTRUCCIÓN DE LA INTERFAZ GRÁFICA (UI CONSTRUCTION)
--     DESCOMPRIMIDO Y ESTRUCTURADO PARA MAXIMA LEGIBILIDAD
-- ============================================================================
print("[Kaelen UI] Iniciando renderizado de la interfaz gráfica...")

-- Crear ScreenGui Principal
local MainScreenGui = Instance.new("ScreenGui")
MainScreenGui.Name = "KaelenUI"
MainScreenGui.ResetOnSpawn = false
MainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainScreenGui.DisplayOrder = 9999
MainScreenGui.IgnoreGuiInset = true

-- Inyección segura (Preferir CoreGui, sino PlayerGui)
local successInject = pcall(function()
    MainScreenGui.Parent = CoreGui
end)

if not successInject then
    print("[Kaelen UI] CoreGui bloqueado por Delta, inyectando en PlayerGui...")
    MainScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ----------------------------------------------------------------------------
-- Botón Flotante de Activación
-- ----------------------------------------------------------------------------
local FloatingButton = Instance.new("ImageButton")
FloatingButton.Name = "FloatBtn"
FloatingButton.Size = UDim2.new(0, 48, 0, 48)
FloatingButton.Position = UDim2.new(1, -60, 0.6, -24)
FloatingButton.BackgroundColor3 = CFG.Colors.Accent
FloatingButton.Image = ""
FloatingButton.AutoButtonColor = false
FloatingButton.ZIndex = 500
FloatingButton.BorderSizePixel = 0
FloatingButton.Parent = MainScreenGui

ApplyCorner(FloatingButton, 24)
ApplyStroke(FloatingButton, CFG.Colors.AccentGlow, 2)
ApplyGradient(FloatingButton, Color3.fromRGB(135, 92, 255), Color3.fromRGB(88, 48, 205), 135)

-- Efecto de resplandor (Glow) para el botón
local ButtonGlowEffect = Instance.new("ImageLabel")
ButtonGlowEffect.Name = "GlowEffect"
ButtonGlowEffect.Size = UDim2.new(0, 80, 0, 80)
ButtonGlowEffect.Position = UDim2.new(0.5, -40, 0.5, -40)
ButtonGlowEffect.BackgroundTransparency = 1
ButtonGlowEffect.Image = "rbxassetid://5028857084"
ButtonGlowEffect.ImageColor3 = CFG.Colors.Accent
ButtonGlowEffect.ImageTransparency = 0.45
ButtonGlowEffect.ZIndex = 499
ButtonGlowEffect.Parent = FloatingButton

-- Letra 'K' en el botón
local ButtonTextIcon = UI_TextLabel(
    FloatingButton, 
    UDim2.new(1, 0, 1, 0), 
    UDim2.new(0, 0, 0, 0), 
    "K", 
    CFG.Colors.White, 
    20, 
    CFG.Fonts.Bold, 
    Enum.TextXAlignment.Center, 
    501
)

-- Bucle infinito para animar el resplandor de forma asíncrona
task.spawn(function()
    while FloatingButton and FloatingButton.Parent do
        -- Expandir resplandor
        CreateTween(
            ButtonGlowEffect, 
            {
                ImageTransparency = 0.12, 
                Size = UDim2.new(0, 90, 0, 90), 
                Position = UDim2.new(0.5, -45, 0.5, -45)
            }, 
            1.5, 
            Enum.EasingStyle.Sine, 
            Enum.EasingDirection.InOut
        )
        task.wait(1.5)
        
        -- Contraer resplandor
        CreateTween(
            ButtonGlowEffect, 
            {
                ImageTransparency = 0.6, 
                Size = UDim2.new(0, 70, 0, 70), 
                Position = UDim2.new(0.5, -35, 0.5, -35)
            }, 
            1.5, 
            Enum.EasingStyle.Sine, 
            Enum.EasingDirection.InOut
        )
        task.wait(1.5)
    end
end)

-- ----------------------------------------------------------------------------
-- Lógica de Arrastre del Botón Flotante (Optimizada para Mobile Touch)
-- ----------------------------------------------------------------------------
FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        AppState.Drag.ButtonDragging = true
        AppState.Drag.ButtonDragOrigin = Vector2.new(input.Position.X, input.Position.Y)
        AppState.Drag.ButtonPosOrigin = FloatingButton.Position
        AppState.Drag.ButtonTotalMoved = 0
    end
end)

UserInputService.InputChanged:Connect(function(input)
    -- Manejo del botón flotante
    if AppState.Drag.ButtonDragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local inputDelta = Vector2.new(input.Position.X, input.Position.Y) - AppState.Drag.ButtonDragOrigin
            AppState.Drag.ButtonTotalMoved = inputDelta.Magnitude
            
            -- Solo mover si el desplazamiento es mayor a 7 píxeles (para evitar mover en clicks)
            if AppState.Drag.ButtonTotalMoved > 7 then
                local newXScale = AppState.Drag.ButtonPosOrigin.X.Scale
                local newXOffset = AppState.Drag.ButtonPosOrigin.X.Offset + inputDelta.X
                local newYScale = AppState.Drag.ButtonPosOrigin.Y.Scale
                local newYOffset = AppState.Drag.ButtonPosOrigin.Y.Offset + inputDelta.Y
                
                FloatingButton.Position = UDim2.new(newXScale, newXOffset, newYScale, newYOffset)
            end
        end
    end
end)

-- ----------------------------------------------------------------------------
-- Ventana Principal (Main Window)
-- ----------------------------------------------------------------------------
local MainWindow = UI_Frame(
    MainScreenGui,
    UDim2.new(0, CFG.Window.Width, 0, CFG.Window.Height),
    UDim2.new(0.5, -CFG.Window.Width/2, 0.5, -CFG.Window.Height/2),
    CFG.Colors.Background,
    0,
    400,
    "MainWindow"
)
MainWindow.ClipsDescendants = true
MainWindow.Visible = false

ApplyCorner(MainWindow, 18)
ApplyStroke(MainWindow, Color3.fromRGB(65, 52, 128), 1.5)
ApplyGradient(MainWindow, Color3.fromRGB(10, 9, 22), Color3.fromRGB(6, 6, 15), 155)

-- Línea superior decorativa (Accent Line)
local TopDecorativeLine = UI_Frame(
    MainWindow,
    UDim2.new(1, 0, 0, 2),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Accent,
    0,
    401,
    "TopLine"
)
ApplyGradient(TopDecorativeLine, Color3.fromRGB(165, 105, 255), Color3.fromRGB(78, 38, 198), 0)

-- Partículas animadas de fondo
for particleIndex = 1, 8 do
    local randomPosX = math.random(5, 95) / 100
    local randomPosY = math.random(5, 95) / 100
    local randomSize = math.random(2, 5)
    
    local particleDot = UI_Frame(
        MainWindow,
        UDim2.new(0, randomSize, 0, randomSize),
        UDim2.new(randomPosX, 0, randomPosY, 0),
        CFG.Colors.Accent,
        0.65,
        400,
        "ParticleDot"
    )
    ApplyCorner(particleDot, randomSize)
    
    task.spawn(function()
        local initialDelay = math.random() * 3
        task.wait(initialDelay)
        
        while particleDot and particleDot.Parent do
            local animDuration1 = math.random() * 2 + 1
            CreateTween(particleDot, {BackgroundTransparency = 0.25}, animDuration1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(animDuration1)
            
            local animDuration2 = math.random() * 2 + 1
            CreateTween(particleDot, {BackgroundTransparency = 0.82}, animDuration2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(animDuration2)
        end
    end)
end

-- ----------------------------------------------------------------------------
-- Header (Cabecera de la ventana)
-- ----------------------------------------------------------------------------
local HeaderPanel = UI_Frame(
    MainWindow,
    UDim2.new(1, 0, 0, 45),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Surface,
    0.2,
    401,
    "HeaderPanel"
)
ApplyCorner(HeaderPanel, 18)
ApplyGradient(HeaderPanel, Color3.fromRGB(26, 20, 58), Color3.fromRGB(12, 10, 28), 100)

local HeaderLogoCircle = UI_Frame(
    HeaderPanel,
    UDim2.new(0, 30, 0, 30),
    UDim2.new(0, 10, 0.5, -15),
    CFG.Colors.Accent,
    0,
    402,
    "HeaderLogo"
)
ApplyCorner(HeaderLogoCircle, 15)
ApplyGradient(HeaderLogoCircle, Color3.fromRGB(145, 95, 255), Color3.fromRGB(82, 42, 200), 135)

local HeaderLogoText = UI_TextLabel(
    HeaderLogoCircle,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    "K",
    CFG.Colors.White,
    16,
    CFG.Fonts.Bold,
    Enum.TextXAlignment.Center,
    403
)

local HeaderTitleLabel = UI_TextLabel(
    HeaderPanel,
    UDim2.new(0, 200, 0, 18),
    UDim2.new(0, 48, 0, 6),
    "Kaelen Premium",
    CFG.Colors.White,
    15,
    CFG.Fonts.Bold,
    Enum.TextXAlignment.Left,
    402
)

local HeaderSubtitleLabel = UI_TextLabel(
    HeaderPanel,
    UDim2.new(0, 240, 0, 14),
    UDim2.new(0, 48, 0, 24),
    "AI Systems v2.3  •  " .. AppState.CurrentMode,
    CFG.Colors.TextMuted,
    9,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Left,
    402
)

local StatusDotIndicator = UI_Frame(
    HeaderPanel,
    UDim2.new(0, 8, 0, 8),
    UDim2.new(1, -45, 0.5, -4),
    CFG.Colors.Danger,
    0,
    402,
    "StatusDot"
)
ApplyCorner(StatusDotIndicator, 4)

local CloseWindowButton = UI_TextButton(
    HeaderPanel,
    UDim2.new(0, 28, 0, 28),
    UDim2.new(1, -36, 0.5, -14),
    Color3.fromRGB(198, 52, 72),
    "✕",
    CFG.Colors.White,
    13,
    CFG.Fonts.Bold,
    402
)
ApplyCorner(CloseWindowButton, 14)

-- Lógica de arrastre de ventana vinculada al Header
HeaderPanel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        AppState.Drag.WindowDragging = true
        AppState.Drag.WindowDragOrigin = Vector2.new(input.Position.X, input.Position.Y)
        AppState.Drag.WindowPosOrigin = MainWindow.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if AppState.Drag.WindowDragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = Vector2.new(input.Position.X, input.Position.Y) - AppState.Drag.WindowDragOrigin
            
            local newXScale = AppState.Drag.WindowPosOrigin.X.Scale
            local newXOffset = AppState.Drag.WindowPosOrigin.X.Offset + delta.X
            local newYScale = AppState.Drag.WindowPosOrigin.Y.Scale
            local newYOffset = AppState.Drag.WindowPosOrigin.Y.Offset + delta.Y
            
            MainWindow.Position = UDim2.new(newXScale, newXOffset, newYScale, newYOffset)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        AppState.Drag.WindowDragging = false
    end
end)

-- ----------------------------------------------------------------------------
-- Barra de Navegación (Tabs)
-- ----------------------------------------------------------------------------
local NavigationBar = UI_Frame(
    MainWindow,
    UDim2.new(1, -20, 0, 32),
    UDim2.new(0, 10, 0, 50),
    CFG.Colors.Card,
    0.12,
    401,
    "NavigationBar"
)
ApplyCorner(NavigationBar, 10)
ApplyStroke(NavigationBar, CFG.Colors.Border, 1)
CreateHorizontalLayout(NavigationBar, 5, Enum.VerticalAlignment.Center)
ApplyPadding(NavigationBar, 3, 3, 4, 4)

local TAB_CONFIGURATION = {"Chat", "Modos", "Config"}
local TabReferencesList = {}

-- Declaración anticipada de función de cambio de panel
local SwitchActivePanel = function(panelName) end

local function SetActiveTabVisuals(tabName)
    for i = 1, #TabReferencesList do
        local tabData = TabReferencesList[i]
        if tabData.name == tabName then
            CreateTween(tabData.button, {BackgroundColor3 = CFG.Colors.Accent, BackgroundTransparency = 0}, 0.2)
            CreateTween(tabData.label, {TextColor3 = CFG.Colors.White}, 0.2)
        else
            CreateTween(tabData.button, {BackgroundColor3 = CFG.Colors.Card, BackgroundTransparency = 0.6}, 0.2)
            CreateTween(tabData.label, {TextColor3 = CFG.Colors.TextMuted}, 0.2)
        end
    end
end

for index = 1, #TAB_CONFIGURATION do
    local currentTabName = TAB_CONFIGURATION[index]
    
    local tabButton = UI_TextButton(
        NavigationBar,
        UDim2.new(0, 90, 1, 0),
        UDim2.new(0, 0, 0, 0),
        CFG.Colors.Card,
        "",
        CFG.Colors.White,
        11,
        CFG.Fonts.Bold,
        402
    )
    tabButton.BackgroundTransparency = 0.6
    ApplyCorner(tabButton, 8)
    
    local tabLabel = UI_TextLabel(
        tabButton,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        currentTabName,
        CFG.Colors.TextMuted,
        11,
        CFG.Fonts.Bold,
        Enum.TextXAlignment.Center,
        403
    )
    
    table.insert(TabReferencesList, {name = currentTabName, button = tabButton, label = tabLabel})
    
    tabButton.MouseButton1Click:Connect(function()
        if AppState.KeyVerified then
            SetActiveTabVisuals(currentTabName)
            SwitchActivePanel(currentTabName)
        else
            warn("[Kaelen UI] Navegación bloqueada: Requiere verificación de API Key.")
        end
    end)
end

-- ----------------------------------------------------------------------------
-- Contenedor Principal de Paneles
-- ----------------------------------------------------------------------------
local PanelsContainer = UI_Frame(
    MainWindow,
    UDim2.new(1, -20, 1, -90),
    UDim2.new(0, 10, 0, 86),
    CFG.Colors.Black,
    1,
    400,
    "PanelsContainer"
)

-- ============================================================================
-- PANEL 1: SISTEMA DE VERIFICACIÓN DE LLAVES (KEY SYSTEM) EXTREMO
-- ============================================================================
local KeySystemPanel = UI_Frame(
    PanelsContainer,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Black,
    1,
    401,
    "KeySystemPanel"
)
CreateVerticalLayout(KeySystemPanel, 8, Enum.HorizontalAlignment.Center)
ApplyPadding(KeySystemPanel, 10, 10, 0, 0)

-- Icono de candado decorativo
local KeyLockIconContainer = UI_Frame(
    KeySystemPanel,
    UDim2.new(0, 50, 0, 50),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Card,
    0.08,
    402,
    "LockIconContainer"
)
KeyLockIconContainer.LayoutOrder = 1
ApplyCorner(KeyLockIconContainer, 25)
ApplyStroke(KeyLockIconContainer, CFG.Colors.Accent, 2)

local KeyLockIconLabel = UI_TextLabel(
    KeyLockIconContainer,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    "🔑",
    CFG.Colors.White,
    22,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Center,
    403
)

local KeySystemTitle = UI_TextLabel(
    KeySystemPanel,
    UDim2.new(1, 0, 0, 22),
    UDim2.new(0, 0, 0, 0),
    "Activar Kaelen Premium",
    CFG.Colors.White,
    16,
    CFG.Fonts.Bold,
    Enum.TextXAlignment.Center,
    402
)
KeySystemTitle.LayoutOrder = 2

local KeySystemSubtitle = UI_TextLabel(
    KeySystemPanel,
    UDim2.new(1, 0, 0, 30),
    UDim2.new(0, 0, 0, 0),
    "Introduce tu API Key de OpenRouter\npara conectarte al servidor.",
    CFG.Colors.TextMuted,
    10,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Center,
    402
)
KeySystemSubtitle.LayoutOrder = 3

local KeyInputField = Instance.new("TextBox")
KeyInputField.Name = "KeyInputField"
KeyInputField.Size = UDim2.new(1, -8, 0, 36)
KeyInputField.BackgroundColor3 = CFG.Colors.Card
KeyInputField.BackgroundTransparency = 0.08
KeyInputField.Text = ""
KeyInputField.PlaceholderText = "Pegar API Key aquí (sk-or-v1-...)"
KeyInputField.TextColor3 = CFG.Colors.Text
KeyInputField.PlaceholderColor3 = CFG.Colors.TextDim
KeyInputField.TextSize = 11
KeyInputField.Font = CFG.Fonts.Monospace
KeyInputField.ClearTextOnFocus = false  -- CRÍTICO PARA MÓVILES: Evita borrar al tocar
KeyInputField.ZIndex = 402
KeyInputField.LayoutOrder = 4
KeyInputField.BorderSizePixel = 0
KeyInputField.Parent = KeySystemPanel
ApplyCorner(KeyInputField, 10)
ApplyStroke(KeyInputField, CFG.Colors.Border, 1)
ApplyPadding(KeyInputField, 0, 0, 10, 10)

local KeyVerifyButton = UI_TextButton(
    KeySystemPanel,
    UDim2.new(1, -8, 0, 36),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Accent,
    "Verificar y Activar",
    CFG.Colors.White,
    12,
    CFG.Fonts.Bold,
    402
)
KeyVerifyButton.LayoutOrder = 5
ApplyCorner(KeyVerifyButton, 10)
ApplyGradient(KeyVerifyButton, Color3.fromRGB(142, 92, 255), Color3.fromRGB(84, 44, 202), 135)

-- Botón de "Guardado Forzoso" (Fallback) oculto por defecto
local KeyForceSaveButton = UI_TextButton(
    KeySystemPanel,
    UDim2.new(1, -8, 0, 24),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Warning,
    "⚠️ Forzar Guardado (Bypass Error Red)",
    CFG.Colors.Black,
    10,
    CFG.Fonts.Bold,
    402
)
KeyForceSaveButton.LayoutOrder = 6
KeyForceSaveButton.Visible = false
ApplyCorner(KeyForceSaveButton, 6)

local KeyStatusLog = UI_TextLabel(
    KeySystemPanel,
    UDim2.new(1, 0, 0, 40),
    UDim2.new(0, 0, 0, 0),
    "",
    CFG.Colors.TextMuted,
    10,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Center,
    402
)
KeyStatusLog.LayoutOrder = 7
KeyStatusLog.TextWrapped = true

-- Lógica avanzada de Verificación de Key
KeyVerifyButton.MouseButton1Click:Connect(function()
    -- Limpiar espacios en blanco alrededor
    local rawKey = KeyInputField.Text
    local sanitizedKey = string.match(rawKey, "^%s*(.-)%s*$")
    
    if not sanitizedKey or sanitizedKey == "" then
        KeyStatusLog.TextColor3 = CFG.Colors.Warning
        KeyStatusLog.Text = "⚠️ Error: El campo de la API Key está vacío."
        return
    end
    
    -- Verificación básica de formato
    if string.len(sanitizedKey) < 10 then
        KeyStatusLog.TextColor3 = CFG.Colors.Warning
        KeyStatusLog.Text = "⚠️ Error: La API Key parece ser demasiado corta o inválida."
        return
    end
    
    -- Actualizar UI estado "Cargando"
    KeyVerifyButton.Text = "⏳ Conectando con servidor..."
    KeyVerifyButton.BackgroundTransparency = 0.3
    KeyStatusLog.TextColor3 = CFG.Colors.TextMuted
    KeyStatusLog.Text = "Verificando credenciales mediante petición HTTP..."
    KeyForceSaveButton.Visible = false
    
    -- Hilo asíncrono para no congelar Delta
    task.spawn(function()
        local isSuccess, errorDetail = TestAPIKeyVerification(sanitizedKey)
        
        if isSuccess then
            -- Éxito total
            AppState.APIKey = sanitizedKey
            AppState.KeyVerified = true
            
            KeyStatusLog.TextColor3 = CFG.Colors.Success
            KeyStatusLog.Text = "✅ Kaelen Activado: Conexión estable establecida."
            CreateTween(StatusDotIndicator, {BackgroundColor3 = CFG.Colors.Success}, 0.5)
            
            KeyVerifyButton.Text = "Sistema Activo"
            KeyVerifyButton.BackgroundTransparency = 0.2
            
            task.wait(1.2)
            
            SwitchActivePanel("Chat")
            SetActiveTabVisuals("Chat")
            
            -- Mensaje de bienvenida inicial
            local welcomeMessage = "⬡ ¡Sistema Inicializado Exitosamente!\n\n" ..
                                   "He sido reconstruido con una arquitectura robusta para evitar crasheos en dispositivos móviles.\n" ..
                                   "Mi motor de comandos ahora es ultrarrápido y seguro.\n\n" ..
                                   "Pruébame escribiendo:\n" ..
                                   "• «Activa el noclip»\n" ..
                                   "• «Pon mi velocidad en 80»\n" ..
                                   "• «Crea un script avanzado»"
                                   
            table.insert(AppState.Messages, {role = "assistant", content = welcomeMessage})
            -- La UI de chat se actualizará cuando se cambie el panel
        else
            -- Falla en la red o key incorrecta
            AppState.KeyVerified = false
            
            KeyStatusLog.TextColor3 = CFG.Colors.Danger
            KeyStatusLog.Text = "❌ Falla de verificación:\n" .. tostring(errorDetail)
            
            KeyVerifyButton.Text = "Reintentar Verificación"
            KeyVerifyButton.BackgroundTransparency = 0
            
            -- Mostrar el botón de forzar guardado si parece que es error de red y no de formato
            if string.match(sanitizedKey, "^sk%-or%-") then
                KeyForceSaveButton.Visible = true
            end
        end
    end)
end)

-- Lógica de guardado forzoso
KeyForceSaveButton.MouseButton1Click:Connect(function()
    local rawKey = KeyInputField.Text
    local sanitizedKey = string.match(rawKey, "^%s*(.-)%s*$")
    
    if sanitizedKey and sanitizedKey ~= "" then
        print("[Kaelen Security] Guardado forzoso de API Key invocado por el usuario.")
        AppState.APIKey = sanitizedKey
        AppState.KeyVerified = true
        
        KeyStatusLog.TextColor3 = CFG.Colors.Warning
        KeyStatusLog.Text = "⚠️ Key guardada forzosamente ignorando el chequeo de red."
        CreateTween(StatusDotIndicator, {BackgroundColor3 = CFG.Colors.Warning}, 0.5)
        
        task.wait(1)
        
        SwitchActivePanel("Chat")
        SetActiveTabVisuals("Chat")
    end
end)

-- ============================================================================
-- PANEL 2: CHAT INTERACTIVO (CHAT PANEL)
-- ============================================================================
local InteractiveChatPanel = UI_Frame(
    PanelsContainer,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Black,
    1,
    401,
    "ChatPanel"
)
InteractiveChatPanel.Visible = false

local MessageScrollingArea = UI_ScrollingFrame(
    InteractiveChatPanel,
    UDim2.new(1, 0, 1, -70),
    UDim2.new(0, 0, 0, 0),
    402
)
CreateVerticalLayout(MessageScrollingArea, 8, Enum.HorizontalAlignment.Left)
ApplyPadding(MessageScrollingArea, 6, 6, 4, 4)

-- Indicador visual de "Pensando"
local ThinkingIndicatorFrame = UI_Frame(
    MessageScrollingArea,
    UDim2.new(0, 140, 0, 28),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.AIBubble,
    0.05,
    403,
    "ThinkingIndicator"
)
ThinkingIndicatorFrame.LayoutOrder = 9999
ThinkingIndicatorFrame.Visible = false
ApplyCorner(ThinkingIndicatorFrame, 14)
ApplyStroke(ThinkingIndicatorFrame, CFG.Colors.Border, 1)
ApplyPadding(ThinkingIndicatorFrame, 0, 0, 10, 10)

local ThinkingLabel = UI_TextLabel(
    ThinkingIndicatorFrame,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    "Procesando...",
    CFG.Colors.TextMuted,
    11,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Left,
    404
)

-- Contenedor de entrada de texto inferior
local ChatInputContainer = UI_Frame(
    InteractiveChatPanel,
    UDim2.new(1, 0, 0, 66),
    UDim2.new(0, 0, 1, -66),
    CFG.Colors.Surface,
    0.18,
    402,
    "InputContainer"
)
ApplyCorner(ChatInputContainer, 12)
ApplyStroke(ChatInputContainer, CFG.Colors.Border, 1)

local ChatTextBox = Instance.new("TextBox")
ChatTextBox.Name = "ChatInput"
ChatTextBox.Size = UDim2.new(1, -44, 0, 34)
ChatTextBox.Position = UDim2.new(0, 6, 0, 6)
ChatTextBox.BackgroundColor3 = CFG.Colors.Card
ChatTextBox.BackgroundTransparency = 0.08
ChatTextBox.Text = ""
ChatTextBox.PlaceholderText = "Escribe un comando o consulta..."
ChatTextBox.TextColor3 = CFG.Colors.Text
ChatTextBox.PlaceholderColor3 = CFG.Colors.TextDim
ChatTextBox.TextSize = 11
ChatTextBox.Font = CFG.Fonts.Regular
ChatTextBox.MultiLine = false
ChatTextBox.ClearTextOnFocus = false
ChatTextBox.ZIndex = 403
ChatTextBox.BorderSizePixel = 0
ChatTextBox.Parent = ChatInputContainer
ApplyCorner(ChatTextBox, 8)
ApplyPadding(ChatTextBox, 0, 0, 10, 10)

local ChatSendButton = UI_TextButton(
    ChatInputContainer,
    UDim2.new(0, 34, 0, 34),
    UDim2.new(1, -38, 0, 6),
    CFG.Colors.Accent,
    "➤",
    CFG.Colors.White,
    14,
    CFG.Fonts.Bold,
    403
)
ApplyCorner(ChatSendButton, 8)
ApplyGradient(ChatSendButton, Color3.fromRGB(142, 92, 255), Color3.fromRGB(84, 44, 202), 135)

-- Barra de comandos rápidos (Quick Action Bar)
local QuickCommandBar = UI_Frame(
    ChatInputContainer,
    UDim2.new(1, -8, 0, 22),
    UDim2.new(0, 4, 0, 42),
    CFG.Colors.Black,
    1,
    403,
    "QuickBar"
)
CreateHorizontalLayout(QuickCommandBar, 5, Enum.VerticalAlignment.Center)

local QuickCommandsData = {
    { icon = "🎮", label = "Analizar Juego", id = "cmd_analyze" },
    { icon = "🚀", label = "Toggle Fly", id = "cmd_fly" },
    { icon = "👻", label = "Noclip", id = "cmd_noclip" },
    { icon = "🗑",  label = "Limpiar", id = "cmd_clear" }
}

local QuickCommandReferences = {}

for index = 1, #QuickCommandsData do
    local commandData = QuickCommandsData[index]
    
    local quickButton = UI_TextButton(
        QuickCommandBar,
        UDim2.new(0, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        CFG.Colors.Card,
        commandData.icon .. " " .. commandData.label,
        CFG.Colors.TextMuted,
        9,
        CFG.Fonts.Regular,
        404
    )
    quickButton.AutomaticSize = Enum.AutomaticSize.X
    quickButton.BackgroundTransparency = 0.3
    ApplyCorner(quickButton, 5)
    ApplyPadding(quickButton, 1, 1, 5, 5)
    
    table.insert(QuickCommandReferences, {
        buttonObject = quickButton,
        commandId = commandData.id
    })
end

-- ============================================================================
-- PANEL 3: SELECCIÓN DE MODO IA (MODES PANEL)
-- ============================================================================
local ModesSelectionPanel = UI_ScrollingFrame(
    PanelsContainer,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    401
)
ModesSelectionPanel.Name = "ModesPanel"
ModesSelectionPanel.Visible = false

CreateVerticalLayout(ModesSelectionPanel, 6, Enum.HorizontalAlignment.Center)
ApplyPadding(ModesSelectionPanel, 4, 4, 0, 0)

local ModePanelTitle = UI_TextLabel(
    ModesSelectionPanel,
    UDim2.new(1, 0, 0, 20),
    UDim2.new(0, 0, 0, 0),
    "Personalidad de Kaelen",
    CFG.Colors.White,
    14,
    CFG.Fonts.Bold,
    Enum.TextXAlignment.Center,
    402
)
ModePanelTitle.LayoutOrder = 0

local ModePanelSubtitle = UI_TextLabel(
    ModesSelectionPanel,
    UDim2.new(1, 0, 0, 14),
    UDim2.new(0, 0, 0, 0),
    "Selecciona el comportamiento del Orquestador",
    CFG.Colors.TextMuted,
    9,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Center,
    402
)
ModePanelSubtitle.LayoutOrder = 1

local AvailableModesList = {
    { name = "Programador", icon = "💻", color = Color3.fromRGB(78, 198, 255), description = "Scripts Lua, optimización y resolución de errores." },
    { name = "Analista",    icon = "🔍", color = Color3.fromRGB(112, 72, 255), description = "Análisis de red, estructura y vulnerabilidades." },
    { name = "Creativo",    icon = "🎨", color = Color3.fromRGB(255, 138, 78), description = "Ideas innovadoras para diseño de juegos." },
    { name = "Troll",       icon = "😈", color = Color3.fromRGB(255, 78, 128), description = "Humor, caos inofensivo y trucos creativos." },
}

local ModeCardReferences = {}

for modeIndex = 1, #AvailableModesList do
    local modeData = AvailableModesList[modeIndex]
    local isCurrentlyActive = (modeData.name == AppState.CurrentMode)
    
    local modeCardButton = UI_TextButton(
        ModesSelectionPanel,
        UDim2.new(1, 0, 0, 50),
        UDim2.new(0, 0, 0, 0),
        CFG.Colors.Card,
        "",
        CFG.Colors.White,
        13,
        CFG.Fonts.Bold,
        402
    )
    modeCardButton.BackgroundTransparency = isCurrentlyActive and 0.05 or 0.3
    modeCardButton.LayoutOrder = modeIndex + 1
    ApplyCorner(modeCardButton, 10)
    
    local cardStroke = ApplyStroke(
        modeCardButton, 
        isCurrentlyActive and CFG.Colors.Accent or CFG.Colors.Border, 
        isCurrentlyActive and 1.5 or 1
    )
    
    local modeIconCircle = UI_Frame(
        modeCardButton,
        UDim2.new(0, 34, 0, 34),
        UDim2.new(0, 10, 0.5, -17),
        modeData.color,
        0.12,
        403,
        "IconCircle"
    )
    ApplyCorner(modeIconCircle, 17)
    
    local modeIconLabel = UI_TextLabel(
        modeIconCircle,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        modeData.icon,
        CFG.Colors.White,
        16,
        CFG.Fonts.Regular,
        Enum.TextXAlignment.Center,
        404
    )
    
    local modeNameLabel = UI_TextLabel(
        modeCardButton,
        UDim2.new(1, -60, 0, 16),
        UDim2.new(0, 52, 0, 8),
        modeData.name,
        CFG.Colors.White,
        12,
        CFG.Fonts.Bold,
        Enum.TextXAlignment.Left,
        403
    )
    
    local modeDescLabel = UI_TextLabel(
        modeCardButton,
        UDim2.new(1, -60, 0, 14),
        UDim2.new(0, 52, 0, 26),
        modeData.description,
        CFG.Colors.TextMuted,
        9,
        CFG.Fonts.Regular,
        Enum.TextXAlignment.Left,
        403
    )
    
    local modeActiveIndicator = UI_Frame(
        modeCardButton,
        UDim2.new(0, 8, 0, 8),
        UDim2.new(1, -16, 0.5, -4),
        modeData.color,
        isCurrentlyActive and 0 or 1,
        403,
        "ActiveIndicator"
    )
    ApplyCorner(modeActiveIndicator, 4)
    
    table.insert(ModeCardReferences, {
        card = modeCardButton,
        stroke = cardStroke,
        badge = modeActiveIndicator,
        name = modeData.name,
        color = modeData.color
    })
    
    -- Lógica de cambio de modo
    modeCardButton.MouseButton1Click:Connect(function()
        print("[Kaelen Config] Modo cambiado a: " .. tostring(modeData.name))
        AppState.CurrentMode = modeData.name
        HeaderSubtitleLabel.Text = "AI Systems v2.3  •  " .. AppState.CurrentMode
        
        -- Actualizar estilos visuales
        for r = 1, #ModeCardReferences do
            local refData = ModeCardReferences[r]
            local isNowActive = (refData.name == modeData.name)
            
            CreateTween(refData.card, {BackgroundTransparency = isNowActive and 0.05 or 0.3}, 0.22)
            CreateTween(refData.badge, {BackgroundTransparency = isNowActive and 0 or 1}, 0.22)
            refData.stroke.Color = isNowActive and CFG.Colors.Accent or CFG.Colors.Border
            refData.stroke.Thickness = isNowActive and 1.5 or 1
        end
    end)
end

-- ============================================================================
-- PANEL 4: CONFIGURACIÓN AVANZADA (CONFIG PANEL)
-- ============================================================================
local ConfigurationPanel = UI_ScrollingFrame(
    PanelsContainer,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    401
)
ConfigurationPanel.Name = "ConfigPanel"
ConfigurationPanel.Visible = false

CreateVerticalLayout(ConfigurationPanel, 8, Enum.HorizontalAlignment.Center)
ApplyPadding(ConfigurationPanel, 4, 4, 0, 0)

local ConfigTitle = UI_TextLabel(
    ConfigurationPanel,
    UDim2.new(1, 0, 0, 20),
    UDim2.new(0, 0, 0, 0),
    "Ajustes del Sistema",
    CFG.Colors.White,
    14,
    CFG.Fonts.Bold,
    Enum.TextXAlignment.Center,
    402
)
ConfigTitle.LayoutOrder = 0

-- Tarjeta de información del motor
local EngineInfoCard = UI_Frame(
    ConfigurationPanel,
    UDim2.new(1, 0, 0, 65),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Card,
    0.18,
    402,
    "InfoCard"
)
EngineInfoCard.LayoutOrder = 1
ApplyCorner(EngineInfoCard, 10)
ApplyStroke(EngineInfoCard, CFG.Colors.Border, 1)
ApplyPadding(EngineInfoCard, 6, 6, 10, 10)

local EngineInfoLabel = UI_TextLabel(
    EngineInfoCard,
    UDim2.new(1, 0, 1, 0),
    UDim2.new(0, 0, 0, 0),
    "⚡ Kaelen v2.3 — Architecture Triple-Engine\n" ..
    "🟢 Motor Fast: Gemma 3 (Latencia Cero)\n" ..
    "🔵 Motor Coder: Qwen 3 (Lógica pura)\n" ..
    "🟣 Motor Reason: Llama 3.3 (Revisión y Análisis)",
    CFG.Colors.TextMuted,
    9,
    CFG.Fonts.Regular,
    Enum.TextXAlignment.Left,
    403
)

local WipeHistoryButton = UI_TextButton(
    ConfigurationPanel,
    UDim2.new(1, 0, 0, 32),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Card,
    "🗑 Borrar Historial de Mensajes",
    CFG.Colors.TextMuted,
    11,
    CFG.Fonts.Bold,
    402
)
WipeHistoryButton.LayoutOrder = 2
WipeHistoryButton.BackgroundTransparency = 0.2
ApplyCorner(WipeHistoryButton, 10)
ApplyStroke(WipeHistoryButton, CFG.Colors.Border, 1)

local ResetLicenseButton = UI_TextButton(
    ConfigurationPanel,
    UDim2.new(1, 0, 0, 32),
    UDim2.new(0, 0, 0, 0),
    CFG.Colors.Danger,
    "⚠ Resetear Clave de API",
    CFG.Colors.White,
    11,
    CFG.Fonts.Bold,
    402
)
ResetLicenseButton.LayoutOrder = 3
ResetLicenseButton.BackgroundTransparency = 0.28
ApplyCorner(ResetLicenseButton, 10)

-- ============================================================================
-- 14. LOGICA VISUAL Y CONTROLADORES DE EVENTOS
-- ============================================================================

-- Mapeo de paneles para el sistema de navegación
local PanelDictionary = {
    Key = KeySystemPanel,
    Chat = InteractiveChatPanel,
    Modos = ModesSelectionPanel,
    Config = ConfigurationPanel
}

-- Mapeo estructurado para ocultar todos
local AllPanelsArray = {
    KeySystemPanel,
    InteractiveChatPanel,
    ModesSelectionPanel,
    ConfigurationPanel
}

-- Función de conmutación de paneles
SwitchActivePanel = function(targetPanelName)
    -- Ocultar todos primero
    for i = 1, #AllPanelsArray do
        AllPanelsArray[i].Visible = false
    end
    
    -- Mostrar objetivo
    local targetPanel = PanelDictionary[targetPanelName]
    if targetPanel then
        targetPanel.Visible = true
    end
end

-- Función auxiliar para auto-scroll del chat
local function AutoScrollToBottom()
    task.delay(0.06, function()
        if MessageScrollingArea and MessageScrollingArea.Parent then
            local targetY = MessageScrollingArea.AbsoluteCanvasSize.Y + 9999
            MessageScrollingArea.CanvasPosition = Vector2.new(0, targetY)
        end
    end)
end

-- Función constructora de mensajes en la UI
local function AddMessageToUI(senderRole, messageContent)
    -- Lógica de historial
    table.insert(AppState.Messages, {
        role = senderRole,
        content = messageContent
    })
    
    if #AppState.Messages > CFG.API.MaxHistory then
        table.remove(AppState.Messages, 1)
    end
    
    AppState.MessageCount = AppState.MessageCount + 1
    local isUserMessage = (senderRole == "user")
    
    -- Contenedor de la fila
    local messageRowFrame = UI_Frame(
        MessageScrollingArea,
        UDim2.new(1, 0, 0, 0),
        UDim2.new(0, 0, 0, 0),
        CFG.Colors.Black,
        1,
        403,
        "MessageRow_" .. tostring(AppState.MessageCount)
    )
    messageRowFrame.AutomaticSize = Enum.AutomaticSize.Y
    messageRowFrame.LayoutOrder = AppState.MessageCount
    
    -- Burbuja de chat visual
    local bubbleBackgroundColor = isUserMessage and CFG.Colors.UserBubble or CFG.Colors.AIBubble
    
    local messageBubble = UI_Frame(
        messageRowFrame,
        UDim2.new(0.84, 0, 0, 0),
        UDim2.new(isUserMessage and 0.16 or 0, 0, 0, 0),
        bubbleBackgroundColor,
        0.05,
        404,
        "Bubble"
    )
    messageBubble.AutomaticSize = Enum.AutomaticSize.Y
    ApplyCorner(messageBubble, 12)
    ApplyPadding(messageBubble, 8, 8, 10, 10)
    
    if not isUserMessage then
        ApplyStroke(messageBubble, CFG.Colors.Border, 1)
    end
    
    local bubbleLayoutAlign = isUserMessage and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
    CreateVerticalLayout(messageBubble, 4, bubbleLayoutAlign)
    
    -- Etiqueta del autor
    local authorName = isUserMessage and ("🧑 " .. LocalPlayer.Name) or "⬡ Kaelen Premium"
    local authorColor = isUserMessage and Color3.fromRGB(185, 158, 255) or CFG.Colors.Accent
    local authorTextAlign = isUserMessage and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    local authorLabel = UI_TextLabel(
        messageBubble,
        UDim2.new(1, 0, 0, 12),
        UDim2.new(0, 0, 0, 0),
        authorName,
        authorColor,
        9,
        CFG.Fonts.Bold,
        authorTextAlign,
        405
    )
    authorLabel.LayoutOrder = 1
    
    -- Contenido textual del mensaje
    local textContentLabel = UI_TextLabel(
        messageBubble,
        UDim2.new(1, 0, 0, 0),
        UDim2.new(0, 0, 0, 0),
        messageContent,
        CFG.Colors.Text,
        11,
        CFG.Fonts.Regular,
        authorTextAlign,
        405
    )
    textContentLabel.AutomaticSize = Enum.AutomaticSize.Y
    textContentLabel.LayoutOrder = 2
    
    -- Animación de entrada suave
    messageBubble.BackgroundTransparency = 1
    textContentLabel.TextTransparency = 1
    authorLabel.TextTransparency = 1
    
    CreateTween(messageBubble, {BackgroundTransparency = 0.05}, 0.3)
    CreateTween(textContentLabel, {TextTransparency = 0}, 0.3)
    CreateTween(authorLabel, {TextTransparency = 0}, 0.3)
    
    AutoScrollToBottom()
end

-- Controlador de la animación de "Pensando..."
local function SetThinkingState(isActive)
    AppState.IsThinking = isActive
    ThinkingIndicatorFrame.Visible = isActive
    
    if isActive then
        ThinkingIndicatorFrame.LayoutOrder = AppState.MessageCount + 1
        
        -- Cancelar tarea anterior si existiese
        if AppState.ThinkTaskThread then
            task.cancel(AppState.ThinkTaskThread)
        end
        
        -- Iniciar nueva tarea de animación de puntos
        AppState.ThinkTaskThread = task.spawn(function()
            local animationFrames = { "●○○", "●●○", "●●●", "○●●", "○○●", "○○○" }
            local frameIndex = 1
            
            while AppState.IsThinking do
                if ThinkingLabel and ThinkingLabel.Parent then
                    ThinkingLabel.Text = "Orquestador trabajando " .. animationFrames[frameIndex]
                end
                frameIndex = (frameIndex % #animationFrames) + 1
                task.wait(0.28)
            end
        end)
        
        AutoScrollToBottom()
    else
        if AppState.ThinkTaskThread then
            task.cancel(AppState.ThinkTaskThread)
            AppState.ThinkTaskThread = nil
        end
    end
end

-- Lógica principal de envío de texto
local function ProcessAndSendUserMessage(rawInputText)
    -- Filtrar espacios vacíos al inicio y final
    local sanitizedText = string.match(rawInputText or "", "^%s*(.-)%s*$")
    
    if sanitizedText == "" or AppState.IsThinking then
        return
    end
    
    -- Limpiar el input UI
    ChatTextBox.Text = ""
    
    -- Renderizar mensaje en pantalla
    AddMessageToUI("user", sanitizedText)
    
    -- Activar animacion
    SetThinkingState(true)
    
    -- Delegar trabajo pesado a un nuevo hilo
    task.spawn(function()
        local aiResponseText, pipelineError = CoreOrchestrator(sanitizedText, AppState.Messages)
        
        -- Detener animación
        SetThinkingState(false)
        
        if pipelineError then
            -- Fallo crítico durante la orquestación
            local errorFormat = "⚠️ Error Crítico Detectado:\n" .. tostring(pipelineError)
            AddMessageToUI("assistant", errorFormat)
        else
            -- Proceso exitoso. Buscar y ejecutar comandos físicos ocultos
            ProcessAIActionCommands(aiResponseText)
            
            -- Mostrar resultado
            AddMessageToUI("assistant", aiResponseText or "No se pudo recuperar información válida.")
        end
    end)
end

-- Eventos de la caja de texto
ChatSendButton.MouseButton1Click:Connect(function()
    ProcessAndSendUserMessage(ChatTextBox.Text)
end)

ChatTextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        ProcessAndSendUserMessage(ChatTextBox.Text)
    end
end)

-- Eventos de botones de acción rápida
for i = 1, #QuickCommandReferences do
    local refData = QuickCommandReferences[i]
    local btnObject = refData.buttonObject
    local commandId = refData.commandId
    
    btnObject.MouseButton1Click:Connect(function()
        if commandId == "cmd_analyze" then
            local contextualData = GetGameContext()
            local promptText = "🎮 Analiza la arquitectura de este juego a profundidad y detecta posibles fallos:\n" .. contextualData
            ProcessAndSendUserMessage(promptText)
            
        elseif commandId == "cmd_fly" then
            ProcessAndSendUserMessage("Por favor, activa mi modo de vuelo para poder volar libremente.")
            
        elseif commandId == "cmd_noclip" then
            ProcessAndSendUserMessage("Necesito atravesar paredes, activa el sistema noclip en mi personaje.")
            
        elseif commandId == "cmd_clear" then
            -- Limpieza profunda de UI
            local children = MessageScrollingArea:GetChildren()
            for childIdx = 1, #children do
                local child = children[childIdx]
                if child:IsA("Frame") and child.Name ~= "ThinkingIndicator" then
                    child:Destroy()
                end
            end
            
            -- Limpieza de memoria
            AppState.Messages = {}
            AppState.MessageCount = 0
            
            AddMessageToUI("assistant", "🗑 La memoria contextual y el historial visual han sido borrados con éxito.")
        end
    end)
end

-- Eventos de Configuración
WipeHistoryButton.MouseButton1Click:Connect(function()
    -- Reutilizamos lógica de limpieza
    local children = MessageScrollingArea:GetChildren()
    for childIdx = 1, #children do
        local child = children[childIdx]
        if child:IsA("Frame") and child.Name ~= "ThinkingIndicator" then
            child:Destroy()
        end
    end
    AppState.Messages = {}
    AppState.MessageCount = 0
    print("[Kaelen Config] Historial reseteado por el usuario.")
end)

ResetLicenseButton.MouseButton1Click:Connect(function()
    -- Reinicio duro de seguridad
    AppState.APIKey = ""
    AppState.KeyVerified = false
    AppState.Messages = {}
    AppState.MessageCount = 0
    
    KeyInputField.Text = ""
    KeyStatusLog.Text = ""
    StatusDotIndicator.BackgroundColor3 = CFG.Colors.Danger
    
    -- Limpiar UI
    local children = MessageScrollingArea:GetChildren()
    for childIdx = 1, #children do
        local child = children[childIdx]
        if child:IsA("Frame") and child.Name ~= "ThinkingIndicator" then
            child:Destroy()
        end
    end
    
    -- Bloquear y mandar a pantalla de login
    SwitchActivePanel("Key")
    print("[Kaelen Config] Licencia revocada localmente. Retornando a pantalla de bloqueo.")
end)

-- ----------------------------------------------------------------------------
-- Manejo de la Ventana Principal (Abrir/Cerrar)
-- ----------------------------------------------------------------------------
OpenKaelenWindow = function()
    AppState.WindowOpen = true
    MainWindow.Visible = true
    
    -- Configurar punto de partida de la animación (Desde el botón flotante)
    local originXScale = FloatingButton.Position.X.Scale
    local originXOffset = FloatingButton.Position.X.Offset + 24
    local originYScale = FloatingButton.Position.Y.Scale
    local originYOffset = FloatingButton.Position.Y.Offset + 24
    
    MainWindow.Size = UDim2.new(0, 0, 0, 0)
    MainWindow.Position = UDim2.new(originXScale, originXOffset, originYScale, originYOffset)
    
    -- Destino final (Centro de la pantalla)
    local targetSize = UDim2.new(0, CFG.Window.Width, 0, CFG.Window.Height)
    local targetPosition = UDim2.new(0.5, -CFG.Window.Width/2, 0.5, -CFG.Window.Height/2)
    
    CreateTween(MainWindow, { Size = targetSize, Position = targetPosition }, 0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

CloseKaelenWindow = function()
    AppState.WindowOpen = false
    
    -- Calcular punto de retorno (Hacia el botón flotante)
    local returnXScale = FloatingButton.Position.X.Scale
    local returnXOffset = FloatingButton.Position.X.Offset + 24
    local returnYScale = FloatingButton.Position.Y.Scale
    local returnYOffset = FloatingButton.Position.Y.Offset + 24
    
    local targetSize = UDim2.new(0, 0, 0, 0)
    local targetPosition = UDim2.new(returnXScale, returnXOffset, returnYScale, returnYOffset)
    
    CreateTween(MainWindow, { Size = targetSize, Position = targetPosition }, 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    
    -- Ocultar después de que termine la animación
    task.delay(0.28, function()
        if MainWindow and MainWindow.Parent then
            MainWindow.Visible = false
        end
    end)
end

CloseWindowButton.MouseButton1Click:Connect(CloseKaelenWindow)

-- Intercepción de teclado para abrir rápido con la tecla "K" (Solo en PC, ignorado en móvil)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.K then
        if AppState.WindowOpen then
            CloseKaelenWindow()
        else
            OpenKaelenWindow()
        end
    end
end)

-- ============================================================================
-- 15. SECUENCIA FINAL DE INICIO
-- ============================================================================

-- Bloquear el acceso estableciendo el panel inicial
SwitchActivePanel("Key")
SetActiveTabVisuals("Chat")

print("[Kaelen Boot] Carga completa. Mostrando panel de llave.")
print("\n")
print("==================================================")
print("  KAELEN PREMIUM - INIT SEQUENCE COMPLETED        ")
print("  - Engine Status: Stable                         ")
print("  - Security Protocol: Active                     ")
print("  - Memory Compression: Disabled                  ")
print("==================================================")
