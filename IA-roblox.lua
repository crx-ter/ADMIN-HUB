-- LXNDXN --
-- Desarrollado para experiencia Premium Mobile (Estilo iOS Glassmorphism)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local guiParent = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")

-- === DICCIONARIO DE TRADUCCIONES ===
local CurrentLanguage = "Español"

local Lang = {
    ["Español"] = {
        TAB_VISUALS = "VISUALES", TAB_COMBAT = "COMBATE", TAB_MISTIC = "MÍSTICO", TAB_MOVEMENT = "MOVIMIENTO", TAB_SETTINGS = "AJUSTES",
        ESP_BOX = "Cajas ESP", TRACERS = "Trazadoras", ESP_NAMES = "Nombres", ESP_HEALTH = "Vida", KATANA_STATUS = "Estado de Katana",
        SILENT_AIM = "Apuntado Silencioso", DIR_TITLE = "Dirección", DIR_HEAD = "Cabeza", DIR_CHEST = "Pecho", DIR_ALL = "General",
        HIT_CHANCE_ON = "Activar Probabilidad de Acierto", HIT_CHANCE_VAL = "Porcentaje de Acierto (%)",
        SHOW_FOV = "Mostrar FOV", FOV_RADIUS = "Radio del FOV", PREDICTION = "Predicción", TRIGGER_BOT = "Gatillo Automático",
        ANTI_KATANA = "Anti-Katana", RESOLVER = "Resolver", ANTI_LOCK = "Anti-Bloqueo",
        MOD_SPEED = "Modificar Velocidad", WALK_SPEED = "Velocidad de Caminado", FLY_ON = "Volar", FLY_SPEED = "Velocidad de Vuelo",
        SAVE_CFG = "Guardar Configuración", LOAD_CFG = "Cargar Configuración", AUTO_LOAD = "Carga Automática", PERF_MODE = "Modo Rendimiento",
        PIN_BTN = "Fijar Botón Flotante", HIDE_BTN = "Ocultar Botón Flotante", LANG_TITLE = "Cambiar Idioma"
    },
    ["Inglés"] = {
        TAB_VISUALS = "VISUALS", TAB_COMBAT = "COMBAT", TAB_MISTIC = "MYSTIC", TAB_MOVEMENT = "MOVEMENT", TAB_SETTINGS = "SETTINGS",
        ESP_BOX = "ESP Boxes", TRACERS = "Tracers", ESP_NAMES = "Names", ESP_HEALTH = "Health", KATANA_STATUS = "Katana Status",
        SILENT_AIM = "Silent Aim", DIR_TITLE = "Target Part", DIR_HEAD = "Head", DIR_CHEST = "Chest", DIR_ALL = "General",
        HIT_CHANCE_ON = "Enable Hit Chance", HIT_CHANCE_VAL = "Hit Chance (%)",
        SHOW_FOV = "Show FOV", FOV_RADIUS = "FOV Radius", PREDICTION = "Prediction", TRIGGER_BOT = "Trigger Bot",
        ANTI_KATANA = "Anti-Katana", RESOLVER = "Resolver", ANTI_LOCK = "Anti-Lock",
        MOD_SPEED = "Modify Speed", WALK_SPEED = "Walk Speed", FLY_ON = "Fly", FLY_SPEED = "Fly Speed",
        SAVE_CFG = "Save Config", LOAD_CFG = "Load Config", AUTO_LOAD = "Auto Load", PERF_MODE = "Performance Mode",
        PIN_BTN = "Pin Float Button", HIDE_BTN = "Hide Float Button", LANG_TITLE = "Change Language"
    },
    ["Portugués"] = {
        TAB_VISUALS = "VISUAIS", TAB_COMBAT = "COMBATE", TAB_MISTIC = "MÍSTICO", TAB_MOVEMENT = "MOVIMENTO", TAB_SETTINGS = "CONFIGURAÇÕES",
        ESP_BOX = "Caixas ESP", TRACERS = "Rastreadores", ESP_NAMES = "Nomes", ESP_HEALTH = "Vida", KATANA_STATUS = "Status da Katana",
        SILENT_AIM = "Mira Silenciosa", DIR_TITLE = "Direção", DIR_HEAD = "Cabeça", DIR_CHEST = "Peito", DIR_ALL = "Geral",
        HIT_CHANCE_ON = "Ativar Chance de Acerto", HIT_CHANCE_VAL = "Chance de Acerto (%)",
        SHOW_FOV = "Mostrar FOV", FOV_RADIUS = "Raio do FOV", PREDICTION = "Previsão", TRIGGER_BOT = "Gatilho Automático",
        ANTI_KATANA = "Anti-Katana", RESOLVER = "Resolver", ANTI_LOCK = "Anti-Bloqueio",
        MOD_SPEED = "Modificar Velocidade", WALK_SPEED = "Velocidade de Caminhada", FLY_ON = "Voar", FLY_SPEED = "Velocidade de Voo",
        SAVE_CFG = "Salvar Configuração", LOAD_CFG = "Carregar Configuração", AUTO_LOAD = "Carregamento Automático", PERF_MODE = "Modo Desempenho",
        PIN_BTN = "Fixar Botão Flutuante", HIDE_BTN = "Ocultar Botão Flutuante", LANG_TITLE = "Mudar Idioma"
    },
    ["Ruso"] = {
        TAB_VISUALS = "ВИЗУАЛЫ", TAB_COMBAT = "БОЙ", TAB_MISTIC = "МИСТИКА", TAB_MOVEMENT = "ДВИЖЕНИЕ", TAB_SETTINGS = "НАСТРОЙКИ",
        ESP_BOX = "ESP Коробки", TRACERS = "Трейсеры", ESP_NAMES = "Имена", ESP_HEALTH = "Здоровье", KATANA_STATUS = "Статус Катаны",
        SILENT_AIM = "Тихий Аим", DIR_TITLE = "Цель", DIR_HEAD = "Голова", DIR_CHEST = "Грудь", DIR_ALL = "Общее",
        HIT_CHANCE_ON = "Шанс Попадания", HIT_CHANCE_VAL = "Шанс Попадания (%)",
        SHOW_FOV = "Показать FOV", FOV_RADIUS = "Радиус FOV", PREDICTION = "Предугадывание", TRIGGER_BOT = "Автоспуск",
        ANTI_KATANA = "Анти-Катана", RESOLVER = "Резольвер", ANTI_LOCK = "Анти-Захват",
        MOD_SPEED = "Изменить Скорость", WALK_SPEED = "Скорость Ходьбы", FLY_ON = "Полет", FLY_SPEED = "Скорость Полета",
        SAVE_CFG = "Сохранить Конфиг", LOAD_CFG = "Загрузить Конфиг", AUTO_LOAD = "Автозагрузка", PERF_MODE = "Производительность",
        PIN_BTN = "Закрепить Кнопку", HIDE_BTN = "Скрыть Кнопку", LANG_TITLE = "Изменить Язык"
    },
    ["Pastún (Afganistán)"] = {
        TAB_VISUALS = "لیدونه", TAB_COMBAT = "جګړه", TAB_MISTIC = "صوفیانه", TAB_MOVEMENT = "حرکت", TAB_SETTINGS = "تنظیمات",
        ESP_BOX = "ESP بکسونه", TRACERS = "تعقیبونکي", ESP_NAMES = "نومونه", ESP_HEALTH = "روغتیا", KATANA_STATUS = "د کټانا حالت",
        SILENT_AIM = "خاموش هدف", DIR_TITLE = "لارښوونه", DIR_HEAD = "سر", DIR_CHEST = "سینه", DIR_ALL = "عمومي",
        HIT_CHANCE_ON = "د وهلو چانس فعال کړئ", HIT_CHANCE_VAL = "د وهلو چانس (%)",
        SHOW_FOV = "FOV وښایاست", FOV_RADIUS = "د FOV شعاع", PREDICTION = "وړاندوینه", TRIGGER_BOT = "اتوماتیک محرک",
        ANTI_KATANA = "انټي-کټانا", RESOLVER = "حل کوونکی", ANTI_LOCK = "انټي-لاک",
        MOD_SPEED = "سرعت بدل کړئ", WALK_SPEED = "د تګ سرعت", FLY_ON = "الوتنه", FLY_SPEED = "د الوتنې سرعت",
        SAVE_CFG = "تشکیلات خوندي کړئ", LOAD_CFG = "تشکیلات بار کړئ", AUTO_LOAD = "اتومات بار", PERF_MODE = "د فعالیت حالت",
        PIN_BTN = "تڼۍ پن کړئ", HIDE_BTN = "تڼۍ پټ کړئ", LANG_TITLE = "ژبه بدله کړئ"
    }
}

