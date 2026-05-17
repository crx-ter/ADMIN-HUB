-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 1 ─ LIMPIEZA DE INSTANCIAS ANTERIORES
--  Garantiza que si el script se re-ejecuta no deje residuos.
--  Usa getgenv() para guardar referencias persistentes entre ejecuciones.
-- ══════════════════════════════════════════════════════════════════

--[[ ── 1.1  Destruye la ScreenGui anterior si existe ─────────────
     getgenv() es el entorno global del ejecutor; persiste entre
     ejecuciones del mismo script dentro de la misma sesión.      ]]
if getgenv().LXNDXN_GUI then
    pcall(function() getgenv().LXNDXN_GUI:Destroy() end)
    getgenv().LXNDXN_GUI = nil
end

--[[ ── 1.2  Desconecta TODAS las conexiones de la sesión anterior
     Esto evita memory leaks y callbacks duplicados.              ]]
getgenv().LXNDXN_CONNECTIONS = getgenv().LXNDXN_CONNECTIONS or {}
for _, conn in pairs(getgenv().LXNDXN_CONNECTIONS) do
    pcall(function() conn:Disconnect() end)
end
table.clear(getgenv().LXNDXN_CONNECTIONS)

--[[ ── 1.3  Limpia Drawing objects anteriores (tracers, FOV, etc.)
     Drawing.new() crea objetos de dibujo que no son instancias
     Roblox, por lo que necesitan limpieza explícita.             ]]
getgenv().LXNDXN_DRAWINGS = getgenv().LXNDXN_DRAWINGS or {}
for _, drawing in pairs(getgenv().LXNDXN_DRAWINGS) do
    pcall(function() drawing:Remove() end)
end
table.clear(getgenv().LXNDXN_DRAWINGS)

--[[ ── 1.4  Cancela tasks/threads activos de la sesión anterior   ]]
getgenv().LXNDXN_THREADS = getgenv().LXNDXN_THREADS or {}
for _, thread in pairs(getgenv().LXNDXN_THREADS) do
    pcall(function() task.cancel(thread) end)
end
table.clear(getgenv().LXNDXN_THREADS)

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 2 ─ SERVICIOS DE ROBLOX
-- ══════════════════════════════════════════════════════════════════

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local Workspace        = game:GetService("Workspace")

local Camera           = Workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 3 ─ HELPERS DE getgenv() PARA REGISTRO SEGURO
--  Funciones utilitarias para registrar conexiones/threads/drawings
--  de forma centralizada y poder limpiarlos al re-ejecutar.
-- ══════════════════════════════════════════════════════════════════

--[[ Registra una RBXScriptConnection para limpieza automática ]]
local function TrackConnection(conn)
    table.insert(getgenv().LXNDXN_CONNECTIONS, conn)
    return conn
end

--[[ Registra un objeto Drawing para limpieza automática ]]
local function TrackDrawing(d)
    table.insert(getgenv().LXNDXN_DRAWINGS, d)
    return d
end

--[[ Registra un task.spawn thread para cancelación automática ]]
local function TrackThread(t)
    table.insert(getgenv().LXNDXN_THREADS, t)
    return t
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 4 ─ CREACIÓN DEL SCREENGUI (Safe CoreGui inject)
-- ══════════════════════════════════════════════════════════════════

--[[ Primero elimina cualquier GUI con el mismo nombre que haya
     quedado en CoreGui (por si el ejecutor no limpió bien).      ]]
local _old = CoreGui:FindFirstChild("LXNDXN_UI_v4")
if _old then pcall(function() _old:Destroy() end) end

