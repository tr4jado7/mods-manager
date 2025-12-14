Mods = {}

local STATES = {
    ["not downloaded"] = { "Não Baixado", { 236, 108, 108 } },
    ["downloading"] = { "Baixando", { 236, 176, 108 } },
    ["downloaded"] = { "Baixado", { 236, 176, 108 } },
    ["actived"] = { "Ativado", { 123, 236, 108 } }
}

local CATEGORY_SIZE_VISIBLE = -1

-- Events

function Mods:onStart()
    self.state = false
    self.category = false
    self.hover = false
    self.selected = false
    self.check = true
    self.slot = 0

    self.search = {
        last = false,
        result = {}
    }

    self.modsList = {}
    self.queue = {}

    self.downloaded = {
        total = { view = 0, bytes = 0 },
        current = { view = 0, bytes = 0 }
    }

    self.password = false

    local settings

    if fileExists("settings.json") then
        settings = fileOpen("settings.json")
    else
        settings = fileCreate("settings.json")
    end

    if settings then
        local content = fileRead(settings, fileGetSize(settings))
        fileClose(settings)

        local setting = fromJSON(content) or {}
        self.check = setting.check
    end

    Thread:create(function()
        local mods, password, allow, totalSize = requestRemoteCall("onGetDependencies")

        if not allow then
            return
        end

        self.modsList = mods or {}
        self.password = password
        self.downloaded.total = totalSize or { view = 0, bytes = 0 }

        for model, data in pairs(MODS) do
            local active = false

            for _, ext in ipairs({ "txd", "dff" }) do
                local category = getCategoryPath(model)
                local path = "assets/mods/" .. category .. "/" .. model .. "." .. ext

                if data.Encrypt then
                    path = getPathEncrypted(model)[ext]
                end

                if fileExists(path) then
                    local file = fileOpen(path)

                    if file then
                        self.downloaded.current.bytes = self.downloaded.current.bytes + fileGetSize(file)
                        self.downloaded.current.view = byte2human(self.downloaded.current.bytes)

                        fileClose(file)

                        self.modsList[category][model].state = "downloaded"

                        if self.check then
                            if ext == "txd" then
                                active = true
                            elseif ext == "dff" and active then
                                self:downloadMod(model, true)
                            end
                        end
                    end
                end
            end
        end
    end)

    self.funcs = {
        onFileDownload = function(...) Mods:onFileDownload(...) end,
        onRender = function() Mods:onRender() end,
        onClick = function(...) Mods:onClick(...) end,
        onCommand = function(...) Mods:onCommand(...) end
    }

    self.scroll = {
        mods = Editbox
    }

    self.editbox = {
        search = Editbox
    }

    addEventHandler("onClientFileDownloadComplete", root, self.funcs.onFileDownload)
    addCommandHandler("mods", self.funcs.onCommand)
end

function Mods:onStop()
    local file = fileOpen("settings.json")

    if not file then
        file = fileCreate("settings.json")
    end

    if file then
        local content = toJSON({
            check = self.check
        })

        fileWrite(file, content)
        fileClose(file)
    end
end

