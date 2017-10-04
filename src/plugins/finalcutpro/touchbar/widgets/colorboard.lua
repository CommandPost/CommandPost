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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local function puckWidget(id, aspect, property)

	local colorBoard = fcp:colorBoard()

	local value = colorBoard:getPercentage(aspect, property)
	if value == nil then value = 0 end

	local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 150}

	widgetCanvas[#widgetCanvas + 1] = {
		id				 = "background",
		type             = "rectangle",
		action           = "strokeAndFill",
		strokeColor      = { white = 1 },
		fillColor        = { white = value / 100 },
		roundedRectRadii = { xRadius = 5, yRadius = 5 },
	}

	widgetCanvas:canvasMouseEvents(true, true, false, true)
		:mouseCallback(function(o,m,i,x,y)

			local max = mod.item:canvasWidth()

			--------------------------------------------------------------------------------
			-- Show the Color Board if it's hidden:
			--------------------------------------------------------------------------------
			if not colorBoard:isShowing() then
				colorBoard:show()
			end

			if not colorBoard:isActive() then
				return
			end

			local mods = eventtap.checkKeyboardModifiers()
			local altPressed = false
			if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
				altPressed = true
			end

			if altPressed then
				x = x * 3.6
			else
				x = (x - 50) * 2
			end

			widgetCanvas.background.fillColor = { white = x/100 }

			if m == "mouseDown" or m == "mouseMove" then
				if altPressed then
					colorBoard:applyAngle(aspect, property, x)
				else
					colorBoard:applyPercentage(aspect, property, x)
				end
			elseif m == "mouseUp" then
			end
	end)

	mod.item = touchbar.item.newCanvas(widgetCanvas, id)
		:canvasClickColor{ alpha = 0.0 }

	return mod.item

end

--- plugins.core.touchbar.widgets.test.init() -> nil
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