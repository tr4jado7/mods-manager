CATEGORYS = { "Veículos", "Skins", "Facções", "Corporações", "Premium", "Pesados " } -- Categorias dos mods
SUFFIX_ENCRYPTED = "nexgen" -- Sufixo dos arquivos criptografados após o "." (qualquer nome)

MODS = {
    [411] = {
        Name = "Lamborghin Revuelto",
        Encrypt = true,
        Category = "Veículos"
    },

    [445] = {
        Name = "Ferrari La Ferrari",
        Encrypt = true,
        Category = "Skins"
    }
}

function outputNotification(...)
    if localPlayer then
        -- client side

        local message = arg[1]
        local type = arg[2] or "info"

        outputChatBox("[" .. type .. "]: " .. message)
    else
        -- server side

        local player = arg[1]
        local message = arg[2]
        local type = arg[3] or "info"

        outputChatBox("[" .. type .. "]: " .. message, player)
    end
end