function Mods:onFileDownload(file, success, resource)
    if resource ~= getThisResource() or not success then
        return
    end

    local path = file:gsub("assets/mods/", "")
    local splited = split(path, "/")
    local ext = splited[#splited]:match("(%w+)$")
    local mod = splited[#splited]:gsub("%." .. ext, "")

    local model = tonumber(mod)

    if not model then
        model, ext = getModelFromHash(mod)

        if not model then
            return
        end
    end

    local data = self.queue[model]
    local infos = MODS[model]
    local category = getCategoryPath(model)

    if data then
        local raw = file

        if ext == "txd" then
            local archive = fileOpen(file)

            if not archive then
                return
            end

            local size = fileGetSize(archive)

            if data.active then
                if infos.Encrypt then
                    raw = decodeString("tea", fileRead(archive, size), { key = self.password })
                end

                local txd = engineLoadTXD(raw)

                if not txd then
                    return
                end

                engineImportTXD(txd, model)
            else
                self.downloaded.current.bytes = self.downloaded.current.bytes + size
                self.downloaded.current.view = byte2human(self.downloaded.current.bytes)
            end

            fileClose(archive)
        elseif ext == "dff" then
            local archive = fileOpen(file)
            self.modsList[category][model].state = "downloaded"

            if not archive then
                return
            end

            local size = fileGetSize(archive)

            if data.active then
                if infos.Encrypt then
                    raw = decodeString("tea", fileRead(archive, size), { key = self.password })
                else
                    self.downloaded.current.bytes = self.downloaded.current.bytes + size
                    self.downloaded.current.view = byte2human(self.downloaded.current.bytes)
                end

                local dff = engineLoadDFF(raw)

                if not dff then
                    return
                end

                engineReplaceModel(dff, model)
                self.modsList[category][model].state = "actived"
            else
                self.downloaded.current.bytes = self.downloaded.current.bytes + size
                self.downloaded.current.view = byte2human(self.downloaded.current.bytes)
            end

            fileClose(archive)
        end
    end
end

function Mods:onRender()
    updateCursor()
    self.hover = false

    local fade = interpolate("animation", self.state and 1 or 0)

    local width, height = resp(785), resp(550)
    local x, y = (screen.x - width) / 2, (screen.y - (height * fade)) / 2

    if not self.state and fade == 0 then
        self:togglePanel(false)
        return
    end

    dxDrawRectangleRounded(x, y, width, height, rgba(38, 42, 46, 0.6 * fade), 9)
    dxDrawRectangleRounded(x + resp(3), y + resp(3), resp(780), resp(545), rgba(38, 42, 46, 0.92 * fade), 9)

    dxDrawImage(x + resp(24), y + resp(24), resp(16), resp(16), icon["main"], rgba(81, 144, 235, fade))
    dxDrawText("Gerenciador de Mods", x + resp(51), y + resp(25), 0, 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("bold", 12))

    dxDrawRectangleRounded(x + resp(25), y + resp(51), resp(735), resp(2), rgba(255, 255, 255, 0.02 * fade), 1)

    dxDrawText("Teleporte-se para diversos locais através deste painel clique nos botões abaixo", x + resp(25), y + resp(64), resp(287), 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12), "left", "top", false, true)

    do
        local hover = isCursorOver(x + resp(749), y + resp(24), resp(12), resp(12))

        if hover then
            self.hover = { action = "close" }
        end

        dxDrawImage(x + resp(749), y + resp(24), resp(12), resp(12), icon["close"], rgbaf("close", hover and {236, 108, 108} or {255, 255, 255, 0.15}, fade))
    end

    do
        local bgWidth = 491
        local margin = 38

        dxDrawRectangleRounded(x + resp(25), y + resp(106), resp(bgWidth), resp(margin), rgba(255, 255, 255, 0.02 * fade), 5)

        local spacing = 0
        local category_visibles = math.min(#CATEGORYS, 5)

        if CATEGORY_SIZE_VISIBLE == -1 then
            CATEGORY_SIZE_VISIBLE = 0

            for i = 1, category_visibles do
                local v = CATEGORYS[i + self.slot]
                CATEGORY_SIZE_VISIBLE = CATEGORY_SIZE_VISIBLE + dxGetTextWidth(v, getFont("medium", 12)) + (i < category_visibles and resp(margin) or 0)
            end
        end

        local startX = (resp(bgWidth) - CATEGORY_SIZE_VISIBLE) / 2

        for i = 1, category_visibles do
            local index = i + self.slot
            local v = CATEGORYS[index]
            local selected = self.category == getCategoryPath(index)

            local textWidth = dxGetTextWidth(v, getFont("medium", 12))
            local hover = isCursorOver(x + resp(25) + startX + spacing, y + resp(107), textWidth, resp(margin))

            if hover then
                self.hover = { action = "category", index = index }
            end

            if selected then
                local barX = interpolate("category:x", startX + spacing)
                -- local barW = interpolate("category:w", textWidth)
                local barW = textWidth

                dxDrawRectangleRounded(x + resp(25) + barX, y + resp(141), barW, resp(3), rgba(81, 144, 235, fade), 2)
            end

            dxDrawText(v, x + resp(25) + startX + spacing, y + resp(117), 0, 0, rgbaf("category:" .. i, (selected or hover) and {255, 255, 255, 0.85} or {255, 255, 255, 0.25}, fade), 1, getFont("medium", 12))
            spacing = spacing + textWidth + resp(margin)
        end

        for i, v in ipairs({
            {"arrow:l", 32, 0},
            {"arrow:r", 488, 180}
        }) do
            local hover = isCursorOver(x + resp(v[2]), y + resp(115), resp(20), resp(20))

            if hover then
                self.hover = { action = v[1] }
            end

            dxDrawImage(x + resp(v[2]), y + resp(115), resp(20), resp(20), icon["arrow"], rgbaf("arrow:" .. i, hover and {81, 144, 235} or {255, 255, 255, 0.15}, fade), v[3])
        end
    end

    dxDrawRectangleRounded(x + resp(526), y + resp(106), resp(234), resp(38), rgba(255, 255, 255, 0.02 * fade), 5)
    dxDrawImage(x + resp(540), y + resp(118), resp(14), resp(14), icon["search"], rgba(255, 255, 255, 0.15 * fade))

    self.editbox.search:draw("Pesquisar...", x + resp(566), y + resp(118), resp(178), resp(14),  rgbaf("search", self.editbox.search.focus and {255, 255, 255, 0.85} or {255, 255, 255, 0.25}, fade))
    self.editbox.search.box = { x + resp(526), y + resp(106), resp(234), resp(38) }

    dxDrawRectangleRounded(x + resp(25), y + resp(154), resp(491), resp(320), rgba(255, 255, 255, 0.02 * fade), 5)
    self.scroll.mods.box = { x + resp(25), y + resp(154), resp(491), resp(320) }

    dxDrawText("ID", x + resp(41), y + resp(169), 0, 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("medium", 12))
    dxDrawText("Nome", x + resp(100), y + resp(169), 0, 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("medium", 12))
    dxDrawText("Tamanho", x + resp(269), y + resp(169), 0, 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("medium", 12))
    dxDrawText("Status", x + resp(399), y + resp(169), 0, 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("medium", 12))

    local search = self.editbox.search.properties.text
    local empty = search == ""

    if search ~= self.search.last or empty then
        self.search.last = search
        self.search.result = {}

        for _, v in pairs(self.modsList[self.category]) do
            if empty or string.find(v.name:lower(), search:lower()) then
                table.insert(self.search.result, v)
            end
        end

        self.scroll.mods.value = 0
    end

    for i = 1, 7 do
        local index = i + self.scroll.mods.value
        local v = self.search.result[index]

        if v then
            local margin = (i - 1) * 38
            local state = STATES[v.state]
            local selected = self.selected == index
            local hover = isCursorOver(x + resp(25), y + resp(197 + margin), resp(491), resp(38))

            if hover then
                self.hover = { action = "mod", index = i + self.slot }
            end

            dxDrawRectangle(x + resp(25), y + resp(197 + margin), resp(491), resp(38), rgbaf("mods:" .. i, selected and {255, 255, 255, 0.04} or hover and {255, 255, 255, 0.01} or {255, 255, 255, 0}, fade))

            dxDrawText(v.model, x + resp(41), y + resp(209 + margin), 0, 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12))
            dxDrawText(v.name, x + resp(102), y + resp(209 + margin), 0, 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12))
            dxDrawText(v.sizeFormatted, x + resp(279), y + resp(209 + margin), 0, 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12))
            dxDrawText(state[1], x + resp(450), y + resp(209 + margin), 0, 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12), "right")

            dxDrawRectangleRounded(x + resp(463), y + resp(209 + margin), resp(15), resp(15), rgba(255, 255, 255, 0.02 * fade), 15 / 2)
            dxDrawRectangleRounded(x + resp(467), y + resp(213 + margin), resp(7), resp(7), rgba(state[2][1], state[2][2], state[2][3], fade), 7 / 2)
        end
    end

    dxDrawRectangleRounded(x + resp(526), y + resp(154), resp(234), resp(320), rgba(255, 255, 255, 0.02 * fade), 5)
    dxDrawImage(x + resp(540), y + resp(168), resp(14), resp(14), icon["mananger"], rgba(81, 144, 235, fade))
    dxDrawText("Gerenciador de Mods", x + resp(566), y + resp(169), 0, 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("medium", 12))
    dxDrawText("Abaixo temos opções que gerenciam os mods basta clicar no botão", x + resp(566), y + resp(189), resp(191), 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12), "left", "top", false, true)

    for i, v in ipairs({
        { "download:all", "Baixar Tudo" },
        { "active:all", "Ativar Tudo" },
        { "disable:all", "Desativar Tudo" },
        { "delete:all", "Excluir Tudo" }
    }) do
        local margin = (i - 1) * 43
        local hover = isCursorOver(x + resp(540), y + resp(239 + margin), resp(204), resp(38))

        if hover then
            self.hover = { action = v[1] }
        end

        dxDrawRectangleRounded(x + resp(540), y + resp(239 + margin), resp(204), resp(38), rgbaf("list:rect:" .. i, hover and {255, 255, 255, 0.04} or {255, 255, 255, 0.02}, fade), 5)
        dxDrawText(v[2], x + resp(540), y + resp(251 + margin), resp(204), 0, rgbaf("list:text:" .. i, hover and {255, 255, 255, 0.85} or {255, 255, 255, 0.25}, fade), 1, getFont("medium", 12), "center")
    end

    do
        local progress = self.downloaded.current.bytes / self.downloaded.total.bytes * 204

        local rectangle = dxDrawRectangleRounded(x + resp(541), y + resp(421), resp(204), resp(38), rgba(81, 144, 235, 0.25 * fade), 5)
        dxDrawImageSection(x + resp(541), y + resp(421), resp(progress) + 1, resp(38) + 1, 1, 1, resp(progress) + 1, resp(38) + 1, rectangle, rgba(81, 144, 235, fade))
        dxDrawText(self.downloaded.current.view .. "/" .. self.downloaded.total.view, x + resp(541), y + resp(433), resp(204), 0, rgba(255, 255, 255, 0.85 * fade), 1, getFont("bold", 12), "center")
    end

    for i, v in ipairs({
        { "download:selected", "Baixar Selecionado" },
        { "active:selected", "Ativar Selecionado" },
        { "disable:selected", "Desativar Selecionado" }
    }) do
        local margin = (i - 1) * 167
        local hover = isCursorOver(x + resp(25 + margin), y + resp(484), resp(157), resp(38))

        if hover then
            self.hover = { action = v[1], model = self.selected }
        end

        dxDrawRectangleRounded(x + resp(25 + margin), y + resp(484), resp(157), resp(38), rgbaf("option:rect:" .. i, hover and {255, 255, 255, 0.04} or {255, 255, 255, 0.02}, fade), 5)
        dxDrawText(v[2], x + resp(25 + margin), y + resp(496), resp(157), 0, rgbaf("option:text:" .. i, hover and {255, 255, 255, 0.85} or {255, 255, 255, 0.25}, fade), 1, getFont("medium", 12), "center")
    end

    dxDrawRectangleRounded(x + resp(526), y + resp(484), resp(234), resp(38), rgba(255, 255, 255, 0.02 * fade), 5)
    dxDrawRectangleRounded(x + resp(526), y + resp(484), resp(38), resp(38), rgba(255, 255, 255, 0.02 * fade), 5)
    dxDrawText("Ativar mods ao entrar", x + resp(587), y + resp(496), 0, 0, rgba(255, 255, 255, 0.25 * fade), 1, getFont("medium", 12))
    dxDrawImage(x + resp(540), y + resp(499), resp(10), resp(10), icon["check"], rgbaf("check", self.check and {81, 144, 235} or {255, 255, 255, 0.25}, fade))

    if isCursorOver(x + resp(526), y + resp(484), resp(234), resp(38)) then
        self.hover = { action = "check" }
    end
