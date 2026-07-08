local RunService = game:GetService("RunService")

local Throttle = {}

function Throttle:Debounce(fn, waitTime)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= waitTime then
            lastCall = now
            return fn(...)
        end
        return false
    end
end

function Throttle:Throttle(fn, minInterval)
    local lastCall = 0
    local pending = false
    local lastArgs = nil

    return function(...)
        local now = tick()
        lastArgs = {...}

        if now - lastCall >= minInterval then
            lastCall = now
            pending = false
            return fn(table.unpack(lastArgs))
        end

        if not pending then
            pending = true
            task.delay(minInterval - (now - lastCall), function()
                pending = false
                if lastArgs then
                    lastCall = tick()
                    fn(table.unpack(lastArgs))
                end
            end)
        end
        return false
    end
end

function Throttle:Coalesce(fn, window)
    local timer = nil
    local lastArgs = nil

    return function(...)
        lastArgs = {...}
        if timer then return end
        timer = task.delay(window or 0.1, function()
            timer = nil
            if lastArgs then
                fn(table.unpack(lastArgs))
            end
        end)
    end
end

function Throttle:Rail(fn, minInterval)
    local cooldown = false
    local queue = false
    local queuedArgs = nil

    return function(...)
        if cooldown then
            queue = true
            queuedArgs = {...}
            return
        end

        cooldown = true
        fn(...)

        task.delay(minInterval, function()
            cooldown = false
            if queue then
                queue = false
                fn(table.unpack(queuedArgs))
                cooldown = true
                task.delay(minInterval, function()
                    cooldown = false
                end)
            end
        end)
    end
end

function Throttle:FrameRate(fn)
    local running = false
    return function(...)
        if running then return end
        running = true
        RunService.Heartbeat:Wait()
        running = false
        fn(...)
    end
end

return Throttle