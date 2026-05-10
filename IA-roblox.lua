-- Kaelen Hub v2.0 --
-- iOS Style | Mobile Optimized | Delta Compatible | Infinite Yield Logic
-- Features: All IY Troll Commands, Movement, Music, Protection, ESP, Utilities

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local MarketplaceService=game:GetService("MarketplaceService")
local Debris           = game:GetService("Debris")
local PhysicsService   = game:GetService("PhysicsService")
local SoundService     = game:GetService("SoundService")
local TextService      = game:GetService("TextService")
local VirtualUser      = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Camera      = workspace.CurrentCamera

-- ============================================================
--  CONFIG
-- ============================================================
local C = {
    BG          = Color3.fromRGB(8, 8, 16),
    Panel       = Color3.fromRGB(15, 15, 28),
    Card        = Color3.fromRGB(22, 22, 38),
    CardHov     = Color3.fromRGB(30, 30, 50),
    Accent      = Color3.fromRGB(110, 72, 255),
    Accent2     = Color3.fromRGB(72, 170, 255),
    Pink        = Color3.fromRGB(255, 72, 172),
    Green       = Color3.fromRGB(72, 255, 150),
    Red         = Color3.fromRGB(255, 72, 72),
    Orange      = Color3.fromRGB(255, 152, 50),
    Yellow      = Color3.fromRGB(255, 220, 50),
    Teal        = Color3.fromRGB(50, 220, 200),
    Text        = Color3.fromRGB(238, 238, 255),
    TextDim     = Color3.fromRGB(130, 130, 170),
    Border      = Color3.fromRGB(45, 45, 75),
    OffBtn      = Color3.fromRGB(45, 45, 68),
    White       = Color3.new(1,1,1),
}

-- ============================================================
--  STATE
-- ============================================================
local ST = {
    Open        = false,
    Mini        = false,
    Tab         = "Troll",
    -- Movement
    Flying      = false,
    FlySpd      = 60,
    Noclip      = false,
    InfJump     = false,
    ClickTP     = false,
    Speed       = 16,
    Jump        = 50,
    -- Troll active
    Spinning    = false,
    SpinSpeed   = 10,
    Attaching   = false,
    Floating    = false,
    Headsitting = false,
    TrollTarget = nil,
    -- Protection
    GodMode     = false,
    Invisible   = false,
    Fullbright  = false,
    -- ESP
    ESPOn       = false,
    -- Music
    MusicOn     = false,
    MusicLoop   = false,
    MusicVol    = 0.8,
    SongIdx     = 1,
    SongID      = nil,
    -- Checkpoints
    CPs         = {},
    -- Misc
    OrigBright  = Lighting.Brightness,
    OrigAmb     = Lighting.Ambient,
    OrigOutAmb  = Lighting.OutdoorAmbient,
    OrigClock   = Lighting.ClockTime,
    AntiAFK     = false,
    Gravity     = 196,
}

-- ============================================================
--  SONG LIST
-- ============================================================
local SONGS = {
    {n="<3",                      id="109781016044674"},
    {n="Dusk",                    id="106475212474249"},
    {n="I'll Go",                 id="5410081298"},
    {n="GateHouse",               id="137409529549092"},
    {n="Sprite",                  id="5410083814"},
    {n="Stayin Alive",            id="132440988854807"},
    {n="Crab Rave",               id="5410086218"},
    {n="Cant See The Moonlight",  id="137072588403399"},
    {n="Sun Sprinting",           id="134698083808996"},
    {n="BackOnTree",              id="95608981665777"},
    {n="Deceptica",               id="79716563884770"},
    {n="Am I Too Late",           id="89804818669338"},
    {n="MovementRhythm",          id="77249446861960"},
    {n="Hold On Sped Up",         id="71045969776776"},
    {n="I Cant - Tony Romera",    id="5410082805"},
    {n="Never Be The One",        id="111990911956281"},
    {n="Starfall",                id="101934851079098"},
    {n="Run Away",                id="128118999630439"},
    {n="Total Confusion",         id="103419239604004"},
    {n="Jumpstyle",               id="1839246711"},
    {n="Techno Rave",             id="125418384596720"},
    {n="Fell It",                 id="109475460178206"},
    {n="TECHNO",                  id="73520333282970"},
    {n="MEMORIES Rave",           id="98432184550661"},
    {n="Rave Romance",            id="80345427689122"},
    {n="Hardstyle",               id="1839246774"},
    {n="EDM Vegas",               id="1842683759"},
    {n="Dreamraver",              id="138577643632319"},
    {n="Rave Hearts Collide",     id="96069332582271"},
    {n="Never Be The One",        id="111990911956281"},
    {n="i didn't see it",         id="103902016839820"},
    {n="Skylines",                id="85762528306791"},
    {n="Right here in my arms",   id="79627520866718"},
    {n="Join me in death",        id="106344107023335"},
    {n="InnerAwakening",          id="76585504240155"},
    {n="Banana Bashin",           id="118231802185865"},
    {n="Woo Woo Woo Woo",         id="77139878722989"},
    {n="I Miss You",              id="125460168433130"},
    {n="Lo-fi Chill A",           id="9043887091"},
    {n="Relaxed Scene",           id="1848354536"},
    {n="Piano In The Dark",       id="1836291588"},
    {n="Moonlit Memories",        id="90866117181187"},
    {n="Capybara",                id="99099326829992"},
    {n="blossom",                 id="136212040250804"},
    {n="Crimson Vision",          id="105214146426572"},
    {n="Ambient Blue",            id="139952467445591"},
    {n="Claire De Lune",          id="1838457617"},
    {n="Nocturne",                id="129108903964685"},
    {n="Velvet Midnight",         id="82091048635749"},
    {n="Dear Lana",               id="119589412825080"},
    {n="SAD!",                    id="72320758533508"},
    {n="plug do rj",              id="129154320419135"},
    {n="BRAZIL DO FUNK",          id="133498554139200"},
    {n="CRYSTAL FUNK",            id="103445348511856"},
    {n="MONTAGEM DANCE RAT",      id="112903678064836"},
    {n="SEA OF PHONK",            id="130367831349871"},
    {n="BAILE FUNK",              id="104880194210827"},
    {n="GOTH FUNK",               id="140704128008979"},
    {n="AURA DEFINED Slowed",     id="109805678713575"},
    {n="BRX PHONK",               id="17422074849"},
    {n="YOTO HIME PHONK",         id="103183298894656"},
    {n="BEM SOLTO BRAZIL",        id="119936139925486"},
    {n="HOTAKFUNK",               id="79314929106323"},
    {n="NEXOVA",                  id="127388462601694"},
    {n="PHONK ULTRA",             id="134839199346188"},
    {n="Demon Phonk Drive",       id="72793675791485"},
    {n="Din1c - Can you",         id="15689448519"},
    {n="Din1c - INVASION",        id="15689453529"},
    {n="Din1c - METAMORPHOSIS",   id="15689451063"},
    {n="Cowbell God",             id="16190760005"},
    {n="Mezcla Espanola 1",       id="124263849663656"},
    {n="UNIVERSO",                id="95518661042892"},
    {n="Cumbia De Los Cholos",    id="77246411659544"},
    {n="Aunque Ella No Lo llore", id="101010703654195"},
    {n="Vine Boom",               id="6823153536"},
    {n="Wii Sports R&B",          id="72697308378715"},
    {n="THE POWER OF ANIME",      id="1226918619"},
    {n="AUUUUUGH",                id="8893545897"},
    {n="Better Call Saul",        id="9106904975"},
    {n="oh my goodness SQUIDwarD",id="132575703"},
    {n="HEHEHE HA",               id="8406005582"},
    {n="Deja vu Initial D",       id="16831106636"},
    {n="TECHNO RAVE RUSH",        id="80517351052799"},
    {n="Offer To All",            id="137363969120954"},
    {n="New Digital Life",        id="138974854130682"},
    {n="Take Me Back",            id="138073768482180"},
    {n="Human Precipice",         id="128296878284393"},
    {n="Ooh La La",               id="110334475372294"},
    {n="Energic Rave",            id="1836029357"},
    {n="Electro Boost",           id="1839246807"},
    {n="Euro Techno",             id="1839246734"},
    {n="Fast Rave",               id="1839246840"},
}

-- ============================================================
--  HELPERS
-- ============================================================
local function Tw(obj, props, dur, sty, dir)
    sty = sty or Enum.EasingStyle.Quart
    dir = dir or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(dur or 0.3, sty, dir), props)
    t:Play(); return t
end

local function Crn(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = type(r)=="number" and UDim.new(0,r) or (r or UDim.new(0,16))
    c.Parent = p; return c
end

local function Strk(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or C.Border
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function Pad(p, t, b, l, r)
    local x = Instance.new("UIPadding")
    x.PaddingTop    = UDim.new(0, t or 8)
    x.PaddingBottom = UDim.new(0, b or 8)
    x.PaddingLeft   = UDim.new(0, l or 8)
    x.PaddingRight  = UDim.new(0, r or 8)
    x.Parent = p; return x
end

local function LL(p, dir, sp, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.Padding = UDim.new(0, sp or 8)
    l.HorizontalAlignment = ha or Enum.HorizontalAlignment.Center
    l.VerticalAlignment = va or Enum.VerticalAlignment.Top
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p; return l
end

local function GL(p, cs, cps)
    local g = Instance.new("UIGridLayout")
    g.CellSize = cs or UDim2.new(0.48, -4, 0, 58)
    g.CellPaddingSize = cps or UDim2.new(0, 6, 0, 6)
    g.SortOrder = Enum.SortOrder.LayoutOrder
    g.HorizontalAlignment = Enum.HorizontalAlignment.Center
    g.Parent = p; return g
end

local function Fr(p, sz, pos, bg, tr)
    local f = Instance.new("Frame")
    f.Size = sz or UDim2.new(1,0,1,0)
    f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = bg or C.Card
    f.BackgroundTransparency = tr or 0
    f.BorderSizePixel = 0
    f.Parent = p; return f
end

local function Lbl(p, txt, sz, col, font, xa, ya)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = txt or ""
    l.TextSize = sz or 14
    l.TextColor3 = col or C.Text
    l.Font = font or Enum.Font.GothamBold
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = ya or Enum.TextYAlignment.Center
    l.Size = UDim2.new(1,0,0,(sz or 14)+8)
    l.TextWrapped = true
    l.Parent = p; return l
end

local function Scr(p, sz, pos)
    local s = Instance.new("ScrollingFrame")
    s.Size = sz or UDim2.new(1,0,1,0)
    s.Position = pos or UDim2.new(0,0,0,0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = C.Accent
    s.CanvasSize = UDim2.new(0,0,0,0)
    s.ScrollingDirection = Enum.ScrollingDirection.Y
    s.Parent = p
    -- Canvas auto-update: connect after layout is added
    local _canvasConnected = false
    s.ChildAdded:Connect(function(child)
        if _canvasConnected then return end
        task.wait(0.1)
        local layout = s:FindFirstChildOfClass("UIListLayout") or s:FindFirstChildOfClass("UIGridLayout")
        if layout then
            _canvasConnected = true
            local function update()
                s.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 60)
            end
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
            update()
        end
    end)
    return s
end

local function Notify(title, msg, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification",{
            Title=title, Text=msg, Duration=dur or 3
        })
    end)
end

local function GetChar() return LocalPlayer.Character end
local function GetRoot()
    local c = GetChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function GetHead()
    local c = GetChar(); return c and c:FindFirstChild("Head")
end

local function SafeDestroy(inst)
    if inst and inst.Parent then inst:Destroy() end
end

-- ============================================================
--  GUI ROOT
-- ============================================================
local PGui = LocalPlayer:WaitForChild("PlayerGui")
local oldHub = PGui:FindFirstChild("KaelenHubV2")
if oldHub then oldHub:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name             = "KaelenHubV2"
SG.ResetOnSpawn     = false
SG.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder     = 999
SG.IgnoreGuiInset   = true
SG.Parent           = PGui

-- ============================================================
--  FLOAT BUTTON
-- ============================================================
local FB = Instance.new("ImageButton")
FB.Name            = "FloatBtn"
FB.Size            = UDim2.new(0,72,0,72)
FB.Position        = UDim2.new(0,14,0.5,-36)
FB.BackgroundColor3= C.Accent
FB.BorderSizePixel = 0
FB.ZIndex          = 20
FB.Parent          = SG
Crn(FB, UDim.new(1,0))

local fbGrad = Instance.new("UIGradient")
fbGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.Accent),
    ColorSequenceKeypoint.new(1, C.Pink),
})
fbGrad.Rotation = 135
fbGrad.Parent = FB

