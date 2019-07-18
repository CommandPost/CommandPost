--- === cp.highland2.app ===
---
--- The `cp.app` for Highland 2.

local require = require

local app               = require "cp.app"
local Document          = require "cp.highland2.Document"

local bundleID = "com.quoteunquoteapps.highlandapp2"

local highland = app.forBundleID(bundleID)
    :registerWindowType(Document)

return highland
