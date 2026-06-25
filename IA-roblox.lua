--[[
    ╔══════════════════════════════════════════════╗
    ║         CONECTA PALABRAS - PRO GUI           ║
    ║      Modern Word Finder • Delta Mobile       ║
    ╚══════════════════════════════════════════════╝
]]

-- ============================================================
--                   SERVICIOS Y CONFIG
-- ============================================================

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local LocalPlayer   = Players.LocalPlayer

local CFG = {
    MAX_RESULTS   = 200,   -- máximo de palabras a mostrar
    ITEM_HEIGHT   = 38,    -- altura de cada item en la lista
    LIST_VISIBLE  = 9,     -- cuántos items visibles a la vez
    ANIM_TIME     = 0.18,
}

-- ============================================================
--                   PALETA Y ESTILO
-- ============================================================

local C = {
    BG          = Color3.fromRGB(10,  12,  20),   -- fondo principal
    PANEL       = Color3.fromRGB(16,  18,  30),   -- panel
    CARD        = Color3.fromRGB(22,  26,  42),   -- tarjeta
    CARD_ALT    = Color3.fromRGB(26,  30,  50),   -- tarjeta alt (zebra)
    ACCENT      = Color3.fromRGB(82,  130, 255),  -- azul eléctrico
    ACCENT2     = Color3.fromRGB(120, 80,  255),  -- violeta
    GREEN       = Color3.fromRGB(60,  210, 140),  -- éxito
    RED         = Color3.fromRGB(255, 75,  90),   -- error
    TEXT        = Color3.fromRGB(225, 228, 255),  -- texto principal
    TEXT_DIM    = Color3.fromRGB(130, 135, 170),  -- texto secundario
    TEXT_MUTED  = Color3.fromRGB(70,  75,  110),  -- texto apagado
    BAR         = Color3.fromRGB(30,  34,  58),   -- scrollbar track
    BAR_THUMB   = Color3.fromRGB(82,  130, 255),  -- scrollbar thumb
    WHITE       = Color3.fromRGB(255, 255, 255),
    BLACK       = Color3.fromRGB(0,   0,   0),
}

-- ============================================================
--                   TRIE - BÚSQUEDA RÁPIDA
-- ============================================================

local TrieNode = {}
TrieNode.__index = TrieNode

function TrieNode.new()
    return setmetatable({ ch = {}, words = {} }, TrieNode)
end

local rootTrie = TrieNode.new()
local totalLoaded = 0

local function trieInsert(word)
    local node = rootTrie
    for i = 1, #word do
        local c = word:sub(i, i)
        if not node.ch[c] then
            node.ch[c] = TrieNode.new()
        end
        node = node.ch[c]
    end
    -- guarda la palabra en el nodo hoja
    node.words[word] = true
end

