--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.Inspector ===
---
--- Inspector

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("inspector")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local AudioInspector					= require("cp.apple.finalcutpro.inspector.audio.AudioInspector")
local ColorInspector					= require("cp.apple.finalcutpro.inspector.color.ColorInspector")
local ColorBoard						= require("cp.apple.finalcutpro.inspector.color.ColorBoard")
local EffectInspector					= require("cp.apple.finalcutpro.inspector.effect.EffectInspector")
local GeneratorInspector				= require("cp.apple.finalcutpro.inspector.generator.GeneratorInspector")
local InfoInspector						= require("cp.apple.finalcutpro.inspector.info.InfoInspector")
local ShareInspector					= require("cp.apple.finalcutpro.inspector.share.ShareInspector")
local TextInspector						= require("cp.apple.finalcutpro.inspector.text.TextInspector")
local TitleInspector					= require("cp.apple.finalcutpro.inspector.title.TitleInspector")
local TransitionInspector				= require("cp.apple.finalcutpro.inspector.transition.TransitionInspector")
local VideoInspector					= require("cp.apple.finalcutpro.inspector.video.VideoInspector")

local id								= require("cp.apple.finalcutpro.ids") "Inspector"
local colorBoardId						= require("cp.apple.finalcutpro.ids") "ColorBoard"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Inspector = {}

--- cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS -> table
--- Constant
--- Table of supported Inspector Tabs
Inspector.INSPECTOR_TABS = {
	["Audio"] 		= "FFInspectorTabAudio",
	["Color"] 		= "FFInspectorTabColor",
	["Effect"] 		= "FFInspectorTabMotionEffectEffect",
	["Generator"] 	= "FFInspectorTabGenerator",
	["Info"] 		= "FFInspectorTabMetadata",
	["Share"] 		= "FFInspectorTabShare",
	["Text"] 		= "FFInspectorTabMotionEffectText",
	["Title"] 		= "FFInspectorTabMotionEffectTitle",
	["Transition"] 	= "FFInspectorTabMotionEffectTransition",
	["Video"] 		= "FFInspectorTabMotionEffectVideo",
}

--- cp.apple.finalcutpro.inspector.Inspector.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - axuielementObject
---
--- Returns:
---  * `true` if matches otherwise `false`
function Inspector.matches(element)
	return axutils.childWithID(element, id "DetailsPanel") ~= nil -- is inspecting
		or axutils.childWithID(element, id "NothingToInspect") ~= nil 	-- nothing to inspect
		or ColorBoard.matchesOriginal(element) ~= nil -- the 10.3 color board
end

--- cp.apple.finalcutpro.inspector.Inspector:new(parent) -> Inspector
--- Method
--- Creates a new Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:new(parent)
	local o = prop.extend({_parent = parent}, Inspector)

	return o
end

--- cp.apple.finalcutpro.inspector.Inspector:parent() -> Parent
--- Method
--- Returns the parent of the Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.inspector.Inspector:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- INSPECTOR UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:UI() -> axuielementObject
--- Method
--- Returns the Inspectors Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` on `nil`
function Inspector:UI()
	return axutils.cache(self, "_ui",
	function()
		local parent = self:parent()
		local ui = parent:rightGroupUI()
		if ui then
			-----------------------------------------------------------------------
			-- It's in the right panel (full-height):
			-----------------------------------------------------------------------
			if Inspector.matches(ui) then
				return ui
			end
		else
			-----------------------------------------------------------------------
			-- It's in the top-right panel (half-height):
			-----------------------------------------------------------------------
			local top = parent:topGroupUI()
			if top then
				for i,child in ipairs(top) do
					if Inspector.matches(child) then
						return child
					end
				end
			end
		end
		return nil
	end,
	Inspector.matches)
end

--- cp.apple.finalcutpro.inspector.Inspector.isShowing() -> boolean
--- Function
--- Returns `true` if the Inspector is showing otherwise `false`
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
Inspector.isShowing = prop.new(function(self)
	local ui = self:UI()
	return ui ~= nil
end):bind(Inspector)

--- cp.apple.finalcutpro.inspector.Inspector:show([tab]) -> Inspector
--- Method
--- Shows the inspector.
---
--- Parameters:
---  * [tab] - A string from the `cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * The `Inspector` instance.
---
--- Notes:
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:show(tab)
	if tab and Inspector.INSPECTOR_TABS[tab] then
		self:selectTab(tab)
	else
		local parent = self:parent()
		-----------------------------------------------------------------------
		-- Show the parent:
		-----------------------------------------------------------------------
		if parent:show() then
			local menuBar = self:app():menuBar()
			-----------------------------------------------------------------------
			-- Enable it in the primary:
			-----------------------------------------------------------------------
			menuBar:checkMenu({"Window", "Show in Workspace", "Inspector"})
		end
	end
	return self
end

