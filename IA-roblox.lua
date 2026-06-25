-- ╔══════════════════════════════════════════════════════════╗
-- ║     CONECTA PALABRAS v4.0 — Word Finder Pro + IA        ║
-- ║  Compact · Transparent · Resizable · Minimize · AI Fix  ║
-- ╚══════════════════════════════════════════════════════════╝

-- ============================================================
--  SERVICIOS
-- ============================================================
local Players    = game:GetService("Players")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

-- ============================================================
--  CONFIG
-- ============================================================
local CFG = {
    W            = 300,    -- ancho inicial (más chico)
    H            = 420,    -- alto inicial
    MIN_W        = 240,
    MIN_H        = 320,
    MAX_W        = 380,
    MAX_H        = 580,
    ITEM_H       = 30,
    LIST_ROWS    = 7,
    MAX_RES      = 120,
    ANIM         = 0.15,
    BG_TRANS     = 0.12,   -- transparencia del fondo (glassmorphism)
    PANEL_TRANS  = 0.18,
}

-- ============================================================
--  PALETA — GLASSMORPHISM
-- ============================================================
local C = {
    BG          = Color3.fromRGB(10,  12,  22),
    GLASS       = Color3.fromRGB(18,  22,  40),
    GLASS2      = Color3.fromRGB(24,  30,  52),
    CARD        = Color3.fromRGB(22,  28,  48),
    CARD2       = Color3.fromRGB(28,  35,  58),
    ACCENT      = Color3.fromRGB(90,  140, 255),
    ACCENT2     = Color3.fromRGB(130, 80,  255),
    ACCENT3     = Color3.fromRGB(60,  210, 255),
    GREEN       = Color3.fromRGB(60,  220, 140),
    RED         = Color3.fromRGB(255, 70,  85),
    ORANGE      = Color3.fromRGB(255, 165, 55),
    TEXT        = Color3.fromRGB(230, 232, 255),
    TEXTD       = Color3.fromRGB(140, 145, 180),
    TEXTM       = Color3.fromRGB(70,  75,  115),
    SCROLL      = Color3.fromRGB(90,  140, 255),
    WHITE       = Color3.fromRGB(255, 255, 255),
    BLACK       = Color3.fromRGB(0,   0,   0),
}

-- ============================================================
--  HTTP HELPER — multi-exploit (Delta/KRNL/Synapse/Fluxus)
-- ============================================================
local function httpRequest(opts)
    -- Delta / KRNL / Fluxus usan request()
    if type(request) == "function" then
        local ok, r = pcall(request, opts)
        if ok and r then return r end
    end
    -- Synapse
    if syn and type(syn.request) == "function" then
        local ok, r = pcall(syn.request, opts)
        if ok and r then return r end
    end
    -- http (algunos exploits)
    if http and type(http.request) == "function" then
        local ok, r = pcall(http.request, opts)
        if ok and r then return r end
    end
    -- HttpService fallback (Studio)
    local hs = game:GetService("HttpService")
    if opts.Method == "GET" then
        local ok, b = pcall(function() return hs:GetAsync(opts.Url, true) end)
        if ok and b then return { Body = b, StatusCode = 200 } end
    end
    return nil
end

local function httpGet(url)
    local r = httpRequest({ Url = url, Method = "GET" })
    if r and r.Body and #r.Body > 5 then return true, r.Body end
    return false, nil
end

local function httpPost(url, headers, body)
    local r = httpRequest({ Url = url, Method = "POST", Headers = headers, Body = body })
    if r and r.Body then return true, r.Body, r.StatusCode end
    return false, nil, nil
end

