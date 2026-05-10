-- Kaelen Hub --
-- Version 1.0 | iOS Style | Mobile Optimized | Delta Compatible
-- Features: Troll, Movement, Music, Protection, Utilities, ESP

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")
local StarterGui     = game:GetService("StarterGui")
local Lighting       = game:GetService("Lighting")
local SoundService   = game:GetService("SoundService")
local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()
local Camera         = workspace.CurrentCamera

-- ============================================================
--  CONFIG & STATE
-- ============================================================
local CFG = {
    Colors = {
        BG         = Color3.fromRGB(10, 10, 18),
        Panel      = Color3.fromRGB(18, 18, 30),
        Card       = Color3.fromRGB(26, 26, 42),
        CardHover  = Color3.fromRGB(34, 34, 54),
        Accent     = Color3.fromRGB(120, 80, 255),
        Accent2    = Color3.fromRGB(80, 180, 255),
        AccentPink = Color3.fromRGB(255, 80, 180),
        AccentGreen= Color3.fromRGB(80, 255, 160),
        AccentRed  = Color3.fromRGB(255, 80, 80),
        AccentOrange=Color3.fromRGB(255, 160, 60),
        Text       = Color3.fromRGB(240, 240, 255),
        TextDim    = Color3.fromRGB(140, 140, 180),
        Border     = Color3.fromRGB(50, 50, 80),
        ToggleOff  = Color3.fromRGB(50, 50, 70),
        ToggleOn   = Color3.fromRGB(120, 80, 255),
        Troll      = Color3.fromRGB(255, 100, 80),
        Music      = Color3.fromRGB(80, 200, 255),
        Move       = Color3.fromRGB(100, 255, 150),
        Protect    = Color3.fromRGB(255, 200, 60),
        Util       = Color3.fromRGB(180, 120, 255),
    },
    FloatSize   = UDim2.new(0, 72, 0, 72),
    FrameSize   = UDim2.new(0.88, 0, 0.78, 0),
    FramePos    = UDim2.new(0.5, 0, 0.5, 0),
    CornerR     = UDim.new(0, 18),
    BtnHeight   = 60,
    AnimSpeed   = 0.35,
}

local State = {
    IsOpen       = false,
    IsMinimized  = false,
    CurrentTab   = "Troll",
    -- Movement
    FlyEnabled   = false,
    FlySpeed     = 50,
    NoclipEnabled= false,
    InfJump      = false,
    ClickTP      = false,
    WalkSpeed    = 16,
    JumpPower    = 50,
    GodMode      = false,
    Invisible    = false,
    Fullbright   = false,
    -- Troll
    SpinEnabled  = false,
    SpinTarget   = nil,
    AttachTarget = nil,
    AttachEnabled= false,
    FloatEnabled = false,
    FloatTarget  = nil,
    HeadsitTarget= nil,
    HeadsitOn    = false,
    -- Music
    MusicPlaying = false,
    MusicLoop    = false,
    MusicVolume  = 0.8,
    CurrentSongIdx = 1,
    MusicID      = nil,
    -- ESP
    ESPEnabled   = false,
    ESPBoxes     = {},
    -- Checkpoints
    Checkpoints  = {},
    -- Misc
    OrigBrightness = Lighting.Brightness,
    OrigAmb      = Lighting.Ambient,
}

-- ============================================================
--  SONG LIST (from your PDF)
-- ============================================================
local SONGS = {
    -- My Favs / Electronic
    {name="<3",                  id="109781016044674"},
    {name="Dusk",                id="106475212474249"},
    {name="I'll Go",             id="5410081298"},
    {name="GateHouse",           id="137409529549092"},
    {name="Sprite",              id="5410083814"},
    {name="Stayin Alive",        id="132440988854807"},
    {name="Crab Rave",           id="5410086218"},
    {name="Cant See The Moonlight",id="137072588403399"},
    {name="Sun Sprinting",       id="134698083808996"},
    {name="BackOnTree",          id="95608981665777"},
    {name="Deceptica",           id="79716563884770"},
    {name="Am I Too Late",       id="89804818669338"},
    {name="MovementRhythm",      id="77249446861960"},
    -- Rave/EDM
    {name="Hold On Sped Up",     id="71045969776776"},
    {name="I Can't - Tony Romera",id="5410082805"},
    {name="Never Be The One",    id="111990911956281"},
    {name="Starfall",            id="101934851079098"},
    {name="Run Away",            id="128118999630439"},
    {name="Total Confusion",     id="103419239604004"},
    {name="Jumpstyle",           id="1839246711"},
    {name="Techno Rave",         id="125418384596720"},
    {name="Fell It",             id="109475460178206"},
    {name="TECHNO",              id="73520333282970"},
    {name="MEMORIES",            id="98432184550661"},
    {name="Hold On",             id="71045969776776"},
    {name="Rave Romance",        id="80345427689122"},
    {name="Hardstyle",           id="1839246774"},
    {name="EDM Vegas",           id="1842683759"},
    {name="Dreamraver",          id="138577643632319"},
    -- Rock
    {name="i didn't see it",     id="103902016839820"},
    {name="Skylines",            id="85762528306791"},
    {name="Right here in my arms",id="79627520866718"},
    {name="Join me in death",    id="106344107023335"},
    {name="InnerAwakening",      id="76585504240155"},
    {name="Banana Bashin",       id="118231802185865"},
    {name="Woo Woo Woo Woo",     id="77139878722989"},
    {name="I Miss You",          id="125460168433130"},
    -- Jazz/Lofi/Chill
    {name="Lo-fi Chill A",       id="9043887091"},
    {name="Relaxed Scene",       id="1848354536"},
    {name="Piano In The Dark",   id="1836291588"},
    {name="Moonlit Memories",    id="90866117181187"},
    {name="Capybara",            id="99099326829992"},
    {name="blossom",             id="136212040250804"},
    {name="Crimson Vision",      id="105214146426572"},
    {name="Ambient Blue",        id="139952467445591"},
    {name="Claire De Lune",      id="1838457617"},
    {name="Nocturne",            id="129108903964685"},
    {name="Velvet Midnight",     id="82091048635749"},
    -- Hip Hop/Rap
    {name="Dear Lana",           id="119589412825080"},
    {name="SAD!",                id="72320758533508"},
    {name="plug do rj",          id="129154320419135"},
    -- Phonk
    {name="BRAZIL DO FUNK",      id="133498554139200"},
    {name="CRYSTAL FUNK",        id="103445348511856"},
    {name="MONTAGEM DANCE RAT",  id="112903678064836"},
    {name="SEA OF PHONK",        id="130367831349871"},
    {name="BAILE FUNK",          id="104880194210827"},
    {name="GOTH FUNK",           id="140704128008979"},
    {name="AURA DEFINED Slowed", id="109805678713575"},
    {name="BRX PHONK",           id="17422074849"},
    {name="YOTO HIME PHONK",     id="103183298894656"},
    {name="BEM SOLTO BRAZIL",    id="119936139925486"},
    {name="HOTAKFUNK",           id="79314929106323"},
    {name="NEXOVA",              id="127388462601694"},
    {name="PHONK ULTRA",         id="134839199346188"},
    {name="Demon Phonk Drive",   id="72793675791485"},
    {name="Din1c - Can you",     id="15689448519"},
    {name="Din1c - INVASION",    id="15689453529"},
    {name="Din1c - METAMORPHOSIS",id="15689451063"},
    {name="Cowbell God",         id="16190760005"},
    -- Salsa
    {name="Mezcla Espanola 1",   id="124263849663656"},
    {name="UNIVERSO",            id="95518661042892"},
    {name="Cumbia De Los Cholos",id="77246411659544"},
    {name="Aunque Ella No Lo llore",id="101010703654195"},
    -- Memes
    {name="Vine Boom",           id="6823153536"},
    {name="Crab Rave",           id="5410086218"},
    {name="Wii Sports R&B",      id="72697308378715"},
    {name="THE POWER OF ANIME",  id="1226918619"},
    {name="AUUUUUGH",            id="8893545897"},
    {name="Better Call Saul",    id="9106904975"},
    {name="oh my goodness SQUIDwarD",id="132575703"},
    {name="HEHEHE HA",           id="8406005582"},
    {name="Deja vu Initial D",   id="16831106636"},
}