--[[ Crea el ScreenGui principal e inyecta en CoreGui.
     Si el ejecutor no tiene permisos, cae a PlayerGui.           ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "LXNDXN_UI_v4"
ScreenGui.ResetOnSpawn    = false
ScreenGui.IgnoreGuiInset  = true
ScreenGui.DisplayOrder    = 999
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling

local _guiOk = pcall(function() ScreenGui.Parent = CoreGui end)
if not _guiOk then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

--[[ Guarda la referencia global para que la próxima ejecución
     pueda destruirla limpiamente.                                ]]
getgenv().LXNDXN_GUI = ScreenGui

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 5 ─ CONFIGURACIÓN GLOBAL (CONFIG STATE)
--  Una sola tabla con TODOS los valores en tiempo real.
--  Se serializa a JSON para guardar/cargar desde archivo.
-- ══════════════════════════════════════════════════════════════════

local Config: {[string]: any} = {
    -- ── VISUALES ────────────────────────────────────────────────
    ESP_BOX             = false,
    ESP_BOX_COLOR_FILL  = { 255, 50,  50  },  -- RGB almacenado como tabla
    ESP_BOX_COLOR_OUT   = { 255, 255, 255 },
    TRACERS             = false,
    TRACER_COLOR        = { 255, 230, 0   },
    ESP_NAMES           = false,
    ESP_HEALTH          = false,
    HEALTH_BAR          = true,   -- barra de vida adicional
    KATANA_STATUS       = false,
    DISTANCE_ESP        = false,  -- muestra distancia en studs
    SKELETON_ESP        = false,  -- [EJEMPLO] líneas de esqueleto

    -- ── COMBATE ─────────────────────────────────────────────────
    SILENT_AIM          = false,
    SILENT_AIM_PART     = "Head",   -- "Head" | "UpperTorso" | "HumanoidRootPart"
    HIT_CHANCE_ON       = false,
    HIT_CHANCE_VAL      = 100,      -- 0-100 %
    SHOW_FOV            = false,
    FOV_RADIUS          = 120,
    FOV_FILLED          = false,
    PREDICTION          = false,
    PREDICTION_FACTOR   = 0.12,     -- segundos de predicción (ajusta al ping)
    TRIGGER_BOT         = false,
    TRIGGER_DELAY       = 60,       -- ms antes de "disparar"
    AIMLOCK             = false,    -- [EJEMPLO] bloqueo de objetivo

    -- ── MÍSTICO ─────────────────────────────────────────────────
    ANTI_KATANA         = false,
    RESOLVER            = false,
    RESOLVER_MODE       = "Auto",   -- "Auto" | "Brute" | "Static"
    ANTI_LOCK           = false,
    ANTI_AIM            = false,    -- [EJEMPLO] mueve la cámara erráticamente
    FAKE_LAG            = false,    -- [EJEMPLO] manipula paquetes de red

    -- ── MOVIMIENTO ──────────────────────────────────────────────
    MOD_SPEED           = false,
    WALK_SPEED          = 16,
    MOD_JUMP            = false,
    JUMP_POWER          = 50,
    FLY_ON              = false,
    FLY_SPEED           = 80,
    NOCLIP              = false,    -- [EJEMPLO] atraviesa paredes
    INF_JUMP            = false,    -- salta infinitamente en el aire
    BHOP                = false,    -- bunny hop automático

    -- ── AJUSTES ─────────────────────────────────────────────────
    AUTO_LOAD           = false,
    PERF_MODE           = false,
    PIN_BTN             = false,
    HIDE_BTN            = false,
    LANGUAGE            = "Español",
    KEYBIND_TOGGLE      = Enum.KeyCode.Insert,
    SHOW_WATERMARK      = true,
}

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 6 ─ LOCALIZACIÓN (i18n) AVANZADA
-- ══════════════════════════════════════════════════════════════════

local CurrentLanguage: string = Config.LANGUAGE

--[[ Tabla maestra de traducciones. Cada key es una clave interna
     y cada valor es el string mostrado en la UI.                 ]]
local Lang: {[string]: {[string]: string}} = {
    ["Español"] = {
        -- Tabs
        TAB_VISUALS  = "VISUALES",  TAB_COMBAT   = "COMBATE",
        TAB_MISTIC   = "MÍSTICO",   TAB_MOVEMENT = "MOVIMIENTO",
        TAB_SETTINGS = "AJUSTES",
        -- Visuales
        ESP_BOX = "Cajas ESP",           TRACERS       = "Trazadoras",
        ESP_NAMES = "Nombres ESP",       ESP_HEALTH    = "Vida ESP",
        KATANA_STATUS = "Estado Katana", DISTANCE_ESP  = "Distancia ESP",
        SKELETON_ESP  = "Esqueleto ESP", HEALTH_BAR    = "Barra de Vida",
        -- Combate
        SILENT_AIM    = "Apuntado Silencioso",  DIR_TITLE     = "Parte del Cuerpo",
        DIR_HEAD      = "Cabeza",               DIR_CHEST     = "Pecho",
        DIR_ALL       = "Centro",
        HIT_CHANCE_ON = "Probabilidad de Acierto",
        HIT_CHANCE_VAL= "Porcentaje (%)",
        SHOW_FOV      = "Mostrar FOV",          FOV_RADIUS    = "Radio del FOV",
        FOV_FILLED    = "FOV Relleno",          PREDICTION    = "Predicción",
        PRED_FACTOR   = "Factor de Predicción", TRIGGER_BOT   = "Gatillo Automático",
        TRIGGER_DELAY = "Delay (ms)",           AIMLOCK       = "Bloqueo de Mira",
        -- Místico
        ANTI_KATANA   = "Anti-Katana",    RESOLVER      = "Resolver",
        RESOLVER_MODE = "Modo Resolver",  ANTI_LOCK     = "Anti-Bloqueo",
        ANTI_AIM      = "Anti-Aim",       FAKE_LAG      = "Fake Lag",
        RES_AUTO      = "Automático",     RES_BRUTE     = "Fuerza Bruta",
        RES_STATIC    = "Estático",
        -- Movimiento
        MOD_SPEED     = "Modificar Velocidad",  WALK_SPEED    = "Velocidad Caminado",
        MOD_JUMP      = "Modificar Salto",      JUMP_POWER    = "Potencia de Salto",
        FLY_ON        = "Volar",                FLY_SPEED     = "Velocidad de Vuelo",
        NOCLIP        = "No-Clip",              INF_JUMP      = "Salto Infinito",
        BHOP          = "Bunny Hop",
        -- Ajustes
        SAVE_CFG      = "Guardar Configuración", LOAD_CFG     = "Cargar Configuración",
        AUTO_LOAD     = "Carga Automática",       PERF_MODE   = "Modo Rendimiento",
        PIN_BTN       = "Fijar Botón",           HIDE_BTN     = "Ocultar Botón",
        LANG_TITLE    = "Idioma",                WATERMARK    = "Marca de Agua",
    },
    ["Inglés"] = {
        TAB_VISUALS  = "VISUALS",   TAB_COMBAT   = "COMBAT",
        TAB_MISTIC   = "MYSTIC",    TAB_MOVEMENT = "MOVEMENT",
        TAB_SETTINGS = "SETTINGS",
        ESP_BOX = "ESP Boxes",       TRACERS       = "Tracers",
        ESP_NAMES = "Name ESP",      ESP_HEALTH    = "Health ESP",
        KATANA_STATUS = "Katana Status", DISTANCE_ESP = "Distance ESP",
        SKELETON_ESP  = "Skeleton ESP",  HEALTH_BAR   = "Health Bar",
        SILENT_AIM    = "Silent Aim",    DIR_TITLE    = "Target Part",
        DIR_HEAD      = "Head",          DIR_CHEST    = "Chest",
        DIR_ALL       = "Center",
        HIT_CHANCE_ON = "Hit Chance",    HIT_CHANCE_VAL = "Percentage (%)",
        SHOW_FOV      = "Show FOV",      FOV_RADIUS   = "FOV Radius",
        FOV_FILLED    = "Filled FOV",    PREDICTION   = "Prediction",
        PRED_FACTOR   = "Pred. Factor",  TRIGGER_BOT  = "Trigger Bot",
        TRIGGER_DELAY = "Delay (ms)",    AIMLOCK      = "Aim Lock",
        ANTI_KATANA   = "Anti-Katana",   RESOLVER     = "Resolver",
        RESOLVER_MODE = "Resolver Mode", ANTI_LOCK    = "Anti-Lock",
        ANTI_AIM      = "Anti-Aim",      FAKE_LAG     = "Fake Lag",
        RES_AUTO      = "Automatic",     RES_BRUTE    = "Brute Force",
        RES_STATIC    = "Static",
        MOD_SPEED     = "Modify Speed",  WALK_SPEED   = "Walk Speed",
        MOD_JUMP      = "Modify Jump",   JUMP_POWER   = "Jump Power",
        FLY_ON        = "Fly",           FLY_SPEED    = "Fly Speed",
        NOCLIP        = "No-Clip",       INF_JUMP     = "Infinite Jump",
        BHOP          = "Bunny Hop",
        SAVE_CFG      = "Save Config",   LOAD_CFG     = "Load Config",
        AUTO_LOAD     = "Auto Load",     PERF_MODE    = "Performance Mode",
        PIN_BTN       = "Pin Button",    HIDE_BTN     = "Hide Button",
        LANG_TITLE    = "Language",      WATERMARK    = "Watermark",
    },
    ["Portugués"] = {
        TAB_VISUALS  = "VISUAIS",   TAB_COMBAT   = "COMBATE",
        TAB_MISTIC   = "MÍSTICO",   TAB_MOVEMENT = "MOVIMENTO",
        TAB_SETTINGS = "CONFIGURAÇÕES",
        ESP_BOX = "Caixas ESP",      TRACERS      = "Rastreadores",
        ESP_NAMES = "Nomes ESP",     ESP_HEALTH   = "Vida ESP",
        KATANA_STATUS = "Status Katana", DISTANCE_ESP = "Distância ESP",
        SKELETON_ESP  = "Esqueleto ESP", HEALTH_BAR   = "Barra de Vida",
        SILENT_AIM    = "Mira Silenciosa", DIR_TITLE  = "Parte do Corpo",
        DIR_HEAD      = "Cabeça",    DIR_CHEST    = "Peito",  DIR_ALL = "Centro",
        HIT_CHANCE_ON = "Chance de Acerto", HIT_CHANCE_VAL = "Percentagem (%)",
        SHOW_FOV      = "Mostrar FOV",  FOV_RADIUS   = "Raio FOV",
        FOV_FILLED    = "FOV Preenchido", PREDICTION = "Previsão",
        PRED_FACTOR   = "Fator Previsão", TRIGGER_BOT = "Gatilho Auto",
        TRIGGER_DELAY = "Delay (ms)",   AIMLOCK      = "Bloqueio de Mira",
        ANTI_KATANA   = "Anti-Katana",  RESOLVER     = "Resolver",
        RESOLVER_MODE = "Modo Resolver", ANTI_LOCK   = "Anti-Bloqueio",
        ANTI_AIM      = "Anti-Aim",     FAKE_LAG     = "Fake Lag",
        RES_AUTO      = "Automático",   RES_BRUTE    = "Força Bruta",
        RES_STATIC    = "Estático",
        MOD_SPEED     = "Modificar Velocidade", WALK_SPEED = "Velocidade",
        MOD_JUMP      = "Modificar Salto",  JUMP_POWER  = "Potência do Salto",
        FLY_ON        = "Voar",         FLY_SPEED    = "Velocidade de Voo",
        NOCLIP        = "No-Clip",      INF_JUMP     = "Salto Infinito",
        BHOP          = "Bunny Hop",
        SAVE_CFG      = "Salvar Config", LOAD_CFG    = "Carregar Config",
        AUTO_LOAD     = "Auto Carregar", PERF_MODE   = "Modo Desempenho",
        PIN_BTN       = "Fixar Botão",   HIDE_BTN    = "Ocultar Botão",
        LANG_TITLE    = "Idioma",        WATERMARK   = "Marca d'Água",
    },
    ["Ruso"] = {
        TAB_VISUALS  = "ВИЗУАЛЫ",  TAB_COMBAT   = "БОЙ",
        TAB_MISTIC   = "МИСТИКА", TAB_MOVEMENT = "ДВИЖЕНИЕ",
        TAB_SETTINGS = "НАСТРОЙКИ",
        ESP_BOX = "ESP Коробки",   TRACERS      = "Трейсеры",
        ESP_NAMES = "Имена ESP",   ESP_HEALTH   = "Здоровье ESP",
        KATANA_STATUS = "Статус Катаны", DISTANCE_ESP = "Дистанция ESP",
        SKELETON_ESP  = "Скелет ESP",    HEALTH_BAR   = "Полоса Здоровья",
        SILENT_AIM    = "Тихий Аим",   DIR_TITLE    = "Часть Тела",
        DIR_HEAD      = "Голова",      DIR_CHEST    = "Грудь", DIR_ALL = "Центр",
        HIT_CHANCE_ON = "Шанс Попадания", HIT_CHANCE_VAL = "Процент (%)",
        SHOW_FOV      = "Показать FOV", FOV_RADIUS  = "Радиус FOV",
        FOV_FILLED    = "Заполненный FOV", PREDICTION = "Предсказание",
        PRED_FACTOR   = "Коэф. Предсказания", TRIGGER_BOT = "Автоспуск",
        TRIGGER_DELAY = "Задержка (мс)",    AIMLOCK    = "Захват Прицела",
        ANTI_KATANA   = "Анти-Катана",  RESOLVER    = "Резольвер",
        RESOLVER_MODE = "Режим Резольвера", ANTI_LOCK = "Анти-Захват",
        ANTI_AIM      = "Анти-Аим",    FAKE_LAG    = "Имитация Лага",
        RES_AUTO      = "Авто",        RES_BRUTE   = "Перебор",
        RES_STATIC    = "Статика",
        MOD_SPEED     = "Изменить Скорость", WALK_SPEED = "Скорость Ходьбы",
        MOD_JUMP      = "Изменить Прыжок",  JUMP_POWER = "Сила Прыжка",
        FLY_ON        = "Полёт",        FLY_SPEED   = "Скорость Полёта",
        NOCLIP        = "Нет-Клип",     INF_JUMP    = "Бесконечный Прыжок",
        BHOP          = "Банни Хоп",
        SAVE_CFG      = "Сохранить",    LOAD_CFG    = "Загрузить",
        AUTO_LOAD     = "Автозагрузка", PERF_MODE   = "Производительность",
        PIN_BTN       = "Закрепить",    HIDE_BTN    = "Скрыть",
        LANG_TITLE    = "Язык",         WATERMARK   = "Водяной Знак",
    },
    ["Pastún"] = {
        TAB_VISUALS = "لیدونه", TAB_COMBAT = "جګړه", TAB_MISTIC = "صوفیانه",
        TAB_MOVEMENT = "حرکت", TAB_SETTINGS = "تنظیمات",
        ESP_BOX = "ESP بکسونه", TRACERS = "تعقیبونکي", ESP_NAMES = "نومونه ESP",
        ESP_HEALTH = "روغتیا ESP", KATANA_STATUS = "د کټانا حالت",
        DISTANCE_ESP = "واټن ESP", SKELETON_ESP = "سکیلیټن ESP",
        HEALTH_BAR = "د روغتیا بار",
        SILENT_AIM = "خاموش هدف", DIR_TITLE = "د جسم برخه",
        DIR_HEAD = "سر", DIR_CHEST = "سینه", DIR_ALL = "مرکز",
        HIT_CHANCE_ON = "د وهلو چانس", HIT_CHANCE_VAL = "سلنه (%)",
        SHOW_FOV = "FOV وښایاست", FOV_RADIUS = "د FOV شعاع",
        FOV_FILLED = "ډک FOV", PREDICTION = "وړاندوینه",
        PRED_FACTOR = "د وړاندوینې فکتور", TRIGGER_BOT = "اتوماتیک ټریګر",
        TRIGGER_DELAY = "ځنډ (ms)", AIMLOCK = "د نښه کولو بندول",
        ANTI_KATANA = "انټي-کټانا", RESOLVER = "حل کوونکی",
        RESOLVER_MODE = "د حل کوونکی حالت", ANTI_LOCK = "انټي-لاک",
        ANTI_AIM = "انټي-ایم", FAKE_LAG = "جعلي لاګ",
        RES_AUTO = "اتوماتیک", RES_BRUTE = "ځواک", RES_STATIC = "ثابت",
        MOD_SPEED = "سرعت بدل کړئ", WALK_SPEED = "د تګ سرعت",
        MOD_JUMP = "لوبه بدله کړئ", JUMP_POWER = "د لوبې ځواک",
        FLY_ON = "الوتنه", FLY_SPEED = "د الوتنې سرعت",
        NOCLIP = "نو-کلیپ", INF_JUMP = "بې پایه لوبه", BHOP = "بني هاپ",
        SAVE_CFG = "خوندي کړئ", LOAD_CFG = "بار کړئ",
        AUTO_LOAD = "اتومات بار", PERF_MODE = "فعالیت حالت",
        PIN_BTN = "پن کړئ", HIDE_BTN = "پټ کړئ",
        LANG_TITLE = "ژبه", WATERMARK = "اوبو نښه",
    },
}

--[[ Lista de elementos UI que reciben traducciones automáticas.
     Cada entry tiene: la instancia, el tipo de binding, la key
     de diccionario, y datos extra (ej. selección de dropdown). ]]
local TranslatingElements: {{UI: Instance, Type: string, Key: string, Extra: any}} = {}

local function RegisterTranslation(inst: Instance, bindType: string, key: string, extra: any?)
    local entry = { UI = inst, Type = bindType, Key = key, Extra = extra or {} }
    table.insert(TranslatingElements, entry)
    -- Aplica la traducción inmediatamente al registrar
    local t = Lang[CurrentLanguage]
    if bindType == "Text" then
        (inst :: TextLabel).Text = t[key] or key
    elseif bindType == "DropdownTitle" then
        local sel = t[entry.Extra.CurrentSelectionKey] or entry.Extra.CurrentSelectionKey or ""
        ;(inst :: TextLabel).Text = (t[key] or key) .. ": " .. sel
    elseif bindType == "DropdownOption" then
        (inst :: TextLabel).Text = "  " .. (t[key] or key)
    end
end

local function UpdateLanguage(newLang: string)
    CurrentLanguage  = newLang
    Config.LANGUAGE  = newLang
    local t = Lang[CurrentLanguage]
    for _, item in ipairs(TranslatingElements) do
        if item.Type == "Text" then
            (item.UI :: TextLabel).Text = t[item.Key] or item.Key
        elseif item.Type == "DropdownTitle" then
            local sel = t[item.Extra.CurrentSelectionKey] or item.Extra.CurrentSelectionKey or ""
            ;(item.UI :: TextLabel).Text = (t[item.Key] or item.Key) .. ": " .. sel
        elseif item.Type == "DropdownOption" then
            (item.UI :: TextLabel).Text = "  " .. (t[item.Key] or item.Key)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 7 ─ BUS DE EVENTOS INTERNO (PubSub)
--  Permite que módulos se comuniquen sin depender el uno del otro.
--  Ejemplo: ESP escucha "PlayerAdded", FlyModule escucha "Respawn"
-- ══════════════════════════════════════════════════════════════════

type EventCallback = (...any) -> ()

local EventBus = {_listeners = {} :: {[string]: {EventCallback}}}

function EventBus:On(event: string, cb: EventCallback)
    if not self._listeners[event] then self._listeners[event] = {} end
    table.insert(self._listeners[event], cb)
end

function EventBus:Fire(event: string, ...: any)
    local listeners = self._listeners[event]
    if listeners then
        for _, cb in ipairs(listeners) do pcall(cb, ...) end
    end
end

function EventBus:Once(event: string, cb: EventCallback)
    local function wrapper(...)
        cb(...)
        -- Se elimina a sí mismo después de la primera llamada
        local listeners = self._listeners[event]
        if listeners then
            for i, fn in ipairs(listeners) do
                if fn == wrapper then table.remove(listeners, i) break end
            end
        end
    end
    self:On(event, wrapper)
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 8 ─ TEMA VISUAL (Design Tokens)
-- ══════════════════════════════════════════════════════════════════

local Theme = {
    -- Paleta de colores
    BG              = Color3.fromRGB(8,  8,  12),
    BG2             = Color3.fromRGB(14, 14, 20),  -- cards
    BG3             = Color3.fromRGB(20, 20, 28),  -- dropdowns
    Accent          = Color3.fromRGB(10, 132, 255),
    AccentGreen     = Color3.fromRGB(48, 209, 88),
    AccentRed       = Color3.fromRGB(255, 69, 58),
    AccentYellow    = Color3.fromRGB(255, 214, 10),
    Text            = Color3.fromRGB(245, 245, 250),
    TextSub         = Color3.fromRGB(155, 155, 165),
    TextDisabled    = Color3.fromRGB(80,  80,  90),
    Border          = Color3.fromRGB(255, 255, 255),
    -- Transparencias
    BGTransp        = 0.25,   -- ventana principal
    CardTransp      = 0.55,   -- tarjetas de componentes
    BorderTransp    = 0.83,
    -- Animaciones
    AnimFast        = 0.15,
    AnimNormal      = 0.28,
    AnimSlow        = 0.45,
    AnimStyle       = Enum.EasingStyle.Quart,
    AnimDir         = Enum.EasingDirection.Out,
}

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 9 ─ UTILIDADES DE UI
-- ══════════════════════════════════════════════════════════════════

--[[ Crea una instancia con propiedades en un solo call.
     El Parent siempre se setea al final para evitar partial-init. ]]
local function New(cls: string, props: {[string]: any}): Instance
    local inst = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" then (inst :: any)[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

--[[ Wrapper de TweenService que respeta el modo rendimiento.
     Si PERF_MODE está activo, aplica los valores instantáneamente. ]]
local function Tween(obj: Instance, props: {[string]: any}, dur: number?, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
    if Config.PERF_MODE then
        -- En modo rendimiento: sin animaciones
        for k, v in pairs(props) do pcall(function() (obj :: any)[k] = v end) end
        return
    end
    local tw = TweenService:Create(obj,
        TweenInfo.new(dur or Theme.AnimNormal, style or Theme.AnimStyle, dir or Theme.AnimDir),
        props)
    tw:Play()
    return tw
end

--[[ Drop shadow usando 9-slice image ]]
local function Shadow(parent: Frame, size: number?, transp: number?)
    size  = size  or 20
    transp = transp or 0.55
    return New("ImageLabel", {
        Parent             = parent,
        Name               = "_Shadow",
        AnchorPoint        = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position           = UDim2.new(0.5, 0, 0.5, size / 2),
        Size               = UDim2.new(1, size * 2, 1, size * 2),
        ZIndex             = (parent.ZIndex or 1) - 1,
        Image              = "rbxassetid://5028857084",
        ImageColor3        = Color3.new(0, 0, 0),
        ImageTransparency  = transp,
        ScaleType          = Enum.ScaleType.Slice,
        SliceCenter        = Rect.new(24, 24, 276, 276),
    })
end

--[[ Actualiza el CanvasSize de un ScrollingFrame automáticamente ]]
local function AutoCanvas(sf: ScrollingFrame)
    local layout = sf:FindFirstChildOfClass("UIListLayout")
    if layout then
        sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end
end

--[[ Redondea un número con N decimales ]]
local function Round(n: number, dec: number?): number
    local f = 10 ^ (dec or 0)
    return math.floor(n * f + 0.5) / f
end

--[[ Obtiene el Humanoid de un personaje de forma segura ]]
local function GetHumanoid(char: Model?): Humanoid?
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

--[[ Convierte tabla {R,G,B} de Config a Color3 ]]
local function CfgColor(t: {number}): Color3
    return Color3.fromRGB(t[1], t[2], t[3])
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 10 ─ SISTEMA DE NOTIFICACIONES (Toast)
--  Muestra mensajes flotantes no-bloqueantes en la esquina.
-- ══════════════════════════════════════════════════════════════════

local NotifContainer = New("Frame", {
    Parent             = ScreenGui,
    Name               = "NotifContainer",
    Size               = UDim2.new(0, 300, 1, -20),
    Position           = UDim2.new(1, -310, 0, 10),
    BackgroundTransparency = 1,
    ZIndex             = 200,
})
New("UIListLayout", {
    Parent         = NotifContainer,
    VerticalAlignment = Enum.VerticalAlignment.Bottom,
    SortOrder      = Enum.SortOrder.LayoutOrder,
    Padding        = UDim.new(0, 6),
})

local notifCount = 0

--[[ type: "info" | "success" | "warn" | "error" ]]
local function Notify(message: string, notifType: string?, duration: number?)
    notifType = notifType or "info"
    duration  = duration  or 3.5
    notifCount += 1

    local accent = (notifType == "success" and Theme.AccentGreen)
                or (notifType == "warn"    and Theme.AccentYellow)
                or (notifType == "error"   and Theme.AccentRed)
                or Theme.Accent

    local icon = (notifType == "success" and "✓")
              or (notifType == "warn"    and "⚠")
              or (notifType == "error"   and "✕")
              or "ℹ"

    local card = New("Frame", {
        Parent             = NotifContainer,
        Size               = UDim2.new(1, 0, 0, 46),
        BackgroundColor3   = Theme.BG2,
        BackgroundTransparency = 0.1,
        ClipsDescendants   = true,
        LayoutOrder        = notifCount,
    })
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
    New("UIStroke",  { Color = accent, Transparency = 0.5, Thickness = 1, Parent = card })

    -- Barra de color izquierda
    New("Frame", {
        Parent           = card,
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
    })

    -- Ícono
    New("TextLabel", {
        Parent              = card,
        Size                = UDim2.new(0, 34, 1, 0),
        Position            = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text                = icon,
        TextColor3          = accent,
        Font                = Enum.Font.GothamBold,
        TextSize            = 18,
    })

    -- Mensaje
    New("TextLabel", {
        Parent              = card,
        Size                = UDim2.new(1, -50, 1, 0),
        Position            = UDim2.new(0, 44, 0, 0),
        BackgroundTransparency = 1,
        Text                = message,
        TextColor3          = Theme.Text,
        Font                = Enum.Font.GothamMedium,
        TextSize            = 12,
        TextXAlignment      = Enum.TextXAlignment.Left,
        TextWrapped         = true,
    })

    -- Barra de progreso (cuenta atrás)
    local progressBG = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = Theme.BG3,
        BorderSizePixel  = 0,
    })
    local progressFill = New("Frame", {
        Parent           = progressBG,
        Size             = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
    })

    -- Animación de entrada (slide desde la derecha)
    card.Position = UDim2.new(1, 10, 0, 0)
    Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, Theme.AnimNormal,
          Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Progreso decreciente
    Tween(progressFill, { Size = UDim2.new(0, 0, 1, 0) }, duration)

    -- Auto-destrucción
    TrackThread(task.delay(duration, function()
        Tween(card, { Position = UDim2.new(1, 10, 0, 0) }, Theme.AnimFast)
        task.delay(Theme.AnimFast + 0.05, function()
            pcall(function() card:Destroy() end)
        end)
    end))
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 11 ─ WATERMARK (Marca de agua superior)
-- ══════════════════════════════════════════════════════════════════

local WatermarkFrame = New("Frame", {
    Parent             = ScreenGui,
    Name               = "Watermark",
    Size               = UDim2.new(0, 220, 0, 28),
    Position           = UDim2.new(0, 12, 0, 12),
    BackgroundColor3   = Theme.BG,
    BackgroundTransparency = 0.2,
    Visible            = Config.SHOW_WATERMARK,
    ZIndex             = 50,
})
New("UICorner", { CornerRadius = UDim.new(0, 6), Parent = WatermarkFrame })
New("UIStroke", { Color = Theme.Accent, Transparency = 0.65, Thickness = 1, Parent = WatermarkFrame })

local WatermarkLabel = New("TextLabel", {
    Parent             = WatermarkFrame,
    Size               = UDim2.new(1, -10, 1, 0),
    Position           = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text               = "LXNDXN v4.0",
    TextColor3         = Theme.Text,
    Font               = Enum.Font.GothamBold,
    TextSize           = 13,
    TextXAlignment     = Enum.TextXAlignment.Left,
    ZIndex             = 51,
})
New("TextLabel", {
    Parent             = WatermarkFrame,
    Size               = UDim2.new(0, 70, 1, 0),
    Position           = UDim2.new(1, -75, 0, 0),
    BackgroundTransparency = 1,
    Text               = "00:00",   -- se actualiza cada segundo
    TextColor3         = Theme.TextSub,
    Font               = Enum.Font.GothamMedium,
    TextSize           = 12,
    TextXAlignment     = Enum.TextXAlignment.Right,
    ZIndex             = 51,
    Name               = "Clock",
})

-- Reloj en tiempo real en el watermark
TrackConnection(RunService.Heartbeat:Connect(function()
    local clock = WatermarkFrame:FindFirstChild("Clock") :: TextLabel?
    if clock then
        clock.Text = os.date("%H:%M:%S") :: string
    end
end))

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 12 ─ CONSTRUCCIÓN DEL MENÚ PRINCIPAL
-- ══════════════════════════════════════════════════════════════════

-- ── 12.1  Botón flotante ──────────────────────────────────────────

local FloatBtn = New("TextButton", {
    Parent             = ScreenGui,
    Name               = "FloatBtn",
    Size               = UDim2.new(0, 54, 0, 54),
    Position           = UDim2.new(0.93, 0, 0.07, 0),
    AnchorPoint        = Vector2.new(0.5, 0.5),
    BackgroundColor3   = Theme.Accent,
    BackgroundTransparency = 0.1,
    Text               = "⚡",
    TextColor3         = Color3.new(1, 1, 1),
    TextScaled         = true,
    Font               = Enum.Font.GothamBold,
    ClipsDescendants   = true,
    ZIndex             = 20,
})
New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FloatBtn })
local FloatStroke = New("UIStroke", {
    Color        = Color3.new(1, 1, 1),
    Transparency = 0.7,
    Thickness    = 1.5,
    Parent       = FloatBtn,
})
Shadow(FloatBtn, 16, 0.4)

