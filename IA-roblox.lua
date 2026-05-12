-- Kaelen Hub v4.0 -- IY Complete Edition
-- Every Infinite Yield command ported to premium iOS GUI
-- Mobile ready | Delta compatible | No UIGridLayout | No AutomaticCanvasSize

-- ============================================================
-- SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local Debris           = game:GetService("Debris")
local SoundService     = game:GetService("SoundService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Cam   = workspace.CurrentCamera

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    BG=Color3.fromRGB(8,8,16), Panel=Color3.fromRGB(14,14,26),
    Card=Color3.fromRGB(22,22,38), Accent=Color3.fromRGB(110,72,255),
    Pink=Color3.fromRGB(255,72,172), Green=Color3.fromRGB(72,255,150),
    Red=Color3.fromRGB(255,72,72), Orange=Color3.fromRGB(255,152,50),
    Yellow=Color3.fromRGB(255,220,50), Teal=Color3.fromRGB(50,220,200),
    Blue=Color3.fromRGB(72,170,255), Text=Color3.fromRGB(238,238,255),
    Dim=Color3.fromRGB(130,130,170), Off=Color3.fromRGB(45,45,68),
    White=Color3.new(1,1,1), Border=Color3.fromRGB(45,45,75),
    Purple=Color3.fromRGB(180,80,255),
}

-- ============================================================
-- IY STATE VARIABLES (exact from IY source)
-- ============================================================
local flinging        = false
local flingDied       = nil
local walkflinging    = false
local walkflingConn   = nil
local oofing          = false
local Clip            = true
local Noclipping      = nil
local FLYING          = false
local flyKeyDown,flyKeyUp,mfly1,mfly2 = nil,nil,nil,nil
local iyflyspeed      = 1
local orbit1,orbit2,orbit3,orbit4 = nil,nil,nil,nil
local loopBringConn   = nil
local loopKillConn    = nil
local loopFlingConn   = nil
local headSitConn     = nil
local bangLoop,bangDied,bang,bangAnim = nil,nil,nil,nil
local carpetLoop,carpetDied,carpet,carpetAnim = nil,nil,nil,nil
local SpasmAnim,Spasm = nil,nil
local antiVoidLoop    = nil
local xrayEnabled     = false
local xrayLoop        = nil
local godConn         = nil
local walltpTouch     = nil
local spinEnabled     = false
local autoclicking    = false
local autoclickConn   = nil
local loopGotoConn    = nil
local loopSpeedConn   = nil
local loopJPConn      = nil
local StareatConn1,StareatConn2 = nil,nil
local WalkToConn      = nil
local norotateConn    = nil
local flyjumpConn     = nil
local autoJumpConn    = nil
local triggerConn     = nil
local cbringConn      = nil
local loopGravConn    = nil
local infJumpConn     = nil
local clickTPConn     = nil
local currentToolSize = Vector3.new(1,1,1)
local currentGripPos  = Vector3.new(0,0,0)
local tweenSpeed      = 1
local OrgDestroyHeight= workspace.FallenPartsDestroyHeight
local OrigLighting    = {
    Brightness=Lighting.Brightness, Ambient=Lighting.Ambient,
    OutdoorAmbient=Lighting.OutdoorAmbient, ClockTime=Lighting.ClockTime,
    FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart,
    GlobalShadows=Lighting.GlobalShadows,
}

-- Target
local ST = {
    Open=false, Mini=false, Tab="Fling",
    Target=nil, Speed=16, Jump=50,
    ESPOn=false, ESPBoxes={},
    MusicOn=false, MusicLoop=false, MusicVol=0.8, SongIdx=1, SongID=nil,
    CPs={}, SpinSpeed=20,
    GodMode=false, Invisible=false, Fullbright=false,
    InfJump=false, ClickTP=false,
    AntiVoid=false, XRay=false,
}

-- ============================================================
-- SONGS
-- ============================================================
local SONGS = {
    {n="<3",id="109781016044674"},{n="Dusk",id="106475212474249"},
    {n="I'll Go",id="5410081298"},{n="GateHouse",id="137409529549092"},
    {n="Sprite",id="5410083814"},{n="Stayin Alive",id="132440988854807"},
    {n="Crab Rave",id="5410086218"},{n="Cant See Moonlight",id="137072588403399"},
    {n="Sun Sprinting",id="134698083808996"},{n="BackOnTree",id="95608981665777"},
    {n="Deceptica",id="79716563884770"},{n="Am I Too Late",id="89804818669338"},
    {n="MovementRhythm",id="77249446861960"},{n="Hold On Sped",id="71045969776776"},
    {n="I Cant Tony Romera",id="5410082805"},{n="Never Be The One",id="111990911956281"},
    {n="Starfall",id="101934851079098"},{n="Run Away",id="128118999630439"},
    {n="Total Confusion",id="103419239604004"},{n="Jumpstyle",id="1839246711"},
    {n="Techno Rave",id="125418384596720"},{n="Fell It",id="109475460178206"},
    {n="TECHNO",id="73520333282970"},{n="Rave Romance",id="80345427689122"},
    {n="Hardstyle",id="1839246774"},{n="EDM Vegas",id="1842683759"},
    {n="Dreamraver",id="138577643632319"},{n="i didn't see it",id="103902016839820"},
    {n="Skylines",id="85762528306791"},{n="Right Here My Arms",id="79627520866718"},
    {n="Join Me Death",id="106344107023335"},{n="InnerAwakening",id="76585504240155"},
    {n="Banana Bashin",id="118231802185865"},{n="I Miss You",id="125460168433130"},
    {n="Lo-fi Chill A",id="9043887091"},{n="Relaxed Scene",id="1848354536"},
    {n="Claire De Lune",id="1838457617"},{n="Moonlit Memories",id="90866117181187"},
    {n="Capybara",id="99099326829992"},{n="blossom",id="136212040250804"},
    {n="Ambient Blue",id="139952467445591"},{n="Nocturne",id="129108903964685"},
    {n="Velvet Midnight",id="82091048635749"},{n="SAD!",id="72320758533508"},
    {n="BRAZIL DO FUNK",id="133498554139200"},{n="CRYSTAL FUNK",id="103445348511856"},
    {n="SEA OF PHONK",id="130367831349871"},{n="BAILE FUNK",id="104880194210827"},
    {n="GOTH FUNK",id="140704128008979"},{n="AURA DEFINED Slw",id="109805678713575"},
    {n="BRX PHONK",id="17422074849"},{n="YOTO HIME PHONK",id="103183298894656"},
    {n="BEM SOLTO BRAZIL",id="119936139925486"},{n="HOTAKFUNK",id="79314929106323"},
    {n="NEXOVA",id="127388462601694"},{n="Din1c INVASION",id="15689453529"},
    {n="Din1c METAMORPHOSIS",id="15689451063"},{n="Cowbell God",id="16190760005"},
    {n="Vine Boom",id="6823153536"},{n="Wii Sports R&B",id="72697308378715"},
    {n="POWER OF ANIME",id="1226918619"},{n="AUUUUUGH",id="8893545897"},
    {n="Better Call Saul",id="9106904975"},{n="HEHEHE HA",id="8406005582"},
    {n="Deja vu Initial D",id="16831106636"},{n="Mezcla Espanola",id="124263849663656"},
    {n="UNIVERSO",id="95518661042892"},{n="PHONK ULTRA",id="134839199346188"},
    {n="Dear Lana",id="119589412825080"},{n="plug do rj",id="129154320419135"},
}

-- ============================================================
-- HELPERS
-- ============================================================
local function Tw(o,p,d,s,dir)
    s=s or Enum.EasingStyle.Quart; dir=dir or Enum.EasingDirection.Out
    local t=TweenService:Create(o,TweenInfo.new(d or 0.3,s,dir),p); t:Play(); return t
end
local function Crn(p,r)
    local c=Instance.new("UICorner")
    c.CornerRadius=type(r)=="number" and UDim.new(0,r) or (r or UDim.new(0,14))
    c.Parent=p; return c
end
local function Strk(p,col,th)
    pcall(function()
        local s=Instance.new("UIStroke"); s.Color=col or C.Border; s.Thickness=th or 1
        pcall(function() s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end)
        s.Parent=p
    end)
end
local function Pad(p,t,b,l,r)
    local x=Instance.new("UIPadding")
    x.PaddingTop=UDim.new(0,t or 8); x.PaddingBottom=UDim.new(0,b or 8)
    x.PaddingLeft=UDim.new(0,l or 8); x.PaddingRight=UDim.new(0,r or 8)
    x.Parent=p; return x
end
local function VList(p,sp,ha)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,sp or 8); l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p; return l
end
local function HList(p,sp,ha,va)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Horizontal
    l.Padding=UDim.new(0,sp or 6); l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment=va or Enum.VerticalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p; return l
end
local function Fr(p,sz,pos,bg,tr)
    local f=Instance.new("Frame"); f.Size=sz or UDim2.new(1,0,1,0)
    f.Position=pos or UDim2.new(0,0,0,0); f.BackgroundColor3=bg or C.Card
    f.BackgroundTransparency=tr or 0; f.BorderSizePixel=0; f.Parent=p; return f
end
local function Scr(p,sz,pos)
    local s=Instance.new("ScrollingFrame"); s.Size=sz or UDim2.new(1,0,1,0)
    s.Position=pos or UDim2.new(0,0,0,0); s.BackgroundTransparency=1
    s.BorderSizePixel=0; s.ScrollBarThickness=4
    s.ScrollBarImageColor3=C.Accent; s.CanvasSize=UDim2.new(0,0,0,3000)
    s.Parent=p; return s
end
local function Notify(title,msg,dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{Title=title,Text=msg,Duration=dur or 3})
    end)
end
local function GetChar() return LP.Character end
local function GetRoot()
    local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetTorso()
    local c=GetChar(); if not c then return end
    return c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
end
local function IsR15()
    local c=GetChar(); if not c then return false end
    return c:FindFirstChild("UpperTorso") ~= nil
end