local function trieCollect(node, results, limit)
    if #results >= limit then return end
    for w in pairs(node.words) do
        results[#results + 1] = w
        if #results >= limit then return end
    end
    for _, child in pairs(node.ch) do
        if #results >= limit then return end
        trieCollect(child, results, limit)
    end
end

local function trieSearch(prefix, limit)
    local node = rootTrie
    for i = 1, #prefix do
        local c = prefix:sub(i, i)
        if not node.ch[c] then return {}, 0 end
        node = node.ch[c]
    end
    local results = {}
    trieCollect(node, results, limit + 100)
    table.sort(results)
    local total = #results
    local shown = {}
    for i = 1, math.min(limit, total) do
        shown[i] = results[i]
    end
    return shown, total
end

-- ============================================================
--                   NORMALIZACIÓN
-- ============================================================

local accentMap = {
    ["á"]="a",["à"]="a",["â"]="a",["ä"]="a",["ã"]="a",
    ["é"]="e",["è"]="e",["ê"]="e",["ë"]="e",
    ["í"]="i",["ì"]="i",["î"]="i",["ï"]="i",
    ["ó"]="o",["ò"]="o",["ô"]="o",["ö"]="o",["õ"]="o",
    ["ú"]="u",["ù"]="u",["û"]="u",["ü"]="u",
    ["ñ"]="n",["ç"]="c",["ý"]="y",
}

local function normalize(w)
    if not w then return "" end
    w = tostring(w):lower():match("^%s*(.-)%s*$")
    for acc, plain in pairs(accentMap) do
        w = w:gsub(acc, plain)
    end
    return w
end

-- ============================================================
--              CARGA DE DICCIONARIOS
-- ============================================================

-- Estado visible en GUI
local statusText   = "Iniciando..."
local isReady      = false
local loadProgress = 0   -- 0.0 → 1.0

local URLS = {
    { lang="EN", url="https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt",           fmt="txt"  },
    { lang="ES", url="https://raw.githubusercontent.com/words/an-array-of-spanish-words/master/index.js",    fmt="js"   },
}

-- Palabras internas de respaldo (cargadas siempre primero como base)
local SEED = {
    -- Español
    "amor","amora","amigo","amiga","animal","ancho","antes","agua","aire","alto","abrir",
    "arbol","arena","arte","ayer","azul","abuela","abuelo","accion","acto","actor",
    "adelante","agosto","alarma","aldea","alma","alegre","ambiente","aprender","apoyo",
    "boca","bonito","bosque","bueno","buscar","banco","barco","blanco","brazo","bella",
    "cabeza","camino","campo","cantar","casa","ciudad","cielo","conocer","conectar",
    "conejo","corazon","correr","comer","comprar","coche","cocina","colores","corona",
    "contra","contigo","construir","concepto","cosa","cuerpo","cuatro","cinco","cien",
    "dia","dinero","dormir","dulce","durante","donde","danza","dato","dedo","diez",
    "escuela","escribir","esperar","esta","estar","estrella","entre","entonces",
    "esperar","esperanza","espejo","espacio","espada","espalda","especial",
    "flor","familia","feliz","fuerza","fuego","forma","fruta","frente","final",
    "gato","grande","gracias","grupo","gente","guerra","gusto","globo","gris",
    "hablar","hacer","hermano","hermana","hombre","hora","historia","hueso",
    "isla","idioma","igual","inicio","imagen","importante",
    "juego","jardin","joven","justo","junto","jefe",
    "largo","libro","lugar","luna","lengua","lento","libre","luchar","luz",
    "mano","mar","mundo","mujer","madre","malo","mapa","mesa","musica","mirar",
    "noche","nombre","nuevo","nunca","nadie","natural","negro","nivel","norte",
    "oso","osa","osos","osas","oeste","obra","oreja","oscuro","objeto",
    "padre","pais","palabra","papel","parque","perro","pequeno","poder","pez",
    "primera","persona","puerta","plaza","planta","plata","playa","poca","poco",
    "querer","quien","quiza",
    "rapido","rojo","rio","rama","raton","reino","reto","rato",
    "sol","sala","saltar","sangre","saber","secreto","segundo","siempre","sobre",
    "trabajo","tiempo","tierra","todo","triste","tarde","tener","tercer",
    "uno","ultima","unir","usar","unico","universo",
    "vida","vez","viento","verde","volar","voz","viejo","vista","valor",
    "zapato","zona","zumo",
    -- Inglés
    "one","two","three","four","five","six","seven","eight","nine","ten",
    "animal","apple","arrow","after","again","also","always","another","answer",
    "back","ball","bank","bird","black","blue","book","born","bring","build",
    "call","came","card","carry","catch","change","child","city","clean","clear",
    "close","cold","color","come","cool","country","cover","create","cut",
    "dark","deal","deep","door","down","draw","dream","drink","drive","drop",
    "each","earth","edge","eight","empty","end","enter","even","every","eye",
    "face","fall","fast","feel","feet","fight","fill","find","fire","first",
    "five","flag","flat","flow","follow","food","force","form","four","free",
    "from","full","game","garden","girl","give","glass","good","great","green",
    "grow","hand","happy","hard","head","hear","heart","heavy","help","here",
    "high","hold","home","hope","hour","house","huge","human","idea","into",
    "just","keep","kind","king","know","land","large","last","late","lead",
    "learn","left","level","life","light","like","line","lion","list","live",
    "long","look","lose","love","made","make","many","meet","mind","miss",
    "moon","more","most","move","much","must","name","near","need","next",
    "night","none","note","only","open","other","over","page","part","past",
    "path","pick","plan","play","point","power","pull","push","race","rain",
    "read","real","rest","ride","ring","rise","road","rock","role","room","rule",
    "same","save","seem","side","sign","sing","slow","snow","some","song","soon",
    "soul","space","star","stay","step","still","stop","story","strong","such",
    "sure","swim","take","tell","than","them","then","time","told","tree","true",
    "turn","type","used","very","view","wait","walk","warm","water","wave",
    "well","went","what","when","wide","will","wind","wise","with","word",
    "work","world","write","year","your","zero",
    -- ONO prefijos especiales
    "ono","onomatopeya",
    -- ARMa prefijos
    "arma","armada","armado","armadura","armamento","armar","armario","armas",
    -- COJO prefijos
    "cojer","cojo","coja","cojos","cojas",
}

local function loadSeed()
    for _, w in ipairs(SEED) do
        local n = normalize(w)
        if n:match("^[a-z]+$") and #n >= 2 then
            trieInsert(n)
            totalLoaded = totalLoaded + 1
        end
    end
end

local function loadFromURL(entry)
    local ok, body = pcall(function()
        return HttpService:GetAsync(entry.url, true)
    end)
    if not ok or not body or #body < 10 then
        return 0
    end
    local count = 0
    if entry.fmt == "js" then
        for w in body:gmatch('"([^"]+)"') do
            local n = normalize(w)
            if n:match("^[a-z]+$") and #n >= 2 and #n <= 30 then
                trieInsert(n)
                count = count + 1
            end
        end
    else
        for w in body:gmatch("[^\r\n]+") do
            local n = normalize(w:match("^%s*(.-)%s*$") or "")
            if n:match("^[a-z]+$") and #n >= 2 and #n <= 30 then
                trieInsert(n)
                count = count + 1
            end
        end
    end
    return count
end

-- ============================================================
--                   HELPERS DE UI
-- ============================================================

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function gradient(parent, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent = parent
    return g
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function tween(obj, props, t, style, dir)
    local ti = TweenInfo.new(
        t or CFG.ANIM_TIME,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, ti, props):Play()
end

local function makeLabel(parent, text, size, color, font, halign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size or 14
    l.TextColor3 = color or C.TEXT
    l.Font = font or Enum.Font.Gotham
    l.TextXAlignment = halign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Parent = parent
    return l
end

-- ============================================================
--                   CONSTRUCCIÓN DE GUI
-- ============================================================

-- Limpia instancias previas
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("CW_GUI")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CW_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ── VENTANA PRINCIPAL ──────────────────────────────────────

local PANEL_W = 340
local PANEL_H = 530

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
Main.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
corner(Main, 16)
stroke(Main, Color3.fromRGB(45, 50, 85), 1.5)

-- Sombra decorativa (fondo degradado sutil)
local Shadow = Instance.new("Frame")
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, 10)
Shadow.BackgroundColor3 = C.BLACK
Shadow.BackgroundTransparency = 0.7
Shadow.BorderSizePixel = 0
Shadow.ZIndex = Main.ZIndex - 1
Shadow.Parent = Main
corner(Shadow, 20)

-- ── HEADER ─────────────────────────────────────────────────

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 56)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = C.PANEL
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 16)

