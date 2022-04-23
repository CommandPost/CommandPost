--- === cp.ui.Column ===
---
--- Represents a Column in a Table.

local require = require

-- local log                                   = require "hs.logger".new "Column"

local Element                               = require "cp.ui.Element"

local Column = Element:subclass("cp.ui.Column")

return Column