-- ============================================================
-- IY NOCLIP (exact)
-- ============================================================
local function DoNoclip()
    Clip=false
    if Noclipping then Noclipping:Disconnect() end
    Noclipping=RunService.Stepped:Connect(function()
        if Clip==false and LP.Character then
            for _,child in pairs(LP.Character:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide==true then
                    child.CanCollide=false
                end
            end
        end
    end)
end
local function DoClip()
    if Noclipping then Noclipping:Disconnect(); Noclipping=nil end
    Clip=true
end

-- ============================================================
-- IY FLY (exact - mobile ControlModule + PC WASD)
-- ============================================================
local function NOFLY()
    FLYING=false
    if flyKeyDown then flyKeyDown:Disconnect(); flyKeyDown=nil end
    if flyKeyUp then flyKeyUp:Disconnect(); flyKeyUp=nil end
    local hum=GetHum()
    if hum then pcall(function() hum.PlatformStand=false end) end
end
local function unmobilefly()
    FLYING=false
    local root=GetRoot()
    if root then
        local bv=root:FindFirstChild("KaelenBV"); local bg=root:FindFirstChild("KaelenBG")
        if bv then bv:Destroy() end; if bg then bg:Destroy() end
    end
    local hum=GetHum(); if hum then pcall(function() hum.PlatformStand=false end) end
    if mfly1 then mfly1:Disconnect(); mfly1=nil end
    if mfly2 then mfly2:Disconnect(); mfly2=nil end
end
local function mobilefly()
    unmobilefly(); FLYING=true
    local root=GetRoot(); if not root then return end
    local bv=Instance.new("BodyVelocity"); bv.Name="KaelenBV"
    bv.MaxForce=Vector3.new(9e9,9e9,9e9); bv.Velocity=Vector3.zero; bv.Parent=root
    local bg=Instance.new("BodyGyro"); bg.Name="KaelenBG"
    bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=1000; bg.D=50; bg.Parent=root
    local ctrl; pcall(function()
        ctrl=require(LP.PlayerScripts:WaitForChild("PlayerModule",3):WaitForChild("ControlModule",3))
    end)
    mfly2=RunService.Heartbeat:Connect(function()
        root=GetRoot(); if not root then return end
        local VH=root:FindFirstChild("KaelenBV"); local GH=root:FindFirstChild("KaelenBG")
        if not VH or not GH then return end
        local hum=GetHum(); if hum then hum.PlatformStand=true end
        VH.MaxForce=Vector3.new(9e9,9e9,9e9); GH.MaxTorque=Vector3.new(9e9,9e9,9e9)
        GH.CFrame=Cam.CoordinateFrame; VH.Velocity=Vector3.zero
        local spd=iyflyspeed*50
        if ctrl then
            local dir=ctrl:GetMoveVector()
            if dir.X~=0 then VH.Velocity=VH.Velocity+Cam.CFrame.RightVector*(dir.X*spd) end
            if dir.Z~=0 then VH.Velocity=VH.Velocity-Cam.CFrame.LookVector*(dir.Z*spd) end
        else
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then VH.Velocity=VH.Velocity+Cam.CFrame.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then VH.Velocity=VH.Velocity-Cam.CFrame.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then VH.Velocity=VH.Velocity-Cam.CFrame.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then VH.Velocity=VH.Velocity+Cam.CFrame.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then VH.Velocity=VH.Velocity+Vector3.new(0,spd,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then VH.Velocity=VH.Velocity-Vector3.new(0,spd,0) end
        end
    end)
end
local function sFLY() -- IY exact PC fly
    NOFLY(); task.wait(); FLYING=true
    local root=GetRoot(); if not root then return end
    local hum=GetHum(); local CONTROL={F=0,B=0,L=0,R=0,Q=0,E=0}
    local lCONTROL={F=0,B=0,L=0,R=0,Q=0,E=0}; local SPEED=0
    local BG=Instance.new("BodyGyro"); local BV=Instance.new("BodyVelocity")
    BG.P=9e4; BG.Parent=root; BG.MaxTorque=Vector3.new(9e9,9e9,9e9); BG.CFrame=root.CFrame
    BV.Velocity=Vector3.zero; BV.MaxForce=Vector3.new(9e9,9e9,9e9); BV.Parent=root
    task.spawn(function()
        repeat task.wait()
            if hum then hum.PlatformStand=true end
            local sp=iyflyspeed*50
            SPEED=(CONTROL.L+CONTROL.R~=0 or CONTROL.F+CONTROL.B~=0 or CONTROL.Q+CONTROL.E~=0) and sp or 0
            if (CONTROL.L+CONTROL.R)~=0 or (CONTROL.F+CONTROL.B)~=0 or (CONTROL.Q+CONTROL.E)~=0 then
                BV.Velocity=((Cam.CFrame.LookVector*(CONTROL.F+CONTROL.B))+((Cam.CFrame*CFrame.new(CONTROL.L+CONTROL.R,(CONTROL.Q+CONTROL.E)*0.2,0)).Position-Cam.CFrame.Position))*SPEED
                lCONTROL={F=CONTROL.F,B=CONTROL.B,L=CONTROL.L,R=CONTROL.R,Q=CONTROL.Q,E=CONTROL.E}
            elseif SPEED~=0 then
                BV.Velocity=((Cam.CFrame.LookVector*(lCONTROL.F+lCONTROL.B))+((Cam.CFrame*CFrame.new(lCONTROL.L+lCONTROL.R,(lCONTROL.F+lCONTROL.B)*0.2,0)).Position-Cam.CFrame.Position))*SPEED
            else BV.Velocity=Vector3.zero end
            BG.CFrame=Cam.CFrame
        until not FLYING
        pcall(function() if hum then hum.PlatformStand=false end; BG:Destroy(); BV:Destroy() end)
    end)
    flyKeyDown=UserInputService.InputBegan:Connect(function(input,proc)
        if proc then return end; local sp=iyflyspeed
        if input.KeyCode==Enum.KeyCode.W then CONTROL.F=sp
        elseif input.KeyCode==Enum.KeyCode.S then CONTROL.B=-sp
        elseif input.KeyCode==Enum.KeyCode.A then CONTROL.L=-sp
        elseif input.KeyCode==Enum.KeyCode.D then CONTROL.R=sp
        elseif input.KeyCode==Enum.KeyCode.E then CONTROL.Q=sp*2
        elseif input.KeyCode==Enum.KeyCode.Q then CONTROL.E=-sp*2 end
    end)
    flyKeyUp=UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.W then CONTROL.F=0
        elseif input.KeyCode==Enum.KeyCode.S then CONTROL.B=0
        elseif input.KeyCode==Enum.KeyCode.A then CONTROL.L=0
        elseif input.KeyCode==Enum.KeyCode.D then CONTROL.R=0
        elseif input.KeyCode==Enum.KeyCode.E then CONTROL.Q=0
        elseif input.KeyCode==Enum.KeyCode.Q then CONTROL.E=0 end
    end)
end
local function StartFly()
    local mob=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if mob then mobilefly() else sFLY() end
end
local function StopFly()
    local mob=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if mob then unmobilefly() else NOFLY() end; FLYING=false
end

-- ============================================================
-- IY FLING (exact - BodyAngularVelocity 99999)
-- ============================================================
local function DoFling()
    flinging=false
    if not LP.Character then return end
    for _,child in pairs(LP.Character:GetDescendants()) do
        if child:IsA("BasePart") then
            pcall(function() child.CustomPhysicalProperties=PhysicalProperties.new(100,0.3,0.5) end)
        end
    end
    DoNoclip(); task.wait(0.1)
    local root=GetRoot(); if not root then return end
    for _,v in pairs(root:GetChildren()) do
        if v:IsA("BodyAngularVelocity") then v:Destroy() end
    end
    local bambam=Instance.new("BodyAngularVelocity")
    bambam.Name="KaelenFlingBAV"; bambam.Parent=root
    bambam.AngularVelocity=Vector3.new(0,99999,0)
    bambam.MaxTorque=Vector3.new(0,math.huge,0)
    bambam.P=math.huge
    for _,v in pairs(LP.Character:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide=false; pcall(function() v.Massless=true end)
            v.Velocity=Vector3.zero
        end
    end
    flinging=true
    local hum=GetHum()
    if hum then
        if flingDied then pcall(function() flingDied:Disconnect() end) end
        flingDied=hum.Died:Connect(function()
            flinging=false; DoClip()
            pcall(function() flingDied:Disconnect() end); flingDied=nil
        end)
    end
    task.spawn(function()
        repeat
            if bambam and bambam.Parent then bambam.AngularVelocity=Vector3.new(0,99999,0) end
            task.wait(0.2)
            if bambam and bambam.Parent then bambam.AngularVelocity=Vector3.zero end
            task.wait(0.1)
        until flinging==false
    end)
    Notify("Fling","Flinging! Press again to stop",3)
end
local function StopFling()
    DoClip()
    if flingDied then pcall(function() flingDied:Disconnect() end); flingDied=nil end
    flinging=false; task.wait(0.1)
    local root=GetRoot()
    if root then
        for _,v in pairs(root:GetChildren()) do
            if v:IsA("BodyAngularVelocity") then v:Destroy() end
        end
    end
    if LP.Character then
        for _,child in pairs(LP.Character:GetDescendants()) do
            if child:IsA("BasePart") then
                pcall(function() child.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5) end)
            end
        end
    end
    Notify("Fling","Stopped",2)
end

-- ============================================================
-- IY WALKFLING (exact)
-- ============================================================
local function DoWalkFling()
    if walkflingConn then walkflingConn:Disconnect(); walkflingConn=nil end
    walkflinging=false; task.wait(0.05)
    DoNoclip()
    local hum=GetHum()
    if hum then hum.Died:Connect(function()
        walkflinging=false; DoClip()
        if walkflingConn then walkflingConn:Disconnect(); walkflingConn=nil end
    end) end
    walkflinging=true
    task.spawn(function()
        repeat
            RunService.Heartbeat:Wait()
            local root=GetRoot(); if not root then task.wait(0.1); continue end
            local vel=root.Velocity
            root.Velocity=vel*10000+Vector3.new(0,10000,0)
            RunService.Heartbeat:Wait()
            if root and root.Parent then root.Velocity=vel end
        until walkflinging==false
        DoClip()
    end)
    Notify("WalkFling","Walk to fling! Toggle to stop",3)
end
local function StopWalkFling()
    walkflinging=false; DoClip()
end

-- ============================================================
-- IY SPIN (exact - BodyAngularVelocity named "Spinning")
-- ============================================================
local function DoSpin(speed)
    local root=GetRoot(); if not root then return end
    for _,v in pairs(root:GetChildren()) do
        if v.Name=="Spinning" then v:Destroy() end
    end
    local Spin=Instance.new("BodyAngularVelocity")
    Spin.Name="Spinning"; Spin.Parent=root
    Spin.MaxTorque=Vector3.new(0,math.huge,0)
    Spin.AngularVelocity=Vector3.new(0,speed or 20,0)
end
local function StopSpin()
    local root=GetRoot(); if not root then return end
    for _,v in pairs(root:GetChildren()) do
        if v.Name=="Spinning" then v:Destroy() end
    end
end

-- ============================================================
-- IY HEADSIT (exact)
-- ============================================================
local function DoHeadsit(target)
    if headSitConn then headSitConn:Disconnect(); headSitConn=nil end
    if not target or not target.Character then return end
    local myHum=GetHum(); if myHum then myHum.Sit=true end
    headSitConn=RunService.Heartbeat:Connect(function()
        local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local myRoot=GetRoot(); local myH=GetHum()
        if tRoot and myRoot and myH and myH.Sit then
            myRoot.CFrame=tRoot.CFrame*CFrame.Angles(0,0,0)*CFrame.new(0,1.6,0.4)
        else headSitConn:Disconnect(); headSitConn=nil end
    end)
    Notify("HeadSit","Sitting on "..target.Name,2)
end
local function StopHeadsit()
    if headSitConn then headSitConn:Disconnect(); headSitConn=nil end
    local hum=GetHum(); if hum then hum.Sit=false end
end

-- ============================================================
-- IY ORBIT (exact)
-- ============================================================
local function DoOrbit(target,speed,dist)
    if orbit1 then orbit1:Disconnect() end; if orbit2 then orbit2:Disconnect() end
    if orbit3 then orbit3:Disconnect() end; if orbit4 then orbit4:Disconnect() end
    if not target or not target.Character then return end
    local root=GetRoot(); local hum=GetHum()
    local rotation=0; speed=speed or 0.2; dist=dist or 6
    orbit1=RunService.Heartbeat:Connect(function()
        pcall(function()
            rotation=rotation+speed
            root.CFrame=CFrame.new(target.Character:FindFirstChild("HumanoidRootPart").Position)*CFrame.Angles(0,math.rad(rotation),0)*CFrame.new(dist,0,0)
        end)
    end)
    orbit2=RunService.Heartbeat:Connect(function()
        pcall(function()
            local tRoot=target.Character:FindFirstChild("HumanoidRootPart")
            if root and tRoot then root.CFrame=CFrame.new(root.Position,tRoot.Position) end
        end)
    end)
    if hum then orbit3=hum.Died:Connect(function()
        if orbit1 then orbit1:Disconnect() end; if orbit2 then orbit2:Disconnect() end
    end) end
    Notify("Orbit","Orbiting "..target.Name,2)
end
local function StopOrbit()
    if orbit1 then orbit1:Disconnect(); orbit1=nil end
    if orbit2 then orbit2:Disconnect(); orbit2=nil end
    if orbit3 then orbit3:Disconnect(); orbit3=nil end
    if orbit4 then orbit4:Disconnect(); orbit4=nil end
end

-- ============================================================
-- IY FREEZE/THAW (exact)
-- ============================================================
local function Freeze(p)
    if not p or not p.Character then return end
    for _,x in next,p.Character:GetDescendants() do
        if x:IsA("BasePart") and not x.Anchored then x.Anchored=true end
    end
end
local function Thaw(p)
    if not p or not p.Character then return end
    for _,x in next,p.Character:GetDescendants() do
        if x:IsA("BasePart") and x.Anchored then x.Anchored=false end
    end
end

-- ============================================================
-- IY LOOPOOF (exact)
-- ============================================================
local function StartLoopOof()
    oofing=true
    task.spawn(function()
        repeat task.wait(0.1)
            for _,v in pairs(Players:GetPlayers()) do
                if v.Character and v.Character:FindFirstChild("Head") then
                    for _,x in pairs(v.Character.Head:GetChildren()) do
                        if x:IsA("Sound") then x.Playing=true end
                    end
                end
            end
        until oofing==false
    end)
end
local function StopLoopOof() oofing=false end

-- ============================================================
-- IY BANG (exact - animation + follow)
-- ============================================================
local function DoBang(target,speed)
    -- Stop previous
    if bangDied then pcall(function() bangDied:Disconnect() end) end
    if bangLoop then pcall(function() bangLoop:Disconnect() end) end
    if bang then pcall(function() bang:Stop() end) end
    if bangAnim then pcall(function() bangAnim:Destroy() end) end
    local hum=GetHum(); if not hum then return end
    bangAnim=Instance.new("Animation")
    bangAnim.AnimationId=IsR15() and "rbxassetid://5918726674" or "rbxassetid://148840371"
    bang=hum:LoadAnimation(bangAnim); bang:Play(0.1,1,1)
    bang:AdjustSpeed(speed or 3)
    bangDied=hum.Died:Connect(function()
        pcall(function() bang:Stop(); bangAnim:Destroy() end)
        pcall(function() bangDied:Disconnect() end)
        pcall(function() bangLoop:Disconnect() end)
    end)
    if target and target.Character then
        local bOffset=CFrame.new(0,0,1.1)
        bangLoop=RunService.Stepped:Connect(function()
            pcall(function()
                local tTorso=target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
                local myRoot=GetRoot()
                if myRoot and tTorso then myRoot.CFrame=tTorso.CFrame*bOffset end
            end)
        end)
    end
    Notify("Bang","Playing bang anim".. (target and " on "..target.Name or ""),2)
end
local function StopBang()
    if bangDied then pcall(function() bangDied:Disconnect(); bangDied=nil end) end
    if bangLoop then pcall(function() bangLoop:Disconnect(); bangLoop=nil end) end
    if bang then pcall(function() bang:Stop(); bang=nil end) end
    if bangAnim then pcall(function() bangAnim:Destroy(); bangAnim=nil end) end
end

-- ============================================================
-- IY CARPET (exact - animation + loop position copy)
-- ============================================================
local function DoCarpet(target)
    if carpetLoop then pcall(function() carpetLoop:Disconnect() end) end
    if carpetDied then pcall(function() carpetDied:Disconnect() end) end
    if carpet then pcall(function() carpet:Stop() end) end
    if carpetAnim then pcall(function() carpetAnim:Destroy() end) end
    if IsR15() then Notify("R6 Only","Carpet requires R6",2); return end
    if not target or not target.Character then return end
    local hum=GetHum(); if not hum then return end
    carpetAnim=Instance.new("Animation"); carpetAnim.AnimationId="rbxassetid://282574440"
    carpet=hum:LoadAnimation(carpetAnim); carpet:Play(0.1,1,1)
    carpetDied=hum.Died:Connect(function()
        pcall(function() carpetLoop:Disconnect(); carpet:Stop(); carpetAnim:Destroy() end)
    end)
    carpetLoop=RunService.Heartbeat:Connect(function()
        pcall(function()
            local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local myRoot=GetRoot()
            if myRoot and tRoot then myRoot.CFrame=tRoot.CFrame end
        end)
    end)
    Notify("Carpet","Carpeting "..target.Name,2)
end
local function StopCarpet()
    if carpetLoop then pcall(function() carpetLoop:Disconnect(); carpetLoop=nil end) end
    if carpetDied then pcall(function() carpetDied:Disconnect(); carpetDied=nil end) end
    if carpet then pcall(function() carpet:Stop(); carpet=nil end) end
    if carpetAnim then pcall(function() carpetAnim:Destroy(); carpetAnim=nil end) end
end

-- ============================================================
-- IY SPASM (exact - animation id 33796059 at speed 99)
-- ============================================================
local function DoSpasm()
    if IsR15() then Notify("R6 Only","Spasm requires R6",2); return end
    if Spasm then pcall(function() Spasm:Stop(); SpasmAnim:Destroy() end) end
    local hum=GetHum(); if not hum then return end
    SpasmAnim=Instance.new("Animation"); SpasmAnim.AnimationId="rbxassetid://33796059"
    Spasm=hum:LoadAnimation(SpasmAnim); Spasm:Play(); Spasm:AdjustSpeed(99)
    Notify("Spasm","Spasming!",2)
end
local function StopSpasm()
    if Spasm then pcall(function() Spasm:Stop(); SpasmAnim:Destroy(); Spasm=nil; SpasmAnim=nil end) end
end

-- ============================================================
-- IY HEADTHROW (anim 35154961)
-- ============================================================
local function DoHeadThrow()
    if IsR15() then Notify("R6 Only","HeadThrow requires R6",2); return end
    local hum=GetHum(); if not hum then return end
    local anim=Instance.new("Animation"); anim.AnimationId="rbxassetid://35154961"
    local track=hum:LoadAnimation(anim); track:Play(0); track:AdjustSpeed(1)
    Notify("HeadThrow","Thrown!",2)
end

-- ============================================================
-- IY ANTIVOID (exact - add velocity when near destroy height)
-- ============================================================
local function StartAntiVoid()
    if antiVoidLoop then antiVoidLoop:Disconnect() end
    antiVoidLoop=RunService.Stepped:Connect(function()
        local root=GetRoot()
        if root and root.Position.Y<=OrgDestroyHeight+25 then
            root.Velocity=root.Velocity+Vector3.new(0,250,0)
        end
    end)
    Notify("AntiVoid","Enabled",2)
end
local function StopAntiVoid()
    if antiVoidLoop then antiVoidLoop:Disconnect(); antiVoidLoop=nil end
    Notify("AntiVoid","Disabled",2)
end

-- ============================================================
-- IY XRAY (exact - LocalTransparencyModifier on non-char parts)
-- ============================================================
local function SetXray(on)
    xrayEnabled=on
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local hasHum=v.Parent:FindFirstChildWhichIsA("Humanoid") or v.Parent.Parent:FindFirstChildWhichIsA("Humanoid")
            if not hasHum then v.LocalTransparencyModifier=on and 0.5 or 0 end
        end
    end
end

-- ============================================================
-- IY STARE (look at target constantly)
-- ============================================================
local function StartStare(target)
    if StareatConn1 then StareatConn1:Disconnect() end
    if StareatConn2 then StareatConn2:Disconnect() end
    if not target or not target.Character then return end
    local root=GetRoot(); if not root then return end
    StareatConn1=RunService.Heartbeat:Connect(function()
        pcall(function()
            local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if root and tRoot then
                root.CFrame=CFrame.new(root.Position,Vector3.new(tRoot.Position.X,root.Position.Y,tRoot.Position.Z))
            end
        end)
    end)
    Notify("Stare","Staring at "..target.Name,2)
end
local function StopStare()
    if StareatConn1 then StareatConn1:Disconnect(); StareatConn1=nil end
    if StareatConn2 then StareatConn2:Disconnect(); StareatConn2=nil end
end

-- ============================================================
-- IY TRIP (exact)
-- ============================================================
local function DoTrip()
    local hum=GetHum(); local root=GetRoot()
    if hum and root then
        hum:ChangeState(Enum.HumanoidStateType.FallingDown)
        root.Velocity=root.CFrame.LookVector*30
    end
    Notify("Trip","Tripped!",2)
end

-- ============================================================
-- IY SCARE (exact - appear in front of target briefly)
-- ============================================================
local function DoScare(target)
    if not target or not target.Character then return end
    local root=GetRoot(); if not root then return end
    local tRoot=target.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    local oldPos=root.CFrame
    root.CFrame=tRoot.CFrame+tRoot.CFrame.LookVector*2
    root.CFrame=CFrame.new(root.Position,tRoot.Position)
    task.wait(0.5); root.CFrame=oldPos
    Notify("Scare","Scared "..target.Name,2)
end

-- ============================================================
-- IY GOD MODE (loop health)
-- ============================================================
local function SetGod(on)
    if godConn then godConn:Disconnect(); godConn=nil end
    if on then
        godConn=RunService.Heartbeat:Connect(function()
            local hum=GetHum()
            if hum and hum.Health<hum.MaxHealth then hum.Health=hum.MaxHealth end
        end)
    end
end

-- ============================================================
-- IY INVISIBLE (LocalTransparencyModifier)
-- ============================================================
local function SetInvisible(on)
    local char=GetChar(); if not char then return end
    for _,v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.LocalTransparencyModifier=on and 1 or 0 end
        if v:IsA("Decal") then v.Transparency=on and 1 or 0 end
    end
end

-- ============================================================
-- IY FULLBRIGHT
-- ============================================================
local function SetFullbright(on)
    if on then
        OrigLighting.Brightness=Lighting.Brightness
        Lighting.Brightness=8
        Lighting.Ambient=Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255)
    else
        Lighting.Brightness=OrigLighting.Brightness
        Lighting.Ambient=OrigLighting.Ambient
        Lighting.OutdoorAmbient=OrigLighting.OutdoorAmbient
    end
