--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.playhead ===
---
--- Manages features relating to the Timeline Playhead.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("playhead")

local geometry					= require("hs.geometry")
local eventtap					= require("hs.eventtap")
local mouse						= require("hs.mouse")

local dialog					= require("cp.dialog")
local fcp						= require("cp.apple.finalcutpro")
local config					= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 					= 1000
local SPACEBAR_KEYCODE 			= 49

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- Ensures the Scrolling Timeline/Playhead Lock are in the correct mode
--------------------------------------------------------------------------------
function mod.update()
	local scrolling	= mod.scrollingTimeline()
	local locked	= mod.playheadLocked()

	local watcher = mod.getScrollingTimelineWatcher()

	if fcp:isFrontmost() and (scrolling or locked) then
		fcp:timeline():lockPlayhead(scrolling)
		if scrolling and not watcher:isEnabled() then
			watcher:start()
		end
		if locked and watcher:isEnabled() then
			watcher:stop()
		end
	else
		watcher:stop()
		fcp:timeline():unlockPlayhead()
	end
end

mod.scrollingTimeline = config.prop("scrollingTimelineActive", false):watch(function(active)
	log.df("Updating Scrolling Timeline: %s", active)
	if active then
		local message = ""

		--------------------------------------------------------------------------------
		-- Ensure that Playhead Lock is Off:
		--------------------------------------------------------------------------------
		if mod.playheadLocked() then
			mod.playheadLocked(false)
			message = i18n("playheadLockDeactivated") .. "\n"
			log.df("Message: %s", message)
		end

		--------------------------------------------------------------------------------
		-- If activated whilst already playing, then turn on Scrolling Timeline:
		--------------------------------------------------------------------------------
		mod.checkScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		dialog.displayNotification(message..i18n("scrollingTimelineActivated"))
	elseif not mod.playheadLocked() then
		dialog.displayNotification(i18n("scrollingTimelineDeactivated"))
	end

	mod.update()
end)

--------------------------------------------------------------------------------
-- SCROLLING TIMELINE WATCHER:
--------------------------------------------------------------------------------
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
	-- Make sure the Command Editor is closed:
	--------------------------------------------------------------------------------
	if fcp:commandEditor():isShowing() then
		log.df("Spacebar pressed while other windows are visible.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Don't activate scrollbar in fullscreen mode:
	--------------------------------------------------------------------------------
	if fcp:fullScreenWindow():isShowing() then
		log.df("Spacebar pressed in fullscreen mode whilst watching for scrolling timeline.")
		return false
	end

	local timeline = fcp:timeline()

	--------------------------------------------------------------------------------
	-- Get Timeline Scroll Area:
	--------------------------------------------------------------------------------
	if not timeline:isShowing() then
		log.ef("ERROR: Could not find Timeline Scroll Area.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Check mouse is in timeline area:
	--------------------------------------------------------------------------------
	local mouseLocation = geometry.point(mouse.getAbsolutePosition())
	local viewFrame = timeline:contents():viewFrame()
	if viewFrame then
		if mouseLocation:inside(geometry.rect(viewFrame)) then

			--------------------------------------------------------------------------------
			-- Mouse is in the timeline area when spacebar pressed so LET'S DO IT!
			--------------------------------------------------------------------------------
			log.df("Mouse inside Timeline Area.")
			timeline:lockPlayhead(true)
			return true
		else
			log.df("Mouse outside of Timeline Area.")
			return false
		end
	else
		log.df("No viewFrame detected in plugins.timeline.playhead.checkScrollingTimeline().")
		return false
	end

end

--------------------------------------------------------------------------------
-- PLAYHEAD LOCK:
--------------------------------------------------------------------------------
mod.playheadLocked = config.prop("lockTimelinePlayhead", false):watch(function(active)
	log.df("Updating Playhead Lock: %s", active)
	if active then
		local message = ""
		--------------------------------------------------------------------------------
		-- Ensure that Scrolling Timeline is off
		--------------------------------------------------------------------------------
		if mod.scrollingTimeline() then
			mod.scrollingTimeline(false)
			message = i18n("scrollingTimelineDeactivated") .. "\n"
		end
		-- Notify the user.
		dialog.displayNotification(message .. i18n("playheadLockActivated"))
	elseif not mod.scrollingTimeline() then
		dialog.displayNotification(i18n("playheadLockDeactivated"))
	end
	mod.update()
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.playhead",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.timeline"] 				= "options",
		["finalcutpro.commands"]					= "fcpxCmds",
		["finalcutpro.preferences.app"]				= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	local section = deps.options:addSection(PRIORITY)

	-- menu items
	section:addItems(1000, function()
		return {
			{ title = i18n("enableScrollingTimeline"),		fn = function() mod.scrollingTimeline:toggle() end, 	checked = mod.scrollingTimeline() },
			{ title = i18n("enableTimelinePlayheadLock"),	fn = function() mod.playheadLocked:toggle() end,				checked = mod.playheadLocked() },
		}
	end)

	-- commands
	deps.fcpxCmds:add("cpScrollingTimeline")
		:groupedBy("timeline")
		:activatedBy():ctrl():option():cmd("w")
		:whenActivated(function() mod.scrollingTimeline:toggle() end)
	deps.fcpxCmds:add("cpLockPlayhead")
		:groupedBy("timeline")
		:whenActivated(function() mod.playheadLocked:toggle() end)

	-- watch for changes
	fcp:watch(
		{
			active 		= mod.update,
			inactive	= mod.update,
		}
	)

	return mod
end

return plugin