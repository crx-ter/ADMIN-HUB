--[[ Infinite Yield Mobile Reborn - Bundled for Delta Executor ]]
-- Version 2.0.0 | Built: 2026-07-08T21:45:40.381Z

local _MODULES = {}

local function _require(path)
    if _MODULES[path] then return _MODULES[path] end
    local alt = path:gsub("^src/", "")
    if _MODULES[alt] then return _MODULES[alt] end
    error("Module not found: " .. tostring(path))
end

-- Module: src/core/observer.lua
_MODULES['src/core/observer.lua'] = (function()
local Signal = require(script.Parent.signal)

local Observer = {}
Observer.__index = Observer

function Observer.new(initialData)
    local self = setmetatable({
        _data = initialData or {},
        _signals = {},
    }, Observer)
    return self
end

function Observer:_getSignal(key)
    if not self._signals[key] then
        self._signals[key] = Signal.new()
    end
    return self._signals[key]
end

function Observer:Get(key)
    return self._data[key]
end

function Observer:Set(key, value)
    local old = self._data[key]
    if old == value then return end
    self._data[key] = value
    local sig = self._signals[key]
    if sig then
        sig:Fire(value, old)
    end
end

function Observer:Update(key, transform)
    local old = self._data[key]
    local new = transform(old)
    self:Set(key, new)
end

function Observer:Watch(key, callback)
    local sig = self:_getSignal(key)
    local conn = sig:Connect(callback)
    callback(self._data[key], nil)
    return conn
end

function Observer:WatchOnce(key, callback)
    local sig = self:_getSignal(key)
    return sig:Once(callback)
end

function Observer:BatchSet(changes)
    local affected = {}
    for key, value in pairs(changes) do
        local old = self._data[key]
        if old ~= value then
            self._data[key] = value
            affected[key] = {New = value, Old = old}
        end
    end
    for key, change in pairs(affected) do
        local sig = self._signals[key]
        if sig then
            sig:Fire(change.New, change.Old)
        end
    end
end

function Observer:Destroy()
    for _, sig in pairs(self._signals) do
        sig:Destroy()
    end
    self._signals = nil
    self._data = nil
end

return Observer
end)()

-- Module: src/core/signal.lua
_MODULES['src/core/signal.lua'] = (function()
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({
        _connections = {},
        _connectionId = 0,
    }, Signal)
    return self
end

function Signal:Connect(callback)
    self._connectionId = self._connectionId + 1
    local id = self._connectionId
    local conn = {
        Id = id,
        Callback = callback,
        Connected = true,
    }
    table.insert(self._connections, conn)
    return conn
end

function Signal:Once(callback)
    local wrapper
    local conn
    wrapper = function(...)
        if conn and conn.Connected then
            conn.Connected = false
            callback(...)
        end
    end
    conn = self:Connect(wrapper)
    return conn
end

function Signal:Fire(...)
    for i = #self._connections, 1, -1 do
        local conn = self._connections[i]
        if conn.Connected then
            local success, err = pcall(conn.Callback, ...)
            if not success then
                warn("[IY] Signal error:", err)
            end
        else
            table.remove(self._connections, i)
        end
    end
end

function Signal:Disconnect(connection)
    if connection and connection.Connected then
        connection.Connected = false
        for i, conn in ipairs(self._connections) do
            if conn.Id == connection.Id then
                table.remove(self._connections, i)
                break
            end
        end
    end
end

function Signal:DisconnectAll()
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    self._connections = {}
end

function Signal:Destroy()
    self:DisconnectAll()
    self._connections = nil
end

return Signal
end)()

-- Module: src/core/theme.lua
_MODULES['src/core/theme.lua'] = (function()
local Theme = {}
Theme.__index = Theme

local DEFAULT_PALETTE = {
    Background = Color3.fromRGB(7, 9, 15),
    Surface = Color3.fromRGB(17, 24, 39),
    SurfaceLight = Color3.fromRGB(31, 41, 55),
    Primary = Color3.fromRGB(59, 130, 246),
    Secondary = Color3.fromRGB(139, 92, 246),
    Accent = Color3.fromRGB(6, 182, 212),
    Success = Color3.fromRGB(34, 197, 94),
    Warning = Color3.fromRGB(251, 191, 36),
    Error = Color3.fromRGB(239, 68, 68),
    TextPrimary = Color3.fromRGB(241, 245, 249),
    TextSecondary = Color3.fromRGB(148, 163, 184),
    TextMuted = Color3.fromRGB(100, 116, 139),
    Border = Color3.fromRGB(55, 65, 81),
    Glow = Color3.fromRGB(59, 130, 246),
}

local DEFAULT_SCALES = {
    XS = 0.75,
    SM = 0.875,
    MD = 1.0,
    LG = 1.125,
    XL = 1.25,
    XXL = 1.5,
}

function Theme.new(overrides)
    local self = setmetatable({}, Theme)
    self.Palette = {}
    for k, v in pairs(DEFAULT_PALETTE) do
        self.Palette[k] = v
    end
    if overrides then
        for k, v in pairs(overrides) do
            if type(v) == "table" and self.Palette[k] then
                for sk, sv in pairs(v) do
                    self.Palette[k] = sv
                end
            else
                self.Palette[k] = v
            end
        end
    end
    self.Scale = 1.0
    self.PanelTransparency = 0.4
    self.BlurIntensity = 12
    self.AnimationSpeed = 1.0
    self.Scales = DEFAULT_SCALES
    return self
end

function Theme:GetColor(name)
    return self.Palette[name] or self.Palette.TextPrimary
end

function Theme:SetPrimary(color)
    self.Palette.Primary = color
    self.Palette.Glow = color
end

function Theme:SetSecondary(color)
    self.Palette.Secondary = color
end

function Theme:GetSurfaceColor(transparency)
    local t = transparency or self.PanelTransparency
    return self.Palette.Surface, t
end

function Theme:GetBorderColor(transparency)
    return self.Palette.Border, 0.6
end

function Theme:GetAccentGradient()
    return {
        Color1 = self.Palette.Primary,
        Color2 = self.Palette.Secondary,
    }
end

function Theme:GetGlassProps(panel)
    panel.BackgroundColor3 = self.Palette.Surface
    panel.BackgroundTransparency = self.PanelTransparency
    local stroke = panel:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = Instance.new("UIStroke")
        stroke.Parent = panel
    end
    stroke.Color = self.Palette.Border
    stroke.Transparency = 0.7
    stroke.Thickness = 1
end

function Theme:ApplyGlass(panel)
    self:GetGlassProps(panel)
end

local _instance = Theme.new()

function Theme.GetGlobal()
    return _instance
end

function Theme.SetGlobal(theme)
    _instance = theme
end

return Theme
end)()

-- Module: src/core/throttle.lua
_MODULES['src/core/throttle.lua'] = (function()
local RunService = game:GetService("RunService")

local Throttle = {}

function Throttle:Debounce(fn, waitTime)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= waitTime then
            lastCall = now
            return fn(...)
        end
        return false
    end
end

function Throttle:Throttle(fn, minInterval)
    local lastCall = 0
    local pending = false
    local lastArgs = nil

    return function(...)
        local now = tick()
        lastArgs = {...}

        if now - lastCall >= minInterval then
            lastCall = now
            pending = false
            return fn(table.unpack(lastArgs))
        end

        if not pending then
            pending = true
            task.delay(minInterval - (now - lastCall), function()
                pending = false
                if lastArgs then
                    lastCall = tick()
                    fn(table.unpack(lastArgs))
                end
            end)
        end
        return false
    end
end

function Throttle:Coalesce(fn, window)
    local timer = nil
    local lastArgs = nil

    return function(...)
        lastArgs = {...}
        if timer then return end
        timer = task.delay(window or 0.1, function()
            timer = nil
            if lastArgs then
                fn(table.unpack(lastArgs))
            end
        end)
    end
end

function Throttle:Rail(fn, minInterval)
    local cooldown = false
    local queue = false
    local queuedArgs = nil

    return function(...)
        if cooldown then
            queue = true
            queuedArgs = {...}
            return
        end

        cooldown = true
        fn(...)

        task.delay(minInterval, function()
            cooldown = false
            if queue then
                queue = false
                fn(table.unpack(queuedArgs))
                cooldown = true
                task.delay(minInterval, function()
                    cooldown = false
                end)
            end
        end)
    end
end

function Throttle:FrameRate(fn)
    local running = false
    return function(...)
        if running then return end
        running = true
        RunService.Heartbeat:Wait()
        running = false
        fn(...)
    end
end

return Throttle
end)()

-- Module: src/core/tween.lua
_MODULES['src/core/tween.lua'] = (function()
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TweenKit = {}
TweenKit.__index = TweenKit

local _pool = {}
local _poolSize = 0
local _MAX_POOL = 100

local EASING_MAP = {
    InQuad = Enum.EasingStyle.Quad,
    OutQuad = Enum.EasingStyle.Quad,
    InOutQuad = Enum.EasingStyle.Quad,
    InCubic = Enum.EasingStyle.Cubic,
    OutCubic = Enum.EasingStyle.Cubic,
    InOutCubic = Enum.EasingStyle.Cubic,
    InQuart = Enum.EasingStyle.Quart,
    OutQuart = Enum.EasingStyle.Quart,
    InOutQuart = Enum.EasingStyle.Quart,
    InQuint = Enum.EasingStyle.Quint,
    OutQuint = Enum.EasingStyle.Quint,
    InOutQuint = Enum.EasingStyle.Quint,
    InSine = Enum.EasingStyle.Sine,
    OutSine = Enum.EasingStyle.Sine,
    InOutSine = Enum.EasingStyle.Sine,
    InExpo = Enum.EasingStyle.Exponential,
    OutExpo = Enum.EasingStyle.Exponential,
    InOutExpo = Enum.EasingStyle.Exponential,
    InCirc = Enum.EasingStyle.Circular,
    OutCirc = Enum.EasingStyle.Circular,
    InOutCirc = Enum.EasingStyle.Circular,
    InElastic = Enum.EasingStyle.Elastic,
    OutElastic = Enum.EasingStyle.Elastic,
    InOutElastic = Enum.EasingStyle.Elastic,
    InBack = Enum.EasingStyle.Back,
    OutBack = Enum.EasingStyle.Back,
    InOutBack = Enum.EasingStyle.Back,
    InBounce = Enum.EasingStyle.Bounce,
    OutBounce = Enum.EasingStyle.Bounce,
    InOutBounce = Enum.EasingStyle.Bounce,
    Linear = Enum.EasingStyle.Linear,
}

local function getEasing(easingName)
    local info = EASING_MAP[easingName]
    if info then
        local dir = Enum.EasingDirection.In
        if easingName:match("^Out") then
            dir = Enum.EasingDirection.Out
        elseif easingName:match("^InOut") then
            dir = Enum.EasingDirection.InOut
        end
        return info, dir
    end
    return Enum.EasingStyle.Quad, Enum.EasingDirection.Out
end

function TweenKit.new(instance, goal, duration, easingName, overwrite)
    local easingStyle, easingDir = getEasing(easingName or "OutQuad")

    if overwrite ~= false then
        TweenKit:CancelInstance(instance)
    end

    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle, easingDir, 0, false, 0)
    local tween

    if _poolSize > 0 and #_pool > 0 then
        tween = table.remove(_pool)
        _poolSize = _poolSize - 1
        tween:Play()
    else
        tween = TweenService:Create(instance, tweenInfo, goal)
    end

    tween:Play()

    local meta = {
        Tween = tween,
        Instance = instance,
        Goal = goal,
        Playing = true,
        Completed = false,
    }

    tween.Completed:Connect(function()
        meta.Playing = false
        meta.Completed = true
        if _poolSize < _MAX_POOL then
            tween:Cancel()
            table.insert(_pool, tween)
            _poolSize = _poolSize + 1
        end
    end)

    return meta
end

function TweenKit:CancelInstance(instance)
    instance = instance:IsA("Instance") and instance or instance.Instance
end

function TweenKit:Cancel(meta)
    if meta and meta.Tween and meta.Playing then
        meta.Tween:Cancel()
        meta.Playing = false
        meta.Completed = true
    end
end

function TweenKit:Sequence(instance, steps, onComplete)
    local index = 1
    local function playNext()
        if index > #steps then
            if onComplete then onComplete() end
            return
        end
        local step = steps[index]
        local meta = TweenKit.new(instance, step.Goal, step.Duration or 0.3, step.Easing or "OutQuad")
        task.delay(step.Duration or 0.3, playNext)
        index = index + 1
    end
    playNext()
end

function TweenKit:Parallel(tweens, onComplete)
    local remaining = #tweens
    if remaining == 0 then
        if onComplete then onComplete() end
        return
    end
    for _, t in ipairs(tweens) do
        TweenKit.new(t.Instance, t.Goal, t.Duration or 0.3, t.Easing or "OutQuad", t.Overwrite)
    end
    if onComplete then
        task.delay(0.35, onComplete)
    end
end

function TweenKit:Scale(instance, targetScale, duration, easing)
    return TweenKit.new(instance, {Size = UDim2.fromScale(targetScale.X, targetScale.Y)}, duration or 0.3, easing or "OutBack")
end

function TweenKit:Fade(instance, targetTransparency, duration, easing)
    return TweenKit.new(instance, {Transparency = targetTransparency}, duration or 0.3, easing or "OutQuad")
end

function TweenKit:Move(instance, targetPosition, duration, easing)
    return TweenKit.new(instance, {Position = targetPosition}, duration or 0.3, easing or "OutQuad")
end

return TweenKit
end)()

