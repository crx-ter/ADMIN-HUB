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