--- cp.apple.finalcutpro.inspector.Inspector:hide() -> Inspector
--- Method
--- Hides the inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Inspector` instance.
function Inspector:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu({"Window", "Show in Workspace", "Inspector"})
	return self
end

function Inspector:topBarUI()
	return axutils.cache(self, "_topBar", function()
		local ui = self:UI()
		return ui and #ui == 3 and axutils.childFromTop(ui, 1) or nil
	end)
end

function Inspector:propertiesUI()
	return axutils.cache(self, "_properties", function()
		local ui = self:UI()
		if ui then
			return (
				(#ui == 3 and axutils.childFromTop(ui, 2)[1]) -- 10.4+ Inspector
				or ColorBoard.matchesOriginal(ui) and ui  -- 10.3 Color Board
				or nil -- not found
			)
		end
		return nil
	end)
end

function Inspector:bottomBarUI()
	return axutils.cache(self, "_bottomBar", function()
		local ui = self:UI()
		return ui and #ui == 3 and axutils.childFromBottom(ui, 1) or nil
	end)
end

--- cp.apple.finalcutpro.inspector.Inspector:selectTab([tab]) -> boolean
--- Method
--- Selects a tab in the inspector.
---
--- Parameters:
---  * [tab] - A string from the `cp.apple.finalcutpro.inspector.Inspector.INSPECTOR_TABS` table
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if an error occurred.
---
--- Notes:
---  * This method will open the Inspector if it's closed, and leave it open.
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectTab(value)
	local code = Inspector.INSPECTOR_TABS[value]
	if not code then
		log.ef("selectTab requires a valid tab string: %s", value)
		return false
	end
	self:show()
	if not self.isShowing() then
		log.ef("Failed to open Inspector")
		return false
	end
	local ui = self:topBarUI()
	local app = self:app()
	local valueTitle = app:string(code)
	for _,subChild in ipairs(ui) do
		local title = subChild:attributeValue("AXTitle")
		if title == valueTitle then
			return subChild:performAction("AXPress")
		end
	end
	return false
end

--- cp.apple.finalcutpro.inspector.Inspector:selectedTab() -> string or nil
--- Method
--- Returns the name of the selected inspector tab otherwise `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if the Inspector is closed or an error occurred.
---
--- Notes:
---  * The tab strings can be:
---    * Audio
---    * Color
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectedTab()
	local ui = self:topBarUI()
	if ui then
		local app = self:app()
		for _,child in ipairs(ui) do
			if child:attributeValue("AXValue") == 1 then
				local title = child:attributeValue("AXTitle")
				if title then
					for value,code in pairs(Inspector.INSPECTOR_TABS) do
						local codeTitle = app:string(code)
						if codeTitle == title then
							return value
						end
					end
				end
			end
		end
	end
	return nil
end

-----------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:video() -> VideoInspector
--- Method
--- Gets the VideoInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector
function Inspector:video()
	if not self._videoInspector then
		self._videoInspector = VideoInspector:new(self)
	end
	return self._videoInspector
end

-----------------------------------------------------------------------
--
-- GENERATOR INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:generator() -> GeneratorInspector
--- Method
--- Gets the GeneratorInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * GeneratorInspector
function Inspector:generator()
	if not self._generatorInspector then
		self._generatorInspector = GeneratorInspector:new(self)
	end
	return self._generatorInspector
end

-----------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:info() -> InfoInspector
--- Method
--- Gets the InfoInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * InfoInspector
function Inspector:info()
	if not self._infoInspector then
		self._infoInspector = InfoInspector:new(self)
	end
	return self._infoInspector
end

-----------------------------------------------------------------------
--
-- EFFECT INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:effect() -> EffectInspector
--- Method
--- Gets the EffectInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * EffectInspector
function Inspector:effect()
	if not self._effectInspector then
		self._effectInspector = EffectInspector:new(self)
	end
	return self._effectInspector
end

-----------------------------------------------------------------------
--
-- TEXT INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:text() -> TextInspector
--- Method
--- Gets the TextInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * TextInspector
function Inspector:text()
	if not self._textInspector then
		self._textInspector = TextInspector:new(self)
	end
	return self._textInspector
end

-----------------------------------------------------------------------
--
-- TITLE INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:title() -> TitleInspector
--- Method
--- Gets the TitleInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * TitleInspector
function Inspector:title()
	if not self._titleInspector then
		self._titleInspector = TitleInspector:new(self)
	end
	return self._titleInspector
end

-----------------------------------------------------------------------
--
-- TRANSITION INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:transition() -> TransitionInspector
--- Method
--- Gets the TransitionInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * TransitionInspector
function Inspector:transition()
	if not self._transitionInspector then
		self._transitionInspector = TransitionInspector:new(self)
	end
	return self._transitionInspector
end

-----------------------------------------------------------------------
--
-- AUDIO INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:audio() -> AudioInspector
--- Method
--- Gets the AudioInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * AudioInspector
function Inspector:audio()
	if not self._audioInspector then
		self._audioInspector = AudioInspector:new(self)
	end
	return self._audioInspector
end

-----------------------------------------------------------------------
--
-- SHARE INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:share() -> ShareInspector
--- Method
--- Gets the ShareInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ShareInspector
function Inspector:share()
	if not self._shareInspector then
		self._shareInspector = ShareInspector:new(self)
	end
	return self._shareInspector
end

-----------------------------------------------------------------------
--
-- COLOR INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.Inspector:color() -> ColorInspector
--- Method
--- Gets the ColorInspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector
function Inspector:color()
	if not self._colorInspector then
		self._colorInspector = ColorInspector:new(self)
	end
	return self._colorInspector
end

return Inspector