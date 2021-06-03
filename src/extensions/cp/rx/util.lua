-- private utility module for `cp.rx`.
local util = {}

local defaultScheduler = nil

util.pack = table.pack or function(...) return { n = select('#', ...), ... } end
util.unpack = table.unpack or _G.unpack
util.eq = function(x, y) return x == y end
util.noop = function() end
util.identity = function(x) return x end
util.constant = function(x) return function() return x end end
util.isa = function(object, class)
  if type(object) == 'table' then
    local mt = getmetatable(object)
    return mt ~= nil and rawequal(mt.__index, class) or not rawequal(mt, object) and util.isa(mt, class)
  end
  return false
end
util.tryWithObserver = function(observer, fn, ...)
  local args = util.pack(...)
  local success, result = xpcall(function() fn(util.unpack(args)) end, function(message) return debug.traceback(message, 2) end)
  if not success then
    observer:onError(result)
  end
  return success, result
end
util.defaultScheduler = function(newScheduler)
    if newScheduler and type(newScheduler.schedule) == "function" then
        defaultScheduler = newScheduler
    end
    return defaultScheduler
end
util.tableId = function(value)
    local __tostring
    local mt = getmetatable(value)
    if mt then
        __tostring = mt.__tostring
        mt.__tostring = nil
    end

    local id = tostring(value)

    if mt then
        mt.__tostring = __tostring
    end
    return id
end

return util