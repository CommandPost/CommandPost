local guitk      = require("hs._asm.guitk")
local styledtext = require("hs.styledtext")
local eventtap   = require("hs.eventtap")

local module = {}

local previousValue
local editFn = function(textObj, msg, ...)
    local args = table.pack(...)
    local defaultReturn = args[#args]

    if msg == "keyPress" then
        local key  = args[1]
        local mods = eventtap.checkKeyboardModifiers()

        if key == "return" then
            if not next(mods) then -- is the table empty?
                eventtap.keyStroke({}, "tab")
                return true
            elseif mods.shift and not mods.cmd and not mods.alt and not mods.ctrl and not mods.capslock and not mods.fn then
                eventtap.keyStroke({ "shift" }, "tab")
                return true
            end
        elseif key == "escape" and not next(mods) then
            if previousValue then
                textObj:value(previousValue)
                textObj:selectAll()
                return true -- technically not necessary for escape, but if that ever changes, this tells the invoking function that we took care of the escape key and it shouldn't
            end
        end
    elseif msg == "shouldBeginEditing" and defaultReturn then
        previousValue = textObj:value()
    elseif msg == "shouldEndEditing"   and defaultReturn then
        previousValue = nil
    end
    -- return the default return value since we didn't return sooner
    return defaultReturn
end

local gui = guitk.new{x = 100, y = 100, h = 300, w = 300 }:show()
local manager = guitk.manager.new()
gui:contentManager(manager)

manager:insert(guitk.element.textfield.newLabel("I am a label, not selectable"):tooltip("newLabel"))
manager:insert(guitk.element.textfield.newLabel(styledtext.new({
    "I am a StyledText selectable label",
    { starts = 8,  ends = 13, attributes = { color = { red  = 1 }, font = { name = "Helvetica-Bold", size = 12 } } },
    { starts = 14, ends = 17, attributes = { color = { blue = 1 }, font = { name = "Helvetica-Oblique", size = 12 } } },
    { starts = 19, ends = 28, attributes = { strikethroughStyle = styledtext.lineAppliesTo.word | styledtext.lineStyles.single } },
})):tooltip("newLabel with styledtext"))
manager:insert(guitk.element.textfield.newTextField("I am a text field"):tooltip("newTextField"):editingCallback(editFn), { w = 200 })
manager:insert(guitk.element.textfield.newWrappingLabel("I am a wrapping label\nthe only difference so far is that I'm selectable"):tooltip("newWrappingLabel -- still trying to figure out what that means"))

-- testing tab/shift-tab works; note if you're testing this before I create formal releases, this required a change to
-- the root module (hs._asm.guitk) as well, so you'll need to recompile that too.
manager:insert(guitk.element.textfield.newTextField("Another one!"):tooltip("added for tabbing"):editingCallback(editFn), { w = 200 })
manager:insert(guitk.element.textfield.newTextField("Another two!"):tooltip("and shift-tabbing"):editingCallback(editFn), { w = 200 })

module.manager = manager

return module
