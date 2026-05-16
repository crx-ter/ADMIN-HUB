-- ┌─────────────────────────────────────────────────────────┐
-- │               SERVICIOS DE ROBLOX                       │
-- └─────────────────────────────────────────────────────────┘
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
local StarterGui        = game:GetService("StarterGui")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera            = Workspace.CurrentCamera

-- ┌─────────────────────────────────────────────────────────┐
-- │         JUGADOR LOCAL + PARENT DEL GUI                  │
-- └─────────────────────────────────────────────────────────┘
local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

-- Intentamos usar CoreGui para mayor seguridad/ocultación
-- Si falla (ejecutor no lo permite), caemos a PlayerGui
local guiParent
local ok = pcall(function()
    local t = Instance.new("ScreenGui")
    t.Parent = CoreGui
    t:Destroy()
    guiParent = CoreGui
end)
if not ok then guiParent = PlayerGui end

-- ┌─────────────────────────────────────────────────────────┐
-- │            SISTEMA DE CONFIGURACIÓN GLOBAL              │
-- └─────────────────────────────────────────────────────────┘
-- Aquí guardamos TODOS los valores de toggles/sliders/dropdowns
-- en tiempo real. También se usa para serializar a JSON.
local Config = {
    -- VISUALES
    ESP_BOX         = false,
    TRACERS         = false,
    ESP_NAMES       = false,
    ESP_HEALTH      = false,
    KATANA_STATUS   = false,
    -- COMBATE
    SILENT_AIM      = false,
    SILENT_AIM_DIR  = "DIR_HEAD",
    HIT_CHANCE_ON   = false,
    HIT_CHANCE_VAL  = 100,
    SHOW_FOV        = false,
    FOV_RADIUS      = 50,
    PREDICTION      = false,
    TRIGGER_BOT     = false,
    -- MÍSTICO
    ANTI_KATANA     = false,
    RESOLVER        = false,
    ANTI_LOCK       = false,
    -- MOVIMIENTO
    MOD_SPEED       = false,
    WALK_SPEED      = 16,
    FLY_ON          = false,
    FLY_SPEED       = 50,
    -- AJUSTES
    AUTO_LOAD       = false,
    PERF_MODE       = false,
    PIN_BTN         = false,
    HIDE_BTN        = false,
    LANGUAGE        = "Español",
}

-- ┌─────────────────────────────────────────────────────────┐
-- │         SISTEMA DE LOCALIZACIÓN (i18n) AVANZADO        │
-- └─────────────────────────────────────────────────────────┘
local CurrentLanguage = Config.LANGUAGE

local Lang = {
    ["Español"] = {
        TAB_VISUALS = "VISUALES", TAB_COMBAT = "COMBATE", TAB_MISTIC = "MÍSTICO",
        TAB_MOVEMENT = "MOVIMIENTO", TAB_SETTINGS = "AJUSTES",
        ESP_BOX = "Cajas ESP", TRACERS = "Trazadoras", ESP_NAMES = "Nombres",
        ESP_HEALTH = "Vida", KATANA_STATUS = "Estado de Katana",
        SILENT_AIM = "Apuntado Silencioso", DIR_TITLE = "Dirección",
        DIR_HEAD = "Cabeza", DIR_CHEST = "Pecho", DIR_ALL = "General",
        HIT_CHANCE_ON = "Activar Probabilidad de Acierto", HIT_CHANCE_VAL = "Porcentaje (%)",
        SHOW_FOV = "Mostrar FOV", FOV_RADIUS = "Radio del FOV",
        PREDICTION = "Predicción", TRIGGER_BOT = "Gatillo Automático",
        ANTI_KATANA = "Anti-Katana", RESOLVER = "Resolver", ANTI_LOCK = "Anti-Bloqueo",
        MOD_SPEED = "Modificar Velocidad", WALK_SPEED = "Velocidad de Caminado",
        FLY_ON = "Volar", FLY_SPEED = "Velocidad de Vuelo",
        SAVE_CFG = "Guardar Config", LOAD_CFG = "Cargar Config",
        AUTO_LOAD = "Carga Automática", PERF_MODE = "Modo Rendimiento",
        PIN_BTN = "Fijar Botón", HIDE_BTN = "Ocultar Botón",
        LANG_TITLE = "Idioma",
    },
    ["Inglés"] = {
        TAB_VISUALS = "VISUALS", TAB_COMBAT = "COMBAT", TAB_MISTIC = "MYSTIC",
        TAB_MOVEMENT = "MOVEMENT", TAB_SETTINGS = "SETTINGS",
        ESP_BOX = "ESP Boxes", TRACERS = "Tracers", ESP_NAMES = "Names",
        ESP_HEALTH = "Health", KATANA_STATUS = "Katana Status",
        SILENT_AIM = "Silent Aim", DIR_TITLE = "Target Part",
        DIR_HEAD = "Head", DIR_CHEST = "Chest", DIR_ALL = "General",
        HIT_CHANCE_ON = "Enable Hit Chance", HIT_CHANCE_VAL = "Hit Chance (%)",
        SHOW_FOV = "Show FOV", FOV_RADIUS = "FOV Radius",
        PREDICTION = "Prediction", TRIGGER_BOT = "Trigger Bot",
        ANTI_KATANA = "Anti-Katana", RESOLVER = "Resolver", ANTI_LOCK = "Anti-Lock",
        MOD_SPEED = "Modify Speed", WALK_SPEED = "Walk Speed",
        FLY_ON = "Fly", FLY_SPEED = "Fly Speed",
        SAVE_CFG = "Save Config", LOAD_CFG = "Load Config",
        AUTO_LOAD = "Auto Load", PERF_MODE = "Performance Mode",
        PIN_BTN = "Pin Button", HIDE_BTN = "Hide Button",
        LANG_TITLE = "Language",
    },
    ["Portugués"] = {
        TAB_VISUALS = "VISUAIS", TAB_COMBAT = "COMBATE", TAB_MISTIC = "MÍSTICO",
        TAB_MOVEMENT = "MOVIMENTO", TAB_SETTINGS = "CONFIGURAÇÕES",
        ESP_BOX = "Caixas ESP", TRACERS = "Rastreadores", ESP_NAMES = "Nomes",
        ESP_HEALTH = "Vida", KATANA_STATUS = "Status da Katana",
        SILENT_AIM = "Mira Silenciosa", DIR_TITLE = "Direção",
        DIR_HEAD = "Cabeça", DIR_CHEST = "Peito", DIR_ALL = "Geral",
        HIT_CHANCE_ON = "Ativar Chance de Acerto", HIT_CHANCE_VAL = "Chance (%)",
        SHOW_FOV = "Mostrar FOV", FOV_RADIUS = "Raio do FOV",
        PREDICTION = "Previsão", TRIGGER_BOT = "Gatilho Automático",
        ANTI_KATANA = "Anti-Katana", RESOLVER = "Resolver", ANTI_LOCK = "Anti-Bloqueio",
        MOD_SPEED = "Modificar Velocidade", WALK_SPEED = "Velocidade",
        FLY_ON = "Voar", FLY_SPEED = "Velocidade de Voo",
        SAVE_CFG = "Salvar Config", LOAD_CFG = "Carregar Config",
        AUTO_LOAD = "Carregamento Automático", PERF_MODE = "Modo Desempenho",
        PIN_BTN = "Fixar Botão", HIDE_BTN = "Ocultar Botão",
        LANG_TITLE = "Idioma",
    },
    ["Ruso"] = {
        TAB_VISUALS = "ВИЗУАЛЫ", TAB_COMBAT = "БОЙ", TAB_MISTIC = "МИСТИКА",
        TAB_MOVEMENT = "ДВИЖЕНИЕ", TAB_SETTINGS = "НАСТРОЙКИ",
        ESP_BOX = "ESP Коробки", TRACERS = "Трейсеры", ESP_NAMES = "Имена",
        ESP_HEALTH = "Здоровье", KATANA_STATUS = "Статус Катаны",
        SILENT_AIM = "Тихий Аим", DIR_TITLE = "Цель",
        DIR_HEAD = "Голова", DIR_CHEST = "Грудь", DIR_ALL = "Общее",
        HIT_CHANCE_ON = "Шанс Попадания", HIT_CHANCE_VAL = "Шанс (%)",
        SHOW_FOV = "Показать FOV", FOV_RADIUS = "Радиус FOV",
        PREDICTION = "Предугадывание", TRIGGER_BOT = "Автоспуск",
        ANTI_KATANA = "Анти-Катана", RESOLVER = "Резольвер", ANTI_LOCK = "Анти-Захват",
        MOD_SPEED = "Изменить Скорость", WALK_SPEED = "Скорость Ходьбы",
        FLY_ON = "Полет", FLY_SPEED = "Скорость Полета",
        SAVE_CFG = "Сохранить", LOAD_CFG = "Загрузить",
        AUTO_LOAD = "Автозагрузка", PERF_MODE = "Производительность",
        PIN_BTN = "Закрепить", HIDE_BTN = "Скрыть",
        LANG_TITLE = "Язык",
    },
    ["Pastún"] = {
        TAB_VISUALS = "لیدونه", TAB_COMBAT = "جګړه", TAB_MISTIC = "صوفیانه",
        TAB_MOVEMENT = "حرکت", TAB_SETTINGS = "تنظیمات",
        ESP_BOX = "ESP بکسونه", TRACERS = "تعقیبونکي", ESP_NAMES = "نومونه",
        ESP_HEALTH = "روغتیا", KATANA_STATUS = "د کټانا حالت",
        SILENT_AIM = "خاموش هدف", DIR_TITLE = "لارښوونه",
        DIR_HEAD = "سر", DIR_CHEST = "سینه", DIR_ALL = "عمومي",
        HIT_CHANCE_ON = "د وهلو چانس", HIT_CHANCE_VAL = "چانس (%)",
        SHOW_FOV = "FOV وښایاست", FOV_RADIUS = "د FOV شعاع",
        PREDICTION = "وړاندوینه", TRIGGER_BOT = "اتوماتیک محرک",
        ANTI_KATANA = "انټي-کټانا", RESOLVER = "حل کوونکی", ANTI_LOCK = "انټي-لاک",
        MOD_SPEED = "سرعت بدل کړئ", WALK_SPEED = "د تګ سرعت",
        FLY_ON = "الوتنه", FLY_SPEED = "د الوتنې سرعت",
        SAVE_CFG = "خوندي کړئ", LOAD_CFG = "بار کړئ",
        AUTO_LOAD = "اتومات بار", PERF_MODE = "فعالیت",
        PIN_BTN = "پن کړئ", HIDE_BTN = "پټ کړئ",
        LANG_TITLE = "ژبه",
    },
}

-- Tabla de todos los elementos que deben actualizarse al cambiar idioma
local TranslatingElements = {}

-- Registra un elemento UI para que reciba traducciones automáticamente
local function RegisterTranslation(instance, type, key, extra)
    table.insert(TranslatingElements, { UI = instance, Type = type, Key = key, Extra = extra or {} })
    -- Aplica la traducción inmediatamente
    if type == "Text" then
        instance.Text = Lang[CurrentLanguage][key] or key
    elseif type == "DropdownTitle" then
        local sel = extra and (Lang[CurrentLanguage][extra.CurrentSelectionKey] or extra.CurrentSelectionKey) or ""
        instance.Text = (Lang[CurrentLanguage][key] or key) .. ": " .. sel
    elseif type == "DropdownOption" then
        instance.Text = "  " .. (Lang[CurrentLanguage][key] or key)
    end
end

