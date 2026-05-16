-- ┌─────────────────────────────────────────────────────────────┐
-- │                      SERVICIOS                              │
-- └─────────────────────────────────────────────────────────────┘
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local CoreGui           = game:GetService("CoreGui")
local Workspace         = game:GetService("Workspace")
local Camera            = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- GUI parent con fallback seguro
local guiParent
do
    local ok = pcall(function()
        local t = Instance.new("ScreenGui"); t.Parent = CoreGui; t:Destroy()
        guiParent = CoreGui
    end)
    if not ok then guiParent = PlayerGui end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │               CONFIGURACIÓN GLOBAL                          │
-- └─────────────────────────────────────────────────────────────┘
local Config = {
    -- VISUALES
    ESP_NAMES       = false,
    ESP_HEALTH      = false,
    KATANA_STATUS   = false,
    -- COMBATE
    SILENT_AIM      = false,
    SILENT_AIM_DIR  = "DIR_HEAD",   -- "DIR_HEAD" | "DIR_CHEST" | "DIR_ALL"
    HIT_CHANCE_ON   = false,
    HIT_CHANCE_VAL  = 100,
    PREDICTION      = false,
    -- ═══════════════════════════════════════════════════════════
    SHOW_FOV        = false,
    FOV_RADIUS      = 80,
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
    FLY_ACCEL       = 12,     -- Suavidad de aceleración (nuevo)
    -- AJUSTES
    AUTO_LOAD       = false,
    PERF_MODE       = false,
    PIN_BTN         = false,
    HIDE_BTN        = false,
    LANGUAGE        = "Español",
}

-- ┌─────────────────────────────────────────────────────────────┐
-- │              LOCALIZACIÓN  (i18n)                           │
-- └─────────────────────────────────────────────────────────────┘
local CurrentLanguage = Config.LANGUAGE

local Lang = {
    ["Español"] = {
        TAB_VISUALS="VISUALES", TAB_COMBAT="COMBATE", TAB_MISTIC="MÍSTICO",
        TAB_MOVEMENT="MOVIMIENTO", TAB_SETTINGS="AJUSTES",
        ESP_NAMES="Nombres", ESP_HEALTH="Vida", KATANA_STATUS="Estado Katana",
        -- Combate
        SHOW_FOV="Mostrar FOV", FOV_RADIUS="Radio FOV",
        TRIGGER_BOT="Gatillo Automático",
        -- Místico
        ANTI_KATANA="Anti-Katana", RESOLVER="Resolver", ANTI_LOCK="Anti-Bloqueo",
        -- Movimiento
        MOD_SPEED="Modificar Velocidad", WALK_SPEED="Vel. Caminado",
        FLY_ON="Volar", FLY_SPEED="Vel. Vuelo", FLY_ACCEL="Suavidad Vuelo",
        -- Ajustes
        SAVE_CFG="Guardar Config", LOAD_CFG="Cargar Config",
        AUTO_LOAD="Carga Automática", PERF_MODE="Modo Rendimiento",
        PIN_BTN="Fijar Botón", HIDE_BTN="Ocultar Botón",
        LANG_TITLE="Idioma",
        SILENT_AIM="Silent Aim",
        HIT_CHANCE_ON="Probabilidad de impacto",
        HIT_CHANCE_VAL="Probabilidad %",
        PREDICTION="Predicción",
        -- Dropdowns Silent Aim (conectar aquí):
        DIR_TITLE="Dirección", DIR_HEAD="Cabeza", DIR_CHEST="Pecho", DIR_ALL="General",
    },
    ["Inglés"] = {
        TAB_VISUALS="VISUALS", TAB_COMBAT="COMBAT", TAB_MISTIC="MYSTIC",
        TAB_MOVEMENT="MOVEMENT", TAB_SETTINGS="SETTINGS",
        ESP_NAMES="Names", ESP_HEALTH="Health", KATANA_STATUS="Katana Status",
        SHOW_FOV="Show FOV", FOV_RADIUS="FOV Radius",
        TRIGGER_BOT="Trigger Bot",
        ANTI_KATANA="Anti-Katana", RESOLVER="Resolver", ANTI_LOCK="Anti-Lock",
        MOD_SPEED="Modify Speed", WALK_SPEED="Walk Speed",
        FLY_ON="Fly", FLY_SPEED="Fly Speed", FLY_ACCEL="Fly Smoothness",
        SAVE_CFG="Save Config", LOAD_CFG="Load Config",
        AUTO_LOAD="Auto Load", PERF_MODE="Performance Mode",
        PIN_BTN="Pin Button", HIDE_BTN="Hide Button",
        LANG_TITLE="Language",
        SILENT_AIM="Silent Aim",
        HIT_CHANCE_ON="Hit Chance",
        HIT_CHANCE_VAL="Hit Chance %",
        PREDICTION="Prediction",
        DIR_TITLE="Target Part", DIR_HEAD="Head", DIR_CHEST="Chest", DIR_ALL="General",
    },
    ["Portugués"] = {
        TAB_VISUALS="VISUAIS", TAB_COMBAT="COMBATE", TAB_MISTIC="MÍSTICO",
        TAB_MOVEMENT="MOVIMENTO", TAB_SETTINGS="CONFIGURAÇÕES",
        ESP_NAMES="Nomes", ESP_HEALTH="Vida", KATANA_STATUS="Status Katana",
        SHOW_FOV="Mostrar FOV", FOV_RADIUS="Raio FOV",
        TRIGGER_BOT="Gatilho Automático",
        ANTI_KATANA="Anti-Katana", RESOLVER="Resolver", ANTI_LOCK="Anti-Bloqueio",
        MOD_SPEED="Modificar Velocidade", WALK_SPEED="Vel. Caminhada",
        FLY_ON="Voar", FLY_SPEED="Vel. Voo", FLY_ACCEL="Suavidade Voo",
        SAVE_CFG="Salvar Config", LOAD_CFG="Carregar Config",
        AUTO_LOAD="Carregamento Automático", PERF_MODE="Modo Desempenho",
        PIN_BTN="Fixar Botão", HIDE_BTN="Ocultar Botão",
        LANG_TITLE="Idioma",
        SILENT_AIM="Silent Aim",
        HIT_CHANCE_ON="Chance de Acerto",
        HIT_CHANCE_VAL="Chance %",
        PREDICTION="Predição",
        DIR_TITLE="Direção", DIR_HEAD="Cabeça", DIR_CHEST="Peito", DIR_ALL="Geral",
    },
    ["Ruso"] = {
        TAB_VISUALS="ВИЗУАЛЫ", TAB_COMBAT="БОЙ", TAB_MISTIC="МИСТИКА",
        TAB_MOVEMENT="ДВИЖЕНИЕ", TAB_SETTINGS="НАСТРОЙКИ",
        ESP_NAMES="Имена", ESP_HEALTH="Здоровье", KATANA_STATUS="Статус Катаны",
        SHOW_FOV="Показать FOV", FOV_RADIUS="Радиус FOV",
        TRIGGER_BOT="Автоспуск",
        ANTI_KATANA="Анти-Катана", RESOLVER="Резольвер", ANTI_LOCK="Анти-Захват",
        MOD_SPEED="Изменить Скорость", WALK_SPEED="Скорость Ходьбы",
        FLY_ON="Полет", FLY_SPEED="Скорость Полета", FLY_ACCEL="Плавность Полета",
        SAVE_CFG="Сохранить", LOAD_CFG="Загрузить",
        AUTO_LOAD="Автозагрузка", PERF_MODE="Производительность",
        PIN_BTN="Закрепить", HIDE_BTN="Скрыть",
        LANG_TITLE="Язык",
        DIR_TITLE="Цель", DIR_HEAD="Голова", DIR_CHEST="Грудь", DIR_ALL="Общее",
    },
    ["Pastún"] = {
        TAB_VISUALS="لیدونه", TAB_COMBAT="جګړه", TAB_MISTIC="صوفیانه",
        TAB_MOVEMENT="حرکت", TAB_SETTINGS="تنظیمات",
        ESP_NAMES="نومونه", ESP_HEALTH="روغتیا", KATANA_STATUS="د کټانا حالت",
        SHOW_FOV="FOV وښایاست", FOV_RADIUS="د FOV شعاع",
        TRIGGER_BOT="اتوماتیک محرک",
        ANTI_KATANA="انټي-کټانا", RESOLVER="حل کوونکی", ANTI_LOCK="انټي-لاک",
        MOD_SPEED="سرعت بدل کړئ", WALK_SPEED="د تګ سرعت",
        FLY_ON="الوتنه", FLY_SPEED="د الوتنې سرعت", FLY_ACCEL="د الوتنې نرمتیا",
        SAVE_CFG="خوندي کړئ", LOAD_CFG="بار کړئ",
        AUTO_LOAD="اتومات بار", PERF_MODE="فعالیت",
        PIN_BTN="پن کړئ", HIDE_BTN="پټ کړئ",
        LANG_TITLE="ژبه",
        DIR_TITLE="لارښوونه", DIR_HEAD="سر", DIR_CHEST="سینه", DIR_ALL="عمومي",
    },
}

local TranslatingElements = {}

local function RegisterTranslation(inst, kind, key, extra)
    table.insert(TranslatingElements, { UI=inst, Type=kind, Key=key, Extra=extra or {} })
    local L = Lang[CurrentLanguage]
    if kind == "Text" then
        inst.Text = L[key] or key
    elseif kind == "DropdownTitle" then
        local sel = extra and (L[extra.CurrentSelectionKey] or extra.CurrentSelectionKey) or ""
        inst.Text = (L[key] or key) .. ": " .. sel
    elseif kind == "DropdownOption" then
        inst.Text = "  " .. (L[key] or key)
    end
end

local function UpdateLanguage(newLang)
    CurrentLanguage = newLang
    Config.LANGUAGE = newLang
    for _, item in ipairs(TranslatingElements) do
        local L = Lang[CurrentLanguage]
        if item.Type == "Text" then
            item.UI.Text = L[item.Key] or item.Key
        elseif item.Type == "DropdownTitle" then
            local sel = L[item.Extra.CurrentSelectionKey] or item.Extra.CurrentSelectionKey or ""
            item.UI.Text = (L[item.Key] or item.Key) .. ": " .. sel
        elseif item.Type == "DropdownOption" then
            item.UI.Text = "  " .. (L[item.Key] or item.Key)
        end
    end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │               BUS DE EVENTOS INTERNO                        │
