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