--- === cp.nib.decoder.Array ===
---
--- Decodes a NIB object of class `"NSArray"` or `"NSMutableArray"`.

return function(instance, class, values)
    local classname = class.classname
    if classname ~= "NSArray" and classname ~= "NSMutableArray" then
        return false
    end

    local objects = values["NS.objects"]
    if not objects then
        return false
    end

    for i,v in ipairs(objects) do
        instance[i] = v
    end
    return true
end