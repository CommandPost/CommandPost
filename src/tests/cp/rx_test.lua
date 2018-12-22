local test                      = require("cp.test")

return test.suite("cp.rx")
:with {
    require "cp.rx.Observable_test",
    require "cp.rx.Subject_test",
    require "cp.rx.AsyncSubject_test",
    require "cp.rx.BehaviorSubject_test",
    require "cp.rx.ReplaySubject_test",
    require "cp.rx.go_test",
}