local fbLabel = Instance.new("TextLabel")
fbLabel.Size = UDim2.new(1,0,1,0)
fbLabel.BackgroundTransparency = 1
fbLabel.Text = "K"
fbLabel.TextSize = 30
fbLabel.Font = Enum.Font.GothamBold
fbLabel.TextColor3 = C.White
fbLabel.ZIndex = 21
fbLabel.Parent = FB

-- Pulse ring animation
local function StartPulse()
    task.spawn(function()
        while FB and FB.Parent do
            local ring = Instance.new("Frame")
            ring.Size = UDim2.new(1,0,1,0)
            ring.Position = UDim2.new(0,0,0,0)
            ring.BackgroundTransparency = 1
            ring.BorderSizePixel = 0
            ring.AnchorPoint = Vector2.new(0.5,0.5)
            ring.Position = UDim2.new(0.5,0,0.5,0)
            ring.ZIndex = 19
            ring.Parent = FB
            Crn(ring, UDim.new(1,0))
            Strk(ring, C.Accent, 2)
            Tw(ring, {Size=UDim2.new(2,0,2,0), Position=UDim2.new(-0.5,0,-0.5,0)}, 1, Enum.EasingStyle.Sine)
            local st = ring:FindFirstChildOfClass("UIStroke")
            if st then Tw(st, {Transparency=1}, 1, Enum.EasingStyle.Sine) end
            task.wait(1)
            SafeDestroy(ring)
            task.wait(0.8)
        end
    end)
end
StartPulse()

-- ============================================================
--  MAIN FRAME
-- ============================================================
local MF = Instance.new("Frame")
MF.Name                   = "MainFrame"
MF.AnchorPoint            = Vector2.new(0.5,0.5)
MF.Size                   = UDim2.new(0,0,0,0)
MF.Position               = UDim2.new(0.5,0,0.5,0)
MF.BackgroundColor3       = C.BG
MF.BackgroundTransparency = 0.05
MF.BorderSizePixel        = 0
MF.Visible                = false
MF.ClipsDescendants       = true
MF.ZIndex                 = 10
MF.Parent                 = SG
Crn(MF, 18)
Strk(MF, C.Border, 1)

local mfGrad = Instance.new("UIGradient")
mfGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,16,36)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,8,18)),
})
mfGrad.Rotation = 135
mfGrad.Parent = MF

-- ============================================================
--  HEADER
-- ============================================================
local HDR = Fr(MF, UDim2.new(1,0,0,58), UDim2.new(0,0,0,0), C.Panel, 0)
HDR.ZIndex = 11
Crn(HDR, 18) -- top corners only via gradient
do
    local hg = Instance.new("UIGradient")
    hg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28,18,52)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14,12,28)),
    })
    hg.Rotation = 90
    hg.Parent = HDR

    -- Logo dot
    local dot = Fr(HDR, UDim2.new(0,8,0,8), UDim2.new(0,14,0.5,-4), C.Accent, 0)
    Crn(dot, UDim.new(1,0))
    dot.ZIndex = 12

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(0,180,0,24)
    titleLbl.Position = UDim2.new(0,28,0,8)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "Kaelen Hub"
    titleLbl.TextSize = 18
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextColor3 = C.White
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 12
    titleLbl.Parent = HDR

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(0,180,0,16)
    subLbl.Position = UDim2.new(0,28,0,32)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "v2.0 | IY Edition | by crx-ter"
    subLbl.TextSize = 11
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextColor3 = C.TextDim
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.ZIndex = 12
    subLbl.Parent = HDR

    -- Min button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0,38,0,38)
    MinBtn.Position = UDim2.new(1,-90,0.5,-19)
    MinBtn.BackgroundColor3 = C.Orange
    MinBtn.BackgroundTransparency = 0.2
    MinBtn.Text = "—"
    MinBtn.TextColor3 = C.White
    MinBtn.TextSize = 18
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.ZIndex = 12
    MinBtn.Parent = HDR
    Crn(MinBtn, 10)

    -- Close button
    local ClsBtn = Instance.new("TextButton")
    ClsBtn.Size = UDim2.new(0,38,0,38)
    ClsBtn.Position = UDim2.new(1,-46,0.5,-19)
    ClsBtn.BackgroundColor3 = C.Red
    ClsBtn.BackgroundTransparency = 0.2
    ClsBtn.Text = "✕"
    ClsBtn.TextColor3 = C.White
    ClsBtn.TextSize = 16
    ClsBtn.Font = Enum.Font.GothamBold
    ClsBtn.BorderSizePixel = 0
    ClsBtn.ZIndex = 12
    ClsBtn.Parent = HDR
    Crn(ClsBtn, 10)

    -- These connect after OpenWindow/CloseWindow are declared below
    _G.__KaelenMinBtn = MinBtn
    _G.__KaelenClsBtn = ClsBtn
end

-- Header Drag
local hdrDrag, hdrDragStart, hdrStartPos, hdrDragDist = false, nil, nil, 0
HDR.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        hdrDrag = true; hdrDragDist = 0
        hdrDragStart = inp.Position
        hdrStartPos  = MF.Position
    end
end)
HDR.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        hdrDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if hdrDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local vp = Camera.ViewportSize
        local d  = inp.Position - hdrDragStart
        hdrDragDist = hdrDragDist + math.abs(d.X) + math.abs(d.Y)
        local nx = math.clamp(hdrStartPos.X.Scale + d.X/vp.X, 0.08, 0.92)
        local ny = math.clamp(hdrStartPos.Y.Scale + d.Y/vp.Y, 0.08, 0.92)
        MF.Position = UDim2.new(nx,0,ny,0)
    end
end)

-- ============================================================
--  TAB BAR
-- ============================================================
local TABS = {
    {id="Troll",   label="Troll",   col=C.Red},
    {id="Move",    label="Move",    col=C.Green},
    {id="Music",   label="Music",   col=C.Accent2},
    {id="Protect", label="Protect", col=C.Yellow},
    {id="ESP",     label="ESP",     col=C.Teal},
    {id="Util",    label="Util",    col=C.Pink},
    {id="Players", label="Players", col=C.Orange},
}

local TabBarOuter = Fr(MF, UDim2.new(1,0,0,50), UDim2.new(0,0,0,58), C.Panel, 0)
TabBarOuter.ZIndex = 11

local TabScr = Instance.new("ScrollingFrame")
TabScr.Size = UDim2.new(1,0,1,0)
TabScr.BackgroundTransparency = 1
TabScr.BorderSizePixel = 0
TabScr.ScrollBarThickness = 0
TabScr.ScrollingDirection = Enum.ScrollingDirection.X
TabScr.CanvasSize = UDim2.new(0, #TABS*92, 0, 0)
TabScr.ZIndex = 11
TabScr.Parent = TabBarOuter
Pad(TabScr, 6,6,8,8)
LL(TabScr, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

local TabBtns = {}

-- Panel container
local PC = Fr(MF, UDim2.new(1,0,1,-108), UDim2.new(0,0,0,108), C.BG, 1)
PC.ZIndex = 10
PC.ClipsDescendants = true

local function SetTab(id)
    ST.Tab = id
    for _, info in ipairs(TABS) do
        local b = TabBtns[info.id]
        if not b then continue end
        if info.id == id then
            Tw(b, {BackgroundColor3=info.col, BackgroundTransparency=0.1}, 0.2)
            b.TextColor3 = C.White
        else
            Tw(b, {BackgroundColor3=C.Card, BackgroundTransparency=0.5}, 0.2)
            b.TextColor3 = C.TextDim
        end
    end
    for _, ch in pairs(PC:GetChildren()) do
        if ch:IsA("Frame") or ch:IsA("ScrollingFrame") then
            ch.Visible = ch.Name == id
        end
    end
end

for i, info in ipairs(TABS) do
    local b = Instance.new("TextButton")
    b.Name = info.id
    b.Size = UDim2.new(0,85,0,38)
    b.BackgroundColor3 = C.Card
    b.BackgroundTransparency = 0.5
    b.Text = info.label
    b.TextColor3 = C.TextDim
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.LayoutOrder = i
    b.ZIndex = 12
    b.Parent = TabScr
    Crn(b, 12)
    TabBtns[info.id] = b
    b.MouseButton1Click:Connect(function() SetTab(info.id) end)
end

-- ============================================================
--  UI COMPONENT BUILDERS
-- ============================================================
local function MakeScrollPanel(name)
    local s = Scr(PC, UDim2.new(1,0,1,0))
    s.Name = name
    s.Visible = false
    s.ZIndex = 11
    Pad(s, 10, 20, 10, 10)
    LL(s, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)
    return s
end

local function Section(parent, text, col)
    local f = Fr(parent, UDim2.new(1,0,0,32), nil, C.Panel, 0)
    f.ZIndex = 12
    Crn(f, 8)
    local bar = Fr(f, UDim2.new(0,3,0,18), UDim2.new(0,0,0.5,-9), col or C.Accent, 0)
    Crn(bar, UDim.new(1,0))
    bar.ZIndex = 13
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,-14,1,0)
    l.Position = UDim2.new(0,10,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = 12
    l.Font = Enum.Font.GothamBold
    l.TextColor3 = col or C.Accent
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 13
    l.Parent = f
    return f
end

local function Toggle(parent, text, default, onTog, col)
    col = col or C.Accent
    local on = default or false
    local f = Fr(parent, UDim2.new(1,0,0,58), nil, C.Card, 0)
    f.ZIndex = 12
    Crn(f, 14)
    Strk(f, C.Border, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-72,1,0)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextColor3 = C.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.ZIndex = 13
    lbl.Parent = f

    local pill = Fr(f, UDim2.new(0,50,0,26), UDim2.new(1,-62,0.5,-13), C.OffBtn, 0)
    Crn(pill, UDim.new(1,0))
    pill.ZIndex = 13

    local knob = Fr(pill, UDim2.new(0,20,0,20), UDim2.new(0,3,0.5,-10), C.White, 0)
    Crn(knob, UDim.new(1,0))
    knob.ZIndex = 14

    local function upd()
        if on then
            Tw(pill, {BackgroundColor3=col}, 0.2)
            Tw(knob, {Position=UDim2.new(0,27,0.5,-10)}, 0.2)
        else
            Tw(pill, {BackgroundColor3=C.OffBtn}, 0.2)
            Tw(knob, {Position=UDim2.new(0,3,0.5,-10)}, 0.2)
        end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15
    btn.Parent = f
    btn.MouseButton1Click:Connect(function()
        on = not on; upd()
        if onTog then onTog(on) end
    end)

    upd()
    return f, function() return on end, function(v) on=v; upd() end
end

local function Btn(parent, text, onClick, col, h)
    col = col or C.Accent
    h = h or 58
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,h)
    b.BackgroundColor3 = col
    b.BackgroundTransparency = 0.2
    b.Text = text
    b.TextColor3 = C.White
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 12
    b.Parent = parent
    Crn(b, 14)
    b.MouseButton1Click:Connect(function()
        Tw(b, {BackgroundTransparency=0}, 0.1)
        task.wait(0.12)
        Tw(b, {BackgroundTransparency=0.2}, 0.2)
        if onClick then pcall(onClick) end
    end)
    b.MouseEnter:Connect(function() Tw(b,{BackgroundTransparency=0.05},0.15) end)
    b.MouseLeave:Connect(function() Tw(b,{BackgroundTransparency=0.2},0.15) end)
    return b
end

local function Btn2(parent, text, onClick, col)
    col = col or C.Accent
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,0,0,0) -- sized by UIGridLayout
    b.BackgroundColor3 = col
    b.BackgroundTransparency = 0.2
    b.Text = text
    b.TextColor3 = C.White
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.ZIndex = 12
    b.TextWrapped = true
    b.Parent = parent
    Crn(b, 12)
    b.MouseButton1Click:Connect(function()
        Tw(b,{BackgroundTransparency=0},0.1)
        task.wait(0.12)
        Tw(b,{BackgroundTransparency=0.2},0.2)
        if onClick then pcall(onClick) end
    end)
    return b
