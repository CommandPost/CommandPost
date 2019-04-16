local Action                = require "cp.spec2.Action"
local Message               = require "cp.spec2.Message"

local RunTest = Action:subclass("cp.spec.action.RunTest")

function RunTest:initialize(report, testFn)
    Action.initialize(self, function()
        local ok, result = xpcall(function() testFn(self) end, function(err)
            if not Message.is(err) then
                err = Message(err)
            end
            err:traceback()
            return err
        end)

        if 
    end)
end

function RunTest:wait(seconds)
    self.waiting = true
    self...
end

return RunTest