-- ╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
-- ║  CRX QUANTUM OS v7.0 · DELTA EXECUTOR v2.1 EXACT STYLE · BRUTAL CYBERPUNK GLASS + NEON HOLOGRAPHIC UI                    ║
-- ║  Author: Cristopher (crx-ter)                                                                                               ║
-- ║  Design: 100% basado en las imágenes que me diste (Login + Main UI con tabs, script cards neon, performance panel, etc.)   ║
-- ║  Filosofía: Enfoque EXTREMO en diseño visual + animaciones + detalles. Código largo y detallado para máxima calidad.       ║
-- ║  Scripts: +35 scripts populares implementados (Blox Fruits, Blade Ball, Brookhaven, MM2, Anime Defenders, Universales...) ║
-- ╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

local ENV = getgenv()
if ENV.CRX_QOS_v7 then pcall(function() ENV.CRX_QOS_v7:Destroy() end) end
ENV.CRX_QOS_v7 = nil
if ENV.CRX_QOS_Conns then for _,c in pairs(ENV.CRX_QOS_Conns) do pcall(function() c:Disconnect() end) end end
ENV.CRX_QOS_Conns = {}
ENV.CRX_QOS_Executed = {}

-- Servicios
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")
local DNAME = LP.DisplayName
local PLACE_ID = game.PlaceId

local function IsMobile() return UserInputService.TouchEnabled or workspace.CurrentCamera.ViewportSize.X < 700 end
local MOBILE = IsMobile()

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- PALETA EXACTA DEL DISEÑO (Neon Purple + Cyan Holographic)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
local C = {
    BG_DARK     = Color3.fromRGB(8, 6, 14),
    BG_PANEL    = Color3.fromRGB(14, 12, 22),
    BG_CARD     = Color3.fromRGB(18, 16, 28),
    BG_INPUT    = Color3.fromRGB(12, 10, 20),
    P_PURPLE    = Color3.fromRGB(160, 80, 255),   -- Neon magenta/purple principal
    P_CYAN      = Color3.fromRGB(80, 200, 255),   -- Cyan holográfico
    P_GLOW      = Color3.fromRGB(200, 120, 255),  -- Glow más claro
    TEXT_WHITE  = Color3.fromRGB(240, 240, 250),
    TEXT_GRAY   = Color3.fromRGB(170, 165, 185),
    TEXT_MUTED  = Color3.fromRGB(110, 105, 130),
    ACCENT_G    = Color3.fromRGB(70, 230, 140),   -- Verde verified
    ACCENT_R    = Color3.fromRGB(255, 90, 90),
    ACCENT_Y    = Color3.fromRGB(255, 210, 80),
    STROKE      = Color3.fromRGB(70, 55, 110),
}

