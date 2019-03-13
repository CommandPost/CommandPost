--- === cp.apple.motion.app ===
---
--- The `cp.app` for Apple's Motion.

local require       = require
local app           = require("cp.app")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local fcpApp = app.forBundleID("com.apple.motionapp")
return fcpApp