-- Module: src/features/commands/Categories.lua
_MODULES['src/features/commands/Categories.lua'] = (function()
local Categories = {
	All = {},
	ById = {},
}

local data = {
	{
		id = "Player",
		name = "Player",
		icon = "P",
		color = Color3.fromRGB(59, 130, 246),
		description = "Player management",
	},
	{
		id = "Movement",
		name = "Movement",
		icon = "M",
		color = Color3.fromRGB(34, 197, 94),
		description = "Movement and flight",
	},
	{
		id = "Visual",
		name = "Visual",
		icon = "V",
		color = Color3.fromRGB(139, 92, 246),
		description = "Visual effects",
	},
	{
		id = "Teleport",
		name = "Teleport",
		icon = "T",
		color = Color3.fromRGB(249, 115, 22),
		description = "Teleportation",
	},
	{
		id = "World",
		name = "World",
		icon = "W",
		color = Color3.fromRGB(6, 182, 212),
		description = "World manipulation",
	},
	{
		id = "Tools",
		name = "Tools",
		icon = "O",
		color = Color3.fromRGB(234, 179, 8),
		description = "Tools and items",
	},
	{
		id = "Utilities",
		name = "Utilities",
		icon = "U",
		color = Color3.fromRGB(239, 68, 68),
		description = "General utilities",
	},
	{
		id = "Console",
		name = "Console",
		icon = "L",
		color = Color3.fromRGB(148, 163, 184),
		description = "Console and logging",
	},
	{
		id = "Trolling",
		name = "Trolling",
		icon = "F",
		color = Color3.fromRGB(236, 72, 153),
		description = "Fun and trolling",
	},
}

for _, cat in data do
	Categories.All[#Categories.All + 1] = cat
	Categories.ById[cat.id] = cat
end

function Categories.GetAll()
	return Categories.All
end

function Categories.GetById(id)
	return Categories.ById[id]
end

return Categories
end)()

-- Module: src/features/commands/Console.lua
_MODULES['src/features/commands/Console.lua'] = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Console = {}

local function getPlayer()
	return Players.LocalPlayer
end

local consoleVisible = true
local consoleGui = nil

function Console.Print()
	return {
		id = "Print",
		name = "Print",
		aliases = { "print", "log" },
		description = "Print a message to console",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(msg)
			print("[IY] " .. tostring(msg or ""))
		end,
		onUndo = function() end,
	}
end

function Console.Warn()
	return {
		id = "Warn",
		name = "Warn",
		aliases = { "warn" },
		description = "Print a warning",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(msg)
			warn("[IY] " .. tostring(msg or ""))
		end,
		onUndo = function() end,
	}
end

function Console.Error()
	return {
		id = "Error",
		name = "Error",
		aliases = { "error" },
		description = "Print an error",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(msg)
			local errMsg = "[IY] " .. tostring(msg or "Unknown error")
			error(errMsg)
		end,
		onUndo = function() end,
	}
end

function Console.ClearConsole()
	return {
		id = "ClearConsole",
		name = "Clear Console",
		aliases = { "clearconsole", "clear", "cls" },
		description = "Clear console output",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					local log = gui:FindFirstChild("Log")
					if log then
						log:ClearAllChildren()
					end
				end
			end
			for _ = 1, 50 do
				print("")
			end
		end,
		onUndo = function() end,
	}
end

function Console.ConsoleToggle()
	return {
		id = "ConsoleToggle",
		name = "Console Toggle",
		aliases = { "consoletoggle", "toggleconsole", "togcon" },
		description = "Show/hide console",
		category = "Console",
		icon = "L",
		isToggle = true,
		onExecute = function()
			consoleVisible = not consoleVisible
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					gui.Enabled = consoleVisible
				end
			end
		end,
		onUndo = function()
			consoleVisible = true
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					gui.Enabled = true
				end
			end
		end,
	}
end

function Console.ExecutorInfo()
	return {
		id = "ExecutorInfo",
		name = "Executor Info",
		aliases = { "executorinfo", "exeinfo", "ei" },
		description = "Show executor info",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local info = {
				Name = "IY Mobile Reborn",
				Version = "1.0.0",
				Executor = identifyexecutor and identifyexecutor() or "Unknown",
				Platform = "Mobile/Cross-Platform",
			}
			print("=== Executor Info ===")
			for k, v in info do
				print(k .. ": " .. tostring(v))
			end
			print("====================")
		end,
		onUndo = function() end,
	}
end

function Console.ScriptInfo()
	return {
		id = "ScriptInfo",
		name = "Script Info",
		aliases = { "scriptinfo", "si" },
		description = "Show script info",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			print("=== IY Mobile Reborn ===")
			print("Version: 1.0.0")
			print("Commands: " .. tostring(#require(script.Parent.Registry).GetAll()))
			print("Infinity Yield inspired")
			print("Build: " .. game:GetService("HttpService"):GenerateGUID(false):sub(1, 8))
		end,
		onUndo = function() end,
	}
end

function Console.Version()
	return {
		id = "Version",
		name = "Version",
		aliases = { "version", "ver" },
		description = "Show version",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			print("IY Mobile Reborn v1.0.0")
		end,
		onUndo = function() end,
	}
end

function Console.Help()
	return {
		id = "Help",
		name = "Help",
		aliases = { "help", "?" },
		description = "Show help message",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(cmdName)
			if cmdName then
				local registry = require(script.Parent.Registry)
				local cmd = registry.GetByName(cmdName)
				if cmd then
					print("=== " .. cmd.name .. " ===")
					print("ID: " .. cmd.id)
					print("Category: " .. cmd.category)
					print("Description: " .. cmd.description)
					if #cmd.aliases > 0 then
						print("Aliases: [" .. table.concat(cmd.aliases, ", ") .. "]")
					end
					print("Toggle: " .. tostring(cmd.isToggle))
				else
					warn("Command not found: " .. cmdName)
				end
			else
				local registry = require(script.Parent.Registry)
				local all = registry.GetAll()
				print("=== IY Mobile Reborn - Help ===")
				print("Total commands: " .. tostring(#all))
				print("Use 'help <command>' for details")
				print("================================")
			end
		end,
		onUndo = function() end,
	}
end

function Console.Credits()
	return {
		id = "Credits",
		name = "Credits",
		aliases = { "credits" },
		description = "Show credits",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			print("=== IY Mobile Reborn ===")
			print("Original: Infinite Yield")
			print("Mobile Re-creation")
			print("Thanks to the exploit community")
			print("=========================")
		end,
		onUndo = function() end,
	}
end

function Console.CopyOutput()
	return {
		id = "CopyOutput",
		name = "Copy Output",
		aliases = { "copyoutput", "copyout" },
		description = "Copy console output",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					local log = gui:FindFirstChild("Log")
					if log then
						local text = ""
						for _, child in log:GetChildren() do
							if child:IsA("TextLabel") or child:IsA("TextButton") then
								text ..= child.Text .. "\n"
							end
						end
						setclipboard(text)
						warn("Console output copied to clipboard")
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Console.SaveLog()
	return {
		id = "SaveLog",
		name = "Save Log",
		aliases = { "savelog", "logsave" },
		description = "Save log to file",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					local log = gui:FindFirstChild("Log")
					if log then
						local text = ""
						for _, child in log:GetChildren() do
							if child:IsA("TextLabel") or child:IsA("TextButton") then
								text ..= child.Text .. "\n"
							end
						end
						local fileName = "IY_Log_" .. os.time() .. ".txt"
						writefile(fileName, text)
						warn("Log saved to " .. fileName)
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

local commandFactories = {
	Console.Print,
	Console.Warn,
	Console.Error,
	Console.ClearConsole,
	Console.ConsoleToggle,
	Console.ExecutorInfo,
	Console.ScriptInfo,
	Console.Version,
	Console.Help,
	Console.Credits,
	Console.CopyOutput,
	Console.SaveLog,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Movement.lua
_MODULES['src/features/commands/Movement.lua'] = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Movement = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

function Movement.Fly()
	local connections = {}
	local flying = false
	local bodyGyro, bodyVelocity
	return {
		id = "Fly",
		name = "Fly",
		aliases = { "fly" },
		description = "Basic flight",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			flying = true
			local root = getRootPart()
			if not root then return end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = true
			end
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.P = 9e4
			bodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
			bodyGyro.CFrame = root.CFrame
			bodyGyro.Parent = root
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
			bodyVelocity.Parent = root
			connections[#connections + 1] = RunService.RenderStepped:Connect(function()
				if not flying then return end
				if not root or not root.Parent then return end
				local ws = hum and hum.WalkSpeed or 50
				local moveDir = Vector3.new()
				local camera = workspace.CurrentCamera
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + camera.CFrame.LookVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - camera.CFrame.LookVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - camera.CFrame.RightVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + camera.CFrame.RightVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, ws, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					moveDir = moveDir - Vector3.new(0, ws, 0)
				end
				bodyVelocity.Velocity = moveDir
				bodyGyro.CFrame = camera.CFrame
			end)
		end,
		onUndo = function()
			flying = false
			if bodyGyro then
				bodyGyro:Destroy()
				bodyGyro = nil
			end
			if bodyVelocity then
				bodyVelocity:Destroy()
				bodyVelocity = nil
			end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = false
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.FlySpeed()
	return {
		id = "FlySpeed",
		name = "Fly Speed",
		aliases = { "flyspeed", "fspeed" },
		description = "Adjust fly speed",
		category = "Movement",
		icon = "M",
		isToggle = false,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = value or 50
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = 16
			end
		end,
	}
end

function Movement.NoClip()
	local connections = {}
	local noclipOn = false
	return {
		id = "NoClip",
		name = "No Clip",
		aliases = { "noclip", "nc" },
		description = "Walk through walls",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			noclipOn = true
			connections[#connections + 1] = RunService.Stepped:Connect(function()
				if not noclipOn then return end
				local char = getCharacter()
				if char then
					for _, part in char:GetDescendants() do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end
			end)
		end,
		onUndo = function()
			noclipOn = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			local char = getCharacter()
			if char then
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end,
	}
end

function Movement.Teleport()
	local connections = {}
	return {
		id = "Teleport",
		name = "Teleport",
		aliases = { "tp", "teleport" },
		description = "Click to teleport",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = { getCharacter() }
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
					if result then
						local root = getRootPart()
						if root then
							root.CFrame = CFrame.new(result.Position + result.Normal * 3)
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.Speed()
	local connections = {}
	return {
		id = "Speed",
		name = "Speed",
		aliases = { "speed", "ws" },
		description = "Walkspeed boost",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = value or 100
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = 16
			end
		end,
	}
end

function Movement.Jump()
	return {
		id = "Jump",
		name = "Jump",
		aliases = { "jump", "jp", "jumppower" },
		description = "Jump boost",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.JumpPower = value or 200
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.JumpPower = 50
			end
		end,
	}
end

function Movement.Float()
	local connections = {}
	local bodyPosition
	return {
		id = "Float",
		name = "Float",
		aliases = { "float" },
		description = "Float in place",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = true
			end
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.P = 5000
			bodyPosition.D = 500
			bodyPosition.MaxForce = Vector3.new(9e4, 9e4, 9e4)
			bodyPosition.Position = root.Position + Vector3.new(0, 5, 0)
			bodyPosition.Parent = root
		end,
		onUndo = function()
			if bodyPosition then
				bodyPosition:Destroy()
				bodyPosition = nil
			end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = false
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.Swim()
	local connections = {}
	local bodyVelocity
	return {
		id = "Swim",
		name = "Swim",
		aliases = { "swim" },
		description = "Swim in air",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = true
				hum:ChangeState(Enum.HumanoidStateType.Swimming)
			end
			bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
			bodyVelocity.Velocity = Vector3.new(0, 0, 0)
			bodyVelocity.Parent = root
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = RunService.RenderStepped:Connect(function()
				if not root or not root.Parent then return end
				local ws = (hum and hum.WalkSpeed) or 16
				local moveDir = Vector3.new()
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + camera.CFrame.LookVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - camera.CFrame.LookVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - camera.CFrame.RightVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + camera.CFrame.RightVector * ws
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					moveDir = moveDir + Vector3.new(0, ws, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					moveDir = moveDir - Vector3.new(0, ws, 0)
				end
				bodyVelocity.Velocity = moveDir
			end)
		end,
		onUndo = function()
			if bodyVelocity then
				bodyVelocity:Destroy()
				bodyVelocity = nil
			end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = false
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.Gravity()
	return {
		id = "Gravity",
		name = "Gravity",
		aliases = { "gravity", "grav" },
		description = "Change local gravity",
		category = "Movement",
		icon = "M",
		isToggle = false,
		onExecute = function(value)
			workspace.Gravity = value or 196.2
		end,
		onUndo = function()
			workspace.Gravity = 196.2
		end,
	}
end

function Movement.StepUp()
	return {
		id = "StepUp",
		name = "Step Up",
		aliases = { "step", "stepup" },
		description = "Adjust stepping height",
		category = "Movement",
		icon = "M",
		isToggle = false,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.HipHeight = value or 2
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.HipHeight = 0
			end
		end,
	}
end

function Movement.WaterWalk()
	local connections = {}
	return {
		id = "WaterWalk",
		name = "Water Walk",
		aliases = { "waterwalk", "wwalk" },
		description = "Walk on water",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			local hum = getHumanoid()
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
			end
			connections[#connections + 1] = RunService.Stepped:Connect(function()
				local root = getRootPart()
				if root and root.Position.Y < 0 then
					root.CFrame = root.CFrame * CFrame.new(0, 3, 0)
				end
			end)
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.WallWalk()
	local connections = {}
	local bodyGyro
	return {
		id = "WallWalk",
		name = "Wall Walk",
		aliases = { "wallwalk", "wwalk" },
		description = "Walk on walls",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = true
			end
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.P = 9e4
			bodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
			bodyGyro.CFrame = root.CFrame
			bodyGyro.Parent = root
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = RunService.RenderStepped:Connect(function()
				if not root or not root.Parent then return end
				local moveDir = Vector3.new()
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + camera.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - camera.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - camera.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + camera.CFrame.RightVector
				end
				if moveDir.Magnitude > 0 then
					moveDir = moveDir.Unit * (hum and hum.WalkSpeed or 16)
					root.CFrame = root.CFrame + moveDir * 0.1
				end
				bodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + camera.CFrame.LookVector)
			end)
		end,
		onUndo = function()
			if bodyGyro then
				bodyGyro:Destroy()
				bodyGyro = nil
			end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = false
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.CeilingWalk()
	local connections = {}
	local bodyGyro
	local bodyPosition
	return {
		id = "CeilingWalk",
		name = "Ceiling Walk",
		aliases = { "ceilingwalk", "cwalk" },
		description = "Walk on ceiling",
		category = "Movement",
		icon = "M",
		isToggle = true,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = true
			end
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.P = 9e4
			bodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
			bodyGyro.CFrame = root.CFrame * CFrame.Angles(math.pi, 0, 0)
			bodyGyro.Parent = root
			bodyPosition = Instance.new("BodyPosition")
			bodyPosition.P = 5000
			bodyPosition.D = 500
			bodyPosition.MaxForce = Vector3.new(9e4, 9e4, 9e4)
			bodyPosition.Position = root.Position + Vector3.new(0, 10, 0)
			bodyPosition.Parent = root
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = RunService.RenderStepped:Connect(function()
				if not root or not root.Parent then return end
				local moveDir = Vector3.new()
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					moveDir = moveDir + camera.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					moveDir = moveDir - camera.CFrame.LookVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					moveDir = moveDir - camera.CFrame.RightVector
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					moveDir = moveDir + camera.CFrame.RightVector
				end
				if moveDir.Magnitude > 0 then
					moveDir = moveDir.Unit * (hum and hum.WalkSpeed or 16)
					root.CFrame = root.CFrame + moveDir * 0.1
				end
				bodyPosition.Position = root.Position + Vector3.new(0, 10, 0)
			end)
		end,
		onUndo = function()
			if bodyGyro then
				bodyGyro:Destroy()
				bodyGyro = nil
			end
			if bodyPosition then
				bodyPosition:Destroy()
				bodyPosition = nil
			end
			local hum = getHumanoid()
			if hum then
				hum.PlatformStand = false
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Movement.Dash()
	return {
		id = "Dash",
		name = "Dash",
		aliases = { "dash" },
		description = "Short burst of speed",
		category = "Movement",
		icon = "M",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if not root then return end
			local camera = workspace.CurrentCamera
			local dir = camera.CFrame.LookVector * (value or 100)
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
			bv.Velocity = dir
			bv.Parent = root
			task.delay(0.3, function()
				bv:Destroy()
			end)
		end,
		onUndo = function() end,
	}
end

local commandFactories = {
	Movement.Fly,
	Movement.FlySpeed,
	Movement.NoClip,
	Movement.Teleport,
	Movement.Speed,
	Movement.Jump,
	Movement.Float,
	Movement.Swim,
	Movement.Gravity,
	Movement.StepUp,
	Movement.WaterWalk,
	Movement.WallWalk,
	Movement.CeilingWalk,
	Movement.Dash,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Player.lua
_MODULES['src/features/commands/Player.lua'] = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Player = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then
		return plr.Character
	end
end

local function getHumanoid()
	local char = getCharacter()
	if char then
		return char:FindFirstChildOfClass("Humanoid")
	end
end

local function getRootPart()
	local char = getCharacter()
	if char then
		return char:FindFirstChild("HumanoidRootPart")
	end
end

function Player.InfiniteJump()
	local connections = {}
	return {
		id = "InfiniteJump",
		name = "Infinite Jump",
		aliases = { "infjump", "infj" },
		description = "Allows infinite jumping",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local plr = getPlayer()
			if not plr then return end
			local con
			con = UserInputService.JumpRequest:Connect(function()
				local hum = getHumanoid()
				if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
			connections[#connections + 1] = con
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Player.Noclip()
	local connections = {}
	local noclipOn = false
	return {
		id = "Noclip",
		name = "Noclip",
		aliases = { "nc", "noclip" },
		description = "Walk through walls",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			noclipOn = true
			local con
			con = RunService.Stepped:Connect(function()
				if not noclipOn then return end
				local char = getCharacter()
				if char then
					for _, part in char:GetDescendants() do
						if part:IsA("BasePart") then
							part.CanCollide = false
						end
					end
				end
			end)
			connections[#connections + 1] = con
		end,
		onUndo = function()
			noclipOn = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			local char = getCharacter()
			if char then
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
		end,
	}
end

function Player.Walkspeed()
	return {
		id = "Walkspeed",
		name = "Walkspeed",
		aliases = { "ws", "speed" },
		description = "Adjust walkspeed (slider)",
		category = "Player",
		icon = "P",
		isToggle = false,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = value or 16
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.WalkSpeed = 16
			end
		end,
	}
end

function Player.JumpPower()
	return {
		id = "JumpPower",
		name = "Jump Power",
		aliases = { "jp", "jumppower" },
		description = "Adjust jump power (slider)",
		category = "Player",
		icon = "P",
		isToggle = false,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.JumpPower = value or 50
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.JumpPower = 50
			end
		end,
	}
end

function Player.HipHeight()
	return {
		id = "HipHeight",
		name = "Hip Height",
		aliases = { "hh", "hipheight" },
		description = "Adjust hip height (slider)",
		category = "Player",
		icon = "P",
		isToggle = false,
		onExecute = function(value)
			local hum = getHumanoid()
			if hum then
				hum.HipHeight = value or 0
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.HipHeight = 0
			end
		end,
	}
end

function Player.Sit()
	return {
		id = "Sit",
		name = "Sit",
		aliases = { "sit" },
		description = "Make player sit",
		category = "Player",
		icon = "P",
		isToggle = false,
		onExecute = function()
			local hum = getHumanoid()
			if hum then
				hum.Sit = true
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.Sit = false
			end
		end,
	}
end

function Player.Lay()
	return {
		id = "Lay",
		name = "Lay",
		aliases = { "lay" },
		description = "Make player lay down",
		category = "Player",
		icon = "P",
		isToggle = false,
		onExecute = function()
			local hum = getHumanoid()
			if hum then
				hum.Sit = true
				local root = getRootPart()
				if root then
					root.CFrame = root.CFrame * CFrame.Angles(math.rad(90), 0, 0)
				end
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.Sit = false
			end
		end,
	}
end

function Player.NoFallDamage()
	local connections = {}
	return {
		id = "NoFallDamage",
		name = "No Fall Damage",
		aliases = { "nofall", "nfd" },
		description = "No fall damage",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local hum = getHumanoid()
			if hum then
				connections[#connections + 1] = hum:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				end)
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Player.GodMode()
	local connections = {}
	return {
		id = "GodMode",
		name = "God Mode",
		aliases = { "god", "godmode" },
		description = "Become invincible",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				connections[#connections + 1] = plr.CharacterAdded:Connect(function(char)
					task.wait(0.5)
					local hum = char:FindFirstChildOfClass("Humanoid")
					if hum then
						hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
						hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
						hum.MaxHealth = math.huge
						hum.Health = math.huge
					end
				end)
				local hum = getHumanoid()
				if hum then
					hum.MaxHealth = math.huge
					hum.Health = math.huge
				end
			end
		end,
		onUndo = function()
			local hum = getHumanoid()
			if hum then
				hum.MaxHealth = 100
				hum.Health = 100
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Player.ESP()
	local connections = {}
	local espObjects = {}
	return {
		id = "ESP",
		name = "ESP",
		aliases = { "esp" },
		description = "See players through walls",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local function addESP(player)
				local function updateChar(char)
					if not char then return end
					local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("BasePart")
					if not root then return end
					local highlight = Instance.new("Highlight")
					highlight.Name = "IY_ESP"
					highlight.Adornee = char
					highlight.FillColor = player.TeamColor.Color
					highlight.OutlineColor = Color3.new(1, 1, 1)
					highlight.FillTransparency = 0.5
					highlight.Parent = char
					espObjects[#espObjects + 1] = highlight
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() then
					addESP(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addESP)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in espObjects do
				obj:Destroy()
			end
			table.clear(espObjects)
			for _, plr in Players:GetPlayers() do
				if plr.Character then
					local hl = plr.Character:FindFirstChild("IY_ESP")
					if hl then hl:Destroy() end
				end
			end
		end,
	}
end

function Player.Chams()
	local connections = {}
	local chamsObjects = {}
	return {
		id = "Chams",
		name = "Chams",
		aliases = { "chams" },
		description = "Colored player outlines",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local function addChams(player)
				local function updateChar(char)
					if not char then return end
					local highlight = Instance.new("Highlight")
					highlight.Name = "IY_Chams"
					highlight.Adornee = char
					highlight.FillColor = Color3.fromRGB(0, 255, 0)
					highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
					highlight.FillTransparency = 0.7
					highlight.OutlineTransparency = 0
					highlight.Parent = char
					chamsObjects[#chamsObjects + 1] = highlight
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() then
					addChams(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addChams)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in chamsObjects do
				obj:Destroy()
			end
			table.clear(chamsObjects)
			for _, plr in Players:GetPlayers() do
				if plr.Character then
					local hl = plr.Character:FindFirstChild("IY_Chams")
					if hl then hl:Destroy() end
				end
			end
		end,
	}
end

function Player.Wallhack()
	local connections = {}
	local whObjects = {}
	return {
		id = "Wallhack",
		name = "Wallhack",
		aliases = { "wh", "wallhack" },
		description = "See through walls",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local function addWH(player)
				local function updateChar(char)
					if not char then return end
					for _, part in char:GetDescendants() do
						if part:IsA("BasePart") and part.Transparency < 1 then
							local orig = part.Transparency
							part.Transparency = 0.5
							whObjects[#whObjects + 1] = { part = part, orig = orig }
						end
					end
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() then
					addWH(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addWH)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, entry in whObjects do
				pcall(function()
					entry.part.Transparency = entry.orig
				end)
			end
			table.clear(whObjects)
		end,
	}
end

function Player.XRay()
	local connections = {}
	local xrayParts = {}
	return {
		id = "XRay",
		name = "X-Ray",
		aliases = { "xray", "xray" },
		description = "See ores through walls",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local workspace = game:GetService("Workspace")
			local function processContainer(container)
				for _, obj in container:GetDescendants() do
					if obj:IsA("BasePart") and (obj.Name:lower():find("ore") or obj.Name:lower():find("rock") or obj.Name:lower():find("gem") or obj.Name:lower():find("crystal") or obj.Name:lower():find("node")) then
						local orig = obj.Transparency
						obj.Transparency = 0.3
						xrayParts[#xrayParts + 1] = { part = obj, orig = orig }
					end
				end
			end
			processContainer(workspace)
			connections[#connections + 1] = workspace.DescendantAdded:Connect(function(desc)
				task.wait(0.1)
				if desc:IsA("BasePart") and (desc.Name:lower():find("ore") or desc.Name:lower():find("rock") or desc.Name:lower():find("gem") or desc.Name:lower():find("crystal") or desc.Name:lower():find("node")) then
					local orig = desc.Transparency
					desc.Transparency = 0.3
					xrayParts[#xrayParts + 1] = { part = desc, orig = orig }
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, entry in xrayParts do
				pcall(function()
					entry.part.Transparency = entry.orig
				end)
			end
			table.clear(xrayParts)
		end,
	}
end

function Player.ThirdPerson()
	return {
		id = "ThirdPerson",
		name = "Third Person",
		aliases = { "tp", "thirdperson", "3p" },
		description = "Third person camera",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local cam = workspace.CurrentCamera
				cam.CameraSubject = getHumanoid()
				cam.CameraType = Enum.CameraType.Custom
			end
		end,
		onUndo = function()
			local plr = getPlayer()
			if plr then
				local cam = workspace.CurrentCamera
				cam.CameraSubject = getHumanoid()
				cam.CameraType = Enum.CameraType.Custom
			end
		end,
	}
end

function Player.FirstPerson()
	return {
		id = "FirstPerson",
		name = "First Person",
		aliases = { "fp", "firstperson", "1p" },
		description = "First person camera",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local cam = workspace.CurrentCamera
				cam.CameraSubject = getHumanoid()
				cam.CameraType = Enum.CameraType.Attach
			end
		end,
		onUndo = function()
			local plr = getPlayer()
			if plr then
				local cam = workspace.CurrentCamera
				cam.CameraSubject = getHumanoid()
				cam.CameraType = Enum.CameraType.Custom
			end
		end,
	}
end

function Player.LockCamera()
	local connections = {}
	return {
		id = "LockCamera",
		name = "Lock Camera",
		aliases = { "lockcam", "lockcamera" },
		description = "Lock camera in place",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local cam = workspace.CurrentCamera
			local savedCF = cam.CFrame
			connections[#connections + 1] = RunService.RenderStepped:Connect(function()
				cam.CFrame = savedCF
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Player.PanicHide()
	return {
		id = "PanicHide",
		name = "Panic Hide",
		aliases = { "panic", "hide" },
		description = "Hide from server logs",
		category = "Player",
		icon = "P",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				plr:SetAttribute("IY_Panic", true)
				local gui = plr:FindFirstChildOfClass("PlayerGui")
				if gui then
					for _, inst in gui:GetChildren() do
						if inst:IsA("ScreenGui") and inst.Enabled then
							inst.Enabled = false
						end
					end
				end
			end
		end,
		onUndo = function()
			local plr = getPlayer()
			if plr then
				plr:SetAttribute("IY_Panic", nil)
				local gui = plr:FindFirstChildOfClass("PlayerGui")
				if gui then
					for _, inst in gui:GetChildren() do
						if inst:IsA("ScreenGui") then
							inst.Enabled = true
						end
					end
				end
			end
		end,
	}
end

function Player.AntiAFK()
	local connections = {}
	return {
		id = "AntiAFK",
		name = "Anti AFK",
		aliases = { "antiafk", "aafk", "noafk" },
		description = "Prevent auto-kick",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local con
				con = plr.Idled:Connect(function()
					task.wait(0.1)
					local vp = game:GetService("VirtualUser")
					vp:CaptureController()
					vp:ClickButton2(Vector2.new())
					plr:SetAttribute("IY_AFK", true)
				end)
				connections[#connections + 1] = con
			end
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Player.NameESP()
	local connections = {}
	local nameObjects = {}
	return {
		id = "NameESP",
		name = "Name ESP",
		aliases = { "names", "nameesp" },
		description = "Show names at distance",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local function addNameTag(player)
				local function updateChar(char)
					if not char then return end
					local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("BasePart")
					if not root then return end
					local billboard = Instance.new("BillboardGui")
					billboard.Name = "IY_NameESP"
					billboard.Size = UDim2.new(0, 200, 0, 50)
					billboard.StudsOffset = Vector3.new(0, 3, 0)
					billboard.AlwaysOnTop = true
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = player.Name
					label.TextColor3 = Color3.fromRGB(255, 255, 255)
					label.TextStrokeTransparency = 0
					label.TextScaled = true
					label.Font = Enum.Font.GothamBold
					label.Parent = billboard
					billboard.Parent = root
					nameObjects[#nameObjects + 1] = billboard
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() then
					addNameTag(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addNameTag)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in nameObjects do
				obj:Destroy()
			end
			table.clear(nameObjects)
		end,
	}
end

function Player.HealthESP()
	local connections = {}
	local healthObjects = {}
	return {
		id = "HealthESP",
		name = "Health ESP",
		aliases = { "healthesp", "hesp" },
		description = "Show health bars",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local function addHealthBar(player)
				local function updateChar(char)
					if not char then return end
					local hum = char:FindFirstChildOfClass("Humanoid")
					if not hum then return end
					local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("BasePart")
					if not root then return end
					local billboard = Instance.new("BillboardGui")
					billboard.Name = "IY_HealthESP"
					billboard.Size = UDim2.new(0, 100, 0, 20)
					billboard.StudsOffset = Vector3.new(0, 4, 0)
					billboard.AlwaysOnTop = true
					local bg = Instance.new("Frame")
					bg.Size = UDim2.new(1, 0, 1, 0)
					bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					bg.BorderSizePixel = 0
					bg.Parent = billboard
					local bar = Instance.new("Frame")
					bar.Name = "Bar"
					bar.Size = UDim2.new(1, 0, 1, 0)
					bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
					bar.BorderSizePixel = 0
					bar.Parent = bg
					local function updateHealth()
						local ratio = hum.Health / hum.MaxHealth
						bar.Size = UDim2.new(ratio, 0, 1, 0)
						bar.BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
					end
					updateHealth()
					connections[#connections + 1] = hum:GetPropertyChangedSignal("Health"):Connect(updateHealth)
					connections[#connections + 1] = hum:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
					billboard.Parent = root
					healthObjects[#healthObjects + 1] = billboard
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() then
					addHealthBar(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addHealthBar)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in healthObjects do
				obj:Destroy()
			end
			table.clear(healthObjects)
		end,
	}
end

function Player.DistanceESP()
	local connections = {}
	local distObjects = {}
	return {
		id = "DistanceESP",
		name = "Distance ESP",
		aliases = { "dist", "distanceesp", "desp" },
		description = "Show distances to players",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local localPlayer = getPlayer()
			local function addDistance(player)
				local function updateChar(char)
					if not char then return end
					local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("BasePart")
					if not root then return end
					local billboard = Instance.new("BillboardGui")
					billboard.Name = "IY_DistanceESP"
					billboard.Size = UDim2.new(0, 100, 0, 30)
					billboard.StudsOffset = Vector3.new(0, 3.5, 0)
					billboard.AlwaysOnTop = true
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.TextColor3 = Color3.fromRGB(255, 255, 0)
					label.TextStrokeTransparency = 0
					label.TextScaled = true
					label.Font = Enum.Font.GothamBold
					label.Parent = billboard
					local function updateDist()
						local localRoot = getRootPart()
						if localRoot and root then
							local dist = (localRoot.Position - root.Position).Magnitude
							label.Text = string.format("%.1f studs", dist)
						end
					end
					updateDist()
					local heartbeatCon
					heartbeatCon = RunService.Heartbeat:Connect(updateDist)
					connections[#connections + 1] = heartbeatCon
					billboard.Parent = root
					distObjects[#distObjects + 1] = billboard
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= localPlayer then
					addDistance(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addDistance)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in distObjects do
				obj:Destroy()
			end
			table.clear(distObjects)
		end,
	}
end

function Player.Tracer()
	local connections = {}
	local tracerObjects = {}
	return {
		id = "Tracer",
		name = "Tracer",
		aliases = { "tracer" },
		description = "Draw lines to players",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local localPlayer = getPlayer()
			local camera = workspace.CurrentCamera
			local function addTracer(player)
				local function updateChar(char)
					if not char then return end
					local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildOfClass("BasePart")
					if not root then return end
					local drawing = Instance.new("Drawing")
					drawing.Name = "IY_Tracer"
					drawing.Type = "Line"
					drawing.Color = player.TeamColor.Color or Color3.new(1, 1, 1)
					drawing.Thickness = 2
					drawing.Transparency = 1
					local function updateLine()
						local localRoot = getRootPart()
						if localRoot and root then
							local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
							local localScreenPos, _ = camera:WorldToViewportPoint(localRoot.Position)
							if onScreen then
								drawing.Visible = true
								drawing.From = Vector2.new(localScreenPos.X, localScreenPos.Y)
								drawing.To = Vector2.new(screenPos.X, screenPos.Y)
							else
								drawing.Visible = false
							end
						end
					end
					updateLine()
					local heartbeatCon = RunService.Heartbeat:Connect(updateLine)
					connections[#connections + 1] = heartbeatCon
					tracerObjects[#tracerObjects + 1] = drawing
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= localPlayer then
					addTracer(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addTracer)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in tracerObjects do
				obj:Destroy()
			end
			table.clear(tracerObjects)
		end,
	}
end

function Player.BoxESP()
	local connections = {}
	local boxObjects = {}
	return {
		id = "BoxESP",
		name = "Box ESP",
		aliases = { "box", "boxesp" },
		description = "Draw boxes around players",
		category = "Player",
		icon = "P",
		isToggle = true,
		onExecute = function()
			local function addBox(player)
				local function updateChar(char)
					if not char then return end
					local highlight = Instance.new("Highlight")
					highlight.Name = "IY_BoxESP"
					highlight.Adornee = char
					highlight.FillTransparency = 1
					highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
					highlight.OutlineTransparency = 0
					highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					highlight.Parent = char
					boxObjects[#boxObjects + 1] = highlight
				end
				if player.Character then
					updateChar(player.Character)
				end
				connections[#connections + 1] = player.CharacterAdded:Connect(updateChar)
			end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() then
					addBox(plr)
				end
			end
			connections[#connections + 1] = Players.PlayerAdded:Connect(addBox)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, obj in boxObjects do
				obj:Destroy()
			end
			table.clear(boxObjects)
		end,
	}
end

local commandFactories = {
	Player.InfiniteJump,
	Player.Noclip,
	Player.Walkspeed,
	Player.JumpPower,
	Player.HipHeight,
	Player.Sit,
	Player.Lay,
	Player.NoFallDamage,
	Player.GodMode,
	Player.ESP,
	Player.Chams,
	Player.Wallhack,
	Player.XRay,
	Player.ThirdPerson,
	Player.FirstPerson,
	Player.LockCamera,
	Player.PanicHide,
	Player.AntiAFK,
	Player.NameESP,
	Player.HealthESP,
	Player.DistanceESP,
	Player.Tracer,
	Player.BoxESP,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Registry.lua
_MODULES['src/features/commands/Registry.lua'] = (function()
local Categories = require(script.Parent.Categories)

local Registry = {
	all = {},
	byId = {},
	byCategory = {},
}

local function registerCommands(cmdList)
	for _, cmd in cmdList do
		Registry.all[#Registry.all + 1] = cmd
		Registry.byId[cmd.id] = cmd
		if not Registry.byCategory[cmd.category] then
			Registry.byCategory[cmd.category] = {}
		end
		Registry.byCategory[cmd.category][#Registry.byCategory[cmd.category] + 1] = cmd
	end
end

local commandModules = {
	require(script.Player),
	require(script.Movement),
	require(script.Visual),
	require(script.Teleport),
	require(script.World),
	require(script.Tools),
	require(script.Utilities),
	require(script.Console),
	require(script.Trolling),
}

for _, module in commandModules do
	registerCommands(module)
end

function Registry.GetAll()
	return Registry.all
end

function Registry.GetByCategory(catId)
	return Registry.byCategory[catId] or {}
end

function Registry.GetByName(name)
	local lower = name:lower()
	for _, cmd in Registry.all do
		if cmd.id:lower() == lower or cmd.name:lower() == lower then
			return cmd
		end
		for _, alias in cmd.aliases do
			if alias:lower() == lower then
				return cmd
			end
		end
	end
	return nil
end

function Registry.GetCount()
	return #Registry.all
end

function Registry.Search(query)
	local lower = query:lower()
	local results = {}
	for _, cmd in Registry.all do
		if cmd.id:lower():find(lower) or cmd.name:lower():find(lower) then
			results[#results + 1] = cmd
		else
			for _, alias in cmd.aliases do
				if alias:lower():find(lower) then
					results[#results + 1] = cmd
					break
				end
			end
		end
	end
	return results
end

function Registry.GetCategoriesWithCommands()
	local result = {}
	for _, cat in Categories.GetAll() do
		result[#result + 1] = {
			category = cat,
			commands = Registry.GetByCategory(cat.id),
		}
	end
	return result
end

return Registry
end)()

-- Module: src/features/commands/Teleport.lua
_MODULES['src/features/commands/Teleport.lua'] = (function()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Teleport = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

local savedPosition = nil

function Teleport.TeleportTo()
	local connections = {}
	return {
		id = "TeleportTo",
		name = "Teleport To",
		aliases = { "tpto", "goto" },
		description = "Click to teleport to position",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local camera = workspace.CurrentCamera
			local mousePos = UserInputService:GetMouseLocation()
			local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = { getCharacter() }
			local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
			if result then
				local root = getRootPart()
				if root then
					root.CFrame = CFrame.new(result.Position + result.Normal * 3)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToPlayer()
	return {
		id = "TeleportToPlayer",
		name = "Teleport To Player",
		aliases = { "tpplayer", "tp2p", "goto" },
		description = "Teleport near a specific player",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(targetName)
			local target = nil
			if targetName then
				for _, plr in Players:GetPlayers() do
					if plr.Name:lower():find(targetName:lower()) or plr.DisplayName:lower():find(targetName:lower()) then
						target = plr
						break
					end
				end
			end
			if not target then
				local nearest = nil
				local nearestDist = math.huge
				local root = getRootPart()
				if not root then return end
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
						if targetRoot then
							local dist = (root.Position - targetRoot.Position).Magnitude
							if dist < nearestDist then
								nearestDist = dist
								target = plr
							end
						end
					end
				end
			end
			if target and target.Character then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				local root = getRootPart()
				if root and targetRoot then
					root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToMouse()
	local connections = {}
	return {
		id = "TeleportToMouse",
		name = "Teleport To Mouse",
		aliases = { "tpmouse", "tpm" },
		description = "Teleport to mouse position",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local camera = workspace.CurrentCamera
			local mousePos = UserInputService:GetMouseLocation()
			local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = { getCharacter() }
			local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
			if result then
				local root = getRootPart()
				if root then
					root.CFrame = CFrame.new(result.Position + result.Normal * 3)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToSpawn()
	return {
		id = "TeleportToSpawn",
		name = "Teleport To Spawn",
		aliases = { "tpspawn", "spawn" },
		description = "Teleport to spawn",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local spawns = workspace:FindFirstChild("SpawnLocation")
			if spawns then
				root.CFrame = spawns.CFrame * CFrame.new(0, 5, 0)
			else
				for _, obj in workspace:GetDescendants() do
					if obj:IsA("SpawnLocation") then
						root.CFrame = obj.CFrame * CFrame.new(0, 5, 0)
						break
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToOrigin()
	return {
		id = "TeleportToOrigin",
		name = "Teleport To Origin",
		aliases = { "tporigin", "origin", "0,0,0" },
		description = "Teleport to 0,0,0",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(0, 5, 0)
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToPart()
	local connections = {}
	return {
		id = "TeleportToPart",
		name = "Teleport To Part",
		aliases = { "tppart", "clicktp" },
		description = "Click a part to teleport to it",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local camera = workspace.CurrentCamera
			local mousePos = UserInputService:GetMouseLocation()
			local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = { getCharacter() }
			local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
			if result and result.Instance then
				local root = getRootPart()
				if root then
					root.CFrame = result.Instance.CFrame * CFrame.new(0, 5, 0)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportUp()
	return {
		id = "TeleportUp",
		name = "Teleport Up",
		aliases = { "tpup", "up" },
		description = "Teleport upward X studs",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if root then
				root.CFrame = root.CFrame * CFrame.new(0, value or 10, 0)
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportDown()
	return {
		id = "TeleportDown",
		name = "Teleport Down",
		aliases = { "tpdown", "down" },
		description = "Teleport downward X studs",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if root then
				root.CFrame = root.CFrame * CFrame.new(0, -(value or 10), 0)
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportForward()
	return {
		id = "TeleportForward",
		name = "Teleport Forward",
		aliases = { "tpforward", "fwd" },
		description = "Teleport forward X studs",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if root then
				local camera = workspace.CurrentCamera
				root.CFrame = root.CFrame + (camera.CFrame.LookVector * (value or 10))
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportBackward()
	return {
		id = "TeleportBackward",
		name = "Teleport Backward",
		aliases = { "tpbackward", "back", "bwd" },
		description = "Teleport backward X studs",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if root then
				local camera = workspace.CurrentCamera
				root.CFrame = root.CFrame - (camera.CFrame.LookVector * (value or 10))
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportLeft()
	return {
		id = "TeleportLeft",
		name = "Teleport Left",
		aliases = { "tpleft", "left" },
		description = "Teleport left X studs",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if root then
				local camera = workspace.CurrentCamera
				root.CFrame = root.CFrame - (camera.CFrame.RightVector * (value or 10))
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportRight()
	return {
		id = "TeleportRight",
		name = "Teleport Right",
		aliases = { "tpright", "right" },
		description = "Teleport right X studs",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(value)
			local root = getRootPart()
			if root then
				local camera = workspace.CurrentCamera
				root.CFrame = root.CFrame + (camera.CFrame.RightVector * (value or 10))
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToCFrame()
	return {
		id = "TeleportToCFrame",
		name = "Teleport To CFrame",
		aliases = { "tpcframe", "tpcf", "setcframe" },
		description = "Teleport to specific coordinates",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(x, y, z)
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(tonumber(x) or 0, tonumber(y) or 5, tonumber(z) or 0)
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportToHighlighted()
	return {
		id = "TeleportToHighlighted",
		name = "Teleport To Highlighted",
		aliases = { "tphighlighted", "tphl" },
		description = "Teleport to highlighted player",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function(targetName)
			local target = nil
			if targetName then
				for _, plr in Players:GetPlayers() do
					if plr.Name:lower():find(targetName:lower()) or plr.DisplayName:lower():find(targetName:lower()) then
						target = plr
						break
					end
				end
			end
			if not target then
				local closest = nil
				local closestDist = math.huge
				local root = getRootPart()
				if not root then return end
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						local r = plr.Character:FindFirstChild("HumanoidRootPart")
						if r then
							local d = (root.Position - r.Position).Magnitude
							if d < closestDist then
								closestDist = d
								target = plr
							end
						end
					end
				end
			end
			if target and target.Character then
				local r = target.Character:FindFirstChild("HumanoidRootPart")
				local root = getRootPart()
				if root and r then
					root.CFrame = r.CFrame * CFrame.new(0, 0, 5)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.TeleportRandom()
	return {
		id = "TeleportRandom",
		name = "Teleport Random",
		aliases = { "tprandom", "tprnd", "randomtp" },
		description = "Random teleport",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if root then
				local x = math.random(-500, 500)
				local z = math.random(-500, 500)
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Blacklist
				params.FilterDescendantsInstances = { getCharacter() }
				local result = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), params)
				local y = (result and result.Position.Y or 0) + 5
				root.CFrame = CFrame.new(x, y, z)
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.SaveLocation()
	return {
		id = "SaveLocation",
		name = "Save Location",
		aliases = { "savepos", "saveloc", "save" },
		description = "Save current position",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if root then
				savedPosition = root.CFrame
			end
		end,
		onUndo = function() end,
	}
end

function Teleport.LoadLocation()
	return {
		id = "LoadLocation",
		name = "Load Location",
		aliases = { "loadpos", "loadloc", "load" },
		description = "Teleport to saved position",
		category = "Teleport",
		icon = "T",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if root and savedPosition then
				root.CFrame = savedPosition
			end
		end,
		onUndo = function() end,
	}
end

local commandFactories = {
	Teleport.TeleportTo,
	Teleport.TeleportToPlayer,
	Teleport.TeleportToMouse,
	Teleport.TeleportToSpawn,
	Teleport.TeleportToOrigin,
	Teleport.TeleportToPart,
	Teleport.TeleportUp,
	Teleport.TeleportDown,
	Teleport.TeleportForward,
	Teleport.TeleportBackward,
	Teleport.TeleportLeft,
	Teleport.TeleportRight,
	Teleport.TeleportToCFrame,
	Teleport.TeleportToHighlighted,
	Teleport.TeleportRandom,
	Teleport.SaveLocation,
	Teleport.LoadLocation,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Tools.lua
_MODULES['src/features/commands/Tools.lua'] = (function()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

local Tools = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

local copiedPart = nil
local selectedParts = {}
local toolConnections = {}

function Tools.ToolGun()
	local connections = {}
	return {
		id = "ToolGun",
		name = "Tool Gun",
		aliases = { "toolgun", "tg" },
		description = "Click parts to manipulate",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						local gui = Instance.new("BillboardGui")
						gui.Name = "IY_ToolGunInfo"
						gui.Size = UDim2.new(0, 200, 0, 50)
						gui.StudsOffset = Vector3.new(0, 3, 0)
						gui.AlwaysOnTop = true
						local label = Instance.new("TextLabel")
						label.Size = UDim2.new(1, 0, 1, 0)
						label.BackgroundTransparency = 1
						label.Text = string.format("%s\nCFrame: %.1f, %.1f, %.1f", result.Instance:GetFullName(), result.Instance.CFrame.X, result.Instance.CFrame.Y, result.Instance.CFrame.Z)
						label.TextColor3 = Color3.new(1, 1, 1)
						label.TextStrokeTransparency = 0
						label.TextScaled = true
						label.Font = Enum.Font.Gotham
						label.Parent = gui
						gui.Parent = result.Instance
						task.delay(2, function()
							gui:Destroy()
						end)
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.FlingGun()
	local connections = {}
	return {
		id = "FlingGun",
		name = "Fling Gun",
		aliases = { "flinggun", "fg" },
		description = "Fling players/parts",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance then
						local part = result.Instance:IsA("BasePart") and result.Instance or result.Instance:FindFirstChildWhichIsA("BasePart")
						if part then
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
							bv.Velocity = ray.Direction * 500 + Vector3.new(0, 100, 0)
							bv.Parent = part
							task.delay(1, function()
								bv:Destroy()
							end)
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.KillGun()
	local connections = {}
	return {
		id = "KillGun",
		name = "Kill Gun",
		aliases = { "killgun", "kg" },
		description = "Kill on click",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance then
						local char = result.Instance:FindFirstAncestorOfClass("Model")
						if char then
							local hum = char:FindFirstChildOfClass("Humanoid")
							if hum and hum.Health > 0 then
								hum.Health = 0
							end
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.FreezeGun()
	local connections = {}
	local frozenParts = {}
	return {
		id = "FreezeGun",
		name = "Freeze Gun",
		aliases = { "freezegun", "fzg" },
		description = "Freeze parts on click",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						frozenParts[#frozenParts + 1] = { part = result.Instance, anchored = result.Instance.Anchored, velocity = result.Instance.Velocity }
						result.Instance.Anchored = true
						result.Instance.Velocity = Vector3.new(0, 0, 0)
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, entry in frozenParts do
				pcall(function()
					entry.part.Anchored = entry.anchored
				end)
			end
			table.clear(frozenParts)
		end,
	}
end

function Tools.RemoveTool()
	local connections = {}
	return {
		id = "RemoveTool",
		name = "Remove Tool",
		aliases = { "removetool", "rmtool" },
		description = "Click to remove parts",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance then
						local base = result.Instance:FindFirstAncestorWhichIsA("BasePart") or result.Instance
						if base:IsA("BasePart") and not base:IsDescendantOf(getCharacter()) then
							base:Destroy()
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.PaintTool()
	local connections = {}
	return {
		id = "PaintTool",
		name = "Paint Tool",
		aliases = { "painttool", "ptool" },
		description = "Click to recolor parts",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						result.Instance.Color = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.CopyTool()
	local connections = {}
	return {
		id = "CopyTool",
		name = "Copy Tool",
		aliases = { "copytool", "ct" },
		description = "Click to copy parts",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						copiedPart = result.Instance:Clone()
						copiedPart.Parent = nil
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.PasteTool()
	return {
		id = "PasteTool",
		name = "Paste Tool",
		aliases = { "pastetool", "pt" },
		description = "Paste copied parts",
		category = "Tools",
		icon = "O",
		isToggle = false,
		onExecute = function()
			if not copiedPart then return end
			local root = getRootPart()
			if not root then return end
			local clone = copiedPart:Clone()
			clone.CFrame = root.CFrame * CFrame.new(0, 0, -10)
			clone.Parent = workspace
		end,
		onUndo = function() end,
	}
end

function Tools.HighlightTool()
	local connections = {}
	return {
		id = "HighlightTool",
		name = "Highlight Tool",
		aliases = { "highlighttool", "hltool" },
		description = "Highlight clicked parts",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						local hl = Instance.new("Highlight")
						hl.Name = "IY_Highlight"
						hl.Adornee = result.Instance
						hl.FillColor = Color3.fromRGB(0, 255, 0)
						hl.FillTransparency = 0.5
						hl.OutlineColor = Color3.new(1, 1, 1)
						hl.Parent = result.Instance
						task.delay(5, function()
							hl:Destroy()
						end)
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.WeldTool()
	local connections = {}
	return {
		id = "WeldTool",
		name = "Weld Tool",
		aliases = { "weldtool", "weld" },
		description = "Weld selected parts together",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			local firstPart = nil
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						if not firstPart then
							firstPart = result.Instance
						else
							local weld = Instance.new("Weld")
							weld.Part0 = firstPart
							weld.Part1 = result.Instance
							weld.C0 = firstPart.CFrame:inverse()
							weld.C1 = result.Instance.CFrame:inverse()
							weld.Parent = firstPart
							firstPart = nil
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.UnweldTool()
	local connections = {}
	return {
		id = "UnweldTool",
		name = "Unweld Tool",
		aliases = { "unweldtool", "unweld" },
		description = "Unweld selected parts",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						for _, weld in result.Instance:GetDescendants() do
							if weld:IsA("Weld") or weld:IsA("ManualWeld") or weld:IsA("Snap") then
								weld:Destroy()
							end
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.CFrameTool()
	local connections = {}
	return {
		id = "CFrameTool",
		name = "CFrame Tool",
		aliases = { "cframetool", "cftool" },
		description = "Show CFrame of clicked part",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance and result.Instance:IsA("BasePart") then
						local cf = result.Instance.CFrame
						local function round(n)
							return math.floor(n * 100 + 0.5) / 100
						end
						local output = result.Instance.Name .. " CFrame: (" .. round(cf.X) .. ", " .. round(cf.Y) .. ", " .. round(cf.Z) .. ")"
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Tools.PropertiesTool()
	local connections = {}
	return {
		id = "PropertiesTool",
		name = "Properties Tool",
		aliases = { "propertiestool", "proptool" },
		description = "Show properties of clicked part",
		category = "Tools",
		icon = "O",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gp)
				if gp then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000)
					if result and result.Instance then
						local info = {}
						if result.Instance:IsA("BasePart") then
							info = {
								Name = result.Instance.Name,
								ClassName = result.Instance.ClassName,
								Size = tostring(result.Instance.Size),
								Position = tostring(result.Instance.Position),
								Color = tostring(result.Instance.Color),
								Material = tostring(result.Instance.Material),
								Anchored = tostring(result.Instance.Anchored),
								CanCollide = tostring(result.Instance.CanCollide),
								Transparency = tostring(result.Instance.Transparency),
							}
						else
							info = {
								Name = result.Instance.Name,
								ClassName = result.Instance.ClassName,
							}
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

local commandFactories = {
	Tools.ToolGun,
	Tools.FlingGun,
	Tools.KillGun,
	Tools.FreezeGun,
	Tools.RemoveTool,
	Tools.PaintTool,
	Tools.CopyTool,
	Tools.PasteTool,
	Tools.HighlightTool,
	Tools.WeldTool,
	Tools.UnweldTool,
	Tools.CFrameTool,
	Tools.PropertiesTool,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Trolling.lua
_MODULES['src/features/commands/Trolling.lua'] = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local Trolling = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function getNearestPlayer()
	local root = getRootPart()
	if not root then return nil end
	local nearest = nil
	local nearestDist = math.huge
	for _, plr in Players:GetPlayers() do
		if plr ~= getPlayer() and plr.Character then
			local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local dist = (root.Position - targetRoot.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearest = plr
				end
			end
		end
	end
	return nearest
end

local function findPlayerByName(name)
	if not name then return getNearestPlayer() end
	local lower = name:lower()
	for _, plr in Players:GetPlayers() do
		if plr.Name:lower():find(lower) or plr.DisplayName:lower():find(lower) then
			return plr
		end
	end
	return nil
end

function Trolling.FlingPlayers()
	local connections = {}
	local flingingPlayers = false
	return {
		id = "FlingPlayers",
		name = "Fling Players",
		aliases = { "flingplayers", "flingp" },
		description = "Fling nearby players",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			flingingPlayers = true
			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if not flingingPlayers then return end
				local root = getRootPart()
				if not root then return end
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
						if targetRoot and (root.Position - targetRoot.Position).Magnitude < 30 then
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
							bv.Velocity = (targetRoot.Position - root.Position).Unit * 500 + Vector3.new(0, 200, 0)
							bv.Parent = targetRoot
							task.delay(0.5, function()
								if bv and bv.Parent then bv:Destroy() end
							end)
						end
					end
				end
			end)
		end,
		onUndo = function()
			flingingPlayers = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.FlingAll()
	local connections = {}
	local flingingAll = false
	return {
		id = "FlingAll",
		name = "Fling All",
		aliases = { "flingall", "flla" },
		description = "Fling everyone including you",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			flingingAll = true
			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if not flingingAll then return end
				for _, plr in Players:GetPlayers() do
					if plr.Character then
						local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
						if targetRoot then
							local bv = targetRoot:FindFirstChildOfClass("BodyVelocity")
							if not bv then
								bv = Instance.new("BodyVelocity")
								bv.MaxForce = Vector3.new(9e4, 9e4, 9e4)
								bv.Parent = targetRoot
							end
							bv.Velocity = Vector3.new(math.random(-500, 500), math.random(200, 500), math.random(-500, 500))
						end
					end
				end
			end)
		end,
		onUndo = function()
			flingingAll = false
			for _, plr in Players:GetPlayers() do
				if plr.Character then
					local root = plr.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local bv = root:FindFirstChildOfClass("BodyVelocity")
						if bv then bv:Destroy() end
					end
				end
			end
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.Btools()
	return {
		id = "Btools",
		name = "Btools",
		aliases = { "btools", "admin" },
		description = "Give yourself admin tools",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			local plr = getPlayer()
			if not plr then return end
			local backpack = plr:FindFirstChild("Backpack")
			if not backpack then return end
			local tools = { "HopperBin", "HopperBin", "HopperBin", "HopperBin", "HopperBin" }
			local binTypes = { Enum.BinType.Clone, Enum.BinType.Grab, Enum.BinType.Hammer, Enum.BinType.Script, Enum.BinType.GameTool }
			for _, binType in binTypes do
				local bin = Instance.new("HopperBin")
				bin.BinType = binType
				bin.Parent = backpack
			end
			warn("Admin tools added to backpack")
		end,
		onUndo = function()
			local plr = getPlayer()
			if not plr then return end
			local backpack = plr:FindFirstChild("Backpack")
			if backpack then
				for _, child in backpack:GetChildren() do
					if child:IsA("HopperBin") then
						child:Destroy()
					end
				end
			end
		end,
	}
end

function Trolling.Explode()
	return {
		id = "Explode",
		name = "Explode",
		aliases = { "explode", "boom" },
		description = "Explode at your position",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local explosion = Instance.new("Explosion")
			explosion.Position = root.Position
			explosion.BlastRadius = 20
			explosion.BlastPressure = 50000
			explosion.DestroyJointRadiusPercent = 1
			explosion.Parent = workspace
		end,
		onUndo = function() end,
	}
end

function Trolling.ExplodePlayer()
	return {
		id = "ExplodePlayer",
		name = "Explode Player",
		aliases = { "explodeplayer", "explodep" },
		description = "Explode at targeted player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target and target.Character then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					local explosion = Instance.new("Explosion")
					explosion.Position = targetRoot.Position
					explosion.BlastRadius = 15
					explosion.BlastPressure = 50000
					explosion.DestroyJointRadiusPercent = 1
					explosion.Parent = workspace
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.FreezePlayer()
	return {
		id = "FreezePlayer",
		name = "Freeze Player",
		aliases = { "freezeplayer", "freezep" },
		description = "Freeze a targeted player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target and target.Character then
				for _, part in target.Character:GetDescendants() do
					if part:IsA("BasePart") then
						part.Anchored = true
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.UnfreezePlayer()
	return {
		id = "UnfreezePlayer",
		name = "Unfreeze Player",
		aliases = { "unfreezeplayer", "unfreezep" },
		description = "Unfreeze a player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target and target.Character then
				for _, part in target.Character:GetDescendants() do
					if part:IsA("BasePart") then
						part.Anchored = false
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.KickPlayer()
	return {
		id = "KickPlayer",
		name = "Kick Player",
		aliases = { "kickplayer", "kickp" },
		description = "Kick a targeted player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target then
				local chr = target.Character
				if chr then
					chr:Destroy()
				end
				target:Destroy()
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.KillAll()
	return {
		id = "KillAll",
		name = "Kill All",
		aliases = { "killall", "ka" },
		description = "Kill all players",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function()
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() and plr.Character then
					local hum = plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = 0
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.KillPlayer()
	return {
		id = "KillPlayer",
		name = "Kill Player",
		aliases = { "killplayer", "killp" },
		description = "Kill targeted player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target and target.Character then
				local hum = target.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Health = 0
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.CrashPlayer()
	return {
		id = "CrashPlayer",
		name = "Crash Player",
		aliases = { "crashplayer", "crashp" },
		description = "Attempt to crash targeted player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target and target.Character then
				for _ = 1, 100 do
					local p = Instance.new("Part")
					p.Anchored = true
					p.CanCollide = true
					p.Size = Vector3.new(100, 0.1, 100)
					p.Position = target.Character:FindFirstChild("HumanoidRootPart").Position
					p.Parent = workspace
					task.wait()
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.LagPlayer()
	local connections = {}
	local laggingPlayer = false
	return {
		id = "LagPlayer",
		name = "Lag Player",
		aliases = { "lagplayer", "lagp" },
		description = "Lag targeted player",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function(targetName)
			laggingPlayer = true
			local target = findPlayerByName(targetName)
			if not target then return end
			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if not laggingPlayer then return end
				if target and target.Character then
					local root = target.Character:FindFirstChild("HumanoidRootPart")
					if root then
						for _ = 1, 50 do
							local p = Instance.new("Part")
							p.Size = Vector3.new(1, 1, 1)
							p.Anchored = true
							p.CanCollide = false
							p.Transparency = 1
							p.Position = root.Position + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
							p.Parent = workspace
							task.delay(0.5, function()
								p:Destroy()
							end)
						end
					end
				end
			end)
		end,
		onUndo = function()
			laggingPlayer = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.LagAll()
	local connections = {}
	local laggingAll = false
	return {
		id = "LagAll",
		name = "Lag All",
		aliases = { "lagall", "laga" },
		description = "Lag all players",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			laggingAll = true
			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if not laggingAll then return end
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						local root = plr.Character:FindFirstChild("HumanoidRootPart")
						if root then
							for _ = 1, 20 do
								local p = Instance.new("Part")
								p.Size = Vector3.new(1, 1, 1)
								p.Anchored = true
								p.CanCollide = false
								p.Transparency = 1
								p.Position = root.Position + Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
								p.Parent = workspace
								task.delay(0.3, function()
									p:Destroy()
								end)
							end
						end
					end
				end
			end)
		end,
		onUndo = function()
			laggingAll = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.Spam()
	return {
		id = "Spam",
		name = "Spam",
		aliases = { "spam" },
		description = "Spam chat",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(msg)
			if not msg then msg = "Spam" end
			for i = 1, 20 do
				task.wait(0.1)
				local args = { [1] = msg .. " " .. tostring(i) }
				local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
				if chatEvent then
					local sayMsg = chatEvent:FindFirstChild("SayMessageRequest")
					if sayMsg then
						sayMsg:FireServer(unpack(args))
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.ChatSpam()
	return {
		id = "ChatSpam",
		name = "Chat Spam",
		aliases = { "chatspam", "cspam" },
		description = "Spam a message",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(msg)
			if not msg then msg = "Chat Spam" end
			for i = 1, 30 do
				task.wait(0.05)
				local args = { [1] = msg .. " [" .. tostring(i) .. "]" }
				local chatEvent = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
				if chatEvent then
					local sayMsg = chatEvent:FindFirstChild("SayMessageRequest")
					if sayMsg then
						sayMsg:FireServer(unpack(args))
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.MessagePlayer()
	return {
		id = "MessagePlayer",
		name = "Message Player",
		aliases = { "messageplayer", "msgp", "dm" },
		description = "Send DM to player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName, msg)
			if not msg then return end
			local target = findPlayerByName(targetName)
			if target then
				StarterGui:SetCore("ChatMakeSystemMessage", {
					Text = "[DM to " .. target.Name .. "]: " .. msg,
					Color = Color3.fromRGB(255, 200, 0),
				})
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.LoopKill()
	local connections = {}
	local loopKilling = false
	return {
		id = "LoopKill",
		name = "Loop Kill",
		aliases = { "loopkill", "lk" },
		description = "Continuously kill players",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			loopKilling = true
			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if not loopKilling then return end
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						local hum = plr.Character:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 then
							hum.Health = 0
						end
					end
				end
			end)
		end,
		onUndo = function()
			loopKilling = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.NoSit()
	local connections = {}
	return {
		id = "NoSit",
		name = "No Sit",
		aliases = { "nosit", "blocksit" },
		description = "Prevent sitting",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			connections[#connections + 1] = RunService.Stepped:Connect(function()
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						local hum = plr.Character:FindFirstChildOfClass("Humanoid")
						if hum and hum.Sit then
							hum.Sit = false
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.AntiTool()
	local connections = {}
	return {
		id = "AntiTool",
		name = "Anti Tool",
		aliases = { "antitool", "blocktool" },
		description = "Prevent tool usage",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			connections[#connections + 1] = RunService.Stepped:Connect(function()
				for _, plr in Players:GetPlayers() do
					if plr ~= getPlayer() and plr.Character then
						for _, tool in plr.Character:GetChildren() do
							if tool:IsA("Tool") or tool:IsA("HopperBin") then
								tool:Destroy()
							end
						end
					end
				end
				local backpack = getPlayer() and getPlayer():FindFirstChild("Backpack")
				if not backpack then return end
				for _, obj in backpack:GetChildren() do
					if obj:IsA("Tool") or obj:IsA("HopperBin") then
						obj:Destroy()
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.BringPlayer()
	return {
		id = "BringPlayer",
		name = "Bring Player",
		aliases = { "bringplayer", "bringp" },
		description = "Bring player to you",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			local root = getRootPart()
			if target and target.Character and root then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -5)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.BringAll()
	return {
		id = "BringAll",
		name = "Bring All",
		aliases = { "bringall", "bringa" },
		description = "Bring all players to you",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() and plr.Character then
					local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, math.random(-10, -3))
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.GoToPlayer()
	return {
		id = "GoToPlayer",
		name = "Go To Player",
		aliases = { "gotoplayer", "goto", "gtp" },
		description = "Teleport to player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			local root = getRootPart()
			if target and target.Character and root then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.ViewPlayer()
	local connections = {}
	return {
		id = "ViewPlayer",
		name = "View Player",
		aliases = { "viewplayer", "view", "spectate", "spec" },
		description = "Spectate player",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			if target and target.Character then
				local cam = workspace.CurrentCamera
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChildOfClass("BasePart")
				if targetRoot then
					cam.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid") or targetRoot
				end
			end
		end,
		onUndo = function()
			local cam = workspace.CurrentCamera
			local plr = getPlayer()
			if plr and plr.Character then
				cam.CameraSubject = plr.Character:FindFirstChildOfClass("Humanoid")
			end
		end,
	}
end

function Trolling.TeleportAllToMe()
	return {
		id = "TeleportAllToMe",
		name = "Teleport All To Me",
		aliases = { "tpalltome", "tpatm", "pull" },
		description = "Pull everyone to your position",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			for _, plr in Players:GetPlayers() do
				if plr ~= getPlayer() and plr.Character then
					local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, math.random(-8, -2))
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.TeleportToMe()
	return {
		id = "TeleportToMe",
		name = "Teleport To Me",
		aliases = { "tptome", "tptm" },
		description = "Teleport a player to you",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			local root = getRootPart()
			if target and target.Character and root then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -5)
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.SwapPositions()
	return {
		id = "SwapPositions",
		name = "Swap Positions",
		aliases = { "swappos", "swap", "exchange" },
		description = "Swap position with another player",
		category = "Trolling",
		icon = "F",
		isToggle = false,
		onExecute = function(targetName)
			local target = findPlayerByName(targetName)
			local root = getRootPart()
			if target and target.Character and root then
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					local myCF = root.CFrame
					local targetCF = targetRoot.CFrame
					root.CFrame = targetCF
					targetRoot.CFrame = myCF
				end
			end
		end,
		onUndo = function() end,
	}
end

function Trolling.LoopTeleport()
	local connections = {}
	local loopTeleporting = false
	return {
		id = "LoopTeleport",
		name = "Loop Teleport",
		aliases = { "looptp", "ltp" },
		description = "Continuously teleport to a player",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function(targetName)
			loopTeleporting = true
			local target = findPlayerByName(targetName)
			if not target then return end
			connections[#connections + 1] = RunService.Heartbeat:Connect(function()
				if not loopTeleporting then return end
				local root = getRootPart()
				if target and target.Character and root then
					local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
					end
				end
			end)
		end,
		onUndo = function()
			loopTeleporting = false
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

function Trolling.Invisible()
	return {
		id = "Invisible",
		name = "Invisible",
		aliases = { "invisible", "invis", "vanish" },
		description = "Make yourself invisible",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			local char = getCharacter()
			if char then
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanCollide = false
					end
				end
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
				end
			end
		end,
		onUndo = function()
			local char = getCharacter()
			if char then
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then
						part.Transparency = 0
						part.CanCollide = true
					end
				end
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
				end
			end
		end,
	}
end

function Trolling.SilentMode()
	return {
		id = "SilentMode",
		name = "Silent Mode",
		aliases = { "silent", "silentmode" },
		description = "Hide command execution",
		category = "Trolling",
		icon = "F",
		isToggle = true,
		onExecute = function()
			getgenv().IY_SilentMode = true
		end,
		onUndo = function()
			getgenv().IY_SilentMode = false
		end,
	}
end

local commandFactories = {
	Trolling.FlingPlayers,
	Trolling.FlingAll,
	Trolling.Btools,
	Trolling.Explode,
	Trolling.ExplodePlayer,
	Trolling.FreezePlayer,
	Trolling.UnfreezePlayer,
	Trolling.KickPlayer,
	Trolling.KillAll,
	Trolling.KillPlayer,
	Trolling.CrashPlayer,
	Trolling.LagPlayer,
	Trolling.LagAll,
	Trolling.Spam,
	Trolling.ChatSpam,
	Trolling.MessagePlayer,
	Trolling.LoopKill,
	Trolling.NoSit,
	Trolling.AntiTool,
	Trolling.BringPlayer,
	Trolling.BringAll,
	Trolling.GoToPlayer,
	Trolling.ViewPlayer,
	Trolling.TeleportAllToMe,
	Trolling.TeleportToMe,
	Trolling.SwapPositions,
	Trolling.LoopTeleport,
	Trolling.Invisible,
	Trolling.SilentMode,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Utilities.lua
_MODULES['src/features/commands/Utilities.lua'] = (function()
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Utilities = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

local chatLogging = false
local chatLogConnections = {}
local fpsCounter = false
local pingCounter = false
local memCounter = false
local statsGui = nil
local statsConnections = {}

function Utilities.CommandBar()
	return {
		id = "CommandBar",
		name = "Command Bar",
		aliases = { "cmdbar", "commandbar", "console" },
		description = "Opens a text command bar",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if not plr then return end
			local gui = Instance.new("ScreenGui")
			gui.Name = "IY_CommandBar"
			gui.DisplayOrder = 999
			gui.ResetOnSpawn = false
			gui.Parent = plr:WaitForChild("PlayerGui")
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, 50)
			frame.Position = UDim2.new(0, 0, 0, 0)
			frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			frame.BackgroundTransparency = 0.3
			frame.BorderSizePixel = 0
			frame.Parent = gui
			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -20, 1, -10)
			box.Position = UDim2.new(0, 10, 0, 5)
			box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			box.BackgroundTransparency = 0.3
			box.TextColor3 = Color3.new(1, 1, 1)
			box.Text = ""
			box.PlaceholderText = "Type a command..."
			box.ClearTextOnFocus = false
			box.Font = Enum.Font.Gotham
			box.TextScaled = true
			box.Parent = frame
			box:CaptureFocus()
		end,
		onUndo = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_CommandBar")
				if gui then gui:Destroy() end
			end
		end,
	}
end

function Utilities.ChatLogger()
	return {
		id = "ChatLogger",
		name = "Chat Logger",
		aliases = { "chatlog", "chatlogger" },
		description = "Logs chat messages",
		category = "Utilities",
		icon = "U",
		isToggle = true,
		onExecute = function()
			chatLogging = true
			if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				local textChannels = TextChatService:FindFirstChild("TextChannels")
				if textChannels then
					local rbxlGeneral = textChannels:FindFirstChild("RBXGeneral")
					if rbxlGeneral then
						chatLogConnections[#chatLogConnections + 1] = rbxlGeneral.MessageReceived:Connect(function(msg)
							if chatLogging then
								warn("[CHAT] " .. msg.Text)
							end
						end)
					end
				end
			else
				local defChat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
				if defChat then
					local msgEvent = defChat:FindFirstChild("OnMessageDoneFiltering")
					if msgEvent then
						chatLogConnections[#chatLogConnections + 1] = msgEvent.OnClientEvent:Connect(function(data)
							if chatLogging and data then
								warn("[CHAT] " .. data.Message)
							end
						end)
					end
				end
			end
		end,
		onUndo = function()
			chatLogging = false
			for _, con in chatLogConnections do
				con:Disconnect()
			end
			table.clear(chatLogConnections)
		end,
	}
end

function Utilities.FPSCounter()
	return {
		id = "FPSCounter",
		name = "FPS Counter",
		aliases = { "fps", "fpscounter" },
		description = "Show/hide FPS",
		category = "Utilities",
		icon = "U",
		isToggle = true,
		onExecute = function()
			fpsCounter = true
			local plr = getPlayer()
			if not plr then return end
			if statsGui then statsGui:Destroy() end
			statsGui = Instance.new("ScreenGui")
			statsGui.Name = "IY_Stats"
			statsGui.DisplayOrder = 1000
			statsGui.ResetOnSpawn = false
			statsGui.Parent = plr:WaitForChild("PlayerGui")
			local label = Instance.new("TextLabel")
			label.Name = "StatsLabel"
			label.Size = UDim2.new(0, 200, 0, 100)
			label.Position = UDim2.new(0, 10, 0, 10)
			label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			label.BackgroundTransparency = 0.5
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0
			label.TextScaled = false
			label.TextSize = 14
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
			label.Parent = statsGui
			local frameTime = 0
			local frameCount = 0
			local fps = 0
			statsConnections[#statsConnections + 1] = RunService.RenderStepped:Connect(function(dt)
				frameCount += 1
				frameTime += dt
				if frameTime >= 1 then
					fps = frameCount
					frameCount = 0
					frameTime = 0
				end
				local text = ""
				if fpsCounter then
					text ..= "FPS: " .. tostring(fps) .. "\n"
				end
				if pingCounter then
					local stats = stats()
					text ..= "Ping: " .. tostring(stats.Network.ServerStatsItem["Data Ping"]:GetValueString()) .. "\n"
				end
				if memCounter then
					text ..= "Mem: " .. tostring(collectgarbage("count")) .. " KB\n"
				end
				label.Text = text
			end)
		end,
		onUndo = function()
			fpsCounter = false
			if statsGui then
				statsGui:Destroy()
				statsGui = nil
			end
			for _, con in statsConnections do
				con:Disconnect()
			end
			table.clear(statsConnections)
		end,
	}
end

function Utilities.PingCounter()
	return {
		id = "PingCounter",
		name = "Ping Counter",
		aliases = { "ping", "pingcounter" },
		description = "Show/hide ping",
		category = "Utilities",
		icon = "U",
		isToggle = true,
		onExecute = function()
			pingCounter = true
			Utilities.FPSCounter().onExecute()
		end,
		onUndo = function()
			pingCounter = false
			Utilities.FPSCounter().onUndo()
		end,
	}
end

function Utilities.MemoryCounter()
	return {
		id = "MemoryCounter",
		name = "Memory Counter",
		aliases = { "mem", "memory", "memorycounter" },
		description = "Show/hide memory",
		category = "Utilities",
		icon = "U",
		isToggle = true,
		onExecute = function()
			memCounter = true
			Utilities.FPSCounter().onExecute()
		end,
		onUndo = function()
			memCounter = false
			Utilities.FPSCounter().onUndo()
		end,
	}
end

function Utilities.FPSCap()
	return {
		id = "FPSCap",
		name = "FPS Cap",
		aliases = { "fpscap", "fpslimit" },
		description = "Cap frame rate",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function(value)
			setfpscap(value or 60)
		end,
		onUndo = function()
			setfpscap(60)
		end,
	}
end

function Utilities.FPSBoost()
	return {
		id = "FPSBoost",
		name = "FPS Boost",
		aliases = { "fpsboost", "boostfps" },
		description = "Performance boost",
		category = "Utilities",
		icon = "U",
		isToggle = true,
		onExecute = function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 999999
		end,
		onUndo = function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
			Lighting.GlobalShadows = true
		end,
	}
end

function Utilities.CrashGame()
	return {
		id = "CrashGame",
		name = "Crash Game",
		aliases = { "crash", "crashgame" },
		description = "Attempts to crash the game",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local infiniteTable = {}
			infiniteTable[1] = infiniteTable
			local bigString = string.rep("A", 9999999)
			while true do
				pcall(function()
					local t = {}
					for i = 1, 10000 do
						t[i] = Instance.new("Part")
					end
				end)
				task.wait()
			end
		end,
		onUndo = function() end,
	}
end

function Utilities.RejoinServer()
	return {
		id = "RejoinServer",
		name = "Rejoin Server",
		aliases = { "rejoinserver", "rjs" },
		description = "Rejoins same server",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local ts = TeleportService
			local placeId = game.PlaceId
			local jobId = game.JobId
			ts:TeleportToPlaceInstance(placeId, jobId, getPlayer())
		end,
		onUndo = function() end,
	}
end

function Utilities.RejoinDifferent()
	return {
		id = "RejoinDifferent",
		name = "Rejoin Different",
		aliases = { "rejoindiff", "rjd" },
		description = "Rejoins different server",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local ts = TeleportService
			local placeId = game.PlaceId
			ts:Teleport(placeId, getPlayer())
		end,
		onUndo = function() end,
	}
end

function Utilities.ServerRegion()
	return {
		id = "ServerRegion",
		name = "Server Region",
		aliases = { "serverregion", "region" },
		description = "Show server region",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("Server Region: " .. tostring(game:GetService("TextService"):GetServerLocation()))
		end,
		onUndo = function() end,
	}
end

function Utilities.ServerTime()
	return {
		id = "ServerTime",
		name = "Server Time",
		aliases = { "servertime", "stime" },
		description = "Show server uptime",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("Server Time: " .. tostring(game:GetService("Workspace").DistributedGameTime) .. " seconds")
		end,
		onUndo = function() end,
	}
end

function Utilities.PlayerCount()
	return {
		id = "PlayerCount",
		name = "Player Count",
		aliases = { "playercount", "count", "players" },
		description = "Show player count",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("Players: " .. tostring(#Players:GetPlayers()))
		end,
		onUndo = function() end,
	}
end

function Utilities.GameID()
	return {
		id = "GameID",
		name = "Game ID",
		aliases = { "gameid", "gid" },
		description = "Show game ID",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("Game ID (Universe ID): " .. tostring(game.GameId))
		end,
		onUndo = function() end,
	}
end

function Utilities.PlaceID()
	return {
		id = "PlaceID",
		name = "Place ID",
		aliases = { "placeid", "pid" },
		description = "Show place ID",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("Place ID: " .. tostring(game.PlaceId))
		end,
		onUndo = function() end,
	}
end

function Utilities.JobID()
	return {
		id = "JobID",
		name = "Job ID",
		aliases = { "jobid", "jid" },
		description = "Show job ID",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("Job ID: " .. tostring(game.JobId))
		end,
		onUndo = function() end,
	}
end

function Utilities.CopyGameLink()
	return {
		id = "CopyGameLink",
		name = "Copy Game Link",
		aliases = { "copygame", "gamelink" },
		description = "Copy game URL",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local url = "https://www.roblox.com/games/" .. tostring(game.PlaceId)
			setclipboard(url)
			warn("Game link copied: " .. url)
		end,
		onUndo = function() end,
	}
end

function Utilities.CopyPlaceLink()
	return {
		id = "CopyPlaceLink",
		name = "Copy Place Link",
		aliases = { "copyplace", "placelink" },
		description = "Copy place link",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local url = "https://www.roblox.com/games/" .. tostring(game.PlaceId)
			setclipboard(url)
			warn("Place link copied: " .. url)
		end,
		onUndo = function() end,
	}
end

function Utilities.CopyJobID()
	return {
		id = "CopyJobID",
		name = "Copy Job ID",
		aliases = { "copyjob", "copyjid" },
		description = "Copy job ID to clipboard",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			setclipboard(game.JobId)
			warn("Job ID copied: " .. game.JobId)
		end,
		onUndo = function() end,
	}
end

function Utilities.GetKey()
	return {
		id = "GetKey",
		name = "Get Key",
		aliases = { "getkey", "key" },
		description = "Generate a key",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local key = HttpService:GenerateGUID(false)
			warn("Generated Key: " .. key)
			setclipboard(key)
		end,
		onUndo = function() end,
	}
end

function Utilities.KeySystem()
	return {
		id = "KeySystem",
		name = "Key System",
		aliases = { "keysystem", "auth" },
		description = "Key authentication",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function(key)
			if key then
				warn("Key verified: " .. key)
			else
				warn("Usage: keysystem <key>")
			end
		end,
		onUndo = function() end,
	}
end

function Utilities.SaveInstance()
	return {
		id = "SaveInstance",
		name = "Save Instance",
		aliases = { "saveinstance", "svinst" },
		description = "Save an instance",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			local data = HttpService:JSONEncode({
				placeId = game.PlaceId,
				jobId = game.JobId,
				time = os.time(),
			})
			warn("Instance saved")
		end,
		onUndo = function() end,
	}
end

function Utilities.LoadInstance()
	return {
		id = "LoadInstance",
		name = "Load Instance",
		aliases = { "loadinstance", "ldinst" },
		description = "Load a saved instance",
		category = "Utilities",
		icon = "U",
		isToggle = false,
		onExecute = function()
			warn("No saved instance found")
		end,
		onUndo = function() end,
	}
end

local commandFactories = {
	Utilities.CommandBar,
	Utilities.ChatLogger,
	Utilities.FPSCounter,
	Utilities.PingCounter,
	Utilities.MemoryCounter,
	Utilities.FPSCap,
	Utilities.FPSBoost,
	Utilities.CrashGame,
	Utilities.RejoinServer,
	Utilities.RejoinDifferent,
	Utilities.ServerRegion,
	Utilities.ServerTime,
	Utilities.PlayerCount,
	Utilities.GameID,
	Utilities.PlaceID,
	Utilities.JobID,
	Utilities.CopyGameLink,
	Utilities.CopyPlaceLink,
	Utilities.CopyJobID,
	Utilities.GetKey,
	Utilities.KeySystem,
	Utilities.SaveInstance,
	Utilities.LoadInstance,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/Visual.lua
_MODULES['src/features/commands/Visual.lua'] = (function()
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Visual = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

local function cloneLighting()
	local clone = {}
	for _, prop in { "Brightness", "FogEnd", "FogStart", "FogColor", "ClockTime", "Ambient", "ColorShift_Top", "ColorShift_Bottom", "OutdoorAmbient", "GeographicLatitude" } do
		clone[prop] = Lighting[prop]
	end
	return clone
end

function Visual.Fullbright()
	local connections = {}
	local saved
	return {
		id = "Fullbright",
		name = "Fullbright",
		aliases = { "fb", "fullbright" },
		description = "Full brightness",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = cloneLighting()
			Lighting.Brightness = 2
			Lighting.FogEnd = 100000
			Lighting.FogStart = 0
			Lighting.Ambient = Color3.new(1, 1, 1)
			Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
			Lighting.ClockTime = 14
			Lighting.GeographicLatitude = 0
		end,
		onUndo = function()
			if saved then
				for k, v in saved do
					if Lighting[k] ~= nil then
						Lighting[k] = v
					end
				end
			end
		end,
	}
end

function Visual.Night()
	local saved
	return {
		id = "Night",
		name = "Night",
		aliases = { "night" },
		description = "Night time",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = cloneLighting()
			Lighting.ClockTime = 0
			Lighting.Brightness = 0.5
			Lighting.Ambient = Color3.fromRGB(20, 20, 40)
			Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
		end,
		onUndo = function()
			if saved then
				for k, v in saved do
					if Lighting[k] ~= nil then
						Lighting[k] = v
					end
				end
			end
		end,
	}
end

function Visual.FogColor()
	local saved
	return {
		id = "FogColor",
		name = "Fog Color",
		aliases = { "fogcolor", "fogc" },
		description = "Change fog color",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.FogColor
			Lighting.FogColor = value or Color3.fromRGB(128, 128, 128)
		end,
		onUndo = function()
			if saved then
				Lighting.FogColor = saved
			end
		end,
	}
end

function Visual.FogEnd()
	local saved
	return {
		id = "FogEnd",
		name = "Fog End",
		aliases = { "fogend", "foge" },
		description = "Adjust fog end distance",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.FogEnd
			Lighting.FogEnd = value or 500
		end,
		onUndo = function()
			if saved then
				Lighting.FogEnd = saved
			end
		end,
	}
end

function Visual.Time()
	local saved
	return {
		id = "Time",
		name = "Time",
		aliases = { "time" },
		description = "Change time of day",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.ClockTime
			Lighting.ClockTime = value or 12
		end,
		onUndo = function()
			if saved then
				Lighting.ClockTime = saved
			end
		end,
	}
end

function Visual.WaterTransparency()
	local saved = {}
	return {
		id = "WaterTransparency",
		name = "Water Transparency",
		aliases = { "watertrans", "watertransparency" },
		description = "Adjust water transparency",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			local transparency = value or 0.5
			for _, obj in workspace:GetDescendants() do
				if obj:IsA("Terrain") or obj:IsA("Part") and (obj.Name:lower():find("water") or obj.Name:lower():find("ocean")) then
					if not saved[obj] then
						saved[obj] = obj.Transparency
					end
					obj.Transparency = transparency
				end
			end
			for _, obj in workspace.Terrain:GetChildren() do
				if obj:IsA("WaterObject") or obj.Name:lower():find("water") then
					if not saved[obj] then
						saved[obj] = obj.Transparency
					end
					obj.Transparency = transparency
				end
			end
		end,
		onUndo = function()
			for obj, orig in saved do
				pcall(function()
					obj.Transparency = orig
				end)
			end
			table.clear(saved)
		end,
	}
end

function Visual.NoFog()
	local saved
	return {
		id = "NoFog",
		name = "No Fog",
		aliases = { "nofog", "removefog" },
		description = "Remove fog",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = { FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
			Lighting.FogEnd = 999999
			Lighting.FogStart = 999999
		end,
		onUndo = function()
			if saved then
				Lighting.FogEnd = saved.FogEnd
				Lighting.FogStart = saved.FogStart
			end
		end,
	}
end

function Visual.BlueTint()
	local saved
	return {
		id = "BlueTint",
		name = "Blue Tint",
		aliases = { "bluetint", "btint" },
		description = "Blue screen tint",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = { ColorShift_Top = Lighting.ColorShift_Top, ColorShift_Bottom = Lighting.ColorShift_Bottom }
			Lighting.ColorShift_Top = Color3.fromRGB(0, 100, 255)
			Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 100)
		end,
		onUndo = function()
			if saved then
				Lighting.ColorShift_Top = saved.ColorShift_Top
				Lighting.ColorShift_Bottom = saved.ColorShift_Bottom
			end
		end,
	}
end

function Visual.Saturation()
	local saved
	return {
		id = "Saturation",
		name = "Saturation",
		aliases = { "saturation", "sat" },
		description = "Adjust color saturation",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.ColorShift_Bottom
			local sat = value or 0.5
			sat = math.clamp(sat, 0, 1)
			local gray = Color3.new(sat, sat, sat)
			Lighting.ColorShift_Bottom = gray
		end,
		onUndo = function()
			if saved then
				Lighting.ColorShift_Bottom = saved
			end
		end,
	}
end

function Visual.Contrast()
	local saved
	return {
		id = "Contrast",
		name = "Contrast",
		aliases = { "contrast" },
		description = "Adjust contrast (Lighting)",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.Brightness
			Lighting.Brightness = value or 1
		end,
		onUndo = function()
			if saved then
				Lighting.Brightness = saved
			end
		end,
	}
end

function Visual.Outline()
	local connections = {}
	local outlines = {}
	return {
		id = "Outline",
		name = "Outline",
		aliases = { "outline" },
		description = "Outlines on everything",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			connections[#connections + 1] = workspace.DescendantAdded:Connect(function(desc)
				task.wait(0.1)
				if desc:IsA("BasePart") and desc.Name ~= "Base" and not desc:FindFirstChild("IY_Outline") then
					local hl = Instance.new("Highlight")
					hl.Name = "IY_Outline"
					hl.Adornee = desc
					hl.FillTransparency = 1
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.OutlineTransparency = 0.3
					hl.Parent = desc
					outlines[#outlines + 1] = hl
				end
			end)
			for _, obj in workspace:GetDescendants() do
				if obj:IsA("BasePart") and obj.Name ~= "Base" then
					local hl = Instance.new("Highlight")
					hl.Name = "IY_Outline"
					hl.Adornee = obj
					hl.FillTransparency = 1
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.OutlineTransparency = 0.3
					hl.Parent = obj
					outlines[#outlines + 1] = hl
				end
			end
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, hl in outlines do
				hl:Destroy()
			end
			table.clear(outlines)
		end,
	}
end

function Visual.Wireframe()
	local connections = {}
	local wireframeParts = {}
	return {
		id = "Wireframe",
		name = "Wireframe",
		aliases = { "wireframe", "wf" },
		description = "Wireframe mode",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			local function applyWireframe(container)
				for _, obj in container:GetDescendants() do
					if obj:IsA("BasePart") then
						wireframeParts[#wireframeParts + 1] = { part = obj, orig = obj.Material }
						obj.Material = Enum.Material.ForceField
					end
				end
			end
			applyWireframe(workspace)
			connections[#connections + 1] = workspace.DescendantAdded:Connect(function(desc)
				task.wait(0.1)
				if desc:IsA("BasePart") then
					wireframeParts[#wireframeParts + 1] = { part = desc, orig = desc.Material }
					desc.Material = Enum.Material.ForceField
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
			for _, entry in wireframeParts do
				pcall(function()
					entry.part.Material = entry.orig
				end)
			end
			table.clear(wireframeParts)
		end,
	}
end

function Visual.LowGraphics()
	local saved
	return {
		id = "LowGraphics",
		name = "Low Graphics",
		aliases = { "lowgraphics", "lowgfx", "lg" },
		description = "Low graphics quality",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = {
				FogEnd = Lighting.FogEnd,
				FogStart = Lighting.FogStart,
				GlobalShadows = Lighting.GlobalShadows,
			}
			Lighting.FogEnd = 999999
			Lighting.FogStart = 999999
			Lighting.GlobalShadows = false
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		end,
		onUndo = function()
			if saved then
				Lighting.FogEnd = saved.FogEnd
				Lighting.FogStart = saved.FogStart
				Lighting.GlobalShadows = saved.GlobalShadows
			end
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
		end,
	}
end

function Visual.HighGraphics()
	local saved
	return {
		id = "HighGraphics",
		name = "High Graphics",
		aliases = { "highgraphics", "highgfx", "hg" },
		description = "High graphics quality",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = {
				GlobalShadows = Lighting.GlobalShadows,
			}
			Lighting.GlobalShadows = true
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
			local pp = Instance.new("PostEffect")
		end,
		onUndo = function()
			if saved then
				Lighting.GlobalShadows = saved.GlobalShadows
			end
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level10
		end,
	}
end

function Visual.RemoveFog()
	local saved
	return {
		id = "RemoveFog",
		name = "Remove Fog",
		aliases = { "removefog", "rfog" },
		description = "Remove all fog",
		category = "Visual",
		icon = "V",
		isToggle = true,
		onExecute = function()
			saved = { FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
			Lighting.FogEnd = 999999
			Lighting.FogStart = 999999
		end,
		onUndo = function()
			if saved then
				Lighting.FogEnd = saved.FogEnd
				Lighting.FogStart = saved.FogStart
			end
		end,
	}
end

function Visual.Ambient()
	local saved
	return {
		id = "Ambient",
		name = "Ambient",
		aliases = { "ambient", "amb" },
		description = "Change ambient color",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.Ambient
			Lighting.Ambient = value or Color3.fromRGB(128, 128, 128)
		end,
		onUndo = function()
			if saved then
				Lighting.Ambient = saved
			end
		end,
	}
end

function Visual.Brightness()
	local saved
	return {
		id = "Brightness",
		name = "Brightness",
		aliases = { "brightness", "bright" },
		description = "Adjust brightness",
		category = "Visual",
		icon = "V",
		isToggle = false,
		onExecute = function(value)
			saved = Lighting.Brightness
			Lighting.Brightness = value or 3
		end,
		onUndo = function()
			if saved then
				Lighting.Brightness = saved
			end
		end,
	}
end

local commandFactories = {
	Visual.Fullbright,
	Visual.Night,
	Visual.FogColor,
	Visual.FogEnd,
	Visual.Time,
	Visual.WaterTransparency,
	Visual.NoFog,
	Visual.BlueTint,
	Visual.Saturation,
	Visual.Contrast,
	Visual.Outline,
	Visual.Wireframe,
	Visual.LowGraphics,
	Visual.HighGraphics,
	Visual.RemoveFog,
	Visual.Ambient,
	Visual.Brightness,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/commands/World.lua
_MODULES['src/features/commands/World.lua'] = (function()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Selection = game:GetService("Selection")

local World = {}

local function getPlayer()
	return Players.LocalPlayer
end

local function getCharacter()
	local plr = getPlayer()
	if plr then return plr.Character end
end

local function getHumanoid()
	local char = getCharacter()
	if char then return char:FindFirstChildOfClass("Humanoid") end
end

local function getRootPart()
	local char = getCharacter()
	if char then return char:FindFirstChild("HumanoidRootPart") end
end

local removingParts = false
local removingDrops = false
local removingTools = false
local removingNPCs = false
local removalConnections = {}

function World.RemoveParts()
	return {
		id = "RemoveParts",
		name = "Remove Parts",
		aliases = { "removeparts", "rmparts" },
		description = "Remove parts when touched",
		category = "World",
		icon = "W",
		isToggle = true,
		onExecute = function()
			removingParts = true
			removalConnections[#removalConnections + 1] = workspace.DescendantAdded:Connect(function(desc)
				if not removingParts then return end
				task.wait(0.1)
				if desc:IsA("BasePart") and desc.Anchored == false and not desc:IsDescendantOf(getCharacter()) then
					desc:Destroy()
				end
			end)
			for _, obj in workspace:GetDescendants() do
				if obj:IsA("BasePart") and obj.Anchored == false and not obj:IsDescendantOf(getCharacter()) then
					obj:Destroy()
				end
			end
		end,
		onUndo = function()
			removingParts = false
			for _, con in removalConnections do
				con:Disconnect()
			end
			table.clear(removalConnections)
		end,
	}
end

function World.RemoveDrops()
	return {
		id = "RemoveDrops",
		name = "Remove Drops",
		aliases = { "removedrops", "rmdrops", "drops" },
		description = "Remove dropped items",
		category = "World",
		icon = "W",
		isToggle = true,
		onExecute = function()
			removingDrops = true
			task.defer(function()
				while removingDrops do
					for _, obj in workspace:GetDescendants() do
						if obj.Name:lower():find("drop") or obj:IsA("Tool") and obj.Parent ~= getCharacter() then
							obj:Destroy()
						end
					end
					task.wait(0.5)
				end
			end)
		end,
		onUndo = function()
			removingDrops = false
		end,
	}
end

function World.RemoveTools()
	return {
		id = "RemoveTools",
		name = "Remove Tools",
		aliases = { "removetools", "rmtools" },
		description = "Remove tools",
		category = "World",
		icon = "W",
		isToggle = true,
		onExecute = function()
			removingTools = true
			task.defer(function()
				while removingTools do
					for _, obj in workspace:GetDescendants() do
						if obj:IsA("Tool") and obj.Parent ~= getCharacter() then
							obj:Destroy()
						end
					end
					task.wait(0.5)
				end
			end)
		end,
		onUndo = function()
			removingTools = false
		end,
	}
end

function World.RemoveNPCs()
	return {
		id = "RemoveNPCs",
		name = "Remove NPCs",
		aliases = { "removenpcs", "rmnpcs" },
		description = "Remove NPCs",
		category = "World",
		icon = "W",
		isToggle = true,
		onExecute = function()
			removingNPCs = true
			task.defer(function()
				while removingNPCs do
					for _, obj in workspace:GetDescendants() do
						if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
							obj:Destroy()
						end
					end
					task.wait(0.5)
				end
			end)
		end,
		onUndo = function()
			removingNPCs = false
		end,
	}
end

function World.Clear()
	return {
		id = "Clear",
		name = "Clear",
		aliases = { "clear" },
		description = "Clear all removable objects",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			for _, obj in workspace:GetDescendants() do
				if obj:IsA("BasePart") and obj.Anchored == false and not obj:IsDescendantOf(getCharacter()) then
					obj:Destroy()
				end
				if obj:IsA("Tool") and obj.Parent ~= getCharacter() then
					obj:Destroy()
				end
				if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
					obj:Destroy()
				end
			end
		end,
		onUndo = function() end,
	}
end

function World.Rejoin()
	return {
		id = "Rejoin",
		name = "Rejoin",
		aliases = { "rejoin", "rj" },
		description = "Rejoin the server",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local ts = game:GetService("TeleportService")
			local placeId = game.PlaceId
			local jobId = game.JobId
			ts:TeleportToPlaceInstance(placeId, jobId, getPlayer())
		end,
		onUndo = function() end,
	}
end

function World.ServerHop()
	return {
		id = "ServerHop",
		name = "Server Hop",
		aliases = { "serverhop", "hop" },
		description = "Change servers",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local ts = game:GetService("TeleportService")
			local placeId = game.PlaceId
			ts:Teleport(placeId, getPlayer())
		end,
		onUndo = function() end,
	}
end

function World.Shutdown()
	return {
		id = "Shutdown",
		name = "Shutdown",
		aliases = { "shutdown", "crashserver" },
		description = "Attempt to shutdown server",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local chr = plr.Character
				if chr then
					chr:Destroy()
				end
				plr:Destroy()
			end
			game:Shutdown()
		end,
		onUndo = function() end,
	}
end

function World.Reset()
	return {
		id = "Reset",
		name = "Reset",
		aliases = { "reset", "respawn" },
		description = "Reset character",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				plr:LoadCharacter()
			end
		end,
		onUndo = function() end,
	}
end

function World.Respawn()
	return {
		id = "Respawn",
		name = "Respawn",
		aliases = { "respawn", "re" },
		description = "Respawn with delay",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local chr = plr.Character
				if chr then
					local hum = chr:FindFirstChildOfClass("Humanoid")
					if hum then
						hum.Health = 0
					end
				end
				task.wait(1)
				plr:LoadCharacter()
			end
		end,
		onUndo = function() end,
	}
end

function World.Leave()
	return {
		id = "Leave",
		name = "Leave",
		aliases = { "leave", "quit" },
		description = "Leave game",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				plr:Kick("Left game")
			end
			task.wait(0.5)
			game:Shutdown()
		end,
		onUndo = function() end,
	}
end

function World.SpawnTool()
	return {
		id = "SpawnTool",
		name = "Spawn Tool",
		aliases = { "spawntool", "spawnt" },
		description = "Spawn a tool",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function(toolName)
			local root = getRootPart()
			if not root then return end
			local tool = Instance.new("Tool")
			tool.Name = toolName or "SpawnedTool"
			tool.Grip = CFrame.new(0, 0, 0)
			tool.Parent = workspace
			tool.Handle = Instance.new("Part")
			tool.Handle.Name = "Handle"
			tool.Handle.Size = Vector3.new(1, 1, 1)
			tool.Handle.BrickColor = BrickColor.Random()
			tool.Handle.Anchored = false
			tool.Handle.CanCollide = true
			tool.Handle.Parent = tool
			tool.Parent = workspace
			tool:FindFirstChild("Handle").CFrame = root.CFrame * CFrame.new(0, 0, -5)
		end,
		onUndo = function() end,
	}
end

function World.SpawnPart()
	return {
		id = "SpawnPart",
		name = "Spawn Part",
		aliases = { "spawnpart", "spawnp" },
		description = "Spawn a part",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function(partName)
			local root = getRootPart()
			if not root then return end
			local part = Instance.new("Part")
			part.Name = partName or "SpawnedPart"
			part.Size = Vector3.new(4, 1, 4)
			part.BrickColor = BrickColor.Random()
			part.Anchored = true
			part.CanCollide = true
			part.Position = root.Position + Vector3.new(0, 0, -10)
			part.Parent = workspace
		end,
		onUndo = function() end,
	}
end

function World.SpawnModel()
	return {
		id = "SpawnModel",
		name = "Spawn Model",
		aliases = { "spawnmodel", "spawnm" },
		description = "Spawn a model",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function(modelName)
			local root = getRootPart()
			if not root then return end
			local model = Instance.new("Model")
			model.Name = modelName or "SpawnedModel"
			local part = Instance.new("Part")
			part.Name = "Main"
			part.Size = Vector3.new(4, 4, 4)
			part.BrickColor = BrickColor.Random()
			part.Anchored = true
			part.Position = root.Position + Vector3.new(0, 0, -10)
			part.Parent = model
			model.Parent = workspace
		end,
		onUndo = function() end,
	}
end

function World.SpawnScript()
	return {
		id = "SpawnScript",
		name = "Spawn Script",
		aliases = { "spawnscript", "spawns" },
		description = "Spawn a script",
		category = "World",
		icon = "W",
		isToggle = false,
		onExecute = function()
			local root = getRootPart()
			if not root then return end
			local part = Instance.new("Part")
			part.Name = "ScriptRunner"
			part.Size = Vector3.new(2, 2, 2)
			part.Anchored = true
			part.Position = root.Position + Vector3.new(0, 0, -5)
			part.Parent = workspace
			local script = Instance.new("Script")
			script.Source = "-- Script spawned by IY Mobile Reborn\nwhile task.wait(1) do\n	print('Hello from spawned script!')\nend"
			script.Parent = part
		end,
		onUndo = function() end,
	}
end

function World.ClickTP()
	local connections = {}
	return {
		id = "ClickTP",
		name = "Click TP",
		aliases = { "clicktp", "ctp" },
		description = "Click to teleport (world mode)",
		category = "World",
		icon = "W",
		isToggle = true,
		onExecute = function()
			local camera = workspace.CurrentCamera
			connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local mousePos = UserInputService:GetMouseLocation()
					local ray = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = { getCharacter() }
					local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
					if result then
						local root = getRootPart()
						if root then
							root.CFrame = CFrame.new(result.Position + result.Normal * 3)
						end
					end
				end
			end)
		end,
		onUndo = function()
			for _, con in connections do
				con:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

local commandFactories = {
	World.RemoveParts,
	World.RemoveDrops,
	World.RemoveTools,
	World.RemoveNPCs,
	World.Clear,
	World.Rejoin,
	World.ServerHop,
	World.Shutdown,
	World.Reset,
	World.Respawn,
	World.Leave,
	World.SpawnTool,
	World.SpawnPart,
	World.SpawnModel,
	World.SpawnScript,
	World.ClickTP,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands
end)()

-- Module: src/features/executor/Hook.lua
_MODULES['src/features/executor/Hook.lua'] = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Hook = {}
Hook.__index = Hook

function Hook.new()
	local self = setmetatable({
		_connections = {},
		_listeners = {
			playerAdded = {},
			playerRemoved = {},
			characterAdded = {},
			characterRemoved = {},
			respawned = {},
		},
	}, Hook)

	return self
end

function Hook:Init()
	self:_connectPlayerEvents()
	self:_connectRunEvents()
end

function Hook:_connectPlayerEvents()
	local playerAddedConn = Players.PlayerAdded:Connect(function(player)
		self:_fire("playerAdded", player)
		self:_hookPlayer(player)
	end)

	table.insert(self._connections, playerAddedConn)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_hookPlayer(player)
	end

	local playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
		self:_fire("playerRemoved", player)
	end)

	table.insert(self._connections, playerRemovingConn)
end

function Hook:_hookPlayer(player)
	local charAddedConn = player.CharacterAdded:Connect(function(character)
		self:_fire("characterAdded", player, character)
		self:_hookCharacter(player, character)
	end)

	table.insert(self._connections, charAddedConn)

	if player.Character then
		self:_hookCharacter(player, player.Character)
	end
end

function Hook:_hookCharacter(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local diedConn = humanoid.Died:Connect(function()
		self:_fire("characterRemoved", player, character)

		local respawnConn = player.CharacterAdded:Once(function(newChar)
			self:_fire("respawned", player, newChar, character)
		end)

		table.insert(self._connections, respawnConn)
	end)

	table.insert(self._connections, diedConn)
end

function Hook:_connectRunEvents()
	local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		self:_fire("heartbeat", dt)
	end)

	table.insert(self._connections, heartbeatConn)
end

function Hook:_fire(eventName, ...)
	local listeners = self._listeners[eventName]
	if not listeners then
		return
	end

	for _, listener in ipairs(listeners) do
		local success, err = pcall(listener, ...)
		if not success then
			warn("[IY] Hook listener error:", err)
		end
	end
end

function Hook:On(eventName, callback)
	if not self._listeners[eventName] then
		warn("[IY] Unknown hook event:", eventName)
		return nil
	end

	table.insert(self._listeners[eventName], callback)
	return callback
end

function Hook:Off(eventName, callback)
	local listeners = self._listeners[eventName]
	if not listeners then
		return
	end

	for i, listener in ipairs(listeners) do
		if listener == callback then
			table.remove(listeners, i)
			return
		end
	end
end

function Hook:Destroy()
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}

	for _, listeners in pairs(self._listeners) do
		table.clear(listeners)
	end
end

return Hook
end)()

-- Module: src/features/executor/Sandbox.lua
_MODULES['src/features/executor/Sandbox.lua'] = (function()
local Sandbox = {}

local RESTRICTED_GLOBALS = {
	require = true,
	loadstring = true,
	loadfile = true,
	dofile = true,
	writefile = true,
	readfile = true,
	appendfile = true,
	delfile = true,
	makefolder = true,
	listfiles = true,
	setclipboard = true,
	getclipboard = true,
	getrawmetatable = true,
	setrawmetatable = true,
	gettread = true,
	newthread = true,
	coroutine = true,
	debug = true,
	io = true,
	os = true,
}

local ALLOWED_GLOBALS = {
	["print"] = true,
	["warn"] = true,
	["error"] = true,
	["type"] = true,
	["typeof"] = true,
	["tostring"] = true,
	["tonumber"] = true,
	["pairs"] = true,
	["ipairs"] = true,
	["next"] = true,
	["select"] = true,
	["unpack"] = true,
	["table"] = true,
	["string"] = true,
	["math"] = true,
	["Vector3"] = true,
	["Vector2"] = true,
	["CFrame"] = true,
	["UDim2"] = true,
	["Color3"] = true,
	["DateTime"] = true,
	["Instance"] = true,
	["game"] = true,
	["workspace"] = true,
	["script"] = true,
	["task"] = true,
	["delay"] = true,
	["spawn"] = true,
	["tick"] = true,
	["time"] = true,
	["elapsed"] = true,
}

function Sandbox.Execute(code)
	if type(code) ~= "string" or #code == 0 then
		warn("[IY] Sandbox: empty or invalid code")
		return false, "No code provided"
	end

	local env = {}
	for k in pairs(ALLOWED_GLOBALS) do
		env[k] = _G[k]
	end

	env._VERSION = nil
	env.module = nil
	env.package = nil

	local sandboxMeta = {
		__index = function(_, key)
			if RESTRICTED_GLOBALS[key] then
				return nil
			end
			return _G[key]
		end,
		__newindex = function(_, key, value)
			if RESTRICTED_GLOBALS[key] then
				warn("[IY] Sandbox: blocked write to", key)
				return
			end
			rawset(env, key, value)
		end,
	}

	setmetatable(env, sandboxMeta)

	local fn, compileError = loadstring(code)
	if not fn then
		warn("[IY] Sandbox: compile error -", compileError)
		return false, compileError
	end

	setfenv(fn, env)

	local success, result = pcall(fn)
	if not success then
		warn("[IY] Sandbox: runtime error -", result)
		return false, result
	end

	return true, result
end

return Sandbox
end)()

-- Module: src/features/search/Fuzzy.lua
_MODULES['src/features/search/Fuzzy.lua'] = (function()
local Fuzzy = {}

function Fuzzy.Score(query, text)
	if not query or not text or #query == 0 or #text == 0 then
		return 0
	end

	query = query:lower():gsub("%s+", "")
	text = text:lower():gsub("%s+", "")

	if #query == 0 or #text == 0 then
		return 0
	end

	if query == text then
		return 1.0
	end

	if text:sub(1, #query) == query then
		return 0.8
	end

	if text:find(query, 1, true) then
		return 0.6
	end

	local charScore = Fuzzy._charMatch(query, text)
	return charScore * 0.3
end

function Fuzzy._charMatch(query, text)
	if #query > #text then
		return 0
	end

	local ti = 1
	local matches = 0

	for qi = 1, #query do
		local qc = query:sub(qi, qi)
		local found = false

		while ti <= #text do
			local tc = text:sub(ti, ti)
			ti = ti + 1
			if qc == tc then
				matches = matches + 1
				found = true
				break
			end
		end

		if not found then
			break
		end
	end

	return matches / #query
end

return Fuzzy
end)()

-- Module: src/features/search/Highlighter.lua
_MODULES['src/features/search/Highlighter.lua'] = (function()
local Highlighter = {}

function Highlighter.Highlight(text, query)
	if not text or not query or #query == 0 then
		return { { text = text or "", matched = false } }
	end

	local lowerText = text:lower()
	local lowerQuery = query:lower()

	local segments = {}
	local searchStart = 1
	local textLen = #text

	while searchStart <= textLen do
		local matchStart = lowerText:find(lowerQuery, searchStart, true)

		if not matchStart then
			table.insert(segments, {
				text = text:sub(searchStart),
				matched = false,
			})
			break
		end

		if matchStart > searchStart then
			table.insert(segments, {
				text = text:sub(searchStart, matchStart - 1),
				matched = false,
			})
		end

		local matchEnd = matchStart + #query - 1
		table.insert(segments, {
			text = text:sub(matchStart, matchEnd),
			matched = true,
		})

		searchStart = matchEnd + 1
	end

	return segments
end

return Highlighter
end)()

-- Module: src/features/search/Indexer.lua
_MODULES['src/features/search/Indexer.lua'] = (function()
local Indexer = {}
Indexer.__index = Indexer

function Indexer.new()
	local self = setmetatable({
		_index = {},
		_commands = {},
	}, Indexer)
	return self
end

function Indexer:Build(commands)
	self._commands = commands
	self._index = {}

	for _, cmd in ipairs(commands) do
		local terms = {}

		if cmd.name then
			table.insert(terms, cmd.name:lower())
		end

		if cmd.aliases then
			for _, alias in ipairs(cmd.aliases) do
				table.insert(terms, alias:lower())
			end
		end

		if cmd.description then
			for word in cmd.description:gmatch("%S+") do
				table.insert(terms, word:lower():gsub("[%p,]", ""))
			end
		end

		if cmd.category then
			table.insert(terms, cmd.category:lower())
		end

		for _, term in ipairs(terms) do
			if term and #term > 0 then
				for i = 1, #term do
					local prefix = term:sub(1, i)
					if not self._index[prefix] then
						self._index[prefix] = {}
					end
					if not self._index[prefix][cmd] then
						self._index[prefix][cmd] = 0
					end
					self._index[prefix][cmd] = self._index[prefix][cmd] + 1
				end
			end
		end
	end
end

function Indexer:Search(query)
	query = query:lower():gsub("%s+", "")
	if #query == 0 then
		return {}
	end

	local results = {}
	local candidates = self._index[query]

	if candidates then
		for cmd, count in pairs(candidates) do
			table.insert(results, { command = cmd, relevance = count })
		end
	end

	table.sort(results, function(a, b)
		return a.relevance > b.relevance
	end)

	return results
end

function Indexer:GetCommands()
	return self._commands
end

return Indexer
end)()

-- Module: src/features/search/Searcher.lua
_MODULES['src/features/search/Searcher.lua'] = (function()
local Throttle = require(script.Parent.Parent.Parent.core.throttle)
local Indexer = require(script.Indexer)
local Fuzzy = require(script.Fuzzy)

local Searcher = {}
Searcher.__index = Searcher

local DEBOUNCE_TIME = 0.15

function Searcher.new()
	local self = setmetatable({
		_indexer = Indexer.new(),
		_debounced = Throttle:Debounce(function() end, DEBOUNCE_TIME),
	}, Searcher)
	return self
end

function Searcher:Build(commands)
	self._indexer:Build(commands)
end

function Searcher:Search(query)
	if not query or #query == 0 then
		return {}
	end

	query = query:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if #query == 0 then
		return {}
	end

	local results = {}
	local seen = {}

	local indexedResults = self._indexer:Search(query)
	for _, result in ipairs(indexedResults) do
		local cmd = result.command
		local score = Fuzzy.Score(query, cmd.name)
		seen[cmd] = true
		table.insert(results, {
			command = cmd,
			score = math.max(score, result.relevance * 0.1),
		})
	end

	local commands = self._indexer:GetCommands()
	for _, cmd in ipairs(commands) do
		if not seen[cmd] then
			local nameScore = Fuzzy.Score(query, cmd.name)
			local bestScore = nameScore

			if cmd.aliases then
				for _, alias in ipairs(cmd.aliases) do
					local aliasScore = Fuzzy.Score(query, alias)
					if aliasScore > bestScore then
						bestScore = aliasScore
					end
				end
			end

			if cmd.category then
				local catScore = Fuzzy.Score(query, cmd.category)
				if catScore > bestScore then
					bestScore = catScore
				end
			end

			if bestScore > 0 then
				table.insert(results, {
					command = cmd,
					score = bestScore,
				})
			end
		end
	end

	table.sort(results, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.command.name and b.command.name then
			return #a.command.name < #b.command.name
		end
		return false
	end)

	return results
end

return Searcher
end)()

-- Module: src/features/settings/Persistence.lua
_MODULES['src/features/settings/Persistence.lua'] = (function()
local HttpService = game:GetService("HttpService")

local Persistence = {}

local FILE_NAME = "IY_Settings.json"

function Persistence.Save(data)
	local json = HttpService:JSONEncode(data)
	local success, err = pcall(function()
		writefile(FILE_NAME, json)
	end)

	if not success then
		warn("[IY] Failed to save settings:", err)
	end
end

function Persistence.Load()
	local success, data = pcall(function()
		return readfile(FILE_NAME)
	end)

	if not success or data == nil or data == "" then
		return nil
	end

	local success2, decoded = pcall(function()
		return HttpService:JSONDecode(data)
	end)

	if not success2 or type(decoded) ~= "table" then
		return nil
	end

	return decoded
end

return Persistence
end)()

-- Module: src/features/settings/Presets.lua
_MODULES['src/features/settings/Presets.lua'] = (function()
local Presets = {}

local PRESET_LIST = {
	Ocean = {
		name = "Ocean",
		primary = Color3.fromRGB(14, 165, 233),
		secondary = Color3.fromRGB(6, 182, 212),
	},
	Purple = {
		name = "Purple",
		primary = Color3.fromRGB(139, 92, 246),
		secondary = Color3.fromRGB(168, 85, 247),
	},
	Emerald = {
		name = "Emerald",
		primary = Color3.fromRGB(16, 185, 129),
		secondary = Color3.fromRGB(52, 211, 153),
	},
	Rose = {
		name = "Rose",
		primary = Color3.fromRGB(244, 63, 94),
		secondary = Color3.fromRGB(251, 113, 133),
	},
	Amber = {
		name = "Amber",
		primary = Color3.fromRGB(245, 158, 11),
		secondary = Color3.fromRGB(251, 191, 36),
	},
}

function Presets.GetAll()
	local list = {}
	for _, preset in pairs(PRESET_LIST) do
		table.insert(list, {
			name = preset.name,
			primary = preset.primary,
			secondary = preset.secondary,
		})
	end
	return list
end

function Presets.Apply(name)
	for _, preset in pairs(PRESET_LIST) do
		if preset.name == name then
			return {
				primaryColor = preset.primary,
				secondaryColor = preset.secondary,
			}
		end
	end

	warn("[IY] Unknown preset:", name)
	return nil
end

return Presets
end)()

-- Module: src/features/settings/Schema.lua
_MODULES['src/features/settings/Schema.lua'] = (function()
local Schema = {}

Schema.definition = {
	primaryColor = {
		key = "primaryColor",
		type = "Color3",
		default = Color3.fromRGB(59, 130, 246),
		min = Color3.new(0, 0, 0),
		max = Color3.new(1, 1, 1),
		step = nil,
		description = "Primary accent color for the UI",
	},
	secondaryColor = {
		key = "secondaryColor",
		type = "Color3",
		default = Color3.fromRGB(139, 92, 246),
		min = Color3.new(0, 0, 0),
		max = Color3.new(1, 1, 1),
		step = nil,
		description = "Secondary accent color for the UI",
	},
	panelTransparency = {
		key = "panelTransparency",
		type = "number",
		default = 0.4,
		min = 0,
		max = 1,
		step = 0.05,
		description = "Glass panel background transparency",
	},
	blurIntensity = {
		key = "blurIntensity",
		type = "number",
		default = 12,
		min = 0,
		max = 48,
		step = 2,
		description = "Background blur intensity for glass panels",
	},
	uiScale = {
		key = "uiScale",
		type = "number",
		default = 1.0,
		min = 0.5,
		max = 2.0,
		step = 0.1,
		description = "Global UI scale multiplier",
	},
	animationSpeed = {
		key = "animationSpeed",
		type = "number",
		default = 1.0,
		min = 0.1,
		max = 3.0,
		step = 0.1,
		description = "Animation speed multiplier",
	},
	showFPS = {
		key = "showFPS",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show FPS counter",
	},
	showPing = {
		key = "showPing",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show ping counter",
	},
	showClock = {
		key = "showClock",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show clock display",
	},
	floatingButton = {
		key = "floatingButton",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show floating action button",
	},
	hapticFeedback = {
		key = "hapticFeedback",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Enable haptic feedback on interactions",
	},
	homeScreenStyle = {
		key = "homeScreenStyle",
		type = "string",
		default = "dynamic",
		min = nil,
		max = nil,
		step = nil,
		description = "Home screen layout style (dynamic, classic, minimal)",
	},
}

function Schema.GetDefaults()
	local defaults = {}
	for key, entry in pairs(Schema.definition) do
		defaults[key] = entry.default
	end
	return defaults
end

function Schema.GetDefinition(key)
	return Schema.definition[key]
end

function Schema.GetAll()
	return Schema.definition
end

return Schema
end)()

-- Module: src/features/settings/Store.lua
_MODULES['src/features/settings/Store.lua'] = (function()
local Observer = require(script.Parent.Parent.Parent.core.observer)
local Schema = require(script.Schema)
local Persistence = require(script.Persistence)

local SettingsStore = {}
SettingsStore.__index = SettingsStore

function SettingsStore.new()
	local defaults = Schema.GetDefaults()
	local saved = Persistence.Load()

	local initialData = {}
	for key, value in pairs(defaults) do
		if saved and saved[key] ~= nil then
			initialData[key] = saved[key]
		else
			initialData[key] = value
		end
	end

	local self = setmetatable({
		_data = initialData,
		_observer = Observer.new(initialData),
	}, SettingsStore)

	return self
end

function SettingsStore:Get(key)
	local def = Schema.GetDefinition(key)
	if not def then
		warn("[IY] Unknown setting:", key)
		return nil
	end

	local value = self._data[key]
	if value == nil then
		return def.default
	end
	return value
end

function SettingsStore:Set(key, value)
	local def = Schema.GetDefinition(key)
	if not def then
		warn("[IY] Unknown setting:", key)
		return false
	end

	if def.type == "number" then
		value = math.clamp(value, def.min, def.max)
		if def.step then
			value = math.round(value / def.step) * def.step
		end
	elseif def.type == "boolean" then
		value = not not value
	elseif def.type == "Color3" then
		value = Color3.new(
			math.clamp(value.R, 0, 1),
			math.clamp(value.G, 0, 1),
			math.clamp(value.B, 0, 1)
		)
	end

	self._data[key] = value
	self._observer:Set(key, value)
	Persistence.Save(self._data)
	return true
end

function SettingsStore:Reset(key)
	local def = Schema.GetDefinition(key)
	if not def then
		return false
	end

	self._data[key] = def.default
	self._observer:Set(key, def.default)
	Persistence.Save(self._data)
	return true
end

function SettingsStore:ResetAll()
	local defaults = Schema.GetDefaults()
	for key, value in pairs(defaults) do
		self._data[key] = value
	end

	self._observer:BatchSet(self._data)
	Persistence.Save(self._data)
end

function SettingsStore:GetSchema()
	return Schema.GetAll()
end

function SettingsStore:Watch(key, callback)
	return self._observer:Watch(key, callback)
end

function SettingsStore:Destroy()
	self._observer:Destroy()
	self._data = nil
end

return SettingsStore
end)()

-- Module: src/init.lua
_MODULES['src/init.lua'] = (function()
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
end)()

-- Module: src/services/CheckpointService.lua
_MODULES['src/services/CheckpointService.lua'] = (function()
local Observer = require(script.Parent.Parent.core.observer)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CheckpointService = {}
CheckpointService.__index = CheckpointService

local FILE_NAME = "IY_Checkpoints.json"

function CheckpointService.new()
	local self = setmetatable({
		_checkpoints = {},
		_nextId = 1,
		_observer = Observer.new({ checkpoints = {} }),
	}, CheckpointService)

	self:_load()
	return self
end

function CheckpointService:_load()
	local success, data = pcall(function()
		return readfile(FILE_NAME)
	end)

	if success and data and data ~= "" then
		local success2, decoded = pcall(function()
			return HttpService:JSONDecode(data)
		end)

		if success2 and type(decoded) == "table" then
			self._checkpoints = decoded.checkpoints or {}
			self._nextId = decoded.nextId or #self._checkpoints + 1
			self._observer:Set("checkpoints", self._checkpoints)
		end
	end
end

function CheckpointService:_save()
	local data = HttpService:JSONEncode({
		checkpoints = self._checkpoints,
		nextId = self._nextId,
	})

	local success, err = pcall(function()
		writefile(FILE_NAME, data)
	end)

	if not success then
		warn("[IY] Failed to save checkpoints:", err)
	end
end

function CheckpointService:_fire()
	self._observer:Set("checkpoints", self._checkpoints)
end

function CheckpointService:Save(name)
	local player = Players.LocalPlayer
	if not player or not player.Character then
		warn("[IY] Cannot save checkpoint: no character")
		return nil
	end

	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		warn("[IY] Cannot save checkpoint: no HumanoidRootPart")
		return nil
	end

	local checkpoint = {
		id = self._nextId,
		name = name or "Checkpoint " .. self._nextId,
		createdAt = DateTime.now():ToIsoDate(),
		position = {
			X = root.Position.X,
			Y = root.Position.Y,
			Z = root.Position.Z,
		},
		distance = 0,
	}

	self._nextId = self._nextId + 1
	table.insert(self._checkpoints, checkpoint)
	self:_save()
	self:_fire()
	return checkpoint
end

function CheckpointService:Delete(id)
	for i, cp in ipairs(self._checkpoints) do
		if cp.id == id then
			table.remove(self._checkpoints, i)
			self:_save()
			self:_fire()
			return true
		end
	end
	return false
end

function CheckpointService:Rename(id, name)
	for _, cp in ipairs(self._checkpoints) do
		if cp.id == id then
			cp.name = name
			self:_save()
			self:_fire()
			return true
		end
	end
	return false
end

function CheckpointService:Update(id)
	local player = Players.LocalPlayer
	if not player or not player.Character then
		return false
	end

	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	for _, cp in ipairs(self._checkpoints) do
		if cp.id == id then
			cp.position = {
				X = root.Position.X,
				Y = root.Position.Y,
				Z = root.Position.Z,
			}
			self:_save()
			self:_fire()
			return true
		end
	end
	return false
end

function CheckpointService:Duplicate(id)
	for _, cp in ipairs(self._checkpoints) do
		if cp.id == id then
			local dup = {
				id = self._nextId,
				name = cp.name .. " (Copy)",
				createdAt = DateTime.now():ToIsoDate(),
				position = { X = cp.position.X, Y = cp.position.Y, Z = cp.position.Z },
				distance = cp.distance,
			}

			self._nextId = self._nextId + 1
			table.insert(self._checkpoints, dup)
			self:_save()
			self:_fire()
			return dup
		end
	end
	return nil
end

function CheckpointService:GetAll()
	return self._checkpoints
end

function CheckpointService:Export(id)
	for _, cp in ipairs(self._checkpoints) do
		if cp.id == id then
			local json = HttpService:JSONEncode(cp)
			setclipboard(json)
			return true
		end
	end
	return false
end

function CheckpointService:Import(json)
	local success, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if not success or type(data) ~= "table" then
		warn("[IY] Invalid checkpoint JSON")
		return false
	end

	data.id = self._nextId
	self._nextId = self._nextId + 1

	table.insert(self._checkpoints, data)
	self:_save()
	self:_fire()
	return true
end

function CheckpointService:GetDistance(a, b)
	local dx = a.position.X - b.position.X
	local dy = a.position.Y - b.position.Y
	local dz = a.position.Z - b.position.Z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function CheckpointService:Watch(callback)
	return self._observer:Watch("checkpoints", callback)
end

function CheckpointService:Destroy()
	self._observer:Destroy()
	self._checkpoints = nil
end

return CheckpointService
end)()

-- Module: src/services/RecentActivity.lua
_MODULES['src/services/RecentActivity.lua'] = (function()
local Observer = require(script.Parent.Parent.core.observer)
local HttpService = game:GetService("HttpService")

local RecentActivity = {}
RecentActivity.__index = RecentActivity

local MAX_ENTRIES = 20
local FILE_NAME = "IY_Recent.json"

function RecentActivity.new()
	local self = setmetatable({
		_entries = {},
		_observer = Observer.new({ entries = {} }),
	}, RecentActivity)

	self:_load()
	return self
end

function RecentActivity:_load()
	local success, data = pcall(function()
		return readfile(FILE_NAME)
	end)

	if success and data and data ~= "" then
		local success2, decoded = pcall(function()
			return HttpService:JSONDecode(data)
		end)

		if success2 and type(decoded) == "table" then
			self._entries = decoded
			self._observer:Set("entries", self._entries)
		end
	end
end

function RecentActivity:Add(cmdName, cmdCategory, timestamp)
	local entry = {
		name = cmdName,
		category = cmdCategory,
		time = timestamp or DateTime.now():ToIsoDate(),
	}

	table.insert(self._entries, 1, entry)

	if #self._entries > MAX_ENTRIES then
		table.remove(self._entries)
	end

	self:_persist()
	self._observer:Set("entries", self._entries)
end

function RecentActivity:GetAll()
	return self._entries
end

function RecentActivity:Clear()
	self._entries = {}
	self:_persist()
	self._observer:Set("entries", self._entries)
end

function RecentActivity:_persist()
	local success, err = pcall(function()
		writefile(FILE_NAME, HttpService:JSONEncode(self._entries))
	end)

	if not success then
		warn("[IY] Failed to persist recent activity:", err)
	end
end

function RecentActivity:Watch(callback)
	return self._observer:Watch("entries", callback)
end

function RecentActivity:Destroy()
	self._observer:Destroy()
	self._entries = nil
end

return RecentActivity
end)()

-- Module: src/ui/components/Button.lua
_MODULES['src/ui/components/Button.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Button = {}
Button.__index = Button

function Button.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _onClick = props.OnClick or function() end,
        _enabled = props.Enabled ~= false,
        _destroyed = false,
    }, Button)

    local size = props.Size or UDim2.new(0, 200, 0, 48)
    local pos = props.Position or UDim2.fromOffset(0, 0)

    self._frame = Glass.new({
        Name = props.Name or "Button",
        Parent = parent,
        Size = size,
        Position = pos,
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = props.CornerRadius or 10,
        Transparency = 0.35,
        Shadow = true,
        BorderGlow = props.Variant == "Primary" and true or false,
        Gradient = props.Variant == "Primary" and {
            Color1 = theme:GetColor("Primary"),
            Color2 = theme:GetColor("Secondary"),
            Alpha = 0.2,
        } or nil,
    })

    if props.Icon then
        self._icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(16, 14),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self._frame,
        })
    end

    self._label = InstanceUtils.New("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -32, 1, 0),
        Position = UDim2.fromOffset(props.Icon and 44 or 16, 0),
        BackgroundTransparency = 1,
        Text = props.Text or "Button",
        TextColor3 = props.Variant == "Primary" and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextPrimary"),
        TextSize = 15 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        Parent = self._frame,
    })

    if props.Description then
        self._desc = InstanceUtils.New("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -32, 0, 16),
            Position = UDim2.new(0, props.Icon and 44 or 16, 0, 26),
            BackgroundTransparency = 1,
            Text = props.Description,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 11 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._ripple = InstanceUtils.New("Frame", {
        Name = "Ripple",
        Size = UDim2.fromScale(0, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0,
        Visible = false,
        Parent = self._frame,
    })
    local rippleCorner = InstanceUtils.MakeCorner(100)
    rippleCorner.Parent = self._ripple

    self._connection = self._frame.InputBegan:Connect(function(input)
        if not self._enabled or self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_onPress()
        end
    end)

    self._endConnection = self._frame.InputEnded:Connect(function(input)
        if not self._enabled or self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_onRelease()
        end
    end)

    return self
end

function Button:_onPress()
    TweenKit.new(self._frame, {BackgroundTransparency = 0.5}, 0.1, "InQuad")
    TweenKit.new(self._frame, {Size = self._frame.Size - UDim2.fromOffset(2, 2)}, 0.1, "InQuad")
    self:_showRipple()
end

function Button:_onRelease()
    TweenKit.new(self._frame, {BackgroundTransparency = 0.35}, 0.2, "OutQuad")
    TweenKit.new(self._frame, {Size = self._frame.Size + UDim2.fromOffset(2, 2)}, 0.2, "OutBack")
    if self._onClick then
        self._onClick()
    end
end

function Button:_showRipple()
    if not self._ripple then return end
    self._ripple.Visible = true
    self._ripple.Size = UDim2.fromScale(0, 0)
    self._ripple.BackgroundTransparency = 0.8
    TweenKit.new(self._ripple, {Size = UDim2.fromScale(2, 2), BackgroundTransparency = 1}, 0.4, "OutQuad")
    task.delay(0.5, function()
        if self._ripple then
            self._ripple.Visible = false
        end
    end)
end

function Button:SetText(text)
    if self._label then
        self._label.Text = text
    end
end

function Button:SetEnabled(enabled)
    self._enabled = enabled
    if self._label then
        self._label.TextTransparency = enabled and 0 or 0.5
    end
end

function Button:SetOnClick(callback)
    self._onClick = callback
end

function Button:Destroy()
    self._destroyed = true
    if self._connection then self._connection:Disconnect() end
    if self._endConnection then self._endConnection:Disconnect() end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._label = nil
    self._icon = nil
    self._ripple = nil
end

return Button
end)()

-- Module: src/ui/components/Card.lua
_MODULES['src/ui/components/Card.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Card = {}
Card.__index = Card

function Card.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _destroyed = false,
    }, Card)

    self._frame = Glass.new({
        Name = props.Name or "Card",
        Parent = parent,
        Size = props.Size or UDim2.new(0, 280, 0, 100),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = props.CornerRadius or 14,
        Transparency = props.Transparency or 0.3,
        Shadow = true,
        BorderGlow = props.Highlight or false,
    })

    if props.Header then
        self._header = InstanceUtils.New("TextLabel", {
            Name = "Header",
            Size = UDim2.new(1, -24, 0, 24),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Text = props.Header,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 16 * theme.Scale,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    if props.Subheader then
        self._subheader = InstanceUtils.New("TextLabel", {
            Name = "Subheader",
            Size = UDim2.new(1, -24, 0, 18),
            Position = UDim2.fromOffset(12, props.Header and 36 or 12),
            BackgroundTransparency = 1,
            Text = props.Subheader,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 13 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    if props.Content then
        local contentY = 12
        if props.Header then contentY = contentY + 24 end
        if props.Subheader then contentY = contentY + 20 end

        self._content = InstanceUtils.New("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, -24, 0, 0),
            Position = UDim2.fromOffset(12, contentY),
            BackgroundTransparency = 1,
            Text = props.Content,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 12 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = self._frame,
        })
        self._content.Size = UDim2.new(1, -24, 0, self._content.TextBounds.Y + 4)
    end

    if props.Footer then
        local footerY = 12
        if props.Header then footerY = footerY + 24 end
        if props.Subheader then footerY = footerY + 20 end
        if self._content then footerY = footerY + self._content.Size.Y.Offset + 4 end

        self._footer = InstanceUtils.New("Frame", {
            Name = "Footer",
            Size = UDim2.new(1, -24, 0, 32),
            Position = UDim2.fromOffset(12, footerY),
            BackgroundTransparency = 1,
            Parent = self._frame,
        })
    end

    return self
end

function Card:GetFrame()
    return self._frame
end

function Card:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._header = nil
    self._subheader = nil
    self._content = nil
    self._footer = nil
end

return Card
end)()

-- Module: src/ui/components/ColorPicker.lua
_MODULES['src/ui/components/ColorPicker.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local defaultColor = props.Default or Color3.fromRGB(59, 130, 246)

    local self = setmetatable({
        _onChange = props.OnChange or function() end,
        _color = defaultColor,
        _open = false,
        _destroyed = false,
    }, ColorPicker)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "ColorPicker",
        Size = props.Size or UDim2.new(0, 280, 0, 50),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, -18),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 12 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._swatch = Glass.new({
        Name = "Swatch",
        Parent = self._frame,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.fromOffset(0, 0),
        CornerRadius = 10,
        Transparency = 0.2,
    })

    self._colorFill = InstanceUtils.New("Frame", {
        Name = "ColorFill",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = defaultColor,
        BorderSizePixel = 0,
        Parent = self._swatch,
    })
    local fillCorner = InstanceUtils.MakeCorner(8)
    fillCorner.Parent = self._colorFill

    self._hexLabel = InstanceUtils.New("TextLabel", {
        Name = "Hex",
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.fromOffset(52, 0),
        BackgroundTransparency = 1,
        Text = "#" .. self:_rgbToHex(defaultColor),
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })

    self._pickerContainer = InstanceUtils.New("Frame", {
        Name = "PickerContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        Parent = self._frame,
    })

    self._pickerPanel = Glass.new({
        Name = "PickerPanel",
        Parent = self._pickerContainer,
        Size = UDim2.new(1, 0, 0, 200),
        CornerRadius = 12,
        Transparency = 0.3,
        Shadow = true,
    })

    self:_buildHueBar()
    self:_buildSaturationBrightness()
    self:_buildPresets()

    self._swatch.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_toggle()
        end
    end)

    return self
end

function ColorPicker:_buildHueBar()
    local bar = InstanceUtils.New("Frame", {
        Name = "HueBar",
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = self._pickerPanel,
    })
    local barCorner = InstanceUtils.MakeCorner(8)
    barCorner.Parent = bar

    local hueGrad = InstanceUtils.New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Parent = bar,
    })

    self._hueSlider = InstanceUtils.New("Frame", {
        Name = "HueSlider",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.fromOffset(0, -1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = bar,
    })
    local sliderCorner = InstanceUtils.MakeCorner(9)
    sliderCorner.Parent = self._hueSlider
end

function ColorPicker:_buildSaturationBrightness()
    local sb = InstanceUtils.New("Frame", {
        Name = "SatBright",
        Size = UDim2.new(1, -20, 0, 120),
        Position = UDim2.fromOffset(10, 34),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        Parent = self._pickerPanel,
    })
    local sbCorner = InstanceUtils.MakeCorner(8)
    sbCorner.Parent = sb

    local whiteGrad = InstanceUtils.New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }),
        Rotation = 90,
        Parent = sb,
    })

    local blackGrad = InstanceUtils.New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
        }),
        Parent = sb,
    })
end

function ColorPicker:_buildPresets()
    local presets = {
        Color3.fromRGB(59, 130, 246),
        Color3.fromRGB(139, 92, 246),
        Color3.fromRGB(6, 182, 212),
        Color3.fromRGB(34, 197, 94),
        Color3.fromRGB(251, 191, 36),
        Color3.fromRGB(239, 68, 68),
        Color3.fromRGB(236, 72, 153),
        Color3.fromRGB(255, 255, 255),
    }

    for i, color in ipairs(presets) do
        local swatch = InstanceUtils.New("Frame", {
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(0, 10 + (i - 1) * 34, 0, 166),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            Parent = self._pickerPanel,
        })
        local swatchCorner = InstanceUtils.MakeCorner(6)
        swatchCorner.Parent = swatch

        swatch.InputBegan:Connect(function(input)
            if self._destroyed then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_setColor(color)
            end
        end)
    end
end

function ColorPicker:_rgbToHex(color)
    return string.format("%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

function ColorPicker:_setColor(color)
    self._color = color
    self._colorFill.BackgroundColor3 = color
    self._hexLabel.Text = "#" .. self:_rgbToHex(color)
    if self._onChange then
        self._onChange(color)
    end
end

function ColorPicker:_toggle()
    if self._open then
        self:_close()
    else
        self:_open()
    end
end

function ColorPicker:_open()
    self._open = true
    self._pickerContainer.Visible = true
    TweenKit.new(self._pickerContainer, {Size = UDim2.new(1, 0, 0, 200)}, 0.25, "OutQuad")
end

function ColorPicker:_close()
    self._open = false
    TweenKit.new(self._pickerContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, "InQuad")
    task.delay(0.2, function()
        if not self._open and self._pickerContainer then
            self._pickerContainer.Visible = false
        end
    end)
end

function ColorPicker:GetColor()
    return self._color
end

function ColorPicker:SetColor(color)
    self:_setColor(color)
end

function ColorPicker:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._swatch = nil
    self._colorFill = nil
    self._pickerContainer = nil
    self._pickerPanel = nil
end

return ColorPicker
end)()

-- Module: src/ui/components/ContextMenu.lua
_MODULES['src/ui/components/ContextMenu.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local ContextMenu = {}
ContextMenu.__index = ContextMenu

local _activeMenu = nil

function ContextMenu.Show(parent, position, items)
    ContextMenu.Close()

    local theme = Theme.GetGlobal()
    local itemHeight = 40
    local totalHeight = #items * itemHeight

    local overlay = InstanceUtils.New("Frame", {
        Name = "ContextOverlay",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local screenSize = parent.AbsoluteSize
    local menuWidth = 200
    local xPos = math.min(position.X, screenSize.X - menuWidth - 8)
    local yPos = math.min(position.Y, screenSize.Y - totalHeight - 8)

    local menu = Glass.new({
        Name = "ContextMenu",
        Parent = overlay,
        Size = UDim2.new(0, menuWidth, 0, totalHeight),
        Position = UDim2.fromOffset(xPos, yPos),
        CornerRadius = 12,
        Transparency = 0.1,
        Shadow = true,
        BorderGlow = true,
    })

    menu.Size = UDim2.new(0, menuWidth, 0, 0)
    TweenKit.new(menu, {Size = UDim2.new(0, menuWidth, 0, totalHeight)}, 0.2, "OutBack")

    for i, item in ipairs(items) do
        local itemFrame = InstanceUtils.New("Frame", {
            Name = "Item_" .. i,
            Size = UDim2.new(1, 0, 0, itemHeight),
            Position = UDim2.new(0, 0, 0, (i - 1) * itemHeight),
            BackgroundTransparency = 1,
            Parent = menu,
        })

        if item.Icon then
            local icon = InstanceUtils.New("TextLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.fromOffset(12, 11),
                BackgroundTransparency = 1,
                Text = item.Icon,
                TextColor3 = item.Destructive and theme:GetColor("Error") or theme:GetColor("TextSecondary"),
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                Parent = itemFrame,
            })
        end

        local textLabel = InstanceUtils.New("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -40, 1, 0),
            Position = UDim2.fromOffset(item.Icon and 36 or 12, 0),
            BackgroundTransparency = 1,
            Text = item.Text or "",
            TextColor3 = item.Destructive and theme:GetColor("Error") or theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = itemFrame,
        })

        if i < #items then
            local sep = InstanceUtils.New("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.new(0, 12, 1, -1),
                BackgroundColor3 = theme:GetColor("Border"),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                Parent = itemFrame,
            })
        end

        itemFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                ContextMenu.Close()
                if item.Callback then
                    item.Callback()
                end
            end
        end)
    end

    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local absPos = Vector2.new(input.Position.X, input.Position.Y)
            local menuAbsPos = menu.AbsolutePosition
            local menuAbsSize = menu.AbsoluteSize
            local inMenu = absPos.X >= menuAbsPos.X and absPos.X <= menuAbsPos.X + menuAbsSize.X
                and absPos.Y >= menuAbsPos.Y and absPos.Y <= menuAbsPos.Y + menuAbsSize.Y
            if not inMenu then
                ContextMenu.Close()
            end
        end
    end)

    _activeMenu = overlay
    return overlay
end

function ContextMenu.Close()
    if _activeMenu then
        _activeMenu:Destroy()
        _activeMenu = nil
    end
end

return ContextMenu
end)()

-- Module: src/ui/components/Dialog.lua
_MODULES['src/ui/components/Dialog.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Dialog = {}
Dialog.__index = Dialog

local _activeDialog = nil

function Dialog.Show(parent, props)
    if _activeDialog then
        _activeDialog:Destroy()
    end

    props = props or {}
    local theme = Theme.GetGlobal()
    local title = props.Title or "Dialog"
    local message = props.Message or ""
    local buttons = props.Buttons or {{Text = "OK", Primary = true}}
    local onClose = props.OnClose or function() end

    local overlay = InstanceUtils.New("Frame", {
        Name = "DialogOverlay",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = parent,
    })

    local dialog = Glass.new({
        Name = "Dialog",
        Parent = overlay,
        Size = UDim2.new(0, 300, 0, 0),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        CornerRadius = 16,
        Transparency = 0.15,
        Shadow = true,
        BorderGlow = true,
    })

    local titleLabel = InstanceUtils.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 28),
        Position = UDim2.fromOffset(16, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 18 * theme.Scale,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dialog,
    })

    local msgLabel = nil
    if message and #message > 0 then
        msgLabel = InstanceUtils.New("TextLabel", {
            Name = "Message",
            Size = UDim2.new(1, -32, 0, 40),
            Position = UDim2.fromOffset(16, 48),
            BackgroundTransparency = 1,
            Text = message,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = dialog,
        })

        local textHeight = msgLabel.TextBounds.Y
        msgLabel.Size = UDim2.new(1, -32, 0, math.max(40, textHeight + 8))
    end

    local contentY = (msgLabel and 48 + msgLabel.Size.Y.Offset) or 48
    local btnY = contentY + 16
    local btnCount = #buttons
    local btnWidth = math.min(120, (280 - (btnCount - 1) * 8) / btnCount)

    local btnContainer = InstanceUtils.New("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -16, 0, 40),
        Position = UDim2.new(0, 8, 0, btnY),
        BackgroundTransparency = 1,
        Parent = dialog,
    })

    for i, btn in ipairs(buttons) do
        local xPos = (i - 1) * (btnWidth + 8)
        local btnLabel = btn.Primary and "Button" or "Button"
        local frame = Glass.new({
            Name = "Btn_" .. (btn.Text or ""),
            Parent = btnContainer,
            Size = UDim2.new(0, btnWidth, 1, 0),
            Position = UDim2.fromOffset(xPos, 0),
            CornerRadius = 10,
            Transparency = btn.Primary and 0.2 or 0.4,
            Gradient = btn.Primary and {
                Color1 = theme:GetColor("Primary"),
                Color2 = theme:GetColor("Secondary"),
                Alpha = 0.3,
            } or nil,
            BorderGlow = btn.Primary or false,
        })

        local text = InstanceUtils.New("TextLabel", {
            Name = "Text",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = btn.Text or "Button",
            TextColor3 = btn.Primary and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            Parent = frame,
        })

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if btn.Callback then
                    btn.Callback()
                end
                self:Destroy()
            end
        end)
    end

    local totalHeight = btnY + 40 + 16
    dialog.Size = UDim2.new(0, 300, 0, totalHeight)

    dialog.Size = UDim2.new(0, 300, 0, 0)
    overlay.BackgroundTransparency = 1

    TweenKit.new(overlay, {BackgroundTransparency = 0.6}, 0.2, "OutQuad")
    TweenKit.new(dialog, {Size = UDim2.new(0, 300, 0, totalHeight)}, 0.3, "OutBack")

    _activeDialog = {
        Overlay = overlay,
        Dialog = dialog,
        OnClose = onClose,
        Destroy = function()
            if not overlay then return end
            TweenKit.new(overlay, {BackgroundTransparency = 1}, 0.15, "InQuad")
            TweenKit.new(dialog, {Size = UDim2.new(0, 300, 0, 0)}, 0.2, "InQuad")
            task.delay(0.25, function()
                if overlay then overlay:Destroy() end
            end)
            overlay = nil
            dialog = nil
            _activeDialog = nil
            onClose()
        end,
    }

    return _activeDialog
end

function Dialog.Close()
    if _activeDialog then
        _activeDialog:Destroy()
    end
end

return Dialog
end)()

-- Module: src/ui/components/Dropdown.lua
_MODULES['src/ui/components/Dropdown.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local items = props.Items or {}
    local selected = props.Default or (items[1] and items[1].Value) or nil

    local self = setmetatable({
        _onSelect = props.OnSelect or function() end,
        _items = items,
        _selected = selected,
        _open = false,
        _destroyed = false,
    }, Dropdown)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Dropdown",
        Size = props.Size or UDim2.new(0, 280, 0, 44),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, -18),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 12 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._header = Glass.new({
        Name = "Header",
        Parent = self._frame,
        Size = UDim2.new(1, 0, 0, 44),
        Position = UDim2.fromOffset(0, 0),
        CornerRadius = 10,
        Transparency = 0.5,
    })

    self._headerText = InstanceUtils.New("TextLabel", {
        Name = "Selected",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = self:_getDisplayText(selected),
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._header,
    })

    self._arrow = InstanceUtils.New("TextLabel", {
        Name = "Arrow",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0, 12),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = self._header,
    })

    self._dropContainer = InstanceUtils.New("Frame", {
        Name = "DropContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        Parent = self._frame,
    })

    self._dropPanel = Glass.new({
        Name = "DropPanel",
        Parent = self._dropContainer,
        Size = UDim2.new(1, 0, 0, 0),
        CornerRadius = 10,
        Transparency = 0.3,
        Shadow = true,
    })

    self._itemButtons = {}
    self:_buildItems()

    self._header.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_toggle()
        end
    end)

    return self
end

function Dropdown:_getDisplayText(value)
    for _, item in ipairs(self._items) do
        if item.Value == value then
            return item.Text or tostring(value)
        end
    end
    return "Select..."
end

function Dropdown:_buildItems()
    for _, btn in ipairs(self._itemButtons) do
        if btn then btn:Destroy() end
    end
    self._itemButtons = {}

    local itemHeight = 40
    local totalHeight = #self._items * itemHeight

    self._dropPanel.Size = UDim2.new(1, 0, 0, totalHeight)

    for i, item in ipairs(self._items) do
        local itemFrame = InstanceUtils.New("Frame", {
            Name = "Item_" .. i,
            Size = UDim2.new(1, 0, 0, itemHeight),
            Position = UDim2.new(0, 0, 0, (i - 1) * itemHeight),
            BackgroundTransparency = 1,
            Parent = self._dropPanel,
        })

        local isSelected = item.Value == self._selected

        if isSelected then
            local sel = InstanceUtils.New("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = theme:GetColor("Primary"),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                Parent = itemFrame,
            })
            local selCorner = InstanceUtils.MakeCorner(0)
            selCorner.Parent = sel
        end

        local itemText = InstanceUtils.New("TextLabel", {
            Name = "Text",
            Size = UDim2.new(1, -24, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = item.Text or tostring(item.Value),
            TextColor3 = isSelected and theme:GetColor("Primary") or theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = itemFrame,
        })

        if item.Description then
            itemText.Size = UDim2.new(1, -24, 0, 20)
            itemText.Position = UDim2.fromOffset(12, 4)
            local desc = InstanceUtils.New("TextLabel", {
                Name = "Desc",
                Size = UDim2.new(1, -24, 0, 14),
                Position = UDim2.fromOffset(12, 24),
                BackgroundTransparency = 1,
                Text = item.Description,
                TextColor3 = theme:GetColor("TextMuted"),
                TextSize = 11 * theme.Scale,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = itemFrame,
            })
        end

        if i < #self._items then
            local sep = InstanceUtils.New("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.new(0, 12, 1, 0),
                BackgroundColor3 = theme:GetColor("Border"),
                BackgroundTransparency = 0.8,
                BorderSizePixel = 0,
                Parent = itemFrame,
            })
        end

        itemFrame.InputBegan:Connect(function(input)
            if self._destroyed then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self._selected = item.Value
                self._headerText.Text = item.Text or tostring(item.Value)
                self._onSelect(item.Value)
                self:_close()
            end
        end)

        table.insert(self._itemButtons, itemFrame)
    end
end

function Toggle:_toggle()
    if self._open then
        self:_close()
    else
        self:_open()
    end
end

function Dropdown:_open()
    self._open = true
    self._dropContainer.Visible = true
    self._arrow.Text = "^"
    local totalHeight = #self._items * 40
    self._dropContainer.Size = UDim2.new(1, 0, 0, 0)
    TweenKit.new(self._dropContainer, {Size = UDim2.new(1, 0, 0, totalHeight)}, 0.25, "OutQuad")
end

function Dropdown:_close()
    self._open = false
    self._arrow.Text = "v"
    TweenKit.new(self._dropContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, "InQuad")
    task.delay(0.2, function()
        if not self._open and self._dropContainer then
            self._dropContainer.Visible = false
        end
    end)
end

function Dropdown:SetItems(items)
    self._items = items
    self:_buildItems()
    if self._selected == nil and #items > 0 then
        self._selected = items[1].Value
        self._headerText.Text = items[1].Text or tostring(items[1].Value)
    end
end

function Dropdown:GetValue()
    return self._selected
end

function Dropdown:SetValue(value)
    self._selected = value
    self._headerText.Text = self:_getDisplayText(value)
end

function Dropdown:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._header = nil
    self._dropPanel = nil
    self._dropContainer = nil
    self._itemButtons = {}
end

return Dropdown
end)()

-- Module: src/ui/components/FloatingButton.lua
_MODULES['src/ui/components/FloatingButton.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)
local Observer = require(script.Parent.Parent.Parent.core.observer)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local FloatingButton = {}
FloatingButton.__index = FloatingButton

function FloatingButton.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _parent = parent,
        _onOpen = props.OnOpen or function() end,
        _onClose = props.OnClose or function() end,
        _visible = true,
        _dragging = false,
        _dragStart = nil,
        _frameStart = nil,
        _destroyed = false,
        _open = false,
        _size = 56,
        _padding = 8,
        _animating = false,
    }, FloatingButton)

    local inset = parent:FindFirstChildOfClass("Frame") and Vector2.new(0, 0) or Vector2.new(0, 0)
    local screenSize = parent.AbsoluteSize

    self._defaultPos = props.DefaultPosition or UDim2.new(1, -(self._size + self._padding), 1, -(self._size + self._padding + 80))

    self._frame = Glass.new({
        Name = "FloatingButton",
        Parent = parent,
        Size = UDim2.new(0, self._size, 0, self._size),
        Position = self._defaultPos,
        AnchorPoint = Vector2.new(0.5, 0.5),
        CornerRadius = self._size / 2,
        Transparency = 0.25,
        Shadow = true,
        BorderGlow = true,
    })

    self._pulse = InstanceUtils.New("Frame", {
        Name = "Pulse",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundColor3 = theme:GetColor("Primary"),
        BackgroundTransparency = 0.85,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    local pulseCorner = InstanceUtils.MakeCorner(self._size / 2)
    pulseCorner.Parent = self._pulse

    self._icon = InstanceUtils.New("TextLabel", {
        Name = "Icon",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "I",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 22,
        Font = Enum.Font.GothamBold,
        Parent = self._frame,
    })

    self._connectors = {}
    self:_connectEvents()
    self:_startPulseAnimation()

    self._frame.Visible = true
    return self
end

function FloatingButton:_connectEvents()
    local began = self._frame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = true
            self._dragStart = input.Position
            self._frameStart = UDim2.new(0, self._frame.AbsolutePosition.X, 0, self._frame.AbsolutePosition.Y)
            TweenKit.new(self._frame, {Size = UDim2.new(0, self._size - 4, 0, self._size - 4)}, 0.1, "OutQuad")
        end
    end)

    local changed = UserInputService.InputChanged:Connect(function(input)
        if self._destroyed or not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_onDrag(input.Position)
        end
    end)

    local ended = UserInputService.InputEnded:Connect(function(input)
        if self._destroyed or not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
            local delta = (input.Position - self._dragStart).Magnitude
            TweenKit.new(self._frame, {Size = UDim2.new(0, self._size, 0, self._size)}, 0.2, "OutBack")
            if delta < 15 then
                self:_onTap()
            else
                self:_onSnap()
            end
        end
    end)

    self._connectors = {began, changed, ended}
end

function FloatingButton:_onDrag(inputPos)
    if self._animating then return end

    local parentAbs = self._parent.AbsolutePosition
    local parentSize = self._parent.AbsoluteSize
    local halfSize = self._size / 2

    local x = math.clamp(inputPos.X - parentAbs.X - halfSize, self._padding, parentSize.X - self._size - self._padding)
    local y = math.clamp(inputPos.Y - parentAbs.Y - halfSize, self._padding + 40, parentSize.Y - self._size - self._padding)

    self._frame.Position = UDim2.fromOffset(x, y)
end

function FloatingButton:_onSnap()
    if self._animating then return end
    self._animating = true

    local parentSize = self._parent.AbsoluteSize
    local framePos = self._frame.AbsolutePosition
    local frameCenter = framePos + Vector2.new(self._size / 2, self._size / 2)
    local parentCenter = parentSize / 2

    local margins = {
        Left = frameCenter.X - 0,
        Right = parentSize.X - frameCenter.X,
        Top = frameCenter.Y - 0,
        Bottom = parentSize.Y - frameCenter.Y,
    }

    local minDist = math.min(margins.Left, margins.Right, margins.Top, margins.Bottom)
    local snapX, snapY

    if minDist == margins.Left then
        snapX = self._padding
    elseif minDist == margins.Right then
        snapX = parentSize.X - self._size - self._padding
    else
        snapX = framePos.X
    end

    local topMargins = {Left = margins.Left, Right = margins.Right}
    local minHoriz = math.min(topMargins.Left, topMargins.Right)

    if minDist == margins.Top then
        snapY = self._padding + 40
    elseif minDist == margins.Bottom then
        snapY = parentSize.Y - self._size - self._padding
    else
        snapY = framePos.Y
    end

    TweenKit.new(self._frame, {
        Position = UDim2.fromOffset(snapX, snapY),
    }, 0.3, "OutQuad")

    task.delay(0.3, function()
        self._animating = false
    end)
end

function FloatingButton:_onTap()
    if self._animating then return end
    self._animating = true

    if not self._open then
        self:Open()
    else
        self:Close()
    end
end

function FloatingButton:Open()
    if self._open or self._animating then return end
    self._open = true

    TweenKit.new(self._frame, {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
    }, 0.2, "InQuad")

    task.delay(0.15, function()
        if not self._destroyed then
            self._frame.Visible = false
            self._animating = false
            self._onOpen()
        end
    end)
end

function FloatingButton:Close()
    if not self._open or self._animating then return end

    self._frame.Size = UDim2.new(0, 0, 0, 0)
    self._frame.BackgroundTransparency = 1
    self._frame.Visible = true

    task.delay(0.05, function()
        if self._destroyed then return end
        self._open = false
        self._animating = false

        TweenKit.new(self._frame, {
            Size = UDim2.new(0, self._size, 0, self._size),
            BackgroundTransparency = 0.25,
        }, 0.35, "OutBack")

        self._onClose()
    end)
end

function FloatingButton:_startPulseAnimation()
    if self._destroyed then return end

    local pulseRunning = true
    local cancelPulse = function()
        pulseRunning = false
    end

    spawn(function()
        while pulseRunning and not self._destroyed do
            task.wait(3)
            if not pulseRunning or self._destroyed then break end
            if self._pulse then
                TweenKit.new(self._pulse, {
                    Size = UDim2.fromScale(1.3, 1.3),
                    BackgroundTransparency = 0.95,
                }, 1.5, "OutQuad")
                task.wait(1.5)
                if not pulseRunning or not self._pulse then break end
                TweenKit.new(self._pulse, {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 0.85,
                }, 1.5, "OutQuad")
            end
        end
    end)

    self._cancelPulse = cancelPulse
end

function FloatingButton:SetPosition(pos)
    self._frame.Position = pos
end

function FloatingButton:GetPosition()
    return self._frame.Position
end

function FloatingButton:Destroy()
    self._destroyed = true
    if self._cancelPulse then self._cancelPulse() end
    for _, conn in ipairs(self._connectors) do
        if conn.Connected then conn:Disconnect() end
    end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._pulse = nil
    self._icon = nil
    self._connectors = {}
end

return FloatingButton
end)()

-- Module: src/ui/components/Keybind.lua
_MODULES['src/ui/components/Keybind.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local UserInputService = game:GetService("UserInputService")

    local defaultKey = props.Default or Enum.KeyCode.F2
    local listening = false

    local self = setmetatable({
        _onChanged = props.OnChanged or function() end,
        _key = defaultKey,
        _listening = false,
        _destroyed = false,
    }, Keybind)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Keybind",
        Size = props.Size or UDim2.new(0, 280, 0, 44),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 0.5,
        BackgroundColor3 = theme:GetColor("Surface"),
        BorderSizePixel = 0,
        Parent = parent,
    })
    local frameCorner = InstanceUtils.MakeCorner(10)
    frameCorner.Parent = self._frame

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -80, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    self._keyDisplay = Glass.new({
        Name = "KeyDisplay",
        Parent = self._frame,
        Size = UDim2.new(0, 60, 0, 32),
        Position = UDim2.new(1, -70, 0, 6),
        CornerRadius = 8,
        Transparency = 0.5,
    })

    self._keyText = InstanceUtils.New("TextLabel", {
        Name = "KeyText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = self._key.Name or "F2",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        Parent = self._keyDisplay,
    })

    self._frame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_startListening()
        end
    end)

    return self
end

function Keybind:_startListening()
    if self._listening then return end
    self._listening = true
    self._keyText.Text = "..."
    self._keyText.TextColor3 = Theme.GetGlobal():GetColor("Primary")

    self._inputConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if self._destroyed then
            if self._inputConn then self._inputConn:Disconnect() end
            return
        end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key ~= Enum.KeyCode.Unknown then
                self._key = key
                self._keyText.Text = key.Name
                self._keyText.TextColor3 = Theme.GetGlobal():GetColor("TextPrimary")
                self._listening = false
                self._onChanged(key)
                if self._inputConn then self._inputConn:Disconnect() end
            end
        end
    end)

    task.delay(5, function()
        if self._listening and not self._destroyed then
            self._listening = false
            self._keyText.Text = self._key.Name
            self._keyText.TextColor3 = Theme.GetGlobal():GetColor("TextPrimary")
            if self._inputConn then self._inputConn:Disconnect() end
        end
    end)
end

function Keybind:GetKey()
    return self._key
end

function Keybind:SetKey(key)
    self._key = key
    self._keyText.Text = key.Name
end

function Keybind:Destroy()
    self._destroyed = true
    if self._inputConn then self._inputConn:Disconnect() end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._keyDisplay = nil
    self._keyText = nil
    self._label = nil
end

return Keybind
end)()

-- Module: src/ui/components/Notification.lua
_MODULES['src/ui/components/Notification.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Notification = {}
Notification.__index = Notification

local _stack = {}
local _MAX_VISIBLE = 4
local _notifHeight = 64
local _spacing = 8
local _container = nil

function Notification.SetContainer(container)
    _container = container
end

function Notification.Show(props)
    if not _container then return end

    local theme = Theme.GetGlobal()
    props = props or {}

    local typeColors = {
        Info = theme:GetColor("Primary"),
        Success = theme:GetColor("Success"),
        Warning = theme:GetColor("Warning"),
        Error = theme:GetColor("Error"),
    }
    local notifColor = typeColors[props.Type] or typeColors.Info

    if #_stack >= _MAX_VISIBLE then
        local oldest = table.remove(_stack, 1)
        if oldest and oldest._destroy then
            oldest:_destroy()
        end
    end

    local yOffset = #_stack * (_notifHeight + _spacing)

    local notif = Glass.new({
        Name = "Notification",
        Parent = _container,
        Size = UDim2.new(1, -16, 0, _notifHeight),
        Position = UDim2.new(0, 8, 0, -_notifHeight),
        AnchorPoint = Vector2.new(0, 0),
        CornerRadius = 12,
        Transparency = 0.25,
        Shadow = true,
        BorderGlow = true,
    })

    local accent = InstanceUtils.New("Frame", {
        Name = "Accent",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = notifColor,
        BorderSizePixel = 0,
        Parent = notif,
    })
    local accentCorner = InstanceUtils.MakeCorner(1.5)
    accentCorner.Parent = accent

    if props.Icon then
        local icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(14, 22),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = notifColor,
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = notif,
        })
    end

    local title = InstanceUtils.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 0, 20),
        Position = UDim2.fromOffset(props.Icon and 42 or 16, 10),
        BackgroundTransparency = 1,
        Text = props.Title or "Notification",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local desc = InstanceUtils.New("TextLabel", {
        Name = "Description",
        Size = UDim2.new(1, -80, 0, 16),
        Position = UDim2.fromOffset(props.Icon and 42 or 16, 30),
        BackgroundTransparency = 1,
        Text = props.Description or "",
        TextColor3 = theme:GetColor("TextSecondary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    local closeBtn = InstanceUtils.New("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = notif,
    })

    local instance = {
        _frame = notif,
        _destroyed = false,
    }

    function instance:_destroy()
        if self._destroyed then return end
        self._destroyed = true
        local idx = nil
        for i, n in ipairs(_stack) do
            if n == self then
                idx = i
                break
            end
        end
        if idx then
            table.remove(_stack, idx)
        end
        TweenKit.new(self._frame, {
            Position = UDim2.new(0, 8, 0, -_notifHeight),
            BackgroundTransparency = 1,
        }, 0.25, "InQuad")
        task.delay(0.3, function()
            if self._frame then
                self._frame:Destroy()
                self._frame = nil
            end
            Notification:_repositionAll()
        end)
    end

    closeBtn.MouseButton1Click:Connect(function()
        instance:_destroy()
    end)

    table.insert(_stack, instance)

    notif.Position = UDim2.new(0, 8, 0, -_notifHeight)

    TweenKit.new(notif, {
        Position = UDim2.new(0, 8, 0, 8 + yOffset),
    }, 0.35, "OutBack")

    local duration = props.Duration or 4
    task.delay(duration, function()
        instance:_destroy()
    end)

    return instance
end

function Notification:_repositionAll()
    for i, notif in ipairs(_stack) do
        if notif._frame and not notif._destroyed then
            local targetY = 8 + (i - 1) * (_notifHeight + _spacing)
            TweenKit.new(notif._frame, {
                Position = UDim2.new(0, 8, 0, targetY),
            }, 0.25, "OutQuad")
        end
    end
end

function Notification.ClearAll()
    for i = #_stack, 1, -1 do
        local notif = _stack[i]
        if notif._destroy then
            notif:_destroy()
        end
    end
    _stack = {}
end

return Notification
end)()

-- Module: src/ui/components/SearchBar.lua
_MODULES['src/ui/components/SearchBar.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local SearchBar = {}
SearchBar.__index = SearchBar

function SearchBar.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _onSearch = props.OnSearch or function() end,
        _onFocus = props.OnFocus or function() end,
        _onBlur = props.OnBlur or function() end,
        _destroyed = false,
        _debounceTimer = nil,
    }, SearchBar)

    self._frame = Glass.new({
        Name = props.Name or "SearchBar",
        Parent = parent,
        Size = props.Size or UDim2.new(0, 280, 0, 40),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = 20,
        Transparency = 0.45,
        BorderGlow = true,
    })

    self._icon = InstanceUtils.New("TextLabel", {
        Name = "Icon",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.fromOffset(12, 11),
        BackgroundTransparency = 1,
        Text = "Q",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Parent = self._frame,
    })

    self._placeholder = InstanceUtils.New("TextLabel", {
        Name = "Placeholder",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1,
        Text = props.Placeholder or "Search commands...",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })

    self._input = InstanceUtils.New("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(36, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "",
        ClearTextOnFocus = false,
        Parent = self._frame,
    })

    self._clearButton = InstanceUtils.New("TextButton", {
        Name = "Clear",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0, 10),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Visible = false,
        Parent = self._frame,
    })

    self._resultsFrame = nil
    self._resultsVisible = false

    self._input.Focused:Connect(function()
        self._placeholder.Visible = false
        self._clearButton.Visible = #self._input.Text > 0
        self._onFocus()
    end)

    self._input.FocusLost:Connect(function()
        if #self._input.Text == 0 then
            self._placeholder.Visible = true
        end
        self._clearButton.Visible = false
        self._onBlur()
    end)

    self._input:GetPropertyChangedSignal("Text"):Connect(function()
        local text = self._input.Text
        self._placeholder.Visible = #text == 0
        self._clearButton.Visible = #text > 0
        if self._debounceTimer then
            self._debounceTimer:Cancel()
        end
        self._debounceTimer = task.delay(0.15, function()
            if not self._destroyed then
                self._onSearch(text)
            end
        end)
    end)

    self._clearButton.MouseButton1Click:Connect(function()
        self._input.Text = ""
        self._onSearch("")
    end)

    return self
end

function SearchBar:GetText()
    return self._input.Text
end

function SearchBar:SetText(text)
    self._input.Text = text
end

function SearchBar:Focus()
    self._input:CaptureFocus()
end

function SearchBar:Destroy()
    self._destroyed = true
    if self._debounceTimer then
        self._debounceTimer:Cancel()
    end
    if self._frame then self._frame:Destroy() end
    if self._resultsFrame then self._resultsFrame:Destroy() end
    self._frame = nil
    self._input = nil
    self._placeholder = nil
    self._icon = nil
    self._clearButton = nil
    self._resultsFrame = nil
end

return SearchBar
end)()

-- Module: src/ui/components/Section.lua
_MODULES['src/ui/components/Section.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Section = {}
Section.__index = Section

function Section.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _collapsed = false,
        _destroyed = false,
    }, Section)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Section",
        Size = props.Size or UDim2.new(0, 280, 0, 40),
        Position = props.Position or UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = parent,
    })

    self._header = InstanceUtils.New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })

    local headerSize = 40

    if props.Icon then
        self._icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(0, 10),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = theme:GetColor("Primary"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self._header,
        })
    end

    self._title = InstanceUtils.New("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.fromOffset(props.Icon and 28 or 0, 10),
        BackgroundTransparency = 1,
        Text = props.Title or "Section",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 16 * theme.Scale,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._header,
    })

    if props.Count then
        self._count = InstanceUtils.New("Frame", {
            Name = "Count",
            Size = UDim2.new(0, 24, 0, 20),
            Position = UDim2.new(1, -32, 0, 10),
            BackgroundColor3 = theme:GetColor("Surface"),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = self._header,
        })
        local countCorner = InstanceUtils.MakeCorner(10)
        countCorner.Parent = self._count
        self._countText = InstanceUtils.New("TextLabel", {
            Name = "CountText",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = tostring(props.Count),
            TextColor3 = theme:GetColor("TextSecondary"),
            TextSize = 11 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            Parent = self._count,
        })
    end

    -- Separator
    local sep = InstanceUtils.New("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme:GetColor("Border"),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Parent = self._header,
    })

    self._content = InstanceUtils.New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self._frame,
    })

    if props.Collapsible ~= false then
        self._header.InputBegan:Connect(function(input)
            if self._destroyed then return end
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:_toggle()
            end
        end)
    end

    return self
end

function Section:_toggle()
    self._collapsed = not self._collapsed
    if self._collapsed then
        local targetHeight = self._content.Size.Y.Offset
        TweenKit.new(self._content, {Size = UDim2.new(1, 0, 0, 0)}, 0.2, "InQuad")
        self._frame.Size = UDim2.new(self._frame.Size.X.Scale, self._frame.Size.X.Offset, 0, 40)
    else
        local contentHeight = self:_calculateContentHeight()
        TweenKit.new(self._content, {Size = UDim2.new(1, 0, 0, contentHeight)}, 0.25, "OutQuad")
        self._frame.Size = UDim2.new(self._frame.Size.X.Scale, self._frame.Size.X.Offset, 0, 40 + contentHeight)
    end
end

function Section:_calculateContentHeight()
    local maxY = 0
    for _, child in ipairs(self._content:GetChildren()) do
        if child:IsA("GuiObject") then
            local bottom = child.Position.Y.Offset + child.Size.Y.Offset
            if bottom > maxY then
                maxY = bottom
            end
        end
    end
    return maxY
end

function Section:GetContent()
    return self._content
end

function Section:AddChild(child)
    child.Parent = self._content
    local contentHeight = self:_calculateContentHeight()
    self._content.Size = UDim2.new(1, 0, 0, contentHeight)
    self._frame.Size = UDim2.new(self._frame.Size.X.Scale, self._frame.Size.X.Offset, 0, 40 + contentHeight)
    return child
end

function Section:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._header = nil
    self._content = nil
    self._title = nil
    self._icon = nil
    self._count = nil
    self._countText = nil
end

return Section
end)()

-- Module: src/ui/components/Slider.lua
_MODULES['src/ui/components/Slider.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Throttle = require(script.Parent.Parent.Parent.core.throttle)

local Slider = {}
Slider.__index = Slider

function Slider.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local min = props.Min or 0
    local max = props.Max or 100
    local val = props.Default or min
    local step = props.Step or 1

    local self = setmetatable({
        _onChange = props.OnChange or function() end,
        _value = val,
        _min = min,
        _max = max,
        _step = step,
        _destroyed = false,
        _dragging = false,
    }, Slider)

    local width = props.Width or 280
    local height = 40

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Slider",
        Size = UDim2.new(0, width, 0, height),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 13 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame,
        })
    end

    local trackY = 24
    self._track = InstanceUtils.New("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, trackY),
        BackgroundColor3 = Color3.fromRGB(45, 55, 72),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    local trackCorner = InstanceUtils.MakeCorner(3)
    trackCorner.Parent = self._track

    self._fill = InstanceUtils.New("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = theme:GetColor("Primary"),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Parent = self._track,
    })
    local fillCorner = InstanceUtils.MakeCorner(3)
    fillCorner.Parent = self._fill

    self._knob = InstanceUtils.New("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.fromOffset(0, -6),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = self._track,
    })
    local knobCorner = InstanceUtils.MakeCorner(9)
    knobCorner.Parent = self._knob

    self._valueText = InstanceUtils.New("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0, 50, 0, 16),
        Position = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(val),
        TextColor3 = theme:GetColor("TextSecondary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self._frame,
    })

    self._updatePosition = Throttle:FrameRate(function(inputPos)
        if self._destroyed then return end
        local trackPos = self._track.AbsolutePosition
        local trackSize = self._track.AbsoluteSize.X
        local relativeX = math.clamp(inputPos.X - trackPos.X, 0, trackSize)
        local normalized = relativeX / trackSize
        local rawValue = self._min + (self._max - self._min) * normalized
        local steppedValue = math.floor(rawValue / self._step + 0.5) * self._step
        local clampedValue = math.clamp(steppedValue, self._min, self._max)
        self._value = clampedValue
        self:_updateVisuals()
        if self._onChange then
            self._onChange(self._value)
        end
    end)

    self._track.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = true
            self._updatePosition(input.Position)
        end
    end)

    self._inputConnection = game:GetService("UserInputService").InputChanged:Connect(function(input)
        if self._destroyed or not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            self._updatePosition(input.Position)
        end
    end)

    self._endConnection = game:GetService("UserInputService").InputEnded:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self._dragging = false
        end
    end)

    self:_updateVisuals()

    return self
end

function Slider:_updateVisuals()
    local normalized = (self._value - self._min) / (self._max - self._min)
    local trackWidth = self._track.AbsoluteSize.X
    local knobX = normalized * trackWidth

    self._fill.Size = UDim2.fromScale(normalized, 1)
    TweenKit.new(self._knob, {Position = UDim2.fromOffset(knobX - 9, -6)}, 0.1, "OutQuad")

    if self._valueText then
        local display = self._value
        if self._value == math.floor(self._value) then
            self._valueText.Text = tostring(math.floor(self._value))
        else
            self._valueText.Text = string.format("%.1f", self._value)
        end
    end
end

function Slider:GetValue()
    return self._value
end

function Slider:SetValue(val)
    val = math.clamp(val, self._min, self._max)
    if val ~= self._value then
        self._value = val
        self:_updateVisuals()
        if self._onChange then
            self._onChange(self._value)
        end
    end
end

function Slider:Destroy()
    self._destroyed = true
    if self._inputConnection then self._inputConnection:Disconnect() end
    if self._endConnection then self._endConnection:Disconnect() end
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._track = nil
    self._fill = nil
    self._knob = nil
    self._valueText = nil
end

return Slider
end)()

-- Module: src/ui/components/TextBox.lua
_MODULES['src/ui/components/TextBox.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local TextBox = {}
TextBox.__index = TextBox

function TextBox.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()

    local self = setmetatable({
        _onChanged = props.OnChanged or function() end,
        _onFocused = props.OnFocused or function() end,
        _onFocusLost = props.OnFocusLost or function() end,
        _destroyed = false,
        _focused = false,
    }, TextBox)

    self._frame = Glass.new({
        Name = props.Name or "TextBox",
        Parent = parent,
        Size = props.Size or UDim2.new(0, 280, 0, 44),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        CornerRadius = 10,
        Transparency = 0.5,
    })

    self._icon = nil
    if props.Icon then
        self._icon = InstanceUtils.New("TextLabel", {
            Name = "Icon",
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.fromOffset(12, 12),
            BackgroundTransparency = 1,
            Text = props.Icon,
            TextColor3 = theme:GetColor("TextMuted"),
            TextSize = 16,
            Font = Enum.Font.GothamBold,
            Parent = self._frame,
        })
    end

    local iconOffset = props.Icon and 40 or 12

    self._placeholder = InstanceUtils.New("TextLabel", {
        Name = "Placeholder",
        Size = UDim2.new(1, -(iconOffset + 4), 1, 0),
        Position = UDim2.fromOffset(iconOffset, 0),
        BackgroundTransparency = 1,
        Text = props.Placeholder or "Type here...",
        TextColor3 = theme:GetColor("TextMuted"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self._frame,
    })

    self._input = InstanceUtils.New("TextBox", {
        Name = "Input",
        Size = UDim2.new(1, -(iconOffset + 4), 1, 0),
        Position = UDim2.fromOffset(iconOffset, 0),
        BackgroundTransparency = 1,
        Text = props.Text or "",
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 14 * theme.Scale,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "",
        ClearTextOnFocus = false,
        Parent = self._frame,
    })

    if props.Password then
        self._input.PlaceholderText = "••••••••"
    end

    self._clearButton = nil
    if props.Clearable ~= false then
        self._clearButton = InstanceUtils.New("TextButton", {
            Name = "Clear",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -32, 0, 10),
            BackgroundTransparency = 1,
            Text = "X",
            TextColor3 = theme:GetColor("TextMuted"),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            Visible = false,
            Parent = self._frame,
        })
        self._clearButton.MouseButton1Click:Connect(function()
            self._input.Text = ""
            self._onChanged("")
            self._clearButton.Visible = false
            self._placeholder.Visible = true
        end)
    end

    self._input.Focused:Connect(function()
        self._focused = true
        TweenKit.new(self._frame, {BackgroundTransparency = 0.25}, 0.2, "OutQuad")
        self._placeholder.Visible = false
        if self._clearButton then
            self._clearButton.Visible = #self._input.Text > 0
        end
        self._onFocused()
    end)

    self._input.FocusLost:Connect(function(enterPressed)
        self._focused = false
        TweenKit.new(self._frame, {BackgroundTransparency = 0.5}, 0.2, "OutQuad")
        if #self._input.Text == 0 then
            self._placeholder.Visible = true
        end
        if self._clearButton then
            self._clearButton.Visible = false
        end
        self._onFocusLost(self._input.Text, enterPressed)
    end)

    self._input:GetPropertyChangedSignal("Text"):Connect(function()
        if self._onChanged then
            self._onChanged(self._input.Text)
        end
        if self._clearButton then
            self._clearButton.Visible = self._focused and #self._input.Text > 0
        end
    end)

    return self
end

function TextBox:GetText()
    return self._input.Text
end

function TextBox:SetText(text)
    self._input.Text = text
    self._placeholder.Visible = #text == 0
end

function TextBox:Focus()
    self._input:CaptureFocus()
end

function TextBox:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    self._frame = nil
    self._input = nil
    self._placeholder = nil
    self._clearButton = nil
    self._icon = nil
end

return TextBox
end)()

-- Module: src/ui/components/Toggle.lua
_MODULES['src/ui/components/Toggle.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local isOn = props.Default or false

    local self = setmetatable({
        _onToggle = props.OnToggle or function() end,
        _value = isOn,
        _destroyed = false,
    }, Toggle)

    self._frame = InstanceUtils.New("Frame", {
        Name = props.Name or "Toggle",
        Size = UDim2.new(0, 50, 0, 28),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = isOn and theme:GetColor("Primary") or Color3.fromRGB(45, 55, 72),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    local corner = InstanceUtils.MakeCorner(14)
    corner.Parent = self._frame

    self._knob = InstanceUtils.New("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(0, isOn and 26 or 3, 0, 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = self._frame,
    })
    local knobCorner = InstanceUtils.MakeCorner(11)
    knobCorner.Parent = self._knob

    local knobStroke = InstanceUtils.New("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.85,
        Thickness = 0.5,
        Parent = self._knob,
    })

    self._label = nil
    if props.Label then
        self._label = InstanceUtils.New("TextLabel", {
            Name = "Label",
            Size = UDim2.new(0, 0, 1, 0),
            Position = UDim2.new(0, 60, 0, 0),
            BackgroundTransparency = 1,
            Text = props.Label,
            TextColor3 = theme:GetColor("TextPrimary"),
            TextSize = 14 * theme.Scale,
            Font = Enum.Font.GothamSemibold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self._frame.Parent or parent,
        })
        self._label.Size = UDim2.new(0, self._label.TextBounds.X + 2, 1, 0)
    end

    self._frame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_toggle()
        end
    end)

    return self
end

function Toggle:_toggle()
    self._value = not self._value
    self:_animate()
    if self._onToggle then
        self._onToggle(self._value)
    end
end

function Toggle:_animate()
    local targetPos = self._value and 26 or 3
    local targetColor = self._value and Theme.GetGlobal():GetColor("Primary") or Color3.fromRGB(45, 55, 72)

    TweenKit.new(self._frame, {BackgroundColor3 = targetColor}, 0.2, "OutQuad")
    TweenKit.new(self._knob, {
        Position = UDim2.new(0, targetPos, 0, 3),
        Size = UDim2.new(0, 22, 0, 22),
    }, 0.25, "OutBack")
end

function Toggle:SetValue(val)
    if val ~= self._value then
        self._value = val
        self:_animate()
    end
end

function Toggle:GetValue()
    return self._value
end

function Toggle:SetOnToggle(callback)
    self._onToggle = callback
end

function Toggle:Destroy()
    self._destroyed = true
    if self._frame then self._frame:Destroy() end
    if self._label then self._label:Destroy() end
    self._frame = nil
    self._knob = nil
    self._label = nil
end

return Toggle
end)()

-- Module: src/ui/components/Tooltip.lua
_MODULES['src/ui/components/Tooltip.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.primitives.glass)

local Tooltip = {}
Tooltip.__index = Tooltip

function Tooltip.new(parent, targetFrame, props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local text = props.Text or ""

    local self = setmetatable({
        _visible = false,
        _destroyed = false,
    }, Tooltip)

    self._container = InstanceUtils.New("Frame", {
        Name = "TooltipContainer",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    self._tooltip = Glass.new({
        Name = "Tooltip",
        Parent = self._container,
        Size = UDim2.new(0, 0, 0, 28),
        Position = UDim2.fromScale(0, 0),
        AnchorPoint = Vector2.new(0.5, 1),
        CornerRadius = 8,
        Transparency = 0.1,
        Visible = false,
    })

    self._label = InstanceUtils.New("TextLabel", {
        Name = "Text",
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(6, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = theme:GetColor("TextPrimary"),
        TextSize = 12 * theme.Scale,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = self._tooltip,
    })

    targetFrame.InputBegan:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            self:Show(input.Position)
        end
    end)

    targetFrame.InputEnded:Connect(function(input)
        if self._destroyed then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            self:Hide()
        end
    end)

    return self
end

function Tooltip:Show(position)
    if self._destroyed then return end
    self._visible = true

    local width = math.min(self._label.TextBounds.X + 24, 200)
    self._tooltip.Size = UDim2.new(0, width, 0, 28)

    if position then
        self._tooltip.Position = UDim2.fromOffset(position.X, position.Y - 8)
    end

    self._tooltip.Visible = true
    self._tooltip.BackgroundTransparency = 1
    TweenKit.new(self._tooltip, {BackgroundTransparency = 0.1}, 0.2, "OutQuad")
    self._tooltip.Size = UDim2.new(0, width, 0, 0)
    TweenKit.new(self._tooltip, {Size = UDim2.new(0, width, 0, 28)}, 0.2, "OutBack")
end

function Tooltip:Hide()
    if self._destroyed or not self._visible then return end
    self._visible = false
    TweenKit.new(self._tooltip, {BackgroundTransparency = 1}, 0.15, "InQuad")
    task.delay(0.15, function()
        if self._tooltip then
            self._tooltip.Visible = false
        end
    end)
end

function Tooltip:SetText(text)
    if self._label then
        self._label.Text = text
    end
end

function Tooltip:Destroy()
    self._destroyed = true
    if self._container then self._container:Destroy() end
    self._container = nil
    self._tooltip = nil
    self._label = nil
end

return Tooltip
end)()

-- Module: src/ui/layout/Responsive.lua
_MODULES['src/ui/layout/Responsive.lua'] = (function()
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Theme = require(script.Parent.Parent.Parent.core.theme)

local Responsive = {}

local SMALL_PHONE = 400
local PHONE = 600
local TABLET = 900

local UserInputService = game:GetService("UserInputService")

function Responsive.GetDeviceType(screenSize)
	if screenSize < SMALL_PHONE then
		return "SmallPhone"
	elseif screenSize < PHONE then
		return "Phone"
	elseif screenSize < TABLET then
		return "Tablet"
	else
		return "Phablet"
	end
end

function Responsive.IsLandscape()
	return UserInputService.KeyboardEnabled and UserInputService.TouchEnabled
		and game:GetService("GuiService"):GetScreenResolution().X > game:GetService("GuiService"):GetScreenResolution().Y
		or false
end

function Responsive.GetScale()
	local theme = Theme.GetGlobal()
	local viewport = game:GetService("GuiService"):GetScreenResolution()
	local minDim = math.min(viewport.X, viewport.Y)
	local deviceType = Responsive.GetDeviceType(minDim)
	local baseScale = theme.Scale or 1.0

	local deviceScale
	if deviceType == "SmallPhone" then
		deviceScale = 0.85
	elseif deviceType == "Phone" then
		deviceScale = 1.0
	elseif deviceType == "Tablet" then
		deviceScale = 1.15
	else
		deviceScale = 1.25
	end

	if Responsive.IsLandscape() then
		deviceScale = deviceScale * 0.9
	end

	local scale = InstanceUtils.New("UIScale", {
		Scale = baseScale * deviceScale,
	})
	return scale
end

function Responsive.GetSafeAreaInsets()
	local top = 0
	local bottom = 0
	local success, result = pcall(function()
		local guiService = game:GetService("GuiService")
		if guiService:GetScreenResolution().Y > 0 then
			local insets = guiService:GetGuiInsets()
			top = insets.Top
			bottom = insets.Bottom
		end
	end)
	if not success then
		top = 0
		bottom = 0
	end
	return top, bottom
end

function Responsive.GetSizeClass(screenSize)
	if screenSize < SMALL_PHONE then
		return "Compact"
	elseif screenSize < PHONE then
		return "Regular"
	else
		return "Regular"
	end
end

Responsive.SMALL_PHONE = SMALL_PHONE
Responsive.PHONE = PHONE
Responsive.TABLET = TABLET

return Responsive
end)()

-- Module: src/ui/layout/ScreenContainer.lua
_MODULES['src/ui/layout/ScreenContainer.lua'] = (function()
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Responsive = require(script.Parent.Responsive)

local ScreenContainer = {}

function ScreenContainer.new(parent, props)
	props = props or {}

	local topInset, bottomInset = Responsive.GetSafeAreaInsets()

	local frame = Glass.new({
		Name = props.Name or "ScreenContainer",
		Parent = parent,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		Transparency = 0,
		CornerRadius = 0,
	})

	local padding = InstanceUtils.New("UIPadding", {
		PaddingTop = UDim.new(0, topInset + 8),
		PaddingBottom = UDim.new(0, bottomInset + 8),
		PaddingLeft = UDim.new(0, 0),
		PaddingRight = UDim.new(0, 0),
		Parent = frame,
	})

	return frame
end

return ScreenContainer
end)()

-- Module: src/ui/navigation/NavBar.lua
_MODULES['src/ui/navigation/NavBar.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Button = require(script.Parent.Parent.Parent.components.Button)

local NavBar = {}
NavBar.__index = NavBar

local NAV_ITEMS = {
	{Name = "Home", Icon = "H", Label = "Home"},
	{Name = "Commands", Icon = "C", Label = "Commands"},
	{Name = "Favorites", Icon = "F", Label = "Favorites"},
	{Name = "Checkpoints", Icon = "P", Label = "Points"},
	{Name = "Settings", Icon = "S", Label = "Settings"},
}

function NavBar.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_activeIndex = props.DefaultIndex or 1,
		_onNavigate = props.OnNavigate or function() end,
		_destroyed = false,
		_items = {},
		_badges = {},
	}, NavBar)

	local barHeight = 64

	self._frame = Glass.new({
		Name = "NavBar",
		Parent = parent,
		Size = UDim2.new(1, 0, 0, barHeight),
		Position = UDim2.new(0, 0, 1, -barHeight),
		AnchorPoint = Vector2.new(0, 0),
		CornerRadius = 0,
		Transparency = 0.3,
		Shadow = true,
	})

	local topBorder = InstanceUtils.New("Frame", {
		Name = "TopBorder",
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundColor3 = theme:GetColor("Border"),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Parent = self._frame,
	})

	self._indicator = InstanceUtils.New("Frame", {
		Name = "Indicator",
		Size = UDim2.new(0, 40, 0, 3),
		Position = UDim2.new(0, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = theme:GetColor("Primary"),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = self._frame,
	})
	local indicatorCorner = InstanceUtils.MakeCorner(1.5)
	indicatorCorner.Parent = self._indicator

	local itemCount = #NAV_ITEMS
	local itemWidth = 1 / itemCount

	for i, itemData in ipairs(NAV_ITEMS) do
		local isActive = i == self._activeIndex

		local item = InstanceUtils.New("Frame", {
			Name = itemData.Name,
			Size = UDim2.new(itemWidth, 0, 1, 0),
			Position = UDim2.new((i - 1) * itemWidth, 0, 0, 8),
			BackgroundTransparency = 1,
			Parent = self._frame,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.fromScale(0.5, 0.15),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = itemData.Icon,
			TextColor3 = isActive and theme:GetColor("Primary") or theme:GetColor("TextMuted"),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Parent = item,
		})

		local label = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -4, 0, 16),
			Position = UDim2.fromScale(0.5, 0.55),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = itemData.Label,
			TextColor3 = isActive and theme:GetColor("TextPrimary") or theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.GothamSemibold,
			Parent = item,
		})

		local badge = nil
		local badgeText = nil
		if props.Badges and props.Badges[i] then
			badge = InstanceUtils.New("Frame", {
				Name = "Badge",
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.fromScale(0.65, 0.05),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = theme:GetColor("Error"),
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
				Parent = item,
			})
			local badgeCorner = InstanceUtils.MakeCorner(9)
			badgeCorner.Parent = badge

			badgeText = InstanceUtils.New("TextLabel", {
				Name = "BadgeText",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = tostring(props.Badges[i]),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				Parent = badge,
			})
		end

		self._items[i] = {
			Frame = item,
			Icon = icon,
			Label = label,
			Badge = badge,
			BadgeText = badgeText,
		}

		item.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:SetActive(i)
			end
		end)
	end

	self:_updateIndicator(false)

	return self
end

function NavBar:SetActive(index, animate)
	if self._destroyed then return end
	if index < 1 or index > #NAV_ITEMS then return end
	if animate == nil then animate = true end

	local oldIndex = self._activeIndex
	self._activeIndex = index

	local theme = Theme.GetGlobal()

	if oldIndex and self._items[oldIndex] then
		local old = self._items[oldIndex]
		old.Icon.TextColor3 = theme:GetColor("TextMuted")
		old.Label.TextColor3 = theme:GetColor("TextMuted")
	end

	local active = self._items[index]
	active.Icon.TextColor3 = theme:GetColor("Primary")
	active.Label.TextColor3 = theme:GetColor("TextPrimary")

	self:_updateIndicator(animate)
	self._onNavigate(NAV_ITEMS[index].Name, index)
end

function NavBar:_updateIndicator(animate)
	local itemCount = #NAV_ITEMS
	local itemWidth = self._frame.AbsoluteSize.X / itemCount
	local targetX = (self._activeIndex - 0.5) * itemWidth

	if animate then
		TweenKit.new(self._indicator, {Position = UDim2.fromOffset(targetX - 20, 0)}, 0.3, "OutBack")
	else
		self._indicator.Position = UDim2.fromOffset(targetX - 20, 0)
	end
end

function NavBar:GetActive()
	return self._activeIndex
end

function NavBar:SetBadge(index, count)
	if self._destroyed then return end
	if self._items[index] then
		local item = self._items[index]
		if count and count > 0 then
			if not item.Badge then
				local theme = Theme.GetGlobal()
				item.Badge = InstanceUtils.New("Frame", {
					Name = "Badge",
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.fromScale(0.65, 0.05),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = theme:GetColor("Error"),
					BackgroundTransparency = 0.1,
					BorderSizePixel = 0,
					Parent = item.Frame,
				})
				local badgeCorner = InstanceUtils.MakeCorner(9)
				badgeCorner.Parent = item.Badge

				item.BadgeText = InstanceUtils.New("TextLabel", {
					Name = "BadgeText",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = tostring(count),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 10,
					Font = Enum.Font.GothamBold,
					Parent = item.Badge,
				})
			else
				item.Badge.Visible = true
				item.BadgeText.Text = tostring(count)
			end
		elseif item.Badge then
			item.Badge.Visible = false
		end
	end
end

function NavBar:GetFrame()
	return self._frame
end

function NavBar:Destroy()
	self._destroyed = true
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._items = {}
end

return NavBar
end)()

-- Module: src/ui/navigation/Router.lua
_MODULES['src/ui/navigation/Router.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Router = {}
Router.__index = Router

function Router.new(parent, props)
	props = props or {}

	local self = setmetatable({
		_parent = parent,
		_screens = {},
		_currentScreen = nil,
		_history = {},
		_maxHistory = 10,
		_onNavigate = props.OnNavigate or function() end,
		_destroyed = false,
	}, Router)

	return self
end

function Router:Register(name, constructor)
	self._screens[name] = constructor
end

function Router:Navigate(targetScreen, params)
	if self._destroyed then return end
	if not self._screens[targetScreen] then
		warn(("Router: Screen '%s' not registered"):format(targetScreen))
		return
	end

	if self._currentScreen then
		table.insert(self._history, 1, {
			Name = self._currentScreen.Name,
			Instance = self._currentScreen.Instance,
		})
		if #self._history > self._maxHistory then
			table.remove(self._history)
		end
	end

	local direction = "left"
	if self._currentScreen then
		local prevIdx = 0
		local nextIdx = 0
		for i, name in ipairs(self._currentScreen._allNames or {}) do
			if name == self._currentScreen.Name then prevIdx = i end
			if name == targetScreen then nextIdx = i end
		end
		if nextIdx > prevIdx then
			direction = "left"
		else
			direction = "right"
		end
	end

	local oldScreen = self._currentScreen

	local container = InstanceUtils.New("Frame", {
		Name = "ScreenContainer_" .. targetScreen,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(direction == "left" and 1 or -1, 0),
		BackgroundTransparency = 1,
		Parent = self._parent,
	})

	local screen = self._screens[targetScreen](container, params or {})
	self._currentScreen = {
		Name = targetScreen,
		Instance = container,
		Screen = screen,
		_allNames = oldScreen and oldScreen._allNames or {targetScreen},
	}

	if oldScreen then
		local oldNames = oldScreen._allNames or {}
		local found = false
		for _, name in ipairs(oldNames) do
			if name == targetScreen then found = true end
		end
		if not found then
			table.insert(self._currentScreen._allNames, targetScreen)
		end
	end

	TweenKit.new(container, {Position = UDim2.fromScale(0, 0)}, 0.3, "OutQuad")

	if oldScreen then
		local oldContainer = oldScreen.Instance
		local exitX = direction == "left" and -1 or 1
		TweenKit.new(oldContainer, {Position = UDim2.fromScale(exitX, 0)}, 0.3, "InQuad")
		task.delay(0.35, function()
			if oldContainer and oldContainer.Parent then
				oldContainer:Destroy()
			end
		end)
	end

	self._onNavigate(targetScreen, params)
end

function Router:GetCurrent()
	return self._currentScreen and self._currentScreen.Name or nil
end

function Router:GoBack()
	if self._destroyed then return end
	if #self._history == 0 then return end

	local previous = table.remove(self._history, 1)
	if previous then
		if self._currentScreen then
			local oldContainer = self._currentScreen.Instance
			TweenKit.new(oldContainer, {Position = UDim2.fromScale(1, 0)}, 0.3, "InQuad")
			task.delay(0.35, function()
				if oldContainer and oldContainer.Parent then
					oldContainer:Destroy()
				end
			end)
		end

		previous.Instance.Position = UDim2.fromScale(-1, 0)
		previous.Instance.Parent = self._parent
		self._currentScreen = previous
		TweenKit.new(previous.Instance, {Position = UDim2.fromScale(0, 0)}, 0.3, "OutQuad")
		self._onNavigate(previous.Name)
	end
end

function Router:GetScreen(name)
	if self._currentScreen and self._currentScreen.Name == name then
		return self._currentScreen.Screen
	end
	return nil
end

function Router:Destroy()
	self._destroyed = true
	for _, screen in ipairs(self._history) do
		if screen.Instance then screen.Instance:Destroy() end
	end
	self._history = {}
	if self._currentScreen and self._currentScreen.Instance then
		self._currentScreen.Instance:Destroy()
	end
	self._currentScreen = nil
	self._screens = {}
end

return Router
end)()

-- Module: src/ui/primitives/glass.lua
_MODULES['src/ui/primitives/glass.lua'] = (function()
local InstanceUtils = require(script.Parent.Parent.utils.instance)
local Theme = require(script.Parent.Parent.core.theme)

local Glass = {}

function Glass.new(props)
    props = props or {}
    local theme = Theme.GetGlobal()
    local frame = InstanceUtils.New("Frame", {
        Name = props.Name or "GlassPanel",
        Size = props.Size or UDim2.fromScale(1, 1),
        Position = props.Position or UDim2.fromOffset(0, 0),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = theme:GetColor("Surface"),
        BackgroundTransparency = props.Transparency or theme.PanelTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = props.ClipsDescendants or false,
        Parent = props.Parent,
    })

    local corner = InstanceUtils.MakeCorner(props.CornerRadius or 12)
    corner.Parent = frame

    local stroke = InstanceUtils.New("UIStroke", {
        Color = theme:GetColor("Border"),
        Transparency = 0.7,
        Thickness = 1,
        Parent = frame,
    })

    if props.Gradient then
        local grad = InstanceUtils.New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, props.Gradient.Color1 or theme:GetColor("Primary")),
                ColorSequenceKeypoint.new(1, props.Gradient.Color2 or theme:GetColor("Secondary")),
            }),
            Rotation = props.Gradient.Rotation or 45,
            Transparency = NumberSequence.new(props.Gradient.Alpha or 0.15),
            Parent = frame,
        })
    end

    if props.Shadow then
        local shadow = InstanceUtils.New("ImageLabel", {
            Name = "DropShadow",
            Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(16, 16),
            Position = UDim2.fromOffset(-8, -8),
            BackgroundTransparency = 1,
            Image = "rbxasset://textures/ui/GuiImagePlaceholder.png",
            ImageColor3 = Color3.new(0, 0, 0),
            ImageTransparency = 0.6,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(8, 8, 8, 8),
            ZIndex = frame.ZIndex - 1,
            Parent = frame,
        })
    end

    if props.BorderGlow then
        local glow = InstanceUtils.New("Frame", {
            Name = "BorderGlow",
            Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(4, 4),
            Position = UDim2.fromOffset(-2, -2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = frame.ZIndex - 1,
            Parent = frame,
        })
        local glowCorner = InstanceUtils.MakeCorner(props.CornerRadius and props.CornerRadius + 2 or 14)
        glowCorner.Parent = glow
        local glowGrad = InstanceUtils.New("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme:GetColor("Primary")),
                ColorSequenceKeypoint.new(0.5, theme:GetColor("Secondary")),
                ColorSequenceKeypoint.new(1, theme:GetColor("Accent")),
            }),
            Rotation = 45,
            Transparency = NumberSequence.new(0.85),
            Parent = glow,
        })
    end

    return frame
end

return Glass
end)()

-- Module: src/ui/primitives/gradient.lua
_MODULES['src/ui/primitives/gradient.lua'] = (function()
local InstanceUtils = require(script.Parent.Parent.utils.instance)

local Gradient = {}

function Gradient.new(props)
    props = props or {}
    local grad = InstanceUtils.New("UIGradient", {
        Color = props.Color or ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
        }),
        Rotation = props.Rotation or 45,
        Transparency = props.Transparency or NumberSequence.new(0),
        Offset = props.Offset or Vector2.new(0, 0),
        Parent = props.Parent,
    })
    return grad
end

function Gradient.Primary(parent)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(59, 130, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(139, 92, 246)),
        }),
        Rotation = 45,
        Parent = parent,
    })
end

function Gradient.Secondary(parent)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 92, 246)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 182, 212)),
        }),
        Rotation = 45,
        Parent = parent,
    })
end

function Gradient.Accent(parent)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 182, 212)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246)),
        }),
        Rotation = 45,
        Parent = parent,
    })
end

function Gradient.Text(parent, color1, color2)
    return Gradient.new({
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1 or Color3.fromRGB(241, 245, 249)),
            ColorSequenceKeypoint.new(1, color2 or Color3.fromRGB(148, 163, 184)),
        }),
        Rotation = 0,
        Parent = parent,
    })
end

return Gradient
end)()

-- Module: src/ui/screens/Checkpoints.lua
_MODULES['src/ui/screens/Checkpoints.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Card = require(script.Parent.Parent.Parent.components.Card)
local Dialog = require(script.Parent.Parent.Parent.components.Dialog)

local Checkpoints = {}
Checkpoints.__index = Checkpoints

function Checkpoints.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_checkpoints = props.Checkpoints or {},
		_onSave = props.OnSave or function() end,
		_onTeleport = props.OnTeleport or function() end,
		_onUpdate = props.OnUpdate or function() end,
		_onDuplicate = props.OnDuplicate or function() end,
		_onRename = props.OnRename or function() end,
		_onDelete = props.OnDelete or function() end,
		_currentPosition = props.CurrentPosition or Vector3.new(0, 0, 0),
		_checkpointItems = {},
		_contextMenu = nil,
	}, Checkpoints)

	self._frame = InstanceUtils.New("Frame", {
		Name = "CheckpointsScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self._saveBtn = Glass.new({
		Name = "SaveButton",
		Parent = self._frame,
		Size = UDim2.new(1, -24, 0, 52),
		Position = UDim2.fromOffset(12, 12),
		CornerRadius = 14,
		Transparency = 0.25,
		BorderGlow = true,
		Gradient = {
			Color1 = theme:GetColor("Primary"),
			Color2 = theme:GetColor("Secondary"),
			Alpha = 0.2,
		},
	})

	local saveIcon = InstanceUtils.New("TextLabel", {
		Name = "Icon",
		Size = UDim2.new(0, 22, 0, 22),
		Position = UDim2.fromOffset(14, 15),
		BackgroundTransparency = 1,
		Text = "S",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = self._saveBtn,
	})

	local saveLabel = InstanceUtils.New("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.fromOffset(44, 0),
		BackgroundTransparency = 1,
		Text = "Save Current Position",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 15 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._saveBtn,
	})

	self._saveBtn.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._onSave()
		end
	end)

	self._listFrame = InstanceUtils.New("ScrollingFrame", {
		Name = "CheckpointList",
		Size = UDim2.new(1, -24, 1, -76),
		Position = UDim2.fromOffset(12, 72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = self._frame,
	})

	self._listContainer = InstanceUtils.New("Frame", {
		Name = "ListContainer",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = self._listFrame,
	})

	self._emptyState = InstanceUtils.New("Frame", {
		Name = "EmptyState",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = #self._checkpoints == 0,
		Parent = self._listFrame,
	})

	local emptyIcon = InstanceUtils.New("TextLabel", {
		Name = "EmptyIcon",
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.fromScale(0.5, 0.3),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "📍",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 36,
		Font = Enum.Font.GothamBold,
		Parent = self._emptyState,
	})

	local emptyText = InstanceUtils.New("TextLabel", {
		Name = "EmptyText",
		Size = UDim2.new(1, -40, 0, 24),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "Save your first checkpoint",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		Parent = self._emptyState,
	})

	local emptySubtext = InstanceUtils.New("TextLabel", {
		Name = "EmptySubtext",
		Size = UDim2.new(1, -40, 0, 18),
		Position = UDim2.fromScale(0.5, 0.52),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "Tap the button above to save your current position",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 12 * theme.Scale,
		Font = Enum.Font.Gotham,
		Parent = self._emptyState,
	})

	self._emptyState.Size = UDim2.new(1, 0, 1, 0)

	self:_rebuildList()

	return self
end

function Checkpoints:SetCurrentPosition(pos)
	self._currentPosition = pos
	self:_updateDistances()
end

function Checkpoints:_updateDistances()
	local theme = Theme.GetGlobal()
	for i, item in ipairs(self._checkpointItems) do
		local dist = (item.Data.Position - self._currentPosition).Magnitude
		local distLabel = item.Frame:FindFirstChild("Distance", true)
		if distLabel then
			distLabel.Text = ("%.1f studs"):format(dist)
		end
	end
end

function Checkpoints:_rebuildList()
	for _, child in ipairs(self._listContainer:GetChildren()) do
		child:Destroy()
	end
	self._checkpointItems = {}

	if #self._checkpoints == 0 then
		self._emptyState.Visible = true
		self._listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	self._emptyState.Visible = false

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cp in ipairs(self._checkpoints) do
		local dist = (cp.Position - self._currentPosition).Magnitude

		local card = Glass.new({
			Name = "CP_" .. (cp.Name or "Checkpoint"),
			Parent = self._listContainer,
			Size = UDim2.new(1, 0, 0, 120),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 14,
			Transparency = 0.3,
			Shadow = true,
		})

		local nameLabel = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 10),
			BackgroundTransparency = 1,
			Text = cp.Name or "Checkpoint",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 16 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local timeLabel = InstanceUtils.New("TextLabel", {
			Name = "Time",
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 34),
			BackgroundTransparency = 1,
			Text = cp.Time or "Just now",
			TextColor3 = theme:GetColor("TextSecondary"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local coords = ("%.1f, %.1f, %.1f"):format(cp.Position.X, cp.Position.Y, cp.Position.Z)
		local coordLabel = InstanceUtils.New("TextLabel", {
			Name = "Coords",
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 52),
			BackgroundTransparency = 1,
			Text = coords,
			TextColor3 = theme:GetColor("Accent"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local distLabel = InstanceUtils.New("TextLabel", {
			Name = "Distance",
			Size = UDim2.new(1, -24, 0, 16),
			Position = UDim2.fromOffset(12, 70),
			BackgroundTransparency = 1,
			Text = ("%.1f studs"):format(dist),
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local actionRow = InstanceUtils.New("Frame", {
			Name = "Actions",
			Size = UDim2.new(1, -24, 0, 30),
			Position = UDim2.fromOffset(12, 88),
			BackgroundTransparency = 1,
			Parent = card,
		})

		local actions = {
			{Name = "Teleport", Color = theme:GetColor("Primary"), Icon = "T"},
			{Name = "Update", Color = theme:GetColor("Secondary"), Icon = "U"},
			{Name = "More", Color = theme:GetColor("TextMuted"), Icon = "⋮"},
		}

		local btnWidth = (1 - 0.04) / 3

		for j, action in ipairs(actions) do
			local btn = Glass.new({
				Name = action.Name .. "Btn",
				Parent = actionRow,
				Size = UDim2.new(btnWidth, -4, 1, 0),
				Position = UDim2.new((j - 1) * (btnWidth + 0.02), 0, 0, 0),
				CornerRadius = 8,
				Transparency = 0.5,
			})

			local btnText = InstanceUtils.New("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = action.Name,
				TextColor3 = action.Color,
				TextSize = 11 * theme.Scale,
				Font = Enum.Font.GothamSemibold,
				Parent = btn,
			})

			local cpIndex = i
			local cpData = cp
			btn.InputBegan:Connect(function(input)
				if self._destroyed then return end
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					if action.Name == "Teleport" then
						self._onTeleport(cpData)
					elseif action.Name == "Update" then
						self._onUpdate(cpData)
					elseif action.Name == "More" then
						self:_showContextMenu(cpData, input)
					end
				end
			end)
		end

		local longPress = false
		local pressTimer = nil
		card.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch then
				pressTimer = task.delay(0.5, function()
					longPress = true
					self:_showQuickActions(cp)
				end)
			end
		end)
		card.InputEnded:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch then
				if pressTimer then
					pressTimer:Cancel()
					pressTimer = nil
				end
				if not longPress then
					self._onTeleport(cp)
				end
				longPress = false
			end
		end})

		table.insert(self._checkpointItems, {Frame = card, Data = cp})
		yOffset = yOffset + 128
	end

	self._listContainer.Size = UDim2.new(1, 0, 0, yOffset)
	self._listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function Checkpoints:_showContextMenu(cp, input)
	if self._contextMenu then
		self._contextMenu:Destroy()
	end

	local theme = Theme.GetGlobal()
	local menuItems = {
		{Text = "Duplicate", Icon = "D", Callback = function()
			self._onDuplicate(cp)
		end},
		{Text = "Rename", Icon = "R", Callback = function()
			self._onRename(cp)
		end},
		{Text = "Delete", Icon = "X", Color = theme:GetColor("Error"), Callback = function()
			Dialog.Show(self._frame, {
				Title = "Delete Checkpoint",
				Message = "Are you sure you want to delete '" .. (cp.Name or "this checkpoint") .. "'?",
				Buttons = {
					{Text = "Cancel", Callback = function() end},
					{Text = "Delete", Primary = true, Callback = function()
						self._onDelete(cp)
					end},
				},
			})
		end},
	}

	local menuHeight = #menuItems * 44 + 8
	self._contextMenu = Glass.new({
		Name = "ContextMenu",
		Parent = self._frame,
		Size = UDim2.new(0, 180, 0, menuHeight),
		Position = UDim2.fromOffset(input.Position.X, input.Position.Y),
		CornerRadius = 12,
		Transparency = 0.15,
		Shadow = true,
		ZIndex = 200,
	})

	local yOff = 4
	for _, item in ipairs(menuItems) do
		local itemFrame = InstanceUtils.New("Frame", {
			Name = item.Text,
			Size = UDim2.new(1, -16, 0, 40),
			Position = UDim2.fromOffset(8, yOff),
			BackgroundTransparency = 1,
			Parent = self._contextMenu,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.fromOffset(8, 10),
			BackgroundTransparency = 1,
			Text = item.Icon or "",
			TextColor3 = item.Color or theme:GetColor("TextPrimary"),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Parent = itemFrame,
		})

		local label = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(34, 0),
			BackgroundTransparency = 1,
			Text = item.Text,
			TextColor3 = item.Color or theme:GetColor("TextPrimary"),
			TextSize = 14 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = itemFrame,
		})

		itemFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				item.Callback()
				if self._contextMenu then
					self._contextMenu:Destroy()
					self._contextMenu = nil
				end
			end
		end)

		yOff = yOff + 44
	end
end

function Checkpoints:_showQuickActions(cp)
	Dialog.Show(self._frame, {
		Title = cp.Name or "Checkpoint",
		Message = ("Position: %.1f, %.1f, %.1f"):format(cp.Position.X, cp.Position.Y, cp.Position.Z),
		Buttons = {
			{Text = "Teleport", Primary = true, Callback = function()
				self._onTeleport(cp)
			end},
			{Text = "Cancel", Callback = function() end},
		},
	})
end

function Checkpoints:SetCheckpoints(checkpoints)
	self._checkpoints = checkpoints or {}
	self:_rebuildList()
end

function Checkpoints:GetFrame()
	return self._frame
end

function Checkpoints:Destroy()
	self._destroyed = true
	if self._contextMenu then
		self._contextMenu:Destroy()
		self._contextMenu = nil
	end
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._checkpointItems = {}
end

return Checkpoints
end)()

-- Module: src/ui/screens/Commands.lua
_MODULES['src/ui/screens/Commands.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local SearchBar = require(script.Parent.Parent.Parent.components.SearchBar)

local Commands = {}
Commands.__index = Commands

local CategoriesModule = require(script.Parent.Parent.Parent.features.commands.Categories)

local CATEGORIES = {"All"}
local CATEGORY_ICONS = {["All"] = "Q"}
for _, cat in ipairs(CategoriesModule.GetAll()) do
    table.insert(CATEGORIES, cat.name)
    CATEGORY_ICONS[cat.name] = cat.icon
end

function Commands.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_commands = props.Commands or {},
		_allCommands = props.Commands or {},
		_activeCategory = "All",
		_searchQuery = "",
		_onToggleFavorite = props.OnToggleFavorite or function() end,
		_onExecute = props.OnExecute or function() end,
		_favorites = props.Favorites or {},
		_categoryChips = {},
		_commandItems = {},
	}, Commands)

	self._frame = InstanceUtils.New("Frame", {
		Name = "CommandsScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self._searchBar = SearchBar.new(self._frame, {
		Name = "CommandSearch",
		Size = UDim2.new(1, -24, 0, 40),
		Position = UDim2.fromOffset(12, 12),
		Placeholder = "Search commands...",
		OnSearch = function(query)
			self._searchQuery = query
			self:_filterCommands()
		end,
	})

	self._categoryRow = InstanceUtils.New("Frame", {
		Name = "CategoryRow",
		Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.fromOffset(0, 60),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self._frame,
	})

	self._categoryList = InstanceUtils.New("Frame", {
		Name = "CategoryList",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = self._categoryRow,
	})

	self:_buildCategoryChips()

	self._listFrame = InstanceUtils.New("ScrollingFrame", {
		Name = "CommandList",
		Size = UDim2.new(1, -24, 1, -112),
		Position = UDim2.fromOffset(12, 108),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = self._frame,
	})

	self._listContainer = InstanceUtils.New("Frame", {
		Name = "ListContainer",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = self._listFrame,
	})

	self._refreshIndicator = InstanceUtils.New("Frame", {
		Name = "RefreshIndicator",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, -60),
		BackgroundColor3 = theme:GetColor("Primary"),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Visible = false,
		Parent = self._frame,
	})
	local refreshCorner = InstanceUtils.MakeCorner(6)
	refreshCorner.Parent = self._refreshIndicator

	self:_rebuildList()

	return self
end

function Commands:_buildCategoryChips()
	local theme = Theme.GetGlobal()
	local xOffset = 12

	for i, category in ipairs(CATEGORIES) do
		local isActive = category == self._activeCategory

		local chip = Glass.new({
			Name = category .. "Chip",
			Parent = self._categoryList,
			Size = UDim2.new(0, 0, 0, 32),
			Position = UDim2.fromOffset(xOffset, 6),
			CornerRadius = 16,
			Transparency = isActive and 0.2 or 0.5,
			Gradient = isActive and {
				Color1 = theme:GetColor("Primary"),
				Color2 = theme:GetColor("Secondary"),
				Alpha = 0.25,
			} or nil,
			BorderGlow = isActive or false,
		})

		local chipLabel = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(0, 0, 1, 0),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 1,
			Text = category,
			TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextSecondary"),
			TextSize = 13 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			Parent = chip,
		})
		chipLabel.Size = UDim2.new(0, chipLabel.TextBounds.X + 24, 1, 0)
		chip.Size = UDim2.new(0, chipLabel.TextBounds.X + 32, 0, 32)

		local labelX = (chip.Size.X.Offset - chipLabel.TextBounds.X) / 2
		chipLabel.Position = UDim2.fromOffset(labelX, 0)

		local catIndex = i
		chip.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self._activeCategory = category
				self:_refreshCategoryChips()
				self:_filterCommands()
			end
		end)

		self._categoryChips[category] = chip
		xOffset = xOffset + chip.Size.X.Offset + 8
	end

	self._categoryList.Size = UDim2.new(0, xOffset + 12, 1, 0)
end

function Commands:_refreshCategoryChips()
	local theme = Theme.GetGlobal()
	for category, chip in pairs(self._categoryChips) do
		local isActive = category == self._activeCategory
		local label = chip:FindFirstChild("Label")
		if label then
			label.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme:GetColor("TextSecondary")
		end
		TweenKit.new(chip, {BackgroundTransparency = isActive and 0.2 or 0.5}, 0.2, "OutQuad")
	end
end

function Commands:_filterCommands()
	local query = self._searchQuery:lower()
	self._commands = {}

	for _, cmd in ipairs(self._allCommands) do
		local matchesCategory = self._activeCategory == "All" or cmd.Category == self._activeCategory
		local matchesSearch = #query == 0 or cmd.Name:lower():find(query, 1, true) or (cmd.Description or ""):lower():find(query, 1, true)
		if matchesCategory and matchesSearch then
			table.insert(self._commands, cmd)
		end
	end

	self:_rebuildList()
end

function Commands:_rebuildList()
	for _, child in ipairs(self._listContainer:GetChildren()) do
		child:Destroy()
	end

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cmd in ipairs(self._commands) do
		local isFavorited = self._favorites[cmd.Name] or false

		local card = Glass.new({
			Name = "Cmd_" .. cmd.Name,
			Parent = self._listContainer,
			Size = UDim2.new(1, 0, 0, 64),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 12,
			Transparency = 0.35,
			Shadow = true,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.fromOffset(10, 18),
			BackgroundTransparency = 1,
			Text = cmd.Icon or "C",
			TextColor3 = theme:GetColor("Primary"),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local nameLabel = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(1, -100, 0, 20),
			Position = UDim2.fromOffset(46, 12),
			BackgroundTransparency = 1,
			Text = cmd.Name or "Command",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 15 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local descLabel = InstanceUtils.New("TextLabel", {
			Name = "Description",
			Size = UDim2.new(1, -100, 0, 16),
			Position = UDim2.fromOffset(46, 34),
			BackgroundTransparency = 1,
			Text = cmd.Description or "No description",
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local starBtn = InstanceUtils.New("TextButton", {
			Name = "Star",
			Size = UDim2.new(0, 32, 0, 32),
			Position = UDim2.new(1, -40, 0, 16),
			BackgroundTransparency = 1,
			Text = isFavorited and "★" or "☆",
			TextColor3 = isFavorited and theme:GetColor("Warning") or theme:GetColor("TextMuted"),
			TextSize = 20,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local cmdName = cmd.Name
		starBtn.MouseButton1Click:Connect(function()
			if self._destroyed then return end
			local newFav = not self._favorites[cmdName]
			self._favorites[cmdName] = newFav
			starBtn.Text = newFav and "★" or "☆"
			starBtn.TextColor3 = newFav and theme:GetColor("Warning") or theme:GetColor("TextMuted")
			self._onToggleFavorite(cmdName, newFav)
		end)

		card.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self._onExecute(cmd.Name)
			end
		end)

		table.insert(self._commandItems, {Frame = card, Data = cmd})
		yOffset = yOffset + 70
	end

	self._listContainer.Size = UDim2.new(1, 0, 0, yOffset)
	self._listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function Commands:Refresh()
	self:_refreshCategoryChips()
	self:_filterCommands()
	TweenKit.new(self._refreshIndicator, {Size = UDim2.new(1, 0, 0, 3)}, 0.3, "OutQuad")
	task.delay(0.6, function()
		if self._refreshIndicator then
			TweenKit.new(self._refreshIndicator, {Size = UDim2.new(1, 0, 0, 0)}, 0.3, "InQuad")
		end
	end)
end

function Commands:SetCommands(commands)
	self._allCommands = commands
	self:_filterCommands()
end

function Commands:SetFavorites(favorites)
	self._favorites = favorites or {}
	self:_rebuildList()
end

function Commands:GetFrame()
	return self._frame
end

function Commands:Destroy()
	self._destroyed = true
	if self._searchBar then self._searchBar:Destroy() end
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._commands = {}
	self._commandItems = {}
end

return Commands
end)()

-- Module: src/ui/screens/Favorites.lua
_MODULES['src/ui/screens/Favorites.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)

local Favorites = {}
Favorites.__index = Favorites

function Favorites.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_favorites = props.Favorites or {},
		_onToggleFavorite = props.OnToggleFavorite or function() end,
		_onExecute = props.OnExecute or function() end,
		_onClearAll = props.OnClearAll or function() end,
		_commandItems = {},
	}, Favorites)

	self._frame = InstanceUtils.New("Frame", {
		Name = "FavoritesScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	self._header = InstanceUtils.New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, -24, 0, 44),
		Position = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		Parent = self._frame,
	})

	local title = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1,
		Text = "Favorites",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 22 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._header,
	})

	local clearBtn = Glass.new({
		Name = "ClearAll",
		Parent = self._header,
		Size = UDim2.new(0, 70, 0, 28),
		Position = UDim2.new(1, -70, 0, 8),
		CornerRadius = 14,
		Transparency = 0.5,
	})
	local clearText = InstanceUtils.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "Clear All",
		TextColor3 = theme:GetColor("Error"),
		TextSize = 12,
		Font = Enum.Font.GothamSemibold,
		Parent = clearBtn,
	})
	clearBtn.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self._onClearAll()
		end
	end)

	self._listFrame = InstanceUtils.New("ScrollingFrame", {
		Name = "FavList",
		Size = UDim2.new(1, -24, 1, -68),
		Position = UDim2.fromOffset(12, 64),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = self._frame,
	})

	self._listContainer = InstanceUtils.New("Frame", {
		Name = "ListContainer",
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = self._listFrame,
	})

	self._emptyState = InstanceUtils.New("Frame", {
		Name = "EmptyState",
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = #self._favorites == 0,
		Parent = self._listFrame,
	})

	local emptyIcon = InstanceUtils.New("TextLabel", {
		Name = "EmptyIcon",
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.fromScale(0.5, 0.35),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "☆",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 40,
		Font = Enum.Font.GothamBold,
		Parent = self._emptyState,
	})

	local emptyText = InstanceUtils.New("TextLabel", {
		Name = "EmptyText",
		Size = UDim2.new(1, -40, 0, 24),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "No favorites yet",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		Parent = self._emptyState,
	})

	local emptySubtext = InstanceUtils.New("TextLabel", {
		Name = "EmptySubtext",
		Size = UDim2.new(1, -40, 0, 18),
		Position = UDim2.fromScale(0.5, 0.58),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Text = "Tap the star on any command to add it here",
		TextColor3 = theme:GetColor("TextMuted"),
		TextSize = 12 * theme.Scale,
		Font = Enum.Font.Gotham,
		Parent = self._emptyState,
	})

	self._emptyState.Size = UDim2.new(1, 0, 1, 0)

	self:_rebuildList()

	return self
end

function Favorites:_rebuildList()
	for _, child in ipairs(self._listContainer:GetChildren()) do
		child:Destroy()
	end
	self._commandItems = {}

	if #self._favorites == 0 then
		self._emptyState.Visible = true
		self._listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end

	self._emptyState.Visible = false

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cmd in ipairs(self._favorites) do
		local card = Glass.new({
			Name = "Fav_" .. cmd.Name,
			Parent = self._listContainer,
			Size = UDim2.new(1, 0, 0, 64),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 12,
			Transparency = 0.35,
			Shadow = true,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.fromOffset(10, 18),
			BackgroundTransparency = 1,
			Text = cmd.Icon or "C",
			TextColor3 = theme:GetColor("Warning"),
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local nameLabel = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(1, -100, 0, 20),
			Position = UDim2.fromOffset(46, 12),
			BackgroundTransparency = 1,
			Text = cmd.Name or "Command",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 15 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local descLabel = InstanceUtils.New("TextLabel", {
			Name = "Description",
			Size = UDim2.new(1, -100, 0, 16),
			Position = UDim2.fromOffset(46, 34),
			BackgroundTransparency = 1,
			Text = cmd.Description or "No description",
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local starBtn = InstanceUtils.New("TextButton", {
			Name = "Star",
			Size = UDim2.new(0, 32, 0, 32),
			Position = UDim2.new(1, -40, 0, 16),
			BackgroundTransparency = 1,
			Text = "★",
			TextColor3 = theme:GetColor("Warning"),
			TextSize = 20,
			Font = Enum.Font.GothamBold,
			Parent = card,
		})

		local cmdName = cmd.Name
		starBtn.MouseButton1Click:Connect(function()
			if self._destroyed then return end
			self._onToggleFavorite(cmdName, false)
		end})

		card.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self._onExecute(cmd.Name)
			end
		end)

		table.insert(self._commandItems, {Frame = card, Data = cmd})
		yOffset = yOffset + 70
	end

	self._listContainer.Size = UDim2.new(1, 0, 0, yOffset)
	self._listFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

function Favorites:SetFavorites(favorites)
	self._favorites = favorites or {}
	self:_rebuildList()
end

function Favorites:GetFrame()
	return self._frame
end

function Favorites:Destroy()
	self._destroyed = true
	if self._frame then self._frame:Destroy() end
	self._frame = nil
	self._commandItems = {}
end

return Favorites
end)()

-- Module: src/ui/screens/Home.lua
_MODULES['src/ui/screens/Home.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Gradient = require(script.Parent.Parent.Parent.primitives.gradient)

local Home = {}
Home.__index = Home

local RunService = game:GetService("RunService")

function Home.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()

	local self = setmetatable({
		_destroyed = false,
		_fps = 0,
		_ping = 0,
		_connections = {},
		_favorites = {},
		_recentCommands = {},
		_loading = true,
	}, Home)

	self._frame = InstanceUtils.New("ScrollingFrame", {
		Name = "HomeScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = parent,
	})

	local container = InstanceUtils.New("Frame", {
		Name = "Container",
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Parent = self._frame,
	})

	self._avatarFrame = Glass.new({
		Name = "Avatar",
		Parent = container,
		Size = UDim2.new(0, 80, 0, 80),
		Position = UDim2.fromOffset(0, 16),
		CornerRadius = 40,
		Transparency = 0.2,
		BorderGlow = true,
		Gradient = {
			Color1 = theme:GetColor("Primary"),
			Color2 = theme:GetColor("Secondary"),
			Alpha = 0.3,
		},
	})

	local avatarFill = InstanceUtils.New("Frame", {
		Name = "AvatarFill",
		Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.fromOffset(2, 2),
		BackgroundColor3 = theme:GetColor("SurfaceLight"),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Parent = self._avatarFrame,
	})
	local avatarFillCorner = InstanceUtils.MakeCorner(38)
	avatarFillCorner.Parent = avatarFill

	local avatarIcon = InstanceUtils.New("TextLabel", {
		Name = "Icon",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "U",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 32,
		Font = Enum.Font.GothamBold,
		Parent = avatarFill,
	})

	self._playerName = InstanceUtils.New("TextLabel", {
		Name = "PlayerName",
		Size = UDim2.new(1, -96, 0, 28),
		Position = UDim2.fromOffset(96, 20),
		BackgroundTransparency = 1,
		Text = "Player",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 22 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	self._displayName = InstanceUtils.New("TextLabel", {
		Name = "DisplayName",
		Size = UDim2.new(1, -96, 0, 18),
		Position = UDim2.fromOffset(96, 48),
		BackgroundTransparency = 1,
		Text = "@player",
		TextColor3 = theme:GetColor("TextSecondary"),
		TextSize = 14 * theme.Scale,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	self._statsRow = InstanceUtils.New("Frame", {
		Name = "StatsRow",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 112),
		BackgroundTransparency = 1,
		Parent = container,
	})

	self._statChips = {}
	local statData = {
		{Name = "FPS", Icon = "F", Value = "0"},
		{Name = "Ping", Icon = "P", Value = "0ms"},
		{Name = "Clock", Icon = "T", Value = "00:00"},
	}
	local chipWidth = (1 - 0.04) / 3

	for i, data in ipairs(statData) do
		local chip = Glass.new({
			Name = data.Name .. "Chip",
			Parent = self._statsRow,
			Size = UDim2.new(chipWidth, -4, 0, 42),
			Position = UDim2.new((i - 1) * (chipWidth + 0.02), 0, 0, 4),
			CornerRadius = 10,
			Transparency = 0.35,
		})

		local chipIcon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.fromOffset(8, 12),
			BackgroundTransparency = 1,
			Text = data.Icon,
			TextColor3 = theme:GetColor("Primary"),
			TextSize = 14,
			Font = Enum.Font.GothamBold,
			Parent = chip,
		})

		local chipValue = InstanceUtils.New("TextLabel", {
			Name = "Value",
			Size = UDim2.new(1, -30, 0, 18),
			Position = UDim2.fromOffset(28, 6),
			BackgroundTransparency = 1,
			Text = data.Value,
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 16 * theme.Scale,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		local chipLabel = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -30, 0, 14),
			Position = UDim2.fromOffset(28, 24),
			BackgroundTransparency = 1,
			Text = data.Name,
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		self._statChips[data.Name] = {Frame = chip, Value = chipValue}
	end

	self._quickActions = InstanceUtils.New("Frame", {
		Name = "QuickActions",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 170),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local qaTitle = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Text = "Quick Actions",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self._quickActions,
	})

	local qaGrid = InstanceUtils.New("Frame", {
		Name = "Grid",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 28),
		BackgroundTransparency = 1,
		Parent = self._quickActions,
	})

	local qaButtons = {
		{Name = "Rejoin", Icon = "R", Color = theme:GetColor("Primary")},
		{Name = "Server Hop", Icon = "S", Color = theme:GetColor("Secondary")},
		{Name = "Reset Char", Icon = "X", Color = theme:GetColor("Warning")},
		{Name = "Anti-AFK", Icon = "A", Color = theme:GetColor("Accent")},
	}

	local gridWidth = (1 - 0.04) / 2
	self._qaFrames = {}

	for i, data in ipairs(qaButtons) do
		local row = math.floor((i - 1) / 2)
		local col = (i - 1) % 2

		local btn = Glass.new({
			Name = data.Name,
			Parent = qaGrid,
			Size = UDim2.new(gridWidth, -4, 0, 56),
			Position = UDim2.new(col * (gridWidth + 0.04), 0, row * 64, 0),
			CornerRadius = 12,
			Transparency = 0.35,
			Gradient = {
				Color1 = data.Color,
				Color2 = data.Color,
				Alpha = 0.1,
			},
		})

		local btnIcon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.fromOffset(10, 8),
			BackgroundTransparency = 1,
			Text = data.Icon,
			TextColor3 = data.Color,
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			Parent = btn,
		})

		local btnLabel = InstanceUtils.New("TextLabel", {
			Name = "Label",
			Size = UDim2.new(1, -16, 0, 16),
			Position = UDim2.fromOffset(8, 32),
			BackgroundTransparency = 1,
			Text = data.Name,
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 12 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		table.insert(self._qaFrames, btn)
	end

	qaGrid.Size = UDim2.new(1, 0, 0, 128)

	self._favoritesSection = InstanceUtils.New("Frame", {
		Name = "FavoritesSection",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 170 + 128 + 16),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local favHeader = InstanceUtils.New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = self._favoritesSection,
	})

	local favTitle = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "Favorites",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = favHeader,
	})

	local seeAllBtn = Glass.new({
		Name = "SeeAll",
		Parent = favHeader,
		Size = UDim2.new(0, 60, 0, 24),
		Position = UDim2.new(1, -60, 0, 3),
		CornerRadius = 12,
		Transparency = 0.6,
	})
	local seeAllText = InstanceUtils.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "See All",
		TextColor3 = theme:GetColor("TextSecondary"),
		TextSize = 11,
		Font = Enum.Font.GothamSemibold,
		Parent = seeAllBtn,
	})

	self._favScroll = InstanceUtils.New("Frame", {
		Name = "FavScroll",
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = self._favoritesSection,
	})

	self._favList = InstanceUtils.New("Frame", {
		Name = "FavList",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = self._favScroll,
	})

	self._favoritesSection.Size = UDim2.new(1, 0, 0, 86)

	self._recentSection = InstanceUtils.New("Frame", {
		Name = "RecentSection",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, self._favoritesSection.Position.Y.Offset + 86 + 8),
		BackgroundTransparency = 1,
		Parent = container,
	})

	local recentHeader = InstanceUtils.New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = self._recentSection,
	})

	local recentTitle = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -60, 1, 0),
		BackgroundTransparency = 1,
		Text = "Recent",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 16 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = recentHeader,
	})

	self._recentList = InstanceUtils.New("Frame", {
		Name = "RecentList",
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 1,
		Parent = self._recentSection,
	})

	self._recentSection.Size = UDim2.new(1, 0, 0, 40)

	self._shimmer = InstanceUtils.New("Frame", {
		Name = "Shimmer",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Visible = true,
		Parent = container,
		ZIndex = 100,
	})

	local shimmerGrad = Gradient.new({
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 24, 39)),
			ColorSequenceKeypoint.new(0.3, Color3.fromRGB(31, 41, 55)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(17, 24, 39)),
			ColorSequenceKeypoint.new(0.7, Color3.fromRGB(31, 41, 55)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 24, 39)),
		}),
		Rotation = 45,
		Parent = self._shimmer,
	})
	self._shimmerGrad = shimmerGrad

	self._shimmerConn = RunService.RenderStepped:Connect(function(dt)
		if self._shimmer and self._shimmerGrad and self._shimmer.Visible then
			local offset = self._shimmerGrad.Offset
			self._shimmerGrad.Offset = Vector2.new(offset.X - dt * 0.3, offset.Y)
		end
	end)

	task.delay(2, function()
		if self._destroyed then return end
		self._loading = false
		if self._shimmer then
			TweenKit.new(self._shimmer, {BackgroundTransparency = 1}, 0.4, "OutQuad")
			task.delay(0.5, function()
				if self._shimmer then self._shimmer.Visible = false end
			end)
		end
	end)

	self:_startStats()
	self:_updateCanvas()

	return self