-- Actualiza todos los elementos registrados con el nuevo idioma
local function UpdateLanguage(newLang)
    CurrentLanguage = newLang
    Config.LANGUAGE = newLang
    for _, item in ipairs(TranslatingElements) do
        local langTable = Lang[CurrentLanguage]
        if item.Type == "Text" then
            item.UI.Text = langTable[item.Key] or item.Key
        elseif item.Type == "DropdownTitle" then
            local sel = langTable[item.Extra.CurrentSelectionKey] or item.Extra.CurrentSelectionKey or ""
            item.UI.Text = (langTable[item.Key] or item.Key) .. ": " .. sel
        elseif item.Type == "DropdownOption" then
            item.UI.Text = "  " .. (langTable[item.Key] or item.Key)
        end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │              SISTEMA DE EVENTOS INTERNO                 │
-- └─────────────────────────────────────────────────────────┘
-- Un bus de eventos simple para comunicar módulos sin acoplamiento
local EventBus = {}
EventBus._listeners = {}

function EventBus:On(event, callback)
    if not self._listeners[event] then self._listeners[event] = {} end
    table.insert(self._listeners[event], callback)
end

function EventBus:Fire(event, ...)
    if self._listeners[event] then
        for _, cb in ipairs(self._listeners[event]) do
            pcall(cb, ...)
        end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │        SISTEMA DE TEMA / VARIABLES DE DISEÑO            │
-- └─────────────────────────────────────────────────────────┘
local Theme = {
    -- Colores principales
    MainColor           = Color3.fromRGB(10, 10, 14),
    GlassTransparency   = 0.30,
    AccentColor         = Color3.fromRGB(10, 132, 255),
    AccentSecondary     = Color3.fromRGB(48, 209, 88),   -- verde para "activo"
    DangerColor         = Color3.fromRGB(255, 69, 58),   -- rojo para advertencias
    TextColor           = Color3.fromRGB(245, 245, 250),
    SecondaryText       = Color3.fromRGB(160, 160, 170),
    BorderColor         = Color3.fromRGB(255, 255, 255),
    BorderTransparency  = 0.82,
    DropdownColor       = Color3.fromRGB(22, 22, 28),
    CardColor           = Color3.fromRGB(20, 20, 26),
    CardTransparency    = 0.50,
    -- Animaciones
    TweenDuration       = 0.3,
    TweenStyle          = Enum.EasingStyle.Quart,
    TweenDir            = Enum.EasingDirection.Out,
}

-- ┌─────────────────────────────────────────────────────────┐
-- │              HELPERS / UTILIDADES GENERALES             │
-- └─────────────────────────────────────────────────────────┘

-- Crea una instancia Roblox con propiedades de forma limpia
local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        if k ~= "Parent" then inst[k] = v end
    end
    if properties.Parent then inst.Parent = properties.Parent end
    return inst
end

-- Crea un Tween con los valores del tema global
local function Tween(object, props, duration, style, dir)
    local info = TweenInfo.new(
        duration or Theme.TweenDuration,
        style    or Theme.TweenStyle,
        dir      or Theme.TweenDir
    )
    local tw = TweenService:Create(object, info, props)
    tw:Play()
    return tw
end

-- Aplica una sombra de drop-shadow a un Frame usando ImageLabel
local function ApplyShadow(frame, offset, transparency)
    offset        = offset or 15
    transparency  = transparency or 0.6
    local shadow = Create("ImageLabel", {
        Name               = "Shadow",
        Parent             = frame,
        AnchorPoint        = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position           = UDim2.new(0.5, 0, 0.5, offset / 2),
        Size               = UDim2.new(1, offset * 2, 1, offset * 2),
        ZIndex             = frame.ZIndex - 1,
        Image              = "rbxassetid://5028857084",
        ImageColor3        = Color3.fromRGB(0, 0, 0),
        ImageTransparency  = transparency,
        ScaleType          = Enum.ScaleType.Slice,
        SliceCenter        = Rect.new(24, 24, 276, 276),
    })
    return shadow
end

-- Actualiza el CanvasSize de un ScrollingFrame según su contenido
local function UpdateCanvasSize(scrollFrame)
    local layout = scrollFrame:FindFirstChildOfClass("UIListLayout")
    if layout then
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
    end
end

