--[[
    ===========================================================================
    ██╗  ██╗ █████╗ ███████╗██╗     ███████╗███╗   ██╗
    ██║ ██╔╝██╔══██╗██╔════╝██║     ██╔════╝████╗  ██║
    █████╔╝ ███████║█████╗  ██║     █████╗  ██╔██╗ ██║
    ██╔═██╗ ██╔══██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║
    ██║  ██╗██║  ██║███████╗███████╗███████╗██║ ╚████║
    ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝
    
    KAELEN AI - ADVANCED ORCHESTRATOR FOR ROBLOX (ULTIMATE MOBILE EDITION)
    Version: 2.3 Ultimate (Touch-Safe Architecture)
    Engines: Qwen3-Coder (Scripts), Hermes 3 405B (Analysis), Liquid LFM 1.2B (Fast Actions)
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

-- ============================================================================
-- 2. VARIABLES DE ENTORNO LOCALES
-- ============================================================================
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ============================================================================
-- 3. LIMPIEZA DE INSTANCIAS ANTERIORES (ANTI-DUPLICACIÓN)
-- ============================================================================
pcall(function()
    local oldUI = CoreGui:FindFirstChild("KaelenUI")
    if oldUI then oldUI:Destroy() end
end)
pcall(function()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui and playerGui:FindFirstChild("KaelenUI") then
        playerGui:FindFirstChild("KaelenUI"):Destroy()
    end
end)

-- ============================================================================
-- 4. CONFIGURACIÓN GLOBAL (MODELOS ACTUALIZADOS)
-- ============================================================================
local CFG = {}
CFG.OpenRouterURL = "https://openrouter.ai/api/v1/chat/completions"

-- Modelos de Inteligencia Artificial (Actualizados según solicitud)
CFG.Models = {}
CFG.Models.Coder = "qwen/qwen3-coder:free"
CFG.Models.Reason = "nousresearch/hermes-3-llama-3.1-405b:free"
CFG.Models.Fast = "liquid/lfm-2.5-1.2b-instruct:free"

-- Parámetros de la API
CFG.API = { MaxTokens = 1800, Temperature = 0.72, MaxHistory = 50 }

-- Dimensiones de la Ventana
CFG.Window = { Width = 440, Height = 300 }

-- Paleta de Colores
CFG.Colors = {
    Background = Color3.fromRGB(8, 8, 18),
    Surface = Color3.fromRGB(15, 14, 30),
    Card = Color3.fromRGB(21, 20, 40),
    Border = Color3.fromRGB(52, 47, 100),
    Accent = Color3.fromRGB(112, 72, 255),
    AccentGlow = Color3.fromRGB(158, 118, 255),
    UserBubble = Color3.fromRGB(92, 52, 232),
    AIBubble = Color3.fromRGB(20, 19, 40),
    Text = Color3.fromRGB(226, 222, 255),
    TextMuted = Color3.fromRGB(118, 112, 172),
    TextDim = Color3.fromRGB(72, 68, 128),
    Success = Color3.fromRGB(68, 212, 132),
    Danger = Color3.fromRGB(255, 72, 98),
    Warning = Color3.fromRGB(255, 198, 68),
    White = Color3.fromRGB(255, 255, 255),
    Black = Color3.fromRGB(0, 0, 0)
}

CFG.Fonts = { Bold = Enum.Font.GothamBold, Regular = Enum.Font.Gotham, Monospace = Enum.Font.Code }

-- ============================================================================
-- 5. GESTOR DE ESTADO DEL SISTEMA
-- ============================================================================
local AppState = {
    APIKey = "", KeyVerified = false, WindowOpen = false, IsThinking = false,
    Messages = {}, CurrentMode = "Analista", CustomSystemPrompt = "",
    ThinkTaskThread = nil, MessageCount = 0,
    Engine = { IsFlying = false, FlyConnection = nil, IsNoclipping = false, NoclipConnection = nil }
}

-- ============================================================================
-- 6. UTILIDADES DE INTERFAZ GRÁFICA (UI FRAMEWORK)
-- ============================================================================
local function CreateTween(object, properties, duration, style, direction)
    if not object then return nil end
    local tweenInfo = TweenInfo.new(duration or 0.28, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function ApplyCorner(parent, radius)
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 12); corner.Parent = parent; return corner
end

local function ApplyStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke"); stroke.Color = color or CFG.Colors.Border; stroke.Thickness = thickness or 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = parent; return stroke
end

local function ApplyPadding(parent, top, bottom, left, right)
    local padding = Instance.new("UIPadding"); padding.PaddingTop = UDim.new(0, top or 8); padding.PaddingBottom = UDim.new(0, bottom or 8); padding.PaddingLeft = UDim.new(0, left or 8); padding.PaddingRight = UDim.new(0, right or 8); padding.Parent = parent; return padding
end

local function CreateVerticalLayout(parent, padding, align)
    local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Vertical; layout.HorizontalAlignment = align or Enum.HorizontalAlignment.Left; layout.Padding = UDim.new(0, padding or 0); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = parent; return layout
end

local function CreateHorizontalLayout(parent, padding, align)
    local layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.VerticalAlignment = align or Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, padding or 0); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = parent; return layout
end

local function ApplyGradient(parent, c1, c2, rot)
    local gradient = Instance.new("UIGradient"); gradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}); gradient.Rotation = rot or 90; gradient.Parent = parent; return gradient
end

-- ============================================================================
-- 7. SISTEMA DE ARRASTRE Y TAP (MOBILE SAFE DRAG SYSTEM)
--    Soluciona el bug de "la bolita me sigue a todos lados"
-- ============================================================================
local function MakeDraggableAndTappable(guiObject, onTapCallback)
    local dragging = false
    local dragInput = nil
    local dragStartPos = nil
    local frameStartPos = nil
    local hasMoved = false

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragInput = input
            dragStartPos = input.Position
            frameStartPos = guiObject.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStartPos
            if delta.Magnitude > 7 then -- Umbral para considerar que es un arrastre y no un tap
                hasMoved = true
                guiObject.Position = UDim2.new(
                    frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                    frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            if dragging then
                dragging = false
                if not hasMoved and onTapCallback then
                    onTapCallback()
                end
            end
            dragInput = nil
        end
    end)
