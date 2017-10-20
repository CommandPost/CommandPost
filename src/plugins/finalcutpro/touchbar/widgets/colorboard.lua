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
local window   			= require("hs.window")

local touchbar 			= require("hs._asm.undocumented.touchbar")

local fcp				= require("cp.apple.finalcutpro")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
	if angle and pct < 0 then
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
		[2] = "Shadows",
		[3] = "Midtones",
		[4] = "Highlights",
	}

	if aspect == "*" then
		local selectedPanel = colorBoard:selectedPanel()
		if selectedPanel then
			if aspectTitle[selectedPanel] and puckTitle[puckID] then
				widgetText = aspectTitle[selectedPanel] .. ": " .. puckTitle[puckID]
			else
				log.ef("Something went wrong")
			end
		else
			widgetText = puckTitle[puckID]
		end
	else
		widgetText = aspectTitle[aspect] .. ": " .. puckTitle[puckID]
	end
	return widgetText
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
	-- Touch Events:
	--------------------------------------------------------------------------------
	widgetCanvas:canvasMouseEvents(true, true, false, true)
		:mouseCallback(function(o,m,i,x,y)

			--------------------------------------------------------------------------------
			-- Update Text Value:
			--------------------------------------------------------------------------------
			widgetCanvas.text.text = getWidgetText(id, aspect)

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

			if shiftPressed then
				x = x * 3.6
			else
				x = (x - 50) * 2
			end

			--------------------------------------------------------------------------------
			-- Update UI:
			--------------------------------------------------------------------------------
			local pct = colorBoard:getPercentage(aspect, property)
			local angle	= colorBoard:getAngle(aspect, property)

			local brightness, solidColor, fillColor, negative = calculateColor(pct, angle)

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

			--------------------------------------------------------------------------------
			-- Perform Action:
			--------------------------------------------------------------------------------
			if m == "mouseDown" or m == "mouseMove" then
				if shiftPressed then
					colorBoard:applyAngle(aspect, property, x)
				else
					colorBoard:applyPercentage(aspect, property, x)
				end
			elseif m == "mouseUp" then
			end
	end)

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

	local params = {
		group = "fcpx",
		text = "Color Board",
		subText = "Adds Color Board Panel buttons and puck controllers.",
		item = groupPuck("colorBoardGroup"),
	}
	deps.manager.widgets:new("colorBoardGroup", params)

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
	return mod.init(deps)
end

return plugin