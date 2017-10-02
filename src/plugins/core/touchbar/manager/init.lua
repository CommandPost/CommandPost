--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               T O U C H B A R    M A N A G E R    P L U G I N              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.touchbar.manager ===
---
--- Touch Bar Manager Plugin.
--- This handles both the Virtual Touch Bar and adding items to the physical Touch Bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("managerTouchBar")

local inspect									= require("hs.inspect")
local eventtap									= require("hs.eventtap")
local image										= require("hs.image")

local touchbar 									= require("hs._asm.undocumented.touchbar")

local config									= require("cp.config")
local prop										= require("cp.prop")
local tools										= require("cp.tools")
local commands									= require("cp.commands")

--------------------------------------------------------------------------------
--
-- THE MODULE - PHYSICAL TOUCH BAR:
--
--------------------------------------------------------------------------------
local mod = {}

-- Touch Bar Items:
mod._tbItems = {}

-- Touch Bar Item IDs:
mod._tbItemIDs = {}

-- Group Statuses:
mod._groupStatus = {}

--- plugins.core.touchbar.manager.closeBox
--- Constant
--- An optional boolean, specifying whether or not the system 
--- escape (or its current replacement) button should be replaced by a button 
--- to remove the modal bar from the touch bar display when pressed.
mod.dismissButton = true

--- plugins.core.touchbar.manager.maxItems
--- Constant
--- The maximum number of Touch Bar items per group.
mod.maxItems = 8

--- plugins.core.touchbar.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableTouchBar", false):watch(function(enabled)
	if enabled then
		mod.start()
	else
		mod.stop()
	end
end)

--- plugins.core.touchbar.manager.buttons <cp.prop: table>
--- Field
--- Contains all the saved Touch Bar Buttons
mod._items = config.prop("touchBarButtons", {})

--- plugins.core.touchbar.manager.supported <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the Touch Bar is supported on this version of macOS.
mod.supported = prop(function() return touchbar.supported() end)

function mod.touchBar()
	return mod._touchBar or nil
end

function mod.clear()
	mod._items({})
	mod.update()
end

function mod.updateIcon(button, group, icon)
	local buttons = mod._items()
	
	button = tostring(button)
	
	if not buttons[group] then	
		buttons[group] = {}
	end
	if not buttons[group][button] then
		buttons[group][button] = {}
	end
	buttons[group][button]["icon"] = icon
	
	mod._items(buttons)
	mod.update()
end

function mod.updateAction(button, group, action)

	if action == i18n("none") then
		return
	end
	
	local buttons = mod._items()
	
	button = tostring(button)
	if not buttons[group] then	
		buttons[group] = {}
	end
	if not buttons[group][button] then
		buttons[group][button] = {}
	end
	buttons[group][button]["action"] = action
	
	mod._items(buttons)
	mod.update()
end

function mod.updateLabel(button, group, label)
	local buttons = mod._items()
	
	button = tostring(button)
	
	if not buttons[group] then	
		buttons[group] = {}
	end
	if not buttons[group][button] then
		buttons[group][button] = {}
	end
	buttons[group][button]["label"] = label

	mod._items(buttons)
	mod.update()
end

function mod.getIcon(button, group)
	local items = mod._items()	
	if items[group] and items[group][button] and items[group][button]["icon"] then
		return items[group][button]["icon"]
	else
		return nil
	end	
end

function mod.getAction(button, group)
	local items = mod._items()	
	if items[group] and items[group][button] and items[group][button]["action"] then
		return items[group][button]["action"]
	else
		return nil
	end	
end

function mod.getLabel(button, group)
	local items = mod._items()	
	if items[group] and items[group][button] and items[group][button]["label"] then
		return items[group][button]["label"]
	else
		return nil
	end	
end


