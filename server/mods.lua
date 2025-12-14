Mods = {}

-- Events

function Mods:onStart()
    self.totalSize = {
        view = 0,
        kbytes = 0
    }

    self.allowClient = true
    self.modsList = self:refreshList()

    self.funcs = {
        onGetDependencies = function() return Mods:onGetDependencies() end
    }

    addRemoteCall("onGetDependencies", self.funcs.onGetDependencies)
end

function Mods:onGetDependencies()
    return self.modsList, get("password"), self.allowClient, self.totalSize
end

-- Functions

function Mods:refreshList()
    local mods = {}
    local index = 1
    local totalSize = 0

    local needEncrypt = false
    local successStart = true

    for i, data in pairs(MODS) do
        local category = getCategoryPath(i)

        if pathIsDirectory("assets/mods/decrypted/" .. category) then
            if not mods[category] then
                mods[category] = {}
            end

            local path = "assets/mods/decrypted/" .. category .. "/" .. i
            local txd, dff

            if fileExists(path .. ".txd") and fileExists(path .. ".dff") then
                if data.Encrypt and not needEncrypt then
                    for _, ext in ipairs({ "txd", "dff" }) do
                        if not fileExists(getPathEncrypted(i)[ext]) then
                            needEncrypt = true
                            break
                        end
                    end
                end

                txd = fileOpen(path .. ".txd")
                dff = fileOpen(path .. ".dff")

                if txd and dff then
                    local size = fileGetSize(txd) + fileGetSize(dff)

                    totalSize = totalSize + size

                    fileClose(txd)
                    fileClose(dff)

                    mods[category][i] = {
                        name = data.Name,
                        model = i,
                        encrypt = data.Encrypt,
                        category = category,
                        size = size,
                        sizeFormatted = byte2human(size),
                        state = "not downloaded",
                        index = index
                    }

                    index = index + 1
                else
                    printf("Falha ao abrir os arquivos " .. i)
                    successStart = false
                end
            else
                printf("Mod " .. i .. " não encontrado na pasta " .. category)
                successStart = false
            end
        else
            printf("Pasta \"" .. category .. "\" não encontrada")
            successStart = false
        end
    end

    if needEncrypt then
        printf("Arquivos não criptografados encontrados, criptografando...")

        for i, v in pairs(MODS) do
            if v.Encrypt then
                self:encryptMod(i)
            end
        end

        printf("Arquivos criptografados com sucesso")
        printf("Reinicie o resource para aplicar as alterações")

        self.allowClient = false
    end

    if successStart then
        printf("Mods carregados com sucesso")
    end

    self.totalSize = {
        view = byte2human(totalSize),
        bytes = totalSize
    }

    return mods
end

function Mods:encryptMod(model)
    local data = MODS[model]

    if not data then
        return
    end

    local category = getCategoryPath(model)
    local path = "assets/mods/decrypted/" .. category .. "/" .. model

    if not (fileExists(path .. ".txd") and fileExists(path .. ".dff")) then
        printf("Arquivos " .. model .. " não encontrados")
        return
    end

    for _, v in ipairs({ "txd", "dff" }) do
        local file = fileOpen(path .. "." .. v)

        if file then
            local buffer = fileRead(file, fileGetSize(file))
            fileClose(file)

            local newFile = fileCreate(getPathEncrypted(model)[v])

            if newFile then
                local encrypted = encodeString("tea", buffer, { key = get("password") })
                fileWrite(newFile, encrypted)
                fileClose(newFile)

                printf("Arquivo " .. model .. "." .. v .. " criptografado com sucesso")
            else
                printf("Falha ao criar o arquivo " .. model .. "." .. v)
            end
        else
            printf("Falha ao abrir o arquivo " .. model .. "." .. v)
        end
    end
end