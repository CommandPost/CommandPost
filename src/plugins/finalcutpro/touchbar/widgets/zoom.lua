--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    T O U C H    B A R    W I D G E T                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.touchbar.widgets.zoom ===
---
--- Final Cut Pro Zoom Control Widget for Touch Bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("zoomWidget")

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

function mod.widget()

	local canvasWidth, canvasHeight = 250, 30

	local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = canvasWidth}

	widgetCanvas[#widgetCanvas + 1] = {
		id				 = "background",
		type             = "rectangle",
		action           = "strokeAndFill",
		strokeColor      = { white = 1 },
		fillColor        = { hex = "#1d1d1d", alpha = 1 },
		roundedRectRadii = { xRadius = 5, yRadius = 5 },
	}

	widgetCanvas[#widgetCanvas + 1] = {
		id				 	= "startLine",
		type             	= "segments",
		coordinates			= {
			{x = 0, y = canvasHeight/2},
			{x = canvasWidth / 2, y = canvasHeight/2} },
		action           	= "stroke",
		strokeColor        	= { hex = "#5051e7", alpha = 1 },
		strokeWidth			= 1.5,
	}

	widgetCanvas[#widgetCanvas + 1] = {
		id				 	= "endLine",
		type             	= "segments",
		coordinates			= {
			{x = canvasWidth / 2, y = canvasHeight/2},
			{x = canvasWidth, y = canvasHeight/2} },
		action           	= "stroke",
		strokeColor        	= { white = 1.0 },
		strokeWidth			= 1.5,
	}

	widgetCanvas[#widgetCanvas + 1] = {
		id				 	= "circle",
		type             	= "circle",
		radius				= 10,
		action           	= "strokeAndFill",
		fillColor        	= { hex = "#414141", alpha = 1 },
		strokeWidth			= 1.5,
		center				= { x = canvasWidth / 2, y = canvasHeight / 2 },
	}

	widgetCanvas:canvasMouseEvents(true, true, false, true)
		:mouseCallback(function(o,m,i,x,y)

		 	if not fcp.isFrontmost() or not fcp:timeline():isShowing() then return end

			widgetCanvas.circle.center = {
				x = x,
				y = canvasHeight / 2,
			}

			widgetCanvas.startLine.coordinates = {
				{x = 0, y = canvasHeight/2},
				{x = x, y = canvasHeight/2},
			}

			widgetCanvas.endLine.coordinates = {
				{ x = x, y = canvasHeight / 2 },
				{ x = canvasWidth, y = canvasHeight / 2 },
			}

			if m == "mouseDown" or m == "mouseMove" then
				local appearance = fcp:timeline():toolbar():appearance()
				if appearance then
					appearance:show():zoomAmount():setValue(x/(canvasWidth/10))
				end
			elseif m == "mouseUp" then
				local appearance = fcp:timeline():toolbar():appearance()
				if appearance then
					fcp:timeline():toolbar():appearance():hide()
				end
			end
	end)

	mod.item = touchbar.item.newCanvas(widgetCanvas, "zoomSlider")
		:canvasClickColor{ alpha = 0.0 }

	return mod.item

end

--- plugins.finalcutpro.touchbar.widgets.zoom.init() -> nil
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
		text = "Zoom Slider",
		subText = "Allows you to control timeline zoom.",
		item = mod.widget(),
	}
	deps.manager.widgets:new("zoomSlider", params)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.touchbar.widgets.zoom",
	group			= "finalcutpro",
	dependencies	= {
		["core.touchbar.manager"] = "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	if touchbar.supported() then
		return mod.init(deps)
	end
end

return plugin