end

-- ============================================================================
-- 8. CLASES CONSTRUCTORAS DE UI
-- ============================================================================
local function UI_Frame(parent, size, pos, bg, trans, z, name)
    local f = Instance.new("Frame"); f.Size = size; f.Position = pos; f.BackgroundColor3 = bg; f.BackgroundTransparency = trans; f.ZIndex = z; f.BorderSizePixel = 0; if name then f.Name = name end; f.Parent = parent; return f
end
local function UI_TextLabel(parent, size, pos, txt, col, txtSize, font, align, z)
    local l = Instance.new("TextLabel"); l.Size = size; l.Position = pos; l.BackgroundTransparency = 1; l.Text = txt; l.TextColor3 = col; l.TextSize = txtSize; l.Font = font; l.TextXAlignment = align; l.ZIndex = z; l.TextWrapped = true; l.Parent = parent; return l
end
local function UI_TextButton(parent, size, pos, bg, txt, col, txtSize, font, z)
    local b = Instance.new("TextButton"); b.Size = size; b.Position = pos; b.BackgroundColor3 = bg; b.Text = txt; b.TextColor3 = col; b.TextSize = txtSize; b.Font = font; b.ZIndex = z; b.AutoButtonColor = false; b.BorderSizePixel = 0; b.Parent = parent; return b
end
local function UI_ScrollingFrame(parent, size, pos, z)
    local s = Instance.new("ScrollingFrame"); s.Size = size; s.Position = pos; s.BackgroundTransparency = 1; s.ScrollBarThickness = 3; s.ScrollBarImageColor3 = CFG.Colors.Accent; s.AutomaticCanvasSize = Enum.AutomaticSize.Y; s.ZIndex = z; s.BorderSizePixel = 0; s.Parent = parent; return s
end

-- ============================================================================
-- 9. MOTOR FÍSICO DE COMANDOS DEL JUGADOR (KAELEN ENGINE)
-- ============================================================================
local function ActivateFly(state)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    AppState.Engine.IsFlying = state
    if state then
        if AppState.Engine.FlyConnection then return end
        local bv = Instance.new("BodyVelocity"); bv.Name = "KaelenFlyV"; bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Parent = hrp
        local bg = Instance.new("BodyGyro"); bg.Name = "KaelenFlyG"; bg.P = 90000; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = hrp.CFrame; bg.Parent = hrp
        
        AppState.Engine.FlyConnection = RunService.RenderStepped:Connect(function()
            local cf = Camera.CFrame
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
            local vert = 0
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert = 1 elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vert = -1 end
            bv.Velocity = ((cf.RightVector * move.X) + (cf.LookVector * move.Z) + Vector3.new(0, vert, 0)) * 50
            bg.CFrame = cf
        end)
    else
        local v = hrp:FindFirstChild("KaelenFlyV"); if v then v:Destroy() end
        local g = hrp:FindFirstChild("KaelenFlyG"); if g then g:Destroy() end
        if AppState.Engine.FlyConnection then AppState.Engine.FlyConnection:Disconnect(); AppState.Engine.FlyConnection = nil end
    end
end

local function ActivateNoclip(state)
    AppState.Engine.IsNoclipping = state
    if state then
        if AppState.Engine.NoclipConnection then return end
        AppState.Engine.NoclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if AppState.Engine.NoclipConnection then AppState.Engine.NoclipConnection:Disconnect(); AppState.Engine.NoclipConnection = nil end
        local char = LocalPlayer.Character
        if char then
            for _, name in ipairs({"Torso", "UpperTorso", "Head", "HumanoidRootPart"}) do
                local p = char:FindFirstChild(name)
                if p then p.CanCollide = true end
            end
        end
    end
end

local function ProcessAIActionCommands(text)
    if not text or type(text) ~= "string" then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if string.match(text, "%[NOCLIP:on%]") then ActivateNoclip(true) end
    if string.match(text, "%[NOCLIP:off%]") then ActivateNoclip(false) end
    if string.match(text, "%[FLY:on%]") then ActivateFly(true) end
    if string.match(text, "%[FLY:off%]") then ActivateFly(false) end
    
    if hum then
        local spd = string.match(text, "%[SPEED:(%d+)%]")
        if spd then hum.WalkSpeed = tonumber(spd) end
        
        local jmp = string.match(text, "%[JUMP:(%d+)%]")
        if jmp then hum.UseJumpPower = true; hum.JumpPower = tonumber(jmp) end
        
        if string.match(text, "%[HEAL%]") then hum.Health = hum.MaxHealth end
    end
end

-- ============================================================================
-- 10. GESTIÓN DE PROMPTS Y CONTEXTO
-- ============================================================================
local SYSTEM_INSTRUCTIONS_COMMANDS = [[
INSTRUCCIONES DE ACCIÓN FÍSICA:
Si el usuario te pide modificar su personaje (volar, atravesar paredes, curarse, velocidad), DEBES incluir UNA de las siguientes etiquetas en tu respuesta:
- Volar: [FLY:on] o [FLY:off]
- Noclip: [NOCLIP:on] o [NOCLIP:off]
- Velocidad: [SPEED:numero]
- Salto: [JUMP:numero]
- Curar: [HEAL]
]]

local SYSTEM_PROMPTS = {
    Programador = "Eres Kaelen, experto AAA en programación Lua para Roblox.\n" .. SYSTEM_INSTRUCTIONS_COMMANDS,
    Analista = "Eres Kaelen, analista y supervisor de seguridad de Roblox.\n" .. SYSTEM_INSTRUCTIONS_COMMANDS,
    Creativo = "Eres Kaelen, Game Designer visionario para experiencias en Roblox.\n" .. SYSTEM_INSTRUCTIONS_COMMANDS,
    Troll = "Eres Kaelen modo Troll, maestro del caos inofensivo.\n" .. SYSTEM_INSTRUCTIONS_COMMANDS
}

