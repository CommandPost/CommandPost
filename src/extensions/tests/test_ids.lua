local test				= require("cp.test")
-- local log				= require("hs.logger").new("t_ids")
-- local inspect			= require("hs.inspect")

local ids				= require("cp.ids")
local config			= require("cp.config")
local v					= require("semver")

local IDS_PATH = config.scriptPath .. "/tests/ids"

local function init(currentVersion)
    local versionFn = type(currentVersion) == "function" and currentVersion or (function() return currentVersion end)
    return ids.new(IDS_PATH, versionFn)
end

return test.suite("cp.ids"):with(

    test("versions", function()

        local id = init(v("10.4.0"))

        ok(eq(id:versions(), {v("10.3.2"), v("10.3.3"), v("10.4.0")}))
    end),

    test("currentVersion", function()
        local id = init("10.0.0")
        ok(eq(id:currentVersion(), v("10.0.0")))
    end),

    test("previousVersion", function()
        local id = init("10.3.3")
        ok(eq(id:previousVersion(), v("10.3.2")))
        ok(eq(id:previousVersion("10.4.0"), v("10.3.3")))
        ok(eq(id:previousVersion("10.3.2"), nil))
        ok(eq(id:previousVersion("10.3.5"), v("10.3.3")))
    end),

    test("load", function()
        local id = init("10.4.0")

        local data = id:load("10.4.0")
        ok(eq(data.Alpha.One, "Uno"))
        ok(eq(data.Beta.A, "ay"))
        ok(eq(data.Beta.B, "bee"))

        data = id:load("10.3.3")
        ok(eq(data.Alpha.One, "1"))
        ok(eq(data.Beta.A, "A"))
        ok(eq(data.Beta.B, nil))
    end),

    test("of", function()
        local id = init("10.4.0")
        local alpha = id:of("10.3.3", "Alpha")

        ok(eq(alpha "One", "1"))
        ok(eq(alpha "Two", "2"))

        alpha = id:of("10.4.0", "Alpha")
        ok(eq(alpha "One", "Uno"))
        ok(eq(alpha "Two", "2"))
    end),

    test("ofCurrent", function()
        local version = "10.4.0"
        local versionFn = function() return version end

        local id = init(versionFn)
        local alpha = id:ofCurrent("Alpha")

        ok(eq(alpha "One", "Uno"))
        ok(eq(alpha "Two", "2"))

        -- change the version number without updating alpha
        version = "10.3.3"
        ok(eq(alpha "One", "1"))
        ok(eq(alpha "Two", "2"))
    end),

    test("__call", function()
        local alpha = init("10.4.0") "Alpha"

        ok(eq(alpha "One", "Uno"))
        ok(eq(alpha "Two", "2"))
    end)


)