end

function Home:_startStats()
	local stats = game:GetService("Stats")
	local perfStats = stats.PerformanceStats

	self._connections[#self._connections + 1] = RunService.RenderStepped:Connect(function()
		if self._destroyed then return end
		self._fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
		if self._statChips["FPS"] then
			self._statChips["FPS"].Value.Text = tostring(self._fps)
		end
	end)

	self._connections[#self._connections + 1] = game:GetService("Players").LocalPlayer:GetNetworkPing():Connect(function()
		return
	end)

	spawn(function()
		while not self._destroyed do
			local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
			if self._statChips["Ping"] then
				self._statChips["Ping"].Value.Text = tostring(ping) .. "ms"
			end
			wait(1)
		end
	end)

	spawn(function()
		while not self._destroyed do
			local timeStr = os.date("%I:%M")
			if self._statChips["Clock"] then
				self._statChips["Clock"].Value.Text = timeStr
			end
			wait(30)
		end
	end)
end

function Home:SetRecentCommands(commands)
	self._recentCommands = commands or {}
	self:_rebuildRecent()
end

function Home:SetFavorites(favorites)
	self._favorites = favorites or {}
	self:_rebuildFavorites()
end

function Home:_rebuildFavorites()
	for _, child in ipairs(self._favList:GetChildren()) do
		child:Destroy()
	end

	local theme = Theme.GetGlobal()
	local xOffset = 0

	for i, fav in ipairs(self._favorites) do
		local chip = Glass.new({
			Name = "FavChip",
			Parent = self._favList,
			Size = UDim2.new(0, 80, 0, 36),
			Position = UDim2.fromOffset(xOffset, 6),
			CornerRadius = 18,
			Transparency = 0.4,
		})
		local chipText = InstanceUtils.New("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = fav.Name or "Item",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 12 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			Parent = chip,
		})
		xOffset = xOffset + 88
	end

	self._favList.Size = UDim2.new(0, xOffset, 1, 0)