local function CollectGameContext()
    local ctx = {}
    pcall(function() ctx.GameName = game.Name end)
    pcall(function() ctx.PlaceId = tostring(game.PlaceId) end)
    pcall(function() ctx.PlayerCount = tostring(#Players:GetPlayers()) end)
    pcall(function() ctx.MyName = LocalPlayer.Name end)
    local ok, json = pcall(function() return HttpService:JSONEncode(ctx) end)
    return ok and json or "{}"
end

-- ============================================================================
-- 11. MÓDULO DE RED (HTTP)
-- ============================================================================
local function GetExecutorRequestFunction()
    local fns = {
        function() return request end,
        function() return http_request end,
        function() return http and http.request end,
        function() return syn and syn.request end,
        function() return fluxus and fluxus.request end,
        function() return getgenv and getgenv().request end,
    }
    for _, fn in ipairs(fns) do
        local ok, f = pcall(fn)
        if ok and type(f) == "function" then return f end
    end
    return nil
end

local function ExecuteApiCall(modelId, messageHistory, systemPrompt)
    if not AppState.KeyVerified or AppState.APIKey == "" then return nil, "API Key no validada." end
    local reqFn = GetExecutorRequestFunction()
    if not reqFn then return nil, "Ejecutor no soporta peticiones HTTP web ('request')." end

    local payloadMsgs = {}
    if systemPrompt and systemPrompt ~= "" then
        table.insert(payloadMsgs, { role = "system", content = systemPrompt })
    end
    for _, m in ipairs(messageHistory) do
        table.insert(payloadMsgs, { role = m.role, content = m.content })
    end

    local payload = { model = modelId, max_tokens = CFG.API.MaxTokens, temperature = CFG.API.Temperature, messages = payloadMsgs }
    local okEnc, jsonBody = pcall(function() return HttpService:JSONEncode(payload) end)
    if not okEnc then return nil, "Error codificando JSON" end

    local okHttp, resp = pcall(function()
        return reqFn({
            Url = CFG.OpenRouterURL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bearer " .. tostring(AppState.APIKey) },
            Body = jsonBody
        })
    end)

    if not okHttp then return nil, "Error del ejecutor: " .. tostring(resp) end
    if type(resp) ~= "table" then return nil, "Respuesta inválida del servidor" end
    if resp.StatusCode ~= 200 then return nil, "Error HTTP " .. tostring(resp.StatusCode) .. "\n" .. tostring(resp.Body) end

    local okDec, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)
    if not okDec then return nil, "JSON corrupto" end
    if data and data.choices and data.choices[1] and data.choices[1].message then
        return data.choices[1].message.content, nil
    end
    return nil, "Estructura de respuesta inesperada"
end

local function TestAPIKeyVerification(key)
    local backupKey = AppState.APIKey; local backupVer = AppState.KeyVerified
    AppState.APIKey = key; AppState.KeyVerified = true
    local resp, err = ExecuteApiCall(CFG.Models.Fast, {{role = "user", content = "Di OK"}}, "Responde solo OK")
    if err then AppState.APIKey = backupKey; AppState.KeyVerified = backupVer; return false, err end
    return true, nil
end

-- ============================================================================
-- 12. ORQUESTADOR (TRIPLE ENGINE)
-- ============================================================================
local function CheckKeywords(text, dict)
    local lw = string.lower(text)
    for _, kw in ipairs(dict) do if string.find(lw, string.lower(kw), 1, true) then return true end end
    return false
end

local function CoreOrchestrator(userInput, history)
    local sysPrompt = SYSTEM_PROMPTS[AppState.CurrentMode] or SYSTEM_PROMPTS.Analista
    
    local isAction = CheckKeywords(userInput, {"vuela", "volar", "fly", "noclip", "atravies", "paredes", "velocidad", "speed", "salto", "jump", "cura", "heal", "vida", "activa"})
    local isCode = CheckKeywords(userInput, {"script", "lua", "código", "codigo", "optimiza", "debug"})

    -- Acción Rápida (Liquid LFM 1.2B)
    if isAction then
        local resp, err = ExecuteApiCall(CFG.Models.Fast, history, sysPrompt)
        if err then return nil, "Fallo Fast: " .. err end
        return "⚡ [Liquid 1.2B - Acción Rápida]\n\n" .. resp, nil
    end

    -- Código (Qwen 3 Coder + Hermes 3 Revisión)
    if isCode or AppState.CurrentMode == "Programador" then
        local codeResp, codeErr = ExecuteApiCall(CFG.Models.Coder, history, sysPrompt .. "\nIMPORTANTE: Solo genera el código.")
        if codeErr then return nil, "Error Coder: " .. codeErr end
        
        local revMsg = {{role = "user", content = "Revisa este código generado:\n```lua\n" .. codeResp .. "\n```"}}
        local finalResp, revErr = ExecuteApiCall(CFG.Models.Reason, revMsg, "Eres Hermes 3. Revisa y explica este código brevemente.")
        
        if revErr then return "⚡ [Qwen3-Coder (Sin revisión)]\n\n" .. codeResp, nil end
        return "⚡ [Dual: Qwen3 + Hermes 3]\n\n" .. finalResp, nil
    end

    -- Análisis Profundo (Hermes 3 405B)
    local resp, err = ExecuteApiCall(CFG.Models.Reason, history, sysPrompt)
    if err then return nil, "Error Reasoner: " .. err end
    return "⬡ [Hermes 3 405B]\n\n" .. resp, nil
end

-- ============================================================================
-- 13. UI CONSTRUCTION (MOBILE SAFE)
-- ============================================================================
local MainScreenGui = Instance.new("ScreenGui")
MainScreenGui.Name = "KaelenUI"
MainScreenGui.ResetOnSpawn = false
MainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainScreenGui.DisplayOrder = 9999
MainScreenGui.IgnoreGuiInset = true

local okInj = pcall(function() MainScreenGui.Parent = CoreGui end)
if not okInj then MainScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Botón Flotante
local FloatingButton = Instance.new("ImageButton")
FloatingButton.Name = "FloatBtn"
FloatingButton.Size = UDim2.new(0, 48, 0, 48)
FloatingButton.Position = UDim2.new(1, -60, 0.6, -24)
FloatingButton.BackgroundColor3 = CFG.Colors.Accent
FloatingButton.AutoButtonColor = false
FloatingButton.ZIndex = 500
FloatingButton.Parent = MainScreenGui
ApplyCorner(FloatingButton, 24)
ApplyStroke(FloatingButton, CFG.Colors.AccentGlow, 2)
ApplyGradient(FloatingButton, Color3.fromRGB(135, 92, 255), Color3.fromRGB(88, 48, 205), 135)

local BtnIcon = UI_TextLabel(FloatingButton, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "K", CFG.Colors.White, 20, CFG.Fonts.Bold, Enum.TextXAlignment.Center, 501)

-- Declaraciones para la ventana
local OpenKaelenWindow, CloseKaelenWindow

-- *** APLICAMOS EL NUEVO SISTEMA DE ARRASTRE ANTI-BUGS MÓVIL AL BOTÓN ***
MakeDraggableAndTappable(FloatingButton, function()
    if AppState.WindowOpen then CloseKaelenWindow() else OpenKaelenWindow() end
end)

-- Ventana Principal
local MainWindow = UI_Frame(MainScreenGui, UDim2.new(0, CFG.Window.Width, 0, CFG.Window.Height), UDim2.new(0.5, -CFG.Window.Width/2, 0.5, -CFG.Window.Height/2), CFG.Colors.Background, 0, 400, "MainWindow")
MainWindow.ClipsDescendants = true
MainWindow.Visible = false
ApplyCorner(MainWindow, 18)
ApplyStroke(MainWindow, Color3.fromRGB(65, 52, 128), 1.5)
ApplyGradient(MainWindow, Color3.fromRGB(10, 9, 22), Color3.fromRGB(6, 6, 15), 155)

-- Header
local HeaderPanel = UI_Frame(MainWindow, UDim2.new(1, 0, 0, 45), UDim2.new(0, 0, 0, 0), CFG.Colors.Surface, 0.2, 401, "HeaderPanel")
ApplyCorner(HeaderPanel, 18)
ApplyGradient(HeaderPanel, Color3.fromRGB(26, 20, 58), Color3.fromRGB(12, 10, 28), 100)

local HeaderLogoCircle = UI_Frame(HeaderPanel, UDim2.new(0, 30, 0, 30), UDim2.new(0, 10, 0.5, -15), CFG.Colors.Accent, 0, 402)
ApplyCorner(HeaderLogoCircle, 15)
ApplyGradient(HeaderLogoCircle, Color3.fromRGB(145, 95, 255), Color3.fromRGB(82, 42, 200), 135)
UI_TextLabel(HeaderLogoCircle, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "K", CFG.Colors.White, 16, CFG.Fonts.Bold, Enum.TextXAlignment.Center, 403)

local HeaderTitleLabel = UI_TextLabel(HeaderPanel, UDim2.new(0, 200, 0, 18), UDim2.new(0, 48, 0, 6), "Kaelen Ultimate", CFG.Colors.White, 15, CFG.Fonts.Bold, Enum.TextXAlignment.Left, 402)
local HeaderSubtitleLabel = UI_TextLabel(HeaderPanel, UDim2.new(0, 240, 0, 14), UDim2.new(0, 48, 0, 24), "Triple Engine  •  " .. AppState.CurrentMode, CFG.Colors.TextMuted, 9, CFG.Fonts.Regular, Enum.TextXAlignment.Left, 402)

local StatusDotIndicator = UI_Frame(HeaderPanel, UDim2.new(0, 8, 0, 8), UDim2.new(1, -45, 0.5, -4), CFG.Colors.Danger, 0, 402)
ApplyCorner(StatusDotIndicator, 4)

local CloseWindowButton = UI_TextButton(HeaderPanel, UDim2.new(0, 28, 0, 28), UDim2.new(1, -36, 0.5, -14), Color3.fromRGB(198, 52, 72), "✕", CFG.Colors.White, 13, CFG.Fonts.Bold, 402)
ApplyCorner(CloseWindowButton, 14)

-- *** APLICAMOS EL NUEVO SISTEMA DE ARRASTRE ANTI-BUGS MÓVIL AL HEADER ***
MakeDraggableAndTappable(HeaderPanel, nil) -- Nil porque el header no tiene función al darle click

-- Navegación
local NavigationBar = UI_Frame(MainWindow, UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 50), CFG.Colors.Card, 0.12, 401)
ApplyCorner(NavigationBar, 10); ApplyStroke(NavigationBar, CFG.Colors.Border, 1); CreateHorizontalLayout(NavigationBar, 5, Enum.VerticalAlignment.Center); ApplyPadding(NavigationBar, 3, 3, 4, 4)

