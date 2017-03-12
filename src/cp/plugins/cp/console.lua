local chooser			= require("hs.chooser")
local drawing 			= require("hs.drawing")
local fnutils 			= require("hs.fnutils")
local menubar			= require("hs.menubar")
local mouse				= require("hs.mouse")
local screen			= require("hs.screen")
local timer				= require("hs.timer")

local ax 				= require("hs._asm.axuielement")

local plugins			= require("cp.plugins")
local fcp				= require("cp.finalcutpro")
local metadata			= require("cp.metadata")

local log				= require("hs.logger").new("console")

local mod = {}

mod.hacksChooser		= nil 		-- the actual hs.chooser
mod.active 				= false		-- is the Hacks Console Active?
mod.chooserChoices		= nil		-- Choices Table
mod.mode 				= "normal"	-- normal, remove, restore
mod.reduceTransparency	= false

--------------------------------------------------------------------------------
-- LOAD CONSOLE:
--------------------------------------------------------------------------------
function mod.new()

	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	mod.hacksChooser = chooser.new(mod.completionAction):bgDark(true)
											           	:rightClickCallback(mod.rightClickAction)
											        	:choices(mod.choices)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	local reduceTransparency = screen.accessibilitySettings()["ReduceTransparency"]
	mod.reduceTransparency = reduceTransparency
	if reduceTransparency then
		mod.hacksChooser:fgColor(nil)
								 :subTextColor(nil)
	else
		mod.hacksChooser:fgColor(drawing.color.x11.snow)
								 :subTextColor(drawing.color.x11.snow)

	end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running, lets preemptively refresh the choices:
	--------------------------------------------------------------------------------
	if fcp:isRunning() then timer.doAfter(3, mod.refresh) end

end

--------------------------------------------------------------------------------
-- REFRESH CONSOLE CHOICES:
--------------------------------------------------------------------------------
function mod.refresh()
	mod.hacksChooser:refreshChoicesCallback()
end

--------------------------------------------------------------------------------
-- SHOW CONSOLE:
--------------------------------------------------------------------------------
function mod.show()

	--------------------------------------------------------------------------------
	-- Reload Console if Reduce Transparency
	--------------------------------------------------------------------------------
	local reduceTransparency = screen.accessibilitySettings()["ReduceTransparency"]
	if reduceTransparency ~= mod.reduceTransparency then
		mod.new()
	end

	--------------------------------------------------------------------------------
	-- The Console always loads in 'normal' mode:
	--------------------------------------------------------------------------------
	mod.mode = "normal"
	mod.refresh()

	--------------------------------------------------------------------------------
	-- Remember last query?
	--------------------------------------------------------------------------------
	local chooserRememberLast = metadata.get("chooserRememberLast")
	local chooserRememberLastValue = metadata.get("chooserRememberLastValue", "")
	if not chooserRememberLast then
		mod.hacksChooser:query("")
	else
		mod.hacksChooser:query(chooserRememberLastValue)
	end

	--------------------------------------------------------------------------------
	-- Console is Active:
	--------------------------------------------------------------------------------
	mod.active = true

	--------------------------------------------------------------------------------
	-- Show Console:
	--------------------------------------------------------------------------------
	mod.hacksChooser:show()

end

--------------------------------------------------------------------------------
-- HIDE CONSOLE:
--------------------------------------------------------------------------------
function mod.hide()

	--------------------------------------------------------------------------------
	-- No Longer Active:
	--------------------------------------------------------------------------------
	mod.active = false

	--------------------------------------------------------------------------------
	-- Hide Chooser:
	--------------------------------------------------------------------------------
	mod.hacksChooser:hide()

	--------------------------------------------------------------------------------
	-- Save Last Query to Settings:
	--------------------------------------------------------------------------------
	metadata.set("chooserRememberLastValue", mod.hacksChooser:query())

	--------------------------------------------------------------------------------
	-- Put focus back on Final Cut Pro:
	--------------------------------------------------------------------------------
	fcp:launch()

end

--------------------------------------------------------------------------------
-- CONSOLE CHOICES:
--------------------------------------------------------------------------------
function mod.choices()

	--------------------------------------------------------------------------------
	-- Debug Mode:
	--------------------------------------------------------------------------------
	log.df("Updating Console Choices.")

	--------------------------------------------------------------------------------
	-- Reset Choices:
	--------------------------------------------------------------------------------
	mod.chooserChoices = nil
	mod.chooserChoices = {}

	--------------------------------------------------------------------------------
	-- Settings:
	--------------------------------------------------------------------------------
	local currentLanguage 				= fcp:getCurrentLanguage()
	local chooserFavourited				= metadata.get(currentLanguage .. ".chooserFavourited", {})
	local chooserRemoved 				= metadata.get(currentLanguage .. ".chooserRemoved", {})
	local chooserShowAutomation 		= metadata.get("chooserShowAutomation")
	local chooserShowShortcuts 			= metadata.get("chooserShowShortcuts")
	local chooserShowHacks 				= metadata.get("chooserShowHacks")
	local chooserShowVideoEffects 		= metadata.get("chooserShowVideoEffects")
	local chooserShowAudioEffects 		= metadata.get("chooserShowAudioEffects")
	local chooserShowTransitions 		= metadata.get("chooserShowTransitions")
	local chooserShowTitles 			= metadata.get("chooserShowTitles")
	local chooserShowGenerators 		= metadata.get("chooserShowGenerators")
	local chooserShowMenuItems 			= metadata.get("chooserShowMenuItems")

	local individualEffect = nil

	if mod.mode == "normal" or mod.mode == "remove" then

		--------------------------------------------------------------------------------
		-- Hardcoded Choices:
		--------------------------------------------------------------------------------
		local chooserAutomation = {
			{
				["text"] 		= "Toggle Scrolling Timeline",
				["subText"] 	= "Automation",
				["plugin"]		= "cp.plugins.timeline.playhead",
				["function"] 	= "toggleScrollingTimeline",
			},
			{
				["text"] = "Highlight Browser Playhead",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.browser.playhead",
				["function"] = "highlight",
				["function1"] = nil,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Reveal in Browser & Highlight",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.matchframe",
				["function"] = "matchFrame",
				["function1"] = nil,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 1",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 1,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 2",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 2,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 3",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 3,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 4",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 4,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 5",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 5,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 6",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 6,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 7",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 7,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 8",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 8,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 9",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 9,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Clip At Lane 10",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.lanes",
				["function"] = "selectClipAtLane",
				["function1"] = 10,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Single Match Frame & Highlight",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.matchframe",
				["function"] = "matchFrame",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Reveal Multicam in Browser & Highlight",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.matchframe",
				["function"] = "multicamMatchFrame",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Reveal Multicam in Angle Editor & Highlight",
				["subText"] = "Automation",
				["plugin"] = "cp.plugins.timeline.matchframe",
				["function"] = "multicamMatchFrame",
				["function1"] = false,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Color Board Puck 1",
				["subText"] = "Automation",
				["function"] = "colorBoardSelectPuck",
				["function1"] = 1,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Color Board Puck 2",
				["subText"] = "Automation",
				["function"] = "colorBoardSelectPuck",
				["function1"] = 2,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Color Board Puck 3",
				["subText"] = "Automation",
				["function"] = "colorBoardSelectPuck",
				["function1"] = 3,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Select Color Board Puck 4",
				["subText"] = "Automation",
				["function"] = "colorBoardSelectPuck",
				["function1"] = 4,
				["function2"] = nil,
				["function3"] = nil,
			},
		}
		local chooserShortcuts = {
			{
				["text"] = "Create Optimized Media (Activate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleCreateOptimizedMedia",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Create Optimized Media (Deactivate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleCreateOptimizedMedia",
				["function1"] = false,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Create Multicam Optimized Media (Activate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleCreateMulticamOptimizedMedia",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Create Multicam Optimized Media (Deactivate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleCreateMulticamOptimizedMedia",
				["function1"] = false,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Create Proxy Media (Activate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleCreateProxyMedia",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Create Proxy Media (Deactivate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleCreateProxyMedia",
				["function1"] = false,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Leave Files In Place On Import (Activate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleLeaveInPlace",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Leave Files In Place On Import (Deactivate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.import.preferences",
				["function"] = "toggleLeaveInPlace",
				["function1"] = false,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Background Render (Activate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.timeline.preferences",
				["function"] = "toggleBackgroundRender",
				["function1"] = true,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Background Render (Deactivate)",
				["subText"] = "Shortcut",
				["plugin"] = "cp.plugins.timeline.preferences",
				["function"] = "toggleBackgroundRender",
				["function1"] = false,
				["function2"] = nil,
				["function3"] = nil,
			},
		}
		local chooserHacks = {
			{
				["text"] = "Change Backup Interval",
				["subText"] = "Hack",
				["function"] = "changeBackupInterval",
				["function1"] = nil,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Toggle Timecode Overlay",
				["subText"] = "Hack",
				["function"] = "toggleTimecodeOverlay",
				["function1"] = nil,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Toggle Moving Markers",
				["subText"] = "Hack",
				["function"] = "toggleMovingMarkers",
				["function1"] = nil,
				["function2"] = nil,
				["function3"] = nil,
			},
			{
				["text"] = "Toggle Enable Rendering During Playback",
				["subText"] = "Hack",
				["function"] = "togglePerformTasksDuringPlayback",
				["function1"] = nil,
				["function2"] = nil,
				["function3"] = nil,
			},
		}

		if chooserShowAutomation then fnutils.concat(mod.chooserChoices, chooserAutomation) end
		if chooserShowShortcuts then fnutils.concat(mod.chooserChoices, chooserShortcuts) end
		if chooserShowHacks then fnutils.concat(mod.chooserChoices, chooserHacks) end

		--------------------------------------------------------------------------------
		-- Menu Items:
		--------------------------------------------------------------------------------
		local chooserMenuItems = metadata.get(currentLanguage .. ".chooserMenuItems", {})
		if chooserShowMenuItems then
			if next(chooserMenuItems) == nil then
				log.df("Building a list of Final Cut Pro menu items for the first time.")
				local fcpxElements = ax.applicationElement(fcp:application())
				if fcpxElements ~= nil and hs.accessibilityState() then
					local whichMenuBar = nil
					for i=1, fcpxElements:attributeValueCount("AXChildren") do
						if fcpxElements[i]:attributeValue("AXRole") == "AXMenuBar" then
							whichMenuBar = i
						end
					end
					if whichMenuBar ~= nil then
						for i=2, fcpxElements[whichMenuBar]:attributeValueCount("AXChildren") -1 do
							for x=1, fcpxElements[whichMenuBar][i][1]:attributeValueCount("AXChildren") do
								if fcpxElements[whichMenuBar][i][1][x]:attributeValue("AXTitle") ~= "" and fcpxElements[whichMenuBar][i][1][x]:attributeValueCount("AXChildren") == 0 then
									local title = fcpxElements[whichMenuBar][i]:attributeValue("AXTitle") .. " > " .. fcpxElements[whichMenuBar][i][1][x]:attributeValue("AXTitle")
									individualEffect = {
										["text"] = title,
										["subText"] = "Menu Item",
										["function"] = "menuItemShortcut",
										["function1"] = i,
										["function2"] = x,
										["function3"] = "",
										["function4"] = "",
									}
									table.insert(chooserMenuItems, 1, individualEffect)
									table.insert(mod.chooserChoices, 1, individualEffect)
								end
								if fcpxElements[whichMenuBar][i][1][x]:attributeValueCount("AXChildren") ~= 0 then
									for y=1, fcpxElements[whichMenuBar][i][1][x][1]:attributeValueCount("AXChildren") do
										if fcpxElements[whichMenuBar][i][1][x][1][y]:attributeValue("AXTitle") ~= "" then
											local title = fcpxElements[whichMenuBar][i]:attributeValue("AXTitle") .. " > " .. fcpxElements[whichMenuBar][i][1][x]:attributeValue("AXTitle") .. " > " .. fcpxElements[whichMenuBar][i][1][x][1][y]:attributeValue("AXTitle")
											individualEffect = {
												["text"] = title,
												["subText"] = "Menu Item",
												["function"] = "menuItemShortcut",
												["function1"] = i,
												["function2"] = x,
												["function3"] = y,
												["function4"] = "",
											}
											table.insert(chooserMenuItems, 1, individualEffect)
											table.insert(mod.chooserChoices, 1, individualEffect)
										end
										if fcpxElements[whichMenuBar][i][1][x][1][y]:attributeValueCount("AXChildren") ~= 0 then
											for z=1, fcpxElements[whichMenuBar][i][1][x][1][y][1]:attributeValueCount("AXChildren") do
												if fcpxElements[whichMenuBar][i][1][x][1][y][1][z]:attributeValue("AXTitle") ~= "" then
													local title = fcpxElements[whichMenuBar][i]:attributeValue("AXTitle") .. " > " .. fcpxElements[whichMenuBar][i][1][x]:attributeValue("AXTitle") .. " > " .. fcpxElements[whichMenuBar][i][1][x][1][y]:attributeValue("AXTitle") .. " > " .. fcpxElements[whichMenuBar][i][1][x][1][y][1][z]:attributeValue("AXTitle")
													individualEffect = {
														["text"] = title,
														["subText"] = "Menu Item",
														["function"] = "menuItemShortcut",
														["function1"] = i,
														["function2"] = x,
														["function3"] = y,
														["function4"] = z,
													}
													table.insert(chooserMenuItems, 1, individualEffect)
													table.insert(mod.chooserChoices, 1, individualEffect)
												end
											end
										end
									end
								end
							end
						end
					end
				end
				metadata.set(currentLanguage .. ".chooserMenuItems", chooserMenuItems)
			else
				--------------------------------------------------------------------------------
				-- Insert Menu Items from Settings:
				--------------------------------------------------------------------------------
				log.df("Using Menu Items from Settings.")
				for i=1, #chooserMenuItems do
					table.insert(mod.chooserChoices, 1, chooserMenuItems[i])
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Video Effects List:
		--------------------------------------------------------------------------------
		if chooserShowVideoEffects then
			local allVideoEffects = metadata.get(currentLanguage .. ".allVideoEffects")
			if allVideoEffects ~= nil and next(allVideoEffects) ~= nil then
				for i=1, #allVideoEffects do
					individualEffect = {
						["text"] = allVideoEffects[i],
						["subText"] = "Video Effect",
						["plugin"] = "cp.plugins.timeline.effects",
						["function"] = "apply",
						["function1"] = allVideoEffects[i],
						["function2"] = "",
						["function3"] = "",
						["function4"] = "",
					}
					table.insert(mod.chooserChoices, 1, individualEffect)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Audio Effects List:
		--------------------------------------------------------------------------------
		if chooserShowAudioEffects then
			local allAudioEffects = metadata.get(currentLanguage .. ".allAudioEffects")
			if allAudioEffects ~= nil and next(allAudioEffects) ~= nil then
				for i=1, #allAudioEffects do
					individualEffect = {
						["text"] = allAudioEffects[i],
						["subText"] = "Audio Effect",
						["plugin"] = "cp.plugins.timeline.effects",
						["function"] = "apply",
						["function1"] = allAudioEffects[i],
						["function2"] = "",
						["function3"] = "",
						["function4"] = "",
					}
					table.insert(mod.chooserChoices, 1, individualEffect)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Transitions List:
		--------------------------------------------------------------------------------
		if chooserShowTransitions then
			local allTransitions = metadata.get(currentLanguage .. ".allTransitions")
			if allTransitions ~= nil and next(allTransitions) ~= nil then
				for i=1, #allTransitions do
					local individualEffect = {
						["text"] = allTransitions[i],
						["subText"] = "Transition",
						["plugin"] = "cp.plugins.timeline.transitions",
						["function"] = "apply",
						["function1"] = allTransitions[i],
						["function2"] = "",
						["function3"] = "",
						["function4"] = "",
					}
					table.insert(mod.chooserChoices, 1, individualEffect)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Titles List:
		--------------------------------------------------------------------------------
		if chooserShowTitles then
			local allTitles = metadata.get(currentLanguage .. ".allTitles")
			if allTitles ~= nil and next(allTitles) ~= nil then
				for i=1, #allTitles do
					individualEffect = {
						["text"] = allTitles[i],
						["subText"] = "Title",
						["plugin"] = "cp.plugins.timeline.titles",
						["function"] = "apply",
						["function1"] = allTitles[i],
						["function2"] = "",
						["function3"] = "",
						["function4"] = "",
					}
					table.insert(mod.chooserChoices, 1, individualEffect)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Generators List:
		--------------------------------------------------------------------------------
		if chooserShowGenerators then
			local allGenerators = metadata.get(currentLanguage .. ".allGenerators")
			if allGenerators ~= nil and next(allGenerators) ~= nil then
				for i=1, #allGenerators do
					local individualEffect = {
						["text"] = allGenerators[i],
						["subText"] = "Generator",
						["plugin"] = "cp.plugins.timeline.generators",
						["function"] = "apply",
						["function1"] = allGenerators[i],
						["function2"] = "",
						["function3"] = "",
						["function4"] = "",
					}
					table.insert(mod.chooserChoices, 1, individualEffect)
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Remove Deleted Items:
		--------------------------------------------------------------------------------
		if next(chooserRemoved) ~= nil then
			for i=1, #chooserRemoved do
				for x=#mod.chooserChoices,1,-1  do
					if mod.chooserChoices[x]["text"] == chooserRemoved[i]["text"] and mod.chooserChoices[x]["subText"] == chooserRemoved[i]["subText"] then
						table.remove(mod.chooserChoices, x)
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Temporarily Remove Favourited Items:
		--------------------------------------------------------------------------------
		local tempFavouiteItems = {}
		if next(chooserFavourited) ~= nil then
			for i=1, #chooserFavourited do
				for x=#mod.chooserChoices,1,-1  do
					if mod.chooserChoices[x]["text"] == chooserFavourited[i]["text"] and mod.chooserChoices[x]["subText"] == chooserFavourited[i]["subText"] then
						tempFavouiteItems[#tempFavouiteItems + 1] = mod.chooserChoices[x]
						table.remove(mod.chooserChoices, x)
					end
				end
			end
		end

		--------------------------------------------------------------------------------
		-- Sort everything:
		--------------------------------------------------------------------------------
		table.sort(mod.chooserChoices, function(a, b) return a.text < b.text end)
		table.sort(tempFavouiteItems, function(a, b) return a.text < b.text end)

		--------------------------------------------------------------------------------
		-- Merge the Tables Back Together:
		--------------------------------------------------------------------------------
		mod.chooserChoices = fnutils.concat(tempFavouiteItems, mod.chooserChoices)

		--------------------------------------------------------------------------------
		-- Return Choices:
		--------------------------------------------------------------------------------
		return mod.chooserChoices

	elseif mod.mode == "restore" then
		return chooserRemoved
	end

end

--------------------------------------------------------------------------------
-- CONSOLE TRIGGER ACTION:
--------------------------------------------------------------------------------
function mod.completionAction(result)

	local currentLanguage = fcp:getCurrentLanguage()
	local chooserRemoved = metadata.get(currentLanguage .. ".chooserRemoved", {})

	--------------------------------------------------------------------------------
	-- Nothing selected:
	--------------------------------------------------------------------------------
	if result == nil then
		--------------------------------------------------------------------------------
		-- Hide Console:
		--------------------------------------------------------------------------------
		mod.hide()
		return
	end

	--------------------------------------------------------------------------------
	-- Normal Mode:
	--------------------------------------------------------------------------------
	if mod.mode == "normal" then
		--------------------------------------------------------------------------------
		-- Hide Console:
		--------------------------------------------------------------------------------
		mod.hide()

		--------------------------------------------------------------------------------
		-- Perform Specific Function:
		--------------------------------------------------------------------------------
		local source = _G
		if result["plugin"] then
			source = plugins(result["plugin"])
		end

		timer.doAfter(0.0000000001, function() source[result["function"]](result["function1"], result["function2"], result["function3"], result["function4"]) end )

	--------------------------------------------------------------------------------
	-- Remove Mode:
	--------------------------------------------------------------------------------
	elseif mod.mode == "remove" then

		chooserRemoved[#chooserRemoved + 1] = result
		metadata.get(currentLanguage .. ".chooserRemoved", chooserRemoved)
		mod.refresh()
		mod.hacksChooser:show()

	--------------------------------------------------------------------------------
	-- Restore Mode:
	--------------------------------------------------------------------------------
	elseif mod.mode == "restore" then

		for x=#chooserRemoved,1,-1 do
			if chooserRemoved[x]["text"] == result["text"] and chooserRemoved[x]["subText"] == result["subText"] then
				table.remove(chooserRemoved, x)
			end
		end
		metadata.get(currentLanguage .. ".chooserRemoved", chooserRemoved)
		if next(chooserRemoved) == nil then mod.mode = "normal" end
		mod.refresh()
		mod.hacksChooser:show()

	end

end

--------------------------------------------------------------------------------
-- CHOOSER RIGHT CLICK:
--------------------------------------------------------------------------------
function mod.rightClickAction()

	--------------------------------------------------------------------------------
	-- Settings:
	--------------------------------------------------------------------------------
	local currentLanguage 				= fcp:getCurrentLanguage()
	local chooserRememberLast 			= metadata.get("chooserRememberLast")
	local chooserRemoved 				= metadata.get(currentLanguage .. ".chooserRemoved", {})
	local chooserFavourited				= metadata.get(currentLanguage .. ".chooserFavourited", {})

	--------------------------------------------------------------------------------
	-- Display Options:
	--------------------------------------------------------------------------------
	local chooserShowAutomation 		= metadata.get("chooserShowAutomation")
	local chooserShowShortcuts 			= metadata.get("chooserShowShortcuts")
	local chooserShowHacks 				= metadata.get("chooserShowHacks")
	local chooserShowVideoEffects 		= metadata.get("chooserShowVideoEffects")
	local chooserShowAudioEffects 		= metadata.get("chooserShowAudioEffects")
	local chooserShowTransitions 		= metadata.get("chooserShowTransitions")
	local chooserShowTitles				= metadata.get("chooserShowTitles")
	local chooserShowGenerators 		= metadata.get("chooserShowGenerators")
	local chooserShowMenuItems 			= metadata.get("chooserShowMenuItems")

	local selectedRowContents 			= mod.hacksChooser:selectedRowContents()

	--------------------------------------------------------------------------------
	-- 'Show All' Display Option:
	--------------------------------------------------------------------------------
	local chooserShowAll = false
	if chooserShowAutomation and chooserShowShortcuts and chooserShowHacks and chooserShowVideoEffects and chooserShowAudioEffects and chooserShowTransitions and chooserShowTitles and chooserShowGenerators then
		chooserShowAll = true
	end

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	mod.rightClickMenubar = menubar.new(false)

	local selectedItemMenu = {}
	local rightClickMenu = {}

	if next(mod.hacksChooser:selectedRowContents()) ~= nil and mod.mode == "normal" then

		local isFavourite = false
		if next(chooserFavourited) ~= nil then
			for i=1, #chooserFavourited do
				if selectedRowContents["text"] == chooserFavourited[i]["text"] and selectedRowContents["subText"] == chooserFavourited[i]["subText"] then
					isFavourite = true
				end
			end
		end

		local favouriteTitle = "Unfavourite"
		if not isFavourite then favouriteTitle = "Favourite" end

		selectedItemMenu = {
			{ title = string.upper(i18n("highlightedItem")) .. ":", disabled = true },
			{ title = favouriteTitle, fn = function()

				if isFavourite then
					--------------------------------------------------------------------------------
					-- Remove from favourites:
					--------------------------------------------------------------------------------
					for x=#chooserFavourited,1,-1 do
						if chooserFavourited[x]["text"] == selectedRowContents["text"] and chooserFavourited[x]["subText"] == selectedRowContents["subText"] then
							table.remove(chooserFavourited, x)
						end
					end
					metadata.get(currentLanguage .. ".chooserFavourited", chooserRemoved)
				else
					--------------------------------------------------------------------------------
					-- Add to favourites:
					--------------------------------------------------------------------------------
					chooserFavourited[#chooserFavourited + 1] = selectedRowContents
					metadata.get(currentLanguage .. ".chooserFavourited", chooserFavourited)
				end

				mod.refresh()
				mod.hacksChooser:show()

			end },
			{ title = i18n("removeFromList"), fn = function()
				chooserRemoved[#chooserRemoved + 1] = selectedRowContents
				metadata.get(currentLanguage .. ".chooserRemoved", chooserRemoved)
				mod.refresh()
				mod.hacksChooser:show()
			end },
			{ title = "-" },
		}
	end

	rightClickMenu = {
		{ title = i18n("mode"), menu = {
			{ title = i18n("normal"), 				checked = mod.mode == "normal",				fn = function() mod.mode = "normal"; 		mod.refresh() end },
			{ title = i18n("removeFromList"),		checked = mod.mode == "remove",				fn = function() mod.mode = "remove"; 		mod.refresh() end },
			{ title = i18n("restoreToList"),		disabled = next(chooserRemoved) == nil, 	checked = mod.mode == "restore",			fn = function() mod.mode = "restore"; 		mod.refresh() end },
		}},
     	{ title = "-" },
     	{ title = i18n("displayOptions"), menu = {
			{ title = i18n("showNone"), disabled=mod.mode == "restore", fn = function()
				metadata.set("chooserShowAutomation", false)
				metadata.set("chooserShowShortcuts", false)
				metadata.set("chooserShowHacks", false)
				metadata.set("chooserShowVideoEffects", false)
				metadata.set("chooserShowAudioEffects", false)
				metadata.set("chooserShowTransitions", false)
				metadata.set("chooserShowTitles", false)
				metadata.set("chooserShowGenerators", false)
				metadata.set("chooserShowMenuItems", false)
				mod.refresh()
			end },
			{ title = i18n("showAll"), 				checked = chooserShowAll, disabled=mod.mode == "restore" or chooserShowAll, fn = function()
				metadata.set("chooserShowAutomation", true)
				metadata.set("chooserShowShortcuts", true)
				metadata.set("chooserShowHacks", true)
				metadata.set("chooserShowVideoEffects", true)
				metadata.set("chooserShowAudioEffects", true)
				metadata.set("chooserShowTransitions", true)
				metadata.set("chooserShowTitles", true)
				metadata.set("chooserShowGenerators", true)
				metadata.set("chooserShowMenuItems", true)
				mod.refresh()
			end },
			{ title = "-" },
			{ title = i18n("showAutomation"), 		checked = chooserShowAutomation,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowAutomation", not chooserShowAutomation); 			mod.refresh() end },
			{ title = i18n("showHacks"), 			checked = chooserShowHacks,			disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowHacks", not chooserShowHacks); 						mod.refresh() end },
			{ title = i18n("showShortcuts"), 		checked = chooserShowShortcuts,		disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowShortcuts", not chooserShowShortcuts); 				mod.refresh() end },
			{ title = "-" },
			{ title = i18n("showVideoEffects"), 	checked = chooserShowVideoEffects,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowVideoEffects", not chooserShowVideoEffects); 		mod.refresh() end },
			{ title = i18n("showAudioEffects"), 	checked = chooserShowAudioEffects,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowAudioEffects", not chooserShowAudioEffects); 		mod.refresh() end },
			{ title = "-" },
			{ title = i18n("showTransitions"), 		checked = chooserShowTransitions,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowTransitions", not chooserShowTransitions); 			mod.refresh() end },
			{ title = i18n("showTitles"), 			checked = chooserShowTitles,		disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowTitles", not chooserShowTitles); 					mod.refresh() end },
			{ title = i18n("showGenerators"), 		checked = chooserShowGenerators,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowGenerators", not chooserShowGenerators); 			mod.refresh() end },
			{ title = "-" },
			{ title = i18n("showMenuItems"), 		checked = chooserShowMenuItems,		disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowMenuItems", not chooserShowMenuItems); 				mod.refresh() end },
			},
		},
       	{ title = "-" },
       	{ title = i18n("preferences") .. "...", menu = {
			{ title = i18n("rememberLastQuery"), 	checked = chooserRememberLast,						fn= function() metadata.set("chooserRememberLast", not chooserRememberLast) end },
			{ title = "-" },
			{ title = i18n("update"), menu = {
				{ title = i18n("effectsShortcuts"),			fn= function() mod.hide(); 		plugins("cp.plugins.timeline.effects").updateEffectsList();				end },
				{ title = i18n("transitionsShortcuts"),		fn= function() mod.hide(); 		plugins("cp.plugins.timeline.transitions").updateTransitionsList(); 		end },
				{ title = i18n("titlesShortcuts"),			fn= function() mod.hide(); 		plugins("cp.plugins.timeline.titles").updateTitlesList()	 				end },
				{ title = i18n("generatorsShortcuts"),		fn= function() mod.hide(); 		plugins("cp.plugins.timeline.generators")updateGeneratorsList() 			end },
				{ title = i18n("menuItems"),				fn= function() metadata.set("chooserMenuItems", nil); 			mod.refresh() end },
			}},
		}},
	}


	rightClickMenu = fnutils.concat(selectedItemMenu, rightClickMenu)

	mod.rightClickMenubar:setMenu(rightClickMenu)
	mod.rightClickMenubar:popupMenu(mouse.getAbsolutePosition())

end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.commands.fcpx"]	= "fcpxCmds",
}

function plugin.init(deps)

	mod.new()

	deps.fcpxCmds:add("cpConsole")
		:whenActivated(function() mod.show() end)
		:activatedBy():ctrl("space")

	return mod

end

return plugin