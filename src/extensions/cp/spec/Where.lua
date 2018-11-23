local require                   = require

local Definition                = require "cp.spec.Definition"
local Run                       = require "cp.spec.Run"

local format                    = string.format
local insert                    = table.insert

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

function RunWhere:initialize(definition, where)
    Run.initialize(self, definition)
    self.where = where
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

-- cp.spec.Where(scenario, whereData)
-- Construtor
-- Creates a new `Where`
--
-- Parameters:
-- * scenario     - The [Scenario](cp.spec.Scenario.md) where it spawned from.
function Where:initialize(scenario, whereData)
    self.testFn = scenario.testFn
    self.whereData = convertData(whereData)

    Definition.initialize(self, scenario.name)
end

function Where:run(...)
    self.currentRun = Run(function(this)
        this:continues()
        self:runNext(1, this)
    end)
    return self.currentRun
end

local function interpolate(name, data)
    -- TODO: implement interpolation
    return name
end

-- runNext(suite, index, this)
-- Function
-- Runs the next test definition at the specified `index`, if available.
-- If not, the `this:passed()` method is called to complete the test.
function Where:runNext(index, whereThis)
    local data = self.whereData[index]
    if data then
        local currentName = interpolate(self.name, data)
        local run = Run(currentName, self.testFn)
        :start(function(this)
            for k,v in pairs(data) do
                if this[k] then
                    error(format("Existing %q value in `this`: %s", k, type(this[k])))
                end
                this[k] = v
            end
        end)
        :complete(function(this)
            -- output a summary if we have a parent and it's verbose
            if this.run.parent ~= nil and self:verbose() then
                self.result:summary()
            end

            -- add the run results
            this.run.result:add(self.currentRun.result)
            -- onto the next run...
            self:runNext(index + 1, this)
        end)
        :parent(self.currentRun)

        if self._beforeEach then
            run:before(self._beforeEach)
        end
        if self._afterEach then
            run:after(self._afterEach)
        end
    else
        -- drop the extra pass for the suite itself
        whereThis.run.result.passes = whereThis.run.result.passes - 1
        whereThis:passed()
    end
end

return Where