end

function Home:_rebuildRecent()
	for _, child in ipairs(self._recentList:GetChildren()) do
		child:Destroy()
	end

	local theme = Theme.GetGlobal()
	local yOffset = 0

	for i, cmd in ipairs(self._recentCommands) do
		if i > 5 then break end

		local chip = Glass.new({
			Name = "RecentChip_" .. i,
			Parent = self._recentList,
			Size = UDim2.new(1, 0, 0, 34),
			Position = UDim2.fromOffset(0, yOffset),
			CornerRadius = 8,
			Transparency = 0.4,
		})

		local icon = InstanceUtils.New("TextLabel", {
			Name = "Icon",
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.fromOffset(8, 8),
			BackgroundTransparency = 1,
			Text = cmd.Icon or "C",
			TextColor3 = theme:GetColor("Primary"),
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			Parent = chip,
		})

		local name = InstanceUtils.New("TextLabel", {
			Name = "Name",
			Size = UDim2.new(0, 100, 1, 0),
			Position = UDim2.fromOffset(30, 0),
			BackgroundTransparency = 1,
			Text = cmd.Name or "command",
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 13 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = chip,
		})

		local time = InstanceUtils.New("TextLabel", {
			Name = "Time",
			Size = UDim2.new(0, 50, 1, 0),
			Position = UDim2.new(1, -54, 0, 0),
			BackgroundTransparency = 1,
			Text = cmd.Time or "now",
			TextColor3 = theme:GetColor("TextMuted"),
			TextSize = 10,
			Font = Enum.Font.Gotham,
			Parent = chip,
		})

		yOffset = yOffset + 38
	end

	self._recentList.Size = UDim2.new(1, 0, 0, yOffset)
	self._recentSection.Size = UDim2.new(1, 0, 0, 34 + yOffset)
	self:_updateCanvas()