-- Registro de elementos para actualización en tiempo real
local TranslatingElements = {}

local function RegisterTranslation(instance, type, key, extra)
    table.insert(TranslatingElements, {UI = instance, Type = type, Key = key, Extra = extra})
    -- Aplicar texto inicial
    if type == "Text" then
        instance.Text = Lang[CurrentLanguage][key]
    elseif type == "DropdownTitle" then
        instance.Text = Lang[CurrentLanguage][key] .. ": " .. (Lang[CurrentLanguage][extra.CurrentSelectionKey] or extra.CurrentSelectionKey)
    elseif type == "DropdownOption" then
        instance.Text = "  " .. Lang[CurrentLanguage][key]
    end
end

local function UpdateLanguage(newLang)
    CurrentLanguage = newLang
    for _, item in ipairs(TranslatingElements) do
        if item.Type == "Text" then
            item.UI.Text = Lang[CurrentLanguage][item.Key]
        elseif item.Type == "DropdownTitle" then
            local sel = Lang[CurrentLanguage][item.Extra.CurrentSelectionKey] or item.Extra.CurrentSelectionKey
            item.UI.Text = Lang[CurrentLanguage][item.Key] .. ": " .. sel
        elseif item.Type == "DropdownOption" then
            item.UI.Text = "  " .. Lang[CurrentLanguage][item.Key]
        end
    end
