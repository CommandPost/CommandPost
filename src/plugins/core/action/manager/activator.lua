--- === plugins.core.action.activator ===
---
--- This module provides provides a way of activating choices provided by action handlers.
--- It also provide support for making a particular action a favourite, returning
--- results based on popularity, and completely hiding particular actions, or categories of action.
---
--- Activators are accessed via the [action manager](plugins.core.action.manager.md) like so:
---
--- ```lua
--- local activator = actionManager.getActivator("foobar")
--- activator:disableHandler("videoEffect")
--- activator:show()
--- ```
---
--- Any changes made to the settings of a finder (such as calling `disableHandler` above) will
--- be preserved for future loads of the finder with the same ID. They are also local
--- to instances of this activator, so disabling "videoEffect" in the "foobar" activator
--- will not affect the "yadayada" activator.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                       = require("hs.logger").new("activator")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local chooser                   = require("hs.chooser")
local drawing                   = require("hs.drawing")
local fnutils                   = require("hs.fnutils")
local inspect                   = require("hs.inspect")
local menubar                   = require("hs.menubar")
local mouse                     = require("hs.mouse")
local screen                    = require("hs.screen")
local timer                     = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                    = require("cp.config")
local idle                      = require("cp.idle")
local prop                      = require("cp.prop")
local i18n                      = require("cp.i18n")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                         = require("moses")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local sort, insert              = table.sort, table.insert
local concat                    = fnutils.concat
local format                    = string.format

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PACKAGE -> string
-- Constant
-- The Package ID.
local PACKAGE = "action.activator."

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local activator = {}
activator.mt = {}
activator.mt.__index = activator.mt

-- applyHiddenTo(choice, hidden) -> none
-- Function
-- Hides a choice
--
-- Parameters:
--  * choice - The choice
--  * hidden - A boolean that defines whether or not the choice is hidden
--
-- Returns:
--  * None
local function applyHiddenTo(choice, hidden)
    if choice.oldText then
        choice.text = choice.oldText
    end

    if hidden then
        choice.oldText = choice.text
        choice.text = i18n("actionHiddenText", {text = choice.text})
        choice.hidden = true
    else
        choice.oldText = nil
        choice.hidden = nil
    end
end

