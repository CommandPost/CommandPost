--- === cp.nib.types ===
---
--- A registry of supported object types for unarchived values.

local require                       = require

local NSString                      = require "cp.nib.type.NSString"

local mod = {
    NSLocalizableString = NSString,
    NSMutableString = NSString,
    NSString = NSString,
}

return mod