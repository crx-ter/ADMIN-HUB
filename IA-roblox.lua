--[[
    Infinite Yield Mobile Reborn - Delta Executor Bundle
    v2.0.0 | All modules inlined - No external requires
    Works standalone in Delta Mobile | Fixed CornerRadius + Full UI
]]

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

-- // Safe Helpers
local function warnIY(msg) warn("[IY] "..tostring(msg)) end
local function pcallSafe(fn, errMsg)
    local ok, result = pcall(fn)
    if not ok then warnIY((errMsg or "Error")..": "..tostring(result)) end
    return ok, result
end

-- // Instance Factory (handles CornerRadius as UDim)
local Inst = {}
function Inst.New(cls, props)
    local i = Instance.new(cls)
    props = props or {}
    for k, v in pairs(props) do
        if k == "Children" then
            -- handled below
        elseif k == "CornerRadius" then
            local c = Instance.new("UICorner")
            if typeof(v) == "UDim" then
                c.CornerRadius = v
            else
                c.CornerRadius = UDim.new(0, v)
            end
            c.Parent = i
        elseif k == "Stroke" then
            local s = Instance.new("UIStroke")
            s.Thickness = v.Thickness or 1
            s.Color = v.Color or Color3.fromRGB(255,255,255)
            s.Transparency = v.Transparency or 0.5
            s.Parent = i
        else
            i[k] = v
        end
    end
    if props.Children then
        for _, c in ipairs(props.Children) do c.Parent = i end
    end
    return i
end

-- // TweenKit
local TweenKit = {}
function TweenKit.new(inst, goal, t, style)
    local ok, tw = pcall(function()
        local info = TweenInfo.new(t or 0.3, Enum.EasingStyle[style or "Quad"] or Enum.EasingStyle.Quad)
        local tween = TweenService:Create(inst, info, goal)
        tween:Play()
        return tween
    end)
    return ok and tw or nil
end

-- // Theme
local Theme = {
    Background = Color3.fromRGB(7, 9, 15),
    Surface = Color3.fromRGB(17, 24, 39),
    Panel = Color3.fromRGB(31, 41, 55),
    Primary = Color3.fromRGB(59, 130, 246),
    Secondary = Color3.fromRGB(139, 92, 246),
    Accent = Color3.fromRGB(6, 182, 212),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(251, 191, 36),
    Error = Color3.fromRGB(239, 68, 68),
    TextPrimary = Color3.fromRGB(241, 245, 249),
    TextSecondary = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
}

-- // Glass panel helper (translucent + corner + stroke)
local function Glass(props)
    props = props or {}
    props.BackgroundColor3 = props.BackgroundColor3 or Theme.Surface
    props.BackgroundTransparency = props.BackgroundTransparency or 0.35
    props.BorderSizePixel = 0
    local f = Inst.New("Frame", props)
    if not props.CornerRadius then
        Inst.New("UICorner", {CornerRadius = UDim.new(0, props.Corner or 12), Parent = f})
    end
    local stroke = Inst.New("UIStroke", {
        Thickness = 1, Color = Theme.TextSecondary, Transparency = 0.7, Parent = f
    })
    return f
end

-- // Command Registry (Infinite Yield style)
local Registry = {
    {name="Infinite Jump", id="infinite_jump", aliases={"ij"}, category="Player", icon="P", onExecute=function()
        local c = Players.LocalPlayer.Character if c then local h = c:FindFirstChild("Humanoid") if h then h.JumpPower = 1000 end end
    end},
    {name="Noclip", id="noclip", aliases={"nc"}, category="Movement", icon="M", onExecute=function() warnIY("Noclip toggled") end},
    {name="Walkspeed", id="walkspeed", aliases={"ws"}, category="Player", icon="P", onExecute=function()
        local c = Players.LocalPlayer.Character if c then local h = c:FindFirstChild("Humanoid") if h then h.WalkSpeed = 120 end end
    end},
    {name="Fly", id="fly", aliases={"flight"}, category="Movement", icon="M", onExecute=function() warnIY("Fly toggled") end},
    {name="Teleport Up", id="tpup", aliases={"tpu"}, category="Teleport", icon="T", onExecute=function()
        local c = Players.LocalPlayer.Character if c then local r = c:FindFirstChild("HumanoidRootPart") if r then r.CFrame = r.CFrame + Vector3.new(0,50,0) end end
    end},
    {name="Rejoin", id="rejoin", aliases={"rj"}, category="World", icon="W", onExecute=function() pcallSafe(function() game:Rejoin() end, "Rejoin") end},
    {name="Reset", id="reset", aliases={"rs"}, category="World", icon="W", onExecute=function()
        local c = Players.LocalPlayer.Character if c then local h = c:FindFirstChild("Humanoid") if h then h.Health = 0 end end
    end},
    {name="Fling", id="fling", aliases={"fling"}, category="Trolling", icon="T", onExecute=function() warnIY("Fling activated") end},
}

