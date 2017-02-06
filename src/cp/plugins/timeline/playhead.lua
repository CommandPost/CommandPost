-- Manages features relating to the Timeline Playhead

-- Imports

local geometry					= require("hs.geometry")
local eventtap					= require("hs.eventtap")
local mouse						= require("hs.mouse")

local dialog					= require("cp.dialog")
local fcp						= require("cp.finalcutpro")
local hacksconsole				= require("cp.fcpx10-3.hacksconsole")
local metadata					= require("cp.metadata")

local log						= require("hs.logger").new("playhead")

-- Constants

local PRIORITY = 1000

-- The Module

local mod = {}

function mod.isScrollingTimelineActive()
	return metadata.get("scrollingTimelineActive", false)
end

function mod.setScrollingTimelineActive(active)
	metadata.set("scrollingTimelineActive", active)
	mod.update()
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
		-- Unlock the playhead.
		--------------------------------------------------------------------------------
		fcp:timeline():unlockPlayhead()

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		dialog.displayNotification(i18n("scrollingTimelineDeactivated"))

	else
		local message = ""

		--------------------------------------------------------------------------------
		-- Ensure that Playhead Lock is Off:
		--------------------------------------------------------------------------------
		if mod.isPlayheadLocked() then
			mod.setPlayheadLocked(false)
			message = i18n("playheadLockDeactivated") .. "\n"
		end

		--------------------------------------------------------------------------------
		-- Update Settings:
		--------------------------------------------------------------------------------
		mod.setScrollingTimelineActive(true)

		--------------------------------------------------------------------------------
		-- If activated whilst already playing, then turn on Scrolling Timeline:
		--------------------------------------------------------------------------------
		mod.checkScrollingTimeline()

		--------------------------------------------------------------------------------
		-- Display Notification:
		--------------------------------------------------------------------------------
		dialog.displayNotification(message..i18n("scrollingTimelineActivated"))

	end
end

--------------------------------------------------------------------------------
-- Ensures the Scrolling Timeline/Playhead Lock are in the correct mode
--------------------------------------------------------------------------------
function mod.update()
	local scrolling	= mod.isScrollingTimelineActive()
	local locked	= mod.isPlayheadLocked()

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
	local viewFrame = timeline:contents():viewFrame()
	if viewFrame then
		if mouseLocation:inside(geometry.rect(viewFrame)) then

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
	else
		debugMessage("No viewFrame detected in plugins.timeline.playhead.checkScrollingTimeline().")
		return false
	end

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- PLAYHEAD LOCK:
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function mod.isPlayheadLocked()
	return metadata.get("lockTimelinePlayhead", false)
end

function mod.setPlayheadLocked(locked)
	metadata.set("lockTimelinePlayhead", locked)
	mod.update()
end

--------------------------------------------------------------------------------
-- TOGGLE LOCK PLAYHEAD:
--------------------------------------------------------------------------------
function mod.togglePlayheadLock()
	local lockTimelinePlayhead = mod.isPlayheadLocked()

	if lockTimelinePlayhead then
		mod.setPlayheadLocked(false)
		dialog.displayNotification(i18n("playheadLockDeactivated"))
	else
		local message = ""
		--------------------------------------------------------------------------------
		-- Ensure that Scrolling Timeline is off
		--------------------------------------------------------------------------------
		if mod.isScrollingTimelineActive() then
			mod.setScrollingTimelineActive(false)
			message = i18n("scrollingTimelineDeactivated") .. "\n"
		end
		mod.setPlayheadLocked(true)
		dialog.displayNotification(message .. i18n("playheadLockActivated"))
	end
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.timeline"] 	= "options",
	["cp.plugins.commands.fcpx"]				= "fcpxCmds",
}

function plugin.init(deps)
	local section = deps.options:addSection(PRIORITY)

	-- menu items
	section:addItems(1000, function()
		return {
			{ title = i18n("enableScrollingTimeline"),		fn = mod.toggleScrollingTimeline, 	checked = mod.isScrollingTimelineActive() },
			{ title = i18n("enableTimelinePlayheadLock"),	fn = mod.togglePlayheadLock,		checked = mod.isPlayheadLocked()},
		}
	end)

	-- commands
	deps.fcpxCmds:add("FCPXHackScrollingTimeline")
		:activatedBy():ctrl():option():cmd("w")
		:whenActivated(mod.toggleScrollingTimeline)
	deps.fcpxCmds:add("FCPXHackLockPlayhead")
		:whenActivated(mod.togglePlayheadLock)

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