-- ============================================================
--  HELPERS
-- ============================================================
local function Tween(obj, props, dur, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local t = TweenService:Create(obj, TweenInfo.new(dur or CFG.AnimSpeed, style, dir), props)
    t:Play(); return t
end
local function Corner(p, r) local c=Instance.new("UICorner") c.CornerRadius=r or CFG.CornerR c.Parent=p return c end
local function Stroke(p, col, th) local s=Instance.new("UIStroke") s.Color=col or CFG.Colors.Border s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=p return s end
local function Padding(p,t,b,l,r) local x=Instance.new("UIPadding") x.PaddingTop=UDim.new(0,t or 8) x.PaddingBottom=UDim.new(0,b or 8) x.PaddingLeft=UDim.new(0,l or 8) x.PaddingRight=UDim.new(0,r or 8) x.Parent=p return x end
local function ListLayout(p, dir, spacing, align)
    local l=Instance.new("UIListLayout")
    l.FillDirection=dir or Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,spacing or 8)
    l.HorizontalAlignment=align or Enum.HorizontalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Parent=p return l
end
local function GridLayout(p, cellSize, spacing)
    local g=Instance.new("UIGridLayout")
    g.CellSize=cellSize or UDim2.new(0.48,0,0,60)
    g.CellPaddingSize=UDim2.new(0,spacing or 8,0,spacing or 8)
    g.SortOrder=Enum.SortOrder.LayoutOrder
    g.Parent=p return g
end
local function Label(p, text, size, color, weight)
    local l=Instance.new("TextLabel")
    l.BackgroundTransparency=1
    l.Text=text or ""
    l.TextSize=size or 14
    l.TextColor3=color or CFG.Colors.Text
    l.Font=weight or Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Size=UDim2.new(1,0,0,size and size+6 or 20)
    l.Parent=p return l
end
local function Frame(p, size, pos, color, transparency)
    local f=Instance.new("Frame")
    f.Size=size or UDim2.new(1,0,1,0)
    f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=color or CFG.Colors.Card
    f.BackgroundTransparency=transparency or 0
    f.BorderSizePixel=0
    f.Parent=p return f
end
local function ScrollFrame(p, size, pos, color)
    local s=Instance.new("ScrollingFrame")
    s.Size=size or UDim2.new(1,0,1,0)
    s.Position=pos or UDim2.new(0,0,0,0)
    s.BackgroundColor3=color or CFG.Colors.Panel
    s.BackgroundTransparency=1
    s.BorderSizePixel=0
    s.ScrollBarThickness=3
    s.ScrollBarImageColor3=CFG.Colors.Accent
    s.CanvasSize=UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize=Enum.AutomaticCanvasSize.Y
    s.Parent=p return s
end

local function GetChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end
local function GetRoot()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title=title, Text=text, Duration=dur or 3
        })
    end)
end

-- ============================================================
--  GUI SETUP
-- ============================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local old = PlayerGui:FindFirstChild("KaelenHub")
if old then old:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "KaelenHub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder    = 999
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Parent          = PlayerGui

-- Floating Button
local FloatBtn = Instance.new("ImageButton")
FloatBtn.Name             = "FloatBtn"
FloatBtn.Size             = CFG.FloatSize
FloatBtn.Position         = UDim2.new(0, 14, 0.55, 0)
FloatBtn.BackgroundColor3 = CFG.Colors.Accent
FloatBtn.BorderSizePixel  = 0
FloatBtn.ZIndex           = 10
FloatBtn.Parent           = ScreenGui
Corner(FloatBtn, UDim.new(1, 0))
do
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CFG.Colors.Accent),
        ColorSequenceKeypoint.new(1, CFG.Colors.AccentPink),
    })
    g.Rotation = 135
    g.Parent = FloatBtn
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.Text = "K"
    lbl.TextSize = 28
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Parent = FloatBtn
    -- Pulse ring
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(1.4,0,1.4,0)
    ring.Position = UDim2.new(-0.2,0,-0.2,0)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.ZIndex = 9
    ring.Parent = FloatBtn
    Corner(ring, UDim.new(1,0))
    Stroke(ring, CFG.Colors.Accent, 2)
    local function pulseRing()
        while FloatBtn.Parent do
            Tween(ring, {Size=UDim2.new(1.6,0,1.6,0), Position=UDim2.new(-0.3,0,-0.3,0)}, 0.8, Enum.EasingStyle.Sine)
            local stroke = ring:FindFirstChildOfClass("UIStroke")
            if stroke then Tween(stroke, {Transparency=1}, 0.8, Enum.EasingStyle.Sine) end
            task.wait(0.8)
            ring.Size = UDim2.new(1.4,0,1.4,0)
            ring.Position = UDim2.new(-0.2,0,-0.2,0)
            if stroke then stroke.Transparency = 0.5 end
            task.wait(0.5)
        end
    end
    task.spawn(pulseRing)
end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.AnchorPoint      = Vector2.new(0.5, 0.5)
MainFrame.Size             = UDim2.new(0,0,0,0)
MainFrame.Position         = CFG.FramePos
MainFrame.BackgroundColor3 = CFG.Colors.BG
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel  = 0
MainFrame.Visible          = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex           = 5
MainFrame.Parent           = ScreenGui
Corner(MainFrame)
Stroke(MainFrame, CFG.Colors.Border, 1)

-- Gradient overlay
local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 18, 38)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20)),
})
mainGrad.Rotation = 135
mainGrad.Parent = MainFrame

-- Header
local Header = Frame(MainFrame, UDim2.new(1,0,0,56), UDim2.new(0,0,0,0), CFG.Colors.Panel, 0)
Header.ZIndex = 6
do
    local hGrad = Instance.new("UIGradient")
    hGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30,20,55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18,14,35)),
    })
    hGrad.Rotation = 90
    hGrad.Parent = Header

    local title = Label(Header, "Kaelen Hub", 18, CFG.Colors.Text, Enum.Font.GothamBold)
    title.Size = UDim2.new(0,160,1,0)
    title.Position = UDim2.new(0,16,0,0)
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.ZIndex = 7

    local subtitle = Label(Header, "by crx-ter", 11, CFG.Colors.TextDim, Enum.Font.Gotham)
    subtitle.Size = UDim2.new(0,160,0,14)
    subtitle.Position = UDim2.new(0,16,0,34)
    subtitle.ZIndex = 7

    -- Close button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0,40,0,40)
    CloseBtn.Position = UDim2.new(1,-50,0.5,-20)
    CloseBtn.BackgroundColor3 = CFG.Colors.AccentRed
    CloseBtn.BackgroundTransparency = 0.3
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.new(1,1,1)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.ZIndex = 7
    CloseBtn.Parent = Header
    Corner(CloseBtn, UDim.new(0,10))

    -- Min button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0,40,0,40)
    MinBtn.Position = UDim2.new(1,-96,0.5,-20)
    MinBtn.BackgroundColor3 = CFG.Colors.AccentOrange
    MinBtn.BackgroundTransparency = 0.3
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.new(1,1,1)
    MinBtn.TextSize = 20
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.ZIndex = 7
    MinBtn.Parent = Header
    Corner(MinBtn, UDim.new(0,10))

    local OpenWindow, CloseWindow, ToggleMinimize

    CloseBtn.MouseButton1Click:Connect(function()
        if CloseWindow then CloseWindow() end
    end)
    MinBtn.MouseButton1Click:Connect(function()
        if ToggleMinimize then ToggleMinimize() end
    end)

    -- Header drag
    local dragging, dragStart, startPos = false, nil, nil
    local dragDist = 0
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragDist = 0
            dragStart = inp.Position
            startPos = MainFrame.Position
        end
    end)
    Header.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
            local vp = Camera.ViewportSize
            local delta = inp.Position - dragStart
            dragDist = math.abs(delta.X)+math.abs(delta.Y)
            local nx = math.clamp(startPos.X.Scale + delta.X/vp.X, 0.05, 0.95)
            local ny = math.clamp(startPos.Y.Scale + delta.Y/vp.Y, 0.05, 0.95)
            MainFrame.Position = UDim2.new(nx, 0, ny, 0)
        end
    end)
