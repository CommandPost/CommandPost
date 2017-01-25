-- Imports
local fcp							= require("hs.finalcutpro")
local settings						= require("hs.settings")
local clipboard						= require("hs.fcpxhacks.modules.clipboard")
local log							= require("hs.logger").new("matchframe")

-- Local Functions

--------------------------------------------------------------------------------
-- NINJA PASTEBOARD COPY:
--------------------------------------------------------------------------------
local function ninjaPasteboardCopy()

	local errorFunction = " Error occurred in ninjaPasteboardCopy()."

	--------------------------------------------------------------------------------
	-- Variables:
	--------------------------------------------------------------------------------
	local ninjaPasteboardCopyError = false
	local finalCutProClipboardUTI = fcp:getPasteboardUTI()
	local enableClipboardHistory = settings.get("fcpxHacks.enableClipboardHistory") or false

	--------------------------------------------------------------------------------
	-- Stop Watching Clipboard:
	--------------------------------------------------------------------------------
	if enableClipboardHistory then clipboard.stopWatching() end

	--------------------------------------------------------------------------------
	-- Save Current Clipboard Contents for later:
	--------------------------------------------------------------------------------
	local originalClipboard = clipboard.readFCPXData()

	--------------------------------------------------------------------------------
	-- Trigger 'copy' from Menubar:
	--------------------------------------------------------------------------------
	local menuBar = fcp:menuBar()
	if menuBar:isEnabled("Edit", "Copy") then
		menuBar:selectMenu("Edit", "Copy")
	else
		log.d("ERROR: Failed to select Copy from Menubar." .. errorFunction)
		if enableClipboardHistory then clipboard.startWatching() end
		return false
	end

	--------------------------------------------------------------------------------
	-- Wait until something new is actually on the Pasteboard:
	--------------------------------------------------------------------------------
	local newClipboard = nil
	just.doUntil(function()
		newClipboard = clipboard.readFCPXData()
		if newClipboard ~= originalClipboard then
			return true
		end
	end, 10, 0.1)
	if newClipboard == nil then
		log.d("ERROR: Failed to get new clipboard contents." .. errorFunction)
		if enableClipboardHistory then clipboard.startWatching() end
		return false
	end

	--------------------------------------------------------------------------------
	-- Restore Original Clipboard Contents:
	--------------------------------------------------------------------------------
	if originalClipboard ~= nil then
		local result = clipboard.writeFCPXData(originalClipboard)
		if not result then
			log.d("ERROR: Failed to restore original Clipboard item." .. errorFunction)
			if enableClipboardHistory then clipboard.startWatching() end
			return false
		end
	end

	--------------------------------------------------------------------------------
	-- Start Watching Clipboard:
	--------------------------------------------------------------------------------
	if enableClipboardHistory then clipboard.startWatching() end

	--------------------------------------------------------------------------------
	-- Return New Clipboard:
	--------------------------------------------------------------------------------
	return true, newClipboard

end

-- The Module
local mod = {}

--------------------------------------------------------------------------------
-- PERFORM MULTICAM MATCH FRAME:
--------------------------------------------------------------------------------
function mod.multicamMatchFrame(goBackToTimeline) -- True or False

	local errorFunction = "\n\nError occurred in multicamMatchFrame()."

	--------------------------------------------------------------------------------
	-- Just in case:
	--------------------------------------------------------------------------------
	if goBackToTimeline == nil then goBackToTimeline = true end
	if type(goBackToTimeline) ~= "boolean" then goBackToTimeline = true end

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	deleteAllHighlights()

	local contents = fcp:timeline():contents()

	--------------------------------------------------------------------------------
	-- Store the originally-selected clips
	--------------------------------------------------------------------------------
	local originalSelection = contents:selectedClipsUI()

	--------------------------------------------------------------------------------
	-- If nothing is selected, select the top clip under the playhead:
	--------------------------------------------------------------------------------
	if not originalSelection or #originalSelection == 0 then
		local playheadClips = contents:playheadClipsUI(true)
		contents:selectClip(playheadClips[1])
	elseif #originalSelection > 1 then
		log.d("Unable to match frame on multiple clips." .. errorFunction)
		return false
	end

	--------------------------------------------------------------------------------
	-- Get Multicam Angle:
	--------------------------------------------------------------------------------
	local multicamAngle = mod.getMulticamAngleFromSelectedClip()
	if multicamAngle == false then
		log.d("The selected clip is not a multicam clip." .. errorFunction)
		contents:selectClips(originalSelection)
		return false
	end

	--------------------------------------------------------------------------------
	-- Open in Angle Editor:
	--------------------------------------------------------------------------------
	local menuBar = fcp:menuBar()
	if menuBar:isEnabled("Clip", "Open Clip") then
		menuBar:selectMenu("Clip", "Open Clip")
	else
		dialog.displayErrorMessage("Failed to open clip in Angle Editor.\n\nAre you sure the clip you have selected is a Multicam?" .. errorFunction)
		return false
	end

	--------------------------------------------------------------------------------
	-- Put focus back on the timeline:
	--------------------------------------------------------------------------------
	if menuBar:isEnabled("Window", "Go To", "Timeline") then
		menuBar:selectMenu("Window", "Go To", "Timeline")
	else
		dialog.displayErrorMessage("Unable to return to timeline." .. errorFunction)
		return false
	end

	--------------------------------------------------------------------------------
	-- Ensure the playhead is visible:
	--------------------------------------------------------------------------------
	contents:playhead():show()

	contents:selectClipInAngle(multicamAngle)

	--------------------------------------------------------------------------------
	-- Reveal In Browser:
	--------------------------------------------------------------------------------
	if menuBar:isEnabled("File", "Reveal in Browser") then
		menuBar:selectMenu("File", "Reveal in Browser")
	end

	--------------------------------------------------------------------------------
	-- Go back to original timeline if appropriate:
	--------------------------------------------------------------------------------
	if goBackToTimeline then
		if menuBar:isEnabled("View", "Timeline History Back") then
			menuBar:selectMenu("View", "Timeline History Back")
		else
			dialog.displayErrorMessage("Unable to go back to previous timeline." .. errorFunction)
			return false
		end
	end

	--------------------------------------------------------------------------------
	-- Select the original clips again.
	--------------------------------------------------------------------------------
	contents:selectClips(originalSelection)

	--------------------------------------------------------------------------------
	-- Highlight Browser Playhead:
	--------------------------------------------------------------------------------
	mod.browserPlayhead.highlight()

