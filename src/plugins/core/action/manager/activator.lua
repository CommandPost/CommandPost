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

local require                   = require

local log                       = require "hs.logger".new "activator"

local chooser                   = require "hs.chooser"
local drawing                   = require "hs.drawing"
local eventtap                  = require "hs.eventtap"
local fnutils                   = require "hs.fnutils"
local host                      = require "hs.host"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"
local screen                    = require "hs.screen"
local timer                     = require "hs.timer"
local toolbar                   = require "hs.webview.toolbar"

local config                    = require "cp.config"
local Do                        = require "cp.rx.go.Do"
local Given                     = require "cp.rx.go.Given"
local Observable                = require "cp.rx" .Observable
local i18n                      = require "cp.i18n"
local idle                      = require "cp.idle"
local prop                      = require "cp.prop"
local tools                     = require "cp.tools"

local moses                     = require "moses"
local class                     = require "middleclass"
local lazy                      = require "cp.lazy"

local concat                    = fnutils.concat
local doAfter                   = timer.doAfter
local format                    = string.format
local imageFromPath             = image.imageFromPath
local insert                    = table.insert
local pack                      = table.pack
local sort                      = table.sort
local spairs                    = tools.spairs
local split                     = tools.split
local uuid                      = host.uuid

local activator = class("core.action.activator"):include(lazy)

-- PACKAGE -> string
-- Constant
-- The Package ID.
local PACKAGE = "action.activator."

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
function activator:initialize(id, manager)
    self._id = id
    self._manager = manager
    self._chooser = nil
    self._prefix = PACKAGE .. id .. "."
end

--- plugins.core.action.activator.searchSubText <cp.prop: boolean>
--- Field
--- If `true`, allow users to search the subtext value.
function activator.lazy.prop:searchSubText()
    return config.prop(self._prefix .. "searchSubText", true)
end

--- plugins.core.action.activator.lastQueryRemembered <cp.prop: boolean>
--- Field
--- If `true`, remember the last query.
function activator.lazy.prop:lastQueryRemembered()
    return config.prop(self._prefix .. "lastQueryRemembered", true)
end

--- plugins.core.action.activator.lastQueryValue <cp.prop: string>
--- Field
--- The last query value.
function activator.lazy.prop:lastQueryValue()
    return config.prop(self._prefix .. "lastQueryValue", "")
end

--- plugins.core.action.activator.showHidden <cp.prop: boolean>
--- Field
--- If `true`, hidden items are shown.
function activator.lazy.prop:showHidden()
    return config.prop(self._prefix .. "showHidden", false)
    -- refresh the chooser list if this status changes.
    :watch(function() self:refreshChooser() end)
end

-- plugins.core.action.activator._allowedHandlers <cp.prop: string>
-- Field
-- The ID of a single handler to source
function activator.lazy.prop._allowedHandlers()
    return prop.THIS(nil)
end

--- plugins.core.action.activator:allowedHandlers <cp.prop: table of handlers; read-only>
--- Field
--- Contains all handlers that are allowed in this activator.
function activator.lazy.prop:allowedHandlers()
    return self._manager.handlers:mutate(
        function(original)
            local handlers = original()
            local allowed = {}
            local allowedIds = self:_allowedHandlers()

            for theID,handler in pairs(handlers) do
                if allowedIds == nil or allowedIds[theID] then
                    allowed[theID] = handler
                end
            end

            return allowed
        end
    )
end

-- plugins.core.action.activator._disabledHandlers <cp.prop: table of booleans>
-- Field
-- Table of disabled handlers. If the ID is present with a value of `true`, it's disabled.
function activator.lazy.prop:_disabledHandlers()
    return config.prop(self._prefix .. "disabledHandlers", {})
    :watch(function() self:refreshChooser() end)
end

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
function activator.lazy.prop:activeHandlers()
    return self.allowedHandlers:mutate(function(original)
        local handlers = original()
        local result = {}

        local disabled = self._disabledHandlers()
        for i,handler in pairs(handlers) do
            if not disabled[i] then
                result[i] = handler
            end
        end

        return result
    end)
    :monitor(self._disabledHandlers)
