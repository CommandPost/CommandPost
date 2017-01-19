-- Manages features relating to the Timeline Playhead

-- Imports

local settings					= require("hs.settings")
local geometry					= require("hs.geometry")
local eventtap					= require("hs.eventtap")
local mouse						= require("hs.mouse")

local dialog					= require("hs.fcpxhacks.modules.dialog")
local fcp						= require("hs.finalcutpro")
local hacksconsole				= require("hs.fcpxhacks.modules.hacksconsole")

local log						= require("hs.logger").new("playhead")

-- Constants

local PRIORITY = 1000

-- The Module

local mod = {}

local manager

function mod.isScrollingTimelineActive()
	return settings.get("fcpxHacks.scrollingTimelineActive") or false
end

function mod.setScrollingTimelineActive(active)
	settings.set("fcpxHacks.scrollingTimelineActive", active)
end

--------------------------------------------------------------------------------
-- TOGGLE SCROLLING TIMELINE:
--------------------------------------------------------------------------------
function mod.toggleScrollingTimeline()

	--------------------------------------------------------------------------------
	-- Toggle Scrolling Timeline:
	--------------------------------------------------------------------------------
	if mod.isScrollingTimelineActive() then
		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		mod.setScrollingTimelineActive(false)

		--------------------------------------------------------------------------------
		-- Stop Watchers:
		--------------------------------------------------------------------------------
		mod.updateScrollingTimelineWatcher()

		--------------------------------------------------------------------------------
		-- Unlock the playhead.
		--------------------------------------------------------------------------------
		fcp:timeline():unlockPlayhead()

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		dialog.displayNotification(i18n("scrollingTimelineDeactivated"))

	else
		--------------------------------------------------------------------------------
		-- Ensure that Playhead Lock is Off:
		--------------------------------------------------------------------------------
		local message = ""
		local lockTimelinePlayhead = mod.isPlayheadLocked()
		if lockTimelinePlayhead then
			mod.togglePlayheadLock()
			message = i18n("playheadLockDeactivated") .. "\n"
		end

		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		mod.setScrollingTimelineActive(true)

		--------------------------------------------------------------------------------
		-- Start Watchers:
		--------------------------------------------------------------------------------
		mod.updateScrollingTimelineWatcher()

		--------------------------------------------------------------------------------
		-- If activated whilst already playing, then turn on Scrolling Timeline:
		--------------------------------------------------------------------------------
		mod.checkScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		dialog.displayNotification(message..i18n("scrollingTimelineActivated"))

	end

	--------------------------------------------------------------------------------
	-- Refresh Menu Bar:
	--------------------------------------------------------------------------------
	manager.refreshMenuBar()

end

--------------------------------------------------------------------------------
-- Ensures the Scrolling Timeline Watcher is in the correct mode.
--------------------------------------------------------------------------------
function mod.updateScrollingTimelineWatcher()
	local watcher = mod.getScrollingTimelineWatcher()
	if mod.isScrollingTimelineActive() and fcp:isFrontmost() then
		watcher:start()
	elseif watcher:isEnabled() then
		watcher:stop()
	end
end

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
local SPACEBAR_KEYCODE = 49

function mod.getScrollingTimelineWatcher()
	if not mod._scrollingTimelineWatcher then
		mod._scrollingTimelineWatcher = eventtap.new(
			{ eventtap.event.types.keyDown }, 
			function(event)
				--------------------------------------------------------------------------------
				-- Don't do anything if we're already locked.
				--------------------------------------------------------------------------------
				if event:getKeyCode() == SPACEBAR_KEYCODE 
				   and next(event:getFlags()) == nil
				   and not fcp:timeline():isLockedPlayhead() then
					--------------------------------------------------------------------------------
					-- Spacebar Pressed:
					--------------------------------------------------------------------------------
					mod.checkScrollingTimeline()
				end
				return false
			end
		)
	end
	return mod._scrollingTimelineWatcher