local TAB_CONFIGURATION = {"Chat", "Modos", "Config"}
local TabReferencesList = {}
local SwitchActivePanel = function(panelName) end

local function SetActiveTabVisuals(tabName)
    for _, tabData in ipairs(TabReferencesList) do
        if tabData.name == tabName then
            CreateTween(tabData.button, {BackgroundColor3 = CFG.Colors.Accent, BackgroundTransparency = 0}, 0.2)
            CreateTween(tabData.label, {TextColor3 = CFG.Colors.White}, 0.2)
        else
            CreateTween(tabData.button, {BackgroundColor3 = CFG.Colors.Card, BackgroundTransparency = 0.6}, 0.2)
            CreateTween(tabData.label, {TextColor3 = CFG.Colors.TextMuted}, 0.2)
        end
    end
end

for _, tabName in ipairs(TAB_CONFIGURATION) do
    local btn = UI_TextButton(NavigationBar, UDim2.new(0, 90, 1, 0), UDim2.new(0, 0, 0, 0), CFG.Colors.Card, "", CFG.Colors.White, 11, CFG.Fonts.Bold, 402)
    btn.BackgroundTransparency = 0.6; ApplyCorner(btn, 8)
    local lbl = UI_TextLabel(btn, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), tabName, CFG.Colors.TextMuted, 11, CFG.Fonts.Bold, Enum.TextXAlignment.Center, 403)
    table.insert(TabReferencesList, {name = tabName, button = btn, label = lbl})
    btn.MouseButton1Click:Connect(function()
        if AppState.KeyVerified then SetActiveTabVisuals(tabName); SwitchActivePanel(tabName) end
    end)
