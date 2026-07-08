local Schema = {}

Schema.definition = {
	primaryColor = {
		key = "primaryColor",
		type = "Color3",
		default = Color3.fromRGB(59, 130, 246),
		min = Color3.new(0, 0, 0),
		max = Color3.new(1, 1, 1),
		step = nil,
		description = "Primary accent color for the UI",
	},
	secondaryColor = {
		key = "secondaryColor",
		type = "Color3",
		default = Color3.fromRGB(139, 92, 246),
		min = Color3.new(0, 0, 0),
		max = Color3.new(1, 1, 1),
		step = nil,
		description = "Secondary accent color for the UI",
	},
	panelTransparency = {
		key = "panelTransparency",
		type = "number",
		default = 0.4,
		min = 0,
		max = 1,
		step = 0.05,
		description = "Glass panel background transparency",
	},
	blurIntensity = {
		key = "blurIntensity",
		type = "number",
		default = 12,
		min = 0,
		max = 48,
		step = 2,
		description = "Background blur intensity for glass panels",
	},
	uiScale = {
		key = "uiScale",
		type = "number",
		default = 1.0,
		min = 0.5,
		max = 2.0,
		step = 0.1,
		description = "Global UI scale multiplier",
	},
	animationSpeed = {
		key = "animationSpeed",
		type = "number",
		default = 1.0,
		min = 0.1,
		max = 3.0,
		step = 0.1,
		description = "Animation speed multiplier",
	},
	showFPS = {
		key = "showFPS",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show FPS counter",
	},
	showPing = {
		key = "showPing",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show ping counter",
	},
	showClock = {
		key = "showClock",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show clock display",
	},
	floatingButton = {
		key = "floatingButton",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Show floating action button",
	},
	hapticFeedback = {
		key = "hapticFeedback",
		type = "boolean",
		default = true,
		min = nil,
		max = nil,
		step = nil,
		description = "Enable haptic feedback on interactions",
	},
	homeScreenStyle = {
		key = "homeScreenStyle",
		type = "string",
		default = "dynamic",
		min = nil,
		max = nil,
		step = nil,
		description = "Home screen layout style (dynamic, classic, minimal)",
	},
}

function Schema.GetDefaults()
	local defaults = {}
	for key, entry in pairs(Schema.definition) do
		defaults[key] = entry.default
	end
	return defaults
end

function Schema.GetDefinition(key)
	return Schema.definition[key]
end

function Schema.GetAll()
	return Schema.definition
end

return Schema