end

-- ============================================================
-- IY INF JUMP
-- ============================================================
local function SetInfJump(on)
    if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end
    if on then
        infJumpConn=UserInputService.JumpRequest:Connect(function()
            local hum=GetHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- ============================================================
-- CLICK TP
-- ============================================================
local function SetClickTP(on)
    if clickTPConn then clickTPConn:Disconnect(); clickTPConn=nil end
    if on then
        clickTPConn=Mouse.Button1Down:Connect(function()
            if not ST.ClickTP then return end
            local root=GetRoot()
            if root and Mouse.Hit then root.CFrame=Mouse.Hit+Vector3.new(0,3,0) end
        end)
    end
end

-- ============================================================
-- IY SIZE
-- ============================================================
local function SetSize(p,scale)
    local char=p and p.Character or GetChar(); if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    pcall(function()
        hum.BodyDepthScale.Value=scale; hum.BodyHeightScale.Value=scale
        hum.BodyWidthScale.Value=scale; hum.HeadScale.Value=scale
    end)
end

-- ============================================================
-- IY WALLWALK (walk on any surface)
-- ============================================================
local wallwalkConn
local function StartWallWalk()
    if wallwalkConn then wallwalkConn:Disconnect() end
    wallwalkConn=RunService.Heartbeat:Connect(function()
        local hum=GetHum()
        if hum then pcall(function() hum:Move(Cam.CFrame.LookVector,true) end) end
    end)
    Notify("WallWalk","Use movement keys on walls",3)
end
local function StopWallWalk()
    if wallwalkConn then wallwalkConn:Disconnect(); wallwalkConn=nil end
end

-- ============================================================
-- IY HATSPIN (spin hats)
-- ============================================================
local hatSpinConn
local function StartHatSpin(speed)
    if hatSpinConn then hatSpinConn:Disconnect() end
    local angle=0
    hatSpinConn=RunService.Heartbeat:Connect(function(dt)
        local char=GetChar(); if not char then return end
        angle=angle+dt*(speed or 5)
        for _,v in pairs(char:GetDescendants()) do
            if v:IsA("Accessory") and v:FindFirstChild("Handle") then
                v.Handle.CFrame=v.Handle.CFrame*CFrame.Angles(0,math.rad(speed or 5)*dt*60,0)
            end
        end
    end)
    Notify("HatSpin","Hats are spinning!",2)
end
local function StopHatSpin()
    if hatSpinConn then hatSpinConn:Disconnect(); hatSpinConn=nil end
end

-- ============================================================
-- IY DROP/DELETE HATS
-- ============================================================
local function DropHats()
    local char=GetChar(); if not char then return end
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") and v:FindFirstChild("Handle") then
            v.Handle.Parent=workspace
        end
    end
    Notify("DropHats","Hats dropped!",2)
end
local function DeleteHats()
    local char=GetChar(); if not char then return end
    for _,v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") then v:Destroy() end
    end
    Notify("DeleteHats","Hats deleted!",2)
end

-- ============================================================
-- IY NOLIMBS (remove arms/legs)
-- ============================================================
local function RemoveLimbs(which)
    local char=GetChar(); if not char then return end
    local limbNames={}
    if which=="arms" or which=="all" then
        limbNames={"Left Arm","Right Arm","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand"}
    elseif which=="legs" or which=="all" then
        for _,n in ipairs({"Left Leg","Right Leg","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}) do
            table.insert(limbNames,n)
        end
    end
    if which=="all" then
        limbNames={"Left Arm","Right Arm","Left Leg","Right Leg","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
    end
    for _,name in ipairs(limbNames) do
        local part=char:FindFirstChild(name)
        if part then part:Destroy() end
    end
    Notify("NoLimbs","Limbs removed",2)
end

-- ============================================================
-- IY CLIENTBRING / LOOPBRING
-- ============================================================
local function StartClientBring(target)
    if cbringConn then cbringConn:Disconnect() end
    if not target then return end
    cbringConn=RunService.Heartbeat:Connect(function()
        local myRoot=GetRoot()
        local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then tRoot.CFrame=myRoot.CFrame*CFrame.new(0,0,4) end
    end)
    Notify("ClientBring","Bringing "..target.Name,2)
end
local function StopClientBring()
    if cbringConn then cbringConn:Disconnect(); cbringConn=nil end
end

-- ============================================================
-- LOOP KILL / FLING TARGET
-- ============================================================
local function StartLoopKill(target)
    if loopKillConn then loopKillConn:Disconnect() end
    if not target then return end
    loopKillConn=RunService.Heartbeat:Connect(function()
        local hum=target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health=0 end
    end)
end
local function StopLoopKill()
    if loopKillConn then loopKillConn:Disconnect(); loopKillConn=nil end
end
local function StartLoopFling(target,power)
    if loopFlingConn then loopFlingConn:Disconnect() end
    if not target then return end
    loopFlingConn=RunService.Heartbeat:Connect(function()
        local root=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity=Vector3.new(math.random(-1,1)*(power or 500),math.random(300,800),math.random(-1,1)*(power or 500)) end
    end)
end
local function StopLoopFling()
    if loopFlingConn then loopFlingConn:Disconnect(); loopFlingConn=nil end
end

-- ============================================================
-- IY STUN (PlatformStand)
-- ============================================================
local function SetStun(on)
    local hum=GetHum(); if hum then hum.PlatformStand=on end
end

-- ============================================================
-- IY NO ROTATE (AutoRotate)
-- ============================================================
local function SetNoRotate(on)
    local hum=GetHum()
    if hum then pcall(function() hum.AutoRotate=not on end) end
end

-- ============================================================
-- IY FLY JUMP (IY exact - jump while maintaining velocity)
-- ============================================================
local function SetFlyJump(on)
    if flyjumpConn then flyjumpConn:Disconnect(); flyjumpConn=nil end
    if on then
        flyjumpConn=UserInputService.JumpRequest:Connect(function()
            local root=GetRoot()
            if root then root.Velocity=root.Velocity+Vector3.new(0,100,0) end
        end)
    end
end

-- ============================================================
-- IY WALKTOWAYPOINT (walk to position)
-- ============================================================
local function WalkTo(target)
    if WalkToConn then WalkToConn:Disconnect(); WalkToConn=nil end
    if not target or not target.Character then return end
    local hum=GetHum(); if not hum then return end
    local tRoot=target.Character:FindFirstChild("HumanoidRootPart")
    if tRoot then hum:MoveTo(tRoot.Position) end
    Notify("WalkTo","Walking to "..target.Name,2)
end

-- ============================================================
-- IY MUTE BOOMBOX
-- ============================================================
local function MuteBoombox(target,on)
    local targets=target and {target} or Players:GetPlayers()
    for _,p in ipairs(targets) do
        if p.Character then
            for _,x in pairs(p.Character:GetDescendants()) do
                if x:IsA("Sound") then x.Playing=not on end
            end
        end
    end
    Notify("Boombox",on and "Muted" or "Unmuted",2)
end

-- ============================================================
-- IY LOOPSPEED / LOOPJUMPPOWER
-- ============================================================
local function StartLoopSpeed(v)
    if loopSpeedConn then loopSpeedConn:Disconnect() end
    loopSpeedConn=RunService.Heartbeat:Connect(function()
        local hum=GetHum(); if hum then hum.WalkSpeed=v end
    end)
end
local function StopLoopSpeed()
    if loopSpeedConn then loopSpeedConn:Disconnect(); loopSpeedConn=nil end
end
local function StartLoopJP(v)
    if loopJPConn then loopJPConn:Disconnect() end
    loopJPConn=RunService.Heartbeat:Connect(function()
        local hum=GetHum(); if hum then hum.JumpPower=v end
    end)
end
local function StopLoopJP()
    if loopJPConn then loopJPConn:Disconnect(); loopJPConn=nil end
end

-- ============================================================
-- IY CHAT
-- ============================================================
local function ChatMsg(msg)
    pcall(function()
        local rs=game:GetService("ReplicatedStorage")
        local ev=rs:FindFirstChild("DefaultChatSystemChatEvents")
        if ev then
            local say=ev:FindFirstChild("SayMessageRequest")
            if say then say:FireServer(msg,"All"); return end
        end
    end)
    pcall(function()
        game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(msg)
    end)
end

local spamConn; local spamMsg=""; local spamOn=false
local function StartSpam(msg,interval)
    spamMsg=msg; spamOn=true
    task.spawn(function()
        repeat ChatMsg(spamMsg); task.wait(interval or 2) until spamOn==false
    end)
    Notify("Spam","Spam started",2)
end
local function StopSpam() spamOn=false; Notify("Spam","Spam stopped",2) end

-- ============================================================
-- IY MISC
-- ============================================================
local function Explode(p)
    if not p or not p.Character then return end
    local root=p.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
    local exp=Instance.new("Explosion"); exp.Position=root.Position
    exp.BlastRadius=8; exp.BlastPressure=500000
    pcall(function() exp.ExplosionType=Enum.ExplosionType.NoCraters end)
    exp.Parent=workspace
end
local function Launch(p,power)
    if not p or not p.Character then return end
    local root=p.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
    local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,power or 1200,0)
    bv.MaxForce=Vector3.new(0,1e9,0); bv.Parent=root; Debris:AddItem(bv,0.4)
end
local function Knockback(p,power)
    if not p or not p.Character then return end
    local myRoot=GetRoot(); if not myRoot then return end
    local tRoot=p.Character:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
    local dir=(tRoot.Position-myRoot.Position).Unit
    local bv=Instance.new("BodyVelocity"); bv.Velocity=dir*(power or 200)+Vector3.new(0,80,0)
    bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=tRoot; Debris:AddItem(bv,0.35)
end
local function Blind(p,dur)
    if not p or not p.Character then return end
    local head=p.Character:FindFirstChild("Head"); if not head then return end
    local part=Instance.new("Part"); part.Size=Vector3.new(8,8,8)
    part.Material=Enum.Material.Neon; part.BrickColor=BrickColor.new("Institutional white")
    part.CanCollide=false; part.CFrame=head.CFrame; part.Parent=workspace
    local weld=Instance.new("WeldConstraint"); weld.Part0=head; weld.Part1=part; weld.Parent=part
    Debris:AddItem(part,dur or 8); Notify("Blind","Blinded "..p.Name.." "..dur.."s",2)
end
local function SetFX(p,t,on)
    local char=p and p.Character or GetChar(); if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return end
    if on then if not root:FindFirstChildOfClass(t) then Instance.new(t).Parent=root end
    else local fx=root:FindFirstChildOfClass(t); if fx then fx:Destroy() end end
end
local function SetNametag(name)
    local hum=GetHum(); if hum then hum.DisplayName=name end
    Notify("Nametag","Name set: "..name,2)
end
local function NoFace()
    local char=GetChar(); if not char then return end
    local head=char:FindFirstChild("Head"); if not head then return end
    local face=head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
    if face then face.Transparency=1 end; Notify("NoFace","Face hidden",2)
end

-- IY DANCE
local danceTracks={}
local danceIDs={"507770239","507771019","507771955","507772104","507772398","507773317","507776043","507776468","507777268","507777451","1073893568","1073893569"}
local function Dance(idx)
    local hum=GetHum(); if not hum then return end
    for _,t in ipairs(danceTracks) do pcall(function() t:Stop() end) end; danceTracks={}
    local anim=Instance.new("Animation")
    anim.AnimationId="rbxassetid://"..(danceIDs[idx] or danceIDs[1])
    local track=hum.Animator:LoadAnimation(anim); track:Play(); danceTracks={track}
    Notify("Dance","Dance "..idx,2)
end
local function StopDance()
    for _,t in ipairs(danceTracks) do pcall(function() t:Stop() end) end; danceTracks={}
end

-- CUSTOM ANIM
local function PlayAnim(id,speed)
    local hum=GetHum(); if not hum then return end
    local anim=Instance.new("Animation"); anim.AnimationId="rbxassetid://"..tostring(id)
    local track=hum.Animator:LoadAnimation(anim)
    pcall(function() track.Priority=Enum.AnimationPriority.Action end)
    track:Play(); if speed then pcall(function() track:AdjustSpeed(speed) end) end
    danceTracks[#danceTracks+1]=track
    Notify("Anim","Playing anim "..id,2)
end
local function SetAnimSpeed(speed)
    local hum=GetHum(); if not hum then return end
    for _,track in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
        pcall(function() track:AdjustSpeed(speed) end)
    end
end

-- COPY ANIM FROM PLAYER
local function CopyAnim(target)
    if not target or not target.Character then return end
    local myHum=GetHum(); local tHum=target.Character:FindFirstChildOfClass("Humanoid")
    if not myHum or not tHum then return end
    for _,t in ipairs(myHum.Animator:GetPlayingAnimationTracks()) do t:Stop() end
    for _,t in ipairs(tHum.Animator:GetPlayingAnimationTracks()) do
        if not t.Animation.AnimationId:find("507768375") then
            local a=myHum.Animator:LoadAnimation(t.Animation)
            a:Play(); a:AdjustSpeed(t.Speed)
        end
    end
    Notify("CopyAnim","Copied "..target.Name.."'s animations",2)
end

-- ESP
local ESPBoxes={}
local function UpdateESP(on)
    for _,b in pairs(ESPBoxes) do pcall(function() b:Destroy() end) end; ESPBoxes={}
    if not on then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local h=Instance.new("SelectionBox"); h.Color3=C.Red; h.LineThickness=0.05
            h.SurfaceTransparency=0.75; h.SurfaceColor3=C.Red; h.Adornee=p.Character; h.Parent=workspace
            ESPBoxes[p.Name]=h
        end
    end
end

-- MUSIC
local MusicSound=Instance.new("Sound"); MusicSound.Name="KaelenMusic"
MusicSound.Volume=0.8; MusicSound.RollOffMaxDistance=999999; MusicSound.RollOffMinDistance=999999
pcall(function() MusicSound.RollOffMode=Enum.RollOffMode.InverseTapered end)
MusicSound.Parent=workspace
local NPLabel
local function PlaySong(id,name)
    MusicSound.SoundId="rbxassetid://"..tostring(id); MusicSound:Stop(); MusicSound:Play()
    ST.MusicOn=true; ST.SongID=tostring(id)
    if NPLabel then NPLabel.Text="Now Playing: "..(name or id) end
    Notify("Music","Now Playing: "..(name or id),3)
end
local function StopMusic() MusicSound:Stop(); ST.MusicOn=false; if NPLabel then NPLabel.Text="Stopped" end end
MusicSound.Ended:Connect(function()
    if ST.MusicLoop and ST.SongID then MusicSound:Play()
    elseif ST.MusicOn then ST.SongIdx=(ST.SongIdx % #SONGS)+1; PlaySong(SONGS[ST.SongIdx].id,SONGS[ST.SongIdx].n) end
end)

-- ============================================================
-- GUI SETUP
-- ============================================================
local PGui=LP:WaitForChild("PlayerGui")
local oldH=PGui:FindFirstChild("KaelenHubV4"); if oldH then oldH:Destroy() end
local SG=Instance.new("ScreenGui"); SG.Name="KaelenHubV4"
SG.ResetOnSpawn=false; SG.IgnoreGuiInset=true; SG.DisplayOrder=999
pcall(function() SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling end)
SG.Parent=PGui

-- FLOAT BUTTON
local FB=Instance.new("ImageButton"); FB.Size=UDim2.new(0,72,0,72)
FB.Position=UDim2.new(0,14,0.5,-36); FB.BackgroundColor3=C.Accent
FB.BorderSizePixel=0; FB.ZIndex=20; FB.Parent=SG; Crn(FB,UDim.new(1,0))
do
    local g=Instance.new("UIGradient"); g.Rotation=135
    g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.Accent),ColorSequenceKeypoint.new(1,C.Pink)})
    g.Parent=FB
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency=1; lbl.Text="K"; lbl.TextSize=30
    lbl.Font=Enum.Font.GothamBold; lbl.TextColor3=C.White; lbl.ZIndex=21; lbl.Parent=FB
end

-- MAIN FRAME
local MF=Instance.new("Frame"); MF.Name="MainFrame"
MF.AnchorPoint=Vector2.new(0.5,0.5); MF.Size=UDim2.new(0,0,0,0)
MF.Position=UDim2.new(0.5,0,0.5,0); MF.BackgroundColor3=C.BG
MF.BackgroundTransparency=0.05; MF.BorderSizePixel=0
MF.Visible=false; MF.ClipsDescendants=true; MF.ZIndex=10; MF.Parent=SG
Crn(MF,18); Strk(MF,C.Border,1)
do
    local g=Instance.new("UIGradient"); g.Rotation=135
    g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(20,16,36)),ColorSequenceKeypoint.new(1,Color3.fromRGB(8,8,18))})
    g.Parent=MF
