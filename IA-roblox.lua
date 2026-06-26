-- ============================================================
--  SERVICIOS
-- ============================================================
local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("ReplicatedStorage")
local LP       = Players.LocalPlayer

-- ============================================================
--  PALETA — Glassmorphism oscuro violeta/azul
-- ============================================================
local C = {
    -- Fondos con transparencia
    BG       = Color3.fromRGB(6, 7, 16),
    GLASS    = Color3.fromRGB(16, 19, 38),
    GLASS2   = Color3.fromRGB(22, 27, 52),
    GLASS3   = Color3.fromRGB(28, 34, 64),
    -- Accentos
    A1       = Color3.fromRGB(100, 150, 255),  -- azul eléctrico
    A2       = Color3.fromRGB(140,  80, 255),  -- violeta
    A3       = Color3.fromRGB( 60, 210, 255),  -- cyan
    -- Estados
    GREEN    = Color3.fromRGB( 56, 220, 130),
    RED      = Color3.fromRGB(255,  65,  80),
    ORANGE   = Color3.fromRGB(255, 160,  50),
    YELLOW   = Color3.fromRGB(255, 220,  60),
    -- Texto
    TEXT     = Color3.fromRGB(230, 233, 255),
    TEXTD    = Color3.fromRGB(140, 148, 190),
    TEXTM    = Color3.fromRGB( 62,  68, 112),
    -- Misc
    BLACK    = Color3.fromRGB(0, 0, 0),
    BORDER   = Color3.fromRGB(55, 65, 125),
    SCROLL   = Color3.fromRGB(100, 150, 255),
}

-- Transparencias
local T = {
    BG     = 0.10,
    PANEL  = 0.14,
    CARD   = 0.08,
    CARD2  = 0.04,
    HANDLE = 0.35,
}

