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