--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.action.activator ===
---
--- This module provides provides a way of activating choices provided by action handlers.
--- It also provide support for making a particular action a favourite, returning
--- results based on popularity, and completely hiding particular actions, or categories of action.
---
--- Activators are accessed via the [action manager](plugins.finalcutpro.action.manager.md) like so:
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
local log						= require("hs.logger").new("activator")

local _							= require("moses")
local prop						= require("cp.prop")
local config					= require("cp.config")
local just						= require("cp.just")
local chooser					= require("hs.chooser")
local drawing 					= require("hs.drawing")
local fnutils 					= require("hs.fnutils")
local menubar					= require("hs.menubar")
local mouse						= require("hs.mouse")
local screen					= require("hs.screen")
local timer						= require("hs.timer")
local application				= require("hs.application")
local fcp						= require("cp.apple.finalcutpro")

local setmetatable				= setmetatable
local sort, insert				= table.sort, table.insert
local concat, filter			= fnutils.concat, fnutils.filter
local format					= string.format

local activator = {}
activator.mt = {}
activator.mt.__index = activator.mt

local PACKAGE = "finalcutpro.action.activator."

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

-- plugins.finalcutpro.action.activator.new(id, manager)
-- Constructor
-- Creates a new `activator` instance with the specified ID and action manager
function activator.new(id, manager)
	local o = {
		_id				= id,
		_manager		= manager,
		_chooser	= nil, 		-- the actual hs.chooser
	}

	prop.extend(o, activator.mt)

	local prefix = PACKAGE .. id .. "."

	--- plugins.finalcutpro.action.activator.searchSubText <cp.prop: boolean>
	--- Field
	--- If `true`, allow users to search the subtext value.
	o.searchSubText = config.prop(prefix .. "searchSubText", true):bind(o)

	--- plugins.finalcutpro.action.activator.lastQueryRemembered <cp.prop: boolean>
	--- Field
	--- If `true`, remember the last query.
	o.lastQueryRemembered = config.prop(prefix .. "lastQueryRemembered", true):bind(o)

	--- plugins.finalcutpro.action.activator.lastQueryValue <cp.prop: string>
	--- Field
	--- The last query value.
	o.lastQueryValue = config.prop(prefix .. "lastQueryValue", ""):bind(o)

	--- plugins.finalcutpro.action.activator.showHidden <cp.prop: boolean>
	--- Field
	--- If `true`, hidden items are shown.
	o.showHidden = config.prop(prefix .. "showHidden", false):bind(o)
	-- refresh the chooser list if this status changes.
	:watch(function() o:refreshChooser() end)

	-- plugins.finalcutpro.action.activator._allowedHandlers <cp.prop: string>
	-- Field
	-- The ID of a single handler to source
	o._allowedHandlers = config.prop(prefix .. "allowedHandlers", nil):bind(o)


--- plugins.finalcutpro.action.activator:allowedHandlers <cp.prop: table of handlers; read-only>
--- Field
--- Contains all handlers that are allowed in this activator.
	o.allowedHandlers = o._manager.handlers:mutate(function(handlers)
		local allowed = {}
		local allowedIds = o:_allowedHandlers()

		for id,handler in pairs(handlers) do
			if allowedIds == nil or allowedIds[id] then
				allowed[id] = handler
			end
		end

		return allowed
	end):bind(o)

	-- plugins.finalcutpro.action.activator._disabledHandlers <cp.prop: table of booleans>
	-- Field
	-- Table of disabled handlers. If the ID is present with a value of `true`, it's disabled.
	o._disabledHandlers = config.prop(prefix .. "disabledHandlers", {}):bind(o)
	:watch(function() o:refreshChooser() end)

--- plugins.finalcutpro.action.activator.activeHandlers <cp.prop: table of handlers>
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
		for id,handler in pairs(handlers) do
			if not disabled[id] then
				result[id] = handler
			end
		end

		return result
	end):bind(o)
	:monitor(o._disabledHandlers)
	:monitor(manager.handlers)

