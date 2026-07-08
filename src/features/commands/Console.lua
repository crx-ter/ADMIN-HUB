local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Console = {}

local function getPlayer()
	return Players.LocalPlayer
end

local consoleVisible = true
local consoleGui = nil

function Console.Print()
	return {
		id = "Print",
		name = "Print",
		aliases = { "print", "log" },
		description = "Print a message to console",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(msg)
			print("[IY] " .. tostring(msg or ""))
		end,
		onUndo = function() end,
	}
end

function Console.Warn()
	return {
		id = "Warn",
		name = "Warn",
		aliases = { "warn" },
		description = "Print a warning",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(msg)
			warn("[IY] " .. tostring(msg or ""))
		end,
		onUndo = function() end,
	}
end

function Console.Error()
	return {
		id = "Error",
		name = "Error",
		aliases = { "error" },
		description = "Print an error",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(msg)
			local errMsg = "[IY] " .. tostring(msg or "Unknown error")
			error(errMsg)
		end,
		onUndo = function() end,
	}
end

function Console.ClearConsole()
	return {
		id = "ClearConsole",
		name = "Clear Console",
		aliases = { "clearconsole", "clear", "cls" },
		description = "Clear console output",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					local log = gui:FindFirstChild("Log")
					if log then
						log:ClearAllChildren()
					end
				end
			end
			for _ = 1, 50 do
				print("")
			end
		end,
		onUndo = function() end,
	}
end

function Console.ConsoleToggle()
	return {
		id = "ConsoleToggle",
		name = "Console Toggle",
		aliases = { "consoletoggle", "toggleconsole", "togcon" },
		description = "Show/hide console",
		category = "Console",
		icon = "L",
		isToggle = true,
		onExecute = function()
			consoleVisible = not consoleVisible
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					gui.Enabled = consoleVisible
				end
			end
		end,
		onUndo = function()
			consoleVisible = true
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					gui.Enabled = true
				end
			end
		end,
	}
end

function Console.ExecutorInfo()
	return {
		id = "ExecutorInfo",
		name = "Executor Info",
		aliases = { "executorinfo", "exeinfo", "ei" },
		description = "Show executor info",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local info = {
				Name = "IY Mobile Reborn",
				Version = "1.0.0",
				Executor = identifyexecutor and identifyexecutor() or "Unknown",
				Platform = "Mobile/Cross-Platform",
			}
			print("=== Executor Info ===")
			for k, v in info do
				print(k .. ": " .. tostring(v))
			end
			print("====================")
		end,
		onUndo = function() end,
	}
end

function Console.ScriptInfo()
	return {
		id = "ScriptInfo",
		name = "Script Info",
		aliases = { "scriptinfo", "si" },
		description = "Show script info",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			print("=== IY Mobile Reborn ===")
			print("Version: 1.0.0")
			print("Commands: " .. tostring(#require(script.Parent.Registry).GetAll()))
			print("Infinity Yield inspired")
			print("Build: " .. game:GetService("HttpService"):GenerateGUID(false):sub(1, 8))
		end,
		onUndo = function() end,
	}
end

function Console.Version()
	return {
		id = "Version",
		name = "Version",
		aliases = { "version", "ver" },
		description = "Show version",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			print("IY Mobile Reborn v1.0.0")
		end,
		onUndo = function() end,
	}
end

function Console.Help()
	return {
		id = "Help",
		name = "Help",
		aliases = { "help", "?" },
		description = "Show help message",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function(cmdName)
			if cmdName then
				local registry = require(script.Parent.Registry)
				local cmd = registry.GetByName(cmdName)
				if cmd then
					print("=== " .. cmd.name .. " ===")
					print("ID: " .. cmd.id)
					print("Category: " .. cmd.category)
					print("Description: " .. cmd.description)
					if #cmd.aliases > 0 then
						print("Aliases: [" .. table.concat(cmd.aliases, ", ") .. "]")
					end
					print("Toggle: " .. tostring(cmd.isToggle))
				else
					warn("Command not found: " .. cmdName)
				end
			else
				local registry = require(script.Parent.Registry)
				local all = registry.GetAll()
				print("=== IY Mobile Reborn - Help ===")
				print("Total commands: " .. tostring(#all))
				print("Use 'help <command>' for details")
				print("================================")
			end
		end,
		onUndo = function() end,
	}
end

function Console.Credits()
	return {
		id = "Credits",
		name = "Credits",
		aliases = { "credits" },
		description = "Show credits",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			print("=== IY Mobile Reborn ===")
			print("Original: Infinite Yield")
			print("Mobile Re-creation")
			print("Thanks to the exploit community")
			print("=========================")
		end,
		onUndo = function() end,
	}
end

function Console.CopyOutput()
	return {
		id = "CopyOutput",
		name = "Copy Output",
		aliases = { "copyoutput", "copyout" },
		description = "Copy console output",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					local log = gui:FindFirstChild("Log")
					if log then
						local text = ""
						for _, child in log:GetChildren() do
							if child:IsA("TextLabel") or child:IsA("TextButton") then
								text ..= child.Text .. "\n"
							end
						end
						setclipboard(text)
						warn("Console output copied to clipboard")
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

function Console.SaveLog()
	return {
		id = "SaveLog",
		name = "Save Log",
		aliases = { "savelog", "logsave" },
		description = "Save log to file",
		category = "Console",
		icon = "L",
		isToggle = false,
		onExecute = function()
			local plr = getPlayer()
			if plr then
				local gui = plr.PlayerGui:FindFirstChild("IY_Console")
				if gui then
					local log = gui:FindFirstChild("Log")
					if log then
						local text = ""
						for _, child in log:GetChildren() do
							if child:IsA("TextLabel") or child:IsA("TextButton") then
								text ..= child.Text .. "\n"
							end
						end
						local fileName = "IY_Log_" .. os.time() .. ".txt"
						writefile(fileName, text)
						warn("Log saved to " .. fileName)
					end
				end
			end
		end,
		onUndo = function() end,
	}
end

local commandFactories = {
	Console.Print,
	Console.Warn,
	Console.Error,
	Console.ClearConsole,
	Console.ConsoleToggle,
	Console.ExecutorInfo,
	Console.ScriptInfo,
	Console.Version,
	Console.Help,
	Console.Credits,
	Console.CopyOutput,
	Console.SaveLog,
}

local commands = {}
for _, factory in commandFactories do
	commands[#commands + 1] = factory()
end

return commands