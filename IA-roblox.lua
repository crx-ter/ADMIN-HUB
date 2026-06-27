-- ============================================================
--  SERVICIOS
-- ============================================================

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("ReplicatedStorage")
local RunSvc   = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP       = Players.LocalPlayer

-- ============================================================
--  HTTP — Delta/KRNL/Synapse/Fluxus
-- ============================================================
local function httpReq(opts)
    for _, fn in ipairs({
        function() return type(request)=="function" and request(opts) end,
        function() return syn and syn.request and syn.request(opts) end,
        function() return http and http.request and http.request(opts) end,
        function() return fluxus and fluxus.request and fluxus.request(opts) end,
        function() return type(http_request)=="function" and http_request(opts) end,
    }) do
        local ok,r = pcall(fn); if ok and r and r.Body then return r end
    end
    if opts.Method=="GET" then
        local ok,b=pcall(function() return game:GetService("HttpService"):GetAsync(opts.Url,true) end)
        if ok and b then return {Body=b,StatusCode=200} end
    end
    return nil
end

local function httpPost(url,hdrs,body)
    local r=httpReq({Url=url,Method="POST",Headers=hdrs,Body=body})
    if r then return r.Body,r.StatusCode or 200 end
    return nil,0
end

-- ============================================================
--  JSON
-- ============================================================
local function jEnc(v)
    local t=type(v)
    if t=="string" then
        return '"'..(v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'))..'"'
    elseif t=="number"  then return tostring(v)
    elseif t=="boolean" then return v and"true"or"false"
    elseif t=="table" then
        if #v>0 then local p={}; for _,x in ipairs(v) do p[#p+1]=jEnc(x) end; return "["..table.concat(p,",").."]"
        else local p={}; for k,x in pairs(v) do p[#p+1]='"'..k..'":'..jEnc(x) end; return "{"..table.concat(p,",").."}" end
    end
    return "null"
end

-- Parser robusto de respuesta OpenRouter
-- Maneja: content normal, content con escapes, errores del proveedor
local function parseAI(raw)
    if not raw or raw=="" then return nil,"empty" end
    -- Intenta extraer content de choices[0].message.content
    -- El truco: busca el patrón exacto que usa OpenRouter
    local ok, obj = pcall(function()
        -- Busca "content" seguido de su valor (puede tener cualquier cosa)
        -- Primero intenta el patrón más preciso
        local s = raw:match('"content"%s*:%s*"(.-)"%s*[,}]')
        if s then
            return s:gsub('\\"','"'):gsub('\\n','\n'):gsub('\\t','\t'):gsub('\\\\','\\')
        end
        -- Si el content tiene newlines, busca diferente
        s = raw:match('"content"%s*:%s*"([^"]*)"')
        if s then return s:gsub('\\n','\n') end
        return nil
    end)
    if ok and obj and #obj>0 then return obj,nil end
    
    -- Detecta errores de OpenRouter
    local errMsg = raw:match('"message"%s*:%s*"([^"]*)"')
    if errMsg then
        if errMsg:find("upstream") or errMsg:find("provider") then
            return nil,"provider_error"  -- error del proveedor, no del script
        end
        if errMsg:find("rate") then return nil,"rate_limit" end
        if errMsg:find("key") or errMsg:find("auth") then return nil,"auth_error" end
        return nil,errMsg
    end
    return nil,"parse_error:"..raw:sub(1,80)
end

-- ============================================================
--  PALETA MACIZA
-- ============================================================
local C = {
    -- Fondos con capas
    BG0    = Color3.fromRGB(4,5,12),     -- fondo más oscuro
    BG1    = Color3.fromRGB(8,10,22),    -- ventana
    BG2    = Color3.fromRGB(12,15,30),   -- panel
    BG3    = Color3.fromRGB(18,22,42),   -- card
    BG4    = Color3.fromRGB(24,29,54),   -- card hover
    -- Acentos
    A1     = Color3.fromRGB(88,143,255),   -- azul principal
    A2     = Color3.fromRGB(138,72,255),   -- violeta
    A3     = Color3.fromRGB(46,214,255),   -- cyan
    A4     = Color3.fromRGB(255,90,160),   -- pink
    -- Estados
    ON     = Color3.fromRGB(46,210,120),   -- verde ON
    OFF    = Color3.fromRGB(32,36,58),     -- gris OFF
    RED    = Color3.fromRGB(255,58,78),
    ORANGE = Color3.fromRGB(255,152,42),
    YELLOW = Color3.fromRGB(255,210,48),
    -- Texto
    T1     = Color3.fromRGB(235,238,255),  -- primario
    T2     = Color3.fromRGB(140,148,195),  -- secundario
    T3     = Color3.fromRGB(62,68,115),    -- muted
    -- Bordes
    B1     = Color3.fromRGB(52,62,128),    -- borde card
    B2     = Color3.fromRGB(36,44,90),     -- borde suave
    -- Scroll
    SCR    = Color3.fromRGB(88,143,255),
}

-- ============================================================
--  UI HELPERS
-- ============================================================
local function rnd(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function str(p,col,th) local s=Instance.new("UIStroke"); s.Color=col; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function grad(p,c0,c1,rot)
    local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c0,c1); g.Rotation=rot or 0; g.Parent=p
end
local function tw(o,pr,t,s,d) TweenSvc:Create(o,TweenInfo.new(t or 0.15,s or Enum.EasingStyle.Quad,d or Enum.EasingDirection.Out),pr):Play() end
local function lbl(p,txt,sz,col,fnt,ax)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=txt or ""
    l.TextSize=sz or 12; l.TextColor3=col or C.T1; l.Font=fnt or Enum.Font.GothamSemibold
    l.TextXAlignment=ax or Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Center
    l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=p; return l
end
local function frame(p,sz,pos,bg,tr)
    local f=Instance.new("Frame"); f.Size=sz; if pos then f.Position=pos end
    f.BackgroundColor3=bg or C.BG3; if tr then f.BackgroundTransparency=tr end
    f.BorderSizePixel=0; f.Parent=p; return f
end

-- ============================================================
--  ESTADO DE COMANDOS
-- ============================================================
local state = {
    fly      = false, flySpeed = 60,
    noclip   = false,
    god      = false,
    invis    = false,
    freeze   = false,
}
local conns = { fly=nil, noclip=nil, god=nil }

-- Helpers personaje
local function chr()  return LP.Character end
local function root() local c=chr(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()  local c=chr(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ============================================================
--  COMANDOS IY — implementación fiel
-- ============================================================
local IY = {}

function IY.fly(speed)
    speed = math.clamp(tonumber(speed) or state.flySpeed, 0, 500)
    state.fly = true; state.flySpeed = speed
    local r=root(); if not r then return end
    if conns.fly then conns.fly:Disconnect() end
    for _,v in ipairs(r:GetChildren()) do
        if v.Name=="IY_BV" or v.Name=="IY_BG" then v:Destroy() end
    end
    local h=hum(); if h then h.PlatformStand=true end
    local bv=Instance.new("BodyVelocity"); bv.Name="IY_BV"; bv.Velocity=Vector3.zero
    bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=r
    local bg=Instance.new("BodyGyro"); bg.Name="IY_BG"; bg.MaxTorque=Vector3.new(4e5,4e5,4e5)
    bg.P=2e4; bg.D=200; bg.CFrame=r.CFrame; bg.Parent=r
    conns.fly=RunSvc.Heartbeat:Connect(function()
        if not state.fly then conns.fly:Disconnect(); return end
        local cam=workspace.CurrentCamera; local d=Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.Q) then d=d-Vector3.yAxis end
        bv.Velocity=d.Magnitude>0 and d.Unit*state.flySpeed or Vector3.zero
        bg.CFrame=cam.CFrame
    end)
end
function IY.unfly()
    state.fly=false
    if conns.fly then conns.fly:Disconnect(); conns.fly=nil end
    local r=root(); if r then
        for _,v in ipairs(r:GetChildren()) do
            if v.Name=="IY_BV" or v.Name=="IY_BG" then v:Destroy() end
        end
    end
    local h=hum(); if h then h.PlatformStand=false end
end
function IY.setFlySpeed(v)
    state.flySpeed=v
    -- Actualiza en tiempo real si está volando
    if state.fly then
        local r=root(); if r then
            local bv=r:FindFirstChild("IY_BV")
            -- solo actualiza velocidad, el heartbeat la lee de state
        end
    end
end

function IY.noclip()
    state.noclip=true
    if conns.noclip then conns.noclip:Disconnect() end
    conns.noclip=RunSvc.Stepped:Connect(function()
        if not state.noclip then conns.noclip:Disconnect(); return end
        local c=chr(); if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end
function IY.clip()
    state.noclip=false
    if conns.noclip then conns.noclip:Disconnect(); conns.noclip=nil end
    local c=chr(); if c then
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end
    end
end

function IY.god()
    state.god=true
    if conns.god then conns.god:Disconnect() end
    local h=hum(); if h then h.MaxHealth=math.huge; h.Health=math.huge end
    conns.god=RunSvc.Heartbeat:Connect(function()
        if not state.god then conns.god:Disconnect(); return end
        local h2=hum(); if h2 then h2.Health=h2.MaxHealth end
    end)
end
function IY.ungod()
    state.god=false
    if conns.god then conns.god:Disconnect(); conns.god=nil end
    local h=hum(); if h then h.MaxHealth=100; h.Health=100 end
end

function IY.invisible()
    state.invis=true
    local c=chr(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.Transparency=p.Name=="HumanoidRootPart" and 1 or 1 end)
        elseif p:IsA("Decal") then pcall(function() p.Transparency=1 end) end
    end
end
function IY.visible()
    state.invis=false
    local c=chr(); if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.Transparency=p.Name=="HumanoidRootPart" and 1 or 0 end)
        elseif p:IsA("Decal") then pcall(function() p.Transparency=0 end) end
    end
end

function IY.speed(v)   local h=hum(); if h then h.WalkSpeed=v end end
function IY.jump(v)    local h=hum(); if h then h.JumpPower=v end end
function IY.gravity(v) workspace.Gravity=v end
function IY.fov(v)     workspace.CurrentCamera.FieldOfView=math.clamp(v,1,120) end
function IY.time(v)    Lighting.TimeOfDay=("%02d:00:00"):format(math.clamp(v,0,23)) end
function IY.reset()    local h=hum(); if h then h.Health=0 end end

function IY.tp(x,y,z)
    local r=root(); if not r then return end
    r.CFrame=CFrame.new(tonumber(x) or 0,tonumber(y) or 0,tonumber(z) or 0)
end
function IY.goto_(name)
    local r=root(); if not r then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) and p.Character then
            local r2=p.Character:FindFirstChild("HumanoidRootPart")
            if r2 then r.CFrame=r2.CFrame*CFrame.new(0,0,3); return end
        end
    end
end
function IY.bring(name)
    local r=root(); if not r then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Name:lower():find(name:lower()) and p.Character then
            local r2=p.Character:FindFirstChild("HumanoidRootPart")
            if r2 then r2.CFrame=r.CFrame*CFrame.new(0,0,2) end
        end
    end
end
function IY.flight(name,pow)
    pow=tonumber(pow) or 120
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and (name=="all" or p.Name:lower():find(name:lower())) and p.Character then
            local r2=p.Character:FindFirstChild("HumanoidRootPart")
            if r2 then
                local bv=Instance.new("BodyVelocity")
                bv.Velocity=Vector3.new(math.random(-pow,pow),pow*2.5,math.random(-pow,pow))
                bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=r2
                game:GetService("Debris"):AddItem(bv,0.25)
            end
        end
    end
end
function IY.spin()
    local r=root(); if not r then return end
    task.spawn(function()
        for i=1,180 do
            if not r.Parent then break end
            r.CFrame=r.CFrame*CFrame.fromEulerAnglesXYZ(0,math.rad(20),0)
            task.wait(0.02)
        end
    end)
end
function IY.freeze(name)
    local target = name=="me" and chr() or nil
    if not target then
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(name:lower()) and p.Character then target=p.Character; break end
        end
    end
    if target then
        for _,p in ipairs(target:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.Anchored=true end) end
        end
    end
end
function IY.unfreeze(name)
    local target = name=="me" and chr() or nil
    if not target then
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(name:lower()) and p.Character then target=p.Character; break end
        end
    end
    if target then
        for _,p in ipairs(target:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.Anchored=false end) end
        end
    end
end
function IY.follow(name)
    task.spawn(function()
        for i=1,300 do
            local r=root(); if not r then break end
            for _,p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(name:lower()) and p.Character then
                    local r2=p.Character:FindFirstChild("HumanoidRootPart")
                    if r2 then r.CFrame=r2.CFrame*CFrame.new(0,0,3) end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Posiciones guardadas
local savedPos={}
function IY.savepos(name)
    local r=root(); if not r then return end
    local p=r.Position
    savedPos[name:lower()]={name=name,x=math.floor(p.X),y=math.floor(p.Y),z=math.floor(p.Z)}
end
function IY.tppos(name)
    local e=savedPos[name:lower()]
    if not e then for k,v in pairs(savedPos) do if k:find(name:lower()) then e=v; break end end end
    if not e then return false end
    local r=root(); if r then r.CFrame=CFrame.new(e.x,e.y,e.z) end
    return true, e.name
end

-- Parser de comandos de texto
local function runCmd(input)
    if not input or input=="" then return end
    local p={}; for w in input:gmatch("%S+") do p[#p+1]=w end
    local c=(p[1] or ""):lower()
    if c=="fly" then IY.fly(p[2])
    elseif c=="unfly" or c=="nofly" then IY.unfly()
    elseif c=="noclip" then IY.noclip()
    elseif c=="clip" then IY.clip()
    elseif c=="speed" or c=="ws" then IY.speed(tonumber(p[2]) or 50)
    elseif c=="jump" or c=="jp" then IY.jump(tonumber(p[2]) or 80)
    elseif c=="god" then IY.god()
    elseif c=="ungod" then IY.ungod()
    elseif c=="invisible" then IY.invisible()
    elseif c=="visible" then IY.visible()
    elseif c=="tp" then IY.tp(p[2],p[3],p[4])
    elseif c=="goto" then IY.goto_(p[2] or "")
    elseif c=="bring" then IY.bring(p[2] or "")
    elseif c=="flight" then IY.flight(p[2] or "all",p[3])
    elseif c=="gravity" or c=="grav" then IY.gravity(tonumber(p[2]) or 196)
    elseif c=="fov" then IY.fov(tonumber(p[2]) or 70)
    elseif c=="time" then IY.time(tonumber(p[2]) or 14)
    elseif c=="spin" then IY.spin()
    elseif c=="freeze" then IY.freeze(p[2] or "me")
    elseif c=="unfreeze" then IY.unfreeze(p[2] or "me")
    elseif c=="follow" then IY.follow(p[2] or "")
    elseif c=="reset" then IY.reset()
    elseif c=="savepos" then IY.savepos(p[2] or "pos")
    elseif c=="tppos" then IY.tppos(p[2] or "")
    end
end

-- ============================================================
--  IA — OpenRouter con manejo correcto de errores
-- ============================================================
local apiKey    = ""
local aiHistory = {}
local gameCtx   = {name="", placeId=tostring(game.PlaceId)}

local function sysPrompt()
    local pos={}; for k,v in pairs(savedPos) do pos[#pos+1]=v.name end
    local plrs={}; for _,p in ipairs(Players:GetPlayers()) do plrs[#plrs+1]=p.Name end
    return "Eres un asistente de Roblox con Infinite Yield. Juegas en: "..gameCtx.name.." (ID:"..gameCtx.placeId..")."..
    " Jugadores: "..table.concat(plrs,",")..". Posiciones guardadas: "..( #pos>0 and table.concat(pos,",") or "ninguna")..
    ".\nComandos disponibles (usa <CMD>cmd</CMD>): fly [vel], unfly, noclip, clip, god, ungod, invisible, visible, speed [n], jump [n], gravity [n], fov [n], time [0-23], tp [x y z], goto [player], bring [player], flight [player] [power], spin, freeze [me/player], unfreeze, follow [player], reset, savepos [name], tppos [name]."..
    "\nPara guardar posición actual: <CMD>savepos NOMBRE</CMD>. Para ir a posición: <CMD>tppos NOMBRE</CMD>."..
    "\nSi el juego es Conecta Palabras, da estrategias de prefijos. Responde en español, máx 2 oraciones + comandos."
end

local function callAI(msg, cb)
    if #apiKey<8 then cb(nil,"no_key"); return end
    local msgs={{role="system",content=sysPrompt()}}
    local st=math.max(1,#aiHistory-5)
    for i=st,#aiHistory do msgs[#msgs+1]=aiHistory[i] end
    msgs[#msgs+1]={role="user",content=msg}
    local payload=jEnc({model="meta-llama/llama-3.3-70b-instruct:free",max_tokens=300,temperature=0.3,messages=msgs})
    local hdrs={["Content-Type"]="application/json",["Authorization"]="Bearer "..apiKey,
        ["HTTP-Referer"]="https://www.roblox.com",["X-Title"]="IYAssistant"}
    task.spawn(function()
        local body,code=httpPost("https://openrouter.ai/api/v1/chat/completions",hdrs,payload)
        if not body then cb(nil,"no_connection"); return end
        local content,err=parseAI(body)
        if not content then
            -- Si es error del proveedor, reintenta con modelo diferente
            if err=="provider_error" then
                -- Reintenta con gpt-4o-mini
                local payload2=jEnc({model="openai/gpt-4o-mini",max_tokens=200,temperature=0.3,messages=msgs})
                local body2=httpPost("https://openrouter.ai/api/v1/chat/completions",hdrs,payload2)
                if body2 then content,err=parseAI(body2) end
            end
            if not content then cb(nil,err or "unknown"); return end
        end
        -- Guarda historial
        aiHistory[#aiHistory+1]={role="user",content=msg}
        aiHistory[#aiHistory+1]={role="assistant",content=content}
        if #aiHistory>12 then local nh={}; for i=#aiHistory-11,#aiHistory do nh[#nh+1]=aiHistory[i] end; aiHistory=nh end
        cb(content,nil)
    end)
end

-- Extrae <CMD> del texto IA
local function execAICmds(text)
    local results={}
    for cmd in text:gmatch("<CMD>(.-)</CMD>") do
        local c=cmd:match("^%s*(.-)%s*$")
        runCmd(c)
        results[#results+1]=c
    end
    local clean=text:gsub("<CMD>.-</CMD>",""):match("^%s*(.-)%s*$") or ""
    return clean, results
end

-- Quick match sin IA
local function quickMatch(msg)
    local ml=msg:lower()
    -- guardar posición
    local sn=ml:match("guarda.+como%s+['\""]?([%w%s%-_]+)['\""]?$") or
              ml:match("^guarda%s+['\""]?([%w%s%-_]+)['\""]?$")
    if sn then IY.savepos(sn:match("^%s*(.-)%s*$")); return "savepos "..sn, "📌 Guardada: "..sn end
    local tn=ml:match("(?:ve|ir|tp|teleport[aá]r?)%s+a%s+['\""]?([%w%s%-_]+)['\""]?$")
    if not tn then tn=ml:match("ve%s+a%s+([%w%-_]+)") end
    if not tn then tn=ml:match("ir%s+a%s+([%w%-_]+)") end
    if tn then
        tn=tn:match("^%s*(.-)%s*$")
        local ok,name=IY.tppos(tn)
        if ok then return "tppos "..tn, "📍 → "..name
        else return nil,"❌ No existe: "..tn end
    end
    -- Comandos directos
    local Q={
        {"vuelo?%s*(%d*)","fly"},{"fly%s*(%d*)","fly"},{"volar%s*(%d*)","fly"},
        {"aterrizar","unfly"},{"sin vuelo","unfly"},{"noclip","noclip"},
        {"clip%f[^a-z]","clip"},{"atravesar paredes","noclip"},
        {"modo? dios","god"},{"god%f[^a-z]","god"},{"god mode","god"},
        {"quitar dios","ungod"},{"ungod","ungod"},
        {"invisible","invisible"},{"visible%f[^a-z]","visible"},
        {"spin","spin"},{"girar","spin"},{"reset","reset"},{"morir","reset"},
        {"speed%s+(%d+)","speed %1"},{"velocidad%s+(%d+)","speed %1"},
        {"jump%s+(%d+)","jump %1"},{"salto%s+(%d+)","jump %1"},
        {"gravity%s+(%d+)","gravity %1"},{"gravedad%s+(%d+)","gravity %1"},
        {"fov%s+(%d+)","fov %1"},{"hora%s+(%d+)","time %1"},{"time%s+(%d+)","time %1"},
    }
    for _,q in ipairs(Q) do
        local cap=ml:match(q[1])
        if cap~=nil then
            local cmd=q[2]:gsub("%%1",type(cap)=="string" and cap or "")
            if cmd:find("fly") and cap~=nil and tonumber(cap) then cmd="fly "..cap end
            runCmd(cmd); return cmd, "⚡ "..cmd
        end
    end
    return nil,nil
end

-- ============================================================
--  LIMPIAR INSTANCIAS PREVIAS
-- ============================================================
pcall(function() game:GetService("CoreGui"):FindFirstChild("IYA_GUI"):Destroy() end)
pcall(function()
    local pg=LP:FindFirstChild("PlayerGui")
    if pg then local o=pg:FindFirstChild("IYA_GUI"); if o then o:Destroy() end end
end)

local SG=Instance.new("ScreenGui"); SG.Name="IYA_GUI"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset=true
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

-- ============================================================
--  VENTANA PRINCIPAL — 300×520, glassmorphism real
-- ============================================================
local W,H=300,520

-- Sombra exterior
local Shadow=Instance.new("Frame"); Shadow.Size=UDim2.new(0,W+20,0,H+20)
Shadow.Position=UDim2.new(0.5,-(W+20)/2,0.5,-(H+20)/2+6)
Shadow.BackgroundColor3=Color3.fromRGB(0,0,0); Shadow.BackgroundTransparency=0.55
Shadow.BorderSizePixel=0; Shadow.ZIndex=0; Shadow.Parent=SG; rnd(Shadow,18)

local Main=Instance.new("Frame"); Main.Name="Main"
Main.Size=UDim2.new(0,W,0,0); Main.Position=UDim2.new(0.5,-W/2,0.5,0)
Main.BackgroundColor3=C.BG1; Main.BackgroundTransparency=0.10
Main.BorderSizePixel=0; Main.Active=true; Main.Draggable=true; Main.ClipsDescendants=true
Main.ZIndex=1; Main.Parent=SG; rnd(Main,14)
str(Main,C.B1,1.5)

-- Gradiente diagonal de fondo
local BGrad=Instance.new("UIGradient")
BGrad.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10,13,28)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(6,7,16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,8,24)),
})
BGrad.Rotation=145; BGrad.Parent=Main

-- Barra top degradada GRANDE
local TopBar=Instance.new("Frame"); TopBar.Size=UDim2.new(1,0,0,3)
TopBar.BackgroundColor3=C.A1; TopBar.BorderSizePixel=0; TopBar.ZIndex=10; TopBar.Parent=Main; rnd(TopBar,2)
grad(TopBar, C.A3, C.A2, 0)

-- Línea brillante diagonal decorativa
local Glow=Instance.new("Frame"); Glow.Size=UDim2.new(0.6,0,0,1)
Glow.Position=UDim2.new(0,0,0,3); Glow.BackgroundColor3=C.A1
Glow.BackgroundTransparency=0.7; Glow.BorderSizePixel=0; Glow.ZIndex=9; Glow.Parent=Main

-- ── BURBUJA ────────────────────────────────────────────────
local Bub=Instance.new("TextButton"); Bub.Size=UDim2.new(0,0,0,0)
Bub.BackgroundColor3=C.BG1; Bub.BorderSizePixel=0; Bub.Text=""
Bub.AutoButtonColor=false; Bub.Visible=false; Bub.ZIndex=60; Bub.Parent=SG; rnd(Bub,24)
str(Bub,C.A1,2)
-- Icono dentro de la burbuja
local BubIcon=Instance.new("TextLabel"); BubIcon.Size=UDim2.new(1,0,1,0); BubIcon.BackgroundTransparency=1
BubIcon.Text="🤖"; BubIcon.TextSize=22; BubIcon.Font=Enum.Font.Gotham
BubIcon.TextXAlignment=Enum.TextXAlignment.Center; BubIcon.TextYAlignment=Enum.TextYAlignment.Center
BubIcon.ZIndex=61; BubIcon.Parent=Bub
-- Gradiente burbuja
local BubGrad=Instance.new("UIGradient")
BubGrad.Color=ColorSequence.new(Color3.fromRGB(12,15,32),Color3.fromRGB(8,10,22))
BubGrad.Rotation=135; BubGrad.Parent=Bub

local bDrag=false; local bOff=Vector2.zero
Bub.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        bDrag=true; bOff=Vector2.new(i.Position.X-Bub.AbsolutePosition.X,i.Position.Y-Bub.AbsolutePosition.Y)
    end
end)
Bub.InputEnded:Connect(function() bDrag=false end)
UIS.InputChanged:Connect(function(i)
    if not bDrag then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    local vp=workspace.CurrentCamera.ViewportSize
    Bub.Position=UDim2.new(0,math.clamp(i.Position.X-bOff.X,0,vp.X-48),0,math.clamp(i.Position.Y-bOff.Y,0,vp.Y-48))
end)

local function doMin()
    tw(Shadow,{BackgroundTransparency=1},0.15)
    tw(Main,{Size=UDim2.new(0,W,0,0)},0.18)
    task.delay(0.2,function()
        Main.Visible=false; Shadow.Visible=false
        local vp=workspace.CurrentCamera.ViewportSize
        Bub.Size=UDim2.new(0,0,0,0); Bub.Position=UDim2.new(0,vp.X-56,0,86); Bub.Visible=true
        tw(Bub,{Size=UDim2.new(0,48,0,48)},0.26,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    end)
end
local function doRes()
    Bub.Visible=false; Main.Visible=true; Shadow.Visible=true
    Shadow.BackgroundTransparency=0.55
    tw(Main,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.26,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end
Bub.MouseButton1Click:Connect(doRes); Bub.TouchTap:Connect(doRes)

-- ── HEADER ─────────────────────────────────────────────────
local Hdr=frame(Main,UDim2.new(1,0,0,46),UDim2.new(0,0,0,0),C.BG2,0.12)
rnd(Hdr,14)
local HFix=frame(Hdr,UDim2.new(1,0,0,14),UDim2.new(0,0,1,-14),C.BG2,0.12)

-- Icono + título
local HIco=lbl(Hdr,"🤖",18,C.A1,Enum.Font.Gotham,Enum.TextXAlignment.Center)
HIco.Size=UDim2.new(0,36,1,0); HIco.Position=UDim2.new(0,4,0,0); HIco.ZIndex=4

local HTitleF=frame(Hdr,UDim2.new(1,-110,0,30),UDim2.new(0,42,0,8),C.BG2,1)
local HTitle=lbl(HTitleF,"IY ASSISTANT",13,C.T1,Enum.Font.GothamBold)
HTitle.Size=UDim2.new(1,0,0,16); HTitle.ZIndex=4
local HGame=lbl(HTitleF,"...",9,C.T2,Enum.Font.GothamSemibold)
HGame.Size=UDim2.new(1,0,0,13); HGame.Position=UDim2.new(0,0,0,16); HGame.ZIndex=4

-- Botón settings
local function mkHBtn(icon,xOff,bg)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0,28,0,28)
    b.Position=UDim2.new(1,xOff,0.5,-14); b.BackgroundColor3=bg or C.BG3
    b.BackgroundTransparency=0.2; b.BorderSizePixel=0; b.Text=icon
    b.TextColor3=C.T2; b.TextSize=14; b.Font=Enum.Font.Gotham
    b.AutoButtonColor=false; b.ZIndex=5; b.Parent=Hdr; rnd(b,8)
    str(b,C.B2,1); return b
end
local BSet=mkHBtn("⚙",-62,C.BG3)
local BMin=mkHBtn("—",-30,Color3.fromRGB(18,34,62)); BMin.TextColor3=C.A1

BMin.MouseButton1Click:Connect(doMin); BMin.TouchTap:Connect(doMin)

-- ── TABS ───────────────────────────────────────────────────
local TabF=frame(Main,UDim2.new(1,-12,0,26),UDim2.new(0,6,0,50),C.BG2,0.2)
rnd(TabF,8); str(TabF,C.B2,1)

local function mkTab(txt,xScale,xOff)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(xScale,-4,1,-4); b.Position=UDim2.new(0,xOff+2,0,2)
    b.BackgroundColor3=C.BG3; b.BackgroundTransparency=0.2; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=C.T3; b.TextSize=10; b.Font=Enum.Font.GothamBold
    b.AutoButtonColor=false; b.Parent=TabF; rnd(b,6); return b
end
local T1=mkTab("💬 Chat",0.34,0)
local T2=mkTab("⚡ Cmds",0.33,T1.Size.X.Scale*TabF.AbsoluteSize.X)
local T3=mkTab("📌 Pos",0.33,0)
T2.Position=UDim2.new(0.34,2,0,2); T3.Position=UDim2.new(0.67,2,0,2)

-- ── CONTENEDORES DE PANELES ────────────────────────────────
local panelY=80  -- Y donde empiezan los paneles
local panelH=H-panelY-36  -- alto disponible

local function mkPanel()
    local f=frame(Main,UDim2.new(1,-12,0,panelH),UDim2.new(0,6,0,panelY),C.BG2,1)
    f.Visible=false; return f
end
local ChatP=mkPanel(); ChatP.Visible=true
local CmdP=mkPanel()
local PosP=mkPanel()

-- ── HANDLE RESIZE ──────────────────────────────────────────
local Handle=frame(Main,UDim2.new(1,0,0,12),UDim2.new(0,0,1,-12),C.BG3,0.4)
rnd(Handle,6); Handle.Active=true; Handle.ZIndex=8
local HL=frame(Handle,UDim2.new(0,32,0,3),UDim2.new(0.5,-16,0.5,-1),C.A1,0.5)
rnd(HL,2); HL.ZIndex=9; HL.BackgroundColor3=C.A1
local resOn=false; local rY0,rH0=0,H
Handle.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
        resOn=true; rY0=i.Position.Y; rH0=Main.AbsoluteSize.Y
    end
end)
Handle.InputEnded:Connect(function() resOn=false; H=Main.AbsoluteSize.Y end)
UIS.InputChanged:Connect(function(i)
    if not resOn then return end
    if i.UserInputType~=Enum.UserInputType.Touch and i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
    local nh=math.clamp(rH0+(i.Position.Y-rY0),340,700)
    Main.Size=UDim2.new(0,W,0,nh); Shadow.Size=UDim2.new(0,W+20,0,nh+20)
    local ph=nh-panelY-36; ph=math.max(ph,100)
    ChatP.Size=UDim2.new(1,-12,0,ph); CmdP.Size=UDim2.new(1,-12,0,ph); PosP.Size=UDim2.new(1,-12,0,ph)
end)

-- ============================================================
--  PANEL CHAT
-- ============================================================
local MsgScroll=Instance.new("ScrollingFrame"); MsgScroll.Size=UDim2.new(1,0,1,-42)
MsgScroll.BackgroundColor3=C.BG1; MsgScroll.BackgroundTransparency=0.08
MsgScroll.BorderSizePixel=0; MsgScroll.ScrollBarThickness=3; MsgScroll.ScrollBarImageColor3=C.SCR
MsgScroll.CanvasSize=UDim2.new(0,0,0,0); MsgScroll.ScrollingDirection=Enum.ScrollingDirection.Y; MsgScroll.Parent=ChatP
rnd(MsgScroll,10); str(MsgScroll,C.B2,1)
local ML=Instance.new("UIListLayout"); ML.SortOrder=Enum.SortOrder.LayoutOrder; ML.Padding=UDim.new(0,5); ML.Parent=MsgScroll
local MP=Instance.new("UIPadding"); MP.PaddingTop=UDim.new(0,5); MP.PaddingLeft=UDim.new(0,5); MP.PaddingRight=UDim.new(0,5); MP.PaddingBottom=UDim.new(0,4); MP.Parent=MsgScroll

-- Input bar
local IBar=frame(ChatP,UDim2.new(1,0,0,38),UDim2.new(0,0,1,-38),C.BG3,0.08)
rnd(IBar,10); str(IBar,C.B1,1)
local IIcon=lbl(IBar,"›",16,C.A1,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
IIcon.Size=UDim2.new(0,26,1,0); IIcon.Position=UDim2.new(0,0,0,0)
local MBox=Instance.new("TextBox"); MBox.Size=UDim2.new(1,-54,1,-10); MBox.Position=UDim2.new(0,26,0,5)
MBox.BackgroundTransparency=1; MBox.PlaceholderText="activa fly · guarda como base1 · pregunta algo..."
MBox.PlaceholderColor3=C.T3; MBox.Text=""; MBox.TextColor3=C.T1
MBox.TextSize=12; MBox.Font=Enum.Font.Gotham; MBox.ClearTextOnFocus=false
MBox.TextXAlignment=Enum.TextXAlignment.Left; MBox.Parent=IBar
local SendBtn=Instance.new("TextButton"); SendBtn.Size=UDim2.new(0,34,0,28)
SendBtn.Position=UDim2.new(1,-38,0.5,-14); SendBtn.BackgroundColor3=C.A1
SendBtn.BackgroundTransparency=0.1; SendBtn.BorderSizePixel=0
SendBtn.Text="➤"; SendBtn.TextColor3=C.T1; SendBtn.TextSize=14; SendBtn.Font=Enum.Font.GothamBold
SendBtn.AutoButtonColor=false; SendBtn.Parent=IBar; rnd(SendBtn,8)
grad(SendBtn,C.A1,C.A2,90)

-- Añadir burbuja de mensaje
local msgOrd=0
local function addMsg(who,text,isUser,isSys)
    msgOrd=msgOrd+1
    local bub=Instance.new("Frame"); bub.Size=UDim2.new(1,0,0,10)
    bub.BackgroundTransparency=1; bub.BorderSizePixel=0; bub.LayoutOrder=msgOrd
    bub.AutomaticSize=Enum.AutomaticSize.Y; bub.Parent=MsgScroll

    -- Burbuja interna con fondo
    local inner=frame(bub,UDim2.new(1,0,0,10),UDim2.new(0,0,0,0),
        isSys and C.BG4 or (isUser and Color3.fromRGB(20,38,74) or Color3.fromRGB(14,19,42)),0.05)
    inner.AutomaticSize=Enum.AutomaticSize.Y; rnd(inner,9)
    str(inner, isUser and Color3.fromRGB(44,74,158) or (isSys and C.B1 or Color3.fromRGB(32,40,96)), 1)

    -- Acento izquierdo
    local accent=frame(inner,UDim2.new(0,2,1,-8),UDim2.new(0,0,0,4),
        isUser and C.A1 or (isSys and C.YELLOW or C.A2),0)
    rnd(accent,2)

    -- Who label
    local wl=lbl(inner, isSys and "⚡ Sistema" or (isUser and "👤 Tú" or "🤖 IA"), 8,
        isUser and C.A1 or (isSys and C.YELLOW or C.A2), Enum.Font.GothamBold)
    wl.Size=UDim2.new(1,-12,0,14); wl.Position=UDim2.new(0,8,0,4)

    -- Texto
    local ml=Instance.new("TextLabel"); ml.BackgroundTransparency=1
    ml.Size=UDim2.new(1,-14,0,0); ml.Position=UDim2.new(0,8,0,20)
    ml.Text=text; ml.TextSize=11; ml.Font=Enum.Font.Gotham; ml.TextColor3=C.T1
    ml.TextWrapped=true; ml.TextXAlignment=Enum.TextXAlignment.Left
    ml.TextYAlignment=Enum.TextYAlignment.Top; ml.AutomaticSize=Enum.AutomaticSize.Y
    ml.LineHeight=1.3; ml.Parent=inner

    -- Padding inferior
    local bot=frame(inner,UDim2.new(1,0,0,6),nil,C.BG4,1); bot.AutomaticSize=Enum.AutomaticSize.None
    bot.Position=UDim2.new(0,0,1,-2)

    task.wait(); task.wait()
    local tot=0; for _,c in ipairs(MsgScroll:GetChildren()) do if c:IsA("Frame") then tot=tot+c.AbsoluteSize.Y+6 end end
    MsgScroll.CanvasSize=UDim2.new(0,0,0,tot+12)
    MsgScroll.CanvasPosition=Vector2.new(0,math.max(0,tot-MsgScroll.AbsoluteSize.Y+12))
    return ml
end

-- ============================================================
--  PANEL COMANDOS — toggles + sliders inline
-- ============================================================
local CmdScroll=Instance.new("ScrollingFrame"); CmdScroll.Size=UDim2.new(1,0,1,0)
CmdScroll.BackgroundColor3=C.BG1; CmdScroll.BackgroundTransparency=0.08
CmdScroll.BorderSizePixel=0; CmdScroll.ScrollBarThickness=3; CmdScroll.ScrollBarImageColor3=C.SCR
CmdScroll.CanvasSize=UDim2.new(0,0,0,0); CmdScroll.Parent=CmdP
rnd(CmdScroll,10); str(CmdScroll,C.B2,1)
local CL=Instance.new("UIListLayout"); CL.SortOrder=Enum.SortOrder.LayoutOrder; CL.Padding=UDim.new(0,4); CL.Parent=CmdScroll
local CPad=Instance.new("UIPadding"); CPad.PaddingTop=UDim.new(0,6); CPad.PaddingLeft=UDim.new(0,6); CPad.PaddingRight=UDim.new(0,6); CPad.Parent=CmdScroll

-- Sección header
local function mkSecHeader(txt,color,order)
    local f=frame(CmdScroll,UDim2.new(1,0,0,18),nil,C.BG2,1)
    f.LayoutOrder=order
    local l=lbl(f,txt,8,color,Enum.Font.GothamBold)
    l.Size=UDim2.new(1,0,1,0)
    -- Línea separadora
    local line=frame(f,UDim2.new(1,0,0,1),UDim2.new(0,0,1,-1),color,0.7)
    return f
end

-- Toggle macizo con slider opcional
-- Cuando togOn=true → muestra slider abajo
local function mkToggle(parent, icon, label, color, order, onToggle, sliderCfg)
    local isOn=false
    local TOGGLE_H=38
    local SLIDER_H=sliderCfg and 38 or 0

    local container=frame(parent,UDim2.new(1,0,0,TOGGLE_H),nil,C.BG3,0.08)
    container.LayoutOrder=order; rnd(container,9); str(container,C.B2,1)
    container.ClipsDescendants=true

    -- Gradiente de fondo
    grad(container, Color3.fromRGB(20,24,48), Color3.fromRGB(14,17,34), 90)

    -- Barra de color izquierda
    local lbar=frame(container,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),color,0)
    rnd(lbar,2)

    -- Icono
    local ico=lbl(container,icon,16,color,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    ico.Size=UDim2.new(0,30,0,TOGGLE_H); ico.Position=UDim2.new(0,5,0,0)

    -- Label
    local lname=lbl(container,label,12,C.T1,Enum.Font.GothamBold)
    lname.Size=UDim2.new(1,-100,0,TOGGLE_H); lname.Position=UDim2.new(0,36,0,0)

    -- Botón ON/OFF tipo pill
    local pill=Instance.new("Frame"); pill.Size=UDim2.new(0,52,0,24)
    pill.Position=UDim2.new(1,-60,0.5,-12); pill.BackgroundColor3=C.OFF
    pill.BorderSizePixel=0; pill.Parent=container; rnd(pill,12)
    str(pill,C.B1,1)

    local pillDot=Instance.new("Frame"); pillDot.Size=UDim2.new(0,18,0,18)
    pillDot.Position=UDim2.new(0,3,0.5,-9); pillDot.BackgroundColor3=C.T3
    pillDot.BorderSizePixel=0; pillDot.Parent=pill; rnd(pillDot,9)

    local pillTxt=lbl(pill,"OFF",8,C.T3,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
    pillTxt.Size=UDim2.new(1,-24,1,0); pillTxt.Position=UDim2.new(0,22,0,0)

    -- Slider (se muestra al activar)
    local sliderFr=nil; local slValLbl=nil
    if sliderCfg then
        sliderFr=frame(container,UDim2.new(1,0,0,SLIDER_H),UDim2.new(0,0,0,TOGGLE_H),C.BG4,0.15)
        rnd(sliderFr,0)
        local slLbl=lbl(sliderFr," "..sliderCfg.label,8,C.T2,Enum.Font.GothamSemibold)
        slLbl.Size=UDim2.new(0.58,0,0,16); slLbl.Position=UDim2.new(0,6,0,2)
        slValLbl=lbl(sliderFr,tostring(sliderCfg.init),10,color,Enum.Font.GothamBold,Enum.TextXAlignment.Right)
        slValLbl.Size=UDim2.new(0.36,0,0,16); slValLbl.Position=UDim2.new(0.62,-4,0,2)
        -- Track
        local track=frame(sliderFr,UDim2.new(1,-12,0,5),UDim2.new(0,6,0,22),Color3.fromRGB(20,24,50),0)
        rnd(track,3); track.Active=true
        local fill=frame(track,UDim2.new((sliderCfg.init-sliderCfg.min)/(sliderCfg.max-sliderCfg.min),0,1,0),nil,color,0)
        rnd(fill,3); grad(fill,color, Color3.fromRGB(math.max(color.R*255-40,0),math.max(color.G*255-20,0),math.min(color.B*255+40,255)),0)
        local thumb=frame(track,UDim2.new(0,14,0,14),UDim2.new(fill.Size.X.Scale,-7,0.5,-7),C.T1,0)
        rnd(thumb,7); thumb.ZIndex=3; str(thumb,color,1.5)

        local dragging=false
        local function updSlider(ax)
            local rel=math.clamp((ax-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            local val=math.floor(sliderCfg.min+(sliderCfg.max-sliderCfg.min)*rel)
            fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-7,0.5,-7)
            slValLbl.Text=tostring(val); if sliderCfg.onChange then sliderCfg.onChange(val) end
        end
        track.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging=true; updSlider(i.Position.X)
            end
        end)
        track.InputEnded:Connect(function() dragging=false end)
        UIS.InputChanged:Connect(function(i)
            if not dragging then return end
            if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
                updSlider(i.Position.X)
            end
        end)
    end

    -- Toggle logic
    local function toggle()
        isOn=not isOn
        if isOn then
            -- ON
            tw(pill,{BackgroundColor3=color},0.15); tw(pillDot,{Position=UDim2.new(1,-21,0.5,-9),BackgroundColor3=C.T1},0.15)
            pillTxt.Text="ON"; pillTxt.TextColor3=C.T1; pillTxt.Position=UDim2.new(0,2,0,0)
            lbar.BackgroundTransparency=0
            if sliderFr then
                tw(container,{Size=UDim2.new(1,0,0,TOGGLE_H+SLIDER_H)},0.18)
            end
        else
            -- OFF
            tw(pill,{BackgroundColor3=C.OFF},0.15); tw(pillDot,{Position=UDim2.new(0,3,0.5,-9),BackgroundColor3=C.T3},0.15)
            pillTxt.Text="OFF"; pillTxt.TextColor3=C.T3; pillTxt.Position=UDim2.new(0,22,0,0)
            lbar.BackgroundTransparency=1
            if sliderFr then
                tw(container,{Size=UDim2.new(1,0,0,TOGGLE_H)},0.18)
            end
        end
        if onToggle then onToggle(isOn) end
    end

    -- Clickable area = toda la fila superior
    local hitbox=Instance.new("TextButton"); hitbox.Size=UDim2.new(1,0,0,TOGGLE_H)
    hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.BorderSizePixel=0; hitbox.Parent=container; hitbox.ZIndex=4
    hitbox.MouseButton1Click:Connect(toggle); hitbox.TouchTap:Connect(toggle)

    return container
end

-- SLIDER STANDALONE (para speed, jump, etc.)
local function mkSlider(parent, icon, label, color, order, minV, maxV, initV, onChange)
    local f=frame(parent,UDim2.new(1,0,0,50),nil,C.BG3,0.08)
    f.LayoutOrder=order; rnd(f,9); str(f,C.B2,1)
    grad(f, Color3.fromRGB(20,24,48), Color3.fromRGB(14,17,34), 90)

    local lbar=frame(f,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),color,0.3); rnd(lbar,2)
    local ico=lbl(f,icon,15,color,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    ico.Size=UDim2.new(0,30,0,24); ico.Position=UDim2.new(0,5,0,2)
    local lname=lbl(f,label,11,C.T1,Enum.Font.GothamBold)
    lname.Size=UDim2.new(0.6,0,0,24); lname.Position=UDim2.new(0,36,0,2)
    local valL=lbl(f,tostring(initV),11,color,Enum.Font.GothamBold,Enum.TextXAlignment.Right)
    valL.Size=UDim2.new(0.32,0,0,24); valL.Position=UDim2.new(0.66,-4,0,2)

    local track=frame(f,UDim2.new(1,-12,0,6),UDim2.new(0,6,0,34),Color3.fromRGB(18,22,46),0)
    rnd(track,4); track.Active=true
    local fill=frame(track,UDim2.new((initV-minV)/(maxV-minV),0,1,0),nil,color,0)
    rnd(fill,4); grad(fill,C.A3,color,0)
    local thumb=frame(track,UDim2.new(0,14,0,14),UDim2.new(fill.Size.X.Scale,-7,0.5,-7),C.T1,0)
    rnd(thumb,7); thumb.ZIndex=4; str(thumb,color,1.5)

    local drag=false
    local function upd(ax)
        local rel=math.clamp((ax-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(minV+(maxV-minV)*rel)
        fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-7,0.5,-7)
        valL.Text=tostring(val); onChange(val)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true; upd(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function() drag=false end)
    UIS.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then upd(i.Position.X) end
    end)
    return f
end

-- BOTÓN DE ACCIÓN SIMPLE
local function mkAction(parent, icon, label, color, order, onClick)
    local f=frame(parent,UDim2.new(1,0,0,36),nil,C.BG3,0.08)
    f.LayoutOrder=order; rnd(f,9); str(f,C.B2,1)
    grad(f, Color3.fromRGB(20,24,48), Color3.fromRGB(14,17,34), 90)

    local lbar=frame(f,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),color,0.5); rnd(lbar,2)
    local ico=lbl(f,icon,15,color,Enum.Font.Gotham,Enum.TextXAlignment.Center)
    ico.Size=UDim2.new(0,30,0,1); ico.Size=UDim2.new(0,30,1,0); ico.Position=UDim2.new(0,5,0,0)
    local lname=lbl(f,label,11,C.T1,Enum.Font.GothamBold)
    lname.Size=UDim2.new(1,-80,1,0); lname.Position=UDim2.new(0,36,0,0)

    local runBtn=Instance.new("TextButton"); runBtn.Size=UDim2.new(0,36,0,26)
    runBtn.Position=UDim2.new(1,-40,0.5,-13); runBtn.BackgroundColor3=color
    runBtn.BackgroundTransparency=0.2; runBtn.BorderSizePixel=0
    runBtn.Text="▶"; runBtn.TextColor3=C.T1; runBtn.TextSize=11; runBtn.Font=Enum.Font.GothamBold
    runBtn.AutoButtonColor=false; runBtn.Parent=f; rnd(runBtn,7); str(runBtn,color,1)

    local function run()
        tw(runBtn,{BackgroundColor3=C.T1},0.08)
        task.delay(0.12,function() tw(runBtn,{BackgroundColor3=color},0.12) end)
        onClick()
    end
    runBtn.MouseButton1Click:Connect(run); runBtn.TouchTap:Connect(run)
    return f
end

-- CONSTRUYE EL PANEL DE COMANDOS
local function buildCmds()
    for _,c in ipairs(CmdScroll:GetChildren()) do if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end end
    local o=0; local function nx() o=o+1; return o end

    -- MOVIMIENTO
    mkSecHeader("  ✈️   MOVIMIENTO",C.A1,nx())

    mkToggle(CmdScroll,"✈️","Fly",C.A1,nx(),function(on)
        if on then IY.fly(state.flySpeed) else IY.unfly() end
    end, {
        label="Velocidad (" ..0 .."–300)",
        min=0,max=300,init=60,
        onChange=function(v) IY.setFlySpeed(v) end
    })

    mkToggle(CmdScroll,"👻","Noclip",C.A2,nx(),function(on)
        if on then IY.noclip() else IY.clip() end
    end)

    mkSlider(CmdScroll,"⚡","Speed",C.ORANGE,nx(),0,250,16,function(v)
        IY.speed(v)
    end)

    mkSlider(CmdScroll,"🦘","Jump Power",C.YELLOW,nx(),0,400,50,function(v)
        IY.jump(v)
    end)

    mkSlider(CmdScroll,"🌍","Gravity",C.A3,nx(),0,600,196,function(v)
        IY.gravity(v)
    end)

    -- COMBATE
    mkSecHeader("  🛡️   COMBATE & ESTADO",C.ON,nx())

    mkToggle(CmdScroll,"🛡️","God Mode",C.ON,nx(),function(on)
        if on then IY.god() else IY.ungod() end
    end)

    mkToggle(CmdScroll,"👁️","Invisible",Color3.fromRGB(160,100,255),nx(),function(on)
        if on then IY.invisible() else IY.visible() end
    end)

    mkAction(CmdScroll,"🔄","Reset",C.RED,nx(),function() IY.reset() end)
    mkAction(CmdScroll,"🌀","Spin",C.A2,nx(),function() IY.spin() end)

    -- MUNDO
    mkSecHeader("  🌍   MUNDO",C.A3,nx())

    mkSlider(CmdScroll,"🎥","FOV",C.A3,nx(),30,120,70,function(v)
        IY.fov(v)
    end)

    mkSlider(CmdScroll,"🕐","Hora",C.YELLOW,nx(),0,23,14,function(v)
        IY.time(v)
    end)

    mkAction(CmdScroll,"📷","Fix Cámara",C.A1,nx(),function()
        workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
    end)

    -- JUGADORES
    mkSecHeader("  👥   JUGADORES",C.A4,nx())

    mkAction(CmdScroll,"🚀","Flight a TODOS",C.RED,nx(),function()
        IY.flight("all",150)
    end)
    mkAction(CmdScroll,"🧊","Freeze a TODOS",Color3.fromRGB(80,160,255),nx(),function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then IY.freeze(p.Name) end
        end
    end)
    mkAction(CmdScroll,"👥","Ver jugadores",C.T2,nx(),function()
        local lines={"👥 En sala:"}
        for _,p in ipairs(Players:GetPlayers()) do lines[#lines+1]=" · "..p.Name..(p==LP and " (tú)" or "") end
        addMsg("sys",table.concat(lines,"\n"),false,true); setTab and setTab(1)
    end)

    -- Calcula canvas
    task.wait(0.1); local h=0
    for _,c in ipairs(CmdScroll:GetChildren()) do if c:IsA("Frame") then h=h+c.AbsoluteSize.Y+5 end end
    CmdScroll.CanvasSize=UDim2.new(0,0,0,h+10)
end

-- ============================================================
--  PANEL POSICIONES
-- ============================================================
local PosScroll=Instance.new("ScrollingFrame"); PosScroll.Size=UDim2.new(1,0,1,-38)
PosScroll.BackgroundColor3=C.BG1; PosScroll.BackgroundTransparency=0.08
PosScroll.BorderSizePixel=0; PosScroll.ScrollBarThickness=3; PosScroll.ScrollBarImageColor3=C.SCR
PosScroll.CanvasSize=UDim2.new(0,0,0,0); PosScroll.Parent=PosP; rnd(PosScroll,10); str(PosScroll,C.B2,1)
local PL=Instance.new("UIListLayout"); PL.SortOrder=Enum.SortOrder.LayoutOrder; PL.Padding=UDim.new(0,4); PL.Parent=PosScroll
local PP=Instance.new("UIPadding"); PP.PaddingTop=UDim.new(0,5); PP.PaddingLeft=UDim.new(0,5); PP.PaddingRight=UDim.new(0,5); PP.Parent=PosScroll

local PosEmpty=lbl(PosP,"Sin posiciones guardadas\n\nEscríbele a la IA:\n\"guarda como camino1\"",10,C.T3,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PosEmpty.Size=UDim2.new(1,0,0,80); PosEmpty.Position=UDim2.new(0,0,0.2,0); PosEmpty.TextWrapped=true

-- Botón guardar + input
local SaveRow=frame(PosP,UDim2.new(1,0,0,34),UDim2.new(0,0,1,-34),C.BG3,0.1)
rnd(SaveRow,9)
local SaveBtn=Instance.new("TextButton"); SaveBtn.Size=UDim2.new(0.55,-2,1,-4); SaveBtn.Position=UDim2.new(0,2,0,2)
SaveBtn.BackgroundColor3=C.A1; SaveBtn.BackgroundTransparency=0.2; SaveBtn.BorderSizePixel=0
SaveBtn.Text="📌 Guardar posición"; SaveBtn.TextColor3=C.T1; SaveBtn.TextSize=10; SaveBtn.Font=Enum.Font.GothamBold
SaveBtn.AutoButtonColor=false; SaveBtn.Parent=SaveRow; rnd(SaveBtn,7)

local NameBox=Instance.new("TextBox"); NameBox.Size=UDim2.new(0.45,-4,1,-4); NameBox.Position=UDim2.new(0.55,2,0,2)
NameBox.BackgroundColor3=C.BG4; NameBox.BackgroundTransparency=0.1; NameBox.BorderSizePixel=0
NameBox.PlaceholderText="Nombre..."; NameBox.PlaceholderColor3=C.T3; NameBox.Text=""
NameBox.TextColor3=C.T1; NameBox.TextSize=11; NameBox.Font=Enum.Font.Gotham
NameBox.ClearTextOnFocus=false; NameBox.TextXAlignment=Enum.TextXAlignment.Center; NameBox.Parent=SaveRow; rnd(NameBox,7)
str(NameBox,C.B1,1)

local posConns={}
local function renderPos()
    for _,c in ipairs(PosScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _,c in ipairs(posConns) do pcall(function() c:Disconnect() end) end; posConns={}
    local list={}; for k,v in pairs(savedPos) do list[#list+1]=v end
    table.sort(list,function(a,b) return a.name<b.name end)
    PosEmpty.Visible=(#list==0)
    for i,v in ipairs(list) do
        local row=frame(PosScroll,UDim2.new(1,0,0,44),nil,C.BG3,0.08)
        row.LayoutOrder=i; rnd(row,9); str(row,C.B1,1)
        grad(row, Color3.fromRGB(20,24,48), Color3.fromRGB(14,17,34), 90)

        local dot=frame(row,UDim2.new(0,3,1,-10),UDim2.new(0,0,0,5),C.ON,0); rnd(dot,2)
        local nl=lbl(row,"📌 "..v.name,12,C.A1,Enum.Font.GothamBold)
        nl.Size=UDim2.new(1,-82,0,18); nl.Position=UDim2.new(0,8,0,4)
        local cl=lbl(row,"("..v.x..", "..v.y..", "..v.z..")",8,C.T2,Enum.Font.GothamSemibold)
        cl.Size=UDim2.new(1,-82,0,14); cl.Position=UDim2.new(0,8,0,24)

        local function mkPosBtn(txt,bg,xOff)
            local b=Instance.new("TextButton"); b.Size=UDim2.new(0,34,0,30)
            b.Position=UDim2.new(1,xOff,0.5,-15); b.BackgroundColor3=bg; b.BackgroundTransparency=0.2
            b.BorderSizePixel=0; b.Text=txt; b.TextColor3=C.T1; b.TextSize=11; b.Font=Enum.Font.GothamBold
            b.AutoButtonColor=false; b.Parent=row; rnd(b,7); str(b,bg,1); return b
        end
        local tp=mkPosBtn("📍",C.A1,-74)
        local del=mkPosBtn("🗑",C.RED,-36)

        local function doTP()
            local r,n=IY.tppos(v.name)
            addMsg("sys","📍 → "..v.name.." ("..v.x..","..v.y..","..v.z..")",false,true)
        end
        local function doDel() savedPos[v.name:lower()]=nil; renderPos() end
        posConns[#posConns+1]=tp.MouseButton1Click:Connect(doTP); posConns[#posConns+1]=tp.TouchTap:Connect(doTP)
        posConns[#posConns+1]=del.MouseButton1Click:Connect(doDel); posConns[#posConns+1]=del.TouchTap:Connect(doDel)
    end
    PosScroll.CanvasSize=UDim2.new(0,0,0,#list*48+10)
end

local function doSavePos()
    local name=(NameBox.Text or ""):match("^%s*(.-)%s*$") or ""
    if #name==0 then name="pos"..os.time() end
    IY.savepos(name); NameBox.Text=""; renderPos()
    addMsg("sys","📌 Guardada: \""..name.."\"",false,true)
end
SaveBtn.MouseButton1Click:Connect(doSavePos); SaveBtn.TouchTap:Connect(doSavePos)
NameBox.FocusLost:Connect(function(e) if e then doSavePos() end end)

-- ============================================================
--  SETTINGS
-- ============================================================
local SetP=frame(Main,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),C.BG0,0.03)
SetP.Visible=false; SetP.ZIndex=20; rnd(SetP,14); str(SetP,C.B1,1.5)
grad(SetP,Color3.fromRGB(10,12,26),Color3.fromRGB(6,7,16),135)

local StLbl=lbl(SetP,"⚙  Configuración",14,C.T1,Enum.Font.GothamBold,Enum.TextXAlignment.Center)
StLbl.Size=UDim2.new(1,0,0,40); StLbl.ZIndex=21

local KF=frame(SetP,UDim2.new(1,-20,0,38),UDim2.new(0,10,0,48),C.BG3,0.1)
rnd(KF,10); str(KF,C.B1,1); KF.ZIndex=21
local KBox=Instance.new("TextBox"); KBox.Size=UDim2.new(1,-10,1,-8); KBox.Position=UDim2.new(0,5,0,4)
KBox.BackgroundTransparency=1; KBox.PlaceholderText="sk-or-v1-..."
KBox.PlaceholderColor3=C.T3; KBox.Text=""; KBox.TextColor3=C.T1
KBox.TextSize=11; KBox.Font=Enum.Font.Gotham; KBox.ClearTextOnFocus=false
KBox.TextXAlignment=Enum.TextXAlignment.Left; KBox.ZIndex=22; KBox.Parent=KF

local KStat=lbl(SetP,"Sin API Key · los comandos IY funcionan igual",9,C.T2,Enum.Font.Gotham,Enum.TextXAlignment.Center)
KStat.Size=UDim2.new(1,-20,0,14); KStat.Position=UDim2.new(0,10,0,92); KStat.ZIndex=21

local function mkSetBtn(txt,x,bg,tc)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0.44,0,0,34); b.Position=UDim2.new(x,0,0,110)
    b.BackgroundColor3=bg; b.BackgroundTransparency=0.15; b.BorderSizePixel=0
    b.Text=txt; b.TextColor3=tc; b.TextSize=11; b.Font=Enum.Font.GothamBold
    b.AutoButtonColor=false; b.ZIndex=21; b.Parent=SetP; rnd(b,9); str(b,bg,1); return b
end
local KSave=mkSetBtn("✓ Guardar",0.04,C.A1,C.T1)
local KClose=mkSetBtn("✕ Cerrar",0.52,C.RED,C.T1)

local KInfo=lbl(SetP,"openrouter.ai → cuenta gratis → API Keys\nModelo: meta-llama/llama-3.3-70b-instruct:free\n\n💡 Sin key: comandos IY funcionan normalmente.\nCon key: la IA entiende lenguaje natural.",9,C.T2,Enum.Font.Gotham,Enum.TextXAlignment.Center)
KInfo.Size=UDim2.new(1,-20,0,60); KInfo.Position=UDim2.new(0,10,0,152); KInfo.TextWrapped=true; KInfo.ZIndex=21

local function saveKey()
    local k=(KBox.Text or ""):match("^%s*(.-)%s*$") or ""; apiKey=k
    if #k>8 then
        KStat.Text="✓ API Key activada · IA lista"; KStat.TextColor3=C.ON
    else
        KStat.Text="⚠ Key inválida"; KStat.TextColor3=C.ORANGE
    end
    task.delay(1.5,function() SetP.Visible=false end)
end
KSave.MouseButton1Click:Connect(saveKey); KSave.TouchTap:Connect(saveKey)
KClose.MouseButton1Click:Connect(function() SetP.Visible=false end); KClose.TouchTap:Connect(function() SetP.Visible=false end)
BSet.MouseButton1Click:Connect(function() KBox.Text=apiKey; SetP.Visible=true end)
BSet.TouchTap:Connect(function() KBox.Text=apiKey; SetP.Visible=true end)

-- ============================================================
--  TABS LOGIC
-- ============================================================
local curTab=1
local function setTab(t)
    curTab=t; ChatP.Visible=(t==1); CmdP.Visible=(t==2); PosP.Visible=(t==3)
    local cols={C.A1,C.ORANGE,C.ON}; local tabs={T1,T2,T3}
    for i,tb in ipairs(tabs) do
        if i==t then
            tw(tb,{BackgroundColor3=cols[i]},0.14); tb.TextColor3=Color3.fromRGB(0,0,0)
        else
            tw(tb,{BackgroundColor3=Color3.fromRGB(16,20,40)},0.14); tb.TextColor3=C.T3
        end
    end
end

-- Referencia setTab antes de buildCmds (los botones de comandos la usan)
T1.MouseButton1Click:Connect(function() setTab(1) end); T1.TouchTap:Connect(function() setTab(1) end)
T2.MouseButton1Click:Connect(function() setTab(2) end); T2.TouchTap:Connect(function() setTab(2) end)
T3.MouseButton1Click:Connect(function() setTab(3) end); T3.TouchTap:Connect(function() setTab(3) end)

-- ============================================================
--  ENVIAR MENSAJE
-- ============================================================
local aiLoading=false

local function sendMsg()
    if aiLoading then return end
    local msg=(MBox.Text or ""):match("^%s*(.-)%s*$") or ""
    if #msg=="" then return end
    MBox.Text=""; addMsg(LP.Name,msg,true,false)

    -- 1. Quick match sin IA
    local cmd,result=quickMatch(msg)
    if result then
        addMsg("ia",result,false,false); renderPos(); return
    end

    -- 2. IA
    aiLoading=true; SendBtn.Text="⏳"; SendBtn.BackgroundTransparency=0.4
    local think=addMsg("ia","✦ Pensando...",false,false)
    callAI(msg,function(content,err)
        aiLoading=false; SendBtn.Text="➤"; SendBtn.BackgroundTransparency=0.1
        if err then
            local msgs={
                no_key="⚠️ Configura tu API Key en ⚙\n(openrouter.ai → cuenta gratis → API Keys)",
                no_connection="❌ Sin conexión HTTP\nVerifica que Delta tiene HTTP habilitado",
                provider_error="⚠️ El proveedor del modelo tuvo un error.\nEsto pasa con cuentas free — vuelve a intentar",
                rate_limit="⏱️ Rate limit alcanzado\nEspera 30 segundos e intenta de nuevo",
                auth_error="🔑 API Key inválida\nVerifica tu key en openrouter.ai → API Keys",
            }
            local m=msgs[err] or ("❌ Error: "..tostring(err):sub(1,80))
            if think and think.Parent then think.Text=m end; return
        end
        local clean,cmds=execAICmds(content)
        local finalText=clean
        if #cmds>0 and #clean>0 then finalText=clean end
        if #cmds>0 and #clean==0 then finalText="⚡ Ejecutado: "..table.concat(cmds,", ") end
        if think and think.Parent then think.Text=finalText end
        renderPos()
    end)
end

SendBtn.MouseButton1Click:Connect(sendMsg); SendBtn.TouchTap:Connect(sendMsg)
MBox.FocusLost:Connect(function(e) if e then sendMsg() end end)

-- ============================================================
--  ANIMACIÓN ENTRADA
-- ============================================================
setTab(1)
buildCmds()
renderPos()

tw(Main,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},
    0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
tw(Shadow,{Position=UDim2.new(0.5,-(W+20)/2,0.5,-(H+20)/2+6),Size=UDim2.new(0,W+20,0,H+20)},0.3)

task.spawn(function()
    pcall(function()
        gameCtx.name=game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    if gameCtx.name=="" then pcall(function() gameCtx.name=game.Name end) end
    HGame.Text=(gameCtx.name~="" and gameCtx.name or "Roblox").." · "..#Players:GetPlayers().."p"
    task.wait(0.35)
    addMsg("ia",
        "¡Hola! 🤖\n\n"..
        "Tab ⚡ Cmds → toggles ON/OFF con sliders\n"..
        "Tab 📌 Pos → guarda y teleporta\n"..
        "Aquí abajo → lenguaje natural\n\n"..
        "Sin API Key los comandos IY funcionan igual.\n"..
        "Con key (⚙): IA entiende cualquier frase.\n\n"..
        "Errores comunes:\n"..
        "• provider_error = modelo free saturado, reintenta\n"..
        "• no_connection = activa HTTP en Delta",
        false,false)
end)