--- plugins.finalcutpro.action.activator.hiddenChoices <cp.prop: table of booleans>
--- Field
--- Contains the set of choice IDs which are hidden in this activator, mapped to a boolean value.
--- If set to `true`, the choice is hidden.
	o.hiddenChoices = config.prop(prefix .. "hiddenChoices", {}):bind(o)

	--- plugins.finalcutpro.action.activator.favoriteChoices <cp.prop: table of booleans>
	--- Field
	--- Contains the set of choice IDs which are favorites in this activator, mapped to a boolean value.
	--- If set to `true`, the choice is a favorite.
	o.favoriteChoices = config.prop(prefix .. "favoriteChoices", {}):bind(o)
	:watch(function() timer.doAfter(1.0, function() o:sortChoices() end) end)

	--- plugins.finalcutpro.action.activator.popularChoices <cp.prop: table of integers>
	--- Field
	--- Keeps track of how popular particular choices are. Returns a table of choice IDs
	--- mapped to the number of times they have been activated.
	o.popularChoices = config.prop(prefix .. "popularChoices", {}):bind(o)
	:watch(function() timer.doAfter(1.0, function() o:sortChoices() end) end)

	--- plugins.finalcutpro.action.activator.configurable <cp.prop: boolean>
	--- Field
	--- If `true` (the default), the activator can be configured by right-clicking on the main chooser.
	o.configurable = config.prop(prefix .. "configurable", true):bind(o)

	if fcp:isRunning() then timer.doAfter(3, function() o:_findChoices() end) end

	return o
end

--- plugins.finalcutpro.action.activator:id() -> string
--- Method
--- Returns the activator's unique ID.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The activator ID.
function activator.mt:id()
	return self._id
end

--- plugins.finalcutpro.action.activator:getActiveHandler(id) -> handler
--- Method
--- Returns the active handler with the specified ID, or `nil` if not available.
---
--- Parameters:
--- * `id`		- The Handler ID
---
--- Returns:
--- * The action handler, or `nil`.
function activator.mt:getActiveHandler(id)
	return self:activeHandlers()[id]
end

--- plugins.finalcutpro.action.activator:allowHandlers(...) -> boolean
--- Method
--- Specifies that only the handlers with the specified IDs will be active in
--- this activator. By default all handlers are allowed.
---
--- Parameters:
--- * `...`		- The list of Handler ID strings to allow.
---
--- Returns:
--- * `true` if the handlers were found.
function activator.mt:allowHandlers(...)
	local allowed = {}
	for _,id in ipairs(table.pack(...)) do
		if self._manager.getHandler(id) then
			allowed[id] = true
		else
			error(string.format("Attempted to make action handler '%s' exclusive, but it could not be found.", id))
		end
	end
	self._allowedHandlers(allowed)
	return self
end

--- plugins.finalcutpro.action.activator:disableHandler(id) -> boolean
--- Method
--- Disables the handler with the specified ID.
---
--- Parameters:
--- * `id`		- The unique action handler ID.
---
--- Returns:
--- * `true` if the handler exists and was disabled.
function activator.mt:disableHandler(id)
	if self._manager.getHandler(id) == nil then
		return false
	end
	local dh = self:_disabledHandlers()
	dh[id] = true
	self:_disabledHandlers(dh)
	return true
end

--- plugins.finalcutpro.action.activator:enableHandler(id) -> boolean
--- Method
--- Enables the handler with the specified ID.
---
--- Parameters:
--- * `id`		- The unique action handler ID.
---
--- Returns:
--- * `true` if the handler exists and was enabled.
function activator.mt:enableHandler(id)
	if self._manager.getHandler(id) == nil then
		return false
	end
	local dh = self:_disabledHandlers()
	dh[id] = nil
	self:_disabledHandlers(dh)
	return true
end

--- plugins.finalcutpro.action.activator:enableAllHandlers() -> nothing
--- Method
--- Enables the all allowed handlers.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function activator.mt:enableAllHandlers()
	self._disabledHandlers:set(nil)
end

--- plugins.finalcutpro.action.activator:disableAllHandlers() -> nothing
--- Method
--- Disables the all allowed handlers.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function activator.mt:disableAllHandlers()
	local dh = {}
	for id,_ in pairs(self:allowedHandlers()) do
		dh[id] = true
	end
	self:_disabledHandlers(dh)
end

--- plugins.finalcutpro.action.activator:isDisabledHandler(id) -> boolean
--- Method
--- Returns `true` if the specified handler is disabled.
---
--- Parameters:
--- * `id`			- The handler ID.
---
--- Returns:
--- * `true` if the handler is disabled.
function activator.mt:isDisabledHandler(id)
	local dh = self:_disabledHandlers()
	return dh[id] == true
end

--- plugins.finalcutpro.action.activator:hideChoice(id) -> boolean
--- Method
--- Hides the choice with the specified ID.
---
--- Parameters:
--- * `id`			- The choice ID to hide.
---
--- Returns:
--- * `true` if successfully hidden.
function activator.mt:hideChoice(id)
	if id then
		-- update the list of hidden choices
		local hidden = self:hiddenChoices()
		hidden[id] = true
		self:hiddenChoices(hidden)

		-- update the actual choice
		for _,choice in ipairs(self:allChoices()) do
			if choice.id == id then
				applyHiddenTo(choice, true)
				break
			end
		end

		-- update the chooser list.
		self:refreshChooser()
		return true
	end
	return false