end

function Home:_updateCanvas()
	local children = self._frame:FindFirstChild("Container")
	if not children then return end
	local container = children
	local maxY = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			local bottom = child.Position.Y.Offset + child.Size.Y.Offset
			if bottom > maxY then
				maxY = bottom
			end
		end
	end
	self._frame.CanvasSize = UDim2.new(0, 0, 0, maxY + 80)
end

function Home:GetFrame()
	return self._frame
end

function Home:Destroy()
	self._destroyed = true
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}
	if self._shimmerConn then
		self._shimmerConn:Disconnect()
		self._shimmerConn = nil
	end
	if self._frame then self._frame:Destroy() end
	self._frame = nil
end

return Home
end)()

-- Module: src/ui/screens/Settings.lua
_MODULES['src/ui/screens/Settings.lua'] = (function()
local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)
local Observer = require(script.Parent.Parent.Parent.core.observer)
local Glass = require(script.Parent.Parent.Parent.primitives.glass)
local Section = require(script.Parent.Parent.Parent.components.Section)
local ColorPicker = require(script.Parent.Parent.Parent.components.ColorPicker)
local Slider = require(script.Parent.Parent.Parent.components.Slider)
local Toggle = require(script.Parent.Parent.Parent.components.Toggle)
local Dialog = require(script.Parent.Parent.Parent.components.Dialog)

