if localPlayer then
    local responses = {}

    addEvent(resourceName .. ":onClientReceiveRemoteCall", true)
    addEventHandler(resourceName .. ":onClientReceiveRemoteCall", resourceRoot, function(identifier, data)
        responses[identifier] = data
    end)

    function requestRemoteCall(eventName, ...)
        assert(coroutine.running(), "You need use a Thread to use requestRemoteCall.")

        local identifier = eventName .. ":" .. math.random(1, 999999)

        triggerServerEvent(resourceName .. ":onReceiveRemoteCallRequest", resourceRoot, identifier, eventName, ...)

        local sleep = 0
        while not responses[identifier] do
            Thread:sleep(100)
            sleep = sleep + 100

            if sleep >= 60000 then
                return false
            end
        end

        return unpack(responses[identifier])
    end
else
    local handledFunctions = {}

    addEvent(resourceName .. ":onReceiveRemoteCallRequest", true)
    addEventHandler(resourceName .. ":onReceiveRemoteCallRequest", resourceRoot, function(identifier, eventName, ...)
        local handler = handledFunctions[eventName]

        if not handler then
            return
        end

        local args = {...}

        Thread:create(function()
            triggerClientEvent(client, resourceName .. ":onClientReceiveRemoteCall", resourceRoot, identifier, {handler(client, unpack(args))})
        end)
    end)

    function addRemoteCall(eventName, func)
        handledFunctions[eventName] = func
    end
end