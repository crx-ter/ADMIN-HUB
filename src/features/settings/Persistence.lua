local HttpService = game:GetService("HttpService")

local Persistence = {}

local FILE_NAME = "IY_Settings.json"

function Persistence.Save(data)
	local json = HttpService:JSONEncode(data)
	local success, err = pcall(function()
		writefile(FILE_NAME, json)
	end)

	if not success then
		warn("[IY] Failed to save settings:", err)
	end
end

function Persistence.Load()
	local success, data = pcall(function()
		return readfile(FILE_NAME)
	end)

	if not success or data == nil or data == "" then
		return nil
	end

	local success2, decoded = pcall(function()
		return HttpService:JSONDecode(data)
	end)

	if not success2 or type(decoded) ~= "table" then
		return nil
	end

	return decoded
end

return Persistence