-- Pulso del botón flotante
local _pulsing = true
TrackThread(task.spawn(function()
    while _pulsing and FloatBtn.Parent do
        Tween(FloatBtn, { BackgroundTransparency = 0.35 }, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(0.95)
        Tween(FloatBtn, { BackgroundTransparency = 0.08 }, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(0.95)
    end
end))

-- ── 12.2  Ventana principal ───────────────────────────────────────

local MainFrame = New("Frame", {
    Parent             = ScreenGui,
    Name               = "MainFrame",
    Size               = UDim2.new(0, 520, 0, 430),
    Position           = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint        = Vector2.new(0.5, 0.5),
    BackgroundColor3   = Theme.BG,
    BackgroundTransparency = Theme.BGTransp,
    ClipsDescendants   = true,
    Visible            = false,
    ZIndex             = 10,
})
New("UICorner", { CornerRadius = UDim.new(0, 18), Parent = MainFrame })
New("UIStroke", {
    Color        = Theme.Border,
    Transparency = Theme.BorderTransp,
    Thickness    = 1,
    Parent       = MainFrame,
})
Shadow(MainFrame, 35, 0.45)

-- Barra de color superior animada
local TopAccent = New("Frame", {
    Parent           = MainFrame,
    Size             = UDim2.new(0.55, 0, 0, 2),
    Position         = UDim2.new(0.225, 0, 0, 0),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel  = 0,
    ZIndex           = 11,
})
New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TopAccent })
-- Animación de color en la barra superior
TrackThread(task.spawn(function()
    local colors = {Theme.Accent, Theme.AccentGreen, Theme.Accent}
    local i = 1
    while MainFrame.Parent do
        i = (i % #colors) + 1
        Tween(TopAccent, { BackgroundColor3 = colors[i] }, 2, Enum.EasingStyle.Sine)
        task.wait(2.1)
    end
end))

-- ── 12.3  TopBar ─────────────────────────────────────────────────

local TopBar = New("Frame", {
    Parent             = MainFrame,
    Name               = "TopBar",
    Size               = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1,
    ZIndex             = 11,
})

-- Título
New("TextLabel", {
    Parent             = TopBar,
    Size               = UDim2.new(0, 140, 1, 0),
    Position           = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1,
    Text               = "LXNDXN",
    TextColor3         = Theme.Text,
    Font               = Enum.Font.GothamBlack,
    TextSize           = 22,
    TextXAlignment     = Enum.TextXAlignment.Left,
    ZIndex             = 12,
})
New("TextLabel", {
    Parent             = TopBar,
    Size               = UDim2.new(0, 50, 0, 16),
    Position           = UDim2.new(0, 100, 0.5, -4),
    BackgroundTransparency = 1,
    Text               = "v4.0",
    TextColor3         = Theme.Accent,
    Font               = Enum.Font.GothamSemibold,
    TextSize           = 11,
    ZIndex             = 12,
})

-- FPS counter en el topbar
local FpsLabel = New("TextLabel", {
    Parent             = TopBar,
    Size               = UDim2.new(0, 80, 1, 0),
    Position           = UDim2.new(1, -90, 0, 0),
    BackgroundTransparency = 1,
    Text               = "60 FPS",
    TextColor3         = Theme.AccentGreen,
    Font               = Enum.Font.GothamMedium,
    TextSize           = 11,
    TextXAlignment     = Enum.TextXAlignment.Right,
    ZIndex             = 12,
})
-- Actualiza el FPS display
local _fpsSmooth = 60
TrackConnection(RunService.RenderStepped:Connect(function(dt)
    _fpsSmooth = _fpsSmooth * 0.9 + (1 / dt) * 0.1
    local fps   = math.floor(_fpsSmooth)
    local color = fps >= 55 and Theme.AccentGreen
               or fps >= 30 and Theme.AccentYellow
               or Theme.AccentRed
    FpsLabel.Text      = fps .. " FPS"
    FpsLabel.TextColor3 = color
end))

-- ── 12.4  TabBar ─────────────────────────────────────────────────

local TabBar = New("ScrollingFrame", {
    Parent             = MainFrame,
    Name               = "TabBar",
    Size               = UDim2.new(1, -40, 0, 34),
    Position           = UDim2.new(0, 20, 0, 52),
    BackgroundTransparency = 1,
    ScrollBarThickness = 0,
    CanvasSize         = UDim2.new(2, 0, 0, 0),
    ScrollingDirection = Enum.ScrollingDirection.X,
    ZIndex             = 11,
})
New("UIListLayout", {
    Parent        = TabBar,
    FillDirection = Enum.FillDirection.Horizontal,
    SortOrder     = Enum.SortOrder.LayoutOrder,
    Padding       = UDim.new(0, 10),
})

-- ── 12.5  Área de contenido ───────────────────────────────────────

local ContentArea = New("Frame", {
    Parent             = MainFrame,
    Name               = "ContentArea",
    Size               = UDim2.new(1, -40, 1, -106),
    Position           = UDim2.new(0, 20, 0, 98),
    BackgroundTransparency = 1,
    ClipsDescendants   = true,
    ZIndex             = 10,
})

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 13 ─ SISTEMA DE DRAG AVANZADO
--  Soporta mouse y touch. Guarda el offset relativo para
--  que el objeto no "salte" al posición del cursor.
-- ══════════════════════════════════════════════════════════════════

local _buttonFixed = false

local function MakeDraggable(target: GuiObject, handle: GuiObject?)
    handle = handle or target
    local dragging    = false
    local dragInput: InputObject?
    local dragStart: Vector3
    local startPos: UDim2

    local function OnInputBegan(input: InputObject)
        -- El botón flotante no se mueve si está fijado
        if target == FloatBtn and _buttonFixed then return end
        local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
                     or input.UserInputType == Enum.UserInputType.Touch
        if isClick then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            -- Feedback visual al agarrar
            Tween(target, { BackgroundTransparency = (target.BackgroundTransparency or 0) + 0.1 }, Theme.AnimFast)
            TrackConnection(input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Tween(target, { BackgroundTransparency = (target.BackgroundTransparency or 0) - 0.1 }, Theme.AnimFast)
                end
            end))
        end
    end

    local function OnInputChanged(input: InputObject)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end

    TrackConnection((handle :: GuiObject).InputBegan:Connect(OnInputBegan))
    TrackConnection(target.InputChanged:Connect(OnInputChanged))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

