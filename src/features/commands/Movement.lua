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