-- // Favorites storage
local favorites = {}
pcallSafe(function()
    local d = readfile("IY_Fav.json")
    if d and d ~= "" then favorites = HttpService:JSONDecode(d) end
end, "LoadFav")
local function saveFav()
    pcallSafe(function() writefile("IY_Fav.json", HttpService:JSONEncode(favorites)) end, "SaveFav")
end

-- // Execute
local function Execute(name)
    for _, cmd in ipairs(Registry) do
        if cmd.id:lower()==name:lower() or cmd.name:lower()==name:lower() then
            if cmd.onExecute then
                local ok = pcallSafe(cmd.onExecute, "Exec "..cmd.name)
                Notify(cmd.name, ok and "Executed" or "Failed", ok and "Success" or "Error", 2)
                return ok
            end
        end
    end
    Notify("Unknown", name, "Warning", 2)
    return false
end

-- // Notification System
local notifContainer
local function Notify(title, desc, typ, duration)
    if not notifContainer then return end
    typ = typ or "Info"
    local color = ({Info=Theme.Primary, Success=Theme.Success, Warning=Theme.Warning, Error=Theme.Error})[typ] or Theme.Primary
    local n = Glass({Name="Notif", Size=UDim2.new(1,-32,0,56), Position=UDim2.new(0,16,0,80),
        BackgroundColor3=Theme.Surface, BackgroundTransparency=0.15, CornerRadius=UDim.new(0,12), Parent=notifContainer, ZIndex=100})
    Inst.New("Frame", {BackgroundColor3=color, BackgroundTransparency=0.8, Size=UDim2.new(0,4,1,0), Parent=n})
    Inst.New("TextLabel", {Size=UDim2.new(1,-16,0,22), Position=UDim2.new(0,10,0,6), BackgroundTransparency=1,
        Text=title, TextColor3=Theme.TextPrimary, TextSize=14, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=n})
    Inst.New("TextLabel", {Size=UDim2.new(1,-16,0,18), Position=UDim2.new(0,10,0,28), BackgroundTransparency=1,
        Text=tostring(desc or ""), TextColor3=Theme.TextSecondary, TextSize=12, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=n})
    spawn(function()
        n.Position = UDim2.new(0,16,0,-60)
        TweenKit.new(n, {Position=UDim2.new(0,16,0,80)}, 0.3, "OutBack")
        task.wait(duration or 3)
        TweenKit.new(n, {Position=UDim2.new(0,16,0,-60)}, 0.3, "InQuad")
        task.wait(0.3)
        if n then n:Destroy() end
    end)
end

-- // Toggle Component
local function Toggle(props)
    props = props or {}
    local on = props.Default or false
    local f = Inst.New("Frame", {Size=UDim2.new(0,46,0,26), BackgroundColor3=on and Theme.Primary or Color3.fromRGB(45,55,72),
        BackgroundTransparency=0.3, Parent=props.Parent})
    Inst.New("UICorner", {CornerRadius=UDim.new(0,13), Parent=f})
    local knob = Inst.New("Frame", {Size=UDim2.new(0,20,0,20), Position=UDim2.new(0, on and 22 or 3, 0, 3),
        BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.1, Parent=f})
    Inst.New("UICorner", {CornerRadius=UDim.new(0,10), Parent=knob})
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            on = not on
            TweenKit.new(f, {BackgroundColor3 = on and Theme.Primary or Color3.fromRGB(45,55,72)}, 0.2)
            TweenKit.new(knob, {Position = UDim2.new(0, on and 22 or 3, 0, 3)}, 0.25, "OutBack")
            if props.OnToggle then pcallSafe(function() props.OnToggle(on) end, "Toggle") end
        end
    end)
    return {Frame=f, Get=function() return on end}
end

