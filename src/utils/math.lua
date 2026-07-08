local MathUtils = {}

function MathUtils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function MathUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

function MathUtils.Map(value, inMin, inMax, outMin, outMax)
    return outMin + (value - inMin) / (inMax - inMin) * (outMax - outMin)
end

function MathUtils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function MathUtils.SnapToGrid(value, gridSize)
    return math.floor(value / gridSize + 0.5) * gridSize
end

function MathUtils.FormatVector3(v)
    return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
end

function MathUtils.Distance(a, b)
    return (a - b).Magnitude
end

function MathUtils.FormatDistance(dist)
    if dist >= 1000 then
        return string.format("%.2f km", dist / 1000)
    end
    return string.format("%.1f m", dist)
end

return MathUtils