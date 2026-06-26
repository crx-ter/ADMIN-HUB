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
--  HTTP — compatible Delta/KRNL/Synapse/Fluxus
-- ============================================================
local function httpReq(opts)
    -- Prueba cada método en orden
    for _, fn in ipairs({
        function() return request and request(opts) end,
        function() return syn and syn.request and syn.request(opts) end,
        function() return http and http.request and http.request(opts) end,
        function() return fluxus and fluxus.request and fluxus.request(opts) end,
        function() return http_request and http_request(opts) end,
    }) do
        local ok, r = pcall(fn)
        if ok and r and r.Body then return r end
    end
    -- Fallback HttpService para GET
    if opts.Method == "GET" then
        local ok, b = pcall(function()
            return game:GetService("HttpService"):GetAsync(opts.Url, true)
        end)
        if ok and b then return {Body=b, StatusCode=200} end
    end
    return nil
end

local function httpPost(url, headers, body)
    local r = httpReq({Url=url, Method="POST", Headers=headers, Body=body})
    if r then return true, r.Body, r.StatusCode end
    return false, nil, nil
end

-- ============================================================
--  JSON mínimo
-- ============================================================
local function jEnc(v)
    local t = type(v)
    if t == "string" then
        v = v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
        return '"'..v..'"'
    elseif t == "number"  then return tostring(v)
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "table" then
        if #v > 0 then
            local p={}; for _,x in ipairs(v) do p[#p+1]=jEnc(x) end
            return "["..table.concat(p,",").."]"
        else
            local p={}; for k,x in pairs(v) do p[#p+1]='"'..tostring(k)..'":'..jEnc(x) end
            return "{"..table.concat(p,",").."}"
        end
    end
    return "null"
end

-- Extrae el campo content de la respuesta OpenRouter
-- Maneja múltiples formatos de respuesta
local function parseAI(s)
    if not s or s == "" then return nil end
    -- Formato estándar choices[0].message.content
    local c = s:match('"content"%s*:%s*"(.-)"(%s*[,}])')
    if c then
        c = c:gsub('\\"','"'):gsub('\\n','\n'):gsub('\\t','\t'):gsub('\\\\','\\')
        if #c > 1 then return c end
    end
    -- Fallback más amplio
    c = s:match('"content"%s*:%s*"([^"]*)"')
    if c and #c > 0 then return c end
    -- Busca error de API
    local e = s:match('"error"%s*:%s*{.-"message"%s*:%s*"([^"]*)"')
    if e then return "❌ Error API: "..e end
    local e2 = s:match('"message"%s*:%s*"([^"]*)"')
    if e2 and not e2:find("Bearer") then return "❌ "..e2 end
    return nil
end

-- ============================================================
--  PALETA
-- ============================================================
local C = {
    BG      = Color3.fromRGB(7,8,18),
    GLASS   = Color3.fromRGB(14,17,32),
    GLASS2  = Color3.fromRGB(20,24,46),
    GLASS3  = Color3.fromRGB(26,31,58),
    A1      = Color3.fromRGB(100,150,255),
    A2      = Color3.fromRGB(130,75,255),
    A3      = Color3.fromRGB(60,210,255),
    GREEN   = Color3.fromRGB(56,220,130),
    RED     = Color3.fromRGB(255,65,80),
    ORANGE  = Color3.fromRGB(255,160,50),
    YELLOW  = Color3.fromRGB(255,215,55),
    TEXT    = Color3.fromRGB(228,231,255),
    TEXTD   = Color3.fromRGB(138,145,188),
    TEXTM   = Color3.fromRGB(60,66,108),
    SCROLL  = Color3.fromRGB(100,150,255),
    USER_BG = Color3.fromRGB(22,42,80),
    AI_BG   = Color3.fromRGB(16,22,46),
    BORDER  = Color3.fromRGB(48,58,118),
    SYS_BG  = Color3.fromRGB(22,30,58),
}

-- ============================================================
--  UI HELPERS
-- ============================================================
local function R(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function S(p,col,th) local s=Instance.new("UIStroke"); s.Color=col or C.BORDER; s.Thickness=th or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end
local function G(p,c0,c1,rot) local g=Instance.new("UIGradient"); g.Color=ColorSequence.new(c0,c1); g.Rotation=rot or 0; g.Parent=p end
local function TW(o,pr,t,s,d) TweenSvc:Create(o,TweenInfo.new(t or 0.15,s or Enum.EasingStyle.Quad,d or Enum.EasingDirection.Out),pr):Play() end
local function LBL(p,txt,sz,col,fnt,ax)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Text=txt; l.TextSize=sz or 12
    l.TextColor3=col or C.TEXT; l.Font=fnt or Enum.Font.Gotham
    l.TextXAlignment=ax or Enum.TextXAlignment.Left; l.TextYAlignment=Enum.TextYAlignment.Center
    l.TextTruncate=Enum.TextTruncate.AtEnd; l.Parent=p; return l
end
local function BTN(p,txt,sz,bg,tc,fs)
    local b=Instance.new("TextButton"); b.Size=sz; b.BackgroundColor3=bg or C.GLASS2
    b.BorderSizePixel=0; b.Text=txt; b.TextColor3=tc or C.TEXT; b.TextSize=fs or 11
    b.Font=Enum.Font.GothamBold; b.AutoButtonColor=false; b.Parent=p; R(b,7); return b
end
local function toggleStyle(btn, on, onCol, offCol)
    btn.BackgroundColor3 = on and (onCol or C.GREEN) or (offCol or Color3.fromRGB(30,20,30))
    btn.TextColor3 = on and C.TEXT or C.TEXTD
end

-- ============================================================
--  ESTADO DE COMANDOS
-- ============================================================
local flyOn      = false; local flySpeed = 60; local flyConn = nil
local noclipOn   = false; local noclipConn = nil
local godOn      = false; local godConn = nil
local flightOn   = false  -- flight = lanzar/empujar jugadores
local espOn      = false; local espConns = {}
local speedVal   = 16
local jumpVal    = 50
local savedPos   = {}     -- {name, x,y,z}

-- Helpers de personaje
local function getChar()  return LP.Character end
local function getRoot()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ============================================================
--  COMANDOS IY — implementación completa
-- ============================================================
local CMD = {}

-- ─── FLY ──────────────────────────────────────────────────
function CMD.fly(speed)
    speed = tonumber(speed) or flySpeed
    flySpeed = speed; flyOn = true
    local root = getRoot(); if not root then return "❌ Sin personaje" end
    if flyConn then flyConn:Disconnect() end
    -- Limpia objetos previos
    for _, v in ipairs(root:GetChildren()) do
        if v.Name == "IY_BV" or v.Name == "IY_BG" then v:Destroy() end
    end
    local hum = getHum()
    if hum then hum.PlatformStand = true end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "IY_BV"; bv.Velocity = Vector3.new(0,0,0)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Parent = root
    local bg = Instance.new("BodyGyro")
    bg.Name = "IY_BG"; bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4; bg.D = 100; bg.CFrame = root.CFrame; bg.Parent = root
    flyConn = RunSvc.Heartbeat:Connect(function()
        if not flyOn or not root or not root.Parent then
            pcall(function() flyConn:Disconnect() end); return
        end
        local cam = workspace.CurrentCamera
        local d = Vector3.new(0,0,0)
        local isTouch = UIS.TouchEnabled and not UIS.KeyboardEnabled
        if not isTouch then
            if UIS:IsKeyDown(Enum.KeyCode.W) then d=d+cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then d=d-cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then d=d-cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then d=d+cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then d=d+Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.Q) then d=d-Vector3.new(0,1,0) end
        end
        bv.Velocity = d.Magnitude>0 and d.Unit*flySpeed or Vector3.new(0,0,0)
        bg.CFrame = cam.CFrame
    end)
    return "✈️ Fly ON · velocidad "..speed
end

function CMD.unfly()
    flyOn = false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    local root=getRoot(); local hum=getHum()
    if root then
        for _,v in ipairs(root:GetChildren()) do
            if v.Name=="IY_BV" or v.Name=="IY_BG" then v:Destroy() end
        end
    end
    if hum then hum.PlatformStand=false end
    return "🚫 Fly OFF"
end

-- ─── NOCLIP ───────────────────────────────────────────────
function CMD.noclip()
    noclipOn = true
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunSvc.Stepped:Connect(function()
        if not noclipOn then pcall(function() noclipConn:Disconnect() end); return end
        local c=getChar(); if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
    return "👻 Noclip ON"
end

function CMD.clip()
    noclipOn = false
    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    local c=getChar(); if c then
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=true end
        end
    end
    return "✅ Noclip OFF"
end

-- ─── SPEED / JUMP ─────────────────────────────────────────
function CMD.speed(n)
    speedVal = tonumber(n) or 50
    local h=getHum(); if h then h.WalkSpeed=speedVal end
    return "⚡ Speed: "..speedVal
end
function CMD.jump(n)
    jumpVal = tonumber(n) or 80
    local h=getHum(); if h then h.JumpPower=jumpVal end
    return "🦘 Jump: "..jumpVal
end
function CMD.jumpheight(n)
    local v=tonumber(n) or 7.2
    local h=getHum(); if h then h.JumpHeight=v end
    return "🦘 JumpHeight: "..v
end

-- ─── GOD ──────────────────────────────────────────────────
function CMD.god()
    godOn=true
    if godConn then godConn:Disconnect() end
    local h=getHum(); if h then h.MaxHealth=math.huge; h.Health=math.huge end
    godConn=RunSvc.Heartbeat:Connect(function()
        if not godOn then pcall(function() godConn:Disconnect() end); return end
        local h2=getHum(); if h2 then h2.Health=h2.MaxHealth end
    end)
    return "🛡️ God ON"
end
function CMD.ungod()
    godOn=false
    if godConn then godConn:Disconnect(); godConn=nil end
    local h=getHum(); if h then h.MaxHealth=100; h.Health=100 end
    return "💔 God OFF"
end

-- ─── TELEPORT ─────────────────────────────────────────────
function CMD.tp(a,b,cc)
    local root=getRoot(); if not root then return "❌ Sin personaje" end
    local x,y,z=tonumber(a),tonumber(b),tonumber(cc)
    if x and y and z then
        root.CFrame=CFrame.new(x,y,z)
        return "📍 Tp → ("..x..","..y..","..z..")"
    end
    -- busca jugador por nombre
    local name=tostring(a or ""):lower()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) and p.Character then
            local r2=p.Character:FindFirstChild("HumanoidRootPart")
            if r2 then root.CFrame=r2.CFrame*CFrame.new(0,0,3); return "📍 Tp → "..p.Name end
        end
    end
    return "❌ Jugador no encontrado: "..tostring(a)
end

function CMD.goto_(target)
    return CMD.tp(tostring(target))
end

function CMD.bring(target)
    local root=getRoot(); if not root then return "❌ Sin personaje" end
    local name=tostring(target or ""):lower(); local count=0
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Name:lower():find(name) and p.Character then
            local r2=p.Character:FindFirstChild("HumanoidRootPart")
            if r2 then r2.CFrame=root.CFrame*CFrame.new(0,0,2); count=count+1 end
        end
    end
    return count>0 and "🤝 Traído: "..target or "❌ No encontrado"
end

-- ─── INVISIBLE ────────────────────────────────────────────
function CMD.invisible()
    local c=getChar(); if not c then return "❌ Sin personaje" end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then pcall(function() p.Transparency=1 end)
        elseif p:IsA("Decal")  then pcall(function() p.Transparency=1 end)
        elseif p:IsA("SpecialMesh") then pcall(function() p.Scale=Vector3.new(0,0,0) end)
        end
    end
    return "👁️ Invisible"
end

function CMD.visible()
    local c=getChar(); if not c then return "❌ Sin personaje" end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            local name=p.Name:lower()
            if name=="humanoidrootpart" then pcall(function() p.Transparency=1 end)
            else pcall(function() p.Transparency=0 end) end
        elseif p:IsA("Decal") then pcall(function() p.Transparency=0 end)
        elseif p:IsA("SpecialMesh") then pcall(function() p.Scale=Vector3.new(1,1,1) end)
        end
    end
    return "👁️ Visible"
end

-- ─── FLIGHT (lanza jugadores al aire) ─────────────────────
-- "flight" en IY usualmente = fuerza/impulso sobre otros
function CMD.flight(target, power)
    local root=getRoot(); if not root then return "❌ Sin personaje" end
    local pow=tonumber(power) or 100
    local name=tostring(target or ""):lower(); local count=0
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and (name=="" or name=="all" or p.Name:lower():find(name)) then
            if p.Character then
                local r2=p.Character:FindFirstChild("HumanoidRootPart")
                local h2=p.Character:FindFirstChildOfClass("Humanoid")
                if r2 then
                    local bv=Instance.new("BodyVelocity")
                    bv.Velocity=Vector3.new(math.random(-pow,pow),pow*2,math.random(-pow,pow))
                    bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Parent=r2
                    game:GetService("Debris"):AddItem(bv,0.3)
                    count=count+1
                end
            end
        end
    end
    return count>0 and "🚀 Flight lanzado a "..count.." jugadores (pow "..pow..")" or "❌ Sin objetivo"
end

-- ─── OTROS COMANDOS IY ────────────────────────────────────
function CMD.reset()
    local h=getHum(); if h then h.Health=0 end; return "💀 Reset"
end
function CMD.sit()
    local h=getHum(); if h then h.Sit=true end; return "🪑 Sentado"
end
function CMD.unsit()
    local h=getHum(); if h then h.Sit=false end; return "🚶 De pie"
end
function CMD.chat(...)
    local msg=table.concat({...}," ")
    pcall(function() LP:Chat(msg) end)
    return "💬 Chat: "..msg
end
function CMD.time(n)
    local t=tonumber(n) or 14
    Lighting.TimeOfDay=("%02d:00:00"):format(math.clamp(t,0,23))
    return "🕐 Hora: "..t
end
function CMD.brightness(n)
    Lighting.Brightness=tonumber(n) or 1; return "☀️ Brillo: "..(n or 1)
end
function CMD.fogend(n)
    Lighting.FogEnd=tonumber(n) or 100000; return "🌫️ FogEnd: "..(n or 100000)
end
function CMD.fov(n)
    workspace.CurrentCamera.FieldOfView=math.clamp(tonumber(n) or 70,1,120)
    return "🎥 FOV: "..(n or 70)
end
function CMD.zoom(n)
    pcall(function() LP.CameraMaxZoomDistance=tonumber(n) or 100 end)
    return "🔭 Zoom: "..(n or 100)
end
function CMD.gravity(n)
    workspace.Gravity=tonumber(n) or 196.2; return "🌍 Gravedad: "..(n or 196.2)
end
function CMD.hum(n)  -- cambia max health
    local h=getHum(); local v=tonumber(n) or 100
    if h then h.MaxHealth=v; h.Health=v end; return "❤️ HP: "..v
end
function CMD.freeze(target)
    local name=tostring(target or "me"):lower()
    local function doFreeze(char)
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.Anchored=true end) end
        end
    end
    if name=="me" or name=="self" then
        local c=getChar(); if c then doFreeze(c) end; return "🧊 Congelado"
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) and p.Character then doFreeze(p.Character) end
    end
    return "🧊 Congelado: "..target