end

function Mods:onClick(button, state)
    if not (button == "left" and state == "down") then
        return
    end

    local hover = self.hover

    if not hover then
        return
    end

    local details = split(self.hover.action, ":")
    local category = getCategoryPath(self.category)
    local mods = self.modsList[category]
    local list = self.search.result

    if details[1] == "download" then
        local model = hover.model

        if details[2] == "all" then
            for _, v in ipairs(list) do
                if v.state == "not downloaded" then
                    self:downloadMod(v.model)
                end
            end
        else
            if model and list[model].state == "not downloaded" then
                self:downloadMod(model)
            end
        end
    elseif details[1] == "active" then
        local model = hover.model

        if details[2] == "all" then
            for _, v in ipairs(list) do
                if v.state == "downloaded" then
                    self:downloadMod(v.model, true)
                end
            end
        else
            if model and mods[model].state == "downloaded" then
                self:downloadMod(model, true)
            end
        end
    elseif details[1] == "disable" then
        local model = hover.model

        if details[2] == "all" then
            for _, v in ipairs(list) do
                if v.state == "actived" then
                    engineRestoreModel(v.model)
                    mods[v.model].state = "downloaded"
                end
            end
        else
            if model and mods[model].state == "actived" then
                engineRestoreModel(model)
                mods[model].state = "downloaded"
            end
        end
    elseif details[1] == "delete" then
        if details[2] == "all" then
            for _, v in ipairs(list) do
                if v.state == "downloaded" then
                    for _, ext in ipairs({ "txd", "dff" }) do
                        local path = "assets/mods/" .. v.category .. "/" .. v.model .. "." .. ext

                        if v.encrypt then
                            path = getPathEncrypted(v.model)[ext]
                        end

                        local file = fileOpen(path)

                        if file then
                            self.downloaded.current.bytes = self.downloaded.current.bytes - fileGetSize(file)
                            self.downloaded.current.view = byte2human(self.downloaded.current.bytes)

                            fileClose(file)
                            fileDelete(path)
                        end
                    end

                    mods[v.model].state = "not downloaded"
                end
            end
        end
    elseif details[1] == "check" then
        self.check = not self.check
    elseif details[1] == "mod" then
        self.selected = hover.index
    elseif details[1] == "close" then
        self.state = false
    elseif details[1] == "arrow" then
        CATEGORY_SIZE_VISIBLE = -1

        if details[2] == "l" then
            if self.slot > 0 then
                self.slot = self.slot - 1
            else
                self.slot = 0
            end
        elseif details[2] == "r" then
            if self.slot < #CATEGORYS - 5 then
                self.slot = self.slot + 1
            else
                self.slot = #CATEGORYS - 5
            end
        end
    elseif details[1] == "category" then
        self:changeCategory(hover.index)
    end