MakeDraggable(FloatBtn)
MakeDraggable(MainFrame, TopBar)

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 14 ─ LÓGICA DE APERTURA / CIERRE
-- ══════════════════════════════════════════════════════════════════

local _menuOpen = false

local function SetMenuOpen(open: boolean)
    _menuOpen = open
    if open then
        MainFrame.Visible            = true
        MainFrame.Size               = UDim2.new(0, 520, 0, 0)
        MainFrame.BackgroundTransparency = 1
        Tween(MainFrame, {
            Size                     = UDim2.new(0, 520, 0, 430),
            BackgroundTransparency   = Theme.BGTransp,
        }, Theme.AnimSlow, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        local tw = Tween(MainFrame, {
            Size                     = UDim2.new(0, 520, 0, 0),
            BackgroundTransparency   = 1,
        }, Theme.AnimNormal)
        if tw then
            tw.Completed:Connect(function()
                MainFrame.Visible = false
            end)
        else
            -- PERF_MODE: sin tween
            MainFrame.Visible = false
        end
    end
end

-- Botón flotante
TrackConnection(FloatBtn.MouseButton1Click:Connect(function()
    SetMenuOpen(not _menuOpen)
end))

-- Hotkey INSERT (configurable)
TrackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.KEYBIND_TOGGLE then
        SetMenuOpen(not _menuOpen)
    end
end))

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 15 ─ FÁBRICA DE COMPONENTES UI
-- ══════════════════════════════════════════════════════════════════

local Tabs:      {[string]: {Button: TextButton, Indicator: Frame}} = {}
local TabFrames: {[string]: ScrollingFrame} = {}
local _activeTab: string? = nil

-- ── 15.1  CreateTab ───────────────────────────────────────────────
local function CreateTab(key: string, order: number): ScrollingFrame
    -- Botón del tab
    local btn = New("TextButton", {
        Parent             = TabBar,
        Name               = key,
        Size               = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        TextColor3         = Theme.TextSub,
        Font               = Enum.Font.GothamSemibold,
        TextSize           = 12,
        LayoutOrder        = order,
        ZIndex             = 12,
    }) :: TextButton
    RegisterTranslation(btn, "Text", key)

    -- Indicador subrayado
    local indicator = New("Frame", {
        Parent           = btn,
        Name             = "Indicator",
        Size             = UDim2.new(0, 0, 0, 2),
        Position         = UDim2.new(0.5, 0, 1, -2),
        AnchorPoint      = Vector2.new(0.5, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })

    -- Frame de contenido (ScrollingFrame)
    local frame = New("ScrollingFrame", {
        Parent             = ContentArea,
        Name               = key .. "_Frame",
        Size               = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        Visible            = false,
        ZIndex             = 10,
    }) :: ScrollingFrame
    local layout = New("UIListLayout", {
        Parent    = frame,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 7),
    })
    New("UIPadding", {
        Parent        = frame,
        PaddingTop    = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 10),
    })

    Tabs[key]      = { Button = btn, Indicator = indicator }
    TabFrames[key] = frame

    -- Auto-resize del canvas
    TrackConnection(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        AutoCanvas(frame)
    end))

    -- Clic en el tab
    TrackConnection(btn.MouseButton1Click:Connect(function()
        if _activeTab == key then return end
        for k, data in pairs(Tabs) do
            TabFrames[k].Visible = false
            Tween(data.Button,    { TextColor3 = Theme.TextSub },        Theme.AnimFast)
            Tween(data.Indicator, { Size = UDim2.new(0, 0, 0, 2) },     Theme.AnimFast)
        end
        _activeTab     = key
        frame.Visible  = true
        Tween(btn,       { TextColor3 = Theme.Accent },                  Theme.AnimFast)
        Tween(indicator, { Size = UDim2.new(0.8, 0, 0, 2) }, Theme.AnimNormal,
              Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end))

    return frame
end

-- ── 15.2  CreateSectionLabel ──────────────────────────────────────
local function SectionLabel(parent: ScrollingFrame, text: string, order: number): Frame
    local f = New("Frame", {
        Parent             = parent,
        Size               = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder        = order,
    }) :: Frame
    New("TextLabel", {
        Parent             = f,
        Size               = UDim2.new(1, -10, 1, 0),
        Position           = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Text               = "── " .. text:upper() .. " ──",
        TextColor3         = Theme.Accent,
        Font               = Enum.Font.GothamBold,
        TextSize            = 10,
        TextXAlignment     = Enum.TextXAlignment.Center,
    })
    return f
end

-- ── 15.3  CreateToggle ────────────────────────────────────────────
--  Retorna (Frame, SetFn) donde SetFn(bool, skipCb?) controla el estado.
type SetToggleFn = (state: boolean, skipCb: boolean?) -> ()

local function CreateToggle(
    parent:    ScrollingFrame,
    key:       string,
    callback:  (boolean) -> ()?,
    order:     number
): (Frame, SetToggleFn)

    local card = New("Frame", {
        Parent             = parent,
        Size               = UDim2.new(1, 0, 0, 44),
        BackgroundColor3   = Theme.BG2,
        BackgroundTransparency = Theme.CardTransp,
        LayoutOrder        = order,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })

    -- Punto de estado (verde = on, gris = off)
    local dot = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(0, 6, 0, 6),
        Position         = UDim2.new(0, 10, 0.5, -3),
        BackgroundColor3 = Theme.TextDisabled,
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })

    local lbl = New("TextLabel", {
        Parent             = card,
        Size               = UDim2.new(1, -80, 1, 0),
        Position           = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1,
        TextColor3         = Theme.Text,
        Font               = Enum.Font.GothamMedium,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }) :: TextLabel
    RegisterTranslation(lbl, "Text", key)

    -- Switch track
    local track = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(0, 44, 0, 22),
        Position         = UDim2.new(1, -56, 0.5, -11),
        BackgroundColor3 = Color3.fromRGB(40, 40, 50),
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

    -- Switch knob
    local knob = New("Frame", {
        Parent           = track,
        Size             = UDim2.new(0, 18, 0, 18),
        Position         = UDim2.new(0, 2, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(200, 200, 210),
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    -- Área de clic (más grande, mejor para móvil)
    local clickArea = New("TextButton", {
        Parent             = card,
        Size               = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text               = "",
        ZIndex             = card.ZIndex + 1,
    }) :: TextButton

    local toggled = false

    local function Set(state: boolean, skipCb: boolean?)
        toggled = state
        local offX = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local trackColor = state and Theme.Accent or Color3.fromRGB(40, 40, 50)
        local dotColor   = state and Theme.AccentGreen or Theme.TextDisabled

        Tween(knob,  { Position = offX      },    Theme.AnimFast, Enum.EasingStyle.Back)
        Tween(track, { BackgroundColor3 = trackColor }, Theme.AnimFast)
        Tween(dot,   { BackgroundColor3 = dotColor   }, Theme.AnimFast)

        -- Pop del knob
        Tween(knob, { Size = UDim2.new(0, 20, 0, 20) }, 0.08)
        task.delay(0.1, function() Tween(knob, { Size = UDim2.new(0, 18, 0, 18) }, 0.1) end)

        if not skipCb and callback then
            pcall(callback, state)
        end
    end

    TrackConnection(clickArea.MouseButton1Click:Connect(function()
        Set(not toggled)
    end))

    -- Hover
    TrackConnection(clickArea.MouseEnter:Connect(function()
        Tween(card, { BackgroundTransparency = Theme.CardTransp - 0.1 }, Theme.AnimFast)
    end))
    TrackConnection(clickArea.MouseLeave:Connect(function()
        Tween(card, { BackgroundTransparency = Theme.CardTransp }, Theme.AnimFast)
    end))

    return card, Set
end

-- ── 15.4  CreateSlider ────────────────────────────────────────────
type GetSliderFn = () -> number
type SetSliderFn = (val: number) -> ()

local function CreateSlider(
    parent:   ScrollingFrame,
    key:      string,
    minV:     number,
    maxV:     number,
    default:  number,
    callback: (number) -> ()?,
    order:    number
): (Frame, GetSliderFn, SetSliderFn)

    local card = New("Frame", {
        Parent             = parent,
        Size               = UDim2.new(1, 0, 0, 62),
        BackgroundColor3   = Theme.BG2,
        BackgroundTransparency = Theme.CardTransp,
        LayoutOrder        = order,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })

    local lbl = New("TextLabel", {
        Parent             = card,
        Size               = UDim2.new(1, -80, 0, 20),
        Position           = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        TextColor3         = Theme.Text,
        Font               = Enum.Font.GothamMedium,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }) :: TextLabel
    RegisterTranslation(lbl, "Text", key)

    local valLbl = New("TextLabel", {
        Parent             = card,
        Size               = UDim2.new(0, 60, 0, 20),
        Position           = UDim2.new(1, -70, 0, 6),
        BackgroundTransparency = 1,
        Text               = tostring(default),
        TextColor3         = Theme.Accent,
        Font               = Enum.Font.GothamBold,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Right,
    }) :: TextLabel

    -- Track
    local trackFrame = New("Frame", {
        Parent           = card,
        Size             = UDim2.new(1, -28, 0, 6),
        Position         = UDim2.new(0, 14, 0, 36),
        BackgroundColor3 = Color3.fromRGB(38, 38, 50),
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackFrame })

    -- Fill con gradiente
    local fill = New("Frame", {
        Parent           = trackFrame,
        Size             = UDim2.new((default - minV)/(maxV - minV), 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
    New("UIGradient", {
        Parent   = fill,
        Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentGreen),
        }),
    })

    -- Knob
    local knob = New("Frame", {
        Parent           = fill,
        Size             = UDim2.new(0, 16, 0, 16),
        Position         = UDim2.new(1, -8, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel  = 0,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
    New("UIStroke",  { Color = Theme.Accent, Transparency = 0.4, Thickness = 2, Parent = knob })

    local current  = default
    local dragging = false

    local function Refresh(inputX: number)
        local rel  = math.clamp((inputX - trackFrame.AbsolutePosition.X) / trackFrame.AbsoluteSize.X, 0, 1)
        current    = Round(minV + (maxV - minV) * rel)
        fill.Size  = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(current)
        if callback then pcall(callback, current) end
    end

    local function SetValue(val: number)
        val     = math.clamp(val, minV, maxV)
        current = val
        local rel = (val - minV) / (maxV - minV)
        fill.Size   = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(val)
        if callback then pcall(callback, val) end
    end

    TrackConnection(trackFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Refresh(input.Position.X)
            Tween(knob, { Size = UDim2.new(0, 19, 0, 19) }, 0.08)
        end
    end))
    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then Refresh(input.Position.X) end
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            Tween(knob, { Size = UDim2.new(0, 16, 0, 16) }, 0.1)
        end
    end))

    return card, function() return current end, SetValue
end

-- ── 15.5  CreateDropdown ──────────────────────────────────────────
local function CreateDropdown(
    parent:   ScrollingFrame,
    titleKey: string,
    optKeys:  {string},
    defKey:   string,
    callback: (string) -> ()?,
    order:    number
): Frame

    local ROW_H    = 30
    local CLOSED_H = 44
    local OPEN_H   = CLOSED_H + #optKeys * ROW_H

    local card = New("Frame", {
        Parent             = parent,
        Size               = UDim2.new(1, 0, 0, CLOSED_H),
        BackgroundColor3   = Theme.BG2,
        BackgroundTransparency = Theme.CardTransp,
        ClipsDescendants   = true,
        LayoutOrder        = order,
    }) :: Frame
    New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })

    local titleLbl = New("TextLabel", {
        Parent             = card,
        Size               = UDim2.new(1, -55, 0, CLOSED_H),
        Position           = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        TextColor3         = Theme.Text,
        Font               = Enum.Font.GothamMedium,
        TextSize           = 13,
        TextXAlignment     = Enum.TextXAlignment.Left,
    }) :: TextLabel
    local extra = { CurrentSelectionKey = defKey }
    RegisterTranslation(titleLbl, "DropdownTitle", titleKey, extra)

    local arrow = New("TextLabel", {
        Parent             = card,
        Size               = UDim2.new(0, 24, 0, 24),
        Position           = UDim2.new(1, -32, 0, 10),
        BackgroundTransparency = 1,
        Text               = "▾",
        TextColor3         = Theme.TextSub,
        Font               = Enum.Font.GothamBold,
        TextSize           = 16,
    }) :: TextLabel

    local optContainer = New("Frame", {
        Parent             = card,
        Size               = UDim2.new(1, 0, 1, -CLOSED_H),
        Position           = UDim2.new(0, 0, 0, CLOSED_H),
        BackgroundTransparency = 1,
    })
    New("UIListLayout", { Parent = optContainer, SortOrder = Enum.SortOrder.LayoutOrder })

    local isOpen = false

    -- Botón que abre/cierra
    local toggleBtn = New("TextButton", {
        Parent             = card,
        Size               = UDim2.new(1, 0, 0, CLOSED_H),
        BackgroundTransparency = 1,
        Text               = "",
        ZIndex             = card.ZIndex + 2,
    }) :: TextButton

    TrackConnection(toggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        Tween(card,  { Size = UDim2.new(1, 0, 0, isOpen and OPEN_H or CLOSED_H) }, Theme.AnimNormal)
        Tween(arrow, { Rotation = isOpen and 180 or 0 }, Theme.AnimNormal)
    end))

    -- Opciones
    for i, optKey in ipairs(optKeys) do
        local optBtn = New("TextButton", {
            Parent             = optContainer,
            Size               = UDim2.new(1, 0, 0, ROW_H),
            BackgroundColor3   = Theme.BG3,
            BackgroundTransparency = 0.25,
            TextColor3         = Theme.TextSub,
            Font               = Enum.Font.Gotham,
            TextSize           = 12,
            TextXAlignment     = Enum.TextXAlignment.Left,
            LayoutOrder        = i,
            ZIndex             = card.ZIndex + 3,
        }) :: TextButton
        RegisterTranslation(optBtn, "DropdownOption", optKey)

        TrackConnection(optBtn.MouseEnter:Connect(function()
            Tween(optBtn, { BackgroundTransparency = 0.0, TextColor3 = Theme.Text }, Theme.AnimFast)
        end))
        TrackConnection(optBtn.MouseLeave:Connect(function()
            Tween(optBtn, { BackgroundTransparency = 0.25, TextColor3 = Theme.TextSub }, Theme.AnimFast)
        end))

        TrackConnection(optBtn.MouseButton1Click:Connect(function()
            extra.CurrentSelectionKey = optKey
            titleLbl.Text = (Lang[CurrentLanguage][titleKey] or titleKey)
                          .. ": " .. (Lang[CurrentLanguage][optKey] or optKey)
            isOpen = false
            Tween(card,  { Size = UDim2.new(1, 0, 0, CLOSED_H) }, Theme.AnimNormal)
            Tween(arrow, { Rotation = 0 }, Theme.AnimNormal)
            if callback then pcall(callback, optKey) end
        end))
    end

    return card
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 16 ─ MÓDULOS DE FUNCIONALIDAD
-- ══════════════════════════════════════════════════════════════════

