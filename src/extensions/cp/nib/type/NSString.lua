--- === cp.nib.type.NSString ===
---
--- A metatype for unarchived `NSString` objects.

local NSString = {}

NSString.__index = NSString

function NSString:__tostring()
    return self["NS.bytes"]
end

function NSString:value()
    return self["NS.bytes"]
end

return NSString