-- plugins.core.action.activator.new(id, manager)
-- Constructor
-- Creates a new `activator` instance with the specified ID and action manager
function activator.new(id, manager)

    local prefix = PACKAGE .. id .. "."

    local o = prop.extend({
        _id             = id,
        _manager        = manager,
        _chooser        = nil,      -- the actual hs.chooser
    }, activator.mt)

    --- plugins.core.action.activator.searchSubText <cp.prop: boolean>
    --- Field
    --- If `true`, allow users to search the subtext value.
    o.searchSubText = config.prop(prefix .. "searchSubText", true):bind(o)

    --- plugins.core.action.activator.lastQueryRemembered <cp.prop: boolean>
    --- Field
    --- If `true`, remember the last query.
    o.lastQueryRemembered = config.prop(prefix .. "lastQueryRemembered", true):bind(o)

    --- plugins.core.action.activator.lastQueryValue <cp.prop: string>
    --- Field
    --- The last query value.
    o.lastQueryValue = config.prop(prefix .. "lastQueryValue", ""):bind(o)

    --- plugins.core.action.activator.showHidden <cp.prop: boolean>
    --- Field
    --- If `true`, hidden items are shown.
    o.showHidden = config.prop(prefix .. "showHidden", false):bind(o)
    -- refresh the chooser list if this status changes.
    :watch(function() o:refreshChooser() end)

    -- plugins.core.action.activator._allowedHandlers <cp.prop: string>
    -- Field
    -- The ID of a single handler to source
    o._allowedHandlers = prop.THIS(nil):bind(o)

    --- plugins.core.action.activator:allowedHandlers <cp.prop: table of handlers; read-only>
    --- Field
    --- Contains all handlers that are allowed in this activator.
    o.allowedHandlers = o._manager.handlers:mutate(
        function(original)
            local handlers = original()
            local allowed = {}
            local allowedIds = o:_allowedHandlers()

            for theID,handler in pairs(handlers) do
                if allowedIds == nil or allowedIds[theID] then
                    allowed[theID] = handler
                end
            end

            return allowed
        end
    ):bind(o)

    -- plugins.core.action.activator._disabledHandlers <cp.prop: table of booleans>
    -- Field
    -- Table of disabled handlers. If the ID is present with a value of `true`, it's disabled.
    o._disabledHandlers = config.prop(prefix .. "disabledHandlers", {}):bind(o)
    :watch(function() o:refreshChooser() end)

    --- plugins.core.action.activator.activeHandlers <cp.prop: table of handlers>
    --- Field
    --- Contains the table of active handlers. A handler is active if it is both allowed and enabled.
    --- The handler ID is the key, so use `pairs` to iterate the list. E.g.:
    ---
    --- ```lua
    --- for id,handler in pairs(activator:activeHandlers()) do
    ---     ...
    --- end
    --- ```
    o.activeHandlers = prop(function(self)
        local handlers = self:allowedHandlers()
        local result = {}

        local disabled = self._disabledHandlers()
        for i,handler in pairs(handlers) do
            if not disabled[i] then
                result[i] = handler
            end
        end

        return result
    end):bind(o)
    :monitor(o._disabledHandlers)
    :monitor(manager.handlers)

    --- plugins.core.action.activator.hiddenChoices <cp.prop: table of booleans>
    --- Field
    --- Contains the set of choice IDs which are hidden in this activator, mapped to a boolean value.
    --- If set to `true`, the choice is hidden.
    o.hiddenChoices = config.prop(prefix .. "hiddenChoices", {}):cached():bind(o)

    --- plugins.core.action.activator.favoriteChoices <cp.prop: table of booleans>
    --- Field
    --- Contains the set of choice IDs which are favorites in this activator, mapped to a boolean value.
    --- If set to `true`, the choice is a favorite.
    o.favoriteChoices = config.prop(prefix .. "favoriteChoices", {}):cached():bind(o)
    :watch(function() timer.doAfter(1.0, function() o:sortChoices() end) end)

    --- plugins.core.action.activator.popularChoices <cp.prop: table of integers>
    --- Field
    --- Keeps track of how popular particular choices are. Returns a table of choice IDs
    --- mapped to the number of times they have been activated.
    o.popularChoices = config.prop(prefix .. "popularChoices", {}):cached():bind(o)
    :watch(function() timer.doAfter(1.0, function() o:sortChoices() end) end)

    --- plugins.core.action.activator.configurable <cp.prop: boolean>
    --- Field
    --- If `true` (the default), the activator can be configured by right-clicking on the main chooser.
    o.configurable = config.prop(prefix .. "configurable", true):cached():bind(o)

    return o
end

--- plugins.core.action.activator:preloadChoices([afterSeconds]) -> activator
--- Method
--- Indicates the activator should preload the choices after a number of seconds.
--- Defaults to 0 seconds if no value is provided.
---
--- Parameters:
---  * `afterSeconds`    - The number of seconds to wait before preloading.
---
--- Returns:
---  * The activator.
function activator.mt:preloadChoices(afterSeconds)
    afterSeconds = afterSeconds or 0
    idle.queue(afterSeconds, function()
        self:_findChoices()
    end)
    return self
end

--- plugins.core.action.activator:id() -> string
--- Method
--- Returns the activator's unique ID.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The activator ID.
function activator.mt:id()
    return self._id
end

--- plugins.core.action.activator:getActiveHandler(id) -> handler
--- Method
--- Returns the active handler with the specified ID, or `nil` if not available.
---
--- Parameters:
---  * `id`      - The Handler ID
---
--- Returns:
---  * The action handler, or `nil`.
function activator.mt:getActiveHandler(id)
    return self:activeHandlers()[id]
end

--- plugins.core.action.activator:allowHandlers(...) -> boolean
--- Method
--- Specifies that only the handlers with the specified IDs will be active in
--- this activator. By default all handlers are allowed.
---
--- Parameters:
---  * `...`     - The list of Handler ID strings to allow.
---
--- Returns:
---  * `true` if the handlers were found.
function activator.mt:allowHandlers(...)
    local allowed = {}
    for _,id in ipairs(table.pack(...)) do -- luacheck: ignore
        if self._manager.getHandler(id) then
            allowed[id] = true
        else
            error(string.format("Attempted to make action handler '%s' exclusive, but it could not be found.", id))
        end
    end
    self._allowedHandlers(allowed)
    return self