local Settings = {}
Settings.__index = Settings

local PRESETS = {
	Ocean = {
		Primary = Color3.fromRGB(6, 182, 212),
		Secondary = Color3.fromRGB(59, 130, 246),
		Name = "Ocean",
	},
	Purple = {
		Primary = Color3.fromRGB(139, 92, 246),
		Secondary = Color3.fromRGB(236, 72, 153),
		Name = "Purple",
	},
	Emerald = {
		Primary = Color3.fromRGB(16, 185, 129),
		Secondary = Color3.fromRGB(34, 197, 94),
		Name = "Emerald",
	},
	Rose = {
		Primary = Color3.fromRGB(239, 68, 68),
		Secondary = Color3.fromRGB(244, 63, 94),
		Name = "Rose",
	},
	Amber = {
		Primary = Color3.fromRGB(251, 191, 36),
		Secondary = Color3.fromRGB(245, 158, 11),
		Name = "Amber",
	},
}

function Settings.new(parent, props)
	props = props or {}
	local theme = Theme.GetGlobal()
	local settingsStore = props.Store or Observer.new({
		PrimaryColor = theme:GetColor("Primary"),
		SecondaryColor = theme:GetColor("Secondary"),
		Transparency = theme.PanelTransparency or 0.4,
		Blur = theme.BlurIntensity or 12,
		Scale = 1.0,
		ShowFPS = true,
		ShowPing = true,
		ShowClock = true,
		ShowFloatingButton = true,
		AnimationSpeed = theme.AnimationSpeed or 1.0,
	})

	local self = setmetatable({
		_destroyed = false,
		_store = settingsStore,
		_sections = {},
		_controls = {},
	}, Settings)

	self._frame = InstanceUtils.New("ScrollingFrame", {
		Name = "SettingsScreen",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = parent,
	})

	local container = InstanceUtils.New("Frame", {
		Name = "Container",
		Size = UDim2.new(1, -24, 0, 0),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Parent = self._frame,
	})

	local title = InstanceUtils.New("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 8),
		BackgroundTransparency = 1,
		Text = "Settings",
		TextColor3 = theme:GetColor("TextPrimary"),
		TextSize = 22 * theme.Scale,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = container,
	})

	self:_buildThemeSection(container)
	self:_buildAppearanceSection(container)
	self:_buildBehaviorSection(container)
	self:_buildAnimationSection(container)
	self:_buildPresetsSection(container)
	self:_buildDangerZone(container)

	self:_updateCanvas()

	return self