-- ── 16.1  UTILIDAD: Obtener objetivo más cercano al centro ────────
local function GetClosestTarget(radiusPx: number?): (Player?, number)
    radiusPx = radiusPx or Config.FOV_RADIUS
    local best:     Player? = nil
    local bestDist: number  = math.huge
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end

        local partName = Config.SILENT_AIM_PART or "Head"
        local part     = char:FindFirstChild(partName)
                      or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local hum = GetHumanoid(char)
        if not hum or hum.Health <= 0 then continue end

        local sp, onScreen = Camera:WorldToViewportPoint((part :: BasePart).Position)
        if onScreen then
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d < (radiusPx :: number) and d < bestDist then
                bestDist = d
                best     = player
            end
        end
    end
    return best, bestDist
end

-- ── 16.2  MÓDULO ESP ─────────────────────────────────────────────
local ESP = {
    BoxEnabled    = false,
    TracerEnabled = false,
    NamesEnabled  = false,
    HealthEnabled = false,
    DistEnabled   = false,
    -- Almacenes de instancias
    Highlights    = {} :: {[Player]: Highlight},
    TracerLines   = {} :: {[Player]: any},  -- Drawing.Line
    NameBBs       = {} :: {[Player]: BillboardGui},
    HealthBBs     = {} :: {[Player]: BillboardGui},
    DistBBs       = {} :: {[Player]: BillboardGui},
}

-- Crea / actualiza un Highlight ESP para un personaje
local function ESP_MakeHighlight(player: Player, char: Model)
    if ESP.Highlights[player] then pcall(function() ESP.Highlights[player]:Destroy() end) end
    local hl            = Instance.new("Highlight")
    hl.FillColor        = CfgColor(Config.ESP_BOX_COLOR_FILL)
    hl.OutlineColor     = CfgColor(Config.ESP_BOX_COLOR_OUT)
    hl.FillTransparency = 0.65
    hl.OutlineTransparency = 0.0
    hl.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee          = char
    hl.Parent           = char
    ESP.Highlights[player] = hl
end

function ESP.StartBoxes()
    ESP.BoxEnabled = true
    local function Apply(p: Player)
        if p == LocalPlayer then return end
        if p.Character then ESP_MakeHighlight(p, p.Character) end
        TrackConnection(p.CharacterAdded:Connect(function(c)
            task.wait(0.1)
            if ESP.BoxEnabled then ESP_MakeHighlight(p, c) end
        end))
    end
    for _, p in ipairs(Players:GetPlayers()) do Apply(p) end
    TrackConnection(Players.PlayerAdded:Connect(Apply))
    TrackConnection(Players.PlayerRemoving:Connect(function(p)
        if ESP.Highlights[p] then
            pcall(function() ESP.Highlights[p]:Destroy() end)
            ESP.Highlights[p] = nil
        end
    end))
end

function ESP.StopBoxes()
    ESP.BoxEnabled = false
    for p, hl in pairs(ESP.Highlights) do
        pcall(function() hl:Destroy() end)
        ESP.Highlights[p] = nil
    end
end

-- Tracers usando Drawing API del ejecutor
local _tracerLoop: RBXScriptConnection?

function ESP.StartTracers()
    ESP.TracerEnabled = true
    -- Limpia anteriores
    for _, line in pairs(ESP.TracerLines) do pcall(function() line:Remove() end) end
    table.clear(ESP.TracerLines)

    local function MakeLine(p: Player)
        if p == LocalPlayer then return end
        local line = Drawing.new("Line")
        TrackDrawing(line)
        line.Color       = CfgColor(Config.TRACER_COLOR)
        line.Thickness   = 1.5
        line.Transparency = 0.85
        line.Visible     = false
        ESP.TracerLines[p] = line
    end

    for _, p in ipairs(Players:GetPlayers()) do MakeLine(p) end
    TrackConnection(Players.PlayerAdded:Connect(MakeLine))

    if _tracerLoop then _tracerLoop:Disconnect() end
    _tracerLoop = TrackConnection(RunService.RenderStepped:Connect(function()
        if not ESP.TracerEnabled then return end
        local vp     = Camera.ViewportSize
        local origin = Vector2.new(vp.X / 2, vp.Y)  -- centro inferior de pantalla

        for _, player in ipairs(Players:GetPlayers()) do
            local line = ESP.TracerLines[player]
            if not line then continue end
            if player == LocalPlayer or not player.Character then
                line.Visible = false; continue
            end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not hrp then line.Visible = false; continue end
            local hum = GetHumanoid(player.Character)
            if not hum or hum.Health <= 0 then line.Visible = false; continue end

            local sp, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen then
                line.From    = origin
                line.To      = Vector2.new(sp.X, sp.Y)
                line.Color   = CfgColor(Config.TRACER_COLOR)  -- color actualizable en tiempo real
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end))
end

function ESP.StopTracers()
    ESP.TracerEnabled = false
    if _tracerLoop then _tracerLoop:Disconnect() _tracerLoop = nil end
    for p, line in pairs(ESP.TracerLines) do
        pcall(function() line:Remove() end)
        ESP.TracerLines[p] = nil
    end
end

-- Nombres
local function ESP_MakeName(player: Player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head") :: BasePart?
    if not head then return end
    if player.Character:FindFirstChild("_LXN_Name") then return end

    local bb         = Instance.new("BillboardGui")
    bb.Name          = "_LXN_Name"
    bb.Size          = UDim2.new(0, 180, 0, 36)
    bb.Adornee       = head
    bb.AlwaysOnTop   = true
    bb.StudsOffset   = Vector3.new(0, 2.8, 0)
    bb.MaxDistance   = 250
    -- Sombra de texto
    local shadow     = Instance.new("TextLabel", bb)
    shadow.Size      = UDim2.new(1,0,1,0)
    shadow.Position  = UDim2.new(0,1,0,1)
    shadow.BackgroundTransparency = 1
    shadow.TextColor3 = Color3.new(0,0,0)
    shadow.Text      = player.Name
    shadow.Font      = Enum.Font.GothamBold
    shadow.TextSize  = 15
    -- Texto principal
    local txt        = Instance.new("TextLabel", bb)
    txt.Size         = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.TextColor3   = Color3.new(1,1,1)
    txt.Text         = player.Name
    txt.Font         = Enum.Font.GothamBold
    txt.TextSize     = 15
    bb.Parent        = head
    ESP.NameBBs[player] = bb
end

function ESP.StartNames()
    ESP.NamesEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do ESP_MakeName(p) end
    TrackConnection(Players.PlayerAdded:Connect(function(p)
        TrackConnection(p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.NamesEnabled then ESP_MakeName(p) end
        end))
    end))
end
function ESP.StopNames()
    ESP.NamesEnabled = false
    for p, bb in pairs(ESP.NameBBs) do
        pcall(function() bb:Destroy() end)
        ESP.NameBBs[p] = nil
    end
end

-- Salud con barra dinámica de color
local function ESP_MakeHealth(player: Player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head") :: BasePart?
    local hum  = GetHumanoid(player.Character)
    if not head or not hum then return end
    if player.Character:FindFirstChild("_LXN_Health") then return end

    local bb         = Instance.new("BillboardGui")
    bb.Name          = "_LXN_Health"
    bb.Size          = UDim2.new(0, 90, 0, 16)
    bb.Adornee       = head
    bb.AlwaysOnTop   = true
    bb.StudsOffset   = Vector3.new(0, 4.4, 0)
    bb.MaxDistance   = 180
    -- Fondo de la barra
    local bg         = Instance.new("Frame", bb)
    bg.Size          = UDim2.new(1,0,0.5,0)
    bg.Position      = UDim2.new(0,0,0.25,0)
    bg.BackgroundColor3 = Color3.fromRGB(20,20,20)
    bg.BorderSizePixel  = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)
    -- Fill dinámico
    local pct        = hum.Health / hum.MaxHealth
    local barFill    = Instance.new("Frame", bg)
    barFill.Size     = UDim2.new(pct, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(
        math.floor(255 * (1 - pct)), math.floor(255 * pct), 40)
    barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(1,0)
    -- Texto
    local txt        = Instance.new("TextLabel", bb)
    txt.Size         = UDim2.new(1,0,0.5,0)
    txt.BackgroundTransparency = 1
    txt.TextColor3   = Color3.new(1,1,1)
    txt.Text         = math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)
    txt.Font         = Enum.Font.GothamBold
    txt.TextScaled   = true
    bb.Parent        = head
    ESP.HealthBBs[player] = bb

    -- Listener de vida en tiempo real
    TrackConnection(hum.HealthChanged:Connect(function(hp)
        if not ESP.HealthEnabled then return end
        local p2    = hp / hum.MaxHealth
        barFill.Size = UDim2.new(p2, 0, 1, 0)
        barFill.BackgroundColor3 = Color3.fromRGB(
            math.floor(255 * (1 - p2)), math.floor(255 * p2), 40)
        txt.Text = math.floor(hp).."/"..math.floor(hum.MaxHealth)
    end))
end

function ESP.StartHealth()
    ESP.HealthEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do ESP_MakeHealth(p) end
    TrackConnection(Players.PlayerAdded:Connect(function(p)
        TrackConnection(p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.HealthEnabled then ESP_MakeHealth(p) end
        end))
    end))
end
function ESP.StopHealth()
    ESP.HealthEnabled = false
    for p, bb in pairs(ESP.HealthBBs) do
        pcall(function() bb:Destroy() end)
        ESP.HealthBBs[p] = nil
    end
end

-- Distancia ESP
local _distLoop: RBXScriptConnection?

