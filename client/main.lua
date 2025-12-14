Main = {}

addEventHandler("onClientResourceStart", resourceRoot, function()
    Main.onStart()
end)

addEventHandler("onClientResourceStop", resourceRoot, function()
    Main.onStop()
end)

-- Events

function Main.onStart()
    Mods:onStart()
end

function Main.onStop()
    Mods:onStop()
end