-- ============================================================
--  HELPERS UI
-- ============================================================
local function rnd(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
end
local function str(p, col, th)
    local s = Instance.new("UIStroke"); s.Color = col; s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end
local function grad(p, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1); g.Rotation = rot or 0; g.Parent = p
end
local function tw(o, pr, t, s, d)
    TweenSvc:Create(o, TweenInfo.new(t or 0.15, s or Enum.EasingStyle.Quad,
        d or Enum.EasingDirection.Out), pr):Play()
end
local function lbl(p, txt, sz, col, fnt, ax)
    local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1
    l.Text = txt; l.TextSize = sz or 12; l.TextColor3 = col or C.TEXT
    l.Font = fnt or Enum.Font.Gotham
    l.TextXAlignment = ax or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = p; return l
end
local function btn(p, txt, sz, bg, tc, fs)
    local b = Instance.new("TextButton"); b.Size = sz
    b.BackgroundColor3 = bg or C.GLASS2; b.BorderSizePixel = 0
    b.Text = txt; b.TextColor3 = tc or C.TEXT; b.TextSize = fs or 11
    b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false; b.Parent = p; rnd(b, 7)
    return b
end
-- Frame genérico glassmorphism
local function gf(p, sz, pos, bg, trans, cr)
    local f = Instance.new("Frame"); f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = bg or C.GLASS; f.BackgroundTransparency = trans or T.PANEL
    f.BorderSizePixel = 0; f.Parent = p; rnd(f, cr or 10); return f
end

-- ============================================================
--  NORMALIZACIÓN
-- ============================================================
local AM = {["á"]="a",["à"]="a",["â"]="a",["ä"]="a",["ã"]="a",
    ["é"]="e",["è"]="e",["ê"]="e",["ë"]="e",["í"]="i",["ì"]="i",
    ["î"]="i",["ï"]="i",["ó"]="o",["ò"]="o",["ô"]="o",["ö"]="o",
    ["õ"]="o",["ú"]="u",["ù"]="u",["û"]="u",["ü"]="u",
    ["ñ"]="n",["ç"]="c",["ý"]="y"}
local function norm(w)
    if not w then return "" end
    w = tostring(w):lower():match("^%s*(.-)%s*$") or ""
    for a,b in pairs(AM) do w = w:gsub(a,b) end
    return w
end

-- ============================================================
--  DICCIONARIO DE PRUEBA — palabras candidatas para probar
--  (el script las manda al servidor y guarda las que acepta)
-- ============================================================
local CANDIDATES = {
-- A
"abad","abeja","abismo","abrazo","abrir","abuelo","abuela","accion","aceite",
"acento","acero","acordar","acto","acudir","adaptar","adelante","adorar","afecto",
"agua","aguila","ahora","aire","alegre","alegria","alma","alto","altura","amar",
"amigo","amiga","amor","animal","antes","apoyo","aprender","arbol","arena","arma",
"armada","armado","armadura","armar","armario","armas","aroma","arte","ayer","azul",
"alacrán","aldea","alfil","alforja","alga","alhaja","alianza","alivio","almeja",
"alondra","alpaca","amapola","amargo","ambar","ambiente","amplio","ancho","angulo",
"animo","anuncio","apagar","arena","arco","ardor","ardilla","arpa","arroyo","asco",
-- AX AXI AXO
"axila","axioma","axon",
-- B
"bailar","baile","banco","barco","barrio","batalla","bello","bella","besar","blanco",
"boca","bonito","bosque","brazo","bueno","buscar","burbuja","brillo","brisa","bronce",
"bruja","bruto","bufalo","bufanda","buho","burro","busqueda",
-- C
"cabeza","camino","campo","cantar","casa","cielo","ciudad","corazon","correr",
"comer","comprar","cocina","corona","contra","construir","cuerpo","calor","calma",
"cambio","cancion","claro","clase","clima","comenzar","conejo","confianza","contar",
"crecer","crear","creer","cultura","cumplir","curiosidad","caballo","cadena",
"caiman","calamar","caldera","camello","canela","capullo","cascada","castillo",
"catedral","caudal","cayado","cazador","cedro","centavo","cereza","certeza",
"cesped","chaleco","champiñon","charca","charco","chimenea","chispa","chivo",
"chorizo","ciervo","cifra","cima","cincel","cipres","ciruelo","ciudad","clavel",
"clavo","cobija","cocotero","codorniz","cofre","cogote","cohete","colina","colmena",
"columna","cometa","concha","condor","conejo","consejo","copa","copete","corcho",
"cordero","correa","corsario","cosecha","covarde","coyote","crisol","crisantemo",
-- CH
"chalupa","charla","chico","chica","chocolate","chiste","choza",
-- D
"danza","dato","dedo","dia","dinero","dormir","dulce","deber","decidir","defender",
"dejar","deseo","destino","diez","dominar","duda","dar","decir","dentro","diferente",
"delfin","delicia","demonio","desierto","diamante","diablo","dichoso","diluvio",
"dinasta","dique","disco","disfraz","distancia","doblar","docena","dragon","drama",
-- E
"edad","elegir","empezar","encontrar","energia","escuela","escribir","escuchar",
"esperar","estar","estrella","espejo","espacio","especial","esperanza","esfuerzo",
"existir","exito","elefante","embudo","empuje","encender","enfrentar","enojo",
"ensenar","enviar","equipo","erizo","ermita","escama","escarcha","escorpion",
"esmeralda","espiga","espina","estanque","estuario","etapa","evasion",
-- F
"familia","feliz","final","flor","forma","fuerza","fuego","fruta","frente",
"fe","fallar","fama","faro","favor","fiesta","fin","flauta","flecha","flujo","frio",
"fabula","falcon","fantasma","faraon","faro","fastidia","fatiga","fauces","faz",
"felino","felpudo","fermento","festin","fianza","fibra","fiera","filo","filosofia",
"finura","fiordo","firma","fisura","flamingo","flecha","flota","fluido","follaje",
"forja","fosa","frasco","fregona","fresno","fronda","fuerza","fulgur","fulgor",
-- G
"gato","grande","gracias","grupo","gente","guerra","gusto","globo","gris","ganar",
"genio","gloria","gritar","guiar","ganador","garra","golpe","gordo","grifo","gramo",
"gabela","galera","gallina","galpon","gamba","ganso","garfio","garza","gavilan",
"gavota","gema","gemido","geranio","gibbon","glaciar","gladio","goblin","goce",
"golem","golondrina","gorila","gorrion","gozne","grajo","granada","granero","grapa",
"grillo","grua","grumo","guante","guardabosque","guirnalda","guisante","gusano",
-- H
"hablar","hacer","hermano","hermana","hombre","hora","historia","honor","horizonte",
"humano","haber","hambre","heroe","hierro","hijo","hija","hogar","humor","humo",
"hacha","halcon","hamaca","haya","hazana","hebra","hechizo","helecho","heraldo",
"herbario","hiena","higuera","hinojo","hipocampo","hojarasca","hollin","hongo",
"hormiga","huella","huerfano","hueso","huevo","huida","huracan",
-- I
"idea","idioma","igual","inicio","imagen","isla","ilusion","impulso","interes",
"invierno","iglesia","impar","incendio","indigo","indio","inferno","ingrediente",
"insecto","instrumento","invierno","iris","ironia",
-- J
"jardin","jefe","joven","juego","justo","junto","joya","jabali","jabón","jaula",
"jilguero","jinete","jirafa","joroba","juncia","junco","juntura",
-- L
"largo","libro","lugar","luna","lengua","lento","libre","luchar","luz","latir",
"lazo","leal","lejos","llamar","llegar","lleno","lograr","lluvia","lobo","lodo",
"labio","lagarto","laguna","lamento","lamprea","lancha","langosta","lapiz","lastre",
"laurel","lavanda","lazo","lechuza","legumbre","lejia","lenteja","leon","leopardo",
"liebre","limon","lince","lino","lirio","lisura","litoral","lombriz","loro","losa",
-- LL
"llave","llama","llanto","llano","llanura","lloro",
-- M
"mano","mar","mundo","mujer","madre","malo","mapa","mesa","musica","mirar",
"mente","meta","miedo","mismo","modo","momento","motor","mover","magia","masa",
"miel","monte","mudo","madera","madeja","madriguera","maiz","malecon","maleza",
"manga","manjar","manta","mantel","manzana","marfil","marisco","marmol","maroma",
"marrana","mastil","materia","maullido","mazorca","medallion","mejillon","melena",
"melon","membrillo","menique","mercado","merengue","mezcal","miel","mimbre","mina",
"mirlo","moho","molino","molusco","monje","monton","moral","morera","morsa","mosca",
"mosquito","motera","motivo","muelle","muerdago","muesca","muleton","muralla","murmullo",
-- N
"noche","nombre","nuevo","nunca","nadie","natural","negro","nivel","norte","nacer",
"nada","naranja","nino","nina","nieve","niebla","nudo","nuez","nacar","narval",
"nectarina","nenufar","nervio","nido","niquel","nogal","nomada","noria",
-- O
"obra","oreja","oscuro","objeto","oeste","oso","orden","origen","olvido","opinar",
"opcion","odio","ofrecer","ola","otro","oceano","oficio","ojo","olivo","ombligo",
"onza","orilla","otono","oveja","oboe","ocelote","ocre","odre","ojiva","olmo",
"ombligo","orca","oregano","oropendola","ortiga","osezno","ostra","otero","otono",
-- OPO
"oponer","oponente","oportuno","oposicion","opresion","opresor",
-- P
"padre","pais","palabra","papel","parque","perro","pequeno","poder","pez","persona",
"puerta","plaza","planta","plata","playa","poco","paciencia","paz","pensar","perder",
"pieza","planeta","proceso","promesa","propio","pecho","pelo","pena","pino","piso",
"pajaro","paloma","palmera","panal","pantano","papagayo","papiro","parana","paramo",
"parra","pastor","patria","patron","pavo","pedernal","peldano","pelicano","pepino",
"perdiz","petalo","petrel","pez","picaflor","pichon","pielago","piloto","pincel",
"pingüino","piraña","pirata","pluma","polilla","polvora","pomelo","porrón","potro",
"praderas","presa","primavera","proa","puerco","pulpo","puma","pupila",
-- Q
"querer","quien","quiza","quieto","quedar","queja","quemar","quinto","queso",
"quebrada","quelonio","quemada","queso","quilate","quimera","quinteto",
-- R
"rama","rapido","raton","reino","reto","rio","rojo","raiz","razon","realidad",
"recuerdo","reflejo","regla","relacion","respeto","respuesta","riesgo","ritmo",
"rumbo","rabia","roble","roca","rocio","rodar","ropa","rosa","rubio","rueda","ruido",
"rana","rapaz","rastrojo","raya","rayo","rebanada","rebano","recluta","redoma",
"redrojo","rejalgar","reliquia","remolacha","renacuajo","reptil","resina","retama",
"retono","ribera","riel","rinoceronte","risco","rizo","rodaballo","roedora","romero",
"ronquera","roseta","ruana","rueca","rugido","ruin","rumia","rutina",
-- S
"sala","saltar","sangre","saber","secreto","segundo","siempre","sobre","sol","sencillo",
"sentir","ser","silencio","simple","sistema","sueno","surco","sacar","seguir","suerte",
"sabio","salud","selva","senal","silla","soplo","suelo","sumar","saeta","salamandra",
"salmón","salvia","sandalo","sapillo","sardina","sauce","sauco","savana","sedal",
"sedimento","semilla","sendero","serpiente","sicomoro","sierra","silice","siluro",
"sirena","sisal","sobra","solsticio","sombra","soneto","sorda","sorbo","surcador",
-- T
"tarde","tener","tiempo","tierra","todo","trabajo","triste","talento","tarea","temor",
"teoria","terminar","tomar","total","tradicion","texto","tipo","tocar","tono","torpe",
"techo","tela","tigre","tronco","tropa","tumba","talon","tallo","tamarindo","tapia",
"tapir","taquilla","tarpon","tasajo","tecla","tejedor","tejido","tejon","tempestad",
"tenaza","tendal","terral","tiberon","timon","tizne","toba","tobillo","tormenta",
"tornillo","torrente","tortuga","tostada","trebejo","trebol","trepador","tribu",
"tributo","trigal","trino","trocha","trueno","trufa","tuberculo","tucan","tulipan",
-- U
"ultimo","unir","uno","usar","unico","universo","union","ubicar","unidad",
"umbral","uncial","ungüento","urraca","utopia","uvero",
-- V
"valor","vida","vez","viento","verde","volar","voz","viejo","vista","valiente",
"verdad","version","via","viaje","vision","voluntad","valer","vencer","venir",
"vivir","volver","vacio","vapor","vara","vela","vena","ventana","verano","verguenza",
"vibora","volcan","vuelo","vaivén","valija","vaquero","vasija","vastago","vate",
"vedado","velamen","venado","verdor","vergel","vertice","vestigio","vientre",
"vigilia","vilano","virote","viscacha","visera","vitela","viuda","vorago",
-- X
"xilofono","xenofobia","xerografia",
-- Y
"yema","yerno","yeso","yoga","yugo","yuca","yute","yacimiento","yacare",
-- Z
"zapato","zona","zumo","zafiro","zorro","zanjar","zarpa","zurdo","zarzal","zorzal",
"zanahoria","zancudo","zapoteca","zarpazo","zopilote","zoologia",
-- Palabras raras/cortas que el juego suele aceptar
"ax","xi","ox","ex",
-- Números romanos / siglas que acepta
"xiii","xix","xxi","xxx",
}

-- ============================================================
--  ESTADO GLOBAL
-- ============================================================
local validSet   = {}   -- word(norm) -> true  (aceptadas por servidor)
local rejSet     = {}   -- word(norm) -> true  (rechazadas)
local usedRound  = {}   -- word(norm) -> true  (jugadas esta ronda)
local validArr   = {}   -- lista ordenada de válidas
local currentPre = ""   -- prefijo actual
local probeRemote = nil -- RemoteFunction/Event de validación
local probeMode  = "none" -- "function"|"event"|"none"
local probeActive = false
local probeCount  = 0
local probeTotal  = 0
local interceptCount = 0

local function addValid(w)
    local n = norm(w); if #n < 2 then return end
    if not validSet[n] then
        validSet[n] = true; rejSet[n] = nil
        validArr[#validArr+1] = n
        table.sort(validArr)
    end
end
local function addRej(w)
    local n = norm(w); if #n < 2 then return end
    if not validSet[n] then rejSet[n] = true end
end
local function markUsed(w)
    local n = norm(w); if #n < 2 then return end
    usedRound[n] = true; addValid(n)
end
local function searchValid(pre)
    local res = {}
    for _,w in ipairs(validArr) do
        if w:sub(1,#pre)==pre and not usedRound[w] then res[#res+1]=w end
    end
    return res
end

-- ============================================================
--  LIMPIAR GUI PREVIA
-- ============================================================
pcall(function() game:GetService("CoreGui"):FindFirstChild("CW_GUI"):Destroy() end)
pcall(function()
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then local old=pg:FindFirstChild("CW_GUI"); if old then old:Destroy() end end
end)

local SG = Instance.new("ScreenGui")
SG.Name="CW_GUI"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset=true
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

-- ============================================================
--  VENTANA PRINCIPAL  270 × 410
-- ============================================================
local W0, H0 = 270, 410

local Main = Instance.new("Frame")
Main.Name="Main"
Main.Size=UDim2.new(0,W0,0,0)
Main.Position=UDim2.new(0.5,-W0/2,0.5,0)
Main.BackgroundColor3=C.BG
Main.BackgroundTransparency=T.BG
Main.BorderSizePixel=0; Main.Active=true; Main.Draggable=true; Main.ClipsDescendants=true
Main.Parent=SG; rnd(Main,14); str(Main,C.BORDER,1)

-- Blur decorativo (gradiente diagonal)
local BGrad=Instance.new("UIGradient")
BGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(14,16,34)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 9, 20)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(12,10,28)),
})
BGrad.Rotation=135; BGrad.Parent=Main

