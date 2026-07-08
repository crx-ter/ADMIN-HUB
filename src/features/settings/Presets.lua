local Presets = {}

local PRESET_LIST = {
	Ocean = {
		name = "Ocean",
		primary = Color3.fromRGB(14, 165, 233),
		secondary = Color3.fromRGB(6, 182, 212),
	},
	Purple = {
		name = "Purple",
		primary = Color3.fromRGB(139, 92, 246),
		secondary = Color3.fromRGB(168, 85, 247),
	},
	Emerald = {
		name = "Emerald",
		primary = Color3.fromRGB(16, 185, 129),
		secondary = Color3.fromRGB(52, 211, 153),
	},
	Rose = {
		name = "Rose",
		primary = Color3.fromRGB(244, 63, 94),
		secondary = Color3.fromRGB(251, 113, 133),
	},
	Amber = {
		name = "Amber",
		primary = Color3.fromRGB(245, 158, 11),
		secondary = Color3.fromRGB(251, 191, 36),
	},
}

function Presets.GetAll()
	local list = {}
	for _, preset in pairs(PRESET_LIST) do
		table.insert(list, {
			name = preset.name,
			primary = preset.primary,
			secondary = preset.secondary,
		})
	end
	return list
end

function Presets.Apply(name)
	for _, preset in pairs(PRESET_LIST) do
		if preset.name == name then
			return {
				primaryColor = preset.primary,
				secondaryColor = preset.secondary,
			}
		end
	end

	warn("[IY] Unknown preset:", name)
	return nil
end

return Presets