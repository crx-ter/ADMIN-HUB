local Signal = require(script.Parent.signal)

local Observer = {}
Observer.__index = Observer

function Observer.new(initialData)
    local self = setmetatable({
        _data = initialData or {},
        _signals = {},
    }, Observer)
    return self
end

function Observer:_getSignal(key)
    if not self._signals[key] then
        self._signals[key] = Signal.new()
    end
    return self._signals[key]
end

function Observer:Get(key)
    return self._data[key]
end

function Observer:Set(key, value)
    local old = self._data[key]
    if old == value then return end
    self._data[key] = value
    local sig = self._signals[key]
    if sig then
        sig:Fire(value, old)
    end
end

function Observer:Update(key, transform)
    local old = self._data[key]
    local new = transform(old)
    self:Set(key, new)
end

function Observer:Watch(key, callback)
    local sig = self:_getSignal(key)
    local conn = sig:Connect(callback)
    callback(self._data[key], nil)
    return conn
end

function Observer:WatchOnce(key, callback)
    local sig = self:_getSignal(key)
    return sig:Once(callback)
end

function Observer:BatchSet(changes)
    local affected = {}
    for key, value in pairs(changes) do
        local old = self._data[key]
        if old ~= value then
            self._data[key] = value
            affected[key] = {New = value, Old = old}
        end
    end
    for key, change in pairs(affected) do
        local sig = self._signals[key]
        if sig then
            sig:Fire(change.New, change.Old)
        end
    end
end

function Observer:Destroy()
    for _, sig in pairs(self._signals) do
        sig:Destroy()
    end
    self._signals = nil
    self._data = nil
end

return Observer