-- Top accent line (gradiente A1→A2→A3)
local TopLine=Instance.new("Frame"); TopLine.Size=UDim2.new(1,0,0,2)
TopLine.BackgroundColor3=C.A1; TopLine.BorderSizePixel=0; TopLine.ZIndex=5; TopLine.Parent=Main; rnd(TopLine,2)
grad(TopLine,C.A3,C.A2,0)

-- ── BURBUJA MINIMIZAR ──────────────────────────────────────
local Bub=Instance.new("TextButton")
Bub.Size=UDim2.new(0,0,0,0)
Bub.BackgroundColor3=C.A1; Bub.BorderSizePixel=0
Bub.Text="⬡"; Bub.TextColor3=C.TEXT; Bub.TextSize=20; Bub.Font=Enum.Font.GothamBold
Bub.AutoButtonColor=false; Bub.Visible=false; Bub.ZIndex=60; Bub.Parent=SG; rnd(Bub,22)
str(Bub,C.A2,2); grad(Bub,C.A1,C.A2,45)

local bDrag=false; local bOff=Vector2.new()
Bub.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        bDrag=true; bOff=Vector2.new(i.Position.X-Bub.AbsolutePosition.X,i.Position.Y-Bub.AbsolutePosition.Y)
    end
end)
Bub.InputEnded:Connect(function() bDrag=false end)
UIS.InputChanged:Connect(function(i)
    if not bDrag then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    local vp=game.Workspace.CurrentCamera.ViewportSize
    Bub.Position=UDim2.new(0,math.clamp(i.Position.X-bOff.X,0,vp.X-44),0,math.clamp(i.Position.Y-bOff.Y,0,vp.Y-44))
end)