end

-- Paneles Container
local PanelsContainer = UI_Frame(MainWindow, UDim2.new(1, -20, 1, -90), UDim2.new(0, 10, 0, 86), CFG.Colors.Black, 1, 400)

-- Panel 1: Key
local KeySystemPanel = UI_Frame(PanelsContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), CFG.Colors.Black, 1, 401)
CreateVerticalLayout(KeySystemPanel, 8, Enum.HorizontalAlignment.Center); ApplyPadding(KeySystemPanel, 10, 10, 0, 0)
local LockIcon = UI_Frame(KeySystemPanel, UDim2.new(0, 50, 0, 50), UDim2.new(0, 0, 0, 0), CFG.Colors.Card, 0.08, 402); LockIcon.LayoutOrder = 1; ApplyCorner(LockIcon, 25); ApplyStroke(LockIcon, CFG.Colors.Accent, 2)
UI_TextLabel(LockIcon, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), "🔑", CFG.Colors.White, 22, CFG.Fonts.Regular, Enum.TextXAlignment.Center, 403)
UI_TextLabel(KeySystemPanel, UDim2.new(1, 0, 0, 22), UDim2.new(0,0,0,0), "Activar Kaelen Ultimate", CFG.Colors.White, 16, CFG.Fonts.Bold, Enum.TextXAlignment.Center, 402).LayoutOrder = 2
UI_TextLabel(KeySystemPanel, UDim2.new(1, 0, 0, 30), UDim2.new(0,0,0,0), "API Key de OpenRouter requerida.", CFG.Colors.TextMuted, 10, CFG.Fonts.Regular, Enum.TextXAlignment.Center, 402).LayoutOrder = 3

local KeyInputField = Instance.new("TextBox")
KeyInputField.Size = UDim2.new(1, -8, 0, 36); KeyInputField.BackgroundColor3 = CFG.Colors.Card; KeyInputField.BackgroundTransparency = 0.08; KeyInputField.PlaceholderText = "sk-or-v1-..."
KeyInputField.TextColor3 = CFG.Colors.Text; KeyInputField.PlaceholderColor3 = CFG.Colors.TextDim; KeyInputField.TextSize = 11; KeyInputField.Font = CFG.Fonts.Monospace
KeyInputField.ClearTextOnFocus = false; KeyInputField.ZIndex = 402; KeyInputField.LayoutOrder = 4; KeyInputField.Parent = KeySystemPanel
ApplyCorner(KeyInputField, 10); ApplyStroke(KeyInputField, CFG.Colors.Border, 1); ApplyPadding(KeyInputField, 0, 0, 10, 10)

local KeyVerifyButton = UI_TextButton(KeySystemPanel, UDim2.new(1, -8, 0, 36), UDim2.new(0,0,0,0), CFG.Colors.Accent, "Verificar y Activar", CFG.Colors.White, 12, CFG.Fonts.Bold, 402); KeyVerifyButton.LayoutOrder = 5
ApplyCorner(KeyVerifyButton, 10); ApplyGradient(KeyVerifyButton, Color3.fromRGB(142, 92, 255), Color3.fromRGB(84, 44, 202), 135)

local KeyForceSaveButton = UI_TextButton(KeySystemPanel, UDim2.new(1, -8, 0, 24), UDim2.new(0,0,0,0), CFG.Colors.Warning, "⚠️ Forzar Guardado", CFG.Colors.Black, 10, CFG.Fonts.Bold, 402); KeyForceSaveButton.LayoutOrder = 6; KeyForceSaveButton.Visible = false; ApplyCorner(KeyForceSaveButton, 6)
local KeyStatusLog = UI_TextLabel(KeySystemPanel, UDim2.new(1, 0, 0, 40), UDim2.new(0,0,0,0), "", CFG.Colors.TextMuted, 10, CFG.Fonts.Regular, Enum.TextXAlignment.Center, 402); KeyStatusLog.LayoutOrder = 7

-- Panel 2: Chat
local InteractiveChatPanel = UI_Frame(PanelsContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), CFG.Colors.Black, 1, 401); InteractiveChatPanel.Visible = false
local MessageScrollingArea = UI_ScrollingFrame(InteractiveChatPanel, UDim2.new(1, 0, 1, -70), UDim2.new(0, 0, 0, 0), 402)
CreateVerticalLayout(MessageScrollingArea, 8, Enum.HorizontalAlignment.Left); ApplyPadding(MessageScrollingArea, 6, 6, 4, 4)

local ThinkingIndicatorFrame = UI_Frame(MessageScrollingArea, UDim2.new(0, 140, 0, 28), UDim2.new(0,0,0,0), CFG.Colors.AIBubble, 0.05, 403); ThinkingIndicatorFrame.LayoutOrder = 9999; ThinkingIndicatorFrame.Visible = false
ApplyCorner(ThinkingIndicatorFrame, 14); ApplyStroke(ThinkingIndicatorFrame, CFG.Colors.Border, 1); ApplyPadding(ThinkingIndicatorFrame, 0, 0, 10, 10)
local ThinkingLabel = UI_TextLabel(ThinkingIndicatorFrame, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), "Procesando...", CFG.Colors.TextMuted, 11, CFG.Fonts.Regular, Enum.TextXAlignment.Left, 404)

local ChatInputContainer = UI_Frame(InteractiveChatPanel, UDim2.new(1, 0, 0, 66), UDim2.new(0, 0, 1, -66), CFG.Colors.Surface, 0.18, 402)
ApplyCorner(ChatInputContainer, 12); ApplyStroke(ChatInputContainer, CFG.Colors.Border, 1)