function ESP.StartDistance()
    ESP.DistEnabled = true
    local function MakeDist(player: Player)
        if player == LocalPlayer then return end
        if not player.Character then return end
        local head = player.Character:FindFirstChild("Head") :: BasePart?
        if not head then return end
        if player.Character:FindFirstChild("_LXN_Dist") then return end

        local bb       = Instance.new("BillboardGui")
        bb.Name        = "_LXN_Dist"
        bb.Size        = UDim2.new(0, 80, 0, 20)
        bb.Adornee     = head
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 6, 0)
        bb.MaxDistance = 500
        local lbl      = Instance.new("TextLabel", bb)
        lbl.Size       = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Theme.AccentYellow
        lbl.Font       = Enum.Font.GothamBold
        lbl.TextSize   = 12
        bb.Parent      = head
        ESP.DistBBs[player] = bb
    end

    for _, p in ipairs(Players:GetPlayers()) do MakeDist(p) end

    -- Actualiza distancia cada frame
    if _distLoop then _distLoop:Disconnect() end
    _distLoop = TrackConnection(RunService.Heartbeat:Connect(function()
        if not ESP.DistEnabled then return end
        local localChar = LocalPlayer.Character
        local localHRP  = localChar and localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
        for player, bb in pairs(ESP.DistBBs) do
            if not bb.Parent then ESP.DistBBs[player] = nil; continue end
            local char = player.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if hrp and localHRP then
                local dist = Round((hrp.Position - localHRP.Position).Magnitude)
                local lbl  = bb:FindFirstChildOfClass("TextLabel")
                if lbl then (lbl :: TextLabel).Text = dist.."m" end
            end
        end
    end))
end

function ESP.StopDistance()
    ESP.DistEnabled = false
    if _distLoop then _distLoop:Disconnect() _distLoop = nil end
    for p, bb in pairs(ESP.DistBBs) do
        pcall(function() bb:Destroy() end)
        ESP.DistBBs[p] = nil
    end
end

-- ── 16.3  MÓDULO FOV CIRCLE ───────────────────────────────────────
local _fovCircle: any?   -- Drawing.Circle
local _fovLoop:   RBXScriptConnection?

local function FOV_Start()
    if _fovCircle then pcall(function() _fovCircle:Remove() end) end
    local c          = Drawing.new("Circle")
    TrackDrawing(c)
    c.NumSides       = 64
    c.Color          = Color3.new(1, 1, 1)
    c.Thickness      = 1.2
    c.Transparency   = 0.8
    c.Filled         = Config.FOV_FILLED
    c.Visible        = true
    _fovCircle       = c

    if _fovLoop then _fovLoop:Disconnect() end
    _fovLoop = TrackConnection(RunService.RenderStepped:Connect(function()
        if not Config.SHOW_FOV or not _fovCircle then return end
        _fovCircle.Radius   = Config.FOV_RADIUS
        _fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        _fovCircle.Filled   = Config.FOV_FILLED
        -- Color dinámico: rojo si hay objetivo dentro del FOV
        local tgt, _ = GetClosestTarget()
        _fovCircle.Color = tgt and Color3.fromRGB(255,80,80) or Color3.new(1,1,1)
    end))
end

local function FOV_Stop()
    if _fovLoop then _fovLoop:Disconnect() _fovLoop = nil end
    if _fovCircle then pcall(function() _fovCircle:Remove() end) _fovCircle = nil end
end

-- ── 16.4  MÓDULO SILENT AIM  [LÓGICA DE EJEMPLO] ─────────────────
--[[
    El Silent Aim real requiere hookear la función de cálculo
    de raycast o de dirección de disparo del juego específico.
    Eso varía de juego a juego. La arquitectura correcta sería:

    1. Identificar la función del gun system que calcula el
       origen y dirección del raycast de disparo.
    2. Usar el hook del ejecutor (hookfunction/detour) para
       interceptarla y redirigir la dirección al objetivo
       seleccionado por GetClosestTarget().
    3. Aplicar HIT_CHANCE_VAL: generar math.random(1,100) y
       solo redirigir si el número es <= HIT_CHANCE_VAL.
    4. Aplicar PREDICTION: sumar la velocidad predicha del
       objetivo * PREDICTION_FACTOR al punto de impacto.

    Ejemplo arquitectural (no ejecutable tal cual):
--]]
local SilentAim = { Active = false }

function SilentAim.Enable()
    SilentAim.Active = true
    --[[  EJEMPLO DE HOOK (requiere ejecutor con hookfunction):
    local oldFunc = hookfunction(GunModule.GetRayDirection, function(origin, ...)
        if not SilentAim.Active then return oldFunc(origin, ...) end

        -- Hit chance: si el número aleatorio supera el umbral, falla
        if Config.HIT_CHANCE_ON and math.random(1,100) > Config.HIT_CHANCE_VAL then
            return oldFunc(origin, ...)
        end

        local target, _ = GetClosestTarget(Config.FOV_RADIUS)
        if not target or not target.Character then return oldFunc(origin, ...) end

        local part = target.Character:FindFirstChild(Config.SILENT_AIM_PART)
                  or target.Character:FindFirstChild("HumanoidRootPart")
        if not part then return oldFunc(origin, ...) end

        -- Predicción de movimiento
        local targetPos = (part :: BasePart).Position
        if Config.PREDICTION then
            local vel = part:IsA("BasePart") and (part :: BasePart).AssemblyLinearVelocity or Vector3.zero
            targetPos = targetPos + vel * Config.PREDICTION_FACTOR
        end

        return (targetPos - origin).Unit
    end)
    ]]
    print("[LXNDXN SilentAim] Activado — modo demostración")
end

function SilentAim.Disable()
    SilentAim.Active = false
    print("[LXNDXN SilentAim] Desactivado")
end

-- ── 16.5  MÓDULO TRIGGER BOT  [LÓGICA DE EJEMPLO] ────────────────
--[[
    El Trigger Bot real simula un click de ratón cuando el
    cursor está sobre un enemigo. En Roblox esto requiere
    simular el input o disparar la función del arma directamente.
--]]
local TriggerBot = { Active = false, _thread = nil :: thread? }

function TriggerBot.Enable()
    TriggerBot.Active = true
    TriggerBot._thread = TrackThread(task.spawn(function()
        while TriggerBot.Active do
            task.wait(0.05)
            local target, dist = GetClosestTarget(20)  -- 20px de tolerancia central
            if target then
                task.wait(Config.TRIGGER_DELAY / 1000)  -- delay configurable en ms
                if TriggerBot.Active then
                    --[[  EJEMPLO: en un juego real harías:
                        mouse:Button1Down()
                        task.wait(0.04)
                        mouse:Button1Up()
                    ]]
                    -- EventBus:Fire("TriggerBot_Fire", target)  ← para módulos que escuchen
                end
            end
        end
    end))
end

function TriggerBot.Disable()
    TriggerBot.Active = false
    if TriggerBot._thread then
        pcall(function() task.cancel(TriggerBot._thread) end)
        TriggerBot._thread = nil
    end
end

-- ── 16.6  MÓDULO VUELO (Implementación real) ──────────────────────
local FlyModule = {
    Active   = false,
    _bv      = nil :: BodyVelocity?,
    _bg      = nil :: BodyGyro?,
    _loop    = nil :: RBXScriptConnection?,
}