-- Línea inferior del header (para que el corner de arriba no afecte abajo)
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 16)
HeaderFix.Position = UDim2.new(0, 0, 1, -16)
HeaderFix.BackgroundColor3 = C.PANEL
HeaderFix.BorderSizePixel = 0
HeaderFix.ZIndex = Header.ZIndex
HeaderFix.Parent = Header

-- Barra de acento degradado arriba del header
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.Position = UDim2.new(0, 0, 0, 0)
AccentBar.BackgroundColor3 = C.ACCENT
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = Header.ZIndex + 1
AccentBar.Parent = Main
corner(AccentBar, 3)
gradient(AccentBar, C.ACCENT, C.ACCENT2, 0)

-- Icono título
local TitleIcon = makeLabel(Header, "⬡", 22, C.ACCENT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
TitleIcon.Size = UDim2.new(0, 40, 1, 0)
TitleIcon.Position = UDim2.new(0, 10, 0, 0)
TitleIcon.ZIndex = Header.ZIndex + 1

local TitleLabel = makeLabel(Header, "CONECTA PALABRAS", 15, C.TEXT, Enum.Font.GothamBold)
TitleLabel.Size = UDim2.new(1, -140, 1, 0)
TitleLabel.Position = UDim2.new(0, 54, 0, 0)
TitleLabel.ZIndex = Header.ZIndex + 1

local SubLabel = makeLabel(Header, "Word Finder Pro", 11, C.TEXT_DIM, Enum.Font.Gotham)
SubLabel.Size = UDim2.new(1, -140, 0, 16)
SubLabel.Position = UDim2.new(0, 54, 0, 30)
SubLabel.ZIndex = Header.ZIndex + 1

-- Botón cerrar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(55, 22, 28)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.RED
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.ZIndex = Header.ZIndex + 2
CloseBtn.Parent = Header
corner(CloseBtn, 8)

CloseBtn.MouseButton1Click:Connect(function()
    tween(Main, { Size = UDim2.new(0, PANEL_W, 0, 0), Position = UDim2.new(0.5, -PANEL_W/2, 0.5, 0) }, 0.2)
    task.delay(0.22, function() ScreenGui:Destroy() end)
end)
CloseBtn.TouchTap:Connect(function()
    tween(Main, { Size = UDim2.new(0, PANEL_W, 0, 0), Position = UDim2.new(0.5, -PANEL_W/2, 0.5, 0) }, 0.2)
    task.delay(0.22, function() ScreenGui:Destroy() end)
end)

-- ── CUERPO ─────────────────────────────────────────────────

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -24, 1, -68)
Body.Position = UDim2.new(0, 12, 0, 60)
Body.BackgroundTransparency = 1
Body.Parent = Main

