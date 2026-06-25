-- ============================================================
--                    CONECTA PALABRAS 
-- ============================================================

-- ============================================================
--                   SERVICIOS Y CONFIG
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local CFG = {
    MAX_RESULTS  = 150,
    ITEM_HEIGHT  = 36,
    LIST_VISIBLE = 8,
    ANIM_TIME    = 0.18,
    VERSION      = "3.0",
}

-- ============================================================
--             HTTP HELPER (compatible con exploits)
-- ============================================================
-- Delta/Synapse/KRNL usan request() en lugar de HttpService

local function httpGet(url)
    -- Intenta con request() (Delta, KRNL, Synapse X, etc.)
    if request then
        local ok, res = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body and #res.Body > 10 then
            return true, res.Body
        end
    end
    -- Fallback: syn.request
    if syn and syn.request then
        local ok, res = pcall(function()
            return syn.request({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body and #res.Body > 10 then
            return true, res.Body
        end
    end
    -- Fallback: http.request (algunos exploits)
    if http and http.request then
        local ok, res = pcall(function()
            return http.request({ Url = url, Method = "GET" })
        end)
        if ok and res and res.Body and #res.Body > 10 then
            return true, res.Body
        end
    end
    -- Último fallback: HttpService (solo en Studio o exploits que lo permiten)
    local hs = game:GetService("HttpService")
    if hs then
        local ok, body = pcall(function()
            return hs:GetAsync(url, true)
        end)
        if ok and body and #body > 10 then
            return true, body
        end
    end
    return false, nil
end

-- POST para OpenRouter AI
local function httpPost(url, headers, body)
    if request then
        local ok, res = pcall(function()
            return request({
                Url     = url,
                Method  = "POST",
                Headers = headers,
                Body    = body,
            })
        end)
        if ok and res then return true, res.Body end
    end
    if syn and syn.request then
        local ok, res = pcall(function()
            return syn.request({
                Url     = url,
                Method  = "POST",
                Headers = headers,
                Body    = body,
            })
        end)
        if ok and res then return true, res.Body end
    end
    if http and http.request then
        local ok, res = pcall(function()
            return http.request({
                Url     = url,
                Method  = "POST",
                Headers = headers,
                Body    = body,
            })
        end)
        if ok and res then return true, res.Body end
    end
    return false, nil
end

-- JSON mínimo (sin dependencias externas)
local function jsonEncode(t)
    local function enc(v)
        local tp = type(v)
        if tp == "string" then
            -- escapa caracteres especiales
            v = v:gsub('\\', '\\\\')
            v = v:gsub('"', '\\"')
            v = v:gsub('\n', '\\n')
            v = v:gsub('\r', '\\r')
            v = v:gsub('\t', '\\t')
            return '"' .. v .. '"'
        elseif tp == "number" then
            return tostring(v)
        elseif tp == "boolean" then
            return v and "true" or "false"
        elseif tp == "table" then
            -- ¿array?
            local isArr = (#v > 0)
            if isArr then
                local parts = {}
                for _, item in ipairs(v) do
                    parts[#parts+1] = enc(item)
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                local parts = {}
                for k, val in pairs(v) do
                    parts[#parts+1] = '"' .. tostring(k) .. '":' .. enc(val)
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        end
        return "null"
    end
    return enc(t)
end

local function jsonDecodeSimple(s)
    -- extrae el primer campo "content" de una respuesta OpenRouter
    -- Busca: "content":"..."
    local content = s:match('"content"%s*:%s*"(.-[^\\])"')
    if content then
        content = content:gsub('\\"', '"')
        content = content:gsub('\\n', '\n')
        content = content:gsub('\\\\', '\\')
        return content
    end
    -- Fallback: busca cualquier texto largo entre comillas después de content
    content = s:match('"content":"(.-)"')
    return content or "Sin respuesta"
end

-- ============================================================
--                   PALETA Y ESTILO
-- ============================================================

local C = {
    BG         = Color3.fromRGB(8,   10,  18),
    PANEL      = Color3.fromRGB(14,  17,  28),
    CARD       = Color3.fromRGB(20,  24,  40),
    CARD_ALT   = Color3.fromRGB(24,  28,  48),
    CARD_HL    = Color3.fromRGB(28,  35,  65),
    ACCENT     = Color3.fromRGB(82,  130, 255),
    ACCENT2    = Color3.fromRGB(120, 80,  255),
    ACCENT3    = Color3.fromRGB(60,  200, 255),
    GREEN      = Color3.fromRGB(60,  210, 140),
    RED        = Color3.fromRGB(255, 75,  90),
    ORANGE     = Color3.fromRGB(255, 160, 60),
    TEXT       = Color3.fromRGB(225, 228, 255),
    TEXT_DIM   = Color3.fromRGB(130, 135, 170),
    TEXT_MUTED = Color3.fromRGB(65,  70,  105),
    BAR        = Color3.fromRGB(28,  32,  55),
    BAR_THUMB  = Color3.fromRGB(82,  130, 255),
    WHITE      = Color3.fromRGB(255, 255, 255),
    BLACK      = Color3.fromRGB(0,   0,   0),
    AI_BG      = Color3.fromRGB(12,  20,  38),
    AI_MSG     = Color3.fromRGB(18,  28,  52),
    AI_USER    = Color3.fromRGB(22,  40,  70),
    SETTINGS   = Color3.fromRGB(14,  18,  32),
}

-- ============================================================
--                   TRIE - BÚSQUEDA RÁPIDA
-- ============================================================

local TrieNode = {}
TrieNode.__index = TrieNode
function TrieNode.new()
    return setmetatable({ ch = {}, words = {} }, TrieNode)
end

local rootTrie   = TrieNode.new()
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
    node.words[word] = true
end

local function trieCollect(node, results, limit)
    if #results >= limit then return end
    for w in pairs(node.words) do
        results[#results+1] = w
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
    trieCollect(node, results, limit + 200)
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
    w = tostring(w):lower():match("^%s*(.-)%s*$") or ""
    for acc, plain in pairs(accentMap) do
        w = w:gsub(acc, plain)
    end
    return w
end

-- ============================================================
--              DICCIONARIO SEED (ampliado ES + EN)
-- ============================================================

local SEED = {
    -- ─── ESPAÑOL A ───
    "abad","abajo","abandonar","abarcar","abejas","abertura","abismo","ablandar",
    "abolir","abono","abordar","abrazo","abrir","absurdo","abuelo","abuela","abundar",
    "acabar","academia","accion","aceite","acento","aceptar","acero","aclarar",
    "acoger","acorde","acoso","acto","actor","actriz","acudir","acuerdo","acusar",
    "adaptar","adelante","adentro","adivinar","admitir","adorar","adulto","afecto",
    "aficion","agencia","agosto","agregar","agua","aguila","aguja","ahora","aire",
    "ajeno","ajustar","alabar","aldea","alegre","alegria","alejar","alma","altar",
    "alto","altura","amanecer","amar","amargo","ambiente","amigo","amiga","amor",
    "amora","amplio","ancho","angulo","animal","animo","antes","anuncio","apagar",
    "apoyo","aprender","arbol","arena","arma","armada","armado","armadura",
    "armamento","armar","armario","armas","aroma","arte","ayer","azul","azucar",
    -- ─── ESPAÑOL B ───
    "bailar","baile","banco","barco","barrio","batalla","bello","bella","besar",
    "blanco","boca","bonito","bosque","brazo","bueno","buscar","burbuja",
    -- ─── ESPAÑOL C ───
    "cabeza","camino","campo","cantar","casa","cielo","ciudad","cojer","cojo",
    "coja","cojos","cojas","conocer","corazon","correr","comer","comprar","coche",
    "cocina","colores","corona","contra","contigo","construir","concepto","cosa",
    "cuerpo","cuatro","cinco","cien","calor","calma","cambio","cancion","claro",
    "clase","clima","cobrar","cocinar","color","comenzar","comer","comprender",
    "comunicar","confianza","confiar","conjunto","contacto","contar","corriente",
    "crecer","crear","creer","critica","cultura","cumplir","curiosidad",
    -- ─── ESPAÑOL D ───
    "danza","dato","dedo","dia","dinero","dormir","dulce","durante","donde",
    "deber","decidir","defender","dejar","deseo","destino","diez","dominar",
    "duda","dueno","dureza",
    -- ─── ESPAÑOL E ───
    "edad","elegir","empezar","encontrar","energia","entre","entonces","escuela",
    "escribir","escuchar","esperar","esta","estar","estrella","espejo","espacio",
    "espada","espalda","especial","esperanza","estilo","esfuerzo","existir","exito",
    -- ─── ESPAÑOL F ───
    "familia","feliz","final","flor","forma","fuerza","fuego","fruta","frente",
    "famoso","fiel","fluir","fondo","futuro","fe",
    -- ─── ESPAÑOL G ───
    "gato","grande","gracias","grupo","gente","guerra","gusto","globo","gris",
    "ganar","genio","gloria","gritar","guiar",
    -- ─── ESPAÑOL H ───
    "hablar","hacer","hermano","hermana","hombre","hora","historia","hueso",
    "hallar","herramienta","honor","horizonte","humano","humilde",
    -- ─── ESPAÑOL I ───
    "idea","idioma","igual","inicio","imagen","importante","isla","identidad",
    "ilusion","impulso","interes","intuicion",
    -- ─── ESPAÑOL J ───
    "jardin","jefe","joven","juego","justo","junto","jornada","juicio",
    -- ─── ESPAÑOL L ───
    "largo","libro","lugar","luna","lengua","lento","libre","luchar","luz",
    "latir","lazo","leal","lejos","llamar","llegar","lleno","lograr",
    -- ─── ESPAÑOL M ───
    "mano","mar","mundo","mujer","madre","malo","mapa","mesa","musica","mirar",
    "mente","meta","miedo","mismo","modo","momento","motor","mover","mejora",
    -- ─── ESPAÑOL N ───
    "noche","nombre","nuevo","nunca","nadie","natural","negro","nivel","norte",
    "nacion","necesitar","noble","norma",
    -- ─── ESPAÑOL O ───
    "obra","oreja","oscuro","objeto","oeste","oso","osa","osos","osas",
    "orden","origen","olvido","opinar","opcion",
    -- ─── ESPAÑOL P ───
    "padre","pais","palabra","papel","parque","perro","pequeno","poder","pez",
    "primera","persona","puerta","plaza","planta","plata","playa","poca","poco",
    "paciencia","pasion","paz","pensar","perder","pieza","planeta","presente",
    "problema","proceso","promesa","propio","pulso",
    -- ─── ESPAÑOL Q ───
    "querer","quien","quiza","quieto","quedar",
    -- ─── ESPAÑOL R ───
    "rama","rapido","raton","reino","reto","rato","rio","rojo",
    "raiz","razon","realidad","recuerdo","reflejo","regla","relacion","respeto",
    "respuesta","riesgo","ritmo","rumbo",
    -- ─── ESPAÑOL S ───
    "sala","saltar","sangre","saber","secreto","segundo","siempre","sobre","sol",
    "sencillo","sentir","sera","ser","silencio","simple","sistema","solucion",
    "sueno","surco",
    -- ─── ESPAÑOL T ───
    "tarde","tener","tercer","tiempo","tierra","todo","trabajo","triste",
    "talento","tarea","temor","teoria","terminar","tomar","total","tradicion",
    -- ─── ESPAÑOL U ───
    "ultimo","unir","uno","usar","unico","universo",
    "union","urgente","utopia",
    -- ─── ESPAÑOL V ───
    "valor","vida","vez","viento","verde","volar","voz","viejo","vista",
    "valiente","verdad","version","via","viaje","vision","voluntad",
    -- ─── ESPAÑOL Z ───
    "zapato","zona","zumo","zafiro","zorro","zanjar",
    -- ─── ESPECIALES ───
    "ono","onomatopeya",

    -- ─── INGLÉS A ───
    "able","absorb","abstract","accept","access","action","active","adapt","add",
    "adopt","advance","after","again","age","agree","ahead","aim","alert","align",
    "alive","allow","almost","along","already","also","always","among","ancient",
    "animal","answer","appear","apple","apply","approach","area","argue","around",
    "arrive","arrow","ask","assume","atom","attempt","attract","autumn","aware",
    -- ─── INGLÉS B ───
    "back","balance","ball","bank","base","bear","beat","become","before","begin",
    "believe","belong","beneath","beyond","bind","bird","black","blame","blend",
    "block","bloom","blue","bond","book","born","both","brain","branch","brave",
    "break","breathe","bridge","bright","bring","broad","build","burn","burst",
    -- ─── INGLÉS C ───
    "call","calm","came","capture","card","carry","catch","cause","center","chain",
    "chance","change","chase","check","child","choose","circle","city","claim",
    "clear","climb","close","code","cold","collect","color","combine","come",
    "commit","common","complete","connect","consider","control","cool","copy",
    "core","count","country","cover","craft","crash","create","cross","cut",
    -- ─── INGLÉS D ───
    "dark","dash","data","deal","decide","deep","define","describe","design",
    "detail","develop","direct","discover","display","divide","door","down","dream",
    "drive","drop","dynamic",
    -- ─── INGLÉS E ───
    "each","edge","eight","empty","engage","enter","even","every","evolve","exact",
    "expand","experience","explore","express","extend","eye",
    -- ─── INGLÉS F ───
    "face","fact","fall","fast","field","fight","fill","find","fire","first",
    "five","flag","flat","flow","focus","follow","food","force","form","four",
    "free","fresh","from","full","future",
    -- ─── INGLÉS G ───
    "game","gather","girl","give","glad","glass","good","grant","great","green",
    "ground","group","grow","guide",
    -- ─── INGLÉS H ───
    "hand","happy","hard","head","heal","hear","heart","heavy","help","here",
    "high","hold","home","hope","huge","human","hunt",
    -- ─── INGLÉS I ───
    "idea","impact","improve","include","inner","into","iron",
    -- ─── INGLÉS J-K ───
    "join","just","keep","kind","king","know",
    -- ─── INGLÉS L ───
    "land","large","last","late","layer","lead","learn","left","level","life",
    "light","link","lion","list","live","long","look","loop","lose","love",
    -- ─── INGLÉS M ───
    "made","make","many","mark","meet","merge","mind","miss","mode","moon",
    "more","most","move","much","must",
    -- ─── INGLÉS N ───
    "name","near","need","next","night","node","none","note","null",
    -- ─── INGLÉS O ───
    "observe","only","open","orbit","order","other","over",
    -- ─── INGLÉS P ───
    "page","part","past","path","pattern","peak","pick","place","plan","play",
    "point","power","pull","push",
    -- ─── INGLÉS Q-R ───
    "quest","quick","race","rain","reach","read","real","rely","rest","reveal",
    "ride","ring","rise","road","rock","role","room","rule","rush",
    -- ─── INGLÉS S ───
    "same","save","scan","seek","seem","send","side","sign","sing","slow","snow",
    "some","song","soon","soul","space","spark","split","start","stay","step",
    "still","stop","store","story","stream","strong","such","surge","swim",
    -- ─── INGLÉS T ───
    "task","tell","test","than","then","time","told","track","trail","tree",
    "true","trust","turn","type",
    -- ─── INGLÉS U-V ───
    "unity","used","vast","view","voice",
    -- ─── INGLÉS W ───
    "wait","walk","warm","water","wave","well","wide","will","wind","wise",
    "word","work","world","write",
    -- ─── INGLÉS X-Z ───
    "yield","zero","zone","zoom",
}

local function loadSeed()
    local count = 0
    for _, w in ipairs(SEED) do
        local n = normalize(w)
        if n:match("^[a-z]+$") and #n >= 2 then
            trieInsert(n)
            count = count + 1
        end
    end
    totalLoaded = totalLoaded + count
    return count
end

local URLS = {
    { lang="EN", url="https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt", fmt="txt"  },
    { lang="ES", url="https://raw.githubusercontent.com/words/an-array-of-spanish-words/master/index.js", fmt="js" },
}

local function loadFromURL(entry)
    local ok, body = httpGet(entry.url)
    if not ok or not body then return 0 end
    local count = 0
    if entry.fmt == "js" then
        for w in body:gmatch('"([^"]+)"') do
            local n = normalize(w)
            if n:match("^[a-z]+$") and #n >= 2 and #n <= 28 then
                trieInsert(n)
                count = count + 1
            end
        end
    else
        for line in body:gmatch("[^\r\n]+") do
            local n = normalize(line:match("^%s*(.-)%s*$") or "")
            if n:match("^[a-z]+$") and #n >= 2 and #n <= 28 then
                trieInsert(n)
                count = count + 1
            end
        end
    end
    totalLoaded = totalLoaded + count
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
    -- elimina stroke previo si existe
    local prev = parent:FindFirstChildOfClass("UIStroke")
    if prev then prev:Destroy() end
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function tw(obj, props, t, style, dir)
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

local function makeBtn(parent, text, size, bgColor, textColor)
    local b = Instance.new("TextButton")
    b.Size = size or UDim2.new(0, 80, 0, 28)
    b.BackgroundColor3 = bgColor or C.CARD
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = textColor or C.TEXT
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.AutoButtonColor = false
    b.Parent = parent
    corner(b, 8)
    return b
end

-- ============================================================
--                   CONSTRUCCIÓN DE GUI
-- ============================================================

pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("CW_GUI")
    if old then old:Destroy() end
end)
pcall(function()
    local old = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("CW_GUI")
    if old then old:Destroy() end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "CW_GUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
local ok2 = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ok2 or not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ── VENTANA PRINCIPAL ──────────────────────────────────────

local PANEL_W = 350
local PANEL_H = 560

local Main = Instance.new("Frame")
Main.Name            = "Main"
Main.Size            = UDim2.new(0, PANEL_W, 0, 0)
Main.Position        = UDim2.new(0.5, -PANEL_W/2, 0.5, 0)
Main.BackgroundColor3 = C.BG
Main.BorderSizePixel = 0
Main.Active          = true
Main.Draggable       = true
Main.ClipsDescendants = true
Main.Parent          = ScreenGui
corner(Main, 16)
stroke(Main, Color3.fromRGB(40, 46, 80), 1.5)

-- ── HEADER ─────────────────────────────────────────────────

local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 54)
Header.BackgroundColor3 = C.PANEL
Header.BorderSizePixel  = 0
Header.Parent           = Main
corner(Header, 16)

-- Fix esquinas inferiores del header
local HFix = Instance.new("Frame")
HFix.Size             = UDim2.new(1, 0, 0, 16)
HFix.Position         = UDim2.new(0, 0, 1, -16)
HFix.BackgroundColor3 = C.PANEL
HFix.BorderSizePixel  = 0
HFix.ZIndex           = Header.ZIndex
HFix.Parent           = Header

-- Barra acento top
local AccentBar = Instance.new("Frame")
AccentBar.Size            = UDim2.new(1, 0, 0, 3)
AccentBar.BackgroundColor3 = C.ACCENT
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex          = Header.ZIndex + 1
AccentBar.Parent          = Main
corner(AccentBar, 3)
gradient(AccentBar, C.ACCENT, C.ACCENT2, 0)

local TitleIcon = makeLabel(Header, "⬡", 20, C.ACCENT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
TitleIcon.Size     = UDim2.new(0, 38, 1, 0)
TitleIcon.Position = UDim2.new(0, 8, 0, 0)
TitleIcon.ZIndex   = Header.ZIndex + 1

local TitleLbl = makeLabel(Header, "CONECTA PALABRAS", 14, C.TEXT, Enum.Font.GothamBold)
TitleLbl.Size     = UDim2.new(1, -160, 0, 22)
TitleLbl.Position = UDim2.new(0, 50, 0, 8)
TitleLbl.ZIndex   = Header.ZIndex + 1

local SubLbl = makeLabel(Header, "Word Finder Pro + IA  v" .. CFG.VERSION, 10, C.TEXT_DIM, Enum.Font.Gotham)
SubLbl.Size     = UDim2.new(1, -160, 0, 16)
SubLbl.Position = UDim2.new(0, 50, 0, 30)
SubLbl.ZIndex   = Header.ZIndex + 1

-- Botón ⚙ Ajustes (API Key)
local SettingsBtn = makeBtn(Header, "⚙", UDim2.new(0, 32, 0, 32), Color3.fromRGB(25, 30, 52), C.TEXT_DIM)
SettingsBtn.Position = UDim2.new(1, -76, 0.5, -16)
SettingsBtn.ZIndex   = Header.ZIndex + 2
SettingsBtn.TextSize = 16
corner(SettingsBtn, 8)

-- Botón cerrar
local CloseBtn = makeBtn(Header, "✕", UDim2.new(0, 32, 0, 32), Color3.fromRGB(50, 18, 22), C.RED)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.ZIndex   = Header.ZIndex + 2
corner(CloseBtn, 8)

local function doClose()
    tw(Main, { Size = UDim2.new(0, PANEL_W, 0, 0), Position = UDim2.new(0.5, -PANEL_W/2, 0.5, 0) }, 0.2)
    task.delay(0.25, function() ScreenGui:Destroy() end)
end
CloseBtn.MouseButton1Click:Connect(doClose)
CloseBtn.TouchTap:Connect(doClose)

-- ── CUERPO ─────────────────────────────────────────────────

local Body = Instance.new("Frame")
Body.Size                = UDim2.new(1, -20, 1, -62)
Body.Position            = UDim2.new(0, 10, 0, 58)
Body.BackgroundTransparency = 1
Body.Parent              = Main

-- ── STATUS BAR ─────────────────────────────────────────────

local StatusBar = Instance.new("Frame")
StatusBar.Size            = UDim2.new(1, 0, 0, 30)
StatusBar.Position        = UDim2.new(0, 0, 0, 0)
StatusBar.BackgroundColor3 = C.CARD
StatusBar.BorderSizePixel = 0
StatusBar.Parent          = Body
corner(StatusBar, 8)

local StatusDot = makeLabel(StatusBar, "●", 11, C.ACCENT, Enum.Font.Gotham, Enum.TextXAlignment.Center)
StatusDot.Size     = UDim2.new(0, 22, 1, 0)
StatusDot.Position = UDim2.new(0, 2, 0, 0)

local StatusTxt = makeLabel(StatusBar, "Cargando...", 10, C.TEXT_DIM, Enum.Font.Gotham)
StatusTxt.Size     = UDim2.new(1, -110, 1, 0)
StatusTxt.Position = UDim2.new(0, 24, 0, 0)

local CountTxt = makeLabel(StatusBar, "0 palabras", 10, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Right)
CountTxt.Size     = UDim2.new(0, 88, 1, 0)
CountTxt.Position = UDim2.new(1, -90, 0, 0)

local ProgTrack = Instance.new("Frame")
ProgTrack.Size            = UDim2.new(1, 0, 0, 2)
ProgTrack.Position        = UDim2.new(0, 0, 1, -2)
ProgTrack.BackgroundColor3 = C.BAR
ProgTrack.BorderSizePixel = 0
ProgTrack.Parent          = StatusBar
corner(ProgTrack, 2)

local ProgFill = Instance.new("Frame")
ProgFill.Size            = UDim2.new(0, 0, 1, 0)
ProgFill.BackgroundColor3 = C.ACCENT
ProgFill.BorderSizePixel  = 0
ProgFill.Parent           = ProgTrack
corner(ProgFill, 2)
gradient(ProgFill, C.ACCENT, C.ACCENT2, 0)

-- ── INPUT ──────────────────────────────────────────────────

local InputFrame = Instance.new("Frame")
InputFrame.Size            = UDim2.new(1, 0, 0, 48)
InputFrame.Position        = UDim2.new(0, 0, 0, 36)
InputFrame.BackgroundColor3 = C.CARD
InputFrame.BorderSizePixel = 0
InputFrame.Parent          = Body
corner(InputFrame, 12)
stroke(InputFrame, Color3.fromRGB(35, 42, 72), 1)

local InputIcon = makeLabel(InputFrame, "🔍", 16, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)
InputIcon.Size     = UDim2.new(0, 38, 1, 0)
InputIcon.Position = UDim2.new(0, 0, 0, 0)

local PrefixBox = Instance.new("TextBox")
PrefixBox.Size               = UDim2.new(1, -88, 1, -10)
PrefixBox.Position           = UDim2.new(0, 40, 0, 5)
PrefixBox.BackgroundTransparency = 1
PrefixBox.PlaceholderText    = "ono, arma, con, amor..."
PrefixBox.PlaceholderColor3  = C.TEXT_MUTED
PrefixBox.Text               = ""
PrefixBox.TextColor3         = C.TEXT
PrefixBox.TextSize           = 17
PrefixBox.Font               = Enum.Font.GothamBold
PrefixBox.ClearTextOnFocus   = false
PrefixBox.TextXAlignment     = Enum.TextXAlignment.Left
PrefixBox.Parent             = InputFrame

local ClearBtn = makeBtn(InputFrame, "✕", UDim2.new(0, 38, 0, 28), Color3.fromRGB(32, 22, 28), C.TEXT_DIM)
ClearBtn.Position = UDim2.new(1, -42, 0.5, -14)
ClearBtn.TextSize = 12

ClearBtn.MouseButton1Click:Connect(function() PrefixBox.Text = "" PrefixBox:CaptureFocus() end)
ClearBtn.TouchTap:Connect(function() PrefixBox.Text = "" end)

PrefixBox.Focused:Connect(function()
    tw(InputFrame, { BackgroundColor3 = C.CARD_HL }, 0.15)
    stroke(InputFrame, C.ACCENT, 1.5)
end)
PrefixBox.FocusLost:Connect(function()
    tw(InputFrame, { BackgroundColor3 = C.CARD }, 0.15)
    stroke(InputFrame, Color3.fromRGB(35, 42, 72), 1)
end)

-- ── TABS (Buscar / IA) ─────────────────────────────────────

local TabBar = Instance.new("Frame")
TabBar.Size            = UDim2.new(1, 0, 0, 28)
TabBar.Position        = UDim2.new(0, 0, 0, 90)
TabBar.BackgroundColor3 = C.PANEL
TabBar.BorderSizePixel = 0
TabBar.Parent          = Body
corner(TabBar, 8)

local TabSearch = makeBtn(TabBar, "🔍 Buscar", UDim2.new(0.5, -2, 1, -4), C.ACCENT, C.WHITE)
TabSearch.Position = UDim2.new(0, 2, 0, 2)
corner(TabSearch, 6)

local TabAI = makeBtn(TabBar, "🤖 IA", UDim2.new(0.5, -2, 1, -4), Color3.fromRGB(22, 25, 45), C.TEXT_DIM)
TabAI.Position = UDim2.new(0.5, 0, 0, 2)
corner(TabAI, 6)

-- ── RESULTADO HEADER ───────────────────────────────────────

local ResHeader = Instance.new("Frame")
ResHeader.Size                = UDim2.new(1, 0, 0, 24)
ResHeader.Position            = UDim2.new(0, 0, 0, 124)
ResHeader.BackgroundTransparency = 1
ResHeader.Parent              = Body

local ResCountLbl = makeLabel(ResHeader, "Escribe para buscar", 10, C.TEXT_MUTED, Enum.Font.Gotham)
ResCountLbl.Size     = UDim2.new(0.75, 0, 1, 0)
ResCountLbl.Position = UDim2.new(0, 2, 0, 0)

local LangBadge = Instance.new("Frame")
LangBadge.Size            = UDim2.new(0, 72, 0, 18)
LangBadge.Position        = UDim2.new(1, -74, 0.5, -9)
LangBadge.BackgroundColor3 = C.CARD
LangBadge.Parent          = ResHeader
corner(LangBadge, 9)

local LangLbl = makeLabel(LangBadge, "ES + EN", 9, C.ACCENT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
LangLbl.Size     = UDim2.new(1, 0, 1, 0)
LangLbl.Position = UDim2.new(0, 0, 0, 0)

-- ── LISTA DE RESULTADOS ────────────────────────────────────

local LIST_H = CFG.ITEM_HEIGHT * CFG.LIST_VISIBLE

local ListContainer = Instance.new("Frame")
ListContainer.Size             = UDim2.new(1, 0, 0, LIST_H + 2)
ListContainer.Position         = UDim2.new(0, 0, 0, 152)
ListContainer.BackgroundColor3 = C.PANEL
ListContainer.BorderSizePixel  = 0
ListContainer.ClipsDescendants = true
ListContainer.Parent           = Body
corner(ListContainer, 10)
stroke(ListContainer, Color3.fromRGB(28, 32, 55), 1)

local ScrollList = Instance.new("ScrollingFrame")
ScrollList.Size                = UDim2.new(1, -10, 1, 0)
ScrollList.Position            = UDim2.new(0, 0, 0, 0)
ScrollList.BackgroundTransparency = 1
ScrollList.BorderSizePixel     = 0
ScrollList.ScrollBarThickness  = 3
ScrollList.ScrollBarImageColor3 = C.BAR_THUMB
ScrollList.CanvasSize          = UDim2.new(0, 0, 0, 0)
ScrollList.ScrollingDirection  = Enum.ScrollingDirection.Y
ScrollList.Parent              = ListContainer

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding   = UDim.new(0, 2)
ListLayout.Parent    = ScrollList

local ListPad = Instance.new("UIPadding")
ListPad.PaddingTop    = UDim.new(0, 3)
ListPad.PaddingBottom = UDim.new(0, 3)
ListPad.PaddingLeft   = UDim.new(0, 4)
ListPad.PaddingRight  = UDim.new(0, 2)
ListPad.Parent        = ScrollList

-- Placeholder
local PHFrame = Instance.new("Frame")
PHFrame.Size                = UDim2.new(1, 0, 1, 0)
PHFrame.BackgroundTransparency = 1
PHFrame.ZIndex              = 3
PHFrame.Parent              = ListContainer

local PHIcon = makeLabel(PHFrame, "⬡", 32, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
PHIcon.Size     = UDim2.new(1, 0, 0, 44)
PHIcon.Position = UDim2.new(0, 0, 0.28, 0)
PHIcon.ZIndex   = 3

local PHTxt = makeLabel(PHFrame, "Escribe un prefijo arriba", 12, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
PHTxt.Size     = UDim2.new(1, 0, 0, 20)
PHTxt.Position = UDim2.new(0, 0, 0.28, 48)
PHTxt.ZIndex   = 3

local PHSub = makeLabel(PHFrame, "ono · con · arma · amor · esp...", 10, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
PHSub.Size     = UDim2.new(1, 0, 0, 18)
PHSub.Position = UDim2.new(0, 0, 0.28, 72)
PHSub.ZIndex   = 3

-- ── PANEL IA ───────────────────────────────────────────────

local AIPanel = Instance.new("Frame")
AIPanel.Size             = UDim2.new(1, 0, 0, LIST_H + 26 + 24)
AIPanel.Position         = UDim2.new(0, 0, 0, 124)
AIPanel.BackgroundColor3 = C.AI_BG
AIPanel.BorderSizePixel  = 0
AIPanel.Visible          = false
AIPanel.ClipsDescendants = true
AIPanel.Parent           = Body
corner(AIPanel, 10)
stroke(AIPanel, Color3.fromRGB(30, 40, 80), 1)

-- Chat scroll
local AIScroll = Instance.new("ScrollingFrame")
AIScroll.Size                = UDim2.new(1, 0, 1, -48)
AIScroll.Position            = UDim2.new(0, 0, 0, 0)
AIScroll.BackgroundTransparency = 1
AIScroll.BorderSizePixel     = 0
AIScroll.ScrollBarThickness  = 3
AIScroll.ScrollBarImageColor3 = C.BAR_THUMB
AIScroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
AIScroll.ScrollingDirection  = Enum.ScrollingDirection.Y
AIScroll.Parent              = AIPanel

local AILayout = Instance.new("UIListLayout")
AILayout.SortOrder = Enum.SortOrder.LayoutOrder
AILayout.Padding   = UDim.new(0, 6)
AILayout.Parent    = AIScroll

local AIPad = Instance.new("UIPadding")
AIPad.PaddingTop    = UDim.new(0, 6)
AIPad.PaddingBottom = UDim.new(0, 6)
AIPad.PaddingLeft   = UDim.new(0, 6)
AIPad.PaddingRight  = UDim.new(0, 6)
AIPad.Parent        = AIScroll

-- Barra input IA
local AIInputBar = Instance.new("Frame")
AIInputBar.Size            = UDim2.new(1, 0, 0, 44)
AIInputBar.Position        = UDim2.new(0, 0, 1, -44)
AIInputBar.BackgroundColor3 = C.CARD
AIInputBar.BorderSizePixel = 0
AIInputBar.Parent          = AIPanel
corner(AIInputBar, 8)

local AIBox = Instance.new("TextBox")
AIBox.Size               = UDim2.new(1, -60, 1, -10)
AIBox.Position           = UDim2.new(0, 6, 0, 5)
AIBox.BackgroundTransparency = 1
AIBox.PlaceholderText    = "Pide palabras con 'ono', 'arm'..."
AIBox.PlaceholderColor3  = C.TEXT_MUTED
AIBox.Text               = ""
AIBox.TextColor3         = C.TEXT
AIBox.TextSize           = 13
AIBox.Font               = Enum.Font.Gotham
AIBox.ClearTextOnFocus   = false
AIBox.TextXAlignment     = Enum.TextXAlignment.Left
AIBox.TextWrapped        = true
AIBox.MultiLine          = false
AIBox.Parent             = AIInputBar

local AISendBtn = makeBtn(AIInputBar, "➤", UDim2.new(0, 46, 0, 34), C.ACCENT, C.WHITE)
AISendBtn.Position = UDim2.new(1, -50, 0.5, -17)
AISendBtn.TextSize = 14
corner(AISendBtn, 8)

-- ── PANEL SETTINGS (API KEY) ────────────────────────────────

local SettingsPanel = Instance.new("Frame")
SettingsPanel.Size            = UDim2.new(1, 0, 1, 0)
SettingsPanel.BackgroundColor3 = C.SETTINGS
SettingsPanel.BorderSizePixel = 0
SettingsPanel.Visible         = false
SettingsPanel.ZIndex          = 20
SettingsPanel.Parent          = Main
corner(SettingsPanel, 16)

local SetTitle = makeLabel(SettingsPanel, "⚙  Configuración IA", 15, C.TEXT, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
SetTitle.Size     = UDim2.new(1, 0, 0, 44)
SetTitle.Position = UDim2.new(0, 0, 0, 10)
SetTitle.ZIndex   = 21

local SetDesc = makeLabel(SettingsPanel, "OpenRouter API Key:", 11, C.TEXT_DIM, Enum.Font.Gotham)
SetDesc.Size     = UDim2.new(1, -24, 0, 18)
SetDesc.Position = UDim2.new(0, 12, 0, 64)
SetDesc.ZIndex   = 21

local APIKeyFrame = Instance.new("Frame")
APIKeyFrame.Size            = UDim2.new(1, -24, 0, 44)
APIKeyFrame.Position        = UDim2.new(0, 12, 0, 84)
APIKeyFrame.BackgroundColor3 = C.CARD
APIKeyFrame.BorderSizePixel = 0
APIKeyFrame.ZIndex          = 21
APIKeyFrame.Parent          = SettingsPanel
corner(APIKeyFrame, 10)
stroke(APIKeyFrame, Color3.fromRGB(40, 50, 90), 1)

local APIKeyBox = Instance.new("TextBox")
APIKeyBox.Size               = UDim2.new(1, -12, 1, -10)
APIKeyBox.Position           = UDim2.new(0, 6, 0, 5)
APIKeyBox.BackgroundTransparency = 1
APIKeyBox.PlaceholderText    = "sk-or-v1-..."
APIKeyBox.PlaceholderColor3  = C.TEXT_MUTED
APIKeyBox.Text               = ""
APIKeyBox.TextColor3         = C.TEXT
APIKeyBox.TextSize           = 13
APIKeyBox.Font               = Enum.Font.Gotham
APIKeyBox.ClearTextOnFocus   = false
APIKeyBox.TextXAlignment     = Enum.TextXAlignment.Left
APIKeyBox.ZIndex             = 22
APIKeyBox.Parent             = APIKeyFrame

local SetInfo = makeLabel(SettingsPanel, "Consigue tu API Key gratis en openrouter.ai", 10, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
SetInfo.Size     = UDim2.new(1, -24, 0, 16)
SetInfo.Position = UDim2.new(0, 12, 0, 136)
SetInfo.ZIndex   = 21

-- Estado IA
local AIStatusLbl = makeLabel(SettingsPanel, "Sin API Key configurada", 11, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)
AIStatusLbl.Size     = UDim2.new(1, -24, 0, 18)
AIStatusLbl.Position = UDim2.new(0, 12, 0, 162)
AIStatusLbl.ZIndex   = 21

-- Botones settings
local SaveBtn = makeBtn(SettingsPanel, "✓ Guardar", UDim2.new(0.44, 0, 0, 36), C.ACCENT, C.WHITE)
SaveBtn.Position = UDim2.new(0.04, 0, 0, 192)
SaveBtn.TextSize = 13
SaveBtn.ZIndex   = 21

local CancelBtn = makeBtn(SettingsPanel, "✕ Cancelar", UDim2.new(0.44, 0, 0, 36), Color3.fromRGB(35, 20, 22), C.RED)
CancelBtn.Position = UDim2.new(0.52, 0, 0, 192)
CancelBtn.TextSize = 13
CancelBtn.ZIndex   = 21

local ModelLbl = makeLabel(SettingsPanel, "Modelo: meta-llama/llama-3.3-70b-instruct:free", 9, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
ModelLbl.Size     = UDim2.new(1, -24, 0, 16)
ModelLbl.Position = UDim2.new(0, 12, 0, 238)
ModelLbl.ZIndex   = 21

-- Token tip
local TokenLbl = makeLabel(SettingsPanel, "💡 Usa la IA solo para búsquedas de palabras\npara ahorrar tokens de tu cuenta gratuita.", 10, C.ORANGE, Enum.Font.Gotham, Enum.TextXAlignment.Center)
TokenLbl.Size      = UDim2.new(1, -24, 0, 34)
TokenLbl.Position  = UDim2.new(0, 12, 0, 262)
TokenLbl.ZIndex    = 21
TokenLbl.TextWrapped = true

-- ============================================================
--               LÓGICA DE ESTADOS
-- ============================================================

local openRouterKey = ""
local currentTab    = "search"  -- "search" | "ai"
local aiHistory     = {}        -- mensajes del chat IA
local aiMsgOrder    = 0

local function setTab(tab)
    currentTab = tab
    if tab == "search" then
        ListContainer.Visible = true
        ResHeader.Visible     = true
        AIPanel.Visible       = false
        tw(TabSearch, { BackgroundColor3 = C.ACCENT }, 0.15)
        TabSearch.TextColor3 = C.WHITE
        tw(TabAI, { BackgroundColor3 = Color3.fromRGB(22, 25, 45) }, 0.15)
        TabAI.TextColor3 = C.TEXT_DIM
    else
        ListContainer.Visible = false
        ResHeader.Visible     = false
        AIPanel.Visible       = true
        tw(TabAI, { BackgroundColor3 = C.ACCENT2 }, 0.15)
        TabAI.TextColor3 = C.WHITE
        tw(TabSearch, { BackgroundColor3 = Color3.fromRGB(22, 25, 45) }, 0.15)
        TabSearch.TextColor3 = C.TEXT_DIM
    end
end

TabSearch.MouseButton1Click:Connect(function() setTab("search") end)
TabSearch.TouchTap:Connect(function() setTab("search") end)
TabAI.MouseButton1Click:Connect(function() setTab("ai") end)
TabAI.TouchTap:Connect(function() setTab("ai") end)

-- Settings panel
local function openSettings()
    APIKeyBox.Text  = openRouterKey
    SettingsPanel.Visible = true
    tw(SettingsPanel, { BackgroundTransparency = 0 }, 0.15)
end
local function closeSettings()
    SettingsPanel.Visible = false
end

SettingsBtn.MouseButton1Click:Connect(openSettings)
SettingsBtn.TouchTap:Connect(openSettings)
CancelBtn.MouseButton1Click:Connect(closeSettings)
CancelBtn.TouchTap:Connect(closeSettings)

SaveBtn.MouseButton1Click:Connect(function()
    local key = APIKeyBox.Text:match("^%s*(.-)%s*$") or ""
    openRouterKey = key
    if #key > 10 then
        AIStatusLbl.Text      = "✓ API Key guardada"
        AIStatusLbl.TextColor3 = C.GREEN
    else
        AIStatusLbl.Text      = "⚠ API Key vacía o inválida"
        AIStatusLbl.TextColor3 = C.ORANGE
    end
    task.delay(1.2, closeSettings)
end)
SaveBtn.TouchTap:Connect(function()
    local key = APIKeyBox.Text:match("^%s*(.-)%s*$") or ""
    openRouterKey = key
    if #key > 10 then
        AIStatusLbl.Text      = "✓ API Key guardada"
        AIStatusLbl.TextColor3 = C.GREEN
    else
        AIStatusLbl.Text      = "⚠ API Key vacía o inválida"
        AIStatusLbl.TextColor3 = C.ORANGE
    end
    task.delay(1.2, closeSettings)
end)

-- ============================================================
--                  CHAT IA — BURBUJA
-- ============================================================

local function addAIBubble(text, isUser)
    aiMsgOrder = aiMsgOrder + 1
    local bubble = Instance.new("Frame")
    bubble.Size            = UDim2.new(1, 0, 0, 10)
    bubble.BackgroundColor3 = isUser and C.AI_USER or C.AI_MSG
    bubble.BorderSizePixel = 0
    bubble.LayoutOrder     = aiMsgOrder
    bubble.AutomaticSize   = Enum.AutomaticSize.Y
    bubble.Parent          = AIScroll
    corner(bubble, 8)

    if isUser then
        stroke(bubble, Color3.fromRGB(60, 80, 140), 1)
    else
        stroke(bubble, Color3.fromRGB(40, 50, 100), 1)
    end

    local prefix = makeLabel(bubble, isUser and "Tú" or "🤖 IA", 9,
        isUser and C.ACCENT or C.ACCENT2, Enum.Font.GothamBold)
    prefix.Size     = UDim2.new(1, -12, 0, 16)
    prefix.Position = UDim2.new(0, 8, 0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size          = UDim2.new(1, -16, 0, 0)
    lbl.Position      = UDim2.new(0, 8, 0, 22)
    lbl.Text          = text
    lbl.TextSize      = 12
    lbl.Font          = Enum.Font.Gotham
    lbl.TextColor3    = C.TEXT
    lbl.TextWrapped   = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Parent        = bubble

    -- Actualiza canvas
    task.wait()
    local total = 0
    for _, child in ipairs(AIScroll:GetChildren()) do
        if child:IsA("Frame") then
            total = total + child.AbsoluteSize.Y + 6
        end
    end
    AIScroll.CanvasSize = UDim2.new(0, 0, 0, total + 12)
    AIScroll.CanvasPosition = Vector2.new(0, math.max(0, total - AIScroll.AbsoluteSize.Y + 12))

    return lbl
end

-- ============================================================
--            OPENROUTER API — LLAMADA OPTIMIZADA
-- ============================================================

-- Sistema prompt muy conciso para ahorrar tokens
local AI_SYSTEM = [[Eres un asistente de Conecta Palabras (juego Roblox). Solo buscas palabras en español e inglés que empiecen con el prefijo que te pida el usuario. Responde SOLO con la lista de palabras, separadas por coma, máximo 20 palabras. Sin explicaciones largas. Si no es una solicitud de palabras, responde en 1 frase corta.]]

local function callOpenRouter(userMsg, callback)
    if #openRouterKey < 10 then
        callback("⚠ Configura tu API Key en ⚙ primero.")
        return
    end

    -- Construye mensajes (solo los últimos 3 pares para ahorrar tokens)
    local msgs = {
        { role = "system", content = AI_SYSTEM }
    }
    local startIdx = math.max(1, #aiHistory - 5)
    for i = startIdx, #aiHistory do
        msgs[#msgs+1] = aiHistory[i]
    end
    msgs[#msgs+1] = { role = "user", content = userMsg }

    local body = jsonEncode({
        model      = "meta-llama/llama-3.3-70b-instruct:free",
        max_tokens = 300,
        messages   = msgs,
    })

    local headers = {
        ["Content-Type"]  = "application/json",
        ["Authorization"] = "Bearer " .. openRouterKey,
        ["HTTP-Referer"]  = "https://roblox.com",
        ["X-Title"]       = "ConectaPalabrasRoblox",
    }

    task.spawn(function()
        local ok, resp = httpPost(
            "https://openrouter.ai/api/v1/chat/completions",
            headers,
            body
        )
        if not ok or not resp then
            callback("❌ Error de conexión. Verifica tu API Key y red.")
            return
        end

        local content = jsonDecodeSimple(resp)
        if not content or #content < 1 then
            -- intenta extraer error
            local errMsg = resp:match('"message"%s*:%s*"([^"]+)"') or "Respuesta inválida"
            callback("❌ " .. errMsg)
            return
        end

        -- guarda en historial
        aiHistory[#aiHistory+1] = { role = "user",      content = userMsg }
        aiHistory[#aiHistory+1] = { role = "assistant", content = content }
        -- limita historial a 20 mensajes para ahorrar tokens
        if #aiHistory > 20 then
            local newH = {}
            for i = #aiHistory - 19, #aiHistory do
                newH[#newH+1] = aiHistory[i]
            end
            aiHistory = newH
        end

        callback(content)
    end)
end

-- Enviar mensaje IA
local aiLoading = false

local function sendAIMessage()
    if aiLoading then return end
    local msg = AIBox.Text:match("^%s*(.-)%s*$") or ""
    if #msg == 0 then return end

    AIBox.Text = ""
    addAIBubble(msg, true)

    -- Mensaje "pensando..."
    aiLoading = true
    AISendBtn.Text          = "⏳"
    AISendBtn.BackgroundColor3 = C.TEXT_MUTED

    local thinkBubble = addAIBubble("✦ Pensando...", false)

    callOpenRouter(msg, function(response)
        aiLoading = false
        AISendBtn.Text             = "➤"
        AISendBtn.BackgroundColor3 = C.ACCENT
        -- actualiza la burbuja de "pensando"
        if thinkBubble and thinkBubble.Parent then
            thinkBubble.Text = response
        end
    end)
end

AISendBtn.MouseButton1Click:Connect(sendAIMessage)
AISendBtn.TouchTap:Connect(sendAIMessage)
AIBox.FocusLost:Connect(function(enter)
    if enter then sendAIMessage() end
end)

-- ============================================================
--               POOL DE ITEMS (LISTA BÚSQUEDA)
-- ============================================================

local POOL_SIZE = CFG.LIST_VISIBLE + 3
local itemPool  = {}

local function createItem(idx)
    local row = Instance.new("Frame")
    row.Name             = "Row_" .. idx
    row.Size             = UDim2.new(1, 0, 0, CFG.ITEM_HEIGHT)
    row.BackgroundColor3 = (idx % 2 == 0) and C.CARD_ALT or C.CARD
    row.BorderSizePixel  = 0
    row.LayoutOrder      = idx
    row.Visible          = false
    row.Parent           = ScrollList
    corner(row, 6)

    local numLbl = makeLabel(row, tostring(idx), 9, C.TEXT_MUTED, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    numLbl.Name     = "Num"
    numLbl.Size     = UDim2.new(0, 24, 1, 0)
    numLbl.Position = UDim2.new(0, 0, 0, 0)

    local dot = Instance.new("Frame")
    dot.Name             = "Dot"
    dot.Size             = UDim2.new(0, 3, 0, 3)
    dot.Position         = UDim2.new(0, 27, 0.5, -1)
    dot.BackgroundColor3 = C.ACCENT
    dot.BorderSizePixel  = 0
    dot.Parent           = row
    corner(dot, 2)

    local wordLbl = makeLabel(row, "", 13, C.TEXT, Enum.Font.GothamBold)
    wordLbl.Name     = "Word"
    wordLbl.Size     = UDim2.new(1, -106, 1, 0)
    wordLbl.Position = UDim2.new(0, 34, 0, 0)

    local lenBadge = Instance.new("Frame")
    lenBadge.Name            = "LenBadge"
    lenBadge.Size            = UDim2.new(0, 32, 0, 18)
    lenBadge.Position        = UDim2.new(1, -84, 0.5, -9)
    lenBadge.BackgroundColor3 = Color3.fromRGB(22, 28, 50)
    lenBadge.BorderSizePixel = 0
    lenBadge.Parent          = row
    corner(lenBadge, 5)

    local lenLbl = makeLabel(lenBadge, "0L", 9, C.TEXT_DIM, Enum.Font.Gotham, Enum.TextXAlignment.Center)
    lenLbl.Name     = "Len"
    lenLbl.Size     = UDim2.new(1, 0, 1, 0)
    lenLbl.Position = UDim2.new(0, 0, 0, 0)

    local copyBtn = Instance.new("TextButton")
    copyBtn.Name             = "Copy"
    copyBtn.Size             = UDim2.new(0, 40, 0, 24)
    copyBtn.Position         = UDim2.new(1, -44, 0.5, -12)
    copyBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 75)
    copyBtn.BorderSizePixel  = 0
    copyBtn.Text             = "📋"
    copyBtn.TextSize         = 12
    copyBtn.AutoButtonColor  = false
    copyBtn.Parent           = row
    corner(copyBtn, 6)

    return row
end

for i = 1, POOL_SIZE do
    itemPool[i] = createItem(i)
end

-- ============================================================
--              RENDERIZADO DE LISTA
-- ============================================================

local copyConns = {}

local function renderList(words, total, prefix)
    PHFrame.Visible = (#words == 0)

    -- limpia conexiones previas del copy
    for _, conn in ipairs(copyConns) do
        pcall(function() conn:Disconnect() end)
    end
    copyConns = {}

    for i = 1, POOL_SIZE do
        local row  = itemPool[i]
        local word = words[i]
        if word then
            row.Visible          = true
            row.BackgroundColor3 = (i % 2 == 0) and C.CARD_ALT or C.CARD
            row.LayoutOrder      = i

            row:FindFirstChild("Num").Text  = tostring(i)
            row:FindFirstChild("Word").Text = word

            local lb = row:FindFirstChild("LenBadge")
            if lb then
                local ll = lb:FindFirstChild("Len")
                if ll then ll.Text = tostring(#word) .. "L" end
            end

            local copyBtn = row:FindFirstChild("Copy")
            if copyBtn then
                local function doCopy()
                    pcall(function()
                        if setclipboard then
                            setclipboard(word)
                        elseif syn and syn.set_clipboard then
                            syn.set_clipboard(word)
                        elseif Clipboard then
                            Clipboard:set(word)
                        end
                    end)
                    copyBtn.BackgroundColor3 = C.GREEN
                    copyBtn.Text             = "✓"
                    task.delay(0.9, function()
                        if copyBtn and copyBtn.Parent then
                            tw(copyBtn, { BackgroundColor3 = Color3.fromRGB(28, 38, 75) }, 0.3)
                            copyBtn.Text = "📋"
                        end
                    end)
                end
                local c1 = copyBtn.MouseButton1Click:Connect(doCopy)
                local c2 = copyBtn.TouchTap:Connect(doCopy)
                copyConns[#copyConns+1] = c1
                copyConns[#copyConns+1] = c2
            end
        else
            row.Visible = false
        end
    end

    -- Canvas
    local visible = math.min(#words, POOL_SIZE)
    ScrollList.CanvasSize    = UDim2.new(0, 0, 0, visible * (CFG.ITEM_HEIGHT + 2) + 8)
    ScrollList.CanvasPosition = Vector2.new(0, 0)

    -- Contador
    if #words == 0 then
        ResCountLbl.Text      = prefix ~= "" and "Sin resultados para \"" .. prefix .. "\"" or "Escribe para buscar"
        ResCountLbl.TextColor3 = #words == 0 and prefix ~= "" and C.RED or C.TEXT_MUTED
    elseif total > CFG.MAX_RESULTS then
        ResCountLbl.Text      = CFG.MAX_RESULTS .. "+ resultados  \"" .. prefix .. "\""
        ResCountLbl.TextColor3 = C.TEXT_DIM
    else
        ResCountLbl.Text      = total .. " resultado" .. (total ~= 1 and "s" or "") .. "  \"" .. prefix .. "\""
        ResCountLbl.TextColor3 = C.GREEN
    end
end

-- ============================================================
--              BÚSQUEDA EN TIEMPO REAL
-- ============================================================

local isReady    = false
local lastPrefix = ""
local debounce   = nil

local function doSearch(raw)
    local prefix = normalize(raw)
    if prefix == lastPrefix then return end
    lastPrefix = prefix

    if #prefix == 0 then
        renderList({}, 0, "")
        ResCountLbl.Text      = "Escribe para buscar palabras"
        ResCountLbl.TextColor3 = C.TEXT_MUTED
        PHFrame.Visible        = true
        return
    end

    if not isReady then
        ResCountLbl.Text      = "⏳ Cargando diccionario..."
        ResCountLbl.TextColor3 = C.TEXT_DIM
        return
    end

    PHFrame.Visible = false
    local words, total = trieSearch(prefix, CFG.MAX_RESULTS)
    renderList(words, total, prefix)
end

PrefixBox:GetPropertyChangedSignal("Text"):Connect(function()
    local txt = PrefixBox.Text
    if debounce then task.cancel(debounce) end
    debounce = task.delay(0.08, function()
        doSearch(txt)
    end)
end)

PrefixBox.FocusLost:Connect(function(enter)
    if enter then doSearch(PrefixBox.Text) end
end)

-- ============================================================
--           ANIMACIÓN DE ENTRADA
-- ============================================================

tw(Main, {
    Size     = UDim2.new(0, PANEL_W, 0, PANEL_H),
    Position = UDim2.new(0.5, -PANEL_W/2, 0.5, -PANEL_H/2)
}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Pulso dot
local dotAlive = true
task.spawn(function()
    while dotAlive and Main.Parent do
        if isReady then
            StatusDot.TextColor3 = C.GREEN
            task.wait(1)
        else
            tw(StatusDot, { TextColor3 = C.ACCENT  }, 0.5)
            task.wait(0.5)
            tw(StatusDot, { TextColor3 = C.TEXT_MUTED }, 0.5)
            task.wait(0.5)
        end
    end
end)

-- ============================================================
--           CARGA DE DICCIONARIOS EN BACKGROUND
-- ============================================================

task.spawn(function()
    -- 1. Seed
    StatusTxt.Text = "Base interna..."
    local s = loadSeed()
    CountTxt.Text  = totalLoaded .. " palabras"
    tw(ProgFill, { Size = UDim2.new(0.12, 0, 1, 0) }, 0.3)

    isReady        = true
    StatusTxt.Text = "✓ Base lista"
    StatusDot.TextColor3 = C.GREEN

    -- 2. URLs
    local steps = { 0.12, 0.58, 1.0 }
    for i, entry in ipairs(URLS) do
        StatusTxt.Text = "⬇ " .. entry.lang .. "..."
        StatusDot.TextColor3 = C.ACCENT
        local n = loadFromURL(entry)
        CountTxt.Text  = totalLoaded .. " palabras"
        tw(ProgFill, { Size = UDim2.new(steps[i+1] or 1, 0, 1, 0) }, 0.5)
        StatusTxt.Text       = "✓ " .. entry.lang .. " +" .. n
        StatusDot.TextColor3  = C.GREEN
        task.wait(0.3)
    end

    tw(ProgFill, { Size = UDim2.new(1, 0, 1, 0) }, 0.2)
    StatusTxt.Text = "✓ Diccionario completo"
    CountTxt.Text  = totalLoaded .. " palabras"

    -- Refresca búsqueda activa
    if #PrefixBox.Text > 0 then
        lastPrefix = ""
        doSearch(PrefixBox.Text)
    end

    -- Colapsa status bar tras 3s
    task.wait(3)
    tw(StatusBar,     { Size = UDim2.new(1, 0, 0, 0)  }, 0.3)
    tw(InputFrame,    { Position = UDim2.new(0, 0, 0, 4)   }, 0.3)
    tw(TabBar,        { Position = UDim2.new(0, 0, 0, 58)  }, 0.3)
    tw(ResHeader,     { Position = UDim2.new(0, 0, 0, 92)  }, 0.3)
    tw(ListContainer, { Position = UDim2.new(0, 0, 0, 120), Size = UDim2.new(1, 0, 0, LIST_H + 40) }, 0.3)
    tw(AIPanel,       { Position = UDim2.new(0, 0, 0, 92),  Size = UDim2.new(1, 0, 0, LIST_H + 64) }, 0.3)
    dotAlive = false
end)

-- IA bienvenida
task.delay(0.5, function()
    addAIBubble("¡Hola! Soy tu asistente de palabras 🤖\n\nPide palabras que empiecen con cualquier prefijo.\nEjemplo: 'dame palabras con ono' o 'palabras en inglés con spl'\n\nConfigura tu API Key en ⚙ para activarme.", false)
end)