end
function CMD.unfreeze(target)
    local name=tostring(target or "me"):lower()
    local function doUnfreeze(char)
        for _,p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.Anchored=false end) end
        end
    end
    if name=="me" then local c=getChar(); if c then doUnfreeze(c) end; return "✅ Descongelado"
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) and p.Character then doUnfreeze(p.Character) end
    end
    return "✅ Descongelado: "..target
end
function CMD.kill(target)
    local name=tostring(target or ""):lower()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) and p.Character then
            local h2=p.Character:FindFirstChildOfClass("Humanoid")
            if h2 then h2.Health=0 end
        end
    end
    return "💀 Killed: "..target
end
function CMD.seizure(target)
    local name=tostring(target or ""):lower()
    task.spawn(function()
        for i=1,80 do
            for _,p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(name) and p~=LP and p.Character then
                    local r2=p.Character:FindFirstChild("HumanoidRootPart")
                    if r2 then
                        r2.CFrame=r2.CFrame*CFrame.new(
                            math.random(-3,3),math.random(-1,1),math.random(-3,3))
                    end
                end
            end
            task.wait(0.05)
        end
    end)
    return "🌀 Seizure: "..target
end
function CMD.follow(target)
    local name=tostring(target or ""):lower()
    task.spawn(function()
        for i=1,200 do
            local root=getRoot(); if not root then break end
            for _,p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(name) and p.Character then
                    local r2=p.Character:FindFirstChild("HumanoidRootPart")
                    if r2 then root.CFrame=r2.CFrame*CFrame.new(0,0,3) end
                end
            end
            task.wait(0.1)
        end
    end)
    return "🏃 Siguiendo: "..target.." (20s)"
end
function CMD.looptp(target)
    CMD.follow(target); return "🔁 LoopTP: "..target
end
function CMD.spin()
    task.spawn(function()
        for i=1,360 do
            local root=getRoot(); if not root then break end
            root.CFrame=root.CFrame*CFrame.fromEulerAnglesXYZ(0,math.rad(10),0)
            task.wait(0.02)
        end
    end)
    return "🌀 Spin!"
