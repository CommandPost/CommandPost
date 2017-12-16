--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector ===
---
--- Inspector

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local id								= require("cp.apple.finalcutpro.ids") "Inspector"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Inspector = {}

--- cp.apple.finalcutpro.main.Inspector.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - axuielementObject
---
--- Returns:
---  * `true` if matches otherwise `false`
function Inspector.matches(element)
	return axutils.childWith(element, "AXIdentifier", id "DetailsPanel") ~= nil -- is inspecting
		or axutils.childWith(element, "AXIdentifier", id "NothingToInspect") ~= nil 	-- nothing to inspect
end

--- cp.apple.finalcutpro.main.Inspector:new(parent) -> Inspector
--- Method
--- Creates a new Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Inspector:new(parent)
	local o = {_parent = parent}
	return prop.extend(o, Inspector)
end

--- cp.apple.finalcutpro.main.Inspector:parent() -> Parent
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

--- cp.apple.finalcutpro.main.Inspector:app() -> App
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

--- cp.apple.finalcutpro.main.Inspector:UI() -> axuielementObject
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
			-- It's in the top-left panel (half-height):
			-----------------------------------------------------------------------
			local top = parent:topGroupUI()
			for i,child in ipairs(top) do
				if Inspector.matches(child) then
					return child
				end
			end
		end
		return nil
	end,
	Inspector.matches)
end

--- cp.apple.finalcutpro.main.Inspector.isShowing() -> boolean
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

--- cp.apple.finalcutpro.main.Inspector:show() -> Inspector
--- Method
--- Shows the inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Inspector` instance.
function Inspector:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		local menuBar = self:app():menuBar()
		-- Enable it in the primary
		menuBar:checkMenu({"Window", "Show in Workspace", "Inspector"})
	end
	return self
end

--- cp.apple.finalcutpro.main.Inspector:hide() -> Inspector
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

--- cp.apple.finalcutpro.main.Inspector:selectTab([value]) -> boolean or nil
--- Method
--- Selects a tab in the inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the selected tab, otherwise `nil` if an error occurred.
---
--- Notes:
---  * This method will open the Inspector if it's closed, and leave it open.
---  * Valid strings for `value` are as follows:
---    * Audio
---    * Effect
---    * Generator
---    * Info
---    * Share
---    * Text
---    * Title
---    * Transition
---    * Video
function Inspector:selectTab(value)
	if not value then
		log.ef("selectTab requires a valid tab string.")
		return nil
	end
	if not self.isShowing() then
		self:show()
		if not self.isShowing() then
			log.ef("Failed to open Inspector")
			return nil
		end
	end
	local ui = self:UI()
	if ui then
		for _,child in ipairs(ui) do
			local app = self:app()
			for _,subChild in ipairs(child) do
				local title = subChild:attributeValue("AXTitle")
				local result = false
				if title == app:string("FFInspectorTabMotionEffectVideo") and value == "Video" then
					result = true
				elseif title == app:string("FFInspectorTabGenerator") and value == "Generator" then
					result = true
				elseif title == app:string("FFInspectorTabMetadata") and value == "Info" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectEffect") and value == "Effect" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectText") and value == "Text" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectTitle") and value == "Title" then
					result = true
				elseif title == app:string("FFInspectorTabMotionEffectTransition") and value == "Transition" then
					result = true
				elseif title == app:string("FFInspectorTabAudio") and value == "Audio" then
					result = true
				elseif title == app:string("FFInspectorTabShare") and value == "Share" then
					result = true
				end
				if result then
					local actionResult = subChild:performAction("AXPress")
					if actionResult then
						return true
					else
						return nil
					end
				end
			end
		end
	end
	return nil
end

--- cp.apple.finalcutpro.main.Inspector:selectedTab() -> string or nil
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
	local ui = self:UI()
	if ui then
		for _,child in ipairs(ui) do
			local app = self:app()
			for _,subChild in ipairs(child) do
				local title = subChild:attributeValue("AXTitle")
				local value = subChild:attributeValue("AXValue")
				if title and value == 1 then
					if title == app:string("FFInspectorTabMotionEffectVideo") then
						return "Video"
					elseif title == app:string("FFInspectorTabGenerator") then
						return "Generator"
					elseif title == app:string("FFInspectorTabMetadata") then
						return "Info"
					elseif title == app:string("FFInspectorTabMotionEffectEffect") then
						return "Effect"
					elseif title == app:string("FFInspectorTabMotionEffectText") then
						return "Text"
					elseif title == app:string("FFInspectorTabMotionEffectTitle") then
						return "Title"
					elseif title == app:string("FFInspectorTabMotionEffectTransition") then
						return "Transition"
					elseif title == app:string("FFInspectorTabAudio") then
						return "Audio"
					elseif title == app:string("FFInspectorTabShare") then
						return "Share"
					elseif title == app:string("FFInspectorTabColor") then
						return "Color"
					end
				end
			end
		end
	end
	return nil
end

--- cp.apple.finalcutpro.main.Inspector:stabilization([value]) -> boolean
--- Method
--- Sets or returns the stabilization setting for a clip.
---
--- Parameters:
---  * [value] - A boolean value you want to set the stabilization setting for the clip to.
---
--- Returns:
---  * The value of the stabilization settings, or `nil` if an error has occurred.
---
--- Notes:
---  * This method will open the Inspector if it's closed, and close it again after adjusting the stablization settings.
function Inspector:stabilization(value)
	local inspectorOriginallyClosed = false
	if not self.isShowing() then
		self:show()
		if not self.isShowing() then
			log.ef("Failed to open Inspector")
			return nil
		end
		inspectorOriginallyClosed = true
	end
	local app = self:app()
	local contents = app:timeline():contents()
	local selectedClips = contents:selectedClipsUI()
	if selectedClips and #selectedClips >= 1 then
		local ui = self:UI()
		if value == nil or type(value) == "boolean" then
			self:selectTab("Video")
			if self:selectedTab() == "Video" then
				local inspectorContent = axutils.childWithID(ui, id "DetailsPanel")
				if inspectorContent then
					for id,child in ipairs(inspectorContent[1][1]) do
						if child:attributeValue("AXValue") == app:string("FFStabilizationEffect") then
							if inspectorContent[1][1][id - 1] then
								local checkbox = inspectorContent[1][1][id - 1]
								if checkbox then
									local checkboxValue = checkbox:attributeValue("AXValue")
									if value == nil then
										if checkboxValue == 1 then
											return true
										else
											return false
										end
									else
										if (checkboxValue == 1 and value == true) or (checkboxValue == 0 and value == false) then
											return value
										else
											local result = checkbox:performAction("AXPress")
											if result then
												return not value
											else
												log.ef("Failed to press checkbox.")
												return nil
											end
										end
									end
								else
									log.ef("Could not find stabilization checkbox.")
								end
							end
						end
					end
				else
					log.ef("Could not find Inspector UI.")
				end
				log.ef("Could not find stabilization checkbox.")
			else
				log.ef("Could not select the video tab.")
			end
		else
			log.ef("The optional value parameter should be a boolean.")
		end
	else
		log.ef("No clip(s) selected.")
	end
	if inspectorOriginallyClosed then
		self:hide()
	end
	return nil
end

return Inspector