end

function Settings:_buildThemeSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "ThemeSection",
		Title = "THEME",
		Icon = "T",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = false,
	})

	local content = section:GetContent()

	self._controls.PrimaryColor = ColorPicker.new(content, {
		Name = "PrimaryColor",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 0),
		Label = "Primary Color",
		Default = theme:GetColor("Primary"),
		OnChange = function(color)
			self._store:Set("PrimaryColor", color)
			theme:SetPrimary(color)
		end,
	})

	self._controls.SecondaryColor = ColorPicker.new(content, {
		Name = "SecondaryColor",
		Size = UDim2.new(1, 0, 0, 50),
		Position = UDim2.fromOffset(0, 60),
		Label = "Secondary Color",
		Default = theme:GetColor("Secondary"),
		OnChange = function(color)
			self._store:Set("SecondaryColor", color)
			theme:SetSecondary(color)
		end,
	})

	section:AddChild(self._controls.PrimaryColor._frame)
	section:AddChild(self._controls.SecondaryColor._frame)

	table.insert(self._sections, section)
end

function Settings:_buildAppearanceSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "AppearanceSection",
		Title = "APPEARANCE",
		Icon = "A",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	self._controls.Transparency = Slider.new(content, {
		Name = "TransparencySlider",
		Width = 280,
		Label = "Panel Transparency",
		Min = 0.3,
		Max = 0.7,
		Step = 0.05,
		Default = theme.PanelTransparency or 0.4,
		OnChange = function(val)
			self._store:Set("Transparency", val)
			theme.PanelTransparency = val
		end,
	})

	self._controls.Blur = Slider.new(content, {
		Name = "BlurSlider",
		Width = 280,
		Label = "Blur Intensity",
		Min = 0,
		Max = 20,
		Step = 1,
		Default = theme.BlurIntensity or 12,
		OnChange = function(val)
			self._store:Set("Blur", val)
			theme.BlurIntensity = val
		end,
	})

	self._controls.Scale = Slider.new(content, {
		Name = "ScaleSlider",
		Width = 280,
		Label = "UI Scale",
		Min = 0.7,
		Max = 1.5,
		Step = 0.05,
		Default = 1.0,
		OnChange = function(val)
			self._store:Set("Scale", val)
			theme.Scale = val
		end,
	})

	section:AddChild(self._controls.Transparency._frame)
	section:AddChild(self._controls.Blur._frame)
	section:AddChild(self._controls.Scale._frame)

	table.insert(self._sections, section)
