--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       F C P X    H A C K S    H U D                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://github.com/latenitefilms).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local hackshud = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------

local application								= require("hs.application")
local chooser									= require("hs.chooser")
local drawing									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local fnutils 									= require("hs.fnutils")
local fs 										= require("hs.fs")
local geometry									= require("hs.geometry")
local host										= require("hs.host")
local mouse										= require("hs.mouse")
local screen									= require("hs.screen")
local settings									= require("hs.settings")
local timer										= require("hs.timer")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")
local window									= require("hs.window")
local windowfilter								= require("hs.window.filter")
local ax										= require("hs._asm.axuielement")

local plugins									= require("cp.plugins")
local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")
local tools										= require("cp.tools")
local commands									= require("cp.commands")

local log										= require("hs.logger").new("hud")

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------

local PRIORITY									= 10000

hackshud.name									= i18n("hacksHUD")
hackshud.width									= 350
hackshud.heightInspector						= 75
hackshud.heightDropTargets						= 75
hackshud.heightButtons							= 70

hackshud.fcpGreen 								= "#3f9253"
hackshud.fcpRed 								= "#d1393e"

hackshud.maxButtons								= 4
hackshud.maxTextLength 							= 25

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

hackshud.ignoreWindowChange						= true
hackshud.windowID								= nil

hackshud.hsBundleID								= hs.processInfo["bundleID"]

function hackshud.isEnabled()
	return metadata.get("enableHacksHUD", false)
end

function hackshud.setEnabled(value)
	metadata.set("enableHacksHUD", value)
	hackshud.update()
end

function hackshud.toggleEnabled()
	hackshud.setEnabled(not hackshud.isEnabled())
end

function hackshud.isInspectorShown()
	return metadata.get("hudShowInspector", true)
end

function hackshud.setInspectorShown(value)
	metadata.set("hudShowInspector", value)
end

function hackshud.toggleInspectorShown()
	hackshud.setInspectorShown(not hackshud.isInspectorShown())
end

function hackshud.isDropTargetsShown()
	return metadata.get("hudShowDropTargets", true)
end

function hackshud.setDropTargetsShown(value)
	return metadata.set("hudShowDropTargets", value)
end

function hackshud.toggleDropTargetsShown()
	hackshud.setDropTargetsShown(not hackshud.isDropTargetsShown())
end

function hackshud.isButtonsShown()
	return metadata.get("hudShowButtons", true)
end

function hackshud.setButtonsShown(value)
	metadata.set("hudShowButtons", value)
end

function hackshud.toggleButtonsShown()
	hackshud.setButtonsShown(not hackshud.isButtonsShown())
end

function hackshud.getPosition()
	return metadata.get("hudPosition", {})
end

function hackshud.setPosition(value)
	metadata.set("hudPosition", value)
end

function hackshud.getButton(index, defaultValue)
	local currentLanguage = fcp:getCurrentLanguage()
	return metadata.get(string.format("%s.hudButton.%d", currentLanguage, index), defaultValue)
end

function hackshud.getButtonCommand(index)
	local button = hackshud.getButton(index)
	if button then
		local group = commands.group(button.group)
		if group then
			return group:get(button.id)
		end
	end
	return nil
end

function hackshud.setButton(index, value)
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.set(string.format("%s.hudButton.%d", currentLanguage, index), value)
end

function hackshud.isFrontmost()
	if hackshud.hudWebView ~= nil then
		return window.focusedWindow() == hackshud.hudWebView:hswindow()
	else
		return false
	end
end

function hackshud.update()
	if hackshud.canShow() then
		hackshud.show()
	else
		hackshud.hide()
	end
end

function hackshud.canShow()
	-- return hackshud.isEnabled()
	local result = (fcp:isFrontmost() or hackshud.isFrontmost() or metadata.isFrontmost())
	and not fcp:fullScreenWindow():isShowing()
	and not fcp:commandEditor():isShowing()
	and hackshud.isEnabled()
	return result
