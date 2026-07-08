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