end

-- ============================================================
--  TAB BAR
-- ============================================================
local TABS = {
    {name="Troll",    icon="", color=CFG.Colors.Troll},
    {name="Move",     icon="", color=CFG.Colors.Move},
    {name="Music",    icon="", color=CFG.Colors.Music},
    {name="Protect",  icon="", color=CFG.Colors.Protect},
    {name="Util",     icon="", color=CFG.Colors.Util},
    {name="ESP",      icon="", color=CFG.Colors.Accent2},
}

local TabBar = Frame(MainFrame, UDim2.new(1,0,0,52), UDim2.new(0,0,0,56), CFG.Colors.Panel, 0)
TabBar.ZIndex = 6

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Size = UDim2.new(1,0,1,0)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 0
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.CanvasSize = UDim2.new(0,0,0,0)
tabScroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.X
tabScroll.Parent = TabBar

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.Padding = UDim.new(0,4)
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Parent = tabScroll
Padding(tabScroll, 6, 6, 8, 8)

local TabBtns = {}
local PanelContainer = Frame(MainFrame, UDim2.new(1,0,1,-108), UDim2.new(0,0,0,108), CFG.Colors.BG, 1)

local ActiveTabColor = CFG.Colors.Accent

local function SetTab(name)
    State.CurrentTab = name
    for _, info in ipairs(TABS) do
        local btn = TabBtns[info.name]
        if not btn then continue end
        if info.name == name then
            Tween(btn, {BackgroundColor3=info.color, BackgroundTransparency=0.1}, 0.2)
            btn.TextColor3 = Color3.new(1,1,1)
            ActiveTabColor = info.color
        else
            Tween(btn, {BackgroundColor3=CFG.Colors.Card, BackgroundTransparency=0.3}, 0.2)
            btn.TextColor3 = CFG.Colors.TextDim
        end
    end
    for _, child in pairs(PanelContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("ScrollingFrame") then
            child.Visible = child.Name == name
        end
    end
end

for i, info in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Name = info.name
    btn.Size = UDim2.new(0, 80, 0, 40)
    btn.BackgroundColor3 = CFG.Colors.Card
    btn.BackgroundTransparency = 0.3
    btn.Text = info.icon .. " " .. info.name
    btn.TextColor3 = CFG.Colors.TextDim
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = i
    btn.Parent = tabScroll
    Corner(btn, UDim.new(0, 12))
    TabBtns[info.name] = btn
    btn.MouseButton1Click:Connect(function()
        SetTab(info.name)
    end)
end

-- ============================================================
--  UI HELPERS FOR PANELS
-- ============================================================
local function MakePanel(name)
    local s = ScrollFrame(PanelContainer, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0))
    s.Name = name
    s.Visible = false
    Padding(s, 10, 10, 10, 10)
    ListLayout(s, Enum.FillDirection.Vertical, 8)
    return s
end

local function SectionLabel(parent, text, color)
    local f = Frame(parent, UDim2.new(1,0,0,28), nil, CFG.Colors.Panel, 0)
    Corner(f, UDim.new(0,8))
    local line = Frame(f, UDim2.new(0,3,0.7,0), UDim2.new(0,0,0.15,0), color or CFG.Colors.Accent, 0)
    Corner(line, UDim.new(1,0))
    local lbl = Label(f, text, 13, color or CFG.Colors.Accent, Enum.Font.GothamBold)
    lbl.Size = UDim2.new(1,-16,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    return f
end

local function MakeToggle(parent, text, defaultOn, onToggle, color)
    color = color or CFG.Colors.Accent
    local f = Frame(parent, UDim2.new(1,0,0,CFG.BtnHeight), nil, CFG.Colors.Card, 0)
    Corner(f)
    Stroke(f, CFG.Colors.Border, 1)

    local enabled = defaultOn or false

    local lbl = Label(f, text, 14, CFG.Colors.Text, Enum.Font.GothamSemibold)
    lbl.Size = UDim2.new(1,-70,1,0)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.TextYAlignment = Enum.TextYAlignment.Center

    -- Toggle pill
    local pill = Frame(f, UDim2.new(0,52,0,28), UDim2.new(1,-64,0.5,-14), CFG.Colors.ToggleOff, 0)
    Corner(pill, UDim.new(1,0))
    local knob = Frame(pill, UDim2.new(0,22,0,22), UDim2.new(0,3,0.5,-11), Color3.new(1,1,1), 0)
    Corner(knob, UDim.new(1,0))

    local function updateVisual()
        if enabled then
            Tween(pill, {BackgroundColor3=color}, 0.2)
            Tween(knob, {Position=UDim2.new(0,27,0.5,-11)}, 0.2)
        else
            Tween(pill, {BackgroundColor3=CFG.Colors.ToggleOff}, 0.2)
            Tween(knob, {Position=UDim2.new(0,3,0.5,-11)}, 0.2)
        end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = f
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateVisual()
        if onToggle then onToggle(enabled) end
    end)

    updateVisual()
    return f, function() return enabled end, function(v) enabled=v updateVisual() end
end

local function MakeButton(parent, text, onClick, color, icon)
    color = color or CFG.Colors.Accent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,CFG.BtnHeight)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.Text = (icon and icon.." " or "") .. text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = parent
    Corner(btn)

    btn.MouseButton1Click:Connect(function()
        Tween(btn, {BackgroundTransparency=0}, 0.1)
        task.wait(0.1)
        Tween(btn, {BackgroundTransparency=0.2}, 0.2)
        if onClick then onClick() end
    end)
    btn.MouseEnter:Connect(function() Tween(btn, {BackgroundTransparency=0.05}, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, {BackgroundTransparency=0.2}, 0.15) end)
    return btn
end

local function MakeSlider(parent, text, minV, maxV, defaultV, onChanged, color)
    color = color or CFG.Colors.Accent
    local f = Frame(parent, UDim2.new(1,0,0,70), nil, CFG.Colors.Card, 0)
    Corner(f)
    Stroke(f, CFG.Colors.Border, 1)

    local valLabel = Label(f, text .. ": " .. tostring(math.floor(defaultV)), 13, CFG.Colors.Text, Enum.Font.GothamBold)
    valLabel.Size = UDim2.new(1,-14,0,22)
    valLabel.Position = UDim2.new(0,14,0,8)

    local track = Frame(f, UDim2.new(1,-28,0,6), UDim2.new(0,14,0,42), CFG.Colors.ToggleOff, 0)
    Corner(track, UDim.new(1,0))

    local fill = Frame(track, UDim2.new((defaultV-minV)/(maxV-minV),0,1,0), nil, color, 0)
    Corner(fill, UDim.new(1,0))

    local knob = Frame(track, UDim2.new(0,18,0,18), UDim2.new((defaultV-minV)/(maxV-minV),0,0.5,-9), color, 0)
    Corner(knob, UDim.new(1,0))
    do local s=Instance.new("UIStroke") s.Color=Color3.new(1,1,1) s.Thickness=2 s.Parent=knob end

    local value = defaultV
    local sliding = false

    local function updateSlider(inputPos)
        local abs = track.AbsolutePosition
        local sz  = track.AbsoluteSize
        local ratio = math.clamp((inputPos.X - abs.X) / sz.X, 0, 1)
        value = math.floor(minV + (maxV - minV) * ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -9, 0.5, -9)
        valLabel.Text = text .. ": " .. tostring(value)
        if onChanged then onChanged(value) end
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateSlider(inp.Position)
        end
    end)
    track.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(inp.Position)
        end
    end)

    return f
