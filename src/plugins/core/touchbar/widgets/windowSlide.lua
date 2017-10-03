--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    T O U C H    B A R    W I D G E T                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.touchbar.widgets.windowSlide ===
---
--- Window Slide Widget for Touch Bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local canvas   			= require("hs.canvas")
local window   			= require("hs.window")
local screen   			= require("hs.screen")

local touchbar 			= require("hs._asm.undocumented.touchbar")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local ID = "windowSlide"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.widget()

	local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 150}
	widgetCanvas[#widgetCanvas + 1] = {
		type             = "rectangle",
		action           = "strokeAndFill",
		strokeColor      = { white = 1 },
		fillColor        = { white = .25 },
		roundedRectRadii = { xRadius = 5, yRadius = 5 },
	}
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

	widgetCanvas:canvasMouseEvents(true, true, false, true):mouseCallback(function(o,m,i,x,y)
		local max = mod.item:canvasWidth()
		local win = window.frontmostWindow()
		if not win then return end

		local screenFrame = screen.mainScreen():frame()
		local winFrame    = win:frame()

		local newCenterPos = screenFrame.x + (x / max) * screenFrame.w
		local newWinX      = newCenterPos - winFrame.w / 2

		if m == "mouseDown" or m == "mouseMove" then
			win:setTopLeft{ x = newWinX, y = winFrame.y }
			widgetCanvas.zigzag.coordinates[2].x = x - 10
			widgetCanvas.zigzag.coordinates[3].x = x - 5
			widgetCanvas.zigzag.coordinates[4].x = x + 5
			widgetCanvas.zigzag.coordinates[5].x = x + 10
		elseif m == "mouseUp" then
			widgetCanvas.zigzag.coordinates[2].x = 65
			widgetCanvas.zigzag.coordinates[3].x = 70
			widgetCanvas.zigzag.coordinates[4].x = 80
			widgetCanvas.zigzag.coordinates[5].x = 85
		end
	end)
	
	mod.item = touchbar.item.newCanvas(widgetCanvas, ID)
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

	local id = ID
	local params = {
		group = "global",
		text = "Window Slide",
		subText = "Allows you to slide window positions.",
		item = mod.widget(),
	}	
	deps.manager.widgets:new(id, params)

	return mod
	
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.touchbar.widgets.windowslide",
	group			= "core",
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