end

-- === VARIABLES GLOBALES DE TEMA ===
local Theme = {
    MainColor = Color3.fromRGB(15, 15, 18), GlassTransparency = 0.35, AccentColor = Color3.fromRGB(10, 132, 255),
    TextColor = Color3.fromRGB(255, 255, 255), SecondaryText = Color3.fromRGB(170, 170, 170),
    BorderColor = Color3.fromRGB(255, 255, 255), BorderTransparency = 0.85, DropdownColor = Color3.fromRGB(30, 30, 35)
}

local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do if k ~= "Parent" then inst[k] = v end end
    if properties.Parent then inst.Parent = properties.Parent end
    return inst
end

local function Tween(object, properties, duration)
    local tw = TweenService:Create(object, TweenInfo.new(duration or 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    tw:Play() return tw
end

-- === UI PRINCIPAL ===
local ScreenGui = Create("ScreenGui", { Name = "LXNDXN_UI", Parent = guiParent, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999 })

local FloatButton = Create("TextButton", {
    Name = "FloatButton", Parent = ScreenGui, Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, 0, 0.1, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.MainColor, BackgroundTransparency = Theme.GlassTransparency,
    Text = "L", TextColor3 = Theme.TextColor, TextTransparency = 0, TextScaled = true, Font = Enum.Font.GothamBold, ClipsDescendants = true
})
local FloatCorner = Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatButton })
local FloatStroke = Create("UIStroke", { Color = Theme.BorderColor, Transparency = Theme.BorderTransparency, Thickness = 1.5, Parent = FloatButton })

local MainFrame = Create("Frame", {
    Name = "MainFrame", Parent = ScreenGui, Size = UDim2.new(0, 480, 0, 383), Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.MainColor, BackgroundTransparency = Theme.GlassTransparency,
    ClipsDescendants = true, Visible = false
})
Create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = MainFrame })
Create("UIStroke", { Color = Theme.BorderColor, Transparency = Theme.BorderTransparency, Thickness = 1, Parent = MainFrame })

local TopBar = Create("Frame", { Name = "TopBar", Parent = MainFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })
Create("TextLabel", { Name = "Title", Parent = TopBar, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, Text = "LXNDXN", TextColor3 = Theme.TextColor, Font = Enum.Font.GothamBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left })