-- └─────────────────────────────────────────────────────────────┘
local EventBus = { _listeners = {} }

function EventBus:On(event, cb)
    self._listeners[event] = self._listeners[event] or {}
    table.insert(self._listeners[event], cb)
end

function EventBus:Fire(event, ...)
    for _, cb in ipairs(self._listeners[event] or {}) do
        pcall(cb, ...)
    end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │                        TEMA                                 │
-- └─────────────────────────────────────────────────────────────┘
local Theme = {
    MainColor          = Color3.fromRGB(10, 10, 14),
    GlassTransparency  = 0.28,
    AccentColor        = Color3.fromRGB(10, 132, 255),
    AccentSecondary    = Color3.fromRGB(48, 209, 88),
    DangerColor        = Color3.fromRGB(255, 69, 58),
    TextColor          = Color3.fromRGB(245, 245, 250),
    SecondaryText      = Color3.fromRGB(155, 155, 168),
    BorderColor        = Color3.fromRGB(255, 255, 255),
    BorderTransparency = 0.82,
    DropdownColor      = Color3.fromRGB(22, 22, 28),
    CardColor          = Color3.fromRGB(20, 20, 26),
    CardTransparency   = 0.48,
    TweenDuration      = 0.28,
    TweenStyle         = Enum.EasingStyle.Quart,
    TweenDir           = Enum.EasingDirection.Out,
}

-- ┌─────────────────────────────────────────────────────────────┐
-- │                     UTILIDADES                              │
-- └─────────────────────────────────────────────────────────────┘
local function Create(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function Tween(obj, props, dur, style, dir)
    local info = TweenInfo.new(
        dur   or Theme.TweenDuration,
        style or Theme.TweenStyle,
        dir   or Theme.TweenDir
    )
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function ApplyShadow(frame, offset, alpha)
    offset = offset or 18; alpha = alpha or 0.55
    return Create("ImageLabel", {
        Name="Shadow", Parent=frame,
        AnchorPoint=Vector2.new(0.5,0.5),
        BackgroundTransparency=1,
        Position=UDim2.new(0.5,0, 0.5, offset/2),
        Size=UDim2.new(1, offset*2, 1, offset*2),
        ZIndex=frame.ZIndex-1,
        Image="rbxassetid://5028857084",
        ImageColor3=Color3.new(0,0,0),
        ImageTransparency=alpha,
        ScaleType=Enum.ScaleType.Slice,
        SliceCenter=Rect.new(24,24,276,276),
    })
end

local function UpdateCanvasSize(sf)
    local layout = sf:FindFirstChildOfClass("UIListLayout")
    if layout then
        sf.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 24)
    end
end

-- Redondeo con decimales configurable
local function Round(n, dec)
    local f = 10^(dec or 0)
    return math.floor(n * f + 0.5) / f
end

-- Lerp vectorial para suavizado de movimiento
local function LerpV3(a, b, t)
    return a + (b - a) * t
end

-- ══════════════════════════════════════════════════════════════
--  FUNCIÓN DE TARGETING (usada por FOV, TriggerBot, y
--  también por tu Silent Aim cuando lo conectes)
--
--  CÓMO CONECTAR TU SILENT AIM:
--  1. Importa / define tu lógica de Silent Aim al final del script.
--  2. Llama GetBestTarget(Config.FOV_RADIUS) para obtener
--     (player, part, score) y usa esos datos en tu namecall hook.
--  3. predictPosition(part) ya está disponible abajo para que
--     lo uses directamente desde tu módulo.
-- ══════════════════════════════════════════════════════════════

-- Devuelve la parte objetivo según Config.SILENT_AIM_DIR
-- (cuando aún no hay SILENT_AIM_DIR usa "HEAD" por defecto)
local function getTargetPart(player)
    if not player.Character then return nil end
    local dir = Config["SILENT_AIM_DIR"] or "DIR_HEAD"
    local partName = "Head"
    if dir == "DIR_CHEST" then
        partName = "UpperTorso"
    elseif dir == "DIR_ALL" then
        partName = "HumanoidRootPart"
    end
    return player.Character:FindFirstChild(partName)
        or player.Character:FindFirstChild("HumanoidRootPart")
end

--[[
    GetBestTarget(maxRadius)
    Devuelve: player, part, score  (o nil si no hay objetivo)

    Algoritmo mejorado respecto a v3:
    - Combina distancia en pantalla + ángulo de cámara + distancia 3D
    - Peso calibrado para favorecer targets en el centro del FOV
    - Ignora targets muertos o sin personaje
    - Score más bajo = mejor objetivo
]]
local function GetBestTarget(maxRadius)
    maxRadius = maxRadius or Config.FOV_RADIUS
    local bestPlayer, bestPart, bestScore = nil, nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    local camCF    = Camera.CFrame
    local camPos   = camCF.Position
    local camLook  = camCF.LookVector

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end

        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local part = getTargetPart(player)
        if not part then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if screenDist > maxRadius then continue end

        local toTarget  = part.Position - camPos
        local dist3D    = toTarget.Magnitude
        if dist3D == 0 then continue end

        -- Ángulo entre la mirada de la cámara y el objetivo
        local dot   = math.clamp(camLook:Dot(toTarget.Unit), -1, 1)
        local angle = math.deg(math.acos(dot))

        -- Ponderación: pantalla pesa más que ángulo, ángulo más que distancia
        local score = screenDist * 1.0 + angle * 0.3 + dist3D * 0.005

        if score < bestScore then
            bestScore  = score
            bestPlayer = player
            bestPart   = part
        end
    end

    return bestPlayer, bestPart, bestScore
end

--[[
    predictPosition(part)
    Calcula la posición futura de una parte aplicando su velocidad
    lineal escalada por distancia y ping estimado.

    NOTA PARA SILENT AIM:
    Llama esto desde tu redirectArguments() para obtener
    targetPos y usarlo en lugar de la posición actual.
    Ejemplo:
        local targetPos = predictPosition(targetPart)
]]
local function predictPosition(part)
    if not part then return nil end
    local pos = part.Position
    if not Config.PREDICTION then return pos end

    local vel      = part.AssemblyLinearVelocity or Vector3.zero
    local dist     = (pos - Camera.CFrame.Position).Magnitude

    -- Factor de predicción: aumenta con la distancia
    -- Calibrado para ser efectivo entre 10 y 500 studs
    local baseFactor  = 0.085
    local distFactor  = math.clamp(dist / 800, 0, 0.18)
    local totalFactor = math.clamp(baseFactor + distFactor, 0.04, 0.26)

    return pos + vel * totalFactor
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │                 MÓDULO SILENT AIM                           │
-- │                                                             │
-- │  Lógica de Silent Aim para Delta Mobile con FOV, hit chance,│
-- │  predicción y redirección conservadora de remotes de disparo.│
-- └─────────────────────────────────────────────────────────────┘
local SilentAim = {
    Active  = false,
    Hooked  = false,
    OldNamecall = nil,
}

local function shouldHit()
    if not Config.HIT_CHANCE_ON then
        return true
    end
    local pct = math.clamp((Config.HIT_CHANCE_VAL or 100) / 100, 0, 1)
    return math.random() <= pct
end

local function isAttackRemote(remote)
    if not remote or typeof(remote) ~= "Instance" then
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
        or name:find("projectile")
        or name:find("shooting")
end

local function patchTableFields(tbl, targetPart, targetPos)
    local patched = false
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            if patchTableFields(value, targetPart, targetPos) then
                patched = true
            end
        elseif typeof(value) == "Instance" and value:IsA("BasePart") then
            tbl[key] = targetPart
            patched = true
        elseif typeof(value) == "Vector3" then
            local lowerKey = tostring(key):lower()
            if lowerKey:find("pos") or lowerKey:find("target") or lowerKey:find("hit") or lowerKey:find("mouse") then
                tbl[key] = targetPos
                patched = true
            end
        elseif typeof(value) == "CFrame" then
            local lowerKey = tostring(key):lower()
            if lowerKey:find("cframe") or lowerKey:find("aim") or lowerKey:find("target") then
                tbl[key] = CFrame.new(value.Position, targetPos)
                patched = true
            end
        elseif type(key) == "string" then
            local lowerKey = key:lower()
            if lowerKey == "target" or lowerKey == "part" or lowerKey == "hitpart" or lowerKey == "victim" then
                tbl[key] = targetPart
                patched = true
            elseif lowerKey == "position" or lowerKey == "pos" or lowerKey == "hitposition" or lowerKey == "hitpos" then
                tbl[key] = targetPos
                patched = true
            end
        end
    end
    return patched
end

local function redirectArguments(args, targetPart, targetPos)
    local newArgs = {}
    for i, arg in ipairs(args) do
        if typeof(arg) == "Instance" and arg:IsA("BasePart") then
            newArgs[i] = targetPart
        elseif typeof(arg) == "Vector3" then
            newArgs[i] = targetPos
        elseif typeof(arg) == "CFrame" then
            newArgs[i] = CFrame.new(arg.Position, targetPos)
        elseif type(arg) == "table" then
            local clone = {}
            for k, v in pairs(arg) do clone[k] = v end
            patchTableFields(clone, targetPart, targetPos)
            newArgs[i] = clone
        else
            newArgs[i] = arg
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
            local hasKey = false
            local hasValue = false
            for k, v in pairs(arg) do
                local keyName = tostring(k):lower()
                if keyName:find("target") or keyName:find("hit") or keyName:find("position") or keyName:find("mouse") or keyName:find("part") then
                    hasKey = true
                end
                if typeof(v) == "Instance" and v:IsA("BasePart") then
                    hasValue = true
                elseif typeof(v) == "Vector3" or typeof(v) == "CFrame" then
                    hasValue = true
                end
            end
            if hasKey and hasValue then
                return true
            end
        end
    end
    return false
end

