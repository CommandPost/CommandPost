--- === cp.rx ===
---
--- Reactive Extensions for Lua.
---
--- RxLua gives Lua the power of Observables, which are data structures that represent a stream of values that arrive over time. They're very handy when dealing with events, streams of data, asynchronous requests, and concurrency.
---
---  * Originally forked from: https://github.com/bjornbytes/rxlua
---  * MIT License: https://github.com/bjornbytes/RxLua/blob/master/LICENSE

local require               = require

local util                  = require "cp.rx.util"
local Reference             = require "cp.rx.Reference"
local Observer              = require "cp.rx.Observer"
local Observable            = require "cp.rx.Observable"
local ImmediateScheduler    = require "cp.rx.ImmediateScheduler"
local CooperativeScheduler  = require "cp.rx.CooperativeScheduler"
local TimeoutScheduler      = require "cp.rx.TimeoutScheduler"
local Subject               = require "cp.rx.Subject"
local AsyncSubject          = require "cp.rx.AsyncSubject"
local BehaviorSubject       = require "cp.rx.BehaviorSubject"
local ReplaySubject         = require "cp.rx.ReplaySubject"

return {
  util = util,
  Reference = Reference,
  Observer = Observer,
  Observable = Observable,
  ImmediateScheduler = ImmediateScheduler,
  CooperativeScheduler = CooperativeScheduler,
  TimeoutScheduler = TimeoutScheduler,
  Subject = Subject,
  AsyncSubject = AsyncSubject,
  BehaviorSubject = BehaviorSubject,
  ReplaySubject = ReplaySubject
}