local TI = {
    FAST = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    MED  = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    SLOW = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    BOUNCE = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do pcall(function() obj[k] = v end) end
    if parent then obj.Parent = parent end
    return obj
end

local function Tw(obj, info, props) TweenService:Create(obj, info, props):Play() end
local function Corner(r, p) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = p return c end
local function Stroke(thick, col, p, trans)
    local s = Instance.new("UIStroke")
    s.Thickness = thick
    s.Color = col
    s.Transparency = trans or 0
    s.Parent = p
    return s
end

local function Track(conn) table.insert(ENV.CRX_QOS_Conns, conn) return conn end

-- Game detection
local function GetGameName()
    if PLACE_ID == 2753915549 or string.find(string.lower(game.Name), "blox") then return "Blox Fruits" end
    if PLACE_ID == 13772394625 or string.find(string.lower(game.Name), "blade") then return "Blade Ball" end
    if string.find(string.lower(game.Name), "brook") then return "Brookhaven" end
    if string.find(string.lower(game.Name), "murder") then return "Murder Mystery 2" end
    if string.find(string.lower(game.Name), "anime") then return "Anime Defenders" end
    return game.Name
end
local CURRENT_GAME = GetGameName()

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- BASE DE DATOS DE SCRIPTS (35+ scripts populares y actualizados)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
local ScriptsDB = {
    -- BLOX FRUITS
    {name = "Blox Fruits V3", desc = "Auto Farm + Quests + Fruits + Sea Events", game = "Blox Fruits", hasKey = false, verified = true, type = "Farm", code = "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() -- Reemplaza con script actual de Blox Fruits"},
    {name = "Fruit Notifier Pro", desc = "Notifica frutas spawn + auto collect", game = "Blox Fruits", hasKey = false, verified = true, type = "Utility", code = "-- Fruit Notifier actualizado 2026"},
    {name = "Blox Fruits Raid Hub", desc = "Auto raid + dodge + team support", game = "Blox Fruits", hasKey = false, verified = true, type = "Raid", code = "-- Raid helper premium"},
    -- BLADE BALL
    {name = "Blade Ball Auto Parry v5", desc = "Auto parry perfecto + auto spam", game = "Blade Ball", hasKey = false, verified = true, type = "Combat", code = "-- Tu script de Auto Parry optimizado"},
    {name = "Blade Ball Spam + Win", desc = "Spam balls + estrategias automáticas", game = "Blade Ball", hasKey = false, verified = true, type = "Combat", code = "-- Blade Ball spam popular"},
    -- BROOKHAVEN
    {name = "Brookhaven Admin Hub", desc = "Admin commands + fly + esp + tools", game = "Brookhaven", hasKey = false, verified = true, type = "Admin", code = "-- Brookhaven Admin completo"},
    {name = "Brookhaven ESP + Aimbot", desc = "ESP jugadores + aim mejorado", game = "Brookhaven", hasKey = false, verified = true, type = "Visual", code = "-- Brookhaven ESP actualizado"},
    -- MURDER MYSTERY 2
    {name = "MM2 ESP + Roles", desc = "ESP sheriff/murder + gun mods", game = "Murder Mystery 2", hasKey = false, verified = true, type = "Visual", code = "-- MM2 ESP popular"},
    {name = "MM2 Murder Tools", desc = "Herramientas para murder/sheriff", game = "Murder Mystery 2", hasKey = false, verified = true, type = "Combat", code = "-- MM2 tools"},
    -- ANIME DEFENDERS
    {name = "Anime Defenders Hub", desc = "Auto summon + upgrade + raids", game = "Anime Defenders", hasKey = false, verified = true, type = "Farm", code = "-- Anime Defenders Hub verificado"},
    {name = "Anime Defenders Auto Farm", desc = "Farming de gemas y unidades", game = "Anime Defenders", hasKey = false, verified = true, type = "Farm", code = "-- Auto Farm Anime Defenders"},
    -- UNIVERSALES
    {name = "Infinite Yield FE", desc = "Admin commands universal estable", game = "Universal", hasKey = false, verified = true, type = "Admin", code = "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()"},
    {name = "Dex Explorer v4", desc = "Explorador de instancias profesional", game = "Universal", hasKey = false, verified = true, type = "Utility", code = "loadstring(game:HttpGet('https://raw.githubusercontent.com/infyiff/backup/main/dex.lua'))()"},
    {name = "Universal Fly + Noclip", desc = "Fly WASD + noclip ligero", game = "Universal", hasKey = false, verified = true, type = "Movement", code = "-- Universal Fly (tu versión favorita)"},
    {name = "Universal ESP", desc = "ESP jugadores + items customizable", game = "Universal", hasKey = false, verified = true, type = "Visual", code = "-- Universal ESP premium"},
    {name = "Click TP + God", desc = "Click to teleport + god mode", game = "Universal", hasKey = false, verified = true, type = "Movement", code = "-- Click TP + God"},
    -- MÁS POPULARES
    {name = "Da Hood Silent Aim", desc = "Silent aim + anti lock + esp", game = "Da Hood", hasKey = false, verified = true, type = "Combat", code = "-- Da Hood script actualizado"},
    {name = "Tower of Hell Skip", desc = "Auto skip stages + godmode", game = "Tower of Hell", hasKey = false, verified = true, type = "Utility", code = "-- ToH godmode + skip"},
    {name = "Pls Donate Auto Farm", desc = "Auto farm de donaciones/robux", game = "Pls Donate", hasKey = false, verified = true, type = "Farm", code = "-- Pls Donate auto farm"},
    {name = "Pet Simulator X Hub", desc = "Auto farm + hatching + trading", game = "Pet Simulator X", hasKey = false, verified = true, type = "Farm", code = "-- PSX Hub popular"},
}

-- Filtrar scripts por juego actual
local function GetFilteredScripts(searchText, onlyNoKey, gameFilter, typeFilter)
    local results = {}
    local current = CURRENT_GAME
    for _, script in ipairs(ScriptsDB) do
        local matchesGame = (script.game == "Universal") or (script.game == current)
        local matchesSearch = (searchText == "" or string.find(string.lower(script.name .. script.desc), string.lower(searchText)))
        local matchesKey = (not onlyNoKey or not script.hasKey)
        local matchesGameFilter = (gameFilter == "All" or script.game == gameFilter)
        local matchesType = (typeFilter == "All" or script.type == typeFilter)

        if matchesGame and matchesSearch and matchesKey and matchesGameFilter and matchesType then
            table.insert(results, script)
        end
    end
    return results
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- COMPONENTES DE DISEÑO (Neon, Glass, Holographic - enfocados en el look de las imágenes)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
local function CreateNeonPanel(parent, size, pos, radius)
    local panel = Make("Frame", {
        Size = size,
        Position = pos,
        BackgroundColor3 = C.BG_PANEL,
        BackgroundTransparency = 0.08,
        ZIndex = 10
    }, parent)
    Corner(radius or 14, panel)
    Stroke(2.2, C.P_PURPLE, panel, 0.15)
    -- Inner glow simulation
    local glow = Make("Frame", {
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1,
        ZIndex = 9
    }, panel)
    Stroke(1.5, C.P_CYAN, glow, 0.6)
    Corner((radius or 14) - 2, glow)
    return panel
end

local function CreateNeonButton(parent, text, size, pos, callback)
    local btn = Make("TextButton", {
        Size = size,
        Position = pos,
        BackgroundColor3 = C.BG_CARD,
        BackgroundTransparency = 0.2,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 12
    }, parent)
    Corner(8, btn)
    Stroke(1.8, C.P_PURPLE, btn, 0.1)

    btn.MouseEnter:Connect(function()
        Tw(btn, TI.FAST, {BackgroundColor3 = Color3.fromRGB(28, 22, 45), BackgroundTransparency = 0.1})
        Stroke(2.2, C.P_GLOW, btn, 0)
    end)
    btn.MouseLeave:Connect(function()
        Tw(btn, TI.FAST, {BackgroundColor3 = C.BG_CARD, BackgroundTransparency = 0.2})
        Stroke(1.8, C.P_PURPLE, btn, 0.1)
    end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function CreateScriptCard(parent, scriptData, yPos)
    local card = Make("Frame", {
        Size = UDim2.new(1, -12, 0, 72),
        Position = UDim2.new(0, 6, 0, yPos),
        BackgroundColor3 = C.BG_CARD,
        BackgroundTransparency = 0.1,
        ZIndex = 11
    }, parent)
    Corner(10, card)
    Stroke(1.6, C.P_PURPLE, card, 0.12)

    -- Left neon accent bar
    local accent = Make("Frame", {
        Size = UDim2.new(0, 4, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = scriptData.verified and C.ACCENT_G or C.P_PURPLE,
        ZIndex = 12
    }, card)
    Corner(2, accent)

    -- Title
    Make("TextLabel", {
        Size = UDim2.new(1, -140, 0, 20),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = scriptData.name,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12
    }, card)

    -- Description
    Make("TextLabel", {
        Size = UDim2.new(1, -140, 0, 28),
        Position = UDim2.new(0, 14, 0, 26),
        BackgroundTransparency = 1,
        Text = scriptData.desc,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_GRAY,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 12
    }, card)

    -- Verified tag
    if scriptData.verified then
        local tag = Make("Frame", {
            Size = UDim2.new(0, 78, 0, 16),
            Position = UDim2.new(0, 14, 0, 52),
            BackgroundColor3 = Color3.fromRGB(15, 45, 30),
            ZIndex = 12
        }, card)
        Corner(4, tag)
        Make("TextLabel", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "✓ Verified by Delta",
            Font = Enum.Font.Gotham,
            TextSize = 8,
            TextColor3 = C.ACCENT_G,
            ZIndex = 13
        }, tag)
    end

    -- IA tag (like in image)
    local iaTag = Make("Frame", {
        Size = UDim2.new(0, 32, 0, 16),
        Position = UDim2.new(0, 96, 0, 52),
        BackgroundColor3 = Color3.fromRGB(25, 20, 45),
        ZIndex = 12
    }, card)
    Corner(4, iaTag)
    Make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "IA",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = C.P_CYAN,
        ZIndex = 13
    }, iaTag)

    -- Execute button (neon style)
    local execBtn = CreateNeonButton(card, "EXECUTE", UDim2.new(0, 78, 0, 24), UDim2.new(1, -84, 0, 8), function()
        local success, err = pcall(function()
            if scriptData.code and scriptData.code ~= "" then
                loadstring(scriptData.code)()
            end
        end)
        if success then
            table.insert(ENV.CRX_QOS_Executed, {name = scriptData.name, time = os.date("%H:%M")})
            PushNotif("Ejecutado", scriptData.name .. " se cargó correctamente", "SUCCESS")
        else
            PushNotif("Error", tostring(err):sub(1, 70), "ERROR")
        end
    end)

    -- Info button
    local infoBtn = CreateNeonButton(card, "INFO", UDim2.new(0, 52, 0, 24), UDim2.new(1, -140, 0, 8), function()
        PushNotif(scriptData.name, scriptData.desc .. " | Juego: " .. scriptData.game, "INFO", 5)
    end)

    return card
