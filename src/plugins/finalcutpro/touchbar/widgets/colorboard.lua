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
local window   			= require("hs.window")
local screen   			= require("hs.screen")

local touchbar 			= require("hs._asm.undocumented.touchbar")

local fcp				= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local function puckWidget(id, aspect, property)

	local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 150}

	-- Box:
	widgetCanvas[#widgetCanvas + 1] = {
		id				 = "background",
		type             = "rectangle",
		action           = "strokeAndFill",
		strokeColor      = { white = 1 },
		fillColor        = { white = .25 },
		roundedRectRadii = { xRadius = 5, yRadius = 5 },
	}

	--[[
	widgetCanvas[#widgetCanvas + 1] = {
		id          = "zigzag",
		type        = "segments",
		action      = "stroke",
		strokeColor = { blue = 1, green = 1 },
		coordinates = {
			{ x =   0, y = 15 },
			{ x =  65, y = 15 },
			{ x =  70, y =  5 },
			{ x =  80, y = 25 },
			{ x =  85, y = 15 },
			{ x = 150, y = 15},
		}
	}
	--]]

	widgetCanvas:canvasMouseEvents(true, true, false, true)
		:mouseCallback(function(o,m,i,x,y)

			local max = mod.item:canvasWidth()

			--------------------------------------------------------------------------------
			-- Show the Color Board with the correct panel
			--------------------------------------------------------------------------------
			local colorBoard = fcp:colorBoard()

			--------------------------------------------------------------------------------
			-- Show the Color Board if it's hidden:
			--------------------------------------------------------------------------------
			if not colorBoard:isShowing() then
				colorBoard:show()
			end

			if not colorBoard:isActive() then
				return
			end

			x = (x - 50) * 2

			if m == "mouseDown" or m == "mouseMove" then
				colorBoard:applyPercentage(aspect, property, x)
				widgetCanvas.background.fillColor = hs.drawing.color.definedCollections.hammerspoon.red
			elseif m == "mouseUp" then
				widgetCanvas.background.fillColor = { white = .25 }
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