function mod.start()
		
	if not mod._bar then 	
		mod._bar = touchbar.bar.new()		
	
		--------------------------------------------------------------------------------
		-- Setup System Icon:
		--------------------------------------------------------------------------------
		mod._sysTrayIcon = touchbar.item.newButton(hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon), "CommandPost")
							 :callback(function(self) 
								self:presentModalBar(mod._bar, mod.dismissButton)
							 end)
							 :addToSystemTray(true)
							 
		--------------------------------------------------------------------------------
		-- Update Touch Bar:
		--------------------------------------------------------------------------------							 
		mod.update()
	end
	
end							 

function mod.stop()
	if mod._bar then
		mod._bar:dismissModalBar()
		mod._bar = nil
		mod._sysTrayIcon = nil
	end
end

local function buttonCallback(item)
	
	local id = item:identifier()	
	local idTable = tools.split(id, "_")
	local group = idTable[1]
	local button = idTable[2]		
	local action = mod.getAction(button, group)	
	
	--log.df("action: %s", action)
	commands.group(group):get(action):pressed()
	
end

local function addButton(icon, action, label, id)
	if not label then
		label = ""
	end
	if icon then 
		icon = image.imageFromURL(icon):setSize({w=36,h=36})
	end	
	table.insert(mod._tbItemIDs, id)	
	if icon then 
		--log.df("Adding button with icon")		
		table.insert(mod._tbItems, touchbar.item.newButton(label, icon, id):callback(buttonCallback))		
	else
		--log.df("Adding button without icon")
		table.insert(mod._tbItems, touchbar.item.newButton(label, id):callback(buttonCallback))
	end
end

function mod.activeGroup()
	
	local groupStatus = mod._groupStatus
	for group, status in pairs(groupStatus) do
		if status then
			return group
		end
	end
	return "global"
	
end

function mod.update()
	
	log.df("Updating Touch Bar Content")
	
	--------------------------------------------------------------------------------
	-- Reset the Touch Bar items:
	--------------------------------------------------------------------------------
	mod._tbItems = {}
	mod._tbItemIDs = {}
	
	--------------------------------------------------------------------------------
	-- Create new buttons:
	--------------------------------------------------------------------------------
	local items = mod._items()	
	for groupID, group in pairs(items) do
		if groupID == mod.activeGroup() then 	
			for buttonID, button in pairs(group) do		
				if button["action"] then
							
					local action 		= button["action"] or nil
					local label 		= button["label"] or nil
					local icon 			= button["icon"] or nil
					local id 			= groupID .. "_" .. buttonID
														
					addButton(icon, action, label, id)
										
				end			
			end
		end
	end
	
	--------------------------------------------------------------------------------
	-- Put the buttons in the correct order:
	--------------------------------------------------------------------------------
	table.sort(mod._tbItemIDs)
		
	--------------------------------------------------------------------------------
	-- Add buttons to the bar:
	--------------------------------------------------------------------------------	
	mod._bar
		:templateItems(mod._tbItems)
		:customizableIdentifiers(mod._tbItemIDs)
		:requiredIdentifiers(mod._tbItemIDs)	
		:defaultIdentifiers(mod._tbItemIDs)
		:presentModalBar()
		
end

function mod.groupStatus(groupID, status)

	mod._groupStatus[groupID] = status
	mod.update()
	
end

--------------------------------------------------------------------------------
-- 
-- THE MODULE - VIRTUAL TOUCH BAR:
--
--------------------------------------------------------------------------------
mod.virtual = {}

mod.virtual.LOCATION_DRAGGABLE 	= "Draggable"
mod.virtual.LOCATION_MOUSE		= "Mouse"
mod.virtual.DEFAULT_VALUE 		= mod.virtual.LOCATION_DRAGGABLE

--- plugins.core.touchbar.manager.virtual.lastLocation <cp.prop: point table>
--- Field
--- The last known Virtual Touch Bar Location
mod.virtual.lastLocation = config.prop("lastVirtualTouchBarLocation")