local TabBar = Create("ScrollingFrame", { Name = "TabBar", Parent = MainFrame, Size = UDim2.new(1, -40, 0, 35), Position = UDim2.new(0, 20, 0, 45), BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(1.2, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.X })
Create("UIListLayout", { Parent = TabBar, FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })

local ContentContainer = Create("Frame", { Name = "ContentContainer", Parent = MainFrame, Size = UDim2.new(1, -40, 1, -100), Position = UDim2.new(0, 20, 0, 90), BackgroundTransparency = 1 })

-- === DRAGGING SISTEMA ===
local ButtonIsFixed = false
local function MakeDraggable(guiObject, dragHandle)
    dragHandle = dragHandle or guiObject
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if guiObject == FloatButton and ButtonIsFixed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true dragStart = input.Position startPos = guiObject.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(FloatButton) MakeDraggable(MainFrame, TopBar)

FloatButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        MainFrame.Size = UDim2.new(0, 480, 0, 0) MainFrame.BackgroundTransparency = 1
        Tween(MainFrame, {Size = UDim2.new(0, 480, 0, 383), BackgroundTransparency = Theme.GlassTransparency}, 0.5)
    end
end)

-- === CREADORES DE COMPONENTES ===
local Tabs, TabFrames = {}, {}

local function UpdateCanvasSize(frame)
    local layout = frame:FindFirstChildOfClass("UIListLayout")
    if layout then frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20) end
end

local function CreateTab(key)
    local TabBtn = Create("TextButton", { Name = key, Parent = TabBar, Size = UDim2.new(0, 90, 1, 0), BackgroundTransparency = 1, TextColor3 = Theme.SecondaryText, Font = Enum.Font.GothamSemibold, TextSize = 14 })
    RegisterTranslation(TabBtn, "Text", key)
    
    local TabFrame = Create("ScrollingFrame", { Name = key.."_Frame", Parent = ContentContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 2, Visible = false })
    local layout = Create("UIListLayout", { Parent = TabFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
    
    Tabs[key] = TabBtn TabFrames[key] = TabFrame
    TabBtn.MouseButton1Click:Connect(function()
        for k, frame in pairs(TabFrames) do
            frame.Visible = (k == key)
            Tween(Tabs[k], {TextColor3 = (k == key) and Theme.AccentColor or Theme.SecondaryText}, 0.2)
        end
    end)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() UpdateCanvasSize(TabFrame) end)
    return TabFrame
end

local function CreateToggle(parent, key, callback)
    local ToggleFrame = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.5 })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ToggleFrame })
    local Label = Create("TextLabel", { Parent = ToggleFrame, Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, TextColor3 = Theme.TextColor, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    RegisterTranslation(Label, "Text", key)
    
    local SwitchBtn = Create("TextButton", { Parent = ToggleFrame, Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -55, 0.5, -10), BackgroundColor3 = Color3.fromRGB(50, 50, 50), Text = "", AutoButtonColor = false })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBtn })
    local Indicator = Create("Frame", { Parent = SwitchBtn, Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Indicator })
    
    local toggled = false
    SwitchBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        Tween(Indicator, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
        Tween(SwitchBtn, {BackgroundColor3 = toggled and Theme.AccentColor or Color3.fromRGB(50, 50, 50)}, 0.2)
        if callback then callback(toggled) end
    end)
    return ToggleFrame
end