local function interceptNamecall(self, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if method ~= "FireServer" and method ~= "InvokeServer" then
        return SilentAim.OldNamecall(self, unpack(args))
    end
    if not SilentAim.Active then
        return SilentAim.OldNamecall(self, unpack(args))
    end
    if not (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        return SilentAim.OldNamecall(self, unpack(args))
    end
    if not isAttackRemote(self) then
        return SilentAim.OldNamecall(self, unpack(args))
    end
    if not argsContainShootData(args) then
        return SilentAim.OldNamecall(self, unpack(args))
    end

    local targetPlayer, targetPart = GetBestTarget(Config.FOV_RADIUS)
    if not targetPlayer or not targetPart or not shouldHit() then
        return SilentAim.OldNamecall(self, unpack(args))
    end

    local targetPos = predictPosition(targetPart)
    return SilentAim.OldNamecall(self, redirectArguments(args, targetPart, targetPos))
end

local function connectSilentAimHook()
    if SilentAim.Hooked then return end

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
    if not SilentAim.Hooked then return end

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
    if SilentAim.Active then return end
    SilentAim.Active = true
    connectSilentAimHook()
    print("[LXNDXN] Silent Aim activado")
end

function SilentAim.Disable()
    SilentAim.Active = false
    disconnectSilentAimHook()
    print("[LXNDXN] Silent Aim desactivado")
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │               CONSTRUCCIÓN DEL GUI                          │
-- └─────────────────────────────────────────────────────────────┘
local ScreenGui = Create("ScreenGui", {
    Name           = "LXNDXN_UI_v4",
    Parent         = guiParent,
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
    DisplayOrder   = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

-- ── BOTÓN FLOTANTE ──────────────────────────────────────────────
local FloatButton = Create("TextButton", {
    Name="FloatButton", Parent=ScreenGui,
    Size=UDim2.new(0,52,0,52),
    Position=UDim2.new(0.92,0, 0.08,0),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=Theme.AccentColor,
    BackgroundTransparency=0.15,
    Text="⚡", TextColor3=Color3.new(1,1,1),
    TextTransparency=0, TextScaled=true,
    Font=Enum.Font.GothamBold,
    ClipsDescendants=true, ZIndex=10,
})
Create("UICorner",  { CornerRadius=UDim.new(1,0), Parent=FloatButton })
local FloatStroke = Create("UIStroke", {
    Color=Color3.new(1,1,1), Transparency=0.7,
    Thickness=1.5, Parent=FloatButton,
})

-- Pulso del botón: solo si no está en PERF_MODE
local pulseTween
local function StartButtonPulse()
    if Config.PERF_MODE then return end
    if pulseTween then pulseTween:Cancel() end
    local function doPulse()
        pulseTween = Tween(FloatButton,{BackgroundTransparency=0.42},0.85,Enum.EasingStyle.Sine)
        pulseTween.Completed:Connect(function()
            pulseTween = Tween(FloatButton,{BackgroundTransparency=0.10},0.85,Enum.EasingStyle.Sine)
            pulseTween.Completed:Connect(doPulse)
        end)
    end
    doPulse()
end
StartButtonPulse()

-- ── VENTANA PRINCIPAL ───────────────────────────────────────────
local MainFrame = Create("Frame", {
    Name="MainFrame", Parent=ScreenGui,
    Size=UDim2.new(0,500,0,415),
    Position=UDim2.new(0.5,0, 0.5,0),
    AnchorPoint=Vector2.new(0.5,0.5),
    BackgroundColor3=Theme.MainColor,
    BackgroundTransparency=Theme.GlassTransparency,
    ClipsDescendants=true, Visible=false, ZIndex=5,
})
Create("UICorner",  { CornerRadius=UDim.new(0,18), Parent=MainFrame })
Create("UIStroke",  { Color=Theme.BorderColor, Transparency=Theme.BorderTransparency, Thickness=1, Parent=MainFrame })
ApplyShadow(MainFrame, 32, 0.48)

-- Línea de acento superior
local AccentLine = Create("Frame", {
    Name="AccentLine", Parent=MainFrame,
    Size=UDim2.new(0.55,0, 0,2),
    Position=UDim2.new(0.225,0, 0,0),
    BackgroundColor3=Theme.AccentColor,
    BorderSizePixel=0, ZIndex=6,
})
Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=AccentLine })

-- Animación de brillo en la línea (respeta PERF_MODE)
task.spawn(function()
    while MainFrame.Parent do
        if not Config.PERF_MODE then
            Tween(AccentLine,{BackgroundColor3=Theme.AccentSecondary},1.6,Enum.EasingStyle.Sine)
            task.wait(1.7)
            Tween(AccentLine,{BackgroundColor3=Theme.AccentColor},1.6,Enum.EasingStyle.Sine)
            task.wait(1.7)
        else
            task.wait(1)
        end
    end
end)

-- ── TOP BAR ─────────────────────────────────────────────────────
local TopBar = Create("Frame", {
    Name="TopBar", Parent=MainFrame,
    Size=UDim2.new(1,0,0,44),
    BackgroundTransparency=1, ZIndex=6,
})
-- Sombra del título
Create("TextLabel", {
    Parent=TopBar, Size=UDim2.new(1,-20,1,0),
    Position=UDim2.new(0,22,0,1),
    BackgroundTransparency=1, Text="LXNDXN",
    TextColor3=Theme.AccentColor, TextTransparency=0.6,
    Font=Enum.Font.GothamBlack, TextSize=20,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
})
Create("TextLabel", {
    Parent=TopBar, Size=UDim2.new(1,-20,1,0),
    Position=UDim2.new(0,20,0,0),
    BackgroundTransparency=1, Text="LXNDXN",
    TextColor3=Theme.TextColor, Font=Enum.Font.GothamBlack,
    TextSize=20, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7,
})
Create("TextLabel", {
    Parent=TopBar, Size=UDim2.new(0,60,0,16),
    Position=UDim2.new(0,88,0,14),
    BackgroundTransparency=1, Text="v4.0",
    TextColor3=Theme.SecondaryText, Font=Enum.Font.GothamSemibold,
    TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7,
})

-- ── TAB BAR ─────────────────────────────────────────────────────
local TabBar = Create("ScrollingFrame", {
    Name="TabBar", Parent=MainFrame,
    Size=UDim2.new(1,-40,0,36),
    Position=UDim2.new(0,20,0,50),
    BackgroundTransparency=1, ScrollBarThickness=0,
    CanvasSize=UDim2.new(1.6,0,0,0),
    ScrollingDirection=Enum.ScrollingDirection.X, ZIndex=6,
})
Create("UIListLayout", {
    Parent=TabBar, FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,12),
})

-- ── CONTENEDOR ──────────────────────────────────────────────────
local ContentContainer = Create("Frame", {
    Name="ContentContainer", Parent=MainFrame,
    Size=UDim2.new(1,-40,1,-104),
    Position=UDim2.new(0,20,0,96),
    BackgroundTransparency=1, ClipsDescendants=true, ZIndex=5,
})

-- ┌─────────────────────────────────────────────────────────────┐
-- │                 DRAG / ARRASTRE                             │
-- └─────────────────────────────────────────────────────────────┘
local ButtonIsFixed = false

local function MakeDraggable(guiObj, handle)
    handle = handle or guiObj
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if guiObj == FloatButton and ButtonIsFixed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = guiObj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local d = input.Position - dragStart
            guiObj.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

MakeDraggable(FloatButton)
MakeDraggable(MainFrame, TopBar)

-- ┌─────────────────────────────────────────────────────────────┐
-- │            TOGGLE MENÚ / TECLA INSERT                       │
-- └─────────────────────────────────────────────────────────────┘
local menuOpen = false

local function ToggleMenu()
    menuOpen = not menuOpen
    if menuOpen then
        MainFrame.Visible = true
        MainFrame.Size    = UDim2.new(0,500,0,0)
        MainFrame.BackgroundTransparency = 1
        Tween(MainFrame, {
            Size=UDim2.new(0,500,0,415),
            BackgroundTransparency=Theme.GlassTransparency,
        }, 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        local t = Tween(MainFrame, {
            Size=UDim2.new(0,500,0,0),
            BackgroundTransparency=1,
        }, 0.28)
        t.Completed:Connect(function() MainFrame.Visible = false end)
    end
end

FloatButton.MouseButton1Click:Connect(ToggleMenu)
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Insert then ToggleMenu() end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │               COMPONENTES UI                                │
-- └─────────────────────────────────────────────────────────────┘
local Tabs      = {}
local TabFrames = {}
local ActiveTab = nil

local function CreateTab(key, order)
    local TabBtn = Create("TextButton", {
        Name=key, Parent=TabBar,
        Size=UDim2.new(0,95,1,0),
        BackgroundTransparency=1,
        TextColor3=Theme.SecondaryText,
        Font=Enum.Font.GothamSemibold,
        TextSize=13, LayoutOrder=order or 0, ZIndex=7,
    })
    RegisterTranslation(TabBtn, "Text", key)

    local TabIndicator = Create("Frame", {
        Name="Indicator", Parent=TabBtn,
        Size=UDim2.new(0,0,0,2),
        Position=UDim2.new(0.5,0,1,-2),
        AnchorPoint=Vector2.new(0.5,0),
        BackgroundColor3=Theme.AccentColor,
        BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=TabIndicator })

    local TabFrame = Create("ScrollingFrame", {
        Name=key.."_Frame", Parent=ContentContainer,
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        ScrollBarThickness=2,
        ScrollBarImageColor3=Theme.AccentColor,
        Visible=false, ZIndex=5,
    })
    local layout = Create("UIListLayout", {
        Parent=TabFrame, SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,8),
    })
    Create("UIPadding", {
        Parent=TabFrame,
        PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,8),
    })

    Tabs[key]      = { Button=TabBtn, Indicator=TabIndicator }
    TabFrames[key] = TabFrame

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        UpdateCanvasSize(TabFrame)
    end)

    TabBtn.MouseButton1Click:Connect(function()
        if ActiveTab == key then return end
        for k, data in pairs(Tabs) do
            TabFrames[k].Visible = false
            Tween(data.Button,    {TextColor3=Theme.SecondaryText}, 0.18)
            Tween(data.Indicator, {Size=UDim2.new(0,0,0,2)}, 0.18)
        end
        ActiveTab = key
        TabFrame.Visible = true
        Tween(TabBtn,      {TextColor3=Theme.AccentColor}, 0.18)
        Tween(TabIndicator,{Size=UDim2.new(0.78,0,0,2)}, 0.28, Enum.EasingStyle.Back)
    end)

    return TabFrame
end