--- plugins.finalcutpro.touchbar.virtual.location <cp.prop: string>
--- Field
--- The Virtual Touch Bar Location Setting
mod.virtual.location = config.prop("displayVirtualTouchBarLocation", mod.virtual.DEFAULT_VALUE):watch(function() mod.virtual.update() end)

--- plugins.core.touchbar.manager.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.virtual.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
	--------------------------------------------------------------------------------
	-- Check for compatibility:
	--------------------------------------------------------------------------------
	if enabled and not mod.supported() then
		dialog.displayMessage(i18n("touchBarError"))
		mod.enabled(false)
	end
	if not enabled then
		mod.virtual.stop()
	end
end)

--- plugins.core.touchbar.manager.virtual.isActive <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the plugin is enabled and the TouchBar is supported on this OS.
mod.virtual.isActive = mod.virtual.enabled:AND(mod.supported):watch(function(active)
	if active then
		mod.virtual.show()
	else
		mod.virtual.hide()
	end
end)

--- plugins.core.touchbar.manager.virtual.start() -> none
--- Function
--- Initialises the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.start()
	if mod.supported() and not mod._touchBar then
	
		--------------------------------------------------------------------------------
		-- Set up Touch Bar:
		--------------------------------------------------------------------------------
		mod._touchBar = touchbar.new()	

		--------------------------------------------------------------------------------
		-- Touch Bar Watcher:
		--------------------------------------------------------------------------------
		mod._touchBar:setCallback(mod.virtual.callback)

		--------------------------------------------------------------------------------
		-- Get last Touch Bar Location from Settings:
		--------------------------------------------------------------------------------
		local lastTouchBarLocation = mod.virtual.lastLocation()
		if lastTouchBarLocation ~= nil then	mod._touchBar:topLeft(lastTouchBarLocation) end

		--------------------------------------------------------------------------------
		-- Draggable Touch Bar:
		--------------------------------------------------------------------------------
		local events = eventtap.event.types
		mod.keyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
			if mod.mouseInsideTouchbar and mod.virtual.location() == mod.virtual.LOCATION_DRAGGABLE then
				if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
					mod._touchBar:backgroundColor{ red = 1 }
									:movable(true)
									:acceptsMouseEvents(false)
				elseif ev:getType() ~= events.leftMouseDown then
					mod._touchBar:backgroundColor{ white = 0 }
								  :movable(false)
								  :acceptsMouseEvents(true)
					mod.virtual.lastLocation(mod._touchBar:topLeft())
				end
			end
			return false
		end):start()

		mod.virtual.update()

	end
end

--- plugins.core.touchbar.manager.virtual.stop() -> none
--- Function
--- Stops the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.stop()
	if mod._touchBar then 
		mod._touchBar:hide()
		mod._touchBar = nil
		collectgarbage() -- See: https://github.com/asmagill/hammerspoon_asm/issues/10#issuecomment-303290853
	end		
	if mod.keyboardWatcher then 
		mod.keyboardWatcher:stop()
		mod.keyboardWatcher = nil
	end
end


--- plugins.finalcutpro.touchbar.virtual.updateLocation() -> none
--- Function
--- Updates the Location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.updateLocation()
	
	--------------------------------------------------------------------------------
	-- Get Settings:
	--------------------------------------------------------------------------------
	local displayTouchBarLocation = mod.virtual.location()

	--------------------------------------------------=-----------------------------
	-- Put it back to last known position:
	--------------------------------------------------------------------------------
	local lastLocation = mod.virtual.lastLocation()
	if lastLocation then
		mod._touchBar:topLeft(lastLocation)
	end
	
	--------------------------------------------------------------------------------
	-- Trigger Callbacks:
	--------------------------------------------------------------------------------
	local updateLocationCallbacks = mod.virtual.updateLocationCallback:getAll()
	if updateLocationCallbacks and type(updateLocationCallbacks) == "table" then
		for i, v in pairs(updateLocationCallbacks) do
			local fn = v:callbackFn()
			if fn and type(fn) == "function" then
				fn()				
			end
		end
	end
	
	--------------------------------------------------------------------------------
	-- Save last Touch Bar Location to Settings:
	--------------------------------------------------------------------------------
	mod.virtual.lastLocation(mod._touchBar:topLeft())
