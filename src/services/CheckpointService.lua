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