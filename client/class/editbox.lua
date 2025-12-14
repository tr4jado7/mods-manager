Editbox = {}
Editbox.__index = Editbox

local list_properties = {
    font = "userdata",
    align = "string",
    wordBreak = "boolean",
    mask = "boolean",
    maskChar = "string",
    isNumber = "boolean",
    maxChars = "number",
    caret = "boolean",
    box = "table",
    text = "string"
}

function Editbox.new(properties)
    local self = setmetatable({}, {__index = Editbox})

    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0

    self.selected = false
    self.focus = false

    self.backspace = {
        press = false,
        last = 0
    }

    self.properties = {
        font = "default-bold",
        align = "left",
        maxChars = 9999,
        caret = true,
        parent = {-1, -1, 0, 0},
        text = ""
    }

    self.funcs = {
        onCharacter = function(...) self:onCharacter(...) end,
        onKey = function(...) self:onKey(...) end,
        onPaste = function(...) self:onPaste(...) end,
        onClick = function(...) self:onClick(...) end
    }

    if properties then
        for i, v in pairs(properties) do
            self.properties[i] = v
        end
    end

    addEventHandler("onClientCharacter", root, self.funcs.onCharacter)
    addEventHandler("onClientKey", root, self.funcs.onKey)
    addEventHandler("onClientPaste", root, self.funcs.onPaste)
    addEventHandler("onClientClick", root, self.funcs.onClick)

    return self
end

function Editbox:destroy()
    removeEventHandler("onClientCharacter", root, self.funcs.onCharacter)
    removeEventHandler("onClientKey", root, self.funcs.onKey)
    removeEventHandler("onClientPaste", root, self.funcs.onPaste)
    removeEventHandler("onClientClick", root, self.funcs.onClick)

    setmetatable(self, nil)
    self = nil
end

function Editbox:draw(display, x, y, width, height, color)
    local properties = self.properties
    local backspace = self.backspace

    local font = properties.font
    local align = properties.align
    local wordBreak = properties.wordBreak

    local tick = getTickCount()

    if backspace.press then
        if tick - backspace.press >= 500 and tick - backspace.last >= 50 then
            self.properties.text = sub(properties.text, 1, #properties.text - 1)
            self.backspace.last = tick
        end
    end

    local text = properties.mask and rep(properties.maskChar, #properties.text) or properties.text
    local textW, textH = dxGetTextSize(text, width, 1, 1, font, wordBreak)

    dxDrawText(
        (len(properties.text) > 0 or Editbox.focus == self) and format("%s%s", text, (wordBreak and properties.caret) and "|" or "") or display,
        x, y, width, height,
        color, 1, font,
        wordBreak and align or (textW > width and "right" or align),
        wordBreak and (textH > height and "bottom" or "top") or "top",
        true, wordBreak
    )

    if self.focus then
        if properties.caret and not wordBreak then
            local caretX = x

            if align == "center" then
                caretX = x + (width + textW) / 2
            elseif align == "right" then
                caretX = x + width - 2
            elseif align == "left" then
                caretX = x + textW
            end

            caretX = min(caretX, x + width)

            local r, g, b = bitExtract(color, 0, 8), bitExtract(color, 8, 8), bitExtract(color, 16, 8)
            dxDrawRectangle(caretX, y, 1, height, tocolor(r, g, b, abs(sin(tick / 255) * 200)))
        end

        if self.selected then
            local rectX, rectY = x, y

            if align == "center" and textW <= width then
                rectX, rectY = x + ((width - textW) / 2), y + ((height - textH) / 2)
            end

            dxDrawRectangle(rectX, rectY, min(width, textW), height, tocolor(29, 161, 242, 50))
        end
    else
        self.selected = false
    end
end

-- Events

function Editbox:onCharacter(char)
    if not self.focus or (self.properties.isNumber and not tonumber(char)) then
        return
    end

    if self.selected then
        self.properties.text = char
        self.selected = false
    else
        if len(self.properties.text) >= self.properties.maxChars then
            return
        end

        self.properties.text = self.properties.text .. char
    end
end

function Editbox:onKey(key, state)
    if not self.focus then
        return
    end

    local ctrl = getKeyState("lctrl")

    if key == "backspace" then
        if state then
            if self.selected then
                self.properties.text = ""
                self.selected = false
            else
                self.properties.text = sub(self.properties.text, 1, len(self.properties.text) - 1)

                self.backspace.press = getTickCount()
                self.backspace.last = getTickCount()
            end
        else
            self.backspace.press = false
        end
    else
        if ctrl then
            if key == "a" then
                self.selected = true
            elseif key == "c" then
                if self.selected then
                    setClipboard(self.properties.text)
                end
            elseif key == "x" then
                if self.selected then
                    setClipboard(self.properties.text)
                    self.properties.text = ""
                    self.selected = false
                end
            end
        end
    end

    if not (ctrl and key == "v") then
        cancelEvent()
    end
end

function Editbox:onPaste(text)
    if not self.focus then
        return
    end

    if self.selected then
        self.properties.text = text
        self.selected = false
    else
        if len(self.properties.text .. text) > self.properties.maxChars then
            return
        end

        self.properties.text = self.properties.text .. text
    end
end

function Editbox:onClick(button, state)
    if not (button == "left" and state == "down") then
        return
    end

    if isCursorOver(unpack(self.box)) then
        self.focus = not self.focus
    else
        self.focus = false
    end
end