local ChatTextBox = Instance.new("TextBox")
ChatTextBox.Size = UDim2.new(1, -44, 0, 34); ChatTextBox.Position = UDim2.new(0, 6, 0, 6); ChatTextBox.BackgroundColor3 = CFG.Colors.Card; ChatTextBox.BackgroundTransparency = 0.08
ChatTextBox.PlaceholderText = "Comando o consulta..."; ChatTextBox.TextColor3 = CFG.Colors.Text; ChatTextBox.PlaceholderColor3 = CFG.Colors.TextDim; ChatTextBox.TextSize = 11; ChatTextBox.Font = CFG.Fonts.Regular; ChatTextBox.ClearTextOnFocus = false
ChatTextBox.ZIndex = 403; ChatTextBox.Parent = ChatInputContainer; ApplyCorner(ChatTextBox, 8); ApplyPadding(ChatTextBox, 0, 0, 10, 10)

local ChatSendButton = UI_TextButton(ChatInputContainer, UDim2.new(0, 34, 0, 34), UDim2.new(1, -38, 0, 6), CFG.Colors.Accent, "➤", CFG.Colors.White, 14, CFG.Fonts.Bold, 403)
ApplyCorner(ChatSendButton, 8); ApplyGradient(ChatSendButton, Color3.fromRGB(142, 92, 255), Color3.fromRGB(84, 44, 202), 135)

local QuickCommandBar = UI_Frame(ChatInputContainer, UDim2.new(1, -8, 0, 22), UDim2.new(0, 4, 0, 42), CFG.Colors.Black, 1, 403)
CreateHorizontalLayout(QuickCommandBar, 5, Enum.VerticalAlignment.Center)
local QuickCommandsData = { { icon = "🎮", label = "Analizar", id = "cmd_analyze" }, { icon = "🚀", label = "Volar", id = "cmd_fly" }, { icon = "👻", label = "Noclip", id = "cmd_noclip" }, { icon = "🗑", label = "Limpiar", id = "cmd_clear" } }
local QuickCommandReferences = {}
for _, cmd in ipairs(QuickCommandsData) do
    local qBtn = UI_TextButton(QuickCommandBar, UDim2.new(0, 0, 1, 0), UDim2.new(0,0,0,0), CFG.Colors.Card, cmd.icon .. " " .. cmd.label, CFG.Colors.TextMuted, 9, CFG.Fonts.Regular, 404)
    qBtn.AutomaticSize = Enum.AutomaticSize.X; qBtn.BackgroundTransparency = 0.3; ApplyCorner(qBtn, 5); ApplyPadding(qBtn, 1, 1, 5, 5)
    table.insert(QuickCommandReferences, { buttonObject = qBtn, commandId = cmd.id })
end

-- Panel 3: Modos
local ModesSelectionPanel = UI_ScrollingFrame(PanelsContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 401); ModesSelectionPanel.Visible = false
CreateVerticalLayout(ModesSelectionPanel, 6, Enum.HorizontalAlignment.Center); ApplyPadding(ModesSelectionPanel, 4, 4, 0, 0)
UI_TextLabel(ModesSelectionPanel, UDim2.new(1, 0, 0, 20), UDim2.new(0,0,0,0), "Personalidad", CFG.Colors.White, 14, CFG.Fonts.Bold, Enum.TextXAlignment.Center, 402).LayoutOrder = 0

local AvailableModesList = {
    { name = "Programador", icon = "💻", color = Color3.fromRGB(78, 198, 255), description = "Scripts Lua y Qwen3 Coder." },
    { name = "Analista",    icon = "🔍", color = Color3.fromRGB(112, 72, 255), description = "Análisis profundo con Hermes 3." },
    { name = "Creativo",    icon = "🎨", color = Color3.fromRGB(255, 138, 78), description = "Game Design e Innovación." },
    { name = "Troll",       icon = "😈", color = Color3.fromRGB(255, 78, 128), description = "Humor, caos y comandos locos." },
}
local ModeCardReferences = {}
for i, md in ipairs(AvailableModesList) do
    local active = (md.name == AppState.CurrentMode)
    local card = UI_TextButton(ModesSelectionPanel, UDim2.new(1, 0, 0, 50), UDim2.new(0,0,0,0), CFG.Colors.Card, "", CFG.Colors.White, 13, CFG.Fonts.Bold, 402); card.BackgroundTransparency = active and 0.05 or 0.3; card.LayoutOrder = i
    ApplyCorner(card, 10); local stroke = ApplyStroke(card, active and CFG.Colors.Accent or CFG.Colors.Border, active and 1.5 or 1)
    local iconBg = UI_Frame(card, UDim2.new(0, 34, 0, 34), UDim2.new(0, 10, 0.5, -17), md.color, 0.12, 403); ApplyCorner(iconBg, 17)
    UI_TextLabel(iconBg, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), md.icon, CFG.Colors.White, 16, CFG.Fonts.Regular, Enum.TextXAlignment.Center, 404)
    UI_TextLabel(card, UDim2.new(1, -60, 0, 16), UDim2.new(0, 52, 0, 8), md.name, CFG.Colors.White, 12, CFG.Fonts.Bold, Enum.TextXAlignment.Left, 403)
    UI_TextLabel(card, UDim2.new(1, -60, 0, 14), UDim2.new(0, 52, 0, 26), md.description, CFG.Colors.TextMuted, 9, CFG.Fonts.Regular, Enum.TextXAlignment.Left, 403)
    local badge = UI_Frame(card, UDim2.new(0, 8, 0, 8), UDim2.new(1, -16, 0.5, -4), md.color, active and 0 or 1, 403); ApplyCorner(badge, 4)
    table.insert(ModeCardReferences, { card = card, stroke = stroke, badge = badge, name = md.name })
    
    card.MouseButton1Click:Connect(function()
        AppState.CurrentMode = md.name; HeaderSubtitleLabel.Text = "Triple Engine  •  " .. AppState.CurrentMode
        for _, ref in ipairs(ModeCardReferences) do
            local isAct = (ref.name == md.name)
            CreateTween(ref.card, {BackgroundTransparency = isAct and 0.05 or 0.3}, 0.22)
            CreateTween(ref.badge, {BackgroundTransparency = isAct and 0 or 1}, 0.22)
            ref.stroke.Color = isAct and CFG.Colors.Accent or CFG.Colors.Border; ref.stroke.Thickness = isAct and 1.5 or 1
        end
    end)