end

--------------------------------------------------------------------------------
-- GET MULTICAM ANGLE FROM SELECTED CLIP:
--------------------------------------------------------------------------------
function mod.getMulticamAngleFromSelectedClip()

	local errorFunction = "\n\nError occurred in getMulticamAngleFromSelectedClip()."

	--------------------------------------------------------------------------------
	-- Ninja Pasteboard Copy:
	--------------------------------------------------------------------------------
	local result, clipboardData = ninjaPasteboardCopy()
	if not result then
		log.e("ERROR: Ninja Pasteboard Copy Failed." .. errorFunction)
		return false
	end

	--------------------------------------------------------------------------------
	-- Convert Binary Data to Table:
	--------------------------------------------------------------------------------
	local fcpxTable = clipboard.unarchiveFCPXData(clipboardData)
	if fcpxTable == nil then
		log.e("ERROR: Converting Binary Data to Table failed." .. errorFunction)
		return false
	end

	local timelineClip = fcpxTable.root.objects[1]
	if not clipboard.isTimelineClip(timelineClip) then
		log.e("ERROR: Not copied from the Timeline." .. errorFunction)
		return false
	end

	local selectedClips = timelineClip.containedItems
	if #selectedClips ~= 1 or clipboard.getClassname(selectedClips[1]) ~= "FFAnchoredAngle" then
		log.e("ERROR: Expected a single Multicam clip to be copied." .. errorFunction)
		return false
	end

	local multicamClip = selectedClips[1]
	local videoAngle = multicamClip.videoAngle

	--------------------------------------------------------------------------------
	-- Find the original media:
	--------------------------------------------------------------------------------
	local mediaId = multicamClip.media.mediaIdentifier
	local media = nil
	for i,item in ipairs(fcpxTable.media) do
		if item.mediaIdentifier == mediaId then
			media = item
			break
		end
	end

	if media == nil or not media.primaryObject or not media.primaryObject.isMultiAngle then
		log.d("ERROR: Couldn't find the media for the multicam clip.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Find the Angle
	--------------------------------------------------------------------------------

	local angles = media.primaryObject.containedItems[1].anchoredItems
	for i,angle in ipairs(angles) do
		if angle.angleID == videoAngle then
			return angle.anchoredLane
		end
	end

	log.d("ERROR: Failed to get anchoredLane." .. errorFunction)
	return false
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.commands.fcpx"]		= "fcpxCmds",
	["hs.fcpxhacks.plugins.browser.playhead"]	= "browserPlayhead",
}


function plugin.init(deps)
	-- Commands
	local cmds = deps.fcpxCmds
	cmds:add("FCPXHackRevealMulticamClipInBrowserAndHighlight")
		:activatedBy():ctrl():option():cmd("d")
		:whenActivated(function() mod.multicamMatchFrame(true) end)
	
	cmds:add("FCPXHackRevealMulticamClipInAngleEditorAndHighlight")
		:activatedBy():ctrl():option():cmd("g")
		:whenActivated(function() mod.multicamMatchFrame(false) end)
		
	mod.browserPlayhead = deps.browserPlayhead
		
	return mod	
end

return plugin