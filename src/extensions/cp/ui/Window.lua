--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Window ===
---
--- A Window UI element.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                         = require("hs.logger").new("button")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local hswindow                      = require("hs.window")
local hswindowfilter                = require("hs.window.filter")
--local inspect                     = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local prop                          = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Window = {}

hswindowfilter.setLogLevel("nothing") -- The wfilter errors are too annoying.
local filter = hswindowfilter.new()

-- _watch(event, window, ...)
-- Private Function
-- Adds a window.filter that will update the provided property if the window matches.
--
-- Parameter:
--  * `event`       - The event to watch for (eg `hs.window.filter.windowCreated`)
--  * `window`      - The `Window` instance
--  * `property`    - The set of `hs.param` values to update.
local function _watch(event, window, property)
    assert(event ~= nil)
    assert(window ~= nil, event)
    assert(property ~= nil, event)
    filter:subscribe(event, function(hsWindow)
        if window:id() == hsWindow:id() then
            property:update()
        end
    end, true)
end

--- cp.ui.Window.matches(element) -> boolean
--- Function
--- Checks if the provided element is a valid window.
function Window.matches(element)
    return element and element:attributeValue("AXRole") == "AXWindow"
end

--- cp.ui.Window.new(uiProp) -> Window
--- Constructor
--- Creates a new Window
---
--- Parameters:
---  * `uiProp`   - a `cp.prop` that returns the `hs._asm.axuielement` for the window.
---
--- Returns:
---  * A new `Window` instance.
function Window.new(uiProp)

    assert(prop.is(uiProp), "Please provide a finder function.")
    local o = prop.extend({UI = uiProp}, Window)

--- cp.ui.Window.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
    local hsWindow = o.UI:mutate(
        function(original)
            local ui = original()
            return ui and ui:asHSWindow()
        end
    )

--- cp.ui.Window.id <cp.prop: number; read-only>
--- Field
--- The unique ID for the window.
    local id = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:id()
        end
    )

--- cp.ui.Window.visible <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window is visible on a screen.
    local visible = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:isVisible()
        end
    ):bind(Window)

--- cp.ui.Window.focused <cp.prop: boolean>
--- Field
--- Is `true` if the window has mouse/keyboard focused.
--- Note: Setting to `false` has no effect, since 'defocusing' isn't definable.
    local focused = hsWindow:mutate(
        function(original)
            return original() == hswindow.focusedWindow()
        end,
        function(focused, original)
            local window = original()
            if window and focused then
                window:focus()
            end
        end
    )

--- cp.ui.Window.exists <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window exists. It may not be visible.
    local exists = o.UI:mutate(
        function(ui)
            return ui ~= nil
        end
    )

--- cp.ui.Window.minimized <cp.prop: boolean>
--- Field
--- Returns `true` if the window exists and is minimised.
    local minimized = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:isMinimized()
        end,
        function(minimized, original)
            local window = original()
            if window then
                if minimized then
                    window:minimize()
                else
                    window:unminimize()
                end
            end
        end
    )

--- cp.ui.Window.frame <cp.prop: hs.geometry rect>
--- Field
--- The `hs.geometry` rect value describing the window's position.
    local frame = hsWindow:mutate(
        function(original)
            local window = original()
            return window and window:frame()
        end,
        function(frame, original)
            local window = original()
            if window then
                window:move(frame)
            end
            return window
        end
    )

--- cp.ui.Window.fullScreen <cp.prop: boolean>
--- Field
--- Returns `true` if the window is full-screen.
    local fullScreen = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:isFullScreen()
        end,
        function(window, fullScreen)
            if window then
                window:setFullScreen(fullScreen)
            end
            return window
        end
    )

    prop.bind(o) {
        hsWindow = hsWindow,
        id = id,
        visible = visible,
        focused = focused,
        exists = exists,
        minimized = minimized,
        frame = frame,
        fullScreen = fullScreen,
    }

    -- Window Visible:
    _watch(hswindowfilter.windowVisible, o, o.visible)

    -- Window Not Visisble:
    _watch(hswindowfilter.windowNotVisible, o, o.visible)

    -- Window Created:
    _watch(hswindowfilter.windowCreated, o, o.UI)

    -- Window Destroyed:
    _watch(hswindowfilter.windowDestroyed, o, o.UI)

    -- Window Moved:
    _watch(hswindowfilter.windowMoved, o, o.frame)

    -- Window Focused:
    _watch(hswindowfilter.windowFocused, o, o.focused)

    -- Window Full-Screened:
    _watch(hswindowfilter.windowFullscreened, o, o.fullScreen)

    -- Window is un-Full-Screened:
    _watch(hswindowfilter.windowUnfullscreened, o, o.fullScreen)

    return o
end

--- cp.ui.Window.close() -> boolean
--- Method
--- Attempts to close the window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the window was successfully closed.
function Window:close()
    local hsWindow = self:hsWindow()
    return hsWindow ~= nil and hsWindow:close()
end

--- cp.ui.Window.focus() -> boolean
--- Method
--- Attempts to focus the window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the window was successfully focused.
function Window:focus()
    local hsWindow = self:hsWindow()
    return hsWindow ~= nil and hsWindow:focus()
end

--- cp.ui.Window:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function Window:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return Window
