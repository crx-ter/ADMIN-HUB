local TableUtils = {}

function TableUtils.DeepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[TableUtils.DeepCopy(k)] = TableUtils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function TableUtils.Merge(...)
    local result = {}
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if type(t) == "table" then
            for k, v in pairs(t) do
                result[k] = v
            end
        end
    end
    return result
end

function TableUtils.Find(t, predicate)
    for i, v in ipairs(t) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil
end

function TableUtils.Filter(t, predicate)
    local result = {}
    for i, v in ipairs(t) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

function TableUtils.Map(t, transform)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = transform(v, i)
    end
    return result
end

function TableUtils.Shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function TableUtils.ToKeyMap(t, keyField)
    local map = {}
    for _, v in ipairs(t) do
        map[v[keyField]] = v
    end
    return map
end

return TableUtils