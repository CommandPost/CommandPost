--- === hs.finalcutpro ===
---
--- API for Final Cut Pro
---
--- Authors:
---
---   Chris Hocking 	https://latenitefilms.com
---   David Peterson 	https://randomphotons.com
---

local finalcutpro = {}

local App									= require("hs.finalcutpro.App")

--- hs.finalcutpro.app() -> hs.application
--- Function
--- Returns the root Final Cut Pro application.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The root Final Cut Pro application.
---
function finalcutpro.app()
	if not finalcutpro._app then
		finalcutpro._app = App:new()
	end
	return finalcutpro._app
end

return finalcutpro