--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    T O U C H    B A R    W I D G E T                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.touchbar.widgets.colorboard ===
---
--- Final Cut Pro Color Board Widget for Touch Bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("colorWidget")

local canvas   			= require("hs.canvas")
local eventtap			= require("hs.eventtap")
local screen   			= require("hs.screen")
local styledtext		= require("hs.styledtext")
local window   			= require("hs.window")
local timer				= require("hs.timer")

local touchbar 			= require("hs._asm.undocumented.touchbar")

local fcp				= require("cp.apple.finalcutpro")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.updateInterval = 0.5

mod._doubleTap = {}
mod._updateCallbacks = {}

local function getBrightness(aspect)
	if aspect == "global" then
		return 0.25
	elseif aspect == "shadows" then
		return 0
	elseif aspect == "midtones" then
		return 0.33
	elseif aspect == "highlights" then
		return 0.66
	else
		return 1
	end
end

local function calculateColor(pct, angle)
	local brightness = nil
	local solidColor = nil
	local fillColor = nil

	if angle then
		solidColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = 1}
		fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = math.abs(pct/100)}
	else
		if pct then
			brightness = pct >= 0 and 1 or 0
			fillColor = {hue = 0, saturation = 0, brightness = brightness, alpha = math.abs(pct/100)}
		end
	end

	local negative = false
	if pct and angle and pct < 0 then
		negative = true
	end

	return brightness, solidColor, fillColor, negative
end

local function getWidgetText(id, aspect)
	local colorBoard = fcp:colorBoard()
	local widgetText
	local puckID = tonumber(string.sub(id, -1))

	local aspectTitle = {
		["color"] = "Color",
		["saturation"] = "Sat",
		["exposure"] = "Exp",
	}

	local puckTitle = {
		[1] = "Global",
		[2] = "Low",
		[3] = "Mid",
		[4] = "High",
	}

	local spanStyle = [[<span style="font-family: -apple-system; font-size: 12px; color: #FFFFFF;">]]
	if aspect == "*" then
		local selectedPanel = colorBoard:selectedPanel()
		if selectedPanel then
			if aspectTitle[selectedPanel] and puckTitle[puckID] then
				widgetText = styledtext.getStyledTextFromData(spanStyle .. "<strong>" .. aspectTitle[selectedPanel] .. ": </strong>" .. puckTitle[puckID] .. "</span>")
			end
		else
			widgetText = styledtext.getStyledTextFromData(spanStyle .. "<strong>" .. puckTitle[puckID] .. ":</strong> </span>")
		end
	else
		widgetText = styledtext.getStyledTextFromData(spanStyle .. "<strong>" .. aspectTitle[aspect] .. ":</strong> </span>") .. puckTitle[puckID]
	end

	return widgetText
end

local function updateCanvas(widgetCanvas, id, aspect, property)

	local colorBoard = fcp:colorBoard()

	if colorBoard:isShowing() == false then
		widgetCanvas.negative.action = "skip"
		widgetCanvas.arc.action = "skip"
		widgetCanvas.info.action = "skip"
		widgetCanvas.circle.action = "skip"
	else
		if colorBoard:selectedPanel() == aspect then
			local pct = colorBoard:getPercentage(aspect, property)
			local angle	= colorBoard:getAngle(aspect, property)

			local brightness, solidColor, fillColor, negative = calculateColor(pct, angle)

			widgetCanvas.circle.action = "strokeAndFill"
			if solidColor then
				widgetCanvas.circle.strokeColor = solidColor
				widgetCanvas.arc.strokeColor = solidColor
				widgetCanvas.arc.fillColor = solidColor
			end
			widgetCanvas.circle.fillColor = fillColor

			if negative then
				widgetCanvas.negative.action = "strokeAndFill"
			else
				widgetCanvas.negative.action = "skip"
			end

			if colorBoard:selectedPanel() == "color" and aspect == "*" then
				widgetCanvas.arc.action = "strokeAndFill"
			else
				widgetCanvas.arc.action = "skip"
			end

			widgetCanvas.info.action = "strokeAndFill"
			if pct then
				widgetCanvas.info.text = pct .. "%"
			else
				widgetCanvas.info.text = ""
			end

			widgetCanvas.text.text = getWidgetText(id, aspect)
		end
	end

end

mod._timer = timer.new(mod.updateInterval, function()
	if fcp:isRunning() and fcp:isFrontmost() and fcp:colorBoard():isShowing() then
		for i, v in pairs(mod._updateCallbacks) do
			v()
		end
	end
end)

--- plugins.finalcutpro.touchbar.widgets.colorboard.start() -> nil
--- Function
--- Stops the Timer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
	mod._timer:start()
end

--- plugins.finalcutpro.touchbar.widgets.colorboard.stop() -> nil
--- Function
--- Stops the Timer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	mod._timer:stop()
end

local function puckWidget(id, aspect, property)

	local colorBoard = fcp:colorBoard()

	local pct = colorBoard:getPercentage(aspect, property)
	local angle	= colorBoard:getAngle(aspect, property)

	local brightness, solidColor, fillColor, negative = calculateColor(pct, angle)

	local value = colorBoard:getPercentage(aspect, property)
	if value == nil then value = 0 end

	local color = {hue=0, saturation=0, brightness=brightness, alpha=1}

	local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 150}

	--------------------------------------------------------------------------------
	-- Background:
	--------------------------------------------------------------------------------
	widgetCanvas[#widgetCanvas + 1] = {
		id				 = "background",
		type             = "rectangle",
		action           = "strokeAndFill",
		strokeColor      = { white = 1 },
		fillColor        = { hex = "#292929", alpha = 1 },
		roundedRectRadii = { xRadius = 5, yRadius = 5 },
	}

	--------------------------------------------------------------------------------
	-- Text:
	--------------------------------------------------------------------------------
	widgetCanvas[#widgetCanvas + 1] = {
		id = "text",
		frame = { h = 30, w = 150, x = 10, y = 6 },
		text = getWidgetText(id, aspect),
		textAlignment = "left",
		textColor = { white = 1.0 },
		textSize = 12,
		type = "text",
	}

	--------------------------------------------------------------------------------
	-- Circle:
	--------------------------------------------------------------------------------
	widgetCanvas[#widgetCanvas + 1] = {
		id				 	= "circle",
		type           		= "circle",
		radius				= "7%",
		center				=  { x = "90%", y = "50%" },
		action           	= "strokeAndFill",
		strokeColor      	= color,
		fillColor        	= fillColor,
	}

	--------------------------------------------------------------------------------
	-- Arc:
	--------------------------------------------------------------------------------
	local arcAction = "skip"
	if colorBoard:selectedPanel() == "color" and aspect == "*" then
		arcAction = "strokeAndFill"
	end
	widgetCanvas[#widgetCanvas + 1] = {
		id				 	= "arc",
		type           		= "arc",
		radius				= "7%",
		center				=  { x = "90%", y = "50%" },
		startAngle			= 135,
		endAngle			= 315,
		action           	= arcAction,
		strokeColor      	= color,
		fillColor        	= color,
	}

	--------------------------------------------------------------------------------
	-- Negative Symbol (Used for Color Panel):
	--------------------------------------------------------------------------------
	local negativeType = "skip"
	if negative then negativeType = "strokeAndFill" end
	widgetCanvas[#widgetCanvas + 1] = {
		id				= "negative",
		type            = "rectangle",
		action          = negativeType,
		strokeColor     = {white=1, alpha=0.75},
		strokeWidth		= 1,
		fillColor       = {white=0, alpha=1.0 },
		frame 			= { h = 5, w = 10, x = 130, y = 12 },
	}

	--------------------------------------------------------------------------------
	-- Text:
	--------------------------------------------------------------------------------
	local textValue = value .. "%" or ""
	widgetCanvas[#widgetCanvas + 1] = {
		id = "info",
		frame = { h = 30, w = 120, x = 0, y = 6 },
		text = textValue,
		textAlignment = "right",
		textColor = { white = 1.0 },
		textSize = 12,
		type = "text",
	}

	--------------------------------------------------------------------------------
	-- Touch Events:
	--------------------------------------------------------------------------------
	widgetCanvas:canvasMouseEvents(true, true, false, true)
		:mouseCallback(function(o,m,i,x,y)

			--------------------------------------------------------------------------------
			-- Stop the timer:
			--------------------------------------------------------------------------------
			mod.stop()

			--------------------------------------------------------------------------------
			-- Detect Double Taps:
			--------------------------------------------------------------------------------
			local skipMaths = false
			if m == "mouseDown" then
				if mod._doubleTap[id] == true then
					--------------------------------------------------------------------------------
					-- Reset Puck:
					--------------------------------------------------------------------------------
					mod._doubleTap[id] = false
					colorBoard:applyPercentage(aspect, property, 0)

					local defaultValues = {
						["global"] = 110,
						["shadows"] = 180,
						["midtones"] = 215,
						["highlights"] = 250,
					}

					colorBoard:applyAngle(aspect, property, defaultValues[property])
					skipMaths = true
				else
					mod._doubleTap[id] = true
				end
				timer.doAfter(eventtap.doubleClickInterval(), function()
					mod._doubleTap[id] = false
				end)
			end

			--------------------------------------------------------------------------------
			-- Show the Color Board if it's hidden:
			--------------------------------------------------------------------------------
			if not colorBoard:isShowing() then
				colorBoard:show()
			end

			--------------------------------------------------------------------------------
			-- Abort if Color Board is not active:
			--------------------------------------------------------------------------------
			if not colorBoard:isActive() then
				return
			end

			--------------------------------------------------------------------------------
			-- Check for keyboard modifiers:
			--------------------------------------------------------------------------------
			local mods = eventtap.checkKeyboardModifiers()
			local shiftPressed = false
			if mods['shift'] and not mods['cmd'] and not mods['alt'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
				shiftPressed = true
			end
			local controlPressed = false
			if mods['ctrl'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['capslock'] and not mods['fn'] then
				controlPressed = true
			end

			--------------------------------------------------------------------------------
			-- Do the maths:
			--------------------------------------------------------------------------------
			if shiftPressed then
				x = x * 2.4
			else
				if controlPressed then
					x = (x-75) * 1.333
				else
					x = (x-75) * 0.75
				end
			end

			--------------------------------------------------------------------------------
			-- Update UI:
			--------------------------------------------------------------------------------
			updateCanvas(o, id, aspect, property)

			--------------------------------------------------------------------------------
			-- Perform Action:
			--------------------------------------------------------------------------------
			if not skipMaths then
				if m == "mouseDown" or m == "mouseMove" then
					if shiftPressed then
						colorBoard:applyAngle(aspect, property, x)
					else
						colorBoard:applyPercentage(aspect, property, x)
					end
				elseif m == "mouseUp" then
				end
			end

			--------------------------------------------------------------------------------
			-- Start the timer:
			--------------------------------------------------------------------------------
			mod.start()

	end)

	--------------------------------------------------------------------------------
	-- Add update callback to timer:
	--------------------------------------------------------------------------------
	mod._updateCallbacks[#mod._updateCallbacks + 1] = function() updateCanvas(widgetCanvas, id, aspect, property) end

	--------------------------------------------------------------------------------
	-- Update the Canvas:
	--------------------------------------------------------------------------------
	updateCanvas(widgetCanvas, id, aspect, property)

	return touchbar.item.newCanvas(widgetCanvas, id):canvasClickColor{ alpha = 0.0 }

end

local function switchToPanel(aspect)
	local colorBoard = fcp:colorBoard()
	if colorBoard then
		colorBoard:showPanel(aspect)
	end
end

local function switchToPanel(aspect)
	local colorBoard = fcp:colorBoard()
	if colorBoard then
		colorBoard:showPanel(aspect)
	end
end

local function groupPuck(id)

	--------------------------------------------------------------------------------
	-- Setup Toggle Button:
	--------------------------------------------------------------------------------
	local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 50}
	widgetCanvas[#widgetCanvas + 1] = {
		id				 = "background",
		type             = "rectangle",
		action           = "strokeAndFill",
		strokeColor      = { white = 1 },
		fillColor        = { hex = "#292929", alpha = 1 },
		roundedRectRadii = { xRadius = 5, yRadius = 5 },
	}
	widgetCanvas[#widgetCanvas + 1] = {
		id = "text",
		frame = { h = 30, w = 50, x = 0, y = 6 },
		text = "Toggle",
		textAlignment = "center",
		textColor = { white = 1.0 },
		textSize = 12,
		type = "text",
	}
	widgetCanvas:canvasMouseEvents(true, true, false, true)
		:mouseCallback(function(o,m,i,x,y)
			if m == "mouseDown" or m == "mouseMove" then
				fcp:colorBoard():togglePanel()
			end
		end)

	--------------------------------------------------------------------------------
	-- Setup Group:
	--------------------------------------------------------------------------------
	local group = touchbar.item.newGroup(id):groupItems({
		touchbar.item.newCanvas(widgetCanvas):canvasClickColor{ alpha = 0.0 },
		puckWidget("colorBoardGroup1", "*", "global"),
		puckWidget("colorBoardGroup2", "*", "shadows"),
		puckWidget("colorBoardGroup3", "*", "midtones"),
		puckWidget("colorBoardGroup4", "*", "highlights"),
	})
	return group

end

--- plugins.finalcutpro.touchbar.widgets.colorboard.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

	--------------------------------------------------------------------------------
	-- Color Board Group:
	--------------------------------------------------------------------------------
	local params = {
		group = "fcpx",
		text = "Color Board (Grouped)",
		subText = "Color Board Panel Toggle Button & 4 x Puck Controls.",
		item = groupPuck("colorBoardGroup"),
	}
	deps.manager.widgets:new("colorBoardGroup", params)

	--------------------------------------------------------------------------------
	-- Active Puck Controls:
	--------------------------------------------------------------------------------
	local params = {
		group = "fcpx",
		text = "Color Board Puck 1",
		subText = "Allows you to control puck one of the Color Board.",
		item = puckWidget("colorBoardPuck1", "*", "global"),
	}
	deps.manager.widgets:new("colorBoardPuck1", params)

	local params = {
		group = "fcpx",
		text = "Color Board Puck 2",
		subText = "Allows you to control puck two of the Color Board.",
		item = puckWidget("colorBoardPuck2", "*", "shadows"),
	}
	deps.manager.widgets:new("colorBoardPuck2", params)

	local params = {
		group = "fcpx",
		text = "Color Board Puck 3",
		subText = "Allows you to control puck three of the Color Board.",
		item = puckWidget("colorBoardPuck3", "*", "midtones"),
	}
	deps.manager.widgets:new("colorBoardPuck3", params)

	local params = {
		group = "fcpx",
		text = "Color Board Puck 4",
		subText = "Allows you to control puck four of the Color Board.",
		item = puckWidget("colorBoardPuck4", "*", "highlights"),
	}
	deps.manager.widgets:new("colorBoardPuck4", params)

	--------------------------------------------------------------------------------
	-- Color Panel:
	--------------------------------------------------------------------------------
	local params = {
		group = "fcpx",
		text = "Color Board Color Puck 1",
		subText = "Allows you to the Color Panel of the Color Board.",
		item = puckWidget("colorBoardColorPuck1", "color", "global"),
	}
	deps.manager.widgets:new("colorBoardColorPuck1", params)

	local params = {
		group = "fcpx",
		text = "Color Board Color Puck 2",
		subText = "Allows you to the Color Panel of the Color Board.",
		item = puckWidget("colorBoardColorPuck2", "color", "shadows"),
	}
	deps.manager.widgets:new("colorBoardColorPuck2", params)

	local params = {
		group = "fcpx",
		text = "Color Board Color Puck 3",
		subText = "Allows you to the Color Panel of the Color Board.",
		item = puckWidget("colorBoardColorPuck3", "color", "midtones"),
	}
	deps.manager.widgets:new("colorBoardColorPuck3", params)

	local params = {
		group = "fcpx",
		text = "Color Board Color Puck 4",
		subText = "Allows you to the Color Panel of the Color Board.",
		item = puckWidget("colorBoardColorPuck4", "color", "highlights"),
	}
	deps.manager.widgets:new("colorBoardColorPuck4", params)

	--------------------------------------------------------------------------------
	-- Saturation Panel:
	--------------------------------------------------------------------------------
	local params = {
		group = "fcpx",
		text = "Color Board Saturation Puck 1",
		subText = "Allows you to the Saturation Panel of the Color Board.",
		item = puckWidget("colorBoardSaturationPuck1", "saturation", "global"),
	}
	deps.manager.widgets:new("colorBoardSaturationPuck1", params)

	local params = {
		group = "fcpx",
		text = "Color Board Saturation Puck 2",
		subText = "Allows you to the Saturation Panel of the Color Board.",
		item = puckWidget("colorBoardSaturationPuck2", "saturation", "shadows"),
	}
	deps.manager.widgets:new("colorBoardSaturationPuck2", params)

	local params = {
		group = "fcpx",
		text = "Color Board Saturation Puck 3",
		subText = "Allows you to the Saturation Panel of the Color Board.",
		item = puckWidget("colorBoardSaturationPuck3", "saturation", "midtones"),
	}
	deps.manager.widgets:new("colorBoardSaturationPuck3", params)

	local params = {
		group = "fcpx",
		text = "Color Board Saturation Puck 4",
		subText = "Allows you to the Saturation Panel of the Color Board.",
		item = puckWidget("colorBoardSaturationPuck4", "saturation", "highlights"),
	}
	deps.manager.widgets:new("colorBoardSaturationPuck4", params)

	--------------------------------------------------------------------------------
	-- Exposure Panel:
	--------------------------------------------------------------------------------
	local params = {
		group = "fcpx",
		text = "Color Board Exposure Puck 1",
		subText = "Allows you to the Exposure Panel of the Color Board.",
		item = puckWidget("colorBoardExposurePuck1", "exposure", "global"),
	}
	deps.manager.widgets:new("colorBoardExposurePuck1", params)

	local params = {
		group = "fcpx",
		text = "Color Board Exposure Puck 2",
		subText = "Allows you to the Exposure Panel of the Color Board.",
		item = puckWidget("colorBoardExposurePuck2", "exposure", "shadows"),
	}
	deps.manager.widgets:new("colorBoardExposurePuck2", params)

	local params = {
		group = "fcpx",
		text = "Color Board Exposure Puck 3",
		subText = "Allows you to the Exposure Panel of the Color Board.",
		item = puckWidget("colorBoardExposurePuck3", "exposure", "midtones"),
	}
	deps.manager.widgets:new("colorBoardExposurePuck3", params)

	local params = {
		group = "fcpx",
		text = "Color Board Exposure Puck 4",
		subText = "Allows you to the Exposure Panel of the Color Board.",
		item = puckWidget("colorBoardExposurePuck4", "exposure", "highlights"),
	}
	deps.manager.widgets:new("colorBoardExposurePuck4", params)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.touchbar.widgets.colorboard",
	group			= "finalcutpro",
	dependencies	= {
		["core.touchbar.manager"] = "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Only enable the timer when Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:watch({
		active		= mod.start,
		inactive	= mod.stop,
		show		= mod.start,
		hide		= mod.stop,
	})

	return mod.init(deps)
end

return plugin