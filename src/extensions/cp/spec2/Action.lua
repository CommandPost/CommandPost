local class             = require "middleclass"

local Action = class("cp.spec2.Action")

function Action:initialize(actionFn)
    self._fn = actionFn
end

function Action:run()
    local result = self:_fn()
    if result then
        result:run()
    end
end

return Action