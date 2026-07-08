--[[
    Infinite Yield Mobile Reborn - Delta Executor Bundle
    v2.0.0 | All modules inlined - No external requires
    Works standalone in Delta Mobile
]]

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

-- // Helper Functions
local function warnIY(msg) warn("[IY] "..tostring(msg)) end

local function pcallSafe(fn, errMsg)
    local ok, result = pcall(fn)
    if not ok then warnIY(errMsg..": "..tostring(result)) end
    return ok, result
end

-- // Observer Pattern (inline)
local Signal = {}
Signal.__index = Signal
function Signal.new()
    local self = setmetatable({_connections = {}, _id = 0}, Signal)
    return self
end
function Signal:Connect(cb)
    self._id = self._id + 1
    local conn = {Id = self._id, Callback = cb, Connected = true}
    table.insert(self._connections, conn)
    return conn
end
function Signal:Fire(...)
    for i = #self._connections, 1, -1 do
        local c = self._connections[i]
        if c.Connected then
            pcall(c.Callback, ...)
        else
            table.remove(self._connections, i)
        end
    end
end
function Signal:Destroy()
    self._connections = nil
end

local Observer = {}
Observer.__index = Observer
function Observer.new(data)
    return setmetatable({_data = data or {}, _signals = {}}, Observer)
end
function Observer:_getSig(k)
    if not self._signals[k] then self._signals[k] = Signal.new() end
    return self._signals[k]
end
function Observer:Set(k, v)
    self._data[k] = v
    if self._signals[k] then self._signals[k]:Fire(v, nil) end
end
function Observer:Get(k) return self._data[k] end
function Observer:Watch(k, cb) return self:_getSig(k):Connect(cb) end
function Observer:Destroy()
    for _, s in pairs(self._signals) do s:Destroy() end
    self._signals = nil
end

-- // Theme
local Theme = {
    Background = Color3.fromRGB(7, 9, 15),
    Surface = Color3.fromRGB(17, 24, 39),
    Primary = Color3.fromRGB(59, 130, 246),
    Secondary = Color3.fromRGB(139, 92, 246),
    TextPrimary = Color3.fromRGB(241, 245, 249),
    TextSecondary = Color3.fromRGB(148, 163, 184),
}
function Theme.Get() return Theme end

-- // Instance Factory
local Inst = {}
function Inst.New(cls, props)
    local i = Instance.new(cls)
    for k, v in pairs(props or {}) do
        if k ~= "Children" then i[k] = v end
    end
    if props and props.Children then
        for _, c in ipairs(props.Children) do c.Parent = i end
    end
    return i
end

-- // TweenKit
local TweenKit = {}
function TweenKit.new(inst, goal, t, style)
    local info = TweenInfo.new(t or 0.3, Enum.EasingStyle[style] or Enum.EasingStyle.Quad)
    local tw = TweenService:Create(inst, info, goal)
    tw:Play()
    return {Tween = tw, Instance = inst}
end

-- // Utils
local Math = {}
function Math.Clamp(v, a, b) return math.max(a, math.min(b, v)) end
function Math.Round(v, d) local m = 10^(d or 0) return math.floor(v*m+0.5)/m end

-- // Icons (inline)
local Icons = {
    Home = "H", Commands = "C", Favorites = "F", Checkpoints = "P", Settings = "S",
    Player = "P", Movement = "M", Visual = "V", Teleport = "T", World = "W",
    Tools = "O", Utilities = "U", Console = "L", Search = "Q",
    Add = "+", Remove = "X", Teleport = "T", Rename = "R", Duplicate = "D",
}

-- // Categories Data
local Categories = {
    {id="player", name="Player", icon="P", color=Theme.Primary},
    {id="movement", name="Movement", icon="M", color=Color3.fromRGB(34,197,94)},
    {id="visual", name="Visual", icon="V", color=Theme.Secondary},
    {id="teleport", name="Teleport", icon="T", color=Color3.fromRGB(249,115,22)},
    {id="world", name="World", icon="W", color=Color3.fromRGB(6,182,212)},
    {id="tools", name="Tools", icon="O", color=Color3.fromRGB(234,179,8)},
    {id="utilities", name="Utilities", icon="U", color=Theme.Primary},
    {id="trolling", name="Trolling", icon="T", color=Color3.fromRGB(236,72,153)},
}

-- // Simple Command Registry (sample)
local Registry = {
    {name="Infinite Jump", aliases={"ij"}, id="infinite_jump", category="player", icon="P", onExecute=function()
        local char = Players.LocalPlayer.Character
        if char then local hum = char:FindFirstChild("Humanoid") if hum then hum.JumpPower = 1000 end end
    end},
    {name="Noclip", aliases={"nc"}, id="noclip", category="movement", icon="M", onExecute=function()
        warnIY("Noclip toggled")
    end},
    {name="Walkspeed", aliases={"ws"}, id="walkspeed", category="player", icon="P", onExecute=function()
        local char = Players.LocalPlayer.Character
        if char then local hum = char:FindFirstChild("Humanoid") if hum then hum.WalkSpeed = 120 end end
    end},
    {name="Fly", aliases={"flight"}, id="fly", category="movement", icon="M", onExecute=function()
        warnIY("Fly toggled")
    end},
    {name="Teleport", aliases={"tp"}, id="teleport", category="teleport", icon="T", onExecute=function()
        local char = Players.LocalPlayer.Character
        if char then local root = char:FindFirstChild("HumanoidRootPart") if root then root.CFrame = CFrame.new(0,100,0) end end
    end},
    {name="Rejoin", aliases={"rj"}, id="rejoin", category="world", icon="W", onExecute=function()
        game:Rejoin()
    end},
    {name="Server Hop", id="serverhop", category="world", icon="W", onExecute=function()
        warnIJ("Server hop requested")
    end},
}