end

local function Slider(parent, text, minv, maxv, defv, onCh, col)
    col = col or C.Accent
    local val = defv
    local f = Fr(parent, UDim2.new(1,0,0,72), nil, C.Card, 0)
    f.ZIndex = 12
    Crn(f, 14)
    Strk(f, C.Border, 1)

    local vlbl = Instance.new("TextLabel")
    vlbl.Size = UDim2.new(1,-14,0,22)
    vlbl.Position = UDim2.new(0,14,0,6)
    vlbl.BackgroundTransparency = 1
    vlbl.Text = text..": "..math.floor(val)
    vlbl.TextSize = 13
    vlbl.Font = Enum.Font.GothamBold
    vlbl.TextColor3 = C.Text
    vlbl.TextXAlignment = Enum.TextXAlignment.Left
    vlbl.ZIndex = 13
    vlbl.Parent = f

    local track = Fr(f, UDim2.new(1,-28,0,6), UDim2.new(0,14,0,44), C.OffBtn, 0)
    Crn(track, UDim.new(1,0))
    track.ZIndex = 13

    local fill = Fr(track, UDim2.new((defv-minv)/(maxv-minv),0,1,0), nil, col, 0)
    Crn(fill, UDim.new(1,0))
    fill.ZIndex = 14

    local knob = Fr(track, UDim2.new(0,18,0,18), UDim2.new((defv-minv)/(maxv-minv),0,0.5,-9), col, 0)
    Crn(knob, UDim.new(1,0))
    knob.ZIndex = 15
    Strk(knob, C.White, 2)

    local sliding = false
    local function upd(pos)
        local ab = track.AbsolutePosition
        local sz = track.AbsoluteSize
        local r  = math.clamp((pos.X - ab.X)/sz.X, 0, 1)
        val = minv + (maxv-minv)*r
        fill.Size = UDim2.new(r,0,1,0)
        knob.Position = UDim2.new(r,-9,0.5,-9)
        vlbl.Text = text..": "..math.floor(val)
        if onCh then onCh(val) end
    end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sliding=true; upd(inp.Position)
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            sliding=false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            upd(inp.Position)
        end
    end)
    return f
end

local function Input(parent, ph, onSub, col)
    col = col or C.Accent
    local f = Fr(parent, UDim2.new(1,0,0,58), nil, C.Card, 0)
    f.ZIndex = 12
    Crn(f, 14)
    Strk(f, C.Border, 1)

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1,-72,0,40)
    tb.Position = UDim2.new(0,10,0.5,-20)
    tb.BackgroundColor3 = C.BG
    tb.BackgroundTransparency = 0.3
    tb.Text = ""
    tb.PlaceholderText = ph or "Enter..."
    tb.PlaceholderColor3 = C.TextDim
    tb.TextColor3 = C.Text
    tb.TextSize = 13
    tb.Font = Enum.Font.Gotham
    tb.BorderSizePixel = 0
    tb.ClearTextOnFocus = false
    tb.ZIndex = 13
    tb.Parent = f
    Crn(tb, 10)
    Pad(tb, 0,0,8,8)

    local go = Instance.new("TextButton")
    go.Size = UDim2.new(0,54,0,40)
    go.Position = UDim2.new(1,-64,0.5,-20)
    go.BackgroundColor3 = col
    go.BackgroundTransparency = 0.2
    go.Text = "OK"
    go.TextColor3 = C.White
    go.TextSize = 13
    go.Font = Enum.Font.GothamBold
    go.BorderSizePixel = 0
    go.ZIndex = 13
    go.Parent = f
    Crn(go, 10)

    go.MouseButton1Click:Connect(function() if onSub then onSub(tb.Text) end end)
    tb.FocusLost:Connect(function(enter) if enter and onSub then onSub(tb.Text) end end)

    return f, tb
end