end
function CMD.attach(target)
    local root=getRoot(); if not root then return "❌ Sin personaje" end
    local name=tostring(target or ""):lower()
    task.spawn(function()
        for i=1,300 do
            if not flyOn then break end
            for _,p in ipairs(Players:GetPlayers()) do
                if p.Name:lower():find(name) and p.Character then
                    local r2=p.Character:FindFirstChild("HumanoidRootPart")
                    if r2 then root.CFrame=r2.CFrame*CFrame.new(0,3,0) end
                end
            end
            task.wait(0.05)
        end
    end)
    return "🔗 Attach: "..target.." (necesita fly)"
end
function CMD.particles()
    local c=getChar(); if not c then return "❌" end
    local root=getRoot()
    if root then
        local pe=Instance.new("ParticleEmitter")
        pe.Rate=50; pe.Speed=NumberRange.new(5,15)
        pe.LightEmission=0.8; pe.LightInfluence=0.2
        pe.Color=ColorSequence.new(C.A1,C.A3)
        pe.Parent=root; game:GetService("Debris"):AddItem(pe,4)
    end
    return "✨ Partículas"
end
function CMD.fixcam()
    workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
    return "📷 Cámara arreglada"
end
function CMD.camlock(target)
    local name=tostring(target or ""):lower()
    for _,p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) and p.Character then
            workspace.CurrentCamera.CameraSubject=p.Character:FindFirstChildOfClass("Humanoid") or p.Character
            return "📷 Cámara → "..p.Name
        end
    end
    return "❌ No encontrado"
