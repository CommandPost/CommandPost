local require                   = require

local Definition                = require "cp.spec.Definition"
local Run                       = require "cp.spec.Run"

local insert                    = table.insert

local WHERE_NAME = "[WHERE]"

-- === cp.spec.RunWhere ===
--
-- Private implementation class.
--
-- This will run the provided [Definition](cp.spec.Definition.cp) once for each
-- data row in the provided data table, where the first row are all `string` values
-- providing the property names, and subsequent rows contain the data for those
-- values for each run.
--
-- Extends [Run](cp.spec.Run.md).
local RunWhere = Run:subclass("cp.spec.RunWhere")

function RunWhere:initialize(where)
    Run.initialize(self, WHERE_NAME)
    self.where = where
    setmetatable(self.shared, {
        __index = function(_, key)
            if self.data then
                return self.data[key]
            end
            -- look up the parent Run's shared data, if available.
            if self._parent then
                return self._parent.shared[key]
            end
        end
    })
end

--- === cp.spec.Where ===
---
--- Created via [Scenario:where(...)](cp.spec.Scenario.md#where).
---
--- Extends [Definition](cp.spec.Definition.md)
local Where = Definition:subclass("cp.spec.Where")

local function convertData(whereData)
    local data = {}

    if #whereData > 1 then
        local titles = whereData[1]

        for i = 2,#whereData do
            local item = {}
            local row = whereData[i]
            for j,key in ipairs(titles) do
                item[key] = row[j]
            end
            insert(data, item)
        end
    end

    return data
end

-- cp.spec.Where(definition, whereData)
-- Construtor
-- Creates a new `Where`
--
-- Parameters:
-- * definition     - The [Definition](cp.spec.Definition.md) where it spawned from.
function Where:initialize(scenario, whereData)
    self.whereData = convertData(whereData)
    self.scenario = scenario

    Definition.initialize(self, WHERE_NAME)
end

function Where:run()
    self.currentRun = RunWhere(self)
    :onRunning(function(this)
        this:wait()
        self:_runNext(1, this)
    end)

    return self.currentRun
end

-- cp.spec.Where:_runNext(index, whereThis)
-- Function
-- Runs the next test definition at the specified `index`, if available.
-- If not, the `this:passed()` method is called to complete the test.
function Where:_runNext(index, whereThis)
    local data = self.whereData[index]
    if data then
        whereThis:log("running data row #%d: %s", index, hs.inspect(data))

        self.currentRun.data = data

        local run = self.scenario:run()

        run:parent(self.currentRun)
        :onComplete(function(this)
            local report = this:run().report

            -- add the run reports
            self.currentRun.report:add(report)
            -- onto the next run...
            self:_runNext(index + 1, whereThis)
        end)

        if self._beforeEach then
            run:onBefore(self._beforeEach)
        end
        if self._afterEach then
            run:onAfter(self._afterEach)
        end
    else
        whereThis:log("done...")
        whereThis:done(true)
    end
end

return Where