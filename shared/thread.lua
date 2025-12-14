Thread = {}

function Thread:create(func)
    local co = coroutine.create(func)
    coroutine.resume(co)
end

function Thread:sleep(time)
    local co = coroutine.running()

    if not co then
        return false
    end

    setTimer(function()
        coroutine.resume(co)
    end, time, 1)

    self:pause()
end

function Thread:pause()
    return coroutine.yield()
end

_fetchRemote = fetchRemote
function fetchRemote(url, options, ...)
    local co = coroutine.running()
    if not co then
        return _fetchRemote(url, options, ...)
    end

    local result
    _fetchRemote(url, options, function(code, received)
        result = { code, received }
    end)

    local lapsed = 0
    while not result do
        Thread:sleep(100)
        lapsed = lapsed + 100

        if lapsed >= 5000 then
            return 408
        end
    end

    return unpack(result)
end