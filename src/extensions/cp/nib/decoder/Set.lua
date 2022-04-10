--- === cp.nib.decoder.Set ===
---
--- Decodes a NIB object of class `"NSSet"` or `"NSMutableSet"`.

return function(instance, class, values)
    local classname = class.classname
    if classname ~= "NSSet" and classname ~= "NSMutableSet" then
        return false
    end

    local nsObjects = values["NS.objects"]
    if not nsObjects then
        return false
    end

    for i,v in ipairs(nsObjects) do
        instance[i] = v
    end
    return true
end