-- Redondea un número a N decimales
local function Round(n, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor(n * factor + 0.5) / factor
end

-- Obtiene el mejor objetivo del juego según distancia al centro de pantalla
-- (esto es usada por SilentAim, TriggerBot, etc.)
local function GetClosestPlayerToMouse(maxRadius)
    maxRadius = maxRadius or Config.FOV_RADIUS
    local closestPlayer  = nil
    local closestDist    = math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            -- Intentamos apuntar a la parte configurada
            local partName = "HumanoidRootPart"
            if Config.SILENT_AIM_DIR == "DIR_HEAD" then
                partName = "Head"
            elseif Config.SILENT_AIM_DIR == "DIR_CHEST" then
                partName = "UpperTorso"
            end

            local part = player.Character:FindFirstChild(partName)
                      or player.Character:FindFirstChild("HumanoidRootPart")

            if part then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                        if dist2D <= maxRadius and dist2D < closestDist then
                            closestDist   = dist2D
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer, closestDist
end

local function GetBestSilentAimTarget(maxRadius)
    maxRadius = maxRadius or Config.FOV_RADIUS
    local bestPlayer, bestPart, bestScore = nil, nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local camPos = Camera.CFrame.Position
    local camLook = Camera.CFrame.LookVector

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local part = getTargetPartFromPlayer(player)
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if screenDist <= maxRadius then
                            local toTarget = (part.Position - camPos)
                            if toTarget.Magnitude > 0 then
                                local dot = math.clamp(camLook:Dot(toTarget.Unit), -1, 1)
                                local angle = math.deg(math.acos(dot))
                                local distance = toTarget.Magnitude
                                local score = screenDist + angle * 0.25 + distance * 0.008
                                if score < bestScore then
                                    bestScore = score
                                    bestPlayer = player
                                    bestPart = part
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPlayer, bestPart, bestScore
end

-- ┌─────────────────────────────────────────────────────────┐
-- │       CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO            │
-- └─────────────────────────────────────────────────────────┘

-- ScreenGui principal
local ScreenGui = Create("ScreenGui", {
    Name            = "LXNDXN_UI_v3",
    Parent          = guiParent,
    ResetOnSpawn    = false,
    IgnoreGuiInset  = true,
    DisplayOrder    = 999,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
})

-- ── BOTÓN FLOTANTE ──────────────────────────────────────────
local FloatButton = Create("TextButton", {
    Name                = "FloatButton",
    Parent              = ScreenGui,
    Size                = UDim2.new(0, 52, 0, 52),
    Position            = UDim2.new(0.92, 0, 0.08, 0),
    AnchorPoint         = Vector2.new(0.5, 0.5),
    BackgroundColor3    = Theme.AccentColor,
    BackgroundTransparency = 0.15,
    Text                = "⚡",
    TextColor3          = Color3.fromRGB(255, 255, 255),
    TextTransparency    = 0,
    TextScaled          = true,
    Font                = Enum.Font.GothamBold,
    ClipsDescendants    = true,
    ZIndex              = 10,
})
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatButton })
local FloatStroke = Create("UIStroke", {
    Color           = Color3.fromRGB(255, 255, 255),
    Transparency    = 0.7,
    Thickness       = 1.5,
    Parent          = FloatButton,
})
-- Efecto de pulso en el botón flotante para indicar que está activo
local pulseTween
local function StartButtonPulse()
    if pulseTween then pulseTween:Cancel() end
    local function doPulse()
        pulseTween = Tween(FloatButton, { BackgroundTransparency = 0.4 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        pulseTween.Completed:Connect(function()
            pulseTween = Tween(FloatButton, { BackgroundTransparency = 0.1 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            pulseTween.Completed:Connect(doPulse)
        end)
    end
    doPulse()
end
StartButtonPulse()

-- ── VENTANA PRINCIPAL ────────────────────────────────────────
local MainFrame = Create("Frame", {
    Name                = "MainFrame",
    Parent              = ScreenGui,
    Size                = UDim2.new(0, 500, 0, 410),
    Position            = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint         = Vector2.new(0.5, 0.5),
    BackgroundColor3    = Theme.MainColor,
    BackgroundTransparency = Theme.GlassTransparency,
    ClipsDescendants    = true,
    Visible             = false,
    ZIndex              = 5,
})
Create("UICorner", { CornerRadius = UDim.new(0, 18), Parent = MainFrame })
Create("UIStroke", {
    Color        = Theme.BorderColor,
    Transparency = Theme.BorderTransparency,
    Thickness    = 1,
    Parent       = MainFrame,
})
ApplyShadow(MainFrame, 30, 0.5)

-- Línea decorativa de acento en la parte superior
local AccentLine = Create("Frame", {
    Name                = "AccentLine",
    Parent              = MainFrame,
    Size                = UDim2.new(0.6, 0, 0, 2),
    Position            = UDim2.new(0.2, 0, 0, 0),
    BackgroundColor3    = Theme.AccentColor,
    BorderSizePixel     = 0,
    ZIndex              = 6,
})
Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = AccentLine })
-- Animación de brillo en la línea de acento
spawn(function()
    while MainFrame.Parent do
        Tween(AccentLine, { BackgroundColor3 = Theme.AccentSecondary }, 1.5, Enum.EasingStyle.Sine)
        wait(1.6)
        Tween(AccentLine, { BackgroundColor3 = Theme.AccentColor }, 1.5, Enum.EasingStyle.Sine)
        wait(1.6)
    end
end)

-- ── BARRA SUPERIOR / TOPBAR ──────────────────────────────────
local TopBar = Create("Frame", {
    Name                = "TopBar",
    Parent              = MainFrame,
    Size                = UDim2.new(1, 0, 0, 44),
    BackgroundTransparency = 1,
    ZIndex              = 6,
})

-- Título con efecto gradiente simulado en dos labels
Create("TextLabel", {
    Name                = "TitleShadow",
    Parent              = TopBar,
    Size                = UDim2.new(1, -20, 1, 0),
    Position            = UDim2.new(0, 22, 0, 1),
    BackgroundTransparency = 1,
    Text                = "LXNDXN",
    TextColor3          = Theme.AccentColor,
    TextTransparency    = 0.6,
    Font                = Enum.Font.GothamBlack,
    TextSize            = 20,
    TextXAlignment      = Enum.TextXAlignment.Left,
    ZIndex              = 6,
})
Create("TextLabel", {
    Name                = "Title",
    Parent              = TopBar,
    Size                = UDim2.new(1, -20, 1, 0),
    Position            = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text                = "LXNDXN",
    TextColor3          = Theme.TextColor,
    Font                = Enum.Font.GothamBlack,
    TextSize            = 20,
    TextXAlignment      = Enum.TextXAlignment.Left,
    ZIndex              = 7,
})
-- Versión
Create("TextLabel", {
    Name                = "Version",
    Parent              = TopBar,
    Size                = UDim2.new(0, 60, 0, 16),
    Position            = UDim2.new(0, 85, 0, 14),
    BackgroundTransparency = 1,
    Text                = "v3.0",
    TextColor3          = Theme.SecondaryText,
    Font                = Enum.Font.GothamSemibold,
    TextSize            = 11,
    TextXAlignment      = Enum.TextXAlignment.Left,
    ZIndex              = 7,
})

-- ── BARRA DE TABS ─────────────────────────────────────────────
local TabBar = Create("ScrollingFrame", {
    Name                = "TabBar",
    Parent              = MainFrame,
    Size                = UDim2.new(1, -40, 0, 36),
    Position            = UDim2.new(0, 20, 0, 50),
    BackgroundTransparency = 1,
    ScrollBarThickness  = 0,
    CanvasSize          = UDim2.new(1.5, 0, 0, 0),
    ScrollingDirection  = Enum.ScrollingDirection.X,
    ZIndex              = 6,
})
Create("UIListLayout", {
    Parent          = TabBar,
    FillDirection   = Enum.FillDirection.Horizontal,
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Padding         = UDim.new(0, 12),
})

-- ── CONTENEDOR DE CONTENIDO ───────────────────────────────────
local ContentContainer = Create("Frame", {
    Name                = "ContentContainer",
    Parent              = MainFrame,
    Size                = UDim2.new(1, -40, 1, -104),
    Position            = UDim2.new(0, 20, 0, 96),
    BackgroundTransparency = 1,
    ClipsDescendants    = true,
    ZIndex              = 5,
})

-- ┌─────────────────────────────────────────────────────────┐
-- │             SISTEMA DE DRAG / ARRASTRE                  │
-- └─────────────────────────────────────────────────────────┘
local ButtonIsFixed = false

local function MakeDraggable(guiObject, dragHandle)
    dragHandle = dragHandle or guiObject
    local dragging, dragInput, dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        -- Si es el botón flotante y está fijado, no permite moverlo
        if guiObject == FloatButton and ButtonIsFixed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MakeDraggable(FloatButton)
MakeDraggable(MainFrame, TopBar)

-- ┌─────────────────────────────────────────────────────────┐
-- │          LÓGICA DE APERTURA/CIERRE DEL MENÚ             │
-- └─────────────────────────────────────────────────────────┘
local menuOpen = false

local function ToggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        -- Animación de entrada: escala desde 0
        MainFrame.Visible             = true
        MainFrame.Size                = UDim2.new(0, 500, 0, 0)
        MainFrame.BackgroundTransparency = 1
        Tween(MainFrame, {
            Size                     = UDim2.new(0, 500, 0, 410),
            BackgroundTransparency   = Theme.GlassTransparency,
        }, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        -- Animación de salida
        local closeTween = Tween(MainFrame, {
            Size                     = UDim2.new(0, 500, 0, 0),
            BackgroundTransparency   = 1,
        }, 0.3)
        closeTween.Completed:Connect(function()
            MainFrame.Visible = false
        end)
    end
end

FloatButton.MouseButton1Click:Connect(ToggleMenu)

-- Tecla INSERT para abrir/cerrar (alternativa de teclado)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Insert then
        ToggleMenu()
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │         CREADORES DE COMPONENTES UI AVANZADOS           │
-- └─────────────────────────────────────────────────────────┘

-- Tabla de botones de tab y sus frames
local Tabs      = {}
local TabFrames = {}
local ActiveTab = nil

-- Crea un tab con su botón y su ScrollingFrame
local function CreateTab(key, layoutOrder)
    -- Botón del tab
    local TabBtn = Create("TextButton", {
        Name                = key,
        Parent              = TabBar,
        Size                = UDim2.new(0, 95, 1, 0),
        BackgroundTransparency = 1,
        TextColor3          = Theme.SecondaryText,
        Font                = Enum.Font.GothamSemibold,
        TextSize            = 13,
        LayoutOrder         = layoutOrder or 0,
        ZIndex              = 7,
    })
    RegisterTranslation(TabBtn, "Text", key)

    -- Indicador subrayado del tab activo
    local TabIndicator = Create("Frame", {
        Name                = "Indicator",
        Parent              = TabBtn,
        Size                = UDim2.new(0, 0, 0, 2),
        Position            = UDim2.new(0.5, 0, 1, -2),
        AnchorPoint         = Vector2.new(0.5, 0),
        BackgroundColor3    = Theme.AccentColor,
        BorderSizePixel     = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TabIndicator })

    -- Frame de contenido para este tab
    local TabFrame = Create("ScrollingFrame", {
        Name                = key .. "_Frame",
        Parent              = ContentContainer,
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness  = 2,
        ScrollBarImageColor3 = Theme.AccentColor,
        Visible             = false,
        ZIndex              = 5,
    })
    local layout = Create("UIListLayout", {
        Parent      = TabFrame,
        SortOrder   = Enum.SortOrder.LayoutOrder,
        Padding     = UDim.new(0, 8),
    })
    -- Padding extra arriba
    Create("UIPadding", {
        Parent          = TabFrame,
        PaddingTop      = UDim.new(0, 4),
        PaddingBottom   = UDim.new(0, 8),
    })

    Tabs[key]      = { Button = TabBtn, Indicator = TabIndicator }
    TabFrames[key] = TabFrame

    -- Cuando el layout cambia de tamaño → actualizar canvas
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UpdateCanvasSize(TabFrame)
    end)

    -- Lógica de clic en el tab
    TabBtn.MouseButton1Click:Connect(function()
        if ActiveTab == key then return end
        -- Oculta todos los frames y resetea indicadores
        for k, data in pairs(Tabs) do
            TabFrames[k].Visible = false
            Tween(data.Button,    { TextColor3 = Theme.SecondaryText }, 0.2)
            Tween(data.Indicator, { Size = UDim2.new(0, 0, 0, 2) }, 0.2)
        end
        -- Activa el nuevo tab con animación
        ActiveTab              = key
        TabFrame.Visible       = true
        Tween(TabBtn,      { TextColor3 = Theme.AccentColor }, 0.2)
        Tween(TabIndicator, { Size = UDim2.new(0.8, 0, 0, 2) }, 0.3, Enum.EasingStyle.Back)
    end)

    return TabFrame
end

-- ──────────────────────────────────────────────────────────
-- COMPONENTE: TOGGLE (Switch avanzado con animación líquida)
-- ──────────────────────────────────────────────────────────
local function CreateToggle(parent, key, callback, layoutOrder)
    local ToggleFrame = Create("Frame", {
        Parent              = parent,
        Size                = UDim2.new(1, 0, 0, 44),
        BackgroundColor3    = Theme.CardColor,
        BackgroundTransparency = Theme.CardTransparency,
        LayoutOrder         = layoutOrder or 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ToggleFrame })

    -- Ícono de estado (punto de color)
    local StatusDot = Create("Frame", {
        Parent           = ToggleFrame,
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(0, 10, 0.5, -3),
        BackgroundColor3 = Theme.SecondaryText,
        BorderSizePixel  = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = StatusDot })

    local Label = Create("TextLabel", {
        Parent              = ToggleFrame,
        Size                = UDim2.new(1, -80, 1, 0),
        Position            = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        TextColor3          = Theme.TextColor,
        Font                = Enum.Font.GothamMedium,
        TextSize            = 13,
        TextXAlignment      = Enum.TextXAlignment.Left,
    })
    RegisterTranslation(Label, "Text", key)

    -- Switch exterior (fondo)
    local SwitchBG = Create("Frame", {
        Parent           = ToggleFrame,
        Size             = UDim2.new(0, 44, 0, 22),
        Position         = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(45, 45, 52),
        BorderSizePixel  = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBG })

    -- Knob del switch
    local Knob = Create("Frame", {
        Parent           = SwitchBG,
        Size             = UDim2.new(0, 18, 0, 18),
        Position         = UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(210, 210, 220),
        BorderSizePixel  = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })

    -- Área de clic transparente (más grande para mejor UX en móvil)
    local ClickArea = Create("TextButton", {
        Parent              = ToggleFrame,
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                = "",
        ZIndex              = ToggleFrame.ZIndex + 1,
    })

    local toggled = false

    local function SetToggle(state, skipCallback)
        toggled = state
        -- Animación del knob
        Tween(Knob, {
            Position = state
                and UDim2.new(1, -20, 0.5, -9)
                or  UDim2.new(0, 2, 0.5, -9),
        }, 0.25, Enum.EasingStyle.Back)
        -- Animación del fondo del switch
        Tween(SwitchBG, {
            BackgroundColor3 = state and Theme.AccentColor or Color3.fromRGB(45, 45, 52),
        }, 0.25)
        -- Actualiza el punto de estado
        Tween(StatusDot, {
            BackgroundColor3 = state and Theme.AccentSecondary or Theme.SecondaryText,
        }, 0.2)
        -- Escala breve del knob para efecto "pop"
        Tween(Knob, { Size = UDim2.new(0, 20, 0, 20) }, 0.1)
        delay(0.12, function()
            Tween(Knob, { Size = UDim2.new(0, 18, 0, 18) }, 0.15)
        end)

        if not skipCallback and callback then
            callback(state)
        end
    end

    ClickArea.MouseButton1Click:Connect(function()
        SetToggle(not toggled)
    end)

    -- Exposición pública del toggle para control externo
    return ToggleFrame, SetToggle
end

-- ──────────────────────────────────────────────────────────
-- COMPONENTE: SLIDER (con valor numérico editable)
-- ──────────────────────────────────────────────────────────
local function CreateSlider(parent, key, minVal, maxVal, defaultVal, callback, layoutOrder)
    local SliderFrame = Create("Frame", {
        Parent              = parent,
        Size                = UDim2.new(1, 0, 0, 64),
        BackgroundColor3    = Theme.CardColor,
        BackgroundTransparency = Theme.CardTransparency,
        LayoutOrder         = layoutOrder or 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = SliderFrame })

    local Label = Create("TextLabel", {
        Parent              = SliderFrame,
        Size                = UDim2.new(1, -80, 0, 22),
        Position            = UDim2.new(0, 15, 0, 6),
        BackgroundTransparency = 1,
        TextColor3          = Theme.TextColor,
        Font                = Enum.Font.GothamMedium,
        TextSize            = 13,
        TextXAlignment      = Enum.TextXAlignment.Left,
    })
    RegisterTranslation(Label, "Text", key)

    local ValueLabel = Create("TextLabel", {
        Parent              = SliderFrame,
        Size                = UDim2.new(0, 55, 0, 22),
        Position            = UDim2.new(1, -68, 0, 6),
        BackgroundTransparency = 1,
        Text                = tostring(defaultVal),
        TextColor3          = Theme.AccentColor,
        Font                = Enum.Font.GothamBold,
        TextSize            = 13,
        TextXAlignment      = Enum.TextXAlignment.Right,
    })

    -- Track del slider
    local Track = Create("Frame", {
        Parent              = SliderFrame,
        Size                = UDim2.new(1, -30, 0, 6),
        Position            = UDim2.new(0, 15, 0, 38),
        BackgroundColor3    = Color3.fromRGB(45, 45, 52),
        BorderSizePixel     = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

    -- Fill del slider
    local Fill = Create("Frame", {
        Parent              = Track,
        Size                = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0),
        BackgroundColor3    = Theme.AccentColor,
        BorderSizePixel     = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

    -- Gradiente en el fill
    Create("UIGradient", {
        Parent      = Fill,
        Color       = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentColor),
            ColorSequenceKeypoint.new(1, Theme.AccentSecondary),
        }),
        Rotation    = 0,
    })

    -- Knob del slider
    local SliderKnob = Create("Frame", {
        Parent              = Fill,
        Size                = UDim2.new(0, 16, 0, 16),
        Position            = UDim2.new(1, -8, 0.5, -8),
        BackgroundColor3    = Color3.fromRGB(255, 255, 255),
        BorderSizePixel     = 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderKnob })
    Create("UIStroke", {
        Color        = Theme.AccentColor,
        Transparency = 0.3,
        Thickness    = 2,
        Parent       = SliderKnob,
    })

    local currentValue = defaultVal
    local isDragging   = false

    local function UpdateSlider(inputX)
        local relativeX = math.clamp(
            (inputX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1
        )
        currentValue         = Round(minVal + (maxVal - minVal) * relativeX)
        Fill.Size            = UDim2.new(relativeX, 0, 1, 0)
        ValueLabel.Text      = tostring(currentValue)
        if callback then callback(currentValue) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateSlider(input.Position.X)
            -- Efecto de "press" en el knob
            Tween(SliderKnob, { Size = UDim2.new(0, 18, 0, 18) }, 0.1)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if isDragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            UpdateSlider(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if isDragging then
                isDragging = false
                Tween(SliderKnob, { Size = UDim2.new(0, 16, 0, 16) }, 0.1)
            end
        end
    end)

    return SliderFrame, function() return currentValue end
end

-- ──────────────────────────────────────────────────────────
-- COMPONENTE: DROPDOWN CON LOCALIZACIÓN
-- ──────────────────────────────────────────────────────────
local function CreateDropdown(parent, titleKey, optionKeys, defaultKey, callback, layoutOrder)
    local optCount       = #optionKeys
    local optionHeight   = 30
    local closedHeight   = 44
    local openHeight     = closedHeight + optCount * optionHeight

    local DropFrame = Create("Frame", {
        Parent              = parent,
        Size                = UDim2.new(1, 0, 0, closedHeight),
        BackgroundColor3    = Theme.CardColor,
        BackgroundTransparency = Theme.CardTransparency,
        ClipsDescendants    = true,
        LayoutOrder         = layoutOrder or 0,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = DropFrame })

    local TitleLabel = Create("TextLabel", {
        Parent              = DropFrame,
        Size                = UDim2.new(1, -60, 0, closedHeight),
        Position            = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        TextColor3          = Theme.TextColor,
        Font                = Enum.Font.GothamMedium,
        TextSize            = 13,
        TextXAlignment      = Enum.TextXAlignment.Left,
    })
    local extraData = { CurrentSelectionKey = defaultKey }
    RegisterTranslation(TitleLabel, "DropdownTitle", titleKey, extraData)

    local Arrow = Create("TextLabel", {
        Parent              = DropFrame,
        Size                = UDim2.new(0, 24, 0, 24),
        Position            = UDim2.new(1, -34, 0, 10),
        BackgroundTransparency = 1,
        Text                = "▾",
        TextColor3          = Theme.SecondaryText,
        Font                = Enum.Font.GothamBold,
        TextSize            = 16,
    })

    local OptionContainer = Create("Frame", {
        Parent              = DropFrame,
        Size                = UDim2.new(1, 0, 1, -closedHeight),
        Position            = UDim2.new(0, 0, 0, closedHeight),
        BackgroundTransparency = 1,
    })
    Create("UIListLayout", { Parent = OptionContainer, SortOrder = Enum.SortOrder.LayoutOrder })

    local isOpen = false

    local ToggleBtn = Create("TextButton", {
        Parent              = DropFrame,
        Size                = UDim2.new(1, 0, 0, closedHeight),
        BackgroundTransparency = 1,
        Text                = "",
        ZIndex              = DropFrame.ZIndex + 2,
    })

    ToggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Tween(DropFrame, {
            Size = UDim2.new(1, 0, 0, isOpen and openHeight or closedHeight),
        }, 0.25, Enum.EasingStyle.Quart)
        Tween(Arrow, { Rotation = isOpen and 180 or 0 }, 0.25)
    end)

    for i, optKey in ipairs(optionKeys) do
        local OptBtn = Create("TextButton", {
            Parent              = OptionContainer,
            Size                = UDim2.new(1, 0, 0, optionHeight),
            BackgroundColor3    = Theme.DropdownColor,
            BackgroundTransparency = 0.3,
            TextColor3          = Theme.SecondaryText,
            Font                = Enum.Font.Gotham,
            TextSize            = 12,
            TextXAlignment      = Enum.TextXAlignment.Left,
            LayoutOrder         = i,
            ZIndex              = DropFrame.ZIndex + 3,
        })
        RegisterTranslation(OptBtn, "DropdownOption", optKey)

        OptBtn.MouseButton1Click:Connect(function()
            extraData.CurrentSelectionKey  = optKey
            TitleLabel.Text = (Lang[CurrentLanguage][titleKey] or titleKey)
                           .. ": "
                           .. (Lang[CurrentLanguage][optKey] or optKey)
            isOpen = false
            Tween(DropFrame, { Size = UDim2.new(1, 0, 0, closedHeight) }, 0.2)
            Tween(Arrow, { Rotation = 0 }, 0.2)
            if callback then callback(optKey) end
        end)

        -- Hover effect
        OptBtn.MouseEnter:Connect(function()
            Tween(OptBtn, { BackgroundTransparency = 0.0 }, 0.15)
        end)
        OptBtn.MouseLeave:Connect(function()
            Tween(OptBtn, { BackgroundTransparency = 0.3 }, 0.15)
        end)
    end

    return DropFrame
end

-- ──────────────────────────────────────────────────────────
-- COMPONENTE: SEPARADOR / LABEL DE SECCIÓN
-- ──────────────────────────────────────────────────────────
local function CreateSectionLabel(parent, text, layoutOrder)
    local F = Create("Frame", {
        Parent              = parent,
        Size                = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder         = layoutOrder or 0,
    })
    Create("TextLabel", {
        Parent              = F,
        Size                = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                = "— " .. text .. " —",
        TextColor3          = Theme.AccentColor,
        Font                = Enum.Font.GothamBold,
        TextSize            = 11,
        TextXAlignment      = Enum.TextXAlignment.Center,
    })
    return F
end

-- ┌─────────────────────────────────────────────────────────┐
-- │              CONSTRUCCIÓN DE TABS                       │
-- └─────────────────────────────────────────────────────────┘

local VisualsTab  = CreateTab("TAB_VISUALS",  1)
local CombatTab   = CreateTab("TAB_COMBAT",   2)
local MisticTab   = CreateTab("TAB_MISTIC",   3)
local MovementTab = CreateTab("TAB_MOVEMENT", 4)
local SettingsTab = CreateTab("TAB_SETTINGS", 5)

-- Activa el primer tab por defecto
ActiveTab                          = "TAB_VISUALS"
TabFrames["TAB_VISUALS"].Visible   = true
Tabs["TAB_VISUALS"].Button.TextColor3    = Theme.AccentColor
Tabs["TAB_VISUALS"].Indicator.Size = UDim2.new(0.8, 0, 0, 2)

-- ================================================================
-- ██╗   ██╗██╗███████╗██╗   ██╗ █████╗ ██╗     ███████╗███████╗
-- ██║   ██║██║██╔════╝██║   ██║██╔══██╗██║     ██╔════╝██╔════╝
-- ██║   ██║██║███████╗██║   ██║███████║██║     █████╗  ███████╗
-- ╚██╗ ██╔╝██║╚════██║██║   ██║██╔══██║██║     ██╔══╝  ╚════██║
--  ╚████╔╝ ██║███████║╚██████╔╝██║  ██║███████╗███████╗███████║
--   ╚═══╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
-- ================================================================
-- Aquí están las implementaciones REALES de cada feature.
-- Las marcadas con [EJEMPLO] son lógicas de demostración
-- porque dependen de mecánicas específicas del juego.

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO ESP: Sistema completo de Extra Sensory        │
-- └─────────────────────────────────────────────────────────┘

local ESP = {
    -- Estado de cada feature
    BoxEnabled      = false,
    TracersEnabled  = false,
    NamesEnabled    = false,
    HealthEnabled   = false,
    -- Almacenamiento de instancias creadas
    Highlights      = {},  -- [player] = Highlight
    TracerLines     = {},  -- [player] = Drawing Line
    NameBillboards  = {},  -- [player] = BillboardGui
    HealthBillboards= {},  -- [player] = BillboardGui
    -- Conexiones de eventos
    Connections     = {},
    HealthConnections= {},
}

-- Limpia todas las instancias ESP de un jugador al salir
local function ESP_CleanPlayer(player)
    if ESP.Highlights[player] then
        pcall(function() ESP.Highlights[player]:Destroy() end)
        ESP.Highlights[player] = nil
    end
    if ESP.TracerLines[player] then
        pcall(function() ESP.TracerLines[player]:Remove() end)
        ESP.TracerLines[player] = nil
    end
    if ESP.NameBillboards[player] then
        pcall(function() ESP.NameBillboards[player]:Destroy() end)
        ESP.NameBillboards[player] = nil
    end
    if ESP.HealthBillboards[player] then
        pcall(function() ESP.HealthBillboards[player]:Destroy() end)
        ESP.HealthBillboards[player] = nil
    end
    if ESP.HealthConnections[player] then
        for _, conn in pairs(ESP.HealthConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
        ESP.HealthConnections[player] = nil
    end
end

-- ── ESP BOX (Highlight) ───────────────────────────────────
-- Usa el objeto Highlight nativo de Roblox para crear
-- contornos y rellenos coloreados alrededor de los personajes.

local function ESP_Box_ApplyToCharacter(player, char)
    -- Evita duplicados
    if ESP.Highlights[player] then
        pcall(function() ESP.Highlights[player]:Destroy() end)
    end
    local hl                    = Instance.new("Highlight")
    hl.FillColor                = Color3.fromRGB(255, 50, 50)   -- rojo translúcido
    hl.OutlineColor             = Color3.fromRGB(255, 255, 255) -- contorno blanco
    hl.FillTransparency         = 0.65
    hl.OutlineTransparency      = 0.05
    hl.DepthMode                = Enum.HighlightDepthMode.AlwaysOnTop  -- visible a través de paredes
    hl.Adornee                  = char
    hl.Parent                   = char
    ESP.Highlights[player]      = hl
end

function ESP.StartBoxes()
    ESP.BoxEnabled = true
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            ESP_Box_ApplyToCharacter(player, player.Character)
        end
    end
    -- Escuchar nuevos personajes de jugadores existentes
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local conn = player.CharacterAdded:Connect(function(char)
                if ESP.BoxEnabled then
                    ESP_Box_ApplyToCharacter(player, char)
                end
            end)
            ESP.Connections["box_char_" .. player.UserId] = conn
        end
    end
    -- Escuchar nuevos jugadores que entren
    ESP.Connections["box_playeradded"] = Players.PlayerAdded:Connect(function(player)
        ESP.Connections["box_char_" .. player.UserId] = player.CharacterAdded:Connect(function(char)
            if ESP.BoxEnabled then ESP_Box_ApplyToCharacter(player, char) end
        end)
    end)
    -- Limpiar al salir
    ESP.Connections["box_playerremoving"] = Players.PlayerRemoving:Connect(function(player)
        ESP_CleanPlayer(player)
    end)
end

function ESP.StopBoxes()
    ESP.BoxEnabled = false
    for player, hl in pairs(ESP.Highlights) do
        pcall(function() hl:Destroy() end)
        ESP.Highlights[player] = nil
    end
    -- Desconecta eventos relacionados con Boxes
    for key, conn in pairs(ESP.Connections) do
        if key:find("box_") then
            pcall(function() conn:Disconnect() end)
            ESP.Connections[key] = nil
        end
    end
end

-- ── ESP TRACERS (Drawing API) ─────────────────────────────
-- Dibuja líneas desde el centro inferior de la pantalla
-- hasta la posición en pantalla de cada jugador enemigo.
-- Usa la Drawing API del ejecutor.

local TracerRenderConnection = nil

function ESP.StartTracers()
    ESP.TracersEnabled = true
    -- Limpia tracers anteriores
    for _, line in pairs(ESP.TracerLines) do
        pcall(function() line:Remove() end)
    end
    ESP.TracerLines = {}

    -- Crea una línea de tracer para cada jugador
    local function MakeTracer(player)
        if player == LocalPlayer then return end
        local line          = Drawing.new("Line")
        line.Color          = Color3.fromRGB(255, 230, 0)  -- amarillo
        line.Thickness      = 1.5
        line.Transparency   = 0.85
        line.Visible        = true
        ESP.TracerLines[player] = line
    end

    for _, p in ipairs(Players:GetPlayers()) do MakeTracer(p) end

    ESP.Connections["tracer_playeradded"] = Players.PlayerAdded:Connect(function(p)
        MakeTracer(p)
    end)

    -- RenderStepped: actualiza posición de cada tracer cada frame
    TracerRenderConnection = RunService.RenderStepped:Connect(function()
        if not ESP.TracersEnabled then return end
        local vpSize = Camera.ViewportSize
        local origin = Vector2.new(vpSize.X / 2, vpSize.Y) -- centro inferior

        for _, player in ipairs(Players:GetPlayers()) do
            local line = ESP.TracerLines[player]
            if not line then continue end

            if player == LocalPlayer or not player.Character then
                line.Visible = false
                continue
            end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then line.Visible = false; continue end

            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then line.Visible = false; continue end

            local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                line.From    = origin
                line.To      = Vector2.new(screenPos.X, screenPos.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end)
end

function ESP.StopTracers()
    ESP.TracersEnabled = false
    if TracerRenderConnection then
        TracerRenderConnection:Disconnect()
        TracerRenderConnection = nil
    end
    for player, line in pairs(ESP.TracerLines) do
        pcall(function() line:Remove() end)
        ESP.TracerLines[player] = nil
    end
    if ESP.Connections["tracer_playeradded"] then
        pcall(function() ESP.Connections["tracer_playeradded"]:Disconnect() end)
        ESP.Connections["tracer_playeradded"] = nil
    end
end

-- ── ESP NOMBRES (BillboardGui) ────────────────────────────
-- Crea etiquetas de nombre flotantes sobre la cabeza de cada
-- jugador enemigo, visibles a través de paredes.

local function ESP_Name_Create(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end
    -- Evita duplicados
    if player.Character:FindFirstChild("LXNDXN_Name") then return end

    local bb            = Instance.new("BillboardGui")
    bb.Name             = "LXNDXN_Name"
    bb.Size             = UDim2.new(0, 200, 0, 40)
    bb.Adornee          = head
    bb.AlwaysOnTop      = true  -- visible a través de paredes
    bb.StudsOffset      = Vector3.new(0, 2.8, 0)
    bb.MaxDistance      = 300   -- máximo 300 studs de distancia

    -- Sombra del texto
    local shadow        = Instance.new("TextLabel", bb)
    shadow.Size         = UDim2.new(1, 0, 1, 0)
    shadow.Position     = UDim2.new(0, 1, 0, 1)
    shadow.BackgroundTransparency = 1
    shadow.TextColor3   = Color3.new(0, 0, 0)
    shadow.Text         = player.Name
    shadow.Font         = Enum.Font.GothamBold
    shadow.TextSize     = 16

    -- Texto principal
    local text          = Instance.new("TextLabel", bb)
    text.Size           = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextColor3     = Color3.fromRGB(255, 255, 255)
    text.TextStrokeTransparency = 0.5
    text.Text           = player.Name
    text.Font           = Enum.Font.GothamBold
    text.TextSize       = 16

    bb.Parent           = head
    ESP.NameBillboards[player] = bb
end

function ESP.StartNames()
    ESP.NamesEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do ESP_Name_Create(p) end
    ESP.Connections["names_playeradded"] = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5) -- espera a que el personaje cargue
            if ESP.NamesEnabled then ESP_Name_Create(p) end
        end)
    end)
end

function ESP.StopNames()
    ESP.NamesEnabled = false
    for p, bb in pairs(ESP.NameBillboards) do
        pcall(function() bb:Destroy() end)
        ESP.NameBillboards[p] = nil
    end
    if ESP.Connections["names_playeradded"] then
        pcall(function() ESP.Connections["names_playeradded"]:Disconnect() end)
        ESP.Connections["names_playeradded"] = nil
    end
end

-- ── ESP SALUD ─────────────────────────────────────────────
-- Muestra la vida actual y máxima sobre la cabeza, con
-- una barra de color que cambia según el porcentaje de vida.

local function ESP_Health_Create(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local head      = player.Character:FindFirstChild("Head")
    local humanoid  = player.Character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then return end

    if ESP.HealthBillboards[player] then
        pcall(function() ESP.HealthBillboards[player]:Destroy() end)
        ESP.HealthBillboards[player] = nil
    end
    if ESP.HealthConnections[player] then
        for _, conn in pairs(ESP.HealthConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
        ESP.HealthConnections[player] = nil
    end

    local bb            = Instance.new("BillboardGui")
    bb.Name             = "LXNDXN_Health"
    bb.Size             = UDim2.new(0, 100, 0, 16)
    bb.Adornee          = head
    bb.AlwaysOnTop      = true
    bb.StudsOffset      = Vector3.new(0, 4.2, 0)
    bb.MaxDistance      = 200

    -- Fondo oscuro de la barra
    local barBG         = Instance.new("Frame", bb)
    barBG.Size          = UDim2.new(1, 0, 0.6, 0)
    barBG.Position      = UDim2.new(0, 0, 0.2, 0)
    barBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barBG })

    -- Barra de salud (fill)
    local healthPct     = humanoid.Health / humanoid.MaxHealth
    local barFill       = Instance.new("Frame", barBG)
    barFill.Size        = UDim2.new(healthPct, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(
        math.floor(255 * (1 - healthPct)),
        math.floor(255 * healthPct),
        30
    )
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barFill })

    -- Texto de vida
    local healthText    = Instance.new("TextLabel", bb)
    healthText.Size     = UDim2.new(1, 0, 0.5, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.new(1, 1, 1)
    healthText.Text     = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
    healthText.Font     = Enum.Font.GothamBold
    healthText.TextScaled = true

    bb.Parent           = head
    ESP.HealthBillboards[player] = bb
    ESP.HealthConnections[player] = {}

    ESP.HealthConnections[player].HumanoidHealth = humanoid.HealthChanged:Connect(function(hp)
        if not ESP.HealthEnabled then return end
        local pct       = hp / humanoid.MaxHealth
        barFill.Size    = UDim2.new(pct, 0, 1, 0)
        barFill.BackgroundColor3 = Color3.fromRGB(
            math.floor(255 * (1 - pct)),
            math.floor(255 * pct),
            30
        )
        healthText.Text = math.floor(hp) .. "/" .. math.floor(humanoid.MaxHealth)
    end)

    ESP.HealthConnections[player].CharacterRemoving = player.CharacterRemoving:Connect(function()
        ESP_CleanPlayer(player)
    end)
end

function ESP.StartHealth()
    ESP.HealthEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        ESP_Health_Create(p)
        ESP.Connections["health_charadded_" .. p.UserId] = p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.HealthEnabled then
                ESP_Health_Create(p)
            end
        end)
    end
    ESP.Connections["health_playeradded"] = Players.PlayerAdded:Connect(function(p)
        ESP.Connections["health_charadded_" .. p.UserId] = p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.HealthEnabled then ESP_Health_Create(p) end
        end)
    end)
    ESP.Connections["health_playerremoving"] = Players.PlayerRemoving:Connect(function(p)
        ESP_CleanPlayer(p)
    end)