local function CreateSlider(parent, key, min, max, default, callback)
    local SliderFrame = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.5 })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SliderFrame })
    
    local Label = Create("TextLabel", { Parent = SliderFrame, Size = UDim2.new(1, -30, 0, 20), Position = UDim2.new(0, 15, 0, 5), BackgroundTransparency = 1, TextColor3 = Theme.TextColor, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    RegisterTranslation(Label, "Text", key)
    local ValueLabel = Create("TextLabel", { Parent = SliderFrame, Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -65, 0, 5), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Theme.AccentColor, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right })
    
    local SliderBG = Create("Frame", { Parent = SliderFrame, Size = UDim2.new(1, -30, 0, 6), Position = UDim2.new(0, 15, 0, 35), BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBG })
    local Fill = Create("Frame", { Parent = SliderBG, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.AccentColor })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })
    local Knob = Create("Frame", { Parent = Fill, Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7), BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Knob })
    
    local dragging = false
    local function UpdateSlider(input)
        local pos = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * pos)
        Fill.Size = UDim2.new(pos, 0, 1, 0) ValueLabel.Text = tostring(value)
        if callback then callback(value) end
    end
    
    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true UpdateSlider(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateSlider(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    
    return SliderFrame
end

local function CreateLocalizedDropdown(parent, titleKey, optionKeys, defaultKey, callback)
    local DropdownFrame = Create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.5, ClipsDescendants = true })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = DropdownFrame })
    
    local TitleLabel = Create("TextLabel", { Parent = DropdownFrame, Size = UDim2.new(1, -60, 0, 40), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, TextColor3 = Theme.TextColor, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
    local DropArrow = Create("TextLabel", { Parent = DropdownFrame, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0, 10), BackgroundTransparency = 1, Text = "▼", TextColor3 = Theme.SecondaryText, Font = Enum.Font.GothamBold, TextSize = 14 })
    
    local extraData = {CurrentSelectionKey = defaultKey}
    RegisterTranslation(TitleLabel, "DropdownTitle", titleKey, extraData)
    
    local OptionContainer = Create("Frame", { Parent = DropdownFrame, Size = UDim2.new(1, 0, 1, -40), Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1 })
    Create("UIListLayout", { Parent = OptionContainer, SortOrder = Enum.SortOrder.LayoutOrder })
    
    local isOpen = false
    local containerHeight = #optionKeys * 30
    local ToggleButton = Create("TextButton", { Parent = DropdownFrame, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "" })
    
    ToggleButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Tween(DropdownFrame, {Size = isOpen and UDim2.new(1, 0, 0, 40 + containerHeight) or UDim2.new(1, 0, 0, 40)}, 0.2)
        Tween(DropArrow, {Rotation = isOpen and 180 or 0}, 0.2)
    end)
    
    for _, optKey in ipairs(optionKeys) do
        local OptBtn = Create("TextButton", { Parent = OptionContainer, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.DropdownColor, BackgroundTransparency = 0.5, TextColor3 = Theme.SecondaryText, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
        RegisterTranslation(OptBtn, "DropdownOption", optKey)
        
        OptBtn.MouseButton1Click:Connect(function()
            extraData.CurrentSelectionKey = optKey
            TitleLabel.Text = Lang[CurrentLanguage][titleKey] .. ": " .. Lang[CurrentLanguage][optKey]
            isOpen = false
            Tween(DropdownFrame, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
            Tween(DropArrow, {Rotation = 0}, 0.2)
            if callback then callback(optKey) end
        end)
    end
    return DropdownFrame
end

-- === CONSTRUCCIÓN DE LA INTERFAZ ===

local VisualsTab = CreateTab("TAB_VISUALS")
local CombatTab = CreateTab("TAB_COMBAT")
local MisticTab = CreateTab("TAB_MISTIC")
local MovementTab = CreateTab("TAB_MOVEMENT")
local SettingsTab = CreateTab("TAB_SETTINGS")

TabFrames["TAB_VISUALS"].Visible = true
Tabs["TAB_VISUALS"].TextColor3 = Theme.AccentColor

-- VISUALES
CreateToggle(VisualsTab, "ESP_BOX", function(state)
    ESP.Enabled = state
    print("ESP " .. (state and "✅ Activado" or "❌ Desactivado"))
end)CreateToggle(VisualsTab, "TRACERS", function(state) end)
CreateToggle(VisualsTab, "ESP_NAMES", function(state) end)
CreateToggle(VisualsTab, "ESP_HEALTH", function(state) end)
CreateToggle(VisualsTab, "KATANA_STATUS", function(state) end)

-- COMBATE
local AimDropdown
CreateToggle(CombatTab, "SILENT_AIM", function(state) if AimDropdown then AimDropdown.Visible = state end end)
AimDropdown = CreateLocalizedDropdown(CombatTab, "DIR_TITLE", {"DIR_HEAD", "DIR_CHEST", "DIR_ALL"}, "DIR_HEAD", function(selKey) end)
AimDropdown.Visible = false

local HitChanceSlider
CreateToggle(CombatTab, "HIT_CHANCE_ON", function(state) if HitChanceSlider then HitChanceSlider.Visible = state end end)
HitChanceSlider = CreateSlider(CombatTab, "HIT_CHANCE_VAL", 0, 100, 100, function(val) end)
HitChanceSlider.Visible = false

local FOVSlider
CreateToggle(CombatTab, "SHOW_FOV", function(state) if FOVSlider then FOVSlider.Visible = state end end)
FOVSlider = CreateSlider(CombatTab, "FOV_RADIUS", 0, 100, 50, function(val) end)
FOVSlider.Visible = false

CreateToggle(CombatTab, "PREDICTION", function(state) end)
CreateToggle(CombatTab, "TRIGGER_BOT", function(state) end)

-- MÍSTICO
CreateToggle(MisticTab, "ANTI_KATANA", function(state) end)
CreateToggle(MisticTab, "RESOLVER", function(state) end)
CreateToggle(MisticTab, "ANTI_LOCK", function(state) end)

-- MOVIMIENTO
local SpeedSlider
CreateToggle(MovementTab, "MOD_SPEED", function(state)
    if SpeedSlider then SpeedSlider.Visible = state end
    if not state and localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then localPlayer.Character.Humanoid.WalkSpeed = 16 end
end)
SpeedSlider = CreateSlider(MovementTab, "WALK_SPEED", 0, 300, 16, function(val)
    if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then localPlayer.Character.Humanoid.WalkSpeed = val end
end)
SpeedSlider.Visible = false

local FlySlider
CreateToggle(MovementTab, "FLY_ON", function(state) if FlySlider then FlySlider.Visible = state end end)
FlySlider = CreateSlider(MovementTab, "FLY_SPEED", 0, 300, 50, function(val) end)
FlySlider.Visible = false

-- AJUSTES
CreateToggle(SettingsTab, "SAVE_CFG", function() end)
CreateToggle(SettingsTab, "LOAD_CFG", function() end)
CreateToggle(SettingsTab, "AUTO_LOAD", function() end)
CreateToggle(SettingsTab, "PERF_MODE", function() end)

CreateToggle(SettingsTab, "PIN_BTN", function(state) ButtonIsFixed = state end)
CreateToggle(SettingsTab, "HIDE_BTN", function(state)
    if state then
        Tween(FloatButton, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
        Tween(FloatStroke, {Transparency = 1}, 0.2)
    else
        Tween(FloatButton, {BackgroundTransparency = Theme.GlassTransparency, TextTransparency = 0}, 0.2)
        Tween(FloatStroke, {Transparency = Theme.BorderTransparency}, 0.2)
    end
end)

-- Menú Especial para cambiar el idioma base (Este NO usa el sistema dinámico de su propio texto para que los nombres de los idiomas sean fijos y siempre reconocibles).
local LangDropdown = Create("Frame", { Parent = SettingsTab, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(25, 25, 30), BackgroundTransparency = 0.5, ClipsDescendants = true })
Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = LangDropdown })
local LangTitle = Create("TextLabel", { Parent = LangDropdown, Size = UDim2.new(1, -60, 0, 40), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, TextColor3 = Theme.TextColor, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left })
RegisterTranslation(LangTitle, "DropdownTitle", "LANG_TITLE", {CurrentSelectionKey = "Español"}) -- Extra.CurrentSelectionKey usará el string literal aquí

local LangArrow = Create("TextLabel", { Parent = LangDropdown, Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -30, 0, 10), BackgroundTransparency = 1, Text = "▼", TextColor3 = Theme.SecondaryText, Font = Enum.Font.GothamBold, TextSize = 14 })
local LangContainer = Create("Frame", { Parent = LangDropdown, Size = UDim2.new(1, 0, 1, -40), Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1 })
Create("UIListLayout", { Parent = LangContainer, SortOrder = Enum.SortOrder.LayoutOrder })
local L_isOpen = false
local LangBtnToggle = Create("TextButton", { Parent = LangDropdown, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "" })

LangBtnToggle.MouseButton1Click:Connect(function()
    L_isOpen = not L_isOpen
    Tween(LangDropdown, {Size = L_isOpen and UDim2.new(1, 0, 0, 40 + (5 * 30)) or UDim2.new(1, 0, 0, 40)}, 0.2)
    Tween(LangArrow, {Rotation = L_isOpen and 180 or 0}, 0.2)
end)

local LangOptions = {"Español", "Inglés", "Portugués", "Ruso", "Pastún (Afganistán)"}
for _, opt in ipairs(LangOptions) do
    local OptBtn = Create("TextButton", { Parent = LangContainer, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.DropdownColor, BackgroundTransparency = 0.5, Text = "  " .. opt, TextColor3 = Theme.SecondaryText, Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left })
    OptBtn.MouseButton1Click:Connect(function()
        L_isOpen = false
        Tween(LangDropdown, {Size = UDim2.new(1, 0, 0, 40)}, 0.2)
        Tween(LangArrow, {Rotation = 0}, 0.2)
        
        -- Ejecutar la traducción principal
        UpdateLanguage(opt)
        
        -- Actualizar el título de este Dropdown manualmente ya que "opt" no es un Key de diccionario, es el nombre del idioma real
        for _, v in ipairs(TranslatingElements) do
            if v.UI == LangTitle then
                v.Extra.CurrentSelectionKey = opt
                v.UI.Text = Lang[CurrentLanguage][v.Key] .. ": " .. opt
            end
        end
    end)
end
- =============================================
-- === VISUALS - ESP SYSTEM ===
-- =============================================

local Camera = workspace.CurrentCamera

local ESP = {
    Enabled = false,
    Boxes = {},
    Tracers = {},
    Names = {}
}

local function CreateESP(plr)
    if plr == localPlayer then return end

    local Box = Drawing.new("Square")
    Box.Thickness = 1.8
    Box.Filled = false
    Box.Transparency = 1
    Box.Color = Color3.fromRGB(255, 60, 60)

    local Tracer = Drawing.new("Line")
    Tracer.Thickness = 1.6
    Tracer.Transparency = 1
    Tracer.Color = Color3.fromRGB(0, 180, 255)

    local Name = Drawing.new("Text")
    Name.Size = 14
    Name.Center = true
    Name.Outline = true
    Name.Color = Color3.new(1, 1, 1)
    Name.Transparency = 1

    ESP.Boxes[plr] = Box
    ESP.Tracers[plr] = Tracer
    ESP.Names[plr] = Name
end

local function UpdateESP()
    if not ESP.Enabled then
        for _, v in pairs(ESP.Boxes) do v.Visible = false end
        for _, v in pairs(ESP.Tracers) do v.Visible = false end
        for _, v in pairs(ESP.Names) do v.Visible = false end
        return
    end

    for plr, box in pairs(ESP.Boxes) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local root = plr.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen then
                local scale = 2800 / pos.Z
                box.Size = Vector2.new(scale * 1.6, scale * 2.4)
                box.Position = Vector2.new(pos.X - box.Size.X/2, pos.Y - box.Size.Y/2)
                box.Visible = true

                local tracer = ESP.Tracers[plr]
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 40)
                tracer.To = Vector2.new(pos.X, pos.Y)
                tracer.Visible = true

                local name = ESP.Names[plr]
                name.Text = plr.Name
                name.Position = Vector2.new(pos.X, pos.Y - box.Size.Y/2 - 20)
                name.Visible = true
            else
                box.Visible = false
                ESP.Tracers[plr].Visible = false
                ESP.Names[plr].Visible = false
            end
        end
    end
end

-- Crear ESP para todos los jugadores
for _, plr in ipairs(Players:GetPlayers()) do
    CreateESP(plr)
end
Players.PlayerAdded:Connect(CreateESP)

-- Actualizar cada frame
RunService.RenderStepped:Connect(UpdateESP)

print("✅ Sistema ESP cargado correctamente")
print("LXNDXN UI: Localization System loaded successfully.")
