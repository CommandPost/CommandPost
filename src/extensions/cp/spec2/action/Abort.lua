local Action                = require "cp.spec2.Action"

local Abort = Action:subclass("cp.spec2.action.Abort")

function Abort:initialize(report, message)
    Action.initialize(self, function()
        report:aborted(message)
    end)
end

return Abort