function FlyModule.Enable()
    FlyModule.Active = true
    local char = LocalPlayer.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local hum  = GetHumanoid(char)
    if not hrp then return end

    if hum then hum.PlatformStand = true end

    local bv        = Instance.new("BodyVelocity")
    bv.Velocity     = Vector3.zero
    bv.MaxForce     = Vector3.new(1e9, 1e9, 1e9)
    bv.P            = 9999
    bv.Parent       = hrp
    FlyModule._bv   = bv

    local bg        = Instance.new("BodyGyro")
    bg.MaxTorque    = Vector3.new(1e9, 1e9, 1e9)
    bg.P            = 9999
    bg.D            = 100
    bg.Parent       = hrp
    FlyModule._bg   = bg

    local UIS = UserInputService
    if FlyModule._loop then FlyModule._loop:Disconnect() end
    FlyModule._loop = TrackConnection(RunService.RenderStepped:Connect(function()
        if not FlyModule.Active then return end
        local speed   = Config.FLY_SPEED
        local camCF   = Camera.CFrame
        local vel     = Vector3.zero
        local isShift = UIS:IsKeyDown(Enum.KeyCode.LeftShift)
        local mult    = isShift and 2 or 1   -- Shift = velocidad doble

        if UIS:IsKeyDown(Enum.KeyCode.W) then vel += camCF.LookVector  * speed * mult end
        if UIS:IsKeyDown(Enum.KeyCode.S) then vel -= camCF.LookVector  * speed * mult end
        if UIS:IsKeyDown(Enum.KeyCode.A) then vel -= camCF.RightVector * speed * mult end
        if UIS:IsKeyDown(Enum.KeyCode.D) then vel += camCF.RightVector * speed * mult end
        if UIS:IsKeyDown(Enum.KeyCode.Space)       then vel += Vector3.new(0, speed * mult, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel -= Vector3.new(0, speed * mult, 0) end

        bv.Velocity = vel
        bg.CFrame   = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end))
end

function FlyModule.Disable()
    FlyModule.Active = false
    if FlyModule._loop then FlyModule._loop:Disconnect() FlyModule._loop = nil end
    if FlyModule._bv   then pcall(function() FlyModule._bv:Destroy()  end) FlyModule._bv  = nil end
    if FlyModule._bg   then pcall(function() FlyModule._bg:Destroy()  end) FlyModule._bg  = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = GetHumanoid(char)
        if hum then hum.PlatformStand = false end
    end
end

-- ── 16.7  SALTO INFINITO ──────────────────────────────────────────
local _infJumpConn: RBXScriptConnection?

local function InfJump_Start()
    if _infJumpConn then _infJumpConn:Disconnect() end
    _infJumpConn = TrackConnection(UserInputService.JumpRequest:Connect(function()
        if not Config.INF_JUMP then return end
        local char = LocalPlayer.Character
        local hum  = GetHumanoid(char)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

local function InfJump_Stop()
    if _infJumpConn then _infJumpConn:Disconnect() _infJumpConn = nil end
end

-- ── 16.8  BUNNY HOP ───────────────────────────────────────────────
local _bhopConn: RBXScriptConnection?

local function BHop_Start()
    if _bhopConn then _bhopConn:Disconnect() end
    _bhopConn = TrackConnection(RunService.Heartbeat:Connect(function()
        if not Config.BHOP then return end
        local char = LocalPlayer.Character
        local hum  = GetHumanoid(char)
        if not hum then return end
        -- Si el jugador mantiene Space y toca el suelo, vuelve a saltar
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)
        and hum:GetState() == Enum.HumanoidStateType.Landed then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))
end

local function BHop_Stop()
    if _bhopConn then _bhopConn:Disconnect() _bhopConn = nil end
end

-- ── 16.9  NOCLIP  [LÓGICA DE EJEMPLO] ────────────────────────────
--[[
    El NoClip real desactiva la colisión del personaje con el mundo.
    La forma más limpia es usar LoopTask sobre los BaseParts del char
    y desactivar CanCollide, pero eso puede ser detectado por el servidor.
    En muchos ejecutores existe la función noclip() directamente.

    EJEMPLO arquitectural:
--]]
local NoClip = { Active = false, _loop = nil :: RBXScriptConnection? }

function NoClip.Enable()
    NoClip.Active = true
    if NoClip._loop then NoClip._loop:Disconnect() end
    NoClip._loop = TrackConnection(RunService.Stepped:Connect(function()
        if not NoClip.Active then return end
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end))
end

function NoClip.Disable()
    NoClip.Active = false
    if NoClip._loop then NoClip._loop:Disconnect() NoClip._loop = nil end
    -- Restaurar colisión
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- ── 16.10 ANTI-KATANA  [LÓGICA DE EJEMPLO] ───────────────────────
--[[
    Detecta animaciones de katana de jugadores cercanos y ejecuta
    una acción de evasión. La ID de la animación depende del juego.
--]]
local AntiKatana = { Active = false, _thread = nil :: thread? }
local KATANA_ANIM_IDS = {  -- IDs de ejemplo; reemplazar con las del juego
    "rbxassetid://000000001",
    "rbxassetid://000000002",
}

function AntiKatana.Enable()
    AntiKatana.Active = true
    AntiKatana._thread = TrackThread(task.spawn(function()
        while AntiKatana.Active do
            task.wait(0.08)
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char = player.Character
                if not char then continue end
                local animator = char:FindFirstChildOfClass("Animator") :: Animator?
                if not animator then continue end
                --[[
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    for _, id in ipairs(KATANA_ANIM_IDS) do
                        if track.Animation.AnimationId == id then
                            -- Acción de evasión: depende del juego
                            -- EjemploEvasion()
                        end
                    end
                end
                ]]
            end
        end
    end))
end

function AntiKatana.Disable()
    AntiKatana.Active = false
    if AntiKatana._thread then pcall(function() task.cancel(AntiKatana._thread) end) end
end

-- ── 16.11 RESOLVER  [LÓGICA DE EJEMPLO] ──────────────────────────
--[[
    Analiza el historial de ángulos del target para predecir
    su hitbox real cuando usa técnicas anti-aim.
--]]
local Resolver = {
    Active  = false,
    History = {} :: {[Player]: {number}},  -- historial de ángulo Y
    _thread = nil :: thread?,
}

function Resolver.GetPredictedAngle(player: Player): number?
    local hist = Resolver.History[player]
    if not hist or #hist < 3 then return nil end
    -- Promedio ponderado de los últimos ángulos (más reciente = más peso)
    local sum, w = 0, 0
    for i, angle in ipairs(hist) do
        local weight = i  -- peso proporcional a la posición
        sum += angle * weight
        w   += weight
    end
    return sum / w
end

function Resolver.Enable()
    Resolver.Active = true
    Resolver._thread = TrackThread(task.spawn(function()
        while Resolver.Active do
            task.wait(0.05)
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local char = player.Character
                if not char then continue end
                local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if not hrp then continue end
                local _, angle, _ = hrp.CFrame:ToEulerAnglesYXZ()
                if not Resolver.History[player] then
                    Resolver.History[player] = {}
                end
                table.insert(Resolver.History[player], math.deg(angle))
                if #Resolver.History[player] > 12 then
                    table.remove(Resolver.History[player], 1)
                end
            end
        end
    end))
end

function Resolver.Disable()
    Resolver.Active  = false
    Resolver.History = {}
    if Resolver._thread then pcall(function() task.cancel(Resolver._thread) end) end
end

-- ── 16.12 ANTI-LOCK  [LÓGICA DE EJEMPLO] ─────────────────────────
local AntiLock = { Active = false, _thread = nil :: thread? }

function AntiLock.Enable()
    AntiLock.Active = true
    AntiLock._thread = TrackThread(task.spawn(function()
        while AntiLock.Active do
            task.wait(0.04)
            --[[  EJEMPLO: detectar si algún jugador tiene lock-on
                  sobre LocalPlayer verificando su línea de visión
                  y aplicando micro-rotaciones al personaje.

                  En un juego real:
                  local char = LocalPlayer.Character
                  local hrp  = char and char:FindFirstChild("HumanoidRootPart")
                  if hrp then
                      local jitter = CFrame.Angles(0, math.rad(math.random(-5,5)), 0)
                      hrp.CFrame   = hrp.CFrame * jitter
                  end
            ]]
        end
    end))
end

function AntiLock.Disable()
    AntiLock.Active = false
    if AntiLock._thread then pcall(function() task.cancel(AntiLock._thread) end) end
end

-- ── 16.13 ANTI-AIM  [LÓGICA DE EJEMPLO] ─────────────────────────
--[[
    Mueve la cabeza/cámara de forma errática para dificultar
    que otros jugadores te apunten. REQUIERE hooks de cliente.
--]]
local AntiAim = { Active = false, _thread = nil :: thread? }

function AntiAim.Enable()
    AntiAim.Active = true
    AntiAim._thread = TrackThread(task.spawn(function()
        while AntiAim.Active do
            task.wait(0.05)
            --[[
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if hrp then
                -- Spin aleatorio: hace que la hitbox real sea impredecible
                local spinAngle = math.random(0, 360)
                hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
            end
            ]]
        end
    end))
end

function AntiAim.Disable()
    AntiAim.Active = false
    if AntiAim._thread then pcall(function() task.cancel(AntiAim._thread) end) end
end

-- ── 16.14 FAKE LAG  [LÓGICA DE EJEMPLO] ─────────────────────────
--[[
    El Fake Lag real manipula el rate de actualización de red
    para que el servidor vea al jugador en una posición vieja.
    Esto requiere hookear funciones de red del cliente,
    algo que varía según el ejecutor.
--]]
local FakeLag = { Active = false }

function FakeLag.Enable()
    FakeLag.Active = true
    --[[
    -- EJEMPLO con ejecutor que soporte network manipulation:
    sethiddenproperty(LocalPlayer, "SimulationRadius", 0)
    -- O usando fire_server_packet throttle si el ejecutor lo permite
    ]]
    print("[LXNDXN FakeLag] Activado — modo demostración")
end

function FakeLag.Disable()
    FakeLag.Active = false
    --[[
    sethiddenproperty(LocalPlayer, "SimulationRadius", 1000)
    ]]
end

-- ── 16.15 KATANA STATUS ESP  [LÓGICA DE EJEMPLO] ─────────────────
local KatanaESP = { Active = false, BBs = {} :: {[Player]: BillboardGui} }

local function KatanaESP_Make(player: Player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local head = player.Character:FindFirstChild("Head") :: BasePart?
    if not head then return end
    if player.Character:FindFirstChild("_LXN_Katana") then return end

    local bb        = Instance.new("BillboardGui")
    bb.Name         = "_LXN_Katana"
    bb.Size         = UDim2.new(0, 110, 0, 18)
    bb.Adornee      = head
    bb.AlwaysOnTop  = true
    bb.StudsOffset  = Vector3.new(0, 5.8, 0)
    bb.MaxDistance  = 120
    local lbl       = Instance.new("TextLabel", bb)
    lbl.Size        = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font        = Enum.Font.GothamBold
    lbl.TextSize    = 12
    lbl.Text        = "⚔ KATANA"
    lbl.TextColor3  = Theme.AccentRed
    bb.Parent       = head
    KatanaESP.BBs[player] = bb

    TrackThread(task.spawn(function()
        while KatanaESP.Active and bb.Parent do
            task.wait(0.2)
            --[[
            local tool     = player.Character and player.Character:FindFirstChildOfClass("Tool")
            local hasKatana = tool and tool.Name:lower():find("katana")
            lbl.Text       = hasKatana and "⚔ KATANA" or "✓ SAFE"
            lbl.TextColor3 = hasKatana and Theme.AccentRed or Theme.AccentGreen
            ]]
        end
    end))
end

function KatanaESP.Enable()
    KatanaESP.Active = true
    for _, p in ipairs(Players:GetPlayers()) do KatanaESP_Make(p) end
    TrackConnection(Players.PlayerAdded:Connect(function(p)
        TrackConnection(p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if KatanaESP.Active then KatanaESP_Make(p) end
        end))
    end))
end

function KatanaESP.Disable()
    KatanaESP.Active = false
    for p, bb in pairs(KatanaESP.BBs) do
        pcall(function() bb:Destroy() end)
        KatanaESP.BBs[p] = nil
    end
end

-- ── 16.16 PERSISTENCIA DE CONFIGURACIÓN ──────────────────────────
local CONFIG_FILE = "LXNDXN_v4_config.json"

local function SaveConfig()
    -- Convierte el Color3 almacenado como tabla (serializable)
    local ok, json = pcall(function() return HttpService:JSONEncode(Config) end)
    if not ok then Notify("Error al serializar config", "error") return end
    local ok2, err = pcall(function() writefile(CONFIG_FILE, json) end)
    if ok2 then
        Notify("Configuración guardada ✓", "success")
    else
        Notify("Sin acceso a writefile: " .. tostring(err), "warn")
    end
end

local function LoadConfig(): boolean
    local ok, content = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or not content then
        Notify("No se encontró config guardada", "warn")
        return false
    end
    local ok2, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(decoded) ~= "table" then
        Notify("Config corrupta o inválida", "error")
        return false
    end
    for k, v in pairs(decoded) do
        if Config[k] ~= nil then Config[k] = v end
    end
    Notify("Configuración cargada ✓", "success")
    return true
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 17 ─ CONSTRUCCIÓN DE TABS Y COMPONENTES
-- ══════════════════════════════════════════════════════════════════

local VisualsTab  = CreateTab("TAB_VISUALS",  1)
local CombatTab   = CreateTab("TAB_COMBAT",   2)
local MisticTab   = CreateTab("TAB_MISTIC",   3)
local MovementTab = CreateTab("TAB_MOVEMENT", 4)
local SettingsTab = CreateTab("TAB_SETTINGS", 5)

-- Activa el primer tab
_activeTab                             = "TAB_VISUALS"
TabFrames["TAB_VISUALS"].Visible       = true
Tabs["TAB_VISUALS"].Button.TextColor3  = Theme.Accent
Tabs["TAB_VISUALS"].Indicator.Size     = UDim2.new(0.8, 0, 0, 2)

-- ══════════════════════════════════════════════════════════════════
--  TAB VISUALES
-- ══════════════════════════════════════════════════════════════════
SectionLabel(VisualsTab, "ESP", 1)

CreateToggle(VisualsTab, "ESP_BOX", function(on)
    Config.ESP_BOX = on
    if on then ESP.StartBoxes() else ESP.StopBoxes() end
end, 2)

CreateToggle(VisualsTab, "TRACERS", function(on)
    Config.TRACERS = on
    if on then ESP.StartTracers() else ESP.StopTracers() end
end, 3)

CreateToggle(VisualsTab, "ESP_NAMES", function(on)
    Config.ESP_NAMES = on
    if on then ESP.StartNames() else ESP.StopNames() end
end, 4)

CreateToggle(VisualsTab, "ESP_HEALTH", function(on)
    Config.ESP_HEALTH = on
    if on then ESP.StartHealth() else ESP.StopHealth() end
end, 5)

CreateToggle(VisualsTab, "DISTANCE_ESP", function(on)
    Config.DISTANCE_ESP = on
    if on then ESP.StartDistance() else ESP.StopDistance() end
end, 6)

CreateToggle(VisualsTab, "KATANA_STATUS", function(on)
    Config.KATANA_STATUS = on
    if on then KatanaESP.Enable() else KatanaESP.Disable() end
end, 7)

-- ══════════════════════════════════════════════════════════════════
--  TAB COMBATE
-- ══════════════════════════════════════════════════════════════════
SectionLabel(CombatTab, "AIM", 1)

local _, setAimToggle = CreateToggle(CombatTab, "SILENT_AIM", function(on)
    Config.SILENT_AIM = on
    aimDD.Visible = on
    if on then SilentAim.Enable() else SilentAim.Disable() end
end, 2)

aimDD = CreateDropdown(CombatTab, "DIR_TITLE",
    {"DIR_HEAD", "DIR_CHEST", "DIR_ALL"}, "DIR_HEAD",
    function(key)
        local map = { DIR_HEAD = "Head", DIR_CHEST = "UpperTorso", DIR_ALL = "HumanoidRootPart" }
        Config.SILENT_AIM_PART = map[key] or "Head"
    end, 3)
aimDD.Visible = false

local hitChanceSlider
CreateToggle(CombatTab, "HIT_CHANCE_ON", function(on)
    Config.HIT_CHANCE_ON = on
    if hitChanceSlider then hitChanceSlider.Visible = on end
end, 4)
hitChanceSlider = CreateSlider(CombatTab, "HIT_CHANCE_VAL", 1, 100, 100, function(v)
    Config.HIT_CHANCE_VAL = v
end, 5)
hitChanceSlider.Visible = false

SectionLabel(CombatTab, "FOV", 6)

local fovSlider, _, setFov
CreateToggle(CombatTab, "SHOW_FOV", function(on)
    Config.SHOW_FOV = on
    if fovSlider then fovSlider.Visible = on end
    if filledToggle then filledToggle.Visible = on end
    if on then FOV_Start() else FOV_Stop() end
end, 7)
fovSlider = CreateSlider(CombatTab, "FOV_RADIUS", 20, 600, 120, function(v)
    Config.FOV_RADIUS = v
end, 8)
fovSlider.Visible = false

local filledToggle
filledToggle = CreateToggle(CombatTab, "FOV_FILLED", function(on)
    Config.FOV_FILLED = on
    if _fovCircle then _fovCircle.Filled = on end
end, 9)
filledToggle.Visible = false

SectionLabel(CombatTab, "OTROS", 10)

local predSlider
CreateToggle(CombatTab, "PREDICTION", function(on)
    Config.PREDICTION = on
    if predSlider then predSlider.Visible = on end
end, 11)
predSlider = CreateSlider(CombatTab, "PRED_FACTOR", 1, 30, 12, function(v)
    Config.PREDICTION_FACTOR = v / 100  -- 0.01 – 0.30 segundos
end, 12)
predSlider.Visible = false

local triggerDelaySlider
CreateToggle(CombatTab, "TRIGGER_BOT", function(on)
    Config.TRIGGER_BOT = on
    if triggerDelaySlider then triggerDelaySlider.Visible = on end
    if on then TriggerBot.Enable() else TriggerBot.Disable() end
end, 13)
triggerDelaySlider = CreateSlider(CombatTab, "TRIGGER_DELAY", 0, 500, 60, function(v)
    Config.TRIGGER_DELAY = v
end, 14)
triggerDelaySlider.Visible = false

-- ══════════════════════════════════════════════════════════════════
--  TAB MÍSTICO
-- ══════════════════════════════════════════════════════════════════
SectionLabel(MisticTab, "ANTI", 1)

CreateToggle(MisticTab, "ANTI_KATANA", function(on)
    Config.ANTI_KATANA = on
    if on then AntiKatana.Enable() else AntiKatana.Disable() end
end, 2)

local resolverDD
local _, setResolverToggle = CreateToggle(MisticTab, "RESOLVER", function(on)
    Config.RESOLVER = on
    if resolverDD then resolverDD.Visible = on end
    if on then Resolver.Enable() else Resolver.Disable() end
end, 3)
resolverDD = CreateDropdown(MisticTab, "RESOLVER_MODE",
    {"RES_AUTO", "RES_BRUTE", "RES_STATIC"}, "RES_AUTO",
    function(key)
        local map = { RES_AUTO = "Auto", RES_BRUTE = "Brute", RES_STATIC = "Static" }
        Config.RESOLVER_MODE = map[key] or "Auto"
    end, 4)
resolverDD.Visible = false

CreateToggle(MisticTab, "ANTI_LOCK", function(on)
    Config.ANTI_LOCK = on
    if on then AntiLock.Enable() else AntiLock.Disable() end
end, 5)

CreateToggle(MisticTab, "ANTI_AIM", function(on)
    Config.ANTI_AIM = on
    if on then AntiAim.Enable() else AntiAim.Disable() end
end, 6)

CreateToggle(MisticTab, "FAKE_LAG", function(on)
    Config.FAKE_LAG = on
    if on then FakeLag.Enable() else FakeLag.Disable() end
end, 7)

-- ══════════════════════════════════════════════════════════════════
--  TAB MOVIMIENTO
-- ══════════════════════════════════════════════════════════════════
SectionLabel(MovementTab, "VELOCIDAD", 1)

local speedSlider, _, setSpeed
CreateToggle(MovementTab, "MOD_SPEED", function(on)
    Config.MOD_SPEED = on
    if speedSlider then speedSlider.Visible = on end
    if not on then
        local char = LocalPlayer.Character
        local hum  = GetHumanoid(char)
        if hum then hum.WalkSpeed = 16 end
    end
end, 2)
speedSlider = CreateSlider(MovementTab, "WALK_SPEED", 0, 500, 16, function(v)
    Config.WALK_SPEED = v
    local char = LocalPlayer.Character
    local hum  = GetHumanoid(char)
    if hum then hum.WalkSpeed = v end
end, 3)
speedSlider.Visible = false

local jumpSlider
CreateToggle(MovementTab, "MOD_JUMP", function(on)
    Config.MOD_JUMP = on
    if jumpSlider then jumpSlider.Visible = on end
    if not on then
        local char = LocalPlayer.Character
        local hum  = GetHumanoid(char)
        if hum then hum.JumpPower = 50 end
    end
end, 4)
jumpSlider = CreateSlider(MovementTab, "JUMP_POWER", 0, 300, 50, function(v)
    Config.JUMP_POWER = v
    local char = LocalPlayer.Character
    local hum  = GetHumanoid(char)
    if hum then hum.JumpPower = v end
end, 5)
jumpSlider.Visible = false

SectionLabel(MovementTab, "ESPECIAL", 6)

CreateToggle(MovementTab, "INF_JUMP", function(on)
    Config.INF_JUMP = on
    if on then InfJump_Start() else InfJump_Stop() end
end, 7)

CreateToggle(MovementTab, "BHOP", function(on)
    Config.BHOP = on
    if on then BHop_Start() else BHop_Stop() end
end, 8)

CreateToggle(MovementTab, "NOCLIP", function(on)
    Config.NOCLIP = on
    if on then NoClip.Enable() else NoClip.Disable() end
end, 9)

SectionLabel(MovementTab, "VUELO", 10)

local flySlider
CreateToggle(MovementTab, "FLY_ON", function(on)
    Config.FLY_ON = on
    if flySlider then flySlider.Visible = on end
    if on then FlyModule.Enable() else FlyModule.Disable() end
end, 11)
flySlider = CreateSlider(MovementTab, "FLY_SPEED", 5, 600, 80, function(v)
    Config.FLY_SPEED = v
end, 12)
flySlider.Visible = false

-- Restaura stats al respawn
TrackConnection(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    local hum = GetHumanoid(char)
    if not hum then return end
    if Config.MOD_SPEED  then hum.WalkSpeed = Config.WALK_SPEED end
    if Config.MOD_JUMP   then hum.JumpPower = Config.JUMP_POWER end
    if Config.FLY_ON     then FlyModule.Enable() end
    EventBus:Fire("CharacterSpawned", char)
end))

-- ══════════════════════════════════════════════════════════════════
--  TAB AJUSTES
-- ══════════════════════════════════════════════════════════════════
SectionLabel(SettingsTab, "CONFIG", 1)

-- Guardar (actúa como botón momentáneo)
local _, setSave = CreateToggle(SettingsTab, "SAVE_CFG", function(on)
    if on then
        SaveConfig()
        task.delay(0.8, function() setSave(false, true) end)
    end
end, 2)

-- Cargar
local _, setLoad = CreateToggle(SettingsTab, "LOAD_CFG", function(on)
    if on then
        LoadConfig()
        task.delay(0.8, function() setLoad(false, true) end)
    end
end, 3)

CreateToggle(SettingsTab, "AUTO_LOAD", function(on)
    Config.AUTO_LOAD = on
end, 4)

CreateToggle(SettingsTab, "PERF_MODE", function(on)
    Config.PERF_MODE = on
    _pulsing = not on
    if on then
        Notify("Modo rendimiento: animaciones desactivadas", "info", 2)
    end
end, 5)

SectionLabel(SettingsTab, "INTERFAZ", 6)

CreateToggle(SettingsTab, "WATERMARK", function(on)
    Config.SHOW_WATERMARK    = on
    WatermarkFrame.Visible   = on
end, 7)

CreateToggle(SettingsTab, "PIN_BTN", function(on)
    Config.PIN_BTN = on
    _buttonFixed   = on
end, 8)

CreateToggle(SettingsTab, "HIDE_BTN", function(on)
    Config.HIDE_BTN = on
    Tween(FloatBtn,   { BackgroundTransparency = on and 1    or 0.1,
                        TextTransparency       = on and 1    or 0   }, Theme.AnimNormal)
    Tween(FloatStroke,{ Transparency           = on and 1    or 0.7 }, Theme.AnimNormal)
end, 9)

SectionLabel(SettingsTab, "IDIOMA", 10)

-- Dropdown de idioma (nombres fijos, no traducidos)
local LANG_H   = 44
local LANG_OPT = 30
local LANG_N   = 5

local langCard = New("Frame", {
    Parent             = SettingsTab,
    Size               = UDim2.new(1, 0, 0, LANG_H),
    BackgroundColor3   = Theme.BG2,
    BackgroundTransparency = Theme.CardTransp,
    ClipsDescendants   = true,
    LayoutOrder        = 11,
}) :: Frame
New("UICorner", { CornerRadius = UDim.new(0, 10), Parent = langCard })

local langTitleLbl = New("TextLabel", {
    Parent             = langCard,
    Size               = UDim2.new(1, -55, 0, LANG_H),
    Position           = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    TextColor3         = Theme.Text,
    Font               = Enum.Font.GothamMedium,
    TextSize           = 13,
    TextXAlignment     = Enum.TextXAlignment.Left,
}) :: TextLabel
local _langExtra = { CurrentSelectionKey = Config.LANGUAGE }
RegisterTranslation(langTitleLbl, "DropdownTitle", "LANG_TITLE", _langExtra)

local langArrow = New("TextLabel", {
    Parent             = langCard,
    Size               = UDim2.new(0, 24, 0, 24),
    Position           = UDim2.new(1, -32, 0, 10),
    BackgroundTransparency = 1,
    Text               = "▾",
    TextColor3         = Theme.TextSub,
    Font               = Enum.Font.GothamBold,
    TextSize           = 16,
}) :: TextLabel

local langOpts = New("Frame", {
    Parent             = langCard,
    Size               = UDim2.new(1, 0, 1, -LANG_H),
    Position           = UDim2.new(0, 0, 0, LANG_H),
    BackgroundTransparency = 1,
})
New("UIListLayout", { Parent = langOpts, SortOrder = Enum.SortOrder.LayoutOrder })

local langOpen = false
local langToggle = New("TextButton", {
    Parent             = langCard,
    Size               = UDim2.new(1, 0, 0, LANG_H),
    BackgroundTransparency = 1,
    Text               = "",
    ZIndex             = langCard.ZIndex + 2,
}) :: TextButton

TrackConnection(langToggle.MouseButton1Click:Connect(function()
    langOpen = not langOpen
    Tween(langCard, { Size = UDim2.new(1,0,0, langOpen and (LANG_H + LANG_N*LANG_OPT) or LANG_H) }, Theme.AnimNormal)
    Tween(langArrow, { Rotation = langOpen and 180 or 0 }, Theme.AnimNormal)
end))

local LANGUAGES = {
    { display = "Español",   key = "Español"   },
    { display = "English",   key = "Inglés"    },
    { display = "Português", key = "Portugués" },
    { display = "Русский",   key = "Ruso"      },
    { display = "پښتو",      key = "Pastún"    },
}
for i, lang in ipairs(LANGUAGES) do
    local btn = New("TextButton", {
        Parent             = langOpts,
        Size               = UDim2.new(1,0,0,LANG_OPT),
        BackgroundColor3   = Theme.BG3,
        BackgroundTransparency = 0.25,
        Text               = "  " .. lang.display,
        TextColor3         = Theme.TextSub,
        Font               = Enum.Font.Gotham,
        TextSize           = 12,
        TextXAlignment     = Enum.TextXAlignment.Left,
        LayoutOrder        = i,
        ZIndex             = langCard.ZIndex + 3,
    }) :: TextButton

    TrackConnection(btn.MouseEnter:Connect(function()
        Tween(btn, { BackgroundTransparency = 0, TextColor3 = Theme.Text }, Theme.AnimFast)
    end))
    TrackConnection(btn.MouseLeave:Connect(function()
        Tween(btn, { BackgroundTransparency = 0.25, TextColor3 = Theme.TextSub }, Theme.AnimFast)
    end))
    TrackConnection(btn.MouseButton1Click:Connect(function()
        UpdateLanguage(lang.key)
        _langExtra.CurrentSelectionKey = lang.display
        langTitleLbl.Text = (Lang[CurrentLanguage]["LANG_TITLE"] or "Language")
                          .. ": " .. lang.display
        langOpen = false
        Tween(langCard,  { Size = UDim2.new(1,0,0,LANG_H) }, Theme.AnimNormal)
        Tween(langArrow, { Rotation = 0 }, Theme.AnimNormal)
        Notify("Idioma cambiado: " .. lang.display, "success", 2)
    end))
end

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 18 ─ AUTO-LOAD DE CONFIGURACIÓN AL INICIAR
-- ══════════════════════════════════════════════════════════════════
TrackThread(task.spawn(function()
    task.wait(0.8)  -- espera a que la UI esté completamente construida
    if Config.AUTO_LOAD then
        local ok = LoadConfig()
        if ok then
            -- Aquí podrías aplicar los valores cargados a los toggles
            -- usando el sistema de SetFn guardado
        end
    end
    -- Notificación de bienvenida
    task.wait(0.2)
    Notify("⚡ LXNDXN v4.0 cargado — INSERT para abrir", "success", 5)
end))

-- ══════════════════════════════════════════════════════════════════
--  SECCIÓN 19 ─ LIMPIEZA TOTAL AL DESTRUIR EL GUI
--  Si el ScreenGui es eliminado externamente, todo se detiene.
-- ══════════════════════════════════════════════════════════════════
TrackConnection(ScreenGui.AncestryChanged:Connect(function()
    if ScreenGui.Parent then return end
    -- Detener todos los módulos
    ESP.StopBoxes();    ESP.StopTracers();   ESP.StopNames()
    ESP.StopHealth();   ESP.StopDistance()
    FlyModule.Disable(); NoClip.Disable()
    InfJump_Stop();     BHop_Stop()
    SilentAim.Disable(); TriggerBot.Disable()
    AntiKatana.Disable(); Resolver.Disable()
    AntiLock.Disable();  AntiAim.Disable()
    FakeLag.Disable();   KatanaESP.Disable()
    FOV_Stop()
    -- Desconectar todo
    for _, conn in pairs(getgenv().LXNDXN_CONNECTIONS) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(getgenv().LXNDXN_CONNECTIONS)
    -- Limpiar drawings
    for _, d in pairs(getgenv().LXNDXN_DRAWINGS) do
        pcall(function() d:Remove() end)
    end
    table.clear(getgenv().LXNDXN_DRAWINGS)
    -- Cancelar threads
    for _, t in pairs(getgenv().LXNDXN_THREADS) do
        pcall(function() task.cancel(t) end)
    end
    table.clear(getgenv().LXNDXN_THREADS)
    getgenv().LXNDXN_GUI = nil
    print("[LXNDXN] Shutdown completo. Todos los módulos detenidos.")
end))

-- ══════════════════════════════════════════════════════════════════
print("╔══════════════════════════════════════════╗")
print("║     L X N D X N   v4.0   LOADED         ║")
print("║   INSERT  →  Toggle Menu                ║")
print("║   getgenv() safe · Full cleanup ready   ║")
print("╚══════════════════════════════════════════╝")
-- ══════════════════════════════════════════════════════════════════