end

local function MakePlayerPicker(parent, onPick)
    local f = Frame(parent, UDim2.new(1,0,0,CFG.BtnHeight), nil, CFG.Colors.Card, 0)
    Corner(f)
    Stroke(f, CFG.Colors.Border, 1)

    local lbl = Label(f, "Target: Everyone", 13, CFG.Colors.TextDim, Enum.Font.Gotham)
    lbl.Size = UDim2.new(1,-70,1,0)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.TextYAlignment = Enum.TextYAlignment.Center

    local idx = 0
    local function getTargets()
        local list = {"Everyone"}
        for _,p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(list, p.Name) end
        end
        return list
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,60,0,36)
    btn.Position = UDim2.new(1,-68,0.5,-18)
    btn.BackgroundColor3 = CFG.Colors.Accent
    btn.BackgroundTransparency = 0.3
    btn.Text = "Next"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = f
    Corner(btn, UDim.new(0,10))

    btn.MouseButton1Click:Connect(function()
        local targets = getTargets()
        idx = (idx % #targets) + 1
        lbl.Text = "Target: " .. targets[idx]
        local target = targets[idx] == "Everyone" and nil or Players:FindFirstChild(targets[idx])
        if onPick then onPick(target) end
    end)
    return f
end

local function MakeInput(parent, placeholder, onSubmit, color)
    color = color or CFG.Colors.Accent
    local f = Frame(parent, UDim2.new(1,0,0,CFG.BtnHeight), nil, CFG.Colors.Card, 0)
    Corner(f)
    Stroke(f, CFG.Colors.Border, 1)

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1,-80,0,40)
    input.Position = UDim2.new(0,10,0.5,-20)
    input.BackgroundColor3 = CFG.Colors.BG
    input.BackgroundTransparency = 0.3
    input.Text = ""
    input.PlaceholderText = placeholder or "Enter..."
    input.PlaceholderColor3 = CFG.Colors.TextDim
    input.TextColor3 = CFG.Colors.Text
    input.TextSize = 13
    input.Font = Enum.Font.Gotham
    input.BorderSizePixel = 0
    input.ClearTextOnFocus = false
    input.Parent = f
    Corner(input, UDim.new(0,10))
    Padding(input, 0,0,8,8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,58,0,40)
    btn.Position = UDim2.new(1,-68,0.5,-20)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.2
    btn.Text = "Go"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = f
    Corner(btn, UDim.new(0,10))

    btn.MouseButton1Click:Connect(function()
        if onSubmit then onSubmit(input.Text) end
    end)
    input.FocusLost:Connect(function(enter)
        if enter and onSubmit then onSubmit(input.Text) end
    end)
    return f, input
end

-- ============================================================
--  MOVEMENT MODULES
-- ============================================================
local FlyConn = {}
local function StartFly()
    local char = GetChar() if not char then return end
    local root = GetRoot() if not root then return end
    local hum  = GetHum()  if not hum  then return end
    hum.PlatformStand = true
    local bv = Instance.new("BodyVelocity") bv.Velocity=Vector3.zero bv.MaxForce=Vector3.new(1e9,1e9,1e9) bv.Parent=root
    local bg = Instance.new("BodyGyro")     bg.MaxTorque=Vector3.new(1e9,1e9,1e9) bg.CFrame=root.CFrame bg.P=1e5 bg.Parent=root
    FlyConn.rs = RunService.Heartbeat:Connect(function()
        if not State.FlyEnabled then bv:Destroy() bg:Destroy() if hum then hum.PlatformStand=false end FlyConn.rs:Disconnect() return end
        local cam = Camera
        local cf = cam.CFrame
        local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0,1,0) end
        bv.Velocity = vel * State.FlySpeed
        if vel.Magnitude > 0 then bg.CFrame = CFrame.lookAt(root.Position, root.Position + vel) end
    end)
end
local function StopFly()
    if FlyConn.rs then FlyConn.rs:Disconnect() end
    local root = GetRoot()
    if root then
        local bv = root:FindFirstChildOfClass("BodyVelocity")
        local bg = root:FindFirstChildOfClass("BodyGyro")
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
    local hum = GetHum()
    if hum then hum.PlatformStand = false end
end

local NoclipConn
local function StartNoclip()
    NoclipConn = RunService.Stepped:Connect(function()
        if not State.NoclipEnabled then NoclipConn:Disconnect() return end
        local char = LocalPlayer.Character
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
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
            if not State.ClickTP then ClickTPConn:Disconnect() return end
            local root = GetRoot()
            if root and Mouse.Hit then
                root.CFrame = Mouse.Hit + Vector3.new(0,3,0)
            end
        end)
    end
end

-- ============================================================
--  TROLL MODULES
-- ============================================================
local SpinConn
local function SpinPlayer(target)
    if SpinConn then SpinConn:Disconnect() end
    local root = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root then
        -- spin self
        root = GetRoot()
    end
    if not root then return end
    local angle = 0
    local cf = root.CFrame
    SpinConn = RunService.Heartbeat:Connect(function(dt)
        if not State.SpinEnabled then SpinConn:Disconnect() return end
        angle = angle + dt * 360 * 3
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(angle), 0)
    end)
end

local function FlingPlayer(target)
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(math.random(-1,1)*500, math.random(300,800), math.random(-1,1)*500)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = root
    game:GetService("Debris"):AddItem(bv, 0.2)
end

local function SuperFlingPlayer(target)
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for i=1,5 do
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(math.random(-1,1)*9999, math.random(999,9999), math.random(-1,1)*9999)
        bv.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
        bv.Parent = root
        game:GetService("Debris"):AddItem(bv, 0.05)
        task.wait(0.05)
    end
end

local function LaunchPlayer(target)
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 1500, 0)
    bv.MaxForce = Vector3.new(0,1e9,0)
    bv.Parent = root
    game:GetService("Debris"):AddItem(bv, 0.3)
end

local AttachConn
local function AttachToPlayer(target)
    if AttachConn then AttachConn:Disconnect() end
    if not target or not target.Character then return end
    AttachConn = RunService.Heartbeat:Connect(function()
        if not State.AttachEnabled then AttachConn:Disconnect() return end
        local myRoot = GetRoot()
        local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if myRoot and tRoot then
            myRoot.CFrame = tRoot.CFrame * CFrame.new(0,0,-4)
        end
    end)
end

local HeadsitConn
local function HeadsitPlayer(target)
    if HeadsitConn then HeadsitConn:Disconnect() end
    if not target or not target.Character then return end
    HeadsitConn = RunService.Heartbeat:Connect(function()
        if not State.HeadsitOn then HeadsitConn:Disconnect() return end
        local myRoot = GetRoot()
        local tHead = target.Character and target.Character:FindFirstChild("Head")
        if myRoot and tHead then
            myRoot.CFrame = tHead.CFrame * CFrame.new(0, 3, 0)
        end
    end)
end

local FloatConn
local function FloatPlayer(target)
    if FloatConn then FloatConn:Disconnect() end
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    FloatConn = RunService.Heartbeat:Connect(function()
        if not State.FloatEnabled then FloatConn:Disconnect() return end
        root.Velocity = Vector3.new(0, 20, 0)
    end)
end

local function SetSize(target, scale)
    local char = target and target.Character or GetChar()
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.BodyDepthScale.Value = scale hum.BodyHeightScale.Value = scale hum.BodyWidthScale.Value = scale hum.HeadScale.Value = scale end
end