end

--- plugins.finalcutpro.action.activator:unhideChoice(id) -> boolean
--- Method
--- Reveals the choice with the specified ID.
---
--- Parameters:
--- * `id`			- The choice ID to hide.
---
--- Returns:
--- * `true` if successfully unhidden.
function activator.mt:unhideChoice(id)
	if id then
		local hidden = self:hiddenChoices()
		hidden[id] = nil
		self:hiddenChoices(hidden)
		self:refreshChooser()

		-- update the actual choice
		for _,choice in ipairs(self:allChoices()) do
			if choice.id == id then
				applyHiddenTo(choice, false)
				break
			end
		end

		return true
	end
	return false
end

--- plugins.finalcutpro.action.activator:isHiddenChoice(id) -> boolean
--- Method
--- Checks if the specified choice is hidden.
---
--- Parameters:
--- * `id`			- The choice ID to check.
---
--- Returns:
--- * `true` if currently hidden.
function activator.mt:isHiddenChoice(id)
	return self:hiddenChoices()[id] == true
end

--- plugins.finalcutpro.action.activator:isHiddenChoice(id) -> boolean
--- Method
--- Checks if the specified choice is hidden.
---
--- Parameters:
--- * `id`			- The choice ID to check.
---
--- Returns:
--- * `true` if currently hidden.
function activator.mt:isFavoriteChoice(id)
	local favorites = self:favoriteChoices()
	return id and favorites and favorites[id] == true
end

--- plugins.finalcutpro.action.activator:favoriteChoice(id) -> boolean
--- Method
--- Marks the choice with the specified ID as a favorite.
---
--- Parameters:
--- * `id`			- The choice ID to favorite.
---
--- Returns:
--- * `true` if successfully favorited.
function activator.mt:favoriteChoice(id)
	if id then
		local favorites = self:favoriteChoices()
		favorites[id] = true
		self:favoriteChoices(favorites)
		return true
	end
	return false
end

--- plugins.finalcutpro.action.activator:unfavoriteChoice(id) -> boolean
--- Method
--- Marks the choice with the specified ID as not a favorite.
---
--- Parameters:
--- * `id`			- The choice ID to unfavorite.
---
--- Returns:
--- * `true` if successfully unfavorited.
function activator.mt:unfavoriteChoice(id)
	if id then
		local favorites = self:favoriteChoices()
		favorites[id] = nil
		self:favoriteChoices(favorites)
		return true
	end
	return false
end

--- plugins.finalcutpro.action.activator:getPopularity(id) -> boolean
--- Method
--- Returns the popularity of the specified choice.
---
--- Parameters:
--- * `id`			- The choice ID to retrieve.
---
--- Returns:
--- * The number of times the choice has been executed.
function activator.mt:getPopularity(id)
	if id then
		local index = self:popularChoices()
		return index[id] or 0
	end
	return 0
end

--- plugins.finalcutpro.action.activator:incPopularity(id) -> boolean
--- Method
--- Marks the choice with the specified ID as not a favorite.
---
--- Parameters:
--- * `id`			- The choice ID to unfavorite.
---
--- Returns:
--- * `true` if successfully unfavorited.
function activator.mt:incPopularity(id)
	if id then
		local index = self:popularChoices()
		local pop = index[id] or 0
		index[id] = pop + 1
		self:popularChoices(index)
	end
end

--- plugins.finalcutpro.action.activator:sortChoices() -> boolean
--- Method
--- Sorts the current set of choices in the activator. It takes into account
--- whether it's a favorite (first priority) and its overall popularity.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the action executed successfully.
function activator.mt:sortChoices()
	if self._choices then
		return sort(self._choices, function(a, b)
			-- Favorites get first priority
			local afav = self:isFavoriteChoice(a.id)
			local bfav = self:isFavoriteChoice(b.id)
			if afav and not bfav then
				return true
			elseif bfav and not afav then
				return false
			end

			-- Then popularity, if specified
			local apop = self:getPopularity(a.id)
			local bpop = self:getPopularity(b.id)
			if apop > bpop then
				return true
			elseif bpop > apop then
				return false
			end

			-- Then text by alphabetical order
			if a.text < b.text then
				return true
			elseif b.text < a.text then
				return false
			end

			-- Then subText by alphabetical order
			local asub = a.subText or ""
			local bsub = b.subText or ""
			return asub < bsub
		end)
	end
