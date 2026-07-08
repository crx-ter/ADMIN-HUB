local TweenKit = require(script.Parent.Parent.Parent.core.tween)
local Theme = require(script.Parent.Parent.Parent.core.theme)
local InstanceUtils = require(script.Parent.Parent.Parent.utils.instance)

local Router = {}
Router.__index = Router

function Router.new(parent, props)
	props = props or {}

	local self = setmetatable({
		_parent = parent,
		_screens = {},
		_currentScreen = nil,
		_history = {},
		_maxHistory = 10,
		_onNavigate = props.OnNavigate or function() end,
		_destroyed = false,
	}, Router)

	return self
end

function Router:Register(name, constructor)
	self._screens[name] = constructor
end

function Router:Navigate(targetScreen, params)
	if self._destroyed then return end
	if not self._screens[targetScreen] then
		warn(("Router: Screen '%s' not registered"):format(targetScreen))
		return
	end

	if self._currentScreen then
		table.insert(self._history, 1, {
			Name = self._currentScreen.Name,
			Instance = self._currentScreen.Instance,
		})
		if #self._history > self._maxHistory then
			table.remove(self._history)
		end
	end

	local direction = "left"
	if self._currentScreen then
		local prevIdx = 0
		local nextIdx = 0
		for i, name in ipairs(self._currentScreen._allNames or {}) do
			if name == self._currentScreen.Name then prevIdx = i end
			if name == targetScreen then nextIdx = i end
		end
		if nextIdx > prevIdx then
			direction = "left"
		else
			direction = "right"
		end
	end

	local oldScreen = self._currentScreen

	local container = InstanceUtils.New("Frame", {
		Name = "ScreenContainer_" .. targetScreen,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(direction == "left" and 1 or -1, 0),
		BackgroundTransparency = 1,
		Parent = self._parent,
	})

	local screen = self._screens[targetScreen](container, params or {})
	self._currentScreen = {
		Name = targetScreen,
		Instance = container,
		Screen = screen,
		_allNames = oldScreen and oldScreen._allNames or {targetScreen},
	}

	if oldScreen then
		local oldNames = oldScreen._allNames or {}
		local found = false
		for _, name in ipairs(oldNames) do
			if name == targetScreen then found = true end
		end
		if not found then
			table.insert(self._currentScreen._allNames, targetScreen)
		end
	end

	TweenKit.new(container, {Position = UDim2.fromScale(0, 0)}, 0.3, "OutQuad")

	if oldScreen then
		local oldContainer = oldScreen.Instance
		local exitX = direction == "left" and -1 or 1
		TweenKit.new(oldContainer, {Position = UDim2.fromScale(exitX, 0)}, 0.3, "InQuad")
		task.delay(0.35, function()
			if oldContainer and oldContainer.Parent then
				oldContainer:Destroy()
			end
		end)
	end

	self._onNavigate(targetScreen, params)
end

function Router:GetCurrent()
	return self._currentScreen and self._currentScreen.Name or nil
end

function Router:GoBack()
	if self._destroyed then return end
	if #self._history == 0 then return end

	local previous = table.remove(self._history, 1)
	if previous then
		if self._currentScreen then
			local oldContainer = self._currentScreen.Instance
			TweenKit.new(oldContainer, {Position = UDim2.fromScale(1, 0)}, 0.3, "InQuad")
			task.delay(0.35, function()
				if oldContainer and oldContainer.Parent then
					oldContainer:Destroy()
				end
			end)
		end

		previous.Instance.Position = UDim2.fromScale(-1, 0)
		previous.Instance.Parent = self._parent
		self._currentScreen = previous
		TweenKit.new(previous.Instance, {Position = UDim2.fromScale(0, 0)}, 0.3, "OutQuad")
		self._onNavigate(previous.Name)
	end
end

function Router:GetScreen(name)
	if self._currentScreen and self._currentScreen.Name == name then
		return self._currentScreen.Screen
	end
	return nil
end

function Router:Destroy()
	self._destroyed = true
	for _, screen in ipairs(self._history) do
		if screen.Instance then screen.Instance:Destroy() end
	end
	self._history = {}
	if self._currentScreen and self._currentScreen.Instance then
		self._currentScreen.Instance:Destroy()
	end
	self._currentScreen = nil
	self._screens = {}
end

return Router