end

--- plugins.core.action.activator.query <cp.prop: string>
--- Field
--- The current "query" value for the activator.
function activator.lazy.prop:query()
    return prop.THIS(nil)
    :watch(function() doAfter(0, function() self:refreshChooser() end) end)
end

--- plugins.core.action.activator.hiddenChoices <cp.prop: table of booleans>
--- Field
--- Contains the set of choice IDs which are hidden in this activator, mapped to a boolean value.
--- If set to `true`, the choice is hidden.
function activator.lazy.prop:hiddenChoices()
    return config.prop(self._prefix .. "hiddenChoices", {}):cached()
end

--- plugins.core.action.activator.favoriteChoices <cp.prop: table of booleans>
--- Field
--- Contains the set of choice IDs which are favorites in this activator, mapped to a boolean value.
--- If set to `true`, the choice is a favorite.
function activator.lazy.prop:favoriteChoices()
    return config.prop(self._prefix .. "favoriteChoices", {}):cached()
    :watch(function() doAfter(1.0, function() self:sortChoices() end) end)
end

--- plugins.core.action.activator.popularChoices <cp.prop: table of integers>
--- Field
--- Keeps track of how popular particular choices are. Returns a table of choice IDs
--- mapped to the number of times they have been activated.
function activator.lazy.prop:popularChoices()
    return config.prop(self._prefix .. "popularChoices", {}):cached()
    :watch(function() doAfter(1.0, function() self:sortChoices() end) end)
end

--- plugins.core.action.activator.configurable <cp.prop: boolean>
--- Field
--- If `true` (the default), the activator can be configured by right-clicking on the main chooser.
function activator.lazy.prop:configurable()
    return config.prop(self._prefix .. "configurable", true):cached()
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
function activator:preloadChoices(afterSeconds)
    afterSeconds = afterSeconds or 0
    idle.queue(afterSeconds, function()
        -- log.df("Preloading choices for '%s'", self._id)
        self:allChoices()
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
function activator:id()
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
function activator:getActiveHandler(id)
    return self:activeHandlers()[id]
end

--- plugins.core.action.activator:allowHandlers(...) -> self
--- Method
--- Specifies that only the handlers with the specified IDs will be active in
--- this activator. By default all handlers are allowed.
---
--- Parameters:
---  * `...`     - The list of Handler ID strings to allow.
---
--- Returns:
---  * Self
function activator:allowHandlers(...)
    local allowed = {}
    for _,id in ipairs(pack(...)) do
        if self._manager.getHandler(id) then
            allowed[id] = true
        else
            error(string.format("Attempted to make action handler '%s' exclusive, but it could not be found.", id))
        end
    end
    self._allowedHandlers(allowed)
    return self
end

--- plugins.core.action.activator:toolbarIcons(table) -> self
--- Method
--- Sets which sections have an icon on the toolbar.
---
--- Parameters:
---  * table - A table containing paths to all the toolbar icons. The key should be
---            the handler ID, and the value should be the path to the icon.
---
--- Returns:
---  * Self
function activator:toolbarIcons(toolbarIcons)
    self._toolbarIcons = toolbarIcons
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
function activator:disableHandler(id)
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
function activator:enableHandler(id)
    if self._manager.getHandler(id) == nil then
        return false
    end
    local dh = self:_disabledHandlers()
    dh[id] = nil
    self:_disabledHandlers(dh)
    self:refreshChooser()
    return true
end

--- plugins.core.action.activator:enableAllHandlers([groupID]]) -> none
--- Method
--- Enables the all allowed handlers.
---
--- Parameters:
---  * groupID - An optional group ID to only enable all handlers of a specific group
---
--- Returns:
---  * None
function activator:enableAllHandlers(groupID)
    if groupID then
        local dh = self:_disabledHandlers()
        local allowedHandlers = self:allowedHandlers()
        for id,_ in pairs(allowedHandlers) do
            local idComponents = split(id, "_")
            local currentGroupID = idComponents and idComponents[1]
            if currentGroupID == groupID then
                dh[id] = nil
            end
        end
        self:_disabledHandlers(dh)
    else
        self._disabledHandlers:set(nil)
    end
    self:refreshChooser()
