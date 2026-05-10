-- Kaelen Hub v3.0 --
-- iOS UI | IY Logic | Delta Mobile | No UIGridLayout | No AutomaticCanvasSize
-- All fling/spin/fly/troll logic copied from Infinite Yield source

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local Debris           = game:GetService("Debris")

local LP    = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Cam   = workspace.CurrentCamera

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    BG     = Color3.fromRGB(8,8,16),
    Panel  = Color3.fromRGB(14,14,26),
    Card   = Color3.fromRGB(22,22,38),
    Accent = Color3.fromRGB(110,72,255),
    Pink   = Color3.fromRGB(255,72,172),
    Green  = Color3.fromRGB(72,255,150),
    Red    = Color3.fromRGB(255,72,72),
    Orange = Color3.fromRGB(255,152,50),
    Yellow = Color3.fromRGB(255,220,50),
    Teal   = Color3.fromRGB(50,220,200),
    Blue   = Color3.fromRGB(72,170,255),
    Text   = Color3.fromRGB(238,238,255),
    Dim    = Color3.fromRGB(130,130,170),
    Off    = Color3.fromRGB(45,45,68),
    White  = Color3.new(1,1,1),
    Border = Color3.fromRGB(45,45,75),
}

-- ============================================================
-- STATE
-- ============================================================
local ST = {
    Open=false, Mini=false, Tab="Troll",
    -- IY flags
    Clip=true, Noclipping=nil,
    FLYING=false, iyflyspeed=1,
    flyKeyDown=nil, flyKeyUp=nil,
    flinging=false, flingDied=nil,
    walkflinging=false,
    headSit=nil,
    -- toggles
    GodMode=false, GodConn=nil,
    Invisible=false,
    InfJump=false, InfJumpConn=nil,
    ClickTP=false, ClickTPConn=nil,
    Speed=16, Jump=50,
    SpinOn=false,
    -- music
    MusicOn=false, MusicLoop=false, MusicVol=0.8, SongIdx=1, SongID=nil,
    -- checkpoints
    CPs={},
    -- esp
    ESPOn=false, ESPBoxes={},
    -- troll target
    Target=nil,
    OrigBright=Lighting.Brightness,
    OrigAmb=Lighting.Ambient,
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
    {n="Join Me In Death",id="106344107023335"},{n="InnerAwakening",id="76585504240155"},
    {n="Banana Bashin",id="118231802185865"},{n="I Miss You",id="125460168433130"},
    {n="Lo-fi Chill A",id="9043887091"},{n="Relaxed Scene",id="1848354536"},
    {n="Piano In Dark",id="1836291588"},{n="Moonlit Memories",id="90866117181187"},
    {n="Capybara",id="99099326829992"},{n="blossom",id="136212040250804"},
    {n="Crimson Vision",id="105214146426572"},{n="Ambient Blue",id="139952467445591"},
    {n="Claire De Lune",id="1838457617"},{n="Nocturne",id="129108903964685"},
    {n="Velvet Midnight",id="82091048635749"},{n="Dear Lana",id="119589412825080"},
    {n="SAD!",id="72320758533508"},{n="BRAZIL DO FUNK",id="133498554139200"},
    {n="CRYSTAL FUNK",id="103445348511856"},{n="SEA OF PHONK",id="130367831349871"},
    {n="BAILE FUNK",id="104880194210827"},{n="GOTH FUNK",id="140704128008979"},
    {n="AURA DEFINED Slw",id="109805678713575"},{n="BRX PHONK",id="17422074849"},
    {n="YOTO HIME PHONK",id="103183298894656"},{n="BEM SOLTO BRAZIL",id="119936139925486"},
    {n="HOTAKFUNK",id="79314929106323"},{n="NEXOVA",id="127388462601694"},
    {n="Din1c INVASION",id="15689453529"},{n="Din1c METAMORPHOSIS",id="15689451063"},
    {n="Cowbell God",id="16190760005"},{n="Vine Boom",id="6823153536"},
    {n="Wii Sports R&B",id="72697308378715"},{n="POWER OF ANIME",id="1226918619"},
    {n="AUUUUUGH",id="8893545897"},{n="Better Call Saul",id="9106904975"},
    {n="HEHEHE HA",id="8406005582"},{n="Deja vu Initial D",id="16831106636"},
    {n="Mezcla Espanola",id="124263849663656"},{n="UNIVERSO",id="95518661042892"},
    {n="Cumbia Los Cholos",id="77246411659544"},{n="PHONK ULTRA",id="134839199346188"},
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
        local s=Instance.new("UIStroke")
        s.Color=col or C.Border; s.Thickness=th or 1
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
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,sp or 8)
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p; return l
end
local function HList(p,sp,ha,va)
    local l=Instance.new("UIListLayout")
    l.FillDirection=Enum.FillDirection.Horizontal
    l.Padding=UDim.new(0,sp or 6)
    l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment=va or Enum.VerticalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p; return l
end
local function Fr(p,sz,pos,bg,tr)
    local f=Instance.new("Frame")
    f.Size=sz or UDim2.new(1,0,1,0); f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or C.Card; f.BackgroundTransparency=tr or 0
    f.BorderSizePixel=0; f.Parent=p; return f
end
local function Lbl(p,txt,sz,col,font,xa)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1; l.Text=txt or ""; l.TextSize=sz or 13
    l.TextColor3=col or C.Text; l.Font=font or Enum.Font.GothamBold
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center
    l.Size=UDim2.new(1,0,0,(sz or 13)+8); l.TextWrapped=true; l.Parent=p; return l
end
-- ScrollFrame WITHOUT AutomaticCanvasSize (IY style: update canvas manually)
local function Scr(p,sz,pos)
    local s=Instance.new("ScrollingFrame")
    s.Size=sz or UDim2.new(1,0,1,0); s.Position=pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency=1; s.BorderSizePixel=0
    s.ScrollBarThickness=4; s.ScrollBarImageColor3=C.Accent
    s.CanvasSize=UDim2.new(0,0,0,2000) -- large default, updated by layout
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

-- ============================================================
-- IY CORE FUNCTIONS (exact logic from IY source)
-- ============================================================