end

function ESP.StopHealth()
    ESP.HealthEnabled = false
    for p, bb in pairs(ESP.HealthBillboards) do
        pcall(function() bb:Destroy() end)
        ESP.HealthBillboards[p] = nil
    end
    for player, conns in pairs(ESP.HealthConnections) do
        for _, conn in pairs(conns) do
            pcall(function() conn:Disconnect() end)
        end
        ESP.HealthConnections[player] = nil
    end
    for key, conn in pairs(ESP.Connections) do
        if key:find("health_") then
            pcall(function() conn:Disconnect() end)
            ESP.Connections[key] = nil
        end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         MÓDULO FOV: Círculo de Radio de Apuntado        │
-- └─────────────────────────────────────────────────────────┘
-- Dibuja un círculo en el centro de la pantalla que indica
-- el radio máximo donde el Silent Aim buscará objetivos.

local FOVCircle = nil
local FOVRenderConn = nil

local function StartFOVCircle()
    if FOVCircle then FOVCircle:Remove() end
    FOVCircle               = Drawing.new("Circle")
    FOVCircle.Color         = Color3.fromRGB(255, 255, 255)
    FOVCircle.Thickness     = 1.2
    FOVCircle.Transparency  = 0.85
    FOVCircle.Filled        = false
    FOVCircle.NumSides      = 64
    FOVCircle.Visible       = true

    -- Actualiza posición al centro cada frame (en caso de resize)
    FOVRenderConn = RunService.RenderStepped:Connect(function()
        if not Config.SHOW_FOV then return end
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius   = Config.FOV_RADIUS
    end)