end

--- plugins.core.action.activator:disableHandler(id) -> boolean
--- Method
--- Disables the handler with the specified ID.
---
--- Parameters:
---  * `id`      - The unique action handler ID.
---
--- Returns:
---  * `true` if the handler exists and was disabled.
function activator.mt:disableHandler(id)
    if self._manager.getHandler(id) == nil then
        return false
    end
    local dh = self:_disabledHandlers()
    dh[id] = true
    self:_disabledHandlers(dh)
    self:refreshChooser()
    return true
end

--- plugins.core.action.activator:enableHandler(id) -> boolean
--- Method
--- Enables the handler with the specified ID.
---
--- Parameters:
---  * `id`      - The unique action handler ID.
---
--- Returns:
---  * `true` if the handler exists and was enabled.
function activator.mt:enableHandler(id)
    if self._manager.getHandler(id) == nil then
        return false
    end
    local dh = self:_disabledHandlers()
    dh[id] = nil
    self:_disabledHandlers(dh)
    self:refreshChooser()
    return true
end

--- plugins.core.action.activator:enableAllHandlers() -> nothing
--- Method
--- Enables the all allowed handlers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function activator.mt:enableAllHandlers()
    self._disabledHandlers:set(nil)
    self:refreshChooser()
end

--- plugins.core.action.activator:disableAllHandlers() -> nothing
--- Method
--- Disables the all allowed handlers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function activator.mt:disableAllHandlers()
    local dh = {}
    for id,_ in pairs(self:allowedHandlers()) do
        dh[id] = true
    end
    self:_disabledHandlers(dh)
    self:refreshChooser()
end

--- plugins.core.action.activator:isDisabledHandler(id) -> boolean
--- Method
--- Returns `true` if the specified handler is disabled.
---
--- Parameters:
---  * `id`          - The handler ID.
---
--- Returns:
---  * `true` if the handler is disabled.
function activator.mt:isDisabledHandler(id)
    local dh = self:_disabledHandlers()
    return dh[id] == true
end

--- plugins.core.action.activator:findChoice(id) -> choice
--- Method
--- Gets a choice
---
--- Parameters:
---  * `id`          - The choice ID.
---
--- Returns:
---  * The choice or `nil` if not found
function activator.mt:findChoice(id)
    for _,choice in ipairs(self:allChoices()) do
        if choice.id == id then
            return choice
        end
    end
    return nil
end

--- plugins.core.action.activator:hideChoice(id) -> boolean
--- Method
--- Hides the choice with the specified ID.
---
--- Parameters:
---  * `id`          - The choice ID to hide.
---
--- Returns:
---  * `true` if successfully hidden otherwise `false`.
function activator.mt:hideChoice(id)
    if id then
        --------------------------------------------------------------------------------
        -- Update the list of hidden choices:
        --------------------------------------------------------------------------------
        local hidden = self:hiddenChoices()
        hidden[id] = true
        self:hiddenChoices(hidden)
        local choice = self:findChoice(id)
        if choice then applyHiddenTo(choice, true) end

        --------------------------------------------------------------------------------
        -- Update the chooser list:
        --------------------------------------------------------------------------------
        self:refreshChooser()
        return true
    end
    return false
end

--- plugins.core.action.activator:unhideChoice(id) -> boolean
--- Method
--- Reveals the choice with the specified ID.
---
--- Parameters:
---  * `id`          - The choice ID to hide.
---
--- Returns:
---  * `true` if successfully unhidden otherwise `false`.
function activator.mt:unhideChoice(id)
    if id then
        local hidden = self:hiddenChoices()
        hidden[id] = nil
        self:hiddenChoices(hidden)
        self:refreshChooser()
        local choice = self:findChoice(id)
        if choice then applyHiddenTo(choice, false) end

        --------------------------------------------------------------------------------
        -- Update the chooser list:
        --------------------------------------------------------------------------------
        self:refreshChooser()
        return true
    end
    return false
end

--- plugins.core.action.activator:isHiddenChoice(id) -> boolean
--- Method
--- Checks if the specified choice is hidden.
---
--- Parameters:
---  * `id`          - The choice ID to check.
---
--- Returns:
---  * `true` if currently hidden otherwise `false`.
function activator.mt:isHiddenChoice(id)
    return self:hiddenChoices()[id] == true
