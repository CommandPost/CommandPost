local spec      = require "cp.spec"
local describe  = spec.describe

return describe "cp.spec" {
    spec "cp.spec.async",
    spec "cp.spec.asyncfail",
    spec "cp.spec.describe",
    spec "cp.spec.fail",
    spec "cp.spec.it",
    spec "cp.spec.Run",
    spec "cp.spec.Scenario",
    spec "cp.spec.simple",
    spec "cp.spec.Specification",
    spec "cp.spec.tests",
    spec "cp.spec.where",
}