end

-- HEADER
local HDR=Fr(MF,UDim2.new(1,0,0,56),UDim2.new(0,0,0,0),C.Panel,0); HDR.ZIndex=11; Crn(HDR,18)
do
    local dot=Fr(HDR,UDim2.new(0,8,0,8),UDim2.new(0,12,0.5,-4),C.Accent,0); Crn(dot,UDim.new(1,0)); dot.ZIndex=12
    local t=Instance.new("TextLabel"); t.Size=UDim2.new(0,200,0,24); t.Position=UDim2.new(0,26,0,8)
    t.BackgroundTransparency=1; t.Text="Kaelen Hub v4"; t.TextSize=17; t.Font=Enum.Font.GothamBold
    t.TextColor3=C.White; t.TextXAlignment=Enum.TextXAlignment.Left; t.ZIndex=12; t.Parent=HDR
    local s=Instance.new("TextLabel"); s.Size=UDim2.new(0,200,0,16); s.Position=UDim2.new(0,26,0,33)
    s.BackgroundTransparency=1; s.Text="IY Complete | by crx-ter"; s.TextSize=11; s.Font=Enum.Font.Gotham
    s.TextColor3=C.Dim; s.TextXAlignment=Enum.TextXAlignment.Left; s.ZIndex=12; s.Parent=HDR
    local MinBtn=Instance.new("TextButton"); MinBtn.Size=UDim2.new(0,38,0,38)
    MinBtn.Position=UDim2.new(1,-90,0.5,-19); MinBtn.BackgroundColor3=C.Orange
    MinBtn.BackgroundTransparency=0.2; MinBtn.Text="—"; MinBtn.TextColor3=C.White
    MinBtn.TextSize=18; MinBtn.Font=Enum.Font.GothamBold; MinBtn.BorderSizePixel=0; MinBtn.ZIndex=12; MinBtn.Parent=HDR
    Crn(MinBtn,10)
    local ClsBtn=Instance.new("TextButton"); ClsBtn.Size=UDim2.new(0,38,0,38)
    ClsBtn.Position=UDim2.new(1,-46,0.5,-19); ClsBtn.BackgroundColor3=C.Red
    ClsBtn.BackgroundTransparency=0.2; ClsBtn.Text="X"; ClsBtn.TextColor3=C.White
    ClsBtn.TextSize=16; ClsBtn.Font=Enum.Font.GothamBold; ClsBtn.BorderSizePixel=0; ClsBtn.ZIndex=12; ClsBtn.Parent=HDR
    Crn(ClsBtn,10)
    _G.__KH4Min=MinBtn; _G.__KH4Cls=ClsBtn
end
local hdrDrag,hdrDS,hdrSP=false,nil,nil
HDR.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        hdrDrag=true; hdrDS=inp.Position; hdrSP=MF.Position end
end)
HDR.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then hdrDrag=false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if hdrDrag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local vp=Cam.ViewportSize; local d=inp.Position-hdrDS
        MF.Position=UDim2.new(math.clamp(hdrSP.X.Scale+d.X/vp.X,0.08,0.92),0,math.clamp(hdrSP.Y.Scale+d.Y/vp.Y,0.08,0.92),0)
    end