-- NOCLIP (IY exact)
local Noclipping
local function DoNoclip()
    ST.Clip=false
    if Noclipping then Noclipping:Disconnect() end
    Noclipping=RunService.Stepped:Connect(function()
        if ST.Clip==false and LP.Character then
            for _,child in pairs(LP.Character:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide==true then
                    child.CanCollide=false
                end
            end
        end
    end)
end
local function DoClip()
    if Noclipping then Noclipping:Disconnect() Noclipping=nil end
    ST.Clip=true
end

-- FLY - IY mobile fly (uses ControlModule like IY does for mobile)
local FLYING=false
local flyKeyDown,flyKeyUp
local mfly1,mfly2
local velocityHandlerName="KaelenBV"
local gyroHandlerName="KaelenBG"

local function NOFLY()
    FLYING=false
    if flyKeyDown then flyKeyDown:Disconnect() flyKeyDown=nil end
    if flyKeyUp then flyKeyUp:Disconnect() flyKeyUp=nil end
    local hum=GetHum()
    if hum then pcall(function() hum.PlatformStand=false end) end
    pcall(function() Cam.CameraType=Enum.CameraType.Custom end)
end

local function unmobilefly()
    pcall(function()
        FLYING=false
        local root=GetRoot()
        if root then
            local bv=root:FindFirstChild(velocityHandlerName)
            local bg=root:FindFirstChild(gyroHandlerName)
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        local hum=GetHum()
        if hum then hum.PlatformStand=false end
        if mfly1 then mfly1:Disconnect() mfly1=nil end
        if mfly2 then mfly2:Disconnect() mfly2=nil end
    end)
end

local function mobilefly()
    unmobilefly()
    FLYING=true
    local root=GetRoot()
    if not root then return end
    local v3inf=Vector3.new(9e9,9e9,9e9)
    local v3zero=Vector3.new(0,0,0)

    local bv=Instance.new("BodyVelocity")
    bv.Name=velocityHandlerName; bv.Parent=root
    bv.MaxForce=v3zero; bv.Velocity=v3zero

    local bg=Instance.new("BodyGyro")
    bg.Name=gyroHandlerName; bg.Parent=root
    bg.MaxTorque=v3inf; bg.P=1000; bg.D=50

    -- Try ControlModule for direction (IY method)
    local controlModule
    pcall(function()
        controlModule=require(LP.PlayerScripts:WaitForChild("PlayerModule",3):WaitForChild("ControlModule",3))
    end)

    mfly2=RunService.Heartbeat:Connect(function()
        root=GetRoot()
        local camera=Cam
        if not root then return end
        local VH=root:FindFirstChild(velocityHandlerName)
        local GH=root:FindFirstChild(gyroHandlerName)
        if not VH or not GH then return end
        local hum=GetHum()
        if hum then hum.PlatformStand=true end
        VH.MaxForce=v3inf; GH.MaxTorque=v3inf
        GH.CFrame=camera.CoordinateFrame
        VH.Velocity=v3zero
        local spd=ST.iyflyspeed*50
        if controlModule then
            local dir=controlModule:GetMoveVector()
            if dir.X~=0 then VH.Velocity=VH.Velocity+camera.CFrame.RightVector*(dir.X*spd) end
            if dir.Z~=0 then VH.Velocity=VH.Velocity-camera.CFrame.LookVector*(dir.Z*spd) end
        else
            -- Fallback: use WASD keys
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then VH.Velocity=VH.Velocity+camera.CFrame.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then VH.Velocity=VH.Velocity-camera.CFrame.LookVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then VH.Velocity=VH.Velocity-camera.CFrame.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then VH.Velocity=VH.Velocity+camera.CFrame.RightVector*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then VH.Velocity=VH.Velocity+Vector3.new(0,1,0)*spd end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then VH.Velocity=VH.Velocity-Vector3.new(0,1,0)*spd end
        end
    end)
end

local function sFLY() -- PC fly (IY exact)
    NOFLY()
    task.wait()
    FLYING=true
    local char=GetChar(); if not char then return end
    local root=GetRoot(); if not root then return end
    local hum=GetHum()
    local CONTROL={F=0,B=0,L=0,R=0,Q=0,E=0}
    local lCONTROL={F=0,B=0,L=0,R=0,Q=0,E=0}
    local SPEED=0
    local BG=Instance.new("BodyGyro"); local BV=Instance.new("BodyVelocity")
    BG.P=9e4; BG.Parent=root; BG.MaxTorque=Vector3.new(9e9,9e9,9e9); BG.CFrame=root.CFrame
    BV.Velocity=Vector3.new(0,0,0); BV.MaxForce=Vector3.new(9e9,9e9,9e9); BV.Parent=root
    task.spawn(function()
        repeat task.wait()
            local camera=Cam
            if hum then hum.PlatformStand=true end
            local spd=ST.iyflyspeed*50
            if CONTROL.L+CONTROL.R~=0 or CONTROL.F+CONTROL.B~=0 or CONTROL.Q+CONTROL.E~=0 then
                SPEED=spd
            else SPEED=0 end
            if (CONTROL.L+CONTROL.R)~=0 or (CONTROL.F+CONTROL.B)~=0 or (CONTROL.Q+CONTROL.E)~=0 then
                BV.Velocity=((camera.CFrame.LookVector*(CONTROL.F+CONTROL.B))+((camera.CFrame*CFrame.new(CONTROL.L+CONTROL.R,(CONTROL.F+CONTROL.B+CONTROL.Q+CONTROL.E)*0.2,0).p)-camera.CFrame.p))*SPEED
                lCONTROL={F=CONTROL.F,B=CONTROL.B,L=CONTROL.L,R=CONTROL.R}
            elseif SPEED~=0 then
                BV.Velocity=((camera.CFrame.LookVector*(lCONTROL.F+lCONTROL.B))+((camera.CFrame*CFrame.new(lCONTROL.L+lCONTROL.R,(lCONTROL.F+lCONTROL.B)*0.2,0).p)-camera.CFrame.p))*SPEED
            else BV.Velocity=Vector3.new(0,0,0) end
            BG.CFrame=camera.CFrame
        until not FLYING
        if hum then hum.PlatformStand=false end
        BG:Destroy(); BV:Destroy()
    end)
    flyKeyDown=UserInputService.InputBegan:Connect(function(input,proc)
        if proc then return end
        local sp=ST.iyflyspeed
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
    local isMobile=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if isMobile then mobilefly() else sFLY() end
end
local function StopFly()
    local isMobile=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if isMobile then unmobilefly() else NOFLY() end
    FLYING=false
end

-- FLING (IY exact logic - BodyAngularVelocity)
local flinging=false
local flingDied
local function DoFling()
    flinging=false
    -- Set heavy physics on self (IY exact)
    for _,child in pairs(LP.Character:GetDescendants()) do
        if child:IsA("BasePart") then
            pcall(function()
                child.CustomPhysicalProperties=PhysicalProperties.new(100,0.3,0.5)
            end)
        end
    end
    DoNoclip()
    task.wait(0.1)
    local root=GetRoot()
    if not root then return end
    -- Clean old BAV
    for _,v in pairs(root:GetChildren()) do
        if v:IsA("BodyAngularVelocity") then v:Destroy() end
    end
    local bambam=Instance.new("BodyAngularVelocity")
    bambam.Name="KaelenFlingBAV"
    bambam.Parent=root
    bambam.AngularVelocity=Vector3.new(0,99999,0)
    bambam.MaxTorque=Vector3.new(0,math.huge,0)
    bambam.P=math.huge
    for _,v in pairs(LP.Character:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide=false
            pcall(function() v.Massless=true end)
            v.Velocity=Vector3.new(0,0,0)
        end
    end
    flinging=true
    local hum=GetHum()
    if hum then
        flingDied=hum.Died:Connect(function()
            flinging=false
            DoClip()
            if flingDied then flingDied:Disconnect() flingDied=nil end
        end)
    end
    task.spawn(function()
        repeat
            if root and root.Parent then
                bambam.AngularVelocity=Vector3.new(0,99999,0)
            end
            task.wait(0.2)
            if root and root.Parent then
                bambam.AngularVelocity=Vector3.new(0,0,0)
            end
            task.wait(0.1)
        until flinging==false
    end)
    Notify("Fling","Flinging! Toggle again to stop",3)
end
local function StopFling()
    DoClip()
    if flingDied then flingDied:Disconnect() flingDied=nil end
    flinging=false
    task.wait(0.1)
    local root=GetRoot()
    if root then
        for _,v in pairs(root:GetChildren()) do
            if v:IsA("BodyAngularVelocity") then v:Destroy() end
        end
    end
    if LP.Character then
        for _,child in pairs(LP.Character:GetDescendants()) do
            if child:IsA("BasePart") then
                pcall(function()
                    child.CustomPhysicalProperties=PhysicalProperties.new(0.7,0.3,0.5)
                end)
            end
        end
    end
    Notify("Fling","Fling stopped",2)
end

-- WALKFLING (IY exact - fling while walking)
local walkflinging=false
local walkflingConn
local function DoWalkFling()
    walkflinging=false
    if walkflingConn then walkflingConn:Disconnect() walkflingConn=nil end
    task.wait(0.05)
    DoNoclip()
    walkflinging=true
    walkflingConn=RunService.Heartbeat:Connect(function()
        if not walkflinging then
            walkflingConn:Disconnect()
            DoClip()
            return
        end
        local root=GetRoot()
        if not root then return end
        local vel=root.Velocity
        root.Velocity=vel*10000+Vector3.new(0,10000,0)
        task.wait()
        if root and root.Parent then root.Velocity=vel end
    end)
    Notify("WalkFling","Walk to fling! Toggle to stop",3)
end
local function StopWalkFling()
    walkflinging=false
    if walkflingConn then walkflingConn:Disconnect() walkflingConn=nil end
    DoClip()
end

-- SPIN (IY exact - BodyAngularVelocity)
local function DoSpin(speed)
    local root=GetRoot(); if not root then return end
    for _,v in pairs(root:GetChildren()) do
        if v.Name=="KaelenSpin" then v:Destroy() end
    end
    local Spin=Instance.new("BodyAngularVelocity")
    Spin.Name="KaelenSpin"
    Spin.Parent=root
    Spin.MaxTorque=Vector3.new(0,math.huge,0)
    Spin.AngularVelocity=Vector3.new(0,speed or 20,0)
end
local function StopSpin()
    local root=GetRoot(); if not root then return end
    for _,v in pairs(root:GetChildren()) do
        if v.Name=="KaelenSpin" then v:Destroy() end
    end
end

-- HEADSIT (IY exact)
local headSitConn
local function DoHeadsit(target)
    if headSitConn then headSitConn:Disconnect() headSitConn=nil end
    if not target or not target.Character then return end
    local myHum=GetHum()
    if myHum then myHum.Sit=true end
    headSitConn=RunService.Heartbeat:Connect(function()
        local tRoot=target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local myRoot=GetRoot()
        local myH=GetHum()
        if tRoot and myRoot and myH and myH.Sit==true then
            myRoot.CFrame=tRoot.CFrame*CFrame.Angles(0,math.rad(0),0)*CFrame.new(0,1.6,0.4)
        else
            headSitConn:Disconnect()
            headSitConn=nil
        end
    end)
    Notify("HeadSit","Sitting on "..target.Name,2)
end
local function StopHeadsit()
    if headSitConn then headSitConn:Disconnect() headSitConn=nil end
    local hum=GetHum()
    if hum then hum.Sit=false end
end

-- FREEZE/THAW (IY exact)
local function Freeze(p)
    local char=p and p.Character
    if not char then return end
    for _,x in pairs(char:GetDescendants()) do
        if x:IsA("BasePart") and not x.Anchored then x.Anchored=true end
    end
end
local function Thaw(p)
    local char=p and p.Character
    if not char then return end
    for _,x in pairs(char:GetDescendants()) do
        if x:IsA("BasePart") and x.Anchored then x.Anchored=false end
    end
end

-- LOOPOOF (IY exact - loops oof sound)
local oofing=false
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

-- GOD MODE (IY style - loop health)
local godConn
local function SetGod(on)
    if godConn then godConn:Disconnect() godConn=nil end
    if on then
        godConn=RunService.Heartbeat:Connect(function()
            local hum=GetHum()
            if hum and hum.Health<hum.MaxHealth then hum.Health=hum.MaxHealth end
        end)
    end
end

-- INVISIBLE (simple local transparency - client side)
local function SetInvisible(on)
    local char=GetChar(); if not char then return end
    for _,v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then v.LocalTransparencyModifier=on and 1 or 0 end
        if v:IsA("Decal") then v.Transparency=on and 1 or 0 end
    end
end

-- FULLBRIGHT
local function SetFullbright(on)
    if on then
        ST.OrigBright=Lighting.Brightness; ST.OrigAmb=Lighting.Ambient
        Lighting.Brightness=8
        Lighting.Ambient=Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient=Color3.fromRGB(255,255,255)
    else
        Lighting.Brightness=ST.OrigBright; Lighting.Ambient=ST.OrigAmb
    end
end

-- INF JUMP
local infJumpConn
local function SetInfJump(on)
    if infJumpConn then infJumpConn:Disconnect() infJumpConn=nil end
    if on then
        infJumpConn=UserInputService.JumpRequest:Connect(function()
            local hum=GetHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

-- CLICK TP
local clickTPConn
local function SetClickTP(on)
    if clickTPConn then clickTPConn:Disconnect() clickTPConn=nil end
    if on then
        clickTPConn=Mouse.Button1Down:Connect(function()
            if not ST.ClickTP then clickTPConn:Disconnect() return end
            local root=GetRoot()
            if root and Mouse.Hit then root.CFrame=Mouse.Hit+Vector3.new(0,3,0) end
        end)
    end
end

-- SIZE (IY humanoid scales)
local function SetSize(p,scale)
    local char=p and p.Character or GetChar(); if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    pcall(function()
        hum.BodyDepthScale.Value=scale; hum.BodyHeightScale.Value=scale
        hum.BodyWidthScale.Value=scale; hum.HeadScale.Value=scale
    end)
end

-- FIRE/SMOKE/SPARKLES
local function SetFX(p,fxType,on)
    local char=p and p.Character or GetChar(); if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not root then return end
    if on then
        if not root:FindFirstChildOfClass(fxType) then Instance.new(fxType).Parent=root end
    else
        local fx=root:FindFirstChildOfClass(fxType)
        if fx then fx:Destroy() end
    end
end

-- LOOPFLING (fling target repeatedly)
local loopFlingConn
local function StartLoopFling(target,power)
    if loopFlingConn then loopFlingConn:Disconnect() end
    loopFlingConn=RunService.Heartbeat:Connect(function()
        if not target or not target.Character then return end
        local root=target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity=Vector3.new(math.random(-1,1)*(power or 500),math.random(300,800),math.random(-1,1)*(power or 500))
        end
    end)
end
local function StopLoopFling()
    if loopFlingConn then loopFlingConn:Disconnect() loopFlingConn=nil end
end

-- CLIENTBRING (IY: bring target to you, loop)
local cbringConn
local function StartClientBring(target)
    if cbringConn then cbringConn:Disconnect() end
    cbringConn=RunService.Heartbeat:Connect(function()
        if not target or not target.Character then return end
        local myRoot=GetRoot()
        local tRoot=target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            tRoot.CFrame=myRoot.CFrame*CFrame.new(0,0,4)
        end
    end)
end
local function StopClientBring()
    if cbringConn then cbringConn:Disconnect() cbringConn=nil end
end

-- LOOPKILL
local loopKillConn
local function StartLoopKill(target)
    if loopKillConn then loopKillConn:Disconnect() end
    loopKillConn=RunService.Heartbeat:Connect(function()
        if not target or not target.Character then return end
        local hum=target.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health=0 end
    end)
end
local function StopLoopKill()
    if loopKillConn then loopKillConn:Disconnect() loopKillConn=nil end
end

-- CHAT
local function ChatMsg(msg)
    local ok=pcall(function()
        local rs=game:GetService("ReplicatedStorage")
        local ev=rs:FindFirstChild("DefaultChatSystemChatEvents")
        if ev then
            local say=ev:FindFirstChild("SayMessageRequest")
            if say then say:FireServer(msg,"All") end
        end
    end)
    if not ok then
        pcall(function()
            game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(msg)
        end)
    end
end

-- EXPLODE
local function Explode(p)
    if not p or not p.Character then return end
    local root=p.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
    local exp=Instance.new("Explosion")
    exp.Position=root.Position; exp.BlastRadius=8; exp.BlastPressure=500000
    pcall(function() exp.ExplosionType=Enum.ExplosionType.NoCraters end)
    exp.Parent=workspace
end

-- LAUNCH
local function Launch(p,power)
    if not p or not p.Character then return end
    local root=p.Character:FindFirstChild("HumanoidRootPart"); if not root then return end
    local bv=Instance.new("BodyVelocity")
    bv.Velocity=Vector3.new(0,power or 1200,0)
    bv.MaxForce=Vector3.new(0,1e9,0)
    bv.Parent=root; Debris:AddItem(bv,0.4)
end

-- KNOCKBACK
local function Knockback(p,power)
    if not p or not p.Character then return end
    local myRoot=GetRoot(); if not myRoot then return end
    local tRoot=p.Character:FindFirstChild("HumanoidRootPart"); if not tRoot then return end
    local dir=(tRoot.Position-myRoot.Position).Unit
    local bv=Instance.new("BodyVelocity")
    bv.Velocity=dir*(power or 200)+Vector3.new(0,80,0)
    bv.MaxForce=Vector3.new(1e9,1e9,1e9)
    bv.Parent=tRoot; Debris:AddItem(bv,0.35)
end

-- BLIND
local function Blind(p,dur)
    if not p or not p.Character then return end
    local head=p.Character:FindFirstChild("Head"); if not head then return end
    local part=Instance.new("Part")
    part.Size=Vector3.new(8,8,8); part.Material=Enum.Material.Neon
    part.BrickColor=BrickColor.new("Institutional white")
    part.CanCollide=false; part.CFrame=head.CFrame; part.Parent=workspace
    local weld=Instance.new("WeldConstraint")
    weld.Part0=head; weld.Part1=part; weld.Parent=part
    Debris:AddItem(part,dur or 8)
    Notify("Blind","Blinded "..p.Name.." for "..(dur or 8).."s",3)
end

-- DANCE
local danceTracks={}
local danceIDs={"507770239","507771019","507771955","507772104","507772398","507773317","507776043","507776468","507777268","507777451","1073893568","1073893569"}
local function Dance(idx)
    local hum=GetHum(); if not hum then return end
    for _,t in ipairs(danceTracks) do pcall(function() t:Stop() end) end
    danceTracks={}
    local anim=Instance.new("Animation")
    anim.AnimationId="rbxassetid://"..(danceIDs[idx] or danceIDs[1])
    local track=hum.Animator:LoadAnimation(anim)
    track:Play(); danceTracks={track}
    Notify("Dance","Dance "..idx,2)
end

-- ANTI-VOID
local antiVoidConn
local function StartAntiVoid()
    if antiVoidConn then antiVoidConn:Disconnect() end
    antiVoidConn=RunService.Heartbeat:Connect(function()
        local root=GetRoot()
        if root and root.Position.Y<workspace.FallenPartsDestroyHeight+100 then
            root.CFrame=CFrame.new(root.Position.X,workspace.FallenPartsDestroyHeight+150,root.Position.Z)
            Notify("AntiVoid","Saved from void!",2)
        end
    end)
end
local function StopAntiVoid()
    if antiVoidConn then antiVoidConn:Disconnect() antiVoidConn=nil end
end

-- MUSIC
local MusicSound=Instance.new("Sound")
MusicSound.Name="KaelenMusic"; MusicSound.Volume=0.8
MusicSound.RollOffMaxDistance=999999; MusicSound.RollOffMinDistance=999999
pcall(function() MusicSound.RollOffMode=Enum.RollOffMode.InverseTapered end)
MusicSound.Parent=workspace

local NPLabel -- forward declared
local function PlaySong(id,name)
    MusicSound.SoundId="rbxassetid://"..tostring(id)
    MusicSound:Stop(); MusicSound:Play()
    ST.MusicOn=true; ST.SongID=tostring(id)
    if NPLabel then NPLabel.Text="Now Playing: "..(name or id) end
    Notify("Music","Now Playing: "..(name or id),3)
end
local function StopMusic()
    MusicSound:Stop(); ST.MusicOn=false
    if NPLabel then NPLabel.Text="Stopped" end
end
MusicSound.Ended:Connect(function()
    if ST.MusicLoop and ST.SongID then MusicSound:Play()
    elseif ST.MusicOn then
        ST.SongIdx=(ST.SongIdx % #SONGS)+1
        PlaySong(SONGS[ST.SongIdx].id,SONGS[ST.SongIdx].n)
    end
end)

-- ESP
local ESPBoxes={}
local function UpdateESP(on)
    for _,b in pairs(ESPBoxes) do pcall(function() b:Destroy() end) end
    ESPBoxes={}
    if not on then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local h=Instance.new("SelectionBox")
            h.Color3=C.Red; h.LineThickness=0.05
            h.SurfaceTransparency=0.75; h.SurfaceColor3=C.Red
            h.Adornee=p.Character; h.Parent=workspace
            ESPBoxes[p.Name]=h
        end
    end
end

-- ============================================================
-- GUI SETUP
-- ============================================================
local PGui=LP:WaitForChild("PlayerGui")
local oldH=PGui:FindFirstChild("KaelenHubV3")
if oldH then oldH:Destroy() end

local SG=Instance.new("ScreenGui")
SG.Name="KaelenHubV3"; SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true; SG.DisplayOrder=999
pcall(function() SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling end)
SG.Parent=PGui

-- FLOAT BUTTON
local FB=Instance.new("ImageButton")
FB.Size=UDim2.new(0,72,0,72); FB.Position=UDim2.new(0,14,0.5,-36)
FB.BackgroundColor3=C.Accent; FB.BorderSizePixel=0; FB.ZIndex=20; FB.Parent=SG
Crn(FB,UDim.new(1,0))
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
local HDR=Fr(MF,UDim2.new(1,0,0,56),UDim2.new(0,0,0,0),C.Panel,0)
HDR.ZIndex=11; Crn(HDR,18)
do
    local dot=Fr(HDR,UDim2.new(0,8,0,8),UDim2.new(0,12,0.5,-4),C.Accent,0); Crn(dot,UDim.new(1,0)); dot.ZIndex=12
    local t=Instance.new("TextLabel"); t.Size=UDim2.new(0,180,0,24); t.Position=UDim2.new(0,26,0,8)
    t.BackgroundTransparency=1; t.Text="Kaelen Hub v3"; t.TextSize=17; t.Font=Enum.Font.GothamBold
    t.TextColor3=C.White; t.TextXAlignment=Enum.TextXAlignment.Left; t.ZIndex=12; t.Parent=HDR
    local s=Instance.new("TextLabel"); s.Size=UDim2.new(0,180,0,16); s.Position=UDim2.new(0,26,0,33)
    s.BackgroundTransparency=1; s.Text="IY Edition | by crx-ter"; s.TextSize=11; s.Font=Enum.Font.Gotham
    s.TextColor3=C.Dim; s.TextXAlignment=Enum.TextXAlignment.Left; s.ZIndex=12; s.Parent=HDR
    -- Buttons stored in _G for forward-declaration
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
    _G.__KH3Min=MinBtn; _G.__KH3Cls=ClsBtn
end
-- Header drag
local hdrDrag,hdrDS,hdrSP=false,nil,nil
HDR.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        hdrDrag=true; hdrDS=inp.Position; hdrSP=MF.Position
    end
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
    {id="Troll",col=C.Red},{id="Move",col=C.Green},{id="Music",col=C.Blue},
    {id="Protect",col=C.Yellow},{id="ESP",col=C.Teal},{id="Util",col=C.Pink},
    {id="Players",col=C.Orange},
}
local TabBar=Fr(MF,UDim2.new(1,0,0,48),UDim2.new(0,0,0,56),C.Panel,0); TabBar.ZIndex=11
local TabScr=Instance.new("ScrollingFrame"); TabScr.Size=UDim2.new(1,0,1,0)
TabScr.BackgroundTransparency=1; TabScr.BorderSizePixel=0; TabScr.ScrollBarThickness=0
TabScr.ScrollingDirection=Enum.ScrollingDirection.X
TabScr.CanvasSize=UDim2.new(0,#TABS*90,0,0); TabScr.ZIndex=11; TabScr.Parent=TabBar
Pad(TabScr,5,5,8,8); HList(TabScr,5)
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
    local b=Instance.new("TextButton"); b.Name=info.id; b.Size=UDim2.new(0,82,0,38)
    b.BackgroundColor3=C.Card; b.BackgroundTransparency=0.5; b.Text=info.id
    b.TextColor3=C.Dim; b.TextSize=13; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.LayoutOrder=i; b.ZIndex=12; b.Parent=TabScr
    Crn(b,12); TabBtns[info.id]=b
    b.MouseButton1Click:Connect(function() SetTab(info.id) end)
end

-- ============================================================
-- PANEL BUILDERS
-- ============================================================
local function MakePanel(name)
    local s=Scr(PC,UDim2.new(1,0,1,0))
    s.Name=name; s.Visible=false; s.ZIndex=11
    Pad(s,10,20,10,10)
    local layout=VList(s,8)
    -- Update canvas when layout changes
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
    l.TextColor3=col; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=13; l.Parent=f
    return f
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
    col=col or C.Accent; h=h or 54
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
        val=minv+(maxv-minv)*r
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,-9,0.5,-9)
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
    go.BackgroundColor3=col; go.BackgroundTransparency=0.2; go.Text="OK"; go.TextColor3=C.White
    go.TextSize=13; go.Font=Enum.Font.GothamBold; go.BorderSizePixel=0; go.ZIndex=13; go.Parent=f; Crn(go,10)
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
    nxt.TextColor3=C.White; nxt.TextSize=12; nxt.Font=Enum.Font.GothamBold; nxt.BorderSizePixel=0; nxt.ZIndex=13; nxt.Parent=f
    Crn(nxt,10)
    nxt.MouseButton1Click:Connect(function()
        local list={"Everyone"}
        for _,p in ipairs(Players:GetPlayers()) do if p~=LP then list[#list+1]=p.Name end end
        idx=(idx % #list)+1
        local name=list[idx]; lbl2.Text=(label or "Target")..": "..name
        ST.Target=name=="Everyone" and nil or Players:FindFirstChild(name)
        if onChange then onChange(ST.Target) end
    end)
    return f
end

-- ============================================================
-- BUILD TROLL PANEL
-- ============================================================
local TrollPanel=MakePanel("Troll")

Sec(TrollPanel,"Target",C.Red)
TgtPicker(TrollPanel,"Target",function(p) ST.Target=p end)

Sec(TrollPanel,"IY Fling System",C.Red)
Tog(TrollPanel,"Fling (IY BodyAngularVelocity)",false,function(on)
    if on then DoFling() else StopFling() end
end,C.Red)

Tog(TrollPanel,"WalkFling (walk = fling)",false,function(on)
    if on then DoWalkFling() else StopWalkFling() end
end,C.Red)

Btn(TrollPanel,"SUPER Fling (Velocity Burst)",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do
        if p~=LP and p.Character then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                task.spawn(function()
                    for i=1,6 do
                        root.Velocity=Vector3.new(math.random(-1,1)*math.random(3000,9999),math.random(1000,9999),math.random(-1,1)*math.random(3000,9999))
                        task.wait(0.05)
                    end
                end)
            end
        end
    end
    Notify("Troll","SUPER FLUNG!",2)
end,Color3.fromRGB(255,30,30))

Btn(TrollPanel,"Launch UP",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do if p~=LP then Launch(p,1500) end end
end,C.Orange)

Btn(TrollPanel,"Knockback",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do if p~=LP then Knockback(p,300) end end
end,C.Orange)

Btn(TrollPanel,"Explode",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do if p~=LP then Explode(p) end end
end,C.Red)

Sec(TrollPanel,"IY Spin (BodyAngularVelocity)",C.Pink)
Sldr(TrollPanel,"Spin Speed",1,100,20,function(v) ST.SpinSpeed=v end,C.Pink)
Tog(TrollPanel,"Spin Self (IY exact)",false,function(on)
    if on then DoSpin(ST.SpinSpeed or 20) else StopSpin() end
end,C.Pink)

Sec(TrollPanel,"IY Headsit",C.Pink)
Tog(TrollPanel,"Headsit Target (IY exact)",false,function(on)
    if on and ST.Target then DoHeadsit(ST.Target) else StopHeadsit() end
end,C.Pink)

Sec(TrollPanel,"Control",C.Pink)
Tog(TrollPanel,"Loop Bring Target",false,function(on)
    if on and ST.Target then StartClientBring(ST.Target) else StopClientBring() end
end,C.Pink)

Tog(TrollPanel,"Loop Kill Target",false,function(on)
    if on and ST.Target then StartLoopKill(ST.Target) else StopLoopKill() end
end,C.Red)

Tog(TrollPanel,"Loop Fling Target",false,function(on)
    if on and ST.Target then StartLoopFling(ST.Target,500) else StopLoopFling() end
end,C.Red)

Btn(TrollPanel,"TP To Target",function()
    if ST.Target and ST.Target.Character then
        local myRoot=GetRoot(); local tRoot=ST.Target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then myRoot.CFrame=tRoot.CFrame*CFrame.new(0,0,4) end
    end
end,C.Accent)

Btn(TrollPanel,"Bring Target To Me",function()
    if ST.Target and ST.Target.Character then
        local myRoot=GetRoot(); local tRoot=ST.Target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then tRoot.CFrame=myRoot.CFrame*CFrame.new(0,0,4) end
    end
end,C.Accent)

Btn(TrollPanel,"Swap Positions",function()
    if ST.Target and ST.Target.Character then
        local myRoot=GetRoot(); local tRoot=ST.Target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then local mc=myRoot.CFrame; myRoot.CFrame=tRoot.CFrame; tRoot.CFrame=mc end
    end
end,C.Accent)

Sec(TrollPanel,"Freeze & Effects",C.Accent)
Btn(TrollPanel,"Freeze Target",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do if p~=LP then Freeze(p) end end
    Notify("Troll","Frozen!",2)
end,C.Accent)

Btn(TrollPanel,"Thaw Target",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do Thaw(p) end
    Notify("Troll","Thawed!",2)
end,C.Accent)

Btn(TrollPanel,"Blind (8s)",function()
    local targets=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(targets) do if p~=LP then Blind(p,8) end end
end,C.Yellow)

Tog(TrollPanel,"Loop OOF Sound (IY exact)",false,function(on)
    if on then StartLoopOof() else StopLoopOof() end
end,C.Yellow)

Sec(TrollPanel,"Size",C.Orange)
Sldr(TrollPanel,"Target Size",0.05,15,1,function(v)
    local targets=ST.Target and {ST.Target} or {}
    for _,p in ipairs(targets) do SetSize(p,v) end
end,C.Orange)
Btn(TrollPanel,"Tiny (0.05x)",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then SetSize(p,0.05) end end
end,C.Orange)
Btn(TrollPanel,"GIANT (10x)",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do if p~=LP then SetSize(p,10) end end
end,C.Orange)
Btn(TrollPanel,"Reset Size",function()
    local t=ST.Target and {ST.Target} or Players:GetPlayers()
    for _,p in ipairs(t) do SetSize(p,1) end
end,C.Green)

Sec(TrollPanel,"FX",C.Teal)
Btn(TrollPanel,"Fire ON Target",function()
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
Btn(TrollPanel,"Kill Target",function()
    local t=ST.Target and {ST.Target} or {}
    for _,p in ipairs(t) do
        if p~=LP and p.Character then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health=0 end
        end
    end
end,C.Red)

Sec(TrollPanel,"Dance (IY Anims)",C.Green)
for i=1,12 do
    Btn(TrollPanel,"Dance "..i,function() Dance(i) end,Color3.fromRGB(50+i*10,180,80),46)
end
Btn(TrollPanel,"Stop Animations",function()
    local hum=GetHum(); if not hum then return end
    for _,t in pairs(hum.Animator:GetPlayingAnimationTracks()) do t:Stop() end
end,C.Dim)

Sec(TrollPanel,"Chat",C.Yellow)
local _,chatTB=Inp(TrollPanel,"Message to say...",nil,C.Yellow)
Btn(TrollPanel,"Say Message",function()
    if chatTB and chatTB.Text~="" then ChatMsg(chatTB.Text) end
end,C.Yellow)

-- ============================================================
-- BUILD MOVE PANEL
-- ============================================================
local MovePanel=MakePanel("Move")

Sec(MovePanel,"IY Fly (Mobile + PC)",C.Green)
Tog(MovePanel,"Fly (uses IY ControlModule on mobile)",false,function(on)
    ST.Flying=on; if on then StartFly() else StopFly() end
end,C.Green)
Sldr(MovePanel,"Fly Speed",0.1,10,1,function(v) ST.iyflyspeed=v end,C.Green)

Sec(MovePanel,"Movement",C.Green)
Tog(MovePanel,"Noclip (IY exact)",false,function(on)
    if on then DoNoclip() else DoClip() end
end,C.Green)
Tog(MovePanel,"Infinite Jump",false,function(on)
    ST.InfJump=on; SetInfJump(on)
end,C.Green)
Tog(MovePanel,"Click Teleport",false,function(on)
    ST.ClickTP=on; SetClickTP(on)
end,C.Green)

Sldr(MovePanel,"Walk Speed",0,500,16,function(v)
    ST.Speed=v; local hum=GetHum(); if hum then hum.WalkSpeed=v end
end,C.Green)
Sldr(MovePanel,"Jump Power",0,500,50,function(v)
    ST.Jump=v; local hum=GetHum(); if hum then hum.JumpPower=v end
end,C.Green)

Btn(MovePanel,"Speed 16 (Normal)",function()
    local hum=GetHum(); if hum then hum.WalkSpeed=16 end end,C.Green)
Btn(MovePanel,"Speed 100 (Fast)",function()
    local hum=GetHum(); if hum then hum.WalkSpeed=100 end end,C.Green)
Btn(MovePanel,"Speed 250 (Sonic)",function()
    local hum=GetHum(); if hum then hum.WalkSpeed=250 end end,C.Green)

Sec(MovePanel,"Checkpoints",C.Teal)
local cpList={}
local cpLbl=Lbl(MovePanel,"No checkpoints",12,C.Dim)

Btn(MovePanel,"Save Checkpoint",function()
    local root=GetRoot(); if not root then return end
    cpList[#cpList+1]=root.CFrame; cpLbl.Text=#cpList.." checkpoint(s) saved"
    Notify("CP","Checkpoint "..#cpList.." saved",2)
end,C.Teal)
Btn(MovePanel,"Load Last Checkpoint",function()
    if #cpList==0 then Notify("CP","None saved!",2) return end
    local root=GetRoot(); if root then root.CFrame=cpList[#cpList] end
end,C.Teal)
Btn(MovePanel,"Clear Checkpoints",function()
    cpList={}; cpLbl.Text="No checkpoints"; Notify("CP","Cleared",2)
end,C.Red)

Sec(MovePanel,"Teleport",C.Accent)
local _,coordTB=Inp(MovePanel,"X Y Z (e.g. 0 100 0)",nil,C.Accent)
Btn(MovePanel,"Teleport To Coords",function()
    local root=GetRoot(); if not root or not coordTB then return end
    local nums={}; for n in coordTB.Text:gmatch("[%-]?%d+%.?%d*") do nums[#nums+1]=tonumber(n) end
    if #nums>=3 then root.CFrame=CFrame.new(nums[1],nums[2],nums[3]); Notify("Move","Teleported!",2) end
end,C.Accent)

Sec(MovePanel,"My Size",C.Orange)
Sldr(MovePanel,"Body Size",0.05,15,1,function(v) SetSize(LP,v) end,C.Orange)
Btn(MovePanel,"Normal Size",function() SetSize(LP,1) end,C.Green)

-- ============================================================
-- BUILD MUSIC PANEL
-- ============================================================
local MusicPanel=MakePanel("Music")

local npCard=Fr(MusicPanel,UDim2.new(1,0,0,76),nil,C.Card,0); npCard.ZIndex=12; Crn(npCard,14); Strk(npCard,C.Blue,1)
NPLabel=Instance.new("TextLabel"); NPLabel.Size=UDim2.new(1,-14,0,26); NPLabel.Position=UDim2.new(0,10,0,8)
NPLabel.BackgroundTransparency=1; NPLabel.Text="Now Playing: --"; NPLabel.TextSize=13; NPLabel.Font=Enum.Font.GothamBold
NPLabel.TextColor3=C.Blue; NPLabel.TextXAlignment=Enum.TextXAlignment.Left; NPLabel.TextWrapped=true; NPLabel.ZIndex=13; NPLabel.Parent=npCard
local statusLbl=Instance.new("TextLabel"); statusLbl.Size=UDim2.new(1,-14,0,18); statusLbl.Position=UDim2.new(0,10,0,38)
statusLbl.BackgroundTransparency=1; statusLbl.Text="Status: Stopped"; statusLbl.TextSize=11; statusLbl.Font=Enum.Font.GothamBold
statusLbl.TextColor3=C.Red; statusLbl.TextXAlignment=Enum.TextXAlignment.Left; statusLbl.ZIndex=13; statusLbl.Parent=npCard
local volLbl=Instance.new("TextLabel"); volLbl.Size=UDim2.new(0.5,0,0,16); volLbl.Position=UDim2.new(0.5,0,0,56)
volLbl.BackgroundTransparency=1; volLbl.Text="Vol: 80% | Global"; volLbl.TextSize=10; volLbl.Font=Enum.Font.Gotham
volLbl.TextColor3=C.Dim; volLbl.TextXAlignment=Enum.TextXAlignment.Left; volLbl.ZIndex=13; volLbl.Parent=npCard

-- Controls row
local ctrlRow=Fr(MusicPanel,UDim2.new(1,0,0,54),nil,C.Card,0); ctrlRow.ZIndex=12; Crn(ctrlRow,14)
HList(ctrlRow,5,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)
Pad(ctrlRow,6,6,8,8)
local function CB(t,col,fn)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(0,64,0,42)
    b.BackgroundColor3=col; b.BackgroundTransparency=0.2; b.Text=t; b.TextColor3=C.White
    b.TextSize=12; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=13; b.Parent=ctrlRow
    Crn(b,10); b.MouseButton1Click:Connect(function() if fn then fn() end end); return b
end
CB("PREV",C.Blue,function()
    ST.SongIdx=((ST.SongIdx-2) % #SONGS)+1; local s=SONGS[ST.SongIdx]; PlaySong(s.id,s.n)
    statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
end)
CB("PLAY",C.Green,function()
    if ST.MusicOn then MusicSound:Pause(); ST.MusicOn=false; statusLbl.Text="Status: Paused"; statusLbl.TextColor3=C.Yellow
    else if ST.SongID then MusicSound:Play(); ST.MusicOn=true
         else local s=SONGS[ST.SongIdx]; PlaySong(s.id,s.n) end
         statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green end
end)
CB("STOP",C.Red,function() StopMusic(); statusLbl.Text="Status: Stopped"; statusLbl.TextColor3=C.Red end)
CB("NEXT",C.Blue,function()
    ST.SongIdx=(ST.SongIdx % #SONGS)+1; local s=SONGS[ST.SongIdx]; PlaySong(s.id,s.n)
    statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
end)

Tog(MusicPanel,"Loop Song",false,function(on) ST.MusicLoop=on; MusicSound.Looped=on end,C.Blue)
Sldr(MusicPanel,"Volume",0,100,80,function(v)
    ST.MusicVol=v/100; MusicSound.Volume=ST.MusicVol; volLbl.Text="Vol: "..v.."% | Global"
end,C.Blue)

Sec(MusicPanel,"Custom Song ID",C.Blue)
local _,custTB=Inp(MusicPanel,"Roblox Sound ID...",nil,C.Blue)
Btn(MusicPanel,"Play Custom ID",function()
    if custTB then local id=custTB.Text:match("%d+")
        if id then PlaySong(id,"Custom #"..id); statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green end
    end
end,C.Blue)

Sec(MusicPanel,"Library | "..#SONGS.." Songs",C.Blue)
for i,song in ipairs(SONGS) do
    local row=Fr(MusicPanel,UDim2.new(1,0,0,52),nil,C.Card,i%2==0 and 0.4 or 0.6)
    row.ZIndex=12; Crn(row,10)
    local sn=Instance.new("TextLabel"); sn.Size=UDim2.new(1,-80,0,26); sn.Position=UDim2.new(0,8,0,4)
    sn.BackgroundTransparency=1; sn.Text=i..". "..song.n; sn.TextSize=12; sn.Font=Enum.Font.GothamSemibold
    sn.TextColor3=C.Text; sn.TextXAlignment=Enum.TextXAlignment.Left; sn.ZIndex=13; sn.Parent=row
    local pb=Instance.new("TextButton"); pb.Size=UDim2.new(0,56,0,34); pb.Position=UDim2.new(1,-64,0.5,-17)
    pb.BackgroundColor3=C.Blue; pb.BackgroundTransparency=0.2; pb.Text="PLAY"
    pb.TextColor3=C.White; pb.TextSize=11; pb.Font=Enum.Font.GothamBold; pb.BorderSizePixel=0; pb.ZIndex=13; pb.Parent=row
    Crn(pb,10); pb.MouseButton1Click:Connect(function()
        ST.SongIdx=i; PlaySong(song.id,song.n)
        statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
    end)
end

-- ============================================================
-- BUILD PROTECT PANEL
-- ============================================================
local ProtPanel=MakePanel("Protect")

Sec(ProtPanel,"Protection",C.Yellow)
Tog(ProtPanel,"God Mode (loop HP)",false,function(on) ST.GodMode=on; SetGod(on) end,C.Yellow)
Tog(ProtPanel,"Invisible (client local)",false,function(on) ST.Invisible=on; SetInvisible(on) end,C.Yellow)
Tog(ProtPanel,"Fullbright",false,function(on) SetFullbright(on) end,C.Yellow)
Tog(ProtPanel,"Infinite Jump",false,function(on) ST.InfJump=on; SetInfJump(on) end,C.Green)
Tog(ProtPanel,"Anti-Void (auto save)",false,function(on)
    if on then StartAntiVoid() else StopAntiVoid() end
end,C.Teal)
Tog(ProtPanel,"Anti-AFK",false,function(on)
    if on then
        local VU=pcall(function() return game:GetService("VirtualUser") end) and game:GetService("VirtualUser")
        if VU then
            _G.__KaelenAntiAFK=RunService.Heartbeat:Connect(function()
                pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
            end)
        end
    else
        if _G.__KaelenAntiAFK then _G.__KaelenAntiAFK:Disconnect() _G.__KaelenAntiAFK=nil end
    end
end,C.Teal)

Sec(ProtPanel,"Quick Actions",C.Yellow)
Btn(ProtPanel,"Reset Velocity",function()
    local root=GetRoot(); if root then root.Velocity=Vector3.zero end; Notify("Protect","Reset velocity",2)
end,C.Yellow)
Btn(ProtPanel,"Unanchor Self",function()
    local char=GetChar(); if char then
        for _,v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.Anchored=false end end
    end; Notify("Protect","Unanchored",2)
end,C.Yellow)
Btn(ProtPanel,"Full Heal",function()
    local hum=GetHum(); if hum then hum.Health=hum.MaxHealth end; Notify("Protect","Healed!",2)
end,C.Green)
Btn(ProtPanel,"Respawn",function() LP:LoadCharacter() end,C.Red)

Sec(ProtPanel,"My Size",C.Orange)
Sldr(ProtPanel,"Body Size",0.05,10,1,function(v) SetSize(LP,v) end,C.Orange)
Btn(ProtPanel,"Normal Size",function() SetSize(LP,1) end,C.Green)

-- ============================================================
-- BUILD ESP PANEL
-- ============================================================
local ESPPanel=MakePanel("ESP")

Sec(ESPPanel,"Visuals",C.Teal)
Tog(ESPPanel,"Player ESP (SelectionBox)",false,function(on) ST.ESPOn=on; UpdateESP(on) end,C.Teal)
Btn(ESPPanel,"Refresh ESP",function()
    if ST.ESPOn then UpdateESP(false); task.wait(0.1); UpdateESP(true) end; Notify("ESP","Refreshed",2)
end,C.Teal)

Sec(ESPPanel,"Player List",C.Teal)
local function BuildPlayerList()
    for _,ch in pairs(ESPPanel:GetChildren()) do if ch.Name=="PLCard" then ch:Destroy() end end
    for _,p in ipairs(Players:GetPlayers()) do
        local card=Fr(ESPPanel,UDim2.new(1,0,0,68),nil,C.Card,0)
        card.Name="PLCard"; card.ZIndex=12; Crn(card,12); Strk(card,C.Border,1)
        local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.6,0,0,24); nl.Position=UDim2.new(0,10,0,6)
        nl.BackgroundTransparency=1; nl.Text=(p==LP and "[YOU] " or "")..p.Name; nl.TextSize=13
        nl.Font=Enum.Font.GothamBold; nl.TextColor3=p==LP and C.Green or C.Text; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.ZIndex=13; nl.Parent=card
        local char=p.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
        local root=char and char:FindFirstChild("HumanoidRootPart"); local myR=GetRoot()
        local dist=root and myR and math.floor((root.Position-myR.Position).Magnitude) or "?"
        local hp=hum and math.floor(hum.Health) or "?"
        local il=Instance.new("TextLabel"); il.Size=UDim2.new(0.6,0,0,18); il.Position=UDim2.new(0,10,0,32)
        il.BackgroundTransparency=1; il.Text="HP "..hp.." | "..dist.."m"; il.TextSize=11
        il.Font=Enum.Font.Gotham; il.TextColor3=C.Dim; il.TextXAlignment=Enum.TextXAlignment.Left; il.ZIndex=13; il.Parent=card
        -- Small action buttons
        local bRow=Fr(card,UDim2.new(0.38,0,1,0),UDim2.new(0.62,0,0,0),C.BG,1); bRow.ZIndex=13
        HList(bRow,4,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center)
        Pad(bRow,4,4,4,4)
        local function SB(t,col,fn)
            local b=Instance.new("TextButton"); b.Size=UDim2.new(0,40,0,28)
            b.BackgroundColor3=col; b.BackgroundTransparency=0.2; b.Text=t; b.TextColor3=C.White
            b.TextSize=10; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=14; b.Parent=bRow
            Crn(b,8); b.MouseButton1Click:Connect(function() if fn then pcall(fn) end end)
        end
        SB("TP",C.Accent,function()
            local myRoot=GetRoot(); local tRoot=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and tRoot then myRoot.CFrame=tRoot.CFrame*CFrame.new(0,0,4) end
        end)
        SB("Fling",C.Red,function()
            local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if root then root.Velocity=Vector3.new(math.random(-1,1)*5000,3000,math.random(-1,1)*5000) end
        end)
        SB("Kill",Color3.fromRGB(200,0,0),function()
            local hum2=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
            if hum2 then hum2.Health=0 end
        end)
    end
end
Btn(ESPPanel,"Refresh List",BuildPlayerList,C.Teal)
BuildPlayerList()
Players.PlayerAdded:Connect(function() task.wait(1); BuildPlayerList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); BuildPlayerList() end)

-- ============================================================
-- BUILD UTIL PANEL
-- ============================================================
local UtilPanel=MakePanel("Util")

Sec(UtilPanel,"Server",C.Pink)
Btn(UtilPanel,"Rejoin",function()
    game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
end,C.Pink)
Btn(UtilPanel,"Server Hop",function()
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

Sec(UtilPanel,"Lighting & World",C.Orange)
Sldr(UtilPanel,"Clock Time",0,24,14,function(v) Lighting.ClockTime=v end,C.Orange)
Sldr(UtilPanel,"Gravity",0,400,196,function(v) workspace.Gravity=v end,C.Orange)
Sldr(UtilPanel,"Fog End",100,999999,999999,function(v) Lighting.FogEnd=v; Lighting.FogStart=v*0.8 end,C.Orange)
Btn(UtilPanel,"Night",function() Lighting.ClockTime=0; Lighting.Brightness=0.3 end,Color3.fromRGB(20,20,60))
Btn(UtilPanel,"Day",function() Lighting.ClockTime=14; Lighting.Brightness=2 end,Color3.fromRGB(255,220,100))
Btn(UtilPanel,"Zero Gravity",function() workspace.Gravity=2; Notify("World","Zero-G!",2) end,C.Blue)
Btn(UtilPanel,"Normal Gravity",function() workspace.Gravity=196 end,C.Green)
Btn(UtilPanel,"Moon Gravity",function() workspace.Gravity=30; Notify("World","Moon-G!",2) end,C.Dim)

Sec(UtilPanel,"Info",C.Dim)
local infoF=Fr(UtilPanel,UDim2.new(1,0,0,80),nil,C.Card,0); infoF.ZIndex=12; Crn(infoF,12); Pad(infoF,8,8,12,12)
local il2=Instance.new("TextLabel"); il2.Size=UDim2.new(1,0,1,0); il2.BackgroundTransparency=1
il2.Text="PlaceID: "..game.PlaceId.."\nPlayers: "..#Players:GetPlayers().."/"..Players.MaxPlayers
il2.TextSize=11; il2.Font=Enum.Font.Gotham; il2.TextColor3=C.Dim; il2.TextXAlignment=Enum.TextXAlignment.Left
il2.TextYAlignment=Enum.TextYAlignment.Top; il2.TextWrapped=true; il2.ZIndex=13; il2.Parent=infoF

-- ============================================================
-- BUILD PLAYERS PANEL
-- ============================================================
local PlayersPanel=MakePanel("Players")

Sec(PlayersPanel,"Mass Actions",C.Orange)
Btn(PlayersPanel,"Fling EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local root=p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                task.spawn(function()
                    for i=1,5 do
                        root.Velocity=Vector3.new(math.random(-1,1)*6000,5000,math.random(-1,1)*6000)
                        task.wait(0.05)
                    end
                end)
            end
        end
    end; Notify("Troll","EVERYONE FLUNG!",2)
end,C.Red)
Btn(PlayersPanel,"Launch EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Launch(p,1500) end end
end,C.Orange)
Btn(PlayersPanel,"Explode EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Explode(p) end end
end,C.Red)
Btn(PlayersPanel,"Freeze EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do if p~=LP then Freeze(p) end end; Notify("Troll","All frozen!",2)
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
Btn(PlayersPanel,"Kill EVERYONE",function()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            local hum=p.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health=0 end
        end
    end
end,C.Red)

Sec(PlayersPanel,"Chat Broadcast",C.Yellow)
local _,broadTB=Inp(PlayersPanel,"Broadcast message...",nil,C.Yellow)
Btn(PlayersPanel,"Broadcast",function()
    if broadTB and broadTB.Text~="" then ChatMsg(broadTB.Text) end
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

if _G.__KH3Min then _G.__KH3Min.MouseButton1Click:Connect(TogMin) end
if _G.__KH3Cls then _G.__KH3Cls.MouseButton1Click:Connect(CloseWindow) end

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
SetTab("Troll")
task.wait(0.3)
Notify("Kaelen Hub v3","IY Edition loaded! | "..#SONGS.." songs | Tap K to open",5)
print("╔══════════════════════════════════════╗")
print("║   Kaelen Hub v3.0 - IY Edition       ║")
print("║   IY Fling + Spin + Headsit + Fly    ║")
print("║   "..#SONGS.." songs | by crx-ter | Delta    ║")
print("╚══════════════════════════════════════╝")