-- // Execute Helper
local function Execute(cmdName)
    for _, cmd in ipairs(Registry) do
        if cmd.id:lower() == cmdName:lower() or cmd.name:lower() == cmdName:lower() then
            if cmd.onExecute then
                local ok = pcallSafe(cmd.onExecute, "Execute error for "..cmd.name)
                return ok
            end
        end
    end
    warnIJ("Command not found: "..cmdName)
    return false
end

-- // Notification System
local notifContainer
local function Notify(title, desc, typ, duration)
    if not notifContainer then return end
    typ = typ or "Info"
    local colors = {Info=Theme.Primary, Success=Color3.fromRGB(34,197,94), Warning=Color3.fromRGB(251,191,36), Error=Color3.fromRGB(239,68,68)}
    local n = Inst.New("Frame", {
        Name="Notif", Size=UDim2.new(0,300,0,60),
        Position=UDim2.new(0,16,0,100), BackgroundTransparency=1, Parent=notifContainer
    })
    local bg = Inst.New("Frame", {BackgroundColor3=Theme.Surface, BackgroundTransparency=0.2, Size=UDim2.fromScale(1,1), Parent=n})
    local txt = Inst.New("TextLabel", {
        Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1,
        Text=title.." – "..(desc or ""), TextColor3=Theme.TextPrimary, TextSize=14, TextWrapped=true, Parent=n
    })
    spawn(function()
        TweenKit.new(bg, {BackgroundTransparency=0.1}, 0.2)
        task.wait(duration or 3)
        TweenKit.new(bg, {BackgroundTransparency=1}, 0.2)
        task.wait(0.3)
        if n then n:Destroy() end
    end)
end

-- // Floating Button
local Floating = {}
Floating.__index = Floating
function Floating.new(parent, onOpen, onClose)
    local self = setmetatable({}, Floating)
    self._frame = Inst.New("Frame", {
        Name="FloatingBtn", Size=UDim2.new(0,56,0,56), AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(1,-72,1,-140), BackgroundTransparency=0.25, BackgroundColor3=Theme.Surface, Parent=parent
    })
    local corner = Inst.New("UICorner", {CornerRadius=28, Parent=self._frame})
    local icon = Inst.New("TextLabel", {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="I", TextColor3=Theme.TextPrimary,
        TextSize=22, Font=Enum.Font.GothamBold, Parent=self._frame
    })
    self._open = false
    self._onOpen = onOpen
    self._onClose = onClose
    
    self._frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            if self._open then
                if self._onClose then self._onClose() end
            else
                if self._onOpen then self._onOpen() end
            end
            self._open = not self._open
        end
    end)
    return self
end
function Floating:Destroy() if self._frame then self._frame:Destroy() end end

-- // Main UI Container
local mainGui
local mainFrame
local navBar
local router

local function buildUI()
    local player = Players.LocalPlayer
    if not player then return end
    
    mainGui = Inst.New("ScreenGui", {
        Name="IY_Mobile_Reborn", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        Parent=player:WaitForChild("PlayerGui", 10)
    })
    
    notifContainer = Inst.New("Frame", {Name="Notifs", Size=UDim2.new(0,320,1,0), BackgroundTransparency=1, Parent=mainGui, ZIndex=1000})
    
    local main = Inst.New("Frame", {
        Name="Main", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainGui
    })
    mainFrame = Inst.New("Frame", {
        Name="Content", Size=UDim2.new(1,0,1,-60), BackgroundTransparency=1, Parent=main
    })
    navBar = Inst.New("Frame", {
        Name="NavBar", Size=UDim2.new(1,0,0,60), Position=UDim2.new(0,0,1,0), BackgroundTransparency=1, Parent=main
    })
    
    -- Home content (minimal)
    local home = Inst.New("Frame", {Name="Home", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Parent=mainFrame})
    Inst.New("TextLabel", {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="Infinite Yield Mobile Reborn",
        TextColor3=Theme.TextPrimary, TextSize=24, Font=Enum.Font.GothamBold, Parent=home
    })
    
    -- Floating button
    Floating.new(mainGui, function()
        main.Visible = true
        TweenKit.new(main, {BackgroundTransparency=0}, 0.3, "OutQuad")
    end, function()
        TweenKit.new(main, {BackgroundTransparency=1}, 0.25)
        task.delay(0.3, function() if main then main.Visible = false end end)
    end)
    
    main.Visible = false
end

-- // Keybind handler
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.F2 then
        if mainGui then
            mainGui.Enabled = not mainGui.Enabled
        end
    end
end)

-- // Bootstrap
pcallSafe(function()
    buildUI()
    Notify("Infinite Yield Mobile", "v2.0 loaded", "Info", 3)
end, "Boot error")

-- // Public API
_G.IY_Mobile_Reborn = {
    Execute = Execute,
    Registry = Registry,
    Notify = Notify,
    Cleanup = function()
        if mainGui then mainGui:Destroy() end
        warnIJ("Cleanup complete")
    end,
    Version = "2.0.0",
    Name = "Infinite Yield Mobile Reborn"
}