end

--- plugins.core.touchbar.manager.virtual.show() -> none
--- Function
--- Show the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.show()
	--------------------------------------------------------------------------------
	-- Check if we need to show the Touch Bar:
	--------------------------------------------------------------------------------
	if mod.supported() and mod.virtual.enabled() then
		mod.virtual.start()
		mod.virtual.updateLocation()
		mod._touchBar:show()
	end
end

--- plugins.core.touchbar.manager.virtual.hide() -> none
--- Function
--- Hide the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.hide()
	if mod.supported() and mod.virtual.enabled() and mod._touchBar then
		mod._touchBar:hide()
	end
end

--- plugins.core.touchbar.manager.virtual.callback() -> none
--- Function
--- Callback Function for the Virtual Touch Bar
---
--- Parameters:
---  * obj - the touchbarObject the callback is for
---  * message - the message to the callback, either "didEnter" or "didExit"
---
--- Returns:
---  * None
function mod.virtual.callback(obj, message)
	if message == "didEnter" then
		mod.mouseInsideTouchbar = true
	elseif message == "didExit" then
		mod.mouseInsideTouchbar = false

		--------------------------------------------------------------------------------
		-- Just in case we got here before the eventtap returned the Touch Bar to normal:
		--------------------------------------------------------------------------------
		mod._touchBar:movable(false)
		mod._touchBar:acceptsMouseEvents(true)
		mod.virtual.lastLocation(mod._touchBar:topLeft())
	end
end

--- plugins.core.touchbar.manager.virtual.update() -> none
--- Function
--- Updates the visibility and location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.virtual.update()
	-- Check if it's active.
	mod.virtual.isActive:update()
end

--------------------------------------------------------------------------------
--
-- LOCATION OVERRIDE CALLBACK:
--
--------------------------------------------------------------------------------

local updateLocationCallback = {}
updateLocationCallback._items = {}

mod.virtual.updateLocationCallback = updateLocationCallback

--- cp.config.updateLocationCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new File Dropped to Dock Icon Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function updateLocationCallback:new(id, callbackFn)

	if updateLocationCallback._items[id] ~= nil then
		error("Duplicate Update Location Callback: " .. id)
	end
	local o = {
		_id = id,
		_callbackFn = callbackFn,
	}
	setmetatable(o, self)
	self.__index = self

	updateLocationCallback._items[id] = o
	return o

end

--- cp.config.updateLocationCallback:get(id) -> table
--- Method
--- Creates a new Dock Icon Click Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function updateLocationCallback:get(id)
	return self._items[id]
end

--- cp.config.updateLocationCallback:getAll() -> table
--- Method
--- Returns all of the created Dock Icon Click Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function updateLocationCallback:getAll()
	return self._items
end

--- cp.config.updateLocationCallback:id() -> string
--- Method
--- Returns the ID of the current Dock Icon Click Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current File Dropped to Dock Icon Callback as a `string`
function updateLocationCallback:id()
	return self._id
end

--- cp.config.updateLocationCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Dock Icon Click Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function updateLocationCallback:callbackFn()
	return self._callbackFn
end

--------------------------------------------------------------------------------
-- 
-- THE MODULE:
--
--------------------------------------------------------------------------------
function mod.init(deps, env)
	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id			= "core.touchbar.manager",
	group		= "core",
	required	= true,
	dependencies	= {
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

function plugin.postInit(deps, env)

	--------------------------------------------------------------------------------
	-- Setup Physical Touch Bar Buttons:
	--------------------------------------------------------------------------------
	if mod.enabled() then
		mod.start()						 
		mod.update()
	end	
end

return plugin