local function TargetPicker(parent, label, onChange)
    local f = Fr(parent, UDim2.new(1,0,0,58), nil, C.Card, 0)
    f.ZIndex = 12
    Crn(f, 14)
    Strk(f, C.Border, 1)

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1,-80,1,0)
    lbl2.Position = UDim2.new(0,14,0,0)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = label or "Target: Everyone"
    lbl2.TextSize = 13
    lbl2.Font = Enum.Font.GothamSemibold
    lbl2.TextColor3 = C.Text
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    lbl2.TextWrapped = true
    lbl2.ZIndex = 13
    lbl2.Parent = f

    local idx = 0
    local function getList()
        local list = {"Everyone"}
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(list, p.Name) end
        end
        return list
    end

    local nxt = Instance.new("TextButton")
    nxt.Size = UDim2.new(0,62,0,38)
    nxt.Position = UDim2.new(1,-70,0.5,-19)
    nxt.BackgroundColor3 = C.Accent
    nxt.BackgroundTransparency = 0.3
    nxt.Text = "Next >"
    nxt.TextColor3 = C.White
    nxt.TextSize = 12
    nxt.Font = Enum.Font.GothamBold
    nxt.BorderSizePixel = 0
    nxt.ZIndex = 13
    nxt.Parent = f
    Crn(nxt, 10)

    nxt.MouseButton1Click:Connect(function()
        local list = getList()
        idx = (idx % #list)+1
        local name = list[idx]
        lbl2.Text = (label or "Target")..(": "..name)
        local target = name=="Everyone" and nil or Players:FindFirstChild(name)
        ST.TrollTarget = target
        if onChange then onChange(target) end
    end)

    return f
end

-- ============================================================
--  IY TROLL LOGIC (FULL)
-- ============================================================

-- Fling
local function Fling(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myRoot = GetRoot()
    if not myRoot then return end
    local dir = (root.Position - myRoot.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = dir * 300 + Vector3.new(math.random(-200,200),math.random(200,500),math.random(-200,200))
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = root
    Debris:AddItem(bv, 0.25)
end

-- Super Fling (IY style - multiple velocity bursts)
local function SuperFling(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    task.spawn(function()
        for i=1,8 do
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(
                math.random(-1,1)*math.random(5000,9999),
                math.random(2000,9999),
                math.random(-1,1)*math.random(5000,9999)
            )
            bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
            bv.Parent = root
            Debris:AddItem(bv, 0.08)
            task.wait(0.08)
        end
    end)
end

-- Orbital Fling (spin then release)
local function OrbitalFling(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myRoot = GetRoot()
    if not myRoot then return end
    task.spawn(function()
        local angle = 0
        local dist = 8
        for i=1,30 do
            angle = angle + 0.3
            dist  = dist + 0.2
            root.CFrame = myRoot.CFrame * CFrame.new(
                math.cos(angle)*dist, 2, math.sin(angle)*dist
            )
            task.wait(0.04)
        end
        -- Release with tangent velocity
        local bv = Instance.new("BodyVelocity")
        local tangent = Vector3.new(-math.sin(angle), 1, math.cos(angle))
        bv.Velocity = tangent * 500 + Vector3.new(0,300,0)
        bv.MaxForce = Vector3.new(1e9,1e9,1e9)
        bv.Parent = root
        Debris:AddItem(bv, 0.3)
    end)
end

-- Launch (straight up)
local function Launch(p, power)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, power or 1200, 0)
    bv.MaxForce = Vector3.new(0, 1e9, 0)
    bv.Parent = root
    Debris:AddItem(bv, 0.4)
end

-- Knockback (IY: push away from you)
local function Knockback(p, power)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myRoot = GetRoot()
    if not myRoot then return end
    local dir = (root.Position - myRoot.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = dir * (power or 200) + Vector3.new(0, 80, 0)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = root
    Debris:AddItem(bv, 0.35)
end

-- Pull (IY: pull toward you)
local function Pull(p, power)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local myRoot = GetRoot()
    if not myRoot then return end
    local dir = (myRoot.Position - root.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = dir * (power or 200)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = root
    Debris:AddItem(bv, 0.4)
end

-- Spin (IY style)
local SpinConn
local function StartSpin(target, speed)
    if SpinConn then SpinConn:Disconnect() end
    local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root then root = GetRoot() end
    if not root then return end
    local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    local angle = 0
    SpinConn = RunService.Heartbeat:Connect(function(dt)
        if not ST.Spinning then
            SpinConn:Disconnect()
            if hum then hum.PlatformStand = false end
            return
        end
        angle = angle + dt * math.rad(360) * (speed or ST.SpinSpeed)
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, angle, 0)
    end)
end

-- Headsit (IY style)
local HeadsitConn
local function StartHeadsit(target)
    if HeadsitConn then HeadsitConn:Disconnect() end
    if not target or not target.Character then return end
    HeadsitConn = RunService.Heartbeat:Connect(function()
        if not ST.Headsitting then HeadsitConn:Disconnect() return end
        local tHead = target.Character and target.Character:FindFirstChild("Head")
        local myRoot = GetRoot()
        if myRoot and tHead then
            myRoot.CFrame = tHead.CFrame * CFrame.new(0,4,0)
        end
    end)
end

-- Attach / Carry
local AttachConn
local function StartAttach(target)
    if AttachConn then AttachConn:Disconnect() end
    if not target or not target.Character then return end
    AttachConn = RunService.Heartbeat:Connect(function()
        if not ST.Attaching then AttachConn:Disconnect() return end
        local myRoot = GetRoot()
        local tRoot  = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, -4)
        end
    end)
end

-- Float (hold player up)
local FloatConn
local function StartFloat(target)
    if FloatConn then FloatConn:Disconnect() end
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    FloatConn = RunService.Heartbeat:Connect(function()
        if not ST.Floating then FloatConn:Disconnect() return end
        root.Velocity = Vector3.new(root.Velocity.X, 25, root.Velocity.Z)
    end)
end

-- Freeze / Thaw (IY anchor all parts)
local function Freeze(p, state)
    if not p or not p.Character then return end
    for _, v in pairs(p.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = state
        end
    end
end

-- Blind (IY: giant neon part on head)
local function Blind(p, dur)
    if not p or not p.Character then return end
    local head = p.Character:FindFirstChild("Head")
    if not head then return end
    local part = Instance.new("Part")
    part.Size = Vector3.new(8,8,8)
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new("Institutional white")
    part.CanCollide = false
    part.CFrame = head.CFrame
    part.Parent = workspace
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = part
    weld.Parent = part
    Debris:AddItem(part, dur or 8)
    Notify("Troll", "Blinded "..p.Name.." for "..(dur or 8).."s", 3)
end

-- Size (IY: scale humanoid)
local function SetSize(p, scale)
    local char = p and p.Character or GetChar()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.BodyDepthScale.Value  = scale
        hum.BodyHeightScale.Value = scale
        hum.BodyWidthScale.Value  = scale
        hum.HeadScale.Value       = scale
    end
end

-- Invisible (IY: lure them with invisibility trick)
-- Actually make LOCAL player invisible
local function SetLocalInvisible(on)
    local char = GetChar()
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") then
            v.LocalTransparencyModifier = on and 1 or 0
        end
        if v:IsA("Decal") then
            v.Transparency = on and 1 or 0
        end
    end
end

-- Bring (IY: teleport target to you)
local function Bring(p)
    if not p or not p.Character then return end
    local myRoot = GetRoot()
    local tRoot  = p.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and tRoot then
        tRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, 4)
    end
end

-- TP to target
local function TPToPlayer(p)
    if not p or not p.Character then return end
    local myRoot = GetRoot()
    local tRoot  = p.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and tRoot then
        myRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
    end
end

-- Grab (IY: weld target to you)
local GrabWeld
local function Grab(p)
    if GrabWeld then GrabWeld:Destroy() GrabWeld=nil end
    if not p or not p.Character then return end
    local myRoot = GetRoot()
    local tRoot  = p.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end
    tRoot.CFrame = myRoot.CFrame * CFrame.new(0,0,-3)
    local w = Instance.new("WeldConstraint")
    w.Part0 = myRoot
    w.Part1 = tRoot
    w.Parent = myRoot
    GrabWeld = w
    Notify("Troll","Grabbed "..p.Name, 2)
end
local function UnGrab()
    if GrabWeld then GrabWeld:Destroy() GrabWeld=nil end
    Notify("Troll","Released", 2)
end

-- Explode (IY: explosion on player)
local function Explode(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local exp = Instance.new("Explosion")
    exp.Position = root.Position
    exp.BlastRadius = 8
    exp.BlastPressure = 500000
    exp.ExplosionType = Enum.ExplosionType.NoCraters
    exp.Parent = workspace
end

-- Fire (set fire on player)
local function SetFire(p, on)
    if not p or not p.Character then return end
    for _, v in pairs(p.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            if on then
                local existing = v:FindFirstChildOfClass("Fire")
                if not existing then
                    local fire = Instance.new("Fire")
                    fire.Heat = 20
                    fire.Size = 5
                    fire.Parent = v
                end
            else
                local fire = v:FindFirstChildOfClass("Fire")
                if fire then fire:Destroy() end
            end
        end
    end
end

-- Sparkles
local function SetSparkles(p, on)
    if not p or not p.Character then return end
    for _, v in pairs(p.Character:GetDescendants()) do
        if v:IsA("BasePart") then
            if on then
                if not v:FindFirstChildOfClass("Sparkles") then
                    Instance.new("Sparkles").Parent = v
                end
            else
                local sp = v:FindFirstChildOfClass("Sparkles")
                if sp then sp:Destroy() end
            end
        end
    end
end

-- Smoke
local function SetSmoke(p, on)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if on then
        local sm = Instance.new("Smoke")
        sm.RiseVelocity = 10
        sm.Density = 0.8
        sm.Parent = root
    else
        local sm = root:FindFirstChildOfClass("Smoke")
        if sm then sm:Destroy() end
    end
end

-- Sit (IY: force character to sit)
local function ForceSit(p)
    if not p or not p.Character then return end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:Sit() end
end

-- Jump (force jump)
local function ForceJump(p)
    if not p or not p.Character then return end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end

-- Loopjump (IY: repeatedly force jumping)
local LoopJumpConn
local function StartLoopJump(p)
    if LoopJumpConn then LoopJumpConn:Disconnect() end
    LoopJumpConn = RunService.Heartbeat:Connect(function()
        ForceJump(p)
    end)
    task.delay(5, function()
        if LoopJumpConn then LoopJumpConn:Disconnect() end
    end)
end

-- Seatbomb (IY: create seat under player and force sit)
local function SeatBomb(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local seat = Instance.new("Seat")
    seat.Size = Vector3.new(4,1,4)
    seat.CFrame = root.CFrame * CFrame.new(0,-3,0)
    seat.Parent = workspace
    Debris:AddItem(seat, 6)
end

-- Swap (IY: swap positions with target)
local function Swap(p)
    if not p or not p.Character then return end
    local myRoot = GetRoot()
    local tRoot  = p.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end
    local myCF = myRoot.CFrame
    local tCF  = tRoot.CFrame
    myRoot.CFrame = tCF
    tRoot.CFrame  = myCF
    Notify("Troll","Swapped with "..p.Name, 2)
end

-- Follow (constantly TP to target)
local FollowConn
local function StartFollow(p)
    if FollowConn then FollowConn:Disconnect() end
    if not p then return end
    FollowConn = RunService.Heartbeat:Connect(function()
        TPToPlayer(p)
    end)
end
local function StopFollow()
    if FollowConn then FollowConn:Disconnect() FollowConn=nil end
end

-- Kill (IY: reduce health to 0)
local function Kill(p)
    if not p or not p.Character then return end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end

-- Roof (IY: TP player to highest point)
local function SendToRoof(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.CFrame = CFrame.new(root.Position.X, 9999, root.Position.Z)
end

-- Sinkhole (IY: TP player to very low Y)
local function Sinkhole(p)
    if not p or not p.Character then return end
    local root = p.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    root.CFrame = CFrame.new(root.Position.X, -9999, root.Position.Z)
end

-- Loopfling
local LoopFlingConn
local function StartLoopFling(p, power)
    if LoopFlingConn then LoopFlingConn:Disconnect() end
    LoopFlingConn = RunService.Heartbeat:Connect(function()
        if not p or not p.Character then return end
        local root = p.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(math.random(-1,1)*(power or 500), math.random(200,800), math.random(-1,1)*(power or 500))
            bv.MaxForce = Vector3.new(1e9,1e9,1e9)
            bv.Parent = root
            Debris:AddItem(bv, 0.08)
        end
    end)
end
local function StopLoopFling()
    if LoopFlingConn then LoopFlingConn:Disconnect() LoopFlingConn=nil end
end

-- Loopkill
local LoopKillConn
local function StartLoopKill(p)
    if LoopKillConn then LoopKillConn:Disconnect() end
    LoopKillConn = RunService.Heartbeat:Connect(function()
        Kill(p)
    end)
end
local function StopLoopKill()
    if LoopKillConn then LoopKillConn:Disconnect() LoopKillConn=nil end
end

-- Bunny (IY: force player to bounce)
local BunnyConn
local function StartBunny(p)
    if BunnyConn then BunnyConn:Disconnect() end
    BunnyConn = RunService.Heartbeat:Connect(function()
        if not p or not p.Character then return end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    task.delay(8, function() if BunnyConn then BunnyConn:Disconnect() end end)
end

-- Dance (IY: 10 dances)
local DanceTracks = {}
local DanceIDs = {
    "507770239","507771019","507771955","507772104",
    "507772398","507773317","507776043","507776468",
    "507777268","507777451","1073893568","1073893569",
}
local function Dance(idx)
    local hum = GetHum()
    if not hum then return end
    for _, t in ipairs(DanceTracks) do pcall(function() t:Stop() end) end
    DanceTracks = {}
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. (DanceIDs[idx] or DanceIDs[1])
    local track = hum.Animator:LoadAnimation(anim)
    track:Play()
    table.insert(DanceTracks, track)
    Notify("Dance","Dance "..idx.." started", 2)
end

-- Emotes (IY: various built-in emotes)
local EmoteIDs = {
    Wave="507770239", Point="507770453", Cheer="507770677",
    Laugh="507770818", Dance1="507771019", Dance2="507771955",
    Dance3="507772104", Salute="3360692915", Shrug="3984580446",
}
local function Emote(name)
    local hum = GetHum()
    if not hum then return end
    local id = EmoteIDs[name]
    if not id then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local track = hum.Animator:LoadAnimation(anim)
    track:Play()
end

-- Spin Dance (spin + dance combined)
local SpinDanceConn
local function StartSpinDance()
    local hum = GetHum()
    if not hum then return end
    local root = GetRoot()
    if not root then return end
    -- Start dance
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://507771955"
    local track = hum.Animator:LoadAnimation(anim)
    track:Play()
    -- Start spin
    local angle = 0
    SpinDanceConn = RunService.Heartbeat:Connect(function(dt)
        angle = angle + dt * math.rad(720)
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0,angle,0)
    end)
end
local function StopSpinDance()
    if SpinDanceConn then SpinDanceConn:Disconnect() SpinDanceConn=nil end
    for _, t in ipairs(DanceTracks) do pcall(function() t:Stop() end) end
end

-- Ragdoll (IY: disconnect motor6ds)
local SavedMotors = {}
local function Ragdoll(p, on)
    local char = p and p.Character or GetChar()
    if not char then return end
    if on then
        SavedMotors = {}
        for _, m in pairs(char:GetDescendants()) do
            if m:IsA("Motor6D") then
                SavedMotors[#SavedMotors+1] = {
                    motor = m,
                    parent = m.Parent,
                    p0 = m.Part0,
                    p1 = m.Part1,
                }
                local att0 = Instance.new("Attachment") att0.CFrame = m.C0 att0.Parent = m.Part0
                local att1 = Instance.new("Attachment") att1.CFrame = m.C1 att1.Parent = m.Part1
                local bs = Instance.new("BallSocketConstraint")
                bs.Attachment0 = att0 bs.Attachment1 = att1 bs.Parent = m.Parent
                m.Parent = nil -- detach
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
    else
        for _, data in ipairs(SavedMotors) do
            data.motor.Parent = data.parent
        end
        SavedMotors = {}
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- FakeMessage (IY: send chat as if it's from target)
-- Note: this only shows locally
local function FakeMessage(fromName, msg)
    local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvent then
        local sayEvent = chatEvent:FindFirstChild("OnMessageDoneFiltering")
        -- Just display via StarterGui system chat (client side)
    end
    -- Create fake chat bubble
    Notify(fromName, msg, 5)
end

-- Force chat (IY: make yourself say something)
local function SayMessage(msg)
    local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvent then
        local sayEvent = chatEvent:FindFirstChild("SayMessageRequest")
        if sayEvent then
            sayEvent:FireServer(msg, "All")
        end
    end
end

-- Loop chat
local LoopChatConn
local LoopChatMsg = ""
local function StartLoopChat(msg, interval)
    LoopChatMsg = msg
    if LoopChatConn then LoopChatConn:Disconnect() end
    LoopChatConn = task.spawn(function()
        while LoopChatMsg ~= "" do
            SayMessage(LoopChatMsg)
            task.wait(interval or 2)
        end
    end)
end
local function StopLoopChat()
    LoopChatMsg = ""
    if LoopChatConn then task.cancel(LoopChatConn) LoopChatConn=nil end
end

-- Nametag (change character display name - local)
local function SetNametag(name)
    local char = GetChar()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayName = name end
end

-- Faceswap (give your face to target or vice versa) - local effect
local function Faceswap(p)
    if not p or not p.Character then return end
    local myChar = GetChar()
    if not myChar then return end
    local myHead = myChar:FindFirstChild("Head")
    local tHead  = p.Character:FindFirstChild("Head")
    if not myHead or not tHead then return end
    local myFace = myHead:FindFirstChild("face") or myHead:FindFirstChildOfClass("Decal")
    local tFace  = tHead:FindFirstChild("face") or tHead:FindFirstChildOfClass("Decal")
    if myFace and tFace then
        local tmp = myFace.Texture
        myFace.Texture = tFace.Texture
        tFace.Texture = tmp
        Notify("Troll","Face swapped with "..p.Name, 3)
    end
end

-- BaconHair (give bacon hair via accessory parenting - local)
-- (this would only show locally without R6/R15 accessory replication)
local function BaconHair(p)
    local char = p and p.Character or GetChar()
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local acc = Instance.new("Accessory")
    local handle = Instance.new("Part")
    handle.Size = Vector3.new(2,2,2)
    handle.Transparency = 0
    handle.CFrame = head.CFrame * CFrame.new(0,1.5,0)
    handle.Parent = acc
    acc.Parent = char
    Debris:AddItem(acc, 10)
    Notify("Troll","BaconHair applied to "..(p and p.Name or "you"), 3)
end

-- Particles spam (big visual effect)
local function ParticleSpam(p, dur)
    local char = p and p.Character or GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    task.spawn(function()
        local parts = {"Fire","Smoke","Sparkles"}
        local instances = {}
        for _, pname in ipairs(parts) do
            local inst = Instance.new(pname)
            inst.Parent = root
            instances[#instances+1] = inst
        end
        task.wait(dur or 5)
        for _, inst in ipairs(instances) do SafeDestroy(inst) end
    end)
end

-- God Particle (permanent glow)
local function GodParticle(on)
    local char = GetChar()
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if on then
        local sp = Instance.new("Sparkles") sp.Parent = root
        local fire = Instance.new("Fire") fire.Heat=-5 fire.Size=2 fire.Color=C.Accent fire.SecondaryColor=C.Pink fire.Parent=root
    else
        for _, v in pairs(root:GetChildren()) do
            if v:IsA("Sparkles") or v:IsA("Fire") then v:Destroy() end
        end
    end
end

-- ============================================================
--  MOVEMENT LOGIC
-- ============================================================
local FlyConns = {}
local function StartFly()
    local char = GetChar(); if not char then return end
    local root = GetRoot(); if not root then return end
    local hum  = GetHum();  if not hum then return end
    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity")
    bv.Velocity=Vector3.zero bv.MaxForce=Vector3.new(1e9,1e9,1e9) bv.Parent=root
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque=Vector3.new(1e9,1e9,1e9) bg.CFrame=root.CFrame bg.P=1e5 bg.Parent=root
    FlyConns.hb = RunService.Heartbeat:Connect(function()
        if not ST.Flying then
            pcall(function() bv:Destroy() end)
            pcall(function() bg:Destroy() end)
            if hum then pcall(function() hum.PlatformStand=false end) end
            FlyConns.hb:Disconnect()
            return
        end
        local cf = Camera.CFrame
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel=vel+cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel=vel-cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel=vel-cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel=vel+cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then vel=vel+Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel=vel-Vector3.new(0,1,0) end
        bv.Velocity = vel * ST.FlySpd
        if vel.Magnitude>0.1 then bg.CFrame=CFrame.lookAt(root.Position,root.Position+vel) end
    end)
end
local function StopFly()
    if FlyConns.hb then FlyConns.hb:Disconnect() end
    local root = GetRoot()
    if root then
        local bv = root:FindFirstChildOfClass("BodyVelocity")
        local bg = root:FindFirstChildOfClass("BodyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then pcall(function() hum.PlatformStand=false end) end
end

local NoclipConn
local function StartNoclip()
    if NoclipConn then NoclipConn:Disconnect() end
    NoclipConn = RunService.Stepped:Connect(function()
        if not ST.Noclip then NoclipConn:Disconnect() return end
        local char = GetChar()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide=false end
            end
        end
    end)
end

local InfJumpConn
local function SetInfJump(on)
    if InfJumpConn then InfJumpConn:Disconnect() InfJumpConn=nil end
    if on then
        InfJumpConn = UserInputService.JumpRequest:Connect(function()
            local hum = GetHum()
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end

local ClickTPConn
local function SetClickTP(on)
    if ClickTPConn then ClickTPConn:Disconnect() ClickTPConn=nil end
    if on then
        ClickTPConn = Mouse.Button1Down:Connect(function()
            if not ST.ClickTP then ClickTPConn:Disconnect() return end
            local root = GetRoot()
            if root and Mouse.Hit then
                root.CFrame = Mouse.Hit + Vector3.new(0,3,0)
            end
        end)
    end
end

-- ============================================================
--  PROTECTION LOGIC
-- ============================================================
local GodConn
local function SetGodMode(on)
    if GodConn then GodConn:Disconnect() GodConn=nil end
    if on then
        GodConn = RunService.Heartbeat:Connect(function()
            local hum = GetHum()
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
    end
end

local function SetFullbright(on)
    if on then
        ST.OrigBright = Lighting.Brightness
        ST.OrigAmb    = Lighting.Ambient
        ST.OrigOutAmb = Lighting.OutdoorAmbient
        Lighting.Brightness = 8
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    else
        Lighting.Brightness = ST.OrigBright
        Lighting.Ambient = ST.OrigAmb
        Lighting.OutdoorAmbient = ST.OrigOutAmb
    end
end

local AntiAFKConn
local function SetAntiAFK(on)
    if AntiAFKConn then AntiAFKConn:Disconnect() AntiAFKConn=nil end
    if on then
        AntiAFKConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
end

-- ============================================================
--  ESP LOGIC
-- ============================================================
local ESPBoxes = {}
local function UpdateESP(on)
    for _, b in pairs(ESPBoxes) do pcall(function() b:Destroy() end) end
    ESPBoxes = {}
    if not on then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = Instance.new("SelectionBox")
            h.Color3 = C.Red
            h.LineThickness = 0.05
            h.SurfaceTransparency = 0.75
            h.SurfaceColor3 = Color3.fromRGB(255,0,0)
            h.Adornee = p.Character
            h.Parent = workspace
            ESPBoxes[p.Name] = h
        end
    end
end

-- Chams (highlight through walls)
local ChamConns = {}
local function SetChams(on)
    for _, c in pairs(ChamConns) do pcall(function() c:Disconnect() end) end
    ChamConns = {}
    if not on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CastShadow=true end
                end
            end
        end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, v in pairs(p.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CastShadow=false end
            end
        end
    end
end

-- ============================================================
--  MUSIC LOGIC
-- ============================================================
local MusicSound = Instance.new("Sound")
MusicSound.Name = "KaelenHubMusic"
MusicSound.RollOffMaxDistance = 999999
MusicSound.RollOffMinDistance = 999999
MusicSound.RollOffMode = Enum.RollOffMode.InverseTapered
MusicSound.Volume = ST.MusicVol
MusicSound.Parent = workspace

local NPLabel -- declared later, used in music functions
local function PlaySong(id, name)
    MusicSound.SoundId = "rbxassetid://" .. tostring(id)
    MusicSound:Stop()
    MusicSound:Play()
    ST.MusicOn = true
    ST.SongID  = tostring(id)
    if NPLabel then NPLabel.Text = "Now Playing: "..(name or id) end
    Notify("Kaelen Music","Now Playing: "..(name or id), 3)
end
local function StopMusic()
    MusicSound:Stop()
    ST.MusicOn = false
    if NPLabel then NPLabel.Text = "Stopped" end
end

MusicSound.Ended:Connect(function()
    if ST.MusicLoop and ST.SongID then
        MusicSound:Play()
    elseif ST.MusicOn then
        ST.SongIdx = (ST.SongIdx % #SONGS) + 1
        PlaySong(SONGS[ST.SongIdx].id, SONGS[ST.SongIdx].n)
    end
end)

-- ============================================================
--  BUILD TROLL PANEL
-- ============================================================
local TrollPanel = MakeScrollPanel("Troll")

do
    Section(TrollPanel, "Target Selector", C.Red)
    TargetPicker(TrollPanel, "Target", function(p) ST.TrollTarget = p end)

    Section(TrollPanel, "Fling Arsenal", C.Red)
    local flingGrid = Fr(TrollPanel, UDim2.new(1,0,0,200), nil, C.BG, 1)
    GL(flingGrid, UDim2.new(0.48,-4,0,56), UDim2.new(0,6,0,6))
    flingGrid.ZIndex = 12

    Btn2(flingGrid, "Fling", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Fling(p) end end
        Notify("Troll","Flung!", 2)
    end, C.Red)

    Btn2(flingGrid, "SUPER Fling", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SuperFling(p) end end
        Notify("Troll","SUPER FLUNG!", 2)
    end, Color3.fromRGB(255,30,30))

    Btn2(flingGrid, "Orbital Fling", function()
        if ST.TrollTarget then OrbitalFling(ST.TrollTarget) end
    end, Color3.fromRGB(200,50,50))

    Btn2(flingGrid, "Launch UP", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Launch(p, 1200) end end
    end, C.Orange)

    Btn2(flingGrid, "Knockback", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Knockback(p, 300) end end
    end, C.Orange)

    Btn2(flingGrid, "Pull To Me", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Pull(p, 300) end end
    end, C.Orange)

    Btn2(flingGrid, "Explode", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Explode(p) end end
    end, C.Red)

    Btn2(flingGrid, "Loop Fling", function()
        if ST.TrollTarget then
            StartLoopFling(ST.TrollTarget, 600)
            task.delay(6, StopLoopFling)
            Notify("Troll","Loop Fling 6s", 2)
        end
    end, Color3.fromRGB(180,20,20))

    -- flingGrid has 8 buttons = 4 rows
    flingGrid.Size = UDim2.new(1,0,0,260)

    Section(TrollPanel, "Control & Position", C.Pink)
    local ctrlGrid = Fr(TrollPanel, UDim2.new(1,0,0,260), nil, C.BG, 1)
    GL(ctrlGrid, UDim2.new(0.48,-4,0,56), UDim2.new(0,6,0,6))
    ctrlGrid.ZIndex = 12

    Btn2(ctrlGrid, "TP To Target", function()
        if ST.TrollTarget then TPToPlayer(ST.TrollTarget) end
    end, C.Accent)

    Btn2(ctrlGrid, "Bring Target", function()
        if ST.TrollTarget then Bring(ST.TrollTarget) end
    end, C.Accent)

    Btn2(ctrlGrid, "Swap Positions", function()
        if ST.TrollTarget then Swap(ST.TrollTarget) end
    end, C.Accent)

    Btn2(ctrlGrid, "Grab", function()
        if ST.TrollTarget then Grab(ST.TrollTarget) end
    end, C.Accent2)

    Btn2(ctrlGrid, "UnGrab", function() UnGrab() end, C.Accent2)

    Btn2(ctrlGrid, "Send To Roof", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SendToRoof(p) end end
    end, C.Pink)

    Btn2(ctrlGrid, "Sinkhole", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Sinkhole(p) end end
    end, C.Pink)

    Btn2(ctrlGrid, "Force Sit", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then ForceSit(p) end end
    end, C.Pink)

    Btn2(ctrlGrid, "Seat Bomb", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SeatBomb(p) end end
    end, C.Pink)

    Btn2(ctrlGrid, "Force Jump", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then ForceJump(p) end end
    end, C.Green)

    Btn2(ctrlGrid, "Bunny (8s)", function()
        if ST.TrollTarget then StartBunny(ST.TrollTarget) end
    end, C.Green)

    Section(TrollPanel, "Toggle Effects", C.Pink)

    Toggle(TrollPanel, "Spin (Target / Self)", false, function(on)
        ST.Spinning = on
        if on then StartSpin(ST.TrollTarget) end
    end, C.Pink)

    Slider(TrollPanel, "Spin Speed", 1, 30, 10, function(v) ST.SpinSpeed=v end, C.Pink)

    Toggle(TrollPanel, "Headsit (requires target)", false, function(on)
        ST.Headsitting = on
        if on and ST.TrollTarget then StartHeadsit(ST.TrollTarget) end
    end, C.Pink)

    Toggle(TrollPanel, "Attach / Carry Target", false, function(on)
        ST.Attaching = on
        if on and ST.TrollTarget then StartAttach(ST.TrollTarget) end
    end, C.Pink)

    Toggle(TrollPanel, "Float Player", false, function(on)
        ST.Floating = on
        if on and ST.TrollTarget then StartFloat(ST.TrollTarget) end
    end, C.Pink)

    Toggle(TrollPanel, "Follow Target", false, function(on)
        if on and ST.TrollTarget then StartFollow(ST.TrollTarget)
        else StopFollow() end
    end, C.Accent2)

    Toggle(TrollPanel, "Loop Kill Target", false, function(on)
        if on and ST.TrollTarget then StartLoopKill(ST.TrollTarget)
        else StopLoopKill() end
    end, C.Red)

    Section(TrollPanel, "Size Control", C.Orange)
    Slider(TrollPanel, "Target Size", 0.05, 15, 1, function(v)
        if ST.TrollTarget then SetSize(ST.TrollTarget, v)
        else SetSize(nil, v) end
    end, C.Orange)

    local sizeGrid = Fr(TrollPanel, UDim2.new(1,0,0,130), nil, C.BG, 1)
    GL(sizeGrid, UDim2.new(0.48,-4,0,56), UDim2.new(0,6,0,6))
    sizeGrid.ZIndex = 12

    Btn2(sizeGrid, "Tiny (0.05x)", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetSize(p,0.05) end end
    end, C.Orange)
    Btn2(sizeGrid, "Small (0.5x)", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetSize(p,0.5) end end
    end, C.Orange)
    Btn2(sizeGrid, "GIANT (10x)", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetSize(p,10) end end
    end, C.Orange)
    Btn2(sizeGrid, "MEGA (25x)", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetSize(p,25) end end
    end, Color3.fromRGB(255,80,0))
    Btn2(sizeGrid, "Reset Size", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetSize(p,1) end
    end, C.Green)
    Btn2(sizeGrid, "My Size: Big", function() SetSize(nil,5) end, C.Teal)

    Section(TrollPanel, "Freeze & Effects", C.Accent2)
    local fxGrid = Fr(TrollPanel, UDim2.new(1,0,0,200), nil, C.BG, 1)
    GL(fxGrid, UDim2.new(0.48,-4,0,56), UDim2.new(0,6,0,6))
    fxGrid.ZIndex = 12

    Btn2(fxGrid, "Freeze Target", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Freeze(p,true) end end
        Notify("Troll","Frozen!", 2)
    end, C.Accent2)
    Btn2(fxGrid, "Thaw Target", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do Freeze(p,false) end
        Notify("Troll","Thawed!", 2)
    end, C.Accent2)
    Btn2(fxGrid, "Blind (8s)", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Blind(p,8) end end
    end, C.Yellow)
    Btn2(fxGrid, "Blind (30s)", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Blind(p,30) end end
    end, Color3.fromRGB(200,180,0))
    Btn2(fxGrid, "Set Fire", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetFire(p,true) end end
    end, Color3.fromRGB(255,120,20))
    Btn2(fxGrid, "Extinguish", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetFire(p,false) end
    end, C.Teal)
    Btn2(fxGrid, "Sparkles ON", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetSparkles(p,true) end
    end, Color3.fromRGB(220,200,255))
    Btn2(fxGrid, "Sparkles OFF", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetSparkles(p,false) end
    end, C.TextDim)
    Btn2(fxGrid, "Smoke ON", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetSmoke(p,true) end
    end, C.TextDim)
    Btn2(fxGrid, "Smoke OFF", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetSmoke(p,false) end
    end, C.TextDim)
    Btn2(fxGrid, "Particle Spam", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do ParticleSpam(p,6) end
    end, C.Pink)
    Btn2(fxGrid, "Kill Target", function()
        local targets = ST.TrollTarget and {ST.TrollTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then Kill(p) end end
    end, C.Red)

    Section(TrollPanel, "Ragdoll", C.Accent)
    Toggle(TrollPanel, "Ragdoll Myself", false, function(on)
        Ragdoll(nil, on)
    end, C.Accent)

    Section(TrollPanel, "Dance & Emotes", C.Green)
    local danceGrid = Fr(TrollPanel, UDim2.new(1,0,0,200), nil, C.BG, 1)
    GL(danceGrid, UDim2.new(0.31,-4,0,52), UDim2.new(0,4,0,4))
    danceGrid.ZIndex = 12

    for i=1,12 do
        Btn2(danceGrid, "Dance "..i, function() Dance(i) end, C.Green)
    end

    local emoteGrid = Fr(TrollPanel, UDim2.new(1,0,0,130), nil, C.BG, 1)
    GL(emoteGrid, UDim2.new(0.31,-4,0,52), UDim2.new(0,4,0,4))
    emoteGrid.ZIndex = 12
    for name, _ in pairs(EmoteIDs) do
        Btn2(emoteGrid, name, function() Emote(name) end, Color3.fromRGB(60,180,80))
    end

    Btn(TrollPanel, "Spin Dance (Toggle)", function()
        if SpinDanceConn then StopSpinDance() else StartSpinDance() end
    end, C.Green)

    Btn(TrollPanel, "Stop All Animations", function()
        local hum = GetHum()
        if hum then
            for _, t in pairs(hum.Animator:GetPlayingAnimationTracks()) do t:Stop() end
        end
    end, C.TextDim)

    Section(TrollPanel, "Chat Tricks", C.Yellow)
    local _, chatTB = Input(TrollPanel, "Message to say...", nil, C.Yellow)
    Btn(TrollPanel, "Say Message", function()
        if chatTB and chatTB.Text ~= "" then SayMessage(chatTB.Text) end
    end, C.Yellow)

    local _, loopChatTB = Input(TrollPanel, "Loop chat message...", nil, C.Yellow)
    Toggle(TrollPanel, "Loop Chat (2s interval)", false, function(on)
        if on and loopChatTB and loopChatTB.Text ~= "" then
            StartLoopChat(loopChatTB.Text, 2)
        else
            StopLoopChat()
        end
    end, C.Yellow)

    Section(TrollPanel, "Appearance Tricks", C.Teal)
    local _, nametagTB = Input(TrollPanel, "New display name...", nil, C.Teal)
    Btn(TrollPanel, "Set Nametag", function()
        if nametagTB and nametagTB.Text ~= "" then
            SetNametag(nametagTB.Text)
            Notify("Troll","Nametag set: "..nametagTB.Text, 3)
        end
    end, C.Teal)

    Btn(TrollPanel, "Faceswap With Target", function()
        if ST.TrollTarget then Faceswap(ST.TrollTarget) end
    end, C.Teal)

    Btn(TrollPanel, "God Particle ON", function() GodParticle(true) end, Color3.fromRGB(180,100,255))
    Btn(TrollPanel, "God Particle OFF", function() GodParticle(false) end, C.TextDim)
end

-- ============================================================
--  BUILD MOVEMENT PANEL
-- ============================================================
local MovePanel = MakeScrollPanel("Move")
do
    Section(MovePanel, "Flight", C.Green)
    Toggle(MovePanel, "Fly (W/A/S/D + Space/Ctrl)", false, function(on)
        ST.Flying = on
        if on then StartFly() else StopFly() end
    end, C.Green)
    Slider(MovePanel, "Fly Speed", 5, 500, 60, function(v)
        ST.FlySpd = v
    end, C.Green)

    Section(MovePanel, "Movement", C.Green)
    Toggle(MovePanel, "Noclip", false, function(on)
        ST.Noclip = on
        if on then StartNoclip() end
    end, C.Green)
    Toggle(MovePanel, "Infinite Jump", false, function(on)
        ST.InfJump = on
        SetInfJump(on)
    end, C.Green)
    Toggle(MovePanel, "Click TP (tap to teleport)", false, function(on)
        ST.ClickTP = on
        SetClickTP(on)
    end, C.Green)

    Slider(MovePanel, "Walk Speed", 0, 500, 16, function(v)
        ST.Speed = v
        local hum = GetHum()
        if hum then hum.WalkSpeed = v end
    end, C.Green)
    Slider(MovePanel, "Jump Power", 0, 500, 50, function(v)
        ST.Jump = v
        local hum = GetHum()
        if hum then hum.JumpPower = v end
    end, C.Green)

    local speedGrid = Fr(MovePanel, UDim2.new(1,0,0,130), nil, C.BG, 1)
    GL(speedGrid, UDim2.new(0.48,-4,0,56), UDim2.new(0,6,0,6))
    speedGrid.ZIndex = 12
    local speedPresets = {{"Normal",16},{"Fast",50},{"Sprint",100},{"Sonic",250}}
    for _, v in ipairs(speedPresets) do
        local name, spd = v[1], v[2]
        Btn2(speedGrid, name.." ("..spd..")", function()
            ST.Speed = spd
            local hum = GetHum()
            if hum then hum.WalkSpeed = spd end
            Notify("Speed",name.." mode", 2)
        end, C.Green)
    end

    Section(MovePanel, "Checkpoints", C.Teal)
    local cpList = {}
    local cpDisplay = Instance.new("TextLabel")
    cpDisplay.Size = UDim2.new(1,0,0,22)
    cpDisplay.BackgroundTransparency = 1
    cpDisplay.TextColor3 = C.TextDim
    cpDisplay.Font = Enum.Font.Gotham
    cpDisplay.TextSize = 12
    cpDisplay.TextXAlignment = Enum.TextXAlignment.Left
    cpDisplay.Text = "No checkpoints saved"
    cpDisplay.ZIndex = 12
    cpDisplay.Parent = MovePanel

    local cpBtnGrid = Fr(MovePanel, UDim2.new(1,0,0,120), nil, C.BG, 1)
    GL(cpBtnGrid, UDim2.new(0.48,-4,0,52), UDim2.new(0,6,0,6))
    cpBtnGrid.ZIndex = 12

    Btn2(cpBtnGrid, "Save CP", function()
        local root = GetRoot()
        if root then
            cpList[#cpList+1] = root.CFrame
            ST.CPs = cpList
            cpDisplay.Text = #cpList.." checkpoint(s) saved"
            Notify("CP","Checkpoint "..#cpList.." saved!", 2)
        end
    end, C.Teal)
    Btn2(cpBtnGrid, "Load Last CP", function()
        if #cpList > 0 then
            local root = GetRoot()
            if root then root.CFrame = cpList[#cpList] end
            Notify("CP","Loaded checkpoint "..#cpList, 2)
        else
            Notify("CP","No checkpoints saved!", 2)
        end
    end, C.Teal)
    Btn2(cpBtnGrid, "Load CP 1", function()
        if cpList[1] then
            local root = GetRoot()
            if root then root.CFrame = cpList[1] end
        end
    end, C.Accent2)
    Btn2(cpBtnGrid, "Clear All CPs", function()
        cpList = {}; ST.CPs = {}
        cpDisplay.Text = "No checkpoints saved"
        Notify("CP","Cleared", 2)
    end, C.Red)

    Section(MovePanel, "Teleport", C.Accent)
    local _, coordTB = Input(MovePanel, "X Y Z  (e.g. 0 100 0)", nil, C.Accent)
    Btn(MovePanel, "Teleport To Coords", function()
        local root = GetRoot()
        if not root or not coordTB then return end
        local nums = {}
        for n in coordTB.Text:gmatch("[%-]?%d+%.?%d*") do nums[#nums+1]=tonumber(n) end
        if #nums >= 3 then
            root.CFrame = CFrame.new(nums[1],nums[2],nums[3])
            Notify("Move","Teleported to "..nums[1]..","..nums[2]..","..nums[3], 2)
        end
    end, C.Accent)

    Btn(MovePanel, "TP to Spawn", function()
        local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
        local root = GetRoot()
        if spawn and root then
            root.CFrame = spawn.CFrame + Vector3.new(0,5,0)
            Notify("Move","Teleported to spawn", 2)
        end
    end, C.Accent)

    Section(MovePanel, "My Size", C.Orange)
    Slider(MovePanel, "My Body Size", 0.05, 15, 1, function(v)
        SetSize(LocalPlayer, v)
    end, C.Orange)
    local mySizeGrid = Fr(MovePanel, UDim2.new(1,0,0,63), nil, C.BG, 1)
    GL(mySizeGrid, UDim2.new(0.31,-4,0,52), UDim2.new(0,4,0,4))
    mySizeGrid.ZIndex = 12
    Btn2(mySizeGrid, "Tiny", function() SetSize(LocalPlayer,0.1) end, C.Orange)
    Btn2(mySizeGrid, "Normal", function() SetSize(LocalPlayer,1) end, C.Green)
    Btn2(mySizeGrid, "Giant", function() SetSize(LocalPlayer,8) end, C.Orange)
end

-- ============================================================
--  BUILD MUSIC PANEL
-- ============================================================
local MusicPanel = MakeScrollPanel("Music")
do
    -- Now playing card
    local npCard = Fr(MusicPanel, UDim2.new(1,0,0,80), nil, C.Card, 0)
    npCard.ZIndex = 12
    Crn(npCard, 14)
    Strk(npCard, C.Accent2, 1)
    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,Color3.fromRGB(15,20,40)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(8,12,28)),
        })
        g.Rotation=135; g.Parent=npCard
    end

    NPLabel = Instance.new("TextLabel")
    NPLabel.Size = UDim2.new(1,-16,0,28)
    NPLabel.Position = UDim2.new(0,10,0,8)
    NPLabel.BackgroundTransparency=1
    NPLabel.Text = "Now Playing: --"
    NPLabel.TextSize=13
    NPLabel.Font=Enum.Font.GothamBold
    NPLabel.TextColor3=C.Accent2
    NPLabel.TextXAlignment=Enum.TextXAlignment.Left
    NPLabel.TextWrapped=true
    NPLabel.ZIndex=13
    NPLabel.Parent=npCard

    local volLbl = Instance.new("TextLabel")
    volLbl.Size=UDim2.new(0.5,0,0,18)
    volLbl.Position=UDim2.new(0,10,0,40)
    volLbl.BackgroundTransparency=1
    volLbl.Text="Vol: 80% | Global"
    volLbl.TextSize=11
    volLbl.Font=Enum.Font.Gotham
    volLbl.TextColor3=C.TextDim
    volLbl.TextXAlignment=Enum.TextXAlignment.Left
    volLbl.ZIndex=13
    volLbl.Parent=npCard

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size=UDim2.new(0.5,0,0,18)
    statusLbl.Position=UDim2.new(0.5,0,0,40)
    statusLbl.BackgroundTransparency=1
    statusLbl.Text="Status: Stopped"
    statusLbl.TextSize=11
    statusLbl.Font=Enum.Font.GothamBold
    statusLbl.TextColor3=C.Red
    statusLbl.TextXAlignment=Enum.TextXAlignment.Left
    statusLbl.ZIndex=13
    statusLbl.Parent=npCard

    -- Controls
    local ctrlF = Fr(MusicPanel, UDim2.new(1,0,0,58), nil, C.Card, 0)
    Crn(ctrlF,14); ctrlF.ZIndex=12
    LL(ctrlF, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    Pad(ctrlF,8,8,8,8)

    local function CtrlB(text, col, fn)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,65,0,42)
        b.BackgroundColor3=col
        b.BackgroundTransparency=0.2
        b.Text=text
        b.TextColor3=C.White
        b.TextSize=12
        b.Font=Enum.Font.GothamBold
        b.BorderSizePixel=0
        b.ZIndex=13
        b.Parent=ctrlF
        Crn(b,10)
        b.MouseButton1Click:Connect(function() if fn then fn() end end)
        return b
    end

    CtrlB("PREV", C.Accent2, function()
        ST.SongIdx = ((ST.SongIdx-2) % #SONGS)+1
        local s = SONGS[ST.SongIdx]
        PlaySong(s.id, s.n)
        statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
    end)
    CtrlB("PLAY", C.Green, function()
        if ST.MusicOn then
            MusicSound:Pause(); ST.MusicOn=false
            statusLbl.Text="Status: Paused"; statusLbl.TextColor3=C.Yellow
        else
            if ST.SongID then MusicSound:Play(); ST.MusicOn=true
            else
                local s=SONGS[ST.SongIdx]
                PlaySong(s.id,s.n)
            end
            statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
        end
    end)
    CtrlB("STOP", C.Red, function()
        StopMusic()
        statusLbl.Text="Status: Stopped"; statusLbl.TextColor3=C.Red
    end)
    CtrlB("NEXT", C.Accent2, function()
        ST.SongIdx = (ST.SongIdx % #SONGS)+1
        local s=SONGS[ST.SongIdx]
        PlaySong(s.id,s.n)
        statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
    end)

    Toggle(MusicPanel, "Loop Song", false, function(on)
        ST.MusicLoop = on
        MusicSound.Looped = on
    end, C.Accent2)

    Slider(MusicPanel, "Volume", 0, 100, 80, function(v)
        ST.MusicVol = v/100
        MusicSound.Volume = ST.MusicVol
        volLbl.Text = "Vol: "..v.."% | Global"
    end, C.Accent2)

    Section(MusicPanel, "Custom Song ID", C.Accent2)
    local _, customTB = Input(MusicPanel, "Enter Roblox Sound ID...", nil, C.Accent2)
    Btn(MusicPanel, "Play Custom ID", function()
        if customTB then
            local id = customTB.Text:match("%d+")
            if id then
                PlaySong(id, "Custom #"..id)
                statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
            end
        end
    end, C.Accent2)

    Section(MusicPanel, "Library | "..#SONGS.." Songs", C.Accent2)
    for i, song in ipairs(SONGS) do
        local row = Fr(MusicPanel, UDim2.new(1,0,0,54), nil, C.Card, i%2==0 and 0.4 or 0.6)
        row.ZIndex=12
        Crn(row,10)

        local num = Instance.new("TextLabel")
        num.Size=UDim2.new(0,28,1,0)
        num.BackgroundTransparency=1
        num.Text=tostring(i)
        num.TextSize=11
        num.Font=Enum.Font.GothamBold
        num.TextColor3=C.TextDim
        num.TextXAlignment=Enum.TextXAlignment.Center
        num.ZIndex=13
        num.Parent=row

        local sn = Instance.new("TextLabel")
        sn.Size=UDim2.new(1,-100,0,26)
        sn.Position=UDim2.new(0,32,0,4)
        sn.BackgroundTransparency=1
        sn.Text=song.n
        sn.TextSize=13
        sn.Font=Enum.Font.GothamSemibold
        sn.TextColor3=C.Text
        sn.TextXAlignment=Enum.TextXAlignment.Left
        pcall(function() sn.TextTruncate=Enum.TextTruncate.AtEnd end)
        sn.ZIndex=13
        sn.Parent=row

        local sid = Instance.new("TextLabel")
        sid.Size=UDim2.new(1,-100,0,18)
        sid.Position=UDim2.new(0,32,0,30)
        sid.BackgroundTransparency=1
        sid.Text="ID: "..song.id
        sid.TextSize=10
        sid.Font=Enum.Font.Gotham
        sid.TextColor3=C.TextDim
        sid.TextXAlignment=Enum.TextXAlignment.Left
        sid.ZIndex=13
        sid.Parent=row

        local pb = Instance.new("TextButton")
        pb.Size=UDim2.new(0,58,0,36)
        pb.Position=UDim2.new(1,-66,0.5,-18)
        pb.BackgroundColor3=C.Accent2
        pb.BackgroundTransparency=0.2
        pb.Text="PLAY"
        pb.TextColor3=C.White
        pb.TextSize=12
        pb.Font=Enum.Font.GothamBold
        pb.BorderSizePixel=0
        pb.ZIndex=13
        pb.Parent=row
        Crn(pb,10)
        pb.MouseButton1Click:Connect(function()
            ST.SongIdx=i
            PlaySong(song.id, song.n)
            statusLbl.Text="Status: Playing"; statusLbl.TextColor3=C.Green
        end)
    end
end

-- ============================================================
--  BUILD PROTECT PANEL
-- ============================================================
local ProtectPanel = MakeScrollPanel("Protect")
do
    Section(ProtectPanel, "Self Protection", C.Yellow)

    Toggle(ProtectPanel, "God Mode (full HP regen)", false, function(on)
        ST.GodMode = on
        SetGodMode(on)
    end, C.Yellow)

    Toggle(ProtectPanel, "Invisible (local)", false, function(on)
        ST.Invisible = on
        SetLocalInvisible(on)
    end, C.Yellow)

    Toggle(ProtectPanel, "Fullbright", false, function(on)
        ST.Fullbright = on
        SetFullbright(on)
    end, C.Yellow)

    Toggle(ProtectPanel, "Anti-AFK", false, function(on)
        ST.AntiAFK = on
        SetAntiAFK(on)
    end, C.Yellow)

    Toggle(ProtectPanel, "Infinite Jump", false, function(on)
        ST.InfJump = on
        SetInfJump(on)
    end, C.Green)

    Section(ProtectPanel, "Quick Actions", C.Yellow)
    local qaGrid = Fr(ProtectPanel, UDim2.new(1,0,0,130), nil, C.BG, 1)
    GL(qaGrid, UDim2.new(0.48,-4,0,56), UDim2.new(0,6,0,6))
    qaGrid.ZIndex = 12

    Btn2(qaGrid, "Reset Velocity", function()
        local root = GetRoot()
        if root then root.Velocity=Vector3.zero end
        Notify("Protect","Velocity reset",2)
    end, C.Yellow)
    Btn2(qaGrid, "Unanchor Self", function()
        local char = GetChar()
        if char then
            for _,v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored=false end
            end
        end
        Notify("Protect","Unanchored",2)
    end, C.Yellow)
    Btn2(qaGrid, "Respawn", function()
        LocalPlayer:LoadCharacter()
    end, C.Red)
    Btn2(qaGrid, "Full Heal", function()
        local hum = GetHum()
        if hum then hum.Health = hum.MaxHealth end
        Notify("Protect","Healed",2)
    end, C.Green)

    Section(ProtectPanel, "My Appearance", C.Teal)
    Toggle(ProtectPanel, "God Particle (glow)", false, function(on)
        GodParticle(on)
    end, C.Teal)

    Slider(ProtectPanel, "My Size", 0.1, 10, 1, function(v)
        SetSize(LocalPlayer, v)
    end, C.Teal)
end

-- ============================================================
--  BUILD ESP PANEL
-- ============================================================
local ESPPanel = MakeScrollPanel("ESP")
do
    Section(ESPPanel, "Visuals", C.Teal)

    Toggle(ESPPanel, "Player ESP (SelectionBox)", false, function(on)
        ST.ESPOn = on
        UpdateESP(on)
    end, C.Teal)

    Toggle(ESPPanel, "Chams (wall highlight)", false, function(on)
        SetChams(on)
    end, C.Teal)

    Btn(ESPPanel, "Refresh ESP", function()
        if ST.ESPOn then
            UpdateESP(false)
            task.wait(0.1)
            UpdateESP(true)
        end
        Notify("ESP","Refreshed",2)
    end, C.Teal)

    Section(ESPPanel, "Player List", C.Teal)

    local function BuildPlayerList()
        for _, ch in pairs(ESPPanel:GetChildren()) do
            if ch.Name == "PLCard" then ch:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            local card = Fr(ESPPanel, UDim2.new(1,0,0,72), nil, C.Card, 0)
            card.Name = "PLCard"
            card.ZIndex = 12
            Crn(card,12)
            Strk(card, C.Border, 1)

            local nameL = Instance.new("TextLabel")
            nameL.Size=UDim2.new(0.55,0,0,24)
            nameL.Position=UDim2.new(0,10,0,6)
            nameL.BackgroundTransparency=1
            nameL.Text=(p==LocalPlayer and "[YOU] " or "")..p.Name
            nameL.TextSize=13
            nameL.Font=Enum.Font.GothamBold
            nameL.TextColor3 = p==LocalPlayer and C.Green or C.Text
            nameL.TextXAlignment=Enum.TextXAlignment.Left
            nameL.ZIndex=13
            nameL.Parent=card

            local char = p.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local myR  = GetRoot()
            local dist = root and myR and math.floor((root.Position-myR.Position).Magnitude) or "?"
            local hp   = hum and math.floor(hum.Health) or "?"
            local mxhp = hum and math.floor(hum.MaxHealth) or "?"

            local infoL = Instance.new("TextLabel")
            infoL.Size=UDim2.new(0.55,0,0,18)
            infoL.Position=UDim2.new(0,10,0,32)
            infoL.BackgroundTransparency=1
            infoL.Text="HP "..hp.."/"..mxhp.." | "..dist.."m"
            infoL.TextSize=11
            infoL.Font=Enum.Font.Gotham
            infoL.TextColor3=C.TextDim
            infoL.TextXAlignment=Enum.TextXAlignment.Left
            infoL.ZIndex=13
            infoL.Parent=card

            local teamL = Instance.new("TextLabel")
            teamL.Size=UDim2.new(0.55,0,0,16)
            teamL.Position=UDim2.new(0,10,0,50)
            teamL.BackgroundTransparency=1
            teamL.Text="Team: "..(p.Team and p.Team.Name or "None")
            teamL.TextSize=10
            teamL.Font=Enum.Font.Gotham
            teamL.TextColor3=C.TextDim
            teamL.TextXAlignment=Enum.TextXAlignment.Left
            teamL.ZIndex=13
            teamL.Parent=card

            -- Action buttons
            local bGrid = Fr(card, UDim2.new(0.42,0,1,0), UDim2.new(0.58,0,0,0), C.BG, 1)
            bGrid.ZIndex=13
            LL(bGrid, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
            Pad(bGrid,4,4,4,4)

            local function SmBtn(text, col, fn)
                local b=Instance.new("TextButton")
                b.Size=UDim2.new(0,42,0,30)
                b.BackgroundColor3=col
                b.BackgroundTransparency=0.2
                b.Text=text
                b.TextColor3=C.White
                b.TextSize=10
                b.Font=Enum.Font.GothamBold
                b.BorderSizePixel=0
                b.ZIndex=14
                b.Parent=bGrid
                Crn(b,8)
                b.MouseButton1Click:Connect(function() if fn then pcall(fn) end end)
                return b
            end

            SmBtn("TP", C.Accent, function() TPToPlayer(p) end)
            SmBtn("Bring", C.Orange, function() Bring(p) end)
            SmBtn("Fling", C.Red, function() Fling(p) end)
            SmBtn("Kill", Color3.fromRGB(200,0,0), function() Kill(p) end)
        end
    end

    Btn(ESPPanel, "Refresh Player List", BuildPlayerList, C.Teal)
    BuildPlayerList()
    Players.PlayerAdded:Connect(function() task.wait(1); BuildPlayerList() end)
    Players.PlayerRemoving:Connect(function() task.wait(0.5); BuildPlayerList() end)
end

-- ============================================================
--  BUILD UTIL PANEL
-- ============================================================
local UtilPanel = MakeScrollPanel("Util")
do
    Section(UtilPanel, "Server", C.Pink)
    Btn(UtilPanel, "Rejoin Current Server", function()
        local tp = game:GetService("TeleportService")
        tp:Teleport(game.PlaceId, LocalPlayer)
    end, C.Pink)
    Btn(UtilPanel, "Server Hop (find new)", function()
        local tp = game:GetService("TeleportService")
        local ok, data = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
            )
        end)
        if ok and data and data.data then
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    tp:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        Notify("Util","No other servers found, rejoining...",3)
        tp:Teleport(game.PlaceId, LocalPlayer)
    end, C.Pink)

    Section(UtilPanel, "Lighting & World", C.Orange)
    Toggle(UtilPanel, "Fullbright", false, function(on)
        SetFullbright(on)
    end, C.Orange)
    Slider(UtilPanel, "Clock Time", 0, 24, 14, function(v)
        Lighting.ClockTime = v
    end, C.Orange)
    Slider(UtilPanel, "Gravity", 0, 400, 196, function(v)
        workspace.Gravity = v
    end, C.Orange)

    local worldGrid = Fr(UtilPanel, UDim2.new(1,0,0,130), nil, C.BG, 1)
    GL(worldGrid, UDim2.new(0.31,-4,0,52), UDim2.new(0,4,0,4))
    worldGrid.ZIndex=12
    Btn2(worldGrid,"Night",function() Lighting.ClockTime=0 Lighting.Brightness=0.3 end, Color3.fromRGB(20,20,60))
    Btn2(worldGrid,"Sunrise",function() Lighting.ClockTime=6 Lighting.Brightness=1 end, Color3.fromRGB(255,150,80))
    Btn2(worldGrid,"Day",function() Lighting.ClockTime=14 Lighting.Brightness=2 end, Color3.fromRGB(255,220,100))
    Btn2(worldGrid,"Sunset",function() Lighting.ClockTime=18 Lighting.Brightness=1.5 end, Color3.fromRGB(255,100,60))
    Btn2(worldGrid,"Zero-G",function() workspace.Gravity=2 Notify("World","Zero Gravity!",2) end, C.Accent2)
    Btn2(worldGrid,"Moon-G",function() workspace.Gravity=30 Notify("World","Moon Gravity!",2) end, C.TextDim)
    Btn2(worldGrid,"Normal-G",function() workspace.Gravity=196 end, C.Green)

    Section(UtilPanel, "Fog", C.Accent2)
    Slider(UtilPanel, "Fog End", 100, 100000, 100000, function(v)
        Lighting.FogEnd = v
        Lighting.FogStart = v * 0.8
    end, C.Accent2)
    Btn(UtilPanel, "Remove Fog", function()
        Lighting.FogEnd = 999999
        Lighting.FogStart = 999999
    end, C.Accent2)

    Section(UtilPanel, "Game Info", C.TextDim)
    local infoCard = Fr(UtilPanel, UDim2.new(1,0,0,90), nil, C.Card, 0)
    infoCard.ZIndex=12; Crn(infoCard,12)
    Pad(infoCard,10,10,12,12)
    local function getGameInfo()
        local pok, pname = pcall(function()
            return MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)
        return string.format(
            "Game: %s\nPlaceID: %s\nJobID: %s\nPlayers: %d/%d",
            pok and pname or "Unknown",
            tostring(game.PlaceId),
            game.JobId:sub(1,12).."...",
            #Players:GetPlayers(),
            Players.MaxPlayers
        )
    end
    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size=UDim2.new(1,0,1,0)
    infoLbl.BackgroundTransparency=1
    infoLbl.Text=getGameInfo()
    infoLbl.TextSize=11
    infoLbl.Font=Enum.Font.Gotham
    infoLbl.TextColor3=C.TextDim
    infoLbl.TextXAlignment=Enum.TextXAlignment.Left
    infoLbl.TextYAlignment=Enum.TextYAlignment.Top
    infoLbl.TextWrapped=true
    infoLbl.ZIndex=13
    infoLbl.Parent=infoCard

    Btn(UtilPanel, "Copy Job ID (notify)", function()
        Notify("JobID", game.JobId, 8)
    end, C.TextDim)

    Section(UtilPanel, "Voice Note", C.TextDim)
    local voiceLbl = Instance.new("TextLabel")
    voiceLbl.Size=UDim2.new(1,0,0,60)
    voiceLbl.BackgroundTransparency=1
    voiceLbl.Text="Voice Changer: Roblox does not allow\nclient-side audio pitch modification.\nUse VoiceMod on PC outside Roblox."
    voiceLbl.TextSize=11
    voiceLbl.Font=Enum.Font.Gotham
    voiceLbl.TextColor3=C.TextDim
    voiceLbl.TextXAlignment=Enum.TextXAlignment.Left
    voiceLbl.TextWrapped=true
    voiceLbl.ZIndex=12
    voiceLbl.Parent=UtilPanel
end

-- ============================================================
--  BUILD PLAYERS PANEL
-- ============================================================
local PlayersPanel = MakeScrollPanel("Players")
do
    Section(PlayersPanel, "All Players Actions", C.Orange)
    Btn(PlayersPanel, "Fling EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then SuperFling(p) end
        end
        Notify("Troll","EVERYONE FLUNG!",2)
    end, C.Red)
    Btn(PlayersPanel, "Launch EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then Launch(p,1500) end
        end
    end, C.Orange)
    Btn(PlayersPanel, "Explode EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then Explode(p) end
        end
    end, C.Red)
    Btn(PlayersPanel, "Freeze EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then Freeze(p,true) end
        end
        Notify("Troll","All frozen!",2)
    end, C.Accent2)
    Btn(PlayersPanel, "Thaw EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do Freeze(p,false) end
    end, C.Accent2)
    Btn(PlayersPanel, "Fire on EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do SetFire(p,true) end
    end, Color3.fromRGB(255,120,20))
    Btn(PlayersPanel, "Sparkle EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do SetSparkles(p,true) end
    end, C.Yellow)
    Btn(PlayersPanel, "GIANT EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then SetSize(p,10) end
        end
    end, C.Orange)
    Btn(PlayersPanel, "Tiny EVERYONE", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then SetSize(p,0.05) end
        end
    end, C.Orange)
    Btn(PlayersPanel, "Reset ALL Sizes", function()
        for _, p in ipairs(Players:GetPlayers()) do SetSize(p,1) end
    end, C.Green)
    Btn(PlayersPanel, "Blind EVERYONE (8s)", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then Blind(p,8) end
        end
    end, C.Yellow)

    Section(PlayersPanel, "Chat Broadcast", C.Yellow)
    local _, broadTB = Input(PlayersPanel, "Broadcast message...", nil, C.Yellow)
    Btn(PlayersPanel, "Broadcast Message", function()
        if broadTB and broadTB.Text ~= "" then
            SayMessage(broadTB.Text)
        end
    end, C.Yellow)
end

-- ============================================================
--  OPEN / CLOSE WINDOW
-- ============================================================
local OpenWindow, CloseWindow, ToggleMin

local FRAME_SIZE = UDim2.new(0.88, 0, 0.78, 0)

OpenWindow = function()
    ST.Open = true
    MF.Visible = true
    MF.Size = UDim2.new(0,0,0,0)
    Tw(MF, {Size=FRAME_SIZE, BackgroundTransparency=0.05}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tw(FB, {BackgroundTransparency=0.3, Size=UDim2.new(0,60,0,60)}, 0.2)
    SetTab(ST.Tab)
end

CloseWindow = function()
    ST.Open = false
    Tw(MF, {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1}, 0.3, Enum.EasingStyle.Quart)
    Tw(FB, {BackgroundTransparency=0, Size=UDim2.new(0,72,0,72)}, 0.2)
    task.wait(0.35)
    if not ST.Open then MF.Visible=false end
end

ToggleMin = function()
    ST.Mini = not ST.Mini
    if ST.Mini then
        Tw(MF, {Size=UDim2.new(FRAME_SIZE.X.Scale,0,0,58)}, 0.3)
    else
        Tw(MF, {Size=FRAME_SIZE}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
end

-- Connect header buttons
if _G.__KaelenMinBtn then
    _G.__KaelenMinBtn.MouseButton1Click:Connect(function() ToggleMin() end)
end
if _G.__KaelenClsBtn then
    _G.__KaelenClsBtn.MouseButton1Click:Connect(function() CloseWindow() end)
end

-- ============================================================
--  FLOAT BUTTON DRAG & TAP
-- ============================================================
local fbDragging, fbDragDist, fbDragStart, fbStartPos = false,0,nil,nil

FB.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        fbDragging=true; fbDragDist=0
        fbDragStart=inp.Position
        fbStartPos=FB.Position
    end
end)

FB.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        if fbDragDist < 10 then
            if ST.Open then CloseWindow() else OpenWindow() end
        end
        fbDragging=false; fbDragDist=0
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if fbDragging and (inp.UserInputType==Enum.UserInputType.MouseMovement
    or inp.UserInputType==Enum.UserInputType.Touch) then
        local d = inp.Position - fbDragStart
        fbDragDist = fbDragDist + math.abs(d.X)+math.abs(d.Y)
        local vp = Camera.ViewportSize
        local nx = math.clamp(fbStartPos.X.Offset+d.X, 0, vp.X-72)
        local ny = math.clamp(fbStartPos.Y.Offset+d.Y, 0, vp.Y-72)
        FB.Position = UDim2.new(0,nx,0,ny)
    end
end)

-- PC keyboard toggle
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode==Enum.KeyCode.RightBracket then
        if ST.Open then CloseWindow() else OpenWindow() end
    end
end)

-- ============================================================
--  CHARACTER RESPAWN HANDLER
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid",5)
    if hum then
        if ST.Speed ~= 16 then hum.WalkSpeed=ST.Speed end
        if ST.Jump ~= 50 then hum.JumpPower=ST.Jump end
    end
    if ST.InfJump    then SetInfJump(true) end
    if ST.Noclip     then StartNoclip() end
    if ST.Flying     then task.wait(0.5); StartFly() end
    if ST.GodMode    then SetGodMode(true) end
    if ST.Invisible  then SetLocalInvisible(true) end
    if ST.Fullbright then SetFullbright(true) end
end)

-- ============================================================
--  INIT
-- ============================================================
SetTab("Troll")

task.wait(0.3)
Notify("Kaelen Hub v2.0","Tap K to open | ] on PC | "..#SONGS.." songs loaded", 5)

print("╔══════════════════════════════════════╗")
print("║      Kaelen Hub v2.0 - IY Edition    ║")
print("║   Troll | Move | Music | ESP | Util   ║")
print("║         by crx-ter | Delta Ready      ║")
print("╚══════════════════════════════════════╝")
print("[Kaelen] Songs: "..#SONGS.." | Tap the K button or press ] to toggle")
