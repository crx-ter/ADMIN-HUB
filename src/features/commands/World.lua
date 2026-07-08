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