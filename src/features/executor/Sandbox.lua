local Sandbox = {}

local RESTRICTED_GLOBALS = {
	require = true,
	loadstring = true,
	loadfile = true,
	dofile = true,
	writefile = true,
	readfile = true,
	appendfile = true,
	delfile = true,
	makefolder = true,
	listfiles = true,
	setclipboard = true,
	getclipboard = true,
	getrawmetatable = true,
	setrawmetatable = true,
	gettread = true,
	newthread = true,
	coroutine = true,
	debug = true,
	io = true,
	os = true,
}

local ALLOWED_GLOBALS = {
	["print"] = true,
	["warn"] = true,
	["error"] = true,
	["type"] = true,
	["typeof"] = true,
	["tostring"] = true,
	["tonumber"] = true,
	["pairs"] = true,
	["ipairs"] = true,
	["next"] = true,
	["select"] = true,
	["unpack"] = true,
	["table"] = true,
	["string"] = true,
	["math"] = true,
	["Vector3"] = true,
	["Vector2"] = true,
	["CFrame"] = true,
	["UDim2"] = true,
	["Color3"] = true,
	["DateTime"] = true,
	["Instance"] = true,
	["game"] = true,
	["workspace"] = true,
	["script"] = true,
	["task"] = true,
	["delay"] = true,
	["spawn"] = true,
	["tick"] = true,
	["time"] = true,
	["elapsed"] = true,
}

function Sandbox.Execute(code)
	if type(code) ~= "string" or #code == 0 then
		warn("[IY] Sandbox: empty or invalid code")
		return false, "No code provided"
	end

	local env = {}
	for k in pairs(ALLOWED_GLOBALS) do
		env[k] = _G[k]
	end

	env._VERSION = nil
	env.module = nil
	env.package = nil

	local sandboxMeta = {
		__index = function(_, key)
			if RESTRICTED_GLOBALS[key] then
				return nil
			end
			return _G[key]
		end,
		__newindex = function(_, key, value)
			if RESTRICTED_GLOBALS[key] then
				warn("[IY] Sandbox: blocked write to", key)
				return
			end
			rawset(env, key, value)
		end,
	}

	setmetatable(env, sandboxMeta)

	local fn, compileError = loadstring(code)
	if not fn then
		warn("[IY] Sandbox: compile error -", compileError)
		return false, compileError
	end

	setfenv(fn, env)

	local success, result = pcall(fn)
	if not success then
		warn("[IY] Sandbox: runtime error -", result)
		return false, result
	end

	return true, result
end

return Sandbox