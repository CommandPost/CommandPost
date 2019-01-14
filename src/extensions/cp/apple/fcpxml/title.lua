--- === cp.apple.fcpxml.title ===
---
--- FCPXML Document Title Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlTitle")

local fnutils       = require("hs.fnutils")

local config        = require("cp.config")
local flicks        = require("cp.time.flicks")
local tools         = require("cp.tools")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local xml           = require("hs._asm.xml")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.fcpxml.title.new(titleName, lane, offset, ref, duration, start, role, titleText, textStyleID, newTextStyle, newTextStyleAttributes) -> fcpxmlTitle Object
--- Constructor
--- Creates a new title to be used in a timeline.
---
--- Parameters:
---  * titleName
---  * lane
---  * offset
---  * ref
---  * duration
---  * start
---  * role
---  * titleText
---  * textStyleID
---  * newTextStyle
---  * newTextStyleAttributes
---
--- Returns:
---  * A new Title object.
---
--- Notes:
---  * `newTextStyleAttributes` is only used if `newTextStyle` is set to `true`.
---  * When `newTextStyle` is set to `true`, the following atttributes can be used
---    within the `newTextStyleAttributes` table:
---      * font - The font name as string (defaults to "Helvetica").
---      * fontSize - The font size a number (defaults to 62).
---      * fontFace - The font face as a string (defaults to "Regular").
---      * fontColor - The font color as a `hs.drawing.color` object (defaults to black).
---      * strokeColor - The stroke color as a `hs.drawing.color` object (defaults to `nil`).
---      * strokeWidth - The stroke width as a number (defaults to 2).
---      * shadowColor - The stroke color as a `hs.drawing.color` object (defaults to `nil`).
---      * shadowDistance - The shadow distance as a number (defaults to 5).
---      * shadowAngle - The shadow angle as a number (defaults to 315).
---      * shadowBlurRadius - The shadow blur radius as a number (defaults to 1).
---      * alignment - The text alignment as a string (defaults to "center").
---      * xPosition - The x position of the title (defaults to 0).
---      * yPosition - The y position of the title (defaults to 0).
function mod.new(titleName, lane, offset, ref, duration, start, role, titleText, textStyleID, newTextStyle, newTextStyleAttributes)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod