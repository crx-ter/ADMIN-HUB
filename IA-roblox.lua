local Players    = game:GetService("Players")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local LP         = Players.LocalPlayer

-- ============================================================
--  PALETA
-- ============================================================
local C = {
    BG      = Color3.fromRGB(8, 10, 20),
    PANEL   = Color3.fromRGB(14, 17, 30),
    CARD    = Color3.fromRGB(20, 24, 42),
    CARD2   = Color3.fromRGB(26, 30, 52),
    ACCENT  = Color3.fromRGB(85, 135, 255),
    ACCENT2 = Color3.fromRGB(125, 75, 255),
    GREEN   = Color3.fromRGB(60, 220, 140),
    RED     = Color3.fromRGB(255, 70, 85),
    ORANGE  = Color3.fromRGB(255, 165, 55),
    YELLOW  = Color3.fromRGB(255, 220, 60),
    TEXT    = Color3.fromRGB(230, 232, 255),
    TEXTD   = Color3.fromRGB(140, 145, 180),
    TEXTM   = Color3.fromRGB(65, 70, 108),
    SCROLL  = Color3.fromRGB(85, 135, 255),
}

-- ============================================================
--  HELPERS UI
-- ============================================================
local function R(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function S(p,col,th) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function TW(o,pr,t) TweenSvc:Create(o,TweenInfo.new(t or 0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),pr):Play() end
local function LBL(p,txt,sz,col,fnt,ax)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=txt; l.TextSize=sz or 12
    l.TextColor3=col or C.TEXT; l.Font=fnt or Enum.Font.Gotham
    l.TextXAlignment=ax or Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Center
    l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=p; return l
end
local function BTN(p,txt,sz,bg,tc)
    local b=Instance.new("TextButton"); b.Size=sz; b.BackgroundColor3=bg or C.CARD
    b.BorderSizePixel=0; b.Text=txt; b.TextColor3=tc or C.TEXT; b.TextSize=12
    b.Font=Enum.Font.GothamBold; b.AutoButtonColor=false; b.Parent=p; R(b,7); return b
end

-- ============================================================
--  LIMPIAR INSTANCIAS PREVIAS
-- ============================================================
pcall(function() game:GetService("CoreGui"):FindFirstChild("CW_GUI"):Destroy() end)
pcall(function() LP:WaitForChild("PlayerGui",3):FindFirstChild("CW_GUI"):Destroy() end)

local SG = Instance.new("ScreenGui")
SG.Name="CW_GUI"; SG.ResetOnSpawn=false; SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset=true
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

-- ============================================================
--  VENTANA PRINCIPAL  (compact: 290 x 400)
-- ============================================================
local W, H = 290, 400

local Main = Instance.new("Frame")
Main.Name="Main"; Main.Size=UDim2.new(0,W,0,0)
Main.Position=UDim2.new(0.5,-W/2,0.5,0)
Main.BackgroundColor3=C.BG; Main.BackgroundTransparency=0.08
Main.BorderSizePixel=0; Main.Active=true; Main.Draggable=true; Main.ClipsDescendants=true
Main.Parent=SG; R(Main,13); S(Main,Color3.fromRGB(55,65,120),1)

-- Tira de color top
local TopBar=Instance.new("Frame"); TopBar.Size=UDim2.new(1,0,0,2); TopBar.BackgroundColor3=C.ACCENT
TopBar.BorderSizePixel=0; TopBar.ZIndex=5; TopBar.Parent=Main; R(TopBar,2)
local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(C.ACCENT,C.ACCENT2); g.Rotation=0; g.Parent=TopBar

-- ── BURBUJA MINIMIZAR ──────────────────────────────────────
local Bubble=Instance.new("TextButton")
Bubble.Size=UDim2.new(0,44,0,44); Bubble.Position=UDim2.new(0,10,0,80)
Bubble.BackgroundColor3=C.ACCENT; Bubble.BorderSizePixel=0
Bubble.Text="⬡"; Bubble.TextColor3=C.TEXT; Bubble.TextSize=20; Bubble.Font=Enum.Font.GothamBold
Bubble.AutoButtonColor=false; Bubble.Visible=false; Bubble.ZIndex=60; Bubble.Parent=SG; R(Bubble,22)
S(Bubble,C.ACCENT2,2)
local bg2=Instance.new("UIGradient"); bg2.Color=ColorSequence.new(C.ACCENT,C.ACCENT2); bg2.Rotation=45; bg2.Parent=Bubble

-- ── HEADER ─────────────────────────────────────────────────
local Hdr=Instance.new("Frame"); Hdr.Size=UDim2.new(1,0,0,44)
Hdr.BackgroundColor3=C.PANEL; Hdr.BackgroundTransparency=0.08; Hdr.BorderSizePixel=0; Hdr.Parent=Main; R(Hdr,13)
local HFix=Instance.new("Frame"); HFix.Size=UDim2.new(1,0,0,13); HFix.Position=UDim2.new(0,0,1,-13)
HFix.BackgroundColor3=C.PANEL; HFix.BackgroundTransparency=0.08; HFix.BorderSizePixel=0; HFix.Parent=Hdr

local TIco=LBL(Hdr,"⬡",17,C.ACCENT,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
TIco.Size=UDim2.new(0,32,1,0); TIco.Position=UDim2.new(0,5,0,0); TIco.ZIndex=4
local TTxt=LBL(Hdr,"CONECTA PALABRAS",12,C.TEXT,Enum.Font.GothamBold)
TTxt.Size=UDim2.new(1,-105,0,18); TTxt.Position=UDim2.new(0,38,0,5); TTxt.ZIndex=4
local STxt=LBL(Hdr,"Monitor en tiempo real v5",9,C.TEXTD,Enum.Font.Gotham)
STxt.Size=UDim2.new(1,-105,0,14); STxt.Position=UDim2.new(0,38,0,24); STxt.ZIndex=4

local BMin=BTN(Hdr,"—",UDim2.new(0,28,0,26),Color3.fromRGB(20,38,65),C.ACCENT)
BMin.Position=UDim2.new(1,-31,0.5,-13); BMin.TextSize=13; BMin.ZIndex=4

-- ── BODY ───────────────────────────────────────────────────
local Body=Instance.new("Frame"); Body.Size=UDim2.new(1,-12,1,-50)
Body.Position=UDim2.new(0,6,0,46); Body.BackgroundTransparency=1; Body.Parent=Main

-- ── PREFIJO ACTUAL (grande, visible) ───────────────────────
local PreFrm=Instance.new("Frame"); PreFrm.Size=UDim2.new(1,0,0,58)
PreFrm.BackgroundColor3=C.CARD; PreFrm.BackgroundTransparency=0.05; PreFrm.BorderSizePixel=0; PreFrm.Parent=Body; R(PreFrm,10)
S(PreFrm,Color3.fromRGB(45,55,100),1)

local PreLabel=LBL(PreFrm,"Detectando prefijo...",13,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PreLabel.Size=UDim2.new(1,0,0,18); PreLabel.Position=UDim2.new(0,0,0,4)

local PreWord=LBL(PreFrm,"---",28,C.ACCENT,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
PreWord.Size=UDim2.new(1,0,0,32); PreWord.Position=UDim2.new(0,0,0,22)

-- ── TABS ───────────────────────────────────────────────────
local TabFrm=Instance.new("Frame"); TabFrm.Size=UDim2.new(1,0,0,26)
TabFrm.Position=UDim2.new(0,0,0,62); TabFrm.BackgroundColor3=C.PANEL
TabFrm.BackgroundTransparency=0.2; TabFrm.BorderSizePixel=0; TabFrm.Parent=Body; R(TabFrm,7)

local TB1=BTN(TabFrm,"✅ Usadas",UDim2.new(0.33,-2,1,-4),C.ACCENT,C.TEXT)
TB1.Position=UDim2.new(0,2,0,2); TB1.TextSize=10; R(TB1,5)
local TB2=BTN(TabFrm,"🔍 Prefijo",UDim2.new(0.33,-2,1,-4),Color3.fromRGB(20,24,44),C.TEXTD)
TB2.Position=UDim2.new(0.33,1,0,2); TB2.TextSize=10; R(TB2,5)
local TB3=BTN(TabFrm,"📝 Manual",UDim2.new(0.34,-2,1,-4),Color3.fromRGB(20,24,44),C.TEXTD)
TB3.Position=UDim2.new(0.66,1,0,2); TB3.TextSize=10; R(TB3,5)

-- ── INFO BAR ───────────────────────────────────────────────
local InfoFrm=Instance.new("Frame"); InfoFrm.Size=UDim2.new(1,0,0,20)
InfoFrm.Position=UDim2.new(0,0,0,92); InfoFrm.BackgroundTransparency=1; InfoFrm.Parent=Body
local InfoLbl=LBL(InfoFrm,"Escaneando GUI del juego...",9,C.TEXTM,Enum.Font.Gotham)
InfoLbl.Size=UDim2.new(1,0,1,0); InfoLbl.Position=UDim2.new(0,2,0,0)

-- ── LISTA PRINCIPAL ────────────────────────────────────────
local ListFrm=Instance.new("Frame"); ListFrm.Size=UDim2.new(1,0,0,236)
ListFrm.Position=UDim2.new(0,0,0,115); ListFrm.BackgroundColor3=C.PANEL
ListFrm.BackgroundTransparency=0.12; ListFrm.BorderSizePixel=0; ListFrm.ClipsDescendants=true; ListFrm.Parent=Body
R(ListFrm,9); S(ListFrm,Color3.fromRGB(32,38,72),1)

local Scroll=Instance.new("ScrollingFrame")
Scroll.Size=UDim2.new(1,-6,1,0); Scroll.BackgroundTransparency=1; Scroll.BorderSizePixel=0
Scroll.ScrollBarThickness=3; Scroll.ScrollBarImageColor3=C.SCROLL
Scroll.CanvasSize=UDim2.new(0,0,0,0); Scroll.ScrollingDirection=Enum.ScrollingDirection.Y; Scroll.Parent=ListFrm
local SLayout=Instance.new("UIListLayout"); SLayout.SortOrder=Enum.SortOrder.LayoutOrder; SLayout.Padding=UDim.new(0,2); SLayout.Parent=Scroll
local SPad=Instance.new("UIPadding"); SPad.PaddingTop=UDim.new(0,3); SPad.PaddingLeft=UDim.new(0,3); SPad.PaddingRight=UDim.new(0,2); SPad.Parent=Scroll

-- Placeholder
local PHFrm=Instance.new("Frame"); PHFrm.Size=UDim2.new(1,0,1,0); PHFrm.BackgroundTransparency=1; PHFrm.ZIndex=3; PHFrm.Parent=ListFrm
local PHT=LBL(PHFrm,"Esperando datos del juego...",11,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PHT.Size=UDim2.new(1,0,0,20); PHT.Position=UDim2.new(0,0,0.4,0); PHT.ZIndex=3
local PHS=LBL(PHFrm,"El script detecta las palabras automáticamente",9,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PHS.Size=UDim2.new(1,0,0,16); PHS.Position=UDim2.new(0,0,0.4,24); PHS.ZIndex=3

-- ── INPUT MANUAL (tab 3) ────────────────────────────────────
local ManFrm=Instance.new("Frame"); ManFrm.Size=UDim2.new(1,0,0,236)
ManFrm.Position=UDim2.new(0,0,0,115); ManFrm.BackgroundTransparency=1; ManFrm.Visible=false; ManFrm.Parent=Body

local ManDesc=LBL(ManFrm,"Escribe el prefijo que te dio el juego:",9,C.TEXTD,Enum.Font.Gotham)
ManDesc.Size=UDim2.new(1,0,0,16); ManDesc.Position=UDim2.new(0,2,0,2)

local ManInputF=Instance.new("Frame"); ManInputF.Size=UDim2.new(1,0,0,36)
ManInputF.Position=UDim2.new(0,0,0,20); ManInputF.BackgroundColor3=C.CARD
ManInputF.BackgroundTransparency=0.05; ManInputF.BorderSizePixel=0; ManInputF.Parent=ManFrm; R(ManInputF,9)
S(ManInputF,Color3.fromRGB(45,55,100),1)

local ManBox=Instance.new("TextBox"); ManBox.Size=UDim2.new(1,-50,1,-8); ManBox.Position=UDim2.new(0,8,0,4)
ManBox.BackgroundTransparency=1; ManBox.PlaceholderText="ej: NA, AR, JAS, ES..."
ManBox.PlaceholderColor3=C.TEXTM; ManBox.Text=""; ManBox.TextColor3=C.TEXT
ManBox.TextSize=16; ManBox.Font=Enum.Font.GothamBold; ManBox.ClearTextOnFocus=false
ManBox.TextXAlignment=Enum.TextXAlignment.Left; ManBox.Parent=ManInputF

local ManBtn=BTN(ManInputF,"→",UDim2.new(0,36,0,28),C.ACCENT,C.TEXT)
ManBtn.Position=UDim2.new(1,-40,0.5,-14); ManBtn.TextSize=16

-- Lista de resultados del tab manual
local ManList=Instance.new("ScrollingFrame"); ManList.Size=UDim2.new(1,0,0,172)
ManList.Position=UDim2.new(0,0,0,60); ManList.BackgroundColor3=C.PANEL
ManList.BackgroundTransparency=0.12; ManList.BorderSizePixel=0
ManList.ScrollBarThickness=3; ManList.ScrollBarImageColor3=C.SCROLL
ManList.CanvasSize=UDim2.new(0,0,0,0); ManList.Parent=ManFrm; R(ManList,8)
S(ManList,Color3.fromRGB(32,38,72),1)
local MLLayout=Instance.new("UIListLayout"); MLLayout.SortOrder=Enum.SortOrder.LayoutOrder; MLLayout.Padding=UDim.new(0,2); MLLayout.Parent=ManList
local MLPad=Instance.new("UIPadding"); MLPad.PaddingTop=UDim.new(0,3); MLPad.PaddingLeft=UDim.new(0,3); MLPad.PaddingRight=UDim.new(0,2); MLPad.Parent=ManList

local ManInfoLbl=LBL(ManFrm,"",9,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
ManInfoLbl.Size=UDim2.new(1,0,0,14); ManInfoLbl.Position=UDim2.new(0,0,0,44)

-- ── HANDLE RESIZE ──────────────────────────────────────────
local Handle=Instance.new("Frame"); Handle.Size=UDim2.new(1,0,0,12)
Handle.Position=UDim2.new(0,0,1,-12); Handle.BackgroundColor3=C.CARD2
Handle.BackgroundTransparency=0.3; Handle.BorderSizePixel=0; Handle.Active=true; Handle.ZIndex=10; Handle.Parent=Main; R(Handle,6)
local HLine=Instance.new("Frame"); HLine.Size=UDim2.new(0,36,0,3); HLine.Position=UDim2.new(0.5,-18,0.5,-1)
HLine.BackgroundColor3=C.ACCENT; HLine.BackgroundTransparency=0.5; HLine.BorderSizePixel=0; HLine.ZIndex=11; HLine.Parent=Handle; R(HLine,2)

-- ============================================================
--  DICCIONARIO SEED DEL JUEGO
--  (palabras que el juego Conecta Palabras acepta — español)
--  Construido a partir de patrones observados en el juego:
--  acepta palabras comunes del español, nombres propios NO.
-- ============================================================
local DICT = {}
local DICT_SET = {}  -- para búsqueda O(1)

local WORDS_RAW = {
-- A
"ábaco","abad","abadía","abeja","abismo","ablandar","abono","abrazo","abrir","absoluto",
"abuelo","abuela","abundar","acabar","acción","aceite","acento","aceptar","acero","aclarar",
"acordar","acoso","acto","acudir","acuerdo","adaptar","adelante","adentro","adorar","adulto",
"afecto","afición","agencia","agosto","agua","águila","aguja","ahora","aire","ajeno",
"ajustar","alabar","aldea","alegre","alegría","alejar","alma","altar","alto","altura",
"amanecer","amar","amargo","ambiente","amigo","amiga","amor","amplio","ancho","ángulo",
"animal","ánimo","antes","apagar","apoyo","aprender","árbol","arena","arma","aroma",
"arte","ayer","azul","azúcar",
-- B
"bailar","baile","banco","barco","barrio","batalla","bello","bella","besar","blanco",
"boca","bonito","bosque","brazo","bueno","buscar","burbuja","bajar","barro","base",
"beber","bien","brillar","burla",
-- C
"cabeza","camino","campo","cantar","casa","cielo","ciudad","conocer","corazón","correr",
"comer","comprar","coche","cocina","color","corona","contra","contigo","construir","cosa",
"cuerpo","cuatro","cinco","cien","calor","calma","cambio","canción","claro","clase",
"clima","cobrar","comenzar","comunicar","confianza","confiar","conjunto","contar","crecer",
"crear","creer","cultura","cumplir","curiosidad","caer","calle","carta","cerca","cierto",
"círculo","conejo",
-- CH
"chico","chica","chocolate","chiste","choza","charla","champiñón","chispa",
-- D
"danza","dato","dedo","día","dinero","dormir","dulce","durante","donde","deber",
"decidir","defender","dejar","deseo","destino","diez","dominar","duda","dureza","dar",
"decir","dentro","descansar","diferente",
-- E
"edad","elegir","empezar","encontrar","energía","entre","entonces","escuela","escribir",
"escuchar","esperar","estar","estrella","espejo","espacio","espada","espalda","especial",
"esperanza","estilo","esfuerzo","existir","éxito","echar","ejemplo","empuje","encender",
"enfrentar","enojo","enseñar","entrar","enviar","equipo","error","escoger","espíritu",
"estudiar",
-- F
"familia","feliz","final","flor","forma","fuerza","fuego","fruta","frente","famoso",
"fiel","fluir","fondo","futuro","fe","fallar","fama","faro","favor","fiesta",
"fila","fin","flauta","flecha","flojo","flujo","frío","frasco",
-- G
"gato","grande","gracias","grupo","gente","guerra","gusto","globo","gris","ganar",
"genio","gloria","gritar","guiar","ganador","garra","golpe","gordo","gramo","grifo",
-- H
"hablar","hacer","hermano","hermana","hombre","hora","historia","hueso","hallar",
"honor","horizonte","humano","humilde","haber","hambre","hecho","héroe","hierro",
"hijo","hija","hilo","hogar","honrar","humor","humo","huir",
-- I
"idea","idioma","igual","inicio","imagen","importante","isla","ilusión","impulso",
"interés","intuición","ignorar","impacto","intentar","inventar","izquierda","invierno",
-- J
"jardín","jefe","joven","juego","justo","junto","jornada","juicio","jalar","joya",
"jugar","juntar","jaula","jabón","jamás","jerga",
-- L
"largo","libro","lugar","luna","lengua","lento","libre","luchar","luz","latir",
"lazo","leal","lejos","llamar","llegar","lleno","lograr","lado","lanzar","lavar",
"leer","levantar","limpiar","listo","llevar","lluvia","lobo","loca","loco","lodo",
-- LL
"llave","llama","llanto","llano",
-- M
"mano","mar","mundo","mujer","madre","malo","mapa","mesa","música","mirar",
"mente","meta","miedo","mismo","modo","momento","motor","mover","mejora","mandar",
"manera","matar","mayor","menor","meter","morir","mostrar","magia","marzo","masa",
"miel","monte","muslo","mudo",
-- N
"noche","nombre","nuevo","nunca","nadie","natural","negro","nivel","norte","nacer",
"nada","naranja","niño","niña","nación","necesitar","noble","norma","nieve","niebla",
"nudo","nuez",
-- Ñ
"ñoño","ñame",
-- O
"obra","oreja","oscuro","objeto","oeste","oso","orden","origen","olvido","opinar",
"opción","ocultar","odio","ofrecer","oir","ola","otro","océano","oficio","ojo",
"olivo","ombligo","onza","ópera","oración","orilla","otoño","oveja",
-- P
"padre","país","palabra","papel","parque","perro","pequeño","poder","pez","primera",
"persona","puerta","plaza","planta","plata","playa","poca","poco","paciencia","pasión",
"paz","pensar","perder","pieza","planeta","presente","problema","proceso","promesa",
"propio","pulso","pagar","partir","pasado","pedir","pelear","peor","piel","pisar",
"placer","pleno","practicar","primo","prueba","puño","pecho","pelo","pena","pino",
"piso","polo","polvo","poro","pozo","prado","presa","puma",
-- Q
"querer","quien","quizá","quieto","quedar","queja","quemar","quinto","queso","quema",
-- R
"rama","rápido","ratón","reino","reto","rato","río","rojo","raíz","razón",
"realidad","recuerdo","reflejo","regla","relación","respeto","respuesta","riesgo",
"ritmo","rumbo","rabia","reír","reparar","repetir","resistir","roble","roca","rocío",
"rodar","rogar","ropa","rosa","roto","rubio","rueda","rugir","ruido","ruina",
-- S
"sala","saltar","sangre","saber","secreto","segundo","siempre","sobre","sol","sencillo",
"sentir","ser","silencio","simple","sistema","solución","sueño","surco","sacar",
"seguir","serio","servir","siglo","sitio","sonrisa","subir","suerte","suma","sabio",
"salud","selva","señal","silla","soga","soplo","sordo","suave","suelo","sumar",
-- T
"tarde","tener","tiempo","tierra","todo","trabajo","triste","talento","tarea","temor",
"teoría","terminar","tomar","total","tradición","talla","texto","tipo","tocar","tono",
"torpe","trueno","tubo","techo","tela","tembl","tigre","tiza","tobillo","tórtola",
"tronco","tropa","trozo","tumba",
-- U
"último","unir","uno","usar","único","universo","unión","urgente","ubicar","unidad",
-- V
"valor","vida","vez","viento","verde","volar","voz","viejo","vista","valiente",
"verdad","versión","vía","viaje","visión","voluntad","valer","vencer","venir","ver",
"vivir","volver","vacío","vapor","vara","vela","vena","ventana","verano","vergüenza",
"viudo","volcán","vuelo","vulgo",
-- X
"xilófono",
-- Y
"yema","yerno","yeso","yoga","yugo",
-- Z
"zapato","zona","zumo","zafiro","zorro","zanjar","zarpa","zoológico","zorro","zurdo",
}

-- Normalización
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
    for a,b in pairs(AMAP) do w=w:gsub(a,b) end
    return w
end

-- Carga diccionario
for _,w in ipairs(WORDS_RAW) do
    local n = norm(w)
    if #n >= 2 and n:match("^[a-z]+$") then
        DICT[#DICT+1] = n
        DICT_SET[n]   = true
    end
end

-- Búsqueda por prefijo
local function searchPrefix(pre, limit)
    local res = {}
    for _,w in ipairs(DICT) do
        if w:sub(1,#pre) == pre then
            res[#res+1] = w
            if limit and #res >= limit then break end
        end
    end
    table.sort(res)
    return res
end

-- ============================================================
--  ESTADO
-- ============================================================
local usedWords   = {}   -- set de palabras ya usadas en la ronda
local usedList    = {}   -- lista ordenada para mostrar
local currentPre  = ""   -- prefijo actual del juego
local currentTab  = 1    -- 1=usadas, 2=prefijo, 3=manual
local minimized   = false

-- ============================================================
--  RESIZE
-- ============================================================
local resizing=false; local resY0=0; local resH0=H
Handle.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        resizing=true; resY0=i.Position.Y; resH0=Main.AbsoluteSize.Y
    end
end)
Handle.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        resizing=false; H=Main.AbsoluteSize.Y
    end
end)
UIS.InputChanged:Connect(function(i)
    if not resizing then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    local dy=i.Position.Y-resY0
    local nh=math.clamp(resH0+dy,280,600)
    Main.Size=UDim2.new(0,W,0,nh)
    local listH=nh-52-62-20-115-12
    listH=math.max(listH,80)
    ListFrm.Size=UDim2.new(1,0,0,listH)
    ManList.Size=UDim2.new(1,0,0,math.max(listH-64,60))
end)

-- ============================================================
--  MINIMIZE / RESTORE
-- ============================================================
-- Drag de burbuja
local bDrag=false; local bOff=Vector2.new(0,0)
Bubble.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        bDrag=true; bOff=Vector2.new(i.Position.X-Bubble.AbsolutePosition.X, i.Position.Y-Bubble.AbsolutePosition.Y)
    end
end)
Bubble.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then bDrag=false end
end)
UIS.InputChanged:Connect(function(i)
    if not bDrag then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    local vp=game.Workspace.CurrentCamera.ViewportSize
    Bubble.Position=UDim2.new(0,math.clamp(i.Position.X-bOff.X,0,vp.X-44),0,math.clamp(i.Position.Y-bOff.Y,0,vp.Y-44))
end)

local function doMin()
    minimized=true
    TW(Main,{Size=UDim2.new(0,W,0,0)},0.18)
    task.delay(0.2,function()
        Main.Visible=false
        local vp=game.Workspace.CurrentCamera.ViewportSize
        Bubble.Size=UDim2.new(0,0,0,0)
        Bubble.Position=UDim2.new(0,vp.X-50,0,90)
        Bubble.Visible=true
        TW(Bubble,{Size=UDim2.new(0,44,0,44)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    end)
end
local function doRes()
    minimized=false; Bubble.Visible=false; Main.Visible=true
    TW(Main,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end
BMin.MouseButton1Click:Connect(doMin); BMin.TouchTap:Connect(doMin)
Bubble.MouseButton1Click:Connect(doRes); Bubble.TouchTap:Connect(doRes)

-- ============================================================
--  RENDER LISTA USADAS
-- ============================================================
local itemConns = {}

local function clearScroll(scr)
    for _,c in ipairs(scr:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    for _,c in ipairs(itemConns) do pcall(function() c:Disconnect() end) end
    itemConns={}
end

local function addRow(scr, idx, word, color, badge, badgeColor)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,28)
    row.BackgroundColor3=(idx%2==0) and C.CARD2 or C.CARD
    row.BackgroundTransparency=0.1; row.BorderSizePixel=0; row.LayoutOrder=idx; row.Parent=scr; R(row,5)

    local numL=LBL(row,tostring(idx),8,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    numL.Size=UDim2.new(0,18,1,0); numL.Position=UDim2.new(0,0,0,0)

    local wL=LBL(row,word,13,color or C.TEXT,Enum.Font.GothamBold)
    wL.Size=UDim2.new(1,-76,1,0); wL.Position=UDim2.new(0,20,0,0)

    if badge then
        local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,36,0,16); bg.Position=UDim2.new(1,-72,0.5,-8)
        bg.BackgroundColor3=badgeColor or C.CARD; bg.BorderSizePixel=0; bg.Parent=row; R(bg,5)
        local bl=LBL(bg,badge,8,C.TEXT,Enum.Font.Gotham,Enum.TextXAlignment.Center)
        bl.Size=UDim2.new(1,0,1,0)
    end

    -- Botón copiar
    local cp=Instance.new("TextButton"); cp.Size=UDim2.new(0,32,0,20); cp.Position=UDim2.new(1,-34,0.5,-10)
    cp.BackgroundColor3=Color3.fromRGB(22,32,68); cp.BorderSizePixel=0; cp.Text="📋"
    cp.TextSize=10; cp.AutoButtonColor=false; cp.Parent=row; R(cp,5)
    local function doCopy()
        pcall(function()
            if setclipboard then setclipboard(word)
            elseif syn and syn.set_clipboard then syn.set_clipboard(word) end
        end)
        cp.BackgroundColor3=C.GREEN; cp.Text="✓"
        task.delay(1,function() if cp and cp.Parent then cp.BackgroundColor3=Color3.fromRGB(22,32,68); cp.Text="📋" end end)
    end
    itemConns[#itemConns+1]=cp.MouseButton1Click:Connect(doCopy)
    itemConns[#itemConns+1]=cp.TouchTap:Connect(doCopy)
    return row
end

local function updateCanvas(scr)
    local h=0
    for _,c in ipairs(scr:GetChildren()) do
        if c:IsA("Frame") then h=h+c.AbsoluteSize.Y+2 end
    end
    scr.CanvasSize=UDim2.new(0,0,0,h+6)
end

-- ============================================================
--  TABS LOGIC
-- ============================================================
local function renderUsadas()
    clearScroll(Scroll)
    PHFrm.Visible=(#usedList==0)
    if #usedList==0 then
        PHT.Text="Aún no hay palabras usadas"
        PHS.Text="Juega una ronda para verlas aquí"
        return
    end
    -- Muestra todas las palabras usadas, resaltando la última
    for i,w in ipairs(usedList) do
        local isLast=(i==#usedList)
        addRow(Scroll, i, w,
            isLast and C.YELLOW or C.TEXTD,
            isLast and "ÚLTIMA" or tostring(#w).."L",
            isLast and Color3.fromRGB(60,50,10) or C.CARD2)
    end
    updateCanvas(Scroll)
    -- Auto-scroll al final
    task.wait()
    Scroll.CanvasPosition=Vector2.new(0,math.max(0,Scroll.CanvasSize.Y.Offset-Scroll.AbsoluteSize.Y))
end

local function renderPrefijo()
    clearScroll(Scroll)
    PHFrm.Visible=false
    if currentPre=="" then
        PHFrm.Visible=true
        PHT.Text="Sin prefijo detectado aún"
        PHS.Text="El prefijo se lee automáticamente del juego"
        return
    end
    -- Busca palabras con el prefijo actual que NO estén ya usadas
    local candidates=searchPrefix(currentPre, 80)
    local available={}
    for _,w in ipairs(candidates) do
        if not usedWords[w] then available[#available+1]=w end
    end
    InfoLbl.Text=tostring(#available).." disponibles con \""..currentPre:upper().."\""
    if #available==0 then
        PHFrm.Visible=true
        PHT.Text="Sin sugerencias para \""..currentPre:upper().."\""
        PHS.Text="El diccionario puede no tener esta combinación"
        return
    end
    for i,w in ipairs(available) do
        addRow(Scroll, i, w, C.GREEN, tostring(#w).."L", Color3.fromRGB(10,40,25))
    end
    updateCanvas(Scroll)
end

local function renderManual(pre)
    clearScroll(ManList)
    if pre=="" then ManInfoLbl.Text=""; return end
    local pn=norm(pre)
    local candidates=searchPrefix(pn, 60)
    local available={}
    for _,w in ipairs(candidates) do
        if not usedWords[w] then available[#available+1]=w end
    end
    ManInfoLbl.Text=tostring(#available).." disponibles con \""..pre:upper().."\""
    if #available==0 then
        local noRes=Instance.new("TextLabel"); noRes.Size=UDim2.new(1,0,0,28)
        noRes.BackgroundTransparency=1; noRes.Text="Sin resultados"
        noRes.TextColor3=C.RED; noRes.TextSize=11; noRes.Font=Enum.Font.Gotham
        noRes.TextXAlignment=Enum.TextXAlignment.Center; noRes.LayoutOrder=1; noRes.Parent=ManList
        ManList.CanvasSize=UDim2.new(0,0,0,32)
        return
    end
    for i,w in ipairs(available) do
        addRow(ManList, i, w, C.GREEN, tostring(#w).."L", Color3.fromRGB(10,40,25))
    end
    local h=0
    for _,c in ipairs(ManList:GetChildren()) do if c:IsA("Frame") then h=h+30 end end
    ManList.CanvasSize=UDim2.new(0,0,0,h+6)
end

local function setTab(t)
    currentTab=t
    local tabs={TB1,TB2,TB3}
    local colors={C.ACCENT,C.GREEN,C.ORANGE}
    for i,tb in ipairs(tabs) do
        if i==t then TW(tb,{BackgroundColor3=colors[i]},0.12); tb.TextColor3=C.TEXT
        else TW(tb,{BackgroundColor3=Color3.fromRGB(20,24,44)},0.12); tb.TextColor3=C.TEXTD end
    end
    ListFrm.Visible=(t==1 or t==2)
    ManFrm.Visible=(t==3)
    if t==1 then renderUsadas()
    elseif t==2 then renderPrefijo()
    end
end

TB1.MouseButton1Click:Connect(function() setTab(1) end); TB1.TouchTap:Connect(function() setTab(1) end)
TB2.MouseButton1Click:Connect(function() setTab(2) end); TB2.TouchTap:Connect(function() setTab(2) end)
TB3.MouseButton1Click:Connect(function() setTab(3) end); TB3.TouchTap:Connect(function() setTab(3) end)

ManBtn.MouseButton1Click:Connect(function() renderManual(ManBox.Text) end)
ManBtn.TouchTap:Connect(function() renderManual(ManBox.Text) end)
ManBox.FocusLost:Connect(function(e) if e then renderManual(ManBox.Text) end end)

-- ============================================================
--  LECTURA DE GUI DEL JUEGO — CORE
--  Busca en PlayerGui todos los TextLabels/TextBoxes y extrae:
--  1. El prefijo actual (letras grandes en pantalla)
--  2. Palabras que aparecen como jugadas
-- ============================================================

-- Filtra strings que son palabras de juego (no UI chrome)
local UI_IGNORE = {
    "chairs","pets","profile","vip","invite","store","free","classic",
    "proportionsnormal","avatarpartscaletype","inner","main","content","hud",
    "leftbar","rightbar","bottomrightbar","container","textlabel","frame",
}
local function isUIChrome(s)
    local sl=s:lower()
    for _,v in ipairs(UI_IGNORE) do if sl==v then return true end end
    -- ignora nombres propios (primera letra mayúscula + letras mezcladas)
    if s:match("^%u") and not s:match("^%u%l+$") then return true end
    return false
end

-- Detecta si parece prefijo del juego (2-5 letras mayúsculas)
local function looksPrefijo(s)
    return s:match("^%u%u+$") and #s >= 2 and #s <= 5
end

-- Detecta si es una palabra jugada (minúsculas o capitalizada, 3+ letras)
local function looksPlayedWord(s)
    local n=norm(s)
    return #n >= 3 and n:match("^[a-z]+$") ~= nil and DICT_SET[n] ~= nil
end

local detectedPrefixes = {}   -- candidatos a prefijo
local lastScanTime = 0

local function scanGameGUI()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end

    local newUsed   = {}
    local prefCands = {}

    local function walkGUI(inst, depth)
        if depth > 10 then return end
        local cls = inst.ClassName
        if cls == "TextLabel" or cls == "TextBox" or cls == "TextButton" then
            local txt = (inst.Text or ""):match("^%s*(.-)%s*$")
            if txt and #txt >= 2 and #txt <= 30 then
                -- ¿Prefijo?
                if looksPrefijo(txt) then
                    prefCands[txt] = (prefCands[txt] or 0) + 1
                end
                -- ¿Palabra jugada?
                if looksPlayedWord(txt) and not isUIChrome(txt) then
                    newUsed[norm(txt)] = true
                end
            end
        end
        local ok, ch = pcall(function() return inst:GetChildren() end)
        if not ok then return end
        for _,c in ipairs(ch) do
            pcall(function() walkGUI(c, depth+1) end)
        end
    end

    pcall(function() walkGUI(pg, 0) end)

    -- Actualiza palabras usadas
    local changed = false
    for w in pairs(newUsed) do
        if not usedWords[w] then
            usedWords[w] = true
            usedList[#usedList+1] = w
            changed = true
        end
    end

    -- Prefijo más frecuente
    local bestPre, bestCount = "", 0
    for p,cnt in pairs(prefCands) do
        if cnt > bestCount then bestPre=p; bestCount=cnt end
    end
    local preNorm = norm(bestPre)
    if preNorm ~= currentPre and #preNorm >= 2 then
        currentPre = preNorm
        PreWord.Text = bestPre:upper()
        PreLabel.Text = "Prefijo actual detectado:"
        PreWord.TextColor3 = C.ACCENT
        -- Destella
        TW(PreWord,{TextColor3=C.GREEN},0.1)
        task.delay(0.3,function() TW(PreWord,{TextColor3=C.ACCENT},0.2) end)
        changed = true
    end

    if changed then
        InfoLbl.Text = tostring(#usedList).." palabras usadas · prefijo: "..(currentPre~="" and currentPre:upper() or "---")
        -- Refresca pestaña activa
        if currentTab == 1 then renderUsadas()
        elseif currentTab == 2 then renderPrefijo() end
    end
end

-- Hook RemoteEvents para capturar palabras enviadas por el servidor
local function hookRemotes()
    local function tryHook(inst, path, depth)
        if depth > 6 then return end
        if inst.ClassName == "RemoteEvent" then
            pcall(function()
                inst.OnClientEvent:Connect(function(...)
                    for _,a in ipairs({...}) do
                        local s = tostring(a)
                        local n = norm(s)
                        -- ¿El servidor mandó una palabra nueva?
                        if #n >= 3 and n:match("^[a-z]+$") and not usedWords[n] then
                            -- guarda independientemente del diccionario
                            -- (el servidor sabe más que nuestro diccionario)
                            usedWords[n]=true
                            usedList[#usedList+1]=n
                            InfoLbl.Text=tostring(#usedList).." palabras · prefijo: "..(currentPre~="" and currentPre:upper() or "---")
                            if currentTab==1 then renderUsadas() end
                        end
                        -- ¿Prefijo nuevo?
                        if looksPrefijo(s) then
                            local pn=norm(s)
                            if pn ~= currentPre then
                                currentPre=pn
                                PreWord.Text=s:upper()
                                PreLabel.Text="Prefijo (via red):"
                                if currentTab==2 then renderPrefijo() end
                            end
                        end
                    end
                end)
            end)
        end
        local ok,ch=pcall(function() return inst:GetChildren() end)
        if not ok then return end
        for _,c in ipairs(ch) do pcall(function() tryHook(c,path.."."..c.Name,depth+1) end) end
    end
    pcall(function() tryHook(game:GetService("ReplicatedStorage"),"RS",0) end)
    pcall(function() tryHook(game.Workspace,"WS",0) end)
end

-- ============================================================
--  BOTÓN LIMPIAR RONDA
-- ============================================================
local BtnReset=BTN(Body,"🔄 Nueva ronda",UDim2.new(1,0,0,24),Color3.fromRGB(15,30,60),C.ACCENT)
BtnReset.Position=UDim2.new(0,0,0,358); BtnReset.TextSize=10
local function doReset()
    usedWords={}; usedList={}; currentPre=""
    PreWord.Text="---"; PreLabel.Text="Detectando prefijo..."
    PreWord.TextColor3=C.ACCENT
    InfoLbl.Text="Ronda nueva — esperando palabras..."
    clearScroll(Scroll); clearScroll(ManList)
    PHFrm.Visible=true; PHT.Text="Ronda nueva iniciada"; PHS.Text="Juega para capturar palabras"
    ManInfoLbl.Text=""
end
BtnReset.MouseButton1Click:Connect(doReset); BtnReset.TouchTap:Connect(doReset)

-- ============================================================
--  ANIMACIÓN ENTRADA
-- ============================================================
TW(Main,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},
    0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

-- ============================================================
--  LOOP PRINCIPAL — escanea cada 0.8s
-- ============================================================
hookRemotes()

task.spawn(function()
    InfoLbl.Text="Iniciando monitor..."
    task.wait(1.5)  -- espera a que la GUI del juego cargue
    InfoLbl.Text="Monitoreando GUI del juego..."
    while Main and Main.Parent do
        pcall(scanGameGUI)
        task.wait(0.8)
    end
end)

-- ENDSCRIPT