-- ── BARRA DE ESTADO / CARGA ────────────────────────────────

local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 32)
StatusBar.Position = UDim2.new(0, 0, 0, 0)
StatusBar.BackgroundColor3 = C.CARD
StatusBar.BorderSizePixel = 0
StatusBar.Parent = Body
corner(StatusBar, 8)

local StatusDot = makeLabel(StatusBar, "●", 12, C.ACCENT, Enum.Font.Gotham, Enum.TextXAlignment.Center)
StatusDot.Size = UDim2.new(0, 24, 1, 0)
StatusDot.Position = UDim2.new(0, 4, 0, 0)

local StatusTxt = makeLabel(StatusBar, "Cargando diccionarios...", 11, C.TEXT_DIM, Enum.Font.Gotham)
StatusTxt.Size = UDim2.new(1, -80, 1, 0)
StatusTxt.Position = UDim2.new(0, 28, 0, 0)

local CountTxt = makeLabel(StatusBar, "0 palabras", 11, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Right)
CountTxt.Size = UDim2.new(0, 90, 1, 0)
CountTxt.Position = UDim2.new(1, -94, 0, 0)

-- Barra de progreso debajo del status
local ProgressTrack = Instance.new("Frame")
ProgressTrack.Size = UDim2.new(1, 0, 0, 3)
ProgressTrack.Position = UDim2.new(0, 0, 1, -3)
ProgressTrack.BackgroundColor3 = C.BAR
ProgressTrack.BorderSizePixel = 0
ProgressTrack.Parent = StatusBar
corner(ProgressTrack, 2)

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.Position = UDim2.new(0, 0, 0, 0)
ProgressFill.BackgroundColor3 = C.ACCENT
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressTrack
corner(ProgressFill, 2)
gradient(ProgressFill, C.ACCENT, C.ACCENT2, 0)

-- ── CAJA DE TEXTO (PREFIJO) ────────────────────────────────

local InputContainer = Instance.new("Frame")
InputContainer.Size = UDim2.new(1, 0, 0, 52)
InputContainer.Position = UDim2.new(0, 0, 0, 40)
InputContainer.BackgroundColor3 = C.CARD
InputContainer.BorderSizePixel = 0
InputContainer.Parent = Body
corner(InputContainer, 12)
stroke(InputContainer, Color3.fromRGB(40, 46, 80), 1)

local InputIcon = makeLabel(InputContainer, "🔍", 18, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)
InputIcon.Size = UDim2.new(0, 44, 1, 0)
InputIcon.Position = UDim2.new(0, 0, 0, 0)

