--- === cp.nib.decoder.Dictionary ===
---
--- Decodes a NIB object of class `"NSDictionary"` or `"NSMutableDictionary"`.

return function(instance, class, values)
    local classname = class.classname
    if classname ~= "NSDictionary" and classname ~= "NSMutableDictionary" then
        return false
    end

    local keys = values["NS.keys"]
    local values = values["NS.objects"]
    if not keys or not values then
        return false
    end

    for i,k in ipairs(keys) do
        instance[k] = values[i]
    end
    return true
end