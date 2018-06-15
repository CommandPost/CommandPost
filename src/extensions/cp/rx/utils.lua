local log           = require("hs.logger").new("rxutils")
local inspect       = require("hs.inspect")

local timer         = require("hs.timer")
local rx            = require("cp.rx")

local Observable    = rx.Observable
local insert        = table.insert
local pack, unpack  = table.pack, table.unpack

local function is(thing, type)
    if type(thing) == "table" then
        type = type.mt or type
        return thing == type or is(getmetatable(thing), type)
    end
    return false
end

local Runner = {}
Runner.mt = {}
Runner.mt.__index = Runner.mt

function Runner.is(thing)
    return is(thing, Runner.mt)
end

function Runner.new(parent, observable, type)
    assert(Observable.is(observable), "Argument #2 must be an Observable.")
    local o = setmetatable({
        _parent = parent,
        _observable = observable,
    }, type or Runner.mt)

    if parent and parent._timer then
        parent._timer:stop()
        parent._timer = nil
    end
    o._timer = timer.doAfter(0, function()
        o:Now()
    end)
    return o
end

function Runner.mt:Now()
    local t = self._timer
    if t and t:running() then
        t:stop()
    end

    local obs = self._observable
    if Observable.is(obs) then
        local subject = rx.AsyncSubject.create()
        obs:subscribe(subject)
        return subject
    else
        error(string.format("Expected an Observable but got %s", inspect(obs)))
    end
end

local function flexZip(args, ...)
    local observables = {}
    args = args or {}
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        local obs
        if Observable.is(arg) then
            obs = arg
        elseif type(arg) == "function" then
            obs = arg(unpack(args))
            if not Observable.is(obs) then
                obs = Observable.of(obs)
            end
        else
            obs = Observable.of(arg)
        end

        insert(observables, obs or Observable.empty())
    end
    return Observable.zip(unpack(observables))
end

local Do = {}
Do.mt = setmetatable({}, Runner.mt)
Do.mt.__index = Do.mt
Do.mt.__tostring = function() return "Do" end

function Do.new(...)
    return Runner.new(nil, flexZip(nil, ...), Do.mt)
end

setmetatable(Do, {
    __call = function(_,...) return Do.new(...) end,
})

function Do.mt:Then(...)
    return Do.Then.new(self, ...)
end

Do.Then = {}
Do.Then.mt = setmetatable({}, Runner.mt)
Do.Then.mt.__index = Do.Then.mt
Do.Then.mt.__tostring = function(self) return tostring(self._parent).."...Then" end

function Do.Then.new(parent, ...)
    local args = pack(...)
    local o = Runner.new(parent, parent._observable:flatMap(function(...)
        return flexZip(pack(...), unpack(args))
    end), Do.Then.mt)

    return o
end

function Do.Then.mt:Then(...)
    return Do.Then.new(self, ...)
end

return {
    Do = Do,
}