local require = require
local prop              = require("cp.prop")
local axutils           = require("cp.ui.axutils")
local strings           = require("cp.apple.finalcutpro.strings")

local Button            = require("cp.ui.Button")

local If                = require("cp.rx.go").If

local Panel = {}
Panel.mt = {}
Panel.mt.__index = Panel.mt

function Panel.is(thing)
    return type(thing) == "table" and (thing == Panel.mt or Panel.is(getmetatable(thing)))
end

function Panel.new(parent, titleKey, subclass)
    if subclass and not Panel.is(subclass) then
        error("Parameter #3 must be a Panel subclass")
    end
    local o = prop.extend({
        _parent = parent,
        _toolbar = parent.toolbar,
        _titleKey = titleKey,
    }, subclass or Panel)

    local buttonUI = parent.toolbar.UI:mutate(function(original)
        local ui = original()
        return ui and axutils.childWith(ui, "AXTitle", o:title())
    end)

    local isShowing = parent.toolbar.selectedTitle:mutate(function(original)
        return original() == o:title()
    end)

    prop.bind(o) {
        UI = buttonUI,
        buttonUI = buttonUI,

        isShowing = isShowing,

        contentsUI = prop.OR(isShowing:AND(parent.groupUI), prop.NIL),
    }

    o.button = Button.new(o, buttonUI)

    return o
end

function Panel.mt:parent()
    return self._parent
end

function Panel.mt:app()
    return self._app
end

function Panel.mt:toolbar()
    return self._toolbar
end

function Panel.mt:title()
    return strings:find(self._titleKey)
end

function Panel.mt:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:parent():doShow())
    :Then(self.button:doPress())
end

function Panel.mt:doHide()
    return If(self.isShowing)
    :Then(self:parent():doHide())
end

return Panel