local PrefixBox = Instance.new("TextBox")
PrefixBox.Size = UDim2.new(1, -100, 1, -12)
PrefixBox.Position = UDim2.new(0, 44, 0, 6)
PrefixBox.BackgroundTransparency = 1
PrefixBox.PlaceholderText = "ono, arma, con, esp..."
PrefixBox.PlaceholderColor3 = C.TEXT_MUTED
PrefixBox.Text = ""
PrefixBox.TextColor3 = C.TEXT
PrefixBox.TextSize = 18
PrefixBox.Font = Enum.Font.GothamBold
PrefixBox.ClearTextOnFocus = false
PrefixBox.TextXAlignment = Enum.TextXAlignment.Left
PrefixBox.Parent = InputContainer

-- Botón limpiar texto
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 42, 0, 30)
ClearBtn.Position = UDim2.new(1, -48, 0.5, -15)
ClearBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 32)
ClearBtn.BorderSizePixel = 0
ClearBtn.Text = "✕"
ClearBtn.TextColor3 = C.TEXT_DIM
ClearBtn.TextSize = 13
ClearBtn.Font = Enum.Font.Gotham
ClearBtn.Parent = InputContainer
corner(ClearBtn, 8)

ClearBtn.MouseButton1Click:Connect(function()
    PrefixBox.Text = ""
    PrefixBox:CaptureFocus()
end)
ClearBtn.TouchTap:Connect(function()
    PrefixBox.Text = ""
end)

-- Efecto foco en input
PrefixBox.Focused:Connect(function()
    tween(InputContainer, { BackgroundColor3 = C.CARD_ALT }, 0.15)
    stroke(InputContainer, C.ACCENT, 1.5)
end)
PrefixBox.FocusLost:Connect(function()
    tween(InputContainer, { BackgroundColor3 = C.CARD }, 0.15)
    stroke(InputContainer, Color3.fromRGB(40, 46, 80), 1)
end)

-- ── CONTADOR DE RESULTADOS ─────────────────────────────────

local ResultHeader = Instance.new("Frame")
ResultHeader.Size = UDim2.new(1, 0, 0, 28)
ResultHeader.Position = UDim2.new(0, 0, 0, 100)
ResultHeader.BackgroundTransparency = 1
ResultHeader.Parent = Body

local ResultCountLabel = makeLabel(ResultHeader, "Escribe para buscar palabras", 11, C.TEXT_MUTED, Enum.Font.Gotham)
ResultCountLabel.Size = UDim2.new(0.7, 0, 1, 0)
ResultCountLabel.Position = UDim2.new(0, 4, 0, 0)

local LangBadge = Instance.new("Frame")
LangBadge.Size = UDim2.new(0, 80, 0, 20)
LangBadge.Position = UDim2.new(1, -82, 0.5, -10)
LangBadge.BackgroundColor3 = C.CARD
LangBadge.Parent = ResultHeader
corner(LangBadge, 10)

local LangLabel = makeLabel(LangBadge, "ES + EN", 10, C.ACCENT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
LangLabel.Size = UDim2.new(1, 0, 1, 0)
LangLabel.Position = UDim2.new(0, 0, 0, 0)

-- ── LISTA DE RESULTADOS CON SCROLL ────────────────────────

local LIST_H = CFG.ITEM_HEIGHT * CFG.LIST_VISIBLE  -- altura visible

local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, 0, 0, LIST_H + 2)
ListContainer.Position = UDim2.new(0, 0, 0, 132)
ListContainer.BackgroundColor3 = C.PANEL
ListContainer.BorderSizePixel = 0
ListContainer.ClipsDescendants = true
ListContainer.Parent = Body
corner(ListContainer, 12)
stroke(ListContainer, Color3.fromRGB(30, 35, 60), 1)

-- ScrollingFrame dentro del contenedor
local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size = UDim2.new(1, -12, 1, 0)
ScrollList.Position = UDim2.new(0, 0, 0, 0)
ScrollList.BackgroundTransparency = 1
ScrollList.BorderSizePixel = 0
ScrollList.ScrollBarThickness = 4
ScrollList.ScrollBarImageColor3 = C.BAR_THUMB
ScrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollList.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollList.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
ScrollList.Parent = ListContainer

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 2)
ListLayout.Parent = ScrollList

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 4)
ListPadding.PaddingBottom = UDim.new(0, 4)
ListPadding.PaddingLeft = UDim.new(0, 6)
ListPadding.PaddingRight = UDim.new(0, 4)
ListPadding.Parent = ScrollList