local function FreezePlayer(target, on)
    if not target or not target.Character then return end
    for _, v in pairs(target.Character:GetDescendants()) do
        if v:IsA("BasePart") then v.Anchored = on end
    end
end

local function BlindPlayer(target)
    if not target or not target.Character then return end
    -- Creates a bright part over their head to blind their camera
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local blinder = Instance.new("Part")
    blinder.Size = Vector3.new(5,5,5)
    blinder.BrickColor = BrickColor.new("White")
    blinder.Material = Enum.Material.Neon
    blinder.CanCollide = false
    blinder.Parent = workspace
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = head
    weld.Part1 = blinder
    weld.Parent = blinder
    blinder.CFrame = head.CFrame
    game:GetService("Debris"):AddItem(blinder, 5)
    Notify("Kaelen", "Blinded "..target.Name.." for 5s", 3)
end

local function KnockbackPlayer(target)
    if not target or not target.Character then return end
    local myRoot = GetRoot()
    local tRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not tRoot then return end
    local dir = (tRoot.Position - myRoot.Position).Unit
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = dir * 200 + Vector3.new(0,80,0)
    bv.MaxForce = Vector3.new(1e9,1e9,1e9)
    bv.Parent = tRoot
    game:GetService("Debris"):AddItem(bv, 0.3)
end

local DanceConn
local DanceAnims = {
    "507770239","507771019","507771955","507772104","507772398",
    "507773317","507776043","507776468","507777268","507777451",
}
local function Dance(idx)
    if DanceConn then DanceConn:Disconnect() end
    local hum = GetHum()
    if not hum then return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. (DanceAnims[idx] or DanceAnims[1])
    local track = hum.Animator:LoadAnimation(anim)
    track:Play()
    DanceConn = track
end

-- ============================================================
--  MUSIC MODULE
-- ============================================================
local MusicSound = Instance.new("Sound")
MusicSound.Name = "KaelenMusic"
MusicSound.Volume = State.MusicVolume
MusicSound.RollOffMaxDistance = 999999
MusicSound.RollOffMinDistance = 999999
MusicSound.RollOffMode = Enum.RollOffMode.InverseTapered
MusicSound.Parent = workspace

local function PlaySong(id)
    MusicSound.SoundId = "rbxassetid://" .. tostring(id)
    MusicSound:Stop()
    MusicSound:Play()
    State.MusicPlaying = true
    State.MusicID = id
end

local function StopMusic()
    MusicSound:Stop()
    State.MusicPlaying = false
end

MusicSound.Ended:Connect(function()
    if State.MusicLoop and State.MusicID then
        MusicSound:Play()
    elseif State.MusicPlaying then
        -- Auto next
        State.CurrentSongIdx = (State.CurrentSongIdx % #SONGS) + 1
        PlaySong(SONGS[State.CurrentSongIdx].id)
    end
end)

-- ============================================================
--  PROTECTION MODULES
-- ============================================================
local GodConn
local function SetGodMode(on)
    if GodConn then GodConn:Disconnect() GodConn=nil end
    if on then
        GodConn = RunService.Heartbeat:Connect(function()
            local hum = GetHum()
            if hum then hum.Health = hum.MaxHealth end
        end)
    end
end

local InvisConn
local function SetInvisible(on)
    local char = GetChar()
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") then
            v.LocalTransparencyModifier = on and 1 or 0
        end
    end
end

local function SetFullbright(on)
    if on then
        State.OrigBrightness = Lighting.Brightness
        State.OrigAmb = Lighting.Ambient
        Lighting.Brightness = 10
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.ClockTime = 14
    else
        Lighting.Brightness = State.OrigBrightness
        Lighting.Ambient = State.OrigAmb
    end
end

-- ============================================================
--  ESP MODULE
-- ============================================================
local ESPHighlights = {}
local function UpdateESP(on)
    for _, h in pairs(ESPHighlights) do h:Destroy() end
    ESPHighlights = {}
    if not on then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = Instance.new("SelectionBox")
            h.Color3 = CFG.Colors.AccentRed
            h.LineThickness = 0.05
            h.SurfaceTransparency = 0.7
            h.SurfaceColor3 = CFG.Colors.AccentRed
            h.Adornee = p.Character
            h.Parent = workspace
            ESPHighlights[p.Name] = h
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    if State.ESPEnabled then
        p.CharacterAdded:Connect(function(char)
            task.wait(1)
            local h = Instance.new("SelectionBox")
            h.Color3 = CFG.Colors.AccentRed
            h.LineThickness = 0.05
            h.SurfaceTransparency = 0.7
            h.SurfaceColor3 = CFG.Colors.AccentRed
            h.Adornee = char
            h.Parent = workspace
            ESPHighlights[p.Name] = h
        end)
    end
end)

-- ============================================================
--  BUILD PANELS
-- ============================================================

