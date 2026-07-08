local Indexer = {}
Indexer.__index = Indexer

function Indexer.new()
	local self = setmetatable({
		_index = {},
		_commands = {},
	}, Indexer)
	return self
end

function Indexer:Build(commands)
	self._commands = commands
	self._index = {}

	for _, cmd in ipairs(commands) do
		local terms = {}

		if cmd.name then
			table.insert(terms, cmd.name:lower())
		end

		if cmd.aliases then
			for _, alias in ipairs(cmd.aliases) do
				table.insert(terms, alias:lower())
			end
		end

		if cmd.description then
			for word in cmd.description:gmatch("%S+") do
				table.insert(terms, word:lower():gsub("[%p,]", ""))
			end
		end

		if cmd.category then
			table.insert(terms, cmd.category:lower())
		end

		for _, term in ipairs(terms) do
			if term and #term > 0 then
				for i = 1, #term do
					local prefix = term:sub(1, i)
					if not self._index[prefix] then
						self._index[prefix] = {}
					end
					if not self._index[prefix][cmd] then
						self._index[prefix][cmd] = 0
					end
					self._index[prefix][cmd] = self._index[prefix][cmd] + 1
				end
			end
		end
	end
end

function Indexer:Search(query)
	query = query:lower():gsub("%s+", "")
	if #query == 0 then
		return {}
	end

	local results = {}
	local candidates = self._index[query]

	if candidates then
		for cmd, count in pairs(candidates) do
			table.insert(results, { command = cmd, relevance = count })
		end
	end

	table.sort(results, function(a, b)
		return a.relevance > b.relevance
	end)

	return results
end

function Indexer:GetCommands()
	return self._commands
end

return Indexer