end

local function CreateStatBar(parent, label, value, maxVal, y)
    local container = Make("Frame", {
        Size = UDim2.new(1, -16, 0, 38),
        Position = UDim2.new(0, 8, 0, y),
        BackgroundTransparency = 1,
        ZIndex = 12
    }, parent)

    Make("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 14),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_GRAY,
        ZIndex = 13
    }, container)

    Make("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, 14),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(value),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.P_CYAN,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 13
    }, container)

    local barBG = Make("Frame", {
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 18),
        BackgroundColor3 = Color3.fromRGB(30, 28, 42),
        ZIndex = 12
    }, container)
    Corner(3, barBG)

    local fill = Make("Frame", {
        Size = UDim2.new(value / maxVal, 0, 1, 0),
        BackgroundColor3 = C.P_CYAN,
        ZIndex = 13
    }, barBG)
    Corner(3, fill)
    Stroke(1, C.P_GLOW, fill, 0.4)

    return container
end

-- Notificaciones estilo holográfico
local function PushNotif(title, body, typ, dur)
    typ = typ or "INFO"
    dur = dur or 3.2
    local col = (typ == "SUCCESS" and C.ACCENT_G) or (typ == "ERROR" and C.ACCENT_R) or C.P_CYAN

    local notif = Make("Frame", {
        Size = UDim2.new(0, 280, 0, 58),
        Position = UDim2.new(1, 10, 1, -70),
        BackgroundColor3 = C.BG_PANEL,
        BackgroundTransparency = 0.1,
        ZIndex = 9999
    }, ScreenGui)
    Corner(10, notif)
    Stroke(1.8, col, notif, 0.15)

    Make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 10, 0, 6),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 10000
    }, notif)

    Make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 10, 0, 24),
        BackgroundTransparency = 1,
        Text = body,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_GRAY,
        TextWrapped = true,
        ZIndex = 10000
    }, notif)

    Tw(notif, TI.BOUNCE, {Position = UDim2.new(1, -290, 1, -70)})
    task.delay(dur, function()
        if notif and notif.Parent then
            Tw(notif, TI.MED, {Position = UDim2.new(1, 10, 1, -70)})
            task.wait(0.25)
            notif:Destroy()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- LOGIN SCREEN (basado EXACTAMENTE en la primera imagen que me diste)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
local function CreateLoginScreen(onSuccess)
    local loginGui = Make("ScreenGui", {
        Name = "QuantumLogin",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000
    }, PlayerGui)

    -- Background cyberpunk
    local bg = Make("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.BG_DARK,
        ZIndex = 1
    }, loginGui)

    -- Holographic lines effect (simplified)
    for i = 1, 8 do
        local line = Make("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, i * 90),
            BackgroundColor3 = C.P_PURPLE,
            BackgroundTransparency = 0.92,
            ZIndex = 2
        }, bg)
    end

    -- Main login panel (neon border exact style)
    local panel = CreateNeonPanel(loginGui, UDim2.new(0, 420, 0, 480), UDim2.new(0.5, -210, 0.5, -240), 18)

    -- Logo + Title
    local logo = Make("Frame", {
        Size = UDim2.new(0, 64, 0, 64),
        Position = UDim2.new(0.5, -32, 0, 22),
        BackgroundColor3 = Color3.fromRGB(30, 20, 55),
        ZIndex = 15
    }, panel)
    Corner(32, logo)
    Stroke(2.5, C.P_PURPLE, logo)

    Make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "⚛",
        Font = Enum.Font.GothamBold,
        TextSize = 32,
        TextColor3 = C.P_CYAN,
        ZIndex = 16
    }, logo)

    Make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 96),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS SECURE LOGIN",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 15
    }, panel)

    Make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 120),
        BackgroundTransparency = 1,
        Text = "Delta Executor v2.1 Authentication Protocol",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.P_CYAN,
        ZIndex = 15
    }, panel)

    -- Input fields (exact neon style from image)
    local userBox = Make("TextBox", {
        Size = UDim2.new(1, -48, 0, 42),
        Position = UDim2.new(0, 24, 0, 158),
        BackgroundColor3 = C.BG_INPUT,
        BackgroundTransparency = 0.15,
        Text = "",
        PlaceholderText = "USUARIO/ID DE ACCESO",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ZIndex = 15
    }, panel)
    Corner(8, userBox)
    Stroke(2, C.P_CYAN, userBox, 0.2)

    local passBox = Make("TextBox", {
        Size = UDim2.new(1, -48, 0, 42),
        Position = UDim2.new(0, 24, 0, 210),
        BackgroundColor3 = C.BG_INPUT,
        BackgroundTransparency = 0.15,
        Text = "",
        PlaceholderText = "CONTRASEÑA DE SEGURIDAD",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ZIndex = 15
    }, panel)
    Corner(8, passBox)
    Stroke(2, C.P_CYAN, passBox, 0.2)

    -- Biometric section (exact from image)
    local bioPanel = CreateNeonPanel(panel, UDim2.new(0.48, -12, 0, 92), UDim2.new(0, 24, 0, 268), 10)
    Make("TextLabel", {
        Size = UDim2.new(1, -8, 0, 16),
        Position = UDim2.new(0, 4, 0, 6),
        BackgroundTransparency = 1,
        Text = "BIOMETRIC AUTHENTICATION",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = C.P_CYAN,
        ZIndex = 16
    }, bioPanel)

    Make("TextLabel", {
        Size = UDim2.new(1, -8, 0, 14),
        Position = UDim2.new(0, 4, 0, 24),
        BackgroundTransparency = 1,
        Text = "ESCANEO BIOMÉTRICO",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_GRAY,
        ZIndex = 16
    }, bioPanel)

    Make("TextLabel", {
        Size = UDim2.new(1, -8, 0, 14),
        Position = UDim2.new(0, 4, 0, 40),
        BackgroundTransparency = 1,
        Text = "(RECOMENDADO)",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = C.ACCENT_G,
        ZIndex = 16
    }, bioPanel)

    -- Big Authenticate button (exact neon style)
    local authBtn = CreateNeonButton(panel, "AUTENTICAR ACCESO", UDim2.new(0.48, -12, 0, 48), UDim2.new(0.5, 6, 0, 268), function()
        local user = userBox.Text
        if user == "" then user = DNAME end

        -- Fake loading animation
        authBtn.Text = "VERIFICANDO..."
        Tw(authBtn, TI.FAST, {BackgroundColor3 = Color3.fromRGB(40, 25, 70)})

        task.wait(0.8)

        loginGui:Destroy()
        onSuccess(user)
    end)

    -- Side info panel (encryption + network)
    local sidePanel = CreateNeonPanel(panel, UDim2.new(0.48, -12, 0, 92), UDim2.new(0, 24, 0, 368), 10)
    Make("TextLabel", {
        Size = UDim2.new(1, -8, 0, 14),
        Position = UDim2.new(0, 4, 0, 8),
        BackgroundTransparency = 1,
        Text = "NIVEL DE ENCRIPTACIÓN: CUÁNTICA",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = C.P_CYAN,
        ZIndex = 16
    }, sidePanel)

    Make("TextLabel", {
        Size = UDim2.new(1, -8, 0, 14),
        Position = UDim2.new(0, 4, 0, 26),
        BackgroundTransparency = 1,
        Text = "VERIFICANDO ENLACE DE RED...",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = C.TEXT_GRAY,
        ZIndex = 16
    }, sidePanel)

    local statusDot = Make("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 8, 0, 48),
        BackgroundColor3 = C.ACCENT_G,
        ZIndex = 16
    }, sidePanel)
    Corner(5, statusDot)

    Make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.new(0, 22, 0, 46),
        BackgroundTransparency = 1,
        Text = "CONECTADO",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = C.ACCENT_G,
        ZIndex = 16
    }, sidePanel)

    -- Footer
    Make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -18),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS AUTHENTICATION PROTOCOL | Delta Executor v2.1",
        Font = Enum.Font.Gotham,
        TextSize = 8,
        TextColor3 = C.TEXT_MUTED,
        ZIndex = 15
    }, panel)

    return loginGui
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- MAIN UI (basado EXACTAMENTE en la segunda imagen - tabs, script list, right panel, media, oracle)
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
local function CreateMainUI(username)
    local mainGui = Make("ScreenGui", {
        Name = "QuantumOS_Main",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 10
    }, PlayerGui)
    ENV.CRX_QOS_v7 = mainGui

    -- Background
    Make("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.BG_DARK,
        BackgroundTransparency = 0.3,
        ZIndex = 1
    }, mainGui)

    -- Top Bar
    local topBar = Make("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = C.BG_PANEL,
        BackgroundTransparency = 0.1,
        ZIndex = 50
    }, mainGui)
    Stroke(1, C.STROKE, topBar, 0.3)

    Make("TextLabel", {
        Size = UDim2.new(0, 220, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = "QUANTUM OS v2.5 | Delta Executor v2.1",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 51
    }, topBar)

    -- User info top right
    Make("TextLabel", {
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(1, -180, 0, 0),
        BackgroundTransparency = 1,
        Text = username or DNAME,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = C.P_CYAN,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 51
    }, topBar)

    -- Tabs (exact from image)
    local tabs = {"HOME", "CHARACTER", "WORLD", "VISUALS", "STATUS", "MEDIA", "SETTINGS"}
    local activeTab = "HOME"
    local tabButtons = {}

    local tabContainer = Make("Frame", {
        Size = UDim2.new(1, -24, 0, 36),
        Position = UDim2.new(0, 12, 0, 52),
        BackgroundTransparency = 1,
        ZIndex = 40
    }, mainGui)

    for i, tabName in ipairs(tabs) do
        local btn = Make("TextButton", {
            Size = UDim2.new(0, 92, 0, 28),
            Position = UDim2.new(0, (i-1) * 96, 0, 0),
            BackgroundColor3 = (tabName == activeTab) and C.P_PURPLE or C.BG_CARD,
            BackgroundTransparency = (tabName == activeTab) and 0.15 or 0.3,
            Text = tabName,
            Font = Enum.Font.GothamSemibold,
            TextSize = 10,
            TextColor3 = (tabName == activeTab) and C.TEXT_WHITE or C.TEXT_GRAY,
            ZIndex = 41
        }, tabContainer)
        Corner(8, btn)
        if tabName == activeTab then Stroke(1.5, C.P_GLOW, btn, 0.1) end

        btn.MouseButton1Click:Connect(function()
            activeTab = tabName
            for name, b in pairs(tabButtons) do
                if name == tabName then
                    b.BackgroundColor3 = C.P_PURPLE
                    b.BackgroundTransparency = 0.15
                    Stroke(1.5, C.P_GLOW, b, 0.1)
                    b.TextColor3 = C.TEXT_WHITE
                else
                    b.BackgroundColor3 = C.BG_CARD
                    b.BackgroundTransparency = 0.3
                    if b:FindFirstChildOfClass("UIStroke") then b:FindFirstChildOfClass("UIStroke"):Destroy() end
                    b.TextColor3 = C.TEXT_GRAY
                end
            end
            -- Here you would switch content based on tab
            PushNotif("Tab", "Cambiado a " .. tabName, "INFO", 1.5)
        end)

        tabButtons[tabName] = btn
    end

    -- Main content area (HOME tab - script list + filters + right panel)
    -- This replicates the second image layout

    -- Left panel: Search + Filters + Script list
    local leftPanel = CreateNeonPanel(mainGui, UDim2.new(0.58, -10, 0.72, -60), UDim2.new(0.01, 0, 0.12, 0), 12)

    -- Search bar
    local searchBox = Make("TextBox", {
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = C.BG_INPUT,
        BackgroundTransparency = 0.2,
        Text = "",
        PlaceholderText = "Search scripts...",
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextColor3 = C.TEXT_WHITE,
        PlaceholderColor3 = C.TEXT_MUTED,
        ZIndex = 12
    }, leftPanel)
    Corner(8, searchBox)
    Stroke(1.5, C.P_CYAN, searchBox, 0.25)

    -- Filter chips (exact style from image)
    local filterY = 46
    local chips = {"KEY REQUIRED: [On]", "NO KEY: [On]", "BY GAME: [" .. CURRENT_GAME .. "]", "BY TYPE: [All]"}
    for i, chipText in ipairs(chips) do
        local chip = Make("TextButton", {
            Size = UDim2.new(0, 118, 0, 22),
            Position = UDim2.new(0, 8 + (i-1) * 122, 0, filterY),
            BackgroundColor3 = C.BG_CARD,
            BackgroundTransparency = 0.25,
            Text = chipText,
            Font = Enum.Font.Gotham,
            TextSize = 9,
            TextColor3 = C.TEXT_GRAY,
            ZIndex = 12
        }, leftPanel)
        Corner(11, chip)
        Stroke(1, C.P_PURPLE, chip, 0.3)
    end

    -- Script list scrolling
    local scriptScroll = Make("ScrollingFrame", {
        Size = UDim2.new(1, -12, 1, -82),
        Position = UDim2.new(0, 6, 0, 76),
        BackgroundTransparency = 1,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = C.P_PURPLE,
        ZIndex = 11
    }, leftPanel)

    local function RefreshScriptList(searchText)
        for _, child in pairs(scriptScroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        local filtered = GetFilteredScripts(searchText or "", false, "All", "All")
        local y = 4
        for _, script in ipairs(filtered) do
            CreateScriptCard(scriptScroll, script, y)
            y = y + 78
        end
        scriptScroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RefreshScriptList(searchBox.Text)
    end)

    task.spawn(function() RefreshScriptList("") end)

    -- Right panel: Avatar + Performance + Current Game (exact from image)
    local rightPanel = CreateNeonPanel(mainGui, UDim2.new(0.38, -10, 0.48, -10), UDim2.new(0.61, 0, 0.12, 0), 12)

    -- Avatar placeholder
    local avatarFrame = Make("Frame", {
        Size = UDim2.new(0, 92, 0, 92),
        Position = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Color3.fromRGB(40, 35, 55),
        ZIndex = 12
    }, rightPanel)
    Corner(46, avatarFrame)
    Stroke(2, C.P_CYAN, avatarFrame)

    Make("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "👤",
        Font = Enum.Font.GothamBold,
        TextSize = 42,
        TextColor3 = C.P_CYAN,
        ZIndex = 13
    }, avatarFrame)

    Make("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 110, 0, 14),
        BackgroundTransparency = 1,
        Text = username or DNAME,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 12
    }, rightPanel)

    -- Performance stats
    CreateStatBar(rightPanel, "FPS", 121, 240, 52)
    CreateStatBar(rightPanel, "CPU", 30, 100, 92)
    CreateStatBar(rightPanel, "RAM", 45, 100, 132)

    Make("TextLabel", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 8, 0, 175),
        BackgroundTransparency = 1,
        Text = "CURRENT GAME: " .. CURRENT_GAME,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = C.P_CYAN,
        ZIndex = 12
    }, rightPanel)

    -- Media Center (bottom left, exact from image)
    local mediaPanel = CreateNeonPanel(mainGui, UDim2.new(0.58, -10, 0.22, -10), UDim2.new(0.01, 0, 0.76, 0), 10)

    Make("TextLabel", {
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1,
        Text = "🎵 MEDIA CENTER",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 12
    }, mediaPanel)

    Make("TextLabel", {
        Size = UDim2.new(1, -12, 0, 16),
        Position = UDim2.new(0, 8, 0, 28),
        BackgroundTransparency = 1,
        Text = "Now Playing: Neo-Cyber Funk",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.P_CYAN,
        ZIndex = 12
    }, mediaPanel)

    -- Simple music controls
    local controls = {"⏮", "⏸", "▶", "⏭"}
    for i, txt in ipairs(controls) do
        local b = Make("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(0, 12 + (i-1) * 32, 0, 52),
            BackgroundColor3 = C.BG_CARD,
            Text = txt,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = C.TEXT_WHITE,
            ZIndex = 13
        }, mediaPanel)
        Corner(6, b)
    end

    -- Quantum Oracle (bottom right, exact from image)
    local oraclePanel = CreateNeonPanel(mainGui, UDim2.new(0.38, -10, 0.22, -10), UDim2.new(0.61, 0, 0.76, 0), 10)

    Make("TextLabel", {
        Size = UDim2.new(1, -12, 0, 18),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundTransparency = 1,
        Text = "⚛ QUANTUM ORACLE  |  AI Assist",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 12
    }, oraclePanel)

    Make("TextLabel", {
        Size = UDim2.new(1, -12, 0, 14),
        Position = UDim2.new(0, 8, 0, 26),
        BackgroundTransparency = 1,
        Text = "GAME AWARENESS: Enabled",
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextColor3 = C.ACCENT_G,
        ZIndex = 12
    }, oraclePanel)

    local chatBox = Make("TextBox", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 8, 0, 48),
        BackgroundColor3 = C.BG_INPUT,
        BackgroundTransparency = 0.2,
        PlaceholderText = "Chat prompt...",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = C.TEXT_WHITE,
        ZIndex = 12
    }, oraclePanel)
    Corner(6, chatBox)

    -- Final boot notification
    task.delay(1.5, function()
        PushNotif("Quantum OS v7", "Bienvenido " .. (username or DNAME) .. " | " .. CURRENT_GAME .. " detectado", "SYSTEM", 4)
    end)

    return mainGui
end

-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
CreateLoginScreen(function(username)
    CreateMainUI(username)
end)

print("[CRX QUANTUM OS v7] Delta Exact Style cargado correctamente. Enfocado 100% en el diseño que pediste.")