end
function CMD.explore()
    -- Muestra todos los jugadores en sala
    local lines={"👥 Jugadores en sala:"}
    for _,p in ipairs(Players:GetPlayers()) do
        lines[#lines+1]=" · "..p.Name..(p==LP and " (tú)" or "")
    end
    return table.concat(lines,"\n")
end

-- ─── GUARDAR / IR POSICIONES ──────────────────────────────
function CMD.savepos(name)
    local root=getRoot(); if not root then return "❌ Sin personaje" end
    local p=root.Position
    savedPos[name:lower()]={name=name, x=math.floor(p.X), y=math.floor(p.Y), z=math.floor(p.Z)}
    return "📌 Guardado: \""..name.."\" ("..math.floor(p.X)..","..math.floor(p.Y)..","..math.floor(p.Z)..")"
end
function CMD.tppos(name)
    local entry=savedPos[name:lower()]
    if not entry then
        -- busca parcial
        for k,v in pairs(savedPos) do if k:find(name:lower()) then entry=v; break end end
    end
    if not entry then
        local list={}; for k in pairs(savedPos) do list[#list+1]=k end
        return "❌ No existe \""..name.."\"\nGuardadas: "..( #list>0 and table.concat(list,", ") or "(ninguna)")
    end
    local root=getRoot(); if not root then return "❌ Sin personaje" end
    root.CFrame=CFrame.new(entry.x,entry.y,entry.z)
    return "📍 → \""..entry.name.."\" ("..entry.x..","..entry.y..","..entry.z..")"
end
function CMD.listpos()
    local lines={"📌 Posiciones guardadas:"}
    for k,v in pairs(savedPos) do
        lines[#lines+1]=" · "..v.name.." ("..v.x..","..v.y..","..v.z..")"
    end
    if #lines==1 then return "📌 Sin posiciones guardadas aún" end
    return table.concat(lines,"\n")
end
function CMD.delpos(name)
    savedPos[name:lower()]=nil; return "🗑️ Eliminada: "..name
end

-- ─── PARSER CENTRAL ───────────────────────────────────────
local function runCmd(input)
    if not input or input=="" then return nil end
    local parts={}
    for p in input:gmatch("%S+") do parts[#parts+1]=p end
    local c=parts[1] and parts[1]:lower() or ""
    local a2,a3,a4=parts[2],parts[3],parts[4]

    if c=="fly"        then return CMD.fly(a2)
    elseif c=="unfly" or c=="nofly" then return CMD.unfly()
    elseif c=="noclip" then return CMD.noclip()
    elseif c=="clip"  or c=="collide" then return CMD.clip()
    elseif c=="speed" or c=="ws"      then return CMD.speed(a2)
    elseif c=="jump"  or c=="jp"      then return CMD.jump(a2)
    elseif c=="jumpheight"            then return CMD.jumpheight(a2)
    elseif c=="god"                   then return CMD.god()
    elseif c=="ungod"                 then return CMD.ungod()
    elseif c=="tp"                    then return CMD.tp(a2,a3,a4)
    elseif c=="goto"  or c=="goto_"   then return CMD.goto_(a2)
    elseif c=="bring"                 then return CMD.bring(a2)
    elseif c=="invisible" or c=="invis" then return CMD.invisible()
    elseif c=="visible" or c=="vis"   then return CMD.visible()
    elseif c=="flight"                then return CMD.flight(a2,a3)
    elseif c=="reset"                 then return CMD.reset()
    elseif c=="sit"                   then return CMD.sit()
    elseif c=="unsit"                 then return CMD.unsit()
    elseif c=="chat"                  then return CMD.chat(table.unpack(parts,2))
    elseif c=="time"                  then return CMD.time(a2)
    elseif c=="brightness"            then return CMD.brightness(a2)
    elseif c=="fogend"                then return CMD.fogend(a2)
    elseif c=="fov"                   then return CMD.fov(a2)
    elseif c=="zoom"                  then return CMD.zoom(a2)
    elseif c=="gravity" or c=="grav"  then return CMD.gravity(a2)
    elseif c=="hum"   or c=="maxhealth" then return CMD.hum(a2)
    elseif c=="freeze"                then return CMD.freeze(a2)
    elseif c=="unfreeze"              then return CMD.unfreeze(a2)
    elseif c=="kill"                  then return CMD.kill(a2)
    elseif c=="seizure"               then return CMD.seizure(a2)
    elseif c=="follow"                then return CMD.follow(a2)
    elseif c=="looptp"                then return CMD.looptp(a2)
    elseif c=="spin"                  then return CMD.spin()
    elseif c=="attach"                then return CMD.attach(a2)
    elseif c=="particles"             then return CMD.particles()
    elseif c=="fixcam"                then return CMD.fixcam()
    elseif c=="camlock"               then return CMD.camlock(a2)
    elseif c=="explore" or c=="players" then return CMD.explore()
    elseif c=="savepos" or c=="save"  then return CMD.savepos(a2 or "pos"..os.time())
    elseif c=="tppos"  or c=="warp"   then return CMD.tppos(a2 or "")
    elseif c=="listpos"               then return CMD.listpos()
    elseif c=="delpos"                then return CMD.delpos(a2 or "")
    end
    return "❓ Cmd desconocido: "..c
end

-- ============================================================
--  CONTEXTO DEL JUEGO
-- ============================================================
local gameInfo = { name="", placeId=tostring(game.PlaceId), players=0 }
local function loadGameCtx()
    pcall(function()
        gameInfo.name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    if gameInfo.name=="" then pcall(function() gameInfo.name=game.Name end) end
    gameInfo.players = #Players:GetPlayers()
end

-- ============================================================
--  IA — OpenRouter (meta-llama/llama-3.3-70b-instruct:free)
-- ============================================================
local apiKey    = ""
local aiHistory = {}

local function buildSysPrompt()
    local posLines={}; for k,v in pairs(savedPos) do posLines[#posLines+1]=v.name.."("..v.x..","..v.y..","..v.z..")" end
    local plrs={}; for _,p in ipairs(Players:GetPlayers()) do plrs[#plrs+1]=p.Name end
    return "Eres un asistente de Roblox con acceso a comandos de Infinite Yield. Juegas "..gameInfo.name..
    " (PlaceId:"..gameInfo.placeId.."). Jugadores: "..table.concat(plrs,",")..
    ". Posiciones guardadas: "..( #posLines>0 and table.concat(posLines,"|") or "ninguna")..
    ".\n\nPara ejecutar comandos pon <CMD>comando args</CMD>. Comandos: fly [vel], unfly, noclip, clip, speed [n], jump [n], god, ungod, tp [x y z / nombre], goto [jugador], bring [jugador], invisible, visible, flight [jugador] [power], freeze [me/jugador], unfreeze, kill [jugador], follow [jugador], spin, fov [n], zoom [n], gravity [n], time [0-23], chat [texto], savepos [nombre], tppos [nombre], listpos, explore.\n\nPara GUARDAR posición: <CMD>savepos NOMBRE</CMD>\nPara IR a posición: <CMD>tppos NOMBRE</CMD>\n\nResponde en español. Sé conciso (2-3 oraciones máx + comandos). Si el juego es Conecta Palabras ayuda con estrategias de prefijos y palabras."
end

local function extractCmds(text)
    local cmds={}
    for cmd in text:gmatch("<CMD>(.-)</CMD>") do
        cmds[#cmds+1]=(cmd:match("^%s*(.-)%s*$"))
    end
    return cmds
end

local function cleanText(text)
    return (text:gsub("<CMD>.-</CMD>",""):match("^%s*(.-)%s*$") or "")
end

local function callAI(userMsg, onResult)
    if #apiKey < 8 then
        onResult("⚠️ Sin API Key.\n\nVe a ⚙ y pega tu key de openrouter.ai\n(cuenta gratis, modelo gratuito)")
        return
    end
    -- Construye historial (últimos 6 mensajes para ahorrar tokens)
    local msgs={{ role="system", content=buildSysPrompt() }}
    local start=math.max(1,#aiHistory-5)
    for i=start,#aiHistory do msgs[#msgs+1]=aiHistory[i] end
    msgs[#msgs+1]={ role="user", content=userMsg }

    local payload=jEnc({
        model="meta-llama/llama-3.3-70b-instruct:free",
        max_tokens=350,
        temperature=0.35,
        messages=msgs,
    })
    local hdrs={
        ["Content-Type"]  = "application/json",
        ["Authorization"] = "Bearer "..apiKey,
        ["HTTP-Referer"]  = "https://www.roblox.com",
        ["X-Title"]       = "RobloxIYAssistant",
    }
    task.spawn(function()
        local ok, body = httpPost("https://openrouter.ai/api/v1/chat/completions", hdrs, payload)
        if not ok or not body then
            onResult("❌ Sin conexión.\n• Verifica que Delta tiene HTTP activado\n• Comprueba tu API Key en ⚙")
            return
        end
        local content = parseAI(body)
        if not content or #content < 2 then
            onResult("❌ Respuesta vacía.\nRespuesta raw:\n"..tostring(body):sub(1,120))
            return
        end
        -- Guarda en historial
        aiHistory[#aiHistory+1]={role="user",content=userMsg}
        aiHistory[#aiHistory+1]={role="assistant",content=content}
        if #aiHistory>12 then
            local nh={}; for i=#aiHistory-11,#aiHistory do nh[#nh+1]=aiHistory[i] end; aiHistory=nh
        end
        -- Ejecuta comandos
        local results={}
        for _,cmd in ipairs(extractCmds(content)) do
            local r=runCmd(cmd)
            if r then results[#results+1]=r end
        end
        local clean=cleanText(content)
        if #results>0 then
            clean=(#clean>0 and clean.."\n\n" or "")..table.concat(results,"\n")
        end
        onResult(clean~="" and clean or "✅ Listo")
    end)
end

-- ============================================================
--  MAPEO RÁPIDO (sin llamar IA, ahorra tokens)
-- ============================================================
local QUICK = {
    {p="fly%s*(%d*)",    fn=function(m) return "fly "..m end},
    {p="vuelo?%s*(%d*)", fn=function(m) return "fly "..m end},
    {p="volar%s*(%d*)",  fn=function(m) return "fly "..m end},
    {p="aterrizar",      fn=function() return "unfly" end},
    {p="quitar? vuelo",  fn=function() return "unfly" end},
    {p="noclip",         fn=function() return "noclip" end},
    {p="atravesar",      fn=function() return "noclip" end},
    {p="clip",           fn=function() return "clip" end},
    {p="god mode",       fn=function() return "god" end},
    {p="modo? dios",     fn=function() return "god" end},
    {p="god",            fn=function() return "god" end},
    {p="quitar? god",    fn=function() return "ungod" end},
    {p="invisible",      fn=function() return "invisible" end},
    {p="visible",        fn=function() return "visible" end},
    {p="spin",           fn=function() return "spin" end},
    {p="reset",          fn=function() return "reset" end},
    {p="morir",          fn=function() return "reset" end},
    {p="speed%s+(%d+)",  fn=function(m) return "speed "..m end},
    {p="velocidad%s+(%d+)", fn=function(m) return "speed "..m end},
    {p="jump%s+(%d+)",   fn=function(m) return "jump "..m end},
    {p="salto%s+(%d+)",  fn=function(m) return "jump "..m end},
    {p="gravity%s+(%d+)", fn=function(m) return "gravity "..m end},
    {p="gravedad%s+(%d+)", fn=function(m) return "gravity "..m end},
    {p="fov%s+(%d+)",    fn=function(m) return "fov "..m end},
}

local function tryQuick(msg)
    local ml=msg:lower()
    -- Guardar posición
    local sn = ml:match("guarda.+como%s+['\"]?([%w%s]+)['\"]?$") or
               ml:match("guardar?.+posici[oó]n.+['\"]?([%w]+)['\"]?$") or
               ml:match("^guarda%s+['\"]?([%w%s]+)['\"]?$")
    if sn then sn=sn:match("^%s*(.-)%s*$"); return "savepos "..sn end
    -- Ir a posición
    local tn = ml:match("ve%s+a%s+['\"]?([%w%s]+)['\"]?$") or
               ml:match("tp.+a%s+['\"]?([%w%s]+)['\"]?$") or
               ml:match("ir%s+a%s+['\"]?([%w%s]+)['\"]?$") or
               ml:match("teleport[aá].+['\"]?([%w%s]+)['\"]?$")
    if tn then tn=tn:match("^%s*(.-)%s*$"); return "tppos "..tn end
    -- Otros
    for _,q in ipairs(QUICK) do
        local m=ml:match(q.p)
        if ml:match(q.p) then return q.fn(m or "") end
    end
    return nil
end

-- ============================================================
--  GUI
-- ============================================================
pcall(function() game:GetService("CoreGui"):FindFirstChild("IYCHAT_GUI"):Destroy() end)
pcall(function()
    local pg=LP:FindFirstChild("PlayerGui")
    if pg then local o=pg:FindFirstChild("IYCHAT_GUI"); if o then o:Destroy() end end
end)

local SG=Instance.new("ScreenGui"); SG.Name="IYCHAT_GUI"; SG.ResetOnSpawn=false
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; SG.IgnoreGuiInset=true
if not pcall(function() SG.Parent=game:GetService("CoreGui") end) then
    SG.Parent=LP:WaitForChild("PlayerGui")
end

local W,H=300,500

local Main=Instance.new("Frame"); Main.Name="Main"
Main.Size=UDim2.new(0,W,0,0); Main.Position=UDim2.new(0.5,-W/2,0.5,0)
Main.BackgroundColor3=C.BG; Main.BackgroundTransparency=0.07
Main.BorderSizePixel=0; Main.Active=true; Main.Draggable=true; Main.ClipsDescendants=true
Main.Parent=SG; R(Main,14); S(Main,C.BORDER,1)
G(Main,Color3.fromRGB(12,14,30),Color3.fromRGB(7,8,18),135)

-- Top accent line
local TopL=Instance.new("Frame"); TopL.Size=UDim2.new(1,0,0,2); TopL.BorderSizePixel=0; TopL.ZIndex=5; TopL.Parent=Main; R(TopL,2)
G(TopL,C.A3,C.A2,0)

-- ── BURBUJA ────────────────────────────────────────────────
local Bub=Instance.new("TextButton"); Bub.Size=UDim2.new(0,0,0,0)
Bub.BackgroundColor3=C.A1; Bub.BorderSizePixel=0; Bub.Text="🤖"; Bub.TextColor3=C.TEXT
Bub.TextSize=22; Bub.Font=Enum.Font.Gotham; Bub.AutoButtonColor=false; Bub.Visible=false; Bub.ZIndex=60; Bub.Parent=SG
R(Bub,22); S(Bub,C.A2,2); G(Bub,C.A1,C.A2,45)
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
    local vp=workspace.CurrentCamera.ViewportSize
    Bub.Position=UDim2.new(0,math.clamp(i.Position.X-bOff.X,0,vp.X-44),0,math.clamp(i.Position.Y-bOff.Y,0,vp.Y-44))
end)
local function doMin()
    TW(Main,{Size=UDim2.new(0,W,0,0)},0.18); task.delay(0.2,function()
        Main.Visible=false; local vp=workspace.CurrentCamera.ViewportSize
        Bub.Size=UDim2.new(0,0,0,0); Bub.Position=UDim2.new(0,vp.X-52,0,90); Bub.Visible=true
        TW(Bub,{Size=UDim2.new(0,44,0,44)},0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    end)
end
local function doRes()
    Bub.Visible=false; Main.Visible=true
    TW(Main,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
end
Bub.MouseButton1Click:Connect(doRes); Bub.TouchTap:Connect(doRes)

-- ── HEADER ─────────────────────────────────────────────────
local Hdr=Instance.new("Frame"); Hdr.Size=UDim2.new(1,0,0,44)
Hdr.BackgroundColor3=C.GLASS; Hdr.BackgroundTransparency=0.1; Hdr.BorderSizePixel=0; Hdr.Parent=Main; R(Hdr,14)
local HF=Instance.new("Frame"); HF.Size=UDim2.new(1,0,0,14); HF.Position=UDim2.new(0,0,1,-14)
HF.BackgroundColor3=C.GLASS; HF.BackgroundTransparency=0.1; HF.BorderSizePixel=0; HF.Parent=Hdr
LBL(Hdr,"🤖",18,C.A1,Enum.Font.Gotham,Enum.TextXAlignment.Center).Size=UDim2.new(0,34,1,0)
local HTitle=LBL(Hdr,"IY ASISTENTE",12,C.TEXT,Enum.Font.GothamBold)
HTitle.Size=UDim2.new(1,-110,0,18); HTitle.Position=UDim2.new(0,38,0,4)
local HGame=LBL(Hdr,"Cargando...",9,C.TEXTD,Enum.Font.Gotham)
HGame.Size=UDim2.new(1,-110,0,14); HGame.Position=UDim2.new(0,38,0,23)
local BSet=BTN(Hdr,"⚙",UDim2.new(0,26,0,24),Color3.fromRGB(20,26,50),C.TEXTD,13)
BSet.Position=UDim2.new(1,-57,0.5,-12); BSet.ZIndex=4
local BMin=BTN(Hdr,"—",UDim2.new(0,26,0,24),Color3.fromRGB(18,35,62),C.A1,12)
BMin.Position=UDim2.new(1,-28,0.5,-12); BMin.ZIndex=4
BMin.MouseButton1Click:Connect(doMin); BMin.TouchTap:Connect(doMin)

-- ── TABS ───────────────────────────────────────────────────
local TabF=Instance.new("Frame"); TabF.Size=UDim2.new(1,-10,0,24); TabF.Position=UDim2.new(0,5,0,48)
TabF.BackgroundColor3=C.GLASS; TabF.BackgroundTransparency=0.2; TabF.BorderSizePixel=0; TabF.Parent=Main; R(TabF,7)
local T1=BTN(TabF,"💬 Chat",UDim2.new(0.34,-2,1,-4),C.A1,C.TEXT,9); T1.Position=UDim2.new(0,2,0,2); R(T1,5)
local T2=BTN(TabF,"⚡ Cmds",UDim2.new(0.33,-1,1,-4),Color3.fromRGB(18,22,44),C.TEXTD,9); T2.Position=UDim2.new(0.34,1,0,2); R(T2,5)
local T3=BTN(TabF,"📌 Posiciones",UDim2.new(0.33,-1,1,-4),Color3.fromRGB(18,22,44),C.TEXTD,9); T3.Position=UDim2.new(0.67,0,0,2); R(T3,5)

-- ── PANEL CHAT ─────────────────────────────────────────────
local ChatP=Instance.new("Frame"); ChatP.Size=UDim2.new(1,-10,1,-130); ChatP.Position=UDim2.new(0,5,0,76)
ChatP.BackgroundTransparency=1; ChatP.Parent=Main

local MsgScroll=Instance.new("ScrollingFrame"); MsgScroll.Size=UDim2.new(1,0,1,-40)
MsgScroll.BackgroundColor3=C.GLASS; MsgScroll.BackgroundTransparency=0.12; MsgScroll.BorderSizePixel=0
MsgScroll.ScrollBarThickness=3; MsgScroll.ScrollBarImageColor3=C.SCROLL
MsgScroll.CanvasSize=UDim2.new(0,0,0,0); MsgScroll.ScrollingDirection=Enum.ScrollingDirection.Y; MsgScroll.Parent=ChatP
R(MsgScroll,10); S(MsgScroll,C.BORDER,1)
local ML=Instance.new("UIListLayout"); ML.SortOrder=Enum.SortOrder.LayoutOrder; ML.Padding=UDim.new(0,5); ML.Parent=MsgScroll
local MP=Instance.new("UIPadding"); MP.PaddingTop=UDim.new(0,5); MP.PaddingLeft=UDim.new(0,4); MP.PaddingRight=UDim.new(0,4); MP.PaddingBottom=UDim.new(0,4); MP.Parent=MsgScroll

local IBar=Instance.new("Frame"); IBar.Size=UDim2.new(1,0,0,36); IBar.Position=UDim2.new(0,0,1,-36)
IBar.BackgroundColor3=C.GLASS2; IBar.BackgroundTransparency=0.1; IBar.BorderSizePixel=0; IBar.Parent=ChatP
R(IBar,9); S(IBar,C.BORDER,1)
local MBox=Instance.new("TextBox"); MBox.Size=UDim2.new(1,-46,1,-10); MBox.Position=UDim2.new(0,7,0,5)
MBox.BackgroundTransparency=1; MBox.PlaceholderText="activa fly · guarda como base1 · ve a base1..."
MBox.PlaceholderColor3=C.TEXTM; MBox.Text=""; MBox.TextColor3=C.TEXT
MBox.TextSize=12; MBox.Font=Enum.Font.Gotham; MBox.ClearTextOnFocus=false; MBox.TextXAlignment=Enum.TextXAlignment.Left; MBox.Parent=IBar
local SendBtn=BTN(IBar,"➤",UDim2.new(0,34,0,26),C.A1,C.TEXT,13); SendBtn.Position=UDim2.new(1,-38,0.5,-13)

-- ── PANEL COMANDOS (Tab 2) ─────────────────────────────────
local CmdP=Instance.new("Frame"); CmdP.Size=UDim2.new(1,-10,1,-130); CmdP.Position=UDim2.new(0,5,0,76)
CmdP.BackgroundTransparency=1; CmdP.Visible=false; CmdP.Parent=Main

local CmdScroll=Instance.new("ScrollingFrame"); CmdScroll.Size=UDim2.new(1,0,1,0)
CmdScroll.BackgroundColor3=C.GLASS; CmdScroll.BackgroundTransparency=0.12; CmdScroll.BorderSizePixel=0
CmdScroll.ScrollBarThickness=3; CmdScroll.ScrollBarImageColor3=C.SCROLL; CmdScroll.CanvasSize=UDim2.new(0,0,0,0); CmdScroll.Parent=CmdP
R(CmdScroll,10); S(CmdScroll,C.BORDER,1)
local CL=Instance.new("UIListLayout"); CL.SortOrder=Enum.SortOrder.LayoutOrder; CL.Padding=UDim.new(0,4); CL.Parent=CmdScroll
local CPad=Instance.new("UIPadding"); CPad.PaddingTop=UDim.new(0,5); CPad.PaddingLeft=UDim.new(0,5); CPad.PaddingRight=UDim.new(0,5); CPad.Parent=CmdScroll

-- ── PANEL POSICIONES (Tab 3) ───────────────────────────────
local PosP=Instance.new("Frame"); PosP.Size=UDim2.new(1,-10,1,-130); PosP.Position=UDim2.new(0,5,0,76)
PosP.BackgroundTransparency=1; PosP.Visible=false; PosP.Parent=Main

local PosScroll=Instance.new("ScrollingFrame"); PosScroll.Size=UDim2.new(1,0,1,-36)
PosScroll.BackgroundColor3=C.GLASS; PosScroll.BackgroundTransparency=0.12; PosScroll.BorderSizePixel=0
PosScroll.ScrollBarThickness=3; PosScroll.ScrollBarImageColor3=C.SCROLL; PosScroll.CanvasSize=UDim2.new(0,0,0,0); PosScroll.Parent=PosP
R(PosScroll,9); S(PosScroll,C.BORDER,1)
local PL=Instance.new("UIListLayout"); PL.SortOrder=Enum.SortOrder.LayoutOrder; PL.Padding=UDim.new(0,3); PL.Parent=PosScroll
local PP=Instance.new("UIPadding"); PP.PaddingTop=UDim.new(0,4); PP.PaddingLeft=UDim.new(0,4); PP.PaddingRight=UDim.new(0,4); PP.Parent=PosScroll

local SaveNow=BTN(PosP,"📌 Guardar posición actual",UDim2.new(1,0,0,30),Color3.fromRGB(12,26,56),C.A1,10)
SaveNow.Position=UDim2.new(0,0,1,-32)
local PosEmpty=LBL(PosP,"Sin posiciones\n\nEscríbele a la IA:\n\"guarda como camino1\"",10,C.TEXTM,Enum.Font.Gotham,Enum.TextXAlignment.Center)
PosEmpty.Size=UDim2.new(1,0,0,70); PosEmpty.Position=UDim2.new(0,0,0.25,0); PosEmpty.TextWrapped=true

-- Input nombre posición
local PosIF=Instance.new("Frame"); PosIF.Size=UDim2.new(1,0,0,28); PosIF.Position=UDim2.new(0,0,1,-62)
PosIF.BackgroundColor3=C.GLASS2; PosIF.BackgroundTransparency=0.1; PosIF.BorderSizePixel=0; PosIF.Visible=false; PosIF.Parent=PosP
R(PosIF,8); S(PosIF,C.BORDER,1)
local PosNB=Instance.new("TextBox"); PosNB.Size=UDim2.new(1,-46,1,-6); PosNB.Position=UDim2.new(0,5,0,3)
PosNB.BackgroundTransparency=1; PosNB.PlaceholderText="Nombre (ej: camino1, base...)"
PosNB.PlaceholderColor3=C.TEXTM; PosNB.Text=""; PosNB.TextColor3=C.TEXT
PosNB.TextSize=12; PosNB.Font=Enum.Font.Gotham; PosNB.ClearTextOnFocus=false; PosNB.TextXAlignment=Enum.TextXAlignment.Left; PosNB.Parent=PosIF
local PosOK=BTN(PosIF,"✓",UDim2.new(0,38,0,22),C.GREEN,C.TEXT,13); PosOK.Position=UDim2.new(1,-42,0.5,-11)

-- ── SETTINGS ───────────────────────────────────────────────
local SetP=Instance.new("Frame"); SetP.Size=UDim2.new(1,0,1,0)
SetP.BackgroundColor3=Color3.fromRGB(7,9,20); SetP.BackgroundTransparency=0.04
SetP.BorderSizePixel=0; SetP.Visible=false; SetP.ZIndex=20; SetP.Parent=Main; R(SetP,14); S(SetP,C.BORDER,1)
LBL(SetP,"⚙  Configuración IA",14,C.TEXT,Enum.Font.GothamBold,Enum.TextXAlignment.Center).Size=UDim2.new(1,0,0,38)
local KF=Instance.new("Frame"); KF.Size=UDim2.new(1,-20,0,36); KF.Position=UDim2.new(0,10,0,44)
KF.BackgroundColor3=C.GLASS2; KF.BackgroundTransparency=0.1; KF.BorderSizePixel=0; KF.Parent=SetP; R(KF,9); S(KF,C.BORDER,1)
local KBox=Instance.new("TextBox"); KBox.Size=UDim2.new(1,-10,1,-8); KBox.Position=UDim2.new(0,5,0,4)
KBox.BackgroundTransparency=1; KBox.PlaceholderText="sk-or-v1-... (API Key OpenRouter)"
KBox.PlaceholderColor3=C.TEXTM; KBox.Text=""; KBox.TextColor3=C.TEXT
KBox.TextSize=11; KBox.Font=Enum.Font.Gotham; KBox.ClearTextOnFocus=false; KBox.TextXAlignment=Enum.TextXAlignment.Left; KBox.ZIndex=21; KBox.Parent=KF
local KStat=LBL(SetP,"Sin API Key — la IA no estará disponible",10,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
KStat.Size=UDim2.new(1,-20,0,14); KStat.Position=UDim2.new(0,10,0,84); KStat.ZIndex=21
local KSave=BTN(SetP,"✓ Guardar Key",UDim2.new(0.45,0,0,32),C.A1,C.TEXT,11); KSave.Position=UDim2.new(0.04,0,0,102); KSave.ZIndex=21
local KClose=BTN(SetP,"✕ Cerrar",UDim2.new(0.45,0,0,32),Color3.fromRGB(36,16,18),C.RED,11); KClose.Position=UDim2.new(0.52,0,0,102); KClose.ZIndex=21
local KInfo=LBL(SetP,"openrouter.ai → cuenta gratis → API Keys\nModelo: meta-llama/llama-3.3-70b-instruct:free\n\n💡 Comandos básicos funcionan sin key.\nLa IA activa para frases complejas.",9,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Center)
KInfo.Size=UDim2.new(1,-20,0,70); KInfo.Position=UDim2.new(0,10,0,140); KInfo.TextWrapped=true; KInfo.ZIndex=21
local function saveKey()
    local k=(KBox.Text or ""):match("^%s*(.-)%s*$") or ""; apiKey=k
    if #k>8 then KStat.Text="✓ Key guardada — IA activada"; KStat.TextColor3=C.GREEN
    else KStat.Text="⚠ Key inválida — IA no disponible"; KStat.TextColor3=C.ORANGE end
    task.delay(1.5,function() SetP.Visible=false end)
end
KSave.MouseButton1Click:Connect(saveKey); KSave.TouchTap:Connect(saveKey)
KClose.MouseButton1Click:Connect(function() SetP.Visible=false end); KClose.TouchTap:Connect(function() SetP.Visible=false end)
BSet.MouseButton1Click:Connect(function() KBox.Text=apiKey; SetP.Visible=true end)
BSet.TouchTap:Connect(function() KBox.Text=apiKey; SetP.Visible=true end)

-- ── RESIZE HANDLE ──────────────────────────────────────────
local Handle=Instance.new("Frame"); Handle.Size=UDim2.new(1,0,0,10)
Handle.Position=UDim2.new(0,0,1,-10); Handle.BackgroundColor3=C.GLASS2
Handle.BackgroundTransparency=0.35; Handle.BorderSizePixel=0; Handle.Active=true; Handle.ZIndex=10; Handle.Parent=Main; R(Handle,5)
local HL=Instance.new("Frame"); HL.Size=UDim2.new(0,28,0,3); HL.Position=UDim2.new(0.5,-14,0.5,-1)
HL.BackgroundColor3=C.A1; HL.BackgroundTransparency=0.5; HL.BorderSizePixel=0; HL.ZIndex=11; HL.Parent=Handle; R(HL,2)
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
    Main.Size=UDim2.new(0,W,0,nh)
    local ch=nh-130; ch=math.max(ch,120)
    ChatP.Size=UDim2.new(1,-10,0,ch); CmdP.Size=UDim2.new(1,-10,0,ch); PosP.Size=UDim2.new(1,-10,0,ch)
end)

-- ============================================================
--  CHAT — añadir burbujas
-- ============================================================
local msgOrder=0
local function addMsg(who, text, isUser, isSys)
    msgOrder=msgOrder+1
    local bub=Instance.new("Frame"); bub.Size=UDim2.new(1,0,0,10)
    bub.BackgroundColor3=isSys and C.SYS_BG or (isUser and C.USER_BG or C.AI_BG)
    bub.BackgroundTransparency=0.1; bub.BorderSizePixel=0; bub.LayoutOrder=msgOrder
    bub.AutomaticSize=Enum.AutomaticSize.Y; bub.Parent=MsgScroll; R(bub,8)
    S(bub, isUser and Color3.fromRGB(50,80,160) or (isSys and Color3.fromRGB(40,55,120) or Color3.fromRGB(35,45,100)), 1)
    local wl=LBL(bub, isSys and "⚡" or (isUser and "👤 "..LP.Name or "🤖 IA"), 8,
        isUser and C.A1 or (isSys and C.YELLOW or C.A2), Enum.Font.GothamBold)
    wl.Size=UDim2.new(1,-10,0,13); wl.Position=UDim2.new(0,6,0,3)
    local ml=Instance.new("TextLabel"); ml.BackgroundTransparency=1
    ml.Size=UDim2.new(1,-12,0,0); ml.Position=UDim2.new(0,6,0,18)
    ml.Text=text; ml.TextSize=11; ml.Font=Enum.Font.Gotham; ml.TextColor3=C.TEXT
    ml.TextWrapped=true; ml.TextXAlignment=Enum.TextXAlignment.Left
    ml.TextYAlignment=Enum.TextYAlignment.Top; ml.AutomaticSize=Enum.AutomaticSize.Y; ml.Parent=bub
    task.wait(); task.wait()
    local tot=0; for _,c in ipairs(MsgScroll:GetChildren()) do if c:IsA("Frame") then tot=tot+c.AbsoluteSize.Y+7 end end
    MsgScroll.CanvasSize=UDim2.new(0,0,0,tot+12)
    MsgScroll.CanvasPosition=Vector2.new(0,math.max(0,tot-MsgScroll.AbsoluteSize.Y+12))
    return ml
end

-- ============================================================
--  TABS
-- ============================================================
local curTab=1
local function setTab(t)
    curTab=t; ChatP.Visible=(t==1); CmdP.Visible=(t==2); PosP.Visible=(t==3)
    local cols={C.A1,C.ORANGE,C.GREEN}; local tabs={T1,T2,T3}
    for i,tb in ipairs(tabs) do
        if i==t then TW(tb,{BackgroundColor3=cols[i]},0.12); tb.TextColor3=Color3.fromRGB(0,0,0)
        else TW(tb,{BackgroundColor3=Color3.fromRGB(18,22,44)},0.12); tb.TextColor3=C.TEXTD end
    end
end
T1.MouseButton1Click:Connect(function() setTab(1) end); T1.TouchTap:Connect(function() setTab(1) end)
T2.MouseButton1Click:Connect(function() setTab(2) end); T2.TouchTap:Connect(function() setTab(2) end)
T3.MouseButton1Click:Connect(function() setTab(3) end); T3.TouchTap:Connect(function() setTab(3) end)

-- ============================================================
--  PANEL COMANDOS — botones + slider de velocidad
-- ============================================================
local sliderConn=nil

local function makeSlider(parent, label, minV, maxV, initV, color, onChange)
    -- Frame contenedor
    local fr=Instance.new("Frame"); fr.Size=UDim2.new(1,0,0,44)
    fr.BackgroundColor3=C.GLASS2; fr.BackgroundTransparency=0.1; fr.BorderSizePixel=0; fr.Parent=parent; R(fr,7)
    -- Etiqueta
    local lbl=LBL(fr,label,9,C.TEXTD,Enum.Font.Gotham); lbl.Size=UDim2.new(0.6,0,0,14); lbl.Position=UDim2.new(0,6,0,3)
    local valLbl=LBL(fr,tostring(initV),10,color,Enum.Font.GothamBold,Enum.TextXAlignment.Right)
    valLbl.Size=UDim2.new(0.38,0,0,14); valLbl.Position=UDim2.new(0.62,-4,0,3)
    -- Track
    local track=Instance.new("Frame"); track.Size=UDim2.new(1,-12,0,6); track.Position=UDim2.new(0,6,0,24)
    track.BackgroundColor3=Color3.fromRGB(24,28,55); track.BorderSizePixel=0; track.Active=true; track.Parent=fr; R(track,4)
    -- Fill
    local fill=Instance.new("Frame"); fill.Size=UDim2.new((initV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3=color; fill.BorderSizePixel=0; fill.Parent=track; R(fill,4)
    -- Thumb
    local thumb=Instance.new("Frame"); thumb.Size=UDim2.new(0,14,0,14)
    thumb.Position=UDim2.new(fill.Size.X.Scale,0,0.5,-7)
    thumb.BackgroundColor3=C.TEXT; thumb.BorderSizePixel=0; thumb.Active=true; thumb.ZIndex=3; thumb.Parent=track; R(thumb,7)

    local dragging=false
    local function updateSlider(absX)
        local rel=math.clamp((absX-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(minV+(maxV-minV)*rel)
        fill.Size=UDim2.new(rel,0,1,0)
        thumb.Position=UDim2.new(rel,-7,0.5,-7)
        valLbl.Text=tostring(val)
        onChange(val)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; updateSlider(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function() dragging=false end)
    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            updateSlider(i.Position.X)
        end
    end)
    return fr, valLbl
end

local function makeCmdBtn(parent, icon, label, onRun, color, order)
    local fr=Instance.new("Frame"); fr.Size=UDim2.new(1,0,0,34)
    fr.BackgroundColor3=color or C.GLASS2; fr.BackgroundTransparency=0.15
    fr.BorderSizePixel=0; fr.LayoutOrder=order or 99; fr.Parent=parent; R(fr,7)
    local il=LBL(fr,icon.." "..label,11,C.TEXT,Enum.Font.GothamBold)
    il.Size=UDim2.new(1,-46,1,0); il.Position=UDim2.new(0,8,0,0)
    local rb=BTN(fr,"▶",UDim2.new(0,32,0,24),C.A1,C.TEXT,12); rb.Position=UDim2.new(1,-36,0.5,-12)
    local function run() local r=onRun(); if r then addMsg("sys",r,false,true); setTab(1) end end
    rb.MouseButton1Click:Connect(run); rb.TouchTap:Connect(run)
    return fr
end

local function buildCmdPanel()
    for _,c in ipairs(CmdScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

    local order=0
    local function o() order=order+1; return order end

    -- CATEGORÍA: MOVIMIENTO
    local cat1=Instance.new("Frame"); cat1.Size=UDim2.new(1,0,0,16); cat1.BackgroundTransparency=1; cat1.LayoutOrder=o(); cat1.Parent=CmdScroll
    LBL(cat1,"✈️  MOVIMIENTO",8,C.A3,Enum.Font.GothamBold).Size=UDim2.new(1,0,1,0)

    -- Fly toggle + slider
    local flyFr=Instance.new("Frame"); flyFr.Size=UDim2.new(1,0,0,78)
    flyFr.BackgroundColor3=Color3.fromRGB(14,26,60); flyFr.BackgroundTransparency=0.1
    flyFr.BorderSizePixel=0; flyFr.LayoutOrder=o(); flyFr.Parent=CmdScroll; R(flyFr,8)

    local flyRow=Instance.new("Frame"); flyRow.Size=UDim2.new(1,0,0,32); flyRow.BackgroundTransparency=1; flyRow.Parent=flyFr
    LBL(flyRow,"✈️  Fly",12,C.A1,Enum.Font.GothamBold).Size=UDim2.new(0.5,0,1,0); (function() local l=flyRow:GetChildren()[1]; l.Position=UDim2.new(0,8,0,0) end)()
    local flyToggle=BTN(flyRow,"▶ ON",UDim2.new(0,52,0,24),C.GREEN,C.TEXT,10); flyToggle.Position=UDim2.new(1,-58,0.5,-12)
    local flySpeedLbl=LBL(flyRow,"",9,C.TEXTD,Enum.Font.Gotham,Enum.TextXAlignment.Right)
    flySpeedLbl.Size=UDim2.new(0.35,0,0,14); flySpeedLbl.Position=UDim2.new(0.45,0,0,0)
    flySpeedLbl.TextYAlignment=Enum.TextYAlignment.Center

    -- Slider de velocidad de fly
    local slFr,slVal=makeSlider(flyFr,"Velocidad (0–300)",0,300,60,C.A1,function(v)
        flySpeed=v
        if flyOn then CMD.fly(v) end  -- actualiza en tiempo real
    end)
    slFr.Position=UDim2.new(0,0,0,32); slFr.Parent=flyFr
    slFr.BackgroundTransparency=1
    -- Quita el frame extra del slider
    slFr.Size=UDim2.new(1,0,0,44)

    local function toggleFly()
        if flyOn then
            CMD.unfly(); flyOn=false
            flyToggle.Text="▶ ON"; toggleStyle(flyToggle,false,C.GREEN,Color3.fromRGB(24,40,24))
        else
            CMD.fly(flySpeed); flyOn=true
            flyToggle.Text="⏹ OFF"; toggleStyle(flyToggle,true,C.RED)
        end
    end
    flyToggle.MouseButton1Click:Connect(toggleFly); flyToggle.TouchTap:Connect(toggleFly)

    makeCmdBtn(CmdScroll,"👻","Noclip",function()
        if noclipOn then return CMD.clip() else return CMD.noclip() end
    end, Color3.fromRGB(30,14,50), o())

    -- Speed slider
    local ssFr,ssVal=makeSlider(CmdScroll,"⚡ Speed (0–200)",0,200,16,C.ORANGE,function(v)
        speedVal=v; CMD.speed(v)
    end)
    ssFr.LayoutOrder=o(); ssFr.Parent=CmdScroll

    -- Jump slider
    local jsFr,jsVal=makeSlider(CmdScroll,"🦘 Jump Power (0–300)",0,300,50,C.YELLOW,function(v)
        jumpVal=v; CMD.jump(v)
    end)
    jsFr.LayoutOrder=o(); jsFr.Parent=CmdScroll

    -- Gravity slider
    local gravFr,gravVal=makeSlider(CmdScroll,"🌍 Gravity (0–500)",0,500,196,C.A3,function(v)
        CMD.gravity(v)
    end)
    gravFr.LayoutOrder=o(); gravFr.Parent=CmdScroll

    -- CATEGORÍA: COMBATE
    local cat2=Instance.new("Frame"); cat2.Size=UDim2.new(1,0,0,16); cat2.BackgroundTransparency=1; cat2.LayoutOrder=o(); cat2.Parent=CmdScroll
    LBL(cat2,"🛡️  COMBATE & ESTADO",8,C.ORANGE,Enum.Font.GothamBold).Size=UDim2.new(1,0,1,0)

    makeCmdBtn(CmdScroll,"🛡️","God Mode",function()
        if godOn then godOn=false; return CMD.ungod() else return CMD.god() end
    end, Color3.fromRGB(14,36,22), o())

    makeCmdBtn(CmdScroll,"💀","Reset",CMD.reset, Color3.fromRGB(40,10,10), o())
    makeCmdBtn(CmdScroll,"🔄","Spin",CMD.spin, Color3.fromRGB(24,20,50), o())

    -- CATEGORÍA: APARIENCIA
    local cat3=Instance.new("Frame"); cat3.Size=UDim2.new(1,0,0,16); cat3.BackgroundTransparency=1; cat3.LayoutOrder=o(); cat3.Parent=CmdScroll
    LBL(cat3,"👁️  APARIENCIA",8,C.A1,Enum.Font.GothamBold).Size=UDim2.new(1,0,1,0)

    makeCmdBtn(CmdScroll,"👁️","Invisible",function()
        return CMD.invisible()
    end, Color3.fromRGB(18,18,40), o())
    makeCmdBtn(CmdScroll,"👀","Visible",CMD.visible, Color3.fromRGB(18,32,18), o())
    makeCmdBtn(CmdScroll,"✨","Partículas",CMD.particles, Color3.fromRGB(22,18,42), o())

    -- CATEGORÍA: MUNDO
    local cat4=Instance.new("Frame"); cat4.Size=UDim2.new(1,0,0,16); cat4.BackgroundTransparency=1; cat4.LayoutOrder=o(); cat4.Parent=CmdScroll
    LBL(cat4,"🌍  MUNDO",8,C.GREEN,Enum.Font.GothamBold).Size=UDim2.new(1,0,1,0)

    -- FOV slider
    local fovFr,fovVal=makeSlider(CmdScroll,"🎥 FOV (30–120)",30,120,70,C.GREEN,function(v)
        CMD.fov(v)
    end)
    fovFr.LayoutOrder=o(); fovFr.Parent=CmdScroll

    -- Time slider
    local timeFr,timeVal=makeSlider(CmdScroll,"🕐 Hora (0–23)",0,23,14,C.YELLOW,function(v)
        CMD.time(v)
    end)
    timeFr.LayoutOrder=o(); timeFr.Parent=CmdScroll

    makeCmdBtn(CmdScroll,"📷","Arreglar cámara",CMD.fixcam, Color3.fromRGB(20,20,40), o())
    makeCmdBtn(CmdScroll,"👥","Ver jugadores",CMD.explore, Color3.fromRGB(16,28,50), o())

    -- CATEGORÍA: FLIGHT (lanzar)
    local cat5=Instance.new("Frame"); cat5.Size=UDim2.new(1,0,0,16); cat5.BackgroundTransparency=1; cat5.LayoutOrder=o(); cat5.Parent=CmdScroll
    LBL(cat5,"🚀  FLIGHT (lanza jugadores)",8,C.RED,Enum.Font.GothamBold).Size=UDim2.new(1,0,1,0)

    makeCmdBtn(CmdScroll,"🚀","Flight a TODOS",function()
        return CMD.flight("all",150)
    end, Color3.fromRGB(40,12,12), o())
    makeCmdBtn(CmdScroll,"🌀","Freeze todos",function()
        for _,p in ipairs(Players:GetPlayers()) do
            if p~=LP and p.Character then CMD.freeze(p.Name) end
        end; return "🧊 Todos congelados"
    end, Color3.fromRGB(10,20,40), o())

    -- Calcula canvas
    task.wait(); local h=0
    for _,c in ipairs(CmdScroll:GetChildren()) do if c:IsA("Frame") then h=h+c.AbsoluteSize.Y+4 end end
    CmdScroll.CanvasSize=UDim2.new(0,0,0,h+10)
end

-- ============================================================
--  PANEL POSICIONES
-- ============================================================
local posConns={}
local function renderPos()
    for _,c in ipairs(PosScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _,c in ipairs(posConns) do pcall(function() c:Disconnect() end) end; posConns={}
    local list={}; for k,v in pairs(savedPos) do list[#list+1]=v end
    table.sort(list,function(a,b) return a.name<b.name end)
    PosEmpty.Visible=(#list==0)
    for i,v in ipairs(list) do
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,40)
        row.BackgroundColor3=C.GLASS2; row.BackgroundTransparency=0.1; row.BorderSizePixel=0
        row.LayoutOrder=i; row.Parent=PosScroll; R(row,7); S(row,C.BORDER,1)
        local nl=LBL(row,"📌 "..v.name,11,C.A1,Enum.Font.GothamBold); nl.Size=UDim2.new(1,-80,0,16); nl.Position=UDim2.new(0,7,0,2)
        local cl=LBL(row,"("..v.x..","..v.y..","..v.z..")",8,C.TEXTD,Enum.Font.Gotham); cl.Size=UDim2.new(1,-80,0,14); cl.Position=UDim2.new(0,7,0,20)
        local tb=BTN(row,"📍",UDim2.new(0,28,0,28),Color3.fromRGB(12,26,55),C.A1,12); tb.Position=UDim2.new(1,-62,0.5,-14)
        local db=BTN(row,"🗑",UDim2.new(0,28,0,28),Color3.fromRGB(38,10,10),C.RED,11); db.Position=UDim2.new(1,-30,0.5,-14)
        local function doTP() local r=CMD.tppos(v.name); addMsg("sys",r,false,true); setTab(1) end
        local function doDel() savedPos[v.name:lower()]=nil; renderPos() end
        posConns[#posConns+1]=tb.MouseButton1Click:Connect(doTP); posConns[#posConns+1]=tb.TouchTap:Connect(doTP)
        posConns[#posConns+1]=db.MouseButton1Click:Connect(doDel); posConns[#posConns+1]=db.TouchTap:Connect(doDel)
    end
    PosScroll.CanvasSize=UDim2.new(0,0,0,#list*44+10)
end

-- Guardar posición manual
local askName=false
SaveNow.MouseButton1Click:Connect(function()
    askName=not askName; PosIF.Visible=askName
    SaveNow.Text=askName and "❌ Cancelar" or "📌 Guardar posición actual"
    if askName then pcall(function() PosNB:CaptureFocus() end) end
end)
SaveNow.TouchTap:Connect(function()
    askName=not askName; PosIF.Visible=askName
    SaveNow.Text=askName and "❌ Cancelar" or "📌 Guardar posición actual"
end)
local function doSavePos()
    local name=(PosNB.Text or ""):match("^%s*(.-)%s*$") or ""
    if #name==0 then return end
    local r=CMD.savepos(name); addMsg("sys",r,false,true)
    renderPos(); PosNB.Text=""; askName=false; PosIF.Visible=false
    SaveNow.Text="📌 Guardar posición actual"
end
PosOK.MouseButton1Click:Connect(doSavePos); PosOK.TouchTap:Connect(doSavePos)
PosNB.FocusLost:Connect(function(e) if e then doSavePos() end end)

-- ============================================================
--  ENVIAR MENSAJE CHAT
-- ============================================================
local aiLoading=false

local function sendMsg()
    if aiLoading then return end
    local msg=(MBox.Text or ""):match("^%s*(.-)%s*$") or ""
    if #msg=="" then return end
    MBox.Text=""
    addMsg(LP.Name, msg, true, false)

    -- 1. Intenta comando directo
    local directCmd=tryQuick(msg)
    if directCmd then
        local r=runCmd(directCmd)
        if r then addMsg("ia",r,false,false) end
        renderPos()
        return
    end

    -- 2. Llama a la IA
    aiLoading=true
    SendBtn.Text="⏳"; TW(SendBtn,{BackgroundColor3=C.TEXTM},0.1)
    local think=addMsg("ia","✦ Pensando...",false,false)
    callAI(msg, function(resp)
        aiLoading=false; SendBtn.Text="➤"; TW(SendBtn,{BackgroundColor3=C.A1},0.1)
        if think and think.Parent then think.Text=resp end
        renderPos()
    end)
end
SendBtn.MouseButton1Click:Connect(sendMsg); SendBtn.TouchTap:Connect(sendMsg)
MBox.FocusLost:Connect(function(e) if e then sendMsg() end end)

-- ============================================================
--  ARRANQUE
-- ============================================================
setTab(1)
buildCmdPanel()
renderPos()

TW(Main,{Size=UDim2.new(0,W,0,H),Position=UDim2.new(0.5,-W/2,0.5,-H/2)},
    0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out)

task.spawn(function()
    loadGameCtx()
    HGame.Text=(gameInfo.name~="" and gameInfo.name or "Roblox").." · "..gameInfo.players.."p"
    task.wait(0.4)
    addMsg("ia",
        "¡Hola! Soy tu asistente IY 🤖\n\n"..
        "Juego: "..(gameInfo.name~="" and gameInfo.name or "detectando...").." · "..gameInfo.players.." jugadores\n\n"..
        "Sin API Key los comandos básicos funcionan igual:\n"..
        "• \"activa el fly\" / \"vuelo\"\n"..
        "• \"guarda como camino1\"\n"..
        "• \"ve a camino1\"\n"..
        "• \"noclip\" / \"god\" / \"invisible\"\n\n"..
        "Con API Key (⚙) la IA entiende cualquier frase y ejecuta comandos complejos.",
        false,false)
end)
