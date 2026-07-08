local Categories = require(script.Parent.Categories)

local Registry = {
	all = {},
	byId = {},
	byCategory = {},
}

local function registerCommands(cmdList)
	for _, cmd in cmdList do
		Registry.all[#Registry.all + 1] = cmd
		Registry.byId[cmd.id] = cmd
		if not Registry.byCategory[cmd.category] then
			Registry.byCategory[cmd.category] = {}
		end
		Registry.byCategory[cmd.category][#Registry.byCategory[cmd.category] + 1] = cmd
	end
end

local commandModules = {
	require(script.Player),
	require(script.Movement),
	require(script.Visual),
	require(script.Teleport),
	require(script.World),
	require(script.Tools),
	require(script.Utilities),
	require(script.Console),
	require(script.Trolling),
}

for _, module in commandModules do
	registerCommands(module)
end

function Registry.GetAll()
	return Registry.all
end

function Registry.GetByCategory(catId)
	return Registry.byCategory[catId] or {}
end

function Registry.GetByName(name)
	local lower = name:lower()
	for _, cmd in Registry.all do
		if cmd.id:lower() == lower or cmd.name:lower() == lower then
			return cmd
		end
		for _, alias in cmd.aliases do
			if alias:lower() == lower then
				return cmd
			end
		end
	end
	return nil
end

function Registry.GetCount()
	return #Registry.all
end

function Registry.Search(query)
	local lower = query:lower()
	local results = {}
	for _, cmd in Registry.all do
		if cmd.id:lower():find(lower) or cmd.name:lower():find(lower) then
			results[#results + 1] = cmd
		else
			for _, alias in cmd.aliases do
				if alias:lower():find(lower) then
					results[#results + 1] = cmd
					break
				end
			end
		end
	end
	return results
end

function Registry.GetCategoriesWithCommands()
	local result = {}
	for _, cat in Categories.GetAll() do
		result[#result + 1] = {
			category = cat,
			commands = Registry.GetByCategory(cat.id),
		}
	end
	return result
end

return Registry