end

--- plugins.finalcutpro.action.activator:allChoices() -> table
--- Method
--- Returns a table of all available choices, even if hidden. Choices from
--- disabled action handlers are not included.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Table of choices that can be displayed by an `hs.chooser`.
function activator.mt:allChoices()
	if not self._choices then
		self:_findChoices()
	end
	return self._choices
end

--- plugins.finalcutpro.action.activator:unhiddenChoices() -> table
--- Method
--- Returns a table with visible choices.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Table of choices that can be displayed by an `hs.chooser`.
function activator.mt:unhiddenChoices()
	return _.filter(self:allChoices(), function(i,choice) return not choice.hidden end)
end

--- plugins.finalcutpro.action.activator:activeChoices() -> table
--- Method
--- Returns a table with active choices. If [showHidden](#showHidden) is set to `true`  hidden
--- items are returned, otherwise they are not.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Table of choices that can be displayed by an `hs.chooser`.
function activator.mt:activeChoices()
	local showHidden = self:showHidden()
	local disabledHandlers = self:_disabledHandlers()

	return _.filter(self:allChoices(), function(i,choice) return (not choice.hidden or showHidden) and not disabledHandlers[choice.type] end)
end

-- plugins.finalcutpro.action.activator:_findChoices() -> nothing
-- Method
-- Finds and sorts all choices from enabled handlers. They are available via
-- the [choices](#choices) or [allChoices](#allChoices) properties.
function activator.mt:_findChoices()
	-- check if we are already watching the handlers.
	local unwatched = not self._watched
	self._watched = true

	local result = {}
	for id,handler in pairs(self:allowedHandlers()) do
		local choices = handler:choices()
		if choices then
			concat(result, choices:getChoices())
		end
		-- check if we should watch the handler choices
		if unwatched then
			handler.choices:watch(function() self:refresh() end)
		end
	end

	local hidden = self:hiddenChoices()
	for _,choice in ipairs(result) do
		applyHiddenTo(choice, hidden[choice.id])
	end
	self._choices = result
	self:sortChoices()
end

--- plugins.finalcutpro.action.activator:refresh()
--- Method
--- Clears the existing set of choices and requests new ones from enabled action handlers.
function activator.mt:refresh()
	self._choices = nil
end

-- A property which will be true if the 'reduce transparency' mode is enabled.
activator.reducedTransparency = prop.new(function()
	return screen.accessibilitySettings()["ReduceTransparency"]
end)

local function initChooser(executeFn, rightClickFn, choicesFn, searchSubText)
	local c = chooser.new(executeFn)
	:bgDark(true)
	:rightClickCallback(rightClickFn)
	:choices(choicesFn)
	:searchSubText(searchSubText)

	local color = activator.reducedTransparency() and nil or drawing.color.x11.snow
	c:fgColor(color):subTextColor(color)

	c:refreshChoicesCallback()

	return c
end

function activator.mt:chooser()
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

--------------------------------------------------------------------------------
-- REFRESH CONSOLE CHOICES:
--------------------------------------------------------------------------------
function activator.mt:refreshChooser()
	if self._chooser then
		self._chooser:refreshChoicesCallback()
	end
end

function activator.mt:checkReducedTransparency()
	local transparency = activator.reducedTransparency()
	if self._lastReducedTransparency ~= transparency then
		self._lastReducedTransparency = transparency
		self._chooser = nil
	end
end

--- plugins.finalcutpro.action.activator:show()
--- Method
--- Shows a chooser listing the available actions. When selected by the user,
--- the [onActivate](#onActivate) function is called.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function activator.mt:show()
	local chooser = self:chooser()
	if chooser and chooser:isVisible() then
		return
	end

	self._frontApp = application.frontmostApplication()

	--------------------------------------------------------------------------------
	-- Reload Console if Reduce Transparency
	--------------------------------------------------------------------------------
	self:checkReducedTransparency()

	self:refreshChooser()

	--------------------------------------------------------------------------------
	-- Remember last query?
	--------------------------------------------------------------------------------
	local chooserRememberLast = self:lastQueryRemembered()
	if not chooserRememberLast then
		chooser:query("")
	else
		chooser:query(self:lastQueryValue())
	end

	--------------------------------------------------------------------------------
	-- Show Console:
	--------------------------------------------------------------------------------
	chooser:searchSubText(self:searchSubText())
	chooser:show()

	return true
end

--------------------------------------------------------------------------------
-- HIDE CONSOLE:
--------------------------------------------------------------------------------
function activator.mt:hide()
	local chooser = self:chooser()
	if chooser then

		--------------------------------------------------------------------------------
		-- Hide Chooser:
		--------------------------------------------------------------------------------
		chooser:hide()

		--------------------------------------------------------------------------------
		-- Save Last Query to Settings:
		--------------------------------------------------------------------------------
		if self:lastQueryRemembered() then
			self.lastQueryValue:set(chooser:query())
		end

		if self._frontApp then
			self._frontApp:activate()
		end
	end
end

--- plugins.finalcutpro.action.activator:onActivate(activateFn) -> activator
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
--- * `activateFn`		- The function to call when an item is activated.
---
--- Returns:
--- * The activator.
function activator.mt:onActivate(activateFn)
	self._onActivate = activateFn
	return self
end

function activator.mt._onActivate(handler, action, text)
	if handler:execute(action) then
		return true
	else
		log.wf("Action '%s' handled by '%s' could not execute: %s", text, hs.inspect(handlerId), hs.inspect(action))
	end
	return false
end

--------------------------------------------------------------------------------
-- CONSOLE TRIGGER ACTION:
--------------------------------------------------------------------------------
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
				self:incPopularity(actionId)
			end
		else
			error(format("No action handler with an ID of %s is registered.", hs.inspect(handlerId)))
		end
	end
end

function activator.mt:rightClickMain(index)
	self:rightClickAction(index, true)
end

--------------------------------------------------------------------------------
-- CHOOSER RIGHT CLICK:
--------------------------------------------------------------------------------
function activator.mt:rightClickAction(index)

	local chooser = self:chooser()

	--------------------------------------------------------------------------------
	-- Settings:
	--------------------------------------------------------------------------------
	local choice = chooser:selectedRowContents(index)

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	self._rightClickMenubar = menubar.new(false)

	local choiceMenu = {}

	if choice and choice.id then
		local isFavorite = self:isFavoriteChoice(choice.id)

		insert( choiceMenu, { title = string.upper(i18n("highlightedItem")) .. ":", disabled = true } )
		if isFavorite then
			insert(
				choiceMenu,
				{
					title = i18n("activatorUnfavoriteAction"),
					fn = function()
						self:unfavoriteChoice(choice.id)
						self:refreshChooser()
						chooser:show()
					end
				}
			)
		else
			insert(
				choiceMenu,
				{
					title = i18n("activatorFavoriteAction"),
					fn = function()
						self:favoriteChoice(choice.id)
						self:refreshChooser()
						chooser:show()
					end
				}
			)
		end

		local isHidden = self:isHiddenChoice(choice.id)
		if isHidden then
			insert(
				choiceMenu,
				{
					title = i18n("activatorUnhideAction"),
					fn = function()
						self:unhideChoice(choice.id)
						self:refreshChooser()
						chooser:show()
					end
				}
			)
		else
			insert(
				choiceMenu,
				{
					title = i18n("activatorHideAction"),
					fn = function()
						self:hideChoice(choice.id)
						self:refreshChooser()
						chooser:show()
					end
				}
			)
		end
	end

	if self:configurable() then
		-- separator
		insert(choiceMenu, { title = "-" })
		insert(choiceMenu, { title = i18n("rememberLastQuery"),		fn=function() self.lastQueryRemembered:toggle() end, checked = self:lastQueryRemembered() })
		insert(choiceMenu, { title = i18n("searchSubtext"),			fn=function() self.searchSubText:toggle() end, checked = self:searchSubText() })
		insert(choiceMenu, { title = i18n("activatorShowHidden"),	fn=function() self.showHidden:toggle() end, checked = self:showHidden() })

		-- The 'Sections' menu
		local sections = { title = i18n("consoleSections") }
		local actionItems = {}
		local allEnabled = true
		local allDisabled = true

		for id,handler in pairs(self:allowedHandlers()) do
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
					self:refreshChooser()
				end,
				checked = enabled,
			}
		end

		sort(actionItems, function(a, b) return a.title < b.title end)

		local allItems = {
			{ title = i18n("consoleSectionsShowAll"), fn = function() self:enableAllHandlers() end, disabled = allEnabled },
			{ title = i18n("consoleSectionsHideAll"), fn = function() self:disableAllHandlers() end, disabled = allDisabled },
			{ title = "-" }
		}
		fnutils.concat(allItems, actionItems)

		sections.menu = allItems

		insert(choiceMenu, sections)
	end

	self._rightClickMenubar:setMenu(choiceMenu)
	self._rightClickMenubar:popupMenu(mouse.getAbsolutePosition())
end

return activator