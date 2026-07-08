local Observer = require(script.Parent.Parent.Parent.core.observer)
local Schema = require(script.Schema)
local Persistence = require(script.Persistence)

local SettingsStore = {}
SettingsStore.__index = SettingsStore

function SettingsStore.new()
	local defaults = Schema.GetDefaults()
	local saved = Persistence.Load()

	local initialData = {}
	for key, value in pairs(defaults) do
		if saved and saved[key] ~= nil then
			initialData[key] = saved[key]
		else
			initialData[key] = value
		end
	end

	local self = setmetatable({
		_data = initialData,
		_observer = Observer.new(initialData),
	}, SettingsStore)

	return self
end

function SettingsStore:Get(key)
	local def = Schema.GetDefinition(key)
	if not def then
		warn("[IY] Unknown setting:", key)
		return nil
	end

	local value = self._data[key]
	if value == nil then
		return def.default
	end
	return value
end

function SettingsStore:Set(key, value)
	local def = Schema.GetDefinition(key)
	if not def then
		warn("[IY] Unknown setting:", key)
		return false
	end

	if def.type == "number" then
		value = math.clamp(value, def.min, def.max)
		if def.step then
			value = math.round(value / def.step) * def.step
		end
	elseif def.type == "boolean" then
		value = not not value
	elseif def.type == "Color3" then
		value = Color3.new(
			math.clamp(value.R, 0, 1),
			math.clamp(value.G, 0, 1),
			math.clamp(value.B, 0, 1)
		)
	end

	self._data[key] = value
	self._observer:Set(key, value)
	Persistence.Save(self._data)
	return true
end

function SettingsStore:Reset(key)
	local def = Schema.GetDefinition(key)
	if not def then
		return false
	end

	self._data[key] = def.default
	self._observer:Set(key, def.default)
	Persistence.Save(self._data)
	return true
end

function SettingsStore:ResetAll()
	local defaults = Schema.GetDefaults()
	for key, value in pairs(defaults) do
		self._data[key] = value
	end

	self._observer:BatchSet(self._data)
	Persistence.Save(self._data)
end

function SettingsStore:GetSchema()
	return Schema.GetAll()
end

function SettingsStore:Watch(key, callback)
	return self._observer:Watch(key, callback)
end

function SettingsStore:Destroy()
	self._observer:Destroy()
	self._data = nil
end

return SettingsStore