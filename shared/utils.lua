min, max, floor, abs, sin = math.min, math.max, math.floor, math.abs, math.sin
gsub, format, sub, len, rep = string.gsub, string.format, string.sub, string.len, string.rep

function reMap(value, low1, high1, low2, high2)
    return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function clamp(value, min, max)
    return max(min, min(max, value))
end

function byte2human(bytes)
    local units = { "B", "KB", "MB", "GB", "TB" }
    local i = 1

    while bytes >= 1024 and i < #units do
        bytes = bytes / 1024
        i = i + 1
    end

    return format("%.2f %s", bytes, units[i])
end

function Vector(...)
    if #arg == 4 then
        return { x = arg[1], y = arg[2], w = arg[3], h = arg[4] }
    elseif #arg == 3 then
        return { x = arg[1], y = arg[2], z = arg[3] }
    end

    return { x = arg[1], y = arg[2] }
end

function table.count(t)
    local count = 0

    for _ in pairs(t) do
        count = count + 1
    end

    return count
end

function registerEvent(event, to, handler)
    addEvent(event, true)
    addEventHandler(event, to, handler)
end

function getCategoryPath(val)
    if type(val) == "string" then
        return removeAccents(val):lower()
    end

    if MODS[val] then
        return getCategoryPath(MODS[val].Category)
    else
        for i, category in ipairs(CATEGORYS) do
            if i == val then
                return getCategoryPath(category)
            end
        end
    end
end

function getPathEncrypted(model)
    local category = getCategoryPath(model)

    return {
        txd = "assets/mods/encrypted/" .. category .. "/" .. md5(model .. "txd") .. "." .. SUFFIX_ENCRYPTED,
        dff = "assets/mods/encrypted/" .. category .. "/" .. md5(model .. "dff") .. "." .. SUFFIX_ENCRYPTED
    }
end

function getModelFromHash(hash, ext)
    if ext then
        for model in pairs(MODS) do
            if hash == md5(model .. ext) then
                return model, ext
            end
        end
    else
        for _, ext in ipairs({ "txd", "dff" }) do
            local result = {getModelFromHash(hash, ext)}

            if result[1] then
                return unpack(result)
            end
        end
    end
end

function printf(...)
    local args = {...}

    if #args == 1 and type(args[1]) == "string" then
        return print(format("[%s] %s", resourceName, args[1]))
    end

    return print(...)
end

function removeAccents(text)
    local accents = {
        ["á"] = "a", ["à"] = "a", ["ã"] = "a", ["â"] = "a", ["ä"] = "a",
        ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
        ["í"] = "i", ["ì"] = "i", ["î"] = "i", ["ï"] = "i",
        ["ó"] = "o", ["ò"] = "o", ["õ"] = "o", ["ô"] = "o", ["ö"] = "o",
        ["ú"] = "u", ["ù"] = "u", ["û"] = "u", ["ü"] = "u",
        ["ý"] = "y", ["ÿ"] = "y",
        ["ñ"] = "n", ["ç"] = "c",
        ["Á"] = "A", ["À"] = "A", ["Ã"] = "A", ["Â"] = "A", ["Ä"] = "A",
        ["É"] = "E", ["È"] = "E", ["Ê"] = "E", ["Ë"] = "E",
        ["Í"] = "I", ["Ì"] = "I", ["Î"] = "I", ["Ï"] = "I",
        ["Ó"] = "O", ["Ò"] = "O", ["Õ"] = "O", ["Ô"] = "O", ["Ö"] = "O",
        ["Ú"] = "U", ["Ù"] = "U", ["Û"] = "U", ["Ü"] = "U",
        ["Ý"] = "Y", ["Ÿ"] = "Y",
        ["Ñ"] = "N", ["Ç"] = "C"
    }

    return (gsub(text, "[%z\1-\127\194-\244][\128-\191]*", accents))
end