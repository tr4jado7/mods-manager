Main = {}

addEventHandler("onResourceStart", resourceRoot, function()
    Main.onStart()
end)

-- Events

function Main.onStart()
    Mods:onStart()
end