-- ============================================================
--  JSON MINIMAL (sin HttpService:JSONEncode para compatibilidad)
-- ============================================================
local function jsonEnc(v)
    local t = type(v)
    if t == "string" then
        v = v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
        return '"'..v..'"'
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "table" then
        if #v > 0 then
            local p={}; for _,x in ipairs(v) do p[#p+1]=jsonEnc(x) end
            return "["..table.concat(p,",").."]"
        else
            local p={}; for k,x in pairs(v) do p[#p+1]='"'..k..'":'..jsonEnc(x) end
            return "{"..table.concat(p,",").."}"
        end
    end
    return "null"
end

-- Extrae "content" de la respuesta OpenRouter
local function parseAIResponse(s)
    if not s then return nil end
    -- Busca el campo content dentro de choices[0].message
    local c = s:match('"content"%s*:%s*"(.-[^\\])"')
    if c then
        c = c:gsub('\\"','"'):gsub('\\n','\n'):gsub('\\\\','\\')
        return c
    end
    -- fallback más simple
    c = s:match('"content":"([^"]*)"')
    if c then return c end
    -- busca error
    local e = s:match('"message"%s*:%s*"([^"]*)"')
    if e then return "❌ "..e end
    return nil
end

-- ============================================================
--  NORMALIZACIÓN
-- ============================================================
local AMAP = {
    ["á"]="a",["à"]="a",["â"]="a",["ä"]="a",["ã"]="a",
    ["é"]="e",["è"]="e",["ê"]="e",["ë"]="e",
    ["í"]="i",["ì"]="i",["î"]="i",["ï"]="i",
    ["ó"]="o",["ò"]="o",["ô"]="o",["ö"]="o",["õ"]="o",
    ["ú"]="u",["ù"]="u",["û"]="u",["ü"]="u",
    ["ñ"]="n",["ç"]="c",["ý"]="y",
}
local function norm(w)
    if not w then return "" end
    w = tostring(w):lower():match("^%s*(.-)%s*$") or ""
    for a,b in pairs(AMAP) do w = w:gsub(a,b) end
    return w
end

-- ============================================================
--  TRIE
-- ============================================================
local function newNode() return {ch={},words={}} end
local ROOT = newNode()
local TOTAL = 0

local function insert(word)
    local n = ROOT
    for i=1,#word do
        local c=word:sub(i,i)
        if not n.ch[c] then n.ch[c]=newNode() end
        n=n.ch[c]
    end
    if not n.words[word] then
        n.words[word]=true
        TOTAL=TOTAL+1
    end
end

local function collect(n,res,lim)
    if #res>=lim then return end
    for w in pairs(n.words) do res[#res+1]=w; if #res>=lim then return end end
    for _,ch in pairs(n.ch) do if #res<lim then collect(ch,res,lim) end end
end

local function search(pre,lim)
    local n=ROOT
    for i=1,#pre do
        local c=pre:sub(i,i)
        if not n.ch[c] then return {},0 end
        n=n.ch[c]
    end
    local res={}
    collect(n,res,lim+300)
    table.sort(res)
    local tot=#res
    local shown={}
    for i=1,math.min(lim,tot) do shown[i]=res[i] end
    return shown,tot
end

-- ============================================================
--  DICCIONARIO SEED — 1000+ palabras ES+EN
-- ============================================================
local SEED = {
-- ── ESPAÑOL completo A ──
"abarcar","abeja","abertura","abismo","ablandar","abolir","abono","abordar",
"abrazo","abrir","absurdo","abuelo","abuela","abundar","acabar","academia",
"accion","aceite","acento","aceptar","acero","aclarar","acoger","acordar",
"acoso","acto","actor","actriz","acudir","acuerdo","acusar","adaptar",
"adelante","adentro","adivinar","admitir","adorar","adulto","afecto","aficion",
"agencia","agosto","agregar","agua","aguila","aguja","ahora","aire","ajeno",
"ajustar","alabar","aldea","alegre","alegria","alejar","alma","altar","alto",
"altura","amanecer","amar","amargo","ambiente","amigo","amiga","amor","amplio",
"ancho","angulo","animal","animo","antes","anuncio","apagar","apoyo","aprender",
"arbol","arena","arma","armada","armado","armadura","armamento","armar",
"armario","armas","aroma","arte","ayer","azul","azucar","abeja","abejas",
-- ── ESPAÑOL B ──
"bailar","baile","banco","barco","barrio","batalla","bello","bella","besar",
"blanco","boca","bonito","bosque","brazo","bueno","buscar","burbuja","bajar",
"barro","base","beber","bien","boca","brazo","brillar","bueno","burla",
-- ── ESPAÑOL C ──
"cabeza","camino","campo","cantar","casa","cielo","ciudad","conocer","corazon",
"correr","comer","comprar","coche","cocina","colores","corona","contra","contigo",
"construir","concepto","cosa","cuerpo","cuatro","cinco","cien","calor","calma",
"cambio","cancion","claro","clase","clima","cobrar","cocinar","color","comenzar",
"comunicar","confianza","confiar","conjunto","contacto","contar","corriente",
"crecer","crear","creer","critica","cultura","cumplir","curiosidad","caer",
"calle","canta","carta","cerca","cerveza","cierto","circulo","cobarde",
"cochino","comenzar","como","conejo","confiar","conocer","cortar","costa",
-- ── ESPAÑOL D ──
"danza","dato","dedo","dia","dinero","dormir","dulce","durante","donde",
"deber","decidir","defender","dejar","deseo","destino","diez","dominar",
"duda","dueno","dureza","dar","decir","dentro","descansar","diferente",
-- ── ESPAÑOL E ──
"edad","elegir","empezar","encontrar","energia","entre","entonces","escuela",
"escribir","escuchar","esperar","esta","estar","estrella","espejo","espacio",
"espada","espalda","especial","esperanza","estilo","esfuerzo","existir","exito",
"echar","ejemplo","empuje","encender","enfrentar","enojo","ensenar","entrar",
"enviar","equipo","error","escoger","esconder","espiritu","estudiar","evaluar",
-- ── ESPAÑOL F ──
"familia","feliz","final","flor","forma","fuerza","fuego","fruta","frente",
"famoso","fiel","fluir","fondo","futuro","fe","fallar","fama","faro",
"favor","fiesta","fila","fin","flauta","flecha","flojo","flujo",
-- ── ESPAÑOL G ──
"gato","grande","gracias","grupo","gente","guerra","gusto","globo","gris",
"ganar","genio","gloria","gritar","guiar","ganador","garra","golpe","gordo",
-- ── ESPAÑOL H ──
"hablar","hacer","hermano","hermana","hombre","hora","historia","hueso",
"hallar","herramienta","honor","horizonte","humano","humilde","haber","hambre",
"hecho","heroe","hierro","hijo","hija","hilo","hogar","honrar","humor",
-- ── ESPAÑOL I ──
"idea","idioma","igual","inicio","imagen","importante","isla","identidad",
"ilusion","impulso","interes","intuicion","ignorar","impacto","intentar",
"inventar","ir","izquierda",
-- ── ESPAÑOL J ──
"jardin","jefe","joven","juego","justo","junto","jornada","juicio","jalar",
"jamás","jerga","joya","jugar","juntar",
-- ── ESPAÑOL L ──
"largo","libro","lugar","luna","lengua","lento","libre","luchar","luz",
"latir","lazo","leal","lejos","llamar","llegar","lleno","lograr","lado",
"lanzar","lastima","lavar","leer","levantar","limpiar","listo","llevar",
-- ── ESPAÑOL M ──
"mano","mar","mundo","mujer","madre","malo","mapa","mesa","musica","mirar",
"mente","meta","miedo","mismo","modo","momento","motor","mover","mejora",
"mandar","manera","matar","mayor","menor","meter","mirar","morir","mostrar",
-- ── ESPAÑOL N ──
"noche","nombre","nuevo","nunca","nadie","natural","negro","nivel","norte",
"nacion","necesitar","noble","norma","nacer","nada","naranja","nino","nina",
-- ── ESPAÑOL O ──
"obra","oreja","oscuro","objeto","oeste","oso","osa","orden","origen",
"olvido","opinar","opcion","ocultar","odio","ofrecer","oir","ola","otro",
-- ── ESPAÑOL P ──
"padre","pais","palabra","papel","parque","perro","pequeno","poder","pez",
"primera","persona","puerta","plaza","planta","plata","playa","poca","poco",
"paciencia","pasion","paz","pensar","perder","pieza","planeta","presente",
"problema","proceso","promesa","propio","pulso","pagar","partir","pasado",
"pedir","pelear","peor","perder","piel","pisar","placer","pleno","practicar",
-- ── ESPAÑOL Q ──
"querer","quien","quiza","quieto","quedar","queja","quemar","quinto",
-- ── ESPAÑOL R ──
"rama","rapido","raton","reino","reto","rato","rio","rojo","raiz","razon",
"realidad","recuerdo","reflejo","regla","relacion","respeto","respuesta",
"riesgo","ritmo","rumbo","radar","rabia","reir","reparar","repetir","resistir",
-- ── ESPAÑOL S ──
"sala","saltar","sangre","saber","secreto","segundo","siempre","sobre","sol",
"sencillo","sentir","sera","ser","silencio","simple","sistema","solucion",
"sueno","surco","saber","sacar","seguir","serio","servir","siglo","sitio",
"sociedad","sonrisa","sortear","subir","suerte","suma",
-- ── ESPAÑOL SC (IMPORTANTE: palabras con sca/sco/scu/scr) ──
"scam","scar","scary","scatter","scene","score","scout","screen","screw",
-- ── ESPAÑOL T ──
"tarde","tener","tercer","tiempo","tierra","todo","trabajo","triste",
"talento","tarea","temor","teoria","terminar","tomar","total","tradicion",
"talla","tampoco","tan","tarde","texto","tipo","tocar","tono","torpe",
-- ── ESPAÑOL U ──
"ultimo","unir","uno","usar","unico","universo","union","urgente","utopia",
"ubicar","unidad",
-- ── ESPAÑOL V ──
"valor","vida","vez","viento","verde","volar","voz","viejo","vista",
"valiente","verdad","version","via","viaje","vision","voluntad","valer",
"vencer","venir","ver","vez","vivir","volver",
-- ── ESPAÑOL Z ──
"zapato","zona","zumo","zafiro","zorro","zanjar","zeal","zero",

-- ── INGLÉS A ──
"able","absorb","abstract","accept","access","action","active","adapt","add",
"adopt","advance","after","again","age","agree","ahead","aim","alert","align",
"alive","allow","almost","along","already","also","always","among","ancient",
"answer","appear","apple","apply","approach","area","argue","around","arrive",
"arrow","ask","assume","atom","attempt","attract","autumn","aware","awful",
"abandon","abuse","achieve","acquire","address","admit","affect","afford",
"agent","ahead","alarm","album","alcohol","alive","ally","alter","amazing",
"amount","angry","announce","apart","attack","avoid",
-- ── INGLÉS B ──
"back","balance","ball","bank","base","bear","beat","become","before","begin",
"believe","belong","beneath","beyond","bind","bird","black","blame","blend",
"block","bloom","blue","bond","book","born","both","brain","branch","brave",
"break","breathe","bridge","bright","bring","broad","build","burn","burst",
"bad","bag","band","banner","barely","battle","beauty","bed","big","bite",
"blade","blank","blaze","bleed","blind","blood","blow","blur","body","boss",
-- ── INGLÉS C ──
"call","calm","came","capture","card","carry","catch","cause","center","chain",
"chance","change","chase","check","child","choose","circle","city","claim",
"clear","climb","close","code","cold","collect","color","combine","come",
"commit","common","complete","connect","consider","control","cool","copy",
"core","count","country","cover","craft","crash","create","cross","cut",
"camp","can","care","chart","clean","cloud","club","coin","crew","crime",
"crowd","cry","cube","cure","current","curve","cycle",
-- ── INGLÉS D ──
"dark","dash","data","deal","decide","deep","define","describe","design",
"detail","develop","direct","discover","display","divide","door","down",
"dream","drive","drop","dynamic","daily","damage","dare","dead","dear",
"debt","decay","delay","dense","deny","depth","desire","despite","doubt",
"draft","draw","drift","drill","dry","due","dull","dust",
-- ── INGLÉS E ──
"each","edge","eight","empty","engage","enter","even","every","evolve","exact",
"expand","explore","express","extend","eye","earn","ease","eat","echo",
"effect","effort","either","elect","elite","else","emerge","emotion","enable",
"end","enemy","enforce","enjoy","enough","ensure","equal","escape","event",
-- ── INGLÉS F ──
"face","fact","fall","fast","field","fight","fill","find","fire","first",
"five","flag","flat","flow","focus","follow","food","force","form","four",
"free","fresh","from","full","future","fade","fail","fair","fake","fame",
"far","farm","fear","feel","few","fight","final","fine","flash","fleet",
"flesh","float","floor","fly","fold","fond","font","fool","foot","fork",
-- ── INGLÉS G ──
"game","gather","girl","give","glad","glass","good","grant","great","green",
"ground","group","grow","guide","gain","gap","gate","gaze","gear","glow",
"go","goal","gold","grab","grade","grand","gray","grip","guard","guess",
"gym",
-- ── INGLÉS H ──
"hand","happy","hard","head","heal","hear","heart","heavy","help","here",
"high","hold","home","hope","huge","human","hunt","habit","half","halt",
"harm","harsh","have","hide","hint","hit","hold","hole","honest","hot",
"hour","humble","hurry","hurt",
-- ── INGLÉS I ──
"idea","impact","improve","include","inner","into","iron","image","imagine",
"imply","input","insight","instead","intent","interest","invent","involve",
-- ── INGLÉS J-K ──
"join","just","keep","kind","king","know","jump","keen","lack","large",
-- ── INGLÉS L ──
"land","last","late","layer","lead","learn","left","level","life","light",
"link","lion","list","live","long","look","loop","lose","love","label",
"launch","lay","lean","limit","listen","local","lock","log","lone","loss",
-- ── INGLÉS M ──
"made","make","many","mark","meet","mind","miss","mode","moon","more",
"most","move","much","must","map","match","matter","mean","merge","metal",
"might","mix","model","moment","moral","motion","motor","mount","move",
-- ── INGLÉS N ──
"name","near","need","next","night","node","none","note","null","narrow",
"natural","network","next","nice","noble","noise","norm","north","notion",
-- ── INGLÉS O ──
"observe","only","open","orbit","order","other","over","object","offer",
"often","old","once","one","option","origin","output","own",
-- ── INGLÉS P ──
"page","part","past","path","pattern","peak","pick","place","plan","play",
"point","power","pull","push","pace","pain","pale","pass","pause","pay",
"peace","phase","pick","pile","pilot","pipe","pitch","pixel","plant","plus",
"port","pose","prime","print","probe","proof","pure","purpose",
-- ── INGLÉS Q-R ──
"quest","quick","quiet","quote","race","rain","reach","read","real","rely",
"rest","reveal","ride","ring","rise","road","rock","role","room","rule",
"rush","radar","rage","raise","rank","rapid","rate","raw","react","record",
"reduce","refer","reflect","refuse","region","relate","remain","remove",
"repeat","replace","report","resolve","result","return","reveal","reward",
-- ── INGLÉS S ──
"same","save","scan","scar","scary","scatter","scene","seek","seem","send",
"side","sign","sing","slow","snow","some","song","soon","soul","space",
"spark","split","start","stay","step","still","stop","store","story","stream",
"strong","such","surge","swim","safe","salt","scale","scope","score","scout",
"screen","screw","scrub","seal","search","shade","shape","share","sharp",
"shift","ship","shoot","short","shout","show","shut","sight","skill","skin",
"slip","slot","smart","smile","smoke","snap","soft","solid","sort","south",
"speed","spend","spin","spoke","spread","spring","stack","stage","stake",
"stand","state","status","stay","steel","stone","store","straight","stress",
"strike","string","strip","stroke","structure","style","sun","supply","swap",
"switch","symbol","system","scratch","script","scroll","score","scare",
-- ── INGLÉS T ──
"task","tell","test","than","then","time","told","track","trail","tree",
"true","trust","turn","type","table","take","talk","target","teach","team",
"tend","term","text","theme","think","threat","through","throw","tight",
"token","top","touch","tough","trade","transform","trend","trial","trick",
"trigger","truth","try","tube","tune",
-- ── INGLÉS U-V ──
"unity","used","vast","view","voice","value","vary","verify","version",
"via","void","volume","vote",
-- ── INGLÉS W ──
"wait","walk","warm","water","wave","well","wide","will","wind","wise",
"word","work","world","write","wake","warn","watch","weak","wealth","web",
"weight","west","what","where","which","white","whole","wild","win","wish",
"without","wonder","worth",
-- ── INGLÉS X-Z ──
"yield","zero","zone","zoom","xenon",
-- ── ONO/ARM especiales ──
"ono","onomatopeya","ona","once","online",
"arma","armada","armado","armadura","armamento","armar","armario","armas",
"armor","army","arm","arms","armed","arrange","arrest","arrive",
-- ── SCR / SCA / SCO (inglés) ──
"scratch","screen","scream","script","scroll","scrap","scrub","scar",
"scan","scam","scary","scatter","scene","scale","scope","score","scout",
"scare","scarce","scarf","scarlet","scatter",
}

-- ============================================================
--  CARGA
-- ============================================================
local isReady   = false
local loadedCnt = 0

local function loadSeed()
    local dedup = {}
    for _,w in ipairs(SEED) do
        local n = norm(w)
        if #n >= 2 and n:match("^[a-z]+$") and not dedup[n] then
            dedup[n] = true
            insert(n)
        end
    end
    loadedCnt = TOTAL
end

local URLS = {
    { lang="EN", url="https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt", fmt="txt" },
    { lang="ES", url="https://raw.githubusercontent.com/words/an-array-of-spanish-words/master/index.js", fmt="js" },
}

local function loadURL(e)
    local ok, body = httpGet(e.url)
    if not ok or not body then return 0 end
    local prev = TOTAL
    if e.fmt == "js" then
        for w in body:gmatch('"([^"]+)"') do
            local n=norm(w)
            if #n>=2 and #n<=28 and n:match("^[a-z]+$") then insert(n) end
        end
    else
        for line in body:gmatch("[^\r\n]+") do
            local n=norm(line:match("^%s*(.-)%s*$") or "")
            if #n>=2 and #n<=28 and n:match("^[a-z]+$") then insert(n) end
        end
    end
    loadedCnt = TOTAL
    return TOTAL - prev
end

-- ============================================================
--  HELPERS UI
-- ============================================================
local function R(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function G(p,c0,c1,rot) local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c0,c1); g.Rotation=rot or 90; g.Parent=p end
local function S(p,col,th) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function TW(obj,props,t,sty,dir)
    TweenSvc:Create(obj,TweenInfo.new(t or CFG.ANIM, sty or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),props):Play()
end
local function LBL(par,txt,sz,col,fnt,ax)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=txt; l.TextSize=sz or 13
    l.TextColor3=col or C.TEXT; l.Font=fnt or Enum.Font.Gotham
    l.TextXAlignment=ax or Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Center
    l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=par; return l
end
local function BTN(par,txt,sz,bg,tc)
    local b=Instance.new("TextButton"); b.Size=sz or UDim2.new(0,60,0,26)
    b.BackgroundColor3=bg or C.CARD; b.BorderSizePixel=0; b.Text=txt
    b.TextColor3=tc or C.TEXT; b.TextSize=12; b.Font=Enum.Font.GothamBold
    b.AutoButtonColor=false; b.Parent=par; R(b,7); return b
end

-- ============================================================
--  INICIALIZAR SCREENGUI
-- ============================================================
pcall(function()
    local cg = game:GetService("CoreGui")
    local old = cg:FindFirstChild("CW_GUI")
    if old then old:Destroy() end
end)
pcall(function()
    local pg = LP:WaitForChild("PlayerGui", 5)
    if pg then
        local old = pg:FindFirstChild("CW_GUI")
        if old then old:Destroy() end
    end
end)

local SG = Instance.new("ScreenGui")
SG.Name            = "CW_GUI"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
local _ok = pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not _ok or not SG.Parent then
    SG.Parent = LP:WaitForChild("PlayerGui")
end

-- ============================================================
--  VENTANA PRINCIPAL
-- ============================================================
local W0 = CFG.W
local H0 = CFG.H

local Main = Instance.new("Frame")
Main.Name              = "Main"
Main.Size              = UDim2.new(0, W0, 0, 0)
Main.Position          = UDim2.new(0.5, -W0/2, 0.5, 0)
Main.BackgroundColor3  = C.BG
Main.BackgroundTransparency = CFG.BG_TRANS
Main.BorderSizePixel   = 0
Main.Active            = true
Main.Draggable         = true
Main.ClipsDescendants  = true
Main.Parent            = SG
R(Main, 14)
S(Main, Color3.fromRGB(60, 70, 120), 1)

-- Gradiente de fondo glassmorphism
G(Main, Color3.fromRGB(14,18,34), Color3.fromRGB(8,10,22), 135)

-- ── BOLITA DE MINIMIZAR ────────────────────────────────────
local Bubble = Instance.new("TextButton")
Bubble.Name              = "Bubble"
Bubble.Size              = UDim2.new(0, 44, 0, 44)
Bubble.Position          = UDim2.new(0.5, -22, 0.5, -22)
Bubble.BackgroundColor3  = C.ACCENT
Bubble.BorderSizePixel   = 0
Bubble.Text              = "⬡"
Bubble.TextColor3        = C.WHITE
Bubble.TextSize          = 20
Bubble.Font              = Enum.Font.GothamBold
Bubble.AutoButtonColor   = false
Bubble.Visible           = false
Bubble.ZIndex            = 50
Bubble.Parent            = SG
R(Bubble, 22)
S(Bubble, C.ACCENT2, 2)
G(Bubble, C.ACCENT, C.ACCENT2, 45)

-- Posición libre de la bolita (draggable)
local bubbleDragging = false
local bubbleDragOffset = Vector2.new(0,0)
Bubble.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or
       inp.UserInputType == Enum.UserInputType.MouseButton1 then
        bubbleDragging = true
        bubbleDragOffset = Vector2.new(
            inp.Position.X - Bubble.AbsolutePosition.X,
            inp.Position.Y - Bubble.AbsolutePosition.Y
        )
    end
end)
Bubble.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or
       inp.UserInputType == Enum.UserInputType.MouseButton1 then
        bubbleDragging = false
    end
end)
UIS.InputChanged:Connect(function(inp)
    if bubbleDragging and (inp.UserInputType == Enum.UserInputType.Touch or
       inp.UserInputType == Enum.UserInputType.MouseButton1) then
        local vp = game.Workspace.CurrentCamera.ViewportSize
        local nx = math.clamp(inp.Position.X - bubbleDragOffset.X, 0, vp.X - 44)
        local ny = math.clamp(inp.Position.Y - bubbleDragOffset.Y, 0, vp.Y - 44)
        Bubble.Position = UDim2.new(0, nx, 0, ny)
    end
end)

-- ── HEADER ────────────────────────────────────────────────
local Header = Instance.new("Frame")
Header.Size              = UDim2.new(1, 0, 0, 46)
Header.BackgroundColor3  = C.GLASS
Header.BackgroundTransparency = 0.1
Header.BorderSizePixel   = 0
Header.Parent            = Main
R(Header, 14)
-- Fix corners bottom
local HFix = Instance.new("Frame")
HFix.Size             = UDim2.new(1,0,0,14)
HFix.Position         = UDim2.new(0,0,1,-14)
HFix.BackgroundColor3 = C.GLASS
HFix.BackgroundTransparency = 0.1
HFix.BorderSizePixel  = 0
HFix.ZIndex           = Header.ZIndex
HFix.Parent           = Header

-- Barra color top
local TopBar = Instance.new("Frame")
TopBar.Size            = UDim2.new(1,0,0,2)
TopBar.BackgroundColor3 = C.ACCENT
TopBar.BorderSizePixel = 0
TopBar.ZIndex          = 5
TopBar.Parent          = Main
R(TopBar,2)
G(TopBar, C.ACCENT3, C.ACCENT2, 0)

local TitleIcon = LBL(Header,"⬡",18,C.ACCENT,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
TitleIcon.Size=UDim2.new(0,34,1,0); TitleIcon.Position=UDim2.new(0,6,0,0); TitleIcon.ZIndex=4

local TitleTxt = LBL(Header,"CONECTA PALABRAS",13,C.TEXT,Enum.Font.GothamBold)
TitleTxt.Size=UDim2.new(1,-130,0,20); TitleTxt.Position=UDim2.new(0,42,0,6); TitleTxt.ZIndex=4
local SubTxt = LBL(Header,"Word Finder + IA v4",9,C.TEXTD,Enum.Font.Gotham)
SubTxt.Size=UDim2.new(1,-130,0,14); SubTxt.Position=UDim2.new(0,42,0,26); SubTxt.ZIndex=4

-- Botón ⚙
local BtnGear = BTN(Header,"⚙",UDim2.new(0,28,0,28),Color3.fromRGB(22,28,50),C.TEXTD)
BtnGear.Position=UDim2.new(1,-63,0.5,-14); BtnGear.TextSize=15; BtnGear.ZIndex=4

-- Botón minimizar (— dash)
local BtnMin = BTN(Header,"—",UDim2.new(0,28,0,28),Color3.fromRGB(22,40,65),C.ACCENT)
BtnMin.Position=UDim2.new(1,-32,0.5,-14); BtnMin.TextSize=14; BtnMin.ZIndex=4

-- ── BODY ──────────────────────────────────────────────────
local Body = Instance.new("Frame")
Body.Size=UDim2.new(1,-14,1,-52)
Body.Position=UDim2.new(0,7,0,48)
Body.BackgroundTransparency=1
Body.Parent=Main

-- ── STATUS BAR ────────────────────────────────────────────
local StatusBar = Instance.new("Frame")
StatusBar.Size=UDim2.new(1,0,0,26)
StatusBar.Position=UDim2.new(0,0,0,0)
StatusBar.BackgroundColor3=C.GLASS2
StatusBar.BackgroundTransparency=0.2
StatusBar.BorderSizePixel=0
StatusBar.Parent=Body
R(StatusBar,7)

local SDot = LBL(StatusBar,"●",10,C.ACCENT,Enum.Font.Gotham,Enum.TextXAlignment.Center)
SDot.Size=UDim2.new(0,20,1,0); SDot.Position=UDim2.new(0,2,0,0)
local STxt = LBL(StatusBar,"Iniciando...",9,C.TEXTD,Enum.Font.Gotham)
STxt.Size=UDim2.new(1,-100,1,0); STxt.Position=UDim2.new(0,22,0,0)
local SCnt = LBL(StatusBar,"0 palabras",9,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Right)
SCnt.Size=UDim2.new(0,80,1,0); SCnt.Position=UDim2.new(1,-82,0,0)

local PrgTrack = Instance.new("Frame")
PrgTrack.Size=UDim2.new(1,0,0,2); PrgTrack.Position=UDim2.new(0,0,1,-2)
PrgTrack.BackgroundColor3=Color3.fromRGB(28,32,55); PrgTrack.BorderSizePixel=0; PrgTrack.Parent=StatusBar; R(PrgTrack,2)
local PrgFill = Instance.new("Frame")
PrgFill.Size=UDim2.new(0,0,1,0); PrgFill.BackgroundColor3=C.ACCENT; PrgFill.BorderSizePixel=0; PrgFill.Parent=PrgTrack; R(PrgFill,2)
G(PrgFill, C.ACCENT3, C.ACCENT2, 0)

-- ── INPUT ─────────────────────────────────────────────────
local InputF = Instance.new("Frame")
InputF.Size=UDim2.new(1,0,0,40)
InputF.Position=UDim2.new(0,0,0,30)
InputF.BackgroundColor3=C.GLASS2
InputF.BackgroundTransparency=0.1
InputF.BorderSizePixel=0
InputF.Parent=Body
R(InputF,10)
S(InputF,Color3.fromRGB(50,58,100),1)

local IIcon = LBL(InputF,"🔍",14,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
IIcon.Size=UDim2.new(0,32,1,0); IIcon.Position=UDim2.new(0,0,0,0)

local PBox = Instance.new("TextBox")
PBox.Size=UDim2.new(1,-72,1,-8); PBox.Position=UDim2.new(0,32,0,4)
PBox.BackgroundTransparency=1; PBox.PlaceholderText="sca, ono, arma, con..."
PBox.PlaceholderColor3=C.TEXTM; PBox.Text=""
PBox.TextColor3=C.TEXT; PBox.TextSize=15; PBox.Font=Enum.Font.GothamBold
PBox.ClearTextOnFocus=false; PBox.TextXAlignment=Enum.TextXAlignment.Left
PBox.Parent=InputF

local BtnClear = BTN(InputF,"✕",UDim2.new(0,32,0,26),Color3.fromRGB(40,22,26),C.TEXTD)
BtnClear.Position=UDim2.new(1,-36,0.5,-13); BtnClear.TextSize=11
BtnClear.MouseButton1Click:Connect(function() PBox.Text="" pcall(function() PBox:CaptureFocus() end) end)
BtnClear.TouchTap:Connect(function() PBox.Text="" end)

PBox.Focused:Connect(function() TW(InputF,{BackgroundColor3=C.CARD},0.12) S(InputF,C.ACCENT,1.5) end)
PBox.FocusLost:Connect(function() TW(InputF,{BackgroundColor3=C.GLASS2},0.12) S(InputF,Color3.fromRGB(50,58,100),1) end)

-- ── TABS ──────────────────────────────────────────────────
local TabsF = Instance.new("Frame")
TabsF.Size=UDim2.new(1,0,0,26); TabsF.Position=UDim2.new(0,0,0,74)
TabsF.BackgroundColor3=C.GLASS2; TabsF.BackgroundTransparency=0.3; TabsF.BorderSizePixel=0; TabsF.Parent=Body
R(TabsF,7)

local TBsearch = BTN(TabsF,"🔍 Buscar",UDim2.new(0.5,-2,1,-4),C.ACCENT,C.WHITE)
TBsearch.Position=UDim2.new(0,2,0,2); TBsearch.TextSize=11; R(TBsearch,5)
local TBai = BTN(TabsF,"🤖 IA",UDim2.new(0.5,-2,1,-4),Color3.fromRGB(22,25,46),C.TEXTD)
TBai.Position=UDim2.new(0.5,0,0,2); TBai.TextSize=11; R(TBai,5)

-- ── CONTADOR ──────────────────────────────────────────────
local ResF = Instance.new("Frame")
ResF.Size=UDim2.new(1,0,0,20); ResF.Position=UDim2.new(0,0,0,104)
ResF.BackgroundTransparency=1; ResF.Parent=Body
local ResLbl = LBL(ResF,"Escribe un prefijo para buscar",9,C.TEXTM,Enum.Font.Gotham)
ResLbl.Size=UDim2.new(1,-60,1,0); ResLbl.Position=UDim2.new(0,2,0,0)
local LangBg = Instance.new("Frame"); LangBg.Size=UDim2.new(0,56,0,16)
LangBg.Position=UDim2.new(1,-58,0.5,-8); LangBg.BackgroundColor3=C.GLASS2; LangBg.BorderSizePixel=0; LangBg.Parent=ResF; R(LangBg,8)
local LangL = LBL(LangBg,"ES+EN",9,C.ACCENT,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
LangL.Size=UDim2.new(1,0,1,0)

-- ── LISTA ─────────────────────────────────────────────────
local LIST_H = CFG.ITEM_H * CFG.LIST_ROWS

local ListF = Instance.new("Frame")
ListF.Size=UDim2.new(1,0,0,LIST_H)
ListF.Position=UDim2.new(0,0,0,127)
ListF.BackgroundColor3=C.GLASS
ListF.BackgroundTransparency=0.15
ListF.BorderSizePixel=0; ListF.ClipsDescendants=true; ListF.Parent=Body
R(ListF,9); S(ListF,Color3.fromRGB(35,42,80),1)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size=UDim2.new(1,-8,1,0); Scroll.BackgroundTransparency=1
Scroll.BorderSizePixel=0; Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=C.SCROLL
Scroll.CanvasSize=UDim2.new(0,0,0,0); Scroll.ScrollingDirection=Enum.ScrollingDirection.Y
Scroll.Parent=ListF
local LL = Instance.new("UIListLayout"); LL.SortOrder=Enum.SortOrder.LayoutOrder; LL.Padding=UDim.new(0,1); LL.Parent=Scroll
local LP2 = Instance.new("UIPadding"); LP2.PaddingTop=UDim.new(0,2); LP2.PaddingLeft=UDim.new(0,3); LP2.PaddingRight=UDim.new(0,2); LP2.Parent=Scroll

-- Placeholder
local PHF = Instance.new("Frame"); PHF.Size=UDim2.new(1,0,1,0); PHF.BackgroundTransparency=1; PHF.ZIndex=3; PHF.Parent=ListF
local PHI = LBL(PHF,"⬡",28,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center); PHI.Size=UDim2.new(1,0,0,36); PHI.Position=UDim2.new(0,0,0.2,0); PHI.ZIndex=3
local PHT = LBL(PHF,"Escribe para buscar",11,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center); PHT.Size=UDim2.new(1,0,0,18); PHT.Position=UDim2.new(0,0,0.2,40); PHT.ZIndex=3
local PHS = LBL(PHF,"sca · ono · arm · con · esp...",9,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center); PHS.Size=UDim2.new(1,0,0,14); PHS.Position=UDim2.new(0,0,0.2,60); PHS.ZIndex=3

-- ── HANDLE RESIZE (línea para arrastrar y cambiar tamaño) ──
local HandleF = Instance.new("Frame")
HandleF.Size=UDim2.new(1,0,0,14)
HandleF.Position=UDim2.new(0,0,1,-14)
HandleF.BackgroundColor3=C.GLASS2
HandleF.BackgroundTransparency=0.3
HandleF.BorderSizePixel=0
HandleF.Active=true
HandleF.ZIndex=10
HandleF.Parent=Main
R(HandleF,7)

-- Línea visual centrada
local HandleLine = Instance.new("Frame")
HandleLine.Size=UDim2.new(0,40,0,3); HandleLine.Position=UDim2.new(0.5,-20,0.5,-1)
HandleLine.BackgroundColor3=C.ACCENT; HandleLine.BackgroundTransparency=0.4; HandleLine.BorderSizePixel=0
HandleLine.ZIndex=11; HandleLine.Parent=HandleF; R(HandleLine,2)

-- ── PANEL IA ──────────────────────────────────────────────
local AIF = Instance.new("Frame")
AIF.Size=UDim2.new(1,0,0,LIST_H)
AIF.Position=UDim2.new(0,0,0,127)
AIF.BackgroundColor3=Color3.fromRGB(10,16,32)
AIF.BackgroundTransparency=0.1
AIF.BorderSizePixel=0; AIF.ClipsDescendants=true; AIF.Visible=false; AIF.Parent=Body
R(AIF,9); S(AIF,Color3.fromRGB(40,50,100),1)

local AIScroll = Instance.new("ScrollingFrame")
AIScroll.Size=UDim2.new(1,0,1,-42); AIScroll.BackgroundTransparency=1
AIScroll.BorderSizePixel=0; AIScroll.ScrollBarThickness=3; AIScroll.ScrollBarImageColor3=C.SCROLL
AIScroll.CanvasSize=UDim2.new(0,0,0,0); AIScroll.Parent=AIF
local AIL = Instance.new("UIListLayout"); AIL.SortOrder=Enum.SortOrder.LayoutOrder; AIL.Padding=UDim.new(0,5); AIL.Parent=AIScroll
local AIP2 = Instance.new("UIPadding"); AIP2.PaddingTop=UDim.new(0,5); AIP2.PaddingLeft=UDim.new(0,5); AIP2.PaddingRight=UDim.new(0,5); AIP2.Parent=AIScroll

local AIBar = Instance.new("Frame")
AIBar.Size=UDim2.new(1,0,0,40); AIBar.Position=UDim2.new(0,0,1,-40)
AIBar.BackgroundColor3=C.GLASS2; AIBar.BackgroundTransparency=0.1; AIBar.BorderSizePixel=0; AIBar.Parent=AIF
R(AIBar,8)

local AIBox = Instance.new("TextBox")
AIBox.Size=UDim2.new(1,-52,1,-8); AIBox.Position=UDim2.new(0,5,0,4)
AIBox.BackgroundTransparency=1; AIBox.PlaceholderText="Pide palabras con 'sca', 'ono'..."
AIBox.PlaceholderColor3=C.TEXTM; AIBox.Text=""; AIBox.TextColor3=C.TEXT
AIBox.TextSize=12; AIBox.Font=Enum.Font.Gotham; AIBox.ClearTextOnFocus=false
AIBox.TextXAlignment=Enum.TextXAlignment.Left; AIBox.Parent=AIBar

local AISend = BTN(AIBar,"➤",UDim2.new(0,40,0,30),C.ACCENT,C.WHITE)
AISend.Position=UDim2.new(1,-44,0.5,-15); AISend.TextSize=13

-- ── PANEL SETTINGS ────────────────────────────────────────
local SetF = Instance.new("Frame")
SetF.Size=UDim2.new(1,0,1,0); SetF.BackgroundColor3=Color3.fromRGB(8,12,24)
SetF.BackgroundTransparency=0.05; SetF.BorderSizePixel=0; SetF.Visible=false; SetF.ZIndex=20; SetF.Parent=Main
R(SetF,14)
S(SetF,Color3.fromRGB(60,70,130),1)

local SetTitle = LBL(SetF,"⚙  Configuración IA",14,C.TEXT,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
SetTitle.Size=UDim2.new(1,0,0,38); SetTitle.Position=UDim2.new(0,0,0,8); SetTitle.ZIndex=21

local SetDesc = LBL(SetF,"API Key de OpenRouter:",10,C.TEXTD,Enum.Font.Gotham)
SetDesc.Size=UDim2.new(1,-20,0,16); SetDesc.Position=UDim2.new(0,10,0,54); SetDesc.ZIndex=21

local KeyF = Instance.new("Frame")
KeyF.Size=UDim2.new(1,-20,0,38); KeyF.Position=UDim2.new(0,10,0,72)
KeyF.BackgroundColor3=C.GLASS2; KeyF.BorderSizePixel=0; KeyF.ZIndex=21; KeyF.Parent=SetF
R(KeyF,9); S(KeyF,Color3.fromRGB(50,60,110),1)

local KeyBox = Instance.new("TextBox")
KeyBox.Size=UDim2.new(1,-10,1,-8); KeyBox.Position=UDim2.new(0,5,0,4)
KeyBox.BackgroundTransparency=1; KeyBox.PlaceholderText="sk-or-v1-xxxxxxxx..."
KeyBox.PlaceholderColor3=C.TEXTM; KeyBox.Text=""; KeyBox.TextColor3=C.TEXT
KeyBox.TextSize=11; KeyBox.Font=Enum.Font.Gotham; KeyBox.ClearTextOnFocus=false
KeyBox.TextXAlignment=Enum.TextXAlignment.Left; KeyBox.ZIndex=22; KeyBox.Parent=KeyF

local SetInfo = LBL(SetF,"Gratis en openrouter.ai → API Keys",9,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
SetInfo.Size=UDim2.new(1,-20,0,14); SetInfo.Position=UDim2.new(0,10,0,114); SetInfo.ZIndex=21

local SetStatus = LBL(SetF,"Sin API Key",10,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
SetStatus.Size=UDim2.new(1,-20,0,16); SetStatus.Position=UDim2.new(0,10,0,130); SetStatus.ZIndex=21

local BtnSave = BTN(SetF,"✓ Guardar",UDim2.new(0.45,0,0,32),C.ACCENT,C.WHITE)
BtnSave.Position=UDim2.new(0.04,0,0,150); BtnSave.TextSize=12; BtnSave.ZIndex=21
local BtnCancel = BTN(SetF,"✕ Cancelar",UDim2.new(0.45,0,0,32),Color3.fromRGB(36,18,20),C.RED)
BtnCancel.Position=UDim2.new(0.52,0,0,150); BtnCancel.TextSize=12; BtnCancel.ZIndex=21

local ModelLbl = LBL(SetF,"Modelo: meta-llama/llama-3.3-70b-instruct:free",8,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
ModelLbl.Size=UDim2.new(1,-20,0,14); ModelLbl.Position=UDim2.new(0,10,0,188); ModelLbl.ZIndex=21

local TokenTip = LBL(SetF,"💡 La IA usa pocos tokens: solo pide palabras con prefijo.\nMáx. 20 palabras por respuesta.",9,C.ORANGE,Enum.Font.Gotham,Enum.TextXAlignment.Center)
TokenTip.Size=UDim2.new(1,-20,0,32); TokenTip.Position=UDim2.new(0,10,0,208); TokenTip.TextWrapped=true; TokenTip.ZIndex=21

-- ============================================================
--  ESTADO GLOBAL
-- ============================================================
local apiKey     = ""
local currentTab = "search"
local aiOrder    = 0
local aiHistory  = {}
local minimized  = false

-- ============================================================
--  MINIMIZE / RESTORE
-- ============================================================
local function doMinimize()
    minimized = true
    TW(Main, { Size=UDim2.new(0,W0,0,0), BackgroundTransparency=1 }, 0.2)
    task.delay(0.22, function()
        Main.Visible = false
        -- Coloca la bolita cerca de la esquina
        local vp = game.Workspace.CurrentCamera.ViewportSize
        Bubble.Position = UDim2.new(0, vp.X - 56, 0, 80)
        TW(Bubble, { Size=UDim2.new(0,0,0,0), Position=UDim2.new(0,vp.X-22,0,102) }, 0)
        Bubble.Visible = true
        TW(Bubble, { Size=UDim2.new(0,44,0,44), Position=UDim2.new(0,vp.X-56,0,80) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

local function doRestore()
    minimized = false
    Bubble.Visible = false
    Main.Visible   = true
    Main.BackgroundTransparency = CFG.BG_TRANS
    Main.Size = UDim2.new(0,W0,0,0)
    TW(Main, { Size=UDim2.new(0,W0,0,H0) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

BtnMin.MouseButton1Click:Connect(doMinimize)
BtnMin.TouchTap:Connect(doMinimize)
Bubble.MouseButton1Click:Connect(doRestore)
Bubble.TouchTap:Connect(doRestore)

-- ============================================================
--  RESIZE (handle inferior arrastrable)
-- ============================================================
local resizing       = false
local resizeStartY   = 0
local resizeStartH   = H0
local resizeStartW   = W0

HandleF.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or
       inp.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing     = true
        resizeStartY = inp.Position.Y
        resizeStartH = Main.AbsoluteSize.Y
        resizeStartW = Main.AbsoluteSize.X
    end
end)
HandleF.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch or
       inp.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = false
        -- guarda nuevas dimensiones
        H0 = Main.AbsoluteSize.Y
        W0 = Main.AbsoluteSize.X
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not resizing then return end
    if inp.UserInputType ~= Enum.UserInputType.Touch and
       inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local dy = inp.Position.Y - resizeStartY
    local newH = math.clamp(resizeStartH + dy, CFG.MIN_H, CFG.MAX_H)
    -- ajusta lista y AIPanel dinámicamente
    local bodyH = newH - 52
    local listH = bodyH - 127 - 14  -- menos header body menos handle
    listH = math.max(listH, CFG.ITEM_H * 3)
    Main.Size = UDim2.new(0, resizeStartW, 0, newH)
    ListF.Size = UDim2.new(1,0,0,listH)
    AIF.Size   = UDim2.new(1,0,0,listH)
    HandleF.Position = UDim2.new(0,0,1,-14)
end)

-- ============================================================
--  TABS
-- ============================================================
local function setTab(t)
    currentTab = t
    if t == "search" then
        ListF.Visible=true; ResF.Visible=true; AIF.Visible=false
        TW(TBsearch,{BackgroundColor3=C.ACCENT},0.12); TBsearch.TextColor3=C.WHITE
        TW(TBai,{BackgroundColor3=Color3.fromRGB(22,25,46)},0.12); TBai.TextColor3=C.TEXTD
    else
        ListF.Visible=false; ResF.Visible=false; AIF.Visible=true
        TW(TBai,{BackgroundColor3=C.ACCENT2},0.12); TBai.TextColor3=C.WHITE
        TW(TBsearch,{BackgroundColor3=Color3.fromRGB(22,25,46)},0.12); TBsearch.TextColor3=C.TEXTD
    end
end
TBsearch.MouseButton1Click:Connect(function() setTab("search") end)
TBsearch.TouchTap:Connect(function() setTab("search") end)
TBai.MouseButton1Click:Connect(function() setTab("ai") end)
TBai.TouchTap:Connect(function() setTab("ai") end)

-- ============================================================
--  SETTINGS
-- ============================================================
BtnGear.MouseButton1Click:Connect(function() KeyBox.Text=apiKey; SetF.Visible=true end)
BtnGear.TouchTap:Connect(function() KeyBox.Text=apiKey; SetF.Visible=true end)
local function closeSet() SetF.Visible=false end
BtnCancel.MouseButton1Click:Connect(closeSet); BtnCancel.TouchTap:Connect(closeSet)
BtnSave.MouseButton1Click:Connect(function()
    apiKey = KeyBox.Text:match("^%s*(.-)%s*$") or ""
    if #apiKey > 10 then
        SetStatus.Text="✓ API Key guardada"; SetStatus.TextColor3=C.GREEN
    else
        SetStatus.Text="⚠ Key vacía o inválida"; SetStatus.TextColor3=C.ORANGE
    end
    task.delay(1.2,closeSet)
end)
BtnSave.TouchTap:Connect(function()
    apiKey = KeyBox.Text:match("^%s*(.-)%s*$") or ""
    if #apiKey > 10 then
        SetStatus.Text="✓ API Key guardada"; SetStatus.TextColor3=C.GREEN
    else
        SetStatus.Text="⚠ Key vacía o inválida"; SetStatus.TextColor3=C.ORANGE
    end
    task.delay(1.2,closeSet)
end)

-- ============================================================
--  CHAT IA — BURBUJA
-- ============================================================
local function addBubble(text, isUser)
    aiOrder = aiOrder + 1
    local bub = Instance.new("Frame")
    bub.Size=UDim2.new(1,0,0,10)
    bub.BackgroundColor3 = isUser and Color3.fromRGB(22,42,75) or Color3.fromRGB(16,26,52)
    bub.BorderSizePixel=0; bub.LayoutOrder=aiOrder; bub.AutomaticSize=Enum.AutomaticSize.Y
    bub.Parent=AIScroll
    R(bub,7)
    S(bub, isUser and Color3.fromRGB(60,90,160) or Color3.fromRGB(40,55,110), 1)

    local who = LBL(bub, isUser and "Tú" or "🤖 IA", 8,
        isUser and C.ACCENT or C.ACCENT2, Enum.Font.GothamBold)
    who.Size=UDim2.new(1,-10,0,14); who.Position=UDim2.new(0,6,0,3)

    local msg = Instance.new("TextLabel")
    msg.BackgroundTransparency=1; msg.Size=UDim2.new(1,-12,0,0); msg.Position=UDim2.new(0,6,0,18)
    msg.Text=text; msg.TextSize=11; msg.Font=Enum.Font.Gotham; msg.TextColor3=C.TEXT
    msg.TextWrapped=true; msg.TextXAlignment=Enum.TextXAlignment.Left
    msg.TextYAlignment=Enum.TextYAlignment.Top; msg.AutomaticSize=Enum.AutomaticSize.Y
    msg.Parent=bub

    task.wait()
    local total=0
    for _,ch in ipairs(AIScroll:GetChildren()) do
        if ch:IsA("Frame") then total=total+ch.AbsoluteSize.Y+6 end
    end
    AIScroll.CanvasSize=UDim2.new(0,0,0,total+12)
    AIScroll.CanvasPosition=Vector2.new(0,math.max(0,total-AIScroll.AbsoluteSize.Y+12))
    return msg
end

-- ============================================================
--  OPENROUTER IA — LLAMADA REAL
-- ============================================================
-- Sistema prompt compacto (ahorra tokens)
local SYS = "Eres asistente del juego Conecta Palabras (Roblox). "..
    "Cuando el usuario pida palabras con un prefijo, responde SOLO con una lista "..
    "de máximo 15 palabras en español e inglés que comiencen con ese prefijo, "..
    "separadas por comas, sin explicaciones. "..
    "Si no es una petición de palabras, responde en UNA oración corta."

local aiLoading = false

local function callAI(userMsg, callback)
    if #apiKey < 8 then
        callback("⚠️ Configura tu API Key en ⚙ primero.\n\nVe a openrouter.ai → crea cuenta gratis → API Keys → copia tu key y pégala aquí.")
        return
    end

    -- Construye historial (solo últimos 4 pares para ahorrar tokens)
    local msgs = {{ role="system", content=SYS }}
    local start = math.max(1, #aiHistory-7)
    for i=start,#aiHistory do msgs[#msgs+1]=aiHistory[i] end
    msgs[#msgs+1] = { role="user", content=userMsg }

    local payload = jsonEnc({
        model      = "meta-llama/llama-3.3-70b-instruct:free",
        max_tokens = 256,
        temperature = 0.3,
        messages   = msgs,
    })

    local hdrs = {
        ["Content-Type"]  = "application/json",
        ["Authorization"] = "Bearer "..apiKey,
        ["HTTP-Referer"]  = "https://www.roblox.com",
        ["X-Title"]       = "ConectaPalabrasRoblox",
    }

    task.spawn(function()
        local ok, body, code = httpPost(
            "https://openrouter.ai/api/v1/chat/completions",
            hdrs, payload
        )

        if not ok or not body then
            callback("❌ Sin conexión. Verifica que el exploit tiene acceso HTTP.\n(Delta: activa 'Allow HTTP' si lo pide)")
            return
        end

        -- Intenta parsear
        local content = parseAIResponse(body)
        if not content or content == "" then
            -- muestra cuerpo crudo para debug
            local snippet = body:sub(1,120)
            callback("❌ Respuesta inesperada:\n"..snippet)
            return
        end

        -- Guarda en historial
        aiHistory[#aiHistory+1] = { role="user",      content=userMsg }
        aiHistory[#aiHistory+1] = { role="assistant", content=content }
        if #aiHistory > 16 then
            local nh={}
            for i=#aiHistory-15,#aiHistory do nh[#nh+1]=aiHistory[i] end
            aiHistory=nh
        end

        callback(content)
    end)
end

local function sendAI()
    if aiLoading then return end
    local msg = AIBox.Text:match("^%s*(.-)%s*$") or ""
    if #msg == 0 then return end
    AIBox.Text=""
    addBubble(msg, true)
    aiLoading=true
    AISend.Text="⏳"; TW(AISend,{BackgroundColor3=C.TEXTM},0.1)
    local think = addBubble("✦ Pensando...", false)
    callAI(msg, function(resp)
        aiLoading=false
        AISend.Text="➤"; TW(AISend,{BackgroundColor3=C.ACCENT},0.1)
        if think and think.Parent then think.Text=resp end
    end)
end
AISend.MouseButton1Click:Connect(sendAI); AISend.TouchTap:Connect(sendAI)
AIBox.FocusLost:Connect(function(e) if e then sendAI() end end)

-- ============================================================
--  POOL DE ITEMS
-- ============================================================
local POOL = CFG.LIST_ROWS + 3
local pool  = {}

local function makeItem(i)
    local row = Instance.new("Frame")
    row.Name=("R%d"):format(i); row.Size=UDim2.new(1,0,0,CFG.ITEM_H)
    row.BackgroundColor3=(i%2==0) and C.CARD2 or C.CARD
    row.BackgroundTransparency=0.1; row.BorderSizePixel=0; row.LayoutOrder=i; row.Visible=false; row.Parent=Scroll
    R(row,5)

    local num=LBL(row,tostring(i),8,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    num.Name="N"; num.Size=UDim2.new(0,20,1,0); num.Position=UDim2.new(0,0,0,0)

    local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,3,0,3)
    dot.Position=UDim2.new(0,22,0.5,-1); dot.BackgroundColor3=C.ACCENT; dot.BorderSizePixel=0; dot.Parent=row; R(dot,2)

    local wlbl=LBL(row,"",13,C.TEXT,Enum.Font.GothamBold)
    wlbl.Name="W"; wlbl.Size=UDim2.new(1,-80,1,0); wlbl.Position=UDim2.new(0,28,0,0)

    local lb=Instance.new("Frame"); lb.Name="LB"; lb.Size=UDim2.new(0,26,0,16)
    lb.Position=UDim2.new(1,-60,0.5,-8); lb.BackgroundColor3=Color3.fromRGB(20,26,48)
    lb.BorderSizePixel=0; lb.Parent=row; R(lb,5)
    local ll=LBL(lb,"",8,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    ll.Name="LL"; ll.Size=UDim2.new(1,0,1,0)

    local cp=Instance.new("TextButton"); cp.Name="CP"
    cp.Size=UDim2.new(0,32,0,20); cp.Position=UDim2.new(1,-35,0.5,-10)
    cp.BackgroundColor3=Color3.fromRGB(25,35,70); cp.BorderSizePixel=0
    cp.Text="📋"; cp.TextSize=10; cp.AutoButtonColor=false; cp.Parent=row; R(cp,5)
    return row
end
for i=1,POOL do pool[i]=makeItem(i) end

-- ============================================================
--  RENDER LISTA
-- ============================================================
local copyConns={}

local function renderList(words, total, pre)
    PHF.Visible=(#words==0)
    for _,c in ipairs(copyConns) do pcall(function() c:Disconnect() end) end
    copyConns={}

    for i=1,POOL do
        local row=pool[i]; local w=words[i]
        if w then
            row.Visible=true; row.LayoutOrder=i
            row.BackgroundColor3=(i%2==0) and C.CARD2 or C.CARD
            row:FindFirstChild("N").Text=tostring(i)
            row:FindFirstChild("W").Text=w
            local lb=row:FindFirstChild("LB"); if lb then local ll=lb:FindFirstChild("LL"); if ll then ll.Text=tostring(#w).."L" end end
            local cp=row:FindFirstChild("CP")
            if cp then
                local function doCopy()
                    pcall(function()
                        if setclipboard then setclipboard(w)
                        elseif syn and syn.set_clipboard then syn.set_clipboard(w)
                        elseif Clipboard then Clipboard:set(w) end
                    end)
                    cp.BackgroundColor3=C.GREEN; cp.Text="✓"
                    task.delay(0.9,function() if cp and cp.Parent then TW(cp,{BackgroundColor3=Color3.fromRGB(25,35,70)},0.3); cp.Text="📋" end end)
                end
                copyConns[#copyConns+1]=cp.MouseButton1Click:Connect(doCopy)
                copyConns[#copyConns+1]=cp.TouchTap:Connect(doCopy)
            end
        else
            row.Visible=false
        end
    end

    local vis=math.min(#words,POOL)
    Scroll.CanvasSize=UDim2.new(0,0,0,vis*(CFG.ITEM_H+1)+6)
    Scroll.CanvasPosition=Vector2.new(0,0)

    if #words==0 then
        ResLbl.Text=pre~="" and "Sin resultados para \""..pre.."\"" or "Escribe para buscar"
        ResLbl.TextColor3=pre~="" and C.RED or C.TEXTM
    elseif total>CFG.MAX_RES then
        ResLbl.Text=CFG.MAX_RES.."+  para \""..pre.."\""; ResLbl.TextColor3=C.TEXTD
    else
        ResLbl.Text=total.." resultado"..(total~=1 and "s" or "").."  \""..pre.."\""; ResLbl.TextColor3=C.GREEN
    end
end

-- ============================================================
--  BÚSQUEDA TIEMPO REAL
-- ============================================================
local lastPre=""
local deb=nil

local function doSearch(raw)
    local pre=norm(raw)
    if pre==lastPre then return end; lastPre=pre
    if #pre==0 then
        renderList({},0,""); ResLbl.Text="Escribe un prefijo para buscar"; ResLbl.TextColor3=C.TEXTM; PHF.Visible=true; return
    end
    if not isReady then ResLbl.Text="⏳ Cargando..."; ResLbl.TextColor3=C.TEXTD; return end
    PHF.Visible=false
    local words,total=search(pre,CFG.MAX_RES)
    renderList(words,total,pre)
end

PBox:GetPropertyChangedSignal("Text"):Connect(function()
    local t=PBox.Text
    if deb then task.cancel(deb) end
    deb=task.delay(0.07,function() doSearch(t) end)
end)
PBox.FocusLost:Connect(function(e) if e then doSearch(PBox.Text) end end)

-- ============================================================
--  ANIMACIÓN ENTRADA
-- ============================================================
TW(Main,{Size=UDim2.new(0,W0,0,H0),Position=UDim2.new(0.5,-W0/2,0.5,-H0/2)},
    0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

-- Pulso dot
local dotOn=true
task.spawn(function()
    while dotOn and Main.Parent do
        if isReady then SDot.TextColor3=C.GREEN; task.wait(1)
        else
            TW(SDot,{TextColor3=C.ACCENT},0.5); task.wait(0.5)
            TW(SDot,{TextColor3=C.TEXTM},0.5);  task.wait(0.5)
        end
    end
end)

-- ============================================================
--  CARGA DICCIONARIOS (BACKGROUND)
-- ============================================================
task.spawn(function()
    STxt.Text="Base interna..."
    loadSeed()
    SCnt.Text=TOTAL.." palabras"
    TW(PrgFill,{Size=UDim2.new(0.1,0,1,0)},0.3)
    isReady=true; SDot.TextColor3=C.GREEN; STxt.Text="✓ Base lista"

    local steps={0.1,0.55,1.0}
    for i,entry in ipairs(URLS) do
        STxt.Text="⬇ "..entry.lang.."..."
        SDot.TextColor3=C.ACCENT
        local n=loadURL(entry)
        SCnt.Text=TOTAL.." palabras"
        TW(PrgFill,{Size=UDim2.new(steps[i+1] or 1,0,1,0)},0.5)
        STxt.Text="✓ "..entry.lang.." +"..n; SDot.TextColor3=C.GREEN; task.wait(0.2)
    end
    TW(PrgFill,{Size=UDim2.new(1,0,1,0)},0.2)
    STxt.Text="✓ Diccionario completo"; SCnt.Text=TOTAL.." palabras"

    if #PBox.Text>0 then lastPre=""; doSearch(PBox.Text) end

    task.wait(3)
    dotOn=false
    -- Colapsa barra de status con animación
    TW(StatusBar,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},0.3)
    task.wait(0.3)
    StatusBar.Visible=false
    -- Sube los elementos
    TW(InputF,{Position=UDim2.new(0,0,0,2)},0.3)
    TW(TabsF,{Position=UDim2.new(0,0,0,46)},0.3)
    TW(ResF,{Position=UDim2.new(0,0,0,76)},0.3)
    TW(ListF,{Position=UDim2.new(0,0,0,99)},0.3)
    TW(AIF,{Position=UDim2.new(0,0,0,99)},0.3)
end)

-- ============================================================
--  MENSAJE BIENVENIDA IA
-- ============================================================
task.delay(0.6,function()
    addBubble("¡Hola! 🤖 Soy tu asistente.\n\nEjemplos de lo que puedes pedirme:\n• 'palabras que empiecen con sca'\n• 'dame palabras en inglés con scr'\n• 'palabras en español con ono'\n\nConfigura tu API Key en ⚙ para activarme.\nopenrouter.ai → cuenta gratis → API Keys", false)
end)

-- FIN SCRIPT