-- PLACEHOLDER (cuando no hay resultados)
local Placeholder = Instance.new("Frame")
Placeholder.Size = UDim2.new(1, 0, 1, 0)
Placeholder.BackgroundTransparency = 1
Placeholder.ZIndex = 3
Placeholder.Parent = ListContainer

local PlaceholderIcon = makeLabel(Placeholder, "⬡", 36, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
PlaceholderIcon.Size = UDim2.new(1, 0, 0, 48)
PlaceholderIcon.Position = UDim2.new(0, 0, 0.3, 0)
PlaceholderIcon.ZIndex = 3

local PlaceholderTxt = makeLabel(Placeholder, "Escribe un prefijo arriba", 13, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
PlaceholderTxt.Size = UDim2.new(1, 0, 0, 22)
PlaceholderTxt.Position = UDim2.new(0, 0, 0.3, 52)
PlaceholderTxt.ZIndex = 3

local PlaceholderSub = makeLabel(Placeholder, "ono · con · arma · esp...", 11, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
PlaceholderSub.Size = UDim2.new(1, 0, 0, 20)
PlaceholderSub.Position = UDim2.new(0, 0, 0.3, 78)
PlaceholderSub.ZIndex = 3

-- ── FOOTER ─────────────────────────────────────────────────

local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 36)
Footer.Position = UDim2.new(0, 0, 0, 456)
Footer.BackgroundTransparency = 1
Footer.Parent = Body

local FooterLeft = makeLabel(Footer, "↕ arrastra para mover", 10, C.TEXT_MUTED, Enum.Font.Gotham)
FooterLeft.Size = UDim2.new(0.6, 0, 1, 0)
FooterLeft.Position = UDim2.new(0, 4, 0, 0)

local FooterRight = makeLabel(Footer, "v2.0 • Delta Mobile", 10, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Right)
FooterRight.Size = UDim2.new(0.4, 0, 1, 0)
FooterRight.Position = UDim2.new(0.6, -4, 0, 0)

-- ============================================================
--               LÓGICA DE RESULTADOS - POOL DE ITEMS
-- ============================================================

-- Pool de frames reutilizables para no crear/destruir en cada búsqueda
local POOL_SIZE = CFG.LIST_VISIBLE + 4
local itemPool = {}

local function createPoolItem(index)
    local row = Instance.new("Frame")
    row.Name = "Row_" .. index
    row.Size = UDim2.new(1, 0, 0, CFG.ITEM_HEIGHT)
    row.BackgroundColor3 = (index % 2 == 0) and C.CARD_ALT or C.CARD
    row.BorderSizePixel = 0
    row.LayoutOrder = index
    row.Visible = false
    row.Parent = ScrollList
    corner(row, 6)

    -- Número
    local numLbl = makeLabel(row, tostring(index), 10, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    numLbl.Name = "Num"
    numLbl.Size = UDim2.new(0, 28, 1, 0)
    numLbl.Position = UDim2.new(0, 0, 0, 0)

    -- Punto de acento
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0, 30, 0.5, -2)
    dot.BackgroundColor3 = C.ACCENT
    dot.BorderSizePixel = 0
    dot.Parent = row
    corner(dot, 2)

    -- Palabra
    local wordLbl = makeLabel(row, "", 14, C.TEXT, Enum.Font.GothamBold)
    wordLbl.Name = "Word"
    wordLbl.Size = UDim2.new(1, -110, 1, 0)
    wordLbl.Position = UDim2.new(0, 40, 0, 0)

    -- Longitud badge
    local lenBadge = Instance.new("Frame")
    lenBadge.Name = "LenBadge"
    lenBadge.Size = UDim2.new(0, 36, 0, 20)
    lenBadge.Position = UDim2.new(1, -90, 0.5, -10)
    lenBadge.BackgroundColor3 = Color3.fromRGB(25, 30, 55)
    lenBadge.BorderSizePixel = 0
    lenBadge.Parent = row
    corner(lenBadge, 6)

    local lenLbl = makeLabel(lenBadge, "0", 10, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    lenLbl.Name = "Len"
    lenLbl.Size = UDim2.new(1, 0, 1, 0)
    lenLbl.Position = UDim2.new(0, 0, 0, 0)

    -- Botón copiar
    local copyBtn = Instance.new("TextButton")
    copyBtn.Name = "Copy"
    copyBtn.Size = UDim2.new(0, 42, 0, 26)
    copyBtn.Position = UDim2.new(1, -46, 0.5, -13)
    copyBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 80)
    copyBtn.BorderSizePixel = 0
    copyBtn.Text = "📋"
    copyBtn.TextSize = 13
    copyBtn.Parent = row
    corner(copyBtn, 6)

    return row
end

-- Crea el pool
for i = 1, POOL_SIZE do
    itemPool[i] = createPoolItem(i)
end

-- Función para actualizar la lista visual
local currentWords = {}

local function renderList(words, total, prefix)
    -- Oculta placeholder
    Placeholder.Visible = (#words == 0)

    -- Actualiza cada item del pool
    for i = 1, POOL_SIZE do
        local row = itemPool[i]
        local word = words[i]
        if word then
            row.Visible = true
            row.BackgroundColor3 = (i % 2 == 0) and C.CARD_ALT or C.CARD
            row:FindFirstChild("Num").Text = tostring(i)
            row:FindFirstChild("Word").Text = word
            row:FindFirstChild("Len"):FindFirstChild("Len") -- workaround
            -- Actualiza longitud
            local lenLbl = row:FindFirstChild("LenBadge") and row:FindFirstChild("LenBadge"):FindFirstChild("Len")
            if lenLbl then lenLbl.Text = tostring(#word) .. "L" end
            -- Actualiza layoutorder
            row.LayoutOrder = i

            -- Resalta el prefijo en la palabra (colorea el texto del prefijo)
            local wordLbl = row:FindFirstChild("Word")
            if wordLbl and #prefix > 0 then
                -- Si la palabra empieza con el prefijo, colorea diferente
                wordLbl.TextColor3 = C.TEXT
            end

            -- Copiar al portapapeles
            local copyBtn = row:FindFirstChild("Copy")
            if copyBtn then
                -- desconecta conexiones previas
                for _, v in ipairs(copyBtn:GetConnectedSignals and copyBtn:GetConnectedSignals() or {}) do
                    pcall(function() v:Disconnect() end)
                end
                local function doCopy()
                    pcall(function()
                        if setclipboard then setclipboard(word)
                        elseif syn and syn.set_clipboard then syn.set_clipboard(word)
                        end
                    end)
                    local orig = copyBtn.BackgroundColor3
                    copyBtn.BackgroundColor3 = C.GREEN
                    copyBtn.Text = "✓"
                    task.delay(0.8, function()
                        if copyBtn and copyBtn.Parent then
                            tween(copyBtn, { BackgroundColor3 = Color3.fromRGB(30, 40, 80) }, 0.3)
                            copyBtn.Text = "📋"
                        end
                    end)
                end
                copyBtn.MouseButton1Click:Connect(doCopy)
                copyBtn.TouchTap:Connect(doCopy)
            end
        else
            row.Visible = false
        end
    end

    -- Ajusta el canvas del scroll basado en total de palabras visibles
    local visibleCount = math.min(#words, POOL_SIZE)
    local canvasH = (visibleCount * (CFG.ITEM_HEIGHT + 2)) + 8
    ScrollList.CanvasSize = UDim2.new(0, 0, 0, canvasH)
    ScrollList.CanvasPosition = Vector2.new(0, 0)

    -- Actualiza contador
    if #words == 0 then
        ResultCountLabel.Text = "Sin resultados"
        ResultCountLabel.TextColor3 = C.RED
    elseif total > CFG.MAX_RESULTS then
        ResultCountLabel.Text = CFG.MAX_RESULTS .. "+ resultados para \"" .. prefix .. "\""
        ResultCountLabel.TextColor3 = C.TEXT_DIM
    else
        ResultCountLabel.Text = total .. " resultado" .. (total ~= 1 and "s" or "") .. " para \"" .. prefix .. "\""
        ResultCountLabel.TextColor3 = C.GREEN
    end
end

-- ============================================================
--              BÚSQUEDA EN TIEMPO REAL
-- ============================================================

local lastPrefix = ""
local searchDebounce = nil

local function doSearch(raw)
    local prefix = normalize(raw)
    if prefix == lastPrefix then return end
    lastPrefix = prefix

    if #prefix == 0 then
        renderList({}, 0, "")
        ResultCountLabel.Text = "Escribe para buscar palabras"
        ResultCountLabel.TextColor3 = C.TEXT_MUTED
        Placeholder.Visible = true
        return
    end

    if not isReady then
        ResultCountLabel.Text = "⏳ Cargando diccionario..."
        ResultCountLabel.TextColor3 = C.TEXT_DIM
        return
    end

    Placeholder.Visible = false
    local words, total = trieSearch(prefix, CFG.MAX_RESULTS)
    currentWords = words
    renderList(words, total, prefix)
end

-- Escucha cambios en tiempo real (mientras escribe)
PrefixBox:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = PrefixBox.Text
    -- Debounce 80ms para no buscar en cada tecla
    if searchDebounce then
        task.cancel(searchDebounce)
    end
    searchDebounce = task.delay(0.08, function()
        doSearch(txt)
    end)
end)

-- También al perder foco (Enter)
PrefixBox.FocusLost:Connect(function(enter)
    if enter then
        doSearch(PrefixBox.Text)
    end
end)

-- ============================================================
--           ANIMACIÓN DE ENTRADA + PULSO DEL DOT
-- ============================================================

-- Entrada con scale
Main.Size = UDim2.new(0, PANEL_W, 0, 0)
Main.Position = UDim2.new(0.5, -PANEL_W/2, 0.5, 0)
tween(Main, {
    Size     = UDim2.new(0, PANEL_W, 0, PANEL_H),
    Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Pulso del dot de estado
local dotPulse = true
task.spawn(function()
    while dotPulse do
        if isReady then
            StatusDot.TextColor3 = C.GREEN
        else
            tween(StatusDot, { TextColor3 = C.ACCENT }, 0.6)
            task.wait(0.6)
            tween(StatusDot, { TextColor3 = C.TEXT_MUTED }, 0.6)
            task.wait(0.6)
        end
        task.wait(0.05)
    end
end)

-- ============================================================
--            CARGA DE DICCIONARIOS (BACKGROUND)
-- ============================================================

task.spawn(function()
    -- 1. Carga semilla interna primero (rápido, sin red)
    StatusTxt.Text = "Cargando base interna..."
    loadSeed()
    CountTxt.Text = totalLoaded .. " palabras"
    tween(ProgressFill, { Size = UDim2.new(0.15, 0, 1, 0) }, 0.3)

    -- Ya puede buscar con las palabras base
    isReady = true
    StatusTxt.Text = "Base lista • descargando más..."
    StatusDot.TextColor3 = C.GREEN

    -- 2. Carga diccionarios en línea
    local progressSteps = { 0.15, 0.6, 1.0 }
    for idx, entry in ipairs(URLS) do
        StatusTxt.Text = "Descargando " .. entry.lang .. "..."
        StatusDot.TextColor3 = C.ACCENT
        local count = loadFromURL(entry)
        totalLoaded = totalLoaded + count
        CountTxt.Text = totalLoaded .. " palabras"
        tween(ProgressFill, { Size = UDim2.new(progressSteps[idx + 1] or 1, 0, 1, 0) }, 0.5)
        StatusTxt.Text = "✓ " .. entry.lang .. " +" .. count
        StatusDot.TextColor3 = C.GREEN
        task.wait(0.4)
    end

    -- Listo total
    tween(ProgressFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.3)
    task.wait(0.4)
    StatusTxt.Text = "✓ Diccionario completo listo"
    StatusDot.TextColor3 = C.GREEN
    CountTxt.Text = totalLoaded .. " palabras"

    -- Refresca si ya había texto escrito
    if #PrefixBox.Text > 0 then
        lastPrefix = ""
        doSearch(PrefixBox.Text)
    end

    -- Después de 3s colapsa la barra de estado
    task.wait(3)
    tween(StatusBar, { Size = UDim2.new(1, 0, 0, 0) }, 0.3)
    tween(InputContainer, { Position = UDim2.new(0, 0, 0, 4) }, 0.3)
    tween(ResultHeader, { Position = UDim2.new(0, 0, 0, 64) }, 0.3)
    tween(ListContainer, { Position = UDim2.new(0, 0, 0, 96), Size = UDim2.new(1, 0, 0, LIST_H + 38) }, 0.3)
end)