end

--- plugins.core.action.activator:isHiddenChoice(id) -> boolean
--- Method
--- Checks if the specified choice is hidden.
---
--- Parameters:
---  * `id`          - The choice ID to check.
---
--- Returns:
---  * `true` if currently hidden.
function activator.mt:isFavoriteChoice(id)
    local favorites = self:favoriteChoices()
    return id and favorites and favorites[id] == true
end

--- plugins.core.action.activator:favoriteChoice(id) -> boolean
--- Method
--- Marks the choice with the specified ID as a favorite.
---
--- Parameters:
---  * `id`          - The choice ID to favorite.
---
--- Returns:
---  * `true` if successfully favorited otherwise `false`.
function activator.mt:favoriteChoice(id)
    if id then
        local favorites = self:favoriteChoices()
        favorites[id] = true
        self:favoriteChoices(favorites)
        local choice = self:findChoice(id)
        if choice then choice.favorite = true end

        --------------------------------------------------------------------------------
        -- Update the chooser list:
        --------------------------------------------------------------------------------
        self:refreshChooser()
        return true
    end
    return false
end

--- plugins.core.action.activator:unfavoriteChoice(id) -> boolean
--- Method
--- Marks the choice with the specified ID as not a favorite.
---
--- Parameters:
---  * `id`          - The choice ID to unfavorite.
---
--- Returns:
---  * `true` if successfully unfavorited.
function activator.mt:unfavoriteChoice(id)
    if id then
        local favorites = self:favoriteChoices()
        favorites[id] = nil
        self:favoriteChoices(favorites)
        local choice = self:findChoice(id)
        if choice then choice.favorite = nil end
        --------------------------------------------------------------------------------
        -- Update the chooser list:
        --------------------------------------------------------------------------------
        self:refreshChooser()
        return true
    end
    return false
end

--- plugins.core.action.activator:getPopularity(id) -> boolean
--- Method
--- Returns the popularity of the specified choice.
---
--- Parameters:
---  * `id`          - The choice ID to retrieve.
---
--- Returns:
---  * The number of times the choice has been executed.
function activator.mt:getPopularity(id)
    if id then
        local index = self:popularChoices()
        return index[id] or 0
    end
    return 0
end

--- plugins.core.action.activator:incPopularity(choice, id) -> boolean
--- Method
--- Increases the popularity of the specified choice.
---
--- Parameters:
---  * `choice`      - The choice.
---  * `id`          - The choice ID to popularise.
---
--- Returns:
---  * `true` if successfully unfavourited, otherwise `false`.
function activator.mt:incPopularity(choice, id)
    if id then
        local index = self:popularChoices()
        local pop = (index[id] or 0) + 1
        index[id] = pop
        choice.popularity = pop
        self:popularChoices(index)
        local newChoice = self:findChoice(id)
        if newChoice then newChoice.popularity = pop end

        --------------------------------------------------------------------------------
        -- Update the chooser list:
        --------------------------------------------------------------------------------
        self:refreshChooser()
    end
end

--- plugins.core.action.activator:sortChoices() -> boolean
--- Method
--- Sorts the current set of choices in the activator. It takes into account
--- whether it's a favorite (first priority) and its overall popularity.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the action executed successfully, otherwise `false`.
function activator.mt:sortChoices()
    if self._choices then
        return sort(self._choices, function(a, b)
            --------------------------------------------------------------------------------
            -- Favorites get first priority:
            --------------------------------------------------------------------------------
            local afav = a.favorite
            local bfav = b.favorite
            if afav and not bfav then
                return true
            elseif bfav and not afav then
                return false
            end

            --------------------------------------------------------------------------------
            -- Then popularity, if specified:
            --------------------------------------------------------------------------------
            local apop = a.popularity or 0
            local bpop = b.popularity or 0
            if apop > bpop then
                return true
            elseif bpop > apop then
                return false
            end

            --------------------------------------------------------------------------------
            -- Then text by alphabetical order:
            --------------------------------------------------------------------------------
            if a.text < b.text then
                return true
            elseif b.text < a.text then
                return false
            end

            --------------------------------------------------------------------------------
            -- Then subText by alphabetical order:
            --------------------------------------------------------------------------------
            local asub = a.subText or ""
            local bsub = b.subText or ""
            return asub < bsub
        end)
    end