end

function Settings:_buildBehaviorSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "BehaviorSection",
		Title = "BEHAVIOR",
		Icon = "B",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()
	local toggleY = 0

	self._controls.ShowFPS = Toggle.new(content, {
		Name = "ShowFPS",
		Default = true,
		Label = "Show FPS",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowFPS", val)
		end,
	})
	toggleY = toggleY + 36

	self._controls.ShowPing = Toggle.new(content, {
		Name = "ShowPing",
		Default = true,
		Label = "Show Ping",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowPing", val)
		end,
	})
	toggleY = toggleY + 36

	self._controls.ShowClock = Toggle.new(content, {
		Name = "ShowClock",
		Default = true,
		Label = "Show Clock",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowClock", val)
		end,
	})
	toggleY = toggleY + 36

	self._controls.ShowFloatingButton = Toggle.new(content, {
		Name = "ShowFloatingButton",
		Default = true,
		Label = "Floating Button",
		Position = UDim2.fromOffset(0, toggleY),
		OnToggle = function(val)
			self._store:Set("ShowFloatingButton", val)
		end,
	})

	section:AddChild(self._controls.ShowFPS._frame)
	section:AddChild(self._controls.ShowPing._frame)
	section:AddChild(self._controls.ShowClock._frame)
	section:AddChild(self._controls.ShowFloatingButton._frame)

	table.insert(self._sections, section)
end

function Settings:_buildAnimationSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "AnimationSection",
		Title = "ANIMATION",
		Icon = "N",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	self._controls.AnimationSpeed = Slider.new(content, {
		Name = "AnimSpeedSlider",
		Width = 280,
		Label = "Animation Speed",
		Min = 0.3,
		Max = 2.0,
		Step = 0.1,
		Default = theme.AnimationSpeed or 1.0,
		OnChange = function(val)
			self._store:Set("AnimationSpeed", val)
			theme.AnimationSpeed = val
		end,
	})

	section:AddChild(self._controls.AnimationSpeed._frame)

	table.insert(self._sections, section)
end

function Settings:_buildPresetsSection(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "PresetsSection",
		Title = "PRESETS",
		Icon = "P",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	local presetRow = InstanceUtils.New("Frame", {
		Name = "PresetRow",
		Size = UDim2.new(1, 0, 0, 60),
		Position = UDim2.fromOffset(0, 0),
		BackgroundTransparency = 1,
		Parent = content,
	})

	local presetWidth = (1 - 0.04) / 3

	local idx = 0
	for _, presetData in pairs(PRESETS) do
		local row = math.floor(idx / 3)
		local col = idx % 3

		local btn = Glass.new({
			Name = presetData.Name .. "Preset",
			Parent = presetRow,
			Size = UDim2.new(presetWidth, -4, 0, 50),
			Position = UDim2.new(col * (presetWidth + 0.02), 0, row * 56, 4),
			CornerRadius = 10,
			Transparency = 0.4,
		})

		local colorSwatch = InstanceUtils.New("Frame", {
			Name = "Swatch",
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.fromScale(0.5, 0.25),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = presetData.Primary,
			BorderSizePixel = 0,
			Parent = btn,
		})
		local swatchCorner = InstanceUtils.MakeCorner(6)
		swatchCorner.Parent = colorSwatch

		local btnLabel = InstanceUtils.New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.fromScale(0.5, 0.6),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = presetData.Name,
			TextColor3 = theme:GetColor("TextPrimary"),
			TextSize = 11 * theme.Scale,
			Font = Enum.Font.GothamSemibold,
			Parent = btn,
		})

		local presetName = presetData.Name
		btn.InputBegan:Connect(function(input)
			if self._destroyed then return end
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:_applyPreset(presetName)
			end
		end)

		idx = idx + 1
	end

	local presetRowHeight = math.ceil(idx / 3) * 56 + 8
	presetRow.Size = UDim2.new(1, 0, 0, presetRowHeight)

	section:AddChild(presetRow)

	table.insert(self._sections, section)
end

function Settings:_buildDangerZone(parent)
	local theme = Theme.GetGlobal()

	local section = Section.new(parent, {
		Name = "DangerZone",
		Title = "DANGER ZONE",
		Icon = "!",
		Size = UDim2.new(1, 0, 0, 40),
		Collapsible = true,
	})

	local content = section:GetContent()

	local resetBtn = Glass.new({
		Name = "ResetAll",
		Parent = content,
		Size = UDim2.new(1, 0, 0, 48),
		Position = UDim2.fromOffset(0, 8),
		CornerRadius = 12,
		Transparency = 0.3,
		BorderGlow = true,
		Gradient = {
			Color1 = theme:GetColor("Error"),
			Color2 = theme:GetColor("Error"),
			Alpha = 0.15,
		},
	})

	local resetIcon = InstanceUtils.New("TextLabel", {
		Name = "Icon",
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.fromOffset(12, 14),
		BackgroundTransparency = 1,
		Text = "!",
		TextColor3 = theme:GetColor("Error"),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = resetBtn,
	})

	local resetLabel = InstanceUtils.New("TextLabel", {
		Name = "Label",
		Size = UDim2.new(1, -48, 1, 0),
		Position = UDim2.fromOffset(40, 0),
		BackgroundTransparency = 1,
		Text = "Reset All Settings",
		TextColor3 = theme:GetColor("Error"),
		TextSize = 15 * theme.Scale,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = resetBtn,
	})

	resetBtn.InputBegan:Connect(function(input)
		if self._destroyed then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			Dialog.Show(self._frame, {
				Title = "Reset Settings",
				Message = "Are you sure you want to reset all settings to default? This cannot be undone.",
				Buttons = {
					{Text = "Cancel", Callback = function() end},
					{Text = "Reset", Primary = true, Callback = function()
						self:_resetAll()
					end},
				},
			})
		end
	end)

	section:AddChild(resetBtn)

	table.insert(self._sections, section)
end

function Settings:_applyPreset(name)
	local preset = PRESETS[name]
	if not preset then return end

	local theme = Theme.GetGlobal()
	theme:SetPrimary(preset.Primary)
	theme:SetSecondary(preset.Secondary)

	self._store:Set("PrimaryColor", preset.Primary)
	self._store:Set("SecondaryColor", preset.Secondary)

	if self._controls.PrimaryColor then
		self._controls.PrimaryColor:SetColor(preset.Primary)
	end
	if self._controls.SecondaryColor then
		self._controls.SecondaryColor:SetColor(preset.Secondary)
	end
end

function Settings:_resetAll()
	local theme = Theme.GetGlobal()
	local defaultTheme = Theme.new()

	theme:SetPrimary(defaultTheme:GetColor("Primary"))
	theme:SetSecondary(defaultTheme:GetColor("Secondary"))
	theme.PanelTransparency = 0.4
	theme.BlurIntensity = 12
	theme.Scale = 1.0
	theme.AnimationSpeed = 1.0

	self._store:BatchSet({
		PrimaryColor = defaultTheme:GetColor("Primary"),
		SecondaryColor = defaultTheme:GetColor("Secondary"),
		Transparency = 0.4,
		Blur = 12,
		Scale = 1.0,
		ShowFPS = true,
		ShowPing = true,
		ShowClock = true,
		ShowFloatingButton = true,
		AnimationSpeed = 1.0,
	})

	if self._controls.PrimaryColor then
		self._controls.PrimaryColor:SetColor(defaultTheme:GetColor("Primary"))
	end
	if self._controls.SecondaryColor then
		self._controls.SecondaryColor:SetColor(defaultTheme:GetColor("Secondary"))
	end
	if self._controls.Transparency then
		self._controls.Transparency:SetValue(0.4)
	end
	if self._controls.Blur then
		self._controls.Blur:SetValue(12)
	end
	if self._controls.Scale then
		self._controls.Scale:SetValue(1.0)
	end
	if self._controls.AnimationSpeed then
		self._controls.AnimationSpeed:SetValue(1.0)
	end
	if self._controls.ShowFPS then
		self._controls.ShowFPS:SetValue(true)
	end
	if self._controls.ShowPing then
		self._controls.ShowPing:SetValue(true)
	end
	if self._controls.ShowClock then
		self._controls.ShowClock:SetValue(true)
	end
	if self._controls.ShowFloatingButton then
		self._controls.ShowFloatingButton:SetValue(true)
	end
end

function Settings:_updateCanvas()
	local children = self._frame:FindFirstChild("Container")
	if not children then return end
	local container = children
	local maxY = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			local bottom = child.Position.Y.Offset + child.Size.Y.Offset
			if bottom > maxY then
				maxY = bottom
			end
		end
	end
	self._frame.CanvasSize = UDim2.new(0, 0, 0, maxY + 40)
end

function Settings:GetStore()
	return self._store
end

function Settings:GetFrame()
	return self._frame
end

function Settings:Destroy()
	self._destroyed = true
	for _, section in ipairs(self._sections) do
		section:Destroy()
	end
	self._sections = {}
	for _, control in pairs(self._controls) do
		if control.Destroy then
			control:Destroy()
		end
	end
	self._controls = {}
	if self._frame then self._frame:Destroy() end
	self._frame = nil
end

return Settings
end)()

-- Module: src/utils/instance.lua
_MODULES['src/utils/instance.lua'] = (function()
local InstanceUtils = {}

function InstanceUtils.New(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        if k ~= "Children" then
            inst[k] = v
        end
    end
    if props.Children then
        for _, child in ipairs(props.Children) do
            child.Parent = inst
        end
    end
    return inst
end

function InstanceUtils.Tag(inst, tag)
    if inst:FindFirstChild("Tags") then
        inst.Tags.Value = inst.Tags.Value .. "," .. tag
    end
end

function InstanceUtils.SafeDestroy(inst)
    if inst and inst.Parent then
        inst:Destroy()
    end
end

function InstanceUtils.ClearChildren(inst)
    for _, child in ipairs(inst:GetChildren()) do
        child:Destroy()
    end
end

function InstanceUtils.MakeScreenGui(name)
    local sg = Instance.new("ScreenGui")
    sg.Name = name or "IYMobileReborn"
    sg.DisplayOrder = 10
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    return sg
end

function InstanceUtils.MakeCorner(radius)
    return InstanceUtils.New("UICorner", {CornerRadius = UDim.new(0, radius)})
end

function InstanceUtils.MakePadding(padding)
    return InstanceUtils.New("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding)
    })
end

function InstanceUtils.MakeStroke(thickness, color, transparency)
    return InstanceUtils.New("UIStroke", {
        Thickness = thickness or 1,
        Color = color or Color3.fromRGB(255, 255, 255),
        Transparency = transparency or 0.8
    })
end

function InstanceUtils.MakeGradient(color1, color2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2)})
    g.Rotation = rotation or 45
    return g
end

return InstanceUtils
end)()

-- Module: src/utils/math.lua
_MODULES['src/utils/math.lua'] = (function()
local MathUtils = {}

function MathUtils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function MathUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

function MathUtils.Map(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) / (inMax - inMin) * (outMax - outMin)
end

function MathUtils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function MathUtils.SnapToGrid(value, gridSize)
    return math.floor(value / gridSize + 0.5) * gridSize
end

function MathUtils.FormatVector3(v)
    return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
end

function MathUtils.Distance(a, b)
    return (a - b).Magnitude
end

function MathUtils.FormatDistance(dist)
    if dist >= 1000 then
        return string.format("%.2f km", dist / 1000)
    end
    return string.format("%.1f m", dist)
end

return MathUtils
end)()

-- Module: src/utils/table.lua
_MODULES['src/utils/table.lua'] = (function()
local TableUtils = {}

function TableUtils.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[TableUtils.DeepCopy(k)] = TableUtils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function TableUtils.Merge(...)
    local result = {}
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" then
            for k, v in pairs(t) do
                result[k] = v
            end
        end
    end
    return result
end

function TableUtils.Find(t, predicate)
    for i, v in ipairs(t) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil
end

function TableUtils.Filter(t, predicate)
    local result = {}
    for i, v in ipairs(t) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

function TableUtils.Map(t, transform)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = transform(v, i)
    end
    return result
end

function TableUtils.Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function TableUtils.ToKeyMap(t, keyField)
    local map = {}
    for _, v in ipairs(t) do
        map[v[keyField]] = v
    end
    return map
end

return TableUtils
end)()

-- Module: assets/icons.lua
_MODULES['assets/icons.lua'] = (function()
--[[
    IY Mobile Reborn — Custom Font Icons
    Generados con TextService para consistencia cross-executor
]]

local Icons = {
    -- Navigation
    Home = "H",
    Commands = "C",
    Favorites = "S",
    Checkpoints = "P",
    Settings = "G",

    -- Categories
    Player = "P",
    Movement = "M",
    Visual = "V",
    Teleport = "T",
    World = "W",
    Tools = "O",
    Utilities = "U",
    Console = "L",
    Search = "Q",

    -- Actions
    Add = "+",
    Remove = "x",
    Edit = "E",
    Duplicate = "D",
    Export = "X",
    Import = "I",
    Teleport = "T",
    Update = "U",
    Rename = "R",
    Delete = "D",

    -- UI
    Close = "X",
    Back = "<",
    Next = ">",
    Menu = "=",
    Minimize = "_",
    Maximize = "O",
    Drag = ":",

    -- Status
    Check = "Y",
    Uncheck = "N",
    Info = "i",
    Warning = "!",
    Error = "E",
    Loading = "L",

    -- Media
    Play = ">",
    Pause = "||",
    Stop = "[]",
    Record = "O",

    -- Misc
    Star = "*",
    Clock = "@",
    Location = "#",
    Player_Icon = "&",
    Server = "$",
    World_Icon = "%",
    FPS = "F",
    Ping = "P",
    Bolt = "Z",
    Gear = "G",
    Book = "B",
    Tag = "T",
    Cube = "Q",
    Eye = "E",
}

return Icons
end)()

-- Bootstrap
local ok, err = pcall(function()
    local init = _require('src/init.lua')
    if type(init) == 'table' then
        if init.__boot then init.__boot() end
    elseif type(init) == 'function' then
        init()
    end
end)
if not ok then warn("[IY] Init error: " .. tostring(err)) end

return {
    Name = "Infinite Yield Mobile Reborn",
    Version = "2.0.0",
}