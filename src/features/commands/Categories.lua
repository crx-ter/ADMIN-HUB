local Categories = {
	All = {},
	ById = {},
}

local data = {
	{
		id = "Player",
		name = "Player",
		icon = "P",
		color = Color3.fromRGB(59, 130, 246),
		description = "Player management",
	},
	{
		id = "Movement",
		name = "Movement",
		icon = "M",
		color = Color3.fromRGB(34, 197, 94),
		description = "Movement and flight",
	},
	{
		id = "Visual",
		name = "Visual",
		icon = "V",
		color = Color3.fromRGB(139, 92, 246),
		description = "Visual effects",
	},
	{
		id = "Teleport",
		name = "Teleport",
		icon = "T",
		color = Color3.fromRGB(249, 115, 22),
		description = "Teleportation",
	},
	{
		id = "World",
		name = "World",
		icon = "W",
		color = Color3.fromRGB(6, 182, 212),
		description = "World manipulation",
	},
	{
		id = "Tools",
		name = "Tools",
		icon = "O",
		color = Color3.fromRGB(234, 179, 8),
		description = "Tools and items",
	},
	{
		id = "Utilities",
		name = "Utilities",
		icon = "U",
		color = Color3.fromRGB(239, 68, 68),
		description = "General utilities",
	},
	{
		id = "Console",
		name = "Console",
		icon = "L",
		color = Color3.fromRGB(148, 163, 184),
		description = "Console and logging",
	},
	{
		id = "Trolling",
		name = "Trolling",
		icon = "F",
		color = Color3.fromRGB(236, 72, 153),
		description = "Fun and trolling",
	},
}

for _, cat in data do
	Categories.All[#Categories.All + 1] = cat
	Categories.ById[cat.id] = cat
end

function Categories.GetAll()
	return Categories.All
end

function Categories.GetById(id)
	return Categories.ById[id]
end

return Categories