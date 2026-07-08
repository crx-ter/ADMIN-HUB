local Observer = require(script.Parent.Parent.core.observer)
local HttpService = game:GetService("HttpService")

local RecentActivity = {}
RecentActivity.__index = RecentActivity

local MAX_ENTRIES = 20
local FILE_NAME = "IY_Recent.json"

function RecentActivity.new()
	local self = setmetatable({
		_entries = {},
		_observer = Observer.new({ entries = {} }),
	}, RecentActivity)

	self:_load()
	return self
end

function RecentActivity:_load()
	local success, data = pcall(function()
		return readfile(FILE_NAME)
	end)

	if success and data and data ~= "" then
		local success2, decoded = pcall(function()
			return HttpService:JSONDecode(data)
		end)

		if success2 and type(decoded) == "table" then
			self._entries = decoded
			self._observer:Set("entries", self._entries)
		end
	end
end

function RecentActivity:Add(cmdName, cmdCategory, timestamp)
	local entry = {
		name = cmdName,
		category = cmdCategory,
		time = timestamp or DateTime.now():ToIsoDate(),
	}

	table.insert(self._entries, 1, entry)

	if #self._entries > MAX_ENTRIES then
		table.remove(self._entries)
	end

	self:_persist()
	self._observer:Set("entries", self._entries)
end

function RecentActivity:GetAll()
	return self._entries
end

function RecentActivity:Clear()
	self._entries = {}
	self:_persist()
	self._observer:Set("entries", self._entries)
end

function RecentActivity:_persist()
	local success, err = pcall(function()
		writefile(FILE_NAME, HttpService:JSONEncode(self._entries))
	end)

	if not success then
		warn("[IY] Failed to persist recent activity:", err)
	end
end

function RecentActivity:Watch(callback)
	return self._observer:Watch("entries", callback)
end

function RecentActivity:Destroy()
	self._observer:Destroy()
	self._entries = nil
end

return RecentActivity