end

local function StopFOVCircle()
    if FOVRenderConn then FOVRenderConn:Disconnect() FOVRenderConn = nil end
    if FOVCircle then FOVCircle:Remove() FOVCircle = nil end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO SILENT AIM: Interceptación y redirección     │
-- └─────────────────────────────────────────────────────────┘
-- Esta implementación está diseñada para ser un Silent Aim real:
-- 1) Calcula el objetivo más cercano al cursor dentro de FOV.
-- 2) Selecciona la parte indicada (cabeza, pecho o general).
-- 3) Intercepta FireServer/InvokeServer y Raycast si el exploit lo permite.
-- 4) Redirige el payload a la posición/pieza objetivo.
-- 5) Respeta Hit Chance y utiliza predicción según distancia.

local SilentAim = {}
SilentAim.Active = false
SilentAim.Hooked = false
SilentAim.OldNamecall = nil

local function shouldHit()
    if not Config.HIT_CHANCE_ON then
        return true
    end
    local chance = math.clamp((Config.HIT_CHANCE_VAL or 100) / 100, 0, 1)
    return math.random() <= chance
end

local function getCursorPosition()
    return UserInputService:GetMouseLocation()
end

local function predictPosition(part)
    if not part then return nil end
    local pos = part.Position
    if not Config.PREDICTION then
        return pos
    end
    local vel = part.AssemblyLinearVelocity or Vector3.new()
    local distance = (pos - Camera.CFrame.Position).Magnitude
    local factor = math.clamp(0.12 + distance / 900, 0.08, 0.22)
    return pos + vel * factor
end

local function isAttackRemote(remote)
    if not remote or not remote.Name then
        return false
    end
    local name = tostring(remote.Name):lower()
    return name:find("attack")
        or name:find("fire")
        or name:find("shoot")
        or name:find("hit")
        or name:find("weapon")
        or name:find("bullet")
        or name:find("damage")
        or name:find("gun")
end

local function patchTableFields(tbl, targetPart, targetPos)
    local ok = false
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            if patchTableFields(value, targetPart, targetPos) then
                ok = true
            end
        elseif typeof(value) == "Instance" and value:IsA("BasePart") then
            tbl[key] = targetPart
            ok = true
        elseif typeof(value) == "Vector3" then
            local name = tostring(key):lower()
            if name:find("pos") or name:find("aim") or name:find("target") or name:find("mouse") then
                tbl[key] = targetPos
                ok = true
            end
        elseif typeof(value) == "CFrame" then
            local name = tostring(key):lower()
            if name:find("cframe") or name:find("aim") or name:find("target") then
                tbl[key] = CFrame.new(value.Position, targetPos)
                ok = true
            end
        elseif type(key) == "string" then
            local lowerKey = key:lower()
            if lowerKey == "target" or lowerKey == "part" or lowerKey == "hitpart" or lowerKey == "victim" then
                tbl[key] = targetPart
                ok = true
            elseif lowerKey == "position" or lowerKey == "pos" or lowerKey == "mouse" or lowerKey == "hitposition" or lowerKey == "hitpos" then
                tbl[key] = targetPos
                ok = true
            end
        end
    end
    return ok
end

local function redirectArguments(args, targetPart, targetPos)
    local newArgs = {}
    for index, arg in ipairs(args) do
        if typeof(arg) == "Instance" and arg:IsA("BasePart") then
            newArgs[index] = targetPart
        elseif typeof(arg) == "Vector3" then
            newArgs[index] = targetPos
        elseif typeof(arg) == "CFrame" then
            newArgs[index] = CFrame.new(arg.Position, targetPos)
        elseif type(arg) == "table" then
            local clone = {}
            for k,v in pairs(arg) do clone[k] = v end
            patchTableFields(clone, targetPart, targetPos)
            newArgs[index] = clone
        else
            newArgs[index] = arg
        end
    end
    return unpack(newArgs)