-- ── TOGGLE ──────────────────────────────────────────────────────
local function CreateToggle(parent, key, callback, order)
    local F = Create("Frame", {
        Parent=parent, Size=UDim2.new(1,0,0,44),
        BackgroundColor3=Theme.CardColor,
        BackgroundTransparency=Theme.CardTransparency,
        LayoutOrder=order or 0,
    })
    Create("UICorner", { CornerRadius=UDim.new(0,10), Parent=F })

    local StatusDot = Create("Frame", {
        Parent=F, Size=UDim2.new(0,6,0,6),
        Position=UDim2.new(0,10,0.5,-3),
        BackgroundColor3=Theme.SecondaryText, BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=StatusDot })

    local Label = Create("TextLabel", {
        Parent=F, Size=UDim2.new(1,-80,1,0),
        Position=UDim2.new(0,24,0,0),
        BackgroundTransparency=1, TextColor3=Theme.TextColor,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    RegisterTranslation(Label, "Text", key)

    local SwitchBG = Create("Frame", {
        Parent=F, Size=UDim2.new(0,44,0,22),
        Position=UDim2.new(1,-56,0.5,-11),
        BackgroundColor3=Color3.fromRGB(45,45,52), BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=SwitchBG })

    local Knob = Create("Frame", {
        Parent=SwitchBG, Size=UDim2.new(0,18,0,18),
        Position=UDim2.new(0,2,0.5,-9),
        BackgroundColor3=Color3.fromRGB(210,210,220), BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=Knob })

    local ClickArea = Create("TextButton", {
        Parent=F, Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1, Text="",
        ZIndex=F.ZIndex+1,
    })

    local toggled = false

    local function SetToggle(state, skipCb)
        toggled = state
        if not Config.PERF_MODE then
            Tween(Knob, {
                Position = state
                    and UDim2.new(1,-20,0.5,-9)
                    or  UDim2.new(0,2,0.5,-9)
            }, 0.22, Enum.EasingStyle.Back)
            Tween(SwitchBG, {
                BackgroundColor3 = state and Theme.AccentColor or Color3.fromRGB(45,45,52)
            }, 0.22)
            Tween(StatusDot, {
                BackgroundColor3 = state and Theme.AccentSecondary or Theme.SecondaryText
            }, 0.18)
            Tween(Knob, {Size=UDim2.new(0,20,0,20)}, 0.09)
            task.delay(0.10, function()
                Tween(Knob, {Size=UDim2.new(0,18,0,18)}, 0.13)
            end)
        else
            -- Sin animación en modo rendimiento
            Knob.Position      = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
            SwitchBG.BackgroundColor3 = state and Theme.AccentColor or Color3.fromRGB(45,45,52)
            StatusDot.BackgroundColor3= state and Theme.AccentSecondary or Theme.SecondaryText
        end
        if not skipCb and callback then callback(state) end
    end

    ClickArea.MouseButton1Click:Connect(function() SetToggle(not toggled) end)
    return F, SetToggle
end

-- ── SLIDER ──────────────────────────────────────────────────────
local function CreateSlider(parent, key, minVal, maxVal, defVal, callback, order)
    local F = Create("Frame", {
        Parent=parent, Size=UDim2.new(1,0,0,64),
        BackgroundColor3=Theme.CardColor,
        BackgroundTransparency=Theme.CardTransparency,
        LayoutOrder=order or 0,
    })
    Create("UICorner", { CornerRadius=UDim.new(0,10), Parent=F })

    local Label = Create("TextLabel", {
        Parent=F, Size=UDim2.new(1,-80,0,22),
        Position=UDim2.new(0,15,0,6),
        BackgroundTransparency=1, TextColor3=Theme.TextColor,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    RegisterTranslation(Label, "Text", key)

    local ValLabel = Create("TextLabel", {
        Parent=F, Size=UDim2.new(0,55,0,22),
        Position=UDim2.new(1,-68,0,6),
        BackgroundTransparency=1, Text=tostring(defVal),
        TextColor3=Theme.AccentColor, Font=Enum.Font.GothamBold,
        TextSize=13, TextXAlignment=Enum.TextXAlignment.Right,
    })

    local Track = Create("Frame", {
        Parent=F, Size=UDim2.new(1,-30,0,6),
        Position=UDim2.new(0,15,0,38),
        BackgroundColor3=Color3.fromRGB(45,45,52), BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=Track })

    local Fill = Create("Frame", {
        Parent=Track,
        Size=UDim2.new((defVal-minVal)/(maxVal-minVal),0,1,0),
        BackgroundColor3=Theme.AccentColor, BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=Fill })
    Create("UIGradient", {
        Parent=Fill,
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentColor),
            ColorSequenceKeypoint.new(1, Theme.AccentSecondary),
        }),
    })

    local SliderKnob = Create("Frame", {
        Parent=Fill, Size=UDim2.new(0,16,0,16),
        Position=UDim2.new(1,-8,0.5,-8),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0,
    })
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=SliderKnob })
    Create("UIStroke", { Color=Theme.AccentColor, Transparency=0.3, Thickness=2, Parent=SliderKnob })

    local currentVal = defVal
    local isDragging = false

    local function UpdateSlider(inputX)
        local rel  = math.clamp((inputX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        currentVal = Round(minVal + (maxVal - minVal) * rel)
        Fill.Size  = UDim2.new(rel, 0, 1, 0)
        ValLabel.Text = tostring(currentVal)
        if callback then callback(currentVal) end
    end

    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            UpdateSlider(input.Position.X)
            if not Config.PERF_MODE then
                Tween(SliderKnob, {Size=UDim2.new(0,18,0,18)}, 0.09)
            end
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
        if (input.UserInputType == Enum.UserInputType.MouseButton1
        or  input.UserInputType == Enum.UserInputType.Touch) and isDragging then
            isDragging = false
            if not Config.PERF_MODE then
                Tween(SliderKnob, {Size=UDim2.new(0,16,0,16)}, 0.09)
            end
        end
    end)

    return F, function() return currentVal end
end

-- ── DROPDOWN ────────────────────────────────────────────────────
local function CreateDropdown(parent, titleKey, optionKeys, defaultKey, callback, order)
    local optH   = 30
    local closedH= 44
    local openH  = closedH + #optionKeys * optH

    local DF = Create("Frame", {
        Parent=parent, Size=UDim2.new(1,0,0,closedH),
        BackgroundColor3=Theme.CardColor,
        BackgroundTransparency=Theme.CardTransparency,
        ClipsDescendants=true, LayoutOrder=order or 0,
    })
    Create("UICorner", { CornerRadius=UDim.new(0,10), Parent=DF })

    local TitleLbl = Create("TextLabel", {
        Parent=DF, Size=UDim2.new(1,-60,0,closedH),
        Position=UDim2.new(0,15,0,0),
        BackgroundTransparency=1, TextColor3=Theme.TextColor,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    local extra = { CurrentSelectionKey = defaultKey }
    RegisterTranslation(TitleLbl, "DropdownTitle", titleKey, extra)

    local Arrow = Create("TextLabel", {
        Parent=DF, Size=UDim2.new(0,24,0,24),
        Position=UDim2.new(1,-34,0,10),
        BackgroundTransparency=1, Text="▾",
        TextColor3=Theme.SecondaryText, Font=Enum.Font.GothamBold, TextSize=16,
    })

    local OptContainer = Create("Frame", {
        Parent=DF, Size=UDim2.new(1,0,1,-closedH),
        Position=UDim2.new(0,0,0,closedH),
        BackgroundTransparency=1,
    })
    Create("UIListLayout", { Parent=OptContainer, SortOrder=Enum.SortOrder.LayoutOrder })

    local isOpen = false

    local ToggleBtn = Create("TextButton", {
        Parent=DF, Size=UDim2.new(1,0,0,closedH),
        BackgroundTransparency=1, Text="", ZIndex=DF.ZIndex+2,
    })
    ToggleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local dur = Config.PERF_MODE and 0 or 0.22
        Tween(DF, { Size=UDim2.new(1,0,0, isOpen and openH or closedH) }, dur)
        Tween(Arrow, { Rotation=isOpen and 180 or 0 }, dur)
    end)

    for i, optKey in ipairs(optionKeys) do
        local OptBtn = Create("TextButton", {
            Parent=OptContainer, Size=UDim2.new(1,0,0,optH),
            BackgroundColor3=Theme.DropdownColor, BackgroundTransparency=0.3,
            TextColor3=Theme.SecondaryText, Font=Enum.Font.Gotham,
            TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
            LayoutOrder=i, ZIndex=DF.ZIndex+3,
        })
        RegisterTranslation(OptBtn, "DropdownOption", optKey)

        OptBtn.MouseButton1Click:Connect(function()
            extra.CurrentSelectionKey = optKey
            TitleLbl.Text = (Lang[CurrentLanguage][titleKey] or titleKey)
                         .. ": "
                         .. (Lang[CurrentLanguage][optKey] or optKey)
            isOpen = false
            local dur = Config.PERF_MODE and 0 or 0.18
            Tween(DF, { Size=UDim2.new(1,0,0,closedH) }, dur)
            Tween(Arrow, { Rotation=0 }, dur)
            if callback then callback(optKey) end
        end)

        OptBtn.MouseEnter:Connect(function() Tween(OptBtn,{BackgroundTransparency=0},0.12) end)
        OptBtn.MouseLeave:Connect(function() Tween(OptBtn,{BackgroundTransparency=0.3},0.12) end)
    end

    return DF
end

-- ── SECCIÓN LABEL ────────────────────────────────────────────────
local function CreateSectionLabel(parent, text, order)
    local F = Create("Frame", {
        Parent=parent, Size=UDim2.new(1,0,0,28),
        BackgroundTransparency=1, LayoutOrder=order or 0,
    })
    Create("TextLabel", {
        Parent=F, Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="— " .. text .. " —",
        TextColor3=Theme.AccentColor, Font=Enum.Font.GothamBold,
        TextSize=11, TextXAlignment=Enum.TextXAlignment.Center,
    })
    return F
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │                      TABS                                   │
-- └─────────────────────────────────────────────────────────────┘
local VisualsTab  = CreateTab("TAB_VISUALS",  1)
local CombatTab   = CreateTab("TAB_COMBAT",   2)
local MisticTab   = CreateTab("TAB_MISTIC",   3)
local MovementTab = CreateTab("TAB_MOVEMENT", 4)
local SettingsTab = CreateTab("TAB_SETTINGS", 5)

-- Tab activo por defecto
ActiveTab = "TAB_VISUALS"
TabFrames["TAB_VISUALS"].Visible       = true
Tabs["TAB_VISUALS"].Button.TextColor3  = Theme.AccentColor
Tabs["TAB_VISUALS"].Indicator.Size     = UDim2.new(0.78,0,0,2)

-- ══════════════════════════════════════════════════════════════
-- ██╗   ██╗██╗███████╗██╗   ██╗ █████╗ ██╗     ███████╗███████╗
-- ██║   ██║██║██╔════╝██║   ██║██╔══██╗██║     ██╔════╝██╔════╝
-- ██║   ██║██║███████╗██║   ██║███████║██║     █████╗  ███████╗
-- ╚██╗ ██╔╝██║╚════██║██║   ██║██╔══██║██║     ██╔══╝  ╚════██║
--  ╚████╔╝ ██║███████║╚██████╔╝██║  ██║███████╗███████╗███████║
-- ══════════════════════════════════════════════════════════════

-- ┌─────────────────────────────────────────────────────────────┐
-- │          MÓDULO ESP (Nombres y Salud — sin paredes)         │
-- │  Visible solo a través de BillboardGui con AlwaysOnTop=false│
-- └─────────────────────────────────────────────────────────────┘
local ESP = {
    NamesEnabled    = false,
    HealthEnabled   = false,
    NameBillboards  = {},
    HealthBillboards= {},
    HealthConns     = {},
    Connections     = {},
}

local function ESP_CleanPlayer(player)
    if ESP.NameBillboards[player] then
        pcall(function() ESP.NameBillboards[player]:Destroy() end)
        ESP.NameBillboards[player] = nil
    end
    if ESP.HealthBillboards[player] then
        pcall(function() ESP.HealthBillboards[player]:Destroy() end)
        ESP.HealthBillboards[player] = nil
    end
    if ESP.HealthConns[player] then
        for _, c in pairs(ESP.HealthConns[player]) do
            pcall(function() c:Disconnect() end)
        end
        ESP.HealthConns[player] = nil
    end
end

-- Nombres sobre cabeza
local function ESP_Name_Create(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head or head:FindFirstChild("LXNDXN_Name") then return end

    local bb = Instance.new("BillboardGui")
    bb.Name         = "LXNDXN_Name"
    bb.Size         = UDim2.new(0,200,0,40)
    bb.Adornee      = head
    bb.AlwaysOnTop  = false   -- No atraviesa paredes
    bb.StudsOffset  = Vector3.new(0, 2.8, 0)
    bb.MaxDistance  = 200

    local shadow = Instance.new("TextLabel", bb)
    shadow.Size   = UDim2.new(1,0,1,0)
    shadow.Position = UDim2.new(0,1,0,1)
    shadow.BackgroundTransparency = 1
    shadow.TextColor3 = Color3.new(0,0,0)
    shadow.Text   = player.Name
    shadow.Font   = Enum.Font.GothamBold
    shadow.TextSize = 16

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size    = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextStrokeTransparency = 0.5
    lbl.Text    = player.Name
    lbl.Font    = Enum.Font.GothamBold
    lbl.TextSize = 16

    bb.Parent = head
    ESP.NameBillboards[player] = bb
end

function ESP.StartNames()
    ESP.NamesEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do ESP_Name_Create(p) end
    ESP.Connections["names_added"] = Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
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
    if ESP.Connections["names_added"] then
        pcall(function() ESP.Connections["names_added"]:Disconnect() end)
        ESP.Connections["names_added"] = nil
    end
end

-- Barra de salud sobre cabeza
local function ESP_Health_Create(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head     = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then return end

    if ESP.HealthBillboards[player] then
        pcall(function() ESP.HealthBillboards[player]:Destroy() end)
    end
    if ESP.HealthConns[player] then
        for _, c in pairs(ESP.HealthConns[player]) do pcall(function() c:Disconnect() end) end
    end
    ESP.HealthConns[player] = {}

    local bb = Instance.new("BillboardGui")
    bb.Name        = "LXNDXN_Health"
    bb.Size        = UDim2.new(0,100,0,16)
    bb.Adornee     = head
    bb.AlwaysOnTop = false
    bb.StudsOffset = Vector3.new(0, 4.2, 0)
    bb.MaxDistance = 150

    local barBG = Instance.new("Frame", bb)
    barBG.Size = UDim2.new(1,0,0.6,0)
    barBG.Position = UDim2.new(0,0,0.2,0)
    barBG.BackgroundColor3 = Color3.fromRGB(20,20,20)
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=barBG })

    local function GetHealthColor(pct)
        -- Verde → amarillo → rojo según porcentaje de vida
        local r = math.clamp(2 * (1 - pct), 0, 1)
        local g = math.clamp(2 * pct, 0, 1)
        return Color3.new(r, g, 0.12)
    end

    local pct    = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local barFill = Instance.new("Frame", barBG)
    barFill.Size = UDim2.new(pct, 0, 1, 0)
    barFill.BackgroundColor3 = GetHealthColor(pct)
    Create("UICorner", { CornerRadius=UDim.new(1,0), Parent=barFill })

    local healthText = Instance.new("TextLabel", bb)
    healthText.Size  = UDim2.new(1,0,0.5,0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.new(1,1,1)
    healthText.Text  = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
    healthText.Font  = Enum.Font.GothamBold
    healthText.TextScaled = true

    bb.Parent = head
    ESP.HealthBillboards[player] = bb

    -- Actualización reactiva: solo cuando cambia la vida (no RenderStepped)
    ESP.HealthConns[player].health = humanoid.HealthChanged:Connect(function(hp)
        if not ESP.HealthEnabled then return end
        local p = math.clamp(hp / humanoid.MaxHealth, 0, 1)
        -- Tween suave para la barra
        Tween(barFill, {
            Size=UDim2.new(p,0,1,0),
            BackgroundColor3=GetHealthColor(p),
        }, 0.15)
        healthText.Text = math.floor(hp) .. "/" .. math.floor(humanoid.MaxHealth)
    end)

    ESP.HealthConns[player].removing = player.CharacterRemoving:Connect(function()
        ESP_CleanPlayer(player)
    end)
end

function ESP.StartHealth()
    ESP.HealthEnabled = true
    for _, p in ipairs(Players:GetPlayers()) do
        ESP_Health_Create(p)
        ESP.Connections["hlt_charadded_"..p.UserId] = p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.HealthEnabled then ESP_Health_Create(p) end
        end)
    end
    ESP.Connections["hlt_added"] = Players.PlayerAdded:Connect(function(p)
        ESP.Connections["hlt_charadded_"..p.UserId] = p.CharacterAdded:Connect(function()
            task.wait(0.5)
            if ESP.HealthEnabled then ESP_Health_Create(p) end
        end)
    end)
    ESP.Connections["hlt_removing"] = Players.PlayerRemoving:Connect(ESP_CleanPlayer)
end

function ESP.StopHealth()
    ESP.HealthEnabled = false
    for p, bb in pairs(ESP.HealthBillboards) do
        pcall(function() bb:Destroy() end)
        ESP.HealthBillboards[p] = nil
    end
    for player, conns in pairs(ESP.HealthConns) do
        for _, c in pairs(conns) do pcall(function() c:Disconnect() end) end
        ESP.HealthConns[player] = nil
    end
    for k, c in pairs(ESP.Connections) do
        if k:find("hlt_") then
            pcall(function() c:Disconnect() end)
            ESP.Connections[k] = nil
        end
    end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO FOV CIRCLE (Drawing API)                     │
-- └─────────────────────────────────────────────────────────────┘
local FOVCircle    = nil
local FOVRenderConn= nil

local function StartFOVCircle()
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    FOVCircle              = Drawing.new("Circle")
    FOVCircle.Color        = Color3.fromRGB(220,220,255)
    FOVCircle.Thickness    = 1.2
    FOVCircle.Transparency = 0.82
    FOVCircle.Filled       = false
    FOVCircle.NumSides     = 64
    FOVCircle.Visible      = true

    if FOVRenderConn then FOVRenderConn:Disconnect() end
    FOVRenderConn = RunService.RenderStepped:Connect(function()
        if not Config.SHOW_FOV or not FOVCircle then return end
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius   = Config.FOV_RADIUS
    end)
end

local function StopFOVCircle()
    if FOVRenderConn then FOVRenderConn:Disconnect(); FOVRenderConn = nil end
    if FOVCircle     then pcall(function() FOVCircle:Remove() end); FOVCircle = nil end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │   MÓDULO KATANA STATUS ESP                                  │
-- └─────────────────────────────────────────────────────────────┘
local KatanaESP = { Active=false, Billboards={} }

local function KatanaESP_Create(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name        = "LXNDXN_KatanaStatus"
    bb.Size        = UDim2.new(0,120,0,20)
    bb.Adornee     = head
    bb.AlwaysOnTop = false
    bb.StudsOffset = Vector3.new(0, 5.5, 0)
    bb.MaxDistance = 100

    local label = Instance.new("TextLabel", bb)
    label.Size   = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Font   = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(80,255,80)
    label.Text   = "✓ SAFE"

    bb.Parent = head
    KatanaESP.Billboards[player] = bb

    -- Polling de herramienta equipada
    task.spawn(function()
        while KatanaESP.Active and bb.Parent do
            task.wait(0.18)
            local hasKatana = false
            if player.Character then
                local tool = player.Character:FindFirstChildOfClass("Tool")
                -- Ajusta el nombre de la katana de tu juego aquí:
                hasKatana = tool ~= nil and tool.Name:lower():find("katana") ~= nil
            end
            label.Text = hasKatana and "⚔ KATANA" or "✓ SAFE"
            label.TextColor3 = hasKatana
                and Color3.fromRGB(255,80,80)
                or  Color3.fromRGB(80,255,80)
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

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO TRIGGER BOT                                  │
-- │  CONEXIÓN PARA SILENT AIM:                                  │
-- │  Si tu SA ya seleccionó un objetivo, puedes reutilizar      │
-- │  GetBestTarget() aquí para disparar solo cuando el          │
-- │  cursor esté sobre él, evitando llamadas redundantes.       │
-- └─────────────────────────────────────────────────────────────┘
local TriggerBot = { Active=false, Thread=nil }

function TriggerBot.Enable()
    TriggerBot.Active = true
    TriggerBot.Thread = task.spawn(function()
        while TriggerBot.Active do
            task.wait(0.05)
            -- Tolerancia de 12px para evitar disparos accidentales
            local target, _, score = GetBestTarget(12)
            if target then
                -- Aquí conecta tu lógica de disparo del juego.
                -- Ejemplo conceptual:
                --   WeaponModule:Fire()
                --   mouse:Button1Click()
                EventBus:Fire("TriggerBotFired", target)
            end
        end
    end)
end

function TriggerBot.Disable()
    TriggerBot.Active = false
    if TriggerBot.Thread then task.cancel(TriggerBot.Thread); TriggerBot.Thread = nil end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO VUELO — Física mejorada                      │
-- │                                                             │
-- │  Mejoras respecto a v3:                                     │
-- │  - Aceleración suave con Lerp en vez de velocidad abrupta   │
-- │  - Desaceleración gradual al soltar teclas                  │
-- │  - Soporte para Shift → boost de velocidad                  │
-- │  - BodyVelocity + BodyGyro correctamente limpiados          │
-- └─────────────────────────────────────────────────────────────┘
local FlyModule = {
    Active       = false,
    BodyVelocity = nil,
    BodyGyro     = nil,
    RenderConn   = nil,
    CurrentVel   = Vector3.zero,
}

function FlyModule.Enable()
    if FlyModule.Active then return end
    FlyModule.Active = true
    FlyModule.CurrentVel = Vector3.zero

    local char     = LocalPlayer.Character
    if not char then FlyModule.Active = false; return end
    local hrp      = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp then FlyModule.Active = false; return end

    local bv     = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.zero
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.P         = 1250
    bv.Parent    = hrp
    FlyModule.BodyVelocity = bv

    local bg         = Instance.new("BodyGyro")
    bg.MaxTorque     = Vector3.new(1e5, 1e5, 1e5)
    bg.P             = 8000
    bg.D             = 120
    bg.Parent        = hrp
    FlyModule.BodyGyro = bg

    if humanoid then humanoid.PlatformStand = true end

    FlyModule.RenderConn = RunService.RenderStepped:Connect(function(dt)
        if not FlyModule.Active then return end

        local speed   = Config.FLY_SPEED
        local accel   = Config.FLY_ACCEL  -- suavidad 1–20
        local camCF   = Camera.CFrame
        local target  = Vector3.zero
        local boost   = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 2.2 or 1.0

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            target = target + camCF.LookVector * speed * boost
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            target = target - camCF.LookVector * speed * boost
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            target = target - camCF.RightVector * speed * boost
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            target = target + camCF.RightVector * speed * boost
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            target = target + Vector3.new(0, speed * boost, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            target = target - Vector3.new(0, speed * boost, 0)
        end

        -- Lerp suave: accel controla qué tan rápido se alcanza la velocidad objetivo
        local lerpFactor = math.clamp(dt * accel, 0, 1)
        FlyModule.CurrentVel  = LerpV3(FlyModule.CurrentVel, target, lerpFactor)
        bv.Velocity           = FlyModule.CurrentVel

        -- Apunta el personaje hacia donde mira la cámara
        bg.CFrame = CFrame.new(hrp.Position, hrp.Position + camCF.LookVector)
    end)
end

function FlyModule.Disable()
    FlyModule.Active = false
    FlyModule.CurrentVel = Vector3.zero

    if FlyModule.RenderConn then
        FlyModule.RenderConn:Disconnect(); FlyModule.RenderConn = nil
    end
    if FlyModule.BodyVelocity then
        pcall(function() FlyModule.BodyVelocity:Destroy() end)
        FlyModule.BodyVelocity = nil
    end
    if FlyModule.BodyGyro then
        pcall(function() FlyModule.BodyGyro:Destroy() end)
        FlyModule.BodyGyro = nil
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO ANTI-KATANA                                  │
-- └─────────────────────────────────────────────────────────────┘
local AntiKatana = { Active=false, Thread=nil }

function AntiKatana.Enable()
    AntiKatana.Active = true
    AntiKatana.Thread = task.spawn(function()
        while AntiKatana.Active do
            task.wait(0.08)
            --[[
                Conecta aquí la lógica de detección de tu juego.
                Ejemplo para detectar animación de katana:

                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local animator = player.Character:FindFirstChildOfClass("Animator")
                        if animator then
                            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                if track.Animation.AnimationId == "TU_ID_DE_ANIMACION" then
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
    if AntiKatana.Thread then task.cancel(AntiKatana.Thread); AntiKatana.Thread = nil end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO RESOLVER                                     │
-- │  Historial de ángulos con ventana deslizante (mejorado)     │
-- └─────────────────────────────────────────────────────────────┘
local Resolver = {
    Active         = false,
    AngleHistory   = {},   -- [player] = { angle, timestamp }[]
    WINDOW_SIZE    = 12,   -- últimos N ángulos a considerar
}

--[[
    GetResolvedAngle(player)
    Devuelve el ángulo Y predicho basado en tendencia lineal.
    Úsalo desde tu Silent Aim para ajustar el aim_dir:
        local resolvedAngle = Resolver.GetResolvedAngle(targetPlayer)
        if resolvedAngle then
            -- aplica offset de ángulo al targetPart.CFrame
        end
]]
function Resolver.GetResolvedAngle(player)
    local hist = Resolver.AngleHistory[player]
    if not hist or #hist < 3 then return nil end

    -- Regresión lineal simple sobre los últimos N ángulos
    local n   = #hist
    local sumX, sumY, sumXY, sumX2 = 0, 0, 0, 0
    for i, entry in ipairs(hist) do
        sumX  = sumX  + i
        sumY  = sumY  + entry.angle
        sumXY = sumXY + i * entry.angle
        sumX2 = sumX2 + i * i
    end
    local denom = (n * sumX2 - sumX * sumX)
    if denom == 0 then return hist[n].angle end

    local slope = (n * sumXY - sumX * sumY) / denom
    -- Predice el siguiente paso
    return hist[n].angle + slope
end

function Resolver.Enable()
    Resolver.Active = true
    task.spawn(function()
        while Resolver.Active do
            task.wait(0.05)
            local now = tick()
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local _, angleY, _ = hrp.CFrame:ToEulerAnglesYXZ()
                        local hist = Resolver.AngleHistory[player] or {}
                        table.insert(hist, { angle=angleY, t=now })
                        -- Ventana deslizante: solo mantiene los últimos N
                        while #hist > Resolver.WINDOW_SIZE do
                            table.remove(hist, 1)
                        end
                        Resolver.AngleHistory[player] = hist
                    end
                end
            end
        end
    end)
end

function Resolver.Disable()
    Resolver.Active       = false
    Resolver.AngleHistory = {}
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO ANTI-LOCK                                    │
-- └─────────────────────────────────────────────────────────────┘
local AntiLock = { Active=false, Thread=nil }

function AntiLock.Enable()
    AntiLock.Active = true
    AntiLock.Thread = task.spawn(function()
        local phase = 0
        while AntiLock.Active do
            task.wait(0.025)
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    -- Movimiento sinusoidal micro para dificultar lock-on
                    -- Amplitud muy pequeña para no afectar gameplay visible
                    phase = phase + 0.18
                    local offset = math.sin(phase) * 0.04
                    -- Aplica como sustituto de CFrame:
                    -- hrp.CFrame = hrp.CFrame * CFrame.Angles(0, offset, 0)
                    -- (Descomenta si tu juego lo permite sin sanción del servidor)
                    _ = offset  -- placeholder hasta que lo conectes
                end
            end
        end
    end)
end

function AntiLock.Disable()
    AntiLock.Active = false
    if AntiLock.Thread then task.cancel(AntiLock.Thread); AntiLock.Thread = nil end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO PREDICCIÓN DE MOVIMIENTO                     │
-- │                                                             │
-- │  CONEXIÓN CON SILENT AIM:                                   │
-- │  1. Llama Prediction.Enable() al activar SA.               │
-- │  2. Usa predictPosition(part) (definido arriba) en tu      │
-- │     redirectArguments() para targetPos.                     │
-- │  3. Si quieres la velocidad cacheada directamente:          │
-- │       local vel = Prediction.VelCache[player]              │
-- └─────────────────────────────────────────────────────────────┘
local Prediction = {
    Active   = false,
    VelCache = {},   -- [player] = Vector3
}

function Prediction.Enable()
    Prediction.Active = true
    task.spawn(function()
        local lastPos = {}
        while Prediction.Active do
            local dt = task.wait(0.05)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local cur = hrp.Position
                        if lastPos[player] then
                            -- Velocidad promediada con el cache anterior
                            -- para reducir ruido de red (ping jitter)
                            local rawVel = (cur - lastPos[player]) / dt
                            local prev   = Prediction.VelCache[player] or rawVel
                            -- EMA (exponential moving average) con α=0.35
                            Prediction.VelCache[player] = prev + (rawVel - prev) * 0.35
                        end
                        lastPos[player] = cur
                    end
                end
            end
        end
    end)
end

function Prediction.Disable()
    Prediction.Active = false
    Prediction.VelCache = {}
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         MÓDULO PERSISTENCIA DE CONFIGURACIÓN                │
-- └─────────────────────────────────────────────────────────────┘
local CONFIG_FILE = "LXNDXN_v4_config.json"

local function SaveConfig()
    local ok, json = pcall(function() return HttpService:JSONEncode(Config) end)
    if not ok then warn("[LXNDXN] Error al serializar:", json); return end
    local ok2, err = pcall(function() writefile(CONFIG_FILE, json) end)
    if ok2 then
        print("[LXNDXN] Config guardada.")
        EventBus:Fire("ConfigSaved")
    else
        warn("[LXNDXN] writefile no disponible:", err)
    end
end

local function LoadConfig()
    local ok, content = pcall(function() return readfile(CONFIG_FILE) end)
    if not ok or not content then warn("[LXNDXN] Config no encontrada."); return nil end

    local ok2, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 or type(decoded) ~= "table" then warn("[LXNDXN] Config corrupta."); return nil end

    -- Solo aplica claves existentes en Config (seguro contra inyección)
    for k, v in pairs(decoded) do
        if Config[k] ~= nil and type(Config[k]) == type(v) then
            Config[k] = v
        end
    end
    print("[LXNDXN] Config cargada.")
    EventBus:Fire("ConfigLoaded", decoded)
    return decoded
end

-- ══════════════════════════════════════════════════════════════
-- POBLACIÓN DE TABS
-- ══════════════════════════════════════════════════════════════

-- ── TAB VISUALES ────────────────────────────────────────────────
CreateSectionLabel(VisualsTab, "ESP FEATURES", 1)

CreateToggle(VisualsTab, "ESP_NAMES", function(state)
    Config.ESP_NAMES = state
    if state then ESP.StartNames() else ESP.StopNames() end
end, 2)

CreateToggle(VisualsTab, "ESP_HEALTH", function(state)
    Config.ESP_HEALTH = state
    if state then ESP.StartHealth() else ESP.StopHealth() end
end, 3)

CreateToggle(VisualsTab, "KATANA_STATUS", function(state)
    Config.KATANA_STATUS = state
    if state then KatanaESP.Enable() else KatanaESP.Disable() end
end, 4)

-- ── TAB COMBATE ─────────────────────────────────────────────────
CreateSectionLabel(CombatTab, "TARGETING", 1)

--[[
╔══════════════════════════════════════════════════════════════════╗
║                  ZONA DE CONEXIÓN: SILENT AIM                   ║
║                                                                  ║
║  Cuando termines tu módulo de Silent Aim, agrégalo aquí:        ║
║                                                                  ║
║  1. Importa / define tu SilentAim = { Enable=..., Disable=... } ║
║     antes de esta sección.                                       ║
║                                                                  ║
║  2. Descomenta los bloques de toggle y dropdown de abajo.        ║
║                                                                  ║
║  3. Agrega las claves a Config (al inicio del script):           ║
║       SILENT_AIM      = false,                                   ║
║       SILENT_AIM_DIR  = "DIR_HEAD",                              ║
║       HIT_CHANCE_ON   = false,                                   ║
║       HIT_CHANCE_VAL  = 100,                                     ║
║       PREDICTION      = false,                                   ║
║                                                                  ║
║  4. Agrega las claves al sistema de idioma en cada tabla         ║
║     de Lang (ya están incluidas como referencia arriba).         ║
║                                                                  ║
║  FUNCIONES DISPONIBLES PARA TU SA:                               ║
║    GetBestTarget(radius)  → player, part, score                  ║
║    predictPosition(part)  → Vector3                              ║
║    Prediction.VelCache[player] → Vector3 velocidad               ║
║    Resolver.GetResolvedAngle(player) → number                    ║
╚══════════════════════════════════════════════════════════════════╝
]]

local aimDropdown
local _, setAimToggle = CreateToggle(CombatTab, "SILENT_AIM", function(state)
    Config.SILENT_AIM = state
    aimDropdown.Visible = state
    if state then
        Prediction.Enable()
        SilentAim.Enable()
    else
        SilentAim.Disable()
        Prediction.Disable()
    end
end, 2)

aimDropdown = CreateDropdown(CombatTab, "DIR_TITLE",
    {"DIR_HEAD", "DIR_CHEST", "DIR_ALL"},
    "DIR_HEAD",
    function(selKey) Config.SILENT_AIM_DIR = selKey end,
    3
)
aimDropdown.Visible = false

local hitChanceSlider
CreateToggle(CombatTab, "HIT_CHANCE_ON", function(state)
    Config.HIT_CHANCE_ON = state
    hitChanceSlider.Visible = state
end, 4)
hitChanceSlider, _ = CreateSlider(CombatTab, "HIT_CHANCE_VAL", 0, 100, 100, function(val)
    Config.HIT_CHANCE_VAL = val
end, 5)
hitChanceSlider.Visible = false

CreateToggle(CombatTab, "PREDICTION", function(state)
    Config.PREDICTION = state
end, 6)

-- FOV
CreateSectionLabel(CombatTab, "FOV", 7)

local fovSlider
CreateToggle(CombatTab, "SHOW_FOV", function(state)
    Config.SHOW_FOV = state
    fovSlider.Visible = state
    if state then StartFOVCircle() else StopFOVCircle() end
end, 7)

fovSlider, _ = CreateSlider(CombatTab, "FOV_RADIUS", 10, 600, 80, function(val)
    Config.FOV_RADIUS = val
    if FOVCircle then FOVCircle.Radius = val end
end, 8)
fovSlider.Visible = false

CreateToggle(CombatTab, "TRIGGER_BOT", function(state)
    Config.TRIGGER_BOT = state
    if state then TriggerBot.Enable() else TriggerBot.Disable() end
end, 9)

-- ── TAB MÍSTICO ─────────────────────────────────────────────────
CreateSectionLabel(MisticTab, "DEFENSIVE", 1)

CreateToggle(MisticTab, "ANTI_KATANA", function(state)
    Config.ANTI_KATANA = state
    if state then AntiKatana.Enable() else AntiKatana.Disable() end
end, 2)

CreateToggle(MisticTab, "RESOLVER", function(state)
    Config.RESOLVER = state
    if state then Resolver.Enable() else Resolver.Disable() end
end, 3)

CreateToggle(MisticTab, "ANTI_LOCK", function(state)
    Config.ANTI_LOCK = state
    if state then AntiLock.Enable() else AntiLock.Disable() end
end, 4)

-- ── TAB MOVIMIENTO ──────────────────────────────────────────────
CreateSectionLabel(MovementTab, "SPEED", 1)

local speedSlider
CreateToggle(MovementTab, "MOD_SPEED", function(state)
    Config.MOD_SPEED = state
    speedSlider.Visible = state
    if not state then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end
end, 2)

speedSlider, _ = CreateSlider(MovementTab, "WALK_SPEED", 0, 500, 16, function(val)
    Config.WALK_SPEED = val
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end, 3)
speedSlider.Visible = false

CreateSectionLabel(MovementTab, "FLY", 4)

local flySpeedSlider, flyAccelSlider
CreateToggle(MovementTab, "FLY_ON", function(state)
    Config.FLY_ON = state
    flySpeedSlider.Visible = state
    flyAccelSlider.Visible = state
    if state then FlyModule.Enable() else FlyModule.Disable() end
end, 5)

flySpeedSlider, _ = CreateSlider(MovementTab, "FLY_SPEED", 5, 600, 50, function(val)
    Config.FLY_SPEED = val
end, 6)
flySpeedSlider.Visible = false

flyAccelSlider, _ = CreateSlider(MovementTab, "FLY_ACCEL", 1, 20, 12, function(val)
    Config.FLY_ACCEL = val
end, 7)
flyAccelSlider.Visible = false

-- Persistencia al respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Config.MOD_SPEED then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.WALK_SPEED end
    end
    if Config.FLY_ON then
        task.wait(0.6)
        FlyModule.Enable()
    end
end)

-- ── TAB AJUSTES ─────────────────────────────────────────────────
CreateSectionLabel(SettingsTab, "CONFIG", 1)

local _, setSaveToggle = CreateToggle(SettingsTab, "SAVE_CFG", function(state)
    if state then
        SaveConfig()
        task.delay(0.6, function()
            if setSaveToggle then setSaveToggle(false, true) end
        end)
    end
end, 2)

local _, setLoadToggle = CreateToggle(SettingsTab, "LOAD_CFG", function(state)
    if state then
        LoadConfig()
        task.delay(0.6, function()
            if setLoadToggle then setLoadToggle(false, true) end
        end)
    end
end, 3)

CreateToggle(SettingsTab, "AUTO_LOAD", function(state)
    Config.AUTO_LOAD = state
end, 4)

CreateToggle(SettingsTab, "PERF_MODE", function(state)
    Config.PERF_MODE = state
    if state then
        if pulseTween then pulseTween:Cancel() end
        FloatButton.BackgroundTransparency = 0.15
    else
        StartButtonPulse()
    end
end, 5)

CreateSectionLabel(SettingsTab, "BUTTON", 6)

CreateToggle(SettingsTab, "PIN_BTN", function(state)
    Config.PIN_BTN = state
    ButtonIsFixed  = state
end, 7)

CreateToggle(SettingsTab, "HIDE_BTN", function(state)
    Config.HIDE_BTN = state
    local dur = Config.PERF_MODE and 0 or 0.28
    if state then
        Tween(FloatButton, {BackgroundTransparency=1, TextTransparency=1}, dur)
        Tween(FloatStroke,  {Transparency=1}, dur)
    else
        Tween(FloatButton, {BackgroundTransparency=0.15, TextTransparency=0}, dur)
        Tween(FloatStroke,  {Transparency=0.7}, dur)
    end
end, 8)

CreateSectionLabel(SettingsTab, "LANGUAGE", 9)

-- Dropdown de idioma
do
    local langOptH  = 30
    local langClosed = 44
    local langOpts   = {
        { name="Español",   key="Español"  },
        { name="English",   key="Inglés"   },
        { name="Português", key="Portugués"},
        { name="Русский",   key="Ruso"     },
        { name="پښتو",      key="Pastún"   },
    }
    local langOpen   = langClosed + #langOpts * langOptH

    local LDF = Create("Frame", {
        Parent=SettingsTab, Size=UDim2.new(1,0,0,langClosed),
        BackgroundColor3=Theme.CardColor,
        BackgroundTransparency=Theme.CardTransparency,
        ClipsDescendants=true, LayoutOrder=10,
    })
    Create("UICorner", { CornerRadius=UDim.new(0,10), Parent=LDF })

    local LTitle = Create("TextLabel", {
        Parent=LDF, Size=UDim2.new(1,-60,0,langClosed),
        Position=UDim2.new(0,15,0,0),
        BackgroundTransparency=1, TextColor3=Theme.TextColor,
        Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    local lextra = { CurrentSelectionKey = Config.LANGUAGE }
    RegisterTranslation(LTitle, "DropdownTitle", "LANG_TITLE", lextra)

    local LArrow = Create("TextLabel", {
        Parent=LDF, Size=UDim2.new(0,24,0,24),
        Position=UDim2.new(1,-34,0,10),
        BackgroundTransparency=1, Text="▾",
        TextColor3=Theme.SecondaryText, Font=Enum.Font.GothamBold, TextSize=16,
    })
    local LC = Create("Frame", {
        Parent=LDF, Size=UDim2.new(1,0,1,-langClosed),
        Position=UDim2.new(0,0,0,langClosed),
        BackgroundTransparency=1,
    })
    Create("UIListLayout", { Parent=LC, SortOrder=Enum.SortOrder.LayoutOrder })

    local LToggle = Create("TextButton", {
        Parent=LDF, Size=UDim2.new(1,0,0,langClosed),
        BackgroundTransparency=1, Text="", ZIndex=LDF.ZIndex+2,
    })
    local lIsOpen = false
    LToggle.MouseButton1Click:Connect(function()
        lIsOpen = not lIsOpen
        local dur = Config.PERF_MODE and 0 or 0.22
        Tween(LDF,    { Size=UDim2.new(1,0,0, lIsOpen and langOpen or langClosed) }, dur)
        Tween(LArrow, { Rotation=lIsOpen and 180 or 0 }, dur)
    end)

    for i, opt in ipairs(langOpts) do
        local OB = Create("TextButton", {
            Parent=LC, Size=UDim2.new(1,0,0,langOptH),
            BackgroundColor3=Theme.DropdownColor, BackgroundTransparency=0.3,
            Text="  "..opt.name, TextColor3=Theme.SecondaryText,
            Font=Enum.Font.Gotham, TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left,
            LayoutOrder=i, ZIndex=LDF.ZIndex+3,
        })
        OB.MouseEnter:Connect(function() Tween(OB,{BackgroundTransparency=0},0.12) end)
        OB.MouseLeave:Connect(function() Tween(OB,{BackgroundTransparency=0.3},0.12) end)
        OB.MouseButton1Click:Connect(function()
            UpdateLanguage(opt.key)
            lextra.CurrentSelectionKey = opt.name
            LTitle.Text = (Lang[CurrentLanguage]["LANG_TITLE"] or "Language") .. ": " .. opt.name
            lIsOpen = false
            local dur = Config.PERF_MODE and 0 or 0.18
            Tween(LDF,    { Size=UDim2.new(1,0,0,langClosed) }, dur)
            Tween(LArrow, { Rotation=0 }, dur)
        end)
    end
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │         ANTI-CHEAT SERVER-SIDE (MEJORADO)                   │
-- │                                                             │
-- │  Mejoras respecto a v3:                                     │
-- │  - Tolerancia de velocidad considera JumpPower real         │
-- │  - Tolerancia vertical separada del plano horizontal        │
-- │  - Decay de warnings basado en tiempo real (no framerate)   │
-- │  - Cooldown de kick por jugador para evitar falsos kick      │
-- │  - Rate limit con ventana deslizante más precisa            │
-- └─────────────────────────────────────────────────────────────┘
if not LocalPlayer then
    local AC = {}
    AC.__index = AC

    local AC_CFG = {
        MaxHorizontalSpeed  = 28,    -- studs/s horizontal
        MaxVerticalSpeed    = 120,   -- studs/s vertical (permite salto + plataformas)
        MaxWarnings         = 5,     -- warnings antes del kick
        WarningDecayRate    = 0.08,  -- warnings/segundo que se perdonan
        RateLimitPerSecond  = 12,
        KickCooldown        = 10,    -- segundos entre kicks del mismo jugador
        CheckInterval       = 0.1,   -- segundos entre chequeos de movimiento
    }

    local PlayerData = {}

    local function AC_InitPlayer(player)
        PlayerData[player.UserId] = {
            LastPosition     = nil,
            LastCheckTime    = tick(),
            LastWarningTime  = tick(),
            Warnings         = 0,
            -- Rate limit con ventana deslizante
            RequestTimestamps = {},
            LastKickTime     = 0,
        }
        player.CharacterAdded:Connect(function(char)
            local d = PlayerData[player.UserId]
            if not d then return end
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                d.LastPosition  = hrp.Position
                d.LastCheckTime = tick()
                d.Warnings      = 0  -- reset al respawn
            end
        end)
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                PlayerData[player.UserId].LastPosition  = hrp.Position
                PlayerData[player.UserId].LastCheckTime = tick()
            end
        end
    end

    local function AC_RemovePlayer(player)
        PlayerData[player.UserId] = nil
    end

    local function AC_KickPlayer(player, reason)
        local d = PlayerData[player.UserId]
        if not d then return end
        local now = tick()
        if now - d.LastKickTime < AC_CFG.KickCooldown then return end
        d.LastKickTime = now
        pcall(function() player:Kick("Comportamiento anómalo detectado (" .. reason .. ")") end)
    end

    -- Chequeo de movimiento: horizontal y vertical separados
    local lastBatchCheck = tick()
    RunService.Heartbeat:Connect(function()
        local now = tick()
        -- Solo corre cada CheckInterval segundos
        if now - lastBatchCheck < AC_CFG.CheckInterval then return end
        lastBatchCheck = now

        for _, player in ipairs(Players:GetPlayers()) do
            local d   = PlayerData[player.UserId]
            local char = player.Character
            if not d or not char then continue end

            local hrp      = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not humanoid or humanoid.Health <= 0 then continue end

            local dt = now - d.LastCheckTime
            if dt < 0.05 or dt > 2.0 then
                -- dt muy pequeño → ruido; dt muy grande → respawn o lag
                d.LastPosition  = hrp.Position
                d.LastCheckTime = now
                continue
            end

            local cur  = hrp.Position
            local last = d.LastPosition or cur
            local delta = cur - last

            -- Separar velocidad horizontal y vertical
            local horzSpeed = Vector2.new(delta.X, delta.Z).Magnitude / dt
            local vertSpeed = math.abs(delta.Y) / dt

            -- Tolerancia horizontal: WalkSpeed del humanoid + margen de red
            local maxHorz = math.max(humanoid.WalkSpeed * 1.35, AC_CFG.MaxHorizontalSpeed)

            local flagged = false

            if horzSpeed > maxHorz then
                d.Warnings = d.Warnings + 1.5
                warn(string.format(
                    "[AC] %s: speedhack horizontal %.1f studs/s (max %.1f)",
                    player.Name, horzSpeed, maxHorz
                ))
                -- Rubber-band al último punto válido
                pcall(function() hrp.CFrame = CFrame.new(last) end)
                flagged = true
            end

            if vertSpeed > AC_CFG.MaxVerticalSpeed then
                d.Warnings = d.Warnings + 1.0
                warn(string.format(
                    "[AC] %s: velocidad vertical anómala %.1f studs/s",
                    player.Name, vertSpeed
                ))
                flagged = true
            end

            if not flagged then
                -- Decay proporcional al tiempo real (no al framerate)
                d.Warnings = math.max(0, d.Warnings - AC_CFG.WarningDecayRate * dt)
                d.LastPosition = cur
            end

            d.LastCheckTime = now

            if d.Warnings >= AC_CFG.MaxWarnings then
                AC_KickPlayer(player, "M-01")
                d.Warnings = 0
            end
        end
    end)

    -- Rate limit con ventana deslizante de 1 segundo
    local function AC_ValidateRemote(player)
        local d = PlayerData[player.UserId]
        if not d then return false end
        local now = tick()
        -- Elimina timestamps fuera de la ventana de 1s
        local window = {}
        for _, t in ipairs(d.RequestTimestamps) do
            if now - t <= 1.0 then table.insert(window, t) end
        end
        table.insert(window, now)
        d.RequestTimestamps = window

        if #window > AC_CFG.RateLimitPerSecond then
            warn("[AC] " .. player.Name .. ": rate limit excedido (" .. #window .. " req/s)")
            return false
        end
        return true
    end

    Players.PlayerAdded:Connect(AC_InitPlayer)
    Players.PlayerRemoving:Connect(AC_RemovePlayer)
    for _, p in ipairs(Players:GetPlayers()) do AC_InitPlayer(p) end

    -- Expón la función de validación para tus RemoteEvents:
    --   if not AC_ValidateRemote(player) then return end
    _G.AC_ValidateRemote = AC_ValidateRemote

    print("[LXNDXN] Anti-Cheat servidor inicializado.")
end

-- ┌─────────────────────────────────────────────────────────────┐
-- │                  AUTO-LOAD AL INICIAR                       │
-- └─────────────────────────────────────────────────────────────┘
task.spawn(function()
    task.wait(0.8)
    local loaded = LoadConfig()
    if loaded and loaded.AUTO_LOAD then
        print("[LXNDXN] Auto-Load: config restaurada.")
        -- Aquí puedes re-activar módulos según el config cargado:
        EventBus:Fire("ConfigApply", loaded)
    end
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │                 NOTIFICACIÓN DE CARGA                       │
-- └─────────────────────────────────────────────────────────────┘
local function ShowNotification(message, duration)
    duration = duration or 3.5
    local N = Create("Frame", {
        Parent=ScreenGui, Size=UDim2.new(0,290,0,48),
        Position=UDim2.new(0.5,-145, 1, 0),
        BackgroundColor3=Theme.AccentColor,
        BackgroundTransparency=0.08, ZIndex=100,
    })
    Create("UICorner", { CornerRadius=UDim.new(0,10), Parent=N })
    Create("TextLabel", {
        Parent=N, Size=UDim2.new(1,-20,1,0),
        Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=message,
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold,
        TextSize=13, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=101,
    })
    Tween(N, {Position=UDim2.new(0.5,-145, 1,-60)}, 0.38, Enum.EasingStyle.Back)
    task.delay(duration, function()
        Tween(N, {Position=UDim2.new(0.5,-145, 1,12), BackgroundTransparency=1}, 0.28)
        task.delay(0.32, function() N:Destroy() end)
    end)
end

task.delay(0.6, function()
    ShowNotification("⚡ LXNDXN v4.0 cargado — INSERT para abrir", 4)
end)

-- ┌─────────────────────────────────────────────────────────────┐
-- │               LIMPIEZA AL DESTRUIR EL GUI                   │
-- └─────────────────────────────────────────────────────────────┘
ScreenGui.AncestryChanged:Connect(function()
    if ScreenGui.Parent then return end
    -- Detiene todos los módulos activos
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
    -- Limpia todas las conexiones ESP
    for _, c in pairs(ESP.Connections) do
        pcall(function() c:Disconnect() end)
    end
    print("[LXNDXN] UI destruida — todos los módulos detenidos.")
end)

-- ══════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT — LXNDXN UI Framework v4.0
-- Agrega tu módulo Silent Aim en la zona marcada del Tab Combate
-- ══════════════════════════════════════════════════════════════
print("╔══════════════════════════════════════╗")
print("║      LXNDXN UI v4.0  LOADED         ║")
print("║  INSERT → abrir/cerrar menú          ║")
print("║  Shift+Volar → boost de velocidad    ║")
print("╚══════════════════════════════════════╝")
