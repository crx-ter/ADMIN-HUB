--[[
    Infinite Yield Mobile Reborn
    Premium Admin Tool para Delta Executor (Android)
    Arquitectura: Observer reactivo + Glassmorphism + TweenKit
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Core
local Signal = require(script.core.signal)
local Observer = require(script.core.observer)
local TweenKit = require(script.core.tween)
local Throttle = require(script.core.throttle)
local Theme = require(script.core.theme)

-- Utils
local InstanceUtils = require(script.utils.instance)
local MathUtils = require(script.utils.math)
local TableUtils = require(script.utils.table)

-- UI Primitives
local Glass = require(script.ui.primitives.glass)
local Gradient = require(script.ui.primitives.gradient)

-- UI Components
local Button = require(script.ui.components.Button)
local Toggle = require(script.ui.components.Toggle)
local Slider = require(script.ui.components.Slider)
local TextBox = require(script.ui.components.TextBox)
local Dropdown = require(script.ui.components.Dropdown)
local ColorPicker = require(script.ui.components.ColorPicker)
local SearchBar = require(script.ui.components.SearchBar)
local Notification = require(script.ui.components.Notification)
local Dialog = require(script.ui.components.Dialog)
local FloatingButton = require(script.ui.components.FloatingButton)
local Card = require(script.ui.components.Card)
local Section = require(script.ui.components.Section)
local Keybind = require(script.ui.components.Keybind)
local ContextMenu = require(script.ui.components.ContextMenu)
local Tooltip = require(script.ui.components.Tooltip)

-- Navigation & Layout
local Router = require(script.ui.navigation.Router)
local NavBar = require(script.ui.navigation.NavBar)
local Responsive = require(script.ui.layout.Responsive)
local ScreenContainer = require(script.ui.layout.ScreenContainer)

-- Screens
local HomeScreen = require(script.ui.screens.Home)
local CommandsScreen = require(script.ui.screens.Commands)
local FavoritesScreen = require(script.ui.screens.Favorites)
local CheckpointsScreen = require(script.ui.screens.Checkpoints)
local SettingsScreen = require(script.ui.screens.Settings)

-- Features
local Registry = require(script.features.commands.Registry)
local Categories = require(script.features.commands.Categories)
local CheckpointService = require(script.services.CheckpointService)
local RecentActivity = require(script.services.RecentActivity)
local SettingsStore = require(script.features.settings.Store)
local Sandbox = require(script.features.executor.Sandbox)

-- ─── BOOT ───────────────────────────────────────────────

local Player = Players.LocalPlayer
local ScreenGui = InstanceUtils.MakeScreenGui("IYMobileReborn")
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

-- Theme global
local theme = Theme.GetGlobal()

-- Settings Store
local settingsStore = SettingsStore.new()
_G.IY_SettingsStore = settingsStore

-- Checkpoint Service
local checkpointService = CheckpointService.new()
_G.IY_Checkpoints = checkpointService

-- Recent Activity
local recentActivity = RecentActivity.new()

-- ─── NOTIFICATION CONTAINER ─────────────────────────────

local notifContainer = InstanceUtils.New("Frame", {
    Name = "NotificationContainer",
    Size = UDim2.new(0, 320, 1, 0),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = ScreenGui,
    ZIndex = 1000,
})
Notification.SetContainer(notifContainer)

-- ─── MAIN UI CONTAINER ──────────────────────────────────

local mainContainer = ScreenContainer.new(ScreenGui, {
    Name = "MainContainer",
})

local mainFrame = InstanceUtils.New("Frame", {
    Name = "MainFrame",
    Size = UDim2.new(1, 0, 1, -64),
    Position = UDim2.fromOffset(0, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = mainContainer,
})

local navArea = InstanceUtils.New("Frame", {
    Name = "NavArea",
    Size = UDim2.new(1, 0, 0, 64),
    Position = UDim2.new(0, 0, 1, 0),
    BackgroundTransparency = 1,
    Parent = mainContainer,
})

-- ─── APP STATE ──────────────────────────────────────────

local appState = Observer.new({
    currentScreen = "Home",
    favorites = {},
    checkpoints = {},
    recentCommands = {},
    fps = 0,
    ping = 0,
    playerName = Player and Player.Name or "Player",
    displayName = Player and Player.DisplayName or "@player",
})

-- Load favorites
local loadFavorites = function()
    local success, data = pcall(function() return readfile("IY_Favorites.json") end)
    if success and data and data ~= "" then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(data) end)
        if ok and type(decoded) == "table" then
            appState:Set("favorites", decoded)
            return decoded
        end
    end
    return {}
end

local saveFavorites = function(favs)
    local data = HttpService:JSONEncode(favs)
    pcall(function() writefile("IY_Favorites.json", data) end)
end

local favorites = loadFavorites()

-- ─── COMMAND EXECUTION ──────────────────────────────────

local function executeCommand(cmdName)
    local cmd = Registry.GetByName(cmdName)
    if cmd then
        local success, err = pcall(function()
            if cmd.onExecute then
                cmd.onExecute()
            end
        end)
        if success then
            local catInfo = Categories.GetById(cmd.category)
            recentActivity:Add({
                Name = cmd.name,
                Icon = cmd.icon or (catInfo and catInfo.icon) or "C",
                Time = os.date("%I:%M"),
            })
            appState:Set("recentCommands", recentActivity:GetAll())
            Notification.Show({
                Title = cmd.name,
                Description = "Command executed",
                Type = "Success",
                Duration = 2,
            })
        else
            Notification.Show({
                Title = "Error",
                Description = cmd.name .. ": " .. tostring(err),
                Type = "Error",
                Duration = 3,
            })
        end
    else
        Notification.Show({
            Title = "Unknown Command",
            Description = cmdName .. " not found",
            Type = "Warning",
            Duration = 2,
        })
    end
end

-- ─── ROUTER ─────────────────────────────────────────────

local router = Router.new(mainFrame, {
    OnNavigate = function(name, index)
        appState:Set("currentScreen", name)
    end,
})

-- Screen builders
router:Register("Home", function(parent, params)
    local screen = HomeScreen.new(parent, {})
    local player = Players.LocalPlayer
    if player then
        pcall(function()
            screen._playerName.Text = player.Name
            screen._displayName.Text = "@" .. player.DisplayName
        end)
    end
    screen:SetFavorites(favorites)
    screen:SetRecentCommands(recentActivity:GetAll())

    -- FPS/Ping real-time updates
    local fpsCount = 0
    local fpsTime = 0
    local connFps = RunService.RenderStepped:Connect(function(dt)
        fpsCount = fpsCount + 1
        fpsTime = fpsTime + dt
        if fpsTime >= 1 then
            appState:Set("fps", math.floor(fpsCount / fpsTime))
            fpsCount = 0
            fpsTime = 0
        end
    end)
    spawn(function()
        while screen._destroyed == false do
            task.wait(1)
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            appState:Set("ping", ping)
        end
    end)

    return screen
end)

router:Register("Commands", function(parent, params)
    local screen = CommandsScreen.new(parent, {
        Commands = Registry.GetAll(),
        Favorites = favorites,
        OnToggleFavorite = function(cmdName, isFav)
            favorites[cmdName] = isFav or nil
            saveFavorites(favorites)
            appState:Set("favorites", favorites)
            local count = 0
            for _, v in pairs(favorites) do if v then count = count + 1 end end
            navBar:SetBadge(3, count > 0 and count or nil)
        end,
        OnExecute = function(cmdName)
            executeCommand(cmdName)
        end,
    })
    return screen
end)

router:Register("Favorites", function(parent, params)
    local screen = FavoritesScreen.new(parent, {
        Favorites = favorites,
        OnRemove = function(cmdName)
            favorites[cmdName] = nil
            saveFavorites(favorites)
            appState:Set("favorites", favorites)
            screen:SetFavorites(favorites)
            local count = 0
            for _, v in pairs(favorites) do if v then count = count + 1 end end
            navBar:SetBadge(3, count > 0 and count or nil)
        end,
        OnExecute = function(cmdName)
            executeCommand(cmdName)
        end,
    })
    return screen
end)

router:Register("Checkpoints", function(parent, params)
    local screen = CheckpointsScreen.new(parent, {
        Checkpoints = checkpointService:GetAll(),
        OnSave = function(name)
            local cp = checkpointService:Save(name)
            if cp then
                screen:SetCheckpoints(checkpointService:GetAll())
                Notification.Show({
                    Title = "Checkpoint Saved",
                    Description = cp.name,
                    Type = "Success",
                    Duration = 2,
                })
            end
        end,
        OnTeleport = function(cp)
            local player = Players.LocalPlayer
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local root = player.Character.HumanoidRootPart
                local pos = Vector3.new(cp.position.X, cp.position.Y, cp.position.Z)
                root.CFrame = CFrame.new(pos)
                Notification.Show({
                    Title = "Teleported",
                    Description = "To " .. (cp.name or "checkpoint"),
                    Type = "Info",
                    Duration = 2,
                })
            end
        end,
        OnUpdate = function(cp)
            checkpointService:Update(cp.id)
            screen:SetCheckpoints(checkpointService:GetAll())
            Notification.Show({Title = "Updated", Description = cp.name, Type = "Success", Duration = 1.5})
        end,
        OnDuplicate = function(cp)
            checkpointService:Duplicate(cp.id)
            screen:SetCheckpoints(checkpointService:GetAll())
        end,
        OnRename = function(cp, newName)
            checkpointService:Rename(cp.id, newName)
            screen:SetCheckpoints(checkpointService:GetAll())
        end,
        OnDelete = function(cp)
            checkpointService:Delete(cp.id)
            screen:SetCheckpoints(checkpointService:GetAll())
            Notification.Show({Title = "Deleted", Description = cp.name, Type = "Warning", Duration = 1.5})
        end,
    })
    return screen
end)

router:Register("Settings", function(parent, params)
    local screen = SettingsScreen.new(parent, {
        Store = settingsStore,
        OnReset = function()
            settingsStore:ResetAll()
            local defaults = settingsStore.GetSchema and settingsStore:GetSchema() or {}
            Notification.Show({Title = "Settings Reset", Type = "Warning", Duration = 2})
        end,
    })
    return screen
end)

-- ─── NAVBAR ─────────────────────────────────────────────

local navBar = NavBar.new(navArea, {
    DefaultIndex = 1,
    OnNavigate = function(name, index)
        local screenMap = {
            Home = "Home",
            Commands = "Commands",
            Favorites = "Favorites",
            Checkpoints = "Checkpoints",
            Settings = "Settings",
        }
        local target = screenMap[name]
        if target then
            router:Navigate(target)
        end
    end,
    Badges = {0, 0, 0, 0, 0},
})

-- Set favorites badge on load
local favCount = 0
for _, v in pairs(favorites) do if v then favCount = favCount + 1 end end
navBar:SetBadge(3, favCount > 0 and favCount or nil)

-- ─── FLOATING BUTTON ────────────────────────────────────

local floatBtn = FloatingButton.new(ScreenGui, {
    DefaultPosition = UDim2.new(1, -72, 1, -140),
    OnOpen = function()
        mainContainer.Visible = true
        mainContainer.Size = UDim2.fromScale(0, 0)
        mainContainer.BackgroundTransparency = 1
        TweenKit.new(mainContainer, {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0,
        }, 0.3, "OutQuad")
    end,
    OnClose = function()
        TweenKit.new(mainContainer, {
            Size = UDim2.fromScale(0, 0),
            BackgroundTransparency = 1,
        }, 0.25, "InQuad")
        task.delay(0.3, function()
            mainContainer.Visible = false
        end)
    end,
})

-- Toggle floating button from settings
settingsStore:Watch("floatingButton", function(value)
    if floatBtn then
        if value then
            floatBtn:Close()
            task.delay(0.4, function()
                if floatBtn and floatBtn._frame then
                    floatBtn._frame.Visible = true
                end
            end)
        else
            if floatBtn and floatBtn._frame then
                floatBtn._frame.Visible = false
            end
        end
    end
end)

-- ─── KEYBIND ────────────────────────────────────────────

local toggleKey = Enum.KeyCode.F2
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
        if mainContainer.Visible then
            floatBtn:Close()
        else
            floatBtn:Open()
        end
    end
end)

-- ─── BOOT SEQUENCE ──────────────────────────────────────

mainContainer.Visible = true

-- Show startup notification
Notification.Show({
    Title = "Infinite Yield Mobile",
    Description = "v2.0 — " .. tostring(#Registry.GetAll()) .. " commands loaded",
    Type = "Info",
    Duration = 3,
    Icon = "I",
})

-- Navigate to Home
router:Navigate("Home")

-- ─── STATE WATCHERS ─────────────────────────────────────

appState:Watch("favorites", function(favs)
    local count = 0
    for _, v in pairs(favs or {}) do if v then count = count + 1 end end
    navBar:SetBadge(3, count > 0 and count or nil)
end)

-- ─── RESIZE HANDLER ─────────────────────────────────────

local resizeConn = ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local size = ScreenGui.AbsoluteSize
    Responsive.CheckSize(size)
    local scale = Responsive.GetScale()
    for _, uiScale in ipairs(ScreenGui:GetDescendants()) do
        if uiScale:IsA("UIScale") then
            uiScale.Scale = scale
        end
    end
end)

-- ─── CLEANUP ────────────────────────────────────────────

local function cleanup()
    if floatBtn then floatBtn:Destroy() end
    if router then router:Destroy() end
    if navBar then navBar:Destroy() end
    if resizeConn then resizeConn:Disconnect() end
    if ScreenGui then ScreenGui:Destroy() end
end

-- Return API for external access
return {
    Execute = executeCommand,
    Registry = Registry,
    Checkpoints = checkpointService,
    Settings = settingsStore,
    Notify = Notification.Show,
    Cleanup = cleanup,
    Version = "2.0.0",
    Name = "Infinite Yield Mobile Reborn",
}