local minimized=false
local function doMin()
    minimized=true; tw(Main,{Size=UDim2.new(0,W0,0,0)},0.18)
    task.delay(0.2,function()
        Main.Visible=false
        local vp=game.Workspace.CurrentCamera.ViewportSize
        Bub.Size=UDim2.new(0,0,0,0); Bub.Position=UDim2.new(0,vp.X-50,0,88); Bub.Visible=true
        tw(Bub,{Size=UDim2.new(0,44,0,44)},0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    end)
end
local function doRes()
    minimized=false; Bub.Visible=false; Main.Visible=true
    local curH=H0
    tw(Main,{Size=UDim2.new(0,W0,0,curH),Position=UDim2.new(0.5,-W0/2,0.5,-curH/2)},
        0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end
Bub.MouseButton1Click:Connect(doRes); Bub.TouchTap:Connect(doRes)

-- ── HEADER ─────────────────────────────────────────────────
local Hdr=gf(Main,UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),C.GLASS,T.PANEL,14)
-- Fix corners bottom
local HF=Instance.new("Frame"); HF.Size=UDim2.new(1,0,0,14); HF.Position=UDim2.new(0,0,1,-14)
HF.BackgroundColor3=C.GLASS; HF.BackgroundTransparency=T.PANEL; HF.BorderSizePixel=0; HF.Parent=Hdr

local HIco=lbl(Hdr,"⬡",17,C.A1,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
HIco.Size=UDim2.new(0,32,1,0); HIco.Position=UDim2.new(0,4,0,0); HIco.ZIndex=4
local HTitle=lbl(Hdr,"CONECTA PALABRAS",12,C.TEXT,Enum.Font.GothamBold)
HTitle.Size=UDim2.new(1,-100,0,18); HTitle.Position=UDim2.new(0,37,0,5); HTitle.ZIndex=4
local HSub=lbl(Hdr,"Auto-extractor v7",9,C.TEXTD,Enum.Font.Gotham)
HSub.Size=UDim2.new(1,-100,0,13); HSub.Position=UDim2.new(0,37,0,24); HSub.ZIndex=4

local BMin=btn(Hdr,"—",UDim2.new(0,26,0,24),Color3.fromRGB(18,34,62),C.A1,13)
BMin.Position=UDim2.new(1,-29,0.5,-12); BMin.ZIndex=4
BMin.MouseButton1Click:Connect(doMin); BMin.TouchTap:Connect(doMin)

-- ── BODY ───────────────────────────────────────────────────
local Body=Instance.new("Frame"); Body.Size=UDim2.new(1,-10,1,-50)
Body.Position=UDim2.new(0,5,0,46); Body.BackgroundTransparency=1; Body.Parent=Main

-- ── PREFIJO CARD ───────────────────────────────────────────
local PreCard=gf(Body,UDim2.new(1,0,0,48),UDim2.new(0,0,0,0),C.GLASS2,T.CARD,10)
str(PreCard,Color3.fromRGB(50,60,115),1)

local PreTag=lbl(PreCard,"PREFIJO ACTUAL",8,C.TEXTM,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
PreTag.Size=UDim2.new(0.5,0,0,14); PreTag.Position=UDim2.new(0,8,0,4)

local ProbeTag=lbl(PreCard,"",8,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Right)
ProbeTag.Size=UDim2.new(0.5,-8,0,14); ProbeTag.Position=UDim2.new(0.5,0,0,4)

local PreWord=lbl(PreCard,"---",26,C.A1,Enum.Font.GothamBold,Enum.TextXAlignment.Left)
PreWord.Size=UDim2.new(0.55,0,0,30); PreWord.Position=UDim2.new(0,8,0,16)

local PreAvail=lbl(PreCard,"0 disponibles",10,C.GREEN,Enum.Font.GothamBold,Enum.TextXAlignment.Right)
PreAvail.Size=UDim2.new(0.42,0,0,14); PreAvail.Position=UDim2.new(0.58,0,0,20)
local PreDict=lbl(PreCard,"0 en diccionario",8,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Right)
PreDict.Size=UDim2.new(0.42,0,0,12); PreDict.Position=UDim2.new(0.58,0,0,34)

-- ── BARRA DE PROGRESO PROBE ────────────────────────────────
local ProbeFrm=gf(Body,UDim2.new(1,0,0,22),UDim2.new(0,0,0,52),C.GLASS,0.2,7)
str(ProbeFrm,Color3.fromRGB(38,46,90),1)

local ProbeBar_track=Instance.new("Frame"); ProbeBar_track.Size=UDim2.new(1,-8,0,4)
ProbeBar_track.Position=UDim2.new(0,4,0,4); ProbeBar_track.BackgroundColor3=Color3.fromRGB(24,28,55)
ProbeBar_track.BorderSizePixel=0; ProbeBar_track.Parent=ProbeFrm; rnd(ProbeBar_track,3)

local ProbeBar=Instance.new("Frame"); ProbeBar.Size=UDim2.new(0,0,1,0)
ProbeBar.BackgroundColor3=C.A1; ProbeBar.BorderSizePixel=0; ProbeBar.Parent=ProbeBar_track; rnd(ProbeBar,3)
grad(ProbeBar,C.A3,C.A2,0)

local ProbeInfo=lbl(ProbeFrm,"Buscando RemoteFunction del juego...",8,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
ProbeInfo.Size=UDim2.new(1,0,0,12); ProbeInfo.Position=UDim2.new(0,0,0,10)

-- ── TABS ───────────────────────────────────────────────────
local TabFrm=gf(Body,UDim2.new(1,0,0,24),UDim2.new(0,0,0,78),C.GLASS,0.25,7)

local TB1=btn(TabFrm,"✅ Disponibles",UDim2.new(0.34,-2,1,-4),C.GREEN,C.BLACK,9)
TB1.Position=UDim2.new(0,2,0,2); rnd(TB1,5)
local TB2=btn(TabFrm,"📚 Aprendidas",UDim2.new(0.33,-1,1,-4),Color3.fromRGB(18,22,44),C.TEXTD,9)
TB2.Position=UDim2.new(0.34,1,0,2); rnd(TB2,5)
local TB3=btn(TabFrm,"🔍 Manual",UDim2.new(0.33,-1,1,-4),Color3.fromRGB(18,22,44),C.TEXTD,9)
TB3.Position=UDim2.new(0.67,0,0,2); rnd(TB3,5)

-- ── INFO BAR ───────────────────────────────────────────────
local InfoLbl=lbl(Body,"Iniciando...",8,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
InfoLbl.Size=UDim2.new(1,0,0,14); InfoLbl.Position=UDim2.new(0,0,0,106)

-- ── LISTA ──────────────────────────────────────────────────
local ListH=H0-50-48-22-24-14-14-30-10  -- espacio restante

local ListFrm=gf(Body,UDim2.new(1,0,0,ListH),UDim2.new(0,0,0,122),C.GLASS,T.PANEL,9)
str(ListFrm,Color3.fromRGB(32,38,72),1)

local Scroll=Instance.new("ScrollingFrame")
Scroll.Size=UDim2.new(1,-5,1,0); Scroll.BackgroundTransparency=1; Scroll.BorderSizePixel=0
Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=C.SCROLL
Scroll.CanvasSize=UDim2.new(0,0,0,0); Scroll.ScrollingDirection=Enum.ScrollingDirection.Y; Scroll.Parent=ListFrm
local SL=Instance.new("UIListLayout"); SL.SortOrder=Enum.SortOrder.LayoutOrder; SL.Padding=UDim.new(0,2); SL.Parent=Scroll
local SP=Instance.new("UIPadding"); SP.PaddingTop=UDim.new(0,3); SP.PaddingLeft=UDim.new(0,3); SP.PaddingRight=UDim.new(0,2); SP.Parent=Scroll

local PHF=Instance.new("Frame"); PHF.Size=UDim2.new(1,0,1,0); PHF.BackgroundTransparency=1; PHF.ZIndex=3; PHF.Parent=ListFrm
local PHT=lbl(PHF,"Esperando...",10,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PHT.Size=UDim2.new(1,0,0,16); PHT.Position=UDim2.new(0,0,0.35,0); PHT.ZIndex=3
local PHS=lbl(PHF,"",8,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PHS.Size=UDim2.new(1,-4,0,28); PHS.Position=UDim2.new(0,2,0.35,20); PHS.TextWrapped=true; PHS.ZIndex=3

-- ── PANEL MANUAL (tab 3) ───────────────────────────────────
local ManFrm=Instance.new("Frame"); ManFrm.Size=UDim2.new(1,0,0,ListH)
ManFrm.Position=UDim2.new(0,0,0,122); ManFrm.BackgroundTransparency=1; ManFrm.Visible=false; ManFrm.Parent=Body

local ManIF=gf(ManFrm,UDim2.new(1,0,0,34),UDim2.new(0,0,0,0),C.GLASS2,T.CARD,9)
str(ManIF,Color3.fromRGB(45,55,100),1)
local ManBox=Instance.new("TextBox"); ManBox.Size=UDim2.new(1,-46,1,-8); ManBox.Position=UDim2.new(0,6,0,4)
ManBox.BackgroundTransparency=1; ManBox.PlaceholderText="Escribe prefijo: opo, ax, nar..."
ManBox.PlaceholderColor3=C.TEXTM; ManBox.Text=""; ManBox.TextColor3=C.TEXT
ManBox.TextSize=14; ManBox.Font=Enum.Font.GothamBold; ManBox.ClearTextOnFocus=false
ManBox.TextXAlignment=Enum.TextXAlignment.Left; ManBox.Parent=ManIF

local ManBtn=btn(ManIF,"→",UDim2.new(0,36,0,26),C.A1,C.TEXT,15)
ManBtn.Position=UDim2.new(1,-40,0.5,-13)

local ManInfoL=lbl(ManFrm,"",8,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
ManInfoL.Size=UDim2.new(1,0,0,12); ManInfoL.Position=UDim2.new(0,0,0,38)

local ManScroll=Instance.new("ScrollingFrame"); ManScroll.Size=UDim2.new(1,0,0,ListH-55)
ManScroll.Position=UDim2.new(0,0,0,54); ManScroll.BackgroundColor3=C.GLASS
ManScroll.BackgroundTransparency=T.PANEL; ManScroll.BorderSizePixel=0
ManScroll.ScrollBarThickness=3; ManScroll.ScrollBarImageColor3=C.SCROLL
ManScroll.CanvasSize=UDim2.new(0,0,0,0); ManScroll.Parent=ManFrm; rnd(ManScroll,8)
str(ManScroll,Color3.fromRGB(32,38,72),1)
local ML=Instance.new("UIListLayout"); ML.SortOrder=Enum.SortOrder.LayoutOrder; ML.Padding=UDim.new(0,2); ML.Parent=ManScroll
local MP=Instance.new("UIPadding"); MP.PaddingTop=UDim.new(0,3); MP.PaddingLeft=UDim.new(0,3); MP.PaddingRight=UDim.new(0,2); MP.Parent=ManScroll

-- ── BOTONES INFERIORES ─────────────────────────────────────
local BotFrm=Instance.new("Frame"); BotFrm.Size=UDim2.new(1,0,0,24)
BotFrm.Position=UDim2.new(0,0,0,122+ListH+4); BotFrm.BackgroundTransparency=1; BotFrm.Parent=Body

local BReset=btn(BotFrm,"🔄 Nueva ronda",UDim2.new(0.48,0,1,0),Color3.fromRGB(12,22,50),C.A1,9)
BReset.Position=UDim2.new(0,0,0,0)
local BCopy=btn(BotFrm,"📋 Copiar dict",UDim2.new(0.48,0,1,0),Color3.fromRGB(10,32,18),C.GREEN,9)
BCopy.Position=UDim2.new(0.52,0,0,0)

-- ── HANDLE RESIZE ──────────────────────────────────────────
local Handle=Instance.new("Frame"); Handle.Size=UDim2.new(1,0,0,10)
Handle.Position=UDim2.new(0,0,1,-10); Handle.BackgroundColor3=C.GLASS3
Handle.BackgroundTransparency=T.HANDLE; Handle.BorderSizePixel=0; Handle.Active=true; Handle.ZIndex=10; Handle.Parent=Main; rnd(Handle,5)
local HLine=Instance.new("Frame"); HLine.Size=UDim2.new(0,30,0,3); HLine.Position=UDim2.new(0.5,-15,0.5,-1)
HLine.BackgroundColor3=C.A1; HLine.BackgroundTransparency=0.5; HLine.BorderSizePixel=0; HLine.ZIndex=11; HLine.Parent=Handle; rnd(HLine,2)

local resizing=false; local resY0=0; local resH0=H0
Handle.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        resizing=true; resY0=i.Position.Y; resH0=Main.AbsoluteSize.Y
    end
end)
Handle.InputEnded:Connect(function() resizing=false; H0=Main.AbsoluteSize.Y end)
UIS.InputChanged:Connect(function(i)
    if not resizing then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    local nh=math.clamp(resH0+(i.Position.Y-resY0),300,650)
    Main.Size=UDim2.new(0,W0,0,nh)
    local lh=nh-50-48-22-24-14-14-30-10
    lh=math.max(lh,60)
    ListFrm.Size=UDim2.new(1,0,0,lh)
    ManFrm.Size=UDim2.new(1,0,0,lh)
    ManScroll.Size=UDim2.new(1,0,0,math.max(lh-55,40))
    BotFrm.Position=UDim2.new(0,0,0,122+lh+4)
end)

-- ============================================================
--  RENDER
-- ============================================================
local aConns={}; local curTab=1

local function clearScroll(scr)
    for _,c in ipairs(scr:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _,c in ipairs(aConns) do pcall(function() c:Disconnect() end) end
    aConns={}
    if scr.CanvasSize then scr.CanvasSize=UDim2.new(0,0,0,0) end
end

local function addRow(scr, i, word, col, badge, bcol)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,26)
    row.BackgroundColor3=(i%2==0) and C.GLASS3 or C.GLASS2
    row.BackgroundTransparency=0.1; row.BorderSizePixel=0; row.LayoutOrder=i; row.Parent=scr; rnd(row,5)

    local nl=lbl(row,tostring(i),7,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    nl.Size=UDim2.new(0,16,1,0)

    local wl=lbl(row,word,12,col or C.TEXT,Enum.Font.GothamBold)
    wl.Size=UDim2.new(1,-66,1,0); wl.Position=UDim2.new(0,18,0,0)

    if badge then
        local bf=Instance.new("Frame"); bf.Size=UDim2.new(0,28,0,14); bf.Position=UDim2.new(1,-58,0.5,-7)
        bf.BackgroundColor3=bcol or C.GLASS; bf.BorderSizePixel=0; bf.Parent=row; rnd(bf,4)
        lbl(bf,badge,7,C.TEXT,Enum.Font.Gotham,Enum.TextXAlignment.Center).Size=UDim2.new(1,0,1,0)
    end

    local cp=Instance.new("TextButton"); cp.Size=UDim2.new(0,26,0,18); cp.Position=UDim2.new(1,-28,0.5,-9)
    cp.BackgroundColor3=Color3.fromRGB(20,28,65); cp.BorderSizePixel=0; cp.Text="📋"; cp.TextSize=9
    cp.AutoButtonColor=false; cp.Parent=row; rnd(cp,4)
    local function doCopy()
        pcall(function()
            if setclipboard then setclipboard(word)
            elseif syn and syn.set_clipboard then syn.set_clipboard(word) end
        end)
        cp.BackgroundColor3=C.GREEN; cp.Text="✓"
        task.delay(1,function() if cp and cp.Parent then cp.BackgroundColor3=Color3.fromRGB(20,28,65); cp.Text="📋" end end)
    end
    aConns[#aConns+1]=cp.MouseButton1Click:Connect(doCopy)
    aConns[#aConns+1]=cp.TouchTap:Connect(doCopy)
end

local function updateCanvas(scr)
    local h=0; for _,c in ipairs(scr:GetChildren()) do if c:IsA("Frame") then h=h+28 end end
    scr.CanvasSize=UDim2.new(0,0,0,h+6)
end

local function renderMain()
    clearScroll(Scroll)
    if curTab==1 then
        -- Disponibles
        if currentPre=="" then
            PHF.Visible=true; PHT.Text="Sin prefijo detectado"; PHS.Text="El script lo lee automáticamente de la pantalla del juego"; return
        end
        local av=searchValid(currentPre)
        PHF.Visible=(#av==0)
        if #av==0 then PHT.Text="Sin palabras conocidas con \""..currentPre:upper().."\""; PHS.Text="El diccionario crece con cada ronda · usa tab Manual para buscar"; return end
        for i,w in ipairs(av) do addRow(Scroll,i,w,C.GREEN,tostring(#w).."L",Color3.fromRGB(8,36,18)) end
        PreAvail.Text=tostring(#av).." disponibles"
    elseif curTab==2 then
        -- Diccionario aprendido
        PHF.Visible=(#validArr==0); if #validArr==0 then PHT.Text="Diccionario vacío"; PHS.Text="Juega rondas o espera el probe automático"; return end
        for i,w in ipairs(validArr) do
            local used=usedRound[w]
            addRow(Scroll,i,w,used and C.TEXTD or C.TEXT,
                used and "USADA" or tostring(#w).."L",
                used and Color3.fromRGB(36,18,8) or C.GLASS3)
        end
    elseif curTab==3 then
        -- Usadas esta ronda
        local us={}; for w in pairs(usedRound) do us[#us+1]=w end; table.sort(us)
        PHF.Visible=(#us==0); if #us==0 then PHT.Text="Ninguna usada aún"; PHS.Text="Aparecen al detectarlas en pantalla"; return end
        for i,w in ipairs(us) do addRow(Scroll,i,w,C.ORANGE,"USADA",Color3.fromRGB(38,22,6)) end
    end
    updateCanvas(Scroll)
end

local function renderManual(pre)
    clearScroll(ManScroll)
    if pre=="" then ManInfoL.Text=""; return end
    local pn=norm(pre)
    local av=searchValid(pn)
    ManInfoL.Text=tostring(#av).." disponibles con \""..pre:upper().."\""
    if #av==0 then
        local f=Instance.new("TextLabel"); f.Size=UDim2.new(1,0,0,26); f.BackgroundTransparency=1
        f.Text="Sin resultados (el dict tiene "..tostring(#validArr).." palabras)"; f.TextColor3=C.TEXTD
        f.TextSize=9; f.Font=Enum.Font.Gotham; f.TextXAlignment=Enum.TextXAlignment.Center; f.LayoutOrder=1; f.Parent=ManScroll
        ManScroll.CanvasSize=UDim2.new(0,0,0,32); return
    end
    for i,w in ipairs(av) do addRow(ManScroll,i,w,C.GREEN,tostring(#w).."L",Color3.fromRGB(8,36,18)) end
    updateCanvas(ManScroll)
end

local function updatePreInfo()
    if currentPre~="" then
        local av=searchValid(currentPre)
        PreAvail.Text=tostring(#av).." disponibles"
        PreAvail.TextColor3=(#av>0) and C.GREEN or C.RED
    end
    PreDict.Text=tostring(#validArr).." en diccionario"
end

local function setTab(t)
    curTab=t
    local cols={C.GREEN,C.A1,C.A3}
    local tabs={TB1,TB2,TB3}
    for i,tb in ipairs(tabs) do
        if i==t then tw(tb,{BackgroundColor3=cols[i]},0.12); tb.TextColor3=C.BLACK
        else tw(tb,{BackgroundColor3=Color3.fromRGB(18,22,44)},0.12); tb.TextColor3=C.TEXTD end
    end
    ListFrm.Visible=(t==1 or t==2); ManFrm.Visible=(t==3)
    if t~=3 then renderMain() end
end

TB1.MouseButton1Click:Connect(function() setTab(1) end); TB1.TouchTap:Connect(function() setTab(1) end)
TB2.MouseButton1Click:Connect(function() setTab(2) end); TB2.TouchTap:Connect(function() setTab(2) end)
TB3.MouseButton1Click:Connect(function() setTab(3) end); TB3.TouchTap:Connect(function() setTab(3) end)

ManBtn.MouseButton1Click:Connect(function() renderManual(ManBox.Text) end)
ManBtn.TouchTap:Connect(function() renderManual(ManBox.Text) end)
ManBox.FocusLost:Connect(function(e) if e then renderManual(ManBox.Text) end end)

BReset.MouseButton1Click:Connect(function()
    usedRound={}; currentPre=""; PreWord.Text="---"; PreWord.TextColor3=C.A1
    PreAvail.Text="0 disponibles"; InfoLbl.Text="Ronda nueva"; renderMain()
end)
BReset.TouchTap:Connect(function()
    usedRound={}; currentPre=""; PreWord.Text="---"; PreWord.TextColor3=C.A1
    PreAvail.Text="0 disponibles"; InfoLbl.Text="Ronda nueva"; renderMain()
end)

BCopy.MouseButton1Click:Connect(function()
    local s=table.concat(validArr,"\n")
    pcall(function() if setclipboard then setclipboard(s) elseif syn and syn.set_clipboard then syn.set_clipboard(s) end end)
    BCopy.Text="✓ Copiado"; BCopy.BackgroundColor3=C.GREEN
    task.delay(1.5,function() BCopy.Text="📋 Copiar dict"; BCopy.BackgroundColor3=Color3.fromRGB(10,32,18) end)
end)
BCopy.TouchTap:Connect(function()
    local s=table.concat(validArr,"\n")
    pcall(function() if setclipboard then setclipboard(s) elseif syn and syn.set_clipboard then syn.set_clipboard(s) end end)
    BCopy.Text="✓ Copiado"; BCopy.BackgroundColor3=C.GREEN
    task.delay(1.5,function() BCopy.Text="📋 Copiar dict"; BCopy.BackgroundColor3=Color3.fromRGB(10,32,18) end)
end)

-- ============================================================
--  INTERCEPTOR — FireServer + OnClientEvent
-- ============================================================
local hookedSet = {}

local function looksWord(s)
    local n=norm(s); return #n>=2 and #n<=30 and n:match("^[a-z]+$")~=nil
end
local function looksPre(s)
    return type(s)=="string" and s:match("^%u+$") and #s>=2 and #s<=6
end

local function onServerData(...)
    for _,a in ipairs({...}) do
        local s=tostring(a)
        if looksPre(s) then
            local pn=norm(s)
            if pn~=currentPre then
                currentPre=pn; PreWord.Text=s:upper()
                tw(PreWord,{TextColor3=C.YELLOW},0.1); task.delay(0.4,function() tw(PreWord,{TextColor3=C.A1},0.3) end)
                updatePreInfo(); if curTab==1 then renderMain() end
            end
        elseif looksWord(s) then
            local n=norm(s); local wasNew=not validSet[n]
            addValid(n); markUsed(n); interceptCount=interceptCount+1
            InfoLbl.Text=tostring(#validArr).." palabras · "..tostring(interceptCount).." capturadas"
            if wasNew then updatePreInfo(); if curTab==1 or curTab==2 then renderMain() end end
        elseif type(a)=="table" then
            for _,v in pairs(a) do
                if type(v)=="string" then
                    if looksPre(v) then local pn=norm(v); if pn~=currentPre then currentPre=pn; PreWord.Text=v:upper(); updatePreInfo() end
                    elseif looksWord(v) then addValid(v); interceptCount=interceptCount+1 end
                end
            end
        end
    end
end

local function hookRemote(r, path)
    if hookedSet[r] then return end; hookedSet[r]=true
    if r.ClassName=="RemoteEvent" then
        pcall(function() r.OnClientEvent:Connect(function(...) onServerData(...) end) end)
    end
end

local function hookAll(root, d)
    if d>6 then return end
    local ok,ch=pcall(function() return root:GetChildren() end); if not ok then return end
    for _,c in ipairs(ch) do
        if c.ClassName=="RemoteEvent" or c.ClassName=="RemoteFunction" then hookRemote(c,c:GetFullName()) end
        pcall(function() hookAll(c,d+1) end)
    end
end

-- Hook FireServer via metamethods (Delta soporta esto)
local function hookFireServer()
    local mt=pcall(function() return getrawmetatable(game) end) and getrawmetatable(game)
    if not mt then return false end
    local old=mt.__namecall
    local ok=pcall(function()
        setreadonly(mt,false)
        mt.__namecall=newcclosure(function(self,...)
            local m=getnamecallmethod()
            if (m=="FireServer" or m=="InvokeServer") and
               (self.ClassName=="RemoteEvent" or self.ClassName=="RemoteFunction") then
                local args={...}
                for _,a in ipairs(args) do
                    if type(a)=="string" and looksWord(a) then
                        local n=norm(a)
                        task.delay(0.6,function()
                            if not rejSet[n] then
                                local wasNew=not validSet[n]
                                addValid(n); markUsed(n); interceptCount=interceptCount+1
                                if wasNew then updatePreInfo(); if curTab==1 or curTab==2 then renderMain() end end
                            end
                        end)
                    end
                end
            end
            return old(self,...)
        end)
        setreadonly(mt,true)
    end)
    return ok
end

-- ============================================================
--  PROBE AUTOMÁTICO — prueba candidatos contra el servidor
--  Encuentra el RemoteFunction de validación e invoca cada palabra
-- ============================================================
local PROBE_DELAY = 0.12   -- segundos entre pruebas (no spamear)

-- Busca RemoteFunctions que sirvan para validar palabras
local function findValidationRemote()
    local candidates = {}
    local function scan(inst, d)
        if d>6 then return end
        local ok,ch=pcall(function() return inst:GetChildren() end); if not ok then return end
        for _,c in ipairs(ch) do
            if c.ClassName=="RemoteFunction" then
                -- Prioriza las que tengan nombres relacionados a palabras/validación
                local name=c.Name:lower()
                local score=0
                if name:find("word") or name:find("palabra") then score=10
                elseif name:find("valid") or name:find("check") then score=9
                elseif name:find("submit") or name:find("send") then score=8
                elseif name:find("play") or name:find("game") then score=6
                else score=1 end
                candidates[#candidates+1]={ref=c, score=score, name=c:GetFullName()}
            end
            pcall(function() scan(c,d+1) end)
        end
    end
    pcall(function() scan(RS,0) end)
    pcall(function() scan(game.Workspace,0) end)
    -- Ordena por score
    table.sort(candidates,function(a,b) return a.score>b.score end)
    return candidates
end

-- Prueba una palabra en un RemoteFunction y detecta si la acepta
-- Retorna: "valid" | "invalid" | "unknown"
local function probeWord(rf, word)
    local result="unknown"
    local ok, ret=pcall(function()
        return rf:InvokeServer(word)
    end)
    if not ok then return "error" end
    if ret==nil then return "unknown" end
    -- Interpreta la respuesta
    local rs=tostring(ret):lower()
    if ret==true or rs=="true" or rs=="valid" or rs=="ok" or rs=="1" or rs=="accepted" then
        result="valid"
    elseif ret==false or rs=="false" or rs=="invalid" or rs=="no" or rs=="0" or rs=="rejected" then
        result="invalid"
    elseif type(ret)=="number" then
        result=(ret>0) and "valid" or "invalid"
    elseif type(ret)=="table" then
        -- Algunos juegos retornan tablas con campo success/valid
        if ret.valid==true or ret.success==true or ret.accepted==true then result="valid"
        elseif ret.valid==false or ret.success==false then result="invalid"
        else result="unknown" end
    end
    return result
end

-- También prueba via RemoteEvent (fire and observe)
local function probeWordEvent(re, word)
    -- Mandamos la palabra y esperamos la respuesta de vuelta
    local received=nil
    local conn=re.OnClientEvent:Connect(function(...)
        local args={...}
        for _,a in ipairs(args) do
            local s=tostring(a):lower()
            if s=="true" or s=="valid" or s=="ok" or s=="accepted" then received="valid"
            elseif s=="false" or s=="invalid" or s=="rejected" then received="invalid"
            elseif type(a)==type(true) then received=a and "valid" or "invalid" end
        end
    end)
    pcall(function() re:FireServer(word) end)
    local t=0
    while received==nil and t<0.5 do task.wait(0.05); t=t+0.05 end
    pcall(function() conn:Disconnect() end)
    return received or "unknown"
end

-- Loop de probe automático
local function runProbe(remote, isFunction)
    probeActive=true
    probeTotal=#CANDIDATES
    probeCount=0
    local validCount=0

    ProbeInfo.Text="Probando "..tostring(probeTotal).." palabras candidatas..."
    ProbeTag.Text="🔵 Probando..."
    ProbeTag.TextColor3=C.A1

    for i, word in ipairs(CANDIDATES) do
        if not Main or not Main.Parent then break end
        local n=norm(word)
        -- No reprobar las ya conocidas
        if not validSet[n] and not rejSet[n] then
            local result
            if isFunction then
                result=probeWord(remote, word)
            else
                result=probeWordEvent(remote, word)
            end

            if result=="valid" then
                addValid(word); validCount=validCount+1
                updatePreInfo()
                if curTab==2 then renderMain() end
            elseif result=="invalid" then
                addRej(word)
            end
            -- "unknown" o "error" no hacemos nada, intentaremos de nuevo si hace falta
        end

        probeCount=i
        local pct=i/probeTotal
        tw(ProbeBar,{Size=UDim2.new(pct,0,1,0)},0.1)
        ProbeInfo.Text=tostring(i).."/"..tostring(probeTotal).." · ✅"..tostring(validCount).." · ⏳"

        task.wait(PROBE_DELAY)
    end

    probeActive=false
    ProbeTag.Text="✅ Probe listo · "..tostring(validCount).." válidas"
    ProbeTag.TextColor3=C.GREEN
    ProbeInfo.Text="Diccionario: "..tostring(#validArr).." palabras aprendidas"
    tw(ProbeBar,{Size=UDim2.new(1,0,1,0)},0.3)
    updatePreInfo()
    renderMain()
end

-- ============================================================
--  ESCANEO GUI — detecta prefijo y palabras usadas visibles
-- ============================================================
local guiSeen={}

local function scanGUI()
    local pg=LP:FindFirstChild("PlayerGui"); if not pg then return end
    local function walk(inst,d)
        if d>9 then return end
        local cls=inst.ClassName
        if cls=="TextLabel" or cls=="TextBox" or cls=="TextButton" then
            local txt=(inst.Text or ""):match("^%s*(.-)%s*$") or ""
            if txt~="" and not guiSeen[txt] then
                guiSeen[txt]=true
                if looksPre(txt) then
                    local pn=norm(txt)
                    if pn~=currentPre then
                        currentPre=pn; PreWord.Text=txt:upper()
                        updatePreInfo(); if curTab==1 then renderMain() end
                    end
                elseif looksWord(txt) and #txt>=3 then
                    local n=norm(txt); local wasNew=not validSet[n]
                    addValid(n); markUsed(n)
                    if wasNew then updatePreInfo(); if curTab==1 or curTab==2 then renderMain() end end
                end
            end
        end
        local ok,ch=pcall(function() return inst:GetChildren() end); if not ok then return end
        for _,c in ipairs(ch) do pcall(function() walk(c,d+1) end) end
    end
    pcall(function() walk(pg,0) end)
end

-- ============================================================
--  ANIMACIÓN ENTRADA
-- ============================================================
tw(Main,{Size=UDim2.new(0,W0,0,H0),Position=UDim2.new(0.5,-W0/2,0.5,-H0/2)},
    0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

-- ============================================================
--  INICIO
-- ============================================================
setTab(1)

task.spawn(function()
    task.wait(1.2)  -- espera que cargue el juego

    -- 1. Hook FireServer (metamethod)
    local fsOk=hookFireServer()

    -- 2. Hookea todos los remotes existentes
    hookAll(RS,0); hookAll(game.Workspace,0)
    pcall(function() hookAll(LP:WaitForChild("PlayerGui",3),0) end)

    -- Observa nuevos remotes
    pcall(function()
        RS.DescendantAdded:Connect(function(d)
            if d.ClassName=="RemoteEvent" or d.ClassName=="RemoteFunction" then
                task.wait(0.1); hookRemote(d,d:GetFullName())
            end
        end)
    end)

    local hooked=0; for _ in pairs(hookedSet) do hooked=hooked+1 end
    InfoLbl.Text=tostring(hooked).." remotes · "..(fsOk and "FireServer ✅" or "modo GUI")

    -- 3. Busca RemoteFunction de validación y corre probe
    task.wait(0.5)
    local rfCandidates=findValidationRemote()

    if #rfCandidates>0 then
        -- Intenta el de mayor score primero
        local found=false
        for _,c in ipairs(rfCandidates) do
            ProbeInfo.Text="Probando remote: "..c.name
            -- Prueba con una palabra conocida para ver si responde
            local testResult=probeWord(c.ref,"casa")
            if testResult=="valid" or testResult=="invalid" then
                -- Este remote responde lógicamente = es el de validación
                ProbeTag.Text="🟢 Remote: "..c.ref.Name
                ProbeTag.TextColor3=C.GREEN
                probeRemote=c.ref; probeMode="function"; found=true
                task.wait(0.3)
                runProbe(c.ref,true)
                break
            end
        end
        if not found then
            -- Intenta como RemoteEvent
            ProbeInfo.Text="Buscando por RemoteEvent..."
            -- busca remotes y prueba el más prometedor
            local function scanRE(inst,d)
                if d>5 then return end
                local ok,ch=pcall(function() return inst:GetChildren() end); if not ok then return end
                for _,c in ipairs(ch) do
                    if c.ClassName=="RemoteEvent" and not found then
                        local name=c.Name:lower()
                        if name:find("word") or name:find("play") or name:find("valid") or name:find("submit") then
                            local r=probeWordEvent(c,"casa")
                            if r=="valid" or r=="invalid" then
                                probeRemote=c; probeMode="event"; found=true
                                ProbeTag.Text="🟢 Event: "..c.Name; ProbeTag.TextColor3=C.GREEN
                                task.wait(0.3); runProbe(c,false)
                            end
                        end
                    end
                    pcall(function() scanRE(c,d+1) end)
                end
            end
            pcall(function() scanRE(RS,0) end)
            if not found then
                ProbeTag.Text="⚠ Sin remote de validación"; ProbeTag.TextColor3=C.ORANGE
                ProbeInfo.Text="El juego puede validar server-side sin remote público · usando GUI+hooks"
            end
        end
    else
        ProbeTag.Text="⚠ Sin RemoteFunction"; ProbeTag.TextColor3=C.ORANGE
        ProbeInfo.Text="Usando captura por GUI e interceptación de red"
    end

    -- 4. Loop de escaneo GUI
    local tick=0
    while Main and Main.Parent do
        pcall(scanGUI)
        tick=tick+1
        if tick>=10 then guiSeen={}; tick=0 end
        task.wait(1)
    end
end)
