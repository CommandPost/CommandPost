--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       F C P X   H A C K S   V O I C E   C O M M A N D S   P L U G I N      --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://latenitefilms.com).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local module = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------

local eventtap								= require("hs.eventtap")
local speech   								= require("hs.speech")
local listener								= speech.listener

local fcp									= require("hs.finalcutpro")

local dialog								= require("hs.fcpxhacks.modules.dialog")

--------------------------------------------------------------------------------
-- LISTENER COMMANDS:
--------------------------------------------------------------------------------

local function openFinalCutPro()
	fcp.launch()
end

local function openCommandEditor()
	if fcp.running() then
		fcp.launch()
		fcp:app():commandEditor():show()
	end
end

local listenerCommands = {
						 	["Keyboard Shortcuts"] 		= function() openCommandEditor() end,
						 	["Scrolling Timeline"] 		= function() toggleScrollingTimeline() end,
						 	["Highlight"]				= function() highlightFCPXBrowserPlayhead() end,
						 	["Reveal"]					= function() matchFrameThenHighlightFCPXBrowserPlayhead() end,
						 	["Lane 1"]					= function() selectClipAtLane(1) end,
						 	["Lane 2"]					= function() selectClipAtLane(2) end,
						 	["Lane 3"]					= function() selectClipAtLane(3) end,
						 	["Lane 4"]					= function() selectClipAtLane(4) end,
						 	["Lane 5"]					= function() selectClipAtLane(5) end,
						 	["Lane 6"]					= function() selectClipAtLane(6) end,
						 	["Lane 7"]					= function() selectClipAtLane(7) end,
						 	["Lane 8"]					= function() selectClipAtLane(8) end,
						 	["Lane 9"]					= function() selectClipAtLane(9) end,
						 	["Lane 10"]					= function() selectClipAtLane(10) end,
						 	["Play"]					= function() eventtap.keyStroke({}, "space") end,
						 }

--------------------------------------------------------------------------------
-- LISTENER CALLBACK:
--------------------------------------------------------------------------------
local listenerCallback = function(listenerObj, text)
	module.talker:speak(text)
	listenerCommands[text]()
end

--------------------------------------------------------------------------------
-- NEW:
--------------------------------------------------------------------------------
module.new = function()

	module.listener = listener.new("FCPX Hacks")
	if module.listener ~= nil then
		local commands = {}
		for i,v in pairs(listenerCommands) do
			commands[#commands + 1] = i
		end
		module.listener:foregroundOnly(false)
					   :blocksOtherRecognizers(true)
					   :commands(commands)
					   :setCallback(listenerCallback)
	else
		dialog.displayMessage("Dictation Commands could not be activated.\n\nPlease try again.")
	end

	module.talker = speech.new()

end

--------------------------------------------------------------------------------
-- START:
--------------------------------------------------------------------------------
module.start = function()

	if module.listener == nil then
		module.new()
	end
	if module.listener ~= nil then
		module.listener:start()
	end

end

--------------------------------------------------------------------------------
-- STOP:
--------------------------------------------------------------------------------
module.stop = function()

	if module.listener ~= nil then
		module.listener:delete()
		module.listener = nil
		module.talker = nil
	end

end


--------------------------------------------------------------------------------
-- IS LISTENING:
--------------------------------------------------------------------------------
module.isListening = function()

	if module.listener ~= nil then
		return module.listener:isListening()
	else
		return nil
	end

end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------
return module