end

function Mods:onCommand(command, ...)
    local args = { ... }

    if command == "mods" then
        if self.state then
            self.state = false
        else
            self:togglePanel(true)
        end
    end
end

-- Functions

function Mods:togglePanel(state)
    if self.state then
        return
    end

    if state then
        if not self.category then
            for i in pairs(self.modsList) do
                self:changeCategory(getCategoryPath(i))
                break
            end
        end

        self.scroll.mods = Scroll.new({ visible = 7 })
        self.editbox.search = Editbox.new({ font = getFont("medium", 12), maxChars = 10 })

        addEventHandler("onClientRender", root, self.funcs.onRender)
        addEventHandler("onClientClick", root, self.funcs.onClick)
    else
        removeEventHandler("onClientRender", root, self.funcs.onRender)
        removeEventHandler("onClientClick", root, self.funcs.onClick)

        self.scroll.mods:destroy()
        self.editbox.search:destroy()
    end

    showCursor(state)
    self.state = state
end

function Mods:changeCategory(category)
    if not category then
        printf("Categoria não encontrada: " .. category)
        return
    end

    if not self.modsList[category] then
        outputNotification("Categoria sem mods: " .. category, "error")
        return
    end

    self.scroll.mods.value = 0
    self.scroll.mods.total = #self.modsList[category]

    self.search.result = self.modsList[category]

    self.category = category
end

function Mods:downloadMod(model, active)
    local data = MODS[model]

    if not data then
        return
    end

    local category = getCategoryPath(model)

    for _, v in ipairs({ "txd", "dff" }) do
        local path = "assets/mods/" .. category .. "/" .. model .. "." .. v

        if data.Encrypt then
            path = getPathEncrypted(model)[v]
        end

        if fileExists(path) and not active then
            fileDelete(path)
        end

        if v == "txd" then
            self.queue[model] = { active = active }

            if not fileExists(path) then
                self.modsList[category][model].state = "downloading"
            end
        end

        downloadFile(path)
    end
end