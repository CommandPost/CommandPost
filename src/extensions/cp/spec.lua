--- === cp.spec ===
---
--- An synchronous/asynchronous test library for Lua.
---
--- This library uses a syntax similar to Ruby RSpec or Mocha.js.
---
--- ## Simple Synchronous Test
---
--- To create a test, create a new file ending with `_spec.lua`. For example, `simple_spec.lua`:
---
--- ```lua
--- local spec          = require "cp.spec"
--- local it            = spec.it
---
--- return it "always passes"
--- :doing(function()
---     assert(true, "This always passes")
--- end)
--- ```
---
--- It can be run from the Debug Console like so:
---
--- ```
--- cp.spec "simple" ()
--- ```
---
--- It will report something like this:
---
--- ```
--- 2019-10-06 18:13:28: [RESULT] it always passes: passed: 1; failed: 0; aborted: 0; time: 0.0022s
--- ```
---
--- ## Simple Synchronous Failure
---
--- If a test fails, it gives a report of where it failed, and if provided, the related message:
---
--- ```lua
--- local spec          = require "cp.spec"
--- local it            = spec.it
---
--- return it "always fails"
--- :doing(function()
---     assert(false, "This always fails")
--- end)
--- ```
---
--- This will result in something like this:
---
--- ```
--- 2019-10-06 21:54:16:   [FAIL] it always fails: [.../simple_spec.lua:6] This always fails
--- 2019-10-06 21:54:16:
--- 2019-10-06 21:54:16: [RESULT] it always fails: passed: 0; failed: 1; aborted: 0; time: 0.0370s
--- ```
---
--- You can then check the line that failed and resolve the issue.
---
--- ## Simple Asynchronous Test
---
--- Performing an asynchronous test is only a little more complicated.
--- We'll modify our `simple_spec.lua` to use of the [Run.This](cp.spec.Run.This.md) instance available to every test:
---
--- ```lua
--- local spec          = require "cp.spec"
--- local it            = spec.it
--- local timer         = require "hs.timer"
---
--- return it "always passes"
--- :doing(function(this)
---     this:wait(5)
---     assert(true, "This happens immediately")
---     timer.doAfter(2, function()
---         assert(true, "This happens after 2 seconds.")
---         this:done()
---     end)
--- end)
--- ```
---
--- Other than using `hs.timer` to actually make this asynchronous, the key additions here are:
---  * `this:wait(5)`: Tells the test that it is asynchronous, and to wait 5 seconds before timing out.
---  * `this:done()`: Called inside the asynchronous function to indicate that it's complete.
---
--- Asycnchronous (and synchronous) tests can also be terminated by a failed `assert`, an `error` or a call to [this:fail(...)](cp.spec.Run.This.md#fail)
--- or [this:abort(...)](cp.spec.Run.This.md#abort)
---
--- ## Multiple tests
---
--- Most things you're testing will require more than a single test. For this,
--- We use [Specification](cp.spec.Specification.md), most simply via the [describe](#describe) function:
---
--- ```lua
--- local spec          = require "cp.spec"
--- local describe, it  = spec.describe, spec.it
---
--- local function sum(a,b)
---     return a + b
--- end
---
--- return describe "sum" {
---     it "results in 3 when you add 1 and 2"
---     :doing(function()
---         assert(sum(1, 2) == 3)
---     end),
---     it "results in 0 when you add 1 and -1"
---     :doing(function()
---         assert(sum(1, -1) == 0)
---     end),
--- }
--- ```
---
--- This will now run two tests, and report something like this:
---
--- ```
--- 2019-10-06 21:40:00: [RESULT] sum: passed: 2; failed: 0; aborted: 0; time: 0.0027s
--- ```
---
--- ## Data-driven Testing
---
--- When testing a feature, there are often multiple variations you want to test,
--- and repeating individual tests can get tedious.
---
--- This is a great place to use the [where](cp.spec.Scenario.md#where) feature.
--- Our previous test can become something like this:
---
--- ```lua
--- return describe "sum" {
---     it "results in ${result} when you add ${a} and ${b}"
---     :doing(function(this)
---         assert(sum(this.a, this.b) == this.result)
---     end)
---     :where {
---         { "a",  "b",    "result"},
---         { 1,    2,      3 },
---         { 1,    -1,     0 },
---     },
--- }
--- ```
---
--- Other variations can be added easily by adding more rows.
---
--- ## Running Multiple Specs
---
--- As shown above, you can run a single spec like so:
---
--- ```lua
--- cp.spec "path.to.spec" ()
--- ```
---
--- You can also run that spec an all other specs under the same path by adding `".*"` to the end.
---
--- ```lua
--- cp.spec "path.to.spec.*" ()
--- ```
---
--- Or run every spec in your system like so:
---
--- ```lua
--- cp.spec "*" ()
--- ```

local require               = require

local log                   = require "hs.logger" .new "spec"

local fs                    = require "hs.fs"

local Handler               = require "cp.spec.Handler"
local DefaultHandler        = require "cp.spec.DefaultHandler"
local Report                = require "cp.spec.Report"
local Run                   = require "cp.spec.Run"
local Definition            = require "cp.spec.Definition"
local Where                 = require "cp.spec.Where"
local Scenario              = require "cp.spec.Scenario"
local Specification         = require "cp.spec.Specification"

local TestCase              = require "cp.spec.TestCase"
local TestSuite             = require "cp.spec.TestSuite"

local expect                = require "cp.spec.expect"
local test                  = require "cp.test"

local format                = string.format

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

------- spec/test loading functions --------

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

-- loadSpecFile(path) -> function, string
-- Local Function
-- This will load a specified file with the spec `searchPath` added to the package path temporarily.
--
-- Parameters:
-- * path - the absolute path to the spec file to load.
--
-- Returns:
-- * function - a function which when executed will run the spec file and return the result. If there was a problem, this will be `nil`.
-- * err - If there was a problem, this will contain the error message.
local function loadSpecFile(path)
    -- 2. Load the file
    local originalPath = package.path
    local testsPath = package.path
    if searchPath then
        testsPath = searchPath .. "/?.lua;" .. searchPath .. "/?/init.lua;" .. originalPath
    end

    package.path = testsPath

    local fn, err = loadfile(path)

    package.path = originalPath

    return fn, err
end

-- converts the id to a path including the search path. Does not include any suffix such as `_spec.lua`.
local function idToPath(id)
    return searchPath .. "/" .. id:gsub("%.", "/")
end

-- findSpecFilePath(id, postfix) -> string
-- Function
-- Checks for both `<id>_<postfix>.lua` and `<id>/._<postfix>.lua` files and returns the absolute path, if the file exists.
--
-- Parameters:
-- * id - eg. `"cp.prop"`
-- * postfix - The postfix to search for (eg. `"spec"` or `"test"`).
local function findSpecFilePath(id, postfix)
    -- 1. Find the test file
    local idPath = idToPath(id)

    -- check for `<id>_<postfix>.lua`
    local testPath = fs.pathToAbsolute(idPath .. "_".. postfix .. ".lua")
    if not testPath then
        -- try `<id>/_<postfix>.lua`
        testPath = fs.pathToAbsolute(idPath .. "/_" .. postfix .. ".lua")
    end

    return testPath
end

-- execSpecFile(path[, errorLevel]) -> anything
-- Function
-- Loads and executes the script at the specified path.
--
-- Parameters:
-- * path - The absolute path to the spec file to execute.
-- * errorLevel - (optional) The error level to report from.
--
-- Returns:
-- * The result of the script at the specified path.
local function execSpecFile(path, errorLevel)
    errorLevel = errorLevel or 1

    local fn, err = loadSpecFile(path)

    if not fn then
        return nil, err
    end

    local ok, result = xpcall(fn, function() debug.traceback(format("Executing %q.", path), errorLevel + 1) end)

    if ok then
        return result
    else
        return nil, result
    end
end

-- execSpec(id, postfix[, errorLevel]) -> function, string
-- Function
-- Tries to find a matching file for the provided `id` and `postfix`. If so, executes the result and returns it.
--
-- Parameters:
-- * id - The test id to execute
-- * postfix - The postfix to search for (eg. "spec" or "test").
-- * errorLevel - If specified, the number of levels up to start reporting the error from. Defaults to 1.
local function execSpec(id, postfix, errorLevel)
    errorLevel = errorLevel or 1
    local testPath = findSpecFilePath(id, postfix)

    if not testPath then
        return nil, format("Unable to find file for %q with postfix of %q", id, postfix)
    end

    return execSpecFile(testPath, errorLevel + 1)
end

-- loadError(id, level, msg, ...) -> nothing
-- Generates a standard 'loading' error message for spec stuff.
--
-- Parameters:
-- * id - The ID of the file being loaded at the time
-- * level - The error level to start reporting from (defaults to 1)
-- * msg - The message to output.
-- * ... - Additional parameters to inject into the message via `string.format`.
--
-- Returns:
-- * Nothing.
local function loadError(id, level, msg, ...)
    level = level or 1
    error(format("Error loading %q: %s", id, msg and format(msg, ...) or "Unknown error."), level + 1)
end

--- cp.spec(id) -> cp.spec.Definition
--- Function
--- This will search the package path (and [specPath](#setSpecPath), if set) for `_spec.lua` files.
--- It will first look for a file ending with `_spec.lua`, then will look for a file named `_spec.lua` in the folder.
--- For example, if you run `require "cp.spec" "foo.bar"`, it will first look for `"foo/bar_spec.lua"`, then `"foo/bar/_spec.lua"`.
--- This gives flexibility for extensions that are organised as single files or as folders.
---
--- Parameters:
--- * id - the path ID for the spec. Eg. "cp.app"
---
--- Returns:
--- * The [Definition](cp.spec.Definition.md), or throws an error.
local function loadSpec(id)
    local result, err = execSpec(id, "spec", 2)

    if not result then
        loadError(id, 2, err)
    end

    if not Definition.is(result) then
        loadError(id, 2, "Ensure the spec file returns the test specification.")
    else
        return result
    end
end

-- wrapTest(tester) -> cp.spec.Definition
-- Function
-- Wraps the `cp.test` `tester` as a [Definition](cp.spec.Definition.md).
--
-- Parameters:
-- * tester - The `cp.test` instance to wrap.
--
-- Returns:
-- * The [Definition](cp.spec.Definition.md).
local function wrapTest(tester)
    if test.case.is(tester) then
        -- if it's a case, wrap it as a Scenario.
        return TestCase(tester)
    elseif test.suite.is(tester) then
        -- if it's a suite, wrap it as a Specification.
        return TestSuite(tester)
    else
        return nil, format("Unsupported test type: %s", type(tester))
    end
end

-- execTestFile(path) -> anything, string or nil
-- Function
-- Executes the script at the specified path, returning the result.
-- If there was an error, a second return value will contain the error message.
--
-- Parameters:
-- * path - The path to execute
--
-- Returns:
-- * anything - the result
-- * err - the error message, or `nil` if none occurred.
local function execTestFile(path)
    local result, err = execSpecFile(path, 2)

    if result then
        result, err = wrapTest(result)
    end

    return result, err
end

--- cp.spec.test(id) -> cp.spec.Definition
--- Function
--- Attempts to load a [cp.test](cp.test.md) with the specified ID, converting
--- it to a `cp.spec` [Definition](cp.spec.Definition.md). This can then
--- be run like any other `spec`.
---
--- Parameters:
--- * id - The `cp.test` ID (eg. `"cp.app"`).
---
--- Returns:
--- * The `Definition` or throws an error if it can't be found.
local function loadTest(id)
    local result, err = execSpec(id, "test")

    if result then
        result, err = wrapTest(result)
    end

    if result then
        return result
    else
        loadError(id, 2, err)
    end
end

local function findSpec(id)
    local path = findSpecFilePath(id, "spec")

    if path then
        local result, err = execSpecFile(path, 2)

        if not result then
            return nil, err
        end

        if not Definition.is(result) then
            return nil, err
        else
            return result
        end
    else -- try load as a `cp.test`
        path = findSpecFilePath(id, "test")

        if path then
            local result, err = execSpecFile(path, 2)

            if not result then
                return nil, err
            end

            result, err = wrapTest(result)
            if not result then
                return nil, err
            else
                return result
            end
        end
    end

    return nil, "Unable to find a spec or test"
end

local SPEC_FILE = "(.*)_spec%.lua$"
local TEST_FILE = "(.*)_test%.lua$"

local function findSpecsInDirectory(path, result)
    path = fs.pathToAbsolute(path)

    if path and fs.attributes(path, "mode") == "directory" then
        for file in fs.dir(path) do
            if file ~= "." and file ~= ".." then
                local filePath = path .. "/" .. file
                local newSpec, err
                local matched = false

                local mode = fs.attributes(filePath, "mode")

                if mode == "file" then
                    if file:match(SPEC_FILE) then
                        log.df("fSID: matched spec: %s", file)
                        matched = true
                        newSpec, err = execSpecFile(filePath)
                    elseif file:match(TEST_FILE) then
                        log.df("fSID: matched test: %s", file)
                        matched = true
                        newSpec, err = execTestFile(filePath)
                    end
                elseif mode == "directory" then
                    log.df("fSID: matched directory")
                    ok, err = findSpecsInDirectory(filePath, result)
                    if not ok then
                        return false, err
                    end
                end

                if newSpec then
                    if Definition.is(newSpec) then
                        result:with(newSpec)
                    else
                        return false, format("Result from %q is not a cp.spec.Definition: %s", filePath, hs.inspect(newSpec))
                    end
                elseif matched then
                    return false, format("Error loading %q as a spec file: %s", filePath, err)
                end
            end
        end

        return true
    end

    return false, format("Expected a directory: %s", path)
end

local function findAllSpecs(id)
    local result = Specification(id .. ".*")

    -- first, find any spec for the actual ID itself:
    local idSpec = findSpec(id)
    if idSpec then
        result:with(idSpec)
    end

    -- next, roll through the file/directory hierarchy looking for additional tests.
    local ok, err = findSpecsInDirectory(idToPath(id), result)

    if ok then
        return result
    else
        return nil, err
    end
end

-- The pattern for id searches
local ID_SEARCH_PATTERN = "(.*)%.%*$"

--- cp.spec.find(idPattern) -> cp.spec.Definition
--- Function
--- Attempts to find specs that match the provided ID pattern.
--- Essentially, this is a standard `require` id/path to the spec file, with
--- an optional `"*"` at the end to indicate that all specs available
--- under that path should be loaded. Eg. "foo.bar" will find the specific spec at `foo/bar_spec.lua` or `foo/bar/._spec.lua`,
--- or if those don't exist it will see if there is a `foo/bar_test.lua` or `foo/bar/._test.lua` and load that via [test](#test) instead.
--- However, if the pattern is "foo.bar.*", it will not only look for those specs, but will also check under that folder for other
--- `_spec.lua` or `_test.lua` files to add to the collection to run.
local function find(idPattern)
    local id = idPattern:match(ID_SEARCH_PATTERN)
    local result, err
    if id then
        result, err = findAllSpecs(id)
    else
        result, err = findSpec(idPattern)
    end

    if result then
        return result
    else
        return nil, err
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
    load = loadSpec,
    test = loadTest,
    setSearchPath = setSearchPath,
}, {
    __call = function(_, ...)
        return find(...)
    end
})