end)

-- TABS
local TABS={
    {id="Fling",col=C.Red},{id="Troll",col=C.Pink},{id="Move",col=C.Green},
    {id="Anim",col=C.Purple},{id="Music",col=C.Blue},{id="Protect",col=C.Yellow},
    {id="ESP",col=C.Teal},{id="Util",col=C.Orange},{id="Players",col=Color3.fromRGB(255,100,50)},
}
local TabBar=Fr(MF,UDim2.new(1,0,0,48),UDim2.new(0,0,0,56),C.Panel,0); TabBar.ZIndex=11
local TabScr=Instance.new("ScrollingFrame"); TabScr.Size=UDim2.new(1,0,1,0)
TabScr.BackgroundTransparency=1; TabScr.BorderSizePixel=0; TabScr.ScrollBarThickness=0
TabScr.ScrollingDirection=Enum.ScrollingDirection.X; TabScr.CanvasSize=UDim2.new(0,#TABS*90,0,0)
TabScr.ZIndex=11; TabScr.Parent=TabBar; Pad(TabScr,5,5,8,8); HList(TabScr,5)
local TabBtns={}
local PC=Fr(MF,UDim2.new(1,0,1,-104),UDim2.new(0,0,0,104),C.BG,1); PC.ZIndex=10; PC.ClipsDescendants=true

local function SetTab(id)
    ST.Tab=id
    for _,info in ipairs(TABS) do
        local b=TabBtns[info.id]; if not b then continue end
        if info.id==id then Tw(b,{BackgroundColor3=info.col,BackgroundTransparency=0.1},0.2); b.TextColor3=C.White
        else Tw(b,{BackgroundColor3=C.Card,BackgroundTransparency=0.5},0.2); b.TextColor3=C.Dim end
    end
    for _,ch in pairs(PC:GetChildren()) do
        if ch:IsA("ScrollingFrame") then ch.Visible=ch.Name==id end
    end
end
for i,info in ipairs(TABS) do
    local b=Instance.new("TextButton"); b.Name=info.id; b.Size=UDim2.new(0,80,0,38)
    b.BackgroundColor3=C.Card; b.BackgroundTransparency=0.5; b.Text=info.id
    b.TextColor3=C.Dim; b.TextSize=12; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.LayoutOrder=i; b.ZIndex=12; b.Parent=TabScr
    Crn(b,12); TabBtns[info.id]=b
    b.MouseButton1Click:Connect(function() SetTab(info.id) end)
end

-- ============================================================
-- PANEL COMPONENTS
-- ============================================================
local function MakePanel(name)
    local s=Scr(PC,UDim2.new(1,0,1,0)); s.Name=name; s.Visible=false; s.ZIndex=11
    Pad(s,10,20,10,10)
    local layout=VList(s,8)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+40)
    end)
    return s
end
local function Sec(parent,text,col)
    col=col or C.Accent
    local f=Fr(parent,UDim2.new(1,0,0,30),nil,C.Panel,0); f.ZIndex=12; Crn(f,8)
    local bar=Fr(f,UDim2.new(0,3,0,18),UDim2.new(0,0,0.5,-9),col,0); Crn(bar,UDim.new(1,0)); bar.ZIndex=13
    local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,-14,1,0); l.Position=UDim2.new(0,10,0,0)
    l.BackgroundTransparency=1; l.Text=text; l.TextSize=12; l.Font=Enum.Font.GothamBold
    l.TextColor3=col; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=13; l.Parent=f; return f
end
local function Tog(parent,text,default,onTog,col)
    col=col or C.Accent; local on=default or false
    local f=Fr(parent,UDim2.new(1,0,0,56),nil,C.Card,0); f.ZIndex=12; Crn(f,14); Strk(f,C.Border,1)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-70,1,0); lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextSize=13; lbl.Font=Enum.Font.GothamSemibold
    lbl.TextColor3=C.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextWrapped=true; lbl.ZIndex=13; lbl.Parent=f
    local pill=Fr(f,UDim2.new(0,50,0,26),UDim2.new(1,-62,0.5,-13),C.Off,0); Crn(pill,UDim.new(1,0)); pill.ZIndex=13
    local knob=Fr(pill,UDim2.new(0,20,0,20),UDim2.new(0,3,0.5,-10),C.White,0); Crn(knob,UDim.new(1,0)); knob.ZIndex=14
    local function upd()
        if on then Tw(pill,{BackgroundColor3=col},0.2); Tw(knob,{Position=UDim2.new(0,27,0.5,-10)},0.2)
        else Tw(pill,{BackgroundColor3=C.Off},0.2); Tw(knob,{Position=UDim2.new(0,3,0.5,-10)},0.2) end
    end
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,1,0); btn.BackgroundTransparency=1
    btn.Text=""; btn.ZIndex=15; btn.Parent=f
    btn.MouseButton1Click:Connect(function() on=not on; upd(); if onTog then onTog(on) end end)
    upd(); return f, function() return on end, function(v) on=v; upd() end
end
local function Btn(parent,text,onClick,col,h)
    col=col or C.Accent; h=h or 52
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,h)
    b.BackgroundColor3=col; b.BackgroundTransparency=0.2; b.Text=text
    b.TextColor3=C.White; b.TextSize=13; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.ZIndex=12; b.TextWrapped=true; b.Parent=parent
    Crn(b,14)
    b.MouseButton1Click:Connect(function()
        Tw(b,{BackgroundTransparency=0},0.1); task.wait(0.12); Tw(b,{BackgroundTransparency=0.2},0.2)
        if onClick then pcall(onClick) end
    end)
    b.MouseEnter:Connect(function() Tw(b,{BackgroundTransparency=0.05},0.15) end)
    b.MouseLeave:Connect(function() Tw(b,{BackgroundTransparency=0.2},0.15) end)
    return b
end
local function Sldr(parent,text,minv,maxv,defv,onCh,col)
    col=col or C.Accent; local val=defv
    local f=Fr(parent,UDim2.new(1,0,0,70),nil,C.Card,0); f.ZIndex=12; Crn(f,14); Strk(f,C.Border,1)
    local vl=Instance.new("TextLabel"); vl.Size=UDim2.new(1,-14,0,22); vl.Position=UDim2.new(0,14,0,6)
    vl.BackgroundTransparency=1; vl.Text=text..": "..math.floor(val); vl.TextSize=13; vl.Font=Enum.Font.GothamBold
    vl.TextColor3=C.Text; vl.TextXAlignment=Enum.TextXAlignment.Left; vl.ZIndex=13; vl.Parent=f
    local track=Fr(f,UDim2.new(1,-28,0,6),UDim2.new(0,14,0,44),C.Off,0); Crn(track,UDim.new(1,0)); track.ZIndex=13
    local fill=Fr(track,UDim2.new((defv-minv)/(maxv-minv),0,1,0),nil,col,0); Crn(fill,UDim.new(1,0)); fill.ZIndex=14
    local knob=Fr(track,UDim2.new(0,18,0,18),UDim2.new((defv-minv)/(maxv-minv),0,0.5,-9),col,0); Crn(knob,UDim.new(1,0)); knob.ZIndex=15; Strk(knob,C.White,2)
    local sliding=false
    local function upd(pos)
        local ab=track.AbsolutePosition; local sz=track.AbsoluteSize
        local r=math.clamp((pos.X-ab.X)/sz.X,0,1)
        val=minv+(maxv-minv)*r; fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,-9,0.5,-9)
        vl.Text=text..": "..math.floor(val); if onCh then onCh(val) end
    end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliding=true; upd(inp.Position) end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then sliding=false end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then upd(inp.Position) end
    end)
    return f
end
local function Inp(parent,ph,onSub,col)
    col=col or C.Accent
    local f=Fr(parent,UDim2.new(1,0,0,56),nil,C.Card,0); f.ZIndex=12; Crn(f,14); Strk(f,C.Border,1)
    local tb=Instance.new("TextBox"); tb.Size=UDim2.new(1,-70,0,38); tb.Position=UDim2.new(0,8,0.5,-19)
    tb.BackgroundColor3=C.BG; tb.BackgroundTransparency=0.3; tb.Text=""; tb.PlaceholderText=ph or "Enter..."
    tb.PlaceholderColor3=C.Dim; tb.TextColor3=C.Text; tb.TextSize=13; tb.Font=Enum.Font.Gotham
    tb.BorderSizePixel=0; tb.ClearTextOnFocus=false; tb.ZIndex=13; tb.Parent=f; Crn(tb,10)
    local go=Instance.new("TextButton"); go.Size=UDim2.new(0,52,0,38); go.Position=UDim2.new(1,-60,0.5,-19)
    go.BackgroundColor3=col; go.BackgroundTransparency=0.2; go.Text="OK"
    go.TextColor3=C.White; go.TextSize=13; go.Font=Enum.Font.GothamBold; go.BorderSizePixel=0; go.ZIndex=13; go.Parent=f; Crn(go,10)
    go.MouseButton1Click:Connect(function() if onSub then onSub(tb.Text) end end)
    tb.FocusLost:Connect(function(enter) if enter and onSub then onSub(tb.Text) end end)
    return f,tb
