local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({
        _connections = {},
        _connectionId = 0,
    }, Signal)
    return self
end

function Signal:Connect(callback)
    self._connectionId = self._connectionId + 1
    local id = self._connectionId
    local conn = {
        Id = id,
        Callback = callback,
        Connected = true,
    }
    table.insert(self._connections, conn)
    return conn
end

function Signal:Once(callback)
    local wrapper
    local conn
    wrapper = function(...)
        if conn and conn.Connected then
            conn.Connected = false
            callback(...)
        end
    end
    conn = self:Connect(wrapper)
    return conn
end

function Signal:Fire(...)
    for i = #self._connections, 1, -1 do
        local conn = self._connections[i]
        if conn.Connected then
            local success, err = pcall(conn.Callback, ...)
            if not success then
                warn("[IY] Signal error:", err)
            end
        else
            table.remove(self._connections, i)
        end
    end
end

function Signal:Disconnect(connection)
    if connection and connection.Connected then
        connection.Connected = false
        for i, conn in ipairs(self._connections) do
            if conn.Id == connection.Id then
                table.remove(self._connections, i)
                break
            end
        end
    end
end

function Signal:DisconnectAll()
    for _, conn in ipairs(self._connections) do
        conn.Connected = false
    end
    self._connections = {}
end

function Signal:Destroy()
    self:DisconnectAll()
    self._connections = nil
end

return Signal