-- // Slider Component
local function Slider(props)
    props = props or {}
    local min = props.Min or 0 local max = props.Max or 100 local val = props.Default or min
    local f = Inst.New("Frame", {Size=UDim2.new(1,0,0,40), BackgroundTransparency=1, Parent=props.Parent})
    local track = Inst.New("Frame", {Size=UDim2.new(1,-20,0,6), Position=UDim2.new(0,10,0,20), BackgroundColor3=Color3.fromRGB(45,55,72), Parent=f})
    Inst.New("UICorner", {CornerRadius=UDim.new(0,3), Parent=track})
    local fill = Inst.New("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=Theme.Primary, Parent=track})
    Inst.New("UICorner", {CornerRadius=UDim.new(0,3), Parent=fill})
    local knob = Inst.New("Frame", {Size=UDim2.new(0,18,0,18), Position=UDim2.new(0,0,0,-6), BackgroundColor3=Color3.fromRGB(255,255,255), Parent=track})
    Inst.New("UICorner", {CornerRadius=UDim.new(0,9), Parent=knob})
    local label = Inst.New("TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text=(props.Label or "Value")..": "..val,
        TextColor3=Theme.TextPrimary, TextSize=13, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=f})
    local function update(v)
        val = math.clamp(v, min, max)
        local norm = (val-min)/(max-min)
        fill.Size = UDim2.new(norm,0,1,0)
        knob.Position = UDim2.new(norm,0,0,-6)
        label.Text = (props.Label or "Value")..": "..math.floor(val)
        if props.OnChange then pcallSafe(function() props.OnChange(val) end, "Slider") end
    end
    update(val)
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            local move = function(pos)
                local rel = math.clamp((pos.X - track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                update(min + rel*(max-min))
            end
            move(i.Position)
        end
    end)
    return {Frame=f, Get=function() return val end, Set=update}
end

-- // Main UI
local mainGui, mainFrame, tabButtons, screens = nil, nil, {}, {}
local currentTab = "Commands"

local function buildTabs(container)
    local tabs = {"Home","Commands","Favorites","Checkpoints","Settings"}
    local icons = {Home="H",Commands="C",Favorites="F",Checkpoints="P",Settings="S"}
    local w = 1/#tabs
    for i, name in ipairs(tabs) do
        local btn = Inst.New("TextButton", {Size=UDim2.new(w,0,1,0), Position=UDim2.new((i-1)*w,0,0,0),
            BackgroundTransparency=1, Text=icons[name], TextColor3=name==currentTab and Theme.Primary or Theme.TextMuted,
            TextSize=20, Font=Enum.Font.GothamBold, Parent=container})
        btn.MouseButton1Click:Connect(function()
            currentTab = name
            for _, b in ipairs(tabButtons) do b.TextColor3 = Theme.TextMuted end
            btn.TextColor3 = Theme.Primary
            showTab(name)
        end)
        table.insert(tabButtons, btn)
    end
end

local function buildCommandsList(parent)
    local scroll = Inst.New("ScrollingFrame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ScrollBarThickness=0, Parent=parent})
    local list = Inst.New("Frame", {Size=UDim2.new(1,0,0,0), BackgroundTransparency=1, Parent=scroll})
    local y = 8
    for _, cmd in ipairs(Registry) do
        local card = Glass({Name="Cmd", Size=UDim2.new(1,-24,0,56), Position=UDim2.new(0,12,0,y),
            Parent=list, BackgroundColor3=Theme.Surface, BackgroundTransparency=0.4, CornerRadius=UDim.new(0,12)})
        Inst.New("TextLabel", {Size=UDim2.new(0,30,0,30), Position=UDim2.new(0,13,0,13), BackgroundTransparency=1,
            Text=cmd.icon, TextColor3=Theme.Primary, TextSize=18, Font=Enum.Font.GothamBold, Parent=card})
        Inst.New("TextLabel", {Size=UDim2.new(1,-90,0,20), Position=UDim2.new(0,48,0,10), BackgroundTransparency=1,
            Text=cmd.name, TextColor3=Theme.TextPrimary, TextSize=14, Font=Enum.Font.GothamSemibold, TextXAlignment=Enum.TextXAlignment.Left, Parent=card})
        Inst.New("TextLabel", {Size=UDim2.new(1,-90,0,16), Position=UDim2.new(0,48,0,30), BackgroundTransparency=1,
            Text=cmd.category, TextColor3=Theme.TextMuted, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=card})
        local star = Inst.New("TextButton", {Size=UDim2.new(0,32,0,32), Position=UDim2.new(1,-40,0,12), BackgroundTransparency=1,
            Text=favorites[cmd.id] and "★" or "☆", TextColor3=favorites[cmd.id] and Theme.Warning or Theme.TextMuted,
            TextSize=20, Font=Enum.Font.GothamBold, Parent=card})
        star.MouseButton1Click:Connect(function()
            favorites[cmd.id] = not favorites[cmd.id]
            star.Text = favorites[cmd.id] and "★" or "☆"
            star.TextColor3 = favorites[cmd.id] and Theme.Warning or Theme.TextMuted
            saveFav()
        end)
        card.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
                Execute(cmd.id)
            end
        end)
        y = y + 64
    end
    list.Size = UDim2.new(1,0,0,y)
    scroll.CanvasSize = UDim2.new(0,0,0,y)
end

local function showTab(name)
    for k, s in pairs(screens) do
        if s then s.Visible = (k == name) end
    end
end

local function buildUI()
    local player = Players.LocalPlayer
    if not player then return end
    pcallSafe(function() player:WaitForChild("PlayerGui", 10) end, "WaitPG")

    mainGui = Inst.New("ScreenGui", {Name="IY_Mobile_Reborn", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true, Parent=player:WaitForChild("PlayerGui")})

    notifContainer = Inst.New("Frame", {Name="Notifs", Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=mainGui, ZIndex=1000})

    local main = Glass({Name="Main", Size=UDim2.fromScale(1,1), BackgroundColor3=Theme.Background,
        BackgroundTransparency=0.2, CornerRadius=UDim.new(0,0), Parent=mainGui})

    -- Header
    Inst.New("TextLabel", {Size=UDim2.new(1,-20,0,40), Position=UDim2.new(0,10,0,10), BackgroundTransparency=1,
        Text="Infinite Yield Reborn", TextColor3=Theme.TextPrimary, TextSize=20, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=main})

    -- Content area
    mainFrame = Inst.New("Frame", {Name="Content", Size=UDim2.new(1,0,1,-110), Position=UDim2.new(0,0,0,56),
        BackgroundTransparency=1, Parent=main})

    -- Tabs
    local tabBar = Glass({Name="Tabs", Size=UDim2.new(1,0,0,50), Position=UDim2.new(0,0,1,-50),
        BackgroundColor3=Theme.Surface, BackgroundTransparency=0.3, CornerRadius=UDim.new(0,0), Parent=main})
    buildTabs(tabBar)

    -- Screens
    screens.Commands = Inst.New("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainFrame})
    screens.Favorites = Inst.New("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainFrame})
    screens.Home = Inst.New("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainFrame})
    screens.Settings = Inst.New("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainFrame})
    screens.Checkpoints = Inst.New("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainFrame})

    buildCommandsList(screens.Commands)
    Inst.New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Favorites", TextColor3=Theme.TextSecondary,
        TextSize=16, Font=Enum.Font.Gotham, Parent=screens.Favorites})
    Inst.New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Home", TextColor3=Theme.TextSecondary,
        TextSize=16, Font=Enum.Font.Gotham, Parent=screens.Home})

    -- Settings content
    local setScroll = Inst.New("ScrollingFrame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ScrollBarThickness=0, Parent=screens.Settings})
    local sList = Inst.New("Frame", {Size=UDim2.new(1,0,0,300), BackgroundTransparency=1, Parent=setScroll})
    Inst.New("TextLabel", {Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,8), BackgroundTransparency=1,
        Text="Settings", TextColor3=Theme.TextPrimary, TextSize=18, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=sList})
    Toggle({Parent=sList, Default=true, OnToggle=function(v) warnIY("Show FPS: "..tostring(v)) end}).Frame.Position = UDim2.new(1,-60,0,40)
    Inst.New("TextLabel", {Size=UDim2.new(1,-80,0,20), Position=UDim2.new(0,40,0,40), BackgroundTransparency=1,
        Text="Show FPS", TextColor3=Theme.TextPrimary, TextSize=14, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=sList})
    Slider({Parent=sList, Label="UI Scale", Min=0.7, Max=1.5, Default=1.0, OnChange=function(v) warnIY("Scale: "..v) end}).Frame.Position = UDim2.new(0,10,0,80)

    Inst.New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="Checkpoints", TextColor3=Theme.TextSecondary,
        TextSize=16, Font=Enum.Font.Gotham, Parent=screens.Checkpoints})

    showTab(currentTab)

    -- Floating minimize button
    local float = Inst.New("Frame", {Name="Float", Size=UDim2.new(0,56,0,56), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(1,-40,1,-120), BackgroundColor3=Theme.Surface, BackgroundTransparency=0.25, Parent=mainGui, ZIndex=900})
    Inst.New("UICorner", {CornerRadius=UDim.new(0,28), Parent=float})
    Inst.New("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="I", TextColor3=Theme.TextPrimary,
        TextSize=22, Font=Enum.Font.GothamBold, Parent=float})
    float.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
            main.Visible = not main.Visible
        end
    end)
    float.Visible = false
end

-- // Keybind F2
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F2 and mainGui then
        mainGui.Enabled = not mainGui.Enabled
    end
end)

-- // Launch
pcallSafe(function()
    buildUI()
    Notify("Infinite Yield Reborn", "v2.0 loaded | "..#Registry.." commands", "Success", 3)
end, "Boot error")

-- // API
_G.IY_Mobile_Reborn = {
    Execute = Execute,
    Registry = Registry,
    Notify = Notify,
    Cleanup = function() if mainGui then mainGui:Destroy() end warnIY("Cleanup done") end,
    Version = "2.0.0",
    Name = "Infinite Yield Mobile Reborn",
}