end

--------------------------------------------------------------------------------
-- CHECK TO SEE IF WE SHOULD ACTUALLY TURN ON THE SCROLLING TIMELINE:
--------------------------------------------------------------------------------
function mod.checkScrollingTimeline()

	--------------------------------------------------------------------------------
	-- Make sure the Command Editor and hacks console are closed:
	--------------------------------------------------------------------------------
	if fcp:commandEditor():isShowing() or hacksconsole.active then
		debugMessage("Spacebar pressed while other windows are visible.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Don't activate scrollbar in fullscreen mode:
	--------------------------------------------------------------------------------
	if fcp:fullScreenWindow():isShowing() then
		debugMessage("Spacebar pressed in fullscreen mode whilst watching for scrolling timeline.")
		return false
	end

	local timeline = fcp:timeline()

	--------------------------------------------------------------------------------
	-- Get Timeline Scroll Area:
	--------------------------------------------------------------------------------
	if not timeline:isShowing() then
		writeToConsole("ERROR: Could not find Timeline Scroll Area.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Check mouse is in timeline area:
	--------------------------------------------------------------------------------
	local mouseLocation = geometry.point(mouse.getAbsolutePosition())
	local viewFrame = geometry.rect(timeline:contents():viewFrame())
	if mouseLocation:inside(viewFrame) then

		--------------------------------------------------------------------------------
		-- Mouse is in the timeline area when spacebar pressed so LET'S DO IT!
		--------------------------------------------------------------------------------
		debugMessage("Mouse inside Timeline Area.")
		timeline:lockPlayhead(true)
		return true
	else
		debugMessage("Mouse outside of Timeline Area.")
		return false
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- PLAYHEAD LOCK:
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function mod.isPlayheadLocked()
	return settings.get("fcpxHacks.lockTimelinePlayhead") or false
end

function mod.setPlayheadLocked(locked)
	settings.set("fcpxHacks.lockTimelinePlayhead", locked)
end

--------------------------------------------------------------------------------
-- TOGGLE LOCK PLAYHEAD:
--------------------------------------------------------------------------------
function mod.togglePlayheadLock()
	local lockTimelinePlayhead = mod.isPlayheadLocked()

	if lockTimelinePlayhead then
		if fcp:isRunning() then
			fcp:timeline():unlockPlayhead()
		end
		dialog.displayNotification(i18n("playheadLockDeactivated"))
		mod.setPlayheadLocked(false)
	else
		local message = ""
		--------------------------------------------------------------------------------
		-- Ensure that Scrolling Timeline is off
		--------------------------------------------------------------------------------
		local scrollingTimeline = mod.isScrollingTimelineActive()
		if scrollingTimeline then
			mod.toggleScrollingTimeline()
			message = i18n("scrollingTimelineDeactivated") .. "\n"
		end
		
		if fcp:isRunning() then
			fcp:timeline():lockPlayhead()
		end
		dialog.displayNotification(message .. i18n("playheadLockActivated"))
		mod.setPlayheadLocked(true)
	end

	manager.refreshMenuBar()
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.menu.manager"]				= "manager",
	["hs.fcpxhacks.plugins.menu.automation.options"] 	= "options",
}

function plugin.init(deps)
	manager = deps.manager
	
	local section = deps.options:addSection(PRIORITY)
	
	section:addItems(1000, function()
		return {
			{ title = i18n("enableScrollingTimeline"),		fn = mod.toggleScrollingTimeline, 	checked = mod.isScrollingTimelineActive() },
			{ title = i18n("enableTimelinePlayheadLock"),	fn = mod.togglePlayheadLock,		checked = mod.isPlayheadLocked()},
		}
	end)
	
	fcp:watch(
		{
			active 		= function() mod.updateScrollingTimelineWatcher() end,
			inactive	= function() mod.updateScrollingTimelineWatcher() end,
		}
	)
	
	return mod
end

return plugin