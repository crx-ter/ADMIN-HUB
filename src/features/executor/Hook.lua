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