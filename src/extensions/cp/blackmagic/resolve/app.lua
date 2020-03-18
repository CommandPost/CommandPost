--- === cp.blackmagic.resolve.app ===
---
--- The `cp.app` for Blackmagic DaVinci Resolve.

local require       = require
local app           = require "cp.app"

local resolveApp = app.forBundleID("com.blackmagic-design.DaVinciResolve")
return resolveApp