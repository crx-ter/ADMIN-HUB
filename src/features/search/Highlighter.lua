local Highlighter = {}

function Highlighter.Highlight(text, query)
	if not text or not query or #query == 0 then
		return { { text = text or "", matched = false } }
	end

	local lowerText = text:lower()
	local lowerQuery = query:lower()

	local segments = {}
	local searchStart = 1
	local textLen = #text

	while searchStart <= textLen do
		local matchStart = lowerText:find(lowerQuery, searchStart, true)

		if not matchStart then
			table.insert(segments, {
				text = text:sub(searchStart),
				matched = false,
			})
			break
		end

		if matchStart > searchStart then
			table.insert(segments, {
				text = text:sub(searchStart, matchStart - 1),
				matched = false,
			})
		end

		local matchEnd = matchStart + #query - 1
		table.insert(segments, {
			text = text:sub(matchStart, matchEnd),
			matched = true,
		})

		searchStart = matchEnd + 1
	end

	return segments
end

return Highlighter