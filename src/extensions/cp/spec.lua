--- === cp.spec ===
---
--- An asynchronous test suite for Lua.
local require               = require

local Handler               = require "cp.spec.Handler"
local DefaultHandler        = require "cp.spec.DefaultHandler"
local Report                = require "cp.spec.Report"
local Run                   = require "cp.spec.Run"
local Definition            = require "cp.spec.Definition"
local Where                 = require "cp.spec.Where"
local Scenario              = require "cp.spec.Scenario"
local Specification         = require "cp.spec.Specification"

local expect                = require "cp.spec.expect"

--- cp.spec.describe(name) -> function(definitions) -> cp.spec.Specification
--- Function
--- Returns a `function` which will accept a list of test [Definitions](cp.spec.Definition.md),
--- or a `table` of [Definitions](cp.spec.Definition.md).
---
--- Parameters:
--- * name      - The name of the test suite.
---
--- Returns:
--- * A `function` that must be called with the set of [Definitions](cp.spec.Definition.md) or [suites](cp.spec.Specification.md) to run.
local function describe(name)
    return function(...)
        return Specification(name):with(...)
    end
end

--- cp.spec.describe(name) -> function(definitions) -> cp.spec.Specification
--- Function
--- Returns a `function` which will accept a list of test [definitions](cp.spec.Definition.md),
--- or a `table` of [definitions](cp.spec.Definition.md).
---
--- Parameters:
--- * name      - The name of the test suite.
---
--- Returns:
--- * A `function` that must be called with the set of [definitions](cp.spec.Definition.md) or [suites](cp.spec.Specification.md) to run.
local context = describe

--- cp.spec.it(name[, ...]) -> cp.spec.Scenario
--- Function
--- Returns an [Scenario](cp.spec.Scenario.md) with the specified name and optional `doingFn` function.
--- If the function is not provided, it must be done via the [doing](#doing) method prior to running.
---
--- Parameters:
--- * name      - The name of the scenario.
--- * doingFn   - (optional) The `function` to call when doing the operation. Will be passed the [Run.This](cp.spec.Run.This.md)
---     instance for the definition.
---
--- Notes:
--- * See [doing](cp.spec.Scenario.md#doing) for more details regarding the function.
local function it(name, doingFn)
    return Scenario("it " .. name, doingFn)
end

-- The path to search to find `spec` files. Defaults to the standard path.
local searchPath = nil

--- cp.spec.setSearchPath(path)
--- Function
--- Sets the path that will be used to search for `spec` files with the `spec "my.extension"` call.
--- By default it will search the current package path. If specified, it will also search the provided path.
---
--- Parameters:
--- * path - The path to search for `spec` files. Set to `nil` to only search the default package path.
local function setSearchPath(path)
    searchPath = path
end

--- cp.spec(item) -> cp.spec.Definition
--- Function
--- This will search the package path (and [specPath](#setSpecPath), if set) for `_spec.lua` files.
--- It will first look for a file ending with `_spec.lua`, then will look for a file named `_spec.lua` in the folder.
---
--- For example, if you run `require "cp.spec" "foo.bar"`, it will first look for `"foo/bar_spec.lua"`, then `"foo/bar/_spec.lua"`.
--- This gives flexibility for extensions that are organised as single files or as folders.
local function find(id)
    id = id or ""
    local testsPath = package.path
    if searchPath then
        testsPath = searchPath .. "/?.lua;" .. searchPath .. "/?/init.lua"
    end

    local testId = id .. "_spec"

    if not package.searchpath(testId, testsPath) then
        if package.searchpath(id .. "._spec", testsPath) then
            testId = id .. "._spec"
        else
            error(string.format("Unable to find specs for '%s'.", id), 2)
        end
    end

    local originalPath = package.path
    local tempPath = testsPath .. ";" .. originalPath

    package.path = tempPath

    local ok, result = xpcall(function() return require(testId) end, function() return debug.traceback("Finding '" .. id .. "' spec failed.", 2) end)

    package.path = originalPath

    if not ok then
        error(result, 2)
    elseif not Definition:is(result) then
        error("Ensure the spec file returns the test specification.", 2)
    else
        return result
    end
end

return setmetatable({
    Handler = Handler,
    DefaultHandler = DefaultHandler,
    Report = Report,
    Run = Run,
    Definition = Definition,
    Scenario = Scenario,
    Where = Where,
    Specification = Specification,
    describe = describe,
    context = context,
    it = it,
    expect = expect,
    setSearchPath = setSearchPath,
}, {
    __call = function(_, ...)
        return find(...)
    end
})