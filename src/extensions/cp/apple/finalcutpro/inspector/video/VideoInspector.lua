--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.video.VideoInspector ===
---
--- Video Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("videoInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local id								= require("cp.apple.finalcutpro.ids") "Inspector"
local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local VideoInspector = {}

--- cp.apple.finalcutpro.inspector.video.VideoInspector:new(parent) -> VideoInspector object
--- Method
--- Creates a new VideoInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A VideoInspector object
-- TODO: Use a function instead of a method.
function VideoInspector:new(parent) -- luacheck: ignore
	local o = {
		_parent = parent,
		_child = {}
	}
	return prop.extend(o, VideoInspector)
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:parent() -> table
--- Method
--- Returns the VideoInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function VideoInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function VideoInspector:app()
	return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.video.VideoInspector:isShowing() -> boolean
--- Method
--- Returns `true` if the Video Inspector is showing otherwise `false`
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function VideoInspector:isShowing()
	return self:parent():selectedTab() == "Video" or false
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:show() -> VideoInspector
--- Method
--- Show's the Video Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * VideoInspector
function VideoInspector:show()
	self:parent():selectTab("Video")
	return self
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:stabilization([value]) -> boolean
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
function VideoInspector:stabilization(value)
	local inspectorOriginallyClosed = false
	if not self:isShowing() then
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
		local ui = self:parent():UI()
		if value == nil or type(value) == "boolean" then
			self:parent():selectTab("Video")
			if self:parent():selectedTab() == "Video" then
				local inspectorContent = axutils.childWithID(ui, id "DetailsPanel")
				if inspectorContent then
					for theID,child in ipairs(inspectorContent[1][1]) do
						if child:attributeValue("AXValue") == app:string("FFStabilizationEffect") then
							if inspectorContent[1][1][theID - 1] then
								local checkbox = inspectorContent[1][1][theID - 1]
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
		self:parent():hide()
	end
	return nil
end

return VideoInspector