end

local function argsContainShootData(args)
    for _, arg in ipairs(args) do
        if typeof(arg) == "Instance" and arg:IsA("BasePart") then
            return true
        end
        if typeof(arg) == "Vector3" or typeof(arg) == "CFrame" then
            return true
        end
        if type(arg) == "table" then
            for k, v in pairs(arg) do
                local keyName = tostring(k):lower()
                if keyName:find("target") or keyName:find("position") or keyName:find("mouse") or keyName:find("hit") then
                    return true
                end
                if typeof(v) == "Instance" and v:IsA("BasePart") then
                    return true
                end
            end
        end
    end
    return false
end

local function decodeRaycastArguments(args)
    local origin = args[1]
    local direction = args[2]
    local params = args[3]
    if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
        return origin, direction, params
    end
    return nil
end

local function interceptNamecall(self, ...)
    local method = getnamecallmethod()
    local args = { ... }
    local targetPlayer, targetPart = GetBestSilentAimTarget(Config.FOV_RADIUS)
    if SilentAim.Active and targetPlayer and targetPart and shouldHit() then
        local targetPos = predictPosition(targetPart)
        if method == "FireServer" or method == "InvokeServer" then
            if self:IsA("RemoteEvent") or self:IsA("RemoteFunction") then
                if isAttackRemote(self) or argsContainShootData(args) then
                    return SilentAim.OldNamecall(self, redirectArguments(args, targetPart, targetPos))
                end
            end
        elseif self == workspace and method == "Raycast" then
            local origin, direction, params = decodeRaycastArguments(args)
            if origin and direction then
                return SilentAim.OldNamecall(self, origin, targetPos - origin, params)
            end
        end
    end
    return SilentAim.OldNamecall(self, unpack(args))
end

