--- === cp.apple.motion.app ===
---
--- The `cp.app` for Apple's Motion.

local require       = require
local app           = require("cp.app")


local motionApp = app.forBundleID("com.apple.motionapp")
return motionApp