end

--------------------------------------------------------------------------------
-- CREATE THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.new()

	--------------------------------------------------------------------------------
	-- Work out HUD height based off settings:
	--------------------------------------------------------------------------------
	local hudShowInspector 		= hackshud.isInspectorShown()
	local hudShowDropTargets 	= hackshud.isDropTargetsShown()
	local hudShowButtons 		= hackshud.isButtonsShown()

	local hudHeight = 0
	if hudShowInspector then hudHeight = hudHeight + hackshud.heightInspector end
	if hudShowDropTargets then hudHeight = hudHeight + hackshud.heightDropTargets end
	if hudShowButtons then hudHeight = hudHeight + hackshud.heightButtons end

	--------------------------------------------------------------------------------
	-- Get last HUD position from settings otherwise default to centre screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultHUDRect = {x = (screenFrame['w']/2) - (hackshud.width/2), y = (screenFrame['h']/2) - (hudHeight/2), w = hackshud.width, h = hudHeight}
	local hudPosition = hackshud.getPosition()
	if next(hudPosition) ~= nil then
		defaultHUDRect = {x = hudPosition["_x"], y = hudPosition["_y"], w = hackshud.width, h = hudHeight}
	end

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	hackshud.hudWebViewController = webview.usercontent.new("hackshud")
		:setCallback(hackshud.javaScriptCallback)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	hackshud.hudWebView = webview.new(defaultHUDRect, {}, hackshud.hudWebViewController)
		:windowStyle({"HUD", "utility", "titled", "nonactivating", "closable"})
		:shadow(true)
		:closeOnEscape(true)
		:html(generateHTML())
		:allowGestures(false)
		:allowNewWindows(false)
		:windowTitle(hackshud.name)
		:level(drawing.windowLevels.modalPanel)

	--------------------------------------------------------------------------------
	-- Window Watcher:
	--------------------------------------------------------------------------------
	hackshud.hudFilter = windowfilter.new(true)
		:setAppFilter(hackshud.name, {activeApplication=true})

	--------------------------------------------------------------------------------
	-- HUD Moved:
	--------------------------------------------------------------------------------
	hackshud.hudFilter:subscribe(windowfilter.windowMoved, function(window, applicationName, event)
		if window:id() == hackshud.windowID then
			if hackshud.active() then
				local result = hackshud.hudWebView:hswindow():frame()
				if result ~= nil then
					hackshud.setPosition(result)
				end
			end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- HUD Closed:
	--------------------------------------------------------------------------------
	hackshud.hudFilter:subscribe(windowfilter.windowDestroyed, 
	function(window, applicationName, event)
		if window:id() == hackshud.windowID then
			if not hackshud.ignoreWindowChange then
				hackshud.setEnabled(false)
			end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Watches all apps:
	--------------------------------------------------------------------------------
	hackshud.windowFilter = windowfilter.new(true)
	
	--------------------------------------------------------------------------------
	-- HUD Unfocussed:
	--------------------------------------------------------------------------------
	hackshud.windowFilter:subscribe(windowfilter.windowFocused, 
	function(window, applicationName, event)
		hackshud.update()
	end, true)
	
	local watcher = application.watcher
	hackshud.appWatcher = watcher.new(
		function(appName, eventType, appObject)
			if eventType == watcher.activated or eventType == watcher.deactivated or eventType == watcher.terminated then
				hackshud.update()
			end
		end
	)
	hackshud.appWatcher:start()
end

--------------------------------------------------------------------------------
-- SHOW THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.show()
	hackshud.ignoreWindowChange = true
	if hackshud.hudWebView == nil then
		hackshud.new()
		hackshud.hudWebView:show()
	else
		hackshud.hudWebView:show()
	end

	--------------------------------------------------------------------------------
	-- Keep checking for a window ID until we get an answer:
	--------------------------------------------------------------------------------
	local hacksHUDWindowIDTimerDone = false
	timer.doUntil(function() return hacksHUDWindowIDTimerDone end, function()
		if hackshud.hudWebView:hswindow() ~= nil then
			if hackshud.hudWebView:hswindow():id() ~= nil then
				hackshud.windowID = hackshud.hudWebView:hswindow():id()
				hacksHUDWindowIDTimerDone = true
			end
		end
	end, 0.05):fire()
	
	if hackshud.windowFilter then hackshud.windowFilter:resume() end
	if hackshud.appWatcher then hackshud.appWatcher:start() end

	hackshud.ignoreWindowChange = false
end

--------------------------------------------------------------------------------
-- IS HACKS HUD ACTIVE:
--------------------------------------------------------------------------------
function hackshud.active()
	if hackshud.hudWebView == nil then
		return false
	end
	if hackshud.hudWebView:hswindow() == nil then
		return false
	else
		return true
	end
end

--------------------------------------------------------------------------------
-- HIDE THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.hide()
	if hackshud.active() then
		hackshud.ignoreWindowChange = true
		hackshud.hudWebView:hide()
		if hackshud.windowFilter then hackshud.windowFilter:pause() end
		if hackshud.appWatcher then hackshud.appWatcher:stop() end
	end
end

--------------------------------------------------------------------------------
-- DELETE THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.delete()
	if hackshud.active() then
		hackshud.hudWebView:delete()
		if hackshud.windowFocus then hackshud.windowFocus:delete() end
		if hackshud.appWatcher then hackshud.appWatcher:stop() end
	end
end

--------------------------------------------------------------------------------
-- RELOAD THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.reload()

	local hudActive = hackshud.active()

	hackshud.delete()
	hackshud.ignoreWindowChange	= true
	hackshud.windowID			= nil
	hackshud.new()

	if hudActive and fcp:isFrontmost() then
		hackshud.show()
	end

end

--------------------------------------------------------------------------------
-- REFRESH THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.refresh()
	if hackshud.active() then
		hackshud.hudWebView:html(generateHTML())
	end
end

--------------------------------------------------------------------------------
-- ASSIGN HUD BUTTON:
--------------------------------------------------------------------------------
function hackshud.assignButton(button)

	--------------------------------------------------------------------------------
	-- Was Final Cut Pro Open?
	--------------------------------------------------------------------------------
	local wasFinalCutProOpen = fcp:isFrontmost()
	local whichButton = button
	local hudButtonChooser = nil
	
	local chooserAction = function(result)

		--------------------------------------------------------------------------------
		-- Hide Chooser:
		--------------------------------------------------------------------------------
		hudButtonChooser:hide()

		--------------------------------------------------------------------------------
		-- Perform Specific Function:
		--------------------------------------------------------------------------------
		if result ~= nil then
			hackshud.setButton(whichButton, {group = result.group, id = result.id})
		end

		--------------------------------------------------------------------------------
		-- Put focus back in Final Cut Pro:
		--------------------------------------------------------------------------------
		if hackshud.wasFinalCutProOpen then
			fcp:launch()
		end

		--------------------------------------------------------------------------------
		-- Reload HUD:
		--------------------------------------------------------------------------------
		if hackshud.isEnabled() then
			hackshud.reload()
		end
	end

	hudButtonChooser = chooser.new(chooserAction):bgDark(true)
												  :fgColor(drawing.color.x11.snow)
												  :subTextColor(drawing.color.x11.snow)
												  :choices(hackshud.choices)
												  :show()
end

--------------------------------------------------------------------------------
-- HACKS CONSOLE CHOICES:
--------------------------------------------------------------------------------
function hackshud.choices()

	local result = {}
	local individualEffect = nil
	
	local chooserCommands = {}
	
	for _,id in pairs(commands.groupIds()) do
		local group = commands.group(id)
		for _,cmd in pairs(group:getAll()) do
			local title = cmd:getTitle()
			if title then
				local subText = cmd:getSubtitle()
				if not subText and cmd:getGroup() then
					subText = i18n(cmd:getGroup() .. "_group")
				end
				chooserCommands[#chooserCommands + 1] = {
					text		= title,
					subText		= subText,
					group		= group:id(),
					id			= cmd:id(),
				}
			end
		end
	end

	fnutils.concat(result, chooserCommands)

	--------------------------------------------------------------------------------
	-- Menu Items:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()
	local chooserMenuItems = metadata.get(currentLanguage .. ".chooserMenuItems") or {}
	if next(chooserMenuItems) == nil then
		debugMessage("Building a list of Final Cut Pro menu items for the first time.")
		local fcpxElements = ax.applicationElement(fcp:application())
		if fcpxElements ~= nil then
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
							table.insert(result, 1, individualEffect)
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
									table.insert(result, 1, individualEffect)
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
											table.insert(result, 1, individualEffect)
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
		debugMessage("Using Menu Items from Settings.")
		for i=1, #chooserMenuItems do
			table.insert(result, 1, chooserMenuItems[i])
		end
	end

	--------------------------------------------------------------------------------
	-- Video Effects List:
	--------------------------------------------------------------------------------
	local allVideoEffects = metadata.get(currentLanguage .. ".allVideoEffects")
	if allVideoEffects ~= nil and next(allVideoEffects) ~= nil then
		for i=1, #allVideoEffects do
			individualEffect = {
				["text"] = allVideoEffects[i],
				["subText"] = "Video Effect",
				["plugin"] = "hs.fcpxhacks.plugins.timeline.effects",
				["function"] = "apply",
				["function1"] = allVideoEffects[i],
				["function2"] = "",
				["function3"] = "",
				["function4"] = "",
			}
			table.insert(result, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Audio Effects List:
	--------------------------------------------------------------------------------
	local allAudioEffects = metadata.get(currentLanguage .. ".allAudioEffects")
	if allAudioEffects ~= nil and next(allAudioEffects) ~= nil then
		for i=1, #allAudioEffects do
			individualEffect = {
				["text"] = allAudioEffects[i],
				["subText"] = "Audio Effect",
				["plugin"] = "hs.fcpxhacks.plugins.timeline.effects",
				["function"] = "apply",
				["function1"] = allAudioEffects[i],
				["function2"] = "",
				["function3"] = "",
				["function4"] = "",
			}
			table.insert(result, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Transitions List:
	--------------------------------------------------------------------------------
	local allTransitions = metadata.get(currentLanguage .. ".allTransitions")
	if allTransitions ~= nil and next(allTransitions) ~= nil then
		for i=1, #allTransitions do
			local individualEffect = {
				["text"] = allTransitions[i],
				["subText"] = "Transition",
				["plugins"] = "hs.fcpxhacks.plugins.timeline.transitions",
				["function"] = "apply",
				["function1"] = allTransitions[i],
				["function2"] = "",
				["function3"] = "",
				["function4"] = "",
			}
			table.insert(result, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Titles List:
	--------------------------------------------------------------------------------
	local allTitles = metadata.get(currentLanguage .. ".allTitles")
	if allTitles ~= nil and next(allTitles) ~= nil then
		for i=1, #allTitles do
			individualEffect = {
				["text"] = allTitles[i],
				["subText"] = "Title",
				["plugin"] = "hs.fcpxhacks.plugins.timeline.titles",
				["function"] = "apply",
				["function1"] = allTitles[i],
				["function2"] = "",
				["function3"] = "",
				["function4"] = "",
			}
			table.insert(result, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Generators List:
	--------------------------------------------------------------------------------
	local allGenerators = metadata.get(currentLanguage .. ".allGenerators")
	if allGenerators ~= nil and next(allGenerators) ~= nil then
		for i=1, #allGenerators do
			local individualEffect = {
				["text"] = allGenerators[i],
				["subText"] = "Generator",
				["plugin"] = "hs.fcpxhacks.plugins.timeline.generators",
				["function"] = "apply",
				["function1"] = allGenerators[i],
				["function2"] = "",
				["function3"] = "",
				["function4"] = "",
			}
			table.insert(result, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Sort everything:
	--------------------------------------------------------------------------------
	table.sort(result, function(a, b) return a.text < b.text end)

	return result

end

--------------------------------------------------------------------------------
-- CONVERT HUB BUTTON TABLE TO FUNCTION URL STRING:
--------------------------------------------------------------------------------
local function hudButtonFunctionsToURL(table)

	local result = ""

	if table["function"] ~= nil then
		if table["function"] ~= "" then
			result = "?function=" .. table["function"]
		end
	end
	if table["function1"] ~= nil then
		if table["function1"] ~= "" then
			result = result .. "&function1=" .. table["function1"]
		end
	end
	if table["function2"] ~= nil then
		if table["function2"] ~= "" then
			result = result .. "&function2=" .. table["function2"]
		end
	end
	if table["function3"] ~= nil then
		if table["function3"] ~= "" then
			result = result .. "&function3=" .. table["function3"]
		end
	end
	if table["function4"] ~= nil then
		if table["function4"] ~= "" then
			result = result .. "&function4=" .. table["function4"]
		end
	end

	if result == "" then result = "?function=displayUnallocatedHUDMessage" end
	result = "commandpost://cmd" .. result

	return result

end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
function generateHTML()

	--------------------------------------------------------------------------------
	-- HUD Settings:
	--------------------------------------------------------------------------------
	local hudShowInspector 		= hackshud.isInspectorShown()
	local hudShowDropTargets 	= hackshud.isDropTargetsShown()
	local hudShowButtons 		= hackshud.isButtonsShown()

	--------------------------------------------------------------------------------
	-- Get Custom HUD Button Values:
	--------------------------------------------------------------------------------
	local unallocatedButton = {
		["text"] = i18n("unassigned"),
		["subText"] = "",
		["function"] = "",
		["function1"] = "",
		["function2"] = "",
		["function3"] = "",
		["function4"] = "",
	}
	local currentLanguage 	= fcp:getCurrentLanguage()
	local hudButtonOne 		= metadata.get(currentLanguage .. ".hudButtonOne") 	or unallocatedButton
	local hudButtonTwo 		= metadata.get(currentLanguage .. ".hudButtonTwo") 	or unallocatedButton
	local hudButtonThree 	= metadata.get(currentLanguage .. ".hudButtonThree") 	or unallocatedButton
	local hudButtonFour 	= metadata.get(currentLanguage .. ".hudButtonFour") 	or unallocatedButton

	local hudButtonOneURL	= hudButtonFunctionsToURL(hudButtonOne)
	local hudButtonTwoURL	= hudButtonFunctionsToURL(hudButtonTwo)
	local hudButtonThreeURL	= hudButtonFunctionsToURL(hudButtonThree)
	local hudButtonFourURL	= hudButtonFunctionsToURL(hudButtonFour)

	--------------------------------------------------------------------------------
	-- Get Final Cut Pro Preferences:
	--------------------------------------------------------------------------------
	local preferences = fcp:getPreferences()

	--------------------------------------------------------------------------------
	-- FFPlayerQuality
	--------------------------------------------------------------------------------
	-- 10 	= Original - Better Quality
	-- 5 	= Original - Better Performance
	-- 4 	= Proxy
	--------------------------------------------------------------------------------

	if preferences["FFPlayerQuality"] == nil then
		FFPlayerQuality = 5
	else
		FFPlayerQuality = preferences["FFPlayerQuality"]
	end
	local playerQuality = nil

	local originalOptimised = i18n("originalOptimised")
	local betterQuality = i18n("betterQuality")
	local betterPerformance = i18n("betterPerformance")
	local proxy = i18n("proxy")

	if FFPlayerQuality == 10 then
		playerMedia = '<span style="color: ' .. hackshud.fcpGreen .. ';">' .. originalOptimised .. '</span>'
		playerQuality = '<span style="color: ' .. hackshud.fcpGreen .. ';">' .. betterQuality .. '</span>'
	elseif FFPlayerQuality == 5 then
		playerMedia = '<span style="color: ' .. hackshud.fcpGreen .. ';">' .. originalOptimised .. '</span>'
		playerQuality = '<span style="color: ' .. hackshud.fcpRed .. ';">' .. betterPerformance .. '</span>'
	elseif FFPlayerQuality == 4 then
		playerMedia = '<span style="color: ' .. hackshud.fcpRed .. ';">' .. proxy .. '</span>'
		playerQuality = '<span style="color: ' .. hackshud.fcpRed .. ';">' .. proxy .. '</span>'
	end
	if preferences["FFAutoRenderDelay"] == nil then
		FFAutoRenderDelay = "0.3"
	else
		FFAutoRenderDelay = preferences["FFAutoRenderDelay"]
	end
	if preferences["FFAutoStartBGRender"] == nil then
		FFAutoStartBGRender = true
	else
		FFAutoStartBGRender = preferences["FFAutoStartBGRender"]
	end

	local backgroundRender = nil
	if FFAutoStartBGRender then
		backgroundRender = '<span style="color: ' .. hackshud.fcpGreen .. ';">' .. i18n("enabled") .. ' (' .. FFAutoRenderDelay .. " " .. i18n("secs", {count=tonumber(FFAutoRenderDelay)}) .. ')</span>'
	else
		backgroundRender = '<span style="color: ' .. hackshud.fcpRed .. ';">' .. i18n("disabled") .. '</span>'
	end

	local html = [[<!DOCTYPE html>
<html>
	<head>
		<!-- Style Sheets: -->
		<style>
		.button {
			text-align: center;
			display:block;
			width: 136px;
			font-family: -apple-system;
			font-size: 10px;
			text-decoration: none;
			background-color: #333333;
			color: #bfbebb;
			padding: 2px 6px 2px 6px;
			border-top: 1px solid #161616;
			border-right: 1px solid #161616;
			border-bottom: 0.5px solid #161616;
			border-left: 1px solid #161616;
			margin-left: auto;
		    margin-right: auto;
		}
		body {
			background-color:#1f1f1f;
			color: #bfbebb;
			font-family: -apple-system;
			font-size: 11px;
			font-weight: lighter;
		}
		table {
			width:100%;
			text-align:left;
		}
		th {
			width:50%;
		}
		h1 {
			font-size: 12px;
			font-weight: bold;
			text-align: center;
			margin: 0px;
			padding: 0px;
		}
		hr {
			height:1px;
			border-width:0;
			color:gray;
			background-color:#797979;
		    display: block;
			margin-top: 10px;
			margin-bottom: 10px;
			margin-left: auto;
			margin-right: auto;
			border-style: inset;
		}
		input[type=text] {
			width: 100%;
			padding: 5px 5px;
			margin: 8px 0;
			box-sizing: border-box;
			border: 4px solid #22426f;
			border-radius: 4px;
			background-color: black;
			color: white;
			text-align:center;
		}
		</style>

		<!-- Javascript: -->
		<script>

			// Disable Right Clicking:
			document.addEventListener("contextmenu", function(e){
			    e.preventDefault();
			}, false);

			// Something has been dropped onto our Dropbox:
			function dropboxAction() {
				var x = document.getElementById("dropbox");
				var dropboxValue = x.value;

				try {
				webkit.messageHandlers.hackshud.postMessage(dropboxValue);
				} catch(err) {
				console.log('The controller does not exist yet');
				}

				x.value = "]] .. string.upper(i18n("hudDropZoneText")) .. [[";
			}

		</script>
	</head>
	<body>]]

	--------------------------------------------------------------------------------
	-- HUD Inspector:
	--------------------------------------------------------------------------------
	if hudShowInspector then html = html .. [[
		<table>
			<tr>
				<th>Media:</th>
				<th>]] .. playerMedia .. [[<th>
			</tr>
			<tr>
				<th>Quality:</th>
				<th>]] .. playerQuality .. [[<th>
			</tr>

			<tr>
				<th>Background Render:</th>
				<th>]] .. backgroundRender .. [[</th>
			</tr>
		</table>]]
	end

	if (hudShowInspector and hudShowDropTargets) or (hudShowInspector and hudShowButtons) then html = html .. [[
		<hr />]]
	end

	--------------------------------------------------------------------------------
	-- HUD Drop Targets:
	--------------------------------------------------------------------------------
	if hudShowDropTargets then html = html .. [[
		<table>
			<tr>
				<th style="width: 30%;">XML Sharing:</th>
				<th style="width: 70%;"><form><input type="text" id="dropbox" name="dropbox" oninput="dropboxAction()" tabindex="-1" value="]] .. string.upper(i18n("hudDropZoneText")) .. [["></form></th>
			<tr>
		</table>]]
	end

	if hudShowDropTargets and hudShowButtons then html = html .. [[
		<hr />]]
	end

	--------------------------------------------------------------------------------
	-- HUD Buttons:
	--------------------------------------------------------------------------------
	local length = 25
	if hudShowButtons then html = html.. [[
		<table>
			<tr>
				<th><a href="]] .. hudButtonOneURL .. [[" class="button">]] .. tools.stringMaxLength(tools.cleanupButtonText(hudButtonOne["text"]), length) .. [[</a></th>
				<th><a href="]] .. hudButtonTwoURL .. [[" class="button">]] .. tools.stringMaxLength(tools.cleanupButtonText(hudButtonTwo["text"]), length) .. [[</a></th>
			<tr>
			<tr style="padding:80px;"><th></th></tr>
			<tr>
				<th><a href="]] .. hudButtonThreeURL .. [[" class="button">]] .. tools.stringMaxLength(tools.cleanupButtonText(hudButtonThree["text"]), length) .. [[</a></th>
				<th><a href="]] .. hudButtonFourURL .. [[" class="button">]] .. tools.stringMaxLength(tools.cleanupButtonText(hudButtonFour["text"]), length) .. [[</a></th>
			</tr>
		</table>]]
	end

	html = html .. [[
	</body>
</html>
	]]

	return html

end

--------------------------------------------------------------------------------
-- JAVASCRIPT CALLBACK:
--------------------------------------------------------------------------------
function hackshud.javaScriptCallback(message)
	if message["body"] ~= nil then
		if string.find(message["body"], "<!DOCTYPE fcpxml>") ~= nil then
			hackshud.shareXML(message["body"])
		else
			dialog.displayMessage(i18n("hudDropZoneError"))
		end
	end
end

--------------------------------------------------------------------------------
-- SHARED XML:
--------------------------------------------------------------------------------
function hackshud.shareXML(incomingXML)

	local enableXMLSharing = hackshud.isEnabled()

	if enableXMLSharing then

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local xmlSharingPath = hackshud.xmlSharing.getSharingPath()

		--------------------------------------------------------------------------------
		-- Get only the needed XML content:
		--------------------------------------------------------------------------------
		local startOfXML = string.find(incomingXML, "<?xml version=")
		local endOfXML = string.find(incomingXML, "</fcpxml>")

		--------------------------------------------------------------------------------
		-- Error Detection:
		--------------------------------------------------------------------------------
		if startOfXML == nil or endOfXML == nil then
			dialog.displayErrorMessage("Something went wrong when attempting to translate the XML data you dropped. Please try again.\n\nError occurred in hackshud.shareXML().")
			if incomingXML ~= nil then
				debugMessage("Start of incomingXML.")
				debugMessage(incomingXML)
				debugMessage("End of incomingXML.")
			else
				debugMessage("ERROR: incomingXML is nil.")
			end
			return "fail"
		end

		--------------------------------------------------------------------------------
		-- New XML:
		--------------------------------------------------------------------------------
		local newXML = string.sub(incomingXML, startOfXML - 2, endOfXML + 8)

		--------------------------------------------------------------------------------
		-- Display Text Box:
		--------------------------------------------------------------------------------
		local textboxResult = dialog.displayTextBoxMessage(i18n("hudXMLNameDialog"), i18n("hudXMLNameError"), "")

		--------------------------------------------------------------------------------
		-- Save the XML content to the Shared XML Folder:
		--------------------------------------------------------------------------------
		local newXMLPath = xmlSharingPath .. host.localizedName() .. "/"

		if not tools.doesDirectoryExist(newXMLPath) then
			fs.mkdir(newXMLPath)
		end

		local file = io.open(newXMLPath .. textboxResult .. ".fcpxml", "w")
		currentClipboardData = file:write(newXML)
		file:close()

	else
		dialog.displayMessage(i18n("hudXMLSharingDisabled"))
	end

end

function hackshud.init(xmlSharing, fcpxCmds)
	hackshud.xmlSharing = xmlSharing
	hackshud.fcpxCmds	= fcpxCmds
	hackshud.update()
	return hackshud
end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.sharing.xml"]		= "xmlSharing",
	["cp.plugins.menu.tools"]		= "tools",
	["cp.plugins.commands.fcpx"]	= "fcpxCmds",
}

function plugin.init(deps)
	hackshud.init(deps.xmlSharing, deps.fcpxCmds)
	
	fcp:watch({
		active		= hackshud.update,
		inactive	= hackshud.update,
	})
	
	fcp:fullScreenWindow():watch({
		show		= hackshud.update,
		hide		= hackshud.update,
	})
	
	fcp:commandEditor():watch({
		show		= hackshud.update,
		hide		= hackshud.update,
	})
	
	-- Menus
	local hudMenu = deps.tools:addMenu(PRIORITY, function() return i18n("hud") end)
	hudMenu:addItem(1000, function()
			return { title = i18n("enableHacksHUD"),	fn = hackshud.toggleEnabled,		checked = hackshud.isEnabled()}
		end)
	hudMenu:addSeparator(2000)
	hudMenu:addMenu(3000, function() return i18n("hudOptions") end)
		:addItems(1000, function()
			return {
				{ title = i18n("showInspector"),	fn = hackshud.toggleInspctorShown,		checked = hackshud.isInspectorShown()},
				{ title = i18n("showDropTargets"),	fn = hackshud.toggleDropTargetsShown, 	checked = hackshud.isDropTargetsShown()},
				{ title = i18n("showButtons"),		fn = hackshud.toggleButtonsShown, 		checked = hackshud.isButtonsShown()},
			}
		end)
		
	hudMenu:addMenu(4000, function() return i18n("assignHUDButtons") end)
		:addItems(1000, function() 
			local items = {}
			local unassignedText = i18n("unassigned")
			for i = 1, hackshud.maxButtons do
				local title = unassignedText
				
				local cmd = hackshud.getButtonCommand(i)
				if cmd then
					title = cmd:getTitle()
				end
				
				title = tools.stringMaxLength(tools.cleanupButtonText(title), hackshud.maxTextLength, "...")
				items[#items + 1] = { title = i18n("hudButtonItem", {count = i, title = title}),	fn = function() hackshud.assignButton(i) end }
			end
			return items
		end)
		
	-- Commands
	deps.fcpxCmds:add("FCPXHackHUD")
		:activatedBy():ctrl():option():cmd("a")
		:whenActivated(hackshud.toggleEnabled)
	
	return hackshud
end

return plugin