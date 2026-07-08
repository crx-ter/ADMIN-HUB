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