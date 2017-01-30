local random = math.random

-- Initialize the pseudo random number generator
math.randomseed( os.time() )
math.random(); math.random(); math.random()
-- done. :-)

local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

return uuid