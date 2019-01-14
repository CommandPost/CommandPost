--- === cp.apple.finalcutpro.ids ===
---
--- Final Cut Pro IDs.

local require = require

local app               = require("cp.apple.finalcutpro.app")

local config            = require("cp.config")
local ids               = require("cp.ids")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
return ids.new(config.scriptPath .. "/cp/apple/finalcutpro/ids/v/", app.versionString)