end
local function TgtPicker(parent,label,onChange)
    local f=Fr(parent,UDim2.new(1,0,0,56),nil,C.Card,0); f.ZIndex=12; Crn(f,14); Strk(f,C.Border,1)
    local lbl2=Instance.new("TextLabel"); lbl2.Size=UDim2.new(1,-80,1,0); lbl2.Position=UDim2.new(0,14,0,0)
    lbl2.BackgroundTransparency=1; lbl2.Text=label or "Target: Everyone"; lbl2.TextSize=13
    lbl2.Font=Enum.Font.GothamSemibold; lbl2.TextColor3=C.Text; lbl2.TextXAlignment=Enum.TextXAlignment.Left
    lbl2.TextWrapped=true; lbl2.ZIndex=13; lbl2.Parent=f
    local idx=0
    local nxt=Instance.new("TextButton"); nxt.Size=UDim2.new(0,62,0,38); nxt.Position=UDim2.new(1,-70,0.5,-19)
    nxt.BackgroundColor3=C.Accent; nxt.BackgroundTransparency=0.3; nxt.Text="Next >"
    nxt.TextColor3=C.White; nxt.TextSize=12; nxt.Font=Enum.Font.GothamBold; nxt.BorderSizePixel=0; nxt.ZIndex=13; nxt.Parent=f; Crn(nxt,10)
    nxt.MouseButton1Click:Connect(function()
        local list={"Everyone"}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then list[#list+1]=p.Name end end
        idx=(idx % #list)+1; local name=list[idx]; lbl2.Text=(label or "Target")..": "..name
        ST.Target=name=="Everyone" and nil or Players:FindFirstChild(name)
        if onChange then onChange(ST.Target) end
    end)
    return f
end

-- ============================================================
-- BUILD FLING PANEL
-- ============================================================
local FlingPanel=MakePanel("Fling")
Sec(FlingPanel,"IY Fling System (BodyAngularVelocity 99999)",C.Red)
Tog(FlingPanel,"FLING (IY exact - toggle)",false,function(on)
    if on then DoFling() else StopFling() end
end,C.Red)
Tog(FlingPanel,"WalkFling (walk = fling, IY exact)",false,function(on)
    if on then DoWalkFling() else StopWalkFling() end
end,C.Red)
Btn(FlingPanel,"Super Fling (velocity burst x5)",function()
    if not LP.Character then return end
    local root=GetRoot(); if not root then return end
    task.spawn(function()
        for i=1,5 do
            root.Velocity=Vector3.new(math.random(-1,1)*math.random(5000,9999),math.random(2000,9999),math.random(-1,1)*math.random(5000,9999))
            task.wait(0.05)
        end
    end)
    Notify("SuperFling","Activated!",2)
end,Color3.fromRGB(255,30,30))

Sec(FlingPanel,"IY Spin (BodyAngularVelocity named Spinning)",C.Pink)
Sldr(FlingPanel,"Spin Speed",1,200,20,function(v) ST.SpinSpeed=v end,C.Pink)
Tog(FlingPanel,"Spin Self (IY exact)",false,function(on)
    if on then DoSpin(ST.SpinSpeed) else StopSpin() end
end,C.Pink)

Sec(FlingPanel,"Fling Others",C.Red)
TgtPicker(FlingPanel,"Fling Target",function(p) ST.Target=p end)
Btn(FlingPanel,"Fling Target (velocity burst)",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do
        if p~=LP and p.Character then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root then task.spawn(function()
                for i=1,5 do root.Velocity=Vector3.new(math.random(-1,1)*6000,5000,math.random(-1,1)*6000); task.wait(0.05) end
            end) end
        end
    end
    Notify("Fling","Flung target!",2)
end,C.Red)
Btn(FlingPanel,"Launch UP",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then Launch(p,1500) end end
end,C.Orange)
Btn(FlingPanel,"Knockback",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then Knockback(p,300) end end
end,C.Orange)
Btn(FlingPanel,"Explode Target",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then Explode(p) end end
end,C.Red)

Sec(FlingPanel,"Loop Commands",C.Red)
Tog(FlingPanel,"Loop Fling Target",false,function(on)
    if on and ST.Target then StartLoopFling(ST.Target,500) else StopLoopFling() end
end,C.Red)
Tog(FlingPanel,"Loop Kill Target",false,function(on)
    if on and ST.Target then StartLoopKill(ST.Target) else StopLoopKill() end
end,C.Red)

-- ============================================================
-- BUILD TROLL PANEL
-- ============================================================
local TrollPanel=MakePanel("Troll")

Sec(TrollPanel,"Target",C.Pink)
TgtPicker(TrollPanel,"Troll Target",function(p) ST.Target=p end)

Sec(TrollPanel,"IY Headsit (exact)",C.Pink)
Tog(TrollPanel,"Headsit Target (IY exact)",false,function(on)
    if on and ST.Target then DoHeadsit(ST.Target) else StopHeadsit() end
end,C.Pink)

Sec(TrollPanel,"IY Control",C.Pink)
Tog(TrollPanel,"ClientBring (loop TP target to me)",false,function(on)
    if on and ST.Target then StartClientBring(ST.Target) else StopClientBring() end
end,C.Pink)
Tog(TrollPanel,"Orbit Target (IY exact)",false,function(on)
    if on and ST.Target then DoOrbit(ST.Target,0.3,6) else StopOrbit() end
end,C.Pink)
Tog(TrollPanel,"Stare At Target",false,function(on)
    if on and ST.Target then StartStare(ST.Target) else StopStare() end
end,C.Pink)
Tog(TrollPanel,"Loop OOF Sound (IY exact)",false,function(on)
    if on then StartLoopOof() else StopLoopOof() end
end,C.Yellow)

Sec(TrollPanel,"IY Animations",C.Purple)
Tog(TrollPanel,"Bang (IY anim 148840371 / 5918726674)",false,function(on)
    if on then DoBang(ST.Target,3) else StopBang() end
end,C.Purple)
Tog(TrollPanel,"Carpet (IY anim 282574440, R6 only)",false,function(on)
    if on and ST.Target then DoCarpet(ST.Target) else StopCarpet() end
end,C.Purple)
Tog(TrollPanel,"Spasm (IY anim 33796059 speed 99, R6)",false,function(on)
    if on then DoSpasm() else StopSpasm() end
end,C.Purple)
Btn(TrollPanel,"HeadThrow (IY anim 35154961, R6)",function() DoHeadThrow() end,C.Purple)

Sec(TrollPanel,"Position Tricks",C.Pink)
Btn(TrollPanel,"TP To Target",function()
    if ST.Target and ST.Target.Character then
        local myR=GetRoot(); local tR=ST.Target.Character:FindFirstChild("HumanoidRootPart")
        if myR and tR then myR.CFrame=tR.CFrame*CFrame.new(0,0,4) end
    end
end,C.Accent)
Btn(TrollPanel,"Bring Target To Me",function()
    if ST.Target and ST.Target.Character then
        local myR=GetRoot(); local tR=ST.Target.Character:FindFirstChild("HumanoidRootPart")
        if myR and tR then tR.CFrame=myR.CFrame*CFrame.new(0,0,4) end
    end
end,C.Accent)
Btn(TrollPanel,"Swap Positions",function()
    if ST.Target and ST.Target.Character then
        local myR=GetRoot(); local tR=ST.Target.Character:FindFirstChild("HumanoidRootPart")
        if myR and tR then local mc=myR.CFrame; myR.CFrame=tR.CFrame; tR.CFrame=mc end
    end
end,C.Accent)
Btn(TrollPanel,"Scare Target (IY exact)",function()
    if ST.Target then DoScare(ST.Target) end
end,C.Pink)
Btn(TrollPanel,"Trip Self (IY exact)",function() DoTrip() end,C.Pink)

Sec(TrollPanel,"Freeze & Effects",C.Accent)
Btn(TrollPanel,"Freeze Target",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then Freeze(p) end end; Notify("Troll","Frozen!",2)
end,C.Accent)
Btn(TrollPanel,"Thaw Target",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do Thaw(p) end; Notify("Troll","Thawed!",2)
end,C.Accent)
Btn(TrollPanel,"Blind (8s)",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then Blind(p,8) end end
end,C.Yellow)
Btn(TrollPanel,"Fire ON",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do SetFX(p,"Fire",true) end
end,Color3.fromRGB(255,120,20))
Btn(TrollPanel,"Fire OFF",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do SetFX(p,"Fire",false) end
end,C.Dim)
Btn(TrollPanel,"Sparkles ON",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do SetFX(p,"Sparkles",true) end
end,C.Yellow)
Btn(TrollPanel,"Smoke ON",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do SetFX(p,"Smoke",true) end
end,C.Dim)
Btn(TrollPanel,"Mute Boombox",function()
    if ST.Target then MuteBoombox(ST.Target,true)
    else MuteBoombox(nil,true) end
end,C.Accent)
Btn(TrollPanel,"Unmute Boombox",function()
    if ST.Target then MuteBoombox(ST.Target,false)
    else MuteBoombox(nil,false) end
end,C.Accent)

Sec(TrollPanel,"Size Control",C.Orange)
Sldr(TrollPanel,"Target Size",0.05,20,1,function(v)
    if ST.Target then SetSize(ST.Target,v) end
end,C.Orange)
Btn(TrollPanel,"Tiny (0.05x)",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then SetSize(p,0.05) end end
end,C.Orange)
Btn(TrollPanel,"GIANT (10x)",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then SetSize(p,10) end end
end,C.Orange)
Btn(TrollPanel,"MEGA (25x)",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then SetSize(p,25) end end
end,Color3.fromRGB(255,80,0))
Btn(TrollPanel,"Reset All Sizes",function()
    for _,p in ipairs(Players:GetPlayers()) do SetSize(p,1) end
end,C.Green)
Sldr(TrollPanel,"My Size",0.05,15,1,function(v) SetSize(LP,v) end,C.Teal)

Sec(TrollPanel,"Chat",C.Yellow)
local _,chatTB=Inp(TrollPanel,"Message to say...",nil,C.Yellow)
Btn(TrollPanel,"Say Message",function()
    if chatTB and chatTB.Text~="" then ChatMsg(chatTB.Text) end
end,C.Yellow)
local _,spamTB=Inp(TrollPanel,"Spam message...",nil,C.Yellow)
Tog(TrollPanel,"Loop Chat Spam (2s)",false,function(on)
    if on and spamTB and spamTB.Text~="" then StartSpam(spamTB.Text,2)
    else StopSpam() end
end,C.Yellow)
local _,nameTB=Inp(TrollPanel,"New display name...",nil,C.Teal)
Btn(TrollPanel,"Set Nametag",function()
    if nameTB and nameTB.Text~="" then SetNametag(nameTB.Text) end
end,C.Teal)
Btn(TrollPanel,"No Face",function() NoFace() end,C.Teal)

Sec(TrollPanel,"Hats",C.Purple)
Sldr(TrollPanel,"HatSpin Speed",1,20,5,function(v)
    if hatSpinConn then StartHatSpin(v) end
end,C.Purple)
Tog(TrollPanel,"HatSpin (IY hatspin)",false,function(on)
    if on then StartHatSpin(5) else StopHatSpin() end
end,C.Purple)
Btn(TrollPanel,"Drop Hats (IY drophats)",function() DropHats() end,C.Purple)
Btn(TrollPanel,"Delete Hats (IY deletehats)",function() DeleteHats() end,C.Red)

Sec(TrollPanel,"Limbs (IY nolimbs/noarms/nolegs)",C.Red)
Btn(TrollPanel,"Remove Arms",function() RemoveLimbs("arms") end,C.Red)
Btn(TrollPanel,"Remove Legs",function() RemoveLimbs("legs") end,C.Red)
Btn(TrollPanel,"Remove All Limbs",function() RemoveLimbs("all") end,Color3.fromRGB(200,0,0))

-- ============================================================
-- BUILD MOVE PANEL
-- ============================================================
local MovePanel=MakePanel("Move")

Sec(MovePanel,"IY Fly (mobile ControlModule + PC WASD)",C.Green)
Tog(MovePanel,"Fly (IY exact - W/A/S/D, Q=down, E=up)",false,function(on)
    ST.Flying=on; if on then StartFly() else StopFly() end
end,C.Green)
Sldr(MovePanel,"Fly Speed (1=50u/s)",0.1,10,1,function(v) iyflyspeed=v end,C.Green)

Sec(MovePanel,"IY Noclip / WallTP",C.Green)
Tog(MovePanel,"Noclip (IY RunService.Stepped exact)",false,function(on)
    if on then DoNoclip() else DoClip() end
end,C.Green)
Tog(MovePanel,"WallTP (walk through walls auto-TP)",false,function(on)
    if on then
        local torso=GetTorso(); if not torso then return end
        if walltpTouch then walltpTouch:Disconnect() end
        walltpTouch=torso.Touched:Connect(function(hit)
            local root=GetRoot(); local hum=GetHum()
            if hit:IsA("BasePart") and hum and root then
                if hit.Position.Y>root.Position.Y-hum.HipHeight then
                    root.CFrame=hit.CFrame*CFrame.new(root.CFrame.LookVector.X,hit.Size.Y/2+hum.HipHeight,root.CFrame.LookVector.Z)
                end
            end
        end)
    else
        if walltpTouch then walltpTouch:Disconnect(); walltpTouch=nil end
    end
end,C.Green)

Sec(MovePanel,"Movement",C.Green)
Tog(MovePanel,"Infinite Jump (IY infjump)",false,function(on)
    ST.InfJump=on; SetInfJump(on)
end,C.Green)
Tog(MovePanel,"FlyJump (IY flyjump - jump in air)",false,function(on)
    SetFlyJump(on)
end,C.Green)
Tog(MovePanel,"Click Teleport",false,function(on)
    ST.ClickTP=on; SetClickTP(on)
end,C.Green)
Tog(MovePanel,"No Rotate (IY norotate)",false,function(on)
    SetNoRotate(on)
end,C.Dim)
Tog(MovePanel,"Stun / PlatformStand (IY stun)",false,function(on)
    SetStun(on)
end,C.Dim)

Sldr(MovePanel,"Walk Speed",0,500,16,function(v)
    ST.Speed=v; local hum=GetHum(); if hum then hum.WalkSpeed=v end
end,C.Green)
Sldr(MovePanel,"Jump Power",0,500,50,function(v)
    ST.Jump=v; local hum=GetHum(); if hum then hum.JumpPower=v end
end,C.Green)
Sldr(MovePanel,"Hip Height",0,50,0,function(v)
    local hum=GetHum(); if hum then pcall(function() hum.HipHeight=v end) end
end,C.Green)
Sldr(MovePanel,"Max Slope Angle",0,89,89,function(v)
    local hum=GetHum(); if hum then pcall(function() hum.MaxSlopeAngle=v end) end
end,C.Green)

Sec(MovePanel,"Speed Presets",C.Green)
Btn(MovePanel,"Normal (16)",function() local h=GetHum(); if h then h.WalkSpeed=16 end end,C.Green)
Btn(MovePanel,"Fast (100)",function() local h=GetHum(); if h then h.WalkSpeed=100 end end,C.Green)
Btn(MovePanel,"Sonic (300)",function() local h=GetHum(); if h then h.WalkSpeed=300 end end,C.Green)

Sec(MovePanel,"IY Loop Speed/JP",C.Teal)
local _,lspTB=Inp(MovePanel,"Speed value...",nil,C.Teal)
Tog(MovePanel,"Loop Speed (IY loopspeed)",false,function(on)
    if on and lspTB then local v=tonumber(lspTB.Text) or 100; StartLoopSpeed(v)
    else StopLoopSpeed() end
end,C.Teal)
local _,ljpTB=Inp(MovePanel,"JP value...",nil,C.Teal)
Tog(MovePanel,"Loop JumpPower (IY loopjp)",false,function(on)
    if on and ljpTB then local v=tonumber(ljpTB.Text) or 100; StartLoopJP(v)
    else StopLoopJP() end
end,C.Teal)

Sec(MovePanel,"Checkpoints (IY waypoints)",C.Teal)
local cpList={}
local cpLbl=Instance.new("TextLabel"); cpLbl.Size=UDim2.new(1,0,0,22)
cpLbl.BackgroundTransparency=1; cpLbl.Text="No checkpoints"; cpLbl.TextSize=12
cpLbl.Font=Enum.Font.Gotham; cpLbl.TextColor3=C.Dim; cpLbl.TextXAlignment=Enum.TextXAlignment.Left
cpLbl.ZIndex=12; cpLbl.Parent=MovePanel

Btn(MovePanel,"Save Checkpoint",function()
    local root=GetRoot(); if not root then return end
    cpList[#cpList+1]=root.CFrame; cpLbl.Text=#cpList.." checkpoint(s) saved"
    Notify("CP","Checkpoint "..#cpList.." saved",2)
end,C.Teal)
Btn(MovePanel,"Load Last Checkpoint",function()
    if #cpList==0 then Notify("CP","None saved!",2); return end
    local root=GetRoot(); if root then root.CFrame=cpList[#cpList] end
    Notify("CP","Loaded!",2)
end,C.Teal)
Btn(MovePanel,"Clear Checkpoints",function()
    cpList={}; cpLbl.Text="No checkpoints"; Notify("CP","Cleared",2)
end,C.Red)

Sec(MovePanel,"Teleport (IY goto)",C.Accent)
local _,coordTB=Inp(MovePanel,"X Y Z  (e.g. 0 100 0)",nil,C.Accent)
Btn(MovePanel,"Teleport To Coords",function()
    local root=GetRoot(); if not root or not coordTB then return end
    local nums={}; for n in coordTB.Text:gmatch("[%-]?%d+%.?%d*") do nums[#nums+1]=tonumber(n) end
    if #nums>=3 then root.CFrame=CFrame.new(nums[1],nums[2],nums[3]); Notify("Move","Teleported!",2) end
end,C.Accent)
Btn(MovePanel,"TP To Spawn",function()
    local sp=workspace:FindFirstChildOfClass("SpawnLocation"); local root=GetRoot()
    if sp and root then root.CFrame=sp.CFrame+Vector3.new(0,5,0) end
end,C.Accent)
Btn(MovePanel,"WalkTo Target",function()
    if ST.Target then WalkTo(ST.Target) end
end,C.Accent)
Btn(MovePanel,"Get My Position",function()
    local root=GetRoot()
    if root then
        local p=root.Position
        Notify("Position",string.format("X:%.1f Y:%.1f Z:%.1f",p.X,p.Y,p.Z),6)
    end
end,C.Dim)

Sec(MovePanel,"My Size",C.Orange)
Sldr(MovePanel,"My Body Size",0.05,15,1,function(v) SetSize(LP,v) end,C.Orange)
Btn(MovePanel,"Normal Size",function() SetSize(LP,1) end,C.Green)

-- ============================================================
-- BUILD ANIM PANEL
-- ============================================================
local AnimPanel=MakePanel("Anim")

Sec(AnimPanel,"IY Dances (exact IDs)",C.Purple)
for i=1,12 do
    Btn(AnimPanel,"Dance "..i.." (ID "..danceIDs[i]..")",function() Dance(i) end,Color3.fromRGB(80+i*8,60,200),48)
end
Btn(AnimPanel,"Stop All Dances",function() StopDance() end,C.Dim)

Sec(AnimPanel,"Custom Animation",C.Purple)
local _,animTB=Inp(AnimPanel,"Animation ID...",nil,C.Purple)
local _,animSpdTB=Inp(AnimPanel,"Anim Speed (default 1)...",nil,C.Purple)
Btn(AnimPanel,"Play Animation",function()
    if animTB and animTB.Text~="" then
        local id=animTB.Text:match("%d+"); if not id then return end
        local spd=tonumber(animSpdTB and animSpdTB.Text) or 1
        PlayAnim(id,spd)
    end
end,C.Purple)
local _,animSpdSlider=Sldr(AnimPanel,"Adjust All Anim Speed",0.1,10,1,function(v)
    SetAnimSpeed(v)
end,C.Purple)

Sec(AnimPanel,"IY Emotes",C.Purple)
local emoteList={{"Wave","507770239"},{"Point","507770453"},{"Cheer","507770677"},{"Laugh","507770818"},{"Dance1","507771019"},{"Dance2","507771955"},{"Salute","3360692915"},{"Shrug","3984580446"}}
for _,em in ipairs(emoteList) do
    Btn(AnimPanel,"Emote: "..em[1],function()
        local hum=GetHum(); if not hum then return end
        local anim=Instance.new("Animation"); anim.AnimationId="rbxassetid://"..em[2]
        local track=hum.Animator:LoadAnimation(anim); track:Play()
        danceTracks[#danceTracks+1]=track
    end,C.Purple,46)
end

Sec(AnimPanel,"Copy/Control",C.Purple)
Btn(AnimPanel,"Copy Target's Animation",function()
    if ST.Target then CopyAnim(ST.Target) end
end,C.Purple)
Btn(AnimPanel,"Stop All Animations",function()
    local hum=GetHum(); if not hum then return end
    for _,t in pairs(hum.Animator:GetPlayingAnimationTracks()) do t:Stop() end
    Notify("Anim","All animations stopped",2)
end,C.Dim)
Tog(AnimPanel,"No Animations (IY noanim)",false,function(on)
    local char=GetChar(); if not char then return end
    local anim=char:FindFirstChild("Animate")
    if anim then anim.Disabled=on end
end,C.Dim)

-- ============================================================
-- BUILD MUSIC PANEL
-- ============================================================
local MusicPanel=MakePanel("Music")

local npCard=Fr(MusicPanel,UDim2.new(1,0,0,76),nil,C.Card,0); npCard.ZIndex=12; Crn(npCard,14); Strk(npCard,C.Blue,1)
NPLabel=Instance.new("TextLabel"); NPLabel.Size=UDim2.new(1,-14,0,26); NPLabel.Position=UDim2.new(0,10,0,8)
NPLabel.BackgroundTransparency=1; NPLabel.Text="Now Playing: --"; NPLabel.TextSize=13; NPLabel.Font=Enum.Font.GothamBold
NPLabel.TextColor3=C.Blue; NPLabel.TextXAlignment=Enum.TextXAlignment.Left; NPLabel.TextWrapped=true; NPLabel.ZIndex=13; NPLabel.Parent=npCard
local sLbl=Instance.new("TextLabel"); sLbl.Size=UDim2.new(1,-14,0,16); sLbl.Position=UDim2.new(0,10,0,38)
sLbl.BackgroundTransparency=1; sLbl.Text="Stopped"; sLbl.TextSize=11; sLbl.Font=Enum.Font.GothamBold
sLbl.TextColor3=C.Red; sLbl.TextXAlignment=Enum.TextXAlignment.Left; sLbl.ZIndex=13; sLbl.Parent=npCard
local vLbl=Instance.new("TextLabel"); vLbl.Size=UDim2.new(0.5,0,0,14); vLbl.Position=UDim2.new(0.5,0,0,57)
vLbl.BackgroundTransparency=1; vLbl.Text="Vol: 80%"; vLbl.TextSize=10; vLbl.Font=Enum.Font.Gotham
vLbl.TextColor3=C.Dim; vLbl.TextXAlignment=Enum.TextXAlignment.Left; vLbl.ZIndex=13; vLbl.Parent=npCard

local ctrlRow=Fr(MusicPanel,UDim2.new(1,0,0,54),nil,C.Card,0); ctrlRow.ZIndex=12; Crn(ctrlRow,14)
HList(ctrlRow,5,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center); Pad(ctrlRow,6,6,8,8)
local function CB(t,col,fn)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0,64,0,42)
    b.BackgroundColor3=col; b.BackgroundTransparency=0.2; b.Text=t; b.TextColor3=C.White
    b.TextSize=12; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=13; b.Parent=ctrlRow; Crn(b,10)
    b.MouseButton1Click:Connect(function() if fn then fn() end end); return b
end
CB("PREV",C.Blue,function()
    ST.SongIdx=((ST.SongIdx-2) % #SONGS)+1; local s=SONGS[ST.SongIdx]; PlaySong(s.id,s.n)
    sLbl.Text="Playing"; sLbl.TextColor3=C.Green
end)
CB("PLAY",C.Green,function()
    if ST.MusicOn then MusicSound:Pause(); ST.MusicOn=false; sLbl.Text="Paused"; sLbl.TextColor3=C.Yellow
    else if ST.SongID then MusicSound:Play(); ST.MusicOn=true
         else local s=SONGS[ST.SongIdx]; PlaySong(s.id,s.n) end
         sLbl.Text="Playing"; sLbl.TextColor3=C.Green end
end)
CB("STOP",C.Red,function() StopMusic(); sLbl.Text="Stopped"; sLbl.TextColor3=C.Red end)
CB("NEXT",C.Blue,function()
    ST.SongIdx=(ST.SongIdx % #SONGS)+1; local s=SONGS[ST.SongIdx]; PlaySong(s.id,s.n)
    sLbl.Text="Playing"; sLbl.TextColor3=C.Green
end)

Tog(MusicPanel,"Loop Song",false,function(on) ST.MusicLoop=on; MusicSound.Looped=on end,C.Blue)
Sldr(MusicPanel,"Volume",0,100,80,function(v)
    ST.MusicVol=v/100; MusicSound.Volume=ST.MusicVol; vLbl.Text="Vol: "..v.."%"
end,C.Blue)

Sec(MusicPanel,"Custom ID",C.Blue)
local _,custTB=Inp(MusicPanel,"Roblox Sound ID...",nil,C.Blue)
Btn(MusicPanel,"Play Custom ID",function()
    if custTB then local id=custTB.Text:match("%d+")
        if id then PlaySong(id,"Custom #"..id); sLbl.Text="Playing"; sLbl.TextColor3=C.Green end
    end
end,C.Blue)

Sec(MusicPanel,"Library ("..#SONGS.." songs)",C.Blue)
for i,song in ipairs(SONGS) do
    local row=Fr(MusicPanel,UDim2.new(1,0,0,52),nil,C.Card,i%2==0 and 0.4 or 0.6); row.ZIndex=12; Crn(row,10)
    local sn=Instance.new("TextLabel"); sn.Size=UDim2.new(1,-80,0,26); sn.Position=UDim2.new(0,8,0,4)
    sn.BackgroundTransparency=1; sn.Text=i..". "..song.n; sn.TextSize=12; sn.Font=Enum.Font.GothamSemibold
    sn.TextColor3=C.Text; sn.TextXAlignment=Enum.TextXAlignment.Left; sn.ZIndex=13; sn.Parent=row
    local pb=Instance.new("TextButton"); pb.Size=UDim2.new(0,56,0,34); pb.Position=UDim2.new(1,-64,0.5,-17)
    pb.BackgroundColor3=C.Blue; pb.BackgroundTransparency=0.2; pb.Text="PLAY"
    pb.TextColor3=C.White; pb.TextSize=11; pb.Font=Enum.Font.GothamBold; pb.BorderSizePixel=0; pb.ZIndex=13; pb.Parent=row
    Crn(pb,10); pb.MouseButton1Click:Connect(function()
        ST.SongIdx=i; PlaySong(song.id,song.n); sLbl.Text="Playing"; sLbl.TextColor3=C.Green
    end)
end

-- ============================================================
-- BUILD PROTECT PANEL
-- ============================================================
local ProtPanel=MakePanel("Protect")

Sec(ProtPanel,"Protection",C.Yellow)
Tog(ProtPanel,"God Mode (loop health)",false,function(on) ST.GodMode=on; SetGod(on) end,C.Yellow)
Tog(ProtPanel,"Invisible (LocalTransparency)",false,function(on) ST.Invisible=on; SetInvisible(on) end,C.Yellow)
Tog(ProtPanel,"Fullbright (IY fullbright)",false,function(on) SetFullbright(on) end,C.Yellow)
Tog(ProtPanel,"Anti-Void (IY antivoid exact)",false,function(on)
    if on then StartAntiVoid() else StopAntiVoid() end
end,C.Teal)
Tog(ProtPanel,"Infinite Jump",false,function(on) SetInfJump(on) end,C.Green)
Tog(ProtPanel,"Anti-AFK",false,function(on)
    if on then
        _G.__KH4AFK=RunService.Heartbeat:Connect(function()
            pcall(function()
                local VU=game:GetService("VirtualUser")
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end)
    else if _G.__KH4AFK then _G.__KH4AFK:Disconnect(); _G.__KH4AFK=nil end end
end,C.Teal)

Sec(ProtPanel,"IY Anchor/Unanchor",C.Yellow)
Btn(ProtPanel,"Anchor Self (IY anchor)",function()
    local root=GetRoot(); if root then root.Anchored=true end; Notify("Protect","Anchored",2)
end,C.Yellow)
Btn(ProtPanel,"Unanchor Self (IY unanchor)",function()
    local root=GetRoot(); if root then root.Anchored=false end; Notify("Protect","Unanchored",2)
end,C.Yellow)
Btn(ProtPanel,"Reset Velocity",function()
    local root=GetRoot(); if root then root.Velocity=Vector3.zero end; Notify("Protect","Velocity reset",2)
end,C.Yellow)
Btn(ProtPanel,"Full Heal",function()
    local hum=GetHum(); if hum then hum.Health=hum.MaxHealth end; Notify("Protect","Healed!",2)
end,C.Green)
Btn(ProtPanel,"Reset (IY reset)",function()
    local hum=GetHum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Dead)
    else local char=GetChar(); if char then char:BreakJoints() end end
end,C.Red)
Btn(ProtPanel,"Respawn (IY respawn)",function() LP:LoadCharacter() end,C.Red)

Sec(ProtPanel,"Lighting (IY fullbright/night/day/nofog)",C.Orange)
Btn(ProtPanel,"Night (IY night)",function()
    Lighting.ClockTime=0; Lighting.Brightness=0.3
    Notify("Lighting","Night mode",2)
end,Color3.fromRGB(20,20,60))
Btn(ProtPanel,"Day (IY day)",function()
    Lighting.ClockTime=14; Lighting.Brightness=2
    Notify("Lighting","Day mode",2)
end,Color3.fromRGB(255,220,100))
Btn(ProtPanel,"No Fog (IY nofog)",function()
    Lighting.FogEnd=999999; Lighting.FogStart=999999
    Notify("Lighting","Fog removed",2)
end,C.Teal)
Btn(ProtPanel,"Restore Lighting (IY restorelighting)",function()
    Lighting.Brightness=OrigLighting.Brightness; Lighting.Ambient=OrigLighting.Ambient
    Lighting.OutdoorAmbient=OrigLighting.OutdoorAmbient; Lighting.ClockTime=OrigLighting.ClockTime
    Lighting.FogEnd=OrigLighting.FogEnd; Lighting.FogStart=OrigLighting.FogStart
    Notify("Lighting","Restored",2)
end,C.Dim)

-- ============================================================
-- BUILD ESP PANEL
-- ============================================================
local ESPPanel=MakePanel("ESP")

Sec(ESPPanel,"IY ESP (SelectionBox)",C.Teal)
Tog(ESPPanel,"Player ESP",false,function(on) ST.ESPOn=on; UpdateESP(on) end,C.Teal)
Tog(ESPPanel,"XRay (IY xray - walls transparent)",false,function(on)
    ST.XRay=on; SetXray(on)
end,C.Teal)
Btn(ESPPanel,"Refresh ESP",function()
    if ST.ESPOn then UpdateESP(false); task.wait(0.1); UpdateESP(true) end; Notify("ESP","Refreshed",2)
end,C.Teal)

Sec(ESPPanel,"Player List",C.Teal)
local function BuildPList()
    for _,ch in pairs(ESPPanel:GetChildren()) do if ch.Name=="PLCard" then ch:Destroy() end end
    for _,p in ipairs(Players:GetPlayers()) do
        local card=Fr(ESPPanel,UDim2.new(1,0,0,68),nil,C.Card,0)
        card.Name="PLCard"; card.ZIndex=12; Crn(card,12); Strk(card,C.Border,1)
        local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.58,0,0,24); nl.Position=UDim2.new(0,10,0,6)
        nl.BackgroundTransparency=1; nl.Text=(p==LP and "[YOU] " or "")..p.Name; nl.TextSize=13
        nl.Font=Enum.Font.GothamBold; nl.TextColor3=p==LP and C.Green or C.Text
        nl.TextXAlignment=Enum.TextXAlignment.Left; nl.ZIndex=13; nl.Parent=card
        local char=p.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart"); local myR=GetRoot()
        local dist=root and myR and math.floor((root.Position-myR.Position).Magnitude) or "?"
        local hp=hum and math.floor(hum.Health) or "?"
        local il=Instance.new("TextLabel"); il.Size=UDim2.new(0.58,0,0,18); il.Position=UDim2.new(0,10,0,32)
        il.BackgroundTransparency=1; il.Text="HP "..hp.." | "..dist.."m"; il.TextSize=11
        il.Font=Enum.Font.Gotham; il.TextColor3=C.Dim; il.TextXAlignment=Enum.TextXAlignment.Left; il.ZIndex=13; il.Parent=card
        local bRow=Fr(card,UDim2.new(0.4,0,1,0),UDim2.new(0.6,0,0,0),C.BG,1); bRow.ZIndex=13
        HList(bRow,3,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center); Pad(bRow,4,4,4,4)
        local function SB(t,col,fn)
            local b=Instance.new("TextButton"); b.Size=UDim2.new(0,40,0,28)
            b.BackgroundColor3=col; b.BackgroundTransparency=0.2; b.Text=t; b.TextColor3=C.White
            b.TextSize=10; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=14; b.Parent=bRow
            Crn(b,8); b.MouseButton1Click:Connect(function() if fn then pcall(fn) end end)
        end
        SB("TP",C.Accent,function()
            local mr=GetRoot(); local tr=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if mr and tr then mr.CFrame=tr.CFrame*CFrame.new(0,0,4) end
        end)
        SB("Fling",C.Red,function()
            local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if root then task.spawn(function()
                for i=1,4 do root.Velocity=Vector3.new(math.random(-1,1)*5000,4000,math.random(-1,1)*5000); task.wait(0.05) end
            end) end
        end)
        SB("Kill",Color3.fromRGB(200,0,0),function()
            local hum2=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum2 then hum2.Health=0 end
        end)
    end
end
Btn(ESPPanel,"Refresh List",BuildPList,C.Teal)
BuildPList()
Players.PlayerAdded:Connect(function() task.wait(1); BuildPList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); BuildPList() end)

-- ============================================================
-- BUILD UTIL PANEL
-- ============================================================
local UtilPanel=MakePanel("Util")

Sec(UtilPanel,"IY Server",C.Pink)
Btn(UtilPanel,"Rejoin (IY rejoin)",function()
    game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
end,C.Pink)
Btn(UtilPanel,"Server Hop (IY serverhop)",function()
    local tp=game:GetService("TeleportService")
    local ok,data=pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and data and data.data then
        for _,s in ipairs(data.data) do
            if s.id~=game.JobId and s.playing<s.maxPlayers then
                tp:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return
            end
        end
    end
    tp:Teleport(game.PlaceId,LP)
end,C.Pink)
Btn(UtilPanel,"Server Info",function()
    Notify("Server","PlaceID: "..game.PlaceId.."\nPlayers: "..#Players:GetPlayers().."/"..Players.MaxPlayers,6)
end,C.Dim)
Btn(UtilPanel,"Notify JobID",function()
    Notify("JobID",game.JobId,8)
end,C.Dim)

Sec(UtilPanel,"IY Lighting",C.Orange)
Sldr(UtilPanel,"Clock Time",0,24,14,function(v) Lighting.ClockTime=v end,C.Orange)
Sldr(UtilPanel,"Brightness",0,10,2,function(v) Lighting.Brightness=v end,C.Orange)
Sldr(UtilPanel,"Fog End",100,999999,999999,function(v) Lighting.FogEnd=v; Lighting.FogStart=v*0.8 end,C.Orange)

Sec(UtilPanel,"IY Workspace (gravity/unlock)",C.Orange)
Sldr(UtilPanel,"Gravity (IY gravity)",0,400,196,function(v) workspace.Gravity=v end,C.Orange)
Btn(UtilPanel,"Unlock Workspace (IY unlockws)",function()
    pcall(function() workspace.Locked=false end)
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then pcall(function() v.Locked=false end) end
    end
    Notify("Util","Workspace unlocked",2)
end,C.Orange)
Btn(UtilPanel,"Remove Terrain",function()
    workspace.Terrain:Clear(); Notify("Util","Terrain removed",2)
end,Color3.fromRGB(150,80,20))
Btn(UtilPanel,"No Click Detector Limits",function()
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then v.MaxActivationDistance=math.huge end
    end
    Notify("Util","Click limits removed",2)
end,C.Teal)
Btn(UtilPanel,"Remove Ads (IY removeads)",function()
    task.spawn(function()
        while task.wait() do
            pcall(function()
                for _,v in pairs(workspace:GetDescendants()) do
                    if v:IsA("PackageLink") then
                        if v.Parent:FindFirstChild("ADpart") or v.Parent:FindFirstChild("AdGuiAdornee") then
                            (v.Parent.Parent or v.Parent):Destroy()
                        end
                    end
                end
            end)
        end
    end)
    Notify("Util","Ad blocker running",2)
end,C.Teal)

Sec(UtilPanel,"World Presets",C.Orange)
Btn(UtilPanel,"Zero Gravity",function() workspace.Gravity=2; Notify("World","Zero-G!",2) end,C.Blue)
Btn(UtilPanel,"Moon Gravity",function() workspace.Gravity=30; Notify("World","Moon-G!",2) end,C.Dim)
Btn(UtilPanel,"Normal Gravity",function() workspace.Gravity=196 end,C.Green)
Btn(UtilPanel,"Night",function() Lighting.ClockTime=0; Lighting.Brightness=0.3 end,Color3.fromRGB(20,20,60))
Btn(UtilPanel,"Day",function() Lighting.ClockTime=14; Lighting.Brightness=2 end,Color3.fromRGB(255,220,100))

-- ============================================================
-- BUILD PLAYERS PANEL
-- ============================================================
local PlayersPanel=MakePanel("Players")

Sec(PlayersPanel,"Mass Actions (IY style)",C.Orange)
Btn(PlayersPanel,"Fling EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root then task.spawn(function()
                for i=1,5 do root.Velocity=Vector3.new(math.random(-1,1)*7000,6000,math.random(-1,1)*7000); task.wait(0.05) end
            end) end
        end
    end; Notify("MASS","EVERYONE FLUNG!",2)
end,C.Red)
Btn(PlayersPanel,"Launch EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Launch(p,1500) end end
end,C.Orange)
Btn(PlayersPanel,"Explode EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Explode(p) end end
end,C.Red)
Btn(PlayersPanel,"Freeze EVERYONE (IY freeze all)",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Freeze(p) end end
    Notify("MASS","All frozen!",2)
end,C.Accent)
Btn(PlayersPanel,"Thaw EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do Thaw(p) end
end,C.Accent)
Btn(PlayersPanel,"GIANT EVERYONE (10x)",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then SetSize(p,10) end end
end,C.Orange)
Btn(PlayersPanel,"Tiny EVERYONE (0.05x)",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then SetSize(p,0.05) end end
end,C.Orange)
Btn(PlayersPanel,"Reset ALL Sizes",function()
    for _,p in ipairs(Players:GetPlayers()) do SetSize(p,1) end
end,C.Green)
Btn(PlayersPanel,"Blind EVERYONE (8s)",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Blind(p,8) end end
end,C.Yellow)
Btn(PlayersPanel,"Fire on EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do SetFX(p,"Fire",true) end
end,Color3.fromRGB(255,120,20))
Btn(PlayersPanel,"Sparkle EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do SetFX(p,"Sparkles",true) end
end,C.Yellow)
Btn(PlayersPanel,"Mute ALL Boomboxes",function()
    for _,p in ipairs(Players:GetPlayers()) do MuteBoombox(p,true) end
end,C.Dim)
Btn(PlayersPanel,"Loop OOF ALL",function()
    StartLoopOof(); task.delay(10,function() StopLoopOof() end)
    Notify("MASS","10s loop oof!",2)
end,C.Yellow)

Sec(PlayersPanel,"Broadcast",C.Yellow)
local _,bcastTB=Inp(PlayersPanel,"Broadcast message...",nil,C.Yellow)
Btn(PlayersPanel,"Broadcast Chat",function()
    if bcastTB and bcastTB.Text~="" then ChatMsg(bcastTB.Text) end
end,C.Yellow)

-- ============================================================
-- OPEN / CLOSE
-- ============================================================
local FSIZE=UDim2.new(0.88,0,0.78,0)
local OpenWindow,CloseWindow,TogMin

OpenWindow=function()
    ST.Open=true; MF.Visible=true; MF.Size=UDim2.new(0,0,0,0)
    Tw(MF,{Size=FSIZE,BackgroundTransparency=0.05},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
    Tw(FB,{BackgroundTransparency=0.3,Size=UDim2.new(0,60,0,60)},0.2)
    SetTab(ST.Tab)
end
CloseWindow=function()
    ST.Open=false
    Tw(MF,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},0.3)
    Tw(FB,{BackgroundTransparency=0,Size=UDim2.new(0,72,0,72)},0.2)
    task.wait(0.35); if not ST.Open then MF.Visible=false end
end
TogMin=function()
    ST.Mini=not ST.Mini
    if ST.Mini then Tw(MF,{Size=UDim2.new(FSIZE.X.Scale,0,0,56)},0.3)
    else Tw(MF,{Size=FSIZE},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out) end
end

if _G.__KH4Min then _G.__KH4Min.MouseButton1Click:Connect(TogMin) end
if _G.__KH4Cls then _G.__KH4Cls.MouseButton1Click:Connect(CloseWindow) end

-- FLOAT BUTTON INPUT
local fbDrag,fbDist,fbDS,fbSP=false,0,nil,nil
FB.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        fbDrag=true; fbDist=0; fbDS=inp.Position; fbSP=FB.Position
    end
end)
FB.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        if fbDist<12 then if ST.Open then CloseWindow() else OpenWindow() end end
        fbDrag=false; fbDist=0
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if fbDrag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local d=inp.Position-fbDS; fbDist=fbDist+math.abs(d.X)+math.abs(d.Y)
        local vp=Cam.ViewportSize
        FB.Position=UDim2.new(0,math.clamp(fbSP.X.Offset+d.X,0,vp.X-72),0,math.clamp(fbSP.Y.Offset+d.Y,0,vp.Y-72))
    end
end)

-- PC TOGGLE
UserInputService.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.RightBracket then
        if ST.Open then CloseWindow() else OpenWindow() end
    end
end)

-- CHARACTER RESPAWN
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum=char:WaitForChild("Humanoid",5)
    if hum then
        if ST.Speed~=16 then hum.WalkSpeed=ST.Speed end
        if ST.Jump~=50 then hum.JumpPower=ST.Jump end
    end
    if ST.InfJump then SetInfJump(true) end
    if ST.Flying then task.wait(0.5); StartFly() end
    if ST.GodMode then SetGod(true) end
end)

-- INIT
SetTab("Fling")
task.wait(0.3)
Notify("Kaelen Hub v4","IY Complete! | "..#SONGS.." songs | Tap K to open",5)
print("╔══════════════════════════════════════╗")
print("║   Kaelen Hub v4.0 - IY Complete      ║")
print("║   Fling|Spin|Bang|Carpet|Headsit     ║")
print("║   "..#SONGS.." songs | by crx-ter | Delta    ║")
print("╚══════════════════════════════════════╝")