local function connectSilentAimHook()
    if SilentAim.Hooked then
        return
    end
    if hookmetamethod then
        SilentAim.OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            return interceptNamecall(self, ...)
        end)
    else
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        SilentAim.OldNamecall = mt.__namecall
        mt.__namecall = newcclosure(function(self, ...)
            return interceptNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end
    SilentAim.Hooked = true
end

local function disconnectSilentAimHook()
    if not SilentAim.Hooked then
        return
    end
    if hookmetamethod and SilentAim.OldNamecall then
        hookmetamethod(game, "__namecall", SilentAim.OldNamecall)
    else
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__namecall = SilentAim.OldNamecall
        setreadonly(mt, true)
    end
    SilentAim.Hooked = false
    SilentAim.OldNamecall = nil
end

function SilentAim.Enable()
    if SilentAim.Active then
        return
    end
    SilentAim.Active = true
    connectSilentAimHook()
    print("[LXNDXN] Silent Aim: Activado")
end

function SilentAim.Disable()
    SilentAim.Active = false
    disconnectSilentAimHook()
    print("[LXNDXN] Silent Aim: Desactivado")
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO TRIGGER BOT: Disparo Automático al Apuntar   │
-- │    [LÓGICA DE EJEMPLO]                                  │
-- └─────────────────────────────────────────────────────────┘
local TriggerBot = {}
TriggerBot.Active   = false
TriggerBot.Thread   = nil

function TriggerBot.Enable()
    TriggerBot.Active = true
    TriggerBot.Thread = task.spawn(function()
        while TriggerBot.Active do
            task.wait(0.05) -- revisa cada 50ms para no spammear

            -- Verificamos si el mouse está sobre un jugador enemigo
            -- [EJEMPLO] En un juego real harías un raycast desde la cámara
            local target, dist = GetClosestPlayerToMouse(15) -- 15px de tolerancia
            if target then
                -- Simulamos el click (en un juego real sería mouse:Click()
                -- o disparar la función del arma)
                -- [EJEMPLO CONCEPTUAL]:
                -- mouse:Button1Click()  -- NO existe en LocalScript directamente
                print("[TriggerBot] Objetivo detectado:", target.Name, "dist:", math.floor(dist))
            end
        end
    end)
end

function TriggerBot.Disable()
    TriggerBot.Active = false
    if TriggerBot.Thread then
        task.cancel(TriggerBot.Thread)
        TriggerBot.Thread = nil
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │         MÓDULO VUELO (FLY)                             │
-- └─────────────────────────────────────────────────────────┘
-- Implementación real de vuelo usando BodyVelocity y
-- BodyGyro en el personaje del jugador.

local FlyModule = {}
FlyModule.Active        = false
FlyModule.BodyVelocity  = nil
FlyModule.BodyGyro      = nil
FlyModule.RenderConn    = nil

function FlyModule.Enable()
    FlyModule.Active = true
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    -- Crea BodyVelocity para controlar la velocidad en 3D
    local bv             = Instance.new("BodyVelocity")
    bv.Velocity          = Vector3.new(0, 0, 0)
    bv.MaxForce          = Vector3.new(math.huge, math.huge, math.huge)
    bv.P                 = 9999
    bv.Parent            = hrp
    FlyModule.BodyVelocity = bv

    -- Crea BodyGyro para estabilizar la rotación
    local bg             = Instance.new("BodyGyro")
    bg.MaxTorque         = Vector3.new(math.huge, math.huge, math.huge)
    bg.P                 = 9999
    bg.D                 = 100
    bg.Parent            = hrp
    FlyModule.BodyGyro   = bg

    -- Pausa la animación de caída
    if humanoid then humanoid.PlatformStand = true end

    -- Loop de vuelo: lee input del teclado para mover al jugador
    FlyModule.RenderConn = RunService.RenderStepped:Connect(function()
        if not FlyModule.Active then return end
        local speed   = Config.FLY_SPEED
        local camCF   = Camera.CFrame
        local velocity = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            velocity = velocity + camCF.LookVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            velocity = velocity - camCF.LookVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            velocity = velocity - camCF.RightVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            velocity = velocity + camCF.RightVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            velocity = velocity + Vector3.new(0, speed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            velocity = velocity - Vector3.new(0, speed, 0)
        end

        bv.Velocity = velocity
        -- Apunta el personaje en la dirección de la cámara
        bg.CFrame   = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)
end

function FlyModule.Disable()
    FlyModule.Active = false
    if FlyModule.RenderConn then
        FlyModule.RenderConn:Disconnect()
        FlyModule.RenderConn = nil
    end
    if FlyModule.BodyVelocity then
        pcall(function() FlyModule.BodyVelocity:Destroy() end)
        FlyModule.BodyVelocity = nil
    end
    if FlyModule.BodyGyro then
        pcall(function() FlyModule.BodyGyro:Destroy() end)
        FlyModule.BodyGyro = nil
    end
    -- Restaura el personaje
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO ANTI-KATANA [LÓGICA DE EJEMPLO]               │
-- └─────────────────────────────────────────────────────────┘
-- En el juego destino, interceptaría los ataques de katana
-- detectando animaciones específicas del atacante.

local AntiKatana = {}
AntiKatana.Active   = false
AntiKatana.Thread   = nil

function AntiKatana.Enable()
    AntiKatana.Active = true
    AntiKatana.Thread = task.spawn(function()
        while AntiKatana.Active do
            task.wait(0.1)
            -- [EJEMPLO] Lógica conceptual:
            -- Detectar si algún jugador cercano está usando la animación
            -- de ataque de katana, y si es así, tomar acción evasiva.
            --[[
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local animator = player.Character:FindFirstChildOfClass("Animator")
                    if animator then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            if track.Animation.AnimationId == "KATANA_ATTACK_ID" then
                                -- Ejecutar evasión: dash, teleport, etc.
                                DoEvasiveAction()
                            end
                        end
                    end
                end
            end
            ]]
        end
    end)
end

function AntiKatana.Disable()
    AntiKatana.Active = false
    if AntiKatana.Thread then task.cancel(AntiKatana.Thread) AntiKatana.Thread = nil end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO RESOLVER [LÓGICA DE EJEMPLO]                  │
-- └─────────────────────────────────────────────────────────┘
-- El resolver intenta predecir hacia dónde se moverá un
-- jugador que usa técnicas anti-aim (girarse rápido, etc.)

local Resolver = {}
Resolver.Active         = false
Resolver.PreviousAngles = {}  -- historial de ángulos de cada jugador

function Resolver.Enable()
    Resolver.Active = true
    -- [EJEMPLO] Guarda el ángulo Y de cada jugador cada frame
    -- para calcular la tendencia y predecir el siguiente ángulo.
    task.spawn(function()
        while Resolver.Active do
            task.wait(0.05)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local angle = hrp.CFrame:ToEulerAnglesYXZ()
                        if not Resolver.PreviousAngles[player] then
                            Resolver.PreviousAngles[player] = {}
                        end
                        table.insert(Resolver.PreviousAngles[player], angle)
                        -- Mantiene solo los últimos 10 ángulos
                        if #Resolver.PreviousAngles[player] > 10 then
                            table.remove(Resolver.PreviousAngles[player], 1)
                        end
                    end
                end
            end
        end
    end)
end

function Resolver.Disable()
    Resolver.Active = false
    Resolver.PreviousAngles = {}
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO ANTI-LOCK [LÓGICA DE EJEMPLO]                 │
-- └─────────────────────────────────────────────────────────┘
-- Previene que otros jugadores usen lock-on contra ti,
-- aplicando movimiento errático o detectando el lock.

local AntiLock = {}
AntiLock.Active     = false
AntiLock.Thread     = nil
local antiLockJitter = 0

function AntiLock.Enable()
    AntiLock.Active = true
    AntiLock.Thread = task.spawn(function()
        while AntiLock.Active do
            task.wait(0.03)
            -- [EJEMPLO] Aplica pequeñas rotaciones aleatorias al personaje
            -- para dificultar el lock-on de sistemas enemy-aim.
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Micro-jitter: variación aleatoria muy pequeña en Y
                    antiLockJitter = antiLockJitter + math.random(-2, 2)
                    -- En un juego real aplicarías esto de forma más sofisticada
                    -- hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(antiLockJitter * 0.1), 0)
                end
            end
        end
    end)
end

function AntiLock.Disable()
    AntiLock.Active = false
    antiLockJitter  = 0
    if AntiLock.Thread then task.cancel(AntiLock.Thread) AntiLock.Thread = nil end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO PREDICCIÓN [LÓGICA DE EJEMPLO]                │
-- └─────────────────────────────────────────────────────────┘
-- Calcula la posición futura del objetivo sumando su
-- velocidad actual multiplicada por el ping/latencia.

local Prediction = {}
Prediction.Active           = false
Prediction.VelocityCache    = {}  -- [player] = Vector3 velocidad

function Prediction.Enable()
    Prediction.Active = true
    -- Trackea velocidad de cada jugador
    task.spawn(function()
        local lastPositions = {}
        while Prediction.Active do
            task.wait(0.05)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local currentPos = hrp.Position
                        if lastPositions[player] then
                            -- Velocidad ≈ (posición actual - posición anterior) / tiempo
                            local vel = (currentPos - lastPositions[player]) / 0.05
                            Prediction.VelocityCache[player] = vel
                        end
                        lastPositions[player] = currentPos
                    end
                end
            end
        end
    end)
end

-- Función auxiliar: calcula posición predicha para un jugador
function Prediction.GetPredictedPosition(player, pingSeconds)
    pingSeconds = pingSeconds or 0.1  -- default 100ms
    if not player.Character then return nil end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local vel = Prediction.VelocityCache[player] or Vector3.new(0, 0, 0)
    return hrp.Position + vel * pingSeconds
end

function Prediction.Disable()
    Prediction.Active = false
    Prediction.VelocityCache = {}
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO KATANA STATUS ESP [LÓGICA DE EJEMPLO]         │
-- └─────────────────────────────────────────────────────────┘
-- Detecta si un jugador tiene la katana equipada/activa
-- y lo muestra con un indicador visual.

local KatanaESP = {}
KatanaESP.Active        = false
KatanaESP.Billboards    = {}

local function KatanaESP_Create(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head")
    if not head then return end

    local bb        = Instance.new("BillboardGui")
    bb.Name         = "LXNDXN_KatanaStatus"
    bb.Size         = UDim2.new(0, 120, 0, 20)
    bb.Adornee      = head
    bb.AlwaysOnTop  = true
    bb.StudsOffset  = Vector3.new(0, 5.5, 0)
    bb.MaxDistance  = 150

    local label     = Instance.new("TextLabel", bb)
    label.Size      = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font      = Enum.Font.GothamBold
    label.TextSize  = 13
    label.TextColor3 = Color3.fromRGB(255, 80, 80)  -- rojo = peligro
    label.Text      = "⚔ KATANA"

    bb.Parent       = head
    KatanaESP.Billboards[player] = bb

    -- [EJEMPLO] Actualiza el estado según si el jugador tiene la katana
    task.spawn(function()
        while KatanaESP.Active and bb.Parent do
            task.wait(0.2)
            -- En un juego real verificarías el tool equipado:
            -- local tool = player.Character:FindFirstChildOfClass("Tool")
            -- local hasKatana = tool and tool.Name:find("Katana")
            local hasKatana = false  -- placeholder
            label.Text      = hasKatana and "⚔ KATANA" or "✓ SAFE"
            label.TextColor3 = hasKatana
                and Color3.fromRGB(255, 80, 80)
                or  Color3.fromRGB(80, 255, 80)
        end
    end)
end

function KatanaESP.Enable()
    KatanaESP.Active = true
    for _, p in ipairs(Players:GetPlayers()) do KatanaESP_Create(p) end
end

function KatanaESP.Disable()
    KatanaESP.Active = false
    for p, bb in pairs(KatanaESP.Billboards) do
        pcall(function() bb:Destroy() end)
        KatanaESP.Billboards[p] = nil
    end
end

-- ┌─────────────────────────────────────────────────────────┐
-- │    MÓDULO PERSISTENCIA DE CONFIGURACIÓN                 │
-- └─────────────────────────────────────────────────────────┘
-- Guarda y carga la configuración usando writefile/readfile
-- del ejecutor. Si no están disponibles, usa un fallback en
-- tabla local (se pierde al cerrar el juego).

local CONFIG_FILE = "LXNDXN_config.json"

local function SaveConfig()
    -- Serializa la tabla Config a JSON
    local success, jsonStr = pcall(function()
        return HttpService:JSONEncode(Config)
    end)
    if not success then
        warn("[LXNDXN] Error al serializar config:", jsonStr)
        return
    end
    -- Intenta escribir el archivo
    local ok2, err = pcall(function()
        writefile(CONFIG_FILE, jsonStr)
    end)
    if ok2 then
        print("[LXNDXN] Configuración guardada correctamente.")
    else
        warn("[LXNDXN] No se pudo guardar (ejecutor sin writefile):", err)
    end
end

local function LoadConfig()
    -- Intenta leer el archivo
    local ok, content = pcall(function()
        return readfile(CONFIG_FILE)
    end)
    if not ok or not content then
        warn("[LXNDXN] No se encontró archivo de configuración.")
        return nil
    end
    -- Deserializa
    local ok2, decoded = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not ok2 or type(decoded) ~= "table" then
        warn("[LXNDXN] Config corrupta o inválida.")
        return nil
    end
    -- Mezcla con los valores por defecto para no perder keys nuevas
    for k, v in pairs(decoded) do
        if Config[k] ~= nil then
            Config[k] = v
        end
    end
    print("[LXNDXN] Configuración cargada correctamente.")
    return decoded
end

-- ================================================================
-- TAB: VISUALES
-- ================================================================

CreateSectionLabel(VisualsTab, "ESP FEATURES", 1)

-- ESP Box
CreateToggle(VisualsTab, "ESP_BOX", function(state)
    Config.ESP_BOX = state
    if state then ESP.StartBoxes() else ESP.StopBoxes() end
end, 2)

-- Tracers
CreateToggle(VisualsTab, "TRACERS", function(state)
    Config.TRACERS = state
    if state then ESP.StartTracers() else ESP.StopTracers() end
end, 3)

-- Nombres
CreateToggle(VisualsTab, "ESP_NAMES", function(state)
    Config.ESP_NAMES = state
    if state then ESP.StartNames() else ESP.StopNames() end
end, 4)

-- Salud
CreateToggle(VisualsTab, "ESP_HEALTH", function(state)
    Config.ESP_HEALTH = state
    if state then ESP.StartHealth() else ESP.StopHealth() end
end, 5)

-- Katana Status ESP
CreateToggle(VisualsTab, "KATANA_STATUS", function(state)
    Config.KATANA_STATUS = state
    if state then KatanaESP.Enable() else KatanaESP.Disable() end
end, 6)

-- ================================================================
-- TAB: COMBATE
-- ================================================================

CreateSectionLabel(CombatTab, "AIM ASSISTANCE", 1)

-- Silent Aim (toggle + dropdown de parte del cuerpo)
local aimDropdown
local _, setAimToggle = CreateToggle(CombatTab, "SILENT_AIM", function(state)
    Config.SILENT_AIM = state
    aimDropdown.Visible = state
    if state then SilentAim.Enable() else SilentAim.Disable() end
end, 2)

aimDropdown = CreateDropdown(CombatTab, "DIR_TITLE",
    {"DIR_HEAD", "DIR_CHEST", "DIR_ALL"},
    "DIR_HEAD",
    function(selKey)
        Config.SILENT_AIM_DIR = selKey
    end, 3
)
aimDropdown.Visible = false

-- Hit Chance (probabilidad de no disparar para parecer menos obvio)
local hitChanceSlider
CreateToggle(CombatTab, "HIT_CHANCE_ON", function(state)
    Config.HIT_CHANCE_ON = state
    hitChanceSlider.Visible = state
end, 4)

hitChanceSlider, _ = CreateSlider(CombatTab, "HIT_CHANCE_VAL", 0, 100, 100, function(val)
    Config.HIT_CHANCE_VAL = val
end, 5)
hitChanceSlider.Visible = false

CreateSectionLabel(CombatTab, "FOV & TARGETING", 6)

-- FOV Circle
local fovSlider
CreateToggle(CombatTab, "SHOW_FOV", function(state)
    Config.SHOW_FOV = state
    fovSlider.Visible = state
    if state then StartFOVCircle() else StopFOVCircle() end
end, 7)

fovSlider, _ = CreateSlider(CombatTab, "FOV_RADIUS", 10, 500, 50, function(val)
    Config.FOV_RADIUS = val
    if FOVCircle then FOVCircle.Radius = val end
end, 8)
fovSlider.Visible = false

-- Predicción
CreateToggle(CombatTab, "PREDICTION", function(state)
    Config.PREDICTION = state
    if state then Prediction.Enable() else Prediction.Disable() end
end, 9)

-- Trigger Bot
CreateToggle(CombatTab, "TRIGGER_BOT", function(state)
    Config.TRIGGER_BOT = state
    if state then TriggerBot.Enable() else TriggerBot.Disable() end
end, 10)

-- ================================================================
-- TAB: MÍSTICO
-- ================================================================

CreateSectionLabel(MisticTab, "ANTI-CHEAT BYPASS", 1)

-- Anti-Katana
CreateToggle(MisticTab, "ANTI_KATANA", function(state)
    Config.ANTI_KATANA = state
    if state then AntiKatana.Enable() else AntiKatana.Disable() end
end, 2)

-- Resolver
CreateToggle(MisticTab, "RESOLVER", function(state)
    Config.RESOLVER = state
    if state then Resolver.Enable() else Resolver.Disable() end
end, 3)

-- Anti-Lock
CreateToggle(MisticTab, "ANTI_LOCK", function(state)
    Config.ANTI_LOCK = state
    if state then AntiLock.Enable() else AntiLock.Disable() end
end, 4)

-- ================================================================
-- TAB: MOVIMIENTO
-- ================================================================

CreateSectionLabel(MovementTab, "CHARACTER MOVEMENT", 1)

-- Velocidad
local speedSlider
CreateToggle(MovementTab, "MOD_SPEED", function(state)
    Config.MOD_SPEED = state
    speedSlider.Visible = state
    if not state then
        -- Restaura velocidad original al desactivar
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
end, 2)

speedSlider, _ = CreateSlider(MovementTab, "WALK_SPEED", 0, 400, 16, function(val)
    Config.WALK_SPEED = val
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end, 3)
speedSlider.Visible = false

-- Mantiene la velocidad al respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if Config.MOD_SPEED then
        task.wait(0.5)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.WALK_SPEED end
    end
    if Config.FLY_ON then
        task.wait(1)
        FlyModule.Enable()
    end
end)

CreateSectionLabel(MovementTab, "FLY", 4)

-- Volar
local flySlider
CreateToggle(MovementTab, "FLY_ON", function(state)
    Config.FLY_ON = state
    flySlider.Visible = state
    if state then FlyModule.Enable() else FlyModule.Disable() end
end, 5)

flySlider, _ = CreateSlider(MovementTab, "FLY_SPEED", 5, 500, 50, function(val)
    Config.FLY_SPEED = val
    -- La velocidad se aplica en tiempo real dentro del RenderStepped del módulo
end, 6)
flySlider.Visible = false

-- ================================================================
-- TAB: AJUSTES
-- ================================================================

CreateSectionLabel(SettingsTab, "CONFIG", 1)

-- Guardar configuración
CreateToggle(SettingsTab, "SAVE_CFG", function(state)
    if state then
        SaveConfig()
        -- El toggle se auto-apaga después de guardar
        task.delay(0.5, function()
            -- Referencia al SetToggle si fuera necesario
        end)
    end
end, 2)

-- Cargar configuración
CreateToggle(SettingsTab, "LOAD_CFG", function(state)
    if state then LoadConfig() end
end, 3)

-- Auto-Load al iniciar
CreateToggle(SettingsTab, "AUTO_LOAD", function(state)
    Config.AUTO_LOAD = state
end, 4)

-- Modo Rendimiento (desactiva animaciones del UI para FPS bajo)
CreateToggle(SettingsTab, "PERF_MODE", function(state)
    Config.PERF_MODE = state
    if state then
        -- Desactiva tweens y el pulso del botón flotante
        if pulseTween then pulseTween:Cancel() end
        FloatButton.BackgroundTransparency = 0.15
    else
        StartButtonPulse()
    end
end, 5)

CreateSectionLabel(SettingsTab, "BUTTON", 6)

-- Fijar botón flotante
CreateToggle(SettingsTab, "PIN_BTN", function(state)
    Config.PIN_BTN = state
    ButtonIsFixed  = state
end, 7)

-- Ocultar botón flotante
CreateToggle(SettingsTab, "HIDE_BTN", function(state)
    Config.HIDE_BTN = state
    if state then
        Tween(FloatButton, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.3)
        Tween(FloatStroke, { Transparency = 1 }, 0.3)
    else
        Tween(FloatButton, { BackgroundTransparency = 0.15, TextTransparency = 0 }, 0.3)
        Tween(FloatStroke, { Transparency = 0.7 }, 0.3)
    end
end, 8)

CreateSectionLabel(SettingsTab, "LANGUAGE", 9)

-- ── DROPDOWN DE IDIOMA ────────────────────────────────────
-- Este dropdown NO usa el sistema de localizaciónm interna
-- porque los nombres de idiomas son fijos y siempre reconocibles.
local langOptionHeight   = 30
local langCount          = 5
local langClosedH        = 44
local langOpenH          = langClosedH + langCount * langOptionHeight

local LangDropFrame = Create("Frame", {
    Parent              = SettingsTab,
    Size                = UDim2.new(1, 0, 0, langClosedH),
    BackgroundColor3    = Theme.CardColor,
    BackgroundTransparency = Theme.CardTransparency,
    ClipsDescendants    = true,
    LayoutOrder         = 10,
})
Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = LangDropFrame })