end

--- plugins.core.action.activator:allChoices() -> table
--- Method
--- Returns a table of all available choices, even if hidden. Choices from
--- disabled action handlers are not included.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of choices that can be displayed by an `hs.chooser`.
function activator.mt:allChoices()
    if not self._choices then
        self:_findChoices()
    end
    return self._choices
end

--- plugins.core.action.activator:unhiddenChoices() -> table
--- Method
--- Returns a table with visible choices.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of choices that can be displayed by an `hs.chooser`.
function activator.mt:unhiddenChoices()
    return _.filter(self:allChoices(), function(_,choice) return not choice.hidden end)
end

--- plugins.core.action.activator:activeChoices() -> table
--- Method
--- Returns a table with active choices. If [showHidden](#showHidden) is set to `true`  hidden
--- items are returned, otherwise they are not.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of choices that can be displayed by an `hs.chooser`.
function activator.mt:activeChoices()
    local showHidden = self:showHidden()
    local disabledHandlers = self:_disabledHandlers()

    return _.filter(self:allChoices(), function(_,choice) return (not choice.hidden or showHidden) and not disabledHandlers[choice.type] end)
end

-- plugins.core.action.activator:_findChoices() -> nothing
-- Method
-- Finds and sorts all choices from enabled handlers. They are available via
-- the [choices](#choices) or [allChoices](#allChoices) properties.
function activator.mt:_findChoices()
    --------------------------------------------------------------------------------
    -- Check if we are already watching the handlers:
    --------------------------------------------------------------------------------
    local unwatched = not self._watched
    self._watched = true

    local result = {}
    for _,handler in pairs(self:allowedHandlers()) do
        local choices = handler:choices()
        if choices then
            concat(result, choices:getChoices())
        end
        --------------------------------------------------------------------------------
        -- Check if we should watch the handler choices:
        --------------------------------------------------------------------------------
        if unwatched then
            handler.choices:watch(function() self:refresh() end)
        end
    end

    local popularity = self:popularChoices()
    local favorites = self:favoriteChoices()
    local hidden = self:hiddenChoices()
    for _,choice in ipairs(result) do
        local id = choice.id
        applyHiddenTo(choice, hidden[id])
        choice.popularity = popularity[id] or 0
        choice.favorite = favorites[id] == true
    end
    self._choices = result
    self:sortChoices()
end

--- plugins.core.action.activator:refresh()
--- Method
--- Clears the existing set of choices and requests new ones from enabled action handlers.
function activator.mt:refresh()
    self._choices = nil
end

--- plugins.core.action.activator.reducedTransparency <cp.prop: boolean>
--- Field
--- A property which will be true if the 'reduce transparency' mode is enabled.
activator.reducedTransparency = prop.new(function()
    return screen.accessibilitySettings()["ReduceTransparency"]
end)

-- initChooser(executeFn, rightClickFn, choicesFn, searchSubText) -> `hs.chooser` object
-- Method
-- Gets a hs.chooser
--
-- Parameters:
--  * executeFn - A function that will be called when the chooser is dismissed. It should accept one parameter, which will be nil if the user dismissed the chooser window, otherwise it will be a table containing whatever information you supplied for the item the user chose.
--  * rightClickFn - A function that will be called whenever the user right clicks on a choice. If this parameter is omitted, the existing callback will be removed.
--  * choicesFn - A function to call when the list of choices is needed.
--
-- Returns:
--  * A `hs.chooser` object
local function initChooser(executeFn, rightClickFn, choicesFn, searchSubText)

    local c = chooser.new(executeFn)
        :bgDark(true)
        :rightClickCallback(rightClickFn)
        :choices(choicesFn)
        :searchSubText(searchSubText)
        :refreshChoicesCallback()

    if activator.reducedTransparency() then
        c:fgColor(nil)
         :subTextColor(nil)
    else
        c:fgColor(drawing.color.x11.snow)
         :subTextColor(drawing.color.x11.snow)
    end

    return c
end

--- plugins.core.action.activator:refreshChooser() -> `hs.chooser` object
--- Method
--- Gets a hs.chooser
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.chooser` object
function activator.mt:chooser()

    --------------------------------------------------------------------------------
    -- Reload Console if Reduce Transparency has been toggled:
    --------------------------------------------------------------------------------
    local transparency = activator.reducedTransparency()
    if self._lastReducedTransparency ~= transparency then
        self._lastReducedTransparency = transparency
        self._chooser = nil
    end

    --------------------------------------------------------------------------------
    -- Create new Chooser if needed:
    --------------------------------------------------------------------------------
    if not self._chooser then
        self._chooser = initChooser(
            function(result) self:activate(result) end,
            function(index) self:rightClickMain(index) end,
            function() return self:activeChoices() end,
            self:searchSubText()
        )
    end
    return self._chooser
end

--- plugins.core.action.activator:refreshChooser()
--- Method
--- Refreshes a Chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator.mt:refreshChooser()
    local theChooser = self:chooser()
    if theChooser then
        theChooser:refreshChoicesCallback()
    end
end

--- plugins.core.action.activator:show()
--- Method
--- Shows a chooser listing the available actions. When selected by the user,
--- the [onActivate](#onActivate) function is called.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator.mt:show()
    local theChooser = self:chooser()
    if theChooser and theChooser:isVisible() then
        return
    end

    --------------------------------------------------------------------------------
    -- Refresh Chooser:
    --------------------------------------------------------------------------------
    self:refreshChooser()

    --------------------------------------------------------------------------------
    -- Remember last query?
    --------------------------------------------------------------------------------
    local chooserRememberLast = self:lastQueryRemembered()
    if not chooserRememberLast then
        theChooser:query("")
    else
        theChooser:query(self:lastQueryValue())
    end

    --------------------------------------------------------------------------------
    -- Show Console:
    --------------------------------------------------------------------------------
    theChooser:searchSubText(self:searchSubText())
    theChooser:show()

    return true
end

--- plugins.core.action.activator:hide()
--- Method
--- Hides a chooser listing the available actions.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator.mt:hide()
    local theChooser = self:chooser()
    if theChooser then

        --------------------------------------------------------------------------------
        -- Save Last Query to Settings:
        --------------------------------------------------------------------------------
        if self:lastQueryRemembered() then
            self.lastQueryValue:set(theChooser:query())
        end

        --------------------------------------------------------------------------------
        -- Hide Chooser:
        --------------------------------------------------------------------------------
        theChooser:hide()

    end
end

--- plugins.core.action.activator:onActivate(activateFn) -> activator
--- Method
--- Registers the provided function to handle 'activate' actions, when the user selects
--- an item in the main chooser.
---
--- By default, the activator will 'execute' the action, but you can choose to provide an
--- alternative action. It will get passed the `handler` object and the `action` table. Eg:
---
--- ```lua
--- activator:onActivate(function(handler, action))
--- ```
---
--- Parameters:
---  * `activateFn`      - The function to call when an item is activated.
---
--- Returns:
---  * The activator.
function activator.mt:onActivate(activateFn)
    self._onActivate = activateFn
    return self
end

-- plugins.core.action.activator:_onActivate(handler, action, text) -> boolean
-- Function
-- Executes an action.
--
-- Parameters:
--  * `handler` - The Handler that will process the action.
--  * `action` - The action table you want to execute.
--  * `text` - The text string of the action
--
-- Returns:
--  * `true` is successful otherwise `false`
function activator.mt._onActivate(handler, action, text)
    if handler:execute(action) then
        return true
    else
        log.wf("Action '%s' handled by '%s' could not execute: %s", text, inspect(handler), inspect(action))
    end
    return false
end

--- plugins.core.action.activator:activate(result) -> none
--- Method
--- Triggered when the chooser is closed.
---
--- Parameters:
---  * `result`      - The result from the chooser.
---
--- Returns:
---  * None
function activator.mt:activate(result)
    self:hide()
    --------------------------------------------------------------------------------
    -- If something was selected:
    --------------------------------------------------------------------------------
    if result then
        local handlerId, action, text = result.type, result.params, result.text
        local handler = self:getActiveHandler(handlerId)
        if handler and action then
            self._onActivate(handler, action, text)
            local actionId = handler:actionId(action)
            if actionId then
                self:incPopularity(result, actionId)
            end
        else
            error(format("No action handler with an ID of %s is registered.", inspect(handlerId)))
        end
    end
end

--- plugins.core.action.activator:rightClickMain(index) -> none
--- Method
--- Triggered when a user right clicks on a chooser.
---
--- Parameters:
---  * `index`      - The row the right click occurred in or 0 if there is currently no selectable row where the right click occurred.
---
--- Returns:
---  * None
function activator.mt:rightClickMain(index)
    self:rightClickAction(index, true)
end

--- plugins.core.action.activator:rightClickAction(index) -> none
--- Method
--- Triggered when a user right clicks on a chooser.
---
--- Parameters:
---  * `index`      - The row the right click occurred in or 0 if there is currently no selectable row where the right click occurred.
---
--- Returns:
---  * None
function activator.mt:rightClickAction(index)

    local theChooser = self:chooser()

    --------------------------------------------------------------------------------
    -- Settings:
    --------------------------------------------------------------------------------
    local choice = theChooser:selectedRowContents(index)

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    self._rightClickMenubar = menubar.new()

    local choiceMenu = {}

    if choice and choice.id then
        local isFavorite = self:isFavoriteChoice(choice.id)

        insert( choiceMenu, { title = string.upper(i18n("highlightedItem")) .. ":", disabled = true } )
        if isFavorite then
            insert(
                choiceMenu,
                {
                    title = i18n("activatorUnfavoriteAction"),
                    fn = function() self:unfavoriteChoice(choice.id) end,
                }
            )
        else
            insert(
                choiceMenu,
                {
                    title = i18n("activatorFavoriteAction"),
                    fn = function() self:favoriteChoice(choice.id) end,
                }
            )
        end

        local isHidden = self:isHiddenChoice(choice.id)
        if isHidden then
            insert(
                choiceMenu,
                {
                    title = i18n("activatorUnhideAction"),
                    fn = function() self:unhideChoice(choice.id) end,
                }
            )
        else
            insert(
                choiceMenu,
                {
                    title = i18n("activatorHideAction"),
                    fn = function() self:hideChoice(choice.id) end
                }
            )
        end
    end

    if self:configurable() then
        --------------------------------------------------------------------------------
        -- Separator:
        --------------------------------------------------------------------------------
        insert(choiceMenu, { title = "-" })
        insert(choiceMenu, { title = i18n("rememberLastQuery"),     fn=function() self.lastQueryRemembered:toggle() end, checked = self:lastQueryRemembered() })
        insert(choiceMenu, { title = i18n("searchSubtext"),         fn=function() self.searchSubText:toggle() end, checked = self:searchSubText() })
        insert(choiceMenu, { title = i18n("activatorShowHidden"),   fn=function() self.showHidden:toggle() end, checked = self:showHidden() })

        --------------------------------------------------------------------------------
        -- The 'Sections' menu:
        --------------------------------------------------------------------------------
        local sections = { title = i18n("consoleSections") }
        local actionItems = {}
        local allEnabled = true
        local allDisabled = true

        for id,_ in pairs(self:allowedHandlers()) do
            local enabled = not self:isDisabledHandler(id)
            allEnabled = allEnabled and enabled
            allDisabled = allDisabled and not enabled
            actionItems[#actionItems + 1] = {
                title = i18n(format("%s_action", id)) or id,
                fn=function()
                    if enabled then
                        self:disableHandler(id)
                    else
                        self:enableHandler(id)
                    end
                end,
                checked = enabled,
            }
        end

        sort(actionItems, function(a, b) return a.title < b.title end)

        local allItems = {
            { title = i18n("consoleSectionsShowAll"), fn = function()
                self:enableAllHandlers()
            end, disabled = allEnabled },
            { title = i18n("consoleSectionsHideAll"), fn = function()
                self:disableAllHandlers()
            end, disabled = allDisabled },
            { title = "-" }
        }
        fnutils.concat(allItems, actionItems)

        sections.menu = allItems

        insert(choiceMenu, sections)
    end

    self._rightClickMenubar:setMenu(choiceMenu):removeFromMenuBar()
    self._rightClickMenubar:popupMenu(mouse.getAbsolutePosition(), true)
end

return activator