end

--- plugins.core.action.activator:disableAllHandlers([groupID]) -> none
--- Method
--- Disables the all allowed handlers.
---
--- Parameters:
---  * groupID - An optional group ID to only disable all handlers of a specific group
---
--- Returns:
---  * None
function activator:disableAllHandlers(groupID)
    if groupID then
        local dh = self:_disabledHandlers()
        local allowedHandlers = self:allowedHandlers()
        for id,_ in pairs(allowedHandlers) do
            local idComponents = split(id, "_")
            local currentGroupID = idComponents and idComponents[1]
            if currentGroupID == groupID then
                dh[id] = true
            end
        end
        self:_disabledHandlers(dh)
    else
        local dh = {}
        for id,_ in pairs(self:allowedHandlers()) do
            dh[id] = true
        end
        self:_disabledHandlers(dh)
    end
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
function activator:isDisabledHandler(id)
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
function activator:findChoice(id)
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
function activator:hideChoice(id)
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
function activator:unhideChoice(id)
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
function activator:isHiddenChoice(id)
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
function activator:isFavoriteChoice(id)
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
function activator:favoriteChoice(id)
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
function activator:unfavoriteChoice(id)
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
function activator:getPopularity(id)
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
function activator:incPopularity(choice, id)
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

local function _sortChoices(choices, query)
    local queryLen = query and query:len() or 0

    return sort(choices, function(a, b)
        --------------------------------------------------------------------------------
        -- Exact query match gets first priority:
        --------------------------------------------------------------------------------
        if queryLen > 0 then
            local aExact = a.textMatch == 1 and a.text:len() == queryLen
            local bExact = b.textMatch == 1 and b.text:len() == queryLen

            if aExact and not bExact then
                return true
            elseif not aExact and bExact then
                return false
            end
        end

        --------------------------------------------------------------------------------
        -- Favorites next:
        --------------------------------------------------------------------------------
        local afav = a.favorite
        local bfav = b.favorite
        if afav and not bfav then
            return true
        elseif bfav and not afav then
            return false
        end

        --------------------------------------------------------------------------------
        -- Prioritise fields that start with query string:
        --
        -- REMINDER: a.text could be a hs.styledtext object
        --------------------------------------------------------------------------------
        if queryLen > 0 then
            local aStartsWithQ = a.textMatch == 1
            local bStartsWithQ = b.textMatch == 1

            if aStartsWithQ and not bStartsWithQ then
                return true
            elseif not aStartsWithQ and bStartsWithQ then
                return false
            end
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
        -- Then text by alphabetical order in lowercase:
        --------------------------------------------------------------------------------
        local aa = a.text:lower()
        local bb = b.text:lower()

        if aa < bb then
            return true
        elseif bb < aa then
            return false
        end

        --------------------------------------------------------------------------------
        -- Then subText by alphabetical order in lowercase:
        --------------------------------------------------------------------------------
        local asub = a.subText or ""
        local bsub = b.subText or ""
        return asub:lower() < bsub:lower()
    end)
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
function activator:sortChoices()
    if self._choices then
        return _sortChoices(self._choices)
    end
    return true
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
function activator:allChoices()
    if not self._choices then
        self:_findChoices():After(5)
    end
    return self._choices
end

