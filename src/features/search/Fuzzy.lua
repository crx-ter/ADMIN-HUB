local Fuzzy = {}

function Fuzzy.Score(query, text)
	if not query or not text or #query == 0 or #text == 0 then
		return 0
	end

	query = query:lower():gsub("%s+", "")
	text = text:lower():gsub("%s+", "")

	if #query == 0 or #text == 0 then
		return 0
	end

	if query == text then
		return 1.0
	end

	if text:sub(1, #query) == query then
		return 0.8
	end

	if text:find(query, 1, true) then
		return 0.6
	end

	local charScore = Fuzzy._charMatch(query, text)
	return charScore * 0.3
end

function Fuzzy._charMatch(query, text)
	if #query > #text then
		return 0
	end

	local ti = 1
	local matches = 0

	for qi = 1, #query do
		local qc = query:sub(qi, qi)
		local found = false

		while ti <= #text do
			local tc = text:sub(ti, ti)
			ti = ti + 1
			if qc == tc then
				matches = matches + 1
				found = true
				break
			end
		end

		if not found then
			break
		end
	end

	return matches / #query
end

return Fuzzy