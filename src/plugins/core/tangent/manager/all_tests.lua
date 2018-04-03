local require       = require
local test 		    = require("cp.test")

return test.suite("cp") :with {
    require "named_test",
    require "action_test",
    require "parameter_test",
    require "menu_test",
    require "binding_test",
    require "group_test",
}