end

-- Panel 4: Config
local ConfigurationPanel = UI_ScrollingFrame(PanelsContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 401); ConfigurationPanel.Visible = false
CreateVerticalLayout(ConfigurationPanel, 8, Enum.HorizontalAlignment.Center); ApplyPadding(ConfigurationPanel, 4, 4, 0, 0)
local InfoCard = UI_Frame(ConfigurationPanel, UDim2.new(1, 0, 0, 65), UDim2.new(0, 0, 0, 0), CFG.Colors.Card, 0.18, 402); ApplyCorner(InfoCard, 10); ApplyStroke(InfoCard, CFG.Colors.Border, 1); ApplyPadding(InfoCard, 6, 6, 10, 10)

UI_TextLabel(InfoCard, UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), "⚡ Kaelen Ultimate — Triple-Engine\n🟢 Fast: Liquid LFM 1.2B\n🔵 Coder: Qwen 3\n🟣 Reason: Hermes 3 405B", CFG.Colors.TextMuted, 9, CFG.Fonts.Regular, Enum.TextXAlignment.Left, 403)

local WipeBtn = UI_TextButton(ConfigurationPanel, UDim2.new(1, 0, 0, 32), UDim2.new(0,0,0,0), CFG.Colors.Card, "🗑 Borrar Historial", CFG.Colors.TextMuted, 11, CFG.Fonts.Bold, 402); WipeBtn.BackgroundTransparency = 0.2; ApplyCorner(WipeBtn, 10); ApplyStroke(WipeBtn, CFG.Colors.Border, 1)
local ResetBtn = UI_TextButton(ConfigurationPanel, UDim2.new(1, 0, 0, 32), UDim2.new(0,0,0,0), CFG.Colors.Danger, "⚠ Resetear Clave de API", CFG.Colors.White, 11, CFG.Fonts.Bold, 402); ResetBtn.BackgroundTransparency = 0.28; ApplyCorner(ResetBtn, 10)

-- ============================================================================
-- 14. LOGICA VISUAL Y EVENTOS
-- ============================================================================
local AllPanelsArray = { KeySystemPanel, InteractiveChatPanel, ModesSelectionPanel, ConfigurationPanel }
SwitchActivePanel = function(name)
    for _, p in ipairs(AllPanelsArray) do p.Visible = false end
    if name == "Key" then KeySystemPanel.Visible = true elseif name == "Chat" then InteractiveChatPanel.Visible = true elseif name == "Modos" then ModesSelectionPanel.Visible = true elseif name == "Config" then ConfigurationPanel.Visible = true end
end

local function AutoScrollToBottom()
    task.delay(0.06, function() if MessageScrollingArea and MessageScrollingArea.Parent then MessageScrollingArea.CanvasPosition = Vector2.new(0, MessageScrollingArea.AbsoluteCanvasSize.Y + 9999) end end)
end

local function AddMessageToUI(role, content)
    table.insert(AppState.Messages, { role = role, content = content })
    if #AppState.Messages > CFG.API.MaxHistory then table.remove(AppState.Messages, 1) end
    AppState.MessageCount = AppState.MessageCount + 1
    
    local isUsr = (role == "user")
    local row = UI_Frame(MessageScrollingArea, UDim2.new(1, 0, 0, 0), UDim2.new(0,0,0,0), CFG.Colors.Black, 1, 403); row.AutomaticSize = Enum.AutomaticSize.Y; row.LayoutOrder = AppState.MessageCount
    local bub = UI_Frame(row, UDim2.new(0.84, 0, 0, 0), UDim2.new(isUsr and 0.16 or 0, 0, 0, 0), isUsr and CFG.Colors.UserBubble or CFG.Colors.AIBubble, 0.05, 404); bub.AutomaticSize = Enum.AutomaticSize.Y
    ApplyCorner(bub, 12); ApplyPadding(bub, 8, 8, 10, 10); if not isUsr then ApplyStroke(bub, CFG.Colors.Border, 1) end
    CreateVerticalLayout(bub, 4, isUsr and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left)
    
    local aName = isUsr and ("🧑 " .. LocalPlayer.Name) or "⬡ Kaelen"
    local aCol = isUsr and Color3.fromRGB(185, 158, 255) or CFG.Colors.Accent
    local aAlign = isUsr and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    UI_TextLabel(bub, UDim2.new(1, 0, 0, 12), UDim2.new(0,0,0,0), aName, aCol, 9, CFG.Fonts.Bold, aAlign, 405).LayoutOrder = 1
    local txtLbl = UI_TextLabel(bub, UDim2.new(1, 0, 0, 0), UDim2.new(0,0,0,0), content, CFG.Colors.Text, 11, CFG.Fonts.Regular, aAlign, 405); txtLbl.AutomaticSize = Enum.AutomaticSize.Y; txtLbl.LayoutOrder = 2
    
    bub.BackgroundTransparency = 1; txtLbl.TextTransparency = 1
    CreateTween(bub, {BackgroundTransparency = 0.05}, 0.3); CreateTween(txtLbl, {TextTransparency = 0}, 0.3)
    AutoScrollToBottom()
end