--- plugins.core.action.activator:activeChoices() -> table
--- Method
--- Returns a table with active choices. If a `query` is set, only choices containing the provided substring are returned.
--- If [showHidden](#showHidden) is set to `true`  hidden
--- items are returned, otherwise they are not.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of choices that can be displayed by an `hs.chooser`.
function activator:activeChoices()
    local showHidden = self:showHidden()
    local disabledHandlers = self:_disabledHandlers()
    local query = self:query()

    query = query and query:lower()

    local queryLen = query and query:len() or 0
    local searchSubText = self:searchSubText()

    local results = moses.select(self:allChoices(), function(choice)
        if (showHidden or not choice.hidden) and not disabledHandlers[choice.type] then
            -- Check if we are filtering by query
            if queryLen > 0 then
                -- Store the match index for sorting later.
                choice.textMatch = choice.text:lower():find(query, 1, true)
                if choice.textMatch then
                    return true
                elseif searchSubText == true and choice.subText and choice.subText:lower():find(query, 1, true) then
                    return true
                end
                return false
            else
                choice.textMatch = nil
            end
            return true
        end
        return false
    end)

    _sortChoices(results, query)

    return results
end

local LOADING_CHOICES = {
    {
        ["text"] = i18n("loading") .. "...",
    }
}

-- plugins.core.action.activator:_findChoices() -> cp.rx.Statement
-- Method
-- Finds and sorts all choices from enabled handlers. They are available via
-- the [choices](#choices) or [allChoices](#allChoices) properties.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function activator:_findChoices()

    self._choices = LOADING_CHOICES

    return Do(function()
        --------------------------------------------------------------------------------
        -- Check if we are already watching the handlers:
        --------------------------------------------------------------------------------
        local unwatched = not self._watched
        self._watched = true

        local popularity = self:popularChoices()
        local favorites = self:favoriteChoices()
        local hidden = self:hiddenChoices()

        local result = {}
        self._choices = result

        local handlers = self:allowedHandlers()

        return Given(Observable.fromTable(handlers, pairs))
        :Then(function(handler)
            local choices = handler:choices()
            if choices then
                local choicesTable = choices:getChoices()

                for _,choice in ipairs(choicesTable) do
                    local id = choice.id
                    applyHiddenTo(choice, hidden[id])
                    choice.popularity = popularity[id] or 0
                    choice.favorite = favorites[id] == true
                end

                concat(result, choicesTable)
            end
            --------------------------------------------------------------------------------
            -- Check if we should watch the handler choices:
            --------------------------------------------------------------------------------
            if unwatched then
                handler.choices:watch(function() self:refresh() end)
            end
        end)
        :ThenYield()
    end)
    :Finally(function()
        self:refreshChooser()
    end)
end


--- plugins.core.action.activator:refresh() -> none
--- Method
--- Clears the existing set of choices and requests new ones from enabled action handlers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function activator:refresh()
    self._choices = nil
end

--- plugins.core.action.activator.reducedTransparency <cp.prop: boolean>
--- Field
--- A property which will be true if the 'reduce transparency' mode is enabled.
activator.reducedTransparency = prop.new(function()
    return screen.accessibilitySettings()["ReduceTransparency"]
end)

--- plugins.core.action.activator:updateSelectedToolbarIcon() -> none
--- Method
--- Updates the selected toolbar icon.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator:updateSelectedToolbarIcon()
    local allHandlersActive = true
    local toolbarIcons = self._toolbarIcons
    local t = self._toolbar
    if t and toolbarIcons then
        for id,_ in pairs(toolbarIcons) do
            local soloed = true
            for i,_ in pairs(self:allowedHandlers()) do
                if self:isDisabledHandler(i) then
                    allHandlersActive = false
                end
                if i ~= id and not self:isDisabledHandler(i) then
                    soloed = false
                    break
                end
            end
            if soloed and not self:isDisabledHandler(id) then
                t:selectedItem(id)
                return
            end
        end
        if allHandlersActive then
            t:selectedItem("showAll")
        else
            t:selectedItem(nil)
        end
    end
end

--- plugins.core.action.activator:chooser() -> `hs.chooser` object
--- Method
--- Gets a hs.chooser
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.chooser` object
function activator:chooser()

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

        --------------------------------------------------------------------------------
        -- Create new toolbar:
        --------------------------------------------------------------------------------
        local t = toolbar.new(uuid())
            :canCustomize(true)
            :autosaves(true)
            :sizeMode("small")

        --------------------------------------------------------------------------------
        -- Add "Show All" button:
        --------------------------------------------------------------------------------
        t:addItems({
            id = "showAll",
            label = i18n("showAll"),
            priority = 1,
            image = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/showAll.png"),
            selectable = true,
            fn = function()
                self:enableAllHandlers()
            end,
        })

        local toolbarIcons = self._toolbarIcons
        if toolbarIcons and next(toolbarIcons) ~= nil then
            --------------------------------------------------------------------------------
            -- Add buttons for each section that has an icon:
            --------------------------------------------------------------------------------
            for id, item in spairs(toolbarIcons, function(x,a,b) return x[b].priority > x[a].priority end) do
                t:addItems({
                    id = id,
                    label = i18n(id .. "_action"),
                    tooltip = i18n(id .. "_action"),
                    image = imageFromPath(item.path),
                    priority = item.priority + 1,
                    selectable = true,
                    fn = function()
                        local soloed = true
                        for i,_ in pairs(self:allowedHandlers()) do
                            if i ~= id and not self:isDisabledHandler(i) then
                                soloed = false
                                break
                            end
                        end
                        if soloed then
                            self:enableAllHandlers()
                            t:selectedItem("showAll")
                        else
                            self:disableAllHandlers()
                            self:enableHandler(id)
                        end
                    end,
                })
            end
        end

        local executeFn = function(result)
            if self._eventtap then
                self._eventtap:stop()
                self._eventtap = nil
            end
            self:activate(result)
        end
        local rightClickFn = function(index) self:rightClickMain(index) end
        local choicesFn = function() return self:activeChoices() end
        local searchSubText = self:searchSubText()

        local updateConsole = function(id)
            if id == "showAll" then
                self:enableAllHandlers()
            else
                local soloed = true
                for i,_ in pairs(self:allowedHandlers()) do
                    if i ~= id and not self:isDisabledHandler(i) then
                        soloed = false
                        break
                    end
                end
                if soloed then
                    self:enableAllHandlers()
                    self._toolbar:selectedItem("showAll")
                else
                    self:disableAllHandlers()
                    self:enableHandler(id)
                end
            end
        end

        local setupEventtap = function()
            if not self._eventtap then
                self._eventtap = eventtap.new({eventtap.event.types.keyDown}, function(event)
                    if event:getFlags():containExactly({"fn", "alt"}) then
                        if event:getKeyCode() == 123 then
                            if self._toolbar then
                                local visibleItems = self._toolbar:visibleItems()
                                local selectedItem = self._toolbar:selectedItem()
                                if not selectedItem then
                                    self._toolbar:selectedItem(visibleItems[1])
                                    updateConsole(visibleItems[1])
                                elseif selectedItem == visibleItems[1] then
                                    self._toolbar:selectedItem(visibleItems[#visibleItems])
                                    updateConsole(visibleItems[#visibleItems])
                                else
                                    local current
                                    for i=1, #visibleItems do
                                        if visibleItems[i] == selectedItem then
                                            current = i
                                            break
                                        end
                                    end
                                    if current then
                                        self._toolbar:selectedItem(visibleItems[current - 1])
                                        updateConsole(visibleItems[current - 1])
                                    end
                                end
                            end
                        elseif event:getKeyCode() == 124 then
                            if self._toolbar then
                                local visibleItems = self._toolbar:visibleItems()
                                local selectedItem = self._toolbar:selectedItem()
                                if not selectedItem then
                                    self._toolbar:selectedItem(visibleItems[1])
                                    updateConsole(visibleItems[1])
                                elseif selectedItem == visibleItems[#visibleItems] then
                                    self._toolbar:selectedItem(visibleItems[1])
                                    updateConsole(visibleItems[1])
                                else
                                    local current
                                    for i=1, #visibleItems do
                                        if visibleItems[i] == selectedItem then
                                            current = i
                                            break
                                        end
                                    end
                                    if current then
                                        self._toolbar:selectedItem(visibleItems[current + 1])
                                        updateConsole(visibleItems[current + 1])
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            if self._eventtap then
                self._eventtap:start()
            end
        end

        local c = chooser.new(executeFn)
            :bgDark(true)
            :rightClickCallback(rightClickFn)
            :choices(choicesFn)
            :searchSubText(searchSubText)
            :showCallback(setupEventtap)
            :queryChangedCallback(function(value)
                self.query:set(value)
            end)

        if t then
            c:attachedToolbar(t)
            t:inTitleBar(true)
        end

        if activator.reducedTransparency() then
            c:fgColor(nil)
             :subTextColor(nil)
        else
            c:fgColor(drawing.color.x11.snow)
             :subTextColor(drawing.color.x11.snow)
        end

        self._chooser = c
        self._toolbar = t

    end
    return self._chooser
end

--- plugins.core.action.activator:refreshChooser() -> none
--- Method
--- Refreshes a Chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator:refreshChooser()
    local theChooser = self:chooser()
    if theChooser then
        theChooser:refreshChoicesCallback(true)
    end
end

--- plugins.core.action.activator:isVisible() -> boolean
--- Method
--- Checks if the chooser is currently displayed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A boolean, `true` if the chooser is displayed on screen, `false` if not.
function activator:isVisible()
    local theChooser = self:chooser()
    return theChooser and theChooser:isVisible()
end

--- plugins.core.action.activator:show() -> boolean
--- Method
--- Shows a chooser listing the available actions. When selected by the user,
--- the [onActivate](#onActivate) function is called.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful
function activator:show()

    --------------------------------------------------------------------------------
    -- Get Chooser:
    --------------------------------------------------------------------------------
    local theChooser = self:chooser()
    if theChooser and theChooser:isVisible() then
        return
    end

    --------------------------------------------------------------------------------
    -- Refresh Chooser:
    --------------------------------------------------------------------------------
    self:refreshChooser()

    --------------------------------------------------------------------------------
    -- Remember Last Query:
    --------------------------------------------------------------------------------
    local chooserRememberLast = self:lastQueryRemembered()
    if chooserRememberLast then
        theChooser:query(self:lastQueryValue())
    else
        theChooser:query("")
    end

    --------------------------------------------------------------------------------
    -- Search Console Subtext:
    --------------------------------------------------------------------------------
    theChooser:searchSubText(self:searchSubText())

    --------------------------------------------------------------------------------
    -- Set Placeholder Text:
    --------------------------------------------------------------------------------
    theChooser:placeholderText(i18n("appName"))

    --------------------------------------------------------------------------------
    -- Update Selected Toolbar Icon:
    --------------------------------------------------------------------------------
    self:updateSelectedToolbarIcon()

    --------------------------------------------------------------------------------
    -- Show Console:
    --------------------------------------------------------------------------------
    Do(function() theChooser:show() end):After(0)

    return true
end

--- plugins.core.action.activator:hide() -> none
--- Method
--- Hides a chooser listing the available actions.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator:hide()
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

--- plugins.core.action.activator:toggle() -> none
--- Method
--- Shows or hides the chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function activator:toggle()
    if self:isVisible() then
        self:hide()
    else
        self:show()
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
function activator:onActivate(activateFn)
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
function activator._onActivate(handler, action, text)
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
function activator:activate(result)
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
function activator:rightClickMain(index)
    self:rightClickAction(index)
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
function activator:rightClickAction(index)

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
        insert(choiceMenu, { title = i18n("rememberLastQuery"),     fn=function() self.lastQueryRemembered:toggle(); self:refreshChooser() end, checked = self:lastQueryRemembered() })
        insert(choiceMenu, { title = i18n("searchSubtext"),         fn=function() self.searchSubText:toggle(); theChooser:searchSubText(self:searchSubText()); self:refreshChooser(); end, checked = self:searchSubText() })
        insert(choiceMenu, { title = i18n("activatorShowHidden"),   fn=function() self.showHidden:toggle(); self:refreshChooser() end, checked = self:showHidden() })
        insert(choiceMenu, { title = "-" })

        --------------------------------------------------------------------------------
        -- The 'Show Action Group' menu:
        --------------------------------------------------------------------------------
        local sections = { title = i18n("showActionGroups") }

        --------------------------------------------------------------------------------
        -- Get list of allowed handler group names:
        --------------------------------------------------------------------------------
        local allowedHandlers = self:allowedHandlers()
        local allowedGroupNames = {}
        for i,_ in pairs(allowedHandlers) do
            local idComponents = split(i, "_")
            local groupID = idComponents and idComponents[1]
            if not allowedGroupNames[groupID] then
                allowedGroupNames[groupID] = true
            end
        end
        table.sort(allowedGroupNames)

        --------------------------------------------------------------------------------
        -- Create sub-menus per action group:
        --------------------------------------------------------------------------------
        local allEnabled = true
        local allDisabled = true

        local allEnabledInGroup = {}
        local allDisabledInGroup = {}

        local groupItems = {}
        for currentGroupID, _ in pairs(allowedGroupNames) do

            allEnabledInGroup[currentGroupID] = true
            allDisabledInGroup[currentGroupID] = true

            local submenu = {}
            for id,_ in pairs(allowedHandlers) do
                local idComponents = split(id, "_")
                local groupID = idComponents and idComponents[1]
                if groupID == currentGroupID then
                    local enabled = not self:isDisabledHandler(id)
                    allEnabled = allEnabled and enabled
                    allDisabled = allDisabled and not enabled

                    allEnabledInGroup[groupID] = allEnabledInGroup[groupID] and enabled
                    allDisabledInGroup[groupID] = allDisabledInGroup[groupID] and not enabled

                    submenu[#submenu + 1] = {
                        title = i18n(format("%s_action", id)) or id,
                        fn=function()
                            if enabled then
                                self:disableHandler(id)
                            else
                                self:enableHandler(id)
                            end
                            self:updateSelectedToolbarIcon()
                        end,
                        checked = enabled,
                    }
                end
            end

            sort(submenu, function(a, b) return a.title < b.title end)

            local allSubmenu = {
                { title = i18n("consoleSectionsShowAll"), fn = function()
                    self:enableAllHandlers(currentGroupID)
                    self:updateSelectedToolbarIcon()
                end, disabled = allEnabledInGroup[currentGroupID] },
                { title = i18n("consoleSectionsHideAll"), fn = function()
                    self:disableAllHandlers(currentGroupID)
                    self:updateSelectedToolbarIcon()
                end, disabled = allDisabledInGroup[currentGroupID] },
                { title = "-" }
            }

            concat(allSubmenu, submenu)

            groupItems[#groupItems + 1] = {
                title = i18n(format("%s_command_group", currentGroupID)) or currentGroupID,
                menu = allSubmenu,
            }
        end

        sort(groupItems, function(a, b) return a.title < b.title end)

        local allItems = {
            { title = i18n("consoleSectionsShowAll"), fn = function()
                self:enableAllHandlers()
                self:updateSelectedToolbarIcon()
            end, disabled = allEnabled },
            { title = i18n("consoleSectionsHideAll"), fn = function()
                self:disableAllHandlers()
                self:updateSelectedToolbarIcon()
            end, disabled = allDisabled },
            { title = "-" }
        }
        concat(allItems, groupItems)

        sections.menu = allItems

        insert(choiceMenu, sections)
    end

    self._rightClickMenubar:setMenu(choiceMenu):removeFromMenuBar()
    self._rightClickMenubar:popupMenu(mouse.getAbsolutePosition(), true)
end

return activator