local LangTitle = Create("TextLabel", {
    Parent              = LangDropFrame,
    Size                = UDim2.new(1, -60, 0, langClosedH),
    Position            = UDim2.new(0, 15, 0, 0),
    BackgroundTransparency = 1,
    TextColor3          = Theme.TextColor,
    Font                = Enum.Font.GothamMedium,
    TextSize            = 13,
    TextXAlignment      = Enum.TextXAlignment.Left,
})
local langExtra = { CurrentSelectionKey = Config.LANGUAGE }
RegisterTranslation(LangTitle, "DropdownTitle", "LANG_TITLE", langExtra)

local LangArrow = Create("TextLabel", {
    Parent              = LangDropFrame,
    Size                = UDim2.new(0, 24, 0, 24),
    Position            = UDim2.new(1, -34, 0, 10),
    BackgroundTransparency = 1,
    Text                = "▾",
    TextColor3          = Theme.SecondaryText,
    Font                = Enum.Font.GothamBold,
    TextSize            = 16,
})

local LangContainer = Create("Frame", {
    Parent              = LangDropFrame,
    Size                = UDim2.new(1, 0, 1, -langClosedH),
    Position            = UDim2.new(0, 0, 0, langClosedH),
    BackgroundTransparency = 1,
})
Create("UIListLayout", { Parent = LangContainer, SortOrder = Enum.SortOrder.LayoutOrder })

local LangToggleBtn = Create("TextButton", {
    Parent              = LangDropFrame,
    Size                = UDim2.new(1, 0, 0, langClosedH),
    BackgroundTransparency = 1,
    Text                = "",
    ZIndex              = LangDropFrame.ZIndex + 2,
})

local langIsOpen = false
LangToggleBtn.MouseButton1Click:Connect(function()
    langIsOpen = not langIsOpen
    Tween(LangDropFrame, {
        Size = UDim2.new(1, 0, 0, langIsOpen and langOpenH or langClosedH),
    }, 0.25)
    Tween(LangArrow, { Rotation = langIsOpen and 180 or 0 }, 0.25)
end)

local LangOptions = {
    { name = "Español",  key = "Español"  },
    { name = "English",  key = "Inglés"   },
    { name = "Português",key = "Portugués"},
    { name = "Русский",  key = "Ruso"     },
    { name = "پښتو",     key = "Pastún"   },
}
for i, opt in ipairs(LangOptions) do
    local OptBtn = Create("TextButton", {
        Parent              = LangContainer,
        Size                = UDim2.new(1, 0, 0, langOptionHeight),
        BackgroundColor3    = Theme.DropdownColor,
        BackgroundTransparency = 0.3,
        Text                = "  " .. opt.name,
        TextColor3          = Theme.SecondaryText,
        Font                = Enum.Font.Gotham,
        TextSize            = 12,
        TextXAlignment      = Enum.TextXAlignment.Left,
        LayoutOrder         = i,
        ZIndex              = LangDropFrame.ZIndex + 3,
    })
    OptBtn.MouseEnter:Connect(function()
        Tween(OptBtn, { BackgroundTransparency = 0.0 }, 0.15)
    end)
    OptBtn.MouseLeave:Connect(function()
        Tween(OptBtn, { BackgroundTransparency = 0.3 }, 0.15)
    end)
    OptBtn.MouseButton1Click:Connect(function()
        -- Actualiza el idioma globalmente
        UpdateLanguage(opt.key)
        -- Actualiza el título del dropdown de idioma
        langExtra.CurrentSelectionKey = opt.name
        LangTitle.Text = (Lang[CurrentLanguage]["LANG_TITLE"] or "Language") .. ": " .. opt.name
        -- Cierra el dropdown
        langIsOpen = false
        Tween(LangDropFrame, { Size = UDim2.new(1, 0, 0, langClosedH) }, 0.2)
        Tween(LangArrow, { Rotation = 0 }, 0.2)
    end)
end

-- ┌─────────────────────────────────────────────────────────┐
-- │          AUTO-LOAD DE CONFIGURACIÓN AL INICIAR          │
-- └─────────────────────────────────────────────────────────┘
-- Si el archivo de config existe y AUTO_LOAD estaba activo,
-- carga automáticamente la configuración guardada.
task.spawn(function()
    task.wait(1) -- pequeña espera para que el UI esté listo
    local loaded = LoadConfig()
    if loaded and loaded.AUTO_LOAD then
        print("[LXNDXN] Auto-Load activo: configuración restaurada.")
        -- Aquí podrías aplicar los valores cargados a todos los toggles
        -- usando las referencias guardadas si tuvieras un sistema de registro.
    end
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │                 NOTIFICACIÓN DE CARGA                   │
-- └─────────────────────────────────────────────────────────┘
-- Muestra una notificación flotante temporal al cargar el script.
local function ShowNotification(message, duration)
    duration = duration or 3
    local notif = Create("Frame", {
        Parent              = ScreenGui,
        Size                = UDim2.new(0, 280, 0, 48),
        Position            = UDim2.new(0.5, -140, 1, 0),  -- empieza abajo
        BackgroundColor3    = Theme.AccentColor,
        BackgroundTransparency = 0.1,
        ZIndex              = 100,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = notif })
    Create("TextLabel", {
        Parent              = notif,
        Size                = UDim2.new(1, -20, 1, 0),
        Position            = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text                = message,
        TextColor3          = Color3.fromRGB(255, 255, 255),
        Font                = Enum.Font.GothamBold,
        TextSize            = 13,
        TextXAlignment      = Enum.TextXAlignment.Left,
        ZIndex              = 101,
    })
    -- Anima hacia arriba
    Tween(notif, { Position = UDim2.new(0.5, -140, 1, -60) }, 0.4, Enum.EasingStyle.Back)
    task.delay(duration, function()
        Tween(notif, { Position = UDim2.new(0.5, -140, 1, 10), BackgroundTransparency = 1 }, 0.3)
        task.delay(0.35, function() notif:Destroy() end)
    end)
end

-- Notificación de bienvenida
task.delay(0.5, function()
    ShowNotification("⚡ LXNDXN v3.0 cargado correctamente", 4)
end)

-- ┌─────────────────────────────────────────────────────────┐
-- │      LIMPIEZA GENERAL AL DESTRUIR EL GUI                │
-- └─────────────────────────────────────────────────────────┘
-- Si el ScreenGui es eliminado (por ejemplo al salir),
-- detiene todos los módulos activos limpiamente.
ScreenGui.AncestryChanged:Connect(function()
    if not ScreenGui.Parent then
        ESP.StopBoxes()
        ESP.StopTracers()
        ESP.StopNames()
        ESP.StopHealth()
        KatanaESP.Disable()
        FlyModule.Disable()
        AntiKatana.Disable()
        Resolver.Disable()
        AntiLock.Disable()
        TriggerBot.Disable()
        Prediction.Disable()
        StopFOVCircle()
        for _, conn in pairs(ESP.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        print("[LXNDXN] UI destruída, todos los módulos detenidos.")
    end
end)

-- ================================================================
-- FIN DEL SCRIPT
-- LXNDXN UI Framework v3.0
-- ================================================================
print("╔══════════════════════════════════╗")
print("║     LXNDXN UI v3.0 LOADED       ║")
print("║  Presiona INSERT para abrir/     ║")
print("║  cerrar el menú.                 ║")
print("╚══════════════════════════════════╝")

-- ┌─────────────────────────────────────────────────────────┐
-- │        ANTI-CHEAT SERVER-SIDE (INTEGRADO)              │
-- └─────────────────────────────────────────────────────────┘
-- Se añade aquí como bloque que solo se ejecuta en servidores.
-- Si este archivo corre en cliente, el bloque se ignora.
if LocalPlayer then
    print("[LXNDXN] AntiCheat: Entorno cliente detectado — módulo servidor omitido.")
else
    local AntiCheatManager = {}
    AntiCheatManager.__index = AntiCheatManager

    -- Configuraciones de Tolerancia (Umbrales)
    local AC_CONFIG = {
        MaxWalkSpeedTolerance = 25,
        MaxJumpHeightTolerance = 10,
        MaxWarningsBeforeKick = 3,
        RateLimitRequestsPerSecond = 10
    }

    local PlayerData = {}

    function AntiCheatManager.InitPlayer(player)
        PlayerData[player.UserId] = {
            LastPosition = nil,
            LastCheckTime = tick(),
            Warnings = 0,
            RemoteRequests = 0,
            LastRequestReset = tick()
        }

        player.CharacterAdded:Connect(function(character)
            local rootPart = character:WaitForChild("HumanoidRootPart")
            PlayerData[player.UserId].LastPosition = rootPart.Position
            PlayerData[player.UserId].LastCheckTime = tick()
        end)

        -- Si el personaje ya existe al momento de añadir el jugador
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            PlayerData[player.UserId].LastPosition = player.Character.HumanoidRootPart.Position
            PlayerData[player.UserId].LastCheckTime = tick()
        end
    end

    function AntiCheatManager.RemovePlayer(player)
        PlayerData[player.UserId] = nil
    end

    function AntiCheatManager.CheckMovement()
        for _, player in ipairs(Players:GetPlayers()) do
            local data = PlayerData[player.UserId]
            local character = player.Character
            if data and character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if rootPart and humanoid and humanoid.Health > 0 then
                    local currentTime = tick()
                    local deltaTime = currentTime - data.LastCheckTime
                    if deltaTime > 0.1 and deltaTime < 1 then
                        local currentPos = rootPart.Position
                        local lastPos = data.LastPosition or currentPos
                        local distanceTraveled = Vector3.new(currentPos.X, 0, currentPos.Z) - Vector3.new(lastPos.X, 0, lastPos.Z)
                        local magnitude = distanceTraveled.Magnitude
                        local maxTheoreticalDistance = AC_CONFIG.MaxWalkSpeedTolerance * deltaTime
                        if magnitude > maxTheoreticalDistance then
                            data.Warnings = data.Warnings + 1
                            warn("[Anti-Cheat]: " .. player.Name .. " detectado moviéndose muy rápido. Dist: " .. tostring(magnitude) .. " Max: " .. tostring(maxTheoreticalDistance))
                            -- Rubberband al último lugar válido
                            pcall(function()
                                rootPart.CFrame = CFrame.new(lastPos)
                            end)
                            if data.Warnings >= AC_CONFIG.MaxWarningsBeforeKick then
                                pcall(function() player:Kick("Comportamiento anómalo detectado (Código: M-01)") end)
                            end
                        else
                            data.LastPosition = currentPos
                            data.Warnings = math.max(0, data.Warnings - 0.05)
                        end
                    end
                    data.LastCheckTime = currentTime
                end
            end
        end
    end

    function AntiCheatManager.ValidateRemoteRequest(player)
        local data = PlayerData[player.UserId]
        if not data then return false end
        local currentTime = tick()
        if currentTime - data.LastRequestReset >= 1 then
            data.RemoteRequests = 0
            data.LastRequestReset = currentTime
        end
        data.RemoteRequests = data.RemoteRequests + 1
        if data.RemoteRequests > AC_CONFIG.RateLimitRequestsPerSecond then
            warn("[Anti-Cheat]: " .. player.Name .. " está enviando demasiadas peticiones al servidor.")
            return false
        end
        return true
    end

    Players.PlayerAdded:Connect(AntiCheatManager.InitPlayer)
    Players.PlayerRemoving:Connect(AntiCheatManager.RemovePlayer)
    RunService.Heartbeat:Connect(AntiCheatManager.CheckMovement)

    print("Anti-Cheat Server-Side (integrado) Inicializado.")
end
