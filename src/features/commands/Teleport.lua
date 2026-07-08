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