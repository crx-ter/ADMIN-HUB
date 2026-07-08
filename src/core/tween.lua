local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TweenKit = {}
TweenKit.__index = TweenKit

local _pool = {}
local _poolSize = 0
local _MAX_POOL = 100

local EASING_MAP = {
    InQuad = Enum.EasingStyle.Quad,
    OutQuad = Enum.EasingStyle.Quad,
    InOutQuad = Enum.EasingStyle.Quad,
    InCubic = Enum.EasingStyle.Cubic,
    OutCubic = Enum.EasingStyle.Cubic,
    InOutCubic = Enum.EasingStyle.Cubic,
    InQuart = Enum.EasingStyle.Quart,
    OutQuart = Enum.EasingStyle.Quart,
    InOutQuart = Enum.EasingStyle.Quart,
    InQuint = Enum.EasingStyle.Quint,
    OutQuint = Enum.EasingStyle.Quint,
    InOutQuint = Enum.EasingStyle.Quint,
    InSine = Enum.EasingStyle.Sine,
    OutSine = Enum.EasingStyle.Sine,
    InOutSine = Enum.EasingStyle.Sine,
    InExpo = Enum.EasingStyle.Exponential,
    OutExpo = Enum.EasingStyle.Exponential,
    InOutExpo = Enum.EasingStyle.Exponential,
    InCirc = Enum.EasingStyle.Circular,
    OutCirc = Enum.EasingStyle.Circular,
    InOutCirc = Enum.EasingStyle.Circular,
    InElastic = Enum.EasingStyle.Elastic,
    OutElastic = Enum.EasingStyle.Elastic,
    InOutElastic = Enum.EasingStyle.Elastic,
    InBack = Enum.EasingStyle.Back,
    OutBack = Enum.EasingStyle.Back,
    InOutBack = Enum.EasingStyle.Back,
    InBounce = Enum.EasingStyle.Bounce,
    OutBounce = Enum.EasingStyle.Bounce,
    InOutBounce = Enum.EasingStyle.Bounce,
    Linear = Enum.EasingStyle.Linear,
}

local function getEasing(easingName)
    local info = EASING_MAP[easingName]
    if info then
        local dir = Enum.EasingDirection.In
        if easingName:match("^Out") then
            dir = Enum.EasingDirection.Out
        elseif easingName:match("^InOut") then
            dir = Enum.EasingDirection.InOut
        end
        return info, dir
    end
    return Enum.EasingStyle.Quad, Enum.EasingDirection.Out
end

function TweenKit.new(instance, goal, duration, easingName, overwrite)
    local easingStyle, easingDir = getEasing(easingName or "OutQuad")

    if overwrite ~= false then
        TweenKit:CancelInstance(instance)
    end

    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle, easingDir, 0, false, 0)
    local tween

    if _poolSize > 0 and #_pool > 0 then
        tween = table.remove(_pool)
        _poolSize = _poolSize - 1
        tween:Play()
    else
        tween = TweenService:Create(instance, tweenInfo, goal)
    end

    tween:Play()

    local meta = {
        Tween = tween,
        Instance = instance,
        Goal = goal,
        Playing = true,
        Completed = false,
    }

    tween.Completed:Connect(function()
        meta.Playing = false
        meta.Completed = true
        if _poolSize < _MAX_POOL then
            tween:Cancel()
            table.insert(_pool, tween)
            _poolSize = _poolSize + 1
        end
    end)

    return meta
end

function TweenKit:CancelInstance(instance)
    instance = instance:IsA("Instance") and instance or instance.Instance
end

function TweenKit:Cancel(meta)
    if meta and meta.Tween and meta.Playing then
        meta.Tween:Cancel()
        meta.Playing = false
        meta.Completed = true
    end
end

function TweenKit:Sequence(instance, steps, onComplete)
    local index = 1
    local function playNext()
        if index > #steps then
            if onComplete then onComplete() end
            return
        end
        local step = steps[index]
        local meta = TweenKit.new(instance, step.Goal, step.Duration or 0.3, step.Easing or "OutQuad")
        task.delay(step.Duration or 0.3, playNext)
        index = index + 1
    end
    playNext()
end

function TweenKit:Parallel(tweens, onComplete)
    local remaining = #tweens
    if remaining == 0 then
        if onComplete then onComplete() end
        return
    end
    for _, t in ipairs(tweens) do
        TweenKit.new(t.Instance, t.Goal, t.Duration or 0.3, t.Easing or "OutQuad", t.Overwrite)
    end
    if onComplete then
        task.delay(0.35, onComplete)
    end
end

function TweenKit:Scale(instance, targetScale, duration, easing)
    return TweenKit.new(instance, {Size = UDim2.fromScale(targetScale.X, targetScale.Y)}, duration or 0.3, easing or "OutBack")
end

function TweenKit:Fade(instance, targetTransparency, duration, easing)
    return TweenKit.new(instance, {Transparency = targetTransparency}, duration or 0.3, easing or "OutQuad")
end

function TweenKit:Move(instance, targetPosition, duration, easing)
    return TweenKit.new(instance, {Position = targetPosition}, duration or 0.3, easing or "OutQuad")
end

return TweenKit