Scroll = {}
Scroll.__index = Scroll

function Scroll.new(properties)
    local instance = setmetatable({}, {__index = Scroll})

    instance.box = false

    instance.value = 0
    instance.visible = 0
    instance.total = 0

    instance.dragging = false
    instance.mouse = false

    instance.funcs = {
        onKey = function(...) instance:onKey(...) end
    }

    if properties then
        for i, v in pairs(properties) do
            instance[i] = v
        end
    end

    addEventHandler("onClientKey", root, instance.funcs.onKey)

    return instance
end

function Scroll:draw(x, y, width, height, backgroundColor, foregroundColor)
    if self.total <= self.visible then
        return
    end

    local foregroundHeight = (height / self.total) * self.visible

    if self.dragging then
        self.value = floor(
            reMap(clamp(cursor.y - self.dragging, y, y + height - foregroundHeight), y, y + height - foregroundHeight, 0, 1) * (self.total - self.visible)
        )
    end

    local foregroundY = reMap(self.value, 0, self.total - self.visible, y, y + height - foregroundHeight)

    if getKeyState("mouse1") then
        if isCursorOver(x, foregroundY, width, foregroundHeight) and not self.mouse then
            self.mouse = true
            self.dragging = cursor.y - foregroundY
        end
    else
        self.dragging = false
        self.mouse = false
    end

    dxDrawRectangleRounded(x, y, width, height, backgroundColor, width / 2)
    dxDrawRectangleRounded(x, foregroundY or foregroundY, width, foregroundHeight, foregroundColor, width / 2)
end

function Scroll:destroy()
    removeEventHandler("onClientKey", root, self.funcs.onKey)
    setmetatable(self, nil)
    self = nil
end

function Scroll:onKey(key)
    if key == "mouse_wheel_up" or key == "mouse_wheel_down" then
        if not self.box or isCursorOver(unpack(self.box)) then
            if self.total <= self.visible then
                return
            end

            if key == "mouse_wheel_down" then
                self.value = min(self.value + 1, self.total - self.visible)
            else
                self.value = max(self.value - 1, 0)
            end
        end
    end
end