local function SetThinkingState(isActive)
    AppState.IsThinking = isActive; ThinkingIndicatorFrame.Visible = isActive
    if isActive then
        ThinkingIndicatorFrame.LayoutOrder = AppState.MessageCount + 1
        if AppState.ThinkTaskThread then task.cancel(AppState.ThinkTaskThread) end
        AppState.ThinkTaskThread = task.spawn(function()
            local frames = { "●○○", "●●○", "●●●", "○●●", "○○●", "○○○" }
            local idx = 1
            while AppState.IsThinking do
                ThinkingLabel.Text = "Pensando " .. frames[idx]
                idx = (idx % #frames) + 1; task.wait(0.28)
            end
        end)
        AutoScrollToBottom()
    elseif AppState.ThinkTaskThread then
        task.cancel(AppState.ThinkTaskThread); AppState.ThinkTaskThread = nil
    end
end

local function ProcessInput(text)
    local safeTxt = string.match(text or "", "^%s*(.-)%s*$")
    if safeTxt == "" or AppState.IsThinking then return end
    ChatTextBox.Text = ""; AddMessageToUI("user", safeTxt); SetThinkingState(true)
    
    task.spawn(function()
        local resp, err = CoreOrchestrator(safeTxt, AppState.Messages)
        SetThinkingState(false)
        if err then AddMessageToUI("assistant", "⚠️ Error:\n" .. tostring(err)) else
            ProcessAIActionCommands(resp)
            AddMessageToUI("assistant", resp or "Sin respuesta.")
        end
    end)
end

ChatSendButton.MouseButton1Click:Connect(function() ProcessInput(ChatTextBox.Text) end)
ChatTextBox.FocusLost:Connect(function(enter) if enter then ProcessInput(ChatTextBox.Text) end end)

for _, r in ipairs(QuickCommandReferences) do
    r.buttonObject.MouseButton1Click:Connect(function()
        if r.commandId == "cmd_analyze" then ProcessInput("🎮 Analiza este juego y dime sus fallos:\n" .. CollectGameContext())
        elseif r.commandId == "cmd_fly" then ProcessInput("Activa mi modo vuelo por favor.")
        elseif r.commandId == "cmd_noclip" then ProcessInput("Activa el noclip (atravesar paredes).")
        elseif r.commandId == "cmd_clear" then
            for _, c in ipairs(MessageScrollingArea:GetChildren()) do if c:IsA("Frame") and c.Name ~= "ThinkingIndicator" then c:Destroy() end end
            AppState.Messages = {}; AppState.MessageCount = 0; AddMessageToUI("assistant", "🗑 Memoria limpiada.")
        end
    end)
end

KeyVerifyButton.MouseButton1Click:Connect(function()
    local key = string.match(KeyInputField.Text, "^%s*(.-)%s*$")
    if not key or key == "" then KeyStatusLog.Text = "⚠️ Key vacía."; return end
    KeyVerifyButton.Text = "⏳ Conectando..."; KeyForceSaveButton.Visible = false
    task.spawn(function()
        local ok, err = TestAPIKeyVerification(key)
        if ok then
            AppState.APIKey = key; AppState.KeyVerified = true; KeyStatusLog.TextColor3 = CFG.Colors.Success; KeyStatusLog.Text = "✅ Activado."
            CreateTween(StatusDotIndicator, {BackgroundColor3 = CFG.Colors.Success}, 0.5); task.wait(1)
            SwitchActivePanel("Chat"); SetActiveTabVisuals("Chat")
            AddMessageToUI("assistant", "⬡ Conectado a OpenRouter.\n\nMotores Cargados:\n• Qwen3-Coder\n• Hermes 3 405B\n• Liquid LFM 1.2B\n\n¿En qué te ayudo hoy?")
        else
            AppState.KeyVerified = false; KeyStatusLog.TextColor3 = CFG.Colors.Danger; KeyStatusLog.Text = "❌ Falla: " .. tostring(err)
            KeyVerifyButton.Text = "Reintentar"; if string.match(key, "^sk%-or%-") then KeyForceSaveButton.Visible = true end
        end
    end)
end)

KeyForceSaveButton.MouseButton1Click:Connect(function()
    local key = string.match(KeyInputField.Text, "^%s*(.-)%s*$")
    if key and key ~= "" then
        AppState.APIKey = key; AppState.KeyVerified = true; KeyStatusLog.TextColor3 = CFG.Colors.Warning; KeyStatusLog.Text = "⚠️ Guardado forzado."
        CreateTween(StatusDotIndicator, {BackgroundColor3 = CFG.Colors.Warning}, 0.5); task.wait(1); SwitchActivePanel("Chat"); SetActiveTabVisuals("Chat")
    end
end)

WipeBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(MessageScrollingArea:GetChildren()) do if c:IsA("Frame") and c.Name ~= "ThinkingIndicator" then c:Destroy() end end
    AppState.Messages = {}; AppState.MessageCount = 0
end)

ResetBtn.MouseButton1Click:Connect(function()
    AppState.APIKey = ""; AppState.KeyVerified = false; AppState.Messages = {}; AppState.MessageCount = 0
    KeyInputField.Text = ""; KeyStatusLog.Text = ""; StatusDotIndicator.BackgroundColor3 = CFG.Colors.Danger
    for _, c in ipairs(MessageScrollingArea:GetChildren()) do if c:IsA("Frame") and c.Name ~= "ThinkingIndicator" then c:Destroy() end end
    SwitchActivePanel("Key")
end)

OpenKaelenWindow = function()
    AppState.WindowOpen = true; MainWindow.Visible = true
    MainWindow.Size = UDim2.new(0, 0, 0, 0); MainWindow.Position = UDim2.new(FloatingButton.Position.X.Scale, FloatingButton.Position.X.Offset + 24, FloatingButton.Position.Y.Scale, FloatingButton.Position.Y.Offset + 24)
    CreateTween(MainWindow, { Size = UDim2.new(0, CFG.Window.Width, 0, CFG.Window.Height), Position = UDim2.new(0.5, -CFG.Window.Width/2, 0.5, -CFG.Window.Height/2) }, 0.40, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

CloseKaelenWindow = function()
    AppState.WindowOpen = false
    CreateTween(MainWindow, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(FloatingButton.Position.X.Scale, FloatingButton.Position.X.Offset + 24, FloatingButton.Position.Y.Scale, FloatingButton.Position.Y.Offset + 24) }, 0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.28, function() if MainWindow and MainWindow.Parent then MainWindow.Visible = false end end)
end

CloseWindowButton.MouseButton1Click:Connect(CloseKaelenWindow)

SwitchActivePanel("Key")
SetActiveTabVisuals("Chat")
