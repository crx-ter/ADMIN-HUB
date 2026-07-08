local Throttle = require(script.Parent.Parent.Parent.core.throttle)
local Indexer = require(script.Indexer)
local Fuzzy = require(script.Fuzzy)

local Searcher = {}
Searcher.__index = Searcher

local DEBOUNCE_TIME = 0.15

function Searcher.new()
	local self = setmetatable({
		_indexer = Indexer.new(),
		_debounced = Throttle:Debounce(function() end, DEBOUNCE_TIME),
	}, Searcher)
	return self
end

function Searcher:Build(commands)
	self._indexer:Build(commands)
end

function Searcher:Search(query)
	if not query or #query == 0 then
		return {}
	end

	query = query:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if #query == 0 then
		return {}
	end

	local results = {}
	local seen = {}

	local indexedResults = self._indexer:Search(query)
	for _, result in ipairs(indexedResults) do
		local cmd = result.command
		local score = Fuzzy.Score(query, cmd.name)
		seen[cmd] = true
		table.insert(results, {
			command = cmd,
			score = math.max(score, result.relevance * 0.1),
		})
	end

	local commands = self._indexer:GetCommands()
	for _, cmd in ipairs(commands) do
		if not seen[cmd] then
			local nameScore = Fuzzy.Score(query, cmd.name)
			local bestScore = nameScore

			if cmd.aliases then
				for _, alias in ipairs(cmd.aliases) do
					local aliasScore = Fuzzy.Score(query, alias)
					if aliasScore > bestScore then
						bestScore = aliasScore
					end
				end
			end

			if cmd.category then
				local catScore = Fuzzy.Score(query, cmd.category)
				if catScore > bestScore then
					bestScore = catScore
				end
			end

			if bestScore > 0 then
				table.insert(results, {
					command = cmd,
					score = bestScore,
				})
			end
		end
	end

	table.sort(results, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.command.name and b.command.name then
			return #a.command.name < #b.command.name
		end
		return false
	end)

	return results
end

return Searcher