-- TROLL PANEL
local TrollPanel = MakePanel("Troll")
do
    SectionLabel(TrollPanel, "Target", CFG.Colors.Troll)
    local selectedTarget = nil
    MakePlayerPicker(TrollPanel, function(p) selectedTarget = p end)

    SectionLabel(TrollPanel, "Fling & Launch", CFG.Colors.Troll)

    MakeButton(TrollPanel, "Fling", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then FlingPlayer(p) end end
        Notify("Kaelen", "Flung!", 2)
    end, CFG.Colors.Troll)

    MakeButton(TrollPanel, "SUPER FLING", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SuperFlingPlayer(p) end end
        Notify("Kaelen", "SUPER FLUNG!!", 2)
    end, Color3.fromRGB(255,50,50))

    MakeButton(TrollPanel, "Launch UP", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then LaunchPlayer(p) end end
    end, CFG.Colors.Troll)

    MakeButton(TrollPanel, "Knockback", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then KnockbackPlayer(p) end end
    end, CFG.Colors.Troll)

    SectionLabel(TrollPanel, "Control", CFG.Colors.AccentPink)

    local spinToggle = MakeToggle(TrollPanel, "Spin (Target/Self)", false, function(on)
        State.SpinEnabled = on
        if on then SpinPlayer(selectedTarget) end
    end, CFG.Colors.AccentPink)

    local headsitToggle = MakeToggle(TrollPanel, "Headsit", false, function(on)
        State.HeadsitOn = on
        if on and selectedTarget then
            HeadsitPlayer(selectedTarget)
        end
    end, CFG.Colors.AccentPink)

    local attachToggle = MakeToggle(TrollPanel, "Attach / Follow", false, function(on)
        State.AttachEnabled = on
        if on and selectedTarget then AttachToPlayer(selectedTarget) end
    end, CFG.Colors.AccentPink)

    local floatToggle = MakeToggle(TrollPanel, "Float Player", false, function(on)
        State.FloatEnabled = on
        if on and selectedTarget then FloatPlayer(selectedTarget) end
    end, CFG.Colors.AccentPink)

    SectionLabel(TrollPanel, "Size & Freeze", CFG.Colors.AccentOrange)

    MakeSlider(TrollPanel, "Target Size", 0.1, 10, 1, function(v)
        if selectedTarget then SetSize(selectedTarget, v) end
    end, CFG.Colors.AccentOrange)

    MakeButton(TrollPanel, "Tiny (0.1x)", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetSize(p, 0.1) end end
    end, CFG.Colors.AccentOrange)

    MakeButton(TrollPanel, "GIANT (10x)", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do if p ~= LocalPlayer then SetSize(p, 10) end end
    end, CFG.Colors.AccentOrange)

    MakeButton(TrollPanel, "Normal Size", function()
        local targets = selectedTarget and {selectedTarget} or Players:GetPlayers()
        for _, p in ipairs(targets) do SetSize(p, 1) end
    end, CFG.Colors.AccentOrange)

    local freezeState = {}
    MakeButton(TrollPanel, "Freeze Target", function()
        if selectedTarget then
            freezeState[selectedTarget.Name] = not (freezeState[selectedTarget.Name] or false)
            FreezePlayer(selectedTarget, freezeState[selectedTarget.Name])
            Notify("Kaelen", (freezeState[selectedTarget.Name] and "Froze " or "Thawed ") .. selectedTarget.Name, 2)
        else
            Notify("Kaelen", "Select a target first", 2)
        end
    end, CFG.Colors.Accent2)

    MakeButton(TrollPanel, "Thaw All", function()
        for _, p in ipairs(Players:GetPlayers()) do FreezePlayer(p, false) end
    end, CFG.Colors.Accent2)

    SectionLabel(TrollPanel, "Misc Troll", CFG.Colors.AccentPink)

    MakeButton(TrollPanel, "Blind (5s)", function()
        if selectedTarget then BlindPlayer(selectedTarget)
        else for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then BlindPlayer(p) end end end
    end, CFG.Colors.AccentPink)

    MakeButton(TrollPanel, "Teleport To Target", function()
        if selectedTarget and selectedTarget.Character then
            local root = GetRoot()
            local tRoot = selectedTarget.Character:FindFirstChild("HumanoidRootPart")
            if root and tRoot then root.CFrame = tRoot.CFrame * CFrame.new(0,0,4) end
        end
    end, CFG.Colors.Accent)

    MakeButton(TrollPanel, "Bring Target To Me", function()
        if selectedTarget and selectedTarget.Character then
            local root = GetRoot()
            local tRoot = selectedTarget.Character:FindFirstChild("HumanoidRootPart")
            if root and tRoot then tRoot.CFrame = root.CFrame * CFrame.new(0,0,4) end
        end
    end, CFG.Colors.Accent)

    SectionLabel(TrollPanel, "Dance", CFG.Colors.Music)
    local danceFrame = Frame(TrollPanel, UDim2.new(1,0,0,130), nil, CFG.Colors.Card, 0)
    Corner(danceFrame)
    Stroke(danceFrame, CFG.Colors.Border, 1)
    local danceGrid = Instance.new("UIGridLayout")
    danceGrid.CellSize = UDim2.new(0.3, -4, 0, 48)
    danceGrid.CellPaddingSize = UDim2.new(0, 4, 0, 4)
    danceGrid.Parent = danceFrame
    Padding(danceFrame, 6, 6, 6, 6)
    for i=1,9 do
        local db = Instance.new("TextButton")
        db.Size = UDim2.new(0,0,0,0)
        db.BackgroundColor3 = CFG.Colors.Music
        db.BackgroundTransparency = 0.3
        db.Text = "Dance "..i
        db.TextColor3 = Color3.new(1,1,1)
        db.TextSize = 12
        db.Font = Enum.Font.GothamBold
        db.BorderSizePixel = 0
        db.Parent = danceFrame
        Corner(db, UDim.new(0,10))
        db.MouseButton1Click:Connect(function() Dance(i) end)
    end
end

-- MOVEMENT PANEL
local MovePanel = MakePanel("Move")
do
    SectionLabel(MovePanel, "Flight", CFG.Colors.Move)
    MakeToggle(MovePanel, "Fly (W/A/S/D + Space)", false, function(on)
        State.FlyEnabled = on
        if on then StartFly() else StopFly() end
    end, CFG.Colors.Move)
    MakeSlider(MovePanel, "Fly Speed", 10, 300, 50, function(v) State.FlySpeed=v end, CFG.Colors.Move)

    SectionLabel(MovePanel, "Movement", CFG.Colors.Move)
    MakeToggle(MovePanel, "Noclip", false, function(on)
        State.NoclipEnabled = on
        if on then StartNoclip() end
    end, CFG.Colors.Move)
    MakeToggle(MovePanel, "Infinite Jump", false, function(on)
        State.InfJump = on
        SetInfJump(on)
    end, CFG.Colors.Move)
    MakeToggle(MovePanel, "Click TP", false, function(on)
        State.ClickTP = on
        SetClickTP(on)
    end, CFG.Colors.Move)

    MakeSlider(MovePanel, "WalkSpeed", 0, 500, 16, function(v)
        State.WalkSpeed = v
        local hum = GetHum()
        if hum then hum.WalkSpeed = v end
    end, CFG.Colors.Move)
    MakeSlider(MovePanel, "JumpPower", 0, 500, 50, function(v)
        State.JumpPower = v
        local hum = GetHum()
        if hum then hum.JumpPower = v end
    end, CFG.Colors.Move)

    SectionLabel(MovePanel, "Checkpoints", CFG.Colors.AccentGreen)
    MakeButton(MovePanel, "Save Checkpoint", function()
        local root = GetRoot()
        if root then
            table.insert(State.Checkpoints, root.CFrame)
            Notify("Kaelen", "Checkpoint "..#State.Checkpoints.." saved!", 2)
        end
    end, CFG.Colors.AccentGreen)
    MakeButton(MovePanel, "Load Last Checkpoint", function()
        if #State.Checkpoints > 0 then
            local root = GetRoot()
            if root then root.CFrame = State.Checkpoints[#State.Checkpoints] end
        else
            Notify("Kaelen", "No checkpoints saved!", 2)
        end
    end, CFG.Colors.AccentGreen)
    MakeButton(MovePanel, "Clear Checkpoints", function()
        State.Checkpoints = {}
        Notify("Kaelen", "Checkpoints cleared", 2)
    end, CFG.Colors.AccentRed)

    SectionLabel(MovePanel, "Quick TP", CFG.Colors.Accent2)
    MakeInput(MovePanel, "X, Y, Z (eg: 0 100 0)", function(text)
        local root = GetRoot()
        if not root then return end
        local coords = {}
        for v in text:gmatch("[%-]?%d+%.?%d*") do table.insert(coords, tonumber(v)) end
        if #coords >= 3 then
            root.CFrame = CFrame.new(coords[1], coords[2], coords[3])
            Notify("Kaelen", "Teleported!", 2)
        end
    end, CFG.Colors.Accent2)
end

-- MUSIC PANEL
local MusicPanel = MakePanel("Music")
do
    -- Now Playing display
    local npFrame = Frame(MusicPanel, UDim2.new(1,0,0,70), nil, CFG.Colors.Card, 0)
    Corner(npFrame)
    Stroke(npFrame, CFG.Colors.Accent, 1)
    do
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20,10,40)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10,18,35)),
        })
        g.Rotation = 135
        g.Parent = npFrame
    end
    local npTitle = Label(npFrame, "Now Playing: --", 13, CFG.Colors.Music, Enum.Font.GothamBold)
    npTitle.Size = UDim2.new(1,-14,0,20)
    npTitle.Position = UDim2.new(0,10,0,10)
    local npSub = Label(npFrame, "Music plays globally for all players", 11, CFG.Colors.TextDim, Enum.Font.Gotham)
    npSub.Size = UDim2.new(1,-14,0,16)
    npSub.Position = UDim2.new(0,10,0,32)
    local npVolLabel = Label(npFrame, "Volume: 80%", 11, CFG.Colors.TextDim, Enum.Font.Gotham)
    npVolLabel.Size = UDim2.new(1,-14,0,16)
    npVolLabel.Position = UDim2.new(0,10,0,50)

    -- Controls
    local ctrlFrame = Frame(MusicPanel, UDim2.new(1,0,0,60), nil, CFG.Colors.Card, 0)
    Corner(ctrlFrame)
    do
        local ctrlList = Instance.new("UIListLayout")
        ctrlList.FillDirection = Enum.FillDirection.Horizontal
        ctrlList.Padding = UDim.new(0,6)
        ctrlList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ctrlList.VerticalAlignment = Enum.VerticalAlignment.Center
        ctrlList.Parent = ctrlFrame

        local function CtrlBtn(text, color, onClick)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0,72,0,44)
            b.BackgroundColor3 = color
            b.BackgroundTransparency = 0.2
            b.Text = text
            b.TextColor3 = Color3.new(1,1,1)
            b.TextSize = 13
            b.Font = Enum.Font.GothamBold
            b.BorderSizePixel = 0
            b.Parent = ctrlFrame
            Corner(b, UDim.new(0,12))
            b.MouseButton1Click:Connect(onClick)
            return b
        end

        CtrlBtn("PREV", CFG.Colors.Accent2, function()
            State.CurrentSongIdx = ((State.CurrentSongIdx - 2) % #SONGS) + 1
            PlaySong(SONGS[State.CurrentSongIdx].id)
            npTitle.Text = "Now Playing: "..SONGS[State.CurrentSongIdx].name
        end)
        CtrlBtn("PLAY", CFG.Colors.AccentGreen, function()
            if State.MusicPlaying then
                MusicSound:Pause()
                State.MusicPlaying = false
            else
                if State.MusicID then MusicSound:Play() State.MusicPlaying=true
                else
                    PlaySong(SONGS[State.CurrentSongIdx].id)
                    npTitle.Text = "Now Playing: "..SONGS[State.CurrentSongIdx].name
                end
            end
        end)
        CtrlBtn("STOP", CFG.Colors.AccentRed, function()
            StopMusic()
            npTitle.Text = "Now Playing: --"
        end)
        CtrlBtn("NEXT", CFG.Colors.Accent2, function()
            State.CurrentSongIdx = (State.CurrentSongIdx % #SONGS) + 1
            PlaySong(SONGS[State.CurrentSongIdx].id)
            npTitle.Text = "Now Playing: "..SONGS[State.CurrentSongIdx].name
        end)
    end

    MakeToggle(MusicPanel, "Loop Song", false, function(on)
        State.MusicLoop = on
        MusicSound.Looped = on
    end, CFG.Colors.Music)

    MakeSlider(MusicPanel, "Volume", 0, 100, 80, function(v)
        State.MusicVolume = v/100
        MusicSound.Volume = State.MusicVolume
        npVolLabel.Text = "Volume: "..v.."%"
    end, CFG.Colors.Music)

    -- Custom ID
    SectionLabel(MusicPanel, "Custom Song ID", CFG.Colors.Music)
    MakeInput(MusicPanel, "Enter Roblox Sound ID...", function(text)
        local id = text:match("%d+")
        if id then
            PlaySong(id)
            npTitle.Text = "Now Playing: Custom #"..id
        end
    end, CFG.Colors.Music)

    -- Song List
    SectionLabel(MusicPanel, "Song Library ("..#SONGS.." songs)", CFG.Colors.Music)
    for i, song in ipairs(SONGS) do
        local songBtn = Instance.new("TextButton")
        songBtn.Size = UDim2.new(1,0,0,52)
        songBtn.BackgroundColor3 = CFG.Colors.Card
        songBtn.BackgroundTransparency = i%2==0 and 0.3 or 0.5
        songBtn.Text = ""
        songBtn.BorderSizePixel = 0
        songBtn.Parent = MusicPanel
        Corner(songBtn, UDim.new(0,10))

        local num = Label(songBtn, tostring(i), 11, CFG.Colors.TextDim, Enum.Font.Gotham)
        num.Size = UDim2.new(0,28,1,0)
        num.Position = UDim2.new(0,8,0,0)
        num.TextYAlignment = Enum.TextYAlignment.Center
        num.TextXAlignment = Enum.TextXAlignment.Center

        local sname = Label(songBtn, song.name, 13, CFG.Colors.Text, Enum.Font.GothamSemibold)
        sname.Size = UDim2.new(1,-90,0,26)
        sname.Position = UDim2.new(0,36,0,4)

        local sid = Label(songBtn, "ID: "..song.id, 10, CFG.Colors.TextDim, Enum.Font.Gotham)
        sid.Size = UDim2.new(1,-90,0,18)
        sid.Position = UDim2.new(0,36,0,30)

        local playIco = Label(songBtn, "PLAY", 11, CFG.Colors.Music, Enum.Font.GothamBold)
        playIco.Size = UDim2.new(0,44,1,0)
        playIco.Position = UDim2.new(1,-52,0,0)
        playIco.TextXAlignment = Enum.TextXAlignment.Center

        songBtn.MouseButton1Click:Connect(function()
            State.CurrentSongIdx = i
            PlaySong(song.id)
            npTitle.Text = "Now Playing: "..song.name
            Notify("Kaelen Music", "Playing: "..song.name, 3)
        end)
    end
end

-- PROTECTION PANEL
local ProtectPanel = MakePanel("Protect")
do
    SectionLabel(ProtectPanel, "Self Protection", CFG.Colors.Protect)

    MakeToggle(ProtectPanel, "God Mode (Full HP)", false, function(on)
        State.GodMode = on
        SetGodMode(on)
    end, CFG.Colors.Protect)

    MakeToggle(ProtectPanel, "Invisible", false, function(on)
        State.Invisible = on
        SetInvisible(on)
    end, CFG.Colors.Protect)

    MakeToggle(ProtectPanel, "Fullbright", false, function(on)
        State.Fullbright = on
        SetFullbright(on)
    end, CFG.Colors.Protect)

    SectionLabel(ProtectPanel, "Anti Troll", CFG.Colors.Protect)

    MakeButton(ProtectPanel, "Anti-Fling (Reset Velocity)", function()
        local root = GetRoot()
        if root then root.Velocity = Vector3.zero end
        Notify("Kaelen", "Velocity reset", 2)
    end, CFG.Colors.Protect)

    MakeButton(ProtectPanel, "Unanchor Self", function()
        local char = GetChar()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.Anchored = false end
            end
        end
        Notify("Kaelen", "Unanchored", 2)
    end, CFG.Colors.Protect)

    MakeButton(ProtectPanel, "Respawn", function()
        LocalPlayer:LoadCharacter()
    end, CFG.Colors.AccentRed)

    SectionLabel(ProtectPanel, "My Size", CFG.Colors.AccentOrange)
    MakeSlider(ProtectPanel, "My Size", 0.1, 10, 1, function(v)
        SetSize(LocalPlayer, v)
    end, CFG.Colors.AccentOrange)
    MakeButton(ProtectPanel, "Normal Size", function() SetSize(LocalPlayer, 1) end, CFG.Colors.AccentOrange)
end

-- UTILITIES PANEL
local UtilPanel = MakePanel("Util")
do
    SectionLabel(UtilPanel, "Server", CFG.Colors.Util)

    MakeButton(UtilPanel, "Rejoin Server", function()
        local tp = game:GetService("TeleportService")
        tp:Teleport(game.PlaceId, LocalPlayer)
    end, CFG.Colors.Util)

    MakeButton(UtilPanel, "Server Hop", function()
        local tp = game:GetService("TeleportService")
        local ok, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if ok and servers and servers.data then
            for _, s in ipairs(servers.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    tp:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        Notify("Kaelen", "No other servers found, rejoining...", 3)
        tp:Teleport(game.PlaceId, LocalPlayer)
    end, CFG.Colors.Util)

    SectionLabel(UtilPanel, "Chat & Spam", CFG.Colors.Util)
    local chatInput, chatBox = MakeInput(UtilPanel, "Message to send...", nil, CFG.Colors.Util)

    MakeButton(UtilPanel, "Chat Message", function()
        local text = chatBox.Text
        if text and text ~= "" then
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") and
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest") and
            game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(text, "All")
        end
    end, CFG.Colors.Util)

    SectionLabel(UtilPanel, "Lighting Tricks", CFG.Colors.AccentPink)
    MakeSlider(UtilPanel, "Clock Time", 0, 24, 14, function(v)
        Lighting.ClockTime = v
    end, CFG.Colors.AccentPink)

    MakeButton(UtilPanel, "Night Mode", function()
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
    end, Color3.fromRGB(30,30,80))

    MakeButton(UtilPanel, "Day Mode", function()
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
    end, Color3.fromRGB(255,200,60))

    SectionLabel(UtilPanel, "Workspace", CFG.Colors.Util)
    MakeSlider(UtilPanel, "Gravity", 0, 300, 196, function(v)
        workspace.Gravity = v
    end, CFG.Colors.Util)

    MakeButton(UtilPanel, "Zero Gravity", function()
        workspace.Gravity = 5
        Notify("Kaelen", "Zero-G mode!", 2)
    end, CFG.Colors.Accent2)
    MakeButton(UtilPanel, "Normal Gravity", function()
        workspace.Gravity = 196
    end, CFG.Colors.Accent)
    MakeButton(UtilPanel, "Moon Gravity", function()
        workspace.Gravity = 30
        Notify("Kaelen", "Moon Gravity!", 2)
    end, Color3.fromRGB(180,180,255))

    SectionLabel(UtilPanel, "Info", CFG.Colors.TextDim)
    local infoLbl = Label(UtilPanel, "Voice changer: Roblox does not allow\nclient-side voice pitch modification.\nThat feature requires a PC app like\nVoiceMod outside of Roblox.", 12, CFG.Colors.TextDim, Enum.Font.Gotham)
    infoLbl.Size = UDim2.new(1,0,0,70)
    infoLbl.TextWrapped = true
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    Padding(infoLbl, 0,0,10,0)
end

-- ESP PANEL
local ESPPanel = MakePanel("ESP")
do
    SectionLabel(ESPPanel, "Player Highlight ESP", CFG.Colors.Accent2)

    MakeToggle(ESPPanel, "ESP (SelectionBox)", false, function(on)
        State.ESPEnabled = on
        UpdateESP(on)
    end, CFG.Colors.Accent2)

    MakeToggle(ESPPanel, "Chams (Through Walls)", false, function(on)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, v in pairs(p.Character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CastShadow = not on
                    end
                end
            end
        end
    end, CFG.Colors.Accent2)

    SectionLabel(ESPPanel, "Player Info", CFG.Colors.Accent2)

    local function RefreshPlayerList()
        for _, child in pairs(ESPPanel:GetChildren()) do
            if child.Name == "PlayerCard" then child:Destroy() end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            local card = Frame(ESPPanel, UDim2.new(1,0,0,60), nil, CFG.Colors.Card, 0)
            card.Name = "PlayerCard"
            Corner(card)
            Stroke(card, CFG.Colors.Border, 1)

            local nameL = Label(card, p.Name, 13, CFG.Colors.Text, Enum.Font.GothamBold)
            nameL.Size = UDim2.new(0.6,0,0,24)
            nameL.Position = UDim2.new(0,10,0,6)

            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local myRoot = GetRoot()

            local dist = "??m"
            if root and myRoot then
                dist = math.floor((root.Position - myRoot.Position).Magnitude).."m"
            end
            local hp = hum and math.floor(hum.Health) or "?"
            local maxHp = hum and math.floor(hum.MaxHealth) or "?"

            local infoL = Label(card, "HP: "..hp.."/"..maxHp.." | Dist: "..dist, 11, CFG.Colors.TextDim, Enum.Font.Gotham)
            infoL.Size = UDim2.new(0.6,0,0,18)
            infoL.Position = UDim2.new(0,10,0,30)

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0,58,0,36)
            tpBtn.Position = UDim2.new(1,-66,0.5,-18)
            tpBtn.BackgroundColor3 = CFG.Colors.Accent
            tpBtn.BackgroundTransparency = 0.2
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.new(1,1,1)
            tpBtn.TextSize = 12
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.BorderSizePixel = 0
            tpBtn.Parent = card
            Corner(tpBtn, UDim.new(0,10))
            tpBtn.MouseButton1Click:Connect(function()
                local myR = GetRoot()
                local tR = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if myR and tR then myR.CFrame = tR.CFrame * CFrame.new(0,0,4) end
            end)
        end
    end

    MakeButton(ESPPanel, "Refresh Player List", RefreshPlayerList, CFG.Colors.Accent2)
    RefreshPlayerList()

    Players.PlayerAdded:Connect(RefreshPlayerList)
    Players.PlayerRemoving:Connect(RefreshPlayerList)
end

-- ============================================================
--  WINDOW OPEN / CLOSE
-- ============================================================
local OpenWindow, CloseWindow, ToggleMinimize

OpenWindow = function()
    State.IsOpen = true
    MainFrame.Visible = true
    Tween(MainFrame, {Size=CFG.FrameSize, BackgroundTransparency=0.08}, CFG.AnimSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(FloatBtn, {BackgroundTransparency=0.3}, 0.2)
    SetTab(State.CurrentTab)
end

CloseWindow = function()
    State.IsOpen = false
    Tween(MainFrame, {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1}, CFG.AnimSpeed, Enum.EasingStyle.Quart)
    Tween(FloatBtn, {BackgroundTransparency=0}, 0.2)
    task.wait(CFG.AnimSpeed)
    if not State.IsOpen then MainFrame.Visible = false end
end

ToggleMinimize = function()
    State.IsMinimized = not State.IsMinimized
    if State.IsMinimized then
        Tween(MainFrame, {Size=UDim2.new(CFG.FrameSize.X.Scale,0,0,56)}, 0.3)
    else
        Tween(MainFrame, {Size=CFG.FrameSize}, CFG.AnimSpeed, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
end

-- ============================================================
--  FLOAT BUTTON INTERACTION
-- ============================================================
local btnDragging = false
local btnDragDist = 0
local btnDragStart, btnStartPos

FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragDist = 0
        btnDragStart = inp.Position
        btnStartPos  = FloatBtn.Position
    end
end)

FloatBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        if btnDragDist < 12 then
            if State.IsOpen then CloseWindow() else OpenWindow() end
        end
        btnDragging = false
        btnDragDist = 0
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if btnDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - btnDragStart
        btnDragDist = math.abs(delta.X) + math.abs(delta.Y)
        local vp = Camera.ViewportSize
        local nx = math.clamp(btnStartPos.X.Offset + delta.X, 0, vp.X - 72)
        local ny = math.clamp(btnStartPos.Y.Offset + delta.Y, 0, vp.Y - 72)
        FloatBtn.Position = UDim2.new(0, nx, 0, ny)
    end
end)

-- ============================================================
--  KEYBOARD SHORTCUT (PC)
-- ============================================================
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightBracket then
        if State.IsOpen then CloseWindow() else OpenWindow() end
    end
end)

-- ============================================================
--  CHARACTER RESPAWN HANDLER
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if State.WalkSpeed ~= 16 then hum.WalkSpeed = State.WalkSpeed end
        if State.JumpPower ~= 50 then hum.JumpPower = State.JumpPower end
    end
    if State.InfJump then SetInfJump(true) end
    if State.NoclipEnabled then StartNoclip() end
    if State.FlyEnabled then task.wait(0.5) StartFly() end
    if State.GodMode then SetGodMode(true) end
end)

-- ============================================================
--  INIT
-- ============================================================
SetTab("Troll")

-- Startup notification
task.wait(0.5)
Notify("Kaelen Hub", "Loaded! Tap K button to open | ] to toggle", 4)

print("╔══════════════════════════════╗")
print("║      Kaelen Hub v1.0         ║")
print("║   by crx-ter | Delta Ready   ║")
print("╚══════════════════════════════╝")
print("[Kaelen] Features: Troll | Move | Music ("..#SONGS.." songs